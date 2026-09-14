#!/usr/bin/env python3
"""kernel_homolog.py -- ★★★ the SX-WSA1R ships a SECOND COPY of the KN5000 KERNEL HEADER.

QUESTION IT ANSWERS
    N-INPUT-GATE-OPENED sect. 120 reduced the LFO rate defect AND the audio input path to ONE word
    -- KN5000 kernel `iw40 = 0C4A1C0820' -- and asked *"what does `w40' DRIVE `P' with?"*.  The
    static corpus of ONE product cannot answer it: `cfmt_opcode.py --control' measures that in the
    KN5000 ROM the C-format opcode is a FUNCTION of (destination, payload), so nothing separates
    them.  ★ The second product does.

    `wsa1/dsp/disasm/struct_00_fd4093.dsm' is a WSA1R I-RAM record the effect directory does not
    name -- catalogued as *"a shared/alternate body (candidates: a second unit's program, an
    alternate reverb tank, or a variant of a named effect)"*.  It is none of those.

        ★★★ IT IS THE KERNEL HEADER.  34 of the KN5000 kernel's first 42 words are
            BYTE-IDENTICAL AND IN ORDER inside it.

    And every place the two copies diverge is a `lo12 = 0x820' word -- the family
    `closure-pointer.md' item H closed a whole pass on with an exhaustive negative:

        KN  w15 op 0x605   <->  WSA w21 op 0x605     same instruction, different payload
        KN  w22 op 0x602   <->  WSA w28 op 0x602     same
        KN  w29 op 0x621   <->  WSA w34 op 0x621     same
        KN  w31 op 0x605   <->  WSA w36 op 0x605     same
      ★ KN  w40 op 0x625   <->  WSA w45 op 0x605     ⛔ THE ONLY ONE THAT DIFFERS

    ★★★★★ Four of the five keep their opcode across two products; the fifth does not -- and the
    fifth is EXACTLY the word sect. 120 isolated from the machine, by a completely independent
    route (a per-slot product invalidate scored on the LFO ramp and the hand-off cell).

    The two words differ in THREE bits, and two of them are inside the 13-bit immediate:

        KN  w40   0C4A1C0820    imm13 = 448  = 14*32     hi12 = 0xC4A
        WSA w45   0C0A5E0820    imm13 = 1504 = 47*32     hi12 = 0xC0A
        xor       0040420000    = word bits 30, 22, 17
                                  bits 22,17 -> the payload;  ★ bit 30 -> `hi12' BIT 6

    ⇒ identical in every field except the payload and ONE FLAG BIT, which the disassembler prints
    as `?6' because nothing has ever decoded it.  `c_opcode' is `hi12 >> 1' and its low three bits
    are `f31' -- both words carry `f31 = 5' -- so the "opcode difference" IS `hi12' bit 6 and
    nothing else.

USAGE
    python3 dsp/tools/kernel_homolog.py           # the alignment + the diverging words
    python3 dsp/tools/kernel_homolog.py --bit6    # ★ the `hi12' bit 6 census, pooled
    python3 dsp/tools/kernel_homolog.py --control # ★ the control -- run it before believing a row

THE CONTROL (rule 15).  "34 words match" means nothing without a null: two programs of the same
ISA share idioms.  `--control' aligns the KN5000 kernel against EVERY other image in both products
and prints the distribution, so the header's score can be read against what an unrelated body
scores.  If a random body also matched 34, the finding would be an artefact of the instrument.

⚠ WHAT THIS IS NOT.  It decodes nothing.  It says the pooled ROM contains a near-minimal pair on
  `hi12' bit 6 at the one slot the machine already flagged, which is a place to point an
  experiment -- and sect. 100 cost three runs to make one experiment fire at all.
"""
import collections
import difflib
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as DIS                                                  # noqa: E402
import class_twins as CT                                                  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
ROW = re.compile(r"^\s*w(\d+)\s+([0-9A-Fa-f]{10})")
KN_KERNEL = os.path.join(HERE, "..", "disasm", "kernel.dsm")
WSA_HOMOLOG = os.path.join(HERE, "..", "..", "wsa1", "dsp", "disasm", "struct_00_fd4093.dsm")
#   sect. 120's word: the one kernel C-format slot whose one-slot product both the LFO ramp and
#   the hand-off cell 0x05 depend on.
SECT120 = 40
#   The KN5000 kernel is 60 words; the header proper ends where the per-unit CALL block begins
#   (w42 = 0801070821, the first `ldptr').  Aligning past it compares a header with a dispatcher.
HEADER_END = 42


