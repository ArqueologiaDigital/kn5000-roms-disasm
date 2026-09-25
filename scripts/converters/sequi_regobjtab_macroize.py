#!/usr/bin/env python3
r"""sequi_regobjtab_macroize.py -- spell v7's hand-expanded RegisterObjectTable
records with the RegObjTable / RegObjTabl macros v10 uses.

QUESTION THIS ANSWERS
    v7's InitializeKubo (sequencer/sequencer_ui.s) registers ~80 object tables
    with the instruction sequence the RegObjTable / RegObjTabl macros
    (display/scoop_display.s) expand to, written out by hand -- 11 lines per
    record, ~870 lines -- while v10's copy of the routine uses the macros.  Can
    v7 use the same macros, so the v7/v10 diff of the routine shows only real
    differences?

HOW
    Finds maximal runs of this 11-line group (case-insensitive, whitespace
    tolerant):

        lda XBC, (XSP)
        ld XWA, <A>
        ld (XBC), XWA
        lda xwa, (<B>:24)
        ld (XBC+0x04), XWA
        ld wa, (<C>:24)          -> RegObjTable A, B, C, D, E
          | ldw (XBC+0x08), <C>  -> RegObjTabl  A, B, C, D, E
        [ld (XBC+0x08), WA]      (RegObjTable form only)
        lda xwa, (<D>:24)
        ld (XBC+0x0a), XWA
        ldw WA, <E>
        call RegisterObjectTable

    and replaces each group by one macro line, keeping every operand's
    spelling (symbols stay symbols).  Values are normalised to the lowercase
    hex v10 uses.  A group whose A or E is <= 7 is refused (the macro would
    pick the compact `:i3` encoding and the explicit text may not have).
    The byte gate certifies the result: --apply rebuilds v7 and compares it
    with the dump, restoring the file on any difference.

RUN
    python3 scripts/converters/sequi_regobjtab_macroize.py [--apply]
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PATH = os.path.join(ROOT, "v7/maincpu/sequencer/sequencer_ui.s")

P = [re.compile(x, re.I) for x in (
    r'^\s*lda\s+xbc,\s*\(xsp\)\s*$',
    r'^\s*ld\s+xwa,\s*(?P<A>0x[0-9a-f]+)\s*$',
    r'^\s*ld\s+\(xbc\),\s*xwa\s*$',
    r'^\s*lda\s+xwa,\s*\((?P<B>[\w.$]+):24\)\s*$',
    r'^\s*ld\s+\(xbc\+0x04\),\s*xwa\s*$',
)]
C_TABLE = re.compile(r'^\s*ld\s+wa,\s*\((?P<C>[\w.$]+):24\)\s*$', re.I)
C_TABLE2 = re.compile(r'^\s*ld\s+\(xbc\+0x08\),\s*wa\s*$', re.I)
C_TABL = re.compile(r'^\s*ldw\s+\(xbc\+0x08\),\s*(?P<C>0x[0-9a-f]+)\s*$', re.I)
TAIL = [re.compile(x, re.I) for x in (
    r'^\s*lda\s+xwa,\s*\((?P<D>[\w.$]+):24\)\s*$',
    r'^\s*ld\s+\(xbc\+0x0a\),\s*xwa\s*$',
    r'^\s*ldw\s+wa,\s*(?P<E>0x[0-9a-f]+)\s*$',
    r'^\s*call\s+RegisterObjectTable\s*$',
)]


def norm(v):
    return "0x%x" % int(v, 16) if re.match(r'^0x[0-9a-f]+$', v, re.I) else v


def match_group(L, i):
    """-> (macro_line, next_index) or None."""
    g = {}
    j = i
    for p in P:
        if j >= len(L):
            return None
        m = p.match(L[j])
        if not m:
            return None
        g.update(m.groupdict())
        j += 1
    m = C_TABLE.match(L[j]) if j < len(L) else None
    if m and j + 1 < len(L) and C_TABLE2.match(L[j + 1]):
        mac, g["C"] = "RegObjTable", m.group("C")
        j += 2
    else:
        m = C_TABL.match(L[j]) if j < len(L) else None
        if not m:
            return None
        mac, g["C"] = "RegObjTabl", m.group("C")
        j += 1
    for p in TAIL:
        if j >= len(L):
            return None
        m = p.match(L[j])
        if not m:
            return None
        g.update(m.groupdict())
        j += 1
    for k in ("A", "E"):
        if int(g[k], 16) <= 7:
            return None
    return ("\t%s %s, %s, %s, %s, %s" % (mac, norm(g["A"]), norm(g["B"]), norm(g["C"]),
                                           norm(g["D"]), norm(g["E"])), j)


def main():
    apply = "--apply" in sys.argv
    src = open(PATH, encoding="latin-1").read()
    L = src.split("\n")
    out, i, n = [], 0, 0
    while i < len(L):
        r = match_group(L, i)
        if r:
            out.append(r[0])
            i = r[1]
            n += 1
        else:
            out.append(L[i])
            i += 1
    print("%d record(s) -> macro calls; %d -> %d lines" % (n, len(L), len(out)))
    if not apply or not n:
        return
    open(PATH, "w", encoding="latin-1").write("\n".join(out))
    r = subprocess.run(["make", "rebuilt_ROMs/kn5000_v7_program.llvm.rom"], cwd=ROOT,
                       capture_output=True, text=True)
    ok = r.returncode == 0 and open(os.path.join(ROOT, "rebuilt_ROMs/kn5000_v7_program.llvm.rom"),
                                    "rb").read() == open(os.path.join(
                                        ROOT, "original_ROMs/kn5000_v7_program.rom"), "rb").read()
    if not ok:
        open(PATH, "w", encoding="latin-1").write(src)
        print(r.stderr[-2000:])
        sys.exit("REJECTED: v7 image differs or build failed; file restored")
    print("VERIFIED: v7 byte-identical")


if __name__ == "__main__":
    main()
