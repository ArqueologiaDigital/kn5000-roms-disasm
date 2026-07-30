#!/usr/bin/env python3
"""gate7.py -- corpus adjudication of guard 6 / guard 7 / the bit-7 GATE,
and of iw30 / iw32's store target.  Static only.

Population (rule 9): the 3057-word corpus = 60-word header + 23-word epilogue
(together the 83-word resident kernel) + 2974 words over the 38 distinct body
images, DSP2 streams {79,88,89,90,91} excluded.
"""
import collections
import sys

ALGO_TABLE = 0x0001ED7C
N_ALGOS = 100
HEADER_ROM = 0x01E496
EPILOGUE_ROM = 0x01E63C
DSP2_MISPARSED = {79, 88, 89, 90, 91}

SUB = "/home/fsanches/compartilhado/kn5000-roms-disasm/original_ROMs/kn5000_subprogram_v142.rom"
TOOLS = "/home/fsanches/compartilhado/kn7000_mame/tools"

HI_ESC, HI_END, HI_ST, HI_B7 = 0x800, 0x400, 0x010, 0x080


def hi12(w): return (w >> 24) & 0xFFF
def class4(w): return (w >> 20) & 0xF
def addr8(w): return (w >> 12) & 0xFF
def lo12(w): return w & 0xFFF
def c_format(w): return (hi12(w) & 0xF00) == 0xC00
def f31(w): return (hi12(w) >> 1) & 7
def src(w): return (w >> 6) & 0x1F
def act(w): return w & 0x1F
def ptrmode(w): return (w >> 5) & 1
def mode(w): return 2 if c_format(w) else (class4(w) & 7)
def st(w): return bool(hi12(w) & HI_ST)
def b7(w): return bool(hi12(w) & HI_B7)
def delta(w):
    a = addr8(w)
    return a - 256 if a >= 128 else a


def anchored_src(s): return s in (0x07, 0x10, 0x19, 0x1A)
def anchored_act(a): return a in (0x00, 0x07, 0x12, 0x13, 0x14, 0x15, 0x19)


def alu_decoded(w, verbose=False):
    """faithful transcription of upd6383d.h alu_decoded(); returns (bool, reason)"""
    if c_format(w):
        return False, "c_format"
    cl = class4(w)
    if cl not in (2, 8, 0xA):
        return False, "guard1-class"
    if lo12(w) & 0x800:
        return False, "guard2-bit11"
    if ptrmode(w):
        return False, "guard2-ptrmode"
    if not anchored_src(src(w)):
        return False, "guard2-src%02X" % src(w)
    if not anchored_act(act(w)):
        return False, "guard2-act%02X" % act(w)
    if st(w) and (cl & 7) != 2:
        return False, "guard5"
    if act(w) == 0x07 and (cl & 7) != 2:
        return False, "guard6"
    if st(w) and b7(w) and f31(w) != 2:
        return False, "guard7"
    f = f31(w)
    if f in (0, 1):
        return True, "-"
    if f == 2:
        return (cl == 8, "guard3-hold-off-8" if cl != 8 else "-")
    return False, "guard3-f31=%d" % f


def txt(w):
    return "%03X.%X.%02X.%03X" % (hi12(w), class4(w), addr8(w), lo12(w))


def load_corpus():
    sys.path.insert(0, TOOLS)
    import kn5000_dsp_extract as E
    rom = E.Rom(SUB)

    def blk(a):
        ir, _c, _o = E.parse_stream(rom, a, limit=40)
        return [int.from_bytes(bytes(x), "big") for x in ir[0][1]] if ir else []

    header, epilogue = blk(HEADER_ROM), blk(EPILOGUE_ROM)
    progs = {}
    for i in range(N_ALGOS):
        p = rom.u32le(ALGO_TABLE + 4 * i)
        try:
            ir, _c, _o = E.parse_stream(rom, p)
        except Exception:
            continue
        if ir:
            progs[i] = [int.from_bytes(bytes(x), "big")
                        for x in (x for _a, ws, _l in ir for x in ws)]
    g = {}
    for a in sorted(progs):
        if a in DSP2_MISPARSED:
            continue
        g.setdefault(tuple(progs[a]), []).append(a)
    images = sorted([(v[0], v, list(k)) for k, v in g.items()], key=lambda t: t[0])
    return header, epilogue, images


