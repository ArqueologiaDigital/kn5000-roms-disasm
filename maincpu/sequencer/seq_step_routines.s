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
	bitda 0, 10363
	jrl z, SeqStep_NoteExit
	ldmw2 (xsp + 4), 0x28AF
	ldmw2 (xsp + 6), 0x2666

SeqStep_NoteReadEvent:
	ldmm16 9830, 10046
	ldmm16 10415, 10044
	call SeqData_ReadNextByte
	ld a, l
	cp l, 0xD2
	jrl z, SeqStep_NoteSetD2
	cp l, 0xD3
	jrl z, SeqStep_NoteSetD1
	cp l, 0xD1
	jr z, SeqStep_NoteSetD1
	cp l, 0xD0
	jr z, SeqStep_NoteSetD1
	extz wa
	sub wa, 0x80
	cps wa, 0
	jr lt, SeqStep_NoteSetOther
	cps wa, 6
	jr gt, SeqStep_NoteSetOther
	add wa, wa
	lda_24 xix, 0xe44ed6
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf4cead
	jp_dri 8, 0x07, 0xF0, 0xE0

SeqStep_NoteByteBlock:
	.byte 0xc1, 0x1c, 0x27, 0x21, 0xc9, 0xcc, 0xff, 0xd8
	.byte 0x12, 0xf1, 0x66, 0x26, 0x50, 0xe1, 0x22, 0x27
	.byte 0x20, 0xf1, 0xaf, 0x28, 0x50, 0x1d, 0xa6, 0x21
	.byte 0xf4, 0xf1, 0xd6, 0x25, 0x47, 0x30, 0x81, 0x00
	.byte 0x1d, 0xb5, 0x21, 0xf4, 0xc1, 0xd6, 0x25, 0x3f
	.byte 0x81, 0x66, 0x49, 0x1d, 0x52, 0x00, 0xf4, 0xc1
	.byte 0x7a, 0x28, 0x3f, 0x00, 0x6e, 0x3e, 0xc1, 0xd6
	.byte 0x25, 0x19, 0xd8, 0x25, 0x1d, 0xa6, 0x21, 0xf4
	.byte 0xf1, 0xd6, 0x25, 0x47, 0xc1, 0xd8, 0x25, 0x21
	.byte 0xd8, 0x12, 0x68, 0xd4, 0xc7, 0xf9, 0xa8, 0x68
	.byte 0x12, 0xc7, 0xf9, 0xa9, 0x68, 0x0d

SeqStep_NoteSetD1:
	ldi_berp 0xF9, 2
	jr SeqStep_NoteConsumeInit

SeqStep_NoteSetD2:
	ldi_berp 0xF9, 3
	jr SeqStep_NoteConsumeInit

SeqStep_NoteSetOther:
	ldi_berp 0xF9, 5

SeqStep_NoteConsumeInit:
	ldi_berp 0xFB, 0

SeqStep_NoteConsumeLoop:
	ldi_berp 0xFA, 0
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr z, SeqStep_NoteConsumeAdvance
	mrdw5 0x9F, 0x04, 0x19, 0xAF, 0x28
	mrdw5 0x9F, 0x06, 0x19, 0x66, 0x26
	jrl SeqStep_NoteExit

SeqStep_NoteConsumeAdvance:
	inc1_berp 0xFB
	ldto_berp A, 0xF9
	cp_berp A, 0xFB
	jr nz, SeqStep_NoteCheckVel
	call SeqData_AdvancePosition
	ldmm16 10044, 10415
	ldmm16 10046, 9830
	jrl SeqStep_NoteReadEvent

SeqStep_NoteCheckVel:
	cpi_berp 0xFB, 1
	jr nz, SeqStep_NoteVelContinue
	call SeqData_ReadNextByte
	cp l, 0x5F
	jr ule, SeqStep_NoteVelSkip
	ldda8 a, 9824
	bit 0, a
	jr nz, SeqStep_NoteVelSave
	ldda16 xwa, 10046
	ldb w, 0x0
	stda8 10012, a
	ldda16 xwa, 10044
	extz xwa
	stda32 10018, xwa
	ldda8 a, 9824
	set 0, a
	stda8 9824, a

SeqStep_NoteVelSave:
	call SeqData_ReadNextByte
	sub l, 0x60
	extz hl
	ld wa, hl
	call PartCtrl_WriteByte_Indexed
	ldto_berp A, 0xFB
	cp_berp A, 0xF9
	jr z, SeqStep_NoteReturn
	cpi_berp 0xFA, 1
	jrl nz, SeqStep_NoteConsumeLoop
	jrl SeqStep_NoteReadEvent

SeqStep_NoteVelSkip:
	ldto_berp A, 0xFB
	cp_berp A, 0xF9
	jr z, SeqStep_NoteReturn

SeqStep_NoteVelContinue:
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr z, SeqStep_NoteExitRestore

SeqStep_NoteExit:
	pop xiz
	inc 4, xsp
	ret

SeqStep_NoteExitRestore:
	inc1_berp 0xFB
	ldto_berp A, 0xFB
	cp_berp A, 0xF9
	jr nz, SeqStep_NoteCheckVel

SeqStep_NoteReturn:
	call SeqData_AdvancePosition
	ldmm16 10044, 10415
	ldmm16 10046, 9830
	ldi_berp 0xFA, 1
	jrl SeqStep_NoteReadEvent

SeqStep_EventProcess:
	dec 6, xsp
	push xiz
	ld (xsp + 8), bc
	ld iz, wa
	stdi8 10014, 0
	ldmw2 (xsp + 6), 0x28AF
	ldmw2 (xsp + 4), 0x2666
	ldmm16 10415, 10044
	ldmm16 9830, 10046
	call SeqPos_DecrementAndCheck
	ldada xbc, 10288
	ldda16 xwa, 10415
	ld (xbc), wa
	ldmw2 (xbc + 2), 0x2666
	ldmm16 10415, 10044
	ldmm16 9830, 10046
	ldda8 a, 10362
	cps a, 0
	jr z, SeqStep_EventPosManage
	cp a, 0xA
	jrl nz, SeqStep_EventExit
	stdi8 10362, 0
	cpdi16 9778, 1
	jr nz, SeqStep_EventPosManage
	cps iz, 0
	jr nz, SeqStep_EventPosManage
	cpw (xsp + 8), 0x0
	jr nz, SeqStep_EventPosManage
	stdi8 10014, 1

SeqStep_EventPosManage:
	stdi8 9824, 0
	stdi8 9826, 0
	bitda 0, 10363
	jrl nz, SeqStep_EventPosConsumeAdvance
	jrl SeqStep_EventExit
	bitda 0, 9824
	jr z, SeqStep_EventPosCheck
	bitda 0, 9826
	call_24 z, 0xF4DD4F

SeqStep_EventPosCheck:
	ldda32 xwa, 10018
	stda16 10379, xwa
	ldda8 a, 10012
	and a, 0xFF
	extz wa
	stda16 10377, xwa
	ldada xwa, 10288
	mriw4 0x90, 0x19, 0x87, 0x28
	mrdw5 0x98, 0x02, 0x19, 0x85, 0x28

SeqStep_EventPosUpdate:
	ldda16 xwa, 10379
	cpda16 xwa, 10022
	jr nz, SeqStep_EventPosAdvance
	ldda8 a, 10016
	extz wa
	cpda16 xwa, 10377
	jr nz, SeqStep_EventPosAdvance
	call SeqPart_ReadByte_Secondary
	extz hl
	ld wa, hl
	call SeqPart_WriteByte_Primary
	ldmm16 10415, 10022
	ldda8 a, 10016
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
	cpdi8 10362, 0
	jr z, SeqStep_EventPosUpdate
	jrl SeqStep_EventExit
	ldi_berp 0xFA, 0
	jr SeqStep_EventPosSetNote
	ldi_berp 0xFA, 1
	jr SeqStep_EventPosSetNote

SeqStep_EventPosSetD1:
	ldi_berp 0xFA, 2
	jr SeqStep_EventPosSetNote

SeqStep_EventPosSetD2:
	ldi_berp 0xFA, 3
	jr SeqStep_EventPosSetNote

SeqStep_EventPosSetD3:
	ldi_berp 0xFA, 5

SeqStep_EventPosSetNote:
	ldi_berp 0xF9, 0

SeqStep_EventPosConsumeLoop:
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jrl nz, SeqStep_EventExit
	inc1_berp 0xF9
	ldto_berp A, 0xFA
	cp_berp A, 0xF9
	jr nz, SeqStep_EventPosReturn

SeqStep_EventPosConsumeCheck:
	call SeqData_AdvancePosition
	ldmm16 10044, 10415
	ldmm16 10046, 9830

SeqStep_EventPosConsumeAdvance:
	ldmm16 10415, 10044
	ldmm16 9830, 10046
	call SeqData_ReadNextByte
	ld a, l
	cp l, 0xD2
	jr z, SeqStep_EventPosSetD2
	cp l, 0xD3
	jr z, SeqStep_EventPosSetD1
	cp l, 0xD1
	jr z, SeqStep_EventPosSetD1
	cp l, 0xD0
	jr z, SeqStep_EventPosSetD1
	extz wa
	sub wa, 0x80
	cps wa, 0
	jr lt, SeqStep_EventPosSetD3
	cps wa, 6
	jr gt, SeqStep_EventPosSetD3
	add wa, wa
	lda_24 xix, 0xe44ee4
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf4d171
	jp_dri 8, 0x07, 0xF0, 0xE0

