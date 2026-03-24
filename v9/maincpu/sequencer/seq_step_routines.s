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
	bitda 0, 0x287b
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
	lda_24 xix, Display_FontPalette_Table_0x7E_
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, SeqStep_NoteByteBlock
	jp_dri 8, 0x07, 0xf0, 0xe0

SeqStep_NoteByteBlock:
	ldda8	a, 0x271c
	and	a, 255
	extz	wa
	stda16	9830, wa
	ldda32	xwa, 0x2722
	stda16	0x28af, wa
	call	SeqData_ReadNextByte
	stda8	9686, l
	ldw	wa, 129
	call	PartCtrl_WriteByte_Indexed
	cpdi8	9686, 129
	jr	z, 73
	call	SeqData_AdvancePosition
	cpdi8	0x287a, 0
	jr	nz, 62
	.byte 0xc1, 0xd6, 0x25, 0x19, 0xd8, 0x25
	call	SeqData_ReadNextByte
	stda8	9686, l
	ldda8	a, 9688
	extz	wa
	jr	-44
	ldi_berp	249, 0
	jr	18
	ldi_berp	249, 1
	jr	13

SeqStep_NoteSetD1:
	ldi_berp 0xf9, 2
	jr SeqStep_NoteConsumeInit

SeqStep_NoteSetD2:
	ldi_berp 0xf9, 3
	jr SeqStep_NoteConsumeInit

SeqStep_NoteSetOther:
	ldi_berp 0xf9, 5

SeqStep_NoteConsumeInit:
	ldi_berp 0xfb, 0

SeqStep_NoteConsumeLoop:
	ldi_berp 0xfa, 0
	call SeqData_AdvancePosition
	cpdi8 0x287a, 0
	jr z, SeqStep_NoteConsumeAdvance
	mrdw5 0x9f, 0x04, 0x19, 0xaf, 0x28
	mrdw5 0x9f, 0x06, 0x19, 0x66, 0x26
	jrl SeqStep_NoteExit

SeqStep_NoteConsumeAdvance:
	inc1_berp 0xfb
	ldto_berp A, 0xf9
	cp_berp A, 0xfb
	jr nz, SeqStep_NoteCheckVel
	call SeqData_AdvancePosition
	ldmm16 0x273c, 0x28af
	ldmm16 0x273e, 9830
	jrl SeqStep_NoteReadEvent

SeqStep_NoteCheckVel:
	cpi_berp 0xfb, 1
	jr nz, SeqStep_NoteVelContinue
	call SeqData_ReadNextByte
	cp l, 0x5f
	jr ule, SeqStep_NoteVelSkip
	ldda8 a, 9824
	bit 0, a
	jr nz, SeqStep_NoteVelSave
	ldda16 xwa, 0x273e
	ldb w, 0x0
	stda8 0x271c, a
	ldda16 xwa, 0x273c
	extz xwa
	stda32 0x2722, xwa
	ldda8 a, 9824
	set 0, a
	stda8 9824, a

SeqStep_NoteVelSave:
	call SeqData_ReadNextByte
	sub l, 0x60
	extz hl
	ld wa, hl
	call PartCtrl_WriteByte_Indexed
	ldto_berp A, 0xfb
	cp_berp A, 0xf9
	jr z, SeqStep_NoteReturn
	cpi_berp 0xfa, 1
	jrl nz, SeqStep_NoteConsumeLoop
	jrl SeqStep_NoteReadEvent

SeqStep_NoteVelSkip:
	ldto_berp A, 0xfb
	cp_berp A, 0xf9
	jr z, SeqStep_NoteReturn

SeqStep_NoteVelContinue:
	call SeqData_AdvancePosition
	cpdi8 0x287a, 0
	jr z, SeqStep_NoteExitRestore

SeqStep_NoteExit:
	pop xiz
	inc 4, xsp
	ret

SeqStep_NoteExitRestore:
	inc1_berp 0xfb
	ldto_berp A, 0xfb
	cp_berp A, 0xf9
	jr nz, SeqStep_NoteCheckVel

SeqStep_NoteReturn:
	call SeqData_AdvancePosition
	ldmm16 0x273c, 0x28af
	ldmm16 0x273e, 9830
	ldi_berp 0xfa, 1
	jrl SeqStep_NoteReadEvent

SeqStep_EventProcess:
	dec 6, xsp
	push xiz
	ld (xsp + 8), bc
	ld iz, wa
	stdi8 0x271e, 0
	ldmw2 (xsp + 6), 0x28af
	ldmw2 (xsp + 4), 0x2666
	ldmm16 0x28af, 0x273c
	ldmm16 9830, 0x273e
	call SeqPos_DecrementAndCheck
	ldada xbc, 0x2830
	ldda16 xwa, 0x28af
	ld (xbc), wa
	ldmw2 (xbc + 2), 0x2666
	ldmm16 0x28af, 0x273c
	ldmm16 9830, 0x273e
	ldda8 a, 0x287a
	cps a, 0
	jr z, SeqStep_EventPosManage
	cp a, 0xa
	jrl nz, SeqStep_EventExit
	stdi8 0x287a, 0
	cpdi16 9778, 1
	jr nz, SeqStep_EventPosManage
	cps iz, 0
	jr nz, SeqStep_EventPosManage
	cpw (xsp + 8), 0x0
	jr nz, SeqStep_EventPosManage
	stdi8 0x271e, 1

SeqStep_EventPosManage:
	stdi8 9824, 0
	stdi8 9826, 0
	bitda 0, 0x287b
	jrl nz, SeqStep_EventPosConsumeAdvance
	jrl SeqStep_EventExit
	bitda 0, 9824
	jr z, SeqStep_EventPosCheck
	bitda 0, 9826
	call_24 z, SeqStep_DecrementPos

SeqStep_EventPosCheck:
	ldda32 xwa, 0x2722
	stda16 0x288b, xwa
	ldda8 a, 0x271c
	and a, 0xff
	extz wa
	stda16 0x2889, xwa
	ldada xwa, 0x2830
	mriw4 0x90, 0x19, 0x87, 0x28
	mrdw5 0x98, 0x02, 0x19, 0x85, 0x28

SeqStep_EventPosUpdate:
	ldda16 xwa, 0x288b
	cpda16 xwa, 0x2726
	jr nz, SeqStep_EventPosAdvance
	ldda8 a, 0x2720
	extz wa
	cpda16 xwa, 0x2889
	jr nz, SeqStep_EventPosAdvance
	call SeqPart_ReadByte_Secondary
	extz hl
	ld wa, hl
	call SeqPart_WriteByte_Primary
	ldmm16 0x28af, 0x2726
	ldda8 a, 0x2720
	extz wa
	stda16 9830, xwa
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
	cpdi8 0x287a, 0
	jr z, SeqStep_EventPosUpdate
	jrl SeqStep_EventExit
	ldi_berp 0xfa, 0
	jr SeqStep_EventPosSetNote
	ldi_berp 0xfa, 1
	jr SeqStep_EventPosSetNote

SeqStep_EventPosSetD1:
	ldi_berp 0xfa, 2
	jr SeqStep_EventPosSetNote

SeqStep_EventPosSetD2:
	ldi_berp 0xfa, 3
	jr SeqStep_EventPosSetNote

SeqStep_EventPosSetD3:
	ldi_berp 0xfa, 5

SeqStep_EventPosSetNote:
	ldi_berp 0xf9, 0

SeqStep_EventPosConsumeLoop:
	call SeqData_AdvancePosition
	cpdi8 0x287a, 0
	jrl nz, SeqStep_EventExit
	inc1_berp 0xf9
	ldto_berp A, 0xfa
	cp_berp A, 0xf9
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
	lda_24 xix, Display_FontPalette_Table_0x8C_
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, SeqStep_EventPosFinish
	jp_dri 8, 0x07, 0xf0, 0xe0

SeqStep_EventPosFinish:
	bitda	0, 0x271e
	jrl	z, -285
	jr	56

SeqStep_EventPosReturn:
	ldi_berp 0xfb, 0

SeqStep_EventPosExit:
	cpi_berp 0xf9, 1
	jr nz, SeqStep_EventPosDone
	call SeqData_ReadNextByte
	bit 7, l
	jr nz, SeqStep_EventStorePos
	cp l, 0x5f
	jr ugt, SeqStep_EventStorePos
	bitda 0, 9824
	jr z, SeqStep_EventPosComplete
	bitda 0, 9826
	call_24 z, SeqStep_DecrementPos

SeqStep_EventPosComplete:
	ldto_berp A, 0xf9
	cp_berp A, 0xfa
	jr z, SeqStep_EventRestore

SeqStep_EventPosDone:
	call SeqData_AdvancePosition
	cpdi8 0x287a, 0
	jr z, SeqStep_EventCleanup

