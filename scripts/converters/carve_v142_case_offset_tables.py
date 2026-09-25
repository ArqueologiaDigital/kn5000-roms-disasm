#!/usr/bin/env python3
r"""carve_v142_case_offset_tables.py -- re-carve sub-CPU v1.42 data 0x00F693-0x00F785 by its readers.

QUESTION THIS ANSWERS
    What are the 243 bytes at 0x00F693-0x00F785 of the v1.42 sub-CPU payload?  Before this
    carve they sat under ten labels that no code referenced (PitchBend_DispatchTable at
    0x00F69B, Voice_GroupOffsets_A..C, Voice_BitMask_ChannelType, MIDI_NoteFreqTable,
    Voice_EnvelopeRateTable, Voice_PolyphonyConfig, Voice_ParamScaleTable, Const_ChannelMax)
    and the first 8 bytes were called "0x00 filler" in Voice_SFX_ModulationTable's header,
    while twelve instructions load addresses INSIDE the span -- `lda xix, (0x00f6a7:24)` and
    friends -- none of them at one of those labels.

    Every one of those twelve reader sites is a computed goto (`add wa,wa / lda xix,TABLE /
    ldw_sri WA / lda xix,BASE / jp_ind`), a byte lookup, or a word lookup.  The reader fixes
    each table's start (the lda operand), its entry size (the `add r,r` doubling or `muls 3`),
    and its entry count (the reader's range check, or -- where the reader has none -- the
    next table's start).  The 13 tables tile 0x00F693-0x00F785 exactly.

WHAT --apply DOES
    1. subcpu_data_tables.s: replaces the lines emitting 0x00F693-0x00F785 (asserted by a
       fresh address map to be exactly the `.zero 8` tail of Voice_SFX_ModulationTable through
       `Const_ChannelMax: .byte 0x07`, with no comments among them) by 13 labelled tables with
       evidence headers.  Jump-offset entries are written `.short Target - Base`, so the byte
       gate pins every case target.  Corrects Voice_SFX_ModulationTable's "8 bytes of 0x00
       filler" line (★ CORRECTED, proven false by Pitch_Get_Patch_Octave_Shift's reader).
    2. kn5000_subprogram_v142.s: inserts a label at every case target that has none
       (`TVF_Build_Dispatch_Case1`, `AudioChannel_Stub_Cmd02`, `Voice_CC_Num120`,
       `Voice_SystemMsg_SubA3`, ...), directly above the target's instruction line.
    The reader sites' numeric operands are then made symbolic by
    scripts/converters/symbolize_v142_abs24_operands.py (exact-label mode), run separately.

GUARDS
    The address map is scripts/analysis/v142_line_map.py (byte-identical-mirror guard).  Every
    table's bytes are re-read from the ROM and every `.short T - B` is checked to equal the ROM
    word before anything is written; every inserted label must land on a line that starts at
    exactly the target address.

RUN
    python3 scripts/converters/carve_v142_case_offset_tables.py           # dry: checks only
    python3 scripts/converters/carve_v142_case_offset_tables.py --apply   # then make gate
"""
import argparse
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "scripts/analysis"))
import v142_line_map as lm  # noqa: E402

TREE = os.path.join(ROOT, "v142/subcpu")
CODE, DATA = "kn5000_subprogram_v142.s", "subcpu_data_tables.s"
rom = open(os.path.join(ROOT, "original_ROMs/kn5000_subprogram_v142.rom"), "rb").read()


def R(a, n):
    return rom[a - 0xEF00:a - 0xEF00 + n]


# ---------------------------------------------------------------------------------------------
# The computed-goto tables: (addr, count, base label, base addr, table label, header, case names,
# per-entry comment).  case_name(k) names the label to create at entry k's target if none exists.
def hexs(k):
    return "%02X" % k


