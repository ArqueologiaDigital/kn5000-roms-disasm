#!/bin/bash
# enc.sh 'asm line' ... : show llvm-mc encoding for each line
MC=/home/fsanches/compartilhado/llvm-project/build/bin/llvm-mc
for l in "$@"; do
  printf '%-40s => ' "$l"
  echo "$l" | $MC -triple=tlcs900 -show-encoding 2>&1 | command grep -E "encoding|error|warning" | sed 's/^[ \t]*//' | tr '\n' ' '
  echo
done
