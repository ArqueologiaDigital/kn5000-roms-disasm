#!/usr/bin/env python3
r"""scoop_popup_names.py -- the semantic record for the LCD parameter pop-up
routines and their text tables in display/scoop_display.s (v10, v9, v7).

QUESTION ANSWERED
-----------------
"What are the unnamed routines and text tables in 0xEFF719-0xF005B4 (v10)?"
Each is described below from its own instructions (read in the re-framed
source of v10; v9 is byte-identical at the same addresses; v7 holds the same
routines 0x2A bytes lower, located here by byte context).  The facts every
header rests on, common to the family:

  * `cpdi8 (0x0def), N / jrl z / ld (0x0def), N / call Display_UpdateRegion0`
    -- (0x0def) is compared with and set to a pop-up id (1, 10 or 15);
  * `call DisplayStr_ClearRegion` -- 27 spaces from 0x0ECD (the LCD text line);
  * `ld l, (0x10f1) / sla hl, 2 / ld xiy, StringData_PartNames / lda_rr ... /
    ld bc, 4 / ldir` -- a 4-character part name, index (0x10f1);
  * `ld a, (0x10f3) / call ParamDigit_ExtractAndFormat` then a copy from
    0x1181 -- the value (0x10f3) printed in decimal;
  * `call Display_UpdateRegion3` -- the line is redrawn.

This script only EMITS a spec for scripts/converters/scoop_annotate.py:

    python3 scripts/converters/scoop_popup_names.py --image v10 --out S.json
    python3 scripts/converters/scoop_annotate.py --image v10 --spec S.json
"""
import argparse
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import scoop_reframe as R  # noqa: E402

PART = "part name = StringData_PartNames[(0x10f1)*4], 4 chars"