JUMP = [
    dict(addr=0xF693, n=10, base="Pitch_Get_Patch_Octave_Shift_JumpTable", label="Pitch_OctaveShift_CaseOffsets",
         hdr=["10 x u16 case offsets from Pitch_Get_Patch_Octave_Shift_JumpTable (0x022982).",
              "Read by Pitch_Get_Patch_Octave_Shift (0x02294E): WA = selector - 0x10, range-checked 0..9",
              "(so 10 entries), doubled, `lda xix,(table:24) / ldw_sri / lda xix,(base:24) / jp_ind`.",
              "Only selector 0x14 (entry 4) reaches the fallback; the other nine return 0."],
         case=lambda k: None, ent=lambda k: "selector 0x%02X" % (0x10 + k)),
    dict(addr=0xF6A7, n=6, base="TVF_Build_Dispatch_Table", label="TVF_Build_CaseOffsets",
         hdr=["6 x u16 case offsets from TVF_Build_Dispatch_Table (0x02412B).",
              "Read by TVF_Build_Dispatch (0x024102): index = (tonerec+54) & 7, range-checked 0..5",
              "(6 entries), doubled, then the same ldw_sri / jp_ind computed goto."],
         case=lambda k: "TVF_Build_Dispatch_Case%d" % k, ent=lambda k: "(tonerec+54)&7 = %d" % k),
    dict(addr=0xF6B3, n=6, base="TVF_BuildEmit_Short_Dispatch_Table", label="TVF_BuildEmit_Short_CaseOffsets",
         hdr=["6 x u16 case offsets from TVF_BuildEmit_Short_Dispatch_Table (0x02432C).",
              "Read by TVF_BuildEmit_Short_Dispatch (0x024300): index = (tonerec+0x0F) & 7,",
              "range-checked 0..5 (6 entries), doubled, ldw_sri / jp_ind."],
         case=lambda k: "TVF_BuildEmit_Short_Case%d" % k, ent=lambda k: "(tonerec+0x0F)&7 = %d" % k),
    dict(addr=0xF6BF, n=6, base="TVF_Emit_Registers_Table", label="TVF_Emit_Registers_CaseOffsets",
         hdr=["6 x u16 case offsets from TVF_Emit_Registers_Table (0x024472).",
              "Read by TVF_Emit_Registers (0x024444): index = (tonerec+54) & 7, range-checked 0..5",
              "(6 entries), doubled, ldw_sri / jp_ind.  Cases 1 and 2 share one body."],
         case=lambda k: "TVF_Emit_Registers_Case%d" % k, ent=lambda k: "(tonerec+54)&7 = %d" % k),
    dict(addr=0xF6CB, n=6, base="Voice_PanReg_WriteDispatchB_Table", label="Voice_PanReg_WriteDispatchB_CaseOffsets",
         hdr=["6 x u16 case offsets from Voice_PanReg_WriteDispatchB_Table (0x024582); the same six",
              "values as TVF_Emit_Registers_CaseOffsets, for the twin landing pad.",
              "Read by Voice_PanReg_WriteDispatchB (0x024554): index = (tonerec+0x0F) & 7, range-checked",
              "0..5 (6 entries), doubled, ldw_sri / jp_ind.  Cases 1 and 2 share one body."],
         case=lambda k: "Voice_PanReg_WriteDispatchB_Case%d" % k, ent=lambda k: "(tonerec+0x0F)&7 = %d" % k),
]
JUMP2 = [
    dict(addr=0xF6DF, n=10, base="AudioMod_Porta_Curve_JumpBase", label="AudioMod_PortaCurve_CaseOffsets",
         hdr=["10 x u16 case offsets from AudioMod_Porta_Curve_JumpBase (0x028500).",
              "Read by AudioMod_Apply_Porta_Curve (0x0284AC): index = A - 0x10, range-checked 0..9",
              "(10 entries), doubled, ldw_sri / jp_ind.  Only A = 0x14 (entry 4) reaches",
              "AudioMod_Apply_Porta_Curve_Skip; the other nine take the shared base body."],
         case=lambda k: None, ent=lambda k: "A = 0x%02X" % (0x10 + k)),
]
JUMP3 = [
    dict(addr=0xF703, n=27, base="AudioChannel_DispatchTable", label="AudioChannel_CaseOffsets",
         hdr=["27 x u16 case offsets from AudioChannel_DispatchTable (0x029E5B): the stub for",
              "destination command id k+1 (entries 0..2 are 5-byte stubs, the rest 11-byte ones).",
              "Read by AudioChannel_Dispatch (0x029E31): index = ((XDE+1) & 0x3F) - 1, range-checked",
              "0..0x1A (27 entries), doubled, ldw_sri / jp_ind."],
         case=lambda k: "AudioChannel_Stub_Cmd%s" % hexs(k + 1), ent=lambda k: "command id 0x%02X" % (k + 1)),
    dict(addr=0xF739, n=11, base="Voice_CC_ModWheel", label="Voice_CC_Mode_CaseOffsets",
         hdr=["11 x u16 case offsets for controller numbers 120..130, relative to Voice_CC_ModWheel",
              "(0x02A306, which is only the base of the arithmetic here, not a case).",
              "Read by Voice_CtrlChange (0x02A282) after its explicit compares for the other CCs:",
              "WA = CC - 0x78, range-checked 0..0x0A (11 entries), doubled, ldw_sri / jp_ind.",
              "122 and 124..127 go straight to Voice_CC_Exit.  (MIDI 1.0 names 120/121/123 All",
              "Sound Off / Reset All Controllers / All Notes Off; 128..130 are not MIDI controller",
              "numbers, so they arrive from inside the firmware.  Each target's body is its callee",
              "list, written next to its entry.)"],
         case=lambda k: "Voice_CC_Num%d" % (0x78 + k), ent=lambda k: "CC %d" % (0x78 + k)),
    dict(addr=0xF74F, n=23, base="Voice_SystemMsg_DispatchTable", label="Voice_SystemMsg_CaseOffsets",
         hdr=["23 x u16 case offsets from Voice_SystemMsg_DispatchTable (0x02A7FC).",
              "Read by Voice_SystemMsg (0x02A7AF, the jump at Voice_SystemMsg_DispatchJump):",
              "sub-command C - 0x80 in 0..7 is used directly; otherwise C - 0x80 - 0x1B must be",
              "8..0x16, so entries 8..22 serve sub-commands 0xA3..0xB1 (23 entries in all).",
              "Doubled, ldw_sri / jp_ind.  Sub-command 0x84 lands on a bare `ret`."],
         case=lambda k: ("Voice_SystemMsg_Sub%s" % hexs(0x80 + k) if k < 8 else
                         "Voice_SystemMsg_Sub%s" % hexs(0xA3 + k - 8)),
         ent=lambda k: "sub-command 0x%02X" % (0x80 + k if k < 8 else 0xA3 + k - 8)),
]

