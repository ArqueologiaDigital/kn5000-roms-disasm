#!/usr/bin/env bash
# dlyseed_run.sh -- capture ONE seeded LLE frame trace of an effect program and confront it.
#
#   dsp/tools/dlyseed_run.sh <TYPEIDX> <OUT.log> [--lo N --hi M] [ENV=VAL ...]
#
# TYPEIDX = DSP EFFECT page index fx_ab.lua navigates to (0 CHORUS, 3 FLANGER, 7 SINGLE DELAY ...).
# The trace frame is computed from fx_ab.lua's own schedule: NOTE ON lands at
#   36.0 s + 0.2 s x TYPEIDX   (each UP tap is two 0.10 s steps)
# and the frame is armed 1.0 s after it (44100 frames/s), inside the 3.5 s note.  Extra
# ENV=VAL arguments (e.g. UPD6383_DLY07DRAM=1) are exported to the emulator; UPD6383_DLYSEED2=1
# is always on.  Runs from the kn7000_mame_build tree, with a visible window, timeout-wrapped;
# then copies error.log to OUT.log and runs dlyseed_confront.py on it.
set -u
TYPEIDX=${1:?TYPEIDX}; OUT=${2:?OUT.log}; shift 2
LO=84; HI=130; EXTRA=()
while [ $# -gt 0 ]; do
  case "$1" in
    --lo) LO=$2; shift 2;;
    --hi) HI=$2; shift 2;;
    *=*)  EXTRA+=("$1"); shift;;
    *)    echo "unknown arg $1"; exit 2;;
  esac
done
HERE=$(cd "$(dirname "$0")" && pwd)
BUILD=${KN7000_BUILD:-$HOME/compartilhado/kn7000_mame_build}
NOTE_T=$(python3 -c "print(36.0 + 0.2*$TYPEIDX)")
FRAME=$(python3 -c "print(int(($NOTE_T + 1.0) * 44100))")
echo "TYPEIDX=$TYPEIDX note-on ~${NOTE_T}s  TRACE_FRAME=$FRAME  extra: ${EXTRA[*]:-none}"
cd "$BUILD" || exit 1
rm -f error.log
env DISPLAY=${DISPLAY:-:0} DHLE=0 DSPCFG=3 TYPEIDX="$TYPEIDX" NOTEMODE=0 TGM=0 \
    UPD6383_DLYSEED2=1 UPD6383_TRACE_FRAME="$FRAME" "${EXTRA[@]}" \
    timeout 180 ./kn7000 kn5000 -rompath ./roms -skip_gameinfo -log -window \
    -autoboot_script "$HERE/fx_ab.lua" > /dev/null 2>&1
echo "rc=$?  LANDED=$(grep -c '### LANDED' error.log)  blocks=$(grep -c 'TIME-ORDERED FRAME TRACE' error.log)"
cp error.log "$OUT"
python3 "$HERE/dlyseed_confront.py" "$OUT" --lo "$LO" --hi "$HI"