SeqStep_EventPosFinish:
	.byte 0xf1, 0x1e, 0x27, 0xc8, 0x76, 0xe3, 0xfe, 0x68
	.byte 0x38

SeqStep_EventPosReturn:
	ldi_berp 0xFB, 0

SeqStep_EventPosExit:
	cpi_berp 0xF9, 1
	jr nz, SeqStep_EventPosDone
	call SeqData_ReadNextByte
	bit 7, l
	jr nz, SeqStep_EventStorePos
	cp l, 0x5F
	jr ugt, SeqStep_EventStorePos
	bitda 0, 9824
	jr z, SeqStep_EventPosComplete
	bitda 0, 9826
	call_24 z, 0xF4DD4F

SeqStep_EventPosComplete:
	ldto_berp A, 0xF9
	cp_berp A, 0xFA
	jr z, SeqStep_EventRestore

SeqStep_EventPosDone:
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr z, SeqStep_EventCleanup

SeqStep_EventExit:
	mrdw5 0x9F, 0x06, 0x19, 0xAF, 0x28
	mrdw5 0x9F, 0x04, 0x19, 0x66, 0x26
	pop xiz
	inc 6, xsp
	ret

SeqStep_EventCleanup:
	inc1_berp 0xF9
	ldto_berp A, 0xF9
	cp_berp A, 0xFA
	jr nz, SeqStep_EventPosExit

SeqStep_EventRestore:
	call SeqData_AdvancePosition
	ldmm16 10044, 10415
	ldmm16 10046, 9830
	ldi_berp 0xFB, 1
	jrl SeqStep_EventPosConsumeAdvance

SeqStep_EventStorePos:
	cpi_berp 0xFB, 1
	jrl z, SeqStep_EventPosConsumeAdvance
	ldda8 a, 9824
	bit 0, a
	jr nz, SeqStep_EventSetState
	ldda16 xwa, 10046
	stda8 10012, a
	ldda16 xwa, 10044
	extz xwa
	stda32 10018, xwa
	ldda8 a, 9824
	set 0, a
	stda8 9824, a

SeqStep_EventSetState:
	ldb l, 0x0
	bitda 0, 10014
	jr nz, SeqStep_EventAdvancePos
	call SeqData_ReadNextByte
	add l, 0x60

SeqStep_EventAdvancePos:
	extz hl
	ld wa, hl
	call PartCtrl_WriteByte_Indexed
	ldto_berp A, 0xF9
	cp_berp A, 0xFA
	jrl z, SeqStep_EventPosConsumeCheck
	jrl SeqStep_EventPosConsumeLoop

SeqStep_VelNoteFwd:
	ldda16 xwa, 9778
	cps wa, 1
	ret z
	ldda8 c, 9780
	stda16 10367, xwa
	extz bc
	ld wa, bc
	lds bc, 0
	call SeqVoice_SeekToBar
	cpdi8 10362, 0
	ret nz
	calr SeqStep_WalkWithCallback
	cps hl, 0
	jr nz, SeqStep_VelNoteFwdApply
	ldmm16 10415, 10431
	ldmm16 9830, 10433
	call SeqData_AdvancePosition

SeqStep_VelNoteFwdApply:
	ldmm16 10046, 9830
	ldmm16 10044, 10415
	jrl SeqStep_MeasureRead

SeqStep_VelNoteBwd:
	ldda8 c, 9780
	inc 1, wa
	stda16 10367, xwa
	extz bc
	ld wa, bc
	lds bc, 0
	call SeqVoice_SeekToBar
	cpdi8 10362, 0
	ret nz
	ldmm16 10044, 10415
	ldmm16 10046, 9830
	jrl SeqStep_MeasureRead

SeqStep_DeleteEvent:
	dec 4, xsp
	push xiz
	ldmw2 (xsp + 4), 0x28AF
	ldmw2 (xsp + 6), 0x2666
	ldda8 a, 9740
	bit 7, a
	jrl nz, SeqStep_DeletePopReturn
	bitda 0, 10363
	jrl nz, SeqStep_DeleteDone
	calr SeqStep_InsertEvent
	jrl SeqStep_DeleteExitRestore
	ldi_berp 0xFA, 0
	jr SeqStep_DeleteConsumeInit
	ldi_berp 0xFA, 1
	jr SeqStep_DeleteConsumeInit

SeqStep_DeleteSetD1:
	ldi_berp 0xFA, 2
	jr SeqStep_DeleteConsumeInit

SeqStep_DeleteSetD2:
	ldi_berp 0xFA, 3
	jr SeqStep_DeleteConsumeInit

SeqStep_DeleteSetOther:
	ldi_berp 0xFA, 5

SeqStep_DeleteConsumeInit:
	lds iz, 0

SeqStep_DeleteConsumeLoop:
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jrl nz, SeqStep_DeleteExitRestore
	inc 1, iz
	ldto_berp A, 0xFA
	extz wa
	cp wa, iz
	jr z, SeqStep_DeleteCleanup
	ldi_berp 0xFB, 0

SeqStep_DeleteConsumeAdvance:
	cps iz, 1
	jr nz, SeqStep_DeleteExit
	call SeqData_ReadNextByte
	cp l, 0x5F
	jr ule, SeqStep_DeleteReturn
	ldda8 a, 9824
	bit 0, a
	jr nz, SeqStep_DeleteFinish
	ldda16 xwa, 10046
	ldb w, 0x0
	stda8 10012, a
	ldda16 xwa, 10044
	extz xwa
	stda32 10018, xwa
	ldda8 a, 9824
	set 0, a
	stda8 9824, a

SeqStep_DeleteFinish:
	ldw wa, 0x5F
	call PartCtrl_WriteByte_Indexed
	ldto_berp A, 0xFA
	extz wa
	cp wa, iz
	jr z, SeqStep_DeleteCheck

SeqStep_DeleteReturn:
	ldto_berp A, 0xFA
	extz wa
	cp wa, iz
	jr nz, SeqStep_DeleteConsumeAdvance

SeqStep_DeleteCheck:
	ldi_berp 0xFB, 1
	jrl SeqStep_DeleteExitRestore

SeqStep_DeleteExit:
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr nz, SeqStep_DeleteExitRestore
	inc 1, iz
	ldto_berp A, 0xFA
	extz wa
	cp wa, iz
	jr nz, SeqStep_DeleteConsumeAdvance
	cpi_berp 0xFB, 0
	jrl z, SeqStep_DeleteConsumeLoop

SeqStep_DeleteCleanup:
	cpi_berp 0xFB, 0
	jr nz, SeqStep_DeleteExitRestore
	call SeqData_AdvancePosition
	ldmm16 10044, 10415
	ldmm16 10046, 9830

SeqStep_DeleteDone:
	ldmm16 9830, 10046
	ldmm16 10415, 10044
	call SeqData_ReadNextByte
	ld a, l
	cp l, 0xD2
	jrl z, SeqStep_DeleteSetD2
	cp l, 0xD3
	jrl z, SeqStep_DeleteSetD1
	cp l, 0xD1
	jrl z, SeqStep_DeleteSetD1
	cp l, 0xD0
	jrl z, SeqStep_DeleteSetD1
	extz wa
	sub wa, 0x80
	cps wa, 0
	jrl lt, SeqStep_DeleteSetOther
	cps wa, 6
	jrl gt, SeqStep_DeleteSetOther
	add wa, wa
	lda_24 xix, 0xe44ef2
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf4d3cd
	jp_dri 8, 0x07, 0xF0, 0xE0

SeqStep_DeleteExitRestore:
	mrdw5 0x9F, 0x04, 0x19, 0xAF, 0x28
	mrdw5 0x9F, 0x06, 0x19, 0x66, 0x26

SeqStep_DeletePopReturn:
	pop xiz
	inc 4, xsp
	ret

SeqStep_TrackChange:
	dec 4, xsp
	push xiz
	stdi8 32578, 35
	ldda8 c, 9996
	cp c, 0x11
	jr nz, SeqStep_TrackChangeCheck
	ldda8 c, 9994
	cpda8 c, 9992
	jrl z, SeqStep_TrackChangeExit
	ldda8 a, 10360
	ldfr_berp A, 0xFB
	dec 1, c
	stda8 10360, c
	call SeqVoice_InitAllChannelParams
	ldto_berp A, 0xFB
	stda8 10360, a
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
	cpda8_24 a, 65507
	jr nz, SeqStep_TrackChangeClear
	ldi_berp 0xFA, 0
	jr SeqStep_TrackChangeSetup

SeqStep_TrackChangeClear:
	ldfr_berp E, 0xFA

SeqStep_TrackChangeSetup:
	ldto_berp A, 0xFA
	extz wa
	extz bc
	call Part_ReadSubBlock32
	ldfr_berp L, 0xF9
	cp_erpb 0xF9, 0x0D
	jr z, SeqStep_TrackChangeDrum
	cp_erpb 0xF9, 0x0E
	jr z, SeqStep_TrackChangeDrum
	cp_erpb 0xF9, 0x0F
	jr z, SeqStep_TrackChangeDrum
	cp_erpb 0xF9, 0x10
	jr nz, SeqStep_TrackChangeNonDrum

