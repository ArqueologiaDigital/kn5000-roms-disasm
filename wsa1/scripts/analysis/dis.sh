#!/bin/bash
# dis.sh <rom-letter> <cpu-address-hex> [nbytes]
# Disassembles a window of a WSA1 ROM at its real CPU address.
# Bases: a=0xF80000  b=0xF00000  c=0xF80000  d=0 (unknown, file-relative)
set -e
ROOT=/home/fsanches/compartilhado/wsa1-roms-disasm
UNIDASM=${UNIDASM:-/home/fsanches/compartilhado/kn7000_mame_build/unidasm}
case "$1" in
  a) F=$ROOT/original_ROMs/wsa1_prom_a.ic12; BASE=$((0xF80000));;
  b) F=$ROOT/original_ROMs/wsa1_prom_b.ic13; BASE=$((0xF00000));;
  c) F=$ROOT/original_ROMs/wsa1_prom_c.ic28; BASE=$((0xF80000));;
  d) F=$ROOT/original_ROMs/wsa1_prom_d.bin;  BASE=0;;
  *) echo "usage: dis.sh {a|b|c|d} <hex-cpu-addr> [nbytes]" >&2; exit 1;;
esac
ADDR=$((16#${2#0x}))
N=${3:-128}
OFF=$((ADDR - BASE))
if [ $OFF -lt 0 ]; then echo "address 0x$(printf %06X $ADDR) is below base of ROM $1" >&2; exit 1; fi
T=$(mktemp)
dd if="$F" of="$T" bs=1 skip=$OFF count=$N status=none
$UNIDASM "$T" -arch tlcs900 -basepc $(printf 0x%X $ADDR)
rm -f "$T"
