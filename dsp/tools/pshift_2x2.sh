#!/usr/bin/env bash
# pshift_2x2.sh -- IS THE RAILED PICKUP THE PROGRAM FAMILY, OR THE DATUM SCALE?
#
# N-INPUT-GATE-OPENED §70: 4 of 4 decoded LEVEL-DETECTOR programs rail their input cell 0x05 at the
# TRUE DEFAULT, while an earlier 14-program census found only 1 rail.  ⚠ Those two censuses are
# DIFFERENT MACHINES: the earlier one carried `UPD6383_PSHIFT=2 UPD6383_C8SHIFT=1'.  PSHIFT=2 sets
# P_SHIFT=7/ACC_SHIFT=16 -- total 23 instead of 22 -- which HALVES every datum, and the datum is
# exactly the quantity that decides whether iw45's bit-4 store clamps.  Pooling them would credit
# the PROGRAM FAMILY with something that may belong to the ARM.  That is the §229 trap.
#
# THE DESIGN: two cells, each holding the PROGRAM and the TRACE INSTANT fixed and changing ONLY the
# machine, against the two captures already on disk:
#
#     A  NO OPERATION (TYPE 14), rails at the default   -> re-run WITH the arms
#     B  FLANGER      (TYPE  3), fine with the arms     -> re-run at the TRUE DEFAULT
#
# Read the result with dsp/tools/pickup_cells.py.  Cells 0x01 and 0x04 double as an INTERNAL NULL:
# if the arm is doing what this claims, they should not move.
set -u
OUT=${1:-/tmp/pshift2x2}
HERE=$(cd "$(dirname "$0")" && pwd)
TYPES="14" NOTEOFS=2.5 "$HERE/catalogue_regression.sh" "$OUT/arms"
TYPES="3"  NOTEOFS=2.5 "$HERE/catalogue_regression.sh" "$OUT/def" UPD6383_PSHIFT=0 UPD6383_C8SHIFT=0
python3 "$HERE/pickup_cells.py" "$OUT/arms/t14_F.log" "$OUT/def/t3_F.log"
