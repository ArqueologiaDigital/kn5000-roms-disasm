#!/usr/bin/env bash
# pair_gate.sh -- THE TWO-SIDED GATE for any uPD6383 product-register / pipeline arm.
#
#   dsp/tools/pair_gate.sh <TAG> [ENV=VAL ...]
#
# QUESTION IT ANSWERS
#   N-INPUT-GATE-OPENED §19 proposed a configuration on the evidence of ONE program (the chorus)
#   and §20 MEASURED that it starves another (the parametric EQ).  A reading of the product
#   register is only admissible if it passes BOTH criteria AT THE SAME SETTING:
#
#     (A) CHORUS, TYPEIDX 0 -- BOTH halves.  The LFO phase cell's increment must be 114 at rest
#         AND the chorus body must be LIVE across a frame pair.  ⚠ The phase alone is NOT a test:
#         §22/§9 measured four structurally unrelated interventions that all report 114, one of
#         which leaves the EQ bit-identical.  114 is as much the starvation signature as the
#         right answer.
#     (B) PARAMETRIC EQ, TYPEIDX 15 -- the body must stay LIVE: cells moving and rows differing
#         between two consecutive frames (frame_pair_diff.py, non-zero exit on a static body).
#         Reference, this binary + baseline arms: NO-FLUSH gives 39 of 44 cells / 105 of 105 rows.
#         CALLFLUSH gives 2 cells / 9 rows; PCLR and the cursor-seed clear give 0 and 0.
#
#     (C) PARAMETRIC EQ, the HLE's own criterion -- the pickup cell must hold exactly ONE copy of
#         the input (pickup_copies.py).  ★★★ This is the only criterion that separates RIGHT from
#         merely ALIVE, and it REVERSED §20: liveness rewards contamination, and the one
#         configuration liveness marked worst (CALLFLUSH) is the one delivering a clean input.
#
#   An arm must pass (A) BOTH HALVES, (B) and (C).  Nothing has yet -- but as of §29 CALLFLUSH
#   passes (A) and (C), and what fails under it is downstream: nothing writes the band's input
#   cell 0x50 (§30).
#
# Example (the §20 baseline that fails B, and the §21 candidate):
#   dsp/tools/pair_gate.sh callflush UPD6383_LO12CAP=1 UPD6383_CALLFLUSH=1 \
#                          UPD6383_SPEC=B9108446A39B440F
#   dsp/tools/pair_gate.sh pclr      UPD6383_LO12CAP=1 UPD6383_PCLR=1 \
#                          UPD6383_SPEC=B9108446A39B440F
#
# Frame schedule is fx_ab.lua's own: NOTE ON at 36.0 s + 0.2 s x TYPEIDX, trace armed 1.0 s later
# (RULE 12 -- a DSP test with no notes playing is not a test).  Visible window, timeout-wrapped.
#
# ⚠⚠ THE BASELINE ARMS ARE NOT OPTIONAL, and leaving them out cost a whole gate run.
#   UPD6383_PSHIFT=2   -- §227's total-23 multiply scale.  At the shipped total-22 the EQ's
#                         pickup arrives PINNED at full scale and every band rails.
#   UPD6383_C8SHIFT=1  -- §2 of the handover banner: `acc >>= 1' on the class-8 post-sum word is
#                         the unique small integer that un-rails the EQ (0 leaves 33 rows at full
#                         scale; 1 propagates all five bands).
# Without them criterion (B) reports the EQ body STATIC no matter what the product register does,
# which reads as "this arm starves the EQ" when the real cause is the scale.  MEASURED: the first
# run of this script omitted both and returned 0 cells / 0 rows for the NO-FLUSH configuration,
# the one already known to give 42 of 52 cells.  Override by passing your own value for either.
set -u
TAG=${1:?TAG}; shift
BASE=(UPD6383_PSHIFT=2 UPD6383_C8SHIFT=1)
EXTRA=()
for a in "${BASE[@]}"; do
  n=${a%%=*}
  for u in "$@"; do [ "${u%%=*}" = "$n" ] && { n=""; break; }; done
  [ -n "$n" ] && EXTRA+=("$a")
