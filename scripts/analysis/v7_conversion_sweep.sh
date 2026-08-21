#!/bin/bash
# How many v7 .byte blocks can be converted to instructions, tree-wide?
#
# ANSWER (2026-08-22): almost none, under ANY criterion tried.
#   v9-content corroboration ... 536 bytes, applied and gated
#   reachability (call targets)  93 bytes in 33 blocks -- and most of those are
#                                1-2 byte fragments, so not worth applying
#
# The reason is structural: the .byte blocks in these sources are delimited by
# LABELS, and labels do not coincide with function entries. In
# midi_dispatch_handlers.s, 615 of 616 block starts are not call targets. A
# block-level converter is simply the wrong shape for this job; the work needs
# one that operates on ADDRESS RANGES -- decode from a reachable entry, follow to
# the function end, rewrite whatever source lines cover that range.
#
# ⚠ THIS SCRIPT PRINTS ERRORS ON PURPOSE. An earlier version of this sweep ran
# the converter with 2>/dev/null, and the converter was crashing on `.byte` lines
# with trailing comments (`0xff\t; call Malloc (v7 addr)`). Every crashed file
# was counted as "nothing to convert", so the sweep reported a clean zero for
# files it had never successfully read. A suppressed error channel makes failure
# indistinguishable from success.
#
# Run:  bash scripts/analysis/v7_conversion_sweep.sh [--reachable]
set -u
cd "$(dirname "$0")/../.."
T=analysis/v7-reachability/v7_call_targets.json
MODE=""
[ "${1:-}" = "--reachable" ] && MODE="--reachable $T"
errors=0
for f in $(ls v7/maincpu/*/*.s v7/maincpu/*.s 2>/dev/null); do
    out=$(timeout 300 python3 scripts/converters/convert_corroborated_blocks.py \
              --file "$f" $MODE 2>&1)
    if echo "$out" | grep -q "Traceback"; then
        echo "ERROR   $f"
        errors=$((errors + 1))
        continue
    fi
    line=$(echo "$out" | grep "CONVERTIBLE")
    n=$(echo "$line" | sed -n 's/.*CONVERTIBLE *\.* *\([0-9]*\) .*/\1/p')
    [ -n "$n" ] && [ "$n" != "0" ] && echo "$n blocks  $(echo "$line" | grep -oP '\(\K[^)]+')  $f"
done
echo "files that failed to parse: $errors"