# (v10 address, new label, positional names it replaces, header lines)
ROUTINES = [
    (0xEFF719, "Disp_ShowNoteValueFields", ["StringData_KeyNames_0x180"], [
        "Fills three fields of the LCD text line from three small tables:",
        "0x0ED9 <- 3 chars of Tbl_NoteValueNames[((0x3714) & 15) * 4],",
        "0x0EDD <- 5 chars of Tbl_NoteValuePlusNames[((0x3715) & 15) * 5],",
        "0x0EE3 <- 4 chars of Tbl_ArticulationNames[((0x3716) & 3) * 4]",
        "(\"TENU\"/\"NORM\"/\"STAC\"/\"CUTT\").  Called after (0x3714..0x3716) change",
        "(PerfMode_Evt03_ClampAndUpdate clamps (0x3716) to 0..3 then calls this)."]),
    (0xEFF837, "Disp_ShowNoteNameAndVelocity", ["StringData_KeyNames_0x29E"], [
        "9 chars at 0x0ECF: blank when (0x3717) = 0xFF, else note name",
        "Tbl_NoteNamesSharp[((0x3718) mod 12)*2] (2 chars, `divs a, 12` remainder),",
        "octave Tbl_OctaveNames[((0x3718) div 12)*2] (\"-2\"..\"8\"), 'V' at +5 and",
        "(0x3717) in decimal at +6 -- a MIDI note number and its velocity."]),
    (0xEFF8DA, "ParamPopup_PartVolume", ["StringData_KeyNames_0x341"], [
        "Pop-up id 10.  \"<part> VOLUME=nnn\": " + PART + ", Str_VolumeEq,",
        "value (0x10f3) in decimal."]),
    (0xEFF98D, "ParamPopup_PartPanpot", ["StringData_PartNames_0x54"], [
        "Pop-up id 10.  \"<part> PANPOT=nnn\": " + PART + ", Str_PanpotEq,",
        "value (0x10f3) in decimal."]),
    (0xEFF9EC, "ParamPopup_PartKeyShift", ["StringData_PartNames_0xB3"], [
        "Pop-up id 10.  \"<part> KEY SHIFT=snn\": " + PART + ", Str_KeyShiftEq,",
        "value (0x10f3) formatted by ParamDigit_CalrData with DE = 64, then the",
        "byte at 0x1180 and three digits from 0x1181."]),
    (0xEFFA59, "ParamPopup_PartTuning", ["StringData_PartNames_0x120"], [
        "Pop-up id 10.  \"<part> TUNING=snn\": " + PART + ", Str_TuningEq,",
        "value (0x10f3) formatted by ParamDigit_CalrData with DE = 128, then the",
        "byte at 0x1180 and three digits from 0x1181."]),
    (0xEFFB02, "ParamPopup_PartBendSense", ["StringData_PartNames_0x1C9"], [
        "Pop-up id 10.  \"<part> BEND SENS=nn\": " + PART + ", Str_BendSensEq,",
        "value (0x10f3), two digits (copied from 0x1182)."]),
    (0xEFFB65, "ParamPopup_PartSustain", ["StringData_PartNames_0x22C"], [
        "Pop-up id 1.  \"<part> SUSTAIN ON /OFF \": " + PART + ", Str_Sustain,",
        "then Str_OnOffPair + 0 when bit 3 of (0x10f3) is set, + 4 when clear."]),
    (0xEFFBD0, "ParamPopup_PartDspEffectOff", ["StringData_PartNames_0x297"], [
        "Pop-up id 1.  \"<part> DSP EFFECT OFF \": " + PART + ", Str_DspEffect,",
        "then Str_OnOffPair + 4 unconditionally (`ld l, 4`)."]),
    (0xEFFC2F, "ParamPopup_PartEffect", ["StringData_PartNames_0x2F6"], [
        "Pop-up id 1.  \"<part> EFFECT ON /OFF \": " + PART + ", StringData_EffectLabel,",
        "then Str_OnOffPair + 0 when bit 6 of (0x10f3) is set, + 4 when clear."]),
    (0xEFFC90, "ParamPopup_PartDspEffectLevel", ["StringData_EffectLabel_0x7"], [
        "Pop-up id 1.  \"<part> DSP EFFECT=nnn\": " + PART + ", Str_DspEffectEq,",
        "value (0x10f3) in decimal."]),
    (0xEFFCF0, "ParamPopup_PartReverb", ["StringData_EffectLabel_0x67"], [
        "Pop-up id 1.  \"<part> REVERB=nnn\": " + PART + ", Str_ReverbEq,",
        "value (0x10f3) in decimal."]),
    (0xEFFD4B, "ParamPopup_PanelMemory", ["StringData_EffectLabel_0xC2"], [
        "Pop-up id 1.  \"PANEL MEMORY=b-n\" from A on entry: A-1 divided by 8",
        "gives bank = quotient+1 -> (0x11f2) and number = remainder+1 -> (0x11f3),",
        "each printed in decimal with '-' (45) between them."]),
    (0xEFFDC1, "ParamPopup_FadeIn", ["StringData_EffectLabel_0x138"], [
        "Pop-up id 1.  Str_FadeIn then Str_On or Str_Off (3 chars) chosen from",
        "A on entry (0 / 1)."]),
    (0xEFFE16, "ParamPopup_FadeOut", ["StringData_EffectLabel_0x18D"], [
        "Pop-up id 1.  Str_FadeOut then Str_On or Str_Off (3 chars) chosen from",
        "A on entry (0 / 1)."]),
    (0xEFFE66, "ParamPopup_ApcMode", ["StringData_EffectLabel_0x1DD"], [
        "Pop-up id 1.  16 chars of StringData_APCModeNames[(W and A) * 16] at 0x0ECF."]),
    (0xEFFF31, "ParamPopup_ApcMemory", ["StringData_APCModeNames_0x90"], [
        "Pop-up id 1.  Str_ApcMemoryOn (14 chars at 0x0ECF); Str_OffAccomp",
        "(\"OFF\") over the \"ON \" at 0x0EDA when (A and W) = 0."]),
    (0xEFFF88, "ParamPopup_AccompPart", ["StringData_APCModeNames_0xE7"], [
        "Pop-up id 1.  A and W are reduced to their bits 7-5 (`and 224 / srl 5`);",
        "16 bytes of Tbl_AccompPartNames + A*16 go to 0x0ECF, and \"OFF\" to",
        "0x0EDC when (A and W) = 0."]),
    (0xF00019, "ParamPopup_DynamicAccomp", ["StringData_APCModeNames_0x178"], [
        "Pop-up id 1.  Str_DynamicAccompOn (17 chars); \"OFF\" at 0x0EDE when",
        "(W and A) = 0."]),
    (0xF0006B, "ParamPopup_TechniChord", ["StringData_APCModeNames_0x1CA"], [
        "Pop-up id 1.  Str_TechniChordOn (16 chars); \"OFF\" at 0x0EDC when",
        "(W and A) = 0."]),
    (0xF000BC, "ParamPopup_KeyNameBracketed", ["StringData_APCModeNames_0x21B"], [
        "Pop-up id 1.  ' ' at 0x0ECE, then 4 chars of Tbl_KeyNamesBracketed",
        "[((0x10f3) & 15) * 4] (\"<G >\", \"<Ab>\" ...), read as two words."]),
    (0xF0014D, "ParamPopup_AccompVolume", ["StringData_APCModeNames_0x2AC"], [
        "Pop-up id 1.  16 chars of Tbl_AccompVolumeLabels[HL * 16] (HL on entry",
        "selects ACC. TOTAL / BASS / DRUMS / ACCMP1..3); then, when bit 7 of",
        "(0x10f5) is set, 8 chars of Tbl_MuteOnOff (+0 \"MUTE ON \", +8 when bit 7",
        "of (0x10f3) is clear), else A (on entry) in decimal at 0x0EDF."]),
    (0xF00236, "ParamPopup_PartTremolo", ["StringData_APCModeNames_0x395"], [
        "Pop-up id 1.  \"<part> TREMOLO ON/OFF\": " + PART + ", Str_Tremolo,",
        "then 3 chars of Str_OnOffPair + 0 (bit 7 of (0x10f3) set) or + 4."]),
    (0xF002B5, "ParamPopup_TotalReverb", ["StringData_APCModeNames_0x414"], [
        "Pop-up id 1.  Str_TotalReverb (13 chars at 0x0ED1), then 4 chars of",
        "Str_OnOffPair + 0 (bit 7 of (0x10f3) set) or + 4."]),
    (0xF00305, "ParamPopup_PartTimbre", ["StringData_APCModeNames_0x464"], [
        "Pop-up id 1.  " + PART + " at 0x0ED1, then 6 chars of",
        "Tbl_TimbreNames[((0x10f3) >> 6) * 6] (NORMAL/BRIGHT/MELLOW/WARM)."]),
    (0xF00379, "ParamPopup_Msa", ["StringData_APCModeNames_0x4D8"], [
        "Pop-up id 15 when (0x0d65) = 3, else 1.  Str_Msa (7 chars at 0x0ED1),",
        "then 4 chars of Tbl_MsaStates[((0x10f3) & 7) * 4] (OFF/ON/#2/#3)."]),
    (0xF00505, "ParamPopup_PartPedal", ["StringData_APCModeNames_0x664"], [
        "Pop-up id 1.  Part name of (0x10f2) at 0x0ED1, then 10 chars of",
        "Tbl_PedalNames[((0x10f1) - 181) * 10] (SUSTAIN/SOFT PEDAL/SOSTENUTE);",
        "the value (0x10f3) in decimal when (0x10f1) = 181."]),
]