SeqStep_TrackChangeDrum:
	ldda8 c, 9994
	ld a, c
	dec 1, a
	cpda8_24 a, 65507
	jr nz, SeqStep_TrackChangeDrumClear
	ldi_berp 0xFA, 0
	jr SeqStep_TrackChangeDrumSetup

SeqStep_TrackChangeDrumClear:
	ldfr_berp C, 0xFA

SeqStep_TrackChangeDrumSetup:
	ldto_berp A, 0xFA
	extz wa
	ldw bc, 0xBD
	call Part_ReadByteDirect
	ldfr_berp L, 0xFB
	cp_erpb 0xFB, 0xFF
	jr nz, SeqStep_TrackChangeProcess
	ldw wa, 0x3A
	call SoundCtrl_SaveAndSendCmd_EE
	jrl SeqStep_TrackChangeExit

SeqStep_TrackChangeProcess:
	ldda8 c, 9994
	ld a, c
	dec 1, a
	cpda8_24 a, 65507
	jr nz, SeqStep_TrackChangeStore
	ldi_berp 0xFA, 0
	jr SeqStep_TrackChangeUpdate

SeqStep_TrackChangeStore:
	ldfr_berp C, 0xFA

SeqStep_TrackChangeUpdate:
	ldi_berp 0xFB, 1

SeqStep_TrackChangeAdvance:
	ldto_berp A, 0xFA
	extz wa
	ldto_berp C, 0xFB
	extz bc
	call Part_ReadSubBlock32
	ldto_berp A, 0xF9
	cp a, l
	jr z, SeqStep_TrackChangeLoopBody
	cp_erpb 0xF9, 0x0E
	jr z, SeqStep_TrackChangeLoopCheck
	cp_erpb 0xF9, 0x0D
	jr nz, SeqStep_TrackChangeNext
	cp l, 0xE
	jr z, SeqStep_TrackChangeLoopBody

SeqStep_TrackChangeNext:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, SeqStep_TrackChangeAdvance

SeqStep_TrackChangeNonDrum:
	cpdi16 62001, 0
	jr nz, SeqStep_TrackChangeLoopDone

SeqStep_TrackChangeLoop:
	stdi8 32578, 15
	jrl SeqStep_TrackChangeValidate

SeqStep_TrackChangeLoopCheck:
	cp l, 0xD
	jr nz, SeqStep_TrackChangeNext

SeqStep_TrackChangeLoopBody:
	ldda8 a, 9998
	cp_berp A, 0xFB
	jr z, SeqStep_TrackChangeNonDrum
	ldda8 a, 9994
	dec 1, a
	stda8 10000, a
	ldto_berp A, 0xFB
	dec 1, a
	stda8 10010, a
	calr SeqStep_BoundaryReturn
	ldto_berp A, 0xFA
	extz wa
	ldto_berp C, 0xFB
	extz bc
	lds de, 0
	call Part_WriteSubBlock32
	cpdi16 62001, 0
	jr z, SeqStep_TrackChangeLoop

SeqStep_TrackChangeLoopDone:
	ldda8 a, 9994
	dec 1, a
	stda8 10000, a
	ldda8 a, 9998
	dec 1, a
	stda8 10010, a
	calr SeqStep_BoundaryReturn
	ldda8 c, 9992
	ld a, c
	dec 1, a
	cpda8_24 a, 65507
	jr nz, SeqStep_TrackChangeLoopReturn
	ldi_berp 0xFA, 0
	jr SeqStep_TrackChangeLoopExit

SeqStep_TrackChangeLoopReturn:
	ldfr_berp C, 0xFA

SeqStep_TrackChangeLoopExit:
	ldto_berp A, 0xFA
	extz wa
	ldda8 c, 9996
	extz bc
	call Part_ReadVoiceWord
	ld (xsp + 4), hl
	ldto_berp A, 0xFA
	extz wa
	ldda8 c, 9996
	extz bc
	call Part_ReadVoiceBit7
	cps l, 0
	jrl z, SeqStep_TrackChangeRecoverDone
	cpw (xsp + 4), 0x0
	jrl z, SeqStep_TrackChangeRecoverDone
	cpw (xsp + 4), 0xFFFF
	jrl z, SeqStep_TrackChangeRecoverDone
	ldda8 a, 9998
	dec 1, a
	stda8 10359, a
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
	ldi_berp 0xFB, 0

SeqStep_TrackChangeFinish:
	ld_spib A, 0xE8
	lda_dpi XBC, 0xEC
	inc1_berp 0xFB
	cp_erpb 0xFB, 0xFB
	jr c, SeqStep_TrackChangeFinish
	jrl SeqStep_TrackChangeWriteDone

SeqStep_TrackChangeComplete:
	cpdi16 62001, 0
	jr nz, SeqStep_TrackChangeFinal

SeqStep_TrackChangeValidate:
	ldda8 a, 9994
	dec 1, a
	stda8 10000, a
	ldda8 a, 9998
	dec 1, a
	stda8 10010, a
	calr SeqStep_BoundaryReturn
	stdi8 32578, 15
	jrl SeqStep_TrackChangeExit

SeqStep_TrackChangeFinal:
	call Part_ProcessAndDecrementVoice
	ldfr_werp HL, 0xFA
	ld wa, (xsp + 6)
	ldto_werp BC, 0xFA
	call PartCtrl_WriteWord
	ld iz, (xsp + 6)
	ldto_werp BC, 0xFA
	ld wa, bc
	ld (xsp + 6), bc
	lds bc, 1
	call PartCtrl_SetClearBit7
	ld wa, (xsp + 6)
	ld bc, iz
	call PartCtrl_WriteWord_Off1
	ld wa, (xsp + 6)
	ldw bc, 0xFFFF
	call PartCtrl_WriteWord
	mrdw5 0x9F, 0x06, 0x19, 0xAF, 0x28
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
	ldi_berp 0xFB, 0

SeqStep_TrackChangeWriteBack:
	ld_spib A, 0xE8
	lda_dpi XBC, 0xEC
	inc1_berp 0xFB
	cp_erpb 0xFB, 0xFB
	jr c, SeqStep_TrackChangeWriteBack

SeqStep_TrackChangeWriteDone:
	ld wa, (xsp + 4)
	call PartCtrl_ReadWord
	ld (xsp + 4), hl
	cpw (xsp + 4), 0xFFFF
	jrl nz, SeqStep_TrackChangeComplete
	ldda8 a, 9994
	extz wa
	ldda8 c, 10359
	inc 1, c
	extz bc
	ldda16 xde, 10415
	call Part_WriteWord_Indexed
	ldda8 a, 9994
	dec 1, a
	cpda8_24 a, 65507
	jr nz, SeqStep_TrackChangeError
	ldda8 c, 10359
	inc 1, c
	extz bc
	ldda16 xde, 10415
	lds wa, 0
	call Part_WriteWord_Indexed

SeqStep_TrackChangeError:
	ldda8 c, 9992
	ld a, c
	dec 1, a
	cpda8_24 a, 65507
	jr nz, SeqStep_TrackChangeErrorExit
	ldi_berp 0xFA, 0
	jr SeqStep_TrackChangeRecover

SeqStep_TrackChangeErrorExit:
	ldfr_berp C, 0xFA

SeqStep_TrackChangeRecover:
	ldto_berp A, 0xFA
	extz wa
	ldda8 c, 9996
	extz bc
	call Part_ReadByte_Indexed
	ldfr_berp L, 0xFB
	ldda8 a, 9994
	extz wa
	ldda8 c, 10359
	inc 1, c
	extz bc
	ldto_berp E, 0xFB
	extz de
	call Part_WriteByte_Indexed
	ldda8 a, 9994
	dec 1, a
	cpda8_24 a, 65507
	jr nz, SeqStep_TrackChangeRecoverDone
	ldda8 c, 10359
	inc 1, c
	extz bc
	ldto_berp E, 0xFB
	extz de
	lds wa, 0
	call Part_WriteByte_Indexed

SeqStep_TrackChangeRecoverDone:
	ldda8 c, 9992
	ld a, c
	dec 1, a
	cpda8_24 a, 65507
	jr nz, SeqStep_TrackChangeRecoverStore
	ldi_berp 0xFA, 0
	jr SeqStep_TrackChangeRecoverReturn

SeqStep_TrackChangeRecoverStore:
	ldfr_berp C, 0xFA

SeqStep_TrackChangeRecoverReturn:
	ldto_berp A, 0xFA
	extz wa
	ldda8 c, 9996
	extz bc
	call Part_ReadSubBlock32
	ldfr_berp L, 0xFB
	ldda8 a, 9994
	extz wa
	ldda8 c, 9998
	extz bc
	ldto_berp E, 0xFB
	extz de
	call Part_WriteSubBlock32
	ldda8 a, 9994
	dec 1, a
	cpda8_24 a, 65507
	jr nz, SeqStep_TrackChangeRecoverAdvance
	ldda8 c, 9998
	extz bc
	ldto_berp E, 0xFB
	extz de
	lds wa, 0
	call Part_WriteSubBlock32

SeqStep_TrackChangeRecoverAdvance:
	ldda8 a, 9994
	extz wa
	ldw bc, 0x1E
	call Part_ReadWord
	ld de, hl
	ldda8 a, 9998
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, SeqStep_TrackChangeRecoverLoop
	slaa bc

SeqStep_TrackChangeRecoverLoop:
	or de, bc
	ldda8 a, 9994
	extz wa
	ldw bc, 0x1E
	call Part_WriteWord
	ldda8 a, 9994
	dec 1, a
	cpda8_24 a, 65507
	jr nz, SeqStep_TrackChangeExit
	ldda8 a, 9998
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, SeqStep_TrackChangeRecoverExit
	slaa bc

