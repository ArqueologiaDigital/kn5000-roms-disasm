#!/usr/bin/env python3
r"""Spell prom_a's fixed-width STRING operand tables as `.ascii` rows instead of `.byte`.

QUESTION THIS ANSWERS / JOB IT DOES
    The 0xFA1404 SYSTEM-menu module's operand tables were emitted as `.byte`
    with a header line from notes/prom_a_fa1404_identify.py such as
    `strings w=8 n<=16` -- the layout tool proved they are arrays of W-character
    strings the display lists index.  The CLAUDE.md string-literal policy wants
    readable text as string literals.  For every table whose header carries
    `strings w=W` this rewrites its `.byte` lines as one `.ascii` row per
    W-character entry, byte for byte (the gate checks every byte).

    Bytes outside 0x20-0x7E are kept inside the literal as \xNN escapes.  Only
    three occur, and only in the note-name tables: 0x88 and 0x8C sit exactly
    where a chromatic scale puts flats and a sharp (`C D\x88D E\x88E F ...`,
    `F F\x8cG`), which is a READING of the LCD font's glyphs, not a decode of
    the font -- the header line added says so.  A table with any other byte
    outside that set is skipped.

CHECKS
    S1  each converted table's bytes equal the ROM; its size is a multiple of W
    S2  the rewritten lines reproduce exactly the bytes of the lines removed

RUN
    python3 notes/proma-2026-09-25/ascii_operand_tables.py           # dry run: list
    python3 notes/proma-2026-09-25/ascii_operand_tables.py --apply
    make gate-wsa1
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

B = srcmap.BASE
GLYPH = {0x88, 0x8C, 0xA9}


def lit(bs):
    out = []
    for c in bs:
        if 0x20 <= c < 0x7F and c not in (0x22, 0x5C):
            out.append(chr(c))
        else:
            out.append("\\x%02x" % c)
    return '"' + "".join(out) + '"'


def main():
    m = srcmap.load()
    L = m.lines
    rom = m.rom
    plan = []
    for i, l in enumerate(L):
        mm = re.match(r"^; (OperandTable_([0-9A-F]{6})) -- (\d+) bytes, kind=operand_table", l)
        if not mm:
            continue
        name, addr, size = mm.group(1), int(mm.group(2), 16), int(mm.group(3))
        j = L.index(name + ":", i)
        w = re.search(r"strings w=(\d+) n<=(\d+)", "\n".join(L[i:j]))
        if not w:
            continue
        W = int(w.group(1))
        data = rom[addr - B:addr - B + size]
        if size % W or any(not (0x20 <= c < 0x7F) and c not in GLYPH for c in data):
            print("  skip %s (w=%d, %d B)" % (name, W, size))
            continue
        k = j + 1
        got = b""
        while len(got) < size:
            bm = re.match(r"^\t\.byte\s+([0-9a-fx, ]+?)\s*;\s*([0-9A-F]{6})\s*$", L[k])
            assert bm, (name, L[k])
            got += bytes(int(x, 16) for x in bm.group(1).split(","))
            k += 1
        assert got == data, name                                              # S1
        rows = []
        for r in range(0, size, W):
            rows.append(("\t.ascii " + lit(data[r:r + W])).ljust(44) + " ; %06X  [%d]" % (addr + r, r // W))
        note = ["; Text: %d rows of %d characters as `.ascii` (lane proma 2026-09-25," % (size // W, W),
                ";          notes/proma-2026-09-25/ascii_operand_tables.py)."]
        if any(c in (0x88, 0x8C) for c in data):
            note.append(";          \\x88 / \\x8c sit where a chromatic scale puts the flats and")
            note.append(";          the sharp -- a reading of the LCD font's glyphs, not a decode.")
        if 0xA9 in data:
            note.append(";          \\xa9 is a character of the LCD font whose glyph is not")
            note.append(";          established here.")
        plan.append((j, k, rows, note, name, size))
    print("%d tables, %d bytes" % (len(plan), sum(p[5] for p in plan)))
    if "--apply" not in sys.argv:
        return
    for j, k, rows, note, name, size in sorted(plan, reverse=True):
        L[j + 1:k] = rows
        L[j - 1:j - 1] = note          # before the closing dash line of the header
    open(srcmap.SRC, "wb").write("\n".join(L).encode("latin-1"))
    print("applied")


if __name__ == "__main__":
    main()
