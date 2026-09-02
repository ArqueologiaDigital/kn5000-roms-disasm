; ==============================================================================
; Technics SX-WSA1R -- prom_c (CPU 2, IC28) -- 0xFA7E2C-0xFABE2F  the VOICE-PARAMETER HELPER MODULE
; ==============================================================================
;
; 9,013 lines moved out of prom_c/wsa1_prom_c.s by notes/prom_c_split.py.  The master
; `.include`s this file at the line the block started on, so the assembler
; sees the same token stream in the same order and the ROM is unchanged:
;
;     python3 scripts/analysis/assert_byte_identical.py    <- the bytes
;     python3 notes/prom_c_split.py --verify               <- the text
;
; ★ EVERY LINE BELOW THIS HEADER IS VERBATIM.  Nothing was reworded, and
;   --verify fails on a single changed character.
;
; WHY THIS IS ONE SUBJECT:
; Banner-declared.  267 Voice_* labels: pitch, key-zone selection and the
; Voice_Stage*/Dev10C_StageRegs_* register stagers.
;
; >>> END OF EXTRACTION HEADER -- everything below is verbatim from the master

; ==============================================================================
; 0xFA7E2C-0xFABE2F -- ★★ THE VOICE-PARAMETER HELPER MODULE
;                       60 routines, 22 computed-goto arms, 4 tables, 16,388 bytes
; ==============================================================================
;
; Everything in this block is a helper the note path calls to turn one field of a
; part or voice record into a value.  It is the block
; notes/FINDINGS-prom_c-voice-module.md §10 ranked as the next module, chosen from
; `python3 notes/prom_c_frontier_src.py --range 0xFA7E2C-0xFABCF9` -- 40 of the 91
; frontier targets and 89 of the 236 call sites, the densest run in the image.
;
; ★ WHO CALLS IT.  126 literal call sites outside the block reach it, and they are
;   not scattered: 61 of them are in the four VoiceRegs_Stage_* routines, and the
;   rest are in VoiceParams_Compute_A/B/C, MidiNote_OnTail, MidiNote_OffTail,
;   MidiNote_OnByPartMode and Voice_Retire_Mode08/10/20 -- the routines
;   notes/FINDINGS-prom_c-voice-module.md already documents as the note path.
;   The full tally, by the converted routine each site sits in, is printed by
;       python3 notes/prom_c_voiceparam_checks.py
;   section 7.  ✔ Re-run at the END of round 3: ALL 126 sites are now in converted
;   code (the row "(caller not yet converted)" is 0, down from 39 when this block
;   was first converted), so the tally is complete rather than a floor.
;   ⚠ The figure was 128 for most of round 3.  Two of those "sites" were byte-pattern
;   noise -- a `1D`/`1E` inside a longer instruction -- and one of them, 0xFA2258,
;   was quoted as the LOW END of the caller span.  prom_c_module_map.py now keeps a
;   site only where the source file's own decode agrees it is an instruction; the
;   real span is 0xFABE52-0xFB8CBD.
;   The sites span 0xFABE52-0xFB8CBD and both ends are checked, not just the first.
;
; ★ THE BLOCK'S OWN BOUNDARIES ARE IN THE BYTES.  0xFA7E2B is `ret`; 0xFA7E2C and
;   0xFABE30 -- the first byte past the block -- are both `link XIZ,imm16`; 0xFABE2F
;   is `ret`.  So the cut falls between routines at both ends, and it was not chosen
;   by address arithmetic.
;
; ★ FOUR COMPUTED-GOTO TABLES SIT IN THE MIDDLE OF THE CODE, and they are why this
;   block could not be converted from a linear disassembly.  A linear decode turns
;   their pointer bytes into instructions, the surrounding branch displacements are
;   then relabelled against those phantom boundaries, and the first attempt rebuilt
;   0xFA9024 as 0x26 where the ROM holds 0x25.  notes/prom_c_verify_fragment.py
;   caught it; the byte gate would have caught it too, but only after the fact.
;   The tables are at 0xFA8C05, 0xFA9032, 0xFA91C6 and 0xFA92D0, each SIX u32
;   entries, and each entry count is established TWICE -- from the `cp WA,5` guard
;   in front of the `jr UGT`, and from reading words while they stay plausible code
;   addresses -- with the two readings required to agree
;   (`python3 notes/prom_c_jumptables.py 0xFA7E2C 0xFABE30`).  In all four, entry 0
;   is the SAME address the out-of-range guard branches to, so index 0 and index > 5
;   are not distinguished.
;
; ★ THREE PAIRS OF ROUTINES IN HERE ARE DUPLICATES, and in two of the three every
;   differing byte is a `calr` displacement whose TARGET is identical on both sides
;   (`python3 notes/prom_c_module_map.py 0xFA7E2C 0xFABE30 --dups`):
;
;       0xFA8347 / 0xFA83CC    97 bytes, 1 byte differs
;       0xFAA87E / 0xFAAC00   238 bytes, 4 bytes differ
;       0xFA919B / 0xFA92A5   266 bytes, 23 differ -- NOT all displacements; this one
;                             also relocates its own jump table and reads a different
;                             struct field, so it is a variant, not a copy.
;
;   A non-pair control (0xFA8347 vs 0xFA842D) differs in 89 of 97 bytes, so the test
;   is not vacuous.  Section 4 of prom_c_voiceparam_checks.py asserts every row.
;   ⚠ RETRACTED 2026-08-25, same day: a FOURTH row read "0xFA8D9B / 0xFA8E47, 71
;   bytes, 1 byte differs".  The 71-byte statement is true -- the sole difference in
;   the first 71 bytes is at +0x1B, the low half of a `calr 0xFA778E` displacement --
;   but the two routines are NOT the same length, so they are not duplicates.  The
;   pair existed only because two BYTE-PATTERN false entries, 0xFA8DE2 and 0xFA8E8E,
;   cut both routines at 71 bytes.  With prom_c_module_map.py's false-entry filter
;   their extents are 172 and 176.  The retraction is asserted, not just written.
;
; ★ THE TWO DISPATCHERS ARE ONE ROUTINE WITH ONE BYTE CHANGED.
;   VoiceParam_DispatchOn_17_36 (0xFA8BDD) and VoiceParam_DispatchOn_17_11 (0xFA900A)
;   are both 64 bytes, share their first twelve, both do `ld XBC,(XHL+0x17)` on the
;   argument, and differ semantically in exactly one byte: the field they then read
;   is +0x36 in one and +0x11 in the other.  Their other differences are the
;   relocated addresses of their own tables.  Those two are the ONLY semantic names
;   in this block, and each claims only what an instruction operand says.
;
; ⚠ WHAT THIS BLOCK DOES NOT ESTABLISH.  Not one field meaning, not one routine's
;   purpose.  Every other routine here is `sub_FAxxxxx`, and every header states its
;   frame size, the argument slots it reads, the absolute addresses it reads and
;   writes, the routines it calls, and its call sites -- all of them instruction
;   operands or an image-wide byte scan, none of them an interpretation.  A name for
;   any of these needs the caller side decoded first, which is the next module, not
;   this one.
;
; ★ HOW THIS BLOCK WAS PRODUCED, end to end and repeatable:
;       python3 notes/gen_prom_c_block.py            > /tmp/vp.s
;       python3 notes/gen_prom_c_block_headers.py --labels  > /tmp/vp.labels
;       python3 notes/gen_prom_c_block_headers.py --headers > /tmp/vp.headers
;       python3 notes/prom_c_apply_headers.py /tmp/vp.s /tmp/vp.labels /tmp/vp.headers \
;           > /tmp/vp.final.s
;       python3 notes/prom_c_verify_fragment.py c 0xFA7E2C /tmp/vp.final.s
;   The generator cuts the range into alternating CODE and TABLE segments, runs each
;   code segment through notes/llvm_roundtrip_autoforce.py -- which assembles its own
;   output and compares it with the ROM before printing anything -- and emits each
;   table as `.long`.  The fragment verifier cleared the result before it was pasted
;   in, and scripts/analysis/assert_byte_identical.py cleared it afterwards.
; ==============================================================================
; --------------------------------------------------------------------------
; sub_FA7E2C -- 0xFA7E2C..0xFA7EE1 (182 bytes)
;
; Called from: 4 site(s) outside this module:
;          0xFB367E in MidiNote_OnTail, 0xFB378B in MidiNote_OffTail
;          0xFB38A0 in MidiNote_OnByPartMode__FB389B, 0xFB39EB in MidiNote_OnByPartMode__FB39E6
; Inputs:  frame `link XIZ,-6`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
;          reads 0x00F2F3
; Evidence: the listing below is the byte-identical round-trip of 0xFA7E2C-0xFA7EE1
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FA7E2C:
	link32 0xEE, 0x0C, 0xFA, 0xFF              ; FA7E2C  link XIZ,0xfffa
	pushw	hl                                   ; FA7E30  push HL
	pushw	de                                   ; FA7E31  push DE
	push	xix                                   ; FA7E32  push XIX
	lda_d16	xix, (0x1523)                      ; FA7E33  lda XIX,0x1523
	ld	h, (xiz+8)                              ; FA7E37  ld H,(XIZ+0x08)
	ld	c, h                                    ; FA7E3A  ld C,H
	extz	bc                                    ; FA7E3C  extz BC
	mul	bc, 0x12C                              ; FA7E3E  mul BC,0x012c
	ld	de, bc                                  ; FA7E42  ld DE,BC
	add	bc, 0x82                               ; FA7E44  add BC,0x0082
	extz	xix                                   ; FA7E48  extz XIX
	extpfx5 0xE3, 0x07, 0xF0, 0xE4, 0x20       ; FA7E4A  ld XWA,(XIX+BC)
	ldl_da	xbc, (0xF2F3)                       ; FA7E4F  ld XBC,(0x00f2f3)
	sub	xbc, xwa                               ; FA7E54  sub XBC,XWA
	ld	(xiz-4), xbc                            ; FA7E56  ld (XIZ+0xfc),XBC
	jrl z, sub_FA7E2C__FA7EC5                  ; FA7E59  jrl Z,0xfa7ec5
	cp	xbc, 25                                 ; FA7E5C  cp XBC,0x00000019
	jr nc, sub_FA7E2C__FA7EA5                  ; FA7E62  jr NC,0xfa7ea5
	ld	wa, de                                  ; FA7E64  ld WA,DE
	add	wa, 0x86                               ; FA7E66  add WA,0x0086
	ld	(xiz-6), wa                             ; FA7E6A  ld (XIZ+0xfa),WA
	extz	xwa                                   ; FA7E6D  extz XWA
	add	wa, ix                                 ; FA7E6F  add WA,IX
	incm8	1, (xwa)                             ; FA7E71  inc 1,(XWA)
	ld	bc, (xiz-6)                             ; FA7E73  ld BC,(XIZ+0xfa)
	extpfx5 0xC3, 0x07, 0xF0, 0xE4, 0x21       ; FA7E76  ld A,(XIX+BC)
	extz	wa                                    ; FA7E7B  extz WA
	cps	wa, 0                                  ; FA7E7D  cp WA,0
	jr z, sub_FA7E2C__FA7EB2                   ; FA7E7F  jr Z,0xfa7eb2
	cps	wa, 1                                  ; FA7E81  cp WA,1
	jr z, sub_FA7E2C__FA7E87                   ; FA7E83  jr Z,0xfa7e87
	jr sub_FA7E2C__FA7E96                      ; FA7E85  jr T,0xfa7e96
sub_FA7E2C__FA7E87:
	ld	bc, de                                  ; FA7E87  ld BC,DE
	add	bc, 0x87                               ; FA7E89  add BC,0x0087
	extz	xbc                                   ; FA7E8D  extz XBC
	add	bc, ix                                 ; FA7E8F  add BC,IX
	ld	(xbc), 16                               ; FA7E91  ld (XBC),0x10
	jr sub_FA7E2C__FA7EC5                      ; FA7E94  jr T,0xfa7ec5
sub_FA7E2C__FA7E96:
	ld	bc, de                                  ; FA7E96  ld BC,DE
	add	bc, 0x87                               ; FA7E98  add BC,0x0087
	extz	xbc                                   ; FA7E9C  extz XBC
	add	bc, ix                                 ; FA7E9E  add BC,IX
	ld	(xbc), 32                               ; FA7EA0  ld (XBC),0x20
	jr sub_FA7E2C__FA7EC5                      ; FA7EA3  jr T,0xfa7ec5
sub_FA7E2C__FA7EA5:
	ld	bc, de                                  ; FA7EA5  ld BC,DE
	add	bc, 0x86                               ; FA7EA7  add BC,0x0086
	extz	xbc                                   ; FA7EAB  extz XBC
	add	bc, ix                                 ; FA7EAD  add BC,IX
	ld	(xbc), 0                                ; FA7EAF  ld (XBC),0x00
sub_FA7E2C__FA7EB2:
	ld	c, h                                    ; FA7EB2  ld C,H
	extz	bc                                    ; FA7EB4  extz BC
	mul	bc, 0x12C                              ; FA7EB6  mul BC,0x012c
	add	bc, 0x87                               ; FA7EBA  add BC,0x0087
	extz	xbc                                   ; FA7EBE  extz XBC
	add	bc, ix                                 ; FA7EC0  add BC,IX
	ld	(xbc), 0                                ; FA7EC2  ld (XBC),0x00
sub_FA7E2C__FA7EC5:
	ld	c, h                                    ; FA7EC5  ld C,H
	extz	bc                                    ; FA7EC7  extz BC
	mul	bc, 0x12C                              ; FA7EC9  mul BC,0x012c
	add	bc, 0x82                               ; FA7ECD  add BC,0x0082
	extz	xbc                                   ; FA7ED1  extz XBC
	add	bc, ix                                 ; FA7ED3  add BC,IX
	ldl_da	xwa, (0xF2F3)                       ; FA7ED5  ld XWA,(0x00f2f3)
	ld	(xbc), xwa                              ; FA7EDA  ld (XBC),XWA
	pop	xix                                    ; FA7EDC  pop XIX
	popw	de                                    ; FA7EDD  pop DE
	popw	hl                                    ; FA7EDE  pop HL
	unlk32 xiz                                 ; FA7EDF  unlk XIZ
	ret                                        ; FA7EE1  ret
; --------------------------------------------------------------------------
; Clamp_ToRange_LowByte -- 0xFA7EE2..0xFA7F03 (34 bytes)
;
; Called from: no site outside this module.
;          17 site(s) inside this module:
;          0xFA86EE 0xFA87B0 0xFA88E3 0xFA8A33 0xFA8B3C 0xFA8B6B
;          0xFA8B91 0xFA8CA6 0xFA8D51 0xFA8E03 0xFA8EAF 0xFA8F69
;          0xFA8F98 0xFA8FBE 0xFA97E3 0xFAA30D 0xFAA44F
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA7EE2-0xFA7F03
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  Clamp_ToRange_LowByte(v, hi, lo): if v > hi the result is hi, else if
;          v < lo the result is lo, else v; the LOW BYTE of the result is returned in A.
;          `cp HL,(XIZ+0x0A) / jr LE` at 0xFA7EEA and `cp HL,(XIZ+0x0C) / jr GE` at 0xFA7EF4,
;          then `ld C,L / ld A,C`.  The name is arithmetic; it says nothing about the
;          seventeen call sites, which pass their own bounds (0xFA97C0 pushes 0x7F and 0).
; --------------------------------------------------------------------------
Clamp_ToRange_LowByte:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA7EE2  link XIZ,0x0000
	pushw	hl                                   ; FA7EE6  push HL
	ld	hl, (xiz+8)                             ; FA7EE7  ld HL,(XIZ+0x08)
	extpfx3 0x9E, 0x0A, 0xF3                   ; FA7EEA  cp HL,(XIZ+0x0a)
	jr le, Clamp_ToRange_LowByte__FA7EF4                  ; FA7EED  jr LE,0xfa7ef4
	ld	hl, (xiz+10)                            ; FA7EEF  ld HL,(XIZ+0x0a)
	jr Clamp_ToRange_LowByte__FA7EFC                      ; FA7EF2  jr T,0xfa7efc
Clamp_ToRange_LowByte__FA7EF4:
	extpfx3 0x9E, 0x0C, 0xF3                   ; FA7EF4  cp HL,(XIZ+0x0c)
	jr ge, Clamp_ToRange_LowByte__FA7EFC                  ; FA7EF7  jr GE,0xfa7efc
	ld	hl, (xiz+12)                            ; FA7EF9  ld HL,(XIZ+0x0c)
Clamp_ToRange_LowByte__FA7EFC:
	ld	c, l                                    ; FA7EFC  ld C,L
	ld	a, c                                    ; FA7EFE  ld A,C
	popw	hl                                    ; FA7F00  pop HL
	unlk32 xiz                                 ; FA7F01  unlk XIZ
	ret                                        ; FA7F03  ret
; --------------------------------------------------------------------------
; Rand_FromTickSquared -- 0xFA7F04..0xFA7F27 (36 bytes)
;
; Called from: no site outside this module.
;          3 site(s) inside this module:
;          0xFA8006 0xFA978C 0xFA9EDC
; Inputs:  no frame and no argument slot read.
; Outputs: no absolute-addressed write.
;          reads 0x00F2F3, 0x00F2F5
; Calls:   0xFCB11B = Multiply32
; Evidence: the listing below is the byte-identical round-trip of 0xFA7F04-0xFA7F27
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ WHAT IT DOES: returns A = ((tick * tick) >> 2) & 0xFF, where `tick` is the 32-bit
;          free-running counter at RAM 0x00F2F3 that the INTT1 handler increments by one
;          (`addl_da 0x00F2F3,xbc` at 0xF9906D; see that routine's header).  The four
;          pushes at 0xFA7F04-0xFA7F13 are `(0x00F2F5),(0x00F2F3)` TWICE, i.e. the same
;          32-bit value as both operands of `Multiply32`; `srl 0x02,XIY` (0xFA7F1C) and
;          `ld C,IYL` (0xFA7F1F) take bits 9..2 of the product.
; ⚠ THE NAME CALLS IT RANDOM FOR ITS USE, NOT FOR ITS ARITHMETIC.  What it computes is
;          deterministic.  All three callers use it as a substitute for a stored
;          parameter: at 0xFA978C and 0xFA9EDC the tone record's byte (+0x01) having the
;          value 0x80 selects this routine's output (bit 7 cleared, so 0..0x7F) instead of
;          the byte itself, and at 0xFA8006 the pitch path scales it by 13 and shifts
;          right 7.  A parameter whose 0x80 encoding means "pick a value" is what makes
;          "random" the reading; nothing measures a distribution.
; Unknown:  whether the tick counter is fast enough at a note-on for the result to be
;          uncorrelated between two voices started in the same interrupt.
; --------------------------------------------------------------------------
Rand_FromTickSquared:
	extpfx5 0xD2, 0xF5, 0xF2, 0x00, 0x04       ; FA7F04  pushw (0x00f2f5)
	extpfx5 0xD2, 0xF3, 0xF2, 0x00, 0x04       ; FA7F09  pushw (0x00f2f3)
	extpfx5 0xD2, 0xF5, 0xF2, 0x00, 0x04       ; FA7F0E  pushw (0x00f2f5)
	extpfx5 0xD2, 0xF3, 0xF2, 0x00, 0x04       ; FA7F13  pushw (0x00f2f3)
	call	0xFCB11B                              ; FA7F18  call 0xfcb11b
	srl	xiy, 2                                 ; FA7F1C  srl 0x02,XIY
	extpfx3 0xC7, 0xF4, 0x8B                   ; FA7F1F  ld C,IYL
	and	c, 0xFF                                ; FA7F22  and C,0xff
	ld	a, c                                    ; FA7F25  ld A,C
	ret                                        ; FA7F27  ret
; --------------------------------------------------------------------------
; Voice_ComputePitch -- 0xFA7F28..0xFA814B (548 bytes)
;
; Called from: 12 site(s) outside this module:
;          0xFB0D0A in sub_FB0B95__FB0C19, 0xFB0FA5 in VoiceParams_Compute_A__FB0ED5
;          0xFB11B4 in VoiceParams_Compute_A__FB10F4, 0xFB142A in VoiceParams_Compute_A__FB131D
;          0xFB16C4 in VoiceParams_Compute_A__FB15B0, 0xFB1986 in VoiceParams_Compute_A__FB185E
;          0xFB1C58 in VoiceParams_Compute_A__FB1B30, 0xFB20FB in sub_FB1FB1__FB20A7
;          0xFB22B5 in VoiceParams_Compute_B__FB2263, 0xFB242C in VoiceParams_Compute_B__FB23DA
;          0xFB25A5 in VoiceParams_Compute_B__FB2553, 0xFB2737 in VoiceParams_Compute_B__FB26E5
; Inputs:  frame `link XIZ,-14`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
;          reads 0x0014FF, 0x001505, 0x00150A
; Calls:   0xFA72E9 = Voice_GetOctaveShift, 0xFA738F = sub_FA738F
;          0xFA73EB = sub_FA73EB, 0xFA7570 = Sat16_0_to_7FFF
;          0xFA7F04 = Rand_FromTickSquared, 0xFCAA2F = Shift16_ArithRight
; Evidence: the listing below is the byte-identical round-trip of 0xFA7F28-0xFA814B
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★★ NAMED (round 7).  THE VOICE PITCH COMPUTATION.  This is the routine that turns a note
;          number into the 15-bit quantity 0x0010C000 register `chan + 0x0400` carries.
; Outputs: voice_record[+0x08] (the pitch before the last stage) and voice_record[+0x06]
;          (the pitch), for the 68-byte record at RAM 0x003BCF + 0x44*voice.
; ★ THE UNIT IS 1/256 OF A SEMITONE, and three independent things say so:
;          1. the accumulator is seeded `A = voice[+0x05] (the note byte) / sll 8,WA /
;             and WA,0x7F00 / add HL,0x0080` at 0xFA7F3A-0xFA7F4B -- note x 256, centred
;             half a step up;
;          2. part[+0x15], which MidiCtrl_Int82_Transpose writes as a signed SEMITONE count,
;             is added SHIFTED LEFT EIGHT (0xFA7F5A);
;          3. part[+0x13], which MidiCtrl_Int81_FineTune writes as (v-0x80)*2, is added
;             UNSHIFTED (0xFA7F68) -- i.e. its full range is one semitone.
;          Sat16_0_to_7FFF then clamps the result to 0..0x7FFF, and 0x7FFF/256 = 127.996:
;          the register's range is exactly the 128 notes.
; Terms it sums, in order: note*256 + 0x80 ; the global word at RAM 0x001505 ;
;          part[+0x15]<<8 ; part[+0x13] ; the return of 0xFA72E9(voice[+0x04], ...) ; then
;          ONE of four key-dependent corrections, selected by a mode byte that is
;          itself chosen by global-setup FLAG BIT 9 at 0xFA7F81 -- and the two paths
;          do NOT share their `else` arm:
;             bit 9 SET   -> mode = the GLOBAL byte (0x00150A), written by
;                            GlobalScale_StoreMode
;             bit 9 CLEAR -> mode = the PER-TONE byte (voice[+0x13])[+0x13]
;             0x40  a pseudo-random detune, (0xFA7F04 result * 13) >> 7
;             0x41  Voice_KeyBend_Curve_0[pitch >> 8]     (0xFDD3AB, signed bytes)
;             0x42  Voice_KeyBend_Curve_1[pitch >> 8]     (0xFDD3AB + 0x80)
;             0x80  GLOBAL path: nothing -- `jr Z,0xfa7fbb` at 0xFA7FB9 targets the
;                   NEXT instruction, so it falls into the else arm.  PER-TONE path:
;                   the join at 0xFA8072, i.e. no correction at all.
;             else  GLOBAL path: the twelve-entry USER SCALE in RAM, 0x00150B +
;                   (note mod 12), sign-extended and doubled (0xFA7FD2-0xFA7FDB) --
;                   written by GlobalScale_StorePitchClassDetune.
;                   PER-TONE path: ROM 0xFDF2C3 + 12*mode + (note mod 12), doubled
;                   (0xFA8064) -- a BANK of such scales, indexed by the mode.
;          * CORRECTED 2026-08-30 (round 8).  This block used to give ONE `else` arm,
;          the ROM table, for both selectors.  The global path has never read that
;          table; it reads RAM.  notes/prom_c_inventory_round8.py --claims asserts
;          both arms' instructions.
;          and finally a KEY-FOLLOW stage: with H = (voice[+0x17])[+0x06] & 7,
;             H == 7  -> the pitch is forced to the constant 0x4280
;             H != 7  -> pitch = 0x4280 + ((pitch - 0x4280) >> H)
;          0x4280 = 0x4200 + 0x80 is exactly this routine's own encoding of note 66, so it
;          is the reference note the key-follow scaling pivots on.  ⚠ WHY note 66 is the
;          pivot is NOT established.
; Evidence: notes/prom_c_dev10c_meaning_checks.py section 8 asserts every byte quoted
;          above; the two bend curves were already proven to be bend curves by this image's
;          own reader (see Voice_KeyBend_Curve_0's header) and by the KN5000 sibling.
; Unknown:  what 0xFA72E9 computes, and what (voice[+0x17])[+0x06] is called.
; --------------------------------------------------------------------------
Voice_ComputePitch:
	link32 0xEE, 0x0C, 0xF2, 0xFF              ; FA7F28  link XIZ,0xfff2
	push	xhl                                   ; FA7F2C  push XHL
	pushw	de                                   ; FA7F2D  push DE
	push	xix                                   ; FA7F2E  push XIX
	ld	ix, (xiz+8)                             ; FA7F2F  ld IX,(XIZ+0x08)
	extz	xix                                   ; FA7F32  extz XIX
	ld	xbc, (xix+31)                           ; FA7F34  ld XBC,(XIX+0x1f)
	ld	(xiz-4), xbc                            ; FA7F37  ld (XIZ+0xfc),XBC
	ld	a, (xix+5)                              ; FA7F3A  ld A,(XIX+0x05)
	extz	wa                                    ; FA7F3D  extz WA
	sll	wa, 8                                  ; FA7F3F  sll 0x08,WA
	and	wa, 0x7F00                             ; FA7F42  and WA,0x7f00
	ld	hl, wa                                  ; FA7F46  ld HL,WA
	add	hl, 0x80                               ; FA7F48  add HL,0x0080
	ld	wa, (0x1505:16)                       ; FA7F4C  ld WA,(0x1505)
	add	wa, hl                                 ; FA7F50  add WA,HL
	ld	(xiz-6), wa                             ; FA7F52  ld (XIZ+0xfa),WA
	ld	hl, (xix+35)                            ; FA7F55  ld HL,(XIX+0x23)
	extz	xhl                                   ; FA7F58  extz XHL
	ld	c, (xhl+21)                             ; FA7F5A  ld C,(XHL+0x15)
	exts	bc                                    ; FA7F5D  exts BC
	sll	bc, 8                                  ; FA7F5F  sll 0x08,BC
	extpfx3 0x9E, 0xFA, 0x81                   ; FA7F62  add BC,(XIZ+0xfa)
	ld	(xiz-8), bc                             ; FA7F65  ld (XIZ+0xf8),BC
	ld	wa, (xhl+19)                            ; FA7F68  ld WA,(XHL+0x13)
	ld	hl, bc                                  ; FA7F6B  ld HL,BC
	add	hl, wa                                 ; FA7F6D  add HL,WA
	ld	xbc, (xix+19)                           ; FA7F6F  ld XBC,(XIX+0x13)
	ld	a, (xbc+85)                             ; FA7F72  ld A,(XBC+0x55)
	pushw	wa                                   ; FA7F75  push WA
	ld	c, (xix+4)                              ; FA7F76  ld C,(XIX+0x04)
	pushw	bc                                   ; FA7F79  push BC
	calr (0xFA72E9 - 0xFA7F7D)                 ; FA7F7A  calr 0xfa72e9
	ld	de, wa                                  ; FA7F7D  ld DE,WA
	add	de, hl                                 ; FA7F7F  add DE,HL
	ld	bc, (0x14FF:16)                       ; FA7F81  ld BC,(0x14ff)
	and	bc, 0x200                              ; FA7F85  and BC,0x0200
	pop	xiy                                    ; FA7F89  pop XIY
	jr z, Voice_ComputePitch__FA7FE0                   ; FA7F8A  jr Z,0xfa7fe0
	extz	xix                                   ; FA7F8C  extz XIX
	ld	bc, (xix+35)                            ; FA7F8E  ld BC,(XIX+0x23)
	extz	xbc                                   ; FA7F91  extz XBC
	ld	a, (xbc+26)                             ; FA7F93  ld A,(XBC+0x1a)
	cps	a, 0                                   ; FA7F96  cp A,0
	jrl z, Voice_ComputePitch__FA8072                  ; FA7F98  jrl Z,0xfa8072
	ldb_d8	c, (0x150A)                         ; FA7F9B  ld C,(0x150a)
	extz	bc                                    ; FA7F9F  extz BC
	cp	bc, 64                                  ; FA7FA1  cp BC,0x0040
	jr z, Voice_ComputePitch__FA8006                   ; FA7FA5  jr Z,0xfa8006
	cp	bc, 65                                  ; FA7FA7  cp BC,0x0041
	jrl z, Voice_ComputePitch__FA8016                  ; FA7FAB  jrl Z,0xfa8016
	cp	bc, 66                                  ; FA7FAE  cp BC,0x0042
	jrl z, Voice_ComputePitch__FA802B                  ; FA7FB2  jrl Z,0xfa802b
	cp	bc, 0x80                                ; FA7FB5  cp BC,0x0080
	jr z, Voice_ComputePitch__FA7FBB                   ; FA7FB9  jr Z,0xfa7fbb
Voice_ComputePitch__FA7FBB:
	extz	xix                                   ; FA7FBB  extz XIX
	ld	c, (xix+5)                              ; FA7FBD  ld C,(XIX+0x05)
	res	7, c                                   ; FA7FC0  res 0x07,C
	extz	bc                                    ; FA7FC3  extz BC
	div	c, 12                                  ; FA7FC5  div C,0x0c
	ld	c, b                                    ; FA7FC8  ld C,B
	extz	bc                                    ; FA7FCA  extz BC
	add	bc, 13                                 ; FA7FCC  add BC,0x000d
	extz	xbc                                   ; FA7FD0  extz XBC
	ld	a, (xbc+0x14FE)                         ; FA7FD2  ld A,(XBC+0x14fe)
	exts	wa                                    ; FA7FD7  exts WA
	add	wa, wa                                 ; FA7FD9  add WA,WA
	add	de, wa                                 ; FA7FDB  add DE,WA
	jrl Voice_ComputePitch__FA8072                     ; FA7FDD  jrl T,0xfa8072
Voice_ComputePitch__FA7FE0:
	extz	xix                                   ; FA7FE0  extz XIX
	ld	xbc, (xix+19)                           ; FA7FE2  ld XBC,(XIX+0x13)
	ld	h, (xbc+19)                             ; FA7FE5  ld H,(XBC+0x13)
	ld	c, h                                    ; FA7FE8  ld C,H
	extz	bc                                    ; FA7FEA  extz BC
	cp	bc, 64                                  ; FA7FEC  cp BC,0x0040
	jr z, Voice_ComputePitch__FA8006                   ; FA7FF0  jr Z,0xfa8006
	cp	bc, 65                                  ; FA7FF2  cp BC,0x0041
	jr z, Voice_ComputePitch__FA8016                   ; FA7FF6  jr Z,0xfa8016
	cp	bc, 66                                  ; FA7FF8  cp BC,0x0042
	jr z, Voice_ComputePitch__FA802B                   ; FA7FFC  jr Z,0xfa802b
	cp	bc, 0x80                                ; FA7FFE  cp BC,0x0080
	jr z, Voice_ComputePitch__FA8072                   ; FA8002  jr Z,0xfa8072
	jr Voice_ComputePitch__FA8046                      ; FA8004  jr T,0xfa8046
Voice_ComputePitch__FA8006:
	calr (0xFA7F04 - 0xFA8009)                 ; FA8006  calr 0xfa7f04
	exts	wa                                    ; FA8009  exts WA
	muls	wa, 13                                ; FA800B  muls WA,0x000d
	sra	wa, 7                                  ; FA800F  sra 0x07,WA
	add	de, wa                                 ; FA8012  add DE,WA
	jr Voice_ComputePitch__FA8072                      ; FA8014  jr T,0xfa8072
Voice_ComputePitch__FA8016:
	ld	bc, de                                  ; FA8016  ld BC,DE
	sra	bc, 8                                  ; FA8018  sra 0x08,BC
	exts	xbc                                   ; FA801B  exts XBC
	add	xbc, 0xFDD3AB                          ; FA801D  add XBC,0x00fdd3ab
	ld	a, (xbc)                                ; FA8023  ld A,(XBC)
	exts	wa                                    ; FA8025  exts WA
	add	de, wa                                 ; FA8027  add DE,WA
	jr Voice_ComputePitch__FA8072                      ; FA8029  jr T,0xfa8072
Voice_ComputePitch__FA802B:
	ld	bc, de                                  ; FA802B  ld BC,DE
	sra	bc, 8                                  ; FA802D  sra 0x08,BC
	exts	xbc                                   ; FA8030  exts XBC
	add	xbc, 0x80                              ; FA8032  add XBC,0x00000080
	add	xbc, 0xFDD3AB                          ; FA8038  add XBC,0x00fdd3ab
	ld	a, (xbc)                                ; FA803E  ld A,(XBC)
	exts	wa                                    ; FA8040  exts WA
	add	de, wa                                 ; FA8042  add DE,WA
	jr Voice_ComputePitch__FA8072                      ; FA8044  jr T,0xfa8072
Voice_ComputePitch__FA8046:
	extz	xix                                   ; FA8046  extz XIX
	ld	c, (xix+5)                              ; FA8048  ld C,(XIX+0x05)
	res	7, c                                   ; FA804B  res 0x07,C
	extz	bc                                    ; FA804E  extz BC
	div	c, 12                                  ; FA8050  div C,0x0c
	ld	a, b                                    ; FA8053  ld A,B
	extz	wa                                    ; FA8055  extz WA
	extz	xwa                                   ; FA8057  extz XWA
	ld	(xiz-8), xwa                            ; FA8059  ld (XIZ+0xf8),XWA
	ldb	c, 12                                  ; FA805C  ld C,0x0c
	mul8rr	c, h                                ; FA805E  mul BC,H
	extz	xbc                                   ; FA8060  extz XBC
	add	xbc, xwa                               ; FA8062  add XBC,XWA
	add	xbc, 0xFDF2C3                          ; FA8064  add XBC,0x00fdf2c3
	ld	a, (xbc)                                ; FA806A  ld A,(XBC)
	exts	wa                                    ; FA806C  exts WA
	add	wa, wa                                 ; FA806E  add WA,WA
	add	de, wa                                 ; FA8070  add DE,WA
Voice_ComputePitch__FA8072:
	pushw	de                                   ; FA8072  push DE
	calr (0xFA7570 - 0xFA8076)                 ; FA8073  calr 0xfa7570
	extz	xix                                   ; FA8076  extz XIX
	ld	(xix+8), wa                             ; FA8078  ld (XIX+0x08),WA
	ld	xbc, (xix+23)                           ; FA807B  ld XBC,(XIX+0x17)
	ld	h, (xbc+6)                              ; FA807E  ld H,(XBC+0x06)
	and	h, 7                                   ; FA8081  and H,0x07
	ld	xbc, (xiz-4)                            ; FA8084  ld XBC,(XIZ+0xfc)
	ld	a, (xbc)                                ; FA8087  ld A,(XBC)
	and	a, 2                                   ; FA8089  and A,0x02
	popw	iy                                    ; FA808C  pop IY
	jr nz, Voice_ComputePitch__FA80C3                  ; FA808D  jr NZ,0xfa80c3
	cps	h, 7                                   ; FA808F  cp H,7
	jr z, Voice_ComputePitch__FA80BB                   ; FA8091  jr Z,0xfa80bb
	ld	a, (xbc+11)                             ; FA8093  ld A,(XBC+0x0b)
	extz	wa                                    ; FA8096  extz WA
	sll	wa, 8                                  ; FA8098  sll 0x08,WA
	add	wa, 0x80                               ; FA809B  add WA,0x0080
	ld	iy, de                                  ; FA809F  ld IY,DE
	sub	iy, wa                                 ; FA80A1  sub IY,WA
	push	0                                     ; FA80A3  push 0x00
	push	h                                     ; FA80A5  push H
	pushw	iy                                   ; FA80A7  push IY
	call	0xFCAA2F                              ; FA80A8  call 0xfcaa2f
	ld	(xiz-6), wa                             ; FA80AC  ld (XIZ+0xfa),WA
	ld	xbc, (xiz-4)                            ; FA80AF  ld XBC,(XIZ+0xfc)
	ld	iy, (xbc+12)                            ; FA80B2  ld IY,(XBC+0x0c)
	ld	de, wa                                  ; FA80B5  ld DE,WA
	add	de, iy                                 ; FA80B7  add DE,IY
	jr Voice_ComputePitch__FA80E2                      ; FA80B9  jr T,0xfa80e2
Voice_ComputePitch__FA80BB:
	ld	xbc, (xiz-4)                            ; FA80BB  ld XBC,(XIZ+0xfc)
	ld	de, (xbc+12)                            ; FA80BE  ld DE,(XBC+0x0c)
	jr Voice_ComputePitch__FA80E2                      ; FA80C1  jr T,0xfa80e2
Voice_ComputePitch__FA80C3:
	cps	h, 7                                   ; FA80C3  cp H,7
	jr z, Voice_ComputePitch__FA80DF                   ; FA80C5  jr Z,0xfa80df
	ldw	bc, 0x4280                             ; FA80C7  ld BC,0x4280
	sub	de, bc                                 ; FA80CA  sub DE,BC
	push	0                                     ; FA80CC  push 0x00
	push	h                                     ; FA80CE  push H
	pushw	de                                   ; FA80D0  push DE
	call	0xFCAA2F                              ; FA80D1  call 0xfcaa2f
	ld	de, wa                                  ; FA80D5  ld DE,WA
	add	wa, 0x4280                             ; FA80D7  add WA,0x4280
	ld	de, wa                                  ; FA80DB  ld DE,WA
	jr Voice_ComputePitch__FA80E2                      ; FA80DD  jr T,0xfa80e2
Voice_ComputePitch__FA80DF:
	ldw	de, 0x4280                             ; FA80DF  ld DE,0x4280
Voice_ComputePitch__FA80E2:
	extz	xix                                   ; FA80E2  extz XIX
	ld	xbc, (xix+23)                           ; FA80E4  ld XBC,(XIX+0x17)
	ld	(xiz-8), xbc                            ; FA80E7  ld (XIZ+0xf8),XBC
	ld	a, (xbc+4)                              ; FA80EA  ld A,(XBC+0x04)
	exts	wa                                    ; FA80ED  exts WA
	sll	wa, 8                                  ; FA80EF  sll 0x08,WA
	add	wa, de                                 ; FA80F2  add WA,DE
	ld	(xiz-10), wa                            ; FA80F4  ld (XIZ+0xf6),WA
	ld	a, (xbc+5)                              ; FA80F7  ld A,(XBC+0x05)
	exts	wa                                    ; FA80FA  exts WA
	add	wa, wa                                 ; FA80FC  add WA,WA
	ld	de, wa                                  ; FA80FE  ld DE,WA
	extpfx3 0x9E, 0xF6, 0x82                   ; FA8100  add DE,(XIZ+0xf6)
	ld	bc, (xix+37)                            ; FA8103  ld BC,(XIX+0x25)
	ld	(xiz-12), bc                            ; FA8106  ld (XIZ+0xf4),BC
	extz	xbc                                   ; FA8109  extz XBC
	ld	a, (xbc+36)                             ; FA810B  ld A,(XBC+0x24)
	exts	wa                                    ; FA810E  exts WA
	sll	wa, 8                                  ; FA8110  sll 0x08,WA
	add	wa, de                                 ; FA8113  add WA,DE
	ld	(xiz-14), wa                            ; FA8115  ld (XIZ+0xf2),WA
	ld	a, (xbc+37)                             ; FA8118  ld A,(XBC+0x25)
	exts	wa                                    ; FA811B  exts WA
	ld	de, wa                                  ; FA811D  ld DE,WA
	extpfx3 0x9E, 0xF2, 0x82                   ; FA811F  add DE,(XIZ+0xf2)
	ld	xbc, (xiz-4)                            ; FA8122  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+10)                             ; FA8125  ld A,(XBC+0x0a)
	pushw	wa                                   ; FA8128  push WA
	ld	a, (xbc+9)                              ; FA8129  ld A,(XBC+0x09)
	pushw	wa                                   ; FA812C  push WA
	pushw	de                                   ; FA812D  push DE
	cps	h, 0                                   ; FA812E  cp H,0
	jr nz, Voice_ComputePitch__FA813C                  ; FA8130  jr NZ,0xfa813c
	calr (0xFA73EB - 0xFA8135)                 ; FA8132  calr 0xfa73eb
	extz	xix                                   ; FA8135  extz XIX
	ld	(xix+6), wa                             ; FA8137  ld (XIX+0x06),WA
	jr Voice_ComputePitch__FA8144                      ; FA813A  jr T,0xfa8144
Voice_ComputePitch__FA813C:
	calr (0xFA738F - 0xFA813F)                 ; FA813C  calr 0xfa738f
	extz	xix                                   ; FA813F  extz XIX
	ld	(xix+6), wa                             ; FA8141  ld (XIX+0x06),WA
Voice_ComputePitch__FA8144:
	inc	6, xsp                                 ; FA8144  inc 6,XSP
	pop	xix                                    ; FA8146  pop XIX
	popw	de                                    ; FA8147  pop DE
	pop	xhl                                    ; FA8148  pop XHL
	unlk32 xiz                                 ; FA8149  unlk XIZ
	ret                                        ; FA814B  ret
; --------------------------------------------------------------------------
; sub_FA814C -- 0xFA814C..0xFA8199 (78 bytes)
;
; Called from: 3 site(s) outside this module:
;          0xFB29C8 in sub_FB289A, 0xFB2BC0 in VoiceParams_Compute_C
;          0xFB2D80 in VoiceParams_Compute_C__FB2C6D
; Inputs:  frame `link XIZ,-2`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA73EB = sub_FA73EB
; Evidence: the listing below is the byte-identical round-trip of 0xFA814C-0xFA8199
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FA814C:
	link32 0xEE, 0x0C, 0xFE, 0xFF              ; FA814C  link XIZ,0xfffe
	push	xhl                                   ; FA8150  push XHL
	pushw	de                                   ; FA8151  push DE
	push	xix                                   ; FA8152  push XIX
	ld	hl, (xiz+8)                             ; FA8153  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FA8156  extz XHL
	ld	xbc, (xhl+23)                           ; FA8158  ld XBC,(XHL+0x17)
	ld	xix, xbc                                ; FA815B  ld XIX,XBC
	ld	xwa, (xhl+31)                           ; FA815D  ld XWA,(XHL+0x1f)
	ld	de, (xwa+12)                            ; FA8160  ld DE,(XWA+0x0c)
	ld	(xhl+8), de                             ; FA8163  ld (XHL+0x08),DE
	ld	c, (xix+4)                              ; FA8166  ld C,(XIX+0x04)
	exts	bc                                    ; FA8169  exts BC
	sll	bc, 8                                  ; FA816B  sll 0x08,BC
	add	bc, de                                 ; FA816E  add BC,DE
	ld	(xiz-2), bc                             ; FA8170  ld (XIZ+0xfe),BC
	ld	a, (xix+5)                              ; FA8173  ld A,(XIX+0x05)
	exts	wa                                    ; FA8176  exts WA
	add	wa, wa                                 ; FA8178  add WA,WA
	ld	de, bc                                  ; FA817A  ld DE,BC
	add	de, wa                                 ; FA817C  add DE,WA
	ld	xbc, (xhl+31)                           ; FA817E  ld XBC,(XHL+0x1f)
	ld	xix, xbc                                ; FA8181  ld XIX,XBC
	ld	a, (xbc+10)                             ; FA8183  ld A,(XBC+0x0a)
	pushw	wa                                   ; FA8186  push WA
	ld	a, (xbc+9)                              ; FA8187  ld A,(XBC+0x09)
	pushw	wa                                   ; FA818A  push WA
	pushw	de                                   ; FA818B  push DE
	calr (0xFA73EB - 0xFA818F)                 ; FA818C  calr 0xfa73eb
	ld	(xhl+6), wa                             ; FA818F  ld (XHL+0x06),WA
	inc	6, xsp                                 ; FA8192  inc 6,XSP
	pop	xix                                    ; FA8194  pop XIX
	popw	de                                    ; FA8195  pop DE
	pop	xhl                                    ; FA8196  pop XHL
	unlk32 xiz                                 ; FA8197  unlk XIZ
	ret                                        ; FA8199  ret
; --------------------------------------------------------------------------
; Voice_SelectKeyZone_Reg0040 -- 0xFA819A..0xFA826B (210 bytes)
;
; Called from: 3 site(s) outside this module:
;          0xFB0B02 in VoiceRegs_Stage_A, 0xFB2820 in VoiceRegs_Stage_C
;          0xFB2EE9 in VoiceRegs_Stage_D
; Inputs:  frame `link XIZ,-12`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D760
;          reads 0x0014FF, 0x00D7ED, 0x00D80D
; Calls:   0xFA744F = KeyMap_LookupByPitch, 0xFA7467 = KeyZone_Stage_Reg0040_Stride8
;          0xFA74AB = KeyZone_Stage_Reg0040_Stride6A, 0xFA74ED = KeyZone_Stage_Reg0040_Stride6B
;          0xFA752F = KeyZone_Stage_Reg0040_Stride4
; Voice record: touches voice_record[+0x06(r), +0x1F(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA819A-0xFA826B
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★★ NAMED (round 7).  PICKS THE KEY ZONE FOR THIS VOICE AND STAGES REGISTER `chan+0x0040`.
;          Reads voice[+0x06] (the pitch), asks KeyMap_LookupByPitch for the zone index of
;          that note, and calls ONE of the four KeyZone_Stage_Reg0040_* walkers -- chosen by
;          bits 0x40 and 0x80 of the first byte of the object at voice[+0x1F] -- which index
;          a record array of stride 8, 6, 6 or 4 and copy the record's FIRST WORD into
;          staging word 1 (RAM 0x00D760 -> register `chan + 0x0040`).
; ★ AND THEN IT REWRITES THE TOP NIBBLE.  When (0x0014FF) & 4 is set and the staged word's
;          bits 15..12 are below 6, those four bits are DOUBLED while bits 11..0 pass through
;          unchanged (0xFA8244-0xFA8261; the identical fix-up is at 0xFA82F0-0xFA8318 in
;          Voice_StageRegs_0040_B).  So the register is read by the firmware as a 4-bit field plus a
;          12-bit payload, and the 4-bit field is remapped by a global configuration bit.
;          [INFERENCE, stated as such] a small top field that a configuration bit doubles,
;          over a 12-bit index, is the shape of a memory-bank selector over a wave number.
;          Nothing here decides that, and no register in this device is called "wave".
; Evidence: `ld WA,(XBC+0x06)` at 0xFA81D9; the four calr sites at 0xFA8210/0xFA8215/
;          0xFA8229/0xFA822E; `ld BC,(0x14FF) / and BC,0x0004` at 0xFA8233; the mask
;          constants 0xF000, 0x6000 and 0x0FFF at 0xFA8244-0xFA8254.
;          notes/prom_c_dev10c_meaning_checks.py sections 11 and 13.
; ★ AND EVERY POINTER IT FOLLOWS IS A 0-BASED OFFSET PLUS AN INSTALLED BASE:
;              XWA = voice[+0x1F]                          the tone-object pointer, absolute
;              XIX = (XWA > (0x00D7ED)) ? (0x00D7ED)       = 0x00F00000, the internal image
;                                       : (0x00D80D)       = 0x00C00000, the expansion board,
;                                                            or 0 when none is fitted
;              key_map_hdr = (XWA+0x01) + XIX              a 0-based offset + the base
;              zone_array  = (XWA+0x05) + XIX              a second
;              key_map     = *(key_map_hdr) + XIX          a third, nested
;              zone        = key_map[note]                 KeyMap_LookupByPitch, 128 bytes
;              sub_index   = key_map_hdr[4 + zone]
;              record      = zone_array + STRIDE * sub_index
;          The bases are installed by ExtBoard_ProbeAndInstallBases (0xFB051E, 0xFB0594).
;          0x00F00000 is prom_d's established base (notes/FINDINGS-memory-map.md §5) and
;          "0-based offsets, no absolute pointers" is prom_d's own established format -- so
;          this is the consumer that section says nothing supplies.  ⚠ It does NOT prove that
;          a specific prom_d structure is one of these arrays; the RAM objects holding the
;          offsets have no traced loader.  notes/prom_c_dev10c_meaning_checks.py section 16.
; Unknown:  what the zone records ARE.  Their first word reaches the hardware; their bytes
;          at +4, +5 and +6 go to Pack104_SetInputs_Rec0C_E08C, which stashes them for the 0x00104000 packer.
; --------------------------------------------------------------------------
Voice_SelectKeyZone_Reg0040:
	link32 0xEE, 0x0C, 0xF4, 0xFF              ; FA819A  link XIZ,0xfff4
	pushw	hl                                   ; FA819E  push HL
	pushw	de                                   ; FA819F  push DE
	push	xix                                   ; FA81A0  push XIX
	ld	bc, (xiz+8)                             ; FA81A1  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA81A4  extz XBC
	ld	xwa, (xbc+31)                           ; FA81A6  ld XWA,(XBC+0x1f)
	ld	(xiz-8), xwa                            ; FA81A9  ld (XIZ+0xf8),XWA
	ldl_da	xix, (0xD7ED)                       ; FA81AC  ld XIX,(0x00d7ed)
	cp	xwa, xix                                ; FA81B1  cp XWA,XIX
	jr ule, Voice_SelectKeyZone_Reg0040__FA81BC                 ; FA81B3  jr ULE,0xfa81bc
	ldl_da	xix, (0xD7ED)                       ; FA81B5  ld XIX,(0x00d7ed)
	jr Voice_SelectKeyZone_Reg0040__FA81C1                      ; FA81BA  jr T,0xfa81c1
Voice_SelectKeyZone_Reg0040__FA81BC:
	ldl_da	xix, (0xD80D)                       ; FA81BC  ld XIX,(0x00d80d)
Voice_SelectKeyZone_Reg0040__FA81C1:
	ld	xbc, (xiz-8)                            ; FA81C1  ld XBC,(XIZ+0xf8)
	ld	xwa, (xbc+1)                            ; FA81C4  ld XWA,(XBC+0x01)
	add	xwa, xix                               ; FA81C7  add XWA,XIX
	ld	(xiz-12), xwa                           ; FA81C9  ld (XIZ+0xf4),XWA
	ld	xiy, (xbc+5)                            ; FA81CC  ld XIY,(XBC+0x05)
	add	xiy, xix                               ; FA81CF  add XIY,XIX
	ld	(xiz-4), xiy                            ; FA81D1  ld (XIZ+0xfc),XIY
	ld	bc, (xiz+8)                             ; FA81D4  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA81D7  extz XBC
	ld	wa, (xbc+6)                             ; FA81D9  ld WA,(XBC+0x06)
	pushw	wa                                   ; FA81DC  push WA
	ld	xwa, (xiz-12)                           ; FA81DD  ld XWA,(XIZ+0xf4)
	ld	xbc, (xwa)                              ; FA81E0  ld XBC,(XWA)
	add	xbc, xix                               ; FA81E2  add XBC,XIX
	push	xbc                                   ; FA81E4  push XBC
	calr (0xFA744F - 0xFA81E8)                 ; FA81E5  calr 0xfa744f
	extz	wa                                    ; FA81E8  extz WA
	extz	xwa                                   ; FA81EA  extz XWA
	inc	4, xwa                                 ; FA81EC  inc 4,XWA
	extpfx3 0xAE, 0xF4, 0x80                   ; FA81EE  add XWA,(XIZ+0xf4)
	ld	l, (xwa)                                ; FA81F1  ld L,(XWA)
	ld	xbc, (xiz-8)                            ; FA81F3  ld XBC,(XIZ+0xf8)
	ld	h, (xbc)                                ; FA81F6  ld H,(XBC)
	ld	w, h                                    ; FA81F8  ld W,H
	and	w, 64                                  ; FA81FA  and W,0x40
	inc	6, xsp                                 ; FA81FD  inc 6,XSP
	jr z, Voice_SelectKeyZone_Reg0040__FA821A                   ; FA81FF  jr Z,0xfa821a
	ld	d, h                                    ; FA8201  ld D,H
	and	d, 0x80                                ; FA8203  and D,0x80
	pushw	hl                                   ; FA8206  push HL
	ld	xwa, (xiz-4)                            ; FA8207  ld XWA,(XIZ+0xfc)
	push	xwa                                   ; FA820A  push XWA
	extpfx3 0x9E, 0x08, 0x04                   ; FA820B  pushw (XIZ+0x08)
	jr z, Voice_SelectKeyZone_Reg0040__FA8215                   ; FA820E  jr Z,0xfa8215
	calr (0xFA7467 - 0xFA8213)                 ; FA8210  calr 0xfa7467
	jr Voice_SelectKeyZone_Reg0040__FA8231                      ; FA8213  jr T,0xfa8231
Voice_SelectKeyZone_Reg0040__FA8215:
	calr (0xFA74AB - 0xFA8218)                 ; FA8215  calr 0xfa74ab
	jr Voice_SelectKeyZone_Reg0040__FA8231                      ; FA8218  jr T,0xfa8231
Voice_SelectKeyZone_Reg0040__FA821A:
	ld	d, h                                    ; FA821A  ld D,H
	and	d, 0x80                                ; FA821C  and D,0x80
	pushw	hl                                   ; FA821F  push HL
	ld	xbc, (xiz-4)                            ; FA8220  ld XBC,(XIZ+0xfc)
	push	xbc                                   ; FA8223  push XBC
	extpfx3 0x9E, 0x08, 0x04                   ; FA8224  pushw (XIZ+0x08)
	jr z, Voice_SelectKeyZone_Reg0040__FA822E                   ; FA8227  jr Z,0xfa822e
	calr (0xFA74ED - 0xFA822C)                 ; FA8229  calr 0xfa74ed
	jr Voice_SelectKeyZone_Reg0040__FA8231                      ; FA822C  jr T,0xfa8231
Voice_SelectKeyZone_Reg0040__FA822E:
	calr (0xFA752F - 0xFA8231)                 ; FA822E  calr 0xfa752f
Voice_SelectKeyZone_Reg0040__FA8231:
	inc	8, xsp                                 ; FA8231  inc 0,XSP
	ld	bc, (0x14FF:16)                       ; FA8233  ld BC,(0x14ff)
	and	bc, 4                                  ; FA8237  and BC,0x0004
	jr z, Voice_SelectKeyZone_Reg0040__FA8266                   ; FA823B  jr Z,0xfa8266
	ldw_da	de, (0xD760)                        ; FA823D  ld DE,(0x00d760)
	ld	hl, de                                  ; FA8242  ld HL,DE
	and	hl, 0xF000                             ; FA8244  and HL,0xf000
	cp	hl, 0x6000                              ; FA8248  cp HL,0x6000
	jr nc, Voice_SelectKeyZone_Reg0040__FA8266                  ; FA824C  jr NC,0xfa8266
	ld	ix, hl                                  ; FA824E  ld IX,HL
	add	ix, ix                                 ; FA8250  add IX,IX
	ld	hl, de                                  ; FA8252  ld HL,DE
	and	hl, 0xFFF                              ; FA8254  and HL,0x0fff
	stw_da	(0xD760), hl                        ; FA8258  ld (0x00d760),HL
	ld	bc, ix                                  ; FA825D  ld BC,IX
	or	bc, hl                                  ; FA825F  or BC,HL
	stw_da	(0xD760), bc                        ; FA8261  ld (0x00d760),BC
Voice_SelectKeyZone_Reg0040__FA8266:
	pop	xix                                    ; FA8266  pop XIX
	popw	de                                    ; FA8267  pop DE
	popw	hl                                    ; FA8268  pop HL
	unlk32 xiz                                 ; FA8269  unlk XIZ
	ret                                        ; FA826B  ret
; --------------------------------------------------------------------------
; Voice_StageRegs_0040_B -- 0xFA826C..0xFA8322 (183 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFB1EF0 in VoiceRegs_Stage_B
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x005A4F, 0x00D760
;          reads 0x0014FF, 0x00D7ED
; Calls:   0xFC3407 = sub_FC3407, 0xFC3480 = sub_FC3480
;          0xFC355B = sub_FC355B, 0xFC3793 = SlotRec_ReadWordAtArgIndex_0003
; Voice record: touches voice_record[+0x00(r), +0x01(rw), +0x03(r), +0x04(r), +0x0F(w), +0x1F(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA826C-0xFA8322
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; Voice_StageRegs_0040_B -- stages word 1 (register 0x0040 + chan) of the 0x0010C000 per-channel
;          staging struct at RAM 0x00D75E, and nothing else in that struct.
;          Write site(s): 0xFA82E4, 0xFA830F, 0xFA8318.
;          Argument: the caller pushes XDE, the 68-byte VOICE RECORD at 0x003BCF + 0x44*voice
;          (`ld C,0x44 / mul BC,(XIZ+0x08) / ld <r>,0x3bcf` at the top of every
;          VoiceRegs_Stage_*), immediately before the call.
;          Called from: VoiceRegs_Stage_B.
;          Evidence: the write addresses above are instruction operands, listed by
;          `python3 notes/prom_c_understanding_round6.py --staging`, which also asserts that
;          this routine writes EXACTLY the register block(s) its name claims and no other.
;          The struct-word -> register-block map is Dev10C_WriteAllChanRegs's own
;          (notes/prom_c_tg_chanmap.py), cross-checked against
;          notes/prom_c_dev10c_field_sources.py by the same section.
;          Unknown: what register 0x0040 carries.  The name states WHICH register this
;          routine produces, never what the register means.
; --------------------------------------------------------------------------
Voice_StageRegs_0040_B:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FA826C  link XIZ,0xfffc
	pushw	hl                                   ; FA8270  push HL
	push	xde                                   ; FA8271  push XDE
	push	xix                                   ; FA8272  push XIX
	ld	de, (xiz+8)                             ; FA8273  ld DE,(XIZ+0x08)
	extz	xde                                   ; FA8276  extz XDE
	ld	xbc, (xde+31)                           ; FA8278  ld XBC,(XDE+0x1f)
	ld	xwa, (xbc+5)                            ; FA827B  ld XWA,(XBC+0x05)
	ld	(xiz-4), xwa                            ; FA827E  ld (XIZ+0xfc),XWA
	ldl_da	xix, (0xD7ED)                       ; FA8281  ld XIX,(0x00d7ed)
	add	xix, xwa                               ; FA8286  add XIX,XWA
	ld	h, (xde+3)                              ; FA8288  ld H,(XDE+0x03)
	cps	h, 0                                   ; FA828B  cp H,0
	jr nz, Voice_StageRegs_0040_B__FA82A4                  ; FA828D  jr NZ,0xfa82a4
	push	0                                     ; FA828F  push 0x00
	push	h                                     ; FA8291  push H
	extz	xde                                   ; FA8293  extz XDE
	ld	c, (xde)                                ; FA8295  ld C,(XDE)
	pushw	bc                                   ; FA8297  push BC
	ld	c, (xde+4)                              ; FA8298  ld C,(XDE+0x04)
	pushw	bc                                   ; FA829B  push BC
	call	0xFC3407                              ; FA829C  call 0xfc3407
	ld	hl, wa                                  ; FA82A0  ld HL,WA
	jr Voice_StageRegs_0040_B__FA82BB                      ; FA82A2  jr T,0xfa82bb
Voice_StageRegs_0040_B__FA82A4:
	cps	h, 3                                   ; FA82A4  cp H,3
	jr nc, Voice_StageRegs_0040_B__FA82CB                  ; FA82A6  jr NC,0xfa82cb
	push	0                                     ; FA82A8  push 0x00
	push	h                                     ; FA82AA  push H
	extz	xde                                   ; FA82AC  extz XDE
	ld	c, (xde)                                ; FA82AE  ld C,(XDE)
	pushw	bc                                   ; FA82B0  push BC
	ld	c, (xde+4)                              ; FA82B1  ld C,(XDE+0x04)
	pushw	bc                                   ; FA82B4  push BC
	call	0xFC3480                              ; FA82B5  call 0xfc3480
	ld	hl, wa                                  ; FA82B9  ld HL,WA
Voice_StageRegs_0040_B__FA82BB:
	inc	6, xsp                                 ; FA82BB  inc 6,XSP
	pushw	hl                                   ; FA82BD  push HL
	call	0xFC355B                              ; FA82BE  call 0xfc355b
	mul	wa, 6                                  ; FA82C2  mul WA,0x0006
	add	xix, xwa                               ; FA82C6  add XIX,XWA
Voice_StageRegs_0040_B__FA82C8:
	popw	bc                                    ; FA82C8  pop BC
	jr Voice_StageRegs_0040_B__FA82D8                      ; FA82C9  jr T,0xfa82d8
Voice_StageRegs_0040_B__FA82CB:
	pushw	de                                   ; FA82CB  push DE
	call	0xFC3793                              ; FA82CC  call 0xfc3793
	mul	wa, 6                                  ; FA82D0  mul WA,0x0006
	add	xix, xwa                               ; FA82D4  add XIX,XWA
	jr Voice_StageRegs_0040_B__FA82C8                      ; FA82D6  jr T,0xfa82c8
Voice_StageRegs_0040_B__FA82D8:
	extz	xde                                   ; FA82D8  extz XDE
	ld	(xde+15), xix                           ; FA82DA  ld (XDE+0x0f),XIX
	extpfx5 0x9A, 0x01, 0x3E, 0x00, 0x40       ; FA82DD  or (XDE+0x01),0x4000
	ld	bc, (xix)                               ; FA82E2  ld BC,(XIX)
	stw_da	(0xD760), bc                        ; FA82E4  ld (0x00d760),BC
	ld	bc, (xix+4)                             ; FA82E9  ld BC,(XIX+0x04)
	stda16	(0x5A4F), bc                        ; FA82EC  ld (0x5a4f),BC
	ld	bc, (0x14FF:16)                       ; FA82F0  ld BC,(0x14ff)
	and	bc, 4                                  ; FA82F4  and BC,0x0004
	jr z, Voice_StageRegs_0040_B__FA831D                   ; FA82F8  jr Z,0xfa831d
	ldw_da	hl, (0xD760)                        ; FA82FA  ld HL,(0x00d760)
	ld	bc, hl                                  ; FA82FF  ld BC,HL
	and	bc, 0xF000                             ; FA8301  and BC,0xf000
	ld	de, bc                                  ; FA8305  ld DE,BC
	add	de, de                                 ; FA8307  add DE,DE
	ld	ix, hl                                  ; FA8309  ld IX,HL
	and	ix, 0xFFF                              ; FA830B  and IX,0x0fff
	stw_da	(0xD760), ix                        ; FA830F  ld (0x00d760),IX
	ld	bc, de                                  ; FA8314  ld BC,DE
	or	bc, ix                                  ; FA8316  or BC,IX
	stw_da	(0xD760), bc                        ; FA8318  ld (0x00d760),BC
Voice_StageRegs_0040_B__FA831D:
	pop	xix                                    ; FA831D  pop XIX
	pop	xde                                    ; FA831E  pop XDE
	popw	hl                                    ; FA831F  pop HL
	unlk32 xiz                                 ; FA8320  unlk XIZ
	ret                                        ; FA8322  ret
; --------------------------------------------------------------------------
; Voice_PitchAddZoneOffset_AB -- 0xFA8323..0xFA8346 (36 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFB0B07 in VoiceRegs_Stage_A, 0xFB1EF5 in VoiceRegs_Stage_B
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
;          reads 0x005A4F
; Calls:   0xFA7570 = Sat16_0_to_7FFF
; Voice record: touches voice_record[+0x06(r), +0x0A(w)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA8323-0xFA8346
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  voice[+0x0A] = Sat16_0_to_7FFF( voice[+0x06] + (0x005A4F) ), i.e. the
;          computed pitch plus the KEY-ZONE tuning offset the zone walkers latched into
;          0x005A4F when they picked the zone record.
; Evidence: `ld HL,(XBC+0x06)` / `ld WA,(0x5A4F)` / `add WA,HL` at 0xFA832D, the call to
;          Sat16_0_to_7FFF at 0xFA8337 and `ld (XBC+0x0A),WA` at 0xFA833F.
;          notes/prom_c_dev10c_meaning_checks.py section 8.
; Why _AB: its only two callers are VoiceRegs_Stage_A and VoiceRegs_Stage_B.
;          Voice_PitchAddZoneOffset_CD is the C/D twin -- 36 bytes each and NOT byte
;          twins (they differ in the register allocation of the same three steps).
; --------------------------------------------------------------------------
Voice_PitchAddZoneOffset_AB:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA8323  link XIZ,0x0000
	pushw	hl                                   ; FA8327  push HL
	ld	bc, (xiz+8)                             ; FA8328  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA832B  extz XBC
	ld	hl, (xbc+6)                             ; FA832D  ld HL,(XBC+0x06)
	ld	wa, (0x5A4F:16)                       ; FA8330  ld WA,(0x5a4f)
	add	wa, hl                                 ; FA8334  add WA,HL
	pushw	wa                                   ; FA8336  push WA
	calr (0xFA7570 - 0xFA833A)                 ; FA8337  calr 0xfa7570
	ld	bc, (xiz+8)                             ; FA833A  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA833D  extz XBC
	ld	(xbc+10), wa                            ; FA833F  ld (XBC+0x0a),WA
	popw	bc                                    ; FA8342  pop BC
	popw	hl                                    ; FA8343  pop HL
	unlk32 xiz                                 ; FA8344  unlk XIZ
	ret                                        ; FA8346  ret
; --------------------------------------------------------------------------
; Voice_StagePitch_Reg0400_AB -- 0xFA8347..0xFA83A7 (97 bytes)
;
; Called from: 4 site(s) outside this module:
;          0xFADD03 in Voice_RestagePitchReg0400_ForList__FADD02, 0xFADDA1 in sub_FADD29__FADDA0
;          0xFB0B0C in VoiceRegs_Stage_A, 0xFB1EFA in VoiceRegs_Stage_B
; Inputs:  frame `link XIZ,-2`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D76C
;          reads 0x001503
; Calls:   0xFA7570 = Sat16_0_to_7FFF
; Evidence: the listing below is the byte-identical round-trip of 0xFA8347-0xFA83A7
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★★ NAMED (round 7).  STAGES 0x0010C000 REGISTER `chan + 0x0400` -- THE PITCH REGISTER.
; Outputs: RAM 0x00D76C = staging word 7 of the struct at 0x00D75E.
;          value = Sat16_0_to_7FFF( voice[+0x0A] + (0x001503) [+/- part[+0x1D]] )
;          where the +/- arm is taken only when voice[+0x01] & 0x0200 is clear and
;          (voice[+0x25])[+0x18] & 0x10 is set, its sign coming from bit 5 of the same word.
; ★ WHY THIS IS THE PITCH REGISTER, end to end:
;          Voice_ComputePitch  -> voice[+0x06]   (note*256, see its header)
;          Voice_PitchAddZoneOffset_AB -> voice[+0x0A]  (+ the zone's tuning offset)
;          this routine       -> staging word 7 (+ the global word at 0x001503)
;          Dev10C_WriteAllChanRegs at 0xFB71D4/0xFB71DD sends staging word 7 to register
;          `chan + 0x0400`, and the single-register accessor Dev10C_SetChanPitch_Reg0400 sends
;          the SAME field on its own -- which is what the two controller-driven refresh
;          loops at 0xFADD1A and 0xFADDB8 call after this routine runs.
; Evidence: `ld HL,(XIX+0x0A)` / `ld BC,(0x1503)` at 0xFA8353, the Sat16 call at 0xFA8399 and
;          `ld (0x00D76C),WA` at 0xFA839C; the device side at 0xFB71D4/0xFB71DD.  All
;          asserted by notes/prom_c_dev10c_meaning_checks.py sections 7 and 8.
; Unknown:  what part[+0x1D] is called, and what the two gating bits mean.
; --------------------------------------------------------------------------
Voice_StagePitch_Reg0400_AB:
	link32 0xEE, 0x0C, 0xFE, 0xFF              ; FA8347  link XIZ,0xfffe
	pushw	hl                                   ; FA834B  push HL
	pushw	de                                   ; FA834C  push DE
	push	xix                                   ; FA834D  push XIX
	ld	ix, (xiz+8)                             ; FA834E  ld IX,(XIZ+0x08)
	extz	xix                                   ; FA8351  extz XIX
	ld	hl, (xix+10)                            ; FA8353  ld HL,(XIX+0x0a)
	ld	bc, (0x1503:16)                       ; FA8356  ld BC,(0x1503)
	ld	de, bc                                  ; FA835A  ld DE,BC
	add	de, hl                                 ; FA835C  add DE,HL
	ld	bc, (xix+1)                             ; FA835E  ld BC,(XIX+0x01)
	and	bc, 0x200                              ; FA8361  and BC,0x0200
	jr nz, Voice_StagePitch_Reg0400_AB__FA8398                  ; FA8365  jr NZ,0xfa8398
	extz	xix                                   ; FA8367  extz XIX
	ld	bc, (xix+37)                            ; FA8369  ld BC,(XIX+0x25)
	extz	xbc                                   ; FA836C  extz XBC
	ld	hl, (xbc+24)                            ; FA836E  ld HL,(XBC+0x18)
	ld	bc, hl                                  ; FA8371  ld BC,HL
	and	bc, 16                                 ; FA8373  and BC,0x0010
	jr z, Voice_StagePitch_Reg0400_AB__FA8398                   ; FA8377  jr Z,0xfa8398
	ld	bc, hl                                  ; FA8379  ld BC,HL
	and	bc, 32                                 ; FA837B  and BC,0x0020
	ld	(xiz-2), bc                             ; FA837F  ld (XIZ+0xfe),BC
	extz	xix                                   ; FA8382  extz XIX
	ld	wa, (xix+35)                            ; FA8384  ld WA,(XIX+0x23)
	extz	xwa                                   ; FA8387  extz XWA
	ld	hl, (xwa+29)                            ; FA8389  ld HL,(XWA+0x1d)
	jr z, Voice_StagePitch_Reg0400_AB__FA8394                   ; FA838C  jr Z,0xfa8394
	ld	bc, hl                                  ; FA838E  ld BC,HL
	sub	de, bc                                 ; FA8390  sub DE,BC
	jr Voice_StagePitch_Reg0400_AB__FA8398                      ; FA8392  jr T,0xfa8398
Voice_StagePitch_Reg0400_AB__FA8394:
	ld	bc, hl                                  ; FA8394  ld BC,HL
	add	de, bc                                 ; FA8396  add DE,BC
Voice_StagePitch_Reg0400_AB__FA8398:
	pushw	de                                   ; FA8398  push DE
	calr (0xFA7570 - 0xFA839C)                 ; FA8399  calr 0xfa7570
	stw_da	(0xD76C), wa                        ; FA839C  ld (0x00d76c),WA
	popw	bc                                    ; FA83A1  pop BC
	pop	xix                                    ; FA83A2  pop XIX
	popw	de                                    ; FA83A3  pop DE
	popw	hl                                    ; FA83A4  pop HL
	unlk32 xiz                                 ; FA83A5  unlk XIZ
	ret                                        ; FA83A7  ret
; --------------------------------------------------------------------------
; Voice_PitchAddZoneOffset_CD -- 0xFA83A8..0xFA83CB (36 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFB2825 in VoiceRegs_Stage_C, 0xFB2EFA in VoiceRegs_Stage_D
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
;          reads 0x005A4F
; Calls:   0xFA7570 = Sat16_0_to_7FFF
; Voice record: touches voice_record[+0x06(r), +0x0A(w)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA83A8-0xFA83CB
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  The C/D twin of Voice_PitchAddZoneOffset_AB: same three steps
;          (voice[+0x0A] = Sat16(voice[+0x06] + (0x005A4F))), called only from
;          VoiceRegs_Stage_C and VoiceRegs_Stage_D.  Evidence at 0xFA83AD-0xFA83C4.
; --------------------------------------------------------------------------
Voice_PitchAddZoneOffset_CD:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA83A8  link XIZ,0x0000
	pushw	hl                                   ; FA83AC  push HL
	ld	hl, (0x5A4F:16)                       ; FA83AD  ld HL,(0x5a4f)
	ld	bc, (xiz+8)                             ; FA83B1  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA83B4  extz XBC
	ld	wa, (xbc+6)                             ; FA83B6  ld WA,(XBC+0x06)
	add	wa, hl                                 ; FA83B9  add WA,HL
	pushw	wa                                   ; FA83BB  push WA
	calr (0xFA7570 - 0xFA83BF)                 ; FA83BC  calr 0xfa7570
	ld	bc, (xiz+8)                             ; FA83BF  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA83C2  extz XBC
	ld	(xbc+10), wa                            ; FA83C4  ld (XBC+0x0a),WA
	popw	bc                                    ; FA83C7  pop BC
	popw	hl                                    ; FA83C8  pop HL
	unlk32 xiz                                 ; FA83C9  unlk XIZ
	ret                                        ; FA83CB  ret
; --------------------------------------------------------------------------
; Voice_StagePitch_Reg0400_CD -- 0xFA83CC..0xFA842C (97 bytes)
;
; Called from: 4 site(s) outside this module:
;          0xFADD0A in Voice_RestagePitchReg0400_ForList__FADD09, 0xFADDA8 in sub_FADD29__FADDA7
;          0xFB282A in VoiceRegs_Stage_C, 0xFB2EFF in VoiceRegs_Stage_D
; Inputs:  frame `link XIZ,-2`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D76C
;          reads 0x001503
; Calls:   0xFA7570 = Sat16_0_to_7FFF
; Evidence: the listing below is the byte-identical round-trip of 0xFA83CC-0xFA842C
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★★ NAMED (round 7).  The C/D twin of Voice_StagePitch_Reg0400_AB -- same computation into
;          the same staging word 7 (0x00D76C -> register `chan + 0x0400`), called from
;          VoiceRegs_Stage_C and VoiceRegs_Stage_D instead of A and B.  97 bytes each.
;          ⚠ They are NOT byte twins: the two bodies allocate registers differently.
; --------------------------------------------------------------------------
Voice_StagePitch_Reg0400_CD:
	link32 0xEE, 0x0C, 0xFE, 0xFF              ; FA83CC  link XIZ,0xfffe
	pushw	hl                                   ; FA83D0  push HL
	pushw	de                                   ; FA83D1  push DE
	push	xix                                   ; FA83D2  push XIX
	ld	ix, (xiz+8)                             ; FA83D3  ld IX,(XIZ+0x08)
	extz	xix                                   ; FA83D6  extz XIX
	ld	hl, (xix+10)                            ; FA83D8  ld HL,(XIX+0x0a)
	ld	bc, (0x1503:16)                       ; FA83DB  ld BC,(0x1503)
	ld	de, bc                                  ; FA83DF  ld DE,BC
	add	de, hl                                 ; FA83E1  add DE,HL
	ld	bc, (xix+1)                             ; FA83E3  ld BC,(XIX+0x01)
	and	bc, 0x200                              ; FA83E6  and BC,0x0200
	jr nz, Voice_StagePitch_Reg0400_CD__FA841D                  ; FA83EA  jr NZ,0xfa841d
	extz	xix                                   ; FA83EC  extz XIX
	ld	bc, (xix+37)                            ; FA83EE  ld BC,(XIX+0x25)
	extz	xbc                                   ; FA83F1  extz XBC
	ld	hl, (xbc+24)                            ; FA83F3  ld HL,(XBC+0x18)
	ld	bc, hl                                  ; FA83F6  ld BC,HL
	and	bc, 16                                 ; FA83F8  and BC,0x0010
	jr z, Voice_StagePitch_Reg0400_CD__FA841D                   ; FA83FC  jr Z,0xfa841d
	ld	bc, hl                                  ; FA83FE  ld BC,HL
	and	bc, 32                                 ; FA8400  and BC,0x0020
	ld	(xiz-2), bc                             ; FA8404  ld (XIZ+0xfe),BC
	extz	xix                                   ; FA8407  extz XIX
	ld	wa, (xix+35)                            ; FA8409  ld WA,(XIX+0x23)
	extz	xwa                                   ; FA840C  extz XWA
	ld	hl, (xwa+29)                            ; FA840E  ld HL,(XWA+0x1d)
	jr z, Voice_StagePitch_Reg0400_CD__FA8419                   ; FA8411  jr Z,0xfa8419
	ld	bc, hl                                  ; FA8413  ld BC,HL
	sub	de, bc                                 ; FA8415  sub DE,BC
	jr Voice_StagePitch_Reg0400_CD__FA841D                      ; FA8417  jr T,0xfa841d
Voice_StagePitch_Reg0400_CD__FA8419:
	ld	bc, hl                                  ; FA8419  ld BC,HL
	add	de, bc                                 ; FA841B  add DE,BC
Voice_StagePitch_Reg0400_CD__FA841D:
	pushw	de                                   ; FA841D  push DE
	calr (0xFA7570 - 0xFA8421)                 ; FA841E  calr 0xfa7570
	stw_da	(0xD76C), wa                        ; FA8421  ld (0x00d76c),WA
	popw	bc                                    ; FA8426  pop BC
	pop	xix                                    ; FA8427  pop XIX
	popw	de                                    ; FA8428  pop DE
	popw	hl                                    ; FA8429  pop HL
	unlk32 xiz                                 ; FA842A  unlk XIZ
	ret                                        ; FA842C  ret
; --------------------------------------------------------------------------
; Voice_StageRegs_0900_0940_0980_AB -- 0xFA842D..0xFA866A (574 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFB0B11 in VoiceRegs_Stage_A, 0xFB1EFF in VoiceRegs_Stage_B
; Inputs:  frame `link XIZ,-20`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D77E, 0x00D780, 0x00D782
; Calls:   0xFA7598 = Clamp_ToRange_Word, 0xFA75BA = ScaleCoeff_TimesAbsDepth_Shr
;          0xFA7602 = DetuneCurve_LookupSigned, 0xFA766C = ScaleClampedDelta_Shr5
;          0xFC7FCA = sub_FC7FCA
; Voice record: touches voice_record[+0x01(r), +0x08(r), +0x0C(r), +0x17(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA842D-0xFA866A
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 2, 2026-08-25.  IT BUILDS REGISTERS 0x0900 / 0x0940 / 0x0980 OF BLOCK GROUP 0x20-0x29.
;          Each is written as `(hi << 8) | (lo & 0xFF)`: the HIGH byte comes from
;          Voice_EnvelopeLevel_Curve (this routine makes SIX of prom_c's thirty
;          lookups of it) clamped to 0..0xFF by Clamp_ToRange_Word, the LOW byte from
;          DetuneCurve_LookupSigned of a value first clamped to -50..+50, i.e. a
;          signed +/-127 depth.  ⚠ That these are envelope STAGES, and in what order,
;          is NOT asserted.  See the 0x0800..0x0A40 block comment in front of
;          Dev10C_WriteAllChanRegs; census by notes/prom_c_reg_bytepair_check.py.
;          ⚠ This says what THREE of the routine's outputs are, not what it is.
; ★ ROUND 6 ------------------------------------------------------------
; Voice_StageRegs_0900_0940_0980_AB -- stages word 16 (register 0x0900 + chan), word 17 (register 0x0940 + chan), word 18 (register 0x0980 + chan) of the 0x0010C000 per-channel
;          staging struct at RAM 0x00D75E, and nothing else in that struct.
;          Write site(s): 0xFA85C0, 0xFA8649, 0xFA865C.
;          Argument: the caller pushes XDE, the 68-byte VOICE RECORD at 0x003BCF + 0x44*voice
;          (`ld C,0x44 / mul BC,(XIZ+0x08) / ld <r>,0x3bcf` at the top of every
;          VoiceRegs_Stage_*), immediately before the call.
;          Called from: VoiceRegs_Stage_A, VoiceRegs_Stage_B.
;          Evidence: the write addresses above are instruction operands, listed by
;          `python3 notes/prom_c_understanding_round6.py --staging`, which also asserts that
;          this routine writes EXACTLY the register block(s) its name claims and no other.
;          The struct-word -> register-block map is Dev10C_WriteAllChanRegs's own
;          (notes/prom_c_tg_chanmap.py), cross-checked against
;          notes/prom_c_dev10c_field_sources.py by the same section.
;          Unknown: what register 0x0900 / 0x0940 / 0x0980 carries.  The name states WHICH register this
;          routine produces, never what the register means.
; --------------------------------------------------------------------------
Voice_StageRegs_0900_0940_0980_AB:
	link32 0xEE, 0x0C, 0xEC, 0xFF              ; FA842D  link XIZ,0xffec
	pushw	hl                                   ; FA8431  push HL
	pushw	de                                   ; FA8432  push DE
	pushw	ix                                   ; FA8433  push IX
	ld	bc, (xiz+8)                             ; FA8434  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA8437  extz XBC
	ld	xwa, (xbc+23)                           ; FA8439  ld XWA,(XBC+0x17)
	ld	(xiz-16), xwa                           ; FA843C  ld (XIZ+0xf0),XWA
	ld	iy, (xbc+1)                             ; FA843F  ld IY,(XBC+0x01)
	and	iy, 0x200                              ; FA8442  and IY,0x0200
	jr z, Voice_StageRegs_0900_0940_0980_AB__FA8458                   ; FA8446  jr Z,0xfa8458
	lda	xiy, (0xD75E:24)                       ; FA8448  lda XIY,0x00d75e
	push	xiy                                   ; FA844D  push XIY
	pushw	bc                                   ; FA844E  push BC
	call	0xFC7FCA                              ; FA844F  call 0xfc7fca
	inc	6, xsp                                 ; FA8453  inc 6,XSP
	jrl Voice_StageRegs_0900_0940_0980_AB__FA8665                     ; FA8455  jrl T,0xfa8665
Voice_StageRegs_0900_0940_0980_AB__FA8458:
	ld	xbc, (xiz-16)                           ; FA8458  ld XBC,(XIZ+0xf0)
	ld	a, (xbc+7)                              ; FA845B  ld A,(XBC+0x07)
	cps	a, 0                                   ; FA845E  cp A,0
	jr ge, Voice_StageRegs_0900_0940_0980_AB__FA8488                  ; FA8460  jr GE,0xfa8488
	ld	a, (xbc+10)                             ; FA8462  ld A,(XBC+0x0a)
	exts	wa                                    ; FA8465  exts WA
	cpl	wa                                     ; FA8467  cpl WA
	inc	1, wa                                  ; FA8469  inc 1,WA
	ld	(xiz-10), wa                            ; FA846B  ld (XIZ+0xf6),WA
	ld	a, (xbc+12)                             ; FA846E  ld A,(XBC+0x0c)
	exts	wa                                    ; FA8471  exts WA
	cpl	wa                                     ; FA8473  cpl WA
	inc	1, wa                                  ; FA8475  inc 1,WA
	ld	(xiz-12), wa                            ; FA8477  ld (XIZ+0xf4),WA
	ld	a, (xbc+14)                             ; FA847A  ld A,(XBC+0x0e)
	exts	wa                                    ; FA847D  exts WA
	cpl	wa                                     ; FA847F  cpl WA
	inc	1, wa                                  ; FA8481  inc 1,WA
	ld	(xiz-8), wa                             ; FA8483  ld (XIZ+0xf8),WA
	jr Voice_StageRegs_0900_0940_0980_AB__FA84A3                      ; FA8486  jr T,0xfa84a3
Voice_StageRegs_0900_0940_0980_AB__FA8488:
	ld	xbc, (xiz-16)                           ; FA8488  ld XBC,(XIZ+0xf0)
	ld	a, (xbc+10)                             ; FA848B  ld A,(XBC+0x0a)
	exts	wa                                    ; FA848E  exts WA
	ld	(xiz-10), wa                            ; FA8490  ld (XIZ+0xf6),WA
	ld	a, (xbc+12)                             ; FA8493  ld A,(XBC+0x0c)
	exts	wa                                    ; FA8496  exts WA
	ld	(xiz-12), wa                            ; FA8498  ld (XIZ+0xf4),WA
	ld	a, (xbc+14)                             ; FA849B  ld A,(XBC+0x0e)
	exts	wa                                    ; FA849E  exts WA
	ld	(xiz-8), wa                             ; FA84A0  ld (XIZ+0xf8),WA
Voice_StageRegs_0900_0940_0980_AB__FA84A3:
	ld	xbc, (xiz-16)                           ; FA84A3  ld XBC,(XIZ+0xf0)
	ld	h, (xbc+17)                             ; FA84A6  ld H,(XBC+0x11)
	cps	h, 0                                   ; FA84A9  cp H,0
	jrl z, Voice_StageRegs_0900_0940_0980_AB__FA8530                  ; FA84AB  jrl Z,0xfa8530
	pushw	4                                    ; FA84AE  push 0x0004
	ld	wa, (xiz+8)                             ; FA84B1  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA84B4  extz XWA
	ld	c, (xwa+12)                             ; FA84B6  ld C,(XWA+0x0c)
	pushw	bc                                   ; FA84B9  push BC
	push	0                                     ; FA84BA  push 0x00
	push	h                                     ; FA84BC  push H
	calr (0xFA75BA - 0xFA84C1)                 ; FA84BE  calr 0xfa75ba
	ld	(xiz-4), wa                             ; FA84C1  ld (XIZ+0xfc),WA
	ld	xbc, (xiz-16)                           ; FA84C4  ld XBC,(XIZ+0xf0)
	ld	h, (xbc+9)                              ; FA84C7  ld H,(XBC+0x09)
	extpfx3 0xC7, 0xF4, 0x9E                   ; FA84CA  ld IYL,H
	extz	iy                                    ; FA84CD  extz IY
	extz	xiy                                   ; FA84CF  extz XIY
	add	xiy, 0xFDEFD9                          ; FA84D1  add XIY,0x00fdefd9
	ld	c, (xiy)                                ; FA84D7  ld C,(XIY)
	extz	bc                                    ; FA84D9  extz BC
	ld	de, bc                                  ; FA84DB  ld DE,BC
	inc	6, xsp                                 ; FA84DD  inc 6,XSP
	cps	h, 0                                   ; FA84DF  cp H,0
	jr z, Voice_StageRegs_0900_0940_0980_AB__FA84E7                   ; FA84E1  jr Z,0xfa84e7
	add	bc, wa                                 ; FA84E3  add BC,WA
	ld	de, bc                                  ; FA84E5  ld DE,BC
Voice_StageRegs_0900_0940_0980_AB__FA84E7:
	ld	xbc, (xiz-16)                           ; FA84E7  ld XBC,(XIZ+0xf0)
	ld	a, (xbc+11)                             ; FA84EA  ld A,(XBC+0x0b)
	ld	(xiz-18), a                             ; FA84ED  ld (XIZ+0xee),A
	extz	wa                                    ; FA84F0  extz WA
	extz	xwa                                   ; FA84F2  extz XWA
	add	xwa, 0xFDEFD9                          ; FA84F4  add XWA,0x00fdefd9
	ld	w, (xwa)                                ; FA84FA  ld W,(XWA)
	ld	l, w                                    ; FA84FC  ld L,W
	extz	hl                                    ; FA84FE  extz HL
	cp (xiz-18), 0x00                          ; FA8500  cp (XIZ+0xee),0x00
	jr z, Voice_StageRegs_0900_0940_0980_AB__FA850B                   ; FA8504  jr Z,0xfa850b
	ld	wa, (xiz-4)                             ; FA8506  ld WA,(XIZ+0xfc)
	add	hl, wa                                 ; FA8509  add HL,WA
Voice_StageRegs_0900_0940_0980_AB__FA850B:
	ld	xbc, (xiz-16)                           ; FA850B  ld XBC,(XIZ+0xf0)
	ld	a, (xbc+13)                             ; FA850E  ld A,(XBC+0x0d)
	ld	(xiz-1), a                              ; FA8511  ld (XIZ+0xff),A
	cps	a, 0                                   ; FA8514  cp A,0
	jr z, Voice_StageRegs_0900_0940_0980_AB__FA8559                   ; FA8516  jr Z,0xfa8559
	extz	wa                                    ; FA8518  extz WA
	extz	xwa                                   ; FA851A  extz XWA
	add	xwa, 0xFDEFD9                          ; FA851C  add XWA,0x00fdefd9
	ld	w, (xwa)                                ; FA8522  ld W,(XWA)
	extpfx3 0xC7, 0xF0, 0x98                   ; FA8524  ld IXL,W
	extz	ix                                    ; FA8527  extz IX
	ld	wa, (xiz-4)                             ; FA8529  ld WA,(XIZ+0xfc)
	add	ix, wa                                 ; FA852C  add IX,WA
	jr Voice_StageRegs_0900_0940_0980_AB__FA8570                      ; FA852E  jr T,0xfa8570
Voice_StageRegs_0900_0940_0980_AB__FA8530:
	ld	xbc, (xiz-16)                           ; FA8530  ld XBC,(XIZ+0xf0)
	ld	a, (xbc+9)                              ; FA8533  ld A,(XBC+0x09)
	extz	wa                                    ; FA8536  extz WA
	extz	xwa                                   ; FA8538  extz XWA
	add	xwa, 0xFDEFD9                          ; FA853A  add XWA,0x00fdefd9
	ld	w, (xwa)                                ; FA8540  ld W,(XWA)
	ld	e, w                                    ; FA8542  ld E,W
	extz	de                                    ; FA8544  extz DE
	ld	a, (xbc+11)                             ; FA8546  ld A,(XBC+0x0b)
	extz	wa                                    ; FA8549  extz WA
	extz	xwa                                   ; FA854B  extz XWA
	add	xwa, 0xFDEFD9                          ; FA854D  add XWA,0x00fdefd9
	ld	w, (xwa)                                ; FA8553  ld W,(XWA)
	ld	l, w                                    ; FA8555  ld L,W
	extz	hl                                    ; FA8557  extz HL
Voice_StageRegs_0900_0940_0980_AB__FA8559:
	ld	xbc, (xiz-16)                           ; FA8559  ld XBC,(XIZ+0xf0)
	ld	a, (xbc+13)                             ; FA855C  ld A,(XBC+0x0d)
	extz	wa                                    ; FA855F  extz WA
	extz	xwa                                   ; FA8561  extz XWA
	add	xwa, 0xFDEFD9                          ; FA8563  add XWA,0x00fdefd9
	ld	w, (xwa)                                ; FA8569  ld W,(XWA)
	extpfx3 0xC7, 0xF0, 0x98                   ; FA856B  ld IXL,W
	extz	ix                                    ; FA856E  extz IX
Voice_StageRegs_0900_0940_0980_AB__FA8570:
	ld	xbc, (xiz-16)                           ; FA8570  ld XBC,(XIZ+0xf0)
	ld	a, (xbc+20)                             ; FA8573  ld A,(XBC+0x14)
	ld	(xiz-5), a                              ; FA8576  ld (XIZ+0xfb),A
	cps	a, 0                                   ; FA8579  cp A,0
	jr z, Voice_StageRegs_0900_0940_0980_AB__FA859D                   ; FA857B  jr Z,0xfa859d
	pushw	wa                                   ; FA857D  push WA
	pushw	0x7F                                 ; FA857E  push 0x007f
	pushw	0                                    ; FA8581  push 0x0000
	ld	w, (xbc+19)                             ; FA8584  ld W,(XBC+0x13)
	push	0                                     ; FA8587  push 0x00
	push	w                                     ; FA8589  push W
	ld	wa, (xiz+8)                             ; FA858B  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA858E  extz XWA
	ld	iy, (xwa+8)                             ; FA8590  ld IY,(XWA+0x08)
	pushw	iy                                   ; FA8593  push IY
	calr (0xFA766C - 0xFA8597)                 ; FA8594  calr 0xfa766c
	add	de, wa                                 ; FA8597  add DE,WA
	inc	8, xsp                                 ; FA8599  inc 0,XSP
	inc	2, xsp                                 ; FA859B  inc 2,XSP
Voice_StageRegs_0900_0940_0980_AB__FA859D:
	pushw	0                                    ; FA859D  push 0x0000
	pushw	0xFF                                 ; FA85A0  push 0x00ff
	pushw	de                                   ; FA85A3  push DE
	calr (0xFA7598 - 0xFA85A7)                 ; FA85A4  calr 0xfa7598
	ld	(xiz-18), wa                            ; FA85A7  ld (XIZ+0xee),WA
	extpfx3 0x9E, 0xF6, 0x04                   ; FA85AA  pushw (XIZ+0xf6)
	calr (0xFA7602 - 0xFA85B0)                 ; FA85AD  calr 0xfa7602
	and	wa, 0xFF                               ; FA85B0  and WA,0x00ff
	ld	(xiz-20), wa                            ; FA85B4  ld (XIZ+0xec),WA
	ld	bc, (xiz-18)                            ; FA85B7  ld BC,(XIZ+0xee)
	sll	bc, 8                                  ; FA85BA  sll 0x08,BC
	extpfx3 0x9E, 0xEC, 0xE1                   ; FA85BD  or BC,(XIZ+0xec)
	stw_da	(0xD77E), bc                        ; FA85C0  ld (0x00d77e),BC
	ld	xbc, (xiz-16)                           ; FA85C5  ld XBC,(XIZ+0xf0)
	ld	d, (xbc+21)                             ; FA85C8  ld D,(XBC+0x15)
	inc	8, xsp                                 ; FA85CB  inc 0,XSP
	cps	d, 0                                   ; FA85CD  cp D,0
	jr z, Voice_StageRegs_0900_0940_0980_AB__FA860E                   ; FA85CF  jr Z,0xfa860e
	push	0                                     ; FA85D1  push 0x00
	push	d                                     ; FA85D3  push D
	pushw	0x7F                                 ; FA85D5  push 0x007f
	pushw	0                                    ; FA85D8  push 0x0000
	ld	a, (xbc+19)                             ; FA85DB  ld A,(XBC+0x13)
	pushw	wa                                   ; FA85DE  push WA
	ld	wa, (xiz+8)                             ; FA85DF  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA85E2  extz XWA
	ld	iy, (xwa+8)                             ; FA85E4  ld IY,(XWA+0x08)
	pushw	iy                                   ; FA85E7  push IY
	calr (0xFA766C - 0xFA85EB)                 ; FA85E8  calr 0xfa766c
	ld	(xiz-18), wa                            ; FA85EB  ld (XIZ+0xee),WA
	pushw	0                                    ; FA85EE  push 0x0000
	pushw	0xFF                                 ; FA85F1  push 0x00ff
	add	wa, hl                                 ; FA85F4  add WA,HL
	pushw	wa                                   ; FA85F6  push WA
	calr (0xFA7598 - 0xFA85FA)                 ; FA85F7  calr 0xfa7598
	ld	hl, wa                                  ; FA85FA  ld HL,WA
	inc	8, xsp                                 ; FA85FC  inc 0,XSP
	inc	8, xsp                                 ; FA85FE  inc 0,XSP
	pushw	0                                    ; FA8600  push 0x0000
	pushw	0xFF                                 ; FA8603  push 0x00ff
	ld	bc, ix                                  ; FA8606  ld BC,IX
	extpfx3 0x9E, 0xEE, 0x81                   ; FA8608  add BC,(XIZ+0xee)
	pushw	bc                                   ; FA860B  push BC
	jr Voice_StageRegs_0900_0940_0980_AB__FA8623                      ; FA860C  jr T,0xfa8623
Voice_StageRegs_0900_0940_0980_AB__FA860E:
	pushw	0                                    ; FA860E  push 0x0000
	pushw	0xFF                                 ; FA8611  push 0x00ff
	pushw	hl                                   ; FA8614  push HL
	calr (0xFA7598 - 0xFA8618)                 ; FA8615  calr 0xfa7598
	ld	hl, wa                                  ; FA8618  ld HL,WA
	inc	6, xsp                                 ; FA861A  inc 6,XSP
	pushw	0                                    ; FA861C  push 0x0000
	pushw	0xFF                                 ; FA861F  push 0x00ff
	pushw	ix                                   ; FA8622  push IX
Voice_StageRegs_0900_0940_0980_AB__FA8623:
	calr (0xFA7598 - 0xFA8626)                 ; FA8623  calr 0xfa7598
	ld	ix, wa                                  ; FA8626  ld IX,WA
	extpfx3 0x9E, 0xF4, 0x04                   ; FA8628  pushw (XIZ+0xf4)
	calr (0xFA7602 - 0xFA862E)                 ; FA862B  calr 0xfa7602
	ld	de, wa                                  ; FA862E  ld DE,WA
	extpfx3 0x9E, 0xF8, 0x04                   ; FA8630  pushw (XIZ+0xf8)
	calr (0xFA7602 - 0xFA8636)                 ; FA8633  calr 0xfa7602
	ld	(xiz-18), wa                            ; FA8636  ld (XIZ+0xee),WA
	ld	bc, de                                  ; FA8639  ld BC,DE
	and	bc, 0xFF                               ; FA863B  and BC,0x00ff
	ld	(xiz-20), bc                            ; FA863F  ld (XIZ+0xec),BC
	ld	iy, hl                                  ; FA8642  ld IY,HL
	sll	iy, 8                                  ; FA8644  sll 0x08,IY
	or	iy, bc                                  ; FA8647  or IY,BC
	stw_da	(0xD780), iy                        ; FA8649  ld (0x00d780),IY
	ld	hl, (xiz-18)                            ; FA864E  ld HL,(XIZ+0xee)
	and	hl, 0xFF                               ; FA8651  and HL,0x00ff
	ld	bc, ix                                  ; FA8655  ld BC,IX
	sll	bc, 8                                  ; FA8657  sll 0x08,BC
	or	bc, hl                                  ; FA865A  or BC,HL
	stw_da	(0xD782), bc                        ; FA865C  ld (0x00d782),BC
	inc	8, xsp                                 ; FA8661  inc 0,XSP
	inc	2, xsp                                 ; FA8663  inc 2,XSP
Voice_StageRegs_0900_0940_0980_AB__FA8665:
	popw	ix                                    ; FA8665  pop IX
	popw	de                                    ; FA8666  pop DE
	popw	hl                                    ; FA8667  pop HL
	unlk32 xiz                                 ; FA8668  unlk XIZ
	ret                                        ; FA866A  ret
; --------------------------------------------------------------------------
; sub_FA866B -- 0xFA866B..0xFA8758 (238 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFA8C24
; Inputs:  frame `link XIZ,-8`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA76D6 = sub_FA76D6, 0xFA77F3 = Add24_ClampTo120
;          0xFA7810 = sub_FA7810, 0xFA7EE2 = Clamp_ToRange_LowByte
; Voice record: touches voice_record[+0x17(r), +0x23(r), +0x25(r), +0x3F(w), +0x41(w)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA866B-0xFA8758
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FA866B:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FA866B  link XIZ,0xfff8
	push	xhl                                   ; FA866F  push XHL
	pushw	de                                   ; FA8670  push DE
	push	xix                                   ; FA8671  push XIX
	ld	ix, (xiz+8)                             ; FA8672  ld IX,(XIZ+0x08)
	extz	xix                                   ; FA8675  extz XIX
	ld	xbc, (xix+23)                           ; FA8677  ld XBC,(XIX+0x17)
	ld	(xiz-6), xbc                            ; FA867A  ld (XIZ+0xfa),XBC
	ld	wa, (xix+35)                            ; FA867D  ld WA,(XIX+0x23)
	extz	xwa                                   ; FA8680  extz XWA
	ld	c, (xwa+0x75)                           ; FA8682  ld C,(XWA+0x75)
	exts	bc                                    ; FA8685  exts BC
	ld	de, bc                                  ; FA8687  ld DE,BC
	ld	xwa, (xiz-6)                            ; FA8689  ld XWA,(XIZ+0xfa)
	ld	c, (xwa+77)                             ; FA868C  ld C,(XWA+0x4d)
	extz	bc                                    ; FA868F  extz BC
	add	bc, de                                 ; FA8691  add BC,DE
	ld	(xiz-8), bc                             ; FA8693  ld (XIZ+0xf8),BC
	ld	c, (xwa+60)                             ; FA8696  ld C,(XWA+0x3c)
	pushw	bc                                   ; FA8699  push BC
	ld	c, (xwa+55)                             ; FA869A  ld C,(XWA+0x37)
	exts	bc                                    ; FA869D  exts BC
	pushw	bc                                   ; FA869F  push BC
	extpfx3 0x9E, 0xF8, 0x04                   ; FA86A0  pushw (XIZ+0xf8)
	pushw	ix                                   ; FA86A3  push IX
	calr (0xFA76D6 - 0xFA86A7)                 ; FA86A4  calr 0xfa76d6
	ld	(xiz-2), wa                             ; FA86A7  ld (XIZ+0xfe),WA
	ld	hl, (xix+37)                            ; FA86AA  ld HL,(XIX+0x25)
	extz	xhl                                   ; FA86AD  extz XHL
	ld	bc, (xhl+26)                            ; FA86AF  ld BC,(XHL+0x1a)
	and	bc, 0x2000                             ; FA86B2  and BC,0x2000
	inc	8, xsp                                 ; FA86B6  inc 0,XSP
	jr z, sub_FA866B__FA86F9                   ; FA86B8  jr Z,0xfa86f9
	extz	xhl                                   ; FA86BA  extz XHL
	ld	bc, (xhl+28)                            ; FA86BC  ld BC,(XHL+0x1c)
	and	bc, 0x2000                             ; FA86BF  and BC,0x2000
	ld	(xiz-8), bc                             ; FA86C3  ld (XIZ+0xf8),BC
	pushw	0                                    ; FA86C6  push 0x0000
	pushw	5                                    ; FA86C9  push 0x0005
	ld	xiy, (xiz-6)                            ; FA86CC  ld XIY,(XIZ+0xfa)
	ld	c, (xiy+78)                             ; FA86CF  ld C,(XIY+0x4e)
	extz	bc                                    ; FA86D2  extz BC
	ld	hl, bc                                  ; FA86D4  ld HL,BC
	extz	xix                                   ; FA86D6  extz XIX
	ld	bc, (xix+35)                            ; FA86D8  ld BC,(XIX+0x23)
	extz	xbc                                   ; FA86DB  extz XBC
	ld	de, (xbc+51)                            ; FA86DD  ld DE,(XBC+0x33)
	jr z, sub_FA866B__FA86E9                   ; FA86E0  jr Z,0xfa86e9
	ld	bc, hl                                  ; FA86E2  ld BC,HL
	sub	bc, de                                 ; FA86E4  sub BC,DE
	pushw	bc                                   ; FA86E6  push BC
	jr sub_FA866B__FA86EE                      ; FA86E7  jr T,0xfa86ee
sub_FA866B__FA86E9:
	ld	bc, hl                                  ; FA86E9  ld BC,HL
	add	bc, de                                 ; FA86EB  add BC,DE
	pushw	bc                                   ; FA86ED  push BC
sub_FA866B__FA86EE:
	calr (0xFA7EE2 - 0xFA86F1)                 ; FA86EE  calr 0xfa7ee2
	exts	wa                                    ; FA86F1  exts WA
	ld	hl, wa                                  ; FA86F3  ld HL,WA
	inc	6, xsp                                 ; FA86F5  inc 6,XSP
	jr sub_FA866B__FA8703                      ; FA86F7  jr T,0xfa8703
sub_FA866B__FA86F9:
	ld	xbc, (xiz-6)                            ; FA86F9  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+78)                             ; FA86FC  ld A,(XBC+0x4e)
	extz	wa                                    ; FA86FF  extz WA
	ld	hl, wa                                  ; FA8701  ld HL,WA
sub_FA866B__FA8703:
	ld	bc, hl                                  ; FA8703  ld BC,HL
	sll	bc, 13                                 ; FA8705  sll 0x0d,BC
	extpfx3 0x9E, 0xFE, 0xE1                   ; FA8708  or BC,(XIZ+0xfe)
	set	10, bc                                 ; FA870B  set 0x0a,BC
	extz	xix                                   ; FA870E  extz XIX
	ld	(xix+63), bc                            ; FA8710  ld (XIX+0x3f),BC
	ld	bc, (xix+35)                            ; FA8713  ld BC,(XIX+0x23)
	extz	xbc                                   ; FA8716  extz XBC
	ld	wa, (xbc+6)                             ; FA8718  ld WA,(XBC+0x06)
	and	wa, 0x200                              ; FA871B  and WA,0x0200
	jr z, sub_FA866B__FA8730                   ; FA871F  jr Z,0xfa8730
	pushw	72                                   ; FA8721  push 0x0048
	calr (0xFA77F3 - 0xFA8727)                 ; FA8724  calr 0xfa77f3
	ld	(xiz-2), wa                             ; FA8727  ld (XIZ+0xfe),WA
	popw	bc                                    ; FA872A  pop BC
	pushw	0x8D                                 ; FA872B  push 0x008d
	jr sub_FA866B__FA8747                      ; FA872E  jr T,0xfa8747
sub_FA866B__FA8730:
	ld	xbc, (xiz-6)                            ; FA8730  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+79)                             ; FA8733  ld A,(XBC+0x4f)
	extz	wa                                    ; FA8736  extz WA
	pushw	wa                                   ; FA8738  push WA
	calr (0xFA77F3 - 0xFA873C)                 ; FA8739  calr 0xfa77f3
	ld	(xiz-2), wa                             ; FA873C  ld (XIZ+0xfe),WA
	ld	xbc, (xiz-6)                            ; FA873F  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+80)                             ; FA8742  ld A,(XBC+0x50)
	popw	iy                                    ; FA8745  pop IY
	pushw	wa                                   ; FA8746  push WA
sub_FA866B__FA8747:
	calr (0xFA7810 - 0xFA874A)                 ; FA8747  calr 0xfa7810
	extpfx3 0x9E, 0xFE, 0xE0                   ; FA874A  or WA,(XIZ+0xfe)
	extz	xix                                   ; FA874D  extz XIX
	ld	(xix+65), wa                            ; FA874F  ld (XIX+0x41),WA
	popw	bc                                    ; FA8752  pop BC
	pop	xix                                    ; FA8753  pop XIX
	popw	de                                    ; FA8754  pop DE
	pop	xhl                                    ; FA8755  pop XHL
	unlk32 xiz                                 ; FA8756  unlk XIZ
	ret                                        ; FA8758  ret
; --------------------------------------------------------------------------
; sub_FA8759 -- 0xFA8759..0xFA888B (307 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFA8C2A
; Inputs:  frame `link XIZ,-8`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA76D6 = sub_FA76D6, 0xFA77F3 = Add24_ClampTo120
;          0xFA7810 = sub_FA7810, 0xFA7EE2 = Clamp_ToRange_LowByte
; Voice record: touches voice_record[+0x17(r), +0x23(r), +0x25(r), +0x3F(w), +0x41(w)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA8759-0xFA888B
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FA8759:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FA8759  link XIZ,0xfff8
	push	xhl                                   ; FA875D  push XHL
	pushw	de                                   ; FA875E  push DE
	pushw	ix                                   ; FA875F  push IX
	ld	bc, (xiz+8)                             ; FA8760  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA8763  extz XBC
	ld	xwa, (xbc+23)                           ; FA8765  ld XWA,(XBC+0x17)
	ld	(xiz-4), xwa                            ; FA8768  ld (XIZ+0xfc),XWA
	ld	hl, bc                                  ; FA876B  ld HL,BC
	extz	xbc                                   ; FA876D  extz XBC
	ld	hl, (xbc+37)                            ; FA876F  ld HL,(XBC+0x25)
	extz	xhl                                   ; FA8772  extz XHL
	ld	bc, (xhl+26)                            ; FA8774  ld BC,(XHL+0x1a)
	and	bc, 0x2000                             ; FA8777  and BC,0x2000
	jr z, sub_FA8759__FA87BB                   ; FA877B  jr Z,0xfa87bb
	extz	xhl                                   ; FA877D  extz XHL
	ld	bc, (xhl+28)                            ; FA877F  ld BC,(XHL+0x1c)
	ld	ix, bc                                  ; FA8782  ld IX,BC
	and	ix, 0x2000                             ; FA8784  and IX,0x2000
	pushw	0                                    ; FA8788  push 0x0000
	pushw	5                                    ; FA878B  push 0x0005
	ld	c, (xwa+78)                             ; FA878E  ld C,(XWA+0x4e)
	extz	bc                                    ; FA8791  extz BC
	ld	hl, bc                                  ; FA8793  ld HL,BC
	ld	bc, (xiz+8)                             ; FA8795  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA8798  extz XBC
	ld	iy, (xbc+35)                            ; FA879A  ld IY,(XBC+0x23)
	extz	xiy                                   ; FA879D  extz XIY
	ld	de, (xiy+51)                            ; FA879F  ld DE,(XIY+0x33)
	jr z, sub_FA8759__FA87AB                   ; FA87A2  jr Z,0xfa87ab
	ld	iy, hl                                  ; FA87A4  ld IY,HL
	sub	iy, de                                 ; FA87A6  sub IY,DE
	pushw	iy                                   ; FA87A8  push IY
	jr sub_FA8759__FA87B0                      ; FA87A9  jr T,0xfa87b0
sub_FA8759__FA87AB:
	ld	bc, hl                                  ; FA87AB  ld BC,HL
	add	bc, de                                 ; FA87AD  add BC,DE
	pushw	bc                                   ; FA87AF  push BC
sub_FA8759__FA87B0:
	calr (0xFA7EE2 - 0xFA87B3)                 ; FA87B0  calr 0xfa7ee2
	exts	wa                                    ; FA87B3  exts WA
	ld	hl, wa                                  ; FA87B5  ld HL,WA
	inc	6, xsp                                 ; FA87B7  inc 6,XSP
	jr sub_FA8759__FA87C5                      ; FA87B9  jr T,0xfa87c5
sub_FA8759__FA87BB:
	ld	xbc, (xiz-4)                            ; FA87BB  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+78)                             ; FA87BE  ld A,(XBC+0x4e)
	extz	wa                                    ; FA87C1  extz WA
	ld	hl, wa                                  ; FA87C3  ld HL,WA
sub_FA8759__FA87C5:
	ld	bc, (xiz+8)                             ; FA87C5  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA87C8  extz XBC
	ld	wa, (xbc+35)                            ; FA87CA  ld WA,(XBC+0x23)
	ld	(xiz-6), wa                             ; FA87CD  ld (XIZ+0xfa),WA
	extz	xwa                                   ; FA87D0  extz XWA
	ld	iy, (xwa+6)                             ; FA87D2  ld IY,(XWA+0x06)
	and	iy, 0x200                              ; FA87D5  and IY,0x0200
	ld	(xiz-8), iy                             ; FA87D9  ld (XIZ+0xf8),IY
	ld	c, (xwa+0x75)                           ; FA87DC  ld C,(XWA+0x75)
	exts	bc                                    ; FA87DF  exts BC
	ld	de, bc                                  ; FA87E1  ld DE,BC
	ld	xwa, (xiz-4)                            ; FA87E3  ld XWA,(XIZ+0xfc)
	ld	c, (xwa+77)                             ; FA87E6  ld C,(XWA+0x4d)
	extz	bc                                    ; FA87E9  extz BC
	ld	ix, bc                                  ; FA87EB  ld IX,BC
	jr z, sub_FA8759__FA882D                   ; FA87ED  jr Z,0xfa882d
	sub	bc, de                                 ; FA87EF  sub BC,DE
	ld	(xiz-6), bc                             ; FA87F1  ld (XIZ+0xfa),BC
	ld	c, (xwa+60)                             ; FA87F4  ld C,(XWA+0x3c)
	pushw	bc                                   ; FA87F7  push BC
	ld	c, (xwa+55)                             ; FA87F8  ld C,(XWA+0x37)
	exts	bc                                    ; FA87FB  exts BC
	pushw	bc                                   ; FA87FD  push BC
	extpfx3 0x9E, 0xFA, 0x04                   ; FA87FE  pushw (XIZ+0xfa)
	extpfx3 0x9E, 0x08, 0x04                   ; FA8801  pushw (XIZ+0x08)
	calr (0xFA76D6 - 0xFA8807)                 ; FA8804  calr 0xfa76d6
	ld	de, wa                                  ; FA8807  ld DE,WA
	ld	bc, hl                                  ; FA8809  ld BC,HL
	sll	bc, 13                                 ; FA880B  sll 0x0d,BC
	or	bc, de                                  ; FA880E  or BC,DE
	or	bc, 0x480                               ; FA8810  or BC,0x0480
	ld	wa, (xiz+8)                             ; FA8814  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA8817  extz XWA
	ld	(xwa+63), bc                            ; FA8819  ld (XWA+0x3f),BC
	pushw	72                                   ; FA881C  push 0x0048
	calr (0xFA77F3 - 0xFA8822)                 ; FA881F  calr 0xfa77f3
	ld	hl, wa                                  ; FA8822  ld HL,WA
	inc	8, xsp                                 ; FA8824  inc 0,XSP
	inc	2, xsp                                 ; FA8826  inc 2,XSP
	pushw	0x8D                                 ; FA8828  push 0x008d
	jr sub_FA8759__FA8878                      ; FA882B  jr T,0xfa8878
sub_FA8759__FA882D:
	ld	bc, ix                                  ; FA882D  ld BC,IX
	add	bc, de                                 ; FA882F  add BC,DE
	ld	(xiz-6), bc                             ; FA8831  ld (XIZ+0xfa),BC
	ld	xwa, (xiz-4)                            ; FA8834  ld XWA,(XIZ+0xfc)
	ld	c, (xwa+60)                             ; FA8837  ld C,(XWA+0x3c)
	pushw	bc                                   ; FA883A  push BC
	ld	c, (xwa+55)                             ; FA883B  ld C,(XWA+0x37)
	exts	bc                                    ; FA883E  exts BC
	pushw	bc                                   ; FA8840  push BC
	extpfx3 0x9E, 0xFA, 0x04                   ; FA8841  pushw (XIZ+0xfa)
	extpfx3 0x9E, 0x08, 0x04                   ; FA8844  pushw (XIZ+0x08)
	calr (0xFA76D6 - 0xFA884A)                 ; FA8847  calr 0xfa76d6
	ld	de, wa                                  ; FA884A  ld DE,WA
	ld	bc, hl                                  ; FA884C  ld BC,HL
	sll	bc, 13                                 ; FA884E  sll 0x0d,BC
	or	bc, de                                  ; FA8851  or BC,DE
	or	bc, 0x480                               ; FA8853  or BC,0x0480
	ld	wa, (xiz+8)                             ; FA8857  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA885A  extz XWA
	ld	(xwa+63), bc                            ; FA885C  ld (XWA+0x3f),BC
	ld	xbc, (xiz-4)                            ; FA885F  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+79)                             ; FA8862  ld A,(XBC+0x4f)
	extz	wa                                    ; FA8865  extz WA
	pushw	wa                                   ; FA8867  push WA
	calr (0xFA77F3 - 0xFA886B)                 ; FA8868  calr 0xfa77f3
	ld	hl, wa                                  ; FA886B  ld HL,WA
	ld	xbc, (xiz-4)                            ; FA886D  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+80)                             ; FA8870  ld A,(XBC+0x50)
	inc	8, xsp                                 ; FA8873  inc 0,XSP
	inc	2, xsp                                 ; FA8875  inc 2,XSP
	pushw	wa                                   ; FA8877  push WA
sub_FA8759__FA8878:
	calr (0xFA7810 - 0xFA887B)                 ; FA8878  calr 0xfa7810
	or	wa, hl                                  ; FA887B  or WA,HL
	ld	bc, (xiz+8)                             ; FA887D  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA8880  extz XBC
	ld	(xbc+65), wa                            ; FA8882  ld (XBC+0x41),WA
	popw	bc                                    ; FA8885  pop BC
	popw	ix                                    ; FA8886  pop IX
	popw	de                                    ; FA8887  pop DE
	pop	xhl                                    ; FA8888  pop XHL
	unlk32 xiz                                 ; FA8889  unlk XIZ
	ret                                        ; FA888B  ret
; --------------------------------------------------------------------------
; sub_FA888C -- 0xFA888C..0xFA8996 (267 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFA8C30
; Inputs:  frame `link XIZ,-12`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x005A51
; Calls:   0xFA76D6 = sub_FA76D6, 0xFA77F3 = Add24_ClampTo120
;          0xFA7810 = sub_FA7810, 0xFA7EE2 = Clamp_ToRange_LowByte
; Voice record: touches voice_record[+0x17(r), +0x23(r), +0x25(r), +0x3F(w), +0x41(w)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA888C-0xFA8996
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FA888C:
	link32 0xEE, 0x0C, 0xF4, 0xFF              ; FA888C  link XIZ,0xfff4
	push	xhl                                   ; FA8890  push XHL
	pushw	de                                   ; FA8891  push DE
	push	xix                                   ; FA8892  push XIX
	ld	bc, (xiz+8)                             ; FA8893  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA8896  extz XBC
	ld	xwa, (xbc+23)                           ; FA8898  ld XWA,(XBC+0x17)
	ld	xix, xwa                                ; FA889B  ld XIX,XWA
	ld	hl, bc                                  ; FA889D  ld HL,BC
	extz	xbc                                   ; FA889F  extz XBC
	ld	hl, (xbc+37)                            ; FA88A1  ld HL,(XBC+0x25)
	extz	xhl                                   ; FA88A4  extz XHL
	ld	bc, (xhl+26)                            ; FA88A6  ld BC,(XHL+0x1a)
	and	bc, 0x2000                             ; FA88A9  and BC,0x2000
	jr z, sub_FA888C__FA88EF                   ; FA88AD  jr Z,0xfa88ef
	extz	xhl                                   ; FA88AF  extz XHL
	ld	bc, (xhl+28)                            ; FA88B1  ld BC,(XHL+0x1c)
	and	bc, 0x2000                             ; FA88B4  and BC,0x2000
	ld	(xiz-4), bc                             ; FA88B8  ld (XIZ+0xfc),BC
	pushw	0                                    ; FA88BB  push 0x0000
	pushw	5                                    ; FA88BE  push 0x0005
	ld	c, (xwa+78)                             ; FA88C1  ld C,(XWA+0x4e)
	extz	bc                                    ; FA88C4  extz BC
	ld	hl, bc                                  ; FA88C6  ld HL,BC
	ld	bc, (xiz+8)                             ; FA88C8  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA88CB  extz XBC
	ld	iy, (xbc+35)                            ; FA88CD  ld IY,(XBC+0x23)
	extz	xiy                                   ; FA88D0  extz XIY
	ld	de, (xiy+51)                            ; FA88D2  ld DE,(XIY+0x33)
	jr z, sub_FA888C__FA88DE                   ; FA88D5  jr Z,0xfa88de
	ld	iy, hl                                  ; FA88D7  ld IY,HL
	sub	iy, de                                 ; FA88D9  sub IY,DE
	pushw	iy                                   ; FA88DB  push IY
	jr sub_FA888C__FA88E3                      ; FA88DC  jr T,0xfa88e3
sub_FA888C__FA88DE:
	ld	bc, hl                                  ; FA88DE  ld BC,HL
	add	bc, de                                 ; FA88E0  add BC,DE
	pushw	bc                                   ; FA88E2  push BC
sub_FA888C__FA88E3:
	calr (0xFA7EE2 - 0xFA88E6)                 ; FA88E3  calr 0xfa7ee2
	exts	wa                                    ; FA88E6  exts WA
	ld	(xiz-2), wa                             ; FA88E8  ld (XIZ+0xfe),WA
	inc	6, xsp                                 ; FA88EB  inc 6,XSP
	jr sub_FA888C__FA88F7                      ; FA88ED  jr T,0xfa88f7
sub_FA888C__FA88EF:
	ld	c, (xix+78)                             ; FA88EF  ld C,(XIX+0x4e)
	extz	bc                                    ; FA88F2  extz BC
	ld	(xiz-2), bc                             ; FA88F4  ld (XIZ+0xfe),BC
sub_FA888C__FA88F7:
	ld	bc, (xiz+8)                             ; FA88F7  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA88FA  extz XBC
	ld	wa, (xbc+35)                            ; FA88FC  ld WA,(XBC+0x23)
	ld	(xiz-4), wa                             ; FA88FF  ld (XIZ+0xfc),WA
	extz	xwa                                   ; FA8902  extz XWA
	ld	iy, (xwa+6)                             ; FA8904  ld IY,(XWA+0x06)
	and	iy, 0x200                              ; FA8907  and IY,0x0200
	ld	(xiz-6), iy                             ; FA890B  ld (XIZ+0xfa),IY
	ld	c, (xwa+0x75)                           ; FA890E  ld C,(XWA+0x75)
	exts	bc                                    ; FA8911  exts BC
	ld	(xiz-8), bc                             ; FA8913  ld (XIZ+0xf8),BC
	ld	a, (xix+77)                             ; FA8916  ld A,(XIX+0x4d)
	extz	wa                                    ; FA8919  extz WA
	add	wa, bc                                 ; FA891B  add WA,BC
	ld	(xiz-10), wa                            ; FA891D  ld (XIZ+0xf6),WA
	ld	c, (xix+60)                             ; FA8920  ld C,(XIX+0x3c)
	pushw	bc                                   ; FA8923  push BC
	ld	c, (xix+55)                             ; FA8924  ld C,(XIX+0x37)
	exts	bc                                    ; FA8927  exts BC
	pushw	bc                                   ; FA8929  push BC
	pushw	wa                                   ; FA892A  push WA
	extpfx3 0x9E, 0x08, 0x04                   ; FA892B  pushw (XIZ+0x08)
	calr (0xFA76D6 - 0xFA8931)                 ; FA892E  calr 0xfa76d6
	ld	ix, wa                                  ; FA8931  ld IX,WA
	ld	bc, (xiz-2)                             ; FA8933  ld BC,(XIZ+0xfe)
	sll	bc, 13                                 ; FA8936  sll 0x0d,BC
	ld	(xiz-12), bc                            ; FA8939  ld (XIZ+0xf4),BC
	ld	hl, ix                                  ; FA893C  ld HL,IX
	ld	de, bc                                  ; FA893E  ld DE,BC
	or	de, hl                                  ; FA8940  or DE,HL
	inc	8, xsp                                 ; FA8942  inc 0,XSP
	cpw (xiz-6), 0x0000                        ; FA8944  cp (XIZ+0xfa),0x0000
	jr z, sub_FA888C__FA8973                   ; FA8949  jr Z,0xfa8973
	ld	bc, de                                  ; FA894B  ld BC,DE
	set	10, bc                                 ; FA894D  set 0x0a,BC
	ld	wa, (xiz+8)                             ; FA8950  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA8953  extz XWA
	ld	(xwa+63), bc                            ; FA8955  ld (XWA+0x3f),BC
	pushw	72                                   ; FA8958  push 0x0048
	calr (0xFA77F3 - 0xFA895E)                 ; FA895B  calr 0xfa77f3
	ld	hl, wa                                  ; FA895E  ld HL,WA
	pushw	0x8D                                 ; FA8960  push 0x008d
	calr (0xFA7810 - 0xFA8966)                 ; FA8963  calr 0xfa7810
	or	wa, hl                                  ; FA8966  or WA,HL
	ld	bc, (xiz+8)                             ; FA8968  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA896B  extz XBC
	ld	(xbc+65), wa                            ; FA896D  ld (XBC+0x41),WA
	pop	xiy                                    ; FA8970  pop XIY
	jr sub_FA888C__FA8991                      ; FA8971  jr T,0xfa8991
sub_FA888C__FA8973:
	ld	bc, (xiz-2)                             ; FA8973  ld BC,(XIZ+0xfe)
	sll	bc, 10                                 ; FA8976  sll 0x0a,BC
	or	bc, de                                  ; FA8979  or BC,DE
	ld	wa, (xiz+8)                             ; FA897B  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA897E  extz XWA
	ld	(xwa+63), bc                            ; FA8980  ld (XWA+0x3f),BC
	ld	bc, (xiz+8)                             ; FA8983  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA8986  extz XBC
	ld	(xbc+65), hl                            ; FA8988  ld (XBC+0x41),HL
	stdi16	(0x5A51), 0                         ; FA898B  ld (0x5a51),0x0000
sub_FA888C__FA8991:
	pop	xix                                    ; FA8991  pop XIX
	popw	de                                    ; FA8992  pop DE
	pop	xhl                                    ; FA8993  pop XHL
	unlk32 xiz                                 ; FA8994  unlk XIZ
	ret                                        ; FA8996  ret
; --------------------------------------------------------------------------
; sub_FA8997 -- 0xFA8997..0xFA8A78 (226 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFA8C36
; Inputs:  frame `link XIZ,-2`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x005A51
; Calls:   0xFA76D6 = sub_FA76D6, 0xFA7EE2 = Clamp_ToRange_LowByte
; Voice record: touches voice_record[+0x17(r), +0x23(r), +0x25(r), +0x3F(w), +0x41(w)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA8997-0xFA8A78
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FA8997:
	link32 0xEE, 0x0C, 0xFE, 0xFF              ; FA8997  link XIZ,0xfffe
	push	xhl                                   ; FA899B  push XHL
	pushw	de                                   ; FA899C  push DE
	push	xix                                   ; FA899D  push XIX
	ld	bc, (xiz+8)                             ; FA899E  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA89A1  extz XBC
	ld	xwa, (xbc+23)                           ; FA89A3  ld XWA,(XBC+0x17)
	ld	xix, xwa                                ; FA89A6  ld XIX,XWA
	ld	hl, bc                                  ; FA89A8  ld HL,BC
	extz	xbc                                   ; FA89AA  extz XBC
	ld	hl, (xbc+35)                            ; FA89AC  ld HL,(XBC+0x23)
	extz	xhl                                   ; FA89AF  extz XHL
	ld	bc, (xhl+6)                             ; FA89B1  ld BC,(XHL+0x06)
	and	bc, 0x200                              ; FA89B4  and BC,0x0200
	jr z, sub_FA8997__FA89C3                   ; FA89B8  jr Z,0xfa89c3
	ld	c, (xwa+77)                             ; FA89BA  ld C,(XWA+0x4d)
	extz	bc                                    ; FA89BD  extz BC
	ld	de, bc                                  ; FA89BF  ld DE,BC
	jr sub_FA8997__FA89D7                      ; FA89C1  jr T,0xfa89d7
sub_FA8997__FA89C3:
	extz	xhl                                   ; FA89C3  extz XHL
	ld	c, (xhl+0x75)                           ; FA89C5  ld C,(XHL+0x75)
	exts	bc                                    ; FA89C8  exts BC
	ld	hl, bc                                  ; FA89CA  ld HL,BC
	ld	a, (xix+77)                             ; FA89CC  ld A,(XIX+0x4d)
	extz	wa                                    ; FA89CF  extz WA
	ld	de, wa                                  ; FA89D1  ld DE,WA
	add	wa, bc                                 ; FA89D3  add WA,BC
	ld	de, wa                                  ; FA89D5  ld DE,WA
sub_FA8997__FA89D7:
	ld	c, (xix+60)                             ; FA89D7  ld C,(XIX+0x3c)
	pushw	bc                                   ; FA89DA  push BC
	ld	c, (xix+55)                             ; FA89DB  ld C,(XIX+0x37)
	exts	bc                                    ; FA89DE  exts BC
	pushw	bc                                   ; FA89E0  push BC
	pushw	de                                   ; FA89E1  push DE
	extpfx3 0x9E, 0x08, 0x04                   ; FA89E2  pushw (XIZ+0x08)
	calr (0xFA76D6 - 0xFA89E8)                 ; FA89E5  calr 0xfa76d6
	ld	de, wa                                  ; FA89E8  ld DE,WA
	ld	hl, (xiz+8)                             ; FA89EA  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FA89ED  extz XHL
	ld	hl, (xhl+37)                            ; FA89EF  ld HL,(XHL+0x25)
	extz	xhl                                   ; FA89F2  extz XHL
	ld	bc, (xhl+26)                            ; FA89F4  ld BC,(XHL+0x1a)
	and	bc, 0x2000                             ; FA89F7  and BC,0x2000
	inc	8, xsp                                 ; FA89FB  inc 0,XSP
	jr z, sub_FA8997__FA8A3E                   ; FA89FD  jr Z,0xfa8a3e
	extz	xhl                                   ; FA89FF  extz XHL
	ld	bc, (xhl+28)                            ; FA8A01  ld BC,(XHL+0x1c)
	and	bc, 0x2000                             ; FA8A04  and BC,0x2000
	ld	(xiz-2), bc                             ; FA8A08  ld (XIZ+0xfe),BC
	pushw	0                                    ; FA8A0B  push 0x0000
	pushw	5                                    ; FA8A0E  push 0x0005
	ld	c, (xix+78)                             ; FA8A11  ld C,(XIX+0x4e)
	extz	bc                                    ; FA8A14  extz BC
	ld	hl, bc                                  ; FA8A16  ld HL,BC
	ld	bc, (xiz+8)                             ; FA8A18  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA8A1B  extz XBC
	ld	iy, (xbc+35)                            ; FA8A1D  ld IY,(XBC+0x23)
	extz	xiy                                   ; FA8A20  extz XIY
	ld	ix, (xiy+51)                            ; FA8A22  ld IX,(XIY+0x33)
	jr z, sub_FA8997__FA8A2E                   ; FA8A25  jr Z,0xfa8a2e
	ld	iy, hl                                  ; FA8A27  ld IY,HL
	sub	iy, ix                                 ; FA8A29  sub IY,IX
	pushw	iy                                   ; FA8A2B  push IY
	jr sub_FA8997__FA8A33                      ; FA8A2C  jr T,0xfa8a33
sub_FA8997__FA8A2E:
	ld	bc, hl                                  ; FA8A2E  ld BC,HL
	add	bc, ix                                 ; FA8A30  add BC,IX
	pushw	bc                                   ; FA8A32  push BC
sub_FA8997__FA8A33:
	calr (0xFA7EE2 - 0xFA8A36)                 ; FA8A33  calr 0xfa7ee2
	exts	wa                                    ; FA8A36  exts WA
	ld	hl, wa                                  ; FA8A38  ld HL,WA
	inc	6, xsp                                 ; FA8A3A  inc 6,XSP
	jr sub_FA8997__FA8A45                      ; FA8A3C  jr T,0xfa8a45
sub_FA8997__FA8A3E:
	ld	c, (xix+78)                             ; FA8A3E  ld C,(XIX+0x4e)
	extz	bc                                    ; FA8A41  extz BC
	ld	hl, bc                                  ; FA8A43  ld HL,BC
sub_FA8997__FA8A45:
	ld	bc, hl                                  ; FA8A45  ld BC,HL
	sll	bc, 13                                 ; FA8A47  sll 0x0d,BC
	ld	ix, bc                                  ; FA8A4A  ld IX,BC
	or	ix, de                                  ; FA8A4C  or IX,DE
	ld	bc, hl                                  ; FA8A4E  ld BC,HL
	sll	bc, 10                                 ; FA8A50  sll 0x0a,BC
	or	bc, ix                                  ; FA8A53  or BC,IX
	set	7, bc                                  ; FA8A55  set 0x07,BC
	ld	wa, (xiz+8)                             ; FA8A58  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA8A5B  extz XWA
	ld	(xwa+63), bc                            ; FA8A5D  ld (XWA+0x3f),BC
	ld	bc, de                                  ; FA8A60  ld BC,DE
	set	7, bc                                  ; FA8A62  set 0x07,BC
	ld	wa, (xiz+8)                             ; FA8A65  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA8A68  extz XWA
	ld	(xwa+65), bc                            ; FA8A6A  ld (XWA+0x41),BC
	stdi16	(0x5A51), 0                         ; FA8A6D  ld (0x5a51),0x0000
	pop	xix                                    ; FA8A73  pop XIX
	popw	de                                    ; FA8A74  pop DE
	pop	xhl                                    ; FA8A75  pop XHL
	unlk32 xiz                                 ; FA8A76  unlk XIZ
	ret                                        ; FA8A78  ret
; --------------------------------------------------------------------------
; sub_FA8A79 -- 0xFA8A79..0xFA8BDC (356 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFA8C3C
; Inputs:  frame `link XIZ,-6`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x005A51
; Calls:   0xFA76D6 = sub_FA76D6, 0xFA7EE2 = Clamp_ToRange_LowByte
; Voice record: touches voice_record[+0x17(r), +0x23(r), +0x25(r), +0x3F(w), +0x41(w)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA8A79-0xFA8BDC
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FA8A79:
	link32 0xEE, 0x0C, 0xFA, 0xFF              ; FA8A79  link XIZ,0xfffa
	push	xhl                                   ; FA8A7D  push XHL
	pushw	de                                   ; FA8A7E  push DE
	push	xix                                   ; FA8A7F  push XIX
	ld	bc, (xiz+8)                             ; FA8A80  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA8A83  extz XBC
	ld	xwa, (xbc+23)                           ; FA8A85  ld XWA,(XBC+0x17)
	ld	xix, xwa                                ; FA8A88  ld XIX,XWA
	ld	hl, bc                                  ; FA8A8A  ld HL,BC
	extz	xbc                                   ; FA8A8C  extz XBC
	ld	hl, (xbc+35)                            ; FA8A8E  ld HL,(XBC+0x23)
	extz	xhl                                   ; FA8A91  extz XHL
	ld	bc, (xhl+6)                             ; FA8A93  ld BC,(XHL+0x06)
	and	bc, 0x200                              ; FA8A96  and BC,0x0200
	jr z, sub_FA8A79__FA8AAE                   ; FA8A9A  jr Z,0xfa8aae
	ld	c, (xwa+77)                             ; FA8A9C  ld C,(XWA+0x4d)
	extz	bc                                    ; FA8A9F  extz BC
	ld	(xiz-4), bc                             ; FA8AA1  ld (XIZ+0xfc),BC
	ld	c, (xwa+79)                             ; FA8AA4  ld C,(XWA+0x4f)
	extz	bc                                    ; FA8AA7  extz BC
	ld	(xiz-2), bc                             ; FA8AA9  ld (XIZ+0xfe),BC
	jr sub_FA8A79__FA8ACB                      ; FA8AAC  jr T,0xfa8acb
sub_FA8A79__FA8AAE:
	extz	xhl                                   ; FA8AAE  extz XHL
	ld	c, (xhl+0x75)                           ; FA8AB0  ld C,(XHL+0x75)
	exts	bc                                    ; FA8AB3  exts BC
	ld	hl, bc                                  ; FA8AB5  ld HL,BC
	ld	a, (xix+77)                             ; FA8AB7  ld A,(XIX+0x4d)
	extz	wa                                    ; FA8ABA  extz WA
	add	wa, bc                                 ; FA8ABC  add WA,BC
	ld	(xiz-4), wa                             ; FA8ABE  ld (XIZ+0xfc),WA
	ld	c, (xix+79)                             ; FA8AC1  ld C,(XIX+0x4f)
	extz	bc                                    ; FA8AC4  extz BC
	add	bc, hl                                 ; FA8AC6  add BC,HL
	ld	(xiz-2), bc                             ; FA8AC8  ld (XIZ+0xfe),BC
sub_FA8A79__FA8ACB:
	ld	c, (xix+60)                             ; FA8ACB  ld C,(XIX+0x3c)
	pushw	bc                                   ; FA8ACE  push BC
	ld	c, (xix+55)                             ; FA8ACF  ld C,(XIX+0x37)
	exts	bc                                    ; FA8AD2  exts BC
	pushw	bc                                   ; FA8AD4  push BC
	extpfx3 0x9E, 0xFC, 0x04                   ; FA8AD5  pushw (XIZ+0xfc)
	extpfx3 0x9E, 0x08, 0x04                   ; FA8AD8  pushw (XIZ+0x08)
	calr (0xFA76D6 - 0xFA8ADE)                 ; FA8ADB  calr 0xfa76d6
	ld	(xiz-4), wa                             ; FA8ADE  ld (XIZ+0xfc),WA
	ld	c, (xix+60)                             ; FA8AE1  ld C,(XIX+0x3c)
	pushw	bc                                   ; FA8AE4  push BC
	ld	c, (xix+55)                             ; FA8AE5  ld C,(XIX+0x37)
	exts	bc                                    ; FA8AE8  exts BC
	pushw	bc                                   ; FA8AEA  push BC
	extpfx3 0x9E, 0xFE, 0x04                   ; FA8AEB  pushw (XIZ+0xfe)
	extpfx3 0x9E, 0x08, 0x04                   ; FA8AEE  pushw (XIZ+0x08)
	calr (0xFA76D6 - 0xFA8AF4)                 ; FA8AF1  calr 0xfa76d6
	ld	(xiz-2), wa                             ; FA8AF4  ld (XIZ+0xfe),WA
	ld	hl, (xiz+8)                             ; FA8AF7  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FA8AFA  extz XHL
	ld	hl, (xhl+37)                            ; FA8AFC  ld HL,(XHL+0x25)
	extz	xhl                                   ; FA8AFF  extz XHL
	ld	bc, (xhl+26)                            ; FA8B01  ld BC,(XHL+0x1a)
	and	bc, 0x2000                             ; FA8B04  and BC,0x2000
	inc	8, xsp                                 ; FA8B08  inc 0,XSP
	inc	8, xsp                                 ; FA8B0A  inc 0,XSP
	jrl z, sub_FA8A79__FA8B9C                  ; FA8B0C  jrl Z,0xfa8b9c
	extz	xhl                                   ; FA8B0F  extz XHL
	ld	bc, (xhl+28)                            ; FA8B11  ld BC,(XHL+0x1c)
	and	bc, 0x2000                             ; FA8B14  and BC,0x2000
	ld	(xiz-6), bc                             ; FA8B18  ld (XIZ+0xfa),BC
	pushw	0                                    ; FA8B1B  push 0x0000
	pushw	5                                    ; FA8B1E  push 0x0005
	ld	c, (xix+78)                             ; FA8B21  ld C,(XIX+0x4e)
	extz	bc                                    ; FA8B24  extz BC
	ld	hl, bc                                  ; FA8B26  ld HL,BC
	ld	bc, (xiz+8)                             ; FA8B28  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA8B2B  extz XBC
	ld	iy, (xbc+35)                            ; FA8B2D  ld IY,(XBC+0x23)
	extz	xiy                                   ; FA8B30  extz XIY
	ld	de, (xiy+51)                            ; FA8B32  ld DE,(XIY+0x33)
	jr z, sub_FA8A79__FA8B66                   ; FA8B35  jr Z,0xfa8b66
	ld	iy, hl                                  ; FA8B37  ld IY,HL
	sub	iy, de                                 ; FA8B39  sub IY,DE
	pushw	iy                                   ; FA8B3B  push IY
	calr (0xFA7EE2 - 0xFA8B3F)                 ; FA8B3C  calr 0xfa7ee2
	exts	wa                                    ; FA8B3F  exts WA
	ld	hl, wa                                  ; FA8B41  ld HL,WA
	inc	6, xsp                                 ; FA8B43  inc 6,XSP
	pushw	0                                    ; FA8B45  push 0x0000
	pushw	5                                    ; FA8B48  push 0x0005
	ld	c, (xix+80)                             ; FA8B4B  ld C,(XIX+0x50)
	extz	bc                                    ; FA8B4E  extz BC
	ld	de, bc                                  ; FA8B50  ld DE,BC
	ld	bc, (xiz+8)                             ; FA8B52  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA8B55  extz XBC
	ld	iy, (xbc+35)                            ; FA8B57  ld IY,(XBC+0x23)
	extz	xiy                                   ; FA8B5A  extz XIY
	ld	bc, (xiy+51)                            ; FA8B5C  ld BC,(XIY+0x33)
	ld	iy, de                                  ; FA8B5F  ld IY,DE
	sub	iy, bc                                 ; FA8B61  sub IY,BC
	pushw	iy                                   ; FA8B63  push IY
	jr sub_FA8A79__FA8B91                      ; FA8B64  jr T,0xfa8b91
sub_FA8A79__FA8B66:
	ld	bc, hl                                  ; FA8B66  ld BC,HL
	add	bc, de                                 ; FA8B68  add BC,DE
	pushw	bc                                   ; FA8B6A  push BC
	calr (0xFA7EE2 - 0xFA8B6E)                 ; FA8B6B  calr 0xfa7ee2
	exts	wa                                    ; FA8B6E  exts WA
	ld	hl, wa                                  ; FA8B70  ld HL,WA
	inc	6, xsp                                 ; FA8B72  inc 6,XSP
	pushw	0                                    ; FA8B74  push 0x0000
	pushw	5                                    ; FA8B77  push 0x0005
	ld	c, (xix+80)                             ; FA8B7A  ld C,(XIX+0x50)
	extz	bc                                    ; FA8B7D  extz BC
	ld	de, bc                                  ; FA8B7F  ld DE,BC
	ld	bc, (xiz+8)                             ; FA8B81  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA8B84  extz XBC
	ld	iy, (xbc+35)                            ; FA8B86  ld IY,(XBC+0x23)
	extz	xiy                                   ; FA8B89  extz XIY
	ld	bc, (xiy+51)                            ; FA8B8B  ld BC,(XIY+0x33)
	add	bc, de                                 ; FA8B8E  add BC,DE
	pushw	bc                                   ; FA8B90  push BC
sub_FA8A79__FA8B91:
	calr (0xFA7EE2 - 0xFA8B94)                 ; FA8B91  calr 0xfa7ee2
	exts	wa                                    ; FA8B94  exts WA
	ld	de, wa                                  ; FA8B96  ld DE,WA
	inc	6, xsp                                 ; FA8B98  inc 6,XSP
	jr sub_FA8A79__FA8BAA                      ; FA8B9A  jr T,0xfa8baa
sub_FA8A79__FA8B9C:
	ld	c, (xix+78)                             ; FA8B9C  ld C,(XIX+0x4e)
	extz	bc                                    ; FA8B9F  extz BC
	ld	hl, bc                                  ; FA8BA1  ld HL,BC
	ld	a, (xix+80)                             ; FA8BA3  ld A,(XIX+0x50)
	extz	wa                                    ; FA8BA6  extz WA
	ld	de, wa                                  ; FA8BA8  ld DE,WA
sub_FA8A79__FA8BAA:
	ld	bc, hl                                  ; FA8BAA  ld BC,HL
	sll	bc, 13                                 ; FA8BAC  sll 0x0d,BC
	ld	hl, bc                                  ; FA8BAF  ld HL,BC
	extpfx3 0x9E, 0xFC, 0xE3                   ; FA8BB1  or HL,(XIZ+0xfc)
	ld	bc, de                                  ; FA8BB4  ld BC,DE
	sll	bc, 10                                 ; FA8BB6  sll 0x0a,BC
	or	bc, hl                                  ; FA8BB9  or BC,HL
	set	7, bc                                  ; FA8BBB  set 0x07,BC
	ld	wa, (xiz+8)                             ; FA8BBE  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA8BC1  extz XWA
	ld	(xwa+63), bc                            ; FA8BC3  ld (XWA+0x3f),BC
	ld	bc, (xiz+8)                             ; FA8BC6  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA8BC9  extz XBC
	ld	wa, (xiz-2)                             ; FA8BCB  ld WA,(XIZ+0xfe)
	ld	(xbc+65), wa                            ; FA8BCE  ld (XBC+0x41),WA
	stdi16	(0x5A51), 0                         ; FA8BD1  ld (0x5a51),0x0000
	pop	xix                                    ; FA8BD7  pop XIX
	popw	de                                    ; FA8BD8  pop DE
	pop	xhl                                    ; FA8BD9  pop XHL
	unlk32 xiz                                 ; FA8BDA  unlk XIZ
	ret                                        ; FA8BDC  ret
; --------------------------------------------------------------------------
; VoiceParam_DispatchOn_17_36 -- 0xFA8BDD..0xFA8C43 (103 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFB0B16 in VoiceRegs_Stage_A, 0xFB1F04 in VoiceRegs_Stage_B
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA78AB = Rec_StoreConsts_003F_0041, 0xFA866B = sub_FA866B
;          0xFA8759 = sub_FA8759, 0xFA888C = sub_FA888C
;          0xFA8997 = sub_FA8997, 0xFA8A79 = sub_FA8A79
; Arms:    6 computed-goto arm(s) inside this routine: 0xFA8C1D 0xFA8C23 0xFA8C29 0xFA8C2F 0xFA8C35 0xFA8C3B
; ★ THE NAME CLAIMS ONLY WHAT THE OPERANDS SAY.  The routine does
;      ld HL,(XIZ+0x08) / ld XBC,(XHL+0x17) / ld A,(XBC+0x36) / and A,0x07
;  -- follow the pointer field at +0x17 of the argument, take the byte at +0x36
;  of what it points to, keep three bits -- and switches on the result.  It does
;  NOT claim to know what field 0x36 means; nothing here reads that.
; ★ IT IS THE SAME ROUTINE AS VoiceParam_DispatchOn_17_11 (0xFA900A) WITH ONE
;  BYTE CHANGED.  The two are 64 bytes long, share their first twelve bytes and
;  their `ld XBC,(XHL+0x17)`, and differ semantically in exactly one byte: the
;  +0x36 here is +0x11 there.  Their remaining differences are the relocated
;  addresses of their own six-entry tables.  Checked byte by byte by
;  notes/prom_c_voiceparam_checks.py section 5.
; ⚠ INDEX 0 AND INDEX > 5 GO TO THE SAME PLACE.  Table entry 0 is 0xFA8C1D,
;  which is also the `jr UGT` target, so a zero field and an out-of-range field
;  are not distinguished.
; Voice record: touches voice_record[+0x17(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA8BDD-0xFA8C43
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the field it switches on MEANS, and what any of the six arms
;          does.  The name states the operand, not a purpose.
; --------------------------------------------------------------------------
VoiceParam_DispatchOn_17_36:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA8BDD  link XIZ,0x0000
	push	xhl                                   ; FA8BE1  push XHL
	ld	hl, (xiz+8)                             ; FA8BE2  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FA8BE5  extz XHL
	ld	xbc, (xhl+23)                           ; FA8BE7  ld XBC,(XHL+0x17)
	ld	a, (xbc+54)                             ; FA8BEA  ld A,(XBC+0x36)
	and	a, 7                                   ; FA8BED  and A,0x07
	extz	wa                                    ; FA8BF0  extz WA
	extz	xwa                                   ; FA8BF2  extz XWA
	cps	wa, 5                                  ; FA8BF4  cp WA,5
	jr ugt, VoiceParam_DispatchOn_17_36__FA8C1D ; FA8BF6  jr UGT,0xfa8c1d
	sll	wa, 2                                  ; FA8BF8  sll 0x02,WA
	add	xwa, 0xFA8C05                          ; FA8BFB  add XWA,0x00fa8c05
	ld	xwa, (xwa)                              ; FA8C01  ld XWA,(XWA)
	jp	(xwa)                                   ; FA8C03  jp T,XWA
; 6 x u32 computed-goto table, 0xFA8C05-0xFA8C1C, 24 bytes.
; THE ENTRY COUNT IS ESTABLISHED TWICE AND THE TWO AGREE: the `cp rr,5`
; guard before the `jr UGT` gives 6, and reading consecutive words while
; each is a plausible code address also gives 6.  The word after the last
; entry is not a plausible entry, so the table ends here rather than being
; assumed to.  (python3 notes/prom_c_jumptables.py 0xFA7E2C 0xFABE30;
; asserted per table by notes/prom_c_voiceparam_checks.py section 2.)
; Entry 0 is the SAME address the out-of-range guard branches to.
	.long 0x00FA8C1D	; 0xFA8C05  entry 0 -> 0xFA8C1D   (also the out-of-range arm)
	.long 0x00FA8C23	; 0xFA8C09  entry 1 -> 0xFA8C23
	.long 0x00FA8C29	; 0xFA8C0D  entry 2 -> 0xFA8C29
	.long 0x00FA8C2F	; 0xFA8C11  entry 3 -> 0xFA8C2F
	.long 0x00FA8C35	; 0xFA8C15  entry 4 -> 0xFA8C35
	.long 0x00FA8C3B	; 0xFA8C19  entry 5 -> 0xFA8C3B
VoiceParam_DispatchOn_17_36__FA8C1D:
	pushw	hl                                   ; FA8C1D  push HL
	calr (0xFA78AB - 0xFA8C21)                 ; FA8C1E  calr 0xfa78ab
	jr VoiceParam_DispatchOn_17_36__FA8C3F     ; FA8C21  jr T,0xfa8c3f
VoiceParam_DispatchOn_17_36__FA8C23:
	pushw	hl                                   ; FA8C23  push HL
	calr (0xFA866B - 0xFA8C27)                 ; FA8C24  calr 0xfa866b
	jr VoiceParam_DispatchOn_17_36__FA8C3F     ; FA8C27  jr T,0xfa8c3f
VoiceParam_DispatchOn_17_36__FA8C29:
	pushw	hl                                   ; FA8C29  push HL
	calr (0xFA8759 - 0xFA8C2D)                 ; FA8C2A  calr 0xfa8759
	jr VoiceParam_DispatchOn_17_36__FA8C3F     ; FA8C2D  jr T,0xfa8c3f
VoiceParam_DispatchOn_17_36__FA8C2F:
	pushw	hl                                   ; FA8C2F  push HL
	calr (0xFA888C - 0xFA8C33)                 ; FA8C30  calr 0xfa888c
	jr VoiceParam_DispatchOn_17_36__FA8C3F     ; FA8C33  jr T,0xfa8c3f
VoiceParam_DispatchOn_17_36__FA8C35:
	pushw	hl                                   ; FA8C35  push HL
	calr (0xFA8997 - 0xFA8C39)                 ; FA8C36  calr 0xfa8997
	jr VoiceParam_DispatchOn_17_36__FA8C3F     ; FA8C39  jr T,0xfa8c3f
VoiceParam_DispatchOn_17_36__FA8C3B:
	pushw	hl                                   ; FA8C3B  push HL
	calr (0xFA8A79 - 0xFA8C3F)                 ; FA8C3C  calr 0xfa8a79
VoiceParam_DispatchOn_17_36__FA8C3F:
	popw	bc                                    ; FA8C3F  pop BC
	pop	xhl                                    ; FA8C40  pop XHL
	unlk32 xiz                                 ; FA8C41  unlk XIZ
	ret                                        ; FA8C43  ret
; --------------------------------------------------------------------------
; sub_FA8C44 -- 0xFA8C44..0xFA8CEE (171 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFA9061
; Inputs:  frame `link XIZ,-8`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA778E = sub_FA778E, 0xFA77F3 = Add24_ClampTo120
;          0xFA7810 = sub_FA7810, 0xFA7EE2 = Clamp_ToRange_LowByte
; Voice record: touches voice_record[+0x17(r), +0x23(r), +0x25(r), +0x3F(w), +0x41(w)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA8C44-0xFA8CEE
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FA8C44:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FA8C44  link XIZ,0xfff8
	push	xhl                                   ; FA8C48  push XHL
	pushw	de                                   ; FA8C49  push DE
	push	xix                                   ; FA8C4A  push XIX
	ld	ix, (xiz+8)                             ; FA8C4B  ld IX,(XIZ+0x08)
	extz	xix                                   ; FA8C4E  extz XIX
	ld	xbc, (xix+23)                           ; FA8C50  ld XBC,(XIX+0x17)
	ld	(xiz-6), xbc                            ; FA8C53  ld (XIZ+0xfa),XBC
	ld	a, (xbc+19)                             ; FA8C56  ld A,(XBC+0x13)
	extz	wa                                    ; FA8C59  extz WA
	pushw	wa                                   ; FA8C5B  push WA
	pushw	ix                                   ; FA8C5C  push IX
	calr (0xFA778E - 0xFA8C60)                 ; FA8C5D  calr 0xfa778e
	ld	(xiz-2), wa                             ; FA8C60  ld (XIZ+0xfe),WA
	ld	hl, (xix+37)                            ; FA8C63  ld HL,(XIX+0x25)
	extz	xhl                                   ; FA8C66  extz XHL
	ld	bc, (xhl+26)                            ; FA8C68  ld BC,(XHL+0x1a)
	and	bc, 0x2000                             ; FA8C6B  and BC,0x2000
	pop	xiy                                    ; FA8C6F  pop XIY
	jr z, sub_FA8C44__FA8CB1                   ; FA8C70  jr Z,0xfa8cb1
	extz	xhl                                   ; FA8C72  extz XHL
	ld	bc, (xhl+28)                            ; FA8C74  ld BC,(XHL+0x1c)
	and	bc, 0x2000                             ; FA8C77  and BC,0x2000
	ld	(xiz-8), bc                             ; FA8C7B  ld (XIZ+0xf8),BC
	pushw	0                                    ; FA8C7E  push 0x0000
	pushw	5                                    ; FA8C81  push 0x0005
	ld	xiy, (xiz-6)                            ; FA8C84  ld XIY,(XIZ+0xfa)
	ld	c, (xiy+20)                             ; FA8C87  ld C,(XIY+0x14)
	extz	bc                                    ; FA8C8A  extz BC
	ld	hl, bc                                  ; FA8C8C  ld HL,BC
	extz	xix                                   ; FA8C8E  extz XIX
	ld	bc, (xix+35)                            ; FA8C90  ld BC,(XIX+0x23)
	extz	xbc                                   ; FA8C93  extz XBC
	ld	de, (xbc+51)                            ; FA8C95  ld DE,(XBC+0x33)
	jr z, sub_FA8C44__FA8CA1                   ; FA8C98  jr Z,0xfa8ca1
	ld	bc, hl                                  ; FA8C9A  ld BC,HL
	sub	bc, de                                 ; FA8C9C  sub BC,DE
	pushw	bc                                   ; FA8C9E  push BC
	jr sub_FA8C44__FA8CA6                      ; FA8C9F  jr T,0xfa8ca6
sub_FA8C44__FA8CA1:
	ld	bc, hl                                  ; FA8CA1  ld BC,HL
	add	bc, de                                 ; FA8CA3  add BC,DE
	pushw	bc                                   ; FA8CA5  push BC
sub_FA8C44__FA8CA6:
	calr (0xFA7EE2 - 0xFA8CA9)                 ; FA8CA6  calr 0xfa7ee2
	exts	wa                                    ; FA8CA9  exts WA
	ld	hl, wa                                  ; FA8CAB  ld HL,WA
	inc	6, xsp                                 ; FA8CAD  inc 6,XSP
	jr sub_FA8C44__FA8CBB                      ; FA8CAF  jr T,0xfa8cbb
sub_FA8C44__FA8CB1:
	ld	xbc, (xiz-6)                            ; FA8CB1  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+20)                             ; FA8CB4  ld A,(XBC+0x14)
	extz	wa                                    ; FA8CB7  extz WA
	ld	hl, wa                                  ; FA8CB9  ld HL,WA
sub_FA8C44__FA8CBB:
	ld	bc, hl                                  ; FA8CBB  ld BC,HL
	sll	bc, 13                                 ; FA8CBD  sll 0x0d,BC
	extpfx3 0x9E, 0xFE, 0xE1                   ; FA8CC0  or BC,(XIZ+0xfe)
	set	10, bc                                 ; FA8CC3  set 0x0a,BC
	extz	xix                                   ; FA8CC6  extz XIX
	ld	(xix+63), bc                            ; FA8CC8  ld (XIX+0x3f),BC
	ld	xbc, (xiz-6)                            ; FA8CCB  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+21)                             ; FA8CCE  ld A,(XBC+0x15)
	extz	wa                                    ; FA8CD1  extz WA
	pushw	wa                                   ; FA8CD3  push WA
	calr (0xFA77F3 - 0xFA8CD7)                 ; FA8CD4  calr 0xfa77f3
	ld	hl, wa                                  ; FA8CD7  ld HL,WA
	ld	xbc, (xiz-6)                            ; FA8CD9  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+22)                             ; FA8CDC  ld A,(XBC+0x16)
	pushw	wa                                   ; FA8CDF  push WA
	calr (0xFA7810 - 0xFA8CE3)                 ; FA8CE0  calr 0xfa7810
	or	wa, hl                                  ; FA8CE3  or WA,HL
	ld	(xix+65), wa                            ; FA8CE5  ld (XIX+0x41),WA
	pop	xbc                                    ; FA8CE8  pop XBC
	pop	xix                                    ; FA8CE9  pop XIX
	popw	de                                    ; FA8CEA  pop DE
	pop	xhl                                    ; FA8CEB  pop XHL
	unlk32 xiz                                 ; FA8CEC  unlk XIZ
	ret                                        ; FA8CEE  ret
; --------------------------------------------------------------------------
; sub_FA8CEF -- 0xFA8CEF..0xFA8D9A (172 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFA9067
; Inputs:  frame `link XIZ,-8`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA778E = sub_FA778E, 0xFA77F3 = Add24_ClampTo120
;          0xFA7810 = sub_FA7810, 0xFA7EE2 = Clamp_ToRange_LowByte
; Voice record: touches voice_record[+0x17(r), +0x23(r), +0x25(r), +0x3F(w), +0x41(w)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA8CEF-0xFA8D9A
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FA8CEF:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FA8CEF  link XIZ,0xfff8
	push	xhl                                   ; FA8CF3  push XHL
	pushw	de                                   ; FA8CF4  push DE
	push	xix                                   ; FA8CF5  push XIX
	ld	ix, (xiz+8)                             ; FA8CF6  ld IX,(XIZ+0x08)
	extz	xix                                   ; FA8CF9  extz XIX
	ld	xbc, (xix+23)                           ; FA8CFB  ld XBC,(XIX+0x17)
	ld	(xiz-6), xbc                            ; FA8CFE  ld (XIZ+0xfa),XBC
	ld	a, (xbc+19)                             ; FA8D01  ld A,(XBC+0x13)
	extz	wa                                    ; FA8D04  extz WA
	pushw	wa                                   ; FA8D06  push WA
	pushw	ix                                   ; FA8D07  push IX
	calr (0xFA778E - 0xFA8D0B)                 ; FA8D08  calr 0xfa778e
	ld	(xiz-2), wa                             ; FA8D0B  ld (XIZ+0xfe),WA
	ld	hl, (xix+37)                            ; FA8D0E  ld HL,(XIX+0x25)
	extz	xhl                                   ; FA8D11  extz XHL
	ld	bc, (xhl+26)                            ; FA8D13  ld BC,(XHL+0x1a)
	and	bc, 0x2000                             ; FA8D16  and BC,0x2000
	pop	xiy                                    ; FA8D1A  pop XIY
	jr z, sub_FA8CEF__FA8D5C                   ; FA8D1B  jr Z,0xfa8d5c
	extz	xhl                                   ; FA8D1D  extz XHL
	ld	bc, (xhl+28)                            ; FA8D1F  ld BC,(XHL+0x1c)
	and	bc, 0x2000                             ; FA8D22  and BC,0x2000
	ld	(xiz-8), bc                             ; FA8D26  ld (XIZ+0xf8),BC
	pushw	0                                    ; FA8D29  push 0x0000
	pushw	5                                    ; FA8D2C  push 0x0005
	ld	xiy, (xiz-6)                            ; FA8D2F  ld XIY,(XIZ+0xfa)
	ld	c, (xiy+20)                             ; FA8D32  ld C,(XIY+0x14)
	extz	bc                                    ; FA8D35  extz BC
	ld	hl, bc                                  ; FA8D37  ld HL,BC
	extz	xix                                   ; FA8D39  extz XIX
	ld	bc, (xix+35)                            ; FA8D3B  ld BC,(XIX+0x23)
	extz	xbc                                   ; FA8D3E  extz XBC
	ld	de, (xbc+51)                            ; FA8D40  ld DE,(XBC+0x33)
	jr z, sub_FA8CEF__FA8D4C                   ; FA8D43  jr Z,0xfa8d4c
	ld	bc, hl                                  ; FA8D45  ld BC,HL
	sub	bc, de                                 ; FA8D47  sub BC,DE
	pushw	bc                                   ; FA8D49  push BC
	jr sub_FA8CEF__FA8D51                      ; FA8D4A  jr T,0xfa8d51
sub_FA8CEF__FA8D4C:
	ld	bc, hl                                  ; FA8D4C  ld BC,HL
	add	bc, de                                 ; FA8D4E  add BC,DE
	pushw	bc                                   ; FA8D50  push BC
sub_FA8CEF__FA8D51:
	calr (0xFA7EE2 - 0xFA8D54)                 ; FA8D51  calr 0xfa7ee2
	exts	wa                                    ; FA8D54  exts WA
	ld	hl, wa                                  ; FA8D56  ld HL,WA
	inc	6, xsp                                 ; FA8D58  inc 6,XSP
	jr sub_FA8CEF__FA8D66                      ; FA8D5A  jr T,0xfa8d66
sub_FA8CEF__FA8D5C:
	ld	xbc, (xiz-6)                            ; FA8D5C  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+20)                             ; FA8D5F  ld A,(XBC+0x14)
	extz	wa                                    ; FA8D62  extz WA
	ld	hl, wa                                  ; FA8D64  ld HL,WA
sub_FA8CEF__FA8D66:
	ld	bc, hl                                  ; FA8D66  ld BC,HL
	sll	bc, 13                                 ; FA8D68  sll 0x0d,BC
	extpfx3 0x9E, 0xFE, 0xE1                   ; FA8D6B  or BC,(XIZ+0xfe)
	or	bc, 0x480                               ; FA8D6E  or BC,0x0480
	extz	xix                                   ; FA8D72  extz XIX
	ld	(xix+63), bc                            ; FA8D74  ld (XIX+0x3f),BC
	ld	xbc, (xiz-6)                            ; FA8D77  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+21)                             ; FA8D7A  ld A,(XBC+0x15)
	extz	wa                                    ; FA8D7D  extz WA
	pushw	wa                                   ; FA8D7F  push WA
	calr (0xFA77F3 - 0xFA8D83)                 ; FA8D80  calr 0xfa77f3
	ld	hl, wa                                  ; FA8D83  ld HL,WA
	ld	xbc, (xiz-6)                            ; FA8D85  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+22)                             ; FA8D88  ld A,(XBC+0x16)
	pushw	wa                                   ; FA8D8B  push WA
	calr (0xFA7810 - 0xFA8D8F)                 ; FA8D8C  calr 0xfa7810
	or	wa, hl                                  ; FA8D8F  or WA,HL
	ld	(xix+65), wa                            ; FA8D91  ld (XIX+0x41),WA
	pop	xbc                                    ; FA8D94  pop XBC
	pop	xix                                    ; FA8D95  pop XIX
	popw	de                                    ; FA8D96  pop DE
	pop	xhl                                    ; FA8D97  pop XHL
	unlk32 xiz                                 ; FA8D98  unlk XIZ
	ret                                        ; FA8D9A  ret
; --------------------------------------------------------------------------
; sub_FA8D9B -- 0xFA8D9B..0xFA8E46 (172 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFA906D
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x005A51
; Calls:   0xFA778E = sub_FA778E, 0xFA7EE2 = Clamp_ToRange_LowByte
; Voice record: touches voice_record[+0x17(r), +0x23(r), +0x25(r), +0x3F(w), +0x41(w)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA8D9B-0xFA8E46
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FA8D9B:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FA8D9B  link XIZ,0xfffc
	push	xhl                                   ; FA8D9F  push XHL
	pushw	de                                   ; FA8DA0  push DE
	push	xix                                   ; FA8DA1  push XIX
	ld	bc, (xiz+8)                             ; FA8DA2  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA8DA5  extz XBC
	ld	xwa, (xbc+23)                           ; FA8DA7  ld XWA,(XBC+0x17)
	ld	xix, xwa                                ; FA8DAA  ld XIX,XWA
	ld	c, (xwa+19)                             ; FA8DAC  ld C,(XWA+0x13)
	extz	bc                                    ; FA8DAF  extz BC
	pushw	bc                                   ; FA8DB1  push BC
	extpfx3 0x9E, 0x08, 0x04                   ; FA8DB2  pushw (XIZ+0x08)
	calr (0xFA778E - 0xFA8DB8)                 ; FA8DB5  calr 0xfa778e
	ld	(xiz-2), wa                             ; FA8DB8  ld (XIZ+0xfe),WA
	ld	hl, (xiz+8)                             ; FA8DBB  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FA8DBE  extz XHL
	ld	hl, (xhl+37)                            ; FA8DC0  ld HL,(XHL+0x25)
	extz	xhl                                   ; FA8DC3  extz XHL
	ld	bc, (xhl+26)                            ; FA8DC5  ld BC,(XHL+0x1a)
	and	bc, 0x2000                             ; FA8DC8  and BC,0x2000
	pop	xiy                                    ; FA8DCC  pop XIY
	jr z, sub_FA8D9B__FA8E0E                   ; FA8DCD  jr Z,0xfa8e0e
	extz	xhl                                   ; FA8DCF  extz XHL
	ld	bc, (xhl+28)                            ; FA8DD1  ld BC,(XHL+0x1c)
	and	bc, 0x2000                             ; FA8DD4  and BC,0x2000
	ld	(xiz-4), bc                             ; FA8DD8  ld (XIZ+0xfc),BC
	pushw	0                                    ; FA8DDB  push 0x0000
	pushw	5                                    ; FA8DDE  push 0x0005
	ld	c, (xix+20)                             ; FA8DE1  ld C,(XIX+0x14)
	extz	bc                                    ; FA8DE4  extz BC
	ld	hl, bc                                  ; FA8DE6  ld HL,BC
	ld	bc, (xiz+8)                             ; FA8DE8  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA8DEB  extz XBC
	ld	iy, (xbc+35)                            ; FA8DED  ld IY,(XBC+0x23)
	extz	xiy                                   ; FA8DF0  extz XIY
	ld	de, (xiy+51)                            ; FA8DF2  ld DE,(XIY+0x33)
	jr z, sub_FA8D9B__FA8DFE                   ; FA8DF5  jr Z,0xfa8dfe
	ld	iy, hl                                  ; FA8DF7  ld IY,HL
	sub	iy, de                                 ; FA8DF9  sub IY,DE
	pushw	iy                                   ; FA8DFB  push IY
	jr sub_FA8D9B__FA8E03                      ; FA8DFC  jr T,0xfa8e03
sub_FA8D9B__FA8DFE:
	ld	bc, hl                                  ; FA8DFE  ld BC,HL
	add	bc, de                                 ; FA8E00  add BC,DE
	pushw	bc                                   ; FA8E02  push BC
sub_FA8D9B__FA8E03:
	calr (0xFA7EE2 - 0xFA8E06)                 ; FA8E03  calr 0xfa7ee2
	exts	wa                                    ; FA8E06  exts WA
	ld	hl, wa                                  ; FA8E08  ld HL,WA
	inc	6, xsp                                 ; FA8E0A  inc 6,XSP
	jr sub_FA8D9B__FA8E15                      ; FA8E0C  jr T,0xfa8e15
sub_FA8D9B__FA8E0E:
	ld	c, (xix+20)                             ; FA8E0E  ld C,(XIX+0x14)
	extz	bc                                    ; FA8E11  extz BC
	ld	hl, bc                                  ; FA8E13  ld HL,BC
sub_FA8D9B__FA8E15:
	ld	de, hl                                  ; FA8E15  ld DE,HL
	sll	de, 13                                 ; FA8E17  sll 0x0d,DE
	ld	ix, (xiz-2)                             ; FA8E1A  ld IX,(XIZ+0xfe)
	ld	bc, de                                  ; FA8E1D  ld BC,DE
	or	bc, ix                                  ; FA8E1F  or BC,IX
	ld	(xiz-4), bc                             ; FA8E21  ld (XIZ+0xfc),BC
	ld	iy, hl                                  ; FA8E24  ld IY,HL
	sll	iy, 10                                 ; FA8E26  sll 0x0a,IY
	or	bc, iy                                  ; FA8E29  or BC,IY
	ld	wa, (xiz+8)                             ; FA8E2B  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA8E2E  extz XWA
	ld	(xwa+63), bc                            ; FA8E30  ld (XWA+0x3f),BC
	ld	bc, (xiz+8)                             ; FA8E33  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA8E36  extz XBC
	ld	(xbc+65), ix                            ; FA8E38  ld (XBC+0x41),IX
	stdi16	(0x5A51), 0                         ; FA8E3B  ld (0x5a51),0x0000
	pop	xix                                    ; FA8E41  pop XIX
	popw	de                                    ; FA8E42  pop DE
	pop	xhl                                    ; FA8E43  pop XHL
	unlk32 xiz                                 ; FA8E44  unlk XIZ
	ret                                        ; FA8E46  ret
; --------------------------------------------------------------------------
; sub_FA8E47 -- 0xFA8E47..0xFA8EF6 (176 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFA9073
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x005A51
; Calls:   0xFA778E = sub_FA778E, 0xFA7EE2 = Clamp_ToRange_LowByte
; Voice record: touches voice_record[+0x17(r), +0x23(r), +0x25(r), +0x3F(w), +0x41(w)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA8E47-0xFA8EF6
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FA8E47:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FA8E47  link XIZ,0xfffc
	push	xhl                                   ; FA8E4B  push XHL
	pushw	de                                   ; FA8E4C  push DE
	push	xix                                   ; FA8E4D  push XIX
	ld	bc, (xiz+8)                             ; FA8E4E  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA8E51  extz XBC
	ld	xwa, (xbc+23)                           ; FA8E53  ld XWA,(XBC+0x17)
	ld	xix, xwa                                ; FA8E56  ld XIX,XWA
	ld	c, (xwa+19)                             ; FA8E58  ld C,(XWA+0x13)
	extz	bc                                    ; FA8E5B  extz BC
	pushw	bc                                   ; FA8E5D  push BC
	extpfx3 0x9E, 0x08, 0x04                   ; FA8E5E  pushw (XIZ+0x08)
	calr (0xFA778E - 0xFA8E64)                 ; FA8E61  calr 0xfa778e
	ld	(xiz-2), wa                             ; FA8E64  ld (XIZ+0xfe),WA
	ld	hl, (xiz+8)                             ; FA8E67  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FA8E6A  extz XHL
	ld	hl, (xhl+37)                            ; FA8E6C  ld HL,(XHL+0x25)
	extz	xhl                                   ; FA8E6F  extz XHL
	ld	bc, (xhl+26)                            ; FA8E71  ld BC,(XHL+0x1a)
	and	bc, 0x2000                             ; FA8E74  and BC,0x2000
	pop	xiy                                    ; FA8E78  pop XIY
	jr z, sub_FA8E47__FA8EBA                   ; FA8E79  jr Z,0xfa8eba
	extz	xhl                                   ; FA8E7B  extz XHL
	ld	bc, (xhl+28)                            ; FA8E7D  ld BC,(XHL+0x1c)
	and	bc, 0x2000                             ; FA8E80  and BC,0x2000
	ld	(xiz-4), bc                             ; FA8E84  ld (XIZ+0xfc),BC
	pushw	0                                    ; FA8E87  push 0x0000
	pushw	5                                    ; FA8E8A  push 0x0005
	ld	c, (xix+20)                             ; FA8E8D  ld C,(XIX+0x14)
	extz	bc                                    ; FA8E90  extz BC
	ld	hl, bc                                  ; FA8E92  ld HL,BC
	ld	bc, (xiz+8)                             ; FA8E94  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA8E97  extz XBC
	ld	iy, (xbc+35)                            ; FA8E99  ld IY,(XBC+0x23)
	extz	xiy                                   ; FA8E9C  extz XIY
	ld	de, (xiy+51)                            ; FA8E9E  ld DE,(XIY+0x33)
	jr z, sub_FA8E47__FA8EAA                   ; FA8EA1  jr Z,0xfa8eaa
	ld	iy, hl                                  ; FA8EA3  ld IY,HL
	sub	iy, de                                 ; FA8EA5  sub IY,DE
	pushw	iy                                   ; FA8EA7  push IY
	jr sub_FA8E47__FA8EAF                      ; FA8EA8  jr T,0xfa8eaf
sub_FA8E47__FA8EAA:
	ld	bc, hl                                  ; FA8EAA  ld BC,HL
	add	bc, de                                 ; FA8EAC  add BC,DE
	pushw	bc                                   ; FA8EAE  push BC
sub_FA8E47__FA8EAF:
	calr (0xFA7EE2 - 0xFA8EB2)                 ; FA8EAF  calr 0xfa7ee2
	exts	wa                                    ; FA8EB2  exts WA
	ld	hl, wa                                  ; FA8EB4  ld HL,WA
	inc	6, xsp                                 ; FA8EB6  inc 6,XSP
	jr sub_FA8E47__FA8EC1                      ; FA8EB8  jr T,0xfa8ec1
sub_FA8E47__FA8EBA:
	ld	c, (xix+20)                             ; FA8EBA  ld C,(XIX+0x14)
	extz	bc                                    ; FA8EBD  extz BC
	ld	hl, bc                                  ; FA8EBF  ld HL,BC
sub_FA8E47__FA8EC1:
	ld	bc, hl                                  ; FA8EC1  ld BC,HL
	sll	bc, 13                                 ; FA8EC3  sll 0x0d,BC
	ld	de, bc                                  ; FA8EC6  ld DE,BC
	extpfx3 0x9E, 0xFE, 0xE2                   ; FA8EC8  or DE,(XIZ+0xfe)
	ld	bc, hl                                  ; FA8ECB  ld BC,HL
	sll	bc, 10                                 ; FA8ECD  sll 0x0a,BC
	or	bc, de                                  ; FA8ED0  or BC,DE
	set	7, bc                                  ; FA8ED2  set 0x07,BC
	ld	wa, (xiz+8)                             ; FA8ED5  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA8ED8  extz XWA
	ld	(xwa+63), bc                            ; FA8EDA  ld (XWA+0x3f),BC
	ld	bc, (xiz-2)                             ; FA8EDD  ld BC,(XIZ+0xfe)
	set	7, bc                                  ; FA8EE0  set 0x07,BC
	ld	wa, (xiz+8)                             ; FA8EE3  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA8EE6  extz XWA
	ld	(xwa+65), bc                            ; FA8EE8  ld (XWA+0x41),BC
	stdi16	(0x5A51), 0                         ; FA8EEB  ld (0x5a51),0x0000
	pop	xix                                    ; FA8EF1  pop XIX
	popw	de                                    ; FA8EF2  pop DE
	pop	xhl                                    ; FA8EF3  pop XHL
	unlk32 xiz                                 ; FA8EF4  unlk XIZ
	ret                                        ; FA8EF6  ret
; --------------------------------------------------------------------------
; sub_FA8EF7 -- 0xFA8EF7..0xFA9009 (275 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFA9079
; Inputs:  frame `link XIZ,-6`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x005A51
; Calls:   0xFA778E = sub_FA778E, 0xFA7EE2 = Clamp_ToRange_LowByte
; Voice record: touches voice_record[+0x17(r), +0x23(r), +0x25(r), +0x3F(w), +0x41(w)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA8EF7-0xFA9009
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FA8EF7:
	link32 0xEE, 0x0C, 0xFA, 0xFF              ; FA8EF7  link XIZ,0xfffa
	push	xhl                                   ; FA8EFB  push XHL
	pushw	de                                   ; FA8EFC  push DE
	push	xix                                   ; FA8EFD  push XIX
	ld	bc, (xiz+8)                             ; FA8EFE  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA8F01  extz XBC
	ld	xwa, (xbc+23)                           ; FA8F03  ld XWA,(XBC+0x17)
	ld	xix, xwa                                ; FA8F06  ld XIX,XWA
	ld	c, (xwa+19)                             ; FA8F08  ld C,(XWA+0x13)
	extz	bc                                    ; FA8F0B  extz BC
	pushw	bc                                   ; FA8F0D  push BC
	extpfx3 0x9E, 0x08, 0x04                   ; FA8F0E  pushw (XIZ+0x08)
	calr (0xFA778E - 0xFA8F14)                 ; FA8F11  calr 0xfa778e
	ld	(xiz-4), wa                             ; FA8F14  ld (XIZ+0xfc),WA
	ld	c, (xix+21)                             ; FA8F17  ld C,(XIX+0x15)
	extz	bc                                    ; FA8F1A  extz BC
	pushw	bc                                   ; FA8F1C  push BC
	extpfx3 0x9E, 0x08, 0x04                   ; FA8F1D  pushw (XIZ+0x08)
	calr (0xFA778E - 0xFA8F23)                 ; FA8F20  calr 0xfa778e
	ld	(xiz-2), wa                             ; FA8F23  ld (XIZ+0xfe),WA
	ld	hl, (xiz+8)                             ; FA8F26  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FA8F29  extz XHL
	ld	hl, (xhl+37)                            ; FA8F2B  ld HL,(XHL+0x25)
	extz	xhl                                   ; FA8F2E  extz XHL
	ld	bc, (xhl+26)                            ; FA8F30  ld BC,(XHL+0x1a)
	and	bc, 0x2000                             ; FA8F33  and BC,0x2000
	inc	8, xsp                                 ; FA8F37  inc 0,XSP
	jrl z, sub_FA8EF7__FA8FC9                  ; FA8F39  jrl Z,0xfa8fc9
	extz	xhl                                   ; FA8F3C  extz XHL
	ld	bc, (xhl+28)                            ; FA8F3E  ld BC,(XHL+0x1c)
	and	bc, 0x2000                             ; FA8F41  and BC,0x2000
	ld	(xiz-6), bc                             ; FA8F45  ld (XIZ+0xfa),BC
	pushw	0                                    ; FA8F48  push 0x0000
	pushw	5                                    ; FA8F4B  push 0x0005
	ld	c, (xix+20)                             ; FA8F4E  ld C,(XIX+0x14)
	extz	bc                                    ; FA8F51  extz BC
	ld	hl, bc                                  ; FA8F53  ld HL,BC
	ld	bc, (xiz+8)                             ; FA8F55  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA8F58  extz XBC
	ld	iy, (xbc+35)                            ; FA8F5A  ld IY,(XBC+0x23)
	extz	xiy                                   ; FA8F5D  extz XIY
	ld	de, (xiy+51)                            ; FA8F5F  ld DE,(XIY+0x33)
	jr z, sub_FA8EF7__FA8F93                   ; FA8F62  jr Z,0xfa8f93
	ld	iy, hl                                  ; FA8F64  ld IY,HL
	sub	iy, de                                 ; FA8F66  sub IY,DE
	pushw	iy                                   ; FA8F68  push IY
	calr (0xFA7EE2 - 0xFA8F6C)                 ; FA8F69  calr 0xfa7ee2
	exts	wa                                    ; FA8F6C  exts WA
	ld	hl, wa                                  ; FA8F6E  ld HL,WA
	inc	6, xsp                                 ; FA8F70  inc 6,XSP
	pushw	0                                    ; FA8F72  push 0x0000
	pushw	5                                    ; FA8F75  push 0x0005
	ld	c, (xix+22)                             ; FA8F78  ld C,(XIX+0x16)
	extz	bc                                    ; FA8F7B  extz BC
	ld	de, bc                                  ; FA8F7D  ld DE,BC
	ld	bc, (xiz+8)                             ; FA8F7F  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA8F82  extz XBC
	ld	iy, (xbc+35)                            ; FA8F84  ld IY,(XBC+0x23)
	extz	xiy                                   ; FA8F87  extz XIY
	ld	bc, (xiy+51)                            ; FA8F89  ld BC,(XIY+0x33)
	ld	iy, de                                  ; FA8F8C  ld IY,DE
	sub	iy, bc                                 ; FA8F8E  sub IY,BC
	pushw	iy                                   ; FA8F90  push IY
	jr sub_FA8EF7__FA8FBE                      ; FA8F91  jr T,0xfa8fbe
sub_FA8EF7__FA8F93:
	ld	bc, hl                                  ; FA8F93  ld BC,HL
	add	bc, de                                 ; FA8F95  add BC,DE
	pushw	bc                                   ; FA8F97  push BC
	calr (0xFA7EE2 - 0xFA8F9B)                 ; FA8F98  calr 0xfa7ee2
	exts	wa                                    ; FA8F9B  exts WA
	ld	hl, wa                                  ; FA8F9D  ld HL,WA
	inc	6, xsp                                 ; FA8F9F  inc 6,XSP
	pushw	0                                    ; FA8FA1  push 0x0000
	pushw	5                                    ; FA8FA4  push 0x0005
	ld	c, (xix+22)                             ; FA8FA7  ld C,(XIX+0x16)
	extz	bc                                    ; FA8FAA  extz BC
	ld	de, bc                                  ; FA8FAC  ld DE,BC
	ld	bc, (xiz+8)                             ; FA8FAE  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA8FB1  extz XBC
	ld	iy, (xbc+35)                            ; FA8FB3  ld IY,(XBC+0x23)
	extz	xiy                                   ; FA8FB6  extz XIY
	ld	bc, (xiy+51)                            ; FA8FB8  ld BC,(XIY+0x33)
	add	bc, de                                 ; FA8FBB  add BC,DE
	pushw	bc                                   ; FA8FBD  push BC
sub_FA8EF7__FA8FBE:
	calr (0xFA7EE2 - 0xFA8FC1)                 ; FA8FBE  calr 0xfa7ee2
	exts	wa                                    ; FA8FC1  exts WA
	ld	de, wa                                  ; FA8FC3  ld DE,WA
	inc	6, xsp                                 ; FA8FC5  inc 6,XSP
	jr sub_FA8EF7__FA8FD7                      ; FA8FC7  jr T,0xfa8fd7
sub_FA8EF7__FA8FC9:
	ld	c, (xix+20)                             ; FA8FC9  ld C,(XIX+0x14)
	extz	bc                                    ; FA8FCC  extz BC
	ld	hl, bc                                  ; FA8FCE  ld HL,BC
	ld	a, (xix+22)                             ; FA8FD0  ld A,(XIX+0x16)
	extz	wa                                    ; FA8FD3  extz WA
	ld	de, wa                                  ; FA8FD5  ld DE,WA
sub_FA8EF7__FA8FD7:
	ld	bc, hl                                  ; FA8FD7  ld BC,HL
	sll	bc, 13                                 ; FA8FD9  sll 0x0d,BC
	ld	hl, bc                                  ; FA8FDC  ld HL,BC
	extpfx3 0x9E, 0xFC, 0xE3                   ; FA8FDE  or HL,(XIZ+0xfc)
	ld	bc, de                                  ; FA8FE1  ld BC,DE
	sll	bc, 10                                 ; FA8FE3  sll 0x0a,BC
	or	bc, hl                                  ; FA8FE6  or BC,HL
	set	7, bc                                  ; FA8FE8  set 0x07,BC
	ld	wa, (xiz+8)                             ; FA8FEB  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA8FEE  extz XWA
	ld	(xwa+63), bc                            ; FA8FF0  ld (XWA+0x3f),BC
	ld	bc, (xiz+8)                             ; FA8FF3  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA8FF6  extz XBC
	ld	wa, (xiz-2)                             ; FA8FF8  ld WA,(XIZ+0xfe)
	ld	(xbc+65), wa                            ; FA8FFB  ld (XBC+0x41),WA
	stdi16	(0x5A51), 0                         ; FA8FFE  ld (0x5a51),0x0000
	pop	xix                                    ; FA9004  pop XIX
	popw	de                                    ; FA9005  pop DE
	pop	xhl                                    ; FA9006  pop XHL
	unlk32 xiz                                 ; FA9007  unlk XIZ
	ret                                        ; FA9009  ret
; --------------------------------------------------------------------------
; VoiceParam_DispatchOn_17_11 -- 0xFA900A..0xFA9080 (119 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFB282F in VoiceRegs_Stage_C, 0xFB2F04 in VoiceRegs_Stage_D
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D766, 0x00D768
; Calls:   0xFA78AB = Rec_StoreConsts_003F_0041, 0xFA8C44 = sub_FA8C44
;          0xFA8CEF = sub_FA8CEF, 0xFA8D9B = sub_FA8D9B
;          0xFA8E47 = sub_FA8E47, 0xFA8EF7 = sub_FA8EF7
; Arms:    6 computed-goto arm(s) inside this routine: 0xFA904A 0xFA9060 0xFA9066 0xFA906C 0xFA9072 0xFA9078
; ★ Same shape as VoiceParam_DispatchOn_17_36 (0xFA8BDD): follow the pointer at
;  +0x17 of the argument, take the byte at +0x11 of the target, mask with 7, and
;  switch.  See that routine's header; the two differ in one semantic byte.
; ⚠ Table entry 0 is 0xFA904A, which is also the `jr UGT` target.
; Voice record: touches voice_record[+0x17(r), +0x3F(r), +0x41(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA900A-0xFA9080
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the field it switches on MEANS, and what any of the six arms
;          does.  The name states the operand, not a purpose.
; --------------------------------------------------------------------------
VoiceParam_DispatchOn_17_11:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA900A  link XIZ,0x0000
	push	xhl                                   ; FA900E  push XHL
	ld	hl, (xiz+8)                             ; FA900F  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FA9012  extz XHL
	ld	xbc, (xhl+23)                           ; FA9014  ld XBC,(XHL+0x17)
	ld	a, (xbc+17)                             ; FA9017  ld A,(XBC+0x11)
	and	a, 7                                   ; FA901A  and A,0x07
	extz	wa                                    ; FA901D  extz WA
	extz	xwa                                   ; FA901F  extz XWA
	cps	wa, 5                                  ; FA9021  cp WA,5
	jr ugt, VoiceParam_DispatchOn_17_11__FA904A ; FA9023  jr UGT,0xfa904a
	sll	wa, 2                                  ; FA9025  sll 0x02,WA
	add	xwa, 0xFA9032                          ; FA9028  add XWA,0x00fa9032
	ld	xwa, (xwa)                              ; FA902E  ld XWA,(XWA)
	jp	(xwa)                                   ; FA9030  jp T,XWA
; 6 x u32 computed-goto table, 0xFA9032-0xFA9049, 24 bytes.
; THE ENTRY COUNT IS ESTABLISHED TWICE AND THE TWO AGREE: the `cp rr,5`
; guard before the `jr UGT` gives 6, and reading consecutive words while
; each is a plausible code address also gives 6.  The word after the last
; entry is not a plausible entry, so the table ends here rather than being
; assumed to.  (python3 notes/prom_c_jumptables.py 0xFA7E2C 0xFABE30;
; asserted per table by notes/prom_c_voiceparam_checks.py section 2.)
; Entry 0 is the SAME address the out-of-range guard branches to.
	.long 0x00FA904A	; 0xFA9032  entry 0 -> 0xFA904A   (also the out-of-range arm)
	.long 0x00FA9060	; 0xFA9036  entry 1 -> 0xFA9060
	.long 0x00FA9066	; 0xFA903A  entry 2 -> 0xFA9066
	.long 0x00FA906C	; 0xFA903E  entry 3 -> 0xFA906C
	.long 0x00FA9072	; 0xFA9042  entry 4 -> 0xFA9072
	.long 0x00FA9078	; 0xFA9046  entry 5 -> 0xFA9078
VoiceParam_DispatchOn_17_11__FA904A:
	pushw	hl                                   ; FA904A  push HL
	calr (0xFA78AB - 0xFA904E)                 ; FA904B  calr 0xfa78ab
	ld	bc, (xhl+63)                            ; FA904E  ld BC,(XHL+0x3f)
	stw_da	(0xD766), bc                        ; FA9051  ld (0x00d766),BC
	ld	bc, (xhl+65)                            ; FA9056  ld BC,(XHL+0x41)
	stw_da	(0xD768), bc                        ; FA9059  ld (0x00d768),BC
	jr VoiceParam_DispatchOn_17_11__FA907C     ; FA905E  jr T,0xfa907c
VoiceParam_DispatchOn_17_11__FA9060:
	pushw	hl                                   ; FA9060  push HL
	calr (0xFA8C44 - 0xFA9064)                 ; FA9061  calr 0xfa8c44
	jr VoiceParam_DispatchOn_17_11__FA907C     ; FA9064  jr T,0xfa907c
VoiceParam_DispatchOn_17_11__FA9066:
	pushw	hl                                   ; FA9066  push HL
	calr (0xFA8CEF - 0xFA906A)                 ; FA9067  calr 0xfa8cef
	jr VoiceParam_DispatchOn_17_11__FA907C     ; FA906A  jr T,0xfa907c
VoiceParam_DispatchOn_17_11__FA906C:
	pushw	hl                                   ; FA906C  push HL
	calr (0xFA8D9B - 0xFA9070)                 ; FA906D  calr 0xfa8d9b
	jr VoiceParam_DispatchOn_17_11__FA907C     ; FA9070  jr T,0xfa907c
VoiceParam_DispatchOn_17_11__FA9072:
	pushw	hl                                   ; FA9072  push HL
	calr (0xFA8E47 - 0xFA9076)                 ; FA9073  calr 0xfa8e47
	jr VoiceParam_DispatchOn_17_11__FA907C     ; FA9076  jr T,0xfa907c
VoiceParam_DispatchOn_17_11__FA9078:
	pushw	hl                                   ; FA9078  push HL
	calr (0xFA8EF7 - 0xFA907C)                 ; FA9079  calr 0xfa8ef7
VoiceParam_DispatchOn_17_11__FA907C:
	popw	bc                                    ; FA907C  pop BC
	pop	xhl                                    ; FA907D  pop XHL
	unlk32 xiz                                 ; FA907E  unlk XIZ
	ret                                        ; FA9080  ret
; --------------------------------------------------------------------------
; Voice_StagePair_Reg0100_0140_First -- 0xFA9081..0xFA9104 (132 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFA91EF 0xFA92F9
; Inputs:  frame `link XIZ,-2`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA76B2 = Clamp_36_to_120
; Voice record: touches voice_record[+0x23(r), +0x25(r), +0x3F(r), +0x41(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA9081-0xFA9104
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ WHAT IT STAGES: words 4 and 5 of the 0x0010C000 staging struct -- registers
;          0x0100 + chan and 0x0140 + chan -- and NOTHING else.  `lda XIX,0x00d75e`
;          (0xFA9088) is the base; `ld (XIX+0x08),BC` (0xFA90E9 and 0xFA90F4) is word 4
;          and `ld (XIX+0x0a),BC` (0xFA90FC) is word 5.
; ★ WHAT MAKES IT "First": THE OFFSET IS APPLIED TO WORD 4 ONLY.  Word 5 is always
;          voice[+0x41] verbatim.  Word 4 is voice[+0x3F] verbatim when bit 6 of
;          (voice[+0x25])[+0x18] is clear (0xFA909C/0xFA90A0), and otherwise
;              word4 = (voice[+0x3F] & 0xFF80) | Clamp_36_to_120( (voice[+0x3F] & 0x7F)
;                                                                 -/+ (voice[+0x23])[+0x21] )
;          with SUBTRACT chosen by bit 7 of the same flag word (0xFA90A4) and ADD
;          otherwise (0xFA90D5).  The `and BC,0xFF80` at 0xFA90E3 is what fixes the field
;          split: bits 15..7 pass through, bits 6..0 are the clamped quantity.
; Called from: exactly two sites -- 0xFA91EF in Voice_StagePair_Reg0100_0140_AB and
;          0xFA92F9 in ..._CD.  Found by decoding EVERY call in the image, in all three
;          forms (0x1D absolute, 0x1E calr d16, 0x1F calr d24); asserted by
;          notes/prom_c_reg0100_0140_checks.py section 1b.
; ⚠ SIBLING: the KN5000 sub-CPU's `TVF_Emit_Offset_Reg100` (0x024366) is the same routine
;          instruction for instruction -- same flag bits 6 and 7, same 0x7F mask, same
;          0xFF80 merge, same clamp, same "second register copied verbatim" tail -- and it
;          stores to that image's 0x0451D4/0x0451D6, its TG registers 0x100/0x140.  ITS
;          BYTES ARE NOT THESE BYTES: of the 102 bytes the two share, 100 differ (different
;          calling convention and different record offsets).  What is borrowed is the
;          identification of the registers, not the code.
; Unknown:  what the 7-bit quantity IS.  See
;          notes/FINDINGS-prom_c-dev10c-sibling-register-map.md.
; --------------------------------------------------------------------------
Voice_StagePair_Reg0100_0140_First:
	link32 0xEE, 0x0C, 0xFE, 0xFF              ; FA9081  link XIZ,0xfffe
	pushw	hl                                   ; FA9085  push HL
	push	xde                                   ; FA9086  push XDE
	push	xix                                   ; FA9087  push XIX
	lda	xix, (0xD75E:24)                       ; FA9088  lda XIX,0x00d75e
	ld	de, (xiz+8)                             ; FA908D  ld DE,(XIZ+0x08)
	extz	xde                                   ; FA9090  extz XDE
	ld	bc, (xde+37)                            ; FA9092  ld BC,(XDE+0x25)
	extz	xbc                                   ; FA9095  extz XBC
	ld	hl, (xbc+24)                            ; FA9097  ld HL,(XBC+0x18)
	ld	bc, hl                                  ; FA909A  ld BC,HL
	and	bc, 64                                 ; FA909C  and BC,0x0040
	jr z, Voice_StagePair_Reg0100_0140_First__FA90EF                   ; FA90A0  jr Z,0xfa90ef
	ld	bc, hl                                  ; FA90A2  ld BC,HL
	and	bc, 0x80                               ; FA90A4  and BC,0x0080
	ld	(xiz-2), bc                             ; FA90A8  ld (XIZ+0xfe),BC
	extz	xde                                   ; FA90AB  extz XDE
	ld	hl, (xde+63)                            ; FA90AD  ld HL,(XDE+0x3f)
	and	hl, 0x7F                               ; FA90B0  and HL,0x007f
	cps	bc, 0                                  ; FA90B4  cp BC,0
	jr z, Voice_StagePair_Reg0100_0140_First__FA90C6                   ; FA90B6  jr Z,0xfa90c6
	extz	xde                                   ; FA90B8  extz XDE
	ld	bc, (xde+35)                            ; FA90BA  ld BC,(XDE+0x23)
	extz	xbc                                   ; FA90BD  extz XBC
	ld	wa, (xbc+33)                            ; FA90BF  ld WA,(XBC+0x21)
	sub	hl, wa                                 ; FA90C2  sub HL,WA
	jr Voice_StagePair_Reg0100_0140_First__FA90D8                      ; FA90C4  jr T,0xfa90d8
Voice_StagePair_Reg0100_0140_First__FA90C6:
	ld	(xiz-2), hl                             ; FA90C6  ld (XIZ+0xfe),HL
	extz	xde                                   ; FA90C9  extz XDE
	ld	bc, (xde+35)                            ; FA90CB  ld BC,(XDE+0x23)
	extz	xbc                                   ; FA90CE  extz XBC
	ld	wa, (xbc+33)                            ; FA90D0  ld WA,(XBC+0x21)
	ld	hl, wa                                  ; FA90D3  ld HL,WA
	extpfx3 0x9E, 0xFE, 0x83                   ; FA90D5  add HL,(XIZ+0xfe)
Voice_StagePair_Reg0100_0140_First__FA90D8:
	pushw	hl                                   ; FA90D8  push HL
	calr (0xFA76B2 - 0xFA90DC)                 ; FA90D9  calr 0xfa76b2
	ld	hl, wa                                  ; FA90DC  ld HL,WA
	extz	xde                                   ; FA90DE  extz XDE
	ld	bc, (xde+63)                            ; FA90E0  ld BC,(XDE+0x3f)
	and	bc, 0xFF80                             ; FA90E3  and BC,0xff80
	or	bc, wa                                  ; FA90E7  or BC,WA
	ld	(xix+8), bc                             ; FA90E9  ld (XIX+0x08),BC
	popw	bc                                    ; FA90EC  pop BC
	jr Voice_StagePair_Reg0100_0140_First__FA90F7                      ; FA90ED  jr T,0xfa90f7
Voice_StagePair_Reg0100_0140_First__FA90EF:
	extz	xde                                   ; FA90EF  extz XDE
	ld	bc, (xde+63)                            ; FA90F1  ld BC,(XDE+0x3f)
	ld	(xix+8), bc                             ; FA90F4  ld (XIX+0x08),BC
Voice_StagePair_Reg0100_0140_First__FA90F7:
	extz	xde                                   ; FA90F7  extz XDE
	ld	bc, (xde+65)                            ; FA90F9  ld BC,(XDE+0x41)
	ld	(xix+10), bc                            ; FA90FC  ld (XIX+0x0a),BC
	pop	xix                                    ; FA90FF  pop XIX
	pop	xde                                    ; FA9100  pop XDE
	popw	hl                                    ; FA9101  pop HL
	unlk32 xiz                                 ; FA9102  unlk XIZ
	ret                                        ; FA9104  ret
; --------------------------------------------------------------------------
; Voice_StagePair_Reg0100_0140_Both -- 0xFA9105..0xFA919A (150 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFA91F5 0xFA92FF
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA76B2 = Clamp_36_to_120
; Voice record: touches voice_record[+0x23(r), +0x25(r), +0x3F(r), +0x41(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA9105-0xFA919A
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ WHAT IT STAGES: words 4 and 5 -- registers 0x0100 + chan and 0x0140 + chan -- and
;          nothing else.  `lda XIX,0x00d75e` (0xFA910C); `ld (XIX+0x08),BC` at 0xFA9174 and
;          0xFA918C; `ld (XIX+0x0a),BC` at 0xFA9181 and 0xFA9192.
; ★ WHAT MAKES IT "Both": ONE clamped offset goes into BOTH registers.  The value is
;          computed exactly as in Voice_StagePair_Reg0100_0140_First -- same flag word
;          (voice[+0x25])[+0x18], same bits 6 and 7, same (voice[+0x23])[+0x21] offset,
;          same Clamp_36_to_120 -- but it is saved in (XIZ+0xfc) at 0xFA916F and merged
;          into word 4 under voice[+0x3F]'s 0xFF80 (0xFA9172) AND into word 5 under
;          voice[+0x41]'s 0xFF80 (0xFA917E).  With bit 6 clear both words are copied
;          verbatim (0xFA9187-0xFA9192).
; Called from: exactly two sites: 0xFA91F5 in ..._AB and 0xFA92FF in ..._CD, by the same
;          whole-image call scan as its sibling above.
; ⚠ SIBLING: the KN5000 sub-CPU's `TVF_Emit_Offset_Both` (0x0243CC) is the same routine and
;          writes the same two registers there.  NOT byte-identical: of the 120 bytes the
;          two share, 116 differ.
; Unknown:  what the 7-bit quantity IS.
; --------------------------------------------------------------------------
Voice_StagePair_Reg0100_0140_Both:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FA9105  link XIZ,0xfffc
	pushw	hl                                   ; FA9109  push HL
	push	xde                                   ; FA910A  push XDE
	push	xix                                   ; FA910B  push XIX
	lda	xix, (0xD75E:24)                       ; FA910C  lda XIX,0x00d75e
	ld	de, (xiz+8)                             ; FA9111  ld DE,(XIZ+0x08)
	extz	xde                                   ; FA9114  extz XDE
	ld	bc, (xde+37)                            ; FA9116  ld BC,(XDE+0x25)
	extz	xbc                                   ; FA9119  extz XBC
	ld	hl, (xbc+24)                            ; FA911B  ld HL,(XBC+0x18)
	ld	bc, hl                                  ; FA911E  ld BC,HL
	and	bc, 64                                 ; FA9120  and BC,0x0040
	jrl z, Voice_StagePair_Reg0100_0140_Both__FA9187                  ; FA9124  jrl Z,0xfa9187
	ld	bc, hl                                  ; FA9127  ld BC,HL
	and	bc, 0x80                               ; FA9129  and BC,0x0080
	ld	(xiz-2), bc                             ; FA912D  ld (XIZ+0xfe),BC
	extz	xde                                   ; FA9130  extz XDE
	ld	hl, (xde+63)                            ; FA9132  ld HL,(XDE+0x3f)
	and	hl, 0x7F                               ; FA9135  and HL,0x007f
	cps	bc, 0                                  ; FA9139  cp BC,0
	jr z, Voice_StagePair_Reg0100_0140_Both__FA914B                   ; FA913B  jr Z,0xfa914b
	extz	xde                                   ; FA913D  extz XDE
	ld	bc, (xde+35)                            ; FA913F  ld BC,(XDE+0x23)
	extz	xbc                                   ; FA9142  extz XBC
	ld	wa, (xbc+33)                            ; FA9144  ld WA,(XBC+0x21)
	sub	hl, wa                                 ; FA9147  sub HL,WA
	jr Voice_StagePair_Reg0100_0140_Both__FA915D                      ; FA9149  jr T,0xfa915d
Voice_StagePair_Reg0100_0140_Both__FA914B:
	ld	(xiz-2), hl                             ; FA914B  ld (XIZ+0xfe),HL
	extz	xde                                   ; FA914E  extz XDE
	ld	bc, (xde+35)                            ; FA9150  ld BC,(XDE+0x23)
	extz	xbc                                   ; FA9153  extz XBC
	ld	wa, (xbc+33)                            ; FA9155  ld WA,(XBC+0x21)
	ld	hl, wa                                  ; FA9158  ld HL,WA
	extpfx3 0x9E, 0xFE, 0x83                   ; FA915A  add HL,(XIZ+0xfe)
Voice_StagePair_Reg0100_0140_Both__FA915D:
	pushw	hl                                   ; FA915D  push HL
	calr (0xFA76B2 - 0xFA9161)                 ; FA915E  calr 0xfa76b2
	ld	hl, wa                                  ; FA9161  ld HL,WA
	extz	xde                                   ; FA9163  extz XDE
	ld	bc, (xde+63)                            ; FA9165  ld BC,(XDE+0x3f)
	and	bc, 0xFF80                             ; FA9168  and BC,0xff80
	ld	(xiz-2), bc                             ; FA916C  ld (XIZ+0xfe),BC
	ld	(xiz-4), wa                             ; FA916F  ld (XIZ+0xfc),WA
	or	bc, wa                                  ; FA9172  or BC,WA
	ld	(xix+8), bc                             ; FA9174  ld (XIX+0x08),BC
	ld	bc, (xde+65)                            ; FA9177  ld BC,(XDE+0x41)
	and	bc, 0xFF80                             ; FA917A  and BC,0xff80
	extpfx3 0x9E, 0xFC, 0xE1                   ; FA917E  or BC,(XIZ+0xfc)
	ld	(xix+10), bc                            ; FA9181  ld (XIX+0x0a),BC
	popw	bc                                    ; FA9184  pop BC
	jr Voice_StagePair_Reg0100_0140_Both__FA9195                      ; FA9185  jr T,0xfa9195
Voice_StagePair_Reg0100_0140_Both__FA9187:
	extz	xde                                   ; FA9187  extz XDE
	ld	bc, (xde+63)                            ; FA9189  ld BC,(XDE+0x3f)
	ld	(xix+8), bc                             ; FA918C  ld (XIX+0x08),BC
	ld	bc, (xde+65)                            ; FA918F  ld BC,(XDE+0x41)
	ld	(xix+10), bc                            ; FA9192  ld (XIX+0x0a),BC
Voice_StagePair_Reg0100_0140_Both__FA9195:
	pop	xix                                    ; FA9195  pop XIX
	pop	xde                                    ; FA9196  pop XDE
	popw	hl                                    ; FA9197  pop HL
	unlk32 xiz                                 ; FA9198  unlk XIZ
	ret                                        ; FA919A  ret
; --------------------------------------------------------------------------
; Voice_StagePair_Reg0100_0140_AB -- 0xFA919B..0xFA92A4 (266 bytes)
;
; Called from: 3 site(s) outside this module:
;          0xFADFED in Voice_RestageRegs0100_0140_ForList__FADFEC, 0xFB0B1B in VoiceRegs_Stage_A
;          0xFB1F09 in VoiceRegs_Stage_B
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D766, 0x00D768
; Calls:   0xFA76B2 = Clamp_36_to_120, 0xFA9081 = Voice_StagePair_Reg0100_0140_First
;          0xFA9105 = Voice_StagePair_Reg0100_0140_Both
; Arms:    5 computed-goto arm(s) inside this routine: 0xFA91DE 0xFA91EE 0xFA91F4 0xFA91FC 0xFA928D
; Voice record: touches voice_record[+0x17(r), +0x23(r), +0x25(r), +0x3F(r), +0x41(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA919B-0xFA92A4
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ WHAT IT STAGES: words 4 and 5 only -- registers 0x0100 + chan and 0x0140 + chan.
;          Both `stw_da` sites appear in each of its three writing arms (0xFA9271/0xFA9285,
;          0xFA9292/0xFA929A) and in the two helpers it calls.
; ★ THE SIX ARMS, from the computed-goto table below, selected by
;          `(voice[+0x17])[+0x36] & 7` (0xFA91AA-0xFA91B6):
;            0 and out-of-range -> 0xFA928D: word4 = voice[+0x3F], word5 = voice[+0x41],
;                                  both verbatim;
;            1, 2               -> Voice_StagePair_Reg0100_0140_First;
;            3                  -> First or Both, chosen by bit 9 of (voice[+0x23])[+0x06]
;                                  (`and WA,0x0200` at 0xFA91E8);
;            4                  -> Voice_StagePair_Reg0100_0140_Both;
;            5                  -> the inline arm at 0xFA91FC, which offsets EACH register
;                                  from ITS OWN base: with M = (voice[+0x23])[+0x21],
;                                    word4 = (voice[+0x3F] & 0xFF80) |
;                Clamp_36_to_120((voice[+0x3F] & 0x7F) -/+ M)
;                                    word5 = (voice[+0x41] & 0xFF80) |
;                Clamp_36_to_120((voice[+0x41] & 0x7F) -/+ M)
;                                  (0xFA9260-0xFA9285), sign again from bit 7 of
;                                  (voice[+0x25])[+0x18].
; ★ ITS TWIN IS Voice_StagePair_Reg0100_0140_CD, AND THE ONE SEMANTIC DIFFERENCE IS THE
;          TONE-RECORD FIELD.  Both routines are 266 bytes; 23 bytes differ, and 22 of
;          those are jump-table entries and `calr` displacements -- relocation.  The ONE
;          remaining difference is at +0x010: this routine reads the tone record's byte
;          +0x36, the CD one reads +0x11.  Those are the DISPLACEMENT BYTES of the
;          `ld A,(XBC+d)` instructions at 0xFA91AA (`89 36 21`) and 0xFA92B4
;          (`89 11 21`) -- byte 0xFA91AB is 0x36, byte 0xFA92B5 is 0x11.  Diffed
;          byte by byte against original_ROMs/wsa1_prom_c.ic28 by
;          notes/prom_c_reg0100_0140_checks.py section 3, which prints all 23 positions.
; Called from: VoiceRegs_Stage_A (0xFB0B1B) and VoiceRegs_Stage_B (0xFB1F09) -- hence _AB --
;          and from Voice_RestageRegs0100_0140_ForList__FADFEC (0xFADFED).
; ⚠ SIBLING: the KN5000 sub-CPU's `TVF_Emit_Registers` (0x024444) dispatches on the same
;          `(patch+54)&7` field with the same six cases in the same roles and emits the same
;          two registers.  NOT byte-identical.
; Unknown:  what the 7-bit quantity IS, and what field +0x36 of the tone record selects
;          between.
; --------------------------------------------------------------------------
Voice_StagePair_Reg0100_0140_AB:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FA919B  link XIZ,0xfffc
	pushw	hl                                   ; FA919F  push HL
	pushw	de                                   ; FA91A0  push DE
	push	xix                                   ; FA91A1  push XIX
	ld	ix, (xiz+8)                             ; FA91A2  ld IX,(XIZ+0x08)
	extz	xix                                   ; FA91A5  extz XIX
	ld	xbc, (xix+23)                           ; FA91A7  ld XBC,(XIX+0x17)
	ld	a, (xbc+54)                             ; FA91AA  ld A,(XBC+0x36)
	and	a, 7                                   ; FA91AD  and A,0x07
	extz	wa                                    ; FA91B0  extz WA
	extz	xwa                                   ; FA91B2  extz XWA
	cps	wa, 5                                  ; FA91B4  cp WA,5
	jrl ugt, Voice_StagePair_Reg0100_0140_AB__FA928D                ; FA91B6  jrl UGT,0xfa928d
	sll	wa, 2                                  ; FA91B9  sll 0x02,WA
	add	xwa, 0xFA91C6                          ; FA91BC  add XWA,0x00fa91c6
	ld	xwa, (xwa)                              ; FA91C2  ld XWA,(XWA)
	jp	(xwa)                                   ; FA91C4  jp T,XWA
; 6 x u32 computed-goto table, 0xFA91C6-0xFA91DD, 24 bytes.
; THE ENTRY COUNT IS ESTABLISHED TWICE AND THE TWO AGREE: the `cp rr,5`
; guard before the `jr UGT` gives 6, and reading consecutive words while
; each is a plausible code address also gives 6.  The word after the last
; entry is not a plausible entry, so the table ends here rather than being
; assumed to.  (python3 notes/prom_c_jumptables.py 0xFA7E2C 0xFABE30;
; asserted per table by notes/prom_c_voiceparam_checks.py section 2.)
; Entry 0 is the SAME address the out-of-range guard branches to.
	.long 0x00FA928D	; 0xFA91C6  entry 0 -> 0xFA928D   (also the out-of-range arm)
	.long 0x00FA91EE	; 0xFA91CA  entry 1 -> 0xFA91EE
	.long 0x00FA91EE	; 0xFA91CE  entry 2 -> 0xFA91EE
	.long 0x00FA91DE	; 0xFA91D2  entry 3 -> 0xFA91DE
	.long 0x00FA91F4	; 0xFA91D6  entry 4 -> 0xFA91F4
	.long 0x00FA91FC	; 0xFA91DA  entry 5 -> 0xFA91FC
Voice_StagePair_Reg0100_0140_AB__FA91DE:
	extz	xix                                   ; FA91DE  extz XIX
	ld	bc, (xix+35)                            ; FA91E0  ld BC,(XIX+0x23)
	extz	xbc                                   ; FA91E3  extz XBC
	ld	wa, (xbc+6)                             ; FA91E5  ld WA,(XBC+0x06)
	and	wa, 0x200                              ; FA91E8  and WA,0x0200
	jr z, Voice_StagePair_Reg0100_0140_AB__FA91F4                   ; FA91EC  jr Z,0xfa91f4
Voice_StagePair_Reg0100_0140_AB__FA91EE:
	pushw	ix                                   ; FA91EE  push IX
	calr (0xFA9081 - 0xFA91F2)                 ; FA91EF  calr 0xfa9081
	jr Voice_StagePair_Reg0100_0140_AB__FA91F8                      ; FA91F2  jr T,0xfa91f8
Voice_StagePair_Reg0100_0140_AB__FA91F4:
	pushw	ix                                   ; FA91F4  push IX
	calr (0xFA9105 - 0xFA91F8)                 ; FA91F5  calr 0xfa9105
Voice_StagePair_Reg0100_0140_AB__FA91F8:
	popw	bc                                    ; FA91F8  pop BC
	jrl Voice_StagePair_Reg0100_0140_AB__FA929F                     ; FA91F9  jrl T,0xfa929f
Voice_StagePair_Reg0100_0140_AB__FA91FC:
	extz	xix                                   ; FA91FC  extz XIX
	ld	bc, (xix+37)                            ; FA91FE  ld BC,(XIX+0x25)
	extz	xbc                                   ; FA9201  extz XBC
	ld	hl, (xbc+24)                            ; FA9203  ld HL,(XBC+0x18)
	ld	bc, hl                                  ; FA9206  ld BC,HL
	and	bc, 64                                 ; FA9208  and BC,0x0040
	jrl z, Voice_StagePair_Reg0100_0140_AB__FA928D                  ; FA920C  jrl Z,0xfa928d
	ld	de, hl                                  ; FA920F  ld DE,HL
	and	de, 0x80                               ; FA9211  and DE,0x0080
	extz	xix                                   ; FA9215  extz XIX
	ld	hl, (xix+63)                            ; FA9217  ld HL,(XIX+0x3f)
	and	hl, 0x7F                               ; FA921A  and HL,0x007f
	cps	de, 0                                  ; FA921E  cp DE,0
	jr z, Voice_StagePair_Reg0100_0140_AB__FA9240                   ; FA9220  jr Z,0xfa9240
	extz	xix                                   ; FA9222  extz XIX
	ld	bc, (xix+35)                            ; FA9224  ld BC,(XIX+0x23)
	extz	xbc                                   ; FA9227  extz XBC
	ld	wa, (xbc+33)                            ; FA9229  ld WA,(XBC+0x21)
	ld	(xiz-2), wa                             ; FA922C  ld (XIZ+0xfe),WA
	ld	de, hl                                  ; FA922F  ld DE,HL
	sub	de, wa                                 ; FA9231  sub DE,WA
	ld	bc, (xix+65)                            ; FA9233  ld BC,(XIX+0x41)
	and	bc, 0x7F                               ; FA9236  and BC,0x007f
	ld	hl, bc                                  ; FA923A  ld HL,BC
	sub	hl, wa                                 ; FA923C  sub HL,WA
	jr Voice_StagePair_Reg0100_0140_AB__FA9260                      ; FA923E  jr T,0xfa9260
Voice_StagePair_Reg0100_0140_AB__FA9240:
	ld	(xiz-2), hl                             ; FA9240  ld (XIZ+0xfe),HL
	extz	xix                                   ; FA9243  extz XIX
	ld	bc, (xix+35)                            ; FA9245  ld BC,(XIX+0x23)
	extz	xbc                                   ; FA9248  extz XBC
	ld	wa, (xbc+33)                            ; FA924A  ld WA,(XBC+0x21)
	ld	(xiz-4), wa                             ; FA924D  ld (XIZ+0xfc),WA
	ld	de, wa                                  ; FA9250  ld DE,WA
	extpfx3 0x9E, 0xFE, 0x82                   ; FA9252  add DE,(XIZ+0xfe)
	ld	bc, (xix+65)                            ; FA9255  ld BC,(XIX+0x41)
	ld	hl, bc                                  ; FA9258  ld HL,BC
	and	hl, 0x7F                               ; FA925A  and HL,0x007f
	add	hl, wa                                 ; FA925E  add HL,WA
Voice_StagePair_Reg0100_0140_AB__FA9260:
	pushw	de                                   ; FA9260  push DE
	calr (0xFA76B2 - 0xFA9264)                 ; FA9261  calr 0xfa76b2
	ld	de, wa                                  ; FA9264  ld DE,WA
	extz	xix                                   ; FA9266  extz XIX
	ld	bc, (xix+63)                            ; FA9268  ld BC,(XIX+0x3f)
	and	bc, 0xFF80                             ; FA926B  and BC,0xff80
	or	bc, wa                                  ; FA926F  or BC,WA
	stw_da	(0xD766), bc                        ; FA9271  ld (0x00d766),BC
	pushw	hl                                   ; FA9276  push HL
	calr (0xFA76B2 - 0xFA927A)                 ; FA9277  calr 0xfa76b2
	ld	hl, wa                                  ; FA927A  ld HL,WA
	ld	bc, (xix+65)                            ; FA927C  ld BC,(XIX+0x41)
	and	bc, 0xFF80                             ; FA927F  and BC,0xff80
	or	bc, wa                                  ; FA9283  or BC,WA
	stw_da	(0xD768), bc                        ; FA9285  ld (0x00d768),BC
	pop	xiy                                    ; FA928A  pop XIY
	jr Voice_StagePair_Reg0100_0140_AB__FA929F                      ; FA928B  jr T,0xfa929f
Voice_StagePair_Reg0100_0140_AB__FA928D:
	extz	xix                                   ; FA928D  extz XIX
	ld	bc, (xix+63)                            ; FA928F  ld BC,(XIX+0x3f)
	stw_da	(0xD766), bc                        ; FA9292  ld (0x00d766),BC
	ld	bc, (xix+65)                            ; FA9297  ld BC,(XIX+0x41)
	stw_da	(0xD768), bc                        ; FA929A  ld (0x00d768),BC
Voice_StagePair_Reg0100_0140_AB__FA929F:
	pop	xix                                    ; FA929F  pop XIX
	popw	de                                    ; FA92A0  pop DE
	popw	hl                                    ; FA92A1  pop HL
	unlk32 xiz                                 ; FA92A2  unlk XIZ
	ret                                        ; FA92A4  ret
; --------------------------------------------------------------------------
; Voice_StagePair_Reg0100_0140_CD -- 0xFA92A5..0xFA93AE (266 bytes)
;
; Called from: 3 site(s) outside this module:
;          0xFADFF4 in Voice_RestageRegs0100_0140_ForList__FADFF3, 0xFB2834 in VoiceRegs_Stage_C
;          0xFB2F09 in VoiceRegs_Stage_D
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D766, 0x00D768
; Calls:   0xFA76B2 = Clamp_36_to_120, 0xFA9081 = Voice_StagePair_Reg0100_0140_First
;          0xFA9105 = Voice_StagePair_Reg0100_0140_Both
; Arms:    5 computed-goto arm(s) inside this routine: 0xFA92E8 0xFA92F8 0xFA92FE 0xFA9306 0xFA9397
; Voice record: touches voice_record[+0x17(r), +0x23(r), +0x25(r), +0x3F(r), +0x41(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA92A5-0xFA93AE
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ The byte twin of Voice_StagePair_Reg0100_0140_AB with ONE semantic difference: it
;          dispatches on the tone record's byte +0x11 instead of +0x36: the instruction
;          is `ld A,(XBC+0x11)` at 0xFA92B4, against `ld A,(XBC+0x36)` at 0xFA91AA.
;          266 bytes each, 23 differing, 22 of them relocation -- see that routine's header
;          and notes/prom_c_reg0100_0140_checks.py section 3.  Everything the AB header
;          says about the six arms, the field split and the registers applies here.
; ★ WHAT IT STAGES: words 4 and 5 only -- registers 0x0100 + chan and 0x0140 + chan
;          (0xFA937B/0xFA938F and 0xFA939C/0xFA93A4).
; Called from: VoiceRegs_Stage_C (0xFB2834) and VoiceRegs_Stage_D (0xFB2F09) -- hence _CD --
;          and from Voice_RestageRegs0100_0140_ForList__FADFF3 (0xFADFF4).
; ★ AND THE SAME FIELD, +0x11, IS WHAT VoiceParam_DispatchOn_17_11 (0xFA900A) SWITCHES ON,
;          which is the other producer of these two words on the C/D path.  The A/B side's
;          counterpart is VoiceParam_DispatchOn_17_36 (0xFA8BDD).
; Unknown:  what the 7-bit quantity IS, and what field +0x11 of the tone record selects
;          between.
; --------------------------------------------------------------------------
Voice_StagePair_Reg0100_0140_CD:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FA92A5  link XIZ,0xfffc
	pushw	hl                                   ; FA92A9  push HL
	pushw	de                                   ; FA92AA  push DE
	push	xix                                   ; FA92AB  push XIX
	ld	ix, (xiz+8)                             ; FA92AC  ld IX,(XIZ+0x08)
	extz	xix                                   ; FA92AF  extz XIX
	ld	xbc, (xix+23)                           ; FA92B1  ld XBC,(XIX+0x17)
	ld	a, (xbc+17)                             ; FA92B4  ld A,(XBC+0x11)
	and	a, 7                                   ; FA92B7  and A,0x07
	extz	wa                                    ; FA92BA  extz WA
	extz	xwa                                   ; FA92BC  extz XWA
	cps	wa, 5                                  ; FA92BE  cp WA,5
	jrl ugt, Voice_StagePair_Reg0100_0140_CD__FA9397                ; FA92C0  jrl UGT,0xfa9397
	sll	wa, 2                                  ; FA92C3  sll 0x02,WA
	add	xwa, 0xFA92D0                          ; FA92C6  add XWA,0x00fa92d0
	ld	xwa, (xwa)                              ; FA92CC  ld XWA,(XWA)
	jp	(xwa)                                   ; FA92CE  jp T,XWA
; 6 x u32 computed-goto table, 0xFA92D0-0xFA92E7, 24 bytes.
; THE ENTRY COUNT IS ESTABLISHED TWICE AND THE TWO AGREE: the `cp rr,5`
; guard before the `jr UGT` gives 6, and reading consecutive words while
; each is a plausible code address also gives 6.  The word after the last
; entry is not a plausible entry, so the table ends here rather than being
; assumed to.  (python3 notes/prom_c_jumptables.py 0xFA7E2C 0xFABE30;
; asserted per table by notes/prom_c_voiceparam_checks.py section 2.)
; Entry 0 is the SAME address the out-of-range guard branches to.
	.long 0x00FA9397	; 0xFA92D0  entry 0 -> 0xFA9397   (also the out-of-range arm)
	.long 0x00FA92F8	; 0xFA92D4  entry 1 -> 0xFA92F8
	.long 0x00FA92F8	; 0xFA92D8  entry 2 -> 0xFA92F8
	.long 0x00FA92E8	; 0xFA92DC  entry 3 -> 0xFA92E8
	.long 0x00FA92FE	; 0xFA92E0  entry 4 -> 0xFA92FE
	.long 0x00FA9306	; 0xFA92E4  entry 5 -> 0xFA9306
Voice_StagePair_Reg0100_0140_CD__FA92E8:
	extz	xix                                   ; FA92E8  extz XIX
	ld	bc, (xix+35)                            ; FA92EA  ld BC,(XIX+0x23)
	extz	xbc                                   ; FA92ED  extz XBC
	ld	wa, (xbc+6)                             ; FA92EF  ld WA,(XBC+0x06)
	and	wa, 0x200                              ; FA92F2  and WA,0x0200
	jr z, Voice_StagePair_Reg0100_0140_CD__FA92FE                   ; FA92F6  jr Z,0xfa92fe
Voice_StagePair_Reg0100_0140_CD__FA92F8:
	pushw	ix                                   ; FA92F8  push IX
	calr (0xFA9081 - 0xFA92FC)                 ; FA92F9  calr 0xfa9081
	jr Voice_StagePair_Reg0100_0140_CD__FA9302                      ; FA92FC  jr T,0xfa9302
Voice_StagePair_Reg0100_0140_CD__FA92FE:
	pushw	ix                                   ; FA92FE  push IX
	calr (0xFA9105 - 0xFA9302)                 ; FA92FF  calr 0xfa9105
Voice_StagePair_Reg0100_0140_CD__FA9302:
	popw	bc                                    ; FA9302  pop BC
	jrl Voice_StagePair_Reg0100_0140_CD__FA93A9                     ; FA9303  jrl T,0xfa93a9
Voice_StagePair_Reg0100_0140_CD__FA9306:
	extz	xix                                   ; FA9306  extz XIX
	ld	bc, (xix+37)                            ; FA9308  ld BC,(XIX+0x25)
	extz	xbc                                   ; FA930B  extz XBC
	ld	hl, (xbc+24)                            ; FA930D  ld HL,(XBC+0x18)
	ld	bc, hl                                  ; FA9310  ld BC,HL
	and	bc, 64                                 ; FA9312  and BC,0x0040
	jrl z, Voice_StagePair_Reg0100_0140_CD__FA9397                  ; FA9316  jrl Z,0xfa9397
	ld	de, hl                                  ; FA9319  ld DE,HL
	and	de, 0x80                               ; FA931B  and DE,0x0080
	extz	xix                                   ; FA931F  extz XIX
	ld	hl, (xix+63)                            ; FA9321  ld HL,(XIX+0x3f)
	and	hl, 0x7F                               ; FA9324  and HL,0x007f
	cps	de, 0                                  ; FA9328  cp DE,0
	jr z, Voice_StagePair_Reg0100_0140_CD__FA934A                   ; FA932A  jr Z,0xfa934a
	extz	xix                                   ; FA932C  extz XIX
	ld	bc, (xix+35)                            ; FA932E  ld BC,(XIX+0x23)
	extz	xbc                                   ; FA9331  extz XBC
	ld	wa, (xbc+33)                            ; FA9333  ld WA,(XBC+0x21)
	ld	(xiz-2), wa                             ; FA9336  ld (XIZ+0xfe),WA
	ld	de, hl                                  ; FA9339  ld DE,HL
	sub	de, wa                                 ; FA933B  sub DE,WA
	ld	bc, (xix+65)                            ; FA933D  ld BC,(XIX+0x41)
	and	bc, 0x7F                               ; FA9340  and BC,0x007f
	ld	hl, bc                                  ; FA9344  ld HL,BC
	sub	hl, wa                                 ; FA9346  sub HL,WA
	jr Voice_StagePair_Reg0100_0140_CD__FA936A                      ; FA9348  jr T,0xfa936a
Voice_StagePair_Reg0100_0140_CD__FA934A:
	ld	(xiz-2), hl                             ; FA934A  ld (XIZ+0xfe),HL
	extz	xix                                   ; FA934D  extz XIX
	ld	bc, (xix+35)                            ; FA934F  ld BC,(XIX+0x23)
	extz	xbc                                   ; FA9352  extz XBC
	ld	wa, (xbc+33)                            ; FA9354  ld WA,(XBC+0x21)
	ld	(xiz-4), wa                             ; FA9357  ld (XIZ+0xfc),WA
	ld	de, wa                                  ; FA935A  ld DE,WA
	extpfx3 0x9E, 0xFE, 0x82                   ; FA935C  add DE,(XIZ+0xfe)
	ld	bc, (xix+65)                            ; FA935F  ld BC,(XIX+0x41)
	ld	hl, bc                                  ; FA9362  ld HL,BC
	and	hl, 0x7F                               ; FA9364  and HL,0x007f
	add	hl, wa                                 ; FA9368  add HL,WA
Voice_StagePair_Reg0100_0140_CD__FA936A:
	pushw	de                                   ; FA936A  push DE
	calr (0xFA76B2 - 0xFA936E)                 ; FA936B  calr 0xfa76b2
	ld	de, wa                                  ; FA936E  ld DE,WA
	extz	xix                                   ; FA9370  extz XIX
	ld	bc, (xix+63)                            ; FA9372  ld BC,(XIX+0x3f)
	and	bc, 0xFF80                             ; FA9375  and BC,0xff80
	or	bc, wa                                  ; FA9379  or BC,WA
	stw_da	(0xD766), bc                        ; FA937B  ld (0x00d766),BC
	pushw	hl                                   ; FA9380  push HL
	calr (0xFA76B2 - 0xFA9384)                 ; FA9381  calr 0xfa76b2
	ld	hl, wa                                  ; FA9384  ld HL,WA
	ld	bc, (xix+65)                            ; FA9386  ld BC,(XIX+0x41)
	and	bc, 0xFF80                             ; FA9389  and BC,0xff80
	or	bc, wa                                  ; FA938D  or BC,WA
	stw_da	(0xD768), bc                        ; FA938F  ld (0x00d768),BC
	pop	xiy                                    ; FA9394  pop XIY
	jr Voice_StagePair_Reg0100_0140_CD__FA93A9                      ; FA9395  jr T,0xfa93a9
Voice_StagePair_Reg0100_0140_CD__FA9397:
	extz	xix                                   ; FA9397  extz XIX
	ld	bc, (xix+63)                            ; FA9399  ld BC,(XIX+0x3f)
	stw_da	(0xD766), bc                        ; FA939C  ld (0x00d766),BC
	ld	bc, (xix+65)                            ; FA93A1  ld BC,(XIX+0x41)
	stw_da	(0xD768), bc                        ; FA93A4  ld (0x00d768),BC
Voice_StagePair_Reg0100_0140_CD__FA93A9:
	pop	xix                                    ; FA93A9  pop XIX
	popw	de                                    ; FA93AA  pop DE
	popw	hl                                    ; FA93AB  pop HL
	unlk32 xiz                                 ; FA93AC  unlk XIZ
	ret                                        ; FA93AE  ret
; --------------------------------------------------------------------------
; Voice_StageRegs_09C0_0A00_0A40_AB -- 0xFA93AF..0xFA95D3 (549 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFB0B20 in VoiceRegs_Stage_A, 0xFB1F0E in VoiceRegs_Stage_B
; Inputs:  frame `link XIZ,-16`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D784, 0x00D786, 0x00D788
; Calls:   0xFA7598 = Clamp_ToRange_Word, 0xFA75BA = ScaleCoeff_TimesAbsDepth_Shr
;          0xFA7602 = DetuneCurve_LookupSigned, 0xFA766C = ScaleClampedDelta_Shr5
; Voice record: touches voice_record[+0x08(r), +0x0C(r), +0x17(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA93AF-0xFA95D3
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 2, 2026-08-25.  IT BUILDS REGISTERS 0x09C0 / 0x0A00 / 0x0A40 OF BLOCK GROUP 0x20-0x29.
;          Each is written as `(hi << 8) | (lo & 0xFF)`: the HIGH byte comes from
;          Voice_EnvelopeLevel_Curve (this routine makes SIX of prom_c's thirty
;          lookups of it) clamped to 0..0xFF by Clamp_ToRange_Word, the LOW byte from
;          DetuneCurve_LookupSigned of a value first clamped to -50..+50, i.e. a
;          signed +/-127 depth.  ⚠ That these are envelope STAGES, and in what order,
;          is NOT asserted.  See the 0x0800..0x0A40 block comment in front of
;          Dev10C_WriteAllChanRegs; census by notes/prom_c_reg_bytepair_check.py.
;          ⚠ This says what THREE of the routine's outputs are, not what it is.
; ★ ROUND 6 ------------------------------------------------------------
; Voice_StageRegs_09C0_0A00_0A40_AB -- stages word 19 (register 0x09C0 + chan), word 20 (register 0x0A00 + chan), word 21 (register 0x0A40 + chan) of the 0x0010C000 per-channel
;          staging struct at RAM 0x00D75E, and nothing else in that struct.
;          Write site(s): 0xFA94F1, 0xFA95B0, 0xFA95C3.
;          Argument: the caller pushes XDE, the 68-byte VOICE RECORD at 0x003BCF + 0x44*voice
;          (`ld C,0x44 / mul BC,(XIZ+0x08) / ld <r>,0x3bcf` at the top of every
;          VoiceRegs_Stage_*), immediately before the call.
;          Called from: VoiceRegs_Stage_A, VoiceRegs_Stage_B.
;          Evidence: the write addresses above are instruction operands, listed by
;          `python3 notes/prom_c_understanding_round6.py --staging`, which also asserts that
;          this routine writes EXACTLY the register block(s) its name claims and no other.
;          The struct-word -> register-block map is Dev10C_WriteAllChanRegs's own
;          (notes/prom_c_tg_chanmap.py), cross-checked against
;          notes/prom_c_dev10c_field_sources.py by the same section.
;          Unknown: what register 0x09C0 / 0x0A00 / 0x0A40 carries.  The name states WHICH register this
;          routine produces, never what the register means.
; --------------------------------------------------------------------------
Voice_StageRegs_09C0_0A00_0A40_AB:
	link32 0xEE, 0x0C, 0xF0, 0xFF              ; FA93AF  link XIZ,0xfff0
	pushw	hl                                   ; FA93B3  push HL
	pushw	de                                   ; FA93B4  push DE
	pushw	ix                                   ; FA93B5  push IX
	ld	bc, (xiz+8)                             ; FA93B6  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA93B9  extz XBC
	ld	xwa, (xbc+23)                           ; FA93BB  ld XWA,(XBC+0x17)
	ld	(xiz-10), xwa                           ; FA93BE  ld (XIZ+0xf6),XWA
	ld	h, (xwa+71)                             ; FA93C1  ld H,(XWA+0x47)
	cps	h, 0                                   ; FA93C4  cp H,0
	jrl z, Voice_StageRegs_09C0_0A00_0A40_AB__FA9446                  ; FA93C6  jrl Z,0xfa9446
	pushw	4                                    ; FA93C9  push 0x0004
	ld	a, (xbc+12)                             ; FA93CC  ld A,(XBC+0x0c)
	pushw	wa                                   ; FA93CF  push WA
	push	0                                     ; FA93D0  push 0x00
	push	h                                     ; FA93D2  push H
	calr (0xFA75BA - 0xFA93D7)                 ; FA93D4  calr 0xfa75ba
	ld	(xiz-4), wa                             ; FA93D7  ld (XIZ+0xfc),WA
	ld	xbc, (xiz-10)                           ; FA93DA  ld XBC,(XIZ+0xf6)
	ld	h, (xbc+63)                             ; FA93DD  ld H,(XBC+0x3f)
	extpfx3 0xC7, 0xF4, 0x9E                   ; FA93E0  ld IYL,H
	extz	iy                                    ; FA93E3  extz IY
	extz	xiy                                   ; FA93E5  extz XIY
	add	xiy, 0xFDEFD9                          ; FA93E7  add XIY,0x00fdefd9
	ld	c, (xiy)                                ; FA93ED  ld C,(XIY)
	extz	bc                                    ; FA93EF  extz BC
	ld	de, bc                                  ; FA93F1  ld DE,BC
	inc	6, xsp                                 ; FA93F3  inc 6,XSP
	cps	h, 0                                   ; FA93F5  cp H,0
	jr z, Voice_StageRegs_09C0_0A00_0A40_AB__FA93FD                   ; FA93F7  jr Z,0xfa93fd
	add	bc, wa                                 ; FA93F9  add BC,WA
	ld	de, bc                                  ; FA93FB  ld DE,BC
Voice_StageRegs_09C0_0A00_0A40_AB__FA93FD:
	ld	xbc, (xiz-10)                           ; FA93FD  ld XBC,(XIZ+0xf6)
	ld	a, (xbc+65)                             ; FA9400  ld A,(XBC+0x41)
	ld	(xiz-12), a                             ; FA9403  ld (XIZ+0xf4),A
	extz	wa                                    ; FA9406  extz WA
	extz	xwa                                   ; FA9408  extz XWA
	add	xwa, 0xFDEFD9                          ; FA940A  add XWA,0x00fdefd9
	ld	w, (xwa)                                ; FA9410  ld W,(XWA)
	ld	l, w                                    ; FA9412  ld L,W
	extz	hl                                    ; FA9414  extz HL
	cp (xiz-12), 0x00                          ; FA9416  cp (XIZ+0xf4),0x00
	jr z, Voice_StageRegs_09C0_0A00_0A40_AB__FA9421                   ; FA941A  jr Z,0xfa9421
	ld	wa, (xiz-4)                             ; FA941C  ld WA,(XIZ+0xfc)
	add	hl, wa                                 ; FA941F  add HL,WA
Voice_StageRegs_09C0_0A00_0A40_AB__FA9421:
	ld	xbc, (xiz-10)                           ; FA9421  ld XBC,(XIZ+0xf6)
	ld	a, (xbc+67)                             ; FA9424  ld A,(XBC+0x43)
	ld	(xiz-1), a                              ; FA9427  ld (XIZ+0xff),A
	cps	a, 0                                   ; FA942A  cp A,0
	jr z, Voice_StageRegs_09C0_0A00_0A40_AB__FA946F                   ; FA942C  jr Z,0xfa946f
	extz	wa                                    ; FA942E  extz WA
	extz	xwa                                   ; FA9430  extz XWA
	add	xwa, 0xFDEFD9                          ; FA9432  add XWA,0x00fdefd9
	ld	w, (xwa)                                ; FA9438  ld W,(XWA)
	extpfx3 0xC7, 0xF0, 0x98                   ; FA943A  ld IXL,W
	extz	ix                                    ; FA943D  extz IX
	ld	wa, (xiz-4)                             ; FA943F  ld WA,(XIZ+0xfc)
	add	ix, wa                                 ; FA9442  add IX,WA
	jr Voice_StageRegs_09C0_0A00_0A40_AB__FA9486                      ; FA9444  jr T,0xfa9486
Voice_StageRegs_09C0_0A00_0A40_AB__FA9446:
	ld	xbc, (xiz-10)                           ; FA9446  ld XBC,(XIZ+0xf6)
	ld	a, (xbc+63)                             ; FA9449  ld A,(XBC+0x3f)
	extz	wa                                    ; FA944C  extz WA
	extz	xwa                                   ; FA944E  extz XWA
	add	xwa, 0xFDEFD9                          ; FA9450  add XWA,0x00fdefd9
	ld	w, (xwa)                                ; FA9456  ld W,(XWA)
	ld	e, w                                    ; FA9458  ld E,W
	extz	de                                    ; FA945A  extz DE
	ld	a, (xbc+65)                             ; FA945C  ld A,(XBC+0x41)
	extz	wa                                    ; FA945F  extz WA
	extz	xwa                                   ; FA9461  extz XWA
	add	xwa, 0xFDEFD9                          ; FA9463  add XWA,0x00fdefd9
	ld	w, (xwa)                                ; FA9469  ld W,(XWA)
	ld	l, w                                    ; FA946B  ld L,W
	extz	hl                                    ; FA946D  extz HL
Voice_StageRegs_09C0_0A00_0A40_AB__FA946F:
	ld	xbc, (xiz-10)                           ; FA946F  ld XBC,(XIZ+0xf6)
	ld	a, (xbc+67)                             ; FA9472  ld A,(XBC+0x43)
	extz	wa                                    ; FA9475  extz WA
	extz	xwa                                   ; FA9477  extz XWA
	add	xwa, 0xFDEFD9                          ; FA9479  add XWA,0x00fdefd9
	ld	w, (xwa)                                ; FA947F  ld W,(XWA)
	extpfx3 0xC7, 0xF0, 0x98                   ; FA9481  ld IXL,W
	extz	ix                                    ; FA9484  extz IX
Voice_StageRegs_09C0_0A00_0A40_AB__FA9486:
	ld	xbc, (xiz-10)                           ; FA9486  ld XBC,(XIZ+0xf6)
	ld	a, (xbc+74)                             ; FA9489  ld A,(XBC+0x4a)
	ld	(xiz-5), a                              ; FA948C  ld (XIZ+0xfb),A
	cps	a, 0                                   ; FA948F  cp A,0
	jr z, Voice_StageRegs_09C0_0A00_0A40_AB__FA94B3                   ; FA9491  jr Z,0xfa94b3
	pushw	wa                                   ; FA9493  push WA
	pushw	0x7F                                 ; FA9494  push 0x007f
	pushw	0                                    ; FA9497  push 0x0000
	ld	w, (xbc+73)                             ; FA949A  ld W,(XBC+0x49)
	push	0                                     ; FA949D  push 0x00
	push	w                                     ; FA949F  push W
	ld	wa, (xiz+8)                             ; FA94A1  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA94A4  extz XWA
	ld	iy, (xwa+8)                             ; FA94A6  ld IY,(XWA+0x08)
	pushw	iy                                   ; FA94A9  push IY
	calr (0xFA766C - 0xFA94AD)                 ; FA94AA  calr 0xfa766c
	add	de, wa                                 ; FA94AD  add DE,WA
	inc	8, xsp                                 ; FA94AF  inc 0,XSP
	inc	2, xsp                                 ; FA94B1  inc 2,XSP
Voice_StageRegs_09C0_0A00_0A40_AB__FA94B3:
	pushw	0                                    ; FA94B3  push 0x0000
	pushw	0xFF                                 ; FA94B6  push 0x00ff
	pushw	de                                   ; FA94B9  push DE
	calr (0xFA7598 - 0xFA94BD)                 ; FA94BA  calr 0xfa7598
	ld	(xiz-12), wa                            ; FA94BD  ld (XIZ+0xf4),WA
	pushw	0xFFCE                               ; FA94C0  push 0xffce
	pushw	50                                   ; FA94C3  push 0x0032
	ld	xbc, (xiz-10)                           ; FA94C6  ld XBC,(XIZ+0xf6)
	ld	a, (xbc+61)                             ; FA94C9  ld A,(XBC+0x3d)
	exts	wa                                    ; FA94CC  exts WA
	ld	(xiz-14), wa                            ; FA94CE  ld (XIZ+0xf2),WA
	ld	a, (xbc+64)                             ; FA94D1  ld A,(XBC+0x40)
	exts	wa                                    ; FA94D4  exts WA
	extpfx3 0x9E, 0xF2, 0x80                   ; FA94D6  add WA,(XIZ+0xf2)
	pushw	wa                                   ; FA94D9  push WA
	calr (0xFA7598 - 0xFA94DD)                 ; FA94DA  calr 0xfa7598
	pushw	wa                                   ; FA94DD  push WA
	calr (0xFA7602 - 0xFA94E1)                 ; FA94DE  calr 0xfa7602
	and	wa, 0xFF                               ; FA94E1  and WA,0x00ff
	ld	(xiz-16), wa                            ; FA94E5  ld (XIZ+0xf0),WA
	ld	bc, (xiz-12)                            ; FA94E8  ld BC,(XIZ+0xf4)
	sll	bc, 8                                  ; FA94EB  sll 0x08,BC
	extpfx3 0x9E, 0xF0, 0xE1                   ; FA94EE  or BC,(XIZ+0xf0)
	stw_da	(0xD784), bc                        ; FA94F1  ld (0x00d784),BC
	ld	xbc, (xiz-10)                           ; FA94F6  ld XBC,(XIZ+0xf6)
	ld	d, (xbc+75)                             ; FA94F9  ld D,(XBC+0x4b)
	inc	8, xsp                                 ; FA94FC  inc 0,XSP
	inc	6, xsp                                 ; FA94FE  inc 6,XSP
	cps	d, 0                                   ; FA9500  cp D,0
	jr z, Voice_StageRegs_09C0_0A00_0A40_AB__FA9541                   ; FA9502  jr Z,0xfa9541
	push	0                                     ; FA9504  push 0x00
	push	d                                     ; FA9506  push D
	pushw	0x7F                                 ; FA9508  push 0x007f
	pushw	0                                    ; FA950B  push 0x0000
	ld	a, (xbc+73)                             ; FA950E  ld A,(XBC+0x49)
	pushw	wa                                   ; FA9511  push WA
	ld	wa, (xiz+8)                             ; FA9512  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA9515  extz XWA
	ld	iy, (xwa+8)                             ; FA9517  ld IY,(XWA+0x08)
	pushw	iy                                   ; FA951A  push IY
	calr (0xFA766C - 0xFA951E)                 ; FA951B  calr 0xfa766c
	ld	(xiz-12), wa                            ; FA951E  ld (XIZ+0xf4),WA
	pushw	0                                    ; FA9521  push 0x0000
	pushw	0xFF                                 ; FA9524  push 0x00ff
	add	wa, hl                                 ; FA9527  add WA,HL
	pushw	wa                                   ; FA9529  push WA
	calr (0xFA7598 - 0xFA952D)                 ; FA952A  calr 0xfa7598
	ld	hl, wa                                  ; FA952D  ld HL,WA
	inc	8, xsp                                 ; FA952F  inc 0,XSP
	inc	8, xsp                                 ; FA9531  inc 0,XSP
	pushw	0                                    ; FA9533  push 0x0000
	pushw	0xFF                                 ; FA9536  push 0x00ff
	ld	bc, ix                                  ; FA9539  ld BC,IX
	extpfx3 0x9E, 0xF4, 0x81                   ; FA953B  add BC,(XIZ+0xf4)
	pushw	bc                                   ; FA953E  push BC
	jr Voice_StageRegs_09C0_0A00_0A40_AB__FA9556                      ; FA953F  jr T,0xfa9556
Voice_StageRegs_09C0_0A00_0A40_AB__FA9541:
	pushw	0                                    ; FA9541  push 0x0000
	pushw	0xFF                                 ; FA9544  push 0x00ff
	pushw	hl                                   ; FA9547  push HL
	calr (0xFA7598 - 0xFA954B)                 ; FA9548  calr 0xfa7598
	ld	hl, wa                                  ; FA954B  ld HL,WA
	inc	6, xsp                                 ; FA954D  inc 6,XSP
	pushw	0                                    ; FA954F  push 0x0000
	pushw	0xFF                                 ; FA9552  push 0x00ff
	pushw	ix                                   ; FA9555  push IX
Voice_StageRegs_09C0_0A00_0A40_AB__FA9556:
	calr (0xFA7598 - 0xFA9559)                 ; FA9556  calr 0xfa7598
	ld	ix, wa                                  ; FA9559  ld IX,WA
	pushw	0xFFCE                               ; FA955B  push 0xffce
	pushw	50                                   ; FA955E  push 0x0032
	ld	xbc, (xiz-10)                           ; FA9561  ld XBC,(XIZ+0xf6)
	ld	a, (xbc+61)                             ; FA9564  ld A,(XBC+0x3d)
	exts	wa                                    ; FA9567  exts WA
	ld	de, wa                                  ; FA9569  ld DE,WA
	ld	a, (xbc+66)                             ; FA956B  ld A,(XBC+0x42)
	exts	wa                                    ; FA956E  exts WA
	add	wa, de                                 ; FA9570  add WA,DE
	pushw	wa                                   ; FA9572  push WA
	calr (0xFA7598 - 0xFA9576)                 ; FA9573  calr 0xfa7598
	pushw	wa                                   ; FA9576  push WA
	calr (0xFA7602 - 0xFA957A)                 ; FA9577  calr 0xfa7602
	ld	de, wa                                  ; FA957A  ld DE,WA
	pushw	0xFFCE                               ; FA957C  push 0xffce
	pushw	50                                   ; FA957F  push 0x0032
	ld	xbc, (xiz-10)                           ; FA9582  ld XBC,(XIZ+0xf6)
	ld	a, (xbc+61)                             ; FA9585  ld A,(XBC+0x3d)
	exts	wa                                    ; FA9588  exts WA
	ld	(xiz-12), wa                            ; FA958A  ld (XIZ+0xf4),WA
	ld	a, (xbc+68)                             ; FA958D  ld A,(XBC+0x44)
	exts	wa                                    ; FA9590  exts WA
	extpfx3 0x9E, 0xF4, 0x80                   ; FA9592  add WA,(XIZ+0xf4)
	pushw	wa                                   ; FA9595  push WA
	calr (0xFA7598 - 0xFA9599)                 ; FA9596  calr 0xfa7598
	pushw	wa                                   ; FA9599  push WA
	calr (0xFA7602 - 0xFA959D)                 ; FA959A  calr 0xfa7602
	ld	(xiz-14), wa                            ; FA959D  ld (XIZ+0xf2),WA
	ld	bc, de                                  ; FA95A0  ld BC,DE
	and	bc, 0xFF                               ; FA95A2  and BC,0x00ff
	ld	(xiz-16), bc                            ; FA95A6  ld (XIZ+0xf0),BC
	ld	iy, hl                                  ; FA95A9  ld IY,HL
	sll	iy, 8                                  ; FA95AB  sll 0x08,IY
	or	iy, bc                                  ; FA95AE  or IY,BC
	stw_da	(0xD786), iy                        ; FA95B0  ld (0x00d786),IY
	ld	hl, (xiz-14)                            ; FA95B5  ld HL,(XIZ+0xf2)
	and	hl, 0xFF                               ; FA95B8  and HL,0x00ff
	ld	bc, ix                                  ; FA95BC  ld BC,IX
	sll	bc, 8                                  ; FA95BE  sll 0x08,BC
	or	bc, hl                                  ; FA95C1  or BC,HL
	stw_da	(0xD788), bc                        ; FA95C3  ld (0x00d788),BC
	add	xsp, 22                                ; FA95C8  add XSP,0x00000016
	popw	ix                                    ; FA95CE  pop IX
	popw	de                                    ; FA95CF  pop DE
	popw	hl                                    ; FA95D0  pop HL
	unlk32 xiz                                 ; FA95D1  unlk XIZ
	ret                                        ; FA95D3  ret
; --------------------------------------------------------------------------
; Voice_StageRegs_0500_08C0_AB -- 0xFA95D4..0xFA96F6 (291 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFB0B25 in VoiceRegs_Stage_A, 0xFB1F13 in VoiceRegs_Stage_B
; Inputs:  frame `link XIZ,-10`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D774, 0x00D77C
;          reads 0x00D77E
; Calls:   0xFA7598 = Clamp_ToRange_Word, 0xFA75BA = ScaleCoeff_TimesAbsDepth_Shr
;          0xFA7602 = DetuneCurve_LookupSigned, 0xFA7654 = DetuneCurve_LookupUnsigned
;          0xFC810C = sub_FC810C
; Voice record: touches voice_record[+0x01(r), +0x0C(r), +0x17(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA95D4-0xFA96F6
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ WHAT IT STAGES: words 11 and 15 -- registers 0x0500 + chan and 0x08C0 + chan -- and
;          nothing else.  `ld (0x00d774),WA` at 0xFA96B0 and `or (0x00d774),BC` at 0xFA96D4
;          are word 11; `ld (0x00d77c),BC` at 0xFA96C3 and 0xFA96EC are word 15.
; ★ REGISTER 0x0500 + chan IS ASSEMBLED AS A BYTE PAIR, AND ITS HIGH BYTE COMES OUT OF
;          THE DETUNE CURVE:
;              hi = Clamp_ToRange_Word( ScaleCoeff_TimesAbsDepth_Shr(tone[+0x12], voice[+0x0C], 6)
;                                       + DetuneCurve_LookupSigned(...), 0, 0x7F )
;              lo = Clamp_ToRange_Word( ScaleCoeff_TimesAbsDepth_Shr(tone[+0x48], voice[+0x0C], 6) + 0x7F,
;                                       0, 0x7F ) & 0xFF
;              word 11 = (hi << 8) | lo                      (`sll 0x08,WA / or WA,BC`,
;                                                             0xFA96AB-0xFA96B0)
;          This routine is one of only four in the image that call
;          DetuneCurve_LookupSigned (0xFA961F, 0xFA9676) and DetuneCurve_LookupUnsigned
;          (0xFA9651, 0xFA9667), and it is the ONLY producer of register 0x0500 that
;          computes rather than clears it.
; ★ AND THE LOW BYTE IS CACHED PER VOICE.  0xFA9609/0xFA960D hands it to sub_FC810C,
;          which stores it at RAM 0x00E1DD + voice[+0x00]; Voice_StageRegs_CD clears that slot on
;          the C/D path (0xFA9740) and sub_FC7FCA reads it back and ORs it into word 11
;          (0xFC80D6) when it rebuilds the register.  Three routines, one byte, one
;          register field.
; Called from: VoiceRegs_Stage_A (0xFB0B25) and VoiceRegs_Stage_B (0xFB1F13).  The C/D
;          path has no computing counterpart: Voice_StageRegs_CD zeroes both words and leaves
;          word 11 to sub_FC7FCA.
; ⚠ SIBLING: the KN5000 sub-CPU calls its register 0x500 the "detune / bend pair"
;          (kn5000_subprogram_v142.s:6949).  A byte pair whose high byte is a detune-curve
;          lookup is what that predicts; see
;          notes/FINDINGS-prom_c-dev10c-sibling-register-map.md §5.  ⚠ No byte comparison
;          was made for this routine, and "bend" is not asserted here.
; Unknown:  what ScaleCoeff_TimesAbsDepth_Shr computes, and what tone fields +0x12 and +0x48 are.
; --------------------------------------------------------------------------
Voice_StageRegs_0500_08C0_AB:
	link32 0xEE, 0x0C, 0xF6, 0xFF              ; FA95D4  link XIZ,0xfff6
	pushw	hl                                   ; FA95D8  push HL
	pushw	de                                   ; FA95D9  push DE
	pushw	ix                                   ; FA95DA  push IX
	ld	bc, (xiz+8)                             ; FA95DB  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA95DE  extz XBC
	ld	xwa, (xbc+23)                           ; FA95E0  ld XWA,(XBC+0x17)
	ld	(xiz-6), xwa                            ; FA95E3  ld (XIZ+0xfa),XWA
	pushw	6                                    ; FA95E6  push 0x0006
	ld	a, (xbc+12)                             ; FA95E9  ld A,(XBC+0x0c)
	pushw	wa                                   ; FA95EC  push WA
	ld	xwa, (xiz-6)                            ; FA95ED  ld XWA,(XIZ+0xfa)
	ld	c, (xwa+72)                             ; FA95F0  ld C,(XWA+0x48)
	pushw	bc                                   ; FA95F3  push BC
	calr (0xFA75BA - 0xFA95F7)                 ; FA95F4  calr 0xfa75ba
	ld	hl, wa                                  ; FA95F7  ld HL,WA
	add	hl, 0x7F                               ; FA95F9  add HL,0x007f
	pushw	0                                    ; FA95FD  push 0x0000
	pushw	0x7F                                 ; FA9600  push 0x007f
	pushw	hl                                   ; FA9603  push HL
	calr (0xFA7598 - 0xFA9607)                 ; FA9604  calr 0xfa7598
	ld	ix, wa                                  ; FA9607  ld IX,WA
	pushw	wa                                   ; FA9609  push WA
	extpfx3 0x9E, 0x08, 0x04                   ; FA960A  pushw (XIZ+0x08)
	call	0xFC810C                              ; FA960D  call 0xfc810c
	ld	xbc, (xiz-6)                            ; FA9611  ld XBC,(XIZ+0xfa)
	ld	h, (xbc+61)                             ; FA9614  ld H,(XBC+0x3d)
	ld	a, (xbc+62)                             ; FA9617  ld A,(XBC+0x3e)
	add	a, h                                   ; FA961A  add A,H
	exts	wa                                    ; FA961C  exts WA
	pushw	wa                                   ; FA961E  push WA
	calr (0xFA7602 - 0xFA9622)                 ; FA961F  calr 0xfa7602
	ld	(xiz-2), wa                             ; FA9622  ld (XIZ+0xfe),WA
	ld	bc, (xiz+8)                             ; FA9625  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9628  extz XBC
	ld	iy, (xbc+1)                             ; FA962A  ld IY,(XBC+0x01)
	and	iy, 0x200                              ; FA962D  and IY,0x0200
	add	xsp, 18                                ; FA9631  add XSP,0x00000012
	cps	iy, 0                                  ; FA9637  cp IY,0
	jrl nz, Voice_StageRegs_0500_08C0_AB__FA96CE                 ; FA9639  jrl NZ,0xfa96ce
	ld	xiy, (xiz-6)                            ; FA963C  ld XIY,(XIZ+0xfa)
	ld	d, (xiy+7)                              ; FA963F  ld D,(XIY+0x07)
	ld	c, d                                    ; FA9642  ld C,D
	exts	bc                                    ; FA9644  exts BC
	ld	hl, bc                                  ; FA9646  ld HL,BC
	cps	d, 0                                   ; FA9648  cp D,0
	jr ge, Voice_StageRegs_0500_08C0_AB__FA9666                  ; FA964A  jr GE,0xfa9666
	cpl	bc                                     ; FA964C  cpl BC
	inc	1, bc                                  ; FA964E  inc 1,BC
	pushw	bc                                   ; FA9650  push BC
	calr (0xFA7654 - 0xFA9654)                 ; FA9651  calr 0xfa7654
	ld	hl, wa                                  ; FA9654  ld HL,WA
	ld	xbc, (xiz-6)                            ; FA9656  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+8)                              ; FA9659  ld A,(XBC+0x08)
	exts	wa                                    ; FA965C  exts WA
	cpl	wa                                     ; FA965E  cpl WA
	inc	1, wa                                  ; FA9660  inc 1,WA
	popw	iy                                    ; FA9662  pop IY
	pushw	wa                                   ; FA9663  push WA
	jr Voice_StageRegs_0500_08C0_AB__FA9676                      ; FA9664  jr T,0xfa9676
Voice_StageRegs_0500_08C0_AB__FA9666:
	pushw	hl                                   ; FA9666  push HL
	calr (0xFA7654 - 0xFA966A)                 ; FA9667  calr 0xfa7654
	ld	hl, wa                                  ; FA966A  ld HL,WA
	ld	xbc, (xiz-6)                            ; FA966C  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+8)                              ; FA966F  ld A,(XBC+0x08)
	exts	wa                                    ; FA9672  exts WA
	popw	iy                                    ; FA9674  pop IY
	pushw	wa                                   ; FA9675  push WA
Voice_StageRegs_0500_08C0_AB__FA9676:
	calr (0xFA7602 - 0xFA9679)                 ; FA9676  calr 0xfa7602
	ld	de, wa                                  ; FA9679  ld DE,WA
	pushw	6                                    ; FA967B  push 0x0006
	ld	bc, (xiz+8)                             ; FA967E  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9681  extz XBC
	ld	a, (xbc+12)                             ; FA9683  ld A,(XBC+0x0c)
	pushw	wa                                   ; FA9686  push WA
	ld	xwa, (xiz-6)                            ; FA9687  ld XWA,(XIZ+0xfa)
	ld	c, (xwa+18)                             ; FA968A  ld C,(XWA+0x12)
	pushw	bc                                   ; FA968D  push BC
	calr (0xFA75BA - 0xFA9691)                 ; FA968E  calr 0xfa75ba
	add	wa, hl                                 ; FA9691  add WA,HL
	ld	(xiz-8), wa                             ; FA9693  ld (XIZ+0xf8),WA
	pushw	0                                    ; FA9696  push 0x0000
	pushw	0x7F                                 ; FA9699  push 0x007f
	pushw	wa                                   ; FA969C  push WA
	calr (0xFA7598 - 0xFA96A0)                 ; FA969D  calr 0xfa7598
	ld	hl, wa                                  ; FA96A0  ld HL,WA
	ld	bc, ix                                  ; FA96A2  ld BC,IX
	and	bc, 0xFF                               ; FA96A4  and BC,0x00ff
	ld	(xiz-10), bc                            ; FA96A8  ld (XIZ+0xf6),BC
	sll	wa, 8                                  ; FA96AB  sll 0x08,WA
	or	wa, bc                                  ; FA96AE  or WA,BC
	stw_da	(0xD774), wa                        ; FA96B0  ld (0x00d774),WA
	ld	hl, (xiz-2)                             ; FA96B5  ld HL,(XIZ+0xfe)
	and	hl, 0xFF                               ; FA96B8  and HL,0x00ff
	ld	bc, de                                  ; FA96BC  ld BC,DE
	sll	bc, 8                                  ; FA96BE  sll 0x08,BC
	or	bc, hl                                  ; FA96C1  or BC,HL
	stw_da	(0xD77C), bc                        ; FA96C3  ld (0x00d77c),BC
	inc	8, xsp                                 ; FA96C8  inc 0,XSP
	inc	6, xsp                                 ; FA96CA  inc 6,XSP
	jr Voice_StageRegs_0500_08C0_AB__FA96F1                      ; FA96CC  jr T,0xfa96f1
Voice_StageRegs_0500_08C0_AB__FA96CE:
	ld	bc, ix                                  ; FA96CE  ld BC,IX
	and	bc, 0xFF                               ; FA96D0  and BC,0x00ff
	ordm16_24	(0xD774), bc                     ; FA96D4  or (0x00d774),BC
	ldw_da	bc, (0xD77E)                        ; FA96D9  ld BC,(0x00d77e)
	ld	hl, bc                                  ; FA96DE  ld HL,BC
	sll	hl, 8                                  ; FA96E0  sll 0x08,HL
	ld	bc, (xiz-2)                             ; FA96E3  ld BC,(XIZ+0xfe)
	and	bc, 0xFF                               ; FA96E6  and BC,0x00ff
	or	bc, hl                                  ; FA96EA  or BC,HL
	stw_da	(0xD77C), bc                        ; FA96EC  ld (0x00d77c),BC
Voice_StageRegs_0500_08C0_AB__FA96F1:
	popw	ix                                    ; FA96F1  pop IX
	popw	de                                    ; FA96F2  pop DE
	popw	hl                                    ; FA96F3  pop HL
	unlk32 xiz                                 ; FA96F4  unlk XIZ
	ret                                        ; FA96F6  ret
; --------------------------------------------------------------------------
; Voice_StageRegs_CD -- 0xFA96F7..0xFA981A (292 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFB2850 in VoiceRegs_Stage_C, 0xFB2F25 in VoiceRegs_Stage_D
; Inputs:  frame `link XIZ,-1`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D76A, 0x00D76E, 0x00D770, 0x00D772, 0x00D774, 0x00D77C, 0x00D77E, 0x00D780, 0x00D782, 0x00D784, 0x00D786, 0x00D788
; Calls:   0xFA7EE2 = Clamp_ToRange_LowByte, 0xFA7F04 = Rand_FromTickSquared
;          0xFC7FCA = sub_FC7FCA, 0xFC810C = sub_FC810C
; Voice record: touches voice_record[+0x01(r), +0x17(r), +0x23(r), +0x25(r), +0x27(rw)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA96F7-0xFA981A
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
;
; ★ THE C/D COUNTERPART OF THE A/B STAGERS, and the reason gap A's four registers
;   read 0x0000 on two of the four voice paths.  It is called only from
;   VoiceRegs_Stage_C (0xFB2850) and VoiceRegs_Stage_D (0xFB2F25), and it ZEROES
;   all four of gap A's staging words rather than computing them:
;       0xFA970F  word 11 (+0x16) -> register chan+0x0500
;       0xFA9773  word  8 (+0x10) -> register chan+0x0440
;       0xFA977A  word  9 (+0x12) -> register chan+0x0480
;       0xFA980E  word 10 (+0x14) -> register chan+0x04C0
;   No channel-selector value is ever computed on the C and D paths: the two
;   routines that compute them, Voice_StageChanSel_Reg0440_Reg0480 and
;   Voice_StageChanSel_Reg04C0, are reached only from VoiceRegs_Stage_A/_B and
;   from two refresh loops.  Word 11 is not left at zero -- 0xFA9760 calls
;   sub_FC7FCA, which rebuilds it from the per-voice byte cached at 0x00E1DD.
; Evidence: the four `ld (0x00d7xx),0x0000` stores above are the whole census of
;          absolute writes to those words on this path; the census is a raw-byte
;          sweep of all four ROM images, `python3
;          notes/prom_c_understanding_round4.py --sites` (4/3/3/3 sites, all in
;          prom_c, none in prom_a, prom_b or prom_d).
; Unknown:  what the routine is FOR beyond staging; the twelve words it writes are
;          named by their register, not by their meaning.
; --------------------------------------------------------------------------
Voice_StageRegs_CD:
	link32 0xEE, 0x0C, 0xFF, 0xFF              ; FA96F7  link XIZ,0xffff
	push	xhl                                   ; FA96FB  push XHL
	pushw	de                                   ; FA96FC  push DE
	push	xix                                   ; FA96FD  push XIX
	ld	bc, (xiz+8)                             ; FA96FE  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9701  extz XBC
	ld	xwa, (xbc+23)                           ; FA9703  ld XWA,(XBC+0x17)
	ld	xix, xwa                                ; FA9706  ld XIX,XWA
	stiw_da	(0xD77C), 0                        ; FA9708  ld (0x00d77c),0x0000
	stiw_da	(0xD774), 0                        ; FA970F  ld (0x00d774),0x0000
	stiw_da	(0xD77E), 0                        ; FA9716  ld (0x00d77e),0x0000
	stiw_da	(0xD780), 0                        ; FA971D  ld (0x00d780),0x0000
	stiw_da	(0xD782), 0                        ; FA9724  ld (0x00d782),0x0000
	stiw_da	(0xD784), 0                        ; FA972B  ld (0x00d784),0x0000
	stiw_da	(0xD786), 0                        ; FA9732  ld (0x00d786),0x0000
	stiw_da	(0xD788), 0                        ; FA9739  ld (0x00d788),0x0000
	pushw	0                                    ; FA9740  push 0x0000
	extpfx3 0x9E, 0x08, 0x04                   ; FA9743  pushw (XIZ+0x08)
	call	0xFC810C                              ; FA9746  call 0xfc810c
	ld	bc, (xiz+8)                             ; FA974A  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA974D  extz XBC
	ld	wa, (xbc+1)                             ; FA974F  ld WA,(XBC+0x01)
	and	wa, 0x200                              ; FA9752  and WA,0x0200
	pop	xiy                                    ; FA9756  pop XIY
	jr z, Voice_StageRegs_CD__FA9773                   ; FA9757  jr Z,0xfa9773
	lda	xwa, (0xD75E:24)                       ; FA9759  lda XWA,0x00d75e
	push	xwa                                   ; FA975E  push XWA
	pushw	bc                                   ; FA975F  push BC
	call	0xFC7FCA                              ; FA9760  call 0xfc7fca
	ldw_da	bc, (0xD77E)                        ; FA9764  ld BC,(0x00d77e)
	sll	bc, 8                                  ; FA9769  sll 0x08,BC
	ordm16_24	(0xD77C), bc                     ; FA976C  or (0x00d77c),BC
	inc	6, xsp                                 ; FA9771  inc 6,XSP
Voice_StageRegs_CD__FA9773:
	stiw_da	(0xD76E), 0                        ; FA9773  ld (0x00d76e),0x0000
	stiw_da	(0xD770), 0                        ; FA977A  ld (0x00d770),0x0000
	ld	c, (xix+1)                              ; FA9781  ld C,(XIX+0x01)
	ld	(xiz-1), c                              ; FA9784  ld (XIZ+0xff),C
	cp	c, 0x80                                 ; FA9787  cp C,0x80
	jr nz, Voice_StageRegs_CD__FA979F                  ; FA978A  jr NZ,0xfa979f
	calr (0xFA7F04 - 0xFA978F)                 ; FA978C  calr 0xfa7f04
	res	7, a                                   ; FA978F  res 0x07,A
	exts	wa                                    ; FA9792  exts WA
	ld	bc, (xiz+8)                             ; FA9794  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9797  extz XBC
	ld	(xbc+39), wa                            ; FA9799  ld (XBC+0x27),WA
	jrl Voice_StageRegs_CD__FA9801                     ; FA979C  jrl T,0xfa9801
Voice_StageRegs_CD__FA979F:
	ld	hl, (xiz+8)                             ; FA979F  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FA97A2  extz XHL
	ld	hl, (xhl+37)                            ; FA97A4  ld HL,(XHL+0x25)
	extz	xhl                                   ; FA97A7  extz XHL
	ld	bc, (xhl+26)                            ; FA97A9  ld BC,(XHL+0x1a)
	and	bc, 64                                 ; FA97AC  and BC,0x0040
	jr z, Voice_StageRegs_CD__FA97F4                   ; FA97B0  jr Z,0xfa97f4
	extz	xhl                                   ; FA97B2  extz XHL
	ld	bc, (xhl+28)                            ; FA97B4  ld BC,(XHL+0x1c)
	ld	ix, bc                                  ; FA97B7  ld IX,BC
	and	ix, 64                                 ; FA97B9  and IX,0x0040
	pushw	0                                    ; FA97BD  push 0x0000
	pushw	0x7F                                 ; FA97C0  push 0x007f
	ld	de, (xiz-1)                             ; FA97C3  ld DE,(XIZ+0xff)
	extz	de                                    ; FA97C6  extz DE
	ld	bc, (xiz+8)                             ; FA97C8  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA97CB  extz XBC
	ld	wa, (xbc+35)                            ; FA97CD  ld WA,(XBC+0x23)
	extz	xwa                                   ; FA97D0  extz XWA
	ld	hl, (xwa+37)                            ; FA97D2  ld HL,(XWA+0x25)
	jr z, Voice_StageRegs_CD__FA97DE                   ; FA97D5  jr Z,0xfa97de
	ld	wa, de                                  ; FA97D7  ld WA,DE
	sub	wa, hl                                 ; FA97D9  sub WA,HL
	pushw	wa                                   ; FA97DB  push WA
	jr Voice_StageRegs_CD__FA97E3                      ; FA97DC  jr T,0xfa97e3
Voice_StageRegs_CD__FA97DE:
	ld	bc, de                                  ; FA97DE  ld BC,DE
	add	bc, hl                                 ; FA97E0  add BC,HL
	pushw	bc                                   ; FA97E2  push BC
Voice_StageRegs_CD__FA97E3:
	calr (0xFA7EE2 - 0xFA97E6)                 ; FA97E3  calr 0xfa7ee2
	exts	wa                                    ; FA97E6  exts WA
	ld	bc, (xiz+8)                             ; FA97E8  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA97EB  extz XBC
	ld	(xbc+39), wa                            ; FA97ED  ld (XBC+0x27),WA
	inc	6, xsp                                 ; FA97F0  inc 6,XSP
	jr Voice_StageRegs_CD__FA9801                      ; FA97F2  jr T,0xfa9801
Voice_StageRegs_CD__FA97F4:
	ld	bc, (xiz-1)                             ; FA97F4  ld BC,(XIZ+0xff)
	extz	bc                                    ; FA97F7  extz BC
	ld	wa, (xiz+8)                             ; FA97F9  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA97FC  extz XWA
	ld	(xwa+39), bc                            ; FA97FE  ld (XWA+0x27),BC
Voice_StageRegs_CD__FA9801:
	ld	bc, (xiz+8)                             ; FA9801  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9804  extz XBC
	ld	wa, (xbc+39)                            ; FA9806  ld WA,(XBC+0x27)
	stw_da	(0xD76A), wa                        ; FA9809  ld (0x00d76a),WA
	stiw_da	(0xD772), 0                        ; FA980E  ld (0x00d772),0x0000
	pop	xix                                    ; FA9815  pop XIX
	popw	de                                    ; FA9816  pop DE
	pop	xhl                                    ; FA9817  pop XHL
	unlk32 xiz                                 ; FA9818  unlk XIZ
	ret                                        ; FA981A  ret
; --------------------------------------------------------------------------
; sub_FA981B -- 0xFA981B..0xFA9914 (250 bytes)
;
; Called from: 9 site(s) outside this module:
;          0xFAE436 in Voice_Restage_Reg0440_BaseCurve_ForPart__FAE404, 0xFAE56A in Voice_Restage_Reg0440_ValueCurve_ForPart__FAE53D
;          0xFAE6B5 in Voice_Restage_Reg0180_BaseCurve_ForPart__FAE683, 0xFAE7EB in Voice_Restage_Reg0180_ValueCurve_ForPart__FAE7BE
;          0xFAE936 in Voice_Restage_Reg04C0_BaseCurve_ForPart__FAE904, 0xFAEA6F in Voice_Restage_Reg04C0_ValueCurve_ForPart__FAEA41
;          0xFB8ABD in Voice_RecomputeEnv_AndWriteSlot2__FB8A85, 0xFB8BBD in Voice_RecomputeEnv_AndWriteSlot1__FB8B85
;          0xFB8CBD in Voice_RecomputeEnv_AndWriteSlot1or3__FB8C85
;          3 site(s) inside this module:
;          0xFA9A2C 0xFA9D72 0xFAA01C
; Inputs:  frame `link XIZ,-20`; argument slots read: (XIZ+0x08), (XIZ+0x0C), (XIZ+0x0E), (XIZ+0x10)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA981B-0xFA9914
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FA981B:
	link32 0xEE, 0x0C, 0xEC, 0xFF              ; FA981B  link XIZ,0xffec
	push	xhl                                   ; FA981F  push XHL
	push	xde                                   ; FA9820  push XDE
	push	xix                                   ; FA9821  push XIX
	ldb	c, 4                                   ; FA9822  ld C,0x04
	extpfx3 0x8E, 0x0C, 0x43                   ; FA9824  mul BC,(XIZ+0x0c)
	ld	(xiz-2), bc                             ; FA9827  ld (XIZ+0xfe),BC
	extz	xbc                                   ; FA982A  extz XBC
	ld	(xiz-6), xbc                            ; FA982C  ld (XIZ+0xfa),XBC
	ldb	a, 16                                  ; FA982F  ld A,0x10
	extpfx3 0x8E, 0x0E, 0x41                   ; FA9831  mul WA,(XIZ+0x0e)
	ld	(xiz-8), wa                             ; FA9834  ld (XIZ+0xf8),WA
	extz	xwa                                   ; FA9837  extz XWA
	add	xwa, xbc                               ; FA9839  add XWA,XBC
	add	xwa, 87                                ; FA983B  add XWA,0x00000057
	ld	(xiz-12), xwa                           ; FA9841  ld (XIZ+0xf4),XWA
	ld	bc, (xiz+8)                             ; FA9844  ld BC,(XIZ+0x08)
	extz	bc                                    ; FA9847  extz BC
	mul	bc, 0x12C                              ; FA9849  mul BC,0x012c
	ld	(xiz-14), bc                            ; FA984D  ld (XIZ+0xf2),BC
	extz	xbc                                   ; FA9850  extz XBC
	ld	xiy, (xbc+0x1523)                       ; FA9852  ld XIY,(XBC+0x1523)
	ld	xix, xiy                                ; FA9857  ld XIX,XIY
	add	xiy, xwa                               ; FA9859  add XIY,XWA
	ld	xix, xiy                                ; FA985B  ld XIX,XIY
	ldb	a, 9                                   ; FA985D  ld A,0x09
	extpfx3 0x8E, 0x0E, 0x41                   ; FA985F  mul WA,(XIZ+0x0e)
	ld	(xiz-16), wa                            ; FA9862  ld (XIZ+0xf0),WA
	ldb	c, 27                                  ; FA9865  ld C,0x1b
	extpfx3 0x8E, 0x10, 0x43                   ; FA9867  mul BC,(XIZ+0x10)
	add	bc, wa                                 ; FA986A  add BC,WA
	ld	(xiz-18), bc                            ; FA986C  ld (XIZ+0xee),BC
	ldw	hl, 0x4CCF                             ; FA986F  ld HL,0x4ccf
	add	hl, bc                                 ; FA9872  add HL,BC
	ld	bc, (xiz-14)                            ; FA9874  ld BC,(XIZ+0xf2)
	extpfx3 0x9E, 0xF8, 0x81                   ; FA9877  add BC,(XIZ+0xf8)
	extpfx3 0x9E, 0xFE, 0x81                   ; FA987A  add BC,(XIZ+0xfe)
	add	bc, 53                                 ; FA987D  add BC,0x0035
	ld	(xiz-20), bc                            ; FA9881  ld (XIZ+0xec),BC
	ldw	de, 0x1523                             ; FA9884  ld DE,0x1523
	add	de, bc                                 ; FA9887  add DE,BC
	ld	c, (xiy)                                ; FA9889  ld C,(XIY)
	extz	xhl                                   ; FA988B  extz XHL
	ld	(xhl+1), c                              ; FA988D  ld (XHL+0x01),C
	ld	c, (xix+1)                              ; FA9890  ld C,(XIX+0x01)
	ld	(xhl+3), c                              ; FA9893  ld (XHL+0x03),C
	ld	c, (xix+3)                              ; FA9896  ld C,(XIX+0x03)
	and	c, 63                                  ; FA9899  and C,0x3f
	ld	(xhl+7), c                              ; FA989C  ld (XHL+0x07),C
	extz	xde                                   ; FA989F  extz XDE
	ld	c, (xde)                                ; FA98A1  ld C,(XDE)
	and	c, 2                                   ; FA98A3  and C,0x02
	jr z, sub_FA981B__FA98B4                   ; FA98A6  jr Z,0xfa98b4
	extz	xde                                   ; FA98A8  extz XDE
	ld	c, (xde+3)                              ; FA98AA  ld C,(XDE+0x03)
	extz	xhl                                   ; FA98AD  extz XHL
	ld	(xhl+2), c                              ; FA98AF  ld (XHL+0x02),C
	jr sub_FA981B__FA98BA                      ; FA98B2  jr T,0xfa98ba
sub_FA981B__FA98B4:
	extz	xhl                                   ; FA98B4  extz XHL
	ld	(xhl+2), 0x80                           ; FA98B6  ld (XHL+0x02),0x80
sub_FA981B__FA98BA:
	extz	xde                                   ; FA98BA  extz XDE
	ld	c, (xde)                                ; FA98BC  ld C,(XDE)
	and	c, 8                                   ; FA98BE  and C,0x08
	jr z, sub_FA981B__FA98CF                   ; FA98C1  jr Z,0xfa98cf
	extz	xde                                   ; FA98C3  extz XDE
	ld	c, (xde+2)                              ; FA98C5  ld C,(XDE+0x02)
	extz	xhl                                   ; FA98C8  extz XHL
	ld	(xhl+4), c                              ; FA98CA  ld (XHL+0x04),C
	jr sub_FA981B__FA98D5                      ; FA98CD  jr T,0xfa98d5
sub_FA981B__FA98CF:
	extz	xhl                                   ; FA98CF  extz XHL
	ld	(xhl+4), 0x80                           ; FA98D1  ld (XHL+0x04),0x80
sub_FA981B__FA98D5:
	ld	c, (xix+2)                              ; FA98D5  ld C,(XIX+0x02)
	and	c, 0x80                                ; FA98D8  and C,0x80
	jr z, sub_FA981B__FA98E4                   ; FA98DB  jr Z,0xfa98e4
	extz	xhl                                   ; FA98DD  extz XHL
	extpfx3 0x83, 0x3E, 0x20                   ; FA98DF  or (XHL),0x20
	jr sub_FA981B__FA98E9                      ; FA98E2  jr T,0xfa98e9
sub_FA981B__FA98E4:
	extz	xhl                                   ; FA98E4  extz XHL
	extpfx3 0x83, 0x3C, 0xDF                   ; FA98E6  and (XHL),0xdf
sub_FA981B__FA98E9:
	ld	c, (xix+3)                              ; FA98E9  ld C,(XIX+0x03)
	and	c, 0xC0                                ; FA98EC  and C,0xc0
	extz	bc                                    ; FA98EF  extz BC
	ld	de, bc                                  ; FA98F1  ld DE,BC
	srl	de, 6                                  ; FA98F3  srl 0x06,DE
	extz	xhl                                   ; FA98F6  extz XHL
	extpfx3 0x83, 0x3C, 0xFC                   ; FA98F8  and (XHL),0xfc
	ld	c, (xhl)                                ; FA98FB  ld C,(XHL)
	ld	(xiz-2), c                              ; FA98FD  ld (XIZ+0xfe),C
	ld	a, e                                    ; FA9900  ld A,E
	or	c, a                                    ; FA9902  or C,A
	ld	(xhl), c                                ; FA9904  ld (XHL),C
	ld	c, (xix+2)                              ; FA9906  ld C,(XIX+0x02)
	res	7, c                                   ; FA9909  res 0x07,C
	ld	(xhl+5), c                              ; FA990C  ld (XHL+0x05),C
	pop	xix                                    ; FA990F  pop XIX
	pop	xde                                    ; FA9910  pop XDE
	pop	xhl                                    ; FA9911  pop XHL
	unlk32 xiz                                 ; FA9912  unlk XIZ
	ret                                        ; FA9914  ret
; --------------------------------------------------------------------------
; Voice_StageChanSel_Reg0440_Reg0480 -- 0xFA9915..0xFA9C5F (843 bytes)
;
; Called from: 4 site(s) outside this module:
;          0xFAE3C4 in Voice_Restage_Reg0440_BaseCurve_ForPart__FAE3B5, 0xFAE4FE in Voice_Restage_Reg0440_ValueCurve_ForPart__FAE4EF
;          0xFB0B2A in VoiceRegs_Stage_A, 0xFB1F18 in VoiceRegs_Stage_B
; Inputs:  frame `link XIZ,-12`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D76E, 0x00D770, 0x00D79A, 0x00D79C, 0x00D79E, 0x00D7A0
; Calls:   0xFA5ED3 = Voice_LookupDev10CChanIndex, 0xFA78E8 = sub_FA78E8
;          0xFA7927 = sub_FA7927, 0xFA796D = EGEnv_Eval_BaseCurveA
;          0xFA79F4 = EGEnv_Eval_ValueCurve_WithBaseCurveA, 0xFA981B = sub_FA981B
;          0xFB5B56 = sub_FB5B56, 0xFB5E39 = Dev10C_ChanSelHighBits
;          0xFB7C27 = Dev10C_Slot2_WriteGateAndValue, 0xFB7C8F = Dev10C_SetChanReg_0600_b
;          0xFB7CB1 = Dev10C_Slot2_StrobeGate, 0xFB7CFF = Dev10C_Slot2_WriteGate8100
;          0xFB7D1D = Dev10C_Slot3_WriteGateAndValue
; Voice record: touches voice_record[+0x00(r), +0x03(r), +0x04(r), +0x0C(r), +0x13(r), +0x23(r), +0x25(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA9915-0xFA9C5F
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
;
; ★★ GAP A -- THIS IS WHERE REGISTERS 0x0440 AND 0x0480 GET THEIR VALUE.
;   It stages the 0x0010C000 staging struct's words 8 and 9,
;       word 8 (+0x10, RAM 0x00D76E) -> register chan+0x0440
;       word 9 (+0x12, RAM 0x00D770) -> register chan+0x0480
;   and both words have the same shape:   word = MODE | CHANNEL.
;
;   ★ THE CHANNEL FIELD IS A CHANNEL OF THIS SAME DEVICE, in the device's own
;   encoding -- bit for bit the value this routine hands, a few instructions
;   later, to a Dev10C_Slot* accessor as that accessor's `chan` argument, where
;   it is added to a register-block base to form the device's register selector.
;   Bits 5..0 are the channel of the 64-channel device and BIT 6 CHOOSES THE
;   BLOCK: Dev10C_Slot1or3_StrobeGate splits on exactly that bit (`cp HL,0x0040`
;   at 0xFB801F) and the two arms read the two slots' own staging fields --
;   +0x3A with block 0x0540 on the low arm (0xFB8025/0xFB8030), +0x3E with
;   0x0580+arg = 0x05C0 + (arg & 0x3F) on the high (0xFB8065/0xFB8070), which is
;   exactly what Dev10C_Slot1_ and Dev10C_Slot3_WriteGateAndValue use.
;
; Evidence, word 8, path A -- MODE from the tone descriptor:
;          0xFA9992 `call Voice_LookupDev10CChanIndex`; 0xFA999A `and DE,0x007f`
;          is the CHANNEL field, and the SAME DE is pushed at 0xFA999E into
;          Dev10C_Slot2_WriteGate8100 (0xFA999F), which forms chan+0x0580 at
;          0xFB7D08.  0xFA99F0 `ld WA,(XBC+0x1e)` / 0xFA99F3 `and WA,0x00c0` is
;          the MODE field; 0xFA99F7 `or WA,DE`; 0xFA99F9 `ld (0x00d76e),WA`.
; Evidence, word 8, path B -- MODE from Dev10C_ChanSelHighBits:
;          0xFA9AE7 `call Dev10C_ChanSelHighBits` -> DE, rejected if 0
;          (0xFA9AEF/0xFA9AF1); 0xFA9B04 `call Voice_LookupDev10CChanIndex`,
;          rejected if its low byte is >= 0x80 (0xFA9B0A/0xFA9B10/0xFA9B14);
;          0xFA9B18 `and IX,0x007f`; 0xFA9B28 `or BC,IX`; 0xFA9B2A
;          `ld (0x00d76e),BC`.  The same masked value reaches
;          Dev10C_Slot2_WriteGateAndValue at 0xFA9B68/0xFA9B6C/0xFA9B6D.
; Evidence, word 9:
;          0xFA9B90 `call Dev10C_ChanSelHighBits` -> DE, rejected if 0
;          (0xFA9B98/0xFA9B9A); 0xFA9BAD `call Voice_LookupDev10CChanIndex`,
;          rejected if >= 0x80 (0xFA9BB3/0xFA9BB9/0xFA9BBD); 0xFA9BC2
;          `and BC,0x003f` -- SIX bits here, not seven; 0xFA9BC6 `or BC,DE`;
;          0xFA9BC8 `ld (0x00d770),BC`.  The same six-bit value reaches
;          Dev10C_Slot3_WriteGateAndValue at 0xFA9C4D/0xFA9C51/0xFA9C52.
; ⚠ WORD 8's TWO FIELDS OVERLAP AT BIT 6.  Mask 0x00C0 against mask 0x007F leaves
;   bit 6 in both, and they are combined with `or`.  Dev10C_ChanSelHighBits never
;   returns a value with bit 6 clear, so on path B word 8's bit 6 is 1 whatever
;   the channel is.  Either the channel is always <= 0x3F there -- nothing in this
;   routine bounds it -- or the two fields genuinely collide.  Recorded, not
;   explained away.  Word 9 has no such problem: 0x00C0 and 0x003F are disjoint.
; Both words are CLEARED at entry (0xFA991C, 0xFA9923), so a rejected lookup
;   leaves 0x0000 -- which is also their power-on value, from offsets +0x10/+0x12
;   of Dev10C_StagingStruct_ResetImage.
; ⚠ NOT ESTABLISHED: that the named channel is a DIFFERENT channel from the one
;   the struct is committed to.  Nothing here compares the two numbers, so
;   "cross-reference" is a shape and not a proven relation.  Nor what the MODE
;   bits mean: their width, position and source are measured, their meaning is not.
; Evidence: every address above is re-decoded by an INDEPENDENT disassembler at
;          the address quoted, and the write census is a raw-byte sweep of all
;          four ROM images -- `python3 notes/prom_c_understanding_round4.py`,
;          sections 1, 2, 3 and 5.  The round-1 lane published this reading with
;          citations that pointed at other instructions; see
;          notes/wave7-round1/README.md lane g1.
; --------------------------------------------------------------------------
Voice_StageChanSel_Reg0440_Reg0480:
	link32 0xEE, 0x0C, 0xF4, 0xFF              ; FA9915  link XIZ,0xfff4
	pushw	hl                                   ; FA9919  push HL
	pushw	de                                   ; FA991A  push DE
	push	xix                                   ; FA991B  push XIX
	stiw_da	(0xD76E), 0                        ; FA991C  ld (0x00d76e),0x0000
	stiw_da	(0xD770), 0                        ; FA9923  ld (0x00d770),0x0000
	ld	bc, (xiz+8)                             ; FA992A  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA992D  extz XBC
	ld	wa, (xbc+35)                            ; FA992F  ld WA,(XBC+0x23)
	ld	(xiz-6), wa                             ; FA9932  ld (XIZ+0xfa),WA
	ld	iy, (xbc+37)                            ; FA9935  ld IY,(XBC+0x25)
	ld	(xiz-8), iy                             ; FA9938  ld (XIZ+0xf8),IY
	ld	a, (xbc+4)                              ; FA993B  ld A,(XBC+0x04)
	ld	(xiz-3), a                              ; FA993E  ld (XIZ+0xfd),A
	ld	w, (xbc+3)                              ; FA9941  ld W,(XBC+0x03)
	ld	(xiz-2), w                              ; FA9944  ld (XIZ+0xfe),W
	ld	hl, iy                                  ; FA9947  ld HL,IY
	add	iy, 30                                 ; FA9949  add IY,0x001e
	ld	hl, iy                                  ; FA994D  ld HL,IY
	extz	xiy                                   ; FA994F  extz XIY
	ld	bc, (xiy)                               ; FA9951  ld BC,(XIY)
	cps	bc, 0                                  ; FA9953  cp BC,0
	jrl z, Voice_StageChanSel_Reg0440_Reg0480__FA9ACB                  ; FA9955  jrl Z,0xfa9acb
	ld	c, (xiy)                                ; FA9958  ld C,(XIY)
	and	c, 3                                   ; FA995A  and C,0x03
	ld	(xiz-1), c                              ; FA995D  ld (XIZ+0xff),C
	mul	c, 4                                   ; FA9960  mul C,0x04
	extz	xbc                                   ; FA9963  extz XBC
	ld	xix, xbc                                ; FA9965  ld XIX,XBC
	add	xix, 89                                ; FA9967  add XIX,0x00000059
	ld	bc, (xiz+8)                             ; FA996D  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9970  extz XBC
	ld	xiy, (xbc+19)                           ; FA9972  ld XIY,(XBC+0x13)
	add	xiy, xix                               ; FA9975  add XIY,XIX
	ld	c, (xiy)                                ; FA9977  ld C,(XIY)
	and	c, 0x80                                ; FA9979  and C,0x80
	jr z, Voice_StageChanSel_Reg0440_Reg0480__FA99A7                   ; FA997C  jr Z,0xfa99a7
	ld	c, (xiz-1)                              ; FA997E  ld C,(XIZ+0xff)
	set	5, c                                   ; FA9981  set 0x05,C
	pushw	bc                                   ; FA9984  push BC
	ld	bc, (xiz+8)                             ; FA9985  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9988  extz XBC
	ld	a, (xbc)                                ; FA998A  ld A,(XBC)
	pushw	wa                                   ; FA998C  push WA
	push	0                                     ; FA998D  push 0x00
	extpfx3 0x8E, 0xFD, 0x04                   ; FA998F  push (XIZ+0xfd)
	call	0xFA5ED3                              ; FA9992  call 0xfa5ed3
	ld	hl, wa                                  ; FA9996  ld HL,WA
	ld	de, wa                                  ; FA9998  ld DE,WA
	and	de, 0x7F                               ; FA999A  and DE,0x007f
	pushw	de                                   ; FA999E  push DE
	call	0xFB7CFF                              ; FA999F  call 0xfb7cff
	inc	8, xsp                                 ; FA99A3  inc 0,XSP
	jr Voice_StageChanSel_Reg0440_Reg0480__FA99C7                      ; FA99A5  jr T,0xfa99c7
Voice_StageChanSel_Reg0440_Reg0480__FA99A7:
	push	0                                     ; FA99A7  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FA99A9  push (XIZ+0xff)
	ld	bc, (xiz+8)                             ; FA99AC  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA99AF  extz XBC
	ld	a, (xbc)                                ; FA99B1  ld A,(XBC)
	pushw	wa                                   ; FA99B3  push WA
	push	0                                     ; FA99B4  push 0x00
	extpfx3 0x8E, 0xFD, 0x04                   ; FA99B6  push (XIZ+0xfd)
	call	0xFA5ED3                              ; FA99B9  call 0xfa5ed3
	ld	hl, wa                                  ; FA99BD  ld HL,WA
	ld	de, wa                                  ; FA99BF  ld DE,WA
	and	de, 0x7F                               ; FA99C1  and DE,0x007f
	inc	6, xsp                                 ; FA99C5  inc 6,XSP
Voice_StageChanSel_Reg0440_Reg0480__FA99C7:
	ldw	bc, 27                                 ; FA99C7  ld BC,0x001b
	mul	xbc, xde                               ; FA99CA  mul XBC,DE
	ld	(xiz-10), bc                            ; FA99CC  ld (XIZ+0xf6),BC
	ldw	ix, 0x4CCF                             ; FA99CF  ld IX,0x4ccf
	add	ix, bc                                 ; FA99D2  add IX,BC
	ld	bc, (xiz+8)                             ; FA99D4  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA99D7  extz XBC
	ld	a, (xbc+12)                             ; FA99D9  ld A,(XBC+0x0c)
	res	7, a                                   ; FA99DC  res 0x07,A
	extz	xix                                   ; FA99DF  extz XIX
	ld	(xix+6), a                              ; FA99E1  ld (XIX+0x06),A
	cp	de, 0x80                                ; FA99E4  cp DE,0x0080
	jrl nc, Voice_StageChanSel_Reg0440_Reg0480__FA9B74                 ; FA99E8  jrl NC,0xfa9b74
	ld	bc, (xiz-8)                             ; FA99EB  ld BC,(XIZ+0xf8)
	extz	xbc                                   ; FA99EE  extz XBC
	ld	wa, (xbc+30)                            ; FA99F0  ld WA,(XBC+0x1e)
	and	wa, 0xC0                               ; FA99F3  and WA,0x00c0
	or	wa, de                                  ; FA99F7  or WA,DE
	stw_da	(0xD76E), wa                        ; FA99F9  ld (0x00d76e),WA
	ld	bc, hl                                  ; FA99FE  ld BC,HL
	and	bc, 0x8000                             ; FA9A00  and BC,0x8000
	jr z, Voice_StageChanSel_Reg0440_Reg0480__FA9A14                   ; FA9A04  jr Z,0xfa9a14
	ld	bc, (xiz-6)                             ; FA9A06  ld BC,(XIZ+0xfa)
	extz	xbc                                   ; FA9A09  extz XBC
	ld	wa, (xbc+4)                             ; FA9A0B  ld WA,(XBC+0x04)
	and	wa, 12                                 ; FA9A0E  and WA,0x000c
	jr z, Voice_StageChanSel_Reg0440_Reg0480__FA9A4D                   ; FA9A12  jr Z,0xfa9a4d
Voice_StageChanSel_Reg0440_Reg0480__FA9A14:
	ld	(xiz-10), e                             ; FA9A14  ld (XIZ+0xf6),E
	push	0                                     ; FA9A17  push 0x00
	extpfx3 0x8E, 0xF6, 0x04                   ; FA9A19  push (XIZ+0xf6)
	pushw	0                                    ; FA9A1C  push 0x0000
	push	0                                     ; FA9A1F  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FA9A21  push (XIZ+0xff)
	extpfx3 0x9E, 0xFA, 0x04                   ; FA9A24  pushw (XIZ+0xfa)
	push	0                                     ; FA9A27  push 0x00
	extpfx3 0x8E, 0xFD, 0x04                   ; FA9A29  push (XIZ+0xfd)
	calr (0xFA981B - 0xFA9A2F)                 ; FA9A2C  calr 0xfa981b
	push	0                                     ; FA9A2F  push 0x00
	extpfx3 0x8E, 0xF6, 0x04                   ; FA9A31  push (XIZ+0xf6)
	calr (0xFA79F4 - 0xFA9A37)                 ; FA9A34  calr 0xfa79f4
	stw_da	(0xD79A), wa                        ; FA9A37  ld (0x00d79a),WA
	lda	xbc, (0xD75E:24)                       ; FA9A3C  lda XBC,0x00d75e
	push	xbc                                   ; FA9A41  push XBC
	pushw	de                                   ; FA9A42  push DE
	call	0xFB7CB1                              ; FA9A43  call 0xfb7cb1
	add	xsp, 18                                ; FA9A47  add XSP,0x00000012
Voice_StageChanSel_Reg0440_Reg0480__FA9A4D:
	extz	xix                                   ; FA9A4D  extz XIX
	ld	c, (xix+7)                              ; FA9A4F  ld C,(XIX+0x07)
	cps	c, 0                                   ; FA9A52  cp C,0
	jr z, Voice_StageChanSel_Reg0440_Reg0480__FA9A64                   ; FA9A54  jr Z,0xfa9a64
	ld	bc, (xiz-6)                             ; FA9A56  ld BC,(XIZ+0xfa)
	extz	xbc                                   ; FA9A59  extz XBC
	ld	wa, (xbc+6)                             ; FA9A5B  ld WA,(XBC+0x06)
	and	wa, 0x2000                             ; FA9A5E  and WA,0x2000
	jr nz, Voice_StageChanSel_Reg0440_Reg0480__FA9A6D                  ; FA9A62  jr NZ,0xfa9a6d
Voice_StageChanSel_Reg0440_Reg0480__FA9A64:
	extz	xix                                   ; FA9A64  extz XIX
	ld	c, (xix)                                ; FA9A66  ld C,(XIX)
	and	c, 32                                  ; FA9A68  and C,0x20
	jr z, Voice_StageChanSel_Reg0440_Reg0480__FA9A86                   ; FA9A6B  jr Z,0xfa9a86
Voice_StageChanSel_Reg0440_Reg0480__FA9A6D:
	extz	xix                                   ; FA9A6D  extz XIX
	ld	(xix+8), 0                              ; FA9A6F  ld (XIX+0x08),0x00
	extpfx3 0x84, 0x3C, 0xF3                   ; FA9A73  and (XIX),0xf3
	ld	c, (xix)                                ; FA9A76  ld C,(XIX)
	set	4, c                                   ; FA9A78  set 0x04,C
	ld	(xix), c                                ; FA9A7B  ld (XIX),C
	stiw_da	(0xD79E), 0                        ; FA9A7D  ld (0x00d79e),0x0000
	jr Voice_StageChanSel_Reg0440_Reg0480__FA9ABB                      ; FA9A84  jr T,0xfa9abb
Voice_StageChanSel_Reg0440_Reg0480__FA9A86:
	extz	xix                                   ; FA9A86  extz XIX
	ld	c, (xix+5)                              ; FA9A88  ld C,(XIX+0x05)
	cps	c, 0                                   ; FA9A8B  cp C,0
	jr nz, Voice_StageChanSel_Reg0440_Reg0480__FA9A97                  ; FA9A8D  jr NZ,0xfa9a97
	ld	bc, hl                                  ; FA9A8F  ld BC,HL
	and	bc, 0x8000                             ; FA9A91  and BC,0x8000
	jr nz, Voice_StageChanSel_Reg0440_Reg0480__FA9AA0                  ; FA9A95  jr NZ,0xfa9aa0
Voice_StageChanSel_Reg0440_Reg0480__FA9A97:
	extz	xix                                   ; FA9A97  extz XIX
	ld	c, (xix)                                ; FA9A99  ld C,(XIX)
	and	c, 56                                  ; FA9A9B  and C,0x38
	jr z, Voice_StageChanSel_Reg0440_Reg0480__FA9AAF                   ; FA9A9E  jr Z,0xfa9aaf
Voice_StageChanSel_Reg0440_Reg0480__FA9AA0:
	ld	bc, (xiz-6)                             ; FA9AA0  ld BC,(XIZ+0xfa)
	extz	xbc                                   ; FA9AA3  extz XBC
	ld	wa, (xbc+4)                             ; FA9AA5  ld WA,(XBC+0x04)
	and	wa, 12                                 ; FA9AA8  and WA,0x000c
	jrl z, Voice_StageChanSel_Reg0440_Reg0480__FA9B74                  ; FA9AAC  jrl Z,0xfa9b74
Voice_StageChanSel_Reg0440_Reg0480__FA9AAF:
	ld	c, e                                    ; FA9AAF  ld C,E
	pushw	bc                                   ; FA9AB1  push BC
	calr (0xFA796D - 0xFA9AB5)                 ; FA9AB2  calr 0xfa796d
	stw_da	(0xD79E), wa                        ; FA9AB5  ld (0x00d79e),WA
	popw	bc                                    ; FA9ABA  pop BC
Voice_StageChanSel_Reg0440_Reg0480__FA9ABB:
	lda	xbc, (0xD75E:24)                       ; FA9ABB  lda XBC,0x00d75e
	push	xbc                                   ; FA9AC0  push XBC
	pushw	de                                   ; FA9AC1  push DE
	call	0xFB7C8F                              ; FA9AC2  call 0xfb7c8f
Voice_StageChanSel_Reg0440_Reg0480__FA9AC6:
	inc	6, xsp                                 ; FA9AC6  inc 6,XSP
	jrl Voice_StageChanSel_Reg0440_Reg0480__FA9B74                     ; FA9AC8  jrl T,0xfa9b74
Voice_StageChanSel_Reg0440_Reg0480__FA9ACB:
	ld	bc, (xiz-6)                             ; FA9ACB  ld BC,(XIZ+0xfa)
	extz	xbc                                   ; FA9ACE  extz XBC
	ld	wa, (xbc+9)                             ; FA9AD0  ld WA,(XBC+0x09)
	and	wa, 0x8000                             ; FA9AD3  and WA,0x8000
	jrl z, Voice_StageChanSel_Reg0440_Reg0480__FA9B74                  ; FA9AD7  jrl Z,0xfa9b74
	pushw	1                                    ; FA9ADA  push 0x0001
	push	0                                     ; FA9ADD  push 0x00
	extpfx3 0x8E, 0xFE, 0x04                   ; FA9ADF  push (XIZ+0xfe)
	push	0                                     ; FA9AE2  push 0x00
	extpfx3 0x8E, 0xFD, 0x04                   ; FA9AE4  push (XIZ+0xfd)
	call	0xFB5E39                              ; FA9AE7  call 0xfb5e39
	ld	de, wa                                  ; FA9AEB  ld DE,WA
	inc	6, xsp                                 ; FA9AED  inc 6,XSP
	cps	wa, 0                                  ; FA9AEF  cp WA,0
	jrl z, Voice_StageChanSel_Reg0440_Reg0480__FA9B74                  ; FA9AF1  jrl Z,0xfa9b74
	pushw	13                                   ; FA9AF4  push 0x000d
	ld	bc, (xiz+8)                             ; FA9AF7  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9AFA  extz XBC
	ld	a, (xbc)                                ; FA9AFC  ld A,(XBC)
	pushw	wa                                   ; FA9AFE  push WA
	push	0                                     ; FA9AFF  push 0x00
	extpfx3 0x8E, 0xFD, 0x04                   ; FA9B01  push (XIZ+0xfd)
	call	0xFA5ED3                              ; FA9B04  call 0xfa5ed3
	ld	hl, wa                                  ; FA9B08  ld HL,WA
	and	wa, 0xFF                               ; FA9B0A  and WA,0x00ff
	inc	6, xsp                                 ; FA9B0E  inc 6,XSP
	cp	wa, 0x80                                ; FA9B10  cp WA,0x0080
	jr nc, Voice_StageChanSel_Reg0440_Reg0480__FA9B74                  ; FA9B14  jr NC,0xfa9b74
	ld	ix, hl                                  ; FA9B16  ld IX,HL
	and	ix, 0x7F                               ; FA9B18  and IX,0x007f
	extpfx3 0xC7, 0xF0, 0x8B                   ; FA9B1C  ld C,IXL
	pushw	bc                                   ; FA9B1F  push BC
	pushw	0                                    ; FA9B20  push 0x0000
	calr (0xFA78E8 - 0xFA9B26)                 ; FA9B23  calr 0xfa78e8
	ld	bc, de                                  ; FA9B26  ld BC,DE
	or	bc, ix                                  ; FA9B28  or BC,IX
	stw_da	(0xD76E), bc                        ; FA9B2A  ld (0x00d76e),BC
	ld	bc, hl                                  ; FA9B2F  ld BC,HL
	and	bc, 0x8000                             ; FA9B31  and BC,0x8000
	pop	xiy                                    ; FA9B35  pop XIY
	jr z, Voice_StageChanSel_Reg0440_Reg0480__FA9B46                   ; FA9B36  jr Z,0xfa9b46
	ld	bc, (xiz-6)                             ; FA9B38  ld BC,(XIZ+0xfa)
	extz	xbc                                   ; FA9B3B  extz XBC
	ld	wa, (xbc+4)                             ; FA9B3D  ld WA,(XBC+0x04)
	and	wa, 4                                  ; FA9B40  and WA,0x0004
	jr z, Voice_StageChanSel_Reg0440_Reg0480__FA9B74                   ; FA9B44  jr Z,0xfa9b74
Voice_StageChanSel_Reg0440_Reg0480__FA9B46:
	ld	bc, (xiz-6)                             ; FA9B46  ld BC,(XIZ+0xfa)
	extz	xbc                                   ; FA9B49  extz XBC
	ld	wa, (xbc+0x69)                          ; FA9B4B  ld WA,(XBC+0x69)
	stw_da	(0xD79E), wa                        ; FA9B4E  ld (0x00d79e),WA
	ld	bc, (xiz-6)                             ; FA9B53  ld BC,(XIZ+0xfa)
	extz	xbc                                   ; FA9B56  extz XBC
	ld	wa, (xbc+0x6B)                          ; FA9B58  ld WA,(XBC+0x6b)
	stw_da	(0xD79A), wa                        ; FA9B5B  ld (0x00d79a),WA
	lda	xbc, (0xD75E:24)                       ; FA9B60  lda XBC,0x00d75e
	push	xbc                                   ; FA9B65  push XBC
	ld	wa, hl                                  ; FA9B66  ld WA,HL
	and	wa, 0x7F                               ; FA9B68  and WA,0x007f
	pushw	wa                                   ; FA9B6C  push WA
	call	0xFB7C27                              ; FA9B6D  call 0xfb7c27
	jrl Voice_StageChanSel_Reg0440_Reg0480__FA9AC6                     ; FA9B71  jrl T,0xfa9ac6
Voice_StageChanSel_Reg0440_Reg0480__FA9B74:
	ld	bc, (xiz-6)                             ; FA9B74  ld BC,(XIZ+0xfa)
	extz	xbc                                   ; FA9B77  extz XBC
	ld	wa, (xbc+9)                             ; FA9B79  ld WA,(XBC+0x09)
	and	wa, 0x8000                             ; FA9B7C  and WA,0x8000
	jrl z, Voice_StageChanSel_Reg0440_Reg0480__FA9C5A                  ; FA9B80  jrl Z,0xfa9c5a
	pushw	0                                    ; FA9B83  push 0x0000
	push	0                                     ; FA9B86  push 0x00
	extpfx3 0x8E, 0xFE, 0x04                   ; FA9B88  push (XIZ+0xfe)
	push	0                                     ; FA9B8B  push 0x00
	extpfx3 0x8E, 0xFD, 0x04                   ; FA9B8D  push (XIZ+0xfd)
	call	0xFB5E39                              ; FA9B90  call 0xfb5e39
	ld	de, wa                                  ; FA9B94  ld DE,WA
	inc	6, xsp                                 ; FA9B96  inc 6,XSP
	cps	wa, 0                                  ; FA9B98  cp WA,0
	jrl z, Voice_StageChanSel_Reg0440_Reg0480__FA9C5A                  ; FA9B9A  jrl Z,0xfa9c5a
	pushw	12                                   ; FA9B9D  push 0x000c
	ld	bc, (xiz+8)                             ; FA9BA0  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9BA3  extz XBC
	ld	a, (xbc)                                ; FA9BA5  ld A,(XBC)
	pushw	wa                                   ; FA9BA7  push WA
	push	0                                     ; FA9BA8  push 0x00
	extpfx3 0x8E, 0xFD, 0x04                   ; FA9BAA  push (XIZ+0xfd)
	call	0xFA5ED3                              ; FA9BAD  call 0xfa5ed3
	ld	hl, wa                                  ; FA9BB1  ld HL,WA
	and	wa, 0xFF                               ; FA9BB3  and WA,0x00ff
	inc	6, xsp                                 ; FA9BB7  inc 6,XSP
	cp	wa, 0x80                                ; FA9BB9  cp WA,0x0080
	jrl nc, Voice_StageChanSel_Reg0440_Reg0480__FA9C5A                 ; FA9BBD  jrl NC,0xfa9c5a
	ld	bc, hl                                  ; FA9BC0  ld BC,HL
	and	bc, 63                                 ; FA9BC2  and BC,0x003f
	or	bc, de                                  ; FA9BC6  or BC,DE
	stw_da	(0xD770), bc                        ; FA9BC8  ld (0x00d770),BC
	push	0                                     ; FA9BCD  push 0x00
	extpfx3 0x8E, 0xFD, 0x04                   ; FA9BCF  push (XIZ+0xfd)
	call	0xFB5B56                              ; FA9BD2  call 0xfb5b56
	ld	d, a                                    ; FA9BD6  ld D,A
	popw	bc                                    ; FA9BD8  pop BC
	cps	a, 0                                   ; FA9BD9  cp A,0
	jr nz, Voice_StageChanSel_Reg0440_Reg0480__FA9BF3                  ; FA9BDB  jr NZ,0xfa9bf3
	ld	bc, hl                                  ; FA9BDD  ld BC,HL
	and	bc, 0x8000                             ; FA9BDF  and BC,0x8000
	jr z, Voice_StageChanSel_Reg0440_Reg0480__FA9BF3                   ; FA9BE3  jr Z,0xfa9bf3
	ld	bc, (xiz-6)                             ; FA9BE5  ld BC,(XIZ+0xfa)
	extz	xbc                                   ; FA9BE8  extz XBC
	ld	wa, (xbc+4)                             ; FA9BEA  ld WA,(XBC+0x04)
	and	wa, 4                                  ; FA9BED  and WA,0x0004
	jr z, Voice_StageChanSel_Reg0440_Reg0480__FA9C5A                   ; FA9BF1  jr Z,0xfa9c5a
Voice_StageChanSel_Reg0440_Reg0480__FA9BF3:
	ld	bc, (xiz-6)                             ; FA9BF3  ld BC,(XIZ+0xfa)
	extz	xbc                                   ; FA9BF6  extz XBC
	ld	ix, (xbc+0x65)                          ; FA9BF8  ld IX,(XBC+0x65)
	stw_da	(0xD7A0), ix                        ; FA9BFB  ld (0x00d7a0),IX
	ld	bc, ix                                  ; FA9C00  ld BC,IX
	and	bc, 0x1FFF                             ; FA9C02  and BC,0x1fff
	extz	xbc                                   ; FA9C06  extz XBC
	ld	xix, xbc                                ; FA9C08  ld XIX,XBC
	push	0                                     ; FA9C0A  push 0x00
	push	d                                     ; FA9C0C  push D
	ld	wa, (xiz+8)                             ; FA9C0E  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA9C11  extz XWA
	ld	c, (xwa+12)                             ; FA9C13  ld C,(XWA+0x0c)
	pushw	bc                                   ; FA9C16  push BC
	push	xix                                   ; FA9C17  push XIX
	calr (0xFA7927 - 0xFA9C1B)                 ; FA9C18  calr 0xfa7927
	ld	xbc, xix                                ; FA9C1B  ld XBC,XIX
	sub	xbc, xiy                               ; FA9C1D  sub XBC,XIY
	ld	(xiz-12), xbc                           ; FA9C1F  ld (XIZ+0xf4),XBC
	extpfx7 0xD2, 0xA0, 0xD7, 0x00, 0x3C, 0x00, 0xE0 ; FA9C22  and (0x00d7a0),0xe000
	ldw_da	ix, (0xD7A0)                        ; FA9C29  ld IX,(0x00d7a0)
	ld	bc, (xiz-12)                            ; FA9C2E  ld BC,(XIZ+0xf4)
	or	bc, ix                                  ; FA9C31  or BC,IX
	stw_da	(0xD7A0), bc                        ; FA9C33  ld (0x00d7a0),BC
	ld	bc, (xiz-6)                             ; FA9C38  ld BC,(XIZ+0xfa)
	extz	xbc                                   ; FA9C3B  extz XBC
	ld	wa, (xbc+0x67)                          ; FA9C3D  ld WA,(XBC+0x67)
	stw_da	(0xD79C), wa                        ; FA9C40  ld (0x00d79c),WA
	lda	xbc, (0xD75E:24)                       ; FA9C45  lda XBC,0x00d75e
	push	xbc                                   ; FA9C4A  push XBC
	ld	wa, hl                                  ; FA9C4B  ld WA,HL
	and	wa, 63                                 ; FA9C4D  and WA,0x003f
	pushw	wa                                   ; FA9C51  push WA
	call	0xFB7D1D                              ; FA9C52  call 0xfb7d1d
	inc	8, xsp                                 ; FA9C56  inc 0,XSP
	inc	6, xsp                                 ; FA9C58  inc 6,XSP
Voice_StageChanSel_Reg0440_Reg0480__FA9C5A:
	pop	xix                                    ; FA9C5A  pop XIX
	popw	de                                    ; FA9C5B  pop DE
	popw	hl                                    ; FA9C5C  pop HL
	unlk32 xiz                                 ; FA9C5D  unlk XIZ
	ret                                        ; FA9C5F  ret
; --------------------------------------------------------------------------
; Voice_StageRegs_0180_AB -- 0xFA9C60..0xFA9F18 (697 bytes)
;
; Called from: 4 site(s) outside this module:
;          0xFAE641 in Voice_Restage_Reg0180_BaseCurve_ForPart__FAE632, 0xFAE77D in Voice_Restage_Reg0180_ValueCurve_ForPart__FAE76E
;          0xFB0B2F in VoiceRegs_Stage_A, 0xFB1F1D in VoiceRegs_Stage_B
; Inputs:  frame `link XIZ,-10`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D76A, 0x00D796, 0x00D798
; Calls:   0xFA5ED3 = Voice_LookupDev10CChanIndex, 0xFA78E8 = sub_FA78E8
;          0xFA7A4B = EGEnv_Eval_BaseCurveB, 0xFA7AD6 = EGEnv_Eval_ValueCurve_WithBaseCurveB
;          0xFA7F04 = Rand_FromTickSquared, 0xFA981B = sub_FA981B
;          0xFB5F91 = sub_FB5F91, 0xFB7E13 = Dev10C_Slot1_WriteGateAndValue
;          0xFB7E7B = Dev10C_SetChanReg_01C0_b, 0xFB7E9D = Dev10C_Slot1_StrobeGate
;          0xFB7EEB = Dev10C_Slot1_WriteGate8100
; Voice record: touches voice_record[+0x00(r), +0x03(r), +0x04(r), +0x0C(r), +0x13(r), +0x17(r), +0x23(r), +0x25(r), +0x27(rw), +0x38(w)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA9C60-0xFA9F18
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; Voice_StageRegs_0180_AB -- stages word 6 (register 0x0180 + chan) of the 0x0010C000 per-channel
;          staging struct at RAM 0x00D75E, and nothing else in that struct.
;          Write site(s): 0xFA9F0E.
;          Argument: the caller pushes XDE, the 68-byte VOICE RECORD at 0x003BCF + 0x44*voice
;          (`ld C,0x44 / mul BC,(XIZ+0x08) / ld <r>,0x3bcf` at the top of every
;          VoiceRegs_Stage_*), immediately before the call.
;          Called from: VoiceRegs_Stage_A, VoiceRegs_Stage_B, Voice_Restage_Reg0180_BaseCurve_ForPart, Voice_Restage_Reg0180_ValueCurve_ForPart.
;          Evidence: the write addresses above are instruction operands, listed by
;          `python3 notes/prom_c_understanding_round6.py --staging`, which also asserts that
;          this routine writes EXACTLY the register block(s) its name claims and no other.
;          The struct-word -> register-block map is Dev10C_WriteAllChanRegs's own
;          (notes/prom_c_tg_chanmap.py), cross-checked against
;          notes/prom_c_dev10c_field_sources.py by the same section.
;          Unknown: what register 0x0180 carries.  The name states WHICH register this
;          routine produces, never what the register means.
; --------------------------------------------------------------------------
Voice_StageRegs_0180_AB:
	link32 0xEE, 0x0C, 0xF6, 0xFF              ; FA9C60  link XIZ,0xfff6
	pushw	hl                                   ; FA9C64  push HL
	push	xde                                   ; FA9C65  push XDE
	push	xix                                   ; FA9C66  push XIX
	ld	bc, (xiz+8)                             ; FA9C67  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9C6A  extz XBC
	ld	wa, (xbc+35)                            ; FA9C6C  ld WA,(XBC+0x23)
	ld	(xiz-4), wa                             ; FA9C6F  ld (XIZ+0xfc),WA
	ld	iy, (xbc+37)                            ; FA9C72  ld IY,(XBC+0x25)
	ld	(xiz-8), iy                             ; FA9C75  ld (XIZ+0xf8),IY
	ld	a, (xbc+4)                              ; FA9C78  ld A,(XBC+0x04)
	ld	(xiz-2), a                              ; FA9C7B  ld (XIZ+0xfe),A
	ld	h, (xbc+3)                              ; FA9C7E  ld H,(XBC+0x03)
	ldw (xiz-6), 0x0000                        ; FA9C81  ld (XIZ+0xfa),0x0000
	extz	xiy                                   ; FA9C86  extz XIY
	ld	wa, (xiy+32)                            ; FA9C88  ld WA,(XIY+0x20)
	cps	wa, 0                                  ; FA9C8B  cp WA,0
	jrl z, Voice_StageRegs_0180_AB__FA9E12                  ; FA9C8D  jrl Z,0xfa9e12
	ld	a, (xiy+32)                             ; FA9C90  ld A,(XIY+0x20)
	and	a, 3                                   ; FA9C93  and A,0x03
	ld	(xiz-1), a                              ; FA9C96  ld (XIZ+0xff),A
	mul	a, 4                                   ; FA9C99  mul A,0x04
	extz	xwa                                   ; FA9C9C  extz XWA
	ld	xix, xwa                                ; FA9C9E  ld XIX,XWA
	add	xix, 0x69                              ; FA9CA0  add XIX,0x00000069
	ld	xwa, (xbc+19)                           ; FA9CA6  ld XWA,(XBC+0x13)
	add	xwa, xix                               ; FA9CA9  add XWA,XIX
	ld	c, (xwa)                                ; FA9CAB  ld C,(XWA)
	and	c, 0x80                                ; FA9CAD  and C,0x80
	jr z, Voice_StageRegs_0180_AB__FA9CDE                   ; FA9CB0  jr Z,0xfa9cde
	ld	c, (xiz-1)                              ; FA9CB2  ld C,(XIZ+0xff)
	or	c, 36                                   ; FA9CB5  or C,0x24
	pushw	bc                                   ; FA9CB8  push BC
	ld	bc, (xiz+8)                             ; FA9CB9  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9CBC  extz XBC
	ld	w, (xbc)                                ; FA9CBE  ld W,(XBC)
	push	0                                     ; FA9CC0  push 0x00
	push	w                                     ; FA9CC2  push W
	push	0                                     ; FA9CC4  push 0x00
	extpfx3 0x8E, 0xFE, 0x04                   ; FA9CC6  push (XIZ+0xfe)
	call	0xFA5ED3                              ; FA9CC9  call 0xfa5ed3
	ld	hl, wa                                  ; FA9CCD  ld HL,WA
	ld	ix, wa                                  ; FA9CCF  ld IX,WA
	and	ix, 63                                 ; FA9CD1  and IX,0x003f
	pushw	ix                                   ; FA9CD5  push IX
	call	0xFB7EEB                              ; FA9CD6  call 0xfb7eeb
	inc	8, xsp                                 ; FA9CDA  inc 0,XSP
	jr Voice_StageRegs_0180_AB__FA9D00                      ; FA9CDC  jr T,0xfa9d00
Voice_StageRegs_0180_AB__FA9CDE:
	ld	c, (xiz-1)                              ; FA9CDE  ld C,(XIZ+0xff)
	set	2, c                                   ; FA9CE1  set 0x02,C
	pushw	bc                                   ; FA9CE4  push BC
	ld	bc, (xiz+8)                             ; FA9CE5  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9CE8  extz XBC
	ld	a, (xbc)                                ; FA9CEA  ld A,(XBC)
	pushw	wa                                   ; FA9CEC  push WA
	push	0                                     ; FA9CED  push 0x00
	extpfx3 0x8E, 0xFE, 0x04                   ; FA9CEF  push (XIZ+0xfe)
	call	0xFA5ED3                              ; FA9CF2  call 0xfa5ed3
	ld	hl, wa                                  ; FA9CF6  ld HL,WA
	ld	ix, wa                                  ; FA9CF8  ld IX,WA
	and	ix, 63                                 ; FA9CFA  and IX,0x003f
	inc	6, xsp                                 ; FA9CFE  inc 6,XSP
Voice_StageRegs_0180_AB__FA9D00:
	ldw	bc, 27                                 ; FA9D00  ld BC,0x001b
	mul	xbc, xix                               ; FA9D03  mul XBC,IX
	add	bc, 9                                  ; FA9D05  add BC,0x0009
	ld	(xiz-10), bc                            ; FA9D09  ld (XIZ+0xf6),BC
	ldw	de, 0x4CCF                             ; FA9D0C  ld DE,0x4ccf
	add	de, bc                                 ; FA9D0F  add DE,BC
	ld	bc, (xiz+8)                             ; FA9D11  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9D14  extz XBC
	ld	a, (xbc+12)                             ; FA9D16  ld A,(XBC+0x0c)
	extz	xde                                   ; FA9D19  extz XDE
	ld	(xde+6), a                              ; FA9D1B  ld (XDE+0x06),A
	ld	bc, hl                                  ; FA9D1E  ld BC,HL
	and	bc, 0xFF                               ; FA9D20  and BC,0x00ff
	cp	bc, 64                                  ; FA9D24  cp BC,0x0040
	jrl nc, Voice_StageRegs_0180_AB__FA9EB5                 ; FA9D28  jrl NC,0xfa9eb5
	ld	bc, (xiz-8)                             ; FA9D2B  ld BC,(XIZ+0xf8)
	extz	xbc                                   ; FA9D2E  extz XBC
	ld	wa, (xbc+32)                            ; FA9D30  ld WA,(XBC+0x20)
	and	wa, 0xC000                             ; FA9D33  and WA,0xc000
	ld	(xiz-10), wa                            ; FA9D37  ld (XIZ+0xf6),WA
	ld	iy, ix                                  ; FA9D3A  ld IY,IX
	sll	iy, 8                                  ; FA9D3C  sll 0x08,IY
	extpfx3 0x9E, 0xF6, 0xE5                   ; FA9D3F  or IY,(XIZ+0xf6)
	ld	(xiz-6), iy                             ; FA9D42  ld (XIZ+0xfa),IY
	ld	wa, hl                                  ; FA9D45  ld WA,HL
	and	wa, 0x8000                             ; FA9D47  and WA,0x8000
	jr z, Voice_StageRegs_0180_AB__FA9D5B                   ; FA9D4B  jr Z,0xfa9d5b
	ld	wa, (xiz-4)                             ; FA9D4D  ld WA,(XIZ+0xfc)
	extz	xwa                                   ; FA9D50  extz XWA
	ld	bc, (xwa+4)                             ; FA9D52  ld BC,(XWA+0x04)
	and	bc, 12                                 ; FA9D55  and BC,0x000c
	jr z, Voice_StageRegs_0180_AB__FA9D93                   ; FA9D59  jr Z,0xfa9d93
Voice_StageRegs_0180_AB__FA9D5B:
	extpfx3 0xC7, 0xF0, 0x8B                   ; FA9D5B  ld C,IXL
	ld	(xiz-10), c                             ; FA9D5E  ld (XIZ+0xf6),C
	pushw	bc                                   ; FA9D61  push BC
	pushw	1                                    ; FA9D62  push 0x0001
	push	0                                     ; FA9D65  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FA9D67  push (XIZ+0xff)
	extpfx3 0x9E, 0xFC, 0x04                   ; FA9D6A  pushw (XIZ+0xfc)
	push	0                                     ; FA9D6D  push 0x00
	extpfx3 0x8E, 0xFE, 0x04                   ; FA9D6F  push (XIZ+0xfe)
	calr (0xFA981B - 0xFA9D75)                 ; FA9D72  calr 0xfa981b
	push	0                                     ; FA9D75  push 0x00
	extpfx3 0x8E, 0xF6, 0x04                   ; FA9D77  push (XIZ+0xf6)
	calr (0xFA7AD6 - 0xFA9D7D)                 ; FA9D7A  calr 0xfa7ad6
	stw_da	(0xD798), wa                        ; FA9D7D  ld (0x00d798),WA
	lda	xbc, (0xD75E:24)                       ; FA9D82  lda XBC,0x00d75e
	push	xbc                                   ; FA9D87  push XBC
	pushw	ix                                   ; FA9D88  push IX
	call	0xFB7E9D                              ; FA9D89  call 0xfb7e9d
	add	xsp, 18                                ; FA9D8D  add XSP,0x00000012
Voice_StageRegs_0180_AB__FA9D93:
	extz	xde                                   ; FA9D93  extz XDE
	ld	c, (xde+7)                              ; FA9D95  ld C,(XDE+0x07)
	cps	c, 0                                   ; FA9D98  cp C,0
	jr z, Voice_StageRegs_0180_AB__FA9DAA                   ; FA9D9A  jr Z,0xfa9daa
	ld	bc, (xiz-4)                             ; FA9D9C  ld BC,(XIZ+0xfc)
	extz	xbc                                   ; FA9D9F  extz XBC
	ld	wa, (xbc+6)                             ; FA9DA1  ld WA,(XBC+0x06)
	and	wa, 0x2000                             ; FA9DA4  and WA,0x2000
	jr nz, Voice_StageRegs_0180_AB__FA9DB3                  ; FA9DA8  jr NZ,0xfa9db3
Voice_StageRegs_0180_AB__FA9DAA:
	extz	xde                                   ; FA9DAA  extz XDE
	ld	c, (xde)                                ; FA9DAC  ld C,(XDE)
	and	c, 32                                  ; FA9DAE  and C,0x20
	jr z, Voice_StageRegs_0180_AB__FA9DCC                   ; FA9DB1  jr Z,0xfa9dcc
Voice_StageRegs_0180_AB__FA9DB3:
	extz	xde                                   ; FA9DB3  extz XDE
	ld	(xde+8), 0                              ; FA9DB5  ld (XDE+0x08),0x00
	extpfx3 0x82, 0x3C, 0xF3                   ; FA9DB9  and (XDE),0xf3
	ld	c, (xde)                                ; FA9DBC  ld C,(XDE)
	set	4, c                                   ; FA9DBE  set 0x04,C
	ld	(xde), c                                ; FA9DC1  ld (XDE),C
	stiw_da	(0xD796), 0                        ; FA9DC3  ld (0x00d796),0x0000
	jr Voice_StageRegs_0180_AB__FA9E02                      ; FA9DCA  jr T,0xfa9e02
Voice_StageRegs_0180_AB__FA9DCC:
	extz	xde                                   ; FA9DCC  extz XDE
	ld	c, (xde+5)                              ; FA9DCE  ld C,(XDE+0x05)
	cps	c, 0                                   ; FA9DD1  cp C,0
	jr nz, Voice_StageRegs_0180_AB__FA9DDD                  ; FA9DD3  jr NZ,0xfa9ddd
	ld	bc, hl                                  ; FA9DD5  ld BC,HL
	and	bc, 0x8000                             ; FA9DD7  and BC,0x8000
	jr nz, Voice_StageRegs_0180_AB__FA9DE6                  ; FA9DDB  jr NZ,0xfa9de6
Voice_StageRegs_0180_AB__FA9DDD:
	extz	xde                                   ; FA9DDD  extz XDE
	ld	c, (xde)                                ; FA9DDF  ld C,(XDE)
	and	c, 56                                  ; FA9DE1  and C,0x38
	jr z, Voice_StageRegs_0180_AB__FA9DF5                   ; FA9DE4  jr Z,0xfa9df5
Voice_StageRegs_0180_AB__FA9DE6:
	ld	bc, (xiz-4)                             ; FA9DE6  ld BC,(XIZ+0xfc)
	extz	xbc                                   ; FA9DE9  extz XBC
	ld	wa, (xbc+4)                             ; FA9DEB  ld WA,(XBC+0x04)
	and	wa, 12                                 ; FA9DEE  and WA,0x000c
	jrl z, Voice_StageRegs_0180_AB__FA9EB5                  ; FA9DF2  jrl Z,0xfa9eb5
Voice_StageRegs_0180_AB__FA9DF5:
	extpfx3 0xC7, 0xF0, 0x8B                   ; FA9DF5  ld C,IXL
	pushw	bc                                   ; FA9DF8  push BC
	calr (0xFA7A4B - 0xFA9DFC)                 ; FA9DF9  calr 0xfa7a4b
	stw_da	(0xD796), wa                        ; FA9DFC  ld (0x00d796),WA
	popw	bc                                    ; FA9E01  pop BC
Voice_StageRegs_0180_AB__FA9E02:
	lda	xbc, (0xD75E:24)                       ; FA9E02  lda XBC,0x00d75e
	push	xbc                                   ; FA9E07  push XBC
	pushw	ix                                   ; FA9E08  push IX
	call	0xFB7E7B                              ; FA9E09  call 0xfb7e7b
Voice_StageRegs_0180_AB__FA9E0D:
	inc	6, xsp                                 ; FA9E0D  inc 6,XSP
	jrl Voice_StageRegs_0180_AB__FA9EB5                     ; FA9E0F  jrl T,0xfa9eb5
Voice_StageRegs_0180_AB__FA9E12:
	ld	bc, (xiz-4)                             ; FA9E12  ld BC,(XIZ+0xfc)
	extz	xbc                                   ; FA9E15  extz XBC
	ld	wa, (xbc+9)                             ; FA9E17  ld WA,(XBC+0x09)
	and	wa, 0x8000                             ; FA9E1A  and WA,0x8000
	jrl z, Voice_StageRegs_0180_AB__FA9EB5                  ; FA9E1E  jrl Z,0xfa9eb5
	push	0                                     ; FA9E21  push 0x00
	push	h                                     ; FA9E23  push H
	push	0                                     ; FA9E25  push 0x00
	extpfx3 0x8E, 0xFE, 0x04                   ; FA9E27  push (XIZ+0xfe)
	call	0xFB5F91                              ; FA9E2A  call 0xfb5f91
	ld	(xiz-6), wa                             ; FA9E2E  ld (XIZ+0xfa),WA
	pop	xiy                                    ; FA9E31  pop XIY
	cps	wa, 0                                  ; FA9E32  cp WA,0
	jrl z, Voice_StageRegs_0180_AB__FA9EB5                  ; FA9E34  jrl Z,0xfa9eb5
	pushw	16                                   ; FA9E37  push 0x0010
	ld	bc, (xiz+8)                             ; FA9E3A  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9E3D  extz XBC
	ld	a, (xbc)                                ; FA9E3F  ld A,(XBC)
	pushw	wa                                   ; FA9E41  push WA
	push	0                                     ; FA9E42  push 0x00
	extpfx3 0x8E, 0xFE, 0x04                   ; FA9E44  push (XIZ+0xfe)
	call	0xFA5ED3                              ; FA9E47  call 0xfa5ed3
	ld	hl, wa                                  ; FA9E4B  ld HL,WA
	and	wa, 0xFF                               ; FA9E4D  and WA,0x00ff
	inc	6, xsp                                 ; FA9E51  inc 6,XSP
	cp	wa, 64                                  ; FA9E53  cp WA,0x0040
	jr nc, Voice_StageRegs_0180_AB__FA9EB5                  ; FA9E57  jr NC,0xfa9eb5
	ld	de, hl                                  ; FA9E59  ld DE,HL
	and	de, 63                                 ; FA9E5B  and DE,0x003f
	ld	c, e                                    ; FA9E5F  ld C,E
	pushw	bc                                   ; FA9E61  push BC
	pushw	1                                    ; FA9E62  push 0x0001
	calr (0xFA78E8 - 0xFA9E68)                 ; FA9E65  calr 0xfa78e8
	ld	bc, de                                  ; FA9E68  ld BC,DE
	sll	bc, 8                                  ; FA9E6A  sll 0x08,BC
	or	(xiz-6), bc                             ; FA9E6D  or (XIZ+0xfa),BC
	ld	bc, hl                                  ; FA9E70  ld BC,HL
	and	bc, 0x8000                             ; FA9E72  and BC,0x8000
	pop	xiy                                    ; FA9E76  pop XIY
	jr z, Voice_StageRegs_0180_AB__FA9E87                   ; FA9E77  jr Z,0xfa9e87
	ld	bc, (xiz-4)                             ; FA9E79  ld BC,(XIZ+0xfc)
	extz	xbc                                   ; FA9E7C  extz XBC
	ld	wa, (xbc+4)                             ; FA9E7E  ld WA,(XBC+0x04)
	and	wa, 4                                  ; FA9E81  and WA,0x0004
	jr z, Voice_StageRegs_0180_AB__FA9EB5                   ; FA9E85  jr Z,0xfa9eb5
Voice_StageRegs_0180_AB__FA9E87:
	ld	bc, (xiz-4)                             ; FA9E87  ld BC,(XIZ+0xfc)
	extz	xbc                                   ; FA9E8A  extz XBC
	ld	wa, (xbc+0x6D)                          ; FA9E8C  ld WA,(XBC+0x6d)
	stw_da	(0xD796), wa                        ; FA9E8F  ld (0x00d796),WA
	ld	bc, (xiz-4)                             ; FA9E94  ld BC,(XIZ+0xfc)
	extz	xbc                                   ; FA9E97  extz XBC
	ld	wa, (xbc+0x6F)                          ; FA9E99  ld WA,(XBC+0x6f)
	stw_da	(0xD798), wa                        ; FA9E9C  ld (0x00d798),WA
	lda	xbc, (0xD75E:24)                       ; FA9EA1  lda XBC,0x00d75e
	push	xbc                                   ; FA9EA6  push XBC
	ld	wa, hl                                  ; FA9EA7  ld WA,HL
	and	wa, 63                                 ; FA9EA9  and WA,0x003f
	pushw	wa                                   ; FA9EAD  push WA
	call	0xFB7E13                              ; FA9EAE  call 0xfb7e13
	jrl Voice_StageRegs_0180_AB__FA9E0D                     ; FA9EB2  jrl T,0xfa9e0d
Voice_StageRegs_0180_AB__FA9EB5:
	ld	bc, (xiz+8)                             ; FA9EB5  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9EB8  extz XBC
	ld	wa, (xbc+37)                            ; FA9EBA  ld WA,(XBC+0x25)
	extz	xwa                                   ; FA9EBD  extz XWA
	ld	c, (xwa+40)                             ; FA9EBF  ld C,(XWA+0x28)
	ld	h, c                                    ; FA9EC2  ld H,C
	ld	bc, (xiz+8)                             ; FA9EC4  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9EC7  extz XBC
	ld	(xbc+56), h                             ; FA9EC9  ld (XBC+0x38),H
	ld	bc, (xiz+8)                             ; FA9ECC  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9ECF  extz XBC
	ld	xwa, (xbc+23)                           ; FA9ED1  ld XWA,(XBC+0x17)
	ld	c, (xwa+1)                              ; FA9ED4  ld C,(XWA+0x01)
	cp	c, 0x80                                 ; FA9ED7  cp C,0x80
	jr nz, Voice_StageRegs_0180_AB__FA9EF1                  ; FA9EDA  jr NZ,0xfa9ef1
	calr (0xFA7F04 - 0xFA9EDF)                 ; FA9EDC  calr 0xfa7f04
	res	7, a                                   ; FA9EDF  res 0x07,A
	exts	wa                                    ; FA9EE2  exts WA
	extpfx3 0x9E, 0xFA, 0xE0                   ; FA9EE4  or WA,(XIZ+0xfa)
	ld	bc, (xiz+8)                             ; FA9EE7  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9EEA  extz XBC
	ld	(xbc+39), wa                            ; FA9EEC  ld (XBC+0x27),WA
	jr Voice_StageRegs_0180_AB__FA9F06                      ; FA9EEF  jr T,0xfa9f06
Voice_StageRegs_0180_AB__FA9EF1:
	ld	bc, (xiz-8)                             ; FA9EF1  ld BC,(XIZ+0xf8)
	extz	xbc                                   ; FA9EF4  extz XBC
	ld	a, (xbc+39)                             ; FA9EF6  ld A,(XBC+0x27)
	extz	wa                                    ; FA9EF9  extz WA
	extpfx3 0x9E, 0xFA, 0xE0                   ; FA9EFB  or WA,(XIZ+0xfa)
	ld	bc, (xiz+8)                             ; FA9EFE  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9F01  extz XBC
	ld	(xbc+39), wa                            ; FA9F03  ld (XBC+0x27),WA
Voice_StageRegs_0180_AB__FA9F06:
	ld	bc, (xiz+8)                             ; FA9F06  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9F09  extz XBC
	ld	wa, (xbc+39)                            ; FA9F0B  ld WA,(XBC+0x27)
	stw_da	(0xD76A), wa                        ; FA9F0E  ld (0x00d76a),WA
	pop	xix                                    ; FA9F13  pop XIX
	pop	xde                                    ; FA9F14  pop XDE
	popw	hl                                    ; FA9F15  pop HL
	unlk32 xiz                                 ; FA9F16  unlk XIZ
	ret                                        ; FA9F18  ret
; --------------------------------------------------------------------------
; Voice_StageChanSel_Reg04C0 -- 0xFA9F19..0xFAA0BB (419 bytes)
;
; Called from: 4 site(s) outside this module:
;          0xFAE8C2 in Voice_Restage_Reg04C0_BaseCurve_ForPart__FAE8B3, 0xFAEA00 in Voice_Restage_Reg04C0_ValueCurve_ForPart__FAE9F1
;          0xFB0B34 in VoiceRegs_Stage_A, 0xFB1F22 in VoiceRegs_Stage_B
; Inputs:  frame `link XIZ,-8`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D772, 0x00D796, 0x00D7A0
; Calls:   0xFA5ED3 = Voice_LookupDev10CChanIndex, 0xFA7B31 = EGEnv_Eval_FreqWriteBaseCurve
;          0xFA7C3A = EGEnv_Eval_ValueCurve_WithFreqWriteCurve, 0xFA981B = sub_FA981B
;          0xFB7FCE = Dev10C_SetChanReg_01C0_or_0600_b, 0xFB8012 = Dev10C_Slot1or3_StrobeGate
;          0xFB80A9 = Dev10C_Slot1or3_WriteGate8100
; Voice record: touches voice_record[+0x00(r), +0x04(r), +0x0C(r), +0x13(r), +0x23(r), +0x25(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA9F19-0xFAA0BB
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
;
; ★★ GAP A -- THIS IS WHERE REGISTER 0x04C0 GETS ITS VALUE.  It stages the
;   0x0010C000 staging struct's word 10 (+0x14, RAM 0x00D772) -> chan+0x04C0, and
;   the word tiles CLEANLY into three disjoint fields:
;       0x4400  a literal, seeded before any test
;       0x3300  a MODE field, from the tone descriptor word at +0x22
;       0x007F  a CHANNEL of this same 0x0010C000 device
;   (0x4400 | 0x3300 | 0x007F = 0x777F, and the three masks are pairwise disjoint
;   -- unlike word 8's, which overlap at bit 6.)
;
; Evidence: 0xFA9F20 `ld (0x00d772),0x4400` SEEDS the word at entry -- it is not
;          cleared, so a rejected lookup leaves 0x4400 in it, NOT 0x0000.  Two
;          arms then call the lookup, 0xFA9F7C and 0xFA9FA3, and both mask its
;          result the same way (0xFA9F85, 0xFA9FAC `and WA,0x007f`) into IX.  A
;          result whose low byte is >= 0x80 is rejected at
;          0xFA9FD5/0xFA9FD9/0xFA9FDD.  0xFA9FE5 `ld WA,(XBC+0x22)` / 0xFA9FE8
;          `and WA,0x3300` is the MODE field; 0xFA9FEC `or WA,IX`; 0xFA9FEE
;          `or (0x00d772),WA` -- an OR into the seeded word, which is why 0x4400
;          survives.  The same IX is pushed at 0xFAA02D into
;          Dev10C_Slot1or3_StrobeGate (0xFAA02E), which turns it into the device
;          register selector 0x0540+arg or 0x0580+arg (0xFB801F/0xFB8030/0xFB8070)
;          -- that is what makes the field a CHANNEL and not just a number.
; ⚠ NOT ESTABLISHED: what the literal 0x4400 or the two mode bits MEAN, and
;   whether the named channel differs from the one the struct is committed to.
; Evidence: `python3 notes/prom_c_understanding_round4.py`, sections 1, 2, 3c, 5;
;          every address is re-decoded by an independent disassembler.
; --------------------------------------------------------------------------
Voice_StageChanSel_Reg04C0:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FA9F19  link XIZ,0xfff8
	pushw	hl                                   ; FA9F1D  push HL
	push	xde                                   ; FA9F1E  push XDE
	push	xix                                   ; FA9F1F  push XIX
	stiw_da	(0xD772), 0x4400                   ; FA9F20  ld (0x00d772),0x4400
	ld	bc, (xiz+8)                             ; FA9F27  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9F2A  extz XBC
	ld	wa, (xbc+35)                            ; FA9F2C  ld WA,(XBC+0x23)
	ld	(xiz-6), wa                             ; FA9F2F  ld (XIZ+0xfa),WA
	ld	iy, (xbc+37)                            ; FA9F32  ld IY,(XBC+0x25)
	ld	(xiz-4), iy                             ; FA9F35  ld (XIZ+0xfc),IY
	ld	l, (xbc+4)                              ; FA9F38  ld L,(XBC+0x04)
	extz	xiy                                   ; FA9F3B  extz XIY
	ld	bc, (xiy+34)                            ; FA9F3D  ld BC,(XIY+0x22)
	cps	bc, 0                                  ; FA9F40  cp BC,0
	jrl z, Voice_StageChanSel_Reg04C0__FAA0B6                  ; FA9F42  jrl Z,0xfaa0b6
	ld	h, (xiy+34)                             ; FA9F45  ld H,(XIY+0x22)
	and	h, 3                                   ; FA9F48  and H,0x03
	ldb	c, 4                                   ; FA9F4B  ld C,0x04
	mul8rr	c, h                                ; FA9F4D  mul BC,H
	extz	xbc                                   ; FA9F4F  extz XBC
	ld	xix, xbc                                ; FA9F51  ld XIX,XBC
	add	xix, 0x79                              ; FA9F53  add XIX,0x00000079
	ld	bc, (xiz+8)                             ; FA9F59  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9F5C  extz XBC
	ld	xwa, (xbc+19)                           ; FA9F5E  ld XWA,(XBC+0x13)
	add	xwa, xix                               ; FA9F61  add XWA,XIX
	ld	c, (xwa)                                ; FA9F63  ld C,(XWA)
	and	c, 0x80                                ; FA9F65  and C,0x80
	jr z, Voice_StageChanSel_Reg04C0__FA9F94                   ; FA9F68  jr Z,0xfa9f94
	ld	c, h                                    ; FA9F6A  ld C,H
	or	c, 40                                   ; FA9F6C  or C,0x28
	pushw	bc                                   ; FA9F6F  push BC
	ld	bc, (xiz+8)                             ; FA9F70  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9F73  extz XBC
	ld	w, (xbc)                                ; FA9F75  ld W,(XBC)
	push	0                                     ; FA9F77  push 0x00
	push	w                                     ; FA9F79  push W
	pushw	hl                                   ; FA9F7B  push HL
	call	0xFA5ED3                              ; FA9F7C  call 0xfa5ed3
	ld	(xiz-2), wa                             ; FA9F80  ld (XIZ+0xfe),WA
	ld	ix, wa                                  ; FA9F83  ld IX,WA
	and	wa, 0x7F                               ; FA9F85  and WA,0x007f
	ld	ix, wa                                  ; FA9F89  ld IX,WA
	pushw	wa                                   ; FA9F8B  push WA
	call	0xFB80A9                              ; FA9F8C  call 0xfb80a9
	inc	8, xsp                                 ; FA9F90  inc 0,XSP
	jr Voice_StageChanSel_Reg04C0__FA9FB4                      ; FA9F92  jr T,0xfa9fb4
Voice_StageChanSel_Reg04C0__FA9F94:
	ld	c, h                                    ; FA9F94  ld C,H
	set	3, c                                   ; FA9F96  set 0x03,C
	pushw	bc                                   ; FA9F99  push BC
	ld	bc, (xiz+8)                             ; FA9F9A  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9F9D  extz XBC
	ld	a, (xbc)                                ; FA9F9F  ld A,(XBC)
	pushw	wa                                   ; FA9FA1  push WA
	pushw	hl                                   ; FA9FA2  push HL
	call	0xFA5ED3                              ; FA9FA3  call 0xfa5ed3
	ld	(xiz-2), wa                             ; FA9FA7  ld (XIZ+0xfe),WA
	ld	ix, wa                                  ; FA9FAA  ld IX,WA
	and	wa, 0x7F                               ; FA9FAC  and WA,0x007f
	ld	ix, wa                                  ; FA9FB0  ld IX,WA
	inc	6, xsp                                 ; FA9FB2  inc 6,XSP
Voice_StageChanSel_Reg04C0__FA9FB4:
	ldw	bc, 27                                 ; FA9FB4  ld BC,0x001b
	mul	xbc, xix                               ; FA9FB7  mul XBC,IX
	add	bc, 18                                 ; FA9FB9  add BC,0x0012
	ld	(xiz-8), bc                             ; FA9FBD  ld (XIZ+0xf8),BC
	ldw	de, 0x4CCF                             ; FA9FC0  ld DE,0x4ccf
	add	de, bc                                 ; FA9FC3  add DE,BC
	ld	bc, (xiz+8)                             ; FA9FC5  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA9FC8  extz XBC
	ld	a, (xbc+12)                             ; FA9FCA  ld A,(XBC+0x0c)
	extz	xde                                   ; FA9FCD  extz XDE
	ld	(xde+6), a                              ; FA9FCF  ld (XDE+0x06),A
	ld	bc, (xiz-2)                             ; FA9FD2  ld BC,(XIZ+0xfe)
	and	bc, 0xFF                               ; FA9FD5  and BC,0x00ff
	cp	bc, 0x80                                ; FA9FD9  cp BC,0x0080
	jrl nc, Voice_StageChanSel_Reg04C0__FAA0B6                 ; FA9FDD  jrl NC,0xfaa0b6
	ld	bc, (xiz-4)                             ; FA9FE0  ld BC,(XIZ+0xfc)
	extz	xbc                                   ; FA9FE3  extz XBC
	ld	wa, (xbc+34)                            ; FA9FE5  ld WA,(XBC+0x22)
	and	wa, 0x3300                             ; FA9FE8  and WA,0x3300
	or	wa, ix                                  ; FA9FEC  or WA,IX
	ordm16_24	(0xD772), wa                     ; FA9FEE  or (0x00d772),WA
	ld	bc, (xiz-2)                             ; FA9FF3  ld BC,(XIZ+0xfe)
	and	bc, 0x8000                             ; FA9FF6  and BC,0x8000
	jr z, Voice_StageChanSel_Reg04C0__FAA00A                   ; FA9FFA  jr Z,0xfaa00a
	ld	bc, (xiz-6)                             ; FA9FFC  ld BC,(XIZ+0xfa)
	extz	xbc                                   ; FA9FFF  extz XBC
	ld	wa, (xbc+4)                             ; FAA001  ld WA,(XBC+0x04)
	and	wa, 12                                 ; FAA004  and WA,0x000c
	jr z, Voice_StageChanSel_Reg04C0__FAA038                   ; FAA008  jr Z,0xfaa038
Voice_StageChanSel_Reg04C0__FAA00A:
	extpfx3 0xC7, 0xF0, 0x8B                   ; FAA00A  ld C,IXL
	ld	(xiz-8), c                              ; FAA00D  ld (XIZ+0xf8),C
	pushw	bc                                   ; FAA010  push BC
	pushw	2                                    ; FAA011  push 0x0002
	push	0                                     ; FAA014  push 0x00
	push	h                                     ; FAA016  push H
	extpfx3 0x9E, 0xFA, 0x04                   ; FAA018  pushw (XIZ+0xfa)
	pushw	hl                                   ; FAA01B  push HL
	calr (0xFA981B - 0xFAA01F)                 ; FAA01C  calr 0xfa981b
	push	0                                     ; FAA01F  push 0x00
	extpfx3 0x8E, 0xF8, 0x04                   ; FAA021  push (XIZ+0xf8)
	calr (0xFA7C3A - 0xFAA027)                 ; FAA024  calr 0xfa7c3a
	lda	xbc, (0xD75E:24)                       ; FAA027  lda XBC,0x00d75e
	push	xbc                                   ; FAA02C  push XBC
	pushw	ix                                   ; FAA02D  push IX
	call	0xFB8012                              ; FAA02E  call 0xfb8012
	add	xsp, 18                                ; FAA032  add XSP,0x00000012
Voice_StageChanSel_Reg04C0__FAA038:
	extz	xde                                   ; FAA038  extz XDE
	ld	c, (xde+7)                              ; FAA03A  ld C,(XDE+0x07)
	cps	c, 0                                   ; FAA03D  cp C,0
	jr z, Voice_StageChanSel_Reg04C0__FAA04F                   ; FAA03F  jr Z,0xfaa04f
	ld	bc, (xiz-6)                             ; FAA041  ld BC,(XIZ+0xfa)
	extz	xbc                                   ; FAA044  extz XBC
	ld	wa, (xbc+6)                             ; FAA046  ld WA,(XBC+0x06)
	and	wa, 0x2000                             ; FAA049  and WA,0x2000
	jr nz, Voice_StageChanSel_Reg04C0__FAA058                  ; FAA04D  jr NZ,0xfaa058
Voice_StageChanSel_Reg04C0__FAA04F:
	extz	xde                                   ; FAA04F  extz XDE
	ld	c, (xde)                                ; FAA051  ld C,(XDE)
	and	c, 32                                  ; FAA053  and C,0x20
	jr z, Voice_StageChanSel_Reg04C0__FAA078                   ; FAA056  jr Z,0xfaa078
Voice_StageChanSel_Reg04C0__FAA058:
	extz	xde                                   ; FAA058  extz XDE
	ld	(xde+8), 0                              ; FAA05A  ld (XDE+0x08),0x00
	extpfx3 0x82, 0x3C, 0xF3                   ; FAA05E  and (XDE),0xf3
	ld	c, (xde)                                ; FAA061  ld C,(XDE)
	set	4, c                                   ; FAA063  set 0x04,C
	ld	(xde), c                                ; FAA066  ld (XDE),C
	stiw_da	(0xD796), 0                        ; FAA068  ld (0x00d796),0x0000
	stiw_da	(0xD7A0), 0                        ; FAA06F  ld (0x00d7a0),0x0000
	jr Voice_StageChanSel_Reg04C0__FAA0A9                      ; FAA076  jr T,0xfaa0a9
Voice_StageChanSel_Reg04C0__FAA078:
	extz	xde                                   ; FAA078  extz XDE
	ld	c, (xde+5)                              ; FAA07A  ld C,(XDE+0x05)
	cps	c, 0                                   ; FAA07D  cp C,0
	jr nz, Voice_StageChanSel_Reg04C0__FAA08A                  ; FAA07F  jr NZ,0xfaa08a
	ld	bc, (xiz-2)                             ; FAA081  ld BC,(XIZ+0xfe)
	and	bc, 0x8000                             ; FAA084  and BC,0x8000
	jr nz, Voice_StageChanSel_Reg04C0__FAA093                  ; FAA088  jr NZ,0xfaa093
Voice_StageChanSel_Reg04C0__FAA08A:
	extz	xde                                   ; FAA08A  extz XDE
	ld	c, (xde)                                ; FAA08C  ld C,(XDE)
	and	c, 56                                  ; FAA08E  and C,0x38
	jr z, Voice_StageChanSel_Reg04C0__FAA0A1                   ; FAA091  jr Z,0xfaa0a1
Voice_StageChanSel_Reg04C0__FAA093:
	ld	bc, (xiz-6)                             ; FAA093  ld BC,(XIZ+0xfa)
	extz	xbc                                   ; FAA096  extz XBC
	ld	wa, (xbc+4)                             ; FAA098  ld WA,(XBC+0x04)
	and	wa, 12                                 ; FAA09B  and WA,0x000c
	jr z, Voice_StageChanSel_Reg04C0__FAA0B6                   ; FAA09F  jr Z,0xfaa0b6
Voice_StageChanSel_Reg04C0__FAA0A1:
	extpfx3 0xC7, 0xF0, 0x8B                   ; FAA0A1  ld C,IXL
	pushw	bc                                   ; FAA0A4  push BC
	calr (0xFA7B31 - 0xFAA0A8)                 ; FAA0A5  calr 0xfa7b31
	popw	bc                                    ; FAA0A8  pop BC
Voice_StageChanSel_Reg04C0__FAA0A9:
	lda	xbc, (0xD75E:24)                       ; FAA0A9  lda XBC,0x00d75e
	push	xbc                                   ; FAA0AE  push XBC
	pushw	ix                                   ; FAA0AF  push IX
	call	0xFB7FCE                              ; FAA0B0  call 0xfb7fce
	inc	6, xsp                                 ; FAA0B4  inc 6,XSP
Voice_StageChanSel_Reg04C0__FAA0B6:
	pop	xix                                    ; FAA0B6  pop XIX
	pop	xde                                    ; FAA0B7  pop XDE
	popw	hl                                    ; FAA0B8  pop HL
	unlk32 xiz                                 ; FAA0B9  unlk XIZ
	ret                                        ; FAA0BB  ret
; --------------------------------------------------------------------------
; Voice_StageRegs_00C0_AB -- 0xFAA0BC..0xFAA1A4 (233 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFB0B39 in VoiceRegs_Stage_A, 0xFB1F27 in VoiceRegs_Stage_B
; Inputs:  frame `link XIZ,-2`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D764
; Voice record: touches voice_record[+0x23(r), +0x25(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFAA0BC-0xFAA1A4
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; Voice_StageRegs_00C0_AB -- stages word 3 (register 0x00C0 + chan) of the 0x0010C000 per-channel
;          staging struct at RAM 0x00D75E, and nothing else in that struct.
;          Write site(s): 0xFAA19A.
;          Argument: the caller pushes XDE, the 68-byte VOICE RECORD at 0x003BCF + 0x44*voice
;          (`ld C,0x44 / mul BC,(XIZ+0x08) / ld <r>,0x3bcf` at the top of every
;          VoiceRegs_Stage_*), immediately before the call.
;          Called from: VoiceRegs_Stage_A, VoiceRegs_Stage_B.
;          Evidence: the write addresses above are instruction operands, listed by
;          `python3 notes/prom_c_understanding_round6.py --staging`, which also asserts that
;          this routine writes EXACTLY the register block(s) its name claims and no other.
;          The struct-word -> register-block map is Dev10C_WriteAllChanRegs's own
;          (notes/prom_c_tg_chanmap.py), cross-checked against
;          notes/prom_c_dev10c_field_sources.py by the same section.
;          Unknown: what register 0x00C0 carries.  The name states WHICH register this
;          routine produces, never what the register means.
;          ★ AND THIS ONE DECODES TO A FORMULA.  Staging word 3 is a PAIR of 7-bit fields:
;          low  = clamp( P[+0x11] +- P[+0x27], 0, 0x7F )
;          high = clamp( P[+0x10] +- P[+0x29] + (int8)P[+0x74], 0, 0x7F )
;          word = (high << 8) | low
;          where P = voice_record[+0x23].  The +- is chosen by TWO BIT PAIRS in one object:
;          with Q = voice_record[+0x25], bit 7 of Q[+0x1A] enables the LOW field's
;          modulation and bit 7 of Q[+0x1C] makes it subtract; bit 8 of the SAME TWO BYTES
;          does the same for the HIGH field.
;          0xFAA0C8 P   0xFAA0D3 low base   0xFAA0CD low depth  0xFAA0EF/0xFAA0FA bit 7
;          0xFAA12E high base   0xFAA128 high depth  0xFAA14A/0xFAA155 bit 8
;          0xFAA171 signed trim P[+0x74]   0xFAA110/0xFAA181 the two clamps
;          0xFAA18C sll 8   0xFAA198 or   0xFAA19A the store
;          Every one of those 15 citations is checked AT THE CITED ADDRESS by
;          `python3 notes/prom_c_understanding_round6.py --reg00c0` -- this tree has published
;          a whole class of citations one byte past the instruction, and that check is the
;          defence against it.
;          The shape is the one Voice_StageRegs_0500_08C0_AB already documents for register
;          0x0500: a byte pair, each half clamped to 0..0x7F, assembled with `sll 8 / or`.
;          ★ ROUND 9: P IS THE PART RECORD, AND THE TWO HALVES ARE MIDI CONTROLLERS
;          91 AND 93.
;          voice_record[+0x23] is assembled as 0x1523 + 0x012C*part: `ld BC,0x1523`
;          at 0xFB0C8A into (XIZ+0xe4), `mul WA,0x012c` at 0xFB0C29 into (XIZ+0xfa),
;          `add BC,(XIZ+0xfa)` at 0xFB0CD3 and `ld (XHL+0x23),BC` at 0xFB0CD6 -- and
;          0x001523 with stride 0x012C is the part-record array.  So P[+0x11] is the
;          byte MidiCtrl_CC93 writes (`add BC,0x0011` at 0xFAD86F, `ld
;          (XBC+0x1523),A` at 0xFAD878) and P[+0x10] is the byte MidiCtrl_CC91
;          writes (`add BC,0x0010` at 0xFAD851, `ld (XBC+0x1523),A` at 0xFAD85A).
;          Register chan+0x00C0 is therefore (controller 91 << 8) | controller 93,
;          each half offset by a per-tone depth and clamped to 0..0x7F.
;          ★ SECOND, INDEPENDENT PRODUCER: NotePool8_Reg00C0_FromPart0Ctrl91And93
;          (0xFC3CFB) builds the same register for the note pool straight out of
;          RAM 0x001533 and 0x001534 -- part 0's +0x10 and +0x11 -- with the same
;          high/low split and no modulation at all.  Two unrelated call paths, one
;          field layout.
;          Unknown: what the bit-7/bit-8 pair selects, and what the device DOES with
;          the pair.  Controllers 91 and 93 are 'effects depth 1 and 3' in the MIDI
;          allocation, but this firmware corroborates only 7, 64 and 120 of its own
;          controller numbers, so no effect is named here.
; --------------------------------------------------------------------------
Voice_StageRegs_00C0_AB:
	link32 0xEE, 0x0C, 0xFE, 0xFF              ; FAA0BC  link XIZ,0xfffe
	push	xhl                                   ; FAA0C0  push XHL
	push	xde                                   ; FAA0C1  push XDE
	pushw	ix                                   ; FAA0C2  push IX
	ld	bc, (xiz+8)                             ; FAA0C3  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA0C6  extz XBC
	ld	hl, (xbc+35)                            ; FAA0C8  ld HL,(XBC+0x23)
	extz	xhl                                   ; FAA0CB  extz XHL
	ld	wa, (xhl+39)                            ; FAA0CD  ld WA,(XHL+0x27)
	ld	(xiz-2), wa                             ; FAA0D0  ld (XIZ+0xfe),WA
	ld	c, (xhl+17)                             ; FAA0D3  ld C,(XHL+0x11)
	extz	bc                                    ; FAA0D6  extz BC
	ld	ix, bc                                  ; FAA0D8  ld IX,BC
	cps	bc, 0                                  ; FAA0DA  cp BC,0
	jr nz, Voice_StageRegs_00C0_AB__FAA0E2                  ; FAA0DC  jr NZ,0xfaa0e2
	cps	wa, 0                                  ; FAA0DE  cp WA,0
	jr z, Voice_StageRegs_00C0_AB__FAA11B                   ; FAA0E0  jr Z,0xfaa11b
Voice_StageRegs_00C0_AB__FAA0E2:
	ld	hl, (xiz+8)                             ; FAA0E2  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FAA0E5  extz XHL
	ld	hl, (xhl+37)                            ; FAA0E7  ld HL,(XHL+0x25)
	extz	xhl                                   ; FAA0EA  extz XHL
	ld	bc, (xhl+26)                            ; FAA0EC  ld BC,(XHL+0x1a)
	and	bc, 0x80                               ; FAA0EF  and BC,0x0080
	jr z, Voice_StageRegs_00C0_AB__FAA10C                   ; FAA0F3  jr Z,0xfaa10c
	extz	xhl                                   ; FAA0F5  extz XHL
	ld	bc, (xhl+28)                            ; FAA0F7  ld BC,(XHL+0x1c)
	and	bc, 0x80                               ; FAA0FA  and BC,0x0080
	jr z, Voice_StageRegs_00C0_AB__FAA107                   ; FAA0FE  jr Z,0xfaa107
	ld	bc, (xiz-2)                             ; FAA100  ld BC,(XIZ+0xfe)
	sub	ix, bc                                 ; FAA103  sub IX,BC
	jr Voice_StageRegs_00C0_AB__FAA10C                      ; FAA105  jr T,0xfaa10c
Voice_StageRegs_00C0_AB__FAA107:
	ld	bc, (xiz-2)                             ; FAA107  ld BC,(XIZ+0xfe)
	add	ix, bc                                 ; FAA10A  add IX,BC
Voice_StageRegs_00C0_AB__FAA10C:
	cps	ix, 0                                  ; FAA10C  cp IX,0
	jr lt, Voice_StageRegs_00C0_AB__FAA11B                  ; FAA10E  jr LT,0xfaa11b
	cp	ix, 0x7F                                ; FAA110  cp IX,0x007f
	jr le, Voice_StageRegs_00C0_AB__FAA11E                  ; FAA114  jr LE,0xfaa11e
	ldw	ix, 0x7F                               ; FAA116  ld IX,0x007f
	jr Voice_StageRegs_00C0_AB__FAA11E                      ; FAA119  jr T,0xfaa11e
Voice_StageRegs_00C0_AB__FAA11B:
	ldw	ix, 0                                  ; FAA11B  ld IX,0x0000
Voice_StageRegs_00C0_AB__FAA11E:
	ld	bc, (xiz+8)                             ; FAA11E  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA121  extz XBC
	ld	de, (xbc+35)                            ; FAA123  ld DE,(XBC+0x23)
	extz	xde                                   ; FAA126  extz XDE
	ld	wa, (xde+41)                            ; FAA128  ld WA,(XDE+0x29)
	ld	(xiz-2), wa                             ; FAA12B  ld (XIZ+0xfe),WA
	ld	c, (xde+16)                             ; FAA12E  ld C,(XDE+0x10)
	extz	bc                                    ; FAA131  extz BC
	ld	hl, bc                                  ; FAA133  ld HL,BC
	cps	bc, 0                                  ; FAA135  cp BC,0
	jr nz, Voice_StageRegs_00C0_AB__FAA13D                  ; FAA137  jr NZ,0xfaa13d
	cps	wa, 0                                  ; FAA139  cp WA,0
	jr z, Voice_StageRegs_00C0_AB__FAA193                   ; FAA13B  jr Z,0xfaa193
Voice_StageRegs_00C0_AB__FAA13D:
	ld	de, (xiz+8)                             ; FAA13D  ld DE,(XIZ+0x08)
	extz	xde                                   ; FAA140  extz XDE
	ld	de, (xde+37)                            ; FAA142  ld DE,(XDE+0x25)
	extz	xde                                   ; FAA145  extz XDE
	ld	bc, (xde+26)                            ; FAA147  ld BC,(XDE+0x1a)
	and	bc, 0x100                              ; FAA14A  and BC,0x0100
	jr z, Voice_StageRegs_00C0_AB__FAA167                   ; FAA14E  jr Z,0xfaa167
	extz	xde                                   ; FAA150  extz XDE
	ld	bc, (xde+28)                            ; FAA152  ld BC,(XDE+0x1c)
	and	bc, 0x100                              ; FAA155  and BC,0x0100
	jr z, Voice_StageRegs_00C0_AB__FAA162                   ; FAA159  jr Z,0xfaa162
	ld	bc, (xiz-2)                             ; FAA15B  ld BC,(XIZ+0xfe)
	sub	hl, bc                                 ; FAA15E  sub HL,BC
	jr Voice_StageRegs_00C0_AB__FAA167                      ; FAA160  jr T,0xfaa167
Voice_StageRegs_00C0_AB__FAA162:
	ld	bc, (xiz-2)                             ; FAA162  ld BC,(XIZ+0xfe)
	add	hl, bc                                 ; FAA165  add HL,BC
Voice_StageRegs_00C0_AB__FAA167:
	ld	bc, (xiz+8)                             ; FAA167  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA16A  extz XBC
	ld	wa, (xbc+35)                            ; FAA16C  ld WA,(XBC+0x23)
	extz	xwa                                   ; FAA16F  extz XWA
	ld	c, (xwa+0x74)                           ; FAA171  ld C,(XWA+0x74)
	exts	bc                                    ; FAA174  exts BC
	add	hl, bc                                 ; FAA176  add HL,BC
	cps	hl, 0                                  ; FAA178  cp HL,0
	jr ge, Voice_StageRegs_00C0_AB__FAA181                  ; FAA17A  jr GE,0xfaa181
	ldw	hl, 0                                  ; FAA17C  ld HL,0x0000
	jr Voice_StageRegs_00C0_AB__FAA18A                      ; FAA17F  jr T,0xfaa18a
Voice_StageRegs_00C0_AB__FAA181:
	cp	hl, 0x7F                                ; FAA181  cp HL,0x007f
	jr le, Voice_StageRegs_00C0_AB__FAA18A                  ; FAA185  jr LE,0xfaa18a
	ldw	hl, 0x7F                               ; FAA187  ld HL,0x007f
Voice_StageRegs_00C0_AB__FAA18A:
	ld	bc, hl                                  ; FAA18A  ld BC,HL
	sll	bc, 8                                  ; FAA18C  sll 0x08,BC
	ld	hl, bc                                  ; FAA18F  ld HL,BC
	jr Voice_StageRegs_00C0_AB__FAA196                      ; FAA191  jr T,0xfaa196
Voice_StageRegs_00C0_AB__FAA193:
	ldw	hl, 0                                  ; FAA193  ld HL,0x0000
Voice_StageRegs_00C0_AB__FAA196:
	ld	bc, hl                                  ; FAA196  ld BC,HL
	or	bc, ix                                  ; FAA198  or BC,IX
	stw_da	(0xD764), bc                        ; FAA19A  ld (0x00d764),BC
	popw	ix                                    ; FAA19F  pop IX
	pop	xde                                    ; FAA1A0  pop XDE
	pop	xhl                                    ; FAA1A1  pop XHL
	unlk32 xiz                                 ; FAA1A2  unlk XIZ
	ret                                        ; FAA1A4  ret
; --------------------------------------------------------------------------
; Voice_StageRegs_00C0_CD -- 0xFAA1A5..0xFAA2B5 (273 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFB2839 in VoiceRegs_Stage_C, 0xFB2F0E in VoiceRegs_Stage_D
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D764
; Voice record: touches voice_record[+0x13(r), +0x23(r), +0x25(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFAA1A5-0xFAA2B5
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; Voice_StageRegs_00C0_CD -- stages word 3 (register 0x00C0 + chan) of the 0x0010C000 per-channel
;          staging struct at RAM 0x00D75E, and nothing else in that struct.
;          Write site(s): 0xFAA2AB.
;          Argument: the caller pushes XDE, the 68-byte VOICE RECORD at 0x003BCF + 0x44*voice
;          (`ld C,0x44 / mul BC,(XIZ+0x08) / ld <r>,0x3bcf` at the top of every
;          VoiceRegs_Stage_*), immediately before the call.
;          Called from: VoiceRegs_Stage_C, VoiceRegs_Stage_D.
;          Evidence: the write addresses above are instruction operands, listed by
;          `python3 notes/prom_c_understanding_round6.py --staging`, which also asserts that
;          this routine writes EXACTLY the register block(s) its name claims and no other.
;          The struct-word -> register-block map is Dev10C_WriteAllChanRegs's own
;          (notes/prom_c_tg_chanmap.py), cross-checked against
;          notes/prom_c_dev10c_field_sources.py by the same section.
;          Unknown: what register 0x00C0 carries.  The name states WHICH register this
;          routine produces, never what the register means.
;          The C/D-path twin of Voice_StageRegs_00C0_AB: same staging word, same pointer
;          voice_record[+0x23], same 0x80/0x100 bit pair at voice_record[+0x25].
;          ⚠ Its arithmetic was NOT decoded in this round -- only the A/B twin was (section
;          3b).  It is NOT asserted to be the same formula; the two routines are 233 and 216
;          bytes and no byte comparison was made.
; --------------------------------------------------------------------------
Voice_StageRegs_00C0_CD:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FAA1A5  link XIZ,0xfffc
	push	xhl                                   ; FAA1A9  push XHL
	push	xde                                   ; FAA1AA  push XDE
	push	xix                                   ; FAA1AB  push XIX
	ld	bc, (xiz+8)                             ; FAA1AC  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA1AF  extz XBC
	ld	xwa, (xbc+19)                           ; FAA1B1  ld XWA,(XBC+0x13)
	ld	xix, xwa                                ; FAA1B4  ld XIX,XWA
	ld	hl, (xbc+35)                            ; FAA1B6  ld HL,(XBC+0x23)
	extz	xhl                                   ; FAA1B9  extz XHL
	ld	iy, (xhl+39)                            ; FAA1BB  ld IY,(XHL+0x27)
	ld	(xiz-4), iy                             ; FAA1BE  ld (XIZ+0xfc),IY
	ld	c, (xhl+17)                             ; FAA1C1  ld C,(XHL+0x11)
	extz	bc                                    ; FAA1C4  extz BC
	ld	(xiz-2), bc                             ; FAA1C6  ld (XIZ+0xfe),BC
	cps	bc, 0                                  ; FAA1C9  cp BC,0
	jr nz, Voice_StageRegs_00C0_CD__FAA1D8                  ; FAA1CB  jr NZ,0xfaa1d8
	ld	c, (xwa+16)                             ; FAA1CD  ld C,(XWA+0x10)
	cps	c, 0                                   ; FAA1D0  cp C,0
	jr nz, Voice_StageRegs_00C0_CD__FAA1D8                  ; FAA1D2  jr NZ,0xfaa1d8
	cps	iy, 0                                  ; FAA1D4  cp IY,0
	jr z, Voice_StageRegs_00C0_CD__FAA228                   ; FAA1D6  jr Z,0xfaa228
Voice_StageRegs_00C0_CD__FAA1D8:
	ld	c, (xix+16)                             ; FAA1D8  ld C,(XIX+0x10)
	extz	bc                                    ; FAA1DB  extz BC
	extpfx3 0x9E, 0xFE, 0x81                   ; FAA1DD  add BC,(XIZ+0xfe)
	add	bc, 0xFFA6                             ; FAA1E0  add BC,0xffa6
	ld	(xiz-2), bc                             ; FAA1E4  ld (XIZ+0xfe),BC
	ld	hl, (xiz+8)                             ; FAA1E7  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FAA1EA  extz XHL
	ld	hl, (xhl+37)                            ; FAA1EC  ld HL,(XHL+0x25)
	extz	xhl                                   ; FAA1EF  extz XHL
	ld	wa, (xhl+26)                            ; FAA1F1  ld WA,(XHL+0x1a)
	and	wa, 0x80                               ; FAA1F4  and WA,0x0080
	jr z, Voice_StageRegs_00C0_CD__FAA213                   ; FAA1F8  jr Z,0xfaa213
	extz	xhl                                   ; FAA1FA  extz XHL
	ld	wa, (xhl+28)                            ; FAA1FC  ld WA,(XHL+0x1c)
	and	wa, 0x80                               ; FAA1FF  and WA,0x0080
	jr z, Voice_StageRegs_00C0_CD__FAA20D                   ; FAA203  jr Z,0xfaa20d
	extpfx3 0x9E, 0xFC, 0xA1                   ; FAA205  sub BC,(XIZ+0xfc)
	ld	(xiz-2), bc                             ; FAA208  ld (XIZ+0xfe),BC
	jr Voice_StageRegs_00C0_CD__FAA213                      ; FAA20B  jr T,0xfaa213
Voice_StageRegs_00C0_CD__FAA20D:
	ld	bc, (xiz-4)                             ; FAA20D  ld BC,(XIZ+0xfc)
	add	(xiz-2), bc                            ; FAA210  add (XIZ+0xfe),BC
Voice_StageRegs_00C0_CD__FAA213:
	cpw (xiz-2), 0x0000                        ; FAA213  cp (XIZ+0xfe),0x0000
	jr lt, Voice_StageRegs_00C0_CD__FAA228                  ; FAA218  jr LT,0xfaa228
	cpw (xiz-2), 0x007F                        ; FAA21A  cp (XIZ+0xfe),0x007f
	jr le, Voice_StageRegs_00C0_CD__FAA22D                  ; FAA21F  jr LE,0xfaa22d
	ldw (xiz-2), 0x007F                        ; FAA221  ld (XIZ+0xfe),0x007f
	jr Voice_StageRegs_00C0_CD__FAA22D                      ; FAA226  jr T,0xfaa22d
Voice_StageRegs_00C0_CD__FAA228:
	ldw (xiz-2), 0x0000                        ; FAA228  ld (XIZ+0xfe),0x0000
Voice_StageRegs_00C0_CD__FAA22D:
	ld	bc, (xiz+8)                             ; FAA22D  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA230  extz XBC
	ld	de, (xbc+35)                            ; FAA232  ld DE,(XBC+0x23)
	extz	xde                                   ; FAA235  extz XDE
	ld	wa, (xde+41)                            ; FAA237  ld WA,(XDE+0x29)
	ld	(xiz-4), wa                             ; FAA23A  ld (XIZ+0xfc),WA
	ld	c, (xde+16)                             ; FAA23D  ld C,(XDE+0x10)
	extz	bc                                    ; FAA240  extz BC
	ld	hl, bc                                  ; FAA242  ld HL,BC
	cps	bc, 0                                  ; FAA244  cp BC,0
	jr nz, Voice_StageRegs_00C0_CD__FAA253                  ; FAA246  jr NZ,0xfaa253
	ld	c, (xix+17)                             ; FAA248  ld C,(XIX+0x11)
	cps	c, 0                                   ; FAA24B  cp C,0
	jr nz, Voice_StageRegs_00C0_CD__FAA253                  ; FAA24D  jr NZ,0xfaa253
	cps	wa, 0                                  ; FAA24F  cp WA,0
	jr z, Voice_StageRegs_00C0_CD__FAA2A3                   ; FAA251  jr Z,0xfaa2a3
Voice_StageRegs_00C0_CD__FAA253:
	ld	c, (xix+17)                             ; FAA253  ld C,(XIX+0x11)
	extz	bc                                    ; FAA256  extz BC
	add	hl, bc                                 ; FAA258  add HL,BC
	add	hl, 0xFFA6                             ; FAA25A  add HL,0xffa6
	ld	de, (xiz+8)                             ; FAA25E  ld DE,(XIZ+0x08)
	extz	xde                                   ; FAA261  extz XDE
	ld	de, (xde+37)                            ; FAA263  ld DE,(XDE+0x25)
	extz	xde                                   ; FAA266  extz XDE
	ld	bc, (xde+26)                            ; FAA268  ld BC,(XDE+0x1a)
	and	bc, 0x100                              ; FAA26B  and BC,0x0100
	jr z, Voice_StageRegs_00C0_CD__FAA288                   ; FAA26F  jr Z,0xfaa288
	extz	xde                                   ; FAA271  extz XDE
	ld	bc, (xde+28)                            ; FAA273  ld BC,(XDE+0x1c)
	and	bc, 0x100                              ; FAA276  and BC,0x0100
	jr z, Voice_StageRegs_00C0_CD__FAA283                   ; FAA27A  jr Z,0xfaa283
	ld	bc, (xiz-4)                             ; FAA27C  ld BC,(XIZ+0xfc)
	sub	hl, bc                                 ; FAA27F  sub HL,BC
	jr Voice_StageRegs_00C0_CD__FAA288                      ; FAA281  jr T,0xfaa288
Voice_StageRegs_00C0_CD__FAA283:
	ld	bc, (xiz-4)                             ; FAA283  ld BC,(XIZ+0xfc)
	add	hl, bc                                 ; FAA286  add HL,BC
Voice_StageRegs_00C0_CD__FAA288:
	cps	hl, 0                                  ; FAA288  cp HL,0
	jr ge, Voice_StageRegs_00C0_CD__FAA291                  ; FAA28A  jr GE,0xfaa291
	ldw	hl, 0                                  ; FAA28C  ld HL,0x0000
	jr Voice_StageRegs_00C0_CD__FAA29A                      ; FAA28F  jr T,0xfaa29a
Voice_StageRegs_00C0_CD__FAA291:
	cp	hl, 0x7F                                ; FAA291  cp HL,0x007f
	jr le, Voice_StageRegs_00C0_CD__FAA29A                  ; FAA295  jr LE,0xfaa29a
	ldw	hl, 0x7F                               ; FAA297  ld HL,0x007f
Voice_StageRegs_00C0_CD__FAA29A:
	ld	bc, hl                                  ; FAA29A  ld BC,HL
	sll	bc, 8                                  ; FAA29C  sll 0x08,BC
	ld	hl, bc                                  ; FAA29F  ld HL,BC
	jr Voice_StageRegs_00C0_CD__FAA2A6                      ; FAA2A1  jr T,0xfaa2a6
Voice_StageRegs_00C0_CD__FAA2A3:
	ldw	hl, 0                                  ; FAA2A3  ld HL,0x0000
Voice_StageRegs_00C0_CD__FAA2A6:
	ld	bc, hl                                  ; FAA2A6  ld BC,HL
	extpfx3 0x9E, 0xFE, 0xE1                   ; FAA2A8  or BC,(XIZ+0xfe)
	stw_da	(0xD764), bc                        ; FAA2AB  ld (0x00d764),BC
	pop	xix                                    ; FAA2B0  pop XIX
	pop	xde                                    ; FAA2B1  pop XDE
	pop	xhl                                    ; FAA2B2  pop XHL
	unlk32 xiz                                 ; FAA2B3  unlk XIZ
	ret                                        ; FAA2B5  ret
; --------------------------------------------------------------------------
; sub_FAA2B6 -- 0xFAA2B6..0xFAA3B4 (255 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFB0B3E in VoiceRegs_Stage_A, 0xFB1F2C in VoiceRegs_Stage_B
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA7EE2 = Clamp_ToRange_LowByte
; Voice record: touches voice_record[+0x17(r), +0x23(r), +0x25(r), +0x29(w)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFAA2B6-0xFAA3B4
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAA2B6:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAA2B6  link XIZ,0x0000
	push	xhl                                   ; FAA2BA  push XHL
	pushw	de                                   ; FAA2BB  push DE
	pushw	ix                                   ; FAA2BC  push IX
	ld	hl, (xiz+8)                             ; FAA2BD  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FAA2C0  extz XHL
	ld	hl, (xhl+37)                            ; FAA2C2  ld HL,(XHL+0x25)
	extz	xhl                                   ; FAA2C5  extz XHL
	ld	bc, (xhl+26)                            ; FAA2C7  ld BC,(XHL+0x1a)
	and	bc, 32                                 ; FAA2CA  and BC,0x0020
	jr z, sub_FAA2B6__FAA318                   ; FAA2CE  jr Z,0xfaa318
	extz	xhl                                   ; FAA2D0  extz XHL
	ld	bc, (xhl+28)                            ; FAA2D2  ld BC,(XHL+0x1c)
	ld	ix, bc                                  ; FAA2D5  ld IX,BC
	and	ix, 32                                 ; FAA2D7  and IX,0x0020
	pushw	0                                    ; FAA2DB  push 0x0000
	pushw	50                                   ; FAA2DE  push 0x0032
	ld	bc, (xiz+8)                             ; FAA2E1  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA2E4  extz XBC
	ld	xwa, (xbc+23)                           ; FAA2E6  ld XWA,(XBC+0x17)
	ld	c, (xwa)                                ; FAA2E9  ld C,(XWA)
	and	c, 63                                  ; FAA2EB  and C,0x3f
	extz	bc                                    ; FAA2EE  extz BC
	ld	hl, bc                                  ; FAA2F0  ld HL,BC
	ld	wa, (xiz+8)                             ; FAA2F2  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FAA2F5  extz XWA
	ld	iy, (xwa+35)                            ; FAA2F7  ld IY,(XWA+0x23)
	extz	xiy                                   ; FAA2FA  extz XIY
	ld	de, (xiy+35)                            ; FAA2FC  ld DE,(XIY+0x23)
	cps	ix, 0                                  ; FAA2FF  cp IX,0
	jr z, sub_FAA2B6__FAA308                   ; FAA301  jr Z,0xfaa308
	sub	bc, de                                 ; FAA303  sub BC,DE
	pushw	bc                                   ; FAA305  push BC
	jr sub_FAA2B6__FAA30D                      ; FAA306  jr T,0xfaa30d
sub_FAA2B6__FAA308:
	ld	bc, hl                                  ; FAA308  ld BC,HL
	add	bc, de                                 ; FAA30A  add BC,DE
	pushw	bc                                   ; FAA30C  push BC
sub_FAA2B6__FAA30D:
	calr (0xFA7EE2 - 0xFAA310)                 ; FAA30D  calr 0xfa7ee2
	exts	wa                                    ; FAA310  exts WA
	ld	ix, wa                                  ; FAA312  ld IX,WA
	inc	6, xsp                                 ; FAA314  inc 6,XSP
	jr sub_FAA2B6__FAA329                      ; FAA316  jr T,0xfaa329
sub_FAA2B6__FAA318:
	ld	bc, (xiz+8)                             ; FAA318  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA31B  extz XBC
	ld	xwa, (xbc+23)                           ; FAA31D  ld XWA,(XBC+0x17)
	ld	c, (xwa)                                ; FAA320  ld C,(XWA)
	and	c, 63                                  ; FAA322  and C,0x3f
	extz	bc                                    ; FAA325  extz BC
	ld	ix, bc                                  ; FAA327  ld IX,BC
sub_FAA2B6__FAA329:
	ld	hl, ix                                  ; FAA329  ld HL,IX
	sll	hl, 2                                  ; FAA32B  sll 0x02,HL
	ldw	ix, 0xFF                               ; FAA32E  ld IX,0x00ff
	ld	bc, hl                                  ; FAA331  ld BC,HL
	sub	ix, bc                                 ; FAA333  sub IX,BC
	cp	ix, 0xFF                                ; FAA335  cp IX,0x00ff
	jr z, sub_FAA2B6__FAA33E                   ; FAA339  jr Z,0xfaa33e
	set	8, ix                                  ; FAA33B  set 0x08,IX
sub_FAA2B6__FAA33E:
	ld	bc, (xiz+8)                             ; FAA33E  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA341  extz XBC
	ld	wa, (xbc+35)                            ; FAA343  ld WA,(XBC+0x23)
	extz	xwa                                   ; FAA346  extz XWA
	ld	c, (xwa+25)                             ; FAA348  ld C,(XWA+0x19)
	and	c, 15                                  ; FAA34B  and C,0x0f
	extz	bc                                    ; FAA34E  extz BC
	ld	hl, bc                                  ; FAA350  ld HL,BC
	cps	bc, 0                                  ; FAA352  cp BC,0
	jr nz, sub_FAA2B6__FAA35B                  ; FAA354  jr NZ,0xfaa35b
	ldw	hl, 0xE00                              ; FAA356  ld HL,0x0e00
	jr sub_FAA2B6__FAA36D                      ; FAA359  jr T,0xfaa36d
sub_FAA2B6__FAA35B:
	cps	hl, 5                                  ; FAA35B  cp HL,5
	jr nz, sub_FAA2B6__FAA364                  ; FAA35D  jr NZ,0xfaa364
	ldw	hl, 0xC00                              ; FAA35F  ld HL,0x0c00
	jr sub_FAA2B6__FAA36D                      ; FAA362  jr T,0xfaa36d
sub_FAA2B6__FAA364:
	dec	1, hl                                  ; FAA364  dec 1,HL
	ld	bc, hl                                  ; FAA366  ld BC,HL
	sll	bc, 9                                  ; FAA368  sll 0x09,BC
	ld	hl, bc                                  ; FAA36B  ld HL,BC
sub_FAA2B6__FAA36D:
	ld	bc, (xiz+8)                             ; FAA36D  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA370  extz XBC
	ld	wa, (xbc+35)                            ; FAA372  ld WA,(XBC+0x23)
	extz	xwa                                   ; FAA375  extz XWA
	ld	c, (xwa+25)                             ; FAA377  ld C,(XWA+0x19)
	and	c, 0xF0                                ; FAA37A  and C,0xf0
	extz	bc                                    ; FAA37D  extz BC
	ld	de, bc                                  ; FAA37F  ld DE,BC
	cps	bc, 0                                  ; FAA381  cp BC,0
	jr nz, sub_FAA2B6__FAA38A                  ; FAA383  jr NZ,0xfaa38a
	ldw	de, 0x7000                             ; FAA385  ld DE,0x7000
	jr sub_FAA2B6__FAA3A1                      ; FAA388  jr T,0xfaa3a1
sub_FAA2B6__FAA38A:
	cp	de, 80                                  ; FAA38A  cp DE,0x0050
	jr nz, sub_FAA2B6__FAA395                  ; FAA38E  jr NZ,0xfaa395
	ldw	de, 0x6000                             ; FAA390  ld DE,0x6000
	jr sub_FAA2B6__FAA3A1                      ; FAA393  jr T,0xfaa3a1
sub_FAA2B6__FAA395:
	ldw	bc, 16                                 ; FAA395  ld BC,0x0010
	sub	de, bc                                 ; FAA398  sub DE,BC
	ld	iy, de                                  ; FAA39A  ld IY,DE
	sll	iy, 8                                  ; FAA39C  sll 0x08,IY
	ld	de, iy                                  ; FAA39F  ld DE,IY
sub_FAA2B6__FAA3A1:
	ld	bc, hl                                  ; FAA3A1  ld BC,HL
	or	bc, ix                                  ; FAA3A3  or BC,IX
	or	bc, de                                  ; FAA3A5  or BC,DE
	ld	wa, (xiz+8)                             ; FAA3A7  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FAA3AA  extz XWA
	ld	(xwa+41), bc                            ; FAA3AC  ld (XWA+0x29),BC
	popw	ix                                    ; FAA3AF  pop IX
	popw	de                                    ; FAA3B0  pop DE
	pop	xhl                                    ; FAA3B1  pop XHL
	unlk32 xiz                                 ; FAA3B2  unlk XIZ
	ret                                        ; FAA3B4  ret
; --------------------------------------------------------------------------
; sub_FAA3B5 -- 0xFAA3B5..0xFAA3EA (54 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFAA492 0xFAA4A3
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFAA3B5-0xFAA3EA
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAA3B5:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAA3B5  link XIZ,0x0000
	pushw	hl                                   ; FAA3B9  push HL
	ld	h, (xiz+10)                             ; FAA3BA  ld H,(XIZ+0x0a)
	cps	h, 0                                   ; FAA3BD  cp H,0
	jr nz, sub_FAA3B5__FAA3C5                  ; FAA3BF  jr NZ,0xfaa3c5
	ldb	a, 7                                   ; FAA3C1  ld A,0x07
	jr sub_FAA3B5__FAA3E7                      ; FAA3C3  jr T,0xfaa3e7
sub_FAA3B5__FAA3C5:
	cps	h, 5                                   ; FAA3C5  cp H,5
	jr nz, sub_FAA3B5__FAA3E1                  ; FAA3C7  jr NZ,0xfaa3e1
	ld	c, (xiz+8)                              ; FAA3C9  ld C,(XIZ+0x08)
	and	c, 15                                  ; FAA3CC  and C,0x0f
	cps	c, 5                                   ; FAA3CF  cp C,5
	jr z, sub_FAA3B5__FAA3DD                   ; FAA3D1  jr Z,0xfaa3dd
	ld	c, (xiz+8)                              ; FAA3D3  ld C,(XIZ+0x08)
	srl	c, 4                                   ; FAA3D6  srl 0x04,C
	cps	c, 5                                   ; FAA3D9  cp C,5
	jr nz, sub_FAA3B5__FAA3E1                  ; FAA3DB  jr NZ,0xfaa3e1
sub_FAA3B5__FAA3DD:
	ldb	a, 6                                   ; FAA3DD  ld A,0x06
	jr sub_FAA3B5__FAA3E7                      ; FAA3DF  jr T,0xfaa3e7
sub_FAA3B5__FAA3E1:
	ld	c, h                                    ; FAA3E1  ld C,H
	dec	1, c                                   ; FAA3E3  dec 1,C
	ld	a, c                                    ; FAA3E5  ld A,C
sub_FAA3B5__FAA3E7:
	popw	hl                                    ; FAA3E7  pop HL
	unlk32 xiz                                 ; FAA3E8  unlk XIZ
	ret                                        ; FAA3EA  ret
; --------------------------------------------------------------------------
; sub_FAA3EB -- 0xFAA3EB..0xFAA4C2 (216 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFB283E in VoiceRegs_Stage_C, 0xFB2F13 in VoiceRegs_Stage_D
; Inputs:  frame `link XIZ,-6`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA7EE2 = Clamp_ToRange_LowByte, 0xFAA3B5 = sub_FAA3B5
; Voice record: touches voice_record[+0x13(r), +0x17(r), +0x23(r), +0x25(r), +0x29(w)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFAA3EB-0xFAA4C2
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAA3EB:
	link32 0xEE, 0x0C, 0xFA, 0xFF              ; FAA3EB  link XIZ,0xfffa
	push	xhl                                   ; FAA3EF  push XHL
	pushw	de                                   ; FAA3F0  push DE
	push	xix                                   ; FAA3F1  push XIX
	ld	bc, (xiz+8)                             ; FAA3F2  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA3F5  extz XBC
	ld	xwa, (xbc+19)                           ; FAA3F7  ld XWA,(XBC+0x13)
	ld	(xiz-4), xwa                            ; FAA3FA  ld (XIZ+0xfc),XWA
	ld	xiy, (xbc+23)                           ; FAA3FD  ld XIY,(XBC+0x17)
	ld	xix, xiy                                ; FAA400  ld XIX,XIY
	ld	hl, bc                                  ; FAA402  ld HL,BC
	extz	xbc                                   ; FAA404  extz XBC
	ld	hl, (xbc+37)                            ; FAA406  ld HL,(XBC+0x25)
	extz	xhl                                   ; FAA409  extz XHL
	ld	bc, (xhl+26)                            ; FAA40B  ld BC,(XHL+0x1a)
	and	bc, 32                                 ; FAA40E  and BC,0x0020
	jr z, sub_FAA3EB__FAA45A                   ; FAA412  jr Z,0xfaa45a
	extz	xhl                                   ; FAA414  extz XHL
	ld	bc, (xhl+28)                            ; FAA416  ld BC,(XHL+0x1c)
	and	bc, 32                                 ; FAA419  and BC,0x0020
	ld	(xiz-6), bc                             ; FAA41D  ld (XIZ+0xfa),BC
	pushw	0                                    ; FAA420  push 0x0000
	pushw	50                                   ; FAA423  push 0x0032
	ld	c, (xiy)                                ; FAA426  ld C,(XIY)
	and	c, 63                                  ; FAA428  and C,0x3f
	extz	bc                                    ; FAA42B  extz BC
	ld	de, bc                                  ; FAA42D  ld DE,BC
	ld	bc, (xiz+8)                             ; FAA42F  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA432  extz XBC
	ld	iy, (xbc+35)                            ; FAA434  ld IY,(XBC+0x23)
	extz	xiy                                   ; FAA437  extz XIY
	ld	hl, (xiy+35)                            ; FAA439  ld HL,(XIY+0x23)
	cpw (xiz-6), 0x0000                        ; FAA43C  cp (XIZ+0xfa),0x0000
	jr z, sub_FAA3EB__FAA44A                   ; FAA441  jr Z,0xfaa44a
	ld	iy, de                                  ; FAA443  ld IY,DE
	sub	iy, hl                                 ; FAA445  sub IY,HL
	pushw	iy                                   ; FAA447  push IY
	jr sub_FAA3EB__FAA44F                      ; FAA448  jr T,0xfaa44f
sub_FAA3EB__FAA44A:
	ld	bc, de                                  ; FAA44A  ld BC,DE
	add	bc, hl                                 ; FAA44C  add BC,HL
	pushw	bc                                   ; FAA44E  push BC
sub_FAA3EB__FAA44F:
	calr (0xFA7EE2 - 0xFAA452)                 ; FAA44F  calr 0xfa7ee2
	exts	wa                                    ; FAA452  exts WA
	ld	hl, wa                                  ; FAA454  ld HL,WA
	inc	6, xsp                                 ; FAA456  inc 6,XSP
	jr sub_FAA3EB__FAA463                      ; FAA458  jr T,0xfaa463
sub_FAA3EB__FAA45A:
	ld	c, (xix)                                ; FAA45A  ld C,(XIX)
	and	c, 63                                  ; FAA45C  and C,0x3f
	extz	bc                                    ; FAA45F  extz BC
	ld	hl, bc                                  ; FAA461  ld HL,BC
sub_FAA3EB__FAA463:
	ld	de, hl                                  ; FAA463  ld DE,HL
	sll	de, 2                                  ; FAA465  sll 0x02,DE
	ldw	hl, 0xFF                               ; FAA468  ld HL,0x00ff
	ld	bc, de                                  ; FAA46B  ld BC,DE
	sub	hl, bc                                 ; FAA46D  sub HL,BC
	cp	hl, 0xFF                                ; FAA46F  cp HL,0x00ff
	jr z, sub_FAA3EB__FAA478                   ; FAA473  jr Z,0xfaa478
	set	8, hl                                  ; FAA475  set 0x08,HL
sub_FAA3EB__FAA478:
	ld	xbc, (xiz-4)                            ; FAA478  ld XBC,(XIZ+0xfc)
	ld	d, (xbc+15)                             ; FAA47B  ld D,(XBC+0x0f)
	ld	wa, (xiz+8)                             ; FAA47E  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FAA481  extz XWA
	ld	iy, (xwa+35)                            ; FAA483  ld IY,(XWA+0x23)
	extz	xiy                                   ; FAA486  extz XIY
	ld	e, (xiy+25)                             ; FAA488  ld E,(XIY+0x19)
	ld	c, d                                    ; FAA48B  ld C,D
	and	c, 15                                  ; FAA48D  and C,0x0f
	pushw	bc                                   ; FAA490  push BC
	pushw	de                                   ; FAA491  push DE
	calr (0xFAA3B5 - 0xFAA495)                 ; FAA492  calr 0xfaa3b5
	extz	wa                                    ; FAA495  extz WA
	ld	ix, wa                                  ; FAA497  ld IX,WA
	sll	ix, 9                                  ; FAA499  sll 0x09,IX
	ld	c, d                                    ; FAA49C  ld C,D
	srl	c, 4                                   ; FAA49E  srl 0x04,C
	pushw	bc                                   ; FAA4A1  push BC
	pushw	de                                   ; FAA4A2  push DE
	calr (0xFAA3B5 - 0xFAA4A6)                 ; FAA4A3  calr 0xfaa3b5
	extz	wa                                    ; FAA4A6  extz WA
	ld	de, wa                                  ; FAA4A8  ld DE,WA
	sll	de, 12                                 ; FAA4AA  sll 0x0c,DE
	ld	bc, ix                                  ; FAA4AD  ld BC,IX
	or	bc, hl                                  ; FAA4AF  or BC,HL
	or	bc, de                                  ; FAA4B1  or BC,DE
	ld	wa, (xiz+8)                             ; FAA4B3  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FAA4B6  extz XWA
	ld	(xwa+41), bc                            ; FAA4B8  ld (XWA+0x29),BC
	inc	8, xsp                                 ; FAA4BB  inc 0,XSP
	pop	xix                                    ; FAA4BD  pop XIX
	popw	de                                    ; FAA4BE  pop DE
	pop	xhl                                    ; FAA4BF  pop XHL
	unlk32 xiz                                 ; FAA4C0  unlk XIZ
	ret                                        ; FAA4C2  ret
; --------------------------------------------------------------------------
; Voice_StageRegs_0800_A -- 0xFAA4C3..0xFAA87D (955 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFB0B43 in VoiceRegs_Stage_A
; Inputs:  frame `link XIZ,-15`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D776
;          reads 0x0014FF
; Calls:   0xFA7598 = Clamp_ToRange_Word, 0xFA75BA = ScaleCoeff_TimesAbsDepth_Shr
;          0xFA766C = ScaleClampedDelta_Shr5
; Voice record: touches voice_record[+0x01(rw), +0x08(r), +0x0C(r), +0x13(r), +0x17(r), +0x1F(r), +0x23(r), +0x25(r), +0x39(w), +0x3B(w), +0x3D(w)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFAA4C3-0xFAA87D
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 2, 2026-08-25.  ONE OF THE FOUR ROUTINES THAT BUILD REGISTER
;          `chan + 0x0800`.  It writes staging word 12 (RAM 0x00D776) as
;          `(level << 8) | rate`: the LOW byte is Voice_EnvelopeRate_Table[tone[+0x28]]
;          and the HIGH byte a value clamped to 0..0xFF through
;          Voice_LevelPair_AttackCurve.  The four writers of word 12 are exactly the
;          four routines in prom_c that read Voice_LevelPair_AttackCurve, and the
;          KN5000 sub-CPU's byte-identical Voice_EnvelopeRate_Table is documented
;          there as "indexed by tonerec+40 ... packed as (level << 8) | rate into TG
;          register 0x800".  See the 0x0800..0x0A40 block comment in front of
;          Dev10C_WriteAllChanRegs; census by notes/prom_c_reg_bytepair_check.py.
;          ⚠ This says what ONE of the routine's outputs is, not what the routine is.
; ★ ROUND 6 ------------------------------------------------------------
; Voice_StageRegs_0800_A -- stages word 12 (register 0x0800 + chan) of the 0x0010C000 per-channel
;          staging struct at RAM 0x00D75E, and nothing else in that struct.
;          Write site(s): 0xFAA649.
;          Argument: the caller pushes XDE, the 68-byte VOICE RECORD at 0x003BCF + 0x44*voice
;          (`ld C,0x44 / mul BC,(XIZ+0x08) / ld <r>,0x3bcf` at the top of every
;          VoiceRegs_Stage_*), immediately before the call.
;          Called from: VoiceRegs_Stage_A.
;          Evidence: the write addresses above are instruction operands, listed by
;          `python3 notes/prom_c_understanding_round6.py --staging`, which also asserts that
;          this routine writes EXACTLY the register block(s) its name claims and no other.
;          The struct-word -> register-block map is Dev10C_WriteAllChanRegs's own
;          (notes/prom_c_tg_chanmap.py), cross-checked against
;          notes/prom_c_dev10c_field_sources.py by the same section.
;          Unknown: what register 0x0800 carries.  The name states WHICH register this
;          routine produces, never what the register means.
; --------------------------------------------------------------------------
Voice_StageRegs_0800_A:
	link32 0xEE, 0x0C, 0xF1, 0xFF              ; FAA4C3  link XIZ,0xfff1
	push	xhl                                   ; FAA4C7  push XHL
	pushw	de                                   ; FAA4C8  push DE
	pushw	ix                                   ; FAA4C9  push IX
	ld	bc, (xiz+8)                             ; FAA4CA  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA4CD  extz XBC
	ld	xwa, (xbc+23)                           ; FAA4CF  ld XWA,(XBC+0x17)
	ld	(xiz-6), xwa                            ; FAA4D2  ld (XIZ+0xfa),XWA
	ld	xiy, (xbc+31)                           ; FAA4D5  ld XIY,(XBC+0x1f)
	ld	(xiz-10), xiy                           ; FAA4D8  ld (XIZ+0xf6),XIY
	ld	bc, (0x14FF:16)                       ; FAA4DB  ld BC,(0x14ff)
	and	bc, 1                                  ; FAA4DF  and BC,0x0001
	jr nz, Voice_StageRegs_0800_A__FAA4F5                  ; FAA4E3  jr NZ,0xfaa4f5
	ld	bc, (xiz+8)                             ; FAA4E5  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA4E8  extz XBC
	ld	xwa, (xbc+19)                           ; FAA4EA  ld XWA,(XBC+0x13)
	ld	c, (xwa+16)                             ; FAA4ED  ld C,(XWA+0x10)
	and	c, 16                                  ; FAA4F0  and C,0x10
	jr z, Voice_StageRegs_0800_A__FAA501                   ; FAA4F3  jr Z,0xfaa501
Voice_StageRegs_0800_A__FAA4F5:
	ld	bc, (xiz+8)                             ; FAA4F5  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA4F8  extz XBC
	extpfx5 0x99, 0x01, 0x3C, 0xFF, 0x7F       ; FAA4FA  and (XBC+0x01),0x7fff
	jr Voice_StageRegs_0800_A__FAA50B                      ; FAA4FF  jr T,0xfaa50b
Voice_StageRegs_0800_A__FAA501:
	ld	bc, (xiz+8)                             ; FAA501  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA504  extz XBC
	extpfx5 0x99, 0x01, 0x3E, 0x00, 0x80       ; FAA506  or (XBC+0x01),0x8000
Voice_StageRegs_0800_A__FAA50B:
	ld	hl, (xiz+8)                             ; FAA50B  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FAA50E  extz XHL
	ld	hl, (xhl+37)                            ; FAA510  ld HL,(XHL+0x25)
	extz	xhl                                   ; FAA513  extz XHL
	ld	bc, (xhl+26)                            ; FAA515  ld BC,(XHL+0x1a)
	and	bc, 0x400                              ; FAA518  and BC,0x0400
	jr z, Voice_StageRegs_0800_A__FAA55B                   ; FAA51C  jr Z,0xfaa55b
	extz	xhl                                   ; FAA51E  extz XHL
	ld	bc, (xhl+28)                            ; FAA520  ld BC,(XHL+0x1c)
	ld	ix, bc                                  ; FAA523  ld IX,BC
	and	ix, 0x400                              ; FAA525  and IX,0x0400
	pushw	0                                    ; FAA529  push 0x0000
	pushw	0x64                                 ; FAA52C  push 0x0064
	ld	xbc, (xiz-6)                            ; FAA52F  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+39)                             ; FAA532  ld A,(XBC+0x27)
	extz	wa                                    ; FAA535  extz WA
	ld	hl, wa                                  ; FAA537  ld HL,WA
	ld	bc, (xiz+8)                             ; FAA539  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA53C  extz XBC
	ld	iy, (xbc+35)                            ; FAA53E  ld IY,(XBC+0x23)
	extz	xiy                                   ; FAA541  extz XIY
	ld	de, (xiy+45)                            ; FAA543  ld DE,(XIY+0x2d)
	jr z, Voice_StageRegs_0800_A__FAA54D                   ; FAA546  jr Z,0xfaa54d
	sub	wa, de                                 ; FAA548  sub WA,DE
	pushw	wa                                   ; FAA54A  push WA
	jr Voice_StageRegs_0800_A__FAA552                      ; FAA54B  jr T,0xfaa552
Voice_StageRegs_0800_A__FAA54D:
	ld	bc, hl                                  ; FAA54D  ld BC,HL
	add	bc, de                                 ; FAA54F  add BC,DE
	pushw	bc                                   ; FAA551  push BC
Voice_StageRegs_0800_A__FAA552:
	calr (0xFA7598 - 0xFAA555)                 ; FAA552  calr 0xfa7598
	ld	hl, wa                                  ; FAA555  ld HL,WA
	inc	6, xsp                                 ; FAA557  inc 6,XSP
	jr Voice_StageRegs_0800_A__FAA565                      ; FAA559  jr T,0xfaa565
Voice_StageRegs_0800_A__FAA55B:
	ld	xbc, (xiz-6)                            ; FAA55B  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+39)                             ; FAA55E  ld A,(XBC+0x27)
	extz	wa                                    ; FAA561  extz WA
	ld	hl, wa                                  ; FAA563  ld HL,WA
Voice_StageRegs_0800_A__FAA565:
	ld	c, l                                    ; FAA565  ld C,L
	extz	bc                                    ; FAA567  extz BC
	extz	xbc                                   ; FAA569  extz XBC
	add	xbc, 0xFDEF74                          ; FAA56B  add XBC,0x00fdef74
	ld	a, (xbc)                                ; FAA571  ld A,(XBC)
	extz	wa                                    ; FAA573  extz WA
	ld	hl, wa                                  ; FAA575  ld HL,WA
	ld	xbc, (xiz-6)                            ; FAA577  ld XBC,(XIZ+0xfa)
	ld	d, (xbc+51)                             ; FAA57A  ld D,(XBC+0x33)
	cps	d, 0                                   ; FAA57D  cp D,0
	jr z, Voice_StageRegs_0800_A__FAA5E1                   ; FAA57F  jr Z,0xfaa5e1
	push	0                                     ; FAA581  push 0x00
	push	d                                     ; FAA583  push D
	ld	a, (xbc+50)                             ; FAA585  ld A,(XBC+0x32)
	pushw	wa                                   ; FAA588  push WA
	ld	a, (xbc+49)                             ; FAA589  ld A,(XBC+0x31)
	pushw	wa                                   ; FAA58C  push WA
	ld	a, (xbc+48)                             ; FAA58D  ld A,(XBC+0x30)
	pushw	wa                                   ; FAA590  push WA
	ld	wa, (xiz+8)                             ; FAA591  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FAA594  extz XWA
	ld	iy, (xwa+8)                             ; FAA596  ld IY,(XWA+0x08)
	pushw	iy                                   ; FAA599  push IY
	calr (0xFA766C - 0xFAA59D)                 ; FAA59A  calr 0xfa766c
	ld	ix, wa                                  ; FAA59D  ld IX,WA
	ld	xbc, (xiz-6)                            ; FAA59F  ld XBC,(XIZ+0xfa)
	ld	d, (xbc+46)                             ; FAA5A2  ld D,(XBC+0x2e)
	inc	8, xsp                                 ; FAA5A5  inc 0,XSP
	inc	2, xsp                                 ; FAA5A7  inc 2,XSP
	cps	d, 0                                   ; FAA5A9  cp D,0
	jr z, Voice_StageRegs_0800_A__FAA5D4                   ; FAA5AB  jr Z,0xfaa5d4
	pushw	4                                    ; FAA5AD  push 0x0004
	ld	bc, (xiz+8)                             ; FAA5B0  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA5B3  extz XBC
	ld	a, (xbc+12)                             ; FAA5B5  ld A,(XBC+0x0c)
	pushw	wa                                   ; FAA5B8  push WA
	push	0                                     ; FAA5B9  push 0x00
	push	d                                     ; FAA5BB  push D
	calr (0xFA75BA - 0xFAA5C0)                 ; FAA5BD  calr 0xfa75ba
	ld	(xiz-13), wa                            ; FAA5C0  ld (XIZ+0xf3),WA
	inc	6, xsp                                 ; FAA5C3  inc 6,XSP
	pushw	0                                    ; FAA5C5  push 0x0000
	pushw	0xFF                                 ; FAA5C8  push 0x00ff
	ld	bc, hl                                  ; FAA5CB  ld BC,HL
	add	bc, ix                                 ; FAA5CD  add BC,IX
	add	bc, wa                                 ; FAA5CF  add BC,WA
	pushw	bc                                   ; FAA5D1  push BC
	jr Voice_StageRegs_0800_A__FAA60B                      ; FAA5D2  jr T,0xfaa60b
Voice_StageRegs_0800_A__FAA5D4:
	pushw	0                                    ; FAA5D4  push 0x0000
	pushw	0xFF                                 ; FAA5D7  push 0x00ff
	ld	bc, hl                                  ; FAA5DA  ld BC,HL
	add	bc, ix                                 ; FAA5DC  add BC,IX
	pushw	bc                                   ; FAA5DE  push BC
	jr Voice_StageRegs_0800_A__FAA60B                      ; FAA5DF  jr T,0xfaa60b
Voice_StageRegs_0800_A__FAA5E1:
	ld	xbc, (xiz-6)                            ; FAA5E1  ld XBC,(XIZ+0xfa)
	ld	d, (xbc+46)                             ; FAA5E4  ld D,(XBC+0x2e)
	cps	d, 0                                   ; FAA5E7  cp D,0
	jr z, Voice_StageRegs_0800_A__FAA612                   ; FAA5E9  jr Z,0xfaa612
	pushw	4                                    ; FAA5EB  push 0x0004
	ld	wa, (xiz+8)                             ; FAA5EE  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FAA5F1  extz XWA
	ld	c, (xwa+12)                             ; FAA5F3  ld C,(XWA+0x0c)
	pushw	bc                                   ; FAA5F6  push BC
	push	0                                     ; FAA5F7  push 0x00
	push	d                                     ; FAA5F9  push D
	calr (0xFA75BA - 0xFAA5FE)                 ; FAA5FB  calr 0xfa75ba
	ld	ix, wa                                  ; FAA5FE  ld IX,WA
	inc	6, xsp                                 ; FAA600  inc 6,XSP
	pushw	0                                    ; FAA602  push 0x0000
	pushw	0xFF                                 ; FAA605  push 0x00ff
	add	wa, hl                                 ; FAA608  add WA,HL
	pushw	wa                                   ; FAA60A  push WA
Voice_StageRegs_0800_A__FAA60B:
	calr (0xFA7598 - 0xFAA60E)                 ; FAA60B  calr 0xfa7598
	ld	hl, wa                                  ; FAA60E  ld HL,WA
	inc	6, xsp                                 ; FAA610  inc 6,XSP
Voice_StageRegs_0800_A__FAA612:
	ld	xbc, (xiz-10)                           ; FAA612  ld XBC,(XIZ+0xf6)
	ld	a, (xbc)                                ; FAA615  ld A,(XBC)
	and	a, 1                                   ; FAA617  and A,0x01
	jr z, Voice_StageRegs_0800_A__FAA624                   ; FAA61A  jr Z,0xfaa624
	cp	hl, 0xFF                                ; FAA61C  cp HL,0x00ff
	jr nz, Voice_StageRegs_0800_A__FAA624                  ; FAA620  jr NZ,0xfaa624
	dec	1, hl                                  ; FAA622  dec 1,HL
Voice_StageRegs_0800_A__FAA624:
	ld	xbc, (xiz-6)                            ; FAA624  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+40)                             ; FAA627  ld A,(XBC+0x28)
	extz	wa                                    ; FAA62A  extz WA
	extz	xwa                                   ; FAA62C  extz XWA
	add	xwa, 0xFDF03E                          ; FAA62E  add XWA,0x00fdf03e
	ld	w, (xwa)                                ; FAA634  ld W,(XWA)
	ld	a, w                                    ; FAA636  ld A,W
	extz	wa                                    ; FAA638  extz WA
	ld	de, wa                                  ; FAA63A  ld DE,WA
	and	de, 0xFF                               ; FAA63C  and DE,0x00ff
	ld	iy, hl                                  ; FAA640  ld IY,HL
	sll	iy, 8                                  ; FAA642  sll 0x08,IY
	ld	ix, iy                                  ; FAA645  ld IX,IY
	or	ix, de                                  ; FAA647  or IX,DE
	stw_da	(0xD776), ix                        ; FAA649  ld (0x00d776),IX
	ld	bc, (xiz+8)                             ; FAA64E  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA651  extz XBC
	ld	(xbc+57), ix                            ; FAA653  ld (XBC+0x39),IX
	ld	hl, (xiz+8)                             ; FAA656  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FAA659  extz XHL
	ld	hl, (xhl+37)                            ; FAA65B  ld HL,(XHL+0x25)
	extz	xhl                                   ; FAA65E  extz XHL
	ld	bc, (xhl+26)                            ; FAA660  ld BC,(XHL+0x1a)
	and	bc, 0x800                              ; FAA663  and BC,0x0800
	jrl z, Voice_StageRegs_0800_A__FAA6F5                  ; FAA667  jrl Z,0xfaa6f5
	extz	xhl                                   ; FAA66A  extz XHL
	ld	bc, (xhl+28)                            ; FAA66C  ld BC,(XHL+0x1c)
	ld	ix, bc                                  ; FAA66F  ld IX,BC
	and	ix, 0x800                              ; FAA671  and IX,0x0800
	pushw	0                                    ; FAA675  push 0x0000
	pushw	0x64                                 ; FAA678  push 0x0064
	ld	xbc, (xiz-6)                            ; FAA67B  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+41)                             ; FAA67E  ld A,(XBC+0x29)
	extz	wa                                    ; FAA681  extz WA
	ld	de, wa                                  ; FAA683  ld DE,WA
	ld	bc, (xiz+8)                             ; FAA685  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA688  extz XBC
	ld	iy, (xbc+35)                            ; FAA68A  ld IY,(XBC+0x23)
	extz	xiy                                   ; FAA68D  extz XIY
	ld	hl, (xiy+47)                            ; FAA68F  ld HL,(XIY+0x2f)
	jr z, Voice_StageRegs_0800_A__FAA6C0                   ; FAA692  jr Z,0xfaa6c0
	sub	wa, hl                                 ; FAA694  sub WA,HL
	pushw	wa                                   ; FAA696  push WA
	calr (0xFA7598 - 0xFAA69A)                 ; FAA697  calr 0xfa7598
	ld	hl, wa                                  ; FAA69A  ld HL,WA
	inc	6, xsp                                 ; FAA69C  inc 6,XSP
	pushw	0                                    ; FAA69E  push 0x0000
	pushw	0x64                                 ; FAA6A1  push 0x0064
	ld	xbc, (xiz-6)                            ; FAA6A4  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+43)                             ; FAA6A7  ld A,(XBC+0x2b)
	extz	wa                                    ; FAA6AA  extz WA
	ld	de, wa                                  ; FAA6AC  ld DE,WA
	ld	bc, (xiz+8)                             ; FAA6AE  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA6B1  extz XBC
	ld	iy, (xbc+35)                            ; FAA6B3  ld IY,(XBC+0x23)
	extz	xiy                                   ; FAA6B6  extz XIY
	ld	bc, (xiy+47)                            ; FAA6B8  ld BC,(XIY+0x2f)
	sub	wa, bc                                 ; FAA6BB  sub WA,BC
	pushw	wa                                   ; FAA6BD  push WA
	jr Voice_StageRegs_0800_A__FAA6EC                      ; FAA6BE  jr T,0xfaa6ec
Voice_StageRegs_0800_A__FAA6C0:
	ld	bc, de                                  ; FAA6C0  ld BC,DE
	add	bc, hl                                 ; FAA6C2  add BC,HL
	pushw	bc                                   ; FAA6C4  push BC
	calr (0xFA7598 - 0xFAA6C8)                 ; FAA6C5  calr 0xfa7598
	ld	hl, wa                                  ; FAA6C8  ld HL,WA
	inc	6, xsp                                 ; FAA6CA  inc 6,XSP
	pushw	0                                    ; FAA6CC  push 0x0000
	pushw	0x64                                 ; FAA6CF  push 0x0064
	ld	xbc, (xiz-6)                            ; FAA6D2  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+43)                             ; FAA6D5  ld A,(XBC+0x2b)
	extz	wa                                    ; FAA6D8  extz WA
	ld	de, wa                                  ; FAA6DA  ld DE,WA
	ld	bc, (xiz+8)                             ; FAA6DC  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA6DF  extz XBC
	ld	iy, (xbc+35)                            ; FAA6E1  ld IY,(XBC+0x23)
	extz	xiy                                   ; FAA6E4  extz XIY
	ld	bc, (xiy+47)                            ; FAA6E6  ld BC,(XIY+0x2f)
	add	wa, bc                                 ; FAA6E9  add WA,BC
	pushw	wa                                   ; FAA6EB  push WA
Voice_StageRegs_0800_A__FAA6EC:
	calr (0xFA7598 - 0xFAA6EF)                 ; FAA6EC  calr 0xfa7598
	ld	de, wa                                  ; FAA6EF  ld DE,WA
	inc	6, xsp                                 ; FAA6F1  inc 6,XSP
	jr Voice_StageRegs_0800_A__FAA706                      ; FAA6F3  jr T,0xfaa706
Voice_StageRegs_0800_A__FAA6F5:
	ld	xbc, (xiz-6)                            ; FAA6F5  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+41)                             ; FAA6F8  ld A,(XBC+0x29)
	extz	wa                                    ; FAA6FB  extz WA
	ld	hl, wa                                  ; FAA6FD  ld HL,WA
	ld	a, (xbc+43)                             ; FAA6FF  ld A,(XBC+0x2b)
	extz	wa                                    ; FAA702  extz WA
	ld	de, wa                                  ; FAA704  ld DE,WA
Voice_StageRegs_0800_A__FAA706:
	ld	c, l                                    ; FAA706  ld C,L
	extz	bc                                    ; FAA708  extz BC
	extz	xbc                                   ; FAA70A  extz XBC
	add	xbc, 0xFDEFD9                          ; FAA70C  add XBC,0x00fdefd9
	ld	a, (xbc)                                ; FAA712  ld A,(XBC)
	extz	wa                                    ; FAA714  extz WA
	ld	hl, wa                                  ; FAA716  ld HL,WA
	ld	b, e                                    ; FAA718  ld B,E
	extpfx3 0xC7, 0xF4, 0x9A                   ; FAA71A  ld IYL,B
	extz	iy                                    ; FAA71D  extz IY
	extz	xiy                                   ; FAA71F  extz XIY
	add	xiy, 0xFDEFD9                          ; FAA721  add XIY,0x00fdefd9
	ld	c, (xiy)                                ; FAA727  ld C,(XIY)
	extz	bc                                    ; FAA729  extz BC
	ld	de, bc                                  ; FAA72B  ld DE,BC
	ld	xiy, (xiz-6)                            ; FAA72D  ld XIY,(XIZ+0xfa)
	ld	c, (xiy+52)                             ; FAA730  ld C,(XIY+0x34)
	ld	(xiz-11), c                             ; FAA733  ld (XIZ+0xf5),C
	cps	c, 0                                   ; FAA736  cp C,0
	jrl z, Voice_StageRegs_0800_A__FAA7CC                  ; FAA738  jrl Z,0xfaa7cc
	pushw	bc                                   ; FAA73B  push BC
	ld	b, (xiy+50)                             ; FAA73C  ld B,(XIY+0x32)
	push	0                                     ; FAA73F  push 0x00
	push	b                                     ; FAA741  push B
	ld	b, (xiy+49)                             ; FAA743  ld B,(XIY+0x31)
	push	0                                     ; FAA746  push 0x00
	push	b                                     ; FAA748  push B
	ld	b, (xiy+48)                             ; FAA74A  ld B,(XIY+0x30)
	push	0                                     ; FAA74D  push 0x00
	push	b                                     ; FAA74F  push B
	ld	bc, (xiz+8)                             ; FAA751  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA754  extz XBC
	ld	wa, (xbc+8)                             ; FAA756  ld WA,(XBC+0x08)
	pushw	wa                                   ; FAA759  push WA
	calr (0xFA766C - 0xFAA75D)                 ; FAA75A  calr 0xfa766c
	ld	ix, wa                                  ; FAA75D  ld IX,WA
	ld	xbc, (xiz-6)                            ; FAA75F  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+47)                             ; FAA762  ld A,(XBC+0x2f)
	ld	(xiz-1), a                              ; FAA765  ld (XIZ+0xff),A
	inc	8, xsp                                 ; FAA768  inc 0,XSP
	inc	2, xsp                                 ; FAA76A  inc 2,XSP
	cps	a, 0                                   ; FAA76C  cp A,0
	jr z, Voice_StageRegs_0800_A__FAA7AD                   ; FAA76E  jr Z,0xfaa7ad
	pushw	4                                    ; FAA770  push 0x0004
	ld	wa, (xiz+8)                             ; FAA773  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FAA776  extz XWA
	ld	c, (xwa+12)                             ; FAA778  ld C,(XWA+0x0c)
	pushw	bc                                   ; FAA77B  push BC
	push	0                                     ; FAA77C  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FAA77E  push (XIZ+0xff)
	calr (0xFA75BA - 0xFAA784)                 ; FAA781  calr 0xfa75ba
	ld	(xiz-13), wa                            ; FAA784  ld (XIZ+0xf3),WA
	pushw	0                                    ; FAA787  push 0x0000
	pushw	0xFF                                 ; FAA78A  push 0x00ff
	ld	bc, hl                                  ; FAA78D  ld BC,HL
	add	bc, ix                                 ; FAA78F  add BC,IX
	add	bc, wa                                 ; FAA791  add BC,WA
	pushw	bc                                   ; FAA793  push BC
	calr (0xFA7598 - 0xFAA797)                 ; FAA794  calr 0xfa7598
	ld	hl, wa                                  ; FAA797  ld HL,WA
	inc	8, xsp                                 ; FAA799  inc 0,XSP
	inc	4, xsp                                 ; FAA79B  inc 4,XSP
	pushw	0                                    ; FAA79D  push 0x0000
	pushw	0xFF                                 ; FAA7A0  push 0x00ff
	ld	bc, de                                  ; FAA7A3  ld BC,DE
	add	bc, ix                                 ; FAA7A5  add BC,IX
	extpfx3 0x9E, 0xF3, 0x81                   ; FAA7A7  add BC,(XIZ+0xf3)
	pushw	bc                                   ; FAA7AA  push BC
	jr Voice_StageRegs_0800_A__FAA80C                      ; FAA7AB  jr T,0xfaa80c
Voice_StageRegs_0800_A__FAA7AD:
	pushw	0                                    ; FAA7AD  push 0x0000
	pushw	0xFF                                 ; FAA7B0  push 0x00ff
	ld	bc, hl                                  ; FAA7B3  ld BC,HL
	add	bc, ix                                 ; FAA7B5  add BC,IX
	pushw	bc                                   ; FAA7B7  push BC
	calr (0xFA7598 - 0xFAA7BB)                 ; FAA7B8  calr 0xfa7598
	ld	hl, wa                                  ; FAA7BB  ld HL,WA
	inc	6, xsp                                 ; FAA7BD  inc 6,XSP
	pushw	0                                    ; FAA7BF  push 0x0000
	pushw	0xFF                                 ; FAA7C2  push 0x00ff
	ld	bc, de                                  ; FAA7C5  ld BC,DE
	add	bc, ix                                 ; FAA7C7  add BC,IX
	pushw	bc                                   ; FAA7C9  push BC
	jr Voice_StageRegs_0800_A__FAA80C                      ; FAA7CA  jr T,0xfaa80c
Voice_StageRegs_0800_A__FAA7CC:
	ld	xbc, (xiz-6)                            ; FAA7CC  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+47)                             ; FAA7CF  ld A,(XBC+0x2f)
	ld	(xiz-2), a                              ; FAA7D2  ld (XIZ+0xfe),A
	cps	a, 0                                   ; FAA7D5  cp A,0
	jr z, Voice_StageRegs_0800_A__FAA813                   ; FAA7D7  jr Z,0xfaa813
	pushw	4                                    ; FAA7D9  push 0x0004
	ld	wa, (xiz+8)                             ; FAA7DC  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FAA7DF  extz XWA
	ld	c, (xwa+12)                             ; FAA7E1  ld C,(XWA+0x0c)
	pushw	bc                                   ; FAA7E4  push BC
	push	0                                     ; FAA7E5  push 0x00
	extpfx3 0x8E, 0xFE, 0x04                   ; FAA7E7  push (XIZ+0xfe)
	calr (0xFA75BA - 0xFAA7ED)                 ; FAA7EA  calr 0xfa75ba
	ld	ix, wa                                  ; FAA7ED  ld IX,WA
	pushw	0                                    ; FAA7EF  push 0x0000
	pushw	0xFF                                 ; FAA7F2  push 0x00ff
	add	wa, hl                                 ; FAA7F5  add WA,HL
	pushw	wa                                   ; FAA7F7  push WA
	calr (0xFA7598 - 0xFAA7FB)                 ; FAA7F8  calr 0xfa7598
	ld	hl, wa                                  ; FAA7FB  ld HL,WA
	inc	8, xsp                                 ; FAA7FD  inc 0,XSP
	inc	4, xsp                                 ; FAA7FF  inc 4,XSP
	pushw	0                                    ; FAA801  push 0x0000
	pushw	0xFF                                 ; FAA804  push 0x00ff
	ld	bc, de                                  ; FAA807  ld BC,DE
	add	bc, ix                                 ; FAA809  add BC,IX
	pushw	bc                                   ; FAA80B  push BC
Voice_StageRegs_0800_A__FAA80C:
	calr (0xFA7598 - 0xFAA80F)                 ; FAA80C  calr 0xfa7598
	ld	de, wa                                  ; FAA80F  ld DE,WA
	inc	6, xsp                                 ; FAA811  inc 6,XSP
Voice_StageRegs_0800_A__FAA813:
	ld	xbc, (xiz-6)                            ; FAA813  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+42)                             ; FAA816  ld A,(XBC+0x2a)
	extz	wa                                    ; FAA819  extz WA
	extz	xwa                                   ; FAA81B  extz XWA
	add	xwa, 0xFDF03E                          ; FAA81D  add XWA,0x00fdf03e
	ld	w, (xwa)                                ; FAA823  ld W,(XWA)
	extpfx3 0xC7, 0xF0, 0x98                   ; FAA825  ld IXL,W
	extz	ix                                    ; FAA828  extz IX
	cps	ix, 4                                  ; FAA82A  cp IX,4
	jr ge, Voice_StageRegs_0800_A__FAA831                  ; FAA82C  jr GE,0xfaa831
	ldw	ix, 4                                  ; FAA82E  ld IX,0x0004
Voice_StageRegs_0800_A__FAA831:
	ld	xbc, (xiz-6)                            ; FAA831  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+44)                             ; FAA834  ld A,(XBC+0x2c)
	extz	wa                                    ; FAA837  extz WA
	extz	xwa                                   ; FAA839  extz XWA
	add	xwa, 0xFDF03E                          ; FAA83B  add XWA,0x00fdf03e
	ld	w, (xwa)                                ; FAA841  ld W,(XWA)
	ld	a, w                                    ; FAA843  ld A,W
	extz	wa                                    ; FAA845  extz WA
	ld	(xiz-13), wa                            ; FAA847  ld (XIZ+0xf3),WA
	ld	iy, ix                                  ; FAA84A  ld IY,IX
	and	iy, 0xFF                               ; FAA84C  and IY,0x00ff
	ld	(xiz-15), iy                            ; FAA850  ld (XIZ+0xf1),IY
	ld	bc, hl                                  ; FAA853  ld BC,HL
	sll	bc, 8                                  ; FAA855  sll 0x08,BC
	or	bc, iy                                  ; FAA858  or BC,IY
	ld	wa, (xiz+8)                             ; FAA85A  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FAA85D  extz XWA
	ld	(xwa+59), bc                            ; FAA85F  ld (XWA+0x3b),BC
	ld	hl, (xiz-13)                            ; FAA862  ld HL,(XIZ+0xf3)
	and	hl, 0xFF                               ; FAA865  and HL,0x00ff
	ld	bc, de                                  ; FAA869  ld BC,DE
	sll	bc, 8                                  ; FAA86B  sll 0x08,BC
	or	bc, hl                                  ; FAA86E  or BC,HL
	ld	wa, (xiz+8)                             ; FAA870  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FAA873  extz XWA
	ld	(xwa+61), bc                            ; FAA875  ld (XWA+0x3d),BC
	popw	ix                                    ; FAA878  pop IX
	popw	de                                    ; FAA879  pop DE
	pop	xhl                                    ; FAA87A  pop XHL
	unlk32 xiz                                 ; FAA87B  unlk XIZ
	ret                                        ; FAA87D  ret
; --------------------------------------------------------------------------
; Voice_StageRegs_0840_0880_AB -- 0xFAA87E..0xFAA96B (238 bytes)
;
; Called from: 4 site(s) outside this module:
;          0xFAE061 in sub_FAE013__FAE053, 0xFB0B4B in VoiceRegs_Stage_A
;          0xFB1F6B in VoiceRegs_Stage_B, 0xFB1F83 in VoiceRegs_Stage_B__FB1F7B
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: writes 0x00D778, 0x00D77A
; Calls:   0xFA7598 = Clamp_ToRange_Word
; Voice record: touches voice_record[+0x23(r), +0x25(r), +0x3B(r), +0x3D(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFAA87E-0xFAA96B
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; Voice_StageRegs_0840_0880_AB -- stages word 13 (register 0x0840 + chan), word 14 (register 0x0880 + chan) of the 0x0010C000 per-channel
;          staging struct at RAM 0x00D75E, and nothing else in that struct.
;          Write site(s): 0xFAA94D, 0xFAA959, 0xFAA91A, 0xFAA935, 0xFAA961.
;          Argument: the caller pushes XDE, the 68-byte VOICE RECORD at 0x003BCF + 0x44*voice
;          (`ld C,0x44 / mul BC,(XIZ+0x08) / ld <r>,0x3bcf` at the top of every
;          VoiceRegs_Stage_*), immediately before the call.
;          Called from: VoiceRegs_Stage_A, VoiceRegs_Stage_B, sub_FAE013.
;          Evidence: the write addresses above are instruction operands, listed by
;          `python3 notes/prom_c_understanding_round6.py --staging`, which also asserts that
;          this routine writes EXACTLY the register block(s) its name claims and no other.
;          The struct-word -> register-block map is Dev10C_WriteAllChanRegs's own
;          (notes/prom_c_tg_chanmap.py), cross-checked against
;          notes/prom_c_dev10c_field_sources.py by the same section.
;          Unknown: what register 0x0840 / 0x0880 carries.  The name states WHICH register this
;          routine produces, never what the register means.
; --------------------------------------------------------------------------
Voice_StageRegs_0840_0880_AB:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FAA87E  link XIZ,0xfffc
	pushw	hl                                   ; FAA882  push HL
	push	xde                                   ; FAA883  push XDE
	pushw	ix                                   ; FAA884  push IX
	ld	de, (xiz+8)                             ; FAA885  ld DE,(XIZ+0x08)
	extz	xde                                   ; FAA888  extz XDE
	ld	bc, (xde+37)                            ; FAA88A  ld BC,(XDE+0x25)
	extz	xbc                                   ; FAA88D  extz XBC
	ld	wa, (xbc+24)                            ; FAA88F  ld WA,(XBC+0x18)
	and	wa, 0x100                              ; FAA892  and WA,0x0100
	jrl z, Voice_StageRegs_0840_0880_AB__FAA954                  ; FAA896  jrl Z,0xfaa954
	extz	xde                                   ; FAA899  extz XDE
	ld	bc, (xde+61)                            ; FAA89B  ld BC,(XDE+0x3d)
	and	bc, 0xFF                               ; FAA89E  and BC,0x00ff
	jrl z, Voice_StageRegs_0840_0880_AB__FAA954                  ; FAA8A2  jrl Z,0xfaa954
	extz	xde                                   ; FAA8A5  extz XDE
	ld	bc, (xde+37)                            ; FAA8A7  ld BC,(XDE+0x25)
	extz	xbc                                   ; FAA8AA  extz XBC
	ld	wa, (xbc+24)                            ; FAA8AC  ld WA,(XBC+0x18)
	ld	ix, wa                                  ; FAA8AF  ld IX,WA
	and	ix, 0x200                              ; FAA8B1  and IX,0x0200
	ld	bc, (xde+59)                            ; FAA8B5  ld BC,(XDE+0x3b)
	ld	hl, bc                                  ; FAA8B8  ld HL,BC
	and	hl, 0x7F                               ; FAA8BA  and HL,0x007f
	ld	bc, (xde+35)                            ; FAA8BE  ld BC,(XDE+0x23)
	extz	xbc                                   ; FAA8C1  extz XBC
	ld	wa, (xbc+31)                            ; FAA8C3  ld WA,(XBC+0x1f)
	ld	(xiz-2), wa                             ; FAA8C6  ld (XIZ+0xfe),WA
	cps	ix, 0                                  ; FAA8C9  cp IX,0
	jr z, Voice_StageRegs_0840_0880_AB__FAA8E0                   ; FAA8CB  jr Z,0xfaa8e0
	ld	ix, hl                                  ; FAA8CD  ld IX,HL
	sub	ix, wa                                 ; FAA8CF  sub IX,WA
	extz	xde                                   ; FAA8D1  extz XDE
	ld	bc, (xde+61)                            ; FAA8D3  ld BC,(XDE+0x3d)
	ld	hl, bc                                  ; FAA8D6  ld HL,BC
	and	hl, 0x7F                               ; FAA8D8  and HL,0x007f
	sub	hl, wa                                 ; FAA8DC  sub HL,WA
	jr Voice_StageRegs_0840_0880_AB__FAA8F5                      ; FAA8DE  jr T,0xfaa8f5
Voice_StageRegs_0840_0880_AB__FAA8E0:
	ld	ix, hl                                  ; FAA8E0  ld IX,HL
	extpfx3 0x9E, 0xFE, 0x84                   ; FAA8E2  add IX,(XIZ+0xfe)
	extz	xde                                   ; FAA8E5  extz XDE
	ld	bc, (xde+61)                            ; FAA8E7  ld BC,(XDE+0x3d)
	ld	hl, bc                                  ; FAA8EA  ld HL,BC
	and	hl, 0x7F                               ; FAA8EC  and HL,0x007f
	ld	bc, (xiz-2)                             ; FAA8F0  ld BC,(XIZ+0xfe)
	add	hl, bc                                 ; FAA8F3  add HL,BC
Voice_StageRegs_0840_0880_AB__FAA8F5:
	pushw	4                                    ; FAA8F5  push 0x0004
	pushw	0x7F                                 ; FAA8F8  push 0x007f
	pushw	ix                                   ; FAA8FB  push IX
	calr (0xFA7598 - 0xFAA8FF)                 ; FAA8FC  calr 0xfa7598
	ld	ix, wa                                  ; FAA8FF  ld IX,WA
	pushw	0                                    ; FAA901  push 0x0000
	pushw	0x7F                                 ; FAA904  push 0x007f
	pushw	hl                                   ; FAA907  push HL
	calr (0xFA7598 - 0xFAA90B)                 ; FAA908  calr 0xfa7598
	ld	hl, wa                                  ; FAA90B  ld HL,WA
	inc	8, xsp                                 ; FAA90D  inc 0,XSP
	inc	4, xsp                                 ; FAA90F  inc 4,XSP
	cp (xiz+10), 0x00                          ; FAA911  cp (XIZ+0x0a),0x00
	jr z, Voice_StageRegs_0840_0880_AB__FAA921                   ; FAA915  jr Z,0xfaa921
	set	15, wa                                 ; FAA917  set 0x0f,WA
	stw_da	(0xD77A), wa                        ; FAA91A  ld (0x00d77a),WA
	jr Voice_StageRegs_0840_0880_AB__FAA93A                      ; FAA91F  jr T,0xfaa93a
Voice_StageRegs_0840_0880_AB__FAA921:
	extz	xde                                   ; FAA921  extz XDE
	ld	bc, (xde+61)                            ; FAA923  ld BC,(XDE+0x3d)
	and	bc, 0xFF00                             ; FAA926  and BC,0xff00
	ld	(xiz-4), bc                             ; FAA92A  ld (XIZ+0xfc),BC
	ld	wa, hl                                  ; FAA92D  ld WA,HL
	and	wa, 0xFF                               ; FAA92F  and WA,0x00ff
	or	bc, wa                                  ; FAA933  or BC,WA
	stw_da	(0xD77A), bc                        ; FAA935  ld (0x00d77a),BC
Voice_StageRegs_0840_0880_AB__FAA93A:
	extz	xde                                   ; FAA93A  extz XDE
	ld	bc, (xde+59)                            ; FAA93C  ld BC,(XDE+0x3b)
	ld	hl, bc                                  ; FAA93F  ld HL,BC
	and	hl, 0xFF00                             ; FAA941  and HL,0xff00
	ld	bc, ix                                  ; FAA945  ld BC,IX
	and	bc, 0xFF                               ; FAA947  and BC,0x00ff
	or	bc, hl                                  ; FAA94B  or BC,HL
	stw_da	(0xD778), bc                        ; FAA94D  ld (0x00d778),BC
	jr Voice_StageRegs_0840_0880_AB__FAA966                      ; FAA952  jr T,0xfaa966
Voice_StageRegs_0840_0880_AB__FAA954:
	extz	xde                                   ; FAA954  extz XDE
	ld	bc, (xde+59)                            ; FAA956  ld BC,(XDE+0x3b)
	stw_da	(0xD778), bc                        ; FAA959  ld (0x00d778),BC
	ld	bc, (xde+61)                            ; FAA95E  ld BC,(XDE+0x3d)
	stw_da	(0xD77A), bc                        ; FAA961  ld (0x00d77a),BC
Voice_StageRegs_0840_0880_AB__FAA966:
	popw	ix                                    ; FAA966  pop IX
	pop	xde                                    ; FAA967  pop XDE
	popw	hl                                    ; FAA968  pop HL
	unlk32 xiz                                 ; FAA969  unlk XIZ
	ret                                        ; FAA96B  ret
; --------------------------------------------------------------------------
; Voice_StageRegs_0800_CD -- 0xFAA96C..0xFAABFF (660 bytes)
;
; Called from: 4 site(s) outside this module:
;          0xFADE84 in sub_FADE2F__FADE6F, 0xFAE0E1 in sub_FAE0A1__FAE0E0
;          0xFB2843 in VoiceRegs_Stage_C, 0xFB2F18 in VoiceRegs_Stage_D
; Inputs:  frame `link XIZ,-11`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D776
; Calls:   0xFA7598 = Clamp_ToRange_Word, 0xFA75BA = ScaleCoeff_TimesAbsDepth_Shr
; Voice record: touches voice_record[+0x01(rw), +0x0C(r), +0x13(r), +0x17(r), +0x23(r), +0x25(r), +0x39(w), +0x3B(w), +0x3D(w), +0x43(w)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFAA96C-0xFAABFF
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 2, 2026-08-25.  ONE OF THE FOUR ROUTINES THAT BUILD REGISTER
;          `chan + 0x0800`.  It writes staging word 12 (RAM 0x00D776) as
;          `(level << 8) | rate`: the LOW byte is Voice_EnvelopeRate_Table[tone[+0x28]]
;          and the HIGH byte a value clamped to 0..0xFF through
;          Voice_LevelPair_AttackCurve.  The four writers of word 12 are exactly the
;          four routines in prom_c that read Voice_LevelPair_AttackCurve, and the
;          KN5000 sub-CPU's byte-identical Voice_EnvelopeRate_Table is documented
;          there as "indexed by tonerec+40 ... packed as (level << 8) | rate into TG
;          register 0x800".  See the 0x0800..0x0A40 block comment in front of
;          Dev10C_WriteAllChanRegs; census by notes/prom_c_reg_bytepair_check.py.
;          ⚠ This says what ONE of the routine's outputs is, not what the routine is.
; ★ ROUND 6 ------------------------------------------------------------
; Voice_StageRegs_0800_CD -- stages word 12 (register 0x0800 + chan) of the 0x0010C000 per-channel
;          staging struct at RAM 0x00D75E, and nothing else in that struct.
;          Write site(s): 0xFAAA31.
;          Argument: the caller pushes XDE, the 68-byte VOICE RECORD at 0x003BCF + 0x44*voice
;          (`ld C,0x44 / mul BC,(XIZ+0x08) / ld <r>,0x3bcf` at the top of every
;          VoiceRegs_Stage_*), immediately before the call.
;          Called from: VoiceRegs_Stage_C, VoiceRegs_Stage_D, sub_FADE2F, sub_FAE0A1.
;          Evidence: the write addresses above are instruction operands, listed by
;          `python3 notes/prom_c_understanding_round6.py --staging`, which also asserts that
;          this routine writes EXACTLY the register block(s) its name claims and no other.
;          The struct-word -> register-block map is Dev10C_WriteAllChanRegs's own
;          (notes/prom_c_tg_chanmap.py), cross-checked against
;          notes/prom_c_dev10c_field_sources.py by the same section.
;          Unknown: what register 0x0800 carries.  The name states WHICH register this
;          routine produces, never what the register means.
; --------------------------------------------------------------------------
Voice_StageRegs_0800_CD:
	link32 0xEE, 0x0C, 0xF5, 0xFF              ; FAA96C  link XIZ,0xfff5
	push	xhl                                   ; FAA970  push XHL
	pushw	de                                   ; FAA971  push DE
	pushw	ix                                   ; FAA972  push IX
	ld	bc, (xiz+8)                             ; FAA973  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA976  extz XBC
	ld	xwa, (xbc+19)                           ; FAA978  ld XWA,(XBC+0x13)
	ld	(xiz-4), xwa                            ; FAA97B  ld (XIZ+0xfc),XWA
	ld	xiy, (xbc+23)                           ; FAA97E  ld XIY,(XBC+0x17)
	ld	(xiz-8), xiy                            ; FAA981  ld (XIZ+0xf8),XIY
	extpfx5 0x99, 0x01, 0x3E, 0x00, 0x80       ; FAA984  or (XBC+0x01),0x8000
	ld	hl, (xiz+8)                             ; FAA989  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FAA98C  extz XHL
	ld	hl, (xhl+37)                            ; FAA98E  ld HL,(XHL+0x25)
	extz	xhl                                   ; FAA991  extz XHL
	ld	bc, (xhl+26)                            ; FAA993  ld BC,(XHL+0x1a)
	and	bc, 0x400                              ; FAA996  and BC,0x0400
	jr z, Voice_StageRegs_0800_CD__FAA9D9                   ; FAA99A  jr Z,0xfaa9d9
	extz	xhl                                   ; FAA99C  extz XHL
	ld	bc, (xhl+28)                            ; FAA99E  ld BC,(XHL+0x1c)
	ld	ix, bc                                  ; FAA9A1  ld IX,BC
	and	ix, 0x400                              ; FAA9A3  and IX,0x0400
	pushw	0                                    ; FAA9A7  push 0x0000
	pushw	0x64                                 ; FAA9AA  push 0x0064
	ld	xbc, (xiz-8)                            ; FAA9AD  ld XBC,(XIZ+0xf8)
	ld	a, (xbc+9)                              ; FAA9B0  ld A,(XBC+0x09)
	extz	wa                                    ; FAA9B3  extz WA
	ld	de, wa                                  ; FAA9B5  ld DE,WA
	ld	bc, (xiz+8)                             ; FAA9B7  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAA9BA  extz XBC
	ld	iy, (xbc+35)                            ; FAA9BC  ld IY,(XBC+0x23)
	extz	xiy                                   ; FAA9BF  extz XIY
	ld	hl, (xiy+45)                            ; FAA9C1  ld HL,(XIY+0x2d)
	jr z, Voice_StageRegs_0800_CD__FAA9CB                   ; FAA9C4  jr Z,0xfaa9cb
	sub	wa, hl                                 ; FAA9C6  sub WA,HL
	pushw	wa                                   ; FAA9C8  push WA
	jr Voice_StageRegs_0800_CD__FAA9D0                      ; FAA9C9  jr T,0xfaa9d0
Voice_StageRegs_0800_CD__FAA9CB:
	ld	bc, de                                  ; FAA9CB  ld BC,DE
	add	bc, hl                                 ; FAA9CD  add BC,HL
	pushw	bc                                   ; FAA9CF  push BC
Voice_StageRegs_0800_CD__FAA9D0:
	calr (0xFA7598 - 0xFAA9D3)                 ; FAA9D0  calr 0xfa7598
	ld	hl, wa                                  ; FAA9D3  ld HL,WA
	inc	6, xsp                                 ; FAA9D5  inc 6,XSP
	jr Voice_StageRegs_0800_CD__FAA9E3                      ; FAA9D7  jr T,0xfaa9e3
Voice_StageRegs_0800_CD__FAA9D9:
	ld	xbc, (xiz-8)                            ; FAA9D9  ld XBC,(XIZ+0xf8)
	ld	a, (xbc+9)                              ; FAA9DC  ld A,(XBC+0x09)
	extz	wa                                    ; FAA9DF  extz WA
	ld	hl, wa                                  ; FAA9E1  ld HL,WA
Voice_StageRegs_0800_CD__FAA9E3:
	ld	c, l                                    ; FAA9E3  ld C,L
	extz	bc                                    ; FAA9E5  extz BC
	extz	xbc                                   ; FAA9E7  extz XBC
	add	xbc, 0xFDEF74                          ; FAA9E9  add XBC,0x00fdef74
	ld	a, (xbc)                                ; FAA9EF  ld A,(XBC)
	extz	wa                                    ; FAA9F1  extz WA
	ld	hl, wa                                  ; FAA9F3  ld HL,WA
	ld	xbc, (xiz-8)                            ; FAA9F5  ld XBC,(XIZ+0xf8)
	ld	d, (xbc+15)                             ; FAA9F8  ld D,(XBC+0x0f)
	cps	d, 0                                   ; FAA9FB  cp D,0
	jr z, Voice_StageRegs_0800_CD__FAAA26                   ; FAA9FD  jr Z,0xfaaa26
	pushw	4                                    ; FAA9FF  push 0x0004
	ld	bc, (xiz+8)                             ; FAAA02  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAAA05  extz XBC
	ld	a, (xbc+12)                             ; FAAA07  ld A,(XBC+0x0c)
	pushw	wa                                   ; FAAA0A  push WA
	push	0                                     ; FAAA0B  push 0x00
	push	d                                     ; FAAA0D  push D
	calr (0xFA75BA - 0xFAAA12)                 ; FAAA0F  calr 0xfa75ba
	ld	ix, wa                                  ; FAAA12  ld IX,WA
	add	ix, hl                                 ; FAAA14  add IX,HL
	pushw	0                                    ; FAAA16  push 0x0000
	pushw	0xFF                                 ; FAAA19  push 0x00ff
	pushw	ix                                   ; FAAA1C  push IX
	calr (0xFA7598 - 0xFAAA20)                 ; FAAA1D  calr 0xfa7598
	ld	hl, wa                                  ; FAAA20  ld HL,WA
	inc	8, xsp                                 ; FAAA22  inc 0,XSP
	inc	4, xsp                                 ; FAAA24  inc 4,XSP
Voice_StageRegs_0800_CD__FAAA26:
	ld	bc, hl                                  ; FAAA26  ld BC,HL
	sll	bc, 8                                  ; FAAA28  sll 0x08,BC
	ld	de, bc                                  ; FAAA2B  ld DE,BC
	or	de, 0x7F                                ; FAAA2D  or DE,0x007f
	stw_da	(0xD776), de                        ; FAAA31  ld (0x00d776),DE
	ld	bc, (xiz+8)                             ; FAAA36  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAAA39  extz XBC
	ld	(xbc+57), de                            ; FAAA3B  ld (XBC+0x39),DE
	ld	hl, (xiz+8)                             ; FAAA3E  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FAAA41  extz XHL
	ld	hl, (xhl+37)                            ; FAAA43  ld HL,(XHL+0x25)
	extz	xhl                                   ; FAAA46  extz XHL
	ld	bc, (xhl+26)                            ; FAAA48  ld BC,(XHL+0x1a)
	and	bc, 0x800                              ; FAAA4B  and BC,0x0800
	jrl z, Voice_StageRegs_0800_CD__FAAADD                  ; FAAA4F  jrl Z,0xfaaadd
	extz	xhl                                   ; FAAA52  extz XHL
	ld	bc, (xhl+28)                            ; FAAA54  ld BC,(XHL+0x1c)
	ld	ix, bc                                  ; FAAA57  ld IX,BC
	and	ix, 0x800                              ; FAAA59  and IX,0x0800
	pushw	0                                    ; FAAA5D  push 0x0000
	pushw	0x64                                 ; FAAA60  push 0x0064
	ld	xbc, (xiz-8)                            ; FAAA63  ld XBC,(XIZ+0xf8)
	ld	a, (xbc+10)                             ; FAAA66  ld A,(XBC+0x0a)
	extz	wa                                    ; FAAA69  extz WA
	ld	de, wa                                  ; FAAA6B  ld DE,WA
	ld	bc, (xiz+8)                             ; FAAA6D  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAAA70  extz XBC
	ld	iy, (xbc+35)                            ; FAAA72  ld IY,(XBC+0x23)
	extz	xiy                                   ; FAAA75  extz XIY
	ld	hl, (xiy+47)                            ; FAAA77  ld HL,(XIY+0x2f)
	jr z, Voice_StageRegs_0800_CD__FAAAA8                   ; FAAA7A  jr Z,0xfaaaa8
	sub	wa, hl                                 ; FAAA7C  sub WA,HL
	pushw	wa                                   ; FAAA7E  push WA
	calr (0xFA7598 - 0xFAAA82)                 ; FAAA7F  calr 0xfa7598
	ld	hl, wa                                  ; FAAA82  ld HL,WA
	inc	6, xsp                                 ; FAAA84  inc 6,XSP
	pushw	0                                    ; FAAA86  push 0x0000
	pushw	0x64                                 ; FAAA89  push 0x0064
	ld	xbc, (xiz-8)                            ; FAAA8C  ld XBC,(XIZ+0xf8)
	ld	a, (xbc+12)                             ; FAAA8F  ld A,(XBC+0x0c)
	extz	wa                                    ; FAAA92  extz WA
	ld	de, wa                                  ; FAAA94  ld DE,WA
	ld	bc, (xiz+8)                             ; FAAA96  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAAA99  extz XBC
	ld	iy, (xbc+35)                            ; FAAA9B  ld IY,(XBC+0x23)
	extz	xiy                                   ; FAAA9E  extz XIY
	ld	bc, (xiy+47)                            ; FAAAA0  ld BC,(XIY+0x2f)
	sub	wa, bc                                 ; FAAAA3  sub WA,BC
	pushw	wa                                   ; FAAAA5  push WA
	jr Voice_StageRegs_0800_CD__FAAAD4                      ; FAAAA6  jr T,0xfaaad4
Voice_StageRegs_0800_CD__FAAAA8:
	ld	bc, de                                  ; FAAAA8  ld BC,DE
	add	bc, hl                                 ; FAAAAA  add BC,HL
	pushw	bc                                   ; FAAAAC  push BC
	calr (0xFA7598 - 0xFAAAB0)                 ; FAAAAD  calr 0xfa7598
	ld	hl, wa                                  ; FAAAB0  ld HL,WA
	inc	6, xsp                                 ; FAAAB2  inc 6,XSP
	pushw	0                                    ; FAAAB4  push 0x0000
	pushw	0x64                                 ; FAAAB7  push 0x0064
	ld	xbc, (xiz-8)                            ; FAAABA  ld XBC,(XIZ+0xf8)
	ld	a, (xbc+12)                             ; FAAABD  ld A,(XBC+0x0c)
	extz	wa                                    ; FAAAC0  extz WA
	ld	de, wa                                  ; FAAAC2  ld DE,WA
	ld	bc, (xiz+8)                             ; FAAAC4  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAAAC7  extz XBC
	ld	iy, (xbc+35)                            ; FAAAC9  ld IY,(XBC+0x23)
	extz	xiy                                   ; FAAACC  extz XIY
	ld	bc, (xiy+47)                            ; FAAACE  ld BC,(XIY+0x2f)
	add	wa, bc                                 ; FAAAD1  add WA,BC
	pushw	wa                                   ; FAAAD3  push WA
Voice_StageRegs_0800_CD__FAAAD4:
	calr (0xFA7598 - 0xFAAAD7)                 ; FAAAD4  calr 0xfa7598
	ld	de, wa                                  ; FAAAD7  ld DE,WA
	inc	6, xsp                                 ; FAAAD9  inc 6,XSP
	jr Voice_StageRegs_0800_CD__FAAAEE                      ; FAAADB  jr T,0xfaaaee
Voice_StageRegs_0800_CD__FAAADD:
	ld	xbc, (xiz-8)                            ; FAAADD  ld XBC,(XIZ+0xf8)
	ld	a, (xbc+10)                             ; FAAAE0  ld A,(XBC+0x0a)
	extz	wa                                    ; FAAAE3  extz WA
	ld	hl, wa                                  ; FAAAE5  ld HL,WA
	ld	a, (xbc+12)                             ; FAAAE7  ld A,(XBC+0x0c)
	extz	wa                                    ; FAAAEA  extz WA
	ld	de, wa                                  ; FAAAEC  ld DE,WA
Voice_StageRegs_0800_CD__FAAAEE:
	ld	c, l                                    ; FAAAEE  ld C,L
	extz	bc                                    ; FAAAF0  extz BC
	extz	xbc                                   ; FAAAF2  extz XBC
	add	xbc, 0xFDEFD9                          ; FAAAF4  add XBC,0x00fdefd9
	ld	a, (xbc)                                ; FAAAFA  ld A,(XBC)
	extz	wa                                    ; FAAAFC  extz WA
	ld	hl, wa                                  ; FAAAFE  ld HL,WA
	ld	b, e                                    ; FAAB00  ld B,E
	extpfx3 0xC7, 0xF4, 0x9A                   ; FAAB02  ld IYL,B
	extz	iy                                    ; FAAB05  extz IY
	extz	xiy                                   ; FAAB07  extz XIY
	add	xiy, 0xFDEFD9                          ; FAAB09  add XIY,0x00fdefd9
	ld	c, (xiy)                                ; FAAB0F  ld C,(XIY)
	extz	bc                                    ; FAAB11  extz BC
	ld	de, bc                                  ; FAAB13  ld DE,BC
	ld	xiy, (xiz-8)                            ; FAAB15  ld XIY,(XIZ+0xf8)
	ld	c, (xiy+16)                             ; FAAB18  ld C,(XIY+0x10)
	ld	(xiz-9), c                              ; FAAB1B  ld (XIZ+0xf7),C
	cps	c, 0                                   ; FAAB1E  cp C,0
	jr z, Voice_StageRegs_0800_CD__FAAB5C                   ; FAAB20  jr Z,0xfaab5c
	pushw	4                                    ; FAAB22  push 0x0004
	ld	bc, (xiz+8)                             ; FAAB25  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAAB28  extz XBC
	ld	a, (xbc+12)                             ; FAAB2A  ld A,(XBC+0x0c)
	pushw	wa                                   ; FAAB2D  push WA
	push	0                                     ; FAAB2E  push 0x00
	extpfx3 0x8E, 0xF7, 0x04                   ; FAAB30  push (XIZ+0xf7)
	calr (0xFA75BA - 0xFAAB36)                 ; FAAB33  calr 0xfa75ba
	ld	ix, wa                                  ; FAAB36  ld IX,WA
	pushw	0                                    ; FAAB38  push 0x0000
	pushw	0xFF                                 ; FAAB3B  push 0x00ff
	add	wa, hl                                 ; FAAB3E  add WA,HL
	pushw	wa                                   ; FAAB40  push WA
	calr (0xFA7598 - 0xFAAB44)                 ; FAAB41  calr 0xfa7598
	ld	hl, wa                                  ; FAAB44  ld HL,WA
	pushw	0                                    ; FAAB46  push 0x0000
	pushw	0xFF                                 ; FAAB49  push 0x00ff
	ld	bc, de                                  ; FAAB4C  ld BC,DE
	add	bc, ix                                 ; FAAB4E  add BC,IX
	pushw	bc                                   ; FAAB50  push BC
	calr (0xFA7598 - 0xFAAB54)                 ; FAAB51  calr 0xfa7598
	ld	de, wa                                  ; FAAB54  ld DE,WA
	add	xsp, 18                                ; FAAB56  add XSP,0x00000012
Voice_StageRegs_0800_CD__FAAB5C:
	ld	xbc, (xiz-8)                            ; FAAB5C  ld XBC,(XIZ+0xf8)
	ld	a, (xbc+11)                             ; FAAB5F  ld A,(XBC+0x0b)
	extz	wa                                    ; FAAB62  extz WA
	extz	xwa                                   ; FAAB64  extz XWA
	add	xwa, 0xFDF03E                          ; FAAB66  add XWA,0x00fdf03e
	ld	w, (xwa)                                ; FAAB6C  ld W,(XWA)
	extpfx3 0xC7, 0xF0, 0x98                   ; FAAB6E  ld IXL,W
	extz	ix                                    ; FAAB71  extz IX
	cps	ix, 4                                  ; FAAB73  cp IX,4
	jr ge, Voice_StageRegs_0800_CD__FAAB7A                  ; FAAB75  jr GE,0xfaab7a
	ldw	ix, 4                                  ; FAAB77  ld IX,0x0004
Voice_StageRegs_0800_CD__FAAB7A:
	ld	bc, ix                                  ; FAAB7A  ld BC,IX
	and	bc, 0xFF                               ; FAAB7C  and BC,0x00ff
	ld	(xiz-11), bc                            ; FAAB80  ld (XIZ+0xf5),BC
	ld	iy, hl                                  ; FAAB83  ld IY,HL
	sll	iy, 8                                  ; FAAB85  sll 0x08,IY
	or	iy, bc                                  ; FAAB88  or IY,BC
	ld	bc, (xiz+8)                             ; FAAB8A  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAAB8D  extz XBC
	ld	(xbc+59), iy                            ; FAAB8F  ld (XBC+0x3b),IY
	ld	xbc, (xiz-4)                            ; FAAB92  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+13)                             ; FAAB95  ld A,(XBC+0x0d)
	and	a, 32                                  ; FAAB98  and A,0x20
	jr z, Voice_StageRegs_0800_CD__FAABE4                   ; FAAB9B  jr Z,0xfaabe4
	ld	xwa, (xiz-8)                            ; FAAB9D  ld XWA,(XIZ+0xf8)
	ld	c, (xwa+13)                             ; FAABA0  ld C,(XWA+0x0d)
	extz	bc                                    ; FAABA3  extz BC
	extz	xbc                                   ; FAABA5  extz XBC
	add	xbc, 0xFDF03E                          ; FAABA7  add XBC,0x00fdf03e
	ld	b, (xbc)                                ; FAABAD  ld B,(XBC)
	ld	c, b                                    ; FAABAF  ld C,B
	extz	bc                                    ; FAABB1  extz BC
	ld	hl, bc                                  ; FAABB3  ld HL,BC
	and	hl, 0xFF                               ; FAABB5  and HL,0x00ff
	ld	bc, de                                  ; FAABB9  ld BC,DE
	sll	bc, 8                                  ; FAABBB  sll 0x08,BC
	or	bc, hl                                  ; FAABBE  or BC,HL
	ld	wa, (xiz+8)                             ; FAABC0  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FAABC3  extz XWA
	ld	(xwa+61), bc                            ; FAABC5  ld (XWA+0x3d),BC
	ld	xbc, (xiz-8)                            ; FAABC8  ld XBC,(XIZ+0xf8)
	ld	a, (xbc+14)                             ; FAABCB  ld A,(XBC+0x0e)
	extz	wa                                    ; FAABCE  extz WA
	exts	xwa                                   ; FAABD0  exts XWA
	add	xwa, 0xFDEFD9                          ; FAABD2  add XWA,0x00fdefd9
	ld	w, (xwa)                                ; FAABD8  ld W,(XWA)
	ld	bc, (xiz+8)                             ; FAABDA  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAABDD  extz XBC
	ld	(xbc+67), w                             ; FAABDF  ld (XBC+0x43),W
	jr Voice_StageRegs_0800_CD__FAABFA                      ; FAABE2  jr T,0xfaabfa
Voice_StageRegs_0800_CD__FAABE4:
	ld	bc, de                                  ; FAABE4  ld BC,DE
	sll	bc, 8                                  ; FAABE6  sll 0x08,BC
	ld	wa, (xiz+8)                             ; FAABE9  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FAABEC  extz XWA
	ld	(xwa+61), bc                            ; FAABEE  ld (XWA+0x3d),BC
	ld	bc, (xiz+8)                             ; FAABF1  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAABF4  extz XBC
	ld	(xbc+67), 0                             ; FAABF6  ld (XBC+0x43),0x00
Voice_StageRegs_0800_CD__FAABFA:
	popw	ix                                    ; FAABFA  pop IX
	popw	de                                    ; FAABFB  pop DE
	pop	xhl                                    ; FAABFC  pop XHL
	unlk32 xiz                                 ; FAABFD  unlk XIZ
	ret                                        ; FAABFF  ret
; --------------------------------------------------------------------------
; Voice_StageRegs_0840_0880_CD -- 0xFAAC00..0xFAACED (238 bytes)
;
; Called from: 5 site(s) outside this module:
;          0xFADE8C in sub_FADE2F__FADE6F, 0xFAE082 in sub_FAE013__FAE07E
;          0xFAE0E9 in sub_FAE0A1__FAE0E0, 0xFB284B in VoiceRegs_Stage_C
;          0xFB2F20 in VoiceRegs_Stage_D
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: writes 0x00D778, 0x00D77A
; Calls:   0xFA7598 = Clamp_ToRange_Word
; Voice record: touches voice_record[+0x23(r), +0x25(r), +0x3B(r), +0x3D(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFAAC00-0xFAACED
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; Voice_StageRegs_0840_0880_CD -- stages word 13 (register 0x0840 + chan), word 14 (register 0x0880 + chan) of the 0x0010C000 per-channel
;          staging struct at RAM 0x00D75E, and nothing else in that struct.
;          Write site(s): 0xFAACCF, 0xFAACDB, 0xFAAC9C, 0xFAACB7, 0xFAACE3.
;          Argument: the caller pushes XDE, the 68-byte VOICE RECORD at 0x003BCF + 0x44*voice
;          (`ld C,0x44 / mul BC,(XIZ+0x08) / ld <r>,0x3bcf` at the top of every
;          VoiceRegs_Stage_*), immediately before the call.
;          Called from: VoiceRegs_Stage_C, VoiceRegs_Stage_D, sub_FADE2F, sub_FAE013, sub_FAE0A1.
;          Evidence: the write addresses above are instruction operands, listed by
;          `python3 notes/prom_c_understanding_round6.py --staging`, which also asserts that
;          this routine writes EXACTLY the register block(s) its name claims and no other.
;          The struct-word -> register-block map is Dev10C_WriteAllChanRegs's own
;          (notes/prom_c_tg_chanmap.py), cross-checked against
;          notes/prom_c_dev10c_field_sources.py by the same section.
;          Unknown: what register 0x0840 / 0x0880 carries.  The name states WHICH register this
;          routine produces, never what the register means.
; --------------------------------------------------------------------------
Voice_StageRegs_0840_0880_CD:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FAAC00  link XIZ,0xfffc
	pushw	hl                                   ; FAAC04  push HL
	push	xde                                   ; FAAC05  push XDE
	pushw	ix                                   ; FAAC06  push IX
	ld	de, (xiz+8)                             ; FAAC07  ld DE,(XIZ+0x08)
	extz	xde                                   ; FAAC0A  extz XDE
	ld	bc, (xde+37)                            ; FAAC0C  ld BC,(XDE+0x25)
	extz	xbc                                   ; FAAC0F  extz XBC
	ld	wa, (xbc+24)                            ; FAAC11  ld WA,(XBC+0x18)
	and	wa, 0x100                              ; FAAC14  and WA,0x0100
	jrl z, Voice_StageRegs_0840_0880_CD__FAACD6                  ; FAAC18  jrl Z,0xfaacd6
	extz	xde                                   ; FAAC1B  extz XDE
	ld	bc, (xde+61)                            ; FAAC1D  ld BC,(XDE+0x3d)
	and	bc, 0xFF                               ; FAAC20  and BC,0x00ff
	jrl z, Voice_StageRegs_0840_0880_CD__FAACD6                  ; FAAC24  jrl Z,0xfaacd6
	extz	xde                                   ; FAAC27  extz XDE
	ld	bc, (xde+37)                            ; FAAC29  ld BC,(XDE+0x25)
	extz	xbc                                   ; FAAC2C  extz XBC
	ld	wa, (xbc+24)                            ; FAAC2E  ld WA,(XBC+0x18)
	ld	ix, wa                                  ; FAAC31  ld IX,WA
	and	ix, 0x200                              ; FAAC33  and IX,0x0200
	ld	bc, (xde+59)                            ; FAAC37  ld BC,(XDE+0x3b)
	ld	hl, bc                                  ; FAAC3A  ld HL,BC
	and	hl, 0x7F                               ; FAAC3C  and HL,0x007f
	ld	bc, (xde+35)                            ; FAAC40  ld BC,(XDE+0x23)
	extz	xbc                                   ; FAAC43  extz XBC
	ld	wa, (xbc+31)                            ; FAAC45  ld WA,(XBC+0x1f)
	ld	(xiz-2), wa                             ; FAAC48  ld (XIZ+0xfe),WA
	cps	ix, 0                                  ; FAAC4B  cp IX,0
	jr z, Voice_StageRegs_0840_0880_CD__FAAC62                   ; FAAC4D  jr Z,0xfaac62
	ld	ix, hl                                  ; FAAC4F  ld IX,HL
	sub	ix, wa                                 ; FAAC51  sub IX,WA
	extz	xde                                   ; FAAC53  extz XDE
	ld	bc, (xde+61)                            ; FAAC55  ld BC,(XDE+0x3d)
	ld	hl, bc                                  ; FAAC58  ld HL,BC
	and	hl, 0x7F                               ; FAAC5A  and HL,0x007f
	sub	hl, wa                                 ; FAAC5E  sub HL,WA
	jr Voice_StageRegs_0840_0880_CD__FAAC77                      ; FAAC60  jr T,0xfaac77
Voice_StageRegs_0840_0880_CD__FAAC62:
	ld	ix, hl                                  ; FAAC62  ld IX,HL
	extpfx3 0x9E, 0xFE, 0x84                   ; FAAC64  add IX,(XIZ+0xfe)
	extz	xde                                   ; FAAC67  extz XDE
	ld	bc, (xde+61)                            ; FAAC69  ld BC,(XDE+0x3d)
	ld	hl, bc                                  ; FAAC6C  ld HL,BC
	and	hl, 0x7F                               ; FAAC6E  and HL,0x007f
	ld	bc, (xiz-2)                             ; FAAC72  ld BC,(XIZ+0xfe)
	add	hl, bc                                 ; FAAC75  add HL,BC
Voice_StageRegs_0840_0880_CD__FAAC77:
	pushw	4                                    ; FAAC77  push 0x0004
	pushw	0x7F                                 ; FAAC7A  push 0x007f
	pushw	ix                                   ; FAAC7D  push IX
	calr (0xFA7598 - 0xFAAC81)                 ; FAAC7E  calr 0xfa7598
	ld	ix, wa                                  ; FAAC81  ld IX,WA
	pushw	0                                    ; FAAC83  push 0x0000
	pushw	0x7F                                 ; FAAC86  push 0x007f
	pushw	hl                                   ; FAAC89  push HL
	calr (0xFA7598 - 0xFAAC8D)                 ; FAAC8A  calr 0xfa7598
	ld	hl, wa                                  ; FAAC8D  ld HL,WA
	inc	8, xsp                                 ; FAAC8F  inc 0,XSP
	inc	4, xsp                                 ; FAAC91  inc 4,XSP
	cp (xiz+10), 0x00                          ; FAAC93  cp (XIZ+0x0a),0x00
	jr z, Voice_StageRegs_0840_0880_CD__FAACA3                   ; FAAC97  jr Z,0xfaaca3
	set	15, wa                                 ; FAAC99  set 0x0f,WA
	stw_da	(0xD77A), wa                        ; FAAC9C  ld (0x00d77a),WA
	jr Voice_StageRegs_0840_0880_CD__FAACBC                      ; FAACA1  jr T,0xfaacbc
Voice_StageRegs_0840_0880_CD__FAACA3:
	extz	xde                                   ; FAACA3  extz XDE
	ld	bc, (xde+61)                            ; FAACA5  ld BC,(XDE+0x3d)
	and	bc, 0xFF00                             ; FAACA8  and BC,0xff00
	ld	(xiz-4), bc                             ; FAACAC  ld (XIZ+0xfc),BC
	ld	wa, hl                                  ; FAACAF  ld WA,HL
	and	wa, 0xFF                               ; FAACB1  and WA,0x00ff
	or	bc, wa                                  ; FAACB5  or BC,WA
	stw_da	(0xD77A), bc                        ; FAACB7  ld (0x00d77a),BC
Voice_StageRegs_0840_0880_CD__FAACBC:
	extz	xde                                   ; FAACBC  extz XDE
	ld	bc, (xde+59)                            ; FAACBE  ld BC,(XDE+0x3b)
	ld	hl, bc                                  ; FAACC1  ld HL,BC
	and	hl, 0xFF00                             ; FAACC3  and HL,0xff00
	ld	bc, ix                                  ; FAACC7  ld BC,IX
	and	bc, 0xFF                               ; FAACC9  and BC,0x00ff
	or	bc, hl                                  ; FAACCD  or BC,HL
	stw_da	(0xD778), bc                        ; FAACCF  ld (0x00d778),BC
	jr Voice_StageRegs_0840_0880_CD__FAACE8                      ; FAACD4  jr T,0xfaace8
Voice_StageRegs_0840_0880_CD__FAACD6:
	extz	xde                                   ; FAACD6  extz XDE
	ld	bc, (xde+59)                            ; FAACD8  ld BC,(XDE+0x3b)
	stw_da	(0xD778), bc                        ; FAACDB  ld (0x00d778),BC
	ld	bc, (xde+61)                            ; FAACE0  ld BC,(XDE+0x3d)
	stw_da	(0xD77A), bc                        ; FAACE3  ld (0x00d77a),BC
Voice_StageRegs_0840_0880_CD__FAACE8:
	popw	ix                                    ; FAACE8  pop IX
	pop	xde                                    ; FAACE9  pop XDE
	popw	hl                                    ; FAACEA  pop HL
	unlk32 xiz                                 ; FAACEB  unlk XIZ
	ret                                        ; FAACED  ret
; --------------------------------------------------------------------------
; Voice_StageRegs_0800_B_ModeLt3 -- 0xFAACEE..0xFAB0BC (975 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFB1F63 in VoiceRegs_Stage_B
; Inputs:  frame `link XIZ,-11`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D776
;          reads 0xFDEF8E
; Calls:   0xFA7598 = Clamp_ToRange_Word, 0xFA75BA = ScaleCoeff_TimesAbsDepth_Shr
;          0xFA766C = ScaleClampedDelta_Shr5, 0xFC37E2 = SlotRec_ReadSignedByte_000A
; Voice record: touches voice_record[+0x01(rw), +0x08(r), +0x0C(r), +0x13(r), +0x17(r), +0x1F(r), +0x23(r), +0x25(r), +0x39(w), +0x3B(w), +0x3D(w)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFAACEE-0xFAB0BC
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 2, 2026-08-25.  ONE OF THE FOUR ROUTINES THAT BUILD REGISTER
;          `chan + 0x0800`.  It writes staging word 12 (RAM 0x00D776) as
;          `(level << 8) | rate`: the LOW byte is Voice_EnvelopeRate_Table[tone[+0x28]]
;          and the HIGH byte a value clamped to 0..0xFF through
;          Voice_LevelPair_AttackCurve.  The four writers of word 12 are exactly the
;          four routines in prom_c that read Voice_LevelPair_AttackCurve, and the
;          KN5000 sub-CPU's byte-identical Voice_EnvelopeRate_Table is documented
;          there as "indexed by tonerec+40 ... packed as (level << 8) | rate into TG
;          register 0x800".  See the 0x0800..0x0A40 block comment in front of
;          Dev10C_WriteAllChanRegs; census by notes/prom_c_reg_bytepair_check.py.
;          ⚠ This says what ONE of the routine's outputs is, not what the routine is.
; ★ ROUND 6 ------------------------------------------------------------
; Voice_StageRegs_0800_B_ModeLt3 -- stages word 12 (register 0x0800 + chan) of the 0x0010C000 per-channel
;          staging struct at RAM 0x00D75E, and nothing else in that struct.
;          Write site(s): 0xFAAE88.
;          Argument: the caller pushes XDE, the 68-byte VOICE RECORD at 0x003BCF + 0x44*voice
;          (`ld C,0x44 / mul BC,(XIZ+0x08) / ld <r>,0x3bcf` at the top of every
;          VoiceRegs_Stage_*), immediately before the call.
;          Called from: VoiceRegs_Stage_B.
;          Evidence: the write addresses above are instruction operands, listed by
;          `python3 notes/prom_c_understanding_round6.py --staging`, which also asserts that
;          this routine writes EXACTLY the register block(s) its name claims and no other.
;          The struct-word -> register-block map is Dev10C_WriteAllChanRegs's own
;          (notes/prom_c_tg_chanmap.py), cross-checked against
;          notes/prom_c_dev10c_field_sources.py by the same section.
;          Unknown: what register 0x0800 carries.  The name states WHICH register this
;          routine produces, never what the register means.
; --------------------------------------------------------------------------
Voice_StageRegs_0800_B_ModeLt3:
	link32 0xEE, 0x0C, 0xF5, 0xFF              ; FAACEE  link XIZ,0xfff5
	push	xhl                                   ; FAACF2  push XHL
	push	xde                                   ; FAACF3  push XDE
	pushw	ix                                   ; FAACF4  push IX
	ld	bc, (xiz+8)                             ; FAACF5  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAACF8  extz XBC
	ld	xwa, (xbc+23)                           ; FAACFA  ld XWA,(XBC+0x17)
	ld	(xiz-6), xwa                            ; FAACFD  ld (XIZ+0xfa),XWA
	ld	xiy, (xbc+19)                           ; FAAD00  ld XIY,(XBC+0x13)
	ld	c, (xiy+16)                             ; FAAD03  ld C,(XIY+0x10)
	and	c, 16                                  ; FAAD06  and C,0x10
	jr z, Voice_StageRegs_0800_B_ModeLt3__FAAD17                   ; FAAD09  jr Z,0xfaad17
	ld	bc, (xiz+8)                             ; FAAD0B  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAAD0E  extz XBC
	extpfx5 0x99, 0x01, 0x3C, 0xFF, 0x7F       ; FAAD10  and (XBC+0x01),0x7fff
	jr Voice_StageRegs_0800_B_ModeLt3__FAAD21                      ; FAAD15  jr T,0xfaad21
Voice_StageRegs_0800_B_ModeLt3__FAAD17:
	ld	bc, (xiz+8)                             ; FAAD17  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAAD1A  extz XBC
	extpfx5 0x99, 0x01, 0x3E, 0x00, 0x80       ; FAAD1C  or (XBC+0x01),0x8000
Voice_StageRegs_0800_B_ModeLt3__FAAD21:
	ld	bc, (xiz+8)                             ; FAAD21  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAAD24  extz XBC
	ld	wa, (xbc+1)                             ; FAAD26  ld WA,(XBC+0x01)
	and	wa, 0x800                              ; FAAD29  and WA,0x0800
	jr z, Voice_StageRegs_0800_B_ModeLt3__FAAD3B                   ; FAAD2D  jr Z,0xfaad3b
	ldb_da	a, (0xFDEF8E)                       ; FAAD2F  ld A,(0xfdef8e)
	extz	wa                                    ; FAAD34  extz WA
	ld	hl, wa                                  ; FAAD36  ld HL,WA
	jrl Voice_StageRegs_0800_B_ModeLt3__FAAE4C                     ; FAAD38  jrl T,0xfaae4c
Voice_StageRegs_0800_B_ModeLt3__FAAD3B:
	extpfx3 0x9E, 0x08, 0x04                   ; FAAD3B  pushw (XIZ+0x08)
	call	0xFC37E2                              ; FAAD3E  call 0xfc37e2
	ld	ix, wa                                  ; FAAD42  ld IX,WA
	ld	xbc, (xiz-6)                            ; FAAD44  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+39)                             ; FAAD47  ld A,(XBC+0x27)
	extz	wa                                    ; FAAD4A  extz WA
	ld	hl, wa                                  ; FAAD4C  ld HL,WA
	add	wa, ix                                 ; FAAD4E  add WA,IX
	ld	hl, wa                                  ; FAAD50  ld HL,WA
	ld	de, (xiz+8)                             ; FAAD52  ld DE,(XIZ+0x08)
	extz	xde                                   ; FAAD55  extz XDE
	ld	de, (xde+37)                            ; FAAD57  ld DE,(XDE+0x25)
	extz	xde                                   ; FAAD5A  extz XDE
	ld	iy, (xde+26)                            ; FAAD5C  ld IY,(XDE+0x1a)
	and	iy, 0x400                              ; FAAD5F  and IY,0x0400
	inc	2, xsp                                 ; FAAD63  inc 2,XSP
	jr z, Voice_StageRegs_0800_B_ModeLt3__FAAD93                   ; FAAD65  jr Z,0xfaad93
	extz	xde                                   ; FAAD67  extz XDE
	ld	iy, (xde+28)                            ; FAAD69  ld IY,(XDE+0x1c)
	ld	ix, iy                                  ; FAAD6C  ld IX,IY
	and	ix, 0x400                              ; FAAD6E  and IX,0x0400
	pushw	0                                    ; FAAD72  push 0x0000
	pushw	0x64                                 ; FAAD75  push 0x0064
	ld	bc, (xiz+8)                             ; FAAD78  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAAD7B  extz XBC
	ld	iy, (xbc+35)                            ; FAAD7D  ld IY,(XBC+0x23)
	extz	xiy                                   ; FAAD80  extz XIY
	ld	de, (xiy+45)                            ; FAAD82  ld DE,(XIY+0x2d)
	jr z, Voice_StageRegs_0800_B_ModeLt3__FAAD8C                   ; FAAD85  jr Z,0xfaad8c
	sub	wa, de                                 ; FAAD87  sub WA,DE
	pushw	wa                                   ; FAAD89  push WA
	jr Voice_StageRegs_0800_B_ModeLt3__FAAD9A                      ; FAAD8A  jr T,0xfaad9a
Voice_StageRegs_0800_B_ModeLt3__FAAD8C:
	ld	bc, hl                                  ; FAAD8C  ld BC,HL
	add	bc, de                                 ; FAAD8E  add BC,DE
	pushw	bc                                   ; FAAD90  push BC
	jr Voice_StageRegs_0800_B_ModeLt3__FAAD9A                      ; FAAD91  jr T,0xfaad9a
Voice_StageRegs_0800_B_ModeLt3__FAAD93:
	pushw	0                                    ; FAAD93  push 0x0000
	pushw	0x64                                 ; FAAD96  push 0x0064
	pushw	hl                                   ; FAAD99  push HL
Voice_StageRegs_0800_B_ModeLt3__FAAD9A:
	calr (0xFA7598 - 0xFAAD9D)                 ; FAAD9A  calr 0xfa7598
	ld	hl, wa                                  ; FAAD9D  ld HL,WA
	extz	wa                                    ; FAAD9F  extz WA
	extz	xwa                                   ; FAADA1  extz XWA
	add	xwa, 0xFDEF74                          ; FAADA3  add XWA,0x00fdef74
	ld	c, (xwa)                                ; FAADA9  ld C,(XWA)
	extz	bc                                    ; FAADAB  extz BC
	ld	hl, bc                                  ; FAADAD  ld HL,BC
	ld	xwa, (xiz-6)                            ; FAADAF  ld XWA,(XIZ+0xfa)
	ld	d, (xwa+51)                             ; FAADB2  ld D,(XWA+0x33)
	inc	6, xsp                                 ; FAADB5  inc 6,XSP
	cps	d, 0                                   ; FAADB7  cp D,0
	jr z, Voice_StageRegs_0800_B_ModeLt3__FAAE1B                   ; FAADB9  jr Z,0xfaae1b
	push	0                                     ; FAADBB  push 0x00
	push	d                                     ; FAADBD  push D
	ld	c, (xwa+50)                             ; FAADBF  ld C,(XWA+0x32)
	pushw	bc                                   ; FAADC2  push BC
	ld	c, (xwa+49)                             ; FAADC3  ld C,(XWA+0x31)
	pushw	bc                                   ; FAADC6  push BC
	ld	c, (xwa+48)                             ; FAADC7  ld C,(XWA+0x30)
	pushw	bc                                   ; FAADCA  push BC
	ld	bc, (xiz+8)                             ; FAADCB  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAADCE  extz XBC
	ld	iy, (xbc+8)                             ; FAADD0  ld IY,(XBC+0x08)
	pushw	iy                                   ; FAADD3  push IY
	calr (0xFA766C - 0xFAADD7)                 ; FAADD4  calr 0xfa766c
	ld	ix, wa                                  ; FAADD7  ld IX,WA
	ld	xbc, (xiz-6)                            ; FAADD9  ld XBC,(XIZ+0xfa)
	ld	d, (xbc+46)                             ; FAADDC  ld D,(XBC+0x2e)
	inc	8, xsp                                 ; FAADDF  inc 0,XSP
	inc	2, xsp                                 ; FAADE1  inc 2,XSP
	cps	d, 0                                   ; FAADE3  cp D,0
	jr z, Voice_StageRegs_0800_B_ModeLt3__FAAE0E                   ; FAADE5  jr Z,0xfaae0e
	pushw	4                                    ; FAADE7  push 0x0004
	ld	bc, (xiz+8)                             ; FAADEA  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAADED  extz XBC
	ld	a, (xbc+12)                             ; FAADEF  ld A,(XBC+0x0c)
	pushw	wa                                   ; FAADF2  push WA
	push	0                                     ; FAADF3  push 0x00
	push	d                                     ; FAADF5  push D
	calr (0xFA75BA - 0xFAADFA)                 ; FAADF7  calr 0xfa75ba
	ld	(xiz-9), wa                             ; FAADFA  ld (XIZ+0xf7),WA
	inc	6, xsp                                 ; FAADFD  inc 6,XSP
	pushw	0                                    ; FAADFF  push 0x0000
	pushw	0xFF                                 ; FAAE02  push 0x00ff
	ld	bc, hl                                  ; FAAE05  ld BC,HL
	add	bc, ix                                 ; FAAE07  add BC,IX
	add	bc, wa                                 ; FAAE09  add BC,WA
	pushw	bc                                   ; FAAE0B  push BC
	jr Voice_StageRegs_0800_B_ModeLt3__FAAE45                      ; FAAE0C  jr T,0xfaae45
Voice_StageRegs_0800_B_ModeLt3__FAAE0E:
	pushw	0                                    ; FAAE0E  push 0x0000
	pushw	0xFF                                 ; FAAE11  push 0x00ff
	ld	bc, hl                                  ; FAAE14  ld BC,HL
	add	bc, ix                                 ; FAAE16  add BC,IX
	pushw	bc                                   ; FAAE18  push BC
	jr Voice_StageRegs_0800_B_ModeLt3__FAAE45                      ; FAAE19  jr T,0xfaae45
Voice_StageRegs_0800_B_ModeLt3__FAAE1B:
	ld	xbc, (xiz-6)                            ; FAAE1B  ld XBC,(XIZ+0xfa)
	ld	d, (xbc+46)                             ; FAAE1E  ld D,(XBC+0x2e)
	cps	d, 0                                   ; FAAE21  cp D,0
	jr z, Voice_StageRegs_0800_B_ModeLt3__FAAE4C                   ; FAAE23  jr Z,0xfaae4c
	pushw	4                                    ; FAAE25  push 0x0004
	ld	wa, (xiz+8)                             ; FAAE28  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FAAE2B  extz XWA
	ld	c, (xwa+12)                             ; FAAE2D  ld C,(XWA+0x0c)
	pushw	bc                                   ; FAAE30  push BC
	push	0                                     ; FAAE31  push 0x00
	push	d                                     ; FAAE33  push D
	calr (0xFA75BA - 0xFAAE38)                 ; FAAE35  calr 0xfa75ba
	ld	ix, wa                                  ; FAAE38  ld IX,WA
	inc	6, xsp                                 ; FAAE3A  inc 6,XSP
	pushw	0                                    ; FAAE3C  push 0x0000
	pushw	0xFF                                 ; FAAE3F  push 0x00ff
	add	wa, hl                                 ; FAAE42  add WA,HL
	pushw	wa                                   ; FAAE44  push WA
Voice_StageRegs_0800_B_ModeLt3__FAAE45:
	calr (0xFA7598 - 0xFAAE48)                 ; FAAE45  calr 0xfa7598
	ld	hl, wa                                  ; FAAE48  ld HL,WA
	inc	6, xsp                                 ; FAAE4A  inc 6,XSP
Voice_StageRegs_0800_B_ModeLt3__FAAE4C:
	ld	bc, (xiz+8)                             ; FAAE4C  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAAE4F  extz XBC
	ld	xwa, (xbc+31)                           ; FAAE51  ld XWA,(XBC+0x1f)
	ld	c, (xwa)                                ; FAAE54  ld C,(XWA)
	and	c, 1                                   ; FAAE56  and C,0x01
	jr z, Voice_StageRegs_0800_B_ModeLt3__FAAE63                   ; FAAE59  jr Z,0xfaae63
	cp	hl, 0xFF                                ; FAAE5B  cp HL,0x00ff
	jr nz, Voice_StageRegs_0800_B_ModeLt3__FAAE63                  ; FAAE5F  jr NZ,0xfaae63
	dec	1, hl                                  ; FAAE61  dec 1,HL
Voice_StageRegs_0800_B_ModeLt3__FAAE63:
	ld	xbc, (xiz-6)                            ; FAAE63  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+40)                             ; FAAE66  ld A,(XBC+0x28)
	extz	wa                                    ; FAAE69  extz WA
	extz	xwa                                   ; FAAE6B  extz XWA
	add	xwa, 0xFDF03E                          ; FAAE6D  add XWA,0x00fdf03e
	ld	w, (xwa)                                ; FAAE73  ld W,(XWA)
	ld	a, w                                    ; FAAE75  ld A,W
	extz	wa                                    ; FAAE77  extz WA
	ld	de, wa                                  ; FAAE79  ld DE,WA
	and	de, 0xFF                               ; FAAE7B  and DE,0x00ff
	ld	iy, hl                                  ; FAAE7F  ld IY,HL
	sll	iy, 8                                  ; FAAE81  sll 0x08,IY
	ld	ix, iy                                  ; FAAE84  ld IX,IY
	or	ix, de                                  ; FAAE86  or IX,DE
	stw_da	(0xD776), ix                        ; FAAE88  ld (0x00d776),IX
	ld	bc, (xiz+8)                             ; FAAE8D  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAAE90  extz XBC
	ld	(xbc+57), ix                            ; FAAE92  ld (XBC+0x39),IX
	ld	hl, (xiz+8)                             ; FAAE95  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FAAE98  extz XHL
	ld	hl, (xhl+37)                            ; FAAE9A  ld HL,(XHL+0x25)
	extz	xhl                                   ; FAAE9D  extz XHL
	ld	bc, (xhl+26)                            ; FAAE9F  ld BC,(XHL+0x1a)
	and	bc, 0x800                              ; FAAEA2  and BC,0x0800
	jrl z, Voice_StageRegs_0800_B_ModeLt3__FAAF34                  ; FAAEA6  jrl Z,0xfaaf34
	extz	xhl                                   ; FAAEA9  extz XHL
	ld	bc, (xhl+28)                            ; FAAEAB  ld BC,(XHL+0x1c)
	ld	ix, bc                                  ; FAAEAE  ld IX,BC
	and	ix, 0x800                              ; FAAEB0  and IX,0x0800
	pushw	0                                    ; FAAEB4  push 0x0000
	pushw	0x64                                 ; FAAEB7  push 0x0064
	ld	xbc, (xiz-6)                            ; FAAEBA  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+41)                             ; FAAEBD  ld A,(XBC+0x29)
	extz	wa                                    ; FAAEC0  extz WA
	ld	de, wa                                  ; FAAEC2  ld DE,WA
	ld	bc, (xiz+8)                             ; FAAEC4  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAAEC7  extz XBC
	ld	iy, (xbc+35)                            ; FAAEC9  ld IY,(XBC+0x23)
	extz	xiy                                   ; FAAECC  extz XIY
	ld	hl, (xiy+47)                            ; FAAECE  ld HL,(XIY+0x2f)
	jr z, Voice_StageRegs_0800_B_ModeLt3__FAAEFF                   ; FAAED1  jr Z,0xfaaeff
	sub	wa, hl                                 ; FAAED3  sub WA,HL
	pushw	wa                                   ; FAAED5  push WA
	calr (0xFA7598 - 0xFAAED9)                 ; FAAED6  calr 0xfa7598
	ld	hl, wa                                  ; FAAED9  ld HL,WA
	inc	6, xsp                                 ; FAAEDB  inc 6,XSP
	pushw	0                                    ; FAAEDD  push 0x0000
	pushw	0x64                                 ; FAAEE0  push 0x0064
	ld	xbc, (xiz-6)                            ; FAAEE3  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+43)                             ; FAAEE6  ld A,(XBC+0x2b)
	extz	wa                                    ; FAAEE9  extz WA
	ld	de, wa                                  ; FAAEEB  ld DE,WA
	ld	bc, (xiz+8)                             ; FAAEED  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAAEF0  extz XBC
	ld	iy, (xbc+35)                            ; FAAEF2  ld IY,(XBC+0x23)
	extz	xiy                                   ; FAAEF5  extz XIY
	ld	bc, (xiy+47)                            ; FAAEF7  ld BC,(XIY+0x2f)
	sub	wa, bc                                 ; FAAEFA  sub WA,BC
	pushw	wa                                   ; FAAEFC  push WA
	jr Voice_StageRegs_0800_B_ModeLt3__FAAF2B                      ; FAAEFD  jr T,0xfaaf2b
Voice_StageRegs_0800_B_ModeLt3__FAAEFF:
	ld	bc, de                                  ; FAAEFF  ld BC,DE
	add	bc, hl                                 ; FAAF01  add BC,HL
	pushw	bc                                   ; FAAF03  push BC
	calr (0xFA7598 - 0xFAAF07)                 ; FAAF04  calr 0xfa7598
	ld	hl, wa                                  ; FAAF07  ld HL,WA
	inc	6, xsp                                 ; FAAF09  inc 6,XSP
	pushw	0                                    ; FAAF0B  push 0x0000
	pushw	0x64                                 ; FAAF0E  push 0x0064
	ld	xbc, (xiz-6)                            ; FAAF11  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+43)                             ; FAAF14  ld A,(XBC+0x2b)
	extz	wa                                    ; FAAF17  extz WA
	ld	de, wa                                  ; FAAF19  ld DE,WA
	ld	bc, (xiz+8)                             ; FAAF1B  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAAF1E  extz XBC
	ld	iy, (xbc+35)                            ; FAAF20  ld IY,(XBC+0x23)
	extz	xiy                                   ; FAAF23  extz XIY
	ld	bc, (xiy+47)                            ; FAAF25  ld BC,(XIY+0x2f)
	add	wa, bc                                 ; FAAF28  add WA,BC
	pushw	wa                                   ; FAAF2A  push WA
Voice_StageRegs_0800_B_ModeLt3__FAAF2B:
	calr (0xFA7598 - 0xFAAF2E)                 ; FAAF2B  calr 0xfa7598
	ld	de, wa                                  ; FAAF2E  ld DE,WA
	inc	6, xsp                                 ; FAAF30  inc 6,XSP
	jr Voice_StageRegs_0800_B_ModeLt3__FAAF45                      ; FAAF32  jr T,0xfaaf45
Voice_StageRegs_0800_B_ModeLt3__FAAF34:
	ld	xbc, (xiz-6)                            ; FAAF34  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+41)                             ; FAAF37  ld A,(XBC+0x29)
	extz	wa                                    ; FAAF3A  extz WA
	ld	hl, wa                                  ; FAAF3C  ld HL,WA
	ld	a, (xbc+43)                             ; FAAF3E  ld A,(XBC+0x2b)
	extz	wa                                    ; FAAF41  extz WA
	ld	de, wa                                  ; FAAF43  ld DE,WA
Voice_StageRegs_0800_B_ModeLt3__FAAF45:
	ld	c, l                                    ; FAAF45  ld C,L
	extz	bc                                    ; FAAF47  extz BC
	extz	xbc                                   ; FAAF49  extz XBC
	add	xbc, 0xFDEFD9                          ; FAAF4B  add XBC,0x00fdefd9
	ld	a, (xbc)                                ; FAAF51  ld A,(XBC)
	extz	wa                                    ; FAAF53  extz WA
	ld	hl, wa                                  ; FAAF55  ld HL,WA
	ld	b, e                                    ; FAAF57  ld B,E
	extpfx3 0xC7, 0xF4, 0x9A                   ; FAAF59  ld IYL,B
	extz	iy                                    ; FAAF5C  extz IY
	extz	xiy                                   ; FAAF5E  extz XIY
	add	xiy, 0xFDEFD9                          ; FAAF60  add XIY,0x00fdefd9
	ld	c, (xiy)                                ; FAAF66  ld C,(XIY)
	extz	bc                                    ; FAAF68  extz BC
	ld	de, bc                                  ; FAAF6A  ld DE,BC
	ld	xiy, (xiz-6)                            ; FAAF6C  ld XIY,(XIZ+0xfa)
	ld	c, (xiy+52)                             ; FAAF6F  ld C,(XIY+0x34)
	ld	(xiz-7), c                              ; FAAF72  ld (XIZ+0xf9),C
	cps	c, 0                                   ; FAAF75  cp C,0
	jrl z, Voice_StageRegs_0800_B_ModeLt3__FAB00B                  ; FAAF77  jrl Z,0xfab00b
	pushw	bc                                   ; FAAF7A  push BC
	ld	b, (xiy+50)                             ; FAAF7B  ld B,(XIY+0x32)
	push	0                                     ; FAAF7E  push 0x00
	push	b                                     ; FAAF80  push B
	ld	b, (xiy+49)                             ; FAAF82  ld B,(XIY+0x31)
	push	0                                     ; FAAF85  push 0x00
	push	b                                     ; FAAF87  push B
	ld	b, (xiy+48)                             ; FAAF89  ld B,(XIY+0x30)
	push	0                                     ; FAAF8C  push 0x00
	push	b                                     ; FAAF8E  push B
	ld	bc, (xiz+8)                             ; FAAF90  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAAF93  extz XBC
	ld	wa, (xbc+8)                             ; FAAF95  ld WA,(XBC+0x08)
	pushw	wa                                   ; FAAF98  push WA
	calr (0xFA766C - 0xFAAF9C)                 ; FAAF99  calr 0xfa766c
	ld	ix, wa                                  ; FAAF9C  ld IX,WA
	ld	xbc, (xiz-6)                            ; FAAF9E  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+47)                             ; FAAFA1  ld A,(XBC+0x2f)
	ld	(xiz-1), a                              ; FAAFA4  ld (XIZ+0xff),A
	inc	8, xsp                                 ; FAAFA7  inc 0,XSP
	inc	2, xsp                                 ; FAAFA9  inc 2,XSP
	cps	a, 0                                   ; FAAFAB  cp A,0
	jr z, Voice_StageRegs_0800_B_ModeLt3__FAAFEC                   ; FAAFAD  jr Z,0xfaafec
	pushw	4                                    ; FAAFAF  push 0x0004
	ld	wa, (xiz+8)                             ; FAAFB2  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FAAFB5  extz XWA
	ld	c, (xwa+12)                             ; FAAFB7  ld C,(XWA+0x0c)
	pushw	bc                                   ; FAAFBA  push BC
	push	0                                     ; FAAFBB  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FAAFBD  push (XIZ+0xff)
	calr (0xFA75BA - 0xFAAFC3)                 ; FAAFC0  calr 0xfa75ba
	ld	(xiz-9), wa                             ; FAAFC3  ld (XIZ+0xf7),WA
	pushw	0                                    ; FAAFC6  push 0x0000
	pushw	0xFF                                 ; FAAFC9  push 0x00ff
	ld	bc, hl                                  ; FAAFCC  ld BC,HL
	add	bc, ix                                 ; FAAFCE  add BC,IX
	add	bc, wa                                 ; FAAFD0  add BC,WA
	pushw	bc                                   ; FAAFD2  push BC
	calr (0xFA7598 - 0xFAAFD6)                 ; FAAFD3  calr 0xfa7598
	ld	hl, wa                                  ; FAAFD6  ld HL,WA
	inc	8, xsp                                 ; FAAFD8  inc 0,XSP
	inc	4, xsp                                 ; FAAFDA  inc 4,XSP
	pushw	0                                    ; FAAFDC  push 0x0000
	pushw	0xFF                                 ; FAAFDF  push 0x00ff
	ld	bc, de                                  ; FAAFE2  ld BC,DE
	add	bc, ix                                 ; FAAFE4  add BC,IX
	extpfx3 0x9E, 0xF7, 0x81                   ; FAAFE6  add BC,(XIZ+0xf7)
	pushw	bc                                   ; FAAFE9  push BC
	jr Voice_StageRegs_0800_B_ModeLt3__FAB04B                      ; FAAFEA  jr T,0xfab04b
Voice_StageRegs_0800_B_ModeLt3__FAAFEC:
	pushw	0                                    ; FAAFEC  push 0x0000
	pushw	0xFF                                 ; FAAFEF  push 0x00ff
	ld	bc, hl                                  ; FAAFF2  ld BC,HL
	add	bc, ix                                 ; FAAFF4  add BC,IX
	pushw	bc                                   ; FAAFF6  push BC
	calr (0xFA7598 - 0xFAAFFA)                 ; FAAFF7  calr 0xfa7598
	ld	hl, wa                                  ; FAAFFA  ld HL,WA
	inc	6, xsp                                 ; FAAFFC  inc 6,XSP
	pushw	0                                    ; FAAFFE  push 0x0000
	pushw	0xFF                                 ; FAB001  push 0x00ff
	ld	bc, de                                  ; FAB004  ld BC,DE
	add	bc, ix                                 ; FAB006  add BC,IX
	pushw	bc                                   ; FAB008  push BC
	jr Voice_StageRegs_0800_B_ModeLt3__FAB04B                      ; FAB009  jr T,0xfab04b
Voice_StageRegs_0800_B_ModeLt3__FAB00B:
	ld	xbc, (xiz-6)                            ; FAB00B  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+47)                             ; FAB00E  ld A,(XBC+0x2f)
	ld	(xiz-2), a                              ; FAB011  ld (XIZ+0xfe),A
	cps	a, 0                                   ; FAB014  cp A,0
	jr z, Voice_StageRegs_0800_B_ModeLt3__FAB052                   ; FAB016  jr Z,0xfab052
	pushw	4                                    ; FAB018  push 0x0004
	ld	wa, (xiz+8)                             ; FAB01B  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FAB01E  extz XWA
	ld	c, (xwa+12)                             ; FAB020  ld C,(XWA+0x0c)
	pushw	bc                                   ; FAB023  push BC
	push	0                                     ; FAB024  push 0x00
	extpfx3 0x8E, 0xFE, 0x04                   ; FAB026  push (XIZ+0xfe)
	calr (0xFA75BA - 0xFAB02C)                 ; FAB029  calr 0xfa75ba
	ld	ix, wa                                  ; FAB02C  ld IX,WA
	pushw	0                                    ; FAB02E  push 0x0000
	pushw	0xFF                                 ; FAB031  push 0x00ff
	add	wa, hl                                 ; FAB034  add WA,HL
	pushw	wa                                   ; FAB036  push WA
	calr (0xFA7598 - 0xFAB03A)                 ; FAB037  calr 0xfa7598
	ld	hl, wa                                  ; FAB03A  ld HL,WA
	inc	8, xsp                                 ; FAB03C  inc 0,XSP
	inc	4, xsp                                 ; FAB03E  inc 4,XSP
	pushw	0                                    ; FAB040  push 0x0000
	pushw	0xFF                                 ; FAB043  push 0x00ff
	ld	bc, de                                  ; FAB046  ld BC,DE
	add	bc, ix                                 ; FAB048  add BC,IX
	pushw	bc                                   ; FAB04A  push BC
Voice_StageRegs_0800_B_ModeLt3__FAB04B:
	calr (0xFA7598 - 0xFAB04E)                 ; FAB04B  calr 0xfa7598
	ld	de, wa                                  ; FAB04E  ld DE,WA
	inc	6, xsp                                 ; FAB050  inc 6,XSP
Voice_StageRegs_0800_B_ModeLt3__FAB052:
	ld	xbc, (xiz-6)                            ; FAB052  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+42)                             ; FAB055  ld A,(XBC+0x2a)
	extz	wa                                    ; FAB058  extz WA
	extz	xwa                                   ; FAB05A  extz XWA
	add	xwa, 0xFDF03E                          ; FAB05C  add XWA,0x00fdf03e
	ld	w, (xwa)                                ; FAB062  ld W,(XWA)
	extpfx3 0xC7, 0xF0, 0x98                   ; FAB064  ld IXL,W
	extz	ix                                    ; FAB067  extz IX
	cps	ix, 4                                  ; FAB069  cp IX,4
	jr ge, Voice_StageRegs_0800_B_ModeLt3__FAB070                  ; FAB06B  jr GE,0xfab070
	ldw	ix, 4                                  ; FAB06D  ld IX,0x0004
Voice_StageRegs_0800_B_ModeLt3__FAB070:
	ld	xbc, (xiz-6)                            ; FAB070  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+44)                             ; FAB073  ld A,(XBC+0x2c)
	extz	wa                                    ; FAB076  extz WA
	extz	xwa                                   ; FAB078  extz XWA
	add	xwa, 0xFDF03E                          ; FAB07A  add XWA,0x00fdf03e
	ld	w, (xwa)                                ; FAB080  ld W,(XWA)
	ld	a, w                                    ; FAB082  ld A,W
	extz	wa                                    ; FAB084  extz WA
	ld	(xiz-9), wa                             ; FAB086  ld (XIZ+0xf7),WA
	ld	iy, ix                                  ; FAB089  ld IY,IX
	and	iy, 0xFF                               ; FAB08B  and IY,0x00ff
	ld	(xiz-11), iy                            ; FAB08F  ld (XIZ+0xf5),IY
	ld	bc, hl                                  ; FAB092  ld BC,HL
	sll	bc, 8                                  ; FAB094  sll 0x08,BC
	or	bc, iy                                  ; FAB097  or BC,IY
	ld	wa, (xiz+8)                             ; FAB099  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FAB09C  extz XWA
	ld	(xwa+59), bc                            ; FAB09E  ld (XWA+0x3b),BC
	ld	hl, (xiz-9)                             ; FAB0A1  ld HL,(XIZ+0xf7)
	and	hl, 0xFF                               ; FAB0A4  and HL,0x00ff
	ld	bc, de                                  ; FAB0A8  ld BC,DE
	sll	bc, 8                                  ; FAB0AA  sll 0x08,BC
	or	bc, hl                                  ; FAB0AD  or BC,HL
	ld	wa, (xiz+8)                             ; FAB0AF  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FAB0B2  extz XWA
	ld	(xwa+61), bc                            ; FAB0B4  ld (XWA+0x3d),BC
	popw	ix                                    ; FAB0B7  pop IX
	pop	xde                                    ; FAB0B8  pop XDE
	pop	xhl                                    ; FAB0B9  pop XHL
	unlk32 xiz                                 ; FAB0BA  unlk XIZ
	ret                                        ; FAB0BC  ret
; --------------------------------------------------------------------------
; Voice_StageRegs_0800_B_ModeGe3 -- 0xFAB0BD..0xFAB489 (973 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFB1F7B in VoiceRegs_Stage_B__FB1F7B
; Inputs:  frame `link XIZ,-15`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D776
; Calls:   0xFA7598 = Clamp_ToRange_Word, 0xFA75BA = ScaleCoeff_TimesAbsDepth_Shr
;          0xFA766C = ScaleClampedDelta_Shr5, 0xFC37BE = SlotRec_ReadSignedByte_0009
; Evidence: the listing below is the byte-identical round-trip of 0xFAB0BD-0xFAB489
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 2, 2026-08-25.  ONE OF THE FOUR ROUTINES THAT BUILD REGISTER
;          `chan + 0x0800`.  It writes staging word 12 (RAM 0x00D776) as
;          `(level << 8) | rate`: the LOW byte is Voice_EnvelopeRate_Table[tone[+0x28]]
;          and the HIGH byte a value clamped to 0..0xFF through
;          Voice_LevelPair_AttackCurve.  The four writers of word 12 are exactly the
;          four routines in prom_c that read Voice_LevelPair_AttackCurve, and the
;          KN5000 sub-CPU's byte-identical Voice_EnvelopeRate_Table is documented
;          there as "indexed by tonerec+40 ... packed as (level << 8) | rate into TG
;          register 0x800".  See the 0x0800..0x0A40 block comment in front of
;          Dev10C_WriteAllChanRegs; census by notes/prom_c_reg_bytepair_check.py.
;          ⚠ This says what ONE of the routine's outputs is, not what the routine is.
; ★ ROUND 6 ------------------------------------------------------------
; Voice_StageRegs_0800_B_ModeGe3 -- stages word 12 (register 0x0800 + chan) of the 0x0010C000 per-channel
;          staging struct at RAM 0x00D75E, and nothing else in that struct.
;          Write site(s): 0xFAB236.
;          Argument: the caller pushes XDE, the 68-byte VOICE RECORD at 0x003BCF + 0x44*voice
;          (`ld C,0x44 / mul BC,(XIZ+0x08) / ld <r>,0x3bcf` at the top of every
;          VoiceRegs_Stage_*), immediately before the call.
;          Called from: VoiceRegs_Stage_B.
;          Evidence: the write addresses above are instruction operands, listed by
;          `python3 notes/prom_c_understanding_round6.py --staging`, which also asserts that
;          this routine writes EXACTLY the register block(s) its name claims and no other.
;          The struct-word -> register-block map is Dev10C_WriteAllChanRegs's own
;          (notes/prom_c_tg_chanmap.py), cross-checked against
;          notes/prom_c_dev10c_field_sources.py by the same section.
;          Unknown: what register 0x0800 carries.  The name states WHICH register this
;          routine produces, never what the register means.
; --------------------------------------------------------------------------
Voice_StageRegs_0800_B_ModeGe3:
	link32 0xEE, 0x0C, 0xF1, 0xFF              ; FAB0BD  link XIZ,0xfff1
	push	xhl                                   ; FAB0C1  push XHL
	pushw	de                                   ; FAB0C2  push DE
	push	xix                                   ; FAB0C3  push XIX
	ld	bc, (xiz+8)                             ; FAB0C4  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAB0C7  extz XBC
	ld	xwa, (xbc+23)                           ; FAB0C9  ld XWA,(XBC+0x17)
	ld	(xiz-6), xwa                            ; FAB0CC  ld (XIZ+0xfa),XWA
	ld	xiy, (xbc+19)                           ; FAB0CF  ld XIY,(XBC+0x13)
	ld	c, (xiy+16)                             ; FAB0D2  ld C,(XIY+0x10)
	and	c, 16                                  ; FAB0D5  and C,0x10
	jr z, Voice_StageRegs_0800_B_ModeGe3__FAB0E6                   ; FAB0D8  jr Z,0xfab0e6
	ld	bc, (xiz+8)                             ; FAB0DA  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAB0DD  extz XBC
	extpfx5 0x99, 0x01, 0x3C, 0xFF, 0x7F       ; FAB0DF  and (XBC+0x01),0x7fff
	jr Voice_StageRegs_0800_B_ModeGe3__FAB0F0                      ; FAB0E4  jr T,0xfab0f0
Voice_StageRegs_0800_B_ModeGe3__FAB0E6:
	ld	bc, (xiz+8)                             ; FAB0E6  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAB0E9  extz XBC
	extpfx5 0x99, 0x01, 0x3E, 0x00, 0x80       ; FAB0EB  or (XBC+0x01),0x8000
Voice_StageRegs_0800_B_ModeGe3__FAB0F0:
	ld	hl, (xiz+8)                             ; FAB0F0  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FAB0F3  extz XHL
	ld	hl, (xhl+37)                            ; FAB0F5  ld HL,(XHL+0x25)
	extz	xhl                                   ; FAB0F8  extz XHL
	ld	bc, (xhl+26)                            ; FAB0FA  ld BC,(XHL+0x1a)
	and	bc, 0x400                              ; FAB0FD  and BC,0x0400
	jr z, Voice_StageRegs_0800_B_ModeGe3__FAB140                   ; FAB101  jr Z,0xfab140
	extz	xhl                                   ; FAB103  extz XHL
	ld	bc, (xhl+28)                            ; FAB105  ld BC,(XHL+0x1c)
	ld	ix, bc                                  ; FAB108  ld IX,BC
	and	ix, 0x400                              ; FAB10A  and IX,0x0400
	pushw	0                                    ; FAB10E  push 0x0000
	pushw	0x64                                 ; FAB111  push 0x0064
	ld	xbc, (xiz-6)                            ; FAB114  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+39)                             ; FAB117  ld A,(XBC+0x27)
	extz	wa                                    ; FAB11A  extz WA
	ld	de, wa                                  ; FAB11C  ld DE,WA
	ld	bc, (xiz+8)                             ; FAB11E  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAB121  extz XBC
	ld	iy, (xbc+35)                            ; FAB123  ld IY,(XBC+0x23)
	extz	xiy                                   ; FAB126  extz XIY
	ld	hl, (xiy+45)                            ; FAB128  ld HL,(XIY+0x2d)
	jr z, Voice_StageRegs_0800_B_ModeGe3__FAB132                   ; FAB12B  jr Z,0xfab132
	sub	wa, hl                                 ; FAB12D  sub WA,HL
	pushw	wa                                   ; FAB12F  push WA
	jr Voice_StageRegs_0800_B_ModeGe3__FAB137                      ; FAB130  jr T,0xfab137
Voice_StageRegs_0800_B_ModeGe3__FAB132:
	ld	bc, de                                  ; FAB132  ld BC,DE
	add	bc, hl                                 ; FAB134  add BC,HL
	pushw	bc                                   ; FAB136  push BC
Voice_StageRegs_0800_B_ModeGe3__FAB137:
	calr (0xFA7598 - 0xFAB13A)                 ; FAB137  calr 0xfa7598
	ld	hl, wa                                  ; FAB13A  ld HL,WA
	inc	6, xsp                                 ; FAB13C  inc 6,XSP
	jr Voice_StageRegs_0800_B_ModeGe3__FAB14A                      ; FAB13E  jr T,0xfab14a
Voice_StageRegs_0800_B_ModeGe3__FAB140:
	ld	xbc, (xiz-6)                            ; FAB140  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+39)                             ; FAB143  ld A,(XBC+0x27)
	extz	wa                                    ; FAB146  extz WA
	ld	hl, wa                                  ; FAB148  ld HL,WA
Voice_StageRegs_0800_B_ModeGe3__FAB14A:
	ld	c, l                                    ; FAB14A  ld C,L
	extz	bc                                    ; FAB14C  extz BC
	extz	xbc                                   ; FAB14E  extz XBC
	add	xbc, 0xFDEF74                          ; FAB150  add XBC,0x00fdef74
	ld	a, (xbc)                                ; FAB156  ld A,(XBC)
	extz	wa                                    ; FAB158  extz WA
	ld	hl, wa                                  ; FAB15A  ld HL,WA
	ld	xbc, (xiz-6)                            ; FAB15C  ld XBC,(XIZ+0xfa)
	ld	d, (xbc+51)                             ; FAB15F  ld D,(XBC+0x33)
	cps	d, 0                                   ; FAB162  cp D,0
	jr z, Voice_StageRegs_0800_B_ModeGe3__FAB1C6                   ; FAB164  jr Z,0xfab1c6
	push	0                                     ; FAB166  push 0x00
	push	d                                     ; FAB168  push D
	ld	a, (xbc+50)                             ; FAB16A  ld A,(XBC+0x32)
	pushw	wa                                   ; FAB16D  push WA
	ld	a, (xbc+49)                             ; FAB16E  ld A,(XBC+0x31)
	pushw	wa                                   ; FAB171  push WA
	ld	a, (xbc+48)                             ; FAB172  ld A,(XBC+0x30)
	pushw	wa                                   ; FAB175  push WA
	ld	wa, (xiz+8)                             ; FAB176  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FAB179  extz XWA
	ld	iy, (xwa+8)                             ; FAB17B  ld IY,(XWA+0x08)
	pushw	iy                                   ; FAB17E  push IY
	calr (0xFA766C - 0xFAB182)                 ; FAB17F  calr 0xfa766c
	ld	ix, wa                                  ; FAB182  ld IX,WA
	ld	xbc, (xiz-6)                            ; FAB184  ld XBC,(XIZ+0xfa)
	ld	d, (xbc+46)                             ; FAB187  ld D,(XBC+0x2e)
	inc	8, xsp                                 ; FAB18A  inc 0,XSP
	inc	2, xsp                                 ; FAB18C  inc 2,XSP
	cps	d, 0                                   ; FAB18E  cp D,0
	jr z, Voice_StageRegs_0800_B_ModeGe3__FAB1B9                   ; FAB190  jr Z,0xfab1b9
	pushw	4                                    ; FAB192  push 0x0004
	ld	bc, (xiz+8)                             ; FAB195  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAB198  extz XBC
	ld	a, (xbc+12)                             ; FAB19A  ld A,(XBC+0x0c)
	pushw	wa                                   ; FAB19D  push WA
	push	0                                     ; FAB19E  push 0x00
	push	d                                     ; FAB1A0  push D
	calr (0xFA75BA - 0xFAB1A5)                 ; FAB1A2  calr 0xfa75ba
	ld	(xiz-9), wa                             ; FAB1A5  ld (XIZ+0xf7),WA
	inc	6, xsp                                 ; FAB1A8  inc 6,XSP
	pushw	0                                    ; FAB1AA  push 0x0000
	pushw	0xFF                                 ; FAB1AD  push 0x00ff
	ld	bc, hl                                  ; FAB1B0  ld BC,HL
	add	bc, ix                                 ; FAB1B2  add BC,IX
	add	bc, wa                                 ; FAB1B4  add BC,WA
	pushw	bc                                   ; FAB1B6  push BC
	jr Voice_StageRegs_0800_B_ModeGe3__FAB1F0                      ; FAB1B7  jr T,0xfab1f0
Voice_StageRegs_0800_B_ModeGe3__FAB1B9:
	pushw	0                                    ; FAB1B9  push 0x0000
	pushw	0xFF                                 ; FAB1BC  push 0x00ff
	ld	bc, hl                                  ; FAB1BF  ld BC,HL
	add	bc, ix                                 ; FAB1C1  add BC,IX
	pushw	bc                                   ; FAB1C3  push BC
	jr Voice_StageRegs_0800_B_ModeGe3__FAB1F0                      ; FAB1C4  jr T,0xfab1f0
Voice_StageRegs_0800_B_ModeGe3__FAB1C6:
	ld	xbc, (xiz-6)                            ; FAB1C6  ld XBC,(XIZ+0xfa)
	ld	d, (xbc+46)                             ; FAB1C9  ld D,(XBC+0x2e)
	cps	d, 0                                   ; FAB1CC  cp D,0
	jr z, Voice_StageRegs_0800_B_ModeGe3__FAB1F7                   ; FAB1CE  jr Z,0xfab1f7
	pushw	4                                    ; FAB1D0  push 0x0004
	ld	wa, (xiz+8)                             ; FAB1D3  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FAB1D6  extz XWA
	ld	c, (xwa+12)                             ; FAB1D8  ld C,(XWA+0x0c)
	pushw	bc                                   ; FAB1DB  push BC
	push	0                                     ; FAB1DC  push 0x00
	push	d                                     ; FAB1DE  push D
	calr (0xFA75BA - 0xFAB1E3)                 ; FAB1E0  calr 0xfa75ba
	ld	ix, wa                                  ; FAB1E3  ld IX,WA
	inc	6, xsp                                 ; FAB1E5  inc 6,XSP
	pushw	0                                    ; FAB1E7  push 0x0000
	pushw	0xFF                                 ; FAB1EA  push 0x00ff
	add	wa, hl                                 ; FAB1ED  add WA,HL
	pushw	wa                                   ; FAB1EF  push WA
Voice_StageRegs_0800_B_ModeGe3__FAB1F0:
	calr (0xFA7598 - 0xFAB1F3)                 ; FAB1F0  calr 0xfa7598
	ld	hl, wa                                  ; FAB1F3  ld HL,WA
	inc	6, xsp                                 ; FAB1F5  inc 6,XSP
Voice_StageRegs_0800_B_ModeGe3__FAB1F7:
	ld	bc, (xiz+8)                             ; FAB1F7  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAB1FA  extz XBC
	ld	xwa, (xbc+31)                           ; FAB1FC  ld XWA,(XBC+0x1f)
	ld	c, (xwa)                                ; FAB1FF  ld C,(XWA)
	and	c, 1                                   ; FAB201  and C,0x01
	jr z, Voice_StageRegs_0800_B_ModeGe3__FAB20E                   ; FAB204  jr Z,0xfab20e
	cp	hl, 0xFF                                ; FAB206  cp HL,0x00ff
	jr nz, Voice_StageRegs_0800_B_ModeGe3__FAB20E                  ; FAB20A  jr NZ,0xfab20e
	dec	1, hl                                  ; FAB20C  dec 1,HL
Voice_StageRegs_0800_B_ModeGe3__FAB20E:
	ld	xbc, (xiz-6)                            ; FAB20E  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+40)                             ; FAB211  ld A,(XBC+0x28)
	extz	wa                                    ; FAB214  extz WA
	extz	xwa                                   ; FAB216  extz XWA
	add	xwa, 0xFDF03E                          ; FAB218  add XWA,0x00fdf03e
	ld	w, (xwa)                                ; FAB21E  ld W,(XWA)
	ld	a, w                                    ; FAB220  ld A,W
	extz	wa                                    ; FAB222  extz WA
	and	wa, 0xFF                               ; FAB224  and WA,0x00ff
	ld	(xiz-9), wa                             ; FAB228  ld (XIZ+0xf7),WA
	ld	iy, hl                                  ; FAB22B  ld IY,HL
	sll	iy, 8                                  ; FAB22D  sll 0x08,IY
	extpfx3 0x9E, 0xF7, 0xE5                   ; FAB230  or IY,(XIZ+0xf7)
	ld	(xiz-11), iy                            ; FAB233  ld (XIZ+0xf5),IY
	stw_da	(0xD776), iy                        ; FAB236  ld (0x00d776),IY
	ld	bc, (xiz+8)                             ; FAB23B  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAB23E  extz XBC
	ld	wa, (xiz-11)                            ; FAB240  ld WA,(XIZ+0xf5)
	ld	(xbc+57), wa                            ; FAB243  ld (XBC+0x39),WA
	pushw	0                                    ; FAB246  push 0x0000
	pushw	0x64                                 ; FAB249  push 0x0064
	extpfx3 0x9E, 0x08, 0x04                   ; FAB24C  pushw (XIZ+0x08)
	call	0xFC37BE                              ; FAB24F  call 0xfc37be
	ld	(xiz-13), wa                            ; FAB253  ld (XIZ+0xf3),WA
	ld	xbc, (xiz-6)                            ; FAB256  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+41)                             ; FAB259  ld A,(XBC+0x29)
	extz	wa                                    ; FAB25C  extz WA
	extpfx3 0x9E, 0xF3, 0x80                   ; FAB25E  add WA,(XIZ+0xf3)
	popw	iy                                    ; FAB261  pop IY
	pushw	wa                                   ; FAB262  push WA
	calr (0xFA7598 - 0xFAB266)                 ; FAB263  calr 0xfa7598
	ld	hl, wa                                  ; FAB266  ld HL,WA
	inc	6, xsp                                 ; FAB268  inc 6,XSP
	pushw	0                                    ; FAB26A  push 0x0000
	pushw	0x64                                 ; FAB26D  push 0x0064
	extpfx3 0x9E, 0x08, 0x04                   ; FAB270  pushw (XIZ+0x08)
	call	0xFC37BE                              ; FAB273  call 0xfc37be
	ld	(xiz-15), wa                            ; FAB277  ld (XIZ+0xf1),WA
	ld	xbc, (xiz-6)                            ; FAB27A  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+43)                             ; FAB27D  ld A,(XBC+0x2b)
	extz	wa                                    ; FAB280  extz WA
	extpfx3 0x9E, 0xF1, 0x80                   ; FAB282  add WA,(XIZ+0xf1)
	popw	iy                                    ; FAB285  pop IY
	pushw	wa                                   ; FAB286  push WA
	calr (0xFA7598 - 0xFAB28A)                 ; FAB287  calr 0xfa7598
	ld	de, wa                                  ; FAB28A  ld DE,WA
	ld	ix, (xiz+8)                             ; FAB28C  ld IX,(XIZ+0x08)
	extz	xix                                   ; FAB28F  extz XIX
	ld	ix, (xix+37)                            ; FAB291  ld IX,(XIX+0x25)
	extz	xix                                   ; FAB294  extz XIX
	ld	bc, (xix+26)                            ; FAB296  ld BC,(XIX+0x1a)
	and	bc, 0x800                              ; FAB299  and BC,0x0800
	inc	6, xsp                                 ; FAB29D  inc 6,XSP
	jrl z, Voice_StageRegs_0800_B_ModeGe3__FAB312                  ; FAB29F  jrl Z,0xfab312
	extz	xix                                   ; FAB2A2  extz XIX
	ld	bc, (xix+28)                            ; FAB2A4  ld BC,(XIX+0x1c)
	and	bc, 0x800                              ; FAB2A7  and BC,0x0800
	ld	(xiz-9), bc                             ; FAB2AB  ld (XIZ+0xf7),BC
	pushw	0                                    ; FAB2AE  push 0x0000
	pushw	0x64                                 ; FAB2B1  push 0x0064
	ld	bc, (xiz+8)                             ; FAB2B4  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAB2B7  extz XBC
	ld	iy, (xbc+35)                            ; FAB2B9  ld IY,(XBC+0x23)
	extz	xiy                                   ; FAB2BC  extz XIY
	ld	ix, (xiy+47)                            ; FAB2BE  ld IX,(XIY+0x2f)
	jr z, Voice_StageRegs_0800_B_ModeGe3__FAB2E9                   ; FAB2C1  jr Z,0xfab2e9
	ld	iy, hl                                  ; FAB2C3  ld IY,HL
	sub	iy, ix                                 ; FAB2C5  sub IY,IX
	pushw	iy                                   ; FAB2C7  push IY
	calr (0xFA7598 - 0xFAB2CB)                 ; FAB2C8  calr 0xfa7598
	ld	hl, wa                                  ; FAB2CB  ld HL,WA
	inc	6, xsp                                 ; FAB2CD  inc 6,XSP
	pushw	0                                    ; FAB2CF  push 0x0000
	pushw	0x64                                 ; FAB2D2  push 0x0064
	ld	bc, (xiz+8)                             ; FAB2D5  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAB2D8  extz XBC
	ld	iy, (xbc+35)                            ; FAB2DA  ld IY,(XBC+0x23)
	extz	xiy                                   ; FAB2DD  extz XIY
	ld	bc, (xiy+47)                            ; FAB2DF  ld BC,(XIY+0x2f)
	ld	iy, de                                  ; FAB2E2  ld IY,DE
	sub	iy, bc                                 ; FAB2E4  sub IY,BC
	pushw	iy                                   ; FAB2E6  push IY
	jr Voice_StageRegs_0800_B_ModeGe3__FAB30B                      ; FAB2E7  jr T,0xfab30b
Voice_StageRegs_0800_B_ModeGe3__FAB2E9:
	ld	bc, hl                                  ; FAB2E9  ld BC,HL
	add	bc, ix                                 ; FAB2EB  add BC,IX
	pushw	bc                                   ; FAB2ED  push BC
	calr (0xFA7598 - 0xFAB2F1)                 ; FAB2EE  calr 0xfa7598
	ld	hl, wa                                  ; FAB2F1  ld HL,WA
	inc	6, xsp                                 ; FAB2F3  inc 6,XSP
	pushw	0                                    ; FAB2F5  push 0x0000
	pushw	0x64                                 ; FAB2F8  push 0x0064
	ld	bc, (xiz+8)                             ; FAB2FB  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAB2FE  extz XBC
	ld	iy, (xbc+35)                            ; FAB300  ld IY,(XBC+0x23)
	extz	xiy                                   ; FAB303  extz XIY
	ld	bc, (xiy+47)                            ; FAB305  ld BC,(XIY+0x2f)
	add	bc, de                                 ; FAB308  add BC,DE
	pushw	bc                                   ; FAB30A  push BC
Voice_StageRegs_0800_B_ModeGe3__FAB30B:
	calr (0xFA7598 - 0xFAB30E)                 ; FAB30B  calr 0xfa7598
	ld	de, wa                                  ; FAB30E  ld DE,WA
	inc	6, xsp                                 ; FAB310  inc 6,XSP
Voice_StageRegs_0800_B_ModeGe3__FAB312:
	ld	c, l                                    ; FAB312  ld C,L
	extz	bc                                    ; FAB314  extz BC
	extz	xbc                                   ; FAB316  extz XBC
	add	xbc, 0xFDEFD9                          ; FAB318  add XBC,0x00fdefd9
	ld	a, (xbc)                                ; FAB31E  ld A,(XBC)
	extz	wa                                    ; FAB320  extz WA
	ld	hl, wa                                  ; FAB322  ld HL,WA
	ld	b, e                                    ; FAB324  ld B,E
	extpfx3 0xC7, 0xF4, 0x9A                   ; FAB326  ld IYL,B
	extz	iy                                    ; FAB329  extz IY
	extz	xiy                                   ; FAB32B  extz XIY
	add	xiy, 0xFDEFD9                          ; FAB32D  add XIY,0x00fdefd9
	ld	c, (xiy)                                ; FAB333  ld C,(XIY)
	extz	bc                                    ; FAB335  extz BC
	ld	de, bc                                  ; FAB337  ld DE,BC
	ld	xiy, (xiz-6)                            ; FAB339  ld XIY,(XIZ+0xfa)
	ld	c, (xiy+52)                             ; FAB33C  ld C,(XIY+0x34)
	ld	(xiz-7), c                              ; FAB33F  ld (XIZ+0xf9),C
	cps	c, 0                                   ; FAB342  cp C,0
	jrl z, Voice_StageRegs_0800_B_ModeGe3__FAB3D8                  ; FAB344  jrl Z,0xfab3d8
	pushw	bc                                   ; FAB347  push BC
	ld	b, (xiy+50)                             ; FAB348  ld B,(XIY+0x32)
	push	0                                     ; FAB34B  push 0x00
	push	b                                     ; FAB34D  push B
	ld	b, (xiy+49)                             ; FAB34F  ld B,(XIY+0x31)
	push	0                                     ; FAB352  push 0x00
	push	b                                     ; FAB354  push B
	ld	b, (xiy+48)                             ; FAB356  ld B,(XIY+0x30)
	push	0                                     ; FAB359  push 0x00
	push	b                                     ; FAB35B  push B
	ld	bc, (xiz+8)                             ; FAB35D  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAB360  extz XBC
	ld	wa, (xbc+8)                             ; FAB362  ld WA,(XBC+0x08)
	pushw	wa                                   ; FAB365  push WA
	calr (0xFA766C - 0xFAB369)                 ; FAB366  calr 0xfa766c
	ld	ix, wa                                  ; FAB369  ld IX,WA
	ld	xbc, (xiz-6)                            ; FAB36B  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+47)                             ; FAB36E  ld A,(XBC+0x2f)
	ld	(xiz-1), a                              ; FAB371  ld (XIZ+0xff),A
	inc	8, xsp                                 ; FAB374  inc 0,XSP
	inc	2, xsp                                 ; FAB376  inc 2,XSP
	cps	a, 0                                   ; FAB378  cp A,0
	jr z, Voice_StageRegs_0800_B_ModeGe3__FAB3B9                   ; FAB37A  jr Z,0xfab3b9
	pushw	4                                    ; FAB37C  push 0x0004
	ld	wa, (xiz+8)                             ; FAB37F  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FAB382  extz XWA
	ld	c, (xwa+12)                             ; FAB384  ld C,(XWA+0x0c)
	pushw	bc                                   ; FAB387  push BC
	push	0                                     ; FAB388  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FAB38A  push (XIZ+0xff)
	calr (0xFA75BA - 0xFAB390)                 ; FAB38D  calr 0xfa75ba
	ld	(xiz-9), wa                             ; FAB390  ld (XIZ+0xf7),WA
	pushw	0                                    ; FAB393  push 0x0000
	pushw	0xFF                                 ; FAB396  push 0x00ff
	ld	bc, hl                                  ; FAB399  ld BC,HL
	add	bc, ix                                 ; FAB39B  add BC,IX
	add	bc, wa                                 ; FAB39D  add BC,WA
	pushw	bc                                   ; FAB39F  push BC
	calr (0xFA7598 - 0xFAB3A3)                 ; FAB3A0  calr 0xfa7598
	ld	hl, wa                                  ; FAB3A3  ld HL,WA
	inc	8, xsp                                 ; FAB3A5  inc 0,XSP
	inc	4, xsp                                 ; FAB3A7  inc 4,XSP
	pushw	0                                    ; FAB3A9  push 0x0000
	pushw	0xFF                                 ; FAB3AC  push 0x00ff
	ld	bc, de                                  ; FAB3AF  ld BC,DE
	add	bc, ix                                 ; FAB3B1  add BC,IX
	extpfx3 0x9E, 0xF7, 0x81                   ; FAB3B3  add BC,(XIZ+0xf7)
	pushw	bc                                   ; FAB3B6  push BC
	jr Voice_StageRegs_0800_B_ModeGe3__FAB418                      ; FAB3B7  jr T,0xfab418
Voice_StageRegs_0800_B_ModeGe3__FAB3B9:
	pushw	0                                    ; FAB3B9  push 0x0000
	pushw	0xFF                                 ; FAB3BC  push 0x00ff
	ld	bc, hl                                  ; FAB3BF  ld BC,HL
	add	bc, ix                                 ; FAB3C1  add BC,IX
	pushw	bc                                   ; FAB3C3  push BC
	calr (0xFA7598 - 0xFAB3C7)                 ; FAB3C4  calr 0xfa7598
	ld	hl, wa                                  ; FAB3C7  ld HL,WA
	inc	6, xsp                                 ; FAB3C9  inc 6,XSP
	pushw	0                                    ; FAB3CB  push 0x0000
	pushw	0xFF                                 ; FAB3CE  push 0x00ff
	ld	bc, de                                  ; FAB3D1  ld BC,DE
	add	bc, ix                                 ; FAB3D3  add BC,IX
	pushw	bc                                   ; FAB3D5  push BC
	jr Voice_StageRegs_0800_B_ModeGe3__FAB418                      ; FAB3D6  jr T,0xfab418
Voice_StageRegs_0800_B_ModeGe3__FAB3D8:
	ld	xbc, (xiz-6)                            ; FAB3D8  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+47)                             ; FAB3DB  ld A,(XBC+0x2f)
	ld	(xiz-2), a                              ; FAB3DE  ld (XIZ+0xfe),A
	cps	a, 0                                   ; FAB3E1  cp A,0
	jr z, Voice_StageRegs_0800_B_ModeGe3__FAB41F                   ; FAB3E3  jr Z,0xfab41f
	pushw	4                                    ; FAB3E5  push 0x0004
	ld	wa, (xiz+8)                             ; FAB3E8  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FAB3EB  extz XWA
	ld	c, (xwa+12)                             ; FAB3ED  ld C,(XWA+0x0c)
	pushw	bc                                   ; FAB3F0  push BC
	push	0                                     ; FAB3F1  push 0x00
	extpfx3 0x8E, 0xFE, 0x04                   ; FAB3F3  push (XIZ+0xfe)
	calr (0xFA75BA - 0xFAB3F9)                 ; FAB3F6  calr 0xfa75ba
	ld	ix, wa                                  ; FAB3F9  ld IX,WA
	pushw	0                                    ; FAB3FB  push 0x0000
	pushw	0xFF                                 ; FAB3FE  push 0x00ff
	add	wa, hl                                 ; FAB401  add WA,HL
	pushw	wa                                   ; FAB403  push WA
	calr (0xFA7598 - 0xFAB407)                 ; FAB404  calr 0xfa7598
	ld	hl, wa                                  ; FAB407  ld HL,WA
	inc	8, xsp                                 ; FAB409  inc 0,XSP
	inc	4, xsp                                 ; FAB40B  inc 4,XSP
	pushw	0                                    ; FAB40D  push 0x0000
	pushw	0xFF                                 ; FAB410  push 0x00ff
	ld	bc, de                                  ; FAB413  ld BC,DE
	add	bc, ix                                 ; FAB415  add BC,IX
	pushw	bc                                   ; FAB417  push BC
Voice_StageRegs_0800_B_ModeGe3__FAB418:
	calr (0xFA7598 - 0xFAB41B)                 ; FAB418  calr 0xfa7598
	ld	de, wa                                  ; FAB41B  ld DE,WA
	inc	6, xsp                                 ; FAB41D  inc 6,XSP
Voice_StageRegs_0800_B_ModeGe3__FAB41F:
	ld	xbc, (xiz-6)                            ; FAB41F  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+42)                             ; FAB422  ld A,(XBC+0x2a)
	extz	wa                                    ; FAB425  extz WA
	extz	xwa                                   ; FAB427  extz XWA
	add	xwa, 0xFDF03E                          ; FAB429  add XWA,0x00fdf03e
	ld	w, (xwa)                                ; FAB42F  ld W,(XWA)
	extpfx3 0xC7, 0xF0, 0x98                   ; FAB431  ld IXL,W
	extz	ix                                    ; FAB434  extz IX
	cps	ix, 4                                  ; FAB436  cp IX,4
	jr ge, Voice_StageRegs_0800_B_ModeGe3__FAB43D                  ; FAB438  jr GE,0xfab43d
	ldw	ix, 4                                  ; FAB43A  ld IX,0x0004
Voice_StageRegs_0800_B_ModeGe3__FAB43D:
	ld	xbc, (xiz-6)                            ; FAB43D  ld XBC,(XIZ+0xfa)
	ld	a, (xbc+44)                             ; FAB440  ld A,(XBC+0x2c)
	extz	wa                                    ; FAB443  extz WA
	extz	xwa                                   ; FAB445  extz XWA
	add	xwa, 0xFDF03E                          ; FAB447  add XWA,0x00fdf03e
	ld	w, (xwa)                                ; FAB44D  ld W,(XWA)
	ld	a, w                                    ; FAB44F  ld A,W
	extz	wa                                    ; FAB451  extz WA
	ld	(xiz-9), wa                             ; FAB453  ld (XIZ+0xf7),WA
	ld	iy, ix                                  ; FAB456  ld IY,IX
	and	iy, 0xFF                               ; FAB458  and IY,0x00ff
	ld	(xiz-11), iy                            ; FAB45C  ld (XIZ+0xf5),IY
	ld	bc, hl                                  ; FAB45F  ld BC,HL
	sll	bc, 8                                  ; FAB461  sll 0x08,BC
	or	bc, iy                                  ; FAB464  or BC,IY
	ld	wa, (xiz+8)                             ; FAB466  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FAB469  extz XWA
	ld	(xwa+59), bc                            ; FAB46B  ld (XWA+0x3b),BC
	ld	hl, (xiz-9)                             ; FAB46E  ld HL,(XIZ+0xf7)
	and	hl, 0xFF                               ; FAB471  and HL,0x00ff
	ld	bc, de                                  ; FAB475  ld BC,DE
	sll	bc, 8                                  ; FAB477  sll 0x08,BC
	or	bc, hl                                  ; FAB47A  or BC,HL
	ld	wa, (xiz+8)                             ; FAB47C  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FAB47F  extz XWA
	ld	(xwa+61), bc                            ; FAB481  ld (XWA+0x3d),BC
	pop	xix                                    ; FAB484  pop XIX
	popw	de                                    ; FAB485  pop DE
	pop	xhl                                    ; FAB486  pop XHL
	unlk32 xiz                                 ; FAB487  unlk XIZ
	ret                                        ; FAB489  ret
; --------------------------------------------------------------------------
; sub_FAB48A -- 0xFAB48A..0xFAB516 (141 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAB68D
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Voice record: touches voice_record[+0x08(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFAB48A-0xFAB516
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAB48A:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FAB48A  link XIZ,0xfffc
	pushw	hl                                   ; FAB48E  push HL
	pushw	de                                   ; FAB48F  push DE
	push	xix                                   ; FAB490  push XIX
	ld	xix, (xiz+10)                           ; FAB491  ld XIX,(XIZ+0x0a)
	ld	bc, (xiz+8)                             ; FAB494  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAB497  extz XBC
	ld	hl, (xbc+8)                             ; FAB499  ld HL,(XBC+0x08)
	and	hl, 0x7F00                             ; FAB49C  and HL,0x7f00
	ld	iy, hl                                  ; FAB4A0  ld IY,HL
	sra	iy, 8                                  ; FAB4A2  sra 0x08,IY
	ld	hl, iy                                  ; FAB4A5  ld HL,IY
	ld	a, (xix+30)                             ; FAB4A7  ld A,(XIX+0x1e)
	extz	wa                                    ; FAB4AA  extz WA
	cp	iy, wa                                  ; FAB4AC  cp IY,WA
	jr ge, sub_FAB48A__FAB4D7                  ; FAB4AE  jr GE,0xfab4d7
	ld	a, (xix+31)                             ; FAB4B0  ld A,(XIX+0x1f)
	extz	wa                                    ; FAB4B3  extz WA
	ld	de, wa                                  ; FAB4B5  ld DE,WA
	cp	iy, wa                                  ; FAB4B7  cp IY,WA
	jr lt, sub_FAB48A__FAB4EB                  ; FAB4B9  jr LT,0xfab4eb
	ld	c, (xix+30)                             ; FAB4BB  ld C,(XIX+0x1e)
	extz	bc                                    ; FAB4BE  extz BC
	ld	(xiz-2), bc                             ; FAB4C0  ld (XIZ+0xfe),BC
	sub	bc, wa                                 ; FAB4C3  sub BC,WA
	ld	(xiz-4), bc                             ; FAB4C5  ld (XIZ+0xfc),BC
	ld	wa, (xiz-2)                             ; FAB4C8  ld WA,(XIZ+0xfe)
	sub	wa, iy                                 ; FAB4CB  sub WA,IY
	muls	wa, 0xFFC0                            ; FAB4CD  muls WA,0xffc0
	exts	xwa                                   ; FAB4D1  exts XWA
	divs	xwa, xbc                              ; FAB4D3  divs XWA,BC
	jr sub_FAB48A__FAB511                      ; FAB4D5  jr T,0xfab511
sub_FAB48A__FAB4D7:
	ld	c, (xix+32)                             ; FAB4D7  ld C,(XIX+0x20)
	extz	bc                                    ; FAB4DA  extz BC
	cp	hl, bc                                  ; FAB4DC  cp HL,BC
	jr le, sub_FAB48A__FAB50F                  ; FAB4DE  jr LE,0xfab50f
	ld	c, (xix+33)                             ; FAB4E0  ld C,(XIX+0x21)
	extz	bc                                    ; FAB4E3  extz BC
	ld	de, bc                                  ; FAB4E5  ld DE,BC
	cp	hl, bc                                  ; FAB4E7  cp HL,BC
	jr le, sub_FAB48A__FAB4F0                  ; FAB4E9  jr LE,0xfab4f0
sub_FAB48A__FAB4EB:
	ldw	wa, 0xFE00                             ; FAB4EB  ld WA,0xfe00
	jr sub_FAB48A__FAB511                      ; FAB4EE  jr T,0xfab511
sub_FAB48A__FAB4F0:
	ld	c, (xix+32)                             ; FAB4F0  ld C,(XIX+0x20)
	extz	bc                                    ; FAB4F3  extz BC
	ld	(xiz-2), bc                             ; FAB4F5  ld (XIZ+0xfe),BC
	ld	wa, de                                  ; FAB4F8  ld WA,DE
	sub	wa, bc                                 ; FAB4FA  sub WA,BC
	ld	(xiz-4), wa                             ; FAB4FC  ld (XIZ+0xfc),WA
	ld	iy, hl                                  ; FAB4FF  ld IY,HL
	sub	iy, bc                                 ; FAB501  sub IY,BC
	muls	iy, 0xFFC0                            ; FAB503  muls IY,0xffc0
	exts	xiy                                   ; FAB507  exts XIY
	divs	xiy, xwa                              ; FAB509  divs XIY,WA
	ld	wa, iy                                  ; FAB50B  ld WA,IY
	jr sub_FAB48A__FAB511                      ; FAB50D  jr T,0xfab511
sub_FAB48A__FAB50F:
	sub	wa, wa                                 ; FAB50F  sub WA,WA
sub_FAB48A__FAB511:
	pop	xix                                    ; FAB511  pop XIX
	popw	de                                    ; FAB512  pop DE
	popw	hl                                    ; FAB513  pop HL
	unlk32 xiz                                 ; FAB514  unlk XIZ
	ret                                        ; FAB516  ret
; --------------------------------------------------------------------------
; sub_FAB517 -- 0xFAB517..0xFAB5A4 (142 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAB698
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Voice record: touches voice_record[+0x0C(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFAB517-0xFAB5A4
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAB517:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FAB517  link XIZ,0xfffc
	pushw	hl                                   ; FAB51B  push HL
	pushw	de                                   ; FAB51C  push DE
	push	xix                                   ; FAB51D  push XIX
	ld	xix, (xiz+10)                           ; FAB51E  ld XIX,(XIZ+0x0a)
	ld	bc, (xiz+8)                             ; FAB521  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FAB524  extz XBC
	ld	a, (xbc+12)                             ; FAB526  ld A,(XBC+0x0c)
	extz	wa                                    ; FAB529  extz WA
	ld	hl, wa                                  ; FAB52B  ld HL,WA
	and	wa, 0x7F                               ; FAB52D  and WA,0x007f
	ld	hl, wa                                  ; FAB531  ld HL,WA
	ld	c, (xix+34)                             ; FAB533  ld C,(XIX+0x22)
	extz	bc                                    ; FAB536  extz BC
	cp	wa, bc                                  ; FAB538  cp WA,BC
	jr ge, sub_FAB517__FAB565                  ; FAB53A  jr GE,0xfab565
	ld	c, (xix+35)                             ; FAB53C  ld C,(XIX+0x23)
	extz	bc                                    ; FAB53F  extz BC
	ld	de, bc                                  ; FAB541  ld DE,BC
	cp	wa, bc                                  ; FAB543  cp WA,BC
	jr lt, sub_FAB517__FAB579                  ; FAB545  jr LT,0xfab579
	ld	c, (xix+34)                             ; FAB547  ld C,(XIX+0x22)
	extz	bc                                    ; FAB54A  extz BC
	ld	(xiz-2), bc                             ; FAB54C  ld (XIZ+0xfe),BC
	sub	bc, de                                 ; FAB54F  sub BC,DE
	ld	(xiz-4), bc                             ; FAB551  ld (XIZ+0xfc),BC
	ld	iy, (xiz-2)                             ; FAB554  ld IY,(XIZ+0xfe)
	sub	iy, wa                                 ; FAB557  sub IY,WA
	muls	iy, 0xFFC0                            ; FAB559  muls IY,0xffc0
	exts	xiy                                   ; FAB55D  exts XIY
	divs	xiy, xbc                              ; FAB55F  divs XIY,BC
	ld	wa, iy                                  ; FAB561  ld WA,IY
	jr sub_FAB517__FAB59F                      ; FAB563  jr T,0xfab59f
sub_FAB517__FAB565:
	ld	c, (xix+36)                             ; FAB565  ld C,(XIX+0x24)
	extz	bc                                    ; FAB568  extz BC
	cp	hl, bc                                  ; FAB56A  cp HL,BC
	jr le, sub_FAB517__FAB59D                  ; FAB56C  jr LE,0xfab59d
	ld	c, (xix+37)                             ; FAB56E  ld C,(XIX+0x25)
	extz	bc                                    ; FAB571  extz BC
	ld	de, bc                                  ; FAB573  ld DE,BC
	cp	hl, bc                                  ; FAB575  cp HL,BC
	jr le, sub_FAB517__FAB57E                  ; FAB577  jr LE,0xfab57e
sub_FAB517__FAB579:
	ldw	wa, 0xFE00                             ; FAB579  ld WA,0xfe00
	jr sub_FAB517__FAB59F                      ; FAB57C  jr T,0xfab59f
sub_FAB517__FAB57E:
	ld	c, (xix+36)                             ; FAB57E  ld C,(XIX+0x24)
	extz	bc                                    ; FAB581  extz BC
	ld	(xiz-2), bc                             ; FAB583  ld (XIZ+0xfe),BC
	ld	wa, de                                  ; FAB586  ld WA,DE
	sub	wa, bc                                 ; FAB588  sub WA,BC
	ld	(xiz-4), wa                             ; FAB58A  ld (XIZ+0xfc),WA
	ld	iy, hl                                  ; FAB58D  ld IY,HL
	sub	iy, bc                                 ; FAB58F  sub IY,BC
	muls	iy, 0xFFC0                            ; FAB591  muls IY,0xffc0
	exts	xiy                                   ; FAB595  exts XIY
	divs	xiy, xwa                              ; FAB597  divs XIY,WA
	ld	wa, iy                                  ; FAB599  ld WA,IY
	jr sub_FAB517__FAB59F                      ; FAB59B  jr T,0xfab59f
sub_FAB517__FAB59D:
	sub	wa, wa                                 ; FAB59D  sub WA,WA
sub_FAB517__FAB59F:
	pop	xix                                    ; FAB59F  pop XIX
	popw	de                                    ; FAB5A0  pop DE
	popw	hl                                    ; FAB5A1  pop HL
	unlk32 xiz                                 ; FAB5A2  unlk XIZ
	ret                                        ; FAB5A4  ret
; --------------------------------------------------------------------------
; sub_FAB5A5 -- 0xFAB5A5..0xFAB6D4 (304 bytes)
;
; Called from: 3 site(s) outside this module:
;          0xFB0B76 in VoiceRegs_Stage_A, 0xFB1F70 in VoiceRegs_Stage_B
;          0xFB1F88 in VoiceRegs_Stage_B__FB1F7B
; Inputs:  frame `link XIZ,-14`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
;          reads 0x005A51, 0x00D7F1
; Calls:   0xFA7CC9 = sub_FA7CC9, 0xFA7D03 = ScaleClampedDelta_Shr5_b
;          0xFAB48A = sub_FAB48A, 0xFAB517 = sub_FAB517
;          0xFC578C = sub_FC578C
; Voice record: touches voice_record[+0x01(rw), +0x08(r), +0x0C(r), +0x0D(w), +0x0F(r), +0x17(r), +0x23(r), +0x27(r), +0x2F(w)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFAB5A5-0xFAB6D4
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAB5A5:
	link32 0xEE, 0x0C, 0xF2, 0xFF              ; FAB5A5  link XIZ,0xfff2
	pushw	hl                                   ; FAB5A9  push HL
	push	xde                                   ; FAB5AA  push XDE
	push	xix                                   ; FAB5AB  push XIX
	ld	de, (xiz+8)                             ; FAB5AC  ld DE,(XIZ+0x08)
	extz	xde                                   ; FAB5AF  extz XDE
	ld	xbc, (xde+23)                           ; FAB5B1  ld XBC,(XDE+0x17)
	ld	xix, xbc                                ; FAB5B4  ld XIX,XBC
	ld	a, (xde+12)                             ; FAB5B6  ld A,(XDE+0x0c)
	extz	wa                                    ; FAB5B9  extz WA
	ld	hl, wa                                  ; FAB5BB  ld HL,WA
	and	wa, 0x80                               ; FAB5BD  and WA,0x0080
	jr z, sub_FAB5A5__FAB5CA                   ; FAB5C1  jr Z,0xfab5ca
	extz	xde                                   ; FAB5C3  extz XDE
	extpfx5 0x9A, 0x01, 0x3E, 0x00, 0x08       ; FAB5C5  or (XDE+0x01),0x0800
sub_FAB5A5__FAB5CA:
	and	hl, 0x7F                               ; FAB5CA  and HL,0x007f
	ld	c, (xix+24)                             ; FAB5CE  ld C,(XIX+0x18)
	cps	c, 0                                   ; FAB5D1  cp C,0
	jr ge, sub_FAB5A5__FAB607                  ; FAB5D3  jr GE,0xfab607
	ld	bc, hl                                  ; FAB5D5  ld BC,HL
	extz	xbc                                   ; FAB5D7  extz XBC
	add	xbc, 0xFDD5AB                          ; FAB5D9  add XBC,0x00fdd5ab
	ld	a, (xbc)                                ; FAB5DF  ld A,(XBC)
	extz	wa                                    ; FAB5E1  extz WA
	ld	(xiz-2), wa                             ; FAB5E3  ld (XIZ+0xfe),WA
	ld	b, (xix+25)                             ; FAB5E6  ld B,(XIX+0x19)
	push	0                                     ; FAB5E9  push 0x00
	push	b                                     ; FAB5EB  push B
	pushw	wa                                   ; FAB5ED  push WA
	calr (0xFA7CC9 - 0xFAB5F1)                 ; FAB5EE  calr 0xfa7cc9
	sub	wa, 0xD0                               ; FAB5F1  sub WA,0x00d0
	ld	(xiz-4), wa                             ; FAB5F5  ld (XIZ+0xfc),WA
	ld	c, (xix+24)                             ; FAB5F8  ld C,(XIX+0x18)
	exts	bc                                    ; FAB5FB  exts BC
	cpl	bc                                     ; FAB5FD  cpl BC
	inc	1, bc                                  ; FAB5FF  inc 1,BC
	muls	xwa, xbc                              ; FAB601  muls XWA,BC
	ld	hl, wa                                  ; FAB603  ld HL,WA
	jr sub_FAB5A5__FAB61F                      ; FAB605  jr T,0xfab61f
sub_FAB5A5__FAB607:
	ld	c, (xix+25)                             ; FAB607  ld C,(XIX+0x19)
	pushw	bc                                   ; FAB60A  push BC
	pushw	hl                                   ; FAB60B  push HL
	calr (0xFA7CC9 - 0xFAB60F)                 ; FAB60C  calr 0xfa7cc9
	sub	wa, 0xD0                               ; FAB60F  sub WA,0x00d0
	ld	(xiz-2), wa                             ; FAB613  ld (XIZ+0xfe),WA
	ld	c, (xix+24)                             ; FAB616  ld C,(XIX+0x18)
	exts	bc                                    ; FAB619  exts BC
	muls	xwa, xbc                              ; FAB61B  muls XWA,BC
	ld	hl, wa                                  ; FAB61D  ld HL,WA
sub_FAB5A5__FAB61F:
	pop	xiy                                    ; FAB61F  pop XIY
	ld	bc, hl                                  ; FAB620  ld BC,HL
	sra	bc, 5                                  ; FAB622  sra 0x05,BC
	add	bc, 0xD8                               ; FAB625  add BC,0x00d8
	ld	(xiz-2), bc                             ; FAB629  ld (XIZ+0xfe),BC
	ld	a, (xix+29)                             ; FAB62C  ld A,(XIX+0x1d)
	pushw	wa                                   ; FAB62F  push WA
	ld	a, (xix+28)                             ; FAB630  ld A,(XIX+0x1c)
	pushw	wa                                   ; FAB633  push WA
	ld	a, (xix+27)                             ; FAB634  ld A,(XIX+0x1b)
	pushw	wa                                   ; FAB637  push WA
	ld	a, (xix+26)                             ; FAB638  ld A,(XIX+0x1a)
	pushw	wa                                   ; FAB63B  push WA
	extz	xde                                   ; FAB63C  extz XDE
	ld	wa, (xde+8)                             ; FAB63E  ld WA,(XDE+0x08)
	pushw	wa                                   ; FAB641  push WA
	calr (0xFA7D03 - 0xFAB645)                 ; FAB642  calr 0xfa7d03
	extpfx3 0x9E, 0xFE, 0x80                   ; FAB645  add WA,(XIZ+0xfe)
	ld	(xiz-4), wa                             ; FAB648  ld (XIZ+0xfc),WA
	ld	bc, (xde+39)                            ; FAB64B  ld BC,(XDE+0x27)
	and	bc, 0x7F                               ; FAB64E  and BC,0x007f
	extz	xbc                                   ; FAB652  extz XBC
	add	xbc, 0xFDF1AA                          ; FAB654  add XBC,0x00fdf1aa
	ld	b, (xbc)                                ; FAB65A  ld B,(XBC)
	ld	c, b                                    ; FAB65C  ld C,B
	exts	bc                                    ; FAB65E  exts BC
	add	wa, bc                                 ; FAB660  add WA,BC
	ld	(xiz-6), wa                             ; FAB662  ld (XIZ+0xfa),WA
	ld	xbc, (xde+15)                           ; FAB665  ld XBC,(XDE+0x0f)
	ld	a, (xbc+3)                              ; FAB668  ld A,(XBC+0x03)
	exts	wa                                    ; FAB66B  exts WA
	extpfx3 0x9E, 0xFA, 0x80                   ; FAB66D  add WA,(XIZ+0xfa)
	ld	(xiz-8), wa                             ; FAB670  ld (XIZ+0xf8),WA
	ldl_da	xbc, (0xD7F1)                       ; FAB673  ld XBC,(0x00d7f1)
	ld	iy, (xbc+0xE0)                          ; FAB678  ld IY,(XBC+0x00e0)
	add	wa, iy                                 ; FAB67D  add WA,IY
	ld	(xiz-10), wa                            ; FAB67F  ld (XIZ+0xf6),WA
	ld	iy, (0x5A51:16)                       ; FAB682  ld IY,(0x5a51)
	add	wa, iy                                 ; FAB686  add WA,IY
	ld	(xiz-12), wa                            ; FAB688  ld (XIZ+0xf4),WA
	push	xix                                   ; FAB68B  push XIX
	pushw	de                                   ; FAB68C  push DE
	calr (0xFAB48A - 0xFAB690)                 ; FAB68D  calr 0xfab48a
	extpfx3 0x9E, 0xF4, 0x80                   ; FAB690  add WA,(XIZ+0xf4)
	ld	(xiz-14), wa                            ; FAB693  ld (XIZ+0xf2),WA
	push	xix                                   ; FAB696  push XIX
	pushw	de                                   ; FAB697  push DE
	calr (0xFAB517 - 0xFAB69B)                 ; FAB698  calr 0xfab517
	ld	hl, wa                                  ; FAB69B  ld HL,WA
	extpfx3 0x9E, 0xF2, 0x83                   ; FAB69D  add HL,(XIZ+0xf2)
	ld	c, (xix)                                ; FAB6A0  ld C,(XIX)
	and	c, 0x80                                ; FAB6A2  and C,0x80
	add	xsp, 22                                ; FAB6A5  add XSP,0x00000016
	cps	c, 0                                   ; FAB6AB  cp C,0
	jr z, sub_FAB5A5__FAB6BF                   ; FAB6AD  jr Z,0xfab6bf
	extz	xde                                   ; FAB6AF  extz XDE
	ld	bc, (xde+35)                            ; FAB6B1  ld BC,(XDE+0x23)
	extz	xbc                                   ; FAB6B4  extz XBC
	ld	a, (xbc+0x87)                           ; FAB6B6  ld A,(XBC+0x0087)
	extz	wa                                    ; FAB6BB  extz WA
	add	hl, wa                                 ; FAB6BD  add HL,WA
sub_FAB5A5__FAB6BF:
	call	0xFC578C                              ; FAB6BF  call 0xfc578c
	add	wa, hl                                 ; FAB6C3  add WA,HL
	extz	xde                                   ; FAB6C5  extz XDE
	ld	(xde+13), wa                            ; FAB6C7  ld (XDE+0x0d),WA
	extpfx5 0xBA, 0x2F, 0x02, 0x00, 0x00       ; FAB6CA  ld (XDE+0x2f),0x0000
	pop	xix                                    ; FAB6CF  pop XIX
	pop	xde                                    ; FAB6D0  pop XDE
	popw	hl                                    ; FAB6D1  pop HL
	unlk32 xiz                                 ; FAB6D2  unlk XIZ
	ret                                        ; FAB6D4  ret
; --------------------------------------------------------------------------
; sub_FAB6D5 -- 0xFAB6D5..0xFAB79C (200 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFB287B in VoiceRegs_Stage_C, 0xFB2F50 in VoiceRegs_Stage_D
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
;          reads 0x005A51, 0x00D7F1
; Calls:   0xFA7CC9 = sub_FA7CC9, 0xFC578C = sub_FC578C
; Voice record: touches voice_record[+0x0C(r), +0x0D(w), +0x0F(r), +0x17(r), +0x27(r), +0x2F(w)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFAB6D5-0xFAB79C
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAB6D5:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FAB6D5  link XIZ,0xfffc
	pushw	hl                                   ; FAB6D9  push HL
	push	xde                                   ; FAB6DA  push XDE
	push	xix                                   ; FAB6DB  push XIX
	ld	de, (xiz+8)                             ; FAB6DC  ld DE,(XIZ+0x08)
	extz	xde                                   ; FAB6DF  extz XDE
	ld	xbc, (xde+23)                           ; FAB6E1  ld XBC,(XDE+0x17)
	ld	xix, xbc                                ; FAB6E4  ld XIX,XBC
	ld	a, (xde+12)                             ; FAB6E6  ld A,(XDE+0x0c)
	res	7, a                                   ; FAB6E9  res 0x07,A
	extz	wa                                    ; FAB6EC  extz WA
	ld	hl, wa                                  ; FAB6EE  ld HL,WA
	ld	a, (xbc+7)                              ; FAB6F0  ld A,(XBC+0x07)
	cps	a, 0                                   ; FAB6F3  cp A,0
	jr ge, sub_FAB6D5__FAB72A                  ; FAB6F5  jr GE,0xfab72a
	ld	wa, hl                                  ; FAB6F7  ld WA,HL
	extz	xwa                                   ; FAB6F9  extz XWA
	add	xwa, 0xFDD5AB                          ; FAB6FB  add XWA,0x00fdd5ab
	ld	w, (xwa)                                ; FAB701  ld W,(XWA)
	ld	a, w                                    ; FAB703  ld A,W
	extz	wa                                    ; FAB705  extz WA
	ld	(xiz-2), wa                             ; FAB707  ld (XIZ+0xfe),WA
	ld	a, (xbc+8)                              ; FAB70A  ld A,(XBC+0x08)
	pushw	wa                                   ; FAB70D  push WA
	extpfx3 0x9E, 0xFE, 0x04                   ; FAB70E  pushw (XIZ+0xfe)
	calr (0xFA7CC9 - 0xFAB714)                 ; FAB711  calr 0xfa7cc9
	sub	wa, 0xD0                               ; FAB714  sub WA,0x00d0
	ld	(xiz-4), wa                             ; FAB718  ld (XIZ+0xfc),WA
	ld	c, (xix+7)                              ; FAB71B  ld C,(XIX+0x07)
	exts	bc                                    ; FAB71E  exts BC
	cpl	bc                                     ; FAB720  cpl BC
	inc	1, bc                                  ; FAB722  inc 1,BC
	muls	xwa, xbc                              ; FAB724  muls XWA,BC
	ld	hl, wa                                  ; FAB726  ld HL,WA
	jr sub_FAB6D5__FAB742                      ; FAB728  jr T,0xfab742
sub_FAB6D5__FAB72A:
	ld	c, (xix+8)                              ; FAB72A  ld C,(XIX+0x08)
	pushw	bc                                   ; FAB72D  push BC
	pushw	hl                                   ; FAB72E  push HL
	calr (0xFA7CC9 - 0xFAB732)                 ; FAB72F  calr 0xfa7cc9
	sub	wa, 0xD0                               ; FAB732  sub WA,0x00d0
	ld	(xiz-2), wa                             ; FAB736  ld (XIZ+0xfe),WA
	ld	c, (xix+7)                              ; FAB739  ld C,(XIX+0x07)
	exts	bc                                    ; FAB73C  exts BC
	muls	xwa, xbc                              ; FAB73E  muls XWA,BC
	ld	hl, wa                                  ; FAB740  ld HL,WA
sub_FAB6D5__FAB742:
	pop	xiy                                    ; FAB742  pop XIY
	ld	bc, hl                                  ; FAB743  ld BC,HL
	sra	bc, 5                                  ; FAB745  sra 0x05,BC
	ld	hl, bc                                  ; FAB748  ld HL,BC
	add	hl, 0xD8                               ; FAB74A  add HL,0x00d8
	extz	xde                                   ; FAB74E  extz XDE
	ld	bc, (xde+39)                            ; FAB750  ld BC,(XDE+0x27)
	and	bc, 0x7F                               ; FAB753  and BC,0x007f
	extz	xbc                                   ; FAB757  extz XBC
	add	xbc, 0xFDF1AA                          ; FAB759  add XBC,0x00fdf1aa
	ld	a, (xbc)                                ; FAB75F  ld A,(XBC)
	exts	wa                                    ; FAB761  exts WA
	ld	ix, wa                                  ; FAB763  ld IX,WA
	add	ix, hl                                 ; FAB765  add IX,HL
	ld	xbc, (xde+15)                           ; FAB767  ld XBC,(XDE+0x0f)
	ld	a, (xbc+3)                              ; FAB76A  ld A,(XBC+0x03)
	exts	wa                                    ; FAB76D  exts WA
	ld	hl, wa                                  ; FAB76F  ld HL,WA
	add	hl, ix                                 ; FAB771  add HL,IX
	ldl_da	xbc, (0xD7F1)                       ; FAB773  ld XBC,(0x00d7f1)
	ld	wa, (xbc+0xE0)                          ; FAB778  ld WA,(XBC+0x00e0)
	ld	ix, wa                                  ; FAB77D  ld IX,WA
	add	ix, hl                                 ; FAB77F  add IX,HL
	ld	wa, (0x5A51:16)                       ; FAB781  ld WA,(0x5a51)
	ld	hl, wa                                  ; FAB785  ld HL,WA
	add	hl, ix                                 ; FAB787  add HL,IX
	call	0xFC578C                              ; FAB789  call 0xfc578c
	add	wa, hl                                 ; FAB78D  add WA,HL
	ld	(xde+13), wa                            ; FAB78F  ld (XDE+0x0d),WA
	extpfx5 0xBA, 0x2F, 0x02, 0x00, 0x00       ; FAB792  ld (XDE+0x2f),0x0000
	pop	xix                                    ; FAB797  pop XIX
	pop	xde                                    ; FAB798  pop XDE
	popw	hl                                    ; FAB799  pop HL
	unlk32 xiz                                 ; FAB79A  unlk XIZ
	ret                                        ; FAB79C  ret
; --------------------------------------------------------------------------
; sub_FAB79D -- 0xFAB79D..0xFAB7DF (67 bytes)
;
; Called from: 4 site(s) outside this module:
;          0xFAC238 in sub_FAC08D__FAC232, 0xFADE08 in Voice_RestageReg0080_ForList__FADE07
;          0xFB0B7B in VoiceRegs_Stage_A, 0xFB1F96 in VoiceRegs_Stage_B__FB1F91
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA7D6A = Voice_StageLevel_Reg0080
; Voice record: touches voice_record[+0x0D(r), +0x17(r), +0x25(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFAB79D-0xFAB7DF
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAB79D:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAB79D  link XIZ,0x0000
	pushw	hl                                   ; FAB7A1  push HL
	pushw	de                                   ; FAB7A2  push DE
	push	xix                                   ; FAB7A3  push XIX
	ld	ix, (xiz+8)                             ; FAB7A4  ld IX,(XIZ+0x08)
	extz	xix                                   ; FAB7A7  extz XIX
	ld	de, (xix+13)                            ; FAB7A9  ld DE,(XIX+0x0d)
	ld	xbc, (xix+23)                           ; FAB7AC  ld XBC,(XIX+0x17)
	ld	h, (xbc+23)                             ; FAB7AF  ld H,(XBC+0x17)
	cps	h, 0                                   ; FAB7B2  cp H,0
	jr z, sub_FAB79D__FAB7C2                   ; FAB7B4  jr Z,0xfab7c2
	ld	c, h                                    ; FAB7B6  ld C,H
	extz	bc                                    ; FAB7B8  extz BC
	add	de, bc                                 ; FAB7BA  add DE,BC
	add	de, 0xFF9C                             ; FAB7BC  add DE,0xff9c
	jr sub_FAB79D__FAB7C6                      ; FAB7C0  jr T,0xfab7c6
sub_FAB79D__FAB7C2:
	add	de, 0xFE00                             ; FAB7C2  add DE,0xfe00
sub_FAB79D__FAB7C6:
	extz	xix                                   ; FAB7C6  extz XIX
	ld	bc, (xix+37)                            ; FAB7C8  ld BC,(XIX+0x25)
	extz	xbc                                   ; FAB7CB  extz XBC
	ld	a, (xbc+38)                             ; FAB7CD  ld A,(XBC+0x26)
	exts	wa                                    ; FAB7D0  exts WA
	add	wa, de                                 ; FAB7D2  add WA,DE
	pushw	wa                                   ; FAB7D4  push WA
	pushw	ix                                   ; FAB7D5  push IX
	calr (0xFA7D6A - 0xFAB7D9)                 ; FAB7D6  calr 0xfa7d6a
	pop	xbc                                    ; FAB7D9  pop XBC
	pop	xix                                    ; FAB7DA  pop XIX
	popw	de                                    ; FAB7DB  pop DE
	popw	hl                                    ; FAB7DC  pop HL
	unlk32 xiz                                 ; FAB7DD  unlk XIZ
	ret                                        ; FAB7DF  ret
; --------------------------------------------------------------------------
; sub_FAB7E0 -- 0xFAB7E0..0xFAB817 (56 bytes)
;
; Called from: 3 site(s) outside this module:
;          0xFADE0F in Voice_RestageReg0080_ForList__FADE0E, 0xFB2880 in VoiceRegs_Stage_C
;          0xFB2F5A in VoiceRegs_Stage_D
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA7D6A = Voice_StageLevel_Reg0080
; Voice record: touches voice_record[+0x0D(r), +0x17(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFAB7E0-0xFAB817
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAB7E0:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FAB7E0  link XIZ,0xfffc
	pushw	hl                                   ; FAB7E4  push HL
	pushw	de                                   ; FAB7E5  push DE
	push	xix                                   ; FAB7E6  push XIX
	ld	ix, (xiz+8)                             ; FAB7E7  ld IX,(XIZ+0x08)
	extz	xix                                   ; FAB7EA  extz XIX
	ld	xbc, (xix+23)                           ; FAB7EC  ld XBC,(XIX+0x17)
	ld	(xiz-4), xbc                            ; FAB7EF  ld (XIZ+0xfc),XBC
	ld	de, (xix+13)                            ; FAB7F2  ld DE,(XIX+0x0d)
	ld	h, (xbc+6)                              ; FAB7F5  ld H,(XBC+0x06)
	cps	h, 0                                   ; FAB7F8  cp H,0
	jr z, sub_FAB7E0__FAB808                   ; FAB7FA  jr Z,0xfab808
	ld	c, h                                    ; FAB7FC  ld C,H
	extz	bc                                    ; FAB7FE  extz BC
	add	de, bc                                 ; FAB800  add DE,BC
	add	de, 0xFF9C                             ; FAB802  add DE,0xff9c
	jr sub_FAB7E0__FAB80C                      ; FAB806  jr T,0xfab80c
sub_FAB7E0__FAB808:
	add	de, 0xFE00                             ; FAB808  add DE,0xfe00
sub_FAB7E0__FAB80C:
	pushw	de                                   ; FAB80C  push DE
	pushw	ix                                   ; FAB80D  push IX
	calr (0xFA7D6A - 0xFAB811)                 ; FAB80E  calr 0xfa7d6a
	pop	xbc                                    ; FAB811  pop XBC
	pop	xix                                    ; FAB812  pop XIX
	popw	de                                    ; FAB813  pop DE
	popw	hl                                    ; FAB814  pop HL
	unlk32 xiz                                 ; FAB815  unlk XIZ
	ret                                        ; FAB817  ret
; --------------------------------------------------------------------------
; Dev10C_StageRegs_0800_0840_ForNoteOn -- 0xFAB818..0xFAB8CB (180 bytes)
;             compute the two staging words that 0xFB7345 pushes into registers
;             0x0800+chan and 0x0840+chan, ON A NOTE-ON.
;             (★ NAMED in wave 7 round 2 as `Dev10C_StageRegs_0800_0840_FAB818`;
;             was `sub_FAB818`.  ★ PROMOTED in round 12: the address suffix was
;             there only to tell three same-shaped producers apart, and this one is
;             separable without it -- MidiNote_OnByPartMode (0xFB3B44) is its ONLY
;             reference of any spelling, and it is the only one of the three the
;             note-on path reaches.  The other two, _FAB8CC and _FAB9D8, are BOTH
;             called from Voice_Retire_Mode08 (0xFB3E22 and 0xFB3E1C), so the caller
;             does NOT separate them and they keep their addresses -- a refusal,
;             re-measured by `python3 notes/prom_c_finish_round12.py --names`.)
;
; Called from: 1 site(s) outside this module:
;          0xFB3B44 in MidiNote_OnByPartMode__FB3B29
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: writes 0x00D78A, 0x00D78C
; Calls:   0xFB3CE0 = VoiceQuery_Tag00_Part, 0xFB73F0 = Dev10C_SetChanReg_0840_0800_b
; Evidence: ★ THE NAME STATES WHERE THE TWO WORDS GO, NOT WHAT THEY MEAN.  The two
;          absolute stores below are the routine's only absolute-addressed output, and
;          the two words they write are read back by Dev10C_WriteSixChanRegs_FromD78A
;          (0xFB7345), which pushes them into registers 0x0800+chan and 0x0840+chan of
;          one channel:
;              0xFAB855  ld (0x00d78a),WA
;              0xFAB869  ld (0x00d78c),WA
;          That register/word map is reproduced from the ROM BYTES, not from this
;          listing, by `python3 notes/prom_c_tg_chanmap.py 0xFB7345 0xAB --pairs`.
;          The six words 0x00D78A..0x00D795 sit immediately after the 22-word staging
;          struct 0x00D75E..0x00D789 of notes/FINDINGS-prom_c-dev10c-producers.md §2;
;          this routine is one of THREE producers of that word pair -- the others are
;          Dev10C_StageRegs_0800_0840_FAB8CC and _FAB9D8.
;          Everything else above is an instruction operand listed by
;          notes/gen_prom_c_block_headers.py; the call sites are
;          notes/prom_c_module_map.py's image-wide scan; the listing is the byte-
;          identical round-trip of 0xFAB818-0xFAB8CB (notes/gen_prom_c_block.py).
; Unknown:  ⚠ what the two values MEAN.
;          Registers 0x0800+chan and 0x0840+chan have a documented quiescent pair,
;          0xFF80 / 0xFF00 (notes/FINDINGS-prom_c-dev10c-register-meanings.md §5), and
;          that file's 2026-08-25 note reports 0x0800+chan as (envelope level << 8) |
;          rate.  Neither statement is re-derived here and neither is asserted of THIS
;          producer.
;          ⚠ whether 0xFB7345 is the ONLY consumer of them.  prom_c contains no absolute
;          LOAD of these six words at all, but a consumer handed the struct base as an
;          argument -- as 0xFB7345 itself is -- would be invisible to that search.
;          "Only located consumer", not "only consumer".
;          ⚠ what this routine is FOR beyond producing those two words.
; --------------------------------------------------------------------------
Dev10C_StageRegs_0800_0840_ForNoteOn:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FAB818  link XIZ,0xfffc
	pushw	hl                                   ; FAB81C  push HL
	push	xix                                   ; FAB81D  push XIX
	ldb	c, 68                                  ; FAB81E  ld C,0x44
	extpfx3 0x8E, 0x0A, 0x43                   ; FAB820  mul BC,(XIZ+0x0a)
	add	bc, 19                                 ; FAB823  add BC,0x0013
	extz	xbc                                   ; FAB827  extz XBC
	ld	xwa, (xbc+0x3BCF)                       ; FAB829  ld XWA,(XBC+0x3bcf)
	ld	l, (xwa+14)                             ; FAB82E  ld L,(XWA+0x0e)
	ld	c, l                                    ; FAB831  ld C,L
	and	c, 0x80                                ; FAB833  and C,0x80
	jrl z, Dev10C_StageRegs_0800_0840_ForNoteOn__FAB8C7                  ; FAB836  jrl Z,0xfab8c7
	res	7, l                                   ; FAB839  res 0x07,L
	ld	c, l                                    ; FAB83C  ld C,L
	extz	bc                                    ; FAB83E  extz BC
	extz	xbc                                   ; FAB840  extz XBC
	ld	(xiz-4), xbc                            ; FAB842  ld (XIZ+0xfc),XBC
	add	xbc, 0xFDF243                          ; FAB845  add XBC,0x00fdf243
	ld	a, (xbc)                                ; FAB84B  ld A,(XBC)
	extz	wa                                    ; FAB84D  extz WA
	sll	wa, 8                                  ; FAB84F  sll 0x08,WA
	set	7, wa                                  ; FAB852  set 0x07,WA
	stw_da	(0xD78A), wa                        ; FAB855  ld (0x00d78a),WA
	lda	xbc, (0xFDF243:24)                     ; FAB85A  lda XBC,0xfdf243
	extpfx3 0xAE, 0xFC, 0x81                   ; FAB85F  add XBC,(XIZ+0xfc)
	ld	a, (xbc)                                ; FAB862  ld A,(XBC)
	extz	wa                                    ; FAB864  extz WA
	sll	wa, 8                                  ; FAB866  sll 0x08,WA
	stw_da	(0xD78C), wa                        ; FAB869  ld (0x00d78c),WA
	push	0                                     ; FAB86E  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAB870  push (XIZ+0x08)
	call	0xFB3CE0                              ; FAB873  call 0xfb3ce0
	ld	xix, xiy                                ; FAB877  ld XIX,XIY
	inc	5, xiy                                 ; FAB879  inc 5,XIY
	ld	xix, xiy                                ; FAB87B  ld XIX,XIY
	popw	bc                                    ; FAB87D  pop BC
Dev10C_StageRegs_0800_0840_ForNoteOn__FAB87E:
	ld	h, (xix)                                ; FAB87E  ld H,(XIX)
	cp	h, 64                                   ; FAB880  cp H,0x40
	jr nc, Dev10C_StageRegs_0800_0840_ForNoteOn__FAB8C7                  ; FAB883  jr NC,0xfab8c7
	ldb	c, 68                                  ; FAB885  ld C,0x44
	mul8rr	c, h                                ; FAB887  mul BC,H
	add	bc, 19                                 ; FAB889  add BC,0x0013
	extz	xbc                                   ; FAB88D  extz XBC
	ld	xwa, (xbc+0x3BCF)                       ; FAB88F  ld XWA,(XBC+0x3bcf)
	ld	c, (xwa+14)                             ; FAB894  ld C,(XWA+0x0e)
	res	7, c                                   ; FAB897  res 0x07,C
	cp	l, c                                    ; FAB89A  cp L,C
	jr nz, Dev10C_StageRegs_0800_0840_ForNoteOn__FAB8C3                  ; FAB89C  jr NZ,0xfab8c3
	extpfx3 0x8E, 0x0A, 0xF6                   ; FAB89E  cp H,(XIZ+0x0a)
	jr z, Dev10C_StageRegs_0800_0840_ForNoteOn__FAB8C3                   ; FAB8A1  jr Z,0xfab8c3
	ldb	c, 68                                  ; FAB8A3  ld C,0x44
	mul8rr	c, h                                ; FAB8A5  mul BC,H
	inc	1, bc                                  ; FAB8A7  inc 1,BC
	extz	xbc                                   ; FAB8A9  extz XBC
	extpfx7 0xD3, 0xE5, 0xCF, 0x3B, 0x3E, 0x00, 0x10 ; FAB8AB  or (XBC+0x3bcf),0x1000
	lda	xbc, (0xD75E:24)                       ; FAB8B2  lda XBC,0x00d75e
	push	xbc                                   ; FAB8B7  push XBC
	ld	a, (xix)                                ; FAB8B8  ld A,(XIX)
	extz	wa                                    ; FAB8BA  extz WA
	pushw	wa                                   ; FAB8BC  push WA
	call	0xFB73F0                              ; FAB8BD  call 0xfb73f0
	inc	6, xsp                                 ; FAB8C1  inc 6,XSP
Dev10C_StageRegs_0800_0840_ForNoteOn__FAB8C3:
	inc	1, xix                                 ; FAB8C3  inc 1,XIX
	jr Dev10C_StageRegs_0800_0840_ForNoteOn__FAB87E                      ; FAB8C5  jr T,0xfab87e
Dev10C_StageRegs_0800_0840_ForNoteOn__FAB8C7:
	pop	xix                                    ; FAB8C7  pop XIX
	popw	hl                                    ; FAB8C8  pop HL
	unlk32 xiz                                 ; FAB8C9  unlk XIZ
	ret                                        ; FAB8CB  ret
; --------------------------------------------------------------------------
; Dev10C_StageRegs_0800_0840_FAB8CC -- 0xFAB8CC..0xFAB9D7 (268 bytes)
;             compute the two staging words that 0xFB7345 pushes into registers
;             0x0800+chan and 0x0840+chan.
;             (★ NAMED in wave 7 round 2; was `sub_FAB8CC`.)
;
; Called from: 3 site(s) outside this module:
;          0xFADF1E in sub_FADEAC__FADF12, 0xFB3D66 in Voice_Retire_Mode20__FB3D5A
;          0xFB3E22 in Voice_Retire_Mode08__FB3E22
; Inputs:  frame `link XIZ,-6`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D78A, 0x00D78C
; Calls:   0xFA7598 = Clamp_ToRange_Word, 0xFA766C = ScaleClampedDelta_Shr5
; Evidence: ★ THE NAME STATES WHERE THE TWO WORDS GO, NOT WHAT THEY MEAN.  The two
;          absolute stores below are the routine's only absolute-addressed output, and
;          the two words they write are read back by Dev10C_WriteSixChanRegs_FromD78A
;          (0xFB7345), which pushes them into registers 0x0800+chan and 0x0840+chan of
;          one channel:
;              0xFAB9C8  ld (0x00d78a),BC
;              0xFAB9CD  ld (0x00d78c),DE
;          That register/word map is reproduced from the ROM BYTES, not from this
;          listing, by `python3 notes/prom_c_tg_chanmap.py 0xFB7345 0xAB --pairs`.
;          The six words 0x00D78A..0x00D795 sit immediately after the 22-word staging
;          struct 0x00D75E..0x00D789 of notes/FINDINGS-prom_c-dev10c-producers.md §2;
;          this routine is one of THREE producers of that word pair -- the others are
;          Dev10C_StageRegs_0800_0840_ForNoteOn and _FAB9D8.
;          Everything else above is an instruction operand listed by
;          notes/gen_prom_c_block_headers.py; the call sites are
;          notes/prom_c_module_map.py's image-wide scan; the listing is the byte-
;          identical round-trip of 0xFAB8CC-0xFAB9D7 (notes/gen_prom_c_block.py).
; Unknown:  ⚠ what the two values MEAN.
;          Registers 0x0800+chan and 0x0840+chan have a documented quiescent pair,
;          0xFF80 / 0xFF00 (notes/FINDINGS-prom_c-dev10c-register-meanings.md §5), and
;          that file's 2026-08-25 note reports 0x0800+chan as (envelope level << 8) |
;          rate.  Neither statement is re-derived here and neither is asserted of THIS
;          producer.
;          ⚠ whether 0xFB7345 is the ONLY consumer of them.  prom_c contains no absolute
;          LOAD of these six words at all, but a consumer handed the struct base as an
;          argument -- as 0xFB7345 itself is -- would be invisible to that search.
;          "Only located consumer", not "only consumer".
;          ⚠ what this routine is FOR beyond producing those two words.
; --------------------------------------------------------------------------
Dev10C_StageRegs_0800_0840_FAB8CC:
	link32 0xEE, 0x0C, 0xFA, 0xFF              ; FAB8CC  link XIZ,0xfffa
	push	xhl                                   ; FAB8D0  push XHL
	pushw	de                                   ; FAB8D1  push DE
	push	xix                                   ; FAB8D2  push XIX
	ld	ix, (xiz+8)                             ; FAB8D3  ld IX,(XIZ+0x08)
	extz	xix                                   ; FAB8D6  extz XIX
	ld	xbc, (xix+23)                           ; FAB8D8  ld XBC,(XIX+0x17)
	ld	(xiz-4), xbc                            ; FAB8DB  ld (XIZ+0xfc),XBC
	ld	hl, (xix+37)                            ; FAB8DE  ld HL,(XIX+0x25)
	extz	xhl                                   ; FAB8E1  extz XHL
	ld	wa, (xhl+26)                            ; FAB8E3  ld WA,(XHL+0x1a)
	and	wa, 0x1000                             ; FAB8E6  and WA,0x1000
	jr z, Dev10C_StageRegs_0800_0840_FAB8CC__FAB924                   ; FAB8EA  jr Z,0xfab924
	extz	xhl                                   ; FAB8EC  extz XHL
	ld	wa, (xhl+28)                            ; FAB8EE  ld WA,(XHL+0x1c)
	and	wa, 0x1000                             ; FAB8F1  and WA,0x1000
	ld	(xiz-6), wa                             ; FAB8F5  ld (XIZ+0xfa),WA
	pushw	0                                    ; FAB8F8  push 0x0000
	pushw	0x64                                 ; FAB8FB  push 0x0064
	ld	a, (xbc+45)                             ; FAB8FE  ld A,(XBC+0x2d)
	extz	wa                                    ; FAB901  extz WA
	ld	de, wa                                  ; FAB903  ld DE,WA
	extz	xix                                   ; FAB905  extz XIX
	ld	iy, (xix+35)                            ; FAB907  ld IY,(XIX+0x23)
	extz	xiy                                   ; FAB90A  extz XIY
	ld	hl, (xiy+49)                            ; FAB90C  ld HL,(XIY+0x31)
	jr z, Dev10C_StageRegs_0800_0840_FAB8CC__FAB916                   ; FAB90F  jr Z,0xfab916
	sub	wa, hl                                 ; FAB911  sub WA,HL
	pushw	wa                                   ; FAB913  push WA
	jr Dev10C_StageRegs_0800_0840_FAB8CC__FAB91B                      ; FAB914  jr T,0xfab91b
Dev10C_StageRegs_0800_0840_FAB8CC__FAB916:
	ld	bc, de                                  ; FAB916  ld BC,DE
	add	bc, hl                                 ; FAB918  add BC,HL
	pushw	bc                                   ; FAB91A  push BC
Dev10C_StageRegs_0800_0840_FAB8CC__FAB91B:
	calr (0xFA7598 - 0xFAB91E)                 ; FAB91B  calr 0xfa7598
	ld	hl, wa                                  ; FAB91E  ld HL,WA
	inc	6, xsp                                 ; FAB920  inc 6,XSP
	jr Dev10C_StageRegs_0800_0840_FAB8CC__FAB92E                      ; FAB922  jr T,0xfab92e
Dev10C_StageRegs_0800_0840_FAB8CC__FAB924:
	ld	xbc, (xiz-4)                            ; FAB924  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+45)                             ; FAB927  ld A,(XBC+0x2d)
	extz	wa                                    ; FAB92A  extz WA
	ld	hl, wa                                  ; FAB92C  ld HL,WA
Dev10C_StageRegs_0800_0840_FAB8CC__FAB92E:
	ld	c, l                                    ; FAB92E  ld C,L
	extz	bc                                    ; FAB930  extz BC
	exts	xbc                                   ; FAB932  exts XBC
	add	xbc, 0xFDEFD9                          ; FAB934  add XBC,0x00fdefd9
	ld	a, (xbc)                                ; FAB93A  ld A,(XBC)
	extz	wa                                    ; FAB93C  extz WA
	ld	hl, wa                                  ; FAB93E  ld HL,WA
	extz	xix                                   ; FAB940  extz XIX
	ld	bc, (xix+35)                            ; FAB942  ld BC,(XIX+0x23)
	extz	xbc                                   ; FAB945  extz XBC
	ld	iy, (xbc+9)                             ; FAB947  ld IY,(XBC+0x09)
	and	iy, 1                                  ; FAB94A  and IY,0x0001
	jr z, Dev10C_StageRegs_0800_0840_FAB8CC__FAB987                   ; FAB94E  jr Z,0xfab987
	extz	xix                                   ; FAB950  extz XIX
	ld	bc, (xix+1)                             ; FAB952  ld BC,(XIX+0x01)
	and	bc, 0x100                              ; FAB955  and BC,0x0100
	jr nz, Dev10C_StageRegs_0800_0840_FAB8CC__FAB987                  ; FAB959  jr NZ,0xfab987
	extz	xix                                   ; FAB95B  extz XIX
	ld	bc, (xix+35)                            ; FAB95D  ld BC,(XIX+0x23)
	extz	xbc                                   ; FAB960  extz XBC
	ld	a, (xbc+22)                             ; FAB962  ld A,(XBC+0x16)
	extz	wa                                    ; FAB965  extz WA
	extz	xwa                                   ; FAB967  extz XWA
	add	xwa, 0xFDF23A                          ; FAB969  add XWA,0x00fdf23a
	ld	c, (xwa)                                ; FAB96F  ld C,(XWA)
	extz	bc                                    ; FAB971  extz BC
	exts	xbc                                   ; FAB973  exts XBC
	add	xbc, 0xFDEFD9                          ; FAB975  add XBC,0x00fdefd9
	ld	b, (xbc)                                ; FAB97B  ld B,(XBC)
	ld	e, b                                    ; FAB97D  ld E,B
	extz	de                                    ; FAB97F  extz DE
	cp	de, hl                                  ; FAB981  cp DE,HL
	jr gt, Dev10C_StageRegs_0800_0840_FAB8CC__FAB987                  ; FAB983  jr GT,0xfab987
	ld	hl, de                                  ; FAB985  ld HL,DE
Dev10C_StageRegs_0800_0840_FAB8CC__FAB987:
	ld	xbc, (xiz-4)                            ; FAB987  ld XBC,(XIZ+0xfc)
	ld	d, (xbc+53)                             ; FAB98A  ld D,(XBC+0x35)
	cps	d, 0                                   ; FAB98D  cp D,0
	jr z, Dev10C_StageRegs_0800_0840_FAB8CC__FAB9BE                   ; FAB98F  jr Z,0xfab9be
	push	0                                     ; FAB991  push 0x00
	push	d                                     ; FAB993  push D
	ld	a, (xbc+50)                             ; FAB995  ld A,(XBC+0x32)
	pushw	wa                                   ; FAB998  push WA
	ld	a, (xbc+49)                             ; FAB999  ld A,(XBC+0x31)
	pushw	wa                                   ; FAB99C  push WA
	ld	a, (xbc+48)                             ; FAB99D  ld A,(XBC+0x30)
	pushw	wa                                   ; FAB9A0  push WA
	extz	xix                                   ; FAB9A1  extz XIX
	ld	wa, (xix+8)                             ; FAB9A3  ld WA,(XIX+0x08)
	pushw	wa                                   ; FAB9A6  push WA
	calr (0xFA766C - 0xFAB9AA)                 ; FAB9A7  calr 0xfa766c
	ld	ix, wa                                  ; FAB9AA  ld IX,WA
	add	ix, hl                                 ; FAB9AC  add IX,HL
	pushw	0                                    ; FAB9AE  push 0x0000
	pushw	0xFF                                 ; FAB9B1  push 0x00ff
	pushw	ix                                   ; FAB9B4  push IX
	calr (0xFA7598 - 0xFAB9B8)                 ; FAB9B5  calr 0xfa7598
	ld	hl, wa                                  ; FAB9B8  ld HL,WA
	inc	8, xsp                                 ; FAB9BA  inc 0,XSP
	inc	8, xsp                                 ; FAB9BC  inc 0,XSP
Dev10C_StageRegs_0800_0840_FAB8CC__FAB9BE:
	ld	de, hl                                  ; FAB9BE  ld DE,HL
	sll	de, 8                                  ; FAB9C0  sll 0x08,DE
	ld	bc, de                                  ; FAB9C3  ld BC,DE
	set	7, bc                                  ; FAB9C5  set 0x07,BC
	stw_da	(0xD78A), bc                        ; FAB9C8  ld (0x00d78a),BC
	stw_da	(0xD78C), de                        ; FAB9CD  ld (0x00d78c),DE
	pop	xix                                    ; FAB9D2  pop XIX
	popw	de                                    ; FAB9D3  pop DE
	pop	xhl                                    ; FAB9D4  pop XHL
	unlk32 xiz                                 ; FAB9D5  unlk XIZ
	ret                                        ; FAB9D7  ret
; --------------------------------------------------------------------------
; Dev10C_StageRegs_0800_0840_FAB9D8 -- 0xFAB9D8..0xFABAE2 (267 bytes)
;             compute the two staging words that 0xFB7345 pushes into registers
;             0x0800+chan and 0x0840+chan.
;             (★ NAMED in wave 7 round 2; was `sub_FAB9D8`.)
;
; Called from: 1 site(s) outside this module:
;          0xFB3E1C in Voice_Retire_Mode08__FB3E0F
; Inputs:  frame `link XIZ,-6`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D78A, 0x00D78C
; Calls:   0xFA7598 = Clamp_ToRange_Word, 0xFA766C = ScaleClampedDelta_Shr5
;          0xFC3806 = SlotRec_ReadSignedByte_000B
; Voice record: touches voice_record[+0x08(r), +0x17(r), +0x23(r), +0x25(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: ★ THE NAME STATES WHERE THE TWO WORDS GO, NOT WHAT THEY MEAN.  The two
;          absolute stores below are the routine's only absolute-addressed output, and
;          the two words they write are read back by Dev10C_WriteSixChanRegs_FromD78A
;          (0xFB7345), which pushes them into registers 0x0800+chan and 0x0840+chan of
;          one channel:
;              0xFABAD3  ld (0x00d78a),BC
;              0xFABAD8  ld (0x00d78c),HL
;              -- both from ONE value: `sll 0x08,HL` at 0xFABACB then `set 0x07,BC`
;                 at 0xFABAD0, so 0x00D78A = (v<<8)|0x80 and 0x00D78C = v<<8
;          That register/word map is reproduced from the ROM BYTES, not from this
;          listing, by `python3 notes/prom_c_tg_chanmap.py 0xFB7345 0xAB --pairs`.
;          The six words 0x00D78A..0x00D795 sit immediately after the 22-word staging
;          struct 0x00D75E..0x00D789 of notes/FINDINGS-prom_c-dev10c-producers.md §2;
;          this routine is one of THREE producers of that word pair -- the others are
;          Dev10C_StageRegs_0800_0840_ForNoteOn and _FAB8CC.
;          Everything else above is an instruction operand listed by
;          notes/gen_prom_c_block_headers.py; the call sites are
;          notes/prom_c_module_map.py's image-wide scan; the listing is the byte-
;          identical round-trip of 0xFAB9D8-0xFABAE2 (notes/gen_prom_c_block.py).
; Unknown:  ⚠ what the two values MEAN.
;          Registers 0x0800+chan and 0x0840+chan have a documented quiescent pair,
;          0xFF80 / 0xFF00 (notes/FINDINGS-prom_c-dev10c-register-meanings.md §5), and
;          that file's 2026-08-25 note reports 0x0800+chan as (envelope level << 8) |
;          rate.  Neither statement is re-derived here and neither is asserted of THIS
;          producer.
;          ⚠ whether 0xFB7345 is the ONLY consumer of them.  prom_c contains no absolute
;          LOAD of these six words at all, but a consumer handed the struct base as an
;          argument -- as 0xFB7345 itself is -- would be invisible to that search.
;          "Only located consumer", not "only consumer".
;          ⚠ what this routine is FOR beyond producing those two words.
; --------------------------------------------------------------------------
Dev10C_StageRegs_0800_0840_FAB9D8:
	link32 0xEE, 0x0C, 0xFA, 0xFF              ; FAB9D8  link XIZ,0xfffa
	push	xhl                                   ; FAB9DC  push XHL
	pushw	de                                   ; FAB9DD  push DE
	push	xix                                   ; FAB9DE  push XIX
	ld	ix, (xiz+8)                             ; FAB9DF  ld IX,(XIZ+0x08)
	extz	xix                                   ; FAB9E2  extz XIX
	ld	xbc, (xix+23)                           ; FAB9E4  ld XBC,(XIX+0x17)
	ld	(xiz-4), xbc                            ; FAB9E7  ld (XIZ+0xfc),XBC
	pushw	ix                                   ; FAB9EA  push IX
	call	0xFC3806                              ; FAB9EB  call 0xfc3806
	ld	(xiz-6), wa                             ; FAB9EF  ld (XIZ+0xfa),WA
	ld	xbc, (xiz-4)                            ; FAB9F2  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+45)                             ; FAB9F5  ld A,(XBC+0x2d)
	extz	wa                                    ; FAB9F8  extz WA
	ld	de, wa                                  ; FAB9FA  ld DE,WA
	extpfx3 0x9E, 0xFA, 0x80                   ; FAB9FC  add WA,(XIZ+0xfa)
	ld	de, wa                                  ; FAB9FF  ld DE,WA
	ld	hl, (xix+37)                            ; FABA01  ld HL,(XIX+0x25)
	extz	xhl                                   ; FABA04  extz XHL
	ld	iy, (xhl+26)                            ; FABA06  ld IY,(XHL+0x1a)
	and	iy, 0x1000                             ; FABA09  and IY,0x1000
	inc	2, xsp                                 ; FABA0D  inc 2,XSP
	jr z, Dev10C_StageRegs_0800_0840_FAB9D8__FABA3B                   ; FABA0F  jr Z,0xfaba3b
	extz	xhl                                   ; FABA11  extz XHL
	ld	iy, (xhl+28)                            ; FABA13  ld IY,(XHL+0x1c)
	and	iy, 0x1000                             ; FABA16  and IY,0x1000
	ld	(xiz-6), iy                             ; FABA1A  ld (XIZ+0xfa),IY
	pushw	0                                    ; FABA1D  push 0x0000
	pushw	0x64                                 ; FABA20  push 0x0064
	extz	xix                                   ; FABA23  extz XIX
	ld	bc, (xix+35)                            ; FABA25  ld BC,(XIX+0x23)
	extz	xbc                                   ; FABA28  extz XBC
	ld	hl, (xbc+49)                            ; FABA2A  ld HL,(XBC+0x31)
	jr z, Dev10C_StageRegs_0800_0840_FAB9D8__FABA34                   ; FABA2D  jr Z,0xfaba34
	sub	wa, hl                                 ; FABA2F  sub WA,HL
	pushw	wa                                   ; FABA31  push WA
	jr Dev10C_StageRegs_0800_0840_FAB9D8__FABA42                      ; FABA32  jr T,0xfaba42
Dev10C_StageRegs_0800_0840_FAB9D8__FABA34:
	ld	bc, de                                  ; FABA34  ld BC,DE
	add	bc, hl                                 ; FABA36  add BC,HL
	pushw	bc                                   ; FABA38  push BC
	jr Dev10C_StageRegs_0800_0840_FAB9D8__FABA42                      ; FABA39  jr T,0xfaba42
Dev10C_StageRegs_0800_0840_FAB9D8__FABA3B:
	pushw	0                                    ; FABA3B  push 0x0000
	pushw	0x64                                 ; FABA3E  push 0x0064
	pushw	de                                   ; FABA41  push DE
Dev10C_StageRegs_0800_0840_FAB9D8__FABA42:
	calr (0xFA7598 - 0xFABA45)                 ; FABA42  calr 0xfa7598
	ld	de, wa                                  ; FABA45  ld DE,WA
	extz	wa                                    ; FABA47  extz WA
	exts	xwa                                   ; FABA49  exts XWA
	add	xwa, 0xFDEFD9                          ; FABA4B  add XWA,0x00fdefd9
	ld	c, (xwa)                                ; FABA51  ld C,(XWA)
	extz	bc                                    ; FABA53  extz BC
	ld	de, bc                                  ; FABA55  ld DE,BC
	extz	xix                                   ; FABA57  extz XIX
	ld	hl, (xix+35)                            ; FABA59  ld HL,(XIX+0x23)
	extz	xhl                                   ; FABA5C  extz XHL
	ld	wa, (xhl+9)                             ; FABA5E  ld WA,(XHL+0x09)
	and	wa, 1                                  ; FABA61  and WA,0x0001
	inc	6, xsp                                 ; FABA65  inc 6,XSP
	jr z, Dev10C_StageRegs_0800_0840_FAB9D8__FABA92                   ; FABA67  jr Z,0xfaba92
	extz	xhl                                   ; FABA69  extz XHL
	ld	a, (xhl+22)                             ; FABA6B  ld A,(XHL+0x16)
	extz	wa                                    ; FABA6E  extz WA
	extz	xwa                                   ; FABA70  extz XWA
	add	xwa, 0xFDF23A                          ; FABA72  add XWA,0x00fdf23a
	ld	w, (xwa)                                ; FABA78  ld W,(XWA)
	ld	a, w                                    ; FABA7A  ld A,W
	extz	wa                                    ; FABA7C  extz WA
	exts	xwa                                   ; FABA7E  exts XWA
	add	xwa, 0xFDEFD9                          ; FABA80  add XWA,0x00fdefd9
	ld	w, (xwa)                                ; FABA86  ld W,(XWA)
	ld	l, w                                    ; FABA88  ld L,W
	extz	hl                                    ; FABA8A  extz HL
	cp	hl, bc                                  ; FABA8C  cp HL,BC
	jr gt, Dev10C_StageRegs_0800_0840_FAB9D8__FABA92                  ; FABA8E  jr GT,0xfaba92
	ld	de, hl                                  ; FABA90  ld DE,HL
Dev10C_StageRegs_0800_0840_FAB9D8__FABA92:
	ld	xbc, (xiz-4)                            ; FABA92  ld XBC,(XIZ+0xfc)
	ld	h, (xbc+53)                             ; FABA95  ld H,(XBC+0x35)
	cps	h, 0                                   ; FABA98  cp H,0
	jr z, Dev10C_StageRegs_0800_0840_FAB9D8__FABAC9                   ; FABA9A  jr Z,0xfabac9
	push	0                                     ; FABA9C  push 0x00
	push	h                                     ; FABA9E  push H
	ld	a, (xbc+50)                             ; FABAA0  ld A,(XBC+0x32)
	pushw	wa                                   ; FABAA3  push WA
	ld	a, (xbc+49)                             ; FABAA4  ld A,(XBC+0x31)
	pushw	wa                                   ; FABAA7  push WA
	ld	a, (xbc+48)                             ; FABAA8  ld A,(XBC+0x30)
	pushw	wa                                   ; FABAAB  push WA
	extz	xix                                   ; FABAAC  extz XIX
	ld	wa, (xix+8)                             ; FABAAE  ld WA,(XIX+0x08)
	pushw	wa                                   ; FABAB1  push WA
	calr (0xFA766C - 0xFABAB5)                 ; FABAB2  calr 0xfa766c
	ld	ix, wa                                  ; FABAB5  ld IX,WA
	add	ix, de                                 ; FABAB7  add IX,DE
	pushw	0                                    ; FABAB9  push 0x0000
	pushw	0xFF                                 ; FABABC  push 0x00ff
	pushw	ix                                   ; FABABF  push IX
	calr (0xFA7598 - 0xFABAC3)                 ; FABAC0  calr 0xfa7598
	ld	de, wa                                  ; FABAC3  ld DE,WA
	inc	8, xsp                                 ; FABAC5  inc 0,XSP
	inc	8, xsp                                 ; FABAC7  inc 0,XSP
Dev10C_StageRegs_0800_0840_FAB9D8__FABAC9:
	ld	hl, de                                  ; FABAC9  ld HL,DE
	sll	hl, 8                                  ; FABACB  sll 0x08,HL
	ld	bc, hl                                  ; FABACE  ld BC,HL
	set	7, bc                                  ; FABAD0  set 0x07,BC
	stw_da	(0xD78A), bc                        ; FABAD3  ld (0x00d78a),BC
	stw_da	(0xD78C), hl                        ; FABAD8  ld (0x00d78c),HL
	pop	xix                                    ; FABADD  pop XIX
	popw	de                                    ; FABADE  pop DE
	pop	xhl                                    ; FABADF  pop XHL
	unlk32 xiz                                 ; FABAE0  unlk XIZ
	ret                                        ; FABAE2  ret
; --------------------------------------------------------------------------
; Dev10C_StageRegs_0900_0940 -- 0xFABAE3..0xFABBFA (280 bytes)
;             compute the two staging words that 0xFB7345 pushes into registers
;             0x0900+chan and 0x0940+chan.
;             (★ NAMED in wave 7 round 2; was `sub_FABAE3`.)
;
; Called from: 3 site(s) outside this module:
;          0xFADF5C in sub_FADEAC__FADF55, 0xFB3D9F in Voice_Retire_Mode20__FB3D9E
;          0xFB3E28 in Voice_Retire_Mode08__FB3E26
; Inputs:  frame `link XIZ,-2`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D78E, 0x00D790
; Calls:   0xFA7598 = Clamp_ToRange_Word, 0xFA75BA = ScaleCoeff_TimesAbsDepth_Shr
;          0xFA7602 = DetuneCurve_LookupSigned, 0xFA766C = ScaleClampedDelta_Shr5
;          0xFC8129 = sub_FC8129
; Evidence: ★ THE NAME STATES WHERE THE TWO WORDS GO, NOT WHAT THEY MEAN.  The two
;          absolute stores below are the routine's only absolute-addressed output, and
;          the two words they write are read back by Dev10C_WriteSixChanRegs_FromD78A
;          (0xFB7345), which pushes them into registers 0x0900+chan and 0x0940+chan of
;          one channel:
;              0xFABBEA  ld (0x00d78e),HL
;              0xFABBEF  ld (0x00d790),HL
;          That register/word map is reproduced from the ROM BYTES, not from this
;          listing, by `python3 notes/prom_c_tg_chanmap.py 0xFB7345 0xAB --pairs`.
;          The six words 0x00D78A..0x00D795 sit immediately after the 22-word staging
;          struct 0x00D75E..0x00D789 of notes/FINDINGS-prom_c-dev10c-producers.md §2;
;          this routine is the ONLY producer of that word pair in prom_c.
;          Everything else above is an instruction operand listed by
;          notes/gen_prom_c_block_headers.py; the call sites are
;          notes/prom_c_module_map.py's image-wide scan; the listing is the byte-
;          identical round-trip of 0xFABAE3-0xFABBFA (notes/gen_prom_c_block.py).
; Unknown:  ⚠ what the two values MEAN.
;          Register blocks 0x0900-0x0A40 have no statement of any kind: §0 of
;          notes/FINDINGS-prom_c-dev10c-register-meanings.md lists them among the blocks
;          whose contents are unknown.
;          ⚠ whether 0xFB7345 is the ONLY consumer of them.  prom_c contains no absolute
;          LOAD of these six words at all, but a consumer handed the struct base as an
;          argument -- as 0xFB7345 itself is -- would be invisible to that search.
;          "Only located consumer", not "only consumer".
;          ⚠ what this routine is FOR beyond producing those two words.
; --------------------------------------------------------------------------
Dev10C_StageRegs_0900_0940:
	link32 0xEE, 0x0C, 0xFE, 0xFF              ; FABAE3  link XIZ,0xfffe
	push	xhl                                   ; FABAE7  push XHL
	pushw	de                                   ; FABAE8  push DE
	push	xix                                   ; FABAE9  push XIX
	ld	bc, (xiz+8)                             ; FABAEA  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FABAED  extz XBC
	ld	wa, (xbc+1)                             ; FABAEF  ld WA,(XBC+0x01)
	and	wa, 0x200                              ; FABAF2  and WA,0x0200
	jr z, Dev10C_StageRegs_0900_0940__FABB08                   ; FABAF6  jr Z,0xfabb08
	lda	xwa, (0xD75E:24)                       ; FABAF8  lda XWA,0x00d75e
	push	xwa                                   ; FABAFD  push XWA
	pushw	bc                                   ; FABAFE  push BC
	call	0xFC8129                              ; FABAFF  call 0xfc8129
	inc	6, xsp                                 ; FABB03  inc 6,XSP
	jrl Dev10C_StageRegs_0900_0940__FABBF5                     ; FABB05  jrl T,0xfabbf5
Dev10C_StageRegs_0900_0940__FABB08:
	ld	bc, (xiz+8)                             ; FABB08  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FABB0B  extz XBC
	ld	xwa, (xbc+23)                           ; FABB0D  ld XWA,(XBC+0x17)
	ld	xix, xwa                                ; FABB10  ld XIX,XWA
	ld	c, (xwa+15)                             ; FABB12  ld C,(XWA+0x0f)
	extz	bc                                    ; FABB15  extz BC
	exts	xbc                                   ; FABB17  exts XBC
	add	xbc, 0xFDEFD9                          ; FABB19  add XBC,0x00fdefd9
	ld	b, (xbc)                                ; FABB1F  ld B,(XBC)
	ld	e, b                                    ; FABB21  ld E,B
	extz	de                                    ; FABB23  extz DE
	ld	hl, (xiz+8)                             ; FABB25  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FABB28  extz XHL
	ld	hl, (xhl+35)                            ; FABB2A  ld HL,(XHL+0x23)
	extz	xhl                                   ; FABB2D  extz XHL
	ld	bc, (xhl+9)                             ; FABB2F  ld BC,(XHL+0x09)
	and	bc, 1                                  ; FABB32  and BC,0x0001
	jr z, Dev10C_StageRegs_0900_0940__FABB61                   ; FABB36  jr Z,0xfabb61
	extz	xhl                                   ; FABB38  extz XHL
	ld	c, (xhl+22)                             ; FABB3A  ld C,(XHL+0x16)
	extz	bc                                    ; FABB3D  extz BC
	extz	xbc                                   ; FABB3F  extz XBC
	add	xbc, 0xFDF23A                          ; FABB41  add XBC,0x00fdf23a
	ld	b, (xbc)                                ; FABB47  ld B,(XBC)
	ld	c, b                                    ; FABB49  ld C,B
	extz	bc                                    ; FABB4B  extz BC
	exts	xbc                                   ; FABB4D  exts XBC
	add	xbc, 0xFDEFD9                          ; FABB4F  add XBC,0x00fdefd9
	ld	b, (xbc)                                ; FABB55  ld B,(XBC)
	ld	l, b                                    ; FABB57  ld L,B
	extz	hl                                    ; FABB59  extz HL
	cp	hl, de                                  ; FABB5B  cp HL,DE
	jr gt, Dev10C_StageRegs_0900_0940__FABB61                  ; FABB5D  jr GT,0xfabb61
	ld	de, hl                                  ; FABB5F  ld DE,HL
Dev10C_StageRegs_0900_0940__FABB61:
	ld	h, (xix+22)                             ; FABB61  ld H,(XIX+0x16)
	cps	h, 0                                   ; FABB64  cp H,0
	jr z, Dev10C_StageRegs_0900_0940__FABB91                   ; FABB66  jr Z,0xfabb91
	push	0                                     ; FABB68  push 0x00
	push	h                                     ; FABB6A  push H
	pushw	0x7F                                 ; FABB6C  push 0x007f
	pushw	0                                    ; FABB6F  push 0x0000
	ld	c, (xix+19)                             ; FABB72  ld C,(XIX+0x13)
	pushw	bc                                   ; FABB75  push BC
	ld	bc, (xiz+8)                             ; FABB76  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FABB79  extz XBC
	ld	wa, (xbc+8)                             ; FABB7B  ld WA,(XBC+0x08)
	pushw	wa                                   ; FABB7E  push WA
	calr (0xFA766C - 0xFABB82)                 ; FABB7F  calr 0xfa766c
	add	de, wa                                 ; FABB82  add DE,WA
	ld	c, (xix+17)                             ; FABB84  ld C,(XIX+0x11)
	inc	8, xsp                                 ; FABB87  inc 0,XSP
	inc	2, xsp                                 ; FABB89  inc 2,XSP
	cps	c, 0                                   ; FABB8B  cp C,0
	jr z, Dev10C_StageRegs_0900_0940__FABBAF                   ; FABB8D  jr Z,0xfabbaf
	jr Dev10C_StageRegs_0900_0940__FABB98                      ; FABB8F  jr T,0xfabb98
Dev10C_StageRegs_0900_0940__FABB91:
	ld	c, (xix+17)                             ; FABB91  ld C,(XIX+0x11)
	cps	c, 0                                   ; FABB94  cp C,0
	jr z, Dev10C_StageRegs_0900_0940__FABBBD                   ; FABB96  jr Z,0xfabbbd
Dev10C_StageRegs_0900_0940__FABB98:
	pushw	4                                    ; FABB98  push 0x0004
	ld	bc, (xiz+8)                             ; FABB9B  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FABB9E  extz XBC
	ld	a, (xbc+12)                             ; FABBA0  ld A,(XBC+0x0c)
	pushw	wa                                   ; FABBA3  push WA
	ld	a, (xix+17)                             ; FABBA4  ld A,(XIX+0x11)
	pushw	wa                                   ; FABBA7  push WA
	calr (0xFA75BA - 0xFABBAB)                 ; FABBA8  calr 0xfa75ba
	add	de, wa                                 ; FABBAB  add DE,WA
	inc	6, xsp                                 ; FABBAD  inc 6,XSP
Dev10C_StageRegs_0900_0940__FABBAF:
	pushw	0                                    ; FABBAF  push 0x0000
	pushw	0xFF                                 ; FABBB2  push 0x00ff
	pushw	de                                   ; FABBB5  push DE
	calr (0xFA7598 - 0xFABBB9)                 ; FABBB6  calr 0xfa7598
	ld	de, wa                                  ; FABBB9  ld DE,WA
	inc	6, xsp                                 ; FABBBB  inc 6,XSP
Dev10C_StageRegs_0900_0940__FABBBD:
	ld	c, (xix+7)                              ; FABBBD  ld C,(XIX+0x07)
	ld	(xiz-2), c                              ; FABBC0  ld (XIZ+0xfe),C
	ld	a, (xix+16)                             ; FABBC3  ld A,(XIX+0x10)
	exts	wa                                    ; FABBC6  exts WA
	ld	hl, wa                                  ; FABBC8  ld HL,WA
	cps	c, 0                                   ; FABBCA  cp C,0
	jr ge, Dev10C_StageRegs_0900_0940__FABBD5                  ; FABBCC  jr GE,0xfabbd5
	cpl	wa                                     ; FABBCE  cpl WA
	inc	1, wa                                  ; FABBD0  inc 1,WA
	pushw	wa                                   ; FABBD2  push WA
	jr Dev10C_StageRegs_0900_0940__FABBD6                      ; FABBD3  jr T,0xfabbd6
Dev10C_StageRegs_0900_0940__FABBD5:
	pushw	hl                                   ; FABBD5  push HL
Dev10C_StageRegs_0900_0940__FABBD6:
	calr (0xFA7602 - 0xFABBD9)                 ; FABBD6  calr 0xfa7602
	ld	hl, wa                                  ; FABBD9  ld HL,WA
	ld	ix, wa                                  ; FABBDB  ld IX,WA
	and	ix, 0xFF                               ; FABBDD  and IX,0x00ff
	ld	bc, de                                  ; FABBE1  ld BC,DE
	sll	bc, 8                                  ; FABBE3  sll 0x08,BC
	ld	hl, bc                                  ; FABBE6  ld HL,BC
	or	hl, ix                                  ; FABBE8  or HL,IX
	stw_da	(0xD78E), hl                        ; FABBEA  ld (0x00d78e),HL
	stw_da	(0xD790), hl                        ; FABBEF  ld (0x00d790),HL
	popw	bc                                    ; FABBF4  pop BC
Dev10C_StageRegs_0900_0940__FABBF5:
	pop	xix                                    ; FABBF5  pop XIX
	popw	de                                    ; FABBF6  pop DE
	pop	xhl                                    ; FABBF7  pop XHL
	unlk32 xiz                                 ; FABBF8  unlk XIZ
	ret                                        ; FABBFA  ret
; --------------------------------------------------------------------------
; Dev10C_StageRegs_09C0_0A00 -- 0xFABBFB..0xFABCF8 (254 bytes)
;             compute the two staging words that 0xFB7345 pushes into registers
;             0x09C0+chan and 0x0A00+chan.
;             (★ NAMED in wave 7 round 2; was `sub_FABBFB`.)
;
; Called from: 3 site(s) outside this module:
;          0xFADF61 in sub_FADEAC__FADF55, 0xFB3DA4 in Voice_Retire_Mode20__FB3D9E
;          0xFB3E2D in Voice_Retire_Mode08__FB3E26
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D792, 0x00D794
; Calls:   0xFA7598 = Clamp_ToRange_Word, 0xFA75BA = ScaleCoeff_TimesAbsDepth_Shr
;          0xFA7602 = DetuneCurve_LookupSigned, 0xFA766C = ScaleClampedDelta_Shr5
; Evidence: ★ THE NAME STATES WHERE THE TWO WORDS GO, NOT WHAT THEY MEAN.  The two
;          absolute stores below are the routine's only absolute-addressed output, and
;          the two words they write are read back by Dev10C_WriteSixChanRegs_FromD78A
;          (0xFB7345), which pushes them into registers 0x09C0+chan and 0x0A00+chan of
;          one channel:
;              0xFABCE7  ld (0x00d792),DE
;              0xFABCEC  ld (0x00d794),DE
;          That register/word map is reproduced from the ROM BYTES, not from this
;          listing, by `python3 notes/prom_c_tg_chanmap.py 0xFB7345 0xAB --pairs`.
;          The six words 0x00D78A..0x00D795 sit immediately after the 22-word staging
;          struct 0x00D75E..0x00D789 of notes/FINDINGS-prom_c-dev10c-producers.md §2;
;          this routine is the ONLY producer of that word pair in prom_c.
;          Everything else above is an instruction operand listed by
;          notes/gen_prom_c_block_headers.py; the call sites are
;          notes/prom_c_module_map.py's image-wide scan; the listing is the byte-
;          identical round-trip of 0xFABBFB-0xFABCF8 (notes/gen_prom_c_block.py).
; Unknown:  ⚠ what the two values MEAN.
;          Register blocks 0x0900-0x0A40 have no statement of any kind: §0 of
;          notes/FINDINGS-prom_c-dev10c-register-meanings.md lists them among the blocks
;          whose contents are unknown.
;          ⚠ whether 0xFB7345 is the ONLY consumer of them.  prom_c contains no absolute
;          LOAD of these six words at all, but a consumer handed the struct base as an
;          argument -- as 0xFB7345 itself is -- would be invisible to that search.
;          "Only located consumer", not "only consumer".
;          ⚠ what this routine is FOR beyond producing those two words.
; --------------------------------------------------------------------------
Dev10C_StageRegs_09C0_0A00:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FABBFB  link XIZ,0xfffc
	push	xhl                                   ; FABBFF  push XHL
	pushw	de                                   ; FABC00  push DE
	push	xix                                   ; FABC01  push XIX
	ld	ix, (xiz+8)                             ; FABC02  ld IX,(XIZ+0x08)
	extz	xix                                   ; FABC05  extz XIX
	ld	xbc, (xix+23)                           ; FABC07  ld XBC,(XIX+0x17)
	ld	(xiz-4), xbc                            ; FABC0A  ld (XIZ+0xfc),XBC
	ld	a, (xbc+69)                             ; FABC0D  ld A,(XBC+0x45)
	extz	wa                                    ; FABC10  extz WA
	exts	xwa                                   ; FABC12  exts XWA
	add	xwa, 0xFDEFD9                          ; FABC14  add XWA,0x00fdefd9
	ld	w, (xwa)                                ; FABC1A  ld W,(XWA)
	ld	e, w                                    ; FABC1C  ld E,W
	extz	de                                    ; FABC1E  extz DE
	ld	hl, (xix+35)                            ; FABC20  ld HL,(XIX+0x23)
	extz	xhl                                   ; FABC23  extz XHL
	ld	wa, (xhl+9)                             ; FABC25  ld WA,(XHL+0x09)
	and	wa, 1                                  ; FABC28  and WA,0x0001
	jr z, Dev10C_StageRegs_09C0_0A00__FABC57                   ; FABC2C  jr Z,0xfabc57
	extz	xhl                                   ; FABC2E  extz XHL
	ld	a, (xhl+22)                             ; FABC30  ld A,(XHL+0x16)
	extz	wa                                    ; FABC33  extz WA
	extz	xwa                                   ; FABC35  extz XWA
	add	xwa, 0xFDF23A                          ; FABC37  add XWA,0x00fdf23a
	ld	w, (xwa)                                ; FABC3D  ld W,(XWA)
	ld	a, w                                    ; FABC3F  ld A,W
	extz	wa                                    ; FABC41  extz WA
	exts	xwa                                   ; FABC43  exts XWA
	add	xwa, 0xFDEFD9                          ; FABC45  add XWA,0x00fdefd9
	ld	w, (xwa)                                ; FABC4B  ld W,(XWA)
	ld	l, w                                    ; FABC4D  ld L,W
	extz	hl                                    ; FABC4F  extz HL
	cp	hl, de                                  ; FABC51  cp HL,DE
	jr gt, Dev10C_StageRegs_09C0_0A00__FABC57                  ; FABC53  jr GT,0xfabc57
	ld	de, hl                                  ; FABC55  ld DE,HL
Dev10C_StageRegs_09C0_0A00__FABC57:
	ld	xbc, (xiz-4)                            ; FABC57  ld XBC,(XIZ+0xfc)
	ld	h, (xbc+76)                             ; FABC5A  ld H,(XBC+0x4c)
	cps	h, 0                                   ; FABC5D  cp H,0
	jr z, Dev10C_StageRegs_09C0_0A00__FABC8A                   ; FABC5F  jr Z,0xfabc8a
	push	0                                     ; FABC61  push 0x00
	push	h                                     ; FABC63  push H
	pushw	0x7F                                 ; FABC65  push 0x007f
	pushw	0                                    ; FABC68  push 0x0000
	ld	a, (xbc+73)                             ; FABC6B  ld A,(XBC+0x49)
	pushw	wa                                   ; FABC6E  push WA
	extz	xix                                   ; FABC6F  extz XIX
	ld	wa, (xix+8)                             ; FABC71  ld WA,(XIX+0x08)
	pushw	wa                                   ; FABC74  push WA
	calr (0xFA766C - 0xFABC78)                 ; FABC75  calr 0xfa766c
	add	de, wa                                 ; FABC78  add DE,WA
	ld	xbc, (xiz-4)                            ; FABC7A  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+71)                             ; FABC7D  ld A,(XBC+0x47)
	inc	8, xsp                                 ; FABC80  inc 0,XSP
	inc	2, xsp                                 ; FABC82  inc 2,XSP
	cps	a, 0                                   ; FABC84  cp A,0
	jr z, Dev10C_StageRegs_09C0_0A00__FABCAB                   ; FABC86  jr Z,0xfabcab
	jr Dev10C_StageRegs_09C0_0A00__FABC94                      ; FABC88  jr T,0xfabc94
Dev10C_StageRegs_09C0_0A00__FABC8A:
	ld	xbc, (xiz-4)                            ; FABC8A  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+71)                             ; FABC8D  ld A,(XBC+0x47)
	cps	a, 0                                   ; FABC90  cp A,0
	jr z, Dev10C_StageRegs_09C0_0A00__FABCB9                   ; FABC92  jr Z,0xfabcb9
Dev10C_StageRegs_09C0_0A00__FABC94:
	pushw	4                                    ; FABC94  push 0x0004
	extz	xix                                   ; FABC97  extz XIX
	ld	c, (xix+12)                             ; FABC99  ld C,(XIX+0x0c)
	pushw	bc                                   ; FABC9C  push BC
	ld	xbc, (xiz-4)                            ; FABC9D  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+71)                             ; FABCA0  ld A,(XBC+0x47)
	pushw	wa                                   ; FABCA3  push WA
	calr (0xFA75BA - 0xFABCA7)                 ; FABCA4  calr 0xfa75ba
	add	de, wa                                 ; FABCA7  add DE,WA
	inc	6, xsp                                 ; FABCA9  inc 6,XSP
Dev10C_StageRegs_09C0_0A00__FABCAB:
	pushw	0                                    ; FABCAB  push 0x0000
	pushw	0xFF                                 ; FABCAE  push 0x00ff
	pushw	de                                   ; FABCB1  push DE
	calr (0xFA7598 - 0xFABCB5)                 ; FABCB2  calr 0xfa7598
	ld	de, wa                                  ; FABCB5  ld DE,WA
	inc	6, xsp                                 ; FABCB7  inc 6,XSP
Dev10C_StageRegs_09C0_0A00__FABCB9:
	pushw	0xFFCE                               ; FABCB9  push 0xffce
	pushw	50                                   ; FABCBC  push 0x0032
	ld	xbc, (xiz-4)                            ; FABCBF  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+61)                             ; FABCC2  ld A,(XBC+0x3d)
	exts	wa                                    ; FABCC5  exts WA
	ld	hl, wa                                  ; FABCC7  ld HL,WA
	ld	a, (xbc+70)                             ; FABCC9  ld A,(XBC+0x46)
	exts	wa                                    ; FABCCC  exts WA
	add	wa, hl                                 ; FABCCE  add WA,HL
	pushw	wa                                   ; FABCD0  push WA
	calr (0xFA7598 - 0xFABCD4)                 ; FABCD1  calr 0xfa7598
	pushw	wa                                   ; FABCD4  push WA
	calr (0xFA7602 - 0xFABCD8)                 ; FABCD5  calr 0xfa7602
	ld	hl, wa                                  ; FABCD8  ld HL,WA
	and	hl, 0xFF                               ; FABCDA  and HL,0x00ff
	ld	bc, de                                  ; FABCDE  ld BC,DE
	sll	bc, 8                                  ; FABCE0  sll 0x08,BC
	ld	de, bc                                  ; FABCE3  ld DE,BC
	or	de, hl                                  ; FABCE5  or DE,HL
	stw_da	(0xD792), de                        ; FABCE7  ld (0x00d792),DE
	stw_da	(0xD794), de                        ; FABCEC  ld (0x00d794),DE
	inc	8, xsp                                 ; FABCF1  inc 0,XSP
	pop	xix                                    ; FABCF3  pop XIX
	popw	de                                    ; FABCF4  pop DE
	pop	xhl                                    ; FABCF5  pop XHL
	unlk32 xiz                                 ; FABCF6  unlk XIZ
	ret                                        ; FABCF8  ret
; --------------------------------------------------------------------------
; sub_FABCF9 -- 0xFABCF9..0xFABD4F (87 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFB3E70 in Voice_Retire_Mode10
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFC8129 = sub_FC8129
; Voice record: touches voice_record[+0x01(r), +0x43(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFABCF9-0xFABD4F
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FABCF9:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FABCF9  link XIZ,0x0000
	push	xhl                                   ; FABCFD  push XHL
	push	xix                                   ; FABCFE  push XIX
	lda	xix, (0xD75E:24)                       ; FABCFF  lda XIX,0x00d75e
	ld	hl, (xiz+8)                             ; FABD04  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FABD07  extz XHL
	ld	bc, (xhl+1)                             ; FABD09  ld BC,(XHL+0x01)
	and	bc, 0x200                              ; FABD0C  and BC,0x0200
	jr z, sub_FABCF9__FABD1C                   ; FABD10  jr Z,0xfabd1c
	push	xix                                   ; FABD12  push XIX
	pushw	hl                                   ; FABD13  push HL
	call	0xFC8129                              ; FABD14  call 0xfc8129
	inc	6, xsp                                 ; FABD18  inc 6,XSP
	jr sub_FABCF9__FABD26                      ; FABD1A  jr T,0xfabd26
sub_FABCF9__FABD1C:
	extpfx5 0xBC, 0x30, 0x02, 0x00, 0x00       ; FABD1C  ld (XIX+0x30),0x0000
	extpfx5 0xBC, 0x32, 0x02, 0x00, 0x00       ; FABD21  ld (XIX+0x32),0x0000
sub_FABCF9__FABD26:
	extz	xhl                                   ; FABD26  extz XHL
	ld	c, (xhl+67)                             ; FABD28  ld C,(XHL+0x43)
	extz	bc                                    ; FABD2B  extz BC
	sll	bc, 8                                  ; FABD2D  sll 0x08,BC
	set	7, bc                                  ; FABD30  set 0x07,BC
	ld	(xix+44), bc                            ; FABD33  ld (XIX+0x2c),BC
	ld	c, (xhl+67)                             ; FABD36  ld C,(XHL+0x43)
	extz	bc                                    ; FABD39  extz BC
	sll	bc, 8                                  ; FABD3B  sll 0x08,BC
	ld	(xix+46), bc                            ; FABD3E  ld (XIX+0x2e),BC
	extpfx5 0xBC, 0x34, 0x02, 0x00, 0x00       ; FABD41  ld (XIX+0x34),0x0000
	extpfx5 0xBC, 0x36, 0x02, 0x00, 0x00       ; FABD46  ld (XIX+0x36),0x0000
	pop	xix                                    ; FABD4B  pop XIX
	pop	xhl                                    ; FABD4C  pop XHL
	unlk32 xiz                                 ; FABD4D  unlk XIZ
	ret                                        ; FABD4F  ret
; --------------------------------------------------------------------------
; sub_FABD50 -- 0xFABD50..0xFABDAB (92 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFADF81 in sub_FADEAC__FADF7A
; Inputs:  frame `link XIZ,-8`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFABD50-0xFABDAB
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FABD50:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FABD50  link XIZ,0xfff8
	push	xhl                                   ; FABD54  push XHL
	push	xix                                   ; FABD55  push XIX
	lda	xix, (0xD75E:24)                       ; FABD56  lda XIX,0x00d75e
	ld	hl, (xiz+8)                             ; FABD5B  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FABD5E  extz XHL
	ld	xbc, (xhl+19)                           ; FABD60  ld XBC,(XHL+0x13)
	ld	(xiz-8), xbc                            ; FABD63  ld (XIZ+0xf8),XBC
	ld	xwa, (xhl+23)                           ; FABD66  ld XWA,(XHL+0x17)
	ld	(xiz-4), xwa                            ; FABD69  ld (XIZ+0xfc),XWA
	ld	a, (xbc+13)                             ; FABD6C  ld A,(XBC+0x0d)
	and	a, 32                                  ; FABD6F  and A,0x20
	jr z, sub_FABD50__FABD92                   ; FABD72  jr Z,0xfabd92
	ld	xbc, (xiz-4)                            ; FABD74  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+14)                             ; FABD77  ld A,(XBC+0x0e)
	extz	wa                                    ; FABD7A  extz WA
	exts	xwa                                   ; FABD7C  exts XWA
	add	xwa, 0xFDEFD9                          ; FABD7E  add XWA,0x00fdefd9
	ld	w, (xwa)                                ; FABD84  ld W,(XWA)
	ld	a, w                                    ; FABD86  ld A,W
	extz	wa                                    ; FABD88  extz WA
	sll	wa, 8                                  ; FABD8A  sll 0x08,WA
	ld	(xix+46), wa                            ; FABD8D  ld (XIX+0x2e),WA
	jr sub_FABD50__FABD9E                      ; FABD90  jr T,0xfabd9e
sub_FABD50__FABD92:
	extz	xhl                                   ; FABD92  extz XHL
	ld	bc, (xhl+59)                            ; FABD94  ld BC,(XHL+0x3b)
	and	bc, 0xFF00                             ; FABD97  and BC,0xff00
	ld	(xix+46), bc                            ; FABD9B  ld (XIX+0x2e),BC
sub_FABD50__FABD9E:
	ld	bc, (xix+46)                            ; FABD9E  ld BC,(XIX+0x2e)
	set	7, bc                                  ; FABDA1  set 0x07,BC
	ld	(xix+44), bc                            ; FABDA4  ld (XIX+0x2c),BC
	pop	xix                                    ; FABDA7  pop XIX
	pop	xhl                                    ; FABDA8  pop XHL
	unlk32 xiz                                 ; FABDA9  unlk XIZ
	ret                                        ; FABDAB  ret
; --------------------------------------------------------------------------
; sub_FABDAC -- 0xFABDAC..0xFABE2F (132 bytes)
;
; Called from: 3 site(s) outside this module:
;          0xFABE52 in Voice_RecomputeAllThreeBaseCurves__FABE3F, 0xFABEDD in Voice_RecomputeAllThreeBaseCurves__FABECC
;          0xFABF6F in Voice_RecomputeAllThreeBaseCurves__FABF5D
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFABDAC-0xFABE2F
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FABDAC:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FABDAC  link XIZ,0x0000
	pushw	hl                                   ; FABDB0  push HL
	push	xde                                   ; FABDB1  push XDE
	ld	de, (xiz+8)                             ; FABDB2  ld DE,(XIZ+0x08)
	extz	xde                                   ; FABDB5  extz XDE
	ld	c, (xde)                                ; FABDB7  ld C,(XDE)
	and	c, 28                                  ; FABDB9  and C,0x1c
	extz	bc                                    ; FABDBC  extz BC
	cp	bc, 8                                   ; FABDBE  cp BC,0x0008
	jr z, sub_FABDAC__FABDED                   ; FABDC2  jr Z,0xfabded
	cp	bc, 16                                  ; FABDC4  cp BC,0x0010
	jr z, sub_FABDAC__FABDCC                   ; FABDC8  jr Z,0xfabdcc
	jr sub_FABDAC__FABE29                      ; FABDCA  jr T,0xfabe29
sub_FABDAC__FABDCC:
	extz	xde                                   ; FABDCC  extz XDE
	incm8	1, (xde+8)                           ; FABDCE  inc 1,(XDE+0x08)
	ld	h, (xde+8)                              ; FABDD1  ld H,(XDE+0x08)
	ld	c, (xde+7)                              ; FABDD4  ld C,(XDE+0x07)
	cp	h, c                                    ; FABDD7  cp H,C
	jr c, sub_FABDAC__FABE29                   ; FABDD9  jr C,0xfabe29
	extz	xde                                   ; FABDDB  extz XDE
	ld	(xde+8), 0                              ; FABDDD  ld (XDE+0x08),0x00
	extpfx3 0x82, 0x3C, 0xEF                   ; FABDE1  and (XDE),0xef
	ld	c, (xde)                                ; FABDE4  ld C,(XDE)
	set	3, c                                   ; FABDE6  set 0x03,C
	ld	(xde), c                                ; FABDE9  ld (XDE),C
	jr sub_FABDAC__FABE29                      ; FABDEB  jr T,0xfabe29
sub_FABDAC__FABDED:
	extz	xde                                   ; FABDED  extz XDE
	incm8	1, (xde+8)                           ; FABDEF  inc 1,(XDE+0x08)
	ld	l, (xde+8)                              ; FABDF2  ld L,(XDE+0x08)
	ld	h, (xde+7)                              ; FABDF5  ld H,(XDE+0x07)
	cp	l, h                                    ; FABDF8  cp L,H
	jr nc, sub_FABDAC__FABE14                  ; FABDFA  jr NC,0xfabe14
	extz	xde                                   ; FABDFC  extz XDE
	ld	c, (xde+8)                              ; FABDFE  ld C,(XDE+0x08)
	extz	bc                                    ; FABE01  extz BC
	ld	de, bc                                  ; FABE03  ld DE,BC
	sll	de, 8                                  ; FABE05  sll 0x08,DE
	ld	c, h                                    ; FABE08  ld C,H
	extz	bc                                    ; FABE0A  extz BC
	ld	wa, de                                  ; FABE0C  ld WA,DE
	extz	xwa                                   ; FABE0E  extz XWA
	div	xwa, xbc                               ; FABE10  div XWA,BC
	jr sub_FABDAC__FABE2B                      ; FABE12  jr T,0xfabe2b
sub_FABDAC__FABE14:
	extz	xde                                   ; FABE14  extz XDE
	ld	(xde+8), 0                              ; FABE16  ld (XDE+0x08),0x00
	extpfx3 0x82, 0x3C, 0xF7                   ; FABE1A  and (XDE),0xf7
	ld	c, (xde)                                ; FABE1D  ld C,(XDE)
	set	2, c                                   ; FABE1F  set 0x02,C
	ld	(xde), c                                ; FABE22  ld (XDE),C
	ldw	wa, 0x100                              ; FABE24  ld WA,0x0100
	jr sub_FABDAC__FABE2B                      ; FABE27  jr T,0xfabe2b
sub_FABDAC__FABE29:
	sub	wa, wa                                 ; FABE29  sub WA,WA
sub_FABDAC__FABE2B:
	pop	xde                                    ; FABE2B  pop XDE
	popw	hl                                    ; FABE2C  pop HL
	unlk32 xiz                                 ; FABE2D  unlk XIZ
	ret                                        ; FABE2F  ret

