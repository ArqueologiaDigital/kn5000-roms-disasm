#!/bin/bash
# usage: dis.sh ADDR_HEX NBYTES_BEFORE COUNT_BYTES   (v9 ROM)
a=$((0x$1)); b=$2; n=$3
start=$((a-b))
/home/fsanches/compartilhado/tools/unidasm /home/fsanches/compartilhado/kn5000-roms-disasm/original_ROMs/kn5000_v9_program.rom -arch tlcs900 -basepc $(printf '0x%X' $start) -skip $((start-0xE00000)) -count $n