# (v10 address, new label or None, positional names, header lines, record width)
TABLES = [
    (0xEFF599, None, [], [
        "StringData_KeyNames: key-root names, 16 x 2 chars, read by SNS_LoadKeyAndChord (0xEFF526):",
        "`ld l, (0x0d6d) / and l, 15 / sla hl, 1` then 2 bytes to (xix).  Entry 0",
        "and 13-15 blank; 1-12 the chromatic scale C, D-flat, D, E-flat, E, F,",
        "F-sharp, G, A-flat, A, B-flat, B with LCD glyph 0x88 = flat and",
        "0x8C = sharp (the same spellings as Tbl_KeyNamesBracketed's \"Db\"/\"F#\")."], 2),
    (0xEFF5B9, "Tbl_ChordTypeNames", ["StringData_KeyNames_0x20"], [
        "64 x 5 chars, read by SNS_LoadKeyAndChord (0xEFF526): `ld l, (0x0d6e) /",
        "and l, 0x3f / ld a, 5 / muls a, l` then 5 bytes to (xix+2).  Chord-type",
        "names (\"7\", \"Maj7\", \"aug\", \"min\", \"m7b5\" ...); 0x88 = flat, 0x8C = sharp."], 5),
    (0xEFF6F9, "Tbl_NoteValueGlyphs", ["StringData_KeyNames_0x160"], [
        "8 x 4 chars, read by SNS_LoadDurationData (0xEFF56D): `ld l, (0x0d61) /",
        "sla hl, 2` then 4 bytes to 0x0EDD.  LCD note glyphs 0x13-0x16, '.' after",
        "a glyph for the dotted value, \"XX\" in the last entry."], 4),
    (0xEFF797, "Tbl_NoteValueNames", ["StringData_KeyNames_0x1FE"], [
        "16 x 4 chars, read by Disp_ShowNoteValueFields (0xEFF719): `ld l,",
        "(0x3714) / and l, 15 / sla hl, 2`, 3 bytes copied to 0x0ED9.  Note glyphs",
        "0x13-0x18 with 0x1F / 0x8B markers after some (tuplet-style values)."], 4),
    (0xEFF7D7, "Tbl_NoteValuePlusNames", ["StringData_KeyNames_0x23E"], [
        "16 x 5 chars, read by Disp_ShowNoteValueFields (0xEFF719): `ld l,",
        "(0x3715) / and l, 15 / ld a, 5 / muls a, l`, 5 bytes to 0x0EDD.  The",
        "Tbl_NoteValueNames values with a \"+\" in front."], 5),
    (0xEFF827, "Tbl_ArticulationNames", ["StringData_PartModeNames"], [
        "4 x 4 chars \"TENU\" \"NORM\" \"STAC\" \"CUTT\", read by Disp_ShowNoteValueFields",
        "(0xEFF719): `ld l, (0x3716) / and l, 3 / sla hl, 2`, 4 bytes to 0x0EE3."], 4),
    (0xEFF8AC, "Tbl_NoteNamesSharp", ["StringData_KeyNames_0x313"], [
        "12 x 2 chars \" C\" \"C#\" \" D\" ... \" B\" (0x8C = sharp), read by",
        "Disp_ShowNoteNameAndVelocity (0xEFF837): index = (0x3718) mod 12,",
        "`sla bc, 1`, 2 bytes to 0x0ECF."], 2),
    (0xEFF8C4, "Tbl_OctaveNames", ["StringData_KeyNames_0x32B"], [
        "11 x 2 chars \"-2\" \"-1\" \"0 \" .. \"8 \", read by Disp_ShowNoteNameAndVelocity",
        "(0xEFF837): index = (0x3718) div 12, `sla bc, 1`, 2 bytes to 0x0ED1."], 2),
    (0xEFF932, "Str_VolumeEq", ["StringData_KeyNames_0x399"], [
        "\"VOLUME=\", 7 chars copied by ParamPopup_PartVolume (0xEFF8DA)."], 7),
    (0xEFF939, None, [], [
        "StringData_PartNames: 21 x 4 chars (RT1 RT2 LFT P 4 .. P15 KBP AC1 AC2 AC3 XXXX",
        "DRUM), read by every ParamPopup_Part* routine: `ld l, (0x10f1) / sla hl,",
        "2 / ld xiy, StringData_PartNames / lda_rr xiy, xiy, hl / ld bc, 4 / ldir`."], 4),
    (0xEFF9E5, "Str_PanpotEq", ["StringData_PartNames_0xAC"], [
        "\"PANPOT=\", 7 chars copied by ParamPopup_PartPanpot (0xEFF98D)."], 7),
    (0xEFFA4F, "Str_KeyShiftEq", ["StringData_PartNames_0x116"], [
        "\"KEY SHIFT=\", 10 chars copied by ParamPopup_PartKeyShift (0xEFF9EC)."], 10),
    (0xEFFABB, "Str_TuningEq", ["StringData_PartNames_0x182"], [
        "\"TUNING=\", 7 chars copied by ParamPopup_PartTuning (0xEFFA59).  The 64",
        "bytes after it (US1 US2 US3 BAS P 8 ..) are 4-char part names of a",
        "second naming scheme with no reader found by name or 32-bit value."], 7),
    (0xEFFB5B, "Str_BendSensEq", ["StringData_PartNames_0x222"], [
        "\"BEND SENS=\", 10 chars copied by ParamPopup_PartBendSense (0xEFFB02)."], 10),
    (0xEFFBC0, "Str_Sustain", ["StringData_PartNames_0x287"], [
        "\"SUSTAIN \", 8 chars copied by ParamPopup_PartSustain (0xEFFB65)."], 8),
    (0xEFFBC8, "Str_OnOffPair", ["StringData_PartNames_0x28F"], [
        "2 x 4 chars \"ON  \" / \"OFF \": +0 or +4 selected by a flag bit and 3 or 4",
        "bytes copied, by ParamPopup_PartSustain/Effect/Tremolo/TotalReverb,",
        "ParamPopup_PartDspEffectOff and Display_BytecodeBlock_F (0xEFF144)."], 4),
    (0xEFFC24, "Str_DspEffect", ["StringData_PartNames_0x2EB"], [
        "\"DSP EFFECT \", 11 chars copied by ParamPopup_PartDspEffectOff (0xEFFBD0)."], 11),
    (0xEFFC89, None, [], [
        "StringData_EffectLabel: \"EFFECT \", 7 chars copied by",
        "ParamPopup_PartEffect (0xEFFC2F)."], 7),
    (0xEFFCE5, "Str_DspEffectEq", ["StringData_EffectLabel_0x5C"], [
        "\"DSP EFFECT=\", 11 chars copied by ParamPopup_PartDspEffectLevel (0xEFFC90)."], 11),
    (0xEFFD44, "Str_ReverbEq", ["StringData_EffectLabel_0xBB"], [
        "\"REVERB=\", 7 chars copied by ParamPopup_PartReverb (0xEFFCF0)."], 7),
    (0xEFFDB4, "Str_PanelMemoryEq", ["StringData_EffectLabel_0x12B"], [
        "\"PANEL MEMORY=\", 13 chars copied by ParamPopup_PanelMemory (0xEFFD4B)."], 13),
    (0xEFFE08, "Str_FadeIn", ["StringData_EffectLabel_0x17F"], [
        "\"FADE-IN \", 8 chars copied by ParamPopup_FadeIn (0xEFFDC1)."], 8),
    (0xEFFE10, "Str_On", ["StringData_EffectLabel_0x187"], [
        "\"ON \", 3 chars copied by ParamPopup_FadeIn and ParamPopup_FadeOut."], 3),
    (0xEFFE13, "Str_Off", ["StringData_EffectLabel_0x18A"], [
        "\"OFF\", 3 chars copied by ParamPopup_FadeIn and ParamPopup_FadeOut."], 3),
    (0xEFFE5D, "Str_FadeOut", ["StringData_EffectLabel_0x1D4"], [
        "\"FADE-OUT \", 9 chars copied by ParamPopup_FadeOut (0xEFFE16)."], 9),
    (0xEFFEA1, None, [], [
        "StringData_APCModeNames: APC mode names, 9 x 16 chars (APC OFF,",
        "BASIC, ADVANCED 1, PIANIST, PIANO MODE, ADVANCED 2, -, -, SPLIT), read",
        "by ParamPopup_ApcMode (0xEFFE66): `sla hl, 4 / lda_rr / ld bc, 16 / ldir`."], 16),
    (0xEFFF7A, "Str_ApcMemoryOn", ["StringData_APCModeNames_0xD9"], [
        "\"APC MEMORY ON \", 14 chars copied by ParamPopup_ApcMemory (0xEFFF31)."], 14),
    (0xEFFFE2, "Tbl_AccompPartNames", ["StringData_APCModeNames_0x141"], [
        "52 bytes read by ParamPopup_AccompPart (0xEFFF88): 16 bytes at +k*16,",
        "k = bits 7-5 of A (`sla hl, 4 / lda_rr / ld bc, 16 / ldir` to 0x0ECF).",
        "Content: 0x09 0x09 \"ACCOMP PART1 ON \", \"ACCOMP PART2 ON \", 0x09 0x09",
        "\"ACCOMP PART3 ON \" -- the visible strings do NOT fall on the reader's",
        "16-byte boundaries, and the role of the 0x09 bytes is not established.",
        "The values 0xF00001-0xF00004 (inside this text) are also loaded as",
        "StringData_APCModeNames_0x160..0x163 by ui/drawbar_panel_ui.s's Softver",
        "screen and handed to SendEvent -- more likely numeric event arguments",
        "than pointers here (not verified)."], 16),
    (0xF00016, "Str_OffAccomp", ["StringData_APCModeNames_0x175"], [
        "\"OFF\", 3 chars copied over the \"ON \" of the ACCOMP/APC MEMORY/DYNAMIC",
        "ACCOMP/TECHNI-CHORD pop-ups when their flag is clear."], 3),
    (0xF00059, "Str_DynamicAccompOn", ["StringData_APCModeNames_0x1B8"], [
        "\"DYNAMIC ACCOMP ON \", 17 chars copied by ParamPopup_DynamicAccomp (0xF00019)."], 18),
    (0xF000AB, "Str_TechniChordOn", ["StringData_APCModeNames_0x20A"], [
        "\"TECHNI-CHORD ON \", 16 chars copied by ParamPopup_TechniChord (0xF0006B)."], 16),
    (0xF0010D, "Tbl_KeyNamesBracketed", ["StringData_APCModeNames_0x26C"], [
        "16 x 4 chars \"<G >\" \"<Ab>\" .. \"<F#>\" then 4 blank entries, read by",
        "ParamPopup_KeyNameBracketed (0xF000BC): `ld l, (0x10f3) / and l, 15 /",
        "sla hl, 2 / ld_rrw wa, xiy, hl` twice."], 4),
    (0xF001C5, "Tbl_AccompVolumeLabels", ["StringData_APCModeNames_0x324"], [
        "6 x 16 chars (ACC. TOTAL VOL.= / BASS / DRUMS / ACCMP1 / ACCMP2 / ACCMP3",
        "VOLUME =), read by ParamPopup_AccompVolume (0xF0014D): `sla hl, 4 /",
        "lda_rr / ld bc, 16 / ldir`."], 16),
    (0xF00225, "Tbl_MuteOnOff", ["StringData_APCModeNames_0x384"], [
        "2 x 8 chars \"MUTE ON \" / \"MUTE OFF\", read by ParamPopup_AccompVolume",
        "(0xF0014D): +8 when bit 7 of (0x10f3) is clear, 8 bytes copied."], 8),
    (0xF00291, "Str_Tremolo", ["StringData_APCModeNames_0x3F0"], [
        "\"TREMOLO \", 8 chars copied by ParamPopup_PartTremolo (0xF00236)."], 8),
    (0xF0029D, "Str_ExtTabEffectEnDis", [], [
        "\"EXT.TAB EFFECT:\" + \"EN  \" + \"DIS \" (23 bytes).  No reader found: no",
        "name at this address and no 24/32-bit value 0xF0029D anywhere in the",
        "ROM; the text sits where the three `ret` stubs 0xF00299-0xF0029C end."], 23),
    (0xF002F7, "Str_TotalReverb", ["StringData_APCModeNames_0x456"], [
        "\"TOTAL REVERB \", 13 chars copied by ParamPopup_TotalReverb (0xF002B5)."], 13),
    (0xF00361, "Tbl_TimbreNames", ["StringData_APCModeNames_0x4C0"], [
        "4 x 6 chars NORMAL / BRIGHT / MELLOW / WARM, read by ParamPopup_PartTimbre",
        "(0xF00305): index ((0x10f3) >> 6) times 6 (`sla h,1 / sla l,2 / add l,h`)."], 6),
    (0xF003D8, "Str_Msa", ["StringData_APCModeNames_0x537"], [
        "\"M.S.A. \", 7 chars copied by ParamPopup_Msa (0xF00379)."], 7),
    (0xF003DF, "Tbl_MsaStates", ["StringData_APCModeNames_0x53E"], [
        "4 x 4 chars OFF / ON / #2 / #3, read by ParamPopup_Msa (0xF00379):",
        "`ld l, (0x10f3) / and l, 7 / sla hl, 2`, 4 bytes copied."], 4),
    (0xF00596, "Tbl_PedalNames", ["StringData_APCModeNames_0x6F5"], [
        "3 x 10 chars \" SUSTAIN  \" / \"SOFT PEDAL\" / \"SOSTENUTE \", read by",
        "ParamPopup_PartPedal (0xF00505): index ((0x10f1) - 181) times 10."], 10),
]


