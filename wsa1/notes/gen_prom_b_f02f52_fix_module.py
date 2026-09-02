#!/usr/bin/env python3
"""Shrink prom_b's Data_F02F52 to its real 24 B extent and recover the
12 B display-list record that follows it -- the twin of Data_F3281C
(notes/gen_prom_b_f3281c_fix_module.py), same shape, same recorded
sizing defect (notes/DEBT-INVENTORY-2026-09-02.md).

QUESTION IT ANSWERS
  `scripts/analysis/sizing_defect_hunt.py --scan prom_b/wsa1_prom_b.s` flags
  `Data_F02F52` as declared 29 B, clean_prefix 24 B, tail 5 B, with a
  ZERO-DRIFT LANDING at 0xF02F76 (the start of the already-converted
  3-record display list right after it) -- byte-for-byte the same defect
  shape as `Data_F3281C`, down to the tail bytes (`03 0c 1a 19 f0`) and the
  recovered record's own handler and trailing field pair.

  Data_F02F52's first 24 bytes are 6 clean `0x00F02Fxx` pointers (checked
  below). The remaining 5 declared bytes, plus the 7-byte `.incbin` right
  after them (0xF02F6F-0xF02F75, already marked "not converted"), are
  exactly 12 bytes -- one interpreter-A op-0x03 record (handler 0xF31ABE,
  fixed 12 bytes), matching the shape of the 3 records already converted
  after it, and pointing at `0x00F0191A` -- the SAME already-named
  `Data_F0191A` object `Data_F3281C`'s recovered record also points at.

RUN
  python3 notes/gen_prom_b_f02f52_fix_module.py --check
  python3 notes/gen_prom_b_f02f52_fix_module.py --apply
  python3 scripts/analysis/assert_byte_identical.py
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
BASE = 0xF00000

OLD_HEADER = "; Data_F02F52 -- 29 bytes, EMITTED AS DATA (not promoted to code)."
NEW_HEADER = ("; Data_F02F52 -- 24 bytes, EMITTED AS DATA (not promoted to code).\n"
              "; SHRUNK 2026-09-02 from a declared 29 B: the trailing 5 declared bytes\n"
              "; plus the 7 B .incbin that followed it were really the first record of\n"
              "; the display list right after this object -- see\n"
              "; notes/gen_prom_b_f02f52_fix_module.py.")

OLD_BYTES_BLOCK = (
    "Data_F02F52:\n"
    "\t.byte\t0x22, 0x2F, 0xF0, 0x00, 0x36, 0x2F, 0xF0, 0x00, 0x3D, 0x2F, 0xF0, "
    "0x00, 0x44, 0x2F, 0xF0, 0x00\t; F02F52  |\"/..6/..=/..D/..|\n"
    "\t.byte\t0x4B, 0x2F, 0xF0, 0x00, 0x52, 0x2F, 0xF0, 0x00, 0x03, 0x0C, 0x1A, "
    "0x19, 0xF0\t; F02F62  |K/..R/.......|\n"
    "\n\t\n"
    "; --- 0xF02F6F-0xF02F75: not converted -- decodes as neither interpreter's "
    "records and is not a uniform fill ---\n"
    "\t.incbin \"original_ROMs/wsa1_prom_b.ic13\", 0x002F6F, 0x000007\n"
)

NEW_BYTES_BLOCK = (
    "Data_F02F52:\n"
    "\t.byte\t0x22, 0x2F, 0xF0, 0x00, 0x36, 0x2F, 0xF0, 0x00, 0x3D, 0x2F, 0xF0, "
    "0x00, 0x44, 0x2F, 0xF0, 0x00\t; F02F52  |\"/..6/..=/..D/..|\n"
    "\t.byte\t0x4B, 0x2F, 0xF0, 0x00, 0x52, 0x2F, 0xF0, 0x00\t; F02F62\n"
)

OLD_RECORDS_HEADER = "; 0xF02F76-0xF02F99 -- 3 display-list records, 36 bytes -- interpreter A"
NEW_RECORDS_HEADER = (
    "; 0xF02F6A-0xF02F99 -- 4 display-list records, 48 bytes -- interpreter A.\n"
    "; The FIRST record (0xF02F6A-0xF02F76, 12 B) was recovered from\n"
    "; Data_F02F52's oversized declaration (see notes/gen_prom_b_f02f52_fix_module.py);\n"
    "; the other 3 (0xF02F76-0xF02F99) are as follows.")

NEW_FIRST_RECORD = (
    "\t.byte 0x03, 0x0C\t; op 03, 12 bytes -> handler 0xF31ABE, recovered from "
    "Data_F02F52's oversized declaration\n"
    "\t.long 0x00F0191A\n"
    "\t.short 0x0B91\n"
    "\t.short 0x0003\n"
    "\t.short 0x000A\n")


def rom():
    return open(ROM, "rb").read()


def cmd_check():
    ok = True
    checks = []
    data = rom()

    clean24 = data[0xF02F52 - BASE:0xF02F6A - BASE]
    checks.append(("Data_F02F52's first 24 bytes are 6 clean 0x00F02Fxx pointers",
                    clean24 == bytes([0x22, 0x2F, 0xF0, 0x00, 0x36, 0x2F, 0xF0, 0x00,
                                      0x3D, 0x2F, 0xF0, 0x00, 0x44, 0x2F, 0xF0, 0x00,
                                      0x4B, 0x2F, 0xF0, 0x00, 0x52, 0x2F, 0xF0, 0x00])))

    recovered = data[0xF02F6A - BASE:0xF02F76 - BASE]
    checks.append(("the recovered 12 B (declared tail + old .incbin) matches "
                    "op 0x03 len 0x0C + long 0x00F0191A + 3 shorts",
                    recovered == bytes.fromhex("030c1a19f000910b03000a00")))

    neighbour = data[0xF02F76 - BASE:0xF02F82 - BASE]
    checks.append(("the recovered record is the SAME 12 B shape (op 0x03, len "
                    "0x0C, handler 0xF31ABE) as its already-converted neighbour",
                    neighbour[0:2] == recovered[0:2] == bytes([0x03, 0x0C])))
    checks.append(("both records share the same trailing 0x0003, 0x000A field pair",
                    recovered[8:12] == neighbour[8:12] == bytes.fromhex("03000a00")))
    checks.append(("both this record and Data_F3281C's recovered record point "
                    "at the same already-named object, 0x00F0191A (Data_F0191A)",
                    recovered[2:6] == bytes.fromhex("1a19f000")))

    checks.append(("byte accounting: 24 (shrunk object) + 12 (recovered record) "
                    "= 36 = the original 29 B declaration + 7 B .incbin",
                    24 + 12 == 29 + 7 == 36))

    src = open(SRC, encoding="latin-1").read()
    checks.append(("the old header text is present, unique, in the current tree",
                    src.count(OLD_HEADER) == 1))
    checks.append(("the old bytes block is present, unique, in the current tree",
                    src.count(OLD_BYTES_BLOCK) == 1))
    checks.append(("the old records header is present, unique, in the current tree",
                    src.count(OLD_RECORDS_HEADER) == 1))

    for name, passed in checks:
        print(f"  {name:<78s} {'ok' if passed else 'FAILED'}")
        ok = ok and passed
    return 0 if ok else 1


def cmd_apply():
    src = open(SRC, encoding="latin-1").read()
    before = len(src)
    assert src.count(OLD_HEADER) == 1, "old header not found or not unique"
    src = src.replace(OLD_HEADER, NEW_HEADER, 1)
    assert src.count(OLD_BYTES_BLOCK) == 1, "old bytes block not found or not unique"
    src = src.replace(OLD_BYTES_BLOCK, NEW_BYTES_BLOCK, 1)

    header_pos = src.index(OLD_RECORDS_HEADER)  # unique, asserted by --check
    src = src[:header_pos] + NEW_RECORDS_HEADER + src[header_pos + len(OLD_RECORDS_HEADER):]

    dashes = "; ------------------------------------------------------------------\n"
    search_from = header_pos + len(NEW_RECORDS_HEADER)
    dash_pos = src.index(dashes, search_from)
    insert_at = dash_pos + len(dashes)
    src = src[:insert_at] + NEW_FIRST_RECORD + src[insert_at:]

    open(SRC, "w", encoding="latin-1").write(src)
    after = len(src)
    print("applied: %d -> %d chars (%+d)" % (before, after, after - before))


def main():
    if "--check" in sys.argv:
        sys.exit(cmd_check())
    if "--apply" in sys.argv:
        cmd_apply()
        return
    sys.exit("usage: --check | --apply")


if __name__ == "__main__":
    main()
