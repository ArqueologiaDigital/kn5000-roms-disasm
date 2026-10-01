#!/usr/bin/env bash
# run_dsp_arm.sh -- THE §228/§229/§231/§232 VEHICLE, EXACTLY, AS A SCRIPT.
#
# NEC uPD6383GF (Technics SX-KN5000, IC311).  This is the recipe that produced
# dsp/analysis/data/A_232.log.gz and every number §232 quotes.  It existed only
# as prose in the register until 2026-09-04; the prose was missing the one thing
# that now decides whether the run measures anything at all -- the build flag.
#
# ⚠⚠ `KN5000_ENABLE_DSP1' DEFAULTS TO 0 in src/mame/matsushita/kn5000.cpp.  With
# it 0 the uPD6383 device is NOT INSTANTIATED, `grep upd6383 error.log' returns
# NOTHING, and that is indistinguishable from "the instrument was never
# reached".  build.sh does NOT pass the flag; this script does.
#
#   dsp/tools/run_dsp_arm.sh <out.log.gz>
#
# It writes the gzipped MAME log to <out.log.gz>.  Grade it with:
#   python3 dsp/tools/routing_census.py --log <out.log.gz>
set -euo pipefail

OUT="${1:?usage: run_dsp_arm.sh <out.log.gz>}"
OVERLAY="${OVERLAY:-$HOME/compartilhado/kn7000_mame}"
TREE="${TREE:-$HOME/compartilhado/kn7000_mame_build}"
EMU="${EMU:-$HOME/compartilhado/kn7000-emulator}"
RIG="$(mktemp -d)"; trap 'rm -rf -- "${RIG:?}"' EXIT
mkdir -p "$RIG/cfg" "$RIG/nvram"

# The DSP research build.  build.sh assembles the tree and links a binary with
# NO DSP; this re-links the same tree with the device compiled in.
SRC='src/mame/matsushita/kn7000.cpp,src/mame/matsushita/kn_tonegen.cpp'
SRC="$SRC,src/mame/matsushita/kn7000_tonegen.cpp,src/mame/matsushita/kn6000_tonegen.cpp"
SRC="$SRC,src/mame/matsushita/kn_cpanel.cpp,src/mame/matsushita/kn7000_cpanel.cpp"
SRC="$SRC,src/mame/matsushita/kn6000_cpanel.cpp,src/mame/matsushita/kn1500.cpp"
SRC="$SRC,src/mame/matsushita/kn5000.cpp,src/mame/matsushita/kn5000_cpanel.cpp"
SRC="$SRC,src/mame/matsushita/kn5000_tonegen.cpp,src/mame/matsushita/wsa1.cpp"
SRC="$SRC,src/mame/matsushita/wsa1_cpanel.cpp,src/mame/matsushita/acoustic_modeling.cpp"

"$OVERLAY/build.sh"                       # assemble/refresh the tree (DSP OFF)
touch "$OVERLAY/src/mame/matsushita/kn5000.cpp"   # make cannot see a flag change
make -C "$TREE" SUBTARGET=kn7000 SOURCES="$SRC" USE_QTDEBUG=1 \
     QT_HOME="${QT_HOME:-/usr/lib/qt6}" CPPFLAGS=-DKN5000_ENABLE_DSP1=1 \
     -j"$(nproc)" 2>&1 | tee "$RIG/build.log" | tail -3
# build.sh EXITS 0 EVEN ON COMPILE FAILURE, and so does this pipeline.  Check.
! grep -q 'error:' "$RIG/build.log" || { echo "COMPILE ERRORS"; exit 1; }
[ "$(stat -c%s "$TREE/kn7000")" -gt 70000000 ] || { echo "binary too small"; exit 1; }
strings -a "$TREE/kn7000" | grep -q 'Effects DSP IC311' \
    || { echo "NO DSP IN THE BINARY -- the flag did not take"; exit 1; }
cp "$TREE/kn7000" "$EMU/kn7000"

# The DSPCFG port is a runtime CONFIG and defaults to Off; value 3 is
# "On + SPECULATIVE ISA".  An ISOLATED cfg dir (standing rule 20: a private
# -cfg_directory hides the user's bug -- here it is deliberate and declared).
cat > "$RIG/cfg/kn5000.cfg" <<'XML'
<?xml version="1.0"?>
<mameconfig version="10">
    <system name="kn5000">
        <input>
            <port tag=":DSPCFG" type="CONFIG" mask="3" defvalue="0" value="3" />
        </input>
    </system>
</mameconfig>
XML

# coldnotes2.lua: cold boot, no panel navigation, triad C4/E4/G4 at 21.0..27.5 s.
# Rule 12: a DSP test with no notes playing is not a test -- the script PRINTS
# `located=' and both note events, so a silent census is visible as such.
# Visible video, always (never -video none), and always timeout-wrapped.
cd "$EMU"
DISPLAY="${DISPLAY:-:0}" timeout 1800 ./kn7000 kn5000 \
    -rompath ./roms -pluginspath ./plugins -skip_gameinfo \
    -cfg_directory "$RIG/cfg" -nvram_directory "$RIG/nvram" \
    -autoboot_script "$OVERLAY/scratchpad/coldnotes2.lua" \
    -seconds_to_run 30 -window -nomaximize -log 2>&1 | tee "$RIG/stdout.txt"

# ⚠ THE LUA SCRIPT'S OUTPUT DOES NOT GO INTO error.log.  `emu.print_error' writes
# to the process's stderr, so `located=' and the two NOTE events -- the ONLY
# evidence that rule 12 was satisfied, i.e. that notes actually played -- exist
# nowhere in the -log file.  Archiving error.log alone loses them, which is how
# an arm ends up unable to prove its own stimulus.  Both streams are archived.
grep -q 'NOTE ON' "$RIG/stdout.txt" || { echo "⚠⚠ NO NOTE ON -- rule 12: this is NOT a test"; exit 1; }
grep -q 'upd6383:' "$EMU/error.log"  || { echo "NO upd6383 OUTPUT"; exit 1; }
{ echo "==== run_dsp_arm.sh STDOUT (the Lua vehicle's own report -- rule 12) ===="
  cat "$RIG/stdout.txt"
  echo "==== MAME -log (error.log) ===="
  cat "$EMU/error.log"; } | gzip -c > "$OUT"
echo "wrote $OUT"
