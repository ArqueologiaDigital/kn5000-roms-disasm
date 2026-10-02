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
	lda xsp, (xsp-504)
	pushw iz
	lda xwa, (0xc1fe:16)
	ld (xsp + 2), xwa
	call SeqMain_SaveWritePos
	ld	(xsp+500), 0x00
	lda xwa, (xsp+500)
	ld xde, xwa
	lda xwa, (xsp+336)
	ld xbc, xwa
	ld xwa, xde
	call MidiEvent_ProcessNoteEntry
	cp l, 0:i3
	jrl z, NoteOn_Epilogue

NoteOn_DispatchByStatus:
	ld	a, (xsp+336)
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
	ld	a, (xsp+339)
	cp a, (xbc)
	jrl nz, NoteOn_AdvanceChannel
	ld wa, (xsp + 6)
	add wa, wa
	add wa, 0x124
	extz xwa
	add xwa, (xsp + 2)
	bitm 6, (xwa)
	jrl z, NoteOn_AdvanceChannel
	lda xwa, (xsp+336)
	ld xbc, xwa
	ld wa, (xsp + 6)
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call Voice_ApplyTransposeWithEncode
	ld iz, 0:i3
	ld c, 0x7f:opc
	jr NoteOn_AutoPlayCheckCount

NoteOn_AutoPlayVoiceLoop:
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp+337)
	add xwa, xbc
	cp (xwa), 0x0
	jr z, NoteOn_AutoPlayNext
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp+336)
	add xwa, xbc
	ld c, (xwa)
	ld	a, (xsp+339)
	extz wa
	extz bc
	call AccWrap_AutoPlayCheck

NoteOn_AutoPlayNext:
	inc 1, iz

NoteOn_AutoPlayCheckCount:
	ld	a, (xsp+337)
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
	lda xwa, (xsp+336)
	ld xbc, xwa
	ld wa, (xsp + 6)
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_CollectAndAllocVoice_NoTimerCheck
	jrl NoteOn_PostAutoPlay

NoteOn_VoiceLookupAndAssign:
	lda xiy, (xsp+336)
	lda xix, (xsp+172:16)
	ldw bc, 0x52
	ldirw
	ld	(xsp+174), 0x00
	ld	(xsp+175), 0x01
	lda xwa, (xsp+172:16)
	call NoteMap_AssignAllVoiceLinks
	ld xwa, (xsp + 2)
	cp (xwa + 1), 0xff
	jrl nz, NoteOn_CheckSpecialChannel
	ld xwa, (xsp + 2)
	bitm 0, (xwa)
	jr z, NoteOn_MergeLayer1
	lda xwa, (xsp + 8)
	ld xhl, xwa
	lda xwa, (xsp+172:16)
	ld xbc, xwa
	ld xwa, (xsp + 2)
	lda xwa, (xwa+196:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, NoteOn_MergeLayer1
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	ld de, 0:i3
	call NoteMap_UpdateEntry

NoteOn_MergeLayer1:
	ld xwa, (xsp + 2)
	bitm 1, (xwa)
	jr z, NoteOn_MergeLayer2
	lda xwa, (xsp + 8)
	ld xhl, xwa
	lda xwa, (xsp+172:16)
	ld xbc, xwa
	ld xwa, (xsp + 2)
	lda xwa, (xwa+200:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, NoteOn_MergeLayer2
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	ld de, 1:i3
	call NoteMap_UpdateEntry

NoteOn_MergeLayer2:
	ld xwa, (xsp + 2)
	bitm 2, (xwa)
	jr z, NoteOn_MergeLayer3
	lda xwa, (xsp + 8)
	ld xhl, xwa
	lda xwa, (xsp+172:16)
	ld xbc, xwa
	ld xwa, (xsp + 2)
	lda xwa, (xwa+204:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, NoteOn_MergeLayer3
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	ld de, 2:i3
	call NoteMap_UpdateEntry

NoteOn_MergeLayer3:
	ld xwa, (xsp + 2)
	bitm 3, (xwa)
	jrl z, NoteOn_PostAutoPlay
	lda xwa, (xsp + 8)
	ld xhl, xwa
	lda xwa, (xsp+172:16)
	ld xbc, xwa
	ld xwa, (xsp + 2)
	lda xwa, (xwa+208:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
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
	ld wa, (0xc598:16)
	and wa, 0xa
	jr z, NoteOn_SpecialChannelUpdate
	lda xwa, (xsp+172:16)
	call NoteMap_MarkEntriesAboveThreshold

NoteOn_SpecialChannelUpdate:
	lda xwa, (xsp+172:16)
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
	lda xwa, (xsp+172:16)
	ld xbc, xwa
	ld xwa, (xsp + 2)
	lda xwa, (xwa+208:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, NoteOn_UpdateByChannelType
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	ldw de, 0x15
	call NoteMap_UpdateEntry

NoteOn_UpdateByChannelType:
	lda xwa, (xsp+172:16)
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
	incw 1, (xsp + 6)
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
	ld	a, (xsp+339)
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
	lda xwa, (xsp+336)
	ld xbc, xwa
	ld wa, (xsp + 6)
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_CollectAndAllocVoice_Indirect
	jrl NoteOnProcess_NextChannel

NoteOn_CC_VoiceLookupAndAssign:
	ld	(xsp+174), 0x00
	ld	(xsp+175), 0x01
	lda xwa, (xsp+172:16)
	call Voice_LookupTableEntries
	cp l, 0:i3
	jrl z, NoteOnProcess_NextChannel
	lda xwa, (xsp+172:16)
	call NoteMap_AssignAllVoiceLinks
	ld xwa, (xsp + 2)
	cp (xwa + 1), 0xff
	jrl nz, NoteOn_CC_CheckSpecialChannel
	ld xwa, (xsp + 2)
	bitm 0, (xwa)
	jr z, NoteOn_CC_MergeLayer1
	lda xwa, (xsp + 8)
	ld xhl, xwa
	lda xwa, (xsp+172:16)
	ld xbc, xwa
	ld xwa, (xsp + 2)
	lda xwa, (xwa+196:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, NoteOn_CC_MergeLayer1
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	ld de, 0:i3
	call NoteMap_UpdateEntry

NoteOn_CC_MergeLayer1:
	ld xwa, (xsp + 2)
	bitm 1, (xwa)
	jr z, NoteOn_CC_MergeLayer2
	lda xwa, (xsp + 8)
	ld xhl, xwa
	lda xwa, (xsp+172:16)
	ld xbc, xwa
	ld xwa, (xsp + 2)
	lda xwa, (xwa+200:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, NoteOn_CC_MergeLayer2
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	ld de, 1:i3
	call NoteMap_UpdateEntry

NoteOn_CC_MergeLayer2:
	ld xwa, (xsp + 2)
	bitm 2, (xwa)
	jr z, NoteOn_CC_MergeLayer3
	lda xwa, (xsp + 8)
	ld xhl, xwa
	lda xwa, (xsp+172:16)
	ld xbc, xwa
	ld xwa, (xsp + 2)
	lda xwa, (xwa+204:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, NoteOn_CC_MergeLayer3
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	ld de, 2:i3
	call NoteMap_UpdateEntry

NoteOn_CC_MergeLayer3:
	ld xwa, (xsp + 2)
	bitm 3, (xwa)
	jrl z, NoteOnProcess_NextChannel
	lda xwa, (xsp + 8)
	ld xhl, xwa
	lda xwa, (xsp+172:16)
	ld xbc, xwa
	ld xwa, (xsp + 2)
	lda xwa, (xwa+208:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
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
	ld wa, (0xc598:16)
	bit 1, wa
	jr z, NoteOn_CC_SpecialUpdate
	lda xwa, (xsp+172:16)
	call NoteMap_MarkEntriesAboveThreshold

NoteOn_CC_SpecialUpdate:
	lda xwa, (xsp+172:16)
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
	lda xwa, (xsp+172:16)
	ld xbc, xwa
	ld xwa, (xsp + 2)
	lda xwa, (xwa+208:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, NoteOn_CC_UpdateByChannelType
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	ldw de, 0x15
	call NoteMap_UpdateEntry

NoteOn_CC_UpdateByChannelType:
	lda xwa, (xsp+172:16)
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
	incw 1, (xsp + 6)
	cpw (xsp + 6), 0x1a
	jrl c, NoteOn_ChannelScanCC_Body

NoteOnProcess_StoreAndAllocate:
	lda xwa, (xsp+500)
	ld xde, xwa
	lda xwa, (xsp+336)
	ld xbc, xwa
	ld xwa, xde
	call MidiEvent_ProcessNoteEntry
	cp l, 0:i3
	jrl nz, NoteOn_DispatchByStatus

NoteOn_Epilogue:
	popw iz
	lda xsp, (xsp+504)
	ret

AccNoteOn_ProcessVoiceSetup:
	lda xsp, (xsp - 18)
	pushw iz
	lda xwa, (0xc1fe:16)
	ld (xsp + 2), xwa
	ld iz, 0:i3
	ld xiy, AccNoteOn_FrameTemplateA
	lda xix, (xsp + 10)
	ldiw
	ldiw
	ld xiy, AccNoteOn_FrameTemplateB
	lda xix, (xsp + 6)
	ldiw
	ldiw
	ld (xsp + 14), 0x0
	lda xwa, (xsp + 14)
	ld xbc, 0xcc1e
	call MidiEvent_ParseNoteSequence
	cp l, 0:i3
	jrl z, AccNoteOn_Return

AccNoteOn_AssignVoices:
	ld xwa, 0xcc1e
	call NoteMap_AssignAllVoiceLinks
	ld iz, 0:i3
	ld e, 0x7f:opc
	jr AccNoteOn_AutoPlayCheck

AccNoteOn_AutoPlayLoop:
	ld wa, iz
	mul wa, 0x5
	inc 4, wa
	lda xbc, (0xcc1f:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0x0
	jr z, AccNoteOn_AutoPlayNext
	ld wa, iz
	mul wa, 0x5
	lda xbc, (0xcc22:16)
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
	ld a, (0xcc1f:16)
	extz wa
	cp iz, wa
	jr c, AccNoteOn_AutoPlayLoop
	call CompIface_ResetPedal
	cp (0x8d38:16), 236
	jr nz, AccNoteOn_EmitVoiceLoop_Init
	ld iz, 0:i3
	ld e, 0x7f:opc
	jr AccNoteOn_MinVelocity_Check

AccNoteOn_FindMinVelocity_Loop:
	ld wa, iz
	mul wa, 0x5
	inc 4, wa
	lda xbc, (0xcc1f:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0x0
	jr z, AccNoteOn_MinVelocity_Next
	ld wa, iz
	mul wa, 0x5
	lda xbc, (0xcc22:16)
	extz xwa
	add xwa, xbc
	cp e, (xwa)
	jr nc, AccNoteOn_UseEntryVelocity
	ld a, e
	jr AccNoteOn_StoreMinVelocity

AccNoteOn_UseEntryVelocity:
	ld wa, iz
	mul wa, 0x5
	lda xbc, (0xcc22:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)

AccNoteOn_StoreMinVelocity:
	ld e, a

AccNoteOn_MinVelocity_Next:
	inc 1, iz

AccNoteOn_MinVelocity_Check:
	ld a, (0xcc1f:16)
	extz wa
	cp iz, wa
	jr c, AccNoteOn_FindMinVelocity_Loop
	ld a, e
	extz wa
	call AccWrap_SetMinVelocity

AccNoteOn_EmitVoiceLoop_Init:
	ld iz, 0:i3
	ld e, 0x7f:opc
	jr AccNoteOn_EmitVoiceLoop_Check

AccNoteOn_EmitVoiceLoop_Body:
	ld wa, iz
	mul wa, 0x5
	lda xbc, (0xcc22:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld e, a
	extz de
	ld wa, iz
	mul wa, 0x5
	inc 4, wa
	lda xbc, (0xcc1f:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld c, a
	extz bc
	ld wa, de
	call Voice_EmitNoteWithVelocity
	inc 1, iz

AccNoteOn_EmitVoiceLoop_Check:
	ld a, (0xcc1f:16)
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
	lda xwa, (xwa+196:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, AccNoteOn_MergeLayer1
	ld xwa, 0xcb7a
	ld xbc, (xsp + 2)
	ld de, 0:i3
	call NoteMap_AddEntry

AccNoteOn_MergeLayer1:
	ld xwa, (xsp + 2)
	bitm 1, (xwa)
	jr z, AccNoteOn_MergeLayer2
	ld xhl, 0xcb7a
	ld xbc, 0xcc1e
	ld xwa, (xsp + 2)
	lda xwa, (xwa+200:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, AccNoteOn_MergeLayer2
	ld xwa, 0xcb7a
	ld xbc, (xsp + 2)
	ld de, 1:i3
	call NoteMap_AddEntry

AccNoteOn_MergeLayer2:
	ld xwa, (xsp + 2)
	bitm 2, (xwa)
	jr z, AccNoteOn_MergeLayer3
	ld xhl, 0xcb7a
	ld xbc, 0xcc1e
	ld xwa, (xsp + 2)
	lda xwa, (xwa+204:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, AccNoteOn_MergeLayer3
	ld xwa, 0xcb7a
	ld xbc, (xsp + 2)
	ld de, 2:i3
	call NoteMap_AddEntry

AccNoteOn_MergeLayer3:
	ld xwa, (xsp + 2)
	bitm 3, (xwa)
	jrl z, AccNoteOn_FinalizeAndAutoPlay
	ld xhl, 0xcb7a
	ld xbc, 0xcc1e
	ld xwa, (xsp + 2)
	lda xwa, (xwa+208:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
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
	ld wa, (0xc598:16)
	and wa, 0xa
	jr z, AccNoteOn_SpecialDirectAdd
	ld xhl, 0xcb7a
	ld xbc, 0xcc1e
	lda xwa, (xsp + 10)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
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
	cp l, 0:i3
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
	lda xwa, (xwa+208:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
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
	cp l, 0:i3
	jrl nz, AccNoteOn_AssignVoices

AccNoteOn_Return:
	call AccWrap_AutoPlayStateMachine
	popw iz
	lda xsp, (xsp + 18)
	ret

AccNoteOn_ChannelDispatch:
	lda xsp, (xsp-174)
	pushw_erp 0xfa
	lda xwa, (0xc1fe:16)
	ld (xsp + 2), xwa
	call SeqBuf_SaveReadPos
	ld (xsp + 6), 0x0
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, xde
	call MidiEvent_ReadAndParseLoop
	cp l, 0:i3
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
	ldib_erp 0xfb, 0
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
	inc1b_erp 0xfb
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
	cp l, 0:i3
	jrl nz, AccMidi_DispatchLoop

AccMidi_Return:
	popw_erp 0xfa
	lda xsp, (xsp+174:16)
	ret

RhythmMidi_Dispatcher:
	lda xsp, (xsp-180)
	pushw_erp 0xfa
	lda xwa, (0xc1fe:16)
	ld (xsp + 2), xwa
	ld xiy, RhythmMidi_FrameTemplate
	lda xix, (xsp + 6)
	ld bc, 2:i3
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
	cp l, 0:i3
	jrl z, RhythmMidi_CC_PostProcess

RhythmMidi_DispatchByStatus:
	ld a, (xsp + 18)
	cp a, 0xb0
	jr z, RhythmMidi_HandleCC
	cp a, 0x90
	jrl nz, RhythmMidi_CC_UpdateOutput
	ld a, (xsp + 21)
	extz wa
	lda xbc, (RhythmMidi_StatusMap:24)
	ld	a, (xbc+wa)
	ldfr_berp A, 0xfa
	sub a, 0x10
	extz wa
	lda xbc, (xsp + 6)
	cp	(xbc+wa), 0x00
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
	ld	(xbc+wa), 0x00
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
	ldib_erp 0xfb, 0
	cpib_erp 0xfb, 5
	jrl nc, RhythmMidi_CC_UpdateOutput

RhythmMidi_CC7F_PartLoop:
	ldto_berp A, 0xfb
	ld (xsp + 21), a
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (RhythmMidi_StatusMap:24)
	ld	a, (xbc+wa)
	ldfr_berp A, 0xfa
	lda xwa, (xsp + 18)
	ld xbc, xwa
	ldto_berp A, 0xfa
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_LookupAndAllocVoice
	inc1b_erp 0xfb
	cpib_erp 0xfb, 5
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
	ldib_erp 0xfb, 0
	cpib_erp 0xfb, 5
	jrl nc, RhythmMidi_CC_UpdateOutput

RhythmMidi_CC7D_PartLoop:
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (xsp + 6)
	cp	(xbc+wa), 0x00
	jr z, RhythmMidi_CC7D_PartNext
	ldto_berp A, 0xfb
	ld (xsp + 21), a
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (RhythmMidi_StatusMap:24)
	ld	a, (xbc+wa)
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
	ld	(xbc+wa), 0x00

RhythmMidi_CC7D_PartNext:
	inc1b_erp 0xfb
	cpib_erp 0xfb, 5
	jr c, RhythmMidi_CC7D_PartLoop
	jr RhythmMidi_CC_UpdateOutput

RhythmMidi_CC_Default:
	cp (xsp + 21), 0x70
	jr c, RhythmMidi_CC_Standard
	ld (xsp + 18), 0xa0
	submi8 (xsp + 21), 0x70
	ld a, (xsp + 21)
	extz wa
	lda xbc, (RhythmMidi_StatusMap:24)
	ld	a, (xbc+wa)
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
	ld	(xbc+wa), 0x00
	jr RhythmMidi_CC_UpdateOutput

RhythmMidi_CC_Standard:
	ld a, (xsp + 21)
	extz wa
	lda xbc, (RhythmMidi_StatusMap:24)
	ld	a, (xbc+wa)
	ldfr_berp A, 0xfa
	sub a, 0x10
	extz wa
	lda xbc, (xsp + 6)
	ld	(xbc+wa), 0x01

RhythmMidi_CC_UpdateOutput:
	lda xwa, (xsp + 12)
	ld xde, xwa
	lda xwa, (xsp + 18)
	ld xbc, xwa
	ld xwa, xde
	call RhythmBuf_ParseEventLoop
	cp l, 0:i3
	jrl nz, RhythmMidi_DispatchByStatus

RhythmMidi_CC_PostProcess:
	ldib_erp 0xfb, 0
	cpib_erp 0xfb, 5
	jr nc, RhythmMidi_CC_Return

RhythmMidi_CC_PostLoop:
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (xsp + 6)
	cp	(xbc+wa), 0x00
	jr z, RhythmMidi_CC_PostNext
	ldto_berp A, 0xfb
	ld (xsp + 21), a
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (RhythmMidi_StatusMap:24)
	ld	a, (xbc+wa)
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
	inc1b_erp 0xfb
	cpib_erp 0xfb, 5
	jr c, RhythmMidi_CC_PostLoop

RhythmMidi_CC_Return:
	popw_erp 0xfa
	lda xsp, (xsp+180:16)
	ret

RhythmMidi_SeqEvt:
	lda xsp, (xsp-174)
	pushw_erp 0xfa
	lda xwa, (0xc1fe:16)
	ld (xsp + 2), xwa
	call SeqEvtBuf_SaveReadPos
	ld (xsp + 6), 0x0
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, xde
	call SeqEvtBuf_ParseEventLoop
	cp l, 0:i3
	jrl z, RhythmMidi_SeqEvt_Return

RhythmMidi_SeqEvt_Dispatch:
	ld a, (xsp + 12)
	cp a, 0xb0
	jr z, RhythmMidi_SeqEvt_CC
	cp a, 0x90
	jrl nz, RhythmMidi_SeqEvt_ReadNext
	ld a, (xsp + 15)
	extz wa
	lda xbc, (RhythmMidi_SeqEvtMap:24)
	ld	e, (xbc+wa)
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
	ldib_erp 0xfb, 0
	cpib_erp 0xfb, 2
	jrl nc, RhythmMidi_SeqEvt_ReadNext

RhythmMidi_SeqEvt_CC7F_Loop:
	ldto_berp A, 0xfb
	ld (xsp + 15), a
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (RhythmMidi_SeqEvtMap:24)
	ld	e, (xbc+wa)
	ld a, e
	cp a, 0xff
	jr z, RhythmMidi_SeqEvt_CC7F_Next
	lda xwa, (xsp + 12)
	extz de
	ld xbc, (xsp + 2)
	call NoteMap_LookupAllocAndStoreResult

RhythmMidi_SeqEvt_CC7F_Next:
	inc1b_erp 0xfb
	cpib_erp 0xfb, 2
	jr c, RhythmMidi_SeqEvt_CC7F_Loop
	jr RhythmMidi_SeqEvt_ReadNext

RhythmMidi_SeqEvt_CC7E:
	ldib_erp 0xfb, 0
	cpib_erp 0xfb, 1
	jr nc, RhythmMidi_SeqEvt_ReadNext

RhythmMidi_SeqEvt_CC7E_Loop:
	ldto_berp A, 0xfb
	ld (xsp + 15), a
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (RhythmMidi_SeqEvtMap:24)
	ld	e, (xbc+wa)
	ld a, e
	cp a, 0xff
	jr z, RhythmMidi_SeqEvt_CC7E_Next
	lda xwa, (xsp + 12)
	extz de
	ld xbc, (xsp + 2)
	call NoteMap_LookupAllocAndStoreResult

RhythmMidi_SeqEvt_CC7E_Next:
	inc1b_erp 0xfb
	cpib_erp 0xfb, 1
	jr c, RhythmMidi_SeqEvt_CC7E_Loop
	jr RhythmMidi_SeqEvt_ReadNext

RhythmMidi_SeqEvt_CC_Default:
	ld a, (xsp + 15)
	extz wa
	lda xbc, (RhythmMidi_SeqEvtMap:24)
	ld	e, (xbc+wa)
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
	cp l, 0:i3
	jrl nz, RhythmMidi_SeqEvt_Dispatch

RhythmMidi_SeqEvt_Return:
	popw_erp 0xfa
	lda xsp, (xsp+174:16)
	ret


; -----------------------------------------------------------------------------
; Section: Voice Initialization & Event Dispatch
; -----------------------------------------------------------------------------
; Voice state initialization, per-voice event dispatch,
; and voice table group setup.
; -----------------------------------------------------------------------------

Voice_InitializeAll:
	lda xsp, (xsp-496)
	push xiz
	lda xiz, (0xc1fe:16)
	ld	(xsp+336), 0x90
	ld	(xsp+338), 0x01
	ld (xsp + 4), 0x0
	cp (xsp + 4), 0x10
	jrl nc, VoiceInit_Epilogue

VoiceInit_PartLoop:
	ld a, (xsp + 4)
	ld	(xsp+339), a
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
	ld	a, (xsp+339)
	cp a, (xbc)
	jrl nz, VoiceProcess_NextChannel
	ld a, (xsp + 6)
	extz wa
	add wa, wa
	add wa, 0x124
	bit	6, (xiz+wa)
	jrl z, VoiceProcess_NextChannel
	ld a, (xsp + 6)
	extz wa
	add wa, wa
	add wa, 0x124
	bit	4, (xiz+wa)
	jr nz, VoiceInit_LookupTableAndAssign
	lda xwa, (xsp+336)
	ld xbc, xwa
	ld a, (xsp + 6)
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, xiz
	call NoteMap_CollectAndAllocVoice_Indirect
	jrl VoiceProcess_NextChannel

VoiceInit_LookupTableAndAssign:
	ld	(xsp+172), 0x90
	ld	(xsp+174), 0x00
	ld	(xsp+175), 0x01
	lda xwa, (xsp+172:16)
	call Voice_LookupTableEntries
	cp l, 0:i3
	jrl z, VoiceProcess_NextChannel
	lda xwa, (xsp+172:16)
	call NoteMap_AssignAllVoiceLinks
	cp (xiz + 1), 0xff
	jrl nz, VoiceInit_CheckSpecialChannel
	bitm 0, (xiz)
	jr z, VoiceInit_MergeLayer1
	lda xwa, (xsp + 8)
	ld xhl, xwa
	lda xwa, (xsp+172:16)
	ld xbc, xwa
	lda xwa, (xiz+196:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, VoiceInit_MergeLayer1
	lda xwa, (xsp + 8)
	ld xbc, xiz
	ld de, 0:i3
	call NoteMap_UpdateEntry

VoiceInit_MergeLayer1:
	bitm 1, (xiz)
	jr z, VoiceInit_MergeLayer2
	lda xwa, (xsp + 8)
	ld xhl, xwa
	lda xwa, (xsp+172:16)
	ld xbc, xwa
	lda xwa, (xiz+200:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, VoiceInit_MergeLayer2
	lda xwa, (xsp + 8)
	ld xbc, xiz
	ld de, 1:i3
	call NoteMap_UpdateEntry

VoiceInit_MergeLayer2:
	bitm 2, (xiz)
	jr z, VoiceInit_MergeLayer3
	lda xwa, (xsp + 8)
	ld xhl, xwa
	lda xwa, (xsp+172:16)
	ld xbc, xwa
	lda xwa, (xiz+204:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, VoiceInit_MergeLayer3
	lda xwa, (xsp + 8)
	ld xbc, xiz
	ld de, 2:i3
	call NoteMap_UpdateEntry

VoiceInit_MergeLayer3:
	bitm 3, (xiz)
	jrl z, VoiceProcess_NextChannel
	lda xwa, (xsp + 8)
	ld xhl, xwa
	lda xwa, (xsp+172:16)
	ld xbc, xwa
	lda xwa, (xiz+208:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, VoiceProcess_NextChannel
	lda xwa, (xsp + 8)
	ld xbc, xiz
	ldw de, 0x15
	call NoteMap_UpdateEntry
	jr VoiceProcess_NextChannel

VoiceInit_CheckSpecialChannel:
	cp (xiz + 1), 0x15
	jr nz, VoiceInit_CheckLayer3Only
	ld wa, (0xc598:16)
	bit 1, wa
	jr z, VoiceInit_SpecialChannelUpdate
	lda xwa, (xsp+172:16)
	call NoteMap_MarkEntriesAboveThreshold

VoiceInit_SpecialChannelUpdate:
	lda xwa, (xsp+172:16)
	ld xbc, xiz
	ldw de, 0x15
	call NoteMap_UpdateEntry
	jr VoiceProcess_NextChannel

VoiceInit_CheckLayer3Only:
	bitm 3, (xiz)
	jr z, VoiceInit_UpdateByChannelType
	lda xwa, (xsp + 8)
	ld xhl, xwa
	lda xwa, (xsp+172:16)
	ld xbc, xwa
	lda xwa, (xiz+208:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, VoiceInit_UpdateByChannelType
	lda xwa, (xsp + 8)
	ld xbc, xiz
	ldw de, 0x15
	call NoteMap_UpdateEntry

VoiceInit_UpdateByChannelType:
	lda xwa, (xsp+172:16)
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
	lda xsp, (xsp+496)
	ret


; -----------------------------------------------------------------------------
; Section: NoteMap Entry Management
; -----------------------------------------------------------------------------
; NoteMap storage, retrieval, voice linking, merge
; allocation, and control change encoding.
; -----------------------------------------------------------------------------

NoteMap_ProcessAndMerge:
	lda xsp, (xsp-328)
	push xiz
	lda xiz, (0xc1fe:16)
	ld	(xsp+168), 0x90
	ld	(xsp+170), 0x00
	ld	(xsp+171), 0x00
	lda xwa, (xsp+168:16)
	call Voice_LookupTableEntries
	cp l, 0:i3
	jrl z, NoteMap_AddEntry_Return
	lda xwa, (xsp+168:16)
	call NoteMap_AssignAllVoiceLinks
	cp (xiz + 1), 0xff
	jrl nz, NoteMap_ProcessMerge_SpecialPath
	lda xwa, (xsp + 4)
	ld xhl, xwa
	lda xwa, (xsp+168:16)
	ld xbc, xwa
	lda xwa, (xiz+196:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, NoteMap_ProcessMerge_Layer1
	lda xwa, (xsp + 4)
	ld xbc, xiz
	ld de, 0:i3
	call NoteMap_AddEntry

NoteMap_ProcessMerge_Layer1:
	lda xwa, (xsp + 4)
	ld xhl, xwa
	lda xwa, (xsp+168:16)
	ld xbc, xwa
	lda xwa, (xiz+196:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, NoteMap_ProcessMerge_Layer2
	lda xwa, (xsp + 4)
	ld xbc, xiz
	ld de, 1:i3
	call NoteMap_AddEntry

NoteMap_ProcessMerge_Layer2:
	lda xwa, (xsp + 4)
	ld xhl, xwa
	lda xwa, (xsp+168:16)
	ld xbc, xwa
	lda xwa, (xiz+204:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, NoteMap_ProcessMerge_Layer3
	lda xwa, (xsp + 4)
	ld xbc, xiz
	ld de, 2:i3
	call NoteMap_AddEntry

NoteMap_ProcessMerge_Layer3:
	lda xwa, (xsp + 4)
	ld xhl, xwa
	lda xwa, (xsp+168:16)
	ld xbc, xwa
	lda xwa, (xiz+208:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, NoteMap_AddEntry_Return
	lda xwa, (xsp + 4)
	ld xbc, xiz
	ldw de, 0x15
	call NoteMap_AddEntry
	jr NoteMap_AddEntry_Return

NoteMap_ProcessMerge_SpecialPath:
	lda xwa, (xsp + 4)
	ld xhl, xwa
	lda xwa, (xsp+168:16)
	ld xbc, xwa
	lda xwa, (xiz+208:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, NoteMap_ProcessMerge_UpdateChannel
	lda xwa, (xsp + 4)
	ld xbc, xiz
	ldw de, 0x15
	call NoteMap_AddEntry

NoteMap_ProcessMerge_UpdateChannel:
	lda xwa, (xsp+168:16)
	ld xbc, xwa
	ld a, (xiz + 1)
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, xiz
	call NoteMap_AddEntry

NoteMap_AddEntry_Return:
	pop xiz
	lda xsp, (xsp+328)
	ret

NoteMap_SendAllNotesOff:
	lda xsp, (xsp-168)
	pushw_erp 0xfa
	lda xwa, (0xc1fe:16)
	ld (xsp + 2), xwa
	ldib_erp 0xfb, 0
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
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, NoteOff_PartLoop_Body

NoteOff_Return:
	popw_erp 0xfa
	lda xsp, (xsp+168:16)
	ret

Voice_InitTableGroup:
	lda xsp, (xsp-168)
	pushw_erp 0xfa
	lda xwa, (0xc1fe:16)
	ld (xsp + 2), xwa
	ld (xsp + 6), 0x90
	ld (xsp + 8), 0x4
	ldib_erp 0xfb, 0
	cpib_erp 0xfb, 5
	jr nc, VoiceTableGroup_Return

VoiceTableGroup_PartLoop:
	ldto_berp A, 0xfb
	ld (xsp + 9), a
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (RhythmMidi_StatusMap:24)
	ld	e, (xbc+wa)
	lda xwa, (xsp + 6)
	extz de
	ld xbc, (xsp + 2)
	call NoteMap_LookupAndAllocVoice
	inc1b_erp 0xfb
	cpib_erp 0xfb, 5
	jr c, VoiceTableGroup_PartLoop

VoiceTableGroup_Return:
	popw_erp 0xfa
	lda xsp, (xsp+168:16)
	ret

Voice_InitTablePair:
	lda xsp, (xsp-168)
	pushw_erp 0xfa
	lda xwa, (0xc1fe:16)
	ld (xsp + 2), xwa
	ld (xsp + 6), 0x90
	ld (xsp + 8), 0x5
	ldib_erp 0xfb, 0
	cpib_erp 0xfb, 2
	jr nc, VoiceTablePair_Return

VoiceTablePair_PartLoop:
	ldto_berp A, 0xfb
	ld (xsp + 9), a
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (RhythmMidi_SeqEvtMap:24)
	ld	e, (xbc+wa)
	lda xwa, (xsp + 6)
	extz de
	ld xbc, (xsp + 2)
	call NoteMap_LookupAllocAndStoreResult
	inc1b_erp 0xfb
	cpib_erp 0xfb, 2
	jr c, VoiceTablePair_PartLoop

VoiceTablePair_Return:
	popw_erp 0xfa
	lda xsp, (xsp+168:16)
	ret

VoiceEvent_ResetAndInit:
	ret

VoiceEvent_AllocAllLayers:
	lda xwa, (0xc1fe:16)
	ld bc, 0:i3
	call NoteMap_AllocateVoice
	lda xwa, (0xc1fe:16)
	ld bc, 1:i3
	call NoteMap_AllocateVoice
	cpw (0xce22:16), 0
	ret z
	call NoteMap_FindBestMatch
	cp l, 0xff
	ret z
	lda xwa, (0xc1fe:16)
	ld bc, 2:i3
	call NoteMap_AllocateVoice
	ret

VoiceEvent_AllocTwoLayers:
	lda	xwa, (0xc1fe:16)
	ld	bc, 0:i3
	call	NoteMap_AssignVoiceParams
	lda	xwa, (0xc1fe:16)
	ld	bc, 1:i3
	jp	NoteMap_AssignVoiceParams

VoiceEvent_DispatchTable:
	lda xwa, (0xc1fe:16)
	ld bc, 2:i3
	call NoteMap_AssignVoiceParams
	lda xwa, (0xc1fe:16)
	ld bc, 2:i3
	jp NoteMap_InitVoiceSlots
VoiceEvent_TableSeparator:
	ret

VoiceEvent_HandlerTable:
	pushw iz
	ld iz, 0:i3
	cp iz, (0xc4ca:16)
	jrl nc, VoiceEvtHandler_Done

; Voice event type dispatch
VoiceEvent_TypeDispatch:
	ld wa, iz
	sll wa, 2
	lda xbc, (0xc4cc:16)
	extz xwa
	add xwa, xbc
	ld h, (xwa)
	ld wa, iz
	sll wa, 2
	lda xbc, (0xc4cd:16)
	extz xwa
	add xwa, xbc
	ld l, (xwa)
	ld wa, iz
	sll wa, 2
	lda xbc, (0xc4ce:16)
	extz xwa
	add xwa, xbc
	ld c, (xwa)
	ld wa, iz
	sll wa, 2
	lda xde, (0xc4cf:16)
	extz xwa
	add xwa, xde
	ld e, (xwa)
	ld a, h
	extz wa
	cp wa, 0:i3
	jrl mi, AudioInit_FlushQueue_LoopNext
	cp wa, 0xd
	jrl gt, AudioInit_FlushQueue_LoopNext
	add wa, wa
	lda xix, (VoiceEvent_SwitchOffsets:24)
	ld	wa, (xix+wa)
	lda xix, (VoiceEvent_Dispatch:24)
	jp	t, (xix+wa)

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
	call nz, (VoiceEvent_DispatchTable:24)

AudioInit_FlushQueue_LoopNext:
	inc 1, iz
	cp iz, (0xc4ca:16)
	jrl c, VoiceEvent_TypeDispatch

VoiceEvtHandler_Done:
	ldw (0xc4ca:16), 0
	popw iz
	ret

VoiceEvent_FlushAndReturn:
	lda xsp, (xsp-336)
	ld	(xsp+334), c
	cp a, 0xff
	jrl z, VoiceClaim_Slot0_Alt
	ld	(xsp+170), 0x90
	ld	(xsp+172), a
	ld	(xsp+173), 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp+170:16)
	ld xbc, xwa
	ld	a, (xsp+334)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jrl z, Audio_StoreParamAndReturn
	ld (xsp + 0:8), 0x4
	ld (xsp + 0:8), 0xb0
	ld	a, (xsp+334)
	ld (xsp + 1), a
	ld (xsp + 2), 0x7b
	ld (xsp + 3), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	ld de, 0:i3
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
	ld	a, (xsp+334)
	extz wa
	lda xbc, (0xc202:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xff
	jrl z, Audio_StoreParamAndReturn
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld	a, (xsp+334)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	jrl Audio_StoreParamAndReturn

VoiceClaim_Slot0_Alt:
	ld	(xsp+170), 0x90
	ld	(xsp+172), 0x00
	ld	(xsp+173), 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp+170:16)
	ld xbc, xwa
	ld	a, (xsp+334)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jrl z, VoiceClaim_Extended_Init
	ld (xsp + 0:8), 0x4
	ld (xsp + 1), 0xb0
	ld	a, (xsp+334)
	ld (xsp + 2), a
	ld (xsp + 3), 0x7b
	ld (xsp + 4), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	ld de, 0:i3
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
	ld	a, (xsp+334)
	extz wa
	lda xbc, (0xc202:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xff
	jr z, VoiceClaim_Slot1_Init
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld	a, (xsp+334)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

VoiceClaim_Slot1_Init:
	ld	(xsp+172), 0x01
	ld	(xsp+173), 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp+170:16)
	ld xbc, xwa
	ld	a, (xsp+334)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jr z, VoiceClaim_Slot2_Init
	ld de, 0:i3
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
	ld	a, (xsp+334)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

VoiceClaim_Slot2_Init:
	ld	(xsp+172), 0x02
	ld	(xsp+173), 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp+170:16)
	ld xbc, xwa
	ld	a, (xsp+334)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jr z, VoiceClaim_Slot3_Init
	ld de, 0:i3
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
	ld	a, (xsp+334)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

VoiceClaim_Slot3_Init:
	ld	(xsp+172), 0x03
	ld	(xsp+173), 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp+170:16)
	ld xbc, xwa
	ld	a, (xsp+334)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jr z, VoiceClaim_Slot6_Init
	ld de, 0:i3
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
	ld	a, (xsp+334)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

VoiceClaim_Slot6_Init:
	ld	(xsp+172), 0x06
	ld	(xsp+173), 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp+170:16)
	ld xbc, xwa
	ld	a, (xsp+334)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jrl z, Audio_StoreParamAndReturn
	ld de, 0:i3
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
	ld	a, (xsp+334)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	jrl Audio_StoreParamAndReturn

VoiceClaim_Extended_Init:
	ld	(xsp+170), 0x90
	ld	(xsp+172), 0x01
	ld	(xsp+173), 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp+170:16)
	ld xbc, xwa
	ld	a, (xsp+334)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jrl z, VoiceClaim_Extended_Return
	ld (xsp + 0:8), 0x4
	ld (xsp + 1), 0xb0
	ld	a, (xsp+334)
	ld (xsp + 2), a
	ld (xsp + 3), 0x7b
	ld (xsp + 4), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	ld de, 0:i3
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
	ld	a, (xsp+334)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	ld	(xsp+172), 0x02
	ld	(xsp+173), 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp+170:16)
	ld xbc, xwa
	ld	a, (xsp+334)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jr z, VoiceClaimExt_Slot2_SetParam
	ld de, 0:i3
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
	ld	a, (xsp+334)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

VoiceClaimExt_Slot2_SetParam:
	ld	(xsp+172), 0x03
	ld	(xsp+173), 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp+170:16)
	ld xbc, xwa
	ld	a, (xsp+334)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jr z, VoiceClaimExt_Slot3_SetParam
	ld de, 0:i3
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
	ld	a, (xsp+334)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

VoiceClaimExt_Slot3_SetParam:
	ld	(xsp+172), 0x06
	ld	(xsp+173), 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp+170:16)
	ld xbc, xwa
	ld	a, (xsp+334)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jrl z, Audio_StoreParamAndReturn
	ld de, 0:i3
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
	ld	a, (xsp+334)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	jrl Audio_StoreParamAndReturn

VoiceClaim_Extended_Return:
	ld	(xsp+172), 0x02
	ld	(xsp+173), 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp+170:16)
	ld xbc, xwa
	ld	a, (xsp+334)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jrl z, VoiceClaimExt2_Slot3_WriteReg
	ld (xsp + 0:8), 0x4
	ld (xsp + 1), 0xb0
	ld	a, (xsp+334)
	ld (xsp + 2), a
	ld (xsp + 3), 0x7b
	ld (xsp + 4), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	ld de, 0:i3
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
	ld	a, (xsp+334)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	ld	(xsp+172), 0x03
	ld	(xsp+173), 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp+170:16)
	ld xbc, xwa
	ld	a, (xsp+334)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jr z, VoiceClaimExt2_Slot2_SetParam
	ld de, 0:i3
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
	ld	a, (xsp+334)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

VoiceClaimExt2_Slot2_SetParam:
	ld	(xsp+172), 0x06
	ld	(xsp+173), 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp+170:16)
	ld xbc, xwa
	ld	a, (xsp+334)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jrl z, Audio_StoreParamAndReturn
	ld de, 0:i3
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
	ld	a, (xsp+334)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	jrl Audio_StoreParamAndReturn

VoiceClaimExt2_Slot3_WriteReg:
	ld	(xsp+172), 0x03
	ld	(xsp+173), 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp+170:16)
	ld xbc, xwa
	ld	a, (xsp+334)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jrl z, VoiceClaimExt2_Slot3_WriteReg2
	ld (xsp + 0:8), 0x4
	ld (xsp + 1), 0xb0
	ld	a, (xsp+334)
	ld (xsp + 2), a
	ld (xsp + 3), 0x7b
	ld (xsp + 4), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	ld de, 0:i3
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
	ld	a, (xsp+334)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	ld	(xsp+172), 0x06
	ld	(xsp+173), 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp+170:16)
	ld xbc, xwa
	ld	a, (xsp+334)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jrl z, Audio_StoreParamAndReturn
	ld de, 0:i3
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
	ld	a, (xsp+334)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	jrl Audio_StoreParamAndReturn

VoiceClaimExt2_Slot3_WriteReg2:
	ld	(xsp+172), 0x06
	ld	(xsp+173), 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp+170:16)
	ld xbc, xwa
	ld	a, (xsp+334)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jr z, Audio_StoreParamAndReturn
	ld (xsp + 0:8), 0x4
	ld (xsp + 1), 0xb0
	ld	a, (xsp+334)
	ld (xsp + 2), a
	ld (xsp + 3), 0x7b
	ld (xsp + 4), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	ld de, 0:i3
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
	ld	a, (xsp+334)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

Audio_StoreParamAndReturn:
	lda xsp, (xsp+336)
	ret


; -----------------------------------------------------------------------------
; Section: MIDI Event & Channel Configuration
; -----------------------------------------------------------------------------
; MIDI channel configuration, voice slot data init,
; and note sequence parsing.
; -----------------------------------------------------------------------------

MidiEvent_ConfigChannel:
	lda xsp, (xsp-336)
	ld	(xsp+334), c
	cp a, 0xff
	jr z, MidiConfig_Slot6Path
	ld	(xsp+170), 0x90
	ld	(xsp+172), a
	ld	(xsp+173), 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp+170:16)
	ld xbc, xwa
	ld	a, (xsp+334)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jrl z, MidiConfig_Return
	ld (xsp + 0:8), 0x4
	ld (xsp + 0:8), 0xb0
	ld	a, (xsp+334)
	ld (xsp + 1), a
	ld (xsp + 2), 0x7b
	ld (xsp + 3), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	ld	a, (xsp+334)
	extz wa
	lda xbc, (0xc202:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xff
	jrl z, MidiConfig_Return
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld	a, (xsp+334)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	jr MidiConfig_Return

MidiConfig_Slot6Path:
	ld	(xsp+170), 0x90
	ld	(xsp+172), 0x06
	ld	(xsp+173), 0xff
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp+170:16)
	ld xbc, xwa
	ld	a, (xsp+334)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jr z, MidiConfig_Return
	ld (xsp + 0:8), 0x4
	ld (xsp + 1), 0xb0
	ld	a, (xsp+334)
	ld (xsp + 2), a
	ld (xsp + 3), 0x7b
	ld (xsp + 4), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	ld	a, (xsp+334)
	extz wa
	lda xbc, (0xc202:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xff
	jr z, MidiConfig_Return
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld	a, (xsp+334)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

MidiConfig_Return:
	lda xsp, (xsp+336)
	ret

Voice_FindAndAllocBestMatch:
	cpw (0xce22:16), 0
	ret z
	call NoteMap_FindBestMatch
	cp l, 0xff
	ret z
	lda xwa, (0xc1fe:16)
	ld bc, 2:i3
	call NoteMap_AllocateVoice
	ret

Voice_InitSlotData:
	ld a, (0xcee5:16)
	extz wa
	ld (0xceff:16), wa
	ld de, 0:i3
	jr VoiceSlotInit_Check

VoiceSlotInit_Loop:
	ld wa, de
	add wa, wa
	inc 4, wa
	lda xbc, (0xcf00:16)
	ld hl, wa
	extz xhl
	add xhl, xbc
	ld wa, de
	inc 1, wa
	lda xbc, (0xcee5:16)
	ld	a, (xbc+wa)
	ld (xhl), a
	ld wa, de
	add wa, wa
	lda xbc, (0xcf03:16)
	extz xwa
	add xwa, xbc
	ld (xwa), 0x40
	inc 1, de

VoiceSlotInit_Check:
	ld a, (0xcee5:16)
	extz wa
	cp de, wa
	jr lt, VoiceSlotInit_Loop
	call Voice_InitPartAllocState
	lda xwa, (0xc1fe:16)
	ld bc, 0:i3
	call NoteMap_AllocateVoice
	lda xwa, (0xc1fe:16)
	ld bc, 1:i3
	call NoteMap_AllocateVoice
	ldw (0xceff:16), 0
	ret

NoteMap_AssignAllVoiceLinks:
	dec 6, xsp
	push xiz
	ld (xsp + 6), xwa
	ld xwa, (xsp + 6)
	ld a, (xwa + 3)
	extz wa
	lda xbc, (NoteMap_LinkByte_Table:24)
	ld	a, (xbc+wa)
	ld (xsp + 4), a
	ld iz, 0:i3
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
	ld a, (0xe829:16)
	ldfr_berp A, 0xfb
	cp a, 0x20
	jrl z, MidiEvent_NoteLoopAdvance
	lda xde, (0xe7e8:16)
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SwapVoiceLinks
	lda xhl, (0xe7e8:16)
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
	lda xhl, (0xc5cb:16)
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	ld a, (xbc)
	ld	(xhl+de), a
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x3
	ld de, wa
	lda xhl, (0xc5cc:16)
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	ld a, (xbc + 1)
	ld	(xhl+de), a
	incw 1, (0xe9ba:16)
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
	lda xde, (0xe7e8:16)
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SwapVoiceLinks
	lda xde, (0xe7e8:16)
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	ldw de, 0x20
	call NoteMap_LinkVoiceSlots
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x3
	lda xbc, (0xc5cb:16)
	ld	(xbc+wa), 0xff
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x3
	lda xbc, (0xc5cc:16)
	ld	(xbc+wa), 0xff
	decw 1, (0xe9ba:16)
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
	incw 1, (xsp + 4)
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
	ld l, 0x0:opc

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
	cp a, 0:i3
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
	incw 1, (xsp + 4)

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
	cp hl, 0:i3
	jr z, MidiEvent_ProcessCC_Continue
	cp (0xc363:16), 255
	jr z, ProcessNoteEntry_CheckDRAM
	ld l, (0xc363:16)
	extz hl
	jr MidiEvent_ProcessCC_Continue

ProcessNoteEntry_CheckDRAM:
	cp (0xc362:16), 0
	jr le, ProcessNoteEntry_LoadDRAM2
	ld a, (0xc362:16)
	exts wa
	add wa, hl
	cp a, 0x7f
	jr ule, ProcessNoteEntry_LoadDRAM
	ldw hl, 0x7f
	jr MidiEvent_ProcessCC_Continue

ProcessNoteEntry_LoadDRAM:
	ld a, (0xc362:16)
	exts wa
	add hl, wa
	jr MidiEvent_ProcessCC_Continue

ProcessNoteEntry_LoadDRAM2:
	ld a, (0xc362:16)
	exts wa
	add wa, hl
	cp a, 0:i3
	jr ge, ProcessNoteEntry_LoadDRAM3
	ld hl, 1:i3
	jr MidiEvent_ProcessCC_Continue

ProcessNoteEntry_LoadDRAM3:
	ld a, (0xc362:16)
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
	incw 1, (xsp + 4)

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
	incw 1, (xsp + 4)
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
	incw 1, (xsp + 4)
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
	ld l, 0x0:opc

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
	cp a, 0:i3
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
	incw 1, (xsp + 2)

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
	incw 1, (xsp + 2)

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
	incw 1, (xsp + 2)
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
	incw 1, (xsp + 2)
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
	ld l, 0x0:opc

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
	cp a, 0:i3
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
	incw 1, (xsp + 2)

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
	incw 1, (xsp + 2)

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
	cp a, 0:i3
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
	incw 1, (xsp + 2)
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
	incw 1, (xsp + 2)
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
	ld l, 0x0:opc

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
	cp a, 0:i3
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
	incw 1, (xsp + 2)

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
	incw 1, (xsp + 2)

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
	cp a, 0:i3
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
	incw 1, (xsp + 2)
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
	incw 1, (xsp + 2)
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
	ld l, 0x0:opc

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
	pushw_erp 0xfa
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
	ld bc, 0:i3
	call NoteMap_FindEntry
	ld xwa, (xsp + 8)
	call NoteMap_FindBestVoiceSlot
	cp l, 0:i3
	jr nz, NoteMap_AltCheckEmit
	ld xwa, (xsp + 4)
	ld bc, 0:i3
	calr NoteMap_AllocateVoice
	ld xwa, (xsp + 4)
	ld bc, 1:i3
	calr NoteMap_AllocateVoice
	cpw (0xce22:16), 0
	jr z, NoteMap_AltCheckEmit
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_AltCheckEmit
	ld xwa, (xsp + 4)
	ld bc, 2:i3
	calr NoteMap_AllocateVoice

NoteMap_AltCheckEmit:
	ld wa, (0xc598:16)
	bit 9, wa
	jr z, AltCheckEmit_LoadParam
	ldib_erp 0xfb, 0
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
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, AltCheckEmit_LoopBody

AltCheckEmit_LoadParam:
	ld xwa, (xsp + 4)
	cp (xwa + 3), 0x0
	jrl nz, NoteMap_AllocCheckNoteOn
	ld xwa, (xsp + 8)
	ld bc, 1:i3
	call NoteMap_EmitNoteOnEvents
	jrl NoteMap_AllocCheckNoteOn

AltCheckEmit_LoadParam2:
	ld xwa, (xsp + 4)
	ld c, (xsp + 2)
	cp	c, (xwa+182)
	jr nz, NoteMap_AllocCheckChannel
	ld a, (xsp + 2)
	ld e, a
	extz de
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	call NoteMap_ResetEntryTimers
	ld xwa, (xsp + 8)
	ld bc, 2:i3
	call NoteMap_FindEntry
	ld xwa, (xsp + 8)
	call NoteMap_FindBestFreeVoice
	cp l, 0:i3
	jr nz, NoteMap_AllocCheckChannel
	call VoiceMap_AllocateSlot
	cp l, 0xff
	jr z, NoteMap_AllocCheckChannel
	ld xwa, (xsp + 4)
	ld bc, 2:i3
	calr NoteMap_AssignVoiceParams
	ld xwa, (xsp + 4)
	ld bc, 2:i3
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
	bit	5, (xwa+bc)
	jr z, AllocCheckChannel_LoadDRAM
	ld c, e
	extz bc
	ld xwa, (xsp + 8)
	call Voice_ScanAndEmitMidiEvents

AllocCheckChannel_LoadDRAM:
	ld wa, (0xc598:16)
	bit 9, wa
	jr z, AllocCheckChannel_LoadParam2
	ldib_erp 0xfb, 0
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
	inc1b_erp 0xfb
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
	ld bc, 0:i3
	call NoteMap_EmitNoteOnEvents

NoteMap_AllocCheckNoteOn:
	popw_erp 0xfa
	lda xsp, (xsp + 10)
	ret

AllocCheckNoteOn_Data:
	lda	xsp, (xsp-10)
	push	qiz
	ld	(xsp+2), e
	ld	(xsp+4), xbc
	ld	(xsp+8), xwa
	cp	(xsp+2), 21
	jr	nz, NoteMap_AddEntry_Skip7
	ld	xwa, (xsp+8)
	ld	bc, 0:i3
	call	NoteMap_FindEntry
	ld	xwa, (xsp+8)
	call	NoteMap_FindBestVoiceSlot
	cp	l, 0:i3
	jr	nz, NoteMap_AddEntry_Skip
	ld	xwa, (xsp+4)
	ld	bc, 0:i3
	calr	NoteMap_AllocateVoice
	ld	xwa, (xsp+4)
	ld	bc, 1:i3
	calr	NoteMap_AllocateVoice
	cpw	(52770:16), 0
	jr	z, NoteMap_AddEntry_Skip
	call	NoteMap_FindBestMatch
	cp	l, 255
	jr	z, NoteMap_AddEntry_Skip
	ld	xwa, (xsp+4)
	ld	bc, 2:i3
	calr	NoteMap_AllocateVoice
NoteMap_AddEntry_Skip:
	ld	wa, (0xc598:16)
	bit	9, wa
	jrl	z, NoteMap_AddEntry_Epilogue
	ldib_erp 251, 0
	cp_erpb 251, 16
	jrl	nc, NoteMap_AddEntry_Epilogue
NoteMap_AddEntry_Loop:
	ldto_berp	a, 251
	extz	wa
	add	wa, 132
	extz	xwa
	.byte 0xaf, 0x04, 0x80, 0x80
	push	xsp
	pop_a
	jr	nz, NoteMap_AddEntry_Skip2
	ldto_berp a, 251
	ld c, a
	extz	bc
	ld	xwa, (xsp+8)
	call	Voice_BuildAndEmitNoteOnEvents
NoteMap_AddEntry_Skip2:
	inc1b_erp 251
	cp_erpb 251, 16
	jr	c, NoteMap_AddEntry_Loop
	jrl	NoteMap_AddEntry_Epilogue
NoteMap_AddEntry_Skip7:
	ld	xwa, (xsp+4)
	ld	c, (xsp+2)
	cp	c, (xwa+182)
	jr	nz, NoteMap_AddEntry_Skip3
	ld	xwa, (xsp+8)
	ld	bc, 2:i3
	call	NoteMap_FindEntry
	ld	xwa, (xsp+8)
	call	NoteMap_FindBestFreeVoice
	cp	l, 0:i3
	jr	nz, NoteMap_AddEntry_Skip3
	call	VoiceMap_AllocateSlot
	cp	l, 255
	jr	z, NoteMap_AddEntry_Skip3
	ld	xwa, (xsp+4)
	ld	bc, 2:i3
	calr	NoteMap_AssignVoiceParams
	ld	xwa, (xsp+4)
	ld	bc, 2:i3
	calr	NoteMap_InitVoiceSlots
NoteMap_AddEntry_Skip3:
	ld	a, (xsp+2)
	ld	c, a
	extz	bc
	ld	xwa, (xsp+8)
	call	NoteMap_AllocNewVoiceEntry
	ld	a, (xsp+2)
	extz	wa
	inc	4, wa
	extz	xwa
	add	xwa, (xsp+4)
	ld	a, (xwa)
	cp	a, (xsp+2)
	jr	nz, NoteMap_AddEntry_Skip4
	ld	a, (xsp+2)
	ld	c, a
	extz	bc
	ld	xwa, (xsp+8)
	call	NoteMap_SetChannelParam
NoteMap_AddEntry_Skip4:
	ld	a, (xsp+2)
	extz	wa
	add	wa, 36
	extz	xwa
	.byte 0xaf, 0x04, 0x80
	ld	e, (xwa)
	ld	a, e
	cp	a, 255
	jr	z, NoteMap_AddEntry_Skip8
	ld	a, (xsp+2)
	extz	wa
	add	wa, wa
	ld	bc, wa
	add	bc, 292
	ld	xwa, (xsp+4)
	bit	5, (xwa+bc)
	jr	z, NoteMap_AddEntry_Skip8
	ld	c, e
	extz	bc
	ld	xwa, (xsp+8)
	call	Voice_ScanAndEmitMidiEvents
NoteMap_AddEntry_Skip8:
	ld	wa, (0xc598:16)
	bit	9, wa
	jr	z, NoteMap_AddEntry_Skip9
	ldib_erp 251, 0
	cp_erpb 251, 16
	jr	nc, NoteMap_AddEntry_Skip9
NoteMap_AddEntry_Loop2:
	ldto_berp	a, 251
	extz	wa
	add	wa, 132
	extz	xwa
	add	xwa, (xsp+4)
	ld	a, (xwa)
	cp	a, (xsp+2)
	jr	nz, NoteMap_AddEntry_Skip5
	ldto_berp a, 251
	ld c, a
	extz	bc
	ld	xwa, (xsp+8)
	call	Voice_BuildAndEmitNoteOnEvents
NoteMap_AddEntry_Skip5:
	inc1b_erp 251
	cp_erpb 251, 16
	jr	c, NoteMap_AddEntry_Loop2
NoteMap_AddEntry_Skip9:
	ld	a, (xsp+2)
	extz	wa
	add	wa, 68
	extz	xwa
	.byte 0xaf, 0x04, 0x80
	ld	a, (xwa)
	ldfr_berp	a, 251
	cp	a, 255
	jr	z, NoteMap_AddEntry_Skip6
	ldto_berp a, 251
	ld c, a
	extz	bc
	ld	xwa, (xsp+8)
	call	SeqPart_EmitNoteOnMessages
NoteMap_AddEntry_Skip6:
	ld	a, (xsp+2)
	extz	wa
	add	wa, 100
	extz	xwa
	.byte 0xaf, 0x04, 0x80
	ld	a, (xwa)
	ldfr_berp	a, 251
	cp	a, 255
	jr	z, NoteMap_AddEntry_Epilogue
	ldto_berp a, 251
	ld c, a
	extz	bc
	ld	xwa, (xsp+8)
	call	Voice_EmitMidiNoteOnEvents
NoteMap_AddEntry_Epilogue:
	pop qiz
	lda	xsp, (xsp+10)
	ret

NoteMap_CollectAndFindBestVoice:
	lda xsp, (xsp-174)
	pushw_erp 0xfa
	ld	(xsp+166), e
	ld	(xsp+168), xbc
	ld	(xsp+172), xwa
	cp	(xsp+166), 0x15
	jrl nz, CollectBestVoice_NonSpecialPath
	lda xwa, (xsp + 2)
	pushw 0x0
	ld	xbc, (xsp+174)
	ld de, 4:i3
	call NoteMap_CollectMatchingEntries
	cp l, 0:i3
	jrl z, NoteMap_PopRetFA_StoreAE
	ld	a, (xsp+166)
	ld e, a
	extz de
	ld	xwa, (xsp+172)
	ld	xbc, (xsp+168)
	call NoteMap_ResetEntryTimers
	lda xwa, (xsp + 2)
	ld bc, 0:i3
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestVoiceSlot
	cp l, 0:i3
	jr nz, NoteMap_AltAllocEmit
	ld	xwa, (xsp+168)
	ld bc, 0:i3
	calr NoteMap_AllocateVoice
	ld	xwa, (xsp+168)
	ld bc, 1:i3
	calr NoteMap_AllocateVoice
	cpw (0xce22:16), 0
	jr z, NoteMap_AltAllocEmit
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_AltAllocEmit
	ld	xwa, (xsp+168)
	ld bc, 2:i3
	calr NoteMap_AllocateVoice

NoteMap_AltAllocEmit:
	ld wa, (0xc598:16)
	bit 9, wa
	jrl z, NoteMap_PopRetFA_StoreAE
	ldib_erp 0xfb, 0
	cp_erpb 0xfb, 0x10
	jrl nc, NoteMap_PopRetFA_StoreAE

CollectBestVoice_EmitLoop:
	ldto_berp A, 0xfb
	extz wa
	add wa, 0x84
	extz xwa
	add	xwa, (xsp+168)
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
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, CollectBestVoice_EmitLoop
	jrl NoteMap_PopRetFA_StoreAE

CollectBestVoice_NonSpecialPath:
	ld	xwa, (xsp+168)
	ld	c, (xsp+166)
	cp	c, (xwa+182)
	jr nz, NoteMap_CollectAndAllocVoice
	lda xwa, (xsp + 2)
	pushw 0x2
	ld	xbc, (xsp+174)
	ld de, 4:i3
	call NoteMap_CollectMatchingEntries
	cp l, 0:i3
	jr z, NoteMap_CollectAndAllocVoice
	ld	a, (xsp+166)
	ld e, a
	extz de
	ld	xwa, (xsp+172)
	ld	xbc, (xsp+168)
	call NoteMap_ResetEntryTimers
	lda xwa, (xsp + 2)
	ld bc, 2:i3
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	cp l, 0:i3
	jr nz, NoteMap_CollectAndAllocVoice
	call VoiceMap_AllocateSlot
	cp l, 0xff
	jr z, NoteMap_CollectAndAllocVoice
	ld	xwa, (xsp+168)
	ld bc, 2:i3
	calr NoteMap_AssignVoiceParams
	ld	xwa, (xsp+168)
	ld bc, 2:i3
	calr NoteMap_InitVoiceSlots

NoteMap_CollectAndAllocVoice:
	lda xwa, (xsp + 2)
	ld xbc, xwa
	ld	a, (xsp+166)
	extz wa
	pushw wa
	ld xwa, xbc
	ld	xbc, (xsp+174)
	ld de, 0:i3
	call NoteMap_CollectMatchingEntries
	cp l, 0:i3
	jrl z, NoteMap_PopRetFA_StoreAE
	lda xwa, (xsp + 2)
	ld xbc, xwa
	ld	a, (xsp+166)
	ld e, a
	extz de
	ld xwa, xbc
	ld	xbc, (xsp+168)
	call NoteMap_ResetEntryTimers
	lda xwa, (xsp + 2)
	ld xde, xwa
	ld	a, (xsp+166)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocNewVoiceEntry
	ld	a, (xsp+166)
	extz wa
	inc 4, wa
	extz xwa
	add	xwa, (xsp+168)
	ld a, (xwa)
	cp	a, (xsp+166)
	jr nz, CollectAllocVoice_CheckDuplicate
	lda xwa, (xsp + 2)
	ld xde, xwa
	ld	a, (xsp+166)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

CollectAllocVoice_CheckDuplicate:
	ld	a, (xsp+166)
	extz wa
	add wa, 0x24
	extz xwa
	add	xwa, (xsp+168)
	ld e, (xwa)
	ld a, e
	cp a, 0xff
	jr z, CollectAllocVoice_EmitCheck
	ld	a, (xsp+166)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld	xwa, (xsp+168)
	bit	5, (xwa+bc)
	jr z, CollectAllocVoice_EmitCheck
	lda xwa, (xsp + 2)
	ld c, e
	extz bc
	call Voice_ScanAndEmitMidiEvents

CollectAllocVoice_EmitCheck:
	ld wa, (0xc598:16)
	bit 9, wa
	jr z, CollectAllocVoice_Em_LoadFromStack
	ldib_erp 0xfb, 0
	cp_erpb 0xfb, 0x10
	jr nc, CollectAllocVoice_Em_LoadFromStack

CollectAllocVoice_EmitLoop:
	ldto_berp A, 0xfb
	extz wa
	add wa, 0x84
	extz xwa
	add	xwa, (xsp+168)
	ld a, (xwa)
	cp	a, (xsp+166)
	jr nz, CollectAllocVoice_Em_Block
	lda xwa, (xsp + 2)
	ld xde, xwa
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

CollectAllocVoice_Em_Block:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, CollectAllocVoice_EmitLoop

CollectAllocVoice_Em_LoadFromStack:
	ld	a, (xsp+166)
	extz wa
	add wa, 0x44
	extz xwa
	add	xwa, (xsp+168)
	ld a, (xwa)
	ldfr_berp A, 0xfb
	cp a, 0xff
	jr z, CollectAllocVoice_Em_LoadFromStack2
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld	xwa, (xsp+172)
	call SeqPart_EmitNoteOnMessages

CollectAllocVoice_Em_LoadFromStack2:
	ld	a, (xsp+166)
	extz wa
	add wa, 0x64
	extz xwa
	add	xwa, (xsp+168)
	ld a, (xwa)
	ldfr_berp A, 0xfb
	cp a, 0xff
	jr z, NoteMap_PopRetFA_StoreAE
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld	xwa, (xsp+172)
	call Voice_EmitMidiNoteOnEvents

NoteMap_PopRetFA_StoreAE:
	popw_erp 0xfa
	lda xsp, (xsp+174:16)
	ret

NoteMap_CollectAndAllocVoice_NoTimerCheck:
	lda xsp, (xsp - 10)
	pushw_erp 0xfa
	ld (xsp + 2), e
	ld (xsp + 4), xbc
	ld (xsp + 8), xwa
	cp (xsp + 2), 0x15
	jrl nz, FallbackVoiceCheck_LoadParam2
	ld xwa, (xsp + 8)
	ld bc, 0:i3
	call NoteMap_FindEntry
	ld xwa, (xsp + 8)
	call NoteMap_FindBestVoiceSlot
	cp l, 1:i3
	jr nz, NoteMap_FallbackVoiceCheck
	ld xwa, (xsp + 4)
	ld bc, 0:i3
	calr NoteMap_AllocateVoice
	ld xwa, (xsp + 4)
	ld bc, 1:i3
	calr NoteMap_AllocateVoice
	cpw (0xce22:16), 0
	jr z, NoteMap_FallbackVoiceCheck
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_FallbackVoiceCheck
	ld xwa, (xsp + 4)
	ld bc, 2:i3
	calr NoteMap_AllocateVoice

NoteMap_FallbackVoiceCheck:
	ld wa, (0xc598:16)
	bit 9, wa
	jr z, FallbackVoiceCheck_LoadParam
	ldib_erp 0xfb, 0
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
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, FallbackVoiceCheck_LoopBody

FallbackVoiceCheck_LoadParam:
	ld xwa, (xsp + 4)
	cp (xwa + 3), 0x0
	jrl nz, NoteMap_AllocVoiceEmit
	ld xwa, (xsp + 8)
	ld bc, 1:i3
	call NoteMap_EmitNoteOnEvents
	jrl NoteMap_AllocVoiceEmit

FallbackVoiceCheck_LoadParam2:
	ld xwa, (xsp + 4)
	ld c, (xsp + 2)
	cp	c, (xwa+182)
	jr nz, NoteMap_LookupAllocEmit
	ld xwa, (xsp + 8)
	ld bc, 2:i3
	call NoteMap_FindEntry
	ld xwa, (xsp + 8)
	call NoteMap_FindBestFreeVoice
	cp l, 1:i3
	jr nz, NoteMap_LookupAllocEmit
	call VoiceMap_AllocateSlot
	cp l, 0xff
	jr z, NoteMap_LookupAllocEmit
	ld xwa, (xsp + 4)
	ld bc, 2:i3
	calr NoteMap_AssignVoiceParams
	ld xwa, (xsp + 4)
	ld bc, 2:i3
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
	ld wa, (0xc598:16)
	bit 9, wa
	jr z, LookupAllocEmit_LoadParam
	ldib_erp 0xfb, 0
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
	inc1b_erp 0xfb
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
	ld bc, 0:i3
	call NoteMap_EmitNoteOnEvents

NoteMap_AllocVoiceEmit:
	popw_erp 0xfa
	lda xsp, (xsp + 10)
	ret

NoteMap_CollectAndAllocVoice_Indirect:
	lda xsp, (xsp-174)
	pushw_erp 0xfa
	ld	(xsp+166), e
	ld	(xsp+168), xbc
	ld	(xsp+172), xwa
	cp	(xsp+166), 0x15
	jrl nz, IndirectCollectEmit_LoadFromStack
	lda xwa, (xsp + 2)
	pushw 0x0
	ld	xbc, (xsp+174)
	ld de, 4:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jrl z, NoteMap_PopRetFA_StoreAE2
	lda xwa, (xsp + 2)
	ld bc, 0:i3
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestVoiceSlot
	cp l, 1:i3
	jr nz, NoteMap_IndirectCollectEmit
	ld	xwa, (xsp+168)
	ld bc, 0:i3
	calr NoteMap_AllocateVoice
	ld	xwa, (xsp+168)
	ld bc, 1:i3
	calr NoteMap_AllocateVoice
	cpw (0xce22:16), 0
	jr z, NoteMap_IndirectCollectEmit
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_IndirectCollectEmit
	ld	xwa, (xsp+168)
	ld bc, 2:i3
	calr NoteMap_AllocateVoice

NoteMap_IndirectCollectEmit:
	ld wa, (0xc598:16)
	bit 9, wa
	jrl z, NoteMap_PopRetFA_StoreAE2
	ldib_erp 0xfb, 0
	cp_erpb 0xfb, 0x10
	jrl nc, NoteMap_PopRetFA_StoreAE2

IndirectCollectEmit_LoopBody:
	ldto_berp A, 0xfb
	extz wa
	add wa, 0x84
	extz xwa
	add	xwa, (xsp+168)
	ld a, (xwa)
	cp	a, (xsp+166)
	jr nz, IndirectCollectEmit_LoopCheck
	lda xwa, (xsp + 2)
	ld xde, xwa
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

IndirectCollectEmit_LoopCheck:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, IndirectCollectEmit_LoopBody
	jrl NoteMap_PopRetFA_StoreAE2

IndirectCollectEmit_LoadFromStack:
	ld	xwa, (xsp+168)
	ld	c, (xsp+166)
	cp	c, (xwa+182)
	jr nz, NoteMap_LookupAllocAndSetChannel
	lda xwa, (xsp + 2)
	pushw 0x2
	ld	xbc, (xsp+174)
	ld de, 4:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, NoteMap_LookupAllocAndSetChannel
	lda xwa, (xsp + 2)
	ld bc, 2:i3
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	cp l, 1:i3
	jr nz, NoteMap_LookupAllocAndSetChannel
	call VoiceMap_AllocateSlot
	cp l, 0xff
	jr z, NoteMap_LookupAllocAndSetChannel
	ld	xwa, (xsp+168)
	ld bc, 2:i3
	calr NoteMap_AssignVoiceParams
	ld	xwa, (xsp+168)
	ld bc, 2:i3
	calr NoteMap_InitVoiceSlots

NoteMap_LookupAllocAndSetChannel:
	lda xwa, (xsp + 2)
	ld xbc, xwa
	ld	a, (xsp+166)
	extz wa
	pushw wa
	ld xwa, xbc
	ld	xbc, (xsp+174)
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jrl z, NoteMap_PopRetFA_StoreAE2
	lda xwa, (xsp + 2)
	ld xde, xwa
	ld	a, (xsp+166)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocNewVoiceEntry
	lda xwa, (xsp + 2)
	ld xde, xwa
	ld	a, (xsp+166)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	ld wa, (0xc598:16)
	bit 9, wa
	jr z, LookupAllocAndSetCha_LoadFromStack
	ldib_erp 0xfb, 0
	cp_erpb 0xfb, 0x10
	jr nc, LookupAllocAndSetCha_LoadFromStack

LookupAllocAndSetCha_LoopBody:
	ldto_berp A, 0xfb
	extz wa
	add wa, 0x84
	extz xwa
	add	xwa, (xsp+168)
	ld a, (xwa)
	cp	a, (xsp+166)
	jr nz, LookupAllocAndSetCha_LoopCheck
	lda xwa, (xsp + 2)
	ld xde, xwa
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

LookupAllocAndSetCha_LoopCheck:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, LookupAllocAndSetCha_LoopBody

LookupAllocAndSetCha_LoadFromStack:
	ld	a, (xsp+166)
	extz wa
	add wa, 0x44
	extz xwa
	add	xwa, (xsp+168)
	ld a, (xwa)
	ldfr_berp A, 0xfb
	cp a, 0xff
	jr z, LookupAllocAndSetCha_LoadFromStack2
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld	xwa, (xsp+172)
	call SeqPart_EmitNoteOnMessages

LookupAllocAndSetCha_LoadFromStack2:
	ld	a, (xsp+166)
	extz wa
	add wa, 0x64
	extz xwa
	add	xwa, (xsp+168)
	ld a, (xwa)
	ldfr_berp A, 0xfb
	cp a, 0xff
	jr z, NoteMap_PopRetFA_StoreAE2
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld	xwa, (xsp+172)
	call Voice_EmitMidiNoteOnEvents

NoteMap_PopRetFA_StoreAE2:
	popw_erp 0xfa
	lda xsp, (xsp+174:16)
	ret

NoteMap_UpdateEntry:
	lda xsp, (xsp - 10)
	pushw_erp 0xfa
	ld (xsp + 2), e
	ld (xsp + 4), xbc
	ld (xsp + 8), xwa
	cp (xsp + 2), 0x15
	jrl nz, UpdateEntry_NonSpecialPath
	ld xwa, (xsp + 8)
	ld bc, 0:i3
	call NoteMap_FindEntry
	ld xwa, (xsp + 8)
	call NoteMap_FindBestVoiceSlot
	cp l, 0:i3
	jr nz, NoteMap_FallbackAllocEmit
	ld xwa, (xsp + 4)
	ld bc, 0:i3
	calr NoteMap_AllocateVoice
	ld xwa, (xsp + 4)
	ld bc, 1:i3
	calr NoteMap_AllocateVoice
	cpw (0xce22:16), 0
	jr z, NoteMap_FallbackAllocEmit
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_FallbackAllocEmit
	ld xwa, (xsp + 4)
	ld bc, 2:i3
	calr NoteMap_AllocateVoice

NoteMap_FallbackAllocEmit:
	ld wa, (0xc598:16)
	bit 9, wa
	jr z, UpdateEntry_CheckLayerCount
	ldib_erp 0xfb, 0
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
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, UpdateEntry_EmitLoop

UpdateEntry_CheckLayerCount:
	ld xwa, (xsp + 4)
	cp (xwa + 3), 0x0
	jrl nz, NoteMap_CollectBestEmit
	ld xwa, (xsp + 8)
	ld bc, 1:i3
	call NoteMap_EmitNoteOnEvents
	jrl NoteMap_CollectBestEmit

UpdateEntry_NonSpecialPath:
	ld xwa, (xsp + 4)
	ld c, (xsp + 2)
	cp	c, (xwa+182)
	jr nz, NoteMap_DirectLookupEmit
	ld xwa, (xsp + 8)
	ld bc, 2:i3
	call NoteMap_FindEntry
	ld xwa, (xsp + 8)
	call NoteMap_FindBestFreeVoice
	cp l, 0:i3
	jr nz, NoteMap_DirectLookupEmit
	call VoiceMap_AllocateSlot
	cp l, 0xff
	jr z, NoteMap_DirectLookupEmit
	ld xwa, (xsp + 4)
	ld bc, 2:i3
	calr NoteMap_AssignVoiceParams
	ld xwa, (xsp + 4)
	ld bc, 2:i3
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
	ld wa, (0xc598:16)
	bit 9, wa
	jr z, UpdateEntry_CheckSeqPartEmit
	ldib_erp 0xfb, 0
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
	inc1b_erp 0xfb
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
	ld bc, 0:i3
	call NoteMap_EmitNoteOnEvents

NoteMap_CollectBestEmit:
	popw_erp 0xfa
	lda xsp, (xsp + 10)
	ret

NoteMap_FindAndAllocBestVoice:
	lda xsp, (xsp-174)
	pushw_erp 0xfa
	ld	(xsp+166), e
	ld	(xsp+168), xbc
	ld	(xsp+172), xwa
	cp	(xsp+166), 0x15
	jrl nz, FindAllocBest_NonSpecialPath
	lda xwa, (xsp + 2)
	pushw 0x0
	ld	xbc, (xsp+174)
	ld de, 4:i3
	call NoteMap_CollectMatchingEntries
	cp l, 0:i3
	jrl z, NoteMap_PopRetFA_StoreAE3
	lda xwa, (xsp + 2)
	ld bc, 0:i3
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestVoiceSlot
	cp l, 0:i3
	jr nz, NoteMap_FindAllocEmit
	ld	xwa, (xsp+168)
	ld bc, 0:i3
	calr NoteMap_AllocateVoice
	ld	xwa, (xsp+168)
	ld bc, 1:i3
	calr NoteMap_AllocateVoice
	cpw (0xce22:16), 0
	jr z, NoteMap_FindAllocEmit
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_FindAllocEmit
	ld	xwa, (xsp+168)
	ld bc, 2:i3
	calr NoteMap_AllocateVoice

NoteMap_FindAllocEmit:
	ld wa, (0xc598:16)
	bit 9, wa
	jrl z, NoteMap_PopRetFA_StoreAE3
	ldib_erp 0xfb, 0
	cp_erpb 0xfb, 0x10
	jrl nc, NoteMap_PopRetFA_StoreAE3

FindAllocEmit_LoopBody:
	ldto_berp A, 0xfb
	extz wa
	add wa, 0x84
	extz xwa
	add	xwa, (xsp+168)
	ld a, (xwa)
	cp	a, (xsp+166)
	jr nz, FindAllocEmit_LoopCheck
	lda xwa, (xsp + 2)
	ld xde, xwa
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

FindAllocEmit_LoopCheck:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, FindAllocEmit_LoopBody
	jrl NoteMap_PopRetFA_StoreAE3

FindAllocBest_NonSpecialPath:
	ld	xwa, (xsp+168)
	ld	c, (xsp+166)
	cp	c, (xwa+182)
	jr nz, NoteMap_CollectAndAllocVoice_NoTimerReset
	lda xwa, (xsp + 2)
	pushw 0x2
	ld	xbc, (xsp+174)
	ld de, 4:i3
	call NoteMap_CollectMatchingEntries
	cp l, 0:i3
	jr z, NoteMap_CollectAndAllocVoice_NoTimerReset
	lda xwa, (xsp + 2)
	ld bc, 2:i3
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	cp l, 0:i3
	jr nz, NoteMap_CollectAndAllocVoice_NoTimerReset
	call VoiceMap_AllocateSlot
	cp l, 0xff
	jr z, NoteMap_CollectAndAllocVoice_NoTimerReset
	ld	xwa, (xsp+168)
	ld bc, 2:i3
	calr NoteMap_AssignVoiceParams
	ld	xwa, (xsp+168)
	ld bc, 2:i3
	calr NoteMap_InitVoiceSlots

NoteMap_CollectAndAllocVoice_NoTimerReset:
	lda xwa, (xsp + 2)
	ld xbc, xwa
	ld	a, (xsp+166)
	extz wa
	pushw wa
	ld xwa, xbc
	ld	xbc, (xsp+174)
	ld de, 0:i3
	call NoteMap_CollectMatchingEntries
	cp l, 0:i3
	jrl z, NoteMap_PopRetFA_StoreAE3
	lda xwa, (xsp + 2)
	ld xde, xwa
	ld	a, (xsp+166)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocNewVoiceEntry
	lda xwa, (xsp + 2)
	ld xde, xwa
	ld	a, (xsp+166)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	ld wa, (0xc598:16)
	bit 9, wa
	jr z, CollectAndAllocVoice_LoadFromStack
	ldib_erp 0xfb, 0
	cp_erpb 0xfb, 0x10
	jr nc, CollectAndAllocVoice_LoadFromStack

CollectAndAllocVoice_LoopBody:
	ldto_berp A, 0xfb
	extz wa
	add wa, 0x84
	extz xwa
	add	xwa, (xsp+168)
	ld a, (xwa)
	cp	a, (xsp+166)
	jr nz, CollectAndAllocVoice_LoopCheck
	lda xwa, (xsp + 2)
	ld xde, xwa
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

CollectAndAllocVoice_LoopCheck:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, CollectAndAllocVoice_LoopBody

CollectAndAllocVoice_LoadFromStack:
	ld	a, (xsp+166)
	extz wa
	add wa, 0x44
	extz xwa
	add	xwa, (xsp+168)
	ld a, (xwa)
	ldfr_berp A, 0xfb
	cp a, 0xff
	jr z, CollectAndAllocVoice_LoadFromStack2
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld	xwa, (xsp+172)
	call SeqPart_EmitNoteOnMessages

CollectAndAllocVoice_LoadFromStack2:
	ld	a, (xsp+166)
	extz wa
	add wa, 0x64
	extz xwa
	add	xwa, (xsp+168)
	ld a, (xwa)
	ldfr_berp A, 0xfb
	cp a, 0xff
	jr z, NoteMap_PopRetFA_StoreAE3
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld	xwa, (xsp+172)
	call Voice_EmitMidiNoteOnEvents

NoteMap_PopRetFA_StoreAE3:
	popw_erp 0xfa
	lda xsp, (xsp+174:16)
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
	ld bc, 0:i3
	call NoteMap_FindEntry
	ld xwa, (xsp + 6)
	call NoteMap_FindBestVoiceSlot
	cp l, 2:i3
	jr z, PopRetFA_StoreAE3_LoadIter
	cp l, 3:i3
	jr nz, NoteMap_AllocVoice_Done

PopRetFA_StoreAE3_LoadIter:
	ld xwa, xiz
	ld bc, 0:i3
	calr NoteMap_AllocateVoice
	ld xwa, xiz
	ld bc, 1:i3
	calr NoteMap_AllocateVoice
	cpw (0xce22:16), 0
	jr z, NoteMap_AllocVoice_Done
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_AllocVoice_Done
	ld xwa, xiz
	ld bc, 2:i3
	calr NoteMap_AllocateVoice

NoteMap_AllocVoice_Done:
	cp (xiz + 3), 0x0
	jrl nz, NoteMap_UpdateVoiceSlots_Return
	ld xwa, (xsp + 6)
	ld bc, 1:i3
	call NoteMap_EmitNoteOnEvents
	jrl NoteMap_UpdateVoiceSlots_Return

AllocVoice_Done_LoadParam:
	ld a, (xsp + 4)
	cp	a, (xiz+182)
	jr nz, NoteMap_AllocVoiceEntry_Continue
	ld a, (xsp + 4)
	ld e, a
	extz de
	ld xwa, (xsp + 6)
	ld xbc, xiz
	call SndParam_ComputeVoiceTuning
	ld xwa, (xsp + 6)
	ld bc, 2:i3
	call NoteMap_FindEntry
	ld xwa, (xsp + 6)
	call NoteMap_FindBestFreeVoice
	cp l, 2:i3
	jr z, AllocVoice_Done_TryAlloc
	cp l, 3:i3
	jr nz, AllocVoice_Done_LoadIter

AllocVoice_Done_TryAlloc:
	call VoiceMap_AllocateSlot
	cp l, 0xff
	jr z, NoteMap_AllocVoiceEntry_Continue
	ld xwa, xiz
	ld bc, 2:i3
	calr NoteMap_AssignVoiceParams
	ld xwa, xiz
	ld bc, 2:i3
	calr NoteMap_InitVoiceSlots
	jr NoteMap_AllocVoiceEntry_Continue

AllocVoice_Done_LoadIter:
	ld xwa, xiz
	ld bc, 2:i3
	calr NoteMap_AssignVoiceParams
	ldw (0xce66:16), 0
	ld (0xceb2:16), 0

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
	bit	5, (xiz+wa)
	jr z, AllocVoiceEntry_Cont_LoadParam2
	extz bc
	ld xwa, (xsp + 6)
	call Voice_ScanAndEmitMidiEvents

AllocVoiceEntry_Cont_LoadParam2:
	ld a, (xsp + 4)
	cp a, (xiz + 2)
	jr nz, NoteMap_UpdateVoiceSlots_Return
	ld xwa, (xsp + 6)
	ld bc, 0:i3
	call NoteMap_EmitNoteOnEvents

NoteMap_UpdateVoiceSlots_Return:
	pop xiz
	inc 6, xsp
	ret

NoteMap_ProcessNoteEvent:
	lda xsp, (xsp-174)
	ld	(xsp+164), e
	ld	(xsp+166), xbc
	ld	(xsp+170), xwa
	cp	(xsp+164), 0x15
	jr nz, ProcessNoteEvent_LoadFromStack2
	lda xwa, (xsp)
	pushw 0x0
	ld	xbc, (xsp+172)
	ld de, 4:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jrl z, NoteMap_StoreAllocResult
	lda xwa, (xsp)
	ld bc, 0:i3
	call NoteMap_FindEntry
	lda xwa, (xsp)
	call NoteMap_FindBestVoiceSlot
	cp l, 2:i3
	jr z, ProcessNoteEvent_LoadFromStack
	cp l, 3:i3
	jrl nz, NoteMap_StoreAllocResult

ProcessNoteEvent_LoadFromStack:
	ld	xwa, (xsp+166)
	ld bc, 0:i3
	calr NoteMap_AllocateVoice
	ld	xwa, (xsp+166)
	ld bc, 1:i3
	calr NoteMap_AllocateVoice
	cpw (0xce22:16), 0
	jrl z, NoteMap_StoreAllocResult
	call NoteMap_FindBestMatch
	cp l, 0xff
	jrl z, NoteMap_StoreAllocResult
	ld	xwa, (xsp+166)
	ld bc, 2:i3
	calr NoteMap_AllocateVoice
	jrl NoteMap_StoreAllocResult

ProcessNoteEvent_LoadFromStack2:
	ld	xwa, (xsp+166)
	ld	c, (xsp+164)
	cp	c, (xwa+182)
	jr nz, NoteMap_LookupAllocAndStore
	lda xwa, (xsp)
	pushw 0x2
	ld	xbc, (xsp+172)
	ld de, 4:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, NoteMap_LookupAllocAndStore
	lda xwa, (xsp)
	ld bc, 2:i3
	call NoteMap_FindEntry
	lda xwa, (xsp)
	call NoteMap_FindBestFreeVoice
	cp l, 2:i3
	jr z, ProcessNoteEvent_TryAlloc
	cp l, 3:i3
	jr nz, ProcessNoteEvent_LoadFromStack3

ProcessNoteEvent_TryAlloc:
	call VoiceMap_AllocateSlot
	cp l, 0xff
	jr z, NoteMap_LookupAllocAndStore
	ld	xwa, (xsp+166)
	ld bc, 2:i3
	calr NoteMap_AssignVoiceParams
	ld	xwa, (xsp+166)
	ld bc, 2:i3
	calr NoteMap_InitVoiceSlots
	jr NoteMap_LookupAllocAndStore

ProcessNoteEvent_LoadFromStack3:
	ld	xwa, (xsp+166)
	ld bc, 2:i3
	calr NoteMap_AssignVoiceParams
	ldw (0xce66:16), 0
	ld (0xceb2:16), 0

NoteMap_LookupAllocAndStore:
	lda xwa, (xsp)
	ld xbc, xwa
	ld	a, (xsp+164)
	extz wa
	pushw wa
	ld xwa, xbc
	ld	xbc, (xsp+172)
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, NoteMap_StoreAllocResult
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+164)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocNewVoiceEntry
	ld a, (xsp + 3)
	extz wa
	add wa, 0x94
	extz xwa
	add	xwa, (xsp+166)
	ld a, (xwa)
	cp	a, (xsp+164)
	jr nz, LookupAllocAndStore_LoadParam
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+164)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LookupAllocAndStore_LoadParam:
	ld a, (xsp + 3)
	extz wa
	add wa, 0xa4
	extz xwa
	add	xwa, (xsp+166)
	ld e, (xwa)
	ld a, e
	cp a, 0xff
	jr z, NoteMap_StoreAllocResult
	ld	a, (xsp+164)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld	xwa, (xsp+166)
	bit	5, (xwa+bc)
	jr z, NoteMap_StoreAllocResult
	lda xwa, (xsp)
	ld c, e
	extz bc
	call Voice_ScanAndEmitMidiEvents

NoteMap_StoreAllocResult:
	lda xsp, (xsp+174:16)
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
	bit	5, (xwa+bc)
	jr z, ProcessRhythmNoteOn_Epilogue
	ld c, e
	extz bc
	ld xwa, (xsp + 6)
	call Voice_ScanAndEmitMidiEvents

ProcessRhythmNoteOn_Epilogue:
	lda xsp, (xsp + 10)
	ret

NoteMap_LookupAndAllocVoice:
	lda xsp, (xsp-170)
	ld	(xsp+164), e
	ld	(xsp+166), xbc
	lda xbc, (xsp)
	ld xde, xbc
	ld	c, (xsp+164)
	extz bc
	pushw bc
	ld xbc, xde
	ld xde, xwa
	ld xwa, xbc
	ld xbc, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jrl z, LookupAndAllocVoice_LoadFromStack2
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+164)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocNewVoiceEntry
	ld	a, (xsp+164)
	extz wa
	inc 4, wa
	extz xwa
	add	xwa, (xsp+166)
	ld a, (xwa)
	cp	a, (xsp+164)
	jr nz, LookupAndAllocVoice_LoadFromStack
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+164)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LookupAndAllocVoice_LoadFromStack:
	ld	a, (xsp+164)
	extz wa
	add wa, 0x24
	extz xwa
	add	xwa, (xsp+166)
	ld e, (xwa)
	ld a, e
	cp a, 0xff
	jr z, Voice_SetParam_Return
	ld	a, (xsp+164)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld	xwa, (xsp+166)
	bit	5, (xwa+bc)
	jr z, Voice_SetParam_Return
	lda xwa, (xsp)
	ld c, e
	extz bc
	call Voice_ScanAndEmitMidiEvents
	jr Voice_SetParam_Return

LookupAndAllocVoice_LoadFromStack2:
	ld	a, (xsp+164)
	extz wa
	inc 4, wa
	extz xwa
	add	xwa, (xsp+166)
	ld a, (xwa)
	cp	a, (xsp+164)
	jr nz, Voice_SetParam_Return
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+164)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

Voice_SetParam_Return:
	lda xsp, (xsp+170:16)
	ret

NoteMap_ProcessRhythmRemap:
	lda xsp, (xsp-170)
	ld	(xsp+164), e
	ld	(xsp+166), xbc
	ld xbc, xwa
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+164)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_CollectMatchingEntries
	cp l, 0:i3
	jrl z, NoteMap_ProcessNoteOff_Done
	lda xwa, (xsp)
	ld xbc, xwa
	ld	a, (xsp+164)
	ld e, a
	extz de
	ld xwa, xbc
	ld	xbc, (xsp+166)
	call NoteMap_ComputePitchOffset
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+164)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocNewVoiceEntry
	ld	a, (xsp+164)
	extz wa
	inc 4, wa
	extz xwa
	add	xwa, (xsp+166)
	ld a, (xwa)
	cp	a, (xsp+164)
	jr nz, ProcessRhythmRemap_LoadFromStack
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+164)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

ProcessRhythmRemap_LoadFromStack:
	ld	a, (xsp+164)
	extz wa
	add wa, 0x24
	extz xwa
	add	xwa, (xsp+166)
	ld e, (xwa)
	ld a, e
	cp a, 0xff
	jr z, NoteMap_ProcessNoteOff_Done
	ld	a, (xsp+164)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld	xwa, (xsp+166)
	bit	5, (xwa+bc)
	jr z, NoteMap_ProcessNoteOff_Done
	lda xwa, (xsp)
	ld c, e
	extz bc
	call Voice_ScanAndEmitMidiEvents

NoteMap_ProcessNoteOff_Done:
	lda xsp, (xsp+170:16)
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
	lda xsp, (xsp-170)
	ld	(xsp+164), e
	ld	(xsp+166), xbc
	lda xbc, (xsp)
	ld xde, xbc
	ld	c, (xsp+164)
	extz bc
	pushw bc
	ld xbc, xwa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, LookupAllocAndStoreR_WriteReg
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+164)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocNewVoiceEntry
	ld	a, (xsp+164)
	extz wa
	inc 4, wa
	extz xwa
	add	xwa, (xsp+166)
	ld a, (xwa)
	cp	a, (xsp+164)
	jr nz, LookupAllocAndStoreR_WriteReg
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+164)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LookupAllocAndStoreR_WriteReg:
	lda xsp, (xsp+170:16)
	ret

NoteMap_InitVoiceSlots:
	lda xsp, (xsp-172)
	push xiz
	ld	(xsp+170), c
	ld	(xsp+172), xwa
	ld	a, (xsp+170)
	extz wa
	add wa, 0xbc
	extz xwa
	add	xwa, (xsp+172)
	ld a, (xwa)
	ld (xsp + 4), a
	cp a, 0xff
	jrl z, NoteMap_PopIz_StoreAC
	ld	a, (xsp+170)
	extz wa
	sla wa, 2
	lda xbc, (NoteMap_VoiceSlotRamPtrs:24)
	ld	xiz, (xbc+wa)
	cpw (xiz), 0x0
	jrl z, NoteMap_PopIz_StoreAC
	ld wa, (xiz)
	ld (xsp + 7), a
	ld (xsp + 6), 0x90
	ld (xsp + 8), 0x6
	ld	a, (xsp+170)
	ld (xsp + 9), a
	ld de, 0:i3
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
	ld	xbc, (xsp+172)
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
	add	xwa, (xsp+172)
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
	add	xwa, (xsp+172)
	ld e, (xwa)
	ld a, e
	cp a, 0xff
	jr z, NoteMap_PopIz_StoreAC
	ld a, (xsp + 4)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld	xwa, (xsp+172)
	bit	5, (xwa+bc)
	jr z, NoteMap_PopIz_StoreAC
	cp	(xsp+170), 0x02
	jr nz, InitVoiceSlots_EmitMidi
	ld	xwa, (xsp+172)
	bit	5, (xwa+342)
	jr z, NoteMap_PopIz_StoreAC

InitVoiceSlots_EmitMidi:
	lda xwa, (xsp + 6)
	ld c, e
	extz bc
	call Voice_ScanAndEmitMidiEvents

NoteMap_PopIz_StoreAC:
	pop xiz
	lda xsp, (xsp+172:16)
	ret

; ============================================================================
; NoteMap_AssignVoiceParams - Assign voice parameters for note-on events
; ============================================================================
; Input:  Voice channel parameters
; Output: None
; Iterates voice slots, validates format, looks up voice, assigns params.
; ============================================================================
NoteMap_AssignVoiceParams:
	lda xsp, (xsp-174)
	pushw_erp 0xfa
	ld	(xsp+170), c
	ld	(xsp+172), xwa
	ld	a, (xsp+170)
	extz wa
	add wa, 0xbc
	extz xwa
	add	xwa, (xsp+172)
	ld a, (xwa)
	ldfr_berp A, 0xfb
	cp a, 0xff
	jrl z, NoteMap_PopRetFA_StoreAE4
	ld	a, (xsp+170)
	extz wa
	sla wa, 2
	lda xbc, (NoteMap_VoiceSlotRamPtrs:24)
	ld	xwa, (xbc+wa)
	ld (xsp + 2), xwa
	ld (xsp + 6), 0x90
	ld (xsp + 8), 0x6
	ld	a, (xsp+170)
	ld (xsp + 9), a
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp + 6)
	ld xbc, xwa
	ldto_berp A, 0xfb
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
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
	add	xwa, (xsp+172)
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
	add	xwa, (xsp+172)
	ld e, (xwa)
	ld a, e
	cp a, 0xff
	jr z, NoteMap_PopRetFA_StoreAE4
	ldto_berp A, 0xfb
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld	xwa, (xsp+172)
	bit	5, (xwa+bc)
	jr z, NoteMap_PopRetFA_StoreAE4
	cp	(xsp+170), 0x02
	jr nz, AssignVoiceParams_Ch_LoadAddr
	ld	xwa, (xsp+172)
	bit	5, (xwa+342)
	jr z, NoteMap_PopRetFA_StoreAE4

AssignVoiceParams_Ch_LoadAddr:
	lda xwa, (xsp + 6)
	ld c, e
	extz bc
	call Voice_ScanAndEmitMidiEvents

NoteMap_PopRetFA_StoreAE4:
	popw_erp 0xfa
	lda xsp, (xsp+174:16)
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
	lda xsp, (xsp-172)
	push xiz
	ld	(xsp+170), c
	ld	(xsp+172), xwa
	ld	a, (xsp+170)
	extz wa
	add wa, 0xbc
	extz xwa
	add	xwa, (xsp+172)
	ld a, (xwa)
	ld (xsp + 4), a
	cp a, 0xff
	jrl z, NoteMap_PopIz_StoreAC2
	ld	a, (xsp+170)
	extz wa
	sla wa, 2
	lda xbc, (NoteMap_VoiceSlotRamPtrs:24)
	ld	xiz, (xbc+wa)
	ld wa, (xiz)
	ld (xsp + 7), a
	ld (xsp + 6), 0x90
	ld (xsp + 8), 0x6
	ld	a, (xsp+170)
	ld (xsp + 9), a
	ld de, 0:i3
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
	ld de, 0:i3
	call NoteMap_CollectMatchingEntries
	cp l, 0:i3
	jrl z, NoteMap_PopIz_StoreAC2
	lda xwa, (xsp + 6)
	ld xbc, xwa
	ld a, (xsp + 4)
	ld e, a
	extz de
	ld xwa, xbc
	ld	xbc, (xsp+172)
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
	add	xwa, (xsp+172)
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
	add	xwa, (xsp+172)
	ld e, (xwa)
	ld a, e
	cp a, 0xff
	jr z, NoteMap_PopIz_StoreAC2
	ld a, (xsp + 4)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld	xwa, (xsp+172)
	bit	5, (xwa+bc)
	jr z, NoteMap_PopIz_StoreAC2
	cp	(xsp+170), 0x02
	jr nz, AllocateVoice_LoadAddr3
	ld	xwa, (xsp+172)
	bit	5, (xwa+342)
	jr z, NoteMap_PopIz_StoreAC2

AllocateVoice_LoadAddr3:
	lda xwa, (xsp + 6)
	ld c, e
	extz bc
	call Voice_ScanAndEmitMidiEvents

NoteMap_PopIz_StoreAC2:
	pop xiz
	lda xsp, (xsp+172:16)
	ret

NoteMap_SwapVoiceLinks:
	ld e, c
	extz de
	add de, de
	ld	e, (xwa+de)
	extz de
	add de, de
	lda	xhl, (xwa+de)
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
	ld	c, (xwa+bc)
	ld	(xwa+de), c
	ret

NoteMap_LinkVoiceSlots:
	ld l, c
	extz hl
	add hl, hl
	lda	xix, (xwa+hl)
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
	ld	(xwa+hl), e
	ld l, e
	extz hl
	add hl, hl
	exts xhl
	add xhl, xwa
	ld l, (xhl + 1)
	extz hl
	add hl, hl
	ld	(xwa+hl), c
	extz de
	add de, de
	lda	xwa, (xwa+de)
	ld (xwa + 1), c
	ret

LinkVoiceSlots_LoadReg:
	ld e, c
	extz de
	add de, de
	lda	xwa, (xwa+de)
	cp (xwa + 1), c
	jr nz, LinkVoiceSlots_InitVal
	ld hl, 0:i3
	ret

LinkVoiceSlots_InitVal:
	ld hl, 1:i3
	ret

LinkVoiceSlots_Block:
	lda xix, (0xc5ca:16)
	lda xiy, (0xe7e8:16)
	ld e, (xwa + 3)
	extz de
	lda xhl, (NoteMap_LinkByte_Table:24)
	ld	e, (xhl+de)
	extz bc
	muls bc, 0x5
	inc 4, bc
	ld	c, (xwa+bc)
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
	lda xhl, (0xc5ca:16)
	lda xix, (0xe7e8:16)
	ld c, 0x20:opc
	cp (xwa + 3), 0x2
	jrl nc, LookupAndMergeVoice_Deref
	ld c, (xwa + 3)
	extz bc
	lda xde, (NoteMap_LinkByte_Table:24)
	ld	c, (xde+bc)
	ldfr_berp C, 0xea
	ld de, 0:i3
	ldto_berp C, 0xea
	extz bc
	add bc, bc
	ld	c, (xix+bc)
	ldfr_berp C, 0xeb
	cpb_erp C, 0xea
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
	ld	c, (xix+bc)
	ldfr_berp C, 0xeb
	inc 1, de
	ldto_berp C, 0xeb
	cpb_erp C, 0xea
	jr nz, LookupAndMergeVoice_LoadReg

LookupAndMergeVoice_LoadReg2:
	ld l, e
	ld (xwa + 1), l
	ret

LookupAndMergeVoice_Deref:
	ld (xwa + 1), 0x0
	ld l, 0x0:opc
	ret

Voice_LookupTableEntries:
	lda xhl, (0xc5ca:16)
	lda xix, (0xe7e8:16)
	ld c, 0x20:opc
	cp (xwa + 3), 0x2
	jrl nc, LookupTableEntries_Deref
	ld c, (xwa + 3)
	extz bc
	lda xde, (NoteMap_LinkByte_Table:24)
	ld	c, (xde+bc)
	ldfr_berp C, 0xea
	ld de, 0:i3
	ldto_berp C, 0xea
	extz bc
	add bc, bc
	ld	c, (xix+bc)
	ldfr_berp C, 0xeb
	cpb_erp C, 0xea
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
	ld	c, (xix+bc)
	ldfr_berp C, 0xeb
	inc 1, de
	ldto_berp C, 0xeb
	cpb_erp C, 0xea
	jr nz, LookupTableEntries_LoadReg

LookupTableEntries_LoadReg2:
	ld l, e
	ld (xwa + 1), l
	ret

LookupTableEntries_Deref:
	ld (xwa + 1), 0x0
	ld l, 0x0:opc
	ret

LookupTableEntries_Prologue:
	push xiz
	ld l, c
	extz hl
	muls hl, 0xd
	lda xix, (NoteMap_ChannelMapRecords:24)
	ld	xix, (xix+hl)
	ld l, c
	extz hl
	muls hl, 0xd
	lda xiy, (LookupTableEntries_Prologue_Data_2:24)
	ld	xiy, (xiy+hl)
	extz bc
	muls bc, 0xd
	lda xhl, (LookupTableEntries_Prologue_Data_3:24)
	extz de
	ld	xbc, (xhl+bc)
	ld	e, (xbc+de)
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
	lda	xiz, (xix+bc)
	ld c, (xsp + 8)
	extz bc
	muls bc, 0x5
	inc 4, bc
	ld	c, (xwa+bc)
	cp c, (xiz + 2)
	jr nz, LookupTableEntries_LoadReg4
	ld c, l
	extz bc
	sla bc, 3
	lda	xiz, (xix+bc)
	ld c, (xwa + 3)
	cp c, (xiz + 1)
	jr nz, LookupTableEntries_LoadReg4
	ld c, l
	extz bc
	ld iz, bc
	sla iz, 3
	ld c, (xwa + 2)
	cp	c, (xix+iz)
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
	cp l, 4:i3
	jr ugt, ClaimVoiceSlot_Deref
	cp (xsp + 12), 0x20
	jr ule, ClaimVoiceSlot_LoadReg

ClaimVoiceSlot_Deref:
	ld (xwa + 1), 0x0
	ld l, 0x0:opc
	jrl NoteMap_LookupReturn

ClaimVoiceSlot_LoadReg:
	ld c, l
	extz bc
	muls bc, 0xd
	ld ix, bc
	lda xiy, (LookupTableEntries_Prologue_Data_3:24)
	ld c, (xsp + 12)
	ldfr_berp C, 0xf8
	extz iz
	ld	xbc, (xiy+ix)
	ld	b, (xbc+iz)
	ldfr_berp L, 0xf0
	extz ix
	muls ix, 0xd
	lda xiy, (NoteMap_ChannelMapRecords:24)
	ld	xix, (xiy+ix)
	extz hl
	muls hl, 0xd
	lda xiy, (LookupTableEntries_Prologue_Data_2:24)
	ld	xhl, (xiy+hl)
	ld (xsp + 4), xhl
	cp (xde + 3), 0xff
	jrl nz, ClaimVoiceSlot_InitVal
	ld hl, 0:i3
	ld c, b
	ldfr_berp C, 0xf4
	extz iy
	ld iz, iy
	add iz, iz
	ld xiy, (xsp + 4)
	ld	c, (xiy+iz)
	ldfr_berp C, 0xe6
	cp c, b
	jrl z, NoteMap_StoreEntryAndReturn

ClaimVoiceSlot_LoadIdx:
	ldto_berp C, 0xe6
	ldfr_berp C, 0xf4
	extz iy
	sla iy, 3
	ld c, (xde + 2)
	cp	c, (xix+iy)
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
	ld	c, (xiy+iz)
	ldfr_berp C, 0xe6
	cp c, b
	jrl nz, ClaimVoiceSlot_LoadIdx
	jrl NoteMap_StoreEntryAndReturn

ClaimVoiceSlot_InitVal:
	ld hl, 0:i3
	ld c, b
	ldfr_berp C, 0xf4
	extz iy
	ld iz, iy
	add iz, iz
	ld xiy, (xsp + 4)
	ld	c, (xiy+iz)
	ldfr_berp C, 0xe6
	cp c, b
	jrl z, NoteMap_StoreEntryAndReturn

ClaimVoiceSlot_LoadIdx3:
	ldto_berp C, 0xe6
	ldfr_berp C, 0xf4
	extz iy
	sla iy, 3
	ld c, (xde + 2)
	cp	c, (xix+iy)
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
	ld	c, (xiy+iz)
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
	cp e, 4:i3
	jr ugt, LookupVoice_RejectOutOfRange
	cp (xsp + 12), 0x20
	jr ule, LookupVoice_StartLookup

LookupVoice_RejectOutOfRange:
	ld (xwa + 1), 0x0
	ld l, 0x0:opc
	jrl NoteMap_LookupVoice_Return

LookupVoice_StartLookup:
	ld c, e
	extz bc
	muls bc, 0xd
	ld hl, bc
	lda xiy, (LookupTableEntries_Prologue_Data_3:24)
	ld c, (xsp + 12)
	ldfr_berp C, 0xf8
	extz iz
	ld	xbc, (xiy+hl)
	ld	d, (xbc+iz)
	ld c, e
	extz bc
	muls bc, 0xd
	lda xhl, (NoteMap_ChannelMapRecords:24)
	ld	xiy, (xhl+bc)
	ld c, e
	extz bc
	muls bc, 0xd
	lda xhl, (LookupTableEntries_Prologue_Data_2:24)
	ld	xbc, (xhl+bc)
	ld (xsp + 4), xbc
	cp (xix + 3), 0xff
	jrl nz, LookupVoice_WithInstrument
	ld hl, 0:i3
	ld c, d
	extz bc
	ld iz, bc
	add iz, iz
	ld xbc, (xsp + 4)
	ld	e, (xbc+iz)
	cp e, d
	jrl z, NoteMap_StoreResultAndReturn

LookupVoice_ScanEntries:
	ld c, e
	extz bc
	ld iz, bc
	sla iz, 3
	ld c, (xix + 2)
	cp	c, (xiy+iz)
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
	ld	e, (xbc+iz)
	cp e, d
	jrl nz, LookupVoice_ScanEntries
	jrl NoteMap_StoreResultAndReturn

LookupVoice_WithInstrument:
	ld hl, 0:i3
	ld c, d
	extz bc
	ld iz, bc
	add iz, iz
	ld xbc, (xsp + 4)
	ld	e, (xbc+iz)
	cp e, d
	jrl z, NoteMap_StoreResultAndReturn

LookupVoice_InstrScanEntries:
	ld c, e
	extz bc
	ld iz, bc
	sla iz, 3
	ld c, (xix + 2)
	cp	c, (xiy+iz)
	jrl nz, LookupVoice_InstrSca_LoadReg
	ld c, e
	extz bc
	sla bc, 3
	lda	xiz, (xiy+bc)
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
	ld	e, (xbc+iz)
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
	lda xsp, (xsp-178)
	pushw iz
	ld l, e
	ld	(xsp+172), xbc
	ld	(xsp+176), xwa
	cp l, 4:i3
	jr ugt, CollectMatchingEntri_LoadFromStack
	cp	(xsp+184), 0x20
	jr ule, CollectMatchingEntri_LoadReg

CollectMatchingEntri_LoadFromStack:
	ld	xwa, (xsp+176)
	ld (xwa + 1), 0x0
	ld l, 0x0:opc
	jrl EmitNoteData_Process_RestoreReg

CollectMatchingEntri_LoadReg:
	ld a, l
	extz wa
	muls wa, 0xd
	ld bc, wa
	lda xde, (LookupTableEntries_Prologue_Data_3:24)
	ld	a, (xsp+184)
	ldfr_berp A, 0xf0
	extz ix
	ld	xwa, (xde+bc)
	ld	a, (xwa+ix)
	ld (xsp + 2), a
	ld a, l
	extz wa
	muls wa, 0xd
	lda xbc, (NoteMap_ChannelMapRecords:24)
	ld	xde, (xbc+wa)
	ld a, l
	extz wa
	muls wa, 0xd
	lda xbc, (LookupTableEntries_Prologue_Data_2:24)
	ld	xwa, (xbc+wa)
	ld (xsp + 4), xwa
	ld hl, 0:i3
	ld iz, 0:i3
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
	lda	xwa, (xwa+bc)
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
	add	xiy, (xsp+172)
	ld bc, 2:i3
	ldirw
	ldi85
	inc 1, hl
	jr EmitNoteData_Process_NextIter

EmitNoteData_Process_LoadReg:
	ld a, c
	extz wa
	sla wa, 3
	lda	xiy, (xde+wa)
	ld wa, iz
	extz xwa
	ld xix, xwa
	sll xix, 2
	add xix, xwa
	inc 4, xix
	add	xix, (xsp+172)
	ld a, (xix)
	cp a, (xiy + 2)
	jr nz, NoteMap_EmitNoteData_Process
	ld a, c
	extz wa
	sla wa, 3
	lda	xix, (xde+wa)
	ld	xwa, (xsp+172)
	ld a, (xwa + 3)
	cp a, (xix + 1)
	jrl nz, NoteMap_EmitNoteData_Process
	ld a, c
	extz wa
	ld ix, wa
	sla ix, 3
	ld	xwa, (xsp+172)
	ld a, (xwa + 2)
	cp	a, (xde+ix)
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
	ld	xwa, (xsp+172)
	ld a, (xwa + 1)
	extz wa
	cp iz, wa
	jrl c, CollectMatchingEntri_LoadParam
	ld (xsp + 9), l
	ld c, (xsp + 2)
	ld hl, 0:i3
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
	add	xix, (xsp+176)
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
	add	xix, (xsp+176)
	ld (xix + 1), 0x0
	ld wa, hl
	extz xwa
	ld xix, xwa
	sll xix, 2
	add xix, xwa
	inc 4, xix
	add	xix, (xsp+176)
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
	add	xix, (xsp+176)
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
	add	xix, (xsp+176)
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
	lda	xwa, (xwa+bc)
	ld a, (xwa + 1)
	ld c, a
	cp a, (xsp + 2)
	jrl nz, EmitNoteData_Process_LoadReg2

EmitNoteData_Process_InitVal:
	ld iz, 0:i3
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
	add	xix, (xsp+176)
	ld bc, 2:i3
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
	ld	xwa, (xsp+176)
	ld (xwa + 1), c
	ld	xwa, (xsp+172)
	ld c, (xwa)
	ld	xwa, (xsp+176)
	ld (xwa), c
	ld	xwa, (xsp+172)
	ld c, (xwa + 2)
	ld	xwa, (xsp+176)
	ld (xwa + 2), c
	ld	xwa, (xsp+172)
	ld c, (xwa + 3)
	ld	xwa, (xsp+176)
	ld (xwa + 3), c

EmitNoteData_Process_RestoreReg:
	popw iz
	lda xsp, (xsp+178:16)
	retd 0x2

NoteMap_AllocNewVoiceEntry:
	lda xsp, (xsp - 14)
	pushw_erp 0xfa
	ld (xsp + 10), c
	ld (xsp + 12), xwa
	lda xwa, (0xe82e:16)
	ld (xsp + 6), xwa
	cp (xsp + 10), 0x20
	jrl ugt, SlotLoop_Continue_RestoreReg
	ld a, (xsp + 10)
	extz wa
	lda xbc, (CharMap_ValueData_A:24)
	ld	a, (xbc+wa)
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
	ld a, (0xe92f:16)
	ldfr_berp A, 0xfb
	cp a, 0x80
	jrl z, AllocNewVoiceEntry_LoadParam2
	ld a, (xsp + 10)
	extz wa
	ld hl, wa
	add hl, hl
	lda xix, (0xc62a:16)
	ld a, (xsp + 10)
	extz wa
	ld bc, wa
	add bc, bc
	lda xde, (0xc62b:16)
	ld	a, (xix+hl)
	cp	a, (xde+bc)
	jrl ule, AllocNewVoiceEntry_LoadParam2
	ld a, (xsp + 10)
	extz wa
	add wa, wa
	lda xbc, (0xc62b:16)
	inc	1, (xbc+wa)
	ldto_berp A, 0xfb
	extz wa
	ld de, wa
	sla de, 3
	lda xhl, (0xc671:16)
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	ld a, (xbc + 4)
	ld	(xhl+de), a
	ldto_berp A, 0xfb
	extz wa
	ld bc, wa
	sla bc, 3
	lda xde, (0xc66a:16)
	ld xwa, (xsp + 12)
	ld a, (xwa + 2)
	ld	(xde+bc), a
	ldto_berp A, 0xfb
	extz wa
	ld bc, wa
	sla bc, 3
	lda xde, (0xc66b:16)
	ld xwa, (xsp + 12)
	ld a, (xwa + 3)
	ld	(xde+bc), a
	ldto_berp A, 0xfb
	extz wa
	ld de, wa
	sla de, 3
	lda xhl, (0xc66c:16)
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	ld a, (xbc)
	ld	(xhl+de), a
	ldto_berp A, 0xfb
	extz wa
	ld de, wa
	sla de, 3
	lda xhl, (0xc66f:16)
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	ld a, (xbc + 2)
	res 7, a
	ld	(xhl+de), a
	ldto_berp A, 0xfb
	extz wa
	ld de, wa
	sla de, 3
	lda xhl, (0xc670:16)
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	ld a, (xbc + 3)
	ld	(xhl+de), a
	ldto_berp A, 0xfb
	extz wa
	ld de, wa
	sla de, 3
	lda xhl, (0xc66d:16)
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	ld a, (xbc + 1)
	ld	(xhl+de), a
	ldto_berp A, 0xfb
	extz wa
	ld bc, wa
	sla bc, 3
	lda xde, (0xc66e:16)
	ld a, (xsp + 10)
	ld	(xde+bc), a
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
	ld bc, 0:i3
	calr LookupTableEntries_Prologue
	ldfr_berp L, 0xfb
	ldto_berp A, 0xfb
	cp a, (xsp + 4)
	jrl z, AllocNewVoiceEntry_LoadParam4
	ld a, (xsp + 10)
	extz wa
	add wa, wa
	lda xbc, (0xc62b:16)
	dec	1, (xbc+wa)
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
	lda xbc, (0xc66f:16)
	ld	a, (xbc+wa)
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
	lda xbc, (0xc670:16)
	ld	a, (xbc+wa)
	ld (xde + 3), a
	lda xde, (0xe82e:16)
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	calr NoteMap_SwapVoiceLinks
	lda xde, (0xe82e:16)
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	ldw de, 0x80
	calr NoteMap_LinkVoiceSlots
	lda xde, (0xe82e:16)
	ld a, (xsp + 4)
	ld c, a
	extz bc
	ld xwa, xde
	calr LinkVoiceSlots_LoadReg
	cp hl, 0:i3
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
	incw 1, (xsp + 2)

SlotLoop_Continue_LoadParam:
	ld xwa, (xsp + 12)
	ld a, (xwa + 1)
	extz wa
	cp (xsp + 2), wa
	jrl c, AllocNewVoiceEntry_LoadParam

SlotLoop_Continue_RestoreReg:
	popw_erp 0xfa
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
	lda xbc, (CharMap_ValueData_A:24)
	ld	a, (xbc+wa)
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
	cp a, 2:i3
	jr z, SetChannelParam_LoadDRAM2
	cp a, 1:i3
	jr z, SetChannelParam_LoadDRAM
	cp a, 0:i3
	jr nz, SetChannelParam_LoadParam2
	ld wa, (0xcf01:16)
	extz xwa
	ld xbc, SetChannelParam_ByteMap
	add xbc, xwa
	ld a, (xbc)
	ld (xsp + 2), a
	jrl Voice_EmitMidiNoteAndBankEvents

SetChannelParam_LoadDRAM:
	ld wa, (0xcf31:16)
	extz xwa
	ld xbc, SetChannelParam_ByteMap
	add xbc, xwa
	ld a, (xbc)
	ld (xsp + 2), a
	jr Voice_EmitMidiNoteAndBankEvents

SetChannelParam_LoadDRAM2:
	ld wa, (0xce24:16)
	extz xwa
	ld xbc, SetChannelParam_ByteMap
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
	lda xbc, (SetChannelParam_ByteMap:24)
	ld	a, (xbc+wa)
	set 3, a
	ld (xsp + 2), a
	jr Voice_EmitMidiNoteAndBankEvents

SetChannelParam_LoadParam4:
	ld xwa, (xsp + 26)
	ld a, (xwa + 2)
	extz wa
	lda xbc, (SetChannelParam_ByteMap:24)
	ld	a, (xbc+wa)
	ld (xsp + 2), a
	jr Voice_EmitMidiNoteAndBankEvents

SetChannelParam_LoadParam5:
	ld xwa, (xsp + 26)
	ld a, (xwa + 2)
	extz wa
	lda xbc, (SetChannelParam_ByteMap:24)
	ld	a, (xbc+wa)
	ld (xsp + 2), a

Voice_EmitMidiNoteAndBankEvents:
	ld iz, 0:i3
	jrl MIDI_SendVoiceData_CheckCount

MIDI_SendVoiceData_Loop:
	ld wa, iz
	muls wa, 0x5
	ld bc, wa
	inc 4, bc
	ld xwa, (xsp + 26)
	lda	xwa, (xwa+bc)
	bitm 1, (xwa + 4)
	jrl nz, MIDI_SendVoiceData_Increment
	ld wa, iz
	muls wa, 0x5
	ld bc, wa
	inc 4, bc
	ld xwa, (xsp + 26)
	lda	xwa, (xwa+bc)
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
	lda	xwa, (xwa+bc)
	ld a, (xwa + 2)
	res 7, a
	ld (xsp + 7), a
	ld wa, iz
	muls wa, 0x5
	ld bc, wa
	inc 4, bc
	ld xwa, (xsp + 26)
	lda	xwa, (xwa+bc)
	ld a, (xwa + 1)
	ld (xsp + 8), a
	lda xwa, (xsp + 4)
	call MIDI_SendCmdPacket
	ld wa, iz
	muls wa, 0x5
	ld bc, wa
	inc 4, bc
	ld xwa, (xsp + 26)
	lda	xwa, (xwa+bc)
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
	cp iz, 0:i3
	call gt, (MIDI_PostSendStub:24)

MIDI_SendVoiceData_Return:
	popw iz
	lda xsp, (xsp + 28)
	ret

Voice_ScanAndEmitMidiEvents:
	dec 6, xsp
	push xiz
	ld (xsp + 4), c
	ld (xsp + 6), xwa
	ld iz, 0:i3
	ldiw_erp 0xfa, 0
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
	cp hl, 0:i3
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
	cp iz, 0:i3
	jr z, ScanEmitMidi_NextVoice
	cp iz, 0xf
	jr ugt, SysExParse_CheckLeng_LoadReg
	ld xwa, (xsp + 6)
	ld a, (xwa + 1)
	dec 1, a
	extz wa
	cpw_erp WA, 0xfa
	jr nz, ScanEmitMidi_NextVoice

SysExParse_CheckLeng_LoadReg:
	ld xwa, 0xccc2
	push xwa
	pushw iz
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	ld iz, 0:i3

ScanEmitMidi_NextVoice:
	inc1w_erp 0xfa

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
	set 0, (1113:16)
	ldmi16 (xsp + 2), 0x41b
	ei 0
	ld bc, 0:i3
	ld iz, 0:i3
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
	lda xde, (0xccd4:16)
	ld hl, wa
	extz xhl
	add xhl, xde
	ld xwa, (xsp + 6)
	ld a, (xwa + 2)
	extz wa
	lda xde, (NoteOn_ChannelByVoice:24)
	ld	a, (xde+wa)
	or a, 0x90
	ld (xhl), a
	ld wa, bc
	mul wa, 0x5
	lda xde, (0xccd5:16)
	ld hl, wa
	extz xhl
	add xhl, xde
	ld a, (xsp + 2)
	ld (xhl), a
	ld wa, bc
	mul wa, 0x5
	lda xde, (0xccd6:16)
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
	lda xde, (0xccd7:16)
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
	lda xde, (0xccd8:16)
	ld hl, wa
	extz xhl
	add xhl, xde
	ld a, (xsp + 4)
	ld (xhl), a
	inc 1, bc

BuildNoteOn_NextVoice:
	cp bc, 0:i3
	jr z, BuildNoteOn_NextVoic_NextIter
	cp bc, 6:i3
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
	ld bc, 0:i3

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
	set 0, (1113:16)
	ldmi16 (xsp + 2), 0x415
	ei 0
	ld bc, 0:i3
	ld iz, 0:i3
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
	lda xde, (0xccf2:16)
	extz xwa
	add xwa, xde
	ld (xwa), 0x90
	ld wa, bc
	mul wa, 0x5
	lda xde, (0xccf3:16)
	ld hl, wa
	extz xhl
	add xhl, xde
	ld a, (xsp + 2)
	ld (xhl), a
	ld wa, bc
	mul wa, 0x5
	lda xde, (0xccf4:16)
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
	lda xde, (0xccf5:16)
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
	lda xde, (0xccf6:16)
	ld hl, wa
	extz xhl
	add xhl, xde
	ld a, (xsp + 4)
	ld (xhl), a
	inc 1, bc

EmitNoteOnMessages_Compare:
	cp bc, 0:i3
	jr z, EmitNoteOnMessages_NextIter
	cp bc, 6:i3
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
	ld bc, 0:i3

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
	set 0, (1113:16)
	ldmi16 (xsp + 2), 0x46a
	ei 0
	ld bc, 0:i3
	ld iz, 0:i3
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
	lda xde, (0xcd10:16)
	extz xwa
	add xwa, xde
	ld (xwa), 0x90
	ld wa, bc
	mul wa, 0x5
	lda xde, (0xcd11:16)
	ld hl, wa
	extz xhl
	add xhl, xde
	ld a, (xsp + 2)
	ld (xhl), a
	ld wa, bc
	mul wa, 0x5
	lda xde, (0xcd12:16)
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
	lda xde, (0xcd13:16)
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
	lda xde, (0xcd14:16)
	ld hl, wa
	extz xhl
	add xhl, xde
	ld a, (xsp + 4)
	ld (xhl), a
	inc 1, bc

EmitMidiNoteOnEvents_Compare:
	cp bc, 0:i3
	jr z, EmitMidiNoteOnEvents_NextIter
	cp bc, 6:i3
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
	ld bc, 0:i3

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
	pushw_erp 0xfa
	ld (xsp + 10), c
	ld (xsp + 12), xwa
	ld a, (xsp + 10)
	extz wa
	lda xbc, (CharMap_ValueData_B:24)
	ld	a, (xbc+wa)
	ld (xsp + 4), a
	lda xwa, (0xe970:16)
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
	ld a, (0xe9b1:16)
	ldfr_berp A, 0xfb
	cp a, 0x20
	jrl z, FindEntry_LoadParam2
	ld a, (xsp + 10)
	extz wa
	ld hl, wa
	add hl, hl
	lda xix, (0xca6a:16)
	ld a, (xsp + 10)
	extz wa
	ld bc, wa
	add bc, bc
	lda xde, (0xca6b:16)
	ld	a, (xix+hl)
	cp	a, (xde+bc)
	jrl ule, FindEntry_LoadParam2
	ld a, (xsp + 10)
	extz wa
	add wa, wa
	lda xbc, (0xca6b:16)
	inc	1, (xbc+wa)
	ldto_berp A, 0xfb
	extz wa
	ld de, wa
	sla de, 3
	lda xhl, (0xca81:16)
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	ld a, (xbc + 4)
	ld	(xhl+de), a
	ldto_berp A, 0xfb
	extz wa
	ld bc, wa
	sla bc, 3
	lda xde, (0xca7a:16)
	ld xwa, (xsp + 12)
	ld a, (xwa + 2)
	ld	(xde+bc), a
	ldto_berp A, 0xfb
	extz wa
	ld bc, wa
	sla bc, 3
	lda xde, (0xca7b:16)
	ld xwa, (xsp + 12)
	ld a, (xwa + 3)
	ld	(xde+bc), a
	ldto_berp A, 0xfb
	extz wa
	ld de, wa
	sla de, 3
	lda xhl, (0xca7c:16)
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	ld a, (xbc)
	ld	(xhl+de), a
	ldto_berp A, 0xfb
	extz wa
	ld de, wa
	sla de, 3
	lda xhl, (0xca7f:16)
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	ld a, (xbc + 2)
	res 7, a
	ld	(xhl+de), a
	ldto_berp A, 0xfb
	extz wa
	ld de, wa
	sla de, 3
	lda xhl, (0xca80:16)
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	ld a, (xbc + 3)
	ld	(xhl+de), a
	ldto_berp A, 0xfb
	extz wa
	ld de, wa
	sla de, 3
	lda xhl, (0xca7d:16)
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	ld a, (xbc + 1)
	ld	(xhl+de), a
	ldto_berp A, 0xfb
	extz wa
	ld bc, wa
	sla bc, 3
	lda xde, (0xca7e:16)
	ld a, (xsp + 10)
	ld	(xde+bc), a
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
	ld bc, 4:i3
	calr LookupTableEntries_Prologue
	ldfr_berp L, 0xfb
	ldto_berp A, 0xfb
	cp a, (xsp + 4)
	jrl z, FindEntry_LoadParam4
	ld a, (xsp + 10)
	extz wa
	add wa, wa
	lda xbc, (0xca6b:16)
	dec	1, (xbc+wa)
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
	lda xbc, (0xca7f:16)
	ld	a, (xbc+wa)
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
	lda xbc, (0xca80:16)
	ld	a, (xbc+wa)
	ld (xde + 3), a
	lda xde, (0xe970:16)
	ldto_berp A, 0xfb
	ld c, a
	extz bc
	ld xwa, xde
	calr NoteMap_SwapVoiceLinks
	lda xde, (0xe970:16)
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
	incw 1, (xsp + 2)

LoopAdvance_Next_LoadParam:
	ld xwa, (xsp + 12)
	ld a, (xwa + 1)
	extz wa
	cp (xsp + 2), wa
	jrl c, FindEntry_LoadParam
	popw_erp 0xfa
	lda xsp, (xsp + 14)
	ret

NoteMap_FindBestVoiceSlot:
	ld hl, 0:i3
	ld d, 0x21:opc
	ld e, 0xff:opc
	ld d, 0x21:opc
	jr NoteMap_FindEntry_AdvanceSlotD

FindBestVoiceSlot_LoadReg:
	ld c, d
	extz bc
	sla bc, 3
	lda xix, (0xca7a:16)
	ld	c, (xix+bc)
	cp c, 0:i3
	jr z, FindBestVoiceSlot_Compare3
	cp c, 1:i3
	jr z, FindBestVoiceSlot_Compare2
	cp c, 2:i3
	jr z, FindBestVoiceSlot_Compare
	cp c, 3:i3
	jr nz, FindBestVoiceSlot_ClearByte
	ld e, 0x3:opc
	jr NoteMap_FindEntry_AdvanceSlotD

FindBestVoiceSlot_Compare:
	cp e, 3:i3
	jr z, NoteMap_FindEntry_AdvanceSlotD
	ld e, 0x2:opc
	jr NoteMap_FindEntry_AdvanceSlotD

FindBestVoiceSlot_Compare2:
	cp e, 3:i3
	jr z, NoteMap_FindEntry_AdvanceSlotD
	cp e, 2:i3
	jr z, NoteMap_FindEntry_AdvanceSlotD
	ld e, 0x1:opc
	jr NoteMap_FindEntry_AdvanceSlotD

FindBestVoiceSlot_Compare3:
	cp e, 3:i3
	jr z, NoteMap_FindEntry_AdvanceSlotD
	cp e, 2:i3
	jr z, NoteMap_FindEntry_AdvanceSlotD
	cp e, 1:i3
	jr z, NoteMap_FindEntry_AdvanceSlotD
	ld e, 0x0:opc
	jr NoteMap_FindEntry_AdvanceSlotD

FindBestVoiceSlot_ClearByte:
	ld e, 0x0:opc

NoteMap_FindEntry_AdvanceSlotD:
	ld c, d
	extz bc
	add bc, bc
	lda xix, (0xe971:16)
	ld	d, (xix+bc)
	ld c, d
	cp c, 0x21
	jr nz, FindBestVoiceSlot_LoadReg
	cp e, 0xff
	jr z, FindEntry_AdvanceSlo_Deref
	ld d, 0x21:opc
	jr FindEntry_AdvanceSlo_LoadReg2

FindEntry_AdvanceSlo_LoadReg:
	ld a, d
	extz wa
	sla wa, 3
	lda xbc, (0xca7a:16)
	cp	(xbc+wa), e
	jr nz, FindEntry_AdvanceSlo_LoadReg2
	ld wa, hl
	add wa, wa
	inc 4, wa
	lda xbc, (0xcf00:16)
	ld ix, wa
	extz xix
	add xix, xbc
	ld a, d
	extz wa
	sla wa, 3
	lda xbc, (0xca7f:16)
	ld	a, (xbc+wa)
	res 7, a
	ld (xix), a
	ld wa, hl
	add wa, wa
	lda xbc, (0xcf03:16)
	ld ix, wa
	extz xix
	add xix, xbc
	ld a, d
	extz wa
	sla wa, 3
	lda xbc, (0xca7d:16)
	ld	a, (xbc+wa)
	ld (xix), a
	inc 1, hl

FindEntry_AdvanceSlo_LoadReg2:
	ld a, d
	extz wa
	add wa, wa
	lda xbc, (0xe971:16)
	ld	d, (xbc+wa)
	ld a, d
	cp a, 0x21
	jr nz, FindEntry_AdvanceSlo_LoadReg
	jr FindEntry_AdvanceSlo_StoreDRAM

FindEntry_AdvanceSlo_Deref:
	ld e, (xwa + 2)

FindEntry_AdvanceSlo_StoreDRAM:
	ld (0xceff:16), hl
	ld a, e
	extz wa
	ld (0xcf01:16), wa
	lda xwa, (0xceff:16)
	push xwa
	call VoiceSlot_CheckAndApply_Prologue
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
	lda xbc, (NoteThreshold_PairTable:24)
	ld	a, (xbc+wa)
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
	lda xbc, (MarkEntriesAboveThre_LoadParam_Data_2:24)
	ld	a, (xbc+wa)
	ldfr_berp A, 0xf9
	jr MarkEntriesAboveThre_LoadIdx

MarkEntriesAboveThre_InitIdx:
	ldib_erp 0xfa, 0
	ldib_erp 0xf9, 0

MarkEntriesAboveThre_LoadIdx:
	ldto_berp A, 0xfa
	xor a, (0xcd2e:16)
	ld e, a
	ldto_berp A, 0xf9
	xor a, (0xcd2f:16)
	ldfr_berp A, 0xfb
	cp e, 0:i3
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
	cpib_erp 0xfb, 0
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
	ld (0xcd2e:16), a
	ldto_berp A, 0xf9
	ld (0xcd2f:16), a

MarkEntriesAboveThre_AdvanceSlot:
	incw 1, (xsp + 4)

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
	ld de, 0:i3
	ld h, 0x23:opc
	ld l, 0xff:opc
	jr NoteMap_FindBestFreeVoice_AdvanceSlotH

FindBestFreeVoice_LoadReg:
	ld c, h
	extz bc
	sla bc, 3
	lda xix, (0xca7a:16)
	ld	c, (xix+bc)
	cp c, 0:i3
	jr z, FindBestFreeVoice_Compare3
	cp c, 1:i3
	jr z, FindBestFreeVoice_Compare2
	cp c, 2:i3
	jr z, FindBestFreeVoice_Compare
	cp c, 3:i3
	jr nz, NoteMap_FindBestFreeVoice_AdvanceSlotH
	ld l, 0x2:opc
	jr NoteMap_FindBestFreeVoice_AdvanceSlotH

FindBestFreeVoice_Compare:
	cp l, 3:i3
	jr z, NoteMap_FindBestFreeVoice_AdvanceSlotH
	ld l, 0x2:opc
	jr NoteMap_FindBestFreeVoice_AdvanceSlotH

FindBestFreeVoice_Compare2:
	cp l, 3:i3
	jr z, NoteMap_FindBestFreeVoice_AdvanceSlotH
	cp l, 2:i3
	jr z, NoteMap_FindBestFreeVoice_AdvanceSlotH
	ld l, 0x1:opc
	jr NoteMap_FindBestFreeVoice_AdvanceSlotH

FindBestFreeVoice_Compare3:
	cp l, 3:i3
	jr z, NoteMap_FindBestFreeVoice_AdvanceSlotH
	cp l, 2:i3
	jr z, NoteMap_FindBestFreeVoice_AdvanceSlotH
	cp l, 1:i3
	jr z, NoteMap_FindBestFreeVoice_AdvanceSlotH
	ld l, 0x0:opc

NoteMap_FindBestFreeVoice_AdvanceSlotH:
	ld c, h
	extz bc
	add bc, bc
	lda xix, (0xe971:16)
	ld	h, (xix+bc)
	ld c, h
	cp c, 0x23
	jr nz, FindBestFreeVoice_LoadReg
	cp l, 0xff
	jr z, FindBestFreeVoice_Ad_Deref
	ld h, 0x23:opc
	jr FindBestFreeVoice_Ad_LoadReg2

FindBestFreeVoice_Ad_LoadReg:
	ld a, h
	extz wa
	sla wa, 3
	lda xbc, (0xca7a:16)
	cp	(xbc+wa), l
	jr nz, FindBestFreeVoice_Ad_LoadReg2
	ld wa, de
	add wa, wa
	inc 4, wa
	lda xbc, (0xce23:16)
	ld ix, wa
	extz xix
	add xix, xbc
	ld a, h
	extz wa
	sla wa, 3
	lda xbc, (0xca7f:16)
	ld	a, (xbc+wa)
	res 7, a
	ld (xix), a
	ld wa, de
	add wa, wa
	lda xbc, (0xce26:16)
	ld ix, wa
	extz xix
	add xix, xbc
	ld a, h
	extz wa
	sla wa, 3
	lda xbc, (0xca7d:16)
	ld	a, (xbc+wa)
	ld (xix), a
	inc 1, de

FindBestFreeVoice_Ad_LoadReg2:
	ld a, h
	extz wa
	add wa, wa
	lda xbc, (0xe971:16)
	ld	h, (xbc+wa)
	ld a, h
	cp a, 0x23
	jr nz, FindBestFreeVoice_Ad_LoadReg
	jr FindBestFreeVoice_Ad_StoreDRAM

FindBestFreeVoice_Ad_Deref:
	ld l, (xwa + 2)

FindBestFreeVoice_Ad_StoreDRAM:
	ld (0xce22:16), de
	ld a, l
	extz wa
	ld (0xce24:16), wa
	ret

NoteMap_EmitNoteOnEvents:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), c
	ld (xsp + 4), xwa
	cp (xsp + 2), 0xff
	jrl z, SynthVoice_Return
	ld bc, 0:i3
	ld iz, 0:i3
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
	lda xde, (0xcd30:16)
	ld hl, wa
	extz xhl
	add xhl, xde
	ld a, (xsp + 2)
	or a, 0x90
	ld (xhl), a
	ld wa, bc
	mul wa, 0x3
	lda xde, (0xcd31:16)
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
	lda xde, (0xcd32:16)
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
	cp bc, 0:i3
	jr z, SynthVoice_NextVoice
	cp bc, 6:i3
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
	ld bc, 0:i3

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
	ld wa, 0:i3
	ld hl, 0:i3
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
	ld bc, 2:i3
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
	pushw_erp 0xfa
	ld (xsp + 16), e
	ld (xsp + 18), xwa
	cp (0x8d36:16), 152
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
	incw 1, (xsp + 2)

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
	ld	a, (xbc+wa)
	sll a, 4
	sra a, 5
	muls a, 0xc
	ld (xsp + 6), a
	add (xsp + 6), e
	ld a, (xsp + 16)
	extz wa
	add wa, wa
	add wa, 0xe4
	lda	xbc, (xbc+wa)
	ld a, 0xf4:opc
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
	ld	a, (xbc+wa)
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
	ld bc, 0:i3
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
	cp hl, 3:i3
	jr z, ResetTimers_Return_LoadParam4
	cp hl, 1:i3
	jr z, ResetTimers_Return_LoadParam3
	cp hl, 0:i3
	jr nz, Synth_WriteChannelMod_Loop
	ld (xsp + 10), 0x1
	ld a, 0x2:opc
	jr Synth_WriteChannelMod_Loop

ResetTimers_Return_LoadParam3:
	ld (xsp + 10), 0xff
	ld a, 0xff:opc
	jr Synth_WriteChannelMod_Loop

ResetTimers_Return_LoadParam4:
	ld (xsp + 10), 0x3
	ld a, 0x4:opc

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
	cp l, 0:i3
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
	cp a, 0:i3
	jr ge, SndParam_ApplyChannelEntry

WriteChannelMod_Loop_AdjustIdx2:
	add_erpb 0xfb, 0x0c
	ldto_berp A, 0xfb
	cp a, 0:i3
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
	cp l, 0:i3
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
	cp a, 0:i3
	jr ge, ApplyChannelEntry_CheckIdx

ApplyChannelEntry_AdjustIdx2:
	add_erpb 0xfb, 0x0c
	ldto_berp A, 0xfb
	cp a, 0:i3
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
	incw 1, (xsp + 2)

StoreChannelResult_LoadParam:
	ld xwa, (xsp + 18)
	ld a, (xwa + 1)
	extz wa
	cp (xsp + 2), wa
	jrl c, WriteChannelMod_Loop_LoadParam

StoreChannelResult_RestoreReg:
	popw_erp 0xfa
	lda xsp, (xsp + 20)
	ret

Voice_ApplyTransposeWithEncode:
	lda xsp, (xsp - 18)
	pushw_erp 0xfa
	ld (xsp + 14), e
	ld (xsp + 16), xwa
	ld a, (xsp + 14)
	extz wa
	add wa, wa
	add wa, 0x124
	ld	a, (xbc+wa)
	sll a, 4
	sra a, 5
	muls a, 0xc
	neg a
	ld (xsp + 4), a
	ld a, (xsp + 14)
	extz wa
	ld bc, 0:i3
	call SndParam_LookupViaEncode
	ld (xsp + 10), hl
	ld a, (xsp + 14)
	extz wa
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	ld (xsp + 12), hl
	ld a, 0x2:opc
	ld xwa, 0x2205
	call SndParam_LookupReadOnly
	cp hl, 3:i3
	jr z, ApplyTransposeWithEn_LoadParam2
	cp hl, 1:i3
	jr z, ApplyTransposeWithEn_LoadParam
	cp hl, 0:i3
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
	cp a, 0:i3
	jr ge, WriteChannelDelay_Lo_LoadParam2

WriteChannelDelay_Lo_AdjustIdx2:
	add_erpb 0xfb, 0x0c
	ldto_berp A, 0xfb
	cp a, 0:i3
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
	cp l, 0:i3
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
	incw 1, (xsp + 2)

WriteChannelDelay_Lo_LoadParam4:
	ld xwa, (xsp + 16)
	ld a, (xwa + 1)
	extz wa
	cp (xsp + 2), wa
	jrl c, WriteChannelDelay_Lo_LoadParam
	popw_erp 0xfa
	lda xsp, (xsp + 18)
	ret

SndParam_ComputeVoiceTuning:
	lda xsp, (xsp - 16)
	pushw_erp 0xfa
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
	ld	a, (xbc+wa)
	sll a, 4
	sra a, 5
	muls a, 0xc
	ld (xsp + 4), a
	add (xsp + 4), e
	ld a, (xsp + 12)
	extz wa
	ld bc, 0:i3
	call SndParam_LookupViaEncode
	ld (xsp + 8), hl
	ld a, (xsp + 12)
	extz wa
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	ld (xsp + 10), hl
	ld a, 0x2:opc
	ld xwa, 0x2205
	call SndParam_LookupReadOnly
	cp hl, 3:i3
	jr z, ComputeVoiceTuning_LoadParam2
	cp hl, 1:i3
	jr z, ComputeVoiceTuning_LoadParam
	cp hl, 0:i3
	jr nz, Synth_WriteChannelGain_Loop
	ld (xsp + 6), 0x1
	ld a, 0x2:opc
	jr Synth_WriteChannelGain_Loop

ComputeVoiceTuning_LoadParam:
	ld (xsp + 6), 0xff
	ld a, 0xff:opc
	jr Synth_WriteChannelGain_Loop

ComputeVoiceTuning_LoadParam2:
	ld (xsp + 6), 0x3
	ld a, 0x4:opc

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
	cp l, 0:i3
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
	cp a, 0:i3
	jr ge, TransposeRange_Clamp

TransposeRange_OctaveUp:
	add_erpb 0xfb, 0x0c
	ldto_berp A, 0xfb
	cp a, 0:i3
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
	incw 1, (xsp + 2)

Synth_WriteParam_Check:
	ld xwa, (xsp + 14)
	ld a, (xwa + 1)
	extz wa
	cp (xsp + 2), wa
	jrl c, Synth_WriteParam_Loop
	popw_erp 0xfa
	lda xsp, (xsp + 16)
	ret

NoteMap_ComputePitchOffset:
	lda xsp, (xsp - 16)
	pushw_erp 0xfa
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
	ld	a, (xbc+wa)
	sll a, 4
	sra a, 5
	muls a, 0xc
	ld (xsp + 4), a
	add (xsp + 4), e
	ld a, (xsp + 12)
	extz wa
	ld bc, 0:i3
	call SndParam_LookupViaEncode
	ld (xsp + 8), hl
	ld a, (xsp + 12)
	extz wa
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	ld (xsp + 10), hl
	ld a, 0x2:opc
	ld xwa, 0x2205
	call SndParam_LookupReadOnly
	cp hl, 3:i3
	jr z, PitchOffset_BothDirs
	cp hl, 1:i3
	jr z, PitchOffset_NegativeDir
	cp hl, 0:i3
	jr nz, Synth_InitChannelState_Loop
	ld (xsp + 6), 0x1
	ld a, 0x2:opc
	jr Synth_InitChannelState_Loop

PitchOffset_NegativeDir:
	ld (xsp + 6), 0xff
	ld a, 0xff:opc
	jr Synth_InitChannelState_Loop

PitchOffset_BothDirs:
	ld (xsp + 6), 0x3
	ld a, 0x4:opc

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
	cp l, 0:i3
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
	cp a, 0:i3
	jr ge, Synth_StoreTransposedNote

CheckNegative_AdjustIdx:
	add_erpb 0xfb, 0x0c
	ldto_berp A, 0xfb
	cp a, 0:i3
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
	incw 1, (xsp + 2)

Synth_InitChannelState_Check:
	ld xwa, (xsp + 14)
	ld a, (xwa + 1)
	extz wa
	cp (xsp + 2), wa
	jrl c, Synth_InitChannelState_Body
	popw_erp 0xfa
	lda xsp, (xsp + 16)
	ret

InitChannelState_Che_InitVal:
	ld hl, 0:i3
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
	ld	c, (xbc+de)
	sll c, 4
	sra c, 5
	muls c, 0xc
	ld l, c
	add l, h
	ld ix, 0:i3
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
	cp l, 0:i3
	jr z, SetTransposeAndAlloc_Compare
	add h, l
	ld c, h
	cp c, 0x7f
	jr ule, SetTransposeAndAlloc_Compare
	cp l, 0:i3
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
	cp c, 0:i3
	jr ge, SetTransposeAndAlloc_Compare

SetTransposeAndAlloc_Compute2:
	add h, 0xc
	ld c, h
	cp c, 0:i3
	jr lt, SetTransposeAndAlloc_Compute2

SetTransposeAndAlloc_Compare:
	cp h, 0x78
	jr c, SetTransposeAndAlloc_LoadReg3
	ld h, 0xff:opc

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
	lda xhl, (CharMap_ValueData_A:24)
	ld	(0xcd44:16), (xhl+wa)
	ld a, (0xcd44:16)
	extz wa
	add wa, wa
	lda xhl, (0xe82e:16)
	ld	(0xcd42:16), (xhl+wa)

UpdateChannelTuning_LoadDRAM:
	ld a, (0xcd42:16)
	cp a, (0xcd44:16)
	jr z, SelectTone_Continue_SetByteFF
	ld a, (0xcd42:16)
	extz wa
	sla wa, 3
	lda xhl, (0xc66a:16)
	cp	(xhl+wa), c
	jr nz, SelectTone_Continue_SetByteFF
	cp e, 2:i3
	jr z, UpdateChannelTuning_LoadDRAM3
	cp e, 1:i3
	jr z, UpdateChannelTuning_LoadDRAM2
	cp e, 0:i3
	jr nz, UpdateChannelTuning_SetByteFF
	ld a, (0xcd42:16)
	extz wa
	sla wa, 3
	lda xbc, (0xc66c:16)
	ld	l, (xbc+wa)
	jr Synth_SelectTone_Continue

UpdateChannelTuning_LoadDRAM2:
	ld a, (0xcd42:16)
	extz wa
	sla wa, 3
	lda xbc, (0xc66f:16)
	ld	l, (xbc+wa)
	jr Synth_SelectTone_Continue

UpdateChannelTuning_LoadDRAM3:
	ld a, (0xcd42:16)
	extz wa
	sla wa, 3
	lda xbc, (0xc670:16)
	ld	l, (xbc+wa)
	jr Synth_SelectTone_Continue

UpdateChannelTuning_SetByteFF:
	ld l, 0xff:opc

Synth_SelectTone_Continue:
	ld a, (0xcd42:16)
	extz wa
	add wa, wa
	lda xbc, (0xe82e:16)
	ld	(0xcd42:16), (xbc+wa)
	jr SelectTone_Continue_Return

SelectTone_Continue_SetByteFF:
	ld l, 0xff:opc

SelectTone_Continue_Return:
	ret

SelectTone_Continue_Prologue:
	dec 6, xsp
	cp (0x8d36:16), 246
	jr nz, SelectTone_Continue_LoadReg
	ld wa, 0:i3
	ld bc, 0:i3
	call SndParam_LookupViaEncode
	ld (xsp + 3), l
	ld wa, 0:i3
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	ld (xsp + 4), l
	ld (xsp + 2), 0x0
	lda xwa, (xsp)
	call SndParam_FetchOscTableEntry
	ld a, (xsp + 0:8)
	add a, 0xf0

SelectTone_Continue_LoadReg:
	ld l, a
	inc 6, xsp
	ret

Rhythm_DispatchCCCommand:
	dec 6, xsp
	ld (xsp + 0:8), 0x4
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
	ld l, 0x0:opc
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cp hl, 1:i3
	jr nz, CheckTransposeRange_LoadParam
	cp (xsp), 0x78
	jr nz, CheckTransposeRange_ClearByte
	ld l, 0x1:opc
	jr UI_CheckControlCode_TestResult

CheckTransposeRange_ClearByte:
	ld l, 0x0:opc
	jr UI_CheckControlCode_TestResult

CheckTransposeRange_LoadParam:
	ld a, (xsp + 2)
	and a, 0xf0
	cp a, 0xf0
	jr nz, CheckTransposeRange_ClearByte2
	ld l, 0x1:opc
	jr UI_CheckControlCode_TestResult

CheckTransposeRange_ClearByte2:
	ld l, 0x0:opc

UI_CheckControlCode_TestResult:
	inc 4, xsp
	ret

CheckControlCode_Tes_WriteReg:
	lda xsp, (xsp-498)
	pushw_erp 0xfa
	ld	(xsp+494), e
	ld	(xsp+496), c
	ld	(xsp+498), a
	ld	(xsp+332), 0x00
	ld	(xsp+333), 0x00
	lda xwa, (xsp+330)
	call NoteMap_LookupAndMergeVoice
	cp l, 0:i3
	jrl z, NoteMap_VoiceAssign_Finalize
	lda xiy, (xsp+330)
	lda xix, (xsp+166:16)
	ldw bc, 0x52
	ldirw
	ld de, 0:i3
	jr CheckControlCode_Tes_LoopCheck

CheckControlCode_Tes_LoopBody:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp+167:16)
	add xwa, xbc
	ld (xwa), 0x0
	inc 1, de

CheckControlCode_Tes_LoopCheck:
	ld	a, (xsp+167)
	extz wa
	cp de, wa
	jr c, CheckControlCode_Tes_LoopBody
	ld	a, (xsp+498)
	cp a, 2:i3
	jrl z, VoiceAssign_CheckBothParts
	cp a, 1:i3
	jrl z, CollectEnabledVoices_CheckMem
	cp a, 0:i3
	jrl nz, NoteMap_VoiceAssign_Finalize
	ld	a, (xsp+496)
	xor	a, (xsp+494)
	and	a, (xsp+494)
	ldfr_berp A, 0xfb
	cp a, 0:i3
	jrl z, NoteMap_AddChangedVoices
	bit_erpb 0xfb, 0x00
	jr z, CheckControlCode_Tes_TestBit0
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	lda xwa, (0xc428:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, CheckControlCode_Tes_TestBit0
	lda xwa, (xsp + 2)
	lda xbc, (0xc364:16)
	ld de, 0:i3
	call NoteMap_AddEntry

CheckControlCode_Tes_TestBit0:
	bit_erpb 0xfb, 0x01
	jr z, CheckControlCode_Tes_TestBit02
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	lda xwa, (0xc42c:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, CheckControlCode_Tes_TestBit02
	lda xwa, (xsp + 2)
	lda xbc, (0xc364:16)
	ld de, 1:i3
	call NoteMap_AddEntry

CheckControlCode_Tes_TestBit02:
	bit_erpb 0xfb, 0x02
	jr z, CheckControlCode_Tes_TestBit03
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	lda xwa, (0xc430:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, CheckControlCode_Tes_TestBit03
	lda xwa, (xsp + 2)
	lda xbc, (0xc364:16)
	ld de, 2:i3
	call NoteMap_AddEntry

CheckControlCode_Tes_TestBit03:
	bit_erpb 0xfb, 0x03
	jr z, NoteMap_AddChangedVoices
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	lda xwa, (0xc434:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, NoteMap_AddChangedVoices
	lda xwa, (xsp + 2)
	lda xbc, (0xc364:16)
	ldw de, 0x15
	call NoteMap_AddEntry
	call AudioInit_RefreshToneBank

NoteMap_AddChangedVoices:
	ld	a, (xsp+496)
	xor	a, (xsp+494)
	and	a, (xsp+496)
	ldfr_berp A, 0xfb
	cp a, 0:i3
	jrl z, NoteMap_CollectEnabledVoices
	bit_erpb 0xfb, 0x00
	jr z, AddChangedVoices_TestBit0
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+330)
	ld xbc, xwa
	lda xwa, (0xc2c2:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, AddChangedVoices_TestBit0
	lda xwa, (xsp + 2)
	lda xbc, (0xc1fe:16)
	ld de, 0:i3
	call NoteMap_AddEntry

AddChangedVoices_TestBit0:
	bit_erpb 0xfb, 0x01
	jr z, AddChangedVoices_TestBit02
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+330)
	ld xbc, xwa
	lda xwa, (0xc2c6:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, AddChangedVoices_TestBit02
	lda xwa, (xsp + 2)
	lda xbc, (0xc1fe:16)
	ld de, 1:i3
	call NoteMap_AddEntry

AddChangedVoices_TestBit02:
	bit_erpb 0xfb, 0x02
	jr z, AddChangedVoices_TestBit03
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+330)
	ld xbc, xwa
	lda xwa, (0xc2ca:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, AddChangedVoices_TestBit03
	lda xwa, (xsp + 2)
	lda xbc, (0xc1fe:16)
	ld de, 2:i3
	call NoteMap_AddEntry

AddChangedVoices_TestBit03:
	bit_erpb 0xfb, 0x03
	jr z, NoteMap_CollectEnabledVoices
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+330)
	ld xbc, xwa
	lda xwa, (0xc2ce:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, NoteMap_CollectEnabledVoices
	lda xwa, (xsp + 2)
	lda xbc, (0xc1fe:16)
	ldw de, 0x15
	call NoteMap_AddEntry

NoteMap_CollectEnabledVoices:
	ld	a, (xsp+496)
	and	a, (xsp+494)
	ldfr_berp A, 0xfb
	cp a, 0:i3
	jrl z, NoteMap_VoiceAssign_Finalize
	bit_erpb 0xfb, 0x00
	jr z, CollectEnabledVoices_TestBit0
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+330)
	ld xbc, xwa
	lda xwa, (0xc2c2:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	lda xwa, (xsp + 2)
	lda xbc, (0xc1fe:16)
	ld de, 0:i3
	call NoteMap_CollectAndFindBestVoice

CollectEnabledVoices_TestBit0:
	bit_erpb 0xfb, 0x01
	jr z, CollectEnabledVoices_TestBit02
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+330)
	ld xbc, xwa
	lda xwa, (0xc2c6:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	lda xwa, (xsp + 2)
	lda xbc, (0xc1fe:16)
	ld de, 1:i3
	call NoteMap_CollectAndFindBestVoice

CollectEnabledVoices_TestBit02:
	bit_erpb 0xfb, 0x02
	jr z, CollectEnabledVoices_TestBit03
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+330)
	ld xbc, xwa
	lda xwa, (0xc2ca:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	lda xwa, (xsp + 2)
	lda xbc, (0xc1fe:16)
	ld de, 2:i3
	call NoteMap_CollectAndFindBestVoice

CollectEnabledVoices_TestBit03:
	bit_erpb 0xfb, 0x03
	jrl z, NoteMap_VoiceAssign_Finalize
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+330)
	ld xbc, xwa
	lda xwa, (0xc2ce:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	lda xwa, (xsp + 2)
	lda xbc, (0xc1fe:16)
	ldw de, 0x15
	call NoteMap_CollectAndFindBestVoice
	jrl NoteMap_VoiceAssign_Finalize

CollectEnabledVoices_CheckMem:
	cp	(xsp+496), 0xff
	jr z, CollectEnabledVoices_CheckMem2
	cp	(xsp+494), 0xff
	jr z, CollectEnabledVoices_CheckMem2
	lda xwa, (xsp+166:16)
	ld xhl, xwa
	lda xbc, (0xc364:16)
	ld	a, (xsp+494)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_AddEntry
	lda xwa, (xsp+330)
	ld xhl, xwa
	lda xbc, (0xc1fe:16)
	ld	a, (xsp+496)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_AddEntry
	jrl NoteMap_VoiceAssign_Finalize

CollectEnabledVoices_CheckMem2:
	cp	(xsp+496), 0xff
	jrl nz, CollectEnabledVoices_CheckMem3
	cp	(xsp+494), 0xff
	jrl z, CollectEnabledVoices_CheckMem3
	lda xwa, (xsp+166:16)
	ld xhl, xwa
	lda xbc, (0xc364:16)
	ld	a, (xsp+494)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_AddEntry
	bit 0, (0xc1fe:16)
	jr z, CollectEnabledVoices_TestBit1
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+330)
	ld xbc, xwa
	lda xwa, (0xc2c2:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, CollectEnabledVoices_TestBit1
	lda xwa, (xsp + 2)
	lda xbc, (0xc1fe:16)
	ld de, 0:i3
	call NoteMap_AddEntry

CollectEnabledVoices_TestBit1:
	bit 1, (0xc1fe:16)
	jr z, CollectEnabledVoices_TestBit2
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+330)
	ld xbc, xwa
	lda xwa, (0xc2c6:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, CollectEnabledVoices_TestBit2
	lda xwa, (xsp + 2)
	lda xbc, (0xc1fe:16)
	ld de, 1:i3
	call NoteMap_AddEntry

CollectEnabledVoices_TestBit2:
	bit 2, (0xc1fe:16)
	jrl z, NoteMap_VoiceAssign_Finalize
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+330)
	ld xbc, xwa
	lda xwa, (0xc2ca:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jrl z, NoteMap_VoiceAssign_Finalize
	lda xwa, (xsp + 2)
	lda xbc, (0xc1fe:16)
	ld de, 2:i3
	call NoteMap_AddEntry
	jrl NoteMap_VoiceAssign_Finalize

CollectEnabledVoices_CheckMem3:
	cp	(xsp+496), 0xff
	jrl z, NoteMap_VoiceAssign_Finalize
	cp	(xsp+494), 0xff
	jrl nz, NoteMap_VoiceAssign_Finalize
	bit 0, (0xc364:16)
	jr z, CollectEnabledVoices_TestBit12
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	lda xwa, (0xc428:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, CollectEnabledVoices_TestBit12
	lda xwa, (xsp + 2)
	lda xbc, (0xc364:16)
	ld de, 0:i3
	call NoteMap_AddEntry

CollectEnabledVoices_TestBit12:
	bit 1, (0xc364:16)
	jr z, CollectEnabledVoices_TestBit22
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	lda xwa, (0xc42c:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, CollectEnabledVoices_TestBit22
	lda xwa, (xsp + 2)
	lda xbc, (0xc364:16)
	ld de, 1:i3
	call NoteMap_AddEntry

CollectEnabledVoices_TestBit22:
	bit 2, (0xc364:16)
	jr z, CollectEnabledVoices_WriteReg
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	lda xwa, (0xc430:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, CollectEnabledVoices_WriteReg
	lda xwa, (xsp + 2)
	lda xbc, (0xc364:16)
	ld de, 2:i3
	call NoteMap_AddEntry

CollectEnabledVoices_WriteReg:
	lda xwa, (xsp+330)
	ld xhl, xwa
	lda xbc, (0xc1fe:16)
	ld	a, (xsp+496)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_AddEntry
	jrl NoteMap_VoiceAssign_Finalize

VoiceAssign_CheckBothParts:
	cp	(xsp+496), 0xff
	jrl z, VoiceAssign_CheckSinglePart
	cp	(xsp+494), 0xff
	jrl z, VoiceAssign_CheckSinglePart
	cpw (0xce68:16), 0
	jr nz, VoiceAssign_LookupAndLoop_Part1
	lda xwa, (0xc364:16)
	ld bc, 2:i3
	call NoteMap_AssignVoiceParams

VoiceAssign_LookupAndLoop_Part1:
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	ld de, 4:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, VoiceAssign_MergeAndCollect_Part1

VoiceAssign_FindRetry_Part1:
	lda xwa, (xsp + 2)
	ld bc, 2:i3
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	ld de, 4:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr nz, VoiceAssign_FindRetry_Part1

VoiceAssign_MergeAndCollect_Part1:
	lda xwa, (xsp + 2)
	ld xix, xwa
	lda xwa, (xsp+330)
	ld xhl, xwa
	ld	a, (xsp+496)
	extz wa
	sla wa, 2
	add wa, 0xc4
	lda xbc, (0xc1fe:16)
	lda	xde, (xbc+wa)
	ld xwa, xix
	ld xbc, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jrl z, NoteMap_VoiceAssign_Finalize
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp + 2)
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	ld de, 4:i3
	call NoteMap_CollectMatchingEntries
	cp l, 0:i3
	jrl z, NoteMap_VoiceAssign_Finalize
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xbc, (0xc1fe:16)
	ld	a, (xsp+496)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_ResetEntryTimers
	lda xwa, (xsp + 2)
	ld bc, 2:i3
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	cp l, 0:i3
	jrl nz, NoteMap_VoiceAssign_Finalize
	call NoteMap_FindBestMatch
	cp l, 0xff
	jrl z, NoteMap_VoiceAssign_Finalize
	lda xwa, (0xc1fe:16)
	ld bc, 2:i3
	call NoteMap_InitVoiceSlots
	jrl NoteMap_VoiceAssign_Finalize

VoiceAssign_CheckSinglePart:
	cp	(xsp+496), 0xff
	jr nz, VoiceAssign_CheckOtherPart
	cp	(xsp+494), 0xff
	jr z, VoiceAssign_CheckOtherPart
	cpw (0xce68:16), 0
	jr nz, VoiceAssign_LookupAndLoop_Part2
	lda xwa, (0xc364:16)
	ld bc, 2:i3
	call NoteMap_AssignVoiceParams

VoiceAssign_LookupAndLoop_Part2:
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	ld de, 4:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jrl z, NoteMap_VoiceAssign_Finalize

VoiceAssign_FindRetry_Part2:
	lda xwa, (xsp + 2)
	ld bc, 2:i3
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	ld de, 4:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr nz, VoiceAssign_FindRetry_Part2
	jrl NoteMap_VoiceAssign_Finalize

VoiceAssign_CheckOtherPart:
	cp	(xsp+496), 0xff
	jrl z, NoteMap_VoiceAssign_Finalize
	cp	(xsp+494), 0xff
	jrl nz, NoteMap_VoiceAssign_Finalize
	lda xwa, (xsp + 2)
	ld xix, xwa
	lda xwa, (xsp+330)
	ld xhl, xwa
	ld	a, (xsp+496)
	extz wa
	sla wa, 2
	add wa, 0xc4
	lda xbc, (0xc1fe:16)
	lda	xde, (xbc+wa)
	ld xwa, xix
	ld xbc, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, NoteMap_VoiceAssign_Finalize
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp + 2)
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	ld de, 4:i3
	call NoteMap_CollectMatchingEntries
	cp l, 0:i3
	jr z, NoteMap_VoiceAssign_Finalize
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xbc, (0xc1fe:16)
	ld	a, (xsp+496)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_ResetEntryTimers
	lda xwa, (xsp + 2)
	ld bc, 2:i3
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	cp l, 0:i3
	jr nz, NoteMap_VoiceAssign_Finalize
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_VoiceAssign_Finalize
	lda xwa, (0xc1fe:16)
	ld bc, 2:i3
	call NoteMap_InitVoiceSlots

NoteMap_VoiceAssign_Finalize:
	ld	(xsp+332), 0x00
	ld	(xsp+333), 0x01
	lda xwa, (xsp+330)
	call NoteMap_LookupAndMergeVoice
	cp l, 0:i3
	jrl z, NoteMap_ReallocVoices_Exit
	lda xwa, (xsp+330)
	lda xbc, (0xc1fe:16)
	ld de, 0:i3
	call Voice_ApplyTransposeWithEncode
	lda xiy, (xsp+330)
	lda xix, (xsp+166:16)
	ldw bc, 0x52
	ldirw
	ld de, 0:i3
	jr VoiceAssign_Finalize_LoopCheck

VoiceAssign_Finalize_LoopBody:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	lda xwa, (xsp+167:16)
	add xwa, xbc
	ld (xwa), 0x0
	inc 1, de

VoiceAssign_Finalize_LoopCheck:
	ld	a, (xsp+167)
	extz wa
	cp de, wa
	jr c, VoiceAssign_Finalize_LoopBody
	ld	a, (xsp+498)
	cp a, 2:i3
	jrl z, ReallocEnabledVoices_CheckMem4
	cp a, 1:i3
	jrl z, ReallocEnabledVoices_CheckMem
	cp a, 0:i3
	jrl nz, NoteMap_ReallocVoices_Exit
	ld	a, (xsp+496)
	xor	a, (xsp+494)
	and	a, (xsp+494)
	ldfr_berp A, 0xfb
	cp a, 0:i3
	jrl z, NoteMap_UpdateChangedVoices
	bit_erpb 0xfb, 0x00
	jr z, VoiceAssign_Finalize_TestBit0
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	lda xwa, (0xc428:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, VoiceAssign_Finalize_TestBit0
	lda xwa, (xsp + 2)
	lda xbc, (0xc364:16)
	ld de, 0:i3
	call NoteMap_UpdateEntry

VoiceAssign_Finalize_TestBit0:
	bit_erpb 0xfb, 0x01
	jr z, VoiceAssign_Finalize_TestBit02
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	lda xwa, (0xc42c:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, VoiceAssign_Finalize_TestBit02
	lda xwa, (xsp + 2)
	lda xbc, (0xc364:16)
	ld de, 1:i3
	call NoteMap_UpdateEntry

VoiceAssign_Finalize_TestBit02:
	bit_erpb 0xfb, 0x02
	jr z, VoiceAssign_Finalize_TestBit03
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	lda xwa, (0xc430:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, VoiceAssign_Finalize_TestBit03
	lda xwa, (xsp + 2)
	lda xbc, (0xc364:16)
	ld de, 2:i3
	call NoteMap_UpdateEntry

VoiceAssign_Finalize_TestBit03:
	bit_erpb 0xfb, 0x03
	jr z, NoteMap_UpdateChangedVoices
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	lda xwa, (0xc434:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, NoteMap_UpdateChangedVoices
	lda xwa, (xsp + 2)
	lda xbc, (0xc364:16)
	ldw de, 0x15
	call NoteMap_UpdateEntry
	call AudioInit_RefreshToneBank

NoteMap_UpdateChangedVoices:
	ld	a, (xsp+496)
	xor	a, (xsp+494)
	and	a, (xsp+496)
	ldfr_berp A, 0xfb
	cp a, 0:i3
	jrl z, NoteMap_ReallocEnabledVoices
	bit_erpb 0xfb, 0x00
	jr z, UpdateChangedVoices_TestBit0
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+330)
	ld xbc, xwa
	lda xwa, (0xc2c2:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, UpdateChangedVoices_TestBit0
	lda xwa, (xsp + 2)
	lda xbc, (0xc1fe:16)
	ld de, 0:i3
	call NoteMap_UpdateEntry

UpdateChangedVoices_TestBit0:
	bit_erpb 0xfb, 0x01
	jr z, UpdateChangedVoices_TestBit02
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+330)
	ld xbc, xwa
	lda xwa, (0xc2c6:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, UpdateChangedVoices_TestBit02
	lda xwa, (xsp + 2)
	lda xbc, (0xc1fe:16)
	ld de, 1:i3
	call NoteMap_UpdateEntry

UpdateChangedVoices_TestBit02:
	bit_erpb 0xfb, 0x02
	jr z, UpdateChangedVoices_TestBit03
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+330)
	ld xbc, xwa
	lda xwa, (0xc2ca:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, UpdateChangedVoices_TestBit03
	lda xwa, (xsp + 2)
	lda xbc, (0xc1fe:16)
	ld de, 2:i3
	call NoteMap_UpdateEntry

UpdateChangedVoices_TestBit03:
	bit_erpb 0xfb, 0x03
	jr z, NoteMap_ReallocEnabledVoices
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+330)
	ld xbc, xwa
	lda xwa, (0xc2ce:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, NoteMap_ReallocEnabledVoices
	lda xwa, (xsp + 2)
	lda xbc, (0xc1fe:16)
	ldw de, 0x15
	call NoteMap_UpdateEntry

NoteMap_ReallocEnabledVoices:
	ld	a, (xsp+496)
	and	a, (xsp+494)
	ldfr_berp A, 0xfb
	cp a, 0:i3
	jrl z, NoteMap_ReallocVoices_Exit
	bit_erpb 0xfb, 0x00
	jr z, ReallocEnabledVoices_TestBit0
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+330)
	ld xbc, xwa
	lda xwa, (0xc2c2:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	lda xwa, (xsp + 2)
	lda xbc, (0xc1fe:16)
	ld de, 0:i3
	call NoteMap_FindAndAllocBestVoice

ReallocEnabledVoices_TestBit0:
	bit_erpb 0xfb, 0x01
	jr z, ReallocEnabledVoices_TestBit02
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+330)
	ld xbc, xwa
	lda xwa, (0xc2c6:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	lda xwa, (xsp + 2)
	lda xbc, (0xc1fe:16)
	ld de, 1:i3
	call NoteMap_FindAndAllocBestVoice

ReallocEnabledVoices_TestBit02:
	bit_erpb 0xfb, 0x02
	jr z, ReallocEnabledVoices_TestBit03
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+330)
	ld xbc, xwa
	lda xwa, (0xc2ca:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	lda xwa, (xsp + 2)
	lda xbc, (0xc1fe:16)
	ld de, 2:i3
	call NoteMap_FindAndAllocBestVoice

ReallocEnabledVoices_TestBit03:
	bit_erpb 0xfb, 0x03
	jrl z, NoteMap_ReallocVoices_Exit
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+330)
	ld xbc, xwa
	lda xwa, (0xc2ce:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	lda xwa, (xsp + 2)
	lda xbc, (0xc1fe:16)
	ldw de, 0x15
	call NoteMap_FindAndAllocBestVoice
	jrl NoteMap_ReallocVoices_Exit

ReallocEnabledVoices_CheckMem:
	cp	(xsp+496), 0xff
	jr z, ReallocEnabledVoices_CheckMem2
	cp	(xsp+494), 0xff
	jr z, ReallocEnabledVoices_CheckMem2
	lda xwa, (xsp+166:16)
	ld xhl, xwa
	lda xbc, (0xc364:16)
	ld	a, (xsp+494)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_UpdateEntry
	lda xwa, (xsp+330)
	ld xhl, xwa
	lda xbc, (0xc1fe:16)
	ld	a, (xsp+496)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_UpdateEntry
	jrl NoteMap_ReallocVoices_Exit

ReallocEnabledVoices_CheckMem2:
	cp	(xsp+496), 0xff
	jrl nz, ReallocEnabledVoices_CheckMem3
	cp	(xsp+494), 0xff
	jrl z, ReallocEnabledVoices_CheckMem3
	lda xwa, (xsp+166:16)
	ld xhl, xwa
	lda xbc, (0xc364:16)
	ld	a, (xsp+494)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_UpdateEntry
	bit 0, (0xc1fe:16)
	jr z, ReallocEnabledVoices_TestBit1
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+330)
	ld xbc, xwa
	lda xwa, (0xc2c2:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, ReallocEnabledVoices_TestBit1
	lda xwa, (xsp + 2)
	lda xbc, (0xc1fe:16)
	ld de, 0:i3
	call NoteMap_UpdateEntry

ReallocEnabledVoices_TestBit1:
	bit 1, (0xc1fe:16)
	jr z, ReallocEnabledVoices_TestBit2
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+330)
	ld xbc, xwa
	lda xwa, (0xc2c6:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, ReallocEnabledVoices_TestBit2
	lda xwa, (xsp + 2)
	lda xbc, (0xc1fe:16)
	ld de, 1:i3
	call NoteMap_UpdateEntry

ReallocEnabledVoices_TestBit2:
	bit 2, (0xc1fe:16)
	jrl z, ReallocEnabledVoices_Block
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+330)
	ld xbc, xwa
	lda xwa, (0xc2ca:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jrl z, ReallocEnabledVoices_Block
	lda xwa, (xsp + 2)
	lda xbc, (0xc1fe:16)
	ld de, 2:i3
	call NoteMap_UpdateEntry
	jrl NoteMap_ReallocVoices_Exit

ReallocEnabledVoices_CheckMem3:
	cp	(xsp+496), 0xff
	jrl z, NoteMap_ReallocVoices_Exit
	cp	(xsp+494), 0xff
	jrl nz, NoteMap_ReallocVoices_Exit
	bit 0, (0xc364:16)
	jr z, ReallocEnabledVoices_TestBit12
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	lda xwa, (0xc428:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, ReallocEnabledVoices_TestBit12
	lda xwa, (xsp + 2)
	lda xbc, (0xc364:16)
	ld de, 0:i3
	call NoteMap_UpdateEntry

ReallocEnabledVoices_TestBit12:
	bit 1, (0xc364:16)
	jr z, ReallocEnabledVoices_TestBit22
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	lda xwa, (0xc42c:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, ReallocEnabledVoices_TestBit22
	lda xwa, (xsp + 2)
	lda xbc, (0xc364:16)
	ld de, 1:i3
	call NoteMap_UpdateEntry

ReallocEnabledVoices_TestBit22:
	bit 2, (0xc364:16)
	jr z, ReallocEnabledVoices_WriteReg
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	lda xwa, (0xc430:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, ReallocEnabledVoices_WriteReg
	lda xwa, (xsp + 2)
	lda xbc, (0xc364:16)
	ld de, 2:i3
	call NoteMap_UpdateEntry

ReallocEnabledVoices_WriteReg:
	lda xwa, (xsp+330)
	ld xhl, xwa
	lda xbc, (0xc1fe:16)
	ld	a, (xsp+496)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_UpdateEntry

ReallocEnabledVoices_Block:
	jrl NoteMap_ReallocVoices_Exit

ReallocEnabledVoices_CheckMem4:
	cp	(xsp+496), 0xff
	jrl z, ReallocEnabledVoices_CheckMem5
	cp	(xsp+494), 0xff
	jrl z, ReallocEnabledVoices_CheckMem5
	cpw (0xce68:16), 0
	jr nz, ReallocEnabledVoices_LoadAddr
	lda xwa, (0xc364:16)
	ld bc, 2:i3
	call NoteMap_AssignVoiceParams

ReallocEnabledVoices_LoadAddr:
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	ld de, 4:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, ReallocEnabledVoices_LoadAddr2

ReallocEnabledVoices_DoFindEntr:
	lda xwa, (xsp + 2)
	ld bc, 2:i3
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	ld de, 4:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr nz, ReallocEnabledVoices_DoFindEntr

ReallocEnabledVoices_LoadAddr2:
	lda xwa, (xsp + 2)
	ld xix, xwa
	lda xwa, (xsp+330)
	ld xhl, xwa
	ld	a, (xsp+496)
	extz wa
	sla wa, 2
	add wa, 0xc4
	lda xbc, (0xc1fe:16)

ReallocEnabledVoices_WriteReg2:	; NOTE: nothing seems to call here, but I saw this value on VGA undocumented registers at routine EF5163. It may be just a coincidence, though.  (was ReallocEnabledVoices_LoadAddr2_0x1D - off by 1 byte)
	lda	xde, (xbc+wa)
	ld xwa, xix
	ld xbc, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jrl z, NoteMap_ReallocVoices_Exit
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp + 2)
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	ld de, 4:i3
	call NoteMap_CollectMatchingEntries
	cp l, 0:i3
	jrl z, NoteMap_ReallocVoices_Exit
	lda xwa, (xsp + 2)
	ld bc, 2:i3
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	cp l, 0:i3
	jrl nz, NoteMap_ReallocVoices_Exit
	call NoteMap_FindBestMatch
	cp l, 0xff
	jrl z, NoteMap_ReallocVoices_Exit
	lda xwa, (0xc1fe:16)
	ld bc, 2:i3
	call NoteMap_InitVoiceSlots
	jrl NoteMap_ReallocVoices_Exit

ReallocEnabledVoices_CheckMem5:
	cp	(xsp+496), 0xff
	jr nz, ReallocEnabledVoices_CheckMem6
	cp	(xsp+494), 0xff
	jr z, ReallocEnabledVoices_CheckMem6
	cpw (0xce68:16), 0
	jr nz, ReallocEnabledVoices_LoadAddr3
	lda xwa, (0xc364:16)
	ld bc, 2:i3
	call NoteMap_AssignVoiceParams

ReallocEnabledVoices_LoadAddr3:
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	ld de, 4:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jrl z, NoteMap_ReallocVoices_Exit

ReallocEnabledVoices_DoFindEntr2:
	lda xwa, (xsp + 2)
	ld bc, 2:i3
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	ld de, 4:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr nz, ReallocEnabledVoices_DoFindEntr2
	jr NoteMap_ReallocVoices_Exit

ReallocEnabledVoices_CheckMem6:
	cp	(xsp+496), 0xff
	jr z, NoteMap_ReallocVoices_Exit
	cp	(xsp+494), 0xff
	jr nz, NoteMap_ReallocVoices_Exit
	lda xwa, (xsp + 2)
	ld xix, xwa
	lda xwa, (xsp+330)
	ld xhl, xwa
	ld	a, (xsp+496)
	extz wa
	sla wa, 2
	add wa, 0xc4
	lda xbc, (0xc1fe:16)
	lda	xde, (xbc+wa)
	ld xwa, xix
	ld xbc, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, NoteMap_ReallocVoices_Exit
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp + 2)
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	ld de, 4:i3
	call NoteMap_CollectMatchingEntries
	cp l, 0:i3
	jr z, NoteMap_ReallocVoices_Exit
	lda xwa, (xsp + 2)
	ld bc, 2:i3
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	cp l, 0:i3
	jr nz, NoteMap_ReallocVoices_Exit
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_ReallocVoices_Exit
	lda xwa, (0xc1fe:16)
	ld bc, 2:i3
	call NoteMap_InitVoiceSlots

NoteMap_ReallocVoices_Exit:
	popw_erp 0xfa
	lda xsp, (xsp+498)
	ret

ReallocVoices_Exit_WriteReg:
	lda xsp, (xsp-328)
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
	cp a, 0:i3
	jrl nz, ReallocVoices_Exit_WriteReg4
	bit 4, (0xc488:16)
	jrl z, ReallocVoices_Exit_WriteReg4
	ld	(xsp+166), 0x00
	ld	(xsp+167), 0x01
	lda xwa, (xsp+164:16)
	call Voice_LookupTableEntries
	cp l, 0:i3
	jrl z, NoteMap_StoreAndRet
	lda xwa, (xsp+164:16)
	call NoteMap_AssignAllVoiceLinks
	cp (0xc365:16), 255
	jrl nz, ReallocVoices_Exit_CheckDRAM
	bit 0, (0xc364:16)
	jr z, ReallocVoices_Exit_TestBit1
	lda xwa, (xsp)
	ld xhl, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	lda xwa, (0xc428:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, ReallocVoices_Exit_TestBit1
	lda xwa, (xsp)
	lda xbc, (0xc364:16)
	ld de, 0:i3
	call NoteMap_UpdateEntry

ReallocVoices_Exit_TestBit1:
	bit 1, (0xc364:16)
	jr z, ReallocVoices_Exit_TestBit2
	lda xwa, (xsp)
	ld xhl, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	lda xwa, (0xc42c:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, ReallocVoices_Exit_TestBit2
	lda xwa, (xsp)
	lda xbc, (0xc364:16)
	ld de, 1:i3
	call NoteMap_UpdateEntry

ReallocVoices_Exit_TestBit2:
	bit 2, (0xc364:16)
	jr z, ReallocVoices_Exit_TestBit3
	lda xwa, (xsp)
	ld xhl, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	lda xwa, (0xc430:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, ReallocVoices_Exit_TestBit3
	lda xwa, (xsp)
	lda xbc, (0xc364:16)
	ld de, 2:i3
	call NoteMap_UpdateEntry

ReallocVoices_Exit_TestBit3:
	bit 3, (0xc364:16)
	jrl z, ReallocVoices_Exit_Block
	lda xwa, (xsp)
	ld xhl, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	lda xwa, (0xc434:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jrl z, ReallocVoices_Exit_Block
	lda xwa, (xsp)
	lda xbc, (0xc364:16)
	ldw de, 0x15
	call NoteMap_UpdateEntry
	call AudioInit_RefreshToneBank
	jrl NoteMap_StoreAndRet

ReallocVoices_Exit_CheckDRAM:
	cp (0xc365:16), 21
	jr nz, ReallocVoices_Exit_TestBit32
	ld wa, (0xc598:16)
	bit 1, wa
	jr z, ReallocVoices_Exit_WriteReg2
	lda xwa, (xsp+164:16)
	call NoteMap_MarkEntriesAboveThreshold

ReallocVoices_Exit_WriteReg2:
	lda xwa, (xsp+164:16)
	lda xbc, (0xc364:16)
	ldw de, 0x15
	call NoteMap_UpdateEntry
	jr NoteMap_StoreAndRet

ReallocVoices_Exit_TestBit32:
	bit 3, (0xc364:16)
	jr z, ReallocVoices_Exit_WriteReg3
	lda xwa, (xsp)
	ld xhl, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	lda xwa, (0xc434:16)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cp l, 0:i3
	jr z, ReallocVoices_Exit_WriteReg3
	lda xwa, (xsp)
	lda xbc, (0xc364:16)
	ldw de, 0x15
	call NoteMap_UpdateEntry
	call AudioInit_RefreshToneBank

ReallocVoices_Exit_WriteReg3:
	lda xwa, (xsp+164:16)
	ld xhl, xwa
	lda xbc, (0xc364:16)
	ld a, (0xc365:16)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_UpdateEntry

ReallocVoices_Exit_Block:
	jr NoteMap_StoreAndRet

ReallocVoices_Exit_WriteReg4:
	ld	(xsp+166), 0x01
	ld	(xsp+167), e
	lda xbc, (xsp+164:16)
	ld xhl, xbc
	lda xbc, (0xc364:16)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_CollectAndAllocVoice_Indirect

NoteMap_StoreAndRet:
	lda xsp, (xsp+328)
	ret

StoreAndRet_WriteReg:
	lda xsp, (xsp-332)
	ld	(xsp+328), c
	ld	(xsp+330), a
	cp	(xsp+330), 0xff
	jrl z, VoiceRealloc_CheckSingleLayer
	cp	(xsp+328), 0xff
	jrl z, VoiceRealloc_CheckSingleLayer
	cpw (0xce68:16), 1
	jr nz, StoreAndRet_WriteReg2
	lda xwa, (0xc364:16)
	ld bc, 2:i3
	call NoteMap_AssignVoiceParams

StoreAndRet_WriteReg2:
	ld	(xsp+166), 0x01
	ld	a, (xsp+328)
	extz wa
	lda xbc, (0xc388:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld	(xsp+167), a
	lda xwa, (xsp)
	ld xde, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	ld	a, (xsp+328)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, StoreAndRet_WriteReg3
	lda xwa, (xsp)
	ld bc, 2:i3
	call NoteMap_FindEntry
	lda xwa, (xsp)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch

StoreAndRet_WriteReg3:
	ld	(xsp+166), 0x01
	ld	a, (xsp+330)
	extz wa
	lda xbc, (0xc222:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld	(xsp+167), a
	lda xwa, (xsp)
	ld xde, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	ld	a, (xsp+330)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jrl z, NoteMap_StoreVoiceResultAndReturn
	lda xwa, (xsp)
	ld xhl, xwa
	lda xbc, (0xc1fe:16)
	ld	a, (xsp+330)
	ld e, a
	extz de
	ld xwa, xhl
	call Voice_ApplyTransposeWithEncode
	lda xwa, (xsp)
	ld bc, 2:i3
	call NoteMap_FindEntry
	lda xwa, (xsp)
	call NoteMap_FindBestFreeVoice
	cp l, 1:i3
	jrl nz, NoteMap_StoreVoiceResultAndReturn
	call NoteMap_FindBestMatch
	cp l, 0xff
	jrl z, NoteMap_StoreVoiceResultAndReturn
	lda xwa, (0xc1fe:16)
	ld bc, 2:i3
	call NoteMap_InitVoiceSlots
	jrl NoteMap_StoreVoiceResultAndReturn

VoiceRealloc_CheckSingleLayer:
	cp	(xsp+330), 0xff
	jr nz, VoiceRealloc_CheckAltLayer
	cp	(xsp+328), 0xff
	jr z, VoiceRealloc_CheckAltLayer
	cpw (0xce68:16), 1
	jr nz, VoiceRealloc_LookupVoice
	lda xwa, (0xc364:16)
	ld bc, 2:i3
	call NoteMap_AssignVoiceParams

VoiceRealloc_LookupVoice:
	ld	(xsp+166), 0x01
	ld	a, (xsp+328)
	extz wa
	lda xbc, (0xc388:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld	(xsp+167), a
	lda xwa, (xsp)
	ld xde, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	ld	a, (xsp+328)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jrl z, NoteMap_StoreVoiceResultAndReturn
	lda xwa, (xsp)
	ld bc, 2:i3
	call NoteMap_FindEntry
	lda xwa, (xsp)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch
	jrl NoteMap_StoreVoiceResultAndReturn

VoiceRealloc_CheckAltLayer:
	cp	(xsp+330), 0xff
	jr z, NoteMap_StoreVoiceResultAndReturn
	cp	(xsp+328), 0xff
	jr nz, NoteMap_StoreVoiceResultAndReturn
	ld	(xsp+166), 0x01
	ld	a, (xsp+330)
	extz wa
	lda xbc, (0xc222:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld	(xsp+167), a
	lda xwa, (xsp)
	ld xde, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	ld	a, (xsp+330)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jr z, NoteMap_StoreVoiceResultAndReturn
	lda xwa, (xsp)
	ld xhl, xwa
	lda xbc, (0xc1fe:16)
	ld	a, (xsp+330)
	ld e, a
	extz de
	ld xwa, xhl
	call Voice_ApplyTransposeWithEncode
	lda xwa, (xsp)
	ld bc, 2:i3
	call NoteMap_FindEntry
	lda xwa, (xsp)
	call NoteMap_FindBestFreeVoice
	cp l, 1:i3
	jr nz, NoteMap_StoreVoiceResultAndReturn
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_StoreVoiceResultAndReturn
	lda xwa, (0xc1fe:16)
	ld bc, 2:i3
	call NoteMap_InitVoiceSlots

NoteMap_StoreVoiceResultAndReturn:
	lda xsp, (xsp+332)
	ret

NoteMap_ProcessDualLayerNoteOff:
	lda xsp, (xsp-168)
	ld	(xsp+164), e
	ld	(xsp+166), a
	cp c, 0xff
	jr z, NoteMap_DualLayerNoteOff_SinglePath
	cp	(xsp+164), 0xff
	jr z, NoteMap_DualLayerNoteOff_SinglePath
	ld (xsp + 2), 0x2
	ld	a, (xsp+166)
	ld (xsp + 3), a
	lda xwa, (xsp)
	ld xhl, xwa
	lda xbc, (0xc364:16)
	ld	a, (xsp+164)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_ProcessNoteEvent
	ld (xsp + 2), 0x3
	ld	a, (xsp+166)
	ld (xsp + 3), a
	lda xwa, (xsp)
	ld xhl, xwa
	lda xbc, (0xc364:16)
	ld	a, (xsp+164)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_ProcessNoteEvent
	jr NoteMap_ProcessNote_SetResult

NoteMap_DualLayerNoteOff_SinglePath:
	cp c, 0xff
	jr nz, NoteMap_ProcessNote_SetResult
	cp	(xsp+164), 0xff
	jr z, NoteMap_ProcessNote_SetResult
	ld (xsp + 2), 0x2
	ld	a, (xsp+166)
	ld (xsp + 3), a
	lda xwa, (xsp)
	ld xhl, xwa
	lda xbc, (0xc364:16)
	ld	a, (xsp+164)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_ProcessNoteEvent
	ld (xsp + 2), 0x3
	ld	a, (xsp+166)
	ld (xsp + 3), a
	lda xwa, (xsp)
	ld xhl, xwa
	lda xbc, (0xc364:16)
	ld	a, (xsp+164)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_ProcessNoteEvent

NoteMap_ProcessNote_SetResult:
	lda xsp, (xsp+168:16)
	ret

NoteMap_ProcessLayeredNoteOn:
	lda xsp, (xsp-332)
	ld	(xsp+328), e
	ld	(xsp+330), a
	cp c, 0xff
	jrl z, ProcessLayeredNoteOn_CheckEnd
	cp	(xsp+328), 0xff
	jrl z, ProcessLayeredNoteOn_CheckEnd
	ld	(xsp+166), 0x02
	ld	a, (xsp+330)
	ld	(xsp+167), a
	lda xwa, (xsp)
	ld xhl, xwa
	lda xwa, (xsp+164:16)
	ld xde, xwa
	ld	a, (xsp+330)
	extz wa
	lda xbc, (0xc3e8:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	pushw wa
	ld xwa, xhl
	ld xbc, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, ProcessLayeredNoteOn_WriteReg
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+328)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

ProcessLayeredNoteOn_WriteReg:
	ld	(xsp+166), 0x03
	ld	a, (xsp+330)
	ld	(xsp+167), a
	lda xwa, (xsp)
	ld xhl, xwa
	lda xwa, (xsp+164:16)
	ld xde, xwa
	ld	a, (xsp+330)
	extz wa
	lda xbc, (0xc3e8:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	pushw wa
	ld xwa, xhl
	ld xbc, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jrl z, ProcessLayeredNoteOn_WriteReg3
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+328)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents
	jrl ProcessLayeredNoteOn_WriteReg3

ProcessLayeredNoteOn_CheckEnd:
	cp c, 0xff
	jrl nz, ProcessLayeredNoteOn_WriteReg3
	cp	(xsp+328), 0xff
	jrl z, ProcessLayeredNoteOn_WriteReg3
	ld	(xsp+166), 0x02
	ld	a, (xsp+330)
	ld	(xsp+167), a
	lda xwa, (xsp)
	ld xhl, xwa
	lda xwa, (xsp+164:16)
	ld xde, xwa
	ld	a, (xsp+330)
	extz wa
	lda xbc, (0xc3e8:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	pushw wa
	ld xwa, xhl
	ld xbc, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, ProcessLayeredNoteOn_WriteReg2
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+328)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

ProcessLayeredNoteOn_WriteReg2:
	ld	(xsp+166), 0x03
	ld	a, (xsp+330)
	ld	(xsp+167), a
	lda xwa, (xsp)
	ld xhl, xwa
	lda xwa, (xsp+164:16)
	ld xde, xwa
	ld	a, (xsp+330)
	extz wa
	lda xbc, (0xc3e8:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	pushw wa
	ld xwa, xhl
	ld xbc, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, ProcessLayeredNoteOn_WriteReg3
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+328)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

ProcessLayeredNoteOn_WriteReg3:
	lda xsp, (xsp+332)
	ret

ProcessLayeredNoteOn_WriteReg4:
	lda xsp, (xsp-332)
	pushw iz
	ld	(xsp+330), c
	ld	(xsp+332), a
	cp	(xsp+332), 0xff
	jrl z, LoopAdvance_Next_CheckMem
	cp	(xsp+330), 0xff
	jrl z, LoopAdvance_Next_CheckMem
	cpw (0xce68:16), 2
	jr nz, ProcessLayeredNoteOn_InitVal
	cpw (0xce68:16), 3
	jr nz, ProcessLayeredNoteOn_InitVal
	lda xwa, (0xc364:16)
	ld bc, 2:i3
	call NoteMap_AssignVoiceParams

ProcessLayeredNoteOn_InitVal:
	ld iz, 0:i3
	cp iz, 0x10
	jrl nc, ProcessLayeredNoteOn_InitVal2

ProcessLayeredNoteOn_LoadIter:
	ld wa, iz
	lda xbc, (0xc3e8:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp	a, (xsp+330)
	jr nz, ProcessLayeredNoteOn_NextIter
	ld	(xsp+168), 0x03
	ldto_berp A, 0xf8
	ld	(xsp+169), a
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	ld de, 4:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, ProcessLayeredNoteOn_WriteReg5
	lda xwa, (xsp + 2)
	ld bc, 2:i3
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch

ProcessLayeredNoteOn_WriteReg5:
	ld	(xsp+168), 0x02
	ldto_berp A, 0xf8
	ld	(xsp+169), a
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	ld de, 4:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, ProcessLayeredNoteOn_NextIter
	lda xwa, (xsp + 2)
	ld bc, 2:i3
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch

ProcessLayeredNoteOn_NextIter:
	inc 1, iz
	cp iz, 0x10
	jrl c, ProcessLayeredNoteOn_LoadIter

ProcessLayeredNoteOn_InitVal2:
	ld iz, 0:i3
	cp iz, 0x10
	jrl nc, NoteMap_PopIzStoreRet

ProcessLayeredNoteOn_LoadIter2:
	ld wa, iz
	lda xbc, (0xc3e8:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp	a, (xsp+332)
	jrl nz, NoteMap_LoopAdvance_Next
	ld	(xsp+168), 0x03
	ldto_berp A, 0xf8
	ld	(xsp+169), a
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	ld	a, (xsp+332)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jr z, NoteMap_ClaimAndInitVoiceSlot_A
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xbc, (0xc1fe:16)
	ld	a, (xsp+332)
	ld e, a
	extz de
	ld xwa, xhl
	call SndParam_ComputeVoiceTuning
	lda xwa, (xsp + 2)
	ld bc, 2:i3
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	cp l, 3:i3
	jr nz, NoteMap_ClaimAndInitVoiceSlot_A
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_ClaimAndInitVoiceSlot_A
	lda xwa, (0xc1fe:16)
	ld bc, 2:i3
	call NoteMap_InitVoiceSlots

NoteMap_ClaimAndInitVoiceSlot_A:
	ld	(xsp+168), 0x02
	ldto_berp A, 0xf8
	ld	(xsp+169), a
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	ld	a, (xsp+332)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jr z, NoteMap_LoopAdvance_Next
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xbc, (0xc1fe:16)
	ld	a, (xsp+332)
	ld e, a
	extz de
	ld xwa, xhl
	call SndParam_ComputeVoiceTuning
	lda xwa, (xsp + 2)
	ld bc, 2:i3
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	cp l, 2:i3
	jr nz, NoteMap_LoopAdvance_Next
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_LoopAdvance_Next
	lda xwa, (0xc1fe:16)
	ld bc, 2:i3
	call NoteMap_InitVoiceSlots

NoteMap_LoopAdvance_Next:
	inc 1, iz
	cp iz, 0x10
	jrl c, ProcessLayeredNoteOn_LoadIter2
	jrl NoteMap_PopIzStoreRet

LoopAdvance_Next_CheckMem:
	cp	(xsp+332), 0xff
	jrl nz, LoopAdvance_Next_CheckMem2
	cp	(xsp+330), 0xff
	jrl z, LoopAdvance_Next_CheckMem2
	cpw (0xce68:16), 2
	jr nz, LoopAdvance_Next_InitVal
	cpw (0xce68:16), 3
	jr nz, LoopAdvance_Next_InitVal
	lda xwa, (0xc364:16)
	ld bc, 2:i3
	call NoteMap_AssignVoiceParams

LoopAdvance_Next_InitVal:
	ld iz, 0:i3
	cp iz, 0x10
	jrl nc, NoteMap_PopIzStoreRet

LoopAdvance_Next_LoadIter:
	ld wa, iz
	lda xbc, (0xc3e8:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp	a, (xsp+330)
	jr nz, LoopAdvance_Next_Increment
	ld	(xsp+168), 0x03
	ldto_berp A, 0xf8
	ld	(xsp+169), a
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	ld de, 4:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, LoopAdvance_Next_WriteReg
	lda xwa, (xsp + 2)
	ld bc, 2:i3
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch

LoopAdvance_Next_WriteReg:
	ld	(xsp+168), 0x02
	ldto_berp A, 0xf8
	ld	(xsp+169), a
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	ld de, 4:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, LoopAdvance_Next_Increment
	lda xwa, (xsp + 2)
	ld bc, 2:i3
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
	cp	(xsp+332), 0xff
	jrl z, NoteMap_PopIzStoreRet
	cp	(xsp+330), 0xff
	jrl nz, NoteMap_PopIzStoreRet
	ld iz, 0:i3
	cp iz, 0x10
	jrl nc, NoteMap_PopIzStoreRet

LoopAdvance_Next_LoadIter2:
	ld wa, iz
	lda xbc, (0xc3e8:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp	a, (xsp+332)
	jrl nz, NoteMap_LoopAdvance_Next2
	ld	(xsp+168), 0x03
	ldto_berp A, 0xf8
	ld	(xsp+169), a
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	ld	a, (xsp+332)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jr z, NoteMap_ClaimAndInitVoiceSlot_B
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xbc, (0xc1fe:16)
	ld	a, (xsp+332)
	ld e, a
	extz de
	ld xwa, xhl
	call SndParam_ComputeVoiceTuning
	lda xwa, (xsp + 2)
	ld bc, 2:i3
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	cp l, 3:i3
	jr nz, NoteMap_ClaimAndInitVoiceSlot_B
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_ClaimAndInitVoiceSlot_B
	lda xwa, (0xc1fe:16)
	ld bc, 2:i3
	call NoteMap_InitVoiceSlots

NoteMap_ClaimAndInitVoiceSlot_B:
	ld	(xsp+168), 0x02
	ldto_berp A, 0xf8
	ld	(xsp+169), a
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp+166:16)
	ld xbc, xwa
	ld	a, (xsp+332)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jr z, NoteMap_LoopAdvance_Next2
	lda xwa, (xsp + 2)
	ld xhl, xwa
	lda xbc, (0xc1fe:16)
	ld	a, (xsp+332)
	ld e, a
	extz de
	ld xwa, xhl
	call SndParam_ComputeVoiceTuning
	lda xwa, (xsp + 2)
	ld bc, 2:i3
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	cp l, 2:i3
	jr nz, NoteMap_LoopAdvance_Next2
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, NoteMap_LoopAdvance_Next2
	lda xwa, (0xc1fe:16)
	ld bc, 2:i3
	call NoteMap_InitVoiceSlots

NoteMap_LoopAdvance_Next2:
	inc 1, iz
	cp iz, 0x10
	jrl c, LoopAdvance_Next_LoadIter2

NoteMap_PopIzStoreRet:
	popw iz
	lda xsp, (xsp+332)
	ret

PopIzStoreRet_Prologue:
	dec 2, xsp
	ld (xsp), a
	cp c, 0xff
	jr nz, PopIzStoreRet_CheckEnd
	cp e, 0xff
	jr z, PopIzStoreRet_CheckEnd
	lda xde, (0xc364:16)
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
	lda xde, (0xc364:16)
	ld a, (xsp)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AssignVoiceParams
	lda xde, (0xc1fe:16)
	ld a, (xsp)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocateVoice
	jr PopIzStoreRet_Increment

PopIzStoreRet_Block:
	lda xde, (0xc1fe:16)
	ld a, (xsp)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocateVoice

PopIzStoreRet_Increment:
	inc 2, xsp
	ret

PopIzStoreRet_WriteReg:
	lda xsp, (xsp-334)
	ld	(xsp+328), e
	ld	(xsp+330), c
	ld	(xsp+332), a
	cp	(xsp+330), 0xff
	jrl nz, NoteMap_CrossChannelReassign
	cp	(xsp+328), 0xff
	jrl z, NoteMap_CrossChannelReassign
	ld	(xsp+166), 0x00
	ld	(xsp+167), 0x00
	lda xwa, (xsp)
	ld xde, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	ld	a, (xsp+332)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, PopIzStoreRet_WriteReg2
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+328)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

PopIzStoreRet_WriteReg2:
	ld	(xsp+166), 0x04
	ld	(xsp+167), 0xff
	lda xwa, (xsp)
	ld xde, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	ld	a, (xsp+332)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, PopIzStoreRet_WriteReg3
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+328)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

PopIzStoreRet_WriteReg3:
	ld	(xsp+166), 0x06
	ld	(xsp+167), 0xff
	lda xwa, (xsp)
	ld xde, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	ld	a, (xsp+332)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, NoteMap_CrossChannelReassign
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+328)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

NoteMap_CrossChannelReassign:
	cp	(xsp+330), 0xff
	jr z, NoteMap_SetParam_Return
	ld	a, (xsp+330)
	cp	a, (xsp+328)
	jr z, NoteMap_SetParam_Return
	cp	(xsp+332), 0x15
	jr z, CrossChannelReassign_WriteReg
	cp	(xsp+332), 0x02
	jr nz, NoteMap_SetParam_Return

CrossChannelReassign_WriteReg:
	ld	(xsp+166), 0x06
	ld	(xsp+167), 0xff
	lda xwa, (xsp)
	ld xde, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	ld	a, (xsp+332)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_ClaimVoiceSlot
	cp l, 0:i3
	jr z, NoteMap_SetParam_Return
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+330)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

NoteMap_SetParam_Return:
	lda xsp, (xsp+334)
	ret

SetParam_Return_WriteReg:
	lda xsp, (xsp-332)
	ld	(xsp+328), e
	ld	(xsp+330), a
	cp c, 0xff
	jrl z, SetParam_Return_CheckEnd
	cp	(xsp+328), 0xff
	jrl z, SetParam_Return_CheckEnd
	ld	(xsp+166), 0x00
	ld	(xsp+167), 0x00
	lda xwa, (xsp)
	ld xde, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	ld	a, (xsp+330)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, SetParam_Return_WriteReg2
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+328)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

SetParam_Return_WriteReg2:
	ld	(xsp+166), 0x04
	ld	(xsp+167), 0xff
	lda xwa, (xsp)
	ld xde, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	ld	a, (xsp+330)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, SetParam_Return_WriteReg3
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+328)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

SetParam_Return_WriteReg3:
	ld	(xsp+166), 0x06
	ld	(xsp+167), 0xff
	cp	(xsp+330), 0x19
	jr nz, SetParam_Return_LoadAddr
	ld a, (0xc422:16)
	ld	(xsp+330), a

SetParam_Return_LoadAddr:
	lda xwa, (xsp)
	ld xde, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	ld	a, (xsp+330)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jrl z, SeqPart_LookupReturn
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+328)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents
	jrl SeqPart_LookupReturn

SetParam_Return_CheckEnd:
	cp c, 0xff
	jrl nz, SeqPart_LookupReturn
	cp	(xsp+328), 0xff
	jrl z, SeqPart_LookupReturn
	ld	(xsp+166), 0x00
	ld	(xsp+167), 0x00
	lda xwa, (xsp)
	ld xde, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	ld	a, (xsp+330)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, SetParam_Return_WriteReg4
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+328)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

SetParam_Return_WriteReg4:
	ld	(xsp+166), 0x04
	ld	(xsp+167), 0xff
	lda xwa, (xsp)
	ld xde, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	ld	a, (xsp+330)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, SetParam_Return_WriteReg5
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+328)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

SetParam_Return_WriteReg5:
	ld	(xsp+166), 0x06
	ld	(xsp+167), 0xff
	cp	(xsp+330), 0x19
	jr nz, SetParam_Return_LoadAddr2
	ld a, (0xc422:16)
	ld	(xsp+330), a

SetParam_Return_LoadAddr2:
	lda xwa, (xsp)
	ld xde, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	ld	a, (xsp+330)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, SeqPart_LookupReturn
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+328)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

SeqPart_LookupReturn:
	lda xsp, (xsp+332)
	ret

SeqPart_EmitMelodicNote:
	lda xsp, (xsp-332)
	ld	(xsp+328), e
	ld	(xsp+330), a
	cp c, 0xff
	jrl z, SeqPart_MelodicNote_SingleLayer
	cp	(xsp+328), 0xff
	jrl z, SeqPart_MelodicNote_SingleLayer
	ld	(xsp+166), 0x00
	ld	(xsp+167), 0x00
	lda xwa, (xsp)
	ld xde, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	ld	a, (xsp+328)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, SeqPart_MelodicNote_Layer1Done
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+330)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

SeqPart_MelodicNote_Layer1Done:
	ld	(xsp+166), 0x01
	ld	(xsp+167), 0xff
	lda xwa, (xsp)
	ld xde, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	ld	a, (xsp+328)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jrl z, SeqPart_EmitMelodicNote_Return
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+330)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents
	jrl SeqPart_EmitMelodicNote_Return

SeqPart_MelodicNote_SingleLayer:
	cp c, 0xff
	jrl nz, SeqPart_EmitMelodicNote_Return
	cp	(xsp+328), 0xff
	jr z, SeqPart_EmitMelodicNote_Return
	ld	(xsp+166), 0x00
	ld	(xsp+167), 0x00
	lda xwa, (xsp)
	ld xde, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	ld	a, (xsp+328)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, SeqPart_MelodicNote_Layer1Done_Alt
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+330)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

SeqPart_MelodicNote_Layer1Done_Alt:
	ld	(xsp+166), 0x01
	ld	(xsp+167), 0xff
	lda xwa, (xsp)
	ld xde, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	ld	a, (xsp+328)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, SeqPart_EmitMelodicNote_Return
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+330)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

SeqPart_EmitMelodicNote_Return:
	lda xsp, (xsp+332)
	ret

SeqPart_EmitPercussionNote:
	lda xsp, (xsp-332)
	ld	(xsp+328), e
	ld	(xsp+330), a
	cp c, 0xff
	jrl z, SeqPart_PercNote_SingleLayer
	cp	(xsp+328), 0xff
	jrl z, SeqPart_PercNote_SingleLayer
	ld	(xsp+166), 0x00
	ld	(xsp+167), 0x00
	lda xwa, (xsp)
	ld xde, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	ld	a, (xsp+330)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, SeqPart_PercNote_Layer1Done
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+328)
	ld c, a
	extz bc
	ld xwa, xde
	call SeqPart_EmitNoteOnMessages

SeqPart_PercNote_Layer1Done:
	ld	(xsp+166), 0x01
	ld	(xsp+167), 0xff
	lda xwa, (xsp)
	ld xde, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	ld	a, (xsp+330)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jrl z, SeqPart_EmitPercussionNote_Return
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+328)
	ld c, a
	extz bc
	ld xwa, xde
	call SeqPart_EmitNoteOnMessages
	jrl SeqPart_EmitPercussionNote_Return

SeqPart_PercNote_SingleLayer:
	cp c, 0xff
	jrl nz, SeqPart_EmitPercussionNote_Return
	cp	(xsp+328), 0xff
	jr z, SeqPart_EmitPercussionNote_Return
	ld	(xsp+166), 0x00
	ld	(xsp+167), 0x00
	lda xwa, (xsp)
	ld xde, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	ld	a, (xsp+330)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, SeqPart_PercNote_Layer1Done_Alt
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+328)
	ld c, a
	extz bc
	ld xwa, xde
	call SeqPart_EmitNoteOnMessages

SeqPart_PercNote_Layer1Done_Alt:
	ld	(xsp+166), 0x01
	ld	(xsp+167), 0xff
	lda xwa, (xsp)
	ld xde, xwa
	lda xwa, (xsp+164:16)
	ld xbc, xwa
	ld	a, (xsp+330)
	extz wa
	pushw wa
	ld xwa, xde
	ld de, 0:i3
	call NoteMap_LookupVoice
	cp l, 0:i3
	jr z, SeqPart_EmitPercussionNote_Return
	lda xwa, (xsp)
	ld xde, xwa
	ld	a, (xsp+328)
	ld c, a
	extz bc
	ld xwa, xde
	call SeqPart_EmitNoteOnMessages

SeqPart_EmitPercussionNote_Return:
	lda xsp, (xsp+332)
	ret

SeqPart_EmitNoteOn_Full:
	lda xsp, (xsp - 12)
	push xiz
	ld iz, 0:i3
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
	cp wa, 0:i3
	jr lt, RhythmBuf_EventDispatchLoop
	cp wa, 0x8
	jr gt, RhythmBuf_EventDispatchLoop
	add wa, wa
	lda xix, (RhythmBuf_SwitchOffsets:24)
	ld	wa, (xix+wa)
	lda xix, (Rhythm_ProcessEventDispatch:24)
	jp	t, (xix+wa)

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
	lda xbc, (Rhythm_EventMapA:24)
	ld	a, (xbc+wa)
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
	ld bc, 0:i3
	call SndPart_SetParam
	ld wa, (xsp + 4)
	ld de, (xsp + 8)
	ldw bc, 0x20
	call SndPart_SetParam
	ld wa, (xsp + 4)
	pushw 0x5
	ld de, (xsp + 8)
	ld bc, 0:i3
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 4)
	pushw 0x5
	ld de, (xsp + 10)
	ldw bc, 0x20
	call SndParam_NotifyAndReturn
	cp (0x8d36:16), 220
	jr z, ProcessEventDispatch_InitVal
	ld wa, (xsp + 4)
	pushw 0x3
	ld de, (xsp + 8)
	ld bc, 0:i3
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 4)
	pushw 0x3
	ld de, (xsp + 10)
	ldw bc, 0x20
	call SndParam_NotifyAndReturn

ProcessEventDispatch_InitVal:
	ld wa, 0:i3
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
	cp (0x8d36:16), 220
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
	cpiw_erp 0xfa, 3
	jrl nz, RhythmBuf_EventDispatchLoop
	cp iz, 0:i3
	jrl nz, RhythmBuf_EventDispatchLoop
	ldw iz, 0x10
	cp iz, 0x14
	jrl ge, RhythmBuf_EventDispatchLoop

ProcessEventDispatch_LoadIter:
	ld wa, iz
	ld bc, 1:i3
	ld de, 0:i3
	call SndPart_SetParam
	ld wa, iz
	pushw 0x5
	ld bc, 1:i3
	ld de, 0:i3
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
	ld de, 0:i3
	call SndPart_SetParam
	ld wa, iz
	pushw 0x5
	ldw bc, 0x40
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	ld wa, iz
	pushw 0x3
	ldw bc, 0x40
	ld de, 0:i3
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
	lda xbc, (Rhythm_EventMapA:24)
	ld	a, (xbc+wa)
	extz wa
	ld (xsp + 4), wa
	ldto_werp WA, 0xfa
	cp wa, 0x10
	jrl z, ProcessEventDispatch_DoInit
	cp wa, 5:i3
	jrl z, ProcessEventDispatch_LoadParam7
	cp wa, 4:i3
	jrl z, ProcessEventDispatch_LoadParam6
	cp wa, 3:i3
	jr z, ProcessEventDispatch_LoadParam5
	cp wa, 2:i3
	jr z, ProcessEventDispatch_InitVal2
	cp wa, 1:i3
	jrl nz, ProcessEventDispatch_Block
	ld wa, (xsp + 4)
	ld de, iz
	ld bc, 1:i3
	call SndPart_SetParam
	ld wa, (xsp + 4)
	pushw 0x5
	ld de, iz
	ld bc, 1:i3
	call SndParam_NotifyAndReturn
	jrl RhythmBuf_EventDispatchLoop

ProcessEventDispatch_InitVal2:
	ld wa, 0:i3
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
	ld iz, 0:i3
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
	lda xbc, (Rhythm_EventMapB:24)
	ld	a, (xbc+wa)
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
	ld bc, 0:i3
	call SndPart_SetParam
	ld wa, (xsp + 4)
	ld de, (xsp + 8)
	ldw bc, 0x20
	call SndPart_SetParam
	ld wa, (xsp + 4)
	ldw bc, 0x5e
	ld de, 0:i3
	call SndPart_SetParam
	ld wa, (xsp + 4)
	pushw 0x3
	ld de, (xsp + 8)
	ld bc, 0:i3
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 4)
	pushw 0x3
	ld de, (xsp + 10)
	ldw bc, 0x20
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 4)
	pushw 0x3
	ldw bc, 0x5e
	ld de, 0:i3
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
	cpiw_erp 0xfa, 3
	jrl nz, SeqEvtBuf_NonNoteDispatchLoop
	cp iz, 0:i3
	jrl nz, SeqEvtBuf_NonNoteDispatchLoop
	ldw (xsp + 8), 0x17
	cpw (xsp + 8), 0x18
	jrl ge, SeqEvtBuf_NonNoteDispatchLoop

NonNoteDispatchLoop_LoadParam2:
	ld wa, (xsp + 8)
	ld bc, 1:i3
	ld de, 0:i3
	call SndPart_SetParam
	ld wa, (xsp + 8)
	ldw bc, 0x1b0
	ldw de, 0x2000
	call SndPart_SetParam
	ld wa, (xsp + 8)
	ldw bc, 0x40
	ld de, 0:i3
	call SndPart_SetParam
	ld wa, (xsp + 8)
	ldw bc, 0xb
	ldw de, 0x7f
	call SndPart_SetParam
	ld wa, (xsp + 8)
	pushw 0x3
	ld bc, 1:i3
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 8)
	pushw 0x3
	ldw bc, 0x1b0
	ldw de, 0x2000
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 8)
	pushw 0x3
	ldw bc, 0x40
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 8)
	pushw 0x3
	ldw bc, 0xb
	ldw de, 0x7f
	call SndParam_NotifyAndReturn
	incw 1, (xsp + 8)
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
	lda xbc, (Rhythm_EventMapB:24)
	ld	a, (xbc+wa)
	extz wa
	ld (xsp + 4), wa
	ldto_werp WA, 0xfa
	dec 1, wa
	cp wa, 0:i3
	jrl lt, SeqPerformance_Event_Block
	cp wa, 6:i3
	jrl gt, SeqPerformance_Event_Block
	add wa, wa
	lda xix, (SeqEvtBuf_SwitchOffsets:24)
	ld	wa, (xix+wa)
	lda xix, (SeqPerformance_EventDispatch:24)
	jp	t, (xix+wa)

; Sequence performance event dispatch (6-entry, table 0xee8fc0)
SeqPerformance_EventDispatch:
	ld	wa, (xsp+4)
	ld	de, iz
	ld	bc, 1:i3
	call	SndPart_SetParam
	ld	wa, (xsp+4)
	pushw	3
	ld	de, iz
	ld	bc, 1:i3
	call	SndParam_NotifyAndReturn
	jrl	SeqEvtBuf_NonNoteDispatchLoop
	ld	wa, 0:i3
	cp	iz, 64
	jr	lt, ProcessEventDispatch_Prologue_Skip
	ld	wa, iz
	add	wa, wa
	sub	wa, 128
ProcessEventDispatch_Prologue_Skip:
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
	jrl	SeqEvtBuf_NonNoteDispatchLoop
	ld	wa, (xsp+4)
	ld	de, iz
	ldw	bc, 64
	call	SndPart_SetParam
	ld	wa, (xsp+4)
	pushw	3
	ld	de, iz
	ldw	bc, 64
	call	SndParam_NotifyAndReturn
	jrl	SeqEvtBuf_NonNoteDispatchLoop
	ld	wa, (xsp+4)
	ld	de, iz
	ldw	bc, 10
	call	SndPart_SetParam
	ld	wa, (xsp+4)
	pushw	3
	ld	de, iz
	ldw	bc, 10
	call	SndParam_NotifyAndReturn
	jrl	SeqEvtBuf_NonNoteDispatchLoop
	ld	wa, (xsp+4)
	ld	de, iz
	ldw	bc, 11
	call	SndPart_SetParam
	ld	wa, (xsp+4)
	pushw	3
	ld	de, iz
	ldw	bc, 11
	call	SndParam_NotifyAndReturn
	jrl	SeqEvtBuf_NonNoteDispatchLoop
	ld	wa, (xsp+4)
	ld	de, iz
	ldw	bc, 94
	call	SndPart_SetParam
	ld	wa, (xsp+4)
	pushw	3
	ld	de, iz
	ldw	bc, 94
	call	SndParam_NotifyAndReturn
	jrl	SeqEvtBuf_NonNoteDispatchLoop

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
	ld l, 0xff:opc
	cpw (0xce66:16), 0
	jr nz, VoiceMap_AllocateSlo_Block
	lda xwa, (0xce22:16)
	calr NoteMap_GetVoiceData_Entry
	cp l, 0xff
	jr z, VoiceMap_AllocateSlo_SetByteFF
	calr UIParam_ScanAndCollect
	ldmm8 0xceae, 0xcedf
	ldmm8 0xceb0, 0xcee0
	ld wa, (0xce24:16)
	ld l, a
	jr NoteMap_FindBestMatch_Return

VoiceMap_AllocateSlo_SetByteFF:
	ld l, 0xff:opc
	jr NoteMap_FindBestMatch_Return

VoiceMap_AllocateSlo_Block:
	cpw (0xce22:16), 0
	jr nz, VoiceMap_AllocateSlo_Block2
	calr Voice_ResetSearchState
	ld (0xceae:16), 255
	ld (0xceb0:16), 255
	ld wa, (0xce24:16)
	ld l, a
	jr NoteMap_FindBestMatch_Return

VoiceMap_AllocateSlo_Block2:
	lda xwa, (0xce22:16)
	calr NoteMap_GetVoiceData_Entry
	cp l, 0xff
	jr z, VoiceMap_AllocateSlo_SetByteFF2
	ld (0xe9bc:16), 10
	ld a, (0xceac:16)
	cp a, (0xceaa:16)
	jr nz, VoiceMap_AllocateSlo_Block3
	ld wa, (0xce24:16)
	cp wa, (0xce68:16)
	jr z, VoiceMap_AllocateSlo_SetByteFF2

VoiceMap_AllocateSlo_Block3:
	ld (0xceb2:16), 1

VoiceMap_AllocateSlo_SetByteFF2:
	ld l, 0xff:opc

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
	ld l, 0xff:opc
	ld (0xe9bc:16), 0
	cpw (0xce22:16), 0
	jr z, CheckVoiceReuse_Block
	ld a, (0xcedf:16)
	cp a, (0xceae:16)
	jr nz, NoteMap_CheckVoiceReuse
	ld a, (0xcee0:16)
	cp a, (0xceb0:16)
	jr nz, NoteMap_CheckVoiceReuse
	ld a, (0xceac:16)
	cp a, (0xceaa:16)
	jr nz, NoteMap_CheckVoiceReuse
	cp (0xceb2:16), 0
	jr z, CheckVoiceReuse_SetByteFF2

NoteMap_CheckVoiceReuse:
	lda xwa, (0xce22:16)
	calr NoteMap_GetVoiceData_Entry
	cp l, 0xff
	jr z, CheckVoiceReuse_SetByteFF
	calr UIParam_ScanAndCollect
	ldmm8 0xceae, 0xcedf
	ldmm8 0xceb0, 0xcee0
	ld wa, (0xce24:16)
	ld l, a
	jr NoteMap_GetVoiceData_Return

CheckVoiceReuse_SetByteFF:
	ld l, 0xff:opc
	jr NoteMap_GetVoiceData_Return

CheckVoiceReuse_SetByteFF2:
	ld l, 0xff:opc
	jr NoteMap_GetVoiceData_Return

CheckVoiceReuse_Block:
	calr Voice_ResetSearchState
	ld (0xceae:16), 255
	ld (0xceb0:16), 255
	ld wa, (0xce24:16)
	ld l, a

NoteMap_GetVoiceData_Return:
	ret

NoteMap_GetVoiceData_Entry:
	ld c, (0xceaa:16)
	ld (0xceac:16), c
	ld c, (0xceab:16)
	ld (0xcead:16), c
	cpw (xwa), 0x0
	jr z, GetVoiceData_Entry_Block2
	ld l, (xwa + 5)
	ld h, (xwa + 4)
	ld de, 1:i3
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
	ld (0xceaa:16), l
	ld (0xceab:16), h
	jr Voice_ReadSearchResult

GetVoiceData_Entry_Block:
	ld (0xceaa:16), 255
	ld (0xceab:16), 255
	jr Voice_ReadSearchResult

GetVoiceData_Entry_Block2:
	ld (0xceaa:16), 255
	ld (0xceab:16), 255

Voice_ReadSearchResult:
	ld l, (0xceaa:16)
	ret

Voice_ResetSearchState:
	ldw (0xce66:16), 0
	ld (0xceb2:16), 0
	ret

UIParam_ScanAndCollect:
	lda xsp, (xsp - 68)
	pushw_erp 0xfa
	ld (0xceb2:16), 0
	cp (0xceab:16), 15
	jr ule, UIParam_SetDefaultCount
	ld a, (0xceab:16)
	sub a, 0xf
	ldfr_berp A, 0xfb
	jr UIParam_CallbackDispatch

UIParam_SetDefaultCount:
	ldib_erp 0xfb, 1

; UIParam callback dispatch
UIParam_CallbackDispatch:
	lda xwa, (xsp + 2)
	ld c, (0xe9be:16)
	extz bc
	sla bc, 2
	lda xde, (Harmony_HandlerTable:24)
	exts xbc
	add xbc, xde
	ld xix, (xbc)
	call (xix)
	cp l, 0:i3
	jr z, UIParam_StoreAndReturn
	ld hl, 0:i3
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
	lda xbc, (0xce67:16)
	ld de, wa
	extz xde
	add xde, xbc
	ld a, (xix)
	ld (xde), a
	ld wa, hl
	add wa, wa
	lda xbc, (0xce6a:16)
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
	ld wa, (0xce24:16)
	ld (0xce68:16), wa
	ld wa, (xsp + 2)
	ld (0xce66:16), wa
	popw_erp 0xfa
	lda xsp, (xsp + 68)
	ret

NoteMap_SearchVoiceEntry:
	cpw (0xcf5f:16), 0
	jrl z, SearchVoice_SetZero
	ld hl, 0:i3
	ld de, 0:i3
	jr SearchVoice_CheckCount

SearchVoice_EntryLoop:
	cp de, 4:i3
	jr z, SearchVoice_StoreResult
	ld bc, hl
	add bc, bc
	inc 4, bc
	lda xix, (0xcf60:16)
	extz xbc
	add xbc, xix
	ld c, (xbc)
	ldfr_berp C, 0xea
	ld c, (0xceaa:16)
	ldto_berp B, 0xea
	cp b, c
	jr gt, SearchVoice_CheckHighBound
	ld c, (0xceaa:16)
	sub c, 0xc
	ld b, c
	ldto_berp C, 0xea
	cp c, b
	jr ule, SearchVoice_CheckLowBound
	jr SearchVoice_CheckDistance

SearchVoice_OctaveDown:
	sub_erpb 0xea, 0x0c

SearchVoice_CheckHighBound:
	ld c, (0xceaa:16)
	ldto_berp B, 0xea
	cp b, c
	jr gt, SearchVoice_OctaveDown
	jr SearchVoice_CheckDistance

SearchVoice_OctaveUp:
	add_erpb 0xea, 0x0c

SearchVoice_CheckLowBound:
	ld c, (0xceaa:16)
	sub c, 0xc
	ld b, c
	ldto_berp C, 0xea
	cp c, b
	jr ule, SearchVoice_OctaveUp

SearchVoice_CheckDistance:
	ld c, (0xceaa:16)
	subb_erp C, 0xea
	cp c, 2:i3
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
	cp hl, (0xcf5f:16)
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
	ld de, 0:i3
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
	cp l, 0:i3
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
	cp l, 0:i3
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
	cp l, 0:i3
	jr z, SoundFX_SetVolumeOffset_Return
	cpw (xiz), 0x1
	jr nz, SoundFX_Handler_1_Block
	ld a, (0xceaa:16)
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
	ld a, (0xceaa:16)
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
	djnz16 de, SoundFX_Handler_1_LoadReg

SoundFX_SetVolumeOffset_Return:
	ld hl, (xiz)
	pop xiz
	ret

SoundFX_Handler_2:
	push xiz
	ld xiz, xwa
	ld a, (0xcedf:16)
	ld e, a
	extz de
	ld a, (0xcee0:16)
	ld c, a
	extz bc
	ld wa, de
	calr VoiceBank_MapNoteToOffset
	ld a, l
	cp a, 0xff
	jr z, SoundFX_Handler_2_ClearWord
	ld a, (0xceaa:16)
	sub a, (0xcee0:16)
	add a, l
	inc 1, a
	ld l, a
	extz wa
	div a, 0xc
	ld l, w
	ld e, l
	extz de
	ld a, (0xcedf:16)
	dec 1, a
	extz wa
	muls wa, 0xc
	lda xbc, (Harmony_Offsets1_A:24)
	exts xwa
	add xwa, xbc
	ld	c, (xwa+de)
	ld a, (0xceaa:16)
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
	ld a, (0xcedf:16)
	ld e, a
	extz de
	ld a, (0xcee0:16)
	ld c, a
	extz bc
	ld wa, de
	calr VoiceBank_MapNoteToOffset
	ld a, l
	cp a, 0xff
	jr z, SoundFX_Handler_3_ClearWord
	ld a, (0xceaa:16)
	sub a, (0xcee0:16)
	add a, l
	inc 1, a
	ld l, a
	extz wa
	div a, 0xc
	ld l, w
	ld e, l
	extz de
	ld a, (0xcedf:16)
	dec 1, a
	extz wa
	muls wa, 0xc
	lda xbc, (Harmony_Offsets1_B:24)
	exts xwa
	add xwa, xbc
	ld	c, (xwa+de)
	ld a, (0xceaa:16)
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
	ld a, (0xcedf:16)
	ld e, a
	extz de
	ld a, (0xcee0:16)
	ld c, a
	extz bc
	ld wa, de
	calr VoiceBank_MapNoteToOffset
	ld a, l
	cp a, 0xff
	jr z, SoundFX_Handler_4_ClearWord
	ld a, (0xceaa:16)
	sub a, (0xcee0:16)
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
	ld a, (0xcedf:16)
	dec 1, a
	extz wa
	muls wa, 0x18
	lda xbc, (Harmony_Offsets2:24)
	exts xwa
	add xwa, xbc
	ld	c, (xwa+de)
	ld a, (0xceaa:16)
	sub a, c
	ld (xiz + 5), a
	ld a, l
	extz wa
	ld de, wa
	add de, de
	ld a, (0xcedf:16)
	dec 1, a
	extz wa
	muls wa, 0x18
	lda xbc, (Harmony_Offsets2:24)
	exts xwa
	add xwa, xbc
	lda	xwa, (xwa+de)
	ld c, (xwa + 1)
	ld a, (0xceaa:16)
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
	ld a, (0xcedf:16)
	ld e, a
	extz de
	ld a, (0xcee0:16)
	ld c, a
	extz bc
	ld wa, de
	calr VoiceBank_MapNoteToOffset
	ld a, l
	cp a, 0xff
	jrl z, SoundFX_Handler_5_ClearWord
	ld a, (0xceaa:16)
	sub a, (0xcee0:16)
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
	ld a, (0xcedf:16)
	dec 1, a
	extz wa
	muls wa, 0x24
	lda xbc, (Harmony_Offsets3_A:24)
	exts xwa
	add xwa, xbc
	ld	c, (xwa+de)
	ld a, (0xceaa:16)
	sub a, c
	ld (xiz + 5), a
	ld a, l
	extz wa
	muls wa, 0x3
	ld de, wa
	ld a, (0xcedf:16)
	dec 1, a
	extz wa
	muls wa, 0x24
	lda xbc, (Harmony_Offsets3_A:24)
	exts xwa
	add xwa, xbc
	lda	xwa, (xwa+de)
	ld c, (xwa + 1)
	ld a, (0xceaa:16)
	sub a, c
	ld (xiz + 7), a
	ld a, l
	extz wa
	muls wa, 0x3
	ld de, wa
	ld a, (0xcedf:16)
	dec 1, a
	extz wa
	muls wa, 0x24
	lda xbc, (Harmony_Offsets3_A:24)
	exts xwa
	add xwa, xbc
	lda	xwa, (xwa+de)
	ld c, (xwa + 2)
	ld a, (0xceaa:16)
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
	ld a, (0xcedf:16)
	ld e, a
	extz de
	ld a, (0xcee0:16)
	ld c, a
	extz bc
	ld wa, de
	calr VoiceBank_MapNoteToOffset
	ld a, l
	cp a, 0xff
	jrl z, SoundFX_Handler_6_ClearWord
	ld a, (0xceaa:16)
	sub a, (0xcee0:16)
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
	ld a, (0xcedf:16)
	dec 1, a
	extz wa
	muls wa, 0x30
	lda xbc, (Harmony_Offsets4_A:24)
	exts xwa
	add xwa, xbc
	ld	c, (xwa+de)
	ld a, (0xceaa:16)
	sub a, c
	ld (xiz + 5), a
	ld a, l
	extz wa
	ld de, wa
	sla de, 2
	ld a, (0xcedf:16)
	dec 1, a
	extz wa
	muls wa, 0x30
	lda xbc, (Harmony_Offsets4_A:24)
	exts xwa
	add xwa, xbc
	lda	xwa, (xwa+de)
	ld c, (xwa + 1)
	ld a, (0xceaa:16)
	sub a, c
	ld (xiz + 7), a
	ld a, l
	extz wa
	ld de, wa
	sla de, 2
	ld a, (0xcedf:16)
	dec 1, a
	extz wa
	muls wa, 0x30
	lda xbc, (Harmony_Offsets4_A:24)
	exts xwa
	add xwa, xbc
	lda	xwa, (xwa+de)
	ld c, (xwa + 2)
	ld a, (0xceaa:16)
	sub a, c
	ld (xiz + 9), a
	ld a, l
	extz wa
	ld de, wa
	sla de, 2
	ld a, (0xcedf:16)
	dec 1, a
	extz wa
	muls wa, 0x30
	lda xbc, (Harmony_Offsets4_A:24)
	exts xwa
	add xwa, xbc
	lda	xwa, (xwa+de)
	ld c, (xwa + 3)
	ld a, (0xceaa:16)
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
	ld a, (0xcedf:16)
	ld e, a
	extz de
	ld a, (0xcee0:16)
	ld c, a
	extz bc
	ld wa, de
	calr VoiceBank_MapNoteToOffset
	ld a, l
	cp a, 0xff
	jrl z, SoundFX_Handler_7_ClearWord
	ld a, (0xceaa:16)
	sub a, (0xcee0:16)
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
	ld a, (0xcedf:16)
	dec 1, a
	extz wa
	muls wa, 0x24
	lda xbc, (Harmony_Offsets3_B:24)
	exts xwa
	add xwa, xbc
	ld	c, (xwa+de)
	ld a, (0xceaa:16)
	sub a, c
	ld (xiz + 5), a
	ld a, l
	extz wa
	muls wa, 0x3
	ld de, wa
	ld a, (0xcedf:16)
	dec 1, a
	extz wa
	muls wa, 0x24
	lda xbc, (Harmony_Offsets3_B:24)
	exts xwa
	add xwa, xbc
	lda	xwa, (xwa+de)
	ld c, (xwa + 1)
	ld a, (0xceaa:16)
	sub a, c
	ld (xiz + 7), a
	ld a, l
	extz wa
	muls wa, 0x3
	ld de, wa
	ld a, (0xcedf:16)
	dec 1, a
	extz wa
	muls wa, 0x24
	lda xbc, (Harmony_Offsets3_B:24)
	exts xwa
	add xwa, xbc
	lda	xwa, (xwa+de)
	ld c, (xwa + 2)
	ld a, (0xceaa:16)
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
	ld a, (0xcedf:16)
	ld e, a
	extz de
	ld a, (0xcee0:16)
	ld c, a
	extz bc
	ld wa, de
	calr VoiceBank_MapNoteToOffset
	ld a, l
	cp a, 0xff
	jrl z, SoundFX_Handler_8_ClearWord
	ld a, (0xceaa:16)
	sub a, (0xcee0:16)
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
	ld a, (0xcedf:16)
	dec 1, a
	extz wa
	muls wa, 0x30
	lda xbc, (Harmony_Offsets4_B:24)
	exts xwa
	add xwa, xbc
	ld	c, (xwa+de)
	ld a, (0xceaa:16)
	sub a, c
	ld (xiz + 5), a
	ld a, l
	extz wa
	ld de, wa
	sla de, 2
	ld a, (0xcedf:16)
	dec 1, a
	extz wa
	muls wa, 0x30
	lda xbc, (Harmony_Offsets4_B:24)
	exts xwa
	add xwa, xbc
	lda	xwa, (xwa+de)
	ld c, (xwa + 1)
	ld a, (0xceaa:16)
	sub a, c
	ld (xiz + 7), a
	ld a, l
	extz wa
	ld de, wa
	sla de, 2
	ld a, (0xcedf:16)
	dec 1, a
	extz wa
	muls wa, 0x30
	lda xbc, (Harmony_Offsets4_B:24)
	exts xwa
	add xwa, xbc
	lda	xwa, (xwa+de)
	ld c, (xwa + 2)
	ld a, (0xceaa:16)
	sub a, c
	ld (xiz + 9), a
	ld a, l
	extz wa
	ld de, wa
	sla de, 2
	ld a, (0xcedf:16)
	dec 1, a
	extz wa
	muls wa, 0x30
	lda xbc, (Harmony_Offsets4_B:24)
	exts xwa
	add xwa, xbc
	lda	xwa, (xwa+de)
	ld c, (xwa + 3)
	ld a, (0xceaa:16)
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
	ld e, (Harmony_FixedIntervals:24)
	ld c, (0xceaa:16)
	sub c, e
	ld (xwa + 5), c
	ld e, (SoundFX_Handler_9_Data_2:24)
	ld c, (0xceaa:16)
	sub c, e
	ld (xwa + 7), c
	ldw (xwa), 0x2
	ld hl, 2:i3
	ret

SoundFX_Handler_10:
	ld e, (SoundFX_Handler_10_Data:24)
	ld c, (0xceaa:16)
	sub c, e
	ld (xwa + 5), c
	ld e, (SoundFX_Handler_10_Data_2:24)
	ld c, (0xceaa:16)
	sub c, e
	ld (xwa + 7), c
	ldw (xwa), 0x2
	ld hl, 2:i3
	ret

SoundFX_Handler_11:
	ld e, (SoundFX_Handler_11_Data:24)
	ld c, (0xceaa:16)
	sub c, e
	ld (xwa + 5), c
	ld e, (SoundFX_Handler_11_Data_2:24)
	ld c, (0xceaa:16)
	sub c, e
	ld (xwa + 7), c
	ldw (xwa), 0x2
	ld hl, 2:i3
	ret

VoiceBank_MapNoteToOffset:
	ld l, 0xff:opc
	cp a, 7:i3
	jr z, MapNoteToOffset_Compare4
	cp a, 4:i3
	jr z, MapNoteToOffset_Compare
	cp a, 0:i3
	jr nz, MapNoteToOffset_ClearByte3
	jr Audio_NullRet1

MapNoteToOffset_Compare:
	cp c, 1:i3
	jr nc, MapNoteToOffset_ClearByte
	cp c, 4:i3
	jr ugt, MapNoteToOffset_Compare2

MapNoteToOffset_ClearByte:
	ld l, 0x0:opc
	jr Audio_NullRet1

MapNoteToOffset_Compare2:
	cp c, 5:i3
	jr nc, MapNoteToOffset_SetByte
	cp c, 0x8
	jr ugt, MapNoteToOffset_Compare3

MapNoteToOffset_SetByte:
	ld l, 0x4:opc
	jr Audio_NullRet1

MapNoteToOffset_Compare3:
	cp c, 0x9
	jr nc, MapNoteToOffset_SetByte2
	cp c, 0xc
	ret ugt

MapNoteToOffset_SetByte2:
	ld l, 0x8:opc
	jr Audio_NullRet1

MapNoteToOffset_Compare4:
	cp c, 1:i3
	jr nc, MapNoteToOffset_ClearByte2
	cp c, 3:i3
	jr ugt, MapNoteToOffset_Compare5

MapNoteToOffset_ClearByte2:
	ld l, 0x0:opc
	jr Audio_NullRet1

MapNoteToOffset_Compare5:
	cp c, 4:i3
	jr nc, MapNoteToOffset_SetByte3
	cp c, 6:i3
	jr ugt, MapNoteToOffset_Compare6

MapNoteToOffset_SetByte3:
	ld l, 0x3:opc
	jr Audio_NullRet1

MapNoteToOffset_Compare6:
	cp c, 7:i3
	jr nc, MapNoteToOffset_SetByte4
	cp c, 0x9
	jr ugt, MapNoteToOffset_Compare7

MapNoteToOffset_SetByte4:
	ld l, 0x6:opc
	jr Audio_NullRet1

MapNoteToOffset_Compare7:
	cp c, 0xa
	jr nc, MapNoteToOffset_SetByte5
	cp c, 0xc
	ret ugt

MapNoteToOffset_SetByte5:
	ld l, 0x9:opc
	jr Audio_NullRet1

MapNoteToOffset_ClearByte3:
	ld l, 0x0:opc

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
	cp (0xceb5:16), 0
	jr z, UpdateNoteState_CheckDRAM
	dec 1, (0xceb5:16)
	jr z, Voice_CheckAndUpdateMode

UpdateNoteState_CheckDRAM:
	cp (0xceb4:16), 0
	jr z, UpdateNoteState_CheckDRAM2
	dec 1, (0xceb4:16)
	jr z, Voice_CheckAndUpdateMode

UpdateNoteState_CheckDRAM2:
	cp (0xceb3:16), 0
	jr z, Voice_ProcessControllers_Return
	dec 1, (0xceb3:16)
	jr z, Voice_CheckAndUpdateMode

Voice_CheckAndUpdateMode:
	ld de, (0xc596:16)
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
	ld de, (0xc596:16)
	and de, 0x2000
	jr nz, PlayMode_StoreResult
	cpw (0xcf01:24), 2
	jr z, ProcessControllers_R_LoadDRAM
	cpw (0xcf01:24), 3
	jr z, ProcessControllers_R_LoadDRAM
	jr PlayMode_ClearBit6

ProcessControllers_R_LoadDRAM:
	ld de, (0xc598:16)
	and de, 0x20
	jr z, PlayMode_UpdateAndReturn
	or (0xcede:24), 64
	jr PlayMode_UpdateAndReturn

PlayMode_ClearBit6:
	and (0xcede:24), 191
	jr PlayMode_UpdateAndReturn

PlayMode_UpdateAndReturn:
	calr Voice_DispatchByTimingState
	calr VoiceSlot_CheckAndApply_LoadReg
	and (0xcede:24), 191
	ld hl, (0x00cf01:24)
	andw (0xcf01:24), 255
	cp h, 0xff
	jr z, PlayMode_SetZeroResult
	ldw hl, 0xff
	jr PlayMode_StoreResult

PlayMode_SetZeroResult:
	ld h, 0x0:opc
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
	cpw (0xcf01:24), 2
	jr z, PlayMode_CheckModes23
	cpw (0xcf01:24), 3
	jr z, PlayMode_CheckModes23
	jr PlayMode_ClearBit6_Alt

PlayMode_CheckModes23:
	ld de, (0xc598:16)
	and de, 0x20
	jr z, PlayMode_CheckSlotAndReturn
	or (0xcede:24), 64
	jr PlayMode_CheckSlotAndReturn

PlayMode_ClearBit6_Alt:
	and (0xcede:24), 191
	jr PlayMode_CheckSlotAndReturn

PlayMode_CheckSlotAndReturn:
	calr Voice_CheckAndResetSlotState
	and (0xcede:24), 191
	ld hl, (0x00cf01:24)
	andw (0xcf01:24), 255
	cp h, 0xff
	jr z, PlayMode_SetZero_Alt
	ldw hl, 0xff
	jr PlayMode_Epilogue

PlayMode_SetZero_Alt:
	ld h, 0x0:opc
	jr PlayMode_Epilogue

PlayMode_Epilogue:
	pop xde
	pop xiz
	pop xix
	ret

Voice_DispatchByTimingState:
	ld bc, (0x00ceff:24)
	cp bc, 0:i3
	jr z, VoiceTiming_ResetSlot
	bit 0, (0xcede:24)
	jr nz, VoiceTiming_ResetSlot
	jr VoiceTiming_CheckBit6

VoiceTiming_ResetSlot:
	calr Voice_CheckAndResetSlotState
	jr Voice_AdjustTiming_Return

VoiceTiming_CheckBit6:
	bit 6, (0xcede:24)
	jr z, VoiceTiming_CheckBit7
	calr Voice_CheckAndResetSlotState
	jr Voice_AdjustTiming_Return

VoiceTiming_CheckBit7:
	bit 7, (0xcede:24)
	jr z, VoiceTiming_CompareThreshold
	calr Voice_UpdateVelocity_Entry
	jr Voice_AdjustTiming_Return

VoiceTiming_CompareThreshold:
	cp bc, (0xcf17:16)
	jr c, VoiceTiming_EqualThreshold
	calr Voice_UpdateVelocity_Entry
	jr Voice_AdjustTiming_Return

VoiceTiming_EqualThreshold:
	cp bc, (0xcf17:16)
	jr ugt, VoiceTiming_BelowThreshold
	calr Voice_SetDecayTimer
	jr Voice_AdjustTiming_Return

VoiceTiming_BelowThreshold:
	calr Voice_MatchVoicePairs

Voice_AdjustTiming_Return:
	ret

Voice_UpdateVelocity_Entry:
	bit 6, (0xcede:24)
	jr nz, Voice_CheckAndUpdateSlot
	cpw (0xcf17:16), 0
	jr z, VelocityUpdate_CheckNoThreshold
	bit 7, (0xcede:24)
	jr z, VelocityUpdate_CheckBit4
	ld de, (0xc596:16)
	and de, 0x2
	jr nz, Voice_CheckAndUpdateSlot

VelocityUpdate_CheckBit4:
	bit 4, (0xcede:24)
	jr z, Voice_CheckAndUpdateSlot
	jr VelocityUpdate_SetTimerValue

VelocityUpdate_CheckNoThreshold:
	ld de, (0xc596:16)
	and de, 0x2
	jr z, Voice_CheckAndUpdateSlot
	bit 4, (0xcede:24)
	jr z, Voice_CheckAndUpdateSlot
	cp (0x00cee0:24), 0x00
	jr z, Voice_CheckAndUpdateSlot

VelocityUpdate_SetTimerValue:
	cp (0xceb3:16), 0
	jr nz, VelocityUpdate_Return
	ld (0xceb3:16), 5
	jr VelocityUpdate_Return

Voice_CheckAndUpdateSlot:
	calr Voice_CheckAndResetSlotState

VelocityUpdate_Return:
	ret

Voice_SetDecayTimer:
	ld de, (0xc596:16)
	and de, 0x2
	jr z, DecayTimer_SetShort
	cp bc, 2:i3
	jr ule, DecayTimer_SetLong

DecayTimer_SetShort:
	ld (0xceb4:16), 6
	jr DecayTimer_Return

DecayTimer_SetLong:
	ld (0xceb4:16), 22

DecayTimer_Return:
	ret

Voice_MatchVoicePairs:
	ld xiy, 0xceff
	ld bc, (xiy + 0:8)
	ld xix, 0xcf17

VoicePair_OuterLoop:
	ld de, (xix + 0:8)
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
	djnz16 bc, VoicePair_OuterLoop

VoicePair_Return:
	ret

Voice_CheckAndResetSlotState:
	ld bc, (0x00ceff:24)
	ld (0xceb3:16), 0
	ld (0xceb4:16), 0
	cp bc, 0:i3
	jr z, CheckAndResetSlotSta_Block
	calr NullRet2_TestBit24
	jr Voice_NullRet2

CheckAndResetSlotSta_Block:
	or (0xcede:24), 128
	ld (0x00cee4:24), 0x00
	ld e, (0xfc5f:16)
	and e, 0x30
	jr nz, Voice_NullRet2
	ld e, (0xfc60:16)
	and e, 0x30
	jr nz, Voice_NullRet2
	ld de, (0xc598:16)
	and de, 0x2
	jr nz, CheckAndResetSlotSta_LoadDRAM
	bit 6, (0xcede:24)
	jr nz, CheckAndResetSlotSta_Block2

CheckAndResetSlotSta_LoadDRAM:
	ld de, (0xc598:16)
	and de, 0x2
	jr nz, CheckAndResetSlotSta_LoadDRAM2
	bit 6, (0xcede:24)
	jr nz, CheckAndResetSlotSta_Block2

CheckAndResetSlotSta_LoadDRAM2:
	ld de, (0xc596:16)
	and de, 0x10
	jr nz, Voice_NullRet2

CheckAndResetSlotSta_Block2:
	calr NullRet2_Block
	jr Voice_NullRet2

Voice_NullRet2:
	ret

NullRet2_Block:
	ldw (0x00ceff:24), 0x0000
	ld (0x00cee5:24), 0x00
	ld (0x00cef1:24), 0x00
	ld (0x00cee0:24), 0x00
	ld (0x00cedf:24), 0x00
	or (0xcede:24), 128
	and (0xcede:24), 249
	ld (0x00cee1:24), 0x00
	ld (0x00cee4:24), 0x00
	calr VoiceSlot_Epilogue_Block2
	ret

NullRet2_Data:
	nop
	incf
	push_f
	ld	d, 0:opc
	.byte 0xdc
	cp	xix, xwa

NullRet2_TestBit24:
	bit 6, (0xcede:24)
	jr nz, EffectState_Dispatch
	ld de, (0xc596:16)
	and de, 0x1
	jr nz, NullRet2_Block2
	ld de, (0xc596:16)
	and de, 0x2
	jr nz, EffectState_Dispatch
	ld de, (0xc598:16)
	and de, 0x2
	jr nz, EffectState_Dispatch
	ld de, (0xc596:16)
	and de, 0x4
	jr nz, EffectState_Dispatch_Block
	jr EffectState_Dispatch

NullRet2_Block2:
	calr EffectState_Dispatch_Block3
	jr EffectState_Dispatch_Block2

EffectState_Dispatch:
	calr PitchCalc_Return_Block
	jr EffectState_Dispatch_Block2

EffectState_Dispatch_Block:
	calr VoiceSlot_LoadResult_Block3

EffectState_Dispatch_Block2:
	calr VoiceSlot_Epilogue_Block2
	ret

EffectState_Dispatch_Block3:
	ld (0x00cee5:24), 0x04
	ld de, (0x00ceff:24)
	calr VoiceSlot_StoreParams_Block2
	calr VoiceSlot_StoreParams_LoadReg3
	jr VoiceSlot_StoreParams
VoiceSlot_StoreParams:

VoiceSlot_StoreParams_Block:
	ld (0x00cedf:24), a
	ld (0x00cee0:24), w
	ld (0x00cee1:24), 0x00
	and (0xcede:24), 249
	ret

VoiceSlot_StoreParams_Block2:
	ldw (0x00cf2f:24), 0x0000
	ld xiy, 0xceff
	ld xix, 0xcf8f
	ld hl, de
	dec 1, hl
	sla hl, 1
	add iy, hl
	cp de, 0:i3
	jr nz, VoiceSlot_StoreParams_OrBits
	ld (0x00cee5:24), 0x00
	jr VoiceSlot_StoreParams_Return

VoiceSlot_StoreParams_OrBits:
	xor wa, wa
	ldfr_werp WA, 0x30
	xor b, b
	xor h, h

VoiceSlot_StoreParams_LoadReg:
	ld l, (xiy + 5)
	ld xiz, VoiceSlot_StoreParams_LoadReg_Data
	ld	c, (xiz+l)
	ldto_werp WA, 0x30
	ld xiz, VoiceSlot_CheckAndApply_Data2
	and_sriw_rm WA, 0x03, 0xf8, 0xe4
	jr nz, VoiceSlot_StoreParams_Decrement
	or_sriw_rm WA, 0x03, 0xf8, 0xe4
	ldfr_werp WA, 0x30
	ld (xix), l
	inc 1, ix
	inc 1, b
	cp b, (0xcee5:24)
	jr nc, VoiceSlot_StoreParams_Block3

VoiceSlot_StoreParams_Decrement:
	dec 1, iy
	dec 1, iy
	dec 1, de
	cp de, 0:i3
	jr nz, VoiceSlot_StoreParams_LoadReg

VoiceSlot_StoreParams_Block3:
	ld (0x00cee5:24), b
	ld c, b
	xor b, b
	ld xix, 0xcee6
	ld xiy, 0xcf8f
	add iy, bc
	dec 1, iy

VoiceSlot_StoreParams_LoadReg2:
	ld a, (xiy)
	ld (xix), a
	dec 1, iy
	inc 1, ix
	djnz16 bc, VoiceSlot_StoreParams_LoadReg2

VoiceSlot_StoreParams_Return:
	ret

VoiceSlot_StoreParams_LoadReg3:
	ld xiy, 0xceff
	ld bc, (0x00ceff:24)
	xor a, a
	xor h, h
	cp bc, 0:i3
	jr z, VoiceSlot_StoreParams_LoadReg5

VoiceSlot_StoreParams_LoadReg4:
	ld l, (xiy + 5)
	cp l, (0xcee6:24)
	jr z, VoiceSlot_StoreParams_Increment
	ld xiz, VoiceSlot_StoreParams_LoadReg_Data
	ld	l, (xiz+hl)
	dec 1, hl
	ld xiz, VoiceSlot_StoreParams_Data
	or	a, (xiz+hl)

VoiceSlot_StoreParams_Increment:
	inc 2, iy
	djnz16 bc, VoiceSlot_StoreParams_LoadReg4

VoiceSlot_StoreParams_LoadReg5:
	ld l, a
	ld xiz, VoiceSlot_StoreParams_LoadReg5_Code
	ld	a, (xiz+hl)
	ld l, (0x00cee6:24)
	ld xiz, VoiceSlot_StoreParams_LoadReg_Data
	ld	w, (xiz+hl)
	and (0xcede:24), 127
	and (0xcede:24), 239
	ret

VoiceSlot_StoreParams_Data:
	normal
	push	sr
	normal
	push	sr
	normal
	normal
	push	sr
	normal
	push	sr
	normal
	push	sr
	normal
VoiceSlot_StoreParams_LoadReg5_Code:
	normal
	push	sr
	halt
	.byte 0x06

Voice_ComputeNoteBitPosition:
	ld l, c
	xor h, h
	dec 1, hl
	ld xiz, 0xcee6
	ld	w, (xiz+hl)
	ld c, b
	xor b, b
	dec 1, bc
	ld iy, hl
	dec 1, iy
	xor de, de

ComputeNoteBitPositi_Prologue:
	pushw bc
	ld xiz, 0xcee6
	ld	l, (xiz+iy)
	sub l, w
	ld xiz, VoiceSlot_StoreParams_LoadReg_Data
	ld	a, (xiz+hl)
	dec 1, a
	ld c, 0xb:opc
	sub c, a
	ldfr_berp A, 0x3c
	ld a, c
	scf
	stcf_a_16 de
	ldto_berp A, 0x3c
	popw bc
	dec 1, iy
	djnz16 bc, ComputeNoteBitPositi_Prologue
	or de, 0x800
	ret

ComputeNoteBitPositi_Data:
	dec	1, bc
	xor	de, de
	xor	hl, hl
	xor	iy, iy
	xor	wa, wa
	pushw	bc
	ld	xiz, 0xcee6
	ld	l, (xiz)
	ld	w, (xiz+iy)
	sub l, h
	xor h, h
	ld	xiz, VoiceSlot_StoreParams_LoadReg_Data
	ld	c, (xiz+hl)
	dec 1, c
	ldfr_berp a, 60
	ld a, c
	scf
	.byte 0xda
	pushw	ix
	ldto_berp	a, 60
	cp	a, c
	jr	nc, Voice_ComputeNoteBitPosition_Skip
	ld	a, c
Voice_ComputeNoteBitPosition_Skip:
	popw	bc
	inc	1, iy
	djnz16	bc, -52
	or	de, 1
	ld	c, 11:opc
	sub	c, a
	ex8	a, c
	slaa	de	; sla A,DE
	ex8	a, c
	ret

ComputeNoteBitPositi_StoreDRAM:
	ld (0xcefd:16), de
	ld c, (0x00cee5:24)
	xor b, b

ComputeNoteBitPositi_Block:
	ldfr_werp DE, 0x3c
	and de, 0x600
	ldto_werp DE, 0x3c
	jr nz, ComputeNoteBitPositi_TestBit9
	ld hl, de
	and hl, 0x1ff
	ld xiz, NoteMask9_ClassTable
	ld	a, (xiz+hl)
	cp a, 0:i3
	jr nz, Voice_PitchCalcStep

ComputeNoteBitPositi_TestBit9:
	bit 9, de
	jr z, Voice_DecrementCounter
	cp c, (0xcee5:24)
	jr nz, Voice_DecrementCounter
	ld hl, de
	and hl, 0x1ff
	ld xiz, NoteMask9_ClassTable
	ld	a, (xiz+hl)
	cp a, 1:i3
	jr nz, ComputeNoteBitPositi_Compare
	ld a, 0x28:opc
	jr Voice_PitchCalcStep

ComputeNoteBitPositi_Compare:
	cp a, 5:i3
	jr nz, Voice_DecrementCounter
	ld a, 0x29:opc
	jr Voice_PitchCalcStep

Voice_DecrementCounter:
	dec 1, c
	cp c, 0:i3
	jr z, PitchCalcStep_ClearByte
	jr PitchCalc_FindBitPosition
PitchCalc_FindBitPosition:

PitchCalc_FindBitPosition_Increment:
	inc 1, b
	sla de, 1
	bit 12, de
	jr nz, PitchCalc_FindBitPosition_OrBits

PitchCalc_FindBitPosition_TestBit11:
	bit 11, de
	jr z, PitchCalc_FindBitPosition_Increment
	jr ComputeNoteBitPositi_Block

PitchCalc_FindBitPosition_OrBits:
	or de, 0x1
	jr PitchCalc_FindBitPosition_TestBit11

Voice_PitchCalcStep:
	ld l, (0x00cee5:24)
	dec 1, l
	xor h, h
	ld xiz, 0xcee6
	ld	l, (xiz+hl)
	add l, b
	ld xiz, VoiceSlot_StoreParams_LoadReg_Data
	ld	w, (xiz+hl)
	jr PitchCalc_Return

PitchCalcStep_ClearByte:
	ld a, 0x0:opc
	ld w, 0x0:opc
	jr PitchCalc_Return
PitchCalc_Return:

	ret

PitchCalc_Return_Block:
	ld (0x00cee5:24), 0x04
	ld de, (0x00ceff:24)
	calr VoiceSlot_StoreParams_Block2
	cp (0x00cee5:24), 0x02
	jr ugt, PitchCalc_Return_Block2
	jr PitchCalc_Return_Block3

PitchCalc_Return_Block2:
	calr Voice_UpdateNoteBitmap
	cp w, 0:i3
	jr nz, VoiceSlot_CompareAndUpdate_Compare
	dec 1, (0xcee5:24)
	calr Voice_UpdateNoteBitmap
	inc 1, (0xcee5:24)
	jr VoiceSlot_CompareAndUpdate_Compare

PitchCalc_Return_Block3:
	calr VoiceSlot_LoadResult_Block
	jr VoiceSlot_CompareAndUpdate
VoiceSlot_CompareAndUpdate:

VoiceSlot_CompareAndUpdate_Compare:
	cp w, 0:i3
	jr nz, VoiceSlot_CompareAndUpdate_TestBit24
	ld a, (0x00cee2:24)
	ld w, (0x00cee3:24)
	jr VoiceSlot_CompareAndUpdate_Block2

VoiceSlot_CompareAndUpdate_TestBit24:
	bit 6, (0xcede:24)
	jr nz, VoiceSlot_CompareAndUpdate_Block
	ldfr_werp DE, 0x3e
	ld de, (0xc596:16)
	and de, 0x8
	ldto_werp DE, 0x3e
	jr nz, VoiceSlot_CompareAndUpdate_Block4
	jr VoiceSlot_CompareAndUpdate_Block3

VoiceSlot_CompareAndUpdate_Block:
	ld l, (0x00cee5:24)
	xor h, h
	dec 1, hl
	ld xiz, 0xcee6
	ld d, (xiz)
	ld	e, (xiz+hl)
	sub d, e
	cp d, 0xc
	jr nc, VoiceSlot_CompareAndUpdate_Block4
	jr VoiceSlot_CompareAndUpdate_Block3

VoiceSlot_CompareAndUpdate_Block2:
	calr NoteDisplay_ClearAndSetUpdate
	jr VoiceSlot_CompareAndUpdate_Return

VoiceSlot_CompareAndUpdate_Block3:
	calr NoteDisplay_InitState
	jr VoiceSlot_CompareAndUpdate_Return

VoiceSlot_CompareAndUpdate_Block4:
	calr NoteDisplay_LookupBitmap

VoiceSlot_CompareAndUpdate_Return:
	ret

Voice_UpdateNoteBitmap:
	push xix
	push xiz
	ld c, (0x00cee5:24)
	ld b, c
	calr Voice_ComputeNoteBitPosition
	ld xiy, NoteMask9_ClassTable
	calr ComputeNoteBitPositi_StoreDRAM
	cp a, 0:i3
	jr z, UpdateNoteBitmap_ClearByte
	or (0xcede:24), 16
	and (0xcede:24), 127
	jr VoiceSlot_LoadResult_LoadReg

UpdateNoteBitmap_ClearByte:
	ld a, 0x0:opc
	ld w, 0x0:opc
	jr VoiceSlot_LoadResult
VoiceSlot_LoadResult:

VoiceSlot_LoadResult_LoadReg:
	ld l, a
	extz hl
	pop xiz
	pop xix
	ret
VoiceSlot_LoadResult_Data:
	ld	c, (0xcee5:24)
	ld	b, c
	calr	Voice_ComputeNoteBitPosition
	ld	xiy, NoteMask9_ClassTable
	calr	ComputeNoteBitPositi_StoreDRAM
	cp	a, 0:i3
	jr	z, Voice_UpdateNoteBitmap_Skip
	or	(0xcede:24), 16
	and	(0xcede:24), 127
	and	(0xcede:24), 249
	jr	Voice_UpdateNoteBitmap_Return
Voice_UpdateNoteBitmap_Skip:
	ld	a, 0:opc
	ld	w, 0:opc
	jr	Voice_UpdateNoteBitmap_Return
Voice_UpdateNoteBitmap_Return:
	ret

VoiceSlot_LoadResult_Block:
	cp (0x00cee0:24), 0x00
	jr z, VoiceSlot_LoadResult_SetByte
	ld a, 0x0:opc
	ld w, 0x0:opc
	jr VoiceSlot_LoadResult_Block2

VoiceSlot_LoadResult_SetByte:
	ld a, 0x1:opc
	ld l, (0x00cee6:24)
	xor h, h
	ld xiz, VoiceSlot_StoreParams_LoadReg_Data
	ld	w, (xiz+hl)

VoiceSlot_LoadResult_Block2:
	and (0xcede:24), 127
	or (0xcede:24), 16
	ret

VoiceSlot_LoadResult_Data2:
	ld	a, 1:opc
	ld	l, (0xcee5:24)
	xor	h, h
	dec	1, hl
	ld	xiz, 0xcee6
	ld	l, (xiz+hl)
	ld	xiz, VoiceSlot_StoreParams_LoadReg_Data
	ld	w, (xiz+hl)
	or	(52958:24), 16
	and	(52958:24), 127
	ret

VoiceSlot_LoadResult_Block3:
	calr Audio_NullRet2_Prologue
	ld wa, (0x00cf2f:24)
	add a, (0xcee5:24)
	cp a, 2:i3
	jr ugt, VoiceSlot_LoadResult_TestBit24
	jrl Audio_NullRet2

VoiceSlot_LoadResult_TestBit24:
	bit 1, (0xcede:24)
	jr nz, VoiceSlot_LoadResult_Block9
	calr Voice_LookupNoteAndComputePitch
	cp w, 0:i3
	jr nz, VoiceSlot_LoadResult_Compare
	ld l, (0x00cee5:24)
	xor h, h
	dec 1, hl
	extz hl
	ld xiz, 0xcee6
	add xiz, xhl
	ld c, (xiz)
	ldfr_lerp XIZ, 0x30
	ldfr_berp C, 0x34
	ld a, (0x00cee5:24)
	dec 1, a
	cp a, 2:i3
	jr ugt, VoiceSlot_LoadResult_Block4
	jr Audio_NullRet2

VoiceSlot_LoadResult_Block4:
	dec 1, (0xcee5:24)
	calr Voice_LookupNoteAndComputePitch
	inc 1, (0xcee5:24)
	ldto_berp C, 0x34
	ldto_lerp XIZ, 0x30
	ld (xiz), c

VoiceSlot_LoadResult_Compare:
	cp w, 0:i3
	jr nz, VoiceSlot_LoadResult_Block5
	ld a, (0x00cee2:24)
	ld w, (0x00cee3:24)
	jr VoiceSlot_LoadResult_Block6

VoiceSlot_LoadResult_Block5:
	ldfr_werp DE, 0x3e
	ld de, (0xc596:16)
	and de, 0x8
	ldto_werp DE, 0x3e
	jr nz, VoiceSlot_LoadResult_Block8
	jr VoiceSlot_LoadResult_Block7

VoiceSlot_LoadResult_Block6:
	calr NoteDisplay_ClearAndSetUpdate
	jr Audio_NullRet2

VoiceSlot_LoadResult_Block7:
	calr NoteDisplay_InitState
	jr Audio_NullRet2

VoiceSlot_LoadResult_Block8:
	calr NoteDisplay_LookupBitmap
	jr Audio_NullRet2

VoiceSlot_LoadResult_Block9:
	calr NoteDisplay_AlternateLookup
	cp a, 0:i3
	jr z, VoiceSlot_LoadResult_Block10
	calr VoiceSlot_Epilogue_Block
	jr Audio_NullRet2

VoiceSlot_LoadResult_Block10:
	calr Voice_LookupNoteAndComputePitch
	cp a, 0:i3
	jr z, VoiceSlot_LoadResult_Block11
	calr NoteDisplay_LookupBitmap
	jr Audio_NullRet2

VoiceSlot_LoadResult_Block11:
	calr NoteDisplay_ClearAndSetUpdate
	jr Audio_NullRet2

Audio_NullRet2:
	ret

Audio_NullRet2_Prologue:
	push xiz
	ld xiy, 0xceff
	ld hl, (0x00ceff:24)
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
	ld de, (0x00ceff:24)
	cp de, 4:i3
	jr c, Voice_ProcessSlotEntry
	ldw (0x00cf2f:24), 0x0001
	ld xiz, xiy
	add xiz, xhl
	ld wa, (xiz + 4)
	ld (0x00cf33:24), wa
	or (0xcede:24), 2
	ld (0x00cee5:24), 0x07
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
	ld de, (0x00ceff:24)
	cp de, 5:i3
	jr c, Voice_ProcessSlotEntry
	ldw (0x00cf2f:24), 0x0001
	ld xiz, xiy
	add xiz, xhl
	ld wa, (xiz + 4)
	ld (0x00cf33:24), wa
	or (0xcede:24), 2
	ld (0x00cee5:24), 0x07
	dec 1, de
	dec 1, de
	calr VoiceSlot_CheckPitchIntervals
	jr Audio_PopIzRet

Voice_ProcessSlotEntry:
	ld de, (0x00ceff:24)
	cp de, 3:i3
	jr c, ProcessSlotEntry_Block2
	ldfr_werp DE, 0x3e
	ld de, (0xc596:16)
	and de, 0x200
	ldto_werp DE, 0x3e
	jr z, ProcessSlotEntry_Block
	ldw (0x00cf2f:24), 0x0000
	and (0xcede:24), 253
	ld (0x00cee5:24), 0x07
	ld de, (0x00ceff:24)
	calr VoiceSlot_CheckPitchIntervals
	calr NoteBuffer_CompactEn_Block2
	jr Audio_PopIzRet

ProcessSlotEntry_Block:
	ldw (0x00cf2f:24), 0x0000
	and (0xcede:24), 253
	ld (0x00cee1:24), 0x00
	ld (0x00cee5:24), 0x07
	ld de, (0x00ceff:24)
	calr VoiceSlot_CheckPitchIntervals
	calr NoteBuffer_CompactEn_Block2
	jr Audio_PopIzRet

ProcessSlotEntry_Block2:
	ld (0x00cee5:24), 0x00

Audio_PopIzRet:
	pop xiz
	ret

VoiceSlot_CheckPitchIntervals:
	push xiz
	cp de, 0:i3
	jr nz, VoiceSlot_CheckPitch_LoadReg
	ld (0x00cee5:24), 0x00
	jrl NoteBuffer_CompactEn_Epilogue

VoiceSlot_CheckPitch_LoadReg:
	ld xiy, 0xceff
	xor xhl, xhl
	ld bc, 1:i3
	cp de, 3:i3
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
	djnz16 bc, VoiceSlot_CheckPitch_LoadReg2
	xor hl, hl

VoiceSlot_CheckPitch_Compare:
	cp hl, 0:i3
	jr nz, VoiceSlot_CheckPitch_Compare2
	and (0xcede:24), 223
	jr NoteBuffer_CompactEntries

VoiceSlot_CheckPitch_Compare2:
	cp hl, 2:i3
	jr nz, VoiceSlot_CheckPitch_Compare3
	ld (0xceb5:16), 2
	or (0xcede:24), 32
	jr NoteBuffer_CompactEntries

VoiceSlot_CheckPitch_Compare3:
	cp hl, 4:i3
	jr nz, VoiceSlot_CheckPitch_OrBits2
	bit 5, (0xcede:24)
	jr z, VoiceSlot_CheckPitch_OrBits
	cp (0xceb5:16), 0
	jr z, NoteBuffer_CompactEntries

VoiceSlot_CheckPitch_OrBits:
	xor hl, hl
	and (0xcede:24), 223
	jr NoteBuffer_CompactEntries

VoiceSlot_CheckPitch_OrBits2:
	xor hl, hl
	and (0xcede:24), 223
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
	cp b, (0xcee5:24)
	jr nc, NoteBuffer_CompactEn_Block
	dec 1, iy
	dec 1, iy
	dec 1, de
	cp de, 0:i3
	jr nz, NoteBuffer_CompactEn_LoadReg

NoteBuffer_CompactEn_Block:
	ld (0x00cee5:24), b
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
	djnz16 bc, NoteBuffer_CompactEn_LoadReg2

NoteBuffer_CompactEn_Epilogue:
	pop xiz
	ret

NoteBuffer_CompactEn_Data:
	ld	w, (xiy+5)
	sub	w, a
	cp	w, 12
	jr	ugt, VoiceSlot_CheckPitchIntervals_Entry
	and	(52958:24), 247
	jr	VoiceSlot_CheckPitchIntervals_Return
VoiceSlot_CheckPitchIntervals_Entry:
	or	(52958:24), 8
	jr	VoiceSlot_CheckPitchIntervals_Return
VoiceSlot_CheckPitchIntervals_Return:
	ret

NoteBuffer_CompactEn_Block2:
	cp (0x00cee4:24), 0x00
	jr z, NoteBuffer_NullRet
	cpw (0xcf2f:24), 0
	jr nz, NoteBuffer_NullRet
	ld wa, (0x00cf33:24)
	ld bc, (0x00ceff:24)
	ld xiy, 0xceff

NoteBuffer_CompactEn_Compare:
	cp wa, (xiy + 4)
	jr nz, NoteBuffer_CompactEn_Increment
	jr NoteBuffer_NullRet

NoteBuffer_CompactEn_Increment:
	inc 2, iy
	djnz16 bc, NoteBuffer_CompactEn_Compare
	ld l, (0x00cee5:24)
	xor h, h
	dec 1, hl
	ld xiz, 0xcee6
	ld	a, (xiz+hl)
	ld w, (0x00cf34:24)
	sub a, w
	cp a, 7:i3
	jr c, NoteBuffer_NullRet
	ldw (0x00cf2f:24), 0x0001
	or (0xcede:24), 2

NoteBuffer_NullRet:
	ret

Voice_LookupNoteAndComputePitch:
	ld c, (0x00cee5:24)
	ld b, c
	pushw bc
	calr Voice_ComputeNoteBitPosition
	ld hl, de
	and xhl, 0x7ff
	sla hl, 1
	ld xiz, ChordRecog_IntervalMaskTable
	add xiz, xhl
	ld a, (xiz)
	ld w, (xiz + 1)
	bit 7, w
	jr z, LookupNoteAndCompute_Block
	and w, 0x7f
	jrl NoteDisplay_FoundEntry

LookupNoteAndCompute_Block:
	cpw (0xcf2f:24), 0
	jr nz, NoteDisplay_SetBounds
	ld c, (0x00cee5:24)
	ld b, 0x3:opc

LookupNoteAndCompute_Prologue:
	pushw bc
	calr Voice_ComputeNoteBitPosition
	ld hl, de
	and hl, 0x7ff
	sla hl, 1
	ld xiz, ChordRecog_IntervalMaskTable
	add xiz, xhl
	ld a, (xiz)
	ld w, (xiz + 1)
	and w, 0x7f
	popw bc
	cp a, 0:i3
	jr nz, NoteDisplay_LookupEntry
	cp b, (0xcee5:24)
	jr nc, NoteDisplay_SetBounds
	inc 1, b
	jr LookupNoteAndCompute_Prologue

NoteDisplay_LookupEntry:
	ld l, (0x00cee5:24)
	xor h, h
	dec 1, hl
	ld xiz, 0xcee6
	ld	l, (xiz+hl)
	add l, w
	ld xiz, VoiceSlot_StoreParams_LoadReg_Data
	ld	w, (xiz+hl)
	dec 1, w
	ld l, (0x00cee5:24)
	ld xiz, 0xcee6
	ld	(xiz+hl), w
	inc 1, (0xcee5:24)

NoteDisplay_SetBounds:
	ld l, (0x00cee5:24)
	ld h, l

NoteDisplay_ScanLoop:
	ld c, l
	ld b, h
	push xhl
	calr Voice_ComputeNoteBitPosition
	ld hl, de
	and hl, 0x7ff
	sla hl, 1
	ld xiz, ChordRecog_IntervalMaskTable
	add xiz, xhl
	ld a, (xiz)
	ld w, (xiz + 1)
	and w, 0x7f
	pop xhl
	cp a, 0:i3
	jr nz, NoteDisplay_FoundEntry
	dec 1, h
	cp h, 4:i3
	jr c, NoteDisplay_NotFound
	jr NoteDisplay_ScanLoop

NoteDisplay_FoundEntry:
	ld l, (0x00cee5:24)
	dec 1, l
	xor h, h
	ld xiz, 0xcee6
	ld	l, (xiz+hl)
	add l, w
	ld xiz, VoiceSlot_StoreParams_LoadReg_Data
	ld	w, (xiz+hl)
	jr NoteDisplay_StoreBoundsReturn

NoteDisplay_NotFound:
	ld a, 0x0:opc
	ld w, 0x0:opc
	jr NoteDisplay_StoreBoundsReturn

NoteDisplay_StoreBoundsReturn:
	popw bc
	ld (0x00cee5:24), c
	ret

NoteDisplay_AlternateLookup:
	ld l, (0x00cee5:24)
	xor h, h
	ld a, (0x00cf34:24)
	ld xiz, 0xcee6
	ld	(xiz+hl), a
	ld bc, hl
	inc 1, bc
	ld b, c
	calr Voice_ComputeNoteBitPosition
	ld hl, de
	and hl, 0x7ff
	sla hl, 1
	ld xiz, ChordRecog_IntervalMaskTable
	ld	a, (xiz+hl)
	cp a, 0:i3
	jr z, Voice_ZeroInitConverge
	ld xiz, ChordRecog_IntervalMaskTable
	add xiz, xhl
	ld w, (xiz + 1)
	and w, 0x7f
	bit 5, w
	jr nz, Voice_ZeroInitConverge
	cp w, 0:i3
	jr nz, Voice_ZeroInitConverge
	ld l, (0x00cf34:24)
	add l, w
	xor h, h
	ld xiz, VoiceSlot_StoreParams_LoadReg_Data
	ld	w, (xiz+hl)
	jr NoteDisplay_AltReturn

Voice_ZeroInitConverge:
	ld a, 0x0:opc
	ld w, 0x0:opc
	jr NoteDisplay_AltReturn

NoteDisplay_AltReturn:
	ret

NoteDisplay_ClearAndSetUpdate:
	push xix
	push xiz
	cp (0x00cee1:24), 0x00
	jr nz, NoteDisplay_ClearReturn
	and (0xcede:24), 249
	or (0xcede:24), 16
	and (0xcede:24), 254

NoteDisplay_ClearReturn:
	pop xiz
	pop xix
	ret

NoteDisplay_InitState:
	push xix
	push xiz
	ld (0x00cedf:24), a
	ld (0x00cee0:24), w
	ld (0x00cee1:24), 0x00
	ld (0x00cee4:24), 0x00
	and (0xcede:24), 253
	and (0xcede:24), 251
	and (0xcede:24), 254
	and (0xcede:24), 127
	or (0xcede:24), 16
	pop xiz
	pop xix
	ret

NoteDisplay_LookupBitmap:
	push xix
	push xiz
	ld (0x00cedf:24), a
	ld (0x00cee0:24), w
	xor hl, hl
	cpw (0xcf2f:24), 0
	jr z, NoteDisplay_LookupFromCurrent
	ld l, (0x00cf34:24)
	jr NoteDisplay_LookupFromTable

NoteDisplay_LookupFromCurrent:
	ld l, (0x00cee5:24)
	dec 1, hl
	ld xiz, 0xcee6
	ld	l, (xiz+hl)

NoteDisplay_LookupFromTable:
	ld xiz, VoiceSlot_StoreParams_LoadReg_Data
	ld	a, (xiz+hl)
	cp (0xcee0:24), a
	jr z, NoteDisplay_SameNote
	cpw (0xcf2f:24), 0
	jr z, NoteDisplay_StoreNoCurrent
	ld (0x00cee1:24), a
	ld (0x00cee4:24), a
	jr NoteDisplay_SetUpdateFlags

NoteDisplay_StoreNoCurrent:
	ld (0x00cee1:24), a
	ld (0x00cee4:24), 0x00

NoteDisplay_SetUpdateFlags:
	and (0xcede:24), 251
	or (0xcede:24), 2
	and (0xcede:24), 254
	and (0xcede:24), 127
	or (0xcede:24), 16
	jr VoiceSlot_Epilogue_Epilogue

NoteDisplay_SameNote:
	cpw (0xcf2f:24), 0
	jr z, NoteDisplay_ClearBoth
	ld (0x00cee1:24), 0x00
	ld (0x00cee4:24), w
	jr NoteDisplay_SetOverlayFlags

NoteDisplay_ClearBoth:
	ld (0x00cee1:24), 0x00
	ld (0x00cee4:24), 0x00

NoteDisplay_SetOverlayFlags:
	or (0xcede:24), 4
	and (0xcede:24), 253
	and (0xcede:24), 254
	and (0xcede:24), 127
	or (0xcede:24), 16
	jr VoiceSlot_Epilogue
VoiceSlot_Epilogue:

VoiceSlot_Epilogue_Epilogue:
	pop xiz
	pop xix
	ret

VoiceSlot_Epilogue_Block:
	ld (0x00cedf:24), a
	ld (0x00cee0:24), w
	ld (0x00cee1:24), 0x00
	ld (0x00cee4:24), w
	or (0xcede:24), 4
	and (0xcede:24), 253
	and (0xcede:24), 127
	or (0xcede:24), 16
	ret

VoiceSlot_Epilogue_Block2:
	calr Voice_InitPartAllocState
	calr VoiceSlot_IterateAlloc_TestBit24
	orw (0xcf01:24), 0xff00
	ld a, (0x00cedf:24)
	ld (0x00cee2:24), a
	ld a, (0x00cee0:24)
	ld (0x00cee3:24), a
	ret

Voice_InitPartAllocState:
	push xix
	push xiz
	cp (0x00cedf:24), 0x00
	jr nz, InitPartAllocState_Block
	calr InitPartAllocState_Block4
	jr InitPartAllocState_Epilogue

InitPartAllocState_Block:
	calr InitPartAllocState_TestBit242
	calr InitPartAllocState_OrBits
	ldfr_werp DE, 0x3e
	ld de, (0xc598:16)
	and de, 0x2
	ldto_werp DE, 0x3e
	jr z, InitPartAllocState_TestBit24
	bit 4, (0xcede:24)
	jr z, InitPartAllocState_Block2
	calr VoiceSlot_SetPitchParams_TestBit24
	jr InitPartAllocState_TestBit24

InitPartAllocState_Block2:
	calr VoiceSlot_IterateAlloc_Block2

InitPartAllocState_TestBit24:
	bit 4, (0xcede:24)
	jr z, InitPartAllocState_Block3
	calr VoiceSlot_IterateAlloc_Block3
	jr InitPartAllocState_Epilogue

InitPartAllocState_Block3:
	calr VoiceSlot_IterateAlloc_LoadReg

InitPartAllocState_Epilogue:
	pop xiz
	pop xix
	ret

InitPartAllocState_Block4:
	ld (0x00cee5:24), 0x00
	ldw (0x00cf5f:24), 0x0000
	ldw (0x00cf77:24), 0x0000
	ld (0x00cef1:24), 0x00
	ret

InitPartAllocState_TestBit242:
	bit 4, (0xcede:24)
	jrl nz, InitPartAllocState_Return
	ld l, (0x00cedf:24)
	xor h, h
	dec 1, hl
	ld xiz, InitPartAllocState_TestBit242_Data
	ld	a, (xiz+hl)
	ld (0x00cee5:24), a
	ld xiz, InitPartAllocState_TestBit242_Data_2
	sla hl, 2
	ld	bc, (xiz+hl)
	inc 2, hl
	ld	de, (xiz+hl)
	ld l, (0x00cee0:24)
	dec 1, l
	add c, l
	add b, l
	add e, l
	add d, l
	xor h, h
	ld l, c
	sla hl, 1
	ld xiz, ChordTables_PitchMask
	ld	wa, (xiz+hl)
	ld l, b
	sla hl, 1
	or	wa, (xiz+hl)
	ld l, e
	sla hl, 1
	or	wa, (xiz+hl)
	ld l, d
	sla hl, 1
	or	wa, (xiz+hl)
	ld xiy, 0xcee6
	ld c, (0x00cee5:24)
	xor b, b
	add iy, bc
	dec 1, iy
	ld e, 0x36:opc

InitPartAllocState_Increment:
	inc 1, e
	srl wa, 1
	jr nc, InitPartAllocState_Increment
	ld (xiy), e
	dec 1, iy
	djnz16 bc, InitPartAllocState_Increment

InitPartAllocState_Return:
	ret

InitPartAllocState_OrBits:
	xor hl, hl
	bit 1, (0xcede:24)
	jr z, InitPartAllocState_Block5
	ld l, (0x00cee1:24)
	jr VoiceSlot_SetPitchParams_LoadReg

InitPartAllocState_Block5:
	ld l, (0x00cee0:24)
	jr VoiceSlot_SetPitchParams
VoiceSlot_SetPitchParams:

VoiceSlot_SetPitchParams_LoadReg:
	ld xiz, VoiceSlot_CheckAndApply_Data
	ld	w, (xiz+hl)
	ld a, 0x40:opc
	ldw (0x00cf77:24), 0x0001
	ld (0x00cf7b:24), wa
	ret

VoiceSlot_SetPitchParams_TestBit24:
	bit 1, (0xcede:24)
	jr z, VoiceSlot_IterateAlloc_Block
	ld l, (0x00cedf:24)
	xor h, h
	dec 1, hl
	ld xiz, InitPartAllocState_TestBit242_Data
	ld	c, (xiz+hl)
	ld (0x00cef1:24), c
	inc 1, (0xcef1:24)
	xor b, b
	ld xiy, InitPartAllocState_TestBit242_Data_2
	ld xix, 0xcef2
	sla hl, 2
	ld d, (0x00cee1:24)
	dec 1, d
	add d, 0x30
	ld e, (0x00cee0:24)
	dec 1, e
	add e, 0x30
	ld a, d
	sub a, 0x18
	ld (xix), a
	inc 1, ix

VoiceSlot_SetPitchParams_LoadFromStack:
	ld	a, (xiy+hl)
	add a, e
	cp a, 0x3c
	jr c, VoiceSlot_SetPitchParams_Compare
	sub a, 0xc

VoiceSlot_SetPitchParams_Compare:
	cp a, d
	jr z, VoiceSlot_SetPitchParams_Block
	ld (xix), a
	inc 1, ix
	jr VoiceSlot_IterateAlloc_NextIter

VoiceSlot_SetPitchParams_Block:
	dec 1, (0xcef1:24)
	jr VoiceSlot_IterateAlloc
VoiceSlot_IterateAlloc:

VoiceSlot_IterateAlloc_NextIter:
	inc 1, hl
	djnz16 bc, VoiceSlot_SetPitchParams_LoadFromStack
	jr VoiceSlot_IterateAlloc_Return

VoiceSlot_IterateAlloc_Block:
	ld l, (0x00cedf:24)
	xor h, h
	dec 1, hl
	ld xiz, InitPartAllocState_TestBit242_Data
	ld	c, (xiz+hl)
	ld (0x00cef1:24), c
	xor b, b
	ld xiy, InitPartAllocState_TestBit242_Data_2
	ld xix, 0xcef2
	sla hl, 2
	ld e, (0x00cee0:24)
	dec 1, e
	add e, 0x30

VoiceSlot_IterateAlloc_LoadFromStack:
	ld	a, (xiy+hl)
	add a, e
	ld (xix), a
	inc 1, hl
	inc 1, ix
	djnz16 bc, VoiceSlot_IterateAlloc_LoadFromStack

VoiceSlot_IterateAlloc_Return:
	ret

VoiceSlot_IterateAlloc_Block2:
	ld l, (0x00cedf:24)
	xor h, h
	dec 1, hl
	ld xiz, InitPartAllocState_TestBit242_Data
	ld	a, (xiz+hl)
	ld (0x00cef1:24), a
	ld xiz, InitPartAllocState_TestBit242_Data_2
	sla hl, 2
	ld	bc, (xiz+hl)
	inc 2, hl
	ld	de, (xiz+hl)
	ld xiz, VoiceSlot_CheckAndApply_Data
	ld l, (0x00cee0:24)
	ld	l, (xiz+l)
	add l, 0xc
	add c, l
	add b, l
	add e, l
	add d, l
	ld (0x00cef2:24), c
	ld (0x00cef3:24), b
	ld (0x00cef4:24), e
	ld (0x00cef5:24), d
	ret

VoiceSlot_IterateAlloc_Block3:
	ld bc, (0x00ceff:24)
	ld (0x00cf5f:24), bc
	cp bc, 0:i3
	jr z, VoiceSlot_IterateAlloc_Return2
	ld xiy, 0xcf03
	ld xix, 0xcf63

VoiceSlot_IterateAlloc_Block4:
	ld WA, (xiy+)
	cp w, 0x6b
	jr ugt, VoiceSlot_IterateAlloc_SetByte
	add w, 0xc

VoiceSlot_IterateAlloc_SetByte:
	ld a, 0x40:opc
	ld (xix+), WA
	djnz16 bc, VoiceSlot_IterateAlloc_Block4

VoiceSlot_IterateAlloc_Return2:
	ret

VoiceSlot_IterateAlloc_LoadReg:
	ld xiy, 0xcee6
	ld xix, 0xcf5f
	ld c, (0x00cee5:24)
	xor b, b
	ld (xix + 0:8), bc

VoiceSlot_IterateAlloc_LoadReg2:
	ld w, (xiy)
	ld a, 0x40:opc
	ld (xix + 4), wa
	inc 1, iy
	inc 1, ix
	inc 1, ix
	djnz16 bc, VoiceSlot_IterateAlloc_LoadReg2
	ret

VoiceSlot_IterateAlloc_TestBit24:
	bit 0, (0xcede:24)
	jr nz, VoiceSlot_IterateAlloc_Block6
	ld a, (0x00cedf:24)
	ld w, (0x00cee0:24)
	ld l, (0x00cee1:24)
	cp a, (0x8d42:16)
	jr nz, VoiceSlot_IterateAlloc_StoreDRAM
	cp w, (0x8d40:16)
	jr nz, VoiceSlot_IterateAlloc_StoreDRAM
	cp l, (0x8d44:16)
	jr z, VoiceSlot_CheckAndApply_Return

VoiceSlot_IterateAlloc_StoreDRAM:
	ld (0x8d42:16), a
	ld (0x8d40:16), w
	bit 1, (0xcede:24)
	jr nz, VoiceSlot_IterateAlloc_StoreDRAM2
	ld (0x8d44:16), 0
	jr VoiceSlot_IterateAlloc_Block5

VoiceSlot_IterateAlloc_StoreDRAM2:
	ld (0x8d44:16), l

VoiceSlot_IterateAlloc_Block5:
	jr VoiceSlot_CheckAndApply_DoCheckDis

VoiceSlot_IterateAlloc_Block6:
	ld (0x8d42:16), 0
	ld (0x8d40:16), 0
	ld (0x8d44:16), 0
	jr VoiceSlot_CheckAndApply
VoiceSlot_CheckAndApply:

VoiceSlot_CheckAndApply_DoCheckDis:
	call BitMapOut_CheckDiskAndApply

VoiceSlot_CheckAndApply_Return:
	ret

; CHORD TABLES used by the fingered-chord code below, 441 bytes, five parts.
; Offsets are from this label; the readers load the part addresses, which are
; named in shared/positional_labels.s as VoiceSlot_StoreParams_LoadReg_Data,
; _0x91, _0xBA and _0x189 (v10/v9 addresses; the chord ROOT is RAM 0xCEE0,
; the chord TYPE is RAM 0xCEDF, both counted from 1):
;   +0x000   1 B   0x00, never read (index 0 is not a root)
;   +0x001  12 B   ROOT -> BASS NOTE: note 0x24..0x2C, 0x21..0x23 (C2..G#2,
;                  A1..B1) for roots 1..12.  Reader VoiceSlot_SetPitchParams_LoadReg
;                  (0xFEA171): W = table[(0xCEE0), or (0xCEE1) when bit 1 of
;                  0xCEDE is set], A = 0x40, (0xCF7B) = WA, (0xCF77) = 1.
;   +0x00D 132 B   NOTE -> PITCH CLASS: 11 rows of 1..12, so entry n = n mod 12
;                  + 1 for notes 0-131.  Readers: every `ld xiz, _Data_0xD` /
;                  `ld_rr8b ... (xiz + note)` in VoiceSlot_StoreParams_*,
;                  Voice_ComputeNoteBitPosition and the routines after it
;                  (12 load sites between 0xFE9753 and 0xFE9F81).
;   +0x091  41 B   CHORD TYPE -> NOTE COUNT (3 or 4).  Reader
;                  InitPartAllocState_TestBit242 (0xFEA0C7): A = table[type-1]
;                  -> (0xCEE5); also loaded at 0xFEA19A, 0xFEA20A, 0xFEA24C.
;   +0x0BA 164 B   CHORD TYPE -> 4 INTERVALS in semitones above the root,
;                  41 x 4 (e.g. 0,4,7,0 / 0,4,7,10 / 0,3,7,0).  Same readers:
;                  BC, DE = record[type-1] (`sla hl, 2`), each + (root - 1);
;                  loaded at 0xFEA0E7, 0xFEA1B0, 0xFEA21B, 0xFEA25B.
;   +0x15E  43 B   the bytes 0x00..0x2A in order: see ChordTables_Run15E.
;   +0x189  48 B   PITCH INDEX -> BIT MASK (ChordTables_PitchMask): 24 x .hword, entry i = 1 << ((i + 5)
;                  mod 12).  Reader InitPartAllocState_TestBit242 ORs the masks
;                  of the four (interval + root - 1) indices into WA, then
;                  writes one note per set bit, bit b -> note 0x37 + b (G3..F#4),
;                  into 0xCEE6.. -- so a C chord (root 1) sounds from middle C.
; Count 41 for the two chord-type parts: the note-count part fills exactly
; 0x91..0xB9 and the interval part 0xBA..0x15D before the 0x00..0x2A run;
; neither reader bounds the type.
VoiceSlot_CheckAndApply_Data:
	.byte 0x00
	; index row
	.byte 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x21, 0x22, 0x23
	; 11 rows of 0x01..0x0c
VoiceSlot_StoreParams_LoadReg_Data:
	.byte 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c
	.byte 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c
	.byte 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c
	.byte 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c
	.byte 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c
	.byte 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c
	.byte 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c
	.byte 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c
	.byte 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c
	.byte 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c
	.byte 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c
	; selector bytes
InitPartAllocState_TestBit242_Data:
	.byte 0x03, 0x04, 0x04, 0x03, 0x03, 0x04, 0x04, 0x04
	.byte 0x04, 0x04, 0x04, 0x04, 0x03, 0x04, 0x04, 0x04
	.byte 0x04, 0x04, 0x04, 0x03, 0x04, 0x04, 0x03, 0x04
	.byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
	.byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
	.byte 0x04
	; 4-byte records
InitPartAllocState_TestBit242_Data_2:
	.byte 0x00, 0x04, 0x07, 0x00
	.byte 0x00, 0x04, 0x07, 0x0a
	.byte 0x00, 0x04, 0x07, 0x0b
	.byte 0x00, 0x04, 0x08, 0x00
	.byte 0x00, 0x03, 0x07, 0x00
	.byte 0x00, 0x03, 0x07, 0x0a
	.byte 0x00, 0x03, 0x06, 0x09
	.byte 0x00, 0x03, 0x06, 0x0a
	.byte 0x00, 0x03, 0x07, 0x0b
	.byte 0x00, 0x05, 0x07, 0x0a
	.byte 0x00, 0x04, 0x07, 0x09
	.byte 0x00, 0x04, 0x08, 0x0a
	.byte 0x00, 0x04, 0x06, 0x00
	.byte 0x00, 0x04, 0x06, 0x0a
	.byte 0x04, 0x07, 0x0a, 0x02
	.byte 0x04, 0x07, 0x0a, 0x01
	.byte 0x04, 0x07, 0x0b, 0x02
	.byte 0x04, 0x07, 0x09, 0x02
	.byte 0x00, 0x03, 0x07, 0x09
	.byte 0x00, 0x03, 0x06, 0x00
	.byte 0x03, 0x07, 0x0a, 0x02
	.byte 0x03, 0x09, 0x02, 0x07
	.byte 0x00, 0x05, 0x07, 0x00
	.byte 0x04, 0x07, 0x0a, 0x03
	.byte 0x00, 0x04, 0x06, 0x0b
	.byte 0x00, 0x04, 0x08, 0x0b
	.byte 0x00, 0x03, 0x06, 0x0b
	.byte 0x00, 0x04, 0x09, 0x0a
	.byte 0x00, 0x04, 0x08, 0x0a
	.byte 0x00, 0x04, 0x09, 0x0a
	.byte 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x04, 0x07, 0x02
	.byte 0x00, 0x03, 0x07, 0x02
; The chord tables' +0x15E part: the 43 bytes 0x00..0x2A in order, between
; the interval records and the pitch-mask words.  No reader found: every
; 24-bit address inside the chord tables was searched in the v10 dump; only
; +0x00, +0x0D, +0x91, +0xBA and +0x189 are loaded (plus one stray +0xD5
; inside misframed bytes at 0xF541B2).  Base-plus-index reads were not
; excluded: the chord-type readers do not bound the type, so a type > 41
; would read here.
ChordTables_Run15E:
	.byte 0x00, 0x01, 0x02, 0x03
	.byte 0x04, 0x05, 0x06, 0x07
	.byte 0x08, 0x09, 0x0a, 0x0b
	.byte 0x0c, 0x0d, 0x0e, 0x0f
	.byte 0x10, 0x11, 0x12, 0x13
	.byte 0x14, 0x15, 0x16, 0x17
	.byte 0x18, 0x19, 0x1a, 0x1b
	.byte 0x1c, 0x1d, 0x1e, 0x1f
	.byte 0x20, 0x21, 0x22, 0x23
	.byte 0x24, 0x25, 0x26, 0x27
	.byte 0x28, 0x29, 0x2a
; The chord tables' +0x189 part (ChordTables_PitchMask in
; shared/positional_labels.s): 24 x .hword, entry i = 1 << ((i + 5) mod 12).
; Reader InitPartAllocState_TestBit242 (v10/v9 0xFEA111: `ld xiz, <this> /
; ld wa, (xiz + hl)` then three `or wa, (xiz + hl)`, hl = 2 x (interval + root - 1)).
ChordTables_PitchMask:
	; 16-bit masks, powers of two
	.hword 0x0020, 0x0040, 0x0080, 0x0100, 0x0200, 0x0400, 0x0800, 0x0001
	.hword 0x0002, 0x0004, 0x0008, 0x0010, 0x0020, 0x0040, 0x0080, 0x0100
	.hword 0x0200, 0x0400, 0x0800, 0x0001, 0x0002, 0x0004, 0x0008, 0x0010

VoiceSlot_CheckAndApply_LoadReg:
	ld xiy, 0xceff
	ld xix, 0xcf17
	ld bc, (xiy + 0:8)
	inc 1, bc
	ldirw
	ret
; 16 x .short 1 << i.  Reader VoiceSlot_StoreParams_LoadReg (v10/v9 0xFE974F):
;   ld c, (xiz + l)  with XIZ = the note -> pitch-class+1 part of the chord
;                    tables (_Data_0xD), then  ld xiz, <this table> /
;   and wa, (xiz + c) / jr nz, <already seen> / or wa, (xiz + c)
; i.e. a WORD read at BYTE offset 1..12, misaligned for odd offsets; the 12
; words it can read (0x0200, 0x0002, 0x0400, 0x0004, ... 0x4000, 0x0040) are
; still 12 distinct single bits, so WA works as a set of pitch classes seen
; while collecting the held notes (no duplicates stored).
VoiceSlot_CheckAndApply_Data2:
	.short	0x0001, 0x0002, 0x0004, 0x0008, 0x0010, 0x0020, 0x0040, 0x0080
	.short	0x0100, 0x0200, 0x0400, 0x0800, 0x1000, 0x2000, 0x4000, 0x8000
; Evaluate a chord from the ALTERNATE note buffer at RAM 0xCEB6 without
; disturbing the current one: saves 0xCEDE-0xCEE4 to 0xCEC0 and the 10-byte
; buffer at 0xCEE5 to 0xCECA, copies 0xCEB6.. into 0xCEE5.., and when it holds
; more than 2 notes runs Voice_UpdateNoteBitmap and NoteDisplay_InitState /
; NoteDisplay_LookupBitmap on it; the result (0xCEDF, 0xCEE0, 0xCEE1, 0xCEDE)
; is written to 0xCEB6..0xCEB9 and the saved state restored.
; No caller found: no branch lands here and no 24-bit pointer to this address
; occurs in the dump.  Its entry is simply the byte after the mask table.
Chord_EvalAltNoteBuffer:
	push	xwa
	push	xbc
	push	xhl
	push	xde
	push	xix
	push	xiy
	push	xiz
; index row
	ld	a, (0xcede:24)
	stb_d8	(0xcec0), a
	ld	a, (0xcedf:24)
	stb_d8	(0xcec1), a
	ld	a, (0xcee0:24)
	stb_d8	(0xcec2), a
	ld	a, (0xcee1:24)
	stb_d8	(0xcec3), a
	ld	a, (0xcee2:24)
	stb_d8	(0xcec4), a
	ld	a, (0xcee3:24)
	stb_d8	(0xcec5), a
	ld	a, (0xcee4:24)
	stb_d8	(0xcec6), a
	ld	xiy, 0xcee5
	ld	xix, 0xceca
	ldw	bc, 10
	ldir85
	ld	xiy, 0xceb6
	ld	xix, 0xcee5
	ldw	bc, 10
	ldir85
	cp	(0xcee5:24), 2
	jrl	ule, VoiceSlot_CheckAndApply_LoadReg_Skip3
	calr	Voice_UpdateNoteBitmap
	cp	w, 0:i3
	jr	nz, VoiceSlot_CheckAndApply_LoadReg_Entry
	dec	1, (0xcee5:24)
	calr	Voice_UpdateNoteBitmap
	inc	1, (0xcee5:24)
	jr	VoiceSlot_CheckAndApply_LoadReg_Entry
	cp	w, 0:i3
	jr	nz, VoiceSlot_CheckAndApply_LoadReg_Entry
	ld	a, (0xcee2:24)
	ld	w, (0xcee3:24)
VoiceSlot_CheckAndApply_LoadReg_Entry:
	bit	6, (0xcede:24)
	jr	nz, VoiceSlot_CheckAndApply_LoadReg_Skip
	.byte	0xd7, 0x3e, 0x9a	; ld QHL3,DE
	ldw_d16	de, (0xc596)
	and	de, 8
	.byte	0xd7, 0x3e, 0x8a	; ld DE,QHL3
	jr	nz, VoiceSlot_CheckAndApply_LoadReg_Skip2
	jr	VoiceSlot_CheckAndApply_LoadReg_Join
VoiceSlot_CheckAndApply_LoadReg_Skip:
	ld	l, (0xcee5:24)
	xor	h, h
	dec	1, hl
	ld	xiz, 0xcee6
	ld	d, (xiz)
	ld	e, (xiz+hl)
	sub	d, e
	cp	d, 12
	jr	nc, VoiceSlot_CheckAndApply_LoadReg_Skip2
VoiceSlot_CheckAndApply_LoadReg_Join:
	calr	NoteDisplay_InitState
	jr	VoiceSlot_CheckAndApply_LoadReg_Join2
VoiceSlot_CheckAndApply_LoadReg_Skip2:
	calr	NoteDisplay_LookupBitmap
VoiceSlot_CheckAndApply_LoadReg_Join2:
	ld	a, (0xcedf:24)
	stb_d8	(0xceb6), a
	ld	a, (0xcee0:24)
	stb_d8	(0xceb7), a
	ld	a, (0xcee1:24)
	stb_d8	(0xceb8), a
	ld	a, (0xcede:24)
	stb_d8	(0xceb9), a
	jr	VoiceSlot_CheckAndApply_LoadReg_Join3
VoiceSlot_CheckAndApply_LoadReg_Skip3:
	ld	(0xceb6:16), 0
	ld	(0xceb7:16), 0
VoiceSlot_CheckAndApply_LoadReg_Join3:
	ldb_d8	a, (0xcec0)
	ld	(0xcede:24), a
	ldb_d8	a, (0xcec1)
	ld	(0xcedf:24), a
	ldb_d8	a, (0xcec2)
	ld	(0xcee0:24), a
	ldb_d8	a, (0xcec3)
	ld	(0xcee1:24), a
	ldb_d8	a, (0xcec4)
	ld	(0xcee2:24), a
	ldb_d8	a, (0xcec5)
	ld	(0xcee3:24), a
	ldb_d8	a, (0xcec6)
	ld	(0xcee4:24), a
	ld	xiy, 0xceca
	ld	xix, 0xcee5
	ldw	bc, 10
	ldir85
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xhl
	pop	xbc
	pop	xwa
	ret

VoiceSlot_CheckAndApply_Prologue:
	push xiz
	ld xiz, xsp
	push xix
	push xde
	ld xiy, (xiz + 8)
	xor xix, xix
	ld bc, (xiy + 0:8)
	sla bc, 1
	ld xiz, xiy
	add xiz, 0x4
	ld xiy, 0:i3

VoiceSlot_CheckAndApply_Compare:
	cp iy, bc
	jr ge, VoiceSlot_CheckAndApply_Epilogue
	ld	wa, (xiz+iy)
	ld ix, iy

VoiceSlot_CheckAndApply_Increment:
	inc 2, ix
	cp ix, bc
	jr ge, VoiceSlot_CheckAndApply_Block
	ldfr_lerp XIZ, 0x38
	extz ix
	add xiz, xix
	exw_erp IZ, 0x38
	cpb_sri_mr W, 0x39, 0x01, 0x00
	jr le, VoiceSlot_CheckAndApply_Increment
	ex	(xiz+ix), wa
	jr VoiceSlot_CheckAndApply_Increment

VoiceSlot_CheckAndApply_Block:
	ld	(xiz+iy), wa
	inc 2, iy
	jr VoiceSlot_CheckAndApply_Compare

VoiceSlot_CheckAndApply_Epilogue:
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
	ld bc, 5:i3
	ldirw
	ldi85
	cp e, 3:i3
	jrl z, NoteDisplay_StoreAnd_LoadReg3
	cp e, 2:i3
	jr z, NoteDisplay_StoreAnd_LoadReg2
	cp e, 1:i3
	jr z, NoteDisplay_StoreAnd_LoadReg
	cp e, 0:i3
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
	ld bc, 5:i3
	ldirw
	ldi85
	cp (0xcee5:16), 0
	jr nz, NoteDisplay_StoreAnd_LoadDRAM
	call NoteDisplay_ClearAndSetUpdate
	ld (0xcedf:16), 0
	ld (0xcee0:16), 0
	ld (0xcee1:16), 0
	jr NoteDisplay_StoreAnd_Block

NoteDisplay_StoreAnd_LoadDRAM:
	ld a, (0xcee5:16)
	dec 1, a
	extz wa
	lda xbc, (0xcee6:16)
	extz xwa
	add xwa, xbc
	ld c, (0xcee6:16)
	sub c, (xwa)
	ld a, c
	cp a, 0xc
	jr ule, NoteDisplay_StoreAnd_DoUpdateNo
	call Voice_UpdateNoteBitmap
	cp hl, 0:i3
	jr nz, NoteDisplay_StoreAnd_DoLookupBi
	dec 1, (0xcee5:16)
	call Voice_UpdateNoteBitmap
	inc 1, (0xcee5:16)

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
	ld bc, 5:i3
	ldirw
	ldi85
	pop xiz
	lda xsp, (xsp + 20)
	ret

SndParam_Init:
	dec 6, xsp
	ld (xsp + 0:8), 0x5
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
	ld	(xsp+0:8), (0xc080)
	ld	(xsp+0x1), (0xc07d)
	ld	(xsp+0x2), (0xc07e)
	ld	(xsp+0x3), (0xc07f)
	ld	a, (xsp+0x1)
	extz	wa
	cp	wa, 0:i3
	jrl	mi, SndParam_ProcessEntry_Epilogue
	cp	wa, 12
	jrl	gt, SndParam_ProcessEntry_Epilogue
	add	wa, wa
	lda	xix, (KeyEvent_SwitchOffsets:24)
	ld	wa, (xix+wa)
	lda	xix, (UIState_ProcessKeyEvent_Code:24)
	jp	t, (xix+wa)
UIState_ProcessKeyEvent_Code:
	ld	a, (xsp+0x3)
	and	a, 255
	jrl	z, SndParam_ProcessEntry_Epilogue
	ld	a, (xsp+0:8)
	extz	wa
	calr	MIDI_WriteChannelData_Block
	cp	l, 0:i3
	jrl	nz, SndParam_ProcessEntry_Epilogue
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	and	a, 255
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
	jrl	SndParam_ProcessEntry_Epilogue
	ld	a, (xsp+0x3)
	.set	SndParam_ProcessEntry, . + 1	; mid-instruction: only a .long in ui_widgets/widget_dispatch.s (bytes 7f a8 fe 00 inside a byte table) names this address
	res	7, a
	cp	a, 0:i3
	jrl	z, SndParam_ProcessEntry_Epilogue
	ld	a, (xsp+0:8)
	extz	wa
	calr	MIDI_WriteChannelData_Block
	cp	l, 0:i3
	jrl	nz, SndParam_ProcessEntry_Epilogue
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
	jrl	SndParam_ProcessEntry_Epilogue
	ld	a, (xsp+0x3)
	and	a, 255
	jrl	z, SndParam_ProcessEntry_Epilogue
	lda	xwa, (xsp)
	ldw	bc, 127
	calr	UIState_ProcessKeyEvent_Helper
	jrl	SndParam_ProcessEntry_Epilogue
	ld	a, (xsp+0x3)
	and	a, 7
	jr	z, SndParam_ProcessEntry_Entry
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	and	a, 7
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
SndParam_ProcessEntry_Entry:
	bitm	3, (xsp+0x3)
	jr	z, UIState_ProcessKeyEvent_Skip
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	and	a, 8
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
UIState_ProcessKeyEvent_Skip:
	bitm	6, (xsp+0x3)
	jrl	z, SndParam_ProcessEntry_Epilogue
	ld	a, (xsp+0:8)
	extz	wa
	calr	MIDI_WriteChannelData_Block
	cp	l, 0:i3
	jrl	nz, SndParam_ProcessEntry_Epilogue
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	and	a, 64
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
	jrl	SndParam_ProcessEntry_Epilogue
	ld	a, (xsp+0x3)
	res	7, a
	cp	a, 0:i3
	jrl	z, SndParam_ProcessEntry_Epilogue
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
	jrl	SndParam_ProcessEntry_Epilogue
	ld	a, (xsp+0x3)
	res	7, a
	cp	a, 0:i3
	jrl	z, SndParam_ProcessEntry_Epilogue
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
	jrl	SndParam_ProcessEntry_Epilogue
	ld	a, (xsp+0x3)
	res	7, a
	cp	a, 0:i3
	jrl	z, SndParam_ProcessEntry_Epilogue
	ld	a, (xsp+0:8)
	extz	wa
	calr	MIDI_WriteChannelData_Block
	cp	l, 0:i3
	jrl	nz, SndParam_ProcessEntry_Epilogue
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
	jrl	SndParam_ProcessEntry_Epilogue
	ld	a, (xsp+0x3)
	res	7, a
	cp	a, 0:i3
	jrl	z, SndParam_ProcessEntry_Epilogue
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
	jr	SndParam_ProcessEntry_Epilogue
	ld	a, (xsp+0x3)
	and	a, 255
	jr	z, SndParam_ProcessEntry_Epilogue
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	and	a, 255
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
	jr	SndParam_ProcessEntry_Epilogue
	ld	a, (xsp+0x3)
	res	7, a
	cp	a, 0:i3
	jr	z, SndParam_ProcessEntry_Epilogue
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
	jr	SndParam_ProcessEntry_Epilogue
	bitm	3, (xsp+0x3)
	jr	z, UIState_ProcessKeyEvent_Skip2
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	and	a, 8
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
UIState_ProcessKeyEvent_Skip2:
	bitm	5, (xsp+0x3)
	jr	z, SndParam_ProcessEntry_Epilogue
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	and	a, 32
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
SndParam_ProcessEntry_Epilogue:
	inc	4, xsp
	ret
HdaeRom_Entry:
	dec	4, xsp
	ld	(xsp+0:8), (0xc080)
	ld	(xsp+0x1), (0xc07d)
	ld	(xsp+0x2), (0xc07e)
	ld	(xsp+0x3), (0xc07f)
	ld	a, (xsp+0x1)
	cp	a, 1:i3
	jr	nz, HdaeRom_Entry_Epilogue
	bitm	7, (xsp+0x3)
	jr	z, HdaeRom_Entry_Skip
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	and	a, 128
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
HdaeRom_Entry_Skip:
	bitm	6, (xsp+0x3)
	jr	z, HdaeRom_Entry_Skip2
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	and	a, 64
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
HdaeRom_Entry_Skip2:
	bitm	5, (xsp+0x3)
	jr	z, HdaeRom_Entry_Epilogue
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	and	a, 32
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
HdaeRom_Entry_Epilogue:
	inc	4, xsp
	ret
HdaeRom_ProcessBlock:
	dec	4, xsp
	ld	(xsp+0:8), (0xc080)
	ld	(xsp+0x1), (0xc07d)
	ld	(xsp+0x2), (0xc07e)
	ld	(xsp+0x3), (0xc07f)
	ld	a, (xsp+0x1)
	cp	a, 24
	jr	ugt, HdaeRom_ProcessBlock_Epilogue
	cp	a, 0:i3
	jr	c, HdaeRom_ProcessBlock_Epilogue
	ld	a, (xsp+0x3)
	and	a, 255
	jr	z, HdaeRom_ProcessBlock_Epilogue
	ld	(xsp+0x1), 0
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	and	a, 255
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
HdaeRom_ProcessBlock_Epilogue:
	inc	4, xsp
	ret
HdaeRom_ReadParam:
	ret
	dec	4, xsp
	ld	(xsp+0:8), (0xc080)
	ld	(xsp+0x1), (0xc07d)
	ld	(xsp+0x2), (0xc07e)
	ld	(xsp+0x3), (0xc07f)
	ld	a, (xsp+0x1)
	cp	a, 24
	jr	ugt, HdaeRom_ReadParam_Epilogue
	cp	a, 0:i3
	jr	c, HdaeRom_ReadParam_Epilogue
	ld	a, (xsp+0x3)
	and	a, 255
	jr	z, HdaeRom_ReadParam_Epilogue
	ld	(xsp+0x1), 0
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	and	a, 255
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
HdaeRom_ReadParam_Epilogue:
	inc	4, xsp
	ret
HdaeRom_WriteParam:
	dec	4, xsp
	ld	(xsp+0:8), (0xc080)
	ld	(xsp+0x1), (0xc07d)
	ld	(xsp+0x2), (0xc07e)
	ld	(xsp+0x3), (0xc07f)
	ld	a, (xsp+0x1)
	cp	a, 24
	jr	ugt, HdaeRom_WriteParam_Epilogue
	cp	a, 0:i3
	jr	c, HdaeRom_WriteParam_Epilogue
	ld	a, (xsp+0x3)
	and	a, 255
	jr	z, HdaeRom_WriteParam_Epilogue
	ld	(xsp+0x1), 0
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	and	a, 255
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
HdaeRom_WriteParam_Epilogue:
	inc	4, xsp
	ret
HdaeRom_CheckResult:
	dec	4, xsp
	ld	(xsp+0:8), (0xc080)
	ld	(xsp+0x1), (0xc07d)
	ld	(xsp+0x2), (0xc07e)
	ld	(xsp+0x3), (0xc07f)
	ld	a, (xsp+0x1)
	cp	a, 24
	jr	ugt, HdaeRom_CheckResult_Epilogue
	cp	a, 0:i3
	jr	c, HdaeRom_CheckResult_Epilogue
	ld	a, (xsp+0x3)
	and	a, 255
	jr	z, HdaeRom_CheckResult_Epilogue
	ld	(xsp+0x1), 0
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	and	a, 255
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
HdaeRom_CheckResult_Epilogue:
	inc	4, xsp
	ret
HdaeRom_FinishBlock:
	dec	4, xsp
	ld	(xsp+0:8), (0xc080)
	ld	(xsp+0x1), (0xc07d)
	ld	(xsp+0x2), (0xc07e)
	ld	(xsp+0x3), (0xc07f)
	ld	a, (xsp+0x1)
	cp	a, 24
	jr	ugt, HdaeRom_FinishBlock_Epilogue
	cp	a, 0:i3
	jr	c, HdaeRom_FinishBlock_Epilogue
	ld	a, (xsp+0x3)
	and	a, 255
	jr	z, HdaeRom_FinishBlock_Epilogue
	ld	(xsp+0x1), 0
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	and	a, 255
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
HdaeRom_FinishBlock_Epilogue:
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
	ld	(xsp+0:8), (0xc080)
	ld	(xsp+0x1), (0xc07d)
	ld	(xsp+0x2), (0xc07e)
	ld	(xsp+0x3), (0xc07f)
	ld	a, (xsp+0x1)
	extz	wa
	cp	wa, 0:i3
	jrl	mi, HdaeRom_TableEntry2_Epilogue
	cp	wa, 7:i3
	jrl	gt, HdaeRom_TableEntry2_Epilogue
	add	wa, wa
	lda	xix, (HdaeRomEntry2_SwitchOffsets:24)
	ld	wa, (xix+wa)
	lda	xix, (HdaeRom_TableEntry2_Code:24)
	jp	t, (xix+wa)
HdaeRom_TableEntry2_Code:
	ld	a, (xsp+0x3)
	and	a, 255
	jr	z, HdaeRom_TableEntry2_Epilogue
	lda	xbc, (xsp+0x2)
	ld	a, 0:opc
	bitm	7, (xsp+0x2)
	jr	nz, HdaeRom_TableEntry2_Skip
	ld	a, (xsp+0x2)
	res	7, a
HdaeRom_TableEntry2_Skip:
	ld	(xbc), a
	ld	a, (xsp+0x2)
	extz	wa
	ld	de, wa
	ldw	wa, 23
	ld	bc, 7:i3
	calr	MIDI_SendControlChange
	ld	a, (xsp+0x2)
	extz	wa
	ld	de, wa
	ldw	wa, 24
	ld	bc, 7:i3
	calr	MIDI_SendControlChange
	jr	HdaeRom_TableEntry2_Epilogue
	ld	a, (xsp+0x3)
	res	7, a
	cp	a, 0:i3
	jr	z, HdaeRom_TableEntry2_Epilogue
	ld	a, (xsp+0x2)
	res	7, a
	extz	wa
	ld	de, wa
	ldw	wa, 23
	ldw	bc, 91
	calr	MIDI_SendControlChange
	ld	a, (xsp+0x2)
	res	7, a
	extz	wa
	ld	de, wa
	ldw	wa, 24
	ldw	bc, 91
	calr	MIDI_SendControlChange
HdaeRom_TableEntry2_Epilogue:
	inc	4, xsp
	ret
	ret
HdaeRom_AltEntry:
	ret
UIStateEvt_ProcessHandler:
	dec	4, xsp
	ld	(xsp+0:8), (0xc080)
	ld	(xsp+0x1), (0xc07d)
	ld	(xsp+0x2), (0xc07e)
	ld	(xsp+0x3), (0xc07f)
	ld	a, (xsp+0x1)
	cp	a, 3:i3
	jr	z, UIStateEvt_ProcessHandler_Skip2
	cp	a, 2:i3
	jr	z, UIStateEvt_ProcessHandler_Epilogue
	cp	a, 1:i3
	jr	z, UIStateEvt_ProcessHandler_Skip
	cp	a, 0:i3
	jr	nz, UIStateEvt_ProcessHandler_Epilogue
	ld	a, (xsp+0x3)
	and	a, 255
	jr	z, UIStateEvt_ProcessHandler_Epilogue
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	and	a, 255
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
	jr	UIStateEvt_ProcessHandler_Epilogue
UIStateEvt_ProcessHandler_Skip:
	ld	a, (xsp+0x3)
	and	a, 255
	jr	z, UIStateEvt_ProcessHandler_Epilogue
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	and	a, 255
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
	jr	UIStateEvt_ProcessHandler_Epilogue
UIStateEvt_ProcessHandler_Skip2:
	bitm	0, (xsp+0x3)
	jr	z, UIStateEvt_ProcessHandler_Epilogue
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	and	a, 1
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
UIStateEvt_ProcessHandler_Epilogue:
	inc	4, xsp
	ret
HdaeRom_AltProcessBlock:
	dec	4, xsp
	ld	(xsp+0:8), (0xc080)
	ld	(xsp+0x1), (0xc07d)
	ld	(xsp+0x2), (0xc07e)
	ld	(xsp+0x3), (0xc07f)
	ld	a, (xsp+0x1)
	cp	a, 13
	jr	ugt, HdaeRom_AltProcessBlock_Epilogue
	cp	a, 2:i3
	jr	nc, HdaeRom_AltProcessBlock_Skip3
	cp	a, 0:i3
	jr	z, HdaeRom_AltProcessBlock_Skip
	cp	a, 1:i3
	jr	z, HdaeRom_AltProcessBlock_Skip2
	jr	HdaeRom_AltProcessBlock_Epilogue
HdaeRom_AltProcessBlock_Skip:
	lda	xwa, (xsp)
	ldw	bc, 255
	calr	UIState_ProcessKeyEvent_Helper
	jr	HdaeRom_AltProcessBlock_Epilogue
HdaeRom_AltProcessBlock_Skip2:
	ld	a, (xsp+0x3)
	and	a, 15
	jr	z, HdaeRom_AltProcessBlock_Entry
	lda	xwa, (xsp)
	ldw	bc, 15
	calr	UIState_ProcessKeyEvent_Helper
HdaeRom_AltProcessBlock_Entry:
	bitm	7, (xsp+0x3)
	jr	z, HdaeRom_AltProcessBlock_Epilogue
	lda	xwa, (xsp)
	ldw	bc, 128
	calr	UIState_ProcessKeyEvent_Helper
	jr	HdaeRom_AltProcessBlock_Epilogue
HdaeRom_AltProcessBlock_Skip3:
	lda	xwa, (xsp)
	ldw	bc, 255
	calr	UIState_ProcessKeyEvent_Helper
HdaeRom_AltProcessBlock_Epilogue:
	inc	4, xsp
	ret
	ret
HdaeRom_AltReadParam:
	dec	4, xsp
	ld	(xsp+0:8), (0xc080)
	ld	(xsp+0x1), (0xc07d)
	ld	(xsp+0x2), (0xc07e)
	ld	(xsp+0x3), (0xc07f)
	ld	a, (xsp+0x1)
	cp	a, 4:i3
	jr	z, HdaeRom_AltReadParam_Epilogue
	cp	a, 3:i3
	jr	z, HdaeRom_AltReadParam_Epilogue
	cp	a, 2:i3
	jr	z, HdaeRom_AltReadParam_Skip
	cp	a, 1:i3
	jr	z, HdaeRom_AltReadParam_Epilogue
	cp	a, 0:i3
	jr	nz, HdaeRom_AltReadParam_Epilogue
	bitm	2, (xsp+0x3)
	jr	z, HdaeRom_AltReadParam_Epilogue
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	and	a, 4
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
	jr	HdaeRom_AltReadParam_Epilogue
HdaeRom_AltReadParam_Skip:
	ld	a, (xsp+0x3)
	and	a, 255
	jr	z, HdaeRom_AltReadParam_Epilogue
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	and	a, 255
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
HdaeRom_AltReadParam_Epilogue:
	inc	4, xsp
	ret
HdaeRom_AltCheckResult:
	dec	4, xsp
	ld	(xsp+0:8), (0xc080)
	ld	(xsp+0x1), (0xc07d)
	ld	(xsp+0x2), (0xc07e)
	ld	(xsp+0x3), (0xc07f)
	ld	a, (xsp+0x1)
	cp	a, 4:i3
	jr	z, HdaeRom_AltCheckResult_Skip3
	cp	a, 3:i3
	jr	z, HdaeRom_AltCheckResult_Epilogue
	cp	a, 2:i3
	jr	z, HdaeRom_AltCheckResult_Skip2
	cp	a, 1:i3
	jr	z, HdaeRom_AltCheckResult_Epilogue
	jr	HdaeRom_AltCheckResult_Epilogue
HdaeRom_AltCheckResult_Skip2:
	bitm	7, (xsp+0x3)
	jr	z, HdaeRom_AltCheckResult_Epilogue
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	and	a, 128
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
	jr	HdaeRom_AltCheckResult_Epilogue
HdaeRom_AltCheckResult_Skip3:
	ld	a, (xsp+0x3)
	and	a, 255
	jr	z, HdaeRom_AltCheckResult_Epilogue
	lda	xbc, (xsp+0x2)
	ld	a, 0:opc
	bitm	7, (xsp+0x2)
	jr	nz, HdaeRom_AltCheckResult_Skip4
	ld	a, (xsp+0x2)
	res	7, a
HdaeRom_AltCheckResult_Skip4:
	ld	(xbc), a
	ld	a, (xsp+0x2)
	extz	wa
	ld	de, wa
	ldw	wa, 25
	ld	bc, 7:i3
	calr	MIDI_SendControlChange
HdaeRom_AltCheckResult_Epilogue:
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+0:8), (0xc080)
	ld	(xsp+0x1), (0xc07d)
	ld	(xsp+0x2), (0xc07e)
	ld	(xsp+0x3), (0xc07f)
	ld	a, (xsp+0x1)
	cp	a, 19
	jr	ugt, HdaeRom_AltCheckResult_Epilogue2
	cp	a, 4:i3
	jr	c, HdaeRom_AltCheckResult_Epilogue2
	ld	a, (xsp+0x1)
	dec	4, a
	extz	wa
	lda_d16	xbc, (0xf1a0)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	extz	wa
	lda	xbc, (AudioInit_SlotOrderMap:24)
	ld	e, (xbc+wa)
	ld	a, e
	cp	a, 1:i3
	jr	z, HdaeRom_AltCheckResult_Skip
	cp	a, 2:i3
	jr	z, HdaeRom_AltCheckResult_Skip
	cp	a, 0:i3
	jr	nz, HdaeRom_AltCheckResult_Epilogue2
HdaeRom_AltCheckResult_Skip:
	extz	de
	ld	a, (xsp+0x3)
	and	a, (xsp+0x2)
	ld	c, a
	extz	bc
	ld	wa, de
	ld	de, bc
	ldw	bc, 145
	calr	MIDI_SendControlChange
HdaeRom_AltCheckResult_Epilogue2:
	inc	4, xsp
	ret
HdaeRom_AltTableEntry0:
	dec	4, xsp
	ld	(xsp+0:8), (0xc080)
	ld	(xsp+0x1), (0xc07d)
	ld	(xsp+0x2), (0xc07e)
	ld	(xsp+0x3), (0xc07f)
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
	inc	4, xsp
	ret
HdaeRom_AltTableEntry1:
	dec	4, xsp
	ld	(xsp+0:8), (0xc080)
	ld	(xsp+0x1), (0xc07d)
	ld	(xsp+0x2), (0xc07e)
	ld	(xsp+0x3), (0xc07f)
	ld	a, (xsp+0x1)
	cp	a, 3:i3
	jr	z, HdaeRom_AltTableEntry1_Skip2
	cp	a, 1:i3
	jr	z, HdaeRom_AltTableEntry1_Skip
	cp	a, 0:i3
	jr	nz, HdaeRom_AltTableEntry1_Epilogue
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
	jr	HdaeRom_AltTableEntry1_Epilogue
HdaeRom_AltTableEntry1_Skip:
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
	jr	HdaeRom_AltTableEntry1_Epilogue
HdaeRom_AltTableEntry1_Skip2:
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
HdaeRom_AltTableEntry1_Epilogue:
	inc	4, xsp
	ret
HdaeRom_AltTableEntry2:
	dec	4, xsp
	ld	(xsp+0:8), (0xc080)
	ld	(xsp+0x1), (0xc07d)
	ld	(xsp+0x2), (0xc07e)
	ld	(xsp+0x3), (0xc07f)
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
	inc	4, xsp
	ret
HdaeRom_AltTableEntry3:
	dec	4, xsp
	ld	(xsp+0:8), (0xc080)
	ld	(xsp+0x1), (0xc07d)
	ld	(xsp+0x2), (0xc07e)
	ld	(xsp+0x3), (0xc07f)
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
	inc	4, xsp
	ret
HdaeRom_AltTableEntry4:
	dec	4, xsp
	ld	(xsp+0:8), (0xc080)
	ld	(xsp+0x1), (0xc07d)
	ld	(xsp+0x2), (0xc07e)
	ld	(xsp+0x3), (0xc07f)
	cp	(xsp+0x1), 16
	jr	c, HdaeRom_AltTableEntry4_Skip
	cp	(xsp+0x1), 20
	jr	ule, HdaeRom_AltTableEntry4_Epilogue
HdaeRom_AltTableEntry4_Skip:
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
HdaeRom_AltTableEntry4_Epilogue:
	inc	4, xsp
	ret
HdaeRom_AltTableEntry5:
	dec	4, xsp
	ld	(xsp+0:8), (0xc080)
	ld	(xsp+0x1), (0xc07d)
	ld	(xsp+0x2), (0xc07e)
	ld	(xsp+0x3), (0xc07f)
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
	inc	4, xsp
	ret
HdaeRom_AltTableEntry6:
	dec	4, xsp
	ld	(xsp+0:8), (0xc080)
	ld	(xsp+0x1), (0xc07d)
	ld	(xsp+0x2), (0xc07e)
	ld	(xsp+0x3), (0xc07f)
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
	inc	4, xsp
	ret
HdaeRom_AltTableEntry7:
	ret
HdaeRom_AltTableEntry8:
	ret
HdaeRom_AltTableEntry9:
	dec	4, xsp
	ld	(xsp+0:8), (0xc080)
	ld	(xsp+0x1), (0xc07d)
	ld	(xsp+0x2), (0xc07e)
	ld	(xsp+0x3), (0xc07f)
	ld	a, (xsp+0x1)
	cp	a, 1:i3
	jr	z, HdaeRom_AltTableEntry9_Skip2
	cp	a, 0:i3
	jr	nz, HdaeRom_AltTableEntry9_Epilogue
	bitm	7, (xsp+0x3)
	jr	z, HdaeRom_AltTableEntry9_Epilogue
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	and	a, 128
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
	jr	HdaeRom_AltTableEntry9_Epilogue
HdaeRom_AltTableEntry9_Skip2:
	ld	a, (xsp+0x3)
	res	7, a
	cp	a, 0:i3
	jr	z, HdaeRom_AltTableEntry9_Entry
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	res	7, a
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
HdaeRom_AltTableEntry9_Entry:
	bitm	7, (xsp+0x3)
	jr	z, HdaeRom_AltTableEntry9_Epilogue
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	a, (xsp+0x3)
	and	a, 128
	ld	c, a
	extz	bc
	ld	xwa, xde
	calr	UIState_ProcessKeyEvent_Helper
HdaeRom_AltTableEntry9_Epilogue:
	inc	4, xsp
	ret
UIState_ProcessKeyEvent_Helper:
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
	cp	hl, 0xffff
	jr	z, HdaeRom_AltTableEntry9_Join
	lda	xwa, (xsp+12)
	ld	xhl, xwa
	lda	xwa, (xsp+8)
	ld	xbc, xwa
	lda	xwa, (xsp+6)
	ld	xde, xwa
	ld	xwa, xhl
	call	SndParam_DecodeMidiAddr
	cp	hl, 0xffff
	jr	z, HdaeRom_AltTableEntry9_Skip
	ld	wa, (xsp+8)
	ld	bc, (xsp+6)
	ld	de, (xsp+10)
	calr	SndPart_SetParam
	jr	HdaeRom_AltTableEntry9_Join
HdaeRom_AltTableEntry9_Skip:
	ld	xwa, (xsp+12)
	ld	bc, (xsp+10)
	calr	SendEpilogue_Data
HdaeRom_AltTableEntry9_Join:
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
	cp bc, 7:i3
	jr z, SndPart_SetVolume
	cp bc, 1:i3
	jr z, SndPart_SetModWheel
	cp bc, 0x20
	jr z, SndPart_SetProgramMSB
	cp bc, 0:i3
	jrl nz, MIDI_SendEpilogue
	ld wa, (xsp + 2)
	add wa, wa
	lda xbc, (0xcfd0:16)
	extz xwa
	add xwa, xbc
	ld (xwa), iz
	jrl MIDI_SendEpilogue

SndPart_SetProgramMSB:
	ld wa, (xsp + 2)
	add wa, wa
	lda xbc, (0xd010:16)
	extz xwa
	add xwa, xbc
	ld (xwa), iz
	jrl MIDI_SendEpilogue

SndPart_SetModWheel:
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	ld bc, 1:i3
	calr MIDI_SendControlChange
	jrl MIDI_SendEpilogue

SndPart_SetVolume:
	ld wa, (xsp + 2)
	ldw bc, 0x8
	call SndParam_LookupViaEncode
	cp hl, 1:i3
	jr nz, SndPart_SetVolume_LoadReg
	ld iz, 0:i3

SndPart_SetVolume_LoadReg:
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	ld bc, 7:i3
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
	cp iz, 0:i3
	jr nz, SndPart_SetDamperPed_LoadReg
	ld wa, 0:i3

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
	lda xbc, (0xd050:16)
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
	cp iz, 0:i3
	jr nz, SndPart_SetFineTune_LoadReg
	ld wa, 0:i3

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
	cp iz, 0:i3
	jr nz, SndPart_SetCoarseTun_LoadReg
	ld wa, 0:i3

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
	ld de, 0:i3
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
	jrl	z, SendEpilogue_Data_Skip34
	cp	bc, 77
	jrl	z, SendEpilogue_Data_Skip33
	cp	bc, 76
	jrl	z, SendEpilogue_Data_Skip32
	cp	bc, 75
	jrl	z, SendEpilogue_Data_Skip31
	cp	bc, 73
	jrl	z, SendEpilogue_Data_Skip30
	cp	bc, 66
	jrl	z, SendEpilogue_Data_Skip14
	cp	bc, 65
	jrl	z, SendEpilogue_Data_Skip9
	cp	bc, 64
	jrl	z, SendEpilogue_Data_Skip7
	cp	bc, 0:i3
	jrl	nz, SendEpilogue_Data_Join
	ld	wa, de
	cp	wa, 193
	jrl	z, SendEpilogue_Data_Skip5
	cp	wa, 192
	jr	z, SendEpilogue_Data_Skip3
	cp	wa, 3:i3
	jr	z, SendEpilogue_Data_Skip
	cp	wa, 0:i3
	jrl	nz, SendEpilogue_Data_Join
	add	iz, 64
	ldto_berp a, 248
	extz	wa
	ld	de, wa
	ldw	wa, 80
	ldw	bc, 130
	calr	SeqVoice_CheckAndRet_Prologue
	jrl	SendEpilogue_Data_Join
SendEpilogue_Data_Skip:
	dec	5, iz
	ldto_berp a, 248
	extz	wa
	ld	de, wa
	ldw	wa, 80
	ldw	bc, 131
	calr	SeqVoice_CheckAndRet_Prologue
	ldto_berp a, 248
	cp a, (59842:16)
	jrl z, SendEpilogue_Data_Join
	ld	wa, (0xc596:16)
	and	wa, 128
	cp	wa, 128
	jr	nz, SendEpilogue_Data_Skip2
	ld	wa, (0xc596:16)
	bit	8, wa
	jr	nz, SendEpilogue_Data_Skip2
	ldw	wa, 255
	ld	bc, 2:i3
	call	MidiEvent_ConfigChannel
SendEpilogue_Data_Skip2:
	ldw	wa, 255
	ldw	bc, 21
	call	MidiEvent_ConfigChannel
	ldw	wa, 255
	ldw	bc, 22
	call	MidiEvent_ConfigChannel
	ldto_berp	a, 248
	ld	(0xe9c2:16), a
	jrl	SendEpilogue_Data_Join
SendEpilogue_Data_Skip3:
	ld	wa, 1:i3
	cp	iz, 0:i3
	jr	nz, SendEpilogue_Data_Skip4
	ld	wa, 2:i3
SendEpilogue_Data_Skip4:
	ld	iz, wa
	ldto_berp	a, 248
	extz	wa
	ld	de, wa
	ldw	wa, 127
	ldw	bc, 9
	calr	SeqVoice_CheckAndRet_Prologue
	jrl	SendEpilogue_Data_Join
SendEpilogue_Data_Skip5:
	ldw	wa, 127
	cp	iz, 0:i3
	jr	nz, SendEpilogue_Data_Skip6
	ld	wa, 0:i3
SendEpilogue_Data_Skip6:
	ld	iz, wa
	ldto_berp	a, 248
	extz	wa
	ld	de, wa
	ldw	wa, 80
	ldw	bc, 153
	calr	SeqVoice_CheckAndRet_Prologue
	jrl	SendEpilogue_Data_Join
SendEpilogue_Data_Skip7:
	ld	wa, de
	cp	wa, 130
	jrl	z, SendEpilogue_Data_Join
	cp	wa, 129
	jrl	z, SendEpilogue_Data_Join
	cp	wa, 128
	jr	z, SendEpilogue_Data_Skip8
	cp	wa, 6:i3
	jrl	ugt, SendEpilogue_Data_Join
	add	wa, wa
	lda	xix, (SendEpilogueB_SwitchOffsets:24)
	ld	wa, (xix+wa)
	lda xix, (MIDI_SendEpilogue_Code:24)
	jp	t, (xix+wa)
MIDI_SendEpilogue_Code:
	ldto_berp a, 248
	extz	wa
	call	SendPartDataBlock_Block
	jrl	SendEpilogue_Data_Join
	ldto_berp a, 248
	extz	wa
	call	SendPartDataBlock_Block2
	jrl	SendEpilogue_Data_Join
	ld	(0xcfca:16), iz
	jrl	SendEpilogue_Data_Join
	ld	(0xcfc8:16), iz
	jrl	SendEpilogue_Data_Join
	ld	(0xcfcc:16), iz
	jrl	SendEpilogue_Data_Join
	ldto_berp	a, 248
	extz	wa
	call	SendPartDataBlock_Block3
	jrl	SendEpilogue_Data_Join
	ldto_berp	a, 248
	extz	wa
	call	SendPartDataBlock_Block9
	jrl	SendEpilogue_Data_Join
SendEpilogue_Data_Skip8:
	ldto_berp	a, 248
	extz	wa
	ld	de, wa
	ldw	wa, 80
	ldw	bc, 133
	calr	SeqVoice_CheckAndRet_Prologue
	jrl	SendEpilogue_Data_Join
SendEpilogue_Data_Skip9:
	ld	wa, de
	cp	wa, 66
	jr	z, SendEpilogue_Data_Skip12
	cp	wa, 65
	jr	z, SendEpilogue_Data_Skip10
	cp	wa, 64
	jrl	nz, SendEpilogue_Data_Join
	ld	(0xcfce:16), iz
	jrl	SendEpilogue_Data_Join
SendEpilogue_Data_Skip10:
	ld	xwa, 0x4142
	call	SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr	nz, SendEpilogue_Data_Skip11
	ld	iz, 0:i3
SendEpilogue_Data_Skip11:
	ldto_berp a, 248
	extz	wa
	call	SendPartDataBlock_Block4
	jrl	SendEpilogue_Data_Join
SendEpilogue_Data_Skip12:
	ld	xwa, 0x4142
	call	SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr	nz, SendEpilogue_Data_Skip13
	ld	wa, 0:i3
	call	SendPartDataBlock_Block4
	jrl	SendEpilogue_Data_Join
SendEpilogue_Data_Skip13:
	ld	xwa, 0x4141
	call	SndParam_LookupReadOnly
	ld	a, l
	extz	wa
	call	SendPartDataBlock_Block4
	jrl	SendEpilogue_Data_Join
SendEpilogue_Data_Skip14:
	ld	wa, de
	sub	wa, 128
	cp	wa, 0:i3
	jrl	c, SendEpilogue_Data_Join
	cp	wa, 14
	jrl	ugt, SendEpilogue_Data_Join
	add	wa, wa
	lda	xix, (SendEpilogueA_SwitchOffsets:24)
	ld	wa, (xix+wa)
	lda xix, (MIDI_SendEpilogue_Code_2:24)
	jp	t, (xix+wa)
MIDI_SendEpilogue_Code_2:
	ldw	wa, 127
	cp	iz, 0:i3
	jr	nz, SendEpilogue_Data_Skip15
	ld	wa, 0:i3
SendEpilogue_Data_Skip15:
	ld	iz, wa
	ldto_berp	a, 248
	extz	wa
	ld	de, wa
	ldw	wa, 80
	ldw	bc, 177
	calr	SeqVoice_CheckAndRet_Prologue
	jrl	SendEpilogue_Data_Join
	ldto_berp	a, 248
	extz	wa
	calr	SendEpilogue_Data_Helper
	ld qiz, hl
	ld de, qiz
	ld	d, 0:opc
	ldw	wa, 80
	ldw	bc, 134
	calr	SeqVoice_CheckAndRet_Prologue
	ld wa, qiz
	and wa, 65280
	jrl	nz, SendEpilogue_Data_Join
	ldto_berp	a, 248
	extz	wa
	calr	SeqVoice_CheckAndRet_Data
	ld	(xsp+4), xhl
	ld	iz, 0:i3
	cp	iz, 12
	jrl	ge, SendEpilogue_Data_Join
SendEpilogue_Data_Loop:
	ld	a, (0xfd1d:16)
	and	a, 15
	ld	c, a
	extz	bc
	add	bc, iz
	ld	wa, bc
	cp	wa, 12
	jr	lt, SendEpilogue_Data_Skip16
	sub	bc, 12
SendEpilogue_Data_Skip16:
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ld	xwa, (xsp+4)
	ld	a, (xwa+iz)
	extz wa
	ld	de, wa
	ldw	wa, 80
	calr	SeqVoice_CheckAndRet_Prologue
	inc	1, iz
	cp	iz, 12
	jr	lt, SendEpilogue_Data_Loop
	jrl	SendEpilogue_Data_Join
	ld	xwa, 0x4281
	call	SndParam_LookupReadOnly
	ld	a, l
	extz	wa
	calr	SendEpilogue_Data_Helper
	ld qiz, hl
	ld wa, qiz
	and wa, 65280
	jrl	nz, SendEpilogue_Data_Join
	ld	xwa, 0x4281
	call	SndParam_LookupReadOnly
	ld	a, l
	extz	wa
	calr	SeqVoice_CheckAndRet_Data
	ld	(xsp+4), xhl
	ld	iz, 0:i3
	cp	iz, 12
	jrl	ge, SendEpilogue_Data_Join
SendEpilogue_Data_Loop2:
	ld	a, (0xfd1d:16)
	and	a, 15
	ld	c, a
	extz	bc
	add	bc, iz
	ld	wa, bc
	cp	wa, 12
	jr	lt, SendEpilogue_Data_Skip17
	sub	bc, 12
SendEpilogue_Data_Skip17:
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ld	xwa, (xsp+4)
	ld	a, (xwa+iz)
	extz wa
	ld	de, wa
	ldw	wa, 80
	calr	SeqVoice_CheckAndRet_Prologue
	inc	1, iz
	cp	iz, 12
	jr	lt, SendEpilogue_Data_Loop2
	jrl	SendEpilogue_Data_Join
	ld	xwa, 0x4281
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jrl	nz, SendEpilogue_Data_Join
	ld	a, (0xfd1d:16)
	and	a, 15
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, SendEpilogue_Data_Skip18
	sub	bc, 12
SendEpilogue_Data_Skip18:
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ld	a, (0xfd1e:16)
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	SeqVoice_CheckAndRet_Prologue
	jrl	SendEpilogue_Data_Join
	ld	xwa, 0x4281
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jrl	nz, SendEpilogue_Data_Join
	ld	a, (0xfd1d:16)
	and	a, 15
	inc	1, a
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, SendEpilogue_Data_Skip19
	sub	bc, 12
SendEpilogue_Data_Skip19:
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ld	a, (0xfd1f:16)
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	SeqVoice_CheckAndRet_Prologue
	jrl	SendEpilogue_Data_Join
	ld	xwa, 0x4281
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jrl	nz, SendEpilogue_Data_Join
	ld	a, (0xfd1d:16)
	and	a, 15
	inc	2, a
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, SendEpilogue_Data_Skip20
	sub	bc, 12
SendEpilogue_Data_Skip20:
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ld	a, (0xfd20:16)
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	SeqVoice_CheckAndRet_Prologue
	jrl	SendEpilogue_Data_Join
	ld	xwa, 0x4281
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jrl	nz, SendEpilogue_Data_Join
	ld	a, (0xfd1d:16)
	and	a, 15
	inc	3, a
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, SendEpilogue_Data_Skip21
	sub	bc, 12
SendEpilogue_Data_Skip21:
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ld	a, (0xfd21:16)
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	SeqVoice_CheckAndRet_Prologue
	jrl	SendEpilogue_Data_Join
	ld	xwa, 0x4281
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jrl	nz, SendEpilogue_Data_Join
	ld	a, (0xfd1d:16)
	and	a, 15
	inc	4, a
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, SendEpilogue_Data_Skip22
	sub	bc, 12
SendEpilogue_Data_Skip22:
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ld	a, (0xfd22:16)
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	SeqVoice_CheckAndRet_Prologue
	jrl	SendEpilogue_Data_Join
	ld	xwa, 0x4281
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jrl	nz, SendEpilogue_Data_Join
	ld	a, (0xfd1d:16)
	and	a, 15
	inc	5, a
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, SendEpilogue_Data_Skip23
	sub	bc, 12
SendEpilogue_Data_Skip23:
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ld	a, (0xfd23:16)
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	SeqVoice_CheckAndRet_Prologue
	jrl	SendEpilogue_Data_Join
	ld	xwa, 0x4281
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jrl	nz, SendEpilogue_Data_Join
	ld	a, (0xfd1d:16)
	and	a, 15
	inc	6, a
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, SendEpilogue_Data_Skip24
	sub	bc, 12
SendEpilogue_Data_Skip24:
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ld	a, (0xfd24:16)
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	SeqVoice_CheckAndRet_Prologue
	jrl	SendEpilogue_Data_Join
	ld	xwa, 0x4281
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jrl	nz, SendEpilogue_Data_Join
	ld	a, (0xfd1d:16)
	and	a, 15
	inc	7, a
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, SendEpilogue_Data_Skip25
	sub	bc, 12
SendEpilogue_Data_Skip25:
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ld	a, (0xfd25:16)
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	SeqVoice_CheckAndRet_Prologue
	jrl	SendEpilogue_Data_Join
	ld	xwa, 0x4281
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jrl	nz, SendEpilogue_Data_Join
	ld	a, (0xfd1d:16)
	and	a, 15
	inc	8, a
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, SendEpilogue_Data_Skip26
	sub	bc, 12
SendEpilogue_Data_Skip26:
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ld	a, (0xfd26:16)
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	SeqVoice_CheckAndRet_Prologue
	jrl	SendEpilogue_Data_Join
	ld	xwa, 0x4281
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jrl	nz, SendEpilogue_Data_Join
	ld	a, (0xfd1d:16)
	and	a, 15
	add	a, 9
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, SendEpilogue_Data_Skip27
	sub	bc, 12
SendEpilogue_Data_Skip27:
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ld	a, (0xfd27:16)
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	SeqVoice_CheckAndRet_Prologue
	jrl	SendEpilogue_Data_Join
	ld	xwa, 0x4281
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jrl	nz, SendEpilogue_Data_Join
	ld	a, (0xfd1d:16)
	and	a, 15
	add	a, 10
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, SendEpilogue_Data_Skip28
	sub	bc, 12
SendEpilogue_Data_Skip28:
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ld	a, (0xfd28:16)
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	SeqVoice_CheckAndRet_Prologue
	jr	SendEpilogue_Data_Join
	ld	xwa, 0x4281
	call	SndParam_LookupReadOnly
	cp	hl, 128
	jr	nz, SendEpilogue_Data_Join
	ld	a, (0xfd1d:16)
	and	a, 15
	add	a, 11
	ld	c, a
	extz	bc
	ld	wa, bc
	cp	wa, 12
	jr	lt, SendEpilogue_Data_Skip29
	sub	bc, 12
SendEpilogue_Data_Skip29:
	ld	wa, bc
	add	wa, 164
	ld	bc, wa
	ld	a, (0xfd29:16)
	extz	wa
	ld	de, wa
	ldw	wa, 80
	calr	SeqVoice_CheckAndRet_Prologue
	jr	SendEpilogue_Data_Join
SendEpilogue_Data_Skip30:
	ld	(0xcfb4:16), xwa
	jr	SendEpilogue_Data_Join
SendEpilogue_Data_Skip31:
	ld	(0xcfb8:16), xwa
	jr	SendEpilogue_Data_Join
SendEpilogue_Data_Skip32:
	ld	(0xcfbc:16), xwa
	jr	SendEpilogue_Data_Join
SendEpilogue_Data_Skip33:
	ld	(0xcfc0:16), xwa
	jr	SendEpilogue_Data_Join
SendEpilogue_Data_Skip34:
	ld	(0xcfc4:16), xwa
SendEpilogue_Data_Join:
	call	MIDI_PostSendStub
	pop	xiz
	inc	4, xsp
	ret

Song_SendPartDataBlocks:
	pushw iz
	ld xwa, (0xcfb4:16)
	cp xwa, 0xffffffff
	jr z, SendPartDataBlocks_LoadDRAM
	ld wa, 0:i3
	call COMM_SendPartDataBlock

SendPartDataBlocks_LoadDRAM:
	ld xwa, (0xcfb8:16)
	cp xwa, 0xffffffff
	jr z, SendPartDataBlocks_LoadDRAM2
	ld wa, 1:i3
	call COMM_SendPartDataBlock

SendPartDataBlocks_LoadDRAM2:
	ld xwa, (0xcfbc:16)
	cp xwa, 0xffffffff
	jr z, SendPartDataBlocks_LoadDRAM3
	ld wa, 4:i3
	call COMM_SendPartDataBlock

SendPartDataBlocks_LoadDRAM3:
	ld xwa, (0xcfc0:16)
	cp xwa, 0xffffffff
	jr z, SendPartDataBlocks_LoadDRAM4
	ld wa, 2:i3
	call COMM_SendPartDataBlock

SendPartDataBlocks_LoadDRAM4:
	ld xwa, (0xcfc4:16)
	cp xwa, 0xffffffff
	jr z, SendPartDataBlocks_Block
	ld wa, 3:i3
	call COMM_SendPartDataBlock

SendPartDataBlocks_Block:
	cpw (0xcfc8:16), 0xffff
	jr z, SendPartDataBlocks_Block2
	ld wa, (0xcfc8:16)
	extz wa
	call SendPartDataBlock_Block7

SendPartDataBlocks_Block2:
	cpw (0xcfca:16), 0xffff
	jr z, SendPartDataBlocks_Block3
	ld wa, (0xcfca:16)
	extz wa
	call SendPartDataBlock_ClearByte

SendPartDataBlocks_Block3:
	cpw (0xcfcc:16), 0xffff
	jr z, SendPartDataBlocks_Block4
	ld wa, (0xcfcc:16)
	extz wa
	call SendPartDataBlock_ClearByte2

SendPartDataBlocks_Block4:
	cpw (0xcfce:16), 0xffff
	jr z, SendPartDataBlocks_InitVal
	ld wa, (0xcfce:16)
	extz wa
	call SendPartDataBlock_ClearByte3

SendPartDataBlocks_InitVal:
	ld iz, 0:i3
	cp iz, 0x18
	jrl gt, SendPartDataBlocks_Send

SendPartDataBlocks_LoadIter:
	ld wa, iz
	add wa, wa
	lda xbc, (0xcfd0:16)
	extz xwa
	add xwa, xbc
	cpw (xwa), 0xffff
	jr z, SendPartDataBlocks_LoadIter3
	ld wa, iz
	add wa, wa
	lda xbc, (0xd010:16)
	extz xwa
	add xwa, xbc
	cpw (xwa), 0xffff
	jr z, SendPartDataBlocks_LoadIter3
	ld wa, iz
	add wa, wa
	lda xbc, (0xd050:16)
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
	lda xbc, (0xd050:16)
	extz xwa
	add xwa, xbc
	ld hl, (xwa)

SendPartDataBlocks_LoadReg:
	ld ix, iz
	ld wa, iz
	add wa, wa
	lda xbc, (0xcfd0:16)
	extz xwa
	add xwa, xbc
	ld iy, (xwa)
	ld wa, iz
	add wa, wa
	lda xbc, (0xd010:16)
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
	lda xbc, (0xd050:16)
	extz xwa
	add xwa, xbc
	cpw (xwa), 0xffff
	jr z, SendPartDataBlocks_NextIter
	ld hl, iz
	ld wa, iz
	add wa, wa
	lda xbc, (0xd050:16)
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
	ld (0xcfb4:16), xwa
	ld xwa, 0xffffffff
	ld (0xcfb8:16), xwa
	ld xwa, 0xffffffff
	ld (0xcfbc:16), xwa
	ld xwa, 0xffffffff
	ld (0xcfc0:16), xwa
	ld xwa, 0xffffffff
	ld (0xcfc4:16), xwa
	ldw (0xcfc8:16), 0xffff
	ldw (0xcfca:16), 0xffff
	ldw (0xcfcc:16), 0xffff
	ldw (0xcfce:16), 0xffff
	ld de, 0:i3
	cp de, 0x18
	ret gt

SendDataReturn_LoadReg:
	ld wa, de
	add wa, wa
	lda xbc, (0xcfd0:16)
	extz xwa
	add xwa, xbc
	ldw (xwa), 0xffff
	ld wa, de
	add wa, wa
	lda xbc, (0xd010:16)
	extz xwa
	add xwa, xbc
	ldw (xwa), 0xffff
	ld wa, de
	add wa, wa
	lda xbc, (0xd050:16)
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
	ld (xsp + 0:8), 0x4
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
	ld (xsp + 0:8), 0x4
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
	ld (xsp + 0:8), 0x4
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
	ld iz, 0:i3
	jr SendChannelPressure_LoadParam

SendChannelPressure_InitVal:
	ld wa, 0:i3
	cp iz, 0:i3
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
	ld wa, (0xc596:16)
	and wa, 0x80
	cp wa, 0x80
	jr nz, SeqVoice_CheckAndRetry
	ld wa, (0xc596:16)
	bit 8, wa
	jr nz, SeqVoice_CheckAndRetry
	ldw wa, 0xff
	ld bc, 2:i3
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
	ld (xsp + 0:8), 0x4
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
	jrl	z, SeqVoice_CheckAndRet_Data_Skip8
	cp	a, 5:i3
	jr	z, SeqVoice_CheckAndRet_Data_Skip7
	cp	a, 4:i3
	jr	z, SeqVoice_CheckAndRet_Data_Skip6
	cp	a, 3:i3
	jr	z, SeqVoice_CheckAndRet_Data_Skip5
	cp	a, 66
	jr	z, SeqVoice_CheckAndRet_Data_Skip4
	cp	a, 65
	jr	z, SeqVoice_CheckAndRet_Data_Skip3
	cp	a, 64
	jr	z, SeqVoice_CheckAndRet_Data_Skip2
	cp	a, 0:i3
	jr	z, SeqVoice_CheckAndRet_Data_Skip
	extz	wa
	sub	wa, 16
	cp	wa, 0:i3
	jrl	lt, SeqVoice_CheckAndRet_Data_Skip9
	cp	wa, 6:i3
	jr	gt, SeqVoice_CheckAndRet_Data_Skip9
	add	wa, wa
	lda	xix, (SeqVoiceSel_SwitchOffsets:24)
	ld	wa, (xix+wa)
	lda	xix, (SeqVoice_CheckAndRet_Data_Skip:24)
	jp	t, (xix+wa)
SeqVoice_CheckAndRet_Data_Skip:
	lda	xhl, (SemitoneBias_TableA:24)
	jr	SeqVoice_CheckAndRet_Data_Return
SeqVoice_CheckAndRet_Data_Skip2:
	lda	xhl, (SemitoneBias_TableB:24)
	jr	SeqVoice_CheckAndRet_Data_Return
SeqVoice_CheckAndRet_Data_Skip3:
	lda	xhl, (SemitoneBias_TableC:24)
	jr	SeqVoice_CheckAndRet_Data_Return
SeqVoice_CheckAndRet_Data_Skip4:
	lda	xhl, (SemitoneBias_TableD:24)
	jr	SeqVoice_CheckAndRet_Data_Return
SeqVoice_CheckAndRet_Data_Skip5:
	lda	xhl, (SemitoneBias_TableE:24)
	jr	SeqVoice_CheckAndRet_Data_Return
SeqVoice_CheckAndRet_Data_Skip6:
	lda	xhl, (SemitoneBias_TableF:24)
	jr	SeqVoice_CheckAndRet_Data_Return
SeqVoice_CheckAndRet_Data_Skip7:
	lda	xhl, (SemitoneBias_TableG:24)
	jr	SeqVoice_CheckAndRet_Data_Return
	lda	xhl, (SemitoneBias_TableH:24)
	jr	SeqVoice_CheckAndRet_Data_Return
	lda	xhl, (SemitoneBias_TableI:24)
	jr	SeqVoice_CheckAndRet_Data_Return
	lda	xhl, (SemitoneBias_TableJ:24)
	jr	SeqVoice_CheckAndRet_Data_Return
	lda	xhl, (SemitoneBias_TableK:24)
	jr	SeqVoice_CheckAndRet_Data_Return
	lda	xhl, (SemitoneBias_TableL:24)
	jr	SeqVoice_CheckAndRet_Data_Return
	lda	xhl, (SemitoneBias_TableM:24)
	jr	SeqVoice_CheckAndRet_Data_Return
	lda	xhl, (SemitoneBias_TableN:24)
	jr	SeqVoice_CheckAndRet_Data_Return
SeqVoice_CheckAndRet_Data_Skip8:
	lda	xhl, (0xfd1e:16)
	jr	SeqVoice_CheckAndRet_Data_Return
SeqVoice_CheckAndRet_Data_Skip9:
	lda	xhl, (SemitoneBias_TableA:24)
SeqVoice_CheckAndRet_Data_Return:
	ret
SendEpilogue_Data_Helper:
	cp	a, 128
	jrl	z, SeqVoice_CheckAndRet_Data_Skip11
	cp	a, 5:i3
	jr	z, 90
	cp	a, 4:i3
	jr	z, 82
	cp	a, 3:i3
	jr	z, 74
	cp	a, 66
	jr	z, 64
	cp	a, 65
	jr	z, 54
	cp	a, 64
	jr	z, 44
	cp	a, 0:i3
	jr	z, SeqVoice_CheckAndRet_Data_Skip10
	extz	wa
	sub	wa, 16
	cp	wa, 0:i3
	jr	lt, SeqVoice_CheckAndRet_Data_Skip12
	cp	wa, 6:i3
	jr	gt, SeqVoice_CheckAndRet_Data_Skip12
	add	wa, wa
	lda	xix, (SendEpilogueC_SwitchOffsets:24)
	ld	wa, (xix+wa)
	lda	xix, (SeqVoice_CheckAndRet_Data_Skip10:24)
	jp	t, (xix+wa)
SeqVoice_CheckAndRet_Data_Skip10:
	ld	hl, 0:i3
	.ascii "hE3@ÿh@3Aÿh;3Bÿh6Û«h2Û¬h.Û­h*"
	ldw	hl, 16
	jr	SeqVoice_CheckAndRet_Data_Return2
	ldw	hl, 17
	jr	SeqVoice_CheckAndRet_Data_Return2
	ldw	hl, 18
	jr	SeqVoice_CheckAndRet_Data_Return2
	ldw	hl, 19
	jr	SeqVoice_CheckAndRet_Data_Return2
	ldw	hl, 20
	jr	SeqVoice_CheckAndRet_Data_Return2
	ldw	hl, 21
	jr	SeqVoice_CheckAndRet_Data_Return2
	ldw	hl, 22
	jr	SeqVoice_CheckAndRet_Data_Return2
SeqVoice_CheckAndRet_Data_Skip11:
	ldw	hl, 128
	jr	SeqVoice_CheckAndRet_Data_Return2
SeqVoice_CheckAndRet_Data_Skip12:
	ld	hl, 0:i3
SeqVoice_CheckAndRet_Data_Return2:
	ret

MIDI_SendSysExCmd:
	dec 6, xsp
	ld (xsp + 0:8), 0x4
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
	ld	de, 0:i3
	calr	SeqVoice_CheckAndRet_Prologue
	jp	MIDI_PostSendStub

COMM_WriteAndCheck:
	dec 4, xsp
	ld (xsp + 2), a
	ld a, 0x1:opc
	cp (xsp + 2), 0x0
	jr nz, WriteAndCheck_LoadParam
	ld a, 0x2:opc

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
	cp hl, 1:i3
	jr nz, MIDI_SendPartVol_LookupFallback
	ld (xsp + 2), 0x0
	jr MIDI_SendPartVol_StoreAndSend

MIDI_SendPartVol_LookupFallback:
	ld wa, (xsp)
	ld bc, 7:i3
	call SndParam_LookupViaEncode
	ld (xsp + 2), l

MIDI_SendPartVol_StoreAndSend:
	ld de, (xsp)
	ld a, (xsp + 2)
	ld c, a
	extz bc
	ld wa, de
	ld de, bc
	ld bc, 7:i3
	calr MIDI_SendControlChange
	incw 1, (xsp)
	cpw (xsp), 0x16
	jr le, MIDI_SendPartVolumes_Loop

MIDI_SendPartVol_ExtraParts:
	ld xwa, 0x2880b
	call SndParam_LookupReadOnly
	cp hl, 1:i3
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
	ld bc, 7:i3
	calr MIDI_SendControlChange
	ld a, (xsp + 2)
	extz wa
	ld de, wa
	ldw wa, 0x18
	ld bc, 7:i3
	calr MIDI_SendControlChange
	call MIDI_PostSendStub
	inc 4, xsp
	ret

MIDI_BroadcastPitchReset:
	push xiz
	ldw iz, 0x40
	ld wa, 0:i3
	cp iz, 0x40
	jr c, PitchReset_ShiftAndOr
	ld wa, iz
	add wa, wa
	sub wa, 0x80

PitchReset_ShiftAndOr:
	sll iz, 7
	or iz, wa
	ldiw_erp 0xfa, 0
	cp_erpw 0xfa, 0x0f, 0x00
	jr ge, PitchReset_CheckExtChannels

PitchReset_ChannelLoop:
	ldto_werp WA, 0xfa
	ld bc, iz
	calr MIDI_SendPitchBend
	ldto_werp WA, 0xfa
	ld bc, 1:i3
	ld de, 0:i3
	calr MIDI_SendControlChange
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0x0f, 0x00
	jr lt, PitchReset_ChannelLoop

PitchReset_CheckExtChannels:
	ld a, (0x379b:16)
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
	ld bc, 1:i3
	ld de, 0:i3
	calr MIDI_SendControlChange
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0x13, 0x00
	jr lt, PitchReset_ExtChannelLoop

PitchReset_Flush:
	call MIDI_PostSendStub
	pop xiz
	ret

MIDI_PitchBendData_Block:
	ldw	wa, 80
	ldw	bc, 146
	ld	de, 0:i3
	calr	SeqVoice_CheckAndRet_Prologue
	jp	MIDI_PostSendStub

MIDI_SendAllSoundOff:
	pushw iz
	ld iz, 0:i3
	cp iz, 0x18
	jr gt, SendAllSoundOff_Flush

SendAllSoundOff_Loop:
	ld wa, iz
	ldw bc, 0x78
	ld de, 0:i3
	calr MIDI_SendControlChange
	inc 1, iz
	cp iz, 0x18
	jr le, SendAllSoundOff_Loop

SendAllSoundOff_Flush:
	call MIDI_PostSendStub
	popw iz
	ret

MIDI_WriteChannelData_Block:
	ld	l, 0:opc
	extz	wa
	sub	wa, 16
	cp	wa, 0:i3
	ret	lt
	cp	wa, 8
	ret	gt
	add	wa, wa
	lda	xix, (ChannelData_SwitchOffsets:24)
	ld	wa, (xix+wa)
	lda xix, (SendAllSoundOff_Flush_Code:24)
	jp	t, (xix+wa)
SendAllSoundOff_Flush_Code:
	ld	l, 1:opc
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
	ld hl, 0:i3
	jr SendCmdPacket_CheckCount

SendCmdPacket_Loop:
	lda xde, (0xd090:16)
	ld bc, hl
	inc 1, bc
	ld	c, (xwa+bc)
	ld	(xde+hl), c
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
	ld wa, 0:i3
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
	ld hl, (0xe9e5:16)
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
	ld iz, 0:i3
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
	cp (0xe9c4:16), 0
	jr nz, OutputFlush_LoadDRAM
	ld hl, 0:i3
	jrl Acc_PopIzRet

OutputFlush_LoadDRAM:
	ld wa, (0xe9e5:16)
	and wa, 0x2
	cp wa, 2:i3
	jr nz, OutputFlush_InitVal
	ld wa, (0xe9e5:16)
	bit 2, wa
	jr nz, OutputFlush_InitVal
	ld hl, 0:i3
	jr Acc_PopIzRet

OutputFlush_InitVal:
	ld wa, 1:i3
	calr AccWrap_PlayModeStateMachine
	ld wa, (0xe9e5:16)
	ld bc, (0xe9ef:16)
	calr PlayModeStateMachine_Prologue
	ld xiz, xhl
	cp (0xe9e4:16), 4
	jr nz, AccSong_ProcessRecord_Loop
	ld xwa, xiz
	calr MidiRealtime_Process_Prologue

AccSong_ProcessRecord_Loop:
	cp (0xe9e7:16), xiz
	jr ugt, AccSong_ProcessRecord_InitVal
	calr FileIO_ReadNextRecord
	ld wa, hl
	cp wa, 0:i3
	jr ge, AccSong_ProcessRecord_LoadDRAM
	ldw hl, 0xffff
	jr Acc_PopIzRet

AccSong_ProcessRecord_LoadDRAM:
	ld a, (0xe9e4:16)
	cp a, 4:i3
	jr z, AccSong_ProcessRecord_LoadReg2
	cp a, 3:i3
	jr z, AccSong_ProcessRecord_LoadReg
	cp a, 2:i3
	jr z, AccSong_ProcessRecord_LoadReg
	cp a, 1:i3
	jr nz, AccSong_ProcessRecord_Loop
	ld a, l
	extz wa
	calr ConfigureBanks_LoadReg
	ld wa, hl
	cp wa, 0:i3
	jr ge, AccSong_ProcessRecord_Loop
	jr Acc_PopIzRet

AccSong_ProcessRecord_LoadReg:
	ld a, l
	extz wa
	calr MidiSysMsg_Handler
	ld wa, hl
	cp wa, 0:i3
	jr ge, AccSong_ProcessRecord_Loop
	jr Acc_PopIzRet

AccSong_ProcessRecord_LoadReg2:
	ld a, l
	extz wa
	calr MidiRealtime_ReadAndProcess
	ld wa, hl
	cp wa, 0:i3
	jr ge, AccSong_ProcessRecord_Loop
	jr Acc_PopIzRet

AccSong_ProcessRecord_InitVal:
	ld hl, 0:i3

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
	ld (0xe9e4:16), a
	call Audio_ConfigureDSP
	ld xwa, (xsp + 2)
	calr NotifyChangeComplete_Prologue
	ld iz, hl
	ld wa, iz
	cp wa, 0:i3
	jr ge, LoadAndStartPlayback_LoadParam
	calr Song_AbortPlayback
	ld hl, iz
	jr SeqVoice_PopIzReturn

LoadAndStartPlayback_LoadParam:
	ld a, (xsp + 6)
	calr SeqVoice_PopIzReturn_Prologue
	ld iz, hl
	ld wa, iz
	cp wa, 0:i3
	jr ge, LoadAndStartPlayback_LoadParam2
	calr Song_AbortPlayback
	ld hl, iz
	jr SeqVoice_PopIzReturn

LoadAndStartPlayback_LoadParam2:
	ld a, (xsp + 6)
	calr SeqVoice_PopIzReturn_Compare
	ld iz, hl
	ld wa, iz
	cp wa, 0:i3
	jr ge, LoadAndStartPlayback_LoadParam3
	calr Song_AbortPlayback
	ld hl, iz
	jr SeqVoice_PopIzReturn

LoadAndStartPlayback_LoadParam3:
	ld xwa, (xsp + 2)
	push xwa
	lda xwa, (0xe9c4:16)
	push xwa
	call Strcpy
	inc 8, xsp
	ld wa, 6:i3
	calr AccWrap_PlayModeStateMachine
	orw (0xe9e5:16), 1
	ld hl, 0:i3

SeqVoice_PopIzReturn:
	popw iz
	inc 6, xsp
	ret

SeqVoice_PopIzReturn_Compare:
	cp a, 4:i3
	jr z, SeqVoice_PopIzReturn_Block2
	cp a, 2:i3
	jr z, SeqVoice_PopIzReturn_Block
	cp a, 1:i3
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
	cp a, 4:i3
	jr z, SeqVoice_PopIzReturn_Block5
	cp a, 2:i3
	jr z, SeqVoice_PopIzReturn_Block4
	cp a, 3:i3
	jr z, SeqVoice_PopIzReturn_Block3
	cp a, 1:i3
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
	ld wa, 2:i3
	calr AccWrap_PlayModeStateMachine
	calr DirectReturn_LoadDRAM
	jrl StoreAndReturn_Block

FileIO_ReadChunk:
	lda xsp, (xsp - 14)
	pushw iz
	ld (xsp + 14), wa
	ldw (xsp + 2), 0x1
	ld wa, (xsp + 14)
	ld (0xe9f3:16), wa
	ld iz, 0:i3
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
	ld wa, (0xe9e5:16)
	bit 0, wa
	jr z, TransitionPlayMode_Block
	ld wa, 4:i3
	calr AccWrap_PlayModeStateMachine
	calr MIDI_ResetAllChannels
	orw (0xe9e5:16), 2

TransitionPlayMode_Block:
	andw (0xe9e5:16), 0xfffb
	ret

Acc_StopPlayMode:
	ld wa, 3:i3
	calr AccWrap_PlayModeStateMachine
	andw (0xe9e5:16), 0xfffd
	andw (0xe9e5:16), 0xfffb
	ret

Acc_StartFillIn:
	ld wa, (0xe9e5:16)
	bit 2, wa
	ret nz
	orw (0xe9e5:16), 4
	ld wa, 4:i3
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
	cp wa, 0:i3
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
	incw 1, (xwa)
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
	cp wa, 0:i3
	jr ge, ReadVariableLengthDa_LoadParam2
	ld xhl, 0xffffffff
	jr ReadVariableLengthDa_Epilogue

ReadVariableLengthDa_LoadParam2:
	ld xwa, (xsp + 8)
	ld bc, (xwa)
	incw 1, (xwa)
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
	ld iz, 0:i3
	ld wa, iz
	cp wa, (xsp + 6)
	jr nc, ReadVariableLengthDa_InitVal

ReadVariableLengthDa_LoopBody:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cp wa, 0:i3
	jr ge, ReadVariableLengthDa_LoopCheck
	ldw hl, 0xffff
	jr ReadVariableLengthDa_RestoreReg

ReadVariableLengthDa_LoopCheck:
	ld xwa, (xsp + 2)
	ld	(xwa+iz), l
	inc 1, iz
	ld wa, iz
	cp wa, (xsp + 6)
	jr c, ReadVariableLengthDa_LoopBody

ReadVariableLengthDa_InitVal:
	ld hl, 0:i3

ReadVariableLengthDa_RestoreReg:
	popw iz
	inc 6, xsp
	ret

AccWrap_PlayModeStateMachine:
	cp wa, 4:i3
	jrl z, PlayModeStateMachine_Block4
	cp wa, 3:i3
	jrl z, PlayModeStateMachine_DoPlayMode2
	cp wa, 2:i3
	jr z, PlayModeStateMachine_Block2
	cp wa, 1:i3
	jr z, PlayModeStateMachine_Block
	cp wa, 6:i3
	ret nz
	ldw (0xd09a:16), 30
	ei 6
	ldw (1052:16), 0
	ld (1051:16), 0
	ei 0
	ret

PlayModeStateMachine_Block:
	cpw (0xd09a:16), 0
	ret le
	subw (0xd09a:16), 1
	ret nz
	res 1, (0x28b2:16)
	res 2, (0x28b2:16)
	res 3, (0x28a7:16)
	ei 6
	ldw (1052:16), 0
	ld (1051:16), 0
	ei 0
	jp AccWrap_PlayModeStart

PlayModeStateMachine_Block2:
	cpw (0xd09a:16), 0
	jr le, PlayModeStateMachine_DoPlayMode
	ldw (0xd09a:16), 0
	ret

PlayModeStateMachine_DoPlayMode:
	call AccWrap_PlayModeDispatch
	ld xwa, 0:i3
	cp xwa, 0x7ffe
	jr ugt, PlayModeStateMachine_Block3

PlayModeStateMachine_TestBit2:
	bit 2, (1057:16)
	jr nz, PlayModeStateMachine_Block3
	inc 1, xwa
	cp xwa, 0x7ffe
	jr ule, PlayModeStateMachine_TestBit2

PlayModeStateMachine_Block3:
	ei 6
	ldw (1052:16), 0
	ld (1051:16), 0
	ei 0
	ret

PlayModeStateMachine_DoPlayMode2:
	call AccWrap_PlayModeStart
	ei 6
	ld xwa, (0xd0a4:16)
	ld (1052:16), wa
	ld xwa, (0xd0a0:16)
	ld (1051:16), a
	ei 0
	ret

PlayModeStateMachine_Block4:
	ei 6
	ld wa, (1052:16)
	extz xwa
	ld (0xd0a4:16), xwa
	ld xwa, 0:i3
	ld a, (1051:16)
	ld (0xd0a0:16), xwa
	ei 0
	call AccWrap_PlayModeDispatch
	ld xwa, 0:i3
	cp xwa, 0x7ffe
	ret ugt

PlayModeStateMachine_TestBit22:
	bit 2, (1057:16)
	ret nz
	inc 1, xwa
	cp xwa, 0x7ffe
	jr ule, PlayModeStateMachine_TestBit22
	ret

PlayModeStateMachine_Block5:
	res 2, (0x28a7:16)
	ret

PlayModeStateMachine_Prologue:
	dec 4, xsp
	push xiz
	ld (xsp + 4), bc
	ld (xsp + 6), wa
	ei 6
	ld a, (1051:16)
	ld xbc, 0:i3
	ld c, a
	ld wa, (1052:16)
	mul wa, 0x60
	ld xiz, xwa
	add xiz, xbc
	ei 0
	ld wa, (xsp + 6)
	bit 2, wa
	jr z, PlayModeStateMachine_LoadParam
	ld wa, (0xec0e:16)
	decw 1, (0xec0e:16)
	cp wa, 0:i3
	jr ge, PlayModeStateMachine_LoadParam
	ldw (0xec0e:16), 6
	inc 1, xiz
	ei 6
	ld xwa, xiz
	ld xbc, 0x60
	call Math_DivideU32
	ld (1052:16), hl
	ld wa, (1052:16)
	extz xwa
	ld (0xd0a4:16), xwa
	ld xwa, xiz
	ld xbc, 0x60
	call DivMod32
	ld a, l
	ld (1051:16), a
	ld w, 0x0:opc
	extz xwa
	ld (0xd0a0:16), xwa
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
	bit 0, (1074:16)
	jr nz, SeqPlay_BusyWaitLoop
	ret

MIDI_ResetAllChannels:
	lda xsp, (xsp - 10)
	pushw iz
	ld iz, 0:i3
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
	ld wa, 3:i3
	calr MIDI_SendSinglePacket
	ldto_berp A, 0xf8
	or a, 0xb0
	ld (xsp + 2), a
	ld (xsp + 3), 0x0
	ld (xsp + 4), 0x40
	lda xwa, (xsp + 2)
	ld xbc, xwa
	ld wa, 3:i3
	calr MIDI_SendSinglePacket
	ldto_berp A, 0xf8
	or a, 0xb0
	ld (xsp + 2), a
	ld (xsp + 3), 0x40
	ld (xsp + 4), 0x0
	lda xwa, (xsp + 2)
	ld xbc, xwa
	ld wa, 3:i3
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
	ld wa, 1:i3
	ld xiy, SendPacket_BitMaskTemplateA
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
	ld de, (0xe9f3:16)
	and	de, (xbc+wa)
	jr nz, SendSinglePacket_DoGetPlayS
	ei 6
	push xiz
	pushm (xsp + 40)
	call SeqMain_WriteBytes
	inc 6, xsp
	ei 0

SendSinglePacket_DoGetPlayS:
	call GetPlayState2
	cp l, 0:i3
	jr z, SendSinglePacket_Epilogue
	cp (0xe9e4:16), 1
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
	jr	c, SendSinglePacket_Data_Code_Skip
	cp	(xiz), 247
	jr	ugt, SendSinglePacket_Data_Code_Skip
	ei	0x06
	push	xiz
	pushm	(xsp+40)
	call	SeqBuf2_WriteBytes
	inc	6, xsp
	ei	0x00
	jr	SendSinglePacket_Data_Code_Epilogue
SendSinglePacket_Data_Code_Skip:
	ld	a, (xiz)
	and	a, 15
	extz	wa
	add	wa, wa
	lda	xbc, (xsp+4)
	ld	de, (0xe9f3:16)
	and	de, (xbc+wa)
	jr	nz, SendSinglePacket_Data_Code_Epilogue
	ei	0x06
	push	xiz
	pushm	(xsp+40)
	call	SeqMain_WriteBytes
	inc	6, xsp
	ei	0x00
SendSinglePacket_Data_Code_Epilogue:
	pop	xiz
	lda	xsp, (xsp+34)
	ret

SendSinglePacket_WriteReg:
	lda xsp, (xsp-142)
	pushw iz
	ld xiy, Smf_ChunkId_MThd
	lda xix, (xsp+136:16)
	ld bc, 2:i3
	ldirw
	ldi85
	ld xiy, Smf_ChunkId_MTrk
	lda xix, (xsp+130:16)
	ld bc, 2:i3
	ldirw
	ldi85
	ldw	(xsp+142), 0x0000
	cpw	(xsp+142), 0x0003
	jr ugt, SendSinglePacket_Block2

SendSinglePacket_DoReadNext:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cp wa, 0:i3
	jr ge, SendSinglePacket_Block
	ldw hl, 0xffff
	jrl SeqFile_Epilogue

SendSinglePacket_Block:
	ld	wa, (xsp+142)
	extz xwa
	lda xbc, (xsp+136:16)
	add xbc, xwa
	cp l, (xbc)
	jr nz, SendSinglePacket_Block2
	incw	1, (xsp+142)
	cpw	(xsp+142), 0x0003
	jr ule, SendSinglePacket_DoReadNext

SendSinglePacket_Block2:
	cpw	(xsp+142), 0x0004
	jrl z, SeqFile_SkipPadding_Init
	ld iz, 0:i3
	ld wa, 3:i3
	sub	wa, (xsp+142)
	cp iz, wa
	jr ugt, SendSinglePacket_Block3

SendSinglePacket_DoReadNext2:
	call TaskBuf_ReadNextByte
	cp hl, 0:i3
	jr ge, SendSinglePacket_Increment
	ldw hl, 0xffff
	jrl SeqFile_Epilogue

SendSinglePacket_Increment:
	inc 1, iz
	ld wa, 3:i3
	sub	wa, (xsp+142)
	cp iz, wa
	jr ule, SendSinglePacket_DoReadNext2

SendSinglePacket_Block3:
	ldw	(xsp+142), 0x0000
	cpw	(xsp+142), 0x007b
	jr ugt, SeqFile_ReadMagicInit

SeqFile_SkipHeaderBytes_Loop:
	call TaskBuf_ReadNextByte
	cp hl, 0:i3
	jr ge, SeqFile_SkipHeaderBytes_Next
	ldw hl, 0xffff
	jrl SeqFile_Epilogue

SeqFile_SkipHeaderBytes_Next:
	incw	1, (xsp+142)
	cpw	(xsp+142), 0x007b
	jr ule, SeqFile_SkipHeaderBytes_Loop

SeqFile_ReadMagicInit:
	ldw	(xsp+142), 0x0000
	cpw	(xsp+142), 0x0003
	jr ugt, SeqFile_ValidateMagicCount

SeqFile_ReadMagicByte_Loop:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cp wa, 0:i3
	jr ge, SeqFile_CheckMagicByte
	ldw hl, 0xffff
	jrl SeqFile_Epilogue

SeqFile_CheckMagicByte:
	ld	wa, (xsp+142)
	extz xwa
	lda xbc, (xsp+136:16)
	add xbc, xwa
	cp l, (xbc)
	jr nz, SeqFile_ValidateMagicCount
	incw	1, (xsp+142)
	cpw	(xsp+142), 0x0003
	jr ule, SeqFile_ReadMagicByte_Loop

SeqFile_ValidateMagicCount:
	cpw	(xsp+142), 0x0004
	jr z, SeqFile_SkipPadding_Init
	ldw hl, 0xfffe
	jrl SeqFile_Epilogue

SeqFile_SkipPadding_Init:
	ldw	(xsp+142), 0x0000
	cpw	(xsp+142), 0x0004
	jr ugt, SeqFile_ReadFormatByte

SeqFile_SkipPadding_Loop:
	call TaskBuf_ReadNextByte
	cp hl, 0:i3
	jr ge, SeqFile_SkipPadding_Next
	ldw hl, 0xffff
	jrl SeqFile_Epilogue

SeqFile_SkipPadding_Next:
	incw	1, (xsp+142)
	cpw	(xsp+142), 0x0004
	jr ule, SeqFile_SkipPadding_Loop

SeqFile_ReadFormatByte:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cp wa, 0:i3
	jr ge, SeqFile_ValidateFormat
	ldw hl, 0xffff
	jrl SeqFile_Epilogue

SeqFile_ValidateFormat:
	cp hl, 0:i3
	jr z, SeqFile_ReadTempoByte1
	ldw hl, 0xfffc
	jrl SeqFile_Epilogue

SeqFile_ReadTempoByte1:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cp wa, 0:i3
	jr ge, SeqFile_StoreTempoByte1
	ldw hl, 0xffff
	jrl SeqFile_Epilogue

SeqFile_StoreTempoByte1:
	ld a, l
	extz wa
	sla wa, 8
	ld (0xe9f1:16), wa
	call TaskBuf_ReadNextByte
	ld wa, hl
	cp wa, 0:i3
	jr ge, SeqFile_ReadTempoByte2
	ldw hl, 0xffff
	jrl SeqFile_Epilogue

SeqFile_ReadTempoByte2:
	ld a, l
	extz wa
	add (0xe9f1:16), wa
	call TaskBuf_ReadNextByte
	ld wa, hl
	cp wa, 0:i3
	jr ge, SeqFile_ReadDivisionByte1
	ldw hl, 0xffff
	jrl SeqFile_Epilogue

SeqFile_ReadDivisionByte1:
	ld a, l
	extz wa
	sla wa, 8
	ld (0xe9ef:16), wa
	call TaskBuf_ReadNextByte
	ld wa, hl
	cp wa, 0:i3
	jr ge, SeqFile_StoreDivisionByte1
	ldw hl, 0xffff
	jrl SeqFile_Epilogue

SeqFile_StoreDivisionByte1:
	ld a, l
	extz wa
	add (0xe9ef:16), wa
	ldw	(xsp+142), 0x0000
	cpw	(xsp+142), 0x0003
	jr ugt, SeqFile_ValidateTrackMagic

SeqFile_ReadTrackMagic_Loop:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cp wa, 0:i3
	jr ge, SeqFile_CheckTrackMagic
	ldw hl, 0xffff
	jr SeqFile_Epilogue

SeqFile_CheckTrackMagic:
	ld	wa, (xsp+142)
	extz xwa
	lda xbc, (xsp+130:16)
	add xbc, xwa
	cp l, (xbc)
	jr nz, SeqFile_ValidateTrackMagic
	incw	1, (xsp+142)
	cpw	(xsp+142), 0x0003
	jr ule, SeqFile_ReadTrackMagic_Loop

SeqFile_ValidateTrackMagic:
	cpw	(xsp+142), 0x0004
	jr z, SeqFile_SkipTrackPad_Init
	ldw hl, 0xfffe
	jr SeqFile_Epilogue

SeqFile_SkipTrackPad_Init:
	ldw	(xsp+142), 0x0000
	cpw	(xsp+142), 0x0003
	jr ugt, SeqFile_ReadTrackLength

SeqFile_SkipTrackPad_Loop:
	call TaskBuf_ReadNextByte
	cp hl, 0:i3
	jr ge, SeqFile_SkipTrackPad_Next
	ldw hl, 0xffff
	jr SeqFile_Epilogue

SeqFile_SkipTrackPad_Next:
	incw	1, (xsp+142)
	cpw	(xsp+142), 0x0003
	jr ule, SeqFile_SkipTrackPad_Loop

SeqFile_ReadTrackLength:
	lda xwa, (xsp+142:16)
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
	add (0xe9e7:16), xhl
	ld hl, 0:i3

SeqFile_Epilogue:
	popw iz
	lda xsp, (xsp+142:16)
	ret

SeqInit_ResetAndSetupChannels:
	calr MIDI_ResetAllChannels
	call GetPlayState1
	cp l, 0:i3
	jr z, SeqInit_SetDefaultMode
	ld wa, 1:i3
	calr SoundParam_InitDefaultBanks
	jr SeqInit_ConfigureBanks

SeqInit_SetDefaultMode:
	ld wa, 0:i3
	calr SoundParam_InitDefaultBanks

SeqInit_ConfigureBanks:
	ld xwa, 4:i3
	call SndParam_LookupReadOnly
	ld wa, hl
	exts xwa
	set 15, wa
	ld (4597:16), wa
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cp hl, 1:i3
	jr nz, ConfigureBanks_Send
	ld (4330:16), 1
	ld xwa, 0xc0
	ld bc, 1:i3
	ld de, 1:i3
	call SoundParam_NotifyChange
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz

ConfigureBanks_Send:
	ldw (0xeaf9:16), 0
	ldw (0xebfb:16), 0
	call Audio_SendEventPostCmd
	ld hl, 0:i3
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
	cp wa, 0:i3
	ret lt
	calr FileIO_ReadMultiByteRecord
	ld xwa, xhl
	cp xwa, 0x0
	jr ge, ConfigureBanks_Block
	ldw hl, 0xffff
	ret

ConfigureBanks_Block:
	add (0xe9e7:16), xhl
	jr ConfigureBanks_InitVal

ConfigureBanks_Block2:
	calr SeekRecord_Done_Prologue
	ld wa, hl
	cp wa, 0:i3
	ret lt
	calr FileIO_ReadMultiByteRecord
	ld xwa, xhl
	cp xwa, 0x0
	jr ge, ConfigureBanks_Block3
	ldw hl, 0xffff
	ret

ConfigureBanks_Block3:
	add (0xe9e7:16), xhl
	jr ConfigureBanks_InitVal

ConfigureBanks_Extend:
	extz wa
	calr SeekRecord_PopReturn_Prologue
	ld wa, hl
	cp wa, 0:i3
	ret lt
	calr FileIO_ReadMultiByteRecord
	ld xwa, xhl
	cp xwa, 0x0
	ret lt
	add (0xe9e7:16), xhl

ConfigureBanks_InitVal:
	ld hl, 0:i3
	ret

ConfigureBanks_WriteReg:
	lda xsp, (xsp-260)
	push xiz
	calr FileIO_ReadNextRecord
	ld wa, hl
	cp wa, 0:i3
	jr ge, ConfigureBanks_LoadReg2
	ldw hl, 0xffff
	jrl FileIO_SeekRecord_Done

ConfigureBanks_LoadReg2:
	ld a, l
	cp a, 0x51
	jrl z, ConfigureBanks_Block7
	cp a, 0x2f
	jr z, ConfigureBanks_Block6
	cp a, 5:i3
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
	ld xiz, 0:i3
	cp xiz, (xsp + 4)
	jr ge, ConfigureBanks_LoadAddr2

ConfigureBanks_Block5:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cp wa, 0:i3
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
	ld xwa, (0xe9e7:16)
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
	cp hl, 0:i3
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
	ld xiz, 0:i3
	cp xiz, (xsp + 4)
	jr ge, ConfigureBanks_LoadParam

ConfigureBanks_Block9:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cp wa, 0:i3
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
	ld (4597:16), wa
	ld bc, iz
	ld xwa, 4:i3
	ld de, 3:i3
	call SoundParam_NotifyChange
	call SeqTimer_UpdateTempoReg
	ld (0xe9eb:16), xiz
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
	ld xiz, 0:i3
	cp xiz, (xsp + 4)
	jr ge, FileIO_SeekRecord_LoopDone

ConfigureBanks_Block12:
	calr FileIO_ReadNextRecord
	cp hl, 0:i3
	jr ge, ConfigureBanks_NextIter
	ldw hl, 0xffff
	jr FileIO_SeekRecord_Done

ConfigureBanks_NextIter:
	inc 1, xiz
	cp xiz, (xsp + 4)
	jr lt, ConfigureBanks_Block12

FileIO_SeekRecord_LoopDone:
	ld hl, 0:i3

FileIO_SeekRecord_Done:
	pop xiz
	lda xsp, (xsp+260)
	ret

SeekRecord_Done_Prologue:
	lda xsp, (xsp - 128)
	push xiz
	calr FileIO_ReadNextRecord
	ldfr_werp HL, 0xfa
	ldto_werp WA, 0xfa
	cp wa, 0:i3
	jr ge, SeekRecord_Done_Block
	ldw hl, 0xffff
	jrl FileIO_SeekRecord_PopReturn

SeekRecord_Done_Block:
	cp_erpw 0xfa, 0x7f, 0x00
	jr le, SeekRecord_Done_LoadParam
	ld iz, 0:i3
	ldto_werp WA, 0xfa
	cp iz, wa
	jrl nc, FileIO_SeekRecord_Return

SeekRecord_Done_LoopBody:
	calr FileIO_ReadNextRecord
	cp hl, 0:i3
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
	ld iz, 0:i3
	ldto_werp WA, 0xfa
	cp iz, wa
	jr nc, SeekRecord_Done_Compare

SeekRecord_Done_LoopBody2:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cp wa, 0:i3
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
	cp hl, 1:i3
	jr nz, SeekRecord_Done_DoLookupRe
	cp (xsp + 8), 0x1
	jr nz, SeekRecord_Done_Block2

SeekRecord_Done_DoLookupRe:
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cp hl, 0:i3
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
	cp l, 0:i3
	jr z, FileIO_SeekRecord_Return
	cp (0xe9e4:16), 1
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
	ld hl, 0:i3

FileIO_SeekRecord_PopReturn:
	pop xiz
	lda xsp, (xsp+128:16)
	ret

SeekRecord_PopReturn_Prologue:
	lda xsp, (xsp - 10)
	push xiz
	ld xiy, SeekRecord_ZeroTemplate
	lda xix, (xsp + 4)
	ld bc, 5:i3
	ldirw
	bit 7, a
	jr z, SeekRecord_PopReturn_Block
	ld (0xd09c:16), a
	ld (xsp + 4), a
	ld iz, 1:i3
	jr SeekRecord_PopReturn_LoadDRAM

SeekRecord_PopReturn_Block:
	ldmi16 (xsp + 4), 0xd09c
	ld (xsp + 5), a
	ld iz, 2:i3

SeekRecord_PopReturn_LoadDRAM:
	ld a, (0xd09c:16)
	and a, 0xf0
	cp a, 0xc0
	jr z, SeekRecord_PopReturn_Block2
	cp a, 0xd0
	jr nz, SeekRecord_PopReturn_Block3

SeekRecord_PopReturn_Block2:
	ldiw_erp 0xfa, 2
	jr SeekRecord_PopReturn_Block4

SeekRecord_PopReturn_Block3:
	ldiw_erp 0xfa, 3

SeekRecord_PopReturn_Block4:
	cpw_erp IZ, 0xfa
	jr nc, SeekRecord_PopReturn_LoadAddr

SeekRecord_PopReturn_LoopBody:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cp wa, 0:i3
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
	cpw_erp IZ, 0xfa
	jr c, SeekRecord_PopReturn_LoopBody

SeekRecord_PopReturn_LoadAddr:
	lda xwa, (xsp + 4)
	ld xbc, xwa
	ldto_werp WA, 0xfa
	calr MIDI_SendSinglePacket
	ld hl, 0:i3

SeekRecord_PopReturn_Epilogue:
	pop xiz
	lda xsp, (xsp + 10)
	ret

SeekRecord_PopReturn_Data:
	ld	hl, 0:i3
	ret

SeqFile_ParseHeader:
	pushw iz
	ld iz, 0:i3
	cp (0xe9c4:16), 0
	jr nz, SeqFile_ParseHeader_Block2
	ld hl, 0:i3
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
	cp wa, 0:i3
	jr z, SeqFile_ParseHeader_Block

SeqFile_ParseHeader_Block3:
	calr SysexRingBuf_GetFreeSpace
	cp hl, 0:i3
	call gt, (Audio_SendEventPostCmd:24)
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
	cp wa, 0:i3
	jr ge, SeqFile_ReadTrackDat_LoadIter
	ld xwa, (xsp + 2)
	ld (xwa), 0x0
	jr SeqFile_ReadTrackDat_RestoreReg

SeqFile_ReadTrackDat_LoadIter:
	ld wa, iz
	ld xbc, (xsp + 2)
	calr SysexRingBuf_ReadBytes
	cp hl, 0:i3
	jr ge, SeqFile_ReadTrackDat_LoadParam
	ld xwa, (xsp + 2)
	ld (xwa), 0x0
	jr SeqFile_ReadTrackDat_RestoreReg

SeqFile_ReadTrackDat_LoadParam:
	ld xwa, (xsp + 2)
	ld	(xwa+iz), 0x00

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
	cp wa, 0:i3
	jr ge, SeqFile_ValidateAndS_LoadIter
	ld xwa, (xsp + 2)
	ld (xwa), 0x0
	jr SeqFile_ValidateAndS_RestoreReg

SeqFile_ValidateAndS_LoadIter:
	ld wa, iz
	ld xbc, (xsp + 2)
	calr StoreAndAdvance_Prologue
	cp hl, 0:i3
	jr ge, SeqFile_ValidateAndS_LoadParam
	ld xwa, (xsp + 2)
	ld (xwa), 0x0
	jr SeqFile_ValidateAndS_RestoreReg

SeqFile_ValidateAndS_LoadParam:
	ld xwa, (xsp + 2)
	ld	(xwa+iz), 0x00

SeqFile_ValidateAndS_RestoreReg:
	popw iz
	inc 4, xsp
	ret

SongFile_DecodeMidiEvent:
	lda xsp, (xsp-528)
	pushw iz
	ld iz, 0:i3
	ld xwa, 0:i3
	ld (xsp + 6), xwa
	ldw (xsp + 10), 0x0
	cpw (0xebfb:16), 0
	jr z, DecodeMidiEvent_Block2
	ld de, (0xebfb:16)
	lda xwa, (0xeafb:16)
	ld xbc, xwa
	ld wa, de
	calr MidiRingBuf_WriteBytes
	cp hl, 0:i3
	jr ge, DecodeMidiEvent_Block
	ldw hl, 0xfffd
	jrl SeqPlay_Epilogue

DecodeMidiEvent_Block:
	ldw (0xebfb:16), 0

DecodeMidiEvent_Block2:
	cpw (0xeaf9:16), 0
	jr z, DecodeMidiEvent_LoadDRAM
	ld de, (0xeaf9:16)
	lda xwa, (0xe9f9:16)
	ld xbc, xwa
	ld wa, de
	calr SysexRingBuf_WriteBytes
	cp hl, 0:i3
	jr ge, DecodeMidiEvent_Send
	ldw hl, 0xfffd
	jrl SeqPlay_Epilogue

DecodeMidiEvent_Send:
	call Audio_SendEventPostCmd
	ldw (0xeaf9:16), 0

DecodeMidiEvent_LoadDRAM:
	ld wa, (0xe9e5:16)
	bit 4, wa
	jr z, DecodeMidiEvent_DoReadNext
	ldw hl, 0xfffd
	jrl SeqPlay_Epilogue

DecodeMidiEvent_DoReadNext:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cp wa, 0:i3
	jr ge, DecodeMidiEvent_LoadParam
	ldw hl, 0xffff
	jrl SeqPlay_Epilogue

DecodeMidiEvent_LoadParam:
	ld wa, (xsp + 10)
	incw 1, (xsp + 10)
	lda xbc, (xsp + 12)
	ld	(xbc+wa), l
	ld wa, (xsp + 10)
	lda xbc, (xsp + 11)
	ld	a, (xbc+wa)
	cp a, 0xf7
	jrl z, DecodeMidiEvent_DoReadNext3
	cp a, 0xf0
	jrl z, DecodeMidiEvent_DoReadNext3
	cp a, 0xff
	jrl nz, SeqPlay_CheckBit7Path
	call TaskBuf_ReadNextByte
	ld wa, hl
	cp wa, 0:i3
	jr ge, DecodeMidiEvent_LoadParam2
	ldw hl, 0xffff
	jrl SeqPlay_Epilogue

DecodeMidiEvent_LoadParam2:
	ld wa, (xsp + 10)
	incw 1, (xsp + 10)
	lda xbc, (xsp + 12)
	ld	(xbc+wa), l
	ld wa, (xsp + 10)
	lda xbc, (xsp + 11)
	ld	a, (xbc+wa)
	cp a, 0x2f
	jr nz, DecodeMidiEvent_LoadAddr
	call TaskBuf_ReadNextByte
	ld wa, hl
	cp wa, 0:i3
	jr ge, DecodeMidiEvent_LoadParam3
	ldw hl, 0xffff
	jrl SeqPlay_Epilogue

DecodeMidiEvent_LoadParam3:
	ld wa, (xsp + 10)
	incw 1, (xsp + 10)
	lda xbc, (xsp + 12)
	ld	(xbc+wa), l
	orw (0xe9e5:16), 16
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
	ld iz, 0:i3
	ld wa, iz
	extz xwa
	cp xwa, (xsp + 2)
	jr ge, DecodeMidiEvent_LoadParam5

DecodeMidiEvent_DoReadNext2:
	call TaskBuf_ReadNextByte
	cp hl, 0:i3
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
	lda xwa, (xsp+272)
	ld xbc, xwa
	ld wa, de
	calr ReadVariableLengthDa_Prologue
	cp hl, 0:i3
	jr ge, DecodeMidiEvent_LoadParam7
	ldw hl, 0xffff
	jrl SeqPlay_Epilogue

DecodeMidiEvent_LoadParam7:
	ld xwa, (xsp + 2)
	pushw wa
	lda xwa, (xsp+274)
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
	cp wa, 0:i3
	jr ge, DecodeMidiEvent_LoadParam8
	ldw hl, 0xffff
	jrl SeqPlay_Epilogue

DecodeMidiEvent_LoadParam8:
	ld wa, (xsp + 10)
	incw 1, (xsp + 10)
	lda xbc, (xsp + 12)
	ld	(xbc+wa), l
	ld wa, (xsp + 10)
	lda xbc, (xsp + 11)
	ld	a, (xbc+wa)
	ld e, a
	extz de
	lda xwa, (xsp+272)
	ld xbc, xwa
	ld wa, de
	calr ReadVariableLengthDa_Prologue
	cp hl, 0:i3
	jr ge, DecodeMidiEvent_LoadParam9
	ldw hl, 0xffff
	jrl SeqPlay_Epilogue

DecodeMidiEvent_LoadParam9:
	ld wa, (xsp + 10)
	lda xbc, (xsp + 11)
	ld	a, (xbc+wa)
	extz wa
	pushw wa
	lda xwa, (xsp+274)
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
	ld	a, (xbc+wa)
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
	ld	a, (xde+wa)
	ld (xhl), a
	ld wa, (xsp + 10)
	lda xbc, (xsp + 11)
	ld	(xbc+wa), (0xec10:16)
	incw 1, (xsp + 10)

SeqPlay_CheckStatusByte:
	ld a, (0xec10:16)
	and a, 0xf0
	cp a, 0xc0
	jr z, SeqPlay_TwoByteMsg
	cp a, 0xd0
	jr nz, SeqPlay_ThreeByteMsg

SeqPlay_TwoByteMsg:
	ld xwa, 2:i3
	ld (xsp + 2), xwa
	jr SeqPlay_ReadRemainingBytes

SeqPlay_ThreeByteMsg:
	ld xwa, 3:i3
	ld (xsp + 2), xwa

SeqPlay_ReadRemainingBytes:
	ld wa, (xsp + 10)
	exts xwa
	cp xwa, (xsp + 2)
	jr ge, SeqPlay_ReadRecord_Entry

SeqPlay_ReadByte_Loop:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cp wa, 0:i3
	jr ge, SeqPlay_StoreByte
	ldw hl, 0xffff
	jrl SeqPlay_Epilogue

SeqPlay_StoreByte:
	lda xwa, (xsp + 12)
	ld bc, (xsp + 10)
	extz xbc
	add xbc, xwa
	ld (xbc), l
	incw 1, (xsp + 10)
	ld wa, (xsp + 10)
	exts xwa
	cp xwa, (xsp + 2)
	jr lt, SeqPlay_ReadByte_Loop

SeqPlay_ReadRecord_Entry:
	ldw	(xsp+270), 0x0000
	ld xwa, (0xe9f5:16)
	ld (xsp + 6), xwa
	ld wa, (0xe9e5:16)
	bit 4, wa
	jr nz, SeqPlay_CheckSysExMarker
	lda xwa, (xsp+270)
	ld xde, xwa
	lda xwa, (xsp+272)
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
	add (0xe9f5:16), xwa

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
	lda xwa, (0xe9f9:16)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld wa, (xsp + 10)
	ld (0xeaf9:16), wa
	jr SeqPlay_CopyToMidiBuffer

SeqVoice_InitZeroPath:
	ldw (0xeaf9:16), 0

SeqPlay_CopyToMidiBuffer:
	ld wa, (xsp + 10)
	pushw wa
	lda xwa, (xsp + 14)
	push xwa
	lda xwa, (0xeafb:16)
	push xwa
	call Mem_Copy
	ld wa, (xsp + 20)
	ld (0xebfb:16), wa
	ld	wa, (xsp+280)
	pushw wa
	lda xwa, (xsp+284)
	push xwa
	ld wa, (0xebfb:16)
	add wa, 0x137
	lda xbc, (0xe9c4:16)
	exts xwa
	add xwa, xbc
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 20)
	ld	wa, (xsp+270)
	add (0xebfb:16), wa
	cpw (0xeaf9:16), 0
	jr z, SeqPlay_CheckMidiBuffer
	ld wa, (0xeaf9:16)
	dec 2, wa
	ld de, wa
	lda xwa, (0xe9fb:16)
	ld xbc, xwa
	ld wa, de
	calr SysexRingBuf_WriteBytes
	cp hl, 0:i3
	jr ge, SeqPlay_SendEvent
	ldw hl, 0xfffd
	jr SeqPlay_Epilogue

SeqPlay_SendEvent:
	call Audio_SendEventPostCmd
	ldw (0xeaf9:16), 0

SeqPlay_CheckMidiBuffer:
	cpw (0xebfb:16), 0
	jr z, SeqPlay_SetSuccess
	ld de, (0xebfb:16)
	lda xwa, (0xeafb:16)
	ld xbc, xwa
	ld wa, de
	calr MidiRingBuf_WriteBytes
	cp hl, 0:i3
	jr ge, SeqPlay_ClearMidiCount
	ldw hl, 0xfffd
	jr SeqPlay_Epilogue

SeqPlay_ClearMidiCount:
	ldw (0xebfb:16), 0

SeqPlay_SetSuccess:
	ld hl, 0:i3

SeqPlay_Epilogue:
	popw iz
	lda xsp, (xsp+528)
	ret

SeqPlay_ReadFileRecord:
	lda xsp, (xsp - 14)
	pushw iz
	ld xiy, ESeq_FileSignature
	lda xix, (xsp + 6)
	ld bc, 4:i3
	ldirw
	ldi85
	ld xwa, 0:i3
	ld (xsp + 2), xwa
	calr FileIO_ReadNextRecord
	ld wa, hl
	cp wa, 0:i3
	jr ge, SeqPlay_RecordReadOK
	ldw hl, 0xffff
	jrl FileIO_Epilogue

SeqPlay_RecordReadOK:
	cp l, 0xfe
	jr z, RecordReadOK_Block
	ldw hl, 0xfffe
	jrl FileIO_Epilogue

RecordReadOK_Block:
	ld xwa, 0:i3
	ld (0xe9eb:16), xwa
	ld iz, 0:i3
	cp iz, 6:i3
	jr nc, RecordReadOK_InitVal

RecordReadOK_LoopBody:
	calr FileIO_ReadNextRecord
	cp hl, 0:i3
	jr ge, RecordReadOK_LoopCheck
	ldw hl, 0xffff
	jrl FileIO_Epilogue

RecordReadOK_LoopCheck:
	inc 1, iz
	cp iz, 6:i3
	jr c, RecordReadOK_LoopBody

RecordReadOK_InitVal:
	ld iz, 0:i3
	cp iz, 0x8
	jr nc, RecordReadOK_InitVal2

RecordReadOK_LoopBody2:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cp wa, 0:i3
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
	ld iz, 0:i3
	cp iz, 0xa
	jr nc, RecordReadOK_Block2

RecordReadOK_LoopBody3:
	calr FileIO_ReadNextRecord
	cp hl, 0:i3
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
	cp wa, 0:i3
	jr ge, RecordReadOK_LoadReg
	ldw hl, 0xffff
	jrl FileIO_Epilogue

RecordReadOK_LoadReg:
	ld a, l
	cp a, 0x40
	jr z, RecordReadOK_Block3
	cp a, 0x21
	jr nz, RecordReadOK_SetWord
	ld (0xe9e4:16), 2

RecordReadOK_InitVal3:
	ld iz, 0:i3
	cp iz, 1:i3
	jr nc, RecordReadOK_InitVal4

RecordReadOK_LoopBody4:
	calr FileIO_ReadNextRecord
	cp hl, 0:i3
	jr ge, RecordReadOK_LoopCheck4
	ldw hl, 0xffff
	jrl FileIO_Epilogue

RecordReadOK_Block3:
	ld (0xe9e4:16), 3
	jr RecordReadOK_InitVal3

RecordReadOK_SetWord:
	ldw hl, 0xfffe
	jrl FileIO_Epilogue

RecordReadOK_LoopCheck4:
	inc 1, iz
	cp iz, 1:i3
	jr c, RecordReadOK_LoopBody4

RecordReadOK_InitVal4:
	ld iz, 0:i3
	cp iz, 3:i3
	jr ugt, RecordReadOK_InitVal5

RecordReadOK_Block4:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cp wa, 0:i3
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
	ld xwa, 0:i3
	ld a, c
	add (xsp + 2), xwa
	inc 1, iz
	cp iz, 3:i3
	jr ule, RecordReadOK_Block4

RecordReadOK_InitVal5:
	ld iz, 0:i3
	cp iz, 3:i3
	jr ugt, RecordReadOK_Block7

RecordReadOK_Block6:
	calr FileIO_ReadNextRecord
	cp hl, 0:i3
	jr ge, RecordReadOK_NextIter
	ldw hl, 0xffff
	jrl FileIO_Epilogue

RecordReadOK_NextIter:
	inc 1, iz
	cp iz, 3:i3
	jr ule, RecordReadOK_Block6

RecordReadOK_Block7:
	ldw (0xe9ef:16), 384
	calr FileIO_ReadNextRecord
	ld wa, hl
	cp wa, 0:i3
	jr ge, RecordReadOK_LoadReg2
	ldw hl, 0xffff
	jrl FileIO_Epilogue

RecordReadOK_LoadReg2:
	ld a, l
	extz wa
	ld (0xe9f1:16), wa
	calr FileIO_ReadNextRecord
	ld wa, hl
	cp wa, 0:i3
	jr ge, RecordReadOK_LoadReg3
	ldw hl, 0xffff
	jrl FileIO_Epilogue

RecordReadOK_LoadReg3:
	ld a, l
	add a, 0x1d
	ld w, 0x0:opc
	extz xwa
	ld (0xe9eb:16), xwa
	ld iz, 0:i3
	cp iz, 1:i3
	jr ugt, RecordReadOK_CheckDRAM

RecordReadOK_Block8:
	calr FileIO_ReadNextRecord
	cp hl, 0:i3
	jr ge, RecordReadOK_NextIter2
	ldw hl, 0xffff
	jrl FileIO_Epilogue

RecordReadOK_NextIter2:
	inc 1, iz
	cp iz, 1:i3
	jr ule, RecordReadOK_Block8

RecordReadOK_CheckDRAM:
	cp (0xe9e4:16), 3
	jr nz, RecordReadOK_InitVal6
	ld xwa, (xsp + 2)
	cp xwa, 0xc
	jr ule, RecordReadOK_InitVal6
	ld iz, 0:i3
	cp iz, 0xc
	jr nc, RecordReadOK_Block9

RecordReadOK_LoopBody5:
	calr FileIO_ReadNextRecord
	cp hl, 0:i3
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
	cp wa, 0:i3
	jr ge, RecordReadOK_LoadReg4
	ldw hl, 0xffff
	jrl FileIO_Epilogue

RecordReadOK_LoadReg4:
	ld a, l
	add a, 0x1d
	ld w, 0x0:opc
	extz xwa
	ld (0xe9eb:16), xwa
	ld iz, 0:i3
	jr RecordReadOK_LoopCheck6

RecordReadOK_LoopBody6:
	calr FileIO_ReadNextRecord
	cp hl, 0:i3
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
	ld iz, 0:i3
	ld wa, iz
	extz xwa
	cp xwa, (xsp + 2)
	jr nc, RecordReadOK_Block10

RecordReadOK_LoopBody7:
	calr FileIO_ReadNextRecord
	cp hl, 0:i3
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
	cp wa, 0:i3
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
	cp hl, 0:i3
	jr ge, RecordReadOK_Block12
	ldw hl, 0xffff
	jr FileIO_Epilogue

RecordReadOK_Block12:
	lda xde, (0xe9eb:16)
	ld xbc, 0x28
	ld xwa, (0xe9eb:16)
	cp xwa, 0x28
	jr ule, RecordReadOK_LoadReg5
	ld xbc, (0xe9eb:16)

RecordReadOK_LoadReg5:
	ld (xde), xbc
	lda xde, (0xe9eb:16)
	ld xbc, 0x12c
	ld xwa, (0xe9eb:16)
	cp xwa, 0x12c
	jr nc, RecordReadOK_LoadReg6
	ld xbc, (0xe9eb:16)

RecordReadOK_LoadReg6:
	ld (xde), xbc
	ld xwa, (0xe9eb:16)
	ld bc, wa
	ld xwa, 4:i3
	ld de, 3:i3
	call SoundParam_NotifyChange
	call SeqTimer_UpdateTempoReg
	ld xwa, 0:i3
	ld (0xe9e7:16), xwa
	ld hl, 0:i3

FileIO_Epilogue:
	popw iz
	lda xsp, (xsp + 14)
	ret

Epilogue_Prologue:
	pushw iz
	calr MIDI_ResetAllChannels
	ld wa, 2:i3
	calr SoundParam_InitDefaultBanks
	ld xwa, 4:i3
	call SndParam_LookupReadOnly
	ld wa, hl
	exts xwa
	set 15, wa
	ld (4597:16), wa
	pushw 0x2
	ld wa, 0:i3
	ld bc, 0:i3
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ld wa, 0:i3
	ldw bc, 0x20
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ld wa, 0:i3
	ld bc, 7:i3
	ldw de, 0x78
	call SndParam_NotifyAndReturn
	pushw 0x2
	ld wa, 1:i3
	ld bc, 0:i3
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ld wa, 1:i3
	ldw bc, 0x20
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ld wa, 1:i3
	ld bc, 7:i3
	ldw de, 0x78
	call SndParam_NotifyAndReturn
	ldw wa, 0x63
	ldw bc, 0x14
	call SysEx_ApplyAndReloadPreset
	ld (0xfc94:16), 80
	ld iz, 0:i3
	cp iz, 0x8
	jr ge, Epilogue_InitVal

Epilogue_LoadReg:
	ld bc, iz
	lda xwa, (0xfc8e:16)
	ld	a, (xwa+iz)
	extz wa
	pushw 0xff
	ld de, wa
	ldw wa, 0x63
	call AssswbWr
	inc 1, iz
	cp iz, 0x8
	jr lt, Epilogue_LoadReg

Epilogue_InitVal:
	ld iz, 0:i3
	cp iz, 0x10
	jr ge, Epilogue_Block

Epilogue_LoadIter:
	ld wa, iz
	pushw 0x2
	ldw bc, 0x80
	ld de, 3:i3
	call SndParam_NotifyAndReturn
	inc 1, iz
	cp iz, 0x10
	jr lt, Epilogue_LoadIter

Epilogue_Block:
	ld xwa, 0:i3
	ld (0xebfd:16), xwa
	ldw (0xec01:16), 0
	ld hl, 0:i3
	popw iz
	ret

Epilogue_Prologue2:
	pushw iz
	calr MIDI_ResetAllChannels
	ld wa, 2:i3
	calr SoundParam_InitDefaultBanks
	ld xwa, 4:i3
	call SndParam_LookupReadOnly
	ld wa, hl
	exts xwa
	set 15, wa
	ld (4597:16), wa
	pushw 0x2
	ld wa, 0:i3
	ld bc, 0:i3
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ld wa, 0:i3
	ldw bc, 0x20
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ld wa, 1:i3
	ld bc, 0:i3
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ld wa, 1:i3
	ldw bc, 0x20
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ld wa, 2:i3
	ld bc, 0:i3
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ld wa, 2:i3
	ldw bc, 0x20
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ld wa, 3:i3
	ld bc, 0:i3
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ld wa, 3:i3
	ldw bc, 0x20
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ld wa, 4:i3
	ld bc, 0:i3
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ld wa, 4:i3
	ldw bc, 0x20
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ld wa, 5:i3
	ld bc, 0:i3
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ld wa, 5:i3
	ldw bc, 0x20
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ld wa, 6:i3
	ld bc, 0:i3
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ld wa, 6:i3
	ldw bc, 0x20
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ld wa, 7:i3
	ld bc, 0:i3
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ld wa, 7:i3
	ldw bc, 0x20
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0x8
	ld bc, 0:i3
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0x8
	ldw bc, 0x20
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0x9
	ld bc, 0:i3
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0x9
	ldw bc, 0x20
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xa
	ld bc, 0:i3
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xa
	ldw bc, 0x20
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xb
	ld bc, 0:i3
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xb
	ldw bc, 0x20
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xc
	ld bc, 0:i3
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xc
	ldw bc, 0x20
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xd
	ld bc, 0:i3
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xd
	ldw bc, 0x20
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xe
	ld bc, 0:i3
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xe
	ldw bc, 0x20
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xf
	ld bc, 0:i3
	ldw de, 0xf0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xf
	ldw bc, 0x20
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	ldw wa, 0x63
	ldw bc, 0x14
	call SysEx_ApplyAndReloadPreset
	ld (0xfc94:16), 80
	ld iz, 0:i3
	cp iz, 0x8
	jr ge, Epilogue_InitVal2

Epilogue_LoadReg2:
	ld bc, iz
	lda xwa, (0xfc8e:16)
	ld	a, (xwa+iz)
	extz wa
	pushw 0xff
	ld de, wa
	ldw wa, 0x63
	call AssswbWr
	inc 1, iz
	cp iz, 0x8
	jr lt, Epilogue_LoadReg2

Epilogue_InitVal2:
	ld iz, 0:i3
	cp iz, 0x10
	jr ge, Epilogue_InitVal3

Epilogue_LoadIter2:
	ld wa, iz
	pushw 0x2
	ldw bc, 0x80
	ld de, 3:i3
	call SndParam_NotifyAndReturn
	inc 1, iz
	cp iz, 0x10
	jr lt, Epilogue_LoadIter2

Epilogue_InitVal3:
	ld hl, 0:i3
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
	cp wa, 0:i3
	jrl lt, Dispatch_InitVal2
	cp wa, 0xf
	jrl gt, Dispatch_InitVal2
	add wa, wa
	lda xix, (MidiSysMsg_SwitchOffsets:24)
	ld	wa, (xix+wa)
	lda xix, (MidiSysMsg_Dispatch:24)
	jp	t, (xix+wa)

; MIDI system message dispatch (15-entry, table 0xeec1e8)
MidiSysMsg_Dispatch:
	calr	FileIO_ReadNextRecord
	ld	wa, hl
	cp	wa, 0:i3
	jr	ge, MidiSysMsg_Handler_Skip
	ldw	hl, 0xffff
	jrl	Dispatch_Epilogue
MidiSysMsg_Handler_Skip:
	cp	l, 247
	jr	nz, MidiSysMsg_Dispatch
	jrl	Dispatch_InitVal2
	ld	iz, 0:i3
	cp	iz, 1:i3
	jrl	ge, Dispatch_InitVal2
MidiSysMsg_Handler_Loop:
	calr	FileIO_ReadNextRecord
	cp	hl, 0:i3
	jr	ge, MidiSysMsg_Handler_Skip2
	ldw	hl, 0xffff
	jrl	Dispatch_Epilogue
MidiSysMsg_Handler_Skip2:
	inc	1, iz
	cp	iz, 1:i3
	jr	lt, MidiSysMsg_Handler_Loop
	jrl	Dispatch_InitVal2
	ldw	hl, 0xfffd
	jrl	Dispatch_Epilogue
	ld	iz, 0:i3
	cp	iz, 1:i3
	jr	ge, MidiSysMsg_Handler_Skip4
MidiSysMsg_Handler_Loop2:
	calr	FileIO_ReadNextRecord
	ld	wa, hl
	cp	wa, 0:i3
	jr	ge, MidiSysMsg_Handler_Skip3
	ldw	hl, 0xffff
	jrl	Dispatch_Epilogue
MidiSysMsg_Handler_Skip3:
	lda	xwa, (xsp+4)
	ld	(xwa+iz), l
	inc	1, iz
	cp	iz, 1:i3
	jr	lt, MidiSysMsg_Handler_Loop2
MidiSysMsg_Handler_Skip4:
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ldw	wa, 243
	calr	Dispatch_Data
	add	(0xe9e7:16), xhl
	jrl	Dispatch_InitVal2
	ld	iz, 0:i3
	cp	iz, 2:i3
	jr	ge, MidiSysMsg_Handler_Skip6
MidiSysMsg_Handler_Loop3:
	calr	FileIO_ReadNextRecord
	ld	wa, hl
	cp	wa, 0:i3
	jr	ge, MidiSysMsg_Handler_Skip5
	ldw	hl, 0xffff
	jrl	Dispatch_Epilogue
MidiSysMsg_Handler_Skip5:
	lda	xwa, (xsp+4)
	ld	(xwa+iz), l
	inc	1, iz
	cp	iz, 2:i3
	jr	lt, MidiSysMsg_Handler_Loop3
MidiSysMsg_Handler_Skip6:
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ldw	wa, 244
	calr	Dispatch_Data
	add	(0xe9e7:16), xhl
	jrl	Dispatch_InitVal2
	ld	iz, 0:i3
	cp	iz, 2:i3
	jrl	ge, Dispatch_InitVal2
MidiSysMsg_Handler_Loop4:
	calr	FileIO_ReadNextRecord
	cp	hl, 0:i3
	jr	ge, MidiSysMsg_Handler_Skip7
	ldw	hl, 0xffff
	jrl	Dispatch_Epilogue
MidiSysMsg_Handler_Skip7:
	inc	1, iz
	cp	iz, 2:i3
	jr	lt, MidiSysMsg_Handler_Loop4
	jrl	Dispatch_InitVal2
	ld	iz, 0:i3
	cp	iz, 2:i3
	jr	ge, MidiSysMsg_Handler_Skip9
MidiSysMsg_Handler_Loop5:
	calr	FileIO_ReadNextRecord
	ld	wa, hl
	cp	wa, 0:i3
	jr	ge, MidiSysMsg_Handler_Skip8
	ldw	hl, 0xffff
	jrl	Dispatch_Epilogue
MidiSysMsg_Handler_Skip8:
	lda	xwa, (xsp+4)
	ld	(xwa+iz), l
	inc	1, iz
	cp	iz, 2:i3
	jr	lt, MidiSysMsg_Handler_Loop5
MidiSysMsg_Handler_Skip9:
	lda	xwa, (xsp+4)
	calr	MidiSysMsg_Handler_Helper
	jr	Dispatch_InitVal2
	ld	iz, 0:i3
	cp	iz, 2:i3
	jr	ge, Dispatch_InitVal2
MidiSysMsg_Handler_Loop6:
	calr	FileIO_ReadNextRecord
	cp	hl, 0:i3
	jr	ge, MidiSysMsg_Handler_Skip10
	ldw	hl, 0xffff
	jr	Dispatch_Epilogue
MidiSysMsg_Handler_Skip10:
	inc	1, iz
	cp	iz, 2:i3
	jr	lt, MidiSysMsg_Handler_Loop6
	jr	Dispatch_InitVal2
MidiSysMsg_Handler_Loop7:
	calr	FileIO_ReadNextRecord
	ld	wa, hl
	cp	wa, 0:i3
	jr	ge, MidiSysMsg_Handler_Skip11
	ldw	hl, 0xffff
	jr	Dispatch_Epilogue
MidiSysMsg_Handler_Skip11:
	cp	l, 247
	jr	nz, MidiSysMsg_Handler_Loop7
	jr	Dispatch_InitVal2

Dispatch_LoadParam:
	ld (xsp + 4), a
	and a, 0xf0
	cp a, 0xc0
	jr z, Dispatch_Block
	cp a, 0xd0
	jr nz, Dispatch_Block2

Dispatch_Block:
	ldiw_erp 0xfa, 2
	jr Dispatch_InitVal

Dispatch_Block2:
	ldiw_erp 0xfa, 3

Dispatch_InitVal:
	ld iz, 1:i3
	cpw_erp IZ, 0xfa
	jr ge, Dispatch_LoadAddr2

Dispatch_Block3:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cp wa, 0:i3
	jr ge, Dispatch_LoadAddr
	ldw hl, 0xffff
	jr Dispatch_Epilogue

Dispatch_LoadAddr:
	lda xwa, (xsp + 4)
	ld	(xwa+iz), l
	inc 1, iz
	cpw_erp IZ, 0xfa
	jr lt, Dispatch_Block3

Dispatch_LoadAddr2:
	lda xwa, (xsp + 4)
	calr Dispatch_Prologue

Dispatch_InitVal2:
	ld hl, 0:i3

Dispatch_Epilogue:
	pop xiz
	lda xsp, (xsp + 10)
	ret

Dispatch_Data:
	cp	a, 244
	jr	z, Dispatch_Data_Skip
	cp	a, 243
	jr	nz, Dispatch_Data_Skip2
	ld	l, (xbc)
	res	7, l
	ld	h, 0:opc
	extz	xhl
	jr	Dispatch_Data_Return
Dispatch_Data_Skip:
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
	jr	Dispatch_Data_Return
Dispatch_Data_Skip2:
	ld	xhl, 0:i3
Dispatch_Data_Return:
	ret
MidiSysMsg_Handler_Helper:
	push	xiz
	ld	xbc, (0xe9eb:16)
	or	xbc, xbc
	jrl	z, Dispatch_Data_Epilogue
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
	ld	xwa, 0:i3
	ld	a, e
	add	xiz, xwa
	ld	xwa, xiz
	ld	xbc, (0xe9eb:16)
	call	Math_MultiplyAccumulate
	ld	xiz, xhl
	ld	xwa, xiz
	ld	xbc, 1000
	call	Math_DivideU32
	ld	xiz, xhl
	ld	xwa, 40
	cp	xiz, 40
	jr	ule, Dispatch_Data_Skip3
	ld	xwa, xiz
Dispatch_Data_Skip3:
	ld	xiz, xwa
	ld	xwa, 300
	cp	xiz, 300
	jr	nc, Dispatch_Data_Skip4
	ld	xwa, xiz
Dispatch_Data_Skip4:
	ld	xiz, xwa
	cp	xiz, 0x100
	jr	nc, Dispatch_Data_Entry
	res	0, (0xfc63:16)
	jr	Dispatch_Data_Join
Dispatch_Data_Entry:
	set	0, (0xfc63:16)
Dispatch_Data_Join:
	ld	wa, iz
	ld	bc, wa
	ld	xwa, 4:i3
	ld	de, 3:i3
	call	SoundParam_NotifyChange
	call	SeqTimer_UpdateTempoReg
	ld	xwa, xiz
	set	15, wa
	ld	(4597:16), wa
Dispatch_Data_Epilogue:
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
	ld wa, 3:i3
	calr MIDI_SendSinglePacket
	ld (xsp + 5), 0x20
	ld a, (xsp + 10)
	and a, 0x7
	sll a, 4
	ld (xsp + 6), a
	lda xwa, (xsp + 4)
	ld xbc, xwa
	ld wa, 3:i3
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
	ld wa, 2:i3
	calr MIDI_SendSinglePacket
	jr ToneGen_PopIzStackReturn

ToneGen_CheckSpecialChannel:
	cp (0xe9e4:16), 2
	jr nz, ToneGen_SendPacketDirect
	ld a, (xiz)
	and a, 0xf
	cp a, 0xe
	jr nz, ToneGen_SendPacketDirect
	ld a, (xiz + 1)
	extz wa
	pushw wa
	ld wa, 5:i3
	ldw bc, 0xf0
	ld de, 0:i3
	call SndParam_LookupByChannel
	ld (xiz + 1), l
	ld xbc, xiz
	ld wa, 3:i3
	calr MIDI_SendSinglePacket
	jr ToneGen_CheckVelocityRepeat

ToneGen_SendPacketDirect:
	ld xbc, xiz
	ld wa, 3:i3
	calr MIDI_SendSinglePacket

ToneGen_CheckVelocityRepeat:
	ld wa, 0:i3
	cp wa, 0:i3
	jr z, ToneGen_CheckZeroVelocity
	cp (xiz + 2), 0x0
	jr z, ToneGen_ResendPacket

ToneGen_CheckZeroVelocity:
	ld wa, 0:i3
	cp wa, 0:i3
	jr z, ToneGen_PopIzStackReturn

ToneGen_ResendPacket:
	ld xbc, xiz
	ld wa, 3:i3
	calr MIDI_SendSinglePacket
	jr ToneGen_PopIzStackReturn

ToneGen_SendAndReturn:
	ld xbc, xiz
	ld wa, 3:i3
	calr MIDI_SendSinglePacket

ToneGen_PopIzStackReturn:
	pop xiz
	lda xsp, (xsp + 10)
	ret

ToneGen_ReadFileRecord:
	push xiz
	ldw (0xe9ef:16), 480
	calr FileIO_ReadNextRecord
	ld wa, hl
	cp wa, 0:i3
	jr ge, ToneGen_CheckRecordType
	ldw hl, 0xffff
	jr ToneGen_PopIzReturn

ToneGen_CheckRecordType:
	ld a, l
	cp a, 0xfe
	jr nz, ToneGen_SignExtendDelta
	calr FileIO_ReadNextRecord
	ld wa, hl
	cp wa, 0:i3
	jr ge, ToneGen_ReadExtendedDelta
	ldw hl, 0xffff
	jr ToneGen_PopIzReturn

ToneGen_ReadExtendedDelta:
	ld xiz, 0:i3
	ldfr_berp L, 0xf8
	calr FileIO_ReadNextRecord
	ld wa, hl
	cp wa, 0:i3
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
	add (0xe9e7:16), xiz
	ld hl, 0:i3

ToneGen_PopIzReturn:
	pop xiz
	ret

ToneGen_ResetAndInitBanks:
	calr MIDI_ResetAllChannels
	ld (4330:16), 1
	ld wa, 1:i3
	calr SoundParam_InitDefaultBanks
	ldw (4597:16), 0x8078
	ld xwa, 4:i3
	ldw bc, 0x76
	ld de, 3:i3
	call SoundParam_NotifyChange
	call SeqTimer_UpdateTempoReg
	pushw 0x2
	ld wa, 0:i3
	ld bc, 0:i3
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ld wa, 0:i3
	ldw bc, 0x20
	ld de, 0:i3
	call SndParam_NotifyAndReturn
	pushw 0x2
	ld wa, 0:i3
	ld bc, 7:i3
	ldw de, 0x7f
	call SndParam_NotifyAndReturn
	ld hl, 0:i3
	ret

MidiRealtime_ReadAndProcess:
	lda xsp, (xsp - 128)
	pushw iz
	ld iz, 0:i3
	ld iz, 0:i3
	ld bc, (0xe9e5:16)
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
	orw (0xe9e5:16), 16
	jrl MidiRealtime_StopAndReturn

MidiRealtime_SysExStart:
	ld iz, 1:i3
	lda xbc, (xsp + 1)
	ld	(xbc+iz), a

MidiRealtime_SysExReadLoop:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cp wa, 0:i3
	jr ge, MidiRealtime_SysExCheckEnd
	ldw hl, 0xffff
	jrl MidiRealtime_ProcessByte

MidiRealtime_SysExCheckEnd:
	inc 1, iz
	cp iz, 0x80
	jr ge, MidiRealtime_SysExCheckF7
	lda xwa, (xsp + 1)
	ld c, l
	ld	(xwa+iz), c

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
	cp wa, 0:i3
	jr ge, MidiRealtime_SysExOv_LoadReg
	ldw hl, 0xffff
	jrl MidiRealtime_ProcessByte

MidiRealtime_SysExOv_LoadReg:
	ld a, l
	cp a, 0xfe
	jr nz, MidiRealtime_SysExOv_LoadReg3
	calr FileIO_ReadNextRecord
	ld wa, hl
	cp wa, 0:i3
	jr ge, MidiRealtime_SysExOv_LoadReg2
	ldw hl, 0xffff
	jrl MidiRealtime_ProcessByte

MidiRealtime_SysExOv_LoadReg2:
	ld iz, hl
	calr FileIO_ReadNextRecord
	ld wa, hl
	cp wa, 0:i3
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
	add (0xe9e7:16), xwa
	jr MidiRealtime_StopAndReturn

MidiRealtime_NonSysExHandler:
	extz wa
	calr VoiceReset_Return_Prologue
	ld wa, hl
	cp wa, 0:i3
	jr lt, MidiRealtime_ProcessByte
	calr FileIO_ReadNextRecord
	ld wa, hl
	cp wa, 0:i3
	jr ge, MidiRealtime_NonSysE_CheckEnd
	ldw hl, 0xffff
	jr MidiRealtime_ProcessByte

MidiRealtime_NonSysE_CheckEnd:
	cp l, 0xff
	jr nz, MidiRealtime_NonSysE_LoadReg
	calr FileIO_ReadNextRecord
	ld wa, hl
	cp wa, 0:i3
	jr ge, MidiRealtime_NonSysE_LoadReg
	ldw hl, 0xffff
	jr MidiRealtime_ProcessByte

MidiRealtime_NonSysE_LoadReg:
	ld a, l
	cp a, 0xfe
	jr nz, MidiRealtime_NonSysE_LoadReg3
	calr FileIO_ReadNextRecord
	ld wa, hl
	cp wa, 0:i3
	jr ge, MidiRealtime_NonSysE_LoadReg2
	ldw hl, 0xffff
	jr MidiRealtime_ProcessByte

MidiRealtime_NonSysE_LoadReg2:
	ld iz, hl
	calr FileIO_ReadNextRecord
	ld wa, hl
	cp wa, 0:i3
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
	add (0xe9e7:16), xwa

MidiRealtime_StopAndReturn:
	ld hl, 0:i3

MidiRealtime_ProcessByte:
	popw iz
	lda xsp, (xsp+128:16)
	ret

MidiRealtime_Process_Prologue:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xwa

ToneGen_ProcessMidiConverge:
	ld xwa, (0xebfd:16)
	cp xwa, (xsp + 2)
	jrl ugt, VoiceReset_Return_RestoreReg
	cpw (0xec01:16), 0
	jr z, ProcessMidiConverge_Block
	lda xwa, (0xec03:16)
	ld xbc, xwa
	ld wa, (0xec01:16)
	calr MIDI_SendSinglePacket

ProcessMidiConverge_Block:
	calr RingBuffer_ReadByte
	ld wa, hl
	cp wa, 0:i3
	jrl lt, ToneGen_VoiceReset_Return
	ld xwa, 0:i3
	ld a, l
	and xwa, 0xff
	ld (0xebfd:16), xwa
	calr RingBuffer_ReadByte
	ld wa, hl
	cp wa, 0:i3
	jrl lt, ToneGen_VoiceReset_Return
	ld xwa, 0:i3
	ld a, l
	sll xwa, 8
	and xwa, 0xff00
	add (0xebfd:16), xwa
	calr RingBuffer_ReadByte
	ld wa, hl
	cp wa, 0:i3
	jrl lt, ToneGen_VoiceReset_Return
	ld xwa, 0:i3
	ld a, l
	sll xwa, 16
	and xwa, SendPartDataBlock_Data2
	add (0xebfd:16), xwa
	calr RingBuffer_ReadByte
	ld wa, hl
	cp wa, 0:i3
	jrl lt, ToneGen_VoiceReset_Return
	ld xwa, 0:i3
	ld a, l
	sll xwa, 8
	sll xwa, 16
	and xwa, 0xff000000
	add (0xebfd:16), xwa
	calr RingBuffer_ReadByte
	ld wa, hl
	cp wa, 0:i3
	jrl lt, ToneGen_VoiceReset_Return
	ld iz, 0:i3
	ld wa, iz
	lda xbc, (0xec03:16)
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
	ldw (0xec01:16), 2
	jr ProcessMidiConverge_InitVal

ProcessMidiConverge_Block3:
	ldw (0xec01:16), 3

ProcessMidiConverge_InitVal:
	ld iz, 1:i3
	jr ProcessMidiConverge_LoopCheck

ProcessMidiConverge_LoopBody:
	calr RingBuffer_ReadByte
	ld wa, hl
	cp wa, 0:i3
	jr lt, ProcessMidiConverge_LoadDRAM
	ld wa, iz
	lda xbc, (0xec03:16)
	extz xwa
	add xwa, xbc
	ld (xwa), l
	inc 1, iz

ProcessMidiConverge_LoopCheck:
	cp iz, (0xec01:16)
	jr c, ProcessMidiConverge_LoopBody

ProcessMidiConverge_LoadDRAM:
	ld a, (0xec03:16)
	and a, 0xf0
	cp a, 0x90
	jr nz, ToneGen_ValidateRange_Loop
	cp (0xec05:16), 0
	jr z, ToneGen_ValidateRange_Loop
	ld a, (0xec05:16)
	extz wa
	mul wa, 0x4b
	extz xwa
	div wa, 0x64
	add wa, 0x20
	ld (0xec05:16), a
	cp (0xec05:16), 127
	jr ule, ToneGen_ValidateRange_Loop
	ld (0xec05:16), 127

ToneGen_ValidateRange_Loop:
	ld a, (0xec03:16)
	and a, 0xf0
	cp a, 0xb0
	jrl nz, ToneGen_ProcessMidiConverge
	cp (0xec04:16), 7
	jrl nz, ToneGen_ProcessMidiConverge
	ld (0xec05:16), 127
	jrl ToneGen_ProcessMidiConverge

ToneGen_VoiceReset_Return:
	ldw (0xec01:16), 0
	ld xwa, 0:i3
	ld (0xebfd:16), xwa

VoiceReset_Return_RestoreReg:
	popw iz
	inc 4, xsp
	ret

VoiceReset_Return_Prologue:
	lda xsp, (xsp - 10)
	push xiz
	bit 7, a
	jr z, VoiceReset_Return_Block
	ld (0xd09e:16), a
	ld (xsp + 4), a
	ld iz, 1:i3
	jr VoiceReset_Return_LoadDRAM

VoiceReset_Return_Block:
	ldmi16 (xsp + 4), 0xd09e
	ld (xsp + 5), a
	ld iz, 2:i3

VoiceReset_Return_LoadDRAM:
	ld a, (0xd09e:16)
	and a, 0xf0
	cp a, 0xc0
	jr z, VoiceReset_Return_Block2
	cp a, 0xd0
	jr nz, VoiceReset_Return_Block3

VoiceReset_Return_Block2:
	ldiw_erp 0xfa, 2
	jr VoiceReset_Return_Block4

VoiceReset_Return_Block3:
	ldiw_erp 0xfa, 3

VoiceReset_Return_Block4:
	cpw_erp IZ, 0xfa
	jr nc, VoiceReset_Return_LoadParam

VoiceReset_Return_LoopBody:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cp wa, 0:i3
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
	cpw_erp IZ, 0xfa
	jr c, VoiceReset_Return_LoopBody

VoiceReset_Return_LoadParam:
	ld a, (xsp + 4)
	and a, 0xf
	jrl nz, VoiceReset_Return_LoadAddr
	ld iz, 4:i3
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
	ld wa, (0xe9e5:16)
	ld bc, (0xe9ef:16)
	calr PlayModeStateMachine_Prologue
	add xhl, 0x3a
	ld xwa, xhl
	ld (xsp + 4), a
	ld xwa, xhl
	srl xwa, 8
	ld (xsp + 5), a
	ld xwa, xhl
	srl xwa, 16
	ld (xsp + 6), a
	srl xhl, 8
	srl xhl, 16
	ld a, l
	ld (xsp + 7), a
	inc4w_erp 0xfa
	ld iz, 0:i3
	cpw_erp IZ, 0xfa
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
	cpw_erp IZ, 0xfa
	jr c, VoiceReset_Return_LoadIter2
	jr VoiceReset_Return_InitVal

VoiceReset_Return_LoadAddr:
	lda xwa, (xsp + 4)
	ld xbc, xwa
	ldto_werp WA, 0xfa
	calr MIDI_SendSinglePacket

VoiceReset_Return_InitVal:
	ld hl, 0:i3

VoiceReset_Return_Epilogue:
	pop xiz
	lda xsp, (xsp + 10)
	ret

SoundParam_InitDefaultBanks:
	lda xsp, (xsp - 96)
	pushw iz
	ld xiy, SoundParam_DefaultBankMap0
	lda xix, (xsp + 82)
	ldw bc, 0x8
	ldirw
	ld xiy, SoundParam_DefaultBankMap1
	lda xix, (xsp + 66)
	ldw bc, 0x8
	ldirw
	ld xiy, SoundParam_DefaultBankMap2
	lda xix, (xsp + 50)
	ldw bc, 0x8
	ldirw
	ld xiy, SoundParam_DefaultBankMap3
	lda xix, (xsp + 34)
	ldw bc, 0x8
	ldirw
	ld xiy, SoundParam_DefaultBankMap4
	lda xix, (xsp + 18)
	ldw bc, 0x8
	ldirw
	ld xiy, SoundParam_DefaultBankMap5
	lda xix, (xsp + 2)
	ldw bc, 0x8
	ldirw
	cp a, 2:i3
	jrl z, SoundParam_InitDefau_Block2
	cp a, 1:i3
	jr z, SoundParam_InitDefau_Block
	cp a, 0:i3
	jrl nz, ToneGen_NotifyChangeComplete_Return
	ld (4330:16), 1
	ld xwa, 0xc1
	ld bc, 0:i3
	ld de, 1:i3
	call SoundParam_NotifyChange
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	set 2, (0xfdad:16)
	ld xwa, 0xc0
	ld bc, 0:i3
	ld de, 1:i3
	call SoundParam_NotifyChange
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	ld iz, 0:i3
	cp iz, 0x10
	jrl ge, ToneGen_NotifyChangeComplete_Return

SoundParam_InitDefau_LoadReg:
	ld de, iz
	lda xwa, (xsp + 82)
	ld	a, (xwa+iz)
	ld c, a
	extz bc
	pushw 0x2
	ld wa, de
	ld de, bc
	ldw bc, 0x401
	call SndParam_NotifyAndReturn
	lda xbc, (0xf1a0:16)
	lda xwa, (xsp + 66)
	ld	a, (xwa+iz)
	ld	(xbc+iz), a
	inc 1, iz
	cp iz, 0x10
	jr lt, SoundParam_InitDefau_LoadReg
	jrl ToneGen_NotifyChangeComplete_Return

SoundParam_InitDefau_Block:
	ld (4330:16), 1
	ld xwa, 0xc1
	ld bc, 0:i3
	ld de, 1:i3
	call SoundParam_NotifyChange
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	res 2, (0xfdad:16)
	ld xwa, 0xc0
	ld bc, 1:i3
	ld de, 1:i3
	call SoundParam_NotifyChange
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	ld iz, 0:i3
	cp iz, 0x10
	jrl ge, ToneGen_NotifyChangeComplete_Return

SoundParam_InitDefau_LoadReg2:
	ld de, iz
	lda xwa, (xsp + 50)
	ld	a, (xwa+iz)
	ld c, a
	extz bc
	pushw 0x2
	ld wa, de
	ld de, bc
	ldw bc, 0x401
	call SndParam_NotifyAndReturn
	lda xbc, (0xf1a0:16)
	lda xwa, (xsp + 34)
	ld	a, (xwa+iz)
	ld	(xbc+iz), a
	inc 1, iz
	cp iz, 0x10
	jr lt, SoundParam_InitDefau_LoadReg2
	jrl ToneGen_NotifyChangeComplete_Return

SoundParam_InitDefau_Block2:
	ld (4330:16), 1
	ld xwa, 0xc0
	ld bc, 0:i3
	ld de, 1:i3
	call SoundParam_NotifyChange
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	res 0, (0xfdad:16)
	ld xwa, 0xc1
	ld bc, 1:i3
	ld de, 1:i3
	call SoundParam_NotifyChange
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	ld iz, 0:i3
	cp iz, 0x10
	jr ge, SoundParam_InitDefau_LoadReg4

SoundParam_InitDefau_LoadReg3:
	ld de, iz
	lda xwa, (xsp + 18)
	ld	a, (xwa+iz)
	ld c, a
	extz bc
	pushw 0x2
	ld wa, de
	ld de, bc
	ldw bc, 0x401
	call SndParam_NotifyAndReturn
	lda xbc, (0xf1a0:16)
	lda xwa, (xsp + 2)
	ld	a, (xwa+iz)
	ld	(xbc+iz), a
	inc 1, iz
	cp iz, 0x10
	jr lt, SoundParam_InitDefau_LoadReg3

SoundParam_InitDefau_LoadReg4:
	ld xwa, 0x2201
	ld bc, 1:i3
	ld de, 2:i3
	call SoundParam_NotifyChange
	ld xwa, 0x2205
	ld bc, 1:i3
	ld de, 2:i3
	call SoundParam_NotifyChange

ToneGen_NotifyChangeComplete_Return:
	popw iz
	lda xsp, (xsp + 96)
	ret

NotifyChangeComplete_Prologue:
	lda xsp, (xsp - 32)
	ld xiy, Disk_DefaultPath
	ld xix, xsp
	ldw bc, 0x10
	ldirw
	ld c, (0xe9e4:16)
	cp c, 4:i3
	jr z, NotifyChangeComplete_DoGetCurre
	cp c, 3:i3
	jr z, NotifyChangeComplete_Prologue2
	cp c, 2:i3
	jr z, NotifyChangeComplete_Prologue2
	cp c, 1:i3
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
	cp wa, 0:i3
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
	ld a, (0xe9e4:16)
	cp a, 4:i3
	jr z, ReadNextRecord_DoLookupB
	cp a, 3:i3
	jr z, ReadNextRecord_DoReadNext
	cp a, 2:i3
	jr z, ReadNextRecord_DoReadNext
	cp a, 1:i3
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
	cp hl, 0:i3
	jr z, ReadNextRecord_Block

ReadNextRecord_Block3:
	calr RingBuffer_ReadByte
	cp hl, 0xfffd
	ret nz
	ld hl, 0:i3
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
	ld a, (0xe9e4:16)
	cp a, 4:i3
	jr z, DirectReturn_DoLookupC
	cp a, 3:i3
	jr z, DirectReturn_DoDrainQue
	cp a, 2:i3
	jr z, DirectReturn_DoDrainQue
	cp a, 1:i3
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
	ldw (4597:16), 120
	ret

StoreAndReturn_Block:
	ld (0xe9e4:16), 0
	ld xwa, 0:i3
	ld (0xe9e7:16), xwa
	ld xwa, 0:i3
	ld (0xe9f5:16), xwa
	ldw (0xe9e5:16), 0
	ld xwa, 0:i3
	ld (0xe9eb:16), xwa
	ldw (0xe9ef:16), 0
	ldw (0xe9f1:16), 0
	ld xwa, 0:i3
	ld (0xebfd:16), xwa
	ldw (0xec01:16), 0
	ld (0xe9c4:16), 0
	calr FileIO_InitTrackSlots
	calr SysexRingBuf_Init
	jrl MidiRingBuf_Init

FileIO_InitTrackSlots:
	ldw (0xd0a8:16), 0
	ldw (0xd0aa:16), 0
	ldw (0xd0ac:16), 2047
	ld de, 0:i3
	jr InitTrackSlots_LoopCheck

InitTrackSlots_LoopBody:
	ld wa, de
	inc 6, wa
	lda xbc, (0xd0a8:16)
	ld	(xbc+wa), 0x00
	inc 1, de

InitTrackSlots_LoopCheck:
	ld wa, de
	cp wa, (0xd0ac:16)
	jr c, InitTrackSlots_LoopBody
	ret

InitTrackSlots_Block:
	cpw (0xd0ac:16), 0
	jr nz, InitTrackSlots_LoadDRAM
	ldw hl, 0xffff
	jr InitTrackSlots_Return

InitTrackSlots_LoadDRAM:
	ld bc, (0xd0a8:16)
	lda xde, (0xd0ae:16)
	extz xbc
	add xbc, xde
	ld (xbc), a
	decw 1, (0xd0ac:16)
	cpw (0xd0a8:16), 2047
	jr nz, InitTrackSlots_IncDRAM
	ldw (0xd0a8:16), 0
	jr InitTrackSlots_InitVal

InitTrackSlots_IncDRAM:
	incw 1, (0xd0a8:16)

InitTrackSlots_InitVal:
	ld hl, 0:i3

InitTrackSlots_Return:
	ret

RingBuffer_ReadByte:
	ld wa, (0xd0a8:16)
	cp wa, (0xd0aa:16)
	jr nz, RingBuffer_ReadByte_LoadDRAM
	ldw hl, 0xffff
	jr RingBuffer_ReadByte_Return

RingBuffer_ReadByte_LoadDRAM:
	ld wa, (0xd0aa:16)
	lda xbc, (0xd0ae:16)
	extz xwa
	add xwa, xbc
	ld l, (xwa)
	extz hl
	incw 1, (0xd0ac:16)
	cpw (0xd0aa:16), 2047
	jr nz, RingBuffer_ReadByte_IncDRAM
	ldw (0xd0aa:16), 0
	jr RingBuffer_ReadByte_Return

RingBuffer_ReadByte_IncDRAM:
	incw 1, (0xd0aa:16)

RingBuffer_ReadByte_Return:
	ret

Seq_CalcAddrOffset:
	ldw hl, 0x7ff
	sub hl, (0xd0ac:16)
	ret

CalcAddrOffset_Data:
	dec	6, xsp
	pushw	iz
	ld	(xsp+2), xbc
	ld	(xsp+6), wa
	ld	iz, 0:i3
	ld	wa, iz
	.byte 0x9f, 0x06, 0xf0
	jr	nc, Seq_CalcAddrOffset_Skip2
Seq_CalcAddrOffset_Loop:
	calr	RingBuffer_ReadByte
	ld	wa, hl
	cp	wa, 0:i3
	jr	ge, Seq_CalcAddrOffset_Skip
	ldw	hl, 0xffff
	jr	Seq_CalcAddrOffset_Epilogue
Seq_CalcAddrOffset_Skip:
	ld	xwa, (xsp+2)
	ld	(xwa+iz), l
	inc 1, iz
	ld wa, iz
	.byte 0x9f, 0x06, 0xf0
	jr	c, Seq_CalcAddrOffset_Loop
Seq_CalcAddrOffset_Skip2:
	ld	hl, 0:i3
Seq_CalcAddrOffset_Epilogue:
	popw	iz
	inc	6, xsp
	ret

MidiRingBuf_WriteBytes:
	dec 6, xsp
	pushw iz
	ld (xsp + 4), xbc
	ld iz, wa
	cp iz, 0:i3
	jr nz, WriteBytes_Block
	ld hl, 0:i3
	jr SndParam_PopStackReturn

WriteBytes_Block:
	cp iz, (0xd0ac:16)
	jr ule, WriteBytes_Block2
	ldw hl, 0xffff
	jr SndParam_PopStackReturn

WriteBytes_Block2:
	cp (0xd0ac:16), iz
	jr ule, SndParam_NotifyError
	ldw (xsp + 2), 0x0
	ld wa, 0:i3
	cp wa, iz
	jr nc, SndParam_NotifySuccess

SndParam_NotifyLoop_Body:
	ld xbc, (xsp + 4)
	ld wa, (xsp + 2)
	ld	a, (xbc+wa)
	extz wa
	calr InitTrackSlots_Block
	incw 1, (xsp + 2)
	ld wa, (xsp + 2)
	cp wa, iz
	jr c, SndParam_NotifyLoop_Body

SndParam_NotifySuccess:
	ld hl, 0:i3
	jr SndParam_PopStackReturn

SndParam_NotifyError:
	ldw hl, 0xffff

SndParam_PopStackReturn:
	popw iz
	inc 6, xsp
	ret

SysexRingBuf_Init:
	ldw (0xd8ae:16), 0
	ldw (0xd8b0:16), 0
	ldw (0xd8b2:16), 2047
	ld de, 0:i3
	jr SysexRingBuf_ClearCheck

SysexRingBuf_ClearLoop:
	ld wa, de
	inc 6, wa
	lda xbc, (0xd8ae:16)
	ld	(xbc+wa), 0x00
	inc 1, de

SysexRingBuf_ClearCheck:
	ld wa, de
	cp wa, (0xd8b2:16)
	jr c, SysexRingBuf_ClearLoop
	ret

SysexRingBuf_WriteByte:
	cpw (0xd8b2:16), 0
	jr nz, SysexRingBuf_StoreAndAdvance
	ldw hl, 0xffff
	jr SysexRingBuf_WriteReturn

SysexRingBuf_StoreAndAdvance:
	ld bc, (0xd8ae:16)
	lda xde, (0xd8b4:16)
	extz xbc
	add xbc, xde
	ld (xbc), a
	decw 1, (0xd8b2:16)
	cpw (0xd8ae:16), 2047
	jr nz, SysexRingBuf_IncrementWrite
	ldw (0xd8ae:16), 0
	jr SysexRingBuf_WriteSuccess

SysexRingBuf_IncrementWrite:
	incw 1, (0xd8ae:16)

SysexRingBuf_WriteSuccess:
	ld hl, 0:i3

SysexRingBuf_WriteReturn:
	ret

SysexRingBuf_ReadByte:
	ld wa, (0xd8ae:16)
	cp wa, (0xd8b0:16)
	jr nz, SysexRingBuf_ReadAndAdvance
	ldw hl, 0xffff
	jr SysexRingBuf_ReadReturn

SysexRingBuf_ReadAndAdvance:
	ld wa, (0xd8b0:16)
	lda xbc, (0xd8b4:16)
	extz xwa
	add xwa, xbc
	ld l, (xwa)
	extz hl
	incw 1, (0xd8b2:16)
	cpw (0xd8b0:16), 2047
	jr nz, SysexRingBuf_IncrementRead
	ldw (0xd8b0:16), 0
	jr SysexRingBuf_ReadReturn

SysexRingBuf_IncrementRead:
	incw 1, (0xd8b0:16)

SysexRingBuf_ReadReturn:
	ret

SysexRingBuf_GetFreeSpace:
	ldw hl, 0x7ff
	sub hl, (0xd8b2:16)
	ret

SysexRingBuf_ReadBytes:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld (xsp + 6), wa
	ld iz, 0:i3
	ld wa, iz
	cp wa, (xsp + 6)
	jr nc, SysexRingBuf_ReadBytesOK

SysexRingBuf_ReadBytesLoop:
	calr SysexRingBuf_ReadByte
	ld wa, hl
	cp wa, 0:i3
	jr ge, SysexRingBuf_ReadBytesStore
	ldw hl, 0xffff
	jr SysexRingBuf_ReadBytesReturn

SysexRingBuf_ReadBytesStore:
	ld xwa, (xsp + 2)
	ld	(xwa+iz), l
	inc 1, iz
	ld wa, iz
	cp wa, (xsp + 6)
	jr c, SysexRingBuf_ReadBytesLoop

SysexRingBuf_ReadBytesOK:
	ld hl, 0:i3

SysexRingBuf_ReadBytesReturn:
	popw iz
	inc 6, xsp
	ret

SysexRingBuf_WriteBytes:
	dec 6, xsp
	pushw iz
	ld (xsp + 4), xbc
	ld iz, wa
	cp iz, 0:i3
	jr nz, SysexRingBuf_WriteNonZero
	ld hl, 0:i3
	jr SysexRingBuf_WriteBytesReturn

SysexRingBuf_WriteNonZero:
	cp iz, (0xd8b2:16)
	call ugt, (SysexRingBuf_Init:24)
	ldw (xsp + 2), 0x0
	ld wa, 0:i3
	cp wa, iz
	jr nc, SysexRingBuf_WriteBytesOK

SysexRingBuf_WriteBytesLoop:
	ld xbc, (xsp + 4)
	ld wa, (xsp + 2)
	ld	a, (xbc+wa)
	extz wa
	calr SysexRingBuf_WriteByte
	incw 1, (xsp + 2)
	ld wa, (xsp + 2)
	cp wa, iz
	jr c, SysexRingBuf_WriteBytesLoop

SysexRingBuf_WriteBytesOK:
	ld hl, 0:i3

SysexRingBuf_WriteBytesReturn:
	popw iz
	inc 6, xsp
	ret

MidiRingBuf_Init:
	ldw (0xe0b4:16), 0
	ldw (0xe0b6:16), 0
	ldw (0xe0b8:16), 127
	ld de, 0:i3
	jr MidiRingBuf_ClearCheck

MidiRingBuf_ClearLoop:
	ld wa, de
	inc 6, wa
	lda xbc, (0xe0b4:16)
	ld	(xbc+wa), 0x00
	inc 1, de

MidiRingBuf_ClearCheck:
	ld wa, de
	cp wa, (0xe0b8:16)
	jr c, MidiRingBuf_ClearLoop
	ret

MidiRingBuf_WriteByte:
	cpw (0xe0b8:16), 0
	jr nz, MidiRingBuf_StoreAndAdvance
	ldw hl, 0xffff
	jr StoreAndAdvance_Return

MidiRingBuf_StoreAndAdvance:
	ld bc, (0xe0b4:16)
	lda xde, (0xe0ba:16)
	extz xbc
	add xbc, xde
	ld (xbc), a
	decw 1, (0xe0b8:16)
	cpw (0xe0b4:16), 127
	jr nz, StoreAndAdvance_IncDRAM
	ldw (0xe0b4:16), 0
	jr StoreAndAdvance_InitVal

StoreAndAdvance_IncDRAM:
	incw 1, (0xe0b4:16)

StoreAndAdvance_InitVal:
	ld hl, 0:i3

StoreAndAdvance_Return:
	ret

StoreAndAdvance_LoadDRAM:
	ld wa, (0xe0b4:16)
	cp wa, (0xe0b6:16)
	jr nz, StoreAndAdvance_LoadDRAM2
	ldw hl, 0xffff
	jr StoreAndAdvance_Return2

StoreAndAdvance_LoadDRAM2:
	ld wa, (0xe0b6:16)
	lda xbc, (0xe0ba:16)
	extz xwa
	add xwa, xbc
	ld l, (xwa)
	extz hl
	incw 1, (0xe0b8:16)
	cpw (0xe0b6:16), 127
	jr nz, StoreAndAdvance_IncDRAM2
	ldw (0xe0b6:16), 0
	jr StoreAndAdvance_Return2

StoreAndAdvance_IncDRAM2:
	incw 1, (0xe0b6:16)

StoreAndAdvance_Return2:
	ret

StoreAndAdvance_Prologue:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld (xsp + 6), wa
	ld iz, 0:i3
	ld wa, iz
	cp wa, (xsp + 6)
	jr nc, StoreAndAdvance_InitVal2

StoreAndAdvance_LoopBody:
	calr StoreAndAdvance_LoadDRAM
	ld wa, hl
	cp wa, 0:i3
	jr ge, StoreAndAdvance_LoopCheck
	ldw hl, 0xffff
	jr StoreAndAdvance_RestoreReg

StoreAndAdvance_LoopCheck:
	ld xwa, (xsp + 2)
	ld	(xwa+iz), l
	inc 1, iz
	ld wa, iz
	cp wa, (xsp + 6)
	jr c, StoreAndAdvance_LoopBody

StoreAndAdvance_InitVal2:
	ld hl, 0:i3

StoreAndAdvance_RestoreReg:
	popw iz
	inc 6, xsp
	ret

StoreAndAdvance_Prologue2:
	dec 6, xsp
	pushw iz
	ld (xsp + 4), xbc
	ld iz, wa
	cp iz, 0:i3
	jr nz, StoreAndAdvance_Block
	ld hl, 0:i3
	jr StoreAndAdvance_RestoreReg2

StoreAndAdvance_Block:
	cp iz, (0xe0b8:16)
	call ugt, (MidiRingBuf_Init:24)
	ldw (xsp + 2), 0x0
	ld wa, 0:i3
	cp wa, iz
	jr nc, StoreAndAdvance_InitVal3

StoreAndAdvance_LoadParam:
	ld xbc, (xsp + 4)
	ld wa, (xsp + 2)
	ld	a, (xbc+wa)
	extz wa
	calr MidiRingBuf_WriteByte
	incw 1, (xsp + 2)
	ld wa, (xsp + 2)
	cp wa, iz
	jr c, StoreAndAdvance_LoadParam

StoreAndAdvance_InitVal3:
	ld hl, 0:i3

StoreAndAdvance_RestoreReg2:
	popw iz
	inc 6, xsp
	ret

StoreAndAdvance_Prologue3:
	pushw	iz
	ld	iz, 0:i3
	call	TaskBuf_ReadNextByte
	ld	iz, hl
	cp	iz, 0:i3
	jr	ge, StoreAndAdvance_Prologue2_Epilogue
	nop
	jr	StoreAndAdvance_Prologue2_Epilogue2
StoreAndAdvance_Prologue2_Epilogue:
	nop
StoreAndAdvance_Prologue2_Epilogue2:
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
	ld (0xe13a:16), 0
	ld (0xe13b:16), 1
	ld xde, 0xe13a
	ld wa, 5:i3
	ld bc, 2:i3
	jp sendCOMM
CharMap_ActivePreamb_LoadDRAM:
	ld	a, (0xc07d:16)
	cp	a, 0:i3
	ret	nz
	ld	a, (0xc07f:16)
	and	a, 15
	ret	z
	ld	(0xe144:16), 1
	ld	a, (0xc07e:16)
	and	a, 15
	ld	(0xe145:16), a
	ld	xde, 0xe144
	ld	wa, 5:i3
	ld	bc, 2:i3
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
	cp hl, 1:i3
	jr nz, CharMap_ActivePreamb_Extend
	ld xwa, 0x48
	cp (xsp + 2), 0xf
	jr nz, CharMap_ActivePreamb_LoadDRAM2
	ld xwa, 0x4c

CharMap_ActivePreamb_LoadDRAM2:
	ld xde, (0xe14e:16)
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
	ld xde, (0xe14e:16)
	add xde, xwa
	add xbc, (xde)
	ld l, (xbc)
	jr CharMap_ActivePreamb_Increment

CharMap_ActivePreamb_LoadDRAM4:
	ld xwa, (0xe14e:16)
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
	cp hl, 1:i3
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
	ld c, 0x70:opc
	jr SndParam_StoreResult_Return

ApplyMaskClamp_Compare:
	cp (xiz), 0xef
	jr ugt, ApplyMaskClamp_LoadParam3
	ld xwa, (xsp + 4)
	cp (xwa), 0x0
	jr nz, ApplyMaskClamp_LoadParam2
	resm 7, (xiz)
	ld c, 0x10:opc
	jr SndParam_StoreResult_Return

ApplyMaskClamp_LoadParam2:
	ld xwa, (xsp + 4)
	cp (xwa), 0x5
	jr nz, ApplyMaskClamp_LoadReg
	resm 7, (xiz)
	ld c, 0x15:opc
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
	ld c, 0x50:opc
	jr SndParam_StoreResult_Return

ApplyMaskClamp_LoadParam5:
	ld xwa, (xsp + 4)
	cp (xwa), 0x5
	jr nz, ApplyMaskClamp_LoadReg
	andmi8 (xiz), 0x3
	ld c, 0x55:opc
	jr SndParam_StoreResult_Return

ApplyMaskClamp_LoadReg:
	ld (xiz), 0x0
	ld c, 0x0:opc

SndParam_StoreResult_Return:
	ld xwa, (xsp + 4)
	ld (xwa), c

SndParam_PopIzSkip4Ret:
	pop xiz
	inc 4, xsp
	ret

SndParam_StoreDRAMInit:
	lda xsp, (xsp-304)
	pushw iz
	ld	(xsp+300), de
	ld	(xsp+302), bc
	ld	(xsp+304), a
	ld (xsp + 6), 0xff
	ld xwa, 0:i3
	ld (xsp + 2), xwa
	jr StoreDRAMInit_Block2

StoreDRAMInit_ReadBuf:
	call SeqBuf_VoiceMap_ReadByte
	cp hl, 0xffff
	jr z, StoreDRAMInit_Block
	lda xwa, (xsp + 12)
	ld (xsp + 8), xwa
	ld xwa, 1:i3
	add (xsp + 8), xwa
	ld iz, 0:i3

StoreDRAMInit_ReadBuf2:
	call SeqBuf_VoiceMap_ReadByte
	ld xwa, (xsp + 8)
	ld (xwa+), l
	ld (xsp + 8), xwa
	inc 1, iz
	cp iz, 7:i3
	jr c, StoreDRAMInit_ReadBuf2
	lda xbc, (xsp + 12)
	ld a, (xbc + 7)
	cp	a, (xsp+304)
	jr nz, StoreDRAMInit_Block
	ld (xbc), 0x0
	ld iz, 0:i3
	cpw	(xsp+302), 0x0000
	jr ule, StoreDRAMInit_LoadParam

StoreDRAMInit_ReadBuf3:
	call SeqBuf_VoiceMap_ReadByte
	ld XWA, (xsp + 0x0136)
	ld (xwa+), l
	ld	(xsp+310), xwa
	inc 1, iz
	cp	iz, (xsp+302)
	jr c, StoreDRAMInit_ReadBuf3

StoreDRAMInit_LoadParam:
	ld (xsp + 6), 0x0
	jr StoreDRAMInit_LoadParam2

StoreDRAMInit_Block:
	ld xwa, 1:i3
	add (xsp + 2), xwa
	ld xwa, (xsp + 2)
	cp xwa, 0xe00
	jr ge, StoreDRAMInit_LoadParam2

StoreDRAMInit_Block2:
	ld	wa, (xsp+300)
	extz xwa
	cp (xsp + 2), xwa
	jrl lt, StoreDRAMInit_ReadBuf

StoreDRAMInit_LoadParam2:
	ld l, (xsp + 6)
	popw iz
	lda xsp, (xsp+304)
	retd 0x4

StoreDRAMInit_LoadDRAM:
	ld xhl, (0xe14e:16)
	ld xde, (xhl + 4)
	dec 1, xde
	ld xix, 0:i3
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
	ld A, (xhl+)
	ld (xde+), a
	cp xde, xbc
	jr c, StoreDRAMInit_Block3
	ret

StoreDRAMInit_Block4:
	lda xwa, (Msg_WrongSwNumber:24)
	ld xde, xwa
	lda xhl, (xwa + 16)

StoreDRAMInit_Block5:
	ld A, (xde+)
	ld (xbc+), a
	cp xde, xhl
	jr c, StoreDRAMInit_Block5
	ret

SndParam_ApplyProgramChangeAsync:
	dec 8, xsp
	pushw_erp 0xfa
	ld (xsp + 2), xde
	ld (xsp + 6), c
	ld (xsp + 8), a
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 6)
	calr SndParam_ApplyMaskClamp
	ld wa, 5:i3
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
	ld wa, 5:i3
	call TaskSched_SignalEvent
	cpib_erp 0xfb, 0
	jr z, ApplyProgramChangeAs_RestoreReg
	lda xwa, (Msg_SoundNameError:24)
	ld xbc, xwa
	ld xde, (xsp + 2)
	lda xhl, (xwa + 17)

ApplyProgramChangeAs_Block:
	ld A, (xbc+)
	ld (xde+), a
	cp xbc, xhl
	jr c, ApplyProgramChangeAs_Block

ApplyProgramChangeAs_RestoreReg:
	popw_erp 0xfa
	inc 8, xsp
	ret

ApplyProgramChangeAs_Prologue:
	dec 6, xsp
	pushw_erp 0xfa
	ld (xsp + 4), c
	ld (xsp + 6), a
	lda xwa, (xsp + 6)
	lda xbc, (xsp + 4)
	calr SndParam_ApplyMaskClamp
	ld wa, 5:i3
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
	ld bc, 1:i3
	ldw de, 0xe00
	calr SndParam_StoreDRAMInit
	ldfr_berp L, 0xfb
	ld wa, 5:i3
	call TaskSched_SignalEvent
	cpib_erp 0xfb, 0
	jr z, ApplyProgramChangeAs_ClearByte
	ld (xsp + 2), 0x0
	jr ApplyProgramChangeAs_LoadParam2

ApplyProgramChangeAs_ClearByte:
	ld a, 0x0:opc
	bitm 7, (xsp + 2)
	jr z, ApplyProgramChangeAs_LoadParam
	ld a, 0x7f:opc

ApplyProgramChangeAs_LoadParam:
	ld (xsp + 2), a

ApplyProgramChangeAs_LoadParam2:
	ld l, (xsp + 2)
	popw_erp 0xfa
	inc 6, xsp
	ret

ApplyProgramChangeAs_Prologue2:
	dec 8, xsp
	pushw_erp 0xfa
	ld (xsp + 2), xde
	ld (xsp + 6), c
	ld (xsp + 8), a
	ld wa, 5:i3
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
	ld wa, 5:i3
	call TaskSched_SignalEvent
	cpib_erp 0xfb, 0
	jr z, ApplyProgramChangeAs_RestoreReg2
	lda xwa, (Msg_SNameError:24)
	ld xbc, xwa
	ld xde, (xsp + 2)
	lda xhl, (xwa + 10)

ApplyProgramChangeAs_Block2:
	ld A, (xbc+)
	ld (xde+), a
	cp xbc, xhl
	jr c, ApplyProgramChangeAs_Block2

ApplyProgramChangeAs_RestoreReg2:
	popw_erp 0xfa
	inc 8, xsp
	ret

ApplyProgramChangeAs_DoLookupRe:
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cp hl, 1:i3
	jr nz, ApplyProgramChangeAs_LoadDRAM
	call GetCurrentPartSelect
	cp l, 0xf
	jr z, ApplyProgramChangeAs_SetByte
	ld l, 0x80:opc
	jr ApplyProgramChangeAs_Return

ApplyProgramChangeAs_SetByte:
	ld l, 0x89:opc
	jr ApplyProgramChangeAs_Return

ApplyProgramChangeAs_LoadDRAM:
	ld xwa, (0xe14e:16)
	ld xwa, (xwa + 4)
	ld l, a

ApplyProgramChangeAs_Return:
	ret

ApplyProgramChangeAs_LoadDRAM2:
	ld xhl, (0xe14e:16)
	add xhl, xbc
	ld xix, (xhl)
	ld c, (xwa + 4)
	extz bc
	extz xbc
	ld xhl, xix
	add xhl, xbc
	ld c, (xhl)
	extz bc
	mul xbc, de
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
SndBuf_WriteParamEntries_Helper:
	jr ApplyProgramChangeAs_LoadReg

SndParam_FetchOscTableEntry:
	push xiz
	ld xiz, xwa
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cp hl, 1:i3
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
	ld xbc, (0xe14e:16)
	ld xwa, (xbc + 8)
	ld e, a
	cp (xiz), l
	jr nc, FetchOscTableEntry_ClearByte
	ld w, (xiz)
	jr FetchOscTableEntry_ClearByte2

FetchOscTableEntry_ClearByte:
	ld w, 0x0:opc

FetchOscTableEntry_ClearByte2:
	ld l, 0x0:opc
	ld a, (xiz + 1)
	cp a, e
	jr nc, FetchOscTableEntry_Compute
	ld l, a

FetchOscTableEntry_Compute:
	add xbc, (xsp + 4)
	ld xix, (xbc)
	ld c, w
	mul bc, e
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
	cp hl, 1:i3
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
	ld xhl, (0xe14e:16)
	add xhl, xbc
	ld xix, (xhl)
	ld c, (xwa + 4)
	extz bc
	extz xbc
	ld xhl, xix
	add xhl, xbc
	ld c, (xhl)
	extz bc
	mul xbc, de
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
	cp hl, 1:i3
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
	ld bc, 0:i3
	call SndParam_LookupViaEncode
	lda xbc, (xiz + 2)
	cp hl, 0xf0
	jr lt, LookupOscEnvelope_LoadDRAM
	ld xwa, (0xe14e:16)
	ld xhl, (xwa + 48)
	jr LookupOscEnvelope_LoadReg2

LookupOscEnvelope_LoadDRAM:
	ld xwa, (0xe14e:16)
	ld xde, (xwa + 28)
	ld xwa, 0:i3
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
	ld xwa, (0xe14e:16)
	ld xhl, (xwa + 48)
	lda xbc, (xiz + 2)

LookupOscEnvelope_LoadReg2:
	ld a, (xbc)
	sll a, 1
	extz wa
	lda	xhl, (xhl+wa)

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
	cp	hl, 1:i3
	jr	nz, SndParam_CheckAndApplyMode_Skip
	ld	xwa, xiz
	calr	SndParam_ApplyVoiceValue
	jr	SndParam_CheckAndApplyMode_Epilogue
SndParam_CheckAndApplyMode_Skip:
	ld	xwa, xiz
	calr	SndParam_LookupOscEnvelope
SndParam_CheckAndApplyMode_Epilogue:
	pop	xiz
	ret

SndParam_LookupFromPointerTable:
	ld xix, (0xe14e:16)
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
	ld xbc, (0xe14e:16)
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
	lda	xbc, (SndParam_LogCurve128:24)
	ld	a, (xbc+wa)
	extz wa
	ld	l, a
	ret

SndParam_LookupAndDispatch:
	dec 6, xsp
	pushw_erp 0xfa
	ld (xsp + 4), c
	ld (xsp + 6), a
	ld (xsp + 2), 0xff
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cp hl, 1:i3
	jr z, SndParam_ReturnResult
	cp (xsp + 4), 0x78
	jr nz, SndParam_ApplyMaskAndCheck
	ld xwa, (0xe14e:16)
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
	ld wa, 5:i3
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
	ld bc, 1:i3
	ldw de, 0xe00
	calr SndParam_StoreDRAMInit
	ldfr_berp L, 0xfb
	ld wa, 5:i3
	call TaskSched_SignalEvent
	ld a, 0x2:opc
	cpib_erp 0xfb, 0
	jr nz, SndParam_StoreResult
	ld a, (xsp + 2)

SndParam_StoreResult:
	ld (xsp + 2), a

SndParam_ReturnResult:
	ld l, (xsp + 2)
	popw_erp 0xfa
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
	cp wa, 0:i3
	jr lt, SndParam_LoadReturnByte
	cp wa, 5:i3
	jr gt, SndParam_LoadReturnByte
	add wa, wa
	lda xix, (SndParamChan_SwitchOffsets:24)
	ld	wa, (xix+wa)
	lda xix, (SndParam_TypeDispatch:24)
	jp	t, (xix+wa)

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
	lda xde, (0xec11:16)
	ld	xde, (xde+hl)
	ld b, 0x0:opc
	extz xbc
	add xbc, xde
	ld l, (xbc)
	jr LoadReturnByte_Increment

LoadTableConverge_LoadReg:
	ld xwa, NoteMap_ConvergeMapA
	jr LoadTableConverge_LoadFromStack

LoadTableConverge_LoadReg2:
	ld xwa, NoteMap_ConvergeMapB

LoadTableConverge_LoadFromStack:
	ld	l, (xwa+de)
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
	ld bc, 0:i3
	calr SndParam_LookupAndDispatch
	cp l, 0xff
	jr z, LookupTableConverge_LoadParam
	ld e, (xsp + 2)
	ld c, (xsp)
	extz bc
	extz de
	dec 1, de
	cp de, 0:i3
	jr lt, LookupTableConverge_LoadParam
	cp de, 5:i3
	jr gt, LookupTableConverge_LoadParam
	add de, de
	lda xix, (SndParamOffs_SwitchOffsets:24)
	ld	de, (xix+de)
	lda xix, (SndParam_OffsetDispatch:24)
	jp	t, (xix+de)

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
	lda xbc, (0xec11:16)
	ld	xbc, (xbc+hl)
	ld xwa, 0:i3
	ld a, (xsp)
	add xwa, xbc
	ld l, (xwa)
	jr LookupTableConverge_Increment

LookupTableConverge_LoadReg:
	ld xwa, NoteMap_ConvergeMapA
	jr LookupTableConverge_LoadFromStack

LookupTableConverge_LoadReg2:
	ld xwa, NoteMap_ConvergeMapB

LookupTableConverge_LoadFromStack:
	ld	l, (xwa+bc)
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
	ld xwa, (SoundData_CategoryDescPtr:24)
	ld (0xe14e:16), xwa
	ret

Param_SignExtendRetu_Block2:
	jr Param_SignExtendRetu_Block
Param_SignExtendReturn_Helper:
	ld l, (xwa + 9)
	res 7, l
	ld h, 0x0:opc
	extz xhl
	sll xhl, 14
	ld e, (xwa + 10)
	res 7, e
	ld d, 0x0:opc
	extz xde
	sll xde, 7
	ld c, (xwa + 11)
	res 7, c
	ld b, 0x0:opc
	extz xbc
	or xhl, xde
	or xhl, xbc
	ret

Param_SignExtendRetu_Data:
	ld	xhl, 0:i3
	ld	l, (xwa+6)
	sll	xhl, 14
	ld	e, (xwa+7)
	res	7, e
	ld	d, 0:opc
	extz	xde
	sll	xde, 7
	ld	c, (xwa+8)
	res	7, c
	ld	b, 0:opc
	extz	xbc
	or xhl, xde
	or xhl, xbc
	ret
Param_SignExtendReturn_Helper2:
	ld hl, wa
	cpl	bc
	and	hl, bc
	retd	4
Param_SignExtendReturn_Helper3:
	dec	2, xsp
	ld	(xsp), c
	ld	xbc, xwa
	cp	xbc, 426
	jr	c, Param_SignExtendReturn_Skip
	sub	xbc, 426
	ld	xwa, xbc
	ld	xbc, 11
	call	DivMod32
	cp	xhl, 9
	jrl	ugt, Param_SignExtendReturn_Skip5
	add	xhl, xhl
	add	xhl, ParamSx_SwitchC
	ld	hl, (xhl)
	lda	xix, (Param_SignExtendReturn_Code2:24)
	jp	t, (xix+hl)
Param_SignExtendReturn_Code2:
	ld	a, (xsp)
	exts	wa
	pushw	127
	pushw	0
	ldw	bc, 0xffff
	ld	de, 0:i3
	jrl	Param_SignExtendReturn_Join
Param_SignExtendReturn_Skip:
	cp	xbc, 102
	jrl	c, Param_SignExtendReturn_Skip2
	sub	xbc, 102
	ld	xwa, xbc
	ld	xbc, 81
	call	DivMod32
	cp	xhl, 76
	jrl	ugt, Param_SignExtendReturn_Skip5
	add	xhl, ParamSx_CaseMapB
	ld	hl, (xhl)
	extz	hl
	sll	hl, 1
	ld	xix, ParamSx_SwitchB
	ld	hl, (xix+hl)
	lda xix, (Param_SignExtendReturn_Code:24)
	jp	t, (xix+hl)
Param_SignExtendReturn_Code:
	ld	a, (xsp)
	exts	wa
	pushw	50
	pushw	0
	ldw	bc, 0xffff
	ld	de, 0:i3
	jrl	Param_SignExtendReturn_Join
	ld	a, (xsp)
	exts	wa
	pushw	128
	pushw	0
	ldw	bc, 0xffff
	ld	de, 0:i3
	jrl	Param_SignExtendReturn_Join
	ld	a, (xsp)
	exts	wa
	pushw	127
	pushw	0
	ldw	bc, 0xffff
	ld	de, 0:i3
	jrl	Param_SignExtendReturn_Join
	ld	a, (xsp)
	exts	wa
	pushw	24
	pushw	0xffe8
	ldw	bc, 0xffff
	ld	de, 0:i3
	jrl	Param_SignExtendReturn_Join
	ld	a, (xsp)
	exts	wa
	pushw	50
	pushw	0xffce
	ldw	bc, 0xffff
	ld	de, 0:i3
	jrl	Param_SignExtendReturn_Join
	ld	a, (xsp)
	exts	wa
	pushw	100
	pushw	0
	ldw	bc, 0xffff
	ld	de, 0:i3
	jrl	Param_SignExtendReturn_Join
Param_SignExtendReturn_Skip2:
	ld	xbc, xwa
	cp	xwa, 15
	jr	gt, Param_SignExtendReturn_Skip3
	cp	xwa, 0
	jr	ge, Param_SignExtendReturn_Skip4
Param_SignExtendReturn_Skip3:
	sub	xbc, 16
	cp	xbc, 0
	jrl	lt, Param_SignExtendReturn_Skip5
	cp	xbc, 76
	jrl	gt, Param_SignExtendReturn_Skip5
	add	xbc, ParamSx_CaseMapA
	ld	bc, (xbc)
	extz	bc
	sll	bc, 1
	ld	xix, ParamSx_SwitchA
	ld	bc, (xix+bc)
	lda xix, (Param_SignExtendReturn_Skip4:24)
	jp	t, (xix+bc)
Param_SignExtendReturn_Skip4:
	ld	a, (xsp)
	exts	wa
	pushw	127
	pushw	32
	ldw	bc, 0xffff
	ld	de, 0:i3
	jr	Param_SignExtendReturn_Join
	ld	a, (xsp)
	exts	wa
	pushw	66
	pushw	0
	ldw	bc, 0xffff
	ld	de, 0:i3
	jr	Param_SignExtendReturn_Join
	ld	a, (xsp)
	exts	wa
	pushw	49
	pushw	0
	ldw	bc, 127
	ld	de, 0:i3
	jr	Param_SignExtendReturn_Join
	ld	a, (xsp)
	exts	wa
	pushw	127
	pushw	0
	ldw	bc, 0xffff
	ld	de, 0:i3
	jr	Param_SignExtendReturn_Join
	ld	a, (xsp)
	exts	wa
	pushw	10
	pushw	6
	ldw	bc, 0xffff
	ld	de, 0:i3
	jr	Param_SignExtendReturn_Join
	ld	a, (xsp)
	exts	wa
	pushw	50
	pushw	0
	ldw	bc, 127
	ld	de, 0:i3
	jr	Param_SignExtendReturn_Join
	ld	a, (xsp)
	exts	wa
	pushw	30
	pushw	0
	ldw	bc, 63
	ld	de, 0:i3
Param_SignExtendReturn_Join:
	calr	Param_SignExtendReturn_Helper2
	ld	(xsp), l
Param_SignExtendReturn_Skip5:
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
	jrl	c, Param_SignExtendReturn_Skip9
	ld	xwa, xiz
	sub	xwa, 295
	ld	xbc, 80
	call	Math_DivideU32
	ld	a, l
	extz	wa
	muls	wa, 80
	extz	xwa
	.byte 0xf3, 0xe1
	ld	l, 1:opc
	ldw	wa, 0x3ab8
	ldw	wa, 0xf6e8
	jr	c, Param_SignExtendReturn_Skip6
	ld	xbc, xiz
	sub	xbc, xwa
	ld	xwa, xbc
	ld	xbc, 11
	call	DivMod32
	cp	xhl, 9
	jrl	ugt, Param_SignExtendReturn_Skip12
	add	xhl, xhl
	add	xhl, ParamSx_SwitchF
	ld	hl, (xhl)
	lda	xix, (Param_SignExtendReturn_Code3:24)
	jp	t, (xix+hl)
Param_SignExtendReturn_Code3:
	pushw	127
	pushw	0
	ld	wa, (xsp+10)
	ldw	bc, 0xffff
	ld	de, 0:i3
	jrl	Param_SignExtendReturn_Join2
Param_SignExtendReturn_Skip6:
	extz	hl
	mul	hl, 80
	add	xhl, 295
	ld	xbc, xiz
	sub	xbc, xhl
	ld	xwa, xbc
	cp	xbc, 12
	jr	ugt, Param_SignExtendReturn_Skip7
	cp	xbc, 0
	jr	nc, Param_SignExtendReturn_Skip8
Param_SignExtendReturn_Skip7:
	sub	xwa, 13
	cp	xwa, 0
	jrl	c, Param_SignExtendReturn_Skip12
	cp	xwa, 40
	jrl	ugt, Param_SignExtendReturn_Skip12
	add	xwa, ParamSx_CaseMapE
	ld	wa, (xwa)
	extz	wa
	sll	wa, 1
	ld	xix, ParamSx_SwitchE
	ld	wa, (xix+wa)
	lda xix, (Param_SignExtendReturn_Skip8:24)
	jp	t, (xix+wa)
Param_SignExtendReturn_Skip8:
	pushw 127
	pushw	32
	ld	wa, (xsp+8)
	ldw	bc, 0xffff
	ld	de, 0:i3
	jrl	Param_SignExtendReturn_Join2
	pushw	127
	pushw	0
	ld	wa, (xsp+10)
	ldw	bc, 0xffff
	ld	de, 0:i3
	jrl	Param_SignExtendReturn_Join2
	pushw	50
	pushw	0
	ld	wa, (xsp+10)
	ldw	bc, 0xffff
	ld	de, 0:i3
	jrl	Param_SignExtendReturn_Join2
	pushw	128
	pushw	0
	ld	wa, (xsp+10)
	ldw	bc, 0xffff
	ld	de, 0:i3
	jrl	Param_SignExtendReturn_Join2
	pushw	127
	pushw	0
	ld	wa, (xsp+10)
	ldw	bc, 0xffff
	ld	de, 0:i3
	jrl	Param_SignExtendReturn_Join2
	pushw	50
	pushw	0xffce
	ld	wa, (xsp+10)
	ldw	bc, 0xffff
	ld	de, 0:i3
	jrl	Param_SignExtendReturn_Join2
	pushw	100
	pushw	0
	ld	wa, (xsp+10)
	ldw	bc, 0xffff
	ld	de, 0:i3
	jr	Param_SignExtendReturn_Join2
Param_SignExtendReturn_Skip9:
	ld	xbc, xwa
	cp	xwa, 15
	jr	gt, Param_SignExtendReturn_Skip10
	cp	xwa, 0
	jr	ge, Param_SignExtendReturn_Skip11
Param_SignExtendReturn_Skip10:
	sub	xbc, 16
	cp	xbc, 0
	jr	lt, Param_SignExtendReturn_Skip12
	cp	xbc, 22
	jr	gt, Param_SignExtendReturn_Skip12
	add	xbc, ParamSx_CaseMapD
	ld	bc, (xbc)
	extz	bc
	sll	bc, 1
	ld	xix, ParamSx_SwitchD
	ld	bc, (xix+bc)
	lda xix, (Param_SignExtendReturn_Skip11:24)
	jp	t, (xix+bc)
Param_SignExtendReturn_Skip11:
	pushw 127
	pushw	32
	ld	wa, (xsp+8)
	ldw	bc, 0xffff
	ld	de, 0:i3
	jr	Param_SignExtendReturn_Join2
	pushw	49
	pushw	0
	ld	wa, (xsp+10)
	ldw	bc, 127
	ld	de, 0:i3
	jr	Param_SignExtendReturn_Join2
	pushw	127
	pushw	0
	ld	wa, (xsp+10)
	ldw	bc, 0xffff
	ld	de, 0:i3
Param_SignExtendReturn_Join2:
	calr	Param_SignExtendReturn_Helper2
	ld	(xsp+8), l
Param_SignExtendReturn_Skip12:
	ld	l, (xsp+8)
	pop	xiz
	inc	6, xsp
	ret
	ret
Param_SignExtendReturn_Join7:
	lda	xsp, (xsp-0x16)
	pushw	iz
	ld	(xsp+0x14), xwa
	ld	xwa, (xsp+0x14)
	calr	Param_SignExtendReturn_Helper
	ld	(xsp+0x6), hl
	ld	xwa, (xsp+0x14)
	calr	Param_SignExtendRetu_Data
	cpw	(xsp+0x6), 0
	jrl	z, Param_SignExtendReturn_Skip16
	cpw	(xsp+0x6), 120
	jrl	le, Param_SignExtendReturn_Skip16
	or	xhl, xhl
	jrl	z, Param_SignExtendReturn_Skip16
	ld	xwa, xhl
	sra	xwa, 15
	sra	xwa, 16
	and	xwa, 0x3fff
	add	xwa, xhl
	and	xwa, 0xffffc000
	ld	(xsp+0x2), xhl
	sub	(xsp+0x2), xwa
	ld	xbc, (xsp+0x2)
	ld	a, (xbc+0x10)
	and	a, 192
	cp	a, 192
	jrl	z, Param_SignExtendReturn_Join3
	cp	a, 64
	jrl	z, Param_SignExtendReturn_Join3
	cp	a, 128
	jr	z, Param_SignExtendReturn_Skip13
	cp	a, 0:i3
	jrl	nz, Param_SignExtendReturn_Join3
Param_SignExtendReturn_Skip13:
	cp	xbc, 470
	jr	ugt, Param_SignExtendReturn_Skip16
	lda	xde, (0xe198:16)
	ld	(xde), 45
	ld	xwa, (xsp+20)
	lda	xhl, (xwa+6)
	lda	xwa, (xde+1)
	ld	(xsp+12), xwa
	cp	iz, 6:i3
	jr	nc, Param_SignExtendReturn_Skip14
Param_SignExtendReturn_Loop:
	ld	xwa, (xsp+12)
	ld	c, (xhl)
	ld	(xwa), c
	inc	1, iz
	cp	iz, 6:i3
	jr	c, Param_SignExtendReturn_Loop
Param_SignExtendReturn_Skip14:
	ld	(xde+7), 0
	lda	xwa, (xde+8)
	ld	(xsp+16), xwa
	ld	(xsp+12), xwa
	ld	wa, (xsp+6)
	cp	iz, wa
	jr	nc, Param_SignExtendReturn_Skip15
Param_SignExtendReturn_Loop2:
	ld	xwa, (xsp+16)
	ld	c, (xwa+1)
	and	c, 15
	ld	xwa, (xsp+12)
	ld	a, (xwa)
	sll	a, 4
	or	a, c
	ld	c, a
	ld	xwa, (xsp+2)
	calr	Param_SignExtendReturn_Helper3
	ld	xwa, (xsp+16)
	ld	(xwa), l
	inc	1, iz
	ld	xwa, 2:i3
	add	(xsp+8), xwa
	ld	wa, (xsp+6)
	cp	iz, wa
	jr	c, Param_SignExtendReturn_Loop2
Param_SignExtendReturn_Skip15:
	ld	bc, (xsp+6)
	inc	8, bc
	ld	wa, 3:i3
	ld	xde, 0xe198
	call	sendCOMM
	ldw	(xsp+18), 0
	jr	Param_SignExtendReturn_Join3
Param_SignExtendReturn_Skip16:
	ldw	(xsp+18), 1
Param_SignExtendReturn_Join3:
	ld	hl, (xsp+18)
	popw	iz
	lda	xsp, (xsp+22)
	ret
SeqAlt_PopIzSkip4Ret2_Helper:
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
	jr	z, Param_SignExtendReturn_Skip17
	cp	a, 17
	jr	nz, Param_SignExtendReturn_Skip18
Param_SignExtendReturn_Skip17:
	ld	(0xe193:16), xde
	ld	wa, 3:i3
	ldw	bc, 21
	jr	Param_SignExtendReturn_Join4
Param_SignExtendReturn_Skip18:
	cp	a, 80
	jr	z, Param_SignExtendReturn_Skip19
	cp	a, 81
	jr	nz, Param_SignExtendReturn_Skip20
Param_SignExtendReturn_Skip19:
	cp	w, 2:i3
	jr	nc, Param_SignExtendReturn_Skip20
	ld	(0xe193:16), xde
	ld	wa, 3:i3
	ldw	bc, 21
Param_SignExtendReturn_Join4:
	call	sendCOMM
	ld	hl, 0:i3
	jr	Param_SignExtendReturn_Return
Param_SignExtendReturn_Skip20:
	ld	hl, 1:i3
Param_SignExtendReturn_Return:
	ret
	dec	2, xsp
	push	xiz
	ld	(0xe193:16), xwa
	ld	(xwa), 240
	ld	xwa, (0xe193:16)
	ld	(xwa+0x1), 80
	ld	xwa, (0xe193:16)
	ld	(xwa+0x2), 44
	ld	xwa, (0xe193:16)
	ld	(xwa+0x3), 4
	ld	xwa, (0xe193:16)
	ld	(xwa+0x4), 0
	ld	xwa, (0xe193:16)
	ld	(xwa+0x5), 17
	ld	xwa, (0xe193:16)
	calr	Param_SignExtendReturn_Helper
	ld	(xsp+0x4), hl
	ld	wa, (xsp+0x4)
	exts	xwa
	add	xwa, xwa
	ld	xbc, (0xe193:16)
	add	xbc, xwa
	add	xbc, 12
	ld	xiz, xbc
	inc	1, xiz
	ld	(xbc), 0
	ld	xwa, (0xe193:16)
	ld	bc, (xsp+0x4)
	add	bc, bc
	add	bc, 13
	call	Param_SignExtendReturn_Helper3_Helper
	ld	(xiz+), l
	ld	(xiz), 247
	ld	xwa, (0xe193:16)
	ld	bc, (xsp+0x4)
	add	bc, bc
	add	bc, 15
	call	Param_SignExtendReturn_Helper3_Helper2
	pop	xiz
	inc	2, xsp
	ret
SeqData_FormatOutput_Default_Helper:
	dec	4, xsp
	push	xiz
	ld	xiz, xwa
	ld	xwa, xiz
	calr	Param_SignExtendReturn_Helper
	ld	(xsp+0x6), hl
	ld	xwa, xiz
	calr	Param_SignExtendRetu_Data
	ld	bc, (xsp+0x6)
	exts	xbc
	cpw	(xsp+0x6), 0
	jr	z, Param_SignExtendReturn_Skip22
	cpw	(xsp+0x6), 120
	jr	le, Param_SignExtendReturn_Skip22
	or	xhl, xhl
	jr	z, Param_SignExtendReturn_Skip22
	ld	xwa, xhl
	sra	xwa, 15
	sra	xwa, 16
	and	xwa, 0x3fff
	add	xwa, xhl
	and	xwa, 0xffffc000
	sub	xhl, xwa
	ld	e, (xhl+0x10)
	and	e, 192
	cp	e, 192
	jr	z, Param_SignExtendReturn_Join6
	add	xhl, xbc
	cp	e, 128
	jr	z, Param_SignExtendReturn_Skip21
	cp	e, 64
	jr	z, Param_SignExtendReturn_Join6
	cp	e, 0:i3
	jr	nz, Param_SignExtendReturn_Join6
	cp	xhl, 0x1d6
	jr	ugt, Param_SignExtendReturn_Skip22
	ld	(0xe193:16), xiz
	ld	wa, 3:i3
	ld	bc, (xsp+0x6)
	ld	xde, xiz
	jr	Param_SignExtendReturn_Join5
Param_SignExtendReturn_Skip21:
	cp	xhl, 0x2927
	jr	ugt, Param_SignExtendReturn_Skip22
	ld	(0xe193:16), xiz
	ld	wa, 3:i3
	ld	bc, (xsp+6)
	ld	xde, xiz
Param_SignExtendReturn_Join5:
	call	sendCOMM
	ldw	(xsp+4), 0
	jr	Param_SignExtendReturn_Join6
Param_SignExtendReturn_Skip22:
	ldw	(xsp+4), 1
Param_SignExtendReturn_Join6:
	ld	hl, (xsp+4)
	pop	xiz
	inc	4, xsp
	ret

Param_SignExtendRetu_Block3:
	lda xde, (0xe2b8:16)
	ld (xde), 0x2b
	ld (xde + 1), 0x30
	ld (xde + 2), 0x7f
	ld (xde + 3), 0x20
	ld (xde + 4), 0x0
	ld (xde + 5), 0x0
	ld (xde + 6), 0x2
	inc 1, (0xe197:16)
	ld l, (0xe197:16)
	res 7, l
	ld (xde + 7), l
	ld (xde + 8), a
	ld (xde + 9), c
	ld wa, 3:i3
	ldw bc, 0xa
	call sendCOMM
	ld l, (0xe2bf:16)
	ret

Param_SignExtendRetu_Block4:
	lda xde, (0xe2c2:16)
	ld (xde), 0x2b
	ld (xde + 1), 0x30
	ld (xde + 2), 0x7f
	ld (xde + 3), 0x22
	ld (xde + 4), 0x0
	ld (xde + 5), 0x0
	ld (xde + 6), 0x2
	inc 1, (0xe197:16)
	ld l, (0xe197:16)
	res 7, l
	ld (xde + 7), l
	ld (xde + 8), a
	ld (xde + 9), c
	ld wa, 3:i3
	ldw bc, 0xa
	call sendCOMM
	ld l, (0xe2c9:16)
	ret

Param_SignExtendRetu_Block5:
	lda xde, (0xe2cc:16)
	ld (xde), 0x2b
	ld (xde + 1), 0x30
	ld (xde + 2), 0x7f
	ld (xde + 3), 0x24
	ld (xde + 4), 0x0
	ld (xde + 5), 0x0
	ld (xde + 6), 0x2
	inc 1, (0xe197:16)
	ld l, (0xe197:16)
	res 7, l
	ld (xde + 7), l
	ld (xde + 8), a
	ld (xde + 9), c
	ld wa, 3:i3
	ldw bc, 0xa
	call sendCOMM
	ld l, (0xe2d3:16)
	ret

SndParam_LookupPartIndex:
	lda xde, (0xe2d6:16)
	ld (xde), 0x2b
	ld (xde + 1), 0x30
	ld (xde + 2), 0x7f
	ld (xde + 3), 0x27
	ld (xde + 4), 0x0
	ld (xde + 5), 0x0
	ld (xde + 6), 0x2
	inc 1, (0xe197:16)
	ld l, (0xe197:16)
	res 7, l
	ld (xde + 7), l
	ld (xde + 8), a
	ld (xde + 9), c
	ld wa, 3:i3
	ldw bc, 0xa
	call sendCOMM
	ld l, (0xe2dd:16)
	ret

LookupPartIndex_Compare:
	cp wa, 4:i3
	jrl ugt, CommPacket_WriteMeas_Block
	lda xde, (0xe2e0:16)
	ld (xde), 0x2d
	ld (xde + 1), 0x0
	ld (xde + 3), 0x0
	ld (xde + 4), 0x0
	ld (xde + 5), 0x0
	lda xhl, (xde + 6)
	ld (xhl), 0x38
	ld (xde + 7), c
	lda xbc, (xde + 2)
	cp wa, 4:i3
	jr z, LookupPartIndex_LoadReg4
	cp wa, 3:i3
	jr z, LookupPartIndex_LoadReg3
	cp wa, 2:i3
	jr z, LookupPartIndex_LoadReg2
	cp wa, 1:i3
	jr z, LookupPartIndex_LoadReg
	cp wa, 0:i3
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
	cp c, 0:i3
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
	ld wa, 3:i3
	call sendCOMM

CommPacket_WriteMeas_Block:
	inc 1, (0xe197:16)
	ld l, (0xe197:16)
	res 7, l
	ret

SendCOMM_VariableLengthPacket:
	push xiz
	lda xhl, (0xe320:16)
	ld (xhl), 0x2c
	ld (xhl + 1), 0x0
	ld (xhl + 2), 0x8
	ld (xhl + 3), c
	ld (xhl + 4), 0x0
	ld (xhl + 5), 0x0
	ld (xhl + 6), e
	ld c, (0xe197:16)
	inc 1, c
	ld (0xe197:16), c
	res 7, c
	ld (xhl + 7), c
	ldiw_erp 0xe6, 0
	ldfr_berp E, 0xf0
	extz ix
	cp ix, 0:i3
	jr ule, SendCOMM_VariableLen_Increment
	ld xiy, xwa
	ldw bc, 0x8

SendCOMM_VariableLen_LoadReg:
	ld iz, bc
	extz xiz
	add xiz, xhl
	ld a, (xiy)
	ld (xiz), a
	inc1w_erp 0xe6
	inc 1, bc
	ldto_werp WA, 0xe6
	cp wa, ix
	jr c, SendCOMM_VariableLen_LoadReg

SendCOMM_VariableLen_Increment:
	inc 8, e
	extz de
	ld wa, 3:i3
	ld bc, de
	ld xde, xhl
	call sendCOMM
	ld l, (0xe197:16)
	res 7, l
	pop xiz
	ret

COMM_BuildAndSendPacket:
	lda xde, (0xe334:16)
	ld (xde), 0x2c
	ld (xde + 1), 0x30
	ld (xde + 2), 0x7f
	ld (xde + 3), 0x4
	ld (xde + 4), 0x0
	ld (xde + 5), 0x0
	ld (xde + 6), 0x2
	inc 1, (0xe197:16)
	ld l, (0xe197:16)
	res 7, l
	ld (xde + 7), l
	ld (xde + 8), a
	ld (xde + 9), c
	ld wa, 3:i3
	ldw bc, 0xa
	jp sendCOMM

BuildAndSendPacket_Block:
	lda xde, (0xe33e:16)
	ld (xde), 0x2c
	ld (xde + 1), 0x30
	ld (xde + 2), 0x7f
	ld (xde + 3), 0x6
	ld (xde + 4), 0x0
	ld (xde + 5), 0x0
	ld (xde + 6), 0x2
	inc 1, (0xe197:16)
	ld l, (0xe197:16)
	res 7, l
	ld (xde + 7), l
	ld (xde + 8), a
	ld (xde + 9), c
	ld wa, 3:i3
	ldw bc, 0xa
	jp sendCOMM

TmFlash_Return:
	lda xde, (0xe348:16)
	ld (xde), 0x2c
	ld (xde + 1), 0x30
	ld (xde + 2), 0x7f
	ld (xde + 3), 0x8
	ld (xde + 4), 0x0
	ld (xde + 5), 0x0
	ld (xde + 6), 0x1
	inc 1, (0xe197:16)
	ld a, (0xe197:16)
	res 7, a
	ld (xde + 7), a
	ld (xde + 8), 0x0
	ld wa, 3:i3
	ldw bc, 0x9
	jp sendCOMM

TmFlash_Return_Prologue:
	dec 6, xsp
	push xiz
	ld (xsp + 8), wa
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, TmFlash_ByteMap
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
	ld iz, 0:i3
	cpiw_erp 0xfa, 0
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
	cpw_erp IZ, 0xfa
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
	ld de, 0:i3
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
	ld a, (0xe356:16)
	extz wa
	ld (xbc), wa
	jr CommParam_SetComplete_Return

TmFlash_Return_LoadDRAM:
	ld a, (0xe357:16)
	extz wa
	ld (xbc), wa
	jr CommParam_SetComplete_Return

TmFlash_Return_LoadDRAM2:
	ld a, (0xe358:16)
	extz wa
	ld (xbc), wa
	jr CommParam_SetComplete_Return

TmFlash_Return_LoadDRAM3:
	ld a, (0xe359:16)
	extz wa
	ld (xbc), wa
	jr CommParam_SetComplete_Return

TmFlash_Return_LoadDRAM4:
	ld a, (0xe35a:16)
	extz wa
	ld (xbc), wa

CommParam_SetComplete_Return:
	pop xiz
	inc 6, xsp
	ret

CommParam_SetComplete_Block:
	ld (0xe356:16), 1
	ld (0xe357:16), 255
	ld (0xe358:16), 255
	ld (0xe359:16), 255
	ld (0xe35a:16), 255
	ld (0xe351:16), 255
	ld (0xe352:16), 255
	ld (0xe353:16), 255
	ld (0xe35b:16), 255
	ld (0xe354:16), 255
	ld (0xe35c:16), 255
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
	cp a, (0xe35c:16)
	ret z
	ldcf_dd8 4, 0x38
	scc8 c, a
	ld (0xe35c:16), a
	ld xwa, 0xe35c
	ldw bc, 0x8
	ld de, 1:i3
	call SendCOMM_VariableLengthPacket
	ret

CommPort_StatusCheck_Compare:
	cp a, c
	jr nz, CheckValidityReturn_SetByteFF
	ld wa, (0x8d38:16)
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
	ld l, 0x0:opc
	jr CheckValidityReturn_Return

CheckValidityReturn_SetByteFF:
	ld l, 0xff:opc

CheckValidityReturn_Return:
	ret

COMM_SendPartDataBlock:
	dec 2, xsp
	pushw_erp 0xfa
	ld (xsp + 2), a
	cp (xsp + 2), 0x4
	jr ugt, SendPartDataBlock_RestoreReg
	ld e, (xsp + 2)
	ld a, e
	extz wa
	muls wa, 0x38
	inc 8, wa
	lda xbc, (0x03c0fa:24)
	ld	wa, (xbc+wa)
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
	lda xde, (0x03c0fa:24)
	ld	bc, (xde+bc)
	extz bc
	calr CommPort_StatusCheck_Compare
	cp (xsp + 2), 0x3
	jr nz, SendPartDataBlock_LoadParam
	ld a, (0xe354:16)
	extz wa
	ld (0x03c1b6:24), wa

SendPartDataBlock_LoadParam:
	ld a, (xsp + 2)
	extz wa
	extz hl
	ld bc, hl
	call LookupPartIndex_Compare

SendPartDataBlock_RestoreReg:
	popw_erp 0xfa
	inc 2, xsp
	ret

SendPartDataBlock_Block:
	; --- Set-if-changed handlers for E351-E354 (4x24 = 96 bytes) ---
	cp	(0xe351:16), a
	ret z
	ld	(0xe351:16), a
	ld xwa, 0x0000e351
	ld	bc, 1:i3
	ld	de, 1:i3
	call SendCOMM_VariableLengthPacket
	ret
SendPartDataBlock_Block2:
	cp	(0xe352:16), a
	ret z
	ld	(0xe352:16), a
	ld xwa, 0x0000e352
	ld	bc, 2:i3
	ld	de, 1:i3
	call SendCOMM_VariableLengthPacket
	ret
SendPartDataBlock_Block3:
	cp	(0xe353:16), a
	ret z
	ld	(0xe353:16), a
	ld xwa, 0x0000e353
	ld	bc, 6:i3
	ld	de, 1:i3
	call SendCOMM_VariableLengthPacket
	ret
SendPartDataBlock_Block4:
	cp	(0xe354:16), a
	ret z
	ld	(0xe354:16), a
	ld xwa, 0x0000e354
	ld	bc, 7:i3
	ld	de, 1:i3
	call SendCOMM_VariableLengthPacket
	ret


SendPartDataBlock_ClearByte:
	ld c, 0x0:opc
	cp a, 0:i3
	jr z, SendPartDataBlock_Block5
	ld c, 0x1:opc

SendPartDataBlock_Block5:
	cp (0xe357:16), c
	ret z
	ld (0xe357:16), c
	ld xwa, 0xe357
	ldw bc, 0x21
	ld de, 1:i3
	call SendCOMM_VariableLengthPacket
	ret

SendPartDataBlock_ClearByte2:
	ld c, 0x0:opc
	cp a, 0:i3
	jr z, SendPartDataBlock_Block6
	ld c, 0x1:opc

SendPartDataBlock_Block6:
	cp (0xe358:16), c
	ret z
	ld (0xe358:16), c
	ld xwa, 0xe358
	ldw bc, 0x22
	ld de, 1:i3
	call SendCOMM_VariableLengthPacket
	ret

SendPartDataBlock_Block7:
	cp (0xe35b:16), a
	ret z
	ld c, 0x1:opc
	cp a, 0:i3
	jr nz, SendPartDataBlock_StoreDRAM
	ld c, 0x0:opc

SendPartDataBlock_StoreDRAM:
	ld (0xe35b:16), c
	ld xwa, 0xe35b
	ldw bc, 0x23
	ld de, 1:i3
	call SendCOMM_VariableLengthPacket
	ret

SendPartDataBlock_ClearByte3:
	ld c, 0x0:opc
	cp a, 0:i3
	jr z, SendPartDataBlock_Block8
	ld c, 0x1:opc

SendPartDataBlock_Block8:
	cp (0xe359:16), c
	ret z
	ld (0xe359:16), c
	ld xwa, 0xe359
	ldw bc, 0x24
	ld de, 1:i3
	call SendCOMM_VariableLengthPacket
	ret

SendPartDataBlock_Block9:
	ld	c, 0:opc
	cp	a, 0:i3
	jr	z, SendPartDataBlock_Block9_Skip
	ld	c, 1:opc
SendPartDataBlock_Block9_Skip:
	cp	(0xe35a:16), c
	ret	z
	ld	(0xe35a:16), c
	ld	xwa, 0xe35a
	ldw	bc, 37
	ld	de, 1:i3
	call	SendCOMM_VariableLengthPacket
	ret
	ld	(0x3c0fa:24), wa
	ld	hl, 0:i3
	ret
	ld	(0x3c0fc:24), wa
	ld	hl, 0:i3
	ret
	ld	(0x3c0fe:24), wa
	ld	hl, 0:i3
	ret
	ld	(0x3c100:24), wa
	ld	hl, 0:i3
	ret

SendPartDataBlock_InitVal:
	ld hl, 0:i3
	cp wa, 5:i3
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
	ld hl, 0:i3
	cp wa, 5:i3
	jr nc, SendPartDataBlock_SetWord2
	ld ix, wa
	extz xix
	ld xwa, xix
	sll xwa, 3
	sub xwa, xix
	sll xwa, 3
	ld xiy, xwa
	inc 8, xiy
	lda xix, (0x03c0fa:24)
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
	ld hl, 0:i3
	cp wa, 5:i3
	jr nc, SendPartDataBlock_SetWord3
	extz xwa
	ld xde, xwa
	sll xde, 3
	sub xde, xwa
	sll xde, 3
	inc 8, xde
	lda xwa, (0x03c126:24)
	add xwa, xde
	ld (xwa), bc
	jr SendPartDataBlock_Return2

SendPartDataBlock_SetWord3:
	ldw hl, 0xffff

SendPartDataBlock_Return2:
	ret

SendPartDataBlock_InitVal3:
	ld hl, 0:i3
	cp wa, 5:i3
	jr nc, SendPartDataBlock_SetWord4
	extz xwa
	ld xde, xwa
	sll xde, 3
	sub xde, xwa
	sll xde, 3
	inc 8, xde
	lda xwa, (0x03c120:24)
	add xwa, xde
	ld (xwa), bc
	jr SendPartDataBlock_Return3

SendPartDataBlock_SetWord4:
	ldw hl, 0xffff

SendPartDataBlock_Return3:
	ret

SendPartDataBlock_SetWord5:
	ldw bc, 0x24b8
	lda xwa, (0x1e0010:24)
	ld de, 0:i3

SendPartDataBlock_Block10:
	add DE, (xwa+)
	djnz16 bc, SendPartDataBlock_Block10
	cpl de
	ld hl, de
	ret

SendPartDataBlock_ClearByte4:
	ld w, 0x0:opc
	lda xde, (0x1e0000:24)
	lda xhl, (SoundRam_Id_KN5000:24)

SendPartDataBlock_LoadReg:
	ld c, w
	extz bc
	ld	a, (xhl+bc)
	cp	a, (xde+bc)
	jr nz, SendPartDataBlock_Compare
	inc 1, w
	cp w, 0x10
	jr c, SendPartDataBlock_LoadReg

SendPartDataBlock_Compare:
	cp w, 0x10
	jr nz, SendPartDataBlock_SetWord6
	calr SendPartDataBlock_SetWord5
	lda xwa, (0x1e0000:24)
	cp	(xwa+29352), hl
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
	call	SubCPU_Payload_GetErrorFlag
	cp	hl, 0xffff
	ret	nz
	ldw	wa, 0xff
	ldw	bc, 0xff
	call	COMM_BuildAndSendPacket
	ret

SendPartDataBlock_Return5:
	ret

SendPartDataBlock_Data:
	lda	xsp, (xsp-10)
	push	xiz
	ld	(xsp+10), xbc
	ld	xiz, xwa
	ld	xwa, xiz
	calr	SendPartDataBlock_Return5_Helper
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
	ldib_erp 230, 0
	ld bc, 0:i3
SendPartDataBlock_Return5_Loop:
	ld	hl, bc
	add	hl, 94
	ld	de, bc
	add	de, 33
	ld	xwa, (xsp+10)
	ld	a, (xwa+de)
	ld	(xiz+hl), a
	inc1b_erp 230
	inc 1, bc
	cp_erpb 230, 8
	jr c, SendPartDataBlock_Return5_Loop
	ld	(xsp+4), 0
	ldw (xsp+8), 0
	ldw (xsp+6), 0
SendPartDataBlock_Data_Loop:
	ld	wa, (xsp+6)
	add	wa, 102
	lda	xbc, (xiz+wa)
	ld de, (xsp+8)
	add de, 41
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
	jr	nz, SendPartDataBlock_Return5_Skip
	.byte 0xb1, 0xbf
SendPartDataBlock_Return5_Skip:
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
	addw	(xsp+6), 81
	addw	(xsp+8), 62
	cp	(xsp+4), 4
	jrl	c, SendPartDataBlock_Data_Loop
	pop	xiz
	lda	xsp, (xsp+10)
	ret
HdaeRom_DataHandler_Helper:
	lda	xhl, (xwa+16)
	ld	e, (xhl)
	and	e, 183
	ld	(xhl), e
	lda	xbc, (xwa+17)
	bit	7, (xbc)
	jr	z, HdaeRom_DataHandler_Helper_Skip
	set	6, e
	ld	(xhl), e
HdaeRom_DataHandler_Helper_Skip:
	bit	1, (xbc)
	jr	z, HdaeRom_DataHandler_Helper_Skip2
	.byte 0xb3, 0xbb
HdaeRom_DataHandler_Helper_Skip2:
	ld	c, (xwa+18)
	and	c, 240
	ldfr_berp	c, 240
	srl	c, 4
	extz	bc
	lda	xhl, (HdaeRom_DataByteMap:24)
	ld	c, (xhl+bc)
	ldfr_berp c, 240
	ldto_berp d, 240
	sll d, 6
	ld	e, (xwa+19)
	ld	c, e
	and	c, 240
	ldfr_berp	c, 240
	srl	c, 4
	extz	bc
	ld	c, (xhl+bc)
	ldfr_berp	c, 240
	sll	c, 4
	or	d, c
	and	e, 15
	ldfr_berp	e, 240
	ldto_berp	c, 240
	extz	bc
	ld	c, (xhl+bc)
	ldfr_berp c, 240
	sll c, 2
	or	d, c
	ld	(xwa+17), d
	lda	xbc, (xwa+20)
	ld	xde, xbc
	lda	xhl, (xbc+124)
SendPartDataBlock_Return5_Loop2:
	ld	c, (xde)
	ld	(xde-2), c
	inc	1, xde
	cp	xde, xhl
	jr	c, SendPartDataBlock_Return5_Loop2
	ld	hl, 0:i3
SendPartDataBlock_Return5_Loop3:
	ld	de, hl
	add	de, 40
	lda	xbc, (xwa+de)
	ld c, (xbc+17)
	ldfr_berp c, 240
	lda	xiy, (xwa+de)
	lda	xbc, (xwa+de)
	ld c, (xbc+16)
	ld (xiy+17), c
	lda	xiy, (xwa+de)
	lda	xbc, (xwa+de)
	ld c, (xbc+15)
	ld (xiy+16), c
	lda	xiy, (xwa+de)
	lda	xbc, (xwa+de)
	ld c, (xbc+14)
	ld (xiy+15), c
	lda	xiy, (xwa+de)
	lda	xbc, (xwa+de)
	ld c, (xbc+13)
	ld (xiy+14), c
	lda	xiy, (xwa+de)
	lda	xbc, (xwa+de)
	ld c, (xbc+12)
	ld (xiy+13), c
	exts xde
	add xde, xwa
	ldto_berp	c, 240
	ld	(xde+12), c
	add	hl, 34
	cp	hl, 102
	jr	lt, SendPartDataBlock_Return5_Loop3
	ret
SendPartDataBlock_Return5_Helper:
	lda xsp, (xsp-426)
	ld	xde, xwa
	ld	xiy, SoundRam_DefaultRecord
	ld	xix, xsp
	ldw	bc, 213
	ldirw
	ld	xiy, xsp
	ld	xix, xde
	ldw	bc, 213
	ldirw
	lda	xwa, (xde+102)
	ld	xiy, xwa
	lda xix, (xde+183)
	ldw bc, 40
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
	ldi85
	lda	xsp, (xsp+426)
	ret
HdaeRom_DataHandler_Helper2:
	lda	xsp, (xsp-0x1a)
	push	xiz
	ld	(xsp+0x16), xbc
	ld	(xsp+0x1a), xwa
	ld	xwa, (xsp+0x1a)
	calr	SendPartDataBlock_Return5_Helper
	ld	xde, (xsp+0x1a)
	lda	xhl, (xde+0x10)
	ld	xwa, (xsp+0x16)
	ld	xiy, xwa
	ld	xix, xde
	ldw	bc, 8
	ldirw
	lda	xwa, (xwa+0x10)
	bitm	7, (xwa)
	jr	z, HdaeRom_DataHandler_Helper2_Skip
	setm	5, (xhl)
	jr	HdaeRom_DataHandler_Helper2_Join
HdaeRom_DataHandler_Helper2_Skip:
	resm	5, (xhl)
HdaeRom_DataHandler_Helper2_Join:
	bitm	2, (xwa)
	jr	z, HdaeRom_DataHandler_Helper2_Skip2
	setm	4, (xhl)
	jr	HdaeRom_DataHandler_Helper2_Join2
HdaeRom_DataHandler_Helper2_Skip2:
	resm	4, (xhl)
HdaeRom_DataHandler_Helper2_Join2:
	ld	xhl, (xsp+0x1a)
	lda	xwa, (xhl+0x29)
	ld	(xsp+0xe), xwa
	andmi8	(xwa), 240
	lda	xwa, (xhl+0x2a)
	ld	(xsp+0xa), xwa
	ld	(xwa), 0
	ld	xix, (xsp+0x16)
	lda	xwa, (xix+0x11)
	ld	(xsp+0x12), xwa
	ld	a, (xwa)
	and	a, 192
	srl	a, 6
	inc	7, a
	ld	c, a
	ld	xwa, (xsp+0xe)
	or	(xwa), c
	ld	xiy, (xsp+0x12)
	ld	a, (xiy)
	and	a, 48
	srl	a, 4
	inc	7, a
	sll	a, 4
	ld	e, a
	ld	xwa, (xsp+0xa)
	ld	c, (xwa)
	or	c, e
	ld	xde, (xsp+0xa)
	ld	(xde), c
	ld	a, (xiy)
	and	a, 12
	srl	a, 2
	inc	7, a
	or	c, a
	ld	(xde), c
	ld	a, (xix+0x12)
	mul	a, 127
	extz	wa
	div	a, 30
	ld	c, a
	ld	(xhl+0x3b), c
	ld	xde, xix
	ld	a, (xde+0x13)
	ld	(xhl+0x2b), a
	lda	xwa, (xde+0x14)
	ld	(xsp+0x12), xwa
	ld	xbc, xhl
	lda	xwa, (xbc+0x2c)
	ld	(xsp+0xe), xwa
	lda	xwa, (xbc+0x3c)
	ld	(xsp+0xa), xwa
	ld	xwa, (xsp+0x12)
	ld	c, (xwa)
	cp	c, 9
	jr	nc, SendPartDataBlock_Return5_Skip2
	inc	5, c
	ld	xwa, (xsp+0xa)
	ld	(xwa), c
	ld	c, 5:opc
	jr	SendPartDataBlock_Return5_Join
SendPartDataBlock_Return5_Skip2:
	cp	c, 24
	jr	nc, SendPartDataBlock_Return5_Skip3
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
	jr	SendPartDataBlock_Return5_Join2
SendPartDataBlock_Return5_Skip3:
	add	c, 19
	ld	xwa, (xsp+10)
	ld	(xwa), c
	ld	c, 19:opc
SendPartDataBlock_Return5_Join:
	ld	xwa, (xsp+18)
	ld	a, (xwa)
	add	a, c
	ld	c, a
	ld	xwa, (xsp+14)
	ld	(xwa), c
SendPartDataBlock_Return5_Join2:
	ld	xix, (xsp+0x16)
	lda	xde, (xix+0x15)
	ld	c, (xde)
	ld	xhl, (xsp+0x1a)
	ld	(xhl+0x3e), c
	ld	c, (xde)
	ld	(xhl+0x2e), c
	ld	c, (xix+0x1e)
	sll	c, 3
	ld	(xhl+0x5c), c
	ld	xwa, xix
	lda	xwa, (xwa+0x1f)
	ld	(xsp+0x6), xwa
	ld	xde, xhl
	ld	a, (xwa)
	ld	(xde+0x5d), a
	ld	(xsp+0x4), 0
	ld	de, 0:i3
HdaeRom_DataHandler_Helper2_Loop:
	ld	ix, de
	add	ix, 94
	ld	hl, de
	add	hl, 32
	ld	xwa, (xsp+0x16)
	ld	xbc, (xsp+0x1a)
	ld	a, (xwa+hl)
	ld	(xbc+ix), a
	incm8	1, (xsp+0x4)
	inc	1, de
	cp	(xsp+0x4), 8
	jr	c, HdaeRom_DataHandler_Helper2_Loop
	ld	xwa, (xsp+0x6)
	ld	a, (xwa)
	and	a, 15
	cp	a, 10
	jr	z, HdaeRom_DataHandler_Helper2_Skip3
	cp	a, 11
	jr	nz, SendPartDataBlock_Return5_Skip4
HdaeRom_DataHandler_Helper2_Skip3:
	ld	xwa, (xsp+0x1a)
	lda	xwa, (xwa+0x60)
	ld	(xsp+0x12), xwa
	ld	xwa, (xsp+0x16)
	cp	(xwa+0x22), 50
	jr	ule, HdaeRom_DataHandler_Helper2_Skip4
	ld	xwa, (xsp+0x12)
	ld	(xwa), 50
HdaeRom_DataHandler_Helper2_Skip4:
	ld	xwa, (xsp+0x6)
	bitm	7, (xwa)
	jr	z, SendPartDataBlock_Return5_Skip4
	ld	xhl, (xsp+0x16)
	lda	xde, (xhl+0x1c)
	ld	a, (xde)
	bit	6, a
	jr	z, SendPartDataBlock_Return5_Skip4
	ld	xbc, (xsp+0x1a)
	ld	(xbc+0x5e), 1
	ld	a, (xhl+0x1d)
	ld	(xbc+0x5f), a
	ld	c, (xde)
	and	c, 63
	ld	xwa, (xsp+0x12)
	ld	(xwa), c
SendPartDataBlock_Return5_Skip4:
	ld	xbc, (xsp+26)
	lda	xwa, (xbc+17)
	ld	(xsp+10), xwa
	and	(xwa), 170
	lda	xbc, (xbc+102)
	ld	xwa, (xsp+22)
	lda	xde, (xwa+40)
	ld	(xsp+4), 0
SendPartDataBlock_Return5_Entry:
	bit	7, (xde)
	jr	z, HdaeRom_DataHandler_Helper2_Join3
	cp	(xsp+4), 0
	jr	nz, HdaeRom_DataHandler_Helper2_Skip5
	ld	xwa, (xsp+10)
	set	0, (xwa)
	jr	HdaeRom_DataHandler_Helper2_Join3
HdaeRom_DataHandler_Helper2_Skip5:
	cp	(xsp+4), 1
	jr	nz, HdaeRom_DataHandler_Helper2_Entry
	ld	xwa, (xsp+10)
	.byte 0xb0, 0xba
	jr	HdaeRom_DataHandler_Helper2_Join3
HdaeRom_DataHandler_Helper2_Entry:
	.byte 0x8f, 0x04
	push	xsp
	push	sr
	jr	nz, HdaeRom_DataHandler_Helper2_Join3
	ld	xwa, (xsp+10)
	.byte 0xb0, 0xbc
HdaeRom_DataHandler_Helper2_Join3:
	lda	xwa, (xbc+6)
	ld	(xwa), 0
	lda	xhl, (xbc+38)
	ld	(xhl), 0
	bit	6, (xde)
	jr	z, HdaeRom_DataHandler_Helper2_Skip6
	set	5, (xwa)
	ld	a, (xhl)
	set	5, a
	ld	(xhl), a
HdaeRom_DataHandler_Helper2_Skip6:
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
	jr	ule, SendPartDataBlock_Return5_Skip5
	ld	(xhl), a
SendPartDataBlock_Return5_Skip5:
	ld	a, (xiy)
	cp	(xhl), a
	jr	ule, SendPartDataBlock_Return5_Skip6
	ld	(xhl), a
SendPartDataBlock_Return5_Skip6:
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
	.set	SendPartDataBlock_Data3, . + 2	; no instruction starts here: the name points 2 byte(s) into the one below
	sll	a, 1
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
	cp	(xwa), 0
	jr	nz, SendPartDataBlock_Return5_Skip7
	ld	xwa, (xsp+14)
	cp	(xwa), 0
	jr	z, SendPartDataBlock_Return5_Entry2
	ld	a, (xde+22)
	ld	(xix), a
	ld	xwa, 23
	jr	SendPartDataBlock_Return5_Join3
SendPartDataBlock_Return5_Entry2:
	.byte 0x86
	push	xsp
	nop
	jr	z, SendPartDataBlock_Return5_Skip7
	ld	a, (xde+25)
	ld	(xix), a
	ld	xwa, 26
SendPartDataBlock_Return5_Join3:
	ld	xiz, xde
	add	xiz, xwa
	ld	a, (xiz)
	ld	(xiy), a
SendPartDataBlock_Return5_Skip7:
	ld	a, (xix)
	cp	(xhl), a
	jr	nc, SendPartDataBlock_Return5_Skip8
	ld	(xhl), a
SendPartDataBlock_Return5_Skip8:
	ld	a, (xiy)
	cp	(xhl), a
	jr	ule, SendPartDataBlock_Return5_Skip9
	ld	(xhl), a
SendPartDataBlock_Return5_Skip9:
	lda	xwa, (xbc+54)
	ld	(xsp+18), xwa
	ld	a, (xde+29)
	inc	3, a
	sla	a, 5
	ld	l, a
	ld	xwa, (xsp+18)
	ld	(xwa), l
	cp	(xde+30), 255
	jr	z, SendPartDataBlock_Return5_Entry2_Code_Skip
	.set	SendPartDataBlock_Data4, . + 1	; no instruction starts here: the name points 1 byte(s) into the one below
	set	0, l
	ld	(xwa), l
SendPartDataBlock_Return5_Entry2_Code_Skip:
	lda	xix, (xbc+77)
	ld	a, (xde+27)
	ld	(xix), a
	ld	xwa, (xsp+6)
	ld	l, (xwa)
	ld	a, l
	and	a, 128
	cp	a, 128
	jr	nz, SendPartDataBlock_Return5_Entry2_Code_Skip2
	and	l, 15
	cp	l, 10
	jr	nz, SendPartDataBlock_Return5_Entry2_Code_Skip2
	ld	(xix), 127
SendPartDataBlock_Return5_Entry2_Code_Skip2:
	ld	a, (xde+28)
	ld	(xbc+55), a
	ld	a, (xde+31)
	ld	(xbc+60), a
NoteEditBox_EventDispatch2_Data_2:
	lda	xix, (xbc+58)
PmBank_DrawRegionInfo_Data:
	ld	a, (xde+32)
	ld	(xix), a
	lda	xiy, (xbc+59)
	.set	SendPartDataBlock_Data5, . + 2	; no instruction starts here: the name points 2 byte(s) into the one below
	ld	a, (xde+33)
	ld	(xiy), a
	lda	xhl, (xbc+57)
	ld	(xhl), 66
	ld	a, (xix)
	cp	a, 66
	jr	ule, SendPartDataBlock_Return5_Entry2_Code_Skip3
	ld	(xhl), a
SendPartDataBlock_Return5_Entry2_Code_Skip3:
	ld	a, (xiy)
	cp	(xhl), a
	jr	ule, SendPartDataBlock_Return5_Skip10
	ld	(xhl), a
SendPartDataBlock_Return5_Skip10:
	incm8	1, (xsp+4)
	lda	xbc, (xbc+81)
	lda	xde, (xde+34)
	.byte 0x8f, 0x04
	push	xsp
	pop	sr
	jrl	c, SendPartDataBlock_Return5_Entry
	pop	xiz
	lda	xsp, (xsp+26)
	ret

SendPartDataBlock_InitVal4:
	ld de, 0:i3
	lda xhl, (SoundRam_Id_KN5000:24)

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
	ld l, 0x6:opc
	ret

SendPartDataBlock_InitVal5:
	ld de, 0:i3
	lda xhl, (SoundRam_Id_KN1500:24)

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
	ld l, 0x5:opc
	ret

SendPartDataBlock_InitVal6:
	ld de, 0:i3
	lda xhl, (SoundRam_Id_KN3000:24)

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
	ld l, 0x4:opc
	ret

SendPartDataBlock_InitVal7:
	ld de, 0:i3
	lda xhl, (SoundRam_Id_KN2000:24)

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
	cp de, 6:i3
	jr c, SendPartDataBlock_LoadReg5

SendPartDataBlock_Compare5:
	cp de, 6:i3
	jr nz, SendPartDataBlock_InitVal8
	ld l, 0x1:opc
	ret

SendPartDataBlock_InitVal8:
	ld de, 0:i3
	lda xhl, (SoundRam_Id_MKA:24)

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
	cp de, 3:i3
	jr c, SendPartDataBlock_LoadReg6

SendPartDataBlock_Compare6:
	cp de, 3:i3
	jr nz, SendPartDataBlock_InitVal9
	ld l, 0x2:opc
	ret

SendPartDataBlock_InitVal9:
	ld de, 0:i3
	lda xhl, (SoundRam_Id_MKB:24)

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
	cp de, 3:i3
	jr c, SendPartDataBlock_LoadReg7

SendPartDataBlock_Compare7:
	cp de, 3:i3
	jr nz, SendPartDataBlock_ClearByte5
	ld l, 0x3:opc
	ret

SendPartDataBlock_ClearByte5:
	ld l, 0x0:opc
	ret

SendPartDataBlock_SetWord7:
	ldw de, 0x24b8
	lda xbc, (0x1e0000:24)
	lda xwa, (xbc + 16)
	ld hl, 0:i3

SendPartDataBlock_Block11:
	add HL, (xwa+)
	djnz16 de, SendPartDataBlock_Block11
	cpl hl
	ld	(xbc+29352), hl
	ret

; HDAE ROM data dispatch handler
HdaeRom_DataHandler:
	lda xsp, (xsp-440)
	push xiz
	ld	(xsp+440), c
	ld	(xsp+442), a
	ld xwa, 0x1e0000
	calr SendPartDataBlock_InitVal4
	lda xbc, (0x1e0000:24)
	extz hl
	dec 1, hl
	cp hl, 0:i3
	jrl lt, HdaeRom_DataDispatch_SetWord
	cp hl, 5:i3
	jrl gt, HdaeRom_DataDispatch_SetWord
	add hl, hl
	lda xix, (HdaeRom_DispatchOffsetTable:24)
	ld	hl, (xix+hl)
	lda xix, (HdaeRom_DataDispatch:24)
	jp	t, (xix+hl)
; HDAE5000 extension ROM data dispatch (6-entry, table HdaeRom_DispatchOffsetTable)
HdaeRom_DataDispatch:
	ld	(xsp+6), xbc
	cp	(xsp+442), 255
	jrl	nz, HdaeRom_DataHandler_Skip
	cp	(xsp+440), 255
	jrl	nz, HdaeRom_DataHandler_Skip
	ldw	(xsp+4), 40
HdaeRom_DataHandler_Loop2:
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
	add	xiy, (xsp+6)
	ld	xix, (xsp+10)
	ldw	bc, 144
	ldirw
	ldi85
	ld	xwa, xiz
	ld	xbc, 470
	call	Math_MultiplyAccumulate
	add	xhl, 16
	add	xhl, (xsp+6)
	ld	xwa, xhl
	ld	xbc, (xsp+10)
	calr	SendPartDataBlock_Data
	subw	(xsp+4), 1
	jr	nz, HdaeRom_DataHandler_Loop2
	jrl	HdaeRom_DataHandler_Skip
	ld	(xsp+6), xbc
	cp	(xsp+442), 255
	jr	nz, HdaeRom_DataHandler_Skip2
	cp	(xsp+440), 255
	jr	nz, HdaeRom_DataHandler_Skip2
	ldw	(xsp+4), 36
HdaeRom_DataHandler_Loop3:
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
	ldw	(36:8), 0x4831:io
	nop
	ldirw
	ld	xbc, 470
	call	Math_MultiplyAccumulate
	add	xhl, 16
	add	xhl, (xsp+6)
	ld	xwa, xhl
	ld	xbc, (xsp+10)
	calr	HdaeRom_DataHandler_Helper2
	subw	(xsp+4), 1
	jr	nz, HdaeRom_DataHandler_Loop3
	jr	HdaeRom_DataHandler_Skip
HdaeRom_DataHandler_Skip2:
	ld	a, (xsp+440)
	extz	wa
	ld	(xsp+4), wa
	jr	HdaeRom_DataHandler_Join
HdaeRom_DataHandler_Loop:
	ld	wa, (xsp+4)
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 3
	add	xbc, xwa
	sll	xbc, 4
	add	xbc, 80
	add	xbc, (xsp+6)
	ld	xwa, xbc
	calr	HdaeRom_DataHandler_Helper
	ld	iz, (xsp+4)
	extz	xiz
	ld	xwa, xiz
	ld	xbc, 470
	call	Math_MultiplyAccumulate
	add	xhl, 16
	add	xhl, (xsp+6)
	ld	xbc, xiz
	sll	xbc, 3
	add	xbc, xiz
	sll	xbc, 4
	add	xbc, 80
	add	xbc, (xsp+6)
	ld	xwa, xhl
	calr	HdaeRom_DataHandler_Helper2
	incw	1, (xsp+4)
HdaeRom_DataHandler_Join:
	ld	a, (xsp+440)
	inc	1, a
	extz	wa
	cp	(xsp+4), wa
	jr	c, HdaeRom_DataHandler_Loop
HdaeRom_DataHandler_Skip:
	ld	hl, 0:i3
	jr	HdaeRom_DataHandler_Epilogue

HdaeRom_DataDispatch_SetWord:
	ldw	hl, 0xff9a
HdaeRom_DataHandler_Epilogue:
	pop	xiz
	lda	xsp, (xsp+440)
	ret

HdaeRom_DataDispatch_Block:
	lda	xde, (0x1e0000:24)
	lda	xwa, (SoundRam_Id_KN5000:24)
	ld	xbc, xwa
	lda	xhl, (xwa + 16)

HdaeRom_DataDispatch_Block2:
	ld	A, (xbc+)
	ld	(xde+), a
	cp	xbc, xhl
	jr	c, HdaeRom_DataDispatch_Block2
	calr	SendPartDataBlock_SetWord7
	ld	hl, 0:i3
	ret

HdaeRom_DataDispatch_Block3:
	lda	xhl, (xwa+18833)
	lda xix, (xwa+29351)
	dec 1, xix
	cp xix, xhl
	jr	c, HdaeRom_DataDispatch_Block3_Skip
	lda	xde, (xix-1)
HdaeRom_DataDispatch_Block3_Loop2:
	ld	c, (xde)
	ld	(xde+1), c
	dec	1, xde
	dec	1, xix
	cp	xix, xhl
	jr	nc, HdaeRom_DataDispatch_Block3_Loop2
; For QE = 0..127 and DE = 2*QE: XHL = XWA + 0x49A7 + DE, then bits 5..4 of
; the byte at XHL+1 become 0b10 (clear 0x30, set bit 5; XBC = XWA + exts(BC)
; reaches the same byte).  Re-framed 2026-10-02 from MAME unidasm's reading
; at this label: the source had cut `lda xhl, (xwa+bc)` (f3 07 e0 e4 33) into
; `.byte 0xf3 / reti / .byte 0xe0, 0xe4 ...`, and that framing spelled a
; rotate whose count byte the CPU reads as 3 as `rrc_i_8 l, 19`.
HdaeRom_DataDispatch_Block3_Skip:
	ld	(xhl), 1
	ldib_erp	234, 0	; ld QE,0 (the assembler has no byte-register name for QE yet)
	ld	de, 0:i3
HdaeRom_DataDispatch_Block3_Loop:
	ld	bc, de
	add	bc, 0x49a7
	lda	xhl, (xwa+bc)
	and	(xhl+1), 0xcf
	exts	xbc
	add	xbc, xwa
	set	5, (xbc+1)
	incb_erp	234, 1	; inc 1,QE
	inc	2, de
	cp_erpb	234, 0x80	; cp QE,0x80
	jr	c, HdaeRom_DataDispatch_Block3_Loop
	ret

; HDAE ROM alt dispatch handler
HdaeRom_AltHandler:
	pushw iz
	ld xwa, 0x1e0000
	calr SendPartDataBlock_InitVal4
	extz hl
	dec 1, hl
	cp hl, 0:i3
	jr lt, HdaeRom_AltDispatch_SetWord
	cp hl, 5:i3
	jr gt, HdaeRom_AltDispatch_SetWord
	add hl, hl
	lda xix, (HdaeRom_AltDispatchOffsetTable:24)
	ld	hl, (xix+hl)
	lda xix, (HdaeRom_AltDispatch:24)
	jp	t, (xix+hl)
; HDAE5000 extension ROM alt dispatch (6-entry, table HdaeRom_AltDispatchOffsetTable)
HdaeRom_AltDispatch:
	ld	xwa, 0x1e0000
	calr	HdaeRom_DataDispatch_Block3
	ld	iz, 0:i3
	jr	HdaeRom_AltHandler_Join

HdaeRom_AltDispatch_SetWord:
	ldw iz, 0xff9a
HdaeRom_AltHandler_Join:
	lda xde, (0x1e0000:24)
	lda xwa, (SoundRam_Id_KN5000:24)
	ld xbc, xwa
	lda xhl, (xwa + 16)

HdaeRom_AltDispatch_Block:
	ld A, (xbc+)
	ld (xde+), a
	cp xbc, xhl
	jr c, HdaeRom_AltDispatch_Block
	calr SendPartDataBlock_SetWord7
	ld hl, iz
	popw iz
	ret

PreTmLoad:
	ret

PostTmLoad:
	cp wa, 0:i3
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
	cp wa, 0:i3
	ret ge
	ldw wa, 0xff
	ldw bc, 0xff
	call COMM_BuildAndSendPacket
	ret

PostTmSave_ByteBlock:
	calr	SendPartDataBlock_InitVal4
	cp	l, 6:i3
	jr	ugt, PostTmSave_ByteBlock_Skip
	cp	l, 1:i3
	jr	c, PostTmSave_ByteBlock_Skip
	ld	hl, 0:i3
	ret
PostTmSave_ByteBlock_Skip:
	ldw	hl, 0xff9a
	ret

PostTmSave_Success:
	cp wa, 0:i3
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
TmFlashWrite_Block1_Entry:
	dec	4, xsp
	ld	(xsp), c
	ld	(xsp+2), a
	ld	a, (xsp+2)
	extz	wa
	ld	c, (xsp)
	extz	bc
	cp	de, 0:i3
	jr	lt, TmFlashWrite_Block1_Entry_Skip2
	cp	(xsp+2), 0x40
	jr	nc, TmFlashWrite_Block1_Entry_Skip
	calr	HdaeRom_DataHandler
	calr	HdaeRom_DataDispatch_Block
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
	ld	xwa, 0x1e0000
	add	xwa, xhl
	lda	xde, (xhl+30720)
	ldw	bc, 470
	jr	TmFlashWrite_Block1_Entry_Join
TmFlashWrite_Block1_Entry_Skip:
	calr	HdaeRom_AltHandler
	calr	HdaeRom_DataDispatch_Block
	ld	a, (xsp)
	extz	wa
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 4
	add	xbc, 0x4aa7
	ld	xwa, 0x1e0000
	add	xwa, xbc
	lda	xde, (xbc+30720)
	ldw	bc, 80
TmFlashWrite_Block1_Entry_Join:
	call	InterCPU_E1_Bulk_Transfer
	ld	a, (xsp+2)
	extz	wa
	ld	c, (xsp)
	extz	bc
	call	BuildAndSendPacket_Block
	jr	TmFlashWrite_Block1_Entry_Join2
TmFlashWrite_Block1_Entry_Skip2:
	call	COMM_BuildAndSendPacket
TmFlashWrite_Block1_Entry_Join2:
	call	FDemoText_RefreshFullDisplay
	inc	4, xsp
	ret
TmFlashWrite_Block1_Return:
	ret
TmFlashWrite_ValidateParams:
	dec	2, xsp
	push	xiz
	ld	(xsp+4), a
	cp	bc, 0:i3
	jrl	lt, TmFlashWrite_Block2_Code_Skip
	ld	iz, 0:i3
	cp	(xsp+4), 64
	jr	nc, TmFlashWrite_ValidateParams_Loop2
TmFlashWrite_ValidateParams_Loop:
	ld	a, (xsp+4)
	extz	wa
	ldto_berp	c, 248
	extz	bc
	calr	HdaeRom_DataHandler
	inc	1, iz
	cp	iz, 20
	jr	c, TmFlashWrite_ValidateParams_Loop
	calr	HdaeRom_DataDispatch_Block
	ld	a, (xsp+4)
	ldfr_berp	a, 248
	extz	iz
	mul	iz, 20
	ld	wa, iz
	extz	xwa
	ld	xbc, 470
	call	Math_MultiplyAccumulate
	add	xhl, 16
	ld	xwa, 0x1e0000
	add	xwa, xhl
	lda	xde, (xhl+30720)
	ldw	bc, 9400
	jr	TmFlashWrite_Block3
TmFlashWrite_ValidateParams_Loop2:
	ld	a, (xsp+4)
	extz	wa
	ldto_berp	c, 248
	extz	bc
	calr	HdaeRom_AltHandler
	inc	1, iz
	cp	iz, 128
	jr	c, TmFlashWrite_ValidateParams_Loop2
	calr	HdaeRom_DataDispatch_Block
	lda	xwa, (0x1e4aa7:24)
	ldw	bc, 0x2800
	.set	TmFlashWrite_Block2, . + 1	; no instruction starts here: the name points 1 byte(s) into the one below
	ld	xde, 0xc2a7
TmFlashWrite_Block3:
	call	InterCPU_E1_Bulk_Transfer
	ld	a, (xsp+4)
	extz	wa
	ldw	bc, 255
	call	BuildAndSendPacket_Block
	jr	TmFlashWrite_ValidateParams_Join
TmFlashWrite_Block2_Code_Skip:
	ld	a, (xsp+0x4)
	extz	wa
	ldw	bc, 255
	call	COMM_BuildAndSendPacket
TmFlashWrite_ValidateParams_Join:
	call	FDemoText_RefreshFullDisplay
	pop	xiz
	inc	2, xsp
	ret

TmFlash_CopyToExtMem:
	lda xwa, (0x300000:24)
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
	jr	z, TmFlash_WriteRoutine_Skip2
	lda	xiz, (0x300000:24)
	add	xiz, 0xb0400
	ld	xde, xiz
	bitm	1, (xsp+20)
	jr	z, TmFlash_WriteRoutine_Entry
	cpw	(xsp+18), 4
	jr	nc, TmFlash_WriteRoutine_Skip
	ld	xwa, (xsp+14)
	ld	(xsp+6), xwa
	ld	xwa, (xsp+10)
	ld	xbc, 0x2927
	call	Math_MultiplyAccumulate
	add	xhl, 0x4980
	add	xhl, xiz
	ld	xwa, (xsp+6)
	ld	(xwa), xhl
	ldw	wa, 10535
	jr	TmFlash_WriteRoutine_Entry_Code_Join
TmFlash_WriteRoutine_Skip:
	ld	(xsp+4), 255
TmFlash_WriteRoutine_Join:
	ld	l, (xsp+4)
	exts	hl
	pop	xiz
	lda	xsp, (xsp+18)
	retd	4
TmFlash_WriteRoutine_Entry:
	.byte 0x9f
	ccf
	push	xsp
	pushw	wa
	nop
	jr	nc, TmFlash_WriteRoutine_Skip
	add	xhl, xde
	ld	xwa, (xsp+14)
	ld	(xwa), xhl
	ldw	wa, 470
	jr	TmFlash_WriteRoutine_Entry_Code_Join
TmFlash_WriteRoutine_Skip2:
	lda	xbc, (0x1e0000:24)
	bit	1, (xsp+20)
	jr	z, TmFlash_WriteRoutine_Entry_Code_Entry
	cpw	(xsp+18), 1
	jr	nc, TmFlash_WriteRoutine_Skip
	lda xbc, (xbc+18816)
	ld xwa, (xsp+14)
	ld (xwa), xbc
	ldw	wa, 10535
	jr	TmFlash_WriteRoutine_Entry_Code_Join
TmFlash_WriteRoutine_Entry_Code_Entry:
	.byte 0x9f
	ccf
	push	xsp
	pushw	wa
	nop
	jr	nc, TmFlash_WriteRoutine_Skip
	add	xbc, xhl
	ld	xwa, (xsp+14)
	ld	(xwa), xbc
	ldw	wa, 470
TmFlash_WriteRoutine_Entry_Code_Join:
	ld	xbc, (xsp+26)
	ld	(xbc), wa
	jr	TmFlash_WriteRoutine_Join
TmFlash_BulkTransferToSubCPU:
	ld	xwa, 0x1e0000
	ldw	bc, 0x72aa
	ld	xde, 0x7800
	call	InterCPU_E1_Bulk_Transfer
	jp	TmFlash_Return
	ld	xwa, 0x1e0000
	calr	SendPartDataBlock_InitVal4
	ldw	wa, 0xff9a
	cp	l, 6:i3
	jr	nz, TmFlash_BulkTransferToSubCPU_Skip
	ld	wa, 0:i3
TmFlash_BulkTransferToSubCPU_Skip:
	ld	hl, wa
	ret
	ld	xwa, 0x1e0000
	calr	SendPartDataBlock_InitVal4
	cp	l, 6:i3
	jr	ugt, TmFlash_BulkTransferToSubCPU_Skip2
	cp	l, 1:i3
	jr	c, TmFlash_BulkTransferToSubCPU_Skip2
	ld	hl, 0:i3
	ret
TmFlash_BulkTransferToSubCPU_Skip2:
	ldw	hl, 0xff9a
	ret
	extz	xwa
	ld	xbc, 470
	call	Math_MultiplyAccumulate
	ld	xwa, xhl
	add	xwa, 16
	ld	xhl, 0x1e0000
	add	xhl, xwa
	ret
	dec	4, xsp
	pushw	iz
	ld	iz, bc
	ld	(xsp+2), xwa
	ld	xwa, (xsp+2)
	calr	SendPartDataBlock_InitVal4
	ld	wa, iz
	extz	xwa
	extz	hl
	dec	1, hl
	cp	hl, 0:i3
	jr	lt, TmFlash_BulkTransferToSubCPU_Skip3
	cp	hl, 5:i3
	jr	gt, TmFlash_BulkTransferToSubCPU_Skip3
	add	hl, hl
	lda	xix, (TmFlashBulkA_SwitchOffsets:24)
	ld	hl, (xix+hl)
	lda	xix, (VoiceParam_DispatchTable1:24)
	jp	t, (xix+hl)	; (xix + hl) SRI dispatch
VoiceParam_DispatchTable1:
	ld	xbc, 470
	jr	TmFlash_BulkTransferToSubCPU_Join
	ld	xbc, 289
TmFlash_BulkTransferToSubCPU_Join:
	call	Math_MultiplyAccumulate
	add	xhl, 16
	.byte 0xaf
	push	sr
	decm8	8, (xhl)
	call16 35304
	sll	xbc, 3
	add	xbc, xwa
	sll	xbc, 4
	add	xbc, 80
	add	xbc, (xsp+2)
	ld	xhl, xbc
	jr	TmFlash_BulkTransferToSubCPU_Epilogue
TmFlash_BulkTransferToSubCPU_Skip3:
	ld	xhl, 0xffffff9a
TmFlash_BulkTransferToSubCPU_Epilogue:
	popw	iz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	cp	wa, 40
	jr	nc, TmFlash_BulkTransferToSubCPU_Skip4
	ld	xiz, xbc
	extz	xwa
	ld	xbc, 470
	call	Math_MultiplyAccumulate
	add	xhl, 16
	ld	xwa, 0x1e0000
	add	xwa, xhl
	ld	(xiz), xwa
	ld	xwa, (xsp+4)
	ldw	(xwa), 470
	ld	hl, 0:i3
	jr	TmFlash_BulkTransferToSubCPU_Epilogue2
TmFlash_BulkTransferToSubCPU_Skip4:
	ldw	hl, 0xff38
TmFlash_BulkTransferToSubCPU_Epilogue2:
	pop	xiz
	inc	4, xsp
	ret
	dec	8, xsp
	pushw	iz
	ld	(xsp+0x2), xde
	ld	iz, bc
	ld	(xsp+0x6), xwa
	ld	xwa, (xsp+0x6)
	calr	SendPartDataBlock_InitVal4
	ld	bc, iz
	extz	xbc
	extz	hl
	dec	1, hl
	cp	hl, 0:i3
	jrl	lt, TmFlash_BulkTransferToSubCPU_Skip5
	cp	hl, 5:i3
	jrl	gt, TmFlash_BulkTransferToSubCPU_Skip5
	add	hl, hl
	lda	xix, (TmFlashBulkB_SwitchOffsets:24)
	ld	hl, (xix+hl)
	lda	xix, (VoiceParam_DispatchTable1_Code:24)
	jp	t, (xix+hl)
VoiceParam_DispatchTable1_Code:
	ld	xwa, xbc
	ld	xbc, 0x1d6
	call	Math_MultiplyAccumulate
	add	xhl, 16
	add	xhl, (xsp+0x6)
	sub	xhl, (xsp+0x6)
	ld	xwa, (xsp+0x2)
	ld	(xwa), xhl
	ldw	wa, 0x1d6
	jr	TmFlash_BulkTransferToSubCPU_Join2
	ld	xwa, xbc
	ld	xbc, 0x121
	call	Math_MultiplyAccumulate
	add	xhl, 16
	add	xhl, (xsp+0x6)
	sub	xhl, (xsp+0x6)
	ld	xwa, (xsp+0x2)
	ld	(xwa), xhl
	ldw	wa, 0x121
	jr	TmFlash_BulkTransferToSubCPU_Join2
	ld	xwa, xbc
	sll	xwa, 3
	add	xwa, xbc
	sll	xwa, 4
	add	xwa, 80
	ld	xhl, xwa
	add	xhl, (xsp+0x6)
	sub	xhl, (xsp+0x6)
	ld	xwa, (xsp+0x2)
	ld	(xwa), xhl
	ldw	wa, 144
TmFlash_BulkTransferToSubCPU_Join2:
	ld	xbc, (xsp+14)
	ld	(xbc), wa
	ld	hl, 0:i3
	jr	TmFlash_BulkTransferToSubCPU_Epilogue3
TmFlash_BulkTransferToSubCPU_Skip5:
	ldw	hl, 0xff9a
TmFlash_BulkTransferToSubCPU_Epilogue3:
	popw	iz
	inc	8, xsp
	retd	4
TmFlash_CompareStrings:
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
	jr	z, TmFlash_CompareStrings_Skip2
	jr	TmFlash_CompareStrings_Join
TmFlash_CompareStrings_Loop:
	ld	a, (xsp+8)
	cp	a, (xiz)
	jr	nz, TmFlash_CompareStrings_Skip
	pushw	(xsp+6)
	push	xiz
	ld	xwa, (xsp+24)
	push	xwa
	call	Mem_Compare
	add	xsp, 10
	cp	hl, 0:i3
	jr	nz, TmFlash_CompareStrings_Skip
TmFlash_CompareStrings_Skip2:
	ld	xhl, xiz
	jr	TmFlash_CompareStrings_Epilogue
TmFlash_CompareStrings_Skip:
	inc	1, xiz
	decm	1, (xsp+4)
TmFlash_CompareStrings_Join:
	ld	wa, (xsp+6)
	.byte 0x9f, 0x04, 0xf0
	jr	ule, TmFlash_CompareStrings_Loop
	ld	xhl, 0:i3
TmFlash_CompareStrings_Epilogue:
	pop	xiz
	inc	6, xsp
	ret

StrSearch_Init:
	ld xbc, (xsp + 4)
	ld hl, 0:i3
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
	ld iy, 0:i3
	ld ix, 0:i3
	lda xbc, (CType_ClassTable:24)
	jr ParseInt16_CheckWhitespace

ParseInt16_SkipWhitespace:
	inc 1, xhl

ParseInt16_CheckWhitespace:
	ld a, (xhl)
	extz wa
	bit	3, (xbc+wa)
	jr nz, ParseInt16_SkipWhitespace
	cp (xhl), 0x2d
	jr nz, ParseInt16_CheckMinus
	ld ix, 1:i3
	jr ParseInt16_SkipSign

ParseInt16_CheckMinus:
	cp (xhl), 0x2b
	jr nz, ParseInt16_DigitLoop

ParseInt16_SkipSign:
	inc 1, xhl

ParseInt16_DigitLoop:
	ld E, (xhl+)
	exts de
	ld a, e
	extz wa
	bit	2, (xbc+wa)
	jr z, ParseInt16_ApplySign
	sub de, 0x30
	muls iy, 0xa
	add iy, de
	jr ParseInt16_DigitLoop

ParseInt16_ApplySign:
	cp ix, 0:i3
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
	ld xiy, 0:i3
	ld ix, 0:i3
	lda xbc, (CType_ClassTable:24)
	jr ParseInt32_CheckWhitespace

ParseInt32_SkipWhitespace:
	inc 1, xhl

ParseInt32_CheckWhitespace:
	ld a, (xhl)
	extz wa
	bit	3, (xbc+wa)
	jr nz, ParseInt32_SkipWhitespace
	cp (xhl), 0x2d
	jr nz, ParseInt32_CheckMinus
	ld ix, 1:i3
	jr ParseInt32_SkipSign

ParseInt32_CheckMinus:
	cp (xhl), 0x2b
	jr nz, ParseInt32_DigitLoop

ParseInt32_SkipSign:
	inc 1, xhl

ParseInt32_DigitLoop:
	ld E, (xhl+)
	exts de
	ld a, e
	extz wa
	bit	2, (xbc+wa)
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
	cp ix, 0:i3
	jr z, ParseInt32_Positive
	ld xwa, xiy
	cpl wa
	cplw_erp 0xe2
	inc 1, xwa
	ld xhl, xwa
	jr ParseInt32_Return

ParseInt32_Positive:
	ld xhl, xiy

ParseInt32_Return:
	ret

Math_MultiplyAccumulate:
	ldto_werp HL, 0xe2
	mul xhl, bc
	ldto_werp DE, 0xe6
	mul xde, wa
	add xhl, xde
	ldfr_werp HL, 0xee
	ld hl, 0:i3
	mul xwa, bc
	add xhl, xwa
	ret

; =============================================================================
; Sprintf_Locked -- Send sound parameter command to Sub CPU
; =============================================================================
; Primary interface for all Main CPU -> Sub CPU audio parameter updates.
; Acquires audio lock #7, formats command via Sprintf_Core (printf-like
; format string parser), writes to ring buffer at 0xbd3c via AssswbWr.
; Referenced by 197+ locations (every Lsw* function, preset loaders, etc.).
; Args: xwa = format string pointer, stack = format arguments
Sprintf_Locked:
	dec 4, xsp
	pushw iz
	ld wa, 7:i3
	call Audio_Lock_Acquire
	ld xwa, (xsp + 10)
	ld (0x03c21c:24), xwa
	ld xwa, (xsp + 10)
	ld (xwa), 0x0
	lda xwa, (xsp + 14)
	inc 4, xwa
	ld (xsp + 2), xwa
	pushw 0xff		; Sprintf_OutputCallback >> 16
	.byte 0x0b		; pushw Sprintf_OutputCallback & 0xffff
	.short Sprintf_OutputCallback
	lda xwa, (xsp + 6)
	push xwa
	ld xwa, (xsp + 22)
	push xwa
	call Sprintf_Core
	lda xsp, (xsp + 12)
	ld iz, hl
	ld wa, 7:i3
	call Audio_Lock_Release
	ld hl, iz
	popw iz
	inc 4, xsp
	ret

Sprintf_Unlocked:
	ld	xwa, (xsp+4)
	ld	(0x3c21c:24), xwa
	ld	xwa, (xsp+4)
	ld	(xwa), 0
	pushw	0xff		; Sprintf_OutputCallback >> 16
	.byte	0x0b		; pushw Sprintf_OutputCallback & 0xffff
	.short	Sprintf_OutputCallback
	lda	xwa, (xsp+16)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	Sprintf_Core
	lda	xsp, (xsp+12)
	ret
Sprintf_OutputCallback:
	ld	xbc, (0x3c21c:24)
	ld	xwa, 1:i3
	add	(0x3c21c:24), xwa
	ld	wa, (xsp+4)
	ld	(xbc), a
	ld	xwa, (0x3c21c:24)
	ld	(xwa), 0
	ret

Free:
	ld xwa, (xsp + 4)
	or xwa, xwa
	ret z
	ld wa, 1:i3
	call TaskSched_WaitForEvent
	ld xbc, (xsp + 4)
	dec 6, xbc
	ld xwa, (0x03d52c:24)
	or xwa, xwa
	jr nz, Free_Block
	ld xwa, 0:i3
	ld (xbc), xwa
	ld (0x03d52c:24), xbc
	ld wa, 1:i3
	jp TaskSched_SignalEvent

Free_Block:
	ld xix, (0x03d52c:24)
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
	ld wa, 1:i3
	jp TaskSched_SignalEvent

Free_LoadReg:
	ld hl, (xbc + 4)
	extz xhl
	ld xwa, xbc
	inc 6, xwa
	add xwa, xhl
	cp xix, (0x3d52c:24)
	jr nz, Free_OrBits
	cp xwa, (0x3d52c:24)
	jr nz, Free_Block2
	ld xwa, (0x03d52c:24)
	ld xwa, (xwa)
	ld (xbc), xwa
	ld xwa, (0x03d52c:24)
	ld wa, (xwa + 4)
	inc 6, wa
	add (xbc + 4), wa
	jr Free_Block3

Free_Block2:
	ld xwa, (0x03d52c:24)
	ld (xbc), xwa

Free_Block3:
	ld (0x03d52c:24), xbc
	ld wa, 1:i3
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
	ld wa, 1:i3
	jp TaskSched_SignalEvent

Free_ClearByte:
	ld e, 0x0:opc
	bit_erpw 0xe2, 0x0f
	jr z, Free_Block4
	ld e, 0x1:opc
	cplw_erp 0xe2
	cpl wa
	inc 1, xwa

Free_Block4:
	bit_erpw 0xe6, 0x0f
	jr z, Free_Prologue
	or e, 0x2
	cplw_erp 0xe6
	cpl bc
	inc 1, xbc

Free_Prologue:
	pushw de
	calr Math_DivideU32
	popw wa
	cp w, 1:i3
	jr z, Free_Compare3
	ld xhl, xde
	bit 0, a
	scc8 nz, a
	jr Free_OrBits2

Free_Compare3:
	cp a, 3:i3
	ret z

Free_OrBits2:
	or xhl, xhl
	ret z
	cp a, 0:i3
	ret z
	cplw_erp 0xee
	cpl hl
	inc 1, xhl
	ret

Free_ClearByte2:
	ld d, 0x0:opc
	jr Free_ClearByte

Math_DivideSigned32:
	ld d, 0x1:opc
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
	cpiw_erp 0xe6, 0
	jr nz, Math_DivideU32_ClearByte
	ld xde, xwa
	div xwa, bc
	jr ov, Math_DivideU32_Block
			; Note: OV (Overflow) is the same as PE = Parity Even
	ld xhl, 0:i3
	ld xde, xhl
	ld hl, wa
	ldto_werp DE, 0xe2
	ret

Math_DivideU32_Block:
	ldto_werp WA, 0xea
	extz xwa
	div xwa, bc
	ldfr_werp WA, 0xee
	ld wa, de
	div xwa, bc
	ld hl, wa
	ldto_werp DE, 0xe2
	extz xde
	ret

Math_DivideU32_LoadReg:
	ld xhl, xwa
	ld xde, 0:i3
	ret

Math_DivideU32_Block2:
	ld xhl, 0:i3
	ld xde, xhl
	dec 1, xhl
	ret

Math_DivideU32_Block3:
	ld xhl, 1:i3
	ld xde, 0:i3
	ret z
	dec 1, xhl
	ld xde, xwa
	ret

Math_DivideU32_ClearByte:
	ld d, 0x0:opc

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
	ld xhl, 0:i3

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
	cp wa, 0:i3
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
	ld hl, 0:i3
	ret

String_Compare_NextIter:
	inc 1, xix
	inc 1, xde
	dec 1, bc

String_Compare_Compare:
	cp bc, 0:i3
	jr z, String_Compare_ClearByte
	ld a, (xde)
	cp a, (xix)
	jr z, String_Compare_CheckZero

String_Compare_ClearByte:
	ld l, 0x0:opc
	cp bc, 0:i3
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
	ld A, (xde+)
	ld (xix+), a
	dec 1, bc

Strncpy_Compare:
	cp bc, 0:i3
	jr z, Strncpy_Block2
	cp (xde), 0x0
	jr nz, Strncpy_Block

Strncpy_Block2:
	jr Strncpy_Compare2

Strncpy_Block3:
	ld (xix+), 0x00
	dec 1, bc

Strncpy_Compare2:
	cp bc, 0:i3
	jr nz, Strncpy_Block3
	ret

; Mem_Compare -- Compare two memory blocks byte-by-byte
; Returns: 0 if equal, nonzero if different
Mem_Compare:
	ld bc, (xsp + 12)
	ld hl, 0:i3
	cp bc, 0:i3
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
	ld L, (xix+)
	extz hl
	ld A, (xiy+)
	extz wa
	sub hl, wa
	ret nz
	sub bc, 0x1
	ret z
	djnz16 de, Mem_Compare_Block

Mem_Compare_LoadReg:
	ld de, bc
	srl bc, 2
	jr z, Mem_Compare_MaskBits

Mem_Compare_Block2:
	ld XHL, (xix+)
	ld XWA, (xiy+)
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
	djnz16 bc, Mem_Compare_Block2
	ld hl, 0:i3

Mem_Compare_MaskBits:
	and de, 0x3
	ret z

Mem_Compare_Block4:
	ld L, (xix+)
	extz hl
	ld A, (xiy+)
	extz wa
	sub hl, wa
	ret nz
	djnz16 de, Mem_Compare_Block4
	ret

Mem_Copy:
	ld bc, (xsp + 12)
	ld xhl, (xsp + 4)
	cp bc, 0:i3
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
	ld A, (xbc+)
	ld (xde+), a

Strcat_CheckZero2:
	cp (xbc), 0x0
	jr nz, Strcat_Block
	ld (xde), 0x0
	ret

Itoa_Safe:
	lda xsp, (xsp - 18)
	push xiz
	ld xhl, (xsp + 28)
	ld ix, 0:i3
	ld bc, (xsp + 32)
	cp bc, 2:i3
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
	cp wa, 0:i3
	jr ge, NumFormat_DivideAndConvert
	ld ix, 1:i3
	ldto_werp WA, 0xe6
	neg wa
	ldfr_werp WA, 0xe6

NumFormat_DivideAndConvert:
	ld de, bc
	ldto_werp WA, 0xe6
	extz xwa
	div xwa, de
	ldto_werp WA, 0xe2
	add a, 0x30
	ld (xiy), a
	cp (xiy), 0x39
	jr le, NumFormat_DivideAndC_Block
	addmi8 (xiy), 0x27

NumFormat_DivideAndC_Block:
	ldto_werp WA, 0xe6
	extz xwa
	div xwa, de
	ldfr_werp WA, 0xe6
	cpiw_erp 0xe6, 0
	jr z, NumFormat_DivideAndC_Compare
	dec 1, xiy
	jr NumFormat_DivideAndConvert

NumFormat_DivideAndC_Compare:
	cp ix, 0:i3
	jr z, NumFormat_DivideAndC_LoadAddr
	ld (-xiy), 0x2d

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
NumFormat_DivideAndC_Data_Entry:
	.byte 0x83, 0xf1
	ret	z
	cp	(xhl+), 0
	jr	nz, NumFormat_DivideAndC_Data_Entry
	ld	xhl, 0:i3
	ret

Malloc:
	dec 6, xsp
	push xiz
	ld wa, (xsp + 14)
	inc 1, wa
	srl wa, 1
	ld (xsp + 8), wa
	add (xsp + 8), wa
	ld wa, 1:i3
	call TaskSched_WaitForEvent
	ld xiz, (0x03d52c:24)
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
	cp xiz, (0x3d52c:24)
	jr nz, Malloc_LoadParam
	ld xwa, (xiz)
	ld (0x03d52c:24), xwa
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
	ld wa, 1:i3
	call TaskSched_SignalEvent
	ld xhl, 0:i3
	jr Malloc_Epilogue

Malloc_Block2:
	ld xwa, 0:i3
	ld (xiz), xwa
	ld wa, (xsp + 8)
	ld (xiz + 4), wa

Malloc_DoSignalEv:
	ld wa, 1:i3
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
	call Sprintf_StringNSearch
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
	ld xhl, (0x03d528:24)
	ret

Heap_Alloc_Block:
	cp (0x3d528:24), xwa
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
	ld xhl, (0x03d524:24)
	add (0x03d524:24), xwa
	sub (0x3d528:24), xwa
	ret

; ============================================================================
; Strlen - Compute string length (C runtime)
; ============================================================================
; Input:  XWA = pointer to null-terminated string (pushed on stack)
; Output: HL = length of string (excluding null terminator)
;         Returns 0xffff if null terminator not found
; Uses Sprintf_MemChr to search for 0x00 byte, then computes result - start.
; Located between Strcpy and Memset (standard C library functions).
; ============================================================================
Strlen:
	push xiz
	pushw 0xffff
	pushw 0x0
	ld xiz, (xsp + 12)
	push xiz
	call Sprintf_MemChr
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
	cplw_erp 0xea
	inc 1, xde
	push xde
	call Sprintf_ItoaBaseN
	lda xsp, (xsp + 10)
	dec 1, xhl
	ret

; ============================================================================
; Itoa_WithBase - Convert integer to string with specified base (C runtime)
; ============================================================================
; Input:  WA = integer value, XBC = base pointer, XDE = format options
; Output: String written to output buffer
; Wrapper around Sprintf_ItoaBaseN. Pushes parameters and delegates to
; the audio command subsystem's integer-to-string conversion.
; ============================================================================
Itoa_WithBase:
	pushw wa
	push xbc
	push xde
	call Sprintf_ItoaBaseN
	lda xsp, (xsp + 10)
	ret

Memset:
	ld bc, (xsp + 10)
	ld xhl, (xsp + 4)
	cp bc, 0:i3
	ret z
	ld xix, xhl
	ld wa, (xsp + 8)
	ld de, ix
	neg de
	and de, 0x3
	jr z, Memset_LoadReg

Memset_Block:
	ld (xix+), a
	sub bc, 0x1
	ret z
	djnz16 de, Memset_Block

Memset_LoadReg:
	ld de, bc
	srl bc, 2
	jr z, Memset_MaskBits
	ld w, a
	ldfr_werp WA, 0xe2

Memset_Block2:
	ld (xix+), XWA
	djnz16 bc, Memset_Block2

Memset_MaskBits:
	and de, 0x3
	ret z

Memset_Block3:
	ld (xix+), a
	djnz16 de, Memset_Block3
	ret

Math_AbsInt16:
	ld hl, (xsp + 4)
	cp hl, 0:i3
	ret ge
	neg hl
	ret

	.include "audio/sprintf_core.s"