SeqStep_EventExit:
	mrdw5 0x9f, 0x06, 0x19, 0xaf, 0x28
	mrdw5 0x9f, 0x04, 0x19, 0x66, 0x26
	pop xiz
	inc 6, xsp
	ret

SeqStep_EventCleanup:
	inc1_berp 0xf9
	ldto_berp A, 0xf9
	cp_berp A, 0xfa
	jr nz, SeqStep_EventPosExit

SeqStep_EventRestore:
	call SeqData_AdvancePosition
	ldmm16 0x273c, 0x28af
	ldmm16 0x273e, 9830
	ldi_berp 0xfb, 1
	jrl SeqStep_EventPosConsumeAdvance

SeqStep_EventStorePos:
	cpi_berp 0xfb, 1
	jrl z, SeqStep_EventPosConsumeAdvance
	ldda8 a, 9824
	bit 0, a
	jr nz, SeqStep_EventSetState
	ldda16 xwa, 0x273e
	stda8 0x271c, a
	ldda16 xwa, 0x273c
	extz xwa
	stda32 0x2722, xwa
	ldda8 a, 9824
	set 0, a
	stda8 9824, a

SeqStep_EventSetState:
	ldb l, 0x0
	bitda 0, 0x271e
	jr nz, SeqStep_EventAdvancePos
	call SeqData_ReadNextByte
	add l, 0x60

SeqStep_EventAdvancePos:
	extz hl
	ld wa, hl
	call PartCtrl_WriteByte_Indexed
	ldto_berp A, 0xf9
	cp_berp A, 0xfa
	jrl z, SeqStep_EventPosConsumeCheck
	jrl SeqStep_EventPosConsumeLoop

SeqStep_VelNoteFwd:
	ldda16 xwa, 9778
	cps wa, 1
	ret z
	ldda8 c, 9780
	stda16 0x287f, xwa
	extz bc
	ld wa, bc
	lds bc, 0
	call SeqVoice_SeekToBar
	cpdi8 0x287a, 0
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
	ldda8 c, 9780
	inc 1, wa
	stda16 0x287f, xwa
	extz bc
	ld wa, bc
	lds bc, 0
	call SeqVoice_SeekToBar
	cpdi8 0x287a, 0
	ret nz
	ldmm16 0x273c, 0x28af
	ldmm16 0x273e, 9830
	jrl SeqStep_MeasureRead

SeqStep_DeleteEvent:
	dec 4, xsp
	push xiz
	ldmw2 (xsp + 4), 0x28af
	ldmw2 (xsp + 6), 0x2666
	ldda8 a, 9740
	bit 7, a
	jrl nz, SeqStep_DeletePopReturn
	bitda 0, 0x287b
	jrl nz, SeqStep_DeleteDone
	calr SeqStep_InsertEvent
	jrl SeqStep_DeleteExitRestore
	ldi_berp 0xfa, 0
	jr SeqStep_DeleteConsumeInit
	ldi_berp 0xfa, 1
	jr SeqStep_DeleteConsumeInit

SeqStep_DeleteSetD1:
	ldi_berp 0xfa, 2
	jr SeqStep_DeleteConsumeInit

SeqStep_DeleteSetD2:
	ldi_berp 0xfa, 3
	jr SeqStep_DeleteConsumeInit

SeqStep_DeleteSetOther:
	ldi_berp 0xfa, 5

SeqStep_DeleteConsumeInit:
	lds iz, 0

SeqStep_DeleteConsumeLoop:
	call SeqData_AdvancePosition
	cpdi8 0x287a, 0
	jrl nz, SeqStep_DeleteExitRestore
	inc 1, iz
	ldto_berp A, 0xfa
	extz wa
	cp wa, iz
	jr z, SeqStep_DeleteCleanup
	ldi_berp 0xfb, 0

SeqStep_DeleteConsumeAdvance:
	cps iz, 1
	jr nz, SeqStep_DeleteExit
	call SeqData_ReadNextByte
	cp l, 0x5f
	jr ule, SeqStep_DeleteReturn
	ldda8 a, 9824
	bit 0, a
	jr nz, SeqStep_DeleteFinish
	ldda16 xwa, 0x273e
	ldb w, 0x0
	stda8 0x271c, a
	ldda16 xwa, 0x273c
	extz xwa
	stda32 0x2722, xwa
	ldda8 a, 9824
	set 0, a
	stda8 9824, a

SeqStep_DeleteFinish:
	ldw wa, 0x5f
	call PartCtrl_WriteByte_Indexed
	ldto_berp A, 0xfa
	extz wa
	cp wa, iz
	jr z, SeqStep_DeleteCheck

SeqStep_DeleteReturn:
	ldto_berp A, 0xfa
	extz wa
	cp wa, iz
	jr nz, SeqStep_DeleteConsumeAdvance

SeqStep_DeleteCheck:
	ldi_berp 0xfb, 1
	jrl SeqStep_DeleteExitRestore

SeqStep_DeleteExit:
	call SeqData_AdvancePosition
	cpdi8 0x287a, 0
	jr nz, SeqStep_DeleteExitRestore
	inc 1, iz
	ldto_berp A, 0xfa
	extz wa
	cp wa, iz
	jr nz, SeqStep_DeleteConsumeAdvance
	cpi_berp 0xfb, 0
	jrl z, SeqStep_DeleteConsumeLoop

SeqStep_DeleteCleanup:
	cpi_berp 0xfb, 0
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
	lda_24 xix, Display_FontPalette_Table_0x9A_
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, SeqStep_DeleteExitRestore
	jp_dri 8, 0x07, 0xf0, 0xe0

SeqStep_DeleteExitRestore:
	mrdw5 0x9f, 0x04, 0x19, 0xaf, 0x28
	mrdw5 0x9f, 0x06, 0x19, 0x66, 0x26

SeqStep_DeletePopReturn:
	pop xiz
	inc 4, xsp
	ret

SeqStep_TrackChange:
	dec 4, xsp
	push xiz
	stdi8 0x7f42, 35
	ldda8 c, 9996
	cp c, 0x11
	jr nz, SeqStep_TrackChangeCheck
	ldda8 c, 9994
	cpda8 c, 9992
	jrl z, SeqStep_TrackChangeExit
	ldda8 a, 0x2878
	ldfr_berp A, 0xfb
	dec 1, c
	stda8 0x2878, c
	call SeqVoice_InitAllChannelParams
	ldto_berp A, 0xfb
	stda8 0x2878, a
	calr SeqStep_MultiTrackProcess
	jrl SeqStep_TrackChangeExit

SeqStep_TrackChangeCheck:
	ldda8 e, 9992
	cpda8 e, 9994
	jr nz, SeqStep_TrackChangeCompare
	cpda8 c, 9998
	jrl z, SeqStep_TrackChangeExit

SeqStep_TrackChangeCompare:
	ld a, e
	dec 1, a
	cpda8_24 a, 0xffe3
	jr nz, SeqStep_TrackChangeClear
	ldi_berp 0xfa, 0
	jr SeqStep_TrackChangeSetup

SeqStep_TrackChangeClear:
	ldfr_berp E, 0xfa

SeqStep_TrackChangeSetup:
	ldto_berp A, 0xfa
	extz wa
	extz bc
	call Part_ReadSubBlock32
	ldfr_berp L, 0xf9
	cp_erpb 0xf9, 0x0d
	jr z, SeqStep_TrackChangeDrum
	cp_erpb 0xf9, 0x0e
	jr z, SeqStep_TrackChangeDrum
	cp_erpb 0xf9, 0x0f
	jr z, SeqStep_TrackChangeDrum
	cp_erpb 0xf9, 0x10
	jr nz, SeqStep_TrackChangeNonDrum

SeqStep_TrackChangeDrum:
	ldda8 c, 9994
	ld a, c
	dec 1, a
	cpda8_24 a, 0xffe3
	jr nz, SeqStep_TrackChangeDrumClear
	ldi_berp 0xfa, 0
	jr SeqStep_TrackChangeDrumSetup

SeqStep_TrackChangeDrumClear:
	ldfr_berp C, 0xfa

SeqStep_TrackChangeDrumSetup:
	ldto_berp A, 0xfa
	extz wa
	ldw bc, 0xbd
	call Part_ReadByteDirect
	ldfr_berp L, 0xfb
	cp_erpb 0xfb, 0xff
	jr nz, SeqStep_TrackChangeProcess
	ldw wa, 0x3a
	call SoundCtrl_SaveAndSendCmd_EE
	jrl SeqStep_TrackChangeExit

SeqStep_TrackChangeProcess:
	ldda8 c, 9994
	ld a, c
	dec 1, a
	cpda8_24 a, 0xffe3
	jr nz, SeqStep_TrackChangeStore
	ldi_berp 0xfa, 0
	jr SeqStep_TrackChangeUpdate

