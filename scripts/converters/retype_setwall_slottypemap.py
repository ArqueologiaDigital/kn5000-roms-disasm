#!/usr/bin/env python3
r"""SetWall_SlotTypeMap is a 20-byte slot -> type map, not code (v10/v9/v7).

QUESTION ANSWERED
    ui/setwall_routines.s decodes the 20 bytes under SetWall_SlotTypeMap as
    `nop / push sr / normal / reti / ld (9:8),10:io / ... / ret`.  Its readers,
    SetWall_CrossType_MapLookup and SetWall_ParseB0ControlChange, both run
    `ld xde,SetWall_SlotTypeMap; ld l,(xde+hl)` (hl = a slot number); the first
    treats 0xFF as "no type" (`cp l,0xff; jr z,SetWall_CrossType_Reset`), the
    second compares the entry with a.  The 20
    entries match the 20-slot tables beside it (SetWall_SlotMaskTable).  This
    rewrites the lines between the label and SetWall_CrossType_Validate as
    `.byte` read from each ROM (asserting the 20 bytes and the next label).

RUN
    python3 scripts/converters/retype_setwall_slottypemap.py --apply v10 v9 v7 ; make gate
"""
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
HDR = ["; 20 x u8 slot -> type map, 0xFF = no type.  SetWall_CrossType_MapLookup reads it with",
       "; `ld xde,<this>; ld l,(xde+hl)` (hl = slot) and branches to SetWall_CrossType_Reset on",
       "; 0xFF; SetWall_ParseB0ControlChange does the same lookup and compares the entry with a.",
       "; (Formerly decoded as instructions.)"]


def main():
    for v in sys.argv[sys.argv.index("--apply") + 1:]:
        out = subprocess.run([NM, os.path.join(ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % v)],
                             capture_output=True, text=True, check=True).stdout
        S = {l.split()[2]: int(l.split()[0], 16) for l in out.splitlines() if len(l.split()) == 3}
        a, e = S["SetWall_SlotTypeMap"], S["SetWall_CrossType_Validate"]
        assert e - a == 20, (v, e - a)
        d = open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % v), "rb").read()
        t = d[a - 0xE00000:e - 0xE00000]
        path = os.path.join(ROOT, v, "maincpu/ui/setwall_routines.s")
        L = open(path, "rb").read().decode("latin-1").split("\n")
        i, j = L.index("SetWall_SlotTypeMap:"), L.index("SetWall_CrossType_Validate:")
        body = [x for x in L[i + 1:j] if x.strip()]
        assert all(not x.lstrip().startswith(";") for x in body), body
        new = HDR + ["SetWall_SlotTypeMap:",
                     "\t.byte " + ", ".join("0x%02x" % b for b in t[:10]),
                     "\t.byte " + ", ".join("0x%02x" % b for b in t[10:]), ""]
        assert not L[i - 1].startswith(";")
        L[i:j] = new
        open(path, "wb").write("\n".join(L).encode("latin-1"))
        print(v, t.hex(" "))


if __name__ == "__main__":
    main()
