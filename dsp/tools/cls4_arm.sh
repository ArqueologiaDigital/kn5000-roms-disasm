#!/usr/bin/env bash
# cls4_arm.sh -- does class 4 post-increment the D-RAM operand pointer?  (V7, the last live reading)
#
#   dsp/tools/cls4_arm.sh [TYPEIDX]        # default 12 = EXCITER (analysis/data/typewalk/TYPE_MAP.md)
#
# QUESTION IT ANSWERS
#   N-INPUT-GATE-OPENED sect. 159: **139 pooled words in 9 shapes are undecoded with their ALU half
#   ALREADY ANCHORED** -- the class test is the only thing refusing them -- and **99 of the 139 are
#   ONE shape**, `0124011CE', the C63 table-lookup idiom's third word (class 4).  sect. 112's
#   standard is *"the ADDRESSING is explained AND the ALU half is anchored"*, and mode 4's pointer
#   behaviour is the open half: post-increment-by-one (`closure_pointer.py' variant V7) and no-move
#   are both alive.
#
#   `addr8' CANNOT SETTLE IT.  MEASURED pooled over both products: class 4 carries the SINGLE value
#   0x01 in 99 of 99 words.  Under V7 the field expresses one displacement in eight bits; under
#   no-move it expresses nothing.  Only an EXECUTION difference can separate them.
#
# WHY A NEW ARM, when sect. 100 already built one
#   `UPD6383_CLS46PTR' moves classes 4 AND 6 together = variant V12.  sect. 158 EXCLUDED V8, V10 and
#   V12 on the MEANING of the field: class 6's `addr8' is the table ENTRY COUNT, anchored at 24 by a
#   table independently proven to have 24 entries, and `closure_pointer.py variants' shows V8's
#   residue delta is +56 == 24 + 32, the two class-6 `addr8' values of the image it walks.  So the
#   existing arm can only ever test a reading that is already dead.  `UPD6383_CLS4PTR' is class 4
#   alone -- V7 -- and had never been run before this script.
#
# WHY EXCITER, and why the criterion can FAIL
#   sect. 160, asked with `f31_oracle_pin.py's OWN selection (algorithms carrying an `op0x70' biquad
#   band -- the firmware's own coefficient writer, not a proxy and not a landmark, sect. 138's
#   rule): **11 algorithms carry a band, 8 contain a class-4 word, and 8 of 8 have a band consumed
#   DOWNSTREAM of that word.**  EXCITER is the sharpest -- class-4 at `w14', band at `w18..w22',
#   four words later.  With the arm ON that band must read DIFFERENT D-RAM cells.  If it does not,
#   the arm is not where I think it is.
#   ★ The oracle's float-model caveat does NOT apply: `f31_oracle_pin.py' cannot separate ADD from
#   ADD-with-a-different-shift, which is a PRECISION limit.  V7 vs V0 changes WHICH CELL is read.
#
# ⚠ READ THE FIRED COUNT FIRST (rule 15).  sect. 97 and sect. 100 each spent a run on an arm that
#   never reached its word, and sect. 100 needed THREE.  A zero here means the placement is wrong
#   and nothing else in the output means anything.
# ⚠ RULE 12: notes must be playing.  The frame schedule below is `fx_ab.lua's own.
# ⚠ sect. 193: the loaded program is FINGERPRINTED in the same run, from that run's own capture.
set -u
TI=${1:-12}                     # 12 = EXCITER
HERE=$(cd "$(dirname "$0")" && pwd)
BUILD=${KN7000_BUILD:-$HOME/compartilhado/kn7000_mame_build}
OUT=${OUTDIR:-${CLAUDE_JOB_DIR:-/tmp}/tmp}/cls4_arm
mkdir -p "$OUT"

NOTE=$(python3 -c "print(36.0 + 0.2*$TI)")
FRAME=$(python3 -c "print(int(($NOTE + 1.0) * 44100))")

cap() {   # cap <armvalue|off> <tag>
  local arm=$1 tag=$2
  local -a extra=()
  [ "$arm" != "off" ] && extra=(UPD6383_CLS4PTR=1)
  ( cd "$BUILD" && rm -f error.log kn5000_dsp1_upload.txt && \
    env DISPLAY=${DISPLAY:-:0} DHLE=0 DSPCFG=3 TYPEIDX="$TI" NOTEMODE=0 TGM=0 \
        UPD6383_CENSUS_PERPROG=1 UPD6383_TRACE_FRAME="$FRAME" "${extra[@]}" \
        timeout 300 ./kn7000 kn5000 -rompath ./roms -skip_gameinfo -log -window \
        -autoboot_script "$HERE/fx_ab.lua" > /dev/null 2>&1
    cp error.log "$OUT/$tag.log" 2>/dev/null
    cp kn5000_dsp1_upload.txt "$OUT/$tag.upload.txt" 2>/dev/null )
}

printf '=== cls4_arm -- UPD6383_CLS4PTR (variant V7) at TYPEIDX %s ===\n\n' "$TI"
for arm in off on; do
  L="$OUT/$arm.log"
  [ -s "$L" ] || cap "$arm" "$arm"
  printf -- '--- arm %s ---\n' "$arm"
  # (1) THE FIRED COUNT, unconditional, printed by upd6383.cpp for both arms
  grep -oE '§160 CLS4PTR \([^)]*\): class-4-ONLY pointer advances performed: [0-9]+' "$L" \
      | tail -1 | sed 's/^/    /' || echo "    FIRED LINE ABSENT"
  grep -oE '§100 CLS46PTR \([^)]*\): class-4/6 pointer advances performed: [0-9]+' "$L" \
      | tail -1 | sed 's/^/    /'
  # (2) sect. 193 -- which program actually loaded, from THIS run's capture
  if [ -s "$OUT/$arm.upload.txt" ]; then
    python3 "$HERE/type_fingerprint.py" "$OUT/$arm.upload.txt" 2>/dev/null \
        | grep -iE 'match|prog' | head -2 | sed 's/^/    fingerprint: /'
  else
    echo "    fingerprint: NO CAPTURE -- the run did not upload"
  fi
  # (3) the observable: the per-unit D-RAM census
  grep -E '§176 D-RAM CENSUS' -A24 "$L" 2>/dev/null | head -14 | sed 's/^/    /'
  echo
done

printf '  logs + captures: %s\n' "$OUT"
printf '  ⚠ fired count FIRST.  Zero with the arm ON means the placement is wrong and the\n'
printf '    rest of the output says nothing (sect. 100 needed three runs to learn that).\n'