SeqStep_TrackChangeRecoverExit:
	ordm16_24 65516, xbc

SeqStep_TrackChangeExit:
	pop xiz
	inc 4, xsp
	ret

SeqStep_MultiTrackProcess:
	lda xsp, (xsp - 22)
	push xiz
	stdi8 10359, 0

SeqStep_MultiTrackLoop:
	cpdi16 62001, 0
	jrl z, SeqStep_MultiTrackCleanup
	ldda8 c, 9992
	ld a, c
	dec 1, a
	cpda8_24 a, 65507
	jr nz, SeqStep_MultiTrackCheck
	ldi_berp 0xF9, 0
	jr SeqStep_MultiTrackAdvance

SeqStep_MultiTrackCheck:
	ldfr_berp C, 0xF9

SeqStep_MultiTrackAdvance:
	ldto_berp A, 0xF9
	extz wa
	ldda8 c, 10359
	inc 1, c
	extz bc
	call Part_ReadVoiceBit7
	cps l, 0
	jrl z, SeqStep_PartCopyComplete
	ldto_berp A, 0xF9
	extz wa
	ldda8 c, 10359
	inc 1, c
	extz bc
	call Part_ReadVoiceWord
	ld iz, hl
	cps iz, 0
	jrl z, SeqStep_PartCopyComplete
	cp iz, 0xFFFF
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
	ldi_berp 0xFA, 0

SeqStep_MultiTrackInner:
	ld_spib A, 0xE8
	lda_dpi XBC, 0xEC
	inc1_berp 0xFA
	cp_erpb 0xFA, 0xFB
	jr c, SeqStep_MultiTrackInner
	jrl SeqStep_PartCopyFinish

SeqStep_MultiTrackCopyCheck:
	cpdi16 62001, 0
	jr nz, SeqStep_PartCopy

SeqStep_MultiTrackCleanup:
	ldda8 a, 10360
	ldfr_berp A, 0xFB
	ldda8 a, 9994
	dec 1, a
	stda8 10360, a
	call SeqVoice_InitAllChannelParams
	ldto_berp A, 0xFB
	stda8 10360, a
	stdi8 32578, 15
	jrl SeqStep_VoiceReassignFinalExit

SeqStep_PartCopy:
	call Part_ProcessAndDecrementVoice
	ldfr_werp HL, 0xFA
	ld wa, (xsp + 4)
	ldto_werp BC, 0xFA
	call PartCtrl_WriteWord
	ldto_werp WA, 0xFA
	lds bc, 1
	call PartCtrl_SetClearBit7
	ldto_werp WA, 0xFA
	ld bc, (xsp + 4)
	call PartCtrl_WriteWord_Off1
	ldto_werp WA, 0xFA
	ldw bc, 0xFFFF
	call PartCtrl_WriteWord
	ldto_werp WA, 0xFA
	ld (xsp + 4), wa
	ldto_werp WA, 0xFA
	stda16 10415, xwa
	ld wa, iz
	dec 1, wa
	extz xwa
	sll xwa, 8
	inc 5, xwa
	lda_24 xhl, 0x0b0000
	ld xde, xhl
	add xde, xwa
	ldto_werp BC, 0xFA
	dec 1, bc
	extz xbc
	sll xbc, 8
	inc 5, xbc
	add xhl, xbc
	ldi_berp 0xFA, 0

SeqStep_PartCopyLoop:
	ld_spib A, 0xE8
	lda_dpi XBC, 0xEC
	inc1_berp 0xFA
	cp_erpb 0xFA, 0xFB
	jr c, SeqStep_PartCopyLoop

SeqStep_PartCopyFinish:
	ld wa, iz
	call PartCtrl_ReadWord
	ld iz, hl
	cp iz, 0xFFFF
	jrl nz, SeqStep_MultiTrackCopyCheck
	ldda8 a, 9994
	extz wa
	ldda8 c, 10359
	inc 1, c
	extz bc
	ldda16 xde, 10415
	call Part_WriteWord_Indexed
	ldda8 a, 9994
	dec 1, a
	cpda8_24 a, 65507
	jr nz, SeqStep_PartCopyUpdateSrc
	ldda8 c, 10359
	inc 1, c
	extz bc
	ldda16 xde, 10415
	lds wa, 0
	call Part_WriteWord_Indexed

SeqStep_PartCopyUpdateSrc:
	ldda8 c, 9992
	ld a, c
	dec 1, a
	cpda8_24 a, 65507
	jr nz, SeqStep_PartCopyClearSrc
	ldi_berp 0xF9, 0
	jr SeqStep_PartCopySetupDest

SeqStep_PartCopyClearSrc:
	ldfr_berp C, 0xF9

SeqStep_PartCopySetupDest:
	ldto_berp A, 0xF9
	extz wa
	ldda8 c, 10359
	inc 1, c
	extz bc
	call Part_ReadByte_Indexed
	ldfr_berp L, 0xFB
	ldda8 a, 9994
	extz wa
	ldda8 c, 10359
	inc 1, c
	extz bc
	ldto_berp E, 0xFB
	extz de
	call Part_WriteByte_Indexed
	ldda8 a, 9994
	dec 1, a
	cpda8_24 a, 65507
	jr nz, SeqStep_PartCopyComplete
	ldda8 c, 10359
	inc 1, c
	extz bc
	ldto_berp E, 0xFB
	extz de
	lds wa, 0
	call Part_WriteByte_Indexed

SeqStep_PartCopyComplete:
	ldda8 a, 10359
	inc 1, a
	stda8 10359, a
	cp a, 0x10
	jrl c, SeqStep_MultiTrackLoop
	ldi_berp 0xFA, 1

SeqStep_VoiceReassign:
	ldda8 e, 9992
	ld a, e
	dec 1, a
	ldto_berp C, 0xFA
	extz bc
	cpda8_24 a, 65507
	jr nz, SeqStep_VoiceReassignCheck
	lds wa, 0
	jr SeqStep_VoiceReassignSetup

SeqStep_VoiceReassignCheck:
	extz de
	ld wa, de

SeqStep_VoiceReassignSetup:
	call Part_ReadSubBlock32
	ldfr_berp L, 0xFB
	ldda8 a, 9994
	extz wa
	ldto_berp C, 0xFA
	extz bc
	ldto_berp E, 0xFB
	extz de
	call Part_WriteSubBlock32
	ldda8 a, 9994
	dec 1, a
	cpda8_24 a, 65507
	jr nz, SeqStep_VoiceReassignProcess
	ldto_berp C, 0xFA
	extz bc
	ldto_berp E, 0xFB
	extz de
	lds wa, 0
	call Part_WriteSubBlock32

SeqStep_VoiceReassignProcess:
	inc1_berp 0xFA
	cp_erpb 0xFA, 0x10
	jr ule, SeqStep_VoiceReassign
	ldda8 c, 9992
	ld a, c
	dec 1, a
	cpda8_24 a, 65507
	jr nz, SeqStep_VoiceReassignValidate
	ld16_24 xde, 0x00ffec
	jr SeqStep_VoiceReassignStore

SeqStep_VoiceReassignValidate:
	extz bc
	ld wa, bc
	ldw bc, 0x1E
	call Part_ReadWord
	ld de, hl

SeqStep_VoiceReassignStore:
	ldda8 c, 9994
	ld a, c
	dec 1, a
	cpda8_24 a, 65507
	jr nz, SeqStep_VoiceReassignUpdate
	st16_24 0x00ffec, xde
	jr SeqStep_VoiceReassignDone

SeqStep_VoiceReassignUpdate:
	extz bc
	ld wa, bc
	ldw bc, 0x1E
	call Part_WriteWord

SeqStep_VoiceReassignDone:
	ldda8 c, 9992
	ld a, c
	dec 1, a
	ld8_24 e, 0x00ffe3
	cp a, e
	jr nz, SeqStep_VoiceReassignReturn
	ldi_berp 0xF9, 0
	jr SeqStep_VoiceReassignExit

SeqStep_VoiceReassignReturn:
	ldfr_berp C, 0xF9

SeqStep_VoiceReassignExit:
	ldda8 c, 9994
	ld a, c
	dec 1, a
	cp a, e
	jr nz, SeqStep_VoiceReassignError
	ldi_berp 0xFA, 0
	jr SeqStep_VoiceReassignCleanup

SeqStep_VoiceReassignError:
	ldfr_berp C, 0xFA

SeqStep_VoiceReassignCleanup:
	ldto_berp A, 0xF9
	extz wa
	ldw bc, 0xBD
	call Part_ReadByteDirect
	ldfr_berp L, 0xFB
	ldto_berp A, 0xFA
	extz wa
	ldto_berp E, 0xFB
	extz de
	ldw bc, 0xBD
	call Part_WriteByte
	ldto_berp A, 0xF9
	extz wa
	lda xbc, (xsp + 6)
	call SeqData_CopyBlock2K
	ldto_berp A, 0xFA
	extz wa
	lda xbc, (xsp + 6)
	call Part_CopyBlock16
	ldto_berp A, 0xF9
	extz wa
	ldw bc, 0x110
	call Part_ReadWord
	ld de, hl
	ldto_berp A, 0xFA
	extz wa
	ldw bc, 0x110
	call Part_WriteWord
	ldto_berp A, 0xF9
	extz wa
	ldto_berp C, 0xFA
	extz bc
	call Part_CopyToBuffer
	ldda8 c, 9994
	dec 1, c
	ld8_24 a, 0x00ffe3
	cp c, a
	jr nz, SeqStep_VoiceReassignFinalExit
	stda8 7500, a
	ldmm_sd24b 0xE3, 0xFF, 0x00, 0x4E, 0x1D
	call SetWall_LoadToneGenData

