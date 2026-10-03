#!/usr/bin/env python3
r"""respell_symbolic_dd8.py -- direct-page pseudos whose address is already an SFR NAME, spelled natively.

QUESTION THIS ANSWERS / WHAT IT DOES
    respell_raw_pseudos.py rewrites `set_dd8 0, 0x44` to `set 0, (0x44:8)`.  It refuses a line
    with a symbolic operand, because unidasm's reading would put a number where the name was.
    symbolize_v142_sfr_operands.py (2026-09-25) had already named v142's SFR operands, so v142 and
    the sub-CPU boot ROM keep `set_dd8 0, PH`.  This rewrites those lines from fixed templates.
    Each template was assembled against its pseudo with the pinned llvm-mc and gives the same
    bytes, e.g. `set_dd8 3, PH` and `set 3, (PH:8)` are both f0 44 bb.  The byte gate then proves
    the tree:

        X_dd8 N, NAME       ->  X N, (NAME:8)       X = set res bit stcf ldcf xorcf chg
        lda_dd8l XRR, NAME  ->  lda xrr, (NAME:8)
        and_sd8b_im NAME, I ->  and (NAME:8), I      (and or_sd8b_im -> or)
        st_dd8b R, NAME     ->  ld (NAME:8), r
        ld_sd8b R, NAME     ->  ld r, (NAME:8)

    A NAME is any identifier that is not a register.  A numeric operand is left to
    respell_raw_pseudos.py.

RUN
    python3 scripts/converters/respell_symbolic_dd8.py --tree v142 [--apply]; make gate-all
"""
import argparse
import collections
import glob
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
REGS = {"a", "w", "b", "c", "d", "e", "h", "l", "wa", "bc", "de", "hl", "ix", "iy", "iz", "sp",
        "xwa", "xbc", "xde", "xhl", "xix", "xiy", "xiz", "xsp"}
PRE = r'(?P<pre>\s*(?:[A-Za-z_.$][\w.$]*:)?\s*)'
NAME = r'(?P<n>[A-Za-z_]\w*)'
POST = r'(?P<post>\s*(?:;.*)?)$'
RULES = [
    (re.compile(PRE + r'(?P<m>set|res|bit|stcf|ldcf|xorcf|chg)_dd8\s+(?P<b>[0-7])\s*,\s*' + NAME + POST, re.I),
     lambda m: "%s\t%s, (%s:8)" % (m["m"].lower(), m["b"], m["n"])),
    (re.compile(PRE + r'lda_dd8l\s+(?P<r>x[a-z]{2})\s*,\s*' + NAME + POST, re.I),
     lambda m: "lda\t%s, (%s:8)" % (m["r"].lower(), m["n"])),
    (re.compile(PRE + r'(?P<m>and|or)_sd8b_im\s+' + NAME + r'\s*,\s*(?P<i>0x[0-9a-fA-F]+|\d+)' + POST, re.I),
     lambda m: "%s\t(%s:8), %s" % (m["m"].lower(), m["n"], m["i"].lower())),
    (re.compile(PRE + r'st_dd8b\s+(?P<r>[a-z])\s*,\s*' + NAME + POST, re.I),
     lambda m: "ld\t(%s:8), %s" % (m["n"], m["r"].lower())),
    (re.compile(PRE + r'ld_sd8b\s+(?P<r>[a-z])\s*,\s*' + NAME + POST, re.I),
     lambda m: "ld\t%s, (%s:8)" % (m["r"].lower(), m["n"])),
]


def _write(path, data):
    tmp = path + ".tmp-respelldd8"
    with open(tmp, "wb") as fh:
        fh.write(data)
    os.replace(tmp, path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True)
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    stats = collections.Counter()
    for p in sorted(glob.glob(os.path.join(ROOT, a.tree, "**", "*.s"), recursive=True)):
        L = open(p, "rb").read().decode("latin-1").split("\n")
        n = 0
        for i, l in enumerate(L):
            for rx, fmt in RULES:
                m = rx.match(l)
                if m and m["n"].lower() not in REGS:
                    L[i] = m["pre"] + fmt(m) + m["post"]
                    stats[fmt(m).split("\t")[0]] += 1
                    n += 1
                    break
        if n:
            print("%-50s %4d" % (os.path.relpath(p, ROOT), n))
            if a.apply:
                _write(p, "\n".join(L).encode("latin-1"))
    print("tree %s: %d lines %s%s" % (a.tree, sum(stats.values()), dict(stats), "" if a.apply else " (dry run)"))


if __name__ == "__main__":
    main()
