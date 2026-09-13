#!/usr/bin/env bash
# detector_pickup_census.sh -- DO THE DECODED LEVEL-DETECTOR PROGRAMS GET AN INPUT AT ALL?
#
#   dsp/tools/detector_pickup_census.sh [OUTDIR]
#
# QUESTION IT ANSWERS
#   N-INPUT-GATE-OPENED §62 found `prog32_distortion' reading STATIC because its pickup cell was
#   RAILED, and this session's opening commit then NARROWED that to "one program, not the dynamics
#   family".  ⛔ That narrowing rested on a 14-program sample containing **no standalone dynamics
#   program except the distortion** -- no compressor, enhancer, auto wah or NO OPERATION.  This
#   captures exactly those four, which `dsp/algorithms/families.md' groups as the programs carrying
#   a LEVEL DETECTOR, and reads their input cells.
#
#   MEASURED 2026-09-13 (§70): **4 of 4 RAIL** -- enhancer +8388607, compressor -8388608,
#   no_operation -8388608, auto_wah +8388607.  ★ `prog00_no_operation' railing is what settles that
#   this is OUR defect: a dry pass-through cannot legitimately saturate its own input.
#
# ⚠⚠ THE MACHINE MATTERS AND OMITTING IT LOOKS LIKE A RESULT.  `catalogue_regression.sh' passes
#   `UPD6383_PSHIFT=2 UPD6383_C8SHIFT=1' as baseline arms.  PSHIFT=2 sets total shift 23 instead of
#   22, which HALVES every datum -- exactly the quantity that decides whether the clamp at `iw45'
#   fires.  This census OVERRIDES them back to the device default, because the question is what the
#   SHIPPED device does.  ⇒ its output must NEVER be pooled with captures taken with the arms on
#   (which is what `data/railed_pickups_2026-09-13.txt' is).  See `pshift_2x2.sh' for the 2x2 that
#   settled that the rail is an INTERACTION of the two.
#
# Each program costs two emulator runs.  Visible window, timeout-wrapped, notes playing (RULE 12),
# every identity fingerprinted by the harness.
set -u
OUT=${1:-/tmp/detector_pickups}
HERE=$(cd "$(dirname "$0")" && pwd)

#   TYPE 2 enhancer | 13 compressor | 14 NO OPERATION | 18 auto wah  (dsp/analysis/data/typewalk/TYPE_MAP.md)
TYPES="2 13 14 18" NOTEOFS=2.5 "$HERE/catalogue_regression.sh" "$OUT" \
	UPD6383_PSHIFT=0 UPD6383_C8SHIFT=0

echo
echo "=== the four decoded LEVEL-DETECTOR programs, at the TRUE DEFAULT ==="
python3 "$HERE/pickup_cells.py" "$OUT"/t2_F.log "$OUT"/t13_F.log "$OUT"/t14_F.log "$OUT"/t18_F.log
