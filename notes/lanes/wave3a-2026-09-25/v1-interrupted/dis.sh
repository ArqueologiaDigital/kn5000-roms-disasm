#!/bin/bash
# dis.sh "hex bytes" ... : llvm-mc disassembly vs unidasm for each byte string
MC=/home/fsanches/compartilhado/llvm-project/build/bin/llvm-mc
UD=$HOME/compartilhado/tools/unidasm
D=/home/fsanches/compartilhado/disasm-lanes/wave3a-scratch/verify-T1
for h in "$@"; do
  hx=$(echo $h | sed 's/0x//g')
  llvm=$(echo "$hx" | sed 's/\([0-9a-fA-F][0-9a-fA-F]\)/0x\1 /g' | $MC -triple=tlcs900 --disassemble 2>&1 | command grep -v "^\s*\.text" | sed 's/^[ \t]*//' | tr '\n' '|')
  echo "$hx" | xxd -r -p > $D/_p.bin
  ud=$($UD $D/_p.bin -arch tlcs900 -basepc 0 2>&1 | head -3 | sed 's/^[0-9a-f]*: //' | tr -s ' ' | tr '\n' '|')
  printf '%-22s LLVM: %-45s MAME: %s\n' "$hx" "$llvm" "$ud"
done
