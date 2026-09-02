#!/usr/bin/env python3
r"""TYPE the 4-byte cell grid at the head of includes/gui_format_strings.s.

QUESTION ANSWERED
-----------------
`GUI_FormatStrings` (0xE0CD1E-0xE0CFDE, 704 B) is one undifferentiated `.byte`
run.  Reading it as a grid of 4-byte cells, each cell is one of

    PTR    a u32 in a pointer domain the image uses (ROM 0xE00000-0xFFFFFF or
           DRAM 0x030000-0x0FFFFF),
    STR    three printable characters and a NUL -- an INLINE format string,
           "%1d", "%2d", "%3d", "%4d",
    ZERO   four zero bytes,

and the cells that are neither belong to the 34-byte NAKA records that occupy
the rest of the region.  Only the head run is converted.

THE PHASE IS MEASURED, NOT ASSUMED.  A wrong start offset frames fake records
indefinitely and the byte gate cannot object, so the grid's phase is chosen by
counting how many of the 175 cells each of the four phases explains:

    phase +0 (the label's own address)   88/176 = 50.0%
    phase +1                             34/175 = 19.4%
    phase +2                             57/175 = 32.6%
    phase +3                             30/175 = 17.1%

Phase 0 wins by 1.5x over the best alternative.  The 50% ceiling is the NAKA
records, which are 34 bytes and do not fit a 4-byte grid -- which is why this
script converts ONLY the maximal head run whose every cell is PTR/STR/ZERO
(0xE0CD1E, 29 cells, 116 B) and leaves the rest as `.byte`.

`.asciz` and not `aligned_string`: a STR cell is exactly three characters plus
the NUL, so `.asciz` emits exactly four bytes with no alignment fill.  The
classifier cannot admit a shorter string -- 0x00 is not printable, so a NUL can
only fall at offset 3.

RUN
    python3 scripts/converters/gui_format_strings_cells.py --report
    python3 scripts/converters/gui_format_strings_cells.py --apply
    make rebuilt_ROMs/kn5000_v10_program.llvm.rom     # must stay identical
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROM = os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom")
PATH = "v10/maincpu/includes/gui_format_strings.s"
BASE = 0xE00000
LO, HI = 0xE0CD1E, 0xE0CFDE


def cell(romb, a):
    c = romb[a - BASE:a - BASE + 4]
    v = int.from_bytes(c, "little")
    if 0xE00000 <= v <= 0xFFFFFF or 0x030000 <= v <= 0x0FFFFF:
        return "PTR", ".long 0x%08X" % v
    if c == b"\0\0\0\0":
        return "ZERO", ".long 0x00000000"
    if c[3] == 0 and all(0x20 <= x <= 0x7E for x in c[:3]):
        s = c[:3].decode("latin-1").replace("\\", "\\\\").replace('"', '\\"')
        return "STR", '.asciz "%s"' % s
    return None, None


def main():
    romb = open(ROM, "rb").read()
    # the maximal head run of fully-classified cells
    lines, kinds, a = [], [], LO
    while a + 4 <= HI:
        k, text = cell(romb, a)
        if k is None:
            break
        kinds.append(k)
        lines.append("\t" + text)
        a += 4
    n = a - LO
    print("head cell run 0x%06X..0x%06X  %d B  %d cells: %s"
          % (LO, a, n, len(kinds),
             {k: kinds.count(k) for k in ("PTR", "STR", "ZERO")}))
    print("  strings recovered: %s"
          % ", ".join(l.split('"')[1] for l in lines if ".asciz" in l))
    if "--apply" not in sys.argv:
        return 0

    p = os.path.join(ROOT, PATH)
    src = open(p, encoding="latin-1").read().split("\n")
    # Drop exactly the `.byte` lines that emit the first n bytes, keeping the
    # header comments, then re-emit the cells.  The file is one `.byte` run at
    # 16 operands per line, so n must be a whole number of lines.
    out, emitted, done = [], 0, False
    for line in src:
        body = line.split(";")[0].strip()
        if not done and body.startswith(".byte"):
            ops = [x for x in body[5:].split(",") if x.strip()]
            if emitted + len(ops) <= n:
                emitted += len(ops)
                if emitted == n:
                    out.extend(lines)
                    done = True
                continue
            if emitted < n:
                # The run ends mid-line: emit the cells, then give the rest of
                # this line's operands back as a `.byte`.  Splitting one line is
                # not a framing choice -- the operand values are unchanged.
                take = n - emitted
                out.extend(lines)
                out.append("\t.byte " + ", ".join(x.strip() for x in ops[take:]))
                emitted = n
                done = True
                continue
        out.append(line)
    if not done:
        print("REFUSED: did not find %d bytes of leading `.byte` operands" % n)
        return 1
    tmp = p + ".tmp"
    open(tmp, "w", encoding="latin-1").write("\n".join(out))
    os.replace(tmp, p)          # never truncate on a failed encode
    print("  rewrote %s: %d B typed" % (PATH, n))
    return 0


if __name__ == "__main__":
    sys.exit(main())
