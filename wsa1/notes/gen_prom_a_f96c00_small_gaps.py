#!/usr/bin/env python3
"""Emit four small prom_a residues (1+15+3+23 = 42 B) around the already
-documented RamInitTable_F96CA6 cluster.

QUESTION IT ANSWERS
  All four sit between already-converted anchors (a `sub_` routine's `ret`,
  the already-documented RamInitTable_F96CA6 arrays, or the already-verified
  1400 B 0x0E fill run) -- none of them are a walk's guess about where code
  or data starts or ends; the anchors on both sides were committed by
  earlier passes and are untouched here.

  0xF96C7B (15 B) -- `sub_F96C65` (already-converted, just above) sets
    `XIY=0x00f96c7b`, `BC=1`, then loops ONCE over a 5-byte (4-byte address,
    1-byte AND-mask) record before `ret`. That accounts for only the first
    5 bytes. The remaining 10 are zero, and `15 = 3 * 5`: this reads as a
    3-slot reserved record table with only slot 0 populated (addr=0x00007f32,
    mask=0xfb) and slots 1-2 zero (unused reserved capacity, never written).
    No other call site sets a different BC or XIY (checked: `0xf96c7b` is
    the sole literal reference to this address in the whole ROM).

  0xF96CA5 (1 B) -- a single 0x0E byte, this file's own established
    erased-flash/RET-padding value (see the file's `.fill` audit trail),
    sitting in a 1-byte gap between `sub_F96C8A`'s `ret` (0xF96CA4) and the
    already-documented `RamInitTable_F96CA6_Addrs` (starts 0xF96CA6).

  0xF96E86 (3 B) -- the already-existing header comment on
    RamInitTable_F96CA6 already does this pass's arithmetic: "80 iterations
    consumes exactly 320 + 160 = 480 bytes, landing EXACTLY on 0xF96E86 --
    three bytes short of the incbin's own end at 0xF96E89". So these 3 bytes
    (`0x24, 0xff, 0xff`) are provably NOT part of either array. No reader
    anywhere in the ROM cites this address (checked: 0 raw 3- or 4-byte
    little-endian pointer hits for 0xF96E86 in the whole image). Left
    unclassified, honestly, the same way `Unclassified_FC48D8` was in
    FINDINGS-prom_a-fc4000-boundary.md.

  0xF97401 (23 B) -- bounded by the already-verified 1400 B 0x0E fill run
    (ends exactly at 0xF97401, per the file's own comment) and `sub_F97418`
    (already-converted, starts exactly at 0xF97401+23). The bytes themselves
    (`00 00 00 0e` x5 + `00 00 00`) are NOT a clean tile of the preceding
    uniform-0x0E fill (mostly zero, only every 4th byte 0x0E) and 23 is not a
    multiple of 4, so this is not simply "more fill, mis-measured". No reader
    cites this address either (0 pointer hits, same check as above). Left
    unclassified.

RUN
  python3 notes/gen_prom_a_f96c00_small_gaps.py --check
  python3 notes/gen_prom_a_f96c00_small_gaps.py --emit-f96c7b  > /tmp/r1.s
  python3 notes/gen_prom_a_f96c00_small_gaps.py --emit-f96ca5  > /tmp/r2.s
  python3 notes/gen_prom_a_f96c00_small_gaps.py --emit-f96e86  > /tmp/r3.s
  python3 notes/gen_prom_a_f96c00_small_gaps.py --emit-f97401  > /tmp/r4.s
  python3 prom_a/insert_region.py 0xF96C7B 0xF96C8A /tmp/r1.s
  python3 prom_a/insert_region.py 0xF96CA5 0xF96CA6 /tmp/r2.s
  python3 prom_a/insert_region.py 0xF96E86 0xF96E89 /tmp/r3.s
  python3 prom_a/insert_region.py 0xF97401 0xF97418 /tmp/r4.s
  python3 scripts/analysis/assert_byte_identical.py
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = 0xF80000


def rom():
    return open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()


def read(lo, hi):
    return rom()[lo - BASE:hi - BASE]


def scan_pointer(addr):
    """How many raw 3- or 4-byte little-endian pointer patterns to `addr`
    appear anywhere in the ROM (route 1/3 elimination, FC4000 style)."""
    lo, mid, hi = addr & 0xFF, (addr >> 8) & 0xFF, (addr >> 16) & 0xFF
    data = rom()
    return data.count(bytes([lo, mid, hi])), data.count(bytes([lo, mid, hi, 0x00]))


def cmd_check():
    ok = True
    checks = []

    r1 = read(0xF96C7B, 0xF96C8A)
    checks.append(("0xF96C7B: 15 B = 3 x 5-byte records",
                    len(r1) == 15 == 3 * 5))
    checks.append(("0xF96C7B: record 0 = addr 0x00007f32, mask 0xfb (matches "
                    "sub_F96C65's single djnz iteration)",
                    r1[0:5] == bytes([0x32, 0x7f, 0x00, 0x00, 0xfb])))
    checks.append(("0xF96C7B: records 1 and 2 are all zero (unused reserved capacity)",
                    r1[5:15] == b"\x00" * 10))
    checks.append(("0xF96C7B: 0xf96c7b is the ONLY literal 3-byte reference "
                    "to this address in the ROM (the sub_F96C65 load itself)",
                    scan_pointer(0xF96C7B)[0] == 1))

    r2 = read(0xF96CA5, 0xF96CA6)
    checks.append(("0xF96CA5: 1 B, value 0x0E (this file's own erased-flash "
                    "padding value)", r2 == b"\x0e"))

    r3 = read(0xF96E86, 0xF96E89)
    checks.append(("0xF96E86: 3 B = 0x24, 0xff, 0xff",
                    r3 == bytes([0x24, 0xff, 0xff])))
    checks.append(("0xF96E86: RamInitTable_F96CA6 (80x4 + 80x2 = 480 B from "
                    "0xF96CA6) ends exactly here, proving these 3 B are NOT "
                    "part of either array",
                    0xF96CA6 + 80 * 4 + 80 * 2 == 0xF96E86))
    checks.append(("0xF96E86: zero pointer hits anywhere in the ROM",
                    scan_pointer(0xF96E86) == (0, 0)))

    r4 = read(0xF97401, 0xF97418)
    checks.append(("0xF97401: 23 B, matches the ROM as measured",
                    r4 == bytes.fromhex("000000" "0e" "000000" "0e" "000000"
                                        "0e" "000000" "0e" "000000" "0e"
                                        "000000")))
    checks.append(("0xF97401: 23 is not a multiple of 4 (rules out a clean "
                    "'00 00 00 0e' tile)", 23 % 4 != 0))
    checks.append(("0xF97401: the preceding 1400 B 0x0E fill run ends exactly "
                    "here (0xF96E89 + 1400)", 0xF96E89 + 1400 == 0xF97401))
    checks.append(("0xF97401: zero pointer hits anywhere in the ROM",
                    scan_pointer(0xF97401) == (0, 0)))

    for name, passed in checks:
        print(f"  {name:<78s} {'ok' if passed else 'FAILED'}")
        ok = ok and passed
    return 0 if ok else 1


def emit_f96c7b():
    r = read(0xF96C7B, 0xF96C8A)
    print("ReservedRecordTable_F96C7B:   ; 3 x 5-byte (addr32,mask8) records, "
          "read by sub_F96C65 (above) which processes only record 0")
    print("\t.long 0x00007f32   ; F96C7B  record 0 addr")
    print("\t.byte 0xfb         ; F96C7F  record 0 mask")
    print("\t.long 0x00000000, 0x00000000   ; F96C80  records 1-2 addr, unused/reserved")
    print("\t.byte 0x00, 0x00   ; F96C88  records 1-2 mask, unused/reserved")


def emit_f96ca5():
    print("; 0xF96CA5 -- 1 B of 0x0E (this file's own erased-flash/RET-padding "
          "value), between sub_F96C8A's ret and RamInitTable_F96CA6_Addrs.")
    print("\t.fill 1, 1, 0x0E   ; F96CA5")


def emit_f96e86():
    print("; 0xF96E86-0xF96E89 -- 3 B, unclassified.  RamInitTable_F96CA6's own")
    print("; header comment already proves its 480 B end exactly here, so these")
    print("; bytes are NOT part of either array.  No reader anywhere in the ROM")
    print("; cites this address (checked: 0 raw pointer hits).  Left untyped.")
    print("Unclassified_F96E86:")
    print("\t.byte 0x24, 0xff, 0xff   ; F96E86")


def emit_f97401():
    print("; 0xF97401-0xF97418 -- 23 B, unclassified.  Bounded by the already-")
    print("; verified 1400 B 0x0E fill run (ends exactly here) and sub_F97418")
    print("; (starts exactly at the far end).  Not a clean tile of the fill")
    print("; (mostly zero, one 0x0E every 4th byte, and 23 is not a multiple")
    print("; of 4) and no reader anywhere in the ROM cites this address.")
    print("Unclassified_F97401:")
    r = read(0xF97401, 0xF97418)
    print("\t.byte %s   ; F97401" % ", ".join("0x%02x" % b for b in r))


def main():
    if "--check" in sys.argv:
        sys.exit(cmd_check())
    if "--emit-f96c7b" in sys.argv:
        emit_f96c7b()
        return
    if "--emit-f96ca5" in sys.argv:
        emit_f96ca5()
        return
    if "--emit-f96e86" in sys.argv:
        emit_f96e86()
        return
    if "--emit-f97401" in sys.argv:
        emit_f97401()
        return
    sys.exit("usage: --check | --emit-f96c7b | --emit-f96ca5 | --emit-f96e86 | --emit-f97401")


if __name__ == "__main__":
    main()
