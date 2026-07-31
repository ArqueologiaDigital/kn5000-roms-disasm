#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""f31r2_downstream.py -- ROUND 2 on `hi12[3:1] > 2' (f31 = 4 and f31 = 5).

sect. 194 / sect. 195 closed the INSTRUCTION-STREAM MINIMAL PAIR route: a pair of
programs that differ in one bit is not a controlled measurement, because neither
the entering machine state nor the overall similarity of the host programs is
part of the pair.  This tool does NOT look for more pairs.  It asks a different
question:

    for every f31 in {4,5} site, WHAT CONSUMES ITS RESULT, and is that consumer
    anchored to a number the ROM itself supplies?

    python3 dsp/tools/f31r2_downstream.py sites    # per-program census
    python3 dsp/tools/f31r2_downstream.py walk     # forward consumer walk
    python3 dsp/tools/f31r2_downstream.py dram     # does the result reach a delay word?
    python3 dsp/tools/f31r2_downstream.py coef     # the C-RAM constants they multiply
    python3 dsp/tools/f31r2_downstream.py null     # the class-distribution NULL
    python3 dsp/tools/f31r2_downstream.py all

POPULATION (rule 9): IC311 only -- 91 algo slots / 38 distinct body images /
2974 body words, plus kernel (60) and epilogue (23).  Streams 79/88/89/90/91 are
IC310 (MN19413) programs and are excluded (data/F31_HIGH_findings.md sect. 2).

