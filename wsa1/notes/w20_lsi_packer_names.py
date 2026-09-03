#!/usr/bin/env python3
"""Apply lane w20/lsi-packers' names and documentation to prom_c/field_accessors.s.

QUESTION THIS ANSWERS
    Wave 19 established what each of the L7A1429's nineteen per-channel
    registers is built from and what the tone editor calls it.  This script is
    the mechanical half of carrying that back into the code: it renames the
    `sub_XXXXXX` routines that BUILD those values, and it inserts one evidence
    block per renamed routine into that routine's existing header.

    It exists so that a reader can check the pass rather than trust it: the map
    is a separate file, the substitution is whole-word, and the prose is here in
    one place instead of scattered across a 10,500-line diff.

WHAT IT DOES NOT DO
    It never touches an existing comment.  `--document` inserts a new block
    immediately before the closing rule of a routine's header; `--rename` only
    substitutes whole-word label names.  Both are checked by

        python3 scripts/analysis/assert_comments_preserved.py --base main \
            --rename-map wsa1/notes/w20-lsi-packer-renames.map \
            wsa1/prom_c/field_accessors.s

    and the bytes by `make gate-all`.

⚠ ENCODING TRAP.  The sources are UTF-8 but this tree reads them as latin-1 in
    places.  Everything here is done on BYTES -- read_bytes / write_bytes -- so a
    star or a warning sign can never truncate the file to zero on an encode
    error.

RUN (from the wsa1/ directory)
    python3 notes/w20_lsi_packer_names.py --rename
    python3 notes/w20_lsi_packer_names.py --document
    python3 notes/w20_lsi_packer_names.py --check      # both applied, nothing left
"""
import argparse
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
TARGET = HERE.parent / "prom_c" / "field_accessors.s"
MAPFILE = HERE / "w20-lsi-packer-renames.map"

RULE = b"; --------------------------------------------------------------------------\n"


def load_map():
    pairs = []
    for line in MAPFILE.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        old, new = line.split("=", 1)
        pairs.append((old, new))
    return pairs


def do_rename():
    raw = TARGET.read_bytes()
    # longest first: `sub_FC49AD` is a prefix of `sub_FC49AD__FC49D7`, and the
    # short match must not corrupt the long one.  Whole-word only.
    for old, new in sorted(load_map(), key=lambda p: -len(p[0])):
        # `\b` will not fire before `__`, so allow a derived `Name__FCxxxx`
        # label to be renamed too -- and NOTHING else.
        pat = re.compile(rb"\b" + old.encode() + rb"(?=__|[^0-9A-Za-z_]|$)")
        raw, n = pat.subn(new.encode(), raw)
        print(f"  {old:12s} -> {new:44s} {n:4d} occurrence(s)")
    TARGET.write_bytes(raw)


# ---------------------------------------------------------------------------
# The documentation.  One block per renamed routine, keyed by the NEW name.
# Every hex address in the prose is an instruction operand of the routine it
# appears in, or of the routine named beside it.
# ---------------------------------------------------------------------------
STAR = "★"
WARN = "⚠"

