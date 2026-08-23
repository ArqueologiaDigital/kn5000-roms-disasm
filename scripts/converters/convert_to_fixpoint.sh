#!/bin/bash
# Run the v7 .byte -> instruction conversion until it stops finding work.
#
# Each round does three things:
#   1. regenerate the reachable call targets from the CURRENT territory map,
#      which now includes whatever the previous round converted;
#   2. convert every range those targets reach;
#   3. rebuild all nine ROM targets and require 9/9 at 100.00%.
#
# Step 1 is the point. Converted code contains calls of its own, so each round
# can expose entry points that did not exist as instructions before. Targets
# already converted stop being candidates, so the total falls while the newly
# discovered set grows -- 808 -> 690 with 34 new, in the first closure round.
#
# ⚠ THE GATE USED TO BE READ WRONG, AND THAT IS WORTH KNOWING. This line was
#     [ "$(make all | grep -c 'Similarity: 100.00%')" != "9" ]
# and `Similarity: 100.00%` is a PREFIX of `Similarity: 100.00%  (22 incorrect
# bytes)`. The percentage is rounded to two decimals -- up to 104 bytes in a
# 2 MB ROM -- so the closure driver would have accepted a round that corrupted
# the tree. It now calls assert_byte_identical.py, which compares bytes and
# exits non-zero. See docs/DISASSEMBLY-COMPLETENESS-SPEC.md anti-pattern 15.
#
# ⚠ THE GATE IS NOT OPTIONAL AND IS NOT SUFFICIENT. It catches duplicate
# labels, undefined symbols and length shifts. It CANNOT catch a range decoded
# from the wrong offset, because the assembler faithfully reproduces whatever
# bytes it is handed -- that is why alignment comes from being a call target
# rather than from a label. Read a diff before trusting a round.
#
# Run:  bash scripts/converters/convert_to_fixpoint.sh [max_rounds]
set -u
cd "$(dirname "$0")/../.."
MAX=${1:-5}
T=analysis/v7-reachability/v7_call_targets.json

code_bytes() {
    python3 scripts/analysis/l1_territory_map.py v7 2>/dev/null \
        | awk '/CODE/{gsub(",","",$2); print $2}'
}

before_all=$(code_bytes)
for round in $(seq 1 "$MAX"); do
    echo "=== round $round"
    prev=$(python3 -c "import json;print(len(json.load(open('$T'))['targets']))" 2>/dev/null || echo 0)
    python3 scripts/analysis/v7_reachable_from_code.py --dump "$T" >/dev/null || exit 1
    now=$(python3 -c "import json;print(len(json.load(open('$T'))['targets']))")
    echo "    targets: $prev -> $now"

    before=$(code_bytes)
    python3 scripts/converters/convert_reachable_ranges.py --apply \
        | grep -E "ranges decode|rewrote|refused|lost to truncation" | sed 's/^/    /'

    if ! make clean-all >/dev/null 2>&1 || \
       ! make all >/dev/null 2>&1 || \
       ! python3 scripts/analysis/assert_byte_identical.py >/dev/null 2>&1; then
        echo "    GATE FAILED -- reverting this round"
        git checkout v7/
        exit 1
    fi
    after=$(code_bytes)
    echo "    CODE $before -> $after  (gate 9/9)"
    if [ "$before" = "$after" ]; then
        # NOT necessarily "no work left". The converter can find ranges and
        # still write nothing, because the rewrite stage refuses them -- which
        # is exactly what happens now: 52 ranges start mid-block and the lead
        # path is disabled. Print the refusals so a stall is never mistaken for
        # completion.
        echo "    no bytes gained -- refusals above say why, and they are"
        echo "    not the same thing as having nothing left to convert"
        break
    fi
done
echo "total CODE $before_all -> $(code_bytes)"
