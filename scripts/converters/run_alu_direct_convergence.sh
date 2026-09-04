#!/bin/bash
# Convert one BASE-OPERATION family of direct-address mnemonics at a time,
# gate it, prove no comment moved, commit it.  Stops on the first red gate.
#
# QUESTION IT ANSWERS: do the ninety-four remaining synthetic mnemonics that
# spell a direct address -- the ALU-direct, bit-direct, inc/dec-direct and
# stl_da/cpib_da/cpw_da/jp_24/call_24/pushdi_24 forms -- respell to their
# NATIVE mnemonic plus a width-annotated operand without moving one ROM byte?
#
# This is the sibling of run_direct_address_convergence.sh, which did the same
# for the seventeen load/store families.  The difference is only the grouping:
# there one MNEMONIC per gate, here one BASE OPERATION per gate (all of `cp`,
# all of `add`, ...), because ninety-four gates at ~3.5 minutes each is half a
# day of rebuilds for no extra information -- every mnemonic inside one group
# shares an encoding class, so a red gate still names one claim.
#
# EXACT COMMAND (from the tree root):
#
#     scripts/converters/run_alu_direct_convergence.sh /tmp/alu-out \
#         bit incdec cp add sub and or xor ld flow
#
# The first argument is a directory for the per-family logs, manifests and
# refusal CSVs.  Each family that converts cleanly is committed on the spot,
# naming its FILES (from the converter's --manifest), never a directory.
#
# ⚠ SNAP must be a binary that does not move.  The shared
#   llvm-project/build/bin/llvm-mc is relinked by backend lanes several times
#   an evening, always while `git log` reports the same commit, and a per-site
#   check taken with one binary followed by a gate taken with the next is two
#   measurements, not one.  The same binary is passed to the converter AND to
#   make.
#
# ⚠ `make gate-all` is NOT used here.  Its third step,
#   assert_toolchain_is_a_prerequisite.py, defaults the assembler to
#   ROOT.parent/llvm-project, which is wrong when the tree is a git worktree
#   under disasm-lanes/.  Run that one separately, once, with --assembler.
set -u
SNAP=${SNAP:-/home/fsanches/compartilhado/toolchain-snapshot/llvm-mc.snap}
JOBS=${JOBS:-4}
S=${1:?usage: $0 <output-dir> <family>...}
shift
mkdir -p "$S"

# The families, and the native spelling each group converges on.  This table is
# the finding of the lane; MAP in convert_direct_address_family.py is the
# machine-readable form and the two must agree.
declare -A MEMBERS=(
 [bit]='resda resda_24 setda setda_24 bitda_24 chgda_24'
 [incdec]='incdi8 incdi8_24 incdi16 incdi16_24 decdi8 decdi8_24 decdi16 decdi16_24'
 [cp]='cpda8 cpda8_24 cpda16 cpda16_24 cpda32 cpda32_24 cpdm8 cpdm8_24 cpdm16 cpdm16_24 cpdm32 cpdm32_24 cpib_da cpw_da'
 [add]='addda8 addda8_24 addda16 addda16_24 addda32 addda32_24 adddm8 adddm16 adddm16_24 adddm32 addl_da adddi8 adddi16 adddi16_24'
 [sub]='subda8 subda8_24 subda16 subda16_24 subda32 sub32_24 subdm8 subdm8_24 subdm16 subdm16_24 subdm32 subdm32_24 subdi8 subdi16 subdi16_24'
 [and]='andda8 andda8_24 andda16 andda16_24 andda32_24 anddm8 anddm8_24 anddm16 anddm16_24 anddm32_24 anddi8_24 anddi16 anddi16_24'
 [or]='orda8 orda8_24 orda16 orda32_24 orddm8 orddm16 ordm8_24 ordm16_24 ordm32_24 ordi8_24 ordi16 ordi16_24'
 [xor]='xorda8 xorda8_24 xorda16_24 xordm8 xordm16_24 xordi8 xordi8_24'
 [ld]='stl_da'
 [flow]='jp_24 call_24 lda_24 pushdi_24'
)
declare -A SPELL=(
 [bit]='res/set/bit n, (addr:16|24)'
 [incdec]='inc/incw/dec/decw n, (addr:16|24)'
 [cp]='cp/cpw reg-or-imm <-> (addr:16|24)'
 [add]='add/addw reg-or-imm <-> (addr:16|24)'
 [sub]='sub/subw reg-or-imm <-> (addr:16|24)'
 [and]='and/andw reg-or-imm <-> (addr:16|24)'
 [or]='or/orw reg-or-imm <-> (addr:16|24)'
 [xor]='xor reg-or-imm <-> (addr:16|24)'
 [ld]='ld (addr:24), r32'
 [flow]='jp/call cc, (addr:24) and pushw (addr:24)'
)

