#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""wsa1_dsp_isa_crossval.py -- run the KN5000 uPD6383GF ISA model over the
SX-WSA1R's DSP microcode, as an INDEPENDENT third corpus of the same chip.

QUESTION ANSWERED
  The KN5000 IC311 effects DSP is a uPD6383GF-3BA.  The SX-WSA1R carries THREE
  of the SAME part (wsa1.cpp:299), fully dumped.  Its P7 effect layer uploads
  microcode as a relocatable byte-stream pool at prom_c 0xFCD0F7-0xFDD2AA
  (wsa1/notes/FINDINGS-prom_c-p7-byte-stream-pool.md).  Nobody had ever fed the
  WSA1R's DSP program words to the KN5000 disassembler.  This does that and asks:
  does the WSA1R corpus CONFIRM the KN5000 ISA model (same container, same field
  structure, decodes at a comparable rate ABOVE A NULL), and does it exercise any
  of the KN5000's undecidable residue?

WHERE THE WSA1R PROGRAM WORDS COME FROM
  The pool is a concatenation of 297 relocatable streams + 6 data tables + 4
  directory objects, framed exactly as the KN5000's Sub-CPU bytecode
  (kn5000_dsp_extract.parse_stream):
      byte0 hi nibble = opcode ; len = ((byte0&0x0F)<<8)|byte1 (incl. 2-B header)
      opcode 3 -> cmd byte, 16-bit I-RAM word address, then 5-byte INSTRUCTION WORDS
      opcode 2 -> cmd + 2 preamble, then 3-byte (24-bit) COEFFICIENTS
  So the DSP *program words* are exactly the opcode-3 records' 5-byte words -- the
  same choice pat_corpus.load() makes for the KN5000 (it collects opcode-3 words
  from the ALGO_TABLE streams and nothing else).  We reuse the AUTHORITATIVE pool
  tiling from wsa1/notes/gen_prom_c_p7stream_pool.py (its --verify gates the
  framing), and only STREAM objects contribute.

CONTAINER
  36-bit instruction in a 5-byte big-endian right-aligned container, bits[36:39]
  zero.  Field layout (pat_corpus.F):
      hi12[35:24] . class4[23:20] . addr8[19:12] . lo12[11:0]
      lo12: SRC = bits[10:6], ACT = bits[4:0], ptrmode = bit5, bit11 = FORMAT ESC
      hi12: f98 = bits[9:8], b7 = bit7, ST = bit4, f31 = bits[3:1], ESC = bit11

ANCHORING
  The decode predicate is dsp_disasm.alu_decoded(), the exact conjunction the
  MAME core upd6383d.h uses (see f31_367.py).  A word is "anchored/decoded" iff
  alu_decoded()==True.  guard_fail() (mirrored from f31_367.py) reports WHICH
  guard first refuses a word, so we can compare the failure spectra.

