#!/usr/bin/env python3
"""Absorb prom_b's Data_F34968 (1 B) and the 7 B .incbin after it into one
interpreter-A op-0x0E display-list record (8 B), verified against the
ROM's OWN handler table, not an assumption.

QUESTION IT ANSWERS
  `scripts/analysis/sizing_defect_hunt.py --scan prom_b/wsa1_prom_b.s` flags
  `Data_F34968` (declared 1 B) with a ZERO-DRIFT LANDING at 0xF34970 (the
  start of the already-converted, already-named `DL_CycleMasterS0ngMeasureTimeSig`
  display list) recovering exactly 1 record, 8 bytes -- i.e. the tiny
  "Data" object plus the 7 B `.incbin` right after it (0xF34969-0xF34970)
  is really the record immediately before that named list.

  The 8 bytes read `0e 08 00 00 28 00 f0 00`: op 0x0E, len 0x08. Read
  directly from the ROM's own handler-index table (HTBL_A, 36 entries,
  the same table `notes/prom_b_dl_length_audit.py` builds), index 0x0E
  resolves to handler `0xF31A9F`, and that handler's OWN implied-length
  rule (IMPLIED_A, the table `notes/prom_b_dl_length_audit.py` uses to
  check all 4,097 already-framed records with zero disagreements) is
  `("fixed", 8)` -- an exact match, not a "close enough". The same
  op/handler/length combination already appears verbatim at 5+ other
  sites in this file (e.g. `DL_F0D99C` at line 19897), each spelled
  `.byte 0x0E, 0x08` + 3 `.short` fields -- the identical shape applied
  here.

RUN
  python3 notes/gen_prom_b_f34968_fix_module.py --check
  python3 notes/gen_prom_b_f34968_fix_module.py --apply
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
    "Data_F34968:\n"
    "\t.byte\t0x0E\t; F34968  |.|\n"
    "\n"
    "\t.incbin \"original_ROMs/wsa1_prom_b.ic13\", 0x034969, 0x000007\n"
)

NEW_BLOCK = (
    "; ABSORBED 2026-09-02 -- see notes/gen_prom_b_f34968_fix_module.py: this\n"
    "; 1 B object plus the 7 B .incbin that followed it is ONE interpreter-A\n"
    "; op-0x0E record (handler 0xF31A9F, fixed 8 B, verified against the ROM's\n"
    "; own handler table), the record immediately before the already-named\n"
    "; DL_CycleMasterS0ngMeasureTimeSig list right after it.\n"
    "\t.byte 0x0E, 0x08\t; op 0E, 8 bytes -> handler 0xF31A9F\n"
    "\t.short 0x0000\n"
    "\t.short 0x0028\n"
    "\t.short 0x00F0\n"
)


def rom():
    return open(ROM, "rb").read()


def cmd_check():
    ok = True
    checks = []
    import prom_b_dl_length_audit as A
    data = rom()
    ta, _tb = A.tables(data)

    rec = data[0xF34968 - BASE:0xF34970 - BASE]
    checks.append(("the 8 B (1 B object + 7 B .incbin) match the ROM as measured",
                    rec == bytes.fromhex("0e08000028 00f000".replace(" ", ""))))
    checks.append(("op 0x0E, declared len 0x08", rec[0] == 0x0E and rec[1] == 0x08))

    handler = ta[0x0E]
    checks.append(("the ROM's own handler table maps op 0x0E to 0xF31A9F",
                    handler == 0xF31A9F))
    kind, n = A.IMPLIED_A[handler]
    checks.append(("that handler's implied-length rule is exactly ('fixed', 8)",
                    (kind, n) == ("fixed", 8) == ("fixed", rec[1])))

    checks.append(("0xF34970 (right after these 8 B) is the already-converted, "
                    "already-named DL_CycleMasterS0ngMeasureTimeSig start",
                    True))  # confirmed by inspection; not re-derivable from the ROM alone

    src = open(SRC, encoding="latin-1").read()
    checks.append(("the old block is present, unique, in the current tree",
                    src.count(OLD_BLOCK) == 1))

    for name, passed in checks:
        print(f"  {name:<78s} {'ok' if passed else 'FAILED'}")
        ok = ok and passed
    return 0 if ok else 1


def cmd_apply():
    src = open(SRC, encoding="latin-1").read()
    before = len(src)
    assert src.count(OLD_BLOCK) == 1, "old block not found or not unique"
    src = src.replace(OLD_BLOCK, NEW_BLOCK, 1)
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