SeqStep_TrackChangeStore:
	ldfr_berp C, 0xfa

SeqStep_TrackChangeUpdate:
	ldi_berp 0xfb, 1

SeqStep_TrackChangeAdvance:
	ldto_berp A, 0xfa
	extz wa
	ldto_berp C, 0xfb
	extz bc
	call Part_ReadSubBlock32
	ldto_berp A, 0xf9
	cp a, l
	jr z, SeqStep_TrackChangeLoopBody
	cp_erpb 0xf9, 0x0e
	jr z, SeqStep_TrackChangeLoopCheck
	cp_erpb 0xf9, 0x0d
	jr nz, SeqStep_TrackChangeNext
	cp l, 0xe
	jr z, SeqStep_TrackChangeLoopBody

SeqStep_TrackChangeNext:
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqStep_TrackChangeAdvance

SeqStep_TrackChangeNonDrum:
	cpdi16 0xf231, 0
	jr nz, SeqStep_TrackChangeLoopDone

SeqStep_TrackChangeLoop:
	stdi8 0x7f42, 15
	jrl SeqStep_TrackChangeValidate

SeqStep_TrackChangeLoopCheck:
	cp l, 0xd
	jr nz, SeqStep_TrackChangeNext

SeqStep_TrackChangeLoopBody:
	ldda8 a, 9998
	cp_berp A, 0xfb
	jr z, SeqStep_TrackChangeNonDrum
	ldda8 a, 9994
	dec 1, a
	stda8 0x2710, a
	ldto_berp A, 0xfb
	dec 1, a
	stda8 0x271a, a
	calr SeqStep_BoundaryReturn
	ldto_berp A, 0xfa
	extz wa
	ldto_berp C, 0xfb
	extz bc
	lds de, 0
	call Part_WriteSubBlock32
	cpdi16 0xf231, 0
	jr z, SeqStep_TrackChangeLoop

SeqStep_TrackChangeLoopDone:
	ldda8 a, 9994
	dec 1, a
	stda8 0x2710, a
	ldda8 a, 9998
	dec 1, a
	stda8 0x271a, a
	calr SeqStep_BoundaryReturn
	ldda8 c, 9992
	ld a, c
	dec 1, a
	cpda8_24 a, 0xffe3
	jr nz, SeqStep_TrackChangeLoopReturn
	ldi_berp 0xfa, 0
	jr SeqStep_TrackChangeLoopExit

SeqStep_TrackChangeLoopReturn:
	ldfr_berp C, 0xfa

SeqStep_TrackChangeLoopExit:
	ldto_berp A, 0xfa
	extz wa
	ldda8 c, 9996
	extz bc
	call Part_ReadVoiceWord
	ld (xsp + 4), hl
	ldto_berp A, 0xfa
	extz wa
	ldda8 c, 9996
	extz bc
	call Part_ReadVoiceBit7
	cps l, 0
	jrl z, SeqStep_TrackChangeRecoverDone
	cpw (xsp + 4), 0x0
	jrl z, SeqStep_TrackChangeRecoverDone
	cpw (xsp + 4), 0xffff
	jrl z, SeqStep_TrackChangeRecoverDone
	ldda8 a, 9998
	dec 1, a
	stda8 0x2877, a
	calr SeqStep_DeleteShiftExit
	ld (xsp + 6), hl
	ld wa, (xsp + 4)
	dec 1, wa
	extz xwa
	sll xwa, 8
	inc 5, xwa
	lda_24 xhl, 0x0b0000
	ld xde, xhl
	add xde, xwa
	ld bc, (xsp + 6)
	dec 1, bc
	extz xbc
	sll xbc, 8
	inc 5, xbc
	add xhl, xbc
	ldi_berp 0xfb, 0

SeqStep_TrackChangeFinish:
	ld_spib A, 0xe8
	lda_dpi XBC, 0xec
	inc1_berp 0xfb
	cp_erpb 0xfb, 0xfb
	jr c, SeqStep_TrackChangeFinish
	jrl SeqStep_TrackChangeWriteDone

SeqStep_TrackChangeComplete:
	cpdi16 0xf231, 0
	jr nz, SeqStep_TrackChangeFinal

SeqStep_TrackChangeValidate:
	ldda8 a, 9994
	dec 1, a
	stda8 0x2710, a
	ldda8 a, 9998
	dec 1, a
	stda8 0x271a, a
	calr SeqStep_BoundaryReturn
	stdi8 0x7f42, 15
	jrl SeqStep_TrackChangeExit

SeqStep_TrackChangeFinal:
	call Part_ProcessAndDecrementVoice
	ldfr_werp HL, 0xfa
	ld wa, (xsp + 6)
	ldto_werp BC, 0xfa
	call PartCtrl_WriteWord
	ld iz, (xsp + 6)
	ldto_werp BC, 0xfa
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
	lda_24 xhl, 0x0b0000
	ld xde, xhl
	add xde, xwa
	ld bc, (xsp + 6)
	dec 1, bc
	extz xbc
	sll xbc, 8
	inc 5, xbc
	add xhl, xbc
	ldi_berp 0xfb, 0

SeqStep_TrackChangeWriteBack:
	ld_spib A, 0xe8
	lda_dpi XBC, 0xec
	inc1_berp 0xfb
	cp_erpb 0xfb, 0xfb
	jr c, SeqStep_TrackChangeWriteBack

SeqStep_TrackChangeWriteDone:
	ld wa, (xsp + 4)
	call PartCtrl_ReadWord
	ld (xsp + 4), hl
	cpw (xsp + 4), 0xffff
	jrl nz, SeqStep_TrackChangeComplete
	ldda8 a, 9994
	extz wa
	ldda8 c, 0x2877
	inc 1, c
	extz bc
	ldda16 xde, 0x28af
	call Part_WriteWord_Indexed
	ldda8 a, 9994
	dec 1, a
	cpda8_24 a, 0xffe3
	jr nz, SeqStep_TrackChangeError
	ldda8 c, 0x2877
	inc 1, c
	extz bc
	ldda16 xde, 0x28af
	lds wa, 0
	call Part_WriteWord_Indexed

SeqStep_TrackChangeError:
	ldda8 c, 9992
	ld a, c
	dec 1, a
	cpda8_24 a, 0xffe3
	jr nz, SeqStep_TrackChangeErrorExit
	ldi_berp 0xfa, 0
	jr SeqStep_TrackChangeRecover

SeqStep_TrackChangeErrorExit:
	ldfr_berp C, 0xfa

SeqStep_TrackChangeRecover:
	ldto_berp A, 0xfa
	extz wa
	ldda8 c, 9996
	extz bc
	call Part_ReadByte_Indexed
	ldfr_berp L, 0xfb
	ldda8 a, 9994
	extz wa
	ldda8 c, 0x2877
	inc 1, c
	extz bc
	ldto_berp E, 0xfb
	extz de
	call Part_WriteByte_Indexed
	ldda8 a, 9994
	dec 1, a
	cpda8_24 a, 0xffe3
	jr nz, SeqStep_TrackChangeRecoverDone
	ldda8 c, 0x2877
	inc 1, c
	extz bc
	ldto_berp E, 0xfb
	extz de
	lds wa, 0
	call Part_WriteByte_Indexed

SeqStep_TrackChangeRecoverDone:
	ldda8 c, 9992
	ld a, c
	dec 1, a
	cpda8_24 a, 0xffe3
	jr nz, SeqStep_TrackChangeRecoverStore
	ldi_berp 0xfa, 0
	jr SeqStep_TrackChangeRecoverReturn

SeqStep_TrackChangeRecoverStore:
	ldfr_berp C, 0xfa

SeqStep_TrackChangeRecoverReturn:
	ldto_berp A, 0xfa
	extz wa
	ldda8 c, 9996
	extz bc
	call Part_ReadSubBlock32
	ldfr_berp L, 0xfb
	ldda8 a, 9994
	extz wa
	ldda8 c, 9998
	extz bc
	ldto_berp E, 0xfb
	extz de
	call Part_WriteSubBlock32
	ldda8 a, 9994
	dec 1, a
	cpda8_24 a, 0xffe3
	jr nz, SeqStep_TrackChangeRecoverAdvance
	ldda8 c, 9998
	extz bc
	ldto_berp E, 0xfb
	extz de
	lds wa, 0
	call Part_WriteSubBlock32

SeqStep_TrackChangeRecoverAdvance:
	ldda8 a, 9994
	extz wa
	ldw bc, 0x1e
	call Part_ReadWord
	ld de, hl
	ldda8 a, 9998
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqStep_TrackChangeRecoverLoop
	slaa bc

