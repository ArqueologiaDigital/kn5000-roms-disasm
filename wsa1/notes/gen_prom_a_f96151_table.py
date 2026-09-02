#!/usr/bin/env python3
"""Emit prom_a 0xF96151-0xF96172 (33 B) as a verified data table.

QUESTION IT ANSWERS
  This 33 B span was left `.incbin` with no note beyond "unconverted". Its
  reader sits in already-converted code immediately above it: `sub_F96062`'s
  helper at `0xF960FE` does `ld XHL,0x00f96151` and then linearly scans
  (`ld W,(XHL) / inc 1,XHL / cp W,D / jr z ... / cp W,0xff / jr nz loop`) --
  a byte table, terminated by 0xFF, searched for a match against register D.

  The table itself is trivial and self-verifying: 32 sequential bytes,
  `0x00, 0x01, 0x02, ... 0x1F`, then the 0xFF terminator the reader's own
  loop condition names -- 33 bytes total, landing exactly on the address
  where the ALREADY-CONVERTED `sub_F96172` starts. Not a walk's plausibility
  judgement: the reader (already committed to the tree, unaffected by this
  pass), the terminator byte value (named by the reader's own `cp W,0xff`),
  and the following label (already committed) all agree independently.

RUN
  python3 notes/gen_prom_a_f96151_table.py --check
  python3 notes/gen_prom_a_f96151_table.py --emit > /tmp/f96151_region.s
  python3 prom_a/insert_region.py 0xF96151 0xF96172 /tmp/f96151_region.s
  python3 scripts/analysis/assert_byte_identical.py
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = 0xF80000
LO, HI = 0xF96151, 0xF96172
TABLE = list(range(32)) + [0xFF]


def rom():
    return open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()


def cmd_check():
    ok = True
    data = list(rom()[LO - BASE:HI - BASE])
    checks = [
        ("span is 33 B (0xF96172-0xF96151)", HI - LO == 33 == len(TABLE)),
        ("bytes are 0x00..0x1F then a 0xFF terminator", data == TABLE),
        ("reader (already-converted, unaffected by this pass) loads this exact "
         "address: `ld XHL,0x00f96151` at 0xF960FE",
         b"\x43\x51\x61\xf9\x00" in rom()[0xF960FE - BASE:0xF96103 - BASE]),
    ]
    for name, passed in checks:
        print(f"  {name:<78s} {'ok' if passed else 'FAILED'}")
        ok = ok and passed
    return 0 if ok else 1


def build_region():
    hexed = ", ".join("0x%02x" % b for b in TABLE)
    return ("IndexTable_F96151:   ; 32 sequential bytes + 0xFF terminator, read "
            "by sub_F96062's helper (0xF960FE) via a linear scan against D\n"
            "\t.byte %s   ; F96151\n" % hexed)


def main():
    if "--check" in sys.argv:
        sys.exit(cmd_check())
    if "--emit" in sys.argv:
        print(build_region())
        return
    sys.exit("usage: --check | --emit")


if __name__ == "__main__":
    main()