SeqStep_VoiceReassignFinalExit:
	pop xiz
	lda xsp, (xsp + 22)
	ret

SeqStep_EventAdvance:
	dec 2, xsp
	push xiz
	ldmw2 (xsp + 4), 0x28AF
	ldda16 xiz, 9830
	bitda 0, 10363
	jr z, SeqStep_EventAdvanceRead
	ldmm16 10415, 10044
	ldmm16 9830, 10046

SeqStep_EventAdvanceCheck:
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr z, SeqStep_EventAdvanceBit7

SeqStep_EventAdvanceLoop:
	mrdw5 0x9F, 0x04, 0x19, 0xAF, 0x28
	stda16 9830, xiz

SeqStep_EventAdvanceRead:
	pop xiz
	inc 2, xsp
	ret

SeqStep_EventAdvanceBit7:
	call SeqData_ReadNextByte
	cp l, 0x7F
	jr z, SeqStep_EventAdvanceDone

SeqStep_EventAdvanceStore:
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr nz, SeqStep_EventAdvanceLoop
	call SeqData_ReadNextByte
	bit 7, l
	jr z, SeqStep_EventAdvanceStore
	ldmm16 10044, 10415
	ldmm16 10046, 9830
	jr SeqStep_EventAdvanceCheck

SeqStep_EventAdvanceDone:
	ldmm16 9830, 10046
	ldmm16 10415, 10044
	call SeqData_ReadNextByte
	ldfr_berp L, 0xFA
	ldw wa, 0x81
	call PartCtrl_WriteByte_Indexed

SeqStep_EventAdvanceReturn:
	cp_erpb 0xFA, 0x81
	jr z, SeqStep_EventAdvanceLoop

SeqStep_EventAdvanceError:
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr nz, SeqStep_EventAdvanceLoop
	ldto_berp A, 0xFA
	ldfr_berp A, 0xFB
	call SeqData_ReadNextByte
	ldfr_berp L, 0xFA
	ldto_berp A, 0xFB
	extz wa
	call PartCtrl_WriteByte_Indexed
	bit_erpb 0xFB, 0x07
	jr z, SeqStep_EventAdvanceReturn
	ldi_berp 0xFA, 0
	jr SeqStep_EventAdvanceError

SeqStep_MeasureRead:
	push xiz
	ldda16 xiz, 10415
	ldda16 xwa, 9830
	ldfr_werp WA, 0xFA
	ldda16 xwa, 10044
	stda16 10415, xwa
	ldmm16 9798, 10044
	ldda16 xwa, 10046
	stda16 9830, xwa
	ldmm16 9796, 10046
	call SeqData_ReadNextByte
	cp l, 0x82
	jrl z, SeqStep_MeasureReadDone
	cp l, 0x81
	jrl z, SeqStep_MeasureReadDone
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jrl nz, SeqStep_MeasureReadDone
	call SeqData_ReadNextByte
	stda8 9804, l
	ldmm16 9800, 9830
	ldmm16 9802, 10415
	calr SeqStep_AdvanceHelper1
	cpdi8 10362, 0
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
	cpdi8 10362, 0
	jr nz, SeqStep_MeasureReadDone
	ldmm8 9804, 9806

SeqStep_MeasureReadCheck:
	calr SeqStep_AdvanceHelper1
	cpdi8 10362, 0
	jr nz, SeqStep_MeasureReadDone
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, SeqStep_MeasureReadProcess
	cp l, 0x81
	jr nz, SeqStep_MeasureReadLoop

SeqStep_MeasureReadProcess:
	calr SeqStep_SkipToHighBit
	cpdi8 10362, 0
	jr nz, SeqStep_MeasureReadDone
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, SeqStep_MeasureReadDone
	cp l, 0x81
	jr z, SeqStep_MeasureReadDone
	ldmm16 9800, 9830
	ldmm16 9802, 10415
	calr SeqStep_AdvanceHelper1
	cpdi8 10362, 0
	jr nz, SeqStep_MeasureReadDone
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, SeqStep_MeasureReadDone
	cp l, 0x81
	jr nz, SeqStep_MeasureReadLoop

SeqStep_MeasureReadDone:
	stda16 10415, xiz
	ldto_werp WA, 0xFA
	stda16 9830, xwa
	pop xiz
	ret

SeqStep_SkipToHighBit:
	ldmm16 9830, 9796
	ldmm16 10415, 9798
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	ret nz

SeqStep_SkipLoop:
	call SeqData_ReadNextByte
	bit 7, l
	jr nz, SeqStep_SkipCheck
	call SeqData_AdvancePosition
	cpdi8 10362, 0
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
	ldmm16 9798, 10415
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	ret nz
	call SeqData_ReadNextByte
	stda8 9804, l
	ret

SeqStep_AdvanceHelper1:
	ldmm16 9830, 9800
	ldmm16 10415, 9802
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	ret nz

SeqStep_AdvanceHelper2:
	call SeqData_ReadNextByte
	bit 7, l
	jr nz, SeqStep_AdvanceHelper2Loop
	call SeqData_AdvancePosition
	cpdi8 10362, 0
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
	ldmm16 9802, 10415
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	ret nz
	call SeqData_ReadNextByte
	stda8 9806, l
	ret

SeqStep_DecrementPos:
	ldda16 xwa, 10046
	cps wa, 5
	jr z, SeqStep_DecrementCheck
	dec 1, wa
	stda8 10016, a
	ldmm16 10022, 10044
	jr SeqStep_DecrementStore

SeqStep_DecrementCheck:
	ldda16 xwa, 10044
	call PartCtrl_ReadWord_Off1
	cps hl, 0
	ret z
	stda16 10022, xhl
	stdi8 10016, 255

SeqStep_DecrementStore:
	stdi8 9826, 1
	ret

SeqStep_WalkWithCallback:
	dec 2, xsp
	push_werp 0xFA
	ldi_berp 0xFB, 0
	ldmm16 10433, 9830
	ldmm16 10431, 10415

SeqStep_WalkCbLoop:
	lda xwa, (xsp + 2)
	calr SeqStep_WalkInner
	cps hl, 0
	jr z, SeqStep_WalkCbCheck81
	ldw hl, 0xFFFF
	jr SeqStep_WalkCbReturn

SeqStep_WalkCbCheck81:
	cp (xsp + 2), 0x81
	jr nz, SeqStep_WalkCbCountCheck
	inc1_berp 0xFB

SeqStep_WalkCbCountCheck:
	cpi_berp 0xFB, 2
	jr nz, SeqStep_WalkCbLoop
	lds hl, 0

SeqStep_WalkCbReturn:
	pop_werp 0xFA
	inc 2, xsp
	ret

SeqStep_WalkInner:
	push xiz
	ld xiz, xwa

SeqStep_WalkInnerLoop:
	calr SeqStep_WalkReadNext
	cps hl, 0
	jr z, SeqStep_WalkInnerProcess
	ldw hl, 0xFFFF
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
	ldda16 xwa, 10433
	cps wa, 5
	jr nz, SeqStep_WalkAdvancePos
	ldda16 xwa, 10431
	call PartCtrl_ReadWord_Off1
	cps hl, 0
	jr nz, SeqStep_WalkUpdatePos
	ldw hl, 0xFFFF
	ret

SeqStep_WalkUpdatePos:
	stda16 10431, xhl
	stdi16 10433, 255
	jr SeqStep_WalkAdvanceDone

SeqStep_WalkAdvancePos:
	inc 1, wa
	stda16 10433, xwa

SeqStep_WalkAdvanceDone:
	lds hl, 0
	ret

SeqStep_WalkReadByte:
	ldda16 xwa, 10433
	ld c, a
	extz bc
	ldda16 xwa, 10431
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
	ldmw2 (xsp + 4), 0x28AF
	ldda16 xiz, 9830
	cp iz, 0xFF
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
	cpdi16 62001, 0
	jr z, SeqStep_InsertDone
	ldw wa, 0x81
	call PartCtrl_WriteByte_Indexed
	call PartCtrl_ReadWordRoutine
	ldfr_werp HL, 0xFA
	ldda16 xwa, 10415
	ldto_werp BC, 0xFA
	call PartCtrl_WriteWord
	ldda16 xbc, 10415
	ldto_werp WA, 0xFA
	call PartCtrl_WriteWord_Off1
	ldto_werp WA, 0xFA
	ldw bc, 0xFFFF
	call PartCtrl_WriteWord
	ldto_werp WA, 0xFA
	lds bc, 5
	ldw de, 0x82
	call PartCtrl_WriteByteToBuf
	ldda8 c, 9780
	extz bc
	lds wa, 0
	ldto_werp DE, 0xFA
	call Part_WriteWord_Indexed
	ldda8 c, 9780
	extz bc
	lds wa, 0
	lds de, 5

SeqStep_InsertError:
	call Part_WriteByte_Indexed

