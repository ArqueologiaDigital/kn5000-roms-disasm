#!/usr/bin/env python3
r"""hdae5000_symbolize_ui_objects.py -- UI object ids as named constants.

QUESTION ANSWERED / JOB IT DOES
-------------------------------
The HD-AE5000 code names its UI objects to the main CPU as 32-bit ids
0x007F0000 + n (`ld xwa,0x007f02c1` before a workspace call, `.long
0x007f0145` in the list screens' id pairs).  n indexes HDAE5000_UiObject_
PtrTable, and HDAE5000_UiObjectName_PtrTable gives 178 of the objects a name
string in the ROM ("HD_PLEASE", "ERR_LOAD", "RAM_EDIT_LSW", "PP_STATUS" ...).

This tool
  * writes one `.equ HDAE5000_OBJ_<name>, 0x007F0000 + n` per named object,
    generated from the table rows themselves, in a block just before
    HDAE5000_UiObjectName_PtrTable (hdae5000_data_tables.s);
  * replaces every 0x007Fnnnn immediate / .long value in the code and in the
    .rodata whose n has a name by that constant (the encoding is the same:
    the value is the same number).
Ids of unnamed objects stay numeric.  With no argument it prints the counts;
--apply rewrites and re-links through scripts/analysis/hdae5000_line_map.py,
which refuses unless the tree is byte-identical.

RUN
    python3 scripts/converters/hdae5000_symbolize_ui_objects.py [--apply]
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import hdae5000_line_map as hlm  # noqa: E402

DT = "hdae5000_data_tables.s"
ROW = re.compile(r'^\s*\.long\s+HdaeUiName_(\d+)\s*;\s*\[\s*(\d+)\]\s*"([^"]*)"')
IMM = re.compile(r"(?<![\w.$])0x0*7[fF]([0-9a-fA-F]{4})\b")


def main(apply):
    src = {rel: open(os.path.join(hlm.HDAE, rel), encoding="latin-1").read().split("\n") for rel in hlm.FILES}
    names = {}
    for ln in src[DT]:
        m = ROW.match(ln)
        if m and m.group(3):
            n = int(m.group(2))
            if int(m.group(1)) != n:
                sys.exit("REFUSED: row index mismatch in %r" % ln)
            names[n] = m.group(3)
    if len(set(names.values())) != len(names):
        sys.exit("REFUSED: duplicate object names")
    sym = {n: "HDAE5000_OBJ_" + nm for n, nm in names.items()}
    counts = collections.Counter()
    for rel, L in src.items():
        for i, ln in enumerate(L):
            code, sep, com = ln.partition(";")
            if not code.strip() or re.match(r"\s*\.(equ|set)\b", code):
                continue
            if rel == DT and not re.match(r"\s*\.long\b", code):
                continue

            def sub(m):
                n = int(m.group(1), 16)
                if n in sym:
                    counts[rel] += 1
                    return sym[n]
                counts["unnamed"] += 1
                return m.group(0)
            new = IMM.sub(sub, code)
            if new != code:
                L[i] = new + sep + com
    print("named objects %d; ids replaced %s" % (len(names), dict(counts)))
    if not apply:
        return
    L = src[DT]
    at = next(i for i, ln in enumerate(L) if ln.startswith("HDAE5000_UiObjectName_PtrTable:"))
    # insert before the comment block that heads the table
    j = at
    while j > 0 and L[j - 1].startswith(";"):
        j -= 1
    block = [";",
             "; UI object ids: the main CPU knows each HD-AE5000 UI object as 0x007F0000 + n,",
             "; n = its index in HDAE5000_UiObject_PtrTable.  One constant per object that",
             "; HDAE5000_UiObjectName_PtrTable names (%d of them), named after that string;" % len(names),
             "; generated from the table rows by scripts/converters/hdae5000_symbolize_ui_objects.py.",
             ";"]
    for n in sorted(names):
        block.append("\t.equ %s, 0x%08x" % (sym[n], 0x007F0000 + n))
    L[j:j] = block + [""]
    for rel, L in src.items():
        open(os.path.join(hlm.HDAE, rel), "w", encoding="latin-1").write("\n".join(L))
    hlm.build_map()
    print("applied; relinked mirror byte-identical")


if __name__ == "__main__":
    main("--apply" in sys.argv[1:])
