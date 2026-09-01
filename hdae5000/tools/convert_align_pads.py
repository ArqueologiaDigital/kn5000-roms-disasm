#!/usr/bin/env python3
"""convert_align_pads.py -- reclassify proven word-alignment padding bytes in
hdae5000_data_tables.s from bare, undocumented `.byte 0x00` into a real
`.balign 2, 0x00` directive.

WHAT QUESTION THIS ANSWERS: which of the file's ~13,215 undocumented `.byte`
operand bytes are not unknown data at all, but the (always-zero) padding byte
a word-aligned string/pointer pool inserts whenever the preceding content ends
on an odd address?

EVIDENCE (see notes/hdae5000-lane-2026-09-02-alignment-padding.md for the
full writeup):
  * Every one of the 1,580 `.long` operands in this file lands on a 4-BYTE-
    aligned address (0 exceptions) -- proven from the real assembler's own
    linked addresses, not a hand-rolled offset parser (see get_addrs.py).
  * 3,953 of 4,167 `.asciz` strings (95%) and 1,582 of 1,608 `.ascii` runs
    (98%) start on an EVEN address; the exceptions cluster tightly inside one
    known different sub-table (a "*"-suffixed glyph-name pool around
    0x2A2065) that has NO leading pad byte at all -- i.e. the exceptions are
    places that never had a pad, not places where this rule is wrong.
  * Two widely-separated, independently pre-existing offset anchors were
    cross-checked against the real assembled address and landed EXACTLY on
    the documented byte, over 20,000 bytes apart:
      - HDAE5000_RECORD_COUNT + up to 0x284 (40+ per-string .set anchors in
        hdae5000_init_data.s) all resolve to the string they name.
      - HDAE5000_Panel_Save_UI + 0x2ca4 = 0x2A2656 = "ABC" (HDAE5000_Str_
        CharSet_Upper_1), and HDAE5000_UI_Page_Titles + 0x11ea = 0x29F174 =
        "! HD FORMAT !" (HDAE5000_Str_Alert_HDFormat), both exactly as their
        comments in hdae5000_init_data.s already claimed.
  * Only converts a `.byte 0x00` when: it is the SOLE operand, has no
    existing comment (i.e. IS in the bare-debt count), sits at an ODD real
    address, and the next content line is `.asciz` or `.ascii` (NOT `.zero`,
    which this file's own statistics show is not reliably aligned -- left
    alone as unconverted debt).

RUN (from the hdae5000 lane worktree root, hdae5000/ as cwd):
    python3 tools/get_lprobe_addrs.py > /tmp/lprobe.txt   # ground-truth addresses
    python3 tools/convert_align_pads.py /tmp/lprobe.txt hdae5000_data_tables.s --apply
Omit --apply to dry-run (prints count + a sample of lines that would change).
"""
import re
import sys

def strip_comment(line):
    in_str = False
    for i, ch in enumerate(line):
        if ch == '"':
            in_str = not in_str
        elif ch == ';' and not in_str:
            return line[:i], line[i + 1:].strip()
    return line, ""

BYTE_RE = re.compile(r'^(\s*)(?:\S+\s*:\s*)?\.byte\b(.*)$', re.IGNORECASE)
DIRECTIVE_RE = re.compile(r'^\s*(?:\S+\s*:\s*)?\.(\w+)')


def count_operands(rest):
    rest = rest.strip()
    if not rest:
        return []
    return [p.strip() for p in rest.split(",") if p.strip() != ""]


def main():
    addr_file, src_file = sys.argv[1], sys.argv[2]
    apply = "--apply" in sys.argv

    addr = {}
    with open(addr_file) as f:
        for line in f:
            a, t, name = line.split()
            n = int(name.split("_", 1)[1])
            addr[n] = int(a, 16)

    with open(src_file, encoding="latin-1") as f:
        lines = f.readlines()

    def next_content(i):
        j = i + 1
        while j <= len(lines):
            code, _ = strip_comment(lines[j - 1])
            if code.strip():
                return j
            j += 1
        return None

    converted = 0
    for i, line in enumerate(lines, 1):
        code, comment = strip_comment(line)
        m = BYTE_RE.match(code)
        if not m or comment:
            continue
        ops = count_operands(m.group(2))
        if len(ops) != 1 or ops[0] not in ("0x00", "0x0"):
            continue
        if addr[i] % 2 != 1:
            continue
        nc = next_content(i)
        if nc is None:
            continue
        ncode, _ = strip_comment(lines[nc - 1])
        nd = DIRECTIVE_RE.match(ncode)
        if not nd or nd.group(1) not in ("asciz", "ascii"):
            continue
        indent = m.group(1)
        lines[i - 1] = (f"{indent}.balign 2, 0x00                       "
                         f"; word-align pad (proven: see convert_align_pads.py header)\n")
        converted += 1

    print(f"converted {converted} bare '.byte 0x00' lines to '.balign 2, 0x00'")
    if apply:
        with open(src_file, "w", encoding="latin-1") as f:
            f.writelines(lines)
        print("written.")
    else:
        print("dry run only; pass --apply to write")


if __name__ == "__main__":
    main()