See analysis/data/F31_ROUND2_findings.md.
"""
import collections
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as DIS                                            # noqa: E402
import lfo_ramp as L                                                # noqa: E402
import f31hi_census as C                                            # noqa: E402

plain, f31, f98 = C.plain, C.f31, C.f98


def hdr(t):
    print("\n" + "=" * 78 + "\n== %s\n" % t + "=" * 78)


def wfmt(w):
    return "%03X.%X.%02X.%03X" % (DIS.hi12(w), DIS.class4(w),
                                  DIS.addr8(w), DIS.lo12(w))


# --------------------------------------------------------------------------
#  the programs, as ordered word lists.  One entry per DISTINCT body image plus
#  the two shared regions, exactly as f31hi_census.corpus() builds them.
# --------------------------------------------------------------------------
def programs():
    out = []
    for nm, addr in (("kernel", C.HEADER_ROM), ("epilogue", C.EPILOGUE_ROM)):
        out.append((nm, nm, C._blk(addr)))
    a2i = L.algo_to_image()
    seen = {}
    for a in sorted(a2i):
        if a in C.DSP2_MISPARSED:
            continue
        seen.setdefault(tuple(a2i[a][2]), a)
    for ws, a in sorted(seen.items(), key=lambda kv: kv[1]):
        out.append((a, C._name(a), list(ws)))
    return out


# --------------------------------------------------------------------------
#  ACCUMULATOR EFFECT of a word, modelled on the CURRENT device (upd6383.cpp
#  exec_alu(), 2026-07-31 snapshot, m_speculative on, default mask
#  0xb910e446a39b440f).  Mirrors the early returns; anything else falls through
#  to the common ALU block and touches the accumulator.
# --------------------------------------------------------------------------
def acc_effect(w):
    """'none' | 'load' | 'add' | 'hold' | 'dram' -- what this word does to acc."""
    if DIS.c_format(w):
        return "none"                       # -> m_cimm, acc untouched
    if DIS.lo12(w) & 0x800:
        return "none"                       # alternate lo12: addressing only
    if DIS.addressing_only(w):
        return "k6"                         # K6 input stage: its own ALU
    if DIS.is_dram(w):
        return "dram"                       # delay port, then re-enters the ALU
    cl = DIS.class4(w)
    hi_esc = bool(DIS.hi12(w) & DIS.HI_ESC)
    if cl == 6:
        return "none"                       # "no table is modelled" -> ALU untouched
    if w == 0 or cl == 5 or (hi_esc and DIS.lo12(w) in (0x015, 0x041)):
        return "none"
    v = f31(w)
    op = v & 3                              # device: `op = sel ? f31 & 3 : f31'
    return {0: "load", 1: "add", 2: "hold", 3: "hold"}[op]


def reads_acc(w):
    return DIS.lo_src(w) == DIS.LO_SRC_ACC


def stores(w):
    return bool(DIS.hi12(w) & DIS.HI_ST) or DIS.lo_act(w) == DIS.LO_ACT_ST_BUS


# --------------------------------------------------------------------------
#  sites
# --------------------------------------------------------------------------
def sites(vals=(4, 5)):
    out = []
    for key, nm, ws in programs():
        for i, w in enumerate(ws):
            if plain(w) and f31(w) in vals:
                out.append((key, nm, i, len(ws), w))
    return out


def cmd_sites():
    hdr("WHERE THE f31 in {4,5} WORDS LIVE -- per program (IC311 population)")
    for v in (4, 5):
        s = sites((v,))
        byprog = collections.Counter(nm for _k, nm, _i, _n, _w in s)
        byword = collections.Counter(wfmt(w) for _k, _nm, _i, _n, w in s)
        print("\n  f31 = %d : %d plain words in %d programs, %d distinct word forms"
              % (v, len(s), len(byprog), len(byword)))
        for nm, c in byprog.most_common():
            print("     %-22s %2d" % (nm, c))
        print("     forms: %s" % ", ".join("%s x%d" % (k, c)
                                           for k, c in byword.most_common()))


# --------------------------------------------------------------------------
#  walk -- the forward consumer walk
# --------------------------------------------------------------------------
def walk_one(ws, i):
    """From site i, walk forward. Returns dict of first-consumer distances."""
    r = {"reader": None, "store": None, "dram": None, "barrier": None,
         "end": None, "readerw": None, "dramw": None, "storew": None}
    for j in range(i + 1, len(ws)):
        w = ws[j]
        d = j - i
        eff = acc_effect(w)
        if r["reader"] is None and reads_acc(w):
            r["reader"], r["readerw"] = d, w
        if r["store"] is None and stores(w) and (reads_acc(w) or DIS.hi12(w) & DIS.HI_ST):
            r["store"], r["storew"] = d, w
        if r["dram"] is None and eff == "dram":
            r["dram"], r["dramw"] = d, w
        if r["barrier"] is None and eff == "load":
            r["barrier"] = d
        if DIS.is_end(w):
            r["end"] = d
            break
        if r["barrier"] is not None and r["reader"] is not None:
            break
    return r


def cmd_walk():
    hdr("THE FORWARD CONSUMER WALK -- what sees the f31 = 4/5 result, and when")
    print("""
  BARRIER = the first later word whose accumulator op is LOAD (acc <- P): it
  discards whatever f31 = 4/5 produced.  A site is DECIDABLE only if a reader or
  a store comes STRICTLY BEFORE the barrier.  (f31-high.md item E/G: 'observable'
  is necessary, not sufficient -- a store nobody reads back observes nothing.)
""")
    tot = collections.Counter()
    rows = []
    for key, nm, i, n, w in sites():
        r = walk_one(dict(programs_by_key())[key], i)
        b = r["barrier"] if r["barrier"] is not None else 10 ** 6
        live = [(k, r[k]) for k in ("reader", "store", "dram")
                if r[k] is not None and r[k] < b]
        verdict = "BLIND" if not live else "+".join("%s@%d" % kv for kv in live)
        tot[verdict.split("@")[0].split("+")[0]] += 1
        rows.append((nm, i, f31(w), wfmt(w), r["barrier"], verdict))
    for nm, i, v, s, b, verdict in rows:
        print("   %-22s w%-3d f31=%d  %-16s barrier@%-4s %s"
              % (nm, i, v, s, b if b is not None else "-", verdict))
    print("\n  summary: %s" % dict(tot))


_PBK = None


def programs_by_key():
    global _PBK
    if _PBK is None:
        _PBK = [(k, ws) for k, _nm, ws in programs()]
    return _PBK


# --------------------------------------------------------------------------
#  dram -- does an f31 = 4/5 result ever reach the delay port?
# --------------------------------------------------------------------------
def cmd_dram():
    hdr("DOES ANY f31 = 4/5 RESULT REACH THE DELAY DOMAIN? (sect. 201 / sect. 202)")
    print("""
  sect. 201 gave the delay lines a real length and sect. 202 fixed the rotation
  sign, so a delay-domain observable is anchored bit-exactly to the ROM's own
  descriptor cells.  The question: is any f31 = 4/5 word UPSTREAM of a delay word
  with no LOAD barrier between them?
