#!/usr/bin/env python3
"""Spec for retype_data_objects.py: maincpu 0xEEC288-0xEED117, the tree's
"Character Mapping Tables" -- 28 x 128-byte byte maps, part of them decoded
as instructions (`swi 7`, `push xsp`, `ld xsp,4294967295` ...).  Retyped as
bytes; the existing one-line comments are carried over verbatim; each map
states what the scans could and could not establish."""
import json
import os
import struct

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
B = 0xE00000
d = open(os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom"), "rb").read()
TAB = [struct.unpack_from("<I", d, 0xEF0319 - B + 4 * i)[0] for i in range(42)]
USE = {}
for i, p in enumerate(TAB):
    USE.setdefault(p, []).append(i)

OLD = {  # the tree's one-line comment above each label (v10/v9), kept verbatim
    "CharMap_Preamble_Table": "Character mapping table - preamble/header (sparse)",
    "CharMap_DefaultIdentity": "Character mapping table - default mode (sparse, 6 refs in pointer table)",
    "CharMap_Mode1Forward": "Character mapping table - mode 1 forward (sparse)",
    "CharMap_Mode2Forward": "Character mapping table - mode 2 forward (sparse)",
    "CharMap_Mode3Forward": "Character mapping table - mode 3 forward (sparse)",
    "CharMap_Mode4Forward": "Character mapping table - mode 4 forward (sparse)",
    "CharMap_Mode5Forward": "Character mapping table - mode 5 forward (sparse)",
    "CharMap_Mode6Forward": "Character mapping table - mode 6 forward (sparse)",
    "CharMap_Mode6Reverse": "Character mapping table - mode 6 reverse (sparse)",
    "CharMap_Mode2Reverse": "Character mapping table - mode 2 reverse (sparse)",
    "CharMap_Mode3Reverse": "Character mapping table - mode 3 reverse (sparse)",
    "CharMap_Mode4Reverse": "Character mapping table - mode 4 reverse (sparse)",
    "CharMap_Mode5Reverse": "Character mapping table - mode 5 reverse (sparse)",
    "CharMap_Mode7": "Character mapping table - mode 7 (sparse)",
    "CharMap_Mode8": "Character mapping table - mode 8 (sparse)",
    "CharMap_Mode9": "Character mapping table - mode 9 forward (sparse)",
    "CharMap_Mode10": "Character mapping table - mode 9 reverse (sparse)",
    "CharMap_Mode11": "Character mapping table - mode 10 (sparse)",
    "CharMap_Mode12": "Character mapping table - full permutation variant A",
    "CharMap_Mode13": "Character mapping table - full permutation variant B",
    "CharMap_Mode14": "Character mapping table - full permutation variant C",
    "CharMap_Mode15": "Character mapping table - full permutation variant D (sequential layout)",
    "CharMap_Mode16": "Character mapping table - full permutation variant E",
    "CharMap_Mode17": "Character mapping table - full permutation variant F (sequential layout)",
    "CharMap_Mode18": "Character mapping table - full permutation variant G",
    "CharMap_Mode19": "Character mapping table - full permutation variant H",
    "CharMap_Mode20": "Character mapping table - full permutation variant I",
    "CharMap_Mode21": "Character mapping table - full permutation variant J (sequential layout)",
    "CharMap_Mode22": "Character mapping table - full permutation variant K",
}
ORDER = ["CharMap_DefaultIdentity", "CharMap_Mode1Forward", "CharMap_Mode2Forward",
         "CharMap_Mode3Forward", "CharMap_Mode4Forward", "CharMap_Mode5Forward",
         "CharMap_Mode6Forward", "CharMap_Mode6Reverse", "CharMap_Mode2Reverse",
         "CharMap_Mode3Reverse", "CharMap_Mode4Reverse", "CharMap_Mode5Reverse",
         "CharMap_Mode7", "CharMap_Mode8", "CharMap_Mode9", "CharMap_Mode10", "CharMap_Mode11",
         "CharMap_Mode12", "CharMap_Mode13", "CharMap_Mode14", "CharMap_Mode15", "CharMap_Mode16",
         "CharMap_Mode17", "CharMap_Mode18", "CharMap_Mode19", "CharMap_Mode20", "CharMap_Mode21",
         "CharMap_Mode22"]
O = []
O.append(dict(lo="0xEEC288", hi="0xEEC298", label="CharMap_Preamble_Table", type="long", header=[
    OLD["CharMap_Preamble_Table"],
    "Actually 4 x u32 routine pointers (CharMap_NullPreamble_0..2, CharMap_ActivePreamble):",
    "entry 18 of Subsys_HandlerTableList, so VoiceInit_Dispatch (0xFDDB5A) calls one entry",
    "of it with every other subsystem's table."],
    drop_comments=[OLD["CharMap_Preamble_Table"]]))
O.append(dict(lo="0xEEC298", hi="0xEEC318", label="NoRef_FF128_EEC298", type="byte", per_line=16,
              header=["128 x 0xFF.  No reader: nothing in the v10 ROM names 0xEEC298 (instruction",
                      "operands and 32-bit data pointers both searched).  Purpose not established."]))
for k, nm in enumerate(ORDER):
    a = 0xEEC318 + 0x80 * k
    m = d[a - B:a - B + 128]
    perm = sorted(m) == list(range(128))
    idx = USE.get(a, [])
    hdr = [OLD[nm],
           "128 x u8; %s; CharMap_ModeDispatchTable entr%s %s." % (
               "a permutation of 0..127" if perm else
               "%d of 128 bytes defined (0xFF = none)" % sum(1 for b in m if b != 0xFF),
               "ies" if len(idx) > 1 else "y", ",".join(map(str, idx)))]
    if k == 0:
        hdr += ["Reader not established.  CharMap_ModeDispatchTable (ui/charmap_dispatch_table.s)",
                "is the only thing that points at these maps, and nothing points at it: no",
                "instruction operand in 0xEF0200-0xEF03FF (covers TABLE-4k bases) and no 32-bit",
                "word in the v10, sub-CPU, table-data, custom-data or HD-AE5000 images names",
                "0xEF0319.  The \"keyboard scan codes to character codes\" description in the",
                "block comment above has no reader behind it either.  (RAM 0xE14E, which",
                "CharMap_ActivePreamb_Prologue indexes, is loaded from SoundData_CategoryDescPtr,",
                "not from this table.)"]
    else:
        hdr += ["Reader not established (see CharMap_DefaultIdentity)."]
    O.append(dict(lo="0x%06X" % a, hi="0x%06X" % (a + 128), label=nm, type="byte", per_line=16,
                  header=hdr, drop_comments=[OLD[nm]]))

print(json.dumps({"objects": O}, indent=1))
