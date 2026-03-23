; =============================================================================
; Note & Voice Mapping (26K lines)
; =============================================================================
;
; Note-on processing, polyphonic voice allocation and stealing,
; NoteMap dispatch (91 functions), sequence playback support, MIDI
; output formatting, sound parameter management, and utility routines.
; One of the largest files in the ROM.
; =============================================================================

NoteOn_EntryPoint:
	st_dri3b L, 0xfd, 0x08, 0xfe
	pushw iz
	ldada xwa, 49662
	ld (xsp + 2), xwa
	call SeqMain_SaveWritePos
	stib_dri 0xfd, 0xf4, 0x01, 0x00
	st_dri3b W, 0xfd, 0xf4, 0x01
	ld xde, xwa
	st_dri3b W, 0xfd, 0x50, 0x01
	ld xbc, xwa
	ld xwa, xde
	call MidiEvent_ProcessNoteEntry
	cps l, 0
	jrl z, NoteOn_Epilogue

NoteOn_DispatchByStatus:
	ld_srib A, (xsp + 0x0150)
	cp a, 0xb0
	jrl z, NoteOn_ChannelScanLoop_CC
	cp a, 0x90
	jrl nz, NoteOnProcess_StoreAndAllocate
	ldw (xsp + 6), 0x0
	cpw (xsp + 6), 0x1a
	jrl nc, NoteOnProcess_StoreAndAllocate

NoteOn_ChannelScanLoop_NoteOn:
	ld wa, (xsp + 6)
	add wa, 0x24
	ld bc, wa
	extz xbc
	add xbc, (xsp + 2)
	ld_srib A, (xsp + 0x0153)
	cp a, (xbc)
	jrl nz, NoteOn_AdvanceChannel
	ld wa, (xsp + 6)
	add wa, wa
	add wa, 0x124
	extz xwa
	add xwa, (xsp + 2)
	bitm 6, (xwa)
	jrl z, NoteOn_AdvanceChannel
	st_dri3b W, 0xfd, 0x50, 0x01
	ld xbc, xwa
	ld wa, (xsp + 6)
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call Voice_ApplyTransposeWithEncode
	lds iz, 0
	ldb c, 0x7f
	jr NoteOn_AutoPlayCheckCount

NoteOn_AutoPlayVoiceLoop:
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	st_dri3b W, 0xfd, 0x51, 0x01
	add xwa, xbc
	cp (xwa), 0x0
	jr z, NoteOn_AutoPlayNext
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	st_dri3b W, 0xfd, 0x50, 0x01
	add xwa, xbc
	ld c, (xwa)
	ld_srib A, (xsp + 0x0153)
	extz wa
	extz bc
	call AccWrap_AutoPlayCheck

NoteOn_AutoPlayNext:
	inc 1, iz

NoteOn_AutoPlayCheckCount:
	ld_srib A, (xsp + 0x0151)
	extz wa
	cp iz, wa
	jr c, NoteOn_AutoPlayVoiceLoop
	call CompIface_ResetPedal
	ld wa, (xsp + 6)
	add wa, wa
	add wa, 0x124
	extz xwa
	add xwa, (xsp + 2)
	bitm 4, (xwa)
	jr nz, NoteOn_VoiceLookupAndAssign
	st_dri3b W, 0xfd, 0x50, 0x01
	ld xbc, xwa
	ld wa, (xsp + 6)
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_CollectAndAllocVoice_NoTimerCheck
	jrl NoteOn_PostAutoPlay

NoteOn_VoiceLookupAndAssign:
	st_dri3b E, 0xfd, 0x50, 0x01
	st_dri3b D, 0xfd, 0xac, 0x00
	ldw bc, 0x52
	ldirw
	stib_dri 0xfd, 0xae, 0x00, 0x00
	stib_dri 0xfd, 0xaf, 0x00, 0x01
	st_dri3b W, 0xfd, 0xac, 0x00
	call NoteMap_AssignAllVoiceLinks
	ld xwa, (xsp + 2)
	cp (xwa + 1), 0xff
	jrl nz, NoteOn_CheckSpecialChannel
	ld xwa, (xsp + 2)
	bitm 0, (xwa)
	jr z, NoteOn_MergeLayer1
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xac, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	st_dri3b W, 0xe1, 0xc4, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, NoteOn_MergeLayer1
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	lds de, 0
	call NoteMap_UpdateEntry

NoteOn_MergeLayer1:
	ld xwa, (xsp + 2)
	bitm 1, (xwa)
	jr z, NoteOn_MergeLayer2
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xac, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	st_dri3b W, 0xe1, 0xc8, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, NoteOn_MergeLayer2
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	lds de, 1
	call NoteMap_UpdateEntry

NoteOn_MergeLayer2:
	ld xwa, (xsp + 2)
	bitm 2, (xwa)
	jr z, NoteOn_MergeLayer3
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xac, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	st_dri3b W, 0xe1, 0xcc, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, NoteOn_MergeLayer3
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	lds de, 2
	call NoteMap_UpdateEntry

NoteOn_MergeLayer3:
	ld xwa, (xsp + 2)
	bitm 3, (xwa)
	jrl z, NoteOn_PostAutoPlay
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xac, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	st_dri3b W, 0xe1, 0xd0, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jrl z, NoteOn_PostAutoPlay
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	ldw de, 0x15
	call NoteMap_UpdateEntry
	jr NoteOn_PostAutoPlay

NoteOn_CheckSpecialChannel:
	ld xwa, (xsp + 2)
	cp (xwa + 1), 0x15
	jr nz, NoteOn_CheckLayer3Only
	ldda16 xwa, 50584
	and wa, 0xa
	jr z, NoteOn_SpecialChannelUpdate
	st_dri3b W, 0xfd, 0xac, 0x00
	call NoteMap_MarkEntriesAboveThreshold

NoteOn_SpecialChannelUpdate:
	st_dri3b W, 0xfd, 0xac, 0x00
	ld xbc, (xsp + 2)
	ldw de, 0x15
	call NoteMap_UpdateEntry
	jr NoteOn_PostAutoPlay

NoteOn_CheckLayer3Only:
	ld xwa, (xsp + 2)
	bitm 3, (xwa)
	jr z, NoteOn_UpdateByChannelType
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xac, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	st_dri3b W, 0xe1, 0xd0, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, NoteOn_UpdateByChannelType
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	ldw de, 0x15
	call NoteMap_UpdateEntry

NoteOn_UpdateByChannelType:
	st_dri3b W, 0xfd, 0xac, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	ld a, (xwa + 1)
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_UpdateEntry

NoteOn_PostAutoPlay:
	call AccWrap_AutoPlayStateMachine

NoteOn_AdvanceChannel:
	incm 1, (xsp + 6)
	cpw (xsp + 6), 0x1a
	jrl c, NoteOn_ChannelScanLoop_NoteOn
	jrl NoteOnProcess_StoreAndAllocate

NoteOn_ChannelScanLoop_CC:
	ldw (xsp + 6), 0x0
	cpw (xsp + 6), 0x1a
	jrl nc, NoteOnProcess_StoreAndAllocate

NoteOn_ChannelScanCC_Body:
	ld wa, (xsp + 6)
	add wa, 0x24
	ld bc, wa
	extz xbc
	add xbc, (xsp + 2)
	ld_srib A, (xsp + 0x0153)
	cp a, (xbc)
	jrl nz, NoteOnProcess_NextChannel
	ld wa, (xsp + 6)
	add wa, wa
	add wa, 0x124
	extz xwa
	add xwa, (xsp + 2)
	bitm 6, (xwa)
	jrl z, NoteOnProcess_NextChannel
	ld wa, (xsp + 6)
	add wa, wa
	add wa, 0x124
	extz xwa
	add xwa, (xsp + 2)
	bitm 4, (xwa)
	jr nz, NoteOn_CC_VoiceLookupAndAssign
	st_dri3b W, 0xfd, 0x50, 0x01
	ld xbc, xwa
	ld wa, (xsp + 6)
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_CollectAndAllocVoice_Indirect
	jrl NoteOnProcess_NextChannel

NoteOn_CC_VoiceLookupAndAssign:
	stib_dri 0xfd, 0xae, 0x00, 0x00
	stib_dri 0xfd, 0xaf, 0x00, 0x01
	st_dri3b W, 0xfd, 0xac, 0x00
	call Voice_LookupTableEntries
	cps l, 0
	jrl z, NoteOnProcess_NextChannel
	st_dri3b W, 0xfd, 0xac, 0x00
	call NoteMap_AssignAllVoiceLinks
	ld xwa, (xsp + 2)
	cp (xwa + 1), 0xff
	jrl nz, NoteOn_CC_CheckSpecialChannel
	ld xwa, (xsp + 2)
	bitm 0, (xwa)
	jr z, NoteOn_CC_MergeLayer1
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xac, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	st_dri3b W, 0xe1, 0xc4, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, NoteOn_CC_MergeLayer1
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	lds de, 0
	call NoteMap_UpdateEntry

NoteOn_CC_MergeLayer1:
	ld xwa, (xsp + 2)
	bitm 1, (xwa)
	jr z, NoteOn_CC_MergeLayer2
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xac, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	st_dri3b W, 0xe1, 0xc8, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, NoteOn_CC_MergeLayer2
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	lds de, 1
	call NoteMap_UpdateEntry

NoteOn_CC_MergeLayer2:
	ld xwa, (xsp + 2)
	bitm 2, (xwa)
	jr z, NoteOn_CC_MergeLayer3
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xac, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	st_dri3b W, 0xe1, 0xcc, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, NoteOn_CC_MergeLayer3
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	lds de, 2
	call NoteMap_UpdateEntry

NoteOn_CC_MergeLayer3:
	ld xwa, (xsp + 2)
	bitm 3, (xwa)
	jrl z, NoteOnProcess_NextChannel
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xac, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	st_dri3b W, 0xe1, 0xd0, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jrl z, NoteOnProcess_NextChannel
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	ldw de, 0x15
	call NoteMap_UpdateEntry
	jr NoteOnProcess_NextChannel

NoteOn_CC_CheckSpecialChannel:
	ld xwa, (xsp + 2)
	cp (xwa + 1), 0x15
	jr nz, NoteOn_CC_CheckLayer3Only
	ldda16 xwa, 50584
	bit 1, wa
	jr z, NoteOn_CC_SpecialUpdate
	st_dri3b W, 0xfd, 0xac, 0x00
	call NoteMap_MarkEntriesAboveThreshold

NoteOn_CC_SpecialUpdate:
	st_dri3b W, 0xfd, 0xac, 0x00
	ld xbc, (xsp + 2)
	ldw de, 0x15
	call NoteMap_UpdateEntry
	jr NoteOnProcess_NextChannel

NoteOn_CC_CheckLayer3Only:
	ld xwa, (xsp + 2)
	bitm 3, (xwa)
	jr z, NoteOn_CC_UpdateByChannelType
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xac, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	st_dri3b W, 0xe1, 0xd0, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, NoteOn_CC_UpdateByChannelType
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	ldw de, 0x15
	call NoteMap_UpdateEntry

NoteOn_CC_UpdateByChannelType:
	st_dri3b W, 0xfd, 0xac, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	ld a, (xwa + 1)
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_UpdateEntry


; -----------------------------------------------------------------------------
; Section: Note-On Processing & Voice Allocation
; -----------------------------------------------------------------------------
; Note-on channel processing, voice slot allocation, and
; accompaniment note-on setup.
; -----------------------------------------------------------------------------

NoteOnProcess_NextChannel:
	incm 1, (xsp + 6)
	cpw (xsp + 6), 0x1a
	jrl c, NoteOn_ChannelScanCC_Body

NoteOnProcess_StoreAndAllocate:
	st_dri3b W, 0xfd, 0xf4, 0x01
	ld xde, xwa
	st_dri3b W, 0xfd, 0x50, 0x01
	ld xbc, xwa
	ld xwa, xde
	call MidiEvent_ProcessNoteEntry
	cps l, 0
	jrl nz, NoteOn_DispatchByStatus

NoteOn_Epilogue:
	popw iz
	st_dri3b L, 0xfd, 0xf8, 0x01
	ret

AccNoteOn_ProcessVoiceSetup:
	lda xsp, (xsp - 18)
	pushw iz
	ldada xwa, 49662
	ld (xsp + 2), xwa
	lds iz, 0
	ld xiy, 0xee8ee8
	lda xix, (xsp + 10)
	ldiw
	ldiw
	ld xiy, 0xee8eec
	lda xix, (xsp + 6)
	ldiw
	ldiw
	ld (xsp + 14), 0x0
	lda xwa, (xsp + 14)
	ld xbc, 0xcc1e
	call MidiEvent_ParseNoteSequence
	cps l, 0
	jrl z, AccNoteOn_Return

AccNoteOn_AssignVoices:
	ld xwa, 0xcc1e
	call NoteMap_AssignAllVoiceLinks
	lds iz, 0
	ldb e, 0x7f
	jr AccNoteOn_AutoPlayCheck

AccNoteOn_AutoPlayLoop:
	ld wa, iz
	mul wa, 0x5
	inc 4, wa
	ldada xbc, 52255
	extz xwa
	add xwa, xbc
	cp (xwa), 0x0
	jr z, AccNoteOn_AutoPlayNext
	ld wa, iz
	mul wa, 0x5
	ldada xbc, 52258
	extz xwa
	add xwa, xbc
	ld e, (xwa)
	ld a, e
	extz wa
	ld bc, wa
	ldw wa, 0x80
	call AccWrap_AutoPlayCheck

AccNoteOn_AutoPlayNext:
	inc 1, iz

AccNoteOn_AutoPlayCheck:
	ldda8 a, 52255
	extz wa
	cp iz, wa
	jr c, AccNoteOn_AutoPlayLoop
	call CompIface_ResetPedal
	cpdi8 36152, 236
	jr nz, AccNoteOn_EmitVoiceLoop_Init
	lds iz, 0
	ldb e, 0x7f
	jr AccNoteOn_MinVelocity_Check

AccNoteOn_FindMinVelocity_Loop:
	ld wa, iz
	mul wa, 0x5
	inc 4, wa
	ldada xbc, 52255
	extz xwa
	add xwa, xbc
	cp (xwa), 0x0
	jr z, AccNoteOn_MinVelocity_Next
	ld wa, iz
	mul wa, 0x5
	ldada xbc, 52258
	extz xwa
	add xwa, xbc
	cp e, (xwa)
	jr nc, AccNoteOn_UseEntryVelocity
	ld a, e
	jr AccNoteOn_StoreMinVelocity

AccNoteOn_UseEntryVelocity:
	ld wa, iz
	mul wa, 0x5
	ldada xbc, 52258
	extz xwa
	add xwa, xbc
	ld a, (xwa)

AccNoteOn_StoreMinVelocity:
	ld e, a

AccNoteOn_MinVelocity_Next:
	inc 1, iz

AccNoteOn_MinVelocity_Check:
	ldda8 a, 52255
	extz wa
	cp iz, wa
	jr c, AccNoteOn_FindMinVelocity_Loop
	ld a, e
	extz wa
	call AccWrap_SetMinVelocity

AccNoteOn_EmitVoiceLoop_Init:
	lds iz, 0
	ldb e, 0x7f
	jr AccNoteOn_EmitVoiceLoop_Check

AccNoteOn_EmitVoiceLoop_Body:
	ld wa, iz
	mul wa, 0x5
	ldada xbc, 52258
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld e, a
	extz de
	ld wa, iz
	mul wa, 0x5
	inc 4, wa
	ldada xbc, 52255
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld c, a
	extz bc
	ld wa, de
	call Voice_EmitNoteWithVelocity
	inc 1, iz

AccNoteOn_EmitVoiceLoop_Check:
	ldda8 a, 52255
	extz wa
	cp iz, wa
	jr c, AccNoteOn_EmitVoiceLoop_Body
	ld xwa, (xsp + 2)
	cp (xwa + 1), 0xff
	jrl nz, AccNoteOn_CheckSpecialChannel
	ld xwa, (xsp + 2)
	bitm 0, (xwa)
	jr z, AccNoteOn_MergeLayer1
	ld xhl, 0xcb7a
	ld xbc, 0xcc1e
	ld xwa, (xsp + 2)
	st_dri3b W, 0xe1, 0xc4, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, AccNoteOn_MergeLayer1
	ld xwa, 0xcb7a
	ld xbc, (xsp + 2)
	lds de, 0
	call NoteMap_AddEntry

AccNoteOn_MergeLayer1:
	ld xwa, (xsp + 2)
	bitm 1, (xwa)
	jr z, AccNoteOn_MergeLayer2
	ld xhl, 0xcb7a
	ld xbc, 0xcc1e
	ld xwa, (xsp + 2)
	st_dri3b W, 0xe1, 0xc8, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, AccNoteOn_MergeLayer2
	ld xwa, 0xcb7a
	ld xbc, (xsp + 2)
	lds de, 1
	call NoteMap_AddEntry

AccNoteOn_MergeLayer2:
	ld xwa, (xsp + 2)
	bitm 2, (xwa)
	jr z, AccNoteOn_MergeLayer3
	ld xhl, 0xcb7a
	ld xbc, 0xcc1e
	ld xwa, (xsp + 2)
	st_dri3b W, 0xe1, 0xcc, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, AccNoteOn_MergeLayer3
	ld xwa, 0xcb7a
	ld xbc, (xsp + 2)
	lds de, 2
	call NoteMap_AddEntry

AccNoteOn_MergeLayer3:
	ld xwa, (xsp + 2)
	bitm 3, (xwa)
	jrl z, AccNoteOn_FinalizeAndAutoPlay
	ld xhl, 0xcb7a
	ld xbc, 0xcc1e
	ld xwa, (xsp + 2)
	st_dri3b W, 0xe1, 0xd0, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jrl z, AccNoteOn_FinalizeAndAutoPlay
	ld xwa, 0xcb7a
	ld xbc, (xsp + 2)
	ldw de, 0x15
	call NoteMap_AddEntry
	jrl AccNoteOn_FinalizeAndAutoPlay

AccNoteOn_CheckSpecialChannel:
	ld xwa, (xsp + 2)
	cp (xwa + 1), 0x15
	jr nz, AccNoteOn_CheckLayer3Only
	ldda16 xwa, 50584
	and wa, 0xa
	jr z, AccNoteOn_SpecialDirectAdd
	ld xhl, 0xcb7a
	ld xbc, 0xcc1e
	lda xwa, (xsp + 10)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, AccNoteOn_SpecialMergeAndAdd
	ld xwa, 0xcb7a
	call NoteMap_MarkEntriesAboveThreshold

AccNoteOn_SpecialMergeAndAdd:
	ld xhl, 0xcb7a
	ld xbc, 0xcc1e
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, AccNoteOn_FinalizeAndAutoPlay
	ld xwa, 0xcb7a
	ld xbc, (xsp + 2)
	ldw de, 0x15
	call NoteMap_AddEntry
	jr AccNoteOn_FinalizeAndAutoPlay

AccNoteOn_SpecialDirectAdd:
	ld xwa, 0xcc1e
	ld xbc, (xsp + 2)
	ldw de, 0x15
	call NoteMap_AddEntry
	jr AccNoteOn_FinalizeAndAutoPlay

AccNoteOn_CheckLayer3Only:
	ld xwa, (xsp + 2)
	bitm 3, (xwa)
	jr z, AccNoteOn_UpdateByChannelType
	ld xhl, 0xcb7a
	ld xbc, 0xcc1e
	ld xwa, (xsp + 2)
	st_dri3b W, 0xe1, 0xd0, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, AccNoteOn_UpdateByChannelType
	ld xwa, 0xcb7a
	ld xbc, (xsp + 2)
	ldw de, 0x15
	call NoteMap_AddEntry

AccNoteOn_UpdateByChannelType:
	ld xbc, 0xcc1e
	ld xwa, (xsp + 2)
	ld a, (xwa + 1)
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_AddEntry

AccNoteOn_FinalizeAndAutoPlay:
	lda xwa, (xsp + 14)
	ld xbc, 0xcc1e
	call MidiEvent_ParseNoteSequence
	cps l, 0
	jrl nz, AccNoteOn_AssignVoices

AccNoteOn_Return:
	call AccWrap_AutoPlayStateMachine
	popw iz
	lda xsp, (xsp + 18)
	ret

AccNoteOn_ChannelDispatch:
	st_dri3b L, 0xfd, 0x52, 0xff
	push_werp 0xfa
	ldada xwa, 49662
	ld (xsp + 2), xwa
	call SeqBuf_SaveReadPos
	ld (xsp + 6), 0x0
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, xde
	call MidiEvent_ReadAndParseLoop
	cps l, 0
	jrl z, AccMidi_Return

AccMidi_DispatchLoop:
	ld a, (xsp + 12)
	cp a, 0xb0
	jr z, AccNoteOn_ChannelLoop_Body
	cp a, 0x90
	jrl nz, AccMidi_ReadNextEvent
	call CompIface_ResetPedal
	ld a, (xsp + 15)
	extz wa
	add wa, 0x84
	extz xwa
	add xwa, (xsp + 2)
	ld a, (xwa)
	ldfr_berp A, 0xfa
	cp a, 0xff
	jrl z, AccMidi_ReadNextEvent
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ldto_berp A, 0xfa
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call PopRetFA_StoreAE3_Prologue
	jrl AccMidi_ReadNextEvent

AccNoteOn_ChannelLoop_Body:
	cp (xsp + 15), 0x7f
	jr nz, AccNoteOn_ChannelLoop_Check
	ldi_berp 0xfb, 0
	cp_erpb 0xfb, 0x10
	jrl nc, AccMidi_ReadNextEvent

AccNoteOn_ChannelLoop_Remap98:
	ldto_berp A, 0xfb
	ld (xsp + 15), a
	ldto_berp A, 0xfb
	extz wa
	add wa, 0x84
	extz xwa
	add xwa, (xsp + 2)
	ld a, (xwa)
	ldfr_berp A, 0xfa
	cp a, 0xff
	jr z, AccNoteOn_ChannelLoop_Next
	ld (xsp + 14), 0x3
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ldto_berp A, 0xfa
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_ProcessNoteEvent
	ld (xsp + 14), 0x2
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ldto_berp A, 0xfa
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_ProcessNoteEvent

AccNoteOn_ChannelLoop_Next:
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, AccNoteOn_ChannelLoop_Remap98
	jr AccMidi_ReadNextEvent

AccNoteOn_ChannelLoop_Check:
	ld a, (xsp + 15)
	extz wa
	add wa, 0x84
	extz xwa
	add xwa, (xsp + 2)
	ld a, (xwa)
	ldfr_berp A, 0xfa
	cp a, 0xff
	jr z, AccMidi_ReadNextEvent
	ld (xsp + 14), 0x3
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ldto_berp A, 0xfa
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_ProcessNoteEvent
	ld (xsp + 14), 0x2
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ldto_berp A, 0xfa
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_ProcessNoteEvent


; -----------------------------------------------------------------------------
; Section: Rhythm & Accompaniment MIDI Processing
; -----------------------------------------------------------------------------
; MIDI event input handling for rhythm patterns and
; accompaniment playback. Includes CC dispatch.
; -----------------------------------------------------------------------------

AccMidi_ReadNextEvent:
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, xde
	call MidiEvent_ReadAndParseLoop
	cps l, 0
	jrl nz, AccMidi_DispatchLoop

AccMidi_Return:
	pop_werp 0xfa
	st_dri3b L, 0xfd, 0xae, 0x00
	ret

RhythmMidi_Dispatcher:
	st_dri3b L, 0xfd, 0x4c, 0xff
	push_werp 0xfa
	ldada xwa, 49662
	ld (xsp + 2), xwa
	ld xiy, 0xee8ef8
	lda xix, (xsp + 6)
	lds bc, 2
	ldirw
	ldi85
	call RhythmBuf_SaveWritePos
	ld (xsp + 12), 0x0
	lda xwa, (xsp + 12)
	ld xde, xwa
	lda xwa, (xsp + 18)
	ld xbc, xwa
	ld xwa, xde
	call RhythmBuf_ParseEventLoop
	cps l, 0
	jrl z, RhythmMidi_CC_PostProcess

RhythmMidi_DispatchByStatus:
	ld a, (xsp + 18)
	cp a, 0xb0
	jr z, RhythmMidi_HandleCC
	cp a, 0x90
	jrl nz, RhythmMidi_CC_UpdateOutput
	ld a, (xsp + 21)
	extz wa
	lda_24 xbc, 0xee8ef0
	ld_srib3 A, 0x07, 0xe4, 0xe0
	ldfr_berp A, 0xfa
	sub a, 0x10
	extz wa
	lda xbc, (xsp + 6)
	cp_srib_im 0x07, 0xe4, 0xe0, 0x00
	jr nz, RhythmMidi_NoteOn_Remap98
	lda xwa, (xsp + 18)
	ld xbc, xwa
	ldto_berp A, 0xfa
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_ProcessRhythmNoteOn
	jrl RhythmMidi_CC_UpdateOutput

RhythmMidi_NoteOn_Remap98:
	ld (xsp + 18), 0x98
	lda xwa, (xsp + 18)
	ld xbc, xwa
	ldto_berp A, 0xfa
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_ProcessRhythmRemap
	ldto_berp A, 0xfa
	sub a, 0x10
	extz wa
	lda xbc, (xsp + 6)
	stib_dri 0x07, 0xe4, 0xe0, 0x00
	jrl RhythmMidi_CC_UpdateOutput

RhythmMidi_HandleCC:
	ld a, (xsp + 21)
	inc 4, a
	cp a, 0x7d
	jr z, RhythmMidi_CC7D
	cp a, 0x7e
	jr z, RhythmMidi_CC7E
	cp a, 0x7f
	jrl nz, RhythmMidi_CC_Default
	ldi_berp 0xfb, 0
	cpi_berp 0xfb, 5
	jrl nc, RhythmMidi_CC_UpdateOutput

RhythmMidi_CC7F_PartLoop:
	ldto_berp A, 0xfb
	ld (xsp + 21), a
	ldto_berp A, 0xfb
	extz wa
	lda_24 xbc, 0xee8ef0
	ld_srib3 A, 0x07, 0xe4, 0xe0
	ldfr_berp A, 0xfa
	lda xwa, (xsp + 18)
	ld xbc, xwa
	ldto_berp A, 0xfa
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_LookupAndAllocVoice
	inc1_berp 0xfb
	cpi_berp 0xfb, 5
	jr c, RhythmMidi_CC7F_PartLoop
	jrl RhythmMidi_CC_UpdateOutput

RhythmMidi_CC7E:
	ld (xsp + 6), 0x1
	ld (xsp + 7), 0x1
	ld (xsp + 8), 0x1
	ld (xsp + 9), 0x1
	ld (xsp + 10), 0x0
	jrl RhythmMidi_CC_UpdateOutput

RhythmMidi_CC7D:
	ldi_berp 0xfb, 0
	cpi_berp 0xfb, 5
	jrl nc, RhythmMidi_CC_UpdateOutput

RhythmMidi_CC7D_PartLoop:
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (xsp + 6)
	cp_srib_im 0x07, 0xe4, 0xe0, 0x00
	jr z, RhythmMidi_CC7D_PartNext
	ldto_berp A, 0xfb
	ld (xsp + 21), a
	ldto_berp A, 0xfb
	extz wa
	lda_24 xbc, 0xee8ef0
	ld_srib3 A, 0x07, 0xe4, 0xe0
	ldfr_berp A, 0xfa
	lda xwa, (xsp + 18)
	ld xbc, xwa
	ldto_berp A, 0xfa
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_LookupAndAllocVoice
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (xsp + 6)
	stib_dri 0x07, 0xe4, 0xe0, 0x00

RhythmMidi_CC7D_PartNext:
	inc1_berp 0xfb
	cpi_berp 0xfb, 5
	jr c, RhythmMidi_CC7D_PartLoop
	jr RhythmMidi_CC_UpdateOutput

RhythmMidi_CC_Default:
	cp (xsp + 21), 0x70
	jr c, RhythmMidi_CC_Standard
	ld (xsp + 18), 0xa0
	submi8 (xsp + 21), 0x70
	ld a, (xsp + 21)
	extz wa
	lda_24 xbc, 0xee8ef0
	ld_srib3 A, 0x07, 0xe4, 0xe0
	ldfr_berp A, 0xfa
	lda xwa, (xsp + 18)
	ld xbc, xwa
	ldto_berp A, 0xfa
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_LookupAndAllocVoice
	ldto_berp A, 0xfa
	sub a, 0x10
	extz wa
	lda xbc, (xsp + 6)
	stib_dri 0x07, 0xe4, 0xe0, 0x00
	jr RhythmMidi_CC_UpdateOutput

RhythmMidi_CC_Standard:
	ld a, (xsp + 21)
	extz wa
	lda_24 xbc, 0xee8ef0
	ld_srib3 A, 0x07, 0xe4, 0xe0
	ldfr_berp A, 0xfa
	sub a, 0x10
	extz wa
	lda xbc, (xsp + 6)
	stib_dri 0x07, 0xe4, 0xe0, 0x01

RhythmMidi_CC_UpdateOutput:
	lda xwa, (xsp + 12)
	ld xde, xwa
	lda xwa, (xsp + 18)
	ld xbc, xwa
	ld xwa, xde
	call RhythmBuf_ParseEventLoop
	cps l, 0
	jrl nz, RhythmMidi_DispatchByStatus

RhythmMidi_CC_PostProcess:
	ldi_berp 0xfb, 0
	cpi_berp 0xfb, 5
	jr nc, RhythmMidi_CC_Return

RhythmMidi_CC_PostLoop:
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (xsp + 6)
	cp_srib_im 0x07, 0xe4, 0xe0, 0x00
	jr z, RhythmMidi_CC_PostNext
	ldto_berp A, 0xfb
	ld (xsp + 21), a
	ldto_berp A, 0xfb
	extz wa
	lda_24 xbc, 0xee8ef0
	ld_srib3 A, 0x07, 0xe4, 0xe0
	ldfr_berp A, 0xfa
	lda xwa, (xsp + 18)
	ld xbc, xwa
	ldto_berp A, 0xfa
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_LookupAndAllocVoice

RhythmMidi_CC_PostNext:
	inc1_berp 0xfb
	cpi_berp 0xfb, 5
	jr c, RhythmMidi_CC_PostLoop

RhythmMidi_CC_Return:
	pop_werp 0xfa
	st_dri3b L, 0xfd, 0xb4, 0x00
	ret

RhythmMidi_SeqEvt:
	st_dri3b L, 0xfd, 0x52, 0xff
	push_werp 0xfa
	ldada xwa, 49662
	ld (xsp + 2), xwa
	call SeqEvtBuf_SaveReadPos
	ld (xsp + 6), 0x0
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, xde
	call SeqEvtBuf_ParseEventLoop
	cps l, 0
	jrl z, RhythmMidi_SeqEvt_Return

RhythmMidi_SeqEvt_Dispatch:
	ld a, (xsp + 12)
	cp a, 0xb0
	jr z, RhythmMidi_SeqEvt_CC
	cp a, 0x90
	jrl nz, RhythmMidi_SeqEvt_ReadNext
	ld a, (xsp + 15)
	extz wa
	lda_24 xbc, 0xee8efe
	ld_srib3 E, 0x07, 0xe4, 0xe0
	ld a, e
	cp a, 0xff
	jrl z, RhythmMidi_SeqEvt_ReadNext
	lda xwa, (xsp + 12)
	extz de
	ld xbc, (xsp + 2)
	call ProcessNoteOff_Done_Prologue
	jrl RhythmMidi_SeqEvt_ReadNext

RhythmMidi_SeqEvt_CC:
	ld a, (xsp + 15)
	cp a, 0x7e
	jr z, RhythmMidi_SeqEvt_CC7E
	cp a, 0x7f
	jr nz, RhythmMidi_SeqEvt_CC_Default
	ldi_berp 0xfb, 0
	cpi_berp 0xfb, 2
	jrl nc, RhythmMidi_SeqEvt_ReadNext

RhythmMidi_SeqEvt_CC7F_Loop:
	ldto_berp A, 0xfb
	ld (xsp + 15), a
	ldto_berp A, 0xfb
	extz wa
	lda_24 xbc, 0xee8efe
	ld_srib3 E, 0x07, 0xe4, 0xe0
	ld a, e
	cp a, 0xff
	jr z, RhythmMidi_SeqEvt_CC7F_Next
	lda xwa, (xsp + 12)
	extz de
	ld xbc, (xsp + 2)
	call NoteMap_LookupAllocAndStoreResult

RhythmMidi_SeqEvt_CC7F_Next:
	inc1_berp 0xfb
	cpi_berp 0xfb, 2
	jr c, RhythmMidi_SeqEvt_CC7F_Loop
	jr RhythmMidi_SeqEvt_ReadNext

RhythmMidi_SeqEvt_CC7E:
	ldi_berp 0xfb, 0
	cpi_berp 0xfb, 1
	jr nc, RhythmMidi_SeqEvt_ReadNext

RhythmMidi_SeqEvt_CC7E_Loop:
	ldto_berp A, 0xfb
	ld (xsp + 15), a
	ldto_berp A, 0xfb
	extz wa
	lda_24 xbc, 0xee8efe
	ld_srib3 E, 0x07, 0xe4, 0xe0
	ld a, e
	cp a, 0xff
	jr z, RhythmMidi_SeqEvt_CC7E_Next
	lda xwa, (xsp + 12)
	extz de
	ld xbc, (xsp + 2)
	call NoteMap_LookupAllocAndStoreResult

RhythmMidi_SeqEvt_CC7E_Next:
	inc1_berp 0xfb
	cpi_berp 0xfb, 1
	jr c, RhythmMidi_SeqEvt_CC7E_Loop
	jr RhythmMidi_SeqEvt_ReadNext

RhythmMidi_SeqEvt_CC_Default:
	ld a, (xsp + 15)
	extz wa
	lda_24 xbc, 0xee8efe
	ld_srib3 E, 0x07, 0xe4, 0xe0
	ld a, e
	cp a, 0xff
	jr z, RhythmMidi_SeqEvt_ReadNext
	lda xwa, (xsp + 12)
	extz de
	ld xbc, (xsp + 2)
	call NoteMap_LookupAllocAndStoreResult

RhythmMidi_SeqEvt_ReadNext:
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, xde
	call SeqEvtBuf_ParseEventLoop
	cps l, 0
	jrl nz, RhythmMidi_SeqEvt_Dispatch

RhythmMidi_SeqEvt_Return:
	pop_werp 0xfa
	st_dri3b L, 0xfd, 0xae, 0x00
	ret


; -----------------------------------------------------------------------------
; Section: Voice Initialization & Event Dispatch
; -----------------------------------------------------------------------------
; Voice state initialization, per-voice event dispatch,
; and voice table group setup.
; -----------------------------------------------------------------------------

Voice_InitializeAll:
	st_dri3b L, 0xfd, 0x10, 0xfe
	push xiz
	ldada xiz, 49662
	stib_dri 0xfd, 0x50, 0x01, 0x90
	stib_dri 0xfd, 0x52, 0x01, 0x01
	ld (xsp + 4), 0x0
	cp (xsp + 4), 0x10
	jrl nc, VoiceInit_Epilogue

VoiceInit_PartLoop:
	ld a, (xsp + 4)
	lda_dri3 XBC, 0xfd, 0x53, 0x01
	ld (xsp + 6), 0x0
	cp (xsp + 6), 0x1a
	jrl nc, VoiceInit_ChannelNext

VoiceInit_ChannelLoop:
	ld a, (xsp + 6)
	extz wa
	add wa, 0x24
	ld bc, wa
	extz xbc
	add xbc, xiz
	ld_srib A, (xsp + 0x0153)
	cp a, (xbc)
	jrl nz, VoiceProcess_NextChannel
	ld a, (xsp + 6)
	extz wa
	add wa, wa
	add wa, 0x124
	bit_dri 6, 0x07, 0xf8, 0xe0
	jrl z, VoiceProcess_NextChannel
	ld a, (xsp + 6)
	extz wa
	add wa, wa
	add wa, 0x124
	bit_dri 4, 0x07, 0xf8, 0xe0
	jr nz, VoiceInit_LookupTableAndAssign
	st_dri3b W, 0xfd, 0x50, 0x01
	ld xbc, xwa
	ld a, (xsp + 6)
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, xiz
	call NoteMap_CollectAndAllocVoice_Indirect
	jrl VoiceProcess_NextChannel

VoiceInit_LookupTableAndAssign:
	stib_dri 0xfd, 0xac, 0x00, 0x90
	stib_dri 0xfd, 0xae, 0x00, 0x00
	stib_dri 0xfd, 0xaf, 0x00, 0x01
	st_dri3b W, 0xfd, 0xac, 0x00
	call Voice_LookupTableEntries
	cps l, 0
	jrl z, VoiceProcess_NextChannel
	st_dri3b W, 0xfd, 0xac, 0x00
	call NoteMap_AssignAllVoiceLinks
	cp (xiz + 1), 0xff
	jrl nz, VoiceInit_CheckSpecialChannel
	bitm 0, (xiz)
	jr z, VoiceInit_MergeLayer1
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xac, 0x00
	ld xbc, xwa
	st_dri3b W, 0xf9, 0xc4, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, VoiceInit_MergeLayer1
	lda xwa, (xsp + 8)
	ld xbc, xiz
	lds de, 0
	call NoteMap_UpdateEntry

VoiceInit_MergeLayer1:
	bitm 1, (xiz)
	jr z, VoiceInit_MergeLayer2
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xac, 0x00
	ld xbc, xwa
	st_dri3b W, 0xf9, 0xc8, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, VoiceInit_MergeLayer2
	lda xwa, (xsp + 8)
	ld xbc, xiz
	lds de, 1
	call NoteMap_UpdateEntry

VoiceInit_MergeLayer2:
	bitm 2, (xiz)
	jr z, VoiceInit_MergeLayer3
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xac, 0x00
	ld xbc, xwa
	st_dri3b W, 0xf9, 0xcc, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, VoiceInit_MergeLayer3
	lda xwa, (xsp + 8)
	ld xbc, xiz
	lds de, 2
	call NoteMap_UpdateEntry

VoiceInit_MergeLayer3:
	bitm 3, (xiz)
	jrl z, VoiceProcess_NextChannel
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xac, 0x00
	ld xbc, xwa
	st_dri3b W, 0xf9, 0xd0, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, VoiceProcess_NextChannel
	lda xwa, (xsp + 8)
	ld xbc, xiz
	ldw de, 0x15
	call NoteMap_UpdateEntry
	jr VoiceProcess_NextChannel

VoiceInit_CheckSpecialChannel:
	cp (xiz + 1), 0x15
	jr nz, VoiceInit_CheckLayer3Only
	ldda16 xwa, 50584
	bit 1, wa
	jr z, VoiceInit_SpecialChannelUpdate
	st_dri3b W, 0xfd, 0xac, 0x00
	call NoteMap_MarkEntriesAboveThreshold

VoiceInit_SpecialChannelUpdate:
	st_dri3b W, 0xfd, 0xac, 0x00
	ld xbc, xiz
	ldw de, 0x15
	call NoteMap_UpdateEntry
	jr VoiceProcess_NextChannel

VoiceInit_CheckLayer3Only:
	bitm 3, (xiz)
	jr z, VoiceInit_UpdateByChannelType
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xac, 0x00
	ld xbc, xwa
	st_dri3b W, 0xf9, 0xd0, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, VoiceInit_UpdateByChannelType
	lda xwa, (xsp + 8)
	ld xbc, xiz
	ldw de, 0x15
	call NoteMap_UpdateEntry

VoiceInit_UpdateByChannelType:
	st_dri3b W, 0xfd, 0xac, 0x00
	ld xbc, xwa
	ld a, (xiz + 1)
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, xiz
	call NoteMap_UpdateEntry

VoiceProcess_NextChannel:
	incm8 1, (xsp + 6)
	cp (xsp + 6), 0x1a
	jrl c, VoiceInit_ChannelLoop

VoiceInit_ChannelNext:
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x10
	jrl c, VoiceInit_PartLoop

VoiceInit_Epilogue:
	pop xiz
	st_dri3b L, 0xfd, 0xf0, 0x01
	ret


; -----------------------------------------------------------------------------
; Section: NoteMap Entry Management
; -----------------------------------------------------------------------------
; NoteMap storage, retrieval, voice linking, merge
; allocation, and control change encoding.
; -----------------------------------------------------------------------------

NoteMap_ProcessAndMerge:
	st_dri3b L, 0xfd, 0xb8, 0xfe
	push xiz
	ldada xiz, 49662
	stib_dri 0xfd, 0xa8, 0x00, 0x90
	stib_dri 0xfd, 0xaa, 0x00, 0x00
	stib_dri 0xfd, 0xab, 0x00, 0x00
	st_dri3b W, 0xfd, 0xa8, 0x00
	call Voice_LookupTableEntries
	cps l, 0
	jrl z, NoteMap_AddEntry_Return
	st_dri3b W, 0xfd, 0xa8, 0x00
	call NoteMap_AssignAllVoiceLinks
	cp (xiz + 1), 0xff
	jrl nz, NoteMap_ProcessMerge_SpecialPath
	lda xwa, (xsp + 4)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa8, 0x00
	ld xbc, xwa
	st_dri3b W, 0xf9, 0xc4, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, NoteMap_ProcessMerge_Layer1
	lda xwa, (xsp + 4)
	ld xbc, xiz
	lds de, 0
	call NoteMap_AddEntry

NoteMap_ProcessMerge_Layer1:
	lda xwa, (xsp + 4)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa8, 0x00
	ld xbc, xwa
	st_dri3b W, 0xf9, 0xc4, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, NoteMap_ProcessMerge_Layer2
	lda xwa, (xsp + 4)
	ld xbc, xiz
	lds de, 1
	call NoteMap_AddEntry

NoteMap_ProcessMerge_Layer2:
	lda xwa, (xsp + 4)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa8, 0x00
	ld xbc, xwa
	st_dri3b W, 0xf9, 0xcc, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, NoteMap_ProcessMerge_Layer3
	lda xwa, (xsp + 4)
	ld xbc, xiz
	lds de, 2
	call NoteMap_AddEntry

NoteMap_ProcessMerge_Layer3:
	lda xwa, (xsp + 4)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa8, 0x00
	ld xbc, xwa
	st_dri3b W, 0xf9, 0xd0, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, NoteMap_AddEntry_Return
	lda xwa, (xsp + 4)
	ld xbc, xiz
	ldw de, 0x15
	call NoteMap_AddEntry
	jr NoteMap_AddEntry_Return

NoteMap_ProcessMerge_SpecialPath:
	lda xwa, (xsp + 4)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa8, 0x00
	ld xbc, xwa
	st_dri3b W, 0xf9, 0xd0, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, NoteMap_ProcessMerge_UpdateChannel
	lda xwa, (xsp + 4)
	ld xbc, xiz
	ldw de, 0x15
	call NoteMap_AddEntry

NoteMap_ProcessMerge_UpdateChannel:
	st_dri3b W, 0xfd, 0xa8, 0x00
	ld xbc, xwa
	ld a, (xiz + 1)
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, xiz
	call NoteMap_AddEntry

NoteMap_AddEntry_Return:
	pop xiz
	st_dri3b L, 0xfd, 0x48, 0x01
	ret

NoteMap_SendAllNotesOff:
	st_dri3b L, 0xfd, 0x58, 0xff
	push_werp 0xfa
	ldada xwa, 49662
	ld (xsp + 2), xwa
	ldi_berp 0xfb, 0
	cp_erpb 0xfb, 0x10
	jr nc, NoteOff_Return

NoteOff_PartLoop_Body:
	ld (xsp + 6), 0x90
	ld (xsp + 8), 0x2
	ldto_berp A, 0xfb
	ld (xsp + 9), a
	ldto_berp A, 0xfb
	extz wa
	add wa, 0x84
	extz xwa
	add xwa, (xsp + 2)
	ld e, (xwa)
	ld a, e
	cp a, 0xff
	jr z, NoteOff_PartLoop_Layer3
	lda xwa, (xsp + 6)
	extz de
	ld xbc, (xsp + 2)
	call NoteMap_ProcessNoteEvent

NoteOff_PartLoop_Layer3:
	ld (xsp + 8), 0x3
	ldto_berp A, 0xfb
	ld (xsp + 9), a
	ldto_berp A, 0xfb
	extz wa
	add wa, 0x84
	extz xwa
	add xwa, (xsp + 2)
	ld e, (xwa)
	ld a, e
	cp a, 0xff
	jr z, NoteOff_PartLoop_Next
	lda xwa, (xsp + 6)
	extz de
	ld xbc, (xsp + 2)
	call NoteMap_ProcessNoteEvent

NoteOff_PartLoop_Next:
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, NoteOff_PartLoop_Body

NoteOff_Return:
	pop_werp 0xfa
	st_dri3b L, 0xfd, 0xa8, 0x00
	ret

Voice_InitTableGroup:
	st_dri3b L, 0xfd, 0x58, 0xff
	push_werp 0xfa
	ldada xwa, 49662
	ld (xsp + 2), xwa
	ld (xsp + 6), 0x90
	ld (xsp + 8), 0x4
	ldi_berp 0xfb, 0
	cpi_berp 0xfb, 5
	jr nc, VoiceTableGroup_Return

VoiceTableGroup_PartLoop:
	ldto_berp A, 0xfb
	ld (xsp + 9), a
	ldto_berp A, 0xfb
	extz wa
	lda_24 xbc, 0xee8ef0
	ld_srib3 E, 0x07, 0xe4, 0xe0
	lda xwa, (xsp + 6)
	extz de
	ld xbc, (xsp + 2)
	call NoteMap_LookupAndAllocVoice
	inc1_berp 0xfb
	cpi_berp 0xfb, 5
	jr c, VoiceTableGroup_PartLoop

VoiceTableGroup_Return:
	pop_werp 0xfa
	st_dri3b L, 0xfd, 0xa8, 0x00
	ret

Voice_InitTablePair:
	st_dri3b L, 0xfd, 0x58, 0xff
	push_werp 0xfa
	ldada xwa, 49662
	ld (xsp + 2), xwa
	ld (xsp + 6), 0x90
	ld (xsp + 8), 0x5
	ldi_berp 0xfb, 0
	cpi_berp 0xfb, 2
	jr nc, VoiceTablePair_Return

VoiceTablePair_PartLoop:
	ldto_berp A, 0xfb
	ld (xsp + 9), a
	ldto_berp A, 0xfb
	extz wa
	lda_24 xbc, 0xee8efe
	ld_srib3 E, 0x07, 0xe4, 0xe0
	lda xwa, (xsp + 6)
	extz de
	ld xbc, (xsp + 2)
	call NoteMap_LookupAllocAndStoreResult
	inc1_berp 0xfb
	cpi_berp 0xfb, 2
	jr c, VoiceTablePair_PartLoop

VoiceTablePair_Return:
	pop_werp 0xfa
	st_dri3b L, 0xfd, 0xa8, 0x00
	ret

VoiceEvent_ResetAndInit:
	ret

VoiceEvent_AllocAllLayers:
	ldada xwa, 49662
	lds bc, 0
	call NoteMap_AllocateVoice
	ldada xwa, 49662
	lds bc, 1
	call NoteMap_AllocateVoice
	cpdi16 52770, 0
	ret z
	call NoteMap_FindBestMatch
	cp l, 0xff
	ret z
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_AllocateVoice
	ret

VoiceEvent_AllocTwoLayers:
	ldada	xwa, 49662
	lds	bc, 0
	call	NoteMap_AssignVoiceParams
	ldada	xwa, 49662
	lds	bc, 1
	jp	NoteMap_AssignVoiceParams

VoiceEvent_DispatchTable:
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_AssignVoiceParams
	ldada xwa, 49662
	lds bc, 2
	jp NoteMap_InitVoiceSlots
VoiceEvent_TableSeparator:
	ret

VoiceEvent_HandlerTable:
	pushw iz
	lds iz, 0
	cpda16 xiz, 50378
	jrl nc, VoiceEvtHandler_Done

; Voice event type dispatch
VoiceEvent_TypeDispatch:
	ld wa, iz
	sll wa, 2
	ldada xbc, 50380
	extz xwa
	add xwa, xbc
	ld h, (xwa)
	ld wa, iz
	sll wa, 2
	ldada xbc, 50381
	extz xwa
	add xwa, xbc
	ld l, (xwa)
	ld wa, iz
	sll wa, 2
	ldada xbc, 50382
	extz xwa
	add xwa, xbc
	ld c, (xwa)
	ld wa, iz
	sll wa, 2
	ldada xde, 50383
	extz xwa
	add xwa, xde
	ld e, (xwa)
	ld a, h
	extz wa
	cps wa, 0
	jrl mi, AudioInit_FlushQueue_LoopNext
	cp wa, 0xd
	jrl gt, AudioInit_FlushQueue_LoopNext
	add wa, wa
	lda_24 xix, 0xee8f06
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, VoiceEvent_Dispatch
	jp_dri 8, 0x07, 0xf0, 0xe0

; Voice event handler dispatch (14-entry, table 0xee8f06)
VoiceEvent_Dispatch:
	ld a, l
	extz wa
	extz bc
	extz de
	call ReallocVoices_Exit_WriteReg
	jrl AudioInit_FlushQueue_LoopNext

VoiceEvtHandler_Type1:
	ld a, c
	extz wa
	ld c, e
	extz bc
	call StoreAndRet_WriteReg
	jrl AudioInit_FlushQueue_LoopNext

VoiceEvtHandler_Type2:
	ld a, l
	extz wa
	extz bc
	extz de
	call CheckControlCode_Tes_WriteReg
	jrl AudioInit_FlushQueue_LoopNext

VoiceEvtHandler_Type3:
	ld a, l
	extz wa
	extz bc
	extz de
	call NoteMap_ProcessLayeredNoteOn
	jr AudioInit_FlushQueue_LoopNext

VoiceEvtHandler_Type4:
	ld a, l
	extz wa
	extz bc
	extz de
	call NoteMap_ProcessDualLayerNoteOff
	jr AudioInit_FlushQueue_LoopNext

VoiceEvtHandler_Type5:
	ld a, c
	extz wa
	ld c, e
	extz bc
	call ProcessLayeredNoteOn_WriteReg4
	jr AudioInit_FlushQueue_LoopNext

VoiceEvtHandler_Type6:
	ld a, l
	extz wa
	extz bc
	extz de
	call PopIzStoreRet_Prologue
	jr AudioInit_FlushQueue_LoopNext

VoiceEvtHandler_Type7:
	ld a, l
	extz wa
	extz bc
	extz de
	call PopIzStoreRet_WriteReg
	jr AudioInit_FlushQueue_LoopNext

VoiceEvtHandler_Type8:
	ld a, l
	extz wa
	extz bc
	extz de
	call SetParam_Return_WriteReg
	jr AudioInit_FlushQueue_LoopNext

VoiceEvtHandler_Type9:
	ld a, l
	extz wa
	extz bc
	extz de
	call SeqPart_EmitMelodicNote
	jr AudioInit_FlushQueue_LoopNext

VoiceEvtHandler_Type10:
	ld a, l
	extz wa
	extz bc
	extz de
	call SeqPart_EmitPercussionNote
	jr AudioInit_FlushQueue_LoopNext

VoiceEvtHandler_Type11:
	call Voice_UpdatePlayModeState
	cp l, 0xff
	jr z, AudioInit_FlushQueue_LoopNext
	calr VoiceEvent_AllocAllLayers
	jr AudioInit_FlushQueue_LoopNext

VoiceEvtHandler_Type12:
	call NoteMap_FindBestMatch
	cp l, 0xff
	call_24 nz, 0xfe12fc

AudioInit_FlushQueue_LoopNext:
	inc 1, iz
	cpda16 xiz, 50378
	jrl c, VoiceEvent_TypeDispatch

VoiceEvtHandler_Done:
	stdi16 50378, 0
	popw iz
	ret

VoiceEvent_FlushAndReturn:
	st_dri3b L, 0xfd, 0xb0, 0xfe
	lda_dri3 XHL, 0xfd, 0x4e, 0x01
	cp a, 0xff
	jrl z, VoiceClaim_Slot0_Alt
	stib_dri 0xfd, 0xaa, 0x00, 0x90
	lda_dri3 XBC, 0xfd, 0xac, 0x00
	stib_dri 0xfd, 0xad, 0x00, 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xaa, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jrl z, Audio_StoreParamAndReturn
	ld (xsp + 256), 0x4
	ld (xsp + 256), 0xb0
	ld_srib A, (xsp + 0x014e)
	ld (xsp + 1), a
	ld (xsp + 2), 0x7b
	ld (xsp + 3), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	lds de, 0
	jr VoiceClaim_Slot0_MarkCheck

VoiceClaim_Slot0_MarkLoop:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 7)
	add xwa, xbc
	setm 7, (xwa)
	inc 1, de

VoiceClaim_Slot0_MarkCheck:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, VoiceClaim_Slot0_MarkLoop
	ld_srib A, (xsp + 0x014e)
	extz wa
	ldada xbc, 49666
	extz xwa
	add xwa, xbc
	cp (xwa), 0xff
	jrl z, Audio_StoreParamAndReturn
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	jrl Audio_StoreParamAndReturn

VoiceClaim_Slot0_Alt:
	stib_dri 0xfd, 0xaa, 0x00, 0x90
	stib_dri 0xfd, 0xac, 0x00, 0x00
	stib_dri 0xfd, 0xad, 0x00, 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xaa, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jrl z, VoiceClaim_Extended_Init
	ld (xsp + 256), 0x4
	ld (xsp + 1), 0xb0
	ld_srib A, (xsp + 0x014e)
	ld (xsp + 2), a
	ld (xsp + 3), 0x7b
	ld (xsp + 4), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	lds de, 0
	jr VoiceClaim_Slot0_Alt_MarkCheck

VoiceClaim_Slot0_Alt_MarkLoop:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 7)
	add xwa, xbc
	setm 7, (xwa)
	inc 1, de

VoiceClaim_Slot0_Alt_MarkCheck:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, VoiceClaim_Slot0_Alt_MarkLoop
	ld_srib A, (xsp + 0x014e)
	extz wa
	ldada xbc, 49666
	extz xwa
	add xwa, xbc
	cp (xwa), 0xff
	jr z, VoiceClaim_Slot1_Init
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

VoiceClaim_Slot1_Init:
	stib_dri 0xfd, 0xac, 0x00, 0x01
	stib_dri 0xfd, 0xad, 0x00, 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xaa, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jr z, VoiceClaim_Slot2_Init
	lds de, 0
	jr VoiceClaim_Slot1_MarkCheck

VoiceClaim_Slot1_MarkLoop:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 7)
	add xwa, xbc
	setm 7, (xwa)
	inc 1, de

VoiceClaim_Slot1_MarkCheck:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, VoiceClaim_Slot1_MarkLoop
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

VoiceClaim_Slot2_Init:
	stib_dri 0xfd, 0xac, 0x00, 0x02
	stib_dri 0xfd, 0xad, 0x00, 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xaa, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jr z, VoiceClaim_Slot3_Init
	lds de, 0
	jr VoiceClaim_Slot2_MarkCheck

VoiceClaim_Slot2_MarkLoop:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 7)
	add xwa, xbc
	setm 7, (xwa)
	inc 1, de

VoiceClaim_Slot2_MarkCheck:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, VoiceClaim_Slot2_MarkLoop
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

VoiceClaim_Slot3_Init:
	stib_dri 0xfd, 0xac, 0x00, 0x03
	stib_dri 0xfd, 0xad, 0x00, 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xaa, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jr z, VoiceClaim_Slot6_Init
	lds de, 0
	jr VoiceClaim_Slot3_MarkCheck

VoiceClaim_Slot3_MarkLoop:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 7)
	add xwa, xbc
	setm 7, (xwa)
	inc 1, de

VoiceClaim_Slot3_MarkCheck:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, VoiceClaim_Slot3_MarkLoop
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

VoiceClaim_Slot6_Init:
	stib_dri 0xfd, 0xac, 0x00, 0x06
	stib_dri 0xfd, 0xad, 0x00, 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xaa, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jrl z, Audio_StoreParamAndReturn
	lds de, 0
	jr VoiceClaim_Slot6_MarkCheck

VoiceClaim_Slot6_MarkLoop:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 7)
	add xwa, xbc
	setm 7, (xwa)
	inc 1, de

VoiceClaim_Slot6_MarkCheck:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, VoiceClaim_Slot6_MarkLoop
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	jrl Audio_StoreParamAndReturn

VoiceClaim_Extended_Init:
	stib_dri 0xfd, 0xaa, 0x00, 0x90
	stib_dri 0xfd, 0xac, 0x00, 0x01
	stib_dri 0xfd, 0xad, 0x00, 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xaa, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jrl z, VoiceClaim_Extended_Return
	ld (xsp + 256), 0x4
	ld (xsp + 1), 0xb0
	ld_srib A, (xsp + 0x014e)
	ld (xsp + 2), a
	ld (xsp + 3), 0x7b
	ld (xsp + 4), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	lds de, 0
	jr VoiceClaimExt_Slot1_MarkCheck

VoiceClaimExt_Slot1_MarkLoop:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 7)
	add xwa, xbc
	setm 7, (xwa)
	inc 1, de

VoiceClaimExt_Slot1_MarkCheck:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, VoiceClaimExt_Slot1_MarkLoop
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	stib_dri 0xfd, 0xac, 0x00, 0x02
	stib_dri 0xfd, 0xad, 0x00, 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xaa, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jr z, VoiceClaimExt_Slot2_SetParam
	lds de, 0
	jr VoiceClaimExt_Slot2_MarkCheck

VoiceClaimExt_Slot2_MarkLoop:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 7)
	add xwa, xbc
	setm 7, (xwa)
	inc 1, de

VoiceClaimExt_Slot2_MarkCheck:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, VoiceClaimExt_Slot2_MarkLoop
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

VoiceClaimExt_Slot2_SetParam:
	stib_dri 0xfd, 0xac, 0x00, 0x03
	stib_dri 0xfd, 0xad, 0x00, 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xaa, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jr z, VoiceClaimExt_Slot3_SetParam
	lds de, 0
	jr VoiceClaimExt_Slot3_MarkCheck

VoiceClaimExt_Slot3_MarkLoop:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 7)
	add xwa, xbc
	setm 7, (xwa)
	inc 1, de

VoiceClaimExt_Slot3_MarkCheck:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, VoiceClaimExt_Slot3_MarkLoop
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

VoiceClaimExt_Slot3_SetParam:
	stib_dri 0xfd, 0xac, 0x00, 0x06
	stib_dri 0xfd, 0xad, 0x00, 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xaa, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jrl z, Audio_StoreParamAndReturn
	lds de, 0
	jr VoiceClaimExt_Slot6_MarkCheck

VoiceClaimExt_Slot6_MarkLoop:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 7)
	add xwa, xbc
	setm 7, (xwa)
	inc 1, de

VoiceClaimExt_Slot6_MarkCheck:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, VoiceClaimExt_Slot6_MarkLoop
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	jrl Audio_StoreParamAndReturn

VoiceClaim_Extended_Return:
	stib_dri 0xfd, 0xac, 0x00, 0x02
	stib_dri 0xfd, 0xad, 0x00, 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xaa, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jrl z, VoiceClaimExt2_Slot3_WriteReg
	ld (xsp + 256), 0x4
	ld (xsp + 1), 0xb0
	ld_srib A, (xsp + 0x014e)
	ld (xsp + 2), a
	ld (xsp + 3), 0x7b
	ld (xsp + 4), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	lds de, 0
	jr VoiceClaimExt2_Slot1_MarkCheck

VoiceClaimExt2_Slot1_MarkLoop:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 7)
	add xwa, xbc
	setm 7, (xwa)
	inc 1, de

VoiceClaimExt2_Slot1_MarkCheck:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, VoiceClaimExt2_Slot1_MarkLoop
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	stib_dri 0xfd, 0xac, 0x00, 0x03
	stib_dri 0xfd, 0xad, 0x00, 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xaa, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jr z, VoiceClaimExt2_Slot2_SetParam
	lds de, 0
	jr VoiceClaimExt2_Slot2_MarkCheck

VoiceClaimExt2_Slot2_MarkLoop:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 7)
	add xwa, xbc
	setm 7, (xwa)
	inc 1, de

VoiceClaimExt2_Slot2_MarkCheck:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, VoiceClaimExt2_Slot2_MarkLoop
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

VoiceClaimExt2_Slot2_SetParam:
	stib_dri 0xfd, 0xac, 0x00, 0x06
	stib_dri 0xfd, 0xad, 0x00, 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xaa, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jrl z, Audio_StoreParamAndReturn
	lds de, 0
	jr VoiceClaimExt2_Slot3_MarkCheck

VoiceClaimExt2_Slot3_MarkLoop:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 7)
	add xwa, xbc
	setm 7, (xwa)
	inc 1, de

VoiceClaimExt2_Slot3_MarkCheck:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, VoiceClaimExt2_Slot3_MarkLoop
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	jrl Audio_StoreParamAndReturn

VoiceClaimExt2_Slot3_WriteReg:
	stib_dri 0xfd, 0xac, 0x00, 0x03
	stib_dri 0xfd, 0xad, 0x00, 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xaa, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jrl z, VoiceClaimExt2_Slot3_WriteReg2
	ld (xsp + 256), 0x4
	ld (xsp + 1), 0xb0
	ld_srib A, (xsp + 0x014e)
	ld (xsp + 2), a
	ld (xsp + 3), 0x7b
	ld (xsp + 4), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	lds de, 0
	jr VoiceClaimExt2_Slot3_LoopCheck

VoiceClaimExt2_Slot3_LoopBody:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 7)
	add xwa, xbc
	setm 7, (xwa)
	inc 1, de

VoiceClaimExt2_Slot3_LoopCheck:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, VoiceClaimExt2_Slot3_LoopBody
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	stib_dri 0xfd, 0xac, 0x00, 0x06
	stib_dri 0xfd, 0xad, 0x00, 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xaa, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jrl z, Audio_StoreParamAndReturn
	lds de, 0
	jr VoiceClaimExt2_Slot3_LoopCheck2

VoiceClaimExt2_Slot3_LoopBody2:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 7)
	add xwa, xbc
	setm 7, (xwa)
	inc 1, de

VoiceClaimExt2_Slot3_LoopCheck2:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, VoiceClaimExt2_Slot3_LoopBody2
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	jrl Audio_StoreParamAndReturn

VoiceClaimExt2_Slot3_WriteReg2:
	stib_dri 0xfd, 0xac, 0x00, 0x06
	stib_dri 0xfd, 0xad, 0x00, 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xaa, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jr z, Audio_StoreParamAndReturn
	ld (xsp + 256), 0x4
	ld (xsp + 1), 0xb0
	ld_srib A, (xsp + 0x014e)
	ld (xsp + 2), a
	ld (xsp + 3), 0x7b
	ld (xsp + 4), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	lds de, 0
	jr VoiceClaimExt2_Slot3_LoopCheck3

VoiceClaimExt2_Slot3_LoopBody3:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 7)
	add xwa, xbc
	setm 7, (xwa)
	inc 1, de

VoiceClaimExt2_Slot3_LoopCheck3:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, VoiceClaimExt2_Slot3_LoopBody3
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

Audio_StoreParamAndReturn:
	st_dri3b L, 0xfd, 0x50, 0x01
	ret


; -----------------------------------------------------------------------------
; Section: MIDI Event & Channel Configuration
; -----------------------------------------------------------------------------
; MIDI channel configuration, voice slot data init,
; and note sequence parsing.
; -----------------------------------------------------------------------------

MidiEvent_ConfigChannel:
	st_dri3b L, 0xfd, 0xb0, 0xfe
	lda_dri3 XHL, 0xfd, 0x4e, 0x01
	cp a, 0xff
	jr z, MidiConfig_Slot6Path
	stib_dri 0xfd, 0xaa, 0x00, 0x90
	lda_dri3 XBC, 0xfd, 0xac, 0x00
	stib_dri 0xfd, 0xad, 0x00, 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xaa, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jrl z, MidiConfig_Return
	ld (xsp + 256), 0x4
	ld (xsp + 256), 0xb0
	ld_srib A, (xsp + 0x014e)
	ld (xsp + 1), a
	ld (xsp + 2), 0x7b
	ld (xsp + 3), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	ld_srib A, (xsp + 0x014e)
	extz wa
	ldada xbc, 49666
	extz xwa
	add xwa, xbc
	cp (xwa), 0xff
	jrl z, MidiConfig_Return
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	jr MidiConfig_Return

MidiConfig_Slot6Path:
	stib_dri 0xfd, 0xaa, 0x00, 0x90
	stib_dri 0xfd, 0xac, 0x00, 0x06
	stib_dri 0xfd, 0xad, 0x00, 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xaa, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jr z, MidiConfig_Return
	ld (xsp + 256), 0x4
	ld (xsp + 1), 0xb0
	ld_srib A, (xsp + 0x014e)
	ld (xsp + 2), a
	ld (xsp + 3), 0x7b
	ld (xsp + 4), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	ld_srib A, (xsp + 0x014e)
	extz wa
	ldada xbc, 49666
	extz xwa
	add xwa, xbc
	cp (xwa), 0xff
	jr z, MidiConfig_Return
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

MidiConfig_Return:
	st_dri3b L, 0xfd, 0x50, 0x01
	ret

Voice_FindAndAllocBestMatch:
	cpdi16 52770, 0
	ret z
	call NoteMap_FindBestMatch
	cp l, 0xff
	ret z
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_AllocateVoice
	ret

Voice_InitSlotData:
	ldda8 a, 52965
	extz wa
	stda16 52991, xwa
	lds de, 0
	jr VoiceSlotInit_Check

VoiceSlotInit_Loop:
	ld wa, de
	add wa, wa
	inc 4, wa
	ldada xbc, 52992
	ld hl, wa
	extz xhl
	add xhl, xbc
	ld wa, de
	inc 1, wa
	ldada xbc, 52965
	ld_srib3 A, 0x07, 0xe4, 0xe0
	ld (xhl), a
	ld wa, de
	add wa, wa
	ldada xbc, 52995
	extz xwa
	add xwa, xbc
	ld (xwa), 0x40
	inc 1, de

VoiceSlotInit_Check:
	ldda8 a, 52965
	extz wa
	cp de, wa
	jr lt, VoiceSlotInit_Loop
	call Voice_InitPartAllocState
	ldada xwa, 49662
	lds bc, 0
	call NoteMap_AllocateVoice
	ldada xwa, 49662
	lds bc, 1
	call NoteMap_AllocateVoice
	stdi16 52991, 0
	ret

NoteMap_AssignAllVoiceLinks:
	dec 6, xsp
	push xiz
	ld (xsp + 6), xwa
	ld xwa, (xsp + 6)
	ld a, (xwa + 3)
	extz wa
	lda_24 xbc, 0xee8eb6
	ld_srib3 A, 0x07, 0xe4, 0xe0
	ld (xsp + 4), a
	lds iz, 0
	jrl VoiceLinks_CheckCount

VoiceLinks_SlotLoop:
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	cp (xbc + 1), 0x0
	jrl z, VoiceLinks_SkipEmpty
	ldda8 a, 59433
	ldfr_berp A, 0xfb
	cp a, 0x20
	jrl z, MidiEvent_NoteLoopAdvance
	ldada xde, 59368
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SwapVoiceLinks
	ldada xhl, 59368
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld a, (xsp + 4)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_LinkVoiceSlots
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x3
	ld de, wa
	ldada xhl, 50635
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	ld a, (xbc)
	lda_dri3 XBC, 0x07, 0xec, 0xe8
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x3
	ld de, wa
	ldada xhl, 50636
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	ld a, (xbc + 1)
	lda_dri3 XBC, 0x07, 0xec, 0xe8
	incdi16 1, 59834
	jr MidiEvent_NoteLoopAdvance

VoiceLinks_SkipEmpty:
	ldto_berp A, 0xf8
	ld c, a
	extz bc
	ld xwa, (xsp + 6)
	call LinkVoiceSlots_Block
	ldfr_berp L, 0xfb
	ldto_berp A, 0xfb
	cp a, (xsp + 4)
	jr z, VoiceLinks_SkipEmpty_LoadIter
	ldada xde, 59368
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SwapVoiceLinks
	ldada xde, 59368
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	ldw de, 0x20
	call NoteMap_LinkVoiceSlots
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x3
	ldada xbc, 50635
	stib_dri 0x07, 0xe4, 0xe0, 0xff
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x3
	ldada xbc, 50636
	stib_dri 0x07, 0xe4, 0xe0, 0xff
	decdi16 1, 59834
	jr MidiEvent_NoteLoopAdvance

VoiceLinks_SkipEmpty_LoadIter:
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	setm 1, (xbc + 4)

MidiEvent_NoteLoopAdvance:
	inc 1, iz

VoiceLinks_CheckCount:
	ld xwa, (xsp + 6)
	ld a, (xwa + 1)
	extz wa
	cp iz, wa
	jrl c, VoiceLinks_SlotLoop
	pop xiz
	inc 6, xsp
	ret

MidiEvent_ParseNoteSequence:
	dec 8, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 8), xwa
	ldw (xsp + 4), 0x0
	ld (xiz), 0x90
	ld (xiz + 2), 0x0
	ld (xiz + 3), 0x0
	ld xwa, (xsp + 8)
	cp (xwa), 0xff
	jr z, MidiEvent_NoteSeqCount

ParseNoteSequence_ReadBuf:
	call SeqBuf_NoteEvent_ReadByte
	ld (xsp + 6), hl
	ld wa, (xsp + 6)
	cp wa, 0xffff
	jr nz, ParseNoteSequence_ReadBuf2
	ld xwa, (xsp + 8)
	ld (xwa), 0xff
	jr MidiEvent_NoteSeqCount

ParseNoteSequence_ReadBuf2:
	call SeqBuf_NoteEvent_ReadByte
	ld wa, hl
	cp wa, 0xffff
	jr nz, ParseNoteSequence_Compare
	ld xwa, (xsp + 8)
	ld (xwa), 0xff
	jr MidiEvent_NoteSeqCount

ParseNoteSequence_Compare:
	cpw (xsp + 4), 0x20
	jr nc, ParseNoteSequence_AdvanceSlot
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, xiz
	ld (xbc + 4), 0x0
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, xiz
	ld wa, (xsp + 6)
	ld (xbc), a
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, xiz
	ld (xbc + 1), l

ParseNoteSequence_AdvanceSlot:
	incm 1, (xsp + 4)
	ld xwa, (xsp + 8)
	cp (xwa), 0xff
	jr nz, ParseNoteSequence_ReadBuf

MidiEvent_NoteSeqCount:
	cpw (xsp + 4), 0x20
	jr ugt, NoteSeqCount_ProcMerge
	ld wa, (xsp + 4)
	ld l, a
	ld (xiz + 1), l
	jr NoteSeqCount_Epilogue

NoteSeqCount_ProcMerge:
	call NoteMap_ProcessAndMerge
	ld (xiz + 1), 0x0
	ldb l, 0x0

NoteSeqCount_Epilogue:
	pop xiz
	inc 8, xsp
	ret

MidiEvent_ProcessNoteEntry:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 10), xbc
	ld xiz, xwa
	ldw (xsp + 4), 0x0
	ld a, (xiz)
	cp a, 0xff
	jrl z, MidiEvent_ClampAndStoreParam
	cps a, 0
	jr z, ProcessNoteEntry_CheckEnd
	ld xwa, (xsp + 10)
	ld c, (xiz)
	ld (xwa), c
	ld xwa, (xsp + 10)
	ld (xwa + 2), 0x1
	ld xwa, (xsp + 10)
	ld c, (xiz + 1)
	ld (xwa + 3), c
	ld xwa, (xsp + 10)
	ld (xwa + 8), 0x0
	ld xwa, (xsp + 10)
	ld c, (xiz + 3)
	ld (xwa + 4), c
	ld xwa, (xsp + 10)
	ld c, (xiz + 4)
	ld (xwa + 5), c
	incm 1, (xsp + 4)

ProcessNoteEntry_CheckEnd:
	cp (xiz), 0xff
	jrl z, MidiEvent_ClampAndStoreParam

ProcessNoteEntry_ReadBuf:
	call SeqMain_ReadData
	ld (xsp + 6), hl
	ld wa, (xsp + 6)
	cp wa, 0xffff
	jr nz, ProcessNoteEntry_ReadBuf2
	ld (xiz), 0xff
	jrl MidiEvent_ClampAndStoreParam

ProcessNoteEntry_ReadBuf2:
	call SeqMain_ReadData
	ld (xsp + 8), hl
	ld wa, (xsp + 8)
	cp wa, 0xffff
	jr nz, ProcessNoteEntry_ReadBuf3
	ld (xiz), 0xff
	jrl MidiEvent_ClampAndStoreParam

ProcessNoteEntry_ReadBuf3:
	call SeqMain_ReadData
	ld wa, hl
	cp wa, 0xffff
	jr nz, ProcessNoteEntry_Compare
	ld (xiz), 0xff
	jrl MidiEvent_ClampAndStoreParam

ProcessNoteEntry_Compare:
	cps hl, 0
	jr z, MidiEvent_ProcessCC_Continue
	cpdi8 50019, 255
	jr z, ProcessNoteEntry_CheckDRAM
	ldda8 l, 50019
	extz hl
	jr MidiEvent_ProcessCC_Continue

ProcessNoteEntry_CheckDRAM:
	cpdi8 50018, 0
	jr le, ProcessNoteEntry_LoadDRAM2
	ldda8 a, 50018
	exts wa
	add wa, hl
	cp a, 0x7f
	jr ule, ProcessNoteEntry_LoadDRAM
	ldw hl, 0x7f
	jr MidiEvent_ProcessCC_Continue

ProcessNoteEntry_LoadDRAM:
	ldda8 a, 50018
	exts wa
	add hl, wa
	jr MidiEvent_ProcessCC_Continue

ProcessNoteEntry_LoadDRAM2:
	ldda8 a, 50018
	exts wa
	add wa, hl
	cps a, 0
	jr ge, ProcessNoteEntry_LoadDRAM3
	lds hl, 1
	jr MidiEvent_ProcessCC_Continue

ProcessNoteEntry_LoadDRAM3:
	ldda8 a, 50018
	exts wa
	add hl, wa

MidiEvent_ProcessCC_Continue:
	ld wa, (xsp + 6)
	and a, 0xf0
	cp a, 0xb0
	jr nz, ClampAndStoreParam_CheckZero
	cpw (xsp + 4), 0x0
	jr nz, ClampAndStoreParam_LoadReg
	ld (xiz), 0xb0
	ld wa, (xsp + 6)
	and a, 0xf
	ld (xiz + 1), a
	ld xwa, (xsp + 10)
	ld c, (xiz)
	ld (xwa), c
	ld xwa, (xsp + 10)
	ld (xwa + 2), 0x1
	ld xwa, (xsp + 10)
	ld c, (xiz + 1)
	ld (xwa + 3), c
	incm 1, (xsp + 4)

ProcessCC_Continue_CheckEnd:
	cp (xiz), 0xff
	jrl nz, ProcessNoteEntry_ReadBuf

MidiEvent_ClampAndStoreParam:
	cpw (xsp + 4), 0x20
	jrl ugt, ClampAndStoreParam_DoInit
	ld wa, (xsp + 4)
	ld l, a
	ld xwa, (xsp + 10)
	ld (xwa + 1), l
	jrl ClampAndStoreParam_Epilogue

ClampAndStoreParam_LoadReg:
	ld (xiz), 0xb0
	ld wa, (xsp + 6)
	and a, 0xf
	ld (xiz + 1), a
	ld wa, (xsp + 8)
	ld (xiz + 3), a
	ld (xiz + 4), l
	jr MidiEvent_ClampAndStoreParam

ClampAndStoreParam_CheckZero:
	cpw (xsp + 4), 0x0
	jrl nz, ClampAndStoreParam_LoadParam2
	ld (xiz), 0x90
	ld wa, (xsp + 6)
	and a, 0xf
	ld (xiz + 1), a
	ld xwa, (xsp + 10)
	ld c, (xiz)
	ld (xwa), c
	ld xwa, (xsp + 10)
	ld (xwa + 2), 0x1
	ld xwa, (xsp + 10)
	ld c, (xiz + 1)
	ld (xwa + 3), c
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 10)
	ld (xbc + 4), 0x0
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 10)
	ld wa, (xsp + 8)
	ld (xbc), a
	ld wa, (xsp + 6)
	and a, 0xf0
	cp a, 0x80
	jr nz, ClampAndStoreParam_LoadParam
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 10)
	ld (xbc + 1), 0x0
	jr ClampAndStoreParam_AdvanceSlot

ClampAndStoreParam_LoadParam:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 10)
	ld (xbc + 1), l

ClampAndStoreParam_AdvanceSlot:
	incm 1, (xsp + 4)
	jrl ProcessCC_Continue_CheckEnd

ClampAndStoreParam_LoadParam2:
	ld wa, (xsp + 6)
	and a, 0xf
	cp a, (xiz + 1)
	jr nz, ClampAndStoreParam_LoadReg2
	cp (xiz), 0xb0
	jr z, ClampAndStoreParam_LoadReg2
	cpw (xsp + 4), 0x20
	jr nc, ClampAndStoreParam_AdvanceSlot2
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 10)
	ld (xbc + 4), 0x0
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 10)
	ld wa, (xsp + 8)
	ld (xbc), a
	ld wa, (xsp + 6)
	and a, 0xf0
	cp a, 0x80
	jr nz, ClampAndStoreParam_LoadParam3
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 10)
	ld (xbc + 1), 0x0
	jr ClampAndStoreParam_AdvanceSlot2

ClampAndStoreParam_LoadParam3:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 10)
	ld (xbc + 1), l

ClampAndStoreParam_AdvanceSlot2:
	incm 1, (xsp + 4)
	jrl ProcessCC_Continue_CheckEnd

ClampAndStoreParam_LoadReg2:
	ld (xiz), 0x90
	ld wa, (xsp + 6)
	and a, 0xf
	ld (xiz + 1), a
	ld wa, (xsp + 8)
	ld (xiz + 3), a
	ld wa, (xsp + 6)
	and a, 0xf0
	cp a, 0x80
	jr nz, ClampAndStoreParam_LoadReg3
	ld (xiz + 4), 0x0
	jrl MidiEvent_ClampAndStoreParam

ClampAndStoreParam_LoadReg3:
	ld (xiz + 4), l
	jrl MidiEvent_ClampAndStoreParam

ClampAndStoreParam_DoInit:
	call Voice_InitializeAll
	ld xwa, (xsp + 10)
	ld (xwa + 1), 0x0
	ldb l, 0x0

ClampAndStoreParam_Epilogue:
	pop xiz
	lda xsp, (xsp + 10)
	ret

MidiEvent_ReadAndParseLoop:
	lda xsp, (xsp - 16)
	pushw iz
	ld (xsp + 10), xbc
	ld (xsp + 14), xwa
	ldw (xsp + 2), 0x0
	ld xwa, (xsp + 14)
	ld a, (xwa)
	cp a, 0xff
	jrl z, NoteMap_FinalizeCount
	cps a, 0
	jr z, ReadAndParseLoop_LoadParam3
	ld xwa, (xsp + 14)
	ld c, (xwa)
	res 3, c
	ld xwa, (xsp + 10)
	ld (xwa), c
	ld xwa, (xsp + 14)
	bitm 3, (xwa)
	jr z, ReadAndParseLoop_LoadParam
	ld xwa, (xsp + 10)
	ld (xwa + 2), 0x3
	jr ReadAndParseLoop_LoadParam2

ReadAndParseLoop_LoadParam:
	ld xwa, (xsp + 10)
	ld (xwa + 2), 0x2

ReadAndParseLoop_LoadParam2:
	ld xwa, (xsp + 14)
	ld xbc, (xsp + 10)
	ld a, (xwa + 1)
	ld (xbc + 3), a
	ld xwa, (xsp + 10)
	ld (xwa + 8), 0x0
	ld xwa, (xsp + 14)
	ld xbc, (xsp + 10)
	ld a, (xwa + 3)
	ld (xbc + 4), a
	ld xwa, (xsp + 14)
	ld xbc, (xsp + 10)
	ld a, (xwa + 4)
	ld (xbc + 5), a
	incm 1, (xsp + 2)

ReadAndParseLoop_LoadParam3:
	ld xwa, (xsp + 14)
	cp (xwa), 0xff
	jrl z, NoteMap_FinalizeCount

ReadAndParseLoop_ReadAlt:
	call SeqBuf_ReadAlternate
	ld iz, hl
	ld wa, iz
	cp wa, 0xffff
	jr nz, ReadAndParseLoop_ReadAlt2
	ld xwa, (xsp + 14)
	ld (xwa), 0xff
	jrl NoteMap_FinalizeCount

ReadAndParseLoop_ReadAlt2:
	call SeqBuf_ReadAlternate
	ld (xsp + 4), hl
	ld wa, (xsp + 4)
	cp wa, 0xffff
	jr nz, ReadAndParseLoop_ReadAlt3
	ld xwa, (xsp + 14)
	ld (xwa), 0xff
	jrl NoteMap_FinalizeCount

ReadAndParseLoop_ReadAlt3:
	call SeqBuf_ReadAlternate
	ld (xsp + 6), hl
	ld wa, (xsp + 6)
	cp wa, 0xffff
	jr nz, ReadAndParseLoop_ReadAlt4
	ld xwa, (xsp + 14)
	ld (xwa), 0xff
	jrl NoteMap_FinalizeCount

ReadAndParseLoop_ReadAlt4:
	call SeqBuf_ReadAlternate
	ld (xsp + 8), hl
	ld wa, (xsp + 8)
	cp wa, 0xffff
	jr nz, ReadAndParseLoop_ReadAlt5
	ld xwa, (xsp + 14)
	ld (xwa), 0xff
	jr NoteMap_FinalizeCount

ReadAndParseLoop_ReadAlt5:
	call SeqBuf_ReadAlternate
	ld wa, hl
	cp wa, 0xffff
	jr nz, ReadAndParseLoop_LoadParam4
	ld xwa, (xsp + 14)
	ld (xwa), 0xff
	jr NoteMap_FinalizeCount

ReadAndParseLoop_LoadParam4:
	ld wa, (xsp + 4)
	cp a, 0x7f
	jrl nz, FinalizeCount_CheckZero
	cpw (xsp + 2), 0x0
	jr nz, FinalizeCount_LoadIdx
	ldto_berp A, 0xf8
	and a, 0x8
	or a, 0xb0
	ld c, a
	ld xwa, (xsp + 14)
	ld (xwa), c
	ld xwa, (xsp + 14)
	ld (xwa + 1), l
	ld xwa, (xsp + 14)
	ld c, (xwa)
	res 3, c
	ld xwa, (xsp + 10)
	ld (xwa), c
	ld xwa, (xsp + 14)
	bitm 3, (xwa)
	jr z, ReadAndParseLoop_LoadParam5
	ld xwa, (xsp + 10)
	ld (xwa + 2), 0x3
	jr ReadAndParseLoop_LoadParam6

ReadAndParseLoop_LoadParam5:
	ld xwa, (xsp + 10)
	ld (xwa + 2), 0x2

ReadAndParseLoop_LoadParam6:
	ld xwa, (xsp + 14)
	ld xbc, (xsp + 10)
	ld a, (xwa + 1)
	ld (xbc + 3), a
	incm 1, (xsp + 2)

ReadAndParseLoop_LoadParam7:
	ld xwa, (xsp + 14)
	cp (xwa), 0xff
	jrl nz, ReadAndParseLoop_ReadAlt

NoteMap_FinalizeCount:
	cpw (xsp + 2), 0x20
	jrl ugt, VoiceNotify_SendAllNotesOff
	ld wa, (xsp + 2)
	ld l, a
	ld xwa, (xsp + 10)
	ld (xwa + 1), l
	jrl VoiceNotify_Epilogue

FinalizeCount_LoadIdx:
	ldto_berp A, 0xf8
	and a, 0x8
	or a, 0xb0
	ld c, a
	ld xwa, (xsp + 14)
	ld (xwa), c
	ld xwa, (xsp + 14)
	ld (xwa + 1), l
	ld wa, (xsp + 6)
	ld c, a
	ld xwa, (xsp + 14)
	ld (xwa + 3), c
	ld wa, (xsp + 8)
	ld c, a
	ld xwa, (xsp + 14)
	ld (xwa + 4), c
	jr NoteMap_FinalizeCount

FinalizeCount_CheckZero:
	cpw (xsp + 2), 0x0
	jrl nz, FinalizeCount_LoadReg
	ldto_berp A, 0xf8
	and a, 0x8
	or a, 0x90
	ld c, a
	ld xwa, (xsp + 14)
	ld (xwa), c
	ld xwa, (xsp + 14)
	ld (xwa + 1), l
	ld xwa, (xsp + 14)
	ld c, (xwa)
	res 3, c
	ld xwa, (xsp + 10)
	ld (xwa), c
	ld xwa, (xsp + 14)
	bitm 3, (xwa)
	jr z, FinalizeCount_LoadParam
	ld xwa, (xsp + 10)
	ld (xwa + 2), 0x3
	jr FinalizeCount_LoadParam2

FinalizeCount_LoadParam:
	ld xwa, (xsp + 10)
	ld (xwa + 2), 0x2

FinalizeCount_LoadParam2:
	ld xwa, (xsp + 14)
	ld xbc, (xsp + 10)
	ld a, (xwa + 1)
	ld (xbc + 3), a
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 10)
	ld (xbc + 4), 0x0
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 10)
	ld wa, (xsp + 6)
	ld (xbc), a
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 10)
	ld wa, (xsp + 8)
	ld (xbc + 1), a
	incm 1, (xsp + 2)
	jrl ReadAndParseLoop_LoadParam7

FinalizeCount_LoadReg:
	ld c, l
	ld xwa, (xsp + 14)
	cp c, (xwa + 1)
	jr nz, Voice_BuildProgramNotify
	ldto_berp C, 0xf8
	ld xwa, (xsp + 14)
	cp c, (xwa)
	jr nz, Voice_BuildProgramNotify
	ld xwa, (xsp + 14)
	cp (xwa), 0xb0
	jr z, Voice_BuildProgramNotify
	cpw (xsp + 2), 0x20
	jr nc, FinalizeCount_AdvanceSlot
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 10)
	ld (xbc + 4), 0x0
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 10)
	ld wa, (xsp + 6)
	ld (xbc), a
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 10)
	ld wa, (xsp + 8)
	ld (xbc + 1), a

FinalizeCount_AdvanceSlot:
	incm 1, (xsp + 2)
	jrl ReadAndParseLoop_LoadParam7


; -----------------------------------------------------------------------------
; Section: Voice Program Change & Notification
; -----------------------------------------------------------------------------
; Voice program change notification, NoteMap finalization,
; and extended control change processing.
; -----------------------------------------------------------------------------

Voice_BuildProgramNotify:
	ldto_berp A, 0xf8
	and a, 0x8
	or a, 0x90
	ld c, a
	ld xwa, (xsp + 14)
	ld (xwa), c
	ld xwa, (xsp + 14)
	ld (xwa + 1), l
	ld wa, (xsp + 6)
	ld c, a
	ld xwa, (xsp + 14)
	ld (xwa + 3), c
	ld wa, (xsp + 8)
	ld c, a
	ld xwa, (xsp + 14)
	ld (xwa + 4), c
	jrl NoteMap_FinalizeCount

VoiceNotify_SendAllNotesOff:
	call NoteMap_SendAllNotesOff
	ld xwa, (xsp + 10)
	ld (xwa + 1), 0x0
	ldb l, 0x0

VoiceNotify_Epilogue:
	popw iz
	lda xsp, (xsp + 16)
	ret

RhythmBuf_ParseEventLoop:
	lda xsp, (xsp - 12)
	pushw iz
	ld (xsp + 6), xbc
	ld (xsp + 10), xwa
	ldw (xsp + 2), 0x0
	ld xwa, (xsp + 10)
	ld a, (xwa)
	cp a, 0xff
	jrl z, NoteMap_EncodeExtControlChange
	cps a, 0
	jr z, RhythmParse_ReadFromBuffer
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 6)
	ld a, (xwa)
	ld (xbc), a
	ld xwa, (xsp + 6)
	ld (xwa + 2), 0x4
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 6)
	ld a, (xwa + 1)
	ld (xbc + 3), a
	ld xwa, (xsp + 6)
	ld (xwa + 8), 0x0
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 6)
	ld a, (xwa + 3)
	ld (xbc + 4), a
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 6)
	ld a, (xwa + 4)
	ld (xbc + 5), a
	incm 1, (xsp + 2)

RhythmParse_ReadFromBuffer:
	ld xwa, (xsp + 10)
	cp (xwa), 0xff
	jrl z, NoteMap_EncodeExtControlChange

RhythmParse_ReadNote:
	call RhythmBuf_ReadAlternate
	ld iz, hl
	ld wa, iz
	cp wa, 0xffff
	jr nz, RhythmParse_ReadVelocity
	ld xwa, (xsp + 10)
	ld (xwa), 0xff
	jr NoteMap_EncodeExtControlChange

RhythmParse_ReadVelocity:
	call RhythmBuf_ReadAlternate
	ld (xsp + 4), hl
	ld wa, (xsp + 4)
	cp wa, 0xffff
	jr nz, RhythmParse_ReadDuration
	ld xwa, (xsp + 10)
	ld (xwa), 0xff
	jr NoteMap_EncodeExtControlChange

RhythmParse_ReadDuration:
	call RhythmBuf_ReadAlternate
	ld wa, hl
	cp wa, 0xffff
	jr nz, RhythmParse_CheckNoteOnType
	ld xwa, (xsp + 10)
	ld (xwa), 0xff
	jr NoteMap_EncodeExtControlChange

RhythmParse_CheckNoteOnType:
	cp_erpb 0xf8, 0x90
	jrl nz, RhythmParse_CheckAccType
	ld wa, (xsp + 4)
	cp a, 0x7f
	jr nz, NoteMap_CheckEndMarker
	cpw (xsp + 2), 0x0
	jr nz, RhythmParse_StoreCCAndNote
	ld xwa, (xsp + 10)
	ld (xwa), 0xb0
	ld a, l
	dec 4, a
	ld c, a
	ld xwa, (xsp + 10)
	ld (xwa + 1), c
	ld xwa, (xsp + 6)
	ld (xwa), 0xb0
	ld xwa, (xsp + 6)
	ld (xwa + 2), 0x4
	ld a, l
	dec 4, a
	ld c, a
	ld xwa, (xsp + 6)
	ld (xwa + 3), c
	incm 1, (xsp + 2)

NoteMap_CheckEndMarker:
	ld xwa, (xsp + 10)
	cp (xwa), 0xff
	jrl nz, RhythmParse_ReadNote

NoteMap_EncodeExtControlChange:
	cpw (xsp + 2), 0x20
	jrl ugt, RhythmParse_TruncateCount
	ld wa, (xsp + 2)
	ld l, a
	ld xwa, (xsp + 6)
	ld (xwa + 1), l
	jrl RhythmParse_StoreCountAndReturn

RhythmParse_StoreCCAndNote:
	ld xwa, (xsp + 10)
	ld (xwa), 0xb0
	ld a, l
	dec 4, a
	ld c, a
	ld xwa, (xsp + 10)
	ld (xwa + 1), c
	ld wa, (xsp + 4)
	ld c, a
	ld xwa, (xsp + 10)
	ld (xwa + 3), c
	ld xwa, (xsp + 10)
	ld (xwa + 4), l
	jr NoteMap_EncodeExtControlChange

RhythmParse_CheckAccType:
	cp_erpb 0xf8, 0x94
	jr c, NoteMap_CheckEndMarker
	cp_erpb 0xf8, 0x98
	jr ugt, NoteMap_CheckEndMarker
	ld wa, (xsp + 4)
	cps a, 0
	jr z, NoteMap_CheckEndMarker
	cp_erpb 0xf8, 0x98
	jr nz, NoteMap_ProcessMergeAlloc
	ld wa, (xsp + 4)
	cp a, 0x7d
	jr c, NoteMap_ProcessMergeAlloc
	ld wa, (xsp + 4)
	cp a, 0x7f
	jr ugt, NoteMap_ProcessMergeAlloc
	ld wa, (xsp + 4)
	extz wa
	ld c, l
	extz bc
	call Rhythm_DispatchCCCommand
	jr NoteMap_CheckEndMarker

NoteMap_ProcessMergeAlloc:
	cpw (xsp + 2), 0x0
	jr nz, RhythmParse_AppendNoteEntry
	ld xwa, (xsp + 10)
	ld (xwa), 0x90
	ldto_berp A, 0xf8
	and a, 0xf
	dec 4, a
	ld c, a
	ld xwa, (xsp + 10)
	ld (xwa + 1), c
	ld xwa, (xsp + 6)
	ld (xwa), 0x90
	ld xwa, (xsp + 6)
	ld (xwa + 2), 0x4
	ldto_berp A, 0xf8
	and a, 0xf
	dec 4, a
	ld c, a
	ld xwa, (xsp + 6)
	ld (xwa + 3), c
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	ld (xbc + 4), 0x0
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	ld wa, (xsp + 4)
	ld (xbc), a
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	ld (xbc + 1), l
	incm 1, (xsp + 2)
	jrl NoteMap_CheckEndMarker

RhythmParse_AppendNoteEntry:
	ldto_berp A, 0xf8
	and a, 0xf
	dec 4, a
	ld c, a
	ld xwa, (xsp + 10)
	cp c, (xwa + 1)
	jr nz, AppendNoteEntry_LoadParam
	ld xwa, (xsp + 10)
	cp (xwa), 0xb0
	jr z, AppendNoteEntry_LoadParam
	cpw (xsp + 2), 0x20
	jr nc, AppendNoteEntry_AdvanceSlot
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	ld (xbc + 4), 0x0
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	ld wa, (xsp + 4)
	ld (xbc), a
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	ld (xbc + 1), l

AppendNoteEntry_AdvanceSlot:
	incm 1, (xsp + 2)
	jrl NoteMap_CheckEndMarker

AppendNoteEntry_LoadParam:
	ld xwa, (xsp + 10)
	ld (xwa), 0x90
	ldto_berp A, 0xf8
	and a, 0xf
	dec 4, a
	ld c, a
	ld xwa, (xsp + 10)
	ld (xwa + 1), c
	ld wa, (xsp + 4)
	ld c, a
	ld xwa, (xsp + 10)
	ld (xwa + 3), c
	ld xwa, (xsp + 10)
	ld (xwa + 4), l
	jrl NoteMap_EncodeExtControlChange

RhythmParse_TruncateCount:
	call Voice_InitTableGroup
	ld xwa, (xsp + 6)
	ld (xwa + 1), 0x0
	ldb l, 0x0

RhythmParse_StoreCountAndReturn:
	popw iz
	lda xsp, (xsp + 12)
	ret

SeqEvtBuf_ParseEventLoop:
	lda xsp, (xsp - 12)
	pushw iz
	ld (xsp + 6), xbc
	ld (xsp + 10), xwa
	ldw (xsp + 2), 0x0
	ld xwa, (xsp + 10)
	ld a, (xwa)
	cp a, 0xff
	jrl z, NoteMap_EncodeControlChange
	cps a, 0
	jr z, ParseEventLoop_LoadParam
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 6)
	ld a, (xwa)
	ld (xbc), a
	ld xwa, (xsp + 6)
	ld (xwa + 2), 0x5
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 6)
	ld a, (xwa + 1)
	ld (xbc + 3), a
	ld xwa, (xsp + 6)
	ld (xwa + 8), 0x0
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 6)
	ld a, (xwa + 3)
	ld (xbc + 4), a
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 6)
	ld a, (xwa + 4)
	ld (xbc + 5), a
	incm 1, (xsp + 2)

ParseEventLoop_LoadParam:
	ld xwa, (xsp + 10)
	cp (xwa), 0xff
	jrl z, NoteMap_EncodeControlChange

ParseEventLoop_ReadAlt:
	call SeqEvtBuf_ReadAlternate
	ld iz, hl
	ld wa, iz
	cp wa, 0xffff
	jr nz, ParseEventLoop_ReadAlt2
	ld xwa, (xsp + 10)
	ld (xwa), 0xff
	jr NoteMap_EncodeControlChange

ParseEventLoop_ReadAlt2:
	call SeqEvtBuf_ReadAlternate
	ld (xsp + 4), hl
	ld wa, (xsp + 4)
	cp wa, 0xffff
	jr nz, ParseEventLoop_ReadAlt3
	ld xwa, (xsp + 10)
	ld (xwa), 0xff
	jr NoteMap_EncodeControlChange

ParseEventLoop_ReadAlt3:
	call SeqEvtBuf_ReadAlternate
	ld wa, hl
	cp wa, 0xffff
	jr nz, ParseEventLoop_CheckIdx
	ld xwa, (xsp + 10)
	ld (xwa), 0xff
	jr NoteMap_EncodeControlChange

ParseEventLoop_CheckIdx:
	cp_erpb 0xf8, 0x90
	jr nz, EncodeControlChange_CheckIdx
	ld wa, (xsp + 4)
	cp a, 0x7f
	jr nz, NoteMap_EncodeCC_Recheck
	cpw (xsp + 2), 0x0
	jr nz, EncodeControlChange_LoadParam
	ld xwa, (xsp + 10)
	ld (xwa), 0xb0
	ld c, l
	ld xwa, (xsp + 10)
	ld (xwa + 1), c
	ld xwa, (xsp + 6)
	ld (xwa), 0xb0
	ld xwa, (xsp + 6)
	ld (xwa + 2), 0x5
	ld xwa, (xsp + 6)
	ld (xwa + 3), l
	incm 1, (xsp + 2)

NoteMap_EncodeCC_Recheck:
	ld xwa, (xsp + 10)
	cp (xwa), 0xff
	jrl nz, ParseEventLoop_ReadAlt

NoteMap_EncodeControlChange:
	cpw (xsp + 2), 0x20
	jrl ugt, EncodeControlChange_DoInit
	ld wa, (xsp + 2)
	ld l, a
	ld xwa, (xsp + 6)
	ld (xwa + 1), l
	jrl EncodeControlChange_RestoreReg

EncodeControlChange_LoadParam:
	ld xwa, (xsp + 10)
	ld (xwa), 0xb0
	ld c, l
	ld xwa, (xsp + 10)
	ld (xwa + 1), c
	ld wa, (xsp + 4)
	ld c, a
	ld xwa, (xsp + 10)
	ld (xwa + 3), c
	ld xwa, (xsp + 10)
	ld (xwa + 4), l
	jr NoteMap_EncodeControlChange

EncodeControlChange_CheckIdx:
	cp_erpb 0xf8, 0x91
	jr c, NoteMap_EncodeCC_Recheck
	cp_erpb 0xf8, 0x92
	jr ugt, NoteMap_EncodeCC_Recheck
	ld wa, (xsp + 4)
	cps a, 0
	jr z, NoteMap_EncodeCC_Recheck
	cpw (xsp + 2), 0x0
	jr nz, EncodeControlChange_LoadIdx
	ld xwa, (xsp + 10)
	ld (xwa), 0x90
	ldto_berp A, 0xf8
	and a, 0xf
	dec 1, a
	ld c, a
	ld xwa, (xsp + 10)
	ld (xwa + 1), c
	ld xwa, (xsp + 6)
	ld (xwa), 0x90
	ld xwa, (xsp + 6)
	ld (xwa + 2), 0x5
	ldto_berp A, 0xf8
	and a, 0xf
	dec 1, a
	ld c, a
	ld xwa, (xsp + 6)
	ld (xwa + 3), c
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	ld (xbc + 4), 0x0
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	ld wa, (xsp + 4)
	ld (xbc), a
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	ld (xbc + 1), l
	incm 1, (xsp + 2)
	jrl NoteMap_EncodeCC_Recheck

EncodeControlChange_LoadIdx:
	ldto_berp A, 0xf8
	and a, 0xf
	dec 1, a
	ld c, a
	ld xwa, (xsp + 10)
	cp c, (xwa + 1)
	jr nz, EncodeControlChange_LoadParam2
	ld xwa, (xsp + 10)
	cp (xwa), 0xb0
	jr z, EncodeControlChange_LoadParam2
	cpw (xsp + 2), 0x20
	jr nc, EncodeControlChange_AdvanceSlot
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	ld (xbc + 4), 0x0
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	ld wa, (xsp + 4)
	ld (xbc), a
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	ld (xbc + 1), l

EncodeControlChange_AdvanceSlot:
	incm 1, (xsp + 2)
	jrl NoteMap_EncodeCC_Recheck

EncodeControlChange_LoadParam2:
	ld xwa, (xsp + 10)
	ld (xwa), 0x90
	ldto_berp A, 0xf8
	and a, 0xf
	dec 1, a
	ld c, a
	ld xwa, (xsp + 10)
	ld (xwa + 1), c
	ld wa, (xsp + 4)
	ld c, a
	ld xwa, (xsp + 10)
	ld (xwa + 3), c
	ld xwa, (xsp + 10)
	ld (xwa + 4), l
	jrl NoteMap_EncodeControlChange

EncodeControlChange_DoInit:
	call Voice_InitTablePair
	ld xwa, (xsp + 6)
	ld (xwa + 1), 0x0
	ldb l, 0x0

EncodeControlChange_RestoreReg:
	popw iz
	lda xsp, (xsp + 12)
	ret

; ============================================================================
; NoteMap_AddEntry - Add a new entry to the note allocation map
; ============================================================================
; Input:  E = channel (must be 0x15 to proceed)
;         XBC = note parameters
;         XWA = note map base pointer
; Output: None (updates note map in place)
; Allocates voice resources for a new note by calling NoteMap_AllocateVoice
; up to 3 times (for layers 0, 1, and optionally 2). Uses NoteMap_FindEntry
; to check for existing entries and NoteMap_FindBestMatch for voice stealing.
; ============================================================================
NoteMap_AddEntry:
	lda xsp, (xsp - 10)
	push_werp 0xfa
	ld (xsp + 2), e
	ld (xsp + 4), xbc
	ld (xsp + 8), xwa
	cp (xsp + 2), 0x15
	jrl nz, AltCheckEmit_LoadParam2
	ld a, (xsp + 2)
	ld e, a
	extz de
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	call NoteMap_ResetEntryTimers
	ld xwa, (xsp + 8)
	lds bc, 0
	call NoteMap_FindEntry
	ld xwa, (xsp + 8)
	call NoteMap_FindBestVoiceSlot
	cps l, 0
	jr nz, NoteMap_AltCheckEmit
	ld xwa, (xsp + 4)
	lds bc, 0
	calr NoteMap_AllocateVoice
	ld xwa, (xsp + 4)
	lds bc, 1
	calr NoteMap_AllocateVoice
	cpdi16 52770, 0
	jr z, NoteMap_AltCheckEmit
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_AltCheckEmit
	ld xwa, (xsp + 4)
	lds bc, 2
	calr NoteMap_AllocateVoice

NoteMap_AltCheckEmit:
	ldda16 xwa, 50584
	bit 9, wa
	jr z, AltCheckEmit_LoadParam
	ldi_berp 0xfb, 0
	cp_erpb 0xfb, 0x10
	jr nc, AltCheckEmit_LoadParam

AltCheckEmit_LoopBody:
	ldto_berp A, 0xfb
	extz wa
	add wa, 0x84
	extz xwa
	add xwa, (xsp + 4)
	cp (xwa), 0x15
	jr nz, AltCheckEmit_LoopCheck
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call Voice_BuildAndEmitNoteOnEvents

AltCheckEmit_LoopCheck:
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, AltCheckEmit_LoopBody

AltCheckEmit_LoadParam:
	ld xwa, (xsp + 4)
	cp (xwa + 3), 0x0
	jrl nz, NoteMap_AllocCheckNoteOn
	ld xwa, (xsp + 8)
	lds bc, 1
	call NoteMap_EmitNoteOnEvents
	jrl NoteMap_AllocCheckNoteOn

AltCheckEmit_LoadParam2:
	ld xwa, (xsp + 4)
	ld c, (xsp + 2)
	cp_srib_rm C, 0xe1, 0xb6, 0x00
	jr nz, NoteMap_AllocCheckChannel
	ld a, (xsp + 2)
	ld e, a
	extz de
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	call NoteMap_ResetEntryTimers
	ld xwa, (xsp + 8)
	lds bc, 2
	call NoteMap_FindEntry
	ld xwa, (xsp + 8)
	call NoteMap_FindBestFreeVoice
	cps l, 0
	jr nz, NoteMap_AllocCheckChannel
	call VoiceMap_AllocateSlot
	cp l, 0xff
	jr z, NoteMap_AllocCheckChannel
	ld xwa, (xsp + 4)
	lds bc, 2
	calr NoteMap_AssignVoiceParams
	ld xwa, (xsp + 4)
	lds bc, 2
	calr NoteMap_InitVoiceSlots

NoteMap_AllocCheckChannel:
	ld a, (xsp + 2)
	ld e, a
	extz de
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	call NoteMap_ResetEntryTimers
	ld a, (xsp + 2)
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call NoteMap_AllocNewVoiceEntry
	ld a, (xsp + 2)
	extz wa
	inc 4, wa
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	cp a, (xsp + 2)
	jr nz, AllocCheckChannel_LoadParam
	ld a, (xsp + 2)
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call NoteMap_SetChannelParam

AllocCheckChannel_LoadParam:
	ld a, (xsp + 2)
	extz wa
	add wa, 0x24
	extz xwa
	add xwa, (xsp + 4)
	ld e, (xwa)
	ld a, e
	cp a, 0xff
	jr z, AllocCheckChannel_LoadDRAM
	ld a, (xsp + 2)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld xwa, (xsp + 4)
	bit_dri 5, 0x07, 0xe0, 0xe4
	jr z, AllocCheckChannel_LoadDRAM
	ld c, e
	extz bc
	ld xwa, (xsp + 8)
	call Voice_ScanAndEmitMidiEvents

AllocCheckChannel_LoadDRAM:
	ldda16 xwa, 50584
	bit 9, wa
	jr z, AllocCheckChannel_LoadParam2
	ldi_berp 0xfb, 0
	cp_erpb 0xfb, 0x10
	jr nc, AllocCheckChannel_LoadParam2

AllocCheckChannel_LoopBody:
	ldto_berp A, 0xfb
	extz wa
	add wa, 0x84
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	cp a, (xsp + 2)
	jr nz, AllocCheckChannel_LoopCheck
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call Voice_BuildAndEmitNoteOnEvents

AllocCheckChannel_LoopCheck:
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, AllocCheckChannel_LoopBody

AllocCheckChannel_LoadParam2:
	ld a, (xsp + 2)
	extz wa
	add wa, 0x44
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	ldfr_berp A, 0xfb
	cp a, 0xff
	jr z, AllocCheckChannel_LoadParam3
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call SeqPart_EmitNoteOnMessages

AllocCheckChannel_LoadParam3:
	ld a, (xsp + 2)
	extz wa
	add wa, 0x64
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	ldfr_berp A, 0xfb
	cp a, 0xff
	jr z, AllocCheckChannel_LoadParam4
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call Voice_EmitMidiNoteOnEvents

AllocCheckChannel_LoadParam4:
	ld xwa, (xsp + 4)
	ld a, (xwa + 2)
	cp a, (xsp + 2)
	jr nz, NoteMap_AllocCheckNoteOn
	ld xwa, (xsp + 8)
	lds bc, 0
	call NoteMap_EmitNoteOnEvents

NoteMap_AllocCheckNoteOn:
	pop_werp 0xfa
	lda xsp, (xsp + 10)
	ret

AllocCheckNoteOn_Data:
	lda	xsp, (xsp-10)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+2), e
	ld	(xsp+4), xbc
	ld	(xsp+8), xwa
	.byte 0x8f
	push_sr
	push	xsp
	pop_a
	jr	nz, 126
	ld	xwa, (xsp+8)
	lds	bc, 0
	call	NoteMap_FindEntry
	ld	xwa, (xsp+8)
	call	NoteMap_FindBestVoiceSlot
	cps	l, 0
	jr	nz, 41
	ld	xwa, (xsp+4)
	lds	bc, 0
	calr	5082
	ld	xwa, (xsp+4)
	lds	bc, 1
	calr	5074
	.byte 0xd1
	ldb	b, 206
	push	xsp
	nop
	nop
	jr	z, 17
	call	NoteMap_FindBestMatch
	cp	l, 255
	jr	z, 8
	ld	xwa, (xsp+4)
	lds	bc, 2
	calr	5049
	ldda16	wa, 50584
	bit	9, wa
	jrl	z, 355
	.byte 0xc7
	swi	3
	cp	(xwa-57), xhl
	.byte 0xcf
	rcf
	jrl	nc, 345
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	add	wa, 132
	extz	xwa
	.byte 0xaf, 0x04, 0x80, 0x80
	push	xsp
	pop_a
	jr	nz, 14
	.byte 0xc7
	swi	3
	add	(xbc-55), c
	extz	bc
	ld	xwa, (xsp+8)
	call	Voice_BuildAndEmitNoteOnEvents
	.byte 0xc7
	swi	3
	jr	lt, -57
	swi	3
	.byte 0xcf
	rcf
	jr	c, -42
	jrl	300
	ld	xwa, (xsp+4)
	ld	c, (xsp+2)
	cp	c, (xwa+182)
	jr	nz, 45
	ld	xwa, (xsp+8)
	lds	bc, 2
	call	NoteMap_FindEntry
	ld	xwa, (xsp+8)
	call	NoteMap_FindBestFreeVoice
	cps	l, 0
	jr	nz, 25
	call	VoiceMap_AllocateSlot
	cp	l, 255
	jr	z, 16
	ld	xwa, (xsp+4)
	lds	bc, 2
	calr	4654
	ld	xwa, (xsp+4)
	lds	bc, 2
	calr	4271
	ld	a, (xsp+2)
	ld	c, a
	extz	bc
	ld	xwa, (xsp+8)
	call	NoteMap_AllocNewVoiceEntry
	ld	a, (xsp+2)
	extz	wa
	inc	4, wa
	extz	xwa
	.byte 0xaf, 0x04, 0x80
	ld	a, (xwa)
	.byte 0x8f
	push_sr
	.byte 0xf1
	jr	nz, 14
	ld	a, (xsp+2)
	ld	c, a
	extz	bc
	ld	xwa, (xsp+8)
	call	NoteMap_SetChannelParam
	ld	a, (xsp+2)
	extz	wa
	add	wa, 36
	extz	xwa
	.byte 0xaf, 0x04, 0x80
	ld	e, (xwa)
	ld	a, e
	cp	a, 255
	jr	z, 34
	ld	a, (xsp+2)
	extz	wa
	add	wa, wa
	ld	bc, wa
	add	bc, 292
	ld	xwa, (xsp+4)
	.byte 0xf3
	reti
	.byte 0xe0, 0xe4
	inc	6, e
	pushw	35789
	extz	bc
	ld	xwa, (xsp+8)
	call	Voice_ScanAndEmitMidiEvents
	ldda16	wa, 50584
	bit	9, wa
	jr	z, 53
	.byte 0xc7
	swi	3
	cp	(xwa-57), xhl
	.byte 0xcf
	rcf
	jr	nc, 44
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	add	wa, 132
	extz	xwa
	.byte 0xaf, 0x04, 0x80
	ld	a, (xwa)
	.byte 0x8f
	push_sr
	.byte 0xf1
	jr	nz, 14
	.byte 0xc7
	swi	3
	add	(xbc-55), c
	extz	bc
	ld	xwa, (xsp+8)
	call	Voice_BuildAndEmitNoteOnEvents
	.byte 0xc7
	swi	3
	jr	lt, -57
	swi	3
	.byte 0xcf
	rcf
	jr	c, -44
	ld	a, (xsp+2)
	extz	wa
	add	wa, 68
	extz	xwa
	.byte 0xaf, 0x04, 0x80
	ld	a, (xwa)
	.byte 0xc7
	swi	3
	.byte 0x99
	cp	a, 255
	jr	z, 14
	.byte 0xc7
	swi	3
	add	(xbc-55), c
	extz	bc
	ld	xwa, (xsp+8)
	call	SeqPart_EmitNoteOnMessages
	ld	a, (xsp+2)
	extz	wa
	add	wa, 100
	extz	xwa
	.byte 0xaf, 0x04, 0x80
	ld	a, (xwa)
	.byte 0xc7
	swi	3
	.byte 0x99
	cp	a, 255
	jr	z, 14
	.byte 0xc7
	swi	3
	add	(xbc-55), c
	extz	bc
	ld	xwa, (xsp+8)
	call	Voice_EmitMidiNoteOnEvents
	.byte 0xd7
	swi	2
	halt
	lda	xsp, (xsp+10)
	ret

NoteMap_CollectAndFindBestVoice:
	st_dri3b L, 0xfd, 0x52, 0xff
	push_werp 0xfa
	lda_dri3 XIY, 0xfd, 0xa6, 0x00
	st_dri3l XBC, 0xfd, 0xa8, 0x00
	st_dri3l XWA, 0xfd, 0xac, 0x00
	cp_srib_im 0xfd, 0xa6, 0x00, 0x15
	jrl nz, CollectBestVoice_NonSpecialPath
	lda xwa, (xsp + 2)
	pushw 0x0
	ld_sril XBC, (xsp + 0x00ae)
	lds de, 4
	call NoteMap_CollectMatchingEntries
	cps l, 0
	jrl z, NoteMap_PopRetFA_StoreAE
	ld_srib A, (xsp + 0x00a6)
	ld e, a
	extz de
	ld_sril XWA, (xsp + 0x00ac)
	ld_sril XBC, (xsp + 0x00a8)
	call NoteMap_ResetEntryTimers
	lda xwa, (xsp + 2)
	lds bc, 0
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestVoiceSlot
	cps l, 0
	jr nz, NoteMap_AltAllocEmit
	ld_sril XWA, (xsp + 0x00a8)
	lds bc, 0
	calr NoteMap_AllocateVoice
	ld_sril XWA, (xsp + 0x00a8)
	lds bc, 1
	calr NoteMap_AllocateVoice
	cpdi16 52770, 0
	jr z, NoteMap_AltAllocEmit
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_AltAllocEmit
	ld_sril XWA, (xsp + 0x00a8)
	lds bc, 2
	calr NoteMap_AllocateVoice

NoteMap_AltAllocEmit:
	ldda16 xwa, 50584
	bit 9, wa
	jrl z, NoteMap_PopRetFA_StoreAE
	ldi_berp 0xfb, 0
	cp_erpb 0xfb, 0x10
	jrl nc, NoteMap_PopRetFA_StoreAE

CollectBestVoice_EmitLoop:
	ldto_berp A, 0xfb
	extz wa
	add wa, 0x84
	extz xwa
	add_sril_rm XWA, 0xfd, 0xa8, 0x00
	cp (xwa), 0x15
	jr nz, CollectBestVoice_EmitNext
	lda xwa, (xsp + 2)
	ld xde, xwa
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

CollectBestVoice_EmitNext:
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, CollectBestVoice_EmitLoop
	jrl NoteMap_PopRetFA_StoreAE

CollectBestVoice_NonSpecialPath:
	ld_sril XWA, (xsp + 0x00a8)
	ld_srib C, (xsp + 0x00a6)
	cp_srib_rm C, 0xe1, 0xb6, 0x00
	jr nz, NoteMap_CollectAndAllocVoice
	lda xwa, (xsp + 2)
	pushw 0x2
	ld_sril XBC, (xsp + 0x00ae)
	lds de, 4
	call NoteMap_CollectMatchingEntries
	cps l, 0
	jr z, NoteMap_CollectAndAllocVoice
	ld_srib A, (xsp + 0x00a6)
	ld e, a
	extz de
	ld_sril XWA, (xsp + 0x00ac)
	ld_sril XBC, (xsp + 0x00a8)
	call NoteMap_ResetEntryTimers
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	cps l, 0
	jr nz, NoteMap_CollectAndAllocVoice
	call VoiceMap_AllocateSlot
	cp l, 0xff
	jr z, NoteMap_CollectAndAllocVoice
	ld_sril XWA, (xsp + 0x00a8)
	lds bc, 2
	calr NoteMap_AssignVoiceParams
	ld_sril XWA, (xsp + 0x00a8)
	lds bc, 2
	calr NoteMap_InitVoiceSlots

NoteMap_CollectAndAllocVoice:
	lda xwa, (xsp + 2)
	ld xbc, xwa
	ld_srib A, (xsp + 0x00a6)
	extz wa
	pushw wa
	ld xwa, xbc
	ld_sril XBC, (xsp + 0x00ae)
	lds de, 0
	call NoteMap_CollectMatchingEntries
	cps l, 0
	jrl z, NoteMap_PopRetFA_StoreAE
	lda xwa, (xsp + 2)
	ld xbc, xwa
	ld_srib A, (xsp + 0x00a6)
	ld e, a
	extz de
	ld xwa, xbc
	ld_sril XBC, (xsp + 0x00a8)
	call NoteMap_ResetEntryTimers
	lda xwa, (xsp + 2)
	ld xde, xwa
	ld_srib A, (xsp + 0x00a6)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocNewVoiceEntry
	ld_srib A, (xsp + 0x00a6)
	extz wa
	inc 4, wa
	extz xwa
	add_sril_rm XWA, 0xfd, 0xa8, 0x00
	ld a, (xwa)
	cp_srib_rm A, 0xfd, 0xa6, 0x00
	jr nz, CollectAllocVoice_CheckDuplicate
	lda xwa, (xsp + 2)
	ld xde, xwa
	ld_srib A, (xsp + 0x00a6)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

CollectAllocVoice_CheckDuplicate:
	ld_srib A, (xsp + 0x00a6)
	extz wa
	add wa, 0x24
	extz xwa
	add_sril_rm XWA, 0xfd, 0xa8, 0x00
	ld e, (xwa)
	ld a, e
	cp a, 0xff
	jr z, CollectAllocVoice_EmitCheck
	ld_srib A, (xsp + 0x00a6)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld_sril XWA, (xsp + 0x00a8)
	bit_dri 5, 0x07, 0xe0, 0xe4
	jr z, CollectAllocVoice_EmitCheck
	lda xwa, (xsp + 2)
	ld c, e
	extz bc
	call Voice_ScanAndEmitMidiEvents

CollectAllocVoice_EmitCheck:
	ldda16 xwa, 50584
	bit 9, wa
	jr z, CollectAllocVoice_Em_LoadFromStack
	ldi_berp 0xfb, 0
	cp_erpb 0xfb, 0x10
	jr nc, CollectAllocVoice_Em_LoadFromStack

CollectAllocVoice_EmitLoop:
	ldto_berp A, 0xfb
	extz wa
	add wa, 0x84
	extz xwa
	add_sril_rm XWA, 0xfd, 0xa8, 0x00
	ld a, (xwa)
	cp_srib_rm A, 0xfd, 0xa6, 0x00
	jr nz, CollectAllocVoice_Em_Block
	lda xwa, (xsp + 2)
	ld xde, xwa
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

CollectAllocVoice_Em_Block:
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, CollectAllocVoice_EmitLoop

CollectAllocVoice_Em_LoadFromStack:
	ld_srib A, (xsp + 0x00a6)
	extz wa
	add wa, 0x44
	extz xwa
	add_sril_rm XWA, 0xfd, 0xa8, 0x00
	ld a, (xwa)
	ldfr_berp A, 0xfb
	cp a, 0xff
	jr z, CollectAllocVoice_Em_LoadFromStack2
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld_sril XWA, (xsp + 0x00ac)
	call SeqPart_EmitNoteOnMessages

CollectAllocVoice_Em_LoadFromStack2:
	ld_srib A, (xsp + 0x00a6)
	extz wa
	add wa, 0x64
	extz xwa
	add_sril_rm XWA, 0xfd, 0xa8, 0x00
	ld a, (xwa)
	ldfr_berp A, 0xfb
	cp a, 0xff
	jr z, NoteMap_PopRetFA_StoreAE
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld_sril XWA, (xsp + 0x00ac)
	call Voice_EmitMidiNoteOnEvents

NoteMap_PopRetFA_StoreAE:
	pop_werp 0xfa
	st_dri3b L, 0xfd, 0xae, 0x00
	ret

NoteMap_CollectAndAllocVoice_NoTimerCheck:
	lda xsp, (xsp - 10)
	push_werp 0xfa
	ld (xsp + 2), e
	ld (xsp + 4), xbc
	ld (xsp + 8), xwa
	cp (xsp + 2), 0x15
	jrl nz, FallbackVoiceCheck_LoadParam2
	ld xwa, (xsp + 8)
	lds bc, 0
	call NoteMap_FindEntry
	ld xwa, (xsp + 8)
	call NoteMap_FindBestVoiceSlot
	cps l, 1
	jr nz, NoteMap_FallbackVoiceCheck
	ld xwa, (xsp + 4)
	lds bc, 0
	calr NoteMap_AllocateVoice
	ld xwa, (xsp + 4)
	lds bc, 1
	calr NoteMap_AllocateVoice
	cpdi16 52770, 0
	jr z, NoteMap_FallbackVoiceCheck
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_FallbackVoiceCheck
	ld xwa, (xsp + 4)
	lds bc, 2
	calr NoteMap_AllocateVoice

NoteMap_FallbackVoiceCheck:
	ldda16 xwa, 50584
	bit 9, wa
	jr z, FallbackVoiceCheck_LoadParam
	ldi_berp 0xfb, 0
	cp_erpb 0xfb, 0x10
	jr nc, FallbackVoiceCheck_LoadParam

FallbackVoiceCheck_LoopBody:
	ldto_berp A, 0xfb
	extz wa
	add wa, 0x84
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	cp a, (xsp + 2)
	jr nz, FallbackVoiceCheck_LoopCheck
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call Voice_BuildAndEmitNoteOnEvents

FallbackVoiceCheck_LoopCheck:
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, FallbackVoiceCheck_LoopBody

FallbackVoiceCheck_LoadParam:
	ld xwa, (xsp + 4)
	cp (xwa + 3), 0x0
	jrl nz, NoteMap_AllocVoiceEmit
	ld xwa, (xsp + 8)
	lds bc, 1
	call NoteMap_EmitNoteOnEvents
	jrl NoteMap_AllocVoiceEmit

FallbackVoiceCheck_LoadParam2:
	ld xwa, (xsp + 4)
	ld c, (xsp + 2)
	cp_srib_rm C, 0xe1, 0xb6, 0x00
	jr nz, NoteMap_LookupAllocEmit
	ld xwa, (xsp + 8)
	lds bc, 2
	call NoteMap_FindEntry
	ld xwa, (xsp + 8)
	call NoteMap_FindBestFreeVoice
	cps l, 1
	jr nz, NoteMap_LookupAllocEmit
	call VoiceMap_AllocateSlot
	cp l, 0xff
	jr z, NoteMap_LookupAllocEmit
	ld xwa, (xsp + 4)
	lds bc, 2
	calr NoteMap_AssignVoiceParams
	ld xwa, (xsp + 4)
	lds bc, 2
	calr NoteMap_InitVoiceSlots

NoteMap_LookupAllocEmit:
	ld a, (xsp + 2)
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call NoteMap_AllocNewVoiceEntry
	ld a, (xsp + 2)
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call NoteMap_SetChannelParam
	ldda16 xwa, 50584
	bit 9, wa
	jr z, LookupAllocEmit_LoadParam
	ldi_berp 0xfb, 0
	cp_erpb 0xfb, 0x10
	jr nc, LookupAllocEmit_LoadParam

LookupAllocEmit_LoopBody:
	ldto_berp A, 0xfb
	extz wa
	add wa, 0x84
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	cp a, (xsp + 2)
	jr nz, LookupAllocEmit_LoopCheck
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call Voice_BuildAndEmitNoteOnEvents

LookupAllocEmit_LoopCheck:
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, LookupAllocEmit_LoopBody

LookupAllocEmit_LoadParam:
	ld a, (xsp + 2)
	extz wa
	add wa, 0x44
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	ldfr_berp A, 0xfb
	cp a, 0xff
	jr z, LookupAllocEmit_LoadParam2
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call SeqPart_EmitNoteOnMessages

LookupAllocEmit_LoadParam2:
	ld a, (xsp + 2)
	extz wa
	add wa, 0x64
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	ldfr_berp A, 0xfb
	cp a, 0xff
	jr z, LookupAllocEmit_LoadParam3
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call Voice_EmitMidiNoteOnEvents

LookupAllocEmit_LoadParam3:
	ld xwa, (xsp + 4)
	cp (xwa + 3), 0x0
	jr nz, NoteMap_AllocVoiceEmit
	ld xwa, (xsp + 8)
	lds bc, 0
	call NoteMap_EmitNoteOnEvents

NoteMap_AllocVoiceEmit:
	pop_werp 0xfa
	lda xsp, (xsp + 10)
	ret

NoteMap_CollectAndAllocVoice_Indirect:
	st_dri3b L, 0xfd, 0x52, 0xff
	push_werp 0xfa
	lda_dri3 XIY, 0xfd, 0xa6, 0x00
	st_dri3l XBC, 0xfd, 0xa8, 0x00
	st_dri3l XWA, 0xfd, 0xac, 0x00
	cp_srib_im 0xfd, 0xa6, 0x00, 0x15
	jrl nz, IndirectCollectEmit_LoadFromStack
	lda xwa, (xsp + 2)
	pushw 0x0
	ld_sril XBC, (xsp + 0x00ae)
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jrl z, NoteMap_PopRetFA_StoreAE2
	lda xwa, (xsp + 2)
	lds bc, 0
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestVoiceSlot
	cps l, 1
	jr nz, NoteMap_IndirectCollectEmit
	ld_sril XWA, (xsp + 0x00a8)
	lds bc, 0
	calr NoteMap_AllocateVoice
	ld_sril XWA, (xsp + 0x00a8)
	lds bc, 1
	calr NoteMap_AllocateVoice
	cpdi16 52770, 0
	jr z, NoteMap_IndirectCollectEmit
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_IndirectCollectEmit
	ld_sril XWA, (xsp + 0x00a8)
	lds bc, 2
	calr NoteMap_AllocateVoice

NoteMap_IndirectCollectEmit:
	ldda16 xwa, 50584
	bit 9, wa
	jrl z, NoteMap_PopRetFA_StoreAE2
	ldi_berp 0xfb, 0
	cp_erpb 0xfb, 0x10
	jrl nc, NoteMap_PopRetFA_StoreAE2

IndirectCollectEmit_LoopBody:
	ldto_berp A, 0xfb
	extz wa
	add wa, 0x84
	extz xwa
	add_sril_rm XWA, 0xfd, 0xa8, 0x00
	ld a, (xwa)
	cp_srib_rm A, 0xfd, 0xa6, 0x00
	jr nz, IndirectCollectEmit_LoopCheck
	lda xwa, (xsp + 2)
	ld xde, xwa
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

IndirectCollectEmit_LoopCheck:
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, IndirectCollectEmit_LoopBody
	jrl NoteMap_PopRetFA_StoreAE2

IndirectCollectEmit_LoadFromStack:
	ld_sril XWA, (xsp + 0x00a8)
	ld_srib C, (xsp + 0x00a6)
	cp_srib_rm C, 0xe1, 0xb6, 0x00
	jr nz, NoteMap_LookupAllocAndSetChannel
	lda xwa, (xsp + 2)
	pushw 0x2
	ld_sril XBC, (xsp + 0x00ae)
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jr z, NoteMap_LookupAllocAndSetChannel
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	cps l, 1
	jr nz, NoteMap_LookupAllocAndSetChannel
	call VoiceMap_AllocateSlot
	cp l, 0xff
	jr z, NoteMap_LookupAllocAndSetChannel
	ld_sril XWA, (xsp + 0x00a8)
	lds bc, 2
	calr NoteMap_AssignVoiceParams
	ld_sril XWA, (xsp + 0x00a8)
	lds bc, 2
	calr NoteMap_InitVoiceSlots

NoteMap_LookupAllocAndSetChannel:
	lda xwa, (xsp + 2)
	ld xbc, xwa
	ld_srib A, (xsp + 0x00a6)
	extz wa
	pushw wa
	ld xwa, xbc
	ld_sril XBC, (xsp + 0x00ae)
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jrl z, NoteMap_PopRetFA_StoreAE2
	lda xwa, (xsp + 2)
	ld xde, xwa
	ld_srib A, (xsp + 0x00a6)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocNewVoiceEntry
	lda xwa, (xsp + 2)
	ld xde, xwa
	ld_srib A, (xsp + 0x00a6)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	ldda16 xwa, 50584
	bit 9, wa
	jr z, LookupAllocAndSetCha_LoadFromStack
	ldi_berp 0xfb, 0
	cp_erpb 0xfb, 0x10
	jr nc, LookupAllocAndSetCha_LoadFromStack

LookupAllocAndSetCha_LoopBody:
	ldto_berp A, 0xfb
	extz wa
	add wa, 0x84
	extz xwa
	add_sril_rm XWA, 0xfd, 0xa8, 0x00
	ld a, (xwa)
	cp_srib_rm A, 0xfd, 0xa6, 0x00
	jr nz, LookupAllocAndSetCha_LoopCheck
	lda xwa, (xsp + 2)
	ld xde, xwa
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

LookupAllocAndSetCha_LoopCheck:
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, LookupAllocAndSetCha_LoopBody

LookupAllocAndSetCha_LoadFromStack:
	ld_srib A, (xsp + 0x00a6)
	extz wa
	add wa, 0x44
	extz xwa
	add_sril_rm XWA, 0xfd, 0xa8, 0x00
	ld a, (xwa)
	ldfr_berp A, 0xfb
	cp a, 0xff
	jr z, LookupAllocAndSetCha_LoadFromStack2
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld_sril XWA, (xsp + 0x00ac)
	call SeqPart_EmitNoteOnMessages

LookupAllocAndSetCha_LoadFromStack2:
	ld_srib A, (xsp + 0x00a6)
	extz wa
	add wa, 0x64
	extz xwa
	add_sril_rm XWA, 0xfd, 0xa8, 0x00
	ld a, (xwa)
	ldfr_berp A, 0xfb
	cp a, 0xff
	jr z, NoteMap_PopRetFA_StoreAE2
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld_sril XWA, (xsp + 0x00ac)
	call Voice_EmitMidiNoteOnEvents

NoteMap_PopRetFA_StoreAE2:
	pop_werp 0xfa
	st_dri3b L, 0xfd, 0xae, 0x00
	ret

NoteMap_UpdateEntry:
	lda xsp, (xsp - 10)
	push_werp 0xfa
	ld (xsp + 2), e
	ld (xsp + 4), xbc
	ld (xsp + 8), xwa
	cp (xsp + 2), 0x15
	jrl nz, UpdateEntry_NonSpecialPath
	ld xwa, (xsp + 8)
	lds bc, 0
	call NoteMap_FindEntry
	ld xwa, (xsp + 8)
	call NoteMap_FindBestVoiceSlot
	cps l, 0
	jr nz, NoteMap_FallbackAllocEmit
	ld xwa, (xsp + 4)
	lds bc, 0
	calr NoteMap_AllocateVoice
	ld xwa, (xsp + 4)
	lds bc, 1
	calr NoteMap_AllocateVoice
	cpdi16 52770, 0
	jr z, NoteMap_FallbackAllocEmit
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_FallbackAllocEmit
	ld xwa, (xsp + 4)
	lds bc, 2
	calr NoteMap_AllocateVoice

NoteMap_FallbackAllocEmit:
	ldda16 xwa, 50584
	bit 9, wa
	jr z, UpdateEntry_CheckLayerCount
	ldi_berp 0xfb, 0
	cp_erpb 0xfb, 0x10
	jr nc, UpdateEntry_CheckLayerCount

UpdateEntry_EmitLoop:
	ldto_berp A, 0xfb
	extz wa
	add wa, 0x84
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	cp a, (xsp + 2)
	jr nz, UpdateEntry_EmitNext
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call Voice_BuildAndEmitNoteOnEvents

UpdateEntry_EmitNext:
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, UpdateEntry_EmitLoop

UpdateEntry_CheckLayerCount:
	ld xwa, (xsp + 4)
	cp (xwa + 3), 0x0
	jrl nz, NoteMap_CollectBestEmit
	ld xwa, (xsp + 8)
	lds bc, 1
	call NoteMap_EmitNoteOnEvents
	jrl NoteMap_CollectBestEmit

UpdateEntry_NonSpecialPath:
	ld xwa, (xsp + 4)
	ld c, (xsp + 2)
	cp_srib_rm C, 0xe1, 0xb6, 0x00
	jr nz, NoteMap_DirectLookupEmit
	ld xwa, (xsp + 8)
	lds bc, 2
	call NoteMap_FindEntry
	ld xwa, (xsp + 8)
	call NoteMap_FindBestFreeVoice
	cps l, 0
	jr nz, NoteMap_DirectLookupEmit
	call VoiceMap_AllocateSlot
	cp l, 0xff
	jr z, NoteMap_DirectLookupEmit
	ld xwa, (xsp + 4)
	lds bc, 2
	calr NoteMap_AssignVoiceParams
	ld xwa, (xsp + 4)
	lds bc, 2
	calr NoteMap_InitVoiceSlots

NoteMap_DirectLookupEmit:
	ld a, (xsp + 2)
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call NoteMap_AllocNewVoiceEntry
	ld a, (xsp + 2)
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call NoteMap_SetChannelParam
	ldda16 xwa, 50584
	bit 9, wa
	jr z, UpdateEntry_CheckSeqPartEmit
	ldi_berp 0xfb, 0
	cp_erpb 0xfb, 0x10
	jr nc, UpdateEntry_CheckSeqPartEmit

UpdateEntry_DirectEmitLoop:
	ldto_berp A, 0xfb
	extz wa
	add wa, 0x84
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	cp a, (xsp + 2)
	jr nz, UpdateEntry_DirectEmitNext
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call Voice_BuildAndEmitNoteOnEvents

UpdateEntry_DirectEmitNext:
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, UpdateEntry_DirectEmitLoop

UpdateEntry_CheckSeqPartEmit:
	ld a, (xsp + 2)
	extz wa
	add wa, 0x44
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	ldfr_berp A, 0xfb
	cp a, 0xff
	jr z, UpdateEntry_CheckMidiEmit
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call SeqPart_EmitNoteOnMessages

UpdateEntry_CheckMidiEmit:
	ld a, (xsp + 2)
	extz wa
	add wa, 0x64
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	ldfr_berp A, 0xfb
	cp a, 0xff
	jr z, UpdateEntry_CheckLayerResult
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call Voice_EmitMidiNoteOnEvents

UpdateEntry_CheckLayerResult:
	ld xwa, (xsp + 4)
	cp (xwa + 3), 0x0
	jr nz, NoteMap_CollectBestEmit
	ld xwa, (xsp + 8)
	lds bc, 0
	call NoteMap_EmitNoteOnEvents

NoteMap_CollectBestEmit:
	pop_werp 0xfa
	lda xsp, (xsp + 10)
	ret

NoteMap_FindAndAllocBestVoice:
	st_dri3b L, 0xfd, 0x52, 0xff
	push_werp 0xfa
	lda_dri3 XIY, 0xfd, 0xa6, 0x00
	st_dri3l XBC, 0xfd, 0xa8, 0x00
	st_dri3l XWA, 0xfd, 0xac, 0x00
	cp_srib_im 0xfd, 0xa6, 0x00, 0x15
	jrl nz, FindAllocBest_NonSpecialPath
	lda xwa, (xsp + 2)
	pushw 0x0
	ld_sril XBC, (xsp + 0x00ae)
	lds de, 4
	call NoteMap_CollectMatchingEntries
	cps l, 0
	jrl z, NoteMap_PopRetFA_StoreAE3
	lda xwa, (xsp + 2)
	lds bc, 0
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestVoiceSlot
	cps l, 0
	jr nz, NoteMap_FindAllocEmit
	ld_sril XWA, (xsp + 0x00a8)
	lds bc, 0
	calr NoteMap_AllocateVoice
	ld_sril XWA, (xsp + 0x00a8)
	lds bc, 1
	calr NoteMap_AllocateVoice
	cpdi16 52770, 0
	jr z, NoteMap_FindAllocEmit
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_FindAllocEmit
	ld_sril XWA, (xsp + 0x00a8)
	lds bc, 2
	calr NoteMap_AllocateVoice

NoteMap_FindAllocEmit:
	ldda16 xwa, 50584
	bit 9, wa
	jrl z, NoteMap_PopRetFA_StoreAE3
	ldi_berp 0xfb, 0
	cp_erpb 0xfb, 0x10
	jrl nc, NoteMap_PopRetFA_StoreAE3

FindAllocEmit_LoopBody:
	ldto_berp A, 0xfb
	extz wa
	add wa, 0x84
	extz xwa
	add_sril_rm XWA, 0xfd, 0xa8, 0x00
	ld a, (xwa)
	cp_srib_rm A, 0xfd, 0xa6, 0x00
	jr nz, FindAllocEmit_LoopCheck
	lda xwa, (xsp + 2)
	ld xde, xwa
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

FindAllocEmit_LoopCheck:
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, FindAllocEmit_LoopBody
	jrl NoteMap_PopRetFA_StoreAE3

FindAllocBest_NonSpecialPath:
	ld_sril XWA, (xsp + 0x00a8)
	ld_srib C, (xsp + 0x00a6)
	cp_srib_rm C, 0xe1, 0xb6, 0x00
	jr nz, NoteMap_CollectAndAllocVoice_NoTimerReset
	lda xwa, (xsp + 2)
	pushw 0x2
	ld_sril XBC, (xsp + 0x00ae)
	lds de, 4
	call NoteMap_CollectMatchingEntries
	cps l, 0
	jr z, NoteMap_CollectAndAllocVoice_NoTimerReset
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	cps l, 0
	jr nz, NoteMap_CollectAndAllocVoice_NoTimerReset
	call VoiceMap_AllocateSlot
	cp l, 0xff
	jr z, NoteMap_CollectAndAllocVoice_NoTimerReset
	ld_sril XWA, (xsp + 0x00a8)
	lds bc, 2
	calr NoteMap_AssignVoiceParams
	ld_sril XWA, (xsp + 0x00a8)
	lds bc, 2
	calr NoteMap_InitVoiceSlots

NoteMap_CollectAndAllocVoice_NoTimerReset:
	lda xwa, (xsp + 2)
	ld xbc, xwa
	ld_srib A, (xsp + 0x00a6)
	extz wa
	pushw wa
	ld xwa, xbc
	ld_sril XBC, (xsp + 0x00ae)
	lds de, 0
	call NoteMap_CollectMatchingEntries
	cps l, 0
	jrl z, NoteMap_PopRetFA_StoreAE3
	lda xwa, (xsp + 2)
	ld xde, xwa
	ld_srib A, (xsp + 0x00a6)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocNewVoiceEntry
	lda xwa, (xsp + 2)
	ld xde, xwa
	ld_srib A, (xsp + 0x00a6)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	ldda16 xwa, 50584
	bit 9, wa
	jr z, CollectAndAllocVoice_LoadFromStack
	ldi_berp 0xfb, 0
	cp_erpb 0xfb, 0x10
	jr nc, CollectAndAllocVoice_LoadFromStack

CollectAndAllocVoice_LoopBody:
	ldto_berp A, 0xfb
	extz wa
	add wa, 0x84
	extz xwa
	add_sril_rm XWA, 0xfd, 0xa8, 0x00
	ld a, (xwa)
	cp_srib_rm A, 0xfd, 0xa6, 0x00
	jr nz, CollectAndAllocVoice_LoopCheck
	lda xwa, (xsp + 2)
	ld xde, xwa
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

CollectAndAllocVoice_LoopCheck:
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, CollectAndAllocVoice_LoopBody

CollectAndAllocVoice_LoadFromStack:
	ld_srib A, (xsp + 0x00a6)
	extz wa
	add wa, 0x44
	extz xwa
	add_sril_rm XWA, 0xfd, 0xa8, 0x00
	ld a, (xwa)
	ldfr_berp A, 0xfb
	cp a, 0xff
	jr z, CollectAndAllocVoice_LoadFromStack2
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld_sril XWA, (xsp + 0x00ac)
	call SeqPart_EmitNoteOnMessages

CollectAndAllocVoice_LoadFromStack2:
	ld_srib A, (xsp + 0x00a6)
	extz wa
	add wa, 0x64
	extz xwa
	add_sril_rm XWA, 0xfd, 0xa8, 0x00
	ld a, (xwa)
	ldfr_berp A, 0xfb
	cp a, 0xff
	jr z, NoteMap_PopRetFA_StoreAE3
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld_sril XWA, (xsp + 0x00ac)
	call Voice_EmitMidiNoteOnEvents

NoteMap_PopRetFA_StoreAE3:
	pop_werp 0xfa
	st_dri3b L, 0xfd, 0xae, 0x00
	ret

PopRetFA_StoreAE3_Prologue:
	dec 6, xsp
	push xiz
	ld (xsp + 4), e
	ld xiz, xbc
	ld (xsp + 6), xwa
	cp (xsp + 4), 0x15
	jr nz, AllocVoice_Done_LoadParam
	ld a, (xsp + 4)
	ld e, a
	extz de
	ld xwa, (xsp + 6)
	ld xbc, xiz
	call SndParam_ComputeVoiceTuning
	ld xwa, (xsp + 6)
	lds bc, 0
	call NoteMap_FindEntry
	ld xwa, (xsp + 6)
	call NoteMap_FindBestVoiceSlot
	cps l, 2
	jr z, PopRetFA_StoreAE3_LoadIter
	cps l, 3
	jr nz, NoteMap_AllocVoice_Done

PopRetFA_StoreAE3_LoadIter:
	ld xwa, xiz
	lds bc, 0
	calr NoteMap_AllocateVoice
	ld xwa, xiz
	lds bc, 1
	calr NoteMap_AllocateVoice
	cpdi16 52770, 0
	jr z, NoteMap_AllocVoice_Done
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_AllocVoice_Done
	ld xwa, xiz
	lds bc, 2
	calr NoteMap_AllocateVoice

NoteMap_AllocVoice_Done:
	cp (xiz + 3), 0x0
	jrl nz, NoteMap_UpdateVoiceSlots_Return
	ld xwa, (xsp + 6)
	lds bc, 1
	call NoteMap_EmitNoteOnEvents
	jrl NoteMap_UpdateVoiceSlots_Return

AllocVoice_Done_LoadParam:
	ld a, (xsp + 4)
	cp_srib_rm A, 0xf9, 0xb6, 0x00
	jr nz, NoteMap_AllocVoiceEntry_Continue
	ld a, (xsp + 4)
	ld e, a
	extz de
	ld xwa, (xsp + 6)
	ld xbc, xiz
	call SndParam_ComputeVoiceTuning
	ld xwa, (xsp + 6)
	lds bc, 2
	call NoteMap_FindEntry
	ld xwa, (xsp + 6)
	call NoteMap_FindBestFreeVoice
	cps l, 2
	jr z, AllocVoice_Done_TryAlloc
	cps l, 3
	jr nz, AllocVoice_Done_LoadIter

AllocVoice_Done_TryAlloc:
	call VoiceMap_AllocateSlot
	cp l, 0xff
	jr z, NoteMap_AllocVoiceEntry_Continue
	ld xwa, xiz
	lds bc, 2
	calr NoteMap_AssignVoiceParams
	ld xwa, xiz
	lds bc, 2
	calr NoteMap_InitVoiceSlots
	jr NoteMap_AllocVoiceEntry_Continue

AllocVoice_Done_LoadIter:
	ld xwa, xiz
	lds bc, 2
	calr NoteMap_AssignVoiceParams
	stdi16 52838, 0
	stdi8 52914, 0

NoteMap_AllocVoiceEntry_Continue:
	ld a, (xsp + 4)
	ld e, a
	extz de
	ld xwa, (xsp + 6)
	ld xbc, xiz
	call SndParam_ComputeVoiceTuning
	ld a, (xsp + 4)
	ld c, a
	extz bc
	ld xwa, (xsp + 6)
	call NoteMap_AllocNewVoiceEntry
	ld xwa, (xsp + 6)
	ld a, (xwa + 3)
	extz wa
	add wa, 0x94
	extz xwa
	add xwa, xiz
	ld a, (xwa)
	cp a, (xsp + 4)
	jr nz, AllocVoiceEntry_Cont_LoadParam
	ld a, (xsp + 4)
	ld c, a
	extz bc
	ld xwa, (xsp + 6)
	call NoteMap_SetChannelParam

AllocVoiceEntry_Cont_LoadParam:
	ld xwa, (xsp + 6)
	ld a, (xwa + 3)
	extz wa
	add wa, 0xa4
	extz xwa
	add xwa, xiz
	ld c, (xwa)
	ld a, c
	cp a, 0xff
	jr z, AllocVoiceEntry_Cont_LoadParam2
	ld a, (xsp + 4)
	extz wa
	add wa, wa
	add wa, 0x124
	bit_dri 5, 0x07, 0xf8, 0xe0
	jr z, AllocVoiceEntry_Cont_LoadParam2
	extz bc
	ld xwa, (xsp + 6)
	call Voice_ScanAndEmitMidiEvents

AllocVoiceEntry_Cont_LoadParam2:
	ld a, (xsp + 4)
	cp a, (xiz + 2)
	jr nz, NoteMap_UpdateVoiceSlots_Return
	ld xwa, (xsp + 6)
	lds bc, 0
	call NoteMap_EmitNoteOnEvents

NoteMap_UpdateVoiceSlots_Return:
	pop xiz
	inc 6, xsp
	ret

NoteMap_ProcessNoteEvent:
	st_dri3b L, 0xfd, 0x52, 0xff
	lda_dri3 XIY, 0xfd, 0xa4, 0x00
	st_dri3l XBC, 0xfd, 0xa6, 0x00
	st_dri3l XWA, 0xfd, 0xaa, 0x00
	cp_srib_im 0xfd, 0xa4, 0x00, 0x15
	jr nz, ProcessNoteEvent_LoadFromStack2
	lda xwa, (xsp)
	pushw 0x0
	ld_sril XBC, (xsp + 0x00ac)
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jrl z, NoteMap_StoreAllocResult
	lda xwa, (xsp)
	lds bc, 0
	call NoteMap_FindEntry
	lda xwa, (xsp)
	call NoteMap_FindBestVoiceSlot
	cps l, 2
	jr z, ProcessNoteEvent_LoadFromStack
	cps l, 3
	jrl nz, NoteMap_StoreAllocResult

ProcessNoteEvent_LoadFromStack:
	ld_sril XWA, (xsp + 0x00a6)
	lds bc, 0
	calr NoteMap_AllocateVoice
	ld_sril XWA, (xsp + 0x00a6)
	lds bc, 1
	calr NoteMap_AllocateVoice
	cpdi16 52770, 0
	jrl z, NoteMap_StoreAllocResult
	call NoteMap_FindBestMatch
	cp l, 0xff
	jrl z, NoteMap_StoreAllocResult
	ld_sril XWA, (xsp + 0x00a6)
	lds bc, 2
	calr NoteMap_AllocateVoice
	jrl NoteMap_StoreAllocResult

ProcessNoteEvent_LoadFromStack2:
	ld_sril XWA, (xsp + 0x00a6)
	ld_srib C, (xsp + 0x00a4)
	cp_srib_rm C, 0xe1, 0xb6, 0x00
	jr nz, NoteMap_LookupAllocAndStore
	lda xwa, (xsp)
	pushw 0x2
	ld_sril XBC, (xsp + 0x00ac)
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jr z, NoteMap_LookupAllocAndStore
	lda xwa, (xsp)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp)
	call NoteMap_FindBestFreeVoice
	cps l, 2
	jr z, ProcessNoteEvent_TryAlloc
	cps l, 3
	jr nz, ProcessNoteEvent_LoadFromStack3

ProcessNoteEvent_TryAlloc:
	call VoiceMap_AllocateSlot
	cp l, 0xff
	jr z, NoteMap_LookupAllocAndStore
	ld_sril XWA, (xsp + 0x00a6)
	lds bc, 2
	calr NoteMap_AssignVoiceParams
	ld_sril XWA, (xsp + 0x00a6)
	lds bc, 2
	calr NoteMap_InitVoiceSlots
	jr NoteMap_LookupAllocAndStore

ProcessNoteEvent_LoadFromStack3:
	ld_sril XWA, (xsp + 0x00a6)
	lds bc, 2
	calr NoteMap_AssignVoiceParams
	stdi16 52838, 0
	stdi8 52914, 0

NoteMap_LookupAllocAndStore:
	lda xwa, (xsp)
	ld xbc, xwa
	ld_srib A, (xsp + 0x00a4)
	extz wa
	pushw wa
	ld xwa, xbc
	ld_sril XBC, (xsp + 0x00ac)
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, NoteMap_StoreAllocResult
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x00a4)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocNewVoiceEntry
	ld a, (xsp + 3)
	extz wa
	add wa, 0x94
	extz xwa
	add_sril_rm XWA, 0xfd, 0xa6, 0x00
	ld a, (xwa)
	cp_srib_rm A, 0xfd, 0xa4, 0x00
	jr nz, LookupAllocAndStore_LoadParam
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x00a4)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LookupAllocAndStore_LoadParam:
	ld a, (xsp + 3)
	extz wa
	add wa, 0xa4
	extz xwa
	add_sril_rm XWA, 0xfd, 0xa6, 0x00
	ld e, (xwa)
	ld a, e
	cp a, 0xff
	jr z, NoteMap_StoreAllocResult
	ld_srib A, (xsp + 0x00a4)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld_sril XWA, (xsp + 0x00a6)
	bit_dri 5, 0x07, 0xe0, 0xe4
	jr z, NoteMap_StoreAllocResult
	lda xwa, (xsp)
	ld c, e
	extz bc
	call Voice_ScanAndEmitMidiEvents

NoteMap_StoreAllocResult:
	st_dri3b L, 0xfd, 0xae, 0x00
	ret

NoteMap_ProcessRhythmNoteOn:
	lda xsp, (xsp - 10)
	ld (xsp), e
	ld (xsp + 2), xbc
	ld (xsp + 6), xwa
	ld a, (xsp)
	ld e, a
	extz de
	ld xwa, (xsp + 6)
	ld xbc, (xsp + 2)
	call NoteMap_ComputePitchOffset
	ld a, (xsp)
	ld c, a
	extz bc
	ld xwa, (xsp + 6)
	call NoteMap_AllocNewVoiceEntry
	ld a, (xsp)
	extz wa
	inc 4, wa
	extz xwa
	add xwa, (xsp + 2)
	ld a, (xwa)
	cp a, (xsp)
	jr nz, ProcessRhythmNoteOn_LoadParam
	ld a, (xsp)
	ld c, a
	extz bc
	ld xwa, (xsp + 6)
	call NoteMap_SetChannelParam

ProcessRhythmNoteOn_LoadParam:
	ld a, (xsp)
	extz wa
	add wa, 0x24
	extz xwa
	add xwa, (xsp + 2)
	ld e, (xwa)
	ld a, e
	cp a, 0xff
	jr z, ProcessRhythmNoteOn_Epilogue
	ld a, (xsp)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld xwa, (xsp + 2)
	bit_dri 5, 0x07, 0xe0, 0xe4
	jr z, ProcessRhythmNoteOn_Epilogue
	ld c, e
	extz bc
	ld xwa, (xsp + 6)
	call Voice_ScanAndEmitMidiEvents

ProcessRhythmNoteOn_Epilogue:
	lda xsp, (xsp + 10)
	ret

NoteMap_LookupAndAllocVoice:
	st_dri3b L, 0xfd, 0x56, 0xff
	lda_dri3 XIY, 0xfd, 0xa4, 0x00
	st_dri3l XBC, 0xfd, 0xa6, 0x00
	lda xbc, (xsp)
	ld xde, xbc
	ld_srib C, (xsp + 0x00a4)
	extz bc
	pushw bc
	ld xbc, xde
	ld xde, xwa
	ld xwa, xbc
	ld xbc, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jrl z, LookupAndAllocVoice_LoadFromStack2
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x00a4)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocNewVoiceEntry
	ld_srib A, (xsp + 0x00a4)
	extz wa
	inc 4, wa
	extz xwa
	add_sril_rm XWA, 0xfd, 0xa6, 0x00
	ld a, (xwa)
	cp_srib_rm A, 0xfd, 0xa4, 0x00
	jr nz, LookupAndAllocVoice_LoadFromStack
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x00a4)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LookupAndAllocVoice_LoadFromStack:
	ld_srib A, (xsp + 0x00a4)
	extz wa
	add wa, 0x24
	extz xwa
	add_sril_rm XWA, 0xfd, 0xa6, 0x00
	ld e, (xwa)
	ld a, e
	cp a, 0xff
	jr z, Voice_SetParam_Return
	ld_srib A, (xsp + 0x00a4)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld_sril XWA, (xsp + 0x00a6)
	bit_dri 5, 0x07, 0xe0, 0xe4
	jr z, Voice_SetParam_Return
	lda xwa, (xsp)
	ld c, e
	extz bc
	call Voice_ScanAndEmitMidiEvents
	jr Voice_SetParam_Return

LookupAndAllocVoice_LoadFromStack2:
	ld_srib A, (xsp + 0x00a4)
	extz wa
	inc 4, wa
	extz xwa
	add_sril_rm XWA, 0xfd, 0xa6, 0x00
	ld a, (xwa)
	cp_srib_rm A, 0xfd, 0xa4, 0x00
	jr nz, Voice_SetParam_Return
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x00a4)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

Voice_SetParam_Return:
	st_dri3b L, 0xfd, 0xaa, 0x00
	ret

NoteMap_ProcessRhythmRemap:
	st_dri3b L, 0xfd, 0x56, 0xff
	lda_dri3 XIY, 0xfd, 0xa4, 0x00
	st_dri3l XBC, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x00a4)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_CollectMatchingEntries
	cps l, 0
	jrl z, NoteMap_ProcessNoteOff_Done
	lda xwa, (xsp)
	ld xbc, xwa
	ld_srib A, (xsp + 0x00a4)
	ld e, a
	extz de
	ld xwa, xbc
	ld_sril XBC, (xsp + 0x00a6)
	call NoteMap_ComputePitchOffset
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x00a4)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocNewVoiceEntry
	ld_srib A, (xsp + 0x00a4)
	extz wa
	inc 4, wa
	extz xwa
	add_sril_rm XWA, 0xfd, 0xa6, 0x00
	ld a, (xwa)
	cp_srib_rm A, 0xfd, 0xa4, 0x00
	jr nz, ProcessRhythmRemap_LoadFromStack
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x00a4)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

ProcessRhythmRemap_LoadFromStack:
	ld_srib A, (xsp + 0x00a4)
	extz wa
	add wa, 0x24
	extz xwa
	add_sril_rm XWA, 0xfd, 0xa6, 0x00
	ld e, (xwa)
	ld a, e
	cp a, 0xff
	jr z, NoteMap_ProcessNoteOff_Done
	ld_srib A, (xsp + 0x00a4)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld_sril XWA, (xsp + 0x00a6)
	bit_dri 5, 0x07, 0xe0, 0xe4
	jr z, NoteMap_ProcessNoteOff_Done
	lda xwa, (xsp)
	ld c, e
	extz bc
	call Voice_ScanAndEmitMidiEvents

NoteMap_ProcessNoteOff_Done:
	st_dri3b L, 0xfd, 0xaa, 0x00
	ret

ProcessNoteOff_Done_Prologue:
	lda xsp, (xsp - 10)
	ld (xsp), e
	ld (xsp + 2), xbc
	ld (xsp + 6), xwa
	ld xwa, (xsp + 6)
	call InitChannelState_Che_InitVal
	ld a, (xsp)
	ld c, a
	extz bc
	ld xwa, (xsp + 6)
	call NoteMap_AllocNewVoiceEntry
	ld a, (xsp)
	extz wa
	inc 4, wa
	extz xwa
	add xwa, (xsp + 2)
	ld a, (xwa)
	cp a, (xsp)
	jr nz, ProcessNoteOff_Done_Epilogue
	ld a, (xsp)
	ld c, a
	extz bc
	ld xwa, (xsp + 6)
	call NoteMap_SetChannelParam

ProcessNoteOff_Done_Epilogue:
	lda xsp, (xsp + 10)
	ret

NoteMap_LookupAllocAndStoreResult:
	st_dri3b L, 0xfd, 0x56, 0xff
	lda_dri3 XIY, 0xfd, 0xa4, 0x00
	st_dri3l XBC, 0xfd, 0xa6, 0x00
	lda xbc, (xsp)
	ld xde, xbc
	ld_srib C, (xsp + 0x00a4)
	extz bc
	pushw bc
	ld xbc, xwa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, LookupAllocAndStoreR_WriteReg
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x00a4)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocNewVoiceEntry
	ld_srib A, (xsp + 0x00a4)
	extz wa
	inc 4, wa
	extz xwa
	add_sril_rm XWA, 0xfd, 0xa6, 0x00
	ld a, (xwa)
	cp_srib_rm A, 0xfd, 0xa4, 0x00
	jr nz, LookupAllocAndStoreR_WriteReg
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x00a4)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LookupAllocAndStoreR_WriteReg:
	st_dri3b L, 0xfd, 0xaa, 0x00
	ret

NoteMap_InitVoiceSlots:
	st_dri3b L, 0xfd, 0x54, 0xff
	push xiz
	lda_dri3 XHL, 0xfd, 0xaa, 0x00
	st_dri3l XWA, 0xfd, 0xac, 0x00
	ld_srib A, (xsp + 0x00aa)
	extz wa
	add wa, 0xbc
	extz xwa
	add_sril_rm XWA, 0xfd, 0xac, 0x00
	ld a, (xwa)
	ld (xsp + 4), a
	cp a, 0xff
	jrl z, NoteMap_PopIz_StoreAC
	ld_srib A, (xsp + 0x00aa)
	extz wa
	sla wa, 2
	lda_24 xbc, 0xee8f22
	ld_sril3 XIZ, 0x07, 0xe4, 0xe0
	cpw (xiz), 0x0
	jrl z, NoteMap_PopIz_StoreAC
	ld wa, (xiz)
	ld (xsp + 7), a
	ld (xsp + 6), 0x90
	ld (xsp + 8), 0x6
	ld_srib A, (xsp + 0x00aa)
	ld (xsp + 9), a
	lds de, 0
	cp de, (xiz)
	jr nc, InitVoiceSlots_AllocAndCheck

InitVoiceSlots_CopyLoop:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 6)
	ld xhl, xwa
	add xhl, xbc
	ld wa, de
	extz xwa
	add xwa, xwa
	inc 4, xwa
	add xwa, xiz
	ld a, (xwa + 1)
	ld (xhl), a
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 7)
	ld xhl, xwa
	add xhl, xbc
	ld wa, de
	extz xwa
	add xwa, xwa
	inc 4, xwa
	add xwa, xiz
	ld a, (xwa)
	ld (xhl), a
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 10)
	add xwa, xbc
	ld (xwa), 0x0
	inc 1, de
	cp de, (xiz)
	jr c, InitVoiceSlots_CopyLoop

InitVoiceSlots_AllocAndCheck:
	lda xwa, (xsp + 6)
	ld xbc, xwa
	ld a, (xsp + 4)
	ld e, a
	extz de
	ld xwa, xbc
	ld_sril XBC, (xsp + 0x00ac)
	call Voice_SetTransposeAndAlloc
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld a, (xsp + 4)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocNewVoiceEntry
	cpw (xiz + 2), 0x0
	jr nz, InitVoiceSlots_SetChannel
	ld a, (xsp + 4)
	extz wa
	inc 4, wa
	extz xwa
	add_sril_rm XWA, 0xfd, 0xac, 0x00
	cp (xwa), 0xff
	jr z, InitVoiceSlots_CheckDualLayer

InitVoiceSlots_SetChannel:
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld a, (xsp + 4)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

InitVoiceSlots_CheckDualLayer:
	cpw (xiz + 2), 0x1
	jr z, NoteMap_PopIz_StoreAC
	ld a, (xsp + 4)
	extz wa
	add wa, 0x24
	extz xwa
	add_sril_rm XWA, 0xfd, 0xac, 0x00
	ld e, (xwa)
	ld a, e
	cp a, 0xff
	jr z, NoteMap_PopIz_StoreAC
	ld a, (xsp + 4)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld_sril XWA, (xsp + 0x00ac)
	bit_dri 5, 0x07, 0xe0, 0xe4
	jr z, NoteMap_PopIz_StoreAC
	cp_srib_im 0xfd, 0xaa, 0x00, 0x02
	jr nz, InitVoiceSlots_EmitMidi
	ld_sril XWA, (xsp + 0x00ac)
	bit_dri 5, 0xe1, 0x56, 0x01
	jr z, NoteMap_PopIz_StoreAC

InitVoiceSlots_EmitMidi:
	lda xwa, (xsp + 6)
	ld c, e
	extz bc
	call Voice_ScanAndEmitMidiEvents

NoteMap_PopIz_StoreAC:
	pop xiz
	st_dri3b L, 0xfd, 0xac, 0x00
	ret

; ============================================================================
; NoteMap_AssignVoiceParams - Assign voice parameters for note-on events
; ============================================================================
; Input:  Voice channel parameters
; Output: None
; Iterates voice slots, validates format, looks up voice, assigns params.
; ============================================================================
NoteMap_AssignVoiceParams:
	st_dri3b L, 0xfd, 0x52, 0xff
	push_werp 0xfa
	lda_dri3 XHL, 0xfd, 0xaa, 0x00
	st_dri3l XWA, 0xfd, 0xac, 0x00
	ld_srib A, (xsp + 0x00aa)
	extz wa
	add wa, 0xbc
	extz xwa
	add_sril_rm XWA, 0xfd, 0xac, 0x00
	ld a, (xwa)
	ldfr_berp A, 0xfb
	cp a, 0xff
	jrl z, NoteMap_PopRetFA_StoreAE4
	ld_srib A, (xsp + 0x00aa)
	extz wa
	sla wa, 2
	lda_24 xbc, 0xee8f22
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld (xsp + 2), xwa
	ld (xsp + 6), 0x90
	ld (xsp + 8), 0x6
	ld_srib A, (xsp + 0x00aa)
	ld (xsp + 9), a
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp + 6)
	ld xbc, xwa
	ldto_berp A, 0xfb
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jrl z, NoteMap_PopRetFA_StoreAE4
	lda xwa, (xsp + 6)
	ld xde, xwa
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocNewVoiceEntry
	ld xwa, (xsp + 2)
	cpw (xwa + 2), 0x0
	jr nz, AssignVoiceParams_SetChannel
	ldto_berp A, 0xfb
	extz wa
	inc 4, wa
	extz xwa
	add_sril_rm XWA, 0xfd, 0xac, 0x00
	cp (xwa), 0xff
	jr z, AssignVoiceParams_CheckDualLayer

AssignVoiceParams_SetChannel:
	lda xwa, (xsp + 6)
	ld xde, xwa
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

AssignVoiceParams_CheckDualLayer:
	ld xwa, (xsp + 2)
	cpw (xwa + 2), 0x1
	jr z, NoteMap_PopRetFA_StoreAE4
	ldto_berp A, 0xfb
	extz wa
	add wa, 0x24
	extz xwa
	add_sril_rm XWA, 0xfd, 0xac, 0x00
	ld e, (xwa)
	ld a, e
	cp a, 0xff
	jr z, NoteMap_PopRetFA_StoreAE4
	ldto_berp A, 0xfb
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld_sril XWA, (xsp + 0x00ac)
	bit_dri 5, 0x07, 0xe0, 0xe4
	jr z, NoteMap_PopRetFA_StoreAE4
	cp_srib_im 0xfd, 0xaa, 0x00, 0x02
	jr nz, AssignVoiceParams_Ch_LoadAddr
	ld_sril XWA, (xsp + 0x00ac)
	bit_dri 5, 0xe1, 0x56, 0x01
	jr z, NoteMap_PopRetFA_StoreAE4

AssignVoiceParams_Ch_LoadAddr:
	lda xwa, (xsp + 6)
	ld c, e
	extz bc
	call Voice_ScanAndEmitMidiEvents

NoteMap_PopRetFA_StoreAE4:
	pop_werp 0xfa
	st_dri3b L, 0xfd, 0xae, 0x00
	ret

; ============================================================================
; NoteMap_AllocateVoice - Allocate a voice slot for a note
; ============================================================================
; Input:  XWA = note map base pointer
;         BC = voice layer index (0, 1, or 2)
; Output: L = allocated voice number (0xff if none available)
; Searches the voice table at 0xee8f22 for an available slot matching the
; requested instrument/channel. Uses a stride of 5 bytes per voice entry.
; Called by NoteMap_AddEntry for each voice layer.
; ============================================================================
NoteMap_AllocateVoice:
	st_dri3b L, 0xfd, 0x54, 0xff
	push xiz
	lda_dri3 XHL, 0xfd, 0xaa, 0x00
	st_dri3l XWA, 0xfd, 0xac, 0x00
	ld_srib A, (xsp + 0x00aa)
	extz wa
	add wa, 0xbc
	extz xwa
	add_sril_rm XWA, 0xfd, 0xac, 0x00
	ld a, (xwa)
	ld (xsp + 4), a
	cp a, 0xff
	jrl z, NoteMap_PopIz_StoreAC2
	ld_srib A, (xsp + 0x00aa)
	extz wa
	sla wa, 2
	lda_24 xbc, 0xee8f22
	ld_sril3 XIZ, 0x07, 0xe4, 0xe0
	ld wa, (xiz)
	ld (xsp + 7), a
	ld (xsp + 6), 0x90
	ld (xsp + 8), 0x6
	ld_srib A, (xsp + 0x00aa)
	ld (xsp + 9), a
	lds de, 0
	cp de, (xiz)
	jrl nc, AllocateVoice_LoadAddr

AllocateVoice_LoadReg:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 6)
	ld xhl, xwa
	add xhl, xbc
	ld wa, de
	extz xwa
	add xwa, xwa
	inc 4, xwa
	add xwa, xiz
	ld a, (xwa + 1)
	ld (xhl), a
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 8)
	ld xhl, xwa
	add xhl, xbc
	ld wa, de
	extz xwa
	add xwa, xwa
	inc 4, xwa
	add xwa, xiz
	ld a, (xwa + 1)
	ld (xhl), a
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 9)
	ld xhl, xwa
	add xhl, xbc
	ld wa, de
	extz xwa
	add xwa, xwa
	inc 4, xwa
	add xwa, xiz
	ld a, (xwa + 1)
	ld (xhl), a
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 7)
	ld xhl, xwa
	add xhl, xbc
	ld wa, de
	extz xwa
	add xwa, xwa
	inc 4, xwa
	add xwa, xiz
	ld a, (xwa)
	ld (xhl), a
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp + 10)
	add xwa, xbc
	ld (xwa), 0x0
	inc 1, de
	cp de, (xiz)
	jrl c, AllocateVoice_LoadReg

AllocateVoice_LoadAddr:
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp + 6)
	ld xbc, xwa
	ld a, (xsp + 4)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_CollectMatchingEntries
	cps l, 0
	jrl z, NoteMap_PopIz_StoreAC2
	lda xwa, (xsp + 6)
	ld xbc, xwa
	ld a, (xsp + 4)
	ld e, a
	extz de
	ld xwa, xbc
	ld_sril XBC, (xsp + 0x00ac)
	call Voice_SetTransposeAndAlloc
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld a, (xsp + 4)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocNewVoiceEntry
	cpw (xiz + 2), 0x0
	jr nz, AllocateVoice_LoadAddr2
	ld a, (xsp + 4)
	extz wa
	inc 4, wa
	extz xwa
	add_sril_rm XWA, 0xfd, 0xac, 0x00
	cp (xwa), 0xff
	jr z, AllocateVoice_Compare

AllocateVoice_LoadAddr2:
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld a, (xsp + 4)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

AllocateVoice_Compare:
	cpw (xiz + 2), 0x1
	jr z, NoteMap_PopIz_StoreAC2
	ld a, (xsp + 4)
	extz wa
	add wa, 0x24
	extz xwa
	add_sril_rm XWA, 0xfd, 0xac, 0x00
	ld e, (xwa)
	ld a, e
	cp a, 0xff
	jr z, NoteMap_PopIz_StoreAC2
	ld a, (xsp + 4)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld_sril XWA, (xsp + 0x00ac)
	bit_dri 5, 0x07, 0xe0, 0xe4
	jr z, NoteMap_PopIz_StoreAC2
	cp_srib_im 0xfd, 0xaa, 0x00, 0x02
	jr nz, AllocateVoice_LoadAddr3
	ld_sril XWA, (xsp + 0x00ac)
	bit_dri 5, 0xe1, 0x56, 0x01
	jr z, NoteMap_PopIz_StoreAC2

AllocateVoice_LoadAddr3:
	lda xwa, (xsp + 6)
	ld c, e
	extz bc
	call Voice_ScanAndEmitMidiEvents

NoteMap_PopIz_StoreAC2:
	pop xiz
	st_dri3b L, 0xfd, 0xac, 0x00
	ret

NoteMap_SwapVoiceLinks:
	ld e, c
	extz de
	add de, de
	ld_srib3 E, 0x07, 0xe0, 0xe8
	extz de
	add de, de
	st_dri3b C, 0x07, 0xe0, 0xe8
	ld e, c
	extz de
	add de, de
	exts xde
	add xde, xwa
	ld e, (xde + 1)
	ld (xhl + 1), e
	ld e, c
	extz de
	add de, de
	exts xde
	add xde, xwa
	ld e, (xde + 1)
	extz de
	add de, de
	extz bc
	add bc, bc
	ld_srib3 C, 0x07, 0xe0, 0xe4
	lda_dri3 XHL, 0x07, 0xe0, 0xe8
	ret

NoteMap_LinkVoiceSlots:
	ld l, c
	extz hl
	add hl, hl
	st_dri3b D, 0x07, 0xe0, 0xec
	ld l, e
	extz hl
	add hl, hl
	exts xhl
	add xhl, xwa
	ld l, (xhl + 1)
	ld (xix + 1), l
	ld l, c
	extz hl
	add hl, hl
	lda_dri3 XIY, 0x07, 0xe0, 0xec
	ld l, e
	extz hl
	add hl, hl
	exts xhl
	add xhl, xwa
	ld l, (xhl + 1)
	extz hl
	add hl, hl
	lda_dri3 XHL, 0x07, 0xe0, 0xec
	extz de
	add de, de
	st_dri3b W, 0x07, 0xe0, 0xe8
	ld (xwa + 1), c
	ret

LinkVoiceSlots_LoadReg:
	ld e, c
	extz de
	add de, de
	st_dri3b W, 0x07, 0xe0, 0xe8
	cp (xwa + 1), c
	jr nz, LinkVoiceSlots_InitVal
	lds hl, 0
	ret

LinkVoiceSlots_InitVal:
	lds hl, 1
	ret

LinkVoiceSlots_Block:
	ldada xix, 50634
	ldada xiy, 59368
	ld e, (xwa + 3)
	extz de
	lda_24 xhl, 0xee8eb6
	ld_srib3 E, 0x07, 0xec, 0xe8
	extz bc
	muls bc, 0x5
	inc 4, bc
	ld_srib3 C, 0x07, 0xe0, 0xe4
	ld a, e
	extz wa
	add wa, wa
	exts xwa
	add xwa, xiy
	ld l, (xwa + 1)
	cp l, e
	ret z

LinkVoiceSlots_LoadReg2:
	ld a, l
	extz wa
	muls wa, 0x3
	exts xwa
	add xwa, xix
	cp (xwa + 1), c
	ret z
	ld a, l
	extz wa
	add wa, wa
	exts xwa
	add xwa, xiy
	ld l, (xwa + 1)
	cp l, e
	jr nz, LinkVoiceSlots_LoadReg2
	ret

NoteMap_LookupAndMergeVoice:
	ldada xhl, 50634
	ldada xix, 59368
	ldb c, 0x20
	cp (xwa + 3), 0x2
	jrl nc, LookupAndMergeVoice_Deref
	ld c, (xwa + 3)
	extz bc
	lda_24 xde, 0xee8eb6
	ld_srib3 C, 0x07, 0xe8, 0xe4
	ldfr_berp C, 0xea
	lds de, 0
	ldto_berp C, 0xea
	extz bc
	add bc, bc
	ld_srib3 C, 0x07, 0xf0, 0xe4
	ldfr_berp C, 0xeb
	cp_berp C, 0xea
	jr z, LookupAndMergeVoice_LoadReg2

LookupAndMergeVoice_LoadReg:
	ld bc, de
	extz xbc
	ld xiy, xbc
	sll xiy, 2
	add xiy, xbc
	inc 4, xiy
	add xiy, xwa
	ldto_berp C, 0xeb
	extz bc
	muls bc, 0x3
	exts xbc
	add xbc, xhl
	ld c, (xbc + 1)
	ld (xiy), c
	ld bc, de
	extz xbc
	ld xiy, xbc
	sll xiy, 2
	add xiy, xbc
	inc 4, xiy
	add xiy, xwa
	ldto_berp C, 0xeb
	extz bc
	muls bc, 0x3
	exts xbc
	add xbc, xhl
	ld c, (xbc + 2)
	ld (xiy + 1), c
	ld bc, de
	extz xbc
	ld xiy, xbc
	sll xiy, 2
	add xiy, xbc
	inc 4, xiy
	add xiy, xwa
	ld (xiy + 4), 0x0
	ldto_berp C, 0xeb
	extz bc
	add bc, bc
	ld_srib3 C, 0x07, 0xf0, 0xe4
	ldfr_berp C, 0xeb
	inc 1, de
	ldto_berp C, 0xeb
	cp_berp C, 0xea
	jr nz, LookupAndMergeVoice_LoadReg

LookupAndMergeVoice_LoadReg2:
	ld l, e
	ld (xwa + 1), l
	ret

LookupAndMergeVoice_Deref:
	ld (xwa + 1), 0x0
	ldb l, 0x0
	ret

Voice_LookupTableEntries:
	ldada xhl, 50634
	ldada xix, 59368
	ldb c, 0x20
	cp (xwa + 3), 0x2
	jrl nc, LookupTableEntries_Deref
	ld c, (xwa + 3)
	extz bc
	lda_24 xde, 0xee8eb6
	ld_srib3 C, 0x07, 0xe8, 0xe4
	ldfr_berp C, 0xea
	lds de, 0
	ldto_berp C, 0xea
	extz bc
	add bc, bc
	ld_srib3 C, 0x07, 0xf0, 0xe4
	ldfr_berp C, 0xeb
	cp_berp C, 0xea
	jr z, LookupTableEntries_LoadReg2

LookupTableEntries_LoadReg:
	ld bc, de
	extz xbc
	ld xiy, xbc
	sll xiy, 2
	add xiy, xbc
	inc 4, xiy
	add xiy, xwa
	ldto_berp C, 0xeb
	extz bc
	muls bc, 0x3
	exts xbc
	add xbc, xhl
	ld c, (xbc + 1)
	ld (xiy), c
	ld bc, de
	extz xbc
	ld xiy, xbc
	sll xiy, 2
	add xiy, xbc
	inc 4, xiy
	add xiy, xwa
	ld (xiy + 1), 0x0
	ld bc, de
	extz xbc
	ld xiy, xbc
	sll xiy, 2
	add xiy, xbc
	inc 4, xiy
	add xiy, xwa
	ld (xiy + 4), 0x0
	ldto_berp C, 0xeb
	extz bc
	add bc, bc
	ld_srib3 C, 0x07, 0xf0, 0xe4
	ldfr_berp C, 0xeb
	inc 1, de
	ldto_berp C, 0xeb
	cp_berp C, 0xea
	jr nz, LookupTableEntries_LoadReg

LookupTableEntries_LoadReg2:
	ld l, e
	ld (xwa + 1), l
	ret

LookupTableEntries_Deref:
	ld (xwa + 1), 0x0
	ldb l, 0x0
	ret

LookupTableEntries_Prologue:
	push xiz
	ld l, c
	extz hl
	muls hl, 0xd
	lda_24 xix, 0xee8f2e
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	ld l, c
	extz hl
	muls hl, 0xd
	lda_24 xiy, 0xee8f32
	ld_sril3 XIY, 0x07, 0xf4, 0xec
	extz bc
	muls bc, 0xd
	lda_24 xhl, 0xee8f36
	extz de
	ld_sril3 XBC, 0x07, 0xec, 0xe4
	ld_srib3 E, 0x07, 0xe4, 0xe8
	ld c, e
	extz bc
	add bc, bc
	exts xbc
	add xbc, xiy
	ld l, (xbc + 1)
	cp l, e
	jr z, LookupTableEntries_Epilogue

LookupTableEntries_LoadReg3:
	ld c, l
	extz bc
	sla bc, 3
	st_dri3b H, 0x07, 0xf0, 0xe4
	ld c, (xsp + 8)
	extz bc
	muls bc, 0x5
	inc 4, bc
	ld_srib3 C, 0x07, 0xe0, 0xe4
	cp c, (xiz + 2)
	jr nz, LookupTableEntries_LoadReg4
	ld c, l
	extz bc
	sla bc, 3
	st_dri3b H, 0x07, 0xf0, 0xe4
	ld c, (xwa + 3)
	cp c, (xiz + 1)
	jr nz, LookupTableEntries_LoadReg4
	ld c, l
	extz bc
	ld iz, bc
	sla iz, 3
	ld c, (xwa + 2)
	cp_srib_rm C, 0x07, 0xf0, 0xf8
	jr z, LookupTableEntries_Epilogue

LookupTableEntries_LoadReg4:
	ld c, l
	extz bc
	add bc, bc
	exts xbc
	add xbc, xiy
	ld l, (xbc + 1)
	cp l, e
	jr nz, LookupTableEntries_LoadReg3

LookupTableEntries_Epilogue:
	pop xiz
	retd 0x2

NoteMap_ClaimVoiceSlot:
	dec 4, xsp
	push xiz
	ld l, e
	ld xde, xbc
	cps l, 4
	jr ugt, ClaimVoiceSlot_Deref
	cp (xsp + 12), 0x20
	jr ule, ClaimVoiceSlot_LoadReg

ClaimVoiceSlot_Deref:
	ld (xwa + 1), 0x0
	ldb l, 0x0
	jrl NoteMap_LookupReturn

ClaimVoiceSlot_LoadReg:
	ld c, l
	extz bc
	muls bc, 0xd
	ld ix, bc
	lda_24 xiy, 0xee8f36
	ld c, (xsp + 12)
	ldfr_berp C, 0xf8
	extz iz
	ld_sril3 XBC, 0x07, 0xf4, 0xf0
	ld_srib3 B, 0x07, 0xe4, 0xf8
	ldfr_berp L, 0xf0
	extz ix
	muls ix, 0xd
	lda_24 xiy, 0xee8f2e
	ld_sril3 XIX, 0x07, 0xf4, 0xf0
	extz hl
	muls hl, 0xd
	lda_24 xiy, 0xee8f32
	ld_sril3 XHL, 0x07, 0xf4, 0xec
	ld (xsp + 4), xhl
	cp (xde + 3), 0xff
	jrl nz, ClaimVoiceSlot_InitVal
	lds hl, 0
	ld c, b
	ldfr_berp C, 0xf4
	extz iy
	ld iz, iy
	add iz, iz
	ld xiy, (xsp + 4)
	ld_srib3 C, 0x07, 0xf4, 0xf8
	ldfr_berp C, 0xe6
	cp c, b
	jrl z, NoteMap_StoreEntryAndReturn

ClaimVoiceSlot_LoadIdx:
	ldto_berp C, 0xe6
	ldfr_berp C, 0xf4
	extz iy
	sla iy, 3
	ld c, (xde + 2)
	cp_srib_rm C, 0x07, 0xf0, 0xf4
	jrl nz, ClaimVoiceSlot_LoadIdx2
	cp hl, 0x20
	jrl nc, NoteMap_StoreEntryAndReturn
	ld iy, hl
	extz xiy
	ld xiz, xiy
	sll xiz, 2
	add xiz, xiy
	inc 4, xiz
	add xiz, xwa
	ldto_berp C, 0xe6
	ldfr_berp C, 0xf4
	extz iy
	sla iy, 3
	exts xiy
	add xiy, xix
	ld c, (xiy + 2)
	ld (xiz), c
	ld iy, hl
	extz xiy
	ld xiz, xiy
	sll xiz, 2
	add xiz, xiy
	inc 4, xiz
	add xiz, xwa
	ldto_berp C, 0xe6
	ldfr_berp C, 0xf4
	extz iy
	sla iy, 3
	exts xiy
	add xiy, xix
	ld c, (xiy + 3)
	ld (xiz + 1), c
	ld iy, hl
	extz xiy
	ld xiz, xiy
	sll xiz, 2
	add xiz, xiy
	inc 4, xiz
	add xiz, xwa
	ldto_berp C, 0xe6
	ldfr_berp C, 0xf4
	extz iy
	sla iy, 3
	exts xiy
	add xiy, xix
	ld c, (xiy + 5)
	res 7, c
	ld (xiz + 2), c
	ld iy, hl
	extz xiy
	ld xiz, xiy
	sll xiz, 2
	add xiz, xiy
	inc 4, xiz
	add xiz, xwa
	ldto_berp C, 0xe6
	ldfr_berp C, 0xf4
	extz iy
	sla iy, 3
	exts xiy
	add xiy, xix
	ld c, (xiy + 6)
	ld (xiz + 3), c
	ld iy, hl
	extz xiy
	ld xiz, xiy
	sll xiz, 2
	add xiz, xiy
	inc 4, xiz
	add xiz, xwa
	ld (xiz + 4), 0x0
	inc 1, hl

ClaimVoiceSlot_LoadIdx2:
	ldto_berp C, 0xe6
	ldfr_berp C, 0xf4
	extz iy
	ld iz, iy
	add iz, iz
	ld xiy, (xsp + 4)
	ld_srib3 C, 0x07, 0xf4, 0xf8
	ldfr_berp C, 0xe6
	cp c, b
	jrl nz, ClaimVoiceSlot_LoadIdx
	jrl NoteMap_StoreEntryAndReturn

ClaimVoiceSlot_InitVal:
	lds hl, 0
	ld c, b
	ldfr_berp C, 0xf4
	extz iy
	ld iz, iy
	add iz, iz
	ld xiy, (xsp + 4)
	ld_srib3 C, 0x07, 0xf4, 0xf8
	ldfr_berp C, 0xe6
	cp c, b
	jrl z, NoteMap_StoreEntryAndReturn

ClaimVoiceSlot_LoadIdx3:
	ldto_berp C, 0xe6
	ldfr_berp C, 0xf4
	extz iy
	sla iy, 3
	ld c, (xde + 2)
	cp_srib_rm C, 0x07, 0xf0, 0xf4
	jrl nz, ClaimVoiceSlot_LoadIdx4
	ldto_berp C, 0xe6
	ldfr_berp C, 0xf4
	extz iy
	sla iy, 3
	exts xiy
	add xiy, xix
	ld c, (xde + 3)
	cp c, (xiy + 1)
	jrl nz, ClaimVoiceSlot_LoadIdx4
	cp hl, 0x20
	jrl nc, NoteMap_StoreEntryAndReturn
	ld iy, hl
	extz xiy
	ld xiz, xiy
	sll xiz, 2
	add xiz, xiy
	inc 4, xiz
	add xiz, xwa
	ldto_berp C, 0xe6
	ldfr_berp C, 0xf4
	extz iy
	sla iy, 3
	exts xiy
	add xiy, xix
	ld c, (xiy + 2)
	ld (xiz), c
	ld iy, hl
	extz xiy
	ld xiz, xiy
	sll xiz, 2
	add xiz, xiy
	inc 4, xiz
	add xiz, xwa
	ldto_berp C, 0xe6
	ldfr_berp C, 0xf4
	extz iy
	sla iy, 3
	exts xiy
	add xiy, xix
	ld c, (xiy + 3)
	ld (xiz + 1), c
	ld iy, hl
	extz xiy
	ld xiz, xiy
	sll xiz, 2
	add xiz, xiy
	inc 4, xiz
	add xiz, xwa
	ldto_berp C, 0xe6
	ldfr_berp C, 0xf4
	extz iy
	sla iy, 3
	exts xiy
	add xiy, xix
	ld c, (xiy + 5)
	res 7, c
	ld (xiz + 2), c
	ld iy, hl
	extz xiy
	ld xiz, xiy
	sll xiz, 2
	add xiz, xiy
	inc 4, xiz
	add xiz, xwa
	ldto_berp C, 0xe6
	ldfr_berp C, 0xf4
	extz iy
	sla iy, 3
	exts xiy
	add xiy, xix
	ld c, (xiy + 6)
	ld (xiz + 3), c
	ld iy, hl
	extz xiy
	ld xiz, xiy
	sll xiz, 2
	add xiz, xiy
	inc 4, xiz
	add xiz, xwa
	ld (xiz + 4), 0x0
	inc 1, hl

ClaimVoiceSlot_LoadIdx4:
	ldto_berp C, 0xe6
	ldfr_berp C, 0xf4
	extz iy
	ld iz, iy
	add iz, iz
	ld xiy, (xsp + 4)
	ld_srib3 C, 0x07, 0xf4, 0xf8
	ldfr_berp C, 0xe6
	cp c, b
	jrl nz, ClaimVoiceSlot_LoadIdx3

NoteMap_StoreEntryAndReturn:
	ld c, l
	ld (xwa + 1), c
	ld c, (xde)
	ld (xwa), c
	ld c, (xde + 2)
	ld (xwa + 2), c
	ld c, (xde + 3)
	ld (xwa + 3), c

NoteMap_LookupReturn:
	pop xiz
	inc 4, xsp
	retd 0x2

; ============================================================================
; NoteMap_LookupVoice - Look up voice assignment for a note event
; ============================================================================
; Input:  E = voice layer (0-4, rejects > 4)
;         XWA = note map pointer
;         (xsp+12) = MIDI channel (rejects > 0x20)
;         XBC = voice parameter block
; Output: L = voice slot index
; Looks up voice tables at 0xee8f2e-0xee8f36, cross-referencing channel,
; instrument, and layer to find the matching voice assignment.
; Uses stride of 0xd (13) bytes per voice entry.
; ============================================================================
NoteMap_LookupVoice:
	dec 4, xsp
	push xiz
	ld xix, xbc
	cps e, 4
	jr ugt, LookupVoice_RejectOutOfRange
	cp (xsp + 12), 0x20
	jr ule, LookupVoice_StartLookup

LookupVoice_RejectOutOfRange:
	ld (xwa + 1), 0x0
	ldb l, 0x0
	jrl NoteMap_LookupVoice_Return

LookupVoice_StartLookup:
	ld c, e
	extz bc
	muls bc, 0xd
	ld hl, bc
	lda_24 xiy, 0xee8f36
	ld c, (xsp + 12)
	ldfr_berp C, 0xf8
	extz iz
	ld_sril3 XBC, 0x07, 0xf4, 0xec
	ld_srib3 D, 0x07, 0xe4, 0xf8
	ld c, e
	extz bc
	muls bc, 0xd
	lda_24 xhl, 0xee8f2e
	ld_sril3 XIY, 0x07, 0xec, 0xe4
	ld c, e
	extz bc
	muls bc, 0xd
	lda_24 xhl, 0xee8f32
	ld_sril3 XBC, 0x07, 0xec, 0xe4
	ld (xsp + 4), xbc
	cp (xix + 3), 0xff
	jrl nz, LookupVoice_WithInstrument
	lds hl, 0
	ld c, d
	extz bc
	ld iz, bc
	add iz, iz
	ld xbc, (xsp + 4)
	ld_srib3 E, 0x07, 0xe4, 0xf8
	cp e, d
	jrl z, NoteMap_StoreResultAndReturn

LookupVoice_ScanEntries:
	ld c, e
	extz bc
	ld iz, bc
	sla iz, 3
	ld c, (xix + 2)
	cp_srib_rm C, 0x07, 0xf4, 0xf8
	jrl nz, LookupVoice_AdvanceAndCheck
	cp hl, 0x20
	jrl nc, NoteMap_StoreResultAndReturn
	ld bc, hl
	extz xbc
	ld xiz, xbc
	sll xiz, 2
	add xiz, xbc
	inc 4, xiz
	add xiz, xwa
	ld c, e
	extz bc
	sla bc, 3
	exts xbc
	add xbc, xiy
	ld c, (xbc + 2)
	ld (xiz), c
	ld bc, hl
	extz xbc
	ld xiz, xbc
	sll xiz, 2
	add xiz, xbc
	inc 4, xiz
	add xiz, xwa
	ld (xiz + 1), 0x0
	ld bc, hl
	extz xbc
	ld xiz, xbc
	sll xiz, 2
	add xiz, xbc
	inc 4, xiz
	add xiz, xwa
	ld c, e
	extz bc
	sla bc, 3
	exts xbc
	add xbc, xiy
	ld c, (xbc + 5)
	res 7, c
	ld (xiz + 2), c
	ld bc, hl
	extz xbc
	ld xiz, xbc
	sll xiz, 2
	add xiz, xbc
	inc 4, xiz
	add xiz, xwa
	ld c, e
	extz bc
	sla bc, 3
	exts xbc
	add xbc, xiy
	ld c, (xbc + 6)
	ld (xiz + 3), c
	ld bc, hl
	extz xbc
	ld xiz, xbc
	sll xiz, 2
	add xiz, xbc
	inc 4, xiz
	add xiz, xwa
	ld (xiz + 4), 0x0
	inc 1, hl

LookupVoice_AdvanceAndCheck:
	ld c, e
	extz bc
	ld iz, bc
	add iz, iz
	ld xbc, (xsp + 4)
	ld_srib3 E, 0x07, 0xe4, 0xf8
	cp e, d
	jrl nz, LookupVoice_ScanEntries
	jrl NoteMap_StoreResultAndReturn

LookupVoice_WithInstrument:
	lds hl, 0
	ld c, d
	extz bc
	ld iz, bc
	add iz, iz
	ld xbc, (xsp + 4)
	ld_srib3 E, 0x07, 0xe4, 0xf8
	cp e, d
	jrl z, NoteMap_StoreResultAndReturn

LookupVoice_InstrScanEntries:
	ld c, e
	extz bc
	ld iz, bc
	sla iz, 3
	ld c, (xix + 2)
	cp_srib_rm C, 0x07, 0xf4, 0xf8
	jrl nz, LookupVoice_InstrSca_LoadReg
	ld c, e
	extz bc
	sla bc, 3
	st_dri3b H, 0x07, 0xf4, 0xe4
	ld c, (xix + 3)
	cp c, (xiz + 1)
	jrl nz, LookupVoice_InstrSca_LoadReg
	cp hl, 0x20
	jrl nc, NoteMap_StoreResultAndReturn
	ld bc, hl
	extz xbc
	ld xiz, xbc
	sll xiz, 2
	add xiz, xbc
	inc 4, xiz
	add xiz, xwa
	ld c, e
	extz bc
	sla bc, 3
	exts xbc
	add xbc, xiy
	ld c, (xbc + 2)
	ld (xiz), c
	ld bc, hl
	extz xbc
	ld xiz, xbc
	sll xiz, 2
	add xiz, xbc
	inc 4, xiz
	add xiz, xwa
	ld (xiz + 1), 0x0
	ld bc, hl
	extz xbc
	ld xiz, xbc
	sll xiz, 2
	add xiz, xbc
	inc 4, xiz
	add xiz, xwa
	ld c, e
	extz bc
	sla bc, 3
	exts xbc
	add xbc, xiy
	ld c, (xbc + 5)
	res 7, c
	ld (xiz + 2), c
	ld bc, hl
	extz xbc
	ld xiz, xbc
	sll xiz, 2
	add xiz, xbc
	inc 4, xiz
	add xiz, xwa
	ld c, e
	extz bc
	sla bc, 3
	exts xbc
	add xbc, xiy
	ld c, (xbc + 6)
	ld (xiz + 3), c
	ld bc, hl
	extz xbc
	ld xiz, xbc
	sll xiz, 2
	add xiz, xbc
	inc 4, xiz
	add xiz, xwa
	ld (xiz + 4), 0x0
	inc 1, hl

LookupVoice_InstrSca_LoadReg:
	ld c, e
	extz bc
	ld iz, bc
	add iz, iz
	ld xbc, (xsp + 4)
	ld_srib3 E, 0x07, 0xe4, 0xf8
	cp e, d
	jrl nz, LookupVoice_InstrScanEntries

NoteMap_StoreResultAndReturn:
	ld c, l
	ld (xwa + 1), c
	ld c, (xix)
	ld (xwa), c
	ld c, (xix + 2)
	ld (xwa + 2), c
	ld c, (xix + 3)
	ld (xwa + 3), c

NoteMap_LookupVoice_Return:
	pop xiz
	inc 4, xsp
	retd 0x2

NoteMap_CollectMatchingEntries:
	st_dri3b L, 0xfd, 0x4e, 0xff
	pushw iz
	ld l, e
	st_dri3l XBC, 0xfd, 0xac, 0x00
	st_dri3l XWA, 0xfd, 0xb0, 0x00
	cps l, 4
	jr ugt, CollectMatchingEntri_LoadFromStack
	cp_srib_im 0xfd, 0xb8, 0x00, 0x20
	jr ule, CollectMatchingEntri_LoadReg

CollectMatchingEntri_LoadFromStack:
	ld_sril XWA, (xsp + 0x00b0)
	ld (xwa + 1), 0x0
	ldb l, 0x0
	jrl EmitNoteData_Process_RestoreReg

CollectMatchingEntri_LoadReg:
	ld a, l
	extz wa
	muls wa, 0xd
	ld bc, wa
	lda_24 xde, 0xee8f36
	ld_srib A, (xsp + 0x00b8)
	ldfr_berp A, 0xf0
	extz ix
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ld_srib3 A, 0x07, 0xe0, 0xf0
	ld (xsp + 2), a
	ld a, l
	extz wa
	muls wa, 0xd
	lda_24 xbc, 0xee8f2e
	ld_sril3 XDE, 0x07, 0xe4, 0xe0
	ld a, l
	extz wa
	muls wa, 0xd
	lda_24 xbc, 0xee8f32
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld (xsp + 4), xwa
	lds hl, 0
	lds iz, 0
	jrl EmitNoteData_Process_LoadFromStack

CollectMatchingEntri_LoadParam:
	ld a, (xsp + 2)
	ld c, a

NoteMap_EmitNoteData_Process:
	ld a, c
	extz wa
	ld bc, wa
	add bc, bc
	ld xwa, (xsp + 4)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld a, (xwa + 1)
	ld c, a
	cp a, (xsp + 2)
	jr nz, EmitNoteData_Process_LoadReg
	ld wa, hl
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xix, (xsp + 8)
	add xix, xbc
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	ld xiy, xbc
	add_sril_rm XIY, 0xfd, 0xac, 0x00
	lds bc, 2
	ldirw
	ldi85
	inc 1, hl
	jr EmitNoteData_Process_NextIter

EmitNoteData_Process_LoadReg:
	ld a, c
	extz wa
	sla wa, 3
	st_dri3b E, 0x07, 0xe8, 0xe0
	ld wa, iz
	extz xwa
	ld xix, xwa
	sll xix, 2
	add xix, xwa
	inc 4, xix
	add_sril_rm XIX, 0xfd, 0xac, 0x00
	ld a, (xix)
	cp a, (xiy + 2)
	jr nz, NoteMap_EmitNoteData_Process
	ld a, c
	extz wa
	sla wa, 3
	st_dri3b D, 0x07, 0xe8, 0xe0
	ld_sril XWA, (xsp + 0x00ac)
	ld a, (xwa + 3)
	cp a, (xix + 1)
	jrl nz, NoteMap_EmitNoteData_Process
	ld a, c
	extz wa
	ld ix, wa
	sla ix, 3
	ld_sril XWA, (xsp + 0x00ac)
	ld a, (xwa + 2)
	cp_srib_rm A, 0x07, 0xe8, 0xf0
	jrl nz, NoteMap_EmitNoteData_Process
	ld a, c
	extz wa
	sla wa, 3
	exts xwa
	add xwa, xde
	setm 0, (xwa + 7)

EmitNoteData_Process_NextIter:
	inc 1, iz

EmitNoteData_Process_LoadFromStack:
	ld_sril XWA, (xsp + 0x00ac)
	ld a, (xwa + 1)
	extz wa
	cp iz, wa
	jrl c, CollectMatchingEntri_LoadParam
	ld (xsp + 9), l
	ld c, (xsp + 2)
	lds hl, 0
	jrl EmitNoteData_Process_LoadReg4

EmitNoteData_Process_LoadReg2:
	ld a, c
	extz wa
	sla wa, 3
	exts xwa
	add xwa, xde
	bitm 0, (xwa + 7)
	jrl nz, EmitNoteData_Process_LoadReg3
	cp iz, 0x20
	jrl nc, EmitNoteData_Process_InitVal
	ld wa, hl
	extz xwa
	ld xix, xwa
	sll xix, 2
	add xix, xwa
	inc 4, xix
	add_sril_rm XIX, 0xfd, 0xb0, 0x00
	ld a, c
	extz wa
	sla wa, 3
	exts xwa
	add xwa, xde
	ld a, (xwa + 2)
	ld (xix), a
	ld wa, hl
	extz xwa
	ld xix, xwa
	sll xix, 2
	add xix, xwa
	inc 4, xix
	add_sril_rm XIX, 0xfd, 0xb0, 0x00
	ld (xix + 1), 0x0
	ld wa, hl
	extz xwa
	ld xix, xwa
	sll xix, 2
	add xix, xwa
	inc 4, xix
	add_sril_rm XIX, 0xfd, 0xb0, 0x00
	ld a, c
	extz wa
	sla wa, 3
	exts xwa
	add xwa, xde
	ld a, (xwa + 5)
	res 7, a
	ld (xix + 2), a
	ld wa, hl
	extz xwa
	ld xix, xwa
	sll xix, 2
	add xix, xwa
	inc 4, xix
	add_sril_rm XIX, 0xfd, 0xb0, 0x00
	ld a, c
	extz wa
	sla wa, 3
	exts xwa
	add xwa, xde
	ld a, (xwa + 6)
	ld (xix + 3), a
	ld wa, hl
	extz xwa
	ld xix, xwa
	sll xix, 2
	add xix, xwa
	inc 4, xix
	add_sril_rm XIX, 0xfd, 0xb0, 0x00
	ld (xix + 4), 0x0
	inc 1, hl
	jr EmitNoteData_Process_LoadReg4

EmitNoteData_Process_LoadReg3:
	ld a, c
	extz wa
	sla wa, 3
	exts xwa
	add xwa, xde
	resm 0, (xwa + 7)

EmitNoteData_Process_LoadReg4:
	ld a, c
	extz wa
	ld bc, wa
	add bc, bc
	ld xwa, (xsp + 4)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld a, (xwa + 1)
	ld c, a
	cp a, (xsp + 2)
	jrl nz, EmitNoteData_Process_LoadReg2

EmitNoteData_Process_InitVal:
	lds iz, 0
	jr EmitNoteData_Process_LoopCheck

EmitNoteData_Process_LoopBody:
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xiy, (xsp + 8)
	add xiy, xbc
	ld wa, hl
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	ld xix, xbc
	add_sril_rm XIX, 0xfd, 0xb0, 0x00
	lds bc, 2
	ldirw
	ldi85
	inc 1, iz
	inc 1, hl

EmitNoteData_Process_LoopCheck:
	ld a, (xsp + 9)
	extz wa
	cp iz, wa
	jr c, EmitNoteData_Process_LoopBody
	ld c, l
	ld_sril XWA, (xsp + 0x00b0)
	ld (xwa + 1), c
	ld_sril XWA, (xsp + 0x00ac)
	ld c, (xwa)
	ld_sril XWA, (xsp + 0x00b0)
	ld (xwa), c
	ld_sril XWA, (xsp + 0x00ac)
	ld c, (xwa + 2)
	ld_sril XWA, (xsp + 0x00b0)
	ld (xwa + 2), c
	ld_sril XWA, (xsp + 0x00ac)
	ld c, (xwa + 3)
	ld_sril XWA, (xsp + 0x00b0)
	ld (xwa + 3), c

EmitNoteData_Process_RestoreReg:
	popw iz
	st_dri3b L, 0xfd, 0xb2, 0x00
	retd 0x2

NoteMap_AllocNewVoiceEntry:
	lda xsp, (xsp - 14)
	push_werp 0xfa
	ld (xsp + 10), c
	ld (xsp + 12), xwa
	ldada xwa, 59438
	ld (xsp + 6), xwa
	cp (xsp + 10), 0x20
	jrl ugt, SlotLoop_Continue_RestoreReg
	ld a, (xsp + 10)
	extz wa
	lda_24 xbc, CharMap_ValueData_A
	ld_srib3 A, 0x07, 0xe4, 0xe0
	ld (xsp + 4), a
	ldw (xsp + 2), 0x0
	jrl SlotLoop_Continue_LoadParam

AllocNewVoiceEntry_LoadParam:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	bitm 1, (xbc + 4)
	jrl nz, NoteMap_SlotLoop_Continue
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	cp (xbc + 1), 0x0
	jrl z, AllocNewVoiceEntry_LoadParam3
	ldda8 a, 59695
	ldfr_berp A, 0xfb
	cp a, 0x80
	jrl z, AllocNewVoiceEntry_LoadParam2
	ld a, (xsp + 10)
	extz wa
	ld hl, wa
	add hl, hl
	ldada xix, 50730
	ld a, (xsp + 10)
	extz wa
	ld bc, wa
	add bc, bc
	ldada xde, 50731
	ld_srib3 A, 0x07, 0xf0, 0xec
	cp_srib_rm A, 0x07, 0xe8, 0xe4
	jrl ule, AllocNewVoiceEntry_LoadParam2
	ld a, (xsp + 10)
	extz wa
	add wa, wa
	ldada xbc, 50731
	inc_srib 1, 0x07, 0xe4, 0xe0
	ldto_berp A, 0xfb
	extz wa
	ld de, wa
	sla de, 3
	ldada xhl, 50801
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	ld a, (xbc + 4)
	lda_dri3 XBC, 0x07, 0xec, 0xe8
	ldto_berp A, 0xfb
	extz wa
	ld bc, wa
	sla bc, 3
	ldada xde, 50794
	ld xwa, (xsp + 12)
	ld a, (xwa + 2)
	lda_dri3 XBC, 0x07, 0xe8, 0xe4
	ldto_berp A, 0xfb
	extz wa
	ld bc, wa
	sla bc, 3
	ldada xde, 50795
	ld xwa, (xsp + 12)
	ld a, (xwa + 3)
	lda_dri3 XBC, 0x07, 0xe8, 0xe4
	ldto_berp A, 0xfb
	extz wa
	ld de, wa
	sla de, 3
	ldada xhl, 50796
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	ld a, (xbc)
	lda_dri3 XBC, 0x07, 0xec, 0xe8
	ldto_berp A, 0xfb
	extz wa
	ld de, wa
	sla de, 3
	ldada xhl, 50799
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	ld a, (xbc + 2)
	res 7, a
	lda_dri3 XBC, 0x07, 0xec, 0xe8
	ldto_berp A, 0xfb
	extz wa
	ld de, wa
	sla de, 3
	ldada xhl, 50800
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	ld a, (xbc + 3)
	lda_dri3 XBC, 0x07, 0xec, 0xe8
	ldto_berp A, 0xfb
	extz wa
	ld de, wa
	sla de, 3
	ldada xhl, 50797
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	ld a, (xbc + 1)
	lda_dri3 XBC, 0x07, 0xec, 0xe8
	ldto_berp A, 0xfb
	extz wa
	ld bc, wa
	sla bc, 3
	ldada xde, 50798
	ld a, (xsp + 10)
	lda_dri3 XBC, 0x07, 0xe8, 0xe4
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, (xsp + 6)
	calr NoteMap_SwapVoiceLinks
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld a, (xsp + 4)
	ld e, a
	extz de
	ld xwa, (xsp + 6)
	calr NoteMap_LinkVoiceSlots
	jrl NoteMap_SlotLoop_Continue

AllocNewVoiceEntry_LoadParam2:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	setm 1, (xbc + 4)
	jrl NoteMap_SlotLoop_Continue

AllocNewVoiceEntry_LoadParam3:
	ld a, (xsp + 10)
	ld c, a
	extz bc
	ld wa, (xsp + 2)
	extz wa
	pushw wa
	ld xwa, (xsp + 14)
	ld de, bc
	lds bc, 0
	calr LookupTableEntries_Prologue
	ldfr_berp L, 0xfb
	ldto_berp A, 0xfb
	cp a, (xsp + 4)
	jrl z, AllocNewVoiceEntry_LoadParam4
	ld a, (xsp + 10)
	extz wa
	add wa, wa
	ldada xbc, 50731
	dec_srib 1, 0x07, 0xe4, 0xe0
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	ld xde, xbc
	add xde, (xsp + 12)
	ldto_berp A, 0xfb
	extz wa
	sla wa, 3
	ldada xbc, 50799
	ld_srib3 A, 0x07, 0xe4, 0xe0
	res 7, a
	ld (xde + 2), a
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	ld xde, xbc
	add xde, (xsp + 12)
	ldto_berp A, 0xfb
	extz wa
	sla wa, 3
	ldada xbc, 50800
	ld_srib3 A, 0x07, 0xe4, 0xe0
	ld (xde + 3), a
	ldada xde, 59438
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	calr NoteMap_SwapVoiceLinks
	ldada xde, 59438
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	ldw de, 0x80
	calr NoteMap_LinkVoiceSlots
	ldada xde, 59438
	ld a, (xsp + 4)
	ld c, a
	extz bc
	ld xwa, xde
	calr LinkVoiceSlots_LoadReg
	cps hl, 0
	jr nz, NoteMap_SlotLoop_Continue
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	setm 7, (xbc + 2)
	jr NoteMap_SlotLoop_Continue

AllocNewVoiceEntry_LoadParam4:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	setm 1, (xbc + 4)

NoteMap_SlotLoop_Continue:
	incm 1, (xsp + 2)

SlotLoop_Continue_LoadParam:
	ld xwa, (xsp + 12)
	ld a, (xwa + 1)
	extz wa
	cp (xsp + 2), wa
	jrl c, AllocNewVoiceEntry_LoadParam

SlotLoop_Continue_RestoreReg:
	pop_werp 0xfa
	lda xsp, (xsp + 14)
	ret

; ============================================================================
; NoteMap_SetChannelParam - Set a MIDI channel parameter in the note map
; ============================================================================
; Input:  C = MIDI channel number
;         XWA = pointer to parameter data (command byte at offset 0)
; Output: None
; Dispatches MIDI channel messages: handles control change (0xa0=all notes off),
; program change, pitch bend, and other channel voice messages. Reads channel
; configuration from voice table at 0xee8eb8.
; ============================================================================
NoteMap_SetChannelParam:
	lda xsp, (xsp - 28)
	pushw iz
	ld (xsp + 24), c
	ld (xsp + 26), xwa
	ld a, (xsp + 24)
	extz wa
	lda_24 xbc, CharMap_ValueData_A
	ld_srib3 A, 0x07, 0xe4, 0xe0
	ld a, (xsp + 24)
	extz wa
	calr SelectTone_Continue_Prologue
	ld (xsp + 24), l
	ld xwa, (xsp + 26)
	cp (xwa), 0xa0
	jr nz, SetChannelParam_LoadParam
	ld (xsp + 4), 0x4
	ld (xsp + 5), 0xb0
	ld a, (xsp + 24)
	ld (xsp + 6), a
	ld (xsp + 7), 0x78
	ld (xsp + 8), 0x0
	lda xwa, (xsp + 4)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	jrl MIDI_SendVoiceData_Return

SetChannelParam_LoadParam:
	ld xwa, (xsp + 26)
	cp (xwa + 2), 0x6
	jr nz, SetChannelParam_LoadParam3
	ld xwa, (xsp + 26)
	ld a, (xwa + 3)
	cps a, 2
	jr z, SetChannelParam_LoadDRAM2
	cps a, 1
	jr z, SetChannelParam_LoadDRAM
	cps a, 0
	jr nz, SetChannelParam_LoadParam2
	ldda16 xwa, 52993
	extz xwa
	ld xbc, 0xee8f70
	add xbc, xwa
	ld a, (xbc)
	ld (xsp + 2), a
	jrl Voice_EmitMidiNoteAndBankEvents

SetChannelParam_LoadDRAM:
	ldda16 xwa, 53041
	extz xwa
	ld xbc, 0xee8f70
	add xbc, xwa
	ld a, (xbc)
	ld (xsp + 2), a
	jr Voice_EmitMidiNoteAndBankEvents

SetChannelParam_LoadDRAM2:
	ldda16 xwa, 52772
	extz xwa
	ld xbc, 0xee8f70
	add xbc, xwa
	ld a, (xbc)
	ld (xsp + 2), a
	jr Voice_EmitMidiNoteAndBankEvents

SetChannelParam_LoadParam2:
	ld (xsp + 2), 0x0
	jr Voice_EmitMidiNoteAndBankEvents

SetChannelParam_LoadParam3:
	ld xwa, (xsp + 26)
	cp (xwa + 2), 0x4
	jr nz, SetChannelParam_LoadParam5
	ld xwa, (xsp + 26)
	bitm 3, (xwa)
	jr z, SetChannelParam_LoadParam4
	ld xwa, (xsp + 26)
	ld a, (xwa + 2)
	extz wa
	lda_24 xbc, 0xee8f70
	ld_srib3 A, 0x07, 0xe4, 0xe0
	set 3, a
	ld (xsp + 2), a
	jr Voice_EmitMidiNoteAndBankEvents

SetChannelParam_LoadParam4:
	ld xwa, (xsp + 26)
	ld a, (xwa + 2)
	extz wa
	lda_24 xbc, 0xee8f70
	ld_srib3 A, 0x07, 0xe4, 0xe0
	ld (xsp + 2), a
	jr Voice_EmitMidiNoteAndBankEvents

SetChannelParam_LoadParam5:
	ld xwa, (xsp + 26)
	ld a, (xwa + 2)
	extz wa
	lda_24 xbc, 0xee8f70
	ld_srib3 A, 0x07, 0xe4, 0xe0
	ld (xsp + 2), a

Voice_EmitMidiNoteAndBankEvents:
	lds iz, 0
	jrl MIDI_SendVoiceData_CheckCount

MIDI_SendVoiceData_Loop:
	ld wa, iz
	muls wa, 0x5
	ld bc, wa
	inc 4, bc
	ld xwa, (xsp + 26)
	st_dri3b W, 0x07, 0xe0, 0xe4
	bitm 1, (xwa + 4)
	jrl nz, MIDI_SendVoiceData_Increment
	ld wa, iz
	muls wa, 0x5
	ld bc, wa
	inc 4, bc
	ld xwa, (xsp + 26)
	st_dri3b W, 0x07, 0xe0, 0xe4
	cp (xwa + 2), 0xff
	jrl z, MIDI_SendVoiceData_Increment
	ld (xsp + 4), 0x4
	ld a, (xsp + 2)
	or a, 0x90
	ld (xsp + 5), a
	ld a, (xsp + 24)
	ld (xsp + 6), a
	ld wa, iz
	muls wa, 0x5
	ld bc, wa
	inc 4, bc
	ld xwa, (xsp + 26)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld a, (xwa + 2)
	res 7, a
	ld (xsp + 7), a
	ld wa, iz
	muls wa, 0x5
	ld bc, wa
	inc 4, bc
	ld xwa, (xsp + 26)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld a, (xwa + 1)
	ld (xsp + 8), a
	lda xwa, (xsp + 4)
	call MIDI_SendCmdPacket
	ld wa, iz
	muls wa, 0x5
	ld bc, wa
	inc 4, bc
	ld xwa, (xsp + 26)
	st_dri3b W, 0x07, 0xe0, 0xe4
	bitm 7, (xwa + 2)
	jr z, MIDI_SendVoiceData_Increment
	ld (xsp + 4), 0x4
	ld (xsp + 5), 0xb0
	ld a, (xsp + 24)
	ld (xsp + 6), a
	ld (xsp + 7), 0x7b
	ld (xsp + 8), 0x0
	lda xwa, (xsp + 4)
	call MIDI_SendCmdPacket

MIDI_SendVoiceData_Increment:
	inc 1, iz

MIDI_SendVoiceData_CheckCount:
	ld xwa, (xsp + 26)
	ld a, (xwa + 1)
	extz wa
	cp iz, wa
	jrl lt, MIDI_SendVoiceData_Loop
	cps iz, 0
	call_24 gt, 0xfebf79

MIDI_SendVoiceData_Return:
	popw iz
	lda xsp, (xsp + 28)
	ret

Voice_ScanAndEmitMidiEvents:
	dec 6, xsp
	push xiz
	ld (xsp + 4), c
	ld (xsp + 6), xwa
	lds iz, 0
	ldi_werp 0xfa, 0
	jrl ScanEmitMidi_CheckVoiceCount

ScanEmitMidi_VoiceLoop:
	ldto_werp WA, 0xfa
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	bitm 1, (xbc + 4)
	jrl nz, MIDI_SysExParse_CheckLength
	ldto_werp WA, 0xfa
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	cp (xbc + 3), 0xff
	jrl z, MIDI_SysExParse_CheckLength
	ld a, (xsp + 4)
	or a, 0x90
	extz wa
	call FileData_ValidateFormat
	cps hl, 0
	jr ge, ScanEmitMidi_ValidFormat
	ld wa, iz
	extz xwa
	ld xbc, 0xccc2
	add xbc, xwa
	ld a, (xsp + 4)
	or a, 0x90
	ld (xbc), a
	ld wa, iz
	extz xwa
	inc 1, xwa
	ld xbc, 0xccc2
	ld xde, xbc
	add xde, xwa
	ldto_werp WA, 0xfa
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	ld a, (xbc + 3)
	ld (xde), a
	ld wa, iz
	extz xwa
	inc 2, xwa
	ld xbc, 0xccc2
	ld xde, xbc
	add xde, xwa
	ldto_werp WA, 0xfa
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	ld a, (xbc + 1)
	ld (xde), a
	inc 3, iz
	jr MIDI_SysExParse_CheckLength

ScanEmitMidi_ValidFormat:
	ld wa, iz
	extz xwa
	ld xbc, 0xccc2
	ld xde, xbc
	add xde, xwa
	ldto_werp WA, 0xfa
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	ld a, (xbc + 3)
	ld (xde), a
	ld wa, iz
	extz xwa
	inc 1, xwa
	ld xbc, 0xccc2
	ld xde, xbc
	add xde, xwa
	ldto_werp WA, 0xfa
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	ld a, (xbc + 1)
	ld (xde), a
	inc 2, iz

MIDI_SysExParse_CheckLength:
	cps iz, 0
	jr z, ScanEmitMidi_NextVoice
	cp iz, 0xf
	jr ugt, SysExParse_CheckLeng_LoadReg
	ld xwa, (xsp + 6)
	ld a, (xwa + 1)
	dec 1, a
	extz wa
	cp_werp WA, 0xfa
	jr nz, ScanEmitMidi_NextVoice

SysExParse_CheckLeng_LoadReg:
	ld xwa, 0xccc2
	push xwa
	pushw iz
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	lds iz, 0

ScanEmitMidi_NextVoice:
	inc1_werp 0xfa

ScanEmitMidi_CheckVoiceCount:
	ld xwa, (xsp + 6)
	ld a, (xwa + 1)
	ld c, a
	extz bc
	ldto_werp WA, 0xfa
	cp wa, bc
	jrl c, ScanEmitMidi_VoiceLoop
	pop xiz
	inc 6, xsp
	ret

Voice_BuildAndEmitNoteOnEvents:
	dec 8, xsp
	pushw iz
	ld (xsp + 4), c
	ld (xsp + 6), xwa
	ei 6
	setda 0, 1113
	ldmi16 (xsp + 2), 0x41b
	ei 0
	lds bc, 0
	lds iz, 0
	jrl BuildNoteOn_CheckVoiceCount

BuildNoteOn_VoiceLoop:
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	inc 4, xde
	add xde, (xsp + 6)
	bitm 1, (xde + 4)
	jrl nz, BuildNoteOn_NextVoice
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	inc 4, xde
	add xde, (xsp + 6)
	cp (xde + 2), 0xff
	jrl z, BuildNoteOn_NextVoice
	ld wa, bc
	mul wa, 0x5
	ldada xde, 52436
	ld hl, wa
	extz xhl
	add xhl, xde
	ld xwa, (xsp + 6)
	ld a, (xwa + 2)
	extz wa
	lda_24 xde, 0xee8f78
	ld_srib3 A, 0x07, 0xe8, 0xe0
	or a, 0x90
	ld (xhl), a
	ld wa, bc
	mul wa, 0x5
	ldada xde, 52437
	ld hl, wa
	extz xhl
	add xhl, xde
	ld a, (xsp + 2)
	ld (xhl), a
	ld wa, bc
	mul wa, 0x5
	ldada xde, 52438
	ld hl, wa
	extz xhl
	add xhl, xde
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	inc 4, xde
	add xde, (xsp + 6)
	ld a, (xde + 2)
	res 7, a
	ld (xhl), a
	ld wa, bc
	mul wa, 0x5
	ldada xde, 52439
	ld hl, wa
	extz xhl
	add xhl, xde
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	inc 4, xde
	add xde, (xsp + 6)
	ld a, (xde + 1)
	ld (xhl), a
	ld wa, bc
	mul wa, 0x5
	ldada xde, 52440
	ld hl, wa
	extz xhl
	add xhl, xde
	ld a, (xsp + 4)
	ld (xhl), a
	inc 1, bc

BuildNoteOn_NextVoice:
	cps bc, 0
	jr z, BuildNoteOn_NextVoic_NextIter
	cps bc, 6
	jr z, BuildNoteOn_NextVoic_LoadReg
	ld xwa, (xsp + 6)
	ld a, (xwa + 1)
	dec 1, a
	extz wa
	cp wa, iz
	jr nz, BuildNoteOn_NextVoic_NextIter

BuildNoteOn_NextVoic_LoadReg:
	ld xwa, 0xccd4
	push xwa
	ld wa, bc
	mul wa, 0x5
	pushw wa
	call TempoRingBuf_WriteBytes
	inc 6, xsp
	lds bc, 0

BuildNoteOn_NextVoic_NextIter:
	inc 1, iz

BuildNoteOn_CheckVoiceCount:
	ld xwa, (xsp + 6)
	ld a, (xwa + 1)
	extz wa
	cp iz, wa
	jrl c, BuildNoteOn_VoiceLoop
	call TempoRingBuf_Consume
	call SeqPlay_CheckAndStartPlayback
	popw iz
	inc 8, xsp
	ret

SeqPart_EmitNoteOnMessages:
	dec 8, xsp
	pushw iz
	ld (xsp + 4), c
	ld (xsp + 6), xwa
	ei 6
	setda 0, 1113
	ldmi16 (xsp + 2), 0x415
	ei 0
	lds bc, 0
	lds iz, 0
	jrl EmitNoteOnMessages_LoadParam

EmitNoteOnMessages_LoadIter:
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	inc 4, xde
	add xde, (xsp + 6)
	bitm 1, (xde + 4)
	jrl nz, EmitNoteOnMessages_Compare
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	inc 4, xde
	add xde, (xsp + 6)
	cp (xde + 2), 0xff
	jrl z, EmitNoteOnMessages_Compare
	ld wa, bc
	mul wa, 0x5
	ldada xde, 52466
	extz xwa
	add xwa, xde
	ld (xwa), 0x90
	ld wa, bc
	mul wa, 0x5
	ldada xde, 52467
	ld hl, wa
	extz xhl
	add xhl, xde
	ld a, (xsp + 2)
	ld (xhl), a
	ld wa, bc
	mul wa, 0x5
	ldada xde, 52468
	ld hl, wa
	extz xhl
	add xhl, xde
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	inc 4, xde
	add xde, (xsp + 6)
	ld a, (xde + 2)
	res 7, a
	ld (xhl), a
	ld wa, bc
	mul wa, 0x5
	ldada xde, 52469
	ld hl, wa
	extz xhl
	add xhl, xde
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	inc 4, xde
	add xde, (xsp + 6)
	ld a, (xde + 1)
	ld (xhl), a
	ld wa, bc
	mul wa, 0x5
	ldada xde, 52470
	ld hl, wa
	extz xhl
	add xhl, xde
	ld a, (xsp + 4)
	ld (xhl), a
	inc 1, bc

EmitNoteOnMessages_Compare:
	cps bc, 0
	jr z, EmitNoteOnMessages_NextIter
	cps bc, 6
	jr z, EmitNoteOnMessages_LoadReg
	ld xwa, (xsp + 6)
	ld a, (xwa + 1)
	dec 1, a
	extz wa
	cp wa, iz
	jr nz, EmitNoteOnMessages_NextIter

EmitNoteOnMessages_LoadReg:
	ld xwa, 0xccf2
	push xwa
	ld wa, bc
	mul wa, 0x5
	pushw wa
	call TempoRingBuf_WriteBytes
	inc 6, xsp
	lds bc, 0

EmitNoteOnMessages_NextIter:
	inc 1, iz

EmitNoteOnMessages_LoadParam:
	ld xwa, (xsp + 6)
	ld a, (xwa + 1)
	extz wa
	cp iz, wa
	jrl c, EmitNoteOnMessages_LoadIter
	call TempoRingBuf_Consume
	popw iz
	inc 8, xsp
	ret

Voice_EmitMidiNoteOnEvents:
	dec 8, xsp
	pushw iz
	ld (xsp + 4), c
	ld (xsp + 6), xwa
	ei 6
	setda 0, 1113
	ldmi16 (xsp + 2), 0x46a
	ei 0
	lds bc, 0
	lds iz, 0
	jrl EmitMidiNoteOnEvents_LoadParam

EmitMidiNoteOnEvents_LoadIter:
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	inc 4, xde
	add xde, (xsp + 6)
	bitm 1, (xde + 4)
	jrl nz, EmitMidiNoteOnEvents_Compare
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	inc 4, xde
	add xde, (xsp + 6)
	cp (xde + 2), 0xff
	jrl z, EmitMidiNoteOnEvents_Compare
	ld wa, bc
	mul wa, 0x5
	ldada xde, 52496
	extz xwa
	add xwa, xde
	ld (xwa), 0x90
	ld wa, bc
	mul wa, 0x5
	ldada xde, 52497
	ld hl, wa
	extz xhl
	add xhl, xde
	ld a, (xsp + 2)
	ld (xhl), a
	ld wa, bc
	mul wa, 0x5
	ldada xde, 52498
	ld hl, wa
	extz xhl
	add xhl, xde
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	inc 4, xde
	add xde, (xsp + 6)
	ld a, (xde + 2)
	res 7, a
	ld (xhl), a
	ld wa, bc
	mul wa, 0x5
	ldada xde, 52499
	ld hl, wa
	extz xhl
	add xhl, xde
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	inc 4, xde
	add xde, (xsp + 6)
	ld a, (xde + 1)
	ld (xhl), a
	ld wa, bc
	mul wa, 0x5
	ldada xde, 52500
	ld hl, wa
	extz xhl
	add xhl, xde
	ld a, (xsp + 4)
	ld (xhl), a
	inc 1, bc

EmitMidiNoteOnEvents_Compare:
	cps bc, 0
	jr z, EmitMidiNoteOnEvents_NextIter
	cps bc, 6
	jr z, EmitMidiNoteOnEvents_LoadReg
	ld xwa, (xsp + 6)
	ld a, (xwa + 1)
	dec 1, a
	extz wa
	cp wa, iz
	jr nz, EmitMidiNoteOnEvents_NextIter

EmitMidiNoteOnEvents_LoadReg:
	ld xwa, 0xcd10
	push xwa
	ld wa, bc
	mul wa, 0x5
	pushw wa
	call TempoRingBuf_WriteBytes
	inc 6, xsp
	lds bc, 0

EmitMidiNoteOnEvents_NextIter:
	inc 1, iz

EmitMidiNoteOnEvents_LoadParam:
	ld xwa, (xsp + 6)
	ld a, (xwa + 1)
	extz wa
	cp iz, wa
	jrl c, EmitMidiNoteOnEvents_LoadIter
	call TempoRingBuf_Consume
	popw iz
	inc 8, xsp
	ret

; ============================================================================
; NoteMap_FindEntry - Find an existing entry in the note map
; ============================================================================
; Input:  C = search key / channel
;         XWA = note map base pointer
;         BC = search mode (0 = standard)
; Output: L = entry index (0xff if not found)
; Searches the note map for an entry matching the given criteria. Uses a
; stride of 5 bytes per entry. Checks active flags (bit 1 at offset 4)
; and matches against channel assignment data at 0xee8ed8.
; ============================================================================
NoteMap_FindEntry:
	lda xsp, (xsp - 14)
	push_werp 0xfa
	ld (xsp + 10), c
	ld (xsp + 12), xwa
	ld a, (xsp + 10)
	extz wa
	lda_24 xbc, CharMap_ValueData_B
	ld_srib3 A, 0x07, 0xe4, 0xe0
	ld (xsp + 4), a
	ldada xwa, 59760
	ld (xsp + 6), xwa
	ldw (xsp + 2), 0x0
	jrl LoopAdvance_Next_LoadParam

FindEntry_LoadParam:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	bitm 1, (xbc + 4)
	jrl nz, Voice_LoopAdvance_Next
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	cp (xbc + 1), 0x0
	jrl z, FindEntry_LoadParam3
	ldda8 a, 59825
	ldfr_berp A, 0xfb
	cp a, 0x20
	jrl z, FindEntry_LoadParam2
	ld a, (xsp + 10)
	extz wa
	ld hl, wa
	add hl, hl
	ldada xix, 51818
	ld a, (xsp + 10)
	extz wa
	ld bc, wa
	add bc, bc
	ldada xde, 51819
	ld_srib3 A, 0x07, 0xf0, 0xec
	cp_srib_rm A, 0x07, 0xe8, 0xe4
	jrl ule, FindEntry_LoadParam2
	ld a, (xsp + 10)
	extz wa
	add wa, wa
	ldada xbc, 51819
	inc_srib 1, 0x07, 0xe4, 0xe0
	ldto_berp A, 0xfb
	extz wa
	ld de, wa
	sla de, 3
	ldada xhl, 51841
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	ld a, (xbc + 4)
	lda_dri3 XBC, 0x07, 0xec, 0xe8
	ldto_berp A, 0xfb
	extz wa
	ld bc, wa
	sla bc, 3
	ldada xde, 51834
	ld xwa, (xsp + 12)
	ld a, (xwa + 2)
	lda_dri3 XBC, 0x07, 0xe8, 0xe4
	ldto_berp A, 0xfb
	extz wa
	ld bc, wa
	sla bc, 3
	ldada xde, 51835
	ld xwa, (xsp + 12)
	ld a, (xwa + 3)
	lda_dri3 XBC, 0x07, 0xe8, 0xe4
	ldto_berp A, 0xfb
	extz wa
	ld de, wa
	sla de, 3
	ldada xhl, 51836
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	ld a, (xbc)
	lda_dri3 XBC, 0x07, 0xec, 0xe8
	ldto_berp A, 0xfb
	extz wa
	ld de, wa
	sla de, 3
	ldada xhl, 51839
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	ld a, (xbc + 2)
	res 7, a
	lda_dri3 XBC, 0x07, 0xec, 0xe8
	ldto_berp A, 0xfb
	extz wa
	ld de, wa
	sla de, 3
	ldada xhl, 51840
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	ld a, (xbc + 3)
	lda_dri3 XBC, 0x07, 0xec, 0xe8
	ldto_berp A, 0xfb
	extz wa
	ld de, wa
	sla de, 3
	ldada xhl, 51837
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	ld a, (xbc + 1)
	lda_dri3 XBC, 0x07, 0xec, 0xe8
	ldto_berp A, 0xfb
	extz wa
	ld bc, wa
	sla bc, 3
	ldada xde, 51838
	ld a, (xsp + 10)
	lda_dri3 XBC, 0x07, 0xe8, 0xe4
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, (xsp + 6)
	calr NoteMap_SwapVoiceLinks
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld a, (xsp + 4)
	ld e, a
	extz de
	ld xwa, (xsp + 6)
	calr NoteMap_LinkVoiceSlots
	jrl Voice_LoopAdvance_Next

FindEntry_LoadParam2:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	setm 1, (xbc + 4)
	jrl Voice_LoopAdvance_Next

FindEntry_LoadParam3:
	ld a, (xsp + 10)
	ld c, a
	extz bc
	ld wa, (xsp + 2)
	extz wa
	pushw wa
	ld xwa, (xsp + 14)
	ld de, bc
	lds bc, 4
	calr LookupTableEntries_Prologue
	ldfr_berp L, 0xfb
	ldto_berp A, 0xfb
	cp a, (xsp + 4)
	jrl z, FindEntry_LoadParam4
	ld a, (xsp + 10)
	extz wa
	add wa, wa
	ldada xbc, 51819
	dec_srib 1, 0x07, 0xe4, 0xe0
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	ld xde, xbc
	add xde, (xsp + 12)
	ldto_berp A, 0xfb
	extz wa
	sla wa, 3
	ldada xbc, 51839
	ld_srib3 A, 0x07, 0xe4, 0xe0
	res 7, a
	ld (xde + 2), a
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	ld xde, xbc
	add xde, (xsp + 12)
	ldto_berp A, 0xfb
	extz wa
	sla wa, 3
	ldada xbc, 51840
	ld_srib3 A, 0x07, 0xe4, 0xe0
	ld (xde + 3), a
	ldada xde, 59760
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	calr NoteMap_SwapVoiceLinks
	ldada xde, 59760
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	ldw de, 0x20
	calr NoteMap_LinkVoiceSlots
	jr Voice_LoopAdvance_Next

FindEntry_LoadParam4:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	setm 1, (xbc + 4)

Voice_LoopAdvance_Next:
	incm 1, (xsp + 2)

LoopAdvance_Next_LoadParam:
	ld xwa, (xsp + 12)
	ld a, (xwa + 1)
	extz wa
	cp (xsp + 2), wa
	jrl c, FindEntry_LoadParam
	pop_werp 0xfa
	lda xsp, (xsp + 14)
	ret

NoteMap_FindBestVoiceSlot:
	lds hl, 0
	ldb d, 0x21
	ldb e, 0xff
	ldb d, 0x21
	jr NoteMap_FindEntry_AdvanceSlotD

FindBestVoiceSlot_LoadReg:
	ld c, d
	extz bc
	sla bc, 3
	ldada xix, 51834
	ld_srib3 C, 0x07, 0xf0, 0xe4
	cps c, 0
	jr z, FindBestVoiceSlot_Compare3
	cps c, 1
	jr z, FindBestVoiceSlot_Compare2
	cps c, 2
	jr z, FindBestVoiceSlot_Compare
	cps c, 3
	jr nz, FindBestVoiceSlot_ClearByte
	ldb e, 0x3
	jr NoteMap_FindEntry_AdvanceSlotD

FindBestVoiceSlot_Compare:
	cps e, 3
	jr z, NoteMap_FindEntry_AdvanceSlotD
	ldb e, 0x2
	jr NoteMap_FindEntry_AdvanceSlotD

FindBestVoiceSlot_Compare2:
	cps e, 3
	jr z, NoteMap_FindEntry_AdvanceSlotD
	cps e, 2
	jr z, NoteMap_FindEntry_AdvanceSlotD
	ldb e, 0x1
	jr NoteMap_FindEntry_AdvanceSlotD

FindBestVoiceSlot_Compare3:
	cps e, 3
	jr z, NoteMap_FindEntry_AdvanceSlotD
	cps e, 2
	jr z, NoteMap_FindEntry_AdvanceSlotD
	cps e, 1
	jr z, NoteMap_FindEntry_AdvanceSlotD
	ldb e, 0x0
	jr NoteMap_FindEntry_AdvanceSlotD

FindBestVoiceSlot_ClearByte:
	ldb e, 0x0

NoteMap_FindEntry_AdvanceSlotD:
	ld c, d
	extz bc
	add bc, bc
	ldada xix, 59761
	ld_srib3 D, 0x07, 0xf0, 0xe4
	ld c, d
	cp c, 0x21
	jr nz, FindBestVoiceSlot_LoadReg
	cp e, 0xff
	jr z, FindEntry_AdvanceSlo_Deref
	ldb d, 0x21
	jr FindEntry_AdvanceSlo_LoadReg2

FindEntry_AdvanceSlo_LoadReg:
	ld a, d
	extz wa
	sla wa, 3
	ldada xbc, 51834
	cp_srib_mr E, 0x07, 0xe4, 0xe0
	jr nz, FindEntry_AdvanceSlo_LoadReg2
	ld wa, hl
	add wa, wa
	inc 4, wa
	ldada xbc, 52992
	ld ix, wa
	extz xix
	add xix, xbc
	ld a, d
	extz wa
	sla wa, 3
	ldada xbc, 51839
	ld_srib3 A, 0x07, 0xe4, 0xe0
	res 7, a
	ld (xix), a
	ld wa, hl
	add wa, wa
	ldada xbc, 52995
	ld ix, wa
	extz xix
	add xix, xbc
	ld a, d
	extz wa
	sla wa, 3
	ldada xbc, 51837
	ld_srib3 A, 0x07, 0xe4, 0xe0
	ld (xix), a
	inc 1, hl

FindEntry_AdvanceSlo_LoadReg2:
	ld a, d
	extz wa
	add wa, wa
	ldada xbc, 59761
	ld_srib3 D, 0x07, 0xe4, 0xe0
	ld a, d
	cp a, 0x21
	jr nz, FindEntry_AdvanceSlo_LoadReg
	jr FindEntry_AdvanceSlo_StoreDRAM

FindEntry_AdvanceSlo_Deref:
	ld e, (xwa + 2)

FindEntry_AdvanceSlo_StoreDRAM:
	stda16 52991, xhl
	ld a, e
	extz wa
	stda16 52993, xwa
	ldada xwa, 52991
	push xwa
	call __jrt_nop_FEA344_Prologue
	inc 4, xsp
	call AccWrap_AutoPlayZoneTrack
	jp ProcessControllers_R_Prologue

NoteMap_MarkEntriesAboveThreshold:
	dec 6, xsp
	push xiz
	ld (xsp + 6), xwa
	ldw (xsp + 4), 0x0
	jrl MarkEntriesAboveThre_LoadParam2

MarkEntriesAboveThre_LoadParam:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	cp (xbc), 0x53
	jrl ule, MarkEntriesAboveThre_AdvanceSlot
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	setm 1, (xbc + 4)
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	cp (xbc + 1), 0x0
	jr z, MarkEntriesAboveThre_InitIdx
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	ld a, (xbc)
	sub a, 0x54
	extz wa
	add wa, wa
	lda_24 xbc, 0xee8f80
	ld_srib3 A, 0x07, 0xe4, 0xe0
	ldfr_berp A, 0xfa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	ld a, (xbc)
	sub a, 0x54
	extz wa
	add wa, wa
	lda_24 xbc, 0xee8f81
	ld_srib3 A, 0x07, 0xe4, 0xe0
	ldfr_berp A, 0xf9
	jr MarkEntriesAboveThre_LoadIdx

MarkEntriesAboveThre_InitIdx:
	ldi_berp 0xfa, 0
	ldi_berp 0xf9, 0

MarkEntriesAboveThre_LoadIdx:
	ldto_berp A, 0xfa
	xorda8 a, 52526
	ld e, a
	ldto_berp A, 0xf9
	xorda8 a, 52527
	ldfr_berp A, 0xfb
	cps e, 0
	jr z, MarkEntriesAboveThre_Block
	ldto_berp A, 0xfa
	ld c, a
	extz bc
	ld a, e
	extz wa
	pushw wa
	ld de, bc
	ldw wa, 0xa8
	ldw bc, 0xb
	call AddswbWr

MarkEntriesAboveThre_Block:
	cpi_berp 0xfb, 0
	jr z, MarkEntriesAboveThre_LoadIdx2
	ldto_berp A, 0xf9
	ld c, a
	extz bc
	ldto_berp A, 0xfb
	extz wa
	pushw wa
	ld de, bc
	ldw wa, 0xa8
	ldw bc, 0xc
	call AddswbWr

MarkEntriesAboveThre_LoadIdx2:
	ldto_berp A, 0xfa
	stda8 52526, a
	ldto_berp A, 0xf9
	stda8 52527, a

MarkEntriesAboveThre_AdvanceSlot:
	incm 1, (xsp + 4)

MarkEntriesAboveThre_LoadParam2:
	ld xwa, (xsp + 6)
	ld a, (xwa + 1)
	extz wa
	cp (xsp + 4), wa
	jrl c, MarkEntriesAboveThre_LoadParam
	pop xiz
	inc 6, xsp
	ret

NoteMap_FindBestFreeVoice:
	lds de, 0
	ldb h, 0x23
	ldb l, 0xff
	jr NoteMap_FindBestFreeVoice_AdvanceSlotH

FindBestFreeVoice_LoadReg:
	ld c, h
	extz bc
	sla bc, 3
	ldada xix, 51834
	ld_srib3 C, 0x07, 0xf0, 0xe4
	cps c, 0
	jr z, FindBestFreeVoice_Compare3
	cps c, 1
	jr z, FindBestFreeVoice_Compare2
	cps c, 2
	jr z, FindBestFreeVoice_Compare
	cps c, 3
	jr nz, NoteMap_FindBestFreeVoice_AdvanceSlotH
	ldb l, 0x2
	jr NoteMap_FindBestFreeVoice_AdvanceSlotH

FindBestFreeVoice_Compare:
	cps l, 3
	jr z, NoteMap_FindBestFreeVoice_AdvanceSlotH
	ldb l, 0x2
	jr NoteMap_FindBestFreeVoice_AdvanceSlotH

FindBestFreeVoice_Compare2:
	cps l, 3
	jr z, NoteMap_FindBestFreeVoice_AdvanceSlotH
	cps l, 2
	jr z, NoteMap_FindBestFreeVoice_AdvanceSlotH
	ldb l, 0x1
	jr NoteMap_FindBestFreeVoice_AdvanceSlotH

FindBestFreeVoice_Compare3:
	cps l, 3
	jr z, NoteMap_FindBestFreeVoice_AdvanceSlotH
	cps l, 2
	jr z, NoteMap_FindBestFreeVoice_AdvanceSlotH
	cps l, 1
	jr z, NoteMap_FindBestFreeVoice_AdvanceSlotH
	ldb l, 0x0

NoteMap_FindBestFreeVoice_AdvanceSlotH:
	ld c, h
	extz bc
	add bc, bc
	ldada xix, 59761
	ld_srib3 H, 0x07, 0xf0, 0xe4
	ld c, h
	cp c, 0x23
	jr nz, FindBestFreeVoice_LoadReg
	cp l, 0xff
	jr z, FindBestFreeVoice_Ad_Deref
	ldb h, 0x23
	jr FindBestFreeVoice_Ad_LoadReg2

FindBestFreeVoice_Ad_LoadReg:
	ld a, h
	extz wa
	sla wa, 3
	ldada xbc, 51834
	cp_srib_mr L, 0x07, 0xe4, 0xe0
	jr nz, FindBestFreeVoice_Ad_LoadReg2
	ld wa, de
	add wa, wa
	inc 4, wa
	ldada xbc, 52771
	ld ix, wa
	extz xix
	add xix, xbc
	ld a, h
	extz wa
	sla wa, 3
	ldada xbc, 51839
	ld_srib3 A, 0x07, 0xe4, 0xe0
	res 7, a
	ld (xix), a
	ld wa, de
	add wa, wa
	ldada xbc, 52774
	ld ix, wa
	extz xix
	add xix, xbc
	ld a, h
	extz wa
	sla wa, 3
	ldada xbc, 51837
	ld_srib3 A, 0x07, 0xe4, 0xe0
	ld (xix), a
	inc 1, de

FindBestFreeVoice_Ad_LoadReg2:
	ld a, h
	extz wa
	add wa, wa
	ldada xbc, 59761
	ld_srib3 H, 0x07, 0xe4, 0xe0
	ld a, h
	cp a, 0x23
	jr nz, FindBestFreeVoice_Ad_LoadReg
	jr FindBestFreeVoice_Ad_StoreDRAM

FindBestFreeVoice_Ad_Deref:
	ld l, (xwa + 2)

FindBestFreeVoice_Ad_StoreDRAM:
	stda16 52770, xde
	ld a, l
	extz wa
	stda16 52772, xwa
	ret

NoteMap_EmitNoteOnEvents:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), c
	ld (xsp + 4), xwa
	cp (xsp + 2), 0xff
	jrl z, SynthVoice_Return
	lds bc, 0
	lds iz, 0
	jrl SynthVoice_CheckVoiceCount

SynthVoice_WriteLoop:
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	inc 4, xde
	add xde, (xsp + 4)
	bitm 1, (xde + 4)
	jrl nz, Synth_WriteVoiceData_CheckSize
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	inc 4, xde
	add xde, (xsp + 4)
	cp (xde + 2), 0xff
	jr z, Synth_WriteVoiceData_CheckSize
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	inc 4, xde
	add xde, (xsp + 4)
	cp (xde + 1), 0x0
	jr z, Synth_WriteVoiceData_CheckSize
	ld wa, bc
	mul wa, 0x3
	ldada xde, 52528
	ld hl, wa
	extz xhl
	add xhl, xde
	ld a, (xsp + 2)
	or a, 0x90
	ld (xhl), a
	ld wa, bc
	mul wa, 0x3
	ldada xde, 52529
	ld hl, wa
	extz xhl
	add xhl, xde
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	inc 4, xde
	add xde, (xsp + 4)
	ld a, (xde + 2)
	res 7, a
	ld (xhl), a
	ld wa, bc
	mul wa, 0x3
	ldada xde, 52530
	ld hl, wa
	extz xhl
	add xhl, xde
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	inc 4, xde
	add xde, (xsp + 4)
	ld a, (xde + 1)
	ld (xhl), a
	inc 1, bc

Synth_WriteVoiceData_CheckSize:
	cps bc, 0
	jr z, SynthVoice_NextVoice
	cps bc, 6
	jr z, SynthVoice_FlushBuffer
	ld xwa, (xsp + 4)
	ld a, (xwa + 1)
	dec 1, a
	extz wa
	cp wa, iz
	jr nz, SynthVoice_NextVoice

SynthVoice_FlushBuffer:
	ld xwa, 0xcd30
	push xwa
	ld wa, bc
	mul wa, 0x3
	pushw wa
	call AltEvtBuf_WriteBytes
	inc 6, xsp
	lds bc, 0

SynthVoice_NextVoice:
	inc 1, iz

SynthVoice_CheckVoiceCount:
	ld xwa, (xsp + 4)
	ld a, (xwa + 1)
	extz wa
	cp iz, wa
	jrl c, SynthVoice_WriteLoop

SynthVoice_Return:
	popw iz
	inc 6, xsp
	ret

; ============================================================================
; NoteMap_MergeEntries - Filter and merge note mapping table entries
; ============================================================================
; Input:  XWA = destination table, XBC = source table, XDE = filter params
; Output: L = count of merged entries
; Copies 3-byte header, then iterates source entries (5 bytes each),
; filtering by note range (upper/lower bounds via bit masking).
; Matching entries are copied using ldirw + ldi85 (5-byte copy).
; ============================================================================
NoteMap_MergeEntries:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xde, xbc
	ld xiz, xwa
	ld a, (xde)
	ld (xiz), a
	ld a, (xde + 2)
	ld (xiz + 2), a
	ld a, (xde + 3)
	ld (xiz + 3), a
	lds wa, 0
	lds hl, 0
	jr MergeEntries_CheckCount

MergeEntries_FilterLoop:
	ld bc, hl
	extz xbc
	ld xix, xbc
	sll xix, 2
	add xix, xbc
	inc 4, xix
	add xix, xde
	ld xbc, (xsp + 4)
	ld c, (xbc + 1)
	srl c, 1
	cp c, (xix)
	jr ugt, MergeEntries_NextEntry
	ld bc, hl
	extz xbc
	ld xix, xbc
	sll xix, 2
	add xix, xbc
	inc 4, xix
	add xix, xde
	ld xbc, (xsp + 4)
	ld c, (xbc)
	res 7, c
	cp (xix), c
	jr ugt, MergeEntries_NextEntry
	ld bc, wa
	extz xbc
	ld xix, xbc
	sll xix, 2
	add xix, xbc
	inc 4, xix
	add xix, xiz
	ld bc, hl
	extz xbc
	ld xiy, xbc
	sll xiy, 2
	add xiy, xbc
	inc 4, xiy
	add xiy, xde
	lds bc, 2
	ldirw
	ldi85
	inc 1, wa

MergeEntries_NextEntry:
	inc 1, hl

MergeEntries_CheckCount:
	ld c, (xde + 1)
	extz bc
	cp hl, bc
	jr c, MergeEntries_FilterLoop
	ld l, a
	ld (xiz + 1), l
	pop xiz
	inc 4, xsp
	ret

NoteMap_ResetEntryTimers:
	lda xsp, (xsp - 20)
	push_werp 0xfa
	ld (xsp + 16), e
	ld (xsp + 18), xwa
	cpdi8 36150, 152
	jr nz, ResetTimers_Return
	ldw (xsp + 2), 0x0
	jr ResetTimers_CheckCount

ResetTimers_Loop:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 18)
	cp (xbc + 1), 0x0
	jr z, ResetTimers_Loop_AdvanceSlot
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 18)
	ldmi16 (xbc + 2), 0x2786
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 18)
	ldmi16 (xbc + 3), 0x2786

ResetTimers_Loop_AdvanceSlot:
	incm 1, (xsp + 2)

ResetTimers_CheckCount:
	ld xwa, (xsp + 18)
	ld a, (xwa + 1)
	extz wa
	cp (xsp + 2), wa
	jr c, ResetTimers_Loop
	jrl StoreChannelResult_RestoreReg

ResetTimers_Return:
	cp (xsp + 16), 0x13
	jr nz, ResetTimers_Return_LoadParam
	ld a, (xsp + 16)
	extz wa
	add wa, wa
	add wa, 0x124
	exts xwa
	add xwa, xbc
	ld e, (xwa + 1)
	sra e, 4
	ld a, (xsp + 16)
	extz wa
	add wa, wa
	add wa, 0x124
	ld_srib3 A, 0x07, 0xe4, 0xe0
	sll a, 4
	sra a, 5
	muls a, 0xc
	ld (xsp + 6), a
	add (xsp + 6), e
	ld a, (xsp + 16)
	extz wa
	add wa, wa
	add wa, 0xe4
	st_dri3b A, 0x07, 0xe4, 0xe0
	ldb a, 0xf4
	add a, (xbc + 1)
	ld (xsp + 4), a
	jr ResetTimers_Return_LoadParam2

ResetTimers_Return_LoadParam:
	ld a, (xsp + 16)
	extz wa
	add wa, wa
	add wa, 0x124
	exts xwa
	add xwa, xbc
	ld e, (xwa + 1)
	sra e, 4
	ld a, (xsp + 16)
	extz wa
	add wa, wa
	add wa, 0x124
	ld_srib3 A, 0x07, 0xe4, 0xe0
	sll a, 4
	sra a, 5
	muls a, 0xc
	ld (xsp + 6), a
	add (xsp + 6), e
	ld a, (xsp + 16)
	extz wa
	add wa, wa
	add wa, 0xe4
	exts xwa
	add xwa, xbc
	ld a, (xwa + 1)
	ld (xsp + 4), a

ResetTimers_Return_LoadParam2:
	ld a, (xsp + 16)
	extz wa
	lds bc, 0
	call SndParam_LookupViaEncode
	ld (xsp + 12), hl
	ld a, (xsp + 16)
	extz wa
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	ld (xsp + 14), hl
	ld (xsp + 8), 0x2
	ld xwa, 0x2205
	call SndParam_LookupReadOnly
	cps hl, 3
	jr z, ResetTimers_Return_LoadParam4
	cps hl, 1
	jr z, ResetTimers_Return_LoadParam3
	cps hl, 0
	jr nz, Synth_WriteChannelMod_Loop
	ld (xsp + 10), 0x1
	ldb a, 0x2
	jr Synth_WriteChannelMod_Loop

ResetTimers_Return_LoadParam3:
	ld (xsp + 10), 0xff
	ldb a, 0xff
	jr Synth_WriteChannelMod_Loop

ResetTimers_Return_LoadParam4:
	ld (xsp + 10), 0x3
	ldb a, 0x4

Synth_WriteChannelMod_Loop:
	ldw (xsp + 2), 0x0
	jrl StoreChannelResult_LoadParam

WriteChannelMod_Loop_LoadParam:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 18)
	ld (xbc + 4), 0x0
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 18)
	cp (xbc + 1), 0x0
	jrl z, StoreChannelResult_AdvanceSlot
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 18)
	ld a, (xbc)
	ldfr_berp A, 0xfb
	ld wa, (xsp + 12)
	ld e, a
	extz de
	ld wa, (xsp + 14)
	ld c, a
	extz bc
	ld wa, de
	calr Note_CheckTransposeRange
	cps l, 0
	jr nz, WriteChannelMod_Loop_CheckEnd
	cp (xsp + 4), 0x0
	jr z, SndParam_ApplyChannelEntry
	ldto_berp A, 0xfb
	add a, (xsp + 4)
	ldfr_berp A, 0xfb
	cp a, 0x7f
	jr ule, SndParam_ApplyChannelEntry
	cp (xsp + 6), 0x0
	jr le, WriteChannelMod_Loop_LoadIdx
	ldto_berp A, 0xfb
	cp a, 0x7f
	jr ule, SndParam_ApplyChannelEntry

WriteChannelMod_Loop_AdjustIdx:
	sub_erpb 0xfb, 0x0c
	ldto_berp A, 0xfb
	cp a, 0x7f
	jr ugt, WriteChannelMod_Loop_AdjustIdx
	jr SndParam_ApplyChannelEntry

WriteChannelMod_Loop_LoadIdx:
	ldto_berp A, 0xfb
	cps a, 0
	jr ge, SndParam_ApplyChannelEntry

WriteChannelMod_Loop_AdjustIdx2:
	add_erpb 0xfb, 0x0c
	ldto_berp A, 0xfb
	cps a, 0
	jr lt, WriteChannelMod_Loop_AdjustIdx2
	jr SndParam_ApplyChannelEntry

WriteChannelMod_Loop_CheckEnd:
	cp (xsp + 8), 0xff
	jr z, SndParam_ApplyChannelEntry
	ld a, (xsp + 8)
	ld l, a
	extz hl
	ld wa, (xsp + 12)
	ld c, a
	extz bc
	ld wa, (xsp + 14)
	ld e, a
	extz de
	ldto_berp A, 0xfb
	extz wa
	pushw wa
	ld wa, hl
	call SndParam_LookupByChannel
	ldfr_berp L, 0xfb

SndParam_ApplyChannelEntry:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 18)
	ldto_berp A, 0xfb
	ld (xbc + 2), a
	ld wa, (xsp + 12)
	ld e, a
	extz de
	ld wa, (xsp + 14)
	ld c, a
	extz bc
	ld wa, de
	calr Note_CheckTransposeRange
	cps l, 0
	jr nz, ApplyChannelEntry_CheckEnd
	cp (xsp + 6), 0x0
	jr z, ApplyChannelEntry_CheckIdx
	ldto_berp A, 0xfb
	add a, (xsp + 6)
	ldfr_berp A, 0xfb
	cp a, 0x7f
	jr ule, ApplyChannelEntry_CheckIdx
	cp (xsp + 6), 0x0
	jr le, ApplyChannelEntry_LoadIdx
	ldto_berp A, 0xfb
	cp a, 0x7f
	jr ule, ApplyChannelEntry_CheckIdx

ApplyChannelEntry_AdjustIdx:
	sub_erpb 0xfb, 0x0c
	ldto_berp A, 0xfb
	cp a, 0x7f
	jr ugt, ApplyChannelEntry_AdjustIdx
	jr ApplyChannelEntry_CheckIdx

ApplyChannelEntry_LoadIdx:
	ldto_berp A, 0xfb
	cps a, 0
	jr ge, ApplyChannelEntry_CheckIdx

ApplyChannelEntry_AdjustIdx2:
	add_erpb 0xfb, 0x0c
	ldto_berp A, 0xfb
	cps a, 0
	jr lt, ApplyChannelEntry_AdjustIdx2

ApplyChannelEntry_CheckIdx:
	cp_erpb 0xfb, 0x78
	jr c, SndParam_StoreChannelResult
	ldi_erpb 0xfb, 0xff
	jr SndParam_StoreChannelResult

ApplyChannelEntry_CheckEnd:
	cp (xsp + 10), 0xff
	jr z, SndParam_StoreChannelResult
	cp_erpb 0xfb, 0xff
	jr z, SndParam_StoreChannelResult
	ld a, (xsp + 10)
	ld l, a
	extz hl
	ld wa, (xsp + 12)
	ld c, a
	extz bc
	ld wa, (xsp + 14)
	ld e, a
	extz de
	ldto_berp A, 0xfb
	extz wa
	pushw wa
	ld wa, hl
	call SndParam_LookupByChannel
	ldfr_berp L, 0xfb

SndParam_StoreChannelResult:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 18)
	ldto_berp A, 0xfb
	ld (xbc + 3), a

StoreChannelResult_AdvanceSlot:
	incm 1, (xsp + 2)

StoreChannelResult_LoadParam:
	ld xwa, (xsp + 18)
	ld a, (xwa + 1)
	extz wa
	cp (xsp + 2), wa
	jrl c, WriteChannelMod_Loop_LoadParam

StoreChannelResult_RestoreReg:
	pop_werp 0xfa
	lda xsp, (xsp + 20)
	ret

Voice_ApplyTransposeWithEncode:
	lda xsp, (xsp - 18)
	push_werp 0xfa
	ld (xsp + 14), e
	ld (xsp + 16), xwa
	ld a, (xsp + 14)
	extz wa
	add wa, wa
	add wa, 0x124
	ld_srib3 A, 0x07, 0xe4, 0xe0
	sll a, 4
	sra a, 5
	muls a, 0xc
	neg a
	ld (xsp + 4), a
	ld a, (xsp + 14)
	extz wa
	lds bc, 0
	call SndParam_LookupViaEncode
	ld (xsp + 10), hl
	ld a, (xsp + 14)
	extz wa
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	ld (xsp + 12), hl
	ldb a, 0x2
	ld xwa, 0x2205
	call SndParam_LookupReadOnly
	cps hl, 3
	jr z, ApplyTransposeWithEn_LoadParam2
	cps hl, 1
	jr z, ApplyTransposeWithEn_LoadParam
	cps hl, 0
	jr nz, Synth_WriteChannelDelay_Loop
	ld (xsp + 8), 0x1
	ld (xsp + 6), 0x2
	jr Synth_WriteChannelDelay_Loop

ApplyTransposeWithEn_LoadParam:
	ld (xsp + 8), 0xff
	ld (xsp + 6), 0xff
	jr Synth_WriteChannelDelay_Loop

ApplyTransposeWithEn_LoadParam2:
	ld (xsp + 8), 0x3
	ld (xsp + 6), 0x4

Synth_WriteChannelDelay_Loop:
	ldw (xsp + 2), 0x0
	jrl WriteChannelDelay_Lo_LoadParam4

WriteChannelDelay_Lo_LoadParam:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 16)
	ld (xbc + 4), 0x0
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 16)
	cp (xbc + 1), 0x0
	jrl z, WriteChannelDelay_Lo_AdvanceSlot
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 16)
	ld a, (xbc)
	ldfr_berp A, 0xfb
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 16)
	ldto_berp A, 0xfb
	ld (xbc + 3), a
	cp (xsp + 4), 0x0
	jr z, WriteChannelDelay_Lo_LoadParam2
	ldto_berp A, 0xfb
	add a, (xsp + 4)
	ldfr_berp A, 0xfb
	cp a, 0x7f
	jr ule, WriteChannelDelay_Lo_LoadParam2
	cp (xsp + 4), 0x0
	jr le, WriteChannelDelay_Lo_LoadIdx
	ldto_berp A, 0xfb
	cp a, 0x7f
	jr ule, WriteChannelDelay_Lo_LoadParam2

WriteChannelDelay_Lo_AdjustIdx:
	sub_erpb 0xfb, 0x0c
	ldto_berp A, 0xfb
	cp a, 0x7f
	jr ugt, WriteChannelDelay_Lo_AdjustIdx
	jr WriteChannelDelay_Lo_LoadParam2

WriteChannelDelay_Lo_LoadIdx:
	ldto_berp A, 0xfb
	cps a, 0
	jr ge, WriteChannelDelay_Lo_LoadParam2

WriteChannelDelay_Lo_AdjustIdx2:
	add_erpb 0xfb, 0x0c
	ldto_berp A, 0xfb
	cps a, 0
	jr lt, WriteChannelDelay_Lo_AdjustIdx2

WriteChannelDelay_Lo_LoadParam2:
	ld wa, (xsp + 10)
	ld e, a
	extz de
	ld wa, (xsp + 12)
	ld c, a
	extz bc
	ld wa, de
	calr Note_CheckTransposeRange
	cps l, 0
	jr z, WriteChannelDelay_Lo_LoadParam3
	cp (xsp + 8), 0xff
	jr z, WriteChannelDelay_Lo_LoadParam3
	ld a, (xsp + 6)
	ld l, a
	extz hl
	ld wa, (xsp + 10)
	ld c, a
	extz bc
	ld wa, (xsp + 12)
	ld e, a
	extz de
	ldto_berp A, 0xfb
	extz wa
	pushw wa
	ld wa, hl
	call SndParam_LookupByChannel
	ldfr_berp L, 0xfb

WriteChannelDelay_Lo_LoadParam3:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 16)
	ldto_berp A, 0xfb
	ld (xbc + 2), a

WriteChannelDelay_Lo_AdvanceSlot:
	incm 1, (xsp + 2)

WriteChannelDelay_Lo_LoadParam4:
	ld xwa, (xsp + 16)
	ld a, (xwa + 1)
	extz wa
	cp (xsp + 2), wa
	jrl c, WriteChannelDelay_Lo_LoadParam
	pop_werp 0xfa
	lda xsp, (xsp + 18)
	ret

SndParam_ComputeVoiceTuning:
	lda xsp, (xsp - 16)
	push_werp 0xfa
	ld (xsp + 12), e
	ld (xsp + 14), xwa
	ld a, (xsp + 12)
	extz wa
	add wa, wa
	add wa, 0x124
	exts xwa
	add xwa, xbc
	ld e, (xwa + 1)
	sra e, 4
	ld a, (xsp + 12)
	extz wa
	add wa, wa
	add wa, 0x124
	ld_srib3 A, 0x07, 0xe4, 0xe0
	sll a, 4
	sra a, 5
	muls a, 0xc
	ld (xsp + 4), a
	add (xsp + 4), e
	ld a, (xsp + 12)
	extz wa
	lds bc, 0
	call SndParam_LookupViaEncode
	ld (xsp + 8), hl
	ld a, (xsp + 12)
	extz wa
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	ld (xsp + 10), hl
	ldb a, 0x2
	ld xwa, 0x2205
	call SndParam_LookupReadOnly
	cps hl, 3
	jr z, ComputeVoiceTuning_LoadParam2
	cps hl, 1
	jr z, ComputeVoiceTuning_LoadParam
	cps hl, 0
	jr nz, Synth_WriteChannelGain_Loop
	ld (xsp + 6), 0x1
	ldb a, 0x2
	jr Synth_WriteChannelGain_Loop

ComputeVoiceTuning_LoadParam:
	ld (xsp + 6), 0xff
	ldb a, 0xff
	jr Synth_WriteChannelGain_Loop

ComputeVoiceTuning_LoadParam2:
	ld (xsp + 6), 0x3
	ldb a, 0x4

Synth_WriteChannelGain_Loop:
	ldw (xsp + 2), 0x0
	jrl Synth_WriteParam_Check

Synth_WriteParam_Loop:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 14)
	ld (xbc + 4), 0x0
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 14)
	cp (xbc + 1), 0x0
	jrl z, Synth_WriteParam_Next
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 14)
	ld a, (xbc)
	ldfr_berp A, 0xfb
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 14)
	ldto_berp A, 0xfb
	ld (xbc + 2), a
	ld wa, (xsp + 8)
	ld e, a
	extz de
	ld wa, (xsp + 10)
	ld c, a
	extz bc
	ld wa, de
	calr Note_CheckTransposeRange
	cps l, 0
	jr nz, TransposeRange_LookupParam
	cp (xsp + 4), 0x0
	jr z, TransposeRange_Clamp
	ldto_berp A, 0xfb
	add a, (xsp + 4)
	ldfr_berp A, 0xfb
	cp a, 0x7f
	jr ule, TransposeRange_Clamp
	cp (xsp + 4), 0x0
	jr le, TransposeRange_CheckLow
	ldto_berp A, 0xfb
	cp a, 0x7f
	jr ule, TransposeRange_Clamp

TransposeRange_OctaveDown:
	sub_erpb 0xfb, 0x0c
	ldto_berp A, 0xfb
	cp a, 0x7f
	jr ugt, TransposeRange_OctaveDown
	jr TransposeRange_Clamp

TransposeRange_CheckLow:
	ldto_berp A, 0xfb
	cps a, 0
	jr ge, TransposeRange_Clamp

TransposeRange_OctaveUp:
	add_erpb 0xfb, 0x0c
	ldto_berp A, 0xfb
	cps a, 0
	jr lt, TransposeRange_OctaveUp

TransposeRange_Clamp:
	cp_erpb 0xfb, 0x78
	jr c, Synth_WriteChannelParam
	ldi_erpb 0xfb, 0xff
	jr Synth_WriteChannelParam

TransposeRange_LookupParam:
	cp (xsp + 6), 0xff
	jr z, Synth_WriteChannelParam
	ld a, (xsp + 6)
	ld l, a
	extz hl
	ld wa, (xsp + 8)
	ld c, a
	extz bc
	ld wa, (xsp + 10)
	ld e, a
	extz de
	ldto_berp A, 0xfb
	extz wa
	pushw wa
	ld wa, hl
	call SndParam_LookupByChannel
	ldfr_berp L, 0xfb

Synth_WriteChannelParam:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 14)
	ldto_berp A, 0xfb
	ld (xbc + 3), a

Synth_WriteParam_Next:
	incm 1, (xsp + 2)

Synth_WriteParam_Check:
	ld xwa, (xsp + 14)
	ld a, (xwa + 1)
	extz wa
	cp (xsp + 2), wa
	jrl c, Synth_WriteParam_Loop
	pop_werp 0xfa
	lda xsp, (xsp + 16)
	ret

NoteMap_ComputePitchOffset:
	lda xsp, (xsp - 16)
	push_werp 0xfa
	ld (xsp + 12), e
	ld (xsp + 14), xwa
	ld a, (xsp + 12)
	extz wa
	add wa, wa
	add wa, 0x124
	exts xwa
	add xwa, xbc
	ld e, (xwa + 1)
	sra e, 4
	ld a, (xsp + 12)
	extz wa
	add wa, wa
	add wa, 0x124
	ld_srib3 A, 0x07, 0xe4, 0xe0
	sll a, 4
	sra a, 5
	muls a, 0xc
	ld (xsp + 4), a
	add (xsp + 4), e
	ld a, (xsp + 12)
	extz wa
	lds bc, 0
	call SndParam_LookupViaEncode
	ld (xsp + 8), hl
	ld a, (xsp + 12)
	extz wa
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	ld (xsp + 10), hl
	ldb a, 0x2
	ld xwa, 0x2205
	call SndParam_LookupReadOnly
	cps hl, 3
	jr z, PitchOffset_BothDirs
	cps hl, 1
	jr z, PitchOffset_NegativeDir
	cps hl, 0
	jr nz, Synth_InitChannelState_Loop
	ld (xsp + 6), 0x1
	ldb a, 0x2
	jr Synth_InitChannelState_Loop

PitchOffset_NegativeDir:
	ld (xsp + 6), 0xff
	ldb a, 0xff
	jr Synth_InitChannelState_Loop

PitchOffset_BothDirs:
	ld (xsp + 6), 0x3
	ldb a, 0x4

Synth_InitChannelState_Loop:
	ldw (xsp + 2), 0x0
	jrl Synth_InitChannelState_Check

Synth_InitChannelState_Body:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 14)
	ld (xbc + 4), 0x0
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 14)
	cp (xbc + 1), 0x0
	jrl z, Synth_InitChannelState_Next
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 14)
	ld a, (xbc)
	ldfr_berp A, 0xfb
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 14)
	ldto_berp A, 0xfb
	ld (xbc + 2), a
	ld wa, (xsp + 8)
	ld e, a
	extz de
	ld wa, (xsp + 10)
	ld c, a
	extz bc
	ld wa, de
	calr Note_CheckTransposeRange
	cps l, 0
	jr nz, Synth_SkipTranspose
	cp (xsp + 4), 0x0
	jr z, Synth_StoreTransposedNote
	ldto_berp A, 0xfb
	add a, (xsp + 4)
	ldfr_berp A, 0xfb
	cp a, 0x7f
	jr ule, Synth_StoreTransposedNote
	cp (xsp + 4), 0x0
	jr le, Synth_CheckNegative
	ldto_berp A, 0xfb
	cp a, 0x7f
	jr ule, Synth_StoreTransposedNote

Synth_OctaveDown_Loop:
	sub_erpb 0xfb, 0x0c
	ldto_berp A, 0xfb
	cp a, 0x7f
	jr ugt, Synth_OctaveDown_Loop
	jr Synth_StoreTransposedNote

Synth_CheckNegative:
	ldto_berp A, 0xfb
	cps a, 0
	jr ge, Synth_StoreTransposedNote

CheckNegative_AdjustIdx:
	add_erpb 0xfb, 0x0c
	ldto_berp A, 0xfb
	cps a, 0
	jr lt, CheckNegative_AdjustIdx

Synth_StoreTransposedNote:
	cp_erpb 0xfb, 0x78
	jr c, Synth_SetChannelTone_Continue
	ldi_erpb 0xfb, 0xff
	jr Synth_SetChannelTone_Continue

Synth_SkipTranspose:
	cp (xsp + 6), 0xff
	jr z, Synth_SetChannelTone_Continue
	ld a, (xsp + 6)
	ld l, a
	extz hl
	ld wa, (xsp + 8)
	ld c, a
	extz bc
	ld wa, (xsp + 10)
	ld e, a
	extz de
	ldto_berp A, 0xfb
	extz wa
	pushw wa
	ld wa, hl
	call SndParam_LookupByChannel
	ldfr_berp L, 0xfb

Synth_SetChannelTone_Continue:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 14)
	ldto_berp A, 0xfb
	ld (xbc + 3), a

Synth_InitChannelState_Next:
	incm 1, (xsp + 2)

Synth_InitChannelState_Check:
	ld xwa, (xsp + 14)
	ld a, (xwa + 1)
	extz wa
	cp (xsp + 2), wa
	jrl c, Synth_InitChannelState_Body
	pop_werp 0xfa
	lda xsp, (xsp + 16)
	ret

InitChannelState_Che_InitVal:
	lds hl, 0
	jr InitChannelState_Che_LoopCheck

InitChannelState_Che_LoopBody:
	ld bc, hl
	extz xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	inc 4, xde
	add xde, xwa
	ld (xde + 4), 0x0
	ld bc, hl
	extz xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	inc 4, xde
	add xde, xwa
	cp (xde + 1), 0x0
	jr z, InitChannelState_Che_NextIter
	ld bc, hl
	extz xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	inc 4, xde
	ld xix, xde
	add xix, xwa
	ld bc, hl
	extz xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	inc 4, xde
	add xde, xwa
	ld c, (xde)
	ld (xix + 2), c
	ld bc, hl
	extz xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	inc 4, xde
	ld xix, xde
	add xix, xwa
	ld bc, hl
	extz xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	inc 4, xde
	add xde, xwa
	ld c, (xde)
	ld (xix + 3), c

InitChannelState_Che_NextIter:
	inc 1, hl

InitChannelState_Che_LoopCheck:
	ld c, (xwa + 1)
	extz bc
	cp hl, bc
	jr c, InitChannelState_Che_LoopBody
	ret

Voice_SetTransposeAndAlloc:
	ld l, e
	extz hl
	add hl, hl
	add hl, 0x124
	exts xhl
	add xhl, xbc
	ld h, (xhl + 1)
	sra h, 4
	extz de
	add de, de
	add de, 0x124
	ld_srib3 C, 0x07, 0xe4, 0xe8
	sll c, 4
	sra c, 5
	muls c, 0xc
	ld l, c
	add l, h
	lds ix, 0
	jrl SetTransposeAndAlloc_Deref

SetTransposeAndAlloc_LoadReg:
	ld bc, ix
	extz xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	inc 4, xde
	add xde, xwa
	ld (xde + 4), 0x0
	ld bc, ix
	extz xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	inc 4, xde
	add xde, xwa
	cp (xde + 1), 0x0
	jr z, SetTransposeAndAlloc_NextIter
	ld bc, ix
	extz xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	inc 4, xde
	add xde, xwa
	ld h, (xde)
	ld bc, ix
	extz xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	inc 4, xde
	add xde, xwa
	ld (xde + 2), h
	cps l, 0
	jr z, SetTransposeAndAlloc_Compare
	add h, l
	ld c, h
	cp c, 0x7f
	jr ule, SetTransposeAndAlloc_Compare
	cps l, 0
	jr le, SetTransposeAndAlloc_LoadReg2
	ld c, h
	cp c, 0x7f
	jr ule, SetTransposeAndAlloc_Compare

SetTransposeAndAlloc_Compute:
	sub h, 0xc
	ld c, h
	cp c, 0x7f
	jr ugt, SetTransposeAndAlloc_Compute
	jr SetTransposeAndAlloc_Compare

SetTransposeAndAlloc_LoadReg2:
	ld c, h
	cps c, 0
	jr ge, SetTransposeAndAlloc_Compare

SetTransposeAndAlloc_Compute2:
	add h, 0xc
	ld c, h
	cps c, 0
	jr lt, SetTransposeAndAlloc_Compute2

SetTransposeAndAlloc_Compare:
	cp h, 0x78
	jr c, SetTransposeAndAlloc_LoadReg3
	ldb h, 0xff

SetTransposeAndAlloc_LoadReg3:
	ld bc, ix
	extz xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	inc 4, xde
	add xde, xwa
	ld (xde + 3), h

SetTransposeAndAlloc_NextIter:
	inc 1, ix

SetTransposeAndAlloc_Deref:
	ld c, (xwa + 1)
	extz bc
	cp ix, bc
	jrl c, SetTransposeAndAlloc_LoadReg
	ret

SndParam_UpdateChannelTuning:
	cp a, 0xff
	jr z, UpdateChannelTuning_LoadDRAM
	extz wa
	lda_24 xhl, CharMap_ValueData_A
	ldmm_srib 0x07, 0xec, 0xe0, 0x44, 0xcd
	ldda8 a, 52548
	extz wa
	add wa, wa
	ldada xhl, 59438
	ldmm_srib 0x07, 0xec, 0xe0, 0x42, 0xcd

UpdateChannelTuning_LoadDRAM:
	ldda8 a, 52546
	cpda8 a, 52548
	jr z, SelectTone_Continue_SetByteFF
	ldda8 a, 52546
	extz wa
	sla wa, 3
	ldada xhl, 50794
	cp_srib_mr C, 0x07, 0xec, 0xe0
	jr nz, SelectTone_Continue_SetByteFF
	cps e, 2
	jr z, UpdateChannelTuning_LoadDRAM3
	cps e, 1
	jr z, UpdateChannelTuning_LoadDRAM2
	cps e, 0
	jr nz, UpdateChannelTuning_SetByteFF
	ldda8 a, 52546
	extz wa
	sla wa, 3
	ldada xbc, 50796
	ld_srib3 L, 0x07, 0xe4, 0xe0
	jr Synth_SelectTone_Continue

UpdateChannelTuning_LoadDRAM2:
	ldda8 a, 52546
	extz wa
	sla wa, 3
	ldada xbc, 50799
	ld_srib3 L, 0x07, 0xe4, 0xe0
	jr Synth_SelectTone_Continue

UpdateChannelTuning_LoadDRAM3:
	ldda8 a, 52546
	extz wa
	sla wa, 3
	ldada xbc, 50800
	ld_srib3 L, 0x07, 0xe4, 0xe0
	jr Synth_SelectTone_Continue

UpdateChannelTuning_SetByteFF:
	ldb l, 0xff

Synth_SelectTone_Continue:
	ldda8 a, 52546
	extz wa
	add wa, wa
	ldada xbc, 59438
	ldmm_srib 0x07, 0xe4, 0xe0, 0x42, 0xcd
	jr SelectTone_Continue_Return

SelectTone_Continue_SetByteFF:
	ldb l, 0xff

SelectTone_Continue_Return:
	ret

SelectTone_Continue_Prologue:
	dec 6, xsp
	cpdi8 36150, 246
	jr nz, SelectTone_Continue_LoadReg
	lds wa, 0
	lds bc, 0
	call SndParam_LookupViaEncode
	ld (xsp + 3), l
	lds wa, 0
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	ld (xsp + 4), l
	ld (xsp + 2), 0x0
	lda xwa, (xsp)
	call SndParam_FetchOscTableEntry
	ld a, (xsp + 256)
	add a, 0xf0

SelectTone_Continue_LoadReg:
	ld l, a
	inc 6, xsp
	ret

Rhythm_DispatchCCCommand:
	dec 6, xsp
	ld (xsp + 256), 0x4
	ld (xsp + 1), 0x90
	ld (xsp + 2), 0x19
	ld (xsp + 3), a
	ld (xsp + 4), c
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	inc 6, xsp
	ret

Note_CheckTransposeRange:
	dec 4, xsp
	ld (xsp), c
	ld (xsp + 2), a
	ldb l, 0x0
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cps hl, 1
	jr nz, CheckTransposeRange_LoadParam
	cp (xsp), 0x78
	jr nz, CheckTransposeRange_ClearByte
	ldb l, 0x1
	jr UI_CheckControlCode_TestResult

CheckTransposeRange_ClearByte:
	ldb l, 0x0
	jr UI_CheckControlCode_TestResult

CheckTransposeRange_LoadParam:
	ld a, (xsp + 2)
	and a, 0xf0
	cp a, 0xf0
	jr nz, CheckTransposeRange_ClearByte2
	ldb l, 0x1
	jr UI_CheckControlCode_TestResult

CheckTransposeRange_ClearByte2:
	ldb l, 0x0

UI_CheckControlCode_TestResult:
	inc 4, xsp
	ret

CheckControlCode_Tes_WriteReg:
	st_dri3b L, 0xfd, 0x0e, 0xfe
	push_werp 0xfa
	lda_dri3 XIY, 0xfd, 0xee, 0x01
	lda_dri3 XHL, 0xfd, 0xf0, 0x01
	lda_dri3 XBC, 0xfd, 0xf2, 0x01
	stib_dri 0xfd, 0x4c, 0x01, 0x00
	stib_dri 0xfd, 0x4d, 0x01, 0x00
	st_dri3b W, 0xfd, 0x4a, 0x01
	call NoteMap_LookupAndMergeVoice
	cps l, 0
	jrl z, NoteMap_VoiceAssign_Finalize
	st_dri3b E, 0xfd, 0x4a, 0x01
	st_dri3b D, 0xfd, 0xa6, 0x00
	ldw bc, 0x52
	ldirw
	lds de, 0
	jr CheckControlCode_Tes_LoopCheck

CheckControlCode_Tes_LoopBody:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	st_dri3b W, 0xfd, 0xa7, 0x00
	add xwa, xbc
	ld (xwa), 0x0
	inc 1, de

CheckControlCode_Tes_LoopCheck:
	ld_srib A, (xsp + 0x00a7)
	extz wa
	cp de, wa
	jr c, CheckControlCode_Tes_LoopBody
	ld_srib A, (xsp + 0x01f2)
	cps a, 2
	jrl z, VoiceAssign_CheckBothParts
	cps a, 1
	jrl z, CollectEnabledVoices_CheckMem
	cps a, 0
	jrl nz, NoteMap_VoiceAssign_Finalize
	ld_srib A, (xsp + 0x01f0)
	xor_srib_rm A, 0xfd, 0xee, 0x01
	and_srib_rm A, 0xfd, 0xee, 0x01
	ldfr_berp A, 0xfb
	cps a, 0
	jrl z, NoteMap_AddChangedVoices
	bit_erpb 0xfb, 0x00
	jr z, CheckControlCode_Tes_TestBit0
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	ldada xwa, 50216
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, CheckControlCode_Tes_TestBit0
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 0
	call NoteMap_AddEntry

CheckControlCode_Tes_TestBit0:
	bit_erpb 0xfb, 0x01
	jr z, CheckControlCode_Tes_TestBit02
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	ldada xwa, 50220
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, CheckControlCode_Tes_TestBit02
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 1
	call NoteMap_AddEntry

CheckControlCode_Tes_TestBit02:
	bit_erpb 0xfb, 0x02
	jr z, CheckControlCode_Tes_TestBit03
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	ldada xwa, 50224
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, CheckControlCode_Tes_TestBit03
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 2
	call NoteMap_AddEntry

CheckControlCode_Tes_TestBit03:
	bit_erpb 0xfb, 0x03
	jr z, NoteMap_AddChangedVoices
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	ldada xwa, 50228
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, NoteMap_AddChangedVoices
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	ldw de, 0x15
	call NoteMap_AddEntry
	call AudioInit_RefreshToneBank

NoteMap_AddChangedVoices:
	ld_srib A, (xsp + 0x01f0)
	xor_srib_rm A, 0xfd, 0xee, 0x01
	and_srib_rm A, 0xfd, 0xf0, 0x01
	ldfr_berp A, 0xfb
	cps a, 0
	jrl z, NoteMap_CollectEnabledVoices
	bit_erpb 0xfb, 0x00
	jr z, AddChangedVoices_TestBit0
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xbc, xwa
	ldada xwa, 49858
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, AddChangedVoices_TestBit0
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 0
	call NoteMap_AddEntry

AddChangedVoices_TestBit0:
	bit_erpb 0xfb, 0x01
	jr z, AddChangedVoices_TestBit02
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xbc, xwa
	ldada xwa, 49862
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, AddChangedVoices_TestBit02
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 1
	call NoteMap_AddEntry

AddChangedVoices_TestBit02:
	bit_erpb 0xfb, 0x02
	jr z, AddChangedVoices_TestBit03
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xbc, xwa
	ldada xwa, 49866
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, AddChangedVoices_TestBit03
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 2
	call NoteMap_AddEntry

AddChangedVoices_TestBit03:
	bit_erpb 0xfb, 0x03
	jr z, NoteMap_CollectEnabledVoices
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xbc, xwa
	ldada xwa, 49870
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, NoteMap_CollectEnabledVoices
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	ldw de, 0x15
	call NoteMap_AddEntry

NoteMap_CollectEnabledVoices:
	ld_srib A, (xsp + 0x01f0)
	and_srib_rm A, 0xfd, 0xee, 0x01
	ldfr_berp A, 0xfb
	cps a, 0
	jrl z, NoteMap_VoiceAssign_Finalize
	bit_erpb 0xfb, 0x00
	jr z, CollectEnabledVoices_TestBit0
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xbc, xwa
	ldada xwa, 49858
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 0
	call NoteMap_CollectAndFindBestVoice

CollectEnabledVoices_TestBit0:
	bit_erpb 0xfb, 0x01
	jr z, CollectEnabledVoices_TestBit02
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xbc, xwa
	ldada xwa, 49862
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 1
	call NoteMap_CollectAndFindBestVoice

CollectEnabledVoices_TestBit02:
	bit_erpb 0xfb, 0x02
	jr z, CollectEnabledVoices_TestBit03
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xbc, xwa
	ldada xwa, 49866
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 2
	call NoteMap_CollectAndFindBestVoice

CollectEnabledVoices_TestBit03:
	bit_erpb 0xfb, 0x03
	jrl z, NoteMap_VoiceAssign_Finalize
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xbc, xwa
	ldada xwa, 49870
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	ldw de, 0x15
	call NoteMap_CollectAndFindBestVoice
	jrl NoteMap_VoiceAssign_Finalize

CollectEnabledVoices_CheckMem:
	cp_srib_im 0xfd, 0xf0, 0x01, 0xff
	jr z, CollectEnabledVoices_CheckMem2
	cp_srib_im 0xfd, 0xee, 0x01, 0xff
	jr z, CollectEnabledVoices_CheckMem2
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xhl, xwa
	ldada xbc, 50020
	ld_srib A, (xsp + 0x01ee)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_AddEntry
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xhl, xwa
	ldada xbc, 49662
	ld_srib A, (xsp + 0x01f0)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_AddEntry
	jrl NoteMap_VoiceAssign_Finalize

CollectEnabledVoices_CheckMem2:
	cp_srib_im 0xfd, 0xf0, 0x01, 0xff
	jrl nz, CollectEnabledVoices_CheckMem3
	cp_srib_im 0xfd, 0xee, 0x01, 0xff
	jrl z, CollectEnabledVoices_CheckMem3
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xhl, xwa
	ldada xbc, 50020
	ld_srib A, (xsp + 0x01ee)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_AddEntry
	bitda 0, 49662
	jr z, CollectEnabledVoices_TestBit1
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xbc, xwa
	ldada xwa, 49858
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, CollectEnabledVoices_TestBit1
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 0
	call NoteMap_AddEntry

CollectEnabledVoices_TestBit1:
	bitda 1, 49662
	jr z, CollectEnabledVoices_TestBit2
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xbc, xwa
	ldada xwa, 49862
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, CollectEnabledVoices_TestBit2
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 1
	call NoteMap_AddEntry

CollectEnabledVoices_TestBit2:
	bitda 2, 49662
	jrl z, NoteMap_VoiceAssign_Finalize
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xbc, xwa
	ldada xwa, 49866
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jrl z, NoteMap_VoiceAssign_Finalize
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 2
	call NoteMap_AddEntry
	jrl NoteMap_VoiceAssign_Finalize

CollectEnabledVoices_CheckMem3:
	cp_srib_im 0xfd, 0xf0, 0x01, 0xff
	jrl z, NoteMap_VoiceAssign_Finalize
	cp_srib_im 0xfd, 0xee, 0x01, 0xff
	jrl nz, NoteMap_VoiceAssign_Finalize
	bitda 0, 50020
	jr z, CollectEnabledVoices_TestBit12
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	ldada xwa, 50216
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, CollectEnabledVoices_TestBit12
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 0
	call NoteMap_AddEntry

CollectEnabledVoices_TestBit12:
	bitda 1, 50020
	jr z, CollectEnabledVoices_TestBit22
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	ldada xwa, 50220
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, CollectEnabledVoices_TestBit22
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 1
	call NoteMap_AddEntry

CollectEnabledVoices_TestBit22:
	bitda 2, 50020
	jr z, CollectEnabledVoices_WriteReg
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	ldada xwa, 50224
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, CollectEnabledVoices_WriteReg
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 2
	call NoteMap_AddEntry

CollectEnabledVoices_WriteReg:
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xhl, xwa
	ldada xbc, 49662
	ld_srib A, (xsp + 0x01f0)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_AddEntry
	jrl NoteMap_VoiceAssign_Finalize

VoiceAssign_CheckBothParts:
	cp_srib_im 0xfd, 0xf0, 0x01, 0xff
	jrl z, VoiceAssign_CheckSinglePart
	cp_srib_im 0xfd, 0xee, 0x01, 0xff
	jrl z, VoiceAssign_CheckSinglePart
	cpdi16 52840, 0
	jr nz, VoiceAssign_LookupAndLoop_Part1
	ldada xwa, 50020
	lds bc, 2
	call NoteMap_AssignVoiceParams

VoiceAssign_LookupAndLoop_Part1:
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jr z, VoiceAssign_MergeAndCollect_Part1

VoiceAssign_FindRetry_Part1:
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jr nz, VoiceAssign_FindRetry_Part1

VoiceAssign_MergeAndCollect_Part1:
	lda xwa, (xsp + 2)
	ld xix, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xhl, xwa
	ld_srib A, (xsp + 0x01f0)
	extz wa
	sla wa, 2
	add wa, 0xc4
	ldada xbc, 49662
	st_dri3b B, 0x07, 0xe4, 0xe0
	ld xwa, xix
	ld xbc, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jrl z, NoteMap_VoiceAssign_Finalize
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp + 2)
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_CollectMatchingEntries
	cps l, 0
	jrl z, NoteMap_VoiceAssign_Finalize
	lda xwa, (xsp + 2)
	ld xhl, xwa
	ldada xbc, 49662
	ld_srib A, (xsp + 0x01f0)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_ResetEntryTimers
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	cps l, 0
	jrl nz, NoteMap_VoiceAssign_Finalize
	call NoteMap_FindBestMatch
	cp l, 0xff
	jrl z, NoteMap_VoiceAssign_Finalize
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_InitVoiceSlots
	jrl NoteMap_VoiceAssign_Finalize

VoiceAssign_CheckSinglePart:
	cp_srib_im 0xfd, 0xf0, 0x01, 0xff
	jr nz, VoiceAssign_CheckOtherPart
	cp_srib_im 0xfd, 0xee, 0x01, 0xff
	jr z, VoiceAssign_CheckOtherPart
	cpdi16 52840, 0
	jr nz, VoiceAssign_LookupAndLoop_Part2
	ldada xwa, 50020
	lds bc, 2
	call NoteMap_AssignVoiceParams

VoiceAssign_LookupAndLoop_Part2:
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jrl z, NoteMap_VoiceAssign_Finalize

VoiceAssign_FindRetry_Part2:
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jr nz, VoiceAssign_FindRetry_Part2
	jrl NoteMap_VoiceAssign_Finalize

VoiceAssign_CheckOtherPart:
	cp_srib_im 0xfd, 0xf0, 0x01, 0xff
	jrl z, NoteMap_VoiceAssign_Finalize
	cp_srib_im 0xfd, 0xee, 0x01, 0xff
	jrl nz, NoteMap_VoiceAssign_Finalize
	lda xwa, (xsp + 2)
	ld xix, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xhl, xwa
	ld_srib A, (xsp + 0x01f0)
	extz wa
	sla wa, 2
	add wa, 0xc4
	ldada xbc, 49662
	st_dri3b B, 0x07, 0xe4, 0xe0
	ld xwa, xix
	ld xbc, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, NoteMap_VoiceAssign_Finalize
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp + 2)
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_CollectMatchingEntries
	cps l, 0
	jr z, NoteMap_VoiceAssign_Finalize
	lda xwa, (xsp + 2)
	ld xhl, xwa
	ldada xbc, 49662
	ld_srib A, (xsp + 0x01f0)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_ResetEntryTimers
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	cps l, 0
	jr nz, NoteMap_VoiceAssign_Finalize
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_VoiceAssign_Finalize
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_InitVoiceSlots

NoteMap_VoiceAssign_Finalize:
	stib_dri 0xfd, 0x4c, 0x01, 0x00
	stib_dri 0xfd, 0x4d, 0x01, 0x01
	st_dri3b W, 0xfd, 0x4a, 0x01
	call NoteMap_LookupAndMergeVoice
	cps l, 0
	jrl z, NoteMap_ReallocVoices_Exit
	st_dri3b W, 0xfd, 0x4a, 0x01
	ldada xbc, 49662
	lds de, 0
	call Voice_ApplyTransposeWithEncode
	st_dri3b E, 0xfd, 0x4a, 0x01
	st_dri3b D, 0xfd, 0xa6, 0x00
	ldw bc, 0x52
	ldirw
	lds de, 0
	jr VoiceAssign_Finalize_LoopCheck

VoiceAssign_Finalize_LoopBody:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	st_dri3b W, 0xfd, 0xa7, 0x00
	add xwa, xbc
	ld (xwa), 0x0
	inc 1, de

VoiceAssign_Finalize_LoopCheck:
	ld_srib A, (xsp + 0x00a7)
	extz wa
	cp de, wa
	jr c, VoiceAssign_Finalize_LoopBody
	ld_srib A, (xsp + 0x01f2)
	cps a, 2
	jrl z, ReallocEnabledVoices_CheckMem4
	cps a, 1
	jrl z, ReallocEnabledVoices_CheckMem
	cps a, 0
	jrl nz, NoteMap_ReallocVoices_Exit
	ld_srib A, (xsp + 0x01f0)
	xor_srib_rm A, 0xfd, 0xee, 0x01
	and_srib_rm A, 0xfd, 0xee, 0x01
	ldfr_berp A, 0xfb
	cps a, 0
	jrl z, NoteMap_UpdateChangedVoices
	bit_erpb 0xfb, 0x00
	jr z, VoiceAssign_Finalize_TestBit0
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	ldada xwa, 50216
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, VoiceAssign_Finalize_TestBit0
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 0
	call NoteMap_UpdateEntry

VoiceAssign_Finalize_TestBit0:
	bit_erpb 0xfb, 0x01
	jr z, VoiceAssign_Finalize_TestBit02
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	ldada xwa, 50220
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, VoiceAssign_Finalize_TestBit02
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 1
	call NoteMap_UpdateEntry

VoiceAssign_Finalize_TestBit02:
	bit_erpb 0xfb, 0x02
	jr z, VoiceAssign_Finalize_TestBit03
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	ldada xwa, 50224
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, VoiceAssign_Finalize_TestBit03
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 2
	call NoteMap_UpdateEntry

VoiceAssign_Finalize_TestBit03:
	bit_erpb 0xfb, 0x03
	jr z, NoteMap_UpdateChangedVoices
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	ldada xwa, 50228
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, NoteMap_UpdateChangedVoices
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	ldw de, 0x15
	call NoteMap_UpdateEntry
	call AudioInit_RefreshToneBank

NoteMap_UpdateChangedVoices:
	ld_srib A, (xsp + 0x01f0)
	xor_srib_rm A, 0xfd, 0xee, 0x01
	and_srib_rm A, 0xfd, 0xf0, 0x01
	ldfr_berp A, 0xfb
	cps a, 0
	jrl z, NoteMap_ReallocEnabledVoices
	bit_erpb 0xfb, 0x00
	jr z, UpdateChangedVoices_TestBit0
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xbc, xwa
	ldada xwa, 49858
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, UpdateChangedVoices_TestBit0
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 0
	call NoteMap_UpdateEntry

UpdateChangedVoices_TestBit0:
	bit_erpb 0xfb, 0x01
	jr z, UpdateChangedVoices_TestBit02
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xbc, xwa
	ldada xwa, 49862
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, UpdateChangedVoices_TestBit02
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 1
	call NoteMap_UpdateEntry

UpdateChangedVoices_TestBit02:
	bit_erpb 0xfb, 0x02
	jr z, UpdateChangedVoices_TestBit03
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xbc, xwa
	ldada xwa, 49866
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, UpdateChangedVoices_TestBit03
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 2
	call NoteMap_UpdateEntry

UpdateChangedVoices_TestBit03:
	bit_erpb 0xfb, 0x03
	jr z, NoteMap_ReallocEnabledVoices
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xbc, xwa
	ldada xwa, 49870
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, NoteMap_ReallocEnabledVoices
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	ldw de, 0x15
	call NoteMap_UpdateEntry

NoteMap_ReallocEnabledVoices:
	ld_srib A, (xsp + 0x01f0)
	and_srib_rm A, 0xfd, 0xee, 0x01
	ldfr_berp A, 0xfb
	cps a, 0
	jrl z, NoteMap_ReallocVoices_Exit
	bit_erpb 0xfb, 0x00
	jr z, ReallocEnabledVoices_TestBit0
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xbc, xwa
	ldada xwa, 49858
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 0
	call NoteMap_FindAndAllocBestVoice

ReallocEnabledVoices_TestBit0:
	bit_erpb 0xfb, 0x01
	jr z, ReallocEnabledVoices_TestBit02
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xbc, xwa
	ldada xwa, 49862
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 1
	call NoteMap_FindAndAllocBestVoice

ReallocEnabledVoices_TestBit02:
	bit_erpb 0xfb, 0x02
	jr z, ReallocEnabledVoices_TestBit03
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xbc, xwa
	ldada xwa, 49866
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 2
	call NoteMap_FindAndAllocBestVoice

ReallocEnabledVoices_TestBit03:
	bit_erpb 0xfb, 0x03
	jrl z, NoteMap_ReallocVoices_Exit
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xbc, xwa
	ldada xwa, 49870
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	ldw de, 0x15
	call NoteMap_FindAndAllocBestVoice
	jrl NoteMap_ReallocVoices_Exit

ReallocEnabledVoices_CheckMem:
	cp_srib_im 0xfd, 0xf0, 0x01, 0xff
	jr z, ReallocEnabledVoices_CheckMem2
	cp_srib_im 0xfd, 0xee, 0x01, 0xff
	jr z, ReallocEnabledVoices_CheckMem2
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xhl, xwa
	ldada xbc, 50020
	ld_srib A, (xsp + 0x01ee)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_UpdateEntry
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xhl, xwa
	ldada xbc, 49662
	ld_srib A, (xsp + 0x01f0)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_UpdateEntry
	jrl NoteMap_ReallocVoices_Exit

ReallocEnabledVoices_CheckMem2:
	cp_srib_im 0xfd, 0xf0, 0x01, 0xff
	jrl nz, ReallocEnabledVoices_CheckMem3
	cp_srib_im 0xfd, 0xee, 0x01, 0xff
	jrl z, ReallocEnabledVoices_CheckMem3
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xhl, xwa
	ldada xbc, 50020
	ld_srib A, (xsp + 0x01ee)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_UpdateEntry
	bitda 0, 49662
	jr z, ReallocEnabledVoices_TestBit1
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xbc, xwa
	ldada xwa, 49858
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, ReallocEnabledVoices_TestBit1
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 0
	call NoteMap_UpdateEntry

ReallocEnabledVoices_TestBit1:
	bitda 1, 49662
	jr z, ReallocEnabledVoices_TestBit2
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xbc, xwa
	ldada xwa, 49862
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, ReallocEnabledVoices_TestBit2
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 1
	call NoteMap_UpdateEntry

ReallocEnabledVoices_TestBit2:
	bitda 2, 49662
	jrl z, ReallocEnabledVoices_Block
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xbc, xwa
	ldada xwa, 49866
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jrl z, ReallocEnabledVoices_Block
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 2
	call NoteMap_UpdateEntry
	jrl NoteMap_ReallocVoices_Exit

ReallocEnabledVoices_CheckMem3:
	cp_srib_im 0xfd, 0xf0, 0x01, 0xff
	jrl z, NoteMap_ReallocVoices_Exit
	cp_srib_im 0xfd, 0xee, 0x01, 0xff
	jrl nz, NoteMap_ReallocVoices_Exit
	bitda 0, 50020
	jr z, ReallocEnabledVoices_TestBit12
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	ldada xwa, 50216
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, ReallocEnabledVoices_TestBit12
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 0
	call NoteMap_UpdateEntry

ReallocEnabledVoices_TestBit12:
	bitda 1, 50020
	jr z, ReallocEnabledVoices_TestBit22
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	ldada xwa, 50220
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, ReallocEnabledVoices_TestBit22
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 1
	call NoteMap_UpdateEntry

ReallocEnabledVoices_TestBit22:
	bitda 2, 50020
	jr z, ReallocEnabledVoices_WriteReg
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	ldada xwa, 50224
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, ReallocEnabledVoices_WriteReg
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 2
	call NoteMap_UpdateEntry

ReallocEnabledVoices_WriteReg:
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xhl, xwa
	ldada xbc, 49662
	ld_srib A, (xsp + 0x01f0)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_UpdateEntry

ReallocEnabledVoices_Block:
	jrl NoteMap_ReallocVoices_Exit

ReallocEnabledVoices_CheckMem4:
	cp_srib_im 0xfd, 0xf0, 0x01, 0xff
	jrl z, ReallocEnabledVoices_CheckMem5
	cp_srib_im 0xfd, 0xee, 0x01, 0xff
	jrl z, ReallocEnabledVoices_CheckMem5
	cpdi16 52840, 0
	jr nz, ReallocEnabledVoices_LoadAddr
	ldada xwa, 50020
	lds bc, 2
	call NoteMap_AssignVoiceParams

ReallocEnabledVoices_LoadAddr:
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jr z, ReallocEnabledVoices_LoadAddr2

ReallocEnabledVoices_DoFindEntr:
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jr nz, ReallocEnabledVoices_DoFindEntr

ReallocEnabledVoices_LoadAddr2:
	lda xwa, (xsp + 2)
	ld xix, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xhl, xwa
	ld_srib A, (xsp + 0x01f0)
	extz wa
	sla wa, 2
	add wa, 0xc4
	ldada xbc, 49662

ReallocEnabledVoices_WriteReg2:	; NOTE: nothing seems to call here, but I saw this value on VGA undocumented registers at routine EF5163. It may be just a coincidence, though.  (was ReallocEnabledVoices_LoadAddr2_0x1D - off by 1 byte)
	st_dri3b B, 0x07, 0xe4, 0xe0
	ld xwa, xix
	ld xbc, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jrl z, NoteMap_ReallocVoices_Exit
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp + 2)
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_CollectMatchingEntries
	cps l, 0
	jrl z, NoteMap_ReallocVoices_Exit
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	cps l, 0
	jrl nz, NoteMap_ReallocVoices_Exit
	call NoteMap_FindBestMatch
	cp l, 0xff
	jrl z, NoteMap_ReallocVoices_Exit
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_InitVoiceSlots
	jrl NoteMap_ReallocVoices_Exit

ReallocEnabledVoices_CheckMem5:
	cp_srib_im 0xfd, 0xf0, 0x01, 0xff
	jr nz, ReallocEnabledVoices_CheckMem6
	cp_srib_im 0xfd, 0xee, 0x01, 0xff
	jr z, ReallocEnabledVoices_CheckMem6
	cpdi16 52840, 0
	jr nz, ReallocEnabledVoices_LoadAddr3
	ldada xwa, 50020
	lds bc, 2
	call NoteMap_AssignVoiceParams

ReallocEnabledVoices_LoadAddr3:
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jrl z, NoteMap_ReallocVoices_Exit

ReallocEnabledVoices_DoFindEntr2:
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jr nz, ReallocEnabledVoices_DoFindEntr2
	jr NoteMap_ReallocVoices_Exit

ReallocEnabledVoices_CheckMem6:
	cp_srib_im 0xfd, 0xf0, 0x01, 0xff
	jr z, NoteMap_ReallocVoices_Exit
	cp_srib_im 0xfd, 0xee, 0x01, 0xff
	jr nz, NoteMap_ReallocVoices_Exit
	lda xwa, (xsp + 2)
	ld xix, xwa
	st_dri3b W, 0xfd, 0x4a, 0x01
	ld xhl, xwa
	ld_srib A, (xsp + 0x01f0)
	extz wa
	sla wa, 2
	add wa, 0xc4
	ldada xbc, 49662
	st_dri3b B, 0x07, 0xe4, 0xe0
	ld xwa, xix
	ld xbc, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, NoteMap_ReallocVoices_Exit
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp + 2)
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_CollectMatchingEntries
	cps l, 0
	jr z, NoteMap_ReallocVoices_Exit
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	cps l, 0
	jr nz, NoteMap_ReallocVoices_Exit
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_ReallocVoices_Exit
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_InitVoiceSlots

NoteMap_ReallocVoices_Exit:
	pop_werp 0xfa
	st_dri3b L, 0xfd, 0xf2, 0x01
	ret

ReallocVoices_Exit_WriteReg:
	st_dri3b L, 0xfd, 0xb8, 0xfe
	cp c, 0xff
	jr z, ReallocVoices_Exit_CheckEnd
	cp e, 0xff
	jr nz, ReallocVoices_Exit_Compare

ReallocVoices_Exit_CheckEnd:
	cp c, 0xff
	jrl nz, NoteMap_StoreAndRet
	cp e, 0xff
	jrl z, NoteMap_StoreAndRet

ReallocVoices_Exit_Compare:
	cps a, 0
	jrl nz, ReallocVoices_Exit_WriteReg4
	bitda 4, 50312
	jrl z, ReallocVoices_Exit_WriteReg4
	stib_dri 0xfd, 0xa6, 0x00, 0x00
	stib_dri 0xfd, 0xa7, 0x00, 0x01
	st_dri3b W, 0xfd, 0xa4, 0x00
	call Voice_LookupTableEntries
	cps l, 0
	jrl z, NoteMap_StoreAndRet
	st_dri3b W, 0xfd, 0xa4, 0x00
	call NoteMap_AssignAllVoiceLinks
	cpdi8 50021, 255
	jrl nz, ReallocVoices_Exit_CheckDRAM
	bitda 0, 50020
	jr z, ReallocVoices_Exit_TestBit1
	lda xwa, (xsp)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ldada xwa, 50216
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, ReallocVoices_Exit_TestBit1
	lda xwa, (xsp)
	ldada xbc, 50020
	lds de, 0
	call NoteMap_UpdateEntry

ReallocVoices_Exit_TestBit1:
	bitda 1, 50020
	jr z, ReallocVoices_Exit_TestBit2
	lda xwa, (xsp)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ldada xwa, 50220
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, ReallocVoices_Exit_TestBit2
	lda xwa, (xsp)
	ldada xbc, 50020
	lds de, 1
	call NoteMap_UpdateEntry

ReallocVoices_Exit_TestBit2:
	bitda 2, 50020
	jr z, ReallocVoices_Exit_TestBit3
	lda xwa, (xsp)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ldada xwa, 50224
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, ReallocVoices_Exit_TestBit3
	lda xwa, (xsp)
	ldada xbc, 50020
	lds de, 2
	call NoteMap_UpdateEntry

ReallocVoices_Exit_TestBit3:
	bitda 3, 50020
	jrl z, ReallocVoices_Exit_Block
	lda xwa, (xsp)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ldada xwa, 50228
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jrl z, ReallocVoices_Exit_Block
	lda xwa, (xsp)
	ldada xbc, 50020
	ldw de, 0x15
	call NoteMap_UpdateEntry
	call AudioInit_RefreshToneBank
	jrl NoteMap_StoreAndRet

ReallocVoices_Exit_CheckDRAM:
	cpdi8 50021, 21
	jr nz, ReallocVoices_Exit_TestBit32
	ldda16 xwa, 50584
	bit 1, wa
	jr z, ReallocVoices_Exit_WriteReg2
	st_dri3b W, 0xfd, 0xa4, 0x00
	call NoteMap_MarkEntriesAboveThreshold

ReallocVoices_Exit_WriteReg2:
	st_dri3b W, 0xfd, 0xa4, 0x00
	ldada xbc, 50020
	ldw de, 0x15
	call NoteMap_UpdateEntry
	jr NoteMap_StoreAndRet

ReallocVoices_Exit_TestBit32:
	bitda 3, 50020
	jr z, ReallocVoices_Exit_WriteReg3
	lda xwa, (xsp)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ldada xwa, 50228
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, ReallocVoices_Exit_WriteReg3
	lda xwa, (xsp)
	ldada xbc, 50020
	ldw de, 0x15
	call NoteMap_UpdateEntry
	call AudioInit_RefreshToneBank

ReallocVoices_Exit_WriteReg3:
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xhl, xwa
	ldada xbc, 50020
	ldda8 a, 50021
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_UpdateEntry

ReallocVoices_Exit_Block:
	jr NoteMap_StoreAndRet

ReallocVoices_Exit_WriteReg4:
	stib_dri 0xfd, 0xa6, 0x00, 0x01
	lda_dri3 XIY, 0xfd, 0xa7, 0x00
	st_dri3b A, 0xfd, 0xa4, 0x00
	ld xhl, xbc
	ldada xbc, 50020
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_CollectAndAllocVoice_Indirect

NoteMap_StoreAndRet:
	st_dri3b L, 0xfd, 0x48, 0x01
	ret

StoreAndRet_WriteReg:
	st_dri3b L, 0xfd, 0xb4, 0xfe
	lda_dri3 XHL, 0xfd, 0x48, 0x01
	lda_dri3 XBC, 0xfd, 0x4a, 0x01
	cp_srib_im 0xfd, 0x4a, 0x01, 0xff
	jrl z, VoiceRealloc_CheckSingleLayer
	cp_srib_im 0xfd, 0x48, 0x01, 0xff
	jrl z, VoiceRealloc_CheckSingleLayer
	cpdi16 52840, 1
	jr nz, StoreAndRet_WriteReg2
	ldada xwa, 50020
	lds bc, 2
	call NoteMap_AssignVoiceParams

StoreAndRet_WriteReg2:
	stib_dri 0xfd, 0xa6, 0x00, 0x01
	ld_srib A, (xsp + 0x0148)
	extz wa
	ldada xbc, 50056
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	lda_dri3 XBC, 0xfd, 0xa7, 0x00
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x0148)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, StoreAndRet_WriteReg3
	lda xwa, (xsp)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch

StoreAndRet_WriteReg3:
	stib_dri 0xfd, 0xa6, 0x00, 0x01
	ld_srib A, (xsp + 0x014a)
	extz wa
	ldada xbc, 49698
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	lda_dri3 XBC, 0xfd, 0xa7, 0x00
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jrl z, NoteMap_StoreVoiceResultAndReturn
	lda xwa, (xsp)
	ld xhl, xwa
	ldada xbc, 49662
	ld_srib A, (xsp + 0x014a)
	ld e, a
	extz de
	ld xwa, xhl
	call Voice_ApplyTransposeWithEncode
	lda xwa, (xsp)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp)
	call NoteMap_FindBestFreeVoice
	cps l, 1
	jrl nz, NoteMap_StoreVoiceResultAndReturn
	call NoteMap_FindBestMatch
	cp l, 0xff
	jrl z, NoteMap_StoreVoiceResultAndReturn
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_InitVoiceSlots
	jrl NoteMap_StoreVoiceResultAndReturn

VoiceRealloc_CheckSingleLayer:
	cp_srib_im 0xfd, 0x4a, 0x01, 0xff
	jr nz, VoiceRealloc_CheckAltLayer
	cp_srib_im 0xfd, 0x48, 0x01, 0xff
	jr z, VoiceRealloc_CheckAltLayer
	cpdi16 52840, 1
	jr nz, VoiceRealloc_LookupVoice
	ldada xwa, 50020
	lds bc, 2
	call NoteMap_AssignVoiceParams

VoiceRealloc_LookupVoice:
	stib_dri 0xfd, 0xa6, 0x00, 0x01
	ld_srib A, (xsp + 0x0148)
	extz wa
	ldada xbc, 50056
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	lda_dri3 XBC, 0xfd, 0xa7, 0x00
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x0148)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jrl z, NoteMap_StoreVoiceResultAndReturn
	lda xwa, (xsp)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch
	jrl NoteMap_StoreVoiceResultAndReturn

VoiceRealloc_CheckAltLayer:
	cp_srib_im 0xfd, 0x4a, 0x01, 0xff
	jr z, NoteMap_StoreVoiceResultAndReturn
	cp_srib_im 0xfd, 0x48, 0x01, 0xff
	jr nz, NoteMap_StoreVoiceResultAndReturn
	stib_dri 0xfd, 0xa6, 0x00, 0x01
	ld_srib A, (xsp + 0x014a)
	extz wa
	ldada xbc, 49698
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	lda_dri3 XBC, 0xfd, 0xa7, 0x00
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jr z, NoteMap_StoreVoiceResultAndReturn
	lda xwa, (xsp)
	ld xhl, xwa
	ldada xbc, 49662
	ld_srib A, (xsp + 0x014a)
	ld e, a
	extz de
	ld xwa, xhl
	call Voice_ApplyTransposeWithEncode
	lda xwa, (xsp)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp)
	call NoteMap_FindBestFreeVoice
	cps l, 1
	jr nz, NoteMap_StoreVoiceResultAndReturn
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_StoreVoiceResultAndReturn
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_InitVoiceSlots

NoteMap_StoreVoiceResultAndReturn:
	st_dri3b L, 0xfd, 0x4c, 0x01
	ret

NoteMap_ProcessDualLayerNoteOff:
	st_dri3b L, 0xfd, 0x58, 0xff
	lda_dri3 XIY, 0xfd, 0xa4, 0x00
	lda_dri3 XBC, 0xfd, 0xa6, 0x00
	cp c, 0xff
	jr z, NoteMap_DualLayerNoteOff_SinglePath
	cp_srib_im 0xfd, 0xa4, 0x00, 0xff
	jr z, NoteMap_DualLayerNoteOff_SinglePath
	ld (xsp + 2), 0x2
	ld_srib A, (xsp + 0x00a6)
	ld (xsp + 3), a
	lda xwa, (xsp)
	ld xhl, xwa
	ldada xbc, 50020
	ld_srib A, (xsp + 0x00a4)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_ProcessNoteEvent
	ld (xsp + 2), 0x3
	ld_srib A, (xsp + 0x00a6)
	ld (xsp + 3), a
	lda xwa, (xsp)
	ld xhl, xwa
	ldada xbc, 50020
	ld_srib A, (xsp + 0x00a4)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_ProcessNoteEvent
	jr NoteMap_ProcessNote_SetResult

NoteMap_DualLayerNoteOff_SinglePath:
	cp c, 0xff
	jr nz, NoteMap_ProcessNote_SetResult
	cp_srib_im 0xfd, 0xa4, 0x00, 0xff
	jr z, NoteMap_ProcessNote_SetResult
	ld (xsp + 2), 0x2
	ld_srib A, (xsp + 0x00a6)
	ld (xsp + 3), a
	lda xwa, (xsp)
	ld xhl, xwa
	ldada xbc, 50020
	ld_srib A, (xsp + 0x00a4)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_ProcessNoteEvent
	ld (xsp + 2), 0x3
	ld_srib A, (xsp + 0x00a6)
	ld (xsp + 3), a
	lda xwa, (xsp)
	ld xhl, xwa
	ldada xbc, 50020
	ld_srib A, (xsp + 0x00a4)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_ProcessNoteEvent

NoteMap_ProcessNote_SetResult:
	st_dri3b L, 0xfd, 0xa8, 0x00
	ret

NoteMap_ProcessLayeredNoteOn:
	st_dri3b L, 0xfd, 0xb4, 0xfe
	lda_dri3 XIY, 0xfd, 0x48, 0x01
	lda_dri3 XBC, 0xfd, 0x4a, 0x01
	cp c, 0xff
	jrl z, ProcessLayeredNoteOn_CheckEnd
	cp_srib_im 0xfd, 0x48, 0x01, 0xff
	jrl z, ProcessLayeredNoteOn_CheckEnd
	stib_dri 0xfd, 0xa6, 0x00, 0x02
	ld_srib A, (xsp + 0x014a)
	lda_dri3 XBC, 0xfd, 0xa7, 0x00
	lda xwa, (xsp)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xde, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	ldada xbc, 50152
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	pushw wa
	ld xwa, xhl
	ld xbc, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, ProcessLayeredNoteOn_WriteReg
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

ProcessLayeredNoteOn_WriteReg:
	stib_dri 0xfd, 0xa6, 0x00, 0x03
	ld_srib A, (xsp + 0x014a)
	lda_dri3 XBC, 0xfd, 0xa7, 0x00
	lda xwa, (xsp)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xde, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	ldada xbc, 50152
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	pushw wa
	ld xwa, xhl
	ld xbc, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jrl z, ProcessLayeredNoteOn_WriteReg3
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents
	jrl ProcessLayeredNoteOn_WriteReg3

ProcessLayeredNoteOn_CheckEnd:
	cp c, 0xff
	jrl nz, ProcessLayeredNoteOn_WriteReg3
	cp_srib_im 0xfd, 0x48, 0x01, 0xff
	jrl z, ProcessLayeredNoteOn_WriteReg3
	stib_dri 0xfd, 0xa6, 0x00, 0x02
	ld_srib A, (xsp + 0x014a)
	lda_dri3 XBC, 0xfd, 0xa7, 0x00
	lda xwa, (xsp)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xde, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	ldada xbc, 50152
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	pushw wa
	ld xwa, xhl
	ld xbc, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, ProcessLayeredNoteOn_WriteReg2
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

ProcessLayeredNoteOn_WriteReg2:
	stib_dri 0xfd, 0xa6, 0x00, 0x03
	ld_srib A, (xsp + 0x014a)
	lda_dri3 XBC, 0xfd, 0xa7, 0x00
	lda xwa, (xsp)
	ld xhl, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xde, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	ldada xbc, 50152
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	pushw wa
	ld xwa, xhl
	ld xbc, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, ProcessLayeredNoteOn_WriteReg3
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

ProcessLayeredNoteOn_WriteReg3:
	st_dri3b L, 0xfd, 0x4c, 0x01
	ret

ProcessLayeredNoteOn_WriteReg4:
	st_dri3b L, 0xfd, 0xb4, 0xfe
	pushw iz
	lda_dri3 XHL, 0xfd, 0x4a, 0x01
	lda_dri3 XBC, 0xfd, 0x4c, 0x01
	cp_srib_im 0xfd, 0x4c, 0x01, 0xff
	jrl z, LoopAdvance_Next_CheckMem
	cp_srib_im 0xfd, 0x4a, 0x01, 0xff
	jrl z, LoopAdvance_Next_CheckMem
	cpdi16 52840, 2
	jr nz, ProcessLayeredNoteOn_InitVal
	cpdi16 52840, 3
	jr nz, ProcessLayeredNoteOn_InitVal
	ldada xwa, 50020
	lds bc, 2
	call NoteMap_AssignVoiceParams

ProcessLayeredNoteOn_InitVal:
	lds iz, 0
	cp iz, 0x10
	jrl nc, ProcessLayeredNoteOn_InitVal2

ProcessLayeredNoteOn_LoadIter:
	ld wa, iz
	ldada xbc, 50152
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp_srib_rm A, 0xfd, 0x4a, 0x01
	jr nz, ProcessLayeredNoteOn_NextIter
	stib_dri 0xfd, 0xa8, 0x00, 0x03
	ldto_berp A, 0xf8
	lda_dri3 XBC, 0xfd, 0xa9, 0x00
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jr z, ProcessLayeredNoteOn_WriteReg5
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch

ProcessLayeredNoteOn_WriteReg5:
	stib_dri 0xfd, 0xa8, 0x00, 0x02
	ldto_berp A, 0xf8
	lda_dri3 XBC, 0xfd, 0xa9, 0x00
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jr z, ProcessLayeredNoteOn_NextIter
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch

ProcessLayeredNoteOn_NextIter:
	inc 1, iz
	cp iz, 0x10
	jrl c, ProcessLayeredNoteOn_LoadIter

ProcessLayeredNoteOn_InitVal2:
	lds iz, 0
	cp iz, 0x10
	jrl nc, NoteMap_PopIzStoreRet

ProcessLayeredNoteOn_LoadIter2:
	ld wa, iz
	ldada xbc, 50152
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp_srib_rm A, 0xfd, 0x4c, 0x01
	jrl nz, NoteMap_LoopAdvance_Next
	stib_dri 0xfd, 0xa8, 0x00, 0x03
	ldto_berp A, 0xf8
	lda_dri3 XBC, 0xfd, 0xa9, 0x00
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014c)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jr z, NoteMap_ClaimAndInitVoiceSlot_A
	lda xwa, (xsp + 2)
	ld xhl, xwa
	ldada xbc, 49662
	ld_srib A, (xsp + 0x014c)
	ld e, a
	extz de
	ld xwa, xhl
	call SndParam_ComputeVoiceTuning
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	cps l, 3
	jr nz, NoteMap_ClaimAndInitVoiceSlot_A
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_ClaimAndInitVoiceSlot_A
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_InitVoiceSlots

NoteMap_ClaimAndInitVoiceSlot_A:
	stib_dri 0xfd, 0xa8, 0x00, 0x02
	ldto_berp A, 0xf8
	lda_dri3 XBC, 0xfd, 0xa9, 0x00
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014c)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jr z, NoteMap_LoopAdvance_Next
	lda xwa, (xsp + 2)
	ld xhl, xwa
	ldada xbc, 49662
	ld_srib A, (xsp + 0x014c)
	ld e, a
	extz de
	ld xwa, xhl
	call SndParam_ComputeVoiceTuning
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	cps l, 2
	jr nz, NoteMap_LoopAdvance_Next
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_LoopAdvance_Next
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_InitVoiceSlots

NoteMap_LoopAdvance_Next:
	inc 1, iz
	cp iz, 0x10
	jrl c, ProcessLayeredNoteOn_LoadIter2
	jrl NoteMap_PopIzStoreRet

LoopAdvance_Next_CheckMem:
	cp_srib_im 0xfd, 0x4c, 0x01, 0xff
	jrl nz, LoopAdvance_Next_CheckMem2
	cp_srib_im 0xfd, 0x4a, 0x01, 0xff
	jrl z, LoopAdvance_Next_CheckMem2
	cpdi16 52840, 2
	jr nz, LoopAdvance_Next_InitVal
	cpdi16 52840, 3
	jr nz, LoopAdvance_Next_InitVal
	ldada xwa, 50020
	lds bc, 2
	call NoteMap_AssignVoiceParams

LoopAdvance_Next_InitVal:
	lds iz, 0
	cp iz, 0x10
	jrl nc, NoteMap_PopIzStoreRet

LoopAdvance_Next_LoadIter:
	ld wa, iz
	ldada xbc, 50152
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp_srib_rm A, 0xfd, 0x4a, 0x01
	jr nz, LoopAdvance_Next_Increment
	stib_dri 0xfd, 0xa8, 0x00, 0x03
	ldto_berp A, 0xf8
	lda_dri3 XBC, 0xfd, 0xa9, 0x00
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jr z, LoopAdvance_Next_WriteReg
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch

LoopAdvance_Next_WriteReg:
	stib_dri 0xfd, 0xa8, 0x00, 0x02
	ldto_berp A, 0xf8
	lda_dri3 XBC, 0xfd, 0xa9, 0x00
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jr z, LoopAdvance_Next_Increment
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch

LoopAdvance_Next_Increment:
	inc 1, iz
	cp iz, 0x10
	jrl c, LoopAdvance_Next_LoadIter
	jrl NoteMap_PopIzStoreRet

LoopAdvance_Next_CheckMem2:
	cp_srib_im 0xfd, 0x4c, 0x01, 0xff
	jrl z, NoteMap_PopIzStoreRet
	cp_srib_im 0xfd, 0x4a, 0x01, 0xff
	jrl nz, NoteMap_PopIzStoreRet
	lds iz, 0
	cp iz, 0x10
	jrl nc, NoteMap_PopIzStoreRet

LoopAdvance_Next_LoadIter2:
	ld wa, iz
	ldada xbc, 50152
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp_srib_rm A, 0xfd, 0x4c, 0x01
	jrl nz, NoteMap_LoopAdvance_Next2
	stib_dri 0xfd, 0xa8, 0x00, 0x03
	ldto_berp A, 0xf8
	lda_dri3 XBC, 0xfd, 0xa9, 0x00
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014c)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jr z, NoteMap_ClaimAndInitVoiceSlot_B
	lda xwa, (xsp + 2)
	ld xhl, xwa
	ldada xbc, 49662
	ld_srib A, (xsp + 0x014c)
	ld e, a
	extz de
	ld xwa, xhl
	call SndParam_ComputeVoiceTuning
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	cps l, 3
	jr nz, NoteMap_ClaimAndInitVoiceSlot_B
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_ClaimAndInitVoiceSlot_B
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_InitVoiceSlots

NoteMap_ClaimAndInitVoiceSlot_B:
	stib_dri 0xfd, 0xa8, 0x00, 0x02
	ldto_berp A, 0xf8
	lda_dri3 XBC, 0xfd, 0xa9, 0x00
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa6, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014c)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jr z, NoteMap_LoopAdvance_Next2
	lda xwa, (xsp + 2)
	ld xhl, xwa
	ldada xbc, 49662
	ld_srib A, (xsp + 0x014c)
	ld e, a
	extz de
	ld xwa, xhl
	call SndParam_ComputeVoiceTuning
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	cps l, 2
	jr nz, NoteMap_LoopAdvance_Next2
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_LoopAdvance_Next2
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_InitVoiceSlots

NoteMap_LoopAdvance_Next2:
	inc 1, iz
	cp iz, 0x10
	jrl c, LoopAdvance_Next_LoadIter2

NoteMap_PopIzStoreRet:
	popw iz
	st_dri3b L, 0xfd, 0x4c, 0x01
	ret

PopIzStoreRet_Prologue:
	dec 2, xsp
	ld (xsp), a
	cp c, 0xff
	jr nz, PopIzStoreRet_CheckEnd
	cp e, 0xff
	jr z, PopIzStoreRet_CheckEnd
	ldada xde, 50020
	ld a, (xsp)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AssignVoiceParams
	jr PopIzStoreRet_Increment

PopIzStoreRet_CheckEnd:
	cp c, 0xff
	jr z, PopIzStoreRet_Block
	cp e, 0xff
	jr z, PopIzStoreRet_Block
	ldada xde, 50020
	ld a, (xsp)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AssignVoiceParams
	ldada xde, 49662
	ld a, (xsp)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocateVoice
	jr PopIzStoreRet_Increment

PopIzStoreRet_Block:
	ldada xde, 49662
	ld a, (xsp)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocateVoice

PopIzStoreRet_Increment:
	inc 2, xsp
	ret

PopIzStoreRet_WriteReg:
	st_dri3b L, 0xfd, 0xb2, 0xfe
	lda_dri3 XIY, 0xfd, 0x48, 0x01
	lda_dri3 XHL, 0xfd, 0x4a, 0x01
	lda_dri3 XBC, 0xfd, 0x4c, 0x01
	cp_srib_im 0xfd, 0x4a, 0x01, 0xff
	jrl nz, NoteMap_CrossChannelReassign
	cp_srib_im 0xfd, 0x48, 0x01, 0xff
	jrl z, NoteMap_CrossChannelReassign
	stib_dri 0xfd, 0xa6, 0x00, 0x00
	stib_dri 0xfd, 0xa7, 0x00, 0x00
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014c)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, PopIzStoreRet_WriteReg2
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

PopIzStoreRet_WriteReg2:
	stib_dri 0xfd, 0xa6, 0x00, 0x04
	stib_dri 0xfd, 0xa7, 0x00, 0xff
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014c)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, PopIzStoreRet_WriteReg3
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

PopIzStoreRet_WriteReg3:
	stib_dri 0xfd, 0xa6, 0x00, 0x06
	stib_dri 0xfd, 0xa7, 0x00, 0xff
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014c)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, NoteMap_CrossChannelReassign
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

NoteMap_CrossChannelReassign:
	cp_srib_im 0xfd, 0x4a, 0x01, 0xff
	jr z, NoteMap_SetParam_Return
	ld_srib A, (xsp + 0x014a)
	cp_srib_rm A, 0xfd, 0x48, 0x01
	jr z, NoteMap_SetParam_Return
	cp_srib_im 0xfd, 0x4c, 0x01, 0x15
	jr z, CrossChannelReassign_WriteReg
	cp_srib_im 0xfd, 0x4c, 0x01, 0x02
	jr nz, NoteMap_SetParam_Return

CrossChannelReassign_WriteReg:
	stib_dri 0xfd, 0xa6, 0x00, 0x06
	stib_dri 0xfd, 0xa7, 0x00, 0xff
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014c)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jr z, NoteMap_SetParam_Return
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x014a)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

NoteMap_SetParam_Return:
	st_dri3b L, 0xfd, 0x4e, 0x01
	ret

SetParam_Return_WriteReg:
	st_dri3b L, 0xfd, 0xb4, 0xfe
	lda_dri3 XIY, 0xfd, 0x48, 0x01
	lda_dri3 XBC, 0xfd, 0x4a, 0x01
	cp c, 0xff
	jrl z, SetParam_Return_CheckEnd
	cp_srib_im 0xfd, 0x48, 0x01, 0xff
	jrl z, SetParam_Return_CheckEnd
	stib_dri 0xfd, 0xa6, 0x00, 0x00
	stib_dri 0xfd, 0xa7, 0x00, 0x00
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, SetParam_Return_WriteReg2
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

SetParam_Return_WriteReg2:
	stib_dri 0xfd, 0xa6, 0x00, 0x04
	stib_dri 0xfd, 0xa7, 0x00, 0xff
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, SetParam_Return_WriteReg3
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

SetParam_Return_WriteReg3:
	stib_dri 0xfd, 0xa6, 0x00, 0x06
	stib_dri 0xfd, 0xa7, 0x00, 0xff
	cp_srib_im 0xfd, 0x4a, 0x01, 0x19
	jr nz, SetParam_Return_LoadAddr
	ldda8 a, 50210
	lda_dri3 XBC, 0xfd, 0x4a, 0x01

SetParam_Return_LoadAddr:
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jrl z, SeqPart_LookupReturn
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents
	jrl SeqPart_LookupReturn

SetParam_Return_CheckEnd:
	cp c, 0xff
	jrl nz, SeqPart_LookupReturn
	cp_srib_im 0xfd, 0x48, 0x01, 0xff
	jrl z, SeqPart_LookupReturn
	stib_dri 0xfd, 0xa6, 0x00, 0x00
	stib_dri 0xfd, 0xa7, 0x00, 0x00
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, SetParam_Return_WriteReg4
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

SetParam_Return_WriteReg4:
	stib_dri 0xfd, 0xa6, 0x00, 0x04
	stib_dri 0xfd, 0xa7, 0x00, 0xff
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, SetParam_Return_WriteReg5
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

SetParam_Return_WriteReg5:
	stib_dri 0xfd, 0xa6, 0x00, 0x06
	stib_dri 0xfd, 0xa7, 0x00, 0xff
	cp_srib_im 0xfd, 0x4a, 0x01, 0x19
	jr nz, SetParam_Return_LoadAddr2
	ldda8 a, 50210
	lda_dri3 XBC, 0xfd, 0x4a, 0x01

SetParam_Return_LoadAddr2:
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, SeqPart_LookupReturn
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

SeqPart_LookupReturn:
	st_dri3b L, 0xfd, 0x4c, 0x01
	ret

SeqPart_EmitMelodicNote:
	st_dri3b L, 0xfd, 0xb4, 0xfe
	lda_dri3 XIY, 0xfd, 0x48, 0x01
	lda_dri3 XBC, 0xfd, 0x4a, 0x01
	cp c, 0xff
	jrl z, SeqPart_MelodicNote_SingleLayer
	cp_srib_im 0xfd, 0x48, 0x01, 0xff
	jrl z, SeqPart_MelodicNote_SingleLayer
	stib_dri 0xfd, 0xa6, 0x00, 0x00
	stib_dri 0xfd, 0xa7, 0x00, 0x00
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x0148)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, SeqPart_MelodicNote_Layer1Done
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x014a)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

SeqPart_MelodicNote_Layer1Done:
	stib_dri 0xfd, 0xa6, 0x00, 0x01
	stib_dri 0xfd, 0xa7, 0x00, 0xff
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x0148)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jrl z, SeqPart_EmitMelodicNote_Return
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x014a)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents
	jrl SeqPart_EmitMelodicNote_Return

SeqPart_MelodicNote_SingleLayer:
	cp c, 0xff
	jrl nz, SeqPart_EmitMelodicNote_Return
	cp_srib_im 0xfd, 0x48, 0x01, 0xff
	jr z, SeqPart_EmitMelodicNote_Return
	stib_dri 0xfd, 0xa6, 0x00, 0x00
	stib_dri 0xfd, 0xa7, 0x00, 0x00
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x0148)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, SeqPart_MelodicNote_Layer1Done_Alt
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x014a)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

SeqPart_MelodicNote_Layer1Done_Alt:
	stib_dri 0xfd, 0xa6, 0x00, 0x01
	stib_dri 0xfd, 0xa7, 0x00, 0xff
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x0148)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, SeqPart_EmitMelodicNote_Return
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x014a)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

SeqPart_EmitMelodicNote_Return:
	st_dri3b L, 0xfd, 0x4c, 0x01
	ret

SeqPart_EmitPercussionNote:
	st_dri3b L, 0xfd, 0xb4, 0xfe
	lda_dri3 XIY, 0xfd, 0x48, 0x01
	lda_dri3 XBC, 0xfd, 0x4a, 0x01
	cp c, 0xff
	jrl z, SeqPart_PercNote_SingleLayer
	cp_srib_im 0xfd, 0x48, 0x01, 0xff
	jrl z, SeqPart_PercNote_SingleLayer
	stib_dri 0xfd, 0xa6, 0x00, 0x00
	stib_dri 0xfd, 0xa7, 0x00, 0x00
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, SeqPart_PercNote_Layer1Done
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call SeqPart_EmitNoteOnMessages

SeqPart_PercNote_Layer1Done:
	stib_dri 0xfd, 0xa6, 0x00, 0x01
	stib_dri 0xfd, 0xa7, 0x00, 0xff
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jrl z, SeqPart_EmitPercussionNote_Return
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call SeqPart_EmitNoteOnMessages
	jrl SeqPart_EmitPercussionNote_Return

SeqPart_PercNote_SingleLayer:
	cp c, 0xff
	jrl nz, SeqPart_EmitPercussionNote_Return
	cp_srib_im 0xfd, 0x48, 0x01, 0xff
	jr z, SeqPart_EmitPercussionNote_Return
	stib_dri 0xfd, 0xa6, 0x00, 0x00
	stib_dri 0xfd, 0xa7, 0x00, 0x00
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, SeqPart_PercNote_Layer1Done_Alt
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call SeqPart_EmitNoteOnMessages

SeqPart_PercNote_Layer1Done_Alt:
	stib_dri 0xfd, 0xa6, 0x00, 0x01
	stib_dri 0xfd, 0xa7, 0x00, 0xff
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xfd, 0xa4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, SeqPart_EmitPercussionNote_Return
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call SeqPart_EmitNoteOnMessages

SeqPart_EmitPercussionNote_Return:
	st_dri3b L, 0xfd, 0x4c, 0x01
	ret

SeqPart_EmitNoteOn_Full:
	lda xsp, (xsp - 12)
	push xiz
	lds iz, 0
	call RhythmBuf_SaveWritePos

RhythmBuf_EventDispatchLoop:
	call RhythmBuf_ReadAlternate
	ld (xsp + 4), hl
	ld wa, (xsp + 4)
	cp wa, 0xffff
	jrl z, ProcessEventDispatch_Send
	ld wa, (xsp + 4)
	cp wa, 0xc8
	jr z, Rhythm_ProcessEventDispatch
	cp wa, 0xc7
	jr z, Rhythm_ProcessEventDispatch
	cp wa, 0xc6
	jr z, Rhythm_ProcessEventDispatch
	cp wa, 0xc5
	jr z, Rhythm_ProcessEventDispatch
	cp wa, 0xc4
	jr z, Rhythm_ProcessEventDispatch
	sub wa, 0xd0
	cps wa, 0
	jr lt, RhythmBuf_EventDispatchLoop
	cp wa, 0x8
	jr gt, RhythmBuf_EventDispatchLoop
	add wa, wa
	lda_24 xix, 0xee8fae
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, Rhythm_ProcessEventDispatch
	jp_dri 8, 0x07, 0xf0, 0xe0

Rhythm_ProcessEventDispatch:
	call RhythmBuf_ReadAlternate
	ld (xsp + 6), hl
	ld wa, (xsp + 6)
	cp wa, 0xffff
	jr z, RhythmBuf_EventDispatchLoop
	call RhythmBuf_ReadAlternate
	ld (xsp + 8), hl
	ld wa, (xsp + 8)
	cp wa, 0xffff
	jr z, RhythmBuf_EventDispatchLoop
	call RhythmBuf_ReadAlternate
	ld (xsp + 12), hl
	ld wa, (xsp + 12)
	cp wa, 0xffff
	jrl z, RhythmBuf_EventDispatchLoop
	call RhythmBuf_ReadAlternate
	ld (xsp + 10), hl
	ld wa, (xsp + 10)
	cp wa, 0xffff
	jrl z, RhythmBuf_EventDispatchLoop
	call RhythmBuf_ReadAlternate
	ld (xsp + 14), hl
	ld wa, (xsp + 14)
	cp wa, 0xffff
	jrl z, RhythmBuf_EventDispatchLoop
	ld wa, (xsp + 4)
	and wa, 0xf
	lda_24 xbc, 0xee8f9a
	ld_srib3 A, 0x07, 0xe4, 0xe0
	extz wa
	ld (xsp + 4), wa
	ld wa, (xsp + 8)
	bit 4, wa
	jr z, ProcessEventDispatch_Compare
	resm 4, (xsp + 8)
	setm 7, (xsp + 6)

ProcessEventDispatch_Compare:
	cpw (xsp + 4), 0x14
	jr nz, ProcessEventDispatch_LoadParam
	ormi16 (xsp + 6), 0xf0
	ldw (xsp + 12), 0x40
	ldw (xsp + 14), 0x48

ProcessEventDispatch_LoadParam:
	ld wa, (xsp + 4)
	ld de, (xsp + 6)
	lds bc, 0
	call SndPart_SetParam
	ld wa, (xsp + 4)
	ld de, (xsp + 8)
	ldw bc, 0x20
	call SndPart_SetParam
	ld wa, (xsp + 4)
	pushw 0x5
	ld de, (xsp + 8)
	lds bc, 0
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 4)
	pushw 0x5
	ld de, (xsp + 10)
	ldw bc, 0x20
	call SndParam_NotifyAndReturn
	cpdi8 36150, 220
	jr z, ProcessEventDispatch_InitVal
	ld wa, (xsp + 4)
	pushw 0x3
	ld de, (xsp + 8)
	lds bc, 0
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 4)
	pushw 0x3
	ld de, (xsp + 10)
	ldw bc, 0x20
	call SndParam_NotifyAndReturn

ProcessEventDispatch_InitVal:
	lds wa, 0
	cpw (xsp + 10), 0x0
	jr z, ProcessEventDispatch_LoadParam2
	ldw wa, 0x7f

ProcessEventDispatch_LoadParam2:
	ld (xsp + 10), wa
	ld wa, (xsp + 4)
	ld de, (xsp + 10)
	ldw bc, 0x5e
	call SndPart_SetParam
	ld wa, (xsp + 4)
	pushw 0x5
	ld de, (xsp + 12)
	ldw bc, 0x5e
	call SndParam_NotifyAndReturn
	cpdi8 36150, 220
	jr z, ProcessEventDispatch_LoadParam3
	ld wa, (xsp + 4)
	pushw 0x3
	ld de, (xsp + 12)
	ldw bc, 0x5e
	call SndParam_NotifyAndReturn

ProcessEventDispatch_LoadParam3:
	ld wa, (xsp + 4)
	ld de, (xsp + 12)
	ldw bc, 0xa
	call SndPart_SetParam
	ld wa, (xsp + 4)
	pushw 0x5
	ld de, (xsp + 14)
	ldw bc, 0xa
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 4)
	pushw 0x3
	ld de, (xsp + 14)
	ldw bc, 0xa
	call SndParam_NotifyAndReturn
	ldw wa, 0x7f
	cpw (xsp + 14), 0x48
	jr ge, ProcessEventDispatch_LoadParam4
	ld wa, (xsp + 14)
	add wa, 0x37

ProcessEventDispatch_LoadParam4:
	ld (xsp + 14), wa
	ld wa, (xsp + 4)
	ld de, (xsp + 14)
	ldw bc, 0xb
	call SndPart_SetParam
	ld wa, (xsp + 4)
	pushw 0x5
	ld de, (xsp + 16)
	ldw bc, 0xb
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 4)
	pushw 0x3
	ld de, (xsp + 16)
	ldw bc, 0xb
	call SndParam_NotifyAndReturn
	jrl RhythmBuf_EventDispatchLoop
	call RhythmBuf_ReadAlternate
	ldfr_werp HL, 0xfa
	ldto_werp WA, 0xfa
	cp wa, 0xffff
	jrl z, RhythmBuf_EventDispatchLoop
	call RhythmBuf_ReadAlternate
	ld iz, hl
	ld wa, iz
	cp wa, 0xffff
	jrl z, RhythmBuf_EventDispatchLoop
	cpi_werp 0xfa, 3
	jrl nz, RhythmBuf_EventDispatchLoop
	cps iz, 0
	jrl nz, RhythmBuf_EventDispatchLoop
	ldw iz, 0x10
	cp iz, 0x14
	jrl ge, RhythmBuf_EventDispatchLoop

ProcessEventDispatch_LoadIter:
	ld wa, iz
	lds bc, 1
	lds de, 0
	call SndPart_SetParam
	ld wa, iz
	pushw 0x5
	lds bc, 1
	lds de, 0
	call SndParam_NotifyAndReturn
	ld wa, iz
	ldw bc, 0x1b0
	ldw de, 0x2000
	call SndPart_SetParam
	ld wa, iz
	pushw 0x5
	ldw bc, 0x1b0
	ldw de, 0x2000
	call SndParam_NotifyAndReturn
	ld wa, iz
	ldw bc, 0x40
	lds de, 0
	call SndPart_SetParam
	ld wa, iz
	pushw 0x5
	ldw bc, 0x40
	lds de, 0
	call SndParam_NotifyAndReturn
	ld wa, iz
	pushw 0x3
	ldw bc, 0x40
	lds de, 0
	call SndParam_NotifyAndReturn
	ld wa, iz
	ldw bc, 0xb
	ldw de, 0x7f
	call SndPart_SetParam
	ld wa, iz
	pushw 0x5
	ldw bc, 0xb
	ldw de, 0x7f
	call SndParam_NotifyAndReturn
	inc 1, iz
	cp iz, 0x14
	jr lt, ProcessEventDispatch_LoadIter
	jrl RhythmBuf_EventDispatchLoop
	call RhythmBuf_ReadAlternate
	ldfr_werp HL, 0xfa
	ldto_werp WA, 0xfa
	cp wa, 0xffff
	jrl z, RhythmBuf_EventDispatchLoop
	call RhythmBuf_ReadAlternate
	ld iz, hl
	ld wa, iz
	cp wa, 0xffff
	jrl z, RhythmBuf_EventDispatchLoop
	ld wa, (xsp + 4)
	and wa, 0xf
	lda_24 xbc, 0xee8f9a
	ld_srib3 A, 0x07, 0xe4, 0xe0
	extz wa
	ld (xsp + 4), wa
	ldto_werp WA, 0xfa
	cp wa, 0x10
	jrl z, ProcessEventDispatch_DoInit
	cps wa, 5
	jrl z, ProcessEventDispatch_LoadParam7
	cps wa, 4
	jrl z, ProcessEventDispatch_LoadParam6
	cps wa, 3
	jr z, ProcessEventDispatch_LoadParam5
	cps wa, 2
	jr z, ProcessEventDispatch_InitVal2
	cps wa, 1
	jrl nz, ProcessEventDispatch_Block
	ld wa, (xsp + 4)
	ld de, iz
	lds bc, 1
	call SndPart_SetParam
	ld wa, (xsp + 4)
	pushw 0x5
	ld de, iz
	lds bc, 1
	call SndParam_NotifyAndReturn
	jrl RhythmBuf_EventDispatchLoop

ProcessEventDispatch_InitVal2:
	lds wa, 0
	cp iz, 0x40
	jr lt, ProcessEventDispatch_LoadReg
	ld wa, iz
	add wa, wa
	sub wa, 0x80

ProcessEventDispatch_LoadReg:
	ld bc, iz
	sla bc, 7
	or bc, wa
	ld iz, bc
	ld wa, (xsp + 4)
	ld de, iz
	ldw bc, 0x1b0
	call SndPart_SetParam
	ld wa, (xsp + 4)
	ld bc, iz
	pushw 0x5
	ld de, bc
	ldw bc, 0x1b0
	call SndParam_NotifyAndReturn
	jrl RhythmBuf_EventDispatchLoop

ProcessEventDispatch_LoadParam5:
	ld wa, (xsp + 4)
	ld de, iz
	ldw bc, 0x40
	call SndPart_SetParam
	ld wa, (xsp + 4)
	pushw 0x5
	ld de, iz
	ldw bc, 0x40
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 4)
	pushw 0x3
	ld de, iz
	ldw bc, 0x40
	call SndParam_NotifyAndReturn
	jrl RhythmBuf_EventDispatchLoop

ProcessEventDispatch_LoadParam6:
	ld wa, (xsp + 4)
	ld de, iz
	ldw bc, 0xa
	call SndPart_SetParam
	ld wa, (xsp + 4)
	pushw 0x5
	ld de, iz
	ldw bc, 0xa
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 4)
	pushw 0x3
	ld de, iz
	ldw bc, 0xa
	call SndParam_NotifyAndReturn
	jrl RhythmBuf_EventDispatchLoop

ProcessEventDispatch_LoadParam7:
	ld wa, (xsp + 4)
	ld de, iz
	ldw bc, 0xb
	call SndPart_SetParam
	ld wa, (xsp + 4)
	pushw 0x5
	ld de, iz
	ldw bc, 0xb
	call SndParam_NotifyAndReturn
	jrl RhythmBuf_EventDispatchLoop

ProcessEventDispatch_DoInit:
	ldto_berp A, 0xf8
	extz wa
	call Audio_InitDispatchReturn
	jrl RhythmBuf_EventDispatchLoop

ProcessEventDispatch_Block:
	jrl RhythmBuf_EventDispatchLoop

ProcessEventDispatch_Send:
	call Song_SendPartDataBlocks
	pop xiz
	lda xsp, (xsp + 12)
	ret

ProcessEventDispatch_Prologue:
	dec 6, xsp
	push xiz
	lds iz, 0
	call SeqEvtBuf_SaveReadPos

SeqEvtBuf_NonNoteDispatchLoop:
	call SeqEvtBuf_ReadAlternate
	ld (xsp + 4), hl
	ld wa, (xsp + 4)
	cp wa, 0xffff
	jrl z, SeqPerformance_Event_Send
	ld wa, (xsp + 4)
	cp wa, 0xd2
	jrl z, SeqEvtBuf_NoteDispatch
	cp wa, 0xd1
	jrl z, SeqEvtBuf_NoteDispatch
	cp wa, 0xd0
	jrl z, NonNoteDispatchLoop_ReadAlt2
	cp wa, 0xc2
	jr z, NonNoteDispatchLoop_ReadAlt
	cp wa, 0xc1
	jr nz, SeqEvtBuf_NonNoteDispatchLoop

NonNoteDispatchLoop_ReadAlt:
	call SeqEvtBuf_ReadAlternate
	ld (xsp + 6), hl
	ld wa, (xsp + 6)
	cp wa, 0xffff
	jr z, SeqEvtBuf_NonNoteDispatchLoop
	call SeqEvtBuf_ReadAlternate
	ld (xsp + 8), hl
	ld wa, (xsp + 8)
	cp wa, 0xffff
	jr z, SeqEvtBuf_NonNoteDispatchLoop
	ld wa, (xsp + 4)
	and wa, 0xf
	lda_24 xbc, 0xee8fa4
	ld_srib3 A, 0x07, 0xe4, 0xe0
	extz wa
	ld (xsp + 4), wa
	ld wa, (xsp + 8)
	bit 4, wa
	jr z, NonNoteDispatchLoop_LoadParam
	resm 4, (xsp + 8)
	setm 7, (xsp + 6)

NonNoteDispatchLoop_LoadParam:
	ld wa, (xsp + 4)
	ld de, (xsp + 6)
	lds bc, 0
	call SndPart_SetParam
	ld wa, (xsp + 4)
	ld de, (xsp + 8)
	ldw bc, 0x20
	call SndPart_SetParam
	ld wa, (xsp + 4)
	ldw bc, 0x5e
	lds de, 0
	call SndPart_SetParam
	ld wa, (xsp + 4)
	pushw 0x3
	ld de, (xsp + 8)
	lds bc, 0
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 4)
	pushw 0x3
	ld de, (xsp + 10)
	ldw bc, 0x20
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 4)
	pushw 0x3
	ldw bc, 0x5e
	lds de, 0
	call SndParam_NotifyAndReturn
	jrl SeqEvtBuf_NonNoteDispatchLoop

NonNoteDispatchLoop_ReadAlt2:
	call SeqEvtBuf_ReadAlternate
	ldfr_werp HL, 0xfa
	ldto_werp WA, 0xfa
	cp wa, 0xffff
	jrl z, SeqEvtBuf_NonNoteDispatchLoop
	call SeqEvtBuf_ReadAlternate
	ld iz, hl
	ld wa, iz
	cp wa, 0xffff
	jrl z, SeqEvtBuf_NonNoteDispatchLoop
	cpi_werp 0xfa, 3
	jrl nz, SeqEvtBuf_NonNoteDispatchLoop
	cps iz, 0
	jrl nz, SeqEvtBuf_NonNoteDispatchLoop
	ldw (xsp + 8), 0x17
	cpw (xsp + 8), 0x18
	jrl ge, SeqEvtBuf_NonNoteDispatchLoop

NonNoteDispatchLoop_LoadParam2:
	ld wa, (xsp + 8)
	lds bc, 1
	lds de, 0
	call SndPart_SetParam
	ld wa, (xsp + 8)
	ldw bc, 0x1b0
	ldw de, 0x2000
	call SndPart_SetParam
	ld wa, (xsp + 8)
	ldw bc, 0x40
	lds de, 0
	call SndPart_SetParam
	ld wa, (xsp + 8)
	ldw bc, 0xb
	ldw de, 0x7f
	call SndPart_SetParam
	ld wa, (xsp + 8)
	pushw 0x3
	lds bc, 1
	lds de, 0
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 8)
	pushw 0x3
	ldw bc, 0x1b0
	ldw de, 0x2000
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 8)
	pushw 0x3
	ldw bc, 0x40
	lds de, 0
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 8)
	pushw 0x3
	ldw bc, 0xb
	ldw de, 0x7f
	call SndParam_NotifyAndReturn
	incm 1, (xsp + 8)
	cpw (xsp + 8), 0x18
	jr lt, NonNoteDispatchLoop_LoadParam2
	jrl SeqEvtBuf_NonNoteDispatchLoop

; Sequencer event buffer note dispatch
SeqEvtBuf_NoteDispatch:
	call SeqEvtBuf_ReadAlternate
	ldfr_werp HL, 0xfa
	ldto_werp WA, 0xfa
	cp wa, 0xffff
	jrl z, SeqEvtBuf_NonNoteDispatchLoop
	call SeqEvtBuf_ReadAlternate
	ld iz, hl
	ld wa, iz
	cp wa, 0xffff
	jrl z, SeqEvtBuf_NonNoteDispatchLoop
	ld wa, (xsp + 4)
	and wa, 0xf
	lda_24 xbc, 0xee8fa4
	ld_srib3 A, 0x07, 0xe4, 0xe0
	extz wa
	ld (xsp + 4), wa
	ldto_werp WA, 0xfa
	dec 1, wa
	cps wa, 0
	jrl lt, SeqPerformance_Event_Block
	cps wa, 6
	jrl gt, SeqPerformance_Event_Block
	add wa, wa
	lda_24 xix, 0xee8fc0
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, SeqPerformance_EventDispatch
	jp_dri 8, 0x07, 0xf0, 0xe0

; Sequence performance event dispatch (6-entry, table 0xee8fc0)
SeqPerformance_EventDispatch:
	ld	wa, (xsp+4)
	ld	de, iz
	lds	bc, 1
	call	SndPart_SetParam
	ld	wa, (xsp+4)
	pushw	3
	ld	de, iz
	lds	bc, 1
	call	SndParam_NotifyAndReturn
	jrl	-505
	lds	wa, 0
	cp	iz, 64
	jr	lt, 8
	ld	wa, iz
	add	wa, wa
	sub	wa, 128
	ld	bc, iz
	sla	bc, 7
	or	bc, wa
	ld	iz, bc
	ld	wa, (xsp+4)
	ld	de, iz
	ldw	bc, 432
	call	SndPart_SetParam
	ld	wa, (xsp+4)
	ld	bc, iz
	pushw	3
	ld	de, bc
	ldw	bc, 432
	call	SndParam_NotifyAndReturn
	jrl	-562
	ld	wa, (xsp+4)
	ld	de, iz
	ldw	bc, 64
	call	SndPart_SetParam
	ld	wa, (xsp+4)
	pushw	3
	ld	de, iz
	ldw	bc, 64
	call	SndParam_NotifyAndReturn
	jrl	-592
	ld	wa, (xsp+4)
	ld	de, iz
	ldw	bc, 10
	call	SndPart_SetParam
	ld	wa, (xsp+4)
	pushw	3
	ld	de, iz
	ldw	bc, 10
	call	SndParam_NotifyAndReturn
	jrl	-622
	ld	wa, (xsp+4)
	ld	de, iz
	ldw	bc, 11
	call	SndPart_SetParam
	ld	wa, (xsp+4)
	pushw	3
	ld	de, iz
	ldw	bc, 11
	call	SndParam_NotifyAndReturn
	jrl	-652
	ld	wa, (xsp+4)
	ld	de, iz
	ldw	bc, 94
	call	SndPart_SetParam
	ld	wa, (xsp+4)
	pushw	3
	ld	de, iz
	ldw	bc, 94
	call	SndParam_NotifyAndReturn
	jrl	-682

SeqPerformance_Event_Block:
	jrl SeqEvtBuf_NonNoteDispatchLoop

SeqPerformance_Event_Send:
	call Song_SendPartDataBlocks
	pop xiz
	inc 6, xsp
	ret

SndParam_DispatchReturn:
	ret

VoiceMap_AllocateSlot:
	ldb l, 0xff
	cpdi16 52838, 0
	jr nz, VoiceMap_AllocateSlo_Block
	ldada xwa, 52770
	calr NoteMap_GetVoiceData_Entry
	cp l, 0xff
	jr z, VoiceMap_AllocateSlo_SetByteFF
	calr UIParam_ScanAndCollect
	ldmm8 52910, 52959
	ldmm8 52912, 52960
	ldda16 xwa, 52772
	ld l, a
	jr NoteMap_FindBestMatch_Return

VoiceMap_AllocateSlo_SetByteFF:
	ldb l, 0xff
	jr NoteMap_FindBestMatch_Return

VoiceMap_AllocateSlo_Block:
	cpdi16 52770, 0
	jr nz, VoiceMap_AllocateSlo_Block2
	calr Voice_ResetSearchState
	stdi8 52910, 255
	stdi8 52912, 255
	ldda16 xwa, 52772
	ld l, a
	jr NoteMap_FindBestMatch_Return

VoiceMap_AllocateSlo_Block2:
	ldada xwa, 52770
	calr NoteMap_GetVoiceData_Entry
	cp l, 0xff
	jr z, VoiceMap_AllocateSlo_SetByteFF2
	stdi8 59836, 10
	ldda8 a, 52908
	cpda8 a, 52906
	jr nz, VoiceMap_AllocateSlo_Block3
	ldda16 xwa, 52772
	cpda16 xwa, 52840
	jr z, VoiceMap_AllocateSlo_SetByteFF2

VoiceMap_AllocateSlo_Block3:
	stdi8 52914, 1

VoiceMap_AllocateSlo_SetByteFF2:
	ldb l, 0xff

NoteMap_FindBestMatch_Return:
	ret

; ============================================================================
; NoteMap_FindBestMatch - Find the best voice to steal for a new note
; ============================================================================
; Input:  Implicit (reads from note map state variables at 52770+)
; Output: L = voice index to steal (0xff if no suitable candidate)
; Implements voice stealing algorithm: compares current note parameters
; against the last-used voice state (addresses 52906-52960) to determine
; if reuse is possible. Falls back to searching for the least-important
; active voice when direct reuse is not available.
; ============================================================================
NoteMap_FindBestMatch:
	ldb l, 0xff
	stdi8 59836, 0
	cpdi16 52770, 0
	jr z, CheckVoiceReuse_Block
	ldda8 a, 52959
	cpda8 a, 52910
	jr nz, NoteMap_CheckVoiceReuse
	ldda8 a, 52960
	cpda8 a, 52912
	jr nz, NoteMap_CheckVoiceReuse
	ldda8 a, 52908
	cpda8 a, 52906
	jr nz, NoteMap_CheckVoiceReuse
	cpdi8 52914, 0
	jr z, CheckVoiceReuse_SetByteFF2

NoteMap_CheckVoiceReuse:
	ldada xwa, 52770
	calr NoteMap_GetVoiceData_Entry
	cp l, 0xff
	jr z, CheckVoiceReuse_SetByteFF
	calr UIParam_ScanAndCollect
	ldmm8 52910, 52959
	ldmm8 52912, 52960
	ldda16 xwa, 52772
	ld l, a
	jr NoteMap_GetVoiceData_Return

CheckVoiceReuse_SetByteFF:
	ldb l, 0xff
	jr NoteMap_GetVoiceData_Return

CheckVoiceReuse_SetByteFF2:
	ldb l, 0xff
	jr NoteMap_GetVoiceData_Return

CheckVoiceReuse_Block:
	calr Voice_ResetSearchState
	stdi8 52910, 255
	stdi8 52912, 255
	ldda16 xwa, 52772
	ld l, a

NoteMap_GetVoiceData_Return:
	ret

NoteMap_GetVoiceData_Entry:
	ldda8 c, 52906
	stda8 52908, c
	ldda8 c, 52907
	stda8 52909, c
	cpw (xwa), 0x0
	jr z, GetVoiceData_Entry_Block2
	ld l, (xwa + 5)
	ld h, (xwa + 4)
	lds de, 1
	cp de, (xwa)
	jr nc, GetVoiceData_Entry_Compare

GetVoiceData_Entry_LoopBody:
	ld bc, de
	extz xbc
	add xbc, xbc
	inc 4, xbc
	add xbc, xwa
	cp l, (xbc + 1)
	jr ule, GetVoiceData_Entry_LoopCheck
	ld bc, de
	extz xbc
	add xbc, xbc
	inc 4, xbc
	add xbc, xwa
	ld l, (xbc + 1)
	ld bc, de
	extz xbc
	add xbc, xbc
	inc 4, xbc
	add xbc, xwa
	ld h, (xbc)

GetVoiceData_Entry_LoopCheck:
	inc 1, de
	cp de, (xwa)
	jr c, GetVoiceData_Entry_LoopBody

GetVoiceData_Entry_Compare:
	cp l, 0x18
	jr ule, GetVoiceData_Entry_Block
	cp l, 0x67
	jr nc, GetVoiceData_Entry_Block
	stda8 52906, l
	stda8 52907, h
	jr Voice_ReadSearchResult

GetVoiceData_Entry_Block:
	stdi8 52906, 255
	stdi8 52907, 255
	jr Voice_ReadSearchResult

GetVoiceData_Entry_Block2:
	stdi8 52906, 255
	stdi8 52907, 255

Voice_ReadSearchResult:
	ldda8 l, 52906
	ret

Voice_ResetSearchState:
	stdi16 52838, 0
	stdi8 52914, 0
	ret

UIParam_ScanAndCollect:
	lda xsp, (xsp - 68)
	push_werp 0xfa
	stdi8 52914, 0
	cpdi8 52907, 15
	jr ule, UIParam_SetDefaultCount
	ldda8 a, 52907
	sub a, 0xf
	ldfr_berp A, 0xfb
	jr UIParam_CallbackDispatch

UIParam_SetDefaultCount:
	ldi_berp 0xfb, 1

; UIParam callback dispatch
UIParam_CallbackDispatch:
	lda xwa, (xsp + 2)
	ldda8 c, 59838
	extz bc
	sla bc, 2
	lda_24 xde, 0xeeae04
	exts xbc
	add xbc, xde
	ld xix, (xbc)
	call (xix)
	cps l, 0
	jr z, UIParam_StoreAndReturn
	lds hl, 0
	jr UIParam_CompareResult

; UI parameter callback return (table 0xeeae04)
UIParam_CallbackReturn:
	ld wa, hl
	extz xwa
	add xwa, xwa
	inc 4, xwa
	lda xbc, (xsp + 3)
	ld xix, xbc
	add xix, xwa
	ld wa, hl
	add wa, wa
	inc 4, wa
	ldada xbc, 52839
	ld de, wa
	extz xde
	add xde, xbc
	ld a, (xix)
	ld (xde), a
	ld wa, hl
	add wa, wa
	ldada xbc, 52842
	ld de, wa
	extz xde
	add xde, xbc
	ldto_berp A, 0xfb
	ld (xde), a
	inc 1, hl

UIParam_CompareResult:
	cp hl, (xsp + 2)
	jr c, UIParam_CallbackReturn

UIParam_StoreAndReturn:
	ldda16 xwa, 52772
	stda16 52840, xwa
	ld wa, (xsp + 2)
	stda16 52838, xwa
	pop_werp 0xfa
	lda xsp, (xsp + 68)
	ret

NoteMap_SearchVoiceEntry:
	cpdi16 53087, 0
	jrl z, SearchVoice_SetZero
	lds hl, 0
	lds de, 0
	jr SearchVoice_CheckCount

SearchVoice_EntryLoop:
	cps de, 4
	jr z, SearchVoice_StoreResult
	ld bc, hl
	add bc, bc
	inc 4, bc
	ldada xix, 53088
	extz xbc
	add xbc, xix
	ld c, (xbc)
	ldfr_berp C, 0xea
	ldda8 c, 52906
	ldto_berp B, 0xea
	cp b, c
	jr gt, SearchVoice_CheckHighBound
	ldda8 c, 52906
	sub c, 0xc
	ld b, c
	ldto_berp C, 0xea
	cp c, b
	jr ule, SearchVoice_CheckLowBound
	jr SearchVoice_CheckDistance

SearchVoice_OctaveDown:
	sub_erpb 0xea, 0x0c

SearchVoice_CheckHighBound:
	ldda8 c, 52906
	ldto_berp B, 0xea
	cp b, c
	jr gt, SearchVoice_OctaveDown
	jr SearchVoice_CheckDistance

SearchVoice_OctaveUp:
	add_erpb 0xea, 0x0c

SearchVoice_CheckLowBound:
	ldda8 c, 52906
	sub c, 0xc
	ld b, c
	ldto_berp C, 0xea
	cp c, b
	jr ule, SearchVoice_OctaveUp

SearchVoice_CheckDistance:
	ldda8 c, 52906
	sub_berp C, 0xea
	cps c, 2
	jr ule, SearchVoice_NextEntry
	ld bc, de
	extz xbc
	add xbc, xbc
	inc 4, xbc
	ld xix, xbc
	add xix, xwa
	ldto_berp C, 0xea
	ld (xix + 1), c
	inc 1, de

SearchVoice_NextEntry:
	inc 1, hl

SearchVoice_CheckCount:
	cpda16 xhl, 53087
	jr c, SearchVoice_EntryLoop

SearchVoice_StoreResult:
	ld c, e
	extz bc
	ld (xwa), bc
	jr SearchVoice_SortCheck

SearchVoice_SetZero:
	ldw (xwa), 0x0

SearchVoice_SortCheck:
	cpw (xwa), 0x1
	jr ule, SearchVoice_Done
	ld hl, (xwa)
	sub hl, 0x1
	jr z, SearchVoice_Done

SearchVoice_BubbleSortOuter:
	lds de, 0
	cp de, hl
	jr nc, SearchVoice_BubbleOuterNext

SearchVoice_BubbleSortInner:
	ld bc, de
	extz xbc
	add xbc, xbc
	inc 4, xbc
	ld xiy, xbc
	add xiy, xwa
	ld bc, de
	inc 1, bc
	extz xbc
	add xbc, xbc
	inc 4, xbc
	ld xix, xbc
	add xix, xwa
	ld c, (xiy + 1)
	cp c, (xix + 1)
	jr nc, SearchVoice_BubbleAdvance
	ld bc, de
	extz xbc
	add xbc, xbc
	inc 4, xbc
	add xbc, xwa
	ld c, (xbc + 1)
	ldfr_berp C, 0xea
	ld bc, de
	extz xbc
	add xbc, xbc
	inc 4, xbc
	ld xix, xbc
	add xix, xwa
	ld bc, de
	inc 1, bc
	extz xbc
	add xbc, xbc
	inc 4, xbc
	add xbc, xwa
	ld c, (xbc + 1)
	ld (xix + 1), c
	ld bc, de
	inc 1, bc
	extz xbc
	add xbc, xbc
	inc 4, xbc
	ld xix, xbc
	add xix, xwa
	ldto_berp C, 0xea
	ld (xix + 1), c

SearchVoice_BubbleAdvance:
	inc 1, de
	cp de, hl
	jr c, SearchVoice_BubbleSortInner

SearchVoice_BubbleOuterNext:
	sub hl, 0x1
	jr nz, SearchVoice_BubbleSortOuter

SearchVoice_Done:
	ld hl, (xwa)
	ret

SoundFX_Handler_12:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr NoteMap_SearchVoiceEntry
	cps l, 0
	jr z, SoundFX_Handler_12_LoadReg
	ldw (xiz), 0x1

SoundFX_Handler_12_LoadReg:
	ld hl, (xiz)
	pop xiz
	ret

SoundFX_Handler_0:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr NoteMap_SearchVoiceEntry
	cps l, 0
	jr z, SoundFX_Handler_0_LoadReg
	submi8 (xiz + 5), 0xc

SoundFX_Handler_0_LoadReg:
	ld hl, (xiz)
	pop xiz
	ret

SoundFX_Handler_1:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr NoteMap_SearchVoiceEntry
	cps l, 0
	jr z, SoundFX_SetVolumeOffset_Return
	cpw (xiz), 0x1
	jr nz, SoundFX_Handler_1_Block
	ldda8 a, 52906
	sub a, (xiz + 5)
	cp a, 0x8
	jr ugt, SoundFX_SetVolumeOffset_Return
	addmi8 (xiz + 5), 0xc
	jr SoundFX_SetVolumeOffset_Return

SoundFX_Handler_1_Block:
	submi8 (xiz + 5), 0xc
	ld de, (xiz)
	sub de, 0x1
	jr z, SoundFX_SetVolumeOffset_Return

SoundFX_Handler_1_LoadReg:
	ld wa, de
	extz xwa
	add xwa, xwa
	inc 4, xwa
	ld xbc, xwa
	add xbc, xiz
	ldda8 a, 52906
	sub a, (xbc + 1)
	cp a, 0x8
	jr ugt, SoundFX_Handler_1_Block2
	ld wa, de
	extz xwa
	add xwa, xwa
	inc 4, xwa
	add xwa, xiz
	addmi8 (xwa + 1), 0xc
	jr SoundFX_SetVolumeOffset_Return

SoundFX_Handler_1_Block2:
	djnz xde, SoundFX_Handler_1_LoadReg

SoundFX_SetVolumeOffset_Return:
	ld hl, (xiz)
	pop xiz
	ret

SoundFX_Handler_2:
	push xiz
	ld xiz, xwa
	ldda8 a, 52959
	ld e, a
	extz de
	ldda8 a, 52960
	ld c, a
	extz bc
	ld wa, de
	calr VoiceBank_MapNoteToOffset
	ld a, l
	cp a, 0xff
	jr z, SoundFX_Handler_2_ClearWord
	ldda8 a, 52906
	subda8 a, 52960
	add a, l
	inc 1, a
	ld l, a
	extz wa
	div a, 0xc
	ld l, w
	ld e, l
	extz de
	ldda8 a, 52959
	dec 1, a
	extz wa
	muls wa, 0xc
	lda_24 xbc, 0xee8fce
	exts xwa
	add xwa, xbc
	ld_srib3 C, 0x07, 0xe0, 0xe8
	ldda8 a, 52906
	sub a, c
	ld (xiz + 5), a
	ldw (xiz), 0x1
	jr SoundFX_Handler_2_LoadReg

SoundFX_Handler_2_ClearWord:
	ldw (xiz), 0x0

SoundFX_Handler_2_LoadReg:
	ld hl, (xiz)
	pop xiz
	ret

SoundFX_Handler_3:
	push xiz
	ld xiz, xwa
	ldda8 a, 52959
	ld e, a
	extz de
	ldda8 a, 52960
	ld c, a
	extz bc
	ld wa, de
	calr VoiceBank_MapNoteToOffset
	ld a, l
	cp a, 0xff
	jr z, SoundFX_Handler_3_ClearWord
	ldda8 a, 52906
	subda8 a, 52960
	add a, l
	inc 1, a
	ld l, a
	extz wa
	div a, 0xc
	ld l, w
	ld e, l
	extz de
	ldda8 a, 52959
	dec 1, a
	extz wa
	muls wa, 0xc
	lda_24 xbc, 0xee98fe
	exts xwa
	add xwa, xbc
	ld_srib3 C, 0x07, 0xe0, 0xe8
	ldda8 a, 52906
	sub a, c
	ld (xiz + 5), a
	ldw (xiz), 0x1
	jr SoundFX_Handler_3_LoadReg

SoundFX_Handler_3_ClearWord:
	ldw (xiz), 0x0

SoundFX_Handler_3_LoadReg:
	ld hl, (xiz)
	pop xiz
	ret

SoundFX_Handler_4:
	push xiz
	ld xiz, xwa
	ldda8 a, 52959
	ld e, a
	extz de
	ldda8 a, 52960
	ld c, a
	extz bc
	ld wa, de
	calr VoiceBank_MapNoteToOffset
	ld a, l
	cp a, 0xff
	jr z, SoundFX_Handler_4_ClearWord
	ldda8 a, 52906
	subda8 a, 52960
	add a, l
	inc 1, a
	ld l, a
	extz wa
	div a, 0xc
	ld l, w
	ld a, l
	extz wa
	ld de, wa
	add de, de
	ldda8 a, 52959
	dec 1, a
	extz wa
	muls wa, 0x18
	lda_24 xbc, 0xee911e
	exts xwa
	add xwa, xbc
	ld_srib3 C, 0x07, 0xe0, 0xe8
	ldda8 a, 52906
	sub a, c
	ld (xiz + 5), a
	ld a, l
	extz wa
	ld de, wa
	add de, de
	ldda8 a, 52959
	dec 1, a
	extz wa
	muls wa, 0x18
	lda_24 xbc, 0xee911e
	exts xwa
	add xwa, xbc
	st_dri3b W, 0x07, 0xe0, 0xe8
	ld c, (xwa + 1)
	ldda8 a, 52906
	sub a, c
	ld (xiz + 7), a
	ldw (xiz), 0x2
	jr SoundFX_Handler_4_LoadReg

SoundFX_Handler_4_ClearWord:
	ldw (xiz), 0x0

SoundFX_Handler_4_LoadReg:
	ld hl, (xiz)
	pop xiz
	ret

SoundFX_Handler_5:
	push xiz
	ld xiz, xwa
	ldda8 a, 52959
	ld e, a
	extz de
	ldda8 a, 52960
	ld c, a
	extz bc
	ld wa, de
	calr VoiceBank_MapNoteToOffset
	ld a, l
	cp a, 0xff
	jrl z, SoundFX_Handler_5_ClearWord
	ldda8 a, 52906
	subda8 a, 52960
	add a, l
	inc 1, a
	ld l, a
	extz wa
	div a, 0xc
	ld l, w
	ld a, l
	extz wa
	muls wa, 0x3
	ld de, wa
	ldda8 a, 52959
	dec 1, a
	extz wa
	muls wa, 0x24
	lda_24 xbc, 0xee9a4e
	exts xwa
	add xwa, xbc
	ld_srib3 C, 0x07, 0xe0, 0xe8
	ldda8 a, 52906
	sub a, c
	ld (xiz + 5), a
	ld a, l
	extz wa
	muls wa, 0x3
	ld de, wa
	ldda8 a, 52959
	dec 1, a
	extz wa
	muls wa, 0x24
	lda_24 xbc, 0xee9a4e
	exts xwa
	add xwa, xbc
	st_dri3b W, 0x07, 0xe0, 0xe8
	ld c, (xwa + 1)
	ldda8 a, 52906
	sub a, c
	ld (xiz + 7), a
	ld a, l
	extz wa
	muls wa, 0x3
	ld de, wa
	ldda8 a, 52959
	dec 1, a
	extz wa
	muls wa, 0x24
	lda_24 xbc, 0xee9a4e
	exts xwa
	add xwa, xbc
	st_dri3b W, 0x07, 0xe0, 0xe8
	ld c, (xwa + 2)
	ldda8 a, 52906
	sub a, c
	ld (xiz + 9), a
	ldw (xiz), 0x3
	jr SoundFX_Handler_5_LoadReg

SoundFX_Handler_5_ClearWord:
	ldw (xiz), 0x0

SoundFX_Handler_5_LoadReg:
	ld hl, (xiz)
	pop xiz
	ret

SoundFX_Handler_6:
	push xiz
	ld xiz, xwa
	ldda8 a, 52959
	ld e, a
	extz de
	ldda8 a, 52960
	ld c, a
	extz bc
	ld wa, de
	calr VoiceBank_MapNoteToOffset
	ld a, l
	cp a, 0xff
	jrl z, SoundFX_Handler_6_ClearWord
	ldda8 a, 52906
	subda8 a, 52960
	add a, l
	inc 1, a
	ld l, a
	extz wa
	div a, 0xc
	ld l, w
	ld a, l
	extz wa
	ld de, wa
	sla de, 2
	ldda8 a, 52959
	dec 1, a
	extz wa
	muls wa, 0x30
	lda_24 xbc, 0xee93be
	exts xwa
	add xwa, xbc
	ld_srib3 C, 0x07, 0xe0, 0xe8
	ldda8 a, 52906
	sub a, c
	ld (xiz + 5), a
	ld a, l
	extz wa
	ld de, wa
	sla de, 2
	ldda8 a, 52959
	dec 1, a
	extz wa
	muls wa, 0x30
	lda_24 xbc, 0xee93be
	exts xwa
	add xwa, xbc
	st_dri3b W, 0x07, 0xe0, 0xe8
	ld c, (xwa + 1)
	ldda8 a, 52906
	sub a, c
	ld (xiz + 7), a
	ld a, l
	extz wa
	ld de, wa
	sla de, 2
	ldda8 a, 52959
	dec 1, a
	extz wa
	muls wa, 0x30
	lda_24 xbc, 0xee93be
	exts xwa
	add xwa, xbc
	st_dri3b W, 0x07, 0xe0, 0xe8
	ld c, (xwa + 2)
	ldda8 a, 52906
	sub a, c
	ld (xiz + 9), a
	ld a, l
	extz wa
	ld de, wa
	sla de, 2
	ldda8 a, 52959
	dec 1, a
	extz wa
	muls wa, 0x30
	lda_24 xbc, 0xee93be
	exts xwa
	add xwa, xbc
	st_dri3b W, 0x07, 0xe0, 0xe8
	ld c, (xwa + 3)
	ldda8 a, 52906
	sub a, c
	ld (xiz + 11), a
	ldw (xiz), 0x4
	jr SoundFX_Handler_6_LoadReg

SoundFX_Handler_6_ClearWord:
	ldw (xiz), 0x0

SoundFX_Handler_6_LoadReg:
	ld hl, (xiz)
	pop xiz
	ret

SoundFX_Handler_7:
	push xiz
	ld xiz, xwa
	ldda8 a, 52959
	ld e, a
	extz de
	ldda8 a, 52960
	ld c, a
	extz bc
	ld wa, de
	calr VoiceBank_MapNoteToOffset
	ld a, l
	cp a, 0xff
	jrl z, SoundFX_Handler_7_ClearWord
	ldda8 a, 52906
	subda8 a, 52960
	add a, l
	inc 1, a
	ld l, a
	extz wa
	div a, 0xc
	ld l, w
	ld a, l
	extz wa
	muls wa, 0x3
	ld de, wa
	ldda8 a, 52959
	dec 1, a
	extz wa
	muls wa, 0x24
	lda_24 xbc, 0xee9e3e
	exts xwa
	add xwa, xbc
	ld_srib3 C, 0x07, 0xe0, 0xe8
	ldda8 a, 52906
	sub a, c
	ld (xiz + 5), a
	ld a, l
	extz wa
	muls wa, 0x3
	ld de, wa
	ldda8 a, 52959
	dec 1, a
	extz wa
	muls wa, 0x24
	lda_24 xbc, 0xee9e3e
	exts xwa
	add xwa, xbc
	st_dri3b W, 0x07, 0xe0, 0xe8
	ld c, (xwa + 1)
	ldda8 a, 52906
	sub a, c
	ld (xiz + 7), a
	ld a, l
	extz wa
	muls wa, 0x3
	ld de, wa
	ldda8 a, 52959
	dec 1, a
	extz wa
	muls wa, 0x24
	lda_24 xbc, 0xee9e3e
	exts xwa
	add xwa, xbc
	st_dri3b W, 0x07, 0xe0, 0xe8
	ld c, (xwa + 2)
	ldda8 a, 52906
	sub a, c
	ld (xiz + 9), a
	ldw (xiz), 0x3
	jr SoundFX_Handler_7_LoadReg

SoundFX_Handler_7_ClearWord:
	ldw (xiz), 0x0

SoundFX_Handler_7_LoadReg:
	ld hl, (xiz)
	pop xiz
	ret

SoundFX_Handler_8:
	push xiz
	ld xiz, xwa
	ldda8 a, 52959
	ld e, a
	extz de
	ldda8 a, 52960
	ld c, a
	extz bc
	ld wa, de
	calr VoiceBank_MapNoteToOffset
	ld a, l
	cp a, 0xff
	jrl z, SoundFX_Handler_8_ClearWord
	ldda8 a, 52906
	subda8 a, 52960
	add a, l
	inc 1, a
	ld l, a
	extz wa
	div a, 0xc
	ld l, w
	ld a, l
	extz wa
	ld de, wa
	sla de, 2
	ldda8 a, 52959
	dec 1, a
	extz wa
	muls wa, 0x30
	lda_24 xbc, 0xeea8be
	exts xwa
	add xwa, xbc
	ld_srib3 C, 0x07, 0xe0, 0xe8
	ldda8 a, 52906
	sub a, c
	ld (xiz + 5), a
	ld a, l
	extz wa
	ld de, wa
	sla de, 2
	ldda8 a, 52959
	dec 1, a
	extz wa
	muls wa, 0x30
	lda_24 xbc, 0xeea8be
	exts xwa
	add xwa, xbc
	st_dri3b W, 0x07, 0xe0, 0xe8
	ld c, (xwa + 1)
	ldda8 a, 52906
	sub a, c
	ld (xiz + 7), a
	ld a, l
	extz wa
	ld de, wa
	sla de, 2
	ldda8 a, 52959
	dec 1, a
	extz wa
	muls wa, 0x30
	lda_24 xbc, 0xeea8be
	exts xwa
	add xwa, xbc
	st_dri3b W, 0x07, 0xe0, 0xe8
	ld c, (xwa + 2)
	ldda8 a, 52906
	sub a, c
	ld (xiz + 9), a
	ld a, l
	extz wa
	ld de, wa
	sla de, 2
	ldda8 a, 52959
	dec 1, a
	extz wa
	muls wa, 0x30
	lda_24 xbc, 0xeea8be
	exts xwa
	add xwa, xbc
	st_dri3b W, 0x07, 0xe0, 0xe8
	ld c, (xwa + 3)
	ldda8 a, 52906
	sub a, c
	ld (xiz + 11), a
	ldw (xiz), 0x4
	jr SoundFX_Handler_8_LoadReg

SoundFX_Handler_8_ClearWord:
	ldw (xiz), 0x0

SoundFX_Handler_8_LoadReg:
	ld hl, (xiz)
	pop xiz
	ret

SoundFX_Handler_9:
	ld8_24 e, 0xeeadfe
	ldda8 c, 52906
	sub c, e
	ld (xwa + 5), c
	ld8_24 e, 0xeeadff
	ldda8 c, 52906
	sub c, e
	ld (xwa + 7), c
	ldw (xwa), 0x2
	lds hl, 2
	ret

SoundFX_Handler_10:
	ld8_24 e, 0xeeae00
	ldda8 c, 52906
	sub c, e
	ld (xwa + 5), c
	ld8_24 e, 0xeeae01
	ldda8 c, 52906
	sub c, e
	ld (xwa + 7), c
	ldw (xwa), 0x2
	lds hl, 2
	ret

SoundFX_Handler_11:
	ld8_24 e, 0xeeae02
	ldda8 c, 52906
	sub c, e
	ld (xwa + 5), c
	ld8_24 e, 0xeeae03
	ldda8 c, 52906
	sub c, e
	ld (xwa + 7), c
	ldw (xwa), 0x2
	lds hl, 2
	ret

VoiceBank_MapNoteToOffset:
	ldb l, 0xff
	cps a, 7
	jr z, MapNoteToOffset_Compare4
	cps a, 4
	jr z, MapNoteToOffset_Compare
	cps a, 0
	jr nz, MapNoteToOffset_ClearByte3
	jr Audio_NullRet1

MapNoteToOffset_Compare:
	cps c, 1
	jr nc, MapNoteToOffset_ClearByte
	cps c, 4
	jr ugt, MapNoteToOffset_Compare2

MapNoteToOffset_ClearByte:
	ldb l, 0x0
	jr Audio_NullRet1

MapNoteToOffset_Compare2:
	cps c, 5
	jr nc, MapNoteToOffset_SetByte
	cp c, 0x8
	jr ugt, MapNoteToOffset_Compare3

MapNoteToOffset_SetByte:
	ldb l, 0x4
	jr Audio_NullRet1

MapNoteToOffset_Compare3:
	cp c, 0x9
	jr nc, MapNoteToOffset_SetByte2
	cp c, 0xc
	ret ugt

MapNoteToOffset_SetByte2:
	ldb l, 0x8
	jr Audio_NullRet1

MapNoteToOffset_Compare4:
	cps c, 1
	jr nc, MapNoteToOffset_ClearByte2
	cps c, 3
	jr ugt, MapNoteToOffset_Compare5

MapNoteToOffset_ClearByte2:
	ldb l, 0x0
	jr Audio_NullRet1

MapNoteToOffset_Compare5:
	cps c, 4
	jr nc, MapNoteToOffset_SetByte3
	cps c, 6
	jr ugt, MapNoteToOffset_Compare6

MapNoteToOffset_SetByte3:
	ldb l, 0x3
	jr Audio_NullRet1

MapNoteToOffset_Compare6:
	cps c, 7
	jr nc, MapNoteToOffset_SetByte4
	cp c, 0x9
	jr ugt, MapNoteToOffset_Compare7

MapNoteToOffset_SetByte4:
	ldb l, 0x6
	jr Audio_NullRet1

MapNoteToOffset_Compare7:
	cp c, 0xa
	jr nc, MapNoteToOffset_SetByte5
	cp c, 0xc
	ret ugt

MapNoteToOffset_SetByte5:
	ldb l, 0x9
	jr Audio_NullRet1

MapNoteToOffset_ClearByte3:
	ldb l, 0x0

Audio_NullRet1:
	ret

Audio_NullRet1_Data:
	jp	NullRet2_Block
	ret
	nop
	nop
	nop
	ret
	nop
	nop
	nop
	ret
	nop
	nop
	nop
	ret
	nop
	nop
	nop
	ret
	nop
	nop
	nop
	ret

Voice_UpdateNoteState:
	cpdi8 52917, 0
	jr z, UpdateNoteState_CheckDRAM
	decdi8 1, 52917
	jr z, Voice_CheckAndUpdateMode

UpdateNoteState_CheckDRAM:
	cpdi8 52916, 0
	jr z, UpdateNoteState_CheckDRAM2
	decdi8 1, 52916
	jr z, Voice_CheckAndUpdateMode

UpdateNoteState_CheckDRAM2:
	cpdi8 52915, 0
	jr z, Voice_ProcessControllers_Return
	decdi8 1, 52915
	jr z, Voice_CheckAndUpdateMode

Voice_CheckAndUpdateMode:
	ldda16 xde, 50582
	and de, 0x2000
	jr nz, Voice_ProcessControllers_Return
	call Voice_UpdatePlayModeState
	cp l, 0xff
	jr z, Voice_ProcessControllers_Return
	call VoiceEvent_AllocAllLayers

Voice_ProcessControllers_Return:
	ret

ProcessControllers_R_Prologue:
	push xix
	push xiz
	push xde
	ldda16 xde, 50582
	and de, 0x2000
	jr nz, PlayMode_StoreResult
	cpdi16_24 52993, 2
	jr z, ProcessControllers_R_LoadDRAM
	cpdi16_24 52993, 3
	jr z, ProcessControllers_R_LoadDRAM
	jr PlayMode_ClearBit6

ProcessControllers_R_LoadDRAM:
	ldda16 xde, 50584
	and de, 0x20
	jr z, PlayMode_UpdateAndReturn
	ordi8_24 52958, 64
	jr PlayMode_UpdateAndReturn

PlayMode_ClearBit6:
	anddi8_24 52958, 191
	jr PlayMode_UpdateAndReturn

PlayMode_UpdateAndReturn:
	calr Voice_DispatchByTimingState
	calr __jrt_nop_FEA344_LoadReg
	anddi8_24 52958, 191
	ld16_24 xhl, 0x00cf01
	anddi16_24 52993, 255
	cp h, 0xff
	jr z, PlayMode_SetZeroResult
	ldw hl, 0xff
	jr PlayMode_StoreResult

PlayMode_SetZeroResult:
	ldb h, 0x0
	jr PlayMode_StoreResult

PlayMode_StoreResult:
	pop xde
	pop xiz
	pop xix
	ret

Voice_UpdatePlayModeState:
	push xix
	push xiz
	push xde
	cpdi16_24 52993, 2
	jr z, PlayMode_CheckModes23
	cpdi16_24 52993, 3
	jr z, PlayMode_CheckModes23
	jr PlayMode_ClearBit6_Alt

PlayMode_CheckModes23:
	ldda16 xde, 50584
	and de, 0x20
	jr z, PlayMode_CheckSlotAndReturn
	ordi8_24 52958, 64
	jr PlayMode_CheckSlotAndReturn

PlayMode_ClearBit6_Alt:
	anddi8_24 52958, 191
	jr PlayMode_CheckSlotAndReturn

PlayMode_CheckSlotAndReturn:
	calr Voice_CheckAndResetSlotState
	anddi8_24 52958, 191
	ld16_24 xhl, 0x00cf01
	anddi16_24 52993, 255
	cp h, 0xff
	jr z, PlayMode_SetZero_Alt
	ldw hl, 0xff
	jr PlayMode_Epilogue

PlayMode_SetZero_Alt:
	ldb h, 0x0
	jr PlayMode_Epilogue

PlayMode_Epilogue:
	pop xde
	pop xiz
	pop xix
	ret

Voice_DispatchByTimingState:
	ld16_24 xbc, 0x00ceff
	cps bc, 0
	jr z, VoiceTiming_ResetSlot
	bitda_24 0, 52958
	jr nz, VoiceTiming_ResetSlot
	jr VoiceTiming_CheckBit6

VoiceTiming_ResetSlot:
	calr Voice_CheckAndResetSlotState
	jr Voice_AdjustTiming_Return

VoiceTiming_CheckBit6:
	bitda_24 6, 52958
	jr z, VoiceTiming_CheckBit7
	calr Voice_CheckAndResetSlotState
	jr Voice_AdjustTiming_Return

VoiceTiming_CheckBit7:
	bitda_24 7, 52958
	jr z, VoiceTiming_CompareThreshold
	calr Voice_UpdateVelocity_Entry
	jr Voice_AdjustTiming_Return

VoiceTiming_CompareThreshold:
	cpda16 xbc, 53015
	jr c, VoiceTiming_EqualThreshold
	calr Voice_UpdateVelocity_Entry
	jr Voice_AdjustTiming_Return

VoiceTiming_EqualThreshold:
	cpda16 xbc, 53015
	jr ugt, VoiceTiming_BelowThreshold
	calr Voice_SetDecayTimer
	jr Voice_AdjustTiming_Return

VoiceTiming_BelowThreshold:
	calr Voice_MatchVoicePairs

Voice_AdjustTiming_Return:
	ret

Voice_UpdateVelocity_Entry:
	bitda_24 6, 52958
	jr nz, Voice_CheckAndUpdateSlot
	cpdi16 53015, 0
	jr z, VelocityUpdate_CheckNoThreshold
	bitda_24 7, 52958
	jr z, VelocityUpdate_CheckBit4
	ldda16 xde, 50582
	and de, 0x2
	jr nz, Voice_CheckAndUpdateSlot

VelocityUpdate_CheckBit4:
	bitda_24 4, 52958
	jr z, Voice_CheckAndUpdateSlot
	jr VelocityUpdate_SetTimerValue

VelocityUpdate_CheckNoThreshold:
	ldda16 xde, 50582
	and de, 0x2
	jr z, Voice_CheckAndUpdateSlot
	bitda_24 4, 52958
	jr z, Voice_CheckAndUpdateSlot
	cpi8_24 0x00cee0, 0x00
	jr z, Voice_CheckAndUpdateSlot

VelocityUpdate_SetTimerValue:
	cpdi8 52915, 0
	jr nz, VelocityUpdate_Return
	stdi8 52915, 5
	jr VelocityUpdate_Return

Voice_CheckAndUpdateSlot:
	calr Voice_CheckAndResetSlotState

VelocityUpdate_Return:
	ret

Voice_SetDecayTimer:
	ldda16 xde, 50582
	and de, 0x2
	jr z, DecayTimer_SetShort
	cps bc, 2
	jr ule, DecayTimer_SetLong

DecayTimer_SetShort:
	stdi8 52916, 6
	jr DecayTimer_Return

DecayTimer_SetLong:
	stdi8 52916, 22

DecayTimer_Return:
	ret

Voice_MatchVoicePairs:
	ld xiy, 0xceff
	ld bc, (xiy + 256)
	ld xix, 0xcf17

VoicePair_OuterLoop:
	ld de, (xix + 256)
	ld w, (xiy + 5)

VoicePair_InnerScan:
	cp w, (xix + 5)
	jr z, VoicePair_AdvanceOuter
	inc 2, ix
	dec 1, de
	jr nz, VoicePair_InnerScan
	calr Voice_UpdateVelocity_Entry
	jr VoicePair_Return

VoicePair_AdvanceOuter:
	inc 2, iy
	djnz xbc, VoicePair_OuterLoop

VoicePair_Return:
	ret

Voice_CheckAndResetSlotState:
	ld16_24 xbc, 0x00ceff
	stdi8 52915, 0
	stdi8 52916, 0
	cps bc, 0
	jr z, CheckAndResetSlotSta_Block
	calr NullRet2_TestBit24
	jr Voice_NullRet2

CheckAndResetSlotSta_Block:
	ordi8_24 52958, 128
	sti8_24 0x00cee4, 0x00
	ldda8 e, 64607
	and e, 0x30
	jr nz, Voice_NullRet2
	ldda8 e, 64608
	and e, 0x30
	jr nz, Voice_NullRet2
	ldda16 xde, 50584
	and de, 0x2
	jr nz, CheckAndResetSlotSta_LoadDRAM
	bitda_24 6, 52958
	jr nz, CheckAndResetSlotSta_Block2

CheckAndResetSlotSta_LoadDRAM:
	ldda16 xde, 50584
	and de, 0x2
	jr nz, CheckAndResetSlotSta_LoadDRAM2
	bitda_24 6, 52958
	jr nz, CheckAndResetSlotSta_Block2

CheckAndResetSlotSta_LoadDRAM2:
	ldda16 xde, 50582
	and de, 0x10
	jr nz, Voice_NullRet2

CheckAndResetSlotSta_Block2:
	calr NullRet2_Block
	jr Voice_NullRet2

Voice_NullRet2:
	ret

NullRet2_Block:
	sti16_24 0x00ceff, 0x0000
	sti8_24 0x00cee5, 0x00
	sti8_24 0x00cef1, 0x00
	sti8_24 0x00cee0, 0x00
	sti8_24 0x00cedf, 0x00
	ordi8_24 52958, 128
	anddi8_24 52958, 249
	sti8_24 0x00cee1, 0x00
	sti8_24 0x00cee4, 0x00
	calr __jrt_nop_FEA013_Block2
	ret

NullRet2_Data:
	nop
	incf
	push_f
	ldb	d, 0
	.byte 0xdc
	cp	xix, xwa

NullRet2_TestBit24:
	bitda_24 6, 52958
	jr nz, EffectState_Dispatch
	ldda16 xde, 50582
	and de, 0x1
	jr nz, NullRet2_Block2
	ldda16 xde, 50582
	and de, 0x2
	jr nz, EffectState_Dispatch
	ldda16 xde, 50584
	and de, 0x2
	jr nz, EffectState_Dispatch
	ldda16 xde, 50582
	and de, 0x4
	jr nz, EffectState_Dispatch_Block
	jr EffectState_Dispatch

NullRet2_Block2:
	calr EffectState_Dispatch_Block3
	jr EffectState_Dispatch_Block2

EffectState_Dispatch:
	calr __jrt_nop_FE9955_Block
	jr EffectState_Dispatch_Block2

EffectState_Dispatch_Block:
	calr __jrt_nop_FE9A0A_Block3

EffectState_Dispatch_Block2:
	calr __jrt_nop_FEA013_Block2
	ret

EffectState_Dispatch_Block3:
	sti8_24 0x00cee5, 0x04
	ld16_24 xde, 0x00ceff
	calr __jrt_nop_FE9709_Block2
	calr __jrt_nop_FE9709_LoadReg3
	jr __jrt_nop_FE9709
__jrt_nop_FE9709:

__jrt_nop_FE9709_Block:
	st8_24 0x00cedf, a
	st8_24 0x00cee0, w
	sti8_24 0x00cee1, 0x00
	anddi8_24 52958, 249
	ret

__jrt_nop_FE9709_Block2:
	sti16_24 0x00cf2f, 0x0000
	ld xiy, 0xceff
	ld xix, 0xcf8f
	ld hl, de
	dec 1, hl
	sla hl, 1
	add iy, hl
	cps de, 0
	jr nz, __jrt_nop_FE9709_OrBits
	sti8_24 0x00cee5, 0x00
	jr __jrt_nop_FE9709_Return

__jrt_nop_FE9709_OrBits:
	xor wa, wa
	ldfr_werp WA, 0x30
	xor b, b
	xor h, h

__jrt_nop_FE9709_LoadReg:
	ld l, (xiy + 5)
	ld xiz, 0xfea356
	ld_srib3 C, 0x03, 0xf8, 0xec
	ldto_werp WA, 0x30
	ld xiz, __jrt_nop_FEA344_Data2
	and_sriw_rm WA, 0x03, 0xf8, 0xe4
	jr nz, __jrt_nop_FE9709_Decrement
	or_sriw_rm WA, 0x03, 0xf8, 0xe4
	ldfr_werp WA, 0x30
	ld (xix), l
	inc 1, ix
	inc 1, b
	cpda8_24 b, 52965
	jr nc, __jrt_nop_FE9709_Block3

__jrt_nop_FE9709_Decrement:
	dec 1, iy
	dec 1, iy
	dec 1, de
	cps de, 0
	jr nz, __jrt_nop_FE9709_LoadReg

__jrt_nop_FE9709_Block3:
	st8_24 0x00cee5, b
	ld c, b
	xor b, b
	ld xix, 0xcee6
	ld xiy, 0xcf8f
	add iy, bc
	dec 1, iy

__jrt_nop_FE9709_LoadReg2:
	ld a, (xiy)
	ld (xix), a
	dec 1, iy
	inc 1, ix
	djnz xbc, __jrt_nop_FE9709_LoadReg2

__jrt_nop_FE9709_Return:
	ret

__jrt_nop_FE9709_LoadReg3:
	ld xiy, 0xceff
	ld16_24 xbc, 0x00ceff
	xor a, a
	xor h, h
	cps bc, 0
	jr z, __jrt_nop_FE9709_LoadReg5

__jrt_nop_FE9709_LoadReg4:
	ld l, (xiy + 5)
	cpda8_24 l, 52966
	jr z, __jrt_nop_FE9709_Increment
	ld xiz, 0xfea356
	ld_srib3 L, 0x07, 0xf8, 0xec
	dec 1, hl
	ld xiz, __jrt_nop_FE9709_Data
	or_srib_rm A, 0x07, 0xf8, 0xec

__jrt_nop_FE9709_Increment:
	inc 2, iy
	djnz xbc, __jrt_nop_FE9709_LoadReg4

__jrt_nop_FE9709_LoadReg5:
	ld l, a
	ld xiz, 0xfe9818
	ld_srib3 A, 0x07, 0xf8, 0xec
	ld8_24 l, 0x00cee6
	ld xiz, 0xfea356
	ld_srib3 W, 0x07, 0xf8, 0xec
	anddi8_24 52958, 127
	anddi8_24 52958, 239
	ret

__jrt_nop_FE9709_Data:
	.byte 0x01
	push_sr
	.byte 0x01
	push_sr
	.byte 0x01, 0x01
	push_sr
	.byte 0x01
	push_sr
	.byte 0x01
	push_sr
	.byte 0x01, 0x01
	push_sr
	halt
	.byte 0x06

Voice_ComputeNoteBitPosition:
	ld l, c
	xor h, h
	dec 1, hl
	ld xiz, 0xcee6
	ld_srib3 W, 0x07, 0xf8, 0xec
	ld c, b
	xor b, b
	dec 1, bc
	ld iy, hl
	dec 1, iy
	xor de, de

ComputeNoteBitPositi_Prologue:
	pushw bc
	ld xiz, 0xcee6
	ld_srib3 L, 0x07, 0xf8, 0xf4
	sub l, w
	ld xiz, 0xfea356
	ld_srib3 A, 0x07, 0xf8, 0xec
	dec 1, a
	ldb c, 0xb
	sub c, a
	ldfr_berp A, 0x3c
	ld a, c
	scf
	stcf_a_16 de
	ldto_berp A, 0x3c
	popw bc
	dec 1, iy
	djnz xbc, ComputeNoteBitPositi_Prologue
	or de, 0x800
	ret

ComputeNoteBitPositi_Data:
	dec	1, bc
	xor	de, de
	xor	hl, hl
	xor	iy, iy
	xor	wa, wa
	pushw	bc
	ld	xiz, 52966
	ld	l, (xiz)
	.byte 0xc3
	reti
	swi	0
	.byte 0xf4
	ldb	w, 206
	and	(xsp), xiz
	.byte 0xd6
	ld	xiz, 16687958
	.byte 0xc3
	reti
	swi	0
	.byte 0xec
	ldb	c, 203
	jr	ge, -57
	push	xix
	add	(xbc-53), bc
	scf
	.byte 0xda
	pushw	ix
	.byte 0xc7
	push	xix
	.byte 0x89
	cp	a, c
	jr	nc, 2
	ld	a, c
	popw	bc
	inc	1, iy
	djnz16	bc, -52
	or	de, 1
	ldb	c, 11
	sub	c, a
	ex8	a, c
	.byte 0xda
	swi	4
	ex8	a, c
	ret

ComputeNoteBitPositi_StoreDRAM:
	stda16 52989, xde
	ld8_24 c, 0x00cee5
	xor b, b

ComputeNoteBitPositi_Block:
	ldfr_werp DE, 0x3c
	and de, 0x600
	ldto_werp DE, 0x3c
	jr nz, ComputeNoteBitPositi_TestBit9
	ld hl, de
	and hl, 0x1ff
	ld xiz, 0xeebe44
	ld_srib3 A, 0x07, 0xf8, 0xec
	cps a, 0
	jr nz, Voice_PitchCalcStep

ComputeNoteBitPositi_TestBit9:
	bit 9, de
	jr z, Voice_DecrementCounter
	cpda8_24 c, 52965
	jr nz, Voice_DecrementCounter
	ld hl, de
	and hl, 0x1ff
	ld xiz, 0xeebe44
	ld_srib3 A, 0x07, 0xf8, 0xec
	cps a, 1
	jr nz, ComputeNoteBitPositi_Compare
	ldb a, 0x28
	jr Voice_PitchCalcStep

ComputeNoteBitPositi_Compare:
	cps a, 5
	jr nz, Voice_DecrementCounter
	ldb a, 0x29
	jr Voice_PitchCalcStep

Voice_DecrementCounter:
	dec 1, c
	cps c, 0
	jr z, PitchCalcStep_ClearByte
	jr __jrt_nop_FE9917
__jrt_nop_FE9917:

__jrt_nop_FE9917_Increment:
	inc 1, b
	sla de, 1
	bit 12, de
	jr nz, __jrt_nop_FE9917_OrBits

__jrt_nop_FE9917_TestBit11:
	bit 11, de
	jr z, __jrt_nop_FE9917_Increment
	jr ComputeNoteBitPositi_Block

__jrt_nop_FE9917_OrBits:
	or de, 0x1
	jr __jrt_nop_FE9917_TestBit11

Voice_PitchCalcStep:
	ld8_24 l, 0x00cee5
	dec 1, l
	xor h, h
	ld xiz, 0xcee6
	ld_srib3 L, 0x07, 0xf8, 0xec
	add l, b
	ld xiz, 0xfea356
	ld_srib3 W, 0x07, 0xf8, 0xec
	jr __jrt_nop_FE9955_Return

PitchCalcStep_ClearByte:
	ldb a, 0x0
	ldb w, 0x0
	jr __jrt_nop_FE9955
__jrt_nop_FE9955:

__jrt_nop_FE9955_Return:
	ret

__jrt_nop_FE9955_Block:
	sti8_24 0x00cee5, 0x04
	ld16_24 xde, 0x00ceff
	calr __jrt_nop_FE9709_Block2
	cpi8_24 0x00cee5, 0x02
	jr ugt, __jrt_nop_FE9955_Block2
	jr __jrt_nop_FE9955_Block3

__jrt_nop_FE9955_Block2:
	calr Voice_UpdateNoteBitmap
	cps w, 0
	jr nz, __jrt_nop_FE9989_Compare
	decdi8_24 1, 52965
	calr Voice_UpdateNoteBitmap
	incdi8_24 1, 52965
	jr __jrt_nop_FE9989_Compare

__jrt_nop_FE9955_Block3:
	calr __jrt_nop_FE9A0A_Block
	jr __jrt_nop_FE9989
__jrt_nop_FE9989:

__jrt_nop_FE9989_Compare:
	cps w, 0
	jr nz, __jrt_nop_FE9989_TestBit24
	ld8_24 a, 0x00cee2
	ld8_24 w, 0x00cee3
	jr __jrt_nop_FE9989_Block2

__jrt_nop_FE9989_TestBit24:
	bitda_24 6, 52958
	jr nz, __jrt_nop_FE9989_Block
	ldfr_werp DE, 0x3e
	ldda16 xde, 50582
	and de, 0x8
	ldto_werp DE, 0x3e
	jr nz, __jrt_nop_FE9989_Block4
	jr __jrt_nop_FE9989_Block3

__jrt_nop_FE9989_Block:
	ld8_24 l, 0x00cee5
	xor h, h
	dec 1, hl
	ld xiz, 0xcee6
	ld d, (xiz)
	ld_srib3 E, 0x07, 0xf8, 0xec
	sub d, e
	cp d, 0xc
	jr nc, __jrt_nop_FE9989_Block4
	jr __jrt_nop_FE9989_Block3

__jrt_nop_FE9989_Block2:
	calr NoteDisplay_ClearAndSetUpdate
	jr __jrt_nop_FE9989_Return

__jrt_nop_FE9989_Block3:
	calr NoteDisplay_InitState
	jr __jrt_nop_FE9989_Return

__jrt_nop_FE9989_Block4:
	calr NoteDisplay_LookupBitmap

__jrt_nop_FE9989_Return:
	ret

Voice_UpdateNoteBitmap:
	push xix
	push xiz
	ld8_24 c, 0x00cee5
	ld b, c
	calr Voice_ComputeNoteBitPosition
	ld xiy, 0xeebe44
	calr ComputeNoteBitPositi_StoreDRAM
	cps a, 0
	jr z, UpdateNoteBitmap_ClearByte
	ordi8_24 52958, 16
	anddi8_24 52958, 127
	jr __jrt_nop_FE9A0A_LoadReg

UpdateNoteBitmap_ClearByte:
	ldb a, 0x0
	ldb w, 0x0
	jr __jrt_nop_FE9A0A
__jrt_nop_FE9A0A:

__jrt_nop_FE9A0A_LoadReg:
	ld l, a
	extz hl
	pop xiz
	pop xix
	ret

__jrt_nop_FE9A0A_Data:
	ld8_24	c, 52965
	ld	b, c
	calr	65025
	ld	xiy, 15646276
	calr	65173
	cps	a, 0
	jr	z, 20
	.byte 0xc2
	or	iz, 15872
	rcf
	.byte 0xc2
	or	iz, 15360
	jrl	nc, -8510
	.byte 0xce
	nop
	push	xix
	swi	1
	jr	6
	ldb	a, 0
	ldb	w, 0
	jr	0
	ret

__jrt_nop_FE9A0A_Block:
	cpi8_24 0x00cee0, 0x00
	jr z, __jrt_nop_FE9A0A_SetByte
	ldb a, 0x0
	ldb w, 0x0
	jr __jrt_nop_FE9A0A_Block2

__jrt_nop_FE9A0A_SetByte:
	ldb a, 0x1
	ld8_24 l, 0x00cee6
	xor h, h
	ld xiz, 0xfea356
	ld_srib3 W, 0x07, 0xf8, 0xec

__jrt_nop_FE9A0A_Block2:
	anddi8_24 52958, 127
	ordi8_24 52958, 16
	ret

__jrt_nop_FE9A0A_Data2:
	ldb	a, 1
	ld8_24	l, 52965
	xor	h, h
	dec	1, hl
	ld	xiz, 52966
	.byte 0xc3
	reti
	swi	0
	.byte 0xec
	ldb	l, 70
	.byte 0x56
	cp	(xhl), xiz
	nop
	.byte 0xc3
	reti
	swi	0
	.byte 0xec
	ldb	w, 194
	or	iz, 15872
	rcf
	.byte 0xc2
	or	iz, 15360
	.byte 0x7f
	ret

__jrt_nop_FE9A0A_Block3:
	calr Audio_NullRet2_Prologue
	ld16_24 xwa, 0x00cf2f
	addda8_24 a, 52965
	cps a, 2
	jr ugt, __jrt_nop_FE9A0A_TestBit24
	jrl Audio_NullRet2

__jrt_nop_FE9A0A_TestBit24:
	bitda_24 1, 52958
	jr nz, __jrt_nop_FE9A0A_Block9
	calr Voice_LookupNoteAndComputePitch
	cps w, 0
	jr nz, __jrt_nop_FE9A0A_Compare
	ld8_24 l, 0x00cee5
	xor h, h
	dec 1, hl
	extz hl
	ld xiz, 0xcee6
	add xiz, xhl
	ld c, (xiz)
	ldfr_lerp XIZ, 0x30
	ldfr_berp C, 0x34
	ld8_24 a, 0x00cee5
	dec 1, a
	cps a, 2
	jr ugt, __jrt_nop_FE9A0A_Block4
	jr Audio_NullRet2

__jrt_nop_FE9A0A_Block4:
	decdi8_24 1, 52965
	calr Voice_LookupNoteAndComputePitch
	incdi8_24 1, 52965
	ldto_berp C, 0x34
	ldto_lerp XIZ, 0x30
	ld (xiz), c

__jrt_nop_FE9A0A_Compare:
	cps w, 0
	jr nz, __jrt_nop_FE9A0A_Block5
	ld8_24 a, 0x00cee2
	ld8_24 w, 0x00cee3
	jr __jrt_nop_FE9A0A_Block6

__jrt_nop_FE9A0A_Block5:
	ldfr_werp DE, 0x3e
	ldda16 xde, 50582
	and de, 0x8
	ldto_werp DE, 0x3e
	jr nz, __jrt_nop_FE9A0A_Block8
	jr __jrt_nop_FE9A0A_Block7

__jrt_nop_FE9A0A_Block6:
	calr NoteDisplay_ClearAndSetUpdate
	jr Audio_NullRet2

__jrt_nop_FE9A0A_Block7:
	calr NoteDisplay_InitState
	jr Audio_NullRet2

__jrt_nop_FE9A0A_Block8:
	calr NoteDisplay_LookupBitmap
	jr Audio_NullRet2

__jrt_nop_FE9A0A_Block9:
	calr NoteDisplay_AlternateLookup
	cps a, 0
	jr z, __jrt_nop_FE9A0A_Block10
	calr __jrt_nop_FEA013_Block
	jr Audio_NullRet2

__jrt_nop_FE9A0A_Block10:
	calr Voice_LookupNoteAndComputePitch
	cps a, 0
	jr z, __jrt_nop_FE9A0A_Block11
	calr NoteDisplay_LookupBitmap
	jr Audio_NullRet2

__jrt_nop_FE9A0A_Block11:
	calr NoteDisplay_ClearAndSetUpdate
	jr Audio_NullRet2

Audio_NullRet2:
	ret

Audio_NullRet2_Prologue:
	push xiz
	ld xiy, 0xceff
	ld16_24 xhl, 0x00ceff
	extz xhl
	dec 1, xhl
	sla xhl, 1
	ld xiz, xiy
	add xiz, xhl
	ld a, (xiz + 3)
	sub a, (xiz + 5)
	cp a, 0xc
	jr z, Audio_NullRet2_LoopCheck
	cp a, 0x8
	jr nc, Audio_NullRet2_LoopBody
	jr Voice_ProcessSlotEntry

Audio_NullRet2_LoopBody:
	ld16_24 xde, 0x00ceff
	cps de, 4
	jr c, Voice_ProcessSlotEntry
	sti16_24 0x00cf2f, 0x0001
	ld xiz, xiy
	add xiz, xhl
	ld wa, (xiz + 4)
	st16_24 0x00cf33, xwa
	ordi8_24 52958, 2
	sti8_24 0x00cee5, 0x07
	dec 1, de
	calr VoiceSlot_CheckPitchIntervals
	jrl Audio_PopIzRet

Audio_NullRet2_LoopCheck:
	ld xiz, xiy
	add xiz, xhl
	ld a, (xiz + 1)
	sub a, (xiz + 3)
	cp a, 0x8
	jr c, Audio_NullRet2_LoopBody
	ld16_24 xde, 0x00ceff
	cps de, 5
	jr c, Voice_ProcessSlotEntry
	sti16_24 0x00cf2f, 0x0001
	ld xiz, xiy
	add xiz, xhl
	ld wa, (xiz + 4)
	st16_24 0x00cf33, xwa
	ordi8_24 52958, 2
	sti8_24 0x00cee5, 0x07
	dec 1, de
	dec 1, de
	calr VoiceSlot_CheckPitchIntervals
	jr Audio_PopIzRet

Voice_ProcessSlotEntry:
	ld16_24 xde, 0x00ceff
	cps de, 3
	jr c, ProcessSlotEntry_Block2
	ldfr_werp DE, 0x3e
	ldda16 xde, 50582
	and de, 0x200
	ldto_werp DE, 0x3e
	jr z, ProcessSlotEntry_Block
	sti16_24 0x00cf2f, 0x0000
	anddi8_24 52958, 253
	sti8_24 0x00cee5, 0x07
	ld16_24 xde, 0x00ceff
	calr VoiceSlot_CheckPitchIntervals
	calr NoteBuffer_CompactEn_Block2
	jr Audio_PopIzRet

ProcessSlotEntry_Block:
	sti16_24 0x00cf2f, 0x0000
	anddi8_24 52958, 253
	sti8_24 0x00cee1, 0x00
	sti8_24 0x00cee5, 0x07
	ld16_24 xde, 0x00ceff
	calr VoiceSlot_CheckPitchIntervals
	calr NoteBuffer_CompactEn_Block2
	jr Audio_PopIzRet

ProcessSlotEntry_Block2:
	sti8_24 0x00cee5, 0x00

Audio_PopIzRet:
	pop xiz
	ret

VoiceSlot_CheckPitchIntervals:
	push xiz
	cps de, 0
	jr nz, VoiceSlot_CheckPitch_LoadReg
	sti8_24 0x00cee5, 0x00
	jrl NoteBuffer_CompactEn_Epilogue

VoiceSlot_CheckPitch_LoadReg:
	ld xiy, 0xceff
	xor xhl, xhl
	lds bc, 1
	cps de, 3
	jr ule, VoiceSlot_CheckPitch_Compare
	ld bc, de
	sub bc, 0x3

VoiceSlot_CheckPitch_LoadReg2:
	ld xiz, xiy
	add xiz, xhl
	ld a, (xiz + 5)
	sub a, (xiz + 7)
	add hl, 0x2
	cp a, 0x8
	jr ugt, VoiceSlot_CheckPitch_Compare
	djnz xbc, VoiceSlot_CheckPitch_LoadReg2
	xor hl, hl

VoiceSlot_CheckPitch_Compare:
	cps hl, 0
	jr nz, VoiceSlot_CheckPitch_Compare2
	anddi8_24 52958, 223
	jr NoteBuffer_CompactEntries

VoiceSlot_CheckPitch_Compare2:
	cps hl, 2
	jr nz, VoiceSlot_CheckPitch_Compare3
	stdi8 52917, 2
	ordi8_24 52958, 32
	jr NoteBuffer_CompactEntries

VoiceSlot_CheckPitch_Compare3:
	cps hl, 4
	jr nz, VoiceSlot_CheckPitch_OrBits2
	bitda_24 5, 52958
	jr z, VoiceSlot_CheckPitch_OrBits
	cpdi8 52917, 0
	jr z, NoteBuffer_CompactEntries

VoiceSlot_CheckPitch_OrBits:
	xor hl, hl
	anddi8_24 52958, 223
	jr NoteBuffer_CompactEntries

VoiceSlot_CheckPitch_OrBits2:
	xor hl, hl
	anddi8_24 52958, 223
	jr NoteBuffer_CompactEntries

NoteBuffer_CompactEntries:
	ld xix, 0xcf8f
	ld xiy, 0xceff
	ld wa, de
	dec 1, wa
	sla wa, 1
	add iy, wa
	srl hl, 1
	sub de, hl
	xor b, b
	xor h, h

NoteBuffer_CompactEn_LoadReg:
	ld l, (xiy + 5)
	ld (xix), l
	inc 1, ix
	inc 1, b
	cpda8_24 b, 52965
	jr nc, NoteBuffer_CompactEn_Block
	dec 1, iy
	dec 1, iy
	dec 1, de
	cps de, 0
	jr nz, NoteBuffer_CompactEn_LoadReg

NoteBuffer_CompactEn_Block:
	st8_24 0x00cee5, b
	ld c, b
	xor b, b
	ld xix, 0xcee6
	ld xiy, 0xcf8f
	add iy, bc
	dec 1, iy

NoteBuffer_CompactEn_LoadReg2:
	ld a, (xiy)
	ld (xix), a
	dec 1, iy
	inc 1, ix
	djnz xbc, NoteBuffer_CompactEn_LoadReg2

NoteBuffer_CompactEn_Epilogue:
	pop xiz
	ret

NoteBuffer_CompactEn_Data:
	ld	w, (xiy+5)
	sub	w, a
	cp	w, 12
	jr	ugt, 8
	.byte 0xc2
	or	iz, 15360
	ldx
	jr	8
	.byte 0xc2
	or	iz, 15872
	ldio	104, 0
	ret

NoteBuffer_CompactEn_Block2:
	cpi8_24 0x00cee4, 0x00
	jr z, NoteBuffer_NullRet
	cpdi16_24 53039, 0
	jr nz, NoteBuffer_NullRet
	ld16_24 xwa, 0x00cf33
	ld16_24 xbc, 0x00ceff
	ld xiy, 0xceff

NoteBuffer_CompactEn_Compare:
	cp wa, (xiy + 4)
	jr nz, NoteBuffer_CompactEn_Increment
	jr NoteBuffer_NullRet

NoteBuffer_CompactEn_Increment:
	inc 2, iy
	djnz xbc, NoteBuffer_CompactEn_Compare
	ld8_24 l, 0x00cee5
	xor h, h
	dec 1, hl
	ld xiz, 0xcee6
	ld_srib3 A, 0x07, 0xf8, 0xec
	ld8_24 w, 0x00cf34
	sub a, w
	cps a, 7
	jr c, NoteBuffer_NullRet
	sti16_24 0x00cf2f, 0x0001
	ordi8_24 52958, 2

NoteBuffer_NullRet:
	ret

Voice_LookupNoteAndComputePitch:
	ld8_24 c, 0x00cee5
	ld b, c
	pushw bc
	calr Voice_ComputeNoteBitPosition
	ld hl, de
	and xhl, 0x7ff
	sla hl, 1
	ld xiz, 0xeeae44
	add xiz, xhl
	ld a, (xiz)
	ld w, (xiz + 1)
	bit 7, w
	jr z, LookupNoteAndCompute_Block
	and w, 0x7f
	jrl NoteDisplay_FoundEntry

LookupNoteAndCompute_Block:
	cpdi16_24 53039, 0
	jr nz, NoteDisplay_SetBounds
	ld8_24 c, 0x00cee5
	ldb b, 0x3

LookupNoteAndCompute_Prologue:
	pushw bc
	calr Voice_ComputeNoteBitPosition
	ld hl, de
	and hl, 0x7ff
	sla hl, 1
	ld xiz, 0xeeae44
	add xiz, xhl
	ld a, (xiz)
	ld w, (xiz + 1)
	and w, 0x7f
	popw bc
	cps a, 0
	jr nz, NoteDisplay_LookupEntry
	cpda8_24 b, 52965
	jr nc, NoteDisplay_SetBounds
	inc 1, b
	jr LookupNoteAndCompute_Prologue

NoteDisplay_LookupEntry:
	ld8_24 l, 0x00cee5
	xor h, h
	dec 1, hl
	ld xiz, 0xcee6
	ld_srib3 L, 0x07, 0xf8, 0xec
	add l, w
	ld xiz, 0xfea356
	ld_srib3 W, 0x07, 0xf8, 0xec
	dec 1, w
	ld8_24 l, 0x00cee5
	ld xiz, 0xcee6
	lda_dri3 XWA, 0x07, 0xf8, 0xec
	incdi8_24 1, 52965

NoteDisplay_SetBounds:
	ld8_24 l, 0x00cee5
	ld h, l

NoteDisplay_ScanLoop:
	ld c, l
	ld b, h
	push xhl
	calr Voice_ComputeNoteBitPosition
	ld hl, de
	and hl, 0x7ff
	sla hl, 1
	ld xiz, 0xeeae44
	add xiz, xhl
	ld a, (xiz)
	ld w, (xiz + 1)
	and w, 0x7f
	pop xhl
	cps a, 0
	jr nz, NoteDisplay_FoundEntry
	dec 1, h
	cps h, 4
	jr c, NoteDisplay_NotFound
	jr NoteDisplay_ScanLoop

NoteDisplay_FoundEntry:
	ld8_24 l, 0x00cee5
	dec 1, l
	xor h, h
	ld xiz, 0xcee6
	ld_srib3 L, 0x07, 0xf8, 0xec
	add l, w
	ld xiz, 0xfea356
	ld_srib3 W, 0x07, 0xf8, 0xec
	jr NoteDisplay_StoreBoundsReturn

NoteDisplay_NotFound:
	ldb a, 0x0
	ldb w, 0x0
	jr NoteDisplay_StoreBoundsReturn

NoteDisplay_StoreBoundsReturn:
	popw bc
	st8_24 0x00cee5, c
	ret

NoteDisplay_AlternateLookup:
	ld8_24 l, 0x00cee5
	xor h, h
	ld8_24 a, 0x00cf34
	ld xiz, 0xcee6
	lda_dri3 XBC, 0x07, 0xf8, 0xec
	ld bc, hl
	inc 1, bc
	ld b, c
	calr Voice_ComputeNoteBitPosition
	ld hl, de
	and hl, 0x7ff
	sla hl, 1
	ld xiz, 0xeeae44
	ld_srib3 A, 0x07, 0xf8, 0xec
	cps a, 0
	jr z, Voice_ZeroInitConverge
	ld xiz, 0xeeae44
	add xiz, xhl
	ld w, (xiz + 1)
	and w, 0x7f
	bit 5, w
	jr nz, Voice_ZeroInitConverge
	cps w, 0
	jr nz, Voice_ZeroInitConverge
	ld8_24 l, 0x00cf34
	add l, w
	xor h, h
	ld xiz, 0xfea356
	ld_srib3 W, 0x07, 0xf8, 0xec
	jr NoteDisplay_AltReturn

Voice_ZeroInitConverge:
	ldb a, 0x0
	ldb w, 0x0
	jr NoteDisplay_AltReturn

NoteDisplay_AltReturn:
	ret

NoteDisplay_ClearAndSetUpdate:
	push xix
	push xiz
	cpi8_24 0x00cee1, 0x00
	jr nz, NoteDisplay_ClearReturn
	anddi8_24 52958, 249
	ordi8_24 52958, 16
	anddi8_24 52958, 254

NoteDisplay_ClearReturn:
	pop xiz
	pop xix
	ret

NoteDisplay_InitState:
	push xix
	push xiz
	st8_24 0x00cedf, a
	st8_24 0x00cee0, w
	sti8_24 0x00cee1, 0x00
	sti8_24 0x00cee4, 0x00
	anddi8_24 52958, 253
	anddi8_24 52958, 251
	anddi8_24 52958, 254
	anddi8_24 52958, 127
	ordi8_24 52958, 16
	pop xiz
	pop xix
	ret

NoteDisplay_LookupBitmap:
	push xix
	push xiz
	st8_24 0x00cedf, a
	st8_24 0x00cee0, w
	xor hl, hl
	cpdi16_24 53039, 0
	jr z, NoteDisplay_LookupFromCurrent
	ld8_24 l, 0x00cf34
	jr NoteDisplay_LookupFromTable

NoteDisplay_LookupFromCurrent:
	ld8_24 l, 0x00cee5
	dec 1, hl
	ld xiz, 0xcee6
	ld_srib3 L, 0x07, 0xf8, 0xec

NoteDisplay_LookupFromTable:
	ld xiz, 0xfea356
	ld_srib3 A, 0x07, 0xf8, 0xec
	cpdm8_24 52960, a
	jr z, NoteDisplay_SameNote
	cpdi16_24 53039, 0
	jr z, NoteDisplay_StoreNoCurrent
	st8_24 0x00cee1, a
	st8_24 0x00cee4, a
	jr NoteDisplay_SetUpdateFlags

NoteDisplay_StoreNoCurrent:
	st8_24 0x00cee1, a
	sti8_24 0x00cee4, 0x00

NoteDisplay_SetUpdateFlags:
	anddi8_24 52958, 251
	ordi8_24 52958, 2
	anddi8_24 52958, 254
	anddi8_24 52958, 127
	ordi8_24 52958, 16
	jr __jrt_nop_FEA013_Epilogue

NoteDisplay_SameNote:
	cpdi16_24 53039, 0
	jr z, NoteDisplay_ClearBoth
	sti8_24 0x00cee1, 0x00
	st8_24 0x00cee4, w
	jr NoteDisplay_SetOverlayFlags

NoteDisplay_ClearBoth:
	sti8_24 0x00cee1, 0x00
	sti8_24 0x00cee4, 0x00

NoteDisplay_SetOverlayFlags:
	ordi8_24 52958, 4
	anddi8_24 52958, 253
	anddi8_24 52958, 254
	anddi8_24 52958, 127
	ordi8_24 52958, 16
	jr __jrt_nop_FEA013
__jrt_nop_FEA013:

__jrt_nop_FEA013_Epilogue:
	pop xiz
	pop xix
	ret

__jrt_nop_FEA013_Block:
	st8_24 0x00cedf, a
	st8_24 0x00cee0, w
	sti8_24 0x00cee1, 0x00
	st8_24 0x00cee4, w
	ordi8_24 52958, 4
	anddi8_24 52958, 253
	anddi8_24 52958, 127
	ordi8_24 52958, 16
	ret

__jrt_nop_FEA013_Block2:
	calr Voice_InitPartAllocState
	calr __jrt_nop_FEA1FA_TestBit24
	ordi16_24 52993, 65280
	ld8_24 a, 0x00cedf
	st8_24 0x00cee2, a
	ld8_24 a, 0x00cee0
	st8_24 0x00cee3, a
	ret

Voice_InitPartAllocState:
	push xix
	push xiz
	cpi8_24 0x00cedf, 0x00
	jr nz, InitPartAllocState_Block
	calr InitPartAllocState_Block4
	jr InitPartAllocState_Epilogue

InitPartAllocState_Block:
	calr InitPartAllocState_TestBit242
	calr InitPartAllocState_OrBits
	ldfr_werp DE, 0x3e
	ldda16 xde, 50584
	and de, 0x2
	ldto_werp DE, 0x3e
	jr z, InitPartAllocState_TestBit24
	bitda_24 4, 52958
	jr z, InitPartAllocState_Block2
	calr __jrt_nop_FEA171_TestBit24
	jr InitPartAllocState_TestBit24

InitPartAllocState_Block2:
	calr __jrt_nop_FEA1FA_Block2

InitPartAllocState_TestBit24:
	bitda_24 4, 52958
	jr z, InitPartAllocState_Block3
	calr __jrt_nop_FEA1FA_Block3
	jr InitPartAllocState_Epilogue

InitPartAllocState_Block3:
	calr __jrt_nop_FEA1FA_LoadReg

InitPartAllocState_Epilogue:
	pop xiz
	pop xix
	ret

InitPartAllocState_Block4:
	sti8_24 0x00cee5, 0x00
	sti16_24 0x00cf5f, 0x0000
	sti16_24 0x00cf77, 0x0000
	sti8_24 0x00cef1, 0x00
	ret

InitPartAllocState_TestBit242:
	bitda_24 4, 52958
	jrl nz, InitPartAllocState_Return
	ld8_24 l, 0x00cedf
	xor h, h
	dec 1, hl
	ld xiz, 0xfea3da
	ld_srib3 A, 0x07, 0xf8, 0xec
	st8_24 0x00cee5, a
	ld xiz, 0xfea403
	sla hl, 2
	ld_sriw3 BC, 0x07, 0xf8, 0xec
	inc 2, hl
	ld_sriw3 DE, 0x07, 0xf8, 0xec
	ld8_24 l, 0x00cee0
	dec 1, l
	add c, l
	add b, l
	add e, l
	add d, l
	xor h, h
	ld l, c
	sla hl, 1
	ld xiz, 0xfea4d2
	ld_sriw3 WA, 0x07, 0xf8, 0xec
	ld l, b
	sla hl, 1
	or_sriw_rm WA, 0x07, 0xf8, 0xec
	ld l, e
	sla hl, 1
	or_sriw_rm WA, 0x07, 0xf8, 0xec
	ld l, d
	sla hl, 1
	or_sriw_rm WA, 0x07, 0xf8, 0xec
	ld xiy, 0xcee6
	ld8_24 c, 0x00cee5
	xor b, b
	add iy, bc
	dec 1, iy
	ldb e, 0x36

InitPartAllocState_Increment:
	inc 1, e
	srl wa, 1
	jr nc, InitPartAllocState_Increment
	ld (xiy), e
	dec 1, iy
	djnz xbc, InitPartAllocState_Increment

InitPartAllocState_Return:
	ret

InitPartAllocState_OrBits:
	xor hl, hl
	bitda_24 1, 52958
	jr z, InitPartAllocState_Block5
	ld8_24 l, 0x00cee1
	jr __jrt_nop_FEA171_LoadReg

InitPartAllocState_Block5:
	ld8_24 l, 0x00cee0
	jr __jrt_nop_FEA171
__jrt_nop_FEA171:

__jrt_nop_FEA171_LoadReg:
	ld xiz, __jrt_nop_FEA344_Data
	ld_srib3 W, 0x07, 0xf8, 0xec
	ldb a, 0x40
	sti16_24 0x00cf77, 0x0001
	st16_24 0x00cf7b, xwa
	ret

__jrt_nop_FEA171_TestBit24:
	bitda_24 1, 52958
	jr z, __jrt_nop_FEA1FA_Block
	ld8_24 l, 0x00cedf
	xor h, h
	dec 1, hl
	ld xiz, 0xfea3da
	ld_srib3 C, 0x07, 0xf8, 0xec
	st8_24 0x00cef1, c
	incdi8_24 1, 52977
	xor b, b
	ld xiy, 0xfea403
	ld xix, 0xcef2
	sla hl, 2
	ld8_24 d, 0x00cee1
	dec 1, d
	add d, 0x30
	ld8_24 e, 0x00cee0
	dec 1, e
	add e, 0x30
	ld a, d
	sub a, 0x18
	ld (xix), a
	inc 1, ix

__jrt_nop_FEA171_LoadFromStack:
	ld_srib3 A, 0x07, 0xf4, 0xec
	add a, e
	cp a, 0x3c
	jr c, __jrt_nop_FEA171_Compare
	sub a, 0xc

__jrt_nop_FEA171_Compare:
	cp a, d
	jr z, __jrt_nop_FEA171_Block
	ld (xix), a
	inc 1, ix
	jr __jrt_nop_FEA1FA_NextIter

__jrt_nop_FEA171_Block:
	decdi8_24 1, 52977
	jr __jrt_nop_FEA1FA
__jrt_nop_FEA1FA:

__jrt_nop_FEA1FA_NextIter:
	inc 1, hl
	djnz xbc, __jrt_nop_FEA171_LoadFromStack
	jr __jrt_nop_FEA1FA_Return

__jrt_nop_FEA1FA_Block:
	ld8_24 l, 0x00cedf
	xor h, h
	dec 1, hl
	ld xiz, 0xfea3da
	ld_srib3 C, 0x07, 0xf8, 0xec
	st8_24 0x00cef1, c
	xor b, b
	ld xiy, 0xfea403
	ld xix, 0xcef2
	sla hl, 2
	ld8_24 e, 0x00cee0
	dec 1, e
	add e, 0x30

__jrt_nop_FEA1FA_LoadFromStack:
	ld_srib3 A, 0x07, 0xf4, 0xec
	add a, e
	ld (xix), a
	inc 1, hl
	inc 1, ix
	djnz xbc, __jrt_nop_FEA1FA_LoadFromStack

__jrt_nop_FEA1FA_Return:
	ret

__jrt_nop_FEA1FA_Block2:
	ld8_24 l, 0x00cedf
	xor h, h
	dec 1, hl
	ld xiz, 0xfea3da
	ld_srib3 A, 0x07, 0xf8, 0xec
	st8_24 0x00cef1, a
	ld xiz, 0xfea403
	sla hl, 2
	ld_sriw3 BC, 0x07, 0xf8, 0xec
	inc 2, hl
	ld_sriw3 DE, 0x07, 0xf8, 0xec
	ld xiz, __jrt_nop_FEA344_Data
	ld8_24 l, 0x00cee0
	ld_srib3 L, 0x03, 0xf8, 0xec
	add l, 0xc
	add c, l
	add b, l
	add e, l
	add d, l
	st8_24 0x00cef2, c
	st8_24 0x00cef3, b
	st8_24 0x00cef4, e
	st8_24 0x00cef5, d
	ret

__jrt_nop_FEA1FA_Block3:
	ld16_24 xbc, 0x00ceff
	st16_24 0x00cf5f, xbc
	cps bc, 0
	jr z, __jrt_nop_FEA1FA_Return2
	ld xiy, 0xcf03
	ld xix, 0xcf63

__jrt_nop_FEA1FA_Block4:
	ld_spiw WA, 0xf5
	cp w, 0x6b
	jr ugt, __jrt_nop_FEA1FA_SetByte
	add w, 0xc

__jrt_nop_FEA1FA_SetByte:
	ldb a, 0x40
	st_dpiw WA, 0xf1
	djnz xbc, __jrt_nop_FEA1FA_Block4

__jrt_nop_FEA1FA_Return2:
	ret

__jrt_nop_FEA1FA_LoadReg:
	ld xiy, 0xcee6
	ld xix, 0xcf5f
	ld8_24 c, 0x00cee5
	xor b, b
	ld (xix + 256), bc

__jrt_nop_FEA1FA_LoadReg2:
	ld w, (xiy)
	ldb a, 0x40
	ld (xix + 4), wa
	inc 1, iy
	inc 1, ix
	inc 1, ix
	djnz xbc, __jrt_nop_FEA1FA_LoadReg2
	ret

__jrt_nop_FEA1FA_TestBit24:
	bitda_24 0, 52958
	jr nz, __jrt_nop_FEA1FA_Block6
	ld8_24 a, 0x00cedf
	ld8_24 w, 0x00cee0
	ld8_24 l, 0x00cee1
	cpda8 a, 36162
	jr nz, __jrt_nop_FEA1FA_StoreDRAM
	cpda8 w, 36160
	jr nz, __jrt_nop_FEA1FA_StoreDRAM
	cpda8 l, 36164
	jr z, __jrt_nop_FEA344_Return

__jrt_nop_FEA1FA_StoreDRAM:
	stda8 36162, a
	stda8 36160, w
	bitda_24 1, 52958
	jr nz, __jrt_nop_FEA1FA_StoreDRAM2
	stdi8 36164, 0
	jr __jrt_nop_FEA1FA_Block5

__jrt_nop_FEA1FA_StoreDRAM2:
	stda8 36164, l

__jrt_nop_FEA1FA_Block5:
	jr __jrt_nop_FEA344_DoCheckDis

__jrt_nop_FEA1FA_Block6:
	stdi8 36162, 0
	stdi8 36160, 0
	stdi8 36164, 0
	jr __jrt_nop_FEA344
__jrt_nop_FEA344:

__jrt_nop_FEA344_DoCheckDis:
	call BitMapOut_CheckDiskAndApply

__jrt_nop_FEA344_Return:
	ret

__jrt_nop_FEA344_Data:
	nop
	.ascii "$%&'()*+,!\"#"
	.byte 0x01
	push_sr
	pop_sr
	.byte 0x04
	halt
	ei	7
	ldio	9, 10
	pushw	268
	push_sr
	pop_sr
	.byte 0x04
	halt
	ei	7
	ldio	9, 10
	pushw	268
	push_sr
	pop_sr
	.byte 0x04
	halt
	ei	7
	ldio	9, 10
	pushw	268
	push_sr
	pop_sr
	.byte 0x04
	halt
	ei	7
	ldio	9, 10
	pushw	268
	push_sr
	pop_sr
	.byte 0x04
	halt
	ei	7
	ldio	9, 10
	pushw	268
	push_sr
	pop_sr
	.byte 0x04
	halt
	ei	7
	ldio	9, 10
	pushw	268
	push_sr
	pop_sr
	.byte 0x04
	halt
	ei	7
	ldio	9, 10
	pushw	268
	push_sr
	pop_sr
	.byte 0x04
	halt
	ei	7
	ldio	9, 10
	pushw	268
	push_sr
	pop_sr
	.byte 0x04
	halt
	ei	7
	ldio	9, 10
	pushw	268
	push_sr
	pop_sr
	.byte 0x04
	halt
	ei	7
	ldio	9, 10
	pushw	268
	push_sr
	pop_sr
	.byte 0x04
	halt
	ei	7
	ldio	9, 10
	pushw	780
	.byte 0x04, 0x04
	pop_sr
	pop_sr
	.byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
	pop_sr
	.byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
	pop_sr
	.byte 0x04, 0x04
	pop_sr
	.fill 8, 1, 0x04
	.fill 8, 1, 0x04
	.byte 0x04, 0x04
	nop
	.byte 0x04
	reti
	nop
	nop
	.byte 0x04
	reti
	ldwio	0, 1796
	pushw	1024
	ldio	0, 0
	pop_sr
	reti
	nop
	nop
	pop_sr
	reti
	ldwio	0, 1539
	push	0
	pop_sr
	.byte 0x06
	ldwio	0, 1795
	pushw	1280
	reti
	ldwio	0, 1796
	push	0
	.byte 0x04
	ldio	10, 0
	.byte 0x04
	di
	nop
	.byte 0x04, 0x06
	ldwio	4, 2567
	push_sr
	.byte 0x04
	reti
	ldwio	1, 1796
	pushw	1026
	reti
	push	2
	nop
	pop_sr
	reti
	push	0
	pop_sr
	di
	pop_sr
	reti
	ldwio	2, 2307
	push_sr
	reti
	nop
	halt
	reti
	nop
	.byte 0x04
	reti
	ldwio	3, 1024
	.byte 0x06
	pushw	1024
	ldio	11, 0
	pop_sr
	.byte 0x06
	pushw	1024
	push	10
	nop
	.byte 0x04
	ldio	10, 0
	.byte 0x04
	push	10
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 24
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x04
	reti
	push_sr
	nop
	pop_sr
	reti
	push_sr
	nop
	.byte 0x01
	push_sr
	pop_sr
	.byte 0x04
	halt
	ei	7
	ldio	9, 10
	pushw	3340
	ret
	retd	4368
	ccf
	zcf
	push_a
	pop_a
	ex_ff
	ldf	24
	pop_f
	.byte 0x1a
	jp	1973532
	.byte 0x1f
	ldb	w, 33
	.asciz "\"#$%&'()* "
	ld	xwa, 0x00008000
	.byte 0x01
	nop
	push_sr
	nop
	.byte 0x04
	nop
	ldio	1, 0
	push_sr
	nop
	.byte 0x04
	nop
	ldio	0, 16
	nop
	ldb	w, 0
	ld	xwa, 32768
	.byte 0x01
	nop
	push_sr
	nop
	.byte 0x04
	nop
	ldio	1, 0
	push_sr
	nop
	.byte 0x04
	nop
	ldio	0, 16
	nop

__jrt_nop_FEA344_LoadReg:
	ld xiy, 0xceff
	ld xix, 0xcf17
	ld bc, (xiy + 256)
	inc 1, bc
	ldirw
	ret

__jrt_nop_FEA344_Data2:
	.byte 0x01
	nop
	push_sr
	nop
	.byte 0x04
	nop
	ldio	0, 16
	nop
	ldb	w, 0
	ld	xwa, 32768
	.byte 0x01
	nop
	push_sr
	nop
	.byte 0x04
	nop
	ldio	0, 16
	nop
	ldb	w, 0
	.byte 0x40
	nop
	.byte 0x80
	.ascii "89;:<=>Â"
	or	iz, 8448
	stda8	52928, a
	ld8_24	a, 52959
	stda8	52929, a
	ld8_24	a, 52960
	stda8	52930, a
	ld8_24	a, 52961
	stda8	52931, a
	ld8_24	a, 52962
	stda8	52932, a
	ld8_24	a, 52963
	stda8	52933, a
	ld8_24	a, 52964
	stda8	52934, a
	ld	xiy, 52965
	ld	xix, 52938
	ldw	bc, 10
	.byte 0x85
	scf
	ld	xiy, 52918
	ld	xix, 52965
	ldw	bc, 10
	.byte 0x85
	scf
	.byte 0xc2, 0xe5, 0xce
	nop
	push	xsp
	push_sr
	jrl	ule, 135
	calr	62522
	cps	w, 0
	jr	nz, 29
	decdi8_24	1, 52965
	calr	62510
	incdi8_24	1, 52965
	jr	14
	cps	w, 0
	jr	nz, 10
	ld8_24	a, 52962
	ld8_24	w, 52963
	.byte 0xf2
	or	iz, 52736
	jr	nz, 18
	.byte 0xd7
	push	xiz
	.byte 0x9a
	ldda16	de, 50582
	and	de, 8
	.byte 0xd7
	push	xiz
	ld	c, (xde+110)
	jr	28
	ld8_24	l, 52965
	xor	h, h
	dec	1, hl
	ld	xiz, 52966
	ld	d, (xiz)
	.byte 0xc3
	reti
	swi	0
	.byte 0xec
	ldb	e, 205
	and	(xix), xix
	.byte 0xcf
	incf
	jr	nc, 5
	calr	63771
	jr	3
	calr	63823
	ld8_24	a, 52959
	stda8	52918, a
	ld8_24	a, 52960
	stda8	52919, a
	ld8_24	a, 52961
	stda8	52920, a
	ld8_24	a, 52958
	stda8	52921, a
	jr	10
	stdi8	52918, 0
	stdi8	52919, 0
	ldda8	a, 52928
	st8_24	52958, a
	ldda8	a, 52929
	st8_24	52959, a
	ldda8	a, 52930
	st8_24	52960, a
	ldda8	a, 52931
	st8_24	52961, a
	ldda8	a, 52932
	st8_24	52962, a
	ldda8	a, 52933
	st8_24	52963, a
	ldda8	a, 52934
	st8_24	52964, a
	ld	xiy, 52938
	ld	xix, 52965
	ldw	bc, 10
	.byte 0x85
	scf
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xhl
	pop	xbc
	pop	xwa
	ret

__jrt_nop_FEA344_Prologue:
	push xiz
	ld xiz, xsp
	push xix
	push xde
	ld xiy, (xiz + 8)
	xor xix, xix
	ld bc, (xiy + 256)
	sla bc, 1
	ld xiz, xiy
	add xiz, 0x4
	lds32 xiy, 0

__jrt_nop_FEA344_Compare:
	cp iy, bc
	jr ge, __jrt_nop_FEA344_Epilogue
	ld_sriw3 WA, 0x07, 0xf8, 0xf4
	ld ix, iy

__jrt_nop_FEA344_Increment:
	inc 2, ix
	cp ix, bc
	jr ge, __jrt_nop_FEA344_Block
	ldfr_lerp XIZ, 0x38
	extz ix
	add xiz, xix
	ex_werp IZ, 0x38
	cp_srib_mr W, 0x39, 0x01, 0x00
	jr le, __jrt_nop_FEA344_Increment
	ex_sriw WA, 0x07, 0xf8, 0xf0
	jr __jrt_nop_FEA344_Increment

__jrt_nop_FEA344_Block:
	st_dri3w WA, 0x07, 0xf8, 0xf4
	inc 2, iy
	jr __jrt_nop_FEA344_Compare

__jrt_nop_FEA344_Epilogue:
	pop xde
	pop xix
	pop xiz
	ret

NoteDisplay_StoreAndDispatch:
	lda xsp, (xsp - 20)
	push xiz
	ld xhl, xbc
	ld xiz, xwa
	ldmi16 (xsp + 10), 0xcedf
	ldmi16 (xsp + 8), 0xcee0
	ldmi16 (xsp + 6), 0xcee1
	ldmi16 (xsp + 4), 0xcede
	ld xiy, 0xcee5
	lda xix, (xsp + 12)
	lds bc, 5
	ldirw
	ldi85
	cps e, 3
	jrl z, NoteDisplay_StoreAnd_LoadReg3
	cps e, 2
	jr z, NoteDisplay_StoreAnd_LoadReg2
	cps e, 1
	jr z, NoteDisplay_StoreAnd_LoadReg
	cps e, 0
	jrl nz, MIDI_FinalizeParamBlock
	ld (xiz), 0x0
	ld (xiz + 1), 0x0
	ld (xiz + 2), 0x0
	ld (xiz + 3), 0x0
	jrl MIDI_FinalizeParamBlock

NoteDisplay_StoreAnd_LoadReg:
	ld (xiz), 0x0
	ld (xiz + 1), 0x0
	ld (xiz + 2), 0x0
	ld (xiz + 3), 0x0
	jrl MIDI_FinalizeParamBlock

NoteDisplay_StoreAnd_LoadReg2:
	ld xiy, xhl
	ld xix, 0xcee5
	lds bc, 5
	ldirw
	ldi85
	cpdi8 52965, 0
	jr nz, NoteDisplay_StoreAnd_LoadDRAM
	call NoteDisplay_ClearAndSetUpdate
	stdi8 52959, 0
	stdi8 52960, 0
	stdi8 52961, 0
	jr NoteDisplay_StoreAnd_Block

NoteDisplay_StoreAnd_LoadDRAM:
	ldda8 a, 52965
	dec 1, a
	extz wa
	ldada xbc, 52966
	extz xwa
	add xwa, xbc
	ldda8 c, 52966
	sub c, (xwa)
	ld a, c
	cp a, 0xc
	jr ule, NoteDisplay_StoreAnd_DoUpdateNo
	call Voice_UpdateNoteBitmap
	cps hl, 0
	jr nz, NoteDisplay_StoreAnd_DoLookupBi
	decdi8 1, 52965
	call Voice_UpdateNoteBitmap
	incdi8 1, 52965

NoteDisplay_StoreAnd_DoLookupBi:
	call NoteDisplay_LookupBitmap
	jr NoteDisplay_StoreAnd_Block

NoteDisplay_StoreAnd_DoUpdateNo:
	call Voice_UpdateNoteBitmap
	call NoteDisplay_InitState

NoteDisplay_StoreAnd_Block:
	ldmi16 (xiz), 0xcedf
	ldmi16 (xiz + 1), 0xcee0
	ldmi16 (xiz + 2), 0xcee1
	ldmi16 (xiz + 3), 0xcede
	jr MIDI_FinalizeParamBlock

NoteDisplay_StoreAnd_LoadReg3:
	ld (xiz), 0x0
	ld (xiz + 1), 0x0
	ld (xiz + 2), 0x0
	ld (xiz + 3), 0x0

MIDI_FinalizeParamBlock:
	mrdb5 0x8f, 0x0a, 0x19, 0xdf, 0xce
	mrdb5 0x8f, 0x08, 0x19, 0xe0, 0xce
	mrdb5 0x8f, 0x06, 0x19, 0xe1, 0xce
	mrdb5 0x8f, 0x04, 0x19, 0xde, 0xce
	lda xiy, (xsp + 12)
	ld xix, 0xcee5
	lds bc, 5
	ldirw
	ldi85
	pop xiz
	lda xsp, (xsp + 20)
	ret

SndParam_Init:
	dec 6, xsp
	ld (xsp + 256), 0x5
	ld (xsp + 1), 0xc0
	ld (xsp + 2), 0x19
	ld (xsp + 3), 0x0
	ld (xsp + 4), 0x40
	ld (xsp + 5), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	inc 6, xsp
	ret

; ============================================================================
; UIState_ProcessKeyEvent - Process a key press/release event in UI state
; ============================================================================
; Input:  Key event data
; Output: None
; Dispatches keyboard and control panel button events within the UI state
; machine to the appropriate page handler.
; ============================================================================
UIState_ProcessKeyEvent:
	dec	4, xsp
	.byte 0xbf
	nop
	push_a
	.byte 0x80, 0xc0, 0xbf, 0x01
	push_a
	jrl	pl, -16448
	push_sr
	push_a
	jrl	nz, -16448
	pop_sr
	push_a
	.byte 0x7f, 0xc0
	ld	a, (xsp+1)
	extz	wa
	cps	wa, 0
	jrl	mi, 483
	cp	wa, 12
	jrl	gt, 476
	add	wa, wa
	lda_24	xix, 15646788
	ld_rrw	wa, xix, wa
	lda_24	xix, 16689231
	jp_rr	8, xix, wa
	ld	a, (xsp+3)
	and	a, 255
	jrl	z, 445
	.byte 0x8f
	nop
	.byte 0x21
	extz	wa
	calr	5821
	cps	l, 0
	jrl	nz, 432
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	and	a, 255
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	2059
	jrl	410
	ld	a, (xsp+3)
	.byte 0xc9
SndParam_ProcessEntry:
	ldw	wa, 51463
	scc16	z, wa
	add	(xsp+1), l
	nop
	ldb	a, 216
	ccf
	calr	5775
	cps	l, 0
	jrl	nz, 386
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	2013
	jrl	364
	ld	a, (xsp+3)
	and	a, 255
	jrl	z, 355
	lda	xwa, (xsp)
	ldw	bc, 127
	calr	1993
	jrl	344
	ld	a, (xsp+3)
	and	a, 7
	jr	z, 19
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	and	a, 7
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	1963
	.byte 0xbf
	pop_sr
	inc	6, c
	zcf
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	and	a, 8
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	1939
	.byte 0xbf
	pop_sr
	scc8	z, h
	.byte 0x1f, 0x01, 0x8f
	nop
	ldb	a, 216
	ccf
	calr	5663
	cps	l, 0
	jrl	nz, 274
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	and	a, 64
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	1901
	jrl	252
	ld	a, (xsp+3)
	res	7, a
	cps	a, 0
	jrl	z, 241
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	1868
	jrl	219
	ld	a, (xsp+3)
	res	7, a
	cps	a, 0
	jrl	z, 208
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	1835
	jrl	186
	ld	a, (xsp+3)
	res	7, a
	cps	a, 0
	jrl	z, 175
	.byte 0x8f
	nop
	ldb	a, 216
	ccf
	calr	5551
	cps	l, 0
	jrl	nz, 162
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	1789
	jrl	140
	ld	a, (xsp+3)
	res	7, a
	cps	a, 0
	jrl	z, 129
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	1756
	jr	108
	ld	a, (xsp+3)
	and	a, 255
	jr	z, 100
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	and	a, 255
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	1727
	jr	79
	ld	a, (xsp+3)
	res	7, a
	cps	a, 0
	jr	z, 69
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	1696
	jr	48
	.byte 0xbf
	pop_sr
	inc	6, c
	zcf
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	and	a, 8
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	1670
	.byte 0xbf
	pop_sr
	inc	6, e
	zcf
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	and	a, 32
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	1646
	inc	4, xsp
	ret
HdaeRom_Entry:
	dec	4, xsp
	.byte 0xbf
	nop
	push_a
	.byte 0x80, 0xc0, 0xbf, 0x01
	push_a
	jrl	pl, -16448
	push_sr
	push_a
	jrl	nz, -16448
	pop_sr
	push_a
	jrl	nc, -28736
	.byte 0x01
	ldb	a, 201
	dec	6, bc
	popw	wa
	.byte 0xbf
	pop_sr
	inc	6, l
	zcf
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	and	a, 128
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	1590
	.byte 0xbf
	pop_sr
	inc	6, h
	zcf
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	and	a, 64
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	1566
	.byte 0xbf
	pop_sr
	inc	6, e
	zcf
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	and	a, 32
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	1542
	inc	4, xsp
	ret
HdaeRom_ProcessBlock:
	dec	4, xsp
	.byte 0xbf
	nop
	push_a
	.byte 0x80, 0xc0, 0xbf, 0x01
	push_a
	jrl	pl, -16448
	push_sr
	push_a
	jrl	nz, -16448
	pop_sr
	push_a
	jrl	nc, -28736
	.byte 0x01
	ldb	a, 201
	.byte 0xcf
	push_f
	jr	ugt, 35
	cps	a, 0
	jr	c, 31
	ld	a, (xsp+3)
	and	a, 255
	jr	z, 23
	ld	(xsp+1), 0
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	and	a, 255
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	1474
	inc	4, xsp
	ret
HdaeRom_ReadParam:
	ret
	dec	4, xsp
	.byte 0xbf
	nop
	push_a
	.byte 0x80, 0xc0, 0xbf, 0x01
	push_a
	jrl	pl, -16448
	push_sr
	push_a
	jrl	nz, -16448
	pop_sr
	push_a
	jrl	nc, -28736
	.byte 0x01
	ldb	a, 201
	.byte 0xcf
	push_f
	jr	ugt, 35
	cps	a, 0
	jr	c, 31
	ld	a, (xsp+3)
	and	a, 255
	jr	z, 23
	ld	(xsp+1), 0
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	and	a, 255
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	1405
	inc	4, xsp
	ret
HdaeRom_WriteParam:
	dec	4, xsp
	.byte 0xbf
	nop
	push_a
	.byte 0x80, 0xc0, 0xbf, 0x01
	push_a
	jrl	pl, -16448
	push_sr
	push_a
	jrl	nz, -16448
	pop_sr
	push_a
	jrl	nc, -28736
	.byte 0x01
	ldb	a, 201
	.byte 0xcf
	push_f
	jr	ugt, 35
	cps	a, 0
	jr	c, 31
	ld	a, (xsp+3)
	and	a, 255
	jr	z, 23
	ld	(xsp+1), 0
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	and	a, 255
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	1337
	inc	4, xsp
	ret
HdaeRom_CheckResult:
	dec	4, xsp
	.byte 0xbf
	nop
	push_a
	.byte 0x80, 0xc0, 0xbf, 0x01
	push_a
	jrl	pl, -16448
	push_sr
	push_a
	jrl	nz, -16448
	pop_sr
	push_a
	jrl	nc, -28736
	.byte 0x01
	ldb	a, 201
	.byte 0xcf
	push_f
	jr	ugt, 35
	cps	a, 0
	jr	c, 31
	ld	a, (xsp+3)
	and	a, 255
	jr	z, 23
	ld	(xsp+1), 0
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	and	a, 255
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	1269
	inc	4, xsp
	ret
HdaeRom_FinishBlock:
	dec	4, xsp
	.byte 0xbf
	nop
	push_a
	.byte 0x80, 0xc0, 0xbf, 0x01
	push_a
	jrl	pl, -16448
	push_sr
	push_a
	jrl	nz, -16448
	pop_sr
	push_a
	jrl	nc, -28736
	.byte 0x01
	ldb	a, 201
	.byte 0xcf
	push_f
	jr	ugt, 35
	cps	a, 0
	jr	c, 31
	ld	a, (xsp+3)
	and	a, 255
	jr	z, 23
	ld	(xsp+1), 0
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	and	a, 255
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	1201
	inc	4, xsp
	ret
HdaeRom_TableEntry0:
	ret
	ret
HdaeRom_TableEntry1:
	ret
	ret
HdaeRom_TableEntry2:
	dec	4, xsp
	.byte 0xbf
	nop
	push_a
	.byte 0x80, 0xc0, 0xbf, 0x01
	push_a
	jrl	pl, -16448
	push_sr
	push_a
	jrl	nz, -16448
	pop_sr
	push_a
	jrl	nc, -28736
	.byte 0x01
	ldb	a, 216
	ccf
	cps	wa, 0
	jrl	mi, 133
	cps	wa, 7
	jrl	gt, 128
	add	wa, wa
	lda_24	xix, 15646814
	.byte 0xd3
	reti
	.byte 0xf0, 0xe0
	ldb	w, 242
	push_a
	.byte 0xac
	swi	6
	ldw	ix, 2035
	.byte 0xf0, 0xe0, 0xd8
	ld	a, (xsp+3)
	and	a, 255
	jr	z, 98
	lda	xbc, (xsp+2)
	ldb	a, 0
	.byte 0xbf
	push_sr
	dec	6, l
	.byte 0x06
	ld	a, (xsp+2)
	res	7, a
	ld	(xbc), a
	ld	a, (xsp+2)
	extz	wa
	ld	de, wa
	ldw	wa, 23
	lds	bc, 7
	calr	3802
	ld	a, (xsp+2)
	extz	wa
	ld	de, wa
	ldw	wa, 24
	lds	bc, 7
	calr	3787
	jr	48
	ld	a, (xsp+3)
	res	7, a
	cps	a, 0
	jr	z, 38
	ld	a, (xsp+2)
	res	7, a
	extz	wa
	ld	de, wa
	ldw	wa, 23
	ldw	bc, 91
	calr	3756
	ld	a, (xsp+2)
	res	7, a
	extz	wa
	ld	de, wa
	ldw	wa, 24
	ldw	bc, 91
	calr	3737
	inc	4, xsp
	ret
	ret
HdaeRom_AltEntry:
	ret
UIStateEvt_ProcessHandler:
	dec	4, xsp
	.byte 0xbf
	nop
	push_a
	.byte 0x80, 0xc0, 0xbf, 0x01
	push_a
	jrl	pl, -16448
	push_sr
	push_a
	jrl	nz, -16448
	pop_sr
	push_a
	jrl	nc, -28736
	.byte 0x01
	ldb	a, 201
	inc	6, hl
	ld	xiz, 1516690121
	cps	a, 1
	jr	z, 33
	cps	a, 0
	jr	nz, 82
	ld	a, (xsp+3)
	and	a, 255
	jr	z, 74
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	and	a, 255
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	956
	jr	53
	ld	a, (xsp+3)
	and	a, 255
	jr	z, 45
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	and	a, 255
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	927
	jr	24
	.byte 0xbf
	pop_sr
	inc	6, w
	zcf
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	and	a, 1
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	901
	inc	4, xsp
	ret
HdaeRom_AltProcessBlock:
	dec	4, xsp
	.byte 0xbf
	nop
	push_a
	.byte 0x80, 0xc0, 0xbf, 0x01
	push_a
	jrl	pl, -16448
	push_sr
	push_a
	jrl	nz, -16448
	pop_sr
	push_a
	jrl	nc, -28736
	.byte 0x01
	ldb	a, 201
	.byte 0xcf
	decf
	jr	ugt, 63
	cps	a, 2
	jr	nc, 51
	cps	a, 0
	jr	z, 6
	cps	a, 1
	jr	z, 12
	jr	49
	lda	xwa, (xsp)
	ldw	bc, 255
	calr	846
	jr	39
	ld	a, (xsp+3)
	and	a, 15
	jr	z, 8
	lda	xwa, (xsp)
	ldw	bc, 15
	calr	828
	.byte 0xbf
	pop_sr
	inc	6, l
	ccf
	lda	xwa, (xsp)
	ldw	bc, 128
	calr	815
	jr	8
	lda	xwa, (xsp)
	ldw	bc, 255
	calr	805
	inc	4, xsp
	ret
	ret
HdaeRom_AltReadParam:
	dec	4, xsp
	.byte 0xbf
	nop
	push_a
	.byte 0x80, 0xc0, 0xbf, 0x01
	push_a
	jrl	pl, -16448
	push_sr
	push_a
	jrl	nz, -16448
	pop_sr
	push_a
	jrl	nc, -28736
	.byte 0x01
	ldb	a, 201
	inc	6, ix
	ld	xiy, 1097259977
	cps	a, 2
	jr	z, 34
	cps	a, 1
	jr	z, 57
	cps	a, 0
	jr	nz, 53
	.byte 0xbf
	pop_sr
	inc	6, b
	ldw	wa, 12471
	ld	xde, xwa
	ld	a, (xsp+3)
	and	a, 4
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	732
	jr	27
	ld	a, (xsp+3)
	and	a, 255
	jr	z, 19
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	and	a, 255
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	703
	inc	4, xsp
	ret
HdaeRom_AltCheckResult:
	dec	4, xsp
	.byte 0xbf
	nop
	push_a
	.byte 0x80, 0xc0, 0xbf, 0x01
	push_a
	jrl	pl, -16448
	push_sr
	push_a
	jrl	nz, -16448
	pop_sr
	push_a
	.byte 0x7f, 0xc0
	ld	a, (xsp+1)
	cps	a, 4
	jr	z, 40
	cps	a, 3
	jr	z, 77
	cps	a, 2
	jr	z, 6
	cps	a, 1
	.ascii "fEhC"
	.byte 0xbf
	pop_sr
	inc	6, l
	push	xiz
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	and	a, 128
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	633
	jr	41
	ld	a, (xsp+3)
	and	a, 255
	jr	z, 33
	lda	xbc, (xsp+2)
	ldb	a, 0
	.byte 0xbf
	push_sr
	dec	6, l
	.byte 0x06
	ld	a, (xsp+2)
	res	7, a
	ld	(xbc), a
	ld	a, (xsp+2)
	extz	wa
	ld	de, wa
	ldw	wa, 25
	lds	bc, 7
	calr	3298
	inc	4, xsp
	ret
	dec	4, xsp
	.byte 0xbf
	nop
	push_a
	.byte 0x80, 0xc0, 0xbf, 0x01
	push_a
	jrl	pl, -16448
	push_sr
	push_a
	jrl	nz, -16448
	pop_sr
	push_a
	jrl	nc, -28736
	.byte 0x01
	ldb	a, 201
	exts	l
	jr	ugt, 69
	cps	a, 4
	jr	c, 65
	ld	a, (xsp+1)
	dec	4, a
	extz	wa
	ldada	xbc, 61856
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	extz	wa
	lda_24	xbc, 15634082
	.byte 0xc3
	reti
	.byte 0xe4, 0xe0
	ldb	e, 205
	xor	(xbc-55), a
	jr	z, 8
	cps	a, 2
	jr	z, 4
	cps	a, 0
	jr	nz, 22
	extz	de
	ld	a, (xsp+3)
	.byte 0x8f
	push_sr
	xordm8	35785, a
	ccf
	ld	wa, de
	ld	de, bc
	ldw	bc, 145
	calr	3196
	inc	4, xsp
	ret
HdaeRom_AltTableEntry0:
	dec	4, xsp
	.byte 0xbf
	nop
	push_a
	.byte 0x80, 0xc0, 0xbf, 0x01
	push_a
	jrl	pl, -16448
	push_sr
	push_a
	jrl	nz, -16448
	pop_sr
	push_a
	jrl	nc, -18496
	ldw	wa, 35560
	ld	a, (xsp+3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	444
	inc	4, xsp
	ret
HdaeRom_AltTableEntry1:
	dec	4, xsp
	.byte 0xbf
	nop
	push_a
	.byte 0x80, 0xc0, 0xbf, 0x01
	push_a
	jrl	pl, -16448
	push_sr
	push_a
	jrl	nz, -16448
	pop_sr
	push_a
	jrl	nc, -28736
	.byte 0x01
	ldb	a, 201
	inc	6, hl
	pushw	ix
	cps	a, 1
	jr	z, 22
	cps	a, 0
	jr	nz, 52
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	388
	jr	34
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	370
	jr	16
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	352
	inc	4, xsp
	ret
HdaeRom_AltTableEntry2:
	dec	4, xsp
	.byte 0xbf
	nop
	push_a
	.byte 0x80, 0xc0, 0xbf, 0x01
	push_a
	jrl	pl, -16448
	push_sr
	push_a
	jrl	nz, -16448
	pop_sr
	push_a
	jrl	nc, -18496
	ldw	wa, 35560
	ld	a, (xsp+3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	308
	inc	4, xsp
	ret
HdaeRom_AltTableEntry3:
	dec	4, xsp
	.byte 0xbf
	nop
	push_a
	.byte 0x80, 0xc0, 0xbf, 0x01
	push_a
	jrl	pl, -16448
	push_sr
	push_a
	jrl	nz, -16448
	pop_sr
	push_a
	jrl	nc, -18496
	ldw	wa, 35560
	ld	a, (xsp+3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	264
	inc	4, xsp
	ret
HdaeRom_AltTableEntry4:
	dec	4, xsp
	.byte 0xbf
	nop
	push_a
	.byte 0x80, 0xc0, 0xbf, 0x01
	push_a
	jrl	pl, -16448
	push_sr
	push_a
	jrl	nz, -16448
	pop_sr
	push_a
	jrl	nc, -28736
	.byte 0x01
	push	xsp
	rcf
	jr	c, 6
	.byte 0x8f, 0x01
	push	xsp
	push_a
	jr	ule, 19
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	208
	inc	4, xsp
	ret
HdaeRom_AltTableEntry5:
	dec	4, xsp
	.byte 0xbf
	nop
	push_a
	.byte 0x80, 0xc0, 0xbf, 0x01
	push_a
	jrl	pl, -16448
	push_sr
	push_a
	jrl	nz, -16448
	pop_sr
	push_a
	jrl	nc, -18496
	ldw	wa, 35560
	ld	a, (xsp+3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	164
	inc	4, xsp
	ret
HdaeRom_AltTableEntry6:
	dec	4, xsp
	.byte 0xbf
	nop
	push_a
	.byte 0x80, 0xc0, 0xbf, 0x01
	push_a
	jrl	pl, -16448
	push_sr
	push_a
	jrl	nz, -16448
	pop_sr
	push_a
	jrl	nc, -18496
	ldw	wa, 35560
	ld	a, (xsp+3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	120
	inc	4, xsp
	ret
HdaeRom_AltTableEntry7:
	ret
HdaeRom_AltTableEntry8:
	ret
HdaeRom_AltTableEntry9:
	dec	4, xsp
	.byte 0xbf
	nop
	push_a
	.byte 0x80, 0xc0, 0xbf, 0x01
	push_a
	jrl	pl, -16448
	push_sr
	push_a
	jrl	nz, -16448
	pop_sr
	push_a
	jrl	nc, -28736
	.byte 0x01
	ldb	a, 201
	inc	6, bc
	calr	55497
	jr	nz, 79
	.byte 0xbf
	pop_sr
	inc	6, l
	popw	de
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	and	a, 128
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	58
	jr	53
	ld	a, (xsp+3)
	res	7, a
	cps	a, 0
	jr	z, 19
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	27
	.byte 0xbf
	pop_sr
	inc	6, l
	zcf
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+3)
	and	a, 128
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	3
	inc	4, xsp
	ret
	lda	xsp, (xsp-12)
	push	xiz
	ld	xiz, xwa
	ld	a, (xiz+3)
	ld	(xsp+4), a
	ld	(xiz+3), c
	lda	xwa, (xsp+12)
	ld	xbc, xwa
	lda	xwa, (xsp+10)
	ld	xde, xwa
	ld	xwa, xiz
	call	SndParam_ResolveWidget
	cp	hl, 65535
	jr	z, 50
	lda	xwa, (xsp+12)
	ld	xhl, xwa
	lda	xwa, (xsp+8)
	ld	xbc, xwa
	lda	xwa, (xsp+6)
	ld	xde, xwa
	ld	xwa, xhl
	call	SndParam_DecodeMidiAddr
	cp	hl, 65535
	jr	z, 14
	ld	wa, (xsp+8)
	ld	bc, (xsp+6)
	ld	de, (xsp+10)
	calr	22
	jr	9
	ld	xwa, (xsp+12)
	ld	bc, (xsp+10)
	calr	489
	ld	a, (xsp+4)
	ld	(xiz+3), a
	pop	xiz
	lda	xsp, (xsp+12)
	ret

; ============================================================================
; SndPart_SetParam - Set a sound part parameter by code
; ============================================================================
; Input:  WA = part number, DE = new value, BC = parameter code
; Output: None
; Dispatches on ~20 parameter codes to update part tables or send via MIDI.
; ============================================================================
SndPart_SetParam:
	dec 2, xsp
	pushw iz
	ld iz, de
	ld (xsp + 2), wa
	cp bc, 0x78
	jrl z, SndPart_SetAllSoundOff
	cp bc, 0x1b2
	jrl z, SndPart_SetPitchBendSens
	cp bc, 0x603
	jrl z, SndPart_SetCoarseTune
	cp bc, 0x602
	jrl z, SndPart_SetFineTune
	cp bc, 0x1b0
	jrl z, SndPart_SetRPN
	cp bc, 0x82
	jrl z, SndPart_SetBankSelect
	cp bc, 0x81
	jrl z, SndPart_SetBankLSB
	cp bc, 0x80
	jrl z, SndPart_SetBankMSB
	cp bc, 0x5e
	jrl z, SndPart_SetDelaySend
	cp bc, 0x5d
	jrl z, SndPart_SetChorusSend
	cp bc, 0x5b
	jrl z, SndPart_SetReverbSend
	cp bc, 0x600
	jrl z, SndPart_SetPitchBendRange
	cp bc, 0x40
	jrl z, SndPart_SetDamperPedal
	cp bc, 0xb
	jr z, SndPart_SetExpression
	cp bc, 0xa
	jr z, SndPart_SetPan
	cps bc, 7
	jr z, SndPart_SetVolume
	cps bc, 1
	jr z, SndPart_SetModWheel
	cp bc, 0x20
	jr z, SndPart_SetProgramMSB
	cps bc, 0
	jrl nz, MIDI_SendEpilogue
	ld wa, (xsp + 2)
	add wa, wa
	ldada xbc, 53200
	extz xwa
	add xwa, xbc
	ld (xwa), iz
	jrl MIDI_SendEpilogue

SndPart_SetProgramMSB:
	ld wa, (xsp + 2)
	add wa, wa
	ldada xbc, 53264
	extz xwa
	add xwa, xbc
	ld (xwa), iz
	jrl MIDI_SendEpilogue

SndPart_SetModWheel:
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	lds bc, 1
	calr MIDI_SendControlChange
	jrl MIDI_SendEpilogue

SndPart_SetVolume:
	ld wa, (xsp + 2)
	ldw bc, 0x8
	call SndParam_LookupViaEncode
	cps hl, 1
	jr nz, SndPart_SetVolume_LoadReg
	lds iz, 0

SndPart_SetVolume_LoadReg:
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	lds bc, 7
	calr MIDI_SendControlChange
	jrl MIDI_SendEpilogue

SndPart_SetPan:
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	ldw bc, 0xa
	calr MIDI_SendControlChange
	jrl MIDI_SendEpilogue

SndPart_SetExpression:
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	ldw bc, 0xb
	calr MIDI_SendControlChange
	jrl MIDI_SendEpilogue

SndPart_SetDamperPedal:
	ldw wa, 0x7f
	cps iz, 0
	jr nz, SndPart_SetDamperPed_LoadReg
	lds wa, 0

SndPart_SetDamperPed_LoadReg:
	ld iz, wa
	ldto_berp A, 0xf8
	ld c, a
	extz bc
	ld wa, (xsp + 2)
	ld de, bc
	ldw bc, 0x40
	calr MIDI_SendControlChange
	jrl MIDI_SendEpilogue

SndPart_SetPitchBendRange:
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	ldw bc, 0x97
	calr MIDI_SendControlChange
	jrl MIDI_SendEpilogue

SndPart_SetReverbSend:
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	ldw bc, 0x5b
	calr MIDI_SendControlChange
	jrl MIDI_SendEpilogue

SndPart_SetChorusSend:
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	ldw bc, 0x5d
	calr MIDI_SendControlChange
	jrl MIDI_SendEpilogue

SndPart_SetDelaySend:
	ld wa, (xsp + 2)
	add wa, wa
	ldada xbc, 53328
	extz xwa
	add xwa, xbc
	ld (xwa), iz
	jrl MIDI_SendEpilogue

SndPart_SetBankMSB:
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	ldw bc, 0x80
	calr MIDI_SendControlChange
	jr MIDI_SendEpilogue

SndPart_SetBankLSB:
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	ldw bc, 0x81
	calr MIDI_SendControlChange
	jr MIDI_SendEpilogue

SndPart_SetBankSelect:
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	ldw bc, 0x82
	calr MIDI_SendControlChange
	jr MIDI_SendEpilogue

SndPart_SetRPN:
	ld bc, iz
	ld wa, (xsp + 2)
	calr MIDI_SendPitchBend
	jr MIDI_SendEpilogue

SndPart_SetFineTune:
	ldw wa, 0x7f
	cps iz, 0
	jr nz, SndPart_SetFineTune_LoadReg
	lds wa, 0

SndPart_SetFineTune_LoadReg:
	ld iz, wa
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	ldw bc, 0x9c
	calr MIDI_SendControlChange
	jr MIDI_SendEpilogue

SndPart_SetCoarseTune:
	ldw wa, 0x7f
	cps iz, 0
	jr nz, SndPart_SetCoarseTun_LoadReg
	lds wa, 0

SndPart_SetCoarseTun_LoadReg:
	ld iz, wa
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	ldw bc, 0x95
	calr MIDI_SendControlChange
	jr MIDI_SendEpilogue

SndPart_SetPitchBendSens:
	ld bc, iz
	ld wa, (xsp + 2)
	calr MIDI_SendChannelPressure
	jr MIDI_SendEpilogue

SndPart_SetAllSoundOff:
	ld wa, (xsp + 2)
	ldw bc, 0x78
	lds de, 0
	calr MIDI_SendControlChange

MIDI_SendEpilogue:
	call MIDI_PostSendStub
	popw iz
	inc 2, xsp
	ret

SendEpilogue_Data:
	dec	4, xsp
	push	xiz
	ld	iz, bc
	ld	xbc, xwa
	srl	xbc, 8
	ld	hl, bc
	ld	xbc, xwa
	and	xbc, 255
	ld	de, bc
	ld	bc, hl
	cp	bc, 78
	jrl	z, 1604
	cp	bc, 77
	jrl	z, 1591
	cp	bc, 76
	jrl	z, 1578
	cp	bc, 75
	jrl	z, 1565
	cp	bc, 73
	jrl	z, 1552
	cp	bc, 66
	jrl	z, 449
	cp	bc, 65
	jrl	z, 345
	cp	bc, 64
	jrl	z, 201
	cps	bc, 0
	jrl	nz, 1554
	ld	wa, de
	cp	wa, 193
	jrl	z, 157
	cp	wa, 192
	jr	z, 122
	cps	wa, 3
	jr	z, 28
	cps	wa, 0
	jrl	nz, 1530
	add	iz, 64
	.byte 0xc7
	swi	0
	.byte 0x89
	extz	wa
	ld	de, wa
	ldw	wa, 80
	ldw	bc, 130
	calr	2290
	jrl	1507
	dec	5, iz
	.byte 0xc7
	swi	0
	.byte 0x89
	extz	wa
	ld	de, wa
	ldw	wa, 80
	ldw	bc, 131
	calr	2269
	.byte 0xc7
	swi	0
	.byte 0x89, 0xc1
	andda8_24	l, 7795177
	halt
	ldda16	wa, 50582
	and	wa, 128
	cp	wa, 128
	jr	nz, 18
	ldda16	wa, 50582
	bit	8, wa
	jr	nz, 9
	ldw	wa, 255
	lds	bc, 2
	call	MidiEvent_ConfigChannel
	ldw	wa, 255
	ldw	bc, 21
	call	MidiEvent_ConfigChannel
	ldw	wa, 255
	ldw	bc, 22
	call	MidiEvent_ConfigChannel
	.byte 0xc7
	swi	0
	.byte 0x89
	stda8	59842, a
	jrl	1417
	lds	wa, 1
	cps	iz, 0
	jr	nz, 2
	lds	wa, 2
	ld	iz, wa
	.byte 0xc7
	swi	0
	.byte 0x89
	extz	wa
	ld	de, wa
	ldw	wa, 127
	ldw	bc, 9
	calr	2171
	jrl	1388
	ldw	wa, 127
	cps	iz, 0
	jr	nz, 2
	lds	wa, 0
	ld	iz, wa
	.byte 0xc7
	swi	0
	.byte 0x89
	extz	wa
	ld	de, wa
	ldw	wa, 80
	ldw	bc, 153
	calr	2141
	jrl	1358
	ld	wa, de
	cp	wa, 130
	jrl	z, 1349
	cp	wa, 129
	jrl	z, 1342
	cp	wa, 128
	jr	z, 96
	cps	wa, 6
	jrl	ugt, 1331
	add	wa, wa
	lda_24	xix, 15646860
	.byte 0xd3
	reti
	.byte 0xf0, 0xe0
	ldb	w, 242
	decf
	.byte 0xb4
	swi	6
	ldw	ix, 2035
	.byte 0xf0, 0xe0, 0xd8, 0xc7
	swi	0
	.byte 0x89
	extz	wa
	call	SendPartDataBlock_Block
	jrl	1297
	.byte 0xc7
	swi	0
	.byte 0x89
	extz	wa
	call	SendPartDataBlock_Block2
	jrl	1285
	stda16	53194, iz
	jrl	1278
	stda16	53192, iz
	jrl	1271
	stda16	53196, iz
	jrl	1264
	.byte 0xc7
	swi	0
	.byte 0x89
	extz	wa
	call	SendPartDataBlock_Block3
	jrl	1252
	.byte 0xc7
	swi	0
	.byte 0x89
	extz	wa
	call	SendPartDataBlock_Block9
	jrl	1240
	.byte 0xc7
	swi	0
	.byte 0x89
	extz	wa
	ld	de, wa
	ldw	wa, 80
	ldw	bc, 133
	calr	2004
	jrl	1221
	ld	wa, de
	cp	wa, 66
	jr	z, 47
	cp	wa, 65
	jr	z, 14
	cp	wa, 64
	jrl	nz, 1200
	stda16	53198, iz
	jrl	1193
	ld	xwa, 16706
	call	SndParam_LookupReadOnly
	cps	hl, 1
	jr	nz, 2
	lds	iz, 0
	.byte 0xc7
	swi	0
	.byte 0x89
	extz	wa
	call	SendPartDataBlock_Block4
	jrl	1166
	ld	xwa, 16706
	call	SndParam_LookupReadOnly
	cps	hl, 1
	jr	nz, 9
	lds	wa, 0
	call	SendPartDataBlock_Block4
	jrl	1144
	ld	xwa, 16705
	call	SndParam_LookupReadOnly
	ld	a, l
	extz	wa
	call	SendPartDataBlock_Block4
	jrl	1124
	ld	wa, de
	sub	wa, 128
	cps	wa, 0
	jrl	c, 1113
	cp	wa, 14
	jrl	ugt, 1106
	add	wa, wa
	lda_24	xix, 15646830
	.byte 0xd3
	reti
	.byte 0xf0, 0xe0
	ldb	w, 242
	sbc	xix, xiz
	swi	6
	ldw	ix, 2035
	.byte 0xf0, 0xe0, 0xd8
	ldw	wa, 127
	cps	iz, 0
	jr	nz, 2
	lds	wa, 0
	ld	iz, wa
	.byte 0xc7
	swi	0
	.byte 0x89
	extz	wa
	ld	de, wa
	ldw	wa, 80
	ldw	bc, 177
	calr	1837
	jrl	1054
	.byte 0xc7
	swi	0
	.byte 0x89
	extz	wa
	calr	2042
	.byte 0xd7
	swi	2
	cp	(xhl-41), de
	.byte 0x8a
	ldb	d, 0
	ldw	wa, 80
	ldw	bc, 134
	calr	1809
	.byte 0xd7
	swi	2
	and	(xwa-40), d
	nop
	swi	7
	jrl	nz, 1019
	.byte 0xc7
	swi	0
	.byte 0x89
	extz	wa
	calr	1823
	ld	(xsp+4), xhl
	lds	iz, 0
	cp	iz, 12
	jrl	ge, 999
	ldda8	a, 64797
	and	a, 15
	ld	c, a
	extz	bc
	add	bc, iz
	ld	wa, bc
	cp	wa, 12
	jr	lt, 4
	sub	bc, 12
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ld	xwa, (xsp+4)
	.byte 0xc3
	reti
	.byte 0xe0
	swi	0
	ldb	a, 216
	ccf
	ld	de, wa
	ldw	wa, 80
	calr	1728
	inc	1, iz
	cp	iz, 12
	jr	lt, -59
	jrl	937
	ld	xwa, 17025
	call	SndParam_LookupReadOnly
	ld	a, l
	extz	wa
	calr	1917
	.byte 0xd7
	swi	2
	cp	(xhl-41), de
	and	(xwa-40), d
	nop
	swi	7
	jrl	nz, 908
	ld	xwa, 17025
	call	SndParam_LookupReadOnly
	ld	a, l
	extz	wa
	calr	1704
	ld	(xsp+4), xhl
	lds	iz, 0
	cp	iz, 12
	jrl	ge, 880
	ldda8	a, 64797
	and	a, 15
	ld	c, a
	extz	bc
	add	bc, iz
	ld	wa, bc
	cp	wa, 12
	jr	lt, 4
	sub	bc, 12
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ld	xwa, (xsp+4)
	.byte 0xc3
	reti
	.byte 0xe0
	swi	0
	ldb	a, 216
	ccf
	ld	de, wa
	ldw	wa, 80
	calr	1609
	inc	1, iz
	cp	iz, 12
	jr	lt, -59
	jrl	818
	ld	xwa, 17025
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jrl	nz, 802
	ldda8	a, 64797
	and	a, 15
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, 4
	sub	bc, 12
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ldda8	a, 64798
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	1537
	jrl	754
	ld	xwa, 17025
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jrl	nz, 738
	ldda8	a, 64797
	and	a, 15
	inc	1, a
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, 4
	sub	bc, 12
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ldda8	a, 64799
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	1471
	jrl	688
	ld	xwa, 17025
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jrl	nz, 672
	ldda8	a, 64797
	and	a, 15
	inc	2, a
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, 4
	sub	bc, 12
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ldda8	a, 64800
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	1405
	jrl	622
	ld	xwa, 17025
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jrl	nz, 606
	ldda8	a, 64797
	and	a, 15
	inc	3, a
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, 4
	sub	bc, 12
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ldda8	a, 64801
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	1339
	jrl	556
	ld	xwa, 17025
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jrl	nz, 540
	ldda8	a, 64797
	and	a, 15
	inc	4, a
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, 4
	sub	bc, 12
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ldda8	a, 64802
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	1273
	jrl	490
	ld	xwa, 17025
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jrl	nz, 474
	ldda8	a, 64797
	and	a, 15
	inc	5, a
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, 4
	sub	bc, 12
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ldda8	a, 64803
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	1207
	jrl	424
	ld	xwa, 17025
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jrl	nz, 408
	ldda8	a, 64797
	and	a, 15
	inc	6, a
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, 4
	sub	bc, 12
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ldda8	a, 64804
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	1141
	jrl	358
	ld	xwa, 17025
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jrl	nz, 342
	ldda8	a, 64797
	and	a, 15
	inc	7, a
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, 4
	sub	bc, 12
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ldda8	a, 64805
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	1075
	jrl	292
	ld	xwa, 17025
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jrl	nz, 276
	ldda8	a, 64797
	and	a, 15
	inc	8, a
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, 4
	sub	bc, 12
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ldda8	a, 64806
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	1009
	jrl	226
	ld	xwa, 17025
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jrl	nz, 210
	ldda8	a, 64797
	and	a, 15
	add	a, 9
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, 4
	sub	bc, 12
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ldda8	a, 64807
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	942
	jrl	159
	ld	xwa, 17025
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jrl	nz, 143
	ldda8	a, 64797
	and	a, 15
	add	a, 10
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, 4
	sub	bc, 12
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ldda8	a, 64808
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	875
	jr	93
	ld	xwa, 17025
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jr	nz, 78
	ldda8	a, 64797
	and	a, 15
	add	a, 11
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, 4
	sub	bc, 12
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ldda8	a, 64809
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	810
	jr	28
	stda32	53172, xwa
	jr	22
	stda32	53176, xwa
	jr	16
	stda32	53180, xwa
	jr	10
	stda32	53184, xwa
	jr	4
	stda32	53188, xwa
	call	MIDI_PostSendStub
	pop	xiz
	inc	4, xsp
	ret

Song_SendPartDataBlocks:
	pushw iz
	ldda32 xwa, 53172
	cp xwa, 0xffffffff
	jr z, SendPartDataBlocks_LoadDRAM
	lds wa, 0
	call COMM_SendPartDataBlock

SendPartDataBlocks_LoadDRAM:
	ldda32 xwa, 53176
	cp xwa, 0xffffffff
	jr z, SendPartDataBlocks_LoadDRAM2
	lds wa, 1
	call COMM_SendPartDataBlock

SendPartDataBlocks_LoadDRAM2:
	ldda32 xwa, 53180
	cp xwa, 0xffffffff
	jr z, SendPartDataBlocks_LoadDRAM3
	lds wa, 4
	call COMM_SendPartDataBlock

SendPartDataBlocks_LoadDRAM3:
	ldda32 xwa, 53184
	cp xwa, 0xffffffff
	jr z, SendPartDataBlocks_LoadDRAM4
	lds wa, 2
	call COMM_SendPartDataBlock

SendPartDataBlocks_LoadDRAM4:
	ldda32 xwa, 53188
	cp xwa, 0xffffffff
	jr z, SendPartDataBlocks_Block
	lds wa, 3
	call COMM_SendPartDataBlock

SendPartDataBlocks_Block:
	cpdi16 53192, 65535
	jr z, SendPartDataBlocks_Block2
	ldda16 xwa, 53192
	extz wa
	call SendPartDataBlock_Block7

SendPartDataBlocks_Block2:
	cpdi16 53194, 65535
	jr z, SendPartDataBlocks_Block3
	ldda16 xwa, 53194
	extz wa
	call SendPartDataBlock_ClearByte

SendPartDataBlocks_Block3:
	cpdi16 53196, 65535
	jr z, SendPartDataBlocks_Block4
	ldda16 xwa, 53196
	extz wa
	call SendPartDataBlock_ClearByte2

SendPartDataBlocks_Block4:
	cpdi16 53198, 65535
	jr z, SendPartDataBlocks_InitVal
	ldda16 xwa, 53198
	extz wa
	call SendPartDataBlock_ClearByte3

SendPartDataBlocks_InitVal:
	lds iz, 0
	cp iz, 0x18
	jrl gt, SendPartDataBlocks_Send

SendPartDataBlocks_LoadIter:
	ld wa, iz
	add wa, wa
	ldada xbc, 53200
	extz xwa
	add xwa, xbc
	cpw (xwa), 0xffff
	jr z, SendPartDataBlocks_LoadIter3
	ld wa, iz
	add wa, wa
	ldada xbc, 53264
	extz xwa
	add xwa, xbc
	cpw (xwa), 0xffff
	jr z, SendPartDataBlocks_LoadIter3
	ld wa, iz
	add wa, wa
	ldada xbc, 53328
	extz xwa
	add xwa, xbc
	cpw (xwa), 0xffff
	jr nz, SendPartDataBlocks_LoadIter2
	ld wa, iz
	ldw bc, 0x5e
	call SndParam_LookupViaEncode
	jr SendPartDataBlocks_LoadReg

SendPartDataBlocks_LoadIter2:
	ld wa, iz
	add wa, wa
	ldada xbc, 53328
	extz xwa
	add xwa, xbc
	ld hl, (xwa)

SendPartDataBlocks_LoadReg:
	ld ix, iz
	ld wa, iz
	add wa, wa
	ldada xbc, 53200
	extz xwa
	add xwa, xbc
	ld iy, (xwa)
	ld wa, iz
	add wa, wa
	ldada xbc, 53264
	extz xwa
	add xwa, xbc
	ld de, (xwa)
	pushw hl
	ld wa, ix
	ld bc, iy
	calr SendChannelPressure_Prologue
	jr SendPartDataBlocks_NextIter

SendPartDataBlocks_LoadIter3:
	ld wa, iz
	add wa, wa
	ldada xbc, 53328
	extz xwa
	add xwa, xbc
	cpw (xwa), 0xffff
	jr z, SendPartDataBlocks_NextIter
	ld hl, iz
	ld wa, iz
	add wa, wa
	ldada xbc, 53328
	extz xwa
	add xwa, xbc
	ld de, (xwa)
	ld wa, hl
	ldw bc, 0x5e
	calr MIDI_SendControlChange

SendPartDataBlocks_NextIter:
	inc 1, iz
	cp iz, 0x18
	jrl le, SendPartDataBlocks_LoadIter

SendPartDataBlocks_Send:
	call MIDI_PostSendStub
	calr COMM_SendDataReturn
	popw iz
	ret

COMM_SendDataReturn:
	ld xwa, 0xffffffff
	stda32 53172, xwa
	ld xwa, 0xffffffff
	stda32 53176, xwa
	ld xwa, 0xffffffff
	stda32 53180, xwa
	ld xwa, 0xffffffff
	stda32 53184, xwa
	ld xwa, 0xffffffff
	stda32 53188, xwa
	stdi16 53192, 65535
	stdi16 53194, 65535
	stdi16 53196, 65535
	stdi16 53198, 65535
	lds de, 0
	cp de, 0x18
	ret gt

SendDataReturn_LoadReg:
	ld wa, de
	add wa, wa
	ldada xbc, 53200
	extz xwa
	add xwa, xbc
	ldw (xwa), 0xffff
	ld wa, de
	add wa, wa
	ldada xbc, 53264
	extz xwa
	add xwa, xbc
	ldw (xwa), 0xffff
	ld wa, de
	add wa, wa
	ldada xbc, 53328
	extz xwa
	add xwa, xbc
	ldw (xwa), 0xffff
	inc 1, de
	cp de, 0x18
	jr le, SendDataReturn_LoadReg
	ret

; ============================================================================
; MIDI_SendControlChange - Send a MIDI Control Change message
; ============================================================================
; Input:  A = MIDI channel, C = controller number, E = value
; Output: None (sends via SubCPU comm)
; Builds [4, 0xb0, chan, ctrl, val] packet, transmits via MIDI_SendCmdPacket.
; ============================================================================
MIDI_SendControlChange:
	dec 6, xsp
	ld (xsp + 256), 0x4
	ld (xsp + 1), 0xb0
	ld (xsp + 2), a
	ld (xsp + 3), c
	ld (xsp + 4), e
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	inc 6, xsp
	ret

MIDI_SendPitchBend:
	dec 6, xsp
	ld (xsp + 256), 0x4
	ld (xsp + 1), 0xe0
	ld (xsp + 2), a
	ld a, c
	res 7, a
	ld (xsp + 3), a
	and bc, 0x3fff
	srl bc, 7
	ld a, c
	ld (xsp + 4), a
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	inc 6, xsp
	ret

MIDI_SendChannelPressure:
	dec 6, xsp
	ld (xsp + 256), 0x4
	ld (xsp + 1), 0xd0
	ld (xsp + 2), a
	ld (xsp + 3), 0x0
	ld (xsp + 4), c
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	inc 6, xsp
	ret

SendChannelPressure_Prologue:
	lda xsp, (xsp - 12)
	pushw iz
	ld (xsp + 12), wa
	ld iz, (xsp + 18)
	cp iz, 0xffff
	jr nz, SendChannelPressure_InitVal
	lds iz, 0
	jr SendChannelPressure_LoadParam

SendChannelPressure_InitVal:
	lds wa, 0
	cps iz, 0
	jr z, SendChannelPressure_LoadReg
	ldw wa, 0x7f

SendChannelPressure_LoadReg:
	ld iz, wa

SendChannelPressure_LoadParam:
	ld (xsp + 10), c
	ld (xsp + 8), e
	lda xwa, (xsp + 10)
	ld xde, xwa
	lda xwa, (xsp + 8)
	ld xbc, xwa
	ld xwa, xde
	call SndParam_ApplyMaskClamp
	ld (xsp + 2), 0x5
	ld (xsp + 3), 0xc0
	ld wa, (xsp + 12)
	ld (xsp + 4), a
	ld a, (xsp + 10)
	ld (xsp + 5), a
	ld a, (xsp + 8)
	ld (xsp + 6), a
	ldto_berp A, 0xf8
	ld (xsp + 7), a
	lda xwa, (xsp + 2)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	cpw (xsp + 12), 0x2
	jr nz, SeqVoice_CheckAndRetry
	ldda16 xwa, 50582
	and wa, 0x80
	cp wa, 0x80
	jr nz, SeqVoice_CheckAndRetry
	ldda16 xwa, 50582
	bit 8, wa
	jr nz, SeqVoice_CheckAndRetry
	ldw wa, 0xff
	lds bc, 2
	call MidiEvent_ConfigChannel

SeqVoice_CheckAndRetry:
	cpw (xsp + 12), 0x15
	jr nz, SeqVoice_CheckAndRet_Compare
	ldw wa, 0xff
	ldw bc, 0x15
	call MidiEvent_ConfigChannel

SeqVoice_CheckAndRet_Compare:
	cpw (xsp + 12), 0x16
	jr nz, SeqVoice_CheckAndRet_RestoreReg
	ldw wa, 0xff
	ldw bc, 0x16
	call MidiEvent_ConfigChannel

SeqVoice_CheckAndRet_RestoreReg:
	popw iz
	lda xsp, (xsp + 12)
	retd 0x2

SeqVoice_CheckAndRet_Prologue:
	dec 6, xsp
	ld (xsp + 256), 0x4
	ld (xsp + 1), 0xf0
	ld (xsp + 2), a
	ld (xsp + 3), c
	ld (xsp + 4), e
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	inc 6, xsp
	ret

SeqVoice_CheckAndRet_Data:
	cp	a, 128
	jrl	z, 166
	cps	a, 5
	jr	z, 106
	cps	a, 4
	jr	z, 95
	cps	a, 3
	jr	z, 84
	cp	a, 66
	jr	z, 72
	cp	a, 65
	jr	z, 60
	cp	a, 64
	jr	z, 48
	cps	a, 0
	jr	z, 37
	extz	wa
	sub	wa, 16
	cps	wa, 0
	jrl	lt, 130
	cps	wa, 6
	jr	gt, 126
	add	wa, wa
	lda_24	xix, 15647066
	ld_rrw	wa, xix, wa
	lda_24	xix, 16694432
	jp_rr	8, xix, wa
	lda_24	xhl, 15646874
	jr	102
	lda_24	xhl, 15646886
	jr	95
	lda_24	xhl, 15646898
	jr	88
	lda_24	xhl, 15646910
	jr	81
	lda_24	xhl, 15646946
	jr	74
	lda_24	xhl, 15646958
	jr	67
	lda_24	xhl, 15646970
	jr	60
	lda_24	xhl, 15646982
	jr	53
	lda_24	xhl, 15646994
	jr	46
	lda_24	xhl, 15647006
	jr	39
	lda_24	xhl, 15647018
	jr	32
	lda_24	xhl, 15647030
	jr	25
	lda_24	xhl, 15647042
	jr	18
	lda_24	xhl, 15647054
	jr	11
	ldada	xhl, 64798
	jr	5
	lda_24	xhl, 15646874
	ret
	cp	a, 128
	jrl	z, 133
	cps	a, 5
	jr	z, 90
	cps	a, 4
	jr	z, 82
	cps	a, 3
	jr	z, 74
	cp	a, 66
	jr	z, 64
	cp	a, 65
	jr	z, 54
	cp	a, 64
	jr	z, 44
	cps	a, 0
	jr	z, 36
	extz	wa
	sub	wa, 16
	cps	wa, 0
	jr	lt, 97
	cps	wa, 6
	jr	gt, 93
	add	wa, wa
	lda_24	xix, 15647080
	ld_rrw	wa, xix, wa
	lda_24	xix, 16694615
	jp_rr	8, xix, wa
	lds	hl, 0
	.ascii "hE3@ÿh@3Aÿh;3Bÿh6Û«h2Û¬h.Û­h*"
	ldw	hl, 16
	jr	37
	ldw	hl, 17
	jr	32
	ldw	hl, 18
	jr	27
	ldw	hl, 19
	jr	22
	ldw	hl, 20
	jr	17
	ldw	hl, 21
	jr	12
	ldw	hl, 22
	jr	7
	ldw	hl, 128
	jr	2
	lds	hl, 0
	ret

MIDI_SendSysExCmd:
	dec 6, xsp
	ld (xsp + 256), 0x4
	ld (xsp + 1), 0xf0
	ld (xsp + 2), 0x50
	ld (xsp + 3), 0x87
	ld (xsp + 4), a
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	inc 6, xsp
	ret

SendSysExCmd_Data:
	ldw	wa, 80
	ldw	bc, 133
	lds	de, 0
	calr	-408
	jp	MIDI_PostSendStub

COMM_WriteAndCheck:
	dec 4, xsp
	ld (xsp + 2), a
	ldb a, 0x1
	cp (xsp + 2), 0x0
	jr nz, WriteAndCheck_LoadParam
	ldb a, 0x2

WriteAndCheck_LoadParam:
	ld (xsp + 2), a
	extz wa
	ld de, wa
	ldw wa, 0x7f
	ldw bc, 0x9
	calr SeqVoice_CheckAndRet_Prologue
	ldw (xsp), 0x0
	cpw (xsp), 0x16
	jr gt, MIDI_SendPartVol_ExtraParts

MIDI_SendPartVolumes_Loop:
	ld wa, (xsp)
	ldw bc, 0x8
	call SndParam_LookupViaEncode
	cps hl, 1
	jr nz, MIDI_SendPartVol_LookupFallback
	ld (xsp + 2), 0x0
	jr MIDI_SendPartVol_StoreAndSend

MIDI_SendPartVol_LookupFallback:
	ld wa, (xsp)
	lds bc, 7
	call SndParam_LookupViaEncode
	ld (xsp + 2), l

MIDI_SendPartVol_StoreAndSend:
	ld de, (xsp)
	ld a, (xsp + 2)
	ld c, a
	extz bc
	ld wa, de
	ld de, bc
	lds bc, 7
	calr MIDI_SendControlChange
	incm 1, (xsp)
	cpw (xsp), 0x16
	jr le, MIDI_SendPartVolumes_Loop

MIDI_SendPartVol_ExtraParts:
	ld xwa, 0x2880b
	call SndParam_LookupReadOnly
	cps hl, 1
	jr nz, MIDI_SendPartVol_ExtraLookup
	ld (xsp + 2), 0x0
	jr MIDI_SendPartVol_ExtraSend

MIDI_SendPartVol_ExtraLookup:
	ld xwa, 0x28801
	call SndParam_LookupReadOnly
	ld (xsp + 2), l

MIDI_SendPartVol_ExtraSend:
	ld a, (xsp + 2)
	extz wa
	ld de, wa
	ldw wa, 0x17
	lds bc, 7
	calr MIDI_SendControlChange
	ld a, (xsp + 2)
	extz wa
	ld de, wa
	ldw wa, 0x18
	lds bc, 7
	calr MIDI_SendControlChange
	call MIDI_PostSendStub
	inc 4, xsp
	ret

MIDI_BroadcastPitchReset:
	push xiz
	ldw iz, 0x40
	lds wa, 0
	cp iz, 0x40
	jr c, PitchReset_ShiftAndOr
	ld wa, iz
	add wa, wa
	sub wa, 0x80

PitchReset_ShiftAndOr:
	sll iz, 7
	or iz, wa
	ldi_werp 0xfa, 0
	cp_erpw 0xfa, 0x0f, 0x00
	jr ge, PitchReset_CheckExtChannels

PitchReset_ChannelLoop:
	ldto_werp WA, 0xfa
	ld bc, iz
	calr MIDI_SendPitchBend
	ldto_werp WA, 0xfa
	lds bc, 1
	lds de, 0
	calr MIDI_SendControlChange
	inc1_werp 0xfa
	cp_erpw 0xfa, 0x0f, 0x00
	jr lt, PitchReset_ChannelLoop

PitchReset_CheckExtChannels:
	ldda8 a, 14235
	and a, 0xf
	jr z, PitchReset_Flush
	ldi_erpw 0xfa, 0x10, 0x00
	cp_erpw 0xfa, 0x13, 0x00
	jr ge, PitchReset_Flush

PitchReset_ExtChannelLoop:
	ldto_werp WA, 0xfa
	ld bc, iz
	calr MIDI_SendPitchBend
	ldto_werp WA, 0xfa
	lds bc, 1
	lds de, 0
	calr MIDI_SendControlChange
	inc1_werp 0xfa
	cp_erpw 0xfa, 0x13, 0x00
	jr lt, PitchReset_ExtChannelLoop

PitchReset_Flush:
	call MIDI_PostSendStub
	pop xiz
	ret

MIDI_PitchBendData_Block:
	ldw	wa, 80
	ldw	bc, 146
	lds	de, 0
	calr	-706
	jp	MIDI_PostSendStub

MIDI_SendAllSoundOff:
	pushw iz
	lds iz, 0
	cp iz, 0x18
	jr gt, SendAllSoundOff_Flush

SendAllSoundOff_Loop:
	ld wa, iz
	ldw bc, 0x78
	lds de, 0
	calr MIDI_SendControlChange
	inc 1, iz
	cp iz, 0x18
	jr le, SendAllSoundOff_Loop

SendAllSoundOff_Flush:
	call MIDI_PostSendStub
	popw iz
	ret

MIDI_WriteChannelData_Block:
	ldb	l, 0
	extz	wa
	sub	wa, 16
	cps	wa, 0
	ret	lt
	cp	wa, 8
	ret	gt
	add	wa, wa
	lda_24	xix, 15647094
	.byte 0xd3
	reti
	.byte 0xf0, 0xe0
	ldb	w, 242
	ld	xiy, 4080336575
	reti
	.byte 0xf0, 0xe0, 0xd8
	ldb	l, 1
	ret

; ============================================================================
; MIDI_SendCmdPacket - Send a pre-built MIDI command packet
; ============================================================================
; Input:  XWA = pointer to command buffer (first byte = count)
; Output: None
; Iterates channel table at 53392, transmits via sendCOMM (XDE=0xd090).
; Low-level MIDI/audio command packet sender.
; ============================================================================
MIDI_SendCmdPacket:
	lds hl, 0
	jr SendCmdPacket_CheckCount

SendCmdPacket_Loop:
	ldada xde, 53392
	ld bc, hl
	inc 1, bc
	ld_srib3 C, 0x07, 0xe0, 0xe4
	lda_dri3 XHL, 0x07, 0xe8, 0xec
	inc 1, hl

SendCmdPacket_CheckCount:
	ld c, (xwa)
	extz bc
	cp hl, bc
	jr lt, SendCmdPacket_Loop
	ld a, (xwa)
	extz wa
	ld xde, 0xd090
	ld bc, wa
	lds wa, 0
	jp sendCOMM

MIDI_PostSendStub:
	ret

; ============================================================================
; SeqState_GetFlags - Get the current sequencer state flags
; ============================================================================
; Input:  None
; Output: XHL = sequencer state flags (from address 59877)
; Simple accessor that reads the 32-bit sequencer state word. Used by the
; sequencer engine to check playback state, loop mode, and recording status.
; ============================================================================
SeqState_GetFlags:
	ldda16 xhl, 59877
	ret

MIDI_OutputFlush:
	pushw iz
	calr OutputFlush_Prologue
	ld iz, hl
	ld wa, iz
	cp wa, 0xfffe
	jr z, OutputFlush_DoVoiceSta
	cp wa, 0xffff
	jr z, OutputFlush_DoVoiceSta
	cp wa, 0xfffd
	jr nz, OutputFlush_RestoreReg
	lds iz, 0
	calr Song_AbortPlayback
	ld wa, iz
	call SongMode_VoiceStateDisp
	jr OutputFlush_RestoreReg

OutputFlush_DoVoiceSta:
	calr Song_AbortPlayback
	ld wa, iz
	call SongMode_VoiceStateDisp

OutputFlush_RestoreReg:
	popw iz
	ret

OutputFlush_Prologue:
	push xiz
	cpdi8 59844, 0
	jr nz, OutputFlush_LoadDRAM
	lds hl, 0
	jrl Acc_PopIzRet

OutputFlush_LoadDRAM:
	ldda16 xwa, 59877
	and wa, 0x2
	cps wa, 2
	jr nz, OutputFlush_InitVal
	ldda16 xwa, 59877
	bit 2, wa
	jr nz, OutputFlush_InitVal
	lds hl, 0
	jr Acc_PopIzRet

OutputFlush_InitVal:
	lds wa, 1
	calr AccWrap_PlayModeStateMachine
	ldda16 xwa, 59877
	ldda16 xbc, 59887
	calr PlayModeStateMachine_Prologue
	ld xiz, xhl
	cpdi8 59876, 4
	jr nz, AccSong_ProcessRecord_Loop
	ld xwa, xiz
	calr MidiRealtime_Process_Prologue

AccSong_ProcessRecord_Loop:
	cpdm32 59879, xiz
	jr ugt, AccSong_ProcessRecord_InitVal
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, AccSong_ProcessRecord_LoadDRAM
	ldw hl, 0xffff
	jr Acc_PopIzRet

AccSong_ProcessRecord_LoadDRAM:
	ldda8 a, 59876
	cps a, 4
	jr z, AccSong_ProcessRecord_LoadReg2
	cps a, 3
	jr z, AccSong_ProcessRecord_LoadReg
	cps a, 2
	jr z, AccSong_ProcessRecord_LoadReg
	cps a, 1
	jr nz, AccSong_ProcessRecord_Loop
	ld a, l
	extz wa
	calr ConfigureBanks_LoadReg
	ld wa, hl
	cps wa, 0
	jr ge, AccSong_ProcessRecord_Loop
	jr Acc_PopIzRet

AccSong_ProcessRecord_LoadReg:
	ld a, l
	extz wa
	calr MidiSysMsg_Handler
	ld wa, hl
	cps wa, 0
	jr ge, AccSong_ProcessRecord_Loop
	jr Acc_PopIzRet

AccSong_ProcessRecord_LoadReg2:
	ld a, l
	extz wa
	calr MidiRealtime_ReadAndProcess
	ld wa, hl
	cps wa, 0
	jr ge, AccSong_ProcessRecord_Loop
	jr Acc_PopIzRet

AccSong_ProcessRecord_InitVal:
	lds hl, 0

Acc_PopIzRet:
	pop xiz
	ret

Acc_LoadAndStartPlayback:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld (xsp + 6), a
	calr PlayModeStateMachine_Block5
	calr StoreAndReturn_Block
	ld a, (xsp + 6)
	stda8 59876, a
	call Audio_ConfigureDSP
	ld xwa, (xsp + 2)
	calr NotifyChangeComplete_Prologue
	ld iz, hl
	ld wa, iz
	cps wa, 0
	jr ge, LoadAndStartPlayback_LoadParam
	calr Song_AbortPlayback
	ld hl, iz
	jr SeqVoice_PopIzReturn

LoadAndStartPlayback_LoadParam:
	ld a, (xsp + 6)
	calr SeqVoice_PopIzReturn_Prologue
	ld iz, hl
	ld wa, iz
	cps wa, 0
	jr ge, LoadAndStartPlayback_LoadParam2
	calr Song_AbortPlayback
	ld hl, iz
	jr SeqVoice_PopIzReturn

LoadAndStartPlayback_LoadParam2:
	ld a, (xsp + 6)
	calr SeqVoice_PopIzReturn_Compare
	ld iz, hl
	ld wa, iz
	cps wa, 0
	jr ge, LoadAndStartPlayback_LoadParam3
	calr Song_AbortPlayback
	ld hl, iz
	jr SeqVoice_PopIzReturn

LoadAndStartPlayback_LoadParam3:
	ld xwa, (xsp + 2)
	push xwa
	ldada xwa, 59844
	push xwa
	call Strcpy
	inc 8, xsp
	lds wa, 6
	calr AccWrap_PlayModeStateMachine
	ordi16 59877, 1
	lds hl, 0

SeqVoice_PopIzReturn:
	popw iz
	inc 6, xsp
	ret

SeqVoice_PopIzReturn_Compare:
	cps a, 4
	jr z, SeqVoice_PopIzReturn_Block2
	cps a, 2
	jr z, SeqVoice_PopIzReturn_Block
	cps a, 1
	ret nz
	calr SendSinglePacket_WriteReg
	jr SeqVoice_PopIzReturn_Return

SeqVoice_PopIzReturn_Block:
	calr SeqPlay_ReadFileRecord
	jr SeqVoice_PopIzReturn_Return

SeqVoice_PopIzReturn_Block2:
	calr ToneGen_ReadFileRecord

SeqVoice_PopIzReturn_Return:
	ret

SeqVoice_PopIzReturn_Prologue:
	pushw iz
	cps a, 4
	jr z, SeqVoice_PopIzReturn_Block5
	cps a, 2
	jr z, SeqVoice_PopIzReturn_Block4
	cps a, 3
	jr z, SeqVoice_PopIzReturn_Block3
	cps a, 1
	jr nz, SwbtWr_ReinitOutputBank_Wrapper
	calr SeqInit_ResetAndSetupChannels
	ld iz, hl
	jr SwbtWr_ReinitOutputBank_Wrapper

SeqVoice_PopIzReturn_Block3:
	calr Epilogue_Prologue
	ld iz, hl
	jr SwbtWr_ReinitOutputBank_Wrapper

SeqVoice_PopIzReturn_Block4:
	calr Epilogue_Prologue2
	ld iz, hl
	jr SwbtWr_ReinitOutputBank_Wrapper

SeqVoice_PopIzReturn_Block5:
	calr ToneGen_ResetAndInitBanks
	ld iz, hl

SwbtWr_ReinitOutputBank_Wrapper:
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld hl, iz
	popw iz
	ret

; ============================================================================
; Song_AbortPlayback - Abort song playback and clean up resources
; ============================================================================
; Input:  None
; Output: None
; Sends MIDI All Notes Off to all 16 channels, releases playback lock,
; closes file I/O, flushes task queues, resets state to zero.
; ============================================================================
Song_AbortPlayback:
	calr MIDI_ResetAllChannels
	lds wa, 2
	calr AccWrap_PlayModeStateMachine
	calr DirectReturn_LoadDRAM
	jrl StoreAndReturn_Block

FileIO_ReadChunk:
	lda xsp, (xsp - 14)
	pushw iz
	ld (xsp + 14), wa
	ldw (xsp + 2), 0x1
	ld wa, (xsp + 14)
	stda16 59891, xwa
	lds iz, 0
	cp iz, 0x10
	jr ge, ReadChunk_RestoreReg

ReadChunk_LoadParam:
	ld wa, (xsp + 14)
	and wa, (xsp + 2)
	jr z, ReadChunk_LoadParam2
	ldto_berp A, 0xf8
	or a, 0xb0
	ld (xsp + 4), a
	ld (xsp + 5), 0x7b
	ld (xsp + 6), 0x0
	ei 6
	lda xwa, (xsp + 4)
	push xwa
	pushw 0x3
	call SeqMain_WriteBytes
	ei 0
	ldto_berp A, 0xf8
	or a, 0xb0
	ld (xsp + 10), a
	ld (xsp + 11), 0x0
	ld (xsp + 12), 0x40
	ei 6
	lda xwa, (xsp + 10)
	push xwa
	pushw 0x3
	call SeqMain_WriteBytes
	ei 0
	ldto_berp A, 0xf8
	or a, 0xb0
	ld (xsp + 16), a
	ld (xsp + 17), 0x40
	ld (xsp + 18), 0x0
	ei 6
	lda xwa, (xsp + 16)
	push xwa
	pushw 0x3
	call SeqMain_WriteBytes
	lda xsp, (xsp + 18)
	ei 0

ReadChunk_LoadParam2:
	ld wa, (xsp + 2)
	add (xsp + 2), wa
	inc 1, iz
	cp iz, 0x10
	jr lt, ReadChunk_LoadParam

ReadChunk_RestoreReg:
	popw iz
	lda xsp, (xsp + 14)
	ret

Acc_TransitionPlayMode:
	ldda16 xwa, 59877
	bit 0, wa
	jr z, TransitionPlayMode_Block
	lds wa, 4
	calr AccWrap_PlayModeStateMachine
	calr MIDI_ResetAllChannels
	ordi16 59877, 2

TransitionPlayMode_Block:
	anddi16 59877, 65531
	ret

Acc_StopPlayMode:
	lds wa, 3
	calr AccWrap_PlayModeStateMachine
	anddi16 59877, 65533
	anddi16 59877, 65531
	ret

Acc_StartFillIn:
	ldda16 xwa, 59877
	bit 2, wa
	ret nz
	ordi16 59877, 4
	lds wa, 4
	calr AccWrap_PlayModeStateMachine
	ret

StartFillIn_Data:
	.byte 0xd1, 0xe5, 0xe9
	push	xix
	swi	3
	swi	7
	ret

FileIO_ReadMultiByteRecord:
	push xiz
	calr FileIO_ReadNextRecord
	ld iz, hl
	exts xiz
	ld xwa, xiz
	cp xwa, 0x0
	jr ge, ReadMultiByteRecord_TestBit7
	ld xhl, 0xffffffff
	jr ReadMultiByteRecord_Epilogue

ReadMultiByteRecord_TestBit7:
	bit 7, iz
	jr z, ReadMultiByteRecord_LoadReg2
	and xiz, 0x7f

ReadMultiByteRecord_Block:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, ReadMultiByteRecord_LoadReg
	ld xhl, 0xffffffff
	jr ReadMultiByteRecord_Epilogue

ReadMultiByteRecord_LoadReg:
	ld wa, hl
	and wa, 0x7f
	exts xwa
	sla xiz, 7
	add xiz, xwa
	bit 7, hl
	jr nz, ReadMultiByteRecord_Block

ReadMultiByteRecord_LoadReg2:
	ld xhl, xiz

ReadMultiByteRecord_Epilogue:
	pop xiz
	ret

FileIO_ReadVariableLengthData:
	lda xsp, (xsp - 12)
	ld (xsp + 4), xbc
	ld (xsp + 8), xwa
	call TaskBuf_ReadNextByte
	ld wa, hl
	exts xwa
	ld (xsp), xwa
	cp xwa, 0x0
	jr ge, ReadVariableLengthDa_LoadParam
	ld xhl, 0xffffffff
	jr ReadVariableLengthDa_Epilogue

ReadVariableLengthDa_LoadParam:
	ld xwa, (xsp + 8)
	ld bc, (xwa)
	incm 1, (xwa)
	ld wa, bc
	extz xwa
	ld xbc, xwa
	add xbc, (xsp + 4)
	ld xwa, (xsp)
	ld (xbc), a
	ld xwa, (xsp)
	bit 7, wa
	jr z, ReadVariableLengthDa_LoadParam3
	ld xwa, 0x7f
	and (xsp), xwa

ReadVariableLengthDa_DoReadNext:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, ReadVariableLengthDa_LoadParam2
	ld xhl, 0xffffffff
	jr ReadVariableLengthDa_Epilogue

ReadVariableLengthDa_LoadParam2:
	ld xwa, (xsp + 8)
	ld bc, (xwa)
	incm 1, (xwa)
	ld wa, bc
	extz xwa
	ld xbc, xwa
	add xbc, (xsp + 4)
	ld a, l
	ld (xbc), a
	ld wa, hl
	and wa, 0x7f
	ld bc, wa
	exts xbc
	ld xwa, (xsp)
	sla xwa, 7
	add xwa, xbc
	ld (xsp), xwa
	bit 7, hl
	jr nz, ReadVariableLengthDa_DoReadNext

ReadVariableLengthDa_LoadParam3:
	ld xhl, (xsp)

ReadVariableLengthDa_Epilogue:
	lda xsp, (xsp + 12)
	ret

ReadVariableLengthDa_Prologue:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld (xsp + 6), wa
	lds iz, 0
	ld wa, iz
	cp wa, (xsp + 6)
	jr nc, ReadVariableLengthDa_InitVal

ReadVariableLengthDa_LoopBody:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, ReadVariableLengthDa_LoopCheck
	ldw hl, 0xffff
	jr ReadVariableLengthDa_RestoreReg

ReadVariableLengthDa_LoopCheck:
	ld xwa, (xsp + 2)
	lda_dri3 XSP, 0x07, 0xe0, 0xf8
	inc 1, iz
	ld wa, iz
	cp wa, (xsp + 6)
	jr c, ReadVariableLengthDa_LoopBody

ReadVariableLengthDa_InitVal:
	lds hl, 0

ReadVariableLengthDa_RestoreReg:
	popw iz
	inc 6, xsp
	ret

AccWrap_PlayModeStateMachine:
	cps wa, 4
	jrl z, PlayModeStateMachine_Block4
	cps wa, 3
	jrl z, PlayModeStateMachine_DoPlayMode2
	cps wa, 2
	jr z, PlayModeStateMachine_Block2
	cps wa, 1
	jr z, PlayModeStateMachine_Block
	cps wa, 6
	ret nz
	stdi16 53402, 30
	ei 6
	stdi16 1052, 0
	stdi8 1051, 0
	ei 0
	ret

PlayModeStateMachine_Block:
	cpdi16 53402, 0
	ret le
	subdi16 53402, 1
	ret nz
	resda 1, 10418
	resda 2, 10418
	resda 3, 10407
	ei 6
	stdi16 1052, 0
	stdi8 1051, 0
	ei 0
	jp AccWrap_PlayModeStart

PlayModeStateMachine_Block2:
	cpdi16 53402, 0
	jr le, PlayModeStateMachine_DoPlayMode
	stdi16 53402, 0
	ret

PlayModeStateMachine_DoPlayMode:
	call AccWrap_PlayModeDispatch
	lds32 xwa, 0
	cp xwa, 0x7ffe
	jr ugt, PlayModeStateMachine_Block3

PlayModeStateMachine_TestBit2:
	bitda 2, 1057
	jr nz, PlayModeStateMachine_Block3
	inc 1, xwa
	cp xwa, 0x7ffe
	jr ule, PlayModeStateMachine_TestBit2

PlayModeStateMachine_Block3:
	ei 6
	stdi16 1052, 0
	stdi8 1051, 0
	ei 0
	ret

PlayModeStateMachine_DoPlayMode2:
	call AccWrap_PlayModeStart
	ei 6
	ldda32 xwa, 53412
	stda16 1052, xwa
	ldda32 xwa, 53408
	stda8 1051, a
	ei 0
	ret

PlayModeStateMachine_Block4:
	ei 6
	ldda16 xwa, 1052
	extz xwa
	stda32 53412, xwa
	lds32 xwa, 0
	ldda8 a, 1051
	stda32 53408, xwa
	ei 0
	call AccWrap_PlayModeDispatch
	lds32 xwa, 0
	cp xwa, 0x7ffe
	ret ugt

PlayModeStateMachine_TestBit22:
	bitda 2, 1057
	ret nz
	inc 1, xwa
	cp xwa, 0x7ffe
	jr ule, PlayModeStateMachine_TestBit22
	ret

PlayModeStateMachine_Block5:
	resda 2, 10407
	ret

PlayModeStateMachine_Prologue:
	dec 4, xsp
	push xiz
	ld (xsp + 4), bc
	ld (xsp + 6), wa
	ei 6
	ldda8 a, 1051
	lds32 xbc, 0
	ld c, a
	ldda16 xwa, 1052
	mul wa, 0x60
	ld xiz, xwa
	add xiz, xbc
	ei 0
	ld wa, (xsp + 6)
	bit 2, wa
	jr z, PlayModeStateMachine_LoadParam
	ldda16 xwa, 60430
	decdi16 1, 60430
	cps wa, 0
	jr ge, PlayModeStateMachine_LoadParam
	stdi16 60430, 6
	inc 1, xiz
	ei 6
	ld xwa, xiz
	ld xbc, 0x60
	call Math_DivideU32
	stda16 1052, xhl
	ldda16 xwa, 1052
	extz xwa
	stda32 53412, xwa
	ld xwa, xiz
	ld xbc, 0x60
	call DivMod32
	ld a, l
	stda8 1051, a
	ldb w, 0x0
	extz xwa
	stda32 53408, xwa
	ei 0

PlayModeStateMachine_LoadParam:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xiz
	call Math_MultiplyAccumulate
	ld xwa, xhl
	ld xbc, 0x60
	call Math_DivideU32
	ld xiz, xhl
	pop xiz
	inc 4, xsp
	ret

SeqPlay_BusyWaitLoop:
	bitda 0, 1074
	jr nz, SeqPlay_BusyWaitLoop
	ret

MIDI_ResetAllChannels:
	lda xsp, (xsp - 10)
	pushw iz
	lds iz, 0
	cp iz, 0x10
	jr ge, ResetAllChannels_RestoreReg

ResetAllChannels_LoadIdx:
	ldto_berp A, 0xf8
	or a, 0xb0
	ld (xsp + 2), a
	ld (xsp + 3), 0x7b
	ld (xsp + 4), 0x0
	lda xwa, (xsp + 2)
	ld xbc, xwa
	lds wa, 3
	calr MIDI_SendSinglePacket
	ldto_berp A, 0xf8
	or a, 0xb0
	ld (xsp + 2), a
	ld (xsp + 3), 0x0
	ld (xsp + 4), 0x40
	lda xwa, (xsp + 2)
	ld xbc, xwa
	lds wa, 3
	calr MIDI_SendSinglePacket
	ldto_berp A, 0xf8
	or a, 0xb0
	ld (xsp + 2), a
	ld (xsp + 3), 0x40
	ld (xsp + 4), 0x0
	lda xwa, (xsp + 2)
	ld xbc, xwa
	lds wa, 3
	calr MIDI_SendSinglePacket
	inc 1, iz
	cp iz, 0x10
	jr lt, ResetAllChannels_LoadIdx

ResetAllChannels_RestoreReg:
	popw iz
	lda xsp, (xsp + 10)
	ret

MIDI_SendSinglePacket:
	lda xsp, (xsp - 34)
	push xiz
	ld xiz, xbc
	ld (xsp + 36), wa
	lds wa, 1
	ld xiy, 0xeec188
	lda xix, (xsp + 4)
	ldw bc, 0x10
	ldirw
	cp (xiz), 0xf0
	jr c, SendSinglePacket_LoadReg
	cp (xiz), 0xf7
	jr ugt, SendSinglePacket_LoadReg
	ei 6
	push xiz
	pushm (xsp + 40)
	call SeqBuf2_WriteBytes
	inc 6, xsp
	ei 0
	jr SendSinglePacket_DoGetPlayS

SendSinglePacket_LoadReg:
	ld a, (xiz)
	and a, 0xf
	extz wa
	add wa, wa
	lda xbc, (xsp + 4)
	ldda16 xde, 59891
	and_sriw_rm DE, 0x07, 0xe4, 0xe0
	jr nz, SendSinglePacket_DoGetPlayS
	ei 6
	push xiz
	pushm (xsp + 40)
	call SeqMain_WriteBytes
	inc 6, xsp
	ei 0

SendSinglePacket_DoGetPlayS:
	call GetPlayState2
	cps l, 0
	jr z, SendSinglePacket_Epilogue
	cpdi8 59876, 1
	jr nz, SendSinglePacket_Epilogue
	push xiz
	pushm (xsp + 40)
	call SeqOut_WriteTimedBytes
	inc 6, xsp

SendSinglePacket_Epilogue:
	pop xiz
	lda xsp, (xsp + 34)
	ret

SendSinglePacket_Data:	.asciz "¿Þ7>éŽ¿$PØ©E¨Áî"
	lda	xix, (xsp+4)
	ldw	bc, 16
	ldirw
	cp	(xiz), 240
	jr	c, 21
	cp	(xiz), 247
	jr	ugt, 16
	ei	0x06
	push	xiz
	pushm	(xsp+40)
	call	SeqBuf2_WriteBytes
	inc	6, xsp
	ei	0x00
	jr	37
	ld	a, (xiz)
	and	a, 15
	extz	wa
	add	wa, wa
	lda	xbc, (xsp+4)
	ldda16	de, 59891
	.byte 0xd3
	reti
	.byte 0xe4, 0xe0, 0xc2
	jr	nz, 14
	ei	0x06
	push	xiz
	pushm	(xsp+40)
	call	SeqMain_WriteBytes
	inc	6, xsp
	ei	0x00
	pop	xiz
	lda	xsp, (xsp+34)
	ret

SendSinglePacket_WriteReg:
	st_dri3b L, 0xfd, 0x72, 0xff
	pushw iz
	ld xiy, 0xeec1c8
	st_dri3b D, 0xfd, 0x88, 0x00
	lds bc, 2
	ldirw
	ldi85
	ld xiy, 0xeec1ce
	st_dri3b D, 0xfd, 0x82, 0x00
	lds bc, 2
	ldirw
	ldi85
	stiw_dri 0xfd, 0x8e, 0x00, 0x00, 0x00
	cp_sriw_im 0xfd, 0x8e, 0x00, 0x03, 0x00
	jr ugt, SendSinglePacket_Block2

SendSinglePacket_DoReadNext:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, SendSinglePacket_Block
	ldw hl, 0xffff
	jrl SeqFile_Epilogue

SendSinglePacket_Block:
	ld_sriw WA, (xsp + 0x008e)
	extz xwa
	st_dri3b A, 0xfd, 0x88, 0x00
	add xbc, xwa
	cp l, (xbc)
	jr nz, SendSinglePacket_Block2
	inc_sriw 1, 0xfd, 0x8e, 0x00
	cp_sriw_im 0xfd, 0x8e, 0x00, 0x03, 0x00
	jr ule, SendSinglePacket_DoReadNext

SendSinglePacket_Block2:
	cp_sriw_im 0xfd, 0x8e, 0x00, 0x04, 0x00
	jrl z, SeqFile_SkipPadding_Init
	lds iz, 0
	lds wa, 3
	sub_sriw_rm WA, 0xfd, 0x8e, 0x00
	cp iz, wa
	jr ugt, SendSinglePacket_Block3

SendSinglePacket_DoReadNext2:
	call TaskBuf_ReadNextByte
	cps hl, 0
	jr ge, SendSinglePacket_Increment
	ldw hl, 0xffff
	jrl SeqFile_Epilogue

SendSinglePacket_Increment:
	inc 1, iz
	lds wa, 3
	sub_sriw_rm WA, 0xfd, 0x8e, 0x00
	cp iz, wa
	jr ule, SendSinglePacket_DoReadNext2

SendSinglePacket_Block3:
	stiw_dri 0xfd, 0x8e, 0x00, 0x00, 0x00
	cp_sriw_im 0xfd, 0x8e, 0x00, 0x7b, 0x00
	jr ugt, SeqFile_ReadMagicInit

SeqFile_SkipHeaderBytes_Loop:
	call TaskBuf_ReadNextByte
	cps hl, 0
	jr ge, SeqFile_SkipHeaderBytes_Next
	ldw hl, 0xffff
	jrl SeqFile_Epilogue

SeqFile_SkipHeaderBytes_Next:
	inc_sriw 1, 0xfd, 0x8e, 0x00
	cp_sriw_im 0xfd, 0x8e, 0x00, 0x7b, 0x00
	jr ule, SeqFile_SkipHeaderBytes_Loop

SeqFile_ReadMagicInit:
	stiw_dri 0xfd, 0x8e, 0x00, 0x00, 0x00
	cp_sriw_im 0xfd, 0x8e, 0x00, 0x03, 0x00
	jr ugt, SeqFile_ValidateMagicCount

SeqFile_ReadMagicByte_Loop:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, SeqFile_CheckMagicByte
	ldw hl, 0xffff
	jrl SeqFile_Epilogue

SeqFile_CheckMagicByte:
	ld_sriw WA, (xsp + 0x008e)
	extz xwa
	st_dri3b A, 0xfd, 0x88, 0x00
	add xbc, xwa
	cp l, (xbc)
	jr nz, SeqFile_ValidateMagicCount
	inc_sriw 1, 0xfd, 0x8e, 0x00
	cp_sriw_im 0xfd, 0x8e, 0x00, 0x03, 0x00
	jr ule, SeqFile_ReadMagicByte_Loop

SeqFile_ValidateMagicCount:
	cp_sriw_im 0xfd, 0x8e, 0x00, 0x04, 0x00
	jr z, SeqFile_SkipPadding_Init
	ldw hl, 0xfffe
	jrl SeqFile_Epilogue

SeqFile_SkipPadding_Init:
	stiw_dri 0xfd, 0x8e, 0x00, 0x00, 0x00
	cp_sriw_im 0xfd, 0x8e, 0x00, 0x04, 0x00
	jr ugt, SeqFile_ReadFormatByte

SeqFile_SkipPadding_Loop:
	call TaskBuf_ReadNextByte
	cps hl, 0
	jr ge, SeqFile_SkipPadding_Next
	ldw hl, 0xffff
	jrl SeqFile_Epilogue

SeqFile_SkipPadding_Next:
	inc_sriw 1, 0xfd, 0x8e, 0x00
	cp_sriw_im 0xfd, 0x8e, 0x00, 0x04, 0x00
	jr ule, SeqFile_SkipPadding_Loop

SeqFile_ReadFormatByte:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, SeqFile_ValidateFormat
	ldw hl, 0xffff
	jrl SeqFile_Epilogue

SeqFile_ValidateFormat:
	cps hl, 0
	jr z, SeqFile_ReadTempoByte1
	ldw hl, 0xfffc
	jrl SeqFile_Epilogue

SeqFile_ReadTempoByte1:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, SeqFile_StoreTempoByte1
	ldw hl, 0xffff
	jrl SeqFile_Epilogue

SeqFile_StoreTempoByte1:
	ld a, l
	extz wa
	sla wa, 8
	stda16 59889, xwa
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, SeqFile_ReadTempoByte2
	ldw hl, 0xffff
	jrl SeqFile_Epilogue

SeqFile_ReadTempoByte2:
	ld a, l
	extz wa
	adddm16 59889, xwa
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, SeqFile_ReadDivisionByte1
	ldw hl, 0xffff
	jrl SeqFile_Epilogue

SeqFile_ReadDivisionByte1:
	ld a, l
	extz wa
	sla wa, 8
	stda16 59887, xwa
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, SeqFile_StoreDivisionByte1
	ldw hl, 0xffff
	jrl SeqFile_Epilogue

SeqFile_StoreDivisionByte1:
	ld a, l
	extz wa
	adddm16 59887, xwa
	stiw_dri 0xfd, 0x8e, 0x00, 0x00, 0x00
	cp_sriw_im 0xfd, 0x8e, 0x00, 0x03, 0x00
	jr ugt, SeqFile_ValidateTrackMagic

SeqFile_ReadTrackMagic_Loop:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, SeqFile_CheckTrackMagic
	ldw hl, 0xffff
	jr SeqFile_Epilogue

SeqFile_CheckTrackMagic:
	ld_sriw WA, (xsp + 0x008e)
	extz xwa
	st_dri3b A, 0xfd, 0x82, 0x00
	add xbc, xwa
	cp l, (xbc)
	jr nz, SeqFile_ValidateTrackMagic
	inc_sriw 1, 0xfd, 0x8e, 0x00
	cp_sriw_im 0xfd, 0x8e, 0x00, 0x03, 0x00
	jr ule, SeqFile_ReadTrackMagic_Loop

SeqFile_ValidateTrackMagic:
	cp_sriw_im 0xfd, 0x8e, 0x00, 0x04, 0x00
	jr z, SeqFile_SkipTrackPad_Init
	ldw hl, 0xfffe
	jr SeqFile_Epilogue

SeqFile_SkipTrackPad_Init:
	stiw_dri 0xfd, 0x8e, 0x00, 0x00, 0x00
	cp_sriw_im 0xfd, 0x8e, 0x00, 0x03, 0x00
	jr ugt, SeqFile_ReadTrackLength

SeqFile_SkipTrackPad_Loop:
	call TaskBuf_ReadNextByte
	cps hl, 0
	jr ge, SeqFile_SkipTrackPad_Next
	ldw hl, 0xffff
	jr SeqFile_Epilogue

SeqFile_SkipTrackPad_Next:
	inc_sriw 1, 0xfd, 0x8e, 0x00
	cp_sriw_im 0xfd, 0x8e, 0x00, 0x03, 0x00
	jr ule, SeqFile_SkipTrackPad_Loop

SeqFile_ReadTrackLength:
	st_dri3b W, 0xfd, 0x8e, 0x00
	ld xde, xwa
	lda xwa, (xsp + 2)
	ld xbc, xwa
	ld xwa, xde
	calr FileIO_ReadVariableLengthData
	ld xwa, xhl
	cp xwa, 0x0
	jr ge, SeqFile_AccumulateLength
	ldw hl, 0xffff
	jr SeqFile_Epilogue

SeqFile_AccumulateLength:
	adddm32 59879, xhl
	lds hl, 0

SeqFile_Epilogue:
	popw iz
	st_dri3b L, 0xfd, 0x8e, 0x00
	ret

SeqInit_ResetAndSetupChannels:
	calr MIDI_ResetAllChannels
	call GetPlayState1
	cps l, 0
	jr z, SeqInit_SetDefaultMode
	lds wa, 1
	calr SoundParam_InitDefaultBanks
	jr SeqInit_ConfigureBanks

SeqInit_SetDefaultMode:
	lds wa, 0
	calr SoundParam_InitDefaultBanks

SeqInit_ConfigureBanks:
	lds32 xwa, 4
	call SndParam_LookupReadOnly
	ld wa, hl
	exts xwa
	set 15, wa
	stda16 4597, xwa
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cps hl, 1
	jr nz, ConfigureBanks_Send
	stdi8 4330, 1
	ld xwa, 0xc0
	lds bc, 1
	lds de, 1
	call SoundParam_NotifyChange
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz

ConfigureBanks_Send:
	stdi16 60153, 0
	stdi16 60411, 0
	call Audio_SendEventPostCmd
	lds hl, 0
	ret

ConfigureBanks_LoadReg:
	ld c, a
	cp c, 0xf7
	jr z, ConfigureBanks_Block2
	cp c, 0xf0
	jr z, ConfigureBanks_Block2
	cp c, 0xff
	jr nz, ConfigureBanks_Extend
	calr ConfigureBanks_WriteReg
	ld wa, hl
	cps wa, 0
	ret lt
	calr FileIO_ReadMultiByteRecord
	ld xwa, xhl
	cp xwa, 0x0
	jr ge, ConfigureBanks_Block
	ldw hl, 0xffff
	ret

ConfigureBanks_Block:
	adddm32 59879, xhl
	jr ConfigureBanks_InitVal

ConfigureBanks_Block2:
	calr SeekRecord_Done_Prologue
	ld wa, hl
	cps wa, 0
	ret lt
	calr FileIO_ReadMultiByteRecord
	ld xwa, xhl
	cp xwa, 0x0
	jr ge, ConfigureBanks_Block3
	ldw hl, 0xffff
	ret

ConfigureBanks_Block3:
	adddm32 59879, xhl
	jr ConfigureBanks_InitVal

ConfigureBanks_Extend:
	extz wa
	calr SeekRecord_PopReturn_Prologue
	ld wa, hl
	cps wa, 0
	ret lt
	calr FileIO_ReadMultiByteRecord
	ld xwa, xhl
	cp xwa, 0x0
	ret lt
	adddm32 59879, xhl

ConfigureBanks_InitVal:
	lds hl, 0
	ret

ConfigureBanks_WriteReg:
	st_dri3b L, 0xfd, 0xfc, 0xfe
	push xiz
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, ConfigureBanks_LoadReg2
	ldw hl, 0xffff
	jrl FileIO_SeekRecord_Done

ConfigureBanks_LoadReg2:
	ld a, l
	cp a, 0x51
	jrl z, ConfigureBanks_Block7
	cp a, 0x2f
	jr z, ConfigureBanks_Block6
	cps a, 5
	jrl nz, ConfigureBanks_Block10
	calr FileIO_ReadNextRecord
	ld wa, hl
	exts xwa
	ld (xsp + 4), xwa
	cp xwa, 0x0
	jr ge, ConfigureBanks_Block4
	ldw hl, 0xffff
	jrl FileIO_SeekRecord_Done

ConfigureBanks_Block4:
	lds32 xiz, 0
	cp xiz, (xsp + 4)
	jr ge, ConfigureBanks_LoadAddr2

ConfigureBanks_Block5:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, ConfigureBanks_LoadAddr
	ldw hl, 0xffff
	jrl FileIO_SeekRecord_Done

ConfigureBanks_LoadAddr:
	lda xwa, (xsp + 8)
	ld xbc, xiz
	add xbc, xwa
	ld (xbc), l
	inc 1, xiz
	cp xiz, (xsp + 4)
	jr lt, ConfigureBanks_Block5

ConfigureBanks_LoadAddr2:
	lda xwa, (xsp + 8)
	ld xbc, xiz
	add xbc, xwa
	ld (xbc), 0x0
	ldda32 xwa, 59879
	or xwa, xwa
	jrl z, FileIO_SeekRecord_LoopDone
	ld xwa, (xsp + 4)
	extz wa
	calr MidiRingBuf_WriteByte
	ld xwa, (xsp + 4)
	ld de, wa
	lda xwa, (xsp + 8)
	ld xbc, xwa
	ld wa, de
	calr StoreAndAdvance_Prologue2
	calr SeqFile_ParseHeader
	call Audio_ExternalCallback
	jrl FileIO_SeekRecord_LoopDone

ConfigureBanks_Block6:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, ConfigureBanks_SetWord
	ldw hl, 0xffff
	jrl FileIO_SeekRecord_Done

ConfigureBanks_SetWord:
	ldw hl, 0xfffd
	jrl FileIO_SeekRecord_Done

ConfigureBanks_Block7:
	calr FileIO_ReadNextRecord
	ld wa, hl
	exts xwa
	ld (xsp + 4), xwa
	cp xwa, 0x0
	jr ge, ConfigureBanks_Block8
	ldw hl, 0xffff
	jrl FileIO_SeekRecord_Done

ConfigureBanks_Block8:
	lds32 xiz, 0
	cp xiz, (xsp + 4)
	jr ge, ConfigureBanks_LoadParam

ConfigureBanks_Block9:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, ConfigureBanks_LoadAddr3
	ldw hl, 0xffff
	jrl FileIO_SeekRecord_Done

ConfigureBanks_LoadAddr3:
	lda xwa, (xsp + 8)
	ld xbc, xiz
	add xbc, xwa
	ld (xbc), l
	inc 1, xiz
	cp xiz, (xsp + 4)
	jr lt, ConfigureBanks_Block9

ConfigureBanks_LoadParam:
	ld a, (xsp + 9)
	ld c, a
	extz bc
	ld a, (xsp + 8)
	extz wa
	sll wa, 8
	add wa, bc
	ld bc, wa
	extz xbc
	ld xwa, 0x39387
	call Math_DivideU32
	ld xiz, xhl
	ld xwa, 0x28
	cp xiz, 0x28
	jr ule, ConfigureBanks_LoadReg3
	ld xwa, xiz

ConfigureBanks_LoadReg3:
	ld xiz, xwa
	ld xwa, 0x12c
	cp xiz, 0x12c
	jr nc, ConfigureBanks_LoadReg4
	ld xwa, xiz

ConfigureBanks_LoadReg4:
	ld xiz, xwa
	set 15, wa
	stda16 4597, xwa
	ld bc, iz
	lds32 xwa, 4
	lds de, 3
	call SoundParam_NotifyChange
	call SeqTimer_UpdateTempoReg
	stda32 59883, xiz
	jr FileIO_SeekRecord_LoopDone

ConfigureBanks_Block10:
	calr FileIO_ReadMultiByteRecord
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	cp xwa, 0x0
	jr ge, ConfigureBanks_Block11
	ldw hl, 0xffff
	jr FileIO_SeekRecord_Done

ConfigureBanks_Block11:
	lds32 xiz, 0
	cp xiz, (xsp + 4)
	jr ge, FileIO_SeekRecord_LoopDone

ConfigureBanks_Block12:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, ConfigureBanks_NextIter
	ldw hl, 0xffff
	jr FileIO_SeekRecord_Done

ConfigureBanks_NextIter:
	inc 1, xiz
	cp xiz, (xsp + 4)
	jr lt, ConfigureBanks_Block12

FileIO_SeekRecord_LoopDone:
	lds hl, 0

FileIO_SeekRecord_Done:
	pop xiz
	st_dri3b L, 0xfd, 0x04, 0x01
	ret

SeekRecord_Done_Prologue:
	lda xsp, (xsp - 128)
	push xiz
	calr FileIO_ReadNextRecord
	ldfr_werp HL, 0xfa
	ldto_werp WA, 0xfa
	cps wa, 0
	jr ge, SeekRecord_Done_Block
	ldw hl, 0xffff
	jrl FileIO_SeekRecord_PopReturn

SeekRecord_Done_Block:
	cp_erpw 0xfa, 0x7f, 0x00
	jr le, SeekRecord_Done_LoadParam
	lds iz, 0
	ldto_werp WA, 0xfa
	cp iz, wa
	jrl nc, FileIO_SeekRecord_Return

SeekRecord_Done_LoopBody:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, SeekRecord_Done_LoopCheck
	ldw hl, 0xffff
	jrl FileIO_SeekRecord_PopReturn

SeekRecord_Done_LoopCheck:
	inc 1, iz
	ldto_werp WA, 0xfa
	cp iz, wa
	jr c, SeekRecord_Done_LoopBody
	jrl FileIO_SeekRecord_Return

SeekRecord_Done_LoadParam:
	ld (xsp + 4), 0xf0
	lds iz, 0
	ldto_werp WA, 0xfa
	cp iz, wa
	jr nc, SeekRecord_Done_Compare

SeekRecord_Done_LoopBody2:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, SeekRecord_Done_LoopCheck2
	ldw hl, 0xffff
	jrl FileIO_SeekRecord_PopReturn

SeekRecord_Done_LoopCheck2:
	ld wa, iz
	inc 1, wa
	extz xwa
	lda xbc, (xsp + 4)
	add xbc, xwa
	ld (xbc), l
	inc 1, iz
	ldto_werp WA, 0xfa
	cp iz, wa
	jr c, SeekRecord_Done_LoopBody2

SeekRecord_Done_Compare:
	cp (xsp + 5), 0x5
	jr nz, FileIO_SeekRecord_SendMidi
	cp (xsp + 6), 0x7e
	jr nz, FileIO_SeekRecord_SendMidi
	cp (xsp + 7), 0x7f
	jr nz, FileIO_SeekRecord_SendMidi
	cp (xsp + 8), 0x9
	jr nz, FileIO_SeekRecord_SendMidi
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cps hl, 1
	jr nz, SeekRecord_Done_DoLookupRe
	cp (xsp + 8), 0x1
	jr nz, SeekRecord_Done_Block2

SeekRecord_Done_DoLookupRe:
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cps hl, 0
	jr nz, SeekRecord_Done_DoGetPlayS
	cp (xsp + 8), 0x2
	jr z, SeekRecord_Done_DoGetPlayS

SeekRecord_Done_Block2:
	calr SeqPlay_BusyWaitLoop
	ldto_werp WA, 0xfa
	inc 1, wa
	ld de, wa
	lda xwa, (xsp + 4)
	ld xbc, xwa
	ld wa, de
	calr MIDI_SendSinglePacket
	jr FileIO_SeekRecord_Return

SeekRecord_Done_DoGetPlayS:
	call GetPlayState2
	cps l, 0
	jr z, FileIO_SeekRecord_Return
	cpdi8 59876, 1
	jr nz, FileIO_SeekRecord_Return
	lda xwa, (xsp + 4)
	push xwa
	ldto_werp WA, 0xfa
	inc 1, wa
	pushw wa
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr FileIO_SeekRecord_Return

FileIO_SeekRecord_SendMidi:
	calr SeqPlay_BusyWaitLoop
	ldto_werp WA, 0xfa
	inc 1, wa
	ld de, wa
	lda xwa, (xsp + 4)
	ld xbc, xwa
	ld wa, de
	calr MIDI_SendSinglePacket

FileIO_SeekRecord_Return:
	lds hl, 0

FileIO_SeekRecord_PopReturn:
	pop xiz
	st_dri3b L, 0xfd, 0x80, 0x00
	ret

SeekRecord_PopReturn_Prologue:
	lda xsp, (xsp - 10)
	push xiz
	ld xiy, 0xeec1d4
	lda xix, (xsp + 4)
	lds bc, 5
	ldirw
	bit 7, a
	jr z, SeekRecord_PopReturn_Block
	stda8 53404, a
	ld (xsp + 4), a
	lds iz, 1
	jr SeekRecord_PopReturn_LoadDRAM

SeekRecord_PopReturn_Block:
	ldmi16 (xsp + 4), 0xd09c
	ld (xsp + 5), a
	lds iz, 2

SeekRecord_PopReturn_LoadDRAM:
	ldda8 a, 53404
	and a, 0xf0
	cp a, 0xc0
	jr z, SeekRecord_PopReturn_Block2
	cp a, 0xd0
	jr nz, SeekRecord_PopReturn_Block3

SeekRecord_PopReturn_Block2:
	ldi_werp 0xfa, 2
	jr SeekRecord_PopReturn_Block4

SeekRecord_PopReturn_Block3:
	ldi_werp 0xfa, 3

SeekRecord_PopReturn_Block4:
	cp_werp IZ, 0xfa
	jr nc, SeekRecord_PopReturn_LoadAddr

SeekRecord_PopReturn_LoopBody:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, SeekRecord_PopReturn_LoopCheck
	ldw hl, 0xffff
	jr SeekRecord_PopReturn_Epilogue

SeekRecord_PopReturn_LoopCheck:
	ld wa, iz
	extz xwa
	lda xbc, (xsp + 4)
	add xbc, xwa
	ld (xbc), l
	inc 1, iz
	cp_werp IZ, 0xfa
	jr c, SeekRecord_PopReturn_LoopBody

SeekRecord_PopReturn_LoadAddr:
	lda xwa, (xsp + 4)
	ld xbc, xwa
	ldto_werp WA, 0xfa
	calr MIDI_SendSinglePacket
	lds hl, 0

SeekRecord_PopReturn_Epilogue:
	pop xiz
	lda xsp, (xsp + 10)
	ret

SeekRecord_PopReturn_Data:
	lds	hl, 0
	ret

SeqFile_ParseHeader:
	pushw iz
	lds iz, 0
	cpdi8 59844, 0
	jr nz, SeqFile_ParseHeader_Block2
	lds hl, 0
	jr SeqFile_ParseHeader_RestoreReg

SeqFile_ParseHeader_Block:
	calr Seq_CalcAddrOffset
	cp hl, 0x780
	jr le, SeqFile_ParseHeader_Block2
	calr SysexRingBuf_GetFreeSpace
	cp hl, 0x40
	jr gt, SeqFile_ParseHeader_Block3
	calr Seq_CalcAddrOffset
	cp hl, 0x7ec
	jr gt, SeqFile_ParseHeader_Block3

SeqFile_ParseHeader_Block2:
	calr SongFile_DecodeMidiEvent
	ld iz, hl
	ld wa, iz
	cps wa, 0
	jr z, SeqFile_ParseHeader_Block

SeqFile_ParseHeader_Block3:
	calr SysexRingBuf_GetFreeSpace
	cps hl, 0
	call_24 gt, 0xf2aa02
	ld wa, iz
	cp wa, 0xfffd
	jr z, SeqFile_ParseHeader_LoadReg
	cp wa, 0xfffe
	jr z, SeqFile_ParseHeader_DoVoiceSta
	cp wa, 0xffff
	jr nz, SeqFile_ParseHeader_LoadReg

SeqFile_ParseHeader_DoVoiceSta:
	calr Song_AbortPlayback
	ld wa, iz
	call SongMode_VoiceStateDisp

SeqFile_ParseHeader_LoadReg:
	ld hl, iz

SeqFile_ParseHeader_RestoreReg:
	popw iz
	ret

SeqFile_ReadTrackData:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xwa
	calr SysexRingBuf_ReadByte
	ld iz, hl
	ld wa, iz
	cps wa, 0
	jr ge, SeqFile_ReadTrackDat_LoadIter
	ld xwa, (xsp + 2)
	ld (xwa), 0x0
	jr SeqFile_ReadTrackDat_RestoreReg

SeqFile_ReadTrackDat_LoadIter:
	ld wa, iz
	ld xbc, (xsp + 2)
	calr SysexRingBuf_ReadBytes
	cps hl, 0
	jr ge, SeqFile_ReadTrackDat_LoadParam
	ld xwa, (xsp + 2)
	ld (xwa), 0x0
	jr SeqFile_ReadTrackDat_RestoreReg

SeqFile_ReadTrackDat_LoadParam:
	ld xwa, (xsp + 2)
	stib_dri 0x07, 0xe0, 0xf8, 0x00

SeqFile_ReadTrackDat_RestoreReg:
	popw iz
	inc 4, xsp
	ret

SeqFile_ValidateAndStore:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xwa
	calr StoreAndAdvance_LoadDRAM
	ld iz, hl
	ld wa, iz
	cps wa, 0
	jr ge, SeqFile_ValidateAndS_LoadIter
	ld xwa, (xsp + 2)
	ld (xwa), 0x0
	jr SeqFile_ValidateAndS_RestoreReg

SeqFile_ValidateAndS_LoadIter:
	ld wa, iz
	ld xbc, (xsp + 2)
	calr StoreAndAdvance_Prologue
	cps hl, 0
	jr ge, SeqFile_ValidateAndS_LoadParam
	ld xwa, (xsp + 2)
	ld (xwa), 0x0
	jr SeqFile_ValidateAndS_RestoreReg

SeqFile_ValidateAndS_LoadParam:
	ld xwa, (xsp + 2)
	stib_dri 0x07, 0xe0, 0xf8, 0x00

SeqFile_ValidateAndS_RestoreReg:
	popw iz
	inc 4, xsp
	ret

SongFile_DecodeMidiEvent:
	st_dri3b L, 0xfd, 0xf0, 0xfd
	pushw iz
	lds iz, 0
	lds32 xwa, 0
	ld (xsp + 6), xwa
	ldw (xsp + 10), 0x0
	cpdi16 60411, 0
	jr z, DecodeMidiEvent_Block2
	ldda16 xde, 60411
	ldada xwa, 60155
	ld xbc, xwa
	ld wa, de
	calr MidiRingBuf_WriteBytes
	cps hl, 0
	jr ge, DecodeMidiEvent_Block
	ldw hl, 0xfffd
	jrl SeqPlay_Epilogue

DecodeMidiEvent_Block:
	stdi16 60411, 0

DecodeMidiEvent_Block2:
	cpdi16 60153, 0
	jr z, DecodeMidiEvent_LoadDRAM
	ldda16 xde, 60153
	ldada xwa, 59897
	ld xbc, xwa
	ld wa, de
	calr SysexRingBuf_WriteBytes
	cps hl, 0
	jr ge, DecodeMidiEvent_Send
	ldw hl, 0xfffd
	jrl SeqPlay_Epilogue

DecodeMidiEvent_Send:
	call Audio_SendEventPostCmd
	stdi16 60153, 0

DecodeMidiEvent_LoadDRAM:
	ldda16 xwa, 59877
	bit 4, wa
	jr z, DecodeMidiEvent_DoReadNext
	ldw hl, 0xfffd
	jrl SeqPlay_Epilogue

DecodeMidiEvent_DoReadNext:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, DecodeMidiEvent_LoadParam
	ldw hl, 0xffff
	jrl SeqPlay_Epilogue

DecodeMidiEvent_LoadParam:
	ld wa, (xsp + 10)
	incm 1, (xsp + 10)
	lda xbc, (xsp + 12)
	lda_dri3 XSP, 0x07, 0xe4, 0xe0
	ld wa, (xsp + 10)
	lda xbc, (xsp + 11)
	ld_srib3 A, 0x07, 0xe4, 0xe0
	cp a, 0xf7
	jrl z, DecodeMidiEvent_DoReadNext3
	cp a, 0xf0
	jrl z, DecodeMidiEvent_DoReadNext3
	cp a, 0xff
	jrl nz, SeqPlay_CheckBit7Path
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, DecodeMidiEvent_LoadParam2
	ldw hl, 0xffff
	jrl SeqPlay_Epilogue

DecodeMidiEvent_LoadParam2:
	ld wa, (xsp + 10)
	incm 1, (xsp + 10)
	lda xbc, (xsp + 12)
	lda_dri3 XSP, 0x07, 0xe4, 0xe0
	ld wa, (xsp + 10)
	lda xbc, (xsp + 11)
	ld_srib3 A, 0x07, 0xe4, 0xe0
	cp a, 0x2f
	jr nz, DecodeMidiEvent_LoadAddr
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, DecodeMidiEvent_LoadParam3
	ldw hl, 0xffff
	jrl SeqPlay_Epilogue

DecodeMidiEvent_LoadParam3:
	ld wa, (xsp + 10)
	incm 1, (xsp + 10)
	lda xbc, (xsp + 12)
	lda_dri3 XSP, 0x07, 0xe4, 0xe0
	ordi16 59877, 16
	jrl SeqPlay_ReadRecord_Entry

DecodeMidiEvent_LoadAddr:
	lda xwa, (xsp + 10)
	ld xde, xwa
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, xde
	calr FileIO_ReadVariableLengthData
	ld (xsp + 2), xhl
	ld xwa, (xsp + 2)
	cp xwa, 0x0
	jr ge, DecodeMidiEvent_LoadParam4
	ldw hl, 0xffff
	jrl SeqPlay_Epilogue

DecodeMidiEvent_LoadParam4:
	ld xwa, (xsp + 2)
	cp xwa, 0x7f
	jr lt, DecodeMidiEvent_LoadParam6
	lds iz, 0
	ld wa, iz
	extz xwa
	cp xwa, (xsp + 2)
	jr ge, DecodeMidiEvent_LoadParam5

DecodeMidiEvent_DoReadNext2:
	call TaskBuf_ReadNextByte
	cps hl, 0
	jr ge, DecodeMidiEvent_Increment
	ldw hl, 0xffff
	jrl SeqPlay_Epilogue

DecodeMidiEvent_Increment:
	inc 1, iz
	ld wa, iz
	extz xwa
	cp xwa, (xsp + 2)
	jr lt, DecodeMidiEvent_DoReadNext2

DecodeMidiEvent_LoadParam5:
	ld (xsp + 12), 0xff
	ld (xsp + 13), 0x4
	ld (xsp + 14), 0x1
	ld (xsp + 15), 0x20
	ldw (xsp + 10), 0x4
	jrl SeqPlay_ReadRecord_Entry

DecodeMidiEvent_LoadParam6:
	ld xwa, (xsp + 2)
	ld de, wa
	st_dri3b W, 0xfd, 0x10, 0x01
	ld xbc, xwa
	ld wa, de
	calr ReadVariableLengthDa_Prologue
	cps hl, 0
	jr ge, DecodeMidiEvent_LoadParam7
	ldw hl, 0xffff
	jrl SeqPlay_Epilogue

DecodeMidiEvent_LoadParam7:
	ld xwa, (xsp + 2)
	pushw wa
	st_dri3b W, 0xfd, 0x12, 0x01
	push xwa
	lda xwa, (xsp + 18)
	ld bc, (xsp + 16)
	extz xbc
	add xbc, xwa
	push xbc
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, (xsp + 2)
	add (xsp + 10), wa
	jrl SeqPlay_ReadRecord_Entry

DecodeMidiEvent_DoReadNext3:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, DecodeMidiEvent_LoadParam8
	ldw hl, 0xffff
	jrl SeqPlay_Epilogue

DecodeMidiEvent_LoadParam8:
	ld wa, (xsp + 10)
	incm 1, (xsp + 10)
	lda xbc, (xsp + 12)
	lda_dri3 XSP, 0x07, 0xe4, 0xe0
	ld wa, (xsp + 10)
	lda xbc, (xsp + 11)
	ld_srib3 A, 0x07, 0xe4, 0xe0
	ld e, a
	extz de
	st_dri3b W, 0xfd, 0x10, 0x01
	ld xbc, xwa
	ld wa, de
	calr ReadVariableLengthDa_Prologue
	cps hl, 0
	jr ge, DecodeMidiEvent_LoadParam9
	ldw hl, 0xffff
	jrl SeqPlay_Epilogue

DecodeMidiEvent_LoadParam9:
	ld wa, (xsp + 10)
	lda xbc, (xsp + 11)
	ld_srib3 A, 0x07, 0xe4, 0xe0
	extz wa
	pushw wa
	st_dri3b W, 0xfd, 0x12, 0x01
	push xwa
	lda xwa, (xsp + 18)
	ld bc, (xsp + 16)
	extz xbc
	add xbc, xwa
	push xbc
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld wa, (xsp + 10)
	lda xbc, (xsp + 11)
	ld_srib3 A, 0x07, 0xe4, 0xe0
	extz wa
	add (xsp + 10), wa
	jrl SeqPlay_ReadRecord_Entry

SeqPlay_CheckBit7Path:
	bitm 7, (xsp + 12)
	jr z, SeqPlay_CopyRecordData
	mrdb5 0x8f, 0x0c, 0x19, 0x10, 0xec
	jr SeqPlay_CheckStatusByte

SeqPlay_CopyRecordData:
	ld wa, (xsp + 10)
	lda xde, (xsp + 11)
	lda xbc, (xsp + 12)
	ld hl, (xsp + 10)
	extz xhl
	add xhl, xbc
	ld_srib3 A, 0x07, 0xe8, 0xe0
	ld (xhl), a
	ld wa, (xsp + 10)
	lda xbc, (xsp + 11)
	ldmmb_dri 0x07, 0xe4, 0xe0, 0x10, 0xec
	incm 1, (xsp + 10)

SeqPlay_CheckStatusByte:
	ldda8 a, 60432
	and a, 0xf0
	cp a, 0xc0
	jr z, SeqPlay_TwoByteMsg
	cp a, 0xd0
	jr nz, SeqPlay_ThreeByteMsg

SeqPlay_TwoByteMsg:
	lds32 xwa, 2
	ld (xsp + 2), xwa
	jr SeqPlay_ReadRemainingBytes

SeqPlay_ThreeByteMsg:
	lds32 xwa, 3
	ld (xsp + 2), xwa

SeqPlay_ReadRemainingBytes:
	ld wa, (xsp + 10)
	exts xwa
	cp xwa, (xsp + 2)
	jr ge, SeqPlay_ReadRecord_Entry

SeqPlay_ReadByte_Loop:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, SeqPlay_StoreByte
	ldw hl, 0xffff
	jrl SeqPlay_Epilogue

SeqPlay_StoreByte:
	lda xwa, (xsp + 12)
	ld bc, (xsp + 10)
	extz xbc
	add xbc, xwa
	ld (xbc), l
	incm 1, (xsp + 10)
	ld wa, (xsp + 10)
	exts xwa
	cp xwa, (xsp + 2)
	jr lt, SeqPlay_ReadByte_Loop

SeqPlay_ReadRecord_Entry:
	stiw_dri 0xfd, 0x0e, 0x01, 0x00, 0x00
	ldda32 xwa, 59893
	ld (xsp + 6), xwa
	ldda16 xwa, 59877
	bit 4, wa
	jr nz, SeqPlay_CheckSysExMarker
	st_dri3b W, 0xfd, 0x0e, 0x01
	ld xde, xwa
	st_dri3b W, 0xfd, 0x10, 0x01
	ld xbc, xwa
	ld xwa, xde
	calr FileIO_ReadVariableLengthData
	ld (xsp + 2), xhl
	ld xwa, (xsp + 2)
	cp xwa, 0x0
	jr ge, SeqPlay_AccumulateDelta
	ldw hl, 0xffff
	jrl SeqPlay_Epilogue

SeqPlay_AccumulateDelta:
	ld xwa, (xsp + 2)
	adddm32 59893, xwa

SeqPlay_CheckSysExMarker:
	cp (xsp + 12), 0xff
	jr nz, SeqVoice_InitZeroPath
	cp (xsp + 13), 0x5
	jr nz, SeqVoice_InitZeroPath
	ld xwa, (xsp + 6)
	or xwa, xwa
	jr z, SeqVoice_InitZeroPath
	ld wa, (xsp + 10)
	pushw wa
	lda xwa, (xsp + 14)
	push xwa
	ldada xwa, 59897
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld wa, (xsp + 10)
	stda16 60153, xwa
	jr SeqPlay_CopyToMidiBuffer

SeqVoice_InitZeroPath:
	stdi16 60153, 0

SeqPlay_CopyToMidiBuffer:
	ld wa, (xsp + 10)
	pushw wa
	lda xwa, (xsp + 14)
	push xwa
	ldada xwa, 60155
	push xwa
	call Mem_Copy
	ld wa, (xsp + 20)
	stda16 60411, xwa
	ld_sriw WA, (xsp + 0x0118)
	pushw wa
	st_dri3b W, 0xfd, 0x1c, 0x01
	push xwa
	ldda16 xwa, 60411
	add wa, 0x137
	ldada xbc, 59844
	exts xwa
	add xwa, xbc
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 20)
	ld_sriw WA, (xsp + 0x010e)
	adddm16 60411, xwa
	cpdi16 60153, 0
	jr z, SeqPlay_CheckMidiBuffer
	ldda16 xwa, 60153
	dec 2, wa
	ld de, wa
	ldada xwa, 59899
	ld xbc, xwa
	ld wa, de
	calr SysexRingBuf_WriteBytes
	cps hl, 0
	jr ge, SeqPlay_SendEvent
	ldw hl, 0xfffd
	jr SeqPlay_Epilogue

SeqPlay_SendEvent:
	call Audio_SendEventPostCmd
	stdi16 60153, 0

SeqPlay_CheckMidiBuffer:
	cpdi16 60411, 0
	jr z, SeqPlay_SetSuccess
	ldda16 xde, 60411
	ldada xwa, 60155
	ld xbc, xwa
	ld wa, de
	calr MidiRingBuf_WriteBytes
	cps hl, 0
	jr ge, SeqPlay_ClearMidiCount
	ldw hl, 0xfffd
	jr SeqPlay_Epilogue

SeqPlay_ClearMidiCount:
	stdi16 60411, 0

SeqPlay_SetSuccess:
	lds hl, 0

SeqPlay_Epilogue:
	popw iz
	st_dri3b L, 0xfd, 0x10, 0x02
	ret

SeqPlay_ReadFileRecord:
	lda xsp, (xsp - 14)
	pushw iz
	ld xiy, 0xeec1de
	lda xix, (xsp + 6)
	lds bc, 4
	ldirw
	ldi85
	lds32 xwa, 0
	ld (xsp + 2), xwa
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, SeqPlay_RecordReadOK
	ldw hl, 0xffff
	jrl FileIO_Epilogue

SeqPlay_RecordReadOK:
	cp l, 0xfe
	jr z, RecordReadOK_Block
	ldw hl, 0xfffe
	jrl FileIO_Epilogue

RecordReadOK_Block:
	lds32 xwa, 0
	stda32 59883, xwa
	lds iz, 0
	cps iz, 6
	jr nc, RecordReadOK_InitVal

RecordReadOK_LoopBody:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, RecordReadOK_LoopCheck
	ldw hl, 0xffff
	jrl FileIO_Epilogue

RecordReadOK_LoopCheck:
	inc 1, iz
	cps iz, 6
	jr c, RecordReadOK_LoopBody

RecordReadOK_InitVal:
	lds iz, 0
	cp iz, 0x8
	jr nc, RecordReadOK_InitVal2

RecordReadOK_LoopBody2:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, RecordReadOK_LoadIter
	ldw hl, 0xffff
	jrl FileIO_Epilogue

RecordReadOK_LoadIter:
	ld wa, iz
	extz xwa
	lda xbc, (xsp + 6)
	add xbc, xwa
	cp l, (xbc)
	jr z, RecordReadOK_LoopCheck2
	ldw hl, 0xfffe
	jrl FileIO_Epilogue

RecordReadOK_LoopCheck2:
	inc 1, iz
	cp iz, 0x8
	jr c, RecordReadOK_LoopBody2

RecordReadOK_InitVal2:
	lds iz, 0
	cp iz, 0xa
	jr nc, RecordReadOK_Block2

RecordReadOK_LoopBody3:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, RecordReadOK_LoopCheck3
	ldw hl, 0xffff
	jrl FileIO_Epilogue

RecordReadOK_LoopCheck3:
	inc 1, iz
	cp iz, 0xa
	jr c, RecordReadOK_LoopBody3

RecordReadOK_Block2:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, RecordReadOK_LoadReg
	ldw hl, 0xffff
	jrl FileIO_Epilogue

RecordReadOK_LoadReg:
	ld a, l
	cp a, 0x40
	jr z, RecordReadOK_Block3
	cp a, 0x21
	jr nz, RecordReadOK_SetWord
	stdi8 59876, 2

RecordReadOK_InitVal3:
	lds iz, 0
	cps iz, 1
	jr nc, RecordReadOK_InitVal4

RecordReadOK_LoopBody4:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, RecordReadOK_LoopCheck4
	ldw hl, 0xffff
	jrl FileIO_Epilogue

RecordReadOK_Block3:
	stdi8 59876, 3
	jr RecordReadOK_InitVal3

RecordReadOK_SetWord:
	ldw hl, 0xfffe
	jrl FileIO_Epilogue

RecordReadOK_LoopCheck4:
	inc 1, iz
	cps iz, 1
	jr c, RecordReadOK_LoopBody4

RecordReadOK_InitVal4:
	lds iz, 0
	cps iz, 3
	jr ugt, RecordReadOK_InitVal5

RecordReadOK_Block4:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, RecordReadOK_LoadIter2
	ldw hl, 0xffff
	jrl FileIO_Epilogue

RecordReadOK_LoadIter2:
	ld wa, iz
	sll wa, 3
	ld c, l
	and a, 0xf
	jr z, RecordReadOK_Block5
	slla c

RecordReadOK_Block5:
	lds32 xwa, 0
	ld a, c
	add (xsp + 2), xwa
	inc 1, iz
	cps iz, 3
	jr ule, RecordReadOK_Block4

RecordReadOK_InitVal5:
	lds iz, 0
	cps iz, 3
	jr ugt, RecordReadOK_Block7

RecordReadOK_Block6:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, RecordReadOK_NextIter
	ldw hl, 0xffff
	jrl FileIO_Epilogue

RecordReadOK_NextIter:
	inc 1, iz
	cps iz, 3
	jr ule, RecordReadOK_Block6

RecordReadOK_Block7:
	stdi16 59887, 384
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, RecordReadOK_LoadReg2
	ldw hl, 0xffff
	jrl FileIO_Epilogue

RecordReadOK_LoadReg2:
	ld a, l
	extz wa
	stda16 59889, xwa
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, RecordReadOK_LoadReg3
	ldw hl, 0xffff
	jrl FileIO_Epilogue

RecordReadOK_LoadReg3:
	ld a, l
	add a, 0x1d
	ldb w, 0x0
	extz xwa
	stda32 59883, xwa
	lds iz, 0
	cps iz, 1
	jr ugt, RecordReadOK_CheckDRAM

RecordReadOK_Block8:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, RecordReadOK_NextIter2
	ldw hl, 0xffff
	jrl FileIO_Epilogue

RecordReadOK_NextIter2:
	inc 1, iz
	cps iz, 1
	jr ule, RecordReadOK_Block8

RecordReadOK_CheckDRAM:
	cpdi8 59876, 3
	jr nz, RecordReadOK_InitVal6
	ld xwa, (xsp + 2)
	cp xwa, 0xc
	jr ule, RecordReadOK_InitVal6
	lds iz, 0
	cp iz, 0xc
	jr nc, RecordReadOK_Block9

RecordReadOK_LoopBody5:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, RecordReadOK_LoopCheck5
	ldw hl, 0xffff
	jrl FileIO_Epilogue

RecordReadOK_LoopCheck5:
	inc 1, iz
	cp iz, 0xc
	jr c, RecordReadOK_LoopBody5

RecordReadOK_Block9:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, RecordReadOK_LoadReg4
	ldw hl, 0xffff
	jrl FileIO_Epilogue

RecordReadOK_LoadReg4:
	ld a, l
	add a, 0x1d
	ldb w, 0x0
	extz xwa
	stda32 59883, xwa
	lds iz, 0
	jr RecordReadOK_LoopCheck6

RecordReadOK_LoopBody6:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, RecordReadOK_NextIter3
	ldw hl, 0xffff
	jrl FileIO_Epilogue

RecordReadOK_NextIter3:
	inc 1, iz

RecordReadOK_LoopCheck6:
	ld xwa, (xsp + 2)
	sub xwa, 0xd
	ld bc, iz
	extz xbc
	cp xbc, xwa
	jr c, RecordReadOK_LoopBody6
	jr RecordReadOK_Block10

RecordReadOK_InitVal6:
	lds iz, 0
	ld wa, iz
	extz xwa
	cp xwa, (xsp + 2)
	jr nc, RecordReadOK_Block10

RecordReadOK_LoopBody7:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, RecordReadOK_LoopCheck7
	ldw hl, 0xffff
	jr FileIO_Epilogue

RecordReadOK_LoopCheck7:
	inc 1, iz
	ld wa, iz
	extz xwa
	cp xwa, (xsp + 2)
	jr c, RecordReadOK_LoopBody7

RecordReadOK_Block10:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, RecordReadOK_Compare
	ldw hl, 0xffff
	jr FileIO_Epilogue

RecordReadOK_Compare:
	cp l, 0xf1
	jr z, RecordReadOK_Block11
	ldw hl, 0xfffe
	jr FileIO_Epilogue

RecordReadOK_Block11:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, RecordReadOK_Block12
	ldw hl, 0xffff
	jr FileIO_Epilogue

RecordReadOK_Block12:
	ldada xde, 59883
	ld xbc, 0x28
	ldda32 xwa, 59883
	cp xwa, 0x28
	jr ule, RecordReadOK_LoadReg5
	ldda32 xbc, 59883

RecordReadOK_LoadReg5:
	ld (xde), xbc
	ldada xde, 59883
	ld xbc, 0x12c
	ldda32 xwa, 59883
	cp xwa, 0x12c
	jr nc, RecordReadOK_LoadReg6
	ldda32 xbc, 59883

RecordReadOK_LoadReg6:
	ld (xde), xbc
	ldda32 xwa, 59883
	ld bc, wa
	lds32 xwa, 4
	lds de, 3
	call SoundParam_NotifyChange
	call SeqTimer_UpdateTempoReg
	lds32 xwa, 0
	stda32 59879, xwa
	lds hl, 0

FileIO_Epilogue:
	popw iz
	lda xsp, (xsp + 14)
	ret

Epilogue_Prologue:
	pushw iz
	calr MIDI_ResetAllChannels
	lds wa, 2
	calr SoundParam_InitDefaultBanks
	lds32 xwa, 4
	call SndParam_LookupReadOnly
	ld wa, hl
	exts xwa
	set 15, wa
	stda16 4597, xwa
	pushw 0x2
	lds wa, 0
	lds bc, 0
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	lds wa, 0
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	lds wa, 0
	lds bc, 7
	ldw de, 0x78
	call SndParam_NotifyAndReturn
	pushw 0x2
	lds wa, 1
	lds bc, 0
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	lds wa, 1
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	lds wa, 1
	lds bc, 7
	ldw de, 0x78
	call SndParam_NotifyAndReturn
	ldw wa, 0x63
	ldw bc, 0x14
	call SysEx_ApplyAndReloadPreset
	stdi8 64660, 80
	lds iz, 0
	cp iz, 0x8
	jr ge, Epilogue_InitVal

Epilogue_LoadReg:
	ld bc, iz
	ldada xwa, 64654
	ld_srib3 A, 0x07, 0xe0, 0xf8
	extz wa
	pushw 0xff
	ld de, wa
	ldw wa, 0x63
	call AssswbWr
	inc 1, iz
	cp iz, 0x8
	jr lt, Epilogue_LoadReg

Epilogue_InitVal:
	lds iz, 0
	cp iz, 0x10
	jr ge, Epilogue_Block

Epilogue_LoadIter:
	ld wa, iz
	pushw 0x2
	ldw bc, 0x80
	lds de, 3
	call SndParam_NotifyAndReturn
	inc 1, iz
	cp iz, 0x10
	jr lt, Epilogue_LoadIter

Epilogue_Block:
	lds32 xwa, 0
	stda32 60413, xwa
	stdi16 60417, 0
	lds hl, 0
	popw iz
	ret

Epilogue_Prologue2:
	pushw iz
	calr MIDI_ResetAllChannels
	lds wa, 2
	calr SoundParam_InitDefaultBanks
	lds32 xwa, 4
	call SndParam_LookupReadOnly
	ld wa, hl
	exts xwa
	set 15, wa
	stda16 4597, xwa
	pushw 0x2
	lds wa, 0
	lds bc, 0
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	lds wa, 0
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	lds wa, 1
	lds bc, 0
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	lds wa, 1
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	lds wa, 2
	lds bc, 0
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	lds wa, 2
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	lds wa, 3
	lds bc, 0
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	lds wa, 3
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	lds wa, 4
	lds bc, 0
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	lds wa, 4
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	lds wa, 5
	lds bc, 0
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	lds wa, 5
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	lds wa, 6
	lds bc, 0
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	lds wa, 6
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	lds wa, 7
	lds bc, 0
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	lds wa, 7
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0x8
	lds bc, 0
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0x8
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0x9
	lds bc, 0
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0x9
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xa
	lds bc, 0
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xa
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xb
	lds bc, 0
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xb
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xc
	lds bc, 0
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xc
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xd
	lds bc, 0
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xd
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xe
	lds bc, 0
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xe
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xf
	lds bc, 0
	ldw de, 0xf0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xf
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	ldw wa, 0x63
	ldw bc, 0x14
	call SysEx_ApplyAndReloadPreset
	stdi8 64660, 80
	lds iz, 0
	cp iz, 0x8
	jr ge, Epilogue_InitVal2

Epilogue_LoadReg2:
	ld bc, iz
	ldada xwa, 64654
	ld_srib3 A, 0x07, 0xe0, 0xf8
	extz wa
	pushw 0xff
	ld de, wa
	ldw wa, 0x63
	call AssswbWr
	inc 1, iz
	cp iz, 0x8
	jr lt, Epilogue_LoadReg2

Epilogue_InitVal2:
	lds iz, 0
	cp iz, 0x10
	jr ge, Epilogue_InitVal3

Epilogue_LoadIter2:
	ld wa, iz
	pushw 0x2
	ldw bc, 0x80
	lds de, 3
	call SndParam_NotifyAndReturn
	inc 1, iz
	cp iz, 0x10
	jr lt, Epilogue_LoadIter2

Epilogue_InitVal3:
	lds hl, 0
	popw iz
	ret

; MIDI system message handler
MidiSysMsg_Handler:
	lda xsp, (xsp - 10)
	push xiz
	ld c, a
	and c, 0xf0
	cp c, 0xf0
	jrl nz, Dispatch_LoadParam
	extz wa
	sub wa, 0xf0
	cps wa, 0
	jrl lt, Dispatch_InitVal2
	cp wa, 0xf
	jrl gt, Dispatch_InitVal2
	add wa, wa
	lda_24 xix, 0xeec1e8
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, MidiSysMsg_Dispatch
	jp_dri 8, 0x07, 0xf0, 0xe0

; MIDI system message dispatch (15-entry, table 0xeec1e8)
MidiSysMsg_Dispatch:
	calr	2375
	ld	wa, hl
	cps	wa, 0
	jr	ge, 6
	ldw	hl, 65535
	jrl	336
	cp	l, 247
	jr	nz, -20
	jrl	326
	lds	iz, 0
	cps	iz, 1
	jrl	ge, 319
	calr	2345
	cps	hl, 0
	jr	ge, 6
	ldw	hl, 65535
	jrl	308
	inc	1, iz
	cps	iz, 1
	jr	lt, -19
	jrl	297
	ldw	hl, 65533
	jrl	293
	lds	iz, 0
	cps	iz, 1
	jr	ge, 29
	calr	2311
	ld	wa, hl
	cps	wa, 0
	jr	ge, 6
	ldw	hl, 65535
	jrl	272
	lda	xwa, (xsp+4)
	st_rrb	l, xwa, iz
	inc	1, iz
	cps	iz, 1
	jr	lt, -29
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ldw	wa, 243
	calr	252
	adddm32	59879, xhl
	jrl	238
	lds	iz, 0
	cps	iz, 2
	jr	ge, 29
	calr	2258
	ld	wa, hl
	cps	wa, 0
	jr	ge, 6
	ldw	hl, 65535
	jrl	219
	lda	xwa, (xsp+4)
	st_rrb	l, xwa, iz
	inc	1, iz
	cps	iz, 2
	jr	lt, -29
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ldw	wa, 244
	calr	199
	adddm32	59879, xhl
	jrl	185
	lds	iz, 0
	cps	iz, 2
	jrl	ge, 178
	calr	2204
	cps	hl, 0
	jr	ge, 6
	ldw	hl, 65535
	jrl	167
	inc	1, iz
	cps	iz, 2
	jr	lt, -19
	jrl	156
	lds	iz, 0
	cps	iz, 2
	jr	ge, 29
	calr	2176
	ld	wa, hl
	cps	wa, 0
	jr	ge, 6
	ldw	hl, 65535
	jrl	137
	lda	xwa, (xsp+4)
	st_rrb	l, xwa, iz
	inc	1, iz
	cps	iz, 2
	jr	lt, -29
	lda	xwa, (xsp+4)
	calr	186
	jr	113
	lds	iz, 0
	cps	iz, 2
	jr	ge, 107
	calr	2133
	cps	hl, 0
	jr	ge, 5
	ldw	hl, 65535
	jr	97
	inc	1, iz
	cps	iz, 2
	jr	lt, -18
	jr	87
	calr	2113
	ld	wa, hl
	cps	wa, 0
	jr	ge, 5
	ldw	hl, 65535
	jr	75
	cp	l, 247
	jr	nz, -19
	jr	66

Dispatch_LoadParam:
	ld (xsp + 4), a
	and a, 0xf0
	cp a, 0xc0
	jr z, Dispatch_Block
	cp a, 0xd0
	jr nz, Dispatch_Block2

Dispatch_Block:
	ldi_werp 0xfa, 2
	jr Dispatch_InitVal

Dispatch_Block2:
	ldi_werp 0xfa, 3

Dispatch_InitVal:
	lds iz, 1
	cp_werp IZ, 0xfa
	jr ge, Dispatch_LoadAddr2

Dispatch_Block3:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, Dispatch_LoadAddr
	ldw hl, 0xffff
	jr Dispatch_Epilogue

Dispatch_LoadAddr:
	lda xwa, (xsp + 4)
	lda_dri3 XSP, 0x07, 0xe0, 0xf8
	inc 1, iz
	cp_werp IZ, 0xfa
	jr lt, Dispatch_Block3

Dispatch_LoadAddr2:
	lda xwa, (xsp + 4)
	calr Dispatch_Prologue

Dispatch_InitVal2:
	lds hl, 0

Dispatch_Epilogue:
	pop xiz
	lda xsp, (xsp + 10)
	ret

Dispatch_Data:
	cp	a, 244
	jr	z, 16
	cp	a, 243
	jr	nz, 51
	ld	l, (xbc)
	res	7, l
	ldb	h, 0
	extz	xhl
	jr	42
	ld	l, (xbc)
	res	7, l
	ld	e, (xbc+1)
	res	7, e
	ld	a, e
	sll	a, 7
	srl	e, 1
	or	l, a
	ld	c, l
	extz	bc
	ld	a, e
	extz	wa
	sla	wa, 8
	add	wa, bc
	ld	hl, wa
	exts	xhl
	jr	2
	lds32	xhl, 0
	ret
	push	xiz
	ldda32	xbc, 59883
	or	xbc, xbc
	jrl	z, 137
	ld	e, (xwa)
	ld	c, (xwa+1)
	ld	a, c
	srl	c, 1
	sll	a, 7
	res	7, e
	or	e, a
	ld	a, c
	extz	wa
	sla	wa, 8
	ld	iz, wa
	exts	xiz
	lds32	xwa, 0
	ld	a, e
	add	xiz, xwa
	ld	xwa, xiz
	ldda32	xbc, 59883
	call	Math_MultiplyAccumulate
	ld	xiz, xhl
	ld	xwa, xiz
	ld	xbc, 1000
	call	Math_DivideU32
	ld	xiz, xhl
	ld	xwa, 40
	cp	xiz, 40
	jr	ule, 2
	ld	xwa, xiz
	ld	xiz, xwa
	ld	xwa, 300
	cp	xiz, 300
	jr	nc, 2
	ld	xwa, xiz
	ld	xiz, xwa
	cp	xiz, 256
	jr	nc, 6
	.byte 0xf1
	jr	ule, -4
	.byte 0xb0
	jr	4
	.byte 0xf1
	jr	ule, -4
	.byte 0xb8
	ld	wa, iz
	ld	bc, wa
	lds32	xwa, 4
	lds	de, 3
	call	SoundParam_NotifyChange
	call	SeqTimer_UpdateTempoReg
	ld	xwa, xiz
	set	15, wa
	stda16	4597, wa
	pop	xiz
	ret

Dispatch_Prologue:
	lda xsp, (xsp - 10)
	push xiz
	ld xiz, xwa
	ld a, (xiz)
	and a, 0xf0
	cp a, 0x80
	jr z, ToneGen_CheckSpecialChannel
	cp a, 0x90
	jr z, ToneGen_CheckSpecialChannel
	cp a, 0xc0
	jrl nz, ToneGen_SendAndReturn
	ld a, (xiz + 1)
	extz wa
	lda xbc, (xsp + 12)
	lda xde, (xsp + 10)
	call SndParam_LookupFromPointerTable
	ld a, (xiz)
	and a, 0xf
	or a, 0xb0
	ld (xsp + 4), a
	ld (xsp + 5), 0x0
	ld a, (xsp + 12)
	ld (xsp + 6), a
	srl a, 7
	ld (xsp + 6), a
	lda xwa, (xsp + 4)
	ld xbc, xwa
	lds wa, 3
	calr MIDI_SendSinglePacket
	ld (xsp + 5), 0x20
	ld a, (xsp + 10)
	and a, 0x7
	sll a, 4
	ld (xsp + 6), a
	lda xwa, (xsp + 4)
	ld xbc, xwa
	lds wa, 3
	calr MIDI_SendSinglePacket
	ld a, (xiz)
	and a, 0xf
	or a, 0xc0
	ld (xsp + 4), a
	ld a, (xsp + 12)
	res 7, a
	ld (xsp + 5), a
	lda xwa, (xsp + 4)
	ld xbc, xwa
	lds wa, 2
	calr MIDI_SendSinglePacket
	jr ToneGen_PopIzStackReturn

ToneGen_CheckSpecialChannel:
	cpdi8 59876, 2
	jr nz, ToneGen_SendPacketDirect
	ld a, (xiz)
	and a, 0xf
	cp a, 0xe
	jr nz, ToneGen_SendPacketDirect
	ld a, (xiz + 1)
	extz wa
	pushw wa
	lds wa, 5
	ldw bc, 0xf0
	lds de, 0
	call SndParam_LookupByChannel
	ld (xiz + 1), l
	ld xbc, xiz
	lds wa, 3
	calr MIDI_SendSinglePacket
	jr ToneGen_CheckVelocityRepeat

ToneGen_SendPacketDirect:
	ld xbc, xiz
	lds wa, 3
	calr MIDI_SendSinglePacket

ToneGen_CheckVelocityRepeat:
	lds wa, 0
	cps wa, 0
	jr z, ToneGen_CheckZeroVelocity
	cp (xiz + 2), 0x0
	jr z, ToneGen_ResendPacket

ToneGen_CheckZeroVelocity:
	lds wa, 0
	cps wa, 0
	jr z, ToneGen_PopIzStackReturn

ToneGen_ResendPacket:
	ld xbc, xiz
	lds wa, 3
	calr MIDI_SendSinglePacket
	jr ToneGen_PopIzStackReturn

ToneGen_SendAndReturn:
	ld xbc, xiz
	lds wa, 3
	calr MIDI_SendSinglePacket

ToneGen_PopIzStackReturn:
	pop xiz
	lda xsp, (xsp + 10)
	ret

ToneGen_ReadFileRecord:
	push xiz
	stdi16 59887, 480
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, ToneGen_CheckRecordType
	ldw hl, 0xffff
	jr ToneGen_PopIzReturn

ToneGen_CheckRecordType:
	ld a, l
	cp a, 0xfe
	jr nz, ToneGen_SignExtendDelta
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, ToneGen_ReadExtendedDelta
	ldw hl, 0xffff
	jr ToneGen_PopIzReturn

ToneGen_ReadExtendedDelta:
	lds32 xiz, 0
	ldfr_berp L, 0xf8
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, ToneGen_ShiftAndAccumulate
	ldw hl, 0xffff
	jr ToneGen_PopIzReturn

ToneGen_ShiftAndAccumulate:
	ld a, l
	extz wa
	sla wa, 8
	exts xwa
	add xiz, xwa
	jr ToneGen_AccumulateDelta

ToneGen_SignExtendDelta:
	ld iz, hl
	exts xiz

ToneGen_AccumulateDelta:
	adddm32 59879, xiz
	lds hl, 0

ToneGen_PopIzReturn:
	pop xiz
	ret

ToneGen_ResetAndInitBanks:
	calr MIDI_ResetAllChannels
	stdi8 4330, 1
	lds wa, 1
	calr SoundParam_InitDefaultBanks
	stdi16 4597, 32888
	lds32 xwa, 4
	ldw bc, 0x76
	lds de, 3
	call SoundParam_NotifyChange
	call SeqTimer_UpdateTempoReg
	pushw 0x2
	lds wa, 0
	lds bc, 0
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	lds wa, 0
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	lds wa, 0
	lds bc, 7
	ldw de, 0x7f
	call SndParam_NotifyAndReturn
	lds hl, 0
	ret

MidiRealtime_ReadAndProcess:
	lda xsp, (xsp - 128)
	pushw iz
	lds iz, 0
	lds iz, 0
	ldda16 xbc, 59877
	bit 4, bc
	jr z, MidiRealtime_DispatchStatus
	ldw hl, 0xfffd
	jrl MidiRealtime_ProcessByte

MidiRealtime_DispatchStatus:
	ld c, a
	cp c, 0xf0
	jr z, MidiRealtime_SysExStart
	cp c, 0xfc
	jrl nz, MidiRealtime_NonSysExHandler
	ordi16 59877, 16
	jrl MidiRealtime_StopAndReturn

MidiRealtime_SysExStart:
	lds iz, 1
	lda xbc, (xsp + 1)
	lda_dri3 XBC, 0x07, 0xe4, 0xf8

MidiRealtime_SysExReadLoop:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, MidiRealtime_SysExCheckEnd
	ldw hl, 0xffff
	jrl MidiRealtime_ProcessByte

MidiRealtime_SysExCheckEnd:
	inc 1, iz
	cp iz, 0x80
	jr ge, MidiRealtime_SysExCheckF7
	lda xwa, (xsp + 1)
	ld c, l
	lda_dri3 XHL, 0x07, 0xe0, 0xf8

MidiRealtime_SysExCheckF7:
	cp hl, 0xf7
	jr nz, MidiRealtime_SysExReadLoop
	cp iz, 0x80
	jr gt, MidiRealtime_SysExOverflow
	ld de, iz
	lda xwa, (xsp + 2)
	ld xbc, xwa
	ld wa, de
	calr MIDI_SendSinglePacket

MidiRealtime_SysExOverflow:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, MidiRealtime_SysExOv_LoadReg
	ldw hl, 0xffff
	jrl MidiRealtime_ProcessByte

MidiRealtime_SysExOv_LoadReg:
	ld a, l
	cp a, 0xfe
	jr nz, MidiRealtime_SysExOv_LoadReg3
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, MidiRealtime_SysExOv_LoadReg2
	ldw hl, 0xffff
	jrl MidiRealtime_ProcessByte

MidiRealtime_SysExOv_LoadReg2:
	ld iz, hl
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, MidiRealtime_SysExOv_Block
	ldw hl, 0xffff
	jr MidiRealtime_ProcessByte

MidiRealtime_SysExOv_Block:
	sla hl, 8
	add iz, hl
	jr MidiRealtime_SysExOv_LoadIter

MidiRealtime_SysExOv_LoadReg3:
	ld iz, hl

MidiRealtime_SysExOv_LoadIter:
	ld wa, iz
	extz xwa
	adddm32 59879, xwa
	jr MidiRealtime_StopAndReturn

MidiRealtime_NonSysExHandler:
	extz wa
	calr VoiceReset_Return_Prologue
	ld wa, hl
	cps wa, 0
	jr lt, MidiRealtime_ProcessByte
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, MidiRealtime_NonSysE_CheckEnd
	ldw hl, 0xffff
	jr MidiRealtime_ProcessByte

MidiRealtime_NonSysE_CheckEnd:
	cp l, 0xff
	jr nz, MidiRealtime_NonSysE_LoadReg
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, MidiRealtime_NonSysE_LoadReg
	ldw hl, 0xffff
	jr MidiRealtime_ProcessByte

MidiRealtime_NonSysE_LoadReg:
	ld a, l
	cp a, 0xfe
	jr nz, MidiRealtime_NonSysE_LoadReg3
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, MidiRealtime_NonSysE_LoadReg2
	ldw hl, 0xffff
	jr MidiRealtime_ProcessByte

MidiRealtime_NonSysE_LoadReg2:
	ld iz, hl
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, MidiRealtime_NonSysE_Block
	ldw hl, 0xffff
	jr MidiRealtime_ProcessByte

MidiRealtime_NonSysE_Block:
	sla hl, 8
	add iz, hl
	jr MidiRealtime_NonSysE_LoadIter

MidiRealtime_NonSysE_LoadReg3:
	ld iz, hl

MidiRealtime_NonSysE_LoadIter:
	ld wa, iz
	extz xwa
	adddm32 59879, xwa

MidiRealtime_StopAndReturn:
	lds hl, 0

MidiRealtime_ProcessByte:
	popw iz
	st_dri3b L, 0xfd, 0x80, 0x00
	ret

MidiRealtime_Process_Prologue:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xwa

ToneGen_ProcessMidiConverge:
	ldda32 xwa, 60413
	cp xwa, (xsp + 2)
	jrl ugt, VoiceReset_Return_RestoreReg
	cpdi16 60417, 0
	jr z, ProcessMidiConverge_Block
	ldada xwa, 60419
	ld xbc, xwa
	ldda16 xwa, 60417
	calr MIDI_SendSinglePacket

ProcessMidiConverge_Block:
	calr RingBuffer_ReadByte
	ld wa, hl
	cps wa, 0
	jrl lt, ToneGen_VoiceReset_Return
	lds32 xwa, 0
	ld a, l
	and xwa, 0xff
	stda32 60413, xwa
	calr RingBuffer_ReadByte
	ld wa, hl
	cps wa, 0
	jrl lt, ToneGen_VoiceReset_Return
	lds32 xwa, 0
	ld a, l
	sll xwa, 8
	and xwa, 0xff00
	adddm32 60413, xwa
	calr RingBuffer_ReadByte
	ld wa, hl
	cps wa, 0
	jrl lt, ToneGen_VoiceReset_Return
	lds32 xwa, 0
	ld a, l
	sll xwa, 0
	and xwa, 0xff0000
	adddm32 60413, xwa
	calr RingBuffer_ReadByte
	ld wa, hl
	cps wa, 0
	jrl lt, ToneGen_VoiceReset_Return
	lds32 xwa, 0
	ld a, l
	sll xwa, 8
	sll xwa, 0
	and xwa, 0xff000000
	adddm32 60413, xwa
	calr RingBuffer_ReadByte
	ld wa, hl
	cps wa, 0
	jrl lt, ToneGen_VoiceReset_Return
	lds iz, 0
	ld wa, iz
	ldada xbc, 60419
	ld de, wa
	extz xde
	add xde, xbc
	ld a, l
	ld (xde), a
	ld a, l
	and a, 0xf0
	cp a, 0xc0
	jr z, ProcessMidiConverge_Block2
	cp a, 0xd0
	jr nz, ProcessMidiConverge_Block3

ProcessMidiConverge_Block2:
	stdi16 60417, 2
	jr ProcessMidiConverge_InitVal

ProcessMidiConverge_Block3:
	stdi16 60417, 3

ProcessMidiConverge_InitVal:
	lds iz, 1
	jr ProcessMidiConverge_LoopCheck

ProcessMidiConverge_LoopBody:
	calr RingBuffer_ReadByte
	ld wa, hl
	cps wa, 0
	jr lt, ProcessMidiConverge_LoadDRAM
	ld wa, iz
	ldada xbc, 60419
	extz xwa
	add xwa, xbc
	ld (xwa), l
	inc 1, iz

ProcessMidiConverge_LoopCheck:
	cpda16 xiz, 60417
	jr c, ProcessMidiConverge_LoopBody

ProcessMidiConverge_LoadDRAM:
	ldda8 a, 60419
	and a, 0xf0
	cp a, 0x90
	jr nz, ToneGen_ValidateRange_Loop
	cpdi8 60421, 0
	jr z, ToneGen_ValidateRange_Loop
	ldda8 a, 60421
	extz wa
	mul wa, 0x4b
	extz xwa
	div wa, 0x64
	add wa, 0x20
	stda8 60421, a
	cpdi8 60421, 127
	jr ule, ToneGen_ValidateRange_Loop
	stdi8 60421, 127

ToneGen_ValidateRange_Loop:
	ldda8 a, 60419
	and a, 0xf0
	cp a, 0xb0
	jrl nz, ToneGen_ProcessMidiConverge
	cpdi8 60420, 7
	jrl nz, ToneGen_ProcessMidiConverge
	stdi8 60421, 127
	jrl ToneGen_ProcessMidiConverge

ToneGen_VoiceReset_Return:
	stdi16 60417, 0
	lds32 xwa, 0
	stda32 60413, xwa

VoiceReset_Return_RestoreReg:
	popw iz
	inc 4, xsp
	ret

VoiceReset_Return_Prologue:
	lda xsp, (xsp - 10)
	push xiz
	bit 7, a
	jr z, VoiceReset_Return_Block
	stda8 53406, a
	ld (xsp + 4), a
	lds iz, 1
	jr VoiceReset_Return_LoadDRAM

VoiceReset_Return_Block:
	ldmi16 (xsp + 4), 0xd09e
	ld (xsp + 5), a
	lds iz, 2

VoiceReset_Return_LoadDRAM:
	ldda8 a, 53406
	and a, 0xf0
	cp a, 0xc0
	jr z, VoiceReset_Return_Block2
	cp a, 0xd0
	jr nz, VoiceReset_Return_Block3

VoiceReset_Return_Block2:
	ldi_werp 0xfa, 2
	jr VoiceReset_Return_Block4

VoiceReset_Return_Block3:
	ldi_werp 0xfa, 3

VoiceReset_Return_Block4:
	cp_werp IZ, 0xfa
	jr nc, VoiceReset_Return_LoadParam

VoiceReset_Return_LoopBody:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, VoiceReset_Return_LoopCheck
	ldw hl, 0xffff
	jrl VoiceReset_Return_Epilogue

VoiceReset_Return_LoopCheck:
	ld wa, iz
	extz xwa
	lda xbc, (xsp + 4)
	add xbc, xwa
	ld (xbc), l
	inc 1, iz
	cp_werp IZ, 0xfa
	jr c, VoiceReset_Return_LoopBody

VoiceReset_Return_LoadParam:
	ld a, (xsp + 4)
	and a, 0xf
	jrl nz, VoiceReset_Return_LoadAddr
	lds iz, 4
	ldto_werp WA, 0xfa
	inc 4, wa
	cp iz, wa
	jr nc, VoiceReset_Return_LoadDRAM2

VoiceReset_Return_LoadIter:
	ld wa, iz
	extz xwa
	lda xbc, (xsp + 4)
	ld xde, xbc
	add xde, xwa
	ld wa, iz
	dec 4, wa
	extz xwa
	lda xbc, (xsp + 4)
	add xbc, xwa
	ld a, (xbc)
	ld (xde), a
	inc 1, iz
	ldto_werp WA, 0xfa
	inc 4, wa
	cp iz, wa
	jr c, VoiceReset_Return_LoadIter

VoiceReset_Return_LoadDRAM2:
	ldda16 xwa, 59877
	ldda16 xbc, 59887
	calr PlayModeStateMachine_Prologue
	add xhl, 0x3a
	ld xwa, xhl
	ld (xsp + 4), a
	ld xwa, xhl
	srl xwa, 8
	ld (xsp + 5), a
	ld xwa, xhl
	srl xwa, 0
	ld (xsp + 6), a
	srl xhl, 8
	srl xhl, 0
	ld a, l
	ld (xsp + 7), a
	inc4_werp 0xfa
	lds iz, 0
	cp_werp IZ, 0xfa
	jr nc, VoiceReset_Return_InitVal

VoiceReset_Return_LoadIter2:
	ld wa, iz
	extz xwa
	lda xbc, (xsp + 4)
	add xbc, xwa
	ld a, (xbc)
	extz wa
	calr InitTrackSlots_Block
	inc 1, iz
	cp_werp IZ, 0xfa
	jr c, VoiceReset_Return_LoadIter2
	jr VoiceReset_Return_InitVal

VoiceReset_Return_LoadAddr:
	lda xwa, (xsp + 4)
	ld xbc, xwa
	ldto_werp WA, 0xfa
	calr MIDI_SendSinglePacket

VoiceReset_Return_InitVal:
	lds hl, 0

VoiceReset_Return_Epilogue:
	pop xiz
	lda xsp, (xsp + 10)
	ret

SoundParam_InitDefaultBanks:
	lda xsp, (xsp - 96)
	pushw iz
	ld xiy, 0xeec208
	lda xix, (xsp + 82)
	ldw bc, 0x8
	ldirw
	ld xiy, 0xeec218
	lda xix, (xsp + 66)
	ldw bc, 0x8
	ldirw
	ld xiy, 0xeec228
	lda xix, (xsp + 50)
	ldw bc, 0x8
	ldirw
	ld xiy, 0xeec238
	lda xix, (xsp + 34)
	ldw bc, 0x8
	ldirw
	ld xiy, 0xeec248
	lda xix, (xsp + 18)
	ldw bc, 0x8
	ldirw
	ld xiy, 0xeec258
	lda xix, (xsp + 2)
	ldw bc, 0x8
	ldirw
	cps a, 2
	jrl z, SoundParam_InitDefau_Block2
	cps a, 1
	jr z, SoundParam_InitDefau_Block
	cps a, 0
	jrl nz, ToneGen_NotifyChangeComplete_Return
	stdi8 4330, 1
	ld xwa, 0xc1
	lds bc, 0
	lds de, 1
	call SoundParam_NotifyChange
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	setda 2, 64941
	ld xwa, 0xc0
	lds bc, 0
	lds de, 1
	call SoundParam_NotifyChange
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	lds iz, 0
	cp iz, 0x10
	jrl ge, ToneGen_NotifyChangeComplete_Return

SoundParam_InitDefau_LoadReg:
	ld de, iz
	lda xwa, (xsp + 82)
	ld_srib3 A, 0x07, 0xe0, 0xf8
	ld c, a
	extz bc
	pushw 0x2
	ld wa, de
	ld de, bc
	ldw bc, 0x401
	call SndParam_NotifyAndReturn
	ldada xbc, 61856
	lda xwa, (xsp + 66)
	ld_srib3 A, 0x07, 0xe0, 0xf8
	lda_dri3 XBC, 0x07, 0xe4, 0xf8
	inc 1, iz
	cp iz, 0x10
	jr lt, SoundParam_InitDefau_LoadReg
	jrl ToneGen_NotifyChangeComplete_Return

SoundParam_InitDefau_Block:
	stdi8 4330, 1
	ld xwa, 0xc1
	lds bc, 0
	lds de, 1
	call SoundParam_NotifyChange
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	resda 2, 64941
	ld xwa, 0xc0
	lds bc, 1
	lds de, 1
	call SoundParam_NotifyChange
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	lds iz, 0
	cp iz, 0x10
	jrl ge, ToneGen_NotifyChangeComplete_Return

SoundParam_InitDefau_LoadReg2:
	ld de, iz
	lda xwa, (xsp + 50)
	ld_srib3 A, 0x07, 0xe0, 0xf8
	ld c, a
	extz bc
	pushw 0x2
	ld wa, de
	ld de, bc
	ldw bc, 0x401
	call SndParam_NotifyAndReturn
	ldada xbc, 61856
	lda xwa, (xsp + 34)
	ld_srib3 A, 0x07, 0xe0, 0xf8
	lda_dri3 XBC, 0x07, 0xe4, 0xf8
	inc 1, iz
	cp iz, 0x10
	jr lt, SoundParam_InitDefau_LoadReg2
	jrl ToneGen_NotifyChangeComplete_Return

SoundParam_InitDefau_Block2:
	stdi8 4330, 1
	ld xwa, 0xc0
	lds bc, 0
	lds de, 1
	call SoundParam_NotifyChange
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	resda 0, 64941
	ld xwa, 0xc1
	lds bc, 1
	lds de, 1
	call SoundParam_NotifyChange
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	lds iz, 0
	cp iz, 0x10
	jr ge, SoundParam_InitDefau_LoadReg4

SoundParam_InitDefau_LoadReg3:
	ld de, iz
	lda xwa, (xsp + 18)
	ld_srib3 A, 0x07, 0xe0, 0xf8
	ld c, a
	extz bc
	pushw 0x2
	ld wa, de
	ld de, bc
	ldw bc, 0x401
	call SndParam_NotifyAndReturn
	ldada xbc, 61856
	lda xwa, (xsp + 2)
	ld_srib3 A, 0x07, 0xe0, 0xf8
	lda_dri3 XBC, 0x07, 0xe4, 0xf8
	inc 1, iz
	cp iz, 0x10
	jr lt, SoundParam_InitDefau_LoadReg3

SoundParam_InitDefau_LoadReg4:
	ld xwa, 0x2201
	lds bc, 1
	lds de, 2
	call SoundParam_NotifyChange
	ld xwa, 0x2205
	lds bc, 1
	lds de, 2
	call SoundParam_NotifyChange

ToneGen_NotifyChangeComplete_Return:
	popw iz
	lda xsp, (xsp + 96)
	ret

NotifyChangeComplete_Prologue:
	lda xsp, (xsp - 32)
	ld xiy, 0xeec268
	ld xix, xsp
	ldw bc, 0x10
	ldirw
	ldda8 c, 59876
	cps c, 4
	jr z, NotifyChangeComplete_DoGetCurre
	cps c, 3
	jr z, NotifyChangeComplete_Prologue2
	cps c, 2
	jr z, NotifyChangeComplete_Prologue2
	cps c, 1
	jr nz, NotifyChangeComplete_SetWord

NotifyChangeComplete_Prologue2:
	push xwa
	lda xwa, (xsp + 4)
	push xwa
	call Strcat
	inc 8, xsp
	lda xwa, (xsp)
	call SndTable_LookupA
	jr ToneGen_RestoreStackReturn

NotifyChangeComplete_DoGetCurre:
	call GetCurrentFileIndexAlt
	ld wa, hl
	cps wa, 0
	jr lt, ToneGen_RestoreStackReturn
	ld wa, hl
	call SndTable_LookupD
	jr ToneGen_RestoreStackReturn

NotifyChangeComplete_SetWord:
	ldw hl, 0xffff

ToneGen_RestoreStackReturn:
	lda xsp, (xsp + 32)
	ret

; ============================================================================
; FileIO_ReadNextRecord - Read next record from file (state machine)
; ============================================================================
; Dispatches on state variable DRAM[59876] (values 1-4).
; Returns: HL = 0 (success), 0xffff (error)
; Used for sequential file record reading during disk operations.
; ============================================================================
FileIO_ReadNextRecord:
	ldda8 a, 59876
	cps a, 4
	jr z, ReadNextRecord_DoLookupB
	cps a, 3
	jr z, ReadNextRecord_DoReadNext
	cps a, 2
	jr z, ReadNextRecord_DoReadNext
	cps a, 1
	jr nz, ReadNextRecord_SetWord
	calr Seq_CalcAddrOffset
	cp hl, 0x780
	jr lt, ReadNextRecord_Block2
	jr ReadNextRecord_Block3

ReadNextRecord_Block:
	calr Seq_CalcAddrOffset
	cp hl, 0x780
	jr ge, ReadNextRecord_Block3

ReadNextRecord_Block2:
	calr SongFile_DecodeMidiEvent
	cps hl, 0
	jr z, ReadNextRecord_Block

ReadNextRecord_Block3:
	calr RingBuffer_ReadByte
	cp hl, 0xfffd
	ret nz
	lds hl, 0
	jr SndParam_DirectReturn

ReadNextRecord_DoReadNext:
	call TaskBuf_ReadNextByte
	jr SndParam_DirectReturn

ReadNextRecord_DoLookupB:
	call SndTable_LookupB
	jr SndParam_DirectReturn

ReadNextRecord_SetWord:
	ldw hl, 0xffff

SndParam_DirectReturn:
	ret

DirectReturn_LoadDRAM:
	ldda8 a, 59876
	cps a, 4
	jr z, DirectReturn_DoLookupC
	cps a, 3
	jr z, DirectReturn_DoDrainQue
	cps a, 2
	jr z, DirectReturn_DoDrainQue
	cps a, 1
	jr nz, SndParam_StoreAndReturn
	call FDC_DrainQueuesAndReset
	calr FileIO_InitTrackSlots
	jr SndParam_StoreAndReturn

DirectReturn_DoDrainQue:
	call FDC_DrainQueuesAndReset
	jr SndParam_StoreAndReturn

DirectReturn_DoLookupC:
	call SndTable_LookupC
	calr FileIO_InitTrackSlots

SndParam_StoreAndReturn:
	stdi16 4597, 120
	ret

StoreAndReturn_Block:
	stdi8 59876, 0
	lds32 xwa, 0
	stda32 59879, xwa
	lds32 xwa, 0
	stda32 59893, xwa
	stdi16 59877, 0
	lds32 xwa, 0
	stda32 59883, xwa
	stdi16 59887, 0
	stdi16 59889, 0
	lds32 xwa, 0
	stda32 60413, xwa
	stdi16 60417, 0
	stdi8 59844, 0
	calr FileIO_InitTrackSlots
	calr SysexRingBuf_Init
	jrl MidiRingBuf_Init

FileIO_InitTrackSlots:
	stdi16 53416, 0
	stdi16 53418, 0
	stdi16 53420, 2047
	lds de, 0
	jr InitTrackSlots_LoopCheck

InitTrackSlots_LoopBody:
	ld wa, de
	inc 6, wa
	ldada xbc, 53416
	stib_dri 0x07, 0xe4, 0xe0, 0x00
	inc 1, de

InitTrackSlots_LoopCheck:
	ld wa, de
	cpda16 xwa, 53420
	jr c, InitTrackSlots_LoopBody
	ret

InitTrackSlots_Block:
	cpdi16 53420, 0
	jr nz, InitTrackSlots_LoadDRAM
	ldw hl, 0xffff
	jr InitTrackSlots_Return

InitTrackSlots_LoadDRAM:
	ldda16 xbc, 53416
	ldada xde, 53422
	extz xbc
	add xbc, xde
	ld (xbc), a
	decdi16 1, 53420
	cpdi16 53416, 2047
	jr nz, InitTrackSlots_IncDRAM
	stdi16 53416, 0
	jr InitTrackSlots_InitVal

InitTrackSlots_IncDRAM:
	incdi16 1, 53416

InitTrackSlots_InitVal:
	lds hl, 0

InitTrackSlots_Return:
	ret

RingBuffer_ReadByte:
	ldda16 xwa, 53416
	cpda16 xwa, 53418
	jr nz, RingBuffer_ReadByte_LoadDRAM
	ldw hl, 0xffff
	jr RingBuffer_ReadByte_Return

RingBuffer_ReadByte_LoadDRAM:
	ldda16 xwa, 53418
	ldada xbc, 53422
	extz xwa
	add xwa, xbc
	ld l, (xwa)
	extz hl
	incdi16 1, 53420
	cpdi16 53418, 2047
	jr nz, RingBuffer_ReadByte_IncDRAM
	stdi16 53418, 0
	jr RingBuffer_ReadByte_Return

RingBuffer_ReadByte_IncDRAM:
	incdi16 1, 53418

RingBuffer_ReadByte_Return:
	ret

Seq_CalcAddrOffset:
	ldw hl, 0x7ff
	subda16 xhl, 53420
	ret

CalcAddrOffset_Data:
	dec	6, xsp
	pushw	iz
	ld	(xsp+2), xbc
	ld	(xsp+6), wa
	lds	iz, 0
	ld	wa, iz
	.byte 0x9f, 0x06, 0xf0
	jr	nc, 31
	calr	65451
	ld	wa, hl
	cps	wa, 0
	jr	ge, 5
	ldw	hl, 65535
	jr	19
	ld	xwa, (xsp+2)
	.byte 0xf3
	reti
	.byte 0xe0
	swi	0
	ld	xsp, 2296275422
	.byte 0x9f, 0x06, 0xf0
	jr	c, -31
	lds	hl, 0
	popw	iz
	inc	6, xsp
	ret

MidiRingBuf_WriteBytes:
	dec 6, xsp
	pushw iz
	ld (xsp + 4), xbc
	ld iz, wa
	cps iz, 0
	jr nz, WriteBytes_Block
	lds hl, 0
	jr SndParam_PopStackReturn

WriteBytes_Block:
	cpda16 xiz, 53420
	jr ule, WriteBytes_Block2
	ldw hl, 0xffff
	jr SndParam_PopStackReturn

WriteBytes_Block2:
	cpdm16 53420, xiz
	jr ule, SndParam_NotifyError
	ldw (xsp + 2), 0x0
	lds wa, 0
	cp wa, iz
	jr nc, SndParam_NotifySuccess

SndParam_NotifyLoop_Body:
	ld xbc, (xsp + 4)
	ld wa, (xsp + 2)
	ld_srib3 A, 0x07, 0xe4, 0xe0
	extz wa
	calr InitTrackSlots_Block
	incm 1, (xsp + 2)
	ld wa, (xsp + 2)
	cp wa, iz
	jr c, SndParam_NotifyLoop_Body

SndParam_NotifySuccess:
	lds hl, 0
	jr SndParam_PopStackReturn

SndParam_NotifyError:
	ldw hl, 0xffff

SndParam_PopStackReturn:
	popw iz
	inc 6, xsp
	ret

SysexRingBuf_Init:
	stdi16 55470, 0
	stdi16 55472, 0
	stdi16 55474, 2047
	lds de, 0
	jr SysexRingBuf_ClearCheck

SysexRingBuf_ClearLoop:
	ld wa, de
	inc 6, wa
	ldada xbc, 55470
	stib_dri 0x07, 0xe4, 0xe0, 0x00
	inc 1, de

SysexRingBuf_ClearCheck:
	ld wa, de
	cpda16 xwa, 55474
	jr c, SysexRingBuf_ClearLoop
	ret

SysexRingBuf_WriteByte:
	cpdi16 55474, 0
	jr nz, SysexRingBuf_StoreAndAdvance
	ldw hl, 0xffff
	jr SysexRingBuf_WriteReturn

SysexRingBuf_StoreAndAdvance:
	ldda16 xbc, 55470
	ldada xde, 55476
	extz xbc
	add xbc, xde
	ld (xbc), a
	decdi16 1, 55474
	cpdi16 55470, 2047
	jr nz, SysexRingBuf_IncrementWrite
	stdi16 55470, 0
	jr SysexRingBuf_WriteSuccess

SysexRingBuf_IncrementWrite:
	incdi16 1, 55470

SysexRingBuf_WriteSuccess:
	lds hl, 0

SysexRingBuf_WriteReturn:
	ret

SysexRingBuf_ReadByte:
	ldda16 xwa, 55470
	cpda16 xwa, 55472
	jr nz, SysexRingBuf_ReadAndAdvance
	ldw hl, 0xffff
	jr SysexRingBuf_ReadReturn

SysexRingBuf_ReadAndAdvance:
	ldda16 xwa, 55472
	ldada xbc, 55476
	extz xwa
	add xwa, xbc
	ld l, (xwa)
	extz hl
	incdi16 1, 55474
	cpdi16 55472, 2047
	jr nz, SysexRingBuf_IncrementRead
	stdi16 55472, 0
	jr SysexRingBuf_ReadReturn

SysexRingBuf_IncrementRead:
	incdi16 1, 55472

SysexRingBuf_ReadReturn:
	ret

SysexRingBuf_GetFreeSpace:
	ldw hl, 0x7ff
	subda16 xhl, 55474
	ret

SysexRingBuf_ReadBytes:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld (xsp + 6), wa
	lds iz, 0
	ld wa, iz
	cp wa, (xsp + 6)
	jr nc, SysexRingBuf_ReadBytesOK

SysexRingBuf_ReadBytesLoop:
	calr SysexRingBuf_ReadByte
	ld wa, hl
	cps wa, 0
	jr ge, SysexRingBuf_ReadBytesStore
	ldw hl, 0xffff
	jr SysexRingBuf_ReadBytesReturn

SysexRingBuf_ReadBytesStore:
	ld xwa, (xsp + 2)
	lda_dri3 XSP, 0x07, 0xe0, 0xf8
	inc 1, iz
	ld wa, iz
	cp wa, (xsp + 6)
	jr c, SysexRingBuf_ReadBytesLoop

SysexRingBuf_ReadBytesOK:
	lds hl, 0

SysexRingBuf_ReadBytesReturn:
	popw iz
	inc 6, xsp
	ret

SysexRingBuf_WriteBytes:
	dec 6, xsp
	pushw iz
	ld (xsp + 4), xbc
	ld iz, wa
	cps iz, 0
	jr nz, SysexRingBuf_WriteNonZero
	lds hl, 0
	jr SysexRingBuf_WriteBytesReturn

SysexRingBuf_WriteNonZero:
	cpda16 xiz, 55474
	call_24 ugt, 0xfee1a9
	ldw (xsp + 2), 0x0
	lds wa, 0
	cp wa, iz
	jr nc, SysexRingBuf_WriteBytesOK

SysexRingBuf_WriteBytesLoop:
	ld xbc, (xsp + 4)
	ld wa, (xsp + 2)
	ld_srib3 A, 0x07, 0xe4, 0xe0
	extz wa
	calr SysexRingBuf_WriteByte
	incm 1, (xsp + 2)
	ld wa, (xsp + 2)
	cp wa, iz
	jr c, SysexRingBuf_WriteBytesLoop

SysexRingBuf_WriteBytesOK:
	lds hl, 0

SysexRingBuf_WriteBytesReturn:
	popw iz
	inc 6, xsp
	ret

MidiRingBuf_Init:
	stdi16 57524, 0
	stdi16 57526, 0
	stdi16 57528, 127
	lds de, 0
	jr MidiRingBuf_ClearCheck

MidiRingBuf_ClearLoop:
	ld wa, de
	inc 6, wa
	ldada xbc, 57524
	stib_dri 0x07, 0xe4, 0xe0, 0x00
	inc 1, de

MidiRingBuf_ClearCheck:
	ld wa, de
	cpda16 xwa, 57528
	jr c, MidiRingBuf_ClearLoop
	ret

MidiRingBuf_WriteByte:
	cpdi16 57528, 0
	jr nz, MidiRingBuf_StoreAndAdvance
	ldw hl, 0xffff
	jr StoreAndAdvance_Return

MidiRingBuf_StoreAndAdvance:
	ldda16 xbc, 57524
	ldada xde, 57530
	extz xbc
	add xbc, xde
	ld (xbc), a
	decdi16 1, 57528
	cpdi16 57524, 127
	jr nz, StoreAndAdvance_IncDRAM
	stdi16 57524, 0
	jr StoreAndAdvance_InitVal

StoreAndAdvance_IncDRAM:
	incdi16 1, 57524

StoreAndAdvance_InitVal:
	lds hl, 0

StoreAndAdvance_Return:
	ret

StoreAndAdvance_LoadDRAM:
	ldda16 xwa, 57524
	cpda16 xwa, 57526
	jr nz, StoreAndAdvance_LoadDRAM2
	ldw hl, 0xffff
	jr StoreAndAdvance_Return2

StoreAndAdvance_LoadDRAM2:
	ldda16 xwa, 57526
	ldada xbc, 57530
	extz xwa
	add xwa, xbc
	ld l, (xwa)
	extz hl
	incdi16 1, 57528
	cpdi16 57526, 127
	jr nz, StoreAndAdvance_IncDRAM2
	stdi16 57526, 0
	jr StoreAndAdvance_Return2

StoreAndAdvance_IncDRAM2:
	incdi16 1, 57526

StoreAndAdvance_Return2:
	ret

StoreAndAdvance_Prologue:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld (xsp + 6), wa
	lds iz, 0
	ld wa, iz
	cp wa, (xsp + 6)
	jr nc, StoreAndAdvance_InitVal2

StoreAndAdvance_LoopBody:
	calr StoreAndAdvance_LoadDRAM
	ld wa, hl
	cps wa, 0
	jr ge, StoreAndAdvance_LoopCheck
	ldw hl, 0xffff
	jr StoreAndAdvance_RestoreReg

StoreAndAdvance_LoopCheck:
	ld xwa, (xsp + 2)
	lda_dri3 XSP, 0x07, 0xe0, 0xf8
	inc 1, iz
	ld wa, iz
	cp wa, (xsp + 6)
	jr c, StoreAndAdvance_LoopBody

StoreAndAdvance_InitVal2:
	lds hl, 0

StoreAndAdvance_RestoreReg:
	popw iz
	inc 6, xsp
	ret

StoreAndAdvance_Prologue2:
	dec 6, xsp
	pushw iz
	ld (xsp + 4), xbc
	ld iz, wa
	cps iz, 0
	jr nz, StoreAndAdvance_Block
	lds hl, 0
	jr StoreAndAdvance_RestoreReg2

StoreAndAdvance_Block:
	cpda16 xiz, 57528
	call_24 ugt, 0xfee2c9
	ldw (xsp + 2), 0x0
	lds wa, 0
	cp wa, iz
	jr nc, StoreAndAdvance_InitVal3

StoreAndAdvance_LoadParam:
	ld xbc, (xsp + 4)
	ld wa, (xsp + 2)
	ld_srib3 A, 0x07, 0xe4, 0xe0
	extz wa
	calr MidiRingBuf_WriteByte
	incm 1, (xsp + 2)
	ld wa, (xsp + 2)
	cp wa, iz
	jr c, StoreAndAdvance_LoadParam

StoreAndAdvance_InitVal3:
	lds hl, 0

StoreAndAdvance_RestoreReg2:
	popw iz
	inc 6, xsp
	ret

StoreAndAdvance_Prologue3:
	pushw	iz
	lds	iz, 0
	call	TaskBuf_ReadNextByte
	ld	iz, hl
	cps	iz, 0
	jr	ge, 3
	nop
	jr	1
	nop
	ld	hl, iz
	popw	iz
	ret

CharMap_NullPreamble_0:
	ret

CharMap_NullPreamble_1:
	ret

CharMap_NullPreamble_2:
	ret

CharMap_ActivePreamble:
	stdi8 57658, 0
	stdi8 57659, 1
	ld xde, 0xe13a
	lds wa, 5
	lds bc, 2
	jp sendCOMM
CharMap_ActivePreamb_LoadDRAM:
	ldda8	a, 49277
	cps	a, 0
	ret	nz
	ldda8	a, 49279
	and	a, 15
	ret	z
	stdi8	57668, 1
	ldda8	a, 49278
	and	a, 15
	stda8	57669, a
	ld	xde, 57668
	lds	wa, 5
	lds	bc, 2
	call	sendCOMM
	ret

CharMap_ActivePreamb_Prologue:
	dec 4, xsp
	ld (xsp), c
	ld (xsp + 2), a
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	ld c, (xsp)
	extz bc
	cps hl, 1
	jr nz, CharMap_ActivePreamb_Extend
	ld xwa, 0x48
	cp (xsp + 2), 0xf
	jr nz, CharMap_ActivePreamb_LoadDRAM2
	ld xwa, 0x4c

CharMap_ActivePreamb_LoadDRAM2:
	ldda32 xde, 57678
	add xde, xwa
	extz xbc
	add xbc, (xde)
	ld l, (xbc)
	jr CharMap_ActivePreamb_Increment

CharMap_ActivePreamb_Extend:
	extz xbc
	cp (xsp + 2), 0xf
	jr nz, CharMap_ActivePreamb_Compare
	ld xwa, 0x40
	jr CharMap_ActivePreamb_LoadDRAM3

CharMap_ActivePreamb_Compare:
	cp (xsp + 2), 0x14
	jr nz, CharMap_ActivePreamb_LoadDRAM4
	ld xwa, 0x44

CharMap_ActivePreamb_LoadDRAM3:
	ldda32 xde, 57678
	add xde, xwa
	add xbc, (xde)
	ld l, (xbc)
	jr CharMap_ActivePreamb_Increment

CharMap_ActivePreamb_LoadDRAM4:
	ldda32 xwa, 57678
	add xbc, (xwa + 60)
	ld l, (xbc)

CharMap_ActivePreamb_Increment:
	inc 4, xsp
	ret

CharMap_ActivePreamb_Prologue2:
	dec 2, xsp
	ld (xsp), a
	call GetCurrentPartSelect
	extz hl
	ld c, (xsp)
	extz bc
	ld wa, hl
	calr CharMap_ActivePreamb_Prologue
	inc 2, xsp
	ret

SndParam_ApplyMaskClamp:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xiz, xwa
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cps hl, 1
	jrl z, SndParam_PopIzSkip4Ret
	ld xwa, (xsp + 4)
	cp (xwa), 0x78
	jr z, SndParam_PopIzSkip4Ret
	cp (xiz), 0x7f
	jr ugt, ApplyMaskClamp_LoadParam
	ld xwa, (xsp + 4)
	andmi8 (xwa), 0x7
	jr SndParam_PopIzSkip4Ret

ApplyMaskClamp_LoadParam:
	ld xwa, (xsp + 4)
	cp (xwa), 0x7
	jr nz, ApplyMaskClamp_Compare
	resm 7, (xiz)
	ldb c, 0x70
	jr SndParam_StoreResult_Return

ApplyMaskClamp_Compare:
	cp (xiz), 0xef
	jr ugt, ApplyMaskClamp_LoadParam3
	ld xwa, (xsp + 4)
	cp (xwa), 0x0
	jr nz, ApplyMaskClamp_LoadParam2
	resm 7, (xiz)
	ldb c, 0x10
	jr SndParam_StoreResult_Return

ApplyMaskClamp_LoadParam2:
	ld xwa, (xsp + 4)
	cp (xwa), 0x5
	jr nz, ApplyMaskClamp_LoadReg
	resm 7, (xiz)
	ldb c, 0x15
	jr SndParam_StoreResult_Return

ApplyMaskClamp_LoadParam3:
	ld xwa, (xsp + 4)
	cp (xwa), 0x1
	jr ugt, ApplyMaskClamp_LoadParam4
	andmi8 (xiz), 0xf
	ld c, (xwa)
	and c, 0x1
	set 6, c
	ld (xwa), c
	jr SndParam_PopIzSkip4Ret

ApplyMaskClamp_LoadParam4:
	ld xwa, (xsp + 4)
	cp (xwa), 0x6
	jr nz, ApplyMaskClamp_LoadParam5
	ld (xiz), 0x0
	ldb c, 0x50
	jr SndParam_StoreResult_Return

ApplyMaskClamp_LoadParam5:
	ld xwa, (xsp + 4)
	cp (xwa), 0x5
	jr nz, ApplyMaskClamp_LoadReg
	andmi8 (xiz), 0x3
	ldb c, 0x55
	jr SndParam_StoreResult_Return

ApplyMaskClamp_LoadReg:
	ld (xiz), 0x0
	ldb c, 0x0

SndParam_StoreResult_Return:
	ld xwa, (xsp + 4)
	ld (xwa), c

SndParam_PopIzSkip4Ret:
	pop xiz
	inc 4, xsp
	ret

SndParam_StoreDRAMInit:
	st_dri3b L, 0xfd, 0xd0, 0xfe
	pushw iz
	st_dri3w DE, 0xfd, 0x2c, 0x01
	st_dri3w BC, 0xfd, 0x2e, 0x01
	lda_dri3 XBC, 0xfd, 0x30, 0x01
	ld (xsp + 6), 0xff
	lds32 xwa, 0
	ld (xsp + 2), xwa
	jr StoreDRAMInit_Block2

StoreDRAMInit_ReadBuf:
	call SeqBuf_VoiceMap_ReadByte
	cp hl, 0xffff
	jr z, StoreDRAMInit_Block
	lda xwa, (xsp + 12)
	ld (xsp + 8), xwa
	lds32 xwa, 1
	add (xsp + 8), xwa
	lds iz, 0

StoreDRAMInit_ReadBuf2:
	call SeqBuf_VoiceMap_ReadByte
	ld xwa, (xsp + 8)
	lda_dpi XSP, 0xe0
	ld (xsp + 8), xwa
	inc 1, iz
	cps iz, 7
	jr c, StoreDRAMInit_ReadBuf2
	lda xbc, (xsp + 12)
	ld a, (xbc + 7)
	cp_srib_rm A, 0xfd, 0x30, 0x01
	jr nz, StoreDRAMInit_Block
	ld (xbc), 0x0
	lds iz, 0
	cp_sriw_im 0xfd, 0x2e, 0x01, 0x00, 0x00
	jr ule, StoreDRAMInit_LoadParam

StoreDRAMInit_ReadBuf3:
	call SeqBuf_VoiceMap_ReadByte
	ld_sril XWA, (xsp + 0x0136)
	lda_dpi XSP, 0xe0
	st_dri3l XWA, 0xfd, 0x36, 0x01
	inc 1, iz
	cp_sriw_rm IZ, 0xfd, 0x2e, 0x01
	jr c, StoreDRAMInit_ReadBuf3

StoreDRAMInit_LoadParam:
	ld (xsp + 6), 0x0
	jr StoreDRAMInit_LoadParam2

StoreDRAMInit_Block:
	lds32 xwa, 1
	add (xsp + 2), xwa
	ld xwa, (xsp + 2)
	cp xwa, 0xe00
	jr ge, StoreDRAMInit_LoadParam2

StoreDRAMInit_Block2:
	ld_sriw WA, (xsp + 0x012c)
	extz xwa
	cp (xsp + 2), xwa
	jrl lt, StoreDRAMInit_ReadBuf

StoreDRAMInit_LoadParam2:
	ld l, (xsp + 6)
	popw iz
	st_dri3b L, 0xfd, 0x30, 0x01
	retd 0x4

StoreDRAMInit_LoadDRAM:
	ldda32 xhl, 57678
	ld xde, (xhl + 4)
	dec 1, xde
	lds32 xix, 0
	ldfr_berp A, 0xf0
	cp xix, xde
	jr ugt, StoreDRAMInit_Block4
	ld xhl, (xhl)
	extz wa
	sll wa, 4
	extz xwa
	add xhl, xwa
	ld xde, xbc
	lda xbc, (xbc + 16)

StoreDRAMInit_Block3:
	ld_spib A, 0xec
	lda_dpi XBC, 0xe8
	cp xde, xbc
	jr c, StoreDRAMInit_Block3
	ret

StoreDRAMInit_Block4:
	lda_24 xwa, 0xeed298
	ld xde, xwa
	lda xhl, (xwa + 16)

StoreDRAMInit_Block5:
	ld_spib A, 0xe8
	lda_dpi XBC, 0xe4
	cp xde, xhl
	jr c, StoreDRAMInit_Block5
	ret

SndParam_ApplyProgramChangeAsync:
	dec 8, xsp
	push_werp 0xfa
	ld (xsp + 2), xde
	ld (xsp + 6), c
	ld (xsp + 8), a
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 6)
	calr SndParam_ApplyMaskClamp
	lds wa, 5
	call TaskSched_WaitForEvent
	ld a, (xsp + 8)
	extz wa
	ld c, (xsp + 6)
	extz bc
	call Param_SignExtendRetu_Block3
	extz hl
	ld xbc, (xsp + 2)
	push xbc
	ld wa, hl
	ldw bc, 0x11
	ldw de, 0xe00
	calr SndParam_StoreDRAMInit
	ldfr_berp L, 0xfb
	lds wa, 5
	call TaskSched_SignalEvent
	cpi_berp 0xfb, 0
	jr z, ApplyProgramChangeAs_RestoreReg
	lda_24 xwa, 0xeed2a8
	ld xbc, xwa
	ld xde, (xsp + 2)
	lda xhl, (xwa + 17)

ApplyProgramChangeAs_Block:
	ld_spib A, 0xe4
	lda_dpi XBC, 0xe8
	cp xbc, xhl
	jr c, ApplyProgramChangeAs_Block

ApplyProgramChangeAs_RestoreReg:
	pop_werp 0xfa
	inc 8, xsp
	ret

ApplyProgramChangeAs_Prologue:
	dec 6, xsp
	push_werp 0xfa
	ld (xsp + 4), c
	ld (xsp + 6), a
	lda xwa, (xsp + 6)
	lda xbc, (xsp + 4)
	calr SndParam_ApplyMaskClamp
	lds wa, 5
	call TaskSched_WaitForEvent
	ld a, (xsp + 6)
	extz wa
	ld c, (xsp + 4)
	extz bc
	call Param_SignExtendRetu_Block4
	extz hl
	lda xbc, (xsp + 2)
	push xbc
	ld wa, hl
	lds bc, 1
	ldw de, 0xe00
	calr SndParam_StoreDRAMInit
	ldfr_berp L, 0xfb
	lds wa, 5
	call TaskSched_SignalEvent
	cpi_berp 0xfb, 0
	jr z, ApplyProgramChangeAs_ClearByte
	ld (xsp + 2), 0x0
	jr ApplyProgramChangeAs_LoadParam2

ApplyProgramChangeAs_ClearByte:
	ldb a, 0x0
	bitm 7, (xsp + 2)
	jr z, ApplyProgramChangeAs_LoadParam
	ldb a, 0x7f

ApplyProgramChangeAs_LoadParam:
	ld (xsp + 2), a

ApplyProgramChangeAs_LoadParam2:
	ld l, (xsp + 2)
	pop_werp 0xfa
	inc 6, xsp
	ret

ApplyProgramChangeAs_Prologue2:
	dec 8, xsp
	push_werp 0xfa
	ld (xsp + 2), xde
	ld (xsp + 6), c
	ld (xsp + 8), a
	lds wa, 5
	call TaskSched_WaitForEvent
	ld a, (xsp + 8)
	extz wa
	ld c, (xsp + 6)
	extz bc
	call Param_SignExtendRetu_Block5
	extz hl
	ld xbc, (xsp + 2)
	push xbc
	ld wa, hl
	ldw bc, 0xa
	ldw de, 0xe00
	calr SndParam_StoreDRAMInit
	ldfr_berp L, 0xfb
	lds wa, 5
	call TaskSched_SignalEvent
	cpi_berp 0xfb, 0
	jr z, ApplyProgramChangeAs_RestoreReg2
	lda_24 xwa, 0xeed2b9
	ld xbc, xwa
	ld xde, (xsp + 2)
	lda xhl, (xwa + 10)

ApplyProgramChangeAs_Block2:
	ld_spib A, 0xe4
	lda_dpi XBC, 0xe8
	cp xbc, xhl
	jr c, ApplyProgramChangeAs_Block2

ApplyProgramChangeAs_RestoreReg2:
	pop_werp 0xfa
	inc 8, xsp
	ret

ApplyProgramChangeAs_DoLookupRe:
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cps hl, 1
	jr nz, ApplyProgramChangeAs_LoadDRAM
	call GetCurrentPartSelect
	cp l, 0xf
	jr z, ApplyProgramChangeAs_SetByte
	ldb l, 0x80
	jr ApplyProgramChangeAs_Return

ApplyProgramChangeAs_SetByte:
	ldb l, 0x89
	jr ApplyProgramChangeAs_Return

ApplyProgramChangeAs_LoadDRAM:
	ldda32 xwa, 57678
	ld xwa, (xwa + 4)
	ld l, a

ApplyProgramChangeAs_Return:
	ret

ApplyProgramChangeAs_LoadDRAM2:
	ldda32 xhl, 57678
	add xhl, xbc
	ld xix, (xhl)
	ld c, (xwa + 4)
	extz bc
	extz xbc
	ld xhl, xix
	add xhl, xbc
	ld c, (xhl)
	extz bc
	mul xbc, xde
	ld xde, xix
	add xde, 0x80
	add xde, xbc
	ld c, (xwa + 3)
	extz bc
	sll bc, 2
	ld hl, bc
	extz xhl
	add xhl, xde
	ld bc, (xhl)
	ld (xwa), c
	ld bc, (xhl + 2)
	ld (xwa + 1), c
	ret

ApplyProgramChangeAs_LoadReg:
	ld xbc, 0x10
	ldw de, 0x400
	jr ApplyProgramChangeAs_LoadDRAM2

ApplyProgramChangeAs_LoadReg2:
	ld xbc, 0x20
	ldw de, 0x200
	jr ApplyProgramChangeAs_LoadDRAM2
	jr ApplyProgramChangeAs_LoadReg

SndParam_FetchOscTableEntry:
	push xiz
	ld xiz, xwa
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cps hl, 1
	jr nz, FetchOscTableEntry_LoadIter
	ld xwa, xiz
	calr ApplyProgramChangeAs_LoadReg2
	jr FetchOscTableEntry_Epilogue

FetchOscTableEntry_LoadIter:
	ld xwa, xiz
	calr ApplyProgramChangeAs_LoadReg

FetchOscTableEntry_Epilogue:
	pop xiz
	ret

FetchOscTableEntry_Prologue:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xiz, xwa
	calr ApplyProgramChangeAs_DoLookupRe
	ldda32 xbc, 57678
	ld xwa, (xbc + 8)
	ld e, a
	cp (xiz), l
	jr nc, FetchOscTableEntry_ClearByte
	ld w, (xiz)
	jr FetchOscTableEntry_ClearByte2

FetchOscTableEntry_ClearByte:
	ldb w, 0x0

FetchOscTableEntry_ClearByte2:
	ldb l, 0x0
	ld a, (xiz + 1)
	cp a, e
	jr nc, FetchOscTableEntry_Compute
	ld l, a

FetchOscTableEntry_Compute:
	add xbc, (xsp + 4)
	ld xix, (xbc)
	ld c, w
	mul8rr c, e
	extz hl
	add hl, bc
	add hl, hl
	extz xhl
	add xix, xhl
	ld a, (xix)
	ld (xiz + 3), a
	ld a, (xix + 1)
	ld (xiz + 4), a
	pop xiz
	inc 4, xsp
	ret

FetchOscTableEntry_LoadReg:
	ld xbc, 0x14
	jr FetchOscTableEntry_Prologue

FetchOscTableEntry_LoadReg2:
	ld xbc, 0x24
	jr FetchOscTableEntry_Prologue

SndParam_ApplyProgramChange:
	push xiz
	ld xiz, xwa
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cps hl, 1
	jr nz, ApplyProgramChange_LoadIter
	ld xwa, xiz
	calr FetchOscTableEntry_LoadReg2
	jr ApplyProgramChange_Epilogue

ApplyProgramChange_LoadIter:
	ld xwa, xiz
	calr FetchOscTableEntry_LoadReg

ApplyProgramChange_Epilogue:
	pop xiz
	ret

ApplyProgramChange_LoadDRAM:
	ldda32 xhl, 57678
	add xhl, xbc
	ld xix, (xhl)
	ld c, (xwa + 4)
	extz bc
	extz xbc
	ld xhl, xix
	add xhl, xbc
	ld c, (xhl)
	extz bc
	mul xbc, xde
	ld xde, xix
	add xde, 0x80
	add xde, xbc
	ld c, (xwa + 3)
	extz bc
	sll bc, 2
	ld hl, bc
	extz xhl
	add xhl, xde
	ld (xwa), 0x0
	ld bc, (xhl)
	ld (xwa + 2), c
	ld bc, (xhl + 2)
	ld (xwa + 1), c
	ret

ApplyProgramChange_LoadReg:
	ld xbc, 0x18
	ldw de, 0x400
	jr ApplyProgramChange_LoadDRAM

SndParam_InitBufferConverge:
	ld xbc, 0x28
	ldw de, 0x200
	jr ApplyProgramChange_LoadDRAM

SndParam_ComputeVoiceIndex:
	push xiz
	ld xiz, xwa
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cps hl, 1
	jr nz, ComputeVoiceIndex_LoadIter
	ld xwa, xiz
	calr SndParam_InitBufferConverge
	jr ComputeVoiceIndex_Epilogue

ComputeVoiceIndex_LoadIter:
	ld xwa, xiz
	calr ApplyProgramChange_LoadReg

ComputeVoiceIndex_Epilogue:
	pop xiz
	ret

SndParam_LookupOscEnvelope:
	push xiz
	ld xiz, xwa
	ld a, (xiz + 5)
	cp a, 0xf
	jr z, LookupOscEnvelope_LoadDRAM2
	extz wa
	lds bc, 0
	call SndParam_LookupViaEncode
	lda xbc, (xiz + 2)
	cp hl, 0xf0
	jr lt, LookupOscEnvelope_LoadDRAM
	ldda32 xwa, 57678
	ld xhl, (xwa + 48)
	jr LookupOscEnvelope_LoadReg2

LookupOscEnvelope_LoadDRAM:
	ldda32 xwa, 57678
	ld xde, (xwa + 28)
	lds32 xwa, 0
	ld a, (xbc)
	sll xwa, 2
	add xde, xwa
	ld xhl, (xde)
	ld c, (xiz + 1)
	lda xde, (xhl + 2)
	jr LookupOscEnvelope_LoadReg

LookupOscEnvelope_Increment:
	inc 3, xhl
	inc 3, xde

LookupOscEnvelope_LoadReg:
	ld a, (xde)
	cp c, a
	jr nc, LookupOscEnvelope_Increment
	cp a, 0xff
	jr nz, LookupOscEnvelope_Increment
	jr LookupOscEnvelope_LoadReg3

LookupOscEnvelope_LoadDRAM2:
	ldda32 xwa, 57678
	ld xhl, (xwa + 48)
	lda xbc, (xiz + 2)

LookupOscEnvelope_LoadReg2:
	ld a, (xbc)
	sll a, 1
	extz wa
	st_dri3b C, 0x07, 0xec, 0xe0

LookupOscEnvelope_LoadReg3:
	ld a, (xhl)
	ld (xiz + 3), a
	ld a, (xhl + 1)
	ld (xiz + 4), a
	pop xiz
	ret

SndParam_ApplyVoiceValue:
	push xiz
	ld xiz, xwa
	ld a, (xiz + 5)
	cp a, 0xf
	jr z, SndParam_SetDefaultKeyOff
	extz wa
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	lda xbc, (xiz + 4)
	ld a, (xiz + 2)
	ld (xiz + 3), a
	cp hl, 0x78
	jr nz, SndParam_StoreNoteValue
	ld (xbc), 0x78
	jr SndParam_ApplyReturn

SndParam_StoreNoteValue:
	ld a, (xiz + 1)
	ld (xbc), a
	jr SndParam_ApplyReturn

SndParam_SetDefaultKeyOff:
	ld a, (xiz + 2)
	ld (xiz + 3), a
	ld (xiz + 4), 0x78

SndParam_ApplyReturn:
	pop xiz
	ret

SndParam_CheckAndApplyMode:
	push	xiz
	ld	xiz, xwa
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cps	hl, 1
	jr	nz, 7
	ld	xwa, xiz
	calr	65456
	jr	5
	ld	xwa, xiz
	calr	65334
	pop	xiz
	ret

SndParam_LookupFromPointerTable:
	ldda32 xix, 57678
	add xix, 0x38
	ld xiy, (xix)
	ld l, a
	add l, a
	extz hl
	extz xhl
	add xiy, xhl
	ld a, (xiy)
	ld (xbc), a
	ld a, (xiy + 1)
	ld (xde), a
	ld xiy, (xix)
	add xiy, xhl
	ld a, (xiy)
	ld (xbc), a
	ld a, (xiy + 1)
	ld (xde), a
	ret

SndParam_LookupByPartAndNote:
	dec 6, xsp
	push xiz
	ld e, c
	ldda32 xbc, 57678
	ld xiz, (xbc + 52)
	lda xbc, (xsp + 4)
	ld (xbc + 3), a
	ld (xbc + 4), e
	ld xwa, xbc
	calr SndParam_ComputeVoiceIndex
	ld a, (xsp + 6)
	extz wa
	extz xwa
	add xwa, xiz
	ld l, (xwa)
	pop xiz
	inc 6, xsp
	ret

SndParam_CompactLookupStub:
	extz	wa
	lda_24	xbc, 15651654
	.byte 0xc3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 216
	ccf
	ld	l, a
	ret

SndParam_LookupAndDispatch:
	dec 6, xsp
	push_werp 0xfa
	ld (xsp + 4), c
	ld (xsp + 6), a
	ld (xsp + 2), 0xff
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cps hl, 1
	jr z, SndParam_ReturnResult
	cp (xsp + 4), 0x78
	jr nz, SndParam_ApplyMaskAndCheck
	ldda32 xwa, 57678
	ld xbc, (xwa + 48)
	ld a, (xsp + 6)
	extz wa
	add wa, wa
	extz xwa
	add xbc, xwa
	ld a, (xbc)
	ld (xsp + 6), a
	ld a, (xbc + 1)
	ld (xsp + 4), a

SndParam_ApplyMaskAndCheck:
	lda xwa, (xsp + 6)
	lda xbc, (xsp + 4)
	calr SndParam_ApplyMaskClamp
	cp (xsp + 4), 0x40
	jr z, SndParam_DispatchProcessParam
	cp (xsp + 4), 0x41
	jr z, SndParam_DispatchProcessParam
	cp (xsp + 4), 0x50
	jr z, SndParam_DispatchProcessParam
	cp (xsp + 4), 0x55
	jr nz, SndParam_ReturnResult

SndParam_DispatchProcessParam:
	lds wa, 5
	call TaskSched_WaitForEvent
	ld a, (xsp + 6)
	extz wa
	ld c, (xsp + 4)
	extz bc
	call SndParam_LookupPartIndex
	extz hl
	lda xbc, (xsp + 2)
	push xbc
	ld wa, hl
	lds bc, 1
	ldw de, 0xe00
	calr SndParam_StoreDRAMInit
	ldfr_berp L, 0xfb
	lds wa, 5
	call TaskSched_SignalEvent
	ldb a, 0x2
	cpi_berp 0xfb, 0
	jr nz, SndParam_StoreResult
	ld a, (xsp + 2)

SndParam_StoreResult:
	ld (xsp + 2), a

SndParam_ReturnResult:
	ld l, (xsp + 2)
	pop_werp 0xfa
	inc 6, xsp
	ret

SndParam_LookupByChannel:
	dec 2, xsp
	ld (xsp), a
	extz bc
	extz de
	ld wa, bc
	ld bc, de
	calr SndParam_LookupAndDispatch
	ld c, (xsp + 6)
	cp l, 0xff
	jr z, SndParam_LoadReturnByte
	ld a, (xsp)
	ld e, c
	extz de
	extz wa
	dec 1, wa
	cps wa, 0
	jr lt, SndParam_LoadReturnByte
	cps wa, 5
	jr gt, SndParam_LoadReturnByte
	add wa, wa
	lda_24 xix, 0xeed3c6
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, SndParam_TypeDispatch
	jp_dri 8, 0x07, 0xf0, 0xe0

; Sound parameter type dispatch (6-entry, table 0xeed3c6)
SndParam_TypeDispatch:
	extz hl
	muls hl, 0x18
	jr SndParam_LoadTableConverge

SndParam_TypeDispatch_Entry1:
	extz hl
	muls hl, 0x18
	inc 4, hl
	jr SndParam_LoadTableConverge

TypeDispatch_Entry1_Extend:
	extz hl
	muls hl, 0x18
	inc 8, hl
	jr SndParam_LoadTableConverge

TypeDispatch_Entry1_Extend2:
	extz hl
	muls hl, 0x18
	add hl, 0xc

SndParam_LoadTableConverge:
	ldada xde, 60433
	ld_sril3 XDE, 0x07, 0xe8, 0xec
	ldb b, 0x0
	extz xbc
	add xbc, xde
	ld l, (xbc)
	jr LoadReturnByte_Increment

LoadTableConverge_LoadReg:
	ld xwa, 0xeed198
	jr LoadTableConverge_LoadFromStack

LoadTableConverge_LoadReg2:
	ld xwa, 0xeed218

LoadTableConverge_LoadFromStack:
	ld_srib3 L, 0x07, 0xe0, 0xe8
	jr LoadReturnByte_Increment

SndParam_LoadReturnByte:
	ld l, c

LoadReturnByte_Increment:
	inc 2, xsp
	retd 0x2

; Sound parameter offset dispatch handler
SndParam_OffsetHandler:
	dec 4, xsp
	ld (xsp), e
	ld (xsp + 2), a
	extz bc
	ld wa, bc
	lds bc, 0
	calr SndParam_LookupAndDispatch
	cp l, 0xff
	jr z, LookupTableConverge_LoadParam
	ld e, (xsp + 2)
	ld c, (xsp)
	extz bc
	extz de
	dec 1, de
	cps de, 0
	jr lt, LookupTableConverge_LoadParam
	cps de, 5
	jr gt, LookupTableConverge_LoadParam
	add de, de
	lda_24 xix, 0xeed3d2
	ld_sriw3 DE, 0x07, 0xf0, 0xe8
	lda_24 xix, SndParam_OffsetDispatch
	jp_dri 8, 0x07, 0xf0, 0xe8

; Sound parameter offset dispatch (6-entry, table 0xeed3d2)
SndParam_OffsetDispatch:
	ldw bc, 0x10
	jr SndParam_LookupTableConverge

OffsetDispatch_SetWord:
	ldw bc, 0x14
	jr SndParam_LookupTableConverge

OffsetDispatch_SetWord2:
	ldw bc, 0x8
	jr SndParam_LookupTableConverge

OffsetDispatch_SetWord3:
	ldw bc, 0xc

SndParam_LookupTableConverge:
	extz hl
	muls hl, 0x18
	add hl, bc
	ldada xbc, 60433
	ld_sril3 XBC, 0x07, 0xe4, 0xec
	lds32 xwa, 0
	ld a, (xsp)
	add xwa, xbc
	ld l, (xwa)
	jr LookupTableConverge_Increment

LookupTableConverge_LoadReg:
	ld xwa, 0xeed198
	jr LookupTableConverge_LoadFromStack

LookupTableConverge_LoadReg2:
	ld xwa, 0xeed218

LookupTableConverge_LoadFromStack:
	ld_srib3 L, 0x07, 0xe0, 0xe4
	jr LookupTableConverge_Increment

LookupTableConverge_LoadParam:
	ld l, (xsp)

LookupTableConverge_Increment:
	inc 4, xsp
	ret

Param_SignExtendReturn:
	extz wa
	extz bc
	extz de
	jrl SndParam_OffsetHandler

Param_SignExtendRetu_Return:
	ret

Param_SignExtendRetu_Block:
	ld32_24 xwa, 0xe0239c
	stda32 57678, xwa
	ret

Param_SignExtendRetu_Block2:
	jr Param_SignExtendRetu_Block
	ld l, (xwa + 9)
	res 7, l
	ldb h, 0x0
	extz xhl
	sll xhl, 14
	ld e, (xwa + 10)
	res 7, e
	ldb d, 0x0
	extz xde
	sll xde, 7
	ld c, (xwa + 11)
	res 7, c
	ldb b, 0x0
	extz xbc
	or xhl, xde
	or xhl, xbc
	ret

Param_SignExtendRetu_Data:
	lds32	xhl, 0
	ld	l, (xwa+6)
	sll	xhl, 14
	ld	e, (xwa+7)
	res	7, e
	ldb	d, 0
	extz	xde
	sll	xde, 7
	ld	c, (xwa+8)
	res	7, c
	ldb	b, 0
	extz	xbc
	.byte 0xea
	xor	(xde+3811), xwa
	.byte 0x8b
	cpl	bc
	and	hl, bc
	retd	4
	dec	2, xsp
	ld	(xsp), c
	ld	xbc, xwa
	cp	xbc, 426
	jr	c, 64
	sub	xbc, 426
	ld	xwa, xbc
	ld	xbc, 11
	call	DivMod32
	cp	xhl, 9
	jrl	ugt, 411
	add	xhl, xhl
	add	xhl, 15652004
	ld	hl, (xhl)
	lda_24	xix, 16706692
	.byte 0xf3
	reti
	.byte 0xf0
	cps	xix, 0
	ld	a, (xsp)
	exts	wa
	pushw	127
	pushw	0
	ldw	bc, 65535
	lds	de, 0
	jrl	368
	cp	xbc, 102
	jrl	c, 167
	sub	xbc, 102
	ld	xwa, xbc
	ld	xbc, 81
	call	DivMod32
	cp	xhl, 76
	jrl	ugt, 338
	add	xhl, 15651913
	ld	hl, (xhl)
	extz	hl
	sll	hl, 1
	ld	xix, 15651990
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	c, 242
	sla	de, 254
	ldw	ix, 2035
	.byte 0xf0
	cps	xix, 0
	ld	a, (xsp)
	exts	wa
	pushw	50
	pushw	0
	ldw	bc, 65535
	lds	de, 0
	jrl	282
	ld	a, (xsp)
	exts	wa
	pushw	128
	pushw	0
	ldw	bc, 65535
	lds	de, 0
	jrl	264
	ld	a, (xsp)
	exts	wa
	pushw	127
	pushw	0
	ldw	bc, 65535
	lds	de, 0
	jrl	246
	ld	a, (xsp)
	exts	wa
	pushw	24
	pushw	65512
	ldw	bc, 65535
	lds	de, 0
	jrl	228
	ld	a, (xsp)
	exts	wa
	pushw	50
	pushw	65486
	ldw	bc, 65535
	lds	de, 0
	jrl	210
	ld	a, (xsp)
	exts	wa
	pushw	100
	pushw	0
	ldw	bc, 65535
	lds	de, 0
	jrl	192
	ld	xbc, xwa
	cp	xwa, 15
	jr	gt, 8
	cp	xwa, 0
	jr	ge, 57
	sub	xbc, 16
	cp	xbc, 0
	jrl	lt, 164
	cp	xbc, 76
	jrl	gt, 155
	add	xbc, 15651822
	ld	bc, (xbc)
	extz	bc
	sll	bc, 1
	ld	xix, 15651899
	.byte 0xd3
	reti
	.byte 0xf0, 0xe4
	ldb	a, 242
	or	(xbc), iy
	swi	6
	ldw	ix, 2035
	.byte 0xf0, 0xe4, 0xd8
	ld	a, (xsp)
	exts	wa
	pushw	127
	pushw	32
	ldw	bc, 65535
	lds	de, 0
	jr	100
	ld	a, (xsp)
	exts	wa
	pushw	66
	pushw	0
	ldw	bc, 65535
	lds	de, 0
	jr	83
	ld	a, (xsp)
	exts	wa
	pushw	49
	pushw	0
	ldw	bc, 127
	lds	de, 0
	jr	66
	ld	a, (xsp)
	exts	wa
	pushw	127
	pushw	0
	ldw	bc, 65535
	lds	de, 0
	jr	49
	ld	a, (xsp)
	exts	wa
	pushw	10
	pushw	6
	ldw	bc, 65535
	lds	de, 0
	jr	32
	ld	a, (xsp)
	exts	wa
	pushw	50
	pushw	0
	ldw	bc, 127
	lds	de, 0
	jr	15
	ld	a, (xsp)
	exts	wa
	pushw	30
	pushw	0
	ldw	bc, 63
	lds	de, 0
	calr	65078
	ld	(xsp), l
	ld	l, (xsp)
	inc	2, xsp
	ret
	dec	6, xsp
	push	xiz
	ld	(xsp+8), c
	ld	xiz, xwa
	ld	c, (xsp+8)
	exts	bc
	ld	(xsp+6), bc
	ld	(xsp+4), bc
	cp	xiz, 295
	jrl	c, 309
	ld	xwa, xiz
	sub	xwa, 295
	ld	xbc, 80
	call	Math_DivideU32
	ld	a, l
	extz	wa
	muls	wa, 80
	extz	xwa
	.byte 0xf3, 0xe1
	ldb	l, 1
	ldw	wa, 15032
	ldw	wa, 63208
	jr	c, 61
	ld	xbc, xiz
	sub	xbc, xwa
	ld	xwa, xbc
	ld	xbc, 11
	call	DivMod32
	cp	xhl, 9
	jrl	ugt, 371
	add	xhl, xhl
	add	xhl, 15652108
	ld	hl, (xhl)
	lda_24	xix, 16707199
	.byte 0xf3
	reti
	.byte 0xf0
	cps	xix, 0
	pushw	127
	pushw	0
	ld	wa, (xsp+10)
	ldw	bc, 65535
	lds	de, 0
	jrl	328
	extz	hl
	mul	hl, 80
	add	xhl, 295
	ld	xbc, xiz
	sub	xbc, xhl
	ld	xwa, xbc
	cp	xbc, 12
	jr	ugt, 8
	cp	xbc, 0
	jr	nc, 57
	sub	xwa, 13
	cp	xwa, 0
	jrl	c, 285
	cp	xwa, 40
	jrl	ugt, 276
	add	xwa, 15652053
	ld	wa, (xwa)
	extz	wa
	sll	wa, 1
	ld	xix, 15652094
	.byte 0xd3
	reti
	.byte 0xf0, 0xe0
	ldb	w, 242
	sll	xhl, 254
	ldw	ix, 2035
	.byte 0xf0, 0xe0
	divs	wa, 127
	pushw	32
	ld	wa, (xsp+8)
	ldw	bc, 65535
	lds	de, 0
	jrl	220
	pushw	127
	pushw	0
	ld	wa, (xsp+10)
	ldw	bc, 65535
	lds	de, 0
	jrl	203
	pushw	50
	pushw	0
	ld	wa, (xsp+10)
	ldw	bc, 65535
	lds	de, 0
	jrl	186
	pushw	128
	pushw	0
	ld	wa, (xsp+10)
	ldw	bc, 65535
	lds	de, 0
	jrl	169
	pushw	127
	pushw	0
	ld	wa, (xsp+10)
	ldw	bc, 65535
	lds	de, 0
	jrl	152
	pushw	50
	pushw	65486
	ld	wa, (xsp+10)
	ldw	bc, 65535
	lds	de, 0
	jrl	135
	pushw	100
	pushw	0
	ld	wa, (xsp+10)
	ldw	bc, 65535
	lds	de, 0
	jr	119
	ld	xbc, xwa
	cp	xwa, 15
	jr	gt, 8
	cp	xwa, 0
	jr	ge, 55
	sub	xbc, 16
	cp	xbc, 0
	jr	lt, 93
	cp	xbc, 22
	jr	gt, 85
	add	xbc, 15652024
	ld	bc, (xbc)
	extz	bc
	sll	bc, 1
	ld	xix, 15652047
	.byte 0xd3
	reti
	.byte 0xf0, 0xe4
	ldb	a, 242
	cp	(xde-17), xiz
	ldw	ix, 2035
	.byte 0xf0, 0xe4
	divs	wa, 127
	pushw	32
	ld	wa, (xsp+8)
	ldw	bc, 65535
	lds	de, 0
	jr	30
	pushw	49
	pushw	0
	ld	wa, (xsp+10)
	ldw	bc, 127
	lds	de, 0
	jr	14
	pushw	127
	pushw	0
	ld	wa, (xsp+10)
	ldw	bc, 65535
	lds	de, 0
	calr	64612
	ld	(xsp+8), l
	ld	l, (xsp+8)
	pop	xiz
	inc	6, xsp
	ret
	ret
	lda	xsp, (xsp-22)
	pushw	iz
	ld	(xsp+20), xwa
	ld	xwa, (xsp+20)
	calr	64511
	ld	(xsp+6), hl
	ld	xwa, (xsp+20)
	calr	64543
	.byte 0x9f, 0x06
	push	xsp
	nop
	nop
	jrl	z, 205
	.byte 0x9f, 0x06
	push	xsp
	jrl	29184
	.byte 0xc5
	nop
	or	xhl, xhl
	jrl	z, 192
	ld	xwa, xhl
	sra	xwa, 15
	sra	xwa, 0
	and	xwa, 16383
	add	xwa, xhl
	and	xwa, 4294950912
	ld	(xsp+2), xhl
	sub	(xsp+2), xwa
	ld	xbc, (xsp+2)
	ld	a, (xbc+16)
	and	a, 192
	cp	a, 192
	jrl	z, 154
	cp	a, 64
	jrl	z, 148
	cp	a, 128
	jr	z, 5
	cps	a, 0
	jrl	nz, 138
	cp	xbc, 470
	jr	ugt, 125
	ldada	xde, 57752
	ld	(xde), 45
	ld	xwa, (xsp+20)
	lda	xhl, (xwa+6)
	lda	xwa, (xde+1)
	ld	(xsp+12), xwa
	cps	iz, 6
	jr	nc, 13
	ld	xwa, (xsp+12)
	ld	c, (xhl)
	ld	(xwa), c
	inc	1, iz
	cps	iz, 6
	jr	c, -13
	ld	(xde+7), 0
	lda	xwa, (xde+8)
	ld	(xsp+16), xwa
	ld	(xsp+12), xwa
	ld	wa, (xsp+6)
	cp	iz, wa
	jr	nc, 46
	ld	xwa, (xsp+16)
	ld	c, (xwa+1)
	and	c, 15
	ld	xwa, (xsp+12)
	ld	a, (xwa)
	sll	a, 4
	or	a, c
	ld	c, a
	ld	xwa, (xsp+2)
	calr	64417
	ld	xwa, (xsp+16)
	ld	(xwa), l
	inc	1, iz
	lds32	xwa, 2
	add	(xsp+8), xwa
	ld	wa, (xsp+6)
	cp	iz, wa
	jr	c, -46
	ld	bc, (xsp+6)
	inc	8, bc
	lds	wa, 3
	ld	xde, 57752
	call	sendCOMM
	.byte 0xbf
	ccf
	push_sr
	nop
	nop
	jr	5
	.byte 0xbf
	ccf
	push_sr
	.byte 0x01
	nop
	ld	hl, (xsp+18)
	popw	iz
	lda	xsp, (xsp+22)
	ret
	ld	xde, xwa
	lda	xhl, (xde+12)
	ld	c, (xhl+1)
	and	c, 15
	ld	w, (xhl)
	sll	w, 4
	or	w, c
	ld	c, (xhl+4)
	and	c, 15
	ld	a, (xhl+3)
	sll	a, 4
	or	a, c
	cp	a, 16
	jr	z, 5
	cp	a, 17
	jr	nz, 11
	stda32	57747, xde
	lds	wa, 3
	ldw	bc, 21
	jr	23
	cp	a, 80
	jr	z, 5
	cp	a, 81
	jr	nz, 21
	cps	w, 2
	jr	nc, 17
	stda32	57747, xde
	lds	wa, 3
	ldw	bc, 21
	call	sendCOMM
	lds	hl, 0
	jr	2
	lds	hl, 1
	ret
	dec	2, xsp
	push	xiz
	stda32	57747, xwa
	ld	(xwa), 240
	ldda32	xwa, 57747
	ld	(xwa+1), 80
	ldda32	xwa, 57747
	ld	(xwa+2), 44
	ldda32	xwa, 57747
	ld	(xwa+3), 4
	ldda32	xwa, 57747
	ld	(xwa+4), 0
	ldda32	xwa, 57747
	ld	(xwa+5), 17
	ldda32	xwa, 57747
	calr	64132
	ld	(xsp+4), hl
	ld	wa, (xsp+4)
	exts	xwa
	add	xwa, xwa
	ldda32	xbc, 57747
	add	xbc, xwa
	add	xbc, 12
	ld	xiz, xbc
	inc	1, xiz
	ld	(xbc), 0
	ldda32	xwa, 57747
	ld	bc, (xsp+4)
	add	bc, bc
	add	bc, 13
	call	16610023
	.byte 0xf5
	swi	0
	ld	xsp, 3791061174
	.byte 0x93, 0xe1
	ldb	w, 159
	.byte 0x04
	ldb	a, 217
	xor	(xbc), a
	.byte 0xc8
	retd	7424
	.byte 0x06
	jrl	ule, 24317
	inc	2, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	xiz, xwa
	ld	xwa, xiz
	calr	64049
	ld	(xsp+6), hl
	ld	xwa, xiz
	calr	64082
	ld	bc, (xsp+6)
	exts	xbc
	.byte 0x9f, 0x06
	push	xsp
	nop
	nop
	jr	z, 113
	.byte 0x9f, 0x06
	push	xsp
	jrl	25088
	jr	gt, -21
	.byte 0xe3
	jr	z, 102
	ld	xwa, xhl
	sra	xwa, 15
	sra	xwa, 0
	and	xwa, 16383
	add	xwa, xhl
	and	xwa, 4294950912
	sub	xhl, xwa
	ld	e, (xhl+16)
	and	e, 192
	cp	e, 192
	jr	z, 72
	add	xhl, xbc
	cp	e, 128
	jr	z, 30
	cp	e, 64
	jr	z, 60
	cps	e, 0
	jr	nz, 56
	cp	xhl, 470
	jr	ugt, 43
	stda32	57747, xiz
	lds	wa, 3
	ld	bc, (xsp+6)
	ld	xde, xiz
	jr	19
	cp	xhl, 10535
	jr	ugt, 22
	stda32	57747, xiz
	lds	wa, 3
	ld	bc, (xsp+6)
	ld	xde, xiz
	call	sendCOMM
	.byte 0xbf, 0x04
	push_sr
	nop
	nop
	jr	5
	.byte 0xbf, 0x04
	push_sr
	.byte 0x01
	nop
	ld	hl, (xsp+4)
	pop	xiz
	inc	4, xsp
	ret

Param_SignExtendRetu_Block3:
	ldada xde, 58040
	ld (xde), 0x2b
	ld (xde + 1), 0x30
	ld (xde + 2), 0x7f
	ld (xde + 3), 0x20
	ld (xde + 4), 0x0
	ld (xde + 5), 0x0
	ld (xde + 6), 0x2
	incdi8 1, 57751
	ldda8 l, 57751
	res 7, l
	ld (xde + 7), l
	ld (xde + 8), a
	ld (xde + 9), c
	lds wa, 3
	ldw bc, 0xa
	call sendCOMM
	ldda8 l, 58047
	ret

Param_SignExtendRetu_Block4:
	ldada xde, 58050
	ld (xde), 0x2b
	ld (xde + 1), 0x30
	ld (xde + 2), 0x7f
	ld (xde + 3), 0x22
	ld (xde + 4), 0x0
	ld (xde + 5), 0x0
	ld (xde + 6), 0x2
	incdi8 1, 57751
	ldda8 l, 57751
	res 7, l
	ld (xde + 7), l
	ld (xde + 8), a
	ld (xde + 9), c
	lds wa, 3
	ldw bc, 0xa
	call sendCOMM
	ldda8 l, 58057
	ret

Param_SignExtendRetu_Block5:
	ldada xde, 58060
	ld (xde), 0x2b
	ld (xde + 1), 0x30
	ld (xde + 2), 0x7f
	ld (xde + 3), 0x24
	ld (xde + 4), 0x0
	ld (xde + 5), 0x0
	ld (xde + 6), 0x2
	incdi8 1, 57751
	ldda8 l, 57751
	res 7, l
	ld (xde + 7), l
	ld (xde + 8), a
	ld (xde + 9), c
	lds wa, 3
	ldw bc, 0xa
	call sendCOMM
	ldda8 l, 58067
	ret

SndParam_LookupPartIndex:
	ldada xde, 58070
	ld (xde), 0x2b
	ld (xde + 1), 0x30
	ld (xde + 2), 0x7f
	ld (xde + 3), 0x27
	ld (xde + 4), 0x0
	ld (xde + 5), 0x0
	ld (xde + 6), 0x2
	incdi8 1, 57751
	ldda8 l, 57751
	res 7, l
	ld (xde + 7), l
	ld (xde + 8), a
	ld (xde + 9), c
	lds wa, 3
	ldw bc, 0xa
	call sendCOMM
	ldda8 l, 58077
	ret

LookupPartIndex_Compare:
	cps wa, 4
	jrl ugt, CommPacket_WriteMeas_Block
	ldada xde, 58080
	ld (xde), 0x2d
	ld (xde + 1), 0x0
	ld (xde + 3), 0x0
	ld (xde + 4), 0x0
	ld (xde + 5), 0x0
	lda xhl, (xde + 6)
	ld (xhl), 0x38
	ld (xde + 7), c
	lda xbc, (xde + 2)
	cps wa, 4
	jr z, LookupPartIndex_LoadReg4
	cps wa, 3
	jr z, LookupPartIndex_LoadReg3
	cps wa, 2
	jr z, LookupPartIndex_LoadReg2
	cps wa, 1
	jr z, LookupPartIndex_LoadReg
	cps wa, 0
	jr nz, LookupPartIndex_LoadReg5
	ld (xbc), 0xa
	jr CommPacket_WriteMeasureCount

LookupPartIndex_LoadReg:
	ld (xbc), 0xb
	jr CommPacket_WriteMeasureCount

LookupPartIndex_LoadReg2:
	ld (xbc), 0xc
	jr CommPacket_WriteMeasureCount

LookupPartIndex_LoadReg3:
	ld (xbc), 0xd
	jr CommPacket_WriteMeasureCount

LookupPartIndex_LoadReg4:
	ld (xbc), 0xe
	jr CommPacket_WriteMeasureCount

LookupPartIndex_LoadReg5:
	ld (xhl), 0x0

CommPacket_WriteMeasureCount:
	ld c, (xhl)
	cps c, 0
	jr z, CommPacket_WriteMeas_Block
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	ld xiy, 0x3c0fa
	add xiy, xbc
	lda xix, (xde + 8)
	ldw bc, 0x1c
	ldirw
	ld c, (xhl)
	inc 8, c
	extz bc
	lds wa, 3
	call sendCOMM

CommPacket_WriteMeas_Block:
	incdi8 1, 57751
	ldda8 l, 57751
	res 7, l
	ret

SendCOMM_VariableLengthPacket:
	push xiz
	ldada xhl, 58144
	ld (xhl), 0x2c
	ld (xhl + 1), 0x0
	ld (xhl + 2), 0x8
	ld (xhl + 3), c
	ld (xhl + 4), 0x0
	ld (xhl + 5), 0x0
	ld (xhl + 6), e
	ldda8 c, 57751
	inc 1, c
	stda8 57751, c
	res 7, c
	ld (xhl + 7), c
	ldi_werp 0xe6, 0
	ldfr_berp E, 0xf0
	extz ix
	cps ix, 0
	jr ule, SendCOMM_VariableLen_Increment
	ld xiy, xwa
	ldw bc, 0x8

SendCOMM_VariableLen_LoadReg:
	ld iz, bc
	extz xiz
	add xiz, xhl
	ld a, (xiy)
	ld (xiz), a
	inc1_werp 0xe6
	inc 1, bc
	ldto_werp WA, 0xe6
	cp wa, ix
	jr c, SendCOMM_VariableLen_LoadReg

SendCOMM_VariableLen_Increment:
	inc 8, e
	extz de
	lds wa, 3
	ld bc, de
	ld xde, xhl
	call sendCOMM
	ldda8 l, 57751
	res 7, l
	pop xiz
	ret

COMM_BuildAndSendPacket:
	ldada xde, 58164
	ld (xde), 0x2c
	ld (xde + 1), 0x30
	ld (xde + 2), 0x7f
	ld (xde + 3), 0x4
	ld (xde + 4), 0x0
	ld (xde + 5), 0x0
	ld (xde + 6), 0x2
	incdi8 1, 57751
	ldda8 l, 57751
	res 7, l
	ld (xde + 7), l
	ld (xde + 8), a
	ld (xde + 9), c
	lds wa, 3
	ldw bc, 0xa
	jp sendCOMM

BuildAndSendPacket_Block:
	ldada xde, 58174
	ld (xde), 0x2c
	ld (xde + 1), 0x30
	ld (xde + 2), 0x7f
	ld (xde + 3), 0x6
	ld (xde + 4), 0x0
	ld (xde + 5), 0x0
	ld (xde + 6), 0x2
	incdi8 1, 57751
	ldda8 l, 57751
	res 7, l
	ld (xde + 7), l
	ld (xde + 8), a
	ld (xde + 9), c
	lds wa, 3
	ldw bc, 0xa
	jp sendCOMM

TmFlash_Return:
	ldada xde, 58184
	ld (xde), 0x2c
	ld (xde + 1), 0x30
	ld (xde + 2), 0x7f
	ld (xde + 3), 0x8
	ld (xde + 4), 0x0
	ld (xde + 5), 0x0
	ld (xde + 6), 0x1
	incdi8 1, 57751
	ldda8 a, 57751
	res 7, a
	ld (xde + 7), a
	ld (xde + 8), 0x0
	lds wa, 3
	ldw bc, 0x9
	jp sendCOMM

TmFlash_Return_Prologue:
	dec 6, xsp
	push xiz
	ld (xsp + 8), wa
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, 0xeed520
	add xbc, xwa
	ld a, (xbc)
	extz wa
	ld (xsp + 4), wa
	sla wa, 8
	extz xwa
	add xwa, 0x4900
	call DSPCfg_ReadParam_Map0
	ld (xsp + 6), hl
	ld wa, (xsp + 8)
	ld bc, (xsp + 6)
	call SendPartDataBlock_InitVal
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	ld xwa, 0x3c0fa
	add xwa, xbc
	ldw (xwa + 42), 0x1
	ldw (xwa + 2), 0x0
	ld wa, (xsp + 4)
	sll wa, 8
	extz xwa
	add xwa, 0x4904
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xfa
	ld wa, (xsp + 8)
	ldto_werp BC, 0xfa
	call SendPartDataBlock_InitVal2
	lds iz, 0
	cpi_werp 0xfa, 0
	jr ule, TmFlash_Return_CheckZero

TmFlash_Return_LoadReg:
	ld bc, iz
	extz xbc
	ld wa, (xsp + 4)
	sll wa, 8
	extz xwa
	add xwa, 0x4910
	add xwa, xbc
	call DSPCfg_ReadParam_Map0
	ld de, hl
	ld wa, (xsp + 8)
	ld bc, iz
	call SendPartDataBlock_Prologue
	inc 1, iz
	cp_werp IZ, 0xfa
	jr c, TmFlash_Return_LoadReg

TmFlash_Return_CheckZero:
	cpw (xsp + 8), 0x0
	jr nz, TmFlash_Return_LoadParam2
	cpw (xsp + 6), 0x35
	jr z, TmFlash_Return_LoadParam
	cpw (xsp + 6), 0xf
	jr nz, TmFlash_Return_LoadParam2

TmFlash_Return_LoadParam:
	ld wa, (xsp + 8)
	ldw bc, 0xf
	lds de, 0
	call SendPartDataBlock_Prologue

TmFlash_Return_LoadParam2:
	ld wa, (xsp + 4)
	sll wa, 8
	extz xwa
	add xwa, 0x4906
	call DSPCfg_ReadParam_Map0
	ld bc, hl
	ld wa, (xsp + 8)
	call SendPartDataBlock_InitVal3
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	ld xwa, 0x3c0fa
	add xwa, xbc
	ldw (xwa + 46), 0x1
	ldw (xwa + 40), 0x0
	ldw (xwa + 48), 0x63
	ldw (xwa + 50), 0x0
	ldw (xwa + 52), 0x0
	lda xbc, (xwa + 54)
	cpw (xsp + 8), 0x4
	jr z, TmFlash_Return_LoadDRAM4
	cpw (xsp + 8), 0x3
	jr z, TmFlash_Return_LoadDRAM3
	cpw (xsp + 8), 0x2
	jr z, TmFlash_Return_LoadDRAM2
	cpw (xsp + 8), 0x1
	jr z, TmFlash_Return_LoadDRAM
	cpw (xsp + 8), 0x0
	jr nz, CommParam_SetComplete_Return
	ldda8 a, 58198
	extz wa
	ld (xbc), wa
	jr CommParam_SetComplete_Return

TmFlash_Return_LoadDRAM:
	ldda8 a, 58199
	extz wa
	ld (xbc), wa
	jr CommParam_SetComplete_Return

TmFlash_Return_LoadDRAM2:
	ldda8 a, 58200
	extz wa
	ld (xbc), wa
	jr CommParam_SetComplete_Return

TmFlash_Return_LoadDRAM3:
	ldda8 a, 58201
	extz wa
	ld (xbc), wa
	jr CommParam_SetComplete_Return

TmFlash_Return_LoadDRAM4:
	ldda8 a, 58202
	extz wa
	ld (xbc), wa

CommParam_SetComplete_Return:
	pop xiz
	inc 6, xsp
	ret

CommParam_SetComplete_Block:
	stdi8 58198, 1
	stdi8 58199, 255
	stdi8 58200, 255
	stdi8 58201, 255
	stdi8 58202, 255
	stdi8 58193, 255
	stdi8 58194, 255
	stdi8 58195, 255
	stdi8 58203, 255
	stdi8 58196, 255
	stdi8 58204, 255
	ret

CommParam_SetComplete_Block2:
	jr CommParam_SetComplete_Block

CommParam_SetComplete_Return2:
	ret

CommParam_SetComplete_Return3:
	ret

CommPort_StatusCheckAndSend:
	ldcf_dd8 4, 0x38
	scc8 c, a
	cpda8 a, 58204
	ret z
	ldcf_dd8 4, 0x38
	scc8 c, a
	stda8 58204, a
	ld xwa, 0xe35c
	ldw bc, 0x8
	lds de, 1
	call SendCOMM_VariableLengthPacket
	ret

CommPort_StatusCheck_Compare:
	cp a, c
	jr nz, CheckValidityReturn_SetByteFF
	ldda16 xwa, 36152
	cp a, 0xd6
	jr z, Note_CheckValidityReturn
	cp a, 0xe
	jr z, Note_CheckValidityReturn
	cp a, 0xc
	jr z, Note_CheckValidityReturn
	cp a, 0xb
	jr z, Note_CheckValidityReturn
	cp a, 0xa
	jr nz, CheckValidityReturn_SetByteFF

Note_CheckValidityReturn:
	ldb l, 0x0
	jr CheckValidityReturn_Return

CheckValidityReturn_SetByteFF:
	ldb l, 0xff

CheckValidityReturn_Return:
	ret

COMM_SendPartDataBlock:
	dec 2, xsp
	push_werp 0xfa
	ld (xsp + 2), a
	cp (xsp + 2), 0x4
	jr ugt, SendPartDataBlock_RestoreReg
	ld e, (xsp + 2)
	ld a, e
	extz wa
	muls wa, 0x38
	inc 8, wa
	lda_24 xbc, 0x03c0fa
	ld_sriw3 WA, 0x07, 0xe4, 0xe0
	ldfr_berp A, 0xfb
	ld a, e
	extz wa
	calr TmFlash_Return_Prologue
	ldto_berp A, 0xfb
	extz wa
	ld c, (xsp + 2)
	extz bc
	muls bc, 0x38
	inc 8, bc
	lda_24 xde, 0x03c0fa
	ld_sriw3 BC, 0x07, 0xe8, 0xe4
	extz bc
	calr CommPort_StatusCheck_Compare
	cp (xsp + 2), 0x3
	jr nz, SendPartDataBlock_LoadParam
	ldda8 a, 58196
	extz wa
	st16_24 0x03c1b6, xwa

SendPartDataBlock_LoadParam:
	ld a, (xsp + 2)
	extz wa
	extz hl
	ld bc, hl
	call LookupPartIndex_Compare

SendPartDataBlock_RestoreReg:
	pop_werp 0xfa
	inc 2, xsp
	ret

SendPartDataBlock_Block:
	; --- Set-if-changed handlers for E351-E354 (4x24 = 96 bytes) ---
	cpdm8	58193, a
	ret z
	stda8	58193, a
	ld xwa, 0x0000e351
	lds	bc, 1
	lds	de, 1
	call SendCOMM_VariableLengthPacket
	ret
SendPartDataBlock_Block2:
	cpdm8	58194, a
	ret z
	stda8	58194, a
	ld xwa, 0x0000e352
	lds	bc, 2
	lds	de, 1
	call SendCOMM_VariableLengthPacket
	ret
SendPartDataBlock_Block3:
	cpdm8	58195, a
	ret z
	stda8	58195, a
	ld xwa, 0x0000e353
	lds	bc, 6
	lds	de, 1
	call SendCOMM_VariableLengthPacket
	ret
SendPartDataBlock_Block4:
	cpdm8	58196, a
	ret z
	stda8	58196, a
	ld xwa, 0x0000e354
	lds	bc, 7
	lds	de, 1
	call SendCOMM_VariableLengthPacket
	ret


SendPartDataBlock_ClearByte:
	ldb c, 0x0
	cps a, 0
	jr z, SendPartDataBlock_Block5
	ldb c, 0x1

SendPartDataBlock_Block5:
	cpdm8 58199, c
	ret z
	stda8 58199, c
	ld xwa, 0xe357
	ldw bc, 0x21
	lds de, 1
	call SendCOMM_VariableLengthPacket
	ret

SendPartDataBlock_ClearByte2:
	ldb c, 0x0
	cps a, 0
	jr z, SendPartDataBlock_Block6
	ldb c, 0x1

SendPartDataBlock_Block6:
	cpdm8 58200, c
	ret z
	stda8 58200, c
	ld xwa, 0xe358
	ldw bc, 0x22
	lds de, 1
	call SendCOMM_VariableLengthPacket
	ret

SendPartDataBlock_Block7:
	cpdm8 58203, a
	ret z
	ldb c, 0x1
	cps a, 0
	jr nz, SendPartDataBlock_StoreDRAM
	ldb c, 0x0

SendPartDataBlock_StoreDRAM:
	stda8 58203, c
	ld xwa, 0xe35b
	ldw bc, 0x23
	lds de, 1
	call SendCOMM_VariableLengthPacket
	ret

SendPartDataBlock_ClearByte3:
	ldb c, 0x0
	cps a, 0
	jr z, SendPartDataBlock_Block8
	ldb c, 0x1

SendPartDataBlock_Block8:
	cpdm8 58201, c
	ret z
	stda8 58201, c
	ld xwa, 0xe359
	ldw bc, 0x24
	lds de, 1
	call SendCOMM_VariableLengthPacket
	ret

SendPartDataBlock_Block9:
	ldb	c, 0
	cps	a, 0
	jr	z, 2
	ldb	c, 1
	cpdm8	58202, c
	ret	z
	stda8	58202, c
	ld	xwa, 58202
	ldw	bc, 37
	lds	de, 1
	call	SendCOMM_VariableLengthPacket
	ret
	st16_24	246010, wa
	lds	hl, 0
	ret
	st16_24	246012, wa
	lds	hl, 0
	ret
	st16_24	246014, wa
	lds	hl, 0
	ret
	st16_24	246016, wa
	lds	hl, 0
	ret

SendPartDataBlock_InitVal:
	lds hl, 0
	cps wa, 5
	jr nc, SendPartDataBlock_SetWord
	cp bc, 0x63
	jr ugt, SendPartDataBlock_SetWord
	extz xwa
	ld xde, xwa
	sll xde, 3
	sub xde, xwa
	sll xde, 3
	inc 8, xde
	ld xwa, 0x3c0fa
	add xwa, xde
	ld (xwa), bc
	jr SendPartDataBlock_Return

SendPartDataBlock_SetWord:
	ldw hl, 0xffff

SendPartDataBlock_Return:
	ret

SendPartDataBlock_Prologue:
	push xiz
	lds hl, 0
	cps wa, 5
	jr nc, SendPartDataBlock_SetWord2
	ld ix, wa
	extz xix
	ld xwa, xix
	sll xwa, 3
	sub xwa, xix
	sll xwa, 3
	ld xiy, xwa
	inc 8, xiy
	lda_24 xix, 0x03c0fa
	ld xiz, xix
	add xiz, xiy
	cp bc, (xiz + 44)
	jr nc, SendPartDataBlock_SetWord2
	extz xbc
	add xbc, xbc
	add xwa, xbc
	add xix, xwa
	ld (xix + 12), de
	jr SendPartDataBlock_Epilogue

SendPartDataBlock_SetWord2:
	ldw hl, 0xffff

SendPartDataBlock_Epilogue:
	pop xiz
	ret

SendPartDataBlock_InitVal2:
	lds hl, 0
	cps wa, 5
	jr nc, SendPartDataBlock_SetWord3
	extz xwa
	ld xde, xwa
	sll xde, 3
	sub xde, xwa
	sll xde, 3
	inc 8, xde
	lda_24 xwa, 0x03c126
	add xwa, xde
	ld (xwa), bc
	jr SendPartDataBlock_Return2

SendPartDataBlock_SetWord3:
	ldw hl, 0xffff

SendPartDataBlock_Return2:
	ret

SendPartDataBlock_InitVal3:
	lds hl, 0
	cps wa, 5
	jr nc, SendPartDataBlock_SetWord4
	extz xwa
	ld xde, xwa
	sll xde, 3
	sub xde, xwa
	sll xde, 3
	inc 8, xde
	lda_24 xwa, 0x03c120
	add xwa, xde
	ld (xwa), bc
	jr SendPartDataBlock_Return3

SendPartDataBlock_SetWord4:
	ldw hl, 0xffff

SendPartDataBlock_Return3:
	ret

SendPartDataBlock_SetWord5:
	ldw bc, 0x24b8
	lda_24 xwa, 0x1e0010
	lds de, 0

SendPartDataBlock_Block10:
	add_spiw DE, 0xe1
	djnz xbc, SendPartDataBlock_Block10
	cpl de
	ld hl, de
	ret

SendPartDataBlock_ClearByte4:
	ldb w, 0x0
	lda_24 xde, 0x1e0000
	lda_24 xhl, 0xeed56c

SendPartDataBlock_LoadReg:
	ld c, w
	extz bc
	ld_srib3 A, 0x07, 0xec, 0xe4
	cp_srib_rm A, 0x07, 0xe8, 0xe4
	jr nz, SendPartDataBlock_Compare
	inc 1, w
	cp w, 0x10
	jr c, SendPartDataBlock_LoadReg

SendPartDataBlock_Compare:
	cp w, 0x10
	jr nz, SendPartDataBlock_SetWord6
	calr SendPartDataBlock_SetWord5
	lda_24 xwa, 0x1e0000
	cp_sriw_mr HL, 0xe1, 0xa8, 0x72
	jr nz, SendPartDataBlock_SetWord6
	ldw bc, 0x72aa
	ld xde, 0x7800
	jp InterCPU_E1_Bulk_Transfer

SendPartDataBlock_SetWord6:
	ldw wa, 0xff
	ldw bc, 0xff
	jp COMM_BuildAndSendPacket

SendPartDataBlock_Return4:
	ret

SendPartDataBlock_DoGetError:
	call SubCPU_Payload_GetErrorFlag
	cp hl, 0xffff
	ret nz
	ldw wa, 0xff
	ldw bc, 0xff
	call COMM_BuildAndSendPacket
	ret

SendPartDataBlock_Return5:
	ret

SendPartDataBlock_Data:
	lda	xsp, (xsp-10)
	push	xiz
	ld	(xsp+10), xbc
	ld	xiz, xwa
	ld	xwa, xiz
	calr	870
	ld	xde, (xsp+10)
	ld	xiy, xde
	ld	xix, xiz
	ldw	bc, 8
	ldirw
	ld	a, (xde+16)
	ld	(xiz+16), a
	ld	xbc, xde
	ld	a, (xbc+17)
	ld	(xiz+17), a
	ld	a, (xbc+18)
	ld	(xiz+18), a
	ld	a, (xbc+19)
	ld	(xiz+19), a
	ld	a, (xbc+20)
	ld	(xiz+24), a
	ld	a, (xbc+21)
	ld	(xiz+25), a
	ld	a, (xbc+22)
	ld	(xiz+36), a
	ld	a, (xbc+23)
	ld	(xiz+37), a
	ld	a, (xbc+24)
	ld	(xiz+41), a
	ld	a, (xbc+25)
	ld	(xiz+42), a
	ld	a, (xbc+26)
	ld	(xiz+43), a
	ld	a, (xbc+27)
	ld	(xiz+44), a
	ld	a, (xbc+28)
	ld	(xiz+45), a
	ld	a, (xbc+29)
	ld	(xiz+46), a
	ld	a, (xbc+31)
	ld	(xiz+92), a
	ld	a, (xbc+32)
	ld	(xiz+93), a
	.byte 0xc7, 0xe6
	sub	(xwa-39), xwa
	ld	hl, bc
	add	hl, 94
	ld	de, bc
	add	de, 33
	ld	xwa, (xsp+10)
	.byte 0xc3
	reti
	.byte 0xe0, 0xe8
	ldb	a, 243
	reti
	swi	0
	.byte 0xec
	ld	xbc, 3647071943
	jr	lt, -57
	.byte 0xe6
	mul	l, 103
	.byte 0xdc
	ld	(xsp+4), 0
	.byte 0xbf
	ldio	2, 0
	nop
	.byte 0xbf
	ei	2
	nop
	nop
	ld	wa, (xsp+6)
	add	wa, 102
	.byte 0xf3
	reti
	swi	0
	.byte 0xe0
	ldw	bc, 2207
	ldb	b, 218
	.byte 0xc8
	pushw	bc
	nop
	ld	xwa, (xsp+10)
	exts	xde
	add	xde, xwa
	ld	a, (xde)
	ld	(xbc+1), a
	ld	a, (xde+1)
	ld	(xbc+2), a
	lda	xhl, (xbc+3)
	ld	a, (xde+2)
	ld	(xhl), a
	and	a, 207
	ld	(xhl), a
	ld	a, (xde+3)
	ld	(xbc+4), a
	ld	a, (xde+4)
	ld	(xbc+5), a
	ld	a, (xde+5)
	ld	(xbc+6), a
	ld	(xbc+7), 50
	ld	a, (xde+6)
	ld	(xbc+8), a
	ld	a, (xde+7)
	ld	(xbc+9), a
	ld	a, (xde+8)
	ld	(xbc+10), a
	ld	a, (xde+9)
	ld	(xbc+11), a
	ld	a, (xde+10)
	ld	(xbc+23), a
	ld	a, (xde+11)
	ld	(xbc+24), a
	lda	xhl, (xde+12)
	ld	a, (xhl)
	ld	(xbc+25), a
	.byte 0xb1, 0xb7
	ld	a, (xhl)
	and	a, 16
	cp	a, 16
	jr	nz, 2
	.byte 0xb1, 0xbf
	ld	a, (xde+13)
	ld	(xbc+26), a
	ld	a, (xde+14)
	ld	(xbc+27), a
	ld	a, (xde+15)
	ld	(xbc+28), a
	ld	a, (xde+16)
	ld	(xbc+29), a
	ld	a, (xde+17)
	ld	(xbc+30), a
	ld	a, (xde+18)
	ld	(xbc+31), a
	ld	a, (xde+19)
	ld	(xbc+32), a
	ld	a, (xde+20)
	ld	(xbc+33), a
	ld	a, (xde+21)
	ld	(xbc+34), a
	ld	a, (xde+22)
	ld	(xbc+35), a
	ld	a, (xde+23)
	ld	(xbc+36), a
	ld	a, (xde+24)
	ld	(xbc+37), a
	ld	a, (xde+25)
	ld	(xbc+39), a
	ld	a, (xde+26)
	ld	(xbc+41), a
	ld	a, (xde+27)
	ld	(xbc+42), a
	ld	a, (xde+28)
	ld	(xbc+43), a
	ld	a, (xde+29)
	ld	(xbc+44), a
	ld	a, (xde+30)
	ld	(xbc+45), a
	ld	a, (xde+31)
	ld	(xbc+46), a
	ld	a, (xde+32)
	ld	(xbc+47), a
	ld	a, (xde+33)
	ld	(xbc+48), a
	ld	a, (xde+34)
	ld	(xbc+49), a
	ld	a, (xde+35)
	ld	(xbc+50), a
	ld	a, (xde+36)
	ld	(xbc+51), a
	ld	a, (xde+37)
	ld	(xbc+52), a
	ld	a, (xde+38)
	ld	(xbc+53), a
	ld	a, (xde+39)
	ld	(xbc+54), a
	ld	a, (xde+40)
	ld	(xbc+55), a
	ld	a, (xde+42)
	ld	(xbc+57), a
	ld	a, (xde+43)
	ld	(xbc+58), a
	ld	a, (xde+44)
	ld	(xbc+59), a
	ld	a, (xde+45)
	ld	(xbc+60), a
	ld	a, (xde+41)
	ld	(xbc+77), a
	ld	a, (xde+46)
	ld	(xbc+61), a
	ld	a, (xde+47)
	ld	(xbc+62), a
	ld	a, (xde+48)
	ld	(xbc+63), a
	ld	a, (xde+49)
	ld	(xbc+64), a
	ld	a, (xde+50)
	ld	(xbc+65), a
	ld	a, (xde+51)
	ld	(xbc+66), a
	ld	a, (xde+52)
	ld	(xbc+67), a
	ld	a, (xde+53)
	ld	(xbc+68), a
	ld	a, (xde+54)
	ld	(xbc+69), a
	ld	a, (xde+55)
	ld	(xbc+70), a
	ld	a, (xde+56)
	ld	(xbc+71), a
	ld	a, (xde+57)
	ld	(xbc+72), a
	ld	a, (xde+58)
	ld	(xbc+73), a
	ld	a, (xde+59)
	ld	(xbc+74), a
	ld	a, (xde+60)
	ld	(xbc+75), a
	ld	a, (xde+61)
	ld	(xbc+76), a
	incm8	1, (xsp+4)
	.byte 0x9f, 0x06
	push	xwa
	.byte 0x51
	nop
	.byte 0x9f
	ldio	56, 62
	nop
	.byte 0x8f, 0x04
	push	xsp
	.byte 0x04
	jrl	c, -444
	pop	xiz
	lda	xsp, (xsp+10)
	ret
	lda	xhl, (xwa+16)
	ld	e, (xhl)
	and	e, 183
	ld	(xhl), e
	lda	xbc, (xwa+17)
	.byte 0xb1
	inc	6, l
	halt
	set	6, e
	ld	(xhl), e
	.byte 0xb1
	inc	6, a
	push_sr
	.byte 0xb3, 0xbb
	ld	c, (xwa+18)
	and	c, 240
	.byte 0xc7, 0xf0, 0x9b
	srl	c, 4
	extz	bc
	lda_24	xhl, 15652237
	.byte 0xc3
	reti
	or	xix, xix
	ldb	c, 199
	.byte 0xf0, 0x9b, 0xc7, 0xf0
	or	(xix-52), h
	.byte 0x06
	ld	e, (xwa+19)
	ld	c, e
	and	c, 240
	.byte 0xc7, 0xf0, 0x9b
	srl	c, 4
	extz	bc
	.byte 0xc3
	reti
	or	xix, xix
	ldb	c, 199
	.byte 0xf0
	or	(xhl-53), iz
	.byte 0x04
	or	d, c
	and	e, 15
	.byte 0xc7, 0xf0, 0x9d, 0xc7, 0xf0, 0x8b
	extz	bc
	.byte 0xc3
	reti
	or	xix, xix
	ldb	c, 199
	.byte 0xf0
	or	(xhl-53), iz
	push_sr
	or	d, c
	ld	(xwa+17), d
	lda	xbc, (xwa+20)
	ld	xde, xbc
	lda	xhl, (xbc+124)
	ld	c, (xde)
	ld	(xde-2), c
	inc	1, xde
	cp	xde, xhl
	jr	c, -11
	lds	hl, 0
	ld	de, hl
	add	de, 40
	.byte 0xf3
	reti
	.byte 0xe0, 0xe8
	ldw	bc, 4489
	ldb	c, 199
	.byte 0xf0, 0x9b, 0xf3
	reti
	.byte 0xe0, 0xe8
	ldw	iy, 2035
	.byte 0xe0, 0xe8
	ldw	bc, 4233
	ldb	c, 189
	scf
	ld	xhl, 3906996211
	ldw	iy, 2035
	.byte 0xe0, 0xe8
	ldw	bc, 3977
	ldb	c, 189
	rcf
	ld	xhl, 3906996211
	ldw	iy, 2035
	.byte 0xe0, 0xe8
	ldw	bc, 3721
	ldb	c, 189
	retd	62275
	reti
	.byte 0xe0, 0xe8
	ldw	iy, 2035
	.byte 0xe0, 0xe8
	ldw	bc, 3465
	ldb	c, 189
	ret
	ld	xhl, 3906996211
	ldw	iy, 2035
	.byte 0xe0, 0xe8
	ldw	bc, 3209
	ldb	c, 189
	decf
	ld	xhl, 2196247530
	.byte 0xc7, 0xf0, 0x8b
	ld	(xde+12), c
	add	hl, 34
	cp	hl, 102
	jr	lt, -117
	ret
	.byte 0xf3
	swi	5
	.byte 0x56
	swi	6
	.byte 0x37
	ld	xde, xwa
	ld	xiy, 15652253
	ld	xix, xsp
	ldw	bc, 213
	ldirw
	ld	xiy, xsp
	ld	xix, xde
	ldw	bc, 213
	ldirw
	lda	xwa, (xde+102)
	ld	xiy, xwa
	.byte 0xf3
	sbc	xsp, xbc
	nop
	ldw	ix, 10289
	nop
	ldirw
	.byte 0x85
	rcf
	ld	xiy, xwa
	lda	xix, (xde+264)
	ldw	bc, 40
	ldirw
	.byte 0x85
	rcf
	ld	xiy, xwa
	lda	xix, (xde+345)
	ldw	bc, 40
	ldirw
	.byte 0x85
	rcf
	.byte 0xf3
	swi	5
	.byte 0xaa, 0x01, 0x37
	ret
	lda	xsp, (xsp-26)
	push	xiz
	ld	(xsp+22), xbc
	ld	(xsp+26), xwa
	ld	xwa, (xsp+26)
	calr	65441
	ld	xde, (xsp+26)
	lda	xhl, (xde+16)
	ld	xwa, (xsp+22)
	ld	xiy, xwa
	ld	xix, xde
	ldw	bc, 8
	ldirw
	lda	xwa, (xwa+16)
	.byte 0xb0
	inc	6, l
	.byte 0x04, 0xb3, 0xbd
	jr	2
	.byte 0xb3, 0xb5, 0xb0
	inc	6, b
	.byte 0x04, 0xb3, 0xbc
	jr	2
	.byte 0xb3, 0xb4
	ld	xhl, (xsp+26)
	lda	xwa, (xhl+41)
	ld	(xsp+14), xwa
	.byte 0x80
	push	xix
	.byte 0xf0
	lda	xwa, (xhl+42)
	ld	(xsp+10), xwa
	ld	(xwa), 0
	ld	xix, (xsp+22)
	lda	xwa, (xix+17)
	ld	(xsp+18), xwa
	ld	a, (xwa)
	and	a, 192
	srl	a, 6
	inc	7, a
	ld	c, a
	ld	xwa, (xsp+14)
	or	(xwa), c
	ld	xiy, (xsp+18)
	ld	a, (xiy)
	and	a, 48
	srl	a, 4
	inc	7, a
	sll	a, 4
	ld	e, a
	ld	xwa, (xsp+10)
	ld	c, (xwa)
	or	c, e
	ld	xde, (xsp+10)
	ld	(xde), c
	ld	a, (xiy)
	and	a, 12
	srl	a, 2
	inc	7, a
	or	c, a
	ld	(xde), c
	ld	a, (xix+18)
	mul	a, 127
	extz	wa
	div	a, 30
	ld	c, a
	ld	(xhl+59), c
	ld	xde, xix
	ld	a, (xde+19)
	ld	(xhl+43), a
	lda	xwa, (xde+20)
	ld	(xsp+18), xwa
	ld	xbc, xhl
	lda	xwa, (xbc+44)
	ld	(xsp+14), xwa
	lda	xwa, (xbc+60)
	ld	(xsp+10), xwa
	ld	xwa, (xsp+18)
	ld	c, (xwa)
	cp	c, 9
	jr	nc, 11
	inc	5, c
	ld	xwa, (xsp+10)
	ld	(xwa), c
	ldb	c, 5
	jr	47
	cp	c, 24
	jr	nc, 32
	ld	a, c
	add	a, c
	dec	4, a
	ld	c, a
	ld	xwa, (xsp+10)
	ld	(xwa), c
	ld	xwa, (xsp+18)
	ld	a, (xwa)
	sll	a, 1
	dec	4, a
	ld	c, a
	ld	xwa, (xsp+14)
	ld	(xwa), c
	jr	24
	add	c, 19
	ld	xwa, (xsp+10)
	ld	(xwa), c
	ldb	c, 19
	ld	xwa, (xsp+18)
	ld	a, (xwa)
	add	a, c
	ld	c, a
	ld	xwa, (xsp+14)
	ld	(xwa), c
	ld	xix, (xsp+22)
	lda	xde, (xix+21)
	ld	c, (xde)
	ld	xhl, (xsp+26)
	ld	(xhl+62), c
	ld	c, (xde)
	ld	(xhl+46), c
	ld	c, (xix+30)
	sll	c, 3
	ld	(xhl+92), c
	ld	xwa, xix
	lda	xwa, (xwa+31)
	ld	(xsp+6), xwa
	ld	xde, xhl
	ld	a, (xwa)
	ld	(xde+93), a
	ld	(xsp+4), 0
	lds	de, 0
	ld	ix, de
	add	ix, 94
	ld	hl, de
	add	hl, 32
	ld	xwa, (xsp+22)
	ld	xbc, (xsp+26)
	.byte 0xc3
	reti
	.byte 0xe0, 0xec
	ldb	a, 243
	reti
	.byte 0xe4, 0xf0
	ld	xbc, 3663791247
	jr	lt, -113
	.byte 0x04
	push	xsp
	ldio	103, 217
	ld	xwa, (xsp+6)
	ld	a, (xwa)
	and	a, 15
	cp	a, 10
	jr	z, 5
	cp	a, 11
	jr	nz, 67
	ld	xwa, (xsp+26)
	lda	xwa, (xwa+96)
	ld	(xsp+18), xwa
	ld	xwa, (xsp+22)
	.byte 0x88
	.ascii "\"?2c"
	.byte 0x06
	ld	xwa, (xsp+18)
	ld	(xwa), 50
	ld	xwa, (xsp+6)
	.byte 0xb0
	inc	6, l
	ldb	d, 175
	ex_ff
	ldb	c, 187
	.byte 0x1c
	ldw	de, 8578
	bit	6, a
	jr	z, 23
	ld	xbc, (xsp+26)
	ld	(xbc+94), 1
	ld	a, (xhl+29)
	ld	(xbc+95), a
	ld	c, (xde)
	and	c, 63
	ld	xwa, (xsp+18)
	ld	(xwa), c
	ld	xbc, (xsp+26)
	lda	xwa, (xbc+17)
	ld	(xsp+10), xwa
	.byte 0x80
	push	xix
	.byte 0xaa
	lda	xbc, (xbc+102)
	ld	xwa, (xsp+22)
	lda	xde, (xwa+40)
	ld	(xsp+4), 0
	.byte 0xb2
	inc	6, l
	ldb	e, 143
	.byte 0x04
	push	xsp
	nop
	jr	nz, 7
	ld	xwa, (xsp+10)
	.byte 0xb0, 0xb8
	jr	24
	.byte 0x8f, 0x04
	push	xsp
	.byte 0x01
	jr	nz, 7
	ld	xwa, (xsp+10)
	.byte 0xb0, 0xba
	jr	11
	.byte 0x8f, 0x04
	push	xsp
	push_sr
	jr	nz, 5
	ld	xwa, (xsp+10)
	.byte 0xb0, 0xbc
	lda	xwa, (xbc+6)
	ld	(xwa), 0
	lda	xhl, (xbc+38)
	ld	(xhl), 0
	.byte 0xb2
	inc	6, h
	push	176
	.byte 0xbd
	ld	a, (xhl)
	set	5, a
	ld	(xhl), a
	ld	a, (xde+1)
	ld	(xbc+2), a
	ld	a, (xde+2)
	ld	(xbc+3), a
	ld	a, (xde+3)
	ld	(xbc+4), a
	ld	a, (xde+4)
	ld	(xbc+5), a
	ld	a, (xde+5)
	ld	(xbc+23), a
	ld	a, (xde+6)
	ld	(xbc+24), a
	ld	a, (xde+7)
	inc	3, a
	sla	a, 5
	ld	(xbc+25), a
	ld	a, (xde+8)
	ld	(xbc+29), a
	lda	xix, (xbc+27)
	ld	a, (xde+9)
	ld	(xix), a
	lda	xiy, (xbc+28)
	ld	a, (xde+10)
	ld	(xiy), a
	lda	xhl, (xbc+26)
	ld	(xhl), 66
	ld	a, (xix)
	cp	a, 66
	jr	ule, 2
	ld	(xhl), a
	ld	a, (xiy)
	cp	(xhl), a
	jr	ule, 2
	ld	(xhl), a
	ld	a, (xde+11)
	sll	a, 1
	ld	(xbc+39), a
	ld	a, (xde+12)
	ld	(xbc+46), a
	ld	(xbc+47), 0
SendPartDataBlock_Data2:
	ld	a, (xde+13)
	sll	a, 1
	ld	(xbc+41), a
	ld	a, (xde+14)
	sla	a, 1
	ld	(xbc+42), a
	ld	a, (xde+15)
	.byte 0xc9, 0xee
SendPartDataBlock_Data3:
	.byte 0x01
	ld	(xbc+43), a
	ld	a, (xde+16)
	sla	a, 1
	ld	(xbc+44), a
	ld	a, (xde+17)
	sll	a, 1
	ld	(xbc+45), a
	lda	xwa, (xde+18)
	ld	(xsp+18), xwa
	ld	a, (xwa)
	ld	(xbc+51), a
	lda	xwa, (xde+21)
	ld	(xsp+14), xwa
	ld	a, (xwa)
	ld	(xbc+52), a
	lda	xiz, (xde+24)
	ld	a, (xiz)
	ld	(xbc+53), a
	lda	xhl, (xbc+48)
	ld	(xhl), 66
	lda	xix, (xbc+49)
	ld	a, (xde+19)
	ld	(xix), a
	lda	xiy, (xbc+50)
	ld	a, (xde+20)
	ld	(xiy), a
	ld	xwa, (xsp+18)
	.byte 0x80
	push	xsp
	nop
	jr	nz, 43
	ld	xwa, (xsp+14)
	.byte 0x80
	push	xsp
	nop
	jr	z, 12
	ld	a, (xde+22)
	ld	(xix), a
	ld	xwa, 23
	jr	15
	.byte 0x86
	push	xsp
	nop
	jr	z, 18
	ld	a, (xde+25)
	ld	(xix), a
	ld	xwa, 26
	ld	xiz, xde
	add	xiz, xwa
	ld	a, (xiz)
	ld	(xiy), a
	ld	a, (xix)
	cp	(xhl), a
	jr	nc, 2
	ld	(xhl), a
	ld	a, (xiy)
	cp	(xhl), a
	jr	ule, 2
	ld	(xhl), a
	lda	xwa, (xbc+54)
	ld	(xsp+18), xwa
	ld	a, (xde+29)
	inc	3, a
	sla	a, 5
	ld	l, a
	ld	xwa, (xsp+18)
	ld	(xwa), l
	.byte 0x8a
	calr	65343
	jr	z, 5
	.byte 0xcf
SendPartDataBlock_Data4:
	ldw	bc, 45056
	ld	xsp, 2318683577
	jp	4305953
	ld	xwa, (xsp+6)
	ld	l, (xwa)
	ld	a, l
	and	a, 128
	cp	a, 128
	jr	nz, 11
	and	l, 15
	cp	l, 10
	jr	nz, 3
	ld	(xix), 127
	ld	a, (xde+28)
	ld	(xbc+55), a
	ld	a, (xde+31)
	ld	(xbc+60), a
	lda	xix, (xbc+58)
	ld	a, (xde+32)
	ld	(xix), a
	lda	xiy, (xbc+59)
	.byte 0x8a, 0x21
SendPartDataBlock_Data5:
	ldb	a, 181
	ld	xbc, 3006478777
	nop
	ld	xde, 3486065028
	ld	xde, 1102250595
	ld	a, (xiy)
	cp	(xhl), a
	jr	ule, 2
	ld	(xhl), a
	incm8	1, (xsp+4)
	lda	xbc, (xbc+81)
	lda	xde, (xde+34)
	.byte 0x8f, 0x04
	push	xsp
	pop_sr
	jrl	c, -474
	pop	xiz
	lda	xsp, (xsp+26)
	ret

SendPartDataBlock_InitVal4:
	lds de, 0
	lda_24 xhl, 0xeed56c

SendPartDataBlock_LoadReg2:
	ld bc, de
	extz xbc
	ld xiy, xbc
	add xiy, xwa
	ld xix, xhl
	add xix, xbc
	ld c, (xix)
	cp c, (xiy)
	jr nz, SendPartDataBlock_Compare2
	inc 1, de
	cp de, 0x10
	jr c, SendPartDataBlock_LoadReg2

SendPartDataBlock_Compare2:
	cp de, 0x10
	jr nz, SendPartDataBlock_InitVal5
	ldb l, 0x6
	ret

SendPartDataBlock_InitVal5:
	lds de, 0
	lda_24 xhl, 0xeed55b

SendPartDataBlock_LoadReg3:
	ld bc, de
	extz xbc
	ld xiy, xbc
	add xiy, xwa
	ld xix, xhl
	add xix, xbc
	ld c, (xix)
	cp c, (xiy)
	jr nz, SendPartDataBlock_Compare3
	inc 1, de
	cp de, 0x10
	jr c, SendPartDataBlock_LoadReg3

SendPartDataBlock_Compare3:
	cp de, 0x10
	jr nz, SendPartDataBlock_InitVal6
	ldb l, 0x5
	ret

SendPartDataBlock_InitVal6:
	lds de, 0
	lda_24 xhl, 0xeed54a

SendPartDataBlock_LoadReg4:
	ld bc, de
	extz xbc
	ld xiy, xbc
	add xiy, xwa
	ld xix, xhl
	add xix, xbc
	ld c, (xix)
	cp c, (xiy)
	jr nz, SendPartDataBlock_Compare4
	inc 1, de
	cp de, 0x10
	jr c, SendPartDataBlock_LoadReg4

SendPartDataBlock_Compare4:
	cp de, 0x10
	jr nz, SendPartDataBlock_InitVal7
	ldb l, 0x4
	ret

SendPartDataBlock_InitVal7:
	lds de, 0
	lda_24 xhl, 0xeed53b

SendPartDataBlock_LoadReg5:
	ld bc, de
	inc 5, bc
	extz xbc
	ld xiy, xbc
	add xiy, xwa
	ld bc, de
	extz xbc
	ld xix, xhl
	add xix, xbc
	ld c, (xix)
	cp c, (xiy)
	jr nz, SendPartDataBlock_Compare5
	inc 1, de
	cps de, 6
	jr c, SendPartDataBlock_LoadReg5

SendPartDataBlock_Compare5:
	cps de, 6
	jr nz, SendPartDataBlock_InitVal8
	ldb l, 0x1
	ret

SendPartDataBlock_InitVal8:
	lds de, 0
	lda_24 xhl, 0xeed542

SendPartDataBlock_LoadReg6:
	ld bc, de
	inc 5, bc
	extz xbc
	ld xiy, xbc
	add xiy, xwa
	ld bc, de
	extz xbc
	ld xix, xhl
	add xix, xbc
	ld c, (xix)
	cp c, (xiy)
	jr nz, SendPartDataBlock_Compare6
	inc 1, de
	cps de, 3
	jr c, SendPartDataBlock_LoadReg6

SendPartDataBlock_Compare6:
	cps de, 3
	jr nz, SendPartDataBlock_InitVal9
	ldb l, 0x2
	ret

SendPartDataBlock_InitVal9:
	lds de, 0
	lda_24 xhl, 0xeed546

SendPartDataBlock_LoadReg7:
	ld bc, de
	inc 5, bc
	extz xbc
	ld xiy, xbc
	add xiy, xwa
	ld bc, de
	extz xbc
	ld xix, xhl
	add xix, xbc
	ld c, (xix)
	cp c, (xiy)
	jr nz, SendPartDataBlock_Compare7
	inc 1, de
	cps de, 3
	jr c, SendPartDataBlock_LoadReg7

SendPartDataBlock_Compare7:
	cps de, 3
	jr nz, SendPartDataBlock_ClearByte5
	ldb l, 0x3
	ret

SendPartDataBlock_ClearByte5:
	ldb l, 0x0
	ret

SendPartDataBlock_SetWord7:
	ldw de, 0x24b8
	lda_24 xbc, 0x1e0000
	lda xwa, (xbc + 16)
	lds hl, 0

SendPartDataBlock_Block11:
	add_spiw HL, 0xe1
	djnz xde, SendPartDataBlock_Block11
	cpl hl
	st_dri3w HL, 0xe5, 0xa8, 0x72
	ret

; HDAE ROM data dispatch handler
HdaeRom_DataHandler:
	st_dri3b L, 0xfd, 0x48, 0xfe
	push xiz
	lda_dri3 XHL, 0xfd, 0xb8, 0x01
	lda_dri3 XBC, 0xfd, 0xba, 0x01
	ld xwa, 0x1e0000
	calr SendPartDataBlock_InitVal4
	lda_24 xbc, 0x1e0000
	extz hl
	dec 1, hl
	cps hl, 0
	jrl lt, HdaeRom_DataDispatch_SetWord
	cps hl, 5
	jrl gt, HdaeRom_DataDispatch_SetWord
	add hl, hl
	lda_24 xix, 0xeed747
	ld_sriw3 HL, 0x07, 0xf0, 0xec
	lda_24 xix, HdaeRom_DataDispatch
	jp_dri 8, 0x07, 0xf0, 0xec
; HDAE5000 extension ROM data dispatch (6-entry, table 0xeed747)
HdaeRom_DataDispatch:
	ld	(xsp+6), xbc
	cp	(xsp+442), 255
	jrl	nz, 307
	cp	(xsp+440), 255
	jrl	nz, 298
	.byte 0xbf, 0x04
	push_sr
	pushw	wa
	nop
	lda	xwa, (xsp+14)
	ld	(xsp+10), xwa
	ld	wa, (xsp+4)
	dec	1, wa
	ld	iz, wa
	extz	xiz
	ld	xwa, xiz
	ld	xbc, 289
	call	Math_MultiplyAccumulate
	add	xhl, 16
	ld	xiy, xhl
	.byte 0xaf, 0x06
	sub	(xiy), l
	ldwio	36, 36913
	nop
	ldirw
	.byte 0x85
	rcf
	ld	xwa, xiz
	ld	xbc, 470
	call	Math_MultiplyAccumulate
	add	xhl, 16
	.byte 0xaf, 0x06
	or	(xhl), c
	.byte 0x88
	ld	xbc, (xsp+10)
	calr	63168
	.byte 0x9f, 0x04
	push	xde
	.byte 0x01
	nop
	jr	nz, -82
	jrl	208
	ld	(xsp+6), xbc
	cp	(xsp+442), 255
	jr	nz, 90
	cp	(xsp+440), 255
	jr	nz, 82
	.byte 0xbf, 0x04
	push_sr
	ldb	d, 0
	lda	xwa, (xsp+14)
	ld	(xsp+10), xwa
	ld	wa, (xsp+4)
	dec	1, wa
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 3
	add	xbc, xwa
	sll	xbc, 4
	add	xbc, 80
	ld	xiy, xbc
	.byte 0xaf, 0x06
	sub	(xiy), l
	ldwio	36, 18481
	nop
	ldirw
	ld	xbc, 470
	call	Math_MultiplyAccumulate
	add	xhl, 16
	.byte 0xaf, 0x06
	or	(xhl), c
	.byte 0x88
	ld	xbc, (xsp+10)
	calr	64029
	.byte 0x9f, 0x04
	push	xde
	.byte 0x01
	nop
	jr	nz, -75
	jr	107
	.byte 0xc3
	swi	5
	.byte 0xb8, 0x01
	ldb	a, 216
	ccf
	ld	(xsp+4), wa
	jr	81
	ld	wa, (xsp+4)
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 3
	add	xbc, xwa
	sll	xbc, 4
	add	xbc, 80
	.byte 0xaf, 0x06
	or	(xbc), a
	.byte 0x88
	calr	63644
	ld	iz, (xsp+4)
	extz	xiz
	ld	xwa, xiz
	ld	xbc, 470
	call	Math_MultiplyAccumulate
	add	xhl, 16
	.byte 0xaf, 0x06
	or	(xhl), h
	or	(xbc-23), h
	pop_sr
	add	xbc, xiz
	sll	xbc, 4
	add	xbc, 80
	.byte 0xaf, 0x06
	or	(xbc), c
	.byte 0x88
	calr	63930
	incm	1, (xsp+4)
	ld	a, (xsp+440)
	inc	1, a
	extz	wa
	cp	(xsp+4), wa
	jr	c, -95
	lds	hl, 0
	jr	3

HdaeRom_DataDispatch_SetWord:
	ldw hl, 0xff9a
	pop xiz
	st_dri3b L, 0xfd, 0xb8, 0x01
	ret

HdaeRom_DataDispatch_Block:
	lda_24 xde, 0x1e0000
	lda_24 xwa, 0xeed56c
	ld xbc, xwa
	lda xhl, (xwa + 16)

HdaeRom_DataDispatch_Block2:
	ld_spib A, 0xe4
	lda_dpi XBC, 0xe8
	cp xbc, xhl
	jr c, HdaeRom_DataDispatch_Block2
	calr SendPartDataBlock_SetWord7
	lds hl, 0
	ret

HdaeRom_DataDispatch_Block3:
	lda	xhl, (xwa+18833)
	.byte 0xf3, 0xe1, 0xa7
	jrl	le, -5068
	jr	ge, -21
	.byte 0xf4
	jr	c, 16
	lda	xde, (xix-1)
	ld	c, (xde)
	ld	(xde+1), c
	dec	1, xde
	dec	1, xix
	cp	xix, xhl
	jr	nc, -13
	ld	(xhl), 1
	.byte 0xc7
	lds32	xde, 0
	lds	de, 0
	ld	bc, de
	add	bc, 18855
	.byte 0xf3
	reti
	.byte 0xe0, 0xe4
	ldw	hl, 395
	push	xix
	.byte 0xcf
	exts	xbc
	add	xbc, xwa
	.byte 0xb9, 0x01, 0xbd, 0xc7
	inc	1, xde
	inc	2, de
	.byte 0xc7
	cp	xde, 249522048

; HDAE ROM alt dispatch handler
HdaeRom_AltHandler:
	pushw iz
	ld xwa, 0x1e0000
	calr SendPartDataBlock_InitVal4
	extz hl
	dec 1, hl
	cps hl, 0
	jr lt, HdaeRom_AltDispatch_SetWord
	cps hl, 5
	jr gt, HdaeRom_AltDispatch_SetWord
	add hl, hl
	lda_24 xix, 0xeed753
	ld_sriw3 HL, 0x07, 0xf0, 0xec
	lda_24 xix, HdaeRom_AltDispatch
	jp_dri 8, 0x07, 0xf0, 0xec
; HDAE5000 extension ROM alt dispatch (6-entry, table 0xeed753)
HdaeRom_AltDispatch:
	ld	xwa, 1966080
	calr	-125
	lds	iz, 0
	jr	3

HdaeRom_AltDispatch_SetWord:
	ldw iz, 0xff9a
	lda_24 xde, 0x1e0000
	lda_24 xwa, 0xeed56c
	ld xbc, xwa
	lda xhl, (xwa + 16)

HdaeRom_AltDispatch_Block:
	ld_spib A, 0xe4
	lda_dpi XBC, 0xe8
	cp xbc, xhl
	jr c, HdaeRom_AltDispatch_Block
	calr SendPartDataBlock_SetWord7
	ld hl, iz
	popw iz
	ret

PreTmLoad:
	ret

PostTmLoad:
	cps wa, 0
	jr lt, PostTmLoad_Send
	ldw wa, 0xff
	ldw bc, 0xff
	calr HdaeRom_DataHandler
	ldw wa, 0xff
	ldw bc, 0xff
	calr HdaeRom_AltHandler
	calr HdaeRom_DataDispatch_Block
	ld xwa, 0x1e0000
	ldw bc, 0x72aa
	ld xde, 0x7800
	call InterCPU_E1_Bulk_Transfer
	ldw wa, 0xff
	ldw bc, 0xff
	call BuildAndSendPacket_Block
	jr PostTmLoad_Block

PostTmLoad_Send:
	ldw wa, 0xff
	ldw bc, 0xff
	call COMM_BuildAndSendPacket

PostTmLoad_Block:
	jp FDemoText_RefreshFullDisplay

PreTmSave:
	ret

PostTmSave:
	cps wa, 0
	ret ge
	ldw wa, 0xff
	ldw bc, 0xff
	call COMM_BuildAndSendPacket
	ret

PostTmSave_ByteBlock:
	calr	64567
	cps	l, 6
	jr	ugt, 7
	cps	l, 1
	jr	c, 3
	lds	hl, 0
	ret
	ldw	hl, 65434
	ret

PostTmSave_Success:
	cps wa, 0
	jr lt, PostTmSave_Failure
	ldw wa, 0xff
	ldw bc, 0xff
	calr HdaeRom_DataHandler
	ldw wa, 0xff
	ldw bc, 0xff
	calr HdaeRom_AltHandler
	calr HdaeRom_DataDispatch_Block
	ld xwa, 0x1e0000
	ldw bc, 0x72aa
	ld xde, 0x7800
	call InterCPU_E1_Bulk_Transfer
	ldw wa, 0xff
	ldw bc, 0xff
	call BuildAndSendPacket_Block
	jr PostTmSave_JumpToRestore

PostTmSave_Failure:
	ldw wa, 0xff
	ldw bc, 0xff
	call COMM_BuildAndSendPacket

PostTmSave_JumpToRestore:
	jp FDemoText_RefreshFullDisplay
TmFlashWrite_Block1:
	ret
	dec	4, xsp
	ld	(xsp), c
	ld	(xsp+2), a
	ld	a, (xsp+2)
	extz	wa
	ld	c, (xsp)
	extz	bc
	cps	de, 0
	jr	lt, 123
	.byte 0x8f
	push_sr
	push	xsp
	ld	xwa, 3860739951
	swi	4
	calr	65137
	ld	c, (xsp)
	extz	bc
	ld	a, (xsp+2)
	extz	wa
	mul	wa, 20
	add	wa, bc
	extz	xwa
	ld	xbc, 470
	call	Math_MultiplyAccumulate
	add	xhl, 16
	ld	xwa, 1966080
	add	xwa, xhl
	lda	xde, (xhl+30720)
	ldw	bc, 470
	jr	43
	calr	65190
	calr	65082
	ld	a, (xsp)
	extz	wa
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 4
	add	xbc, 19111
	ld	xwa, 1966080
	add	xwa, xbc
	.byte 0xf3, 0xe5
	nop
	.asciz "x21P"
	call	InterCPU_E1_Bulk_Transfer
	ld	a, (xsp+2)
	extz	wa
	ld	c, (xsp)
	extz	bc
	call	BuildAndSendPacket_Block
	jr	4
	call	COMM_BuildAndSendPacket
	call	FDemoText_RefreshFullDisplay
	inc	4, xsp
	ret
	ret
	dec	2, xsp
	push	xiz
	ld	(xsp+4), a
	cps	bc, 0
	jrl	lt, 135
	lds	iz, 0
	.byte 0x8f, 0x04
	.ascii "?@oH"
	.byte 0x04
	ldb	a, 216
	ccf
	.byte 0xc7
	swi	0
	.byte 0x8b
	extz	bc
	calr	64584
	inc	1, iz
	cp	iz, 20
	jr	c, -21
	calr	64971
	ld	a, (xsp+4)
	.byte 0xc7
	swi	0
	.byte 0x99
	extz	iz
	mul	iz, 20
	ld	wa, iz
	extz	xwa
	ld	xbc, 470
	call	Math_MultiplyAccumulate
	add	xhl, 16
	ld	xwa, 1966080
	add	xwa, xhl
	.byte 0xf3, 0xed
	nop
	jrl	12594
	.byte 0xb8
	ldb	d, 104
	ldb	e, 143
	.byte 0x04
	ldb	a, 216
	ccf
	.byte 0xc7
	swi	0
	.byte 0x8b
	extz	bc
	calr	65015
	inc	1, iz
	cp	iz, 128
	jr	c, -21
	calr	64899
	lda_24	xwa, 1985191
	ldw	bc, 10240
	.byte 0x42
TmFlashWrite_Block2:
	.byte 0xa7, 0xc2
	nop
	nop
TmFlashWrite_Block3:
	call	InterCPU_E1_Bulk_Transfer
	ld	a, (xsp+4)
	extz	wa
	ldw	bc, 255
	call	BuildAndSendPacket_Block
	jr	12
	ld	a, (xsp+4)
	extz	wa
	ldw	bc, 255
	call	COMM_BuildAndSendPacket
	call	FDemoText_RefreshFullDisplay
	pop	xiz
	.byte 0xef
	jr	le, 0x0e

TmFlash_CopyToExtMem:
	lda_24 xwa, 0x300000
	add xwa, 0xb0400
	ldw bc, 0xee1f
	ld xde, 0xa0000
	call InterCPU_E1_Bulk_Transfer
	jp TmFlash_Return
TmFlash_WriteRoutine:
	lda	xsp, (xsp-18)
	push	xiz
	ld	(xsp+14), xde
	ld	(xsp+18), bc
	ld	(xsp+20), a
	ld	(xsp+4), 0
	ld	wa, (xsp+18)
	extz	xwa
	ld	(xsp+10), xwa
	ld	xbc, 470
	call	Math_MultiplyAccumulate
	add	xhl, 16
	bitm	0, (xsp+20)
	jr	z, 96
	lda_24	xiz, 3145728
	add	xiz, 721920
	ld	xde, xiz
	bitm	1, (xsp+20)
	jr	z, 59
	cpw	(xsp+18), 4
	jr	nc, 36
	ld	xwa, (xsp+14)
	ld	(xsp+6), xwa
	ld	xwa, (xsp+10)
	ld	xbc, 10535
	call	Math_MultiplyAccumulate
	add	xhl, 18816
	add	xhl, xiz
	ld	xwa, (xsp+6)
	.byte 0xb0
	.ascii "c0')hT"
	ld	(xsp+4), 255
	ld	l, (xsp+4)
	exts	hl
	pop	xiz
	lda	xsp, (xsp+18)
	retd	4
	.byte 0x9f
	ccf
	push	xsp
	pushw	wa
	nop
	jr	nc, -23
	add	xhl, xde
	ld	xwa, (xsp+14)
	ld	(xwa), xhl
	ldw	wa, 470
	jr	49
	lda_24	xbc, 1966080
	.byte 0xbf
	push_a
	inc	6, a
	ex_ff
	.byte 0x9f
	ccf
	push	xsp
	.byte 0x01
	nop
	jr	nc, -52
	.byte 0xf3, 0xe5, 0x80
	popw	bc
	ldw	bc, 3759
	ldb	w, 176
	.byte 0x61
	.ascii "0')h"
	scf
	.byte 0x9f
	ccf
	push	xsp
	pushw	wa
	nop
	jr	nc, -74
	add	xbc, xhl
	ld	xwa, (xsp+14)
	ld	(xwa), xbc
	ldw	wa, 470
	ld	xbc, (xsp+26)
	ld	(xbc), wa
	jr	-87
	ld	xwa, 1966080
	ldw	bc, 29354
	ld	xde, 30720
	call	InterCPU_E1_Bulk_Transfer
	jp	TmFlash_Return
	ld	xwa, 1966080
	calr	63909
	ldw	wa, 65434
	cps	l, 6
	jr	nz, 2
	lds	wa, 0
	ld	hl, wa
	ret
	ld	xwa, 1966080
	calr	63889
	cps	l, 6
	jr	ugt, 7
	cps	l, 1
	jr	c, 3
	lds	hl, 0
	ret
	ldw	hl, 65434
	ret
	extz	xwa
	ld	xbc, 470
	call	Math_MultiplyAccumulate
	ld	xwa, xhl
	add	xwa, 16
	ld	xhl, 1966080
	add	xhl, xwa
	ret
	dec	4, xsp
	pushw	iz
	ld	iz, bc
	ld	(xsp+2), xwa
	ld	xwa, (xsp+2)
	calr	63833
	ld	wa, iz
	extz	xwa
	extz	hl
	dec	1, hl
	cps	hl, 0
	jr	lt, 76
	cps	hl, 5
	jr	gt, 72
	add	hl, hl
	lda_24	xix, 15652703
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	c, 242
	swi	3
	reti
	swi	7
	ldw	ix, 2035
	.byte 0xf0
	cps	xix, 0
	ld	xbc, 470
	jr	5
	ld	xbc, 289
	call	Math_MultiplyAccumulate
	add	xhl, 16
	.byte 0xaf
	push_sr
	decm8	8, (xhl)
	.byte 0x1c
	ld	xbc, xwa
	sll	xbc, 3
	add	xbc, xwa
	sll	xbc, 4
	add	xbc, 80
	.byte 0xaf
	push_sr
	or	(xbc), a
	.byte 0x8b
	jr	5
	ld	xhl, 4294967194
	popw	iz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	cp	wa, 40
	jr	nc, 39
	ld	xiz, xbc
	extz	xwa
	ld	xbc, 470
	call	Math_MultiplyAccumulate
	add	xhl, 16
	ld	xwa, 1966080
	add	xwa, xhl
	ld	(xiz), xwa
	ld	xwa, (xsp+4)
	.byte 0xb0
	push_sr
	.byte 0xd6, 0x01
	lds	hl, 0
	jr	3
	ldw	hl, 65336
	pop	xiz
	inc	4, xsp
	ret
	dec	8, xsp
	pushw	iz
	ld	(xsp+2), xde
	ld	iz, bc
	ld	(xsp+6), xwa
	ld	xwa, (xsp+6)
	calr	63661
	ld	bc, iz
	extz	xbc
	extz	hl
	dec	1, hl
	cps	hl, 0
	jrl	lt, 134
	cps	hl, 5
	jrl	gt, 129
	add	hl, hl
	lda_24	xix, 15652715
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	c, 242
	cp	(xbc+8), xsp
	ldw	ix, 2035
	.byte 0xf0
	cps	xix, 0
	ld	xwa, xbc
	ld	xbc, 470
	call	Math_MultiplyAccumulate
	add	xhl, 16
	.byte 0xaf, 0x06
	sub	(xhl), l
	.byte 0x06
	sub	(xhl), xsp
	push_sr
	ldb	w, 176
	jr	ule, 48
	.byte 0xd6, 0x01
	jr	65
	ld	xwa, xbc
	ld	xbc, 289
	call	Math_MultiplyAccumulate
	add	xhl, 16
	.byte 0xaf, 0x06
	sub	(xhl), l
	.byte 0x06
	sub	(xhl), xsp
	push_sr
	ldb	w, 176
	jr	ule, 48
	ldb	a, 1
	jr	32
	ld	xwa, xbc
	sll	xwa, 3
	add	xwa, xbc
	sll	xwa, 4
	add	xwa, 80
	ld	xhl, xwa
	.byte 0xaf, 0x06
	sub	(xhl), l
	.byte 0x06
	sub	(xhl), xsp
	push_sr
	ldb	w, 176
	jr	ule, 48
	.byte 0x90
	nop
	ld	xbc, (xsp+14)
	ld	(xbc), wa
	lds	hl, 0
	jr	3
	ldw	hl, 65434
	popw	iz
	inc	8, xsp
	retd	4
	dec	6, xsp
	push	xiz
	ld	xwa, (xsp+18)
	ld	a, (xwa)
	ld	(xsp+8), a
	ld	xiz, (xsp+14)
	push	xiz
	call	Strlen
	ld	(xsp+8), hl
	ld	xwa, (xsp+22)
	push	xwa
	call	Strlen
	inc	8, xsp
	ld	(xsp+6), hl
	.byte 0x9f, 0x06
	push	xsp
	nop
	nop
	jr	z, 31
	jr	38
	ld	a, (xsp+8)
	.byte 0x86, 0xf1
	jr	nz, 26
	.byte 0x9f
	ei	4
	push	xiz
	ld	xwa, (xsp+24)
	push	xwa
	call	Mem_Compare
	add	xsp, 10
	cps	hl, 0
	jr	nz, 4
	ld	xhl, xiz
	jr	15
	inc	1, xiz
	decm	1, (xsp+4)
	ld	wa, (xsp+6)
	.byte 0x9f, 0x04, 0xf0
	jr	ule, -46
	lds32	xhl, 0
	pop	xiz
	inc	6, xsp
	ret

StrSearch_Init:
	ld xbc, (xsp + 4)
	lds hl, 0
	jr StrSearch_CheckHaystackEnd

StrSearch_LoadNeedle:
	ld xde, (xsp + 8)
	jr StrSearch_CheckNeedleEnd

StrSearch_CompareChar:
	ld a, (xde)
	cp a, (xbc)
	ret z
	inc 1, xde

StrSearch_CheckNeedleEnd:
	cp (xde), 0x0
	jr nz, StrSearch_CompareChar
	inc 1, xbc
	inc 1, hl

StrSearch_CheckHaystackEnd:
	cp (xbc), 0x0
	jr nz, StrSearch_LoadNeedle
	ret

ParseInt16:
	ld xhl, (xsp + 4)
	lds iy, 0
	lds ix, 0
	lda_24 xbc, 0xeed778
	jr ParseInt16_CheckWhitespace

ParseInt16_SkipWhitespace:
	inc 1, xhl

ParseInt16_CheckWhitespace:
	ld a, (xhl)
	extz wa
	bit_dri 3, 0x07, 0xe4, 0xe0
	jr nz, ParseInt16_SkipWhitespace
	cp (xhl), 0x2d
	jr nz, ParseInt16_CheckMinus
	lds ix, 1
	jr ParseInt16_SkipSign

ParseInt16_CheckMinus:
	cp (xhl), 0x2b
	jr nz, ParseInt16_DigitLoop

ParseInt16_SkipSign:
	inc 1, xhl

ParseInt16_DigitLoop:
	ld_spib E, 0xec
	exts de
	ld a, e
	extz wa
	bit_dri 2, 0x07, 0xe4, 0xe0
	jr z, ParseInt16_ApplySign
	sub de, 0x30
	muls iy, 0xa
	add iy, de
	jr ParseInt16_DigitLoop

ParseInt16_ApplySign:
	cps ix, 0
	jr z, ParseInt16_Positive
	ld wa, iy
	neg wa
	ld hl, wa
	jr ParseInt16_Return

ParseInt16_Positive:
	ld hl, iy

ParseInt16_Return:
	ret

ParseInt32:
	ld xhl, (xsp + 4)
	lds32 xiy, 0
	lds ix, 0
	lda_24 xbc, 0xeed778
	jr ParseInt32_CheckWhitespace

ParseInt32_SkipWhitespace:
	inc 1, xhl

ParseInt32_CheckWhitespace:
	ld a, (xhl)
	extz wa
	bit_dri 3, 0x07, 0xe4, 0xe0
	jr nz, ParseInt32_SkipWhitespace
	cp (xhl), 0x2d
	jr nz, ParseInt32_CheckMinus
	lds ix, 1
	jr ParseInt32_SkipSign

ParseInt32_CheckMinus:
	cp (xhl), 0x2b
	jr nz, ParseInt32_DigitLoop

ParseInt32_SkipSign:
	inc 1, xhl

ParseInt32_DigitLoop:
	ld_spib E, 0xec
	exts de
	ld a, e
	extz wa
	bit_dri 2, 0x07, 0xe4, 0xe0
	jr z, ParseInt32_ApplySign
	sub de, 0x30
	ld wa, de
	exts xwa
	ld xde, xiy
	sla xde, 2
	add xde, xiy
	add xde, xde
	ld xiy, xde
	add xiy, xwa
	jr ParseInt32_DigitLoop

ParseInt32_ApplySign:
	cps ix, 0
	jr z, ParseInt32_Positive
	ld xwa, xiy
	cpl wa
	cpl_werp 0xe2
	inc 1, xwa
	ld xhl, xwa
	jr ParseInt32_Return

ParseInt32_Positive:
	ld xhl, xiy

ParseInt32_Return:
	ret

Math_MultiplyAccumulate:
	ldto_werp HL, 0xe2
	mul xhl, xbc
	ldto_werp DE, 0xe6
	mul xde, xwa
	add xhl, xde
	ldfr_werp HL, 0xee
	lds hl, 0
	mul xwa, xbc
	add xhl, xwa
	ret

; =============================================================================
; Audio_SendCommand -- Send sound parameter command to Sub CPU
; =============================================================================
; Primary interface for all Main CPU -> Sub CPU audio parameter updates.
; Acquires audio lock #7, formats command via Audio_CommandEncoder (printf-like
; format string parser), writes to ring buffer at 0xbd3c via AssswbWr.
; Referenced by 197+ locations (every Lsw* function, preset loaders, etc.).
; Args: xwa = format string pointer, stack = format arguments
Audio_SendCommand:
	dec 4, xsp
	pushw iz
	lds wa, 7
	call Audio_Lock_Acquire
	ld xwa, (xsp + 10)
	st32_24 0x03c21c, xwa
	ld xwa, (xsp + 10)
	ld (xwa), 0x0
	lda xwa, (xsp + 14)
	inc 4, xwa
	ld (xsp + 2), xwa
	pushw 0xff
	pushw 0xad8
	lda xwa, (xsp + 6)
	push xwa
	ld xwa, (xsp + 22)
	push xwa
	call Audio_CommandEncoder
	lda xsp, (xsp + 12)
	ld iz, hl
	lds wa, 7
	call Audio_Lock_Release
	ld hl, iz
	popw iz
	inc 4, xsp
	ret

Audio_SendCommand_Block:
	ld	xwa, (xsp+4)
	st32_24	246300, xwa
	ld	xwa, (xsp+4)
	ld	(xwa), 0
	pushw	255
	pushw	2776
	lda	xwa, (xsp+16)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	Audio_CommandEncoder
	lda	xsp, (xsp+12)
	ret
	ld32_24	xbc, 246300
	lds32	xwa, 1
	addm32_24	246300, xwa
	ld	wa, (xsp+4)
	ld	(xbc), a
	ld32_24	xwa, 246300
	ld	(xwa), 0
	ret

Free:
	ld xwa, (xsp + 4)
	or xwa, xwa
	ret z
	lds wa, 1
	call TaskSched_WaitForEvent
	ld xbc, (xsp + 4)
	dec 6, xbc
	ld32_24 xwa, 0x03d52c
	or xwa, xwa
	jr nz, Free_Block
	lds32 xwa, 0
	ld (xbc), xwa
	st32_24 0x03d52c, xbc
	lds wa, 1
	jp TaskSched_SignalEvent

Free_Block:
	ld32_24 xix, 0x03d52c
	ld xde, xix
	or xix, xix
	jr z, Free_Compare2

Free_Compare:
	cp xbc, xix
	jr ule, Free_Compare2
	ld xde, xix
	ld xix, (xix)
	or xix, xix
	jr nz, Free_Compare

Free_Compare2:
	cp xbc, xix
	jr nz, Free_LoadReg
	lds wa, 1
	jp TaskSched_SignalEvent

Free_LoadReg:
	ld hl, (xbc + 4)
	extz xhl
	ld xwa, xbc
	inc 6, xwa
	add xwa, xhl
	cpda32_24 xix, 251180
	jr nz, Free_OrBits
	cpda32_24 xwa, 251180
	jr nz, Free_Block2
	ld32_24 xwa, 0x03d52c
	ld xwa, (xwa)
	ld (xbc), xwa
	ld32_24 xwa, 0x03d52c
	ld wa, (xwa + 4)
	inc 6, wa
	add (xbc + 4), wa
	jr Free_Block3

Free_Block2:
	ld32_24 xwa, 0x03d52c
	ld (xbc), xwa

Free_Block3:
	st32_24 0x03d52c, xbc
	lds wa, 1
	jp TaskSched_SignalEvent

Free_OrBits:
	or xix, xix
	jr z, Free_LoadReg2
	cp xwa, xix
	jr nz, Free_LoadReg2
	ld xwa, (xix)
	ld (xbc), xwa
	ld wa, (xix + 4)
	add wa, (xbc + 4)
	inc 6, wa
	ld (xbc + 4), wa
	jr Free_LoadReg3

Free_LoadReg2:
	ld (xbc), xix

Free_LoadReg3:
	ld hl, (xde + 4)
	extz xhl
	ld xwa, xde
	inc 6, xwa
	add xwa, xhl
	cp xwa, xbc
	jr nz, Free_LoadReg4
	ld xwa, (xbc)
	ld (xde), xwa
	ld wa, (xbc + 4)
	add wa, (xde + 4)
	inc 6, wa
	ld (xde + 4), wa
	jr Free_InitVal

Free_LoadReg4:
	ld (xde), xbc

Free_InitVal:
	lds wa, 1
	jp TaskSched_SignalEvent

Free_ClearByte:
	ldb e, 0x0
	bit_erpw 0xe2, 0x0f
	jr z, Free_Block4
	ldb e, 0x1
	cpl_werp 0xe2
	cpl wa
	inc 1, xwa

Free_Block4:
	bit_erpw 0xe6, 0x0f
	jr z, Free_Prologue
	or e, 0x2
	cpl_werp 0xe6
	cpl bc
	inc 1, xbc

Free_Prologue:
	pushw de
	calr Math_DivideU32
	popw wa
	cps w, 1
	jr z, Free_Compare3
	ld xhl, xde
	bit 0, a
	scc8 nz, a
	jr Free_OrBits2

Free_Compare3:
	cps a, 3
	ret z

Free_OrBits2:
	or xhl, xhl
	ret z
	cps a, 0
	ret z
	cpl_werp 0xee
	cpl hl
	inc 1, xhl
	ret

Free_ClearByte2:
	ldb d, 0x0
	jr Free_ClearByte

Math_DivideSigned32:
	ldb d, 0x1
	jr Free_ClearByte

DivMod32:
	calr Math_DivideU32
	ld xhl, xde
	ret

Math_DivideU32:
	cp xbc, 0x1
	jr z, Math_DivideU32_LoadReg
	jr c, Math_DivideU32_Block2
	cp xwa, xbc
	jr ule, Math_DivideU32_Block3
	cpi_werp 0xe6, 0
	jr nz, Math_DivideU32_ClearByte
	ld xde, xwa
	div xwa, xbc
	jr ov, Math_DivideU32_Block
			; Note: OV (Overflow) is the same as PE = Parity Even
	lds32 xhl, 0
	ld xde, xhl
	ld hl, wa
	ldto_werp DE, 0xe2
	ret

Math_DivideU32_Block:
	ldto_werp WA, 0xea
	extz xwa
	div xwa, xbc
	ldfr_werp WA, 0xee
	ld wa, de
	div xwa, xbc
	ld hl, wa
	ldto_werp DE, 0xe2
	extz xde
	ret

Math_DivideU32_LoadReg:
	ld xhl, xwa
	lds32 xde, 0
	ret

Math_DivideU32_Block2:
	lds32 xhl, 0
	ld xde, xhl
	dec 1, xhl
	ret

Math_DivideU32_Block3:
	lds32 xhl, 1
	lds32 xde, 0
	ret z
	dec 1, xhl
	ld xde, xwa
	ret

Math_DivideU32_ClearByte:
	ldb d, 0x0

Math_DivideU32_Compare:
	cp xwa, xbc
	jr c, Math_DivideU32_Shift
	inc 1, d
	add xbc, xbc
	jr nc, Math_DivideU32_Compare
	rr xbc
	jr Math_DivideU32_Block4

Math_DivideU32_Shift:
	srl xbc, 1

Math_DivideU32_Block4:
	lds32 xhl, 0

Math_DivideU32_Compute:
	add xhl, xhl
	cp xwa, xbc
	jr c, Math_DivideU32_Shift2
	set 0, l
	sub xwa, xbc

Math_DivideU32_Shift2:
	srl xbc, 1
	djnz8 d, Math_DivideU32_Compute
	ld xde, xwa
	ret

Strncat:
	ld xix, (xsp + 4)
	ld xhl, xix
	jr Strncat_CheckZero

Strncat_NextIter:
	inc 1, xix

Strncat_CheckZero:
	cp (xix), 0x0
	jr nz, Strncat_NextIter
	ld xde, (xsp + 8)
	ld bc, (xsp + 12)
	jr Strncat_LoadReg2

Strncat_LoadReg:
	ld a, (xde)
	ld (xix), a
	cp (xix), 0x0
	ret z
	inc 1, xix
	inc 1, xde

Strncat_LoadReg2:
	ld wa, bc
	dec 1, bc
	cps wa, 0
	jr nz, Strncat_LoadReg
	ld (xix), 0x0
	ret

String_Compare:
	ld bc, (xsp + 12)
	ld xde, (xsp + 8)
	ld xix, (xsp + 4)
	jr String_Compare_Compare

String_Compare_CheckZero:
	cp (xix), 0x0
	jr nz, String_Compare_NextIter
	lds hl, 0
	ret

String_Compare_NextIter:
	inc 1, xix
	inc 1, xde
	dec 1, bc

String_Compare_Compare:
	cps bc, 0
	jr z, String_Compare_ClearByte
	ld a, (xde)
	cp a, (xix)
	jr z, String_Compare_CheckZero

String_Compare_ClearByte:
	ldb l, 0x0
	cps bc, 0
	jr z, String_Compare_Extend
	ld a, (xix)
	sub a, (xde)
	ld l, a

String_Compare_Extend:
	exts hl
	ret

; Strncpy -- Copy string with length limit, zero-pad remainder
; Args: (xsp+4)=dest, (xsp+8)=src, (xsp+12)=maxlen
Strncpy:
	ld bc, (xsp + 12)
	ld xde, (xsp + 8)
	ld xix, (xsp + 4)
	ld xhl, xix
	jr Strncpy_Compare

Strncpy_Block:
	ld_spib A, 0xe8
	lda_dpi XBC, 0xf0
	dec 1, bc

Strncpy_Compare:
	cps bc, 0
	jr z, Strncpy_Block2
	cp (xde), 0x0
	jr nz, Strncpy_Block

Strncpy_Block2:
	jr Strncpy_Compare2

Strncpy_Block3:
	stib_dpi 0xf0, 0x00
	dec 1, bc

Strncpy_Compare2:
	cps bc, 0
	jr nz, Strncpy_Block3
	ret

; Mem_Compare -- Compare two memory blocks byte-by-byte
; Returns: 0 if equal, nonzero if different
Mem_Compare:
	ld bc, (xsp + 12)
	lds hl, 0
	cps bc, 0
	ret z
	ld xix, (xsp + 4)
	ld xiy, (xsp + 8)
	cp xix, xiy
	ret z
	ld de, ix
	neg de
	and de, 0x3
	jr z, Mem_Compare_LoadReg

Mem_Compare_Block:
	ld_spib L, 0xf0
	extz hl
	ld_spib A, 0xf4
	extz wa
	sub hl, wa
	ret nz
	sub bc, 0x1
	ret z
	djnz xde, Mem_Compare_Block

Mem_Compare_LoadReg:
	ld de, bc
	srl bc, 2
	jr z, Mem_Compare_MaskBits

Mem_Compare_Block2:
	ld_spil XHL, 0xf2
	ld_spil XWA, 0xf6
	cp xhl, xwa
	jr z, Mem_Compare_Block3
	cp hl, wa
	jr nz, Mem_Compare_Compare
	ldto_werp HL, 0xee
	ldto_werp WA, 0xe2

Mem_Compare_Compare:
	cp l, a
	jr nz, Mem_Compare_Extend
	ld l, h
	ld a, w

Mem_Compare_Extend:
	extz hl
	extz wa
	sub hl, wa
	ret

Mem_Compare_Block3:
	djnz xbc, Mem_Compare_Block2
	lds hl, 0

Mem_Compare_MaskBits:
	and de, 0x3
	ret z

Mem_Compare_Block4:
	ld_spib L, 0xf0
	extz hl
	ld_spib A, 0xf4
	extz wa
	sub hl, wa
	ret nz
	djnz xde, Mem_Compare_Block4
	ret

Mem_Copy:
	ld bc, (xsp + 12)
	ld xhl, (xsp + 4)
	cps bc, 0
	ret z
	ld xix, xhl
	ld xiy, (xsp + 8)
	cp xix, xiy
	ret z
	bit 0, ix
	jr z, Mem_Copy_Shift
	ldi85
	ret nov

Mem_Copy_Shift:
	srl bc, 1
	jr z, Mem_Copy_Block
	ldirw

Mem_Copy_Block:
	ret nc
	ldi85
	ret

; ============================================================================
; Strcat - Concatenate strings (C runtime)
; ============================================================================
; Input:  Stack arg1 = destination string pointer
;         Stack arg2 = source string pointer
; Output: XHL = original destination pointer
; Finds null terminator in dest, then copies src bytes until null.
; Located near Strcpy and Strlen (standard C library functions).
; ============================================================================
Strcat:
	ld xde, (xsp + 4)
	ld xhl, xde
	jr Strcat_CheckZero

Strcat_NextIter:
	inc 1, xde

Strcat_CheckZero:
	cp (xde), 0x0
	jr nz, Strcat_NextIter
	ld xbc, (xsp + 8)
	jr Strcat_CheckZero2

Strcat_Block:
	ld_spib A, 0xe4
	lda_dpi XBC, 0xe8

Strcat_CheckZero2:
	cp (xbc), 0x0
	jr nz, Strcat_Block
	ld (xde), 0x0
	ret

Itoa_Safe:
	lda xsp, (xsp - 18)
	push xiz
	ld xhl, (xsp + 28)
	lds ix, 0
	ld bc, (xsp + 32)
	cps bc, 2
	jr lt, Itoa_Safe_LoadReg
	cp bc, 0x24
	jr le, Itoa

Itoa_Safe_LoadReg:
	ld (xhl), 0x0
	jr NumFormat_DivideAndC_Epilogue

; ============================================================================
; Itoa - Convert integer to ASCII string (C runtime)
; ============================================================================
; Input:  (xsp+26) = workspace register set selector
;         BC = numeric base (e.g., 10 for decimal)
;         XIZ+4 = output buffer pointer
; Output: Null-terminated string written to buffer
; Converts an integer to its string representation in the given base.
; Handles negative numbers when base is 10 (prepends '-'). Digits above
; 9 use lowercase letters (a-f). Uses repeated division algorithm.
; ============================================================================
Itoa:
	ld wa, (xsp + 26)
	ldfr_werp WA, 0xe6
	lda xiz, (xsp + 4)
	ld (xiz + 17), 0x0
	lda xiy, (xiz + 16)
	cp bc, 0xa
	jr nz, NumFormat_DivideAndConvert
	ldto_werp WA, 0xe6
	cps wa, 0
	jr ge, NumFormat_DivideAndConvert
	lds ix, 1
	ldto_werp WA, 0xe6
	neg wa
	ldfr_werp WA, 0xe6

NumFormat_DivideAndConvert:
	ld de, bc
	ldto_werp WA, 0xe6
	extz xwa
	div xwa, xde
	ldto_werp WA, 0xe2
	add a, 0x30
	ld (xiy), a
	cp (xiy), 0x39
	jr le, NumFormat_DivideAndC_Block
	addmi8 (xiy), 0x27

NumFormat_DivideAndC_Block:
	ldto_werp WA, 0xe6
	extz xwa
	div xwa, xde
	ldfr_werp WA, 0xe6
	cpi_werp 0xe6, 0
	jr z, NumFormat_DivideAndC_Compare
	dec 1, xiy
	jr NumFormat_DivideAndConvert

NumFormat_DivideAndC_Compare:
	cps ix, 0
	jr z, NumFormat_DivideAndC_LoadAddr
	stib_dpd 0xf4, 0x2d

NumFormat_DivideAndC_LoadAddr:
	lda xwa, (xiz + 18)
	sub xwa, xiy
	pushw wa
	push xiy
	push xhl
	call Mem_Copy
	lda xsp, (xsp + 10)

NumFormat_DivideAndC_Epilogue:
	pop xiz
	lda xsp, (xsp + 18)
	ret

NumFormat_DivideAndC_Data:
	ld	xhl, (xsp+4)
	ld	wa, (xsp+8)
	.byte 0x83, 0xf1
	ret	z
	.byte 0xc5, 0xec
	push	xsp
	nop
	jr	nz, -10
	lds32	xhl, 0
	ret

Malloc:
	dec 6, xsp
	push xiz
	ld wa, (xsp + 14)
	inc 1, wa
	srl wa, 1
	ld (xsp + 8), wa
	add (xsp + 8), wa
	lds wa, 1
	call TaskSched_WaitForEvent
	ld32_24 xiz, 0x03d52c
	or xiz, xiz
	jr z, Malloc_OrBits

Malloc_LoadReg:
	ld wa, (xiz + 4)
	cp wa, (xsp + 8)
	jr nc, Malloc_OrBits
	ld (xsp + 4), xiz
	ld xiz, (xiz)
	or xiz, xiz
	jr nz, Malloc_LoadReg

Malloc_OrBits:
	or xiz, xiz
	jr z, Malloc_LoadParam2
	ld wa, (xiz + 4)
	sub wa, (xsp + 8)
	cp wa, 0xa
	jr c, Malloc_Block
	ld wa, (xsp + 8)
	extz xwa
	inc 6, xwa
	ld xbc, xiz
	add xbc, xwa
	ld xwa, (xiz)
	ld (xbc), xwa
	ld wa, (xiz + 4)
	dec 6, wa
	sub wa, (xsp + 8)
	ld (xbc + 4), wa
	ld (xiz), xbc
	ld wa, (xsp + 8)
	ld (xiz + 4), wa

Malloc_Block:
	cpda32_24 xiz, 251180
	jr nz, Malloc_LoadParam
	ld xwa, (xiz)
	st32_24 0x03d52c, xwa
	jr Malloc_DoSignalEv

Malloc_LoadParam:
	ld xwa, (xsp + 4)
	ld xbc, (xiz)
	ld (xwa), xbc
	jr Malloc_DoSignalEv

Malloc_LoadParam2:
	ld wa, (xsp + 8)
	inc 6, wa
	extz xwa
	call Heap_Alloc
	ld xiz, xhl
	ld xwa, xiz
	cp xwa, 0xffffffff
	jr nz, Malloc_Block2
	lds wa, 1
	call TaskSched_SignalEvent
	lds32 xhl, 0
	jr Malloc_Epilogue

Malloc_Block2:
	lds32 xwa, 0
	ld (xiz), xwa
	ld wa, (xsp + 8)
	ld (xiz + 4), wa

Malloc_DoSignalEv:
	lds wa, 1
	call TaskSched_SignalEvent
	inc 6, xiz
	ld xhl, xiz

Malloc_Epilogue:
	pop xiz
	inc 6, xsp
	ret

; ============================================================================
; Strcmp - Compare two strings (C runtime)
; ============================================================================
; Input:  (xsp+8) = pointer to string 1 (XIZ)
;         (xsp+18) = pointer to string 2 (XWA)
; Output: HL = comparison result (0 = equal)
; Computes length of string 1 via Strlen, then calls Mem_Compare to compare
; that many bytes between the two strings.
; ============================================================================
Strcmp:
	push xiz
	ld xiz, (xsp + 8)
	push xiz
	call Strlen
	pushw hl
	ld xwa, (xsp + 18)
	push xwa
	push xiz
	call Mem_Compare
	lda xsp, (xsp + 14)
	pop xiz
	ret

Strcpy:
	push xiz
	pushw 0xfffe
	pushw 0x0
	ld xwa, (xsp + 16)
	push xwa
	ld xiz, (xsp + 16)
	push xiz
	call AudioCmd_StringNSearch
	add xsp, 0xc
	or xhl, xhl
	jr nz, Strcpy_LoadReg
	ld xwa, xiz
	add xwa, 0xffff
	ld (xwa), 0x0

Strcpy_LoadReg:
	ld xhl, xiz
	pop xiz
	ret

; ============================================================================
; Heap_Alloc - Allocate memory from the heap (C runtime)
; ============================================================================
; Input:  XWA = size in bytes to allocate (0 = return heap base)
; Output: XHL = pointer to allocated block (0xffffffff if insufficient space)
; Simple bump allocator: advances the heap pointer at 0x03d524 by the
; requested size. Checks available space at 0x03d528. Falls through to
; Heap_Grow if space is available.
; ============================================================================
Heap_Alloc:
	or xwa, xwa
	jr nz, Heap_Alloc_Block
	ld32_24 xhl, 0x03d528
	ret

Heap_Alloc_Block:
	cpdm32_24 251176, xwa
	jr nc, Heap_Grow
	ld xhl, 0xffffffff
	ret

; ============================================================================
; Heap_Grow - Grow the heap by allocating more memory
; ============================================================================
; Input:  XWA = size in bytes to allocate
; Output: XHL = pointer to newly allocated block (previous heap top)
; Advances the heap top pointer (0x03d524) and decreases available space
; counter (at address 251176). Called by Heap_Alloc after size check passes.
; ============================================================================
Heap_Grow:
	ld32_24 xhl, 0x03d524
	addm32_24 0x03d524, xwa
	subdm32_24 251176, xwa
	ret

; ============================================================================
; Strlen - Compute string length (C runtime)
; ============================================================================
; Input:  XWA = pointer to null-terminated string (pushed on stack)
; Output: HL = length of string (excluding null terminator)
;         Returns 0xffff if null terminator not found
; Uses AudioCmd_MemChr to search for 0x00 byte, then computes result - start.
; Located between Strcpy and Memset (standard C library functions).
; ============================================================================
Strlen:
	push xiz
	pushw 0xffff
	pushw 0x0
	ld xiz, (xsp + 12)
	push xiz
	call AudioCmd_MemChr
	inc 8, xsp
	or xhl, xhl
	jr nz, Strlen_Compute
	ldw hl, 0xffff
	jr Strlen_Epilogue

Strlen_Compute:
	sub xhl, xiz

Strlen_Epilogue:
	pop xiz
	ret

Strlen_LoadParam:
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld wa, (xsp + 12)
	cp wa, 0xa
	jr nz, Itoa_WithBase
	cp xde, 0x0
	jr ge, Itoa_WithBase
	ld (xbc), 0x2d
	pushw wa
	lda xwa, (xbc + 1)
	push xwa
	cpl de
	cpl_werp 0xea
	inc 1, xde
	push xde
	call AudioCmd_ItoaBaseN
	lda xsp, (xsp + 10)
	dec 1, xhl
	ret

; ============================================================================
; Itoa_WithBase - Convert integer to string with specified base (C runtime)
; ============================================================================
; Input:  WA = integer value, XBC = base pointer, XDE = format options
; Output: String written to output buffer
; Wrapper around AudioCmd_ItoaBaseN. Pushes parameters and delegates to
; the audio command subsystem's integer-to-string conversion.
; ============================================================================
Itoa_WithBase:
	pushw wa
	push xbc
	push xde
	call AudioCmd_ItoaBaseN
	lda xsp, (xsp + 10)
	ret

Memset:
	ld bc, (xsp + 10)
	ld xhl, (xsp + 4)
	cps bc, 0
	ret z
	ld xix, xhl
	ld wa, (xsp + 8)
	ld de, ix
	neg de
	and de, 0x3
	jr z, Memset_LoadReg

Memset_Block:
	lda_dpi XBC, 0xf0
	sub bc, 0x1
	ret z
	djnz xde, Memset_Block

Memset_LoadReg:
	ld de, bc
	srl bc, 2
	jr z, Memset_MaskBits
	ld w, a
	ldfr_werp WA, 0xe2

Memset_Block2:
	st_dpil XWA, 0xf2
	djnz xbc, Memset_Block2

Memset_MaskBits:
	and de, 0x3
	ret z

Memset_Block3:
	lda_dpi XBC, 0xf0
	djnz xde, Memset_Block3
	ret

Math_AbsInt16:
	ld hl, (xsp + 4)
	cps hl, 0
	ret ge
	neg hl
	ret

	.include "audio/audio_cmd_encoder.s"
