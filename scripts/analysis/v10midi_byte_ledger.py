#!/usr/bin/env python3
"""Question answered: for the two directories this lane owns, where does every
remaining raw `.byte` operand byte belong -- and is it debt at all?

A `.byte` count is not a debt count. This script PARTITIONS every `.byte`
operand byte of a file into exactly one bucket, and prints the partition with
its total so the buckets can be checked against a plain count:

  (b) DATA-UNTYPED   the byte lies in a region the pointer-array test of
                     v10_byte_run_classifier.py identifies as a table; it
                     should be typed, and typing it needs an INDEXING RULE
                     read off the code that loads the base.
  (c) BYTE-TABLE     a run of >= 8 bytes with no pointer structure inside a
                     region that is almost entirely `.byte`: a genuine
                     byte-valued table, already correctly represented, NOT debt.
  (d) BLOCKED        re-framing the run needs an instruction the installed
                     decoder cannot decode. Sub-split by the blocking byte
                     value, because that list is the work order for the
                     backend. (d-blind) is the {0x01, 0x04} subset -- gaps that
                     unidasm decodes as real instructions.
  (a) CODE-AS-BYTE   the run is inside code the decoder CAN decode, but this
                     lane refused to re-frame it: the span contains a string
                     literal, or its text does not re-assemble to the same
                     bytes, or no anchor exists on one side.

HOW THIS CAN BE WRONG. Bucket (b) rests on the pointer test, whose measured
error rates against regions of known class are printed by
`v10_byte_run_classifier.py --control`. Its miss direction dominates: short
tables (< 8 entries) and non-pointer tables are NOT detected, so bucket (a) and
(c) may still hide data. That is the safe direction -- an undetected data
region is left alone rather than converted to instructions -- but it means (b)
is a LOWER BOUND on the data still to type, not the whole of it.

Exact commands (from the repo root):

    python3 scripts/analysis/v10_line_address_map.py \
        v10/maincpu/midi/midi_dispatch_handlers.s \
        v10/maincpu/display/scoop_display.s --out /tmp/lm.json
    python3 scripts/analysis/v10midi_byte_ledger.py --linemap /tmp/lm.json \
        v10/maincpu/midi/midi_dispatch_handlers.s \
        v10/maincpu/display/scoop_display.s
"""
import argparse
import collections
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import v10_byte_run_classifier as C
import v10_reframe as R
import v10_reframe_code_runs as F

ROM_BASE = 0xE00000


def ptr_arrays(rom, a, b, minn=C.MIN_PTRS):
    """Maximal runs of >= minn consecutive in-range LE u32 inside [a, b), over
    every start alignment. Returns a list of (start, end) addresses."""
    out = []
    for k in range(4):
        run, i = [], a + k
        while i + 4 <= b:
            v = int.from_bytes(rom[i - ROM_BASE:i - ROM_BASE + 4], "little")
            if C.in_target(v):
                run.append(i)
            else:
                if len(run) >= minn:
                    out.append((run[0], run[-1] + 4))
                run = []
            i += 4
        if len(run) >= minn:
            out.append((run[0], run[-1] + 4))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="+")
    ap.add_argument("--linemap", required=True)
    args = ap.parse_args()
    rom = R.rom_bytes()
    maps = json.load(open(args.linemap))
    grand = collections.Counter()
    blockers = collections.Counter()
    for rel in args.files:
        lm = {int(k): v for k, v in maps[rel].items()}
        path = os.path.join(R.ROOT, rel)
        lines, regions = C.parse(path, lm)
        tot = sum(len(l.strip()[5:].split(",")) for l in lines
                  if l.strip().startswith(".byte"))
        buckets = collections.Counter()
        for reg in regions:
            runs = F.byte_runs(lines, lm, reg["ln"], reg["end_line"])
            if not runs or reg["end"] <= reg["addr"]:
                continue
            data = rom[reg["addr"] - ROM_BASE:reg["end"] - ROM_BASE]
            nbreg = sum(C.byte_bytes(lines, f, l + 1) for f, l, _, _ in runs)
            # ⚠ A region-level verdict is not a run-level verdict: these two
            # files have regions where a pointer table and 90 lines of ordinary
            # code share one label, and charging every `.byte` in them to DATA
            # overstated bucket (b) by 10x. Locate the ARRAYS inside the region
            # and ask whether THIS RUN overlaps one.
            arrays = ptr_arrays(rom, reg["addr"], reg["end"])
            bounds, texts, bad = F.sweep(rom, reg["addr"], reg["end"])
            lineaddr = set(lm[k] for k in lm if reg["ln"] <= k < reg["end_line"])
            anchors = sorted(bounds & lineaddr)
            for f, l, s, e in runs:
                nb = C.byte_bytes(lines, f, l + 1)
                # A run the tree DOCUMENTS as a table -- an indexing rule
                # stated in the comment above it -- is already correct, not
                # debt. This is asked FIRST: a documented byte table can sit
                # immediately after a pointer array, and the alignment-free
                # array search will happily run one word past its end.
                doc = "".join(lines[max(0, f - 12):f - 1])
                if nb >= 8 and ("INDEXING RULE" in doc or "byte table" in doc):
                    buckets["c-BYTE-TABLE (documented)"] += nb
                    continue
                if any(a0 < e and s < a1 for a0, a1 in arrays):
                    buckets["b-DATA-UNTYPED"] += nb
                    continue
                lo = [x for x in anchors if x <= s]
                hi = [x for x in anchors if x >= e]
                if not lo or not hi:
                    buckets["a-CODE-AS-BYTE (no anchor)"] += nb
                    continue
                A, B = lo[-1], hi[0]
                badhere = [x for x in bad if A <= x < B]
                swallow = [x for x in range(A, B)
                           if x not in texts and rom[x - ROM_BASE] in F.BLIND]
                if badhere or swallow:
                    vals = ({rom[x - ROM_BASE] for x in badhere}
                            | {rom[x - ROM_BASE] for x in swallow})
                    for v in vals:
                        blockers[v] += nb
                    if vals & F.BLIND:
                        buckets["d-BLOCKED (blind 0x01/0x04)"] += nb
                    else:
                        buckets["d-BLOCKED (other backend gap)"] += nb
                    continue
                buckets["a-CODE-AS-BYTE (refused)"] += nb
        acc = sum(buckets.values())
        print("=" * 74)
        print("%s   %d .byte operand bytes" % (rel, tot))
        for k in sorted(buckets):
            print("   %-32s %6d" % (k, buckets[k]))
        print("   %-32s %6d  (unclassified: %d, in regions with no label span)"
              % ("PARTITION TOTAL", acc, tot - acc))
        grand.update(buckets)
        grand["TOTAL .byte"] += tot
    print("=" * 74)
    for k in sorted(grand):
        print("   %-32s %6d" % (k, grand[k]))
    print("\n   blocking byte values, by .byte bytes they hold up:")
    for v, n in blockers.most_common(15):
        print("     0x%02x  %5d B" % (v, n))


if __name__ == "__main__":
    main()