# Per-entry callee notes for the CC and system-message tables, from the code at each target.
CC_NOTE = {0: "Voice_PortamentoSlots_WriteHW(part)", 1: "Voice_NoteState_Clear(part)",
           3: "Voice_SetLFO_ActiveFlag, Voice_AllocateForRelease, Voice_ParamInit",
           8: "Voice_CC_SetPortamentoRate(part, value)",
           9: "Voice_CC_SetPortamentoDepth, then Pitch_Refresh_Sounding_Voices",
           10: "Voice_CC_SetPortamentoTime(part, value)"}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    amap = lm.line_map()
    at_line = {}
    for (f, i), ad in amap.items():
        at_line.setdefault((f, ad), i)
    src = {f: open(os.path.join(TREE, f), "rb").read().decode("latin-1").split("\n") for f in (CODE, DATA)}

    # existing labels of the code file, by address (label line -> address of next emitting line)
    import re
    lab_at = {}
    code_rows = sorted((ad, i) for (f, i), ad in amap.items() if f == CODE)
    nxt = {}
    j = 0
    for i, ln in enumerate(src[CODE]):
        m = re.match(r"^([A-Za-z_]\w*):", ln)
        if m:
            # address of the first emitting line at or after i
            k = i
            while (CODE, k) not in amap and k < len(src[CODE]) - 1:
                k += 1
            lab_at.setdefault(amap.get((CODE, k)), []).append(m.group(1))
    base_addr = {}
    for ad, names in lab_at.items():
        for nme in names:
            base_addr[nme] = ad

    inserts = {}       # code line index -> label name
    tables = []        # (addr, lines)
    errors = []
    for t in JUMP + JUMP2 + JUMP3:
        b = base_addr.get(t["base"])
        if b is None:
            errors.append("base %s not found" % t["base"])
            continue
        offs = struct.unpack("<%dH" % t["n"], R(t["addr"], 2 * t["n"]))
        rows = []
        first = {}
        for k, o in enumerate(offs):
            tgt = b + o
            if tgt in first:
                name = first[tgt]
            elif tgt in lab_at:
                name = lab_at[tgt][0]
            else:
                name = t["case"](k)
                if name is None:
                    errors.append("%s entry %d: target 0x%06X has no label" % (t["label"], k, tgt))
                    continue
                li = at_line.get((CODE, tgt))
                if li is None:
                    errors.append("%s entry %d: no line starts at 0x%06X" % (t["label"], k, tgt))
                    continue
                inserts[li] = name
                lab_at[tgt] = [name]
            first.setdefault(tgt, name)
            note = t["ent"](k)
            if t["label"] == "Voice_CC_Mode_CaseOffsets":
                note += " -> " + CC_NOTE.get(k, "Voice_CC_Exit (ignored)")
            rows.append((name, t["base"], note, o, tgt))
        tables.append((t, rows))

    if errors:
        for e in errors:
            print("ERROR", e)
        sys.exit(1)

    out = []
    W = max(len("%s - %s" % (r[0], r[1])) for _, rows in tables for r in rows)

    def emit_jump(t, rows):
        out.append("; --- 0x%06X-0x%06X  %s" % (t["addr"], t["addr"] + 2 * t["n"] - 1, t["hdr"][0]))
        for h in t["hdr"][1:]:
            out.append("; " + h)
        out.append("%s:" % t["label"])
        for name, base, note, o, tgt in rows:
            expr = "%s - %s" % (name, base)
            out.append("\t.short %s%s; %s" % (expr, "\t" * max(1, (W + 8 - len(expr)) // 8 + 1), note))

    for t, rows in tables:
        if t["addr"] == 0xF6DF:
            # the two 4-byte bus-routing mask tables come just before this one (0xF6D7, 0xF6DB)
            ma, mb = R(0xF6D7, 4), R(0xF6DB, 4)
            assert ma == bytes([0x01, 0x04, 0x10, 0x40]) and mb == bytes([0x02, 0x08, 0x20, 0x80]), (ma, mb)
            out += [
                "; --- 0x00F6D7-0x00F6DE  two 4-byte bit tables, one byte per output bus w = 0..3",
                "; Read by AudioMod_Apply_BusRouting (0x02833C): per bus w it loads byte [table + w]",
                "; from each (`lda xiy,(table:24) / ld L,(XIY+HL)`, HL = w, loop bound w < 4) and ANDs it",
                "; with the caller's C: EnableBits[w] = 1 << 2w, OrIXBits[w] = 1 << (2w+1).  With the",
                "; enable bit clear the routine clears DE|IX in slot word w (+0x18 of output-slot record w",
                "; of the part); with it set, the second bit chooses OR DE|IX (set) or clear IX then OR DE.",
                "AudioMod_BusRouting_EnableBits:",
                "\t.byte 0x01, 0x04, 0x10, 0x40\t\t; buses 0..3: bits 0, 2, 4, 6 of C",
                "AudioMod_BusRouting_OrIXBits:",
                "\t.byte 0x02, 0x08, 0x20, 0x80\t\t; buses 0..3: bits 1, 3, 5, 7 of C",
            ]
        if t["addr"] == 0xF703:
            w = struct.unpack("<8H", R(0xF6F3, 16))
            assert [x >> 8 for x in w] == [0x60, 0x62, 0x64, 0x65, 0x67, 0x69, 0x6B, 0x6C] and \
                all(x & 0xFF == 0x80 for x in w), w
            out += [
                "; --- 0x00F6F3-0x00F702  8 x u16, rhythm-mode word stored at 0x041360",
                "; Read by Voice_SetRhythmMode (0x028B9C): index = bits 7..4 of the packed SysEx byte A",
                "; (`and c,0xF0 / srl c,4 / add bc,bc / lda xde,(table:24) / ldw_sri`), result -> 0x041360.",
                "; Count 8 is pinned by the next table (AudioChannel_CaseOffsets, 0x00F703): the reader",
                "; does NOT bound the index, so a nibble of 8..15 would read that table instead.",
                "; High bytes 0x60 0x62 0x64 0x65 0x67 0x69 0x6B 0x6C step 2,2,1,2,2,2,1 -- a major scale --",
                "; and the low byte is 0x80 in all eight.  Reading them as 8.8 semitone pitches (the unit",
                "; Pitch_Get_Patch_Octave_Shift uses) is an inference from that pattern; the consumer of",
                "; 0x041360 was not traced.",
                "Voice_RhythmMode_ScalePitch_Table:",
                "\t.short 0x6080, 0x6280, 0x6480, 0x6580, 0x6780, 0x6980, 0x6b80, 0x6c80",
            ]
        emit_jump(t, rows)
    sel = R(0xF77D, 9)
    assert sel == bytes([0, 1, 6, 3, 5, 8, 2, 4, 7]), sel
    out += [
        "; --- 0x00F77D-0x00F785  3 records x 3 bytes: scratch-array slot of each 4-bit field",
        "; Read by Voice_Selector_Unpack3Groups (0x02ABEE): for group E = 0..2 it reads bytes",
        "; [table + 3E + 0], [+1], [+2] (three `lda (table+k:24)` bases, index E*3 via `muls 3`) and",
        "; stores the k-th low nibble of BC at that index of the caller's 9-byte stack array.",
        "; The nine destinations are a permutation of 0..8.  Count 3 = the three calls E = 0..2 made",
        "; by Voice_Selector_FindBestSlot.  (The last byte, 0x07, was labelled Const_ChannelMax.)",
        "Voice_Selector_FieldSlot_Table:",
        "\t.byte 0, 1, 6\t\t; group 0: fields 0,1,2 -> slots 0, 1, 6",
        "\t.byte 3, 5, 8\t\t; group 1: fields 0,1,2 -> slots 3, 5, 8",
        "\t.byte 2, 4, 7\t\t; group 2: fields 0,1,2 -> slots 2, 4, 7",
    ]

    # --- locate the data lines to replace
    d = src[DATA]
    first_i = at_line[(DATA, 0xF693)]
    last_i = at_line[(DATA, 0xF785)]
    assert d[first_i].strip() == ".zero 8", d[first_i]
    assert d[last_i].strip() == ".byte 0x07" and d[last_i - 1].strip() == "Const_ChannelMax:", d[last_i - 1:last_i + 1]
    assert not any(";" in x for x in d[first_i:last_i + 1]), "comments inside the replaced span"
    # nothing between first_i and last_i may emit outside 0xF693..0xF785 (it cannot: contiguous)
    old = "\n".join(d[first_i:last_i + 1])
    new_block = out
    # the SFX table keeps no filler: its last data line was the .zero 8 -> drop it, then blank
    d2 = d[:first_i] + [""] + new_block + d[last_i + 1:]
    txt = "\n".join(d2)
    oldc = ("; 0x00F693-0x00F69A is 8 bytes of 0x00 filler between this table and the next.\n")
    newc = ("; ★ CORRECTED 2026-09-25: this line said \"0x00F693-0x00F69A is 8 bytes of 0x00 filler between\n"
            "; this table and the next\".  They are entries 0..3 of Pitch_OctaveShift_CaseOffsets, the\n"
            "; 10-entry table Pitch_Get_Patch_Octave_Shift reads from 0x00F693 (carve below).\n")
    newc = newc.encode("utf-8").decode("latin-1")    # the file is UTF-8 text handled as latin-1
    assert txt.count(oldc) == 1
    txt = txt.replace(oldc, newc)

    # --- code labels
    c = src[CODE]
    for li in sorted(inserts, reverse=True):
        c.insert(li, "%s:" % inserts[li])
    print("tables: %d; code labels inserted: %d" % (len(tables) + 4, len(inserts)))
    for li in sorted(inserts):
        print("  %s:%d  %s" % (CODE, li + 1, inserts[li]))
    print("replaced %d data lines (%d bytes old text) with %d lines" % (last_i - first_i + 1, len(old), len(new_block)))
    if a.apply:
        open(os.path.join(TREE, DATA), "wb").write(txt.encode("latin-1"))
        open(os.path.join(TREE, CODE), "wb").write("\n".join(c).encode("latin-1"))
        print("written; now run symbolize_v142_abs24_operands.py --apply and make gate")


if __name__ == "__main__":
    main()
