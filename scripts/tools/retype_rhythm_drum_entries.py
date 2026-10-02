#!/usr/bin/env python3
"""retype_rhythm_drum_entries.py -- RhythmDrum_Entries: four independent bytes per entry, as the reader splits them.

QUESTION THIS ANSWERS / JOB IT DOES
  RhythmDrum_Entries (1718 u32, naka_widget_descriptors.c) was headed "their field meaning is not
  established" (a census research target, 6,872 B per maincpu tree).  Its one reader,
  VoiceAssign_ProcessRequest -> VoiceAssign_Process_Loop / _Return / __pad_F671E7
  (sequencer/accompaniment_engine.s), splits each entry into four bytes used independently --
  established 2026-10-02 by reading those routines; see the header this writes.  This rewrites
  the headers (.s and the C member comment) in v10/v9/v7, and retypes the C member as
  rhythm_drum_entry_t[1718] {param_lo, param_hi, preset_sel, ram3881_value} with each u32
  initializer split little-endian -- same bytes (`make gate-all`).  The locator header
  (RhythmROM_BankProgramLocators) gets what the value locates: the Rhythm Data ROM at 0x400000.

USAGE
  python3 scripts/tools/retype_rhythm_drum_entries.py        # then make gate-all
"""
import re
import subprocess

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
OLD_ENT = ["RhythmDrum_Entries -- 1718 u32 in 70 consecutive groups whose sizes",
           "are RhythmDrum_EntryCounts (sum 1718 = 6872 / 4 -- the layout is",
           "pinned by that sum). VoiceAssign_ProcessRequest (v10/v9 0x{a}, v7",
           "0x{b}): xde = (sum of the counts before the group + byte 0x37{c} +",
           "drum) * 4; `ld xhl,(<this>+xde)`. The values (0x100, 0x10100, 0x20100,",
           "...) are not addresses; their field meaning is not established."]
NEW_ENT = ["RhythmDrum_Entries -- 1718 entries of four bytes in 70 consecutive groups",
           "whose sizes are RhythmDrum_EntryCounts (sum 1718 = 6872 / 4).",
           "VoiceAssign_ProcessRequest (v10/v9 0x{a}, v7 0x{b}) picks entry (sum of",
           "the counts before the group + byte 0x37{c} + drum) and splits it, each",
           "byte on its own path (VoiceAssign_Process_Loop / _Return, __pad_F671E7):",
           "  +3 is stored at RAM 0x3881 + drum;",
           "  +0/+1 (HL) go to SndParam_ApplyProgramChange_Safe (HL to RAM 0x90EA,",
           "     selector 72 to 0x90EC, SndParam_ApplyAndFetch, new HL from 0x90EE),",
           "     then VoiceParam_ClampAndValidate; the resulting L and H are stored",
           "     at RAM 0x38D2 + drum and 0x38D9 + drum and select",
           "     RhythmROM_BankProgramLocators entry H * 128 + (L & 0x7F);",
           "  +2 is the index __pad_F671E7 reads the byte table",
           "     RegPreset_LoadVoiceData with; that byte & 7 picks entries of two",
           "     word tables.",
           "So an entry is four fields, not one number."]
OLD_LOC = "pairs mark unused (bank, program) slots. What the 32-bit value locates\n{p} is not established."
NEW_LOC = ("pairs mark unused (bank, program) slots. It locates data in the Rhythm\n"
           "{p} Data ROM (0x400000, technics-docs memory-map.md): VoiceAssign_Process_Return\n"
           "{p} computes xix = 0x400000 + (the long at RAM 0x3277) + ((hi & 0xFF) << 16 | lo).")
TYPEDEF = """/* RhythmDrum_Entries' entry: four bytes the reader uses separately (see the member's header). */
typedef struct __attribute__((packed)) {
    uint8_t param_lo;       /* +0: L for SndParam_ApplyProgramChange_Safe */
    uint8_t param_hi;       /* +1: H for it */
    uint8_t preset_sel;     /* +2: index into RegPreset_LoadVoiceData */
    uint8_t ram3881_value;  /* +3: stored at RAM 0x3881 + drum */
} rhythm_drum_entry_t;

"""


def block(lines, prefix):
    return "\n".join(prefix + x if x else prefix.rstrip() for x in lines)


for v in ("v10", "v9", "v7"):
    a, b, c = ("F67128", "F66D24", "B2")
    for path, pre in (("%s/maincpu/ui_widgets/widget_descriptors.s" % v, "; "),
                      ("%s/maincpu/ui_widgets/naka_widget_descriptors.c" % v, "     * ")):
        t = open(path, "rb").read().decode("latin-1")
        old = block([x.format(a=a if pre == "     * " else a.lower(), b=b if pre == "     * " else b.lower(),
                              c=c if pre == "     * " else c.lower()) for x in OLD_ENT], pre)
        new = block([x.format(a=a if pre == "     * " else a.lower(), b=b if pre == "     * " else b.lower(),
                              c=c if pre == "     * " else c.lower()) for x in NEW_ENT], pre)
        assert t.count(old) == 1, (path, "entries header")
        t = t.replace(old, new)
        ol, nl = OLD_LOC.format(p=pre.rstrip()), NEW_LOC.format(p=pre.rstrip())
        assert t.count(ol) == 1, (path, "locator header")
        t = t.replace(ol, nl)
        if path.endswith(".c"):
            assert t.count("    uint32_t RhythmDrum_Entries[1718];") == 1
            t = t.replace("    uint32_t RhythmDrum_Entries[1718];", "    rhythm_drum_entry_t RhythmDrum_Entries[1718];")
            m = re.search(r'(    \.RhythmDrum_Entries = \{\n)(.*?)(\n    \},)', t, re.S)
            vals = [int(x, 16) for x in re.findall(r'0x[0-9A-Fa-f]{8}', m.group(2))]
            assert len(vals) == 1718
            body = "\n".join("        { 0x%02X, 0x%02X, 0x%02X, 0x%02X }," % (x & 0xFF, x >> 8 & 0xFF, x >> 16 & 0xFF, x >> 24)
                             for x in vals)
            t = t[:m.start(2)] + body + t[m.end(2):]
            k = t.index("typedef struct __attribute__((packed)) {")
            t = t[:k] + TYPEDEF + t[k:]
        open(path, "wb").write(t.encode("latin-1"))
        print(path, "ok")
