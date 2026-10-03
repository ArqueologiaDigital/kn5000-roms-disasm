#!/bin/bash
# run.sh -- re-derive the v7 audio/sndparam_routines.s + midi/midi_serial_routines.s port.
#
# QUESTION THIS ANSWERS: can v7's sndparam/midi_serial span carry v10's names at the addresses of
# v10's code (no 0x41A drift), keep every instruction the pre-port files had, and still build the
# v7 dump byte for byte?  Run from the repository root on a tree whose four v7 files below are the
# pre-port ones (the commit before this note's commit).  Ends with `make gate-all`.
set -euo pipefail
CACHE="${TMPDIR:?}/port-sndser"
mkdir -p "$CACHE"
rm -f -- "${CACHE:?}/v7_map.json"            # the v7 map must be the pre-port tree's
cat v7/maincpu/audio/sndparam_routines.s v7/maincpu/midi/midi_serial_routines.s > "$CACHE/span.before.s"
make rebuilt_ROMs/kn5000_v7_program.llvm.elf rebuilt_ROMs/kn5000_v10_program.llvm.elf > /dev/null
# 1. port v10's text onto v7's bytes; gaps keep the pre-port lines; old names other files reach only
#    as `Name + k` are not kept (the link then fails until step 2)
PORT_GAPFILL=1 PORT_REPOINT=1 PORT_CACHE="$CACHE" \
    python3 scripts/converters/port_v10_span_to_v7.py --span sndser --apply || true
# 2. re-aim the other files' references at the labels now at the addresses they meant
python3 scripts/converters/repoint_v7_after_port.py "$CACHE/span.before.s" --apply
# 3. the one reference with no label at its address: SndParam_RegisterHandlers[4] (v7 0xFCD5CA)
python3 - <<'PY'
import os, sys
f = "v7/maincpu/ui_widgets/widget_dispatch.s"
b = open(f, "rb").read().decode("latin-1")
o = ".long SndParam_ResolveWidgetVariant2_Data + 131"
assert b.count(o) == 1
d = b.replace(o, ".long 0x00fcd5ca").encode("latin-1"); open(f + ".tmp", "wb").write(d); os.replace(f + ".tmp", f)
PY
make rebuilt_ROMs/kn5000_v7_program.llvm.rom > /dev/null
cmp rebuilt_ROMs/kn5000_v7_program.llvm.rom original_ROMs/kn5000_v7_program.rom
python3 - <<'PY'
import os, sys
sys.path.insert(0, "scripts/tools")
import place_labels as P
pl = P.Planner("v7")
print(pl.add(0xFCD5CA, "SndParam_RegisterType4_Handler"))
pl.apply()
f = "v7/maincpu/ui_widgets/widget_dispatch.s"
b = open(f, "rb").read().decode("latin-1")
d = b.replace(".long 0x00fcd5ca", ".long SndParam_RegisterType4_Handler").encode("latin-1")
open(f + ".tmp", "wb").write(d); os.replace(f + ".tmp", f)
PY
make gate-all