def allwords(header, epilogue, images):
    for i, w in enumerate(header):
        yield ("KERNEL/header", i, w)
    for i, w in enumerate(epilogue):
        yield ("KERNEL/epilogue", 60 + i, w)
    for r, algos, ws in images:
        for i, w in enumerate(ws):
            yield ("algo%d" % r, i, w)


def main():
    header, epilogue, images = load_corpus()
    C = list(allwords(header, epilogue, images))
    print("POPULATION: header %d + epilogue %d + %d body images (%d words) = %d"
          % (len(header), len(epilogue), len(images),
             sum(len(w) for _r, _a, w in images), len(C)))
    kern = [(l, i, w) for l, i, w in C if l.startswith("KERNEL")]
    print("           kernel = %d words; bodies = %d words\n"
          % (len(kern), len(C) - len(kern)))

    IW30, IW32 = 0x009AA00200, 0x0000AFF207
    IW70 = 0x2A6185_0C7 if False else 0x2A61850C7

    # ---------------- 0. the three words in question ----------------
    print("=" * 78)
    print("0. THE WORDS IN QUESTION -- located by I-RAM index in the kernel")
    print("=" * 78)
    for name, want in (("iw30", IW30), ("iw32", IW32), ("iw70", IW70)):
        hits = [(l, i) for l, i, w in C if w == want]
        d, r = alu_decoded(want)
        print("  %-5s %s  f31=%d b4=%d b7=%d src=%02X act=%02X mode=%d delta=%+d"
              % (name, txt(want), f31(want), st(want), b7(want),
                 src(want), act(want), mode(want), delta(want)))
        print("        alu_decoded = %-5s  first-refusing guard: %s" % (d, r))
        print("        occurrences: %s" % (hits if len(hits) < 12 else
                                          "%d sites, kernel=%s" % (len(hits),
                                          [x for x in hits if x[0].startswith("KERNEL")])))
    print()

    # ---------------- 1. bit4 AND bit7 census ----------------
    print("=" * 78)
    print("1. STORE bit 4 AND GATE bit 7 -- the whole corpus, split by f31")
    print("=" * 78)
    n_st = sum(1 for _l, _i, w in C if st(w))
    n_b7 = sum(1 for _l, _i, w in C if b7(w))
    both = [(l, i, w) for l, i, w in C if st(w) and b7(w)]
    print("  words carrying bit 4          : %4d / %d" % (n_st, len(C)))
    print("  words carrying bit 7          : %4d / %d" % (n_b7, len(C)))
    print("  words carrying BOTH           : %4d" % len(both))
    exp = n_st * n_b7 / len(C)
    print("  ★ NULL if the two bits were INDEPENDENT: %.1f expected, %d observed"
          " (ratio %.2f)" % (exp, len(both), len(both) / exp))
    print()
    print("   f31 | bit4&bit7 | of which kernel |  bit4 & !bit7 | !bit4 & bit7 | guard7")
    print("   ----+-----------+-----------------+---------------+--------------+-------")
    for f in range(8):
        bb = [x for x in both if f31(x[2]) == f]
        bk = [x for x in bb if x[0].startswith("KERNEL")]
        b4o = sum(1 for _l, _i, w in C if st(w) and not b7(w) and f31(w) == f)
        b7o = sum(1 for _l, _i, w in C if b7(w) and not st(w) and f31(w) == f)
        print("    %d  |   %5d   |      %5d      |     %6d    |    %6d    |  %s"
              % (f, len(bb), len(bk), b4o, b7o,
                 "EXEC" if f == 2 else "condemned"))
    print()
    cond = [x for x in both if f31(x[2]) != 2]
    print("  ★ guard 7 condemns %d of the %d bit4+bit7 words = %.1f%%"
          % (len(cond), len(both), 100.0 * len(cond) / len(both)))
    ck = [x for x in cond if x[0].startswith("KERNEL")]
    print("  ★ and %d of the condemned sit in the RESIDENT KERNEL: %s"
          % (len(ck), [(l, i, txt(w)) for l, i, w in ck]))
    print()
    print("  the f31 outside {1,2} set (store-gate.md item F's \"13\"):")
    odd = [x for x in both if f31(x[2]) not in (1, 2)]
    cnt = collections.Counter(txt(w) for _l, _i, w in odd)
    for k, v in cnt.most_common():
        where = [(l, i) for l, i, w in odd if txt(w) == k]
        print("     %-18s x%-3d  %s" % (k, v, where[:6]))
    print("     total %d  (kernel %d, bodies %d)"
          % (len(odd), sum(1 for x in odd if x[0].startswith("KERNEL")),
             sum(1 for x in odd if not x[0].startswith("KERNEL"))))
    print()

    # how many of the 180 would alu_decoded accept if guard 7 vanished?
    print("  PRICE OF GUARD 7 (what it, and NOTHING ELSE, refuses):")
    refused_only_by_7 = [x for x in both if alu_decoded(x[2])[1] == "guard7"]
    print("     %d words are refused by guard 7 as the FIRST failing guard"
          % len(refused_only_by_7))
    r = collections.Counter(alu_decoded(w)[1] for _l, _i, w in both)
    for k, v in r.most_common():
        print("        first-failing guard %-18s %4d" % (k, v))
    print()

    # ---------------- 2. ACT 0x07 ----------------
    print("=" * 78)
    print("2. ACTION 0x07 -- guard 6's \"303 of 303 executing L=07 words are mode 2\"")
    print("=" * 78)
    a07 = [(l, i, w) for l, i, w in C if act(w) == 0x07 and not c_format(w)
           and not ptrmode(w)]
    a07all = [(l, i, w) for l, i, w in C if act(w) == 0x07]
    print("  every word with lo12[4:0] == 0x07 : %d  (of which c_format %d, ptrmode %d)"
          % (len(a07all), sum(1 for _l, _i, w in a07all if c_format(w)),
             sum(1 for _l, _i, w in a07all if ptrmode(w) and not c_format(w))))
    bycl = collections.Counter(class4(w) for _l, _i, w in a07)
    bymo = collections.Counter(mode(w) for _l, _i, w in a07)
    print("  by class4 : %s" % dict(sorted(bycl.items())))
    print("  by mode   : %s" % dict(sorted(bymo.items())))
    ex = [(l, i, w) for l, i, w in a07all if alu_decoded(w)[0]]
    print("  ★ EXECUTING under alu_decoded()          : %d" % len(ex))
    print("     their modes: %s" % dict(collections.Counter(mode(w) for _l, _i, w in ex)))
    # the vacuity check
    surv = [(l, i, w) for l, i, w in a07all
            if not c_format(w) and class4(w) in (2, 8, 0xA)
            and not (lo12(w) & 0x800) and not ptrmode(w)
            and anchored_src(src(w))]
    print("  ★ VACUITY CHECK -- guard 6 can only bite a word that survives guard 1")
    print("     (class in {2,8,A}) and the routing guard.  Among {2,8,A}, mode != 2")
    print("     happens ONLY at class 8.  Words with ACT 0x07 and class 8 in the")
    print("     whole corpus: %d.  Surviving guards 1+2 with class 8: %d."
          % (bycl.get(8, 0), sum(1 for _l, _i, w in surv if class4(w) == 8)))
    print("     ⇒ guard 6's cell CAN NOT be non-empty: its statistic is 303 of 303")
    print("       by CONSTRUCTION of guard 1, not by measurement of the corpus.")
    print()
    m1 = [(l, i, w) for l, i, w in a07 if class4(w) == 1]
    print("  MODE-1 (class4 == 1) ACT-0x07 words -- iw70's family: %d" % len(m1))
    for k, v in collections.Counter(txt(w) for _l, _i, w in m1).most_common(20):
        where = [(l, i) for l, i, w in m1 if txt(w) == k]
        print("     %-18s x%-3d  %s" % (k, v, where[:5]))
    print("     alu_decoded on these: %s"
          % dict(collections.Counter(alu_decoded(w)[1] for _l, _i, w in m1)))
    print()

    # ---------------- 3. class A vs class 2 ----------------
    print("=" * 78)
    print("3. class4 == 0xA vs class4 == 2 -- is class A's store target different?")
    print("=" * 78)
    for label, pred in (("bit-4 store words", lambda w: st(w) and not c_format(w)),
                        ("ACT-0x07 words", lambda w: act(w) == 0x07 and not c_format(w)
                         and not ptrmode(w))):
        cc = collections.Counter(class4(w) for _l, _i, w in C if pred(w))
        print("  %-20s by class4: %s" % (label, dict(sorted(cc.items()))))
    print()
    print("  the LFO triple (lfo-ramp.md sect. 1) and iw30, all at lo12 = 0x200:")
    fam = [w for _l, _i, w in C if lo12(w) == 0x200 and class4(w) == 0xA
           and addr8(w) == 0x00]
    for k, v in collections.Counter(txt(w) for w in fam).most_common():
        ww = [w for w in fam if txt(w) == k][0]
        sites = [(l, i) for l, i, w in C if w == ww]
        kk = [s for s in sites if s[0].startswith("KERNEL")]
        print("     %-18s x%-4d f31=%d b4=%d b7=%d   kernel sites %s"
              % (k, v, f31(ww), st(ww), b7(ww), kk))
    print()
    print("  the class-2 partner 082.2.00.1C0 :")
    for k in (0x00822001C0,):
        sites = [(l, i) for l, i, w in C if w == k]
        print("     %-18s x%-4d f31=%d b4=%d b7=%d src=%02X act=%02X"
              % (txt(k), len(sites), f31(k), st(k), b7(k), src(k), act(k)))
        print("       kernel sites %s" % [s for s in sites if s[0].startswith("KERNEL")])
    print()
    print("  ★ class-A words at (b7,f31) == (1,2) -- store-gate.md item E FORCES")
    print("    these to store the accumulator to mem[ptr] (17928/17928 survivors):")
    e12 = [(l, i, w) for l, i, w in C if st(w) and b7(w) and f31(w) == 2]
    cc = collections.Counter((class4(w), mode(w)) for _l, _i, w in e12)
    print("     %d words, by (class4, mode): %s" % (len(e12), dict(sorted(cc.items()))))
    print("     distinct forms: %s"
          % sorted(set(txt(w) for _l, _i, w in e12))[:14])
    print()

    # ---------------- 4. pre vs post increment ----------------
    print("=" * 78)
    print("4. PRE- vs POST-INCREMENT for ACT 0x07 -- what the corpus can say")
    print("=" * 78)
    m2_07 = [(l, i, w) for l, i, w in C if act(w) == 0x07 and not c_format(w)
             and not ptrmode(w) and (class4(w) & 7) == 2]
    print("  mode-2 ACT-0x07 words: %d" % len(m2_07))
    z = sum(1 for _l, _i, w in m2_07 if delta(w) == 0)
    print("  ★ CALIBRATION -- for how many is the question even ANSWERABLE?")
    print("     delta == 0 (pre and post are the SAME cell, BLIND) : %d (%.1f%%)"
          % (z, 100.0 * z / len(m2_07)))
    print("     delta != 0 (the two models differ)                : %d"
          % (len(m2_07) - z))
    dd = collections.Counter(delta(w) for _l, _i, w in m2_07)
    print("     delta histogram: %s" % dict(sorted(dd.items())))
    print()
    dboth = [(l, i, w) for l, i, w in C if st(w) and act(w) == 0x07
             and not c_format(w) and not ptrmode(w)]
    print("  ★ THE DOUBLE-STORE TEST: words carrying BOTH bit 4 and ACT 0x07.")
    print("    If bit 4 stores at the PRE cell (sect. 35, FORCED by the K6 table)")
    print("    and ACT 0x07 at the POST cell, such a word writes TWO cells.")
    print("     count: %d" % len(dboth))
    for k, v in collections.Counter(txt(w) for _l, _i, w in dboth).most_common(30):
        ww = [w for _l, _i, w in dboth if txt(w) == k][0]
        print("     %-18s x%-4d mode=%d delta=%+d src=%02X f31=%d b7=%d"
              % (k, v, mode(ww), delta(ww), src(ww), f31(ww), b7(ww)))
    nz = [x for x in dboth if delta(x[2]) != 0 and (class4(x[2]) & 7) == 2]
    print("     of these, mode 2 AND delta != 0 (the discriminating ones): %d" % len(nz))
    print()

    # ---------------- 5. the static kernel pointer walk around iw30/iw32 ----
    print("=" * 78)
    print("5. THE STATIC KERNEL WALK, iw24..iw40 -- what cell each model picks")
    print("=" * 78)
    kw = header + epilogue
    p = 0
    rows = []
    for i, w in enumerate(kw):
        pre = p
        d = delta(w) if (not c_format(w) and (class4(w) & 7) == 2) else 0
        p = (p + d) & 0xFF
        rows.append((i, w, pre, d, p))
    for i, w, pre, d, post in rows:
        if 24 <= i <= 40:
            mark = "  <== iw%d" % i if i in (30, 32) else ""
            print("   iw%-3d %s  pre=%+d delta=%+d post=%+d  b4=%d b7=%d f31=%d "
                  "src=%02X act=%02X%s"
                  % (i, txt(w), pre if pre < 128 else pre - 256, d,
                     post if post < 128 else post - 256,
                     st(w), b7(w), f31(w), src(w), act(w), mark))
    p30 = [r for r in rows if r[0] == 30][0]
    p32 = [r for r in rows if r[0] == 32][0]
    print()
    print("   relative geometry (pointer units, iw0 = 0):")
    print("     iw30 pre = %+d  post = %+d" % (p30[2], p30[4]))
    print("     iw32 pre = %+d  post = %+d" % (p32[2], p32[4]))
    print("     ⇒ iw32's PRE cell is iw30's store cell + %d" % (p32[2] - p30[2]))
    print("       iw32's POST cell is iw30's store cell + %d" % (p32[4] - p30[2]))
    print()

    # ---------------- 6. f31=5 population ----------------
    print("=" * 78)
    print("6. f31 == 5 -- iw30's accumulator operation")
    print("=" * 78)
    f5 = [(l, i, w) for l, i, w in C if not c_format(w) and f31(w) == 5]
    print("  f31 == 5 words: %d" % len(f5))
    for k, v in collections.Counter(txt(w) for _l, _i, w in f5).most_common(20):
        ww = [w for _l, _i, w in f5 if txt(w) == k][0]
        sites = [(l, i) for l, i, w in f5 if w == ww]
        print("     %-18s x%-4d b4=%d b7=%d src=%02X act=%02X   %s"
              % (k, v, st(ww), b7(ww), src(ww), act(ww),
                 ("KERNEL " + str([s[1] for s in sites if s[0].startswith("KERNEL")]))
                 if any(s[0].startswith("KERNEL") for s in sites) else
                 str(sorted(set(s[0] for s in sites))[:4])))
    print()
    fh = collections.Counter(f31(w) for _l, _i, w in C if not c_format(w))
    print("  whole-corpus f31 histogram (non-c_format): %s" % dict(sorted(fh.items())))
    print()

    # ---------------- 7. SRC 0x08 ----------------
    print("=" * 78)
    print("7. SRC 0x08 -- the operand iw30 and iw32 both read")
    print("=" * 78)
    s8 = [(l, i, w) for l, i, w in C if not c_format(w) and not ptrmode(w)
          and src(w) == 0x08]
    print("  SRC 0x08 words: %d   by class4 %s"
          % (len(s8), dict(sorted(collections.Counter(class4(w) for _l, _i, w in s8).items()))))
    print("  by ACT: %s" % dict(sorted(collections.Counter(act(w) for _l, _i, w in s8).items())))
    print("  none of them is anchored, so alu_decoded refuses ALL %d at guard 2." % len(s8))
    print("  in the KERNEL: %s"
          % [(i, txt(w)) for l, i, w in s8 if l.startswith("KERNEL")])
    print()


if __name__ == "__main__":
    main()


def load_algo_level():
    """lfo_ramp.py's OWN population: every valid ALGORITHM SLOT, not just the
    distinct images -- which is why its counts carry a ~2.4x replication."""
    sys.path.insert(0, TOOLS)
    import kn5000_dsp_extract as E
    rom = E.Rom(SUB)
    out = {}
    for i in range(N_ALGOS):
        p = rom.u32le(ALGO_TABLE + 4 * i)
        try:
            ir, _c, _o = E.parse_stream(rom, p)
        except Exception:
            continue
        if not ir or ir[0][0] not in (84, 200):
            continue
        out[i] = (i, [i], [int.from_bytes(bytes(x), "big")
                           for _a, ws, _l in ir for x in ws])
    return [out[k] for k in sorted(out)]
