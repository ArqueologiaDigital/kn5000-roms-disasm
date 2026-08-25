#!/usr/bin/env python3
"""How many display layers does the WSA1 really have, and who selects them?

QUESTION IT ANSWERS: notes/FINDINGS-display-controller.md ended with "Nothing
yet writes (0x2540).  Finding that writer names the three layers."  (0x2540) is
the byte LCD_SelectCurrentLayer scales by 4 to index a THREE-entry table of
layer base pointers at 0xF8EEB1, and until now the "three" rested on one
argument: a fourth entry would overlap the first instruction of SWI7 service
0x05.  That is sound but it is a single point of failure.

This censuses every access to (0x2540) in both images and asks what values the
firmware ever puts there.

    python3 notes/lcd_layer_census.py            # the histogram
    python3 notes/lcd_layer_census.py --sites    # every address
    python3 notes/lcd_layer_census.py --check    # exits non-zero if it drifted

★ THE ANSWER, AND WHY IT IS TRUSTWORTHY DESPITE BEING A BYTE CENSUS.  This is a
byte-pattern search, not an instruction-boundary scan, exactly like
notes/prom_a_xref.py -- so on its own a hit could be bytes inside some other
instruction.  What makes the result solid is the DISTRIBUTION.  Across both
ROMs the pattern `F1 40 25 00 nn` -- `ld (0x2540),#nn` -- matches many hundreds
of times, and the immediate `nn` takes exactly THREE values: 0, 1 and 2.  If
these were coincidental byte sequences the fifth byte would be spread over
0..255; instead it never once exceeds 2.  A census that cannot tell code from
data still cannot manufacture that.

Independently, exactly one of the prom_a sites falls inside source this tree has
already converted -- 0xF8EEBD, the first instruction of LCD_Svc_05_FillRect,
where it is written out as `stdi8 (0x2540), 0x01`.  So at least one hit is
confirmed to be a real instruction at a real boundary, by the byte gate itself.

Opcode meanings are read out of MAME's tables rather than remembered: with a
0xF1 prefix (16-bit direct address, memory destination) opcode 0x00 is
op_LDBMI (`ld (mem),#imm8`), 0x40-0x47 op_LDBMR (`ld (mem),r`) and 0x30-0x37
op_LDAL (`lda r,mem`, i.e. take the ADDRESS); with a 0xC1 prefix opcode
0x20-0x27 is op_LDBRM (`ld r,(mem)`).
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAME = "/home/fsanches/compartilhado/mame/src/devices/cpu/tlcs900/900tbl.hxx"
IMGS = (("prom_a", 0xF80000, os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")),
        ("prom_b", 0xF00000, os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")))
ADDR = 0x2540


def mame_table(name):
    src = open(MAME).read()
    i = src.index("s_mnemonic_%s[256] =" % name)
    return re.findall(r"&tlcs900_device::(\w+)", src[i:src.index("};", i)])


def census():
    f0, c0 = mame_table("f0"), mame_table("c0")
    key = bytes([ADDR & 0xFF, ADDR >> 8])
    imm = collections.Counter()
    sites = collections.defaultdict(list)
    for tag, base, path in IMGS:
        d = open(path, "rb").read()
        i = 0
        while True:
            i = d.find(key, i)
            if i < 0:
                break
            if i:
                p, op = d[i - 1], d[i + 2]
                at = base + i - 1
                if p == 0xF1 and f0[op] == "op_LDBMI":
                    imm[d[i + 3]] += 1
                    sites["write imm"].append((tag, at, d[i + 3]))
                elif p == 0xF1 and f0[op] == "op_LDBMR":
                    sites["write reg"].append((tag, at, None))
                elif p == 0xF1 and f0[op] == "op_LDAL":
                    sites["take address"].append((tag, at, None))
                elif p == 0xC1 and c0[op] == "op_LDBRM":
                    sites["read"].append((tag, at, None))
                elif p in (0xC1, 0xD1, 0xE1, 0xF1):
                    sites["other %02X/%02X" % (p, op)].append((tag, at, None))
            i += 1
    return imm, sites


def main():
    imm, sites = census()
    print("accesses to (0x%04X), both images:" % ADDR)
    for k in sorted(sites):
        pa = sum(1 for t, _, _ in sites[k] if t == "prom_a")
        print("  %-14s %4d   (prom_a %d, prom_b %d)"
              % (k, len(sites[k]), pa, len(sites[k]) - pa))
    print()
    print("  ★ the immediate written, over %d sites:" % sum(imm.values()))
    for v in sorted(imm):
        print("       layer %d : %4d sites" % (v, imm[v]))
    print("  distinct values: %d   highest: %d" % (len(imm), max(imm)))
    if "--sites" in sys.argv:
        for k in sorted(sites):
            for t, a, v in sites[k]:
                print("    %-14s %s 0x%06X%s"
                      % (k, t, a, "" if v is None else "  #%d" % v))
    if "--check" in sys.argv:
        bad = []
        if sorted(imm) != [0, 1, 2]:
            bad.append("immediate values are %s, not [0, 1, 2]" % sorted(imm))
        if sum(imm.values()) < 700:
            bad.append("only %d immediate sites" % sum(imm.values()))
        # the one site that is confirmed to be a real instruction
        if not any(a == 0xF8EEBD and v == 1 for t, a, v in sites["write imm"]):
            bad.append("0xF8EEBD (LCD_Svc_05_FillRect) is not in the census")
        src = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")).read()
        if "stdi8 (0x2540), 0x01                          ; F8EEBD" not in src:
            bad.append("the converted source no longer spells 0xF8EEBD that way")
        for b in bad:
            print("FAIL", b)
        print("\n%d checks failed" % len(bad))
        sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
