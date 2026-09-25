#!/usr/bin/env python3
r"""sequi_log_regcheck.py -- in a sequi_reframe.py log, does every replaced
instruction name the same REGISTERS as MAME unidasm's reading of its bytes?

QUESTION THIS ANSWERS
    A byte-exact round trip cannot see a disassembler that prints the wrong
    register for the right bytes (the LLVM disassembler printed
    `cpda8 xbc, (0x32f6)` for c1 f6 32 f1, which is `cp A,(0x32f6)`).  The
    re-frame logs record `ADDR  new-text  || unidasm: <reading>` for every
    replaced instruction; this compares the register FAMILIES (a/w/wa/xwa ->
    wa, ...) of the two texts and prints the lines where both name registers
    and the sets differ.  Expected, harmless differences: extended-register
    moves spelled with a numeric code (`ldb_erp l, 250` = unidasm
    `ld QIZL,L`), and SRI forms whose index registers are raw bytes
    (`cpl_sri_rm xwa, 0x07, 0xf0, 0xf4` = `cp XWA,(XIX+IY)`).

RUN
    python3 scripts/analysis/sequi_log_regcheck.py notes/sequi-2026-09-25/reframe-*.log
"""
import re
import sys

FAM = {}
for fam, names in {"wa": "a w wa xwa qwa qa qw", "bc": "b c bc xbc qbc qb qc",
                   "de": "d e de xde qde qd qe", "hl": "h l hl xhl qhl qh ql",
                   "ix": "ix xix qix ixl ixh", "iy": "iy xiy qiy iyl iyh",
                   "iz": "iz xiz qiz izl izh qizh qizl", "sp": "sp xsp"}.items():
    for n in names.split():
        FAM[n] = fam


def fams(t):
    t = t.split(";")[0].lower().strip()
    t = t.split(None, 1)[1] if len(t.split(None, 1)) > 1 else ""
    return {FAM[x] for x in re.findall(r'(?<![\w.$])([a-z]+)(?![\w.$:])', t) if x in FAM}


def main():
    n = bad = 0
    for f in sys.argv[1:]:
        for ln in open(f, encoding="latin-1"):
            m = re.match(r'\s+0x([0-9A-F]+)\s+(.*?)\s+\|\| unidasm: (.*)$', ln.rstrip())
            if not m:
                continue
            n += 1
            a, b = fams(m.group(2)), fams(m.group(3))
            if a and b and a != b:
                bad += 1
                print("%s 0x%s  %s  ||  %s" % (f.split("/")[-1], m.group(1), m.group(2), m.group(3)))
    print("%d replaced instruction(s), %d with differing register families" % (n, bad))


if __name__ == "__main__":
    main()
