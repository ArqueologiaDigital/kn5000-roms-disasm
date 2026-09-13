#!/usr/bin/env bash
# catalogue_sweep_sel.sh -- sweep HIGH TYPE indices with the CALIBRATED selector, and verify each.
#
#   dsp/tools/catalogue_sweep_sel.sh <OUTDIR> "<TYPES>" [ENV=VAL ...]
#
# WHY A SECOND SWEEP HARNESS
#   `catalogue_regression.sh` drives `fx_ab.lua`, which saturates DOWN to 0 and steps UP. §193
#   MEASURED that this DROPS STEPS at long distances (indices 28 and 30 both landed one slot
#   short), so it is trustworthy only for the short-distance regime -- which is why that harness
#   sweeps TYPE 0..8 plus 15. Everything above needs `type_select.lua`, which saturates UP and
#   walks a short distance DOWN.
#
# ★ AND EVERY RUN IS FINGERPRINTED. `type_select.lua`'s own header says it: a transport that is
#   merely *more* reliable is not a transport that is correct. Each run's `kn5000_dsp1_upload.txt`
#   is matched against the 38 listings (`type_fingerprint.py`, 16 words) and the identity is
#   printed beside the capture, so a mis-selection is visible in the output instead of silently
#   becoming a result. ⚠ Requires the calibrated `TYPELAST=37` (the list has 38 entries).
#
# ★ THE TRACE FRAME IS DERIVED FROM THE SELECTOR'S OWN SCHEDULE, not guessed:
#       t(NOTES ON) = 19.0 + 5.3 + 45*0.32 + 1.5 + 0.4*(LAST - TYPEIDX) + 2.0 + 0.5
#                   = 42.7 + 0.4*(LAST - TYPEIDX)     seconds
#   and the notes are held 6.0 s, so the frame is armed ONE SECOND AFTER note-on -- inside the
#   note (RULE 12: a DSP test with no notes playing is not a test).
#
# Visible window, timeout-wrapped. Each index costs one emulator run.
set -u
OUT=${1:?OUTDIR}; TYPES=${2:?"TYPES, e.g. \"29 30 33\""}; shift 2
EXTRA=(UPD6383_PSHIFT=2 UPD6383_C8SHIFT=1 "$@")
HERE=$(cd "$(dirname "$0")" && pwd)
BUILD=${KN7000_BUILD:-$HOME/compartilhado/kn7000_mame_build}
LAST=${TYPELAST:-37}
mkdir -p "$OUT"

echo "=== catalogue_sweep_sel -> $OUT : TYPES=[$TYPES] TYPELAST=$LAST : ${EXTRA[*]} ==="
for ti in $TYPES; do
  for off in 0 1; do
    frame=$(python3 -c "print(int((42.7 + 0.4*($LAST - $ti) + 1.0) * 44100) + $off)")
    tag=$([ "$off" = 0 ] && echo F || echo F1)
    ( cd "$BUILD" && rm -f error.log kn5000_dsp1_upload.txt && \
      env DISPLAY=${DISPLAY:-:0} TYPEIDX="$ti" TYPELAST="$LAST" DSPCFG=3 \
          UPD6383_TRACE_FRAME="$frame" "${EXTRA[@]}" \
          timeout 200 ./kn7000 kn5000 -rompath ./roms -skip_gameinfo -log -window \
          -autoboot_script "$HERE/type_select.lua" > /dev/null 2>&1
      cp error.log "$OUT/t${ti}_${tag}.log"
      [ "$off" = 0 ] && cp kn5000_dsp1_upload.txt "$OUT/up_t${ti}.txt" 2>/dev/null )
  done
  printf "TYPE %2d  frame=%s  " "$ti" "$(python3 -c "print(int((42.7 + 0.4*($LAST - $ti) + 1.0) * 44100))")"
  python3 "$HERE/type_fingerprint.py" "$OUT/up_t${ti}.txt" 2>/dev/null | sed 's/^[^ ]* *//'
done
echo "=== done --each row above names the program that ACTUALLY loaded ==="
