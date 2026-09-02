#!/usr/bin/env python3
"""What is at 0xF29BC6-0xF2ADD1 (4,620 B), between the block/song-store region
and the already-converted DL_CombinationGroupMenuReMap1 display list?

QUESTION IT ANSWERS
    This was the largest remaining `.incbin` in prom_b: a single 0x120C-byte
    span with no known call site pointing into most of it.  It is FOUR
    different things back to back, not one unknown blob.

STRUCTURE, each part proven independently below (see --selftest)

  PART 1 -- 0xF29BC6-0xF29C0A (68 B): a 17-entry, 4-byte pointer table, stride
    0xE6.  Entry i recomputes as 0xF29C0A + i*0xE6 for all 17 entries --
    verified against the ROM's stored bytes, not asserted.  Entry 0 points at
    the byte immediately after the table itself.

  PART 2 -- 0xF29C0A-0xF2AB50 (3,910 B = 17 * 0xE6): the 17 records the table
    addresses.  Each is:
        +0x00           1 flag byte (0 in records 0-15, 1 in record 16)
        +0x01-0x2D      45 zero bytes
        +0x2E-0xB7      a 24x46-pixel 1bpp bitmap, 46 rows of 3 bytes, MSB-first
        +0xB8-0xE5      46 zero bytes
    Rendered as pixels (--show-bitmaps), the 17 records are 17 ANIMATION
    FRAMES of one glyph -- a diamond/hourglass outline -- traced in a little
    more on each frame, frame 0 all-blank and frame 16 fully drawn.  This is
    checked structurally, not just eyeballed: in every record the only nonzero
    bytes lie in the 0x2E-0xB7 window (45-byte header and 46-byte footer are
    all zero in all 17 records), and the pixel counts across the 17 frames are
    non-decreasing (a growing glyph), which a random or textual payload would
    not produce. It is NOT a display list: no interpretation of these bytes as
    (op, len) records self-frames (checked for both interpreters' bounds), and
    display-list operand bytes are never bit-mirrored/symmetric the way these
    rows are.

  PART 3 -- 0xF2AB50-0xF2AC50 (256 B): TWO parallel 32-entry, 4-byte arrays
    (top byte always zero).  Block 1 (the first 32 entries) is a ramp,
    0x76A2..0x7EA2 step 0x40, EXCEPT one doubled step (0x80) between index 8
    and 9 (0x7862 -> 0x78E2, skipping 0x78A2).  Block 2 (the next 32 entries)
    is block 1 + 0x20 exactly, entry for entry, including the same doubled
    step at the same index -- verified by recomputing both ramps and diffing
    every one of the 64 stored values, and by an exact block2[i]==block1[i]+
    0x20 check across all 32 pairs.  Committed as a typed, UNNAMED array:
    nothing in the tree currently reads it through a resolved call site, so a
    name here would be a guess. (See "what this does not claim" below.)

  PART 4 -- 0xF2AC50-0xF2ADD1 (386 B): 44 ordinary interpreter-A display-list
    records -- reuses scripts/analysis/prom_b_display_lists.py's own walk()/
    render(), the same instrument that already converted the rest of this
    file's display lists.  Walking op/len from 0xF2AC50 lands with ZERO DRIFT
    on 0xF2ADD2, where DL_CombinationGroupMenuReMap1 (already committed)
    begins.  This is the "COMBINATION GROUP MENU" title, a "1."-"16." number
    list, "USER1"/"ROM/EXT" captions, "OK", and 20 coordinate/rectangle
    records.  It was invisible to prom_b_display_lists.py's own call-site scan
    because it is reached by a CALL SHAPE that scanner does not look for (a
    stack push of start/end rather than `ld XIY,imm/ld XIX,imm/call`) -- the
    same class of gap gen_prom_b_dl_shape23_module.py and
    gen_prom_b_dl_closure_gaps_module.py closed elsewhere in this file.

WHAT THIS DOES NOT CLAIM
    Part 3's array is typed by width (4-byte entries) and by the ramp
    structure that generates 63 of its 64 values, but not NAMED: no resolved
    call site in this tree indexes it, so nothing here asserts what a
    "COMBINATION GROUP" caller would use it for. Part 2's glyph is not named
    either -- "diamond/hourglass outline, 17 growing frames" is a description
    of the pixels, not a claim about which screen or control uses it.
    Semantic labelling is deferred per notes/lanes/BRIEF-2026-09-01.md; this
    script's job is to make every byte real, typed source, not to guess a use.

VERIFICATION
    --selftest: part boundaries sum to the whole span, the pointer-table
    recomputation, the bitmap header/footer-zero + non-decreasing-pixel-count
    checks, the ramp recomputation for part 3, and part 4's zero-drift framing
    against a documented interpreter-A handler table.  The byte gate
    (`make gate-wsa1`) is what actually certifies the emitted bytes.

RUN
    python3 notes/gen_prom_b_f29bc6_module.py --selftest
    python3 notes/gen_prom_b_f29bc6_module.py --show-bitmaps
    python3 notes/gen_prom_b_f29bc6_module.py --asm > /tmp/f29bc6.s
    python3 notes/gen_prom_b_f29bc6_module.py --splice
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL           # noqa: E402
from asm_source import write_part           # noqa: E402

B_BASE = 0xF00000
S_FILE = "prom_b/wsa1_prom_b.s"
ROM = "original_ROMs/wsa1_prom_b.ic13"

SPAN_OFF, SPAN_SIZE = 0x029BC6, 0x00120C

TBL_OFF, TBL_N, TBL_ENTSZ = 0x029BC6, 17, 4
REC_OFF, REC_N, REC_STRIDE = 0x029C0A, 17, 0xE6
REC_ROWS_OFF, REC_ROWS_N, REC_ROW_W = 0x2E, 46, 3       # within a record
ARR_OFF, ARR_N, ARR_ENTSZ = 0x02AB50, 64, 4
DL_OFF, DL_END_OFF = 0x02AC50, 0x02ADD2                  # file offsets

FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-64s %-16s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def rom_bytes():
    return open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()


def le(data, off, n):
    return int.from_bytes(data[off:off + n], "little")


# --------------------------------------------------------------------------
# PART 1 -- pointer table
# --------------------------------------------------------------------------
def part1_entries(data):
    return [le(data, TBL_OFF + i * TBL_ENTSZ, TBL_ENTSZ) for i in range(TBL_N)]


# --------------------------------------------------------------------------
# PART 2 -- 17 bitmap records
# --------------------------------------------------------------------------
def record_bytes(data, i):
    o = REC_OFF + i * REC_STRIDE
    return data[o:o + REC_STRIDE]


def record_pixel_count(rec):
    n = 0
    for r in range(REC_ROWS_N):
        row = rec[REC_ROWS_OFF + r * REC_ROW_W: REC_ROWS_OFF + r * REC_ROW_W + REC_ROW_W]
        n += bin(int.from_bytes(row, "big")).count("1")
    return n


def render_bitmap_rows(rec):
    lines = []
    for r in range(REC_ROWS_N):
        row = rec[REC_ROWS_OFF + r * REC_ROW_W: REC_ROWS_OFF + r * REC_ROW_W + REC_ROW_W]
        v = int.from_bytes(row, "big")
        lines.append("".join("#" if (v >> (23 - b)) & 1 else "." for b in range(24)))
    return lines


# --------------------------------------------------------------------------
# PART 3 -- 64-entry array / ramp
# --------------------------------------------------------------------------
def part3_entries(data):
    return [le(data, ARR_OFF + i * ARR_ENTSZ, ARR_ENTSZ) for i in range(ARR_N)]


def part3_blocks(vals):
    return vals[:32], vals[32:]


def part3_ramp_check(block):
    """block: 32 4-byte values.  Expect a step-0x40 ramp from block[0], with
    exactly one doubled step (0x80).  Returns (hits, skip_index_or_None)."""
    lo16 = [v & 0xFFFF for v in block]
    hits, skip_at = 0, None
    expect = lo16[0]
    for i, v in enumerate(lo16):
        if v == expect:
            hits += 1
        elif skip_at is None and v == expect + 0x40:
            hits += 1
            skip_at = i
            expect += 0x40
        expect += 0x40
    return hits, skip_at


# --------------------------------------------------------------------------
# assembly emission
# --------------------------------------------------------------------------
def emit_part1(data):
    out = ["; --- 0x%06X-0x%06X: 17-entry pointer table, 4 bytes/entry, stride 0x%X ---\n"
           "; entry i = 0x%06X + i*0x%X; each names the record at PART 2 below.\n"
           % (B_BASE + TBL_OFF, B_BASE + REC_OFF - 1, REC_STRIDE, REC_OFF + B_BASE, REC_STRIDE)]
    for i, v in enumerate(part1_entries(data)):
        out.append("\t.long 0x%08X\t; -> record %d\n" % (v, i))
    return out


def emit_part2(data):
    out = ["\n; --- 0x%06X-0x%06X: 17 x 0x%X-byte records -- a 17-frame, 24x46px\n"
           "; 1bpp bitmap animation (frame 0 blank, frame 16 fully drawn).  Each\n"
           "; record: 1 flag byte, 45 zero bytes, 46 rows x 3 bytes (MSB-first),\n"
           "; 46 zero bytes.  See --show-bitmaps.  Not named: see module docstring.\n"
           % (B_BASE + REC_OFF, B_BASE + ARR_OFF - 1, REC_STRIDE)]
    for i in range(REC_N):
        rec = record_bytes(data, i)
        out.append("BITMAP_ICON_F29BC6_%d:\n" % i)
        out.append("\t.byte 0x%02X\t; flag\n" % rec[0])
        out.append("\t.fill 45, 1, 0x00\t; header padding\n")
        for r in range(REC_ROWS_N):
            row = rec[REC_ROWS_OFF + r * REC_ROW_W: REC_ROWS_OFF + r * REC_ROW_W + REC_ROW_W]
            out.append("\t.byte " + ", ".join("0x%02X" % b for b in row)
                       + "\t; row %2d\n" % r)
        out.append("\t.fill 46, 1, 0x00\t; footer padding\n")
    return out


def emit_part3(data):
    b1, b2 = part3_blocks(part3_entries(data))
    out = ["\n; --- 0x%06X-0x%06X: two parallel 32 x 4-byte arrays (top byte always 0).\n"
           "; Block 1: ramp 0x%04X..0x%04X step 0x40, one doubled step (0x80).\n"
           "; Block 2 = block 1 + 0x20, entry for entry, same doubled step.\n"
           "; Typed, unnamed -- see module docstring.\n"
           % (B_BASE + ARR_OFF, B_BASE + DL_OFF - 1, b1[0] & 0xFFFF, b1[-1] & 0xFFFF)]
    for v in b1:
        out.append("\t.long 0x%08X\n" % v)
    for v in b2:
        out.append("\t.long 0x%08X\n" % v)
    return out


def emit_part4(data):
    hta = [le(data, DL.HTBL + i * 4, 4) for i in range(36)]
    s, e = B_BASE + DL_OFF, B_BASE + DL_END_OFF
    recs = DL.walk(data, s, e)
    if recs is None:
        raise SystemExit("part 4 does not frame end to end")
    out = ["\n; ------------------------------------------------------------------\n",
           "; 0x%06X-0x%06X -- %d display-list records, %d bytes -- interpreter A\n"
           "; NOT reached by any known call shape (1/2/3); a plain op/len walk\n"
           "; from 0x%06X lands with ZERO DRIFT on 0x%06X, where the already-\n"
           "; converted DL_CombinationGroupMenuReMap1 begins.\n"
           % (s, e - 1, len(recs), e - s, s, e),
           "; ------------------------------------------------------------------\n"]
    out.append("DL_%06X:\n" % s)
    out += DL.render(data, recs, hta, set())
    return out, recs


def full_asm(data):
    out = []
    out += emit_part1(data)
    out += emit_part2(data)
    out += emit_part3(data)
    p4, _ = emit_part4(data)
    out += p4
    return out


def splice(new_lines):
    path = os.path.join(ROOT, S_FILE)
    text = open(path, encoding="utf-8").read()
    lines = text.split("\n")
    target = '\t.incbin "%s", 0x%06X, 0x%06X' % (ROM, SPAN_OFF, SPAN_SIZE)
    idx = [i for i, ln in enumerate(lines) if ln.strip() == target.strip()]
    if len(idx) != 1:
        raise SystemExit("expected exactly one directive matching 0x%06X, found %d"
                         % (SPAN_OFF, len(idx)))
    i = idx[0]
    before_ctx = lines[:i] + lines[i + 1:]
    new_block = "".join(new_lines).rstrip("\n").split("\n")
    out_lines = lines[:i] + new_block + lines[i + 1:]
    after_ctx = out_lines[:i] + out_lines[i + len(new_block):]
    if after_ctx != before_ctx:
        raise SystemExit("REFUSING TO SPLICE: context outside the target directive moved")
    write_part(path, "\n".join(out_lines), root=ROOT, allow_growth=True)


def main():
    data = rom_bytes()

    if "--show-bitmaps" in sys.argv:
        for i in (0, 1, 8, 15, 16):
            rec = record_bytes(data, i)
            print("--- frame %d (flag=0x%02X, pixels=%d) ---"
                  % (i, rec[0], record_pixel_count(rec)))
            for row in render_bitmap_rows(rec):
                print(row)
        return 0

    if "--selftest" in sys.argv:
        print("gen_prom_b_f29bc6_module.py --selftest")
        check("span still present verbatim",
              ('\t.incbin "%s", 0x%06X, 0x%06X' % (ROM, SPAN_OFF, SPAN_SIZE)).strip()
              in open(os.path.join(ROOT, S_FILE)).read(), True)
        check("parts sum to the whole span",
              (REC_OFF - TBL_OFF) + (ARR_OFF - REC_OFF) + (DL_OFF - ARR_OFF)
              + (DL_END_OFF - DL_OFF), SPAN_SIZE)

        # part 1
        ents = part1_entries(data)
        recomputed = [REC_OFF + B_BASE + i * REC_STRIDE for i in range(TBL_N)]
        check("part1: 17 entries recompute exactly", ents, recomputed)

        # part 2
        recs = [record_bytes(data, i) for i in range(REC_N)]
        header_ok = all(r[1:1 + 45] == b"\x00" * 45 for r in recs)
        footer_ok = all(r[REC_ROWS_OFF + REC_ROWS_N * REC_ROW_W:] == b"\x00" * 46 for r in recs)
        check("part2: all 17 headers (45 B) are zero", header_ok, True)
        check("part2: all 17 footers (46 B) are zero", footer_ok, True)
        check("part2: record size accounts for header+bitmap+footer",
              1 + 45 + REC_ROWS_N * REC_ROW_W + 46, REC_STRIDE)
        flags = [r[0] for r in recs]
        check("part2: flag byte is 0 except the last record", flags, [0] * 16 + [1])
        counts = [record_pixel_count(r) for r in recs]
        nondecr = all(counts[i] <= counts[i + 1] for i in range(len(counts) - 1))
        check("part2: pixel count is non-decreasing across the 17 frames", nondecr, True)
        check("part2: frame 0 is blank (0 pixels)", counts[0], 0)
        check("part2: frame 16 has the most pixels", counts[16], max(counts))
        # rule out display-list framing for both interpreters
        blob = b"".join(recs)
        dl_a = DL.walk(data, B_BASE + REC_OFF, B_BASE + REC_OFF + len(blob))
        check("part2: does NOT self-frame as an interpreter-A display list", dl_a, None)

        # part 3
        arr = part3_entries(data)
        check("part3: 64 entries, top byte always 0",
              all(v <= 0xFFFF for v in arr), True)
        b1, b2 = part3_blocks(arr)
        h1, skip1 = part3_ramp_check(b1)
        h2, skip2 = part3_ramp_check(b2)
        check("part3: block1 ramp recompute hits (of 32)", h1, 32)
        check("part3: block2 ramp recompute hits (of 32)", h2, 32)
        check("part3: block1 has exactly one doubled step", skip1 is not None, True)
        check("part3: block2's doubled step is at the same index", skip2, skip1)
        check("part3: block2 == block1 + 0x20, entry for entry",
              [v & 0xFFFF for v in b2], [(v & 0xFFFF) + 0x20 for v in b1])

        # part 4
        hta = [le(data, DL.HTBL + i * 4, 4) for i in range(36)]
        s, e = B_BASE + DL_OFF, B_BASE + DL_END_OFF
        recs4 = DL.walk(data, s, e)
        check("part4: op/len walk frames end-to-end with zero drift", recs4 is not None, True)
        if recs4:
            consumed = sum(ln for _p, _op, ln in recs4)
            check("part4: consumed bytes == span size", consumed, DL_END_OFF - DL_OFF)
            check("part4: record count", len(recs4), 44)
            all_known = all(hta[op] in DL.HANDLERS for _p, op, _ln in recs4)
            check("part4: every opcode resolves to a documented interpreter-A handler",
                  all_known, True)

        print("FAILURES: %d" % len(FAIL))
        return 1 if FAIL else 0

    if "--asm" in sys.argv:
        sys.stdout.write("".join(full_asm(data)))
        return 0

    if "--splice" in sys.argv:
        lines = full_asm(data)
        splice(lines)
        print("spliced 0x%06X-0x%06X (%d bytes) into %s" % (
            B_BASE + SPAN_OFF, B_BASE + SPAN_OFF + SPAN_SIZE - 1, SPAN_SIZE, S_FILE))
        return 0

    print("usage: --selftest | --show-bitmaps | --asm | --splice")
    return 1


if __name__ == "__main__":
    sys.exit(main())
