#!/bin/bash
# Lane uiproc driver: audit -> re-frame -> re-audit, until a file has no
# misframe / byte-code windows left, then symbolise its numeric branches.
#
# QUESTION / JOB: bring one source file of one image to "unidasm agrees with
# every instruction boundary" using the two committed tools
# (scripts/analysis/lane_uiproc_framing_audit.py and
#  scripts/converters/lane_uiproc_reframe.py), then run
# scripts/converters/symbolize_numeric_branches.py on it.
#
# Windows that hold data directives (.long/.ascii/...) are printed with their
# data lines so a human can confirm they are code misframes (a stray 4-byte
# `.long Label` in the middle of instructions), not real tables; the re-framer
# refuses any window whose decode contains an absurd instruction.
#
# RUN   scripts/converters/lane_uiproc_reframe_loop.sh v10 ui/ui_mode_handlers.s [scratchdir]
set -e
IMG=$1; F=$2; S=${3:-/tmp/claude-1000/lane-uiproc}
B=$(basename "$F" .s)
cd "$(dirname "$0")/../.."
for pass in 1 2 3 4; do
  python3 scripts/analysis/lane_uiproc_framing_audit.py --image "$IMG" --file "$F" \
      --windows-out "$S/loop_${IMG}_$B.json" | tee "$S/loop_${IMG}_$B.audit$pass.txt" \
      | command grep -v "BYTE-CODE\|  MISFRAME lines" || true
  python3 - "$S/loop_${IMG}_$B.json" <<'EOF'
import json, sys
p = sys.argv[1]
w = json.load(open(p)) + json.load(open(p + ".data-review"))
m = []
for x in sorted(w):
    if m and x[0] <= m[-1][1]:
        m[-1][1] = max(m[-1][1], x[1])
    else:
        m.append(list(x))
json.dump(m, open(p + ".all", "w"))
print("windows:", len(m))
open(p + ".n", "w").write(str(len(m)))
EOF
  N=$(cat "$S/loop_${IMG}_$B.json.n")
  # a window whose only content is a .byte the backend cannot spell stays
  # as it is: stop when the count stops falling
  if [ "$N" = "0" ] || [ "$N" = "${PREV:-x}" ]; then break; fi
  PREV=$N
  python3 scripts/converters/lane_uiproc_reframe.py --image "$IMG" --file "$F" \
      --windows "$S/loop_${IMG}_$B.json.all" --quiet --skip-refused --apply 2>&1 | tail -4
done
python3 scripts/converters/symbolize_numeric_branches.py --image "$IMG" --only "$F" --apply --verify 2>&1 | tail -3