SeqStep_TrackChangeRecoverLoop:
	or de, bc
	ldda8 a, 9994
	extz wa
	ldw bc, 0x1e
	call Part_WriteWord
	ldda8 a, 9994
	dec 1, a
	cpda8_24 a, 0xffe3
	jr nz, SeqStep_TrackChangeExit
	ldda8 a, 9998
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqStep_TrackChangeRecoverExit
	slaa bc

SeqStep_TrackChangeRecoverExit:
	ordm16_24 0xffec, xbc

SeqStep_TrackChangeExit:
	pop xiz
	inc 4, xsp
	ret

SeqStep_MultiTrackProcess:
	lda xsp, (xsp - 22)
	push xiz
	stdi8 0x2877, 0

SeqStep_MultiTrackLoop:
	cpdi16 0xf231, 0
	jrl z, SeqStep_MultiTrackCleanup
	ldda8 c, 9992
	ld a, c
	dec 1, a
	cpda8_24 a, 0xffe3
	jr nz, SeqStep_MultiTrackCheck
	ldi_berp 0xf9, 0
	jr SeqStep_MultiTrackAdvance

SeqStep_MultiTrackCheck:
	ldfr_berp C, 0xf9

SeqStep_MultiTrackAdvance:
	ldto_berp A, 0xf9
	extz wa
	ldda8 c, 0x2877
	inc 1, c
	extz bc
	call Part_ReadVoiceBit7
	cps l, 0
	jrl z, SeqStep_PartCopyComplete
	ldto_berp A, 0xf9
	extz wa
	ldda8 c, 0x2877
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
	lda_24 xhl, 0x0b0000
	ld xde, xhl
	add xde, xwa
	ld bc, (xsp + 4)
	dec 1, bc
	extz xbc
	sll xbc, 8
	inc 5, xbc
	add xhl, xbc
	ldi_berp 0xfa, 0

SeqStep_MultiTrackInner:
	ld_spib A, 0xe8
	lda_dpi XBC, 0xec
	inc1_berp 0xfa
	cp_erpb 0xfa, 0xfb
	jr c, SeqStep_MultiTrackInner
	jrl SeqStep_PartCopyFinish

SeqStep_MultiTrackCopyCheck:
	cpdi16 0xf231, 0
	jr nz, SeqStep_PartCopy

SeqStep_MultiTrackCleanup:
	ldda8 a, 0x2878
	ldfr_berp A, 0xfb
	ldda8 a, 9994
	dec 1, a
	stda8 0x2878, a
	call SeqVoice_InitAllChannelParams
	ldto_berp A, 0xfb
	stda8 0x2878, a
	stdi8 0x7f42, 15
	jrl SeqStep_VoiceReassignFinalExit

SeqStep_PartCopy:
	call Part_ProcessAndDecrementVoice
	ldfr_werp HL, 0xfa
	ld wa, (xsp + 4)
	ldto_werp BC, 0xfa
	call PartCtrl_WriteWord
	ldto_werp WA, 0xfa
	lds bc, 1
	call PartCtrl_SetClearBit7
	ldto_werp WA, 0xfa
	ld bc, (xsp + 4)
	call PartCtrl_WriteWord_Off1
	ldto_werp WA, 0xfa
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	ldto_werp WA, 0xfa
	ld (xsp + 4), wa
	ldto_werp WA, 0xfa
	stda16 0x28af, xwa
	ld wa, iz
	dec 1, wa
	extz xwa
	sll xwa, 8
	inc 5, xwa
	lda_24 xhl, 0x0b0000
	ld xde, xhl
	add xde, xwa
	ldto_werp BC, 0xfa
	dec 1, bc
	extz xbc
	sll xbc, 8
	inc 5, xbc
	add xhl, xbc
	ldi_berp 0xfa, 0

SeqStep_PartCopyLoop:
	ld_spib A, 0xe8
	lda_dpi XBC, 0xec
	inc1_berp 0xfa
	cp_erpb 0xfa, 0xfb
	jr c, SeqStep_PartCopyLoop

SeqStep_PartCopyFinish:
	ld wa, iz
	call PartCtrl_ReadWord
	ld iz, hl
	cp iz, 0xffff
	jrl nz, SeqStep_MultiTrackCopyCheck
	ldda8 a, 9994
	extz wa
	ldda8 c, 0x2877
	inc 1, c
	extz bc
	ldda16 xde, 0x28af
	call Part_WriteWord_Indexed
	ldda8 a, 9994
	dec 1, a
	cpda8_24 a, 0xffe3
	jr nz, SeqStep_PartCopyUpdateSrc
	ldda8 c, 0x2877
	inc 1, c
	extz bc
	ldda16 xde, 0x28af
	lds wa, 0
	call Part_WriteWord_Indexed

SeqStep_PartCopyUpdateSrc:
	ldda8 c, 9992
	ld a, c
	dec 1, a
	cpda8_24 a, 0xffe3
	jr nz, SeqStep_PartCopyClearSrc
	ldi_berp 0xf9, 0
	jr SeqStep_PartCopySetupDest

SeqStep_PartCopyClearSrc:
	ldfr_berp C, 0xf9

SeqStep_PartCopySetupDest:
	ldto_berp A, 0xf9
	extz wa
	ldda8 c, 0x2877
	inc 1, c
	extz bc
	call Part_ReadByte_Indexed
	ldfr_berp L, 0xfb
	ldda8 a, 9994
	extz wa
	ldda8 c, 0x2877
	inc 1, c
	extz bc
	ldto_berp E, 0xfb
	extz de
	call Part_WriteByte_Indexed
	ldda8 a, 9994
	dec 1, a
	cpda8_24 a, 0xffe3
	jr nz, SeqStep_PartCopyComplete
	ldda8 c, 0x2877
	inc 1, c
	extz bc
	ldto_berp E, 0xfb
	extz de
	lds wa, 0
	call Part_WriteByte_Indexed

SeqStep_PartCopyComplete:
	ldda8 a, 0x2877
	inc 1, a
	stda8 0x2877, a
	cp a, 0x10
	jrl c, SeqStep_MultiTrackLoop
	ldi_berp 0xfa, 1

SeqStep_VoiceReassign:
	ldda8 e, 9992
	ld a, e
	dec 1, a
	ldto_berp C, 0xfa
	extz bc
	cpda8_24 a, 0xffe3
	jr nz, SeqStep_VoiceReassignCheck
	lds wa, 0
	jr SeqStep_VoiceReassignSetup

SeqStep_VoiceReassignCheck:
	extz de
	ld wa, de

SeqStep_VoiceReassignSetup:
	call Part_ReadSubBlock32
	ldfr_berp L, 0xfb
	ldda8 a, 9994
	extz wa
	ldto_berp C, 0xfa
	extz bc
	ldto_berp E, 0xfb
	extz de
	call Part_WriteSubBlock32
	ldda8 a, 9994
	dec 1, a
	cpda8_24 a, 0xffe3
	jr nz, SeqStep_VoiceReassignProcess
	ldto_berp C, 0xfa
	extz bc
	ldto_berp E, 0xfb
	extz de
	lds wa, 0
	call Part_WriteSubBlock32

SeqStep_VoiceReassignProcess:
	inc1_berp 0xfa
	cp_erpb 0xfa, 0x10
	jr ule, SeqStep_VoiceReassign
	ldda8 c, 9992
	ld a, c
	dec 1, a
	cpda8_24 a, 0xffe3
	jr nz, SeqStep_VoiceReassignValidate
	ld16_24 xde, 0x00ffec
	jr SeqStep_VoiceReassignStore

SeqStep_VoiceReassignValidate:
	extz bc
	ld wa, bc
	ldw bc, 0x1e
	call Part_ReadWord
	ld de, hl

SeqStep_VoiceReassignStore:
	ldda8 c, 9994
	ld a, c
	dec 1, a
	cpda8_24 a, 0xffe3
	jr nz, SeqStep_VoiceReassignUpdate
	st16_24 0x00ffec, xde
	jr SeqStep_VoiceReassignDone

SeqStep_VoiceReassignUpdate:
	extz bc
	ld wa, bc
	ldw bc, 0x1e
	call Part_WriteWord

SeqStep_VoiceReassignDone:
	ldda8 c, 9992
	ld a, c
	dec 1, a
	ld8_24 e, 0x00ffe3
	cp a, e
	jr nz, SeqStep_VoiceReassignReturn
	ldi_berp 0xf9, 0
	jr SeqStep_VoiceReassignExit

SeqStep_VoiceReassignReturn:
	ldfr_berp C, 0xf9

SeqStep_VoiceReassignExit:
	ldda8 c, 9994
	ld a, c
	dec 1, a
	cp a, e
	jr nz, SeqStep_VoiceReassignError
	ldi_berp 0xfa, 0
	jr SeqStep_VoiceReassignCleanup

SeqStep_VoiceReassignError:
	ldfr_berp C, 0xfa

