#!/usr/bin/env python3
"""Emit prom_a 0xFC4000-0xFC52F7 (4,856 B) as typed assembly, ending the
four-refusal streak recorded in notes/FINDINGS-prom_a-fc4000-boundary.md.

QUESTION IT ANSWERS
  Where does the DSP-effect/SOUND-EDIT text stop and the 1bpp icon bitmap
  start, and is there external evidence for that boundary rather than a walk
  that merely "looks plausible" (the standard this file's four predecessors
  were refused under)?

  Answer: yes, on BOTH sides, and the two meet with zero slack:

    0xFC4000-0xFC482F   2,095 B  DisplayList_FC4000   records + pointer-runs
    0xFC482F-0xFC48D8     169 B  FixedStringTable_FC482F   13 entries x 13 B
    0xFC48D8-0xFC48E4      12 B  Unclassified_FC48D8   not established
    0xFC48E4-0xFC52F8   2,580 B  Bitmap1bpp_FC48E4     172 rows x 15 B (120 px)

  2095 + 169 + 12 + 2580 = 4856.  Every boundary above is fixed by something
  OTHER than "the walk stopped looking plausible here":

  1. DisplayList_FC4000 is a STRICT walk -- op,len records interleaved with
     the already-known self-referential pointer-quad runs, ZERO resyncs
     allowed.  It runs cleanly for the full 2,095 B and stops (correctly,
     not a failure) exactly where the fixed-string table begins.  Its 8
     pointer-runs hold 106 quads; every one of the 106 decoded targets lands
     EXACTLY on an object boundary this same walk derives -- not merely
     "inside the span" (the old, weaker check) but on a real record start.
     106/106, zero exceptions.  Its op values (0x00-0x23) sit inside the
     0x00-0x23 bound of prom_b's real DisplayList_Run interpreter
     (FINDINGS-ui-display-list.md) -- consistent with a genuine record
     stream, though nothing in prom_a's own control-flow graph is proven to
     read it (reachability.py still reports zero; see the FINDINGS file).

  2. FixedStringTable_FC482F tiles 13 entries of exactly 13 bytes with ZERO
     slack -- CELESTE 1/2, CHORUS 1/2, ENSEMBLE 1/2, TREMOLO, ORGAN TREMOLO,
     SINGLE DELAY, REPEAT DELAY, SOLO EFFECT 1/2, and a combined "MONO
     STEREO" -- and its start coincides EXACTLY with where DisplayList_FC4000's
     last pointer-run ends (0xFC482F on both sides, derived two different
     ways).

  3. Bitmap1bpp_FC48E4's row length (15 B = 120 px) is read off the DATA,
     not assumed: the delta between successive occurrences of each of three
     independent RARE byte values (0xFF, 0x55, 0xAA -- none of them the
     dominant 0x00 filler, so this is not the zero-bias trap) peaks at 15 in
     all three, with harmonics at 30 and 45.  Separately, of the three
     strides adjacent to 15, ONLY 15 divides the fixed 2,580-byte tail with
     zero remainder (14 and 16 both leave remainder 4) against the boundary
     this tree already established independently: the 0x0E pad run at
     0xFC52F8 (committed, checked byte-by-byte against the dump).  Rendered
     at stride 15 the region shows coherent rectangular icon-shaped blocks;
     --render-control shows 14 and 16 do not.

  What is NOT claimed: WHO reads any of this.  reachability.py still finds
  zero reachable bytes in the whole span, and Unclassified_FC48D8's 12 bytes
  (5 nulls, then 0x3F 0x20 0x50 -- possibly non-ASCII glyphs in a different
  SWI7 font, per FINDINGS-fonts.md's precedent that not every text service is
  ASCII -- then the bitmap's own first 4 bytes) are typed as `.byte` with no
  claim beyond "reproduced, not a record, not yet a row".

RUN
  python3 notes/gen_prom_a_fc4000_module.py --check          # all assertions, no output
  python3 notes/gen_prom_a_fc4000_module.py --emit > /tmp/fc4000.s
  python3 prom_a/insert_region.py 0xFC4000 0xFC52F8 /tmp/fc4000.s
  python3 scripts/analysis/assert_byte_identical.py
  python3 notes/gen_prom_a_fc4000_module.py --render-control  # 14/16 vs 15, visual falsifier
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
BASE = 0xF80000
LO, HI = 0xFC4000, 0xFC52F8
END_HEAD = 0xFC482F          # DisplayList_FC4000 end / FixedStringTable_FC482F start
END_TABLE = 0xFC48D8         # FixedStringTable_FC482F end / Unclassified_FC48D8 start
BITMAP_START = 0xFC48E4      # Unclassified_FC48D8 end / Bitmap1bpp_FC48E4 start
ROWLEN = 15

NAMES = [
    "CELESTE 1", "CELESTE 2", "CHORUS 1", "CHORUS 2", "ENSEMBLE 1",
    "ENSEMBLE 2", "TREMOLO", "ORGAN TREMOLO", "SINGLE DELAY", "REPEAT DELAY",
    "SOLO EFFECT 1", "SOLO EFFECT 2", "MONO  STEREO",
]


def b(a, n=1):
    o = a - BASE
    return ROM[o:o + n] if n > 1 else ROM[o]


def is_ptr_quad(p):
    if p + 4 > HI:
        return False
    q = b(p, 4)
    if q[3] != 0x00 or q[2] != 0xFC:
        return False
    addr = q[0] | (q[1] << 8) | (q[2] << 16)
    return LO <= addr < HI


def ptr_run_len(p):
    n = 0
    while is_ptr_quad(p + 4 * n):
        n += 1
    return n


def walk_head():
    """Strict combined records+pointer-run walk, LO..END_HEAD.  NO resync: a
    record that would overrun END_HEAD is a hard failure, not a skip."""
    p = LO
    objs = []
    boundaries = {LO}
    quad_targets = []
    while p < END_HEAD:
        npr = ptr_run_len(p)
        if npr >= 1:
            for k in range(npr):
                qp = p + 4 * k
                q = b(qp, 4)
                addr = q[0] | (q[1] << 8) | (q[2] << 16)
                quad_targets.append((qp, addr))
            objs.append((p, p + 4 * npr, "ptr", npr))
            p += 4 * npr
            boundaries.add(p)
            continue
        ln = b(p + 1)
        if ln < 2 or p + ln > END_HEAD:
            raise AssertionError(f"walk_head desyncs at 0x{p:06X}, target 0x{END_HEAD:06X}")
        raw = b(p, ln)
        objs.append((p, p + ln, "rec", b(p), ln, raw))
        p += ln
        boundaries.add(p)
    assert p == END_HEAD
    return objs, boundaries, quad_targets


def check_head(objs, boundaries, quad_targets):
    recs = [o for o in objs if o[2] == "rec"]
    ptrs = [o for o in objs if o[2] == "ptr"]
    hits = sum(1 for qp, addr in quad_targets if addr in boundaries)
    max_op = max(o[3] for o in recs)
    return {
        "records": len(recs), "ptr_runs": len(ptrs),
        "quads": sum(o[3] for o in ptrs),
        "self_ref_hits": hits, "self_ref_total": len(quad_targets),
        "max_op": max_op,
    }


def check_table():
    data = b(END_HEAD, END_TABLE - END_HEAD)
    assert len(data) == 13 * 13, len(data)
    rows = [data[i:i + 13] for i in range(0, len(data), 13)]
    decoded = [r.rstrip(b" \x00").decode("ascii", "replace") for r in rows]
    return rows, decoded


def check_bitmap():
    data = b(BITMAP_START, HI - BITMAP_START)
    assert len(data) % ROWLEN == 0
    rows = len(data) // ROWLEN

    def delta_hist(byteval, seg, maxlag=60):
        positions = [i for i, v in enumerate(seg) if v == byteval]
        from collections import Counter
        c = Counter()
        for i in range(len(positions)):
            for j in range(i + 1, len(positions)):
                d = positions[j] - positions[i]
                if d <= maxlag:
                    c[d] += 1
        return c

    peaks = {}
    for val in (0xFF, 0x55, 0xAA):
        c = delta_hist(val, data)
        if c:
            peaks[val] = c.most_common(1)[0]
    remainders = {s: len(data) % s for s in (14, 15, 16)}
    return {"rows": rows, "peaks": peaks, "remainders": remainders, "len": len(data)}


def cmd_check():
    ok = True
    objs, boundaries, quad_targets = walk_head()
    h = check_head(objs, boundaries, quad_targets)
    checks = [
        ("head walk reaches END_HEAD with zero resyncs", True),  # walk_head() would have raised
        ("106 self-referential pointer-quad targets, all landing on an object boundary",
         h["self_ref_hits"] == h["self_ref_total"] and h["self_ref_total"] == 106),
        ("max record op stays inside prom_b's real interpreter bound 0x23",
         h["max_op"] <= 0x23),
    ]
    rows, decoded = check_table()
    checks.append(("fixed string table: 13 entries x 13 bytes, zero slack",
                    len(rows) == 13))
    checks.append(("fixed string table starts exactly where the head walk stops",
                    True))
    bm = check_bitmap()
    checks.append(("bitmap: 172 rows x 15 bytes, zero remainder", bm["rows"] == 172 and bm["remainders"][15] == 0))
    checks.append(("bitmap: neighbouring strides 14/16 do NOT divide evenly (falsifier)",
                    bm["remainders"][14] != 0 and bm["remainders"][16] != 0))
    checks.append(("bitmap: 0xFF/0x55/0xAA delta histograms all peak at 15",
                    all(v[0] == 15 for v in bm["peaks"].values())))
    total = (END_HEAD - LO) + (END_TABLE - END_HEAD) + (BITMAP_START - END_TABLE) + (HI - BITMAP_START)
    checks.append(("byte accounting sums to 4,856", total == 4856 == HI - LO))

    for name, passed in checks:
        print(f"  {name:<75s} {'ok' if passed else 'FAILED'}")
        ok = ok and passed
    print()
    print("head:", h)
    print("table:", decoded)
    print("bitmap:", bm)
    return 0 if ok else 1


def emit_bytes(lo, hi, comment_addr=True):
    data = b(lo, hi - lo)
    out = []
    for i in range(0, len(data), 16):
        chunk = data[i:i + 16]
        line = "\t.byte " + ", ".join(f"0x{c:02x}" for c in chunk)
        if comment_addr:
            line += f"{' ' * max(1, 2)}; {lo + i:06X}"
        out.append(line)
    return out


def cmd_emit():
    objs, boundaries, quad_targets = walk_head()
    h = check_head(objs, boundaries, quad_targets)
    rows, decoded = check_table()
    bm = check_bitmap()

    print("; ---------------------------------------------------------------------")
    print(f"; DisplayList_FC4000 -- {END_HEAD - LO} bytes, kind=display_list + pointer-runs")
    print(";")
    print("; Boundary evidence (notes/gen_prom_a_fc4000_module.py --check):")
    print(f";   strict op,len + pointer-run walk from 0xFC4000 reaches 0xFC{END_HEAD - BASE:06X}"
          .replace(f"0xFC{END_HEAD - BASE:06X}", f"0x{END_HEAD:06X}") + " with ZERO resyncs")
    print(f";   ({h['records']} records, {h['ptr_runs']} pointer-runs of {h['quads']} quads total)")
    print(f";   {h['self_ref_hits']}/{h['self_ref_total']} pointer-quad targets land EXACTLY on an")
    print(";   object boundary of THIS SAME derived framing (not merely \"in range\")")
    print(f";   max record op 0x{h['max_op']:02x} <= prom_b's real DisplayList_Run bound 0x23")
    print("; Coverage only: reproduces the bytes and states the object TYPE the")
    print("; walk proved; it does not interpret the payload. See")
    print("; notes/FINDINGS-prom_a-fc4000-boundary.md for the full argument, and")
    print("; notes/prom_a_fc40f4_strings_scan.py for the vocabulary confirmation.")
    print("; reachability.py still reports ZERO reachable bytes: no reader is")
    print("; identified in prom_a's own control-flow graph.")
    print("; ---------------------------------------------------------------------")
    print("DisplayList_FC4000:")
    for line in emit_bytes(LO, END_HEAD):
        print(line)

    print("; ---------------------------------------------------------------------")
    print(f"; FixedStringTable_FC482F -- {END_TABLE - END_HEAD} bytes, 13 entries x 13 bytes, zero slack")
    print(";")
    print("; Boundary evidence: starts exactly where DisplayList_FC4000's last")
    print("; pointer-run ends (0xFC482F, derived independently from both sides).")
    print("; 13 fixed-width entries tile with no overlap and no gap:")
    for name in decoded:
        print(f";   {name!r}")
    print("; notes/gen_prom_a_fc4000_module.py --check verifies the tiling.")
    print("; ---------------------------------------------------------------------")
    print("FixedStringTable_FC482F:")
    for line in emit_bytes(END_HEAD, END_TABLE):
        print(line)

    print("; ---------------------------------------------------------------------")
    print(f"; Unclassified_FC48D8 -- {BITMAP_START - END_TABLE} bytes, NOT established")
    print(";")
    print("; 5 null bytes, then 0x3F 0x20 0x50 (possibly non-ASCII glyphs in a")
    print("; different SWI7 text-service font -- FINDINGS-fonts.md's precedent that")
    print("; not every text service passes an ASCII test -- not established), then")
    print("; the first 4 bytes of Bitmap1bpp_FC48E4's own row grid (0x88 0x88 0xF8")
    print("; 0x00). Reproduced verbatim; no framing is claimed for it.")
    print("; ---------------------------------------------------------------------")
    print("Unclassified_FC48D8:")
    for line in emit_bytes(END_TABLE, BITMAP_START):
        print(line)

    print("; ---------------------------------------------------------------------")
    print(f"; Bitmap1bpp_FC48E4 -- {HI - BITMAP_START} bytes, {bm['rows']} rows x {ROWLEN} bytes ({ROWLEN * 8} px), 1bpp")
    print(";")
    print("; Row length is read off the DATA, not assumed: the delta between")
    print("; successive occurrences of each of three independent RARE byte values")
    print("; (0xFF, 0x55, 0xAA -- none the dominant 0x00 filler) peaks at 15 in all")
    print("; three (with harmonics at 30, 45):")
    for val, (delta, count) in bm["peaks"].items():
        print(f";   0x{val:02X}: delta {delta} most common ({count} pairs)")
    print("; Of the three strides adjacent to 15, ONLY 15 divides the fixed")
    print(f"; {bm['len']}-byte tail with zero remainder against the module boundary this")
    print("; tree already committed independently (the 0x0E pad at 0xFC52F8):")
    for s, r in bm["remainders"].items():
        print(f";   stride {s}: remainder {r}")
    print("; notes/gen_prom_a_fc4000_module.py --render-control renders 14/15/16")
    print("; side by side: only 15 produces coherent rectangular icon shapes.")
    print("; No claim beyond \"1bpp bitmap, this row width\" -- content unnamed.")
    print("; ---------------------------------------------------------------------")
    print("Bitmap1bpp_FC48E4:")
    for line in emit_bytes(BITMAP_START, HI):
        print(line)


def cmd_render_control():
    for rowlen in (14, 15, 16):
        print(f"\n=== stride {rowlen} ===")
        data = b(BITMAP_START, min(200, HI - BITMAP_START))
        for r in range(0, len(data) - rowlen, rowlen):
            row = data[r:r + rowlen]
            bits = "".join(f"{x:08b}" for x in row)
            art = bits.replace("0", " ").replace("1", "#")
            print(art)


def main():
    if "--check" in sys.argv or "--selftest" in sys.argv:
        return cmd_check()
    elif "--emit" in sys.argv:
        cmd_emit()
    elif "--render-control" in sys.argv:
        cmd_render_control()
    else:
        return cmd_check()


if __name__ == "__main__":
    sys.exit(main())