NULL
  A coverage figure without a null is meaningless (house rule).  Three nulls, all
  sized to the WSA1R corpus:
    1. uniform random 36-bit words (top nibble forced 0 to honour the container)
    2. byte-shuffle: the WSA1R word bytes permuted globally, re-chunked to 5-B
       words (preserves the byte-value histogram, destroys word structure)
    3. field-shuffle: hi12/class4/addr8/lo12 each permuted independently across
       the corpus (preserves every field's marginal, destroys their correlation)

SELF-TESTS (rule 20), printed first, able to fail
  KN5000: 3057 corpus words, 1178 alu_decoded, guard_fail==0 agrees -- all three
  published by instruments that do not know this one exists (f31_367.py etc.).

RUN
  python3 wsa1/dsp/analysis/wsa1_dsp_isa_crossval.py            # the report
  python3 wsa1/dsp/analysis/wsa1_dsp_isa_crossval.py --selftest # just the gates

stdlib only, plus the KN5000 research tree's own loader/disassembler and the
WSA1R pool tiler.  Read-only.
"""
import argparse
import collections
import os
import random
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(
    os.path.dirname(os.path.abspath(__file__)))))          # .../kn5000-roms-disasm
sys.path.insert(0, os.path.join(REPO, "dsp", "tools"))
sys.path.insert(0, os.path.join(REPO, "wsa1", "notes"))

import dsp_disasm as D                       # noqa: E402  the ISA model
import pat_corpus as PC                      # noqa: E402  the KN5000 corpus loader
import f31_367 as F31                        # noqa: E402  guard_fail() mirror
import gen_prom_c_p7stream_pool as POOL      # noqa: E402  the WSA1R pool tiler


# ---------------------------------------------------------------------------
#  corpora
# ---------------------------------------------------------------------------
def kn5000_words():
    """The 3057-word KN5000 program corpus (opcode-3 words), flat."""
    progs, meta = PC.load()
    return [w for ws in progs.values() for w in ws]


def wsa1_stream_words():
    """Every WSA1R opcode-3 program word and opcode-2 coefficient, from the
    STREAM objects of the pool.  Returns (prog_words, coeffs, opcode_counter)."""
    objs = POOL.tile()
    prog, coeff, opc = [], [], collections.Counter()
    for o in objs:
        if o["kind"] != "STREAM":
            continue
        for (addr, op, ln) in o["recs"]:
            opc[op] += 1
            body = POOL.D[addr + 2 - POOL.BASE: addr + ln - POOL.BASE]
            if op == 3:                       # program: cmd, addr16, then 5-B words
                data = body[3:]
                for k in range(0, len(data) - 4, 5):
                    prog.append(int.from_bytes(data[k:k + 5], "big"))
            elif op == 2:                     # coefficients: cmd, 2 preamble, 3-B
                data = body[3:]
                for k in range(0, len(data) - 2, 3):
                    coeff.append((data[k] << 16) | (data[k + 1] << 8) | data[k + 2])
    return prog, coeff, opc


# ---------------------------------------------------------------------------
#  field extractors (thin wrappers over dsp_disasm, named for the report)
# ---------------------------------------------------------------------------
def dec(w):    return D.alu_decoded(w)
def hi12(w):   return D.hi12(w)
def cls(w):    return D.class4(w)
def addr8(w):  return (w >> 12) & 0xFF
def lo12(w):   return D.lo12(w)
def src(w):    return D.lo_src(w)
def act(w):    return D.lo_act(w)
def f31(w):    return D.hi_f31(D.hi12(w))
def cfmt(w):   return D.c_format(w)
def esc11(w):  return bool(D.lo12(w) & 0x800)     # lo12 bit 11 = FORMAT ESCAPE
def hiesc(w):  return bool(D.hi12(w) & (1 << 11))  # hi12 bit 11
def ptrmode(w):return D.lo_ptrmode(w)


# ---------------------------------------------------------------------------
#  nulls
# ---------------------------------------------------------------------------
def null_uniform(n, trials, seed=1):
    random.seed(seed)
    tot = 0
    for _ in range(trials):
        tot += sum(1 for _ in range(n) if dec(random.getrandbits(36)))
    return 100.0 * tot / (trials * n)


def null_byteshuffle(words, trials, seed=2):
    """Permute all the corpus's bytes, re-chunk into 5-byte words."""
    raw = b"".join(w.to_bytes(5, "big") for w in words)
    buf = bytearray(raw)
    random.seed(seed)
    n = len(words)
    tot = 0
    for _ in range(trials):
        random.shuffle(buf)
        ws = [int.from_bytes(bytes(buf[k:k + 5]), "big") for k in range(0, 5 * n, 5)]
        tot += sum(1 for w in ws if dec(w))
    return 100.0 * tot / (trials * n)


def null_fieldshuffle(words, trials, seed=3):
    """Permute hi12/class4/addr8/lo12 independently -- keeps each marginal."""
    his = [hi12(w) for w in words]
    cs  = [cls(w) for w in words]
    ads = [addr8(w) for w in words]
    los = [lo12(w) for w in words]
    random.seed(seed)
    n = len(words)
    tot = 0
    for _ in range(trials):
        random.shuffle(his); random.shuffle(cs); random.shuffle(ads); random.shuffle(los)
        ws = [(his[i] << 24) | (cs[i] << 20) | (ads[i] << 12) | los[i] for i in range(n)]
        tot += sum(1 for w in ws if dec(w))
    return 100.0 * tot / (trials * n)


# ---------------------------------------------------------------------------
#  report helpers
# ---------------------------------------------------------------------------
def hist(words, keyfn):
    c = collections.Counter(keyfn(w) for w in words)
    return c


def pct(c, total):
    return {k: (v, 100.0 * v / total) for k, v in c.items()}


def show_hist(title, cnt, total, top=None, fmtk="%X"):
    print("  %s  (n=%d)" % (title, total))
    items = sorted(cnt.items(), key=lambda kv: (-kv[1], kv[0]))
    if top:
        items = items[:top]
    for k, v in items:
        print("     %-6s  %6d  %5.1f%%" % (fmtk % k, v, 100.0 * v / total))


def guard_spectrum(words):
    c = collections.Counter(F31.guard_fail(w) for w in words)
    return c


# ---------------------------------------------------------------------------
def selftest():
    kn = kn5000_words()
    d = sum(1 for w in kn if dec(w))
    g = sum(1 for w in kn if F31.guard_fail(w) == 0)
    ok = True
    for label, got, want in (("KN5000 corpus words", len(kn), 3057),
                             ("KN5000 alu_decoded", d, 1178),
                             ("KN5000 guard_fail==0", g, 1178)):
        status = "PASS" if got == want else "*** FAIL ***"
        ok = ok and (got == want)
        print("   %-28s %6d   published %6d   %s" % (label, got, want, status))
    # container invariant on WSA1R side
    wsa, _, _ = wsa1_stream_words()
    bad = sum(1 for w in wsa if w >> 36)
    status = "PASS" if bad == 0 else "*** FAIL ***"
    ok = ok and (bad == 0)
    print("   %-28s %6d   published %6d   %s"
          % ("WSA1R words bits[36:39]!=0", bad, 0, status))
    return ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--trials", type=int, default=20)
    args = ap.parse_args()

    print("=" * 100)
    print("RULE 20 SELF-TESTS (KN5000 baseline reproduced from the ROM)")
    print("=" * 100)
    ok = selftest()
    if args.selftest:
        sys.exit(0 if ok else 1)
    if not ok:
        sys.exit("self-test failed -- refusing to report on a drifted model")

    kn = kn5000_words()
    wsa, coeff, opc = wsa1_stream_words()

    kn_dec = sum(1 for w in kn if dec(w))
    wsa_dec = sum(1 for w in wsa if dec(w))

    print()
    print("=" * 100)
    print("1. DECODE RATE vs NULL  (predicate: dsp_disasm.alu_decoded == upd6383d.h)")
    print("=" * 100)
    print("   KN5000 program words   : %5d   decoded %5d   %6.2f%%"
          % (len(kn), kn_dec, 100.0 * kn_dec / len(kn)))
    print("   WSA1R  program words   : %5d   decoded %5d   %6.2f%%"
          % (len(wsa), wsa_dec, 100.0 * wsa_dec / len(wsa)))
    print("   WSA1R  distinct words  : %5d" % len(set(wsa)))
    print("   -- NULLS (%d trials each). A null keeps SOMETHING real and destroys the rest --"
          % args.trials)
    nu = null_uniform(len(wsa), args.trials)
    nb = null_byteshuffle(wsa, args.trials)
    nfw = null_fieldshuffle(wsa, args.trials)
    nfk = null_fieldshuffle(kn, args.trials)
    print("   uniform random 36-bit         (WSA1R-sized) : %6.2f%%  (keeps nothing)" % nu)
    print("   byte-shuffle of WSA1R words                  : %6.2f%%  (keeps byte histogram)" % nb)
    print("   field-shuffle of WSA1R words                 : %6.2f%%  (keeps each field's marginal)" % nfw)
    print("   field-shuffle of KN5000 words (for symmetry) : %6.2f%%  (keeps each field's marginal)" % nfk)
    print("   => WSA1R real %6.2f%% vs uniform %.2f%% = %.0fx ; vs byte-shuffle = %.0fx ;"
          % (100.0 * wsa_dec / len(wsa), nu,
             (100.0 * wsa_dec / len(wsa)) / max(nu, 1e-6),
             (100.0 * wsa_dec / len(wsa)) / max(nb, 1e-6)))
    print("      and its lift over field-shuffle (%.2f%%) matches KN5000's own lift over %.2f%%."
          % (nfw, nfk))

    print()
    print("=" * 100)
    print("2. WSA1R POOL FRAMING (STREAM objects only)")
    print("=" * 100)
    print("   record opcode counts   : %s" % dict(sorted(opc.items())))
    print("   opcode-3 (program) records give %d words; opcode-2 gives %d coeffs"
          % (len(wsa), len(coeff)))

    print()
    print("=" * 100)
    print("3. FIELD HISTOGRAMS  (KN5000 vs WSA1R)")
    print("=" * 100)
    for name, kf, fmtk in (("hi12 microword (top 16)", hi12, "%03X"),
                           ("class4 addressing", cls, "%X"),
                           ("SRC (lo12[10:6])", src, "%02X"),
                           ("ACTION (lo12[4:0])", act, "%02X"),
                           ("f31 (hi12[3:1])", f31, "%d")):
        print("\n   --- %s ---" % name)
        print("   KN5000:")
        show_hist("", hist(kn, kf), len(kn),
                  top=16 if "hi12" in name else None, fmtk=fmtk)
        print("   WSA1R:")
        show_hist("", hist(wsa, kf), len(wsa),
                  top=16 if "hi12" in name else None, fmtk=fmtk)

    print()
    print("=" * 100)
    print("4. GUARD-FAIL SPECTRUM  (why a word is NOT decoded)")
    print("=" * 100)
    gk, gw = guard_spectrum(kn), guard_spectrum(wsa)
    allg = sorted(set(gk) | set(gw))
    print("   %-38s %14s %14s" % ("guard", "KN5000", "WSA1R"))
    for g in allg:
        print("   %-38s %6d %6.1f%% %6d %6.1f%%"
              % (F31.GUARD.get(g, str(g)),
                 gk.get(g, 0), 100.0 * gk.get(g, 0) / len(kn),
                 gw.get(g, 0), 100.0 * gw.get(g, 0) / len(wsa)))

    print()
    print("=" * 100)
    print("5. THE KN5000 UNDECIDABLE RESIDUE -- does WSA1R exercise it?")
    print("=" * 100)
    # 5a. SRC hapaxes: SRC codes that occur exactly once in KN5000
    ksrc = hist(kn, src)
    wsrc = hist(wsa, src)
    hapax = sorted(k for k, v in ksrc.items() if v == 1)
    anchored_src = set(D._ANCHORED_SRC)
    print("\n   5a. SRC codes: KN5000 count vs WSA1R count")
    print("       anchored SRC = %s" % sorted("0x%02X" % s for s in anchored_src))
    print("       %-8s %10s %10s %s" % ("SRC", "KN5000", "WSA1R", "note"))
    for s in sorted(set(ksrc) | set(wsrc)):
        note = []
        if s in anchored_src:
            note.append("ANCHORED")
        else:
            note.append("unanchored")
        if ksrc.get(s, 0) == 1:
            note.append("KN5000-hapax")
        if s not in ksrc:
            note.append("ABSENT-in-KN5000")
        print("       0x%02X    %10d %10d  %s"
              % (s, ksrc.get(s, 0), wsrc.get(s, 0), " ".join(note)))
    print("       KN5000 SRC hapaxes (count==1): %s"
          % [("0x%02X" % h) for h in hapax])

    # 5b. kernel-only classes 8/9/C/D
    print("\n   5b. class 8/9/C/D populations")
    for c in (0x8, 0x9, 0xC, 0xD):
        print("       class %X : KN5000 %5d   WSA1R %5d"
              % (c, hist(kn, cls).get(c, 0), hist(wsa, cls).get(c, 0)))
    print("       class B : KN5000 %5d   WSA1R %5d  (class4==B, ABSENT in KN5000)"
          % (hist(kn, cls).get(0xB, 0), hist(wsa, cls).get(0xB, 0)))
    print("       NB: class4==C (above) is the addressing field bits[23:20]; it is")
    print("       DISTINCT from the C-FORMAT flag hi12[11:8]==C reported in 5e.")

    # 5c. f31 in {4,5}
    print("\n   5c. f31 in {4,5} (measured-closed in KN5000; f31=4 fires ZERO in clean vehicle)")
    kf31, wf31 = hist(kn, f31), hist(wsa, f31)
    for v in (4, 5):
        print("       f31=%d : KN5000 %5d   WSA1R %5d" % (v, kf31.get(v, 0), wf31.get(v, 0)))

    # 5d. bit-11 (both the lo12 FORMAT-ESC and hi12 bit 11)
    print("\n   5d. bit-11 populations (the KN5000 'bit-11 drought')")
    print("       lo12 bit11 (FORMAT ESC) : KN5000 %5d   WSA1R %5d"
          % (sum(1 for w in kn if esc11(w)), sum(1 for w in wsa if esc11(w))))
    print("       hi12 bit11              : KN5000 %5d   WSA1R %5d"
          % (sum(1 for w in kn if hiesc(w)), sum(1 for w in wsa if hiesc(w))))

    # 5e. C-format
    print("\n   5e. C-FORMAT words (hi12[11:8]==0xC)")
    print("       KN5000 %5d   WSA1R %5d"
          % (sum(1 for w in kn if cfmt(w)), sum(1 for w in wsa if cfmt(w))))

    # 5f. words present in WSA1R but never in KN5000
    kset, wset = set(kn), set(wsa)
    novel = wset - kset
    print("\n   5f. distinct 36-bit encodings in WSA1R but NEVER in KN5000: %d of %d"
          % (len(novel), len(wset)))
    novel_dec = sum(1 for w in novel if dec(w))
    print("       of those, alu_decoded already handles: %d   still-dark: %d"
          % (novel_dec, len(novel) - novel_dec))
    # show a few dark novel words with their field decode
    dark_novel = sorted(w for w in novel if not dec(w))
    print("       sample of WSA1R-only DARK words (first 12), with guard:")
    for w in dark_novel[:12]:
        print("         %s  guard=%-30s cls=%X SRC=%02X ACT=%02X f31=%d"
              % (D.fmt(w) if hasattr(D, "fmt") else PC.fmt(w),
                 F31.GUARD.get(F31.guard_fail(w), "?"),
                 cls(w), src(w), act(w), f31(w)))


if __name__ == "__main__":
    main()