def locate(img, v10addr, rb10, rb, hint=None):
    """v10 address -> the same byte context in `img` (identity for v9).
    A context found more than once is resolved by `hint` (the displacement of
    the neighbours already located), within 0x100 of it."""
    if img in ("v10", "v9"):
        return v10addr
    B = R.BASE
    multi = []
    for pre, post in ((8, 8), (12, 12), (4, 12), (16, 16), (6, 20), (16, 0), (0, 16)):
        key = rb10[v10addr - B - pre:v10addr - B + post]
        hits = [m.start() + pre + B for m in re.finditer(re.escape(key), rb)]
        if len(hits) == 1:
            return hits[0]
        multi += hits
    if hint is not None and multi:
        best = min(multi, key=lambda h: abs(h - (v10addr + hint)))
        if abs(best - (v10addr + hint)) <= 0x100:
            return best
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    img = a.image
    rel = "%s/maincpu/display/scoop_display.s" % img
    rb10, rb = R.rom("v10"), R.rom(img)
    spec = []
    located = {}
    for addr in [x[0] for x in ROUTINES] + [x[0] for x in TABLES]:
        located[addr] = locate(img, addr, rb10, rb)
    for addr in located:
        if located[addr] is None:
            near = sorted((abs(k - addr), v - k) for k, v in located.items() if v is not None)
            located[addr] = locate(img, addr, rb10, rb, hint=near[0][1] if near else None)
            if located[addr] is None:
                raise SystemExit("no %s context for v10 0x%06X" % (img, addr))
    # RAM variables that moved between versions, learned by aligning each
    # routine's unidasm stream with v10's (same mnemonics, different operand)
    ram = {}
    rommap = {}
    if img not in ("v10", "v9"):
        for addr in [x[0] for x in ROUTINES] + [0xEFF526, 0xEFF56D]:
            other = located.get(addr) or locate(img, addr, rb10, rb, hint=-0x2A) or addr - 0x2A
            ua, ub = R.unidasm("v10", addr, 160), R.unidasm(img, other, 160)
            for (_, _, ta), (_, _, tb) in zip(ua, ub):
                if ta.split()[0] != tb.split()[0]:
                    break
                for p, q in zip(re.findall(r'0x([0-9a-f]+)', ta), re.findall(r'0x([0-9a-f]+)', tb)):
                    if p != q and int(p, 16) < 0x10000:
                        ram[int(p, 16)] = int(q, 16)

    def port(line):
        if img in ("v10", "v9"):
            return line

        def sub(m):
            v = int(m.group(0), 16)
            if v >= 0xE00000:
                if v not in rommap:
                    rommap[v] = locate(img, v, rb10, rb, hint=-0x2A)
                    if rommap[v] is None:
                        # same instruction shapes 0x2A lower (this area's v7 shift)?
                        ma = [t.split()[0] for _, _, t in R.unidasm("v10", v, 24)][:5]
                        mb = [t.split()[0] for _, _, t in R.unidasm(img, v - 0x2A, 24)][:5]
                        rommap[v] = v - 0x2A if ma == mb else None
                return "0x%06X" % rommap[v] if rommap[v] else m.group(0)
            if v in ram:
                return ("0x%04x" if m.group(0).islower() or m.group(0)[2:].islower() else "0x%04X") % ram[v]
            return m.group(0)
        return re.sub(r'0x[0-9A-Fa-f]{4,6}', sub, line)

    for addr, name, old, hdr in ROUTINES:
        ad = located[addr]
        hdr = [port(x) for x in hdr]
        spec.append({"file": rel, "addr": "0x%06X" % ad, "label": name,
                     "comment": [name + " -- LCD parameter pop-up." if name.startswith("ParamPopup")
                                 else name] + hdr,
                     "rename": {o: name for o in old}})
    for addr, name, old, hdr, rec in TABLES:
        ad = located[addr]
        hdr = [port(x) for x in hdr]
        e = {"file": rel, "addr": "0x%06X" % ad, "comment": hdr}
        if name:
            e["label"] = name
            e["rename"] = {o: name for o in old}
        spec.append(e)
    json.dump(spec, open(a.out, "w"), indent=1)
    print("%d entries -> %s" % (len(spec), a.out))


if __name__ == "__main__":
    main()