SeqStep_VoiceReassignCleanup:
	ldto_berp A, 0xf9
	extz wa
	ldw bc, 0xbd
	call Part_ReadByteDirect
	ldfr_berp L, 0xfb
	ldto_berp A, 0xfa
	extz wa
	ldto_berp E, 0xfb
	extz de
	ldw bc, 0xbd
	call Part_WriteByte
	ldto_berp A, 0xf9
	extz wa
	lda xbc, (xsp + 6)
	call SeqData_CopyBlock2K
	ldto_berp A, 0xfa
	extz wa
	lda xbc, (xsp + 6)
	call Part_CopyBlock16
	ldto_berp A, 0xf9
	extz wa
	ldw bc, 0x110
	call Part_ReadWord
	ld de, hl
	ldto_berp A, 0xfa
	extz wa
	ldw bc, 0x110
	call Part_WriteWord
	ldto_berp A, 0xf9
	extz wa
	ldto_berp C, 0xfa
	extz bc
	call Part_CopyToBuffer
	ldda8 c, 9994
	dec 1, c
	ld8_24 a, 0x00ffe3
	cp c, a
	jr nz, SeqStep_VoiceReassignFinalExit
	stda8 7500, a
	ldmm_sd24b 0xe3, 0xff, 0x00, 0x4e, 0x1d
	call SetWall_LoadToneGenData

SeqStep_VoiceReassignFinalExit:
	pop xiz
	lda xsp, (xsp + 22)
	ret

SeqStep_EventAdvance:
	dec 2, xsp
	push xiz
	ldmw2 (xsp + 4), 0x28af
	ldda16 xiz, 9830
	bitda 0, 0x287b
	jr z, SeqStep_EventAdvanceRead
	ldmm16 0x28af, 0x273c
	ldmm16 9830, 0x273e

SeqStep_EventAdvanceCheck:
	call SeqData_AdvancePosition
	cpdi8 0x287a, 0
	jr z, SeqStep_EventAdvanceBit7

SeqStep_EventAdvanceLoop:
	mrdw5 0x9f, 0x04, 0x19, 0xaf, 0x28
	stda16 9830, xiz

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
	cpdi8 0x287a, 0
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
	ldfr_berp L, 0xfa
	ldw wa, 0x81
	call PartCtrl_WriteByte_Indexed

SeqStep_EventAdvanceReturn:
	cp_erpb 0xfa, 0x81
	jr z, SeqStep_EventAdvanceLoop

SeqStep_EventAdvanceError:
	call SeqData_AdvancePosition
	cpdi8 0x287a, 0
	jr nz, SeqStep_EventAdvanceLoop
	ldto_berp A, 0xfa
	ldfr_berp A, 0xfb
	call SeqData_ReadNextByte
	ldfr_berp L, 0xfa
	ldto_berp A, 0xfb
	extz wa
	call PartCtrl_WriteByte_Indexed
	bit_erpb 0xfb, 0x07
	jr z, SeqStep_EventAdvanceReturn
	ldi_berp 0xfa, 0
	jr SeqStep_EventAdvanceError

SeqStep_MeasureRead:
	push xiz
	ldda16 xiz, 0x28af
	ldda16 xwa, 9830
	ldfr_werp WA, 0xfa
	ldda16 xwa, 0x273c
	stda16 0x28af, xwa
	ldmm16 9798, 0x273c
	ldda16 xwa, 0x273e
	stda16 9830, xwa
	ldmm16 9796, 0x273e
	call SeqData_ReadNextByte
	cp l, 0x82
	jrl z, SeqStep_MeasureReadDone
	cp l, 0x81
	jrl z, SeqStep_MeasureReadDone
	call SeqData_AdvancePosition
	cpdi8 0x287a, 0
	jrl nz, SeqStep_MeasureReadDone
	call SeqData_ReadNextByte
	stda8 9804, l
	ldmm16 9800, 9830
	ldmm16 9802, 0x28af
	calr SeqStep_AdvanceHelper1
	cpdi8 0x287a, 0
	jr nz, SeqStep_MeasureReadDone
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, SeqStep_MeasureReadDone
	cp l, 0x81
	jr z, SeqStep_MeasureReadDone

SeqStep_MeasureReadLoop:
	ldda8 a, 9804
	cpda8 a, 9806
	jr ule, SeqStep_MeasureReadCheck
	calr SeqStep_DeleteShiftEvents
	cpdi8 0x287a, 0
	jr nz, SeqStep_MeasureReadDone
	ldmm8 9804, 9806

SeqStep_MeasureReadCheck:
	calr SeqStep_AdvanceHelper1
	cpdi8 0x287a, 0
	jr nz, SeqStep_MeasureReadDone
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, SeqStep_MeasureReadProcess
	cp l, 0x81
	jr nz, SeqStep_MeasureReadLoop

SeqStep_MeasureReadProcess:
	calr SeqStep_SkipToHighBit
	cpdi8 0x287a, 0
	jr nz, SeqStep_MeasureReadDone
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, SeqStep_MeasureReadDone
	cp l, 0x81
	jr z, SeqStep_MeasureReadDone
	ldmm16 9800, 9830
	ldmm16 9802, 0x28af
	calr SeqStep_AdvanceHelper1
	cpdi8 0x287a, 0
	jr nz, SeqStep_MeasureReadDone
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, SeqStep_MeasureReadDone
	cp l, 0x81
	jr nz, SeqStep_MeasureReadLoop

SeqStep_MeasureReadDone:
	stda16 0x28af, xiz
	ldto_werp WA, 0xfa
	stda16 9830, xwa
	pop xiz
	ret

SeqStep_SkipToHighBit:
	ldmm16 9830, 9796
	ldmm16 0x28af, 9798
	call SeqData_AdvancePosition
	cpdi8 0x287a, 0
	ret nz

SeqStep_SkipLoop:
	call SeqData_ReadNextByte
	bit 7, l
	jr nz, SeqStep_SkipCheck
	call SeqData_AdvancePosition
	cpdi8 0x287a, 0
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
	cpdi8 0x287a, 0
	ret nz
	call SeqData_ReadNextByte
	stda8 9804, l
	ret

SeqStep_AdvanceHelper1:
	ldmm16 9830, 9800
	ldmm16 0x28af, 9802
	call SeqData_AdvancePosition
	cpdi8 0x287a, 0
	ret nz

SeqStep_AdvanceHelper2:
	call SeqData_ReadNextByte
	bit 7, l
	jr nz, SeqStep_AdvanceHelper2Loop
	call SeqData_AdvancePosition
	cpdi8 0x287a, 0
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
	cpdi8 0x287a, 0
	ret nz
	call SeqData_ReadNextByte
	stda8 9806, l
	ret

SeqStep_DecrementPos:
	ldda16 xwa, 0x273e
	cps wa, 5
	jr z, SeqStep_DecrementCheck
	dec 1, wa
	stda8 0x2720, a
	ldmm16 0x2726, 0x273c
	jr SeqStep_DecrementStore

SeqStep_DecrementCheck:
	ldda16 xwa, 0x273c
	call PartCtrl_ReadWord_Off1
	cps hl, 0
	ret z
	stda16 0x2726, xhl
	stdi8 0x2720, 255

SeqStep_DecrementStore:
	stdi8 9826, 1
	ret

SeqStep_WalkWithCallback:
	dec 2, xsp
	push_werp 0xfa
	ldi_berp 0xfb, 0
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
	inc1_berp 0xfb

SeqStep_WalkCbCountCheck:
	cpi_berp 0xfb, 2
	jr nz, SeqStep_WalkCbLoop
	lds hl, 0

SeqStep_WalkCbReturn:
	pop_werp 0xfa
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
	ldda16 xwa, 0x28c1
	cps wa, 5
	jr nz, SeqStep_WalkAdvancePos
	ldda16 xwa, 0x28bf
	call PartCtrl_ReadWord_Off1
	cps hl, 0
	jr nz, SeqStep_WalkUpdatePos
	ldw hl, 0xffff
	ret

SeqStep_WalkUpdatePos:
	stda16 0x28bf, xhl
	stdi16 0x28c1, 255
	jr SeqStep_WalkAdvanceDone

SeqStep_WalkAdvancePos:
	inc 1, wa
	stda16 0x28c1, xwa

SeqStep_WalkAdvanceDone:
	lds hl, 0
	ret

SeqStep_WalkReadByte:
	ldda16 xwa, 0x28c1
	ld c, a
	extz bc
	ldda16 xwa, 0x28bf
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
	ldda16 xiz, 9830
	cp iz, 0xff
	jr z, SeqStep_InsertValidate
	ldw wa, 0x81
	call PartCtrl_WriteByte_Indexed
	incdi16 1, 9830
	ldw wa, 0x82
	call PartCtrl_WriteByte_Indexed
	ldda8 c, 9780
	extz bc
	ldda16 xde, 9830
	lds wa, 0
	jr SeqStep_InsertError