SeqStep_InsertDone:
	mrdw5 0x9F, 0x04, 0x19, 0xAF, 0x28
	stda16 9830, xiz
	pop xiz
	inc 2, xsp
	ret

SeqStep_PrepareReadBack:
	push xiz
	ldda16 xiz, 10415
	ldda16 xwa, 9830
	ldfr_werp WA, 0xFA
	stda16 10433, xwa
	ldda16 xwa, 9830
	cps wa, 5
	jr nz, SeqStep_PrepareCheck
	ldda16 xwa, 10415
	call PartCtrl_ReadWord_Off1
	stda16 10415, xhl
	stdi16 9830, 255
	jr SeqStep_PrepareDone

SeqStep_PrepareCheck:
	dec 1, wa
	stda16 9830, xwa

SeqStep_PrepareDone:
	call SeqData_ReadNextByte
	stda16 10415, xiz
	ldto_werp WA, 0xFA
	stda16 9830, xwa
	pop xiz
	ret

SeqStep_DeleteShiftEvents:
	dec 8, xsp
	push xiz
	ldmm16 10379, 9802
	ldmm16 10377, 9800
	call SeqPart_ReadByte_Secondary
	lds wa, 0
	ldi_werp 0xFA, 1
	extz xwa
	lda xbc, (xsp + 4)
	add xbc, xwa
	ld (xbc), l
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jr z, SeqStep_DeleteShiftAdvance
	jrl SeqStep_DeleteShiftCleanup

SeqStep_DeleteShiftLoop:
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jrl nz, SeqStep_DeleteShiftCleanup

SeqStep_DeleteShiftAdvance:
	call SeqPart_ReadByte_Secondary
	ldto_werp WA, 0xFA
	inc1_werp 0xFA
	extz xwa
	lda xbc, (xsp + 4)
	add xbc, xwa
	ld (xbc), l
	bit 7, l
	jr z, SeqStep_DeleteShiftLoop
	dec1_werp 0xFA
	call PartCtrl_NavigateBackward
	ldmm16 10375, 10379
	ldmm16 10373, 10377
	ldmm16 10379, 9802
	ldmm16 10377, 9800
	call PartCtrl_NavigateBackward

SeqStep_DeleteShiftDone:
	call SeqPart_ReadByte_Secondary
	ldda16 xwa, 10379
	cpda16 xwa, 9798
	jr nz, SeqStep_DeleteShiftReturn
	ldda16 xwa, 10377
	cpda16 xwa, 9796
	jr nz, SeqStep_DeleteShiftReturn
	extz hl
	ld wa, hl
	call SeqPart_WriteByte_Primary
	ldmm16 10375, 9798
	ldmm16 10373, 9796
	lds iz, 0
	cpi_werp 0xFA, 0
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
	cpdi8 10362, 0
	jr z, SeqStep_DeleteShiftError
	jr SeqStep_DeleteShiftCleanup

SeqStep_DeleteShiftReturn:
	extz hl
	ld wa, hl
	call SeqPart_WriteByte_Primary
	call PartCtrl_NavigateBackward
	cpdi8 10362, 0
	jr nz, SeqStep_DeleteShiftCleanup
	call PartCtrl_NavigateBackwardAlt
	cpdi8 10362, 0
	jr z, SeqStep_DeleteShiftDone
	jr SeqStep_DeleteShiftCleanup

SeqStep_DeleteShiftError:
	inc 1, iz
	cp_werp IZ, 0xFA
	jr c, SeqStep_DeleteShiftUpdate

SeqStep_DeleteShiftCleanup:
	pop xiz
	inc 8, xsp
	ret

SeqStep_DeleteShiftExit:
	pushw iz
	cpdi16 62001, 0
	jr nz, SeqStep_DeleteShiftFinal
	ldw hl, 0xFFFF
	jr SeqStep_BoundaryCheckB

SeqStep_DeleteShiftFinal:
	call PartCtrl_ReadWordRoutine
	ld iz, hl
	stda16 10415, xiz
	ld wa, iz
	lds bc, 1
	call PartCtrl_SetClearBit7
	ld wa, iz
	lds bc, 0
	call PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xFFFF
	call PartCtrl_WriteWord
	ldda8 a, 9994
	extz wa
	ldda8 c, 10359
	inc 1, c
	extz bc
	lds de, 1
	call Part_SetClearVoiceBit7
	ldda8 a, 9994
	extz wa
	ldda8 c, 10359
	inc 1, c
	extz bc
	ld de, iz
	call Part_WriteVoiceWord
	ldda8 a, 9994
	dec 1, a
	cpda8_24 a, 65507
	jr nz, SeqStep_BoundaryCheckA
	ldda8 c, 10359
	inc 1, c
	extz bc
	lds wa, 0
	lds de, 1
	call Part_SetClearVoiceBit7
	ldda8 c, 10359
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
	push_werp 0xFA
	ldda8 a, 10000
	cpda8_24 a, 65507
	jr nz, SeqStep_BoundaryProcess
	ldi_berp 0xFB, 0
	jr SeqStep_BoundaryAdvance

SeqStep_BoundaryProcess:
	inc 1, a
	ldfr_berp A, 0xFB

SeqStep_BoundaryAdvance:
	ldto_berp A, 0xFB
	extz wa
	ldda8 c, 10010
	inc 1, c
	extz bc
	call Part_ReadVoiceBit7
	cps l, 0
	jrl z, SeqStep_BoundaryFinal
	ldto_berp A, 0xFB
	extz wa
	ldda8 c, 10010
	inc 1, c
	extz bc
	call Part_ReadVoiceWord
	ld wa, hl
	cps wa, 0
	jr z, SeqStep_BoundaryDone
	cp wa, 0xFFFF
	jr nz, SeqStep_BoundaryExit

SeqStep_BoundaryDone:
	jrl SeqStep_BoundaryFinal

SeqStep_BoundaryExit:
	call Part_StealAndReallocVoices
	ldda8 a, 10000
	inc 1, a
	extz wa
	ldda8 c, 10010
	inc 1, c
	extz bc
	lds de, 0
	call Part_SetClearVoiceBit7
	ldda8 a, 10000
	inc 1, a
	extz wa
	ldda8 c, 10010
	inc 1, c
	extz bc
	ldw de, 0xFFFF
	call Part_WriteVoiceWord
	ldda8 a, 10000
	cpda8_24 a, 65507
	jr nz, SeqStep_BoundaryError
	ldda8 c, 10010
	inc 1, c
	extz bc
	lds wa, 0
	lds de, 0
	call Part_SetClearVoiceBit7
	ldda8 c, 10010
	inc 1, c
	extz bc
	lds wa, 0
	ldw de, 0xFFFF
	call Part_WriteVoiceWord

SeqStep_BoundaryError:
	ldda8 a, 10000
	inc 1, a
	extz wa
	ldda8 c, 10010
	inc 1, c
	extz bc
	ldw de, 0xFFFF
	call Part_WriteWord_Indexed
	ldda8 a, 10000
	inc 1, a
	extz wa
	ldda8 c, 10010
	inc 1, c
	extz bc
	lds de, 5
	call Part_WriteByte_Indexed
	ldda8 a, 10000
	cpda8_24 a, 65507
	jr nz, SeqStep_BoundaryFinal
	ldda8 c, 10010
	inc 1, c
	extz bc
	lds wa, 0
	ldw de, 0xFFFF
	call Part_WriteWord_Indexed
	ldda8 c, 10010
	inc 1, c
	extz bc
	lds wa, 0
	lds de, 5
	call Part_WriteByte_Indexed

SeqStep_BoundaryFinal:
	pop_werp 0xFA
	ret

SeqStep_SkipIfLeftFlag:
	bitda 0, 10361
	jr z, SeqStep_SkipIfLeftDone
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
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
	ldw hl, 0xFFFF
	ret

SeqStep_SkipInvertedA:
	extz wa
	calr SeqStep_SkipToMeasure
	cps hl, 0
	jr z, SeqStep_SkipInvertedADone
	ldw hl, 0xFFFF
	ret

SeqStep_SkipInvertedADone:
	lds hl, 0
	ret

SeqStep_SkipInvertedB:
	extz wa
	calr SeqStep_SkipToMeasure
	cps hl, 0
	jr z, SeqStep_SkipInvertedBDone
	ldw hl, 0xFFFF
	ret

SeqStep_SkipInvertedBDone:
	lds hl, 0
	ret

SeqStep_AdvanceOneEvent:
	extz wa
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceToNextEntry
	cpdi8 10362, 0
	jr nz, SeqStep_AdvanceOneDone
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jr z, SeqStep_AdvanceOneReturn

SeqStep_AdvanceOneDone:
	ldw hl, 0xFFFF
	ret

SeqStep_AdvanceOneReturn:
	lds hl, 0
	ret

SeqStep_SkipToMeasure:
	extz wa
	calr SeqStep_AdvanceOneEvent
	cps hl, 0
	jr z, SeqStep_SkipToMeasureLoop
	ldw hl, 0xFFFF
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
	cpdi8 10362, 0
	jr nz, SeqStep_SkipThreeError
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jr nz, SeqStep_SkipThreeError
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jr nz, SeqStep_SkipThreeError
	call SeqPart_ReadByte_Secondary
	cps l, 0
	jr z, SeqStep_SkipThreeReturn

SeqStep_SkipThreeError:
	ldw hl, 0xFFFF
	ret

SeqStep_SkipThreeReturn:
	lds hl, 0
	ret

