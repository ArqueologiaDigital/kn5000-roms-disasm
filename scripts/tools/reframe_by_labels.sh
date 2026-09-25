#!/bin/bash
# Reframe the same routine span in v10, v9 and v7, located by its bounding
# LABELS in each image (so it follows the address deltas between versions),
# with scripts/converters/reframe_region.py.  Dry-run unless APPLY=1.
#   scripts/tools/reframe_by_labels.sh <file relative to maincpu> <StartLabel> <EndLabel> [images]
# Prints each image's range and the tool's verdict; stops at the first failure.
set -e
f=$1; l0=$2; l1=$3; imgs=${4:-"v10 v9 v7"}
NM=~/compartilhado/llvm-project/build/bin/llvm-nm
for v in $imgs; do
  elf=rebuilt_ROMs/kn5000_${v}_program.llvm.elf
  a=$($NM $elf | awk -v L=$l0 '$3==L{print $1}')
  b=$($NM $elf | awk -v L=$l1 '$3==L{print $1}')
  if [ -z "$a" ] || [ -z "$b" ]; then echo "$v: label missing ($l0=$a $l1=$b)"; exit 1; fi
  r=$(printf "0x%X-0x%X" 0x$a 0x$b)
  echo "== $v $r"
  if [ "$APPLY" = 1 ]; then
    python3 scripts/converters/reframe_region.py --image $v --file $f --range $r --apply 2>&1 | tail -1
    make rebuilt_ROMs/kn5000_${v}_program.llvm.rom >/dev/null 2>&1 || { echo "$v BUILD FAILED"; exit 1; }
    cmp -s rebuilt_ROMs/kn5000_${v}_program.llvm.rom original_ROMs/kn5000_${v}_program.rom && echo "$v IDENTICAL" || { echo "$v DIFFERS"; exit 1; }
  else
    python3 scripts/converters/reframe_region.py --image $v --file $f --range $r 2>&1 | head -1
  fi
done