DOCS = {

"Slot64Pool_MoveToList": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 Slot64Pool_MoveToList -- moves one node of the 64-entry
          pool at 0x005B63 onto list `(XIZ+0x0a)`, unlinking it from the list it
          is on.  The pool is 64 entries of 7 bytes -- 0x005B63 + 7*i, and
          64*7 = 448 ends at 0x005D22, the byte before the part-record array at
          0x005D23 (Pack104_SetInputs_PartRecord's own base).  Entry layout,
          from the operands here and in Slot64Pool_InitAllFree:
            +0x00 next (2)   +0x02 prev (2)   +0x04 list id (1)
            +0x05 the entry's own index 0..63 (1)   +0x06 a use count (1)
          The two list heads are the words at 0x00E00E (list 0) and 0x00E010
          (list 1), indexed as `head[listid]` by `mul C,0x02 / add XBC,0x0000e00e`
          at 0xFC3FBD and 0xFC3FC4.  New nodes are spliced in at the head.
 WHY IT IS ON THE 0x00104000 PATH: the index this pool hands out
          (Slot64Pool_AcquireOrAddRef) is stored to R[+0x07] at 0xFC4D27 and
          0xFC7DE9, and Dev104_PackStagingStruct builds staging word 0 --
          register chan+0x0000 -- as `(R[+0x07] << 8) | P[+0x07]` at
          0xFC4DE3-0xFC4DF1.  So this pool's index IS bits 15:8 of that register.
 GRADE: PROVEN for the data structure and for where the index lands.
""",

"Slot64Pool_AcquireOrAddRef": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 Slot64Pool_AcquireOrAddRef -- returns an index 0..63 out
          of the 0x005B63 pool.  Two arms, on the argument:
            arg < 0x40   0xFC4064   take THAT entry and bump its use count
                                    (`inc 1,(XHL+0x06)`, 0xFC4078)
            arg >= 0x40  0xFC407D   take the head of list 1, or of list 0 when
                                    list 1 is empty (0xFC4087-0xFC408D), move it
                                    to list 1 and set its use count to 1
          The return value is the entry's own index byte +0x05 (0xFC409F).
          Callers pass 0x00FF for "give me a fresh one" (0xFC4D1B, 0xFC7DDD).
 WHERE IT REACHES THE DEVICE: see Slot64Pool_MoveToList -- the result is
          R[+0x07] and thence bits 15:8 of register chan+0x0000.
 {STAR}{STAR} THIS DECODES ONE OF THE TWO SITES notes/HLE-GUIDE-l7a1429.md section 8.5
          lists as the undecoded writers of register 0x0000.  Both of them --
          0xFC4D27 in Pack104_SetInputs_SubRecordPair and 0xFC7DE9 in
          Pack104_StageReg_0000_ForVoice -- store THIS routine's return value.
          The guide reports bits 13:8 as "the CHANNEL on the power-on path"; a
          64-entry allocator handing an index into exactly those bits on the note
          path is the same field, allocated.  Grade STRONG for "these are the
          device's 64 channels", PROVEN for "a 0..63 index from a 64-entry pool".
 {WARN} REPORTED, NOT EDITED: notes/FINDINGS-l7a1429-parameter-names.md section 6
          and the guide's section 8.5 say those two sites write `P[+0x07]` bits
          6:4.  They write `R[+0x07]` -- the base is `lda XIX,0x00e086` at
          0xFC4C8C / 0xFC7DB6, i.e. the 37-byte record, not the 42-byte
          sub-record.  So the producer of P[+0x07] bits 6:4 is still unlocated.
""",

"Slot64Pool_Release": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 Slot64Pool_Release -- drops one reference to pool entry
          `(XIZ+0x08)`.  Use count 1 (0xFC40C1) means last user: the entry goes
          back to list 0 and its count to 0 (0xFC40C5-0xFC40CC).  A count above 1
          is merely decremented (0xFC40D9).  A count of 0 is a no-op.
          Called from 0xFC4CF0 (Pack104_SetInputs_SubRecordPair, releasing the
          slot the voice held) and 0xFC7DD9 (Pack104_StageReg_0000_ForVoice).
 GRADE: PROVEN for the arithmetic; for what the slot IS see
          Slot64Pool_AcquireOrAddRef.
""",

"Slot64Pool_InitAllFree": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 Slot64Pool_InitAllFree -- builds the 0x005B63 pool: both
          list heads cleared (0xFC40EA, 0xFC40F1), then 64 entries of 7 bytes
          stamped with their own index (`ld (XDE+0x05),H`, 0xFC40FD; `inc 7,DE`
          and `cp H,0x40` at 0xFC410D-0xFC4114), then all 64 pushed onto list 0
          (0xFC411B-0xFC4129).
          {STAR} 64 entries is the count, and 64 is the L7A1429's channel count
          (notes/FINDINGS-l7a1429-write-sequencing.md section 1).
 GRADE: PROVEN for the structure; STRONG for "these are the device's channels".
""",

"Pack104_ComputeTuningWords_0040_0080": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 Pack104_ComputeTuningWords_0040_0080 -- builds the two
          tuning words registers chan+0x0040 (MAIN RESONATOR) and chan+0x0080
          (SUB RESONATOR) are made from.  P is the 42-byte sub-record
          *(0x00E084), PART the 187-byte part record *(0x00E082).
            mode = bits 7:6 of P[+0x02]                    0xFC46B2-0xFC46B8
            mode 1:  P[+0x0A] = sat(PART[+0x0D] + P[+0x0E])
                     P[+0x0C] = sat(PART[+0x0D] + P[+0x10])
            mode 2:  the same with PART[+0x0D] negated     0xFC474E, 0xFC4794
            other:   P[+0x0A] = P[+0x0E], P[+0x0C] = P[+0x10]        0xFC47D0
          `sat` is the packer's asymmetric saturate: positive overflow -> 0x7FFF
          (0xFC46ED), negative overflow -> 0x0000 (0xFC46FC).
 WHERE THE VALUES GO: Dev104_PackStagingStruct reads P[+0x0A] at 0xFC4DFD into
          staging word 1 (struct+0x02 = register chan+0x0040) and P[+0x0C] at
          0xFC4EAC into word 2 (struct+0x04 = chan+0x0080).  That is the first
          term of notes/HLE-GUIDE-l7a1429.md section 5's
          `SatAsym(P[+0x0A] + P[+0x12] + d1)`.
 UNITS: P[+0x0E]/P[+0x10] are KEY SHIFT + TUNE in 1/256 semitone
          (Pack104_UnpackWaveSelRec_ToSubRecord); PART[+0x0D] is written
          `value << 8` by PartRec_SetTuningOffset_000D at 0xFC6572, so the
          part-level offset is in whole semitones.
 GRADE: PROVEN for the arithmetic and for which staging words it feeds.  STRONG
          for the names MAIN/SUB RESONATOR, KEY SHIFT and TUNE, which come from
          notes/FINDINGS-l7a1429-parameter-names.md section 4 and carry that
          note's two points of failure (its section 5b).
""",

"Pack104_UnpackWaveSelRec_ToSubRecord": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 Pack104_UnpackWaveSelRec_ToSubRecord -- reads the
          43-byte WAVE-SELECT RECORD passed in (XIZ+0x08) and expands its
          modelling tail into the fields of the 42-byte sub-record P
          (*(0x00E084)) that Dev104_PackStagingStruct then consumes.  `pN` below
          is arm-4 tone-edit parameter N = wave-select byte +0x0N
          (notes/FINDINGS-l7a1429-parameter-names.md section 2b, PROVEN):
            P[+0x0E] = (s8)p29 * 256 + (s8)p30 * 2   0xFC480B, 0xFC4828
            P[+0x10] = (s8)p41 * 256 + (s8)p42 * 2   0xFC483C, 0xFC4859
                       MAIN / SUB `KEY SHIFT` + `TUNE`, 1/256 semitone; the *2
                       makes a TUNE step 2/256 semitone = 0.78 cent
            P[+0x07] &= 0x0070                        0xFC4865  (bits 6:4 kept)
            p21 bit 7 -> set bit 15 of P[+0x07] and P[+0x0E] += 0x0C00  0xFC488B
            p31 bit 7 -> set bit 14 of P[+0x07] and P[+0x10] += 0x0C00  0xFC48BD
            p33 < 0   -> set bit 7 of P[+0x07]                          0xFC48EE
            p25 bit 7 -> P[+0x12] = (p26 << 8) + p27  0xFC490A, 0xFC4926
            p37 bit 7 -> P[+0x14] = (p38 << 8) + p39  0xFC4942, 0xFC495E
                       these are the second term of registers 0x0040 / 0x0080
            i5 = clamp(p15, 44..96)                   0xFC496B-0xFC497C
            P[+0x26] = Curve_Muting_Cutoff_Q16_128[i5]   0xFC4987, 0xFC4993
            P[+0x24] = Curve_Muting_Cutoff_Q13_128[i5]   0xFC4996, 0xFC49A4
 WHERE THE VALUES GO: the packer copies P[+0x26] to R[+0x1A] (0xFC5675-0xFC567F)
          and thence to staging word 18 = register chan+0x0480 (0xFC568F), and
          P[+0x24] straight to word 15 = chan+0x03C0 (0xFC56BA).  Those are the
          THIRD instance of the MUTING curve pair that
          notes/HLE-GUIDE-l7a1429.md section 2.3 proves exists; this routine is
          where its index `i5` is formed and cached.
 GRADE: PROVEN for every line above -- all operands.  The parameter NAMES are
          STRONG (parameter-names note section 4); `FORMANT` for the i5 section
          stays WEAK there and is not asserted here.
""",

"Pack104_StageRegs_00C0_0100_0240": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 Pack104_StageRegs_00C0_0100_0240 -- fills the three
          staging words its counterpart Dev104_SetChanRegs_00C0_0100_0240 ships,
          into the struct passed in (XIZ+0x08).  R is the 37-byte record
          *(0x00E086).  This routine IS notes/HLE-GUIDE-l7a1429.md section 5's
          value expression for registers 0x00C0, 0x0100 and 0x0240:
            i = clamp(R[+0x12] + R[+0x16] + R[+0x21], 0..250)   0xFC49CC-0xFC49DB
            struct+0x06 (word 3, reg chan+0x00C0) =
                Curve_Position_Log2Period_251[i]               0xFC49E5
              + (0x4280 - R[+0x0E])   unless bit 7 of *(R+1)[+0x0E]   0xFC4A18
              - R[+0x0C]                                       0xFC4A29
              forced to 0x0000 / 0x7F00 on underflow           0xFC4A37/0xFC4A3C
            struct+0x08 (word 4, reg chan+0x0100) =
                Dev104_Reg0100_Const_251[the SAME index i]     0xFC49ED-0xFC49F9
            struct+0x12 (word 9, reg chan+0x0240) =
                high16( fold(R[+0x1A])
                      * Curve_Fitting_Exp2Rise_128[
                            clamp(R[+0x14] + R[+0x18] + |R[+0x21]|/4, 0..0x7F)] )
                then `& 0xFFF8 | 7`                            0xFC4AD9-0xFC4ADD
              `fold` is the sign-magnitude -> offset-binary step at
              0xFC4A51-0xFC4A72, and R[+0x1A] is the word register chan+0x0480
              carries (see Pack104_UnpackWaveSelRec_ToSubRecord).
              {WARN} `srl 0x00,XIY` at 0xFC4ACC is a shift by SIXTEEN; the guide's
              section 4 settles that from the 0xFE133B reset image and grades it
              PROVEN on one stated premise.
 {STAR} WHY THESE THREE TRAVEL TOGETHER: 0x00C0 and 0x0240 are exactly the two
          registers whose index carries R[+0x21], the `P0SITI0N M0VEMENT` term
          that Pack104_TickPositionMovement_ForVoice recomputes; 0x0100 rides
          along because its table is read with the same index register.
 GRADE: PROVEN for the arithmetic and the destinations.  The names
          `P0SITI0N` (0x00C0) and its table-pair companion (0x0100) are STRONG;
          0x0240's name is WEAK -- a 3! choice among DEPTH / FORMANT /
          INTERACTION GAIN with no measurement (guide sections 3 and 8.3).
""",

"Pack104_StageReg_0280": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 Pack104_StageReg_0280 -- fills the one staging word its
          counterpart Dev104_SetChanReg_0280 ships (that routine reads struct
          offset +0x14, 0xFB7B58).  With R = *(0x00E086):
            struct+0x14 (word 10, register chan+0x0280) =
                Curve_Exp2Gain_Percent_101[clamp(R[+0x10] + R[+0x23], 0..100)]
            0xFC4AFA-0xFC4B26
          which is notes/HLE-GUIDE-l7a1429.md section 5's row for 0x0280
          verbatim.  The 0..100 clamp against a 101-entry curve is the reason
          that note reads the control as a PERCENT.
 WHERE ITS INPUTS COME FROM: Dev104_PackStagingStruct sets
          R[+0x10] = Q5(LinCoef_SubGain_KeyRamp_Q5_128, p36) at 0xFC513E-0xFC518C
          -- the touch depth -- and R[+0x23] = P[+0x1E] at 0xFC5196-0xFC51A0,
          the value PartRec_SetSubGainOffset_000F derives from p33.
 GRADE: PROVEN for the arithmetic and the destination.  The name `SUB GAIN` is
          STRONG and is the single fact the whole MAIN/SUB direction rests on
          (notes/FINDINGS-l7a1429-parameter-names.md section 5b).
""",

"PartRec_SetFittingOffset_0001": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 PartRec_SetFittingOffset_0001 -- stores a part-level
          FITTING offset into PART[+0x01] (0xFC58BD; the part record is
          0x005D23 + 0xBB*arg) and then, for each of the four elements whose
          sub-record P has bit 7 of P[+0x00] set, re-derives
            P[+0x16] = (p21 & 0x7F) +/- PART[+0x01]     0xFC5938-0xFC5951
            P[+0x18] = (p31 & 0x7F) +/- PART[+0x01]     0xFC5959-0xFC596F
          with the sign taken from bits 4:3 of P[+0x00] (0xFC5925), which this
          routine also sets from its mask argument.  `pN` is read through
          P[+0x03], the wave-select record pointer.
 WHERE THE VALUES GO: Dev104_PackStagingStruct reads P[+0x16] at 0xFC4FA0 and
          P[+0x18] at 0xFC505D as the additive term of `v1` / `v2` in
          notes/HLE-GUIDE-l7a1429.md section 5.2, and v1/v2 index
          Curve_Fitting_Exp2Decay_256 and Curve_Fitting_Exp2Rise_128 for
          registers chan+0x0140 / 0x01C0 (MAIN) and chan+0x0180 / 0x0200 (SUB).
 GRADE: PROVEN for the offsets and the data path.  STRONG for the name
          `FITTING`, from notes/FINDINGS-l7a1429-parameter-names.md section 5c,
          which carries that note's one-caption point of failure.
""",

"PartRec_SetPositionOffset_0003": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 PartRec_SetPositionOffset_0003 -- stores a part-level
          `P0SITI0N` offset into PART[+0x03] (0xFC5A0E) and re-derives, per
          enabled element, with the sign from bits 2:1 of P[+0x00] (0xFC5A73):
            P[+0x20] = p13 +/- PART[+0x03]             0xFC5A86-0xFC5AA2
            P[+0x22] = (p14 & 0x7F) +/- PART[+0x03]/4  0xFC5AE2-0xFC5B1B
 WHERE THE VALUES GO: the packer copies P[+0x20] to R[+0x16] (0xFC5661-0xFC566B)
          and P[+0x22] to R[+0x18] (0xFC5699-0xFC56A3), and those are two of the
          three terms of the index that
          Pack104_StageRegs_00C0_0100_0240 turns into registers chan+0x00C0
          (via R[+0x16]) and chan+0x0240 (via R[+0x18]).
 GRADE: PROVEN for the offsets and the data path.  STRONG for `P0SITI0N`, from
          notes/FINDINGS-l7a1429-parameter-names.md section 5e.  p14's own role
          stays WEAK there and is not asserted here.
""",

"PartRec_SetPositionOffset_0005": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 PartRec_SetPositionOffset_0005 -- the same routine as
          PartRec_SetPositionOffset_0003 with two differences: it stores its
          value into PART[+0x05] instead (0xFC5BC1), and it takes its sign from
          bits 7:6 of P[+0x01] plus bit 5 of P[+0x00] (0xFC5BDE-0xFC5C0D) rather
          than bits 2:1 of P[+0x00].  It re-derives the same two sub-record
          fields, P[+0x20] and P[+0x22] (0xFC5C5B, 0xFC5CD4, 0xFC5CE5, 0xFC5CF7),
          and so reaches registers chan+0x00C0 and chan+0x0240 by the same route.
 {WARN} AN ASYMMETRY, REPORTED AND NOT RESOLVED.  The re-derivation reads
          PART[+0x03] (0xFC5C4D, 0xFC5C7C, 0xFC5CA2, 0xFC5CB9), NOT the
          PART[+0x05] this routine has just written.  So a second, independent
          part-level position control exists in the record and this pass could
          not find where its value is folded into what the elements see.  The
          name says which field the routine SETS and which parameter it
          refreshes; it does not claim the two are the same number.
 GRADE: PROVEN for the store, the refresh and the destinations.  STRONG for
          `P0SITI0N`.
""",

"Pack104_RestageRegs_00C0_0100_0240_ForVoice": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 Pack104_RestageRegs_00C0_0100_0240_ForVoice --
          points the packer's globals at one sounding voice and rebuilds the
          three `P0SITI0N` staging words for it, returning non-zero when it did.
            0x00E086 = 0x00753E + 37*(XIZ+0x08)   the voice's 37-byte record R
            0x00E084 = R[+0x05]                   its 42-byte sub-record P
          then recomputes R's position terms and calls
          Pack104_StageRegs_00C0_0100_0240 with the caller's staging struct
          (0xFC5EE9).
 {STAR}{STAR} WHAT PINS IT: its caller `sub_FAEAF9` (prom_c/midi/midi_controllers.s)
          walks the part's sounding voices from VoiceQuery_Tag00_Part, calls this
          routine at 0xFAEB41 and, when it returns non-zero, calls
          Dev104_SetChanRegs_00C0_0100_0240 at 0xFAEB56 with the SAME staging
          buffer 0x00D7A2.  The pair is prepare-then-write, and the writer's name
          is already established from its own `add rr,0x00C0` operands.
 GRADE: PROVEN for the pairing and the destinations; STRONG for `P0SITI0N`.
""",

"PartRec_SetMovementDepth_0007": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 PartRec_SetMovementDepth_0007 -- stores a part-level
          `P0SITI0N M0VEMENT` depth offset into PART[+0x07] (0xFC5F1A) and
          re-derives, per enabled element,
            P[+0x28] = clamp(p17 +/- PART[+0x07], 0..50)   0xFC5F95-0xFC5FEE
          with the sign from bits 5:4 of P[+0x01] (0xFC5F37-0xFC5F62).
 WHERE THE VALUE GOES: the packer copies P[+0x28] into R[+0x1D]
          (0xFC55A3-0xFC55AF), and R[+0x1D] is the depth in
          `R[+0x21] = waveform * R[+0x1D] / 50`, computed by
          Pack104_TickPositionMovement_ForVoice at 0xFC7CA6-0xFC7CB4.  R[+0x21]
          is the movement term of registers chan+0x00C0 and chan+0x0240.
          {STAR} The 0..50 clamp and the divide by 50 are the same 50: p17's own
          factory values are {{0,10,15,16,20,30,40,50}}
          (notes/FINDINGS-l7a1429-parameter-names.md section 5e).
 GRADE: PROVEN for the arithmetic and the data path; STRONG for the name, which
          is the guide's `P0SITI0N M0VEMENT` page.
""",

"Pack104_RefreshMovementDepth_ForVoice": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 Pack104_RefreshMovementDepth_ForVoice -- the
          per-voice half of PartRec_SetMovementDepth_0007.  It points
          0x00E086 at the voice's 37-byte record and 0x00E084 at its sub-record
          (0xFC603A, 0xFC6044), rewrites P[+0x28] (0xFC60CB, 0xFC60E2) and copies
          it into the live modulator state R[+0x1D] (0xFC60F8), then sets the
          movement run state R[+0x1C] to one of 0..4 (0xFC611B-0xFC616B).
 {STAR} IT SHIPS NOTHING TO THE DEVICE, and it does not need to: registers
          chan+0x00C0 / 0x0100 / 0x0240 are rewritten for every sounding voice at
          the measured 40.69 Hz refresh
          (notes/FINDINGS-l7a1429-write-sequencing.md), so a new depth is picked
          up on the next tick.  Its caller `sub_FAEBD1` (midi_controllers.s,
          0xFAEC13) accordingly has no Dev104_ call after the loop, unlike the
          0x00C0 and 0x0280 handlers.
 GRADE: PROVEN for the stores; STRONG for `P0SITI0N M0VEMENT`.
""",

"PartRec_SetMovementRate_0009": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 PartRec_SetMovementRate_0009 -- stores a part-level
          `P0SITI0N M0VEMENT` rate offset into PART[+0x09] (0xFC6194) and
          re-derives, per enabled element,
            P[+0x29] = Curve_FE0296[clamp((p18 & 0x7F) +/- PART[+0x09], 0..50)]
            0xFC620E-0xFC627D
          with the sign from bits 3:2 of P[+0x01] (0xFC61B1-0xFC61DC).
 WHERE THE VALUE GOES: the packer copies P[+0x29] into R[+0x1E]
          (0xFC55B9-0xFC55C5), and Pack104_TickPositionMovement_ForVoice adds
          R[+0x1E] to the 9-bit phase accumulator R[+0x1F] once per tick
          (0xFC7C5D-0xFC7C84).  {STAR} A per-tick phase increment IS a rate, which
          is why this pass says RATE where
          notes/FINDINGS-l7a1429-parameter-names.md section 5e says p18 is the
          movement "form".  Reported as a sharpening of that lane's word, not as
          a contradiction: bit 7 of p18, which that note calls the form flag, is
          masked off here (`res 0x07,C`, 0xFC6211) and is a separate field.
 {STAR} Curve_FE0296 (0x00FE0296) is therefore the MOVEMENT RATE table, 51 entries
          for the 0..50 index, and it ends exactly where the 512-byte movement
          waveform begins at 0x00FE02C9 (0xFE0296 + 51 = 0xFE02C9).  Both tables
          are in another file and were NOT renamed by this lane.
 GRADE: PROVEN for the arithmetic, the table extents and the phase use.
""",

"Pack104_RefreshMovementRate_ForVoice": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 Pack104_RefreshMovementRate_ForVoice -- the
          per-voice half of PartRec_SetMovementRate_0009: points 0x00E086 /
          0x00E084 at the voice's records (0xFC62AE, 0xFC62B8), rewrites
          P[+0x29] through Curve_FE0296 (0xFC634A, 0xFC6359), copies it into the
          live phase increment R[+0x1E] (0xFC636F) and sets the run state
          R[+0x1C] (0xFC6392-0xFC63E2).
 It ships nothing to the device, for the reason given under
          Pack104_RefreshMovementDepth_ForVoice.
 GRADE: PROVEN for the stores and the destination.
""",

"PartRec_SetMutingOffset_000B": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 PartRec_SetMutingOffset_000B -- stores a part-level
          `MUTING` cutoff offset into PART[+0x0B] (0xFC640B) and re-derives, per
          enabled element,
            P[+0x1A] = (p22 & 0x7F) +/- PART[+0x0B]   0xFC6483-0xFC64A2
            P[+0x1C] = (p32 & 0x7F) +/- PART[+0x0B]   0xFC64A5-0xFC64C4
          with the sign from bits 1:0 of P[+0x01] (0xFC6428-0xFC6453).
 WHERE THE VALUES GO: Dev104_PackStagingStruct reads P[+0x1A] at 0xFC529F as the
          additive term of the index `i3` and P[+0x1C] at 0xFC5415 for `i4`
          (notes/HLE-GUIDE-l7a1429.md section 5.2).  i3 indexes
          Curve_Muting_Cutoff_Q16_128 for register chan+0x0400 (0xFC52E1) and
          Curve_Muting_Cutoff_Q13_128 for chan+0x0340 (0xFC52EF); i4 does the
          same for chan+0x0440 and chan+0x0380.
 {STAR} UNIT: the guide's fit makes that index a MIDI note -- cutoff(i) =
          440 * 2^((i + 36 - 69)/12) Hz at 44.1 kHz, PROVEN to 0.8 cent -- so
          this part-level control is an offset in SEMITONES OF CUTOFF, clamped
          between Table_Muting_CutoffFloor_ByKeyZone_256[zone] and PART[+0x12]
          (0xFC52AF-0xFC52D6).
 GRADE: PROVEN for the arithmetic, the data path and the unit.  STRONG for the
          name `MUTING`, which carries the parameter-names note's section 5c
          point of failure.
""",

"PartRec_SetTuningOffset_000D": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 PartRec_SetTuningOffset_000D -- stores a part-level
          tuning offset into PART[+0x0D] as `value << 8` (0xFC6572, 0xFC657A) --
          i.e. in whole semitones of the register's 1/256-semitone unit -- sets
          the per-element sign in bits 7:6 of P[+0x02] (0xFC6591-0xFC65C2), and
          calls Pack104_ComputeTuningWords_0040_0080 (0xFC65D2) to fold it into
          P[+0x0A] / P[+0x0C], the words registers chan+0x0040 and chan+0x0080
          are built from.
 GRADE: PROVEN for the store, the shift and the callee.  STRONG for the names
          MAIN / SUB RESONATOR `KEY SHIFT` + `TUNE` (parameter-names note
          section 5d).
""",

"PartRec_SetSubGainOffset_000F": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 PartRec_SetSubGainOffset_000F -- stores a part-level
          `SUB GAIN` offset into PART[+0x0F] (0xFC660B) and re-derives, per
          enabled element,
            P[+0x1E] = |(s8)p33| +/- PART[+0x0F]      0xFC668F-0xFC66EB
          with the sign from bits 5:4 of P[+0x02] (0xFC66AC), which it also sets
          from its mask argument (0xFC6662, 0xFC666E).
 WHERE THE VALUE GOES: Dev104_PackStagingStruct copies P[+0x1E] into R[+0x23]
          (0xFC5196-0xFC51A0) and Pack104_StageReg_0280 turns
          R[+0x10] + R[+0x23] into staging word 10 = register chan+0x0280.
 GRADE: PROVEN for the arithmetic and the data path.  STRONG for `SUB GAIN`
          (parameter-names note section 5b) -- the one name the MAIN/SUB
          direction of the whole register map rests on.
""",

"Pack104_RestageReg_0280_ForVoice": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 Pack104_RestageReg_0280_ForVoice -- points the
          packer's globals at one sounding voice (0x00E086 = 0x00753E +
          37*(XIZ+0x08) at 0xFC672A, 0x00E084 = R[+0x05] at 0xFC6734), re-derives
          that voice's `SUB GAIN` value into P[+0x1E] and R[+0x23]
          (0xFC6782-0xFC67E2) and calls Pack104_StageReg_0280 (0xFC67E9).
          Returns non-zero when it staged something.
          {WARN} It then ORs 7 into the low three bits of the staged word
          (0xFC67EF).  Dev104_PackStagingStruct does NOT do that on the note
          path, so register chan+0x0280 has a low-3-bit field this refresh sets
          and the packer leaves clear.  Recorded, not explained.
 {STAR}{STAR} WHAT PINS IT: its caller `sub_FAECC7` (midi_controllers.s) calls this at
          0xFAED0F and, on a non-zero return, Dev104_SetChanReg_0280 at 0xFAED24
          with the same staging buffer -- and that writer reads struct offset
          +0x14, which is the word Pack104_StageReg_0280 fills.
 GRADE: PROVEN for the pairing and the destination; STRONG for `SUB GAIN`.
""",

"Pack104_LoadElementWaveSelRec": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 Pack104_LoadElementWaveSelRec -- binds one 43-byte
          wave-select record to one element of one part and derives every
          sub-record field the 0x00104000 packer reads from it.  Arguments
          (part, element, waveSelRec, enable):
            0x00E082 = 0x005D23 + 0xBB*part                    0xFC681B
            0x00E084 = that + 0x13 + 42*element                0xFC682B
            P[+0x03] = the wave-select record pointer          0xFC6834
            bit 7 of P[+0x00] = (enable != 0)                  0xFC6841/0xFC6849
            enable == 0 -> return without deriving             0xFC684F
            else call Pack104_UnpackWaveSelRec_ToSubRecord     0xFC6856
          then a dispatch on bits 4:3 of P[+0x00] that folds the part-level
          offsets into the element's derived fields, ending at P[+0x1E]
          (0xFC6C7F, 0xFC6C96, 0xFC6C9F).
 {STAR} P[+0x03] IS the `Q` of notes/HLE-GUIDE-l7a1429.md and this store at
          0xFC6834 is the one notes/FINDINGS-l7a1429-parameter-names.md section
          1a cites when it proves Q is a 43-byte WAVE-SELECT record and not a
          tone record.  All 40 of this routine's call sites pass a 43-byte
          object; the census is in that note.
 GRADE: PROVEN for the strides, the bind and the enable bit; STRONG for "this is
          where a tone's modelling parameters enter the packer".
""",

"Pack104_DispatchByResoMode_ForPart": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 Pack104_DispatchByResoMode_ForPart -- reads the
          `RESO MODE` field of all four elements of a part and dispatches on the
          combination.  For each of the four sub-records it takes
          `Q[+0x0B] & 0xC0` through P[+0x03] (0xFC74B9-0xFC74BF) and shifts it
          into an 8-bit code H, two bits per element (0xFC74CF-0xFC74D6); then
            H == 0     -> sub_FC6CA8      0xFC74EC
            H == 0xAA  -> sub_FC6D6E      0xFC74F6
            low nibble non-zero -> sub_FC6FFD else sub_FC6CEA   0xFC7502/0xFC7507
            high nibble non-zero -> sub_FC723F else sub_FC6D2C  0xFC7511/0xFC7516
          When its second argument is 1 it first clears the part's eight
          modelling-parameter words -- PART[+0x01], +0x03, +0x05, +0x07, +0x09,
          +0x0B, +0x0D, +0x0F (0xFC7527-0xFC757B) -- and then re-derives each
          enabled element.
 {STAR}{STAR} THOSE EIGHT WORDS ARE EXACTLY the eight this lane names one setter for:
          PartRec_SetFittingOffset_0001, SetPositionOffset_0003/_0005,
          SetMovementDepth_0007, SetMovementRate_0009, SetMutingOffset_000B,
          SetTuningOffset_000D, SetSubGainOffset_000F.  One routine clearing
          precisely that set, on a stride of two, is independent confirmation
          that they are one group.
 GRADE: PROVEN that it reads wave-select byte +0x0B bits 7:6 and that it clears
          those eight words.  `RESO MODE` for that field is STRONG
          (notes/FINDINGS-l7a1429-parameter-names.md section 2d, where the
          64-name RESONATOR TYPE list in bits 5:0 is PROVEN).
          {WARN} What the six dispatch arms COMPUTE is not established -- they are
          left as sub_XXXXXX.  The name says what selects them, nothing more.
""",

"Pack104_TickPositionMovement_ForVoice": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 Pack104_TickPositionMovement_ForVoice -- advances
          one voice's `P0SITI0N M0VEMENT` modulator by one tick and restages the
          three registers it moves.  With R = *(0x00E086) = 0x00753E +
          37*(XIZ+0x08) (0xFC7C2A) and 0x00E084 = R[+0x05] (0xFC7C34):
            R[+0x1C] run state, read at 0xFC7C44
                 == 1  run;  == 4  start (state <- 1, phase R[+0x1F] <- 0,
                                     0xFC7CC1-0xFC7CC9)
                 == 3  stop  (state <- 0, R[+0x21] <- 0, 0xFC7CD8-0xFC7CE0)
            running:  R[+0x1F] += R[+0x1E]          0xFC7C5D-0xFC7C6D
                      R[+0x1F] &= 0x01FF            0xFC7C7A   -- a 512-step phase
                      w = (s8) *(0x00FE02C9 + R[+0x1F])        0xFC7C91-0xFC7C99
                      R[+0x21] = w * R[+0x1D] / 50  0xFC7CA6-0xFC7CB4
            then call Pack104_StageRegs_00C0_0100_0240   0xFC7CE9
 {STAR}{STAR} THIS IS the guide's `R[+0x21] = p17 * sine / 50`
          (notes/HLE-GUIDE-l7a1429.md section 5, row 0x00C0) implemented: the
          depth R[+0x1D] comes from p17 through PartRec_SetMovementDepth_0007 and
          the increment R[+0x1E] from p18 through PartRec_SetMovementRate_0009.
          It is also the 40.69 Hz rewrite of {{0x00C0, 0x0100, 0x0240}} that
          notes/FINDINGS-l7a1429-write-sequencing.md measured, seen from the
          producing side -- and it explains why those three and no others are
          periodic.
 {STAR} 0x00FE02C9 is therefore a 512-entry signed movement WAVEFORM table.  It is
          in another file and was NOT renamed by this lane.
 GRADE: PROVEN for the arithmetic, the phase width and the table address;
          STRONG for `P0SITI0N M0VEMENT`.
""",

"Pack104_StageReg_0000_ForVoice": f"""
 {STAR} WAVE 20 (lane w20/lsi-packers) ------------------------------------------
 Pack104_StageReg_0000_ForVoice -- gives one voice a
          slot out of the 64-entry pool and stages register chan+0x0000 from it.
          With R = *(0x00E086) = 0x00753E + 37*(XIZ+0x08) (0xFC7DC7):
            H = R[+0x07]; if H < 0x40 release it   Slot64Pool_Release, 0xFC7DD9
            R[+0x07] = Slot64Pool_AcquireOrAddRef(0x00FF)  0xFC7DE0, 0xFC7DE9
            struct+0x00 = R[+0x07] << 8            0xFC7DF7-0xFC7DFD
            then bit 2 SET                         0xFC7E01-0xFC7E07
          struct+0x00 is staging word 0 = register chan+0x0000.
 {STAR}{STAR} 0xFC7DE9 is one of the two sites notes/HLE-GUIDE-l7a1429.md section 8.5
          lists as undecoded writers of register 0x0000; the other, 0xFC4D27, is
          the identical sequence in Pack104_SetInputs_SubRecordPair.  Both store
          a 0..63 index out of a 64-entry pool into R[+0x07], and the packer puts
          R[+0x07] in bits 15:8 of the register (0xFC4DE3-0xFC4DF1).  The guide
          reads bits 13:8 as the channel on the power-on path; this is the same
          field, allocated, on the note path.  Grade STRONG.
          {WARN} It is R[+0x07], not P[+0x07].  See Slot64Pool_AcquireOrAddRef for
          the correction that owes to the parameter-names note's section 6.
          The bit-2 set matches the guide's "bit 2 SET by every note event".
 GRADE: PROVEN for the arithmetic and the destination; STRONG for the reading of
          bits 15:8.
""",
}


def do_document():
    raw = TARGET.read_bytes()
    inserted = 0
    for name, prose in DOCS.items():
        label = (name + ":\n").encode()
        i = raw.find(b"\n" + label)
        if i < 0:
            sys.exit(f"FAIL: label {name} not found -- run --rename first")
        # the header's closing rule is the line immediately before the label
        j = raw.rfind(RULE, 0, i + 1)
        if j < 0:
            sys.exit(f"FAIL: no closing rule above {name}")
        block = "".join(";" + ln + "\n" for ln in prose.strip("\n").split("\n"))
        if block.encode("utf-8") in raw:
            continue
        raw = raw[:j] + block.encode("utf-8") + raw[j:]
        inserted += 1
        print(f"  documented {name}")
    TARGET.write_bytes(raw)
    print(f"{inserted} block(s) inserted")


def do_check():
    raw = TARGET.read_bytes()
    bad = []
    for old, new in load_map():
        if re.search(rb"\b" + old.encode() + rb"\b", raw):
            bad.append(f"{old} still present")
        if not re.search(rb"^" + new.encode() + rb":$", raw, re.M):
            bad.append(f"{new} not defined")
    for name in DOCS:
        if name.encode() + b" -- " not in raw:
            bad.append(f"{name} has no wave-20 block")
    for b in bad:
        print("  FAIL:", b)
    print("FAILURES:", len(bad))
    return 1 if bad else 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--rename", action="store_true")
    ap.add_argument("--document", action="store_true")
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    if a.rename:
        do_rename()
    if a.document:
        do_document()
    if a.check:
        sys.exit(do_check())
    if not (a.rename or a.document or a.check):
        ap.error("pick --rename, --document or --check")