SeqStep_InsertValidate:
	cpdi16 0xf231, 0
	jr z, SeqStep_InsertDone
	ldw wa, 0x81
	call PartCtrl_WriteByte_Indexed
	call PartCtrl_ReadWordRoutine
	ldfr_werp HL, 0xfa
	ldda16 xwa, 0x28af
	ldto_werp BC, 0xfa
	call PartCtrl_WriteWord
	ldda16 xbc, 0x28af
	ldto_werp WA, 0xfa
	call PartCtrl_WriteWord_Off1
	ldto_werp WA, 0xfa
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	ldto_werp WA, 0xfa
	lds bc, 5
	ldw de, 0x82
	call PartCtrl_WriteByteToBuf
	ldda8 c, 9780
	extz bc
	lds wa, 0
	ldto_werp DE, 0xfa
	call Part_WriteWord_Indexed
	ldda8 c, 9780
	extz bc
	lds wa, 0
	lds de, 5

SeqStep_InsertError:
	call Part_WriteByte_Indexed

SeqStep_InsertDone:
	mrdw5 0x9f, 0x04, 0x19, 0xaf, 0x28
	stda16 9830, xiz
	pop xiz
	inc 2, xsp
	ret

SeqStep_PrepareReadBack:
	push xiz
	ldda16 xiz, 0x28af
	ldda16 xwa, 9830
	ldfr_werp WA, 0xfa
	stda16 0x28c1, xwa
	ldda16 xwa, 9830
	cps wa, 5
	jr nz, SeqStep_PrepareCheck
	ldda16 xwa, 0x28af
	call PartCtrl_ReadWord_Off1
	stda16 0x28af, xhl
	stdi16 9830, 255
	jr SeqStep_PrepareDone

SeqStep_PrepareCheck:
	dec 1, wa
	stda16 9830, xwa

SeqStep_PrepareDone:
	call SeqData_ReadNextByte
	stda16 0x28af, xiz
	ldto_werp WA, 0xfa
	stda16 9830, xwa
	pop xiz
	ret

SeqStep_DeleteShiftEvents:
	dec 8, xsp
	push xiz
	ldmm16 0x288b, 9802
	ldmm16 0x2889, 9800
	call SeqPart_ReadByte_Secondary
	lds wa, 0
	ldi_werp 0xfa, 1
	extz xwa
	lda xbc, (xsp + 4)
	add xbc, xwa
	ld (xbc), l
	call PartCtrl_AdvanceReadPos
	cpdi8 0x287a, 0
	jr z, SeqStep_DeleteShiftAdvance
	jrl SeqStep_DeleteShiftCleanup

SeqStep_DeleteShiftLoop:
	call PartCtrl_AdvanceReadPos
	cpdi8 0x287a, 0
	jrl nz, SeqStep_DeleteShiftCleanup

SeqStep_DeleteShiftAdvance:
	call SeqPart_ReadByte_Secondary
	ldto_werp WA, 0xfa
	inc1_werp 0xfa
	extz xwa
	lda xbc, (xsp + 4)
	add xbc, xwa
	ld (xbc), l
	bit 7, l
	jr z, SeqStep_DeleteShiftLoop
	dec1_werp 0xfa
	call PartCtrl_NavigateBackward
	ldmm16 0x2887, 0x288b
	ldmm16 0x2885, 0x2889
	ldmm16 0x288b, 9802
	ldmm16 0x2889, 9800
	call PartCtrl_NavigateBackward

SeqStep_DeleteShiftDone:
	call SeqPart_ReadByte_Secondary
	ldda16 xwa, 0x288b
	cpda16 xwa, 9798
	jr nz, SeqStep_DeleteShiftReturn
	ldda16 xwa, 0x2889
	cpda16 xwa, 9796
	jr nz, SeqStep_DeleteShiftReturn
	extz hl
	ld wa, hl
	call SeqPart_WriteByte_Primary
	ldmm16 0x2887, 9798
	ldmm16 0x2885, 9796
	lds iz, 0
	cpi_werp 0xfa, 0
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
	cpdi8 0x287a, 0
	jr z, SeqStep_DeleteShiftError
	jr SeqStep_DeleteShiftCleanup

SeqStep_DeleteShiftReturn:
	extz hl
	ld wa, hl
	call SeqPart_WriteByte_Primary
	call PartCtrl_NavigateBackward
	cpdi8 0x287a, 0
	jr nz, SeqStep_DeleteShiftCleanup
	call PartCtrl_NavigateBackwardAlt
	cpdi8 0x287a, 0
	jr z, SeqStep_DeleteShiftDone
	jr SeqStep_DeleteShiftCleanup

SeqStep_DeleteShiftError:
	inc 1, iz
	cp_werp IZ, 0xfa
	jr c, SeqStep_DeleteShiftUpdate

SeqStep_DeleteShiftCleanup:
	pop xiz
	inc 8, xsp
	ret

SeqStep_DeleteShiftExit:
	pushw iz
	cpdi16 0xf231, 0
	jr nz, SeqStep_DeleteShiftFinal
	ldw hl, 0xffff
	jr SeqStep_BoundaryCheckB

SeqStep_DeleteShiftFinal:
	call PartCtrl_ReadWordRoutine
	ld iz, hl
	stda16 0x28af, xiz
	ld wa, iz
	lds bc, 1
	call PartCtrl_SetClearBit7
	ld wa, iz
	lds bc, 0
	call PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	ldda8 a, 9994
	extz wa
	ldda8 c, 0x2877
	inc 1, c
	extz bc
	lds de, 1
	call Part_SetClearVoiceBit7
	ldda8 a, 9994
	extz wa
	ldda8 c, 0x2877
	inc 1, c
	extz bc
	ld de, iz
	call Part_WriteVoiceWord
	ldda8 a, 9994
	dec 1, a
	cpda8_24 a, 0xffe3
	jr nz, SeqStep_BoundaryCheckA
	ldda8 c, 0x2877
	inc 1, c
	extz bc
	lds wa, 0
	lds de, 1
	call Part_SetClearVoiceBit7
	ldda8 c, 0x2877
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
	push_werp 0xfa
	ldda8 a, 0x2710
	cpda8_24 a, 0xffe3
	jr nz, SeqStep_BoundaryProcess
	ldi_berp 0xfb, 0
	jr SeqStep_BoundaryAdvance

SeqStep_BoundaryProcess:
	inc 1, a
	ldfr_berp A, 0xfb

SeqStep_BoundaryAdvance:
	ldto_berp A, 0xfb
	extz wa
	ldda8 c, 0x271a
	inc 1, c
	extz bc
	call Part_ReadVoiceBit7
	cps l, 0
	jrl z, SeqStep_BoundaryFinal
	ldto_berp A, 0xfb
	extz wa
	ldda8 c, 0x271a
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
	ldda8 a, 0x2710
	inc 1, a
	extz wa
	ldda8 c, 0x271a
	inc 1, c
	extz bc
	lds de, 0
	call Part_SetClearVoiceBit7
	ldda8 a, 0x2710
	inc 1, a
	extz wa
	ldda8 c, 0x271a
	inc 1, c
	extz bc
	ldw de, 0xffff
	call Part_WriteVoiceWord
	ldda8 a, 0x2710
	cpda8_24 a, 0xffe3
	jr nz, SeqStep_BoundaryError
	ldda8 c, 0x271a
	inc 1, c
	extz bc
	lds wa, 0
	lds de, 0
	call Part_SetClearVoiceBit7
	ldda8 c, 0x271a
	inc 1, c
	extz bc
	lds wa, 0
	ldw de, 0xffff
	call Part_WriteVoiceWord

SeqStep_BoundaryError:
	ldda8 a, 0x2710
	inc 1, a
	extz wa
	ldda8 c, 0x271a
	inc 1, c
	extz bc
	ldw de, 0xffff
	call Part_WriteWord_Indexed
	ldda8 a, 0x2710
	inc 1, a
	extz wa
	ldda8 c, 0x271a
	inc 1, c
	extz bc
	lds de, 5
	call Part_WriteByte_Indexed
	ldda8 a, 0x2710
	cpda8_24 a, 0xffe3
	jr nz, SeqStep_BoundaryFinal
	ldda8 c, 0x271a
	inc 1, c
	extz bc
	lds wa, 0
	ldw de, 0xffff
	call Part_WriteWord_Indexed
	ldda8 c, 0x271a
	inc 1, c
	extz bc
	lds wa, 0
	lds de, 5
	call Part_WriteByte_Indexed

SeqStep_BoundaryFinal:
	pop_werp 0xfa
	ret

