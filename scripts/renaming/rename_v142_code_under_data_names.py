#!/usr/bin/env python3
r"""rename_v142_code_under_data_names.py -- sub-CPU v1.42 routines that still carry DATA-shaped names.

QUESTION THIS ANSWERS / WHAT IT DOES
    Twenty-odd routines in kn5000_subprogram_v142.s kept names from the era when their bytes
    were emitted as `.byte` (`ToneGen_PanTable_02D0DC`, `VoiceParam_FullSetup_ExtData`,
    `DSP_StateTable_DefaultData` ...).  Their own headers already say "MISIDENTIFIED AS DATA"
    and describe what they do; several propose a rename and leave it "to the maintainer".  The
    2026-09-25 semantic brief asks lanes to make exactly that call, so this script renames each
    one to what its header (quoted in RENAMES below) says it does.

    * CODE (the part of each line before `;`) is renamed everywhere, so the byte gate covers
      every reference (an unrenamed operand would fail to assemble).
    * COMMENTS are renamed too, EXCEPT on the lines listed in HISTORICAL: those record what the
      old name was ("MISIDENTIFIED AS DATA (LLVM: X .byte)", "The ELF calls it X") and would
      become false if rewritten.
    * A line `; ★ Renamed 2026-09-25 from <old>: <reason>` is inserted above each renamed label.
    * Not renamed, deliberately: VoiceCC_DataTable_0280FE, VoiceCC_DataTable_028F75 and
      VoiceModWheel_DataTable_02A061 -- scripts/lanes/verify_mislabel_markers.py (not this
      lane's file) looks those names up in the source, and renaming them would break it.

RUN
    python3 scripts/renaming/rename_v142_code_under_data_names.py            # dry: counts
    python3 scripts/renaming/rename_v142_code_under_data_names.py --apply    # then make gate
    The old=new map for assert_comments_preserved.py --rename-map is printed by --map.
"""
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FILES = ["v142/subcpu/kn5000_subprogram_v142.s", "v142/subcpu/subcpu_data_tables.s"]

# old -> (new, reason quoted/condensed from the routine's existing header)
RENAMES = {
    "VoiceSlot_DataTable_02AE22": ("Voice_SetArticWord0_LowByte",
        "header: replaces the low byte of articulation word 0, part+0x102 = (.. & 0xFF00) | C"),
    "VoiceAllocate_DataTable_02CD14": ("Voice_Query_PartVoices_Mask7F",
        "header: the mode-0x00 query-packet builder (mask 0x007F) beside Voice_Query_PartVoices"),
    "ToneGen_PanTable_02D0DC": ("ToneGen_WriteReg0080_StrobeClear",
        "header: writes TG 0x0080+ch from shadow+0x04 with bit15 (the load strobe) cleared"),
    "ToneGen_NoteTable_02D55E": ("ToneGen_WriteReg0840_Shadow2E",
        "header: single-register writer, TG 0x0840+ch <- shadow+0x2E"),
    "ToneGen_GlobalConfigTable_02D93E": ("ToneGen_WriteReg0440_0480",
        "header: writes TG 0x0440+ch <- +0x10 and 0x0480+ch <- +0x12"),
    "ToneGen_ExtParams56b_DataTable": ("ToneGen_WriteReg0640",
        "header: writes TG 0x0640+ch <- shadow+0x42"),
    "ToneGen_ExtParams15_DataTable": ("ToneGen_WriteExtParams_15_Banked",
        "header: channel-banked version of ToneGen_WriteExtParams_15 (bank split at ch 0x40)"),
    "ToneGen_ConfigInit_AltData": ("ToneGen_SelfTest_ProbeVoice0",
        "header: the dormant 'is the tone generator alive?' probe that polls voice 0"),
    "VoiceStruct_BulkInit_AltData": ("CustomTone_CopyToneRecord",
        "header: copies a resolved tone record (0xEE bytes) into a custom-tone slot"),
    "VoiceSubSlot_Init_AltData": ("CustomTone_CopySubUnitRecord",
        "header: copies a sub-unit record (0xF0 bytes) into a custom-tone slot's sub-unit"),
    "VoiceParam_FullSetup_ExtData": ("Voice_Part_SetStateAndReinit",
        "header: sets the part status bits from C, then re-initialises the part by its mode"),
    "VoiceAlloc_CheckAndInit_ExtData": ("VoiceAlloc_CheckAndInit_FromRecord",
        "header: register-argument twin of VoiceAlloc_CheckAndInit, part from the record"),
    "VoiceAlloc_WithRoutingFlag_ExtData": ("VoiceAlloc_Apply_Algo_Group0",
        "header: ALGORITHM GROUP 0 APPLY; siblings are VoiceAlloc_Apply_Algo_Group1/2"),
    "VoiceChanScan_Data": ("VoiceChanScan_ReturnPUnchanged",
        "the `L = C; ret` arm: partial index p returned unpacked (RAM tones / kits)"),
    "VoiceTablePtr_Data": ("VoiceTablePtr_StdIndex28",
        "arm selecting the standard index table Root->+0x28"),
    "AlgoType_TableLookup": ("Partial_GetBaseKey",
        "header: fetch the base key number of one partial (HL = block[+1])"),
    "AlgoType_Table0": ("Partial_GetBaseKey_P0Own", "arm: p = 0, non-unison, partial 0's block"),
    "AlgoType_Table1": ("Partial_GetBaseKey_P1", "arm: p = 1 entry, tests Part_PresentWord bit 15"),
    "AlgoType_Table2": ("Partial_GetBaseKey_P1Own", "arm: p = 1, non-unison, partial 1's block"),
    "AlgoType_Table3": ("Partial_GetBaseKey_P2", "arm: p = 2, block at 0x041420"),
    "AlgoType_TableCommon": ("Partial_GetBaseKey_P3", "arm: p = 3, block at 0x041445"),
    "DSP_AlgoType_Dispatch1_TableData": ("DSP_AlgoType_Dispatch1_Arms",
        "header: NOT DATA -- the arm block of the computed jump above"),
    "DSP_AlgoType_Dispatch2_TableData": ("DSP_AlgoType_Dispatch2_Arms",
        "header: NOT DATA -- the arm block of the computed jump above"),
    "Voice_ProgChange_TableData": ("Voice_Part_ResetSlotRouting",
        "header: masks the four output slots' flag bytes, AlgoFlag writes, EFF_RoutingInit x4"),
    "RingBuf_ReadByte_Data": ("RingBuf_ReadByte_MidiRing",
        "header: `lda XWA,0x2B0D` then RINGBUF_READBYTE -- read one byte from the MIDI ring"),
    "Audio_CmdHandler_ConstData": ("RingBuf_Write4K",
        "header: stores C at payload[write index & 0x0FFF] of a 4 KB ring (its own banner's name)"),
    "DSP_FlushAllSlots_Data": ("DSP_FlushAllSlots_ForPart",
        "header: flush the DSP with the program-change bytes of part A"),
    "DSP_WriteAlgoBuffer_Data": ("DSP_WriteAlgoBuffer_Return",
        "header: the shared `pop XIZ / ret` exit of DSP_WriteAlgoBuffer"),
    "DSP_StateTable_DefaultData": ("DSP_Set_MixParam_45B2",
        "header: (0x45B2) = WA then DSP_MixerCoeff_Compute; siblings DSP_Set_MixParam_45B4/_45B6"),
    "DSP_Config_ClampData": ("DSP_Config_DeadTail_SumWords",
        "header: an unreachable tail `ld HL,(0x045566) / add HL,(0x045444) / ret`"),
    "DSP_State_LoadAndApply_InlineData": ("DSP_ParamFetch_Op61Table",
        "header: table fetch XHL = *(0x0129A3 + 4*XBC), the decoder of byte-code opcode 0x61"),
}

