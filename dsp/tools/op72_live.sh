#!/usr/bin/env bash
# op72_live.sh -- move the COMPRESSOR's parameter and read what the evaluator writes.
#
#   dsp/tools/op72_live.sh [TYPEIDX] [NPARAM] "NVALUE1 NVALUE2 ..."
#   default: 13 (COMPRESSOR)  0  "0 20 40"
#
# QUESTION IT ANSWERS
#   N-INPUT-GATE-OPENED sect. 170: the handover's #1 item -- a bit-exact reference for ONE dynamics
#   program, which sect. 149 says unblocks `f31 = 3' (56 sole-axis words) AND the job sect. 135
#   named for `ACT 0x0B' (191) -- was four fifths done.  sect. 153 read the gain law
#
#       cell = 10 ^ ( -0.0697 x (99 - user) ) x 0.9999
#
#   out of the evaluator at 0x039ABD, and sect. 170 then found it CANNOT BE CHECKED AGAINST THE ROM:
#   all four `op 0x72' cells (algo 36 0x04/0x0D, algo 75 0x0A/0x19) hold `0x600000' -- exactly 0.75 --
#   which the law produces at NO integer knob position at any of sect. 154's three scales.  Scoped
#   with a null: `op 0x72' is 8 of 8 "low 16 bits zero" against a 35 % corpus base rate (p ~ 2e-4),
#   so those cells carry a HARD-CODED DEFAULT while parameter cells generally store evaluator output.
#
#   ⇒ the law has no stored output to validate against, and the only remaining route is to MOVE THE
#   PARAMETER and capture what the evaluator actually writes.  That is this script.
#
# HOW IT WORKS
#   `peq_gain.lua' already navigates the DSP EFFECT editor and steps PARAMETER / VALUE -- it is
#   parameterised by TYPEIDX / NPARAM / NVALUE and was written for the EQ's gain.  Nothing about it
#   is EQ-specific: point it at TYPEIDX 13 (prog36_compressor per the authoritative TYPE map) and
#   sweep NVALUE.  Each run's `kn5000_dsp1_upload.txt' is the uC-IF capture; the KN5000 serialises
#   coefficient loads as the same 5-byte groups the WSA1R does (`dsp_disasm.host_packet', and
#   `upd6383.cpp' host_w's poke path is cross-corroborated between the two products), so the C-RAM
#   map is recoverable from it directly.
#
# WHAT TO LOOK FOR
#   (1) Does ANY C-RAM cell move between NVALUE settings?  If none does, the navigation did not
#       reach an editable parameter and nothing else in the output means anything -- the same
#       lesson sect. 97 and sect. 100 each paid a run for.
#   (2) Does cell 0x04 (and 0x0D) move?  Those are the `op 0x72' operands.
#   (3) If they move, each (user, cell) pair is a point ON the law.  Two points determine whether
#       `10^(-0.0697 x (99-u)) x 0.9999' is right, at which scale, and with what clamp -- and that
#       completes the gain computer WITHOUT proving the eight floating-point helpers, which sect. 170
#       showed would have validated an implementation against nothing.
#
# ⚠ RULE 12: notes play (peq_gain.lua drives C4/E4/G4).  ⚠ sect. 193: fingerprint the loaded program
#   from the run's OWN capture -- done below, because a TYPE-selected run that loaded the wrong
#   program has been the cause of more than one wasted campaign.
set -u
TI=${1:-13}
NP=${2:-0}
VALS=${3:-"0 20 40"}
HERE=$(cd "$(dirname "$0")" && pwd)
BUILD=${KN7000_BUILD:-$HOME/compartilhado/kn7000_mame_build}
OUT=${OUTDIR:-${CLAUDE_JOB_DIR:-/tmp}/tmp}/op72_live
mkdir -p "$OUT"

for v in $VALS; do
  L="$OUT/v$v.log"
  if [ ! -s "$L" ]; then
    ( cd "$BUILD" && rm -f error.log kn5000_dsp1_upload.txt && \
      env DISPLAY=${DISPLAY:-:0} TYPEIDX="$TI" NPARAM="$NP" NVALUE="$v" \
          timeout 300 ./kn7000 kn5000 -rompath ./roms -skip_gameinfo -log -window \
          -autoboot_script "$HERE/peq_gain.lua" > /dev/null 2>&1
      cp error.log "$L" 2>/dev/null
      cp kn5000_dsp1_upload.txt "$OUT/v$v.upload.txt" 2>/dev/null )
  fi
done

python3 "$HERE/op72_live.py" "$OUT" $VALS