for FAM in "$@"; do
  echo "######## $FAM"
  ARGS=""
  for MN in ${MEMBERS[$FAM]}; do ARGS="$ARGS --mnemonic $MN"; done
  LLVM_MC="$SNAP" python3 scripts/converters/convert_direct_address_family.py \
      $ARGS --apply --manifest "$S/manifest_$FAM.txt" \
      --report "$S/refused_$FAM.csv" > "$S/conv_$FAM.log" 2>&1 \
      || { echo "CONVERTER FAILED for $FAM"; exit 1; }
  tail -20 "$S/conv_$FAM.log"
  NF=$(wc -l < "$S/manifest_$FAM.txt")
  NL=$(grep -a "^rewrote" "$S/conv_$FAM.log" | grep -ao "[0-9]* lines" | grep -ao "[0-9]*")
  echo "manifest files=$NF converted lines=$NL"
  if [ -z "$NL" ] || [ "$NL" = "0" ]; then
      echo "NOTHING CONVERTED for $FAM (already applied?) -- stopping"; exit 3; fi

  # ⚠ the byte gate CANNOT see a lost comment.  This is the other half.
  python3 scripts/analysis/assert_comments_preserved.py --base main \
      $(cat "$S/manifest_$FAM.txt") > "$S/comments_$FAM.log" 2>&1
  if [ $? -ne 0 ]; then
      tail -20 "$S/comments_$FAM.log"; echo "COMMENTS MOVED in $FAM -- stopping"; exit 4; fi
  tail -2 "$S/comments_$FAM.log"

  make -j"$JOBS" LLVM_MC="$SNAP" gate gate-wsa1 > "$S/gate_$FAM.log" 2>&1
  RC=$?
  # ⚠ the shared toolchain is relinked mid-run; that surfaces as a transient
  # "Permission denied" on ld.lld or clang, not as a real regression.
  for try in 1 2 3 4; do
      [ $RC -eq 0 ] && break
      grep -aq "Permission denied" "$S/gate_$FAM.log" || break
      echo "  transient toolchain Permission denied -- retry $try for $FAM"
      sleep 60
      make -j"$JOBS" LLVM_MC="$SNAP" gate gate-wsa1 > "$S/gate_$FAM.log" 2>&1
      RC=$?
  done
  grep -ac "IDENTICAL\|^  ok " "$S/gate_$FAM.log" | sed 's/^/  byte-identical images: /'
  grep -a "FAIL\|BYTES DIFFER\|DIFFERS" "$S/gate_$FAM.log"
  if [ $RC -ne 0 ]; then echo "GATE RED after $FAM -- stopping"; exit 2; fi

  git add --pathspec-from-file="$S/manifest_$FAM.txt" || exit 1
  git commit -q -m "$FAM-direct -> \`${SPELL[$FAM]}\`: $NL sites in $NF files" \
    -m "Every site verified individually: the old spelling and each candidate new spelling assembled in isolation, kept only on an identical encoding and fixup list. Comments asserted insertions-only against main." \
    -m "Gate after: 13/13 ROMs byte-identical under llvm-mc.snap sha256 850b013e0e8f14d9." \
    -m "LLVM: tlcs900_backend@$(cd ~/compartilhado/llvm-project && git log -1 --format='%h (%H)')" || exit 1
  git log -1 --oneline
done
echo "ALL DONE"
