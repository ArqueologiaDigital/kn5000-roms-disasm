; =============================================================================
; v7: sound-parameter lookup code (NOT interrupt vectors, NOT the MIDI table)
; =============================================================================
; Until 2026-09-25 this file was titled "Interrupt Vector Trampolines" and said
; each 8-byte slot was a hardware interrupt vector.  That is false in every
; version (the CPU's vector table is at 0xFFFF00, boot/rom_end_structure.s; in
; v9/v10 this file holds the tail of the MIDI RX handler table).  In v7 the
; file's 525 bytes, 0xFCCC3D-0xFCCE49, are code: the bytes v10 carries at
; 0xFCD40E-0xFCD61A in audio/sndparam_routines.s (v10 = v7 + 0x7D1 all along
; this stretch; v7's file boundaries here sit 0x41A above their v10
; counterparts, see scripts/analysis/v7_label_drift.py on the audio lane).
; Ported from v10 by scripts/lanes/sys/port_islands.py --whole --delta 0x7d1
; (every line re-assembled to the v7 bytes; the 41 + 292 byte romslices and the
; partial decode between them are gone).  The two v7 labels are real entries
; and keep their v7 names because 18 and 8 other v7 files call them by those:
;   AcApcToggleProc_Helper      0xFCCC66, 343 calls = v10 SndParam_LookupReadOnly
;   DkMdlyPly_CheckState_Helper 0xFCCD26,  73 calls = v10 SndParam_LookupViaEncode
; The first 41 bytes are v10's SndParam_Lkp2_CallType1 .. SndParam_WrapNotify2
; (v10 0xFCD40E-0xFCD436).  Six local labels of the old decode were dropped
; (notes below mark where).

; (was .incbin "includes/romslices/v7_block_interrupt_vector_trampolines_head.bin")
interrupt_vector_trampolines_Skip:
	ld	wa, (xsp + 10)
	calr	Audio_ResetAfterPayloadError_Helper_Helper2
	jr	interrupt_vector_trampolines_Join
interrupt_vector_trampolines_Skip2:
	ldw	(xsp + 4), 0xffff
interrupt_vector_trampolines_Join:
	ld	hl, (xsp + 4)
	pop	xiz
	lda	xsp, (xsp + 10)
	ret
KeyScan_Disable_Helper:
	pushw	iz
	ld	iz, de
	calr	UIState_CheckAndRenderBitmap_Helper_Helper
	ld	xwa, xhl
	ld	bc, iz
	ld	de, (xsp+6)
	calr	MainTitle_PrepareAndDispatch_Helper
	popw	iz
	retd	2
AcApcToggleProc_Helper:
	dec	6, xsp
	push	xiz
	ldw	(xsp + 4), 0xffff
	ld	xiz, xwa
	ld	xwa, 0:i3
	ld	(xsp + 6), xwa
	ld	xhl, xiz
	and	xhl, 0xff
	ld	xwa, xhl
	sll	xwa, 9
	add	xwa, xhl
	ld	xhl, xiz
	srl	xhl, 8
	and	xhl, 0xff
	add	xhl, xwa
	ld	xwa, xhl
	sll	xwa, 9
	add	xwa, xhl
	ld	xhl, xiz
	srl	xhl, 16
	and	xhl, 0x1f
	add	xhl, xwa
	ld	xwa, xhl
	ld	xbc, 0x7ff
	call	FDC_SetupSectorParams_Helper
	ld	ix, hl
	jr	AcApcToggleProc_Helper_Join2
; (v7 label .Lc_fcccb4 stood here; dropped, see the file header)
AcApcToggleProc_Helper_Loop:
	ld	bc, 0:i3
	cp	xiz, xde
	jr	z, AcApcToggleProc_Helper_Skip
	ldw	bc, 0xffff
	jr	AcApcToggleProc_Helper_Join
; (v7 label .Lc_fcccbf stood here; dropped, see the file header)
AcApcToggleProc_Helper_Skip:
	cp	bc, 0xffff
	jr	z, AcApcToggleProc_Helper_Join
	ld	xwa, (xwa + 4)
	ld	(xsp + 6), xwa
; (v7 label .Lc_fccccb stood here; dropped, see the file header)
AcApcToggleProc_Helper_Join:
	inc	1, hl
	cp	hl, 0x7ff
	jr	ugt, AcApcToggleProc_Helper_Skip2
	ld	wa, ix
	inc	3, wa
	extz	xwa
	div	wa, 0x7ff
	ldto_werp	IX, 0xe2
; (v7 label .Lc_fccce0 stood here; dropped, see the file header)
AcApcToggleProc_Helper_Join2:
	ld	bc, ix
	extz	xbc
	sll	xbc, 3
	ld	xwa, 0x34100
	add	xwa, xbc
	ld	xde, (xwa)
	cp	xde, NakaData_RomEnd
	jr	nz, AcApcToggleProc_Helper_Loop