""")
    hits = 0
    pbk = dict(programs_by_key())
    for key, nm, i, n, w in sites():
        ws = pbk[key]
        r = walk_one(ws, i)
        b = r["barrier"] if r["barrier"] is not None else 10 ** 6
        if r["dram"] is not None and r["dram"] < b:
            hits += 1
            print("   ★ %-22s w%-3d f31=%d %s -> DRAM@+%d %s (barrier@%s)"
                  % (nm, i, f31(w), wfmt(w), r["dram"], wfmt(r["dramw"]),
                     r["barrier"]))
    print("\n   f31 = 4/5 sites reaching a delay word before a LOAD barrier: %d of %d"
          % (hits, len(sites())))
    # and the converse: how far is the NEAREST delay word in the same program?
    near = []
    for key, nm, i, n, w in sites():
        ws = pbk[key]
        ds = [abs(j - i) for j, x in enumerate(ws) if acc_effect(x) == "dram"]
        near.append((nm, i, f31(w), min(ds) if ds else None,
                     sum(1 for x in ws if acc_effect(x) == "dram")))
    nod = [x for x in near if x[4] == 0]
    print("   f31 = 4/5 sites in a program with NO delay word at all: %d of %d"
          % (len(nod), len(near)))


# --------------------------------------------------------------------------
#  coef -- the constants these words multiply
# --------------------------------------------------------------------------
def cmd_coef():
    hdr("THE C-RAM CONSTANT EACH f31 = 4/5 WORD FETCHES")
    print("""
  A class-A / class-2 word with a coefficient fetch multiplies C-RAM[addr8] by
  the bus.  The ROM's chosen constant is the one piece of DESIGNER INTENT
  attached to the word, so it is the only thing that can grade a reading from
  the ROM alone.
