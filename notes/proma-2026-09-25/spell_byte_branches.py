#!/usr/bin/env python3
r"""Spell prom_a's `.byte`-framed branches (`jr`, `djnz`, `calr`, `call (xreg)`) as
instructions with symbolic targets.

QUESTION THIS ANSWERS
    Which `.byte` lines of wsa1/prom_a/wsa1_prom_a.s carry a single branch
    instruction (their trailing comment gives the ROM bytes and unidasm's
    rendering, e.g. `; FA70FC  66 05   jr Z,0xfa7103`), and can each be written as
    that instruction with a LABEL for its target?  A target must be the first
    byte of a source line (address comment present, bytes matching the ROM);
    an existing label there is reused, otherwise `.L<ADDR>:` is inserted.
    The byte gate then checks every displacement, because the assembler computes
    it from the label.

RUN
    python3 notes/proma-2026-09-25/spell_byte_branches.py [--apply]
    make gate-wsa1
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

PAT = re.compile(r'^\t\.byte ([0-9a-fx, ]+?)(\s*);\s*([0-9A-F]{6})\s+((?:[0-9a-f]{2} )+)\s*'
                 r'(jr|djnz|calr|call)\s+([A-Za-z]+,)?\s*([0-9a-fx]+|T,X\w+)\s*$')
LAB = re.compile(r'^([A-Za-z_.$][\w.$]*):')


def main():
    apply_ = "--apply" in sys.argv
    m = srcmap.load()
    L = m.lines
    addr_line = {}
    for i, l in enumerate(L):
        mm = srcmap.ADDR.search(l)
        if mm and not l.lstrip().startswith(";"):
            addr_line.setdefault(int(mm.group(1), 16), i)
    edits, inserts = {}, {}
    for i, l in enumerate(L):
        mm = PAT.match(l)
        if not mm:
            continue
        _, pad, ad, bs, mn, cc, tgt = mm.groups()
        cc = (cc or "").rstrip(",").lower()
        rom = bytes(int(x, 16) for x in bs.split())
        a = int(ad, 16)
        assert m.rom[a - srcmap.BASE:a - srcmap.BASE + len(rom)] == rom, l
        if mn == "call":
            assert tgt.upper() == "T,XIX" or tgt.startswith("T,X"), l
            text = "call (%s)" % tgt.split(",")[1].lower()
        else:
            t = int(tgt, 16)
            j = addr_line.get(t)
            assert j is not None, "target 0x%06X of 0x%06X is not a statement start" % (t, a)
            k = j - 1
            while k >= 0 and (L[k].startswith(";") or not L[k].strip()):
                k -= 1
            lab = LAB.match(L[k]).group(1) if LAB.match(L[k]) else None
            if lab is None:
                lab = ".L%06X" % t
                inserts[j] = lab
            reg = {"cb": "c", "ca": "b", "c9": "a"}.get(bs.split()[0], None)
            if mn == "djnz":
                text = "djnz8 %s, %s" % (reg, lab)
            elif mn == "jr":
                text = "jr %s, %s" % (cc, lab) if cc else "jr %s" % lab
            else:
                text = "calr %s" % lab
        comment = l[l.index(";"):]
        edits[i] = "\t%-45s %s" % (text, comment)
        print("0x%06X  %-28s <- %s" % (a, text, l.strip()[:60]))
    print("%d lines, %d labels to insert" % (len(edits), len(inserts)))
    if not apply_:
        return
    out = []
    for i, l in enumerate(L):
        if i in inserts:
            out.append("%s:" % inserts[i])
        out.append(edits.get(i, l))
    open(srcmap.SRC, "w", encoding="latin-1").write("\n".join(out))
    print("applied")


if __name__ == "__main__":
    main()
