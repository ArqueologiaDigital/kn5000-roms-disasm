#!/bin/bash
# V1c probe: does the tree AT a given disasm commit rebuild byte-identically with
# a given llvm-mc binary?  Answers check (3): is each commit's `LLVM:` trailer the
# binary its tree was (or could have been) gated with?
#
# Usage: per_commit_gate.sh <slotdir> <commit> <llvm-mc binary> [label]
#   - extracts `git archive <commit>` into <slotdir>/tree (fresh), read-only on the repo
#   - runs `make LLVM_MC=<bin> gate-all` there (clang/lld/objcopy = build/bin, the pin)
#   - writes <slotdir>/../results/<commit>_<label>.log ; last lines carry the verdict
# Signal: "PASS: every rebuilt ROM is byte-identical." twice (KN5000 + wsa1) and EXIT=0.
set -u
SLOT=$1; C=$2; MC=$3; LABEL=${4:-$(sha256sum "$MC" | cut -c1-8)}
REPO=$(cd "$(dirname "$0")/../../.." && pwd)
RES=$(dirname "$SLOT")/results
mkdir -p "$RES" "$SLOT"
export TMPDIR=${TMPDIR:-$HOME/compartilhado/tmp}
LOG=$RES/${C}_${LABEL}.log
rm -rf "$SLOT/tree"; mkdir -p "$SLOT/tree"
( cd "$REPO" && git archive "$C" ) | tar -x -C "$SLOT/tree"
{
  echo "# commit $C  llvm-mc $(sha256sum "$MC")  $(date -Iseconds)"
  cd "$SLOT/tree" && LLVM_MC="$MC" make LLVM_MC="$MC" gate-all
  echo "EXIT=$?"
  date -Iseconds
} > "$LOG" 2>&1
echo "$C $LABEL: $(command grep -c 'IDENTICAL$' "$LOG") IDENTICAL, $(command grep -cE '^\s+ok\s+wsa1' "$LOG") wsa1 ok, $(tail -2 "$LOG" | head -1)"
