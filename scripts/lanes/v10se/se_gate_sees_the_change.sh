#!/bin/bash
# CAN THE BYTE GATE ACTUALLY SEE THIS LANE'S CONVERSION?
#
# QUESTION ANSWERED
#   A green gate certifies nothing unless the gate would have gone RED on the
#   change.  This lane replaced 1,769 B of sound_editor_ui.s with .incbin of
#   C-compiled screen descriptors; if the descriptors were somehow not actually
#   reaching the ROM (stale prerequisite, wrong section, dead .incbin), the gate
#   would stay green while the conversion did nothing.
#
#   This script perturbs ONE field of ONE newly-integrated descriptor
#   (se_setup_sel1.c, boundary_0.p1.x: 13 -> 14, which is the ROM byte at
#   0x00F12B4B), rebuilds the v10 image, and asserts the rebuild now DIFFERS
#   from the dump AT THAT ADDRESS.  Then it restores the file and asserts the
#   rebuild is identical again.
#
# RUN   bash scripts/lanes/v10se/se_gate_sees_the_change.sh
set -u
cd "$(dirname "$0")/../../.." || exit 1
C=v10/maincpu/audio/sound_editor_screens/se_setup_sel1.c
ADDR=0x00F12B4B
OFF=$(( 0xF12B4B - 0xE00000 ))

cp "$C" "$C.orig"
trap 'mv -f "$C.orig" "$C"' EXIT

python3 - "$C" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding='latin-1').read()
assert '.x = 13, .y = 73' in s, "expected field not found -- update this probe"
open(p, 'w', encoding='latin-1').write(s.replace('.x = 13, .y = 73', '.x = 14, .y = 73', 1))
PY

make rebuilt_ROMs/kn5000_v10_program.llvm.rom >/dev/null 2>&1
GOT=$(python3 -c "
o=open('original_ROMs/kn5000_v10_program.rom','rb').read()
r=open('rebuilt_ROMs/kn5000_v10_program.llvm.rom','rb').read()
d=[i for i,(a,b) in enumerate(zip(o,r)) if a!=b]
print(len(d), ' '.join(hex(0xE00000+i) for i in d[:5]))")
echo "perturbed: $GOT differing byte(s), expected exactly 1 at $ADDR"
case "$GOT" in
  "1 $(python3 -c "print(hex(0xE00000+$OFF))")") echo "  GATE SEES IT: PASS";;
  *) echo "  GATE DOES NOT SEE IT: FAIL";;
esac

mv -f "$C.orig" "$C"; touch "$C"   # mv restores the OLD mtime, which make would ignore
trap - EXIT
make rebuilt_ROMs/kn5000_v10_program.llvm.rom >/dev/null 2>&1
if cmp -s rebuilt_ROMs/kn5000_v10_program.llvm.rom original_ROMs/kn5000_v10_program.rom; then
  echo "restored: byte-identical again: PASS"
else
  echo "restored: STILL DIFFERS -- something is wrong: FAIL"
fi
