#!/usr/bin/env python3
"""Emit prom_a 0xF8C652-0xF8C842 (496 B) as verified assembly.

QUESTION IT ANSWERS
  FINDINGS-prom_a-f8c000-cluster.md refused this span outright: "8
  undecodable bytes at a roughly 16-byte stride (0xF8C687 through 0xF8C708),
  the signature of an embedded fixed-stride table, not a misread of pure
  code." That call was right about there being a table, but the naive
  decode's `db` count UNDERCOUNTS how much of the span is really data: two
  more tables (0xF8C727-0xF8C746 and 0xF8C764-0xF8C77D) sit further down and
  their bytes happen to decode as short, valid-looking (but wrong)
  instructions -- `normal`, `push SR`, `max` -- so unidasm never flags them.
  Exactly the failure mode the project brief warns about: a `db` count is
  necessary, never sufficient, and a table whose bytes are individually
  decodable is invisible to it.

  All three tables were found the same way: by locating the READER, not by
  refining the walk.

  TABLE 1 -- `PointerTable_F8C687`, 128 B, 32 little-endian longs.
  `sub_F8C652` ends with `ld A,(0x2250) / sla 0x02,A / ld XIY,0x00f8c687 /
  ld XIY,(XIY+A)` -- a 5-bit index (A, shifted left by 2 = *4) selects a
  32-bit entry from a table at 0xF8C687. Max index 31, entry width 4, so the
  table is exactly 32*4 = 128 bytes, ending at 0xF8C707 -- which is
  `DispatchTable_F8C2B2`'s OWN id=0x0002 target, already committed to the
  tree. The table's own values corroborate the read: 32 longs in a strictly
  monotonic increasing progression, `0x000076c2, 0x00007702, 0x00007742,
  ... 0x00007ec2`, each 0x40 more than the last except for one 0x80 step
  (index 7->8) -- structure, not noise.

  TABLES 2 AND 3 -- `RecordTable_F8C727` (31 B, 10x 3-byte records + a 0xFF
  terminator) and `RecordTable_F8C764` (25 B, 8x 3-byte records + a 0xFF
  terminator). Both are read by the SAME shared parser, `sub_F8C7F9`
  (`cp (XIY),0xff` / `cp A,(XIY)` / `add IY,0x0003` / loop -- terminator-and
  linear-scan, the identical shape already established for `CmdList_*` +
  its parser at `.LF8C16D` in FINDINGS-prom_a-f8c000-cluster.md, just a
  different shared routine and a different record width). Two call sites
  (`sub_F8C707` loading `XIY,0x00f8c727` then `calr sub_F8C7F9`; the routine
  at `0xF8C746` doing the same with `0x00f8c764`) are already-decoded code in
  THIS SAME PASS, not manufactured by the tables -- and each table's
  terminator lands exactly where the following code block already needs to
  start (`0xF8C746` and `0xF8C77D`, the latter ALSO `DispatchTable_F8C2B2`'s
  own id=0x0200 target).

  With all three tables excised (128 + 31 + 25 = 184 B of the 496), the
  remaining 312 bytes decode as four short routines with zero drift, and
  three of `DispatchTable_F8C2B2`'s eight non-placeholder targets land
  exactly on the resulting segment starts: 0xF8C652 (id=0x0080, the span's
  own start), 0xF8C707 (id=0x0002), 0xF8C77D (id=0x0200). Same evidentiary
  standard as FC4000, FDE74C and F8C485: the boundary is fixed by something
  outside the walk.

RUN
  python3 notes/gen_prom_a_f8c652_module.py --check
  python3 notes/gen_prom_a_f8c652_module.py --emit > /tmp/f8c652_region.s
  python3 prom_a/insert_region.py 0xF8C652 0xF8C842 /tmp/f8c652_region.s
  python3 scripts/analysis/assert_byte_identical.py
"""
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "prom_a"))
import roundtrip as RT  # noqa: E402

BASE = 0xF80000
LO, HI = 0xF8C652, 0xF8C842

