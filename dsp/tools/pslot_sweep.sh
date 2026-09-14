#!/usr/bin/env bash
# pslot_sweep.sh -- sweep ONE env arm over a list of values and score the two consumers that
#                   N-INPUT-GATE-OPENED sect. 120 showed depend on the same word.
#
#   dsp/tools/pslot_sweep.sh <VAR> <v1,v2,...> [EXTRA_ENV=VAL ...]
#
# QUESTION IT ANSWERS
#   sect. 120 asked which C-format word's one-slot PRODUCT the chorus LFO and the per-unit hand-off
#   cell 0x05 depend on, and answered it by clearing the product at one I-RAM slot at a time.  This
#   is the harness that did it, and the same harness scores sect. 121's `hi12' bit-6 menu.
#
#     dsp/tools/pslot_sweep.sh UPD6383_PCLRIW 1,15,22,29,31,40,48,56     # ★ sect. 120, verbatim
#     dsp/tools/pslot_sweep.sh UPD6383_HI6C   0,1,2,3,4,5,6,7,8,9,10,11  # ★ sect. 121
#
# THE TWO CRITERIA, and why both are needed
#   (1) THE LFO RAMP.  `lfo-ramp.md' anchors the chorus increment NINE-FOLD at
#       floor(0.5993 * 2^23 / 44100) = 114, so the device's own sect. 228 rise census must report a
#       mean step of 114.  ⛔ RULE 13 / sect. 34: "114" is ALSO the starvation signature -- any
#       intervention that empties the product at the LFO entry reports it -- so it is not a test on
#       its own, which is exactly what criterion (2) is for.
#   (2) THE HAND-OFF CELL 0x05.  The per-unit hand-off (sect. 76's SRC0B2 promotion criterion) must
#       stay LIVE in the sect. 176 D-RAM census: present, wide (order +-2.9 M) and changing.  A
#       configuration that fixes the LFO by starving the input path fails here, and sect. 120
#       measured exactly that at `iw40'.
#
# ⚠ `UPD6383_CENSUS_PERPROG=1' IS NOT OPTIONAL.  The D-RAM and rise censuses accumulate from boot
#   and the capture harness steps UP through the effect list, so without it a threshold read off
#   one program is being applied to a cumulative total.  FIVE defective criteria were built that
#   way before sect. 103 added the per-program reset; see the blog's Part 231 closing paragraph.
#
# ⚠ THE FIRED COUNT IS PRINTED FIRST, ALWAYS (rule 15).  sect. 97 and sect. 100 each spent a run
#   on an arm that never reached the word it was aimed at, and sect. 100 needed THREE: a non-zero
#   fired count is still not the count you predicted.  Check it before reading any other column.
set -u
VAR=${1:?VAR -- the env arm to sweep, e.g. UPD6383_PCLRIW}
LIST=${2:?comma-separated values}
shift 2

HERE=$(cd "$(dirname "$0")" && pwd)
BUILD=${KN7000_BUILD:-$HOME/compartilhado/kn7000_mame_build}
OUTDIR=${OUTDIR:-${CLAUDE_JOB_DIR:-/tmp}/tmp}/pslot_$(echo "$VAR" | tr 'A-Z' 'a-z')
mkdir -p "$OUTDIR"
TI=${TYPEIDX_SWEEP:-0}          # 0 = CHORUS (the LFO program lfo-ramp.md anchors)

# The frame schedule is fx_ab.lua's own: NOTE ON at 36.0 s + 0.2 s x TYPEIDX, trace armed 1.0 s
# later (RULE 12 -- a DSP test with no notes playing is not a test).  Visible window, timeout-
# wrapped (the run-discipline memory).
cap() {   # cap <value> <out.log> [EXTRA_ENV=VAL ...]
  local v=$1 out=$2 note frame
  shift 2          # ⚠ WITHOUT THIS, `"$@"' below still holds <value> and <out.log> and `env'
                   #   tries to exec the log path.  Cost one silent empty sweep to find.
  note=$(python3 -c "print(36.0 + 0.2*$TI)")
  frame=$(python3 -c "print(int(($note + 1.0) * 44100))")
  ( cd "$BUILD" && rm -f error.log && \
    env DISPLAY=${DISPLAY:-:0} DHLE=0 DSPCFG=3 TYPEIDX="$TI" NOTEMODE=0 TGM=0 \
        UPD6383_CENSUS_PERPROG=1 UPD6383_TRACE_FRAME="$frame" "$VAR=$v" "$@" \
        timeout 240 ./kn7000 kn5000 -rompath ./roms -skip_gameinfo -log -window \
        -autoboot_script "$HERE/fx_ab.lua" > /dev/null 2>&1
    cp error.log "$out" 2>/dev/null )
}

printf '=== pslot_sweep %s over {%s} -- TYPEIDX %s, per-program census ===\n\n' "$VAR" "$LIST" "$TI"
printf '%-6s %-12s %-14s %s\n' "value" "fired" "LFO mean" "hand-off cell 0x05"
IFS=',' read -ra VALS <<< "$LIST"
for v in "${VALS[@]}"; do
  L="$OUTDIR/v$v.log"
  [ -s "$L" ] || cap "$v" "$L" "$@"
  # the arm's own unconditional fired count -- whichever sect. printed it
  FIRED=$(grep -oE "(at that slot|bit 6 set|words that invalidated P): [0-9]+" "$L" 2>/dev/null \
          | tail -1 | grep -oE '[0-9]+$')
  # sect. 228 rise census, unit row 07 -- the LFO phase cell's mean step
  LFO=$(grep -A9 '§228 LFO RISE' "$L" 2>/dev/null | grep -E '^\s*\[?:?[a-z0-9]*\]?\s*07:' \
        | grep -oE 'mean [0-9.]+' | head -1 | cut -d' ' -f2)
  # sect. 176 D-RAM census, the per-unit hand-off cell
  HO=$(grep -E '§176 D-RAM CENSUS' -A40 "$L" 2>/dev/null | grep -oE '05:[^ ]*' | head -1)
  printf '%-6s %-12s %-14s %s\n' "$v" "${FIRED:-NONE}" "${LFO:-none}" "${HO:-ABSENT -- destroyed}"
done
printf '\n  logs: %s\n' "$OUTDIR"
printf '  ⚠ read the fired column FIRST: an arm that never reached its word says nothing.\n'