""")
    cnt = collections.Counter()
    for key, nm, i, n, w in sites():
        if not isinstance(key, int):
            cram = None
        else:
            try:
                cram = L.cram_of_algo(key)
            except Exception:
                cram = None
        ad = DIS.addr8(w)
        v = None
        if cram is not None and ad < len(cram):
            v = cram[ad]
        cnt[(f31(w), wfmt(w), "------" if v is None else "%06X" % (v & 0xFFFFFF))] += 1
    for (v, s, c), k in sorted(cnt.items(), key=lambda kv: (-kv[1], kv[0])):
        note = ""
        if c == "517CC1":
            note = "  <- floor(2/pi * 2^23), the |sin| mean"
        elif c == "600000":
            note = "  <- 0.75"
        elif c == "000018":
            note = "  <- 24 = the LFO table extent"
        elif c == "400000":
            note = "  <- 0.5"
        print("   f31=%d %-16s C-RAM=%-8s x%-3d%s" % (v, s, c, k, note))


# --------------------------------------------------------------------------
#  null -- the class distribution and its hypergeometric null
# --------------------------------------------------------------------------
#  ⛔ S2's list.  CIRCULAR when used to score f31: sect. 140 S2 DERIVED it as
#  "the images with zero f31 >= 3" and only then observed they are all linear.
#  Kept so the circular number can be printed AND labelled.
LINEAR_S2 = {"CHORUS", "MODULATED CHORUS", "FLANGER", "ENSEMBLE", "SINGLE DELAY",
             "MULTI TAP DELAY", "ROOM REVERB 1", "VIBRATO", "MIX UP",
             "S.DELAY+CHORUS", "S.DELAY x2", "S.DELAY+FLANGER",
             "S.DELAY+VIBRATO", "S.DELAY+PHASER"}

#  ★ THE NON-CIRCULAR CLASS.  Decided from the EFFECT NAME alone, by what the
#  named effect requires in audio engineering, with no reference to any f31
#  count.  "NEEDS a magnitude/limit stage" = the textbook realisation of the
#  effect contains a rectifier, an envelope follower or a saturating shaper.
NEEDS_MAGNITUDE = {
    "DISTORTION", "OVERDRIVE", "FUZZ",          # saturating waveshaper
    "EXCITER", "ENHANCER",                      # harmonic generator
    "COMPRESSOR", "AUTO WAH", "GATED REVERB",   # envelope follower
    "AUTO WAH+S.DELAY", "PEQ+COMPRESSOR", "PEQ+COMPR+DIST", "PEQ+COMPR+OVER",
    "PEQ+DIST+DELAY", "PEQ+OVER+DELAY",
}
#  Everything else in the IC311 image set is LINEAR or BILINEAR by name:
#  EQ, delay, reverb, chorus/flanger/phaser/vibrato/ensemble, pan, rotary,
#  ring modulation (a product of two signals -- no magnitude stage).


def _lhyp(K, N, k, n):
    return (math.lgamma(K + 1) - math.lgamma(k + 1) - math.lgamma(K - k + 1)
            + math.lgamma(N - K + 1) - math.lgamma(n - k + 1)
            - math.lgamma(N - K - n + k + 1)
            - (math.lgamma(N + 1) - math.lgamma(n + 1) - math.lgamma(N - n + 1)))


def _null_against(label, setnm, note):
    bodies = [(nm, ws) for k, nm, ws in programs() if isinstance(k, int)]
    N = sum(len([w for w in ws if plain(w)]) for _nm, ws in bodies)
    n = sum(1 for k, _nm, _i, _x, _w in sites() if isinstance(k, int))
    K = sum(len([w for w in ws if plain(w)]) for nm, ws in bodies if nm in setnm)
    k = sum(1 for key, nm, _i, _x, _w in sites()
            if isinstance(key, int) and nm in setnm)
    print("\n   %s   %s" % (label, note))
    print("     plain BODY words                N = %4d" % N)
    print("     of them inside the set          K = %4d  (%.1f %%)"
          % (K, 100.0 * K / N))
    print("     f31 in {4,5} body words         n = %4d" % n)
    print("     of them inside the set          k = %4d   expected %.1f"
          % (k, n * K / N))
    lo = sum(math.exp(_lhyp(K, N, kk, n))
             for kk in range(0, k + 1) if N - K - n + kk >= 0)
    hi = sum(math.exp(_lhyp(K, N, kk, n))
             for kk in range(k, min(K, n) + 1) if N - K - n + kk >= 0)
    print("     hypergeometric P[X <= k] = %.3g   P[X >= k] = %.3g" % (lo, hi))
    for v in (4, 5):
        s = [x for x in sites((v,)) if isinstance(x[0], int)]
        kv = sum(1 for x in s if x[1] in setnm)
        print("       f31 = %d: %d body words, %d inside the set" % (v, len(s), kv))


def cmd_null():
    hdr("THE NULL -- is the f31 = 4/5 PLACEMENT distinguishable from arbitrary?")
    print("""
  NULL: f31 = 4/5 is an inert alias of 0/1, so which code the designer emits is
  arbitrary and independent of what the program computes.  Then every program
  carries its population share of f31 = 4/5 words.

  Two partitions are scored.  Only the second one is admissible as evidence.