def load(path):
    out = {}
    for ln in open(path, errors="replace"):
        m = ROW.match(ln)
        if m:
            out[int(m.group(1))] = int(m.group(2), 16)
    return [out[k] for k in sorted(out)]


def align(a, b):
    sm = difflib.SequenceMatcher(None, ["%010X" % x for x in a], ["%010X" % x for x in b],
                                 autojunk=False)
    return sm.get_opcodes()


def tag(w):
    if DIS.c_format(w):
        return "C-fmt opcode 0x%03X  imm13 %-5d  hi12 %03X  bit6 %d" % (
            DIS.c_opcode(w), DIS.c_imm13(w), DIS.hi12(w), (DIS.hi12(w) >> 6) & 1)
    return "%03X.%X.%02X.%03X" % (DIS.hi12(w), DIS.class4(w), DIS.addr8(w), DIS.lo12(w))


def show_alignment():
    a, b = load(KN_KERNEL)[:HEADER_END], load(WSA_HOMOLOG)
    print("   KN5000 kernel header w0..w%d (%d words)   vs   WSA1R struct_00_fd4093 (%d words)\n"
          % (HEADER_END - 1, len(a), len(b)))
    same = 0
    for op, i1, i2, j1, j2 in align(a, b):
        if op == "equal":
            same += i2 - i1
            print("      == IDENTICAL  KN w%-3d..w%-3d  ==  WSA w%-3d..w%-3d   (%d words)"
                  % (i1, i2 - 1, j1, j2 - 1, i2 - i1))
            continue
        print("      !! %-7s  KN w%-3d..w%-3d      WSA w%-3d..w%-3d" % (op, i1, i2 - 1, j1, j2 - 1))
        for k in range(i1, i2):
            mark = "   ★★★ sect. 120: THE ONE" if k == SECT120 else ""
            print("           KN  w%-3d %010X  %s%s" % (k, a[k], tag(a[k]), mark))
        for k in range(j1, j2):
            print("           WSA w%-3d %010X  %s" % (k, b[k], tag(b[k])))
    print("\n   ⇒ ★★★ %d of %d KN5000 kernel-header words are BYTE-IDENTICAL AND IN ORDER"
          % (same, len(a)))
    print("        inside a WSA1R record the effect directory does not name.")
    return same, a, b


def show_the_pair(a, b):
    kn = a[SECT120]
    #   its WSA1R counterpart is the `lo12 = 0x820' word in the matching divergence
    wsa = None
    for op, i1, i2, j1, j2 in align(a, b):
        if op != "equal" and i1 <= SECT120 < i2:
            for k in range(j1, j2):
                if DIS.lo12(b[k]) == 0x820:
                    wsa = b[k]
    if wsa is None:
        print("\n   ⛔ no counterpart found -- the alignment moved; re-read it above.")
        return
    x = kn ^ wsa
    print("\n   ★★★ THE NEAR-MINIMAL PAIR sect. 120 NEEDED\n")
    print("      KN  w%-3d  %010X   imm13 %-5d  hi12 %03X  f31 %d  bit6 %d"
          % (SECT120, kn, DIS.c_imm13(kn), DIS.hi12(kn), DIS.hi_f31(DIS.hi12(kn)),
             (DIS.hi12(kn) >> 6) & 1))
    print("      WSA      %010X   imm13 %-5d  hi12 %03X  f31 %d  bit6 %d"
          % (wsa, DIS.c_imm13(wsa), DIS.hi12(wsa), DIS.hi_f31(DIS.hi12(wsa)),
             (DIS.hi12(wsa) >> 6) & 1))
    bits = [i for i in range(36) if (x >> i) & 1]
    inpay = [i for i in bits if 12 <= i <= 24]
    print("      xor      %010X   word bits %s" % (x, ", ".join(str(i) for i in bits)))
    print("                            of which %s lie inside the 13-bit immediate (bits 12..24)"
          % (", ".join(str(i) for i in inpay) or "none"))
    out = [i for i in bits if i not in inpay]
    print("      ⇒ OUTSIDE THE PAYLOAD: %s%s"
          % (", ".join("bit %d" % i for i in out) or "nothing",
             "   ★ = `hi12' bit %d" % (out[0] - 24) if len(out) == 1 else ""))
    print("\n      Both carry f31 = %d, so `c_opcode' (= hi12 >> 1, low three bits = f31) differs"
          % DIS.hi_f31(DIS.hi12(kn)))
    print("      in exactly that one flag.  The disassembler prints it `?6'.")