SeqStep_ProcessC0:
	dec 4, xsp
	push xiz
	ld (xsp + 6), a
	ldda8 a, 10361
	and a, 0x3
	jr z, SeqStep_ProcessC0SavePos
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jr nz, SeqStep_ProcessC0Error
	jr SeqStep_ProcessC0Done

SeqStep_ProcessC0SavePos:
	ldda16 xwa, 10379
	ldfr_werp WA, 0xFA
	ldda16 xiz, 10377
	calr SeqStep_SkipThreeEvents
	cps hl, 0
	jr nz, SeqStep_ProcessC0Done
	ldto_werp WA, 0xFA
	stda16 10379, xwa
	stda16 10377, xiz
	ld (xsp + 4), 0x0
	jr SeqStep_ProcessC0ReadParam

SeqStep_ProcessC0Check:
	cp (xsp + 4), 0x2
	jr nz, SeqStep_ProcessC0ReadParam
	ldmi16 (xsp + 6), 0x287C

SeqStep_ProcessC0ReadParam:
	ld a, (xsp + 6)
	extz wa
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceToNextEntry
	cpdi8 10362, 0
	jr nz, SeqStep_ProcessC0Error
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jr z, SeqStep_ProcessC0Advance

SeqStep_ProcessC0Error:
	ldw hl, 0xFFFF
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
	ldda16 xwa, 10379
	ldfr_werp WA, 0xFA
	ldda16 xiz, 10377
	calr SeqStep_ParseRhythm
	ldto_werp WA, 0xFA
	stda16 10379, xwa
	stda16 10377, xiz
	cpdi8 10362, 0
	jr nz, SeqStep_ProcessB0Error
	ldda8 a, 10397
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
	cpdi8 10362, 0
	jr nz, SeqStep_ProcessB0Error
	jr SeqStep_ProcessB0Exit

SeqStep_ProcessB0Advance:
	ld (xsp + 4), 0x0
	jr SeqStep_ProcessB0Return

SeqStep_ProcessB0Validate:
	cp (xsp + 4), 0x2
	jr nz, SeqStep_ProcessB0Skip
	ldmi16 (xsp + 6), 0x287C

SeqStep_ProcessB0Skip:
	cp (xsp + 4), 0x3
	jr nz, SeqStep_ProcessB0Done
	ldmi16 (xsp + 6), 0xD3C

SeqStep_ProcessB0Done:
	cp (xsp + 4), 0x4
	jr nz, SeqStep_ProcessB0Return
	ldda8 a, 3387
	cp a, 0xFF
	jr z, SeqStep_ProcessB0Return
	ld (xsp + 6), a

SeqStep_ProcessB0Return:
	ld a, (xsp + 6)
	extz wa
	calr SeqStep_AdvanceOneEvent
	cps hl, 0
	jr z, SeqStep_ProcessB0Cleanup

SeqStep_ProcessB0Error:
	ldw hl, 0xFFFF
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
	cpdi8 10362, 0
	jr nz, SeqStep_ParseRhythmCheck
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jr nz, SeqStep_ParseRhythmCheck
	stdi8 3387, 255
	call SeqPart_ReadByte_Secondary
	res 7, l
	ldda8 a, 4340
	or a, l
	stda8 4340, a
	cp a, 0x48
	jr z, SeqStep_ParseRhythmError
	ldda8 c, 10397
	res 2, c
	stda8 10397, c
	ldda8 e, 10355
	extz de
	lda_24 xhl, 0xe44ba4
	ldda8 a, 4340
	cp_srib_rm A, 0x07, 0xEC, 0xE8
	jr z, SeqStep_ParseRhythmLoop
	res 0, c
	res 2, c
	stda8 10397, c
	jrl SeqStep_ParseRhythmComplete

SeqStep_ParseRhythmLoop:
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jr z, SeqStep_ParseRhythmAdvance

SeqStep_ParseRhythmCheck:
	ldw hl, 0xFFFF
	ret

SeqStep_ParseRhythmAdvance:
	call SeqPart_ReadByte_Secondary
	ldda8 c, 10397
	cps l, 3
	jr c, SeqStep_ParseRhythmProcess
	cp l, 0xB
	jr ugt, SeqStep_ParseRhythmProcess
	cps l, 6
	jr nz, SeqStep_ParseRhythmStore

SeqStep_ParseRhythmProcess:
	res 0, c
	res 2, c
	stda8 10397, c
	jrl SeqStep_ParseRhythmComplete

SeqStep_ParseRhythmStore:
	ldda8 a, 10361
	and a, 0x3
	jr nz, SeqStep_ParseRhythmReturn

SeqStep_ParseRhythmDone:
	setda 0, 10397
	jr SeqStep_ParseRhythmValidate

SeqStep_ParseRhythmReturn:
	cps l, 3
	jr z, SeqStep_ParseRhythmDone
	res 0, c
	res 2, c
	stda8 10397, c
	jr SeqStep_ParseRhythmComplete

SeqStep_ParseRhythmError:
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jr nz, SeqStep_ParseRhythmComplete
	call SeqPart_ReadByte_Secondary
	cps l, 5
	jr z, SeqStep_ParseRhythmExit
	ldda8 a, 10397
	res 2, a
	stda8 10397, a
	cpdi8 10355, 12
	jr z, SeqStep_ParseRhythmSkip
	res 0, a
	res 2, a
	stda8 10397, a
	jr SeqStep_ParseRhythmComplete

SeqStep_ParseRhythmSkip:
	cps l, 3
	jr nz, SeqStep_ParseRhythmCleanup
	set 0, a
	stda8 10397, a

SeqStep_ParseRhythmValidate:
	stda8 3388, l
	jr SeqStep_ParseRhythmComplete

SeqStep_ParseRhythmCleanup:
	res 0, a
	res 2, a
	stda8 10397, a
	jr SeqStep_ParseRhythmComplete

SeqStep_ParseRhythmExit:
	resda 0, 10397
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jr nz, SeqStep_ParseRhythmComplete
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jr nz, SeqStep_ParseRhythmComplete
	call SeqPart_ReadByte_Secondary
	ldda8 a, 3310
	and a, 0xFC
	jr z, SeqStep_ParseRhythmFinal
	setda 2, 10397
	jr SeqStep_ParseRhythmComplete

SeqStep_ParseRhythmFinal:
	resda 2, 10397

SeqStep_ParseRhythmComplete:
	lds hl, 0
	ret

SeqStep_CommitEvent:
	extz wa
	call SeqPart_WriteByte_Primary
	ldda16 xwa, 10373
	ld c, a
	extz bc
	ldda16 xwa, 10375
	call Part_WriteWordAndByte
	ldda16 xwa, 10375
	jp Part_CheckAndReallocVoices

SeqStep_ProcessC0Ext:
	dec 4, xsp
	push xiz
	ld (xsp + 6), a
	ldda8 a, 10361
	and a, 0x3
	jr z, SeqStep_ProcessC0ExtCheck
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jr nz, SeqStep_ProcessC0ExtReturn
	jr SeqStep_ProcessC0ExtFinal

SeqStep_ProcessC0ExtCheck:
	bitda 1, 4393
	jr nz, SeqStep_ProcessC0ExtProcess
	ldda16 xwa, 10379
	ldfr_werp WA, 0xFA
	ldda16 xiz, 10377
	calr SeqStep_SkipThreeEvents
	cps hl, 0
	jr nz, SeqStep_ProcessC0ExtFinal
	ldto_werp WA, 0xFA
	stda16 10379, xwa
	stda16 10377, xiz

SeqStep_ProcessC0ExtProcess:
	ld (xsp + 4), 0x0
	jr SeqStep_ProcessC0ExtDone

SeqStep_ProcessC0ExtSkip:
	cp (xsp + 4), 0x2
	jr nz, SeqStep_ProcessC0ExtDone
	ldmi16 (xsp + 6), 0x287C

SeqStep_ProcessC0ExtDone:
	ld a, (xsp + 6)
	extz wa
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceToNextEntry
	cpdi8 10362, 0
	jr nz, SeqStep_ProcessC0ExtReturn
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jr z, SeqStep_ProcessC0ExtExit

SeqStep_ProcessC0ExtReturn:
	ldw hl, 0xFFFF
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
	ldda16 xwa, 10379
	ldfr_werp WA, 0xFA
	ldda16 xiz, 10377
	calr SeqPart_EventLoopContinue
	ldto_werp WA, 0xFA
	stda16 10379, xwa
	stda16 10377, xiz
	cpdi8 10362, 0
	jr nz, SeqStep_ProcessB0ExtExit
	ldda8 a, 10397
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
	cpdi8 10362, 0
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
	cp a, 0xFF
	jr z, SeqStep_ProcessB0ExtReturn
	bitda 1, 4393
	jr nz, SeqStep_ProcessB0ExtReturn
	ld (xsp + 6), a

SeqStep_ProcessB0ExtReturn:
	ld a, (xsp + 6)
	extz wa
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceToNextEntry
	cpdi8 10362, 0
	jr nz, SeqStep_ProcessB0ExtExit
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jr z, SeqStep_ProcessB0ExtComplete

SeqStep_ProcessB0ExtExit:
	ldw hl, 0xFFFF

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
	ldmi16 (xsp + 6), 0x287C