SeqStep_SkipIfLeftFlag:
	bitda 0, 0x2879
	jr z, SeqStep_SkipIfLeftDone
	call PartCtrl_AdvanceReadPos
	cpdi8 0x287a, 0
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
	cpdi8 0x287a, 0
	jr nz, SeqStep_AdvanceOneDone
	call PartCtrl_AdvanceReadPos
	cpdi8 0x287a, 0
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
	cpdi8 0x287a, 0
	jr nz, SeqStep_SkipThreeError
	call PartCtrl_AdvanceReadPos
	cpdi8 0x287a, 0
	jr nz, SeqStep_SkipThreeError
	call PartCtrl_AdvanceReadPos
	cpdi8 0x287a, 0
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
	ldda8 a, 0x2879
	and a, 0x3
	jr z, SeqStep_ProcessC0SavePos
	call PartCtrl_AdvanceReadPos
	cpdi8 0x287a, 0
	jr nz, SeqStep_ProcessC0Error
	jr SeqStep_ProcessC0Done

SeqStep_ProcessC0SavePos:
	ldda16 xwa, 0x288b
	ldfr_werp WA, 0xfa
	ldda16 xiz, 0x2889
	calr SeqStep_SkipThreeEvents
	cps hl, 0
	jr nz, SeqStep_ProcessC0Done
	ldto_werp WA, 0xfa
	stda16 0x288b, xwa
	stda16 0x2889, xiz
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
	cpdi8 0x287a, 0
	jr nz, SeqStep_ProcessC0Error
	call PartCtrl_AdvanceReadPos
	cpdi8 0x287a, 0
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
	stda8 4340, a
	ld a, (xsp + 6)
	and a, 0x2
	sll a, 6
	stda8 3310, a
	ldda16 xwa, 0x288b
	ldfr_werp WA, 0xfa
	ldda16 xiz, 0x2889
	calr SeqStep_ParseRhythm
	ldto_werp WA, 0xfa
	stda16 0x288b, xwa
	stda16 0x2889, xiz
	cpdi8 0x287a, 0
	jr nz, SeqStep_ProcessB0Error
	ldda8 a, 0x289d
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
	cpdi8 0x287a, 0
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
	ldda8 a, 3387
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
	cpdi8 0x287a, 0
	jr nz, SeqStep_ParseRhythmCheck
	call PartCtrl_AdvanceReadPos
	cpdi8 0x287a, 0
	jr nz, SeqStep_ParseRhythmCheck
	stdi8 3387, 255
	call SeqPart_ReadByte_Secondary
	res 7, l
	ldda8 a, 4340
	or a, l
	stda8 4340, a
	cp a, 0x48
	jr z, SeqStep_ParseRhythmError
	ldda8 c, 0x289d
	res 2, c
	stda8 0x289d, c
	ldda8 e, 0x2873
	extz de
	lda_24 xhl, FontPalette_Gradient7_0x32_
	ldda8 a, 4340
	cp_srib_rm A, 0x07, 0xec, 0xe8
	jr z, SeqStep_ParseRhythmLoop
	res 0, c
	res 2, c
	stda8 0x289d, c
	jrl SeqStep_ParseRhythmComplete

SeqStep_ParseRhythmLoop:
	call PartCtrl_AdvanceReadPos
	cpdi8 0x287a, 0
	jr z, SeqStep_ParseRhythmAdvance

SeqStep_ParseRhythmCheck:
	ldw hl, 0xffff
	ret

SeqStep_ParseRhythmAdvance:
	call SeqPart_ReadByte_Secondary
	ldda8 c, 0x289d
	cps l, 3
	jr c, SeqStep_ParseRhythmProcess
	cp l, 0xb
	jr ugt, SeqStep_ParseRhythmProcess
	cps l, 6
	jr nz, SeqStep_ParseRhythmStore

SeqStep_ParseRhythmProcess:
	res 0, c
	res 2, c
	stda8 0x289d, c
	jrl SeqStep_ParseRhythmComplete

SeqStep_ParseRhythmStore:
	ldda8 a, 0x2879
	and a, 0x3
	jr nz, SeqStep_ParseRhythmReturn

SeqStep_ParseRhythmDone:
	setda 0, 0x289d
	jr SeqStep_ParseRhythmValidate

SeqStep_ParseRhythmReturn:
	cps l, 3
	jr z, SeqStep_ParseRhythmDone
	res 0, c
	res 2, c
	stda8 0x289d, c
	jr SeqStep_ParseRhythmComplete

SeqStep_ParseRhythmError:
	call PartCtrl_AdvanceReadPos
	cpdi8 0x287a, 0
	jr nz, SeqStep_ParseRhythmComplete
	call SeqPart_ReadByte_Secondary
	cps l, 5
	jr z, SeqStep_ParseRhythmExit
	ldda8 a, 0x289d
	res 2, a
	stda8 0x289d, a
	cpdi8 0x2873, 12
	jr z, SeqStep_ParseRhythmSkip
	res 0, a
	res 2, a
	stda8 0x289d, a
	jr SeqStep_ParseRhythmComplete

SeqStep_ParseRhythmSkip:
	cps l, 3
	jr nz, SeqStep_ParseRhythmCleanup
	set 0, a
	stda8 0x289d, a

SeqStep_ParseRhythmValidate:
	stda8 3388, l
	jr SeqStep_ParseRhythmComplete

SeqStep_ParseRhythmCleanup:
	res 0, a
	res 2, a
	stda8 0x289d, a
	jr SeqStep_ParseRhythmComplete

SeqStep_ParseRhythmExit:
	resda 0, 0x289d
	call PartCtrl_AdvanceReadPos
	cpdi8 0x287a, 0
	jr nz, SeqStep_ParseRhythmComplete
	call PartCtrl_AdvanceReadPos
	cpdi8 0x287a, 0
	jr nz, SeqStep_ParseRhythmComplete
	call SeqPart_ReadByte_Secondary
	ldda8 a, 3310
	and a, 0xfc
	jr z, SeqStep_ParseRhythmFinal
	setda 2, 0x289d
	jr SeqStep_ParseRhythmComplete

SeqStep_ParseRhythmFinal:
	resda 2, 0x289d

SeqStep_ParseRhythmComplete:
	lds hl, 0
	ret

SeqStep_CommitEvent:
	extz wa
	call SeqPart_WriteByte_Primary
	ldda16 xwa, 0x2885
	ld c, a
	extz bc
	ldda16 xwa, 0x2887
	call Part_WriteWordAndByte
	ldda16 xwa, 0x2887
	jp Part_CheckAndReallocVoices

SeqStep_ProcessC0Ext:
	dec 4, xsp
	push xiz
	ld (xsp + 6), a
	ldda8 a, 0x2879
	and a, 0x3
	jr z, SeqStep_ProcessC0ExtCheck
	call PartCtrl_AdvanceReadPos
	cpdi8 0x287a, 0
	jr nz, SeqStep_ProcessC0ExtReturn
	jr SeqStep_ProcessC0ExtFinal

SeqStep_ProcessC0ExtCheck:
	bitda 1, 4393
	jr nz, SeqStep_ProcessC0ExtProcess
	ldda16 xwa, 0x288b
	ldfr_werp WA, 0xfa
	ldda16 xiz, 0x2889
	calr SeqStep_SkipThreeEvents
	cps hl, 0
	jr nz, SeqStep_ProcessC0ExtFinal
	ldto_werp WA, 0xfa
	stda16 0x288b, xwa
	stda16 0x2889, xiz

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
	cpdi8 0x287a, 0
	jr nz, SeqStep_ProcessC0ExtReturn
	call PartCtrl_AdvanceReadPos
	cpdi8 0x287a, 0
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
	stda8 4340, a
	ld a, (xsp + 6)
	and a, 0x2
	sll a, 6
	stda8 3310, a
	bitda 1, 4393
	jr nz, SeqStep_ProcessB0ExtSkip
	ldda16 xwa, 0x288b
	ldfr_werp WA, 0xfa
	ldda16 xiz, 0x2889
	calr SeqPart_EventLoopContinue
	ldto_werp WA, 0xfa
	stda16 0x288b, xwa
	stda16 0x2889, xiz
	cpdi8 0x287a, 0
	jr nz, SeqStep_ProcessB0ExtExit
	ldda8 a, 0x289d
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
	cpdi8 0x287a, 0
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
	ldda8 a, 3387
	cp a, 0xff
	jr z, SeqStep_ProcessB0ExtReturn
	bitda 1, 4393
	jr nz, SeqStep_ProcessB0ExtReturn
	ld (xsp + 6), a

SeqStep_ProcessB0ExtReturn:
	ld a, (xsp + 6)
	extz wa
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceToNextEntry
	cpdi8 0x287a, 0
	jr nz, SeqStep_ProcessB0ExtExit
	call PartCtrl_AdvanceReadPos
	cpdi8 0x287a, 0
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
	bitda 1, 4393
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
	ldda8 a, 8956
	extz wa
	sla wa, 2
	lda_24 xbc, Display_FontPalette_Table_0xA8_
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	jp (xhl)

