#!/usr/bin/env bash
# regen_words_unchanged.sh -- after regenerating a disassembly tree, prove ONLY the rendering moved.
#
#   dsp/tools/regen_words_unchanged.sh [GIT_REF]        (default: HEAD)
#
# QUESTION IT ANSWERS
#   `gen_dsp_disasm.py' and `gen_wsa1_dsp_disasm.py' rewrite every listing from the ROM whenever the
#   shared instruction-set model changes.  sect. 123 regenerated 63 WSA1R files at once and sect. 124
#   another 53, which is exactly the situation where a generator bug would rewrite a WORD and nobody
#   would notice inside four thousand changed lines.
#
#   The KN5000 has `dsp/verify.py' (BYTE-MATCH against the ROM) and the WSA1R does not.  This is the
#   cheap invariant that covers BOTH trees: the `wNNN  HHHHHHHHHH' column is the ROM, so it must be
#   BIT-IDENTICAL across a rendering change.  Anything else is a generator defect, not a decode.
#
#   MEASURED 2026-09-14 over sect. 122 + sect. 124: 8003 of 8003 word columns identical across both
#   trees while 116 files and ~4300 lines changed.
#
# ⚠ THIS IS NOT A BYTE-MATCH.  It proves the regeneration did not move a word RELATIVE TO THE REF,
#   not that the ref was right.  `dsp/verify.py' is what proves the KN5000 listings reproduce the ROM;
#   run it too, and treat this as the WSA1R tree's stand-in until it has its own.
set -u
REF=${1:-HEAD}
cd "$(dirname "$0")/../.." || exit 1
OUT=${OUTDIR:-${CLAUDE_JOB_DIR:-/tmp}/tmp}/regenchk
mkdir -p "$OUT"
: > "$OUT/old.txt"; : > "$OUT/new.txt"
for f in wsa1/dsp/disasm/*.dsm dsp/disasm/*.dsm; do
  git show "$REF:$f" 2>/dev/null | grep -oE '^[[:space:]]*w[0-9]+[[:space:]]+[0-9A-F]{10}' | tr -s ' ' >> "$OUT/old.txt"
  grep -oE '^[[:space:]]*w[0-9]+[[:space:]]+[0-9A-F]{10}' "$f" | tr -s ' ' >> "$OUT/new.txt"
done
N=$(wc -l < "$OUT/new.txt")
if diff -q "$OUT/old.txt" "$OUT/new.txt" >/dev/null; then
  echo "★ WORD COLUMNS IDENTICAL vs $REF -- $N of $N words; the regeneration changed only rendering"
  exit 0
fi
echo "⛔ WORDS CHANGED vs $REF -- this is a GENERATOR DEFECT, not a decode.  First differences:"
diff "$OUT/old.txt" "$OUT/new.txt" | head -20
exit 1