# 1-based line numbers (in the file BEFORE this script runs) whose COMMENT records the old name
# as history; located by content so a line-number drift is caught.
HISTORICAL = [
    "; VoiceAllocate_DataTable_02CD14, but it is live code",
    "(LLVM emits it as ToneGen_PanTable_02D0DC .byte)",
    "(LLVM: ToneGen_NoteTable_02D55E .byte)",
    "(LLVM: ToneGen_GlobalConfigTable_02D93E .byte)",
    "(LLVM: ToneGen_ExtParams56b_DataTable .byte)",
    "(LLVM: ToneGen_ExtParams15_DataTable .byte)",
    "(LLVM: ToneGen_ConfigInit_AltData .byte)",
    "source under the name VoiceStruct_BulkInit_AltData; it is ordinary code",
    "(LLVM: VoiceSubSlot_Init_AltData .byte)",
    "(LLVM: VoiceParam_FullSetup_ExtData). It is eight live routines",
    "The ELF calls it Voice_ProgChange_TableData",
    "The ELF name RingBuf_ReadByte_Data implies data",
    "(the ELF calls it DSP_FlushAllSlots_Data)",
    "This address is currently labelled DSP_StateTable_DefaultData",
    "0x036205-0x036304  DSP_StateTable_DefaultData -- NOT DATA",
    "0x036DEA-0x036DF4  DSP_Config_ClampData -- eleven bytes",
    "survives only as bytes inside the `.byte` blob ToneGen_ConfigInit_AltData",
    "Despite the \"_ExtData\" suffix this is",
]

PAT = re.compile(r"\b(" + "|".join(sorted(map(re.escape, RENAMES), key=len, reverse=True)) + r")(_\w+)?\b")


def sub(text):
    return PAT.sub(lambda m: RENAMES[m.group(1)][0] + (m.group(2) or ""), text)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--map", action="store_true")
    a = ap.parse_args()
    if a.map:
        for o, (n, _) in RENAMES.items():
            print("%s=%s" % (o, n))
        return
    hist_seen = set()
    for f in FILES:
        p = os.path.join(ROOT, f)
        L = open(p, "rb").read().decode("latin-1").split("\n")
        out, nc, ncom, nlab = [], 0, 0, 0
        for ln in L:
            code, sep, com = ln.partition(";")
            m = re.match(r"^(\w+):", code)
            if m and m.group(1) in RENAMES:
                new, why = RENAMES[m.group(1)]
                note = "; ★ Renamed 2026-09-25 from %s: %s." % (m.group(1), why)
                out.append(note.encode("utf-8").decode("latin-1"))
                nlab += 1
            c2 = sub(code)
            nc += c2 != code
            if sep:
                hist = [h for h in HISTORICAL if h in ln]
                if hist:
                    hist_seen.update(hist)
                    com2 = com
                else:
                    com2 = sub(com)
                    ncom += com2 != com
            else:
                com2 = com
            out.append(c2 + sep + com2)
        print("%s: %d code lines, %d comment lines renamed, %d labels annotated" % (f, nc, ncom, nlab))
        if a.apply:
            open(p, "wb").write("\n".join(out).encode("latin-1"))
    missing = [h for h in HISTORICAL if h not in hist_seen]
    if missing:
        sys.exit("HISTORICAL anchors not found (source drifted?): %s" % missing)


if __name__ == "__main__":
    main()