TABLE1_LO, TABLE1_HI = 0xF8C687, 0xF8C707   # 128 B, 32 longs
TABLE2_LO, TABLE2_HI = 0xF8C727, 0xF8C746   # 31 B, 10 records + terminator
TABLE3_LO, TABLE3_HI = 0xF8C764, 0xF8C77D   # 25 B, 8 records + terminator

SEG_0 = (0xF8C652, TABLE1_LO)   # sub_F8C652, dispatch id=0x0080
SEG_1 = (TABLE1_HI, TABLE2_LO)  # sub_F8C707, dispatch id=0x0002
SEG_2 = (TABLE2_HI, TABLE3_LO)  # internal, reads RecordTable_F8C764
SEG_3 = (TABLE3_HI, HI)         # sub_F8C77D (dispatch id=0x0200) .. sub_F8C7F9 shared parser .. end

DISPATCH_TARGETS_IN_SPAN = {0xF8C652, 0xF8C707, 0xF8C77D}

TABLE1_LONGS = [
    0x000076C2, 0x00007702, 0x00007742, 0x00007782, 0x000077C2, 0x00007802,
    0x00007842, 0x00007882, 0x00007902, 0x00007942, 0x00007982, 0x000079C2,
    0x00007A02, 0x00007A42, 0x00007A82, 0x00007AC2, 0x00007B02, 0x00007B42,
    0x00007B82, 0x00007BC2, 0x00007C02, 0x00007C42, 0x00007C82, 0x00007CC2,
    0x00007D02, 0x00007D42, 0x00007D82, 0x00007DC2, 0x00007E02, 0x00007E42,
    0x00007E82, 0x00007EC2,
]  # monotonic, step 0x40 except ONE 0x80 step (index 7->8) -- a real
   # irregularity in the ROM's own data, not a transcription choice
TABLE2_BYTES = bytes.fromhex(
    "01 02 01 02 02 02 17 02 04 16 02 08 09 04 01 0a 04 02 "
    "12 04 04 15 04 08 08 04 10 03 04 20 ff".replace(" ", ""))
TABLE3_BYTES = bytes.fromhex(
    "01 01 01 02 01 02 17 01 04 16 01 08 09 04 01 0a 04 02 "
    "12 05 01 15 05 02 ff".replace(" ", ""))


def rom():
    return open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()


def read(lo, hi):
    return rom()[lo - BASE:hi - BASE]


def cmd_check():
    ok = True
    checks = []

    t1 = list(struct.unpack("<32I", read(TABLE1_LO, TABLE1_HI)))
    checks.append(("TABLE1 (32 longs @0xF8C687) matches the claimed +0x40 progression",
                    t1 == TABLE1_LONGS))
    diffs = [t1[i + 1] - t1[i] for i in range(len(t1) - 1)]
    checks.append(("TABLE1 is strictly monotonic increasing, step 0x40 except one 0x80",
                    all(d in (0x40, 0x80) for d in diffs) and diffs.count(0x80) == 1))
    checks.append(("TABLE1 size (128 B) = (max index 31 + 1) * entry width 4",
                    (TABLE1_HI - TABLE1_LO) == 32 * 4 == 128))

    t2 = read(TABLE2_LO, TABLE2_HI)
    t3 = read(TABLE3_LO, TABLE3_HI)
    checks.append(("TABLE2 (31 B @0xF8C727) matches, 10 records + 0xFF terminator",
                    t2 == TABLE2_BYTES and t2[-1] == 0xFF and len(t2) == 31))
    checks.append(("TABLE3 (25 B @0xF8C764) matches, 8 records + 0xFF terminator",
                    t3 == TABLE3_BYTES and t3[-1] == 0xFF and len(t3) == 25))
    checks.append(("both record tables are 3n+1 bytes (n whole records + terminator)",
                    (len(t2) - 1) % 3 == 0 and (len(t3) - 1) % 3 == 0))

    # byte accounting: 4 code segments + 3 tables = 496 B, contiguous, no gap/overlap
    bounds = [SEG_0, (TABLE1_LO, TABLE1_HI), SEG_1, (TABLE2_LO, TABLE2_HI),
              SEG_2, (TABLE3_LO, TABLE3_HI), SEG_3]
    contiguous = bounds[0][0] == LO and bounds[-1][1] == HI
    for i in range(1, len(bounds)):
        contiguous = contiguous and bounds[i - 1][1] == bounds[i][0]
    total = sum(hi - lo for lo, hi in bounds)
    checks.append(("7 pieces are contiguous 0xF8C652-0xF8C842 with no gap/overlap",
                    contiguous))
    checks.append(("byte accounting: total = 496", total == 496 == (HI - LO)))

    seg_starts = {SEG_0[0], SEG_1[0], SEG_3[0]}
    checks.append(("all 3 DispatchTable_F8C2B2 targets in this span land on a "
                    "converted segment start (0xF8C652, 0xF8C707, 0xF8C77D)",
                    DISPATCH_TARGETS_IN_SPAN <= seg_starts))

    region = build_region()
    src = RT.macro_prelude() + "\n\t.text\n" + region
    got = RT.assemble_block(src)
    expected = read(LO, HI)
    checks.append(("whole 496 B region round-trips byte-exact through llvm-mc",
                    got == expected))

    for name, passed in checks:
        print(f"  {name:<78s} {'ok' if passed else 'FAILED'}")
        ok = ok and passed
    return 0 if ok else 1