done
EXTRA+=("$@")
HERE=$(cd "$(dirname "$0")" && pwd)
BUILD=${KN7000_BUILD:-$HOME/compartilhado/kn7000_mame_build}
OUTDIR=${OUTDIR:-${CLAUDE_JOB_DIR:-/tmp}/tmp}
mkdir -p "$OUTDIR"

cap() {   # cap <TYPEIDX> <FRAME_OFFSET_FRAMES> <OUT.log>
  local ti=$1 off=$2 out=$3
  local note frame
  note=$(python3 -c "print(36.0 + 0.2*$ti)")
  frame=$(python3 -c "print(int(($note + 1.0) * 44100) + $off)")
  ( cd "$BUILD" && rm -f error.log && \
    env DISPLAY=${DISPLAY:-:0} DHLE=0 DSPCFG=3 TYPEIDX="$ti" NOTEMODE=0 TGM=0 \
        UPD6383_TRACE_FRAME="$frame" "${EXTRA[@]}" \
        timeout 180 ./kn7000 kn5000 -rompath ./roms -skip_gameinfo -log -window \
        -autoboot_script "$HERE/fx_ab.lua" > /dev/null 2>&1
    cp error.log "$out" )
}

echo "=== pair_gate [$TAG] : ${EXTRA[*]:-(no arms)} ==="

echo "--- (A) CHORUS phase + liveness, TYPEIDX 0 ---"
# The phase landmark is the delta between the phase-accumulate word (hi12 092.A) and the wrap word
# (094.A) INSIDE one frame, i.e. the increment the LFO actually applied.
# ⚠⚠ THE PHASE ALONE IS VACUOUS.  MEASURED over four structurally unrelated interventions
# (CALLFLUSH, PCLR, the cursor-seed clear, and the starved baseline): EVERY configuration that
# empties the product register at the LFO entry word reports 114, including ones that leave the
# EQ bit-identical across a frame pair.  "114" is the STARVATION signature as much as the correct
# answer, so the chorus needs its OWN liveness half -- hence the second capture.
cap 0 0 "$OUTDIR/pg_${TAG}_cho.log"
cap 0 1 "$OUTDIR/pg_${TAG}_cho_F1.log"
python3 "$HERE/dlyseed_confront.py" "$OUTDIR/pg_${TAG}_cho.log" --lo 84 --hi 188 2>/dev/null \
  | grep -E "delta across the pair" \
  || echo "  !! no LFO landmark line -- the chorus trace is missing or the body never ran"
python3 "$HERE/frame_pair_diff.py" "$OUTDIR/pg_${TAG}_cho.log" "$OUTDIR/pg_${TAG}_cho_F1.log" \
    --lo 84 --hi 188 | grep -E "cells seen|tuples differing|VERDICT"
echo "(A) liveness exit status: ${PIPESTATUS[0]}   [0 = live, non-zero = STATIC]"

echo "--- (B) PARAMETRIC EQ liveness, TYPEIDX 15 ---"
cap 15 0 "$OUTDIR/pg_${TAG}_eq.log"
cap 15 1 "$OUTDIR/pg_${TAG}_eq_F1.log"
python3 "$HERE/frame_pair_diff.py" "$OUTDIR/pg_${TAG}_eq.log" "$OUTDIR/pg_${TAG}_eq_F1.log" \
    --lo 84 --hi 188
echo "(B) exit status: $?   [0 = live, non-zero = STATIC]"

# ★★★ (C) THE ONLY CRITERION THAT DISTINGUISHES RIGHT FROM MERELY ALIVE, and the one that
# reversed §20.  Liveness rewards CONTAMINATION: the baseline moves 39 of 44 cells because the
# body is filtering the kernel's leftover product, and a configuration that counts the input
# three times moves even more.  The HLE says what the number should be -- the EQ's input is ONE
# copy of the pickup -- so measure that.  §29: of seven configurations only UPD6383_CALLFLUSH=1
# passes it (0.999), the baseline gives 1.589 and §138 rails at 0x7FFFFF.
echo "--- (C) ONE COPY of the input at the EQ's pickup cell (the HLE's criterion) ---"
python3 "$HERE/pickup_copies.py" "$OUTDIR/pg_${TAG}_eq.log"
echo "(C) exit status: $?   [0 = one clean copy, non-zero = wrong quantity]"
