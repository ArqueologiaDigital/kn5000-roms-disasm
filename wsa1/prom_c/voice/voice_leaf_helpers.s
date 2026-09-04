; ==============================================================================
; Technics SX-WSA1R -- prom_c (CPU 2, IC28) -- 0xFA5949-0xFA7E2B  the leaf helpers the voice-parameter module calls
; ==============================================================================
;
; 5,936 lines moved out of prom_c/wsa1_prom_c.s by notes/prom_c_split.py.  The master
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
; Banner-declared.  EGEnv_* envelope evaluators, Clamp_*, DetuneCurve_*,
; KeyZone_*, VoiceSubsystem_Init and the voice allocator.
;
; >>> END OF EXTRACTION HEADER -- everything below is verbatim from the master

; ==============================================================================
; 0xFA5949-0xFA7E2B -- ★ THE LEAF HELPERS THE VOICE-PARAMETER MODULE CALLS
;                      68 routines, no tables, 9,443 bytes
; ==============================================================================
;
; Converted immediately after the block below it, and chosen the same way: once
; 0xFA7E2C-0xFABE2F was converted, `python3 notes/prom_c_frontier_src.py --clusters`
; put this range at the top with 39 targets and 197 sites in one 5,919-byte run --
; the module's own callees becoming visible the moment the module did.  Taken with
; the three isolated targets just below it the range held
;
;   0xFA5949-0xFA7E2B  ->  42 target(s), 208 site(s), 9443 byte(s) wide
;       (python3 notes/prom_c_frontier_src.py --range 0xFA5949-0xFA7E2B)
;
; i.e. 42 of the 98 frontier targets and 208 of the 346 sites.
;
; ★ IT IS A LEAF LAYER, and the call census says so: 254 literal call sites reach it
;   from outside, 54 from inside, and the outside ones are dominated by the block
;   below -- Voice_StageRegs_0800_B_ModeGe3 (17), Voice_StageRegs_0800_A (15), Voice_StageRegs_0800_B_ModeLt3 (15), Voice_StageRegs_09C0_0A00_0A40_AB (13),
;   Voice_StageRegs_0900_0940_0980_AB (10), Voice_StageRegs_0800_CD (9), Voice_StageChanSel_Reg0440_Reg0480 (8), Voice_StageRegs_0500_08C0_AB (8),
;   VoiceParams_Compute_A (7) and so on.  ⚠ An earlier draft of this list named
;   sub_FAA61A (10); that address was a BYTE-PATTERN false entry, and with the
;   filter its sites belong to Voice_StageRegs_0800_A.
;   ✔ Re-measured at the end of round 3: ALL 256 are now in converted code
;   (46 were still `.incbin` when this block was converted).  The tally is
;   `python3 notes/prom_c_module_map.py 0xFA5949 0xFA7E2C`.  ⚠ The figures were
;   256/55 for most of round 3; the difference is byte-pattern noise the tool now
;   filters out (see the ★ paragraph in the block below).
;
; ★ NO COMPUTED-GOTO TABLES.  `python3 notes/prom_c_jumptables.py 0xFA5949 0xFA7E2C`
;   prints an empty table, so unlike the block below this one a straight linear
;   decode of the whole range is sound -- and it was still verified segment by
;   segment rather than assumed.
;
; ★★ THREE PAIRS OF ROUTINES IN HERE ARE BYTE-IDENTICAL, not merely similar:
;
;       0xFA727D / 0xFA72B3    54 bytes, 0 differ
;       0xFA7598 / 0xFA78C6    34 bytes, 0 differ
;       0xFA766C / 0xFA7D03    70 bytes, 0 differ
;
;   (`python3 notes/prom_c_module_map.py 0xFA5949 0xFA7E2C --dups`.)
;   ⚠ AND THE COPIES ARE NOT EQUALLY USED.  0xFA7598 is the most-called address in
;   the whole prom_c frontier -- 60 literal sites -- while its byte-for-byte twin
;   0xFA78C6 has ZERO.  0xFA766C has 14 sites and its twin 0xFA7D03 has 1.  A call
;   through a register is invisible to that scan, so "zero" is "no literal transfer
;   found", not "dead code"; but it is not a small difference and it is not noise.
;
; ★ ONE OPEN QUESTION ELSEWHERE IN THIS FILE IS CLOSED HERE.  The
;   MidiIn_ParseRingAndDispatch header listed as Unknown "the call to 0xFA5949 at
;   0xFB061F, made with the byte count pushed, before any parsing happens".
;   0xFA5949 is fifteen bytes long and its whole body is
;   `ld BC,(XIZ+0x08) / ld (0x008678),BC` -- it stores its argument at 0x008678 and
;   returns.  That header now says so.
;
; ⚠ AS ABOVE, NO ROUTINE HERE IS NAMED FOR WHAT IT DOES.  Each header states the
;   frame, the argument slots read, the absolute addresses read and written, the
;   calls made and the call sites -- operands and byte scans, not interpretation.
;
; ★ REGENERATE (the same pipeline as the block below):
;       python3 notes/gen_prom_c_block.py --start 0xFA5949 --end 0xFA7E2C > /tmp/m2.s
;       python3 notes/gen_prom_c_block_headers.py --start 0xFA5949 --end 0xFA7E2C \
;           --labels > /tmp/m2.labels
;       python3 notes/gen_prom_c_block_headers.py --start 0xFA5949 --end 0xFA7E2C \
;           --headers > /tmp/m2.headers
;       python3 notes/prom_c_apply_headers.py /tmp/m2.s /tmp/m2.labels /tmp/m2.headers \
;           > /tmp/m2.final.s
;       python3 notes/prom_c_verify_fragment.py c 0xFA5949 /tmp/m2.final.s
; ==============================================================================
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `MidiIn_StoreRingBacklog` is now `MidiIn_StoreRingBacklog`.
;   GRADE PROVEN.  WHY `MidiIn_StoreRingBacklog`:
;   the whole body is `(0x008678) = (XIZ+0x08)`, and its ONE caller pushes the
;   ring byte count it has just guarded (`cp DE,4` 0xFB0619, `push DE` 0xFB061E).
;   0x008678 is read only by ChanAlloc_ForNoteRequest, which compares it against
;   0x20/0x30/0x40/0x50 to pick how hard to work for a free channel.
; MidiIn_StoreRingBacklog -- 0xFA5949..0xFA5957 (15 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFB061F in MidiIn_ParseRingAndDispatch__FB0619
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x008678
; Evidence: the listing below is the byte-identical round-trip of 0xFA5949-0xFA5957
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
MidiIn_StoreRingBacklog:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA5949  link XIZ,0x0000
	ld	bc, (xiz+8)                             ; FA594D  ld BC,(XIZ+0x08)
	ld	(0x8678:24), bc                        ; FA5950  ld (0x008678),BC
	unlk32 xiz                                 ; FA5955  unlk XIZ
	ret                                        ; FA5957  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `MidiNote_StoreStatusBit3` is now `MidiNote_StoreStatusBit3`.
;   GRADE PROVEN.  WHY `MidiNote_StoreStatusBit3`:
;   the whole body is `(0x008677) = (XIZ+0x08)`, and its ONE caller pushes
;   `msg[0] & 0x08` (0xFB3F50-0xFB3F55) -- bit 3 of the message's status byte.
;   0x008677 is read only by ChanAlloc_ForNoteRequest, as the flag that chooses
;   between two sets of backlog thresholds.
; MidiNote_StoreStatusBit3 -- 0xFA5958..0xFA5966 (15 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFB3F56 in MidiNote_Dispatch
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x008677
; Evidence: the listing below is the byte-identical round-trip of 0xFA5958-0xFA5966
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
MidiNote_StoreStatusBit3:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA5958  link XIZ,0x0000
	ld	c, (xiz+8)                              ; FA595C  ld C,(XIZ+0x08)
	ld	(0x8677:24), c                         ; FA595F  ld (0x008677),C
	unlk32 xiz                                 ; FA5964  unlk XIZ
	ret                                        ; FA5966  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `Rec0E3E_GroupOfIndex` is now `Rec0E3E_GroupOfIndex`.
;   GRADE PROVEN.  WHY `Rec0E3E_GroupOfIndex`:
;   body: index < 0x40 -> 0, 0x40..0x7F -> 4, 0x80..0xBF -> 8, else 0.  Both
;   callers pass a 0x0E3E slot index and hand the result straight to
;   Rec0E3E_MoveToList as its COLUMN argument, so the three values are the three
;   64-slot groups the 192-record array is divided into.
; Rec0E3E_GroupOfIndex -- 0xFA5967..0xFA598B (37 bytes)
;
; Called from: no site outside this module.
;          3 site(s) inside this module:
;          0xFA5D4B 0xFA5E62 0xFA62B5
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA5967-0xFA598B
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
Rec0E3E_GroupOfIndex:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA5967  link XIZ,0x0000
	pushw	hl                                   ; FA596B  push HL
	ld	h, (xiz+8)                              ; FA596C  ld H,(XIZ+0x08)
	cp	h, 64                                   ; FA596F  cp H,0x40
	jr c, sub_FA5967__FA5986                   ; FA5972  jr C,0xfa5986
	cp	h, 0x80                                 ; FA5974  cp H,0x80
	jr nc, sub_FA5967__FA597D                  ; FA5977  jr NC,0xfa597d
	ldb	a, 4                                   ; FA5979  ld A,0x04
	jr sub_FA5967__FA5988                      ; FA597B  jr T,0xfa5988
sub_FA5967__FA597D:
	cp	h, 0xC0                                 ; FA597D  cp H,0xc0
	jr nc, sub_FA5967__FA5986                  ; FA5980  jr NC,0xfa5986
	ldb	a, 8                                   ; FA5982  ld A,0x08
	jr sub_FA5967__FA5988                      ; FA5984  jr T,0xfa5988
sub_FA5967__FA5986:
	sub	a, a                                   ; FA5986  sub A,A
sub_FA5967__FA5988:
	popw	hl                                    ; FA5988  pop HL
	unlk32 xiz                                 ; FA5989  unlk XIZ
	ret                                        ; FA598B  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `Rec0E3E_IndexWithinGroup` is now `Rec0E3E_IndexWithinGroup`.
;   GRADE PROVEN.  WHY `Rec0E3E_IndexWithinGroup`:
;   body: selector&3 == 0 or 1 -> i & 0x3F; == 2 -> (i - 0x40) & 0x7F;
;   == 3 -> i & 0x7F.  Every caller passes a 0x0E3E slot index and uses the
;   result as the low byte of a (selector, index) pair.
; Rec0E3E_IndexWithinGroup -- 0xFA598C..0xFA59CD (66 bytes)
;
; Called from: no site outside this module.
;          5 site(s) inside this module:
;          0xFA5F60 0xFA5FC2 0xFA6002 0xFA60E1 0xFA6189
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA598C-0xFA59CD
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
Rec0E3E_IndexWithinGroup:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA598C  link XIZ,0x0000
	pushw	hl                                   ; FA5990  push HL
	ld	h, (xiz+8)                              ; FA5991  ld H,(XIZ+0x08)
	ld	c, (xiz+10)                             ; FA5994  ld C,(XIZ+0x0a)
	and	c, 3                                   ; FA5997  and C,0x03
	extz	bc                                    ; FA599A  extz BC
	cps	bc, 0                                  ; FA599C  cp BC,0
	jr z, sub_FA598C__FA59AE                   ; FA599E  jr Z,0xfa59ae
	cps	bc, 1                                  ; FA59A0  cp BC,1
	jr z, sub_FA598C__FA59AE                   ; FA59A2  jr Z,0xfa59ae
	cps	bc, 2                                  ; FA59A4  cp BC,2
	jr z, sub_FA598C__FA59B7                   ; FA59A6  jr Z,0xfa59b7
	cps	bc, 3                                  ; FA59A8  cp BC,3
	jr z, sub_FA598C__FA59C3                   ; FA59AA  jr Z,0xfa59c3
	jr sub_FA598C__FA59CA                      ; FA59AC  jr T,0xfa59ca
sub_FA598C__FA59AE:
	ld	c, h                                    ; FA59AE  ld C,H
	and	c, 63                                  ; FA59B0  and C,0x3f
	ld	a, c                                    ; FA59B3  ld A,C
	jr sub_FA598C__FA59CA                      ; FA59B5  jr T,0xfa59ca
sub_FA598C__FA59B7:
	ld	c, h                                    ; FA59B7  ld C,H
	sub	c, 64                                  ; FA59B9  sub C,0x40
	res	7, c                                   ; FA59BC  res 0x07,C
	ld	a, c                                    ; FA59BF  ld A,C
	jr sub_FA598C__FA59CA                      ; FA59C1  jr T,0xfa59ca
sub_FA598C__FA59C3:
	ld	c, h                                    ; FA59C3  ld C,H
	res	7, c                                   ; FA59C5  res 0x07,C
	ld	a, c                                    ; FA59C8  ld A,C
sub_FA598C__FA59CA:
	popw	hl                                    ; FA59CA  pop HL
	unlk32 xiz                                 ; FA59CB  unlk XIZ
	ret                                        ; FA59CD  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `Rec11FE_UnlinkFromRing` is now `Rec11FE_UnlinkFromRing`.
;   GRADE PROVEN.  WHY `Rec11FE_UnlinkFromRing`:
;   body: with rec = 0x11FE + 12*chan and ring r, it does
;   `next=rec[r]; prev=rec[r+4]; A[prev][r]=next; A[next][r+4]=prev;`
;   `rec[r]=rec[r+4]=chan` -- a circular doubly-linked unlink and self-link.
; Rec11FE_UnlinkFromRing -- 0xFA59CE..0xFA5A35 (104 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFA5B44 0xFA5D65
; Inputs:  frame `link XIZ,-6`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA59CE-0xFA5A35
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
Rec11FE_UnlinkFromRing:
	link32 0xEE, 0x0C, 0xFA, 0xFF              ; FA59CE  link XIZ,0xfffa
	pushw	hl                                   ; FA59D2  push HL
	pushw	de                                   ; FA59D3  push DE
	push	xix                                   ; FA59D4  push XIX
	lda	xix, (0x11FE:16)                      ; FA59D5  lda XIX,0x11fe
	ld	h, (xiz+8)                              ; FA59D9  ld H,(XIZ+0x08)
	ldb	c, 12                                  ; FA59DC  ld C,0x0c
	mul8rr	c, h                                ; FA59DE  mul BC,H
	ld	de, bc                                  ; FA59E0  ld DE,BC
	ld	wa, (xiz+10)                            ; FA59E2  ld WA,(XIZ+0x0a)
	extz	wa                                    ; FA59E5  extz WA
	ld	(xiz-2), wa                             ; FA59E7  ld (XIZ+0xfe),WA
	add	bc, wa                                 ; FA59EA  add BC,WA
	ld	(xiz-4), bc                             ; FA59EC  ld (XIZ+0xfc),BC
	extz	xix                                   ; FA59EF  extz XIX
	extpfx5 0xC3, 0x07, 0xF0, 0xE4, 0x27       ; FA59F1  ld L,(XIX+BC)
	ld	de, bc                                  ; FA59F6  ld DE,BC
	inc	4, de                                  ; FA59F8  inc 4,DE
	extpfx5 0xC3, 0x07, 0xF0, 0xE8, 0x23       ; FA59FA  ld C,(XIX+DE)
	ld	(xiz-6), c                              ; FA59FF  ld (XIZ+0xfa),C
	mul	c, 12                                  ; FA5A02  mul C,0x0c
	add	bc, wa                                 ; FA5A05  add BC,WA
	extz	xbc                                   ; FA5A07  extz XBC
	add	bc, ix                                 ; FA5A09  add BC,IX
	ld	(xbc), l                                ; FA5A0B  ld (XBC),L
	ldb	c, 12                                  ; FA5A0D  ld C,0x0c
	mul8rr	c, l                                ; FA5A0F  mul BC,L
	extpfx3 0x9E, 0xFE, 0x81                   ; FA5A11  add BC,(XIZ+0xfe)
	inc	4, bc                                  ; FA5A14  inc 4,BC
	extz	xbc                                   ; FA5A16  extz XBC
	add	bc, ix                                 ; FA5A18  add BC,IX
	ld	a, (xiz-6)                              ; FA5A1A  ld A,(XIZ+0xfa)
	ld	(xbc), a                                ; FA5A1D  ld (XBC),A
	ld	bc, ix                                  ; FA5A1F  ld BC,IX
	extz	xbc                                   ; FA5A21  extz XBC
	extpfx3 0x9E, 0xFC, 0x81                   ; FA5A23  add BC,(XIZ+0xfc)
	ld	(xbc), h                                ; FA5A26  ld (XBC),H
	ld	bc, ix                                  ; FA5A28  ld BC,IX
	extz	xbc                                   ; FA5A2A  extz XBC
	add	bc, de                                 ; FA5A2C  add BC,DE
	ld	(xbc), h                                ; FA5A2E  ld (XBC),H
	pop	xix                                    ; FA5A30  pop XIX
	popw	de                                    ; FA5A31  pop DE
	popw	hl                                    ; FA5A32  pop HL
	unlk32 xiz                                 ; FA5A33  unlk XIZ
	ret                                        ; FA5A35  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `Rec11FE_InsertIntoRing` is now `Rec11FE_InsertIntoRing`.
;   GRADE PROVEN.  WHY `Rec11FE_InsertIntoRing`:
;   body: the same unlink, then splices `chan` in beside the third argument's
;   record on ring r, using the same next=[r] / prev=[r+4] pair.
; Rec11FE_InsertIntoRing -- 0xFA5A36..0xFA5AC9 (148 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFA5B54
; Inputs:  frame `link XIZ,-8`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA5A36-0xFA5AC9
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
Rec11FE_InsertIntoRing:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FA5A36  link XIZ,0xfff8
	pushw	hl                                   ; FA5A3A  push HL
	pushw	de                                   ; FA5A3B  push DE
	push	xix                                   ; FA5A3C  push XIX
	lda	xix, (0x11FE:16)                      ; FA5A3D  lda XIX,0x11fe
	ld	h, (xiz+8)                              ; FA5A41  ld H,(XIZ+0x08)
	ldb	l, 12                                  ; FA5A44  ld L,0x0c
	ld	c, h                                    ; FA5A46  ld C,H
	mul8rr	c, l                                ; FA5A48  mul BC,L
	ld	de, bc                                  ; FA5A4A  ld DE,BC
	ld	wa, (xiz+10)                            ; FA5A4C  ld WA,(XIZ+0x0a)
	extz	wa                                    ; FA5A4F  extz WA
	ld	(xiz-2), wa                             ; FA5A51  ld (XIZ+0xfe),WA
	add	bc, wa                                 ; FA5A54  add BC,WA
	ld	(xiz-4), bc                             ; FA5A56  ld (XIZ+0xfc),BC
	extz	xix                                   ; FA5A59  extz XIX
	extpfx5 0xC3, 0x07, 0xF0, 0xE4, 0x24       ; FA5A5B  ld D,(XIX+BC)
	inc	4, bc                                  ; FA5A60  inc 4,BC
	ld	(xiz-6), bc                             ; FA5A62  ld (XIZ+0xfa),BC
	extpfx5 0xC3, 0x07, 0xF0, 0xE4, 0x25       ; FA5A65  ld E,(XIX+BC)
	ld	c, e                                    ; FA5A6A  ld C,E
	mul8rr	c, l                                ; FA5A6C  mul BC,L
	add	bc, wa                                 ; FA5A6E  add BC,WA
	extz	xbc                                   ; FA5A70  extz XBC
	add	bc, ix                                 ; FA5A72  add BC,IX
	ld	(xbc), d                                ; FA5A74  ld (XBC),D
	ld	c, d                                    ; FA5A76  ld C,D
	mul8rr	c, l                                ; FA5A78  mul BC,L
	extpfx3 0x9E, 0xFE, 0x81                   ; FA5A7A  add BC,(XIZ+0xfe)
	inc	4, bc                                  ; FA5A7D  inc 4,BC
	extz	xbc                                   ; FA5A7F  extz XBC
	add	bc, ix                                 ; FA5A81  add BC,IX
	ld	(xbc), e                                ; FA5A83  ld (XBC),E
	ld	c, (xiz+12)                             ; FA5A85  ld C,(XIZ+0x0c)
	mul8rr	c, l                                ; FA5A88  mul BC,L
	extpfx3 0x9E, 0xFE, 0x81                   ; FA5A8A  add BC,(XIZ+0xfe)
	ld	de, bc                                  ; FA5A8D  ld DE,BC
	inc	4, de                                  ; FA5A8F  inc 4,DE
	extpfx5 0xC3, 0x07, 0xF0, 0xE8, 0x23       ; FA5A91  ld C,(XIX+DE)
	ld	(xiz-8), c                              ; FA5A96  ld (XIZ+0xf8),C
	mul8rr	c, l                                ; FA5A99  mul BC,L
	extpfx3 0x9E, 0xFE, 0x81                   ; FA5A9B  add BC,(XIZ+0xfe)
	extz	xbc                                   ; FA5A9E  extz XBC
	add	bc, ix                                 ; FA5AA0  add BC,IX
	ld	(xbc), h                                ; FA5AA2  ld (XBC),H
	ld	bc, ix                                  ; FA5AA4  ld BC,IX
	extz	xbc                                   ; FA5AA6  extz XBC
	extpfx3 0x9E, 0xFA, 0x81                   ; FA5AA8  add BC,(XIZ+0xfa)
	ld	a, (xiz-8)                              ; FA5AAB  ld A,(XIZ+0xf8)
	ld	(xbc), a                                ; FA5AAE  ld (XBC),A
	ld	bc, ix                                  ; FA5AB0  ld BC,IX
	extz	xbc                                   ; FA5AB2  extz XBC
	extpfx3 0x9E, 0xFC, 0x81                   ; FA5AB4  add BC,(XIZ+0xfc)
	ld	a, (xiz+12)                             ; FA5AB7  ld A,(XIZ+0x0c)
	ld	(xbc), a                                ; FA5ABA  ld (XBC),A
	ld	bc, ix                                  ; FA5ABC  ld BC,IX
	extz	xbc                                   ; FA5ABE  extz XBC
	add	bc, de                                 ; FA5AC0  add BC,DE
	ld	(xbc), h                                ; FA5AC2  ld (XBC),H
	pop	xix                                    ; FA5AC4  pop XIX
	popw	de                                    ; FA5AC5  pop DE
	popw	hl                                    ; FA5AC6  pop HL
	unlk32 xiz                                 ; FA5AC7  unlk XIZ
	ret                                        ; FA5AC9  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `Rec11FE_BindRingToSlot` is now `Rec11FE_BindRingToSlot`.
;   GRADE PROVEN.  WHY `Rec11FE_BindRingToSlot`:
;   body: detaches chan's ring r from the 0x0E3E slot it currently names
;   (handing that slot's owner byte [+4] to the next channel on the ring, or
;   0xFF when chan was alone), then links chan into the new slot's ring and
;   stores the new slot index in rec11FE[chan][8+r].
; Rec11FE_BindRingToSlot -- 0xFA5ACA..0xFA5B6F (166 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFA5FBA 0xFA5FFA
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFA59CE = Rec11FE_UnlinkFromRing, 0xFA5A36 = Rec11FE_InsertIntoRing
; Evidence: the listing below is the byte-identical round-trip of 0xFA5ACA-0xFA5B6F
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
Rec11FE_BindRingToSlot:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FA5ACA  link XIZ,0xfffc
	push	xhl                                   ; FA5ACE  push XHL
	pushw	de                                   ; FA5ACF  push DE
	pushw	ix                                   ; FA5AD0  push IX
	ld	e, (xiz+8)                              ; FA5AD1  ld E,(XIZ+0x08)
	ldb	c, 12                                  ; FA5AD4  ld C,0x0c
	mul8rr	c, e                                ; FA5AD6  mul BC,E
	ld	(xiz-4), bc                             ; FA5AD8  ld (XIZ+0xfc),BC
	ldw	wa, 0x11FE                             ; FA5ADB  ld WA,0x11fe
	add	wa, bc                                 ; FA5ADE  add WA,BC
	ld	(xiz-2), wa                             ; FA5AE0  ld (XIZ+0xfe),WA
	ld	ix, (xiz+10)                            ; FA5AE3  ld IX,(XIZ+0x0a)
	extz	ix                                    ; FA5AE6  extz IX
	ld	bc, ix                                  ; FA5AE8  ld BC,IX
	inc	8, bc                                  ; FA5AEA  inc 0,BC
	extz	xwa                                   ; FA5AEC  extz XWA
	extpfx5 0xC3, 0x07, 0xE0, 0xE4, 0x26       ; FA5AEE  ld H,(XWA+BC)
	cp	h, 0xC0                                 ; FA5AF3  cp H,0xc0
	jr nc, sub_FA5ACA__FA5B23                  ; FA5AF6  jr NC,0xfa5b23
	ldb	c, 5                                   ; FA5AF8  ld C,0x05
	mul8rr	c, h                                ; FA5AFA  mul BC,H
	ld	(xiz-4), bc                             ; FA5AFC  ld (XIZ+0xfc),BC
	ldw	hl, 0xE3E                              ; FA5AFF  ld HL,0x0e3e
	add	hl, bc                                 ; FA5B02  add HL,BC
	extz	xhl                                   ; FA5B04  extz XHL
	ld	c, (xhl+4)                              ; FA5B06  ld C,(XHL+0x04)
	cp	c, e                                    ; FA5B09  cp C,E
	jr nz, sub_FA5ACA__FA5B23                  ; FA5B0B  jr NZ,0xfa5b23
	extpfx5 0xC3, 0x07, 0xE0, 0xF0, 0x24       ; FA5B0D  ld D,(XWA+IX)
	cp	d, e                                    ; FA5B12  cp D,E
	jr z, sub_FA5ACA__FA5B1D                   ; FA5B14  jr Z,0xfa5b1d
	extz	xhl                                   ; FA5B16  extz XHL
	ld	(xhl+4), d                              ; FA5B18  ld (XHL+0x04),D
	jr sub_FA5ACA__FA5B23                      ; FA5B1B  jr T,0xfa5b23
sub_FA5ACA__FA5B1D:
	extz	xhl                                   ; FA5B1D  extz XHL
	ld	(xhl+4), 0xFF                           ; FA5B1F  ld (XHL+0x04),0xff
sub_FA5ACA__FA5B23:
	ldb	c, 5                                   ; FA5B23  ld C,0x05
	extpfx3 0x8E, 0x0C, 0x43                   ; FA5B25  mul BC,(XIZ+0x0c)
	ld	ix, bc                                  ; FA5B28  ld IX,BC
	ldw	hl, 0xE3E                              ; FA5B2A  ld HL,0x0e3e
	add	hl, bc                                 ; FA5B2D  add HL,BC
	extz	xhl                                   ; FA5B2F  extz XHL
	ld	d, (xhl+4)                              ; FA5B31  ld D,(XHL+0x04)
	cp	d, 64                                   ; FA5B34  cp D,0x40
	jr ule, sub_FA5ACA__FA5B4A                 ; FA5B37  jr ULE,0xfa5b4a
	extz	xhl                                   ; FA5B39  extz XHL
	ld	(xhl+4), e                              ; FA5B3B  ld (XHL+0x04),E
	push	0                                     ; FA5B3E  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FA5B40  push (XIZ+0x0a)
	pushw	de                                   ; FA5B43  push DE
	calr (0xFA59CE - 0xFA5B47)                 ; FA5B44  calr 0xfa59ce
	pop	xiy                                    ; FA5B47  pop XIY
	jr sub_FA5ACA__FA5B59                      ; FA5B48  jr T,0xfa5b59
sub_FA5ACA__FA5B4A:
	push	0                                     ; FA5B4A  push 0x00
	push	d                                     ; FA5B4C  push D
	push	0                                     ; FA5B4E  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FA5B50  push (XIZ+0x0a)
	pushw	de                                   ; FA5B53  push DE
	calr (0xFA5A36 - 0xFA5B57)                 ; FA5B54  calr 0xfa5a36
	inc	6, xsp                                 ; FA5B57  inc 6,XSP
sub_FA5ACA__FA5B59:
	ld	bc, (xiz+10)                            ; FA5B59  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FA5B5C  extz BC
	inc	8, bc                                  ; FA5B5E  inc 0,BC
	extz	xbc                                   ; FA5B60  extz XBC
	extpfx3 0x9E, 0xFE, 0x81                   ; FA5B62  add BC,(XIZ+0xfe)
	ld	a, (xiz+12)                             ; FA5B65  ld A,(XIZ+0x0c)
	ld	(xbc), a                                ; FA5B68  ld (XBC),A
	popw	ix                                    ; FA5B6A  pop IX
	popw	de                                    ; FA5B6B  pop DE
	pop	xhl                                    ; FA5B6C  pop XHL
	unlk32 xiz                                 ; FA5B6D  unlk XIZ
	ret                                        ; FA5B6F  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `Rec0E3E_UnlinkFromRing` is now `Rec0E3E_UnlinkFromRing`.
;   GRADE PROVEN.  WHY `Rec0E3E_UnlinkFromRing`:
;   body: with s = 0x0E3E + 5*index, `next=s[0]; prev=s[1];`
;   `S[prev][0]=next; S[next][1]=prev; s[0]=s[1]=index` -- unlink + self-link.
; Rec0E3E_UnlinkFromRing -- 0xFA5B70..0xFA5BC6 (87 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFA5CBE
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA5B70-0xFA5BC6
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
Rec0E3E_UnlinkFromRing:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FA5B70  link XIZ,0xfffc
	pushw	hl                                   ; FA5B74  push HL
	pushw	de                                   ; FA5B75  push DE
	push	xix                                   ; FA5B76  push XIX
	lda	xix, (0xE3E:16)                       ; FA5B77  lda XIX,0x0e3e
	ld	h, (xiz+8)                              ; FA5B7B  ld H,(XIZ+0x08)
	ldb	c, 5                                   ; FA5B7E  ld C,0x05
	mul8rr	c, h                                ; FA5B80  mul BC,H
	ld	de, bc                                  ; FA5B82  ld DE,BC
	extz	xix                                   ; FA5B84  extz XIX
	extpfx5 0xC3, 0x07, 0xF0, 0xE4, 0x27       ; FA5B86  ld L,(XIX+BC)
	inc	1, bc                                  ; FA5B8B  inc 1,BC
	ld	(xiz-2), bc                             ; FA5B8D  ld (XIZ+0xfe),BC
	extpfx5 0xC3, 0x07, 0xF0, 0xE4, 0x21       ; FA5B90  ld A,(XIX+BC)
	ld	(xiz-4), a                              ; FA5B95  ld (XIZ+0xfc),A
	mul	a, 5                                   ; FA5B98  mul A,0x05
	extz	xwa                                   ; FA5B9B  extz XWA
	add	wa, ix                                 ; FA5B9D  add WA,IX
	ld	(xwa), l                                ; FA5B9F  ld (XWA),L
	ldb	c, 5                                   ; FA5BA1  ld C,0x05
	mul8rr	c, l                                ; FA5BA3  mul BC,L
	inc	1, bc                                  ; FA5BA5  inc 1,BC
	extz	xbc                                   ; FA5BA7  extz XBC
	add	bc, ix                                 ; FA5BA9  add BC,IX
	ld	a, (xiz-4)                              ; FA5BAB  ld A,(XIZ+0xfc)
	ld	(xbc), a                                ; FA5BAE  ld (XBC),A
	ld	bc, ix                                  ; FA5BB0  ld BC,IX
	extz	xbc                                   ; FA5BB2  extz XBC
	add	bc, de                                 ; FA5BB4  add BC,DE
	ld	(xbc), h                                ; FA5BB6  ld (XBC),H
	ld	bc, ix                                  ; FA5BB8  ld BC,IX
	extz	xbc                                   ; FA5BBA  extz XBC
	extpfx3 0x9E, 0xFE, 0x81                   ; FA5BBC  add BC,(XIZ+0xfe)
	ld	(xbc), h                                ; FA5BBF  ld (XBC),H
	pop	xix                                    ; FA5BC1  pop XIX
	popw	de                                    ; FA5BC2  pop DE
	popw	hl                                    ; FA5BC3  pop HL
	unlk32 xiz                                 ; FA5BC4  unlk XIZ
	ret                                        ; FA5BC6  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `Rec0E3E_InsertBeforeInRing` is now `Rec0E3E_InsertBeforeInRing`.
;   GRADE PROVEN.  WHY `Rec0E3E_InsertBeforeInRing`:
;   body: the same unlink, then inserts the first argument's record immediately
;   before the second's in the [0]=next / [1]=prev ring.
; Rec0E3E_InsertBeforeInRing -- 0xFA5BC7..0xFA5C42 (124 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFA5CC9
; Inputs:  frame `link XIZ,-6`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA5BC7-0xFA5C42
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
Rec0E3E_InsertBeforeInRing:
	link32 0xEE, 0x0C, 0xFA, 0xFF              ; FA5BC7  link XIZ,0xfffa
	pushw	hl                                   ; FA5BCB  push HL
	pushw	de                                   ; FA5BCC  push DE
	push	xix                                   ; FA5BCD  push XIX
	lda	xix, (0xE3E:16)                       ; FA5BCE  lda XIX,0x0e3e
	ld	h, (xiz+8)                              ; FA5BD2  ld H,(XIZ+0x08)
	ldb	c, 5                                   ; FA5BD5  ld C,0x05
	mul8rr	c, h                                ; FA5BD7  mul BC,H
	ld	de, bc                                  ; FA5BD9  ld DE,BC
	extz	xix                                   ; FA5BDB  extz XIX
	extpfx5 0xC3, 0x07, 0xF0, 0xE4, 0x27       ; FA5BDD  ld L,(XIX+BC)
	inc	1, bc                                  ; FA5BE2  inc 1,BC
	ld	(xiz-2), bc                             ; FA5BE4  ld (XIZ+0xfe),BC
	extpfx5 0xC3, 0x07, 0xF0, 0xE4, 0x21       ; FA5BE7  ld A,(XIX+BC)
	ld	(xiz-4), a                              ; FA5BEC  ld (XIZ+0xfc),A
	mul	a, 5                                   ; FA5BEF  mul A,0x05
	extz	xwa                                   ; FA5BF2  extz XWA
	add	wa, ix                                 ; FA5BF4  add WA,IX
	ld	(xwa), l                                ; FA5BF6  ld (XWA),L
	ldb	c, 5                                   ; FA5BF8  ld C,0x05
	mul8rr	c, l                                ; FA5BFA  mul BC,L
	inc	1, bc                                  ; FA5BFC  inc 1,BC
	extz	xbc                                   ; FA5BFE  extz XBC
	add	bc, ix                                 ; FA5C00  add BC,IX
	ld	a, (xiz-4)                              ; FA5C02  ld A,(XIZ+0xfc)
	ld	(xbc), a                                ; FA5C05  ld (XBC),A
	ldb	c, 5                                   ; FA5C07  ld C,0x05
	extpfx3 0x8E, 0x0A, 0x43                   ; FA5C09  mul BC,(XIZ+0x0a)
	inc	1, bc                                  ; FA5C0C  inc 1,BC
	ld	(xiz-6), bc                             ; FA5C0E  ld (XIZ+0xfa),BC
	extpfx5 0xC3, 0x07, 0xF0, 0xE4, 0x27       ; FA5C11  ld L,(XIX+BC)
	ldb	a, 5                                   ; FA5C16  ld A,0x05
	mul8rr	a, l                                ; FA5C18  mul WA,L
	extz	xwa                                   ; FA5C1A  extz XWA
	add	wa, ix                                 ; FA5C1C  add WA,IX
	ld	(xwa), h                                ; FA5C1E  ld (XWA),H
	ld	bc, ix                                  ; FA5C20  ld BC,IX
	extz	xbc                                   ; FA5C22  extz XBC
	extpfx3 0x9E, 0xFE, 0x81                   ; FA5C24  add BC,(XIZ+0xfe)
	ld	(xbc), l                                ; FA5C27  ld (XBC),L
	ld	bc, ix                                  ; FA5C29  ld BC,IX
	extz	xbc                                   ; FA5C2B  extz XBC
	add	bc, de                                 ; FA5C2D  add BC,DE
	ld	a, (xiz+10)                             ; FA5C2F  ld A,(XIZ+0x0a)
	ld	(xbc), a                                ; FA5C32  ld (XBC),A
	ld	bc, ix                                  ; FA5C34  ld BC,IX
	extz	xbc                                   ; FA5C36  extz XBC
	extpfx3 0x9E, 0xFA, 0x81                   ; FA5C38  add BC,(XIZ+0xfa)
	ld	(xbc), h                                ; FA5C3B  ld (XBC),H
	pop	xix                                    ; FA5C3D  pop XIX
	popw	de                                    ; FA5C3E  pop DE
	popw	hl                                    ; FA5C3F  pop HL
	unlk32 xiz                                 ; FA5C40  unlk XIZ
	ret                                        ; FA5C42  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `Rec0E3E_MoveToList` is now `Rec0E3E_MoveToList`.
;   GRADE PROVEN.  WHY `Rec0E3E_MoveToList`:
;   body: takes slot `s` off the list named by its own s[+2] (part) and s[+3]
;   (column) in the head table at 0x0AA8, links it onto list (arg2, arg3) --
;   self-linking when that head reads 0xFF -- and then stores arg2 into s[+2]
;   and arg3 into s[+3].
; Rec0E3E_MoveToList -- 0xFA5C43..0xFA5CE8 (166 bytes)
;
; Called from: no site outside this module.
;          4 site(s) inside this module:
;          0xFA5D56 0xFA5E6E 0xFA5FED 0xFA62C1
; Inputs:  frame `link XIZ,-6`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFA5B70 = Rec0E3E_UnlinkFromRing, 0xFA5BC7 = Rec0E3E_InsertBeforeInRing
; Evidence: the listing below is the byte-identical round-trip of 0xFA5C43-0xFA5CE8
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
Rec0E3E_MoveToList:
	link32 0xEE, 0x0C, 0xFA, 0xFF              ; FA5C43  link XIZ,0xfffa
	pushw	hl                                   ; FA5C47  push HL
	pushw	de                                   ; FA5C48  push DE
	push	xix                                   ; FA5C49  push XIX
	ld	e, (xiz+8)                              ; FA5C4A  ld E,(XIZ+0x08)
	ldb	c, 5                                   ; FA5C4D  ld C,0x05
	mul8rr	c, e                                ; FA5C4F  mul BC,E
	ld	(xiz-4), bc                             ; FA5C51  ld (XIZ+0xfc),BC
	ldw	wa, 0xE3E                              ; FA5C54  ld WA,0x0e3e
	add	wa, bc                                 ; FA5C57  add WA,BC
	ld	(xiz-2), wa                             ; FA5C59  ld (XIZ+0xfe),WA
	extz	xwa                                   ; FA5C5C  extz XWA
	ld	c, (xwa+2)                              ; FA5C5E  ld C,(XWA+0x02)
	mul	c, 27                                  ; FA5C61  mul C,0x1b
	ld	(xiz-6), bc                             ; FA5C64  ld (XIZ+0xfa),BC
	ldw	ix, 0xAA8                              ; FA5C67  ld IX,0x0aa8
	add	ix, bc                                 ; FA5C6A  add IX,BC
	ld	c, (xwa+3)                              ; FA5C6C  ld C,(XWA+0x03)
	extz	bc                                    ; FA5C6F  extz BC
	ld	hl, bc                                  ; FA5C71  ld HL,BC
	extz	xix                                   ; FA5C73  extz XIX
	extpfx5 0xC3, 0x07, 0xF0, 0xE4, 0x23       ; FA5C75  ld C,(XIX+BC)
	cp	c, e                                    ; FA5C7A  cp C,E
	jr nz, sub_FA5C43__FA5C97                  ; FA5C7C  jr NZ,0xfa5c97
	ld	d, (xwa)                                ; FA5C7E  ld D,(XWA)
	cp	d, e                                    ; FA5C80  cp D,E
	jr z, sub_FA5C43__FA5C8E                   ; FA5C82  jr Z,0xfa5c8e
	ld	bc, ix                                  ; FA5C84  ld BC,IX
	extz	xbc                                   ; FA5C86  extz XBC
	add	bc, hl                                 ; FA5C88  add BC,HL
	ld	(xbc), d                                ; FA5C8A  ld (XBC),D
	jr sub_FA5C43__FA5C97                      ; FA5C8C  jr T,0xfa5c97
sub_FA5C43__FA5C8E:
	ld	bc, ix                                  ; FA5C8E  ld BC,IX
	extz	xbc                                   ; FA5C90  extz XBC
	add	bc, hl                                 ; FA5C92  add BC,HL
	ld	(xbc), 0xFF                             ; FA5C94  ld (XBC),0xff
sub_FA5C43__FA5C97:
	ldb	c, 27                                  ; FA5C97  ld C,0x1b
	extpfx3 0x8E, 0x0A, 0x43                   ; FA5C99  mul BC,(XIZ+0x0a)
	ld	(xiz-4), bc                             ; FA5C9C  ld (XIZ+0xfc),BC
	ldw	ix, 0xAA8                              ; FA5C9F  ld IX,0x0aa8
	add	ix, bc                                 ; FA5CA2  add IX,BC
	ld	hl, (xiz+12)                            ; FA5CA4  ld HL,(XIZ+0x0c)
	extz	hl                                    ; FA5CA7  extz HL
	extz	xix                                   ; FA5CA9  extz XIX
	extpfx5 0xC3, 0x07, 0xF0, 0xEC, 0x24       ; FA5CAB  ld D,(XIX+HL)
	cp	d, 0xC0                                 ; FA5CB0  cp D,0xc0
	jr ule, sub_FA5C43__FA5CC4                 ; FA5CB3  jr ULE,0xfa5cc4
	ld	bc, ix                                  ; FA5CB5  ld BC,IX
	extz	xbc                                   ; FA5CB7  extz XBC
	add	bc, hl                                 ; FA5CB9  add BC,HL
	ld	(xbc), e                                ; FA5CBB  ld (XBC),E
	pushw	de                                   ; FA5CBD  push DE
	calr (0xFA5B70 - 0xFA5CC1)                 ; FA5CBE  calr 0xfa5b70
	popw	bc                                    ; FA5CC1  pop BC
	jr sub_FA5C43__FA5CCD                      ; FA5CC2  jr T,0xfa5ccd
sub_FA5C43__FA5CC4:
	push	0                                     ; FA5CC4  push 0x00
	push	d                                     ; FA5CC6  push D
	pushw	de                                   ; FA5CC8  push DE
	calr (0xFA5BC7 - 0xFA5CCC)                 ; FA5CC9  calr 0xfa5bc7
	pop	xiy                                    ; FA5CCC  pop XIY
sub_FA5C43__FA5CCD:
	ld	bc, (xiz-2)                             ; FA5CCD  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FA5CD0  extz XBC
	ld	a, (xiz+10)                             ; FA5CD2  ld A,(XIZ+0x0a)
	ld	(xbc+2), a                              ; FA5CD5  ld (XBC+0x02),A
	ld	bc, (xiz-2)                             ; FA5CD8  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FA5CDB  extz XBC
	ld	a, (xiz+12)                             ; FA5CDD  ld A,(XIZ+0x0c)
	ld	(xbc+3), a                              ; FA5CE0  ld (XBC+0x03),A
	pop	xix                                    ; FA5CE3  pop XIX
	popw	de                                    ; FA5CE4  pop DE
	popw	hl                                    ; FA5CE5  pop HL
	unlk32 xiz                                 ; FA5CE6  unlk XIZ
	ret                                        ; FA5CE8  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `Rec11FE_ReleaseAllRings` is now `Rec11FE_ReleaseAllRings`.
;   GRADE PROVEN.  WHY `Rec11FE_ReleaseAllRings`:
;   body: for r = 0..3, if rec11FE[chan][8+r] < 0xC0 and that slot's owner byte
;   [+4] is chan, hand ownership to the next channel on the ring (or 0xFF),
;   Rec0E3E_MoveToList(slot, 0x21, Rec0E3E_GroupOfIndex(slot)) -- part 0x21 is
;   one past the 33 real parts, i.e. the free list -- unlink the ring, and store
;   0xFF in rec11FE[chan][8+r].
; Rec11FE_ReleaseAllRings -- 0xFA5CE9..0xFA5D83 (155 bytes)
;
; Called from: no site outside this module.
;          3 site(s) inside this module:
;          0xFA603C 0xFA6998 0xFA6E4D
; Inputs:  frame `link XIZ,-5`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA5967 = Rec0E3E_GroupOfIndex, 0xFA59CE = Rec11FE_UnlinkFromRing
;          0xFA5C43 = Rec0E3E_MoveToList
; Evidence: the listing below is the byte-identical round-trip of 0xFA5CE9-0xFA5D83
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
Rec11FE_ReleaseAllRings:
	link32 0xEE, 0x0C, 0xFB, 0xFF              ; FA5CE9  link XIZ,0xfffb
	pushw	hl                                   ; FA5CED  push HL
	pushw	de                                   ; FA5CEE  push DE
	push	xix                                   ; FA5CEF  push XIX
	ldb	c, 12                                  ; FA5CF0  ld C,0x0c
	extpfx3 0x8E, 0x08, 0x43                   ; FA5CF2  mul BC,(XIZ+0x08)
	ld	hl, bc                                  ; FA5CF5  ld HL,BC
	ldw	wa, 0x11FE                             ; FA5CF7  ld WA,0x11fe
	add	wa, bc                                 ; FA5CFA  add WA,BC
	ld	(xiz-2), wa                             ; FA5CFC  ld (XIZ+0xfe),WA
	ld	(xiz-3), 0                              ; FA5CFF  ld (XIZ+0xfd),0x00
	ldw	de, 8                                  ; FA5D03  ld DE,0x0008
sub_FA5CE9__FA5D06:
	ld	bc, (xiz-2)                             ; FA5D06  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FA5D09  extz XBC
	extpfx5 0xC3, 0x07, 0xE4, 0xE8, 0x26       ; FA5D0B  ld H,(XBC+DE)
	cp	h, 0xC0                                 ; FA5D10  cp H,0xc0
	jr nc, sub_FA5CE9__FA5D73                  ; FA5D13  jr NC,0xfa5d73
	ldb	a, 5                                   ; FA5D15  ld A,0x05
	mul8rr	a, h                                ; FA5D17  mul WA,H
	ld	(xiz-5), wa                             ; FA5D19  ld (XIZ+0xfb),WA
	ldw	ix, 0xE3E                              ; FA5D1C  ld IX,0x0e3e
	add	ix, wa                                 ; FA5D1F  add IX,WA
	extz	xix                                   ; FA5D21  extz XIX
	ld	a, (xix+4)                              ; FA5D23  ld A,(XIX+0x04)
	extpfx3 0x8E, 0x08, 0xF1                   ; FA5D26  cp A,(XIZ+0x08)
	jr nz, sub_FA5CE9__FA5D5B                  ; FA5D29  jr NZ,0xfa5d5b
	ld	wa, (xiz-3)                             ; FA5D2B  ld WA,(XIZ+0xfd)
	extz	wa                                    ; FA5D2E  extz WA
	extpfx5 0xC3, 0x07, 0xE4, 0xE0, 0x27       ; FA5D30  ld L,(XBC+WA)
	extpfx3 0x8E, 0x08, 0xF7                   ; FA5D35  cp L,(XIZ+0x08)
	jr z, sub_FA5CE9__FA5D41                   ; FA5D38  jr Z,0xfa5d41
	extz	xix                                   ; FA5D3A  extz XIX
	ld	(xix+4), l                              ; FA5D3C  ld (XIX+0x04),L
	jr sub_FA5CE9__FA5D5B                      ; FA5D3F  jr T,0xfa5d5b
sub_FA5CE9__FA5D41:
	extz	xix                                   ; FA5D41  extz XIX
	ld	(xix+4), 0xFF                           ; FA5D43  ld (XIX+0x04),0xff
	push	0                                     ; FA5D47  push 0x00
	push	h                                     ; FA5D49  push H
	calr (0xFA5967 - 0xFA5D4E)                 ; FA5D4B  calr 0xfa5967
	pushw	wa                                   ; FA5D4E  push WA
	pushw	33                                   ; FA5D4F  push 0x0021
	push	0                                     ; FA5D52  push 0x00
	push	h                                     ; FA5D54  push H
	calr (0xFA5C43 - 0xFA5D59)                 ; FA5D56  calr 0xfa5c43
	inc	8, xsp                                 ; FA5D59  inc 0,XSP
sub_FA5CE9__FA5D5B:
	push	0                                     ; FA5D5B  push 0x00
	extpfx3 0x8E, 0xFD, 0x04                   ; FA5D5D  push (XIZ+0xfd)
	push	0                                     ; FA5D60  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FA5D62  push (XIZ+0x08)
	calr (0xFA59CE - 0xFA5D68)                 ; FA5D65  calr 0xfa59ce
	ld	bc, (xiz-2)                             ; FA5D68  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FA5D6B  extz XBC
	add	bc, de                                 ; FA5D6D  add BC,DE
	ld	(xbc), 0xFF                             ; FA5D6F  ld (XBC),0xff
	pop	xiy                                    ; FA5D72  pop XIY
sub_FA5CE9__FA5D73:
	inc	1, de                                  ; FA5D73  inc 1,DE
	incm8	1, (xiz-3)                           ; FA5D75  inc 1,(XIZ+0xfd)
	cp (xiz-3), 0x04                           ; FA5D78  cp (XIZ+0xfd),0x04
	jr c, sub_FA5CE9__FA5D06                   ; FA5D7C  jr C,0xfa5d06
	pop	xix                                    ; FA5D7E  pop XIX
	popw	de                                    ; FA5D7F  pop DE
	popw	hl                                    ; FA5D80  pop HL
	unlk32 xiz                                 ; FA5D81  unlk XIZ
	ret                                        ; FA5D83  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `VoiceSlots_InitAllTables` is now `VoiceSlots_InitAllTables`.
;   GRADE PROVEN.  WHY `VoiceSlots_InitAllTables`:
;   body: fills all three tables with their own strides and counts --
;   0x11FE 64 x 12 (rings self-linked, slot bytes 0xFF), 0x0E3E 192 x 5 (rings
;   self-linked, owner 0xFF), 0x0AA8 34 x 27 (all 0xFF) -- then puts all 192
;   slots on the free list with Rec0E3E_MoveToList(s, 0x21, group).
; VoiceSlots_InitAllTables -- 0xFA5D84..0xFA5E81 (254 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFA68D3
; Inputs:  frame `link XIZ,-3`; no positive frame slot is read
; Outputs: no absolute-addressed write.
; Calls:   0xFA5967 = Rec0E3E_GroupOfIndex, 0xFA5C43 = Rec0E3E_MoveToList
; Evidence: the listing below is the byte-identical round-trip of 0xFA5D84-0xFA5E81
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
VoiceSlots_InitAllTables:
	link32 0xEE, 0x0C, 0xFD, 0xFF              ; FA5D84  link XIZ,0xfffd
	pushw	hl                                   ; FA5D88  push HL
	pushw	de                                   ; FA5D89  push DE
	push	xix                                   ; FA5D8A  push XIX
	ld	(xiz-1), 0                              ; FA5D8B  ld (XIZ+0xff),0x00
	ldw	de, 0                                  ; FA5D8F  ld DE,0x0000
sub_FA5D84__FA5D92:
	ldb	h, 0                                   ; FA5D92  ld H,0x00
sub_FA5D84__FA5D94:
	ld	ix, de                                  ; FA5D94  ld IX,DE
	ld	c, h                                    ; FA5D96  ld C,H
	extz	bc                                    ; FA5D98  extz BC
	add	bc, ix                                 ; FA5D9A  add BC,IX
	ld	(xiz-3), bc                             ; FA5D9C  ld (XIZ+0xfd),BC
	inc	8, bc                                  ; FA5D9F  inc 0,BC
	extz	xbc                                   ; FA5DA1  extz XBC
	ld	(xbc+0x11FE), 0xFF                      ; FA5DA3  ld (XBC+0x11fe),0xff
	ld	bc, (xiz-3)                             ; FA5DA9  ld BC,(XIZ+0xfd)
	extz	xbc                                   ; FA5DAC  extz XBC
	ld	a, (xiz-1)                              ; FA5DAE  ld A,(XIZ+0xff)
	ld	(xbc+0x11FE), a                         ; FA5DB1  ld (XBC+0x11fe),A
	inc	4, bc                                  ; FA5DB6  inc 4,BC
	extz	xbc                                   ; FA5DB8  extz XBC
	ld	(xbc+0x11FE), a                         ; FA5DBA  ld (XBC+0x11fe),A
	inc	1, h                                   ; FA5DBF  inc 1,H
	cps	h, 4                                   ; FA5DC1  cp H,4
	jr c, sub_FA5D84__FA5D94                   ; FA5DC3  jr C,0xfa5d94
	add	de, 12                                 ; FA5DC5  add DE,0x000c
	inc	1, a                                   ; FA5DC9  inc 1,A
	ld	(xiz-1), a                              ; FA5DCB  ld (XIZ+0xff),A
	cp	a, 64                                   ; FA5DCE  cp A,0x40
	jr c, sub_FA5D84__FA5D92                   ; FA5DD1  jr C,0xfa5d92
	ld	(xiz-1), 0                              ; FA5DD3  ld (XIZ+0xff),0x00
	ldw	hl, 0                                  ; FA5DD7  ld HL,0x0000
sub_FA5D84__FA5DDA:
	ld	de, hl                                  ; FA5DDA  ld DE,HL
	ld	ix, de                                  ; FA5DDC  ld IX,DE
	extz	xix                                   ; FA5DDE  extz XIX
	ld	c, (xiz-1)                              ; FA5DE0  ld C,(XIZ+0xff)
	ld	(xix+0xE3E), c                          ; FA5DE3  ld (XIX+0x0e3e),C
	ld	bc, ix                                  ; FA5DE8  ld BC,IX
	inc	1, bc                                  ; FA5DEA  inc 1,BC
	extz	xbc                                   ; FA5DEC  extz XBC
	ld	a, (xiz-1)                              ; FA5DEE  ld A,(XIZ+0xff)
	ld	(xbc+0xE3E), a                          ; FA5DF1  ld (XBC+0x0e3e),A
	ld	bc, ix                                  ; FA5DF6  ld BC,IX
	inc	2, bc                                  ; FA5DF8  inc 2,BC
	extz	xbc                                   ; FA5DFA  extz XBC
	ld	(xbc+0xE3E), 0                          ; FA5DFC  ld (XBC+0x0e3e),0x00
	ld	bc, ix                                  ; FA5E02  ld BC,IX
	inc	3, bc                                  ; FA5E04  inc 3,BC
	extz	xbc                                   ; FA5E06  extz XBC
	ld	(xbc+0xE3E), 0                          ; FA5E08  ld (XBC+0x0e3e),0x00
	ld	bc, ix                                  ; FA5E0E  ld BC,IX
	inc	4, bc                                  ; FA5E10  inc 4,BC
	extz	xbc                                   ; FA5E12  extz XBC
	ld	(xbc+0xE3E), 0xFF                       ; FA5E14  ld (XBC+0x0e3e),0xff
	ld	hl, de                                  ; FA5E1A  ld HL,DE
	inc	5, hl                                  ; FA5E1C  inc 5,HL
	inc	1, a                                   ; FA5E1E  inc 1,A
	ld	(xiz-1), a                              ; FA5E20  ld (XIZ+0xff),A
	cp	a, 0xC0                                 ; FA5E23  cp A,0xc0
	jr c, sub_FA5D84__FA5DDA                   ; FA5E26  jr C,0xfa5dda
	ldw	de, 0                                  ; FA5E28  ld DE,0x0000
	ld	(xiz-1), 34                             ; FA5E2B  ld (XIZ+0xff),0x22
sub_FA5D84__FA5E2F:
	ldb	h, 0                                   ; FA5E2F  ld H,0x00
	ld	ix, de                                  ; FA5E31  ld IX,DE
sub_FA5D84__FA5E33:
	ld	(xiz-3), ix                             ; FA5E33  ld (XIZ+0xfd),IX
	ld	bc, (xiz-3)                             ; FA5E36  ld BC,(XIZ+0xfd)
	extz	xbc                                   ; FA5E39  extz XBC
	ld	(xbc+0xAA8), 0xFF                       ; FA5E3B  ld (XBC+0x0aa8),0xff
	ld	ix, bc                                  ; FA5E41  ld IX,BC
	inc	1, ix                                  ; FA5E43  inc 1,IX
	inc	1, h                                   ; FA5E45  inc 1,H
	cp	h, 27                                   ; FA5E47  cp H,0x1b
	jr c, sub_FA5D84__FA5E33                   ; FA5E4A  jr C,0xfa5e33
	add	de, 27                                 ; FA5E4C  add DE,0x001b
	decm8	1, (xiz-1)                           ; FA5E50  dec 1,(XIZ+0xff)
	cp (xiz-1), 0x00                           ; FA5E53  cp (XIZ+0xff),0x00
	jr nz, sub_FA5D84__FA5E2F                  ; FA5E57  jr NZ,0xfa5e2f
	ld	(xiz-1), 0                              ; FA5E59  ld (XIZ+0xff),0x00
sub_FA5D84__FA5E5D:
	push	0                                     ; FA5E5D  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FA5E5F  push (XIZ+0xff)
	calr (0xFA5967 - 0xFA5E65)                 ; FA5E62  calr 0xfa5967
	pushw	wa                                   ; FA5E65  push WA
	pushw	33                                   ; FA5E66  push 0x0021
	push	0                                     ; FA5E69  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FA5E6B  push (XIZ+0xff)
	calr (0xFA5C43 - 0xFA5E71)                 ; FA5E6E  calr 0xfa5c43
	incm8	1, (xiz-1)                           ; FA5E71  inc 1,(XIZ+0xff)
	inc	8, xsp                                 ; FA5E74  inc 0,XSP
	cp (xiz-1), 0xC0                           ; FA5E76  cp (XIZ+0xff),0xc0
	jr c, sub_FA5D84__FA5E5D                   ; FA5E7A  jr C,0xfa5e5d
	pop	xix                                    ; FA5E7C  pop XIX
	popw	de                                    ; FA5E7D  pop DE
	popw	hl                                    ; FA5E7E  pop HL
	unlk32 xiz                                 ; FA5E7F  unlk XIZ
	ret                                        ; FA5E81  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `Rec0E3E_FreeListHead` is now `Rec0E3E_FreeListHead`.
;   GRADE PROVEN.  WHY `Rec0E3E_FreeListHead`:
;   body: reads 0x0AA8 + 0x37B + {0, 4, 8} by a 2-bit selector.  0x37B = 27*33,
;   so the row is part 33 -- the free row, one past the 33 real parts -- and the
;   three columns are Rec0E3E_GroupOfIndex's three values.
; Rec0E3E_FreeListHead -- 0xFA5E82..0xFA5ED2 (81 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFA5F89 0xFA5FD5
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA5E82-0xFA5ED2
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
Rec0E3E_FreeListHead:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA5E82  link XIZ,0x0000
	pushw	hl                                   ; FA5E86  push HL
	push	xde                                   ; FA5E87  push XDE
	ldw	de, 0xAA8                              ; FA5E88  ld DE,0x0aa8
	add	de, 0x37B                              ; FA5E8B  add DE,0x037b
	ld	bc, (xiz+8)                             ; FA5E8F  ld BC,(XIZ+0x08)
	and	bc, 3                                  ; FA5E92  and BC,0x0003
	cps	bc, 0                                  ; FA5E96  cp BC,0
	jr z, sub_FA5E82__FA5EA8                   ; FA5E98  jr Z,0xfa5ea8
	cps	bc, 1                                  ; FA5E9A  cp BC,1
	jr z, sub_FA5E82__FA5EBA                   ; FA5E9C  jr Z,0xfa5eba
	cps	bc, 2                                  ; FA5E9E  cp BC,2
	jr z, sub_FA5E82__FA5EB0                   ; FA5EA0  jr Z,0xfa5eb0
	cps	bc, 3                                  ; FA5EA2  cp BC,3
	jr z, sub_FA5E82__FA5EC3                   ; FA5EA4  jr Z,0xfa5ec3
	jr sub_FA5E82__FA5ECC                      ; FA5EA6  jr T,0xfa5ecc
sub_FA5E82__FA5EA8:
	extz	xde                                   ; FA5EA8  extz XDE
	ld	c, (xde)                                ; FA5EAA  ld C,(XDE)
	ld	a, c                                    ; FA5EAC  ld A,C
	jr sub_FA5E82__FA5ECE                      ; FA5EAE  jr T,0xfa5ece
sub_FA5E82__FA5EB0:
	extz	xde                                   ; FA5EB0  extz XDE
	ld	h, (xde+8)                              ; FA5EB2  ld H,(XDE+0x08)
	cp	h, 0xC0                                 ; FA5EB5  cp H,0xc0
	jr ule, sub_FA5E82__FA5ECC                 ; FA5EB8  jr ULE,0xfa5ecc
sub_FA5E82__FA5EBA:
	extz	xde                                   ; FA5EBA  extz XDE
	ld	c, (xde+4)                              ; FA5EBC  ld C,(XDE+0x04)
	ld	a, c                                    ; FA5EBF  ld A,C
	jr sub_FA5E82__FA5ECE                      ; FA5EC1  jr T,0xfa5ece
sub_FA5E82__FA5EC3:
	extz	xde                                   ; FA5EC3  extz XDE
	ld	c, (xde+8)                              ; FA5EC5  ld C,(XDE+0x08)
	ld	a, c                                    ; FA5EC8  ld A,C
	jr sub_FA5E82__FA5ECE                      ; FA5ECA  jr T,0xfa5ece
sub_FA5E82__FA5ECC:
	ld	a, h                                    ; FA5ECC  ld A,H
sub_FA5E82__FA5ECE:
	pop	xde                                    ; FA5ECE  pop XDE
	popw	hl                                    ; FA5ECF  pop HL
	unlk32 xiz                                 ; FA5ED0  unlk XIZ
	ret                                        ; FA5ED2  ret
; --------------------------------------------------------------------------
; Voice_LookupDev10CChanIndex -- 0xFA5ED3..0xFA6025 (339 bytes)
;
; Called from: 9 site(s) outside this module:
;          0xFA9992 in Voice_StageChanSel_Reg0440_Reg0480, 0xFA99B9 in Voice_StageChanSel_Reg0440_Reg0480__FA99A7
;          0xFA9B04 in Voice_StageChanSel_Reg0440_Reg0480__FA9ACB, 0xFA9BAD in Voice_StageChanSel_Reg0440_Reg0480__FA9B74
;          0xFA9CC9 in Voice_StageRegs_0180_AB, 0xFA9CF2 in Voice_StageRegs_0180_AB__FA9CDE
;          0xFA9E47 in Voice_StageRegs_0180_AB__FA9E12, 0xFA9F7C in Voice_StageChanSel_Reg04C0
;          0xFA9FA3 in Voice_StageChanSel_Reg04C0__FA9F94
;          1 site(s) inside this module:
;          0xFA6071
; Inputs:  frame `link XIZ,-2`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFA598C = Rec0E3E_IndexWithinGroup, 0xFA5ACA = Rec11FE_BindRingToSlot
;          0xFA5C43 = Rec0E3E_MoveToList, 0xFA5E82 = Rec0E3E_FreeListHead
; Evidence: the listing below is the byte-identical round-trip of 0xFA5ED3-0xFA6025
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
;
; ★ THE RETURN VALUE IS TWO BYTES WITH TWO JOBS:
;       high byte = the third argument masked to 6 bits (0xFA5EDA `ld E,(XIZ+0x0c)`,
;                   0xFA5EDD `and E,0x3f`), sometimes with bit 7 set (0xFA5F67,
;                   0xFA5FC7), shifted up at 0xFA6015 and OR'd in at 0xFA601C;
;       low byte  = THE RESULT, or 0xFF when there is none (0xFA600D `ld H,0xff`).
;   Assembled at 0xFA601E `ld WA,BC` and returned through the common exit 0xFA6020.
;
; ★ THE LOW BYTE IS A 0x0010C000 CHANNEL INDEX, and the name says only that
;   because only that is measured.  NINE of the ten call sites mask it to 0x3F or
;   0x7F immediately (the tenth, 0xFA6071, is VoiceSlots_ReleaseThenLookup's tail call and passes
;   the value through untouched), and THREE of those nine hand the masked value
;   straight to a Dev10C_Slot* accessor as its `chan` argument -- 0xFA999F
;   (Dev10C_Slot2_WriteGate8100), 0xFA9CD6 (Dev10C_Slot1_WriteGate8100), 0xFA9F8C
;   (Dev10C_Slot1or3_WriteGate8100) -- where it becomes a device register selector
;   by adding a block base.  The other six are the else-arms of the same if/else
;   pairs and mask to the IDENTICAL width, so the field width is not an artefact
;   of which arm ran.  Three of nine is the honest fraction, not a majority.
; ★ WHAT BOUNDS IT: a 192-entry RAM array of 5-byte records at 0x00000E3E.
;          0xFA5F37 `cp H,0xc0` rejects >= 192 before use; 0xFA5F3C/0xFA5F3E
;          `ld C,0x05` / `mul BC,H` is the stride; 0xFA5F43 `ld IX,0x0e3e` is the
;          base.  0x0E3E + 192*5 = 0x11FE, which is the base of the NEXT array
;          this same routine indexes (0xFA5F22 `ld WA,0x11fe`) -- the two arrays
;          close on each other, and that is what fixes the count at 192.
;          192 = 3 * 64; the consumers accept only 0..0x7F = 2 * 64 of it.
;
; ★ THE THREE ARGUMENTS, BOUNDED BY THE ROUTINE'S OWN GUARDS AND BY THREE RAM
;   ARRAYS THAT CLOSE ON EACH OTHER.  This is the read
;   `notes/WSA1-EMULATION-DISASM-GAPS.md` gap A asks for by name ("339 bytes,
;   converted, never read"):
;       (XIZ+0x08)  guarded `cp (XIZ+0x08),0x21` at 0xFA5EE6  -> 0..32  (33 values)
;                   indexes the STRIDE-27 array at RAM 0x00000AA8
;                   (0xFA5F97 `ld C,0x1b` / 0xFA5F99 `mul BC,(XIZ+0x08)`,
;                    0xFA5FA6 `ld H,(XBC+0x0aa8)`)
;       (XIZ+0x0A)  guarded `cp (XIZ+0x0a),0x40` at 0xFA5EE0  -> 0..63  (64 values)
;                   indexes the STRIDE-12 array at RAM 0x000011FE
;                   (0xFA5F1B `ld C,0x0c` / 0xFA5F1D `mul BC,(XIZ+0x0a)`,
;                    0xFA5F22 `ld WA,0x11fe`)
;       (XIZ+0x0C)  masked `and E,0x3f` at 0xFA5EDD          -> 0..63  (6 bits)
;                   keys BOTH lookup tables: Table_FE10C9 through `and C,0x1f`
;                   (0xFA5EFE/0xFA5F05, 32 entries, values 0..3) and Table_FE10E9
;                   unmasked (0xFA5F13, 64 entries, values 0..26)
;   ★ AND THE THREE RAM ARRAYS ARE CONTIGUOUS, each one's COUNT fixed by the next
;   one's base -- which is why the counts above are not guesses:
;       0x0AA8 + 27*34  = 0x0E3E      0x0E3E + 5*192 = 0x11FE
;       0x11FE + 12*64  = 0x14FE
;   The 0x0AA8 array holds 34 records although the guard admits only 33 indices;
;   the extra room is the `+ D` from Table_FE10E9, whose largest value is 26, so
;   27*32 + 26 = 890 stays inside 27*34 = 918.  Checked over all 64 entries.
; ⚠ NOT ESTABLISHED: WHAT the three arguments are.  The overlay's copy of the gap
;   list proposes "(part, channel, parameter index)" from these same three bounds;
;   that is a reading of the bounds, not a measurement, and it is NOT adopted here.
;   Also open: why the 0x0E3E array is 192 long when the consumers use 128 of it,
;   and whether the routine ALLOCATES or merely LOOKS UP.  "Lookup" is the weaker
;   of the two readings and is the one the name uses.
; Evidence: `python3 notes/prom_c_understanding_round4.py --chanarg --lookup`,
;          with every cited address re-decoded by an independent disassembler and
;          the call-site census printed with its denominator.
; --------------------------------------------------------------------------
Voice_LookupDev10CChanIndex:
	link32 0xEE, 0x0C, 0xFE, 0xFF              ; FA5ED3  link XIZ,0xfffe
	pushw	hl                                   ; FA5ED7  push HL
	pushw	de                                   ; FA5ED8  push DE
	push	xix                                   ; FA5ED9  push XIX
	ld	e, (xiz+12)                             ; FA5EDA  ld E,(XIZ+0x0c)
	and	e, 63                                  ; FA5EDD  and E,0x3f
	cp (xiz+10), 0x40                          ; FA5EE0  cp (XIZ+0x0a),0x40
	jr nc, Voice_LookupDev10CChanIndex__FA5EEC                  ; FA5EE4  jr NC,0xfa5eec
	cp (xiz+8), 0x21                           ; FA5EE6  cp (XIZ+0x08),0x21
	jr c, Voice_LookupDev10CChanIndex__FA5EFC                   ; FA5EEA  jr C,0xfa5efc
Voice_LookupDev10CChanIndex__FA5EEC:
	ld	c, e                                    ; FA5EEC  ld C,E
	extz	bc                                    ; FA5EEE  extz BC
	sll	bc, 8                                  ; FA5EF0  sll 0x08,BC
	or	bc, 0xFF                                ; FA5EF3  or BC,0x00ff
	ld	wa, bc                                  ; FA5EF7  ld WA,BC
	jrl Voice_LookupDev10CChanIndex__FA6020                     ; FA5EF9  jrl T,0xfa6020
Voice_LookupDev10CChanIndex__FA5EFC:
	ld	c, e                                    ; FA5EFC  ld C,E
	and	c, 31                                  ; FA5EFE  and C,0x1f
	extz	bc                                    ; FA5F01  extz BC
	extz	xbc                                   ; FA5F03  extz XBC
	add	xbc, 0xFE10C9                          ; FA5F05  add XBC,0x00fe10c9
	ld	l, (xbc)                                ; FA5F0B  ld L,(XBC)
	ld	c, e                                    ; FA5F0D  ld C,E
	extz	bc                                    ; FA5F0F  extz BC
	extz	xbc                                   ; FA5F11  extz XBC
	add	xbc, 0xFE10E9                          ; FA5F13  add XBC,0x00fe10e9
	ld	d, (xbc)                                ; FA5F19  ld D,(XBC)
	ldb	c, 12                                  ; FA5F1B  ld C,0x0c
	extpfx3 0x8E, 0x0A, 0x43                   ; FA5F1D  mul BC,(XIZ+0x0a)
	ld	ix, bc                                  ; FA5F20  ld IX,BC
	ldw	wa, 0x11FE                             ; FA5F22  ld WA,0x11fe
	add	wa, bc                                 ; FA5F25  add WA,BC
	ld	(xiz-2), wa                             ; FA5F27  ld (XIZ+0xfe),WA
	ld	c, l                                    ; FA5F2A  ld C,L
	extz	bc                                    ; FA5F2C  extz BC
	inc	8, bc                                  ; FA5F2E  inc 0,BC
	extz	xwa                                   ; FA5F30  extz XWA
	extpfx5 0xC3, 0x07, 0xE0, 0xE4, 0x26       ; FA5F32  ld H,(XWA+BC)
	cp	h, 0xC0                                 ; FA5F37  cp H,0xc0
	jr nc, Voice_LookupDev10CChanIndex__FA5F7D                  ; FA5F3A  jr NC,0xfa5f7d
	ldb	c, 5                                   ; FA5F3C  ld C,0x05
	mul8rr	c, h                                ; FA5F3E  mul BC,H
	ld	(xiz-2), bc                             ; FA5F40  ld (XIZ+0xfe),BC
	ldw	ix, 0xE3E                              ; FA5F43  ld IX,0x0e3e
	add	ix, bc                                 ; FA5F46  add IX,BC
	extz	xix                                   ; FA5F48  extz XIX
	ld	c, (xix+2)                              ; FA5F4A  ld C,(XIX+0x02)
	extpfx3 0x8E, 0x08, 0xF3                   ; FA5F4D  cp C,(XIZ+0x08)
	jr nz, Voice_LookupDev10CChanIndex__FA5F7D                  ; FA5F50  jr NZ,0xfa5f7d
	extz	xix                                   ; FA5F52  extz XIX
	ld	c, (xix+3)                              ; FA5F54  ld C,(XIX+0x03)
	cp	c, d                                    ; FA5F57  cp C,D
	jr nz, Voice_LookupDev10CChanIndex__FA5F7D                  ; FA5F59  jr NZ,0xfa5f7d
	pushw	hl                                   ; FA5F5B  push HL
	push	0                                     ; FA5F5C  push 0x00
	push	h                                     ; FA5F5E  push H
	calr (0xFA598C - 0xFA5F63)                 ; FA5F60  calr 0xfa598c
	ld	h, a                                    ; FA5F63  ld H,A
	ld	c, e                                    ; FA5F65  ld C,E
	set	7, c                                   ; FA5F67  set 0x07,C
	extz	bc                                    ; FA5F6A  extz BC
	ld	ix, bc                                  ; FA5F6C  ld IX,BC
	sll	ix, 8                                  ; FA5F6E  sll 0x08,IX
	ld	c, h                                    ; FA5F71  ld C,H
	extz	bc                                    ; FA5F73  extz BC
	or	bc, ix                                  ; FA5F75  or BC,IX
	pop	xiy                                    ; FA5F77  pop XIY
	ld	wa, bc                                  ; FA5F78  ld WA,BC
	jrl Voice_LookupDev10CChanIndex__FA6020                     ; FA5F7A  jrl T,0xfa6020
Voice_LookupDev10CChanIndex__FA5F7D:
	ld	c, e                                    ; FA5F7D  ld C,E
	and	c, 32                                  ; FA5F7F  and C,0x20
	jr z, Voice_LookupDev10CChanIndex__FA5F97                   ; FA5F82  jr Z,0xfa5f97
	ld	c, l                                    ; FA5F84  ld C,L
	extz	bc                                    ; FA5F86  extz BC
	pushw	bc                                   ; FA5F88  push BC
	calr (0xFA5E82 - 0xFA5F8C)                 ; FA5F89  calr 0xfa5e82
	ld	h, a                                    ; FA5F8C  ld H,A
	popw	bc                                    ; FA5F8E  pop BC
	cp	a, 0xC0                                 ; FA5F8F  cp A,0xc0
	jrl nc, Voice_LookupDev10CChanIndex__FA600D                 ; FA5F92  jrl NC,0xfa600d
	jr Voice_LookupDev10CChanIndex__FA5FE0                      ; FA5F95  jr T,0xfa5fe0
Voice_LookupDev10CChanIndex__FA5F97:
	ldb	c, 27                                  ; FA5F97  ld C,0x1b
	extpfx3 0x8E, 0x08, 0x43                   ; FA5F99  mul BC,(XIZ+0x08)
	ld	ix, bc                                  ; FA5F9C  ld IX,BC
	ld	a, d                                    ; FA5F9E  ld A,D
	extz	wa                                    ; FA5FA0  extz WA
	add	bc, wa                                 ; FA5FA2  add BC,WA
	extz	xbc                                   ; FA5FA4  extz XBC
	ld	h, (xbc+0xAA8)                          ; FA5FA6  ld H,(XBC+0x0aa8)
	cp	h, 0xC0                                 ; FA5FAB  cp H,0xc0
	jr nc, Voice_LookupDev10CChanIndex__FA5FD0                  ; FA5FAE  jr NC,0xfa5fd0
	push	0                                     ; FA5FB0  push 0x00
	push	h                                     ; FA5FB2  push H
	pushw	hl                                   ; FA5FB4  push HL
	push	0                                     ; FA5FB5  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FA5FB7  push (XIZ+0x0a)
	calr (0xFA5ACA - 0xFA5FBD)                 ; FA5FBA  calr 0xfa5aca
	pushw	hl                                   ; FA5FBD  push HL
	push	0                                     ; FA5FBE  push 0x00
	push	h                                     ; FA5FC0  push H
	calr (0xFA598C - 0xFA5FC5)                 ; FA5FC2  calr 0xfa598c
	ld	h, a                                    ; FA5FC5  ld H,A
	set	7, e                                   ; FA5FC7  set 0x07,E
	inc	8, xsp                                 ; FA5FCA  inc 0,XSP
	inc	2, xsp                                 ; FA5FCC  inc 2,XSP
	jr Voice_LookupDev10CChanIndex__FA600F                      ; FA5FCE  jr T,0xfa600f
Voice_LookupDev10CChanIndex__FA5FD0:
	ld	c, l                                    ; FA5FD0  ld C,L
	extz	bc                                    ; FA5FD2  extz BC
	pushw	bc                                   ; FA5FD4  push BC
	calr (0xFA5E82 - 0xFA5FD8)                 ; FA5FD5  calr 0xfa5e82
	ld	h, a                                    ; FA5FD8  ld H,A
	popw	bc                                    ; FA5FDA  pop BC
	cp	a, 0xC0                                 ; FA5FDB  cp A,0xc0
	jr nc, Voice_LookupDev10CChanIndex__FA600D                  ; FA5FDE  jr NC,0xfa600d
Voice_LookupDev10CChanIndex__FA5FE0:
	push	0                                     ; FA5FE0  push 0x00
	push	d                                     ; FA5FE2  push D
	push	0                                     ; FA5FE4  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FA5FE6  push (XIZ+0x08)
	push	0                                     ; FA5FE9  push 0x00
	push	h                                     ; FA5FEB  push H
	calr (0xFA5C43 - 0xFA5FF0)                 ; FA5FED  calr 0xfa5c43
	push	0                                     ; FA5FF0  push 0x00
	push	h                                     ; FA5FF2  push H
	pushw	hl                                   ; FA5FF4  push HL
	push	0                                     ; FA5FF5  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FA5FF7  push (XIZ+0x0a)
	calr (0xFA5ACA - 0xFA5FFD)                 ; FA5FFA  calr 0xfa5aca
	pushw	hl                                   ; FA5FFD  push HL
	push	0                                     ; FA5FFE  push 0x00
	push	h                                     ; FA6000  push H
	calr (0xFA598C - 0xFA6005)                 ; FA6002  calr 0xfa598c
	ld	h, a                                    ; FA6005  ld H,A
	inc	8, xsp                                 ; FA6007  inc 0,XSP
	inc	8, xsp                                 ; FA6009  inc 0,XSP
	jr Voice_LookupDev10CChanIndex__FA600F                      ; FA600B  jr T,0xfa600f
Voice_LookupDev10CChanIndex__FA600D:
	ldb	h, 0xFF                                ; FA600D  ld H,0xff
Voice_LookupDev10CChanIndex__FA600F:
	ld	c, e                                    ; FA600F  ld C,E
	extz	bc                                    ; FA6011  extz BC
	ld	ix, bc                                  ; FA6013  ld IX,BC
	sll	ix, 8                                  ; FA6015  sll 0x08,IX
	ld	c, h                                    ; FA6018  ld C,H
	extz	bc                                    ; FA601A  extz BC
	or	bc, ix                                  ; FA601C  or BC,IX
	ld	wa, bc                                  ; FA601E  ld WA,BC
Voice_LookupDev10CChanIndex__FA6020:
	pop	xix                                    ; FA6020  pop XIX
	popw	de                                    ; FA6021  pop DE
	popw	hl                                    ; FA6022  pop HL
	unlk32 xiz                                 ; FA6023  unlk XIZ
	ret                                        ; FA6025  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `VoiceSlots_ReleaseChanAndReturnNone` is now `VoiceSlots_ReleaseChanAndReturnNone`.
;   GRADE PROVEN.  WHY `VoiceSlots_ReleaseChanAndReturnNone`:
;   body: if chan < 0x40 call Rec11FE_ReleaseAllRings(chan); return
;   ((sel & 0x3F) << 8) | 0xFF -- the same two-byte (selector, result) shape
;   Voice_LookupDev10CChanIndex returns, with 0xFF meaning `no slot`.
; VoiceSlots_ReleaseChanAndReturnNone -- 0xFA6026..0xFA6050 (43 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFA605F
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFA5CE9 = Rec11FE_ReleaseAllRings
; Evidence: the listing below is the byte-identical round-trip of 0xFA6026-0xFA6050
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
VoiceSlots_ReleaseChanAndReturnNone:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA6026  link XIZ,0x0000
	pushw	hl                                   ; FA602A  push HL
	ld	h, (xiz+10)                             ; FA602B  ld H,(XIZ+0x0a)
	and	h, 63                                  ; FA602E  and H,0x3f
	cp (xiz+8), 0x40                           ; FA6031  cp (XIZ+0x08),0x40
	jr nc, sub_FA6026__FA6040                  ; FA6035  jr NC,0xfa6040
	push	0                                     ; FA6037  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FA6039  push (XIZ+0x08)
	calr (0xFA5CE9 - 0xFA603F)                 ; FA603C  calr 0xfa5ce9
	popw	bc                                    ; FA603F  pop BC
sub_FA6026__FA6040:
	ld	c, h                                    ; FA6040  ld C,H
	extz	bc                                    ; FA6042  extz BC
	sll	bc, 8                                  ; FA6044  sll 0x08,BC
	or	bc, 0xFF                                ; FA6047  or BC,0x00ff
	ld	wa, bc                                  ; FA604B  ld WA,BC
	popw	hl                                    ; FA604D  pop HL
	unlk32 xiz                                 ; FA604E  unlk XIZ
	ret                                        ; FA6050  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `VoiceSlots_ReleaseThenLookup` is now `VoiceSlots_ReleaseThenLookup`.
;   GRADE PROVEN.  WHY `VoiceSlots_ReleaseThenLookup`:
;   body is two calls and nothing else: VoiceSlots_ReleaseChanAndReturnNone
;   then Voice_LookupDev10CChanIndex on the same channel.
;   ⚠ NOT REFERENCED -- no literal call/calr/jp/jrl and no 24- or 32-bit pointer
;   in the 512 KiB reaches it.  The BODY is the evidence for the name, not a
;   caller; the precedent for naming an unreferenced routine from its body alone
;   is Clamp_ToRange_Word_b (0xFA78C6).
; VoiceSlots_ReleaseThenLookup -- 0xFA6051..0xFA607A (42 bytes)
;
; Called from: no site outside this module.
;          ⚠ NOT FOUND -- no literal call/calr/jp reaches this address anywhere
;          in the image.  A register-indirect call would be invisible to that
;          scan, so this is "not found", not "dead".
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x0E)
; Outputs: no absolute-addressed write.
; Calls:   0xFA5ED3 = Voice_LookupDev10CChanIndex, 0xFA6026 = VoiceSlots_ReleaseChanAndReturnNone
; Evidence: the listing below is the byte-identical round-trip of 0xFA6051-0xFA607A
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
VoiceSlots_ReleaseThenLookup:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA6051  link XIZ,0x0000
	push	0                                     ; FA6055  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FA6057  push (XIZ+0x0c)
	push	0                                     ; FA605A  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FA605C  push (XIZ+0x0a)
	calr (0xFA6026 - 0xFA6062)                 ; FA605F  calr 0xfa6026
	push	0                                     ; FA6062  push 0x00
	extpfx3 0x8E, 0x0E, 0x04                   ; FA6064  push (XIZ+0x0e)
	push	0                                     ; FA6067  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FA6069  push (XIZ+0x0a)
	push	0                                     ; FA606C  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FA606E  push (XIZ+0x08)
	calr (0xFA5ED3 - 0xFA6074)                 ; FA6071  calr 0xfa5ed3
	inc	8, xsp                                 ; FA6074  inc 0,XSP
	inc	2, xsp                                 ; FA6076  inc 2,XSP
	unlk32 xiz                                 ; FA6078  unlk XIZ
	ret                                        ; FA607A  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `VoiceSlots_ListSlotsOfChannel` is now `VoiceSlots_ListSlotsOfChannel`.
;   GRADE PROVEN.  WHY `VoiceSlots_ListSlotsOfChannel`:
;   body: walks rec11FE[chan] rings 0..3, keeps a ring whose slot's
;   Table_FE1129 code passes the caller's (value, mask) filter, and appends
;   (code << 8) | Rec0E3E_IndexWithinGroup(slot) to the buffer at RAM 0x0086FC,
;   terminating it with 0xFFFF.  ⚠ NOT REFERENCED (see VoiceSlots_ReleaseThenLookup).
; VoiceSlots_ListSlotsOfChannel -- 0xFA607B..0xFA610F (149 bytes)
;
; Called from: no site outside this module.
;          ⚠ NOT FOUND -- no literal call/calr/jp reaches this address anywhere
;          in the image.  A register-indirect call would be invisible to that
;          scan, so this is "not found", not "dead".
; Inputs:  frame `link XIZ,-8`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFA598C = Rec0E3E_IndexWithinGroup
; Evidence: the listing below is the byte-identical round-trip of 0xFA607B-0xFA610F
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
VoiceSlots_ListSlotsOfChannel:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FA607B  link XIZ,0xfff8
	pushw	hl                                   ; FA607F  push HL
	pushw	de                                   ; FA6080  push DE
	push	xix                                   ; FA6081  push XIX
	ld	c, (xiz+12)                             ; FA6082  ld C,(XIZ+0x0c)
	cpl	c                                      ; FA6085  cpl C
	ld	(xiz-2), c                              ; FA6087  ld (XIZ+0xfe),C
	extpfx3 0x8E, 0x0A, 0xC3                   ; FA608A  and C,(XIZ+0x0a)
	ld	(xiz-3), c                              ; FA608D  ld (XIZ+0xfd),C
	ldb	c, 12                                  ; FA6090  ld C,0x0c
	extpfx3 0x8E, 0x08, 0x43                   ; FA6092  mul BC,(XIZ+0x08)
	ld	de, bc                                  ; FA6095  ld DE,BC
	ldw	wa, 0x11FE                             ; FA6097  ld WA,0x11fe
	add	wa, bc                                 ; FA609A  add WA,BC
	ld	(xiz-6), wa                             ; FA609C  ld (XIZ+0xfa),WA
	lda	xix, (0x86FC:24)                       ; FA609F  lda XIX,0x0086fc
	ldb	h, 0                                   ; FA60A4  ld H,0x00
	ldw	de, 8                                  ; FA60A6  ld DE,0x0008
sub_FA607B__FA60A9:
	ld	bc, (xiz-6)                             ; FA60A9  ld BC,(XIZ+0xfa)
	extz	xbc                                   ; FA60AC  extz XBC
	extpfx5 0xC3, 0x07, 0xE4, 0xE8, 0x27       ; FA60AE  ld L,(XBC+DE)
	cp	l, 0xC0                                 ; FA60B3  cp L,0xc0
	jr nc, sub_FA607B__FA60F9                  ; FA60B6  jr NC,0xfa60f9
	ldb	a, 5                                   ; FA60B8  ld A,0x05
	mul8rr	a, l                                ; FA60BA  mul WA,L
	inc	3, wa                                  ; FA60BC  inc 3,WA
	extz	xwa                                   ; FA60BE  extz XWA
	ld	c, (xwa+0xE3E)                          ; FA60C0  ld C,(XWA+0x0e3e)
	extz	bc                                    ; FA60C5  extz BC
	extz	xbc                                   ; FA60C7  extz XBC
	add	xbc, 0xFE1129                          ; FA60C9  add XBC,0x00fe1129
	ld	a, (xbc)                                ; FA60CF  ld A,(XBC)
	ld	(xiz-1), a                              ; FA60D1  ld (XIZ+0xff),A
	extpfx3 0x8E, 0xFE, 0xC1                   ; FA60D4  and A,(XIZ+0xfe)
	extpfx3 0x8E, 0xFD, 0xF1                   ; FA60D7  cp A,(XIZ+0xfd)
	jr nz, sub_FA607B__FA60F9                  ; FA60DA  jr NZ,0xfa60f9
	push	0                                     ; FA60DC  push 0x00
	push	h                                     ; FA60DE  push H
	pushw	hl                                   ; FA60E0  push HL
	calr (0xFA598C - 0xFA60E4)                 ; FA60E1  calr 0xfa598c
	extz	wa                                    ; FA60E4  extz WA
	ld	(xiz-8), wa                             ; FA60E6  ld (XIZ+0xf8),WA
	ld	bc, (xiz-1)                             ; FA60E9  ld BC,(XIZ+0xff)
	extz	bc                                    ; FA60EC  extz BC
	sll	bc, 8                                  ; FA60EE  sll 0x08,BC
	extpfx3 0x9E, 0xF8, 0xE1                   ; FA60F1  or BC,(XIZ+0xf8)
	ld	(xix), bc                               ; FA60F4  ld (XIX),BC
	inc	2, xix                                 ; FA60F6  inc 2,XIX
	pop	xiy                                    ; FA60F8  pop XIY
sub_FA607B__FA60F9:
	inc	1, de                                  ; FA60F9  inc 1,DE
	inc	1, h                                   ; FA60FB  inc 1,H
	cps	h, 4                                   ; FA60FD  cp H,4
	jr c, sub_FA607B__FA60A9                   ; FA60FF  jr C,0xfa60a9
	extpfx4 0xB4, 0x02, 0xFF, 0xFF             ; FA6101  ld (XIX),0xffff
	lda	xiy, (0x86FC:24)                       ; FA6105  lda XIY,0x0086fc
	pop	xix                                    ; FA610A  pop XIX
	popw	de                                    ; FA610B  pop DE
	popw	hl                                    ; FA610C  pop HL
	unlk32 xiz                                 ; FA610D  unlk XIZ
	ret                                        ; FA610F  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `VoiceSlots_ListSlotsOfPart` is now `VoiceSlots_ListSlotsOfPart`.
;   GRADE PROVEN.  WHY `VoiceSlots_ListSlotsOfPart`:
;   body: walks the 27 columns of the 0x0AA8 row for one part, and for each
;   column whose Table_FE1129 code passes the caller's (value, mask) filter walks
;   that column's ring of slots, appending (code << 8) |
;   Rec0E3E_IndexWithinGroup(slot) to the buffer at RAM 0x0086 7A, 0xFFFF-terminated.
; VoiceSlots_ListSlotsOfPart -- 0xFA6110..0xFA61BC (173 bytes)
;
; Called from: 21 site(s) outside this module:
;          0xFAC4F1 in sub_FAC42C__FAC49B, 0xFAC55A in sub_FAC526
;          0xFAC654 in sub_FAC58F__FAC5FE, 0xFAC6BD in sub_FAC689
;          0xFAC769 in sub_FAC6F2__FAC75E, 0xFAC7BC in sub_FAC79C
;          0xFACCA7 in sub_FACC75, 0xFACCE8 in sub_FACC75__FACCD4
;          0xFACD4D in sub_FACD1B, 0xFACD8E in sub_FACD1B__FACD7A
;          0xFACDE1 in sub_FACDC1, 0xFACE34 in sub_FACE14
;          0xFAE3E9 in Voice_Restage_Reg0440_BaseCurve_ForPart__FAE3DC, 0xFAE523 in Voice_Restage_Reg0440_ValueCurve_ForPart__FAE516
;          0xFAE668 in Voice_Restage_Reg0180_BaseCurve_ForPart__FAE659, 0xFAE7A4 in Voice_Restage_Reg0180_ValueCurve_ForPart__FAE795
;          0xFAE8E9 in Voice_Restage_Reg04C0_BaseCurve_ForPart__FAE8DA, 0xFAEA27 in Voice_Restage_Reg04C0_ValueCurve_ForPart__FAEA18
;          0xFB8A56 in Voice_RecomputeEnv_AndWriteSlot2__FB8A49, 0xFB8B56 in Voice_RecomputeEnv_AndWriteSlot1__FB8B47
;          0xFB8C56 in Voice_RecomputeEnv_AndWriteSlot1or3__FB8C47
; Inputs:  frame `link XIZ,-7`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFA598C = Rec0E3E_IndexWithinGroup
; Evidence: the listing below is the byte-identical round-trip of 0xFA6110-0xFA61BC
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
VoiceSlots_ListSlotsOfPart:
	link32 0xEE, 0x0C, 0xF9, 0xFF              ; FA6110  link XIZ,0xfff9
	pushw	hl                                   ; FA6114  push HL
	pushw	de                                   ; FA6115  push DE
	push	xix                                   ; FA6116  push XIX
	ld	c, (xiz+12)                             ; FA6117  ld C,(XIZ+0x0c)
	cpl	c                                      ; FA611A  cpl C
	ld	(xiz-3), c                              ; FA611C  ld (XIZ+0xfd),C
	extpfx3 0x8E, 0x0A, 0xC3                   ; FA611F  and C,(XIZ+0x0a)
	ld	(xiz-4), c                              ; FA6122  ld (XIZ+0xfc),C
	ldb	c, 27                                  ; FA6125  ld C,0x1b
	extpfx3 0x8E, 0x08, 0x43                   ; FA6127  mul BC,(XIZ+0x08)
	ld	hl, bc                                  ; FA612A  ld HL,BC
	ldw	wa, 0xAA8                              ; FA612C  ld WA,0x0aa8
	add	wa, bc                                 ; FA612F  add WA,BC
	ld	(xiz-6), wa                             ; FA6131  ld (XIZ+0xfa),WA
	lda	xix, (0x867A:24)                       ; FA6134  lda XIX,0x00867a
	ld	(xiz-7), 0                              ; FA6139  ld (XIZ+0xf9),0x00
sub_FA6110__FA613D:
	ld	bc, (xiz-7)                             ; FA613D  ld BC,(XIZ+0xf9)
	extz	bc                                    ; FA6140  extz BC
	ld	wa, (xiz-6)                             ; FA6142  ld WA,(XIZ+0xfa)
	extz	xwa                                   ; FA6145  extz XWA
	extpfx5 0xC3, 0x07, 0xE0, 0xE4, 0x24       ; FA6147  ld D,(XWA+BC)
	cp	d, 0xC0                                 ; FA614C  cp D,0xc0
	jr nc, sub_FA6110__FA61A5                  ; FA614F  jr NC,0xfa61a5
	ld	bc, (xiz-7)                             ; FA6151  ld BC,(XIZ+0xf9)
	extz	bc                                    ; FA6154  extz BC
	extz	xbc                                   ; FA6156  extz XBC
	add	xbc, 0xFE1129                          ; FA6158  add XBC,0x00fe1129
	ld	h, (xbc)                                ; FA615E  ld H,(XBC)
	ld	b, (xiz-3)                              ; FA6160  ld B,(XIZ+0xfd)
	and	b, h                                   ; FA6163  and B,H
	extpfx3 0x8E, 0xFC, 0xF2                   ; FA6165  cp B,(XIZ+0xfc)
	jr nz, sub_FA6110__FA61A5                  ; FA6168  jr NZ,0xfa61a5
	ld	c, h                                    ; FA616A  ld C,H
	and	c, 31                                  ; FA616C  and C,0x1f
	extz	bc                                    ; FA616F  extz BC
	extz	xbc                                   ; FA6171  extz XBC
	add	xbc, 0xFE10C9                          ; FA6173  add XBC,0x00fe10c9
	ld	e, (xbc)                                ; FA6179  ld E,(XBC)
	ld	l, d                                    ; FA617B  ld L,D
	ld	c, h                                    ; FA617D  ld C,H
	extz	bc                                    ; FA617F  extz BC
	sll	bc, 8                                  ; FA6181  sll 0x08,BC
	ld	(xiz-2), bc                             ; FA6184  ld (XIZ+0xfe),BC
sub_FA6110__FA6187:
	pushw	de                                   ; FA6187  push DE
	pushw	hl                                   ; FA6188  push HL
	calr (0xFA598C - 0xFA618C)                 ; FA6189  calr 0xfa598c
	extz	wa                                    ; FA618C  extz WA
	extpfx3 0x9E, 0xFE, 0xE0                   ; FA618E  or WA,(XIZ+0xfe)
	ld	(xix), wa                               ; FA6191  ld (XIX),WA
	inc	2, xix                                 ; FA6193  inc 2,XIX
	ldb	c, 5                                   ; FA6195  ld C,0x05
	mul8rr	c, l                                ; FA6197  mul BC,L
	extz	xbc                                   ; FA6199  extz XBC
	ld	l, (xbc+0xE3E)                          ; FA619B  ld L,(XBC+0x0e3e)
	pop	xiy                                    ; FA61A0  pop XIY
	cp	l, d                                    ; FA61A1  cp L,D
	jr nz, sub_FA6110__FA6187                  ; FA61A3  jr NZ,0xfa6187
sub_FA6110__FA61A5:
	incm8	1, (xiz-7)                           ; FA61A5  inc 1,(XIZ+0xf9)
	cp (xiz-7), 0x1B                           ; FA61A8  cp (XIZ+0xf9),0x1b
	jr c, sub_FA6110__FA613D                   ; FA61AC  jr C,0xfa613d
	extpfx4 0xB4, 0x02, 0xFF, 0xFF             ; FA61AE  ld (XIX),0xffff
	lda	xiy, (0x867A:24)                       ; FA61B2  lda XIY,0x00867a
	pop	xix                                    ; FA61B7  pop XIX
	popw	de                                    ; FA61B8  pop DE
	popw	hl                                    ; FA61B9  pop HL
	unlk32 xiz                                 ; FA61BA  unlk XIZ
	ret                                        ; FA61BC  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `VoiceSlots_ListChannelsOfPart` is now `VoiceSlots_ListChannelsOfPart`.
;   GRADE PROVEN.  WHY `VoiceSlots_ListChannelsOfPart`:
;   body: the same 0x0AA8 row walk, but for each surviving column it follows the
;   slot's owner byte [+4] into the 0x11FE ring and appends CHANNEL numbers to
;   the buffer at RAM 0x00877E, 0xFF-terminated.
;   ⚠ NOT REFERENCED (see VoiceSlots_ReleaseThenLookup).
; VoiceSlots_ListChannelsOfPart -- 0xFA61BD..0xFA6268 (172 bytes)
;
; Called from: no site outside this module.
;          ⚠ NOT FOUND -- no literal call/calr/jp reaches this address anywhere
;          in the image.  A register-indirect call would be invisible to that
;          scan, so this is "not found", not "dead".
; Inputs:  frame `link XIZ,-6`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA61BD-0xFA6268
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
VoiceSlots_ListChannelsOfPart:
	link32 0xEE, 0x0C, 0xFA, 0xFF              ; FA61BD  link XIZ,0xfffa
	pushw	hl                                   ; FA61C1  push HL
	pushw	de                                   ; FA61C2  push DE
	push	xix                                   ; FA61C3  push XIX
	ld	c, (xiz+12)                             ; FA61C4  ld C,(XIZ+0x0c)
	cpl	c                                      ; FA61C7  cpl C
	ld	(xiz-1), c                              ; FA61C9  ld (XIZ+0xff),C
	extpfx3 0x8E, 0x0A, 0xC3                   ; FA61CC  and C,(XIZ+0x0a)
	ld	(xiz-2), c                              ; FA61CF  ld (XIZ+0xfe),C
	ldb	c, 27                                  ; FA61D2  ld C,0x1b
	extpfx3 0x8E, 0x08, 0x43                   ; FA61D4  mul BC,(XIZ+0x08)
	ld	hl, bc                                  ; FA61D7  ld HL,BC
	ldw	wa, 0xAA8                              ; FA61D9  ld WA,0x0aa8
	add	wa, bc                                 ; FA61DC  add WA,BC
	ld	(xiz-4), wa                             ; FA61DE  ld (XIZ+0xfc),WA
	lda	xix, (0x877E:24)                       ; FA61E1  lda XIX,0x00877e
	ldb	e, 0                                   ; FA61E6  ld E,0x00
sub_FA61BD__FA61E8:
	ld	c, e                                    ; FA61E8  ld C,E
	extz	bc                                    ; FA61EA  extz BC
	ld	wa, (xiz-4)                             ; FA61EC  ld WA,(XIZ+0xfc)
	extz	xwa                                   ; FA61EF  extz XWA
	extpfx5 0xC3, 0x07, 0xE0, 0xE4, 0x26       ; FA61F1  ld H,(XWA+BC)
	cp	h, 0xC0                                 ; FA61F6  cp H,0xc0
	jr nc, sub_FA61BD__FA6254                  ; FA61F9  jr NC,0xfa6254
	ld	c, e                                    ; FA61FB  ld C,E
	extz	bc                                    ; FA61FD  extz BC
	extz	xbc                                   ; FA61FF  extz XBC
	add	xbc, 0xFE1129                          ; FA6201  add XBC,0x00fe1129
	ld	d, (xbc)                                ; FA6207  ld D,(XBC)
	ld	b, (xiz-1)                              ; FA6209  ld B,(XIZ+0xff)
	and	b, d                                   ; FA620C  and B,D
	extpfx3 0x8E, 0xFE, 0xF2                   ; FA620E  cp B,(XIZ+0xfe)
	jr nz, sub_FA61BD__FA6254                  ; FA6211  jr NZ,0xfa6254
	ldb	c, 5                                   ; FA6213  ld C,0x05
	mul8rr	c, h                                ; FA6215  mul BC,H
	inc	4, bc                                  ; FA6217  inc 4,BC
	extz	xbc                                   ; FA6219  extz XBC
	ld	h, (xbc+0xE3E)                          ; FA621B  ld H,(XBC+0x0e3e)
	cp	h, 64                                   ; FA6220  cp H,0x40
	jr nc, sub_FA61BD__FA6254                  ; FA6223  jr NC,0xfa6254
	ld	l, h                                    ; FA6225  ld L,H
	ld	c, d                                    ; FA6227  ld C,D
	and	c, 31                                  ; FA6229  and C,0x1f
	extz	bc                                    ; FA622C  extz BC
	extz	xbc                                   ; FA622E  extz XBC
	add	xbc, 0xFE10C9                          ; FA6230  add XBC,0x00fe10c9
	ld	d, (xbc)                                ; FA6236  ld D,(XBC)
sub_FA61BD__FA6238:
	ld	(xix), h                                ; FA6238  ld (XIX),H
	inc	1, xix                                 ; FA623A  inc 1,XIX
	ldb	c, 12                                  ; FA623C  ld C,0x0c
	mul8rr	c, l                                ; FA623E  mul BC,L
	ld	(xiz-6), bc                             ; FA6240  ld (XIZ+0xfa),BC
	ld	a, d                                    ; FA6243  ld A,D
	extz	wa                                    ; FA6245  extz WA
	add	bc, wa                                 ; FA6247  add BC,WA
	extz	xbc                                   ; FA6249  extz XBC
	ld	l, (xbc+0x11FE)                         ; FA624B  ld L,(XBC+0x11fe)
	cp	l, h                                    ; FA6250  cp L,H
	jr nz, sub_FA61BD__FA6238                  ; FA6252  jr NZ,0xfa6238
sub_FA61BD__FA6254:
	inc	1, e                                   ; FA6254  inc 1,E
	cp	e, 27                                   ; FA6256  cp E,0x1b
	jr c, sub_FA61BD__FA61E8                   ; FA6259  jr C,0xfa61e8
	ld	(xix), 0xFF                             ; FA625B  ld (XIX),0xff
	lda	xiy, (0x877E:24)                       ; FA625E  lda XIY,0x00877e
	pop	xix                                    ; FA6263  pop XIX
	popw	de                                    ; FA6264  pop DE
	popw	hl                                    ; FA6265  pop HL
	unlk32 xiz                                 ; FA6266  unlk XIZ
	ret                                        ; FA6268  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `VoiceSlots_ReapOrphansInBank` is now `VoiceSlots_ReapOrphansInBank`.
;   GRADE PROVEN.  WHY `VoiceSlots_ReapOrphansInBank`:
;   body: over the 48 slots of one bank (`mul BC,0x30` on the bank number, 4
;   banks x 48 = the 192 slots), any slot whose owner byte [+4] is > 0x40 and
;   whose part [+2] is not already 0x21 is put back on the free list.  Its one
;   caller is Dev10C_PollBankAndRetire's tail, once per bank sweep.
; VoiceSlots_ReapOrphansInBank -- 0xFA6269..0xFA62D9 (113 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFA69F3
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA5967 = Rec0E3E_GroupOfIndex, 0xFA5C43 = Rec0E3E_MoveToList
; Evidence: the listing below is the byte-identical round-trip of 0xFA6269-0xFA62D9
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
VoiceSlots_ReapOrphansInBank:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FA6269  link XIZ,0xfffc
	push	xhl                                   ; FA626D  push XHL
	push	xde                                   ; FA626E  push XDE
	pushw	ix                                   ; FA626F  push IX
	ldb	c, 48                                  ; FA6270  ld C,0x30
	extpfx3 0x8E, 0x08, 0x43                   ; FA6272  mul BC,(XIZ+0x08)
	ld	(xiz-2), bc                             ; FA6275  ld (XIZ+0xfe),BC
	ld	ix, bc                                  ; FA6278  ld IX,BC
	add	bc, 48                                 ; FA627A  add BC,0x0030
	ld	ix, bc                                  ; FA627E  ld IX,BC
	cp	(xiz-2), bc                             ; FA6280  cp (XIZ+0xfe),BC
	jr nc, sub_FA6269__FA62D4                  ; FA6283  jr NC,0xfa62d4
	ldw	wa, 5                                  ; FA6285  ld WA,0x0005
	extpfx3 0x9E, 0xFE, 0x40                   ; FA6288  mul XWA,(XIZ+0xfe)
	ld	(xiz-4), wa                             ; FA628B  ld (XIZ+0xfc),WA
	ld	hl, wa                                  ; FA628E  ld HL,WA
	inc	4, hl                                  ; FA6290  inc 4,HL
	ld	de, wa                                  ; FA6292  ld DE,WA
	inc	2, de                                  ; FA6294  inc 2,DE
sub_FA6269__FA6296:
	extz	xhl                                   ; FA6296  extz XHL
	ld	c, (xhl+0xE3E)                          ; FA6298  ld C,(XHL+0x0e3e)
	cp	c, 64                                   ; FA629D  cp C,0x40
	jr ule, sub_FA6269__FA62C6                 ; FA62A0  jr ULE,0xfa62c6
	extz	xde                                   ; FA62A2  extz XDE
	ld	c, (xde+0xE3E)                          ; FA62A4  ld C,(XDE+0x0e3e)
	cp	c, 33                                   ; FA62A9  cp C,0x21
	jr z, sub_FA6269__FA62C6                   ; FA62AC  jr Z,0xfa62c6
	ld	c, (xiz-2)                              ; FA62AE  ld C,(XIZ+0xfe)
	ld	(xiz-4), c                              ; FA62B1  ld (XIZ+0xfc),C
	pushw	bc                                   ; FA62B4  push BC
	calr (0xFA5967 - 0xFA62B8)                 ; FA62B5  calr 0xfa5967
	pushw	wa                                   ; FA62B8  push WA
	pushw	33                                   ; FA62B9  push 0x0021
	push	0                                     ; FA62BC  push 0x00
	extpfx3 0x8E, 0xFC, 0x04                   ; FA62BE  push (XIZ+0xfc)
	calr (0xFA5C43 - 0xFA62C4)                 ; FA62C1  calr 0xfa5c43
	inc	8, xsp                                 ; FA62C4  inc 0,XSP
sub_FA6269__FA62C6:
	inc	5, de                                  ; FA62C6  inc 5,DE
	inc	5, hl                                  ; FA62C8  inc 5,HL
	incw	1, (xiz-2)                            ; FA62CA  incw 1,(XIZ+0xfe)
	ld	bc, (xiz-2)                             ; FA62CD  ld BC,(XIZ+0xfe)
	cp	bc, ix                                  ; FA62D0  cp BC,IX
	jr c, sub_FA6269__FA6296                   ; FA62D2  jr C,0xfa6296
sub_FA6269__FA62D4:
	popw	ix                                    ; FA62D4  pop IX
	pop	xde                                    ; FA62D5  pop XDE
	pop	xhl                                    ; FA62D6  pop XHL
	unlk32 xiz                                 ; FA62D7  unlk XIZ
	ret                                        ; FA62D9  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `ChanRec_RelinkToPoolQueue` is now `ChanRec_RelinkToPoolQueue`.
;   GRADE PROVEN.  WHY `ChanRec_RelinkToPoolQueue`:
;   body: unlinks the channel record from the queue named by its OWN cursor
;   pair rec[+0x0F] (pool base) / rec[+0x11] (queue index), decrementing that
;   queue's occupancy byte at base+idx+0x10 or +0x17 (chosen by bit 0 of the
;   channel number rec[+0x14]); links it onto queue arg2 of pool arg1 through
;   the rec[+0x00]/rec[+0x02] link pair; stores the new cursor and increments
;   the new queue's occupancy byte.
; ChanRec_RelinkToPoolQueue -- 0xFA62DA..0xFA643E (357 bytes)
;
; Called from: no site outside this module.
;          5 site(s) inside this module:
;          0xFA6560 0xFA65EC 0xFA6641 0xFA6D50 0xFA6E37
; Inputs:  frame `link XIZ,-1`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA62DA-0xFA643E
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
ChanRec_RelinkToPoolQueue:
	link32 0xEE, 0x0C, 0xFF, 0xFF              ; FA62DA  link XIZ,0xffff
	push	xhl                                   ; FA62DE  push XHL
	push	xde                                   ; FA62DF  push XDE
	push	xix                                   ; FA62E0  push XIX
	ld	ix, (xiz+8)                             ; FA62E1  ld IX,(XIZ+0x08)
	extz	xix                                   ; FA62E4  extz XIX
	ld	ix, (xix+15)                            ; FA62E6  ld IX,(XIX+0x0f)
	ld	bc, (xiz+8)                             ; FA62E9  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA62EC  extz XBC
	ld	a, (xbc+17)                             ; FA62EE  ld A,(XBC+0x11)
	ld	(xiz-1), a                              ; FA62F1  ld (XIZ+0xff),A
	ld	h, (xbc+20)                             ; FA62F4  ld H,(XBC+0x14)
	ld	w, h                                    ; FA62F7  ld W,H
	and	w, 1                                   ; FA62F9  and W,0x01
	jr z, sub_FA62DA__FA631F                   ; FA62FC  jr Z,0xfa631f
	extz	wa                                    ; FA62FE  extz WA
	ld	hl, wa                                  ; FA6300  ld HL,WA
	add	wa, 23                                 ; FA6302  add WA,0x0017
	ld	hl, wa                                  ; FA6306  ld HL,WA
	extz	xix                                   ; FA6308  extz XIX
	extpfx5 0xC3, 0x07, 0xF0, 0xE0, 0x24       ; FA630A  ld D,(XIX+WA)
	cps	d, 0                                   ; FA630F  cp D,0
	jr z, sub_FA62DA__FA6341                   ; FA6311  jr Z,0xfa6341
	ld	c, d                                    ; FA6313  ld C,D
	dec	1, c                                   ; FA6315  dec 1,C
	extz	xwa                                   ; FA6317  extz XWA
	add	wa, ix                                 ; FA6319  add WA,IX
	ld	(xwa), c                                ; FA631B  ld (XWA),C
	jr sub_FA62DA__FA6341                      ; FA631D  jr T,0xfa6341
sub_FA62DA__FA631F:
	ld	de, (xiz-1)                             ; FA631F  ld DE,(XIZ+0xff)
	extz	de                                    ; FA6322  extz DE
	add	de, 16                                 ; FA6324  add DE,0x0010
	extz	xix                                   ; FA6328  extz XIX
	extpfx5 0xC3, 0x07, 0xF0, 0xE8, 0x26       ; FA632A  ld H,(XIX+DE)
	cps	h, 0                                   ; FA632F  cp H,0
	jr z, sub_FA62DA__FA6341                   ; FA6331  jr Z,0xfa6341
	ld	c, h                                    ; FA6333  ld C,H
	dec	1, c                                   ; FA6335  dec 1,C
	ld	h, c                                    ; FA6337  ld H,C
	ld	bc, ix                                  ; FA6339  ld BC,IX
	extz	xbc                                   ; FA633B  extz XBC
	add	bc, de                                 ; FA633D  add BC,DE
	ld	(xbc), h                                ; FA633F  ld (XBC),H
sub_FA62DA__FA6341:
	ldb	c, 2                                   ; FA6341  ld C,0x02
	extpfx3 0x8E, 0xFF, 0x43                   ; FA6343  mul BC,(XIZ+0xff)
	ld	hl, bc                                  ; FA6346  ld HL,BC
	inc	2, bc                                  ; FA6348  inc 2,BC
	ld	hl, bc                                  ; FA634A  ld HL,BC
	extz	xix                                   ; FA634C  extz XIX
	extpfx5 0xD3, 0x07, 0xF0, 0xE4, 0x20       ; FA634E  ld WA,(XIX+BC)
	extpfx3 0x9E, 0x08, 0xF0                   ; FA6353  cp WA,(XIZ+0x08)
	jr nz, sub_FA62DA__FA6375                  ; FA6356  jr NZ,0xfa6375
	ld	wa, (xiz+8)                             ; FA6358  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA635B  extz XWA
	ld	de, (xwa)                               ; FA635D  ld DE,(XWA)
	cp	de, wa                                  ; FA635F  cp DE,WA
	jr z, sub_FA62DA__FA636B                   ; FA6361  jr Z,0xfa636b
	extz	xbc                                   ; FA6363  extz XBC
	add	bc, ix                                 ; FA6365  add BC,IX
	ld	(xbc), de                               ; FA6367  ld (XBC),DE
	jr sub_FA62DA__FA6375                      ; FA6369  jr T,0xfa6375
sub_FA62DA__FA636B:
	sub	bc, bc                                 ; FA636B  sub BC,BC
	ld	wa, ix                                  ; FA636D  ld WA,IX
	extz	xwa                                   ; FA636F  extz XWA
	add	wa, hl                                 ; FA6371  add WA,HL
	ld	(xwa), bc                               ; FA6373  ld (XWA),BC
sub_FA62DA__FA6375:
	ldb	c, 2                                   ; FA6375  ld C,0x02
	extpfx3 0x8E, 0x0C, 0x43                   ; FA6377  mul BC,(XIZ+0x0c)
	ld	hl, bc                                  ; FA637A  ld HL,BC
	inc	2, bc                                  ; FA637C  inc 2,BC
	ld	hl, bc                                  ; FA637E  ld HL,BC
	ld	de, (xiz+10)                            ; FA6380  ld DE,(XIZ+0x0a)
	extz	xde                                   ; FA6383  extz XDE
	extpfx5 0xD3, 0x07, 0xE8, 0xE4, 0x22       ; FA6385  ld DE,(XDE+BC)
	sub	wa, wa                                 ; FA638A  sub WA,WA
	cp	de, wa                                  ; FA638C  cp DE,WA
	jr nz, sub_FA62DA__FA63BE                  ; FA638E  jr NZ,0xfa63be
	extz	xbc                                   ; FA6390  extz XBC
	extpfx3 0x9E, 0x0A, 0x81                   ; FA6392  add BC,(XIZ+0x0a)
	ld	wa, (xiz+8)                             ; FA6395  ld WA,(XIZ+0x08)
	ld	(xbc), wa                               ; FA6398  ld (XBC),WA
	ld	bc, (xiz+8)                             ; FA639A  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA639D  extz XBC
	ld	hl, (xbc)                               ; FA639F  ld HL,(XBC)
	ld	de, (xbc+2)                             ; FA63A1  ld DE,(XBC+0x02)
	extz	xde                                   ; FA63A4  extz XDE
	ld	(xde), hl                               ; FA63A6  ld (XDE),HL
	extz	xhl                                   ; FA63A8  extz XHL
	ld	(xhl+2), de                             ; FA63AA  ld (XHL+0x02),DE
	ld	bc, (xiz+8)                             ; FA63AD  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA63B0  extz XBC
	ld	(xbc), bc                               ; FA63B2  ld (XBC),BC
	ld	bc, (xiz+8)                             ; FA63B4  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA63B7  extz XBC
	ld	(xbc+2), bc                             ; FA63B9  ld (XBC+0x02),BC
	jr sub_FA62DA__FA63F2                      ; FA63BC  jr T,0xfa63f2
sub_FA62DA__FA63BE:
	ld	bc, (xiz+8)                             ; FA63BE  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA63C1  extz XBC
	ld	hl, (xbc)                               ; FA63C3  ld HL,(XBC)
	ld	ix, (xbc+2)                             ; FA63C5  ld IX,(XBC+0x02)
	extz	xix                                   ; FA63C8  extz XIX
	ld	(xix), hl                               ; FA63CA  ld (XIX),HL
	extz	xhl                                   ; FA63CC  extz XHL
	ld	(xhl+2), ix                             ; FA63CE  ld (XHL+0x02),IX
	extz	xde                                   ; FA63D1  extz XDE
	ld	hl, (xde+2)                             ; FA63D3  ld HL,(XDE+0x02)
	extz	xhl                                   ; FA63D6  extz XHL
	ld	bc, (xiz+8)                             ; FA63D8  ld BC,(XIZ+0x08)
	ld	(xhl), bc                               ; FA63DB  ld (XHL),BC
	ld	bc, (xiz+8)                             ; FA63DD  ld BC,(XIZ+0x08)
	ld	(xde+2), bc                             ; FA63E0  ld (XDE+0x02),BC
	ld	bc, (xiz+8)                             ; FA63E3  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA63E6  extz XBC
	ld	(xbc), de                               ; FA63E8  ld (XBC),DE
	ld	bc, (xiz+8)                             ; FA63EA  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA63ED  extz XBC
	ld	(xbc+2), hl                             ; FA63EF  ld (XBC+0x02),HL
sub_FA62DA__FA63F2:
	ld	bc, (xiz+8)                             ; FA63F2  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA63F5  extz XBC
	ld	wa, (xiz+10)                            ; FA63F7  ld WA,(XIZ+0x0a)
	ld	(xbc+15), wa                            ; FA63FA  ld (XBC+0x0f),WA
	ld	bc, (xiz+8)                             ; FA63FD  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA6400  extz XBC
	ld	a, (xiz+12)                             ; FA6402  ld A,(XIZ+0x0c)
	ld	(xbc+17), a                             ; FA6405  ld (XBC+0x11),A
	ld	bc, (xiz+8)                             ; FA6408  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA640B  extz XBC
	ld	h, (xbc+20)                             ; FA640D  ld H,(XBC+0x14)
	ld	a, h                                    ; FA6410  ld A,H
	and	a, 1                                   ; FA6412  and A,0x01
	jr z, sub_FA62DA__FA6429                   ; FA6415  jr Z,0xfa6429
	ld	wa, (xiz+12)                            ; FA6417  ld WA,(XIZ+0x0c)
	extz	wa                                    ; FA641A  extz WA
	add	wa, 23                                 ; FA641C  add WA,0x0017
	extz	xwa                                   ; FA6420  extz XWA
	extpfx3 0x9E, 0x0A, 0x80                   ; FA6422  add WA,(XIZ+0x0a)
	incm8	1, (xwa)                             ; FA6425  inc 1,(XWA)
	jr sub_FA62DA__FA6439                      ; FA6427  jr T,0xfa6439
sub_FA62DA__FA6429:
	ld	bc, (xiz+12)                            ; FA6429  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FA642C  extz BC
	add	bc, 16                                 ; FA642E  add BC,0x0010
	extz	xbc                                   ; FA6432  extz XBC
	extpfx3 0x9E, 0x0A, 0x81                   ; FA6434  add BC,(XIZ+0x0a)
	incm8	1, (xbc)                             ; FA6437  inc 1,(XBC)
sub_FA62DA__FA6439:
	pop	xix                                    ; FA6439  pop XIX
	pop	xde                                    ; FA643A  pop XDE
	pop	xhl                                    ; FA643B  pop XHL
	unlk32 xiz                                 ; FA643C  unlk XIZ
	ret                                        ; FA643E  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `ChanRec_RelinkToPartQueue` is now `ChanRec_RelinkToPartQueue`.
;   GRADE PROVEN.  WHY `ChanRec_RelinkToPartQueue`:
;   the same routine one link pair over: it uses rec[+0x04]/rec[+0x06] as the
;   links and rec[+0x0C]/rec[+0x0E] as the cursor, and keeps no occupancy count.
;   ChanRec_Release passes it 0x041C + 6*33 -- the row one past the 33 parts.
; ChanRec_RelinkToPartQueue -- 0xFA643F..0xFA6527 (233 bytes)
;
; Called from: no site outside this module.
;          4 site(s) inside this module:
;          0xFA656F 0xFA6D5A 0xFA6F1D 0xFA6F76
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA643F-0xFA6527
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
ChanRec_RelinkToPartQueue:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA643F  link XIZ,0x0000
	push	xhl                                   ; FA6443  push XHL
	push	xde                                   ; FA6444  push XDE
	push	xix                                   ; FA6445  push XIX
	ld	hl, (xiz+8)                             ; FA6446  ld HL,(XIZ+0x08)
	extz	xhl                                   ; FA6449  extz XHL
	ld	hl, (xhl+12)                            ; FA644B  ld HL,(XHL+0x0c)
	ld	bc, (xiz+8)                             ; FA644E  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA6451  extz XBC
	ld	a, (xbc+14)                             ; FA6453  ld A,(XBC+0x0e)
	mul	a, 2                                   ; FA6456  mul A,0x02
	ld	de, wa                                  ; FA6459  ld DE,WA
	inc	2, wa                                  ; FA645B  inc 2,WA
	ld	de, wa                                  ; FA645D  ld DE,WA
	extz	xhl                                   ; FA645F  extz XHL
	extpfx5 0xD3, 0x07, 0xEC, 0xE0, 0x25       ; FA6461  ld IY,(XHL+WA)
	cp	iy, bc                                  ; FA6466  cp IY,BC
	jr nz, sub_FA643F__FA6488                  ; FA6468  jr NZ,0xfa6488
	ld	ix, bc                                  ; FA646A  ld IX,BC
	extz	xbc                                   ; FA646C  extz XBC
	ld	ix, (xbc+4)                             ; FA646E  ld IX,(XBC+0x04)
	extpfx3 0x9E, 0x08, 0xF4                   ; FA6471  cp IX,(XIZ+0x08)
	jr z, sub_FA643F__FA647E                   ; FA6474  jr Z,0xfa647e
	extz	xwa                                   ; FA6476  extz XWA
	add	wa, hl                                 ; FA6478  add WA,HL
	ld	(xwa), ix                               ; FA647A  ld (XWA),IX
	jr sub_FA643F__FA6488                      ; FA647C  jr T,0xfa6488
sub_FA643F__FA647E:
	sub	bc, bc                                 ; FA647E  sub BC,BC
	ld	wa, hl                                  ; FA6480  ld WA,HL
	extz	xwa                                   ; FA6482  extz XWA
	add	wa, de                                 ; FA6484  add WA,DE
	ld	(xwa), bc                               ; FA6486  ld (XWA),BC
sub_FA643F__FA6488:
	ldb	c, 2                                   ; FA6488  ld C,0x02
	extpfx3 0x8E, 0x0C, 0x43                   ; FA648A  mul BC,(XIZ+0x0c)
	ld	hl, bc                                  ; FA648D  ld HL,BC
	inc	2, bc                                  ; FA648F  inc 2,BC
	ld	hl, bc                                  ; FA6491  ld HL,BC
	ld	de, (xiz+10)                            ; FA6493  ld DE,(XIZ+0x0a)
	extz	xde                                   ; FA6496  extz XDE
	extpfx5 0xD3, 0x07, 0xE8, 0xE4, 0x22       ; FA6498  ld DE,(XDE+BC)
	sub	wa, wa                                 ; FA649D  sub WA,WA
	cp	de, wa                                  ; FA649F  cp DE,WA
	jr nz, sub_FA643F__FA64D4                  ; FA64A1  jr NZ,0xfa64d4
	extz	xbc                                   ; FA64A3  extz XBC
	extpfx3 0x9E, 0x0A, 0x81                   ; FA64A5  add BC,(XIZ+0x0a)
	ld	wa, (xiz+8)                             ; FA64A8  ld WA,(XIZ+0x08)
	ld	(xbc), wa                               ; FA64AB  ld (XBC),WA
	ld	bc, (xiz+8)                             ; FA64AD  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA64B0  extz XBC
	ld	hl, (xbc+4)                             ; FA64B2  ld HL,(XBC+0x04)
	ld	de, (xbc+6)                             ; FA64B5  ld DE,(XBC+0x06)
	extz	xde                                   ; FA64B8  extz XDE
	ld	(xde+4), hl                             ; FA64BA  ld (XDE+0x04),HL
	extz	xhl                                   ; FA64BD  extz XHL
	ld	(xhl+6), de                             ; FA64BF  ld (XHL+0x06),DE
	ld	bc, (xiz+8)                             ; FA64C2  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA64C5  extz XBC
	ld	(xbc+4), bc                             ; FA64C7  ld (XBC+0x04),BC
	ld	bc, (xiz+8)                             ; FA64CA  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA64CD  extz XBC
	ld	(xbc+6), bc                             ; FA64CF  ld (XBC+0x06),BC
	jr sub_FA643F__FA650C                      ; FA64D2  jr T,0xfa650c
sub_FA643F__FA64D4:
	ld	bc, (xiz+8)                             ; FA64D4  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA64D7  extz XBC
	ld	hl, (xbc+4)                             ; FA64D9  ld HL,(XBC+0x04)
	ld	ix, (xbc+6)                             ; FA64DC  ld IX,(XBC+0x06)
	extz	xix                                   ; FA64DF  extz XIX
	ld	(xix+4), hl                             ; FA64E1  ld (XIX+0x04),HL
	extz	xhl                                   ; FA64E4  extz XHL
	ld	(xhl+6), ix                             ; FA64E6  ld (XHL+0x06),IX
	extz	xde                                   ; FA64E9  extz XDE
	ld	hl, (xde+6)                             ; FA64EB  ld HL,(XDE+0x06)
	extz	xhl                                   ; FA64EE  extz XHL
	ld	bc, (xiz+8)                             ; FA64F0  ld BC,(XIZ+0x08)
	ld	(xhl+4), bc                             ; FA64F3  ld (XHL+0x04),BC
	ld	bc, (xiz+8)                             ; FA64F6  ld BC,(XIZ+0x08)
	ld	(xde+6), bc                             ; FA64F9  ld (XDE+0x06),BC
	ld	bc, (xiz+8)                             ; FA64FC  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA64FF  extz XBC
	ld	(xbc+4), de                             ; FA6501  ld (XBC+0x04),DE
	ld	bc, (xiz+8)                             ; FA6504  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA6507  extz XBC
	ld	(xbc+6), hl                             ; FA6509  ld (XBC+0x06),HL
sub_FA643F__FA650C:
	ld	bc, (xiz+8)                             ; FA650C  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA650F  extz XBC
	ld	wa, (xiz+10)                            ; FA6511  ld WA,(XIZ+0x0a)
	ld	(xbc+12), wa                            ; FA6514  ld (XBC+0x0c),WA
	ld	bc, (xiz+8)                             ; FA6517  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA651A  extz XBC
	ld	a, (xiz+12)                             ; FA651C  ld A,(XIZ+0x0c)
	ld	(xbc+14), a                             ; FA651F  ld (XBC+0x0e),A
	pop	xix                                    ; FA6522  pop XIX
	pop	xde                                    ; FA6523  pop XDE
	pop	xhl                                    ; FA6524  pop XHL
	unlk32 xiz                                 ; FA6525  unlk XIZ
	ret                                        ; FA6527  ret
; --------------------------------------------------------------------------
; ★ ChanRec_Release -- take one CHANNEL RECORD out of service.  (round 2, 2026-08-25)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFA6892 (VoiceSubsystem_Init, for all 64 records in a row)
;          0xFA6989 (Dev10C_PollBankAndRetire, for one channel the device stopped
;                    reporting as busy)
; Inputs:  (XIZ+0x08) = the address of a 23-byte channel record in the array at
;          RAM 0x04E8 (see the block comment on VoiceSubsystem_Init below).
; Outputs: rec[+0x12] = 0x01 exactly; rec[+0x15] = 0; the record UNLINKED from the
;          doubly-linked list it was on (rec[+0x08] = prev, rec[+0x0A] = next:
;          `(next+0x08) = prev`, `(prev+0x0A) = next`, then both of the record's own
;          links point at itself); the byte at `(rec[+0x0F]) + 1` decremented if it
;          was non-zero; and two list helpers called with the POINTERS 0x03FE and
;          0x04E2.
;          ⚠ CORRECTED 2026-08-25 (round-2 audit, F4).  This line used to read
;          "the heads 0x03FE and 0x041C" -- it quoted the first argument as the
;          SUM and the second as the BASE, two conventions in one sentence.  Both
;          arguments are sums: `ld BC,0x0200 / add BC,0x01fe` (0xFA6557/0xFA655A)
;          gives 0x03FE, and `ld BC,0x041c / add BC,0x00c6` (0xFA6566/0xFA6569)
;          gives 0x04E2 -- which is 0x041C, the value init puts in rec[+0x0C],
;          plus 0xC6.  Each helper also takes a third argument, pushed first:
;          6 for 0xFA62DA (0xFA6554) and 1 for 0xFA643F (0xFA6563).
; Evidence: ★ IT IS THE ONLY WRITER OF THE FLAG VALUE EVERY OTHER SITE TESTS FOR.
;          `ld (XIX+0x12),0x01` at 0xFA6594 and `ld (XIX+0x15),0x00` at 0xFA6598 are
;          the two stores; the guard at the top, `ld C,(XIX+0x12) / and C,0x01 /
;          jrl NZ` (0xFA6534-0xFA653A), makes the routine idempotent, and the same
;          `and A,0x01` guard appears in Dev10C_PollBankAndRetire at 0xFA6983.  The
;          unlink is 0xFA6572-0xFA6591 read as instructions.  All four stores are
;          asserted from the ROM bytes by `python3 notes/prom_c_voice_sweep_checks.py`
;          section 5.
; Unknown:  ⚠ what 0xFA62DA and 0xFA643F do with the pointers 0x03FE and 0x04E2, so
;          "release" here means the unlink plus the flag byte and NOT a decoded
;          allocator.  What rec[+0x0F]'s [+0x00]/[+0x01] pair counts.
; --------------------------------------------------------------------------
ChanRec_Release:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FA6528  link XIZ,0xfffc
	push	xhl                                   ; FA652C  push XHL
	push	xde                                   ; FA652D  push XDE
	push	xix                                   ; FA652E  push XIX
	ld	ix, (xiz+8)                             ; FA652F  ld IX,(XIZ+0x08)
	extz	xix                                   ; FA6532  extz XIX
	ld	c, (xix+18)                             ; FA6534  ld C,(XIX+0x12)
	and	c, 1                                   ; FA6537  and C,0x01
	jrl nz, sub_FA6528__FA65B7                 ; FA653A  jrl NZ,0xfa65b7
	extz	xix                                   ; FA653D  extz XIX
	ld	de, (xix+15)                            ; FA653F  ld DE,(XIX+0x0f)
	extz	xde                                   ; FA6542  extz XDE
	ld	h, (xde+1)                              ; FA6544  ld H,(XDE+0x01)
	cps	h, 0                                   ; FA6547  cp H,0
	jr z, sub_FA6528__FA6554                   ; FA6549  jr Z,0xfa6554
	ld	c, h                                    ; FA654B  ld C,H
	dec	1, c                                   ; FA654D  dec 1,C
	extz	xde                                   ; FA654F  extz XDE
	ld	(xde+1), c                              ; FA6551  ld (XDE+0x01),C
sub_FA6528__FA6554:
	pushw	6                                    ; FA6554  push 0x0006
	ldw	bc, 0x200                              ; FA6557  ld BC,0x0200
	add	bc, 0x1FE                              ; FA655A  add BC,0x01fe
	pushw	bc                                   ; FA655E  push BC
	pushw	ix                                   ; FA655F  push IX
	calr (0xFA62DA - 0xFA6563)                 ; FA6560  calr 0xfa62da
	pushw	1                                    ; FA6563  push 0x0001
	ldw	bc, 0x41C                              ; FA6566  ld BC,0x041c
	add	bc, 0xC6                               ; FA6569  add BC,0x00c6
	pushw	bc                                   ; FA656D  push BC
	pushw	ix                                   ; FA656E  push IX
	calr (0xFA643F - 0xFA6572)                 ; FA656F  calr 0xfa643f
	ld	bc, (xix+8)                             ; FA6572  ld BC,(XIX+0x08)
	ld	(xiz-2), bc                             ; FA6575  ld (XIZ+0xfe),BC
	ld	wa, (xix+10)                            ; FA6578  ld WA,(XIX+0x0a)
	ld	(xiz-4), wa                             ; FA657B  ld (XIZ+0xfc),WA
	extz	xwa                                   ; FA657E  extz XWA
	ld	(xwa+8), bc                             ; FA6580  ld (XWA+0x08),BC
	ld	bc, (xiz-2)                             ; FA6583  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FA6586  extz XBC
	ld	wa, (xiz-4)                             ; FA6588  ld WA,(XIZ+0xfc)
	ld	(xbc+10), wa                            ; FA658B  ld (XBC+0x0a),WA
	ld	(xix+8), ix                             ; FA658E  ld (XIX+0x08),IX
	ld	(xix+10), ix                            ; FA6591  ld (XIX+0x0a),IX
	ld	(xix+18), 1                             ; FA6594  ld (XIX+0x12),0x01
	ld	(xix+21), 0                             ; FA6598  ld (XIX+0x15),0x00
	ld	hl, (xix+15)                            ; FA659C  ld HL,(XIX+0x0f)
	extz	xhl                                   ; FA659F  extz XHL
	ld	e, (xhl)                                ; FA65A1  ld E,(XHL)
	ld	d, (xhl+1)                              ; FA65A3  ld D,(XHL+0x01)
	inc	8, xsp                                 ; FA65A6  inc 0,XSP
	inc	4, xsp                                 ; FA65A8  inc 4,XSP
	cp	d, e                                    ; FA65AA  cp D,E
	jr nc, sub_FA6528__FA65B7                  ; FA65AC  jr NC,0xfa65b7
	ld	c, d                                    ; FA65AE  ld C,D
	inc	1, c                                   ; FA65B0  inc 1,C
	extz	xhl                                   ; FA65B2  extz XHL
	ld	(xhl+1), c                              ; FA65B4  ld (XHL+0x01),C
sub_FA6528__FA65B7:
	pop	xix                                    ; FA65B7  pop XIX
	pop	xde                                    ; FA65B8  pop XDE
	pop	xhl                                    ; FA65B9  pop XHL
	unlk32 xiz                                 ; FA65BA  unlk XIZ
	ret                                        ; FA65BC  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `ChanRec_ToPoolQueue6_SetFlag1` is now `ChanRec_ToPoolQueue6_SetFlag1`.
;   GRADE PROVEN.  WHY `ChanRec_ToPoolQueue6_SetFlag1`:
;   body: if rec[+0x12] & 3 is zero, clear flag bits 2 and 3, set bit 1, and
;   ChanRec_RelinkToPoolQueue(rec, rec[+0x0F], 6) -- queue 6 of the record's own
;   pool, which is the queue ChanRec_Release also uses.
; ChanRec_ToPoolQueue6_SetFlag1 -- 0xFA65BD..0xFA65F5 (57 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFA6614 0xFA69DA
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA62DA = ChanRec_RelinkToPoolQueue
; Evidence: the listing below is the byte-identical round-trip of 0xFA65BD-0xFA65F5
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
ChanRec_ToPoolQueue6_SetFlag1:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA65BD  link XIZ,0x0000
	pushw	hl                                   ; FA65C1  push HL
	push	xde                                   ; FA65C2  push XDE
	ld	de, (xiz+8)                             ; FA65C3  ld DE,(XIZ+0x08)
	extz	xde                                   ; FA65C6  extz XDE
	ld	h, (xde+18)                             ; FA65C8  ld H,(XDE+0x12)
	ld	c, h                                    ; FA65CB  ld C,H
	and	c, 3                                   ; FA65CD  and C,0x03
	jr nz, sub_FA65BD__FA65F1                  ; FA65D0  jr NZ,0xfa65f1
	ld	l, h                                    ; FA65D2  ld L,H
	and	l, 0xF3                                ; FA65D4  and L,0xf3
	extz	xde                                   ; FA65D7  extz XDE
	ld	(xde+18), l                             ; FA65D9  ld (XDE+0x12),L
	ld	c, l                                    ; FA65DC  ld C,L
	set	1, c                                   ; FA65DE  set 0x01,C
	ld	(xde+18), c                             ; FA65E1  ld (XDE+0x12),C
	pushw	6                                    ; FA65E4  push 0x0006
	ld	bc, (xde+15)                            ; FA65E7  ld BC,(XDE+0x0f)
	pushw	bc                                   ; FA65EA  push BC
	pushw	de                                   ; FA65EB  push DE
	calr (0xFA62DA - 0xFA65EF)                 ; FA65EC  calr 0xfa62da
	inc	6, xsp                                 ; FA65EF  inc 6,XSP
sub_FA65BD__FA65F1:
	pop	xde                                    ; FA65F1  pop XDE
	popw	hl                                    ; FA65F2  pop HL
	unlk32 xiz                                 ; FA65F3  unlk XIZ
	ret                                        ; FA65F5  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `ChanRec_BeginRelease` is now `ChanRec_BeginRelease`.
;   GRADE PROVEN.  WHY `ChanRec_BeginRelease`:
;   body: held channels (flag bit 7) are left alone; a channel whose cached
;   0x0180 read-back rec[+0x15] has fallen below 0x80 goes to
;   ChanRec_ToPoolQueue6_SetFlag1; otherwise, if flag bit 3 is set, bit 3 is
;   cleared, bit 2 set, and the record relinked to pool queue rec[+0x16].
; ChanRec_BeginRelease -- 0xFA65F6..0xFA664A (85 bytes)
;
; Called from: no site outside this module.
;          3 site(s) inside this module:
;          0xFA6EF0 0xFA6F21 0xFA6F7A
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA62DA = ChanRec_RelinkToPoolQueue, 0xFA65BD = ChanRec_ToPoolQueue6_SetFlag1
; Evidence: the listing below is the byte-identical round-trip of 0xFA65F6-0xFA664A
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
ChanRec_BeginRelease:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA65F6  link XIZ,0x0000
	pushw	hl                                   ; FA65FA  push HL
	push	xde                                   ; FA65FB  push XDE
	ld	de, (xiz+8)                             ; FA65FC  ld DE,(XIZ+0x08)
	extz	xde                                   ; FA65FF  extz XDE
	ld	c, (xde+18)                             ; FA6601  ld C,(XDE+0x12)
	and	c, 0x80                                ; FA6604  and C,0x80
	jr nz, sub_FA65F6__FA6646                  ; FA6607  jr NZ,0xfa6646
	extz	xde                                   ; FA6609  extz XDE
	ld	c, (xde+21)                             ; FA660B  ld C,(XDE+0x15)
	cp	c, 0x80                                 ; FA660E  cp C,0x80
	jr nc, sub_FA65F6__FA661A                  ; FA6611  jr NC,0xfa661a
	pushw	de                                   ; FA6613  push DE
	calr (0xFA65BD - 0xFA6617)                 ; FA6614  calr 0xfa65bd
	popw	bc                                    ; FA6617  pop BC
	jr sub_FA65F6__FA6646                      ; FA6618  jr T,0xfa6646
sub_FA65F6__FA661A:
	extz	xde                                   ; FA661A  extz XDE
	ld	h, (xde+18)                             ; FA661C  ld H,(XDE+0x12)
	ld	c, h                                    ; FA661F  ld C,H
	and	c, 8                                   ; FA6621  and C,0x08
	jr z, sub_FA65F6__FA6646                   ; FA6624  jr Z,0xfa6646
	ld	l, h                                    ; FA6626  ld L,H
	res	3, l                                   ; FA6628  res 0x03,L
	extz	xde                                   ; FA662B  extz XDE
	ld	(xde+18), l                             ; FA662D  ld (XDE+0x12),L
	ld	c, l                                    ; FA6630  ld C,L
	set	2, c                                   ; FA6632  set 0x02,C
	ld	(xde+18), c                             ; FA6635  ld (XDE+0x12),C
	ld	c, (xde+22)                             ; FA6638  ld C,(XDE+0x16)
	pushw	bc                                   ; FA663B  push BC
	ld	bc, (xde+15)                            ; FA663C  ld BC,(XDE+0x0f)
	pushw	bc                                   ; FA663F  push BC
	pushw	de                                   ; FA6640  push DE
	calr (0xFA62DA - 0xFA6644)                 ; FA6641  calr 0xfa62da
	inc	6, xsp                                 ; FA6644  inc 6,XSP
sub_FA65F6__FA6646:
	pop	xde                                    ; FA6646  pop XDE
	popw	hl                                    ; FA6647  pop HL
	unlk32 xiz                                 ; FA6648  unlk XIZ
	ret                                        ; FA664A  ret
; --------------------------------------------------------------------------
; ==============================================================================
; ★★ WAVE 17 -- THE VOICE ALLOCATOR: POOLS, QUEUES, AND WHAT STEALS A VOICE
; ==============================================================================
; ADDED 2026-09-03 by the voice-engine lane, insertions only under
; `scripts/analysis/assert_comments_preserved.py`.  Every `; sub_FAxxxx -- 0x...`
; header line below still spells an address-form name where the label has been
; renamed; the `★ NAMED (wave 17)` block in front of each carries the current
; label, and supersedes that header's `Unknown: what the routine is FOR` line.
; The table and the applier are `wsa1/notes/prom_c_voice_names_w17.py`.
;
; The whole of section 2 of the wave-17 block in note_engine.s -- the lifecycle --
; is implemented by the routines in THIS file.  What follows is the data structure
; those routines move records between.
;
; ★ EVERY NUMBER IN THIS BLOCK IS RE-DERIVED FROM THE ROM BYTES -- never from
;   this file and never from a disassembler's text -- by
;       python3 wsa1/notes/prom_c_voice_engine_w17_checks.py --selftest
;   whose --selftest also runs two NEGATIVE CONTROLS (a wrong stride and a
;   wrong table base) and requires both to go red.
;
; ------------------------------------------------------------------------------
; A. THE POOL, THE PART ROW, AND THE TWO LISTS EVERY CHANNEL RECORD IS ON
; ------------------------------------------------------------------------------
; A RESOURCE POOL is 30 bytes at RAM 0x0200 + 30*p, p = 0..17.  Its shape is read
; off VoiceSubsystem_Init's initialiser (`cp D,7` at 0xFA6770 counts the queues,
; `add HL,0x001e` at 0xFA6774 is the stride, `cp (XIZ-7),0x12` at 0xFA677B the
; count) and off the two relink routines' arithmetic:
;
;     +0x00  u8     LIMIT           -- from ROM, see C below
;     +0x01  u8     COUNT           -- channels currently charged to this pool
;     +0x02  u16[7] QUEUE HEADS     -- queue q's head is at +0x02 + 2*q
;     +0x10  u8[7]  EVEN OCCUPANCY  -- queue q, channels with (chan & 1) == 0
;     +0x17  u8[7]  ODD OCCUPANCY   -- queue q, channels with (chan & 1) == 1
;
; A PART ROW is 6 bytes at RAM 0x041C + 6*part, part = 0..33:
;
;     +0x00  u16    the base address of the POOL this part draws from
;     +0x02  u16    queue 0 head   -- the part's SOUNDING channels
;     +0x04  u16    queue 1 head   -- the part's RELEASED channels
;
; Every one of the 64 channel records at 0x04E8 is on one queue of each at all
; times, through TWO INDEPENDENT LINK PAIRS -- which is why the record carries
; four link words where two would do:
;
;     pool list   links rec[+0x00]/rec[+0x02], cursor rec[+0x0F] (pool base) and
;                 rec[+0x11] (queue 0..6); moved by ChanRec_RelinkToPoolQueue,
;                 which is the ONLY routine that touches the occupancy bytes.
;     part list   links rec[+0x04]/rec[+0x06], cursor rec[+0x0C] (part row) and
;                 rec[+0x0E] (queue 0 or 1); moved by ChanRec_RelinkToPartQueue.
;
; A third pair, rec[+0x08]/rec[+0x0A], is a transient list the note path splices
; and unsplices directly (ChanRec_ReleaseByChannel, ChanRec_ReleaseQueueAndCollect,
; ChanAlloc_ForNoteRequest's 0x0087D0 chain).
;
; ★ ROW 33 AND POOL 17 ARE THE UNASSIGNED ONES.  MidiNote_Dispatch refuses a part
;   index >= 0x21 = 33, so row 33 is one past every real part; ChanRec_Release
;   passes ChanRec_RelinkToPartQueue the address 0x04E2 = 0x041C + 6*33 and
;   ChanRec_RelinkToPoolQueue the address 0x03FE = 0x0200 + 30*17, queue 6.  At
;   boot VoiceSubsystem_Init calls ChanRec_Release on all 64 records in a row
;   (0xFA6891-0xFA68A1), so every channel starts on pool 17, queue 6.
;
; ------------------------------------------------------------------------------
; B. THE QUEUE NUMBER IS THE STEALING PRIORITY
; ------------------------------------------------------------------------------
; Seven queues per pool, and which one a record sits on is half of its state (the
; other half is the flag byte rec[+0x12]; see note_engine.s section 2):
;
;     queue 6   IDLE / FREE   -- ChanRec_Release and ChanRec_ToPoolQueue6_SetFlag1
;                               both put records here, and it is FIRST in every
;                               search order in ROM.
;     queues 5,4,3  RELEASING -- ChanRec_BeginRelease relinks to rec[+0x16], and
;                               rec[+0x16] is byte +5 of the allocation descriptor
;                               (section C), whose values in ROM are 3, 4 and 5.
;     queues 2,1,0  SOUNDING  -- ChanAlloc_ForNoteRequest links a freshly allocated
;                               record to byte +4 of the same descriptor, whose
;                               values in ROM are 0, 1 and 2.
;
; ★ AND THE SEARCH ORDERS IN ROM ARE IN THAT ORDER, descending.  The list at
;   0xFE11F8, the one the first descriptor names, reads
;       86 85 06 05 84 83 82 04 03 02 81 80 01 00 FF
;   -- bit 7 of an entry means "look in the OVERFLOW POOL (pool 16, base 0x03E0)
;   for that queue instead of in the part's own pool", and dropping bit 7 leaves
;   6 5 6 5 4 3 2 4 3 2 1 0 1 0 -- STRICTLY DESCENDING in queue number, free
;   first and the lowest-numbered sounding queue last, split into three TIERS
;   {6,5} {4,3,2} {1,0}; inside each tier the OVERFLOW copy comes first and the
;   own-pool copy repeats it.  So a note takes a free channel before a releasing
;   one and a releasing one before a sounding one, and within a tier it prefers a
;   voice already pushed out into the overflow pool over one still charged to the
;   part's own budget.
;   The other two lists are the same sequence TRUNCATED -- 0xFE1207 drops the last
;   entry (own queue 0) and 0xFE1215 stops after the second tier -- so an element
;   whose descriptor is k >= 2 can never steal a voice sitting on queue 1 or
;   queue 0, i.e. never one that descriptor k = 0 or k = 1 allocated.  The
;   truncation IS the priority between elements.
;
; ------------------------------------------------------------------------------
; C. ★★ THE POLYPHONY BUDGET IS IN ROM, AND BOTH COPIES OF IT SUM TO EXACTLY 64
; ------------------------------------------------------------------------------
; VoiceSubsystem_Init takes ONE argument and it selects between two complete
; allocation policies -- a limit table and a part-to-pool map each:
;
;   arg == 0    Table_FE1144 limits   18 u8:  24 24 16  0 x13  64 64
;               Table_FE1168 pool map 34 u16: part 0 -> pool 0, parts 1..7 ->
;                                             pool 1, parts 8..32 -> pool 2,
;                                             part 33 -> pool 17
;   arg != 0    Table_FE1156 limits   18 u8:  12 6 6 4 4 4 4 4 2 2 2 2 2 2 2 6
;                                             64 64
;               Table_FE11AC pool map 34 u16: parts 0..15 -> pools 0..15, parts
;                                             16..31 -> pools 0..15 again,
;                                             part 32 -> pool 15, part 33 -> pool 17
;
; ★ THE CHECK, AND IT IS NOT A WEAK ONE.  The used entries of BOTH limit tables sum
;   to exactly 64 -- 24 + 24 + 16 = 64, and 12+6+6+4+4+4+4+4+2+2+2+2+2+2+2+6 = 64 --
;   which is the channel count `cp H,0x40` fixes three other ways in this
;   subsystem.  The two tables share no byte pattern and were plainly authored
;   separately; two independent 16-entry byte tables both summing to exactly the
;   channel count is not what arbitrary data looks like.  Entries 16 and 17 are
;   both 0x40 in both tables: pool 16 is the overflow pool and pool 17 the free
;   pool, and each may hold all 64.
;   ⚠ WHAT IS AND IS NOT CLAIMED.  That the byte is a LIMIT is read off the code:
;   ChanRec_Release increments pool[+0x01] only `if pool[+0x01] < pool[+0x00]`
;   (0xFA65AA), and ChanAlloc_ForNoteRequest does the same test (0xFA6DE5) and
;   takes the overflow path when it fails.  That the two tables are "two allocation
;   MODES" is a reading of the one argument that selects them; WHICH mode the
;   machine uses when is not established here -- the argument comes from
;   sub_FADA7C and from ExtBoard_ProbeAndInstallBases.
;
; ★ THE ALLOCATION DESCRIPTORS, 6 bytes at 0xFE1220 + 6*k, k = req[+2+i] & 0x0F:
;       +0x00  u32  pointer to a 0xFF-terminated search order (section B)
;       +0x04  u8   the pool queue a newly allocated record is linked to
;       +0x05  u8   the pool queue ChanRec_BeginRelease will use, into rec[+0x16]
;   The first three, read out of the ROM bytes:
;       k=0  -> 0x00FE11F8, 0, 3      k=1  -> 0x00FE1207, 1, 3
;       k=2  -> 0x00FE1215, 2, 4      k>=3 -> 0x00FE1215, 2, 5
;
; ★ WHAT HAPPENS WHEN A POOL IS FULL, and it is not a refusal.  After
;   ChanAlloc_ForNoteRequest has taken a record it tests the new pool's
;   `count < limit`.  If the pool is AT its limit it walks the second search order
;   at 0xFE11F0 -- `06 05 02 04 03 01 00 FF` -- finds a record already in that pool,
;   moves it to the OVERFLOW pool 16 with ChanRec_RelinkToPoolQueue(rec, 0x03E0,
;   rec[+0x11]) keeping its queue number, bumps the overflow pool's count and sets
;   flag bit 4 (0xFA6E42).  So a part that exceeds its budget does not lose the new
;   note; it pushes an old one out of its own budget into the shared one, where
;   section B's search order will steal it first.
;
; ------------------------------------------------------------------------------
; D. THE OTHER THREE TABLES: THE SLOT MACHINERY
; ------------------------------------------------------------------------------
; Separate from the pool/part queues, and moved by a different set of routines,
; three more arrays bind each channel to up to four shared "slots":
;
;     0x11FE  64 x 12   per channel: next[4], prev[4], slot index[4].  Four
;                       independent rings, r = 0..3.  Rec11FE_UnlinkFromRing,
;                       Rec11FE_InsertIntoRing, Rec11FE_BindRingToSlot,
;                       Rec11FE_ReleaseAllRings.
;     0x0E3E  192 x 5   a slot: next, prev, part, column, owner-channel (0xFF when
;                       free).  Three groups of 64, and Rec0E3E_GroupOfIndex maps a
;                       slot index onto its group code 0 / 4 / 8.
;                       Rec0E3E_UnlinkFromRing, Rec0E3E_InsertBeforeInRing,
;                       Rec0E3E_MoveToList, Rec0E3E_FreeListHead.
;     0x0AA8  34 x 27   the head of the slot ring for (part, column).  Row 33 with
;                       columns 0 / 4 / 8 is the free list, which is where
;                       VoiceSlots_InitAllTables puts all 192 slots at boot.
;
; The consumer is Voice_LookupDev10CChanIndex, whose header below states the three
; arguments and their bounds; its result is a 0x0010C000 channel index that
; Voice_StageChanSel_Reg0440_Reg0480, Voice_StageRegs_0180_AB and
; Voice_StageChanSel_Reg04C0 hand to the Dev10C_Slot* accessors.
; ⚠ WHAT THIS MACHINERY IS FOR IS STILL NOT ESTABLISHED.  Its shape, its
;   invariants and its operations are; the musical role of a "slot" is not, and no
;   name in this file claims one -- Rec0E3E_ and Rec11FE_ name the ADDRESS of the
;   array, which is a fact, and the verb after it is what the body does.
; ==============================================================================
; ============================================================================
; ★★ THE 64 CHANNEL RECORDS, AND WHAT 0x0010C000 GIVES BACK   (round 2, 2026-08-25)
; ============================================================================
; Written against gap **F** of ../kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md,
; which asks whether the read at register block 0x0000 index 0..3 is "really an
; active-voice bitmap of 16 channels per bank" and what the read at 0x0180 + channel
; returns.  The driver answers 0 to both and says that answering 0 is a decision.
;
; Everything in this comment is asserted from the ROM bytes of
; original_ROMs/wsa1_prom_c.ic28 by `python3 notes/prom_c_voice_sweep_checks.py`
; (74 checks, FAILURES: 0).  The argument is in
; notes/FINDINGS-prom_c-voice-readback.md.
;
; ---------------------------------------------------------------------------
; A. THE CHANNEL RECORD ARRAY -- RAM 0x04E8, 64 records of 23 (0x17) bytes
; ---------------------------------------------------------------------------
; ★ COUNT AND STRIDE ARE BOTH IMMEDIATES IN THE INITIALISER BELOW, not inferences:
; `ld DE,0x04E8` (0xFA67FF) is the base, `add HL,0x0017` (0xFA687D) the stride and
; `cp (XIZ-7),0x40` (0xFA6884) the bound.  64 x 23 = 1472, so the array is
; 0x04E8-0x0AA7 and the LAST record, channel 63, is at 0x0A91.  Dev10C_PollBankAndRetire
; reaches exactly that record on the last pass of bank 3, by the same two constants.
;
;   off   w  set at init to      what else touches it
;   ----  -  ------------------  --------------------------------------------------
;   +0x00 2  the record itself   -- a list link, self-linked when idle
;   +0x02 2  the record itself   -- a list link
;   +0x04 2  the record itself   -- a list link
;   +0x06 2  the record itself   -- a list link
;   +0x08 2  the record itself   PREV: ChanRec_Release does `(next+0x08) = prev`
;   +0x0A 2  the record itself   NEXT: ChanRec_Release does `(prev+0x0A) = next`
;   +0x0C 2  0x041C              a RAM object shared by all 64 records
;   +0x0E 1  1
;   +0x0F 2  0x0200              a second shared object; ChanRec_Release decrements
;                                its byte [+0x01] when non-zero
;   +0x11 1  6
;   +0x12 1  0                   ★ THE FLAG BYTE -- see C below
;   +0x13 1  (not written)       ⚠ unaccounted
;   +0x14 1  the record's index  0..63; equal to the hardware channel number
;   +0x15 1  0                   ★ the cached 0x0180 read-back
;   +0x16 1  (not written)       ⚠ unaccounted
;
; ---------------------------------------------------------------------------
; B. THE TWO 64-BIT CHANNEL MASKS, AND HOW A CHANNEL NUMBER IS ENCODED
; ---------------------------------------------------------------------------
;   RAM 0x0087BF  4 words   the mask the device last reported, OR the hold mask
;   RAM 0x0087C7  4 words   the HOLD mask -- channels the software refuses to retire
;   RAM 0x0087CF  1 byte    the bank cursor, 0..3
;
; Both masks use ONE encoding: word index `chan >> 4`, bit `chan & 15`, built as
; `Shift16_Left(1, chan & 0x0F)` at 0xFA6CE3-0xFA6CF6 and used at three sites.  That
; is the same pairing Dev10C_PollBankAndRetire imposes on the word it READS from the
; device -- two independent routines agreeing, which is why the bitmap reading of
; register block 0 is a finding and not a guess.
;
; ★ 0x0087C7 IS THE HOLD MASK, and it tracks flag bit 7 exactly: the arm at 0xFA6CDC
; writes rec[+0x12] = 0x88 and SETS the channel's bit (0xFA6D01); its sibling at
; 0xFA6D07 writes 0x08 and CLEARS it (0xFA6D37).  Dev10C_PollBankAndRetire ORs this
; mask into the device word before differencing, so a held channel is never retired.
;
; ---------------------------------------------------------------------------
; C. THE FLAG BYTE rec[+0x12]
; ---------------------------------------------------------------------------
;   bit 0   the record is RELEASED.  ChanRec_Release is its only writer (it stores
;           exactly 0x01) and four separate guards test it to skip work.
;   bit 7   mirrors the channel's bit in the 0x0087C7 hold mask (see B).
;   bit 2   gates the low-read-back action in Dev10C_PollBankAndRetire (0xFA69D4).
;   bit 1   set by 0xFA65BD, which also clears bits 2 and 3.
;   bit 3   set together with the allocation (0x08 / 0x88).
;   ⚠ Only bits 0 and 7 are named above; 1, 2 and 3 are recorded by the sites that
;   write and test them and are NOT given roles.
;
; ---------------------------------------------------------------------------
; D. THE FOUR REGISTERS THAT SILENCE A CHANNEL
; ---------------------------------------------------------------------------
; The first arm of VoiceSubsystem_Init writes FOUR registers per channel for all 64,
; and it runs only when at least one of the four 0x0087BF words is non-zero -- i.e.
; only when something was sounding:
;
;   0x0840 + chan := 0xFF00      (0xFA669A)
;   0x0800 + chan := 0xFF80      (0xFA66A8)
;   0x00C0 + chan := 0x0000      (0xFA66B4)
;   0x0000 + chan := 0x7E00      (0xFA66C7)
;
; The same four constants appear nowhere else except in the three other routines that
; stop channels: Dev10C_ResetAllChannels (0x0800/0x0840 for all 64, 0xFB811E/0xFB8132),
; Dev10C_QuiesceListedChans_0800_0840 (the same pair per listed channel) and
; Dev10C_ChanReset (0x00C0 := 0 and block 0 := 0x7E00, 0xFB0AA4/0xFB0AB5).  So these
; four registers, with these four values, are what this firmware drives to stop a
; channel.  ⚠ That they SILENCE it is the obvious reading and is NOT asserted:
; nothing in this image reads any of the four back, and no measurement is involved.
; ============================================================================

; --------------------------------------------------------------------------
; ★★ VoiceSubsystem_Init -- silence every channel, build the 64 channel records,
;             release them all, and clear both masks.  (round 2, 2026-08-25)
;
; Called from: 2 site(s) outside this module:
;          0xFADAA1 in sub_FADA7C__FADAA1, 0xFB05D4 in ExtBoard_ProbeAndInstallBases__FB05CD
;          -- the second is on the boot path, four calls into MAIN's init chain.
; Inputs:  (XIZ+0x08) selects between the two 64-byte ROM tables at 0xFE1144 and
;          0xFE1156 that it copies into RAM 0x0200 (`cp (XIZ+0x08),0x00` at 0xFA66E2).
; Outputs: in order -- (1) if any 0x0087BF word is non-zero, the four-register silence
;          set of section D above for all 64 channels; (2) the RAM 0x0200 table filled
;          from ROM; (3) 64 channel records at 0x04E8 built to the layout in section A;
;          (4) ChanRec_Release called on every one of them (0xFA6891-0xFA68A1, a
;          64-pass loop); (5) the four words of 0x0087BF and the four of 0x0087C7
;          zeroed (0xFA68AA-0xFA68D1); (6) a call to 0xFA5D84.
; Evidence: the count 64 and the stride 23 are the immediates cited in section A, and
;          both are re-read from the ROM by `python3 notes/prom_c_voice_sweep_checks.py`
;          sections 7 and 8, which also asserts the LAST record's address, 0x0A91.
;          The listing below is the byte-identical round-trip of 0xFA664B-0xFA68DB
;          (notes/gen_prom_c_block.py, cleared by notes/prom_c_verify_fragment.py
;          before insertion).
; Unknown:  ⚠ what the two 64-byte ROM tables at 0xFE1144 / 0xFE1156 hold, and what
;          the argument that chooses between them means.  What the 0x041C and 0x0200
;          objects are.  ⚠ The middle section, 0xFA6727-0xFA67F9, is not decoded here.
; --------------------------------------------------------------------------
VoiceSubsystem_Init:
	link32 0xEE, 0x0C, 0xEF, 0xFF              ; FA664B  link XIZ,0xffef
	push	xhl                                   ; FA664F  push XHL
	pushw	de                                   ; FA6650  push DE
	push	xix                                   ; FA6651  push XIX
	ld	(xiz-7), 0                              ; FA6652  ld (XIZ+0xf9),0x00
	ldw	hl, 0                                  ; FA6656  ld HL,0x0000
VoiceSubsystem_Init__FA6659:
	ld	bc, hl                                  ; FA6659  ld BC,HL
	extz	xbc                                   ; FA665B  extz XBC
	add	xbc, 0x87BF                            ; FA665D  add XBC,0x000087bf
	ld	bc, (xbc)                               ; FA6663  ld BC,(XBC)
	cps	bc, 0                                  ; FA6665  cp BC,0
	jr nz, VoiceSubsystem_Init__FA6674                  ; FA6667  jr NZ,0xfa6674
	inc	2, hl                                  ; FA6669  inc 2,HL
	incm8	1, (xiz-7)                           ; FA666B  inc 1,(XIZ+0xf9)
	cp (xiz-7), 0x04                           ; FA666E  cp (XIZ+0xf9),0x04
	jr c, VoiceSubsystem_Init__FA6659                   ; FA6672  jr C,0xfa6659
VoiceSubsystem_Init__FA6674:
	cp (xiz-7), 0x04                           ; FA6674  cp (XIZ+0xf9),0x04
	jr nc, VoiceSubsystem_Init__FA66DB                  ; FA6678  jr NC,0xfa66db
	ld	(xiz-7), 0                              ; FA667A  ld (XIZ+0xf9),0x00
	ld	xix, 0x10C000                           ; FA667E  ld XIX,0x0010c000
	ld	xbc, xix                                ; FA6683  ld XBC,XIX
	inc	2, xbc                                 ; FA6685  inc 2,XBC
	ld	(xiz-6), xbc                            ; FA6687  ld (XIZ+0xfa),XBC
	ldw	de, 0x840                              ; FA668A  ld DE,0x0840
	ldw	hl, 0x800                              ; FA668D  ld HL,0x0800
	ldw (xiz-2), 0x00C0                        ; FA6690  ld (XIZ+0xfe),0x00c0
VoiceSubsystem_Init__FA6695:
	ld	(xix), de                               ; FA6695  ld (XIX),DE
	ld	xbc, (xiz-6)                            ; FA6697  ld XBC,(XIZ+0xfa)
	extpfx4 0xB1, 0x02, 0x00, 0xFF             ; FA669A  ld (XBC),0xff00
	nop                                        ; FA669E  nop
	nop                                        ; FA669F  nop
	nop                                        ; FA66A0  nop
	nop                                        ; FA66A1  nop
	nop                                        ; FA66A2  nop
	ld	(xix), hl                               ; FA66A3  ld (XIX),HL
	ld	xbc, (xiz-6)                            ; FA66A5  ld XBC,(XIZ+0xfa)
	extpfx4 0xB1, 0x02, 0x80, 0xFF             ; FA66A8  ld (XBC),0xff80
	ld	bc, (xiz-2)                             ; FA66AC  ld BC,(XIZ+0xfe)
	ld	(xix), bc                               ; FA66AF  ld (XIX),BC
	ld	xbc, (xiz-6)                            ; FA66B1  ld XBC,(XIZ+0xfa)
	extpfx4 0xB1, 0x02, 0x00, 0x00             ; FA66B4  ld (XBC),0x0000
	nop                                        ; FA66B8  nop
	nop                                        ; FA66B9  nop
	nop                                        ; FA66BA  nop
	nop                                        ; FA66BB  nop
	nop                                        ; FA66BC  nop
	ld	bc, (xiz-7)                             ; FA66BD  ld BC,(XIZ+0xf9)
	extz	bc                                    ; FA66C0  extz BC
	ld	(xix), bc                               ; FA66C2  ld (XIX),BC
	ld	xbc, (xiz-6)                            ; FA66C4  ld XBC,(XIZ+0xfa)
	extpfx4 0xB1, 0x02, 0x00, 0x7E             ; FA66C7  ld (XBC),0x7e00
	inc	1, de                                  ; FA66CB  inc 1,DE
	inc	1, hl                                  ; FA66CD  inc 1,HL
	incw	1, (xiz-2)                            ; FA66CF  incw 1,(XIZ+0xfe)
	incm8	1, (xiz-7)                           ; FA66D2  inc 1,(XIZ+0xf9)
	cp (xiz-7), 0x40                           ; FA66D5  cp (XIZ+0xf9),0x40
	jr c, VoiceSubsystem_Init__FA6695                   ; FA66D9  jr C,0xfa6695
VoiceSubsystem_Init__FA66DB:
	ld	(xiz-7), 0                              ; FA66DB  ld (XIZ+0xf9),0x00
	ldw	hl, 0                                  ; FA66DF  ld HL,0x0000
VoiceSubsystem_Init__FA66E2:
	cp (xiz+8), 0x00                           ; FA66E2  cp (XIZ+0x08),0x00
	jr nz, VoiceSubsystem_Init__FA6700                  ; FA66E6  jr NZ,0xfa6700
	ld	bc, (xiz-7)                             ; FA66E8  ld BC,(XIZ+0xf9)
	extz	bc                                    ; FA66EB  extz BC
	extz	xbc                                   ; FA66ED  extz XBC
	add	xbc, 0xFE1144                          ; FA66EF  add XBC,0x00fe1144
	ld	a, (xbc)                                ; FA66F5  ld A,(XBC)
	extz	xhl                                   ; FA66F7  extz XHL
	ld	(xhl+0x200), a                          ; FA66F9  ld (XHL+0x0200),A
	jr VoiceSubsystem_Init__FA6716                      ; FA66FE  jr T,0xfa6716
VoiceSubsystem_Init__FA6700:
	ld	bc, (xiz-7)                             ; FA6700  ld BC,(XIZ+0xf9)
	extz	bc                                    ; FA6703  extz BC
	extz	xbc                                   ; FA6705  extz XBC
	add	xbc, 0xFE1156                          ; FA6707  add XBC,0x00fe1156
	ld	a, (xbc)                                ; FA670D  ld A,(XBC)
	extz	xhl                                   ; FA670F  extz XHL
	ld	(xhl+0x200), a                          ; FA6711  ld (XHL+0x0200),A
VoiceSubsystem_Init__FA6716:
	ld	bc, hl                                  ; FA6716  ld BC,HL
	inc	1, bc                                  ; FA6718  inc 1,BC
	extz	xbc                                   ; FA671A  extz XBC
	ld	(xbc+0x200), 0                          ; FA671C  ld (XBC+0x0200),0x00
	ldb	d, 0                                   ; FA6722  ld D,0x00
	ldw	ix, 0                                  ; FA6724  ld IX,0x0000
VoiceSubsystem_Init__FA6727:
	ld	(xiz-9), ix                             ; FA6727  ld (XIZ+0xf7),IX
	ld	bc, (xiz-9)                             ; FA672A  ld BC,(XIZ+0xf7)
	ld	(xiz-11), bc                            ; FA672D  ld (XIZ+0xf5),BC
	ld	(xiz-13), hl                            ; FA6730  ld (XIZ+0xf3),HL
	extpfx3 0x9E, 0xF3, 0x81                   ; FA6733  add BC,(XIZ+0xf3)
	inc	2, bc                                  ; FA6736  inc 2,BC
	ld	(xiz-15), bc                            ; FA6738  ld (XIZ+0xf1),BC
	sub	wa, wa                                 ; FA673B  sub WA,WA
	extz	xbc                                   ; FA673D  extz XBC
	ld	(xbc+0x200), wa                         ; FA673F  ld (XBC+0x0200),WA
	ld	c, d                                    ; FA6744  ld C,D
	extz	bc                                    ; FA6746  extz BC
	extpfx3 0x9E, 0xF3, 0x81                   ; FA6748  add BC,(XIZ+0xf3)
	ld	(xiz-17), bc                            ; FA674B  ld (XIZ+0xef),BC
	add	bc, 16                                 ; FA674E  add BC,0x0010
	extz	xbc                                   ; FA6752  extz XBC
	ld	(xbc+0x200), 0                          ; FA6754  ld (XBC+0x0200),0x00
	ld	bc, (xiz-17)                            ; FA675A  ld BC,(XIZ+0xef)
	add	bc, 23                                 ; FA675D  add BC,0x0017
	extz	xbc                                   ; FA6761  extz XBC
	ld	(xbc+0x200), 0                          ; FA6763  ld (XBC+0x0200),0x00
	ld	ix, (xiz-9)                             ; FA6769  ld IX,(XIZ+0xf7)
	inc	2, ix                                  ; FA676C  inc 2,IX
	inc	1, d                                   ; FA676E  inc 1,D
	cps	d, 7                                   ; FA6770  cp D,7
	jr c, VoiceSubsystem_Init__FA6727                   ; FA6772  jr C,0xfa6727
	add	hl, 30                                 ; FA6774  add HL,0x001e
	incm8	1, (xiz-7)                           ; FA6778  inc 1,(XIZ+0xf9)
	cp (xiz-7), 0x12                           ; FA677B  cp (XIZ+0xf9),0x12
	jrl c, VoiceSubsystem_Init__FA66E2                  ; FA677F  jrl C,0xfa66e2
	ldw (xiz-4), 0x0000                        ; FA6782  ld (XIZ+0xfc),0x0000
	ldw	hl, 0                                  ; FA6787  ld HL,0x0000
	ld	(xiz-7), 34                             ; FA678A  ld (XIZ+0xf9),0x22
VoiceSubsystem_Init__FA678E:
	ld	ix, (xiz-4)                             ; FA678E  ld IX,(XIZ+0xfc)
	extz	xix                                   ; FA6791  extz XIX
	cp (xiz+8), 0x00                           ; FA6793  cp (XIZ+0x08),0x00
	jr nz, VoiceSubsystem_Init__FA67AB                  ; FA6797  jr NZ,0xfa67ab
	lda	xbc, (0xFE1168:24)                     ; FA6799  lda XBC,0xfe1168
	add	xbc, xix                               ; FA679E  add XBC,XIX
	ld	wa, (xbc)                               ; FA67A0  ld WA,(XBC)
	extz	xhl                                   ; FA67A2  extz XHL
	ld	(xhl+0x41C), wa                         ; FA67A4  ld (XHL+0x041c),WA
	jr VoiceSubsystem_Init__FA67BB                      ; FA67A9  jr T,0xfa67bb
VoiceSubsystem_Init__FA67AB:
	lda	xbc, (0xFE11AC:24)                     ; FA67AB  lda XBC,0xfe11ac
	add	xbc, xix                               ; FA67B0  add XBC,XIX
	ld	wa, (xbc)                               ; FA67B2  ld WA,(XBC)
	extz	xhl                                   ; FA67B4  extz XHL
	ld	(xhl+0x41C), wa                         ; FA67B6  ld (XHL+0x041c),WA
VoiceSubsystem_Init__FA67BB:
	ld	(xiz-2), hl                             ; FA67BB  ld (XIZ+0xfe),HL
	ldw	ix, 0                                  ; FA67BE  ld IX,0x0000
	ldb	d, 2                                   ; FA67C1  ld D,0x02
VoiceSubsystem_Init__FA67C3:
	ld	(xiz-9), ix                             ; FA67C3  ld (XIZ+0xf7),IX
	ld	bc, (xiz-2)                             ; FA67C6  ld BC,(XIZ+0xfe)
	extpfx3 0x9E, 0xF7, 0x81                   ; FA67C9  add BC,(XIZ+0xf7)
	inc	2, bc                                  ; FA67CC  inc 2,BC
	ld	(xiz-11), bc                            ; FA67CE  ld (XIZ+0xf5),BC
	sub	wa, wa                                 ; FA67D1  sub WA,WA
	extz	xbc                                   ; FA67D3  extz XBC
	ld	(xbc+0x41C), wa                         ; FA67D5  ld (XBC+0x041c),WA
	ld	ix, (xiz-9)                             ; FA67DA  ld IX,(XIZ+0xf7)
	inc	2, ix                                  ; FA67DD  inc 2,IX
	dec	1, d                                   ; FA67DF  dec 1,D
	cps	d, 0                                   ; FA67E1  cp D,0
	jr nz, VoiceSubsystem_Init__FA67C3                  ; FA67E3  jr NZ,0xfa67c3
	incw	2, (xiz-4)                            ; FA67E5  incw 2,(XIZ+0xfc)
	inc	6, hl                                  ; FA67E8  inc 6,HL
	decm8	1, (xiz-7)                           ; FA67EA  dec 1,(XIZ+0xf9)
	cp (xiz-7), 0x00                           ; FA67ED  cp (XIZ+0xf9),0x00
	jr nz, VoiceSubsystem_Init__FA678E                  ; FA67F1  jr NZ,0xfa678e
	ld	(xiz-7), 0                              ; FA67F3  ld (XIZ+0xf9),0x00
	ldw	hl, 0                                  ; FA67F7  ld HL,0x0000
VoiceSubsystem_Init__FA67FA:
	ld	ix, hl                                  ; FA67FA  ld IX,HL
	ld	(xiz-9), ix                             ; FA67FC  ld (XIZ+0xf7),IX
	ldw	de, 0x4E8                              ; FA67FF  ld DE,0x04e8
	ld	bc, de                                  ; FA6802  ld BC,DE
	extpfx3 0x9E, 0xF7, 0x81                   ; FA6804  add BC,(XIZ+0xf7)
	ld	(xiz-11), bc                            ; FA6807  ld (XIZ+0xf5),BC
	extz	xbc                                   ; FA680A  extz XBC
	ld	a, (xiz-7)                              ; FA680C  ld A,(XIZ+0xf9)
	ld	(xbc+20), a                             ; FA680F  ld (XBC+0x14),A
	ld	bc, (xiz-11)                            ; FA6812  ld BC,(XIZ+0xf5)
	extz	xbc                                   ; FA6815  extz XBC
	ld	(xbc), bc                               ; FA6817  ld (XBC),BC
	ld	bc, (xiz-11)                            ; FA6819  ld BC,(XIZ+0xf5)
	extz	xbc                                   ; FA681C  extz XBC
	ld	(xbc+2), bc                             ; FA681E  ld (XBC+0x02),BC
	ld	bc, (xiz-11)                            ; FA6821  ld BC,(XIZ+0xf5)
	extz	xbc                                   ; FA6824  extz XBC
	ld	(xbc+4), bc                             ; FA6826  ld (XBC+0x04),BC
	ld	bc, (xiz-11)                            ; FA6829  ld BC,(XIZ+0xf5)
	extz	xbc                                   ; FA682C  extz XBC
	ld	(xbc+6), bc                             ; FA682E  ld (XBC+0x06),BC
	ld	bc, (xiz-11)                            ; FA6831  ld BC,(XIZ+0xf5)
	extz	xbc                                   ; FA6834  extz XBC
	ld	(xbc+8), bc                             ; FA6836  ld (XBC+0x08),BC
	ld	bc, (xiz-11)                            ; FA6839  ld BC,(XIZ+0xf5)
	extz	xbc                                   ; FA683C  extz XBC
	ld	(xbc+10), bc                            ; FA683E  ld (XBC+0x0a),BC
	ld	bc, (xiz-11)                            ; FA6841  ld BC,(XIZ+0xf5)
	extz	xbc                                   ; FA6844  extz XBC
	ld	(xbc+18), 0                             ; FA6846  ld (XBC+0x12),0x00
	ldw	bc, 0x41C                              ; FA684A  ld BC,0x041c
	ld	wa, (xiz-11)                            ; FA684D  ld WA,(XIZ+0xf5)
	extz	xwa                                   ; FA6850  extz XWA
	ld	(xwa+12), bc                            ; FA6852  ld (XWA+0x0c),BC
	ld	bc, (xiz-11)                            ; FA6855  ld BC,(XIZ+0xf5)
	extz	xbc                                   ; FA6858  extz XBC
	ld	(xbc+14), 1                             ; FA685A  ld (XBC+0x0e),0x01
	ldw	bc, 0x200                              ; FA685E  ld BC,0x0200
	ld	wa, (xiz-11)                            ; FA6861  ld WA,(XIZ+0xf5)
	extz	xwa                                   ; FA6864  extz XWA
	ld	(xwa+15), bc                            ; FA6866  ld (XWA+0x0f),BC
	ld	bc, (xiz-11)                            ; FA6869  ld BC,(XIZ+0xf5)
	extz	xbc                                   ; FA686C  extz XBC
	ld	(xbc+17), 6                             ; FA686E  ld (XBC+0x11),0x06
	ld	bc, (xiz-11)                            ; FA6872  ld BC,(XIZ+0xf5)
	extz	xbc                                   ; FA6875  extz XBC
	ld	(xbc+21), 0                             ; FA6877  ld (XBC+0x15),0x00
	ld	hl, ix                                  ; FA687B  ld HL,IX
	add	hl, 23                                 ; FA687D  add HL,0x0017
	incm8	1, (xiz-7)                           ; FA6881  inc 1,(XIZ+0xf9)
	cp (xiz-7), 0x40                           ; FA6884  cp (XIZ+0xf9),0x40
	jrl c, VoiceSubsystem_Init__FA67FA                  ; FA6888  jrl C,0xfa67fa
	ld	hl, de                                  ; FA688B  ld HL,DE
	ld	(xiz-7), 64                             ; FA688D  ld (XIZ+0xf9),0x40
VoiceSubsystem_Init__FA6891:
	pushw	hl                                   ; FA6891  push HL
	calr (0xFA6528 - 0xFA6895)                 ; FA6892  calr 0xfa6528
	add	hl, 23                                 ; FA6895  add HL,0x0017
	decm8	1, (xiz-7)                           ; FA6899  dec 1,(XIZ+0xf9)
	popw	bc                                    ; FA689C  pop BC
	cp (xiz-7), 0x00                           ; FA689D  cp (XIZ+0xf9),0x00
	jr nz, VoiceSubsystem_Init__FA6891                  ; FA68A1  jr NZ,0xfa6891
	ldw	hl, 0                                  ; FA68A3  ld HL,0x0000
	ld	(xiz-7), 4                              ; FA68A6  ld (XIZ+0xf9),0x04
VoiceSubsystem_Init__FA68AA:
	ld	de, hl                                  ; FA68AA  ld DE,HL
	ld	ix, de                                  ; FA68AC  ld IX,DE
	extz	xix                                   ; FA68AE  extz XIX
	lda	xbc, (0x87BF:24)                       ; FA68B0  lda XBC,0x0087bf
	add	xbc, xix                               ; FA68B5  add XBC,XIX
	extpfx4 0xB1, 0x02, 0x00, 0x00             ; FA68B7  ld (XBC),0x0000
	lda	xbc, (0x87C7:24)                       ; FA68BB  lda XBC,0x0087c7
	add	xbc, xix                               ; FA68C0  add XBC,XIX
	extpfx4 0xB1, 0x02, 0x00, 0x00             ; FA68C2  ld (XBC),0x0000
	ld	hl, de                                  ; FA68C6  ld HL,DE
	inc	2, hl                                  ; FA68C8  inc 2,HL
	decm8	1, (xiz-7)                           ; FA68CA  dec 1,(XIZ+0xf9)
	cp (xiz-7), 0x00                           ; FA68CD  cp (XIZ+0xf9),0x00
	jr nz, VoiceSubsystem_Init__FA68AA                  ; FA68D1  jr NZ,0xfa68aa
	calr (0xFA5D84 - 0xFA68D6)                 ; FA68D3  calr 0xfa5d84
	pop	xix                                    ; FA68D6  pop XIX
	popw	de                                    ; FA68D7  pop DE
	pop	xhl                                    ; FA68D8  pop XHL
	unlk32 xiz                                 ; FA68D9  unlk XIZ
	ret                                        ; FA68DB  ret
; --------------------------------------------------------------------------
; ★★ Dev10C_PollBankAndRetire -- READ the tone device's channel status for ONE BANK
;             of sixteen channels, retire the channels it has stopped reporting, and
;             cache each surviving channel's 0x0180 read-back.  (round 2, 2026-08-25)
;
; ★ THIS IS THE ROUTINE GAP F ASKS ABOUT.  It contains BOTH of the device's two
; reads, and it is the only place in either image that reads 0x0010C000 at all.
;
; Called from: 1 site(s) outside this module:
;          0xFB05FD in Toggle14FE_AndDispatch__FB05FD -- i.e. on every OTHER pass of
;          that alternator, which MAIN calls once per loop.  One bank per call and
;          four banks, so a channel is looked at once every eight passes of MAIN.
; Inputs:  device 0x0010C000; the two 4-word masks at RAM 0x0087BF and 0x0087C7;
;          the 64 channel records at RAM 0x04E8; no frame argument.
; Outputs: (0x0087CF) = the bank cursor, advanced and masked to 0..3;
;          0x0087BF[bank] = (the word read from the device) | 0x0087C7[bank];
;          rec[+0x15] for each polled channel; and, per retired channel,
;          Dev10C_ChanReset(chan) + 0xFA5CE9(chan) + ChanRec_Release(rec).
; Calls:   0xFA5CE9 = Rec11FE_ReleaseAllRings, 0xFA6269 = VoiceSlots_ReapOrphansInBank
;          0xFA6528 = ChanRec_Release, 0xFA65BD = ChanRec_ToPoolQueue6_SetFlag1
;          0xFB0A8B = Dev10C_ChanReset
;
; Evidence: EVERY INSTRUCTION BELOW IS ASSERTED FROM THE ROM BYTES BY
;          `python3 notes/prom_c_voice_sweep_checks.py` (74 checks, FAILURES: 0).
;          The argument is in notes/FINDINGS-prom_c-voice-readback.md.  In brief:
;
;          ★ READ 1 -- register block 0x0000, index 0..3, IS A 16-CHANNEL BITMAP.
;          `inc 1,(0x0087cf)` / `and H,0x03` (0xFA68E3, 0xFA68ED) keep the cursor in
;          0..3; `ld (XIX),BC` at 0xFA6901 selects with that number and NOTHING added
;          to it; `ld HL,(XBC)` at 0xFA690A reads the +4 port once.  The loop then
;          walks a bit mask that starts at 0x0001 (0xFA695C) and is shifted left in
;          memory until it goes zero (`sllw (XIZ+0xf6)`, 0xFA69E7) -- sixteen passes
;          -- while the channel number D counts up from `bank * 16` (`sll 0x04,C`,
;          0xFA694A) and the record pointer steps by 23 (0xFA69E2).  So bit i of the
;          word read at select n is paired, in one loop body, with channel 16n+i.
;          ★ AND A SECOND, INDEPENDENT WITNESS: the two RAM masks use the same
;          encoding, built by unrelated code -- `Shift16_Left(1, chan & 0x0F)` stored
;          at word index `chan >> 4` (0xFA6CE3, 0xFA6CEA, 0xFA6CF3, 0xFA6CF6).
;          ★ POLARITY.  The differenced word is `ended = old & ~(device | hold)`.
;          In registers: WA = device_word | 0x0087C7[bank] (0xFA6918 `add XWA,0x87C7`
;          / 0xFA691E `ld WA,(XWA)` / 0xFA6920 `or WA,HL`), HL = old = 0x0087BF[bank]
;          (0xFA692D), and `xor WA,HL` / `and WA,HL` (0xFA692F/0xFA6931) is therefore
;          `old & ~WA` = `old & ~device & ~hold`.  A channel in that difference is
;          TORN DOWN -- Dev10C_ChanReset at 0xFA6990.  A bit that goes away therefore
;          means the channel has stopped, so a bit that is SET means the channel is
;          still busy; a HELD channel is never in the difference at all.
;          ⚠ CORRECTED 2026-08-25 (round-2 audit, F7).  This line used to read
;          "`WA = (new ^ old) & old` is `old & ~new`" and never said what `new` was,
;          dropping the hold-mask term that 0xFA6920 ORs in.
;
;          ★ READ 2 -- register block 0x0180 + channel.  `ld (XWA),HL` at 0xFA69AF
;          selects `0x0180 + chan` (0xFA696D built it), `ld BC,(XIX)` at 0xFA69B1
;          reads the +4 port, and the value is masked `& 0x3FFF`, shifted right 5 and
;          then TRUNCATED TO A BYTE by `ld E,C` -- so what survives is BITS 12..5,
;          and bit 13 is discarded by the truncation, not by the mask.  That byte is
;          cached in rec[+0x15] and compared against 0x80 (0xFA69C7); below it, and
;          only if the record's flag bit 2 is set (0xFA69D4), the channel goes to
;          0xFA65BD.
;
; Unknown:  ⚠ WHAT THE 0x0180 QUANTITY PHYSICALLY IS.  What is established is that
;          the firmware treats it as a magnitude that FALLS and that crossing below
;          0x80 -- half of the 8-bit field it keeps -- means this voice is finished.
;          Nothing here ties it to amplitude, to a sample position or to time, and
;          "envelope" is NOT asserted.
;          ⚠ What the device does with a WRITE to block 0.  The two reads above are
;          at the +4 port with index 0..3; block 0 is WRITTEN per channel, with
;          0x8100 (Dev10C_WriteAllChanRegs, 0xFB7239) and 0x7E00 (Dev10C_ChanReset,
;          0xFB0AB5).  Read and write are recorded separately and neither is used to
;          argue about the other.
;          ⚠ What 0xFA5CE9 and 0xFA6269 do, and channel-record flag bits 1 and 2.
; --------------------------------------------------------------------------
Dev10C_PollBankAndRetire:
	link32 0xEE, 0x0C, 0xEA, 0xFF              ; FA68DC  link XIZ,0xffea
	pushw	hl                                   ; FA68E0  push HL
	pushw	de                                   ; FA68E1  push DE
	push	xix                                   ; FA68E2  push XIX
	inc	1, (0x87CF:24)                      ; FA68E3  inc 1,(0x0087cf)
	ld	h, (0x87CF:24)                         ; FA68E8  ld H,(0x0087cf)
	and	h, 3                                   ; FA68ED  and H,0x03
	ld	(0x87CF:24), h                         ; FA68F0  ld (0x0087cf),H
	ld	c, h                                    ; FA68F5  ld C,H
	extz	bc                                    ; FA68F7  extz BC
	ld	(xiz-16), bc                            ; FA68F9  ld (XIZ+0xf0),BC
	ld	xix, 0x10C000                           ; FA68FC  ld XIX,0x0010c000
	ld	(xix), bc                               ; FA6901  ld (XIX),BC
	ld	xbc, xix                                ; FA6903  ld XBC,XIX
	inc	4, xbc                                 ; FA6905  inc 4,XBC
	ld	(xiz-14), xbc                           ; FA6907  ld (XIZ+0xf2),XBC
	ld	hl, (xbc)                               ; FA690A  ld HL,(XBC)
	ldb	a, 2                                   ; FA690C  ld A,0x02
	extpfx5 0xC2, 0xCF, 0x87, 0x00, 0x41       ; FA690E  mul WA,(0x0087cf)
	extz	xwa                                   ; FA6913  extz XWA
	ld	(xiz-20), xwa                           ; FA6915  ld (XIZ+0xec),XWA
	add	xwa, 0x87C7                            ; FA6918  add XWA,0x000087c7
	ld	wa, (xwa)                               ; FA691E  ld WA,(XWA)
	or	wa, hl                                  ; FA6920  or WA,HL
	ld	(xiz-22), wa                            ; FA6922  ld (XIZ+0xea),WA
	lda	xiy, (0x87BF:24)                       ; FA6925  lda XIY,0x0087bf
	extpfx3 0xAE, 0xEC, 0x85                   ; FA692A  add XIY,(XIZ+0xec)
	ld	hl, (xiy)                               ; FA692D  ld HL,(XIY)
	xor	wa, hl                                 ; FA692F  xor WA,HL
	and	wa, hl                                 ; FA6931  and WA,HL
	ld	(xiz-6), wa                             ; FA6933  ld (XIZ+0xfa),WA
	lda	xiy, (0x87BF:24)                       ; FA6936  lda XIY,0x0087bf
	extpfx3 0xAE, 0xEC, 0x85                   ; FA693B  add XIY,(XIZ+0xec)
	ld	bc, (xiz-22)                            ; FA693E  ld BC,(XIZ+0xea)
	ld	(xiy), bc                               ; FA6941  ld (XIY),BC
	ld	d, (0x87CF:24)                         ; FA6943  ld D,(0x0087cf)
	ld	c, d                                    ; FA6948  ld C,D
	sll	c, 4                                   ; FA694A  sll 0x04,C
	ld	d, c                                    ; FA694D  ld D,C
	mul	c, 23                                  ; FA694F  mul C,0x17
	ld	hl, bc                                  ; FA6952  ld HL,BC
	ldw	wa, 0x4E8                              ; FA6954  ld WA,0x04e8
	add	wa, bc                                 ; FA6957  add WA,BC
	ld	(xiz-8), wa                             ; FA6959  ld (XIZ+0xf8),WA
	ldw (xiz-10), 0x0001                       ; FA695C  ld (XIZ+0xf6),0x0001
	ld	(xiz-4), xix                            ; FA6961  ld (XIZ+0xfc),XIX
	ld	xix, (xiz-14)                           ; FA6964  ld XIX,(XIZ+0xf2)
	ld	c, d                                    ; FA6967  ld C,D
	extz	bc                                    ; FA6969  extz BC
	ld	hl, bc                                  ; FA696B  ld HL,BC
	add	bc, 0x180                              ; FA696D  add BC,0x0180
	ld	hl, bc                                  ; FA6971  ld HL,BC
Dev10C_PollBankAndRetire__FA6973:
	ld	bc, (xiz-10)                            ; FA6973  ld BC,(XIZ+0xf6)
	extpfx3 0x9E, 0xFA, 0xC1                   ; FA6976  and BC,(XIZ+0xfa)
	jr z, Dev10C_PollBankAndRetire__FA699F                   ; FA6979  jr Z,0xfa699f
	ld	bc, (xiz-8)                             ; FA697B  ld BC,(XIZ+0xf8)
	extz	xbc                                   ; FA697E  extz XBC
	ld	a, (xbc+18)                             ; FA6980  ld A,(XBC+0x12)
	and	a, 1                                   ; FA6983  and A,0x01
	jr nz, Dev10C_PollBankAndRetire__FA699F                  ; FA6986  jr NZ,0xfa699f
	pushw	bc                                   ; FA6988  push BC
	calr (0xFA6528 - 0xFA698C)                 ; FA6989  calr 0xfa6528
	push	0                                     ; FA698C  push 0x00
	push	d                                     ; FA698E  push D
	call	0xFB0A8B                              ; FA6990  call 0xfb0a8b
	push	0                                     ; FA6994  push 0x00
	push	d                                     ; FA6996  push D
	calr (0xFA5CE9 - 0xFA699B)                 ; FA6998  calr 0xfa5ce9
	inc	6, xsp                                 ; FA699B  inc 6,XSP
	jr Dev10C_PollBankAndRetire__FA69DE                      ; FA699D  jr T,0xfa69de
Dev10C_PollBankAndRetire__FA699F:
	ld	bc, (xiz-8)                             ; FA699F  ld BC,(XIZ+0xf8)
	extz	xbc                                   ; FA69A2  extz XBC
	ld	a, (xbc+18)                             ; FA69A4  ld A,(XBC+0x12)
	and	a, 0x81                                ; FA69A7  and A,0x81
	jr nz, Dev10C_PollBankAndRetire__FA69DE                  ; FA69AA  jr NZ,0xfa69de
	ld	xwa, (xiz-4)                            ; FA69AC  ld XWA,(XIZ+0xfc)
	ld	(xwa), hl                               ; FA69AF  ld (XWA),HL
	ld	bc, (xix)                               ; FA69B1  ld BC,(XIX)
	ld	(xiz-16), bc                            ; FA69B3  ld (XIZ+0xf0),BC
	and	bc, 0x3FFF                             ; FA69B6  and BC,0x3fff
	srl	bc, 5                                  ; FA69BA  srl 0x05,BC
	ld	e, c                                    ; FA69BD  ld E,C
	ld	bc, (xiz-8)                             ; FA69BF  ld BC,(XIZ+0xf8)
	extz	xbc                                   ; FA69C2  extz XBC
	ld	(xbc+21), e                             ; FA69C4  ld (XBC+0x15),E
	cp	e, 0x80                                 ; FA69C7  cp E,0x80
	jr nc, Dev10C_PollBankAndRetire__FA69DE                  ; FA69CA  jr NC,0xfa69de
	ld	bc, (xiz-8)                             ; FA69CC  ld BC,(XIZ+0xf8)
	extz	xbc                                   ; FA69CF  extz XBC
	ld	a, (xbc+18)                             ; FA69D1  ld A,(XBC+0x12)
	and	a, 4                                   ; FA69D4  and A,0x04
	jr z, Dev10C_PollBankAndRetire__FA69DE                   ; FA69D7  jr Z,0xfa69de
	pushw	bc                                   ; FA69D9  push BC
	calr (0xFA65BD - 0xFA69DD)                 ; FA69DA  calr 0xfa65bd
	popw	bc                                    ; FA69DD  pop BC
Dev10C_PollBankAndRetire__FA69DE:
	inc	1, hl                                  ; FA69DE  inc 1,HL
	inc	1, d                                   ; FA69E0  inc 1,D
	extpfx5 0x9E, 0xF8, 0x38, 0x17, 0x00       ; FA69E2  add (XIZ+0xf8),0x0017
	extpfx3 0x9E, 0xF6, 0x7E                   ; FA69E7  sllw (XIZ+0xf6)
	jr nz, Dev10C_PollBankAndRetire__FA6973                  ; FA69EA  jr NZ,0xfa6973
	push	0                                     ; FA69EC  push 0x00
	extpfx5 0xC2, 0xCF, 0x87, 0x00, 0x04       ; FA69EE  push (0x0087cf)
	calr (0xFA6269 - 0xFA69F6)                 ; FA69F3  calr 0xfa6269
	popw	bc                                    ; FA69F6  pop BC
	pop	xix                                    ; FA69F7  pop XIX
	popw	de                                    ; FA69F8  pop DE
	popw	hl                                    ; FA69F9  pop HL
	unlk32 xiz                                 ; FA69FA  unlk XIZ
	ret                                        ; FA69FC  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `ChanAlloc_FindVictim` is now `ChanAlloc_FindVictim`.
;   GRADE PROVEN.  WHY `ChanAlloc_FindVictim`:
;   body: walks a 0xFF-terminated byte list of queue codes in priority order
;   (bit 7 = a queue of the shared pool at 0x03E0, else a queue of the pool the
;   part object's first word names), takes the first non-empty queue whose
;   occupancy byte is non-zero, and returns the first record on it whose channel
;   number rec[+0x14] has the wanted parity, or 0.
; ChanAlloc_FindVictim -- 0xFA69FD..0xFA6BB4 (440 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFA6C8A
; Inputs:  frame `link XIZ,-12`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0E)
; Outputs: no absolute-addressed write.
;          reads 0x00040C, 0x000414, 0x00041B
; Evidence: the listing below is the byte-identical round-trip of 0xFA69FD-0xFA6BB4
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
ChanAlloc_FindVictim:
	link32 0xEE, 0x0C, 0xF4, 0xFF              ; FA69FD  link XIZ,0xfff4
	push	xhl                                   ; FA6A01  push XHL
	pushw	de                                   ; FA6A02  push DE
	push	xix                                   ; FA6A03  push XIX
	ld	c, (xiz+14)                             ; FA6A04  ld C,(XIZ+0x0e)
	and	c, 32                                  ; FA6A07  and C,0x20
	jrl z, sub_FA69FD__FA6B10                  ; FA6A0A  jrl Z,0xfa6b10
	ld	hl, (0x40C:16)                        ; FA6A0D  ld HL,(0x040c)
	sub	bc, bc                                 ; FA6A11  sub BC,BC
	cp	hl, bc                                  ; FA6A13  cp HL,BC
	jr z, sub_FA69FD__FA6A3A                   ; FA6A15  jr Z,0xfa6a3a
	ld	c, (0x414:16)                          ; FA6A17  ld C,(0x0414)
	cps	c, 0                                   ; FA6A1B  cp C,0
	jr z, sub_FA69FD__FA6A3A                   ; FA6A1D  jr Z,0xfa6a3a
	ld	de, (0x40C:16)                        ; FA6A1F  ld DE,(0x040c)
	ld	hl, de                                  ; FA6A23  ld HL,DE
sub_FA69FD__FA6A25:
	extz	xhl                                   ; FA6A25  extz XHL
	ld	c, (xhl+20)                             ; FA6A27  ld C,(XHL+0x14)
	and	c, 1                                   ; FA6A2A  and C,0x01
	jr z, sub_FA69FD__FA6A37                   ; FA6A2D  jr Z,0xfa6a37
	extz	xhl                                   ; FA6A2F  extz XHL
	ld	hl, (xhl)                               ; FA6A31  ld HL,(XHL)
	cp	hl, de                                  ; FA6A33  cp HL,DE
	jr nz, sub_FA69FD__FA6A25                  ; FA6A35  jr NZ,0xfa6a25
sub_FA69FD__FA6A37:
	jrl sub_FA69FD__FA6B3C                     ; FA6A37  jrl T,0xfa6b3c
sub_FA69FD__FA6A3A:
	ldw	hl, 0x200                              ; FA6A3A  ld HL,0x0200
	ld	bc, hl                                  ; FA6A3D  ld BC,HL
	add	bc, 0x1E2                              ; FA6A3F  add BC,0x01e2
	extz	xbc                                   ; FA6A43  extz XBC
	ld	(xiz-12), xbc                           ; FA6A45  ld (XIZ+0xf4),XBC
	ld	wa, hl                                  ; FA6A48  ld WA,HL
	add	wa, 0x1F0                              ; FA6A4A  add WA,0x01f0
	extz	xwa                                   ; FA6A4E  extz XWA
	ld	(xiz-8), xwa                            ; FA6A50  ld (XIZ+0xf8),XWA
	ld	bc, (xiz+8)                             ; FA6A53  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA6A56  extz XBC
	ld	hl, (xbc)                               ; FA6A58  ld HL,(XBC)
	ld	iy, hl                                  ; FA6A5A  ld IY,HL
	inc	2, iy                                  ; FA6A5C  inc 2,IY
	extz	xiy                                   ; FA6A5E  extz XIY
	ld	xix, xiy                                ; FA6A60  ld XIX,XIY
	ld	bc, hl                                  ; FA6A62  ld BC,HL
	add	bc, 16                                 ; FA6A64  add BC,0x0010
	extz	xbc                                   ; FA6A68  extz XBC
	ld	(xiz-4), xbc                            ; FA6A6A  ld (XIZ+0xfc),XBC
sub_FA69FD__FA6A6D:
	ld	xbc, (xiz+10)                           ; FA6A6D  ld XBC,(XIZ+0x0a)
	ld	l, (xbc)                                ; FA6A70  ld L,(XBC)
	cp	l, 0xFF                                 ; FA6A72  cp L,0xff
	jrl z, sub_FA69FD__FA6BAB                  ; FA6A75  jrl Z,0xfa6bab
	ld	a, l                                    ; FA6A78  ld A,L
	and	a, 0x80                                ; FA6A7A  and A,0x80
	jr z, sub_FA69FD__FA6AC7                   ; FA6A7D  jr Z,0xfa6ac7
	ld	h, l                                    ; FA6A7F  ld H,L
	res	7, h                                   ; FA6A81  res 0x07,H
	ldb	a, 2                                   ; FA6A84  ld A,0x02
	mul8rr	a, h                                ; FA6A86  mul WA,H
	extz	xwa                                   ; FA6A88  extz XWA
	extpfx3 0xAE, 0xF4, 0x80                   ; FA6A8A  add XWA,(XIZ+0xf4)
	ld	de, (xwa)                               ; FA6A8D  ld DE,(XWA)
	sub	wa, wa                                 ; FA6A8F  sub WA,WA
	cp	de, wa                                  ; FA6A91  cp DE,WA
	jrl z, sub_FA69FD__FA6B06                  ; FA6A93  jrl Z,0xfa6b06
	ld	a, h                                    ; FA6A96  ld A,H
	extz	wa                                    ; FA6A98  extz WA
	extz	xwa                                   ; FA6A9A  extz XWA
	extpfx3 0xAE, 0xF8, 0x80                   ; FA6A9C  add XWA,(XIZ+0xf8)
	ld	c, (xwa)                                ; FA6A9F  ld C,(XWA)
	cps	c, 0                                   ; FA6AA1  cp C,0
	jr z, sub_FA69FD__FA6B06                   ; FA6AA3  jr Z,0xfa6b06
	ldb	c, 2                                   ; FA6AA5  ld C,0x02
	mul8rr	c, h                                ; FA6AA7  mul BC,H
	extz	xbc                                   ; FA6AA9  extz XBC
	extpfx3 0xAE, 0xF4, 0x81                   ; FA6AAB  add XBC,(XIZ+0xf4)
	ld	de, (xbc)                               ; FA6AAE  ld DE,(XBC)
	ld	hl, de                                  ; FA6AB0  ld HL,DE
sub_FA69FD__FA6AB2:
	extz	xhl                                   ; FA6AB2  extz XHL
	ld	c, (xhl+20)                             ; FA6AB4  ld C,(XHL+0x14)
	and	c, 1                                   ; FA6AB7  and C,0x01
	jr z, sub_FA69FD__FA6AC4                   ; FA6ABA  jr Z,0xfa6ac4
	extz	xhl                                   ; FA6ABC  extz XHL
	ld	hl, (xhl)                               ; FA6ABE  ld HL,(XHL)
	cp	hl, de                                  ; FA6AC0  cp HL,DE
	jr nz, sub_FA69FD__FA6AB2                  ; FA6AC2  jr NZ,0xfa6ab2
sub_FA69FD__FA6AC4:
	jrl sub_FA69FD__FA6B3C                     ; FA6AC4  jrl T,0xfa6b3c
sub_FA69FD__FA6AC7:
	ldb	c, 2                                   ; FA6AC7  ld C,0x02
	mul8rr	c, l                                ; FA6AC9  mul BC,L
	extz	xbc                                   ; FA6ACB  extz XBC
	add	xbc, xix                               ; FA6ACD  add XBC,XIX
	ld	de, (xbc)                               ; FA6ACF  ld DE,(XBC)
	sub	bc, bc                                 ; FA6AD1  sub BC,BC
	cp	de, bc                                  ; FA6AD3  cp DE,BC
	jr z, sub_FA69FD__FA6B06                   ; FA6AD5  jr Z,0xfa6b06
	ld	c, l                                    ; FA6AD7  ld C,L
	extz	bc                                    ; FA6AD9  extz BC
	extz	xbc                                   ; FA6ADB  extz XBC
	extpfx3 0xAE, 0xFC, 0x81                   ; FA6ADD  add XBC,(XIZ+0xfc)
	ld	a, (xbc)                                ; FA6AE0  ld A,(XBC)
	cps	a, 0                                   ; FA6AE2  cp A,0
	jr z, sub_FA69FD__FA6B06                   ; FA6AE4  jr Z,0xfa6b06
	ldb	c, 2                                   ; FA6AE6  ld C,0x02
	mul8rr	c, l                                ; FA6AE8  mul BC,L
	extz	xbc                                   ; FA6AEA  extz XBC
	add	xbc, xix                               ; FA6AEC  add XBC,XIX
	ld	de, (xbc)                               ; FA6AEE  ld DE,(XBC)
	ld	hl, de                                  ; FA6AF0  ld HL,DE
sub_FA69FD__FA6AF2:
	extz	xhl                                   ; FA6AF2  extz XHL
	ld	c, (xhl+20)                             ; FA6AF4  ld C,(XHL+0x14)
	and	c, 1                                   ; FA6AF7  and C,0x01
	jr z, sub_FA69FD__FA6B04                   ; FA6AFA  jr Z,0xfa6b04
	extz	xhl                                   ; FA6AFC  extz XHL
	ld	hl, (xhl)                               ; FA6AFE  ld HL,(XHL)
	cp	hl, de                                  ; FA6B00  cp HL,DE
	jr nz, sub_FA69FD__FA6AF2                  ; FA6B02  jr NZ,0xfa6af2
sub_FA69FD__FA6B04:
	jr sub_FA69FD__FA6B3C                      ; FA6B04  jr T,0xfa6b3c
sub_FA69FD__FA6B06:
	sub	xbc, xbc                               ; FA6B06  sub XBC,XBC
	inc	1, xbc                                 ; FA6B08  inc 1,XBC
	add	(xiz+10), xbc                          ; FA6B0A  add (XIZ+0x0a),XBC
	jrl sub_FA69FD__FA6A6D                     ; FA6B0D  jrl T,0xfa6a6d
sub_FA69FD__FA6B10:
	ld	hl, (0x40C:16)                        ; FA6B10  ld HL,(0x040c)
	sub	bc, bc                                 ; FA6B14  sub BC,BC
	cp	hl, bc                                  ; FA6B16  cp HL,BC
	jr z, sub_FA69FD__FA6B4A                   ; FA6B18  jr Z,0xfa6b4a
	ld	c, (0x41B:16)                          ; FA6B1A  ld C,(0x041b)
	cps	c, 0                                   ; FA6B1E  cp C,0
	jr z, sub_FA69FD__FA6B41                   ; FA6B20  jr Z,0xfa6b41
	ld	de, (0x40C:16)                        ; FA6B22  ld DE,(0x040c)
	ld	hl, de                                  ; FA6B26  ld HL,DE
sub_FA69FD__FA6B28:
	extz	xhl                                   ; FA6B28  extz XHL
	ld	c, (xhl+20)                             ; FA6B2A  ld C,(XHL+0x14)
	and	c, 1                                   ; FA6B2D  and C,0x01
	cps	c, 1                                   ; FA6B30  cp C,1
	jr z, sub_FA69FD__FA6B3C                   ; FA6B32  jr Z,0xfa6b3c
	extz	xhl                                   ; FA6B34  extz XHL
	ld	hl, (xhl)                               ; FA6B36  ld HL,(XHL)
	cp	hl, de                                  ; FA6B38  cp HL,DE
	jr nz, sub_FA69FD__FA6B28                  ; FA6B3A  jr NZ,0xfa6b28
sub_FA69FD__FA6B3C:
	ld	wa, hl                                  ; FA6B3C  ld WA,HL
	jrl sub_FA69FD__FA6BAF                     ; FA6B3E  jrl T,0xfa6baf
sub_FA69FD__FA6B41:
	ld	bc, (0x40C:16)                        ; FA6B41  ld BC,(0x040c)
	ld	wa, bc                                  ; FA6B45  ld WA,BC
	jrl sub_FA69FD__FA6BAF                     ; FA6B47  jrl T,0xfa6baf
sub_FA69FD__FA6B4A:
	ldw	bc, 0x200                              ; FA6B4A  ld BC,0x0200
	add	bc, 0x1E2                              ; FA6B4D  add BC,0x01e2
	extz	xbc                                   ; FA6B51  extz XBC
	ld	(xiz-12), xbc                           ; FA6B53  ld (XIZ+0xf4),XBC
	ld	wa, (xiz+8)                             ; FA6B56  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA6B59  extz XWA
	ld	iy, (xwa)                               ; FA6B5B  ld IY,(XWA)
	inc	2, iy                                  ; FA6B5D  inc 2,IY
	extz	xiy                                   ; FA6B5F  extz XIY
	ld	xix, xiy                                ; FA6B61  ld XIX,XIY
sub_FA69FD__FA6B63:
	ld	xbc, (xiz+10)                           ; FA6B63  ld XBC,(XIZ+0x0a)
	ld	l, (xbc)                                ; FA6B66  ld L,(XBC)
	cp	l, 0xFF                                 ; FA6B68  cp L,0xff
	jr z, sub_FA69FD__FA6BAB                   ; FA6B6B  jr Z,0xfa6bab
	ld	a, l                                    ; FA6B6D  ld A,L
	and	a, 0x80                                ; FA6B6F  and A,0x80
	jr z, sub_FA69FD__FA6B8E                   ; FA6B72  jr Z,0xfa6b8e
	ld	h, l                                    ; FA6B74  ld H,L
	res	7, h                                   ; FA6B76  res 0x07,H
	ldb	a, 2                                   ; FA6B79  ld A,0x02
	mul8rr	a, h                                ; FA6B7B  mul WA,H
	extz	xwa                                   ; FA6B7D  extz XWA
	extpfx3 0xAE, 0xF4, 0x80                   ; FA6B7F  add XWA,(XIZ+0xf4)
	ld	hl, (xwa)                               ; FA6B82  ld HL,(XWA)
	sub	wa, wa                                 ; FA6B84  sub WA,WA
	cp	hl, wa                                  ; FA6B86  cp HL,WA
	jr z, sub_FA69FD__FA6BA2                   ; FA6B88  jr Z,0xfa6ba2
	ld	wa, hl                                  ; FA6B8A  ld WA,HL
	jr sub_FA69FD__FA6BAF                      ; FA6B8C  jr T,0xfa6baf
sub_FA69FD__FA6B8E:
	ldb	c, 2                                   ; FA6B8E  ld C,0x02
	mul8rr	c, l                                ; FA6B90  mul BC,L
	extz	xbc                                   ; FA6B92  extz XBC
	add	xbc, xix                               ; FA6B94  add XBC,XIX
	ld	hl, (xbc)                               ; FA6B96  ld HL,(XBC)
	sub	bc, bc                                 ; FA6B98  sub BC,BC
	cp	hl, bc                                  ; FA6B9A  cp HL,BC
	jr z, sub_FA69FD__FA6BA2                   ; FA6B9C  jr Z,0xfa6ba2
	ld	wa, hl                                  ; FA6B9E  ld WA,HL
	jr sub_FA69FD__FA6BAF                      ; FA6BA0  jr T,0xfa6baf
sub_FA69FD__FA6BA2:
	sub	xbc, xbc                               ; FA6BA2  sub XBC,XBC
	inc	1, xbc                                 ; FA6BA4  inc 1,XBC
	add	(xiz+10), xbc                          ; FA6BA6  add (XIZ+0x0a),XBC
	jr sub_FA69FD__FA6B63                      ; FA6BA9  jr T,0xfa6b63
sub_FA69FD__FA6BAB:
	sub	bc, bc                                 ; FA6BAB  sub BC,BC
	ld	wa, bc                                  ; FA6BAD  ld WA,BC
sub_FA69FD__FA6BAF:
	pop	xix                                    ; FA6BAF  pop XIX
	popw	de                                    ; FA6BB0  pop DE
	pop	xhl                                    ; FA6BB1  pop XHL
	unlk32 xiz                                 ; FA6BB2  unlk XIZ
	ret                                        ; FA6BB4  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `ChanAlloc_ForNoteRequest` is now `ChanAlloc_ForNoteRequest`.
;   GRADE PROVEN.  WHY `ChanAlloc_ForNoteRequest`:
;   body: bounds the request's part index with `cp A,0x21`, then for each of the
;   four element slots req[+2+i] runs ChanAlloc_FindVictim over the search order
;   in the 6-byte ROM record at 0xFE1220 + 6*(req[+2+i] & 0x0F), stamps the note
;   into rec[+0x13], the flag byte 0x08/0x88 into rec[+0x12], relinks the record
;   to a pool queue and to the part's queue 0, and writes the channel number
;   into req[+0x0A+i] (0xFF when nothing was found).  Its five callers are
;   VoiceParams_Compute_A..D and VoiceRecords_InitFromAlloc, whose own header
;   already reads "asks the allocator for voices".
; ChanAlloc_ForNoteRequest -- 0xFA6BB5..0xFA6EA4 (752 bytes)
;
; Called from: 5 site(s) outside this module:
;          0xFB1DA5 in VoiceParams_Compute_A__FB1DA1, 0xFB2784 in VoiceParams_Compute_B__FB2780
;          0xFB2E4D in VoiceParams_Compute_C__FB2E2D, 0xFB35D7 in VoiceParams_Compute_D__FB35B7
;          0xFB3FCC in VoiceRecords_InitFromAlloc
; Inputs:  frame `link XIZ,-29`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x0087D0
;          reads 0x008677, 0x008678
; Calls:   0xFA5CE9 = Rec11FE_ReleaseAllRings, 0xFA62DA = ChanRec_RelinkToPoolQueue
;          0xFA643F = ChanRec_RelinkToPartQueue, 0xFA69FD = ChanAlloc_FindVictim
;          0xFCA0BA = Shift16_Left
; Evidence: the listing below is the byte-identical round-trip of 0xFA6BB5-0xFA6EA4
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
ChanAlloc_ForNoteRequest:
	link32 0xEE, 0x0C, 0xE3, 0xFF              ; FA6BB5  link XIZ,0xffe3
	push	xhl                                   ; FA6BB9  push XHL
	push	xde                                   ; FA6BBA  push XDE
	push	xix                                   ; FA6BBB  push XIX
	ld	xbc, (xiz+8)                            ; FA6BBC  ld XBC,(XIZ+0x08)
	ld	a, (xbc+6)                              ; FA6BBF  ld A,(XBC+0x06)
	and	a, 64                                  ; FA6BC2  and A,0x40
	jr nz, sub_FA6BB5__FA6BCE                  ; FA6BC5  jr NZ,0xfa6bce
	ldw	(0x87D0:24), 0                        ; FA6BC7  ld (0x0087d0),0x0000
sub_FA6BB5__FA6BCE:
	ld	xbc, (xiz+8)                            ; FA6BCE  ld XBC,(XIZ+0x08)
	ld	wa, (xbc)                               ; FA6BD1  ld WA,(XBC)
	and	wa, 0x1F00                             ; FA6BD3  and WA,0x1f00
	srl	wa, 8                                  ; FA6BD7  srl 0x08,WA
	ld	h, a                                    ; FA6BDA  ld H,A
	cp	a, 33                                   ; FA6BDC  cp A,0x21
	jrl nc, sub_FA6BB5__FA6E7C                 ; FA6BDF  jrl NC,0xfa6e7c
	cp (0x008677:24), 0x00                     ; FA6BE2  cp (0x008677),0x00
	jr z, sub_FA6BB5__FA6BFE                   ; FA6BE8  jr Z,0xfa6bfe
	extpfx7 0xD2, 0x78, 0x86, 0x00, 0x3F, 0x30, 0x00 ; FA6BEA  cp (0x008678),0x0030
	jr nc, sub_FA6BB5__FA6C07                  ; FA6BF1  jr NC,0xfa6c07
	extpfx7 0xD2, 0x78, 0x86, 0x00, 0x3F, 0x20, 0x00 ; FA6BF3  cp (0x008678),0x0020
	jr c, sub_FA6BB5__FA6C27                   ; FA6BFA  jr C,0xfa6c27
	jr sub_FA6BB5__FA6C19                      ; FA6BFC  jr T,0xfa6c19
sub_FA6BB5__FA6BFE:
	extpfx7 0xD2, 0x78, 0x86, 0x00, 0x3F, 0x50, 0x00 ; FA6BFE  cp (0x008678),0x0050
	jr c, sub_FA6BB5__FA6C10                   ; FA6C05  jr C,0xfa6c10
sub_FA6BB5__FA6C07:
	ld	xbc, (xiz+8)                            ; FA6C07  ld XBC,(XIZ+0x08)
	extpfx4 0x89, 0x03, 0x3C, 0x7F             ; FA6C0A  and (XBC+0x03),0x7f
	jr sub_FA6BB5__FA6C19                      ; FA6C0E  jr T,0xfa6c19
sub_FA6BB5__FA6C10:
	extpfx7 0xD2, 0x78, 0x86, 0x00, 0x3F, 0x40, 0x00 ; FA6C10  cp (0x008678),0x0040
	jr c, sub_FA6BB5__FA6C27                   ; FA6C17  jr C,0xfa6c27
sub_FA6BB5__FA6C19:
	ld	xbc, (xiz+8)                            ; FA6C19  ld XBC,(XIZ+0x08)
	extpfx4 0x89, 0x04, 0x3C, 0x7F             ; FA6C1C  and (XBC+0x04),0x7f
	ld	xbc, (xiz+8)                            ; FA6C20  ld XBC,(XIZ+0x08)
	extpfx4 0x89, 0x05, 0x3C, 0x7F             ; FA6C23  and (XBC+0x05),0x7f
sub_FA6BB5__FA6C27:
	ldb	c, 6                                   ; FA6C27  ld C,0x06
	mul8rr	c, h                                ; FA6C29  mul BC,H
	ld	de, bc                                  ; FA6C2B  ld DE,BC
	ldw	wa, 0x41C                              ; FA6C2D  ld WA,0x041c
	add	wa, bc                                 ; FA6C30  add WA,BC
	ld	(xiz-22), wa                            ; FA6C32  ld (XIZ+0xea),WA
	ldw	bc, 0x200                              ; FA6C35  ld BC,0x0200
	add	bc, 0x1E0                              ; FA6C38  add BC,0x01e0
	ld	(xiz-8), bc                             ; FA6C3C  ld (XIZ+0xf8),BC
	sub	xiy, xiy                               ; FA6C3F  sub XIY,XIY
	inc	2, xiy                                 ; FA6C41  inc 2,XIY
	ld	(xiz-20), xiy                           ; FA6C43  ld (XIZ+0xec),XIY
	sub	xbc, xbc                               ; FA6C46  sub XBC,XBC
	inc	6, xbc                                 ; FA6C48  inc 6,XBC
	ld	(xiz-12), xbc                           ; FA6C4A  ld (XIZ+0xf4),XBC
	ld	xbc, 10                                 ; FA6C4D  ld XBC,0x0000000a
	ld	(xiz-16), xbc                           ; FA6C52  ld (XIZ+0xf0),XBC
	ld	(xiz-23), 4                             ; FA6C55  ld (XIZ+0xe9),0x04
sub_FA6BB5__FA6C59:
	ld	xbc, (xiz+8)                            ; FA6C59  ld XBC,(XIZ+0x08)
	extpfx3 0xAE, 0xEC, 0x81                   ; FA6C5C  add XBC,(XIZ+0xec)
	ld	h, (xbc)                                ; FA6C5F  ld H,(XBC)
	ld	a, h                                    ; FA6C61  ld A,H
	and	a, 0x80                                ; FA6C63  and A,0x80
	jrl z, sub_FA6BB5__FA6E5E                  ; FA6C66  jrl Z,0xfa6e5e
	ld	a, h                                    ; FA6C69  ld A,H
	and	a, 15                                  ; FA6C6B  and A,0x0f
	mul	a, 6                                   ; FA6C6E  mul A,0x06
	extz	xwa                                   ; FA6C71  extz XWA
	ld	xix, xwa                                ; FA6C73  ld XIX,XWA
	add	xix, 0xFE1220                          ; FA6C75  add XIX,0x00fe1220
	ld	xbc, (xiz+8)                            ; FA6C7B  ld XBC,(XIZ+0x08)
	extpfx3 0xAE, 0xF4, 0x81                   ; FA6C7E  add XBC,(XIZ+0xf4)
	ld	a, (xbc)                                ; FA6C81  ld A,(XBC)
	pushw	wa                                   ; FA6C83  push WA
	ld	xbc, (xix)                              ; FA6C84  ld XBC,(XIX)
	push	xbc                                   ; FA6C86  push XBC
	extpfx3 0x9E, 0xEA, 0x04                   ; FA6C87  pushw (XIZ+0xea)
	calr (0xFA69FD - 0xFA6C8D)                 ; FA6C8A  calr 0xfa69fd
	ld	de, wa                                  ; FA6C8D  ld DE,WA
	sub	bc, bc                                 ; FA6C8F  sub BC,BC
	inc	8, xsp                                 ; FA6C91  inc 0,XSP
	cp	wa, bc                                  ; FA6C93  cp WA,BC
	jrl z, sub_FA6BB5__FA6E5E                  ; FA6C95  jrl Z,0xfa6e5e
	extz	xwa                                   ; FA6C98  extz XWA
	ld	c, (xwa+20)                             ; FA6C9A  ld C,(XWA+0x14)
	ld	(xiz-5), c                              ; FA6C9D  ld (XIZ+0xfb),C
	ld	hl, (xwa+15)                            ; FA6CA0  ld HL,(XWA+0x0f)
	extz	xhl                                   ; FA6CA3  extz XHL
	ld	b, (xhl+1)                              ; FA6CA5  ld B,(XHL+0x01)
	ld	(xiz-1), b                              ; FA6CA8  ld (XIZ+0xff),B
	cps	b, 0                                   ; FA6CAB  cp B,0
	jr z, sub_FA6BB5__FA6CB6                   ; FA6CAD  jr Z,0xfa6cb6
	dec	1, b                                   ; FA6CAF  dec 1,B
	extz	xhl                                   ; FA6CB1  extz XHL
	ld	(xhl+1), b                              ; FA6CB3  ld (XHL+0x01),B
sub_FA6BB5__FA6CB6:
	ld	xbc, (xiz+8)                            ; FA6CB6  ld XBC,(XIZ+0x08)
	ld	a, (xbc)                                ; FA6CB9  ld A,(XBC)
	res	7, a                                   ; FA6CBB  res 0x07,A
	extz	xde                                   ; FA6CBE  extz XDE
	ld	(xde+19), a                             ; FA6CC0  ld (XDE+0x13),A
	ld	(xde+21), 0xFF                          ; FA6CC3  ld (XDE+0x15),0xff
	ld	c, (xix+5)                              ; FA6CC7  ld C,(XIX+0x05)
	ld	(xde+22), c                             ; FA6CCA  ld (XDE+0x16),C
	ld	xbc, (xiz+8)                            ; FA6CCD  ld XBC,(XIZ+0x08)
	extpfx3 0xAE, 0xF4, 0x81                   ; FA6CD0  add XBC,(XIZ+0xf4)
	ld	a, (xbc)                                ; FA6CD3  ld A,(XBC)
	and	a, 0x80                                ; FA6CD5  and A,0x80
	jr z, sub_FA6BB5__FA6D05                   ; FA6CD8  jr Z,0xfa6d05
	extz	xde                                   ; FA6CDA  extz XDE
	ld	(xde+18), 0x88                          ; FA6CDC  ld (XDE+0x12),0x88
	ld	c, (xiz-5)                              ; FA6CE0  ld C,(XIZ+0xfb)
	and	c, 15                                  ; FA6CE3  and C,0x0f
	pushw	bc                                   ; FA6CE6  push BC
	pushw	1                                    ; FA6CE7  push 0x0001
	call	0xFCA0BA                              ; FA6CEA  call 0xfca0ba
	ld	hl, wa                                  ; FA6CEE  ld HL,WA
	ld	c, (xiz-5)                              ; FA6CF0  ld C,(XIZ+0xfb)
	srl	c, 4                                   ; FA6CF3  srl 0x04,C
	mul	c, 2                                   ; FA6CF6  mul C,0x02
	extz	xbc                                   ; FA6CF9  extz XBC
	add	xbc, 0x87C7                            ; FA6CFB  add XBC,0x000087c7
	or	(xbc), hl                               ; FA6D01  or (XBC),HL
	jr sub_FA6BB5__FA6D43                      ; FA6D03  jr T,0xfa6d43
sub_FA6BB5__FA6D05:
	extz	xde                                   ; FA6D05  extz XDE
	ld	(xde+18), 8                             ; FA6D07  ld (XDE+0x12),0x08
	ld	c, (xiz-5)                              ; FA6D0B  ld C,(XIZ+0xfb)
	and	c, 15                                  ; FA6D0E  and C,0x0f
	pushw	bc                                   ; FA6D11  push BC
	pushw	1                                    ; FA6D12  push 0x0001
	call	0xFCA0BA                              ; FA6D15  call 0xfca0ba
	ld	hl, wa                                  ; FA6D19  ld HL,WA
	cpl	wa                                     ; FA6D1B  cpl WA
	ld	(xiz-25), wa                            ; FA6D1D  ld (XIZ+0xe7),WA
	ld	c, (xiz-5)                              ; FA6D20  ld C,(XIZ+0xfb)
	srl	c, 4                                   ; FA6D23  srl 0x04,C
	mul	c, 2                                   ; FA6D26  mul C,0x02
	extz	xbc                                   ; FA6D29  extz XBC
	ld	(xiz-29), xbc                           ; FA6D2B  ld (XIZ+0xe3),XBC
	add	xbc, 0x87C7                            ; FA6D2E  add XBC,0x000087c7
	ld	wa, (xiz-25)                            ; FA6D34  ld WA,(XIZ+0xe7)
	and	(xbc), wa                              ; FA6D37  and (XBC),WA
	lda	xbc, (0x87BF:24)                       ; FA6D39  lda XBC,0x0087bf
	extpfx3 0xAE, 0xE3, 0x81                   ; FA6D3E  add XBC,(XIZ+0xe3)
	or	(xbc), hl                               ; FA6D41  or (XBC),HL
sub_FA6BB5__FA6D43:
	ld	c, (xix+4)                              ; FA6D43  ld C,(XIX+0x04)
	pushw	bc                                   ; FA6D46  push BC
	ld	bc, (xiz-22)                            ; FA6D47  ld BC,(XIZ+0xea)
	extz	xbc                                   ; FA6D4A  extz XBC
	ld	wa, (xbc)                               ; FA6D4C  ld WA,(XBC)
	pushw	wa                                   ; FA6D4E  push WA
	pushw	de                                   ; FA6D4F  push DE
	calr (0xFA62DA - 0xFA6D53)                 ; FA6D50  calr 0xfa62da
	pushw	0                                    ; FA6D53  push 0x0000
	extpfx3 0x9E, 0xEA, 0x04                   ; FA6D56  pushw (XIZ+0xea)
	pushw	de                                   ; FA6D59  push DE
	calr (0xFA643F - 0xFA6D5D)                 ; FA6D5A  calr 0xfa643f
	sub	bc, bc                                 ; FA6D5D  sub BC,BC
	inc	8, xsp                                 ; FA6D5F  inc 0,XSP
	inc	4, xsp                                 ; FA6D61  inc 4,XSP
	cp	(0x87D0:24), bc                     ; FA6D63  cp (0x0087d0),BC
	jr z, sub_FA6BB5__FA6DBB                   ; FA6D68  jr Z,0xfa6dbb
	ld	hl, (0x87D0:24)                        ; FA6D6A  ld HL,(0x0087d0)
	extz	xde                                   ; FA6D6F  extz XDE
	ld	ix, (xde+8)                             ; FA6D71  ld IX,(XDE+0x08)
	ldw (xiz-25), 0x000A                       ; FA6D74  ld (XIZ+0xe7),0x000a
	ld	bc, (xiz-25)                            ; FA6D79  ld BC,(XIZ+0xe7)
	extpfx5 0xD3, 0x07, 0xE8, 0xE4, 0x20       ; FA6D7C  ld WA,(XDE+BC)
	ld	(xiz-27), wa                            ; FA6D81  ld (XIZ+0xe5),WA
	extz	xwa                                   ; FA6D84  extz XWA
	ld	(xwa+8), ix                             ; FA6D86  ld (XWA+0x08),IX
	ld	bc, ix                                  ; FA6D89  ld BC,IX
	extz	xbc                                   ; FA6D8B  extz XBC
	extpfx3 0x9E, 0xE7, 0x81                   ; FA6D8D  add BC,(XIZ+0xe7)
	ld	wa, (xiz-27)                            ; FA6D90  ld WA,(XIZ+0xe5)
	ld	(xbc), wa                               ; FA6D93  ld (XBC),WA
	ld	bc, (xiz-25)                            ; FA6D95  ld BC,(XIZ+0xe7)
	extz	xhl                                   ; FA6D98  extz XHL
	extpfx5 0xD3, 0x07, 0xEC, 0xE4, 0x24       ; FA6D9A  ld IX,(XHL+BC)
	extz	xix                                   ; FA6D9F  extz XIX
	ld	(xix+8), de                             ; FA6DA1  ld (XIX+0x08),DE
	ld	bc, hl                                  ; FA6DA4  ld BC,HL
	extz	xbc                                   ; FA6DA6  extz XBC
	extpfx3 0x9E, 0xE7, 0x81                   ; FA6DA8  add BC,(XIZ+0xe7)
	ld	(xbc), de                               ; FA6DAB  ld (XBC),DE
	ld	(xde+8), hl                             ; FA6DAD  ld (XDE+0x08),HL
	ld	bc, de                                  ; FA6DB0  ld BC,DE
	extz	xbc                                   ; FA6DB2  extz XBC
	extpfx3 0x9E, 0xE7, 0x81                   ; FA6DB4  add BC,(XIZ+0xe7)
	ld	(xbc), ix                               ; FA6DB7  ld (XBC),IX
	jr sub_FA6BB5__FA6DD6                      ; FA6DB9  jr T,0xfa6dd6
sub_FA6BB5__FA6DBB:
	ld	(0x87D0:24), de                        ; FA6DBB  ld (0x0087d0),DE
	ld	hl, (xde+8)                             ; FA6DC0  ld HL,(XDE+0x08)
	ld	ix, (xde+10)                            ; FA6DC3  ld IX,(XDE+0x0a)
	extz	xix                                   ; FA6DC6  extz XIX
	ld	(xix+8), hl                             ; FA6DC8  ld (XIX+0x08),HL
	extz	xhl                                   ; FA6DCB  extz XHL
	ld	(xhl+10), ix                            ; FA6DCD  ld (XHL+0x0a),IX
	ld	(xde+8), de                             ; FA6DD0  ld (XDE+0x08),DE
	ld	(xde+10), de                            ; FA6DD3  ld (XDE+0x0a),DE
sub_FA6BB5__FA6DD6:
	extz	xde                                   ; FA6DD6  extz XDE
	ld	hl, (xde+15)                            ; FA6DD8  ld HL,(XDE+0x0f)
	extz	xhl                                   ; FA6DDB  extz XHL
	ld	c, (xhl)                                ; FA6DDD  ld C,(XHL)
	ld	(xiz-25), c                             ; FA6DDF  ld (XIZ+0xe7),C
	ld	d, (xhl+1)                              ; FA6DE2  ld D,(XHL+0x01)
	cp	d, c                                    ; FA6DE5  cp D,C
	jr nc, sub_FA6BB5__FA6DF4                  ; FA6DE7  jr NC,0xfa6df4
	ld	c, d                                    ; FA6DE9  ld C,D
	inc	1, c                                   ; FA6DEB  inc 1,C
	extz	xhl                                   ; FA6DED  extz XHL
	ld	(xhl+1), c                              ; FA6DEF  ld (XHL+0x01),C
	jr sub_FA6BB5__FA6E48                      ; FA6DF2  jr T,0xfa6e48
sub_FA6BB5__FA6DF4:
	ld	bc, hl                                  ; FA6DF4  ld BC,HL
	inc	2, bc                                  ; FA6DF6  inc 2,BC
	extz	xbc                                   ; FA6DF8  extz XBC
	ld	(xiz-4), xbc                            ; FA6DFA  ld (XIZ+0xfc),XBC
	lda	xix, (0xFE11F0:24)                     ; FA6DFD  lda XIX,0xfe11f0
sub_FA6BB5__FA6E02:
	ld	h, (xix)                                ; FA6E02  ld H,(XIX)
	cp	h, 0xFF                                 ; FA6E04  cp H,0xff
	jr z, sub_FA6BB5__FA6E22                   ; FA6E07  jr Z,0xfa6e22
	ldb	c, 2                                   ; FA6E09  ld C,0x02
	mul8rr	c, h                                ; FA6E0B  mul BC,H
	extz	xbc                                   ; FA6E0D  extz XBC
	extpfx3 0xAE, 0xFC, 0x81                   ; FA6E0F  add XBC,(XIZ+0xfc)
	ld	de, (xbc)                               ; FA6E12  ld DE,(XBC)
	sub	bc, bc                                 ; FA6E14  sub BC,BC
	cp	de, bc                                  ; FA6E16  cp DE,BC
	jr z, sub_FA6BB5__FA6E1E                   ; FA6E18  jr Z,0xfa6e1e
	ld	hl, de                                  ; FA6E1A  ld HL,DE
	jr sub_FA6BB5__FA6E25                      ; FA6E1C  jr T,0xfa6e25
sub_FA6BB5__FA6E1E:
	inc	1, xix                                 ; FA6E1E  inc 1,XIX
	jr sub_FA6BB5__FA6E02                      ; FA6E20  jr T,0xfa6e02
sub_FA6BB5__FA6E22:
	ldw	hl, 0                                  ; FA6E22  ld HL,0x0000
sub_FA6BB5__FA6E25:
	ld	de, hl                                  ; FA6E25  ld DE,HL
	sub	bc, bc                                 ; FA6E27  sub BC,BC
	cp	hl, bc                                  ; FA6E29  cp HL,BC
	jr z, sub_FA6BB5__FA6E48                   ; FA6E2B  jr Z,0xfa6e48
	extz	xde                                   ; FA6E2D  extz XDE
	ld	c, (xde+17)                             ; FA6E2F  ld C,(XDE+0x11)
	pushw	bc                                   ; FA6E32  push BC
	extpfx3 0x9E, 0xF8, 0x04                   ; FA6E33  pushw (XIZ+0xf8)
	pushw	de                                   ; FA6E36  push DE
	calr (0xFA62DA - 0xFA6E3A)                 ; FA6E37  calr 0xfa62da
	ld	bc, (xde+15)                            ; FA6E3A  ld BC,(XDE+0x0f)
	extz	xbc                                   ; FA6E3D  extz XBC
	incm8	1, (xbc+1)                           ; FA6E3F  inc 1,(XBC+0x01)
	extpfx4 0x8A, 0x12, 0x3E, 0x10             ; FA6E42  or (XDE+0x12),0x10
	inc	6, xsp                                 ; FA6E46  inc 6,XSP
sub_FA6BB5__FA6E48:
	push	0                                     ; FA6E48  push 0x00
	extpfx3 0x8E, 0xFB, 0x04                   ; FA6E4A  push (XIZ+0xfb)
	calr (0xFA5CE9 - 0xFA6E50)                 ; FA6E4D  calr 0xfa5ce9
	ld	xbc, (xiz+8)                            ; FA6E50  ld XBC,(XIZ+0x08)
	extpfx3 0xAE, 0xF0, 0x81                   ; FA6E53  add XBC,(XIZ+0xf0)
	ld	a, (xiz-5)                              ; FA6E56  ld A,(XIZ+0xfb)
	ld	(xbc), a                                ; FA6E59  ld (XBC),A
	popw	bc                                    ; FA6E5B  pop BC
	jr sub_FA6BB5__FA6E67                      ; FA6E5C  jr T,0xfa6e67
sub_FA6BB5__FA6E5E:
	ld	xbc, (xiz+8)                            ; FA6E5E  ld XBC,(XIZ+0x08)
	extpfx3 0xAE, 0xF0, 0x81                   ; FA6E61  add XBC,(XIZ+0xf0)
	ld	(xbc), 0xFF                             ; FA6E64  ld (XBC),0xff
sub_FA6BB5__FA6E67:
	sub	xbc, xbc                               ; FA6E67  sub XBC,XBC
	inc	1, xbc                                 ; FA6E69  inc 1,XBC
	add	(xiz-20), xbc                          ; FA6E6B  add (XIZ+0xec),XBC
	add	(xiz-12), xbc                          ; FA6E6E  add (XIZ+0xf4),XBC
	add	(xiz-16), xbc                          ; FA6E71  add (XIZ+0xf0),XBC
	sub	(xiz-23), c                            ; FA6E74  sub (XIZ+0xe9),C
	jrl nz, sub_FA6BB5__FA6C59                 ; FA6E77  jrl NZ,0xfa6c59
	jr sub_FA6BB5__FA6E9F                      ; FA6E7A  jr T,0xfa6e9f
sub_FA6BB5__FA6E7C:
	ld	xix, 10                                 ; FA6E7C  ld XIX,0x0000000a
	ld	(xiz-23), 4                             ; FA6E81  ld (XIZ+0xe9),0x04
sub_FA6BB5__FA6E85:
	ld	(xiz-27), xix                           ; FA6E85  ld (XIZ+0xe5),XIX
	ld	xbc, (xiz+8)                            ; FA6E88  ld XBC,(XIZ+0x08)
	extpfx3 0xAE, 0xE5, 0x81                   ; FA6E8B  add XBC,(XIZ+0xe5)
	ld	(xbc), 0xFF                             ; FA6E8E  ld (XBC),0xff
	ld	xix, (xiz-27)                           ; FA6E91  ld XIX,(XIZ+0xe5)
	inc	1, xix                                 ; FA6E94  inc 1,XIX
	decm8	1, (xiz-23)                          ; FA6E96  dec 1,(XIZ+0xe9)
	cp (xiz-23), 0x00                          ; FA6E99  cp (XIZ+0xe9),0x00
	jr nz, sub_FA6BB5__FA6E85                  ; FA6E9D  jr NZ,0xfa6e85
sub_FA6BB5__FA6E9F:
	pop	xix                                    ; FA6E9F  pop XIX
	pop	xde                                    ; FA6EA0  pop XDE
	pop	xhl                                    ; FA6EA1  pop XHL
	unlk32 xiz                                 ; FA6EA2  unlk XIZ
	ret                                        ; FA6EA4  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `ChanRec_ClearHoldAndRelease` is now `ChanRec_ClearHoldAndRelease`.
;   GRADE PROVEN.  WHY `ChanRec_ClearHoldAndRelease`:
;   body: clears flag bit 7 of rec[+0x12], clears the channel's bit in the
;   0x0087C7 hold mask, then calls ChanRec_BeginRelease on the same record.
; ChanRec_ClearHoldAndRelease -- 0xFA6EA5..0xFA6EF9 (85 bytes)
;
; Called from: 7 site(s) outside this module:
;          0xFAC05B in sub_FAC026, 0xFAC1DD in sub_FAC08D__FAC1D3
;          0xFACA94 in sub_FACA40__FACA84, 0xFACB2C in sub_FACAB7__FACB1C
;          0xFACB4E in sub_FACAB7__FACB3E, 0xFADF46 in sub_FADEAC__FADF12
;          0xFB3D8F in Voice_Retire_Mode20__FB3D5A
; Inputs:  frame `link XIZ,-2`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA65F6 = ChanRec_BeginRelease, 0xFCA0BA = Shift16_Left
; Evidence: the listing below is the byte-identical round-trip of 0xFA6EA5-0xFA6EF9
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
ChanRec_ClearHoldAndRelease:
	link32 0xEE, 0x0C, 0xFE, 0xFF              ; FA6EA5  link XIZ,0xfffe
	pushw	hl                                   ; FA6EA9  push HL
	pushw	de                                   ; FA6EAA  push DE
	push	xix                                   ; FA6EAB  push XIX
	lda	xix, (0x4E8:16)                       ; FA6EAC  lda XIX,0x04e8
	ld	h, (xiz+8)                              ; FA6EB0  ld H,(XIZ+0x08)
	ldb	c, 23                                  ; FA6EB3  ld C,0x17
	mul8rr	c, h                                ; FA6EB5  mul BC,H
	ld	de, bc                                  ; FA6EB7  ld DE,BC
	add	bc, 18                                 ; FA6EB9  add BC,0x0012
	extz	xbc                                   ; FA6EBD  extz XBC
	add	bc, ix                                 ; FA6EBF  add BC,IX
	extpfx3 0x81, 0x3C, 0x7F                   ; FA6EC1  and (XBC),0x7f
	ld	c, h                                    ; FA6EC4  ld C,H
	and	c, 15                                  ; FA6EC6  and C,0x0f
	pushw	bc                                   ; FA6EC9  push BC
	pushw	1                                    ; FA6ECA  push 0x0001
	call	0xFCA0BA                              ; FA6ECD  call 0xfca0ba
	cpl	wa                                     ; FA6ED1  cpl WA
	ld	(xiz-2), wa                             ; FA6ED3  ld (XIZ+0xfe),WA
	ld	c, h                                    ; FA6ED6  ld C,H
	srl	c, 4                                   ; FA6ED8  srl 0x04,C
	mul	c, 2                                   ; FA6EDB  mul C,0x02
	extz	xbc                                   ; FA6EDE  extz XBC
	add	xbc, 0x87C7                            ; FA6EE0  add XBC,0x000087c7
	ld	wa, (xiz-2)                             ; FA6EE6  ld WA,(XIZ+0xfe)
	and	(xbc), wa                              ; FA6EE9  and (XBC),WA
	ld	bc, ix                                  ; FA6EEB  ld BC,IX
	add	bc, de                                 ; FA6EED  add BC,DE
	pushw	bc                                   ; FA6EEF  push BC
	calr (0xFA65F6 - 0xFA6EF3)                 ; FA6EF0  calr 0xfa65f6
	popw	bc                                    ; FA6EF3  pop BC
	pop	xix                                    ; FA6EF4  pop XIX
	popw	de                                    ; FA6EF5  pop DE
	popw	hl                                    ; FA6EF6  pop HL
	unlk32 xiz                                 ; FA6EF7  unlk XIZ
	ret                                        ; FA6EF9  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `ChanRec_ReleaseByChannel` is now `ChanRec_ReleaseByChannel`.
;   GRADE PROVEN.  WHY `ChanRec_ReleaseByChannel`:
;   body: rejects chan >= 0x40, relinks the record to queue 1 of its own part
;   object, calls ChanRec_BeginRelease, and unlinks it from the
;   rec[+0x08]/rec[+0x0A] pair.  Its one caller is MidiNote_OffTail.
; ChanRec_ReleaseByChannel -- 0xFA6EFA..0xFA6F47 (78 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFB3855 in MidiNote_OffTail__FB384D
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA643F = ChanRec_RelinkToPartQueue, 0xFA65F6 = ChanRec_BeginRelease
; Evidence: the listing below is the byte-identical round-trip of 0xFA6EFA-0xFA6F47
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
ChanRec_ReleaseByChannel:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA6EFA  link XIZ,0x0000
	push	xhl                                   ; FA6EFE  push XHL
	push	xde                                   ; FA6EFF  push XDE
	push	xix                                   ; FA6F00  push XIX
	cp (xiz+8), 0x40                           ; FA6F01  cp (XIZ+0x08),0x40
	jr nc, sub_FA6EFA__FA6F42                  ; FA6F05  jr NC,0xfa6f42
	ldb	c, 23                                  ; FA6F07  ld C,0x17
	extpfx3 0x8E, 0x08, 0x43                   ; FA6F09  mul BC,(XIZ+0x08)
	ld	ix, bc                                  ; FA6F0C  ld IX,BC
	ldw	hl, 0x4E8                              ; FA6F0E  ld HL,0x04e8
	add	hl, bc                                 ; FA6F11  add HL,BC
	pushw	1                                    ; FA6F13  push 0x0001
	extz	xhl                                   ; FA6F16  extz XHL
	ld	bc, (xhl+12)                            ; FA6F18  ld BC,(XHL+0x0c)
	pushw	bc                                   ; FA6F1B  push BC
	pushw	hl                                   ; FA6F1C  push HL
	calr (0xFA643F - 0xFA6F20)                 ; FA6F1D  calr 0xfa643f
	pushw	hl                                   ; FA6F20  push HL
	calr (0xFA65F6 - 0xFA6F24)                 ; FA6F21  calr 0xfa65f6
	ld	de, (xhl+8)                             ; FA6F24  ld DE,(XHL+0x08)
	inc	8, xsp                                 ; FA6F27  inc 0,XSP
	cp	hl, de                                  ; FA6F29  cp HL,DE
	jr z, sub_FA6EFA__FA6F42                   ; FA6F2B  jr Z,0xfa6f42
	extz	xhl                                   ; FA6F2D  extz XHL
	ld	ix, (xhl+10)                            ; FA6F2F  ld IX,(XHL+0x0a)
	extz	xix                                   ; FA6F32  extz XIX
	ld	(xix+8), de                             ; FA6F34  ld (XIX+0x08),DE
	extz	xde                                   ; FA6F37  extz XDE
	ld	(xde+10), ix                            ; FA6F39  ld (XDE+0x0a),IX
	ld	(xhl+8), hl                             ; FA6F3C  ld (XHL+0x08),HL
	ld	(xhl+10), hl                            ; FA6F3F  ld (XHL+0x0a),HL
sub_FA6EFA__FA6F42:
	pop	xix                                    ; FA6F42  pop XIX
	pop	xde                                    ; FA6F43  pop XDE
	pop	xhl                                    ; FA6F44  pop XHL
	unlk32 xiz                                 ; FA6F45  unlk XIZ
	ret                                        ; FA6F47  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `ChanRec_ReleaseQueueAndCollect` is now `ChanRec_ReleaseQueueAndCollect`.
;   GRADE PROVEN.  WHY `ChanRec_ReleaseQueueAndCollect`:
;   body: walks one part queue; unless the caller passes the `any note` flag it
;   keeps only records whose rec[+0x13] equals the wanted note; each kept record
;   is relinked to part queue 1, passed to ChanRec_BeginRelease, has its channel
;   number rec[+0x14] appended to the caller's output list, and is unlinked from
;   the rec[+0x08]/rec[+0x0A] pair.  The list is 0xFF-terminated.
; ChanRec_ReleaseQueueAndCollect -- 0xFA6F48..0xFA6FDF (152 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFA70A4 0xFA70CC
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0C), (XIZ+0x0E), (XIZ+0x10)
; Outputs: no absolute-addressed write.
; Calls:   0xFA643F = ChanRec_RelinkToPartQueue, 0xFA65F6 = ChanRec_BeginRelease
; Evidence: the listing below is the byte-identical round-trip of 0xFA6F48-0xFA6FDF
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
ChanRec_ReleaseQueueAndCollect:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FA6F48  link XIZ,0xfffc
	pushw	hl                                   ; FA6F4C  push HL
	push	xde                                   ; FA6F4D  push XDE
	push	xix                                   ; FA6F4E  push XIX
	ld	ix, (xiz+12)                            ; FA6F4F  ld IX,(XIZ+0x0c)
	sub	bc, bc                                 ; FA6F52  sub BC,BC
	cp	ix, bc                                  ; FA6F54  cp IX,BC
	jrl z, sub_FA6F48__FA6FD2                  ; FA6F56  jrl Z,0xfa6fd2
	ld	de, ix                                  ; FA6F59  ld DE,IX
sub_FA6F48__FA6F5B:
	cp (xiz+16), 0x00                          ; FA6F5B  cp (XIZ+0x10),0x00
	jr nz, sub_FA6F48__FA6F6C                  ; FA6F5F  jr NZ,0xfa6f6c
	extz	xde                                   ; FA6F61  extz XDE
	ld	c, (xde+19)                             ; FA6F63  ld C,(XDE+0x13)
	extpfx3 0x8E, 0x0E, 0xF3                   ; FA6F66  cp C,(XIZ+0x0e)
	jrl nz, sub_FA6F48__FA6FC9                 ; FA6F69  jrl NZ,0xfa6fc9
sub_FA6F48__FA6F6C:
	pushw	1                                    ; FA6F6C  push 0x0001
	extz	xde                                   ; FA6F6F  extz XDE
	ld	bc, (xde+12)                            ; FA6F71  ld BC,(XDE+0x0c)
	pushw	bc                                   ; FA6F74  push BC
	pushw	de                                   ; FA6F75  push DE
	calr (0xFA643F - 0xFA6F79)                 ; FA6F76  calr 0xfa643f
	pushw	de                                   ; FA6F79  push DE
	calr (0xFA65F6 - 0xFA6F7D)                 ; FA6F7A  calr 0xfa65f6
	ld	c, (xde+20)                             ; FA6F7D  ld C,(XDE+0x14)
	ld	(xiz-2), c                              ; FA6F80  ld (XIZ+0xfe),C
	ld	xbc, (xiz+8)                            ; FA6F83  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc)                              ; FA6F86  ld XWA,(XBC)
	ld	c, (xiz-2)                              ; FA6F88  ld C,(XIZ+0xfe)
	ld	(xwa), c                                ; FA6F8B  ld (XWA),C
	ld	xbc, (xiz+8)                            ; FA6F8D  ld XBC,(XIZ+0x08)
	sub	xwa, xwa                               ; FA6F90  sub XWA,XWA
	inc	1, xwa                                 ; FA6F92  inc 1,XWA
	add	(xbc), xwa                             ; FA6F94  add (XBC),XWA
	ld	hl, (xde+8)                             ; FA6F96  ld HL,(XDE+0x08)
	inc	8, xsp                                 ; FA6F99  inc 0,XSP
	cp	de, hl                                  ; FA6F9B  cp DE,HL
	jr z, sub_FA6F48__FA6FD2                   ; FA6F9D  jr Z,0xfa6fd2
	ld	ix, de                                  ; FA6F9F  ld IX,DE
	extz	xix                                   ; FA6FA1  extz XIX
	ld	bc, (xix+8)                             ; FA6FA3  ld BC,(XIX+0x08)
	ld	(xiz-2), bc                             ; FA6FA6  ld (XIZ+0xfe),BC
	ld	wa, (xix+10)                            ; FA6FA9  ld WA,(XIX+0x0a)
	ld	(xiz-4), wa                             ; FA6FAC  ld (XIZ+0xfc),WA
	extz	xwa                                   ; FA6FAF  extz XWA
	ld	(xwa+8), bc                             ; FA6FB1  ld (XWA+0x08),BC
	ld	bc, (xiz-2)                             ; FA6FB4  ld BC,(XIZ+0xfe)
	extz	xbc                                   ; FA6FB7  extz XBC
	ld	wa, (xiz-4)                             ; FA6FB9  ld WA,(XIZ+0xfc)
	ld	(xbc+10), wa                            ; FA6FBC  ld (XBC+0x0a),WA
	ld	(xix+8), ix                             ; FA6FBF  ld (XIX+0x08),IX
	ld	(xix+10), ix                            ; FA6FC2  ld (XIX+0x0a),IX
	ld	de, hl                                  ; FA6FC5  ld DE,HL
	jr sub_FA6F48__FA6F6C                      ; FA6FC7  jr T,0xfa6f6c
sub_FA6F48__FA6FC9:
	extz	xde                                   ; FA6FC9  extz XDE
	ld	de, (xde+4)                             ; FA6FCB  ld DE,(XDE+0x04)
	cp	de, ix                                  ; FA6FCE  cp DE,IX
	jr nz, sub_FA6F48__FA6F5B                  ; FA6FD0  jr NZ,0xfa6f5b
sub_FA6F48__FA6FD2:
	ld	xbc, (xiz+8)                            ; FA6FD2  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc)                              ; FA6FD5  ld XWA,(XBC)
	ld	(xwa), 0xFF                             ; FA6FD7  ld (XWA),0xff
	pop	xix                                    ; FA6FDA  pop XIX
	pop	xde                                    ; FA6FDB  pop XDE
	popw	hl                                    ; FA6FDC  pop HL
	unlk32 xiz                                 ; FA6FDD  unlk XIZ
	ret                                        ; FA6FDF  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `VoiceQuery_Run` is now `VoiceQuery_Run`.
;   GRADE PROVEN.  WHY `VoiceQuery_Run`:
;   its six callers are exactly the six VoiceQuery_Tag* wrappers, and it is the
;   whole body of all six: it selects on the request's tag byte req[0] (bits
;   0x80 / 0x40) and on req[+3] bit 7, walks part queue 0 and/or queue 1 of
;   0x041C + 6*part -- or all 64 channel records when req[+3]'s part field is
;   non-zero -- and writes the matching channel numbers to req+5, 0xFF-terminated.
; VoiceQuery_Run -- 0xFA6FE0..0xFA727C (669 bytes)
;
; Called from: 6 site(s) outside this module:
;          0xFB3C53 in VoiceQuery_Tag80_PartNote, 0xFB3C80 in VoiceQuery_Tag80_Part
;          0xFB3CA9 in VoiceQuery_Tag40_Part, 0xFB3CD5 in VoiceQuery_Tag00_PartBit7
;          0xFB3CFE in VoiceQuery_Tag00_Part, 0xFB3D1D in VoiceQuery_Tag00_All
; Inputs:  frame `link XIZ,-15`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA6F48 = ChanRec_ReleaseQueueAndCollect
; Evidence: the listing below is the byte-identical round-trip of 0xFA6FE0-0xFA727C
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
VoiceQuery_Run:
	link32 0xEE, 0x0C, 0xF1, 0xFF              ; FA6FE0  link XIZ,0xfff1
	push	xhl                                   ; FA6FE4  push XHL
	push	xde                                   ; FA6FE5  push XDE
	push	xix                                   ; FA6FE6  push XIX
	ld	xbc, (xiz+8)                            ; FA6FE7  ld XBC,(XIZ+0x08)
	ld	a, (xbc+3)                              ; FA6FEA  ld A,(XBC+0x03)
	res	7, a                                   ; FA6FED  res 0x07,A
	ld	(xiz-1), a                              ; FA6FF0  ld (XIZ+0xff),A
	ld	w, (xbc+1)                              ; FA6FF3  ld W,(XBC+0x01)
	res	7, w                                   ; FA6FF6  res 0x07,W
	ld	(xiz-2), w                              ; FA6FF9  ld (XIZ+0xfe),W
	inc	5, xbc                                 ; FA6FFC  inc 5,XBC
	ld	(xiz-6), xbc                            ; FA6FFE  ld (XIZ+0xfa),XBC
	ld	xiy, (xiz+8)                            ; FA7001  ld XIY,(XIZ+0x08)
	ld	bc, (xiy+3)                             ; FA7004  ld BC,(XIY+0x03)
	and	bc, 0x1F00                             ; FA7007  and BC,0x1f00
	jr z, sub_FA6FE0__FA703C                   ; FA700B  jr Z,0xfa703c
	ldw	de, 0x4E8                              ; FA700D  ld DE,0x04e8
	ldb	h, 64                                  ; FA7010  ld H,0x40
sub_FA6FE0__FA7012:
	extz	xde                                   ; FA7012  extz XDE
	ld	c, (xde+18)                             ; FA7014  ld C,(XDE+0x12)
	and	c, 1                                   ; FA7017  and C,0x01
	jr nz, sub_FA6FE0__FA702F                  ; FA701A  jr NZ,0xfa702f
	extz	xde                                   ; FA701C  extz XDE
	ld	c, (xde+20)                             ; FA701E  ld C,(XDE+0x14)
	ld	l, c                                    ; FA7021  ld L,C
	ld	xbc, (xiz-6)                            ; FA7023  ld XBC,(XIZ+0xfa)
	ld	(xbc), l                                ; FA7026  ld (XBC),L
	sub	xbc, xbc                               ; FA7028  sub XBC,XBC
	inc	1, xbc                                 ; FA702A  inc 1,XBC
	add	(xiz-6), xbc                           ; FA702C  add (XIZ+0xfa),XBC
sub_FA6FE0__FA702F:
	add	de, 23                                 ; FA702F  add DE,0x0017
	dec	1, h                                   ; FA7033  dec 1,H
	cps	h, 0                                   ; FA7035  cp H,0
	jr nz, sub_FA6FE0__FA7012                  ; FA7037  jr NZ,0xfa7012
	jrl sub_FA6FE0__FA7271                     ; FA7039  jrl T,0xfa7271
sub_FA6FE0__FA703C:
	ld	xbc, (xiz+8)                            ; FA703C  ld XBC,(XIZ+0x08)
	ld	wa, (xbc+1)                             ; FA703F  ld WA,(XBC+0x01)
	and	wa, 0x1F00                             ; FA7042  and WA,0x1f00
	srl	wa, 8                                  ; FA7046  srl 0x08,WA
	ld	h, a                                    ; FA7049  ld H,A
	mul	a, 6                                   ; FA704B  mul A,0x06
	ld	de, wa                                  ; FA704E  ld DE,WA
	inc	2, wa                                  ; FA7050  inc 2,WA
	ld	(xiz-13), wa                            ; FA7052  ld (XIZ+0xf3),WA
	ldw	bc, 0x41C                              ; FA7055  ld BC,0x041c
	ld	(xiz-15), bc                            ; FA7058  ld (XIZ+0xf1),BC
	add	bc, wa                                 ; FA705B  add BC,WA
	extz	xbc                                   ; FA705D  extz XBC
	ld	xix, xbc                                ; FA705F  ld XIX,XBC
	ld	wa, de                                  ; FA7061  ld WA,DE
	inc	4, wa                                  ; FA7063  inc 4,WA
	extpfx3 0x9E, 0xF1, 0x80                   ; FA7065  add WA,(XIZ+0xf1)
	extz	xwa                                   ; FA7068  extz XWA
	ld	(xiz-10), xwa                           ; FA706A  ld (XIZ+0xf6),XWA
	cp	h, 33                                   ; FA706D  cp H,0x21
	jrl nc, sub_FA6FE0__FA7271                 ; FA7070  jrl NC,0xfa7271
	ld	xiy, (xiz+8)                            ; FA7073  ld XIY,(XIZ+0x08)
	ld	h, (xiy)                                ; FA7076  ld H,(XIY)
	ld	c, h                                    ; FA7078  ld C,H
	and	c, 0x80                                ; FA707A  and C,0x80
	jr z, sub_FA6FE0__FA70D6                   ; FA707D  jr Z,0xfa70d6
	ld	bc, (xiy+3)                             ; FA707F  ld BC,(XIY+0x03)
	and	bc, 0x7F                               ; FA7082  and BC,0x007f
	jr z, sub_FA6FE0__FA70BB                   ; FA7086  jr Z,0xfa70bb
	ld	hl, (xix)                               ; FA7088  ld HL,(XIX)
	sub	bc, bc                                 ; FA708A  sub BC,BC
	cp	hl, bc                                  ; FA708C  cp HL,BC
	jrl z, sub_FA6FE0__FA7271                  ; FA708E  jrl Z,0xfa7271
	ld	de, hl                                  ; FA7091  ld DE,HL
sub_FA6FE0__FA7093:
	push	0                                     ; FA7093  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FA7095  push (XIZ+0xff)
	push	0                                     ; FA7098  push 0x00
	extpfx3 0x8E, 0xFE, 0x04                   ; FA709A  push (XIZ+0xfe)
	ld	bc, (xix)                               ; FA709D  ld BC,(XIX)
	pushw	bc                                   ; FA709F  push BC
	lda	xbc, (xiz-6)                           ; FA70A0  lda XBC,XIZ+0xfa
	push	xbc                                   ; FA70A3  push XBC
	calr (0xFA6F48 - 0xFA70A7)                 ; FA70A4  calr 0xfa6f48
	ld	hl, (xix)                               ; FA70A7  ld HL,(XIX)
	sub	bc, bc                                 ; FA70A9  sub BC,BC
	inc	8, xsp                                 ; FA70AB  inc 0,XSP
	inc	2, xsp                                 ; FA70AD  inc 2,XSP
	cp	hl, bc                                  ; FA70AF  cp HL,BC
	jrl z, sub_FA6FE0__FA7271                  ; FA70B1  jrl Z,0xfa7271
	cp	hl, de                                  ; FA70B4  cp HL,DE
	jrl z, sub_FA6FE0__FA7271                  ; FA70B6  jrl Z,0xfa7271
	jr sub_FA6FE0__FA7093                      ; FA70B9  jr T,0xfa7093
sub_FA6FE0__FA70BB:
	push	0                                     ; FA70BB  push 0x00
	extpfx3 0x8E, 0xFF, 0x04                   ; FA70BD  push (XIZ+0xff)
	push	0                                     ; FA70C0  push 0x00
	extpfx3 0x8E, 0xFE, 0x04                   ; FA70C2  push (XIZ+0xfe)
	ld	bc, (xix)                               ; FA70C5  ld BC,(XIX)
	pushw	bc                                   ; FA70C7  push BC
	lda	xbc, (xiz-6)                           ; FA70C8  lda XBC,XIZ+0xfa
	push	xbc                                   ; FA70CB  push XBC
	calr (0xFA6F48 - 0xFA70CF)                 ; FA70CC  calr 0xfa6f48
	inc	8, xsp                                 ; FA70CF  inc 0,XSP
	inc	2, xsp                                 ; FA70D1  inc 2,XSP
	jrl sub_FA6FE0__FA7277                     ; FA70D3  jrl T,0xfa7277
sub_FA6FE0__FA70D6:
	ld	c, h                                    ; FA70D6  ld C,H
	and	c, 64                                  ; FA70D8  and C,0x40
	jr z, sub_FA6FE0__FA712B                   ; FA70DB  jr Z,0xfa712b
	ld	c, (xiz-2)                              ; FA70DD  ld C,(XIZ+0xfe)
	ld	(xiz-11), c                             ; FA70E0  ld (XIZ+0xf5),C
	ld	xbc, (xiz-10)                           ; FA70E3  ld XBC,(XIZ+0xf6)
	ld	de, (xbc)                               ; FA70E6  ld DE,(XBC)
	lda	xix, (xiz-6)                           ; FA70E8  lda XIX,XIZ+0xfa
	sub	wa, wa                                 ; FA70EB  sub WA,WA
	cp	de, wa                                  ; FA70ED  cp DE,WA
	jr z, sub_FA6FE0__FA7123                   ; FA70EF  jr Z,0xfa7123
	ld	hl, de                                  ; FA70F1  ld HL,DE
sub_FA6FE0__FA70F3:
	cp (xiz-1), 0x00                           ; FA70F3  cp (XIZ+0xff),0x00
	jr nz, sub_FA6FE0__FA7103                  ; FA70F7  jr NZ,0xfa7103
	extz	xhl                                   ; FA70F9  extz XHL
	ld	c, (xhl+19)                             ; FA70FB  ld C,(XHL+0x13)
	extpfx3 0x8E, 0xF5, 0xF3                   ; FA70FE  cp C,(XIZ+0xf5)
	jr nz, sub_FA6FE0__FA711A                  ; FA7101  jr NZ,0xfa711a
sub_FA6FE0__FA7103:
	extz	xhl                                   ; FA7103  extz XHL
	ld	c, (xhl+20)                             ; FA7105  ld C,(XHL+0x14)
	ld	(xiz-13), c                             ; FA7108  ld (XIZ+0xf3),C
	ld	xbc, (xiz-6)                            ; FA710B  ld XBC,(XIZ+0xfa)
	ld	a, (xiz-13)                             ; FA710E  ld A,(XIZ+0xf3)
	ld	(xbc), a                                ; FA7111  ld (XBC),A
	sub	xbc, xbc                               ; FA7113  sub XBC,XBC
	inc	1, xbc                                 ; FA7115  inc 1,XBC
	add	(xiz-6), xbc                           ; FA7117  add (XIZ+0xfa),XBC
sub_FA6FE0__FA711A:
	extz	xhl                                   ; FA711A  extz XHL
	ld	hl, (xhl+4)                             ; FA711C  ld HL,(XHL+0x04)
	cp	hl, de                                  ; FA711F  cp HL,DE
	jr nz, sub_FA6FE0__FA70F3                  ; FA7121  jr NZ,0xfa70f3
sub_FA6FE0__FA7123:
	ld	xbc, (xix)                              ; FA7123  ld XBC,(XIX)
	ld	(xbc), 0xFF                             ; FA7125  ld (XBC),0xff
	jrl sub_FA6FE0__FA7277                     ; FA7128  jrl T,0xfa7277
sub_FA6FE0__FA712B:
	ld	xbc, (xiz+8)                            ; FA712B  ld XBC,(XIZ+0x08)
	ld	wa, (xbc+3)                             ; FA712E  ld WA,(XBC+0x03)
	and	wa, 0x80                               ; FA7131  and WA,0x0080
	jrl z, sub_FA6FE0__FA71CE                  ; FA7135  jrl Z,0xfa71ce
	ld	a, (xiz-2)                              ; FA7138  ld A,(XIZ+0xfe)
	ld	(xiz-11), a                             ; FA713B  ld (XIZ+0xf5),A
	ld	de, (xix)                               ; FA713E  ld DE,(XIX)
	lda	xix, (xiz-6)                           ; FA7140  lda XIX,XIZ+0xfa
	sub	wa, wa                                 ; FA7143  sub WA,WA
	cp	de, wa                                  ; FA7145  cp DE,WA
	jr z, sub_FA6FE0__FA717B                   ; FA7147  jr Z,0xfa717b
	ld	hl, de                                  ; FA7149  ld HL,DE
sub_FA6FE0__FA714B:
	cp (xiz-1), 0x00                           ; FA714B  cp (XIZ+0xff),0x00
	jr nz, sub_FA6FE0__FA715B                  ; FA714F  jr NZ,0xfa715b
	extz	xhl                                   ; FA7151  extz XHL
	ld	c, (xhl+19)                             ; FA7153  ld C,(XHL+0x13)
	extpfx3 0x8E, 0xF5, 0xF3                   ; FA7156  cp C,(XIZ+0xf5)
	jr nz, sub_FA6FE0__FA7172                  ; FA7159  jr NZ,0xfa7172
sub_FA6FE0__FA715B:
	extz	xhl                                   ; FA715B  extz XHL
	ld	c, (xhl+20)                             ; FA715D  ld C,(XHL+0x14)
	ld	(xiz-13), c                             ; FA7160  ld (XIZ+0xf3),C
	ld	xbc, (xiz-6)                            ; FA7163  ld XBC,(XIZ+0xfa)
	ld	a, (xiz-13)                             ; FA7166  ld A,(XIZ+0xf3)
	ld	(xbc), a                                ; FA7169  ld (XBC),A
	sub	xbc, xbc                               ; FA716B  sub XBC,XBC
	inc	1, xbc                                 ; FA716D  inc 1,XBC
	add	(xiz-6), xbc                           ; FA716F  add (XIZ+0xfa),XBC
sub_FA6FE0__FA7172:
	extz	xhl                                   ; FA7172  extz XHL
	ld	hl, (xhl+4)                             ; FA7174  ld HL,(XHL+0x04)
	cp	hl, de                                  ; FA7177  cp HL,DE
	jr nz, sub_FA6FE0__FA714B                  ; FA7179  jr NZ,0xfa714b
sub_FA6FE0__FA717B:
	ld	xbc, (xix)                              ; FA717B  ld XBC,(XIX)
	ld	(xbc), 0xFF                             ; FA717D  ld (XBC),0xff
	ld	c, (xiz-2)                              ; FA7180  ld C,(XIZ+0xfe)
	ld	(xiz-11), c                             ; FA7183  ld (XIZ+0xf5),C
	ld	xbc, (xiz-10)                           ; FA7186  ld XBC,(XIZ+0xf6)
	ld	de, (xbc)                               ; FA7189  ld DE,(XBC)
	lda	xix, (xiz-6)                           ; FA718B  lda XIX,XIZ+0xfa
	sub	wa, wa                                 ; FA718E  sub WA,WA
	cp	de, wa                                  ; FA7190  cp DE,WA
	jr z, sub_FA6FE0__FA71C6                   ; FA7192  jr Z,0xfa71c6
	ld	hl, de                                  ; FA7194  ld HL,DE
sub_FA6FE0__FA7196:
	cp (xiz-1), 0x00                           ; FA7196  cp (XIZ+0xff),0x00
	jr nz, sub_FA6FE0__FA71A6                  ; FA719A  jr NZ,0xfa71a6
	extz	xhl                                   ; FA719C  extz XHL
	ld	c, (xhl+19)                             ; FA719E  ld C,(XHL+0x13)
	extpfx3 0x8E, 0xF5, 0xF3                   ; FA71A1  cp C,(XIZ+0xf5)
	jr nz, sub_FA6FE0__FA71BD                  ; FA71A4  jr NZ,0xfa71bd
sub_FA6FE0__FA71A6:
	extz	xhl                                   ; FA71A6  extz XHL
	ld	c, (xhl+20)                             ; FA71A8  ld C,(XHL+0x14)
	ld	(xiz-13), c                             ; FA71AB  ld (XIZ+0xf3),C
	ld	xbc, (xiz-6)                            ; FA71AE  ld XBC,(XIZ+0xfa)
	ld	a, (xiz-13)                             ; FA71B1  ld A,(XIZ+0xf3)
	ld	(xbc), a                                ; FA71B4  ld (XBC),A
	sub	xbc, xbc                               ; FA71B6  sub XBC,XBC
	inc	1, xbc                                 ; FA71B8  inc 1,XBC
	add	(xiz-6), xbc                           ; FA71BA  add (XIZ+0xfa),XBC
sub_FA6FE0__FA71BD:
	extz	xhl                                   ; FA71BD  extz XHL
	ld	hl, (xhl+4)                             ; FA71BF  ld HL,(XHL+0x04)
	cp	hl, de                                  ; FA71C2  cp HL,DE
	jr nz, sub_FA6FE0__FA7196                  ; FA71C4  jr NZ,0xfa7196
sub_FA6FE0__FA71C6:
	ld	xbc, (xix)                              ; FA71C6  ld XBC,(XIX)
	ld	(xbc), 0xFF                             ; FA71C8  ld (XBC),0xff
	jrl sub_FA6FE0__FA7277                     ; FA71CB  jrl T,0xfa7277
sub_FA6FE0__FA71CE:
	ld	xbc, (xiz+8)                            ; FA71CE  ld XBC,(XIZ+0x08)
	ld	wa, (xbc+1)                             ; FA71D1  ld WA,(XBC+0x01)
	and	wa, 0x80                               ; FA71D4  and WA,0x0080
	jr z, sub_FA6FE0__FA7224                   ; FA71D8  jr Z,0xfa7224
	ld	a, (xiz-2)                              ; FA71DA  ld A,(XIZ+0xfe)
	ld	(xiz-11), a                             ; FA71DD  ld (XIZ+0xf5),A
	ld	de, (xix)                               ; FA71E0  ld DE,(XIX)
	lda	xix, (xiz-6)                           ; FA71E2  lda XIX,XIZ+0xfa
	sub	wa, wa                                 ; FA71E5  sub WA,WA
	cp	de, wa                                  ; FA71E7  cp DE,WA
	jr z, sub_FA6FE0__FA721D                   ; FA71E9  jr Z,0xfa721d
	ld	hl, de                                  ; FA71EB  ld HL,DE
sub_FA6FE0__FA71ED:
	cp (xiz-1), 0x00                           ; FA71ED  cp (XIZ+0xff),0x00
	jr nz, sub_FA6FE0__FA71FD                  ; FA71F1  jr NZ,0xfa71fd
	extz	xhl                                   ; FA71F3  extz XHL
	ld	c, (xhl+19)                             ; FA71F5  ld C,(XHL+0x13)
	extpfx3 0x8E, 0xF5, 0xF3                   ; FA71F8  cp C,(XIZ+0xf5)
	jr nz, sub_FA6FE0__FA7214                  ; FA71FB  jr NZ,0xfa7214
sub_FA6FE0__FA71FD:
	extz	xhl                                   ; FA71FD  extz XHL
	ld	c, (xhl+20)                             ; FA71FF  ld C,(XHL+0x14)
	ld	(xiz-13), c                             ; FA7202  ld (XIZ+0xf3),C
	ld	xbc, (xiz-6)                            ; FA7205  ld XBC,(XIZ+0xfa)
	ld	a, (xiz-13)                             ; FA7208  ld A,(XIZ+0xf3)
	ld	(xbc), a                                ; FA720B  ld (XBC),A
	sub	xbc, xbc                               ; FA720D  sub XBC,XBC
	inc	1, xbc                                 ; FA720F  inc 1,XBC
	add	(xiz-6), xbc                           ; FA7211  add (XIZ+0xfa),XBC
sub_FA6FE0__FA7214:
	extz	xhl                                   ; FA7214  extz XHL
	ld	hl, (xhl+4)                             ; FA7216  ld HL,(XHL+0x04)
	cp	hl, de                                  ; FA7219  cp HL,DE
	jr nz, sub_FA6FE0__FA71ED                  ; FA721B  jr NZ,0xfa71ed
sub_FA6FE0__FA721D:
	ld	xbc, (xix)                              ; FA721D  ld XBC,(XIX)
	ld	(xbc), 0xFF                             ; FA721F  ld (XBC),0xff
	jr sub_FA6FE0__FA7277                      ; FA7222  jr T,0xfa7277
sub_FA6FE0__FA7224:
	ld	c, (xiz-2)                              ; FA7224  ld C,(XIZ+0xfe)
	ld	(xiz-11), c                             ; FA7227  ld (XIZ+0xf5),C
	ld	xbc, (xiz-10)                           ; FA722A  ld XBC,(XIZ+0xf6)
	ld	de, (xbc)                               ; FA722D  ld DE,(XBC)
	lda	xix, (xiz-6)                           ; FA722F  lda XIX,XIZ+0xfa
	sub	wa, wa                                 ; FA7232  sub WA,WA
	cp	de, wa                                  ; FA7234  cp DE,WA
	jr z, sub_FA6FE0__FA726A                   ; FA7236  jr Z,0xfa726a
	ld	hl, de                                  ; FA7238  ld HL,DE
sub_FA6FE0__FA723A:
	cp (xiz-1), 0x00                           ; FA723A  cp (XIZ+0xff),0x00
	jr nz, sub_FA6FE0__FA724A                  ; FA723E  jr NZ,0xfa724a
	extz	xhl                                   ; FA7240  extz XHL
	ld	c, (xhl+19)                             ; FA7242  ld C,(XHL+0x13)
	extpfx3 0x8E, 0xF5, 0xF3                   ; FA7245  cp C,(XIZ+0xf5)
	jr nz, sub_FA6FE0__FA7261                  ; FA7248  jr NZ,0xfa7261
sub_FA6FE0__FA724A:
	extz	xhl                                   ; FA724A  extz XHL
	ld	c, (xhl+20)                             ; FA724C  ld C,(XHL+0x14)
	ld	(xiz-13), c                             ; FA724F  ld (XIZ+0xf3),C
	ld	xbc, (xiz-6)                            ; FA7252  ld XBC,(XIZ+0xfa)
	ld	a, (xiz-13)                             ; FA7255  ld A,(XIZ+0xf3)
	ld	(xbc), a                                ; FA7258  ld (XBC),A
	sub	xbc, xbc                               ; FA725A  sub XBC,XBC
	inc	1, xbc                                 ; FA725C  inc 1,XBC
	add	(xiz-6), xbc                           ; FA725E  add (XIZ+0xfa),XBC
sub_FA6FE0__FA7261:
	extz	xhl                                   ; FA7261  extz XHL
	ld	hl, (xhl+4)                             ; FA7263  ld HL,(XHL+0x04)
	cp	hl, de                                  ; FA7266  cp HL,DE
	jr nz, sub_FA6FE0__FA723A                  ; FA7268  jr NZ,0xfa723a
sub_FA6FE0__FA726A:
	ld	xbc, (xix)                              ; FA726A  ld XBC,(XIX)
	ld	(xbc), 0xFF                             ; FA726C  ld (XBC),0xff
	jr sub_FA6FE0__FA7277                      ; FA726F  jr T,0xfa7277
sub_FA6FE0__FA7271:
	ld	xbc, (xiz-6)                            ; FA7271  ld XBC,(XIZ+0xfa)
	ld	(xbc), 0xFF                             ; FA7274  ld (XBC),0xff
sub_FA6FE0__FA7277:
	pop	xix                                    ; FA7277  pop XIX
	pop	xde                                    ; FA7278  pop XDE
	pop	xhl                                    ; FA7279  pop XHL
	unlk32 xiz                                 ; FA727A  unlk XIZ
	ret                                        ; FA727C  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `VelSplit_LayerFromVelocity` is now `VelSplit_LayerFromVelocity`.
;   GRADE PROVEN.  WHY `VelSplit_LayerFromVelocity`:
;   body: `v = arg & 0x7F`; returns 0/1/2/3 for v <= t[0] / t[1] / t[2] / above.
;   Every caller passes VoiceParams_Compute_A's fourth argument, and
;   MidiNote_OnByPartMode pushes MidiNote_Dispatch's msg[3] into that slot
;   (0xFB38A4 / 0xFB38B7), i.e. the VELOCITY.
; VelSplit_LayerFromVelocity -- 0xFA727D..0xFA72B2 (54 bytes)
;
; Called from: 7 site(s) outside this module:
;          0xFB0C49 in sub_FB0B95__FB0C19, 0xFB0F00 in VoiceParams_Compute_A__FB0ED5
;          0xFB1116 in VoiceParams_Compute_A__FB10F4, 0xFB133F in VoiceParams_Compute_A__FB131D
;          0xFB15DB in VoiceParams_Compute_A__FB15B0, 0xFB1889 in VoiceParams_Compute_A__FB185E
;          0xFB1B5B in VoiceParams_Compute_A__FB1B30
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA727D-0xFA72B2
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
VelSplit_LayerFromVelocity:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA727D  link XIZ,0x0000
	pushw	hl                                   ; FA7281  push HL
	push	xix                                   ; FA7282  push XIX
	ld	xix, (xiz+10)                           ; FA7283  ld XIX,(XIZ+0x0a)
	ld	h, (xiz+8)                              ; FA7286  ld H,(XIZ+0x08)
	res	7, h                                   ; FA7289  res 0x07,H
	ld	c, (xix)                                ; FA728C  ld C,(XIX)
	cp	h, c                                    ; FA728E  cp H,C
	jr ule, sub_FA727D__FA72AC                 ; FA7290  jr ULE,0xfa72ac
	ld	c, (xix+1)                              ; FA7292  ld C,(XIX+0x01)
	cp	h, c                                    ; FA7295  cp H,C
	jr ule, sub_FA727D__FA72A8                 ; FA7297  jr ULE,0xfa72a8
	ld	c, (xix+2)                              ; FA7299  ld C,(XIX+0x02)
	cp	h, c                                    ; FA729C  cp H,C
	jr ule, sub_FA727D__FA72A4                 ; FA729E  jr ULE,0xfa72a4
	ldb	a, 3                                   ; FA72A0  ld A,0x03
	jr sub_FA727D__FA72AE                      ; FA72A2  jr T,0xfa72ae
sub_FA727D__FA72A4:
	ldb	a, 2                                   ; FA72A4  ld A,0x02
	jr sub_FA727D__FA72AE                      ; FA72A6  jr T,0xfa72ae
sub_FA727D__FA72A8:
	ldb	a, 1                                   ; FA72A8  ld A,0x01
	jr sub_FA727D__FA72AE                      ; FA72AA  jr T,0xfa72ae
sub_FA727D__FA72AC:
	sub	a, a                                   ; FA72AC  sub A,A
sub_FA727D__FA72AE:
	pop	xix                                    ; FA72AE  pop XIX
	popw	hl                                    ; FA72AF  pop HL
	unlk32 xiz                                 ; FA72B0  unlk XIZ
	ret                                        ; FA72B2  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `VelSplit_LayerFromVelocity_b` is now `VelSplit_LayerFromVelocity_b`.
;   GRADE PROVEN.  WHY `VelSplit_LayerFromVelocity_b`:
;   byte-for-byte identical to VelSplit_LayerFromVelocity (54 bytes, 0 differ,
;   prom_c_module_map.py --dups) and reached with the same argument from
;   VoiceParams_Compute_C/D.  The `_b` suffix is the tree's existing spelling
;   for a byte-identical twin (Clamp_ToRange_Word_b, ScaleClampedDelta_Shr5_b).
; VelSplit_LayerFromVelocity_b -- 0xFA72B3..0xFA72E8 (54 bytes)
;
; Called from: 6 site(s) outside this module:
;          0xFB290D in sub_FB289A, 0xFB2B1B in VoiceParams_Compute_C
;          0xFB2CD1 in VoiceParams_Compute_C__FB2C6D, 0xFB3048 in sub_FB2F74
;          0xFB328F in VoiceParams_Compute_D, 0xFB3492 in VoiceParams_Compute_D__FB33CE
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA72B3-0xFA72E8
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
VelSplit_LayerFromVelocity_b:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA72B3  link XIZ,0x0000
	pushw	hl                                   ; FA72B7  push HL
	push	xix                                   ; FA72B8  push XIX
	ld	xix, (xiz+10)                           ; FA72B9  ld XIX,(XIZ+0x0a)
	ld	h, (xiz+8)                              ; FA72BC  ld H,(XIZ+0x08)
	res	7, h                                   ; FA72BF  res 0x07,H
	ld	c, (xix)                                ; FA72C2  ld C,(XIX)
	cp	h, c                                    ; FA72C4  cp H,C
	jr ule, sub_FA72B3__FA72E2                 ; FA72C6  jr ULE,0xfa72e2
	ld	c, (xix+1)                              ; FA72C8  ld C,(XIX+0x01)
	cp	h, c                                    ; FA72CB  cp H,C
	jr ule, sub_FA72B3__FA72DE                 ; FA72CD  jr ULE,0xfa72de
	ld	c, (xix+2)                              ; FA72CF  ld C,(XIX+0x02)
	cp	h, c                                    ; FA72D2  cp H,C
	jr ule, sub_FA72B3__FA72DA                 ; FA72D4  jr ULE,0xfa72da
	ldb	a, 3                                   ; FA72D6  ld A,0x03
	jr sub_FA72B3__FA72E4                      ; FA72D8  jr T,0xfa72e4
sub_FA72B3__FA72DA:
	ldb	a, 2                                   ; FA72DA  ld A,0x02
	jr sub_FA72B3__FA72E4                      ; FA72DC  jr T,0xfa72e4
sub_FA72B3__FA72DE:
	ldb	a, 1                                   ; FA72DE  ld A,0x01
	jr sub_FA72B3__FA72E4                      ; FA72E0  jr T,0xfa72e4
sub_FA72B3__FA72E2:
	sub	a, a                                   ; FA72E2  sub A,A
sub_FA72B3__FA72E4:
	pop	xix                                    ; FA72E4  pop XIX
	popw	hl                                    ; FA72E5  pop HL
	unlk32 xiz                                 ; FA72E6  unlk XIZ
	ret                                        ; FA72E8  ret
; --------------------------------------------------------------------------
; Voice_GetOctaveShift -- 0xFA72E9..0xFA738E (166 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFA7F7A in Voice_ComputePitch
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
;          reads 0x0014FF, 0x00D7ED, 0x00D7F1
; Evidence: the listing below is the byte-identical round-trip of 0xFA72E9-0xFA738E
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Name:     returns a part's whole-octave pitch offset, in 8.8 semitones
; Evidence: its ONE caller is Voice_ComputePitch (0xFA7F7A). With bit 0 of
;           (0x14FF) set it reads directory slot +0x6C (ToneDB_BankMap) at
;           the part record's byte +28 (0xFA7311 `add IY,0x001C` then
;           0xFA7317 `ld C,(XIY+0x1523)`), uses the row number that returns
;           as a 128-entry stride into slot +0xA8
;           (ToneDB_OctaveShiftByProgram, 0xFA7332 and 0xFA7351 `sll
;           0x07,BC`) indexed by the part record's byte +27 (0xFA733B /
;           0xFA7341), and returns that byte shifted left 8 (0xFA735F).
;           prom_d's table holds only 0x00, 0xF4 and 0x0C -- 0, -12 and +12
;           -- so the shift makes the result semitones in 8.8. The third arm
;           (0xFA7372) reads Instrument_OctaveShift_Semitones at 0xFDF22A,
;           whose sixteen bytes ARE 12*k for k = -8..+7, sign-extends and
;           shifts by the same 8: two independent tables, one unit. ★ This
;           also confirms from the CONSUMER side what prom_d's own note left
;           open -- that the byte at voice record +27 is a program number
;           and +28 a bank selector
; Unknown:  what bit 0 and bit 1 of (0x14FF) select between the three arms
; Named:   ROUND 11, by notes/prom_c_inventory_round8.py -- it was `sub_FA72E9`.
; --------------------------------------------------------------------------
Voice_GetOctaveShift:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FA72E9  link XIZ,0xfffc
	pushw	hl                                   ; FA72ED  push HL
	pushw	de                                   ; FA72EE  push DE
	push	xix                                   ; FA72EF  push XIX
	ld	hl, (0x14FF:16)                       ; FA72F0  ld HL,(0x14ff)
	ld	bc, hl                                  ; FA72F4  ld BC,HL
	and	bc, 1                                  ; FA72F6  and BC,0x0001
	jr z, Voice_GetOctaveShift__FA7366                   ; FA72FA  jr Z,0xfa7366
	ld	xbc, (0xD7F1:24)                       ; FA72FC  ld XBC,(0x00d7f1)
	ld	xwa, (xbc+0x6C)                         ; FA7301  ld XWA,(XBC+0x6c)
	ld	xix, xwa                                ; FA7304  ld XIX,XWA
	ld	iy, (xiz+8)                             ; FA7306  ld IY,(XIZ+0x08)
	extz	iy                                    ; FA7309  extz IY
	mul	iy, 0x12C                              ; FA730B  mul IY,0x012c
	ld	hl, iy                                  ; FA730F  ld HL,IY
	add	iy, 28                                 ; FA7311  add IY,0x001c
	extz	xiy                                   ; FA7315  extz XIY
	ld	c, (xiy+0x1523)                         ; FA7317  ld C,(XIY+0x1523)
	extz	bc                                    ; FA731C  extz BC
	extz	xbc                                   ; FA731E  extz XBC
	add	xwa, xbc                               ; FA7320  add XWA,XBC
	addda32_24	xwa, (0xD7ED)                   ; FA7322  add XWA,(0x00d7ed)
	ld	c, (xwa)                                ; FA7327  ld C,(XWA)
	extz	bc                                    ; FA7329  extz BC
	ld	de, bc                                  ; FA732B  ld DE,BC
	ld	xwa, (0xD7F1:24)                       ; FA732D  ld XWA,(0x00d7f1)
	ld	xiy, (xwa+0xA8)                         ; FA7332  ld XIY,(XWA+0x00a8)
	ld	xix, xiy                                ; FA7337  ld XIX,XIY
	ld	bc, hl                                  ; FA7339  ld BC,HL
	add	bc, 27                                 ; FA733B  add BC,0x001b
	extz	xbc                                   ; FA733F  extz XBC
	ld	c, (xbc+0x1523)                         ; FA7341  ld C,(XBC+0x1523)
	extz	bc                                    ; FA7346  extz BC
	extz	xbc                                   ; FA7348  extz XBC
	add	xiy, xbc                               ; FA734A  add XIY,XBC
	ld	(xiz-4), xiy                            ; FA734C  ld (XIZ+0xfc),XIY
	ld	bc, de                                  ; FA734F  ld BC,DE
	sll	bc, 7                                  ; FA7351  sll 0x07,BC
	extz	xbc                                   ; FA7354  extz XBC
	add	xiy, xbc                               ; FA7356  add XIY,XBC
	addda32_24	xiy, (0xD7ED)                   ; FA7358  add XIY,(0x00d7ed)
	ld	bc, (xiy)                               ; FA735D  ld BC,(XIY)
	sll	bc, 8                                  ; FA735F  sll 0x08,BC
	ld	wa, bc                                  ; FA7362  ld WA,BC
	jr Voice_GetOctaveShift__FA7389                      ; FA7364  jr T,0xfa7389
Voice_GetOctaveShift__FA7366:
	ld	bc, hl                                  ; FA7366  ld BC,HL
	and	bc, 2                                  ; FA7368  and BC,0x0002
	jr z, Voice_GetOctaveShift__FA7372                   ; FA736C  jr Z,0xfa7372
	sub	wa, wa                                 ; FA736E  sub WA,WA
	jr Voice_GetOctaveShift__FA7389                      ; FA7370  jr T,0xfa7389
Voice_GetOctaveShift__FA7372:
	ld	c, (xiz+10)                             ; FA7372  ld C,(XIZ+0x0a)
	and	c, 15                                  ; FA7375  and C,0x0f
	extz	bc                                    ; FA7378  extz BC
	extz	xbc                                   ; FA737A  extz XBC
	add	xbc, 0xFDF22A                          ; FA737C  add XBC,0x00fdf22a
	ld	a, (xbc)                                ; FA7382  ld A,(XBC)
	exts	wa                                    ; FA7384  exts WA
	sll	wa, 8                                  ; FA7386  sll 0x08,WA
Voice_GetOctaveShift__FA7389:
	pop	xix                                    ; FA7389  pop XIX
	popw	de                                    ; FA738A  pop DE
	popw	hl                                    ; FA738B  pop HL
	unlk32 xiz                                 ; FA738C  unlk XIZ
	ret                                        ; FA738E  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `Pitch_ClampToNoteRange` is now `Pitch_ClampToNoteRange`.
;   GRADE PROVEN.  WHY `Pitch_ClampToNoteRange`:
;   body: negative pitches saturate to 0x7FFF or to 0 (the same 0xC000 split
;   Sat16_0_to_7FFF uses), then the value is clamped to
;   [lo*256 + 0x80, hi*256 + 0x80] -- the 1/256-semitone encoding of two note
;   numbers that Voice_ComputePitch's own header establishes.
; Pitch_ClampToNoteRange -- 0xFA738F..0xFA73EA (92 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFA813C in Voice_ComputePitch__FA813C
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA738F-0xFA73EA
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
Pitch_ClampToNoteRange:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA738F  link XIZ,0x0000
	pushw	hl                                   ; FA7393  push HL
	pushw	de                                   ; FA7394  push DE
	pushw	ix                                   ; FA7395  push IX
	ld	ix, (xiz+8)                             ; FA7396  ld IX,(XIZ+0x08)
	ld	de, ix                                  ; FA7399  ld DE,IX
	ld	bc, ix                                  ; FA739B  ld BC,IX
	and	bc, 0x8000                             ; FA739D  and BC,0x8000
	jr z, sub_FA738F__FA73AF                   ; FA73A1  jr Z,0xfa73af
	ldw	de, 0x7FFF                             ; FA73A3  ld DE,0x7fff
	cp	ix, 0xC000                              ; FA73A6  cp IX,0xc000
	jr le, sub_FA738F__FA73AF                  ; FA73AA  jr LE,0xfa73af
	ldw	de, 0                                  ; FA73AC  ld DE,0x0000
sub_FA738F__FA73AF:
	ld	hl, (xiz+10)                            ; FA73AF  ld HL,(XIZ+0x0a)
	extz	hl                                    ; FA73B2  extz HL
	ld	bc, hl                                  ; FA73B4  ld BC,HL
	sll	bc, 8                                  ; FA73B6  sll 0x08,BC
	ld	hl, bc                                  ; FA73B9  ld HL,BC
	add	bc, 0x80                               ; FA73BB  add BC,0x0080
	ld	hl, bc                                  ; FA73BF  ld HL,BC
	cp	de, bc                                  ; FA73C1  cp DE,BC
	jr ge, sub_FA738F__FA73C9                  ; FA73C3  jr GE,0xfa73c9
	ld	wa, bc                                  ; FA73C5  ld WA,BC
	jr sub_FA738F__FA73E5                      ; FA73C7  jr T,0xfa73e5
sub_FA738F__FA73C9:
	ld	hl, (xiz+12)                            ; FA73C9  ld HL,(XIZ+0x0c)
	extz	hl                                    ; FA73CC  extz HL
	ld	bc, hl                                  ; FA73CE  ld BC,HL
	sll	bc, 8                                  ; FA73D0  sll 0x08,BC
	ld	hl, bc                                  ; FA73D3  ld HL,BC
	add	bc, 0x80                               ; FA73D5  add BC,0x0080
	ld	hl, bc                                  ; FA73D9  ld HL,BC
	cp	de, bc                                  ; FA73DB  cp DE,BC
	jr le, sub_FA738F__FA73E3                  ; FA73DD  jr LE,0xfa73e3
	ld	wa, bc                                  ; FA73DF  ld WA,BC
	jr sub_FA738F__FA73E5                      ; FA73E1  jr T,0xfa73e5
sub_FA738F__FA73E3:
	ld	wa, de                                  ; FA73E3  ld WA,DE
sub_FA738F__FA73E5:
	popw	ix                                    ; FA73E5  pop IX
	popw	de                                    ; FA73E6  pop DE
	popw	hl                                    ; FA73E7  pop HL
	unlk32 xiz                                 ; FA73E8  unlk XIZ
	ret                                        ; FA73EA  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `Pitch_FoldOctavesIntoRange` is now `Pitch_FoldOctavesIntoRange`.
;   GRADE PROVEN.  WHY `Pitch_FoldOctavesIntoRange`:
;   the same two bounds, but instead of clamping it ADDS or SUBTRACTS 0x0C00 --
;   twelve semitones in the 1/256-semitone unit -- until the pitch lies inside
;   the range.
; Pitch_FoldOctavesIntoRange -- 0xFA73EB..0xFA744E (100 bytes)
;
; Called from: 3 site(s) outside this module:
;          0xFA8132 in Voice_ComputePitch__FA80E2, 0xFA818C in Voice_ComputePitch_FromToneRecord
;          0xFC375D in sub_FC36BE
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA73EB-0xFA744E
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
Pitch_FoldOctavesIntoRange:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA73EB  link XIZ,0x0000
	pushw	hl                                   ; FA73EF  push HL
	pushw	de                                   ; FA73F0  push DE
	ld	de, (xiz+8)                             ; FA73F1  ld DE,(XIZ+0x08)
sub_FA73EB__FA73F4:
	ld	bc, de                                  ; FA73F4  ld BC,DE
	and	bc, 0x8000                             ; FA73F6  and BC,0x8000
	jr z, sub_FA73EB__FA740F                   ; FA73FA  jr Z,0xfa740f
	cp	de, 0xC000                              ; FA73FC  cp DE,0xc000
	jr le, sub_FA73EB__FA7408                  ; FA7400  jr LE,0xfa7408
	add	de, 0xC00                              ; FA7402  add DE,0x0c00
	jr sub_FA73EB__FA73F4                      ; FA7406  jr T,0xfa73f4
sub_FA73EB__FA7408:
	ldw	bc, 0xC00                              ; FA7408  ld BC,0x0c00
	sub	de, bc                                 ; FA740B  sub DE,BC
	jr sub_FA73EB__FA73F4                      ; FA740D  jr T,0xfa73f4
sub_FA73EB__FA740F:
	ld	hl, (xiz+10)                            ; FA740F  ld HL,(XIZ+0x0a)
	extz	hl                                    ; FA7412  extz HL
	ld	bc, hl                                  ; FA7414  ld BC,HL
	sll	bc, 8                                  ; FA7416  sll 0x08,BC
	ld	hl, bc                                  ; FA7419  ld HL,BC
	add	bc, 0x80                               ; FA741B  add BC,0x0080
	ld	hl, bc                                  ; FA741F  ld HL,BC
sub_FA73EB__FA7421:
	cp	de, hl                                  ; FA7421  cp DE,HL
	jr ge, sub_FA73EB__FA742B                  ; FA7423  jr GE,0xfa742b
	add	de, 0xC00                              ; FA7425  add DE,0x0c00
	jr sub_FA73EB__FA7421                      ; FA7429  jr T,0xfa7421
sub_FA73EB__FA742B:
	ld	hl, (xiz+12)                            ; FA742B  ld HL,(XIZ+0x0c)
	extz	hl                                    ; FA742E  extz HL
	ld	bc, hl                                  ; FA7430  ld BC,HL
	sll	bc, 8                                  ; FA7432  sll 0x08,BC
	ld	hl, bc                                  ; FA7435  ld HL,BC
	add	bc, 0x80                               ; FA7437  add BC,0x0080
	ld	hl, bc                                  ; FA743B  ld HL,BC
sub_FA73EB__FA743D:
	cp	de, hl                                  ; FA743D  cp DE,HL
	jr le, sub_FA73EB__FA7448                  ; FA743F  jr LE,0xfa7448
	ldw	bc, 0xC00                              ; FA7441  ld BC,0x0c00
	sub	de, bc                                 ; FA7444  sub DE,BC
	jr sub_FA73EB__FA743D                      ; FA7446  jr T,0xfa743d
sub_FA73EB__FA7448:
	ld	wa, de                                  ; FA7448  ld WA,DE
	popw	de                                    ; FA744A  pop DE
	popw	hl                                    ; FA744B  pop HL
	unlk32 xiz                                 ; FA744C  unlk XIZ
	ret                                        ; FA744E  ret
; --------------------------------------------------------------------------
; KeyMap_LookupByPitch -- 0xFA744F..0xFA7466 (24 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFA81E5 in Voice_SelectKeyZone_Reg0040__FA81C1
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA744F-0xFA7466
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  A 128-ENTRY KEY MAP.  Returns, in A, the byte at
;          arg0 + ((arg1 & 0x7F00) >> 8) -- arg1 being a pitch in Voice_ComputePitch's
;          units, so the index is its NOTE NUMBER, 0..127, and the table it indexes is
;          128 bytes long.
; Evidence: `and BC,0x7F00 / sra 0x08,BC` at 0xFA7456, `exts XBC / add XBC,(XIZ+0x08) /
;          ld A,(XBC)` at 0xFA745D.  notes/prom_c_dev10c_meaning_checks.py section 10.
;          Its one caller, Voice_SelectKeyZone_Reg0040, passes voice[+0x06] as arg1 and uses
;          the returned byte as the record index of the four KeyZone_Stage_* walkers -- the
;          shape of a key-split (multisample) map.
; --------------------------------------------------------------------------
KeyMap_LookupByPitch:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA744F  link XIZ,0x0000
	ld	bc, (xiz+12)                            ; FA7453  ld BC,(XIZ+0x0c)
	and	bc, 0x7F00                             ; FA7456  and BC,0x7f00
	sra	bc, 8                                  ; FA745A  sra 0x08,BC
	exts	xbc                                   ; FA745D  exts XBC
	extpfx3 0xAE, 0x08, 0x81                   ; FA745F  add XBC,(XIZ+0x08)
	ld	a, (xbc)                                ; FA7462  ld A,(XBC)
	unlk32 xiz                                 ; FA7464  unlk XIZ
	ret                                        ; FA7466  ret
; --------------------------------------------------------------------------
; KeyZone_Stage_Reg0040_Stride8 -- 0xFA7467..0xFA74AA (68 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFA8210 in Voice_SelectKeyZone_Reg0040__FA81C1
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0E)
; Outputs: writes 0x005A4F, 0x00D760
; Calls:   0xFC4D85 = Pack104_SetInputs_Rec0C_E08C
; Evidence: the listing below is the byte-identical round-trip of 0xFA7467-0xFA74AA
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  One of FOUR walkers that index a key-zone record array of stride 8
;          and copy record word 0 into staging word 1 (RAM 0x00D760), which
;          Dev10C_WriteAllChanRegs sends to 0x0010C000 register `chan + 0x0040`.  It also
;          stores the record cursor in voice[+0x0F], ORs 0x6000 into voice[+0x01], and hands
;          three record bytes to Pack104_SetInputs_Rec0C_E08C for the 0x00104000 side.
; Evidence: the stride is the `ld C,imm8` at offset +9 of the body; the mask is the
;          `or (XHL+0x01),imm16` at +0x1D; the store is `ld (0x00D760),BC`.
;          ⚠ THE FOUR ARE NOT COPIES OF ONE ANOTHER -- pairwise, 18 to 38 of the bytes they
;          share differ.  Both the strides and the difference counts are asserted by
;          notes/prom_c_dev10c_meaning_checks.py section 11.
; Unknown:  what the records are.  Only their word 0 reaches this device.
; --------------------------------------------------------------------------
KeyZone_Stage_Reg0040_Stride8:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA7467  link XIZ,0x0000
	push	xhl                                   ; FA746B  push XHL
	push	xix                                   ; FA746C  push XIX
	ld	hl, (xiz+8)                             ; FA746D  ld HL,(XIZ+0x08)
	ldb	c, 8                                   ; FA7470  ld C,0x08
	extpfx3 0x8E, 0x0E, 0x43                   ; FA7472  mul BC,(XIZ+0x0e)
	extz	xbc                                   ; FA7475  extz XBC
	ld	xix, xbc                                ; FA7477  ld XIX,XBC
	extpfx3 0xAE, 0x0A, 0x84                   ; FA7479  add XIX,(XIZ+0x0a)
	extz	xhl                                   ; FA747C  extz XHL
	ld	(xhl+15), xix                           ; FA747E  ld (XHL+0x0f),XIX
	extpfx5 0x9B, 0x01, 0x3E, 0x00, 0x60       ; FA7481  or (XHL+0x01),0x6000
	ld	bc, (xix)                               ; FA7486  ld BC,(XIX)
	ld	(0xD760:24), bc                        ; FA7488  ld (0x00d760),BC
	ld	bc, (xix+6)                             ; FA748D  ld BC,(XIX+0x06)
	ld	(0x5A4F:16), bc                        ; FA7490  ld (0x5a4f),BC
	ld	bc, (xix+6)                             ; FA7494  ld BC,(XIX+0x06)
	pushw	bc                                   ; FA7497  push BC
	ld	c, (xix+5)                              ; FA7498  ld C,(XIX+0x05)
	pushw	bc                                   ; FA749B  push BC
	ld	c, (xix+4)                              ; FA749C  ld C,(XIX+0x04)
	pushw	bc                                   ; FA749F  push BC
	call	0xFC4D85                              ; FA74A0  call 0xfc4d85
	inc	6, xsp                                 ; FA74A4  inc 6,XSP
	pop	xix                                    ; FA74A6  pop XIX
	pop	xhl                                    ; FA74A7  pop XHL
	unlk32 xiz                                 ; FA74A8  unlk XIZ
	ret                                        ; FA74AA  ret
; --------------------------------------------------------------------------
; KeyZone_Stage_Reg0040_Stride6A -- 0xFA74AB..0xFA74EC (66 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFA8215 in Voice_SelectKeyZone_Reg0040__FA8215
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0E)
; Outputs: writes 0x005A4F, 0x00D760
; Calls:   0xFC4D85 = Pack104_SetInputs_Rec0C_E08C
; Evidence: the listing below is the byte-identical round-trip of 0xFA74AB-0xFA74EC
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  One of FOUR walkers that index a key-zone record array of stride 6
;          and copy record word 0 into staging word 1 (RAM 0x00D760), which
;          Dev10C_WriteAllChanRegs sends to 0x0010C000 register `chan + 0x0040`.  It also
;          stores the record cursor in voice[+0x0F], ORs 0x6000 into voice[+0x01], and hands
;          three record bytes to Pack104_SetInputs_Rec0C_E08C for the 0x00104000 side.
; Evidence: the stride is the `ld C,imm8` at offset +9 of the body; the mask is the
;          `or (XHL+0x01),imm16` at +0x1D; the store is `ld (0x00D760),BC`.
;          ⚠ THE FOUR ARE NOT COPIES OF ONE ANOTHER -- pairwise, 18 to 38 of the bytes they
;          share differ.  Both the strides and the difference counts are asserted by
;          notes/prom_c_dev10c_meaning_checks.py section 11.
; Unknown:  what the records are.  Only their word 0 reaches this device.
; --------------------------------------------------------------------------
KeyZone_Stage_Reg0040_Stride6A:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA74AB  link XIZ,0x0000
	push	xhl                                   ; FA74AF  push XHL
	push	xix                                   ; FA74B0  push XIX
	ld	hl, (xiz+8)                             ; FA74B1  ld HL,(XIZ+0x08)
	ldb	c, 6                                   ; FA74B4  ld C,0x06
	extpfx3 0x8E, 0x0E, 0x43                   ; FA74B6  mul BC,(XIZ+0x0e)
	extz	xbc                                   ; FA74B9  extz XBC
	ld	xix, xbc                                ; FA74BB  ld XIX,XBC
	extpfx3 0xAE, 0x0A, 0x84                   ; FA74BD  add XIX,(XIZ+0x0a)
	extz	xhl                                   ; FA74C0  extz XHL
	ld	(xhl+15), xix                           ; FA74C2  ld (XHL+0x0f),XIX
	extpfx5 0x9B, 0x01, 0x3E, 0x00, 0x60       ; FA74C5  or (XHL+0x01),0x6000
	ld	bc, (xix)                               ; FA74CA  ld BC,(XIX)
	ld	(0xD760:24), bc                        ; FA74CC  ld (0x00d760),BC
	ldw	(0x5A4F:16), 0                         ; FA74D1  ld (0x5a4f),0x0000
	pushw	0                                    ; FA74D7  push 0x0000
	ld	c, (xix+5)                              ; FA74DA  ld C,(XIX+0x05)
	pushw	bc                                   ; FA74DD  push BC
	ld	c, (xix+4)                              ; FA74DE  ld C,(XIX+0x04)
	pushw	bc                                   ; FA74E1  push BC
	call	0xFC4D85                              ; FA74E2  call 0xfc4d85
	inc	6, xsp                                 ; FA74E6  inc 6,XSP
	pop	xix                                    ; FA74E8  pop XIX
	pop	xhl                                    ; FA74E9  pop XHL
	unlk32 xiz                                 ; FA74EA  unlk XIZ
	ret                                        ; FA74EC  ret
; --------------------------------------------------------------------------
; KeyZone_Stage_Reg0040_Stride6B -- 0xFA74ED..0xFA752E (66 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFA8229 in Voice_SelectKeyZone_Reg0040__FA821A
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0E)
; Outputs: writes 0x005A4F, 0x00D760
; Calls:   0xFC4D85 = Pack104_SetInputs_Rec0C_E08C
; Evidence: the listing below is the byte-identical round-trip of 0xFA74ED-0xFA752E
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  One of FOUR walkers that index a key-zone record array of stride 6
;          and copy record word 0 into staging word 1 (RAM 0x00D760), which
;          Dev10C_WriteAllChanRegs sends to 0x0010C000 register `chan + 0x0040`.  It also
;          stores the record cursor in voice[+0x0F], ORs 0x4000 into voice[+0x01], and hands
;          three record bytes to Pack104_SetInputs_Rec0C_E08C for the 0x00104000 side.
; Evidence: the stride is the `ld C,imm8` at offset +9 of the body; the mask is the
;          `or (XHL+0x01),imm16` at +0x1D; the store is `ld (0x00D760),BC`.
;          ⚠ THE FOUR ARE NOT COPIES OF ONE ANOTHER -- pairwise, 18 to 38 of the bytes they
;          share differ.  Both the strides and the difference counts are asserted by
;          notes/prom_c_dev10c_meaning_checks.py section 11.
; Unknown:  what the records are.  Only their word 0 reaches this device.
; --------------------------------------------------------------------------
KeyZone_Stage_Reg0040_Stride6B:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA74ED  link XIZ,0x0000
	push	xhl                                   ; FA74F1  push XHL
	push	xix                                   ; FA74F2  push XIX
	ld	hl, (xiz+8)                             ; FA74F3  ld HL,(XIZ+0x08)
	ldb	c, 6                                   ; FA74F6  ld C,0x06
	extpfx3 0x8E, 0x0E, 0x43                   ; FA74F8  mul BC,(XIZ+0x0e)
	extz	xbc                                   ; FA74FB  extz XBC
	ld	xix, xbc                                ; FA74FD  ld XIX,XBC
	extpfx3 0xAE, 0x0A, 0x84                   ; FA74FF  add XIX,(XIZ+0x0a)
	extz	xhl                                   ; FA7502  extz XHL
	ld	(xhl+15), xix                           ; FA7504  ld (XHL+0x0f),XIX
	extpfx5 0x9B, 0x01, 0x3E, 0x00, 0x40       ; FA7507  or (XHL+0x01),0x4000
	ld	bc, (xix)                               ; FA750C  ld BC,(XIX)
	ld	(0xD760:24), bc                        ; FA750E  ld (0x00d760),BC
	ld	bc, (xix+4)                             ; FA7513  ld BC,(XIX+0x04)
	ld	(0x5A4F:16), bc                        ; FA7516  ld (0x5a4f),BC
	ld	bc, (xix+4)                             ; FA751A  ld BC,(XIX+0x04)
	pushw	bc                                   ; FA751D  push BC
	pushw	0                                    ; FA751E  push 0x0000
	pushw	0                                    ; FA7521  push 0x0000
	call	0xFC4D85                              ; FA7524  call 0xfc4d85
	inc	6, xsp                                 ; FA7528  inc 6,XSP
	pop	xix                                    ; FA752A  pop XIX
	pop	xhl                                    ; FA752B  pop XHL
	unlk32 xiz                                 ; FA752C  unlk XIZ
	ret                                        ; FA752E  ret
; --------------------------------------------------------------------------
; KeyZone_Stage_Reg0040_Stride4 -- 0xFA752F..0xFA756F (65 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFA822E in Voice_SelectKeyZone_Reg0040__FA822E
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0E)
; Outputs: writes 0x005A4F, 0x00D760
; Calls:   0xFC4D85 = Pack104_SetInputs_Rec0C_E08C
; Evidence: the listing below is the byte-identical round-trip of 0xFA752F-0xFA756F
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  One of FOUR walkers that index a key-zone record array of stride 4
;          and copy record word 0 into staging word 1 (RAM 0x00D760), which
;          Dev10C_WriteAllChanRegs sends to 0x0010C000 register `chan + 0x0040`.  It also
;          stores the record cursor in voice[+0x0F], ORs none into voice[+0x01], and hands
;          three record bytes to Pack104_SetInputs_Rec0C_E08C for the 0x00104000 side.
; Evidence: the stride is the `ld C,imm8` at offset +9 of the body; the mask is the
;          `or (XHL+0x01),imm16` at +0x1D; the store is `ld (0x00D760),BC`.
;          ⚠ THE FOUR ARE NOT COPIES OF ONE ANOTHER -- pairwise, 18 to 38 of the bytes they
;          share differ.  Both the strides and the difference counts are asserted by
;          notes/prom_c_dev10c_meaning_checks.py section 11.
; Unknown:  what the records are.  Only their word 0 reaches this device.
; --------------------------------------------------------------------------
KeyZone_Stage_Reg0040_Stride4:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA752F  link XIZ,0x0000
	push	xhl                                   ; FA7533  push XHL
	push	xix                                   ; FA7534  push XIX
	ld	hl, (xiz+8)                             ; FA7535  ld HL,(XIZ+0x08)
	ldb	c, 4                                   ; FA7538  ld C,0x04
	extpfx3 0x8E, 0x0E, 0x43                   ; FA753A  mul BC,(XIZ+0x0e)
	extz	xbc                                   ; FA753D  extz XBC
	ld	xix, xbc                                ; FA753F  ld XIX,XBC
	extpfx3 0xAE, 0x0A, 0x84                   ; FA7541  add XIX,(XIZ+0x0a)
	extz	xhl                                   ; FA7544  extz XHL
	ld	(xhl+15), xix                           ; FA7546  ld (XHL+0x0f),XIX
	ld	bc, (xhl+1)                             ; FA7549  ld BC,(XHL+0x01)
	ld	(xhl+1), bc                             ; FA754C  ld (XHL+0x01),BC
	ld	bc, (xix)                               ; FA754F  ld BC,(XIX)
	ld	(0xD760:24), bc                        ; FA7551  ld (0x00d760),BC
	ldw	(0x5A4F:16), 0                         ; FA7556  ld (0x5a4f),0x0000
	pushw	0                                    ; FA755C  push 0x0000
	pushw	0                                    ; FA755F  push 0x0000
	pushw	0                                    ; FA7562  push 0x0000
	call	0xFC4D85                              ; FA7565  call 0xfc4d85
	inc	6, xsp                                 ; FA7569  inc 6,XSP
	pop	xix                                    ; FA756B  pop XIX
	pop	xhl                                    ; FA756C  pop XHL
	unlk32 xiz                                 ; FA756D  unlk XIZ
	ret                                        ; FA756F  ret
; --------------------------------------------------------------------------
; Sat16_0_to_7FFF -- 0xFA7570..0xFA7597 (40 bytes)
;
; Called from: 6 site(s) outside this module:
;          0xFA8073 in Voice_ComputePitch__FA8072, 0xFA8337 in Voice_PitchAddZoneOffset_AB
;          0xFA8399 in Voice_StagePitch_Reg0400_AB__FA8398, 0xFA83BC in Voice_PitchAddZoneOffset_CD
;          0xFA841E in Voice_StagePitch_Reg0400_CD__FA841D, 0xFC3718 in sub_FC36BE
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA7570-0xFA7597
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  A SATURATION to the 15-bit range [0x0000, 0x7FFF]: if bit 15 of the
;          argument is set, the result is 0x7FFF when the argument is <= 0xC000 (an overflow
;          from below) and 0x0000 otherwise (a genuine negative); otherwise the argument
;          passes through.
; Evidence: `and BC,0x8000` (0xFA757D), `cp HL,0xC000` (0xFA7583), `ld DE,0x0000` (0xFA7589),
;          `ld DE,0x7FFF` (0xFA758E).  notes/prom_c_dev10c_meaning_checks.py section 9.
;          The name is arithmetic and claims nothing about the callers -- but note that five
;          of its six call sites are the pitch chain, where 0x7FFF/256 = note 127.996.
; --------------------------------------------------------------------------
Sat16_0_to_7FFF:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA7570  link XIZ,0x0000
	pushw	hl                                   ; FA7574  push HL
	pushw	de                                   ; FA7575  push DE
	ld	de, (xiz+8)                             ; FA7576  ld DE,(XIZ+0x08)
	ld	hl, de                                  ; FA7579  ld HL,DE
	ld	bc, de                                  ; FA757B  ld BC,DE
	and	bc, 0x8000                             ; FA757D  and BC,0x8000
	jr z, Sat16_0_to_7FFF__FA7591                   ; FA7581  jr Z,0xfa7591
	cp	hl, 0xC000                              ; FA7583  cp HL,0xc000
	jr ule, Sat16_0_to_7FFF__FA758E                 ; FA7587  jr ULE,0xfa758e
	ldw	de, 0                                  ; FA7589  ld DE,0x0000
	jr Sat16_0_to_7FFF__FA7591                      ; FA758C  jr T,0xfa7591
Sat16_0_to_7FFF__FA758E:
	ldw	de, 0x7FFF                             ; FA758E  ld DE,0x7fff
Sat16_0_to_7FFF__FA7591:
	ld	wa, de                                  ; FA7591  ld WA,DE
	popw	de                                    ; FA7593  pop DE
	popw	hl                                    ; FA7594  pop HL
	unlk32 xiz                                 ; FA7595  unlk XIZ
	ret                                        ; FA7597  ret
; --------------------------------------------------------------------------
; Clamp_ToRange_Word -- 0xFA7598..0xFA75B9 (34 bytes)
;
; Called from: 60 site(s) outside this module:
;          0xFA85A4 in Voice_StageRegs_0900_0940_0980_AB__FA859D, 0xFA85F7 in Voice_StageRegs_0900_0940_0980_AB__FA859D
;          0xFA8615 in Voice_StageRegs_0900_0940_0980_AB__FA860E, 0xFA8623 in Voice_StageRegs_0900_0940_0980_AB__FA8623
;          0xFA94BA in Voice_StageRegs_09C0_0A00_0A40_AB__FA94B3, 0xFA94DA in Voice_StageRegs_09C0_0A00_0A40_AB__FA94B3
;          0xFA952A in Voice_StageRegs_09C0_0A00_0A40_AB__FA94B3, 0xFA9548 in Voice_StageRegs_09C0_0A00_0A40_AB__FA9541
;          0xFA9556 in Voice_StageRegs_09C0_0A00_0A40_AB__FA9556, 0xFA9573 in Voice_StageRegs_09C0_0A00_0A40_AB__FA9556
;          0xFA9596 in Voice_StageRegs_09C0_0A00_0A40_AB__FA9556, 0xFA9604 in Voice_StageRegs_0500_08C0_AB
;          0xFA969D in Voice_StageRegs_0500_08C0_AB__FA9676, 0xFAA552 in Voice_StageRegs_0800_A__FAA552
;          0xFAA60B in Voice_StageRegs_0800_A__FAA60B, 0xFAA697 in Voice_StageRegs_0800_A__FAA624
;          0xFAA6C5 in Voice_StageRegs_0800_A__FAA6C0, 0xFAA6EC in Voice_StageRegs_0800_A__FAA6EC
;          0xFAA794 in Voice_StageRegs_0800_A__FAA706, 0xFAA7B8 in Voice_StageRegs_0800_A__FAA7AD
;          0xFAA7F8 in Voice_StageRegs_0800_A__FAA7CC, 0xFAA80C in Voice_StageRegs_0800_A__FAA80C
;          0xFAA8FC in Voice_StageRegs_0840_0880_AB__FAA8F5, 0xFAA908 in Voice_StageRegs_0840_0880_AB__FAA8F5
;          0xFAA9D0 in Voice_StageRegs_0800_CD__FAA9D0, 0xFAAA1D in Voice_StageRegs_0800_CD__FAA9E3
;          0xFAAA7F in Voice_StageRegs_0800_CD__FAAA26, 0xFAAAAD in Voice_StageRegs_0800_CD__FAAAA8
;          0xFAAAD4 in Voice_StageRegs_0800_CD__FAAAD4, 0xFAAB41 in Voice_StageRegs_0800_CD__FAAAEE
;          0xFAAB51 in Voice_StageRegs_0800_CD__FAAAEE, 0xFAAC7E in Voice_StageRegs_0840_0880_CD__FAAC77
;          0xFAAC8A in Voice_StageRegs_0840_0880_CD__FAAC77, 0xFAAD9A in Voice_StageRegs_0800_B_ModeLt3__FAAD9A
;          0xFAAE45 in Voice_StageRegs_0800_B_ModeLt3__FAAE45, 0xFAAED6 in Voice_StageRegs_0800_B_ModeLt3__FAAE63
;          0xFAAF04 in Voice_StageRegs_0800_B_ModeLt3__FAAEFF, 0xFAAF2B in Voice_StageRegs_0800_B_ModeLt3__FAAF2B
;          0xFAAFD3 in Voice_StageRegs_0800_B_ModeLt3__FAAF45, 0xFAAFF7 in Voice_StageRegs_0800_B_ModeLt3__FAAFEC
;          0xFAB037 in Voice_StageRegs_0800_B_ModeLt3__FAB00B, 0xFAB04B in Voice_StageRegs_0800_B_ModeLt3__FAB04B
;          0xFAB137 in Voice_StageRegs_0800_B_ModeGe3__FAB137, 0xFAB1F0 in Voice_StageRegs_0800_B_ModeGe3__FAB1F0
;          0xFAB263 in Voice_StageRegs_0800_B_ModeGe3__FAB20E, 0xFAB287 in Voice_StageRegs_0800_B_ModeGe3__FAB20E
;          0xFAB2C8 in Voice_StageRegs_0800_B_ModeGe3__FAB20E, 0xFAB2EE in Voice_StageRegs_0800_B_ModeGe3__FAB2E9
;          0xFAB30B in Voice_StageRegs_0800_B_ModeGe3__FAB30B, 0xFAB3A0 in Voice_StageRegs_0800_B_ModeGe3__FAB312
;          0xFAB3C4 in Voice_StageRegs_0800_B_ModeGe3__FAB3B9, 0xFAB404 in Voice_StageRegs_0800_B_ModeGe3__FAB3D8
;          0xFAB418 in Voice_StageRegs_0800_B_ModeGe3__FAB418, 0xFAB91B in Dev10C_StageRegs_0800_0840_FAB8CC__FAB91B
;          0xFAB9B5 in Dev10C_StageRegs_0800_0840_FAB8CC__FAB987, 0xFABA42 in Dev10C_StageRegs_0800_0840_FAB9D8__FABA42
;          0xFABAC0 in Dev10C_StageRegs_0800_0840_FAB9D8__FABA92, 0xFABBB6 in Dev10C_StageRegs_0900_0940__FABBAF
;          0xFABCB2 in Dev10C_StageRegs_09C0_0A00__FABCAB, 0xFABCD1 in Dev10C_StageRegs_09C0_0A00__FABCB9
; Inputs:  (XIZ+0x08) = the value, (XIZ+0x0A) = the HIGH bound, (XIZ+0x0C) = the LOW
;          bound -- so a caller pushes low, high, value, in that order.
; Outputs: WA = min(max(value, low), high).  SIGNED: the two compares are `jr LE`
;          and `jr GE`.  No absolute-addressed write.
; Evidence: ★ NAMED round 2, 2026-08-25.  The whole routine is
;          `cp HL,(XIZ+0x0A) / jr LE` at 0xFA75A0 -- return the high bound if the
;          value exceeds it -- then `cp HL,(XIZ+0x0C) / jr GE` at 0xFA75AA -- return
;          the low bound if it is below -- and otherwise `ld WA,HL` at 0xFA75B4.
;          It is the sibling of Clamp_ToRange_LowByte (0xFA7EE2) and Clamp_0_to_00FF
;          (0xFA7D49), which have the same shape.
;          The bound pairs its callers use are read straight off the pushes and are
;          part of what names the registers they feed: (0x0000, 0x00FF) for a
;          magnitude, (0x0004, 0x007F) and (0x0000, 0x007F) for a 7-bit field, and
;          (0xFFCE, 0x0032) -- i.e. -50..+50 -- for the values that then go through
;          DetuneCurve_LookupSigned.  See the 0x0800..0x0A40 block comment in front
;          of Dev10C_WriteAllChanRegs.
; Unknown:  nothing about this routine; what its CALLERS are clamping is the open
;          question and is answered per-register elsewhere.
; --------------------------------------------------------------------------
Clamp_ToRange_Word:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA7598  link XIZ,0x0000
	pushw	hl                                   ; FA759C  push HL
	ld	hl, (xiz+8)                             ; FA759D  ld HL,(XIZ+0x08)
	extpfx3 0x9E, 0x0A, 0xF3                   ; FA75A0  cp HL,(XIZ+0x0a)
	jr le, Clamp_ToRange_Word__FA75AA                  ; FA75A3  jr LE,0xfa75aa
	ld	wa, (xiz+10)                            ; FA75A5  ld WA,(XIZ+0x0a)
	jr Clamp_ToRange_Word__FA75B6                      ; FA75A8  jr T,0xfa75b6
Clamp_ToRange_Word__FA75AA:
	extpfx3 0x9E, 0x0C, 0xF3                   ; FA75AA  cp HL,(XIZ+0x0c)
	jr ge, Clamp_ToRange_Word__FA75B4                  ; FA75AD  jr GE,0xfa75b4
	ld	wa, (xiz+12)                            ; FA75AF  ld WA,(XIZ+0x0c)
	jr Clamp_ToRange_Word__FA75B6                      ; FA75B2  jr T,0xfa75b6
Clamp_ToRange_Word__FA75B4:
	ld	wa, hl                                  ; FA75B4  ld WA,HL
Clamp_ToRange_Word__FA75B6:
	popw	hl                                    ; FA75B6  pop HL
	unlk32 xiz                                 ; FA75B7  unlk XIZ
	ret                                        ; FA75B9  ret
; --------------------------------------------------------------------------
; ScaleCoeff_TimesAbsDepth_Shr -- 0xFA75BA..0xFA7601 (72 bytes)
;
; Called from: 20 site(s) outside this module:
;          0xFA84BE in Voice_StageRegs_0900_0940_0980_AB__FA84A3, 0xFA93D4 in Voice_StageRegs_09C0_0A00_0A40_AB
;          0xFA95F4 in Voice_StageRegs_0500_08C0_AB, 0xFA968E in Voice_StageRegs_0500_08C0_AB__FA9676
;          0xFAA5BD in Voice_StageRegs_0800_A__FAA565, 0xFAA5FB in Voice_StageRegs_0800_A__FAA5E1
;          0xFAA781 in Voice_StageRegs_0800_A__FAA706, 0xFAA7EA in Voice_StageRegs_0800_A__FAA7CC
;          0xFAAA0F in Voice_StageRegs_0800_CD__FAA9E3, 0xFAAB33 in Voice_StageRegs_0800_CD__FAAAEE
;          0xFAADF7 in Voice_StageRegs_0800_B_ModeLt3__FAAD9A, 0xFAAE35 in Voice_StageRegs_0800_B_ModeLt3__FAAE1B
;          0xFAAFC0 in Voice_StageRegs_0800_B_ModeLt3__FAAF45, 0xFAB029 in Voice_StageRegs_0800_B_ModeLt3__FAB00B
;          0xFAB1A2 in Voice_StageRegs_0800_B_ModeGe3__FAB14A, 0xFAB1E0 in Voice_StageRegs_0800_B_ModeGe3__FAB1C6
;          0xFAB38D in Voice_StageRegs_0800_B_ModeGe3__FAB312, 0xFAB3F6 in Voice_StageRegs_0800_B_ModeGe3__FAB3D8
;          0xFABBA8 in Dev10C_StageRegs_0900_0940__FABB98, 0xFABCA4 in Dev10C_StageRegs_09C0_0A00__FABC94
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Calls:   0xFCAA2F = Shift16_ArithRight
; Evidence: the listing below is the byte-identical round-trip of 0xFA75BA-0xFA7601
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ WHAT IT COMPUTES.  The body is thirty instructions and there is nothing else in it:
;     0xFA75BF  ld L,(XIZ+0x08)          the DEPTH, tested as a signed byte
;     0xFA75C2  ld H,(XIZ+0x0a)          the POSITION
;     0xFA75C5  res 0x07,H               ...taken modulo 0x80
;     0xFA75C8  cp L,0 / jr GE           if the depth is negative:
;     0xFA75D2  add XBC,0x00FDD5AB         H = Voice_DepthMirror_Table[H], i.e. 0x7F - H
;     0xFA75DC  cpl A / inc 1,A            L = -L
;     0xFA75EA  add XBC,0x00FDD62B       A = PitchBend_ScaleCoeff_Table[H]
;     0xFA75F2  muls WA,L                SIGNED 8x8 -> 16: coeff * |depth|
;     0xFA75FA  call Shift16_ArithRight(product, (XIZ+0x0c))
;   The depth's SIGN is therefore not carried into the product -- it chooses which end of
;   the coefficient curve is read.
; ★ THE RESULT IS <= 0 FOR EVERY INPUT EXCEPT ONE.  All 128 entries of
;   PitchBend_ScaleCoeff_Table are in [-64, -1] as signed bytes, so the product is normally
;   <= 0 and so is the shifted result.  ⚠ CORRECTED: this line used to read "THE RESULT IS
;   NEVER POSITIVE", which contradicted the 0x80 paragraph FOUR LINES BELOW in this same
;   header -- depth byte 0x80 negates to itself, the product changes sign, and an exhaustive
;   sweep reaches +1. The clamp exists for exactly that case, which is why the header
;   describing the clamp and the header denying the case could both be here at once. That is
;   why Voice_StageRegs_0500_08C0_AB adds 0x7F: with a count of 6 the value lands in
;   [-127, 0], 0x7F + it lands in [0, 0x7F] -- exactly the 7-bit low byte of register
;   0x0500 + chan -- and the caller's Clamp_ToRange_Word(x, 0, 0x7F) does nothing at all.
; Called with count 4 at 18 of the 20 sites and with count 6 at 2 (both inside
;   Voice_StageRegs_0500_08C0_AB).
; Evidence: `python3 notes/prom_c_naming_round3.py --scale` evaluates the datapath
;          EXHAUSTIVELY -- all 256 depth bytes against all 128 positions, against the two
;          ROM tables read at their `add XBC,imm32` operands -- and reports that the clamp
;          changes its argument for exactly ONE depth byte, 0x80, at 127 of the 128
;          positions.  0x80 is the one value whose two's-complement negation at
;          0xFA75DC-0xFA75E2 overflows back to itself, so the product changes sign; the
;          clamp exists for that case and no other.  `--claims C6` re-derives the 20/18/2
;          call-site split and checks the total against an independent grep.
; Unknown:  ⚠ what the two arguments MEAN.  "depth" and "position" are the roles the
;          arithmetic gives them, not decoded quantities, and the two table names come
;          from the KN5000 sibling (see each table's own header) rather than from here.
;          ⚠ with the count of 4 that 18 callers pass, the result spans [-508, 0], which
;          does NOT fit a 7-bit field.  Nothing was traced about what those callers do
;          with it.
; --------------------------------------------------------------------------
ScaleCoeff_TimesAbsDepth_Shr:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA75BA  link XIZ,0x0000
	pushw	hl                                   ; FA75BE  push HL
	ld	l, (xiz+8)                              ; FA75BF  ld L,(XIZ+0x08)
	ld	h, (xiz+10)                             ; FA75C2  ld H,(XIZ+0x0a)
	res	7, h                                   ; FA75C5  res 0x07,H
	cps	l, 0                                   ; FA75C8  cp L,0
	jr ge, ScaleCoeff_TimesAbsDepth_Shr__FA75E4                  ; FA75CA  jr GE,0xfa75e4
	ld	c, h                                    ; FA75CC  ld C,H
	extz	bc                                    ; FA75CE  extz BC
	extz	xbc                                   ; FA75D0  extz XBC
	add	xbc, 0xFDD5AB                          ; FA75D2  add XBC,0x00fdd5ab
	ld	h, (xbc)                                ; FA75D8  ld H,(XBC)
	ld	a, l                                    ; FA75DA  ld A,L
	cpl	a                                      ; FA75DC  cpl A
	ld	l, a                                    ; FA75DE  ld L,A
	inc	1, a                                   ; FA75E0  inc 1,A
	ld	l, a                                    ; FA75E2  ld L,A
ScaleCoeff_TimesAbsDepth_Shr__FA75E4:
	ld	c, h                                    ; FA75E4  ld C,H
	extz	bc                                    ; FA75E6  extz BC
	extz	xbc                                   ; FA75E8  extz XBC
	add	xbc, 0xFDD62B                          ; FA75EA  add XBC,0x00fdd62b
	ld	a, (xbc)                                ; FA75F0  ld A,(XBC)
	muls8rr	a, l                               ; FA75F2  muls WA,L
	push	0                                     ; FA75F4  push 0x00
	extpfx3 0x8E, 0x0C, 0x04                   ; FA75F6  push (XIZ+0x0c)
	pushw	wa                                   ; FA75F9  push WA
	call	0xFCAA2F                              ; FA75FA  call 0xfcaa2f
	popw	hl                                    ; FA75FE  pop HL
	unlk32 xiz                                 ; FA75FF  unlk XIZ
	ret                                        ; FA7601  ret
; --------------------------------------------------------------------------
; DetuneCurve_LookupSigned -- 0xFA7602..0xFA7653 (82 bytes)
;
; Called from: 10 site(s) outside this module:
;          0xFA85AD in Voice_StageRegs_0900_0940_0980_AB__FA859D, 0xFA862B in Voice_StageRegs_0900_0940_0980_AB__FA8623
;          0xFA8633 in Voice_StageRegs_0900_0940_0980_AB__FA8623, 0xFA94DE in Voice_StageRegs_09C0_0A00_0A40_AB__FA94B3
;          0xFA9577 in Voice_StageRegs_09C0_0A00_0A40_AB__FA9556, 0xFA959A in Voice_StageRegs_09C0_0A00_0A40_AB__FA9556
;          0xFA961F in Voice_StageRegs_0500_08C0_AB, 0xFA9676 in Voice_StageRegs_0500_08C0_AB__FA9676
;          0xFABBD6 in Dev10C_StageRegs_0900_0940__FABBD6, 0xFABCD5 in Dev10C_StageRegs_09C0_0A00__FABCB9
; Inputs:  (XIZ+0x08) = a SIGNED value.
; Outputs: WA = `sign(v) * Detune_Scale_Curve[min(|v|, 50)]`, i.e. -127..+127.
; Evidence: ★ NAMED round 2, 2026-08-25, for the TABLE it reads and NOT for a
;          quantity.  `cp HL,0` at 0xFA760A splits the arms; the negative arm
;          two's-complements (0xFA7610/0xFA7614), clamps with `cp BC,0x0032`
;          (0xFA7618), indexes with `add XBC,0x00fdf123` (0xFA7627) and negates the
;          result (0xFA7631/0xFA7633); the positive arm is the same without the two
;          negations (0xFA7637, 0xFA7646).  Detune_Scale_Curve is 51 bytes rising
;          0x00..0x7F with knees at [16] and [32] and T[50] = 0x7F, so the law is
;          "a +/-50 control expanded to a +/-127 field, coarsening as it goes".
;          ⚠ THE TABLE'S NAME IS TRANSPLANTED from the KN5000 sub-CPU (the 51 bytes
;          are byte-identical, v142/subcpu/subcpu_data_tables.s:1889) and it may
;          MISLEAD here: in this image the only callers are the level/parameter
;          packers for 0x0010C000 registers 0x0900-0x0A40 and 0x08C0, not a pitch
;          path -- and the KN5000's own header says its `Detune_ScaleSymmetric` is
;          "called from the level packer" too.  The KN5000 routine is NOT
;          byte-identical to this one: it takes WA and returns XHL with no stack
;          frame, where this one is a framed stack-argument routine.  The ALGORITHM
;          matches instruction for instruction; the encoding does not.
; Unknown:  what the +/-50 control IS, at any of the ten call sites.
; --------------------------------------------------------------------------
DetuneCurve_LookupSigned:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA7602  link XIZ,0x0000
	pushw	hl                                   ; FA7606  push HL
	ld	hl, (xiz+8)                             ; FA7607  ld HL,(XIZ+0x08)
	cps	hl, 0                                  ; FA760A  cp HL,0
	jr ge, DetuneCurve_LookupSigned__FA7637                  ; FA760C  jr GE,0xfa7637
	ld	bc, hl                                  ; FA760E  ld BC,HL
	cpl	bc                                     ; FA7610  cpl BC
	ld	hl, bc                                  ; FA7612  ld HL,BC
	inc	1, bc                                  ; FA7614  inc 1,BC
	ld	hl, bc                                  ; FA7616  ld HL,BC
	cp	bc, 50                                  ; FA7618  cp BC,0x0032
	jr le, DetuneCurve_LookupSigned__FA7621                  ; FA761C  jr LE,0xfa7621
	ldw	hl, 50                                 ; FA761E  ld HL,0x0032
DetuneCurve_LookupSigned__FA7621:
	ld	c, l                                    ; FA7621  ld C,L
	extz	bc                                    ; FA7623  extz BC
	extz	xbc                                   ; FA7625  extz XBC
	add	xbc, 0xFDF123                          ; FA7627  add XBC,0x00fdf123
	ld	a, (xbc)                                ; FA762D  ld A,(XBC)
	extz	wa                                    ; FA762F  extz WA
	cpl	wa                                     ; FA7631  cpl WA
	inc	1, wa                                  ; FA7633  inc 1,WA
	jr DetuneCurve_LookupSigned__FA7650                      ; FA7635  jr T,0xfa7650
DetuneCurve_LookupSigned__FA7637:
	cp	hl, 50                                  ; FA7637  cp HL,0x0032
	jr le, DetuneCurve_LookupSigned__FA7640                  ; FA763B  jr LE,0xfa7640
	ldw	hl, 50                                 ; FA763D  ld HL,0x0032
DetuneCurve_LookupSigned__FA7640:
	ld	c, l                                    ; FA7640  ld C,L
	extz	bc                                    ; FA7642  extz BC
	extz	xbc                                   ; FA7644  extz XBC
	add	xbc, 0xFDF123                          ; FA7646  add XBC,0x00fdf123
	ld	a, (xbc)                                ; FA764C  ld A,(XBC)
	extz	wa                                    ; FA764E  extz WA
DetuneCurve_LookupSigned__FA7650:
	popw	hl                                    ; FA7650  pop HL
	unlk32 xiz                                 ; FA7651  unlk XIZ
	ret                                        ; FA7653  ret
; --------------------------------------------------------------------------
; DetuneCurve_LookupUnsigned -- 0xFA7654..0xFA766B (24 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFA9651 in Voice_StageRegs_0500_08C0_AB, 0xFA9667 in Voice_StageRegs_0500_08C0_AB__FA9666
; Inputs:  (XIZ+0x08) = an index.
; Outputs: WA = `Detune_Scale_Curve[index]`, with NO clamp and NO sign handling.
; Evidence: ★ NAMED round 2, 2026-08-25.  The whole routine is
;          `add XBC,0x00fdf123` at 0xFA765F and the byte load after it; the
;          signed variant is DetuneCurve_LookupSigned above.  Same caveat about the
;          table's transplanted name.
; Unknown:  ⚠ the index is NOT bounded here, and the table is only 51 bytes.  Both
;          call sites are in Voice_StageRegs_0500_08C0_AB and neither was traced to its source.
; --------------------------------------------------------------------------
DetuneCurve_LookupUnsigned:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA7654  link XIZ,0x0000
	ld	c, (xiz+8)                              ; FA7658  ld C,(XIZ+0x08)
	extz	bc                                    ; FA765B  extz BC
	extz	xbc                                   ; FA765D  extz XBC
	add	xbc, 0xFDF123                          ; FA765F  add XBC,0x00fdf123
	ld	a, (xbc)                                ; FA7665  ld A,(XBC)
	extz	wa                                    ; FA7667  extz WA
	unlk32 xiz                                 ; FA7669  unlk XIZ
	ret                                        ; FA766B  ret
; --------------------------------------------------------------------------
; ScaleClampedDelta_Shr5 -- 0xFA766C..0xFA76B1 (70 bytes)
;             take bits 14..8 of a packed word, clamp them to a caller's range, subtract
;             a base and scale by a signed factor with an arithmetic shift right of 5.
;             (★ NAMED in wave 7 round 2; was `sub_FA766C`.)
;
; Called from: 14 site(s) outside this module:
;          0xFA8594 in Voice_StageRegs_0900_0940_0980_AB__FA8570, 0xFA85E8 in Voice_StageRegs_0900_0940_0980_AB__FA859D
;          0xFA94AA in Voice_StageRegs_09C0_0A00_0A40_AB__FA9486, 0xFA951B in Voice_StageRegs_09C0_0A00_0A40_AB__FA94B3
;          0xFAA59A in Voice_StageRegs_0800_A__FAA565, 0xFAA75A in Voice_StageRegs_0800_A__FAA706
;          0xFAADD4 in Voice_StageRegs_0800_B_ModeLt3__FAAD9A, 0xFAAF99 in Voice_StageRegs_0800_B_ModeLt3__FAAF45
;          0xFAB17F in Voice_StageRegs_0800_B_ModeGe3__FAB14A, 0xFAB366 in Voice_StageRegs_0800_B_ModeGe3__FAB312
;          0xFAB9A7 in Dev10C_StageRegs_0800_0840_FAB8CC__FAB987, 0xFABAB2 in Dev10C_StageRegs_0800_0840_FAB9D8__FABA92
;          0xFABB7F in Dev10C_StageRegs_0900_0940__FABB61, 0xFABC75 in Dev10C_StageRegs_09C0_0A00__FABC57
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x0E), (XIZ+0x10)
; Outputs: no absolute-addressed write.
; Evidence: ★ five steps, each an instruction or a pair:
;              0xFA7675  and DE,0x7F00 / srl 0x08,BC     
;                        -- v = (arg0 >> 8) & 0x7F, so 0..127
;              0xFA7685  cp BC,(XIZ+0x0e) / jr ULE       
;                        -- v > (XIZ+0x0E) ?  v = (XIZ+0x0E)
;              0xFA7692  cp DE,(XIZ+0x0c) / jr NC        
;                        -- v < (XIZ+0x0C) ?  v = (XIZ+0x0C)
;              0xFA769D  ld HL,DE / sub HL,BC             -- minus the base at (XIZ+0x0A)
;              0xFA76A4  exts BC / muls XBC,HL / sra 0x05,BC / ld WA,BC  
;                        -- * (XIZ+0x10) >> 5
;          The comparisons are the UNSIGNED conditions (`jr ULE`, `jr NC`) while the
;          multiply is `muls` on an `exts`-ed factor, so the value is unsigned and the
;          factor is signed; both are opcodes.  The bit field is `0x7F00` and the shift
;          `0x08`, so the payload really is bits 14..8 and not a whole byte at bits
;          15..8.
;          Fourteen call sites, all outside this module, and four of them are the
;          staging producers named in this round: Dev10C_StageRegs_0800_0840_FAB8CC
;          (0xFAB9A7), _FAB9D8 (0xFABAB2), Dev10C_StageRegs_0900_0940 (0xFABB7F) and
;          Dev10C_StageRegs_09C0_0A00 (0xFABC75).
; Unknown:  ⚠ what the packed word at (XIZ+0x08) is, and therefore what bits 14..8 hold.
;          A key-number or controller reading is PLAUSIBLE from the 0..127 range and is
;          NOT asserted; nothing traced here reads the field's meaning.
;          ⚠ the units of the >> 5.  It is the scale that makes the product fit, and no
;          consumer was followed far enough to say what the result measures.
; --------------------------------------------------------------------------
ScaleClampedDelta_Shr5:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA766C  link XIZ,0x0000
	pushw	hl                                   ; FA7670  push HL
	pushw	de                                   ; FA7671  push DE
	ld	de, (xiz+8)                             ; FA7672  ld DE,(XIZ+0x08)
	and	de, 0x7F00                             ; FA7675  and DE,0x7f00
	ld	bc, de                                  ; FA7679  ld BC,DE
	srl	bc, 8                                  ; FA767B  srl 0x08,BC
	ld	de, bc                                  ; FA767E  ld DE,BC
	ld	hl, (xiz+14)                            ; FA7680  ld HL,(XIZ+0x0e)
	extz	hl                                    ; FA7683  extz HL
	cp	bc, hl                                  ; FA7685  cp BC,HL
	jr ule, ScaleClampedDelta_Shr5__FA768D                 ; FA7687  jr ULE,0xfa768d
	ld	de, hl                                  ; FA7689  ld DE,HL
	jr ScaleClampedDelta_Shr5__FA7698                      ; FA768B  jr T,0xfa7698
ScaleClampedDelta_Shr5__FA768D:
	ld	hl, (xiz+12)                            ; FA768D  ld HL,(XIZ+0x0c)
	extz	hl                                    ; FA7690  extz HL
	cp	de, hl                                  ; FA7692  cp DE,HL
	jr nc, ScaleClampedDelta_Shr5__FA7698                  ; FA7694  jr NC,0xfa7698
	ld	de, hl                                  ; FA7696  ld DE,HL
ScaleClampedDelta_Shr5__FA7698:
	ld	bc, (xiz+10)                            ; FA7698  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FA769B  extz BC
	ld	hl, de                                  ; FA769D  ld HL,DE
	sub	hl, bc                                 ; FA769F  sub HL,BC
	ld	bc, (xiz+16)                            ; FA76A1  ld BC,(XIZ+0x10)
	exts	bc                                    ; FA76A4  exts BC
	muls	xbc, xhl                              ; FA76A6  muls XBC,HL
	sra	bc, 5                                  ; FA76A8  sra 0x05,BC
	ld	wa, bc                                  ; FA76AB  ld WA,BC
	popw	de                                    ; FA76AD  pop DE
	popw	hl                                    ; FA76AE  pop HL
	unlk32 xiz                                 ; FA76AF  unlk XIZ
	ret                                        ; FA76B1  ret
; --------------------------------------------------------------------------
; Clamp_36_to_120 -- 0xFA76B2..0xFA76D5 (36 bytes)
;
; Called from: 6 site(s) outside this module:
;          0xFA90D9 in Voice_StagePair_Reg0100_0140_First__FA90D8, 0xFA915E in Voice_StagePair_Reg0100_0140_Both__FA915D
;          0xFA9261 in Voice_StagePair_Reg0100_0140_AB__FA9260, 0xFA9277 in Voice_StagePair_Reg0100_0140_AB__FA9260
;          0xFA936B in Voice_StagePair_Reg0100_0140_CD__FA936A, 0xFA9381 in Voice_StagePair_Reg0100_0140_CD__FA936A
;          2 site(s) inside this module:
;          0xFA7784 0xFA77E9
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA76B2-0xFA76D5
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ WHAT IT DOES: clamps a signed word to [36, 120] = [0x24, 0x78] and returns it in WA.
;          `cp HL,0x0078 / jr LE` (0xFA76BA) and `cp HL,0x0024 / jr GE` (0xFA76C5) are the
;          only two comparisons in the routine and both bounds are IMMEDIATES, so the name
;          states measured numbers, not a role.
; Called by: eight sites, and ALL EIGHT ARE ON THE PATH TO REGISTERS 0x0100/0x0140 --
;          the four staging routines Voice_StagePair_Reg0100_0140_{First,Both,AB,CD}
;          (0xFA90D9, 0xFA915E, 0xFA9261, 0xFA9277, 0xFA936B, 0xFA9381) and the two
;          routines that build the voice words those stagers copy, VoiceParam_AddCurveAndKeyDepth_Clamp (0xFA7784)
;          and VoiceParam_AddCurveDepth_Clamp (0xFA77E9).  No other caller exists in either image.
; ⚠ SIBLING, NOT A TRANSPLANT.  The KN5000 sub-CPU has a structurally identical routine
;          its project calls `TVF_Clamp_Cutoff` (0x022BF2), clamping to [0, 120] -- SAME
;          upper immediate 0x78, DIFFERENT floor -- and it is called from that image's
;          emitters of the same two registers.  THE BYTES ARE NOT THE SAME: over the 20
;          bytes the two routines share, 19 differ (this one takes its argument in a
;          `link XIZ` frame, the sibling in WA).  The name here therefore states the
;          BOUNDS this image contains; the word "cutoff" is the sibling's and lives in
;          notes/FINDINGS-prom_c-dev10c-sibling-register-map.md with its caveat.
; Unknown:  what the clamped quantity IS.  Nothing in this image names it.
; --------------------------------------------------------------------------
Clamp_36_to_120:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA76B2  link XIZ,0x0000
	pushw	hl                                   ; FA76B6  push HL
	ld	hl, (xiz+8)                             ; FA76B7  ld HL,(XIZ+0x08)
	cp	hl, 0x78                                ; FA76BA  cp HL,0x0078
	jr le, Clamp_36_to_120__FA76C5                  ; FA76BE  jr LE,0xfa76c5
	ldw	wa, 0x78                               ; FA76C0  ld WA,0x0078
	jr Clamp_36_to_120__FA76D2                      ; FA76C3  jr T,0xfa76d2
Clamp_36_to_120__FA76C5:
	cp	hl, 36                                  ; FA76C5  cp HL,0x0024
	jr ge, Clamp_36_to_120__FA76D0                  ; FA76C9  jr GE,0xfa76d0
	ldw	wa, 36                                 ; FA76CB  ld WA,0x0024
	jr Clamp_36_to_120__FA76D2                      ; FA76CE  jr T,0xfa76d2
Clamp_36_to_120__FA76D0:
	ld	wa, hl                                  ; FA76D0  ld WA,HL
Clamp_36_to_120__FA76D2:
	popw	hl                                    ; FA76D2  pop HL
	unlk32 xiz                                 ; FA76D3  unlk XIZ
	ret                                        ; FA76D5  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `VoiceParam_AddCurveAndKeyDepth_Clamp` is now `VoiceParam_AddCurveAndKeyDepth_Clamp`.
;   GRADE STRONG.  WHY `VoiceParam_AddCurveAndKeyDepth_Clamp`:
;   body: base + (Table_FDEBF4[bank*0x80 + voice[+0x0C] & 0x7F] * depth1) >> 5
;   + ((voice[+0x08]>>8 clamped to tone[+0x3A]..tone[+0x3B]) - tone[+0x39])
;   * depth2 >> 5, then + 0x18 and Clamp_36_to_120.  All seven callers are the
;   five VoiceParam_Build0100_0140_On36_Arm* routines, and Clamp_36_to_120's own
;   header records that every one of ITS callers is on the path to registers
;   0x0100/0x0140.
; VoiceParam_AddCurveAndKeyDepth_Clamp -- 0xFA76D6..0xFA778D (184 bytes)
;
; Called from: 7 site(s) outside this module:
;          0xFA86A4 in VoiceParam_Build0100_0140_On36_Arm1, 0xFA8804 in sub_FA8759__FA87C5
;          0xFA8847 in sub_FA8759__FA882D, 0xFA892E in sub_FA888C__FA88F7
;          0xFA89E5 in sub_FA8997__FA89D7, 0xFA8ADB in sub_FA8A79__FA8ACB
;          0xFA8AF1 in sub_FA8A79__FA8ACB
; Inputs:  frame `link XIZ,-8`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x0E)
; Outputs: no absolute-addressed write.
; Calls:   0xFA76B2 = Clamp_36_to_120
; Evidence: the listing below is the byte-identical round-trip of 0xFA76D6-0xFA778D
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
VoiceParam_AddCurveAndKeyDepth_Clamp:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FA76D6  link XIZ,0xfff8
	pushw	hl                                   ; FA76DA  push HL
	pushw	de                                   ; FA76DB  push DE
	pushw	ix                                   ; FA76DC  push IX
	ld	ix, (xiz+10)                            ; FA76DD  ld IX,(XIZ+0x0a)
	ld	bc, (xiz+8)                             ; FA76E0  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA76E3  extz XBC
	ld	xwa, (xbc+23)                           ; FA76E5  ld XWA,(XBC+0x17)
	ld	(xiz-4), xwa                            ; FA76E8  ld (XIZ+0xfc),XWA
	cpw (xiz+12), 0x0000                       ; FA76EB  cp (XIZ+0x0c),0x0000
	jr z, sub_FA76D6__FA772A                   ; FA76F0  jr Z,0xfa772a
	ld	c, (xwa+54)                             ; FA76F2  ld C,(XWA+0x36)
	and	c, 0xE0                                ; FA76F5  and C,0xe0
	srl	c, 5                                   ; FA76F8  srl 0x05,C
	mul	c, 0x80                                ; FA76FB  mul C,0x80
	extz	xbc                                   ; FA76FE  extz XBC
	ld	(xiz-8), xbc                            ; FA7700  ld (XIZ+0xf8),XBC
	ld	wa, (xiz+8)                             ; FA7703  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA7706  extz XWA
	ld	c, (xwa+12)                             ; FA7708  ld C,(XWA+0x0c)
	extz	bc                                    ; FA770B  extz BC
	and	bc, 0x7F                               ; FA770D  and BC,0x007f
	extz	xbc                                   ; FA7711  extz XBC
	extpfx3 0xAE, 0xF8, 0x81                   ; FA7713  add XBC,(XIZ+0xf8)
	add	xbc, 0xFDEBF4                          ; FA7716  add XBC,0x00fdebf4
	ld	b, (xbc)                                ; FA771C  ld B,(XBC)
	ld	c, b                                    ; FA771E  ld C,B
	exts	bc                                    ; FA7720  exts BC
	extpfx3 0x9E, 0x0C, 0x49                   ; FA7722  muls XBC,(XIZ+0x0c)
	sra	bc, 5                                  ; FA7725  sra 0x05,BC
	add	ix, bc                                 ; FA7728  add IX,BC
sub_FA76D6__FA772A:
	cp (xiz+14), 0x00                          ; FA772A  cp (XIZ+0x0e),0x00
	jr z, sub_FA76D6__FA777D                   ; FA772E  jr Z,0xfa777d
	ld	bc, (xiz+8)                             ; FA7730  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA7733  extz XBC
	ld	hl, (xbc+8)                             ; FA7735  ld HL,(XBC+0x08)
	and	hl, 0x7F00                             ; FA7738  and HL,0x7f00
	ld	iy, hl                                  ; FA773C  ld IY,HL
	srl	iy, 8                                  ; FA773E  srl 0x08,IY
	ld	hl, iy                                  ; FA7741  ld HL,IY
	ld	xwa, (xiz-4)                            ; FA7743  ld XWA,(XIZ+0xfc)
	ld	c, (xwa+59)                             ; FA7746  ld C,(XWA+0x3b)
	extz	bc                                    ; FA7749  extz BC
	ld	de, bc                                  ; FA774B  ld DE,BC
	cp	iy, bc                                  ; FA774D  cp IY,BC
	jr ule, sub_FA76D6__FA7755                 ; FA774F  jr ULE,0xfa7755
	ld	hl, bc                                  ; FA7751  ld HL,BC
	jr sub_FA76D6__FA7765                      ; FA7753  jr T,0xfa7765
sub_FA76D6__FA7755:
	ld	xbc, (xiz-4)                            ; FA7755  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+58)                             ; FA7758  ld A,(XBC+0x3a)
	extz	wa                                    ; FA775B  extz WA
	ld	de, wa                                  ; FA775D  ld DE,WA
	cp	hl, wa                                  ; FA775F  cp HL,WA
	jr nc, sub_FA76D6__FA7765                  ; FA7761  jr NC,0xfa7765
	ld	hl, wa                                  ; FA7763  ld HL,WA
sub_FA76D6__FA7765:
	ld	xbc, (xiz-4)                            ; FA7765  ld XBC,(XIZ+0xfc)
	ld	a, (xbc+57)                             ; FA7768  ld A,(XBC+0x39)
	extz	wa                                    ; FA776B  extz WA
	ld	de, hl                                  ; FA776D  ld DE,HL
	sub	de, wa                                 ; FA776F  sub DE,WA
	ld	wa, (xiz+14)                            ; FA7771  ld WA,(XIZ+0x0e)
	exts	wa                                    ; FA7774  exts WA
	muls	xwa, xde                              ; FA7776  muls XWA,DE
	sra	wa, 5                                  ; FA7778  sra 0x05,WA
	add	ix, wa                                 ; FA777B  add IX,WA
sub_FA76D6__FA777D:
	ld	bc, ix                                  ; FA777D  ld BC,IX
	add	bc, 24                                 ; FA777F  add BC,0x0018
	pushw	bc                                   ; FA7783  push BC
	calr (0xFA76B2 - 0xFA7787)                 ; FA7784  calr 0xfa76b2
	popw	bc                                    ; FA7787  pop BC
	popw	ix                                    ; FA7788  pop IX
	popw	de                                    ; FA7789  pop DE
	popw	hl                                    ; FA778A  pop HL
	unlk32 xiz                                 ; FA778B  unlk XIZ
	ret                                        ; FA778D  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `VoiceParam_AddCurveDepth_Clamp` is now `VoiceParam_AddCurveDepth_Clamp`.
;   GRADE STRONG.  WHY `VoiceParam_AddCurveDepth_Clamp`:
;   the same shape with the velocity term only (tone[+0x12] as the depth,
;   tone[+0x11] bits 7..5 as the curve bank), + 0x18, Clamp_36_to_120.  All six
;   callers are the five VoiceParam_Build0100_0140_On11_Arm* routines.
; VoiceParam_AddCurveDepth_Clamp -- 0xFA778E..0xFA77F2 (101 bytes)
;
; Called from: 6 site(s) outside this module:
;          0xFA8C5D in VoiceParam_Build0100_0140_On11_Arm1, 0xFA8D08 in VoiceParam_Build0100_0140_On11_Arm2
;          0xFA8DB5 in VoiceParam_Build0100_0140_On11_Arm3, 0xFA8E61 in VoiceParam_Build0100_0140_On11_Arm4
;          0xFA8F11 in VoiceParam_Build0100_0140_On11_Arm5, 0xFA8F20 in VoiceParam_Build0100_0140_On11_Arm5
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFA76B2 = Clamp_36_to_120
; Evidence: the listing below is the byte-identical round-trip of 0xFA778E-0xFA77F2
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
VoiceParam_AddCurveDepth_Clamp:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA778E  link XIZ,0x0000
	pushw	hl                                   ; FA7792  push HL
	pushw	de                                   ; FA7793  push DE
	push	xix                                   ; FA7794  push XIX
	ld	de, (xiz+10)                            ; FA7795  ld DE,(XIZ+0x0a)
	ld	bc, (xiz+8)                             ; FA7798  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA779B  extz XBC
	ld	xwa, (xbc+23)                           ; FA779D  ld XWA,(XBC+0x17)
	ld	xix, xwa                                ; FA77A0  ld XIX,XWA
	ld	c, (xwa+18)                             ; FA77A2  ld C,(XWA+0x12)
	exts	bc                                    ; FA77A5  exts BC
	ld	hl, bc                                  ; FA77A7  ld HL,BC
	cps	bc, 0                                  ; FA77A9  cp BC,0
	jr z, sub_FA778E__FA77E2                   ; FA77AB  jr Z,0xfa77e2
	ld	c, (xwa+17)                             ; FA77AD  ld C,(XWA+0x11)
	and	c, 0xE0                                ; FA77B0  and C,0xe0
	srl	c, 5                                   ; FA77B3  srl 0x05,C
	mul	c, 0x80                                ; FA77B6  mul C,0x80
	extz	xbc                                   ; FA77B9  extz XBC
	ld	xix, xbc                                ; FA77BB  ld XIX,XBC
	ld	wa, (xiz+8)                             ; FA77BD  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA77C0  extz XWA
	ld	c, (xwa+12)                             ; FA77C2  ld C,(XWA+0x0c)
	extz	bc                                    ; FA77C5  extz BC
	and	bc, 0x7F                               ; FA77C7  and BC,0x007f
	extz	xbc                                   ; FA77CB  extz XBC
	add	xbc, xix                               ; FA77CD  add XBC,XIX
	add	xbc, 0xFDEBF4                          ; FA77CF  add XBC,0x00fdebf4
	ld	b, (xbc)                                ; FA77D5  ld B,(XBC)
	ld	c, b                                    ; FA77D7  ld C,B
	exts	bc                                    ; FA77D9  exts BC
	muls	xbc, xhl                              ; FA77DB  muls XBC,HL
	sra	bc, 5                                  ; FA77DD  sra 0x05,BC
	add	de, bc                                 ; FA77E0  add DE,BC
sub_FA778E__FA77E2:
	ld	bc, de                                  ; FA77E2  ld BC,DE
	add	bc, 24                                 ; FA77E4  add BC,0x0018
	pushw	bc                                   ; FA77E8  push BC
	calr (0xFA76B2 - 0xFA77EC)                 ; FA77E9  calr 0xfa76b2
	popw	bc                                    ; FA77EC  pop BC
	pop	xix                                    ; FA77ED  pop XIX
	popw	de                                    ; FA77EE  pop DE
	popw	hl                                    ; FA77EF  pop HL
	unlk32 xiz                                 ; FA77F0  unlk XIZ
	ret                                        ; FA77F2  ret
; --------------------------------------------------------------------------
; Add24_ClampTo120 -- 0xFA77F3..0xFA780F (29 bytes)
;             (* NAMED in wave 7 round 12; was `sub_FA77F3`.)
;
; Called from: 7 site(s) outside this module:
;          0xFA8724 in sub_FA866B__FA8703, 0xFA8739 in sub_FA866B__FA8730
;          0xFA881F in sub_FA8759__FA87C5, 0xFA8868 in sub_FA8759__FA882D
;          0xFA895B in sub_FA888C__FA88F7, 0xFA8CD4 in sub_FA8C44__FA8CBB
;          0xFA8D80 in sub_FA8CEF__FA8D66
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA77F3-0xFA780F
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; * WHAT IT DOES: returns min(arg + 24, 120).
; Evidence: `add HL,0x0018` at 0xFA77FB, `cp HL,0x0078` at 0xFA77FF and
;          `jr LE,0xfa780a` at 0xFA7803 -- the LE arm keeps HL, the fall-through
;          loads the constant with `ld WA,0x0078` at 0xFA7805.  0x78 = 120, the
;          same ceiling Clamp_36_to_120 (0xFA76B2) uses.
; Unknown:  what the quantity IS.  All five callers are arms of
;          VoiceParam_DispatchOn_17_36 and VoiceParam_DispatchOn_17_11; nothing
;          here gives the value a unit, so the name states the arithmetic only.
; --------------------------------------------------------------------------
Add24_ClampTo120:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA77F3  link XIZ,0x0000
	pushw	hl                                   ; FA77F7  push HL
	ld	hl, (xiz+8)                             ; FA77F8  ld HL,(XIZ+0x08)
	add	hl, 24                                 ; FA77FB  add HL,0x0018
	cp	hl, 0x78                                ; FA77FF  cp HL,0x0078
	jr le, Add24_ClampTo120__FA780A                  ; FA7803  jr LE,0xfa780a
	ldw	wa, 0x78                               ; FA7805  ld WA,0x0078
	jr Add24_ClampTo120__FA780C                      ; FA7808  jr T,0xfa780c
Add24_ClampTo120__FA780A:
	ld	wa, hl                                  ; FA780A  ld WA,HL
Add24_ClampTo120__FA780C:
	popw	hl                                    ; FA780C  pop HL
	unlk32 xiz                                 ; FA780D  unlk XIZ
	ret                                        ; FA780F  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `VoiceParam_LoadTriple_Set5A51` is now `VoiceParam_LoadTriple_Set5A51`.
;   GRADE PROVEN.  WHY `VoiceParam_LoadTriple_Set5A51`:
;   body: reads a 3-byte record at 0xFDF180 + 3*(arg & 0x0F) when arg bit 7 is
;   set, else at 0xFDF156 + 3*(arg & 0x0F); returns (rec[1] << 8) | rec[0] and
;   stores rec[2], sign-extended, at RAM 0x005A51.  Every caller ORs the return
;   into voice_record[+0x41].
; VoiceParam_LoadTriple_Set5A51 -- 0xFA7810..0xFA78AA (155 bytes)
;
; Called from: 5 site(s) outside this module:
;          0xFA8747 in sub_FA866B__FA8747, 0xFA8878 in sub_FA8759__FA8878
;          0xFA8963 in sub_FA888C__FA88F7, 0xFA8CE0 in sub_FA8C44__FA8CBB
;          0xFA8D8C in sub_FA8CEF__FA8D66
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x005A51
; Evidence: the listing below is the byte-identical round-trip of 0xFA7810-0xFA78AA
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
VoiceParam_LoadTriple_Set5A51:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FA7810  link XIZ,0xfffc
	pushw	hl                                   ; FA7814  push HL
	pushw	de                                   ; FA7815  push DE
	push	xix                                   ; FA7816  push XIX
	ld	c, (xiz+8)                              ; FA7817  ld C,(XIZ+0x08)
	and	c, 15                                  ; FA781A  and C,0x0f
	extz	bc                                    ; FA781D  extz BC
	mul	bc, 3                                  ; FA781F  mul BC,0x0003
	ld	(xiz-4), xbc                            ; FA7823  ld (XIZ+0xfc),XBC
	ld	xix, xbc                                ; FA7826  ld XIX,XBC
	inc	1, xbc                                 ; FA7828  inc 1,XBC
	ld	xix, xbc                                ; FA782A  ld XIX,XBC
	ld	a, (xiz+8)                              ; FA782C  ld A,(XIZ+0x08)
	and	a, 0x80                                ; FA782F  and A,0x80
	jr z, sub_FA7810__FA786A                   ; FA7832  jr Z,0xfa786a
	add	xbc, 0xFDF180                          ; FA7834  add XBC,0x00fdf180
	ld	a, (xbc)                                ; FA783A  ld A,(XBC)
	extz	wa                                    ; FA783C  extz WA
	ld	hl, wa                                  ; FA783E  ld HL,WA
	sll	wa, 8                                  ; FA7840  sll 0x08,WA
	ld	hl, wa                                  ; FA7843  ld HL,WA
	lda	xbc, (0xFDF180:24)                     ; FA7845  lda XBC,0xfdf180
	extpfx3 0xAE, 0xFC, 0x81                   ; FA784A  add XBC,(XIZ+0xfc)
	ld	a, (xbc)                                ; FA784D  ld A,(XBC)
	extz	wa                                    ; FA784F  extz WA
	ld	de, wa                                  ; FA7851  ld DE,WA
	ld	xbc, (xiz-4)                            ; FA7853  ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FA7856  inc 2,XBC
	add	xbc, 0xFDF180                          ; FA7858  add XBC,0x00fdf180
	ld	b, (xbc)                                ; FA785E  ld B,(XBC)
	ld	c, b                                    ; FA7860  ld C,B
	exts	bc                                    ; FA7862  exts BC
	ld	(0x5A51:16), bc                        ; FA7864  ld (0x5a51),BC
	jr sub_FA7810__FA789F                      ; FA7868  jr T,0xfa789f
sub_FA7810__FA786A:
	lda	xbc, (0xFDF156:24)                     ; FA786A  lda XBC,0xfdf156
	add	xbc, xix                               ; FA786F  add XBC,XIX
	ld	a, (xbc)                                ; FA7871  ld A,(XBC)
	extz	wa                                    ; FA7873  extz WA
	ld	hl, wa                                  ; FA7875  ld HL,WA
	sll	wa, 8                                  ; FA7877  sll 0x08,WA
	ld	hl, wa                                  ; FA787A  ld HL,WA
	lda	xbc, (0xFDF156:24)                     ; FA787C  lda XBC,0xfdf156
	extpfx3 0xAE, 0xFC, 0x81                   ; FA7881  add XBC,(XIZ+0xfc)
	ld	a, (xbc)                                ; FA7884  ld A,(XBC)
	extz	wa                                    ; FA7886  extz WA
	ld	de, wa                                  ; FA7888  ld DE,WA
	ld	xbc, (xiz-4)                            ; FA788A  ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FA788D  inc 2,XBC
	add	xbc, 0xFDF156                          ; FA788F  add XBC,0x00fdf156
	ld	b, (xbc)                                ; FA7895  ld B,(XBC)
	ld	c, b                                    ; FA7897  ld C,B
	exts	bc                                    ; FA7899  exts BC
	ld	(0x5A51:16), bc                        ; FA789B  ld (0x5a51),BC
sub_FA7810__FA789F:
	ld	bc, de                                  ; FA789F  ld BC,DE
	or	bc, hl                                  ; FA78A1  or BC,HL
	ld	wa, bc                                  ; FA78A3  ld WA,BC
	pop	xix                                    ; FA78A5  pop XIX
	popw	de                                    ; FA78A6  pop DE
	popw	hl                                    ; FA78A7  pop HL
	unlk32 xiz                                 ; FA78A8  unlk XIZ
	ret                                        ; FA78AA  ret
; --------------------------------------------------------------------------
; Rec_StoreConsts_003F_0041 -- 0xFA78AB..0xFA78C5 (27 bytes)
;             (* NAMED in wave 7 round 12; was `sub_FA78AB`.)
;
; Called from: 2 site(s) outside this module:
;          0xFA8C1E in VoiceParam_DispatchOn_17_36__FA8C1D, 0xFA904B in VoiceParam_DispatchOn_17_11__FA904A
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Voice record: touches voice_record[+0x3F(w), +0x41(w)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA78AB-0xFA78C5
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; * WHAT IT DOES: stores two CONSTANT words into the argument record --
;   rec[+0x3F] = 0x017F and rec[+0x41] = 0x7F7F.  It reads nothing.
; Evidence: `ld (XBC+0x3f),0x017f` at 0xFA78B4 and `ld (XBC+0x41),0x7f7f` at
;          0xFA78BE, with the record pointer reloaded from (XIZ+0x08) before each
;          (0xFA78AF, 0xFA78B9).  Nine instructions in all.
; Unknown:  what the two fields are and why those values.  Both callers are the
;          dispatchers VoiceParam_DispatchOn_17_36 and VoiceParam_DispatchOn_17_11,
;          which name a subsystem and not this routine's job; the suffix is a pair
;          of field offsets, so this name is a FRAME.
; --------------------------------------------------------------------------
Rec_StoreConsts_003F_0041:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA78AB  link XIZ,0x0000
	ld	bc, (xiz+8)                             ; FA78AF  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA78B2  extz XBC
	extpfx5 0xB9, 0x3F, 0x02, 0x7F, 0x01       ; FA78B4  ld (XBC+0x3f),0x017f
	ld	bc, (xiz+8)                             ; FA78B9  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA78BC  extz XBC
	extpfx5 0xB9, 0x41, 0x02, 0x7F, 0x7F       ; FA78BE  ld (XBC+0x41),0x7f7f
	unlk32 xiz                                 ; FA78C3  unlk XIZ
	ret                                        ; FA78C5  ret
; --------------------------------------------------------------------------
; Clamp_ToRange_Word_b -- 0xFA78C6..0xFA78E7 (34 bytes)
;
; Called from: no site outside this module.
;          ⚠ NOT FOUND -- no literal call/calr/jp reaches this address anywhere
;          in the image.  A register-indirect call would be invisible to that
;          scan, so this is "not found", not "dead".
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA78C6-0xFA78E7
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  ⚠ 34 bytes BYTE-IDENTICAL, zero differing, to
;          Clamp_ToRange_Word at 0xFA7598 -- a second copy of one function, which is
;          why it takes that name with the tree's `_b` suffix (the same convention as
;          Dev10C_SetChanReg_0180_b at 0xFB7B9F).  Reproduce the diff with
;          `python3 notes/prom_c_finish_round7.py --twins`.
;          So: WA = min(max((XIZ+0x08), (XIZ+0x0C)), (XIZ+0x0A)), signed.
; Called from: NOT FOUND -- no literal call/calr/jp and no 24- or 32-bit pointer in
;          the image reaches 0xFA78C6.
; --------------------------------------------------------------------------
Clamp_ToRange_Word_b:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA78C6  link XIZ,0x0000
	pushw	hl                                   ; FA78CA  push HL
	ld	hl, (xiz+8)                             ; FA78CB  ld HL,(XIZ+0x08)
	extpfx3 0x9E, 0x0A, 0xF3                   ; FA78CE  cp HL,(XIZ+0x0a)
	jr le, sub_FA78C6__FA78D8                  ; FA78D1  jr LE,0xfa78d8
	ld	wa, (xiz+10)                            ; FA78D3  ld WA,(XIZ+0x0a)
	jr sub_FA78C6__FA78E4                      ; FA78D6  jr T,0xfa78e4
sub_FA78C6__FA78D8:
	extpfx3 0x9E, 0x0C, 0xF3                   ; FA78D8  cp HL,(XIZ+0x0c)
	jr ge, sub_FA78C6__FA78E2                  ; FA78DB  jr GE,0xfa78e2
	ld	wa, (xiz+12)                            ; FA78DD  ld WA,(XIZ+0x0c)
	jr sub_FA78C6__FA78E4                      ; FA78E0  jr T,0xfa78e4
sub_FA78C6__FA78E2:
	ld	wa, hl                                  ; FA78E2  ld WA,HL
sub_FA78C6__FA78E4:
	popw	hl                                    ; FA78E4  pop HL
	unlk32 xiz                                 ; FA78E5  unlk XIZ
	ret                                        ; FA78E7  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `EnvRec_ClearSlot` is now `EnvRec_ClearSlot`.
;   GRADE PROVEN.  WHY `EnvRec_ClearSlot`:
;   body: zeroes bytes +0..+5 and +7 of the 9-byte sub-record at
;   0x4CCF + 27*chan + 9*slot.  0x4CCF is 0x3BCF + 64*0x44, the byte after the
;   voice-record array, and 27 = 3 * 9.
; EnvRec_ClearSlot -- 0xFA78E8..0xFA7926 (63 bytes)
;
; Called from: 3 site(s) outside this module:
;          0xFA9B23 in Voice_StageChanSel_Reg0440_Reg0480__FA9ACB, 0xFA9E65 in Voice_StageRegs_0180_AB__FA9E12
;          0xFB6D8D in sub_FB6CEE__FB6D83
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA78E8-0xFA7926
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
EnvRec_ClearSlot:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA78E8  link XIZ,0x0000
	push	xhl                                   ; FA78EC  push XHL
	pushw	de                                   ; FA78ED  push DE
	ldb	c, 9                                   ; FA78EE  ld C,0x09
	extpfx3 0x8E, 0x08, 0x43                   ; FA78F0  mul BC,(XIZ+0x08)
	ld	hl, bc                                  ; FA78F3  ld HL,BC
	ldb	a, 27                                  ; FA78F5  ld A,0x1b
	extpfx3 0x8E, 0x0A, 0x41                   ; FA78F7  mul WA,(XIZ+0x0a)
	ld	de, wa                                  ; FA78FA  ld DE,WA
	add	de, bc                                 ; FA78FC  add DE,BC
	ldw	bc, 0x4CCF                             ; FA78FE  ld BC,0x4ccf
	ld	hl, bc                                  ; FA7901  ld HL,BC
	add	hl, de                                 ; FA7903  add HL,DE
	extz	xhl                                   ; FA7905  extz XHL
	ld	(xhl+1), 0                              ; FA7907  ld (XHL+0x01),0x00
	ld	(xhl+2), 0                              ; FA790B  ld (XHL+0x02),0x00
	ld	(xhl+3), 0                              ; FA790F  ld (XHL+0x03),0x00
	ld	(xhl+4), 0                              ; FA7913  ld (XHL+0x04),0x00
	ld	(xhl), 0                                ; FA7917  ld (XHL),0x00
	ld	(xhl+5), 0                              ; FA791A  ld (XHL+0x05),0x00
	ld	(xhl+7), 0                              ; FA791E  ld (XHL+0x07),0x00
	popw	de                                    ; FA7922  pop DE
	pop	xhl                                    ; FA7923  pop XHL
	unlk32 xiz                                 ; FA7924  unlk XIZ
	ret                                        ; FA7926  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `EGEnv_ScaleDepth_Shr12` is now `EGEnv_ScaleDepth_Shr12`.
;   GRADE PROVEN.  WHY `EGEnv_ScaleDepth_Shr12`:
;   body: returns min(v, (v * ((0x7F - a) * b)) >> 12) using Multiply32 twice.
;   All five callers are EGEnv_Eval_BaseCurveA/B/FreqWrite and
;   Voice_StageChanSel_Reg0440_Reg0480, each subtracting the result from the
;   curve product it has just formed.
; EGEnv_ScaleDepth_Shr12 -- 0xFA7927..0xFA796C (70 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFA9C18 in Voice_StageChanSel_Reg0440_Reg0480__FA9BF3
;          4 site(s) inside this module:
;          0xFA79B9 0xFA7A9B 0xFA7B89 0xFA7BFC
; Inputs:  frame `link XIZ,-8`; argument slots read: (XIZ+0x08), (XIZ+0x0C), (XIZ+0x0E)
; Outputs: no absolute-addressed write.
; Calls:   0xFCB11B = Multiply32
; Evidence: the listing below is the byte-identical round-trip of 0xFA7927-0xFA796C
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
EGEnv_ScaleDepth_Shr12:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FA7927  link XIZ,0xfff8
	push	xix                                   ; FA792B  push XIX
	ld	bc, (xiz+12)                            ; FA792C  ld BC,(XIZ+0x0c)
	extz	bc                                    ; FA792F  extz BC
	extz	xbc                                   ; FA7931  extz XBC
	ld	xwa, 0x7F                               ; FA7933  ld XWA,0x0000007f
	sub	xwa, xbc                               ; FA7938  sub XWA,XBC
	ld	(xiz-4), xwa                            ; FA793A  ld (XIZ+0xfc),XWA
	ld	bc, (xiz+14)                            ; FA793D  ld BC,(XIZ+0x0e)
	extz	bc                                    ; FA7940  extz BC
	extz	xbc                                   ; FA7942  extz XBC
	push	xbc                                   ; FA7944  push XBC
	push	xwa                                   ; FA7945  push XWA
	call	0xFCB11B                              ; FA7946  call 0xfcb11b
	ld	(xiz-8), xiy                            ; FA794A  ld (XIZ+0xf8),XIY
	ld	xix, (xiz+8)                            ; FA794D  ld XIX,(XIZ+0x08)
	push	xiy                                   ; FA7950  push XIY
	push	xix                                   ; FA7951  push XIX
	call	0xFCB11B                              ; FA7952  call 0xfcb11b
	ld	xix, xiy                                ; FA7956  ld XIX,XIY
	srl	xiy, 12                                ; FA7958  srl 0x0c,XIY
	ld	xix, xiy                                ; FA795B  ld XIX,XIY
	extpfx3 0xAE, 0x08, 0xF5                   ; FA795D  cp XIY,(XIZ+0x08)
	jr ule, sub_FA7927__FA7967                 ; FA7960  jr ULE,0xfa7967
	ld	xiy, (xiz+8)                            ; FA7962  ld XIY,(XIZ+0x08)
	jr sub_FA7927__FA7969                      ; FA7965  jr T,0xfa7969
sub_FA7927__FA7967:
	ld	xiy, xix                                ; FA7967  ld XIY,XIX
sub_FA7927__FA7969:
	pop	xix                                    ; FA7969  pop XIX
	unlk32 xiz                                 ; FA796A  unlk XIZ
	ret                                        ; FA796C  ret
; --------------------------------------------------------------------------
; EGEnv_Eval_BaseCurveA -- 0xFA796D..0xFA79F3 (135 bytes)
;
; Called from: 4 site(s) outside this module:
;          0xFA9AB2 in Voice_StageChanSel_Reg0440_Reg0480__FA9AAF, 0xFABE60 in Voice_RecomputeAllThreeBaseCurves__FABE3F
;          0xFAE45F in Voice_Restage_Reg0440_BaseCurve_ForPart__FAE45B, 0xFB8AC9 in Voice_RecomputeEnv_AndWriteSlot2__FB8A85
; Inputs:  frame `link XIZ,-6`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA7927 = EGEnv_ScaleDepth_Shr12, 0xFCB11B = Multiply32
; Evidence: the listing below is the byte-identical round-trip of 0xFA796D-0xFA79F3
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; EGEnv_Eval_BaseCurveA -- one of SIX evaluators of the
;          27-byte record array at RAM 0x4CCF (`ld C,0x1b` 0xFA7974, `ld HL,0x4ccf` 0xFA797C).
;          value = ((EGEnv_BaseCurve_A[rec+1] * rec[+2]) - correction) >> 7, clamped to
;          0x1FFF, OR'd with EGEnv_ModeBits_Table[rec[+0] & 3].
;          0xFA798B  add XBC,0x00FDE12B   the curve, indexed by rec[+1]*2
;          0xFA79C2  srl 0x07,XIY         the >> 7
;          0xFA79C7  cp XIY,0x1FFF        the clamp
;          0xFA79E2  add XBC,0x00FDEBEC   EGEnv_ModeBits_Table, indexed by rec[+0]&3
;          The correction (skipped when rec[+5] == 0) is EGEnv_ScaleDepth_Shr12(product, rec[+6], rec[+5]).
;          Evidence: `python3 notes/prom_c_understanding_round6.py --blocks`, which reads all
;          six evaluators out of the listing and asserts that each indexes exactly one base
;          curve, that the base evaluators clamp to 0x1FFF and the value evaluators to
;          0x3FFF, and that only the base evaluators touch the mode-bit table.
;          ★ THIS IS BLOCK A OF THREE.  A/B/C are THIS TREE'S labels for three groups that
;          differ in one operand -- which of the three 256-byte base curves at 0xFDE12B,
;          0xFDE22B and 0xFDE32B they index.  Block A's stager writes registers 0x0440 and
;          0x0480; block B's writes 0x0180; block C's writes 0x04C0.  No ROM byte spells "A".
;          Unknown: what the record at 0x4CCF is, what its index selects, and what the block
;          modulates.
; --------------------------------------------------------------------------
EGEnv_Eval_BaseCurveA:
	link32 0xEE, 0x0C, 0xFA, 0xFF              ; FA796D  link XIZ,0xfffa
	push	xhl                                   ; FA7971  push XHL
	pushw	de                                   ; FA7972  push DE
	push	xix                                   ; FA7973  push XIX
	ldb	c, 27                                  ; FA7974  ld C,0x1b
	extpfx3 0x8E, 0x08, 0x43                   ; FA7976  mul BC,(XIZ+0x08)
	ld	(xiz-2), bc                             ; FA7979  ld (XIZ+0xfe),BC
	ldw	hl, 0x4CCF                             ; FA797C  ld HL,0x4ccf
	add	hl, bc                                 ; FA797F  add HL,BC
	extz	xhl                                   ; FA7981  extz XHL
	ld	c, (xhl+1)                              ; FA7983  ld C,(XHL+0x01)
	mul	c, 2                                   ; FA7986  mul C,0x02
	extz	xbc                                   ; FA7989  extz XBC
	add	xbc, 0xFDE12B                          ; FA798B  add XBC,0x00fde12b
	ld	bc, (xbc)                               ; FA7991  ld BC,(XBC)
	extz	xbc                                   ; FA7993  extz XBC
	ld	(xiz-6), xbc                            ; FA7995  ld (XIZ+0xfa),XBC
	ld	a, (xhl+2)                              ; FA7998  ld A,(XHL+0x02)
	extz	wa                                    ; FA799B  extz WA
	extz	xwa                                   ; FA799D  extz XWA
	push	xwa                                   ; FA799F  push XWA
	push	xbc                                   ; FA79A0  push XBC
	call	0xFCB11B                              ; FA79A1  call 0xfcb11b
	ld	xix, xiy                                ; FA79A5  ld XIX,XIY
	ld	d, (xhl+5)                              ; FA79A7  ld D,(XHL+0x05)
	cps	d, 0                                   ; FA79AA  cp D,0
	jr z, EGEnv_Eval_BaseCurveA__FA79C0                   ; FA79AC  jr Z,0xfa79c0
	push	0                                     ; FA79AE  push 0x00
	push	d                                     ; FA79B0  push D
	extz	xhl                                   ; FA79B2  extz XHL
	ld	c, (xhl+6)                              ; FA79B4  ld C,(XHL+0x06)
	pushw	bc                                   ; FA79B7  push BC
	push	xiy                                   ; FA79B8  push XIY
	calr (0xFA7927 - 0xFA79BC)                 ; FA79B9  calr 0xfa7927
	sub	xix, xiy                               ; FA79BC  sub XIX,XIY
	inc	8, xsp                                 ; FA79BE  inc 0,XSP
EGEnv_Eval_BaseCurveA__FA79C0:
	ld	xiy, xix                                ; FA79C0  ld XIY,XIX
	srl	xiy, 7                                 ; FA79C2  srl 0x07,XIY
	ld	xix, xiy                                ; FA79C5  ld XIX,XIY
	cp	xiy, 0x1FFF                             ; FA79C7  cp XIY,0x00001fff
	jr ule, EGEnv_Eval_BaseCurveA__FA79D4                 ; FA79CD  jr ULE,0xfa79d4
	ld	xix, 0x1FFF                             ; FA79CF  ld XIX,0x00001fff
EGEnv_Eval_BaseCurveA__FA79D4:
	ld	de, ix                                  ; FA79D4  ld DE,IX
	extz	xhl                                   ; FA79D6  extz XHL
	ld	c, (xhl)                                ; FA79D8  ld C,(XHL)
	and	c, 3                                   ; FA79DA  and C,0x03
	mul	c, 2                                   ; FA79DD  mul C,0x02
	extz	xbc                                   ; FA79E0  extz XBC
	add	xbc, 0xFDEBEC                          ; FA79E2  add XBC,0x00fdebec
	ld	bc, (xbc)                               ; FA79E8  ld BC,(XBC)
	or	bc, de                                  ; FA79EA  or BC,DE
	ld	wa, bc                                  ; FA79EC  ld WA,BC
	pop	xix                                    ; FA79EE  pop XIX
	popw	de                                    ; FA79EF  pop DE
	pop	xhl                                    ; FA79F0  pop XHL
	unlk32 xiz                                 ; FA79F1  unlk XIZ
	ret                                        ; FA79F3  ret
; --------------------------------------------------------------------------
; EGEnv_Eval_ValueCurve_WithBaseCurveA -- 0xFA79F4..0xFA7A4A (87 bytes)
;
; Called from: 3 site(s) outside this module:
;          0xFA9A34 in Voice_StageChanSel_Reg0440_Reg0480__FA9A14, 0xFAE5A3 in Voice_Restage_Reg0440_ValueCurve_ForPart__FAE59F
;          0xFB8AD7 in Voice_RecomputeEnv_AndWriteSlot2__FB8A85
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFCB11B = Multiply32
; Evidence: the listing below is the byte-identical round-trip of 0xFA79F4-0xFA7A4A
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; EGEnv_Eval_ValueCurve_WithBaseCurveA -- the
;          other half of block A.  value = (EGEnv_ValueCurve_Simple[rec[+3]] * rec[+4]) >> 7,
;          clamped to 0x3FFF, with NO mode bits.
;          0xFA7A13  add XBC,0x00FDE02B   EGEnv_ValueCurve_Simple, indexed by rec[+3]*2
;          0xFA7A2F  srl 0x07,XIY
;          0xFA7A34  cp XIY,0x3FFF
;          ★ THE PAIRING IS MEASURED, NOT ASSUMED.  All three value evaluators read the SAME
;          table with the SAME fields, so what makes this one block A's is CO-OCCURRENCE: over
;          the thirteen routines in the image that call any of the six evaluators, none calls
;          one block's value evaluator beside another block's base evaluator, and none calls
;          two blocks' value evaluators.  The one routine that spans blocks --
;          Voice_RecomputeAllThreeBaseCurves -- calls all three BASE evaluators and no value
;          evaluator, and is named rather than smoothed away.
;          Evidence: notes/prom_c_understanding_round6.py --blocks prints the whole caller
;          table and asserts both properties.
; --------------------------------------------------------------------------
EGEnv_Eval_ValueCurve_WithBaseCurveA:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FA79F4  link XIZ,0xfffc
	pushw	hl                                   ; FA79F8  push HL
	push	xde                                   ; FA79F9  push XDE
	push	xix                                   ; FA79FA  push XIX
	ldb	c, 27                                  ; FA79FB  ld C,0x1b
	extpfx3 0x8E, 0x08, 0x43                   ; FA79FD  mul BC,(XIZ+0x08)
	ld	hl, bc                                  ; FA7A00  ld HL,BC
	ldw	wa, 0x4CCF                             ; FA7A02  ld WA,0x4ccf
	ld	de, wa                                  ; FA7A05  ld DE,WA
	add	de, bc                                 ; FA7A07  add DE,BC
	extz	xde                                   ; FA7A09  extz XDE
	ld	c, (xde+3)                              ; FA7A0B  ld C,(XDE+0x03)
	mul	c, 2                                   ; FA7A0E  mul C,0x02
	extz	xbc                                   ; FA7A11  extz XBC
	add	xbc, 0xFDE02B                          ; FA7A13  add XBC,0x00fde02b
	ld	bc, (xbc)                               ; FA7A19  ld BC,(XBC)
	extz	xbc                                   ; FA7A1B  extz XBC
	ld	(xiz-4), xbc                            ; FA7A1D  ld (XIZ+0xfc),XBC
	ld	a, (xde+4)                              ; FA7A20  ld A,(XDE+0x04)
	extz	wa                                    ; FA7A23  extz WA
	extz	xwa                                   ; FA7A25  extz XWA
	push	xwa                                   ; FA7A27  push XWA
	push	xbc                                   ; FA7A28  push XBC
	call	0xFCB11B                              ; FA7A29  call 0xfcb11b
	ld	xix, xiy                                ; FA7A2D  ld XIX,XIY
	srl	xiy, 7                                 ; FA7A2F  srl 0x07,XIY
	ld	xix, xiy                                ; FA7A32  ld XIX,XIY
	cp	xiy, 0x3FFF                             ; FA7A34  cp XIY,0x00003fff
	jr ule, EGEnv_Eval_ValueCurve_WithBaseCurveA__FA7A41                 ; FA7A3A  jr ULE,0xfa7a41
	ld	xix, 0x3FFF                             ; FA7A3C  ld XIX,0x00003fff
EGEnv_Eval_ValueCurve_WithBaseCurveA__FA7A41:
	ld	bc, ix                                  ; FA7A41  ld BC,IX
	ld	wa, bc                                  ; FA7A43  ld WA,BC
	pop	xix                                    ; FA7A45  pop XIX
	pop	xde                                    ; FA7A46  pop XDE
	popw	hl                                    ; FA7A47  pop HL
	unlk32 xiz                                 ; FA7A48  unlk XIZ
	ret                                        ; FA7A4A  ret
; --------------------------------------------------------------------------
; EGEnv_Eval_BaseCurveB -- 0xFA7A4B..0xFA7AD5 (139 bytes)
;
; Called from: 4 site(s) outside this module:
;          0xFA9DF9 in Voice_StageRegs_0180_AB__FA9DF5, 0xFABEEB in Voice_RecomputeAllThreeBaseCurves__FABECC
;          0xFAE6DE in Voice_Restage_Reg0180_BaseCurve_ForPart__FAE6DA, 0xFB8BC9 in Voice_RecomputeEnv_AndWriteSlot1__FB8B85
; Inputs:  frame `link XIZ,-6`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA7927 = EGEnv_ScaleDepth_Shr12, 0xFCB11B = Multiply32
; Evidence: the listing below is the byte-identical round-trip of 0xFA7A4B-0xFA7AD5
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; EGEnv_Eval_BaseCurveB -- block B's base evaluator: the same
;          shape as EGEnv_Eval_BaseCurveA with ONE operand changed, EGEnv_BaseCurve_B
;          (`add XBC,0x00FDE22B` at 0xFA7A6D instead of 0x00FDE12B).  Same record array, same
;          fields +0/+1/+2/+5/+6, same 0x1FFF clamp, same EGEnv_ModeBits_Table OR.
;          Evidence: notes/prom_c_understanding_round6.py --blocks.
; --------------------------------------------------------------------------
EGEnv_Eval_BaseCurveB:
	link32 0xEE, 0x0C, 0xFA, 0xFF              ; FA7A4B  link XIZ,0xfffa
	push	xhl                                   ; FA7A4F  push XHL
	pushw	de                                   ; FA7A50  push DE
	push	xix                                   ; FA7A51  push XIX
	ldb	c, 27                                  ; FA7A52  ld C,0x1b
	extpfx3 0x8E, 0x08, 0x43                   ; FA7A54  mul BC,(XIZ+0x08)
	add	bc, 9                                  ; FA7A57  add BC,0x0009
	ld	(xiz-2), bc                             ; FA7A5B  ld (XIZ+0xfe),BC
	ldw	hl, 0x4CCF                             ; FA7A5E  ld HL,0x4ccf
	add	hl, bc                                 ; FA7A61  add HL,BC
	extz	xhl                                   ; FA7A63  extz XHL
	ld	c, (xhl+1)                              ; FA7A65  ld C,(XHL+0x01)
	mul	c, 2                                   ; FA7A68  mul C,0x02
	extz	xbc                                   ; FA7A6B  extz XBC
	add	xbc, 0xFDE22B                          ; FA7A6D  add XBC,0x00fde22b
	ld	bc, (xbc)                               ; FA7A73  ld BC,(XBC)
	extz	xbc                                   ; FA7A75  extz XBC
	ld	(xiz-6), xbc                            ; FA7A77  ld (XIZ+0xfa),XBC
	ld	a, (xhl+2)                              ; FA7A7A  ld A,(XHL+0x02)
	extz	wa                                    ; FA7A7D  extz WA
	extz	xwa                                   ; FA7A7F  extz XWA
	push	xwa                                   ; FA7A81  push XWA
	push	xbc                                   ; FA7A82  push XBC
	call	0xFCB11B                              ; FA7A83  call 0xfcb11b
	ld	xix, xiy                                ; FA7A87  ld XIX,XIY
	ld	d, (xhl+5)                              ; FA7A89  ld D,(XHL+0x05)
	cps	d, 0                                   ; FA7A8C  cp D,0
	jr z, EGEnv_Eval_BaseCurveB__FA7AA2                   ; FA7A8E  jr Z,0xfa7aa2
	push	0                                     ; FA7A90  push 0x00
	push	d                                     ; FA7A92  push D
	extz	xhl                                   ; FA7A94  extz XHL
	ld	c, (xhl+6)                              ; FA7A96  ld C,(XHL+0x06)
	pushw	bc                                   ; FA7A99  push BC
	push	xiy                                   ; FA7A9A  push XIY
	calr (0xFA7927 - 0xFA7A9E)                 ; FA7A9B  calr 0xfa7927
	sub	xix, xiy                               ; FA7A9E  sub XIX,XIY
	inc	8, xsp                                 ; FA7AA0  inc 0,XSP
EGEnv_Eval_BaseCurveB__FA7AA2:
	ld	xiy, xix                                ; FA7AA2  ld XIY,XIX
	srl	xiy, 7                                 ; FA7AA4  srl 0x07,XIY
	ld	xix, xiy                                ; FA7AA7  ld XIX,XIY
	cp	xiy, 0x1FFF                             ; FA7AA9  cp XIY,0x00001fff
	jr ule, EGEnv_Eval_BaseCurveB__FA7AB6                 ; FA7AAF  jr ULE,0xfa7ab6
	ld	xix, 0x1FFF                             ; FA7AB1  ld XIX,0x00001fff
EGEnv_Eval_BaseCurveB__FA7AB6:
	ld	de, ix                                  ; FA7AB6  ld DE,IX
	extz	xhl                                   ; FA7AB8  extz XHL
	ld	c, (xhl)                                ; FA7ABA  ld C,(XHL)
	and	c, 3                                   ; FA7ABC  and C,0x03
	mul	c, 2                                   ; FA7ABF  mul C,0x02
	extz	xbc                                   ; FA7AC2  extz XBC
	add	xbc, 0xFDEBEC                          ; FA7AC4  add XBC,0x00fdebec
	ld	bc, (xbc)                               ; FA7ACA  ld BC,(XBC)
	or	bc, de                                  ; FA7ACC  or BC,DE
	ld	wa, bc                                  ; FA7ACE  ld WA,BC
	pop	xix                                    ; FA7AD0  pop XIX
	popw	de                                    ; FA7AD1  pop DE
	pop	xhl                                    ; FA7AD2  pop XHL
	unlk32 xiz                                 ; FA7AD3  unlk XIZ
	ret                                        ; FA7AD5  ret
; --------------------------------------------------------------------------
; EGEnv_Eval_ValueCurve_WithBaseCurveB -- 0xFA7AD6..0xFA7B30 (91 bytes)
;
; Called from: 3 site(s) outside this module:
;          0xFA9D7A in Voice_StageRegs_0180_AB__FA9D5B, 0xFAE824 in Voice_Restage_Reg0180_ValueCurve_ForPart__FAE820
;          0xFB8BD7 in Voice_RecomputeEnv_AndWriteSlot1__FB8B85
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFCB11B = Multiply32
; Evidence: the listing below is the byte-identical round-trip of 0xFA7AD6-0xFA7B30
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; EGEnv_Eval_ValueCurve_WithBaseCurveB -- block
;          B's value evaluator; `add XBC,0x00FDE02B` at 0xFA7AF9, clamp 0x3FFF at 0xFA7B1A.
;          Paired with EGEnv_Eval_BaseCurveB by the co-occurrence census
;          (notes/prom_c_understanding_round6.py --blocks).
; --------------------------------------------------------------------------
EGEnv_Eval_ValueCurve_WithBaseCurveB:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FA7AD6  link XIZ,0xfffc
	pushw	hl                                   ; FA7ADA  push HL
	push	xde                                   ; FA7ADB  push XDE
	push	xix                                   ; FA7ADC  push XIX
	ldb	c, 27                                  ; FA7ADD  ld C,0x1b
	extpfx3 0x8E, 0x08, 0x43                   ; FA7ADF  mul BC,(XIZ+0x08)
	ld	hl, bc                                  ; FA7AE2  ld HL,BC
	add	hl, 9                                  ; FA7AE4  add HL,0x0009
	ldw	bc, 0x4CCF                             ; FA7AE8  ld BC,0x4ccf
	ld	de, bc                                  ; FA7AEB  ld DE,BC
	add	de, hl                                 ; FA7AED  add DE,HL
	extz	xde                                   ; FA7AEF  extz XDE
	ld	c, (xde+3)                              ; FA7AF1  ld C,(XDE+0x03)
	mul	c, 2                                   ; FA7AF4  mul C,0x02
	extz	xbc                                   ; FA7AF7  extz XBC
	add	xbc, 0xFDE02B                          ; FA7AF9  add XBC,0x00fde02b
	ld	bc, (xbc)                               ; FA7AFF  ld BC,(XBC)
	extz	xbc                                   ; FA7B01  extz XBC
	ld	(xiz-4), xbc                            ; FA7B03  ld (XIZ+0xfc),XBC
	ld	a, (xde+4)                              ; FA7B06  ld A,(XDE+0x04)
	extz	wa                                    ; FA7B09  extz WA
	extz	xwa                                   ; FA7B0B  extz XWA
	push	xwa                                   ; FA7B0D  push XWA
	push	xbc                                   ; FA7B0E  push XBC
	call	0xFCB11B                              ; FA7B0F  call 0xfcb11b
	ld	xix, xiy                                ; FA7B13  ld XIX,XIY
	srl	xiy, 7                                 ; FA7B15  srl 0x07,XIY
	ld	xix, xiy                                ; FA7B18  ld XIX,XIY
	cp	xiy, 0x3FFF                             ; FA7B1A  cp XIY,0x00003fff
	jr ule, EGEnv_Eval_ValueCurve_WithBaseCurveB__FA7B27                 ; FA7B20  jr ULE,0xfa7b27
	ld	xix, 0x3FFF                             ; FA7B22  ld XIX,0x00003fff
EGEnv_Eval_ValueCurve_WithBaseCurveB__FA7B27:
	ld	bc, ix                                  ; FA7B27  ld BC,IX
	ld	wa, bc                                  ; FA7B29  ld WA,BC
	pop	xix                                    ; FA7B2B  pop XIX
	pop	xde                                    ; FA7B2C  pop XDE
	popw	hl                                    ; FA7B2D  pop HL
	unlk32 xiz                                 ; FA7B2E  unlk XIZ
	ret                                        ; FA7B30  ret
; --------------------------------------------------------------------------
; EGEnv_Eval_FreqWriteBaseCurve -- 0xFA7B31..0xFA7C39 (265 bytes)
;
; Called from: 4 site(s) outside this module:
;          0xFAA0A5 in Voice_StageChanSel_Reg04C0__FAA0A1, 0xFABF7E in Voice_RecomputeAllThreeBaseCurves__FABF5D
;          0xFAE966 in Voice_Restage_Reg04C0_BaseCurve_ForPart__FAE962, 0xFB8CC9 in Voice_RecomputeEnv_AndWriteSlot1or3__FB8C85
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D796, 0x00D7A0
; Calls:   0xFA7927 = EGEnv_ScaleDepth_Shr12, 0xFCB11B = Multiply32
; Evidence: the listing below is the byte-identical round-trip of 0xFA7B31-0xFA7C39
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; EGEnv_Eval_FreqWriteBaseCurve -- block C's base
;          evaluator: the same shape again, indexing Voice_FreqWrite_BaseCurve (0xFDE32B) at
;          0xFA7B5B and 0xFA7BCE, and it evaluates the record TWICE, storing 0x00D796 and
;          0x00D7A0.
;          ⚠ WHY NOT `EGEnv_Eval_BaseCurveC`.  0xFDE32B is the third of three 256-byte tables
;          0x100 apart read by three routines that differ in nothing else, so
;          `Voice_FreqWrite_BaseCurve` beside `EGEnv_BaseCurve_A` and `_B` looks like an
;          inconsistency -- and renaming it was considered and REJECTED this round.  All three
;          names are KN5000 sub-CPU transplants onto BYTE-IDENTICAL tables (prom_c 0xFDE12B /
;          0xFDE22B / 0xFDE32B <- kn5000 sub-CPU 0x10A64 / 0x10B64 / 0x10C64,
;          notes/FINDINGS-kn5000-transplant-offset.md).  The asymmetry is the SIBLING'S;
;          erasing it would destroy what makes the transplant checkable.
;          Evidence: notes/prom_c_understanding_round6.py --blocks.
; --------------------------------------------------------------------------
EGEnv_Eval_FreqWriteBaseCurve:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FA7B31  link XIZ,0xfffc
	pushw	hl                                   ; FA7B35  push HL
	push	xde                                   ; FA7B36  push XDE
	push	xix                                   ; FA7B37  push XIX
	ldb	c, 27                                  ; FA7B38  ld C,0x1b
	extpfx3 0x8E, 0x08, 0x43                   ; FA7B3A  mul BC,(XIZ+0x08)
	ld	hl, bc                                  ; FA7B3D  ld HL,BC
	add	hl, 18                                 ; FA7B3F  add HL,0x0012
	ldw	de, 0x4CCF                             ; FA7B43  ld DE,0x4ccf
	ld	bc, hl                                  ; FA7B46  ld BC,HL
	add	de, bc                                 ; FA7B48  add DE,BC
	cp (xiz+8), 0x40                           ; FA7B4A  cp (XIZ+0x08),0x40
	jrl nc, EGEnv_Eval_FreqWriteBaseCurve__FA7BC4                 ; FA7B4E  jrl NC,0xfa7bc4
	extz	xde                                   ; FA7B51  extz XDE
	ld	c, (xde+1)                              ; FA7B53  ld C,(XDE+0x01)
	mul	c, 2                                   ; FA7B56  mul C,0x02
	extz	xbc                                   ; FA7B59  extz XBC
	add	xbc, 0xFDE32B                          ; FA7B5B  add XBC,0x00fde32b
	ld	bc, (xbc)                               ; FA7B61  ld BC,(XBC)
	extz	xbc                                   ; FA7B63  extz XBC
	ld	(xiz-4), xbc                            ; FA7B65  ld (XIZ+0xfc),XBC
	ld	a, (xde+2)                              ; FA7B68  ld A,(XDE+0x02)
	extz	wa                                    ; FA7B6B  extz WA
	extz	xwa                                   ; FA7B6D  extz XWA
	push	xwa                                   ; FA7B6F  push XWA
	push	xbc                                   ; FA7B70  push XBC
	call	0xFCB11B                              ; FA7B71  call 0xfcb11b
	ld	xix, xiy                                ; FA7B75  ld XIX,XIY
	ld	h, (xde+5)                              ; FA7B77  ld H,(XDE+0x05)
	cps	h, 0                                   ; FA7B7A  cp H,0
	jr z, EGEnv_Eval_FreqWriteBaseCurve__FA7B90                   ; FA7B7C  jr Z,0xfa7b90
	push	0                                     ; FA7B7E  push 0x00
	push	h                                     ; FA7B80  push H
	extz	xde                                   ; FA7B82  extz XDE
	ld	c, (xde+6)                              ; FA7B84  ld C,(XDE+0x06)
	pushw	bc                                   ; FA7B87  push BC
	push	xiy                                   ; FA7B88  push XIY
	calr (0xFA7927 - 0xFA7B8C)                 ; FA7B89  calr 0xfa7927
	sub	xix, xiy                               ; FA7B8C  sub XIX,XIY
	inc	8, xsp                                 ; FA7B8E  inc 0,XSP
EGEnv_Eval_FreqWriteBaseCurve__FA7B90:
	ld	xiy, xix                                ; FA7B90  ld XIY,XIX
	srl	xiy, 7                                 ; FA7B92  srl 0x07,XIY
	ld	xix, xiy                                ; FA7B95  ld XIX,XIY
	cp	xiy, 0x1FFF                             ; FA7B97  cp XIY,0x00001fff
	jr ule, EGEnv_Eval_FreqWriteBaseCurve__FA7BA4                 ; FA7B9D  jr ULE,0xfa7ba4
	ld	xix, 0x1FFF                             ; FA7B9F  ld XIX,0x00001fff
EGEnv_Eval_FreqWriteBaseCurve__FA7BA4:
	ld	hl, ix                                  ; FA7BA4  ld HL,IX
	extz	xde                                   ; FA7BA6  extz XDE
	ld	c, (xde)                                ; FA7BA8  ld C,(XDE)
	and	c, 3                                   ; FA7BAA  and C,0x03
	mul	c, 2                                   ; FA7BAD  mul C,0x02
	extz	xbc                                   ; FA7BB0  extz XBC
	add	xbc, 0xFDEBEC                          ; FA7BB2  add XBC,0x00fdebec
	ld	bc, (xbc)                               ; FA7BB8  ld BC,(XBC)
	or	bc, hl                                  ; FA7BBA  or BC,HL
	ld	(0xD796:24), bc                        ; FA7BBC  ld (0x00d796),BC
	jrl EGEnv_Eval_FreqWriteBaseCurve__FA7C34                     ; FA7BC1  jrl T,0xfa7c34
EGEnv_Eval_FreqWriteBaseCurve__FA7BC4:
	extz	xde                                   ; FA7BC4  extz XDE
	ld	c, (xde+1)                              ; FA7BC6  ld C,(XDE+0x01)
	mul	c, 2                                   ; FA7BC9  mul C,0x02
	extz	xbc                                   ; FA7BCC  extz XBC
	add	xbc, 0xFDE32B                          ; FA7BCE  add XBC,0x00fde32b
	ld	bc, (xbc)                               ; FA7BD4  ld BC,(XBC)
	extz	xbc                                   ; FA7BD6  extz XBC
	ld	(xiz-4), xbc                            ; FA7BD8  ld (XIZ+0xfc),XBC
	ld	a, (xde+2)                              ; FA7BDB  ld A,(XDE+0x02)
	extz	wa                                    ; FA7BDE  extz WA
	extz	xwa                                   ; FA7BE0  extz XWA
	push	xwa                                   ; FA7BE2  push XWA
	push	xbc                                   ; FA7BE3  push XBC
	call	0xFCB11B                              ; FA7BE4  call 0xfcb11b
	ld	xix, xiy                                ; FA7BE8  ld XIX,XIY
	ld	h, (xde+5)                              ; FA7BEA  ld H,(XDE+0x05)
	cps	h, 0                                   ; FA7BED  cp H,0
	jr z, EGEnv_Eval_FreqWriteBaseCurve__FA7C03                   ; FA7BEF  jr Z,0xfa7c03
	push	0                                     ; FA7BF1  push 0x00
	push	h                                     ; FA7BF3  push H
	extz	xde                                   ; FA7BF5  extz XDE
	ld	c, (xde+6)                              ; FA7BF7  ld C,(XDE+0x06)
	pushw	bc                                   ; FA7BFA  push BC
	push	xiy                                   ; FA7BFB  push XIY
	calr (0xFA7927 - 0xFA7BFF)                 ; FA7BFC  calr 0xfa7927
	sub	xix, xiy                               ; FA7BFF  sub XIX,XIY
	inc	8, xsp                                 ; FA7C01  inc 0,XSP
EGEnv_Eval_FreqWriteBaseCurve__FA7C03:
	ld	xiy, xix                                ; FA7C03  ld XIY,XIX
	srl	xiy, 7                                 ; FA7C05  srl 0x07,XIY
	ld	xix, xiy                                ; FA7C08  ld XIX,XIY
	cp	xiy, 0x1FFF                             ; FA7C0A  cp XIY,0x00001fff
	jr ule, EGEnv_Eval_FreqWriteBaseCurve__FA7C17                 ; FA7C10  jr ULE,0xfa7c17
	ld	xix, 0x1FFF                             ; FA7C12  ld XIX,0x00001fff
EGEnv_Eval_FreqWriteBaseCurve__FA7C17:
	ld	hl, ix                                  ; FA7C17  ld HL,IX
	extz	xde                                   ; FA7C19  extz XDE
	ld	c, (xde)                                ; FA7C1B  ld C,(XDE)
	and	c, 3                                   ; FA7C1D  and C,0x03
	mul	c, 2                                   ; FA7C20  mul C,0x02
	extz	xbc                                   ; FA7C23  extz XBC
	add	xbc, 0xFDEBEC                          ; FA7C25  add XBC,0x00fdebec
	ld	bc, (xbc)                               ; FA7C2B  ld BC,(XBC)
	or	bc, hl                                  ; FA7C2D  or BC,HL
	ld	(0xD7A0:24), bc                        ; FA7C2F  ld (0x00d7a0),BC
EGEnv_Eval_FreqWriteBaseCurve__FA7C34:
	pop	xix                                    ; FA7C34  pop XIX
	pop	xde                                    ; FA7C35  pop XDE
	popw	hl                                    ; FA7C36  pop HL
	unlk32 xiz                                 ; FA7C37  unlk XIZ
	ret                                        ; FA7C39  ret
; --------------------------------------------------------------------------
; EGEnv_Eval_ValueCurve_WithFreqWriteCurve -- 0xFA7C3A..0xFA7CC8 (143 bytes)
;
; Called from: 3 site(s) outside this module:
;          0xFAA024 in Voice_StageChanSel_Reg04C0__FAA00A, 0xFAEAAF in Voice_Restage_Reg04C0_ValueCurve_ForPart__FAEAAB
;          0xFB8CD2 in Voice_RecomputeEnv_AndWriteSlot1or3__FB8C85
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D798, 0x00D79C
; Calls:   0xFCB11B = Multiply32
; Evidence: the listing below is the byte-identical round-trip of 0xFA7C3A-0xFA7CC8
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; EGEnv_Eval_ValueCurve_WithFreqWriteCurve --
;          block C's value evaluator; `add XBC,0x00FDE02B` at 0xFA7C5D, clamp 0x3FFF at
;          0xFA7C84.  It also tests bit 5 of rec[+0] (`and C,0x20` at 0xFA7C95) and writes the
;          globals 0x00D798 and 0x00D79C, which the other two value evaluators do not.
;          Paired with EGEnv_Eval_FreqWriteBaseCurve by the co-occurrence census.
; --------------------------------------------------------------------------
EGEnv_Eval_ValueCurve_WithFreqWriteCurve:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FA7C3A  link XIZ,0xfffc
	push	xhl                                   ; FA7C3E  push XHL
	pushw	de                                   ; FA7C3F  push DE
	push	xix                                   ; FA7C40  push XIX
	ldb	c, 27                                  ; FA7C41  ld C,0x1b
	extpfx3 0x8E, 0x08, 0x43                   ; FA7C43  mul BC,(XIZ+0x08)
	ld	de, bc                                  ; FA7C46  ld DE,BC
	add	de, 18                                 ; FA7C48  add DE,0x0012
	ldw	hl, 0x4CCF                             ; FA7C4C  ld HL,0x4ccf
	ld	bc, de                                  ; FA7C4F  ld BC,DE
	add	hl, bc                                 ; FA7C51  add HL,BC
	extz	xhl                                   ; FA7C53  extz XHL
	ld	c, (xhl+3)                              ; FA7C55  ld C,(XHL+0x03)
	mul	c, 2                                   ; FA7C58  mul C,0x02
	extz	xbc                                   ; FA7C5B  extz XBC
	add	xbc, 0xFDE02B                          ; FA7C5D  add XBC,0x00fde02b
	ld	bc, (xbc)                               ; FA7C63  ld BC,(XBC)
	extz	xbc                                   ; FA7C65  extz XBC
	ld	(xiz-4), xbc                            ; FA7C67  ld (XIZ+0xfc),XBC
	ld	a, (xhl+4)                              ; FA7C6A  ld A,(XHL+0x04)
	extz	wa                                    ; FA7C6D  extz WA
	extz	xwa                                   ; FA7C6F  extz XWA
	push	xwa                                   ; FA7C71  push XWA
	push	xbc                                   ; FA7C72  push XBC
	call	0xFCB11B                              ; FA7C73  call 0xfcb11b
	ld	xix, xiy                                ; FA7C77  ld XIX,XIY
	srl	xiy, 7                                 ; FA7C79  srl 0x07,XIY
	ld	xix, xiy                                ; FA7C7C  ld XIX,XIY
	cp (xiz+8), 0x40                           ; FA7C7E  cp (XIZ+0x08),0x40
	jr nc, EGEnv_Eval_ValueCurve_WithFreqWriteCurve__FA7CAF                  ; FA7C82  jr NC,0xfa7caf
	cp	xiy, 0x3FFF                             ; FA7C84  cp XIY,0x00003fff
	jr ule, EGEnv_Eval_ValueCurve_WithFreqWriteCurve__FA7C91                 ; FA7C8A  jr ULE,0xfa7c91
	ld	xix, 0x3FFF                             ; FA7C8C  ld XIX,0x00003fff
EGEnv_Eval_ValueCurve_WithFreqWriteCurve__FA7C91:
	extz	xhl                                   ; FA7C91  extz XHL
	ld	c, (xhl)                                ; FA7C93  ld C,(XHL)
	and	c, 32                                  ; FA7C95  and C,0x20
	jr z, EGEnv_Eval_ValueCurve_WithFreqWriteCurve__FA7CA6                   ; FA7C98  jr Z,0xfa7ca6
	ld	bc, ix                                  ; FA7C9A  ld BC,IX
	set	15, bc                                 ; FA7C9C  set 0x0f,BC
	ld	(0xD798:24), bc                        ; FA7C9F  ld (0x00d798),BC
	jr EGEnv_Eval_ValueCurve_WithFreqWriteCurve__FA7CC3                      ; FA7CA4  jr T,0xfa7cc3
EGEnv_Eval_ValueCurve_WithFreqWriteCurve__FA7CA6:
	ld	bc, ix                                  ; FA7CA6  ld BC,IX
	ld	(0xD798:24), bc                        ; FA7CA8  ld (0x00d798),BC
	jr EGEnv_Eval_ValueCurve_WithFreqWriteCurve__FA7CC3                      ; FA7CAD  jr T,0xfa7cc3
EGEnv_Eval_ValueCurve_WithFreqWriteCurve__FA7CAF:
	cp	xix, 0x3FFF                             ; FA7CAF  cp XIX,0x00003fff
	jr ule, EGEnv_Eval_ValueCurve_WithFreqWriteCurve__FA7CBC                 ; FA7CB5  jr ULE,0xfa7cbc
	ld	xix, 0x3FFF                             ; FA7CB7  ld XIX,0x00003fff
EGEnv_Eval_ValueCurve_WithFreqWriteCurve__FA7CBC:
	ld	bc, ix                                  ; FA7CBC  ld BC,IX
	ld	(0xD79C:24), bc                        ; FA7CBE  ld (0x00d79c),BC
EGEnv_Eval_ValueCurve_WithFreqWriteCurve__FA7CC3:
	pop	xix                                    ; FA7CC3  pop XIX
	popw	de                                    ; FA7CC4  pop DE
	pop	xhl                                    ; FA7CC5  pop XHL
	unlk32 xiz                                 ; FA7CC6  unlk XIZ
	ret                                        ; FA7CC8  ret
; --------------------------------------------------------------------------
; ★ NAMED (wave 17): `VelCurve_Lookup` is now `VelCurve_Lookup`.
;   GRADE STRONG.  WHY `VelCurve_Lookup`:
;   body: `Table_FDD6AB[0x100 * ((b & 0xE0) >> 5) + Table_FDDDAB[a]]` -- one of
;   eight 256-entry curves.  All four callers are Voice_ComputeLevelBase_AB/_CD,
;   which pass Table_FDD5AB[velocity] as `a` and a tone-record byte as the bank,
;   then subtract 0xD0 and multiply by the tone's signed sensitivity byte.
; VelCurve_Lookup -- 0xFA7CC9..0xFA7D02 (58 bytes)
;
; Called from: 4 site(s) outside this module:
;          0xFAB5EE in sub_FAB5A5__FAB5CA, 0xFAB60C in sub_FAB5A5__FAB607
;          0xFAB711 in Voice_ComputeLevelBase_CD, 0xFAB72F in sub_FAB6D5__FAB72A
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA7CC9-0xFA7D02
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
VelCurve_Lookup:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA7CC9  link XIZ,0x0000
	push	xix                                   ; FA7CCD  push XIX
	ld	c, (xiz+10)                             ; FA7CCE  ld C,(XIZ+0x0a)
	and	c, 0xE0                                ; FA7CD1  and C,0xe0
	srl	c, 5                                   ; FA7CD4  srl 0x05,C
	extz	bc                                    ; FA7CD7  extz BC
	mul	bc, 0x100                              ; FA7CD9  mul BC,0x0100
	ld	xix, xbc                                ; FA7CDD  ld XIX,XBC
	ld	wa, (xiz+8)                             ; FA7CDF  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA7CE2  extz XWA
	add	xwa, 0xFDDDAB                          ; FA7CE4  add XWA,0x00fdddab
	ld	w, (xwa)                                ; FA7CEA  ld W,(XWA)
	extpfx3 0xC7, 0xF4, 0x98                   ; FA7CEC  ld IYL,W
	extz	iy                                    ; FA7CEF  extz IY
	extz	xiy                                   ; FA7CF1  extz XIY
	add	xbc, xiy                               ; FA7CF3  add XBC,XIY
	add	xbc, 0xFDD6AB                          ; FA7CF5  add XBC,0x00fdd6ab
	ld	a, (xbc)                                ; FA7CFB  ld A,(XBC)
	extz	wa                                    ; FA7CFD  extz WA
	pop	xix                                    ; FA7CFF  pop XIX
	unlk32 xiz                                 ; FA7D00  unlk XIZ
	ret                                        ; FA7D02  ret
; --------------------------------------------------------------------------
; ScaleClampedDelta_Shr5_b -- 0xFA7D03..0xFA7D48 (70 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFAB642 in sub_FAB5A5__FAB61F
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x0E), (XIZ+0x10)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA7D03-0xFA7D48
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  ⚠ 70 bytes BYTE-IDENTICAL, zero differing, to
;          ScaleClampedDelta_Shr5 at 0xFA766C -- a second copy of one function.
;          `python3 notes/prom_c_finish_round7.py --twins`.
;          So: v = (arg0 >> 8) & 0x7F, clamped to [(XIZ+0x0C), (XIZ+0x0E)], minus the
;          base at (XIZ+0x0A), times (XIZ+0x10), arithmetic-shifted right 5.
; --------------------------------------------------------------------------
ScaleClampedDelta_Shr5_b:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA7D03  link XIZ,0x0000
	pushw	hl                                   ; FA7D07  push HL
	pushw	de                                   ; FA7D08  push DE
	ld	de, (xiz+8)                             ; FA7D09  ld DE,(XIZ+0x08)
	and	de, 0x7F00                             ; FA7D0C  and DE,0x7f00
	ld	bc, de                                  ; FA7D10  ld BC,DE
	srl	bc, 8                                  ; FA7D12  srl 0x08,BC
	ld	de, bc                                  ; FA7D15  ld DE,BC
	ld	hl, (xiz+14)                            ; FA7D17  ld HL,(XIZ+0x0e)
	extz	hl                                    ; FA7D1A  extz HL
	cp	bc, hl                                  ; FA7D1C  cp BC,HL
	jr ule, sub_FA7D03__FA7D24                 ; FA7D1E  jr ULE,0xfa7d24
	ld	de, hl                                  ; FA7D20  ld DE,HL
	jr sub_FA7D03__FA7D2F                      ; FA7D22  jr T,0xfa7d2f
sub_FA7D03__FA7D24:
	ld	hl, (xiz+12)                            ; FA7D24  ld HL,(XIZ+0x0c)
	extz	hl                                    ; FA7D27  extz HL
	cp	de, hl                                  ; FA7D29  cp DE,HL
	jr nc, sub_FA7D03__FA7D2F                  ; FA7D2B  jr NC,0xfa7d2f
	ld	de, hl                                  ; FA7D2D  ld DE,HL
sub_FA7D03__FA7D2F:
	ld	bc, (xiz+10)                            ; FA7D2F  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FA7D32  extz BC
	ld	hl, de                                  ; FA7D34  ld HL,DE
	sub	hl, bc                                 ; FA7D36  sub HL,BC
	ld	bc, (xiz+16)                            ; FA7D38  ld BC,(XIZ+0x10)
	exts	bc                                    ; FA7D3B  exts BC
	muls	xbc, xhl                              ; FA7D3D  muls XBC,HL
	sra	bc, 5                                  ; FA7D3F  sra 0x05,BC
	ld	wa, bc                                  ; FA7D42  ld WA,BC
	popw	de                                    ; FA7D44  pop DE
	popw	hl                                    ; FA7D45  pop HL
	unlk32 xiz                                 ; FA7D46  unlk XIZ
	ret                                        ; FA7D48  ret
; --------------------------------------------------------------------------
; Clamp_0_to_00FF -- 0xFA7D49..0xFA7D69 (33 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFA7DCA
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFA7D49-0xFA7D69
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7).  Clamps a signed 16-bit argument to 0x0000..0x00FF and returns it in
;          WA.  `cp HL,0x00FF` at 0xFA7D51, `cp HL,0` at 0xFA7D5C.  Its one caller is
;          Voice_StageLevel_Reg0080, which uses the result as an index into a 256-entry
;          table -- so the bound and the table length agree.  notes/prom_c_dev10c_meaning_checks.py section 4.
; --------------------------------------------------------------------------
Clamp_0_to_00FF:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FA7D49  link XIZ,0x0000
	pushw	hl                                   ; FA7D4D  push HL
	ld	hl, (xiz+8)                             ; FA7D4E  ld HL,(XIZ+0x08)
	cp	hl, 0xFF                                ; FA7D51  cp HL,0x00ff
	jr le, Clamp_0_to_00FF__FA7D5C                  ; FA7D55  jr LE,0xfa7d5c
	ldw	wa, 0xFF                               ; FA7D57  ld WA,0x00ff
	jr Clamp_0_to_00FF__FA7D66                      ; FA7D5A  jr T,0xfa7d66
Clamp_0_to_00FF__FA7D5C:
	cps	hl, 0                                  ; FA7D5C  cp HL,0
	jr ge, Clamp_0_to_00FF__FA7D64                  ; FA7D5E  jr GE,0xfa7d64
	sub	wa, wa                                 ; FA7D60  sub WA,WA
	jr Clamp_0_to_00FF__FA7D66                      ; FA7D62  jr T,0xfa7d66
Clamp_0_to_00FF__FA7D64:
	ld	wa, hl                                  ; FA7D64  ld WA,HL
Clamp_0_to_00FF__FA7D66:
	popw	hl                                    ; FA7D66  pop HL
	unlk32 xiz                                 ; FA7D67  unlk XIZ
	ret                                        ; FA7D69  ret
; --------------------------------------------------------------------------
; Voice_StageLevel_Reg0080 -- 0xFA7D6A..0xFA7E2B (194 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFAB7D6 in sub_FAB79D__FAB7C6, 0xFAB80E in sub_FAB7E0__FAB80C
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: writes 0x00D762
; Calls:   0xFA7D49 = Clamp_0_to_00FF
; Voice record: touches voice_record[+0x06(r), +0x0F(r), +0x23(r), +0x25(r), +0x2F(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFA7D6A-0xFA7E2B
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★★ NAMED (round 7).  STAGES 0x0010C000 REGISTER `chan + 0x0080` -- THE OUTPUT LEVEL.
; Outputs: RAM 0x00D762 = staging word 2 of the struct at 0x00D75E.
; The value, field by field:
;          bits 11..0   2 * Voice_OutputLevel_Table[ idx ]      (0xFDDE2B, 256 u16)
;          bits 14..12  a 3-bit field: either (voice[+0x0F])[+0x02] & 0x70, shifted left 8,
;                       when bit 7 of that byte is set, or else
;                       Voice_Reg080_NoteField_Table[ voice[+0x06] >> 8 ]  (0xFDD2AB)
;          bit 15       NOT set here -- Dev10C_WriteAllChanRegs sets it on the way in and
;                       clears it on the way out, the 1-then-0 gate pulse.
;          and the three fields TILE the sixteen bits exactly: 2*T[255] = 0x0FF4 fits below
;          0x1000, and every entry of the note-field table is a multiple of 0x1000 below
;          0x8000.  (notes/prom_c_dev10c_meaning_checks.py sections 5, 6 and 7.)
;          idx = Clamp_0_to_00FF( part[+0x0B] + arg1 + part[+0x0E] + voice[+0x2F]
;                                 [+/- part[+0x2B]] )
;          with the +/- arm gated by (voice[+0x25])[+0x1A] & 0x0200 and signed by
;          (voice[+0x25])[+0x1C] & 0x0200.
; ★ WHY THIS IS THE LEVEL.  part[+0x0B] is what MidiCtrl_CC07 -- MIDI CHANNEL VOLUME --
;          writes, and part[+0x0E] is what MidiCtrl_CC11 -- EXPRESSION -- writes, both
;          through Voice_CC_VolumeCurve, which is a logarithmic attenuation of exactly 32
;          counts per halving.  Their sum indexes Voice_OutputLevel_Table, whose 256 entries
;          satisfy, with NO exception,
;              T[16e + m] = 128*e + round(128 * log2(1 + m/16))
;          i.e. the base-2 logarithm, 128 counts per octave, of the amplitude whose 4-bit
;          exponent and 4-bit mantissa are packed in the index.  Doubled by this routine,
;          that is 256 counts per octave of the register field, ~0.0235 dB per count, and a
;          span of about 48 dB.  Larger value = LOUDER: controller value 127 contributes 0
;          attenuation and lands at the top of the table.
;          That table is also byte-identical to the KN5000 sub-CPU's `Voice_OutputLevel_Table`
;          (see its own header) -- an independent project having named it the same thing.
; Evidence: 0xFA7D79 (the part-record pointer voice[+0x23]), 0xFA7D7E (+0x0B), 0xFA7D86
;          (+0x0E), 0xFA7DCA (the clamp), 0xFA7DD1 (the table), 0xFA7DD7-0xFA7DDC (the
;          doubling), 0xFA7E12 (the note-field table), 0xFA7E1A (the OR and the store).
;          notes/prom_c_dev10c_meaning_checks.py section 4.
; Unknown:  what the 3-bit field in bits 14..12 selects.  Its note-derived form is an
;          eight-step staircase over each octave and it does NOT depend on the level, so it
;          is a separate parameter sharing the register -- nothing here says which.
; --------------------------------------------------------------------------
Voice_StageLevel_Reg0080:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FA7D6A  link XIZ,0xfffc
	push	xhl                                   ; FA7D6E  push XHL
	push	xde                                   ; FA7D6F  push XDE
	pushw	ix                                   ; FA7D70  push IX
	ld	ix, (xiz+10)                            ; FA7D71  ld IX,(XIZ+0x0a)
	ld	de, (xiz+8)                             ; FA7D74  ld DE,(XIZ+0x08)
	extz	xde                                   ; FA7D77  extz XDE
	ld	de, (xde+35)                            ; FA7D79  ld DE,(XDE+0x23)
	extz	xde                                   ; FA7D7C  extz XDE
	ld	bc, (xde+11)                            ; FA7D7E  ld BC,(XDE+0x0b)
	add	bc, ix                                 ; FA7D81  add BC,IX
	ld	(xiz-2), bc                             ; FA7D83  ld (XIZ+0xfe),BC
	ld	wa, (xde+14)                            ; FA7D86  ld WA,(XDE+0x0e)
	add	bc, wa                                 ; FA7D89  add BC,WA
	ld	(xiz-4), bc                             ; FA7D8B  ld (XIZ+0xfc),BC
	ld	wa, (xiz+8)                             ; FA7D8E  ld WA,(XIZ+0x08)
	extz	xwa                                   ; FA7D91  extz XWA
	ld	iy, (xwa+47)                            ; FA7D93  ld IY,(XWA+0x2f)
	ld	ix, bc                                  ; FA7D96  ld IX,BC
	add	ix, iy                                 ; FA7D98  add IX,IY
	ld	hl, wa                                  ; FA7D9A  ld HL,WA
	extz	xwa                                   ; FA7D9C  extz XWA
	ld	hl, (xwa+37)                            ; FA7D9E  ld HL,(XWA+0x25)
	extz	xhl                                   ; FA7DA1  extz XHL
	ld	bc, (xhl+26)                            ; FA7DA3  ld BC,(XHL+0x1a)
	and	bc, 0x200                              ; FA7DA6  and BC,0x0200
	jr z, Voice_StageLevel_Reg0080__FA7DC9                   ; FA7DAA  jr Z,0xfa7dc9
	extz	xhl                                   ; FA7DAC  extz XHL
	ld	bc, (xhl+28)                            ; FA7DAE  ld BC,(XHL+0x1c)
	and	bc, 0x200                              ; FA7DB1  and BC,0x0200
	ld	(xiz-2), bc                             ; FA7DB5  ld (XIZ+0xfe),BC
	extz	xde                                   ; FA7DB8  extz XDE
	ld	hl, (xde+43)                            ; FA7DBA  ld HL,(XDE+0x2b)
	jr z, Voice_StageLevel_Reg0080__FA7DC5                   ; FA7DBD  jr Z,0xfa7dc5
	ld	bc, hl                                  ; FA7DBF  ld BC,HL
	sub	ix, bc                                 ; FA7DC1  sub IX,BC
	jr Voice_StageLevel_Reg0080__FA7DC9                      ; FA7DC3  jr T,0xfa7dc9
Voice_StageLevel_Reg0080__FA7DC5:
	ld	bc, hl                                  ; FA7DC5  ld BC,HL
	add	ix, bc                                 ; FA7DC7  add IX,BC
Voice_StageLevel_Reg0080__FA7DC9:
	pushw	ix                                   ; FA7DC9  push IX
	calr (0xFA7D49 - 0xFA7DCD)                 ; FA7DCA  calr 0xfa7d49
	muls	wa, 2                                 ; FA7DCD  muls WA,0x0002
	add	xwa, 0xFDDE2B                          ; FA7DD1  add XWA,0x00fdde2b
	ld	bc, (xwa)                               ; FA7DD7  ld BC,(XWA)
	ld	ix, bc                                  ; FA7DD9  ld IX,BC
	add	ix, ix                                 ; FA7DDB  add IX,IX
	ld	bc, (xiz+8)                             ; FA7DDD  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA7DE0  extz XBC
	ld	xwa, (xbc+15)                           ; FA7DE2  ld XWA,(XBC+0x0f)
	ld	h, (xwa+2)                              ; FA7DE5  ld H,(XWA+0x02)
	ld	a, h                                    ; FA7DE8  ld A,H
	and	a, 0x80                                ; FA7DEA  and A,0x80
	popw	iy                                    ; FA7DED  pop IY
	jr z, Voice_StageLevel_Reg0080__FA7E03                   ; FA7DEE  jr Z,0xfa7e03
	ld	a, h                                    ; FA7DF0  ld A,H
	extz	wa                                    ; FA7DF2  extz WA
	ld	hl, wa                                  ; FA7DF4  ld HL,WA
	and	wa, 0x70                               ; FA7DF6  and WA,0x0070
	ld	hl, wa                                  ; FA7DFA  ld HL,WA
	sll	wa, 8                                  ; FA7DFC  sll 0x08,WA
	ld	hl, wa                                  ; FA7DFF  ld HL,WA
	jr Voice_StageLevel_Reg0080__FA7E1A                      ; FA7E01  jr T,0xfa7e1a
Voice_StageLevel_Reg0080__FA7E03:
	ld	bc, (xiz+8)                             ; FA7E03  ld BC,(XIZ+0x08)
	extz	xbc                                   ; FA7E06  extz XBC
	ld	wa, (xbc+6)                             ; FA7E08  ld WA,(XBC+0x06)
	srl	wa, 8                                  ; FA7E0B  srl 0x08,WA
	mul	wa, 2                                  ; FA7E0E  mul WA,0x0002
	add	xwa, 0xFDD2AB                          ; FA7E12  add XWA,0x00fdd2ab
	ld	hl, (xwa)                               ; FA7E18  ld HL,(XWA)
Voice_StageLevel_Reg0080__FA7E1A:
	ld	bc, hl                                  ; FA7E1A  ld BC,HL
	or	bc, ix                                  ; FA7E1C  or BC,IX
	set	15, bc                                 ; FA7E1E  set 0x0f,BC
	ld	(0xD762:24), bc                        ; FA7E21  ld (0x00d762),BC
	popw	ix                                    ; FA7E26  pop IX
	pop	xde                                    ; FA7E27  pop XDE
	pop	xhl                                    ; FA7E28  pop XHL
	unlk32 xiz                                 ; FA7E29  unlk XIZ
	ret                                        ; FA7E2B  ret