def _block_text(lo, hi):
    lines, good, stats = RT.emit_block(lo, hi)
    if not good:
        sys.stderr.write("!! block 0x%06X-0x%06X did NOT round-trip: %r\n"
                          % (lo, hi, dict(stats)))
        sys.exit(1)
    out = []
    for l, addr, bs, why in lines:
        if addr is None:
            out.append(l)
        else:
            raw = " ".join("%02x" % b for b in bs)
            out.append("%-46s ; %06X  %s" % (l, addr, raw))
    return "\n".join(out)


def build_region():
    parts = []
    parts.append("; ---------------------------------------------------------------------")
    parts.append("; 0xF8C652-0xF8C842 (496 B) -- CONVERTED, see")
    parts.append("; notes/FINDINGS-prom_a-f8c652-boundary.md.  Four short routines reached")
    parts.append("; by DispatchTable_F8C2B2 and a shared record-parser, three data tables")
    parts.append("; pinned by their own readers -- the naive decode's 8-undecodable-byte")
    parts.append("; count only caught the first of these three.")
    parts.append("; ---------------------------------------------------------------------")
    parts.append("sub_F8C652:   ; entry: DispatchTable_F8C2B2 id=0x0080")
    parts.append(_block_text(*SEG_0))
    parts.append("PointerTable_F8C687:   ; 128 B, 32 longs, +0x40 arithmetic "
                 "progression, read via (5-bit index)*4")
    for i in range(0, 32, 4):
        vals = ", ".join("0x%08x" % v for v in TABLE1_LONGS[i:i + 4])
        parts.append("\t.long %s   ; F8C%03X" % (vals, 0x687 + i * 4))
    parts.append("sub_F8C707:   ; entry: DispatchTable_F8C2B2 id=0x0002")
    parts.append(_block_text(*SEG_1))
    parts.append("RecordTable_F8C727:   ; 10 x [key,val_lo,val_hi] + 0xFF terminator, "
                 "read by sub_F8C7F9's shared linear scan")
    hex_bytes = ", ".join("0x%02x" % b for b in TABLE2_BYTES)
    parts.append("\t.byte %s   ; F8C727" % hex_bytes)
    parts.append(_block_text(*SEG_2))
    parts.append("RecordTable_F8C764:   ; 8 x [key,val_lo,val_hi] + 0xFF terminator, "
                 "read by sub_F8C7F9's shared linear scan")
    hex_bytes = ", ".join("0x%02x" % b for b in TABLE3_BYTES)
    parts.append("\t.byte %s   ; F8C764" % hex_bytes)
    parts.append("sub_F8C77D:   ; entry: DispatchTable_F8C2B2 id=0x0200")
    parts.append(_block_text(*SEG_3))
    return "\n".join(parts) + "\n"


def main():
    if "--check" in sys.argv:
        sys.exit(cmd_check())
    if "--emit" in sys.argv:
        print(build_region())
        return
    sys.exit("usage: --check | --emit")


if __name__ == "__main__":
    main()
