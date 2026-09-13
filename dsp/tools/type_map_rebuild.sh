#!/usr/bin/env bash
# type_map_rebuild.sh -- rebuild the DSP EFFECT TYPE map BY FINGERPRINT, one index at a time.
#
#   dsp/tools/type_map_rebuild.sh <OUTDIR> [FIRST] [LAST]
#
# WHY
#   `dsp/analysis/data/typewalk/TYPE_MAP.md` was built by matching *distinct consecutive* program
#   images, so two adjacent slots sharing one image collapsed into a single row and every later
#   index shifted. The result is a map that cannot be trusted above index 8, which blocks every
#   index-addressed experiment on 28 of the 38 programs.
#
#   This rebuilds it the only way that cannot collapse rows: select each index with the CALIBRATED
#   transport and IDENTIFY WHAT ACTUALLY LOADED, from the machine's own upload capture.
#
# ★ THE CALIBRATION THIS DEPENDS ON (MEASURED 2026-09-13): the list has **38 entries (0..37)**,
#   not 36, so `type_select.lua` needs `TYPELAST=37`. At the old 35 both known-answer controls
#   landed exactly two slots high (`TYPEIDX 0 -> prog03_enhancer`, `15 -> prog50_vibrato`); at 37
#   both pass (`prog01_chorus`, `prog39_parametric_eq`). See TYPE_MAP.md's banner.
#
# ⚠ TWO TRAPS, each of which cost a run:
#   * these lua scripts print to STDOUT/STDERR, **not** `error.log` -- capture with `> f 2>&1`;
#   * the panel title read at `0x30AE5` returns garbage in this build, so the DISPLAY cannot
#     identify the program. Only the upload fingerprint can.
#
# Each index costs one emulator run. Visible window, timeout-wrapped.
set -u
OUT=${1:?OUTDIR}
FIRST=${2:-0}
LAST=${3:-37}
HERE=$(cd "$(dirname "$0")" && pwd)
BUILD=${KN7000_BUILD:-$HOME/compartilhado/kn7000_mame_build}
TYPELAST=${TYPELAST:-37}
mkdir -p "$OUT"

echo "=== type_map_rebuild: indices $FIRST..$LAST, TYPELAST=$TYPELAST -> $OUT ==="
for ti in $(seq "$FIRST" "$LAST"); do
  ( cd "$BUILD" && rm -f kn5000_dsp1_upload.txt && \
    env DISPLAY=${DISPLAY:-:0} TYPEIDX="$ti" TYPELAST="$TYPELAST" \
        timeout 110 ./kn7000 kn5000 -rompath ./roms -skip_gameinfo -window \
        -autoboot_script "$HERE/type_select.lua" > /dev/null 2>&1
    cp kn5000_dsp1_upload.txt "$OUT/up_t${ti}.txt" 2>/dev/null )
  printf "TYPE %2d  " "$ti"
  python3 "$HERE/type_fingerprint.py" "$OUT/up_t${ti}.txt" 2>/dev/null | sed 's/^[^ ]* *//'
done
echo "=== done; the table is the lines above, each one MEASURED from the machine's own upload ==="