def show_bit6():
    cf, nc = collections.Counter(), collections.Counter()
    clear = []
    for label, img, slots, ws in CT.images():
        for sl, w in zip(slots, ws):
            b6 = (DIS.hi12(w) >> 6) & 1
            if DIS.c_format(w):
                cf[b6] += 1
                if not b6:
                    clear.append((label, img, sl, w))
            else:
                nc[b6] += 1
    print("\n   ★ `hi12' BIT 6 CENSUS, POOLED (KN5000 + SX-WSA1R)\n")
    print("      C-format words      bit6=0 %5d   bit6=1 %5d   <- SET is the common case"
          % (cf[0], cf[1]))
    print("      non-C-format words  bit6=0 %5d   bit6=1 %5d" % (nc[0], nc[1]))
    print("\n      ⇒ on a C-format word bit 6 is SET %.1f %% of the time; CLEAR is the exception,"
          % (100.0 * cf[1] / max(1, cf[0] + cf[1])))
    print("        and the WSA1R's copy of sect. 120's word is one of the exceptions.\n")
    print("      every C-format word with bit 6 CLEAR, by opcode:")
    byop = collections.defaultdict(list)
    for label, img, sl, w in clear:
        byop[DIS.c_opcode(w)].append((label, img, sl, w))
    for op in sorted(byop):
        rows = byop[op]
        los = collections.Counter(DIS.lo12(w) for _, _, _, w in rows)
        print("        0x%03X  x%-4d  lo12 %s" % (op, len(rows),
              " ".join("%03X x%d" % kv for kv in sorted(los.items()))))
    return cf, nc


def show_control():
    """The null: what does the KN5000 kernel header score against an UNRELATED image?"""
    a = load(KN_KERNEL)[:HEADER_END]
    scores = []
    for label, img, slots, ws in CT.images():
        if img == "kernel" and label == "KN":
            continue
        s = sum(i2 - i1 for op, i1, i2, _, _ in align(a, ws) if op == "equal")
        scores.append((s, label, img))
    scores.sort(reverse=True)
    print("\n   ★ CONTROL (rule 15) -- the same alignment against every other image, %d of them\n"
          % len(scores))
    print("      rank  score  image")
    for i, (s, label, img) in enumerate(scores[:8]):
        star = "   ★★★ the homolog" if img == "struct_00_fd4093" else ""
        print("      %-5d %5d  %-7s %s%s" % (i + 1, s, label, img, star))
    rest = [s for s, _, img in scores if img != "struct_00_fd4093"]
    mean = sum(rest) / len(rest)
    top = scores[0][0]
    print("      ...")
    print("      %-5d %5d  %-7s %s" % (len(scores), scores[-1][0], scores[-1][1], scores[-1][2]))
    print("\n      mean over the %d NON-homolog images: %.1f   max: %d   the homolog: %d"
          % (len(rest), mean, max(rest), [s for s, _, img in scores
                                          if img == "struct_00_fd4093"][0]))
    hom = [s for s, _, img in scores if img == "struct_00_fd4093"][0]
    print("      ⇒ %s: the homolog scores %.1fx the mean and %s the best unrelated image."
          % ("THE FINDING SURVIVES ITS NULL" if hom > max(rest) else "⛔ NOT SEPARATED FROM THE NULL",
             hom / mean, "beats" if hom > max(rest) else "does NOT beat"))
    return hom, mean, max(rest)


def main():
    print("=" * 100)
    print("  kernel_homolog -- the WSA1R's unnamed structural record IS the KN5000 kernel header")
    print("=" * 100 + "\n")
    same, a, b = show_alignment()
    show_the_pair(a, b)
    if "--bit6" in sys.argv or "--all" in sys.argv:
        show_bit6()
    if "--control" in sys.argv or "--all" in sys.argv:
        show_control()
    return 0


if __name__ == "__main__":
    sys.exit(main())
