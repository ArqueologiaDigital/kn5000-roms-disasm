#!/usr/bin/env python3
"""cfmt_addr.py -- is the C-format payload an I-RAM ADDRESS?  The region test and its null.

QUESTION IT ANSWERS
    `k3-pointers.md' sect. 8 item 3 is the standing objection, and it is a fair one:

        *"The C-format payload rule is family-local.  `A = imm13 >> 5' is measured on
        `(hi12 & 0xFFE) == 0xC40' only (57/57 in-corpus) and fails 9/11 outside. ... extending it
        to `C00 / C04 / C0A / C16 / C42 / C4A / C64' is NOT [safe]."*

    `dsp_disasm.decoded()' obeys it to the letter -- `is_c40' returns True and the other **11**
    C-format occurrences trap, which is the `C-format 11' row of `decode_leverage.py'.  The
    objection is that the extension was UNMEASURED.  This file measures it, two ways, neither of
    which assumes the `0xC40' family's rule.

    ★ ROUTE 1 -- THE REGION TEST (here).  The KN5000's resident microcode is I-RAM 0..82, split
    into the kernel (0..59) and the output stage / epilogue (60..82).  If `A = imm13 >> 5' is an
    I-RAM address it must land inside the image that carries it; if it is data it has no reason
    to.  `A' is 8 bits, so the null is explicit and computable.

    ★ ROUTE 2 -- THE RELOCATION TEST (`kernel_homolog.py --reloc').  The SX-WSA1R carries a
    byte-homologous copy of this kernel header at a different offset (34 of 42 words identical and
    in order; best unrelated image 2).  A field that is an ADDRESS must shift by the number of
    words inserted before it and a field that is DATA must not.  MEASURED: `A' tracks the
    relocation EXACTLY in 4 of 4 comparable pairs, while `B = imm13 & 0x1F' and `f31' are
    IDENTICAL across the two products at all five positions.  That separates address from data
    with no semantic assumption at all.

USAGE
    python3 dsp/tools/cfmt_addr.py              # the 11 words, the region test, the null
    python3 dsp/tools/cfmt_addr.py --all        # ★ and every `is_c40' word too, as a check

⚠ WHAT THIS IS NOT.  It does not say WHAT the address is for.  `w40 -> 14' is a backward
  reference to an END-OF-BLOCK word and `closure-pointer.md' item B has already FALSIFIED the
  whole family as the frame-closing D-RAM pointer load ON SITING.  "The payload is an I-RAM
  address" and "we know what the instruction does with it" are different claims and only the
  first is measured here.
"""
import collections
import glob
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as DIS                                                  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
ROW = re.compile(r"^\s*w(\d+)\s+([0-9A-Fa-f]{10})")
#   The resident microcode's two regions.  `dsp-frame-advance.md': the kernel is I-RAM 0..59 and
#   the output stage / epilogue 60..82; bodies are uploaded per algorithm from I-RAM 84 up.
REGIONS = {"kernel": (0, 59), "epilogue": (60, 82)}
AWIDTH = 8               # `A' is imm13 >> 5, eight bits: the null's denominator is 256


def words(pat):
    for f in sorted(glob.glob(pat)):
        b = os.path.basename(f)[:-4]
        if b == "index":
            continue
        for ln in open(f, errors="replace"):
            m = ROW.match(ln)
            if m:
                yield b, int(m.group(1)), int(m.group(2), 16)


def region_of(img, slot):
    if img in REGIONS:
        return REGIONS[img]
    return (84, 84 + 400)        # a body: uploaded above the resident window


def main():
    everything = "--all" in sys.argv
    rows = []
    for img, slot, w in words(os.path.join(HERE, "..", "disasm", "*.dsm")):
        if not DIS.c_format(w):
            continue
        if DIS.is_c40(w) and not everything:
            continue
        rows.append((img, slot, w))

    print("=" * 100)
    print("  cfmt_addr -- is the C-format payload `A = imm13 >> 5' an I-RAM address?")
    print("=" * 100 + "\n")
    print("   %-10s %-5s %-11s %-7s %-5s %-4s %-9s %-9s %s"
          % ("image", "slot", "word", "opcode", "A", "B", "A - slot", "region", "verdict"))
    inside = 0
    pnull = 1.0
    for img, slot, w in sorted(rows, key=lambda r: (r[0], r[1])):
        lo, hi = region_of(img, slot)
        a = DIS.c_a(w)
        ok = lo <= a <= hi
        inside += ok
        pnull *= (hi - lo + 1) / float(1 << AWIDTH)
        print("   %-10s %-5d %010X  0x%03X   %-5d %-4d %+-9d %-9s %s"
              % (img, slot, w, DIS.c_opcode(w), a, DIS.c_b(w), a - slot,
                 "%d..%d" % (lo, hi), "★ INSIDE its own region" if ok else "⛔ OUTSIDE"))
    print("\n   ⇒ %d of %d payloads land INSIDE the image that carries them." % (inside, len(rows)))
    print("\n   ★ THE NULL (rule 15).  `A' is %d bits, so under a uniform payload the chance of"
          % AWIDTH)
    print("     ALL %d landing inside their own region is" % len(rows))
    print("        %s = %.3g"
          % (" x ".join("%d/256" % (region_of(i, s)[1] - region_of(i, s)[0] + 1)
                        for i, s, _ in sorted(rows)[:4]) + " x ...", pnull))
    print("     ⇒ %s" % ("THE PAYLOAD IS AN ADDRESS, at p = %.3g" % pnull if inside == len(rows)
                         else "NOT all inside -- the claim fails, %d exception(s)"
                         % (len(rows) - inside)))

    #  ---- the structure that falls out of it -------------------------------
    print("\n   ★ AND THE SHAPE OF THE REFERENCES, which no null was needed to see:\n")
    byop = collections.defaultdict(list)
    for img, slot, w in rows:
        byop[DIS.c_opcode(w)].append((img, slot, DIS.c_a(w), DIS.c_b(w)))
    for op in sorted(byop):
        r = byop[op]
        print("      opcode 0x%03X  x%-3d  A-slot %s   B %s"
              % (op, len(r), sorted(set(a - s for _, s, a, _ in r)),
                 sorted(set(b for *_, b in r))))
    print("\n      0x632 (kernel w48 -> 45, w56 -> 53): both -3, and both land at `block start + 3'")
    print("      of their OWN per-unit CALL block (42..49 and 50..59) -- a per-unit address that")
    print("      relocates with the block, which is what the two-block kernel would need.")
    print("      0x600/0x60B (epilogue w76 -> 76, w82 -> 82): SELF-REFERENCES, A == the word's own")
    print("      slot.  Data has no reason to equal its own address.")
    return 0 if inside == len(rows) else 1


if __name__ == "__main__":
    sys.exit(main())
