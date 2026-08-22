#!/bin/bash
# QUESTION: forget the probe's own plumbing -- if I dd the bytes straight out of
# the ROM FILE at a named address and assemble the spelling the `ld (r+imm),imm`
# rule gives, are they the same bytes?  Nine sites, one per encoding family and
# per interesting displacement class (d8==0 needing the +256 sentinel, negative
# d8, word store, both F3 raw forms, and the one F3 site whose register byte has
# no register name).
#
# RUN (from the repo root):  bash tools/spelling-probes/spotcheck_ld_ri_imm.sh
# RESULT 2026-08-22, LLVM tlcs900_backend@cb165c5cdc4b: 9 sites, 9 MATCH.
#
# Full census, sweep and trap list: verify_ld_ri_imm.py / README-ld_ri_imm.md
set -u
MC=~/compartilhado/llvm-project/build/bin/llvm-mc
ok=0; n=0
check() { # rom base addr nbytes spelling
  local off=$(( $3 - $2 ))
  local b e v
  b=$(dd if=original_ROMs/$1 bs=1 skip=$off count=$4 2>/dev/null \
      | xxd -p | sed 's/../& /g;s/ $//')
  e=$(printf '%s\n' "$5" | $MC -triple=tlcs900 --show-encoding 2>&1 \
      | grep -o 'encoding: \[[^]]*\]' | sed 's/encoding: \[//;s/\]//;s/0x//g;s/,/ /g')
  n=$((n+1))
  if [ "$b" = "$e" ]; then v=MATCH; ok=$((ok+1)); else v=DIFFER; fi
  printf '%-28s %06x  rom=[%-22s] mc=[%-22s] %s  <- %s\n' "$1" "$3" "$b" "$e" "$v" "$5"
}
check kn5000_v7_program.rom   0xE00000 0xefb8e2 4 'ld (xiz+256), 0x90'
check kn5000_v7_program.rom   0xE00000 0xfe0cb8 4 'ld (xsp+256), 4'
check kn5000_v9_program.rom   0xE00000 0xe0e376 4 'ld (xiz-16), 74'
check kn5000_v7_program.rom   0xE00000 0xfc36e1 5 'ldw (xhl-2), 128'
check kn5000_v7_program.rom   0xE00000 0xfdfa87 6 'stib_ind 253, 244, 1, 0'
check kn5000_v7_program.rom   0xE00000 0xfebe2d 7 'stiw_ind 253, 142, 0, 0, 0'
check kn5000_table_data.rom   0x800000 0x85fc3f 6 'stib_ind 29, 176, 2, 0'
check kn5000_v7_program.rom   0xE00000 0xf07a6d 4 'ld (xwa+6), 255'
check kn5000_v10_program.rom  0xE00000 0xf78c80 5 'ldw (xsp+38), 1'
echo "$ok/$n MATCH"
[ "$ok" = "$n" ]