; (v7 label .Lc_fcccf8 stood here; dropped, see the file header)
AcApcToggleProc_Helper_Skip2:
	ld	xwa, (xsp + 6)
	or	xwa, xwa
	jr	z, AcApcToggleProc_Helper_Skip3
	ld	a, (xwa + 12)
	cp	a, 7:i3
	jr	nc, AcApcToggleProc_Helper_Skip3
	extz	wa
	sla	wa, 2
	lda	xbc, (Naka_MainDispatch_Table_0xDC0:24)
	lda	xbc, (xbc+wa)
	ld	xwa, (xsp + 6)
	ld	xhl, (xbc)
	call	(xhl)
	ld	(xsp + 4), hl
; (v7 label .Lc_fccd1f stood here; dropped, see the file header)
AcApcToggleProc_Helper_Skip3:
	ld	hl, (xsp + 4)
	pop	xiz
	inc	6, xsp
	ret
; (was .incbin "includes/romslices/v7_block_interrupt_vector_trampolines_tail.bin")
DkMdlyPly_CheckState_Helper:
	calr	UIState_CheckAndRenderBitmap_Helper_Helper
	ld	xwa, xhl
	jrl	AcApcToggleProc_Helper
GroupBoxProc_StartSSFPresentation_Helper:
	lda	xsp, (xsp - 22)
	push	xiz
	ld	(xsp + 14), xde
	ld	(xsp + 18), xbc
	ld	(xsp + 22), xwa
	ld	xbc, (xsp + 22)
	lda	xwa, (xbc + 2)
	ld	(xsp + 10), xwa
	ld	a, (xwa)
	extz	wa
	ld	(xsp + 4), wa
	ld	e, (xbc)
	ld	xwa, xbc
	ld	c, (xwa + 1)
	inc	3, xwa
	ld	(xsp + 6), xwa
	ld	a, (xwa)
	extz	de
	extz	bc
	extz	wa
	ld	l, e
	ld	e, a
	ld	b, 0x0:opc
	extz	xbc
	sll	xbc, 8
	ld	h, 0x0:opc
	extz	xhl
	sll	xhl, 16
	or	xhl, xbc
	ld	d, 0x0:opc
	extz	xde
	ld	xiz, xde
	or	xiz, xhl
	ld	xde, xiz
	srl	xde, 8
	ld	xhl, xde
	and	xhl, 0xf
	ld	xwa, xhl
	sll	xwa, 9
	add	xwa, xhl
	ld	xhl, xde
	srl	xhl, 4
	and	xhl, 0xf
	add	xhl, xwa
	ld	xwa, xhl
	sll	xwa, 9
	add	xwa, xhl
	ld	xhl, xde
	srl	xhl, 8
	and	xhl, 0xf
	add	xhl, xwa
	ld	xbc, xhl
	sll	xbc, 9
	add	xbc, xhl
	srl	xde, 12
	ld	xhl, xde
	and	xhl, 0xf
	add	xhl, xbc
	ld	xwa, xhl
	ld	xbc, 0x7ff
	call	FDC_SetupSectorParams_Helper
	sll	hl, 2
	lda	xwa, (0x973c:16)
	extz	xhl
	add	xhl, xwa
	ld	xde, (xhl)
	or	xde, xde
	jrl	z, EmptyRoutine_03_Skip2
	ld	xix, (xde)
	ldw	hl, 0xffff
	ld	xwa, xix
	srl	xwa, 8
	ld	xbc, xiz
	srl	xbc, 8
	cp	xbc, xwa
	jr	nz, DkMdlyPly_CheckState_Helper_Skip2
	ld	xwa, xiz
	srl	xwa, 16
	cp	xwa, 0xb1
	jr	z, DkMdlyPly_CheckState_Helper_Skip
	ld	xwa, xix
	and	xwa, 0xff
	and	xwa, xiz
	and	xwa, 0xff
	jr	z, DkMdlyPly_CheckState_Helper_Skip2
DkMdlyPly_CheckState_Helper_Skip:
	ld	hl, 0:i3
	jr	SndParam_RW_FoundCallback_v7
DkMdlyPly_CheckState_Helper_Skip2:
	cp	hl, 0xffff
	jr	nz, SndParam_RW_FoundCallback_v7
	ld	xwa, (xde + 8)
	or	xwa, xwa
	jr	z, EmptyRoutine_03_Skip2
DkMdlyPly_CheckState_Helper_Loop:
	ld	xde, (xde + 8)
	ld	xix, xiz
	ld	xiy, (xde)
	ldw	hl, 0xffff
	ld	xwa, xiy
	srl	xwa, 8
	cp	xbc, xwa
	jr	nz, SndParam_RW_ChainCheckFirst_v7
	ld	xwa, xix
	srl	xwa, 16
	cp	xwa, 0xb1
	jr	z, EmptyRoutine_03_Skip
	ld	xwa, xiy
	.byte	0xe8, 0xcc, 0xff, 0x00
