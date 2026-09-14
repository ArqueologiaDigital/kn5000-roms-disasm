#!/usr/bin/env python3
"""ACTION-field census: how many `lo12[4:0] == X` sites are words where lo12[4:0]
IS the ACTION field, and how many are words where it is NOT.

QUESTION ANSWERED
-----------------
"ACT 0x0B has 159 words" style counts are the usual way an ACTION axis is sized.
This tool says how much of such a count is an artefact of reading lo12[4:0] on
words that have no ACTION field at all:

  * hi12 bit 11 set  = FORMAT ESCAPE -- instruction-set.md 'hi12' table, row 11:
    "bits[10:0] mean something else" (MEASURED).  Mode-1+ESCAPE is the external
    delay-DRAM family (276/3057, MEASURED by R2).
  * hi12[11:8] == 0xC = C-FORMAT -- class4/addr8/lo12 are immediate DATA
    (MEASURED, notes/kn5000-dsp-header.md sect. 6), so there is no lo12 at all.
  * lo12 bit 11 set  = the bit-11 family -- analysis/bit11-family.md item A:
    `alu_decoded()` refuses these "because lo12 is not the ALU route there".

Only the CLEAN column is a site where a decode of the ACTION code buys a word.

SIGNAL READ
-----------
The 10-hex-digit microword printed by the generated disassembly listings
(`  wNNN  HHHHHHHHHH  ...`).  Fields per instruction-set.md 'Word format':
hi12 = bits[35:24], class4 = bits[23:20], addr8 = bits[19:12], lo12 = bits[11:0].

RUN
---
    python3 dsp/tools/act_field_census.py              # the 7-code ACTION axis
    python3 dsp/tools/act_field_census.py 0B 1A 1B     # any codes you like

Measured 2026-09-14 on both trees (7-code axis 0B,1A,1B,1D,11,17,16):

    KN5000 IC311 (3057 w):  119 sites =  10 C-fmt +  60 ESCAPE +  49 CLEAN
    WSA1R        (4946 w):  196 sites =   8 C-fmt + 131 ESCAPE +  57 CLEAN

    ACT 0x0B on the WSA1R is 131 sites of which 115 are ESCAPE -> 16 CLEAN.
    ACT 0x16 has ZERO sites in the whole 4946-word WSA1R corpus.
"""
import collections
import glob
import os
import re
import sys

WORD_RE = re.compile(r'^\s+w\d+\s+([0-9A-F]{10})\b')
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TREES = (("KN5000 IC311", "dsp/disasm/*.dsm"), ("WSA1R", "wsa1/dsp/disasm/*.dsm"))


def words(pattern):
    for path in sorted(glob.glob(os.path.join(ROOT, pattern))):
        with open(path, errors="ignore") as fh:
            for line in fh:
                m = WORD_RE.match(line)
                if m:
                    yield int(m.group(1), 16)


def bucket(w):
    """Which reading of lo12[4:0] applies to this word."""
    hi12 = (w >> 24) & 0xFFF
    if (hi12 >> 8) == 0xC:
        return "C-fmt"          # no class4/addr8/lo12: they are immediate data
    if hi12 & 0x800:
        return "ESCAPE"         # hi12 bit 11: bits[10:0] mean something else
    if (w & 0xFFF) & 0x800:
        return "lo12b11"        # the bit-11 family: lo12 is not the ALU route
    return "CLEAN"


def main(codes):
    cols = ("C-fmt", "ESCAPE", "lo12b11", "CLEAN")
    for name, pattern in TREES:
        corpus = list(words(pattern))
        tally = collections.defaultdict(collections.Counter)
        for w in corpus:
            act = w & 0x1F
            if act in codes:
                tally[act][bucket(w)] += 1
        print("--- %s: %d words in the listings" % (name, len(corpus)))
        print("%5s %6s %6s %7s %8s %6s" % ("ACT", "sites", *cols))
        total = collections.Counter()
        for act in sorted(codes):
            row = tally[act]
            total.update(row)
            print("0x%02X %6d %6d %6d %7d %8d"
                  % (act, sum(row.values()), *(row[c] for c in cols)))
        print("%5s %6d %6d %6d %7d %8d\n"
              % ("SUM", sum(total.values()), *(total[c] for c in cols)))


if __name__ == "__main__":
    args = sys.argv[1:]
    main({int(a, 16) for a in args} if args else {0x0B, 0x1A, 0x1B, 0x1D, 0x11, 0x17, 0x16})
