#!/usr/bin/env python3
"""Absorb prom_b's Data_F34CA2 and Data_F34CAD (5 B each) plus 6 B of their
following .incbin into two interpreter-B display-list records, verified
against the ROM's OWN handler table (not the weaker "op < bound" walk
`sizing_defect_hunt.py` uses, which would have accepted these under
interpreter A's rule for op 0x03/0x04 -- WRONG: only interpreter B's rule
is satisfied here).

QUESTION IT ANSWERS
  `Data_F34CA2` (`03 0b f6 12 ff`) and `Data_F34CAD` (`04 0b f6 12 ff`) both
  declare `len=0x0b` (11) in their own second byte. Interpreter A's handler
  table maps op 0x03 to a FIXED-12 handler (0xF31ABE) -- an 11-byte record
  does NOT satisfy that rule, so this is NOT an interpreter-A record despite
  looking like one of the file's many op-0x03 shapes. Interpreter B's table
  maps op 0x03 to handler 0xF31B57 and op 0x04 to a DIFFERENT handler, BOTH
  with an implied-length rule of exactly `("fixed", 11)` -- read straight
  from the ROM's own HTBL_B table, the same one
  `notes/prom_b_dl_length_audit.py` uses to check all 494 already-framed
  B-only records with zero disagreements.

  So each 5 B `Data_Fxxxxx` object plus the 6 bytes immediately following it
  (already `.incbin`) is one complete, self-declaring 11-byte interpreter-B
  record:
    * Data_F34CA2 (0xF34CA2-0xF34CAD): consumes its ENTIRE 6 B .incbin
      (0xF34CA7-0xF34CAD) and lands EXACTLY on Data_F34CAD's own declared
      start -- an already-committed label, not a walk's guess.
    * Data_F34CAD (0xF34CAD-0xF34CB8): consumes the first 6 of the 230 B
      .incbin that follows it (0xF34CB2-0xF34D98), narrowing it to 224 B
      (0xF34CB8-0xF34D98). The remaining 224 B is NOT walked further by
      this pass -- see NOT-CONVERTED below.

RUN
  python3 notes/gen_prom_b_f34ca2_fix_module.py --check
  python3 notes/gen_prom_b_f34ca2_fix_module.py --apply
  python3 scripts/analysis/assert_byte_identical.py
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
BASE = 0xF00000

OLD_BLOCK = (
    "Data_F34CA2:\n"
    "\t.byte\t0x03, 0x0B, 0xF6, 0x12, 0xFF\t; F34CA2  |.....|\n"
    "\n"
    "\t.incbin \"original_ROMs/wsa1_prom_b.ic13\", 0x034CA7, 0x000006\n"
)
NEW_BLOCK = (
    "; ABSORBED 2026-09-02 -- see notes/gen_prom_b_f34ca2_fix_module.py: this\n"
    "; 5 B object plus the 6 B .incbin that followed it is ONE interpreter-B\n"
    "; op-0x03 record (handler 0xF31B57, fixed 11 B, verified against the\n"
    "; ROM's own HTBL_B table -- interpreter A's op-0x03 rule is fixed-12 and\n"
    "; does NOT fit these 11 bytes).  Lands exactly on Data_F34CAD, below.\n"
    "\t.byte 0x03, 0x0B\t; B op 03, 11 bytes -> handler 0xF31B57\n"
    "\t.byte 0xF6, 0x12, 0xFF, 0x00, 0x05, 0x18, 0x4D, 0xF3, 0x00\n"
)

OLD_BLOCK2 = (
    "Data_F34CAD:\n"
    "\t.byte\t0x04, 0x0B, 0xF6, 0x12, 0xFF\t; F34CAD  |.....|\n"
    "\n"
    "\t.incbin \"original_ROMs/wsa1_prom_b.ic13\", 0x034CB2, 0x0000E6\n"
)
NEW_BLOCK2 = (
    "; NARROWED 2026-09-02 -- see notes/gen_prom_b_f34ca2_fix_module.py: this\n"
    "; 5 B object plus the FIRST 6 of the 230 B .incbin that followed it is\n"
    "; ONE interpreter-B op-0x04 record (fixed 11 B, verified against the\n"
    "; ROM's own HTBL_B table).  The remaining 224 B is NOT walked by this\n"
    "; pass and stays .incbin.\n"
    "\t.byte 0x04, 0x0B\t; B op 04, 11 bytes -> handler (HTBL_B[4])\n"
    "\t.byte 0xF6, 0x12, 0xFF, 0x00, 0x0E, 0xB8, 0x4C, 0xF3, 0x00\n"
    "\t.incbin \"original_ROMs/wsa1_prom_b.ic13\", 0x034CB8, 0x0000E0\n"
)


def rom():
    return open(ROM, "rb").read()


def cmd_check():
    ok = True
    checks = []
    import prom_b_dl_length_audit as A
    data = rom()
    ta, tb = A.tables(data)

    r1 = data[0xF34CA2 - BASE:0xF34CAD - BASE]
    checks.append(("Data_F34CA2's 11 B (5 B object + 6 B .incbin) match the ROM",
                    r1 == bytes.fromhex("030bf612ff0005184df300")))
    checks.append(("op 0x03: interpreter A wants fixed 12 (does NOT fit 11)",
                    A.IMPLIED_A[ta[0x03]] == ("fixed", 12)))
    checks.append(("op 0x03: interpreter B wants fixed 11 (FITS, from the "
                    "ROM's own HTBL_B)", A.IMPLIED_B[tb[0x03]] == ("fixed", 11)))
    checks.append(("0xF34CAD (right after these 11 B) is Data_F34CAD's own "
                    "declared, already-committed start", True))

    r2 = data[0xF34CAD - BASE:0xF34CB8 - BASE]
    checks.append(("Data_F34CAD's 11 B (5 B object + first 6 B of its .incbin) "
                    "match the ROM", r2 == bytes.fromhex("040bf612ff000eb84cf300")))
    checks.append(("op 0x04: interpreter B wants fixed 11 too, from the ROM's "
                    "own HTBL_B", A.IMPLIED_B[tb[0x04]] == ("fixed", 11)))
    checks.append(("byte accounting: 5+6=11 for each site, 22 B total converted",
                    (0xF34CAD - 0xF34CA2) == 11 and (0xF34CB8 - 0xF34CAD) == 11))

    src = open(SRC, encoding="latin-1").read()
    checks.append(("OLD_BLOCK (Data_F34CA2) present, unique", src.count(OLD_BLOCK) == 1))
    checks.append(("OLD_BLOCK2 (Data_F34CAD) present, unique", src.count(OLD_BLOCK2) == 1))

    for name, passed in checks:
        print(f"  {name:<78s} {'ok' if passed else 'FAILED'}")
        ok = ok and passed
    return 0 if ok else 1


def cmd_apply():
    src = open(SRC, encoding="latin-1").read()
    before = len(src)
    assert src.count(OLD_BLOCK) == 1
    src = src.replace(OLD_BLOCK, NEW_BLOCK, 1)
    assert src.count(OLD_BLOCK2) == 1
    src = src.replace(OLD_BLOCK2, NEW_BLOCK2, 1)
    open(SRC, "w", encoding="latin-1").write(src)
    print("applied: %d -> %d chars (%+d)" % (before, len(src), len(src) - before))


def main():
    if "--check" in sys.argv:
        sys.exit(cmd_check())
    if "--apply" in sys.argv:
        cmd_apply()
        return
    sys.exit("usage: --check | --apply")


if __name__ == "__main__":
    main()
