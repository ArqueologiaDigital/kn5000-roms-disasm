#!/bin/bash
# usage: dis.sh ADDR_HEX_START COUNT_BYTES(decimal or 0x)
a=$((0x$1)); n=$(($2))
/home/fsanches/compartilhado/tools/unidasm /home/fsanches/compartilhado/kn5000-roms-disasm/original_ROMs/kn5000_v7_program.rom -arch tlcs900 -basepc $(printf '%x' $a) -skip $(printf '%d' $((a-0xE00000))) -count $n