""")
    _null_against("[A] sect. 140 S2's LINEAR list", LINEAR_S2,
                  "⛔ CIRCULAR -- the list was DERIVED from the f31 census")
    _null_against("[B] NEEDS A MAGNITUDE STAGE", NEEDS_MAGNITUDE,
                  "★ a-priori, from the effect NAME alone")


# --------------------------------------------------------------------------
#  ctx -- print the window around the interesting sites
# --------------------------------------------------------------------------
def cmd_ctx():
    hdr("THE CONTEXT WINDOWS -- the sites that are NOT blind")
    pbk = dict(programs_by_key())
    want = collections.OrderedDict()
    for key, nm, i, n, w in sites():
        ws = pbk[key]
        r = walk_one(ws, i)
        b = r["barrier"] if r["barrier"] is not None else 10 ** 6
        live = [k for k in ("reader", "store", "dram")
                if r[k] is not None and r[k] < b]
        if live:
            want[(nm, i)] = (key, f31(w), live)
    for (nm, i), (key, v, live) in want.items():
        ws = pbk[key]
        print("\n   %s  w%d  f31=%d  (%s)" % (nm, i, v, "+".join(live)))
        for j in range(max(0, i - 2), min(len(ws), i + 5)):
            mark = " **" if j == i else "   "
            w = ws[j]
            print("     %s w%-3d %s  f31=%d cls=%X src=%02X act=%02X %s%s%s"
                  % (mark, j, wfmt(w), f31(w), DIS.class4(w), DIS.lo_src(w),
                     DIS.lo_act(w), acc_effect(w).upper(),
                     " ST" if DIS.hi12(w) & DIS.HI_ST else "",
                     "" if not DIS.is_dram(w)
                     else "  DRAM-%s" % DIS.dram_dir(w)))


# --------------------------------------------------------------------------
#  free -- ★ the OPERAND-FREE family
# --------------------------------------------------------------------------
def operand_free(w):
    """No memory operand, no coefficient fetch, no store, no pointer move, no
    temp capture -- the whole word IS the opcode."""
    return (plain(w)
            and DIS.class4(w) == 2               # not class A/8: no cursor fetch
            and not (DIS.class4(w) & 8)          # coeff_fetch()
            and DIS.addr8(w) == 0                # ptr_postinc by 0
            and DIS.lo12(w) == 0                 # SRC 0x00, ACT 0x00, no ptrmode
            and not (DIS.hi12(w) & DIS.HI_ST)    # no bit-4 store
            and not (DIS.hi12(w) & 0x080))       # no bit 7


def cmd_free():
    hdr("★ THE OPERAND-FREE FAMILY -- `0XX.2.00.000', where the word IS the opcode")
    print("""
  A word with class 2, addr8 0x00, lo12 0x000 and hi12 bit 4 clear has:
     no memory operand   (SRC 0x00, and class 2 fetches no cursor coefficient)
     no destination      (ACT 0x00, no bit-4 store)
     no pointer movement (addr8 = 0 -> p += 0)
  Everything that distinguishes one such word from another is in hi12, and
  inside hi12 only f31 and bit 5 ever vary.  A word with no operands cannot be
  a BINARY operation; it can only be a UNARY operation ON THE ACCUMULATOR.
""")
    tab = collections.Counter()
    for _k, nm, ws in programs():
        for w in ws:
            if operand_free(w):
                tab[(DIS.hi12(w), f31(w))] += 1
    print("   hi12   f31   count   (whole IC311 machine, plain words)")
    for (h, v), c in sorted(tab.items()):
        print("   %03X     %d    %4d %s" % (h, v, c, "★" if v > 2 else ""))
    tot = sum(tab.values())
    hi = sum(c for (h, v), c in tab.items() if v > 2)
    print("\n   total operand-free words %d, of which f31 > 2: %d (%.1f %%)"
          % (tot, hi, 100.0 * hi / tot))
    n45 = sum(1 for _k, _nm, _i, _x, w in sites() if operand_free(w))
    print("   f31 in {4,5} words that are OPERAND-FREE: %d of %d (%.1f %%)"
          % (n45, len(sites()), 100.0 * n45 / len(sites())))
    base = 0
    tt = 0
    for _k, _nm, ws in programs():
        for w in ws:
            if plain(w):
                tt += 1
                if operand_free(w):
                    base += 1
    print("   base rate of operand-free among ALL plain words: %d / %d = %.1f %%"
          % (base, tt, 100.0 * base / tt))


def main():
    cmds = {"sites": cmd_sites, "walk": cmd_walk, "dram": cmd_dram,
            "coef": cmd_coef, "null": cmd_null, "ctx": cmd_ctx, "free": cmd_free}
    args = sys.argv[1:] or ["all"]
    if args == ["all"]:
        args = list(cmds)
    for a in args:
        cmds[a]()


if __name__ == "__main__":
    main()