SeqStep_TimerDispatchB:
	ldda8 a, 8956
	extz wa
	sla wa, 2
	lda_24 xbc, Display_FontPalette_Table_0x104_
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	jp (xhl)

SeqStep_TimerDispatchC:
	ldda8 a, 8956
	extz wa
	sla wa, 2
	lda_24 xbc, Display_FontPalette_Table_0x160_
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	jp (xhl)

SeqStep_PlaybackStateMachine:
	push_werp 0xfa
	ldda8 a, 7518
	cps a, 0
	jr z, SeqStep_PlaybackDecrCount
	dec 1, a
	stda8 7518, a

SeqStep_PlaybackDecrCount:
	ei 6
	ldda8 a, 1057
	ldfr_berp A, 0xfb
	res 1, a
	res 4, a
	stda8 1057, a
	ei 0
	cpdi16 0x28a8, 0
	jr nz, SeqStep_PlaybackCheck10408
	bit_erpb 0xfb, 0x04
	jr z, SeqStep_PlaybackCheckFill
	cpdi16 0x28b4, 0
	jr nz, SeqStep_PlaybackCallFill

SeqStep_PlaybackCheckFill:
	bit_erpb 0xfb, 0x04
	jr z, SeqStep_PlaybackCheckBeat
	bitda 0, 0x28c5
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
	cpdi16 0x28b4, 0
	jr z, SeqStep_PlaybackNoAction
	call SeqNote_ProcessNoteOn
	jr SeqStep_PlaybackResultDispatch

SeqStep_PlaybackNoAction:
	ldb l, 0x0
	jr SeqStep_PlaybackReturn

SeqStep_PlaybackCheck10408:
	bit_erpb 0xfb, 0x04
	jr z, SeqStep_PlaybackCheckFill2
	cpdi16 0x28aa, 0
	jr nz, SeqStep_PlaybackCallExtFill

SeqStep_PlaybackCheckFill2:
	bit_erpb 0xfb, 0x04
	jr z, SeqStep_PlaybackCheckBeat2
	bitda 0, 0x28c5
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
	cpdi16 0x28aa, 0
	jr nz, SeqStep_PlaybackCallPattern
	cpdi16 0x28b4, 0
	jr z, SeqStep_PlaybackNoAction
	bitda 0, 0x28c5
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
	pop_werp 0xfa
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
	stdi16 0xf1ce, 0x4d80
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
	stda16 0xf1ce, xwa
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
	ldda32 xde, 7514
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
	ldi_berp 0xfa, 1

SeqStep_UpdateRefsCheck:
	ldi_berp 0xfb, 1

SeqStep_UpdateRefsAdvance:
	ldto_berp A, 0xfa
	extz wa
	ldto_berp C, 0xfb
	extz bc
	call Part_ReadVoiceBit7
	cps l, 0
	jr z, SeqStep_UpdateRefsDone
	ldto_berp A, 0xfa
	extz wa
	ldto_berp C, 0xfb
	extz bc
	call Part_ReadVoiceWord
	cp hl, (xsp + 4)
	jr nz, SeqStep_UpdateRefsDone
	ldto_berp A, 0xfa
	extz wa
	ldto_berp C, 0xfb
	extz bc
	ld de, iz
	call Part_WriteVoiceWord

SeqStep_UpdateRefsDone:
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqStep_UpdateRefsAdvance
	inc1_berp 0xfa
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
	ldi_berp 0xfa, 1

SeqStep_UpdateLinksCheck:
	ldi_berp 0xfb, 1

SeqStep_UpdateLinksAdvance:
	ldto_berp A, 0xfa
	extz wa
	ldto_berp C, 0xfb
	add_berp C, 0xfb
	add c, 0x76
	extz bc
	call Part_ReadWord
	cp hl, (xsp + 4)
	jr nz, SeqStep_UpdateLinksDone
	ldto_berp A, 0xfa
	extz wa
	ldto_berp C, 0xfb
	add_berp C, 0xfb
	add c, 0x76
	extz bc
	ld de, iz
	call Part_WriteWord

SeqStep_UpdateLinksDone:
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqStep_UpdateLinksAdvance
	inc1_berp 0xfa
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
	stdi16 0xf231, 0
	stdi16 0xf22f, 0xffff
	jrl SeqStep_RebuildReturn

SeqStep_RebuildLoop:
	mrdw5 0x9f, 0x02, 0x19, 0x2f, 0xf2
	stdi16 0xf231, 0
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
	incdi16 1, 0xf231
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
	incdi16 1, 0xf231
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
	incdi16 1, 0xf231

SeqStep_RebuildReturn:
	popw iz
	inc 2, xsp
	ret

SeqStep_ByteBlockEA5F:
	.byte 0xef, 0x6a, 0x3e, 0xc2, 0xe3, 0xff, 0x00, 0x19
	.byte 0x47, 0xf2, 0xd2, 0xec, 0xff, 0x00, 0x19, 0x48
	.byte 0xf2, 0xc2, 0xe3, 0xff, 0x00, 0x21, 0xd8, 0x12
	.byte 0x1d, 0x0b, 0x14, 0xf4, 0x1e, 0x36, 0xfd, 0xd1
	.byte 0xce, 0xf1, 0x20, 0xd7, 0xfa, 0x98, 0xd1, 0x31
	.byte 0xf2, 0x26, 0xbf, 0x04, 0x16, 0x2f, 0xf2, 0xc2
	.byte 0xe3, 0xff, 0x00, 0x21, 0xd8, 0x12, 0x1d, 0x26
	.byte 0x14, 0xf4, 0xd7, 0xfa, 0x88, 0xf1, 0xce, 0xf1
	.byte 0x50, 0xf1, 0x31, 0xf2, 0x56, 0x9f, 0x04, 0x19
	.byte 0x2f, 0xf2, 0x5e, 0xef, 0x62, 0x0e, 0xc1, 0x47
	.byte 0xf2, 0x21, 0xf2, 0xe3, 0xff, 0x00, 0x41, 0xf1
	.byte 0x47, 0xf2, 0x00, 0x00, 0xd1, 0x48, 0xf2, 0x20
	.byte 0xf2, 0xec, 0xff, 0x00, 0x50, 0xf1, 0x48, 0xf2
	.byte 0x02, 0x00, 0x00, 0xf1, 0x68, 0x26, 0x02, 0x01
	.byte 0x00, 0xf1, 0xa7, 0x28, 0xb3, 0x78, 0xd3, 0xfc

SeqStep_ReinitPartTable:
	dec 6, xsp
	push xiz
	ld8_24 a, 0x00ffe3
	extz wa
	call SeqData_CopyBlockToBuffer
	ld8_24 e, 0x00ffe3
	extz de
	lds wa, 1
	ldw bc, 0xc7
	call Part_WriteByte
	ld16_24 xde, 0x00ffec
	lds wa, 1
	ldw bc, 0xc8
	call Part_WriteWord
	calr SeqStep_FindAndCompact
	ld (xsp + 4), xhl
	ldda16 xiz, 0xf1ce
	ldda16 xwa, 0xf22f
	ldfr_werp WA, 0xfa
	ldmw2 (xsp + 8), 0xf231
	ld8_24 a, 0x00ffe3
	extz wa
	call VoicePreset_LoadAndInitPan
	stda16 0xf1ce, xiz
	ldto_werp WA, 0xfa
	stda16 0xf22f, xwa
	mrdw5 0x9f, 0x08, 0x19, 0x31, 0xf2
	ldto_werp WA, 0xfa
	call Part_WriteWordBlock_OffsetAF
	ldda16 xwa, 0xf231
	call Part_SetAllVoicePos
	ldi_berp 0xfb, 1

SeqStep_ReinitLoop:
	ldto_berp A, 0xfb
	extz wa
	ldda16 xde, 0xf1ce
	ldw bc, 0x4e
	call Part_WriteWord
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x0a
	jr ule, SeqStep_ReinitLoop
	ld xhl, (xsp + 4)
	pop xiz
	inc 6, xsp
	ret

SeqStep_MemAllocWrapper:
	push xiz
	ld wa, (xsp + 8)
	exts xwa
	push xwa
	pushw 0x0
	call SeqStep_MallocWrapper
	inc 6, xsp
	ld xiz, xhl
	or xiz, xiz
	jr z, SeqStep_MemAllocFail
	ld wa, (xsp + 8)
	pushw wa
	pushw 0x0
	push xiz
	call Memset
	inc 8, xsp
	jr SeqStep_MemAllocReturn

SeqStep_MemAllocFail:
	sti16_24 0x01e53c, 0x0003

SeqStep_MemAllocReturn:
	ld xhl, xiz
	pop xiz
	ret
