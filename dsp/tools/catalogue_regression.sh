#!/usr/bin/env bash
# catalogue_regression.sh -- run a candidate decode across MORE THAN THE TWO REFERENCE PROGRAMS.
#
#   dsp/tools/catalogue_regression.sh <OUTDIR> [ENV=VAL ...]
#
# QUESTION IT ANSWERS
#   N-INPUT-GATE-OPENED §32's configuration passes all four gate criteria -- on CHORUS and
#   PARAMETRIC EQ.  Two programs is not the catalogue.  This captures a frame pair for each of a
#   family-spanning sample and dsp/tools/regression_report.py compares candidate against baseline.
#
# ★ THE SAMPLE, and why these indices.  dsp/analysis/data/typewalk/TYPE_MAP.md is the
#   authoritative TYPE map and carries a documented defect: **it is OFF BY ONE above index 8**
#   (two adjacent slots sharing one program image collapsed into one row).  So this sample uses
#   ONLY indices 0..8, which are unaffected, plus 15 (PARAMETRIC EQ), which was measured
#   independently by peq_select.lua and is one of the map's two known-answer controls:
#
#     0 CHORUS          1 MODULATED CHORUS   2 ENHANCER      3 FLANGER    4 PHASER
#     5 ENSEMBLE        6 GATED REVERB       7 SINGLE DELAY  8 MULTI TAP DELAY
#     15 PARAMETRIC EQ
#
#   That is the modulation family, the reverb family, both delay shapes and the biquad -- ten
#   programs, no index whose identity is in doubt.  ⚠ It is NOT the whole catalogue: the dynamics
#   (distortion/compressor) and the 14 combis sit above the off-by-one and need the TYPE walk
#   re-run without deduplication before they can be addressed by index.
#
# Each program costs two emulator runs.  Visible window, timeout-wrapped (RULE 12: the note is
# playing at the traced frame, by fx_ab.lua's own schedule).
set -u
OUT=${1:?OUTDIR}; shift
EXTRA=(UPD6383_PSHIFT=2 UPD6383_C8SHIFT=1 "$@")
HERE=$(cd "$(dirname "$0")" && pwd)
BUILD=${KN7000_BUILD:-$HOME/compartilhado/kn7000_mame_build}
TYPES=${TYPES:-"0 1 2 3 4 5 6 7 8 15"}
mkdir -p "$OUT"

echo "=== catalogue_regression -> $OUT : ${EXTRA[*]} ==="
for ti in $TYPES; do
  for off in 0 1; do
    note=$(python3 -c "print(36.0 + 0.2*$ti)")
    frame=$(python3 -c "print(int(($note + 1.0) * 44100) + $off)")
    tag=$([ "$off" = 0 ] && echo F || echo F1)
    ( cd "$BUILD" && rm -f error.log && \
      env DISPLAY=${DISPLAY:-:0} DHLE=0 DSPCFG=3 TYPEIDX="$ti" NOTEMODE=0 TGM=0 \
          UPD6383_TRACE_FRAME="$frame" "${EXTRA[@]}" \
          timeout 180 ./kn7000 kn5000 -rompath ./roms -skip_gameinfo -log -window \
          -autoboot_script "$HERE/fx_ab.lua" > /dev/null 2>&1
      cp error.log "$OUT/t${ti}_${tag}.log" )
  done
  echo "  TYPE $ti captured"
done
echo "=== done; compare with: python3 dsp/tools/regression_report.py --base <dir> --cand $OUT ==="
