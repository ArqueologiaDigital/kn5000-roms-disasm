#!/usr/bin/env python3
r"""Symbolise numeric relative branches inside address ranges a human has vetted as CODE.

QUESTION THIS ANSWERS / JOB IT DOES
    The shared branch symboliser refuses whole blocks on heuristics (R3 "absurd
    neighbourhood": a `nop / nop / nop / ret` stub, a `.byte` shift it cannot
    spell) that are right for unknown bytes and wrong for code whose header
    already documents it.  For the ranges listed in RANGES -- each with the
    header that vouches for it -- this rewrites `jr cc,N` / `jrl cc,N` /
    `calr N` / `djnz ...,N` operands as labels:

      * the line's address comment and its hex bytes must equal the ROM there;
      * the displacement is recomputed from the ROM bytes (not from the text);
      * the target must be a statement start in the source (else it is left);
      * a missing target label is inserted as `.L<ADDR>`.

    THE BYTE GATE CHECKS EVERY EDIT: the assembler recomputes the displacement
    from the label, so a label at the wrong address changes the image.

RANGES (vetted by the header named)
    0xF8A81D-0xF8A913   sub_F8A81D, PanelGroupQueue_ExpandToEvents and
                        PanelEvent_ShiftThenRunAction (their headers).

RUN
    python3 notes/proma-2026-09-25/symbolize_vetted_ranges.py            # list
    python3 notes/proma-2026-09-25/symbolize_vetted_ranges.py --apply
    make gate-wsa1
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

B = srcmap.BASE
RANGES = [(0xF8A81D, 0xF8A913)]
LINE = re.compile(r"^(\t(jr|jrl|calr)\s+(?:([a-z]+)\s*,\s*)?)(-?0x[0-9a-fA-F]+|-?\d+)(\s*;\s*([0-9A-F]{6})\s+((?:[0-9a-f]{2}\s?)+).*)$")


def target(rom, a, op):
    b = rom[a - B]
    if op == "jr":
        assert 0x60 <= b <= 0x6F, hex(a)
        return a + 2 + int.from_bytes(rom[a - B + 1:a - B + 2], "little", signed=True)
    if op == "jrl":
        assert 0x70 <= b <= 0x7F, hex(a)
        return a + 3 + int.from_bytes(rom[a - B + 1:a - B + 3], "little", signed=True)
    assert b == 0x1E, hex(a)
    return a + 3 + int.from_bytes(rom[a - B + 1:a - B + 3], "little", signed=True)


def main():
    m = srcmap.load()
    L, rom = m.lines, m.rom
    edits, labels = [], {}
    for i, l in enumerate(L):
        mm = LINE.match(l)
        if not mm:
            continue
        a = int(mm.group(6), 16)
        if not any(lo <= a < hi for lo, hi in RANGES):
            continue
        bs = bytes(int(x, 16) for x in mm.group(7).split())
        assert rom[a - B:a - B + len(bs)] == bs, hex(a)
        t = target(rom, a, mm.group(2))
        if m.line_of(t) is None:
            print("  left  0x%06X -> 0x%06X (not a statement start)" % (a, t))
            continue
        names = [n for n in m.labels_at(t)]
        k = m.line_of(t) - 1                      # source-only labels (.L are not in the ELF)
        while k >= 0 and re.match(r"^[A-Za-z_.$][\w.$]*:", L[k]):
            names.append(L[k].split(":")[0])
            k -= 1
        name = names[0] if names else ".L%06X" % t
        if not names:
            labels[t] = name
        edits.append((i, mm.group(1) + name + mm.group(5)))
        print("  0x%06X %-4s -> %s" % (a, mm.group(2), name))
    print("%d operands, %d labels to insert" % (len(edits), len(labels)))
    if "--apply" not in sys.argv:
        return
    for i, new in edits:
        L[i] = new
    for t, name in sorted(labels.items(), reverse=True):
        i = m.line_of(t)
        L[i:i] = [name + ":"]
    open(srcmap.SRC, "wb").write("\n".join(L).encode("latin-1"))
    print("applied")


if __name__ == "__main__":
    main()
