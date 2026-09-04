; ==========================================================================
; Sequencer Step Recording/Editing Routines
;
; Handles step-mode sequencer input, note event processing, and
; memory allocation for sequencer data. Used when recording in
; step mode (as opposed to real-time recording).
;
; Key routines:
;   SeqStep_NoteDispatch    - Dispatch incoming note events in step mode
;   SeqStep_NoteReadEvent   - Read and process a note event
;   SeqStep_EventProcess    - Process sequencer events
;   SeqStep_MemAllocReturn  - Memory allocation for step data
; ==========================================================================

SeqStep_NoteDispatch:
	dec 4, xsp
	push xiz
	bit 0, (0x287b:16)
	jrl z, SeqStep_NoteExit
	ldmw2 (xsp + 4), 0x28af
	ldmw2 (xsp + 6), 0x2666

SeqStep_NoteReadEvent:
	ldmm16 9830, 0x273e
	ldmm16 0x28af, 0x273c
	call SeqData_ReadNextByte
	ld a, l
	cp l, 0xd2
	jrl z, SeqStep_NoteSetD2
	cp l, 0xd3
	jrl z, SeqStep_NoteSetD1
	cp l, 0xd1
	jr z, SeqStep_NoteSetD1
	cp l, 0xd0
	jr z, SeqStep_NoteSetD1
	extz wa
	sub wa, 0x80
	cps wa, 0
	jr lt, SeqStep_NoteSetOther
	cps wa, 6
	jr gt, SeqStep_NoteSetOther
	add wa, wa
	lda xix, (Display_FontPalette_Table_0x7E:24)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda xix, (SeqStep_NoteByteBlock:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

SeqStep_NoteByteBlock:
	ld	a, (0x271c:16)
	and	a, 255
	extz	wa
	ld	(9830:16), wa
	ld	xwa, (0x2722:16)
	ld	(0x28af:16), wa
	call	SeqData_ReadNextByte
	ld	(9686:16), l
	ldw	wa, 129
	call	PartCtrl_WriteByte_Indexed
	cp	(9686:16), 129
	jr	z, 73
	call	SeqData_AdvancePosition
	cp	(0x287a:16), 0
	jr	nz, 62
	.byte 0xc1, 0xd6, 0x25, 0x19, 0xd8, 0x25
	call	SeqData_ReadNextByte
	ld	(9686:16), l
	ld	a, (9688:16)
	extz	wa
	jr	-44
	ldib_erp	249, 0
	jr	18
	ldib_erp	249, 1
	jr	13

SeqStep_NoteSetD1:
	ldib_erp 0xf9, 2
	jr SeqStep_NoteConsumeInit

SeqStep_NoteSetD2:
	ldib_erp 0xf9, 3
	jr SeqStep_NoteConsumeInit

SeqStep_NoteSetOther:
	ldib_erp 0xf9, 5

SeqStep_NoteConsumeInit:
	ldib_erp 0xfb, 0

SeqStep_NoteConsumeLoop:
	ldib_erp 0xfa, 0
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr z, SeqStep_NoteConsumeAdvance
	mrdw5 0x9f, 0x04, 0x19, 0xaf, 0x28
	mrdw5 0x9f, 0x06, 0x19, 0x66, 0x26
	jrl SeqStep_NoteExit

SeqStep_NoteConsumeAdvance:
	inc1b_erp 0xfb
	stb_erp A, 0xf9
	cpb_erp A, 0xfb
	jr nz, SeqStep_NoteCheckVel
	call SeqData_AdvancePosition
	ldmm16 0x273c, 0x28af
	ldmm16 0x273e, 9830
	jrl SeqStep_NoteReadEvent

SeqStep_NoteCheckVel:
	cpib_erp 0xfb, 1
	jr nz, SeqStep_NoteVelContinue
	call SeqData_ReadNextByte
	cp l, 0x5f
	jr ule, SeqStep_NoteVelSkip
	ld a, (9824:16)
	bit 0, a
	jr nz, SeqStep_NoteVelSave
	ld wa, (0x273e:16)
	ldb w, 0x0
	ld (0x271c:16), a
	ld wa, (0x273c:16)
	extz xwa
	ld (0x2722:16), xwa
	ld a, (9824:16)
	set 0, a
	ld (9824:16), a

SeqStep_NoteVelSave:
	call SeqData_ReadNextByte
	sub l, 0x60
	extz hl
	ld wa, hl
	call PartCtrl_WriteByte_Indexed
	stb_erp A, 0xfb
	cpb_erp A, 0xf9
	jr z, SeqStep_NoteReturn
	cpib_erp 0xfa, 1
	jrl nz, SeqStep_NoteConsumeLoop
	jrl SeqStep_NoteReadEvent

SeqStep_NoteVelSkip:
	stb_erp A, 0xfb
	cpb_erp A, 0xf9
	jr z, SeqStep_NoteReturn

SeqStep_NoteVelContinue:
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr z, SeqStep_NoteExitRestore

SeqStep_NoteExit:
	pop xiz
	inc 4, xsp
	ret

SeqStep_NoteExitRestore:
	inc1b_erp 0xfb
	stb_erp A, 0xfb
	cpb_erp A, 0xf9
	jr nz, SeqStep_NoteCheckVel

SeqStep_NoteReturn:
	call SeqData_AdvancePosition
	ldmm16 0x273c, 0x28af
	ldmm16 0x273e, 9830
	ldib_erp 0xfa, 1
	jrl SeqStep_NoteReadEvent

SeqStep_EventProcess:
	dec 6, xsp
	push xiz
	ld (xsp + 8), bc
	ld iz, wa
	ld (0x271e:16), 0
	ldmw2 (xsp + 6), 0x28af
	ldmw2 (xsp + 4), 0x2666
	ldmm16 0x28af, 0x273c
	ldmm16 9830, 0x273e
	call SeqPos_DecrementAndCheck
	lda xbc, (0x2830:16)
	ld wa, (0x28af:16)
	ld (xbc), wa
	ldmw2 (xbc + 2), 0x2666
	ldmm16 0x28af, 0x273c
	ldmm16 9830, 0x273e
	ld a, (0x287a:16)
	cps a, 0
	jr z, SeqStep_EventPosManage
	cp a, 0xa
	jrl nz, SeqStep_EventExit
	ld (0x287a:16), 0
	cpw (9778:16), 1
	jr nz, SeqStep_EventPosManage
	cps iz, 0
	jr nz, SeqStep_EventPosManage
	cpw (xsp + 8), 0x0
	jr nz, SeqStep_EventPosManage
	ld (0x271e:16), 1

SeqStep_EventPosManage:
	ld (9824:16), 0
	ld (9826:16), 0
	bit 0, (0x287b:16)
	jrl nz, SeqStep_EventPosConsumeAdvance
	jrl SeqStep_EventExit
	bit 0, (9824:16)
	jr z, SeqStep_EventPosCheck
	bit 0, (9826:16)
	call_24 z, SeqStep_DecrementPos

SeqStep_EventPosCheck:
	ld xwa, (0x2722:16)
	ld (0x288b:16), wa
	ld a, (0x271c:16)
	and a, 0xff
	extz wa
	ld (0x2889:16), wa
	lda xwa, (0x2830:16)
	mriw4 0x90, 0x19, 0x87, 0x28
	mrdw5 0x98, 0x02, 0x19, 0x85, 0x28

SeqStep_EventPosUpdate:
	ld wa, (0x288b:16)
	cp wa, (0x2726:16)
	jr nz, SeqStep_EventPosAdvance
	ld a, (0x2720:16)
	extz wa
	cp wa, (0x2889:16)
	jr nz, SeqStep_EventPosAdvance
	call SeqPart_ReadByte_Secondary
	extz hl
	ld wa, hl
	call SeqPart_WriteByte_Primary
	ldmm16 0x28af, 0x2726
	ld a, (0x2720:16)
	extz wa
	ld (9830:16), wa
	ldw wa, 0x81
	call PartCtrl_WriteByte_Indexed
	jrl SeqStep_EventExit

SeqStep_EventPosAdvance:
	call SeqPart_ReadByte_Secondary
	extz hl
	ld wa, hl
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceReadPos
	call PartCtrl_AdvanceToNextEntry
	cp (0x287a:16), 0
	jr z, SeqStep_EventPosUpdate
	jrl SeqStep_EventExit
	ldib_erp 0xfa, 0
	jr SeqStep_EventPosSetNote
	ldib_erp 0xfa, 1
	jr SeqStep_EventPosSetNote

SeqStep_EventPosSetD1:
	ldib_erp 0xfa, 2
	jr SeqStep_EventPosSetNote

SeqStep_EventPosSetD2:
	ldib_erp 0xfa, 3
	jr SeqStep_EventPosSetNote

SeqStep_EventPosSetD3:
	ldib_erp 0xfa, 5

SeqStep_EventPosSetNote:
	ldib_erp 0xf9, 0

SeqStep_EventPosConsumeLoop:
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jrl nz, SeqStep_EventExit
	inc1b_erp 0xf9
	stb_erp A, 0xfa
	cpb_erp A, 0xf9
	jr nz, SeqStep_EventPosReturn

SeqStep_EventPosConsumeCheck:
	call SeqData_AdvancePosition
	ldmm16 0x273c, 0x28af
	ldmm16 0x273e, 9830

SeqStep_EventPosConsumeAdvance:
	ldmm16 0x28af, 0x273c
	ldmm16 9830, 0x273e
	call SeqData_ReadNextByte
	ld a, l
	cp l, 0xd2
	jr z, SeqStep_EventPosSetD2
	cp l, 0xd3
	jr z, SeqStep_EventPosSetD1
	cp l, 0xd1
	jr z, SeqStep_EventPosSetD1
	cp l, 0xd0
	jr z, SeqStep_EventPosSetD1
	extz wa
	sub wa, 0x80
	cps wa, 0
	jr lt, SeqStep_EventPosSetD3
	cps wa, 6
	jr gt, SeqStep_EventPosSetD3
	add wa, wa
	lda xix, (Display_FontPalette_Table_0x8C:24)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda xix, (SeqStep_EventPosFinish:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

SeqStep_EventPosFinish:
	bit	0, (0x271e:16)
	jrl	z, -285
	jr	56

SeqStep_EventPosReturn:
	ldib_erp 0xfb, 0

SeqStep_EventPosExit:
	cpib_erp 0xf9, 1
	jr nz, SeqStep_EventPosDone
	call SeqData_ReadNextByte
	bit 7, l
	jr nz, SeqStep_EventStorePos
	cp l, 0x5f
	jr ugt, SeqStep_EventStorePos
	bit 0, (9824:16)
	jr z, SeqStep_EventPosComplete
	bit 0, (9826:16)
	call_24 z, SeqStep_DecrementPos

SeqStep_EventPosComplete:
	stb_erp A, 0xf9
	cpb_erp A, 0xfa
	jr z, SeqStep_EventRestore

SeqStep_EventPosDone:
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr z, SeqStep_EventCleanup

SeqStep_EventExit:
	mrdw5 0x9f, 0x06, 0x19, 0xaf, 0x28
	mrdw5 0x9f, 0x04, 0x19, 0x66, 0x26
	pop xiz
	inc 6, xsp
	ret

SeqStep_EventCleanup:
	inc1b_erp 0xf9
	stb_erp A, 0xf9
	cpb_erp A, 0xfa
	jr nz, SeqStep_EventPosExit

SeqStep_EventRestore:
	call SeqData_AdvancePosition
	ldmm16 0x273c, 0x28af
	ldmm16 0x273e, 9830
	ldib_erp 0xfb, 1
	jrl SeqStep_EventPosConsumeAdvance

SeqStep_EventStorePos:
	cpib_erp 0xfb, 1
	jrl z, SeqStep_EventPosConsumeAdvance
	ld a, (9824:16)
	bit 0, a
	jr nz, SeqStep_EventSetState
	ld wa, (0x273e:16)
	ld (0x271c:16), a
	ld wa, (0x273c:16)
	extz xwa
	ld (0x2722:16), xwa
	ld a, (9824:16)
	set 0, a
	ld (9824:16), a

SeqStep_EventSetState:
	ldb l, 0x0
	bit 0, (0x271e:16)
	jr nz, SeqStep_EventAdvancePos
	call SeqData_ReadNextByte
	add l, 0x60

SeqStep_EventAdvancePos:
	extz hl
	ld wa, hl
	call PartCtrl_WriteByte_Indexed
	stb_erp A, 0xf9
	cpb_erp A, 0xfa
	jrl z, SeqStep_EventPosConsumeCheck
	jrl SeqStep_EventPosConsumeLoop

SeqStep_VelNoteFwd:
	ld wa, (9778:16)
	cps wa, 1
	ret z
	ld c, (9780:16)
	ld (0x287f:16), wa
	extz bc
	ld wa, bc
	lds bc, 0
	call SeqVoice_SeekToBar
	cp (0x287a:16), 0
	ret nz
	calr SeqStep_WalkWithCallback
	cps hl, 0
	jr nz, SeqStep_VelNoteFwdApply
	ldmm16 0x28af, 0x28bf
	ldmm16 9830, 0x28c1
	call SeqData_AdvancePosition

SeqStep_VelNoteFwdApply:
	ldmm16 0x273e, 9830
	ldmm16 0x273c, 0x28af
	jrl SeqStep_MeasureRead

SeqStep_VelNoteBwd:
	ld c, (9780:16)
	inc 1, wa
	ld (0x287f:16), wa
	extz bc
	ld wa, bc
	lds bc, 0
	call SeqVoice_SeekToBar
	cp (0x287a:16), 0
	ret nz
	ldmm16 0x273c, 0x28af
	ldmm16 0x273e, 9830
	jrl SeqStep_MeasureRead

SeqStep_DeleteEvent:
	dec 4, xsp
	push xiz
	ldmw2 (xsp + 4), 0x28af
	ldmw2 (xsp + 6), 0x2666
	ld a, (9740:16)
	bit 7, a
	jrl nz, SeqStep_DeletePopReturn
	bit 0, (0x287b:16)
	jrl nz, SeqStep_DeleteDone
	calr SeqStep_InsertEvent
	jrl SeqStep_DeleteExitRestore
	ldib_erp 0xfa, 0
	jr SeqStep_DeleteConsumeInit
	ldib_erp 0xfa, 1
	jr SeqStep_DeleteConsumeInit

SeqStep_DeleteSetD1:
	ldib_erp 0xfa, 2
	jr SeqStep_DeleteConsumeInit

SeqStep_DeleteSetD2:
	ldib_erp 0xfa, 3
	jr SeqStep_DeleteConsumeInit

SeqStep_DeleteSetOther:
	ldib_erp 0xfa, 5

SeqStep_DeleteConsumeInit:
	lds iz, 0

SeqStep_DeleteConsumeLoop:
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jrl nz, SeqStep_DeleteExitRestore
	inc 1, iz
	stb_erp A, 0xfa
	extz wa
	cp wa, iz
	jr z, SeqStep_DeleteCleanup
	ldib_erp 0xfb, 0

SeqStep_DeleteConsumeAdvance:
	cps iz, 1
	jr nz, SeqStep_DeleteExit
	call SeqData_ReadNextByte
	cp l, 0x5f
	jr ule, SeqStep_DeleteReturn
	ld a, (9824:16)
	bit 0, a
	jr nz, SeqStep_DeleteFinish
	ld wa, (0x273e:16)
	ldb w, 0x0
	ld (0x271c:16), a
	ld wa, (0x273c:16)
	extz xwa
	ld (0x2722:16), xwa
	ld a, (9824:16)
	set 0, a
	ld (9824:16), a

SeqStep_DeleteFinish:
	ldw wa, 0x5f
	call PartCtrl_WriteByte_Indexed
	stb_erp A, 0xfa
	extz wa
	cp wa, iz
	jr z, SeqStep_DeleteCheck

SeqStep_DeleteReturn:
	stb_erp A, 0xfa
	extz wa
	cp wa, iz
	jr nz, SeqStep_DeleteConsumeAdvance

SeqStep_DeleteCheck:
	ldib_erp 0xfb, 1
	jrl SeqStep_DeleteExitRestore

SeqStep_DeleteExit:
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr nz, SeqStep_DeleteExitRestore
	inc 1, iz
	stb_erp A, 0xfa
	extz wa
	cp wa, iz
	jr nz, SeqStep_DeleteConsumeAdvance
	cpib_erp 0xfb, 0
	jrl z, SeqStep_DeleteConsumeLoop

SeqStep_DeleteCleanup:
	cpib_erp 0xfb, 0
	jr nz, SeqStep_DeleteExitRestore
	call SeqData_AdvancePosition
	ldmm16 0x273c, 0x28af
	ldmm16 0x273e, 9830

SeqStep_DeleteDone:
	ldmm16 9830, 0x273e
	ldmm16 0x28af, 0x273c
	call SeqData_ReadNextByte
	ld a, l
	cp l, 0xd2
	jrl z, SeqStep_DeleteSetD2
	cp l, 0xd3
	jrl z, SeqStep_DeleteSetD1
	cp l, 0xd1
	jrl z, SeqStep_DeleteSetD1
	cp l, 0xd0
	jrl z, SeqStep_DeleteSetD1
	extz wa
	sub wa, 0x80
	cps wa, 0
	jrl lt, SeqStep_DeleteSetOther
	cps wa, 6
	jrl gt, SeqStep_DeleteSetOther
	add wa, wa
	lda xix, (Display_FontPalette_Table_0x9A:24)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda xix, (SeqStep_DeleteExitRestore:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

SeqStep_DeleteExitRestore:
	mrdw5 0x9f, 0x04, 0x19, 0xaf, 0x28
	mrdw5 0x9f, 0x06, 0x19, 0x66, 0x26

SeqStep_DeletePopReturn:
	pop xiz
	inc 4, xsp
	ret

SeqStep_TrackChange:
	dec 4,XSP
	push XIZ
	ld (0x7ea6:16), 0x23
	ld c, (0x270c:16)
	cp C,0x11
	jr nz, SeqStep_TrackChangeCheck
	ld c, (0x270a:16)
	cp c, (0x2708:16)
	jrl z, SeqStep_TrackChangeExit
	ld a, (0x2878:16)
	st_erpb_rr a, 0xfb
	dec 1,C
	ld (0x2878:16), c
	call SeqVoice_InitAllChannelParams
	ld_erpb_rr a, 0xfb
	ld (0x2878:16), a
	calr SeqStep_MultiTrackProcess
	jrl t, SeqStep_TrackChangeExit
SeqStep_TrackChangeCheck:
	ld e, (9992:16)
	cp e, (9994:16)
	jr nz, SeqStep_TrackChangeCompare
	cp c, (9998:16)
	jrl z, SeqStep_TrackChangeExit

SeqStep_TrackChangeCompare:
	ld a, e
	dec 1, a
	cp a, (0xffe3:24)
	jr nz, SeqStep_TrackChangeClear
	ldib_erp 0xfa, 0
	jr SeqStep_TrackChangeSetup

SeqStep_TrackChangeClear:
	ldb_erp E, 0xfa

SeqStep_TrackChangeSetup:
	stb_erp A, 0xfa
	extz wa
	extz bc
	call Part_ReadSubBlock32
	ldb_erp L, 0xf9
	cp_erpb 0xf9, 0x0d
	jr z, SeqStep_TrackChangeDrum
	cp_erpb 0xf9, 0x0e
	jr z, SeqStep_TrackChangeDrum
	cp_erpb 0xf9, 0x0f
	jr z, SeqStep_TrackChangeDrum
	cp_erpb 0xf9, 0x10
	jr nz, SeqStep_TrackChangeNonDrum

SeqStep_TrackChangeDrum:
	ld c, (9994:16)
	ld a, c
	dec 1, a
	cp a, (0xffe3:24)
	jr nz, SeqStep_TrackChangeDrumClear
	ldib_erp 0xfa, 0
	jr SeqStep_TrackChangeDrumSetup

SeqStep_TrackChangeDrumClear:
	ldb_erp C, 0xfa

SeqStep_TrackChangeDrumSetup:
	stb_erp A, 0xfa
	extz wa
	ldw bc, 0xbd
	call Part_ReadByteDirect
	ldb_erp L, 0xfb
	cp_erpb 0xfb, 0xff
	jr nz, SeqStep_TrackChangeProcess
	ldw wa, 0x3a
	call SoundCtrl_SaveAndSendCmd_EE
	jrl SeqStep_TrackChangeExit

SeqStep_TrackChangeProcess:
	ld c, (9994:16)
	ld a, c
	dec 1, a
	cp a, (0xffe3:24)
	jr nz, SeqStep_TrackChangeStore
	ldib_erp 0xfa, 0
	jr SeqStep_TrackChangeUpdate

SeqStep_TrackChangeStore:
	ldb_erp C, 0xfa

SeqStep_TrackChangeUpdate:
	ldib_erp 0xfb, 1

SeqStep_TrackChangeAdvance:
	stb_erp A, 0xfa
	extz wa
	stb_erp C, 0xfb
	extz bc
	call Part_ReadSubBlock32
	stb_erp A, 0xf9
	cp a, l
	jr z, SeqStep_TrackChangeLoopBody
	cp_erpb 0xf9, 0x0e
	jr z, SeqStep_TrackChangeLoopCheck
	cp_erpb 0xf9, 0x0d
	jr nz, SeqStep_TrackChangeNext
	cp l, 0xe
	jr z, SeqStep_TrackChangeLoopBody

SeqStep_TrackChangeNext:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqStep_TrackChangeAdvance

SeqStep_TrackChangeNonDrum:
	cpw (0xf231:16), 0
	jr nz, SeqStep_TrackChangeLoopDone

SeqStep_TrackChangeLoop:
	ld	(32422:16), 15
	jrl	240
SeqStep_TrackChangeLoopCheck:
	cp l, 0xd
	jr nz, SeqStep_TrackChangeNext

SeqStep_TrackChangeLoopBody:
	ld a, (9998:16)
	cpb_erp A, 0xfb
	jr z, SeqStep_TrackChangeNonDrum
	ld a, (9994:16)
	dec 1, a
	ld (0x2710:16), a
	stb_erp A, 0xfb
	dec 1, a
	ld (0x271a:16), a
	calr SeqStep_BoundaryReturn
	stb_erp A, 0xfa
	extz wa
	stb_erp C, 0xfb
	extz bc
	lds de, 0
	call Part_WriteSubBlock32
	cpw (0xf231:16), 0
	jr z, SeqStep_TrackChangeLoop

SeqStep_TrackChangeLoopDone:
	ld a, (9994:16)
	dec 1, a
	ld (0x2710:16), a
	ld a, (9998:16)
	dec 1, a
	ld (0x271a:16), a
	calr SeqStep_BoundaryReturn
	ld c, (9992:16)
	ld a, c
	dec 1, a
	cp a, (0xffe3:24)
	jr nz, SeqStep_TrackChangeLoopReturn
	ldib_erp 0xfa, 0
	jr SeqStep_TrackChangeLoopExit

SeqStep_TrackChangeLoopReturn:
	ldb_erp C, 0xfa

SeqStep_TrackChangeLoopExit:
	stb_erp A, 0xfa
	extz wa
	ld c, (9996:16)
	extz bc
	call Part_ReadVoiceWord
	ld (xsp + 4), hl
	stb_erp A, 0xfa
	extz wa
	ld c, (9996:16)
	extz bc
	call Part_ReadVoiceBit7
	cps l, 0
	jrl z, SeqStep_TrackChangeRecoverDone
	cpw (xsp + 4), 0x0
	jrl z, SeqStep_TrackChangeRecoverDone
	cpw (xsp + 4), 0xffff
	jrl z, SeqStep_TrackChangeRecoverDone
	ld a, (9998:16)
	dec 1, a
	ld (0x2877:16), a
	calr SeqStep_DeleteShiftExit
	ld (xsp + 6), hl
	ld wa, (xsp + 4)
	dec 1, wa
	extz xwa
	sll xwa, 8
	inc 5, xwa
	lda xhl, (0x0b0000:24)
	ld xde, xhl
	add xde, xwa
	ld bc, (xsp + 6)
	dec 1, bc
	extz xbc
	sll xbc, 8
	inc 5, xbc
	add xhl, xbc
	ldib_erp 0xfb, 0

SeqStep_TrackChangeFinish:
	ldb_spi A, 0xe8
	lda_dpi XBC, 0xec
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0xfb
	jr c, SeqStep_TrackChangeFinish
	jrl SeqStep_TrackChangeWriteDone

SeqStep_TrackChangeComplete:
	cpw (0xf231:16), 0
	jr nz, SeqStep_TrackChangeFinal

SeqStep_TrackChangeValidate:
	ld	a, (9994:16)
	dec	1, a
	ld	(10000:16), a
	ld	a, (9998:16)
	dec	1, a
	ld	(10010:16), a
	calr	2668
	ld	(32422:16), 15
	jrl	448
SeqStep_TrackChangeFinal:
	call Part_ProcessAndDecrementVoice
	ldw_erp HL, 0xfa
	ld wa, (xsp + 6)
	stw_erp BC, 0xfa
	call PartCtrl_WriteWord
	ld iz, (xsp + 6)
	stw_erp BC, 0xfa
	ld wa, bc
	ld (xsp + 6), bc
	lds bc, 1
	call PartCtrl_SetClearBit7
	ld wa, (xsp + 6)
	ld bc, iz
	call PartCtrl_WriteWord_Off1
	ld wa, (xsp + 6)
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	mrdw5 0x9f, 0x06, 0x19, 0xaf, 0x28
	ld wa, (xsp + 4)
	dec 1, wa
	extz xwa
	sll xwa, 8
	inc 5, xwa
	lda xhl, (0x0b0000:24)
	ld xde, xhl
	add xde, xwa
	ld bc, (xsp + 6)
	dec 1, bc
	extz xbc
	sll xbc, 8
	inc 5, xbc
	add xhl, xbc
	ldib_erp 0xfb, 0

SeqStep_TrackChangeWriteBack:
	ldb_spi A, 0xe8
	lda_dpi XBC, 0xec
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0xfb
	jr c, SeqStep_TrackChangeWriteBack

SeqStep_TrackChangeWriteDone:
	ld wa, (xsp + 4)
	call PartCtrl_ReadWord
	ld (xsp + 4), hl
	cpw (xsp + 4), 0xffff
	jrl nz, SeqStep_TrackChangeComplete
	ld a, (9994:16)
	extz wa
	ld c, (0x2877:16)
	inc 1, c
	extz bc
	ld de, (0x28af:16)
	call Part_WriteWord_Indexed
	ld a, (9994:16)
	dec 1, a
	cp a, (0xffe3:24)
	jr nz, SeqStep_TrackChangeError
	ld c, (0x2877:16)
	inc 1, c
	extz bc
	ld de, (0x28af:16)
	lds wa, 0
	call Part_WriteWord_Indexed

SeqStep_TrackChangeError:
	ld c, (9992:16)
	ld a, c
	dec 1, a
	cp a, (0xffe3:24)
	jr nz, SeqStep_TrackChangeErrorExit
	ldib_erp 0xfa, 0
	jr SeqStep_TrackChangeRecover

SeqStep_TrackChangeErrorExit:
	ldb_erp C, 0xfa

SeqStep_TrackChangeRecover:
	stb_erp A, 0xfa
	extz wa
	ld c, (9996:16)
	extz bc
	call Part_ReadByte_Indexed
	ldb_erp L, 0xfb
	ld a, (9994:16)
	extz wa
	ld c, (0x2877:16)
	inc 1, c
	extz bc
	stb_erp E, 0xfb
	extz de
	call Part_WriteByte_Indexed
	ld a, (9994:16)
	dec 1, a
	cp a, (0xffe3:24)
	jr nz, SeqStep_TrackChangeRecoverDone
	ld c, (0x2877:16)
	inc 1, c
	extz bc
	stb_erp E, 0xfb
	extz de
	lds wa, 0
	call Part_WriteByte_Indexed

SeqStep_TrackChangeRecoverDone:
	ld c, (9992:16)
	ld a, c
	dec 1, a
	cp a, (0xffe3:24)
	jr nz, SeqStep_TrackChangeRecoverStore
	ldib_erp 0xfa, 0
	jr SeqStep_TrackChangeRecoverReturn

SeqStep_TrackChangeRecoverStore:
	ldb_erp C, 0xfa

SeqStep_TrackChangeRecoverReturn:
	stb_erp A, 0xfa
	extz wa
	ld c, (9996:16)
	extz bc
	call Part_ReadSubBlock32
	ldb_erp L, 0xfb
	ld a, (9994:16)
	extz wa
	ld c, (9998:16)
	extz bc
	stb_erp E, 0xfb
	extz de
	call Part_WriteSubBlock32
	ld a, (9994:16)
	dec 1, a
	cp a, (0xffe3:24)
	jr nz, SeqStep_TrackChangeRecoverAdvance
	ld c, (9998:16)
	extz bc
	stb_erp E, 0xfb
	extz de
	lds wa, 0
	call Part_WriteSubBlock32

SeqStep_TrackChangeRecoverAdvance:
	ld a, (9994:16)
	extz wa
	ldw bc, 0x1e
	call Part_ReadWord
	ld de, hl
	ld a, (9998:16)
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqStep_TrackChangeRecoverLoop
	slaa bc

SeqStep_TrackChangeRecoverLoop:
	or de, bc
	ld a, (9994:16)
	extz wa
	ldw bc, 0x1e
	call Part_WriteWord
	ld a, (9994:16)
	dec 1, a
	cp a, (0xffe3:24)
	jr nz, SeqStep_TrackChangeExit
	ld a, (9998:16)
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqStep_TrackChangeRecoverExit
	slaa bc

SeqStep_TrackChangeRecoverExit:
	ordm16_24 (0xffec), xbc

SeqStep_TrackChangeExit:
	pop xiz
	inc 4, xsp
	ret

SeqStep_MultiTrackProcess:
	lda xsp, (xsp - 22)
	push xiz
	ld (0x2877:16), 0

SeqStep_MultiTrackLoop:
	cpw (0xf231:16), 0
	jrl z, SeqStep_MultiTrackCleanup
	ld c, (9992:16)
	ld a, c
	dec 1, a
	cp a, (0xffe3:24)
	jr nz, SeqStep_MultiTrackCheck
	ldib_erp 0xf9, 0
	jr SeqStep_MultiTrackAdvance

SeqStep_MultiTrackCheck:
	ldb_erp C, 0xf9

SeqStep_MultiTrackAdvance:
	stb_erp A, 0xf9
	extz wa
	ld c, (0x2877:16)
	inc 1, c
	extz bc
	call Part_ReadVoiceBit7
	cps l, 0
	jrl z, SeqStep_PartCopyComplete
	stb_erp A, 0xf9
	extz wa
	ld c, (0x2877:16)
	inc 1, c
	extz bc
	call Part_ReadVoiceWord
	ld iz, hl
	cps iz, 0
	jrl z, SeqStep_PartCopyComplete
	cp iz, 0xffff
	jrl z, SeqStep_PartCopyComplete
	calr SeqStep_DeleteShiftExit
	ld (xsp + 4), hl
	ld wa, iz
	dec 1, wa
	extz xwa
	sll xwa, 8
	inc 5, xwa
	lda xhl, (0x0b0000:24)
	ld xde, xhl
	add xde, xwa
	ld bc, (xsp + 4)
	dec 1, bc
	extz xbc
	sll xbc, 8
	inc 5, xbc
	add xhl, xbc
	ldib_erp 0xfa, 0

SeqStep_MultiTrackInner:
	ldb_spi A, 0xe8
	lda_dpi XBC, 0xec
	inc1b_erp 0xfa
	cp_erpb 0xfa, 0xfb
	jr c, SeqStep_MultiTrackInner
	jrl SeqStep_PartCopyFinish

SeqStep_MultiTrackCopyCheck:
	cpw (0xf231:16), 0
	jr nz, SeqStep_PartCopy

SeqStep_MultiTrackCleanup:
	ld a, (0x2878:16)

	ldb_erp A, 0xfb

	ld a, (9994:16)

	dec 1, a

	ld (0x2878:16), a

	call	15988897

	stb_erp A, 0xfb

	ld (0x2878:16), a

	.byte 0xf1, 0xa6, 0x7e, 0x00, 0x0f	; stdi8 (0x7f42), 15 (v7 patched)

	.byte 0x78, 0x5a, 0x02	; jrl SeqStep_VoiceReassignFinalExit (v7 displacement)



SeqStep_PartCopy:
	call Part_ProcessAndDecrementVoice
	ldw_erp HL, 0xfa
	ld wa, (xsp + 4)
	stw_erp BC, 0xfa
	call PartCtrl_WriteWord
	stw_erp WA, 0xfa
	lds bc, 1
	call PartCtrl_SetClearBit7
	stw_erp WA, 0xfa
	ld bc, (xsp + 4)
	call PartCtrl_WriteWord_Off1
	stw_erp WA, 0xfa
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	stw_erp WA, 0xfa
	ld (xsp + 4), wa
	stw_erp WA, 0xfa
	ld (0x28af:16), wa
	ld wa, iz
	dec 1, wa
	extz xwa
	sll xwa, 8
	inc 5, xwa
	lda xhl, (0x0b0000:24)
	ld xde, xhl
	add xde, xwa
	stw_erp BC, 0xfa
	dec 1, bc
	extz xbc
	sll xbc, 8
	inc 5, xbc
	add xhl, xbc
	ldib_erp 0xfa, 0

SeqStep_PartCopyLoop:
	ldb_spi A, 0xe8
	lda_dpi XBC, 0xec
	inc1b_erp 0xfa
	cp_erpb 0xfa, 0xfb
	jr c, SeqStep_PartCopyLoop

SeqStep_PartCopyFinish:
	ld wa, iz
	call PartCtrl_ReadWord
	ld iz, hl
	cp iz, 0xffff
	jrl nz, SeqStep_MultiTrackCopyCheck
	ld a, (9994:16)
	extz wa
	ld c, (0x2877:16)
	inc 1, c
	extz bc
	ld de, (0x28af:16)
	call Part_WriteWord_Indexed
	ld a, (9994:16)
	dec 1, a
	cp a, (0xffe3:24)
	jr nz, SeqStep_PartCopyUpdateSrc
	ld c, (0x2877:16)
	inc 1, c
	extz bc
	ld de, (0x28af:16)
	lds wa, 0
	call Part_WriteWord_Indexed

SeqStep_PartCopyUpdateSrc:
	ld c, (9992:16)
	ld a, c
	dec 1, a
	cp a, (0xffe3:24)
	jr nz, SeqStep_PartCopyClearSrc
	ldib_erp 0xf9, 0
	jr SeqStep_PartCopySetupDest

SeqStep_PartCopyClearSrc:
	ldb_erp C, 0xf9

SeqStep_PartCopySetupDest:
	stb_erp A, 0xf9
	extz wa
	ld c, (0x2877:16)
	inc 1, c
	extz bc
	call Part_ReadByte_Indexed
	ldb_erp L, 0xfb
	ld a, (9994:16)
	extz wa
	ld c, (0x2877:16)
	inc 1, c
	extz bc
	stb_erp E, 0xfb
	extz de
	call Part_WriteByte_Indexed
	ld a, (9994:16)
	dec 1, a
	cp a, (0xffe3:24)
	jr nz, SeqStep_PartCopyComplete
	ld c, (0x2877:16)
	inc 1, c
	extz bc
	stb_erp E, 0xfb
	extz de
	lds wa, 0
	call Part_WriteByte_Indexed

SeqStep_PartCopyComplete:
	ld a, (0x2877:16)
	inc 1, a
	ld (0x2877:16), a
	cp a, 0x10
	jrl c, SeqStep_MultiTrackLoop
	ldib_erp 0xfa, 1

SeqStep_VoiceReassign:
	ld e, (9992:16)
	ld a, e
	dec 1, a
	stb_erp C, 0xfa
	extz bc
	cp a, (0xffe3:24)
	jr nz, SeqStep_VoiceReassignCheck
	lds wa, 0
	jr SeqStep_VoiceReassignSetup

SeqStep_VoiceReassignCheck:
	extz de
	ld wa, de

SeqStep_VoiceReassignSetup:
	call Part_ReadSubBlock32
	ldb_erp L, 0xfb
	ld a, (9994:16)
	extz wa
	stb_erp C, 0xfa
	extz bc
	stb_erp E, 0xfb
	extz de
	call Part_WriteSubBlock32
	ld a, (9994:16)
	dec 1, a
	cp a, (0xffe3:24)
	jr nz, SeqStep_VoiceReassignProcess
	stb_erp C, 0xfa
	extz bc
	stb_erp E, 0xfb
	extz de
	lds wa, 0
	call Part_WriteSubBlock32

SeqStep_VoiceReassignProcess:
	inc1b_erp 0xfa
	cp_erpb 0xfa, 0x10
	jr ule, SeqStep_VoiceReassign
	ld c, (9992:16)
	ld a, c
	dec 1, a
	cp a, (0xffe3:24)
	jr nz, SeqStep_VoiceReassignValidate
	ld de, (0x00ffec:24)
	jr SeqStep_VoiceReassignStore

SeqStep_VoiceReassignValidate:
	extz bc
	ld wa, bc
	ldw bc, 0x1e
	call Part_ReadWord
	ld de, hl

SeqStep_VoiceReassignStore:
	ld c, (9994:16)
	ld a, c
	dec 1, a
	cp a, (0xffe3:24)
	jr nz, SeqStep_VoiceReassignUpdate
	ld (0x00ffec:24), de
	jr SeqStep_VoiceReassignDone

SeqStep_VoiceReassignUpdate:
	extz bc
	ld wa, bc
	ldw bc, 0x1e
	call Part_WriteWord

SeqStep_VoiceReassignDone:
	ld c, (9992:16)
	ld a, c
	dec 1, a
	ld e, (0x00ffe3:24)
	cp a, e
	jr nz, SeqStep_VoiceReassignReturn
	ldib_erp 0xf9, 0
	jr SeqStep_VoiceReassignExit

SeqStep_VoiceReassignReturn:
	ldb_erp C, 0xf9

; === v7-specific block: SeqStep_VoiceReassignExit (120 bytes) ===
SeqStep_VoiceReassignExit:
	.incbin "includes/romslices/v7_block_seqstep_voicereassignexit.bin"
; === end v7 block ===
SeqStep_VoiceReassignFinalExit:
	pop xiz
	lda xsp, (xsp + 22)
	ret

SeqStep_EventAdvance:
	dec 2, xsp
	push xiz
	ldmw2 (xsp + 4), 0x28af
	ld iz, (9830:16)
	bit 0, (0x287b:16)
	jr z, SeqStep_EventAdvanceRead
	ldmm16 0x28af, 0x273c
	ldmm16 9830, 0x273e

SeqStep_EventAdvanceCheck:
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr z, SeqStep_EventAdvanceBit7

SeqStep_EventAdvanceLoop:
	mrdw5 0x9f, 0x04, 0x19, 0xaf, 0x28
	ld (9830:16), iz

SeqStep_EventAdvanceRead:
	pop xiz
	inc 2, xsp
	ret

SeqStep_EventAdvanceBit7:
	call SeqData_ReadNextByte
	cp l, 0x7f
	jr z, SeqStep_EventAdvanceDone

SeqStep_EventAdvanceStore:
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr nz, SeqStep_EventAdvanceLoop
	call SeqData_ReadNextByte
	bit 7, l
	jr z, SeqStep_EventAdvanceStore
	ldmm16 0x273c, 0x28af
	ldmm16 0x273e, 9830
	jr SeqStep_EventAdvanceCheck

SeqStep_EventAdvanceDone:
	ldmm16 9830, 0x273e
	ldmm16 0x28af, 0x273c
	call SeqData_ReadNextByte
	ldb_erp L, 0xfa
	ldw wa, 0x81
	call PartCtrl_WriteByte_Indexed

SeqStep_EventAdvanceReturn:
	cp_erpb 0xfa, 0x81
	jr z, SeqStep_EventAdvanceLoop

SeqStep_EventAdvanceError:
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr nz, SeqStep_EventAdvanceLoop
	stb_erp A, 0xfa
	ldb_erp A, 0xfb
	call SeqData_ReadNextByte
	ldb_erp L, 0xfa
	stb_erp A, 0xfb
	extz wa
	call PartCtrl_WriteByte_Indexed
	bit_erpb 0xfb, 0x07
	jr z, SeqStep_EventAdvanceReturn
	ldib_erp 0xfa, 0
	jr SeqStep_EventAdvanceError

SeqStep_MeasureRead:
	push xiz
	ld iz, (0x28af:16)
	ld wa, (9830:16)
	ldw_erp WA, 0xfa
	ld wa, (0x273c:16)
	ld (0x28af:16), wa
	ldmm16 9798, 0x273c
	ld wa, (0x273e:16)
	ld (9830:16), wa
	ldmm16 9796, 0x273e
	call SeqData_ReadNextByte
	cp l, 0x82
	jrl z, SeqStep_MeasureReadDone
	cp l, 0x81
	jrl z, SeqStep_MeasureReadDone
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jrl nz, SeqStep_MeasureReadDone
	call SeqData_ReadNextByte
	ld (9804:16), l
	ldmm16 9800, 9830
	ldmm16 9802, 0x28af
	calr SeqStep_AdvanceHelper1
	cp (0x287a:16), 0
	jr nz, SeqStep_MeasureReadDone
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, SeqStep_MeasureReadDone
	cp l, 0x81
	jr z, SeqStep_MeasureReadDone

SeqStep_MeasureReadLoop:
	ld a, (9804:16)
	cp a, (9806:16)
	jr ule, SeqStep_MeasureReadCheck
	calr SeqStep_DeleteShiftEvents
	cp (0x287a:16), 0
	jr nz, SeqStep_MeasureReadDone
	ldmm8 9804, 9806

SeqStep_MeasureReadCheck:
	calr SeqStep_AdvanceHelper1
	cp (0x287a:16), 0
	jr nz, SeqStep_MeasureReadDone
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, SeqStep_MeasureReadProcess
	cp l, 0x81
	jr nz, SeqStep_MeasureReadLoop

SeqStep_MeasureReadProcess:
	calr SeqStep_SkipToHighBit
	cp (0x287a:16), 0
	jr nz, SeqStep_MeasureReadDone
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, SeqStep_MeasureReadDone
	cp l, 0x81
	jr z, SeqStep_MeasureReadDone
	ldmm16 9800, 9830
	ldmm16 9802, 0x28af
	calr SeqStep_AdvanceHelper1
	cp (0x287a:16), 0
	jr nz, SeqStep_MeasureReadDone
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, SeqStep_MeasureReadDone
	cp l, 0x81
	jr nz, SeqStep_MeasureReadLoop

SeqStep_MeasureReadDone:
	ld (0x28af:16), iz
	stw_erp WA, 0xfa
	ld (9830:16), wa
	pop xiz
	ret

SeqStep_SkipToHighBit:
	ldmm16 9830, 9796
	ldmm16 0x28af, 9798
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	ret nz

SeqStep_SkipLoop:
	call SeqData_ReadNextByte
	bit 7, l
	jr nz, SeqStep_SkipCheck
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr z, SeqStep_SkipLoop
	ret

SeqStep_SkipCheck:
	call SeqData_ReadNextByte
	cp l, 0x82
	ret z
	cp l, 0x81
	jr nz, SeqStep_SkipDone
	ret

SeqStep_SkipDone:
	ldmm16 9796, 9830
	ldmm16 9798, 0x28af
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	ret nz
	call SeqData_ReadNextByte
	ld (9804:16), l
	ret

SeqStep_AdvanceHelper1:
	ldmm16 9830, 9800
	ldmm16 0x28af, 9802
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	ret nz

SeqStep_AdvanceHelper2:
	call SeqData_ReadNextByte
	bit 7, l
	jr nz, SeqStep_AdvanceHelper2Loop
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr z, SeqStep_AdvanceHelper2
	ret

SeqStep_AdvanceHelper2Loop:
	call SeqData_ReadNextByte
	cp l, 0x82
	ret z
	cp l, 0x81
	jr nz, SeqStep_AdvanceHelper2Done
	ret

SeqStep_AdvanceHelper2Done:
	ldmm16 9800, 9830
	ldmm16 9802, 0x28af
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	ret nz
	call SeqData_ReadNextByte
	ld (9806:16), l
	ret

SeqStep_DecrementPos:
	ld wa, (0x273e:16)
	cps wa, 5
	jr z, SeqStep_DecrementCheck
	dec 1, wa
	ld (0x2720:16), a
	ldmm16 0x2726, 0x273c
	jr SeqStep_DecrementStore

SeqStep_DecrementCheck:
	ld wa, (0x273c:16)
	call PartCtrl_ReadWord_Off1
	cps hl, 0
	ret z
	ld (0x2726:16), hl
	ld (0x2720:16), 255

SeqStep_DecrementStore:
	ld (9826:16), 1
	ret

SeqStep_WalkWithCallback:
	dec 2, xsp
	pushw_erp 0xfa
	ldib_erp 0xfb, 0
	ldmm16 0x28c1, 9830
	ldmm16 0x28bf, 0x28af

SeqStep_WalkCbLoop:
	lda xwa, (xsp + 2)
	calr SeqStep_WalkInner
	cps hl, 0
	jr z, SeqStep_WalkCbCheck81
	ldw hl, 0xffff
	jr SeqStep_WalkCbReturn

SeqStep_WalkCbCheck81:
	cp (xsp + 2), 0x81
	jr nz, SeqStep_WalkCbCountCheck
	inc1b_erp 0xfb

SeqStep_WalkCbCountCheck:
	cpib_erp 0xfb, 2
	jr nz, SeqStep_WalkCbLoop
	lds hl, 0

SeqStep_WalkCbReturn:
	popw_erp 0xfa
	inc 2, xsp
	ret

SeqStep_WalkInner:
	push xiz
	ld xiz, xwa

SeqStep_WalkInnerLoop:
	calr SeqStep_WalkReadNext
	cps hl, 0
	jr z, SeqStep_WalkInnerProcess
	ldw hl, 0xffff
	jr SeqStep_WalkInnerReturn

SeqStep_WalkInnerProcess:
	calr SeqStep_WalkReadByte
	ld (xiz), l
	bitm 7, (xiz)
	jr z, SeqStep_WalkInnerLoop
	lds hl, 0

SeqStep_WalkInnerReturn:
	pop xiz
	ret

SeqStep_WalkReadNext:
	ld wa, (0x28c1:16)
	cps wa, 5
	jr nz, SeqStep_WalkAdvancePos
	ld wa, (0x28bf:16)
	call PartCtrl_ReadWord_Off1
	cps hl, 0
	jr nz, SeqStep_WalkUpdatePos
	ldw hl, 0xffff
	ret

SeqStep_WalkUpdatePos:
	ld (0x28bf:16), hl
	ldw (0x28c1:16), 255
	jr SeqStep_WalkAdvanceDone

SeqStep_WalkAdvancePos:
	inc 1, wa
	ld (0x28c1:16), wa

SeqStep_WalkAdvanceDone:
	lds hl, 0
	ret

SeqStep_WalkReadByte:
	ld wa, (0x28c1:16)
	ld c, a
	extz bc
	ld wa, (0x28bf:16)
	jp PartCtrl_ReadByte

SeqStep_InsertEvent:
	calr SeqStep_PrepareReadBack
	cp l, 0x81
	ret z
	calr SeqStep_InsertEventInner
	ret

SeqStep_InsertEventInner:
	dec 2, xsp
	push xiz
	ldmw2 (xsp + 4), 0x28af
	ld iz, (9830:16)
	cp iz, 0xff
	jr z, SeqStep_InsertValidate
	ldw wa, 0x81
	call PartCtrl_WriteByte_Indexed
	incw 1, (9830:16)
	ldw wa, 0x82
	call PartCtrl_WriteByte_Indexed
	ld c, (9780:16)
	extz bc
	ld de, (9830:16)
	lds wa, 0
	jr SeqStep_InsertError

SeqStep_InsertValidate:
	cpw (0xf231:16), 0
	jr z, SeqStep_InsertDone
	ldw wa, 0x81
	call PartCtrl_WriteByte_Indexed
	call PartCtrl_ReadWordRoutine
	ldw_erp HL, 0xfa
	ld wa, (0x28af:16)
	stw_erp BC, 0xfa
	call PartCtrl_WriteWord
	ld bc, (0x28af:16)
	stw_erp WA, 0xfa
	call PartCtrl_WriteWord_Off1
	stw_erp WA, 0xfa
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	stw_erp WA, 0xfa
	lds bc, 5
	ldw de, 0x82
	call PartCtrl_WriteByteToBuf
	ld c, (9780:16)
	extz bc
	lds wa, 0
	stw_erp DE, 0xfa
	call Part_WriteWord_Indexed
	ld c, (9780:16)
	extz bc
	lds wa, 0
	lds de, 5

SeqStep_InsertError:
	call Part_WriteByte_Indexed

SeqStep_InsertDone:
	mrdw5 0x9f, 0x04, 0x19, 0xaf, 0x28
	ld (9830:16), iz
	pop xiz
	inc 2, xsp
	ret

SeqStep_PrepareReadBack:
	push xiz
	ld iz, (0x28af:16)
	ld wa, (9830:16)
	ldw_erp WA, 0xfa
	ld (0x28c1:16), wa
	ld wa, (9830:16)
	cps wa, 5
	jr nz, SeqStep_PrepareCheck
	ld wa, (0x28af:16)
	call PartCtrl_ReadWord_Off1
	ld (0x28af:16), hl
	ldw (9830:16), 255
	jr SeqStep_PrepareDone

SeqStep_PrepareCheck:
	dec 1, wa
	ld (9830:16), wa

SeqStep_PrepareDone:
	call SeqData_ReadNextByte
	ld (0x28af:16), iz
	stw_erp WA, 0xfa
	ld (9830:16), wa
	pop xiz
	ret

SeqStep_DeleteShiftEvents:
	dec 8, xsp
	push xiz
	ldmm16 0x288b, 9802
	ldmm16 0x2889, 9800
	call SeqPart_ReadByte_Secondary
	lds wa, 0
	ldiw_erp 0xfa, 1
	extz xwa
	lda xbc, (xsp + 4)
	add xbc, xwa
	ld (xbc), l
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr z, SeqStep_DeleteShiftAdvance
	jrl SeqStep_DeleteShiftCleanup

SeqStep_DeleteShiftLoop:
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jrl nz, SeqStep_DeleteShiftCleanup

SeqStep_DeleteShiftAdvance:
	call SeqPart_ReadByte_Secondary
	stw_erp WA, 0xfa
	inc1w_erp 0xfa
	extz xwa
	lda xbc, (xsp + 4)
	add xbc, xwa
	ld (xbc), l
	bit 7, l
	jr z, SeqStep_DeleteShiftLoop
	dec1w_erp 0xfa
	call PartCtrl_NavigateBackward
	ldmm16 0x2887, 0x288b
	ldmm16 0x2885, 0x2889
	ldmm16 0x288b, 9802
	ldmm16 0x2889, 9800
	call PartCtrl_NavigateBackward

SeqStep_DeleteShiftDone:
	call SeqPart_ReadByte_Secondary
	ld wa, (0x288b:16)
	cp wa, (9798:16)
	jr nz, SeqStep_DeleteShiftReturn
	ld wa, (0x2889:16)
	cp wa, (9796:16)
	jr nz, SeqStep_DeleteShiftReturn
	extz hl
	ld wa, hl
	call SeqPart_WriteByte_Primary
	ldmm16 0x2887, 9798
	ldmm16 0x2885, 9796
	lds iz, 0
	cpiw_erp 0xfa, 0
	jr ule, SeqStep_DeleteShiftCleanup

SeqStep_DeleteShiftUpdate:
	ld wa, iz
	extz xwa
	lda xbc, (xsp + 4)
	add xbc, xwa
	ld a, (xbc)
	extz wa
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceToNextEntry
	cp (0x287a:16), 0
	jr z, SeqStep_DeleteShiftError
	jr SeqStep_DeleteShiftCleanup

SeqStep_DeleteShiftReturn:
	extz hl
	ld wa, hl
	call SeqPart_WriteByte_Primary
	call PartCtrl_NavigateBackward
	cp (0x287a:16), 0
	jr nz, SeqStep_DeleteShiftCleanup
	call PartCtrl_NavigateBackwardAlt
	cp (0x287a:16), 0
	jr z, SeqStep_DeleteShiftDone
	jr SeqStep_DeleteShiftCleanup

SeqStep_DeleteShiftError:
	inc 1, iz
	cpw_erp IZ, 0xfa
	jr c, SeqStep_DeleteShiftUpdate

SeqStep_DeleteShiftCleanup:
	pop xiz
	inc 8, xsp
	ret

SeqStep_DeleteShiftExit:
	pushw iz
	cpw (0xf231:16), 0
	jr nz, SeqStep_DeleteShiftFinal
	ldw hl, 0xffff
	jr SeqStep_BoundaryCheckB

SeqStep_DeleteShiftFinal:
	call PartCtrl_ReadWordRoutine
	ld iz, hl
	ld (0x28af:16), iz
	ld wa, iz
	lds bc, 1
	call PartCtrl_SetClearBit7
	ld wa, iz
	lds bc, 0
	call PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	ld a, (9994:16)
	extz wa
	ld c, (0x2877:16)
	inc 1, c
	extz bc
	lds de, 1
	call Part_SetClearVoiceBit7
	ld a, (9994:16)
	extz wa
	ld c, (0x2877:16)
	inc 1, c
	extz bc
	ld de, iz
	call Part_WriteVoiceWord
	ld a, (9994:16)
	dec 1, a
	cp a, (0xffe3:24)
	jr nz, SeqStep_BoundaryCheckA
	ld c, (0x2877:16)
	inc 1, c
	extz bc
	lds wa, 0
	lds de, 1
	call Part_SetClearVoiceBit7
	ld c, (0x2877:16)
	inc 1, c
	extz bc
	lds wa, 0
	ld de, iz
	call Part_WriteVoiceWord

SeqStep_BoundaryCheckA:
	ld hl, iz

SeqStep_BoundaryCheckB:
	popw iz
	ret

SeqStep_BoundaryReturn:
	pushw_erp 0xfa
	ld a, (0x2710:16)
	cp a, (0xffe3:24)
	jr nz, SeqStep_BoundaryProcess
	ldib_erp 0xfb, 0
	jr SeqStep_BoundaryAdvance

SeqStep_BoundaryProcess:
	inc 1, a
	ldb_erp A, 0xfb

SeqStep_BoundaryAdvance:
	stb_erp A, 0xfb
	extz wa
	ld c, (0x271a:16)
	inc 1, c
	extz bc
	call Part_ReadVoiceBit7
	cps l, 0
	jrl z, SeqStep_BoundaryFinal
	stb_erp A, 0xfb
	extz wa
	ld c, (0x271a:16)
	inc 1, c
	extz bc
	call Part_ReadVoiceWord
	ld wa, hl
	cps wa, 0
	jr z, SeqStep_BoundaryDone
	cp wa, 0xffff
	jr nz, SeqStep_BoundaryExit

SeqStep_BoundaryDone:
	jrl SeqStep_BoundaryFinal

SeqStep_BoundaryExit:
	call Part_StealAndReallocVoices
	ld a, (0x2710:16)
	inc 1, a
	extz wa
	ld c, (0x271a:16)
	inc 1, c
	extz bc
	lds de, 0
	call Part_SetClearVoiceBit7
	ld a, (0x2710:16)
	inc 1, a
	extz wa
	ld c, (0x271a:16)
	inc 1, c
	extz bc
	ldw de, 0xffff
	call Part_WriteVoiceWord
	ld a, (0x2710:16)
	cp a, (0xffe3:24)
	jr nz, SeqStep_BoundaryError
	ld c, (0x271a:16)
	inc 1, c
	extz bc
	lds wa, 0
	lds de, 0
	call Part_SetClearVoiceBit7
	ld c, (0x271a:16)
	inc 1, c
	extz bc
	lds wa, 0
	ldw de, 0xffff
	call Part_WriteVoiceWord

SeqStep_BoundaryError:
	ld a, (0x2710:16)
	inc 1, a
	extz wa
	ld c, (0x271a:16)
	inc 1, c
	extz bc
	ldw de, 0xffff
	call Part_WriteWord_Indexed
	ld a, (0x2710:16)
	inc 1, a
	extz wa
	ld c, (0x271a:16)
	inc 1, c
	extz bc
	lds de, 5
	call Part_WriteByte_Indexed
	ld a, (0x2710:16)
	cp a, (0xffe3:24)
	jr nz, SeqStep_BoundaryFinal
	ld c, (0x271a:16)
	inc 1, c
	extz bc
	lds wa, 0
	ldw de, 0xffff
	call Part_WriteWord_Indexed
	ld c, (0x271a:16)
	inc 1, c
	extz bc
	lds wa, 0
	lds de, 5
	call Part_WriteByte_Indexed

SeqStep_BoundaryFinal:
	popw_erp 0xfa
	ret

SeqStep_SkipIfLeftFlag:
	bit 0, (0x2879:16)
	jr z, SeqStep_SkipIfLeftDone
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr nz, SeqStep_SkipIfLeftReturn

SeqStep_SkipIfLeftCheck:
	lds hl, 0
	ret

SeqStep_SkipIfLeftDone:
	extz wa
	calr SeqStep_SkipToMeasure
	cps hl, 0
	jr z, SeqStep_SkipIfLeftCheck

SeqStep_SkipIfLeftReturn:
	ldw hl, 0xffff
	ret

SeqStep_SkipInvertedA:
	extz wa
	calr SeqStep_SkipToMeasure
	cps hl, 0
	jr z, SeqStep_SkipInvertedADone
	ldw hl, 0xffff
	ret

SeqStep_SkipInvertedADone:
	lds hl, 0
	ret

SeqStep_SkipInvertedB:
	extz wa
	calr SeqStep_SkipToMeasure
	cps hl, 0
	jr z, SeqStep_SkipInvertedBDone
	ldw hl, 0xffff
	ret

SeqStep_SkipInvertedBDone:
	lds hl, 0
	ret

SeqStep_AdvanceOneEvent:
	extz wa
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceToNextEntry
	cp (0x287a:16), 0
	jr nz, SeqStep_AdvanceOneDone
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr z, SeqStep_AdvanceOneReturn

SeqStep_AdvanceOneDone:
	ldw hl, 0xffff
	ret

SeqStep_AdvanceOneReturn:
	lds hl, 0
	ret

SeqStep_SkipToMeasure:
	extz wa
	calr SeqStep_AdvanceOneEvent
	cps hl, 0
	jr z, SeqStep_SkipToMeasureLoop
	ldw hl, 0xffff
	ret

SeqStep_SkipToMeasureLoop:
	call SeqPart_ReadByte_Secondary
	ld a, l
	bit 7, a
	jr z, SeqStep_SkipToMeasure
	lds hl, 0
	ret

SeqStep_SkipThreeEvents:
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr nz, SeqStep_SkipThreeError
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr nz, SeqStep_SkipThreeError
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr nz, SeqStep_SkipThreeError
	call SeqPart_ReadByte_Secondary
	cps l, 0
	jr z, SeqStep_SkipThreeReturn

SeqStep_SkipThreeError:
	ldw hl, 0xffff
	ret

SeqStep_SkipThreeReturn:
	lds hl, 0
	ret

SeqStep_ProcessC0:
	dec 4, xsp
	push xiz
	ld (xsp + 6), a
	ld a, (0x2879:16)
	and a, 0x3
	jr z, SeqStep_ProcessC0SavePos
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr nz, SeqStep_ProcessC0Error
	jr SeqStep_ProcessC0Done

SeqStep_ProcessC0SavePos:
	ld wa, (0x288b:16)
	ldw_erp WA, 0xfa
	ld iz, (0x2889:16)
	calr SeqStep_SkipThreeEvents
	cps hl, 0
	jr nz, SeqStep_ProcessC0Done
	stw_erp WA, 0xfa
	ld (0x288b:16), wa
	ld (0x2889:16), iz
	ld (xsp + 4), 0x0
	jr SeqStep_ProcessC0ReadParam

SeqStep_ProcessC0Check:
	cp (xsp + 4), 0x2
	jr nz, SeqStep_ProcessC0ReadParam
	ldmi16 (xsp + 6), 0x287c

SeqStep_ProcessC0ReadParam:
	ld a, (xsp + 6)
	extz wa
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceToNextEntry
	cp (0x287a:16), 0
	jr nz, SeqStep_ProcessC0Error
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr z, SeqStep_ProcessC0Advance

SeqStep_ProcessC0Error:
	ldw hl, 0xffff
	jr SeqStep_ProcessC0Return

SeqStep_ProcessC0Advance:
	incm8 1, (xsp + 4)
	call SeqPart_ReadByte_Secondary
	ld (xsp + 6), l
	bitm 7, (xsp + 6)
	jr z, SeqStep_ProcessC0Check

SeqStep_ProcessC0Done:
	lds hl, 0

SeqStep_ProcessC0Return:
	pop xiz
	inc 4, xsp
	ret

SeqStep_ProcessB0:
	dec 4, xsp
	push xiz
	ld (xsp + 6), a
	ld a, (xsp + 6)
	and a, 0x4
	sll a, 5
	ld (4340:16), a
	ld a, (xsp + 6)
	and a, 0x2
	sll a, 6
	ld (3310:16), a
	ld wa, (0x288b:16)
	ldw_erp WA, 0xfa
	ld iz, (0x2889:16)
	calr SeqStep_ParseRhythm
	stw_erp WA, 0xfa
	ld (0x288b:16), wa
	ld (0x2889:16), iz
	cp (0x287a:16), 0
	jr nz, SeqStep_ProcessB0Error
	ld a, (0x289d:16)
	bit 0, a
	jr nz, SeqStep_ProcessB0Advance
	bit 2, a
	jr z, SeqStep_ProcessB0Check
	ld a, (xsp + 6)
	extz wa
	calr SeqStep_SkipToMeasure
	cps hl, 0
	jr nz, SeqStep_ProcessB0Error
	jr SeqStep_ProcessB0Exit

SeqStep_ProcessB0Check:
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr nz, SeqStep_ProcessB0Error
	jr SeqStep_ProcessB0Exit

SeqStep_ProcessB0Advance:
	ld (xsp + 4), 0x0
	jr SeqStep_ProcessB0Return

SeqStep_ProcessB0Validate:
	cp (xsp + 4), 0x2
	jr nz, SeqStep_ProcessB0Skip
	ldmi16 (xsp + 6), 0x287c

SeqStep_ProcessB0Skip:
	cp (xsp + 4), 0x3
	jr nz, SeqStep_ProcessB0Done
	ldmi16 (xsp + 6), 0xd3c

SeqStep_ProcessB0Done:
	cp (xsp + 4), 0x4
	jr nz, SeqStep_ProcessB0Return
	ld a, (3387:16)
	cp a, 0xff
	jr z, SeqStep_ProcessB0Return
	ld (xsp + 6), a

SeqStep_ProcessB0Return:
	ld a, (xsp + 6)
	extz wa
	calr SeqStep_AdvanceOneEvent
	cps hl, 0
	jr z, SeqStep_ProcessB0Cleanup

SeqStep_ProcessB0Error:
	ldw hl, 0xffff
	jr SeqStep_ProcessB0Final

SeqStep_ProcessB0Cleanup:
	incm8 1, (xsp + 4)
	call SeqPart_ReadByte_Secondary
	ld (xsp + 6), l
	bitm 7, (xsp + 6)
	jr z, SeqStep_ProcessB0Validate

SeqStep_ProcessB0Exit:
	lds hl, 0

SeqStep_ProcessB0Final:
	pop xiz
	inc 4, xsp
	ret

SeqStep_ParseRhythm:
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr nz, SeqStep_ParseRhythmCheck
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr nz, SeqStep_ParseRhythmCheck
	ld (3387:16), 255
	call SeqPart_ReadByte_Secondary
	res 7, l
	ld a, (4340:16)
	or a, l
	ld (4340:16), a
	cp a, 0x48
	jr z, SeqStep_ParseRhythmError
	ld c, (0x289d:16)
	res 2, c
	ld (0x289d:16), c
	ld e, (0x2873:16)
	extz de
	lda xhl, (FontPalette_Gradient7_0x32:24)
	ld a, (4340:16)
	cpb_sri_rm A, 0x07, 0xec, 0xe8
	jr z, SeqStep_ParseRhythmLoop
	res 0, c
	res 2, c
	ld (0x289d:16), c
	jrl SeqStep_ParseRhythmComplete

SeqStep_ParseRhythmLoop:
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr z, SeqStep_ParseRhythmAdvance

SeqStep_ParseRhythmCheck:
	ldw hl, 0xffff
	ret

SeqStep_ParseRhythmAdvance:
	call SeqPart_ReadByte_Secondary
	ld c, (0x289d:16)
	cps l, 3
	jr c, SeqStep_ParseRhythmProcess
	cp l, 0xb
	jr ugt, SeqStep_ParseRhythmProcess
	cps l, 6
	jr nz, SeqStep_ParseRhythmStore

SeqStep_ParseRhythmProcess:
	res 0, c
	res 2, c
	ld (0x289d:16), c
	jrl SeqStep_ParseRhythmComplete

SeqStep_ParseRhythmStore:
	ld a, (0x2879:16)
	and a, 0x3
	jr nz, SeqStep_ParseRhythmReturn

SeqStep_ParseRhythmDone:
	set 0, (0x289d:16)
	jr SeqStep_ParseRhythmValidate

SeqStep_ParseRhythmReturn:
	cps l, 3
	jr z, SeqStep_ParseRhythmDone
	res 0, c
	res 2, c
	ld (0x289d:16), c
	jr SeqStep_ParseRhythmComplete

SeqStep_ParseRhythmError:
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr nz, SeqStep_ParseRhythmComplete
	call SeqPart_ReadByte_Secondary
	cps l, 5
	jr z, SeqStep_ParseRhythmExit
	ld a, (0x289d:16)
	res 2, a
	ld (0x289d:16), a
	cp (0x2873:16), 12
	jr z, SeqStep_ParseRhythmSkip
	res 0, a
	res 2, a
	ld (0x289d:16), a
	jr SeqStep_ParseRhythmComplete

SeqStep_ParseRhythmSkip:
	cps l, 3
	jr nz, SeqStep_ParseRhythmCleanup
	set 0, a
	ld (0x289d:16), a

SeqStep_ParseRhythmValidate:
	ld (3388:16), l
	jr SeqStep_ParseRhythmComplete

SeqStep_ParseRhythmCleanup:
	res 0, a
	res 2, a
	ld (0x289d:16), a
	jr SeqStep_ParseRhythmComplete

SeqStep_ParseRhythmExit:
	res 0, (0x289d:16)
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr nz, SeqStep_ParseRhythmComplete
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr nz, SeqStep_ParseRhythmComplete
	call SeqPart_ReadByte_Secondary
	ld a, (3310:16)
	and a, 0xfc
	jr z, SeqStep_ParseRhythmFinal
	set 2, (0x289d:16)
	jr SeqStep_ParseRhythmComplete

SeqStep_ParseRhythmFinal:
	res 2, (0x289d:16)

SeqStep_ParseRhythmComplete:
	lds hl, 0
	ret

SeqStep_CommitEvent:
	extz wa
	call SeqPart_WriteByte_Primary
	ld wa, (0x2885:16)
	ld c, a
	extz bc
	ld wa, (0x2887:16)
	call Part_WriteWordAndByte
	ld wa, (0x2887:16)
	jp Part_CheckAndReallocVoices

SeqStep_ProcessC0Ext:
	dec 4, xsp
	push xiz
	ld (xsp + 6), a
	ld a, (0x2879:16)
	and a, 0x3
	jr z, SeqStep_ProcessC0ExtCheck
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr nz, SeqStep_ProcessC0ExtReturn
	jr SeqStep_ProcessC0ExtFinal

SeqStep_ProcessC0ExtCheck:
	bit 1, (4393:16)
	jr nz, SeqStep_ProcessC0ExtProcess
	ld wa, (0x288b:16)
	ldw_erp WA, 0xfa
	ld iz, (0x2889:16)
	calr SeqStep_SkipThreeEvents
	cps hl, 0
	jr nz, SeqStep_ProcessC0ExtFinal
	stw_erp WA, 0xfa
	ld (0x288b:16), wa
	ld (0x2889:16), iz

SeqStep_ProcessC0ExtProcess:
	ld (xsp + 4), 0x0
	jr SeqStep_ProcessC0ExtDone

SeqStep_ProcessC0ExtSkip:
	cp (xsp + 4), 0x2
	jr nz, SeqStep_ProcessC0ExtDone
	ldmi16 (xsp + 6), 0x287c

SeqStep_ProcessC0ExtDone:
	ld a, (xsp + 6)
	extz wa
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceToNextEntry
	cp (0x287a:16), 0
	jr nz, SeqStep_ProcessC0ExtReturn
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr z, SeqStep_ProcessC0ExtExit

SeqStep_ProcessC0ExtReturn:
	ldw hl, 0xffff
	jr SeqStep_ProcessC0ExtComplete

SeqStep_ProcessC0ExtExit:
	incm8 1, (xsp + 4)
	call SeqPart_ReadByte_Secondary
	ld (xsp + 6), l
	bitm 7, (xsp + 6)
	jr z, SeqStep_ProcessC0ExtSkip

SeqStep_ProcessC0ExtFinal:
	lds hl, 0

SeqStep_ProcessC0ExtComplete:
	pop xiz
	inc 4, xsp
	ret

SeqStep_ProcessB0Ext:
	dec 4, xsp
	push xiz
	ld (xsp + 6), a
	ld a, (xsp + 6)
	and a, 0x4
	sll a, 5
	ld (4340:16), a
	ld a, (xsp + 6)
	and a, 0x2
	sll a, 6
	ld (3310:16), a
	bit 1, (4393:16)
	jr nz, SeqStep_ProcessB0ExtSkip
	ld wa, (0x288b:16)
	ldw_erp WA, 0xfa
	ld iz, (0x2889:16)
	calr SeqPart_EventLoopContinue
	stw_erp WA, 0xfa
	ld (0x288b:16), wa
	ld (0x2889:16), iz
	cp (0x287a:16), 0
	jr nz, SeqStep_ProcessB0ExtExit
	ld a, (0x289d:16)
	bit 0, a
	jr nz, SeqStep_ProcessB0ExtSkip
	bit 2, a
	jr z, SeqStep_ProcessB0ExtCheck
	ld a, (xsp + 6)
	extz wa
	calr SeqStep_SkipToMeasure
	cps hl, 0
	jr z, SeqStep_ProcessB0ExtProcess
	jr SeqStep_ProcessB0ExtExit

SeqStep_ProcessB0ExtCheck:
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr nz, SeqStep_ProcessB0ExtExit

SeqStep_ProcessB0ExtProcess:
	lds hl, 0
	jr SeqStep_ProcessB0ExtFinal

SeqStep_ProcessB0ExtSkip:
	ld (xsp + 4), 0x0
	jr SeqStep_ProcessB0ExtReturn

SeqStep_ProcessB0ExtDone:
	cp (xsp + 4), 0x4
	jr nz, SeqStep_ProcessB0ExtReturn
	ld a, (3387:16)
	cp a, 0xff
	jr z, SeqStep_ProcessB0ExtReturn
	bit 1, (4393:16)
	jr nz, SeqStep_ProcessB0ExtReturn
	ld (xsp + 6), a

SeqStep_ProcessB0ExtReturn:
	ld a, (xsp + 6)
	extz wa
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceToNextEntry
	cp (0x287a:16), 0
	jr nz, SeqStep_ProcessB0ExtExit
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr z, SeqStep_ProcessB0ExtComplete

SeqStep_ProcessB0ExtExit:
	ldw hl, 0xffff

SeqStep_ProcessB0ExtFinal:
	pop xiz
	inc 4, xsp
	ret

SeqStep_ProcessB0ExtComplete:
	incm8 1, (xsp + 4)
	call SeqPart_ReadByte_Secondary
	ld (xsp + 6), l
	bitm 7, (xsp + 6)
	jr nz, SeqStep_ProcessB0ExtProcess
	ld a, (xsp + 6)
	extz wa
	call SeqPart_WriteByte_Primary
	cp (xsp + 4), 0x2
	jr nz, SeqStep_ProcessB0ExtCleanup
	ldmi16 (xsp + 6), 0x287c

SeqStep_ProcessB0ExtCleanup:
	cp (xsp + 4), 0x3
	jr nz, SeqStep_ProcessB0ExtDone
	bit 1, (4393:16)
	jr nz, SeqStep_ProcessB0ExtReturn
	ldmi16 (xsp + 6), 0xd3c
	jr SeqStep_ProcessB0ExtReturn

SeqStep_MainTimerTick:
	calr SeqStep_TimerDispatchA
	call SeqPlay_SyncPlaybackPosition
	calr SeqStep_TimerDispatchB
	call Seq_HandleModeTransition
	call SeqNotify_CheckAndClearStart
	calr SeqStep_PlaybackStateMachine
	call SeqPlay_SetupRhythmMode
	call PlaybackMode_DispatchByType
	call SeqTimer_CheckPlaybackCountdown
	jp BmDrEdit_TempoAnimTimer

SeqStep_TimerDispatchA:
	ld a, (8956:16)
	extz wa
	sla wa, 2
	lda xbc, (Display_FontPalette_Table_0xA8:24)
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	jp (xhl)

SeqStep_TimerDispatchB:
	ld a, (8956:16)
	extz wa
	sla wa, 2
	lda xbc, (Display_FontPalette_Table_0x104:24)
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	jp (xhl)

SeqStep_TimerDispatchC:
	ld a, (8956:16)
	extz wa
	sla wa, 2
	lda xbc, (Display_FontPalette_Table_0x160:24)
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	jp (xhl)

SeqStep_PlaybackStateMachine:
	pushw_erp 0xfa
	ld a, (7518:16)
	cps a, 0
	jr z, SeqStep_PlaybackDecrCount
	dec 1, a
	ld (7518:16), a

SeqStep_PlaybackDecrCount:
	ei 6
	ld a, (1057:16)
	ldb_erp A, 0xfb
	res 1, a
	res 4, a
	ld (1057:16), a
	ei 0
	cpw (0x28a8:16), 0
	jr nz, SeqStep_PlaybackCheck10408
	bit_erpb 0xfb, 0x04
	jr z, SeqStep_PlaybackCheckFill
	cpw (0x28b4:16), 0
	jr nz, SeqStep_PlaybackCallFill

SeqStep_PlaybackCheckFill:
	bit_erpb 0xfb, 0x04
	jr z, SeqStep_PlaybackCheckBeat
	bit 0, (0x28c5:16)
	jr z, SeqStep_PlaybackCheckBeat

SeqStep_PlaybackCallFill:
	call SeqPlay_HandlePlaybackEvent
	jr SeqStep_PlaybackResultDispatch

SeqStep_PlaybackCheckBeat:
	bit_erpb 0xfb, 0x01
	jr z, SeqStep_PlaybackCheckPattern
	call SeqPlay_PreparePlaybackState
	jr SeqStep_PlaybackResultDispatch

SeqStep_PlaybackCheckPattern:
	cpw (0x28b4:16), 0
	jr z, SeqStep_PlaybackNoAction
	call SeqNote_ProcessNoteOn
	jr SeqStep_PlaybackResultDispatch

SeqStep_PlaybackNoAction:
	ldb l, 0x0
	jr SeqStep_PlaybackReturn

SeqStep_PlaybackCheck10408:
	bit_erpb 0xfb, 0x04
	jr z, SeqStep_PlaybackCheckFill2
	cpw (0x28aa:16), 0
	jr nz, SeqStep_PlaybackCallExtFill

SeqStep_PlaybackCheckFill2:
	bit_erpb 0xfb, 0x04
	jr z, SeqStep_PlaybackCheckBeat2
	bit 0, (0x28c5:16)
	jr z, SeqStep_PlaybackCheckBeat2

SeqStep_PlaybackCallExtFill:
	call SeqPlay_ProcessVoiceAndNotes

SeqStep_PlaybackResultDispatch:
	cps l, 3
	jr z, SeqStep_PlaybackResult3
	cps l, 2
	jr z, SeqStep_PlaybackResult2
	cps l, 4
	jr z, SeqStep_PlaybackResult4
	cps l, 1
	jr z, SeqStep_PlaybackResult1
	jr SeqStep_PlaybackReturn

SeqStep_PlaybackCheckBeat2:
	bit_erpb 0xfb, 0x01
	jr z, SeqStep_PlaybackCheckTiming
	call SeqPlay_SaveAndPrepareState
	jr SeqStep_PlaybackResultDispatch

SeqStep_PlaybackCheckTiming:
	cpw (0x28aa:16), 0
	jr nz, SeqStep_PlaybackCallPattern
	cpw (0x28b4:16), 0
	jr z, SeqStep_PlaybackNoAction
	bit 0, (0x28c5:16)
	jr z, SeqStep_PlaybackNoAction

SeqStep_PlaybackCallPattern:
	call SeqPlay_ProcessNoteAndTempo
	jr SeqStep_PlaybackResultDispatch

SeqStep_PlaybackResult1:
	call SeqPlay_StopAndResetAll
	jr SeqStep_PlaybackReturn

SeqStep_PlaybackResult4:
	call SeqPlay_StopAndClearSequence
	jr SeqStep_PlaybackReturn

SeqStep_PlaybackResult2:
	call SeqPlay_StopAndClearChannels
	jr SeqStep_PlaybackReturn

SeqStep_PlaybackResult3:
	call SeqPlay_DispatchAndResetAll

SeqStep_PlaybackReturn:
	popw_erp 0xfa
	ret

SeqStep_PlaybackNop:
	ret

SeqStep_PlaybackMaxPart:
	ret

SeqStep_FindLastUsedPart:
	dec 4, xsp
	ldw wa, 0x4d8
	calr SeqStep_SearchBackward
	ld (xsp + 2), hl
	lds wa, 1
	calr SeqStep_SearchForward
	ld (xsp), hl
	cpw (xsp), 0x4d8
	jr nc, SeqStep_FindLastReturn
	ld wa, (xsp)
	cp wa, (xsp + 2)
	jr nc, SeqStep_FindLastReturn

SeqStep_FindLastLoop:
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr SeqStep_SwapTwoParts
	ld wa, (xsp)
	cp wa, (xsp + 2)
	jr c, SeqStep_FindLastLoop

SeqStep_FindLastReturn:
	inc 4, xsp
	ret

SeqStep_FindAndCompactEntry:
	lds wa, 1
	calr SeqStep_SearchForward
	ld wa, hl
	jrl SeqStep_RebuildPartChain

SeqStep_FindAndCompact:
	dec 4, xsp
	pushw iz
	ldw (0xf1ce:16), 0x4d80
	ldw wa, 0x4d8
	calr SeqStep_SearchBackward
	ld (xsp + 2), hl
	lds wa, 1
	calr SeqStep_SearchForward
	ld (xsp + 4), hl
	cpw (xsp + 4), 0x4d8
	jr nc, SeqStep_CompactDone
	ld wa, (xsp + 4)
	cp wa, (xsp + 2)
	jr nc, SeqStep_CompactDone

SeqStep_CompactLoop:
	lda xwa, (xsp + 2)
	lda xbc, (xsp + 4)
	calr SeqStep_SwapTwoParts
	ld wa, (xsp + 4)
	cp wa, (xsp + 2)
	jr c, SeqStep_CompactLoop

SeqStep_CompactDone:
	ld iz, (xsp + 4)
	dec 1, iz
	ld wa, iz
	sll wa, 4
	ld (0xf1ce:16), wa
	ld wa, (xsp + 4)
	calr SeqStep_RebuildPartChain
	ld hl, iz
	extz xhl
	sll xhl, 8
	popw iz
	inc 4, xsp
	ret

SeqStep_SearchBackward:
	pushw iz
	ld iz, wa

SeqStep_SearchBackwardLoop:
	ld wa, iz
	call PartCtrl_TestBit7
	cps l, 0
	jr nz, SeqStep_SearchBackwardDone
	djnz xiz, SeqStep_SearchBackwardLoop

SeqStep_SearchBackwardDone:
	ld hl, iz
	popw iz
	ret

SeqStep_SearchForward:
	pushw iz
	ld iz, wa

SeqStep_SearchForwardLoop:
	ld wa, iz
	call PartCtrl_TestBit7
	cps l, 0
	jr z, SeqStep_SearchForwardDone
	inc 1, iz
	cp iz, 0x4d8
	jr ule, SeqStep_SearchForwardLoop

SeqStep_SearchForwardDone:
	ld hl, iz
	popw iz
	ret

SeqStep_SwapTwoParts:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xiz, xwa
	ld wa, (xiz)
	ld xbc, (xsp + 4)
	ld bc, (xbc)
	calr SeqStep_CopyPartData
	ld wa, (xiz)
	ld xbc, (xsp + 4)
	ld bc, (xbc)
	calr SeqStep_UpdateRefsAfterSwap
	ld wa, (xiz)
	ld xbc, (xsp + 4)
	ld bc, (xbc)
	calr SeqStep_UpdateForwardLinks
	ld wa, (xiz)
	calr SeqStep_SearchBackward
	ld (xiz), hl
	ld xwa, (xsp + 4)
	ld wa, (xwa)
	calr SeqStep_SearchForward
	ld xwa, (xsp + 4)
	ld (xwa), hl
	pop xiz
	inc 4, xsp
	ret

SeqStep_CopyPartData:
	dec 4, xsp
	push xiz
	ld xde, (7514:16)
	ld (xsp + 4), xde
	ld iy, wa
	extz xiy
	dec 1, xiy
	sll xiy, 8
	ld xiz, xde
	ld ix, bc
	extz xix
	dec 1, xix
	sll xix, 8
	lds hl, 0

SeqStep_CopyPartReturn:
	ld bc, hl
	extz xbc
	ld xde, xbc
	add xde, xix
	add xde, xiz
	add xbc, xiy
	add xbc, (xsp + 4)
	ld c, (xbc)
	ld (xde), c
	inc 1, hl
	cp hl, 0x100
	jr c, SeqStep_CopyPartReturn
	lds bc, 0
	call PartCtrl_SetClearBit7
	pop xiz
	inc 4, xsp
	ret

SeqStep_UpdateRefsAfterSwap:
	dec 2, xsp
	push xiz
	ld iz, bc
	ld (xsp + 4), wa
	ld wa, iz
	call PartCtrl_ReadWord_Off1
	ld wa, hl
	cps wa, 0
	jr z, SeqStep_UpdateRefsLoop
	ld bc, iz
	call PartCtrl_WriteWord
	jr SeqStep_UpdateRefsReturn

SeqStep_UpdateRefsLoop:
	ldib_erp 0xfa, 1

SeqStep_UpdateRefsCheck:
	ldib_erp 0xfb, 1

SeqStep_UpdateRefsAdvance:
	stb_erp A, 0xfa
	extz wa
	stb_erp C, 0xfb
	extz bc
	call Part_ReadVoiceBit7
	cps l, 0
	jr z, SeqStep_UpdateRefsDone
	stb_erp A, 0xfa
	extz wa
	stb_erp C, 0xfb
	extz bc
	call Part_ReadVoiceWord
	cp hl, (xsp + 4)
	jr nz, SeqStep_UpdateRefsDone
	stb_erp A, 0xfa
	extz wa
	stb_erp C, 0xfb
	extz bc
	ld de, iz
	call Part_WriteVoiceWord

SeqStep_UpdateRefsDone:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqStep_UpdateRefsAdvance
	inc1b_erp 0xfa
	cp_erpb 0xfa, 0x0a
	jr ule, SeqStep_UpdateRefsCheck

SeqStep_UpdateRefsReturn:
	pop xiz
	inc 2, xsp
	ret

SeqStep_UpdateForwardLinks:
	dec 2, xsp
	push xiz
	ld iz, bc
	ld (xsp + 4), wa
	ld wa, iz
	call PartCtrl_ReadWord
	ld wa, hl
	cp wa, 0xffff
	jr z, SeqStep_UpdateLinksLoop
	ld bc, iz
	call PartCtrl_WriteWord_Off1
	jr SeqStep_UpdateLinksReturn

SeqStep_UpdateLinksLoop:
	ldib_erp 0xfa, 1

SeqStep_UpdateLinksCheck:
	ldib_erp 0xfb, 1

SeqStep_UpdateLinksAdvance:
	stb_erp A, 0xfa
	extz wa
	stb_erp C, 0xfb
	addb_erp C, 0xfb
	add c, 0x76
	extz bc
	call Part_ReadWord
	cp hl, (xsp + 4)
	jr nz, SeqStep_UpdateLinksDone
	stb_erp A, 0xfa
	extz wa
	stb_erp C, 0xfb
	addb_erp C, 0xfb
	add c, 0x76
	extz bc
	ld de, iz
	call Part_WriteWord

SeqStep_UpdateLinksDone:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqStep_UpdateLinksAdvance
	inc1b_erp 0xfa
	cp_erpb 0xfa, 0x0a
	jr ule, SeqStep_UpdateLinksCheck

SeqStep_UpdateLinksReturn:
	pop xiz
	inc 2, xsp
	ret

SeqStep_RebuildPartChain:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), wa
	cpw (xsp + 2), 0x4d8
	jr ule, SeqStep_RebuildLoop
	ldw (0xf231:16), 0
	ldw (0xf22f:16), 0xffff
	jrl SeqStep_RebuildReturn

SeqStep_RebuildLoop:
	mrdw5 0x9f, 0x02, 0x19, 0x2f, 0xf2
	ldw (0xf231:16), 0
	ld wa, (xsp + 2)
	lds bc, 0
	call PartCtrl_SetClearBit7
	ld wa, (xsp + 2)
	lds bc, 0
	call PartCtrl_WriteWord_Off1
	ld bc, (xsp + 2)
	inc 1, bc
	ld wa, (xsp + 2)
	call PartCtrl_WriteWord
	ld wa, (xsp + 2)
	lds bc, 5
	ldw de, 0x82
	call PartCtrl_WriteByteToBuf
	incw 1, (0xf231:16)
	ld iz, (xsp + 2)
	inc 1, iz
	cp iz, 0x4d8
	jr nc, SeqStep_RebuildAdvance

SeqStep_RebuildCheck:
	ld wa, iz
	lds bc, 0
	call PartCtrl_SetClearBit7
	ld bc, iz
	dec 1, bc
	ld wa, iz
	call PartCtrl_WriteWord_Off1
	ld bc, iz
	inc 1, bc
	ld wa, iz
	call PartCtrl_WriteWord
	ld wa, (xsp + 2)
	lds bc, 5
	ldw de, 0x82
	call PartCtrl_WriteByteToBuf
	incw 1, (0xf231:16)
	inc 1, iz
	cp iz, 0x4d8
	jr c, SeqStep_RebuildCheck

SeqStep_RebuildAdvance:
	ldw wa, 0x4d8
	lds bc, 0
	call PartCtrl_SetClearBit7
	cpw (xsp + 2), 0x4d8
	jr z, SeqStep_RebuildDone
	ldw wa, 0x4d8
	ldw bc, 0x4d7
	call PartCtrl_WriteWord_Off1

SeqStep_RebuildDone:
	ldw wa, 0x4d8
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	ld wa, (xsp + 2)
	lds bc, 5
	ldw de, 0x82
	call PartCtrl_WriteByteToBuf
	incw 1, (0xf231:16)

SeqStep_RebuildReturn:
	popw iz
	inc 2, xsp
	ret

SeqStep_ByteBlockEA5F:
	.incbin "includes/romslices/v7_transplant_SeqStep_ByteBlockEA5F.bin"
SeqStep_ReinitPartTable:
	dec 6, xsp
	push xiz
	ld a, (0x00ffe3:24)
	extz wa
	call SeqData_CopyBlockToBuffer
	ld e, (0x00ffe3:24)
	extz de
	lds wa, 1
	ldw bc, 0xc7
	call Part_WriteByte
	ld de, (0x00ffec:24)
	lds wa, 1
	ldw bc, 0xc8
	call Part_WriteWord
	calr SeqStep_FindAndCompact
	ld (xsp + 4), xhl
	ld iz, (0xf1ce:16)
	ld wa, (0xf22f:16)
	ldw_erp WA, 0xfa
	ldmw2 (xsp + 8), 0xf231
	ld a, (0x00ffe3:24)
	extz wa
	call VoicePreset_LoadAndInitPan
	ld (0xf1ce:16), iz
	stw_erp WA, 0xfa
	ld (0xf22f:16), wa
	mrdw5 0x9f, 0x08, 0x19, 0x31, 0xf2
	stw_erp WA, 0xfa
	call Part_WriteWordBlock_OffsetAF
	ld wa, (0xf231:16)
	call Part_SetAllVoicePos
	ldib_erp 0xfb, 1

SeqStep_ReinitLoop:
	stb_erp A, 0xfb
	extz wa
	ld de, (0xf1ce:16)
	ldw bc, 0x4e
	call Part_WriteWord
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jr ule, SeqStep_ReinitLoop
	ld xhl, (xsp + 4)
	pop xiz
	inc 6, xsp
	ret

SeqStep_MemAllocWrapper:
	push	xiz
	ld	wa, (xsp+8)
	exts	xwa
	push	xwa
	pushw	0
	call	16051728
	inc	6, xsp
	ld	xiz, xhl
	or	xiz, xiz
	jr	z, 16
	ld	wa, (xsp+8)
	pushw	wa
	pushw	0
	push	xiz
	call	16713757
	inc	8, xsp
	jr	7
SeqStep_MemAllocFail:
	ldw (0x01e53c:24), 0x0003

SeqStep_MemAllocReturn:
	ld xhl, xiz
	pop xiz
	ret
