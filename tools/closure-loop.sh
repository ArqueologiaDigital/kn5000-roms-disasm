#!/bin/bash
# Iterate: reseed call targets from the (now larger) CODE territory, close over
# branch destinations, convert, gate. Each converted range enlarges CODE, which
# exposes more call sites AND more branch destinations -- a nested fixpoint that
# a single pass of either scan cannot reach.
#
# Stops when a round converts 0 bytes. Aborts immediately if the byte gate fails.
# Usage: tools/closure-loop.sh [max_rounds]
set -u
cd "$(dirname "$0")/.."
MAX=${1:-8}
for i in $(seq 1 "$MAX"); do
  echo "=== round $i ==="
  # ⚠ --dump takes a PATH argument (sys.argv[index+1]). An earlier version of
  # this loop wrote `--dump` with no path and redirected stderr to /dev/null, so
  # the reseed raised IndexError EVERY round and the loop happily continued
  # without it -- a failure that did not propagate. Errors are visible now and
  # a failed reseed stops the loop.
  if ! python3 scripts/analysis/v7_reachable_from_code.py --dump \
       analysis/v7-reachability/v7_call_targets.json >/dev/null; then
    echo "reseed FAILED in round $i -- stopping"; exit 1
  fi
  python3 scripts/analysis/v7_branch_closure.py --dump 2>&1 | tail -3
  OUT=$(python3 scripts/converters/convert_reachable_ranges.py --apply 2>&1)
  echo "$OUT" | grep -E "^converted" || echo "converted 0"
  if ! python3 scripts/analysis/assert_byte_identical.py >/dev/null 2>&1; then
    echo "BYTE GATE FAILED in round $i -- stopping, tree left for inspection"; exit 1
  fi
  echo "$OUT" | grep -qE "^converted 0 range" && { echo "converged"; break; }
done
python3 -c "
import importlib.util,collections
s=importlib.util.spec_from_file_location('spans','scripts/analysis/v7_undisassembled_spans.py')
m=importlib.util.module_from_spec(s); s.loader.exec_module(m)
t=m.territory(m.runs('v7/maincpu/kn5000_v7_program.s','v7/maincpu'))
h=collections.Counter(t); print(f'CODE {h[1]:,} {100*h[1]/len(t):.2f}%')"