SeqStep_ProcessB0ExtCleanup:
	cp (xsp + 4), 0x3
	jr nz, SeqStep_ProcessB0ExtDone
	bitda 1, 4393
	jr nz, SeqStep_ProcessB0ExtReturn
	ldmi16 (xsp + 6), 0xD3C
	jr SeqStep_ProcessB0ExtReturn

SeqStep_MainTimerTick:
	calr SeqStep_TimerDispatchA
	call SeqPlay_SyncPlaybackPosition
	calr SeqStep_TimerDispatchB
	call Seq_HandleModeTransition
	call SeqNotify_CheckAndClearStart
	calr SeqStep_PlaybackStateMachine
	call SeqPlay_SetupRhythmMode
	call LABEL_F2057D
	call SeqTimer_SetPlaybackFlags
	jp BmDrEdit_TempoAnimTimer

SeqStep_TimerDispatchA:
	ldda8 a, 8956
	extz wa
	sla wa, 2
	lda_24 xbc, 0xe44f00
	ld_sril3 XHL, 0x07, 0xE4, 0xE0
	jp (xhl)

SeqStep_TimerDispatchB:
	ldda8 a, 8956
	extz wa
	sla wa, 2
	lda_24 xbc, 0xe44f5c
	ld_sril3 XHL, 0x07, 0xE4, 0xE0
	jp (xhl)

SeqStep_TimerDispatchC:
	ldda8 a, 8956
	extz wa
	sla wa, 2
	lda_24 xbc, 0xe44fb8
	ld_sril3 XHL, 0x07, 0xE4, 0xE0
	jp (xhl)

SeqStep_PlaybackStateMachine:
	push_werp 0xFA
	ldda8 a, 7518
	cps a, 0
	jr z, SeqStep_PlaybackDecrCount
	dec 1, a
	stda8 7518, a

SeqStep_PlaybackDecrCount:
	ei 6
	ldda8 a, 1057
	ldfr_berp A, 0xFB
	res 1, a
	res 4, a
	stda8 1057, a
	ei 0
	cpdi16 10408, 0
	jr nz, SeqStep_PlaybackCheck10408
	bit_erpb 0xFB, 0x04
	jr z, SeqStep_PlaybackCheckFill
	cpdi16 10420, 0
	jr nz, SeqStep_PlaybackCallFill

SeqStep_PlaybackCheckFill:
	bit_erpb 0xFB, 0x04
	jr z, SeqStep_PlaybackCheckBeat
	bitda 0, 10437
	jr z, SeqStep_PlaybackCheckBeat

SeqStep_PlaybackCallFill:
	call SeqPlay_HandlePlaybackEvent
	jr SeqStep_PlaybackResultDispatch

SeqStep_PlaybackCheckBeat:
	bit_erpb 0xFB, 0x01
	jr z, SeqStep_PlaybackCheckPattern
	call SeqPlay_PreparePlaybackState
	jr SeqStep_PlaybackResultDispatch

SeqStep_PlaybackCheckPattern:
	cpdi16 10420, 0
	jr z, SeqStep_PlaybackNoAction
	call SeqNote_ProcessNoteOn
	jr SeqStep_PlaybackResultDispatch

SeqStep_PlaybackNoAction:
	ldb l, 0x0
	jr SeqStep_PlaybackReturn

SeqStep_PlaybackCheck10408:
	bit_erpb 0xFB, 0x04
	jr z, SeqStep_PlaybackCheckFill2
	cpdi16 10410, 0
	jr nz, SeqStep_PlaybackCallExtFill

SeqStep_PlaybackCheckFill2:
	bit_erpb 0xFB, 0x04
	jr z, SeqStep_PlaybackCheckBeat2
	bitda 0, 10437
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
	bit_erpb 0xFB, 0x01
	jr z, SeqStep_PlaybackCheckTiming
	call SeqPlay_SaveAndPrepareState
	jr SeqStep_PlaybackResultDispatch

SeqStep_PlaybackCheckTiming:
	cpdi16 10410, 0
	jr nz, SeqStep_PlaybackCallPattern
	cpdi16 10420, 0
	jr z, SeqStep_PlaybackNoAction
	bitda 0, 10437
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
	pop_werp 0xFA
	ret

SeqStep_PlaybackNop:
	ret

SeqStep_PlaybackMaxPart:
	.byte 0x0e

SeqStep_FindLastUsedPart:
	dec 4, xsp
	ldw wa, 0x4D8
	calr SeqStep_SearchBackward
	ld (xsp + 2), hl
	lds wa, 1
	calr SeqStep_SearchForward
	ld (xsp), hl
	cpw (xsp), 0x4D8
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
	stdi16 61902, 19840
	ldw wa, 0x4D8
	calr SeqStep_SearchBackward
	ld (xsp + 2), hl
	lds wa, 1
	calr SeqStep_SearchForward
	ld (xsp + 4), hl
	cpw (xsp + 4), 0x4D8
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
	stda16 61902, xwa
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
	cp iz, 0x4D8
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
	ldi_berp 0xFA, 1

SeqStep_UpdateRefsCheck:
	ldi_berp 0xFB, 1

SeqStep_UpdateRefsAdvance:
	ldto_berp A, 0xFA
	extz wa
	ldto_berp C, 0xFB
	extz bc
	call Part_ReadVoiceBit7
	cps l, 0
	jr z, SeqStep_UpdateRefsDone
	ldto_berp A, 0xFA
	extz wa
	ldto_berp C, 0xFB
	extz bc
	call Part_ReadVoiceWord
	cp hl, (xsp + 4)
	jr nz, SeqStep_UpdateRefsDone
	ldto_berp A, 0xFA
	extz wa
	ldto_berp C, 0xFB
	extz bc
	ld de, iz
	call Part_WriteVoiceWord

SeqStep_UpdateRefsDone:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, SeqStep_UpdateRefsAdvance
	inc1_berp 0xFA
	cp_erpb 0xFA, 0x0A
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
	cp wa, 0xFFFF
	jr z, SeqStep_UpdateLinksLoop
	ld bc, iz
	call PartCtrl_WriteWord_Off1
	jr SeqStep_UpdateLinksReturn

SeqStep_UpdateLinksLoop:
	ldi_berp 0xFA, 1

SeqStep_UpdateLinksCheck:
	ldi_berp 0xFB, 1

SeqStep_UpdateLinksAdvance:
	ldto_berp A, 0xFA
	extz wa
	ldto_berp C, 0xFB
	add_berp C, 0xFB
	add c, 0x76
	extz bc
	call Part_ReadWord
	cp hl, (xsp + 4)
	jr nz, SeqStep_UpdateLinksDone
	ldto_berp A, 0xFA
	extz wa
	ldto_berp C, 0xFB
	add_berp C, 0xFB
	add c, 0x76
	extz bc
	ld de, iz
	call Part_WriteWord

SeqStep_UpdateLinksDone:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, SeqStep_UpdateLinksAdvance
	inc1_berp 0xFA
	cp_erpb 0xFA, 0x0A
	jr ule, SeqStep_UpdateLinksCheck

SeqStep_UpdateLinksReturn:
	pop xiz
	inc 2, xsp
	ret

SeqStep_RebuildPartChain:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), wa
	cpw (xsp + 2), 0x4D8
	jr ule, SeqStep_RebuildLoop
	stdi16 62001, 0
	stdi16 61999, 65535
	jrl SeqStep_RebuildReturn

SeqStep_RebuildLoop:
	mrdw5 0x9F, 0x02, 0x19, 0x2F, 0xF2
	stdi16 62001, 0
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
	incdi16 1, 62001
	ld iz, (xsp + 2)
	inc 1, iz
	cp iz, 0x4D8
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
	incdi16 1, 62001
	inc 1, iz
	cp iz, 0x4D8
	jr c, SeqStep_RebuildCheck

SeqStep_RebuildAdvance:
	ldw wa, 0x4D8
	lds bc, 0
	call PartCtrl_SetClearBit7
	cpw (xsp + 2), 0x4D8
	jr z, SeqStep_RebuildDone
	ldw wa, 0x4D8
	ldw bc, 0x4D7
	call PartCtrl_WriteWord_Off1

SeqStep_RebuildDone:
	ldw wa, 0x4D8
	ldw bc, 0xFFFF
	call PartCtrl_WriteWord
	ld wa, (xsp + 2)
	lds bc, 5
	ldw de, 0x82
	call PartCtrl_WriteByteToBuf
	incdi16 1, 62001

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
	ldw bc, 0xC7
	call Part_WriteByte
	ld16_24 xde, 0x00ffec
	lds wa, 1
	ldw bc, 0xC8
	call Part_WriteWord
	calr SeqStep_FindAndCompact
	ld (xsp + 4), xhl
	ldda16 xiz, 61902
	ldda16 xwa, 61999
	ldfr_werp WA, 0xFA
	ldmw2 (xsp + 8), 0xF231
	ld8_24 a, 0x00ffe3
	extz wa
	call VoicePreset_LoadAndInitPan
	stda16 61902, xiz
	ldto_werp WA, 0xFA
	stda16 61999, xwa
	mrdw5 0x9F, 0x08, 0x19, 0x31, 0xF2
	ldto_werp WA, 0xFA
	call Part_WriteWordBlock_OffsetAF
	ldda16 xwa, 62001
	call Part_SetAllVoicePos
	ldi_berp 0xFB, 1

SeqStep_ReinitLoop:
	ldto_berp A, 0xFB
	extz wa
	ldda16 xde, 61902
	ldw bc, 0x4E
	call Part_WriteWord
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x0A
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
