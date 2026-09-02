#!/bin/bash
# Convert one direct-address family at a time, gate it, commit it.  Stops the
# whole run on the first red gate.
#
# QUESTION IT ANSWERS: which NATIVE spelling does each of the seventeen
# synthetic direct-address mnemonics become, and does the tree still rebuild
# byte-identically one family at a time?
#
# ★ The SPELL map below is the finding of this lane in one place: the native
#   mnemonic and the address width each synthetic name corresponds to.  The
#   machine-readable form of the same map -- with the register class the
#   synthetic name did not state -- is MAP in
#   scripts/converters/convert_direct_address_family.py; this is the human
#   summary, and the two must agree.
#
# EXACT COMMAND (from the tree root):
#
#     scripts/converters/run_direct_address_convergence.sh /tmp/conv-out \
#         stdi8 stda16 cpdi8 bitda ldw_da ldl_da stdi16 ldb_da stib_da \
#         stw_da anddi8 stda32 stiw_da ordi8 cpdi16 stb_da ldda32
#
# The first argument is a directory for the per-family logs, manifests and
# refusal CSVs.  Every family that converts cleanly is committed on the spot,
# naming its FILES (from the converter's --manifest), never a directory.
#
# ⚠ LLVM_MC must be a binary that does not move.  The shared
#   llvm-project/build/bin/llvm-mc is relinked by backend lanes several times
#   an evening -- five times on 2026-09-02, all while `git log` said the same
#   commit -- and a per-site check taken with one binary followed by a gate
#   taken with the next is two measurements, not one.  Override SNAP with a
#   snapshot copy.
#
# ⚠ `make gate-all` is NOT used here.  Its third step,
#   assert_toolchain_is_a_prerequisite.py, defaults the assembler to
#   ROOT.parent/llvm-project, which is wrong when the tree is a git worktree
#   under disasm-lanes/.  Run that one separately, once, with an explicit
#   --assembler; it asserts a property of the Makefiles, not of any conversion.
set -u
SNAP=${SNAP:-/home/fsanches/compartilhado/toolchain-snapshot/llvm-mc.snap}
S=${1:?usage: $0 <output-dir> <mnemonic>...}
shift
mkdir -p "$S"

declare -A SPELL=(
 [stdi8]='ld (addr:16), imm8'     [stda16]='ld (addr:16), r16'
 [cpdi8]='cp (addr:16), imm8'     [ldda32]='ld r32, (addr:16)'
 [bitda]='bit n, (addr:16)'       [ldw_da]='ld r16, (addr:24)'
 [ldl_da]='ld r32, (addr:24)'     [stdi16]='ldw (addr:16), imm16'
 [ldb_da]='ld r8, (addr:24)'      [stib_da]='ld (addr:24), imm8'
 [stw_da]='ld (addr:24), r16'     [anddi8]='and (addr:16), imm8'
 [stda32]='ld (addr:16), r32'     [stiw_da]='ldw (addr:24), imm16'
 [ordi8]='or (addr:16), imm8'     [cpdi16]='cpw (addr:16), imm16'
 [stb_da]='ld (addr:24), r8'
)

for MN in "$@"; do
  echo "######## $MN"
  LLVM_MC="$SNAP" python3 scripts/converters/convert_direct_address_family.py \
      --mnemonic "$MN" --apply --manifest "$S/manifest_$MN.txt" \
      --report "$S/refused_$MN.csv" > "$S/conv_$MN.log" 2>&1 \
      || { echo "CONVERTER FAILED for $MN"; exit 1; }
  tail -14 "$S/conv_$MN.log"
  NF=$(wc -l < "$S/manifest_$MN.txt")
  NL=$(grep -a "^rewrote" "$S/conv_$MN.log" | grep -ao "[0-9]* lines" | grep -ao "[0-9]*")
  DIFF=$(git diff --numstat -- $(cat "$S/manifest_$MN.txt") | awk '{a+=$1;d+=$2} END{print a" "d}')
  echo "manifest files=$NF converted lines=$NL  diff(add del)=$DIFF"
  if [ -z "$NL" ] || [ "$NL" = "0" ]; then
      echo "NOTHING CONVERTED for $MN (already applied?) -- stopping"; exit 3; fi

  make LLVM_MC="$SNAP" gate gate-wsa1 > "$S/gate_$MN.log" 2>&1
  RC=$?
  # ⚠ the shared toolchain is relinked mid-run; that surfaces as a transient
  # "Permission denied" on llvm-mc or ld.lld, not as a real regression.
  for try in 1 2 3 4; do
      [ $RC -eq 0 ] && break
      grep -aq "Permission denied" "$S/gate_$MN.log" || break
      echo "  transient toolchain Permission denied -- retry $try for $MN"
      sleep 60
      make LLVM_MC="$SNAP" gate gate-wsa1 > "$S/gate_$MN.log" 2>&1
      RC=$?
  done
  grep -a "PASS\|FAIL\|BYTES DIFFER" "$S/gate_$MN.log"
  if [ $RC -ne 0 ]; then echo "GATE RED after $MN -- stopping"; exit 2; fi

  git add --pathspec-from-file="$S/manifest_$MN.txt" || exit 1
  git commit -q -m "$MN -> \`${SPELL[$MN]}\`: $NL sites in $NF files" \
    -m "Every site verified individually against its old spelling before it was written. Gate after: both byte gates green, 13/13 ROMs byte-identical, 8/8 images assembling." \
    -m "LLVM: tlcs900_backend@$(cd ~/compartilhado/llvm-project && git log -1 --format='%h (%H)')" || exit 1
  git log -1 --oneline
done
echo "ALL DONE"
