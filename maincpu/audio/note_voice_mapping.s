; =============================================================================
; Note & Voice Mapping (26K lines)
; =============================================================================
;
; Note-on processing, polyphonic voice allocation and stealing,
; NoteMap dispatch (91 functions), sequence playback support, MIDI
; output formatting, sound parameter management, and utility routines.
; One of the largest files in the ROM.
; =============================================================================

LABEL_FE0245:
	st_dri3b L, 0xFD, 0x08, 0xFE
	pushw iz
	ldada xwa, 49662
	ld (xsp + 2), xwa
	call SeqMain_SaveWritePos
	stib_dri 0xFD, 0xF4, 0x01, 0x00
	st_dri3b W, 0xFD, 0xF4, 0x01
	ld xde, xwa
	st_dri3b W, 0xFD, 0x50, 0x01
	ld xbc, xwa
	ld xwa, xde
	call MidiEvent_ProcessNoteEntry
	cps l, 0
	jrl z, LABEL_FE06E0

LABEL_FE0275:
	ld_srib A, (xsp + 0x0150)
	cp a, 0xB0
	jrl z, LABEL_FE04E0
	cp a, 0x90
	jrl nz, NoteOnProcess_StoreAndAllocate
	ldw (xsp + 6), 0x0
	cpw (xsp + 6), 0x1A
	jrl nc, NoteOnProcess_StoreAndAllocate

LABEL_FE0293:
	ld wa, (xsp + 6)
	add wa, 0x24
	ld bc, wa
	extz xbc
	add xbc, (xsp + 2)
	ld_srib A, (xsp + 0x0153)
	cp a, (xbc)
	jrl nz, LABEL_FE04D2
	ld wa, (xsp + 6)
	add wa, wa
	add wa, 0x124
	extz xwa
	add xwa, (xsp + 2)
	bitm 6, (xwa)
	jrl z, LABEL_FE04D2
	st_dri3b W, 0xFD, 0x50, 0x01
	ld xbc, xwa
	ld wa, (xsp + 6)
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call Voice_ApplyTransposeWithEncode
	lds iz, 0
	ldb c, 0x7F
	jr LABEL_FE0319

LABEL_FE02DB:
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	st_dri3b W, 0xFD, 0x51, 0x01
	add xwa, xbc
	cp (xwa), 0x0
	jr z, LABEL_FE0317
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	st_dri3b W, 0xFD, 0x50, 0x01
	add xwa, xbc
	ld c, (xwa)
	ld_srib A, (xsp + 0x0153)
	extz wa
	extz bc
	call AccWrap_AutoPlayCheck

LABEL_FE0317:
	inc 1, iz

LABEL_FE0319:
	ld_srib A, (xsp + 0x0151)
	extz wa
	cp iz, wa
	jr c, LABEL_FE02DB
	call CompIface_ResetPedal
	ld wa, (xsp + 6)
	add wa, wa
	add wa, 0x124
	extz xwa
	add xwa, (xsp + 2)
	bitm 4, (xwa)
	jr nz, LABEL_FE0354
	st_dri3b W, 0xFD, 0x50, 0x01
	ld xbc, xwa
	ld wa, (xsp + 6)
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call LABEL_FE301A
	jrl LABEL_FE04CE

LABEL_FE0354:
	st_dri3b E, 0xFD, 0x50, 0x01
	st_dri3b D, 0xFD, 0xAC, 0x00
	ldw bc, 0x52
	ldirw
	stib_dri 0xFD, 0xAE, 0x00, 0x00
	stib_dri 0xFD, 0xAF, 0x00, 0x01
	st_dri3b W, 0xFD, 0xAC, 0x00
	call NoteMap_AssignAllVoiceLinks
	ld xwa, (xsp + 2)
	cp (xwa + 1), 0xFF
	jrl nz, LABEL_FE0453
	ld xwa, (xsp + 2)
	bitm 0, (xwa)
	jr z, LABEL_FE03B5
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xAC, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	st_dri3b W, 0xE1, 0xC4, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE03B5
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	lds de, 0
	call NoteMap_UpdateEntry

LABEL_FE03B5:
	ld xwa, (xsp + 2)
	bitm 1, (xwa)
	jr z, LABEL_FE03E8
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xAC, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	st_dri3b W, 0xE1, 0xC8, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE03E8
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	lds de, 1
	call NoteMap_UpdateEntry

LABEL_FE03E8:
	ld xwa, (xsp + 2)
	bitm 2, (xwa)
	jr z, LABEL_FE041B
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xAC, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	st_dri3b W, 0xE1, 0xCC, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE041B
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	lds de, 2
	call NoteMap_UpdateEntry

LABEL_FE041B:
	ld xwa, (xsp + 2)
	bitm 3, (xwa)
	jrl z, LABEL_FE04CE
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xAC, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	st_dri3b W, 0xE1, 0xD0, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jrl z, LABEL_FE04CE
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	ldw de, 0x15
	call NoteMap_UpdateEntry
	jr LABEL_FE04CE

LABEL_FE0453:
	ld xwa, (xsp + 2)
	cp (xwa + 1), 0x15
	jr nz, LABEL_FE0480
	ldda16 xwa, 50584
	and wa, 0xA
	jr z, LABEL_FE046F
	st_dri3b W, 0xFD, 0xAC, 0x00
	call NoteMap_MarkEntriesAboveThreshold

LABEL_FE046F:
	st_dri3b W, 0xFD, 0xAC, 0x00
	ld xbc, (xsp + 2)
	ldw de, 0x15
	call NoteMap_UpdateEntry
	jr LABEL_FE04CE

LABEL_FE0480:
	ld xwa, (xsp + 2)
	bitm 3, (xwa)
	jr z, LABEL_FE04B4
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xAC, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	st_dri3b W, 0xE1, 0xD0, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE04B4
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	ldw de, 0x15
	call NoteMap_UpdateEntry

LABEL_FE04B4:
	st_dri3b W, 0xFD, 0xAC, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	ld a, (xwa + 1)
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_UpdateEntry

LABEL_FE04CE:
	call AccWrap_AutoPlayStateMachine

LABEL_FE04D2:
	incm 1, (xsp + 6)
	cpw (xsp + 6), 0x1A
	jrl c, LABEL_FE0293
	jrl NoteOnProcess_StoreAndAllocate

LABEL_FE04E0:
	ldw (xsp + 6), 0x0
	cpw (xsp + 6), 0x1A
	jrl nc, NoteOnProcess_StoreAndAllocate

LABEL_FE04ED:
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
	jr nz, LABEL_FE0544
	st_dri3b W, 0xFD, 0x50, 0x01
	ld xbc, xwa
	ld wa, (xsp + 6)
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_CollectAndAllocVoice_Indirect
	jrl NoteOnProcess_NextChannel

LABEL_FE0544:
	stib_dri 0xFD, 0xAE, 0x00, 0x00
	stib_dri 0xFD, 0xAF, 0x00, 0x01
	st_dri3b W, 0xFD, 0xAC, 0x00
	call Voice_LookupTableEntries
	cps l, 0
	jrl z, NoteOnProcess_NextChannel
	st_dri3b W, 0xFD, 0xAC, 0x00
	call NoteMap_AssignAllVoiceLinks
	ld xwa, (xsp + 2)
	cp (xwa + 1), 0xFF
	jrl nz, LABEL_FE0642
	ld xwa, (xsp + 2)
	bitm 0, (xwa)
	jr z, LABEL_FE05A4
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xAC, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	st_dri3b W, 0xE1, 0xC4, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE05A4
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	lds de, 0
	call NoteMap_UpdateEntry

LABEL_FE05A4:
	ld xwa, (xsp + 2)
	bitm 1, (xwa)
	jr z, LABEL_FE05D7
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xAC, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	st_dri3b W, 0xE1, 0xC8, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE05D7
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	lds de, 1
	call NoteMap_UpdateEntry

LABEL_FE05D7:
	ld xwa, (xsp + 2)
	bitm 2, (xwa)
	jr z, LABEL_FE060A
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xAC, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	st_dri3b W, 0xE1, 0xCC, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE060A
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	lds de, 2
	call NoteMap_UpdateEntry

LABEL_FE060A:
	ld xwa, (xsp + 2)
	bitm 3, (xwa)
	jrl z, NoteOnProcess_NextChannel
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xAC, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	st_dri3b W, 0xE1, 0xD0, 0x00
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

LABEL_FE0642:
	ld xwa, (xsp + 2)
	cp (xwa + 1), 0x15
	jr nz, LABEL_FE066E
	ldda16 xwa, 50584
	bit 1, wa
	jr z, LABEL_FE065D
	st_dri3b W, 0xFD, 0xAC, 0x00
	call NoteMap_MarkEntriesAboveThreshold

LABEL_FE065D:
	st_dri3b W, 0xFD, 0xAC, 0x00
	ld xbc, (xsp + 2)
	ldw de, 0x15
	call NoteMap_UpdateEntry
	jr NoteOnProcess_NextChannel

LABEL_FE066E:
	ld xwa, (xsp + 2)
	bitm 3, (xwa)
	jr z, LABEL_FE06A2
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xAC, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	st_dri3b W, 0xE1, 0xD0, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE06A2
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 2)
	ldw de, 0x15
	call NoteMap_UpdateEntry

LABEL_FE06A2:
	st_dri3b W, 0xFD, 0xAC, 0x00
	ld xbc, xwa
	ld xwa, (xsp + 2)
	ld a, (xwa + 1)
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_UpdateEntry

NoteOnProcess_NextChannel:
	incm 1, (xsp + 6)
	cpw (xsp + 6), 0x1A
	jrl c, LABEL_FE04ED

NoteOnProcess_StoreAndAllocate:
	st_dri3b W, 0xFD, 0xF4, 0x01
	ld xde, xwa
	st_dri3b W, 0xFD, 0x50, 0x01
	ld xbc, xwa
	ld xwa, xde
	call MidiEvent_ProcessNoteEntry
	cps l, 0
	jrl nz, LABEL_FE0275

LABEL_FE06E0:
	popw iz
	st_dri3b L, 0xFD, 0xF8, 0x01
	ret

AccNoteOn_ProcessVoiceSetup:
	lda xsp, (xsp - 18)
	pushw iz
	ldada xwa, 49662
	ld (xsp + 2), xwa
	lds iz, 0
	ld xiy, 0xEE8EE8
	lda xix, (xsp + 10)
	ldiw
	ldiw
	ld xiy, 0xEE8EEC
	lda xix, (xsp + 6)
	ldiw
	ldiw
	ld (xsp + 14), 0x0
	lda xwa, (xsp + 14)
	ld xbc, 0xCC1E
	call MidiEvent_ParseNoteSequence
	cps l, 0
	jrl z, LABEL_FE09BB

LABEL_FE0721:
	ld xwa, 0xCC1E
	call NoteMap_AssignAllVoiceLinks
	lds iz, 0
	ldb e, 0x7F
	jr LABEL_FE0764

LABEL_FE0730:
	ld wa, iz
	mul wa, 0x5
	inc 4, wa
	ldada xbc, 52255
	extz xwa
	add xwa, xbc
	cp (xwa), 0x0
	jr z, LABEL_FE0762
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

LABEL_FE0762:
	inc 1, iz

LABEL_FE0764:
	ldda8 a, 52255
	extz wa
	cp iz, wa
	jr c, LABEL_FE0730
	call CompIface_ResetPedal
	cpdi8 36152, 236
	jr nz, LABEL_FE07D0
	lds iz, 0
	ldb e, 0x7F
	jr LABEL_FE07BE

LABEL_FE077F:
	ld wa, iz
	mul wa, 0x5
	inc 4, wa
	ldada xbc, 52255
	extz xwa
	add xwa, xbc
	cp (xwa), 0x0
	jr z, LABEL_FE07BC
	ld wa, iz
	mul wa, 0x5
	ldada xbc, 52258
	extz xwa
	add xwa, xbc
	cp e, (xwa)
	jr nc, LABEL_FE07AA
	ld a, e
	jr LABEL_FE07BA

LABEL_FE07AA:
	ld wa, iz
	mul wa, 0x5
	ldada xbc, 52258
	extz xwa
	add xwa, xbc
	ld a, (xwa)

LABEL_FE07BA:
	ld e, a

LABEL_FE07BC:
	inc 1, iz

LABEL_FE07BE:
	ldda8 a, 52255
	extz wa
	cp iz, wa
	jr c, LABEL_FE077F
	ld a, e
	extz wa
	call LABEL_F74A2C

LABEL_FE07D0:
	lds iz, 0
	ldb e, 0x7F
	jr LABEL_FE0808

LABEL_FE07D6:
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
	call LABEL_FB7BDF
	inc 1, iz

LABEL_FE0808:
	ldda8 a, 52255
	extz wa
	cp iz, wa
	jr c, LABEL_FE07D6
	ld xwa, (xsp + 2)
	cp (xwa + 1), 0xFF
	jrl nz, LABEL_FE08EE
	ld xwa, (xsp + 2)
	bitm 0, (xwa)
	jr z, LABEL_FE084F
	ld xhl, 0xCB7A
	ld xbc, 0xCC1E
	ld xwa, (xsp + 2)
	st_dri3b W, 0xE1, 0xC4, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE084F
	ld xwa, 0xCB7A
	ld xbc, (xsp + 2)
	lds de, 0
	call NoteMap_AddEntry

LABEL_FE084F:
	ld xwa, (xsp + 2)
	bitm 1, (xwa)
	jr z, LABEL_FE0882
	ld xhl, 0xCB7A
	ld xbc, 0xCC1E
	ld xwa, (xsp + 2)
	st_dri3b W, 0xE1, 0xC8, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE0882
	ld xwa, 0xCB7A
	ld xbc, (xsp + 2)
	lds de, 1
	call NoteMap_AddEntry

LABEL_FE0882:
	ld xwa, (xsp + 2)
	bitm 2, (xwa)
	jr z, LABEL_FE08B5
	ld xhl, 0xCB7A
	ld xbc, 0xCC1E
	ld xwa, (xsp + 2)
	st_dri3b W, 0xE1, 0xCC, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE08B5
	ld xwa, 0xCB7A
	ld xbc, (xsp + 2)
	lds de, 2
	call NoteMap_AddEntry

LABEL_FE08B5:
	ld xwa, (xsp + 2)
	bitm 3, (xwa)
	jrl z, AccNoteOn_FinalizeAndAutoPlay
	ld xhl, 0xCB7A
	ld xbc, 0xCC1E
	ld xwa, (xsp + 2)
	st_dri3b W, 0xE1, 0xD0, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jrl z, AccNoteOn_FinalizeAndAutoPlay
	ld xwa, 0xCB7A
	ld xbc, (xsp + 2)
	ldw de, 0x15
	call NoteMap_AddEntry
	jrl AccNoteOn_FinalizeAndAutoPlay

LABEL_FE08EE:
	ld xwa, (xsp + 2)
	cp (xwa + 1), 0x15
	jr nz, LABEL_FE095E
	ldda16 xwa, 50584
	and wa, 0xA
	jr z, LABEL_FE094D
	ld xhl, 0xCB7A
	ld xbc, 0xCC1E
	lda xwa, (xsp + 10)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE0923
	ld xwa, 0xCB7A
	call NoteMap_MarkEntriesAboveThreshold

LABEL_FE0923:
	ld xhl, 0xCB7A
	ld xbc, 0xCC1E
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, AccNoteOn_FinalizeAndAutoPlay
	ld xwa, 0xCB7A
	ld xbc, (xsp + 2)
	ldw de, 0x15
	call NoteMap_AddEntry
	jr AccNoteOn_FinalizeAndAutoPlay

LABEL_FE094D:
	ld xwa, 0xCC1E
	ld xbc, (xsp + 2)
	ldw de, 0x15
	call NoteMap_AddEntry
	jr AccNoteOn_FinalizeAndAutoPlay

LABEL_FE095E:
	ld xwa, (xsp + 2)
	bitm 3, (xwa)
	jr z, LABEL_FE0992
	ld xhl, 0xCB7A
	ld xbc, 0xCC1E
	ld xwa, (xsp + 2)
	st_dri3b W, 0xE1, 0xD0, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE0992
	ld xwa, 0xCB7A
	ld xbc, (xsp + 2)
	ldw de, 0x15
	call NoteMap_AddEntry

LABEL_FE0992:
	ld xbc, 0xCC1E
	ld xwa, (xsp + 2)
	ld a, (xwa + 1)
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_AddEntry

AccNoteOn_FinalizeAndAutoPlay:
	lda xwa, (xsp + 14)
	ld xbc, 0xCC1E
	call MidiEvent_ParseNoteSequence
	cps l, 0
	jrl nz, LABEL_FE0721

LABEL_FE09BB:
	call AccWrap_AutoPlayStateMachine
	popw iz
	lda xsp, (xsp + 18)
	ret

LABEL_FE09C4:
	st_dri3b L, 0xFD, 0x52, 0xFF
	push_werp 0xFA
	ldada xwa, 49662
	ld (xsp + 2), xwa
	call SeqBuf_SaveReadPos
	ld (xsp + 6), 0x0
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, xde
	call LABEL_FE21DB
	cps l, 0
	jrl z, LABEL_FE0AFD

LABEL_FE09F0:
	ld a, (xsp + 12)
	cp a, 0xB0
	jr z, LABEL_FE0A33
	cp a, 0x90
	jrl nz, AccMidi_ReadNextEvent
	call CompIface_ResetPedal
	ld a, (xsp + 15)
	extz wa
	add wa, 0x84
	extz xwa
	add xwa, (xsp + 2)
	ld a, (xwa)
	ldfr_berp A, 0xFA
	cp a, 0xFF
	jrl z, AccMidi_ReadNextEvent
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ldto_berp A, 0xFA
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call LABEL_FE376C
	jrl AccMidi_ReadNextEvent

LABEL_FE0A33:
	cp (xsp + 15), 0x7F
	jr nz, LABEL_FE0A9E
	ldi_berp 0xFB, 0
	cp_erpb 0xFB, 0x10
	jrl nc, AccMidi_ReadNextEvent

LABEL_FE0A43:
	ldto_berp A, 0xFB
	ld (xsp + 15), a
	ldto_berp A, 0xFB
	extz wa
	add wa, 0x84
	extz xwa
	add xwa, (xsp + 2)
	ld a, (xwa)
	ldfr_berp A, 0xFA
	cp a, 0xFF
	jr z, LABEL_FE0A93
	ld (xsp + 14), 0x3
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ldto_berp A, 0xFA
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_ProcessNoteEvent
	ld (xsp + 14), 0x2
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ldto_berp A, 0xFA
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_ProcessNoteEvent

LABEL_FE0A93:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr c, LABEL_FE0A43
	jr AccMidi_ReadNextEvent

LABEL_FE0A9E:
	ld a, (xsp + 15)
	extz wa
	add wa, 0x84
	extz xwa
	add xwa, (xsp + 2)
	ld a, (xwa)
	ldfr_berp A, 0xFA
	cp a, 0xFF
	jr z, AccMidi_ReadNextEvent
	ld (xsp + 14), 0x3
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ldto_berp A, 0xFA
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_ProcessNoteEvent
	ld (xsp + 14), 0x2
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ldto_berp A, 0xFA
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_ProcessNoteEvent

AccMidi_ReadNextEvent:
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, xde
	call LABEL_FE21DB
	cps l, 0
	jrl nz, LABEL_FE09F0

LABEL_FE0AFD:
	pop_werp 0xFA
	st_dri3b L, 0xFD, 0xAE, 0x00
	ret

RhythmMidi_Dispatcher:
	st_dri3b L, 0xFD, 0x4C, 0xFF
	push_werp 0xFA
	ldada xwa, 49662
	ld (xsp + 2), xwa
	ld xiy, 0xEE8EF8
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
	call LABEL_FE24B1
	cps l, 0
	jrl z, RhythmMidi_CC_PostProcess

LABEL_FE0B40:
	ld a, (xsp + 18)
	cp a, 0xB0
	jr z, RhythmMidi_HandleCC
	cp a, 0x90
	jrl nz, RhythmMidi_CC_UpdateOutput
	ld a, (xsp + 21)
	extz wa
	lda_24 xbc, 0xee8ef0
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ldfr_berp A, 0xFA
	sub a, 0x10
	extz wa
	lda xbc, (xsp + 6)
	cp_srib_im 0x07, 0xE4, 0xE0, 0x00
	jr nz, LABEL_FE0B88
	lda xwa, (xsp + 18)
	ld xbc, xwa
	ldto_berp A, 0xFA
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call LABEL_FE3A52
	jrl RhythmMidi_CC_UpdateOutput

LABEL_FE0B88:
	ld (xsp + 18), 0x98
	lda xwa, (xsp + 18)
	ld xbc, xwa
	ldto_berp A, 0xFA
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call LABEL_FE3BB4
	ldto_berp A, 0xFA
	sub a, 0x10
	extz wa
	lda xbc, (xsp + 6)
	stib_dri 0x07, 0xE4, 0xE0, 0x00
	jrl RhythmMidi_CC_UpdateOutput

RhythmMidi_HandleCC:
	ld a, (xsp + 21)
	inc 4, a
	cp a, 0x7D
	jr z, RhythmMidi_CC7D
	cp a, 0x7E
	jr z, RhythmMidi_CC7E
	cp a, 0x7F
	jrl nz, RhythmMidi_CC_Default
	ldi_berp 0xFB, 0
	cpi_berp 0xFB, 5
	jrl nc, RhythmMidi_CC_UpdateOutput

RhythmMidi_CC7F_PartLoop:
	ldto_berp A, 0xFB
	ld (xsp + 21), a
	ldto_berp A, 0xFB
	extz wa
	lda_24 xbc, 0xee8ef0
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ldfr_berp A, 0xFA
	lda xwa, (xsp + 18)
	ld xbc, xwa
	ldto_berp A, 0xFA
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_LookupAndAllocVoice
	inc1_berp 0xFB
	cpi_berp 0xFB, 5
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
	ldi_berp 0xFB, 0
	cpi_berp 0xFB, 5
	jrl nc, RhythmMidi_CC_UpdateOutput

RhythmMidi_CC7D_PartLoop:
	ldto_berp A, 0xFB
	extz wa
	lda xbc, (xsp + 6)
	cp_srib_im 0x07, 0xE4, 0xE0, 0x00
	jr z, RhythmMidi_CC7D_PartNext
	ldto_berp A, 0xFB
	ld (xsp + 21), a
	ldto_berp A, 0xFB
	extz wa
	lda_24 xbc, 0xee8ef0
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ldfr_berp A, 0xFA
	lda xwa, (xsp + 18)
	ld xbc, xwa
	ldto_berp A, 0xFA
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_LookupAndAllocVoice
	ldto_berp A, 0xFB
	extz wa
	lda xbc, (xsp + 6)
	stib_dri 0x07, 0xE4, 0xE0, 0x00

RhythmMidi_CC7D_PartNext:
	inc1_berp 0xFB
	cpi_berp 0xFB, 5
	jr c, RhythmMidi_CC7D_PartLoop
	jr RhythmMidi_CC_UpdateOutput

RhythmMidi_CC_Default:
	cp (xsp + 21), 0x70
	jr c, RhythmMidi_CC_Standard
	ld (xsp + 18), 0xA0
	submi8 (xsp + 21), 0x70
	ld a, (xsp + 21)
	extz wa
	lda_24 xbc, 0xee8ef0
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ldfr_berp A, 0xFA
	lda xwa, (xsp + 18)
	ld xbc, xwa
	ldto_berp A, 0xFA
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_LookupAndAllocVoice
	ldto_berp A, 0xFA
	sub a, 0x10
	extz wa
	lda xbc, (xsp + 6)
	stib_dri 0x07, 0xE4, 0xE0, 0x00
	jr RhythmMidi_CC_UpdateOutput

RhythmMidi_CC_Standard:
	ld a, (xsp + 21)
	extz wa
	lda_24 xbc, 0xee8ef0
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ldfr_berp A, 0xFA
	sub a, 0x10
	extz wa
	lda xbc, (xsp + 6)
	stib_dri 0x07, 0xE4, 0xE0, 0x01

RhythmMidi_CC_UpdateOutput:
	lda xwa, (xsp + 12)
	ld xde, xwa
	lda xwa, (xsp + 18)
	ld xbc, xwa
	ld xwa, xde
	call LABEL_FE24B1
	cps l, 0
	jrl nz, LABEL_FE0B40

RhythmMidi_CC_PostProcess:
	ldi_berp 0xFB, 0
	cpi_berp 0xFB, 5
	jr nc, RhythmMidi_CC_Return

RhythmMidi_CC_PostLoop:
	ldto_berp A, 0xFB
	extz wa
	lda xbc, (xsp + 6)
	cp_srib_im 0x07, 0xE4, 0xE0, 0x00
	jr z, RhythmMidi_CC_PostNext
	ldto_berp A, 0xFB
	ld (xsp + 21), a
	ldto_berp A, 0xFB
	extz wa
	lda_24 xbc, 0xee8ef0
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ldfr_berp A, 0xFA
	lda xwa, (xsp + 18)
	ld xbc, xwa
	ldto_berp A, 0xFA
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, (xsp + 2)
	call NoteMap_LookupAndAllocVoice

RhythmMidi_CC_PostNext:
	inc1_berp 0xFB
	cpi_berp 0xFB, 5
	jr c, RhythmMidi_CC_PostLoop

RhythmMidi_CC_Return:
	pop_werp 0xFA
	st_dri3b L, 0xFD, 0xB4, 0x00
	ret

RhythmMidi_SeqEvt:
	st_dri3b L, 0xFD, 0x52, 0xFF
	push_werp 0xFA
	ldada xwa, 49662
	ld (xsp + 2), xwa
	call SeqEvtBuf_SaveReadPos
	ld (xsp + 6), 0x0
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, xde
	call LABEL_FE273A
	cps l, 0
	jrl z, RhythmMidi_SeqEvt_Return

RhythmMidi_SeqEvt_Dispatch:
	ld a, (xsp + 12)
	cp a, 0xB0
	jr z, RhythmMidi_SeqEvt_CC
	cp a, 0x90
	jrl nz, RhythmMidi_SeqEvt_ReadNext
	ld a, (xsp + 15)
	extz wa
	lda_24 xbc, 0xee8efe
	ld_srib3 E, 0x07, 0xE4, 0xE0
	ld a, e
	cp a, 0xFF
	jrl z, RhythmMidi_SeqEvt_ReadNext
	lda xwa, (xsp + 12)
	extz de
	ld xbc, (xsp + 2)
	call LABEL_FE3C7B
	jrl RhythmMidi_SeqEvt_ReadNext

RhythmMidi_SeqEvt_CC:
	ld a, (xsp + 15)
	cp a, 0x7E
	jr z, RhythmMidi_SeqEvt_CC7E
	cp a, 0x7F
	jr nz, RhythmMidi_SeqEvt_CC_Default
	ldi_berp 0xFB, 0
	cpi_berp 0xFB, 2
	jrl nc, RhythmMidi_SeqEvt_ReadNext

RhythmMidi_SeqEvt_CC7F_Loop:
	ldto_berp A, 0xFB
	ld (xsp + 15), a
	ldto_berp A, 0xFB
	extz wa
	lda_24 xbc, 0xee8efe
	ld_srib3 E, 0x07, 0xE4, 0xE0
	ld a, e
	cp a, 0xFF
	jr z, RhythmMidi_SeqEvt_CC7F_Next
	lda xwa, (xsp + 12)
	extz de
	ld xbc, (xsp + 2)
	call NoteMap_LookupAllocAndStoreResult

RhythmMidi_SeqEvt_CC7F_Next:
	inc1_berp 0xFB
	cpi_berp 0xFB, 2
	jr c, RhythmMidi_SeqEvt_CC7F_Loop
	jr RhythmMidi_SeqEvt_ReadNext

RhythmMidi_SeqEvt_CC7E:
	ldi_berp 0xFB, 0
	cpi_berp 0xFB, 1
	jr nc, RhythmMidi_SeqEvt_ReadNext

RhythmMidi_SeqEvt_CC7E_Loop:
	ldto_berp A, 0xFB
	ld (xsp + 15), a
	ldto_berp A, 0xFB
	extz wa
	lda_24 xbc, 0xee8efe
	ld_srib3 E, 0x07, 0xE4, 0xE0
	ld a, e
	cp a, 0xFF
	jr z, RhythmMidi_SeqEvt_CC7E_Next
	lda xwa, (xsp + 12)
	extz de
	ld xbc, (xsp + 2)
	call NoteMap_LookupAllocAndStoreResult

RhythmMidi_SeqEvt_CC7E_Next:
	inc1_berp 0xFB
	cpi_berp 0xFB, 1
	jr c, RhythmMidi_SeqEvt_CC7E_Loop
	jr RhythmMidi_SeqEvt_ReadNext

RhythmMidi_SeqEvt_CC_Default:
	ld a, (xsp + 15)
	extz wa
	lda_24 xbc, 0xee8efe
	ld_srib3 E, 0x07, 0xE4, 0xE0
	ld a, e
	cp a, 0xFF
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
	call LABEL_FE273A
	cps l, 0
	jrl nz, RhythmMidi_SeqEvt_Dispatch

RhythmMidi_SeqEvt_Return:
	pop_werp 0xFA
	st_dri3b L, 0xFD, 0xAE, 0x00
	ret

Voice_InitializeAll:
	st_dri3b L, 0xFD, 0x10, 0xFE
	push xiz
	ldada xiz, 49662
	stib_dri 0xFD, 0x50, 0x01, 0x90
	stib_dri 0xFD, 0x52, 0x01, 0x01
	ld (xsp + 4), 0x0
	cp (xsp + 4), 0x10
	jrl nc, LABEL_FE1063

LABEL_FE0E96:
	ld a, (xsp + 4)
	lda_dri3 XBC, 0xFD, 0x53, 0x01
	ld (xsp + 6), 0x0
	cp (xsp + 6), 0x1A
	jrl nc, LABEL_FE1059

LABEL_FE0EA9:
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
	bit_dri 6, 0x07, 0xF8, 0xE0
	jrl z, VoiceProcess_NextChannel
	ld a, (xsp + 6)
	extz wa
	add wa, wa
	add wa, 0x124
	bit_dri 4, 0x07, 0xF8, 0xE0
	jr nz, LABEL_FE0F00
	st_dri3b W, 0xFD, 0x50, 0x01
	ld xbc, xwa
	ld a, (xsp + 6)
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, xiz
	call NoteMap_CollectAndAllocVoice_Indirect
	jrl VoiceProcess_NextChannel

LABEL_FE0F00:
	stib_dri 0xFD, 0xAC, 0x00, 0x90
	stib_dri 0xFD, 0xAE, 0x00, 0x00
	stib_dri 0xFD, 0xAF, 0x00, 0x01
	st_dri3b W, 0xFD, 0xAC, 0x00
	call Voice_LookupTableEntries
	cps l, 0
	jrl z, VoiceProcess_NextChannel
	st_dri3b W, 0xFD, 0xAC, 0x00
	call NoteMap_AssignAllVoiceLinks
	cp (xiz + 1), 0xFF
	jrl nz, LABEL_FE0FE4
	bitm 0, (xiz)
	jr z, LABEL_FE0F5C
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xAC, 0x00
	ld xbc, xwa
	st_dri3b W, 0xF9, 0xC4, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE0F5C
	lda xwa, (xsp + 8)
	ld xbc, xiz
	lds de, 0
	call NoteMap_UpdateEntry

LABEL_FE0F5C:
	bitm 1, (xiz)
	jr z, LABEL_FE0F88
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xAC, 0x00
	ld xbc, xwa
	st_dri3b W, 0xF9, 0xC8, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE0F88
	lda xwa, (xsp + 8)
	ld xbc, xiz
	lds de, 1
	call NoteMap_UpdateEntry

LABEL_FE0F88:
	bitm 2, (xiz)
	jr z, LABEL_FE0FB4
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xAC, 0x00
	ld xbc, xwa
	st_dri3b W, 0xF9, 0xCC, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE0FB4
	lda xwa, (xsp + 8)
	ld xbc, xiz
	lds de, 2
	call NoteMap_UpdateEntry

LABEL_FE0FB4:
	bitm 3, (xiz)
	jrl z, VoiceProcess_NextChannel
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xAC, 0x00
	ld xbc, xwa
	st_dri3b W, 0xF9, 0xD0, 0x00
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

LABEL_FE0FE4:
	cp (xiz + 1), 0x15
	jr nz, LABEL_FE100C
	ldda16 xwa, 50584
	bit 1, wa
	jr z, LABEL_FE0FFC
	st_dri3b W, 0xFD, 0xAC, 0x00
	call NoteMap_MarkEntriesAboveThreshold

LABEL_FE0FFC:
	st_dri3b W, 0xFD, 0xAC, 0x00
	ld xbc, xiz
	ldw de, 0x15
	call NoteMap_UpdateEntry
	jr VoiceProcess_NextChannel

LABEL_FE100C:
	bitm 3, (xiz)
	jr z, LABEL_FE1039
	lda xwa, (xsp + 8)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xAC, 0x00
	ld xbc, xwa
	st_dri3b W, 0xF9, 0xD0, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE1039
	lda xwa, (xsp + 8)
	ld xbc, xiz
	ldw de, 0x15
	call NoteMap_UpdateEntry

LABEL_FE1039:
	st_dri3b W, 0xFD, 0xAC, 0x00
	ld xbc, xwa
	ld a, (xiz + 1)
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, xiz
	call NoteMap_UpdateEntry

VoiceProcess_NextChannel:
	incm8 1, (xsp + 6)
	cp (xsp + 6), 0x1A
	jrl c, LABEL_FE0EA9

LABEL_FE1059:
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x10
	jrl c, LABEL_FE0E96

LABEL_FE1063:
	pop xiz
	st_dri3b L, 0xFD, 0xF0, 0x01
	ret

NoteMap_ProcessAndMerge:
	st_dri3b L, 0xFD, 0xB8, 0xFE
	push xiz
	ldada xiz, 49662
	stib_dri 0xFD, 0xA8, 0x00, 0x90
	stib_dri 0xFD, 0xAA, 0x00, 0x00
	stib_dri 0xFD, 0xAB, 0x00, 0x00
	st_dri3b W, 0xFD, 0xA8, 0x00
	call Voice_LookupTableEntries
	cps l, 0
	jrl z, NoteMap_AddEntry_Return
	st_dri3b W, 0xFD, 0xA8, 0x00
	call NoteMap_AssignAllVoiceLinks
	cp (xiz + 1), 0xFF
	jrl nz, LABEL_FE1147
	lda xwa, (xsp + 4)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA8, 0x00
	ld xbc, xwa
	st_dri3b W, 0xF9, 0xC4, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE10CC
	lda xwa, (xsp + 4)
	ld xbc, xiz
	lds de, 0
	call NoteMap_AddEntry

LABEL_FE10CC:
	lda xwa, (xsp + 4)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA8, 0x00
	ld xbc, xwa
	st_dri3b W, 0xF9, 0xC4, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE10F4
	lda xwa, (xsp + 4)
	ld xbc, xiz
	lds de, 1
	call NoteMap_AddEntry

LABEL_FE10F4:
	lda xwa, (xsp + 4)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA8, 0x00
	ld xbc, xwa
	st_dri3b W, 0xF9, 0xCC, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE111C
	lda xwa, (xsp + 4)
	ld xbc, xiz
	lds de, 2
	call NoteMap_AddEntry

LABEL_FE111C:
	lda xwa, (xsp + 4)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA8, 0x00
	ld xbc, xwa
	st_dri3b W, 0xF9, 0xD0, 0x00
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

LABEL_FE1147:
	lda xwa, (xsp + 4)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA8, 0x00
	ld xbc, xwa
	st_dri3b W, 0xF9, 0xD0, 0x00
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE1170
	lda xwa, (xsp + 4)
	ld xbc, xiz
	ldw de, 0x15
	call NoteMap_AddEntry

LABEL_FE1170:
	st_dri3b W, 0xFD, 0xA8, 0x00
	ld xbc, xwa
	ld a, (xiz + 1)
	ld e, a
	extz de
	ld xwa, xbc
	ld xbc, xiz
	call NoteMap_AddEntry

NoteMap_AddEntry_Return:
	pop xiz
	st_dri3b L, 0xFD, 0x48, 0x01
	ret

NoteMap_SendAllNotesOff:
	st_dri3b L, 0xFD, 0x58, 0xFF
	push_werp 0xFA
	ldada xwa, 49662
	ld (xsp + 2), xwa
	ldi_berp 0xFB, 0
	cp_erpb 0xFB, 0x10
	jr nc, LABEL_FE120C

LABEL_FE11A5:
	ld (xsp + 6), 0x90
	ld (xsp + 8), 0x2
	ldto_berp A, 0xFB
	ld (xsp + 9), a
	ldto_berp A, 0xFB
	extz wa
	add wa, 0x84
	extz xwa
	add xwa, (xsp + 2)
	ld e, (xwa)
	ld a, e
	cp a, 0xFF
	jr z, LABEL_FE11D6
	lda xwa, (xsp + 6)
	extz de
	ld xbc, (xsp + 2)
	call NoteMap_ProcessNoteEvent

LABEL_FE11D6:
	ld (xsp + 8), 0x3
	ldto_berp A, 0xFB
	ld (xsp + 9), a
	ldto_berp A, 0xFB
	extz wa
	add wa, 0x84
	extz xwa
	add xwa, (xsp + 2)
	ld e, (xwa)
	ld a, e
	cp a, 0xFF
	jr z, LABEL_FE1203
	lda xwa, (xsp + 6)
	extz de
	ld xbc, (xsp + 2)
	call NoteMap_ProcessNoteEvent

LABEL_FE1203:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr c, LABEL_FE11A5

LABEL_FE120C:
	pop_werp 0xFA
	st_dri3b L, 0xFD, 0xA8, 0x00
	ret

Voice_InitTableGroup:
	st_dri3b L, 0xFD, 0x58, 0xFF
	push_werp 0xFA
	ldada xwa, 49662
	ld (xsp + 2), xwa
	ld (xsp + 6), 0x90
	ld (xsp + 8), 0x4
	ldi_berp 0xFB, 0
	cpi_berp 0xFB, 5
	jr nc, LABEL_FE125D

LABEL_FE1234:
	ldto_berp A, 0xFB
	ld (xsp + 9), a
	ldto_berp A, 0xFB
	extz wa
	lda_24 xbc, 0xee8ef0
	ld_srib3 E, 0x07, 0xE4, 0xE0
	lda xwa, (xsp + 6)
	extz de
	ld xbc, (xsp + 2)
	call NoteMap_LookupAndAllocVoice
	inc1_berp 0xFB
	cpi_berp 0xFB, 5
	jr c, LABEL_FE1234

LABEL_FE125D:
	pop_werp 0xFA
	st_dri3b L, 0xFD, 0xA8, 0x00
	ret

Voice_InitTablePair:
	st_dri3b L, 0xFD, 0x58, 0xFF
	push_werp 0xFA
	ldada xwa, 49662
	ld (xsp + 2), xwa
	ld (xsp + 6), 0x90
	ld (xsp + 8), 0x5
	ldi_berp 0xFB, 0
	cpi_berp 0xFB, 2
	jr nc, LABEL_FE12AE

LABEL_FE1285:
	ldto_berp A, 0xFB
	ld (xsp + 9), a
	ldto_berp A, 0xFB
	extz wa
	lda_24 xbc, 0xee8efe
	ld_srib3 E, 0x07, 0xE4, 0xE0
	lda xwa, (xsp + 6)
	extz de
	ld xbc, (xsp + 2)
	call NoteMap_LookupAllocAndStoreResult
	inc1_berp 0xFB
	cpi_berp 0xFB, 2
	jr c, LABEL_FE1285

LABEL_FE12AE:
	pop_werp 0xFA
	st_dri3b L, 0xFD, 0xA8, 0x00
	ret

LABEL_FE12B7:
	ret

LABEL_FE12B8:
	ldada xwa, 49662
	lds bc, 0
	call NoteMap_AllocateVoice
	ldada xwa, 49662
	lds bc, 1
	call NoteMap_AllocateVoice
	cpdi16 52770, 0
	ret z
	call NoteMap_FindBestMatch
	cp l, 0xFF
	ret z
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_AllocateVoice
	ret

LABEL_FE12E8:
	ldada	xwa, 49662
	lds	bc, 0
	call	16662177
	ldada	xwa, 49662
	lds	bc, 1
	jp	16662177

LABEL_FE12FC:
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_AssignVoiceParams
	ldada xwa, 49662
	lds bc, 2
	jp NoteMap_InitVoiceSlots
LABEL_FE1310:
	.byte 0x0e

LABEL_FE1311:
	pushw iz
	lds iz, 0
	cpda16 xiz, 50378
	jrl nc, LABEL_FE143D

; Voice event type dispatch
VoiceEvent_TypeDispatch:	; FE131B
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
	cp wa, 0xD
	jrl gt, AudioInit_FlushQueue_LoopNext
	add wa, wa
	lda_24 xix, 0xee8f06
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xfe137d
	jp_dri 8, 0x07, 0xF0, 0xE0

; Voice event handler dispatch (14-entry, table 0xEE8F06)
VoiceEvent_Dispatch:	; FE137D
	ld a, l
	extz wa
	extz bc
	extz de
	call LABEL_FE745F
	jrl AudioInit_FlushQueue_LoopNext

LABEL_FE138C:
	ld a, c
	extz wa
	ld c, e
	extz bc
	call LABEL_FE760D
	jrl AudioInit_FlushQueue_LoopNext

LABEL_FE139B:
	ld a, l
	extz wa
	extz bc
	extz de
	call LABEL_FE672F
	jrl AudioInit_FlushQueue_LoopNext

LABEL_FE13AA:
	ld a, l
	extz wa
	extz bc
	extz de
	call LABEL_FE78C7
	jr AudioInit_FlushQueue_LoopNext

LABEL_FE13B8:
	ld a, l
	extz wa
	extz bc
	extz de
	call LABEL_FE780A
	jr AudioInit_FlushQueue_LoopNext

LABEL_FE13C6:
	ld a, c
	extz wa
	ld c, e
	extz bc
	call LABEL_FE7A3E
	jr AudioInit_FlushQueue_LoopNext

LABEL_FE13D4:
	ld a, l
	extz wa
	extz bc
	extz de
	call LABEL_FE7E03
	jr AudioInit_FlushQueue_LoopNext

LABEL_FE13E2:
	ld a, l
	extz wa
	extz bc
	extz de
	call LABEL_FE7E62
	jr AudioInit_FlushQueue_LoopNext

LABEL_FE13F0:
	ld a, l
	extz wa
	extz bc
	extz de
	call LABEL_FE7FAA
	jr AudioInit_FlushQueue_LoopNext

LABEL_FE13FE:
	ld a, l
	extz wa
	extz bc
	extz de
	call LABEL_FE8177
	jr AudioInit_FlushQueue_LoopNext

LABEL_FE140C:
	ld a, l
	extz wa
	extz bc
	extz de
	call LABEL_FE82A5
	jr AudioInit_FlushQueue_LoopNext

LABEL_FE141A:
	call Voice_UpdatePlayModeState
	cp l, 0xFF
	jr z, AudioInit_FlushQueue_LoopNext
	calr LABEL_FE12B8
	jr AudioInit_FlushQueue_LoopNext

LABEL_FE1428:
	call NoteMap_FindBestMatch
	cp l, 0xFF
	call_24 nz, 0xFE12FC

AudioInit_FlushQueue_LoopNext:
	inc 1, iz
	cpda16 xiz, 50378
	jrl c, VoiceEvent_TypeDispatch

LABEL_FE143D:
	stdi16 50378, 0
	popw iz
	ret

LABEL_FE1445:
	st_dri3b L, 0xFD, 0xB0, 0xFE
	lda_dri3 XHL, 0xFD, 0x4E, 0x01
	cp a, 0xFF
	jrl z, LABEL_FE14F8
	stib_dri 0xFD, 0xAA, 0x00, 0x90
	lda_dri3 XBC, 0xFD, 0xAC, 0x00
	stib_dri 0xFD, 0xAD, 0x00, 0xFF
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xAA, 0x00
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
	ld (xsp + 256), 0xB0
	ld_srib A, (xsp + 0x014e)
	ld (xsp + 1), a
	ld (xsp + 2), 0x7B
	ld (xsp + 3), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	lds de, 0
	jr LABEL_FE14C3

LABEL_FE14AD:
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

LABEL_FE14C3:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, LABEL_FE14AD
	ld_srib A, (xsp + 0x014e)
	extz wa
	ldada xbc, 49666
	extz xwa
	add xwa, xbc
	cp (xwa), 0xFF
	jrl z, Audio_StoreParamAndReturn
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	jrl Audio_StoreParamAndReturn

LABEL_FE14F8:
	stib_dri 0xFD, 0xAA, 0x00, 0x90
	stib_dri 0xFD, 0xAC, 0x00, 0x00
	stib_dri 0xFD, 0xAD, 0x00, 0xFF
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xAA, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jrl z, LABEL_FE1728
	ld (xsp + 256), 0x4
	ld (xsp + 1), 0xB0
	ld_srib A, (xsp + 0x014e)
	ld (xsp + 2), a
	ld (xsp + 3), 0x7B
	ld (xsp + 4), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	lds de, 0
	jr LABEL_FE1567

LABEL_FE1551:
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

LABEL_FE1567:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, LABEL_FE1551
	ld_srib A, (xsp + 0x014e)
	extz wa
	ldada xbc, 49666
	extz xwa
	add xwa, xbc
	cp (xwa), 0xFF
	jr z, LABEL_FE1598
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LABEL_FE1598:
	stib_dri 0xFD, 0xAC, 0x00, 0x01
	stib_dri 0xFD, 0xAD, 0x00, 0xFF
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xAA, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jr z, LABEL_FE15FB
	lds de, 0
	jr LABEL_FE15DE

LABEL_FE15C8:
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

LABEL_FE15DE:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, LABEL_FE15C8
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LABEL_FE15FB:
	stib_dri 0xFD, 0xAC, 0x00, 0x02
	stib_dri 0xFD, 0xAD, 0x00, 0xFF
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xAA, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jr z, LABEL_FE165E
	lds de, 0
	jr LABEL_FE1641

LABEL_FE162B:
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

LABEL_FE1641:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, LABEL_FE162B
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LABEL_FE165E:
	stib_dri 0xFD, 0xAC, 0x00, 0x03
	stib_dri 0xFD, 0xAD, 0x00, 0xFF
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xAA, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jr z, LABEL_FE16C1
	lds de, 0
	jr LABEL_FE16A4

LABEL_FE168E:
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

LABEL_FE16A4:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, LABEL_FE168E
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LABEL_FE16C1:
	stib_dri 0xFD, 0xAC, 0x00, 0x06
	stib_dri 0xFD, 0xAD, 0x00, 0xFF
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xAA, 0x00
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
	jr LABEL_FE1708

LABEL_FE16F2:
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

LABEL_FE1708:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, LABEL_FE16F2
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	jrl Audio_StoreParamAndReturn

LABEL_FE1728:
	stib_dri 0xFD, 0xAA, 0x00, 0x90
	stib_dri 0xFD, 0xAC, 0x00, 0x01
	stib_dri 0xFD, 0xAD, 0x00, 0xFF
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xAA, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jrl z, LABEL_FE18E1
	ld (xsp + 256), 0x4
	ld (xsp + 1), 0xB0
	ld_srib A, (xsp + 0x014e)
	ld (xsp + 2), a
	ld (xsp + 3), 0x7B
	ld (xsp + 4), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	lds de, 0
	jr LABEL_FE1797

LABEL_FE1781:
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

LABEL_FE1797:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, LABEL_FE1781
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	stib_dri 0xFD, 0xAC, 0x00, 0x02
	stib_dri 0xFD, 0xAD, 0x00, 0xFF
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xAA, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jr z, LABEL_FE1817
	lds de, 0
	jr LABEL_FE17FA

LABEL_FE17E4:
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

LABEL_FE17FA:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, LABEL_FE17E4
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LABEL_FE1817:
	stib_dri 0xFD, 0xAC, 0x00, 0x03
	stib_dri 0xFD, 0xAD, 0x00, 0xFF
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xAA, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jr z, LABEL_FE187A
	lds de, 0
	jr LABEL_FE185D

LABEL_FE1847:
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

LABEL_FE185D:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, LABEL_FE1847
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LABEL_FE187A:
	stib_dri 0xFD, 0xAC, 0x00, 0x06
	stib_dri 0xFD, 0xAD, 0x00, 0xFF
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xAA, 0x00
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
	jr LABEL_FE18C1

LABEL_FE18AB:
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

LABEL_FE18C1:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, LABEL_FE18AB
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	jrl Audio_StoreParamAndReturn

LABEL_FE18E1:
	stib_dri 0xFD, 0xAC, 0x00, 0x02
	stib_dri 0xFD, 0xAD, 0x00, 0xFF
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xAA, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jrl z, LABEL_FE1A31
	ld (xsp + 256), 0x4
	ld (xsp + 1), 0xB0
	ld_srib A, (xsp + 0x014e)
	ld (xsp + 2), a
	ld (xsp + 3), 0x7B
	ld (xsp + 4), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	lds de, 0
	jr LABEL_FE194A

LABEL_FE1934:
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

LABEL_FE194A:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, LABEL_FE1934
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	stib_dri 0xFD, 0xAC, 0x00, 0x03
	stib_dri 0xFD, 0xAD, 0x00, 0xFF
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xAA, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jr z, LABEL_FE19CA
	lds de, 0
	jr LABEL_FE19AD

LABEL_FE1997:
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

LABEL_FE19AD:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, LABEL_FE1997
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LABEL_FE19CA:
	stib_dri 0xFD, 0xAC, 0x00, 0x06
	stib_dri 0xFD, 0xAD, 0x00, 0xFF
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xAA, 0x00
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
	jr LABEL_FE1A11

LABEL_FE19FB:
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

LABEL_FE1A11:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, LABEL_FE19FB
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	jrl Audio_StoreParamAndReturn

LABEL_FE1A31:
	stib_dri 0xFD, 0xAC, 0x00, 0x03
	stib_dri 0xFD, 0xAD, 0x00, 0xFF
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xAA, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jrl z, LABEL_FE1B1E
	ld (xsp + 256), 0x4
	ld (xsp + 1), 0xB0
	ld_srib A, (xsp + 0x014e)
	ld (xsp + 2), a
	ld (xsp + 3), 0x7B
	ld (xsp + 4), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	lds de, 0
	jr LABEL_FE1A9A

LABEL_FE1A84:
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

LABEL_FE1A9A:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, LABEL_FE1A84
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	stib_dri 0xFD, 0xAC, 0x00, 0x06
	stib_dri 0xFD, 0xAD, 0x00, 0xFF
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xAA, 0x00
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
	jr LABEL_FE1AFE

LABEL_FE1AE8:
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

LABEL_FE1AFE:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, LABEL_FE1AE8
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	jrl Audio_StoreParamAndReturn

LABEL_FE1B1E:
	stib_dri 0xFD, 0xAC, 0x00, 0x06
	stib_dri 0xFD, 0xAD, 0x00, 0xFF
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xAA, 0x00
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
	ld (xsp + 1), 0xB0
	ld_srib A, (xsp + 0x014e)
	ld (xsp + 2), a
	ld (xsp + 3), 0x7B
	ld (xsp + 4), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	lds de, 0
	jr LABEL_FE1B86

LABEL_FE1B70:
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

LABEL_FE1B86:
	ld a, (xsp + 7)
	extz wa
	cp de, wa
	jr c, LABEL_FE1B70
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

Audio_StoreParamAndReturn:
	st_dri3b L, 0xFD, 0x50, 0x01
	ret

MidiEvent_ConfigChannel:
	st_dri3b L, 0xFD, 0xB0, 0xFE
	lda_dri3 XHL, 0xFD, 0x4E, 0x01
	cp a, 0xFF
	jr z, LABEL_FE1C37
	stib_dri 0xFD, 0xAA, 0x00, 0x90
	lda_dri3 XBC, 0xFD, 0xAC, 0x00
	stib_dri 0xFD, 0xAD, 0x00, 0xFF
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xAA, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jrl z, LABEL_FE1CB3
	ld (xsp + 256), 0x4
	ld (xsp + 256), 0xB0
	ld_srib A, (xsp + 0x014e)
	ld (xsp + 1), a
	ld (xsp + 2), 0x7B
	ld (xsp + 3), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	ld_srib A, (xsp + 0x014e)
	extz wa
	ldada xbc, 49666
	extz xwa
	add xwa, xbc
	cp (xwa), 0xFF
	jrl z, LABEL_FE1CB3
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam
	jr LABEL_FE1CB3

LABEL_FE1C37:
	stib_dri 0xFD, 0xAA, 0x00, 0x90
	stib_dri 0xFD, 0xAC, 0x00, 0x06
	stib_dri 0xFD, 0xAD, 0x00, 0xFF
	lda xwa, (xsp + 6)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xAA, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014e)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_ClaimVoiceSlot
	cps l, 0
	jr z, LABEL_FE1CB3
	ld (xsp + 256), 0x4
	ld (xsp + 1), 0xB0
	ld_srib A, (xsp + 0x014e)
	ld (xsp + 2), a
	ld (xsp + 3), 0x7B
	ld (xsp + 4), 0x0
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	ld_srib A, (xsp + 0x014e)
	extz wa
	ldada xbc, 49666
	extz xwa
	add xwa, xbc
	cp (xwa), 0xFF
	jr z, LABEL_FE1CB3
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld_srib A, (xsp + 0x014e)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LABEL_FE1CB3:
	st_dri3b L, 0xFD, 0x50, 0x01
	ret

Voice_FindAndAllocBestMatch:
	cpdi16 52770, 0
	ret z
	call NoteMap_FindBestMatch
	cp l, 0xFF
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
	jr LABEL_FE1D13

LABEL_FE1CE3:
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
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ld (xhl), a
	ld wa, de
	add wa, wa
	ldada xbc, 52995
	extz xwa
	add xwa, xbc
	ld (xwa), 0x40
	inc 1, de

LABEL_FE1D13:
	ldda8 a, 52965
	extz wa
	cp de, wa
	jr lt, LABEL_FE1CE3
	call LABEL_FEA066
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
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ld (xsp + 4), a
	lds iz, 0
	jrl LABEL_FE1E7B

LABEL_FE1D5C:
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	cp (xbc + 1), 0x0
	jrl z, LABEL_FE1DFC
	ldda8 a, 59433
	ldfr_berp A, 0xFB
	cp a, 0x20
	jrl z, MidiEvent_NoteLoopAdvance
	ldada xde, 59368
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SwapVoiceLinks
	ldada xhl, 59368
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld a, (xsp + 4)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_LinkVoiceSlots
	ldto_berp A, 0xFB
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
	lda_dri3 XBC, 0x07, 0xEC, 0xE8
	ldto_berp A, 0xFB
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
	lda_dri3 XBC, 0x07, 0xEC, 0xE8
	incdi16 1, 59834
	jr MidiEvent_NoteLoopAdvance

LABEL_FE1DFC:
	ldto_berp A, 0xF8
	ld c, a
	extz bc
	ld xwa, (xsp + 6)
	call LABEL_FE4231
	ldfr_berp L, 0xFB
	ldto_berp A, 0xFB
	cp a, (xsp + 4)
	jr z, LABEL_FE1E66
	ldada xde, 59368
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SwapVoiceLinks
	ldada xde, 59368
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, xde
	ldw de, 0x20
	call NoteMap_LinkVoiceSlots
	ldto_berp A, 0xFB
	extz wa
	muls wa, 0x3
	ldada xbc, 50635
	stib_dri 0x07, 0xE4, 0xE0, 0xFF
	ldto_berp A, 0xFB
	extz wa
	muls wa, 0x3
	ldada xbc, 50636
	stib_dri 0x07, 0xE4, 0xE0, 0xFF
	decdi16 1, 59834
	jr MidiEvent_NoteLoopAdvance

LABEL_FE1E66:
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

LABEL_FE1E7B:
	ld xwa, (xsp + 6)
	ld a, (xwa + 1)
	extz wa
	cp iz, wa
	jrl c, LABEL_FE1D5C
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
	cp (xwa), 0xFF
	jr z, MidiEvent_NoteSeqCount

LABEL_FE1EAC:
	call SeqAlt4_ReadByte
	ld (xsp + 6), hl
	ld wa, (xsp + 6)
	cp wa, 0xFFFF
	jr nz, LABEL_FE1EC4
	ld xwa, (xsp + 8)
	ld (xwa), 0xFF
	jr MidiEvent_NoteSeqCount

LABEL_FE1EC4:
	call SeqAlt4_ReadByte
	ld wa, hl
	cp wa, 0xFFFF
	jr nz, LABEL_FE1ED8
	ld xwa, (xsp + 8)
	ld (xwa), 0xFF
	jr MidiEvent_NoteSeqCount

LABEL_FE1ED8:
	cpw (xsp + 4), 0x20
	jr nc, LABEL_FE1F1B
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

LABEL_FE1F1B:
	incm 1, (xsp + 4)
	ld xwa, (xsp + 8)
	cp (xwa), 0xFF
	jr nz, LABEL_FE1EAC

MidiEvent_NoteSeqCount:
	cpw (xsp + 4), 0x20
	jr ugt, LABEL_FE1F37
	ld wa, (xsp + 4)
	ld l, a
	ld (xiz + 1), l
	jr LABEL_FE1F41

LABEL_FE1F37:
	call NoteMap_ProcessAndMerge
	ld (xiz + 1), 0x0
	ldb l, 0x0

LABEL_FE1F41:
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
	cp a, 0xFF
	jrl z, MidiEvent_ClampAndStoreParam
	cps a, 0
	jr z, LABEL_FE1F92
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

LABEL_FE1F92:
	cp (xiz), 0xFF
	jrl z, MidiEvent_ClampAndStoreParam

LABEL_FE1F98:
	call SeqMain_ReadData
	ld (xsp + 6), hl
	ld wa, (xsp + 6)
	cp wa, 0xFFFF
	jr nz, LABEL_FE1FAE
	ld (xiz), 0xFF
	jrl MidiEvent_ClampAndStoreParam

LABEL_FE1FAE:
	call SeqMain_ReadData
	ld (xsp + 8), hl
	ld wa, (xsp + 8)
	cp wa, 0xFFFF
	jr nz, LABEL_FE1FC4
	ld (xiz), 0xFF
	jrl MidiEvent_ClampAndStoreParam

LABEL_FE1FC4:
	call SeqMain_ReadData
	ld wa, hl
	cp wa, 0xFFFF
	jr nz, LABEL_FE1FD6
	ld (xiz), 0xFF
	jrl MidiEvent_ClampAndStoreParam

LABEL_FE1FD6:
	cps hl, 0
	jr z, MidiEvent_ProcessCC_Continue
	cpdi8 50019, 255
	jr z, LABEL_FE1FE9
	ldda8 l, 50019
	extz hl
	jr MidiEvent_ProcessCC_Continue

LABEL_FE1FE9:
	cpdi8 50018, 0
	jr le, LABEL_FE200C
	ldda8 a, 50018
	exts wa
	add wa, hl
	cp a, 0x7F
	jr ule, LABEL_FE2002
	ldw hl, 0x7F
	jr MidiEvent_ProcessCC_Continue

LABEL_FE2002:
	ldda8 a, 50018
	exts wa
	add hl, wa
	jr MidiEvent_ProcessCC_Continue

LABEL_FE200C:
	ldda8 a, 50018
	exts wa
	add wa, hl
	cps a, 0
	jr ge, LABEL_FE201C
	lds hl, 1
	jr MidiEvent_ProcessCC_Continue

LABEL_FE201C:
	ldda8 a, 50018
	exts wa
	add hl, wa

MidiEvent_ProcessCC_Continue:
	ld wa, (xsp + 6)
	and a, 0xF0
	cp a, 0xB0
	jr nz, LABEL_FE208F
	cpw (xsp + 4), 0x0
	jr nz, LABEL_FE2078
	ld (xiz), 0xB0
	ld wa, (xsp + 6)
	and a, 0xF
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

LABEL_FE205C:
	cp (xiz), 0xFF
	jrl nz, LABEL_FE1F98

MidiEvent_ClampAndStoreParam:
	cpw (xsp + 4), 0x20
	jrl ugt, LABEL_FE21C9
	ld wa, (xsp + 4)
	ld l, a
	ld xwa, (xsp + 10)
	ld (xwa + 1), l
	jrl LABEL_FE21D6

LABEL_FE2078:
	ld (xiz), 0xB0
	ld wa, (xsp + 6)
	and a, 0xF
	ld (xiz + 1), a
	ld wa, (xsp + 8)
	ld (xiz + 3), a
	ld (xiz + 4), l
	jr MidiEvent_ClampAndStoreParam

LABEL_FE208F:
	cpw (xsp + 4), 0x0
	jrl nz, LABEL_FE2121
	ld (xiz), 0x90
	ld wa, (xsp + 6)
	and a, 0xF
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
	and a, 0xF0
	cp a, 0x80
	jr nz, LABEL_FE2107
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 10)
	ld (xbc + 1), 0x0
	jr LABEL_FE211B

LABEL_FE2107:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 10)
	ld (xbc + 1), l

LABEL_FE211B:
	incm 1, (xsp + 4)
	jrl LABEL_FE205C

LABEL_FE2121:
	ld wa, (xsp + 6)
	and a, 0xF
	cp a, (xiz + 1)
	jr nz, LABEL_FE219F
	cp (xiz), 0xB0
	jr z, LABEL_FE219F
	cpw (xsp + 4), 0x20
	jr nc, LABEL_FE2199
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
	and a, 0xF0
	cp a, 0x80
	jr nz, LABEL_FE2185
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 10)
	ld (xbc + 1), 0x0
	jr LABEL_FE2199

LABEL_FE2185:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 10)
	ld (xbc + 1), l

LABEL_FE2199:
	incm 1, (xsp + 4)
	jrl LABEL_FE205C

LABEL_FE219F:
	ld (xiz), 0x90
	ld wa, (xsp + 6)
	and a, 0xF
	ld (xiz + 1), a
	ld wa, (xsp + 8)
	ld (xiz + 3), a
	ld wa, (xsp + 6)
	and a, 0xF0
	cp a, 0x80
	jr nz, LABEL_FE21C3
	ld (xiz + 4), 0x0
	jrl MidiEvent_ClampAndStoreParam

LABEL_FE21C3:
	ld (xiz + 4), l
	jrl MidiEvent_ClampAndStoreParam

LABEL_FE21C9:
	call Voice_InitializeAll
	ld xwa, (xsp + 10)
	ld (xwa + 1), 0x0
	ldb l, 0x0

LABEL_FE21D6:
	pop xiz
	lda xsp, (xsp + 10)
	ret

LABEL_FE21DB:
	lda xsp, (xsp - 16)
	pushw iz
	ld (xsp + 10), xbc
	ld (xsp + 14), xwa
	ldw (xsp + 2), 0x0
	ld xwa, (xsp + 14)
	ld a, (xwa)
	cp a, 0xFF
	jrl z, NoteMap_FinalizeCount
	cps a, 0
	jr z, LABEL_FE224B
	ld xwa, (xsp + 14)
	ld c, (xwa)
	res 3, c
	ld xwa, (xsp + 10)
	ld (xwa), c
	ld xwa, (xsp + 14)
	bitm 3, (xwa)
	jr z, LABEL_FE2216
	ld xwa, (xsp + 10)
	ld (xwa + 2), 0x3
	jr LABEL_FE221D

LABEL_FE2216:
	ld xwa, (xsp + 10)
	ld (xwa + 2), 0x2

LABEL_FE221D:
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

LABEL_FE224B:
	ld xwa, (xsp + 14)
	cp (xwa), 0xFF
	jrl z, NoteMap_FinalizeCount

LABEL_FE2254:
	call SeqBuf_ReadAlternate
	ld iz, hl
	ld wa, iz
	cp wa, 0xFFFF
	jr nz, LABEL_FE226B
	ld xwa, (xsp + 14)
	ld (xwa), 0xFF
	jrl NoteMap_FinalizeCount

LABEL_FE226B:
	call SeqBuf_ReadAlternate
	ld (xsp + 4), hl
	ld wa, (xsp + 4)
	cp wa, 0xFFFF
	jr nz, LABEL_FE2284
	ld xwa, (xsp + 14)
	ld (xwa), 0xFF
	jrl NoteMap_FinalizeCount

LABEL_FE2284:
	call SeqBuf_ReadAlternate
	ld (xsp + 6), hl
	ld wa, (xsp + 6)
	cp wa, 0xFFFF
	jr nz, LABEL_FE229D
	ld xwa, (xsp + 14)
	ld (xwa), 0xFF
	jrl NoteMap_FinalizeCount

LABEL_FE229D:
	call SeqBuf_ReadAlternate
	ld (xsp + 8), hl
	ld wa, (xsp + 8)
	cp wa, 0xFFFF
	jr nz, LABEL_FE22B5
	ld xwa, (xsp + 14)
	ld (xwa), 0xFF
	jr NoteMap_FinalizeCount

LABEL_FE22B5:
	call SeqBuf_ReadAlternate
	ld wa, hl
	cp wa, 0xFFFF
	jr nz, LABEL_FE22C9
	ld xwa, (xsp + 14)
	ld (xwa), 0xFF
	jr NoteMap_FinalizeCount

LABEL_FE22C9:
	ld wa, (xsp + 4)
	cp a, 0x7F
	jrl nz, LABEL_FE236F
	cpw (xsp + 2), 0x0
	jr nz, LABEL_FE2341
	ldto_berp A, 0xF8
	and a, 0x8
	or a, 0xB0
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
	jr z, LABEL_FE230C
	ld xwa, (xsp + 10)
	ld (xwa + 2), 0x3
	jr LABEL_FE2313

LABEL_FE230C:
	ld xwa, (xsp + 10)
	ld (xwa + 2), 0x2

LABEL_FE2313:
	ld xwa, (xsp + 14)
	ld xbc, (xsp + 10)
	ld a, (xwa + 1)
	ld (xbc + 3), a
	incm 1, (xsp + 2)

LABEL_FE2322:
	ld xwa, (xsp + 14)
	cp (xwa), 0xFF
	jrl nz, LABEL_FE2254

NoteMap_FinalizeCount:
	cpw (xsp + 2), 0x20
	jrl ugt, LABEL_FE249F
	ld wa, (xsp + 2)
	ld l, a
	ld xwa, (xsp + 10)
	ld (xwa + 1), l
	jrl LABEL_FE24AC

LABEL_FE2341:
	ldto_berp A, 0xF8
	and a, 0x8
	or a, 0xB0
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

LABEL_FE236F:
	cpw (xsp + 2), 0x0
	jrl nz, LABEL_FE2405
	ldto_berp A, 0xF8
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
	jr z, LABEL_FE23AA
	ld xwa, (xsp + 10)
	ld (xwa + 2), 0x3
	jr LABEL_FE23B1

LABEL_FE23AA:
	ld xwa, (xsp + 10)
	ld (xwa + 2), 0x2

LABEL_FE23B1:
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
	jrl LABEL_FE2322

LABEL_FE2405:
	ld c, l
	ld xwa, (xsp + 14)
	cp c, (xwa + 1)
	jr nz, Voice_BuildProgramNotify
	ldto_berp C, 0xF8
	ld xwa, (xsp + 14)
	cp c, (xwa)
	jr nz, Voice_BuildProgramNotify
	ld xwa, (xsp + 14)
	cp (xwa), 0xB0
	jr z, Voice_BuildProgramNotify
	cpw (xsp + 2), 0x20
	jr nc, LABEL_FE246A
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

LABEL_FE246A:
	incm 1, (xsp + 2)
	jrl LABEL_FE2322

Voice_BuildProgramNotify:
	ldto_berp A, 0xF8
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

LABEL_FE249F:
	call NoteMap_SendAllNotesOff
	ld xwa, (xsp + 10)
	ld (xwa + 1), 0x0
	ldb l, 0x0

LABEL_FE24AC:
	popw iz
	lda xsp, (xsp + 16)
	ret

LABEL_FE24B1:
	lda xsp, (xsp - 12)
	pushw iz
	ld (xsp + 6), xbc
	ld (xsp + 10), xwa
	ldw (xsp + 2), 0x0
	ld xwa, (xsp + 10)
	ld a, (xwa)
	cp a, 0xFF
	jrl z, NoteMap_EncodeExtControlChange
	cps a, 0
	jr z, LABEL_FE250E
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

LABEL_FE250E:
	ld xwa, (xsp + 10)
	cp (xwa), 0xFF
	jrl z, NoteMap_EncodeExtControlChange

LABEL_FE2517:
	call RhythmBuf_ReadAlternate
	ld iz, hl
	ld wa, iz
	cp wa, 0xFFFF
	jr nz, LABEL_FE252D
	ld xwa, (xsp + 10)
	ld (xwa), 0xFF
	jr NoteMap_EncodeExtControlChange

LABEL_FE252D:
	call RhythmBuf_ReadAlternate
	ld (xsp + 4), hl
	ld wa, (xsp + 4)
	cp wa, 0xFFFF
	jr nz, LABEL_FE2545
	ld xwa, (xsp + 10)
	ld (xwa), 0xFF
	jr NoteMap_EncodeExtControlChange

LABEL_FE2545:
	call RhythmBuf_ReadAlternate
	ld wa, hl
	cp wa, 0xFFFF
	jr nz, LABEL_FE2559
	ld xwa, (xsp + 10)
	ld (xwa), 0xFF
	jr NoteMap_EncodeExtControlChange

LABEL_FE2559:
	cp_erpb 0xF8, 0x90
	jrl nz, LABEL_FE25E1
	ld wa, (xsp + 4)
	cp a, 0x7F
	jr nz, NoteMap_CheckEndMarker
	cpw (xsp + 2), 0x0
	jr nz, LABEL_FE25BC
	ld xwa, (xsp + 10)
	ld (xwa), 0xB0
	ld a, l
	dec 4, a
	ld c, a
	ld xwa, (xsp + 10)
	ld (xwa + 1), c
	ld xwa, (xsp + 6)
	ld (xwa), 0xB0
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
	cp (xwa), 0xFF
	jrl nz, LABEL_FE2517

NoteMap_EncodeExtControlChange:
	cpw (xsp + 2), 0x20
	jrl ugt, LABEL_FE2728
	ld wa, (xsp + 2)
	ld l, a
	ld xwa, (xsp + 6)
	ld (xwa + 1), l
	jrl LABEL_FE2735

LABEL_FE25BC:
	ld xwa, (xsp + 10)
	ld (xwa), 0xB0
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

LABEL_FE25E1:
	cp_erpb 0xF8, 0x94
	jr c, NoteMap_CheckEndMarker
	cp_erpb 0xF8, 0x98
	jr ugt, NoteMap_CheckEndMarker
	ld wa, (xsp + 4)
	cps a, 0
	jr z, NoteMap_CheckEndMarker
	cp_erpb 0xF8, 0x98
	jr nz, NoteMap_ProcessMergeAlloc
	ld wa, (xsp + 4)
	cp a, 0x7D
	jr c, NoteMap_ProcessMergeAlloc
	ld wa, (xsp + 4)
	cp a, 0x7F
	jr ugt, NoteMap_ProcessMergeAlloc
	ld wa, (xsp + 4)
	extz wa
	ld c, l
	extz bc
	call LABEL_FE66D7
	jr NoteMap_CheckEndMarker

NoteMap_ProcessMergeAlloc:
	cpw (xsp + 2), 0x0
	jr nz, LABEL_FE2698
	ld xwa, (xsp + 10)
	ld (xwa), 0x90
	ldto_berp A, 0xF8
	and a, 0xF
	dec 4, a
	ld c, a
	ld xwa, (xsp + 10)
	ld (xwa + 1), c
	ld xwa, (xsp + 6)
	ld (xwa), 0x90
	ld xwa, (xsp + 6)
	ld (xwa + 2), 0x4
	ldto_berp A, 0xF8
	and a, 0xF
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

LABEL_FE2698:
	ldto_berp A, 0xF8
	and a, 0xF
	dec 4, a
	ld c, a
	ld xwa, (xsp + 10)
	cp c, (xwa + 1)
	jr nz, LABEL_FE26FE
	ld xwa, (xsp + 10)
	cp (xwa), 0xB0
	jr z, LABEL_FE26FE
	cpw (xsp + 2), 0x20
	jr nc, LABEL_FE26F8
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

LABEL_FE26F8:
	incm 1, (xsp + 2)
	jrl NoteMap_CheckEndMarker

LABEL_FE26FE:
	ld xwa, (xsp + 10)
	ld (xwa), 0x90
	ldto_berp A, 0xF8
	and a, 0xF
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

LABEL_FE2728:
	call Voice_InitTableGroup
	ld xwa, (xsp + 6)
	ld (xwa + 1), 0x0
	ldb l, 0x0

LABEL_FE2735:
	popw iz
	lda xsp, (xsp + 12)
	ret

LABEL_FE273A:
	lda xsp, (xsp - 12)
	pushw iz
	ld (xsp + 6), xbc
	ld (xsp + 10), xwa
	ldw (xsp + 2), 0x0
	ld xwa, (xsp + 10)
	ld a, (xwa)
	cp a, 0xFF
	jrl z, NoteMap_EncodeControlChange
	cps a, 0
	jr z, LABEL_FE2797
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

LABEL_FE2797:
	ld xwa, (xsp + 10)
	cp (xwa), 0xFF
	jrl z, NoteMap_EncodeControlChange

LABEL_FE27A0:
	call SeqEvtBuf_ReadAlternate
	ld iz, hl
	ld wa, iz
	cp wa, 0xFFFF
	jr nz, LABEL_FE27B6
	ld xwa, (xsp + 10)
	ld (xwa), 0xFF
	jr NoteMap_EncodeControlChange

LABEL_FE27B6:
	call SeqEvtBuf_ReadAlternate
	ld (xsp + 4), hl
	ld wa, (xsp + 4)
	cp wa, 0xFFFF
	jr nz, LABEL_FE27CE
	ld xwa, (xsp + 10)
	ld (xwa), 0xFF
	jr NoteMap_EncodeControlChange

LABEL_FE27CE:
	call SeqEvtBuf_ReadAlternate
	ld wa, hl
	cp wa, 0xFFFF
	jr nz, LABEL_FE27E2
	ld xwa, (xsp + 10)
	ld (xwa), 0xFF
	jr NoteMap_EncodeControlChange

LABEL_FE27E2:
	cp_erpb 0xF8, 0x90
	jr nz, LABEL_FE285B
	ld wa, (xsp + 4)
	cp a, 0x7F
	jr nz, NoteMap_EncodeCC_Recheck
	cpw (xsp + 2), 0x0
	jr nz, LABEL_FE283A
	ld xwa, (xsp + 10)
	ld (xwa), 0xB0
	ld c, l
	ld xwa, (xsp + 10)
	ld (xwa + 1), c
	ld xwa, (xsp + 6)
	ld (xwa), 0xB0
	ld xwa, (xsp + 6)
	ld (xwa + 2), 0x5
	ld xwa, (xsp + 6)
	ld (xwa + 3), l
	incm 1, (xsp + 2)

NoteMap_EncodeCC_Recheck:
	ld xwa, (xsp + 10)
	cp (xwa), 0xFF
	jrl nz, LABEL_FE27A0

NoteMap_EncodeControlChange:
	cpw (xsp + 2), 0x20
	jrl ugt, LABEL_FE297D
	ld wa, (xsp + 2)
	ld l, a
	ld xwa, (xsp + 6)
	ld (xwa + 1), l
	jrl LABEL_FE298A

LABEL_FE283A:
	ld xwa, (xsp + 10)
	ld (xwa), 0xB0
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

LABEL_FE285B:
	cp_erpb 0xF8, 0x91
	jr c, NoteMap_EncodeCC_Recheck
	cp_erpb 0xF8, 0x92
	jr ugt, NoteMap_EncodeCC_Recheck
	ld wa, (xsp + 4)
	cps a, 0
	jr z, NoteMap_EncodeCC_Recheck
	cpw (xsp + 2), 0x0
	jr nz, LABEL_FE28ED
	ld xwa, (xsp + 10)
	ld (xwa), 0x90
	ldto_berp A, 0xF8
	and a, 0xF
	dec 1, a
	ld c, a
	ld xwa, (xsp + 10)
	ld (xwa + 1), c
	ld xwa, (xsp + 6)
	ld (xwa), 0x90
	ld xwa, (xsp + 6)
	ld (xwa + 2), 0x5
	ldto_berp A, 0xF8
	and a, 0xF
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

LABEL_FE28ED:
	ldto_berp A, 0xF8
	and a, 0xF
	dec 1, a
	ld c, a
	ld xwa, (xsp + 10)
	cp c, (xwa + 1)
	jr nz, LABEL_FE2953
	ld xwa, (xsp + 10)
	cp (xwa), 0xB0
	jr z, LABEL_FE2953
	cpw (xsp + 2), 0x20
	jr nc, LABEL_FE294D
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

LABEL_FE294D:
	incm 1, (xsp + 2)
	jrl NoteMap_EncodeCC_Recheck

LABEL_FE2953:
	ld xwa, (xsp + 10)
	ld (xwa), 0x90
	ldto_berp A, 0xF8
	and a, 0xF
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

LABEL_FE297D:
	call Voice_InitTablePair
	ld xwa, (xsp + 6)
	ld (xwa + 1), 0x0
	ldb l, 0x0

LABEL_FE298A:
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
	push_werp 0xFA
	ld (xsp + 2), e
	ld (xsp + 4), xbc
	ld (xsp + 8), xwa
	cp (xsp + 2), 0x15
	jrl nz, LABEL_FE2A45
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
	cp l, 0xFF
	jr z, NoteMap_AltCheckEmit
	ld xwa, (xsp + 4)
	lds bc, 2
	calr NoteMap_AllocateVoice

NoteMap_AltCheckEmit:
	ldda16 xwa, 50584
	bit 9, wa
	jr z, LABEL_FE2A2F
	ldi_berp 0xFB, 0
	cp_erpb 0xFB, 0x10
	jr nc, LABEL_FE2A2F

LABEL_FE2A05:
	ldto_berp A, 0xFB
	extz wa
	add wa, 0x84
	extz xwa
	add xwa, (xsp + 4)
	cp (xwa), 0x15
	jr nz, LABEL_FE2A26
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call Voice_BuildAndEmitNoteOnEvents

LABEL_FE2A26:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr c, LABEL_FE2A05

LABEL_FE2A2F:
	ld xwa, (xsp + 4)
	cp (xwa + 3), 0x0
	jrl nz, NoteMap_AllocCheckNoteOn
	ld xwa, (xsp + 8)
	lds bc, 1
	call NoteMap_EmitNoteOnEvents
	jrl NoteMap_AllocCheckNoteOn

LABEL_FE2A45:
	ld xwa, (xsp + 4)
	ld c, (xsp + 2)
	cp_srib_rm C, 0xE1, 0xB6, 0x00
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
	cp l, 0xFF
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
	jr nz, LABEL_FE2AD0
	ld a, (xsp + 2)
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call NoteMap_SetChannelParam

LABEL_FE2AD0:
	ld a, (xsp + 2)
	extz wa
	add wa, 0x24
	extz xwa
	add xwa, (xsp + 4)
	ld e, (xwa)
	ld a, e
	cp a, 0xFF
	jr z, LABEL_FE2B09
	ld a, (xsp + 2)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld xwa, (xsp + 4)
	bit_dri 5, 0x07, 0xE0, 0xE4
	jr z, LABEL_FE2B09
	ld c, e
	extz bc
	ld xwa, (xsp + 8)
	call Voice_ScanAndEmitMidiEvents

LABEL_FE2B09:
	ldda16 xwa, 50584
	bit 9, wa
	jr z, LABEL_FE2B47
	ldi_berp 0xFB, 0
	cp_erpb 0xFB, 0x10
	jr nc, LABEL_FE2B47

LABEL_FE2B1B:
	ldto_berp A, 0xFB
	extz wa
	add wa, 0x84
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	cp a, (xsp + 2)
	jr nz, LABEL_FE2B3E
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call Voice_BuildAndEmitNoteOnEvents

LABEL_FE2B3E:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr c, LABEL_FE2B1B

LABEL_FE2B47:
	ld a, (xsp + 2)
	extz wa
	add wa, 0x44
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	ldfr_berp A, 0xFB
	cp a, 0xFF
	jr z, LABEL_FE2B6D
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call SeqPart_EmitNoteOnMessages

LABEL_FE2B6D:
	ld a, (xsp + 2)
	extz wa
	add wa, 0x64
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	ldfr_berp A, 0xFB
	cp a, 0xFF
	jr z, LABEL_FE2B93
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call Voice_EmitMidiNoteOnEvents

LABEL_FE2B93:
	ld xwa, (xsp + 4)
	ld a, (xwa + 2)
	cp a, (xsp + 2)
	jr nz, NoteMap_AllocCheckNoteOn
	ld xwa, (xsp + 8)
	lds bc, 0
	call NoteMap_EmitNoteOnEvents

NoteMap_AllocCheckNoteOn:
	pop_werp 0xFA
	lda xsp, (xsp + 10)
	ret

LABEL_FE2BAE:
	.byte 0xbf, 0xf6, 0x37, 0xd7, 0xfa, 0x04, 0xbf, 0x02
	.byte 0x45, 0xbf, 0x04, 0x61, 0xbf, 0x08, 0x60, 0x8f
	.byte 0x02, 0x3f, 0x15, 0x6e, 0x7e, 0xaf, 0x08, 0x20
	.byte 0xd9, 0xa8, 0x1d, 0x67, 0x55, 0xfe, 0xaf, 0x08
	.byte 0x20, 0x1d, 0x24, 0x58, 0xfe, 0xcf, 0xd8, 0x6e
	.byte 0x29, 0xaf, 0x04, 0x20, 0xd9, 0xa8, 0x1e, 0xda
	.byte 0x13, 0xaf, 0x04, 0x20, 0xd9, 0xa9, 0x1e, 0xd2
	.byte 0x13, 0xd1, 0x22, 0xce, 0x3f, 0x00, 0x00, 0x66
	.byte 0x11, 0x1d, 0xfc, 0x8a, 0xfe, 0xcf, 0xcf, 0xff
	.byte 0x66, 0x08, 0xaf, 0x04, 0x20, 0xd9, 0xaa, 0x1e
	.byte 0xb9, 0x13, 0xd1, 0x98, 0xc5, 0x20, 0xd8, 0x33
	.byte 0x09, 0x76, 0x63, 0x01, 0xc7, 0xfb, 0xa8, 0xc7
	.byte 0xfb, 0xcf, 0x10, 0x7f, 0x59, 0x01, 0xc7, 0xfb
	.byte 0x89, 0xd8, 0x12, 0xd8, 0xc8, 0x84, 0x00, 0xe8
	.byte 0x12, 0xaf, 0x04, 0x80, 0x80, 0x3f, 0x15, 0x6e
	.byte 0x0e, 0xc7, 0xfb, 0x89, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0xaf, 0x08, 0x20, 0x1d, 0x0b, 0x52, 0xfe, 0xc7
	.byte 0xfb, 0x61, 0xc7, 0xfb, 0xcf, 0x10, 0x67, 0xd6
	.byte 0x78, 0x2c, 0x01, 0xaf, 0x04, 0x20, 0x8f, 0x02
	.byte 0x23, 0xc3, 0xe1, 0xb6, 0x00, 0xf3, 0x6e, 0x2d
	.byte 0xaf, 0x08, 0x20, 0xd9, 0xaa, 0x1d, 0x67, 0x55
	.byte 0xfe, 0xaf, 0x08, 0x20, 0x1d, 0x40, 0x5a, 0xfe
	.byte 0xcf, 0xd8, 0x6e, 0x19, 0x1d, 0x81, 0x8a, 0xfe
	.byte 0xcf, 0xcf, 0xff, 0x66, 0x10, 0xaf, 0x04, 0x20
	.byte 0xd9, 0xaa, 0x1e, 0x2e, 0x12, 0xaf, 0x04, 0x20
	.byte 0xd9, 0xaa, 0x1e, 0xaf, 0x10, 0x8f, 0x02, 0x21
	.byte 0xc9, 0x8b, 0xd9, 0x12, 0xaf, 0x08, 0x20, 0x1d
	.byte 0x0d, 0x4c, 0xfe, 0x8f, 0x02, 0x21, 0xd8, 0x12
	.byte 0xd8, 0x64, 0xe8, 0x12, 0xaf, 0x04, 0x80, 0x80
	.byte 0x21, 0x8f, 0x02, 0xf1, 0x6e, 0x0e, 0x8f, 0x02
	.byte 0x21, 0xc9, 0x8b, 0xd9, 0x12, 0xaf, 0x08, 0x20
	.byte 0x1d, 0xf9, 0x4e, 0xfe, 0x8f, 0x02, 0x21, 0xd8
	.byte 0x12, 0xd8, 0xc8, 0x24, 0x00, 0xe8, 0x12, 0xaf
	.byte 0x04, 0x80, 0x80, 0x25, 0xcd, 0x89, 0xc9, 0xcf
	.byte 0xff, 0x66, 0x22, 0x8f, 0x02, 0x21, 0xd8, 0x12
	.byte 0xd8, 0x80, 0xd8, 0x89, 0xd9, 0xc8, 0x24, 0x01
	.byte 0xaf, 0x04, 0x20, 0xf3, 0x07, 0xe0, 0xe4, 0xcd
	.byte 0x66, 0x0b, 0xcd, 0x8b, 0xd9, 0x12, 0xaf, 0x08
	.byte 0x20, 0x1d, 0xcf, 0x50, 0xfe, 0xd1, 0x98, 0xc5
	.byte 0x20, 0xd8, 0x33, 0x09, 0x66, 0x35, 0xc7, 0xfb
	.byte 0xa8, 0xc7, 0xfb, 0xcf, 0x10, 0x6f, 0x2c, 0xc7
	.byte 0xfb, 0x89, 0xd8, 0x12, 0xd8, 0xc8, 0x84, 0x00
	.byte 0xe8, 0x12, 0xaf, 0x04, 0x80, 0x80, 0x21, 0x8f
	.byte 0x02, 0xf1, 0x6e, 0x0e, 0xc7, 0xfb, 0x89, 0xc9
	.byte 0x8b, 0xd9, 0x12, 0xaf, 0x08, 0x20, 0x1d, 0x0b
	.byte 0x52, 0xfe, 0xc7, 0xfb, 0x61, 0xc7, 0xfb, 0xcf
	.byte 0x10, 0x67, 0xd4, 0x8f, 0x02, 0x21, 0xd8, 0x12
	.byte 0xd8, 0xc8, 0x44, 0x00, 0xe8, 0x12, 0xaf, 0x04
	.byte 0x80, 0x80, 0x21, 0xc7, 0xfb, 0x99, 0xc9, 0xcf
	.byte 0xff, 0x66, 0x0e, 0xc7, 0xfb, 0x89, 0xc9, 0x8b
	.byte 0xd9, 0x12, 0xaf, 0x08, 0x20, 0x1d, 0x3b, 0x53
	.byte 0xfe, 0x8f, 0x02, 0x21, 0xd8, 0x12, 0xd8, 0xc8
	.byte 0x64, 0x00, 0xe8, 0x12, 0xaf, 0x04, 0x80, 0x80
	.byte 0x21, 0xc7, 0xfb, 0x99, 0xc9, 0xcf, 0xff, 0x66
	.byte 0x0e, 0xc7, 0xfb, 0x89, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0xaf, 0x08, 0x20, 0x1d, 0x51, 0x54, 0xfe, 0xd7
	.byte 0xfa, 0x05, 0xbf, 0x0a, 0x37, 0x0e

NoteMap_CollectAndFindBestVoice:
	st_dri3b L, 0xFD, 0x52, 0xFF
	push_werp 0xFA
	lda_dri3 XIY, 0xFD, 0xA6, 0x00
	st_dri3l XBC, 0xFD, 0xA8, 0x00
	st_dri3l XWA, 0xFD, 0xAC, 0x00
	cp_srib_im 0xFD, 0xA6, 0x00, 0x15
	jrl nz, LABEL_FE2E4B
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
	cp l, 0xFF
	jr z, NoteMap_AltAllocEmit
	ld_sril XWA, (xsp + 0x00a8)
	lds bc, 2
	calr NoteMap_AllocateVoice

NoteMap_AltAllocEmit:
	ldda16 xwa, 50584
	bit 9, wa
	jrl z, NoteMap_PopRetFA_StoreAE
	ldi_berp 0xFB, 0
	cp_erpb 0xFB, 0x10
	jrl nc, NoteMap_PopRetFA_StoreAE

LABEL_FE2E18:
	ldto_berp A, 0xFB
	extz wa
	add wa, 0x84
	extz xwa
	add_sril_rm XWA, 0xFD, 0xA8, 0x00
	cp (xwa), 0x15
	jr nz, LABEL_FE2E3F
	lda xwa, (xsp + 2)
	ld xde, xwa
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

LABEL_FE2E3F:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr c, LABEL_FE2E18
	jrl NoteMap_PopRetFA_StoreAE

LABEL_FE2E4B:
	ld_sril XWA, (xsp + 0x00a8)
	ld_srib C, (xsp + 0x00a6)
	cp_srib_rm C, 0xE1, 0xB6, 0x00
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
	cp l, 0xFF
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
	add_sril_rm XWA, 0xFD, 0xA8, 0x00
	ld a, (xwa)
	cp_srib_rm A, 0xFD, 0xA6, 0x00
	jr nz, LABEL_FE2F32
	lda xwa, (xsp + 2)
	ld xde, xwa
	ld_srib A, (xsp + 0x00a6)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LABEL_FE2F32:
	ld_srib A, (xsp + 0x00a6)
	extz wa
	add wa, 0x24
	extz xwa
	add_sril_rm XWA, 0xFD, 0xA8, 0x00
	ld e, (xwa)
	ld a, e
	cp a, 0xFF
	jr z, LABEL_FE2F73
	ld_srib A, (xsp + 0x00a6)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld_sril XWA, (xsp + 0x00a8)
	bit_dri 5, 0x07, 0xE0, 0xE4
	jr z, LABEL_FE2F73
	lda xwa, (xsp + 2)
	ld c, e
	extz bc
	call Voice_ScanAndEmitMidiEvents

LABEL_FE2F73:
	ldda16 xwa, 50584
	bit 9, wa
	jr z, LABEL_FE2FB9
	ldi_berp 0xFB, 0
	cp_erpb 0xFB, 0x10
	jr nc, LABEL_FE2FB9

LABEL_FE2F85:
	ldto_berp A, 0xFB
	extz wa
	add wa, 0x84
	extz xwa
	add_sril_rm XWA, 0xFD, 0xA8, 0x00
	ld a, (xwa)
	cp_srib_rm A, 0xFD, 0xA6, 0x00
	jr nz, LABEL_FE2FB0
	lda xwa, (xsp + 2)
	ld xde, xwa
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

LABEL_FE2FB0:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr c, LABEL_FE2F85

LABEL_FE2FB9:
	ld_srib A, (xsp + 0x00a6)
	extz wa
	add wa, 0x44
	extz xwa
	add_sril_rm XWA, 0xFD, 0xA8, 0x00
	ld a, (xwa)
	ldfr_berp A, 0xFB
	cp a, 0xFF
	jr z, LABEL_FE2FE5
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld_sril XWA, (xsp + 0x00ac)
	call SeqPart_EmitNoteOnMessages

LABEL_FE2FE5:
	ld_srib A, (xsp + 0x00a6)
	extz wa
	add wa, 0x64
	extz xwa
	add_sril_rm XWA, 0xFD, 0xA8, 0x00
	ld a, (xwa)
	ldfr_berp A, 0xFB
	cp a, 0xFF
	jr z, NoteMap_PopRetFA_StoreAE
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld_sril XWA, (xsp + 0x00ac)
	call Voice_EmitMidiNoteOnEvents

NoteMap_PopRetFA_StoreAE:
	pop_werp 0xFA
	st_dri3b L, 0xFD, 0xAE, 0x00
	ret

LABEL_FE301A:
	lda xsp, (xsp - 10)
	push_werp 0xFA
	ld (xsp + 2), e
	ld (xsp + 4), xbc
	ld (xsp + 8), xwa
	cp (xsp + 2), 0x15
	jrl nz, LABEL_FE30C1
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
	cp l, 0xFF
	jr z, NoteMap_FallbackVoiceCheck
	ld xwa, (xsp + 4)
	lds bc, 2
	calr NoteMap_AllocateVoice

NoteMap_FallbackVoiceCheck:
	ldda16 xwa, 50584
	bit 9, wa
	jr z, LABEL_FE30AB
	ldi_berp 0xFB, 0
	cp_erpb 0xFB, 0x10
	jr nc, LABEL_FE30AB

LABEL_FE307F:
	ldto_berp A, 0xFB
	extz wa
	add wa, 0x84
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	cp a, (xsp + 2)
	jr nz, LABEL_FE30A2
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call Voice_BuildAndEmitNoteOnEvents

LABEL_FE30A2:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr c, LABEL_FE307F

LABEL_FE30AB:
	ld xwa, (xsp + 4)
	cp (xwa + 3), 0x0
	jrl nz, NoteMap_AllocVoiceEmit
	ld xwa, (xsp + 8)
	lds bc, 1
	call NoteMap_EmitNoteOnEvents
	jrl NoteMap_AllocVoiceEmit

LABEL_FE30C1:
	ld xwa, (xsp + 4)
	ld c, (xsp + 2)
	cp_srib_rm C, 0xE1, 0xB6, 0x00
	jr nz, NoteMap_LookupAllocEmit
	ld xwa, (xsp + 8)
	lds bc, 2
	call NoteMap_FindEntry
	ld xwa, (xsp + 8)
	call NoteMap_FindBestFreeVoice
	cps l, 1
	jr nz, NoteMap_LookupAllocEmit
	call VoiceMap_AllocateSlot
	cp l, 0xFF
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
	jr z, LABEL_FE3155
	ldi_berp 0xFB, 0
	cp_erpb 0xFB, 0x10
	jr nc, LABEL_FE3155

LABEL_FE3129:
	ldto_berp A, 0xFB
	extz wa
	add wa, 0x84
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	cp a, (xsp + 2)
	jr nz, LABEL_FE314C
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call Voice_BuildAndEmitNoteOnEvents

LABEL_FE314C:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr c, LABEL_FE3129

LABEL_FE3155:
	ld a, (xsp + 2)
	extz wa
	add wa, 0x44
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	ldfr_berp A, 0xFB
	cp a, 0xFF
	jr z, LABEL_FE317B
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call SeqPart_EmitNoteOnMessages

LABEL_FE317B:
	ld a, (xsp + 2)
	extz wa
	add wa, 0x64
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	ldfr_berp A, 0xFB
	cp a, 0xFF
	jr z, LABEL_FE31A1
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call Voice_EmitMidiNoteOnEvents

LABEL_FE31A1:
	ld xwa, (xsp + 4)
	cp (xwa + 3), 0x0
	jr nz, NoteMap_AllocVoiceEmit
	ld xwa, (xsp + 8)
	lds bc, 0
	call NoteMap_EmitNoteOnEvents

NoteMap_AllocVoiceEmit:
	pop_werp 0xFA
	lda xsp, (xsp + 10)
	ret

NoteMap_CollectAndAllocVoice_Indirect:
	st_dri3b L, 0xFD, 0x52, 0xFF
	push_werp 0xFA
	lda_dri3 XIY, 0xFD, 0xA6, 0x00
	st_dri3l XBC, 0xFD, 0xA8, 0x00
	st_dri3l XWA, 0xFD, 0xAC, 0x00
	cp_srib_im 0xFD, 0xA6, 0x00, 0x15
	jrl nz, LABEL_FE327E
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
	cp l, 0xFF
	jr z, NoteMap_IndirectCollectEmit
	ld_sril XWA, (xsp + 0x00a8)
	lds bc, 2
	calr NoteMap_AllocateVoice

NoteMap_IndirectCollectEmit:
	ldda16 xwa, 50584
	bit 9, wa
	jrl z, NoteMap_PopRetFA_StoreAE2
	ldi_berp 0xFB, 0
	cp_erpb 0xFB, 0x10
	jrl nc, NoteMap_PopRetFA_StoreAE2

LABEL_FE3247:
	ldto_berp A, 0xFB
	extz wa
	add wa, 0x84
	extz xwa
	add_sril_rm XWA, 0xFD, 0xA8, 0x00
	ld a, (xwa)
	cp_srib_rm A, 0xFD, 0xA6, 0x00
	jr nz, LABEL_FE3272
	lda xwa, (xsp + 2)
	ld xde, xwa
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

LABEL_FE3272:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr c, LABEL_FE3247
	jrl NoteMap_PopRetFA_StoreAE2

LABEL_FE327E:
	ld_sril XWA, (xsp + 0x00a8)
	ld_srib C, (xsp + 0x00a6)
	cp_srib_rm C, 0xE1, 0xB6, 0x00
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
	cp l, 0xFF
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
	jr z, LABEL_FE3362
	ldi_berp 0xFB, 0
	cp_erpb 0xFB, 0x10
	jr nc, LABEL_FE3362

LABEL_FE332E:
	ldto_berp A, 0xFB
	extz wa
	add wa, 0x84
	extz xwa
	add_sril_rm XWA, 0xFD, 0xA8, 0x00
	ld a, (xwa)
	cp_srib_rm A, 0xFD, 0xA6, 0x00
	jr nz, LABEL_FE3359
	lda xwa, (xsp + 2)
	ld xde, xwa
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

LABEL_FE3359:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr c, LABEL_FE332E

LABEL_FE3362:
	ld_srib A, (xsp + 0x00a6)
	extz wa
	add wa, 0x44
	extz xwa
	add_sril_rm XWA, 0xFD, 0xA8, 0x00
	ld a, (xwa)
	ldfr_berp A, 0xFB
	cp a, 0xFF
	jr z, LABEL_FE338E
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld_sril XWA, (xsp + 0x00ac)
	call SeqPart_EmitNoteOnMessages

LABEL_FE338E:
	ld_srib A, (xsp + 0x00a6)
	extz wa
	add wa, 0x64
	extz xwa
	add_sril_rm XWA, 0xFD, 0xA8, 0x00
	ld a, (xwa)
	ldfr_berp A, 0xFB
	cp a, 0xFF
	jr z, NoteMap_PopRetFA_StoreAE2
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld_sril XWA, (xsp + 0x00ac)
	call Voice_EmitMidiNoteOnEvents

NoteMap_PopRetFA_StoreAE2:
	pop_werp 0xFA
	st_dri3b L, 0xFD, 0xAE, 0x00
	ret

NoteMap_UpdateEntry:
	lda xsp, (xsp - 10)
	push_werp 0xFA
	ld (xsp + 2), e
	ld (xsp + 4), xbc
	ld (xsp + 8), xwa
	cp (xsp + 2), 0x15
	jrl nz, LABEL_FE346A
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
	cp l, 0xFF
	jr z, NoteMap_FallbackAllocEmit
	ld xwa, (xsp + 4)
	lds bc, 2
	calr NoteMap_AllocateVoice

NoteMap_FallbackAllocEmit:
	ldda16 xwa, 50584
	bit 9, wa
	jr z, LABEL_FE3454
	ldi_berp 0xFB, 0
	cp_erpb 0xFB, 0x10
	jr nc, LABEL_FE3454

LABEL_FE3428:
	ldto_berp A, 0xFB
	extz wa
	add wa, 0x84
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	cp a, (xsp + 2)
	jr nz, LABEL_FE344B
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call Voice_BuildAndEmitNoteOnEvents

LABEL_FE344B:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr c, LABEL_FE3428

LABEL_FE3454:
	ld xwa, (xsp + 4)
	cp (xwa + 3), 0x0
	jrl nz, NoteMap_CollectBestEmit
	ld xwa, (xsp + 8)
	lds bc, 1
	call NoteMap_EmitNoteOnEvents
	jrl NoteMap_CollectBestEmit

LABEL_FE346A:
	ld xwa, (xsp + 4)
	ld c, (xsp + 2)
	cp_srib_rm C, 0xE1, 0xB6, 0x00
	jr nz, NoteMap_DirectLookupEmit
	ld xwa, (xsp + 8)
	lds bc, 2
	call NoteMap_FindEntry
	ld xwa, (xsp + 8)
	call NoteMap_FindBestFreeVoice
	cps l, 0
	jr nz, NoteMap_DirectLookupEmit
	call VoiceMap_AllocateSlot
	cp l, 0xFF
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
	jr z, LABEL_FE34FE
	ldi_berp 0xFB, 0
	cp_erpb 0xFB, 0x10
	jr nc, LABEL_FE34FE

LABEL_FE34D2:
	ldto_berp A, 0xFB
	extz wa
	add wa, 0x84
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	cp a, (xsp + 2)
	jr nz, LABEL_FE34F5
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call Voice_BuildAndEmitNoteOnEvents

LABEL_FE34F5:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr c, LABEL_FE34D2

LABEL_FE34FE:
	ld a, (xsp + 2)
	extz wa
	add wa, 0x44
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	ldfr_berp A, 0xFB
	cp a, 0xFF
	jr z, LABEL_FE3524
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call SeqPart_EmitNoteOnMessages

LABEL_FE3524:
	ld a, (xsp + 2)
	extz wa
	add wa, 0x64
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	ldfr_berp A, 0xFB
	cp a, 0xFF
	jr z, LABEL_FE354A
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	call Voice_EmitMidiNoteOnEvents

LABEL_FE354A:
	ld xwa, (xsp + 4)
	cp (xwa + 3), 0x0
	jr nz, NoteMap_CollectBestEmit
	ld xwa, (xsp + 8)
	lds bc, 0
	call NoteMap_EmitNoteOnEvents

NoteMap_CollectBestEmit:
	pop_werp 0xFA
	lda xsp, (xsp + 10)
	ret

NoteMap_FindAndAllocBestVoice:
	st_dri3b L, 0xFD, 0x52, 0xFF
	push_werp 0xFA
	lda_dri3 XIY, 0xFD, 0xA6, 0x00
	st_dri3l XBC, 0xFD, 0xA8, 0x00
	st_dri3l XWA, 0xFD, 0xAC, 0x00
	cp_srib_im 0xFD, 0xA6, 0x00, 0x15
	jrl nz, LABEL_FE3627
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
	cp l, 0xFF
	jr z, NoteMap_FindAllocEmit
	ld_sril XWA, (xsp + 0x00a8)
	lds bc, 2
	calr NoteMap_AllocateVoice

NoteMap_FindAllocEmit:
	ldda16 xwa, 50584
	bit 9, wa
	jrl z, NoteMap_PopRetFA_StoreAE3
	ldi_berp 0xFB, 0
	cp_erpb 0xFB, 0x10
	jrl nc, NoteMap_PopRetFA_StoreAE3

LABEL_FE35F0:
	ldto_berp A, 0xFB
	extz wa
	add wa, 0x84
	extz xwa
	add_sril_rm XWA, 0xFD, 0xA8, 0x00
	ld a, (xwa)
	cp_srib_rm A, 0xFD, 0xA6, 0x00
	jr nz, LABEL_FE361B
	lda xwa, (xsp + 2)
	ld xde, xwa
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

LABEL_FE361B:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr c, LABEL_FE35F0
	jrl NoteMap_PopRetFA_StoreAE3

LABEL_FE3627:
	ld_sril XWA, (xsp + 0x00a8)
	ld_srib C, (xsp + 0x00a6)
	cp_srib_rm C, 0xE1, 0xB6, 0x00
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
	cp l, 0xFF
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
	jr z, LABEL_FE370B
	ldi_berp 0xFB, 0
	cp_erpb 0xFB, 0x10
	jr nc, LABEL_FE370B

LABEL_FE36D7:
	ldto_berp A, 0xFB
	extz wa
	add wa, 0x84
	extz xwa
	add_sril_rm XWA, 0xFD, 0xA8, 0x00
	ld a, (xwa)
	cp_srib_rm A, 0xFD, 0xA6, 0x00
	jr nz, LABEL_FE3702
	lda xwa, (xsp + 2)
	ld xde, xwa
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

LABEL_FE3702:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr c, LABEL_FE36D7

LABEL_FE370B:
	ld_srib A, (xsp + 0x00a6)
	extz wa
	add wa, 0x44
	extz xwa
	add_sril_rm XWA, 0xFD, 0xA8, 0x00
	ld a, (xwa)
	ldfr_berp A, 0xFB
	cp a, 0xFF
	jr z, LABEL_FE3737
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld_sril XWA, (xsp + 0x00ac)
	call SeqPart_EmitNoteOnMessages

LABEL_FE3737:
	ld_srib A, (xsp + 0x00a6)
	extz wa
	add wa, 0x64
	extz xwa
	add_sril_rm XWA, 0xFD, 0xA8, 0x00
	ld a, (xwa)
	ldfr_berp A, 0xFB
	cp a, 0xFF
	jr z, NoteMap_PopRetFA_StoreAE3
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld_sril XWA, (xsp + 0x00ac)
	call Voice_EmitMidiNoteOnEvents

NoteMap_PopRetFA_StoreAE3:
	pop_werp 0xFA
	st_dri3b L, 0xFD, 0xAE, 0x00
	ret

LABEL_FE376C:
	dec 6, xsp
	push xiz
	ld (xsp + 4), e
	ld xiz, xbc
	ld (xsp + 6), xwa
	cp (xsp + 4), 0x15
	jr nz, LABEL_FE37DE
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
	jr z, LABEL_FE37A5
	cps l, 3
	jr nz, NoteMap_AllocVoice_Done

LABEL_FE37A5:
	ld xwa, xiz
	lds bc, 0
	calr NoteMap_AllocateVoice
	ld xwa, xiz
	lds bc, 1
	calr NoteMap_AllocateVoice
	cpdi16 52770, 0
	jr z, NoteMap_AllocVoice_Done
	call NoteMap_FindBestMatch
	cp l, 0xFF
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

LABEL_FE37DE:
	ld a, (xsp + 4)
	cp_srib_rm A, 0xF9, 0xB6, 0x00
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
	jr z, LABEL_FE3810
	cps l, 3
	jr nz, LABEL_FE3829

LABEL_FE3810:
	call VoiceMap_AllocateSlot
	cp l, 0xFF
	jr z, NoteMap_AllocVoiceEntry_Continue
	ld xwa, xiz
	lds bc, 2
	calr NoteMap_AssignVoiceParams
	ld xwa, xiz
	lds bc, 2
	calr NoteMap_InitVoiceSlots
	jr NoteMap_AllocVoiceEntry_Continue

LABEL_FE3829:
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
	jr nz, LABEL_FE387E
	ld a, (xsp + 4)
	ld c, a
	extz bc
	ld xwa, (xsp + 6)
	call NoteMap_SetChannelParam

LABEL_FE387E:
	ld xwa, (xsp + 6)
	ld a, (xwa + 3)
	extz wa
	add wa, 0xA4
	extz xwa
	add xwa, xiz
	ld c, (xwa)
	ld a, c
	cp a, 0xFF
	jr z, LABEL_FE38B2
	ld a, (xsp + 4)
	extz wa
	add wa, wa
	add wa, 0x124
	bit_dri 5, 0x07, 0xF8, 0xE0
	jr z, LABEL_FE38B2
	extz bc
	ld xwa, (xsp + 6)
	call Voice_ScanAndEmitMidiEvents

LABEL_FE38B2:
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
	st_dri3b L, 0xFD, 0x52, 0xFF
	lda_dri3 XIY, 0xFD, 0xA4, 0x00
	st_dri3l XBC, 0xFD, 0xA6, 0x00
	st_dri3l XWA, 0xFD, 0xAA, 0x00
	cp_srib_im 0xFD, 0xA4, 0x00, 0x15
	jr nz, LABEL_FE3943
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
	jr z, LABEL_FE390F
	cps l, 3
	jrl nz, NoteMap_StoreAllocResult

LABEL_FE390F:
	ld_sril XWA, (xsp + 0x00a6)
	lds bc, 0
	calr NoteMap_AllocateVoice
	ld_sril XWA, (xsp + 0x00a6)
	lds bc, 1
	calr NoteMap_AllocateVoice
	cpdi16 52770, 0
	jrl z, NoteMap_StoreAllocResult
	call NoteMap_FindBestMatch
	cp l, 0xFF
	jrl z, NoteMap_StoreAllocResult
	ld_sril XWA, (xsp + 0x00a6)
	lds bc, 2
	calr NoteMap_AllocateVoice
	jrl NoteMap_StoreAllocResult

LABEL_FE3943:
	ld_sril XWA, (xsp + 0x00a6)
	ld_srib C, (xsp + 0x00a4)
	cp_srib_rm C, 0xE1, 0xB6, 0x00
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
	jr z, LABEL_FE397E
	cps l, 3
	jr nz, LABEL_FE399D

LABEL_FE397E:
	call VoiceMap_AllocateSlot
	cp l, 0xFF
	jr z, NoteMap_LookupAllocAndStore
	ld_sril XWA, (xsp + 0x00a6)
	lds bc, 2
	calr NoteMap_AssignVoiceParams
	ld_sril XWA, (xsp + 0x00a6)
	lds bc, 2
	calr NoteMap_InitVoiceSlots
	jr NoteMap_LookupAllocAndStore

LABEL_FE399D:
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
	add_sril_rm XWA, 0xFD, 0xA6, 0x00
	ld a, (xwa)
	cp_srib_rm A, 0xFD, 0xA4, 0x00
	jr nz, LABEL_FE3A0E
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x00a4)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LABEL_FE3A0E:
	ld a, (xsp + 3)
	extz wa
	add wa, 0xA4
	extz xwa
	add_sril_rm XWA, 0xFD, 0xA6, 0x00
	ld e, (xwa)
	ld a, e
	cp a, 0xFF
	jr z, NoteMap_StoreAllocResult
	ld_srib A, (xsp + 0x00a4)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld_sril XWA, (xsp + 0x00a6)
	bit_dri 5, 0x07, 0xE0, 0xE4
	jr z, NoteMap_StoreAllocResult
	lda xwa, (xsp)
	ld c, e
	extz bc
	call Voice_ScanAndEmitMidiEvents

NoteMap_StoreAllocResult:
	st_dri3b L, 0xFD, 0xAE, 0x00
	ret

LABEL_FE3A52:
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
	jr nz, LABEL_FE3A98
	ld a, (xsp)
	ld c, a
	extz bc
	ld xwa, (xsp + 6)
	call NoteMap_SetChannelParam

LABEL_FE3A98:
	ld a, (xsp)
	extz wa
	add wa, 0x24
	extz xwa
	add xwa, (xsp + 2)
	ld e, (xwa)
	ld a, e
	cp a, 0xFF
	jr z, LABEL_FE3ACF
	ld a, (xsp)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld xwa, (xsp + 2)
	bit_dri 5, 0x07, 0xE0, 0xE4
	jr z, LABEL_FE3ACF
	ld c, e
	extz bc
	ld xwa, (xsp + 6)
	call Voice_ScanAndEmitMidiEvents

LABEL_FE3ACF:
	lda xsp, (xsp + 10)
	ret

NoteMap_LookupAndAllocVoice:
	st_dri3b L, 0xFD, 0x56, 0xFF
	lda_dri3 XIY, 0xFD, 0xA4, 0x00
	st_dri3l XBC, 0xFD, 0xA6, 0x00
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
	jrl z, LABEL_FE3B82
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
	add_sril_rm XWA, 0xFD, 0xA6, 0x00
	ld a, (xwa)
	cp_srib_rm A, 0xFD, 0xA4, 0x00
	jr nz, LABEL_FE3B40
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x00a4)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LABEL_FE3B40:
	ld_srib A, (xsp + 0x00a4)
	extz wa
	add wa, 0x24
	extz xwa
	add_sril_rm XWA, 0xFD, 0xA6, 0x00
	ld e, (xwa)
	ld a, e
	cp a, 0xFF
	jr z, Voice_SetParam_Return
	ld_srib A, (xsp + 0x00a4)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld_sril XWA, (xsp + 0x00a6)
	bit_dri 5, 0x07, 0xE0, 0xE4
	jr z, Voice_SetParam_Return
	lda xwa, (xsp)
	ld c, e
	extz bc
	call Voice_ScanAndEmitMidiEvents
	jr Voice_SetParam_Return

LABEL_FE3B82:
	ld_srib A, (xsp + 0x00a4)
	extz wa
	inc 4, wa
	extz xwa
	add_sril_rm XWA, 0xFD, 0xA6, 0x00
	ld a, (xwa)
	cp_srib_rm A, 0xFD, 0xA4, 0x00
	jr nz, Voice_SetParam_Return
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x00a4)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

Voice_SetParam_Return:
	st_dri3b L, 0xFD, 0xAA, 0x00
	ret

LABEL_FE3BB4:
	st_dri3b L, 0xFD, 0x56, 0xFF
	lda_dri3 XIY, 0xFD, 0xA4, 0x00
	st_dri3l XBC, 0xFD, 0xA6, 0x00
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
	add_sril_rm XWA, 0xFD, 0xA6, 0x00
	ld a, (xwa)
	cp_srib_rm A, 0xFD, 0xA4, 0x00
	jr nz, LABEL_FE3C35
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x00a4)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LABEL_FE3C35:
	ld_srib A, (xsp + 0x00a4)
	extz wa
	add wa, 0x24
	extz xwa
	add_sril_rm XWA, 0xFD, 0xA6, 0x00
	ld e, (xwa)
	ld a, e
	cp a, 0xFF
	jr z, NoteMap_ProcessNoteOff_Done
	ld_srib A, (xsp + 0x00a4)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld_sril XWA, (xsp + 0x00a6)
	bit_dri 5, 0x07, 0xE0, 0xE4
	jr z, NoteMap_ProcessNoteOff_Done
	lda xwa, (xsp)
	ld c, e
	extz bc
	call Voice_ScanAndEmitMidiEvents

NoteMap_ProcessNoteOff_Done:
	st_dri3b L, 0xFD, 0xAA, 0x00
	ret

LABEL_FE3C7B:
	lda xsp, (xsp - 10)
	ld (xsp), e
	ld (xsp + 2), xbc
	ld (xsp + 6), xwa
	ld xwa, (xsp + 6)
	call LABEL_FE64A3
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
	jr nz, LABEL_FE3CB8
	ld a, (xsp)
	ld c, a
	extz bc
	ld xwa, (xsp + 6)
	call NoteMap_SetChannelParam

LABEL_FE3CB8:
	lda xsp, (xsp + 10)
	ret

NoteMap_LookupAllocAndStoreResult:
	st_dri3b L, 0xFD, 0x56, 0xFF
	lda_dri3 XIY, 0xFD, 0xA4, 0x00
	st_dri3l XBC, 0xFD, 0xA6, 0x00
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
	jr z, LABEL_FE3D24
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
	add_sril_rm XWA, 0xFD, 0xA6, 0x00
	ld a, (xwa)
	cp_srib_rm A, 0xFD, 0xA4, 0x00
	jr nz, LABEL_FE3D24
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x00a4)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LABEL_FE3D24:
	st_dri3b L, 0xFD, 0xAA, 0x00
	ret

NoteMap_InitVoiceSlots:
	st_dri3b L, 0xFD, 0x54, 0xFF
	push xiz
	lda_dri3 XHL, 0xFD, 0xAA, 0x00
	st_dri3l XWA, 0xFD, 0xAC, 0x00
	ld_srib A, (xsp + 0x00aa)
	extz wa
	add wa, 0xBC
	extz xwa
	add_sril_rm XWA, 0xFD, 0xAC, 0x00
	ld a, (xwa)
	ld (xsp + 4), a
	cp a, 0xFF
	jrl z, NoteMap_PopIz_StoreAC
	ld_srib A, (xsp + 0x00aa)
	extz wa
	sla wa, 2
	lda_24 xbc, 0xee8f22
	ld_sril3 XIZ, 0x07, 0xE4, 0xE0
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
	jr nc, LABEL_FE3DED

LABEL_FE3D8D:
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
	jr c, LABEL_FE3D8D

LABEL_FE3DED:
	lda xwa, (xsp + 6)
	ld xbc, xwa
	ld a, (xsp + 4)
	ld e, a
	extz de
	ld xwa, xbc
	ld_sril XBC, (xsp + 0x00ac)
	call LABEL_FE6525
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld a, (xsp + 4)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocNewVoiceEntry
	cpw (xiz + 2), 0x0
	jr nz, LABEL_FE3E30
	ld a, (xsp + 4)
	extz wa
	inc 4, wa
	extz xwa
	add_sril_rm XWA, 0xFD, 0xAC, 0x00
	cp (xwa), 0xFF
	jr z, LABEL_FE3E42

LABEL_FE3E30:
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld a, (xsp + 4)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LABEL_FE3E42:
	cpw (xiz + 2), 0x1
	jr z, NoteMap_PopIz_StoreAC
	ld a, (xsp + 4)
	extz wa
	add wa, 0x24
	extz xwa
	add_sril_rm XWA, 0xFD, 0xAC, 0x00
	ld e, (xwa)
	ld a, e
	cp a, 0xFF
	jr z, NoteMap_PopIz_StoreAC
	ld a, (xsp + 4)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld_sril XWA, (xsp + 0x00ac)
	bit_dri 5, 0x07, 0xE0, 0xE4
	jr z, NoteMap_PopIz_StoreAC
	cp_srib_im 0xFD, 0xAA, 0x00, 0x02
	jr nz, LABEL_FE3E8F
	ld_sril XWA, (xsp + 0x00ac)
	bit_dri 5, 0xE1, 0x56, 0x01
	jr z, NoteMap_PopIz_StoreAC

LABEL_FE3E8F:
	lda xwa, (xsp + 6)
	ld c, e
	extz bc
	call Voice_ScanAndEmitMidiEvents

NoteMap_PopIz_StoreAC:
	pop xiz
	st_dri3b L, 0xFD, 0xAC, 0x00
	ret

; ============================================================================
; NoteMap_AssignVoiceParams - Assign voice parameters for note-on events
; ============================================================================
; Input:  Voice channel parameters
; Output: None
; Iterates voice slots, validates format, looks up voice, assigns params.
; ============================================================================
NoteMap_AssignVoiceParams:
	st_dri3b L, 0xFD, 0x52, 0xFF
	push_werp 0xFA
	lda_dri3 XHL, 0xFD, 0xAA, 0x00
	st_dri3l XWA, 0xFD, 0xAC, 0x00
	ld_srib A, (xsp + 0x00aa)
	extz wa
	add wa, 0xBC
	extz xwa
	add_sril_rm XWA, 0xFD, 0xAC, 0x00
	ld a, (xwa)
	ldfr_berp A, 0xFB
	cp a, 0xFF
	jrl z, NoteMap_PopRetFA_StoreAE4
	ld_srib A, (xsp + 0x00aa)
	extz wa
	sla wa, 2
	lda_24 xbc, 0xee8f22
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld (xsp + 2), xwa
	ld (xsp + 6), 0x90
	ld (xsp + 8), 0x6
	ld_srib A, (xsp + 0x00aa)
	ld (xsp + 9), a
	lda xwa, (xsp + 6)
	ld xde, xwa
	lda xwa, (xsp + 6)
	ld xbc, xwa
	ldto_berp A, 0xFB
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jrl z, NoteMap_PopRetFA_StoreAE4
	lda xwa, (xsp + 6)
	ld xde, xwa
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocNewVoiceEntry
	ld xwa, (xsp + 2)
	cpw (xwa + 2), 0x0
	jr nz, LABEL_FE3F43
	ldto_berp A, 0xFB
	extz wa
	inc 4, wa
	extz xwa
	add_sril_rm XWA, 0xFD, 0xAC, 0x00
	cp (xwa), 0xFF
	jr z, LABEL_FE3F55

LABEL_FE3F43:
	lda xwa, (xsp + 6)
	ld xde, xwa
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LABEL_FE3F55:
	ld xwa, (xsp + 2)
	cpw (xwa + 2), 0x1
	jr z, NoteMap_PopRetFA_StoreAE4
	ldto_berp A, 0xFB
	extz wa
	add wa, 0x24
	extz xwa
	add_sril_rm XWA, 0xFD, 0xAC, 0x00
	ld e, (xwa)
	ld a, e
	cp a, 0xFF
	jr z, NoteMap_PopRetFA_StoreAE4
	ldto_berp A, 0xFB
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld_sril XWA, (xsp + 0x00ac)
	bit_dri 5, 0x07, 0xE0, 0xE4
	jr z, NoteMap_PopRetFA_StoreAE4
	cp_srib_im 0xFD, 0xAA, 0x00, 0x02
	jr nz, LABEL_FE3FA5
	ld_sril XWA, (xsp + 0x00ac)
	bit_dri 5, 0xE1, 0x56, 0x01
	jr z, NoteMap_PopRetFA_StoreAE4

LABEL_FE3FA5:
	lda xwa, (xsp + 6)
	ld c, e
	extz bc
	call Voice_ScanAndEmitMidiEvents

NoteMap_PopRetFA_StoreAE4:
	pop_werp 0xFA
	st_dri3b L, 0xFD, 0xAE, 0x00
	ret

; ============================================================================
; NoteMap_AllocateVoice - Allocate a voice slot for a note
; ============================================================================
; Input:  XWA = note map base pointer
;         BC = voice layer index (0, 1, or 2)
; Output: L = allocated voice number (0xFF if none available)
; Searches the voice table at 0xEE8F22 for an available slot matching the
; requested instrument/channel. Uses a stride of 5 bytes per voice entry.
; Called by NoteMap_AddEntry for each voice layer.
; ============================================================================
NoteMap_AllocateVoice:
	st_dri3b L, 0xFD, 0x54, 0xFF
	push xiz
	lda_dri3 XHL, 0xFD, 0xAA, 0x00
	st_dri3l XWA, 0xFD, 0xAC, 0x00
	ld_srib A, (xsp + 0x00aa)
	extz wa
	add wa, 0xBC
	extz xwa
	add_sril_rm XWA, 0xFD, 0xAC, 0x00
	ld a, (xwa)
	ld (xsp + 4), a
	cp a, 0xFF
	jrl z, NoteMap_PopIz_StoreAC2
	ld_srib A, (xsp + 0x00aa)
	extz wa
	sla wa, 2
	lda_24 xbc, 0xee8f22
	ld_sril3 XIZ, 0x07, 0xE4, 0xE0
	ld wa, (xiz)
	ld (xsp + 7), a
	ld (xsp + 6), 0x90
	ld (xsp + 8), 0x6
	ld_srib A, (xsp + 0x00aa)
	ld (xsp + 9), a
	lds de, 0
	cp de, (xiz)
	jrl nc, LABEL_FE40BD

LABEL_FE4016:
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
	jrl c, LABEL_FE4016

LABEL_FE40BD:
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
	call LABEL_FE6525
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld a, (xsp + 4)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocNewVoiceEntry
	cpw (xiz + 2), 0x0
	jr nz, LABEL_FE411D
	ld a, (xsp + 4)
	extz wa
	inc 4, wa
	extz xwa
	add_sril_rm XWA, 0xFD, 0xAC, 0x00
	cp (xwa), 0xFF
	jr z, LABEL_FE412F

LABEL_FE411D:
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld a, (xsp + 4)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LABEL_FE412F:
	cpw (xiz + 2), 0x1
	jr z, NoteMap_PopIz_StoreAC2
	ld a, (xsp + 4)
	extz wa
	add wa, 0x24
	extz xwa
	add_sril_rm XWA, 0xFD, 0xAC, 0x00
	ld e, (xwa)
	ld a, e
	cp a, 0xFF
	jr z, NoteMap_PopIz_StoreAC2
	ld a, (xsp + 4)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x124
	ld_sril XWA, (xsp + 0x00ac)
	bit_dri 5, 0x07, 0xE0, 0xE4
	jr z, NoteMap_PopIz_StoreAC2
	cp_srib_im 0xFD, 0xAA, 0x00, 0x02
	jr nz, LABEL_FE417C
	ld_sril XWA, (xsp + 0x00ac)
	bit_dri 5, 0xE1, 0x56, 0x01
	jr z, NoteMap_PopIz_StoreAC2

LABEL_FE417C:
	lda xwa, (xsp + 6)
	ld c, e
	extz bc
	call Voice_ScanAndEmitMidiEvents

NoteMap_PopIz_StoreAC2:
	pop xiz
	st_dri3b L, 0xFD, 0xAC, 0x00
	ret

NoteMap_SwapVoiceLinks:
	ld e, c
	extz de
	add de, de
	ld_srib3 E, 0x07, 0xE0, 0xE8
	extz de
	add de, de
	st_dri3b C, 0x07, 0xE0, 0xE8
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
	ld_srib3 C, 0x07, 0xE0, 0xE4
	lda_dri3 XHL, 0x07, 0xE0, 0xE8
	ret

NoteMap_LinkVoiceSlots:
	ld l, c
	extz hl
	add hl, hl
	st_dri3b D, 0x07, 0xE0, 0xEC
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
	lda_dri3 XIY, 0x07, 0xE0, 0xEC
	ld l, e
	extz hl
	add hl, hl
	exts xhl
	add xhl, xwa
	ld l, (xhl + 1)
	extz hl
	add hl, hl
	lda_dri3 XHL, 0x07, 0xE0, 0xEC
	extz de
	add de, de
	st_dri3b W, 0x07, 0xE0, 0xE8
	ld (xwa + 1), c
	ret

LABEL_FE421B:
	ld e, c
	extz de
	add de, de
	st_dri3b W, 0x07, 0xE0, 0xE8
	cp (xwa + 1), c
	jr nz, LABEL_FE422E
	lds hl, 0
	ret

LABEL_FE422E:
	lds hl, 1
	ret

LABEL_FE4231:
	ldada xix, 50634
	ldada xiy, 59368
	ld e, (xwa + 3)
	extz de
	lda_24 xhl, 0xee8eb6
	ld_srib3 E, 0x07, 0xEC, 0xE8
	extz bc
	muls bc, 0x5
	inc 4, bc
	ld_srib3 C, 0x07, 0xE0, 0xE4
	ld a, e
	extz wa
	add wa, wa
	exts xwa
	add xwa, xiy
	ld l, (xwa + 1)
	cp l, e
	ret z

LABEL_FE4266:
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
	jr nz, LABEL_FE4266
	ret

LABEL_FE4289:
	ldada xhl, 50634
	ldada xix, 59368
	ldb c, 0x20
	cp (xwa + 3), 0x2
	jrl nc, LABEL_FE4337
	ld c, (xwa + 3)
	extz bc
	lda_24 xde, 0xee8eb6
	ld_srib3 C, 0x07, 0xE8, 0xE4
	ldfr_berp C, 0xEA
	lds de, 0
	ldto_berp C, 0xEA
	extz bc
	add bc, bc
	ld_srib3 C, 0x07, 0xF0, 0xE4
	ldfr_berp C, 0xEB
	cp_berp C, 0xEA
	jr z, LABEL_FE4331

LABEL_FE42C2:
	ld bc, de
	extz xbc
	ld xiy, xbc
	sll xiy, 2
	add xiy, xbc
	inc 4, xiy
	add xiy, xwa
	ldto_berp C, 0xEB
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
	ldto_berp C, 0xEB
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
	ldto_berp C, 0xEB
	extz bc
	add bc, bc
	ld_srib3 C, 0x07, 0xF0, 0xE4
	ldfr_berp C, 0xEB
	inc 1, de
	ldto_berp C, 0xEB
	cp_berp C, 0xEA
	jr nz, LABEL_FE42C2

LABEL_FE4331:
	ld l, e
	ld (xwa + 1), l
	ret

LABEL_FE4337:
	ld (xwa + 1), 0x0
	ldb l, 0x0
	ret

Voice_LookupTableEntries:
	ldada xhl, 50634
	ldada xix, 59368
	ldb c, 0x20
	cp (xwa + 3), 0x2
	jrl nc, LABEL_FE43DD
	ld c, (xwa + 3)
	extz bc
	lda_24 xde, 0xee8eb6
	ld_srib3 C, 0x07, 0xE8, 0xE4
	ldfr_berp C, 0xEA
	lds de, 0
	ldto_berp C, 0xEA
	extz bc
	add bc, bc
	ld_srib3 C, 0x07, 0xF0, 0xE4
	ldfr_berp C, 0xEB
	cp_berp C, 0xEA
	jr z, LABEL_FE43D7

LABEL_FE4377:
	ld bc, de
	extz xbc
	ld xiy, xbc
	sll xiy, 2
	add xiy, xbc
	inc 4, xiy
	add xiy, xwa
	ldto_berp C, 0xEB
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
	ldto_berp C, 0xEB
	extz bc
	add bc, bc
	ld_srib3 C, 0x07, 0xF0, 0xE4
	ldfr_berp C, 0xEB
	inc 1, de
	ldto_berp C, 0xEB
	cp_berp C, 0xEA
	jr nz, LABEL_FE4377

LABEL_FE43D7:
	ld l, e
	ld (xwa + 1), l
	ret

LABEL_FE43DD:
	ld (xwa + 1), 0x0
	ldb l, 0x0
	ret

LABEL_FE43E4:
	push xiz
	ld l, c
	extz hl
	muls hl, 0xD
	lda_24 xix, 0xee8f2e
	ld_sril3 XIX, 0x07, 0xF0, 0xEC
	ld l, c
	extz hl
	muls hl, 0xD
	lda_24 xiy, 0xee8f32
	ld_sril3 XIY, 0x07, 0xF4, 0xEC
	extz bc
	muls bc, 0xD
	lda_24 xhl, 0xee8f36
	extz de
	ld_sril3 XBC, 0x07, 0xEC, 0xE4
	ld_srib3 E, 0x07, 0xE4, 0xE8
	ld c, e
	extz bc
	add bc, bc
	exts xbc
	add xbc, xiy
	ld l, (xbc + 1)
	cp l, e
	jr z, LABEL_FE448A

LABEL_FE4431:
	ld c, l
	extz bc
	sla bc, 3
	st_dri3b H, 0x07, 0xF0, 0xE4
	ld c, (xsp + 8)
	extz bc
	muls bc, 0x5
	inc 4, bc
	ld_srib3 C, 0x07, 0xE0, 0xE4
	cp c, (xiz + 2)
	jr nz, LABEL_FE4479
	ld c, l
	extz bc
	sla bc, 3
	st_dri3b H, 0x07, 0xF0, 0xE4
	ld c, (xwa + 3)
	cp c, (xiz + 1)
	jr nz, LABEL_FE4479
	ld c, l
	extz bc
	ld iz, bc
	sla iz, 3
	ld c, (xwa + 2)
	cp_srib_rm C, 0x07, 0xF0, 0xF8
	jr z, LABEL_FE448A

LABEL_FE4479:
	ld c, l
	extz bc
	add bc, bc
	exts xbc
	add xbc, xiy
	ld l, (xbc + 1)
	cp l, e
	jr nz, LABEL_FE4431

LABEL_FE448A:
	pop xiz
	retd 0x2

NoteMap_ClaimVoiceSlot:
	dec 4, xsp
	push xiz
	ld l, e
	ld xde, xbc
	cps l, 4
	jr ugt, LABEL_FE449F
	cp (xsp + 12), 0x20
	jr ule, LABEL_FE44A8

LABEL_FE449F:
	ld (xwa + 1), 0x0
	ldb l, 0x0
	jrl LABEL_FE4720

LABEL_FE44A8:
	ld c, l
	extz bc
	muls bc, 0xD
	ld ix, bc
	lda_24 xiy, 0xee8f36
	ld c, (xsp + 12)
	ldfr_berp C, 0xF8
	extz iz
	ld_sril3 XBC, 0x07, 0xF4, 0xF0
	ld_srib3 B, 0x07, 0xE4, 0xF8
	ldfr_berp L, 0xF0
	extz ix
	muls ix, 0xD
	lda_24 xiy, 0xee8f2e
	ld_sril3 XIX, 0x07, 0xF4, 0xF0
	extz hl
	muls hl, 0xD
	lda_24 xiy, 0xee8f32
	ld_sril3 XHL, 0x07, 0xF4, 0xEC
	ld (xsp + 4), xhl
	cp (xde + 3), 0xFF
	jrl nz, LABEL_FE45F6
	lds hl, 0
	ld c, b
	ldfr_berp C, 0xF4
	extz iy
	ld iz, iy
	add iz, iz
	ld xiy, (xsp + 4)
	ld_srib3 C, 0x07, 0xF4, 0xF8
	ldfr_berp C, 0xE6
	cp c, b
	jrl z, NoteMap_StoreEntryAndReturn

LABEL_FE4513:
	ldto_berp C, 0xE6
	ldfr_berp C, 0xF4
	extz iy
	sla iy, 3
	ld c, (xde + 2)
	cp_srib_rm C, 0x07, 0xF0, 0xF4
	jrl nz, LABEL_FE45D7
	cp hl, 0x20
	jrl nc, NoteMap_StoreEntryAndReturn
	ld iy, hl
	extz xiy
	ld xiz, xiy
	sll xiz, 2
	add xiz, xiy
	inc 4, xiz
	add xiz, xwa
	ldto_berp C, 0xE6
	ldfr_berp C, 0xF4
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
	ldto_berp C, 0xE6
	ldfr_berp C, 0xF4
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
	ldto_berp C, 0xE6
	ldfr_berp C, 0xF4
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
	ldto_berp C, 0xE6
	ldfr_berp C, 0xF4
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

LABEL_FE45D7:
	ldto_berp C, 0xE6
	ldfr_berp C, 0xF4
	extz iy
	ld iz, iy
	add iz, iz
	ld xiy, (xsp + 4)
	ld_srib3 C, 0x07, 0xF4, 0xF8
	ldfr_berp C, 0xE6
	cp c, b
	jrl nz, LABEL_FE4513
	jrl NoteMap_StoreEntryAndReturn

LABEL_FE45F6:
	lds hl, 0
	ld c, b
	ldfr_berp C, 0xF4
	extz iy
	ld iz, iy
	add iz, iz
	ld xiy, (xsp + 4)
	ld_srib3 C, 0x07, 0xF4, 0xF8
	ldfr_berp C, 0xE6
	cp c, b
	jrl z, NoteMap_StoreEntryAndReturn

LABEL_FE4613:
	ldto_berp C, 0xE6
	ldfr_berp C, 0xF4
	extz iy
	sla iy, 3
	ld c, (xde + 2)
	cp_srib_rm C, 0x07, 0xF0, 0xF4
	jrl nz, LABEL_FE46EF
	ldto_berp C, 0xE6
	ldfr_berp C, 0xF4
	extz iy
	sla iy, 3
	exts xiy
	add xiy, xix
	ld c, (xde + 3)
	cp c, (xiy + 1)
	jrl nz, LABEL_FE46EF
	cp hl, 0x20
	jrl nc, NoteMap_StoreEntryAndReturn
	ld iy, hl
	extz xiy
	ld xiz, xiy
	sll xiz, 2
	add xiz, xiy
	inc 4, xiz
	add xiz, xwa
	ldto_berp C, 0xE6
	ldfr_berp C, 0xF4
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
	ldto_berp C, 0xE6
	ldfr_berp C, 0xF4
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
	ldto_berp C, 0xE6
	ldfr_berp C, 0xF4
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
	ldto_berp C, 0xE6
	ldfr_berp C, 0xF4
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

LABEL_FE46EF:
	ldto_berp C, 0xE6
	ldfr_berp C, 0xF4
	extz iy
	ld iz, iy
	add iz, iz
	ld xiy, (xsp + 4)
	ld_srib3 C, 0x07, 0xF4, 0xF8
	ldfr_berp C, 0xE6
	cp c, b
	jrl nz, LABEL_FE4613

NoteMap_StoreEntryAndReturn:
	ld c, l
	ld (xwa + 1), c
	ld c, (xde)
	ld (xwa), c
	ld c, (xde + 2)
	ld (xwa + 2), c
	ld c, (xde + 3)
	ld (xwa + 3), c

LABEL_FE4720:
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
; Looks up voice tables at 0xEE8F2E-0xEE8F36, cross-referencing channel,
; instrument, and layer to find the matching voice assignment.
; Uses stride of 0xD (13) bytes per voice entry.
; ============================================================================
NoteMap_LookupVoice:
	dec 4, xsp
	push xiz
	ld xix, xbc
	cps e, 4
	jr ugt, LABEL_FE4735
	cp (xsp + 12), 0x20
	jr ule, LABEL_FE473E

LABEL_FE4735:
	ld (xwa + 1), 0x0
	ldb l, 0x0
	jrl LABEL_FE495C

LABEL_FE473E:
	ld c, e
	extz bc
	muls bc, 0xD
	ld hl, bc
	lda_24 xiy, 0xee8f36
	ld c, (xsp + 12)
	ldfr_berp C, 0xF8
	extz iz
	ld_sril3 XBC, 0x07, 0xF4, 0xEC
	ld_srib3 D, 0x07, 0xE4, 0xF8
	ld c, e
	extz bc
	muls bc, 0xD
	lda_24 xhl, 0xee8f2e
	ld_sril3 XIY, 0x07, 0xEC, 0xE4
	ld c, e
	extz bc
	muls bc, 0xD
	lda_24 xhl, 0xee8f32
	ld_sril3 XBC, 0x07, 0xEC, 0xE4
	ld (xsp + 4), xbc
	cp (xix + 3), 0xFF
	jrl nz, LABEL_FE4861
	lds hl, 0
	ld c, d
	extz bc
	ld iz, bc
	add iz, iz
	ld xbc, (xsp + 4)
	ld_srib3 E, 0x07, 0xE4, 0xF8
	cp e, d
	jrl z, NoteMap_StoreResultAndReturn

LABEL_FE47A4:
	ld c, e
	extz bc
	ld iz, bc
	sla iz, 3
	ld c, (xix + 2)
	cp_srib_rm C, 0x07, 0xF4, 0xF8
	jrl nz, LABEL_FE4849
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

LABEL_FE4849:
	ld c, e
	extz bc
	ld iz, bc
	add iz, iz
	ld xbc, (xsp + 4)
	ld_srib3 E, 0x07, 0xE4, 0xF8
	cp e, d
	jrl nz, LABEL_FE47A4
	jrl NoteMap_StoreResultAndReturn

LABEL_FE4861:
	lds hl, 0
	ld c, d
	extz bc
	ld iz, bc
	add iz, iz
	ld xbc, (xsp + 4)
	ld_srib3 E, 0x07, 0xE4, 0xF8
	cp e, d
	jrl z, NoteMap_StoreResultAndReturn

LABEL_FE4878:
	ld c, e
	extz bc
	ld iz, bc
	sla iz, 3
	ld c, (xix + 2)
	cp_srib_rm C, 0x07, 0xF4, 0xF8
	jrl nz, LABEL_FE4932
	ld c, e
	extz bc
	sla bc, 3
	st_dri3b H, 0x07, 0xF4, 0xE4
	ld c, (xix + 3)
	cp c, (xiz + 1)
	jrl nz, LABEL_FE4932
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

LABEL_FE4932:
	ld c, e
	extz bc
	ld iz, bc
	add iz, iz
	ld xbc, (xsp + 4)
	ld_srib3 E, 0x07, 0xE4, 0xF8
	cp e, d
	jrl nz, LABEL_FE4878

NoteMap_StoreResultAndReturn:
	ld c, l
	ld (xwa + 1), c
	ld c, (xix)
	ld (xwa), c
	ld c, (xix + 2)
	ld (xwa + 2), c
	ld c, (xix + 3)
	ld (xwa + 3), c

LABEL_FE495C:
	pop xiz
	inc 4, xsp
	retd 0x2

NoteMap_CollectMatchingEntries:
	st_dri3b L, 0xFD, 0x4E, 0xFF
	pushw iz
	ld l, e
	st_dri3l XBC, 0xFD, 0xAC, 0x00
	st_dri3l XWA, 0xFD, 0xB0, 0x00
	cps l, 4
	jr ugt, LABEL_FE4980
	cp_srib_im 0xFD, 0xB8, 0x00, 0x20
	jr ule, LABEL_FE498E

LABEL_FE4980:
	ld_sril XWA, (xsp + 0x00b0)
	ld (xwa + 1), 0x0
	ldb l, 0x0
	jrl LABEL_FE4C04

LABEL_FE498E:
	ld a, l
	extz wa
	muls wa, 0xD
	ld bc, wa
	lda_24 xde, 0xee8f36
	ld_srib A, (xsp + 0x00b8)
	ldfr_berp A, 0xF0
	extz ix
	ld_sril3 XWA, 0x07, 0xE8, 0xE4
	ld_srib3 A, 0x07, 0xE0, 0xF0
	ld (xsp + 2), a
	ld a, l
	extz wa
	muls wa, 0xD
	lda_24 xbc, 0xee8f2e
	ld_sril3 XDE, 0x07, 0xE4, 0xE0
	ld a, l
	extz wa
	muls wa, 0xD
	lda_24 xbc, 0xee8f32
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld (xsp + 4), xwa
	lds hl, 0
	lds iz, 0
	jrl LABEL_FE4A99

LABEL_FE49E2:
	ld a, (xsp + 2)
	ld c, a

NoteMap_EmitNoteData_Process:
	ld a, c
	extz wa
	ld bc, wa
	add bc, bc
	ld xwa, (xsp + 4)
	st_dri3b W, 0x07, 0xE0, 0xE4
	ld a, (xwa + 1)
	ld c, a
	cp a, (xsp + 2)
	jr nz, LABEL_FE4A31
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
	add_sril_rm XIY, 0xFD, 0xAC, 0x00
	lds bc, 2
	ldirw
	ldi85
	inc 1, hl
	jr LABEL_FE4A97

LABEL_FE4A31:
	ld a, c
	extz wa
	sla wa, 3
	st_dri3b E, 0x07, 0xE8, 0xE0
	ld wa, iz
	extz xwa
	ld xix, xwa
	sll xix, 2
	add xix, xwa
	inc 4, xix
	add_sril_rm XIX, 0xFD, 0xAC, 0x00
	ld a, (xix)
	cp a, (xiy + 2)
	jr nz, NoteMap_EmitNoteData_Process
	ld a, c
	extz wa
	sla wa, 3
	st_dri3b D, 0x07, 0xE8, 0xE0
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
	cp_srib_rm A, 0x07, 0xE8, 0xF0
	jrl nz, NoteMap_EmitNoteData_Process
	ld a, c
	extz wa
	sla wa, 3
	exts xwa
	add xwa, xde
	setm 0, (xwa + 7)

LABEL_FE4A97:
	inc 1, iz

LABEL_FE4A99:
	ld_sril XWA, (xsp + 0x00ac)
	ld a, (xwa + 1)
	extz wa
	cp iz, wa
	jrl c, LABEL_FE49E2
	ld (xsp + 9), l
	ld c, (xsp + 2)
	lds hl, 0
	jrl LABEL_FE4B74

LABEL_FE4AB3:
	ld a, c
	extz wa
	sla wa, 3
	exts xwa
	add xwa, xde
	bitm 0, (xwa + 7)
	jrl nz, LABEL_FE4B66
	cp iz, 0x20
	jrl nc, LABEL_FE4B8F
	ld wa, hl
	extz xwa
	ld xix, xwa
	sll xix, 2
	add xix, xwa
	inc 4, xix
	add_sril_rm XIX, 0xFD, 0xB0, 0x00
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
	add_sril_rm XIX, 0xFD, 0xB0, 0x00
	ld (xix + 1), 0x0
	ld wa, hl
	extz xwa
	ld xix, xwa
	sll xix, 2
	add xix, xwa
	inc 4, xix
	add_sril_rm XIX, 0xFD, 0xB0, 0x00
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
	add_sril_rm XIX, 0xFD, 0xB0, 0x00
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
	add_sril_rm XIX, 0xFD, 0xB0, 0x00
	ld (xix + 4), 0x0
	inc 1, hl
	jr LABEL_FE4B74

LABEL_FE4B66:
	ld a, c
	extz wa
	sla wa, 3
	exts xwa
	add xwa, xde
	resm 0, (xwa + 7)

LABEL_FE4B74:
	ld a, c
	extz wa
	ld bc, wa
	add bc, bc
	ld xwa, (xsp + 4)
	st_dri3b W, 0x07, 0xE0, 0xE4
	ld a, (xwa + 1)
	ld c, a
	cp a, (xsp + 2)
	jrl nz, LABEL_FE4AB3

LABEL_FE4B8F:
	lds iz, 0
	jr LABEL_FE4BC3

LABEL_FE4B93:
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
	add_sril_rm XIX, 0xFD, 0xB0, 0x00
	lds bc, 2
	ldirw
	ldi85
	inc 1, iz
	inc 1, hl

LABEL_FE4BC3:
	ld a, (xsp + 9)
	extz wa
	cp iz, wa
	jr c, LABEL_FE4B93
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

LABEL_FE4C04:
	popw iz
	st_dri3b L, 0xFD, 0xB2, 0x00
	retd 0x2

NoteMap_AllocNewVoiceEntry:
	lda xsp, (xsp - 14)
	push_werp 0xFA
	ld (xsp + 10), c
	ld (xsp + 12), xwa
	ldada xwa, 59438
	ld (xsp + 6), xwa
	cp (xsp + 10), 0x20
	jrl ugt, LABEL_FE4EF2
	ld a, (xsp + 10)
	extz wa
	lda_24 xbc, 0xee8eb8
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ld (xsp + 4), a
	ldw (xsp + 2), 0x0
	jrl LABEL_FE4EE4

LABEL_FE4C41:
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
	jrl z, LABEL_FE4DFC
	ldda8 a, 59695
	ldfr_berp A, 0xFB
	cp a, 0x80
	jrl z, LABEL_FE4DE5
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
	ld_srib3 A, 0x07, 0xF0, 0xEC
	cp_srib_rm A, 0x07, 0xE8, 0xE4
	jrl ule, LABEL_FE4DE5
	ld a, (xsp + 10)
	extz wa
	add wa, wa
	ldada xbc, 50731
	inc_srib 1, 0x07, 0xE4, 0xE0
	ldto_berp A, 0xFB
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
	lda_dri3 XBC, 0x07, 0xEC, 0xE8
	ldto_berp A, 0xFB
	extz wa
	ld bc, wa
	sla bc, 3
	ldada xde, 50794
	ld xwa, (xsp + 12)
	ld a, (xwa + 2)
	lda_dri3 XBC, 0x07, 0xE8, 0xE4
	ldto_berp A, 0xFB
	extz wa
	ld bc, wa
	sla bc, 3
	ldada xde, 50795
	ld xwa, (xsp + 12)
	ld a, (xwa + 3)
	lda_dri3 XBC, 0x07, 0xE8, 0xE4
	ldto_berp A, 0xFB
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
	lda_dri3 XBC, 0x07, 0xEC, 0xE8
	ldto_berp A, 0xFB
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
	lda_dri3 XBC, 0x07, 0xEC, 0xE8
	ldto_berp A, 0xFB
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
	lda_dri3 XBC, 0x07, 0xEC, 0xE8
	ldto_berp A, 0xFB
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
	lda_dri3 XBC, 0x07, 0xEC, 0xE8
	ldto_berp A, 0xFB
	extz wa
	ld bc, wa
	sla bc, 3
	ldada xde, 50798
	ld a, (xsp + 10)
	lda_dri3 XBC, 0x07, 0xE8, 0xE4
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, (xsp + 6)
	calr NoteMap_SwapVoiceLinks
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld a, (xsp + 4)
	ld e, a
	extz de
	ld xwa, (xsp + 6)
	calr NoteMap_LinkVoiceSlots
	jrl NoteMap_SlotLoop_Continue

LABEL_FE4DE5:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	setm 1, (xbc + 4)
	jrl NoteMap_SlotLoop_Continue

LABEL_FE4DFC:
	ld a, (xsp + 10)
	ld c, a
	extz bc
	ld wa, (xsp + 2)
	extz wa
	pushw wa
	ld xwa, (xsp + 14)
	ld de, bc
	lds bc, 0
	calr LABEL_FE43E4
	ldfr_berp L, 0xFB
	ldto_berp A, 0xFB
	cp a, (xsp + 4)
	jrl z, LABEL_FE4ECD
	ld a, (xsp + 10)
	extz wa
	add wa, wa
	ldada xbc, 50731
	dec_srib 1, 0x07, 0xE4, 0xE0
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	ld xde, xbc
	add xde, (xsp + 12)
	ldto_berp A, 0xFB
	extz wa
	sla wa, 3
	ldada xbc, 50799
	ld_srib3 A, 0x07, 0xE4, 0xE0
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
	ldto_berp A, 0xFB
	extz wa
	sla wa, 3
	ldada xbc, 50800
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ld (xde + 3), a
	ldada xde, 59438
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, xde
	calr NoteMap_SwapVoiceLinks
	ldada xde, 59438
	ldto_berp A, 0xFB
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
	calr LABEL_FE421B
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

LABEL_FE4ECD:
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

LABEL_FE4EE4:
	ld xwa, (xsp + 12)
	ld a, (xwa + 1)
	extz wa
	cp (xsp + 2), wa
	jrl c, LABEL_FE4C41

LABEL_FE4EF2:
	pop_werp 0xFA
	lda xsp, (xsp + 14)
	ret

; ============================================================================
; NoteMap_SetChannelParam - Set a MIDI channel parameter in the note map
; ============================================================================
; Input:  C = MIDI channel number
;         XWA = pointer to parameter data (command byte at offset 0)
; Output: None
; Dispatches MIDI channel messages: handles control change (0xA0=all notes off),
; program change, pitch bend, and other channel voice messages. Reads channel
; configuration from voice table at 0xEE8EB8.
; ============================================================================
NoteMap_SetChannelParam:
	lda xsp, (xsp - 28)
	pushw iz
	ld (xsp + 24), c
	ld (xsp + 26), xwa
	ld a, (xsp + 24)
	extz wa
	lda_24 xbc, 0xee8eb8
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ld a, (xsp + 24)
	extz wa
	calr LABEL_FE66A2
	ld (xsp + 24), l
	ld xwa, (xsp + 26)
	cp (xwa), 0xA0
	jr nz, LABEL_FE4F49
	ld (xsp + 4), 0x4
	ld (xsp + 5), 0xB0
	ld a, (xsp + 24)
	ld (xsp + 6), a
	ld (xsp + 7), 0x78
	ld (xsp + 8), 0x0
	lda xwa, (xsp + 4)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	jrl LABEL_FE50CA

LABEL_FE4F49:
	ld xwa, (xsp + 26)
	cp (xwa + 2), 0x6
	jr nz, LABEL_FE4FA7
	ld xwa, (xsp + 26)
	ld a, (xwa + 3)
	cps a, 2
	jr z, LABEL_FE4F8D
	cps a, 1
	jr z, LABEL_FE4F79
	cps a, 0
	jr nz, LABEL_FE4FA1
	ldda16 xwa, 52993
	extz xwa
	ld xbc, 0xEE8F70
	add xbc, xwa
	ld a, (xbc)
	ld (xsp + 2), a
	jrl Voice_EmitMidiNoteAndBankEvents

LABEL_FE4F79:
	ldda16 xwa, 53041
	extz xwa
	ld xbc, 0xEE8F70
	add xbc, xwa
	ld a, (xbc)
	ld (xsp + 2), a
	jr Voice_EmitMidiNoteAndBankEvents

LABEL_FE4F8D:
	ldda16 xwa, 52772
	extz xwa
	ld xbc, 0xEE8F70
	add xbc, xwa
	ld a, (xbc)
	ld (xsp + 2), a
	jr Voice_EmitMidiNoteAndBankEvents

LABEL_FE4FA1:
	ld (xsp + 2), 0x0
	jr Voice_EmitMidiNoteAndBankEvents

LABEL_FE4FA7:
	ld xwa, (xsp + 26)
	cp (xwa + 2), 0x4
	jr nz, LABEL_FE4FE8
	ld xwa, (xsp + 26)
	bitm 3, (xwa)
	jr z, LABEL_FE4FD1
	ld xwa, (xsp + 26)
	ld a, (xwa + 2)
	extz wa
	lda_24 xbc, 0xee8f70
	ld_srib3 A, 0x07, 0xE4, 0xE0
	set 3, a
	ld (xsp + 2), a
	jr Voice_EmitMidiNoteAndBankEvents

LABEL_FE4FD1:
	ld xwa, (xsp + 26)
	ld a, (xwa + 2)
	extz wa
	lda_24 xbc, 0xee8f70
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ld (xsp + 2), a
	jr Voice_EmitMidiNoteAndBankEvents

LABEL_FE4FE8:
	ld xwa, (xsp + 26)
	ld a, (xwa + 2)
	extz wa
	lda_24 xbc, 0xee8f70
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ld (xsp + 2), a

Voice_EmitMidiNoteAndBankEvents:
	lds iz, 0
	jrl LABEL_FE50B6

LABEL_FE5002:
	ld wa, iz
	muls wa, 0x5
	ld bc, wa
	inc 4, bc
	ld xwa, (xsp + 26)
	st_dri3b W, 0x07, 0xE0, 0xE4
	bitm 1, (xwa + 4)
	jrl nz, MIDI_SendVoiceData_Increment
	ld wa, iz
	muls wa, 0x5
	ld bc, wa
	inc 4, bc
	ld xwa, (xsp + 26)
	st_dri3b W, 0x07, 0xE0, 0xE4
	cp (xwa + 2), 0xFF
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
	st_dri3b W, 0x07, 0xE0, 0xE4
	ld a, (xwa + 2)
	res 7, a
	ld (xsp + 7), a
	ld wa, iz
	muls wa, 0x5
	ld bc, wa
	inc 4, bc
	ld xwa, (xsp + 26)
	st_dri3b W, 0x07, 0xE0, 0xE4
	ld a, (xwa + 1)
	ld (xsp + 8), a
	lda xwa, (xsp + 4)
	call MIDI_SendCmdPacket
	ld wa, iz
	muls wa, 0x5
	ld bc, wa
	inc 4, bc
	ld xwa, (xsp + 26)
	st_dri3b W, 0x07, 0xE0, 0xE4
	bitm 7, (xwa + 2)
	jr z, MIDI_SendVoiceData_Increment
	ld (xsp + 4), 0x4
	ld (xsp + 5), 0xB0
	ld a, (xsp + 24)
	ld (xsp + 6), a
	ld (xsp + 7), 0x7B
	ld (xsp + 8), 0x0
	lda xwa, (xsp + 4)
	call MIDI_SendCmdPacket

MIDI_SendVoiceData_Increment:
	inc 1, iz

LABEL_FE50B6:
	ld xwa, (xsp + 26)
	ld a, (xwa + 1)
	extz wa
	cp iz, wa
	jrl lt, LABEL_FE5002
	cps iz, 0
	call_24 gt, 0xFEBF79

LABEL_FE50CA:
	popw iz
	lda xsp, (xsp + 28)
	ret

Voice_ScanAndEmitMidiEvents:
	dec 6, xsp
	push xiz
	ld (xsp + 4), c
	ld (xsp + 6), xwa
	lds iz, 0
	ldi_werp 0xFA, 0
	jrl LABEL_FE51F5

LABEL_FE50E0:
	ldto_werp WA, 0xFA
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	bitm 1, (xbc + 4)
	jrl nz, MIDI_SysExParse_CheckLength
	ldto_werp WA, 0xFA
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	cp (xbc + 3), 0xFF
	jrl z, MIDI_SysExParse_CheckLength
	ld a, (xsp + 4)
	or a, 0x90
	extz wa
	call FileData_ValidateFormat
	cps hl, 0
	jr ge, LABEL_FE5180
	ld wa, iz
	extz xwa
	ld xbc, 0xCCC2
	add xbc, xwa
	ld a, (xsp + 4)
	or a, 0x90
	ld (xbc), a
	ld wa, iz
	extz xwa
	inc 1, xwa
	ld xbc, 0xCCC2
	ld xde, xbc
	add xde, xwa
	ldto_werp WA, 0xFA
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
	ld xbc, 0xCCC2
	ld xde, xbc
	add xde, xwa
	ldto_werp WA, 0xFA
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

LABEL_FE5180:
	ld wa, iz
	extz xwa
	ld xbc, 0xCCC2
	ld xde, xbc
	add xde, xwa
	ldto_werp WA, 0xFA
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
	ld xbc, 0xCCC2
	ld xde, xbc
	add xde, xwa
	ldto_werp WA, 0xFA
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
	jr z, LABEL_FE51F2
	cp iz, 0xF
	jr ugt, LABEL_FE51E3
	ld xwa, (xsp + 6)
	ld a, (xwa + 1)
	dec 1, a
	extz wa
	cp_werp WA, 0xFA
	jr nz, LABEL_FE51F2

LABEL_FE51E3:
	ld xwa, 0xCCC2
	push xwa
	pushw iz
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	lds iz, 0

LABEL_FE51F2:
	inc1_werp 0xFA

LABEL_FE51F5:
	ld xwa, (xsp + 6)
	ld a, (xwa + 1)
	ld c, a
	extz bc
	ldto_werp WA, 0xFA
	cp wa, bc
	jrl c, LABEL_FE50E0
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
	ldmi16 (xsp + 2), 0x41B
	ei 0
	lds bc, 0
	lds iz, 0
	jrl LABEL_FE5322

LABEL_FE5228:
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	inc 4, xde
	add xde, (xsp + 6)
	bitm 1, (xde + 4)
	jrl nz, LABEL_FE52F5
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	inc 4, xde
	add xde, (xsp + 6)
	cp (xde + 2), 0xFF
	jrl z, LABEL_FE52F5
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
	ld_srib3 A, 0x07, 0xE8, 0xE0
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

LABEL_FE52F5:
	cps bc, 0
	jr z, LABEL_FE5320
	cps bc, 6
	jr z, LABEL_FE530B
	ld xwa, (xsp + 6)
	ld a, (xwa + 1)
	dec 1, a
	extz wa
	cp wa, iz
	jr nz, LABEL_FE5320

LABEL_FE530B:
	ld xwa, 0xCCD4
	push xwa
	ld wa, bc
	mul wa, 0x5
	pushw wa
	call TempoRingBuf_WriteBytes
	inc 6, xsp
	lds bc, 0

LABEL_FE5320:
	inc 1, iz

LABEL_FE5322:
	ld xwa, (xsp + 6)
	ld a, (xwa + 1)
	extz wa
	cp iz, wa
	jrl c, LABEL_FE5228
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
	jrl LABEL_FE543C

LABEL_FE5358:
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	inc 4, xde
	add xde, (xsp + 6)
	bitm 1, (xde + 4)
	jrl nz, LABEL_FE540F
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	inc 4, xde
	add xde, (xsp + 6)
	cp (xde + 2), 0xFF
	jrl z, LABEL_FE540F
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

LABEL_FE540F:
	cps bc, 0
	jr z, LABEL_FE543A
	cps bc, 6
	jr z, LABEL_FE5425
	ld xwa, (xsp + 6)
	ld a, (xwa + 1)
	dec 1, a
	extz wa
	cp wa, iz
	jr nz, LABEL_FE543A

LABEL_FE5425:
	ld xwa, 0xCCF2
	push xwa
	ld wa, bc
	mul wa, 0x5
	pushw wa
	call TempoRingBuf_WriteBytes
	inc 6, xsp
	lds bc, 0

LABEL_FE543A:
	inc 1, iz

LABEL_FE543C:
	ld xwa, (xsp + 6)
	ld a, (xwa + 1)
	extz wa
	cp iz, wa
	jrl c, LABEL_FE5358
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
	ldmi16 (xsp + 2), 0x46A
	ei 0
	lds bc, 0
	lds iz, 0
	jrl LABEL_FE5552

LABEL_FE546E:
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	inc 4, xde
	add xde, (xsp + 6)
	bitm 1, (xde + 4)
	jrl nz, LABEL_FE5525
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	inc 4, xde
	add xde, (xsp + 6)
	cp (xde + 2), 0xFF
	jrl z, LABEL_FE5525
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

LABEL_FE5525:
	cps bc, 0
	jr z, LABEL_FE5550
	cps bc, 6
	jr z, LABEL_FE553B
	ld xwa, (xsp + 6)
	ld a, (xwa + 1)
	dec 1, a
	extz wa
	cp wa, iz
	jr nz, LABEL_FE5550

LABEL_FE553B:
	ld xwa, 0xCD10
	push xwa
	ld wa, bc
	mul wa, 0x5
	pushw wa
	call TempoRingBuf_WriteBytes
	inc 6, xsp
	lds bc, 0

LABEL_FE5550:
	inc 1, iz

LABEL_FE5552:
	ld xwa, (xsp + 6)
	ld a, (xwa + 1)
	extz wa
	cp iz, wa
	jrl c, LABEL_FE546E
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
; Output: L = entry index (0xFF if not found)
; Searches the note map for an entry matching the given criteria. Uses a
; stride of 5 bytes per entry. Checks active flags (bit 1 at offset 4)
; and matches against channel assignment data at 0xEE8ED8.
; ============================================================================
NoteMap_FindEntry:
	lda xsp, (xsp - 14)
	push_werp 0xFA
	ld (xsp + 10), c
	ld (xsp + 12), xwa
	ld a, (xsp + 10)
	extz wa
	lda_24 xbc, 0xee8ed8
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ld (xsp + 4), a
	ldada xwa, 59760
	ld (xsp + 6), xwa
	ldw (xsp + 2), 0x0
	jrl LABEL_FE580F

LABEL_FE5594:
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
	jrl z, LABEL_FE574F
	ldda8 a, 59825
	ldfr_berp A, 0xFB
	cp a, 0x20
	jrl z, LABEL_FE5738
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
	ld_srib3 A, 0x07, 0xF0, 0xEC
	cp_srib_rm A, 0x07, 0xE8, 0xE4
	jrl ule, LABEL_FE5738
	ld a, (xsp + 10)
	extz wa
	add wa, wa
	ldada xbc, 51819
	inc_srib 1, 0x07, 0xE4, 0xE0
	ldto_berp A, 0xFB
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
	lda_dri3 XBC, 0x07, 0xEC, 0xE8
	ldto_berp A, 0xFB
	extz wa
	ld bc, wa
	sla bc, 3
	ldada xde, 51834
	ld xwa, (xsp + 12)
	ld a, (xwa + 2)
	lda_dri3 XBC, 0x07, 0xE8, 0xE4
	ldto_berp A, 0xFB
	extz wa
	ld bc, wa
	sla bc, 3
	ldada xde, 51835
	ld xwa, (xsp + 12)
	ld a, (xwa + 3)
	lda_dri3 XBC, 0x07, 0xE8, 0xE4
	ldto_berp A, 0xFB
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
	lda_dri3 XBC, 0x07, 0xEC, 0xE8
	ldto_berp A, 0xFB
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
	lda_dri3 XBC, 0x07, 0xEC, 0xE8
	ldto_berp A, 0xFB
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
	lda_dri3 XBC, 0x07, 0xEC, 0xE8
	ldto_berp A, 0xFB
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
	lda_dri3 XBC, 0x07, 0xEC, 0xE8
	ldto_berp A, 0xFB
	extz wa
	ld bc, wa
	sla bc, 3
	ldada xde, 51838
	ld a, (xsp + 10)
	lda_dri3 XBC, 0x07, 0xE8, 0xE4
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, (xsp + 6)
	calr NoteMap_SwapVoiceLinks
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld a, (xsp + 4)
	ld e, a
	extz de
	ld xwa, (xsp + 6)
	calr NoteMap_LinkVoiceSlots
	jrl Voice_LoopAdvance_Next

LABEL_FE5738:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 12)
	setm 1, (xbc + 4)
	jrl Voice_LoopAdvance_Next

LABEL_FE574F:
	ld a, (xsp + 10)
	ld c, a
	extz bc
	ld wa, (xsp + 2)
	extz wa
	pushw wa
	ld xwa, (xsp + 14)
	ld de, bc
	lds bc, 4
	calr LABEL_FE43E4
	ldfr_berp L, 0xFB
	ldto_berp A, 0xFB
	cp a, (xsp + 4)
	jrl z, LABEL_FE57F8
	ld a, (xsp + 10)
	extz wa
	add wa, wa
	ldada xbc, 51819
	dec_srib 1, 0x07, 0xE4, 0xE0
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	ld xde, xbc
	add xde, (xsp + 12)
	ldto_berp A, 0xFB
	extz wa
	sla wa, 3
	ldada xbc, 51839
	ld_srib3 A, 0x07, 0xE4, 0xE0
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
	ldto_berp A, 0xFB
	extz wa
	sla wa, 3
	ldada xbc, 51840
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ld (xde + 3), a
	ldada xde, 59760
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, xde
	calr NoteMap_SwapVoiceLinks
	ldada xde, 59760
	ldto_berp A, 0xFB
	ld c, a
	extz bc
	ld xwa, xde
	ldw de, 0x20
	calr NoteMap_LinkVoiceSlots
	jr Voice_LoopAdvance_Next

LABEL_FE57F8:
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

LABEL_FE580F:
	ld xwa, (xsp + 12)
	ld a, (xwa + 1)
	extz wa
	cp (xsp + 2), wa
	jrl c, LABEL_FE5594
	pop_werp 0xFA
	lda xsp, (xsp + 14)
	ret

NoteMap_FindBestVoiceSlot:
	lds hl, 0
	ldb d, 0x21
	ldb e, 0xFF
	ldb d, 0x21
	jr NoteMap_FindEntry_AdvanceSlotD

LABEL_FE582E:
	ld c, d
	extz bc
	sla bc, 3
	ldada xix, 51834
	ld_srib3 C, 0x07, 0xF0, 0xE4
	cps c, 0
	jr z, LABEL_FE5866
	cps c, 1
	jr z, LABEL_FE585A
	cps c, 2
	jr z, LABEL_FE5852
	cps c, 3
	jr nz, LABEL_FE5876
	ldb e, 0x3
	jr NoteMap_FindEntry_AdvanceSlotD

LABEL_FE5852:
	cps e, 3
	jr z, NoteMap_FindEntry_AdvanceSlotD
	ldb e, 0x2
	jr NoteMap_FindEntry_AdvanceSlotD

LABEL_FE585A:
	cps e, 3
	jr z, NoteMap_FindEntry_AdvanceSlotD
	cps e, 2
	jr z, NoteMap_FindEntry_AdvanceSlotD
	ldb e, 0x1
	jr NoteMap_FindEntry_AdvanceSlotD

LABEL_FE5866:
	cps e, 3
	jr z, NoteMap_FindEntry_AdvanceSlotD
	cps e, 2
	jr z, NoteMap_FindEntry_AdvanceSlotD
	cps e, 1
	jr z, NoteMap_FindEntry_AdvanceSlotD
	ldb e, 0x0
	jr NoteMap_FindEntry_AdvanceSlotD

LABEL_FE5876:
	ldb e, 0x0

NoteMap_FindEntry_AdvanceSlotD:
	ld c, d
	extz bc
	add bc, bc
	ldada xix, 59761
	ld_srib3 D, 0x07, 0xF0, 0xE4
	ld c, d
	cp c, 0x21
	jr nz, LABEL_FE582E
	cp e, 0xFF
	jr z, LABEL_FE5908
	ldb d, 0x21
	jr LABEL_FE58F0

LABEL_FE5897:
	ld a, d
	extz wa
	sla wa, 3
	ldada xbc, 51834
	cp_srib_mr E, 0x07, 0xE4, 0xE0
	jr nz, LABEL_FE58F0
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
	ld_srib3 A, 0x07, 0xE4, 0xE0
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
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ld (xix), a
	inc 1, hl

LABEL_FE58F0:
	ld a, d
	extz wa
	add wa, wa
	ldada xbc, 59761
	ld_srib3 D, 0x07, 0xE4, 0xE0
	ld a, d
	cp a, 0x21
	jr nz, LABEL_FE5897
	jr LABEL_FE590B

LABEL_FE5908:
	ld e, (xwa + 2)

LABEL_FE590B:
	stda16 52991, xhl
	ld a, e
	extz wa
	stda16 52993, xwa
	ldada xwa, 52991
	push xwa
	call LABEL_FEA688
	inc 4, xsp
	call AccWrap_AutoPlayZoneTrack
	jp LABEL_FE946B

NoteMap_MarkEntriesAboveThreshold:
	dec 6, xsp
	push xiz
	ld (xsp + 6), xwa
	ldw (xsp + 4), 0x0
	jrl LABEL_FE5A2E

LABEL_FE5938:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 6)
	cp (xbc), 0x53
	jrl ule, LABEL_FE5A2B
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
	jr z, LABEL_FE59CA
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
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ldfr_berp A, 0xFA
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
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ldfr_berp A, 0xF9
	jr LABEL_FE59D0

LABEL_FE59CA:
	ldi_berp 0xFA, 0
	ldi_berp 0xF9, 0

LABEL_FE59D0:
	ldto_berp A, 0xFA
	xorda8 a, 52526
	ld e, a
	ldto_berp A, 0xF9
	xorda8 a, 52527
	ldfr_berp A, 0xFB
	cps e, 0
	jr z, LABEL_FE59FF
	ldto_berp A, 0xFA
	ld c, a
	extz bc
	ld a, e
	extz wa
	pushw wa
	ld de, bc
	ldw wa, 0xA8
	ldw bc, 0xB
	call AddswbWr

LABEL_FE59FF:
	cpi_berp 0xFB, 0
	jr z, LABEL_FE5A1D
	ldto_berp A, 0xF9
	ld c, a
	extz bc
	ldto_berp A, 0xFB
	extz wa
	pushw wa
	ld de, bc
	ldw wa, 0xA8
	ldw bc, 0xC
	call AddswbWr

LABEL_FE5A1D:
	ldto_berp A, 0xFA
	stda8 52526, a
	ldto_berp A, 0xF9
	stda8 52527, a

LABEL_FE5A2B:
	incm 1, (xsp + 4)

LABEL_FE5A2E:
	ld xwa, (xsp + 6)
	ld a, (xwa + 1)
	extz wa
	cp (xsp + 4), wa
	jrl c, LABEL_FE5938
	pop xiz
	inc 6, xsp
	ret

NoteMap_FindBestFreeVoice:
	lds de, 0
	ldb h, 0x23
	ldb l, 0xFF
	jr NoteMap_FindBestFreeVoice_AdvanceSlotH

LABEL_FE5A48:
	ld c, h
	extz bc
	sla bc, 3
	ldada xix, 51834
	ld_srib3 C, 0x07, 0xF0, 0xE4
	cps c, 0
	jr z, LABEL_FE5A80
	cps c, 1
	jr z, LABEL_FE5A74
	cps c, 2
	jr z, LABEL_FE5A6C
	cps c, 3
	jr nz, NoteMap_FindBestFreeVoice_AdvanceSlotH
	ldb l, 0x2
	jr NoteMap_FindBestFreeVoice_AdvanceSlotH

LABEL_FE5A6C:
	cps l, 3
	jr z, NoteMap_FindBestFreeVoice_AdvanceSlotH
	ldb l, 0x2
	jr NoteMap_FindBestFreeVoice_AdvanceSlotH

LABEL_FE5A74:
	cps l, 3
	jr z, NoteMap_FindBestFreeVoice_AdvanceSlotH
	cps l, 2
	jr z, NoteMap_FindBestFreeVoice_AdvanceSlotH
	ldb l, 0x1
	jr NoteMap_FindBestFreeVoice_AdvanceSlotH

LABEL_FE5A80:
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
	ld_srib3 H, 0x07, 0xF0, 0xE4
	ld c, h
	cp c, 0x23
	jr nz, LABEL_FE5A48
	cp l, 0xFF
	jr z, LABEL_FE5B1E
	ldb h, 0x23
	jr LABEL_FE5B06

LABEL_FE5AAD:
	ld a, h
	extz wa
	sla wa, 3
	ldada xbc, 51834
	cp_srib_mr L, 0x07, 0xE4, 0xE0
	jr nz, LABEL_FE5B06
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
	ld_srib3 A, 0x07, 0xE4, 0xE0
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
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ld (xix), a
	inc 1, de

LABEL_FE5B06:
	ld a, h
	extz wa
	add wa, wa
	ldada xbc, 59761
	ld_srib3 H, 0x07, 0xE4, 0xE0
	ld a, h
	cp a, 0x23
	jr nz, LABEL_FE5AAD
	jr LABEL_FE5B21

LABEL_FE5B1E:
	ld l, (xwa + 2)

LABEL_FE5B21:
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
	cp (xsp + 2), 0xFF
	jrl z, LABEL_FE5C28
	lds bc, 0
	lds iz, 0
	jrl LABEL_FE5C1B

LABEL_FE5B45:
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
	cp (xde + 2), 0xFF
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
	jr z, LABEL_FE5C19
	cps bc, 6
	jr z, LABEL_FE5C04
	ld xwa, (xsp + 4)
	ld a, (xwa + 1)
	dec 1, a
	extz wa
	cp wa, iz
	jr nz, LABEL_FE5C19

LABEL_FE5C04:
	ld xwa, 0xCD30
	push xwa
	ld wa, bc
	mul wa, 0x3
	pushw wa
	call AltEvtBuf_WriteBytes
	inc 6, xsp
	lds bc, 0

LABEL_FE5C19:
	inc 1, iz

LABEL_FE5C1B:
	ld xwa, (xsp + 4)
	ld a, (xwa + 1)
	extz wa
	cp iz, wa
	jrl c, LABEL_FE5B45

LABEL_FE5C28:
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
	jr LABEL_FE5CAB

LABEL_FE5C4C:
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
	jr ugt, LABEL_FE5CA9
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
	jr ugt, LABEL_FE5CA9
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

LABEL_FE5CA9:
	inc 1, hl

LABEL_FE5CAB:
	ld c, (xde + 1)
	extz bc
	cp hl, bc
	jr c, LABEL_FE5C4C
	ld l, a
	ld (xiz + 1), l
	pop xiz
	inc 4, xsp
	ret

NoteMap_ResetEntryTimers:
	lda xsp, (xsp - 20)
	push_werp 0xFA
	ld (xsp + 16), e
	ld (xsp + 18), xwa
	cpdi8 36150, 152
	jr nz, LABEL_FE5D2D
	ldw (xsp + 2), 0x0
	jr LABEL_FE5D1D

LABEL_FE5CD7:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 18)
	cp (xbc + 1), 0x0
	jr z, LABEL_FE5D1A
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

LABEL_FE5D1A:
	incm 1, (xsp + 2)

LABEL_FE5D1D:
	ld xwa, (xsp + 18)
	ld a, (xwa + 1)
	extz wa
	cp (xsp + 2), wa
	jr c, LABEL_FE5CD7
	jrl LABEL_FE5FBA

LABEL_FE5D2D:
	cp (xsp + 16), 0x13
	jr nz, LABEL_FE5D81
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
	ld_srib3 A, 0x07, 0xE4, 0xE0
	sll a, 4
	sra a, 5
	muls a, 0xC
	ld (xsp + 6), a
	add (xsp + 6), e
	ld a, (xsp + 16)
	extz wa
	add wa, wa
	add wa, 0xE4
	st_dri3b A, 0x07, 0xE4, 0xE0
	ldb a, 0xF4
	add a, (xbc + 1)
	ld (xsp + 4), a
	jr LABEL_FE5DCA

LABEL_FE5D81:
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
	ld_srib3 A, 0x07, 0xE4, 0xE0
	sll a, 4
	sra a, 5
	muls a, 0xC
	ld (xsp + 6), a
	add (xsp + 6), e
	ld a, (xsp + 16)
	extz wa
	add wa, wa
	add wa, 0xE4
	exts xwa
	add xwa, xbc
	ld a, (xwa + 1)
	ld (xsp + 4), a

LABEL_FE5DCA:
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
	jr z, LABEL_FE5E10
	cps hl, 1
	jr z, LABEL_FE5E08
	cps hl, 0
	jr nz, Synth_WriteChannelMod_Loop
	ld (xsp + 10), 0x1
	ldb a, 0x2
	jr Synth_WriteChannelMod_Loop

LABEL_FE5E08:
	ld (xsp + 10), 0xFF
	ldb a, 0xFF
	jr Synth_WriteChannelMod_Loop

LABEL_FE5E10:
	ld (xsp + 10), 0x3
	ldb a, 0x4

Synth_WriteChannelMod_Loop:
	ldw (xsp + 2), 0x0
	jrl LABEL_FE5FAC

LABEL_FE5E1E:
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
	jrl z, LABEL_FE5FA9
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 18)
	ld a, (xbc)
	ldfr_berp A, 0xFB
	ld wa, (xsp + 12)
	ld e, a
	extz de
	ld wa, (xsp + 14)
	ld c, a
	extz bc
	ld wa, de
	calr Note_CheckTransposeRange
	cps l, 0
	jr nz, LABEL_FE5EBC
	cp (xsp + 4), 0x0
	jr z, SndParam_ApplyChannelEntry
	ldto_berp A, 0xFB
	add a, (xsp + 4)
	ldfr_berp A, 0xFB
	cp a, 0x7F
	jr ule, SndParam_ApplyChannelEntry
	cp (xsp + 6), 0x0
	jr le, LABEL_FE5EA8
	ldto_berp A, 0xFB
	cp a, 0x7F
	jr ule, SndParam_ApplyChannelEntry

LABEL_FE5E9A:
	sub_erpb 0xFB, 0x0C
	ldto_berp A, 0xFB
	cp a, 0x7F
	jr ugt, LABEL_FE5E9A
	jr SndParam_ApplyChannelEntry

LABEL_FE5EA8:
	ldto_berp A, 0xFB
	cps a, 0
	jr ge, SndParam_ApplyChannelEntry

LABEL_FE5EAF:
	add_erpb 0xFB, 0x0C
	ldto_berp A, 0xFB
	cps a, 0
	jr lt, LABEL_FE5EAF
	jr SndParam_ApplyChannelEntry

LABEL_FE5EBC:
	cp (xsp + 8), 0xFF
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
	ldto_berp A, 0xFB
	extz wa
	pushw wa
	ld wa, hl
	call SndParam_LookupByChannel
	ldfr_berp L, 0xFB

SndParam_ApplyChannelEntry:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 18)
	ldto_berp A, 0xFB
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
	jr nz, LABEL_FE5F62
	cp (xsp + 6), 0x0
	jr z, LABEL_FE5F56
	ldto_berp A, 0xFB
	add a, (xsp + 6)
	ldfr_berp A, 0xFB
	cp a, 0x7F
	jr ule, LABEL_FE5F56
	cp (xsp + 6), 0x0
	jr le, LABEL_FE5F44
	ldto_berp A, 0xFB
	cp a, 0x7F
	jr ule, LABEL_FE5F56

LABEL_FE5F36:
	sub_erpb 0xFB, 0x0C
	ldto_berp A, 0xFB
	cp a, 0x7F
	jr ugt, LABEL_FE5F36
	jr LABEL_FE5F56

LABEL_FE5F44:
	ldto_berp A, 0xFB
	cps a, 0
	jr ge, LABEL_FE5F56

LABEL_FE5F4B:
	add_erpb 0xFB, 0x0C
	ldto_berp A, 0xFB
	cps a, 0
	jr lt, LABEL_FE5F4B

LABEL_FE5F56:
	cp_erpb 0xFB, 0x78
	jr c, SndParam_StoreChannelResult
	ldi_erpb 0xFB, 0xFF
	jr SndParam_StoreChannelResult

LABEL_FE5F62:
	cp (xsp + 10), 0xFF
	jr z, SndParam_StoreChannelResult
	cp_erpb 0xFB, 0xFF
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
	ldto_berp A, 0xFB
	extz wa
	pushw wa
	ld wa, hl
	call SndParam_LookupByChannel
	ldfr_berp L, 0xFB

SndParam_StoreChannelResult:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 18)
	ldto_berp A, 0xFB
	ld (xbc + 3), a

LABEL_FE5FA9:
	incm 1, (xsp + 2)

LABEL_FE5FAC:
	ld xwa, (xsp + 18)
	ld a, (xwa + 1)
	extz wa
	cp (xsp + 2), wa
	jrl c, LABEL_FE5E1E

LABEL_FE5FBA:
	pop_werp 0xFA
	lda xsp, (xsp + 20)
	ret

Voice_ApplyTransposeWithEncode:
	lda xsp, (xsp - 18)
	push_werp 0xFA
	ld (xsp + 14), e
	ld (xsp + 16), xwa
	ld a, (xsp + 14)
	extz wa
	add wa, wa
	add wa, 0x124
	ld_srib3 A, 0x07, 0xE4, 0xE0
	sll a, 4
	sra a, 5
	muls a, 0xC
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
	jr z, LABEL_FE6033
	cps hl, 1
	jr z, LABEL_FE6029
	cps hl, 0
	jr nz, Synth_WriteChannelDelay_Loop
	ld (xsp + 8), 0x1
	ld (xsp + 6), 0x2
	jr Synth_WriteChannelDelay_Loop

LABEL_FE6029:
	ld (xsp + 8), 0xFF
	ld (xsp + 6), 0xFF
	jr Synth_WriteChannelDelay_Loop

LABEL_FE6033:
	ld (xsp + 8), 0x3
	ld (xsp + 6), 0x4

Synth_WriteChannelDelay_Loop:
	ldw (xsp + 2), 0x0
	jrl LABEL_FE613A

LABEL_FE6043:
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
	jrl z, LABEL_FE6137
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 16)
	ld a, (xbc)
	ldfr_berp A, 0xFB
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 16)
	ldto_berp A, 0xFB
	ld (xbc + 3), a
	cp (xsp + 4), 0x0
	jr z, LABEL_FE60DF
	ldto_berp A, 0xFB
	add a, (xsp + 4)
	ldfr_berp A, 0xFB
	cp a, 0x7F
	jr ule, LABEL_FE60DF
	cp (xsp + 4), 0x0
	jr le, LABEL_FE60CD
	ldto_berp A, 0xFB
	cp a, 0x7F
	jr ule, LABEL_FE60DF

LABEL_FE60BF:
	sub_erpb 0xFB, 0x0C
	ldto_berp A, 0xFB
	cp a, 0x7F
	jr ugt, LABEL_FE60BF
	jr LABEL_FE60DF

LABEL_FE60CD:
	ldto_berp A, 0xFB
	cps a, 0
	jr ge, LABEL_FE60DF

LABEL_FE60D4:
	add_erpb 0xFB, 0x0C
	ldto_berp A, 0xFB
	cps a, 0
	jr lt, LABEL_FE60D4

LABEL_FE60DF:
	ld wa, (xsp + 10)
	ld e, a
	extz de
	ld wa, (xsp + 12)
	ld c, a
	extz bc
	ld wa, de
	calr Note_CheckTransposeRange
	cps l, 0
	jr z, LABEL_FE6120
	cp (xsp + 8), 0xFF
	jr z, LABEL_FE6120
	ld a, (xsp + 6)
	ld l, a
	extz hl
	ld wa, (xsp + 10)
	ld c, a
	extz bc
	ld wa, (xsp + 12)
	ld e, a
	extz de
	ldto_berp A, 0xFB
	extz wa
	pushw wa
	ld wa, hl
	call SndParam_LookupByChannel
	ldfr_berp L, 0xFB

LABEL_FE6120:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 16)
	ldto_berp A, 0xFB
	ld (xbc + 2), a

LABEL_FE6137:
	incm 1, (xsp + 2)

LABEL_FE613A:
	ld xwa, (xsp + 16)
	ld a, (xwa + 1)
	extz wa
	cp (xsp + 2), wa
	jrl c, LABEL_FE6043
	pop_werp 0xFA
	lda xsp, (xsp + 18)
	ret

SndParam_ComputeVoiceTuning:
	lda xsp, (xsp - 16)
	push_werp 0xFA
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
	ld_srib3 A, 0x07, 0xE4, 0xE0
	sll a, 4
	sra a, 5
	muls a, 0xC
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
	jr z, LABEL_FE61D3
	cps hl, 1
	jr z, LABEL_FE61CB
	cps hl, 0
	jr nz, Synth_WriteChannelGain_Loop
	ld (xsp + 6), 0x1
	ldb a, 0x2
	jr Synth_WriteChannelGain_Loop

LABEL_FE61CB:
	ld (xsp + 6), 0xFF
	ldb a, 0xFF
	jr Synth_WriteChannelGain_Loop

LABEL_FE61D3:
	ld (xsp + 6), 0x3
	ldb a, 0x4

Synth_WriteChannelGain_Loop:
	ldw (xsp + 2), 0x0
	jrl LABEL_FE62E4

LABEL_FE61E1:
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
	jrl z, LABEL_FE62E1
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 14)
	ld a, (xbc)
	ldfr_berp A, 0xFB
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 14)
	ldto_berp A, 0xFB
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
	jr nz, LABEL_FE62A0
	cp (xsp + 4), 0x0
	jr z, LABEL_FE6294
	ldto_berp A, 0xFB
	add a, (xsp + 4)
	ldfr_berp A, 0xFB
	cp a, 0x7F
	jr ule, LABEL_FE6294
	cp (xsp + 4), 0x0
	jr le, LABEL_FE6282
	ldto_berp A, 0xFB
	cp a, 0x7F
	jr ule, LABEL_FE6294

LABEL_FE6274:
	sub_erpb 0xFB, 0x0C
	ldto_berp A, 0xFB
	cp a, 0x7F
	jr ugt, LABEL_FE6274
	jr LABEL_FE6294

LABEL_FE6282:
	ldto_berp A, 0xFB
	cps a, 0
	jr ge, LABEL_FE6294

LABEL_FE6289:
	add_erpb 0xFB, 0x0C
	ldto_berp A, 0xFB
	cps a, 0
	jr lt, LABEL_FE6289

LABEL_FE6294:
	cp_erpb 0xFB, 0x78
	jr c, Synth_WriteChannelParam
	ldi_erpb 0xFB, 0xFF
	jr Synth_WriteChannelParam

LABEL_FE62A0:
	cp (xsp + 6), 0xFF
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
	ldto_berp A, 0xFB
	extz wa
	pushw wa
	ld wa, hl
	call SndParam_LookupByChannel
	ldfr_berp L, 0xFB

Synth_WriteChannelParam:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 14)
	ldto_berp A, 0xFB
	ld (xbc + 3), a

LABEL_FE62E1:
	incm 1, (xsp + 2)

LABEL_FE62E4:
	ld xwa, (xsp + 14)
	ld a, (xwa + 1)
	extz wa
	cp (xsp + 2), wa
	jrl c, LABEL_FE61E1
	pop_werp 0xFA
	lda xsp, (xsp + 16)
	ret

NoteMap_ComputePitchOffset:
	lda xsp, (xsp - 16)
	push_werp 0xFA
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
	ld_srib3 A, 0x07, 0xE4, 0xE0
	sll a, 4
	sra a, 5
	muls a, 0xC
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
	jr z, LABEL_FE637D
	cps hl, 1
	jr z, LABEL_FE6375
	cps hl, 0
	jr nz, Synth_InitChannelState_Loop
	ld (xsp + 6), 0x1
	ldb a, 0x2
	jr Synth_InitChannelState_Loop

LABEL_FE6375:
	ld (xsp + 6), 0xFF
	ldb a, 0xFF
	jr Synth_InitChannelState_Loop

LABEL_FE637D:
	ld (xsp + 6), 0x3
	ldb a, 0x4

Synth_InitChannelState_Loop:
	ldw (xsp + 2), 0x0
	jrl LABEL_FE648E

LABEL_FE638B:
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
	jrl z, LABEL_FE648B
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 14)
	ld a, (xbc)
	ldfr_berp A, 0xFB
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 14)
	ldto_berp A, 0xFB
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
	jr nz, LABEL_FE644A
	cp (xsp + 4), 0x0
	jr z, LABEL_FE643E
	ldto_berp A, 0xFB
	add a, (xsp + 4)
	ldfr_berp A, 0xFB
	cp a, 0x7F
	jr ule, LABEL_FE643E
	cp (xsp + 4), 0x0
	jr le, LABEL_FE642C
	ldto_berp A, 0xFB
	cp a, 0x7F
	jr ule, LABEL_FE643E

LABEL_FE641E:
	sub_erpb 0xFB, 0x0C
	ldto_berp A, 0xFB
	cp a, 0x7F
	jr ugt, LABEL_FE641E
	jr LABEL_FE643E

LABEL_FE642C:
	ldto_berp A, 0xFB
	cps a, 0
	jr ge, LABEL_FE643E

LABEL_FE6433:
	add_erpb 0xFB, 0x0C
	ldto_berp A, 0xFB
	cps a, 0
	jr lt, LABEL_FE6433

LABEL_FE643E:
	cp_erpb 0xFB, 0x78
	jr c, Synth_SetChannelTone_Continue
	ldi_erpb 0xFB, 0xFF
	jr Synth_SetChannelTone_Continue

LABEL_FE644A:
	cp (xsp + 6), 0xFF
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
	ldto_berp A, 0xFB
	extz wa
	pushw wa
	ld wa, hl
	call SndParam_LookupByChannel
	ldfr_berp L, 0xFB

Synth_SetChannelTone_Continue:
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	add xbc, (xsp + 14)
	ldto_berp A, 0xFB
	ld (xbc + 3), a

LABEL_FE648B:
	incm 1, (xsp + 2)

LABEL_FE648E:
	ld xwa, (xsp + 14)
	ld a, (xwa + 1)
	extz wa
	cp (xsp + 2), wa
	jrl c, LABEL_FE638B
	pop_werp 0xFA
	lda xsp, (xsp + 16)
	ret

LABEL_FE64A3:
	lds hl, 0
	jr LABEL_FE651B

LABEL_FE64A7:
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
	jr z, LABEL_FE6519
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

LABEL_FE6519:
	inc 1, hl

LABEL_FE651B:
	ld c, (xwa + 1)
	extz bc
	cp hl, bc
	jr c, LABEL_FE64A7
	ret

LABEL_FE6525:
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
	ld_srib3 C, 0x07, 0xE4, 0xE8
	sll c, 4
	sra c, 5
	muls c, 0xC
	ld l, c
	add l, h
	lds ix, 0
	jrl LABEL_FE65F1

LABEL_FE6558:
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
	jr z, LABEL_FE65EF
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
	jr z, LABEL_FE65D6
	add h, l
	ld c, h
	cp c, 0x7F
	jr ule, LABEL_FE65D6
	cps l, 0
	jr le, LABEL_FE65C7
	ld c, h
	cp c, 0x7F
	jr ule, LABEL_FE65D6

LABEL_FE65BB:
	sub h, 0xC
	ld c, h
	cp c, 0x7F
	jr ugt, LABEL_FE65BB
	jr LABEL_FE65D6

LABEL_FE65C7:
	ld c, h
	cps c, 0
	jr ge, LABEL_FE65D6

LABEL_FE65CD:
	add h, 0xC
	ld c, h
	cps c, 0
	jr lt, LABEL_FE65CD

LABEL_FE65D6:
	cp h, 0x78
	jr c, LABEL_FE65DD
	ldb h, 0xFF

LABEL_FE65DD:
	ld bc, ix
	extz xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	inc 4, xde
	add xde, xwa
	ld (xde + 3), h

LABEL_FE65EF:
	inc 1, ix

LABEL_FE65F1:
	ld c, (xwa + 1)
	extz bc
	cp ix, bc
	jrl c, LABEL_FE6558
	ret

SndParam_UpdateChannelTuning:
	cp a, 0xFF
	jr z, LABEL_FE6622
	extz wa
	lda_24 xhl, 0xee8eb8
	ldmm_srib 0x07, 0xEC, 0xE0, 0x44, 0xCD
	ldda8 a, 52548
	extz wa
	add wa, wa
	ldada xhl, 59438
	ldmm_srib 0x07, 0xEC, 0xE0, 0x42, 0xCD

LABEL_FE6622:
	ldda8 a, 52546
	cpda8 a, 52548
	jr z, LABEL_FE669F
	ldda8 a, 52546
	extz wa
	sla wa, 3
	ldada xhl, 50794
	cp_srib_mr C, 0x07, 0xEC, 0xE0
	jr nz, LABEL_FE669F
	cps e, 2
	jr z, LABEL_FE6674
	cps e, 1
	jr z, LABEL_FE6660
	cps e, 0
	jr nz, LABEL_FE6688
	ldda8 a, 52546
	extz wa
	sla wa, 3
	ldada xbc, 50796
	ld_srib3 L, 0x07, 0xE4, 0xE0
	jr Synth_SelectTone_Continue

LABEL_FE6660:
	ldda8 a, 52546
	extz wa
	sla wa, 3
	ldada xbc, 50799
	ld_srib3 L, 0x07, 0xE4, 0xE0
	jr Synth_SelectTone_Continue

LABEL_FE6674:
	ldda8 a, 52546
	extz wa
	sla wa, 3
	ldada xbc, 50800
	ld_srib3 L, 0x07, 0xE4, 0xE0
	jr Synth_SelectTone_Continue

LABEL_FE6688:
	ldb l, 0xFF

Synth_SelectTone_Continue:
	ldda8 a, 52546
	extz wa
	add wa, wa
	ldada xbc, 59438
	ldmm_srib 0x07, 0xE4, 0xE0, 0x42, 0xCD
	jr LABEL_FE66A1

LABEL_FE669F:
	ldb l, 0xFF

LABEL_FE66A1:
	ret

LABEL_FE66A2:
	dec 6, xsp
	cpdi8 36150, 246
	jr nz, LABEL_FE66D2
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
	add a, 0xF0

LABEL_FE66D2:
	ld l, a
	inc 6, xsp
	ret

LABEL_FE66D7:
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
	ld xwa, 0xC0
	call SndParam_LookupReadOnly
	cps hl, 1
	jr nz, LABEL_FE671B
	cp (xsp), 0x78
	jr nz, LABEL_FE6717
	ldb l, 0x1
	jr UI_CheckControlCode_TestResult

LABEL_FE6717:
	ldb l, 0x0
	jr UI_CheckControlCode_TestResult

LABEL_FE671B:
	ld a, (xsp + 2)
	and a, 0xF0
	cp a, 0xF0
	jr nz, LABEL_FE672A
	ldb l, 0x1
	jr UI_CheckControlCode_TestResult

LABEL_FE672A:
	ldb l, 0x0

UI_CheckControlCode_TestResult:
	inc 4, xsp
	ret

LABEL_FE672F:
	st_dri3b L, 0xFD, 0x0E, 0xFE
	push_werp 0xFA
	lda_dri3 XIY, 0xFD, 0xEE, 0x01
	lda_dri3 XHL, 0xFD, 0xF0, 0x01
	lda_dri3 XBC, 0xFD, 0xF2, 0x01
	stib_dri 0xFD, 0x4C, 0x01, 0x00
	stib_dri 0xFD, 0x4D, 0x01, 0x00
	st_dri3b W, 0xFD, 0x4A, 0x01
	call LABEL_FE4289
	cps l, 0
	jrl z, NoteMap_VoiceAssign_Finalize
	st_dri3b E, 0xFD, 0x4A, 0x01
	st_dri3b D, 0xFD, 0xA6, 0x00
	ldw bc, 0x52
	ldirw
	lds de, 0
	jr LABEL_FE678C

LABEL_FE6773:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	st_dri3b W, 0xFD, 0xA7, 0x00
	add xwa, xbc
	ld (xwa), 0x0
	inc 1, de

LABEL_FE678C:
	ld_srib A, (xsp + 0x00a7)
	extz wa
	cp de, wa
	jr c, LABEL_FE6773
	ld_srib A, (xsp + 0x01f2)
	cps a, 2
	jrl z, LABEL_FE6BDB
	cps a, 1
	jrl z, LABEL_FE6A1A
	cps a, 0
	jrl nz, NoteMap_VoiceAssign_Finalize
	ld_srib A, (xsp + 0x01f0)
	xor_srib_rm A, 0xFD, 0xEE, 0x01
	and_srib_rm A, 0xFD, 0xEE, 0x01
	ldfr_berp A, 0xFB
	cps a, 0
	jrl z, NoteMap_AddChangedVoices
	bit_erpb 0xFB, 0x00
	jr z, LABEL_FE67F1
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	ldada xwa, 50216
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE67F1
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 0
	call NoteMap_AddEntry

LABEL_FE67F1:
	bit_erpb 0xFB, 0x01
	jr z, LABEL_FE6820
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	ldada xwa, 50220
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE6820
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 1
	call NoteMap_AddEntry

LABEL_FE6820:
	bit_erpb 0xFB, 0x02
	jr z, LABEL_FE684F
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	ldada xwa, 50224
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE684F
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 2
	call NoteMap_AddEntry

LABEL_FE684F:
	bit_erpb 0xFB, 0x03
	jr z, NoteMap_AddChangedVoices
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
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
	xor_srib_rm A, 0xFD, 0xEE, 0x01
	and_srib_rm A, 0xFD, 0xF0, 0x01
	ldfr_berp A, 0xFB
	cps a, 0
	jrl z, NoteMap_CollectEnabledVoices
	bit_erpb 0xFB, 0x00
	jr z, LABEL_FE68C9
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xbc, xwa
	ldada xwa, 49858
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE68C9
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 0
	call NoteMap_AddEntry

LABEL_FE68C9:
	bit_erpb 0xFB, 0x01
	jr z, LABEL_FE68F8
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xbc, xwa
	ldada xwa, 49862
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE68F8
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 1
	call NoteMap_AddEntry

LABEL_FE68F8:
	bit_erpb 0xFB, 0x02
	jr z, LABEL_FE6927
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xbc, xwa
	ldada xwa, 49866
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE6927
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 2
	call NoteMap_AddEntry

LABEL_FE6927:
	bit_erpb 0xFB, 0x03
	jr z, NoteMap_CollectEnabledVoices
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
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
	and_srib_rm A, 0xFD, 0xEE, 0x01
	ldfr_berp A, 0xFB
	cps a, 0
	jrl z, NoteMap_VoiceAssign_Finalize
	bit_erpb 0xFB, 0x00
	jr z, LABEL_FE6994
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xbc, xwa
	ldada xwa, 49858
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 0
	call NoteMap_CollectAndFindBestVoice

LABEL_FE6994:
	bit_erpb 0xFB, 0x01
	jr z, LABEL_FE69BF
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xbc, xwa
	ldada xwa, 49862
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 1
	call NoteMap_CollectAndFindBestVoice

LABEL_FE69BF:
	bit_erpb 0xFB, 0x02
	jr z, LABEL_FE69EA
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xbc, xwa
	ldada xwa, 49866
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 2
	call NoteMap_CollectAndFindBestVoice

LABEL_FE69EA:
	bit_erpb 0xFB, 0x03
	jrl z, NoteMap_VoiceAssign_Finalize
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
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

LABEL_FE6A1A:
	cp_srib_im 0xFD, 0xF0, 0x01, 0xFF
	jr z, LABEL_FE6A61
	cp_srib_im 0xFD, 0xEE, 0x01, 0xFF
	jr z, LABEL_FE6A61
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xhl, xwa
	ldada xbc, 50020
	ld_srib A, (xsp + 0x01ee)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_AddEntry
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xhl, xwa
	ldada xbc, 49662
	ld_srib A, (xsp + 0x01f0)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_AddEntry
	jrl NoteMap_VoiceAssign_Finalize

LABEL_FE6A61:
	cp_srib_im 0xFD, 0xF0, 0x01, 0xFF
	jrl nz, LABEL_FE6B1F
	cp_srib_im 0xFD, 0xEE, 0x01, 0xFF
	jrl z, LABEL_FE6B1F
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xhl, xwa
	ldada xbc, 50020
	ld_srib A, (xsp + 0x01ee)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_AddEntry
	bitda 0, 49662
	jr z, LABEL_FE6ABC
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xbc, xwa
	ldada xwa, 49858
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE6ABC
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 0
	call NoteMap_AddEntry

LABEL_FE6ABC:
	bitda 1, 49662
	jr z, LABEL_FE6AEB
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xbc, xwa
	ldada xwa, 49862
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE6AEB
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 1
	call NoteMap_AddEntry

LABEL_FE6AEB:
	bitda 2, 49662
	jrl z, NoteMap_VoiceAssign_Finalize
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
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

LABEL_FE6B1F:
	cp_srib_im 0xFD, 0xF0, 0x01, 0xFF
	jrl z, NoteMap_VoiceAssign_Finalize
	cp_srib_im 0xFD, 0xEE, 0x01, 0xFF
	jrl nz, NoteMap_VoiceAssign_Finalize
	bitda 0, 50020
	jr z, LABEL_FE6B60
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	ldada xwa, 50216
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE6B60
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 0
	call NoteMap_AddEntry

LABEL_FE6B60:
	bitda 1, 50020
	jr z, LABEL_FE6B8F
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	ldada xwa, 50220
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE6B8F
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 1
	call NoteMap_AddEntry

LABEL_FE6B8F:
	bitda 2, 50020
	jr z, LABEL_FE6BBE
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	ldada xwa, 50224
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE6BBE
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 2
	call NoteMap_AddEntry

LABEL_FE6BBE:
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xhl, xwa
	ldada xbc, 49662
	ld_srib A, (xsp + 0x01f0)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_AddEntry
	jrl NoteMap_VoiceAssign_Finalize

LABEL_FE6BDB:
	cp_srib_im 0xFD, 0xF0, 0x01, 0xFF
	jrl z, LABEL_FE6CD7
	cp_srib_im 0xFD, 0xEE, 0x01, 0xFF
	jrl z, LABEL_FE6CD7
	cpdi16 52840, 0
	jr nz, LABEL_FE6BFF
	ldada xwa, 50020
	lds bc, 2
	call NoteMap_AssignVoiceParams

LABEL_FE6BFF:
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jr z, LABEL_FE6C49

LABEL_FE6C1A:
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jr nz, LABEL_FE6C1A

LABEL_FE6C49:
	lda xwa, (xsp + 2)
	ld xix, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xhl, xwa
	ld_srib A, (xsp + 0x01f0)
	extz wa
	sla wa, 2
	add wa, 0xC4
	ldada xbc, 49662
	st_dri3b B, 0x07, 0xE4, 0xE0
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
	cp l, 0xFF
	jrl z, NoteMap_VoiceAssign_Finalize
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_InitVoiceSlots
	jrl NoteMap_VoiceAssign_Finalize

LABEL_FE6CD7:
	cp_srib_im 0xFD, 0xF0, 0x01, 0xFF
	jr nz, LABEL_FE6D47
	cp_srib_im 0xFD, 0xEE, 0x01, 0xFF
	jr z, LABEL_FE6D47
	cpdi16 52840, 0
	jr nz, LABEL_FE6CF9
	ldada xwa, 50020
	lds bc, 2
	call NoteMap_AssignVoiceParams

LABEL_FE6CF9:
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jrl z, NoteMap_VoiceAssign_Finalize

LABEL_FE6D15:
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jr nz, LABEL_FE6D15
	jrl NoteMap_VoiceAssign_Finalize

LABEL_FE6D47:
	cp_srib_im 0xFD, 0xF0, 0x01, 0xFF
	jrl z, NoteMap_VoiceAssign_Finalize
	cp_srib_im 0xFD, 0xEE, 0x01, 0xFF
	jrl nz, NoteMap_VoiceAssign_Finalize
	lda xwa, (xsp + 2)
	ld xix, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xhl, xwa
	ld_srib A, (xsp + 0x01f0)
	extz wa
	sla wa, 2
	add wa, 0xC4
	ldada xbc, 49662
	st_dri3b B, 0x07, 0xE4, 0xE0
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
	cp l, 0xFF
	jr z, NoteMap_VoiceAssign_Finalize
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_InitVoiceSlots

NoteMap_VoiceAssign_Finalize:
	stib_dri 0xFD, 0x4C, 0x01, 0x00
	stib_dri 0xFD, 0x4D, 0x01, 0x01
	st_dri3b W, 0xFD, 0x4A, 0x01
	call LABEL_FE4289
	cps l, 0
	jrl z, NoteMap_ReallocVoices_Exit
	st_dri3b W, 0xFD, 0x4A, 0x01
	ldada xbc, 49662
	lds de, 0
	call Voice_ApplyTransposeWithEncode
	st_dri3b E, 0xFD, 0x4A, 0x01
	st_dri3b D, 0xFD, 0xA6, 0x00
	ldw bc, 0x52
	ldirw
	lds de, 0
	jr LABEL_FE6E35

LABEL_FE6E1C:
	ld wa, de
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	inc 4, xbc
	st_dri3b W, 0xFD, 0xA7, 0x00
	add xwa, xbc
	ld (xwa), 0x0
	inc 1, de

LABEL_FE6E35:
	ld_srib A, (xsp + 0x00a7)
	extz wa
	cp de, wa
	jr c, LABEL_FE6E1C
	ld_srib A, (xsp + 0x01f2)
	cps a, 2
	jrl z, LABEL_FE7284
	cps a, 1
	jrl z, LABEL_FE70C3
	cps a, 0
	jrl nz, NoteMap_ReallocVoices_Exit
	ld_srib A, (xsp + 0x01f0)
	xor_srib_rm A, 0xFD, 0xEE, 0x01
	and_srib_rm A, 0xFD, 0xEE, 0x01
	ldfr_berp A, 0xFB
	cps a, 0
	jrl z, NoteMap_UpdateChangedVoices
	bit_erpb 0xFB, 0x00
	jr z, LABEL_FE6E9A
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	ldada xwa, 50216
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE6E9A
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 0
	call NoteMap_UpdateEntry

LABEL_FE6E9A:
	bit_erpb 0xFB, 0x01
	jr z, LABEL_FE6EC9
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	ldada xwa, 50220
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE6EC9
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 1
	call NoteMap_UpdateEntry

LABEL_FE6EC9:
	bit_erpb 0xFB, 0x02
	jr z, LABEL_FE6EF8
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	ldada xwa, 50224
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE6EF8
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 2
	call NoteMap_UpdateEntry

LABEL_FE6EF8:
	bit_erpb 0xFB, 0x03
	jr z, NoteMap_UpdateChangedVoices
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
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
	xor_srib_rm A, 0xFD, 0xEE, 0x01
	and_srib_rm A, 0xFD, 0xF0, 0x01
	ldfr_berp A, 0xFB
	cps a, 0
	jrl z, NoteMap_ReallocEnabledVoices
	bit_erpb 0xFB, 0x00
	jr z, LABEL_FE6F72
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xbc, xwa
	ldada xwa, 49858
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE6F72
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 0
	call NoteMap_UpdateEntry

LABEL_FE6F72:
	bit_erpb 0xFB, 0x01
	jr z, LABEL_FE6FA1
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xbc, xwa
	ldada xwa, 49862
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE6FA1
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 1
	call NoteMap_UpdateEntry

LABEL_FE6FA1:
	bit_erpb 0xFB, 0x02
	jr z, LABEL_FE6FD0
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xbc, xwa
	ldada xwa, 49866
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE6FD0
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 2
	call NoteMap_UpdateEntry

LABEL_FE6FD0:
	bit_erpb 0xFB, 0x03
	jr z, NoteMap_ReallocEnabledVoices
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
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
	and_srib_rm A, 0xFD, 0xEE, 0x01
	ldfr_berp A, 0xFB
	cps a, 0
	jrl z, NoteMap_ReallocVoices_Exit
	bit_erpb 0xFB, 0x00
	jr z, LABEL_FE703D
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xbc, xwa
	ldada xwa, 49858
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 0
	call NoteMap_FindAndAllocBestVoice

LABEL_FE703D:
	bit_erpb 0xFB, 0x01
	jr z, LABEL_FE7068
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xbc, xwa
	ldada xwa, 49862
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 1
	call NoteMap_FindAndAllocBestVoice

LABEL_FE7068:
	bit_erpb 0xFB, 0x02
	jr z, LABEL_FE7093
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xbc, xwa
	ldada xwa, 49866
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 2
	call NoteMap_FindAndAllocBestVoice

LABEL_FE7093:
	bit_erpb 0xFB, 0x03
	jrl z, NoteMap_ReallocVoices_Exit
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
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

LABEL_FE70C3:
	cp_srib_im 0xFD, 0xF0, 0x01, 0xFF
	jr z, LABEL_FE710A
	cp_srib_im 0xFD, 0xEE, 0x01, 0xFF
	jr z, LABEL_FE710A
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xhl, xwa
	ldada xbc, 50020
	ld_srib A, (xsp + 0x01ee)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_UpdateEntry
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xhl, xwa
	ldada xbc, 49662
	ld_srib A, (xsp + 0x01f0)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_UpdateEntry
	jrl NoteMap_ReallocVoices_Exit

LABEL_FE710A:
	cp_srib_im 0xFD, 0xF0, 0x01, 0xFF
	jrl nz, LABEL_FE71C8
	cp_srib_im 0xFD, 0xEE, 0x01, 0xFF
	jrl z, LABEL_FE71C8
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xhl, xwa
	ldada xbc, 50020
	ld_srib A, (xsp + 0x01ee)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_UpdateEntry
	bitda 0, 49662
	jr z, LABEL_FE7165
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xbc, xwa
	ldada xwa, 49858
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE7165
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 0
	call NoteMap_UpdateEntry

LABEL_FE7165:
	bitda 1, 49662
	jr z, LABEL_FE7194
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xbc, xwa
	ldada xwa, 49862
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE7194
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 1
	call NoteMap_UpdateEntry

LABEL_FE7194:
	bitda 2, 49662
	jrl z, LABEL_FE7281
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xbc, xwa
	ldada xwa, 49866
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jrl z, LABEL_FE7281
	lda xwa, (xsp + 2)
	ldada xbc, 49662
	lds de, 2
	call NoteMap_UpdateEntry
	jrl NoteMap_ReallocVoices_Exit

LABEL_FE71C8:
	cp_srib_im 0xFD, 0xF0, 0x01, 0xFF
	jrl z, NoteMap_ReallocVoices_Exit
	cp_srib_im 0xFD, 0xEE, 0x01, 0xFF
	jrl nz, NoteMap_ReallocVoices_Exit
	bitda 0, 50020
	jr z, LABEL_FE7209
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	ldada xwa, 50216
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE7209
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 0
	call NoteMap_UpdateEntry

LABEL_FE7209:
	bitda 1, 50020
	jr z, LABEL_FE7238
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	ldada xwa, 50220
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE7238
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 1
	call NoteMap_UpdateEntry

LABEL_FE7238:
	bitda 2, 50020
	jr z, LABEL_FE7267
	lda xwa, (xsp + 2)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	ldada xwa, 50224
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE7267
	lda xwa, (xsp + 2)
	ldada xbc, 50020
	lds de, 2
	call NoteMap_UpdateEntry

LABEL_FE7267:
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xhl, xwa
	ldada xbc, 49662
	ld_srib A, (xsp + 0x01f0)
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_UpdateEntry

LABEL_FE7281:
	jrl NoteMap_ReallocVoices_Exit

LABEL_FE7284:
	cp_srib_im 0xFD, 0xF0, 0x01, 0xFF
	jrl z, LABEL_FE7368
	cp_srib_im 0xFD, 0xEE, 0x01, 0xFF
	jrl z, LABEL_FE7368
	cpdi16 52840, 0
	jr nz, LABEL_FE72A8
	ldada xwa, 50020
	lds bc, 2
	call NoteMap_AssignVoiceParams

LABEL_FE72A8:
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jr z, LABEL_FE72F2

LABEL_FE72C3:
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jr nz, LABEL_FE72C3

LABEL_FE72F2:
	lda xwa, (xsp + 2)
	ld xix, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xhl, xwa
	ld_srib A, (xsp + 0x01f0)
	extz wa
	sla wa, 2
	add wa, 0xC4
	ldada xbc, 49662

LABEL_FE7310:	; NOTE: nothing seems to call here, but I saw this value on VGA undocumented registers at routine EF5163. It may be just a coincidence, though.  (was LABEL_FE730F - off by 1 byte)
	st_dri3b B, 0x07, 0xE4, 0xE0
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
	cp l, 0xFF
	jrl z, NoteMap_ReallocVoices_Exit
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_InitVoiceSlots
	jrl NoteMap_ReallocVoices_Exit

LABEL_FE7368:
	cp_srib_im 0xFD, 0xF0, 0x01, 0xFF
	jr nz, LABEL_FE73D7
	cp_srib_im 0xFD, 0xEE, 0x01, 0xFF
	jr z, LABEL_FE73D7
	cpdi16 52840, 0
	jr nz, LABEL_FE738A
	ldada xwa, 50020
	lds bc, 2
	call NoteMap_AssignVoiceParams

LABEL_FE738A:
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jrl z, NoteMap_ReallocVoices_Exit

LABEL_FE73A6:
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jr nz, LABEL_FE73A6
	jr NoteMap_ReallocVoices_Exit

LABEL_FE73D7:
	cp_srib_im 0xFD, 0xF0, 0x01, 0xFF
	jr z, NoteMap_ReallocVoices_Exit
	cp_srib_im 0xFD, 0xEE, 0x01, 0xFF
	jr nz, NoteMap_ReallocVoices_Exit
	lda xwa, (xsp + 2)
	ld xix, xwa
	st_dri3b W, 0xFD, 0x4A, 0x01
	ld xhl, xwa
	ld_srib A, (xsp + 0x01f0)
	extz wa
	sla wa, 2
	add wa, 0xC4
	ldada xbc, 49662
	st_dri3b B, 0x07, 0xE4, 0xE0
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
	cp l, 0xFF
	jr z, NoteMap_ReallocVoices_Exit
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_InitVoiceSlots

NoteMap_ReallocVoices_Exit:
	pop_werp 0xFA
	st_dri3b L, 0xFD, 0xF2, 0x01
	ret

LABEL_FE745F:
	st_dri3b L, 0xFD, 0xB8, 0xFE
	cp c, 0xFF
	jr z, LABEL_FE746E
	cp e, 0xFF
	jr nz, LABEL_FE747A

LABEL_FE746E:
	cp c, 0xFF
	jrl nz, NoteMap_StoreAndRet
	cp e, 0xFF
	jrl z, NoteMap_StoreAndRet

LABEL_FE747A:
	cps a, 0
	jrl nz, LABEL_FE75E7
	bitda 4, 50312
	jrl z, LABEL_FE75E7
	stib_dri 0xFD, 0xA6, 0x00, 0x00
	stib_dri 0xFD, 0xA7, 0x00, 0x01
	st_dri3b W, 0xFD, 0xA4, 0x00
	call Voice_LookupTableEntries
	cps l, 0
	jrl z, NoteMap_StoreAndRet
	st_dri3b W, 0xFD, 0xA4, 0x00
	call NoteMap_AssignAllVoiceLinks
	cpdi8 50021, 255
	jrl nz, LABEL_FE756F
	bitda 0, 50020
	jr z, LABEL_FE74DE
	lda xwa, (xsp)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
	ld xbc, xwa
	ldada xwa, 50216
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE74DE
	lda xwa, (xsp)
	ldada xbc, 50020
	lds de, 0
	call NoteMap_UpdateEntry

LABEL_FE74DE:
	bitda 1, 50020
	jr z, LABEL_FE750B
	lda xwa, (xsp)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
	ld xbc, xwa
	ldada xwa, 50220
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE750B
	lda xwa, (xsp)
	ldada xbc, 50020
	lds de, 1
	call NoteMap_UpdateEntry

LABEL_FE750B:
	bitda 2, 50020
	jr z, LABEL_FE7538
	lda xwa, (xsp)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
	ld xbc, xwa
	ldada xwa, 50224
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE7538
	lda xwa, (xsp)
	ldada xbc, 50020
	lds de, 2
	call NoteMap_UpdateEntry

LABEL_FE7538:
	bitda 3, 50020
	jrl z, LABEL_FE75E5
	lda xwa, (xsp)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
	ld xbc, xwa
	ldada xwa, 50228
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jrl z, LABEL_FE75E5
	lda xwa, (xsp)
	ldada xbc, 50020
	ldw de, 0x15
	call NoteMap_UpdateEntry
	call AudioInit_RefreshToneBank
	jrl NoteMap_StoreAndRet

LABEL_FE756F:
	cpdi8 50021, 21
	jr nz, LABEL_FE759A
	ldda16 xwa, 50584
	bit 1, wa
	jr z, LABEL_FE7588
	st_dri3b W, 0xFD, 0xA4, 0x00
	call NoteMap_MarkEntriesAboveThreshold

LABEL_FE7588:
	st_dri3b W, 0xFD, 0xA4, 0x00
	ldada xbc, 50020
	ldw de, 0x15
	call NoteMap_UpdateEntry
	jr NoteMap_StoreAndRet

LABEL_FE759A:
	bitda 3, 50020
	jr z, LABEL_FE75CC
	lda xwa, (xsp)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
	ld xbc, xwa
	ldada xwa, 50228
	ld xde, xwa
	ld xwa, xhl
	call NoteMap_MergeEntries
	cps l, 0
	jr z, LABEL_FE75CC
	lda xwa, (xsp)
	ldada xbc, 50020
	ldw de, 0x15
	call NoteMap_UpdateEntry
	call AudioInit_RefreshToneBank

LABEL_FE75CC:
	st_dri3b W, 0xFD, 0xA4, 0x00
	ld xhl, xwa
	ldada xbc, 50020
	ldda8 a, 50021
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_UpdateEntry

LABEL_FE75E5:
	jr NoteMap_StoreAndRet

LABEL_FE75E7:
	stib_dri 0xFD, 0xA6, 0x00, 0x01
	lda_dri3 XIY, 0xFD, 0xA7, 0x00
	st_dri3b A, 0xFD, 0xA4, 0x00
	ld xhl, xbc
	ldada xbc, 50020
	ld e, a
	extz de
	ld xwa, xhl
	call NoteMap_CollectAndAllocVoice_Indirect

NoteMap_StoreAndRet:
	st_dri3b L, 0xFD, 0x48, 0x01
	ret

LABEL_FE760D:
	st_dri3b L, 0xFD, 0xB4, 0xFE
	lda_dri3 XHL, 0xFD, 0x48, 0x01
	lda_dri3 XBC, 0xFD, 0x4A, 0x01
	cp_srib_im 0xFD, 0x4A, 0x01, 0xFF
	jrl z, LABEL_FE770A
	cp_srib_im 0xFD, 0x48, 0x01, 0xFF
	jrl z, LABEL_FE770A
	cpdi16 52840, 1
	jr nz, LABEL_FE7640
	ldada xwa, 50020
	lds bc, 2
	call NoteMap_AssignVoiceParams

LABEL_FE7640:
	stib_dri 0xFD, 0xA6, 0x00, 0x01
	ld_srib A, (xsp + 0x0148)
	extz wa
	ldada xbc, 50056
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	lda_dri3 XBC, 0xFD, 0xA7, 0x00
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x0148)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, LABEL_FE768D
	lda xwa, (xsp)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch

LABEL_FE768D:
	stib_dri 0xFD, 0xA6, 0x00, 0x01
	ld_srib A, (xsp + 0x014a)
	extz wa
	ldada xbc, 49698
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	lda_dri3 XBC, 0xFD, 0xA7, 0x00
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
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
	cp l, 0xFF
	jrl z, NoteMap_StoreVoiceResultAndReturn
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_InitVoiceSlots
	jrl NoteMap_StoreVoiceResultAndReturn

LABEL_FE770A:
	cp_srib_im 0xFD, 0x4A, 0x01, 0xFF
	jr nz, LABEL_FE777D
	cp_srib_im 0xFD, 0x48, 0x01, 0xFF
	jr z, LABEL_FE777D
	cpdi16 52840, 1
	jr nz, LABEL_FE772C
	ldada xwa, 50020
	lds bc, 2
	call NoteMap_AssignVoiceParams

LABEL_FE772C:
	stib_dri 0xFD, 0xA6, 0x00, 0x01
	ld_srib A, (xsp + 0x0148)
	extz wa
	ldada xbc, 50056
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	lda_dri3 XBC, 0xFD, 0xA7, 0x00
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
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

LABEL_FE777D:
	cp_srib_im 0xFD, 0x4A, 0x01, 0xFF
	jr z, NoteMap_StoreVoiceResultAndReturn
	cp_srib_im 0xFD, 0x48, 0x01, 0xFF
	jr nz, NoteMap_StoreVoiceResultAndReturn
	stib_dri 0xFD, 0xA6, 0x00, 0x01
	ld_srib A, (xsp + 0x014a)
	extz wa
	ldada xbc, 49698
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	lda_dri3 XBC, 0xFD, 0xA7, 0x00
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
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
	cp l, 0xFF
	jr z, NoteMap_StoreVoiceResultAndReturn
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_InitVoiceSlots

NoteMap_StoreVoiceResultAndReturn:
	st_dri3b L, 0xFD, 0x4C, 0x01
	ret

LABEL_FE780A:
	st_dri3b L, 0xFD, 0x58, 0xFF
	lda_dri3 XIY, 0xFD, 0xA4, 0x00
	lda_dri3 XBC, 0xFD, 0xA6, 0x00
	cp c, 0xFF
	jr z, LABEL_FE786E
	cp_srib_im 0xFD, 0xA4, 0x00, 0xFF
	jr z, LABEL_FE786E
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

LABEL_FE786E:
	cp c, 0xFF
	jr nz, NoteMap_ProcessNote_SetResult
	cp_srib_im 0xFD, 0xA4, 0x00, 0xFF
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
	st_dri3b L, 0xFD, 0xA8, 0x00
	ret

LABEL_FE78C7:
	st_dri3b L, 0xFD, 0xB4, 0xFE
	lda_dri3 XIY, 0xFD, 0x48, 0x01
	lda_dri3 XBC, 0xFD, 0x4A, 0x01
	cp c, 0xFF
	jrl z, LABEL_FE7989
	cp_srib_im 0xFD, 0x48, 0x01, 0xFF
	jrl z, LABEL_FE7989
	stib_dri 0xFD, 0xA6, 0x00, 0x02
	ld_srib A, (xsp + 0x014a)
	lda_dri3 XBC, 0xFD, 0xA7, 0x00
	lda xwa, (xsp)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
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
	jr z, LABEL_FE7935
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

LABEL_FE7935:
	stib_dri 0xFD, 0xA6, 0x00, 0x03
	ld_srib A, (xsp + 0x014a)
	lda_dri3 XBC, 0xFD, 0xA7, 0x00
	lda xwa, (xsp)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
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
	jrl z, LABEL_FE7A38
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents
	jrl LABEL_FE7A38

LABEL_FE7989:
	cp c, 0xFF
	jrl nz, LABEL_FE7A38
	cp_srib_im 0xFD, 0x48, 0x01, 0xFF
	jrl z, LABEL_FE7A38
	stib_dri 0xFD, 0xA6, 0x00, 0x02
	ld_srib A, (xsp + 0x014a)
	lda_dri3 XBC, 0xFD, 0xA7, 0x00
	lda xwa, (xsp)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
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
	jr z, LABEL_FE79E8
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

LABEL_FE79E8:
	stib_dri 0xFD, 0xA6, 0x00, 0x03
	ld_srib A, (xsp + 0x014a)
	lda_dri3 XBC, 0xFD, 0xA7, 0x00
	lda xwa, (xsp)
	ld xhl, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
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
	jr z, LABEL_FE7A38
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

LABEL_FE7A38:
	st_dri3b L, 0xFD, 0x4C, 0x01
	ret

LABEL_FE7A3E:
	st_dri3b L, 0xFD, 0xB4, 0xFE
	pushw iz
	lda_dri3 XHL, 0xFD, 0x4A, 0x01
	lda_dri3 XBC, 0xFD, 0x4C, 0x01
	cp_srib_im 0xFD, 0x4C, 0x01, 0xFF
	jrl z, LABEL_FE7C1C
	cp_srib_im 0xFD, 0x4A, 0x01, 0xFF
	jrl z, LABEL_FE7C1C
	cpdi16 52840, 2
	jr nz, LABEL_FE7A7A
	cpdi16 52840, 3
	jr nz, LABEL_FE7A7A
	ldada xwa, 50020
	lds bc, 2
	call NoteMap_AssignVoiceParams

LABEL_FE7A7A:
	lds iz, 0
	cp iz, 0x10
	jrl nc, LABEL_FE7B19

LABEL_FE7A83:
	ld wa, iz
	ldada xbc, 50152
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp_srib_rm A, 0xFD, 0x4A, 0x01
	jr nz, LABEL_FE7B10
	stib_dri 0xFD, 0xA8, 0x00, 0x03
	ldto_berp A, 0xF8
	lda_dri3 XBC, 0xFD, 0xA9, 0x00
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jr z, LABEL_FE7AD3
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch

LABEL_FE7AD3:
	stib_dri 0xFD, 0xA8, 0x00, 0x02
	ldto_berp A, 0xF8
	lda_dri3 XBC, 0xFD, 0xA9, 0x00
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jr z, LABEL_FE7B10
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch

LABEL_FE7B10:
	inc 1, iz
	cp iz, 0x10
	jrl c, LABEL_FE7A83

LABEL_FE7B19:
	lds iz, 0
	cp iz, 0x10
	jrl nc, NoteMap_PopIzStoreRet

LABEL_FE7B22:
	ld wa, iz
	ldada xbc, 50152
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp_srib_rm A, 0xFD, 0x4C, 0x01
	jrl nz, NoteMap_LoopAdvance_Next
	stib_dri 0xFD, 0xA8, 0x00, 0x03
	ldto_berp A, 0xF8
	lda_dri3 XBC, 0xFD, 0xA9, 0x00
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
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
	cp l, 0xFF
	jr z, NoteMap_ClaimAndInitVoiceSlot_A
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_InitVoiceSlots

NoteMap_ClaimAndInitVoiceSlot_A:
	stib_dri 0xFD, 0xA8, 0x00, 0x02
	ldto_berp A, 0xF8
	lda_dri3 XBC, 0xFD, 0xA9, 0x00
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
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
	cp l, 0xFF
	jr z, NoteMap_LoopAdvance_Next
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_InitVoiceSlots

NoteMap_LoopAdvance_Next:
	inc 1, iz
	cp iz, 0x10
	jrl c, LABEL_FE7B22
	jrl NoteMap_PopIzStoreRet

LABEL_FE7C1C:
	cp_srib_im 0xFD, 0x4C, 0x01, 0xFF
	jrl nz, LABEL_FE7CEA
	cp_srib_im 0xFD, 0x4A, 0x01, 0xFF
	jrl z, LABEL_FE7CEA
	cpdi16 52840, 2
	jr nz, LABEL_FE7C48
	cpdi16 52840, 3
	jr nz, LABEL_FE7C48
	ldada xwa, 50020
	lds bc, 2
	call NoteMap_AssignVoiceParams

LABEL_FE7C48:
	lds iz, 0
	cp iz, 0x10
	jrl nc, NoteMap_PopIzStoreRet

LABEL_FE7C51:
	ld wa, iz
	ldada xbc, 50152
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp_srib_rm A, 0xFD, 0x4A, 0x01
	jr nz, LABEL_FE7CDE
	stib_dri 0xFD, 0xA8, 0x00, 0x03
	ldto_berp A, 0xF8
	lda_dri3 XBC, 0xFD, 0xA9, 0x00
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jr z, LABEL_FE7CA1
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch

LABEL_FE7CA1:
	stib_dri 0xFD, 0xA8, 0x00, 0x02
	ldto_berp A, 0xF8
	lda_dri3 XBC, 0xFD, 0xA9, 0x00
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, xwa
	pushw 0x2
	ld xwa, xde
	lds de, 4
	call NoteMap_LookupVoice
	cps l, 0
	jr z, LABEL_FE7CDE
	lda xwa, (xsp + 2)
	lds bc, 2
	call NoteMap_FindEntry
	lda xwa, (xsp + 2)
	call NoteMap_FindBestFreeVoice
	call NoteMap_FindBestMatch

LABEL_FE7CDE:
	inc 1, iz
	cp iz, 0x10
	jrl c, LABEL_FE7C51
	jrl NoteMap_PopIzStoreRet

LABEL_FE7CEA:
	cp_srib_im 0xFD, 0x4C, 0x01, 0xFF
	jrl z, NoteMap_PopIzStoreRet
	cp_srib_im 0xFD, 0x4A, 0x01, 0xFF
	jrl nz, NoteMap_PopIzStoreRet
	lds iz, 0
	cp iz, 0x10
	jrl nc, NoteMap_PopIzStoreRet

LABEL_FE7D05:
	ld wa, iz
	ldada xbc, 50152
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp_srib_rm A, 0xFD, 0x4C, 0x01
	jrl nz, NoteMap_LoopAdvance_Next2
	stib_dri 0xFD, 0xA8, 0x00, 0x03
	ldto_berp A, 0xF8
	lda_dri3 XBC, 0xFD, 0xA9, 0x00
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
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
	cp l, 0xFF
	jr z, NoteMap_ClaimAndInitVoiceSlot_B
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_InitVoiceSlots

NoteMap_ClaimAndInitVoiceSlot_B:
	stib_dri 0xFD, 0xA8, 0x00, 0x02
	ldto_berp A, 0xF8
	lda_dri3 XBC, 0xFD, 0xA9, 0x00
	lda xwa, (xsp + 2)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA6, 0x00
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
	cp l, 0xFF
	jr z, NoteMap_LoopAdvance_Next2
	ldada xwa, 49662
	lds bc, 2
	call NoteMap_InitVoiceSlots

NoteMap_LoopAdvance_Next2:
	inc 1, iz
	cp iz, 0x10
	jrl c, LABEL_FE7D05

NoteMap_PopIzStoreRet:
	popw iz
	st_dri3b L, 0xFD, 0x4C, 0x01
	ret

LABEL_FE7E03:
	dec 2, xsp
	ld (xsp), a
	cp c, 0xFF
	jr nz, LABEL_FE7E23
	cp e, 0xFF
	jr z, LABEL_FE7E23
	ldada xde, 50020
	ld a, (xsp)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AssignVoiceParams
	jr LABEL_FE7E5F

LABEL_FE7E23:
	cp c, 0xFF
	jr z, LABEL_FE7E4F
	cp e, 0xFF
	jr z, LABEL_FE7E4F
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
	jr LABEL_FE7E5F

LABEL_FE7E4F:
	ldada xde, 49662
	ld a, (xsp)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_AllocateVoice

LABEL_FE7E5F:
	inc 2, xsp
	ret

LABEL_FE7E62:
	st_dri3b L, 0xFD, 0xB2, 0xFE
	lda_dri3 XIY, 0xFD, 0x48, 0x01
	lda_dri3 XHL, 0xFD, 0x4A, 0x01
	lda_dri3 XBC, 0xFD, 0x4C, 0x01
	cp_srib_im 0xFD, 0x4A, 0x01, 0xFF
	jrl nz, NoteMap_CrossChannelReassign
	cp_srib_im 0xFD, 0x48, 0x01, 0xFF
	jrl z, NoteMap_CrossChannelReassign
	stib_dri 0xFD, 0xA6, 0x00, 0x00
	stib_dri 0xFD, 0xA7, 0x00, 0x00
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014c)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, LABEL_FE7EC6
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LABEL_FE7EC6:
	stib_dri 0xFD, 0xA6, 0x00, 0x04
	stib_dri 0xFD, 0xA7, 0x00, 0xFF
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014c)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, LABEL_FE7F04
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call NoteMap_SetChannelParam

LABEL_FE7F04:
	stib_dri 0xFD, 0xA6, 0x00, 0x06
	stib_dri 0xFD, 0xA7, 0x00, 0xFF
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
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
	cp_srib_im 0xFD, 0x4A, 0x01, 0xFF
	jr z, NoteMap_SetParam_Return
	ld_srib A, (xsp + 0x014a)
	cp_srib_rm A, 0xFD, 0x48, 0x01
	jr z, NoteMap_SetParam_Return
	cp_srib_im 0xFD, 0x4C, 0x01, 0x15
	jr z, LABEL_FE7F66
	cp_srib_im 0xFD, 0x4C, 0x01, 0x02
	jr nz, NoteMap_SetParam_Return

LABEL_FE7F66:
	stib_dri 0xFD, 0xA6, 0x00, 0x06
	stib_dri 0xFD, 0xA7, 0x00, 0xFF
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
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
	st_dri3b L, 0xFD, 0x4E, 0x01
	ret

LABEL_FE7FAA:
	st_dri3b L, 0xFD, 0xB4, 0xFE
	lda_dri3 XIY, 0xFD, 0x48, 0x01
	lda_dri3 XBC, 0xFD, 0x4A, 0x01
	cp c, 0xFF
	jrl z, LABEL_FE8097
	cp_srib_im 0xFD, 0x48, 0x01, 0xFF
	jrl z, LABEL_FE8097
	stib_dri 0xFD, 0xA6, 0x00, 0x00
	stib_dri 0xFD, 0xA7, 0x00, 0x00
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, LABEL_FE8006
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

LABEL_FE8006:
	stib_dri 0xFD, 0xA6, 0x00, 0x04
	stib_dri 0xFD, 0xA7, 0x00, 0xFF
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, LABEL_FE8044
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

LABEL_FE8044:
	stib_dri 0xFD, 0xA6, 0x00, 0x06
	stib_dri 0xFD, 0xA7, 0x00, 0xFF
	cp_srib_im 0xFD, 0x4A, 0x01, 0x19
	jr nz, LABEL_FE8061
	ldda8 a, 50210
	lda_dri3 XBC, 0xFD, 0x4A, 0x01

LABEL_FE8061:
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jrl z, LABEL_FE8171
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents
	jrl LABEL_FE8171

LABEL_FE8097:
	cp c, 0xFF
	jrl nz, LABEL_FE8171
	cp_srib_im 0xFD, 0x48, 0x01, 0xFF
	jrl z, LABEL_FE8171
	stib_dri 0xFD, 0xA6, 0x00, 0x00
	stib_dri 0xFD, 0xA7, 0x00, 0x00
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, LABEL_FE80E4
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

LABEL_FE80E4:
	stib_dri 0xFD, 0xA6, 0x00, 0x04
	stib_dri 0xFD, 0xA7, 0x00, 0xFF
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, LABEL_FE8122
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

LABEL_FE8122:
	stib_dri 0xFD, 0xA6, 0x00, 0x06
	stib_dri 0xFD, 0xA7, 0x00, 0xFF
	cp_srib_im 0xFD, 0x4A, 0x01, 0x19
	jr nz, LABEL_FE813F
	ldda8 a, 50210
	lda_dri3 XBC, 0xFD, 0x4A, 0x01

LABEL_FE813F:
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, LABEL_FE8171
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_ScanAndEmitMidiEvents

LABEL_FE8171:
	st_dri3b L, 0xFD, 0x4C, 0x01
	ret

LABEL_FE8177:
	st_dri3b L, 0xFD, 0xB4, 0xFE
	lda_dri3 XIY, 0xFD, 0x48, 0x01
	lda_dri3 XBC, 0xFD, 0x4A, 0x01
	cp c, 0xFF
	jrl z, LABEL_FE8215
	cp_srib_im 0xFD, 0x48, 0x01, 0xFF
	jrl z, LABEL_FE8215
	stib_dri 0xFD, 0xA6, 0x00, 0x00
	stib_dri 0xFD, 0xA7, 0x00, 0x00
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x0148)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, LABEL_FE81D3
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x014a)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

LABEL_FE81D3:
	stib_dri 0xFD, 0xA6, 0x00, 0x01
	stib_dri 0xFD, 0xA7, 0x00, 0xFF
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
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

LABEL_FE8215:
	cp c, 0xFF
	jrl nz, SeqPart_EmitMelodicNote_Return
	cp_srib_im 0xFD, 0x48, 0x01, 0xFF
	jr z, SeqPart_EmitMelodicNote_Return
	stib_dri 0xFD, 0xA6, 0x00, 0x00
	stib_dri 0xFD, 0xA7, 0x00, 0x00
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x0148)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, LABEL_FE8261
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x014a)
	ld c, a
	extz bc
	ld xwa, xde
	call Voice_BuildAndEmitNoteOnEvents

LABEL_FE8261:
	stib_dri 0xFD, 0xA6, 0x00, 0x01
	stib_dri 0xFD, 0xA7, 0x00, 0xFF
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
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
	st_dri3b L, 0xFD, 0x4C, 0x01
	ret

LABEL_FE82A5:
	st_dri3b L, 0xFD, 0xB4, 0xFE
	lda_dri3 XIY, 0xFD, 0x48, 0x01
	lda_dri3 XBC, 0xFD, 0x4A, 0x01
	cp c, 0xFF
	jrl z, LABEL_FE8343
	cp_srib_im 0xFD, 0x48, 0x01, 0xFF
	jrl z, LABEL_FE8343
	stib_dri 0xFD, 0xA6, 0x00, 0x00
	stib_dri 0xFD, 0xA7, 0x00, 0x00
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, LABEL_FE8301
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call SeqPart_EmitNoteOnMessages

LABEL_FE8301:
	stib_dri 0xFD, 0xA6, 0x00, 0x01
	stib_dri 0xFD, 0xA7, 0x00, 0xFF
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
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

LABEL_FE8343:
	cp c, 0xFF
	jrl nz, SeqPart_EmitPercussionNote_Return
	cp_srib_im 0xFD, 0x48, 0x01, 0xFF
	jr z, SeqPart_EmitPercussionNote_Return
	stib_dri 0xFD, 0xA6, 0x00, 0x00
	stib_dri 0xFD, 0xA7, 0x00, 0x00
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
	ld xbc, xwa
	ld_srib A, (xsp + 0x014a)
	extz wa
	pushw wa
	ld xwa, xde
	lds de, 0
	call NoteMap_LookupVoice
	cps l, 0
	jr z, LABEL_FE838F
	lda xwa, (xsp)
	ld xde, xwa
	ld_srib A, (xsp + 0x0148)
	ld c, a
	extz bc
	ld xwa, xde
	call SeqPart_EmitNoteOnMessages

LABEL_FE838F:
	stib_dri 0xFD, 0xA6, 0x00, 0x01
	stib_dri 0xFD, 0xA7, 0x00, 0xFF
	lda xwa, (xsp)
	ld xde, xwa
	st_dri3b W, 0xFD, 0xA4, 0x00
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
	st_dri3b L, 0xFD, 0x4C, 0x01
	ret

LABEL_FE83D3:
	lda xsp, (xsp - 12)
	push xiz
	lds iz, 0
	call RhythmBuf_SaveWritePos

RhythmBuf_EventDispatchLoop:
	call RhythmBuf_ReadAlternate
	ld (xsp + 4), hl
	ld wa, (xsp + 4)
	cp wa, 0xFFFF
	jrl z, LABEL_FE87B9
	ld wa, (xsp + 4)
	cp wa, 0xC8
	jr z, Rhythm_ProcessEventDispatch
	cp wa, 0xC7
	jr z, Rhythm_ProcessEventDispatch
	cp wa, 0xC6
	jr z, Rhythm_ProcessEventDispatch
	cp wa, 0xC5
	jr z, Rhythm_ProcessEventDispatch
	cp wa, 0xC4
	jr z, Rhythm_ProcessEventDispatch
	sub wa, 0xD0
	cps wa, 0
	jr lt, RhythmBuf_EventDispatchLoop
	cp wa, 0x8
	jr gt, RhythmBuf_EventDispatchLoop
	add wa, wa
	lda_24 xix, 0xee8fae
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xfe8433
	jp_dri 8, 0x07, 0xF0, 0xE0

Rhythm_ProcessEventDispatch:
	call RhythmBuf_ReadAlternate
	ld (xsp + 6), hl
	ld wa, (xsp + 6)
	cp wa, 0xFFFF
	jr z, RhythmBuf_EventDispatchLoop
	call RhythmBuf_ReadAlternate
	ld (xsp + 8), hl
	ld wa, (xsp + 8)
	cp wa, 0xFFFF
	jr z, RhythmBuf_EventDispatchLoop
	call RhythmBuf_ReadAlternate
	ld (xsp + 12), hl
	ld wa, (xsp + 12)
	cp wa, 0xFFFF
	jrl z, RhythmBuf_EventDispatchLoop
	call RhythmBuf_ReadAlternate
	ld (xsp + 10), hl
	ld wa, (xsp + 10)
	cp wa, 0xFFFF
	jrl z, RhythmBuf_EventDispatchLoop
	call RhythmBuf_ReadAlternate
	ld (xsp + 14), hl
	ld wa, (xsp + 14)
	cp wa, 0xFFFF
	jrl z, RhythmBuf_EventDispatchLoop
	ld wa, (xsp + 4)
	and wa, 0xF
	lda_24 xbc, 0xee8f9a
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	ld (xsp + 4), wa
	ld wa, (xsp + 8)
	bit 4, wa
	jr z, LABEL_FE84AA
	resm 4, (xsp + 8)
	setm 7, (xsp + 6)

LABEL_FE84AA:
	cpw (xsp + 4), 0x14
	jr nz, LABEL_FE84C0
	ormi16 (xsp + 6), 0xF0
	ldw (xsp + 12), 0x40
	ldw (xsp + 14), 0x48

LABEL_FE84C0:
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
	jr z, LABEL_FE851E
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

LABEL_FE851E:
	lds wa, 0
	cpw (xsp + 10), 0x0
	jr z, LABEL_FE852A
	ldw wa, 0x7F

LABEL_FE852A:
	ld (xsp + 10), wa
	ld wa, (xsp + 4)
	ld de, (xsp + 10)
	ldw bc, 0x5E
	call SndPart_SetParam
	ld wa, (xsp + 4)
	pushw 0x5
	ld de, (xsp + 12)
	ldw bc, 0x5E
	call SndParam_NotifyAndReturn
	cpdi8 36150, 220
	jr z, LABEL_FE8561
	ld wa, (xsp + 4)
	pushw 0x3
	ld de, (xsp + 12)
	ldw bc, 0x5E
	call SndParam_NotifyAndReturn

LABEL_FE8561:
	ld wa, (xsp + 4)
	ld de, (xsp + 12)
	ldw bc, 0xA
	call SndPart_SetParam
	ld wa, (xsp + 4)
	pushw 0x5
	ld de, (xsp + 14)
	ldw bc, 0xA
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 4)
	pushw 0x3
	ld de, (xsp + 14)
	ldw bc, 0xA
	call SndParam_NotifyAndReturn
	ldw wa, 0x7F
	cpw (xsp + 14), 0x48
	jr ge, LABEL_FE859F
	ld wa, (xsp + 14)
	add wa, 0x37

LABEL_FE859F:
	ld (xsp + 14), wa
	ld wa, (xsp + 4)
	ld de, (xsp + 14)
	ldw bc, 0xB
	call SndPart_SetParam
	ld wa, (xsp + 4)
	pushw 0x5
	ld de, (xsp + 16)
	ldw bc, 0xB
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 4)
	pushw 0x3
	ld de, (xsp + 16)
	ldw bc, 0xB
	call SndParam_NotifyAndReturn
	jrl RhythmBuf_EventDispatchLoop
	call RhythmBuf_ReadAlternate
	ldfr_werp HL, 0xFA
	ldto_werp WA, 0xFA
	cp wa, 0xFFFF
	jrl z, RhythmBuf_EventDispatchLoop
	call RhythmBuf_ReadAlternate
	ld iz, hl
	ld wa, iz
	cp wa, 0xFFFF
	jrl z, RhythmBuf_EventDispatchLoop
	cpi_werp 0xFA, 3
	jrl nz, RhythmBuf_EventDispatchLoop
	cps iz, 0
	jrl nz, RhythmBuf_EventDispatchLoop
	ldw iz, 0x10
	cp iz, 0x14
	jrl ge, RhythmBuf_EventDispatchLoop

LABEL_FE8607:
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
	ldw bc, 0x1B0
	ldw de, 0x2000
	call SndPart_SetParam
	ld wa, iz
	pushw 0x5
	ldw bc, 0x1B0
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
	ldw bc, 0xB
	ldw de, 0x7F
	call SndPart_SetParam
	ld wa, iz
	pushw 0x5
	ldw bc, 0xB
	ldw de, 0x7F
	call SndParam_NotifyAndReturn
	inc 1, iz
	cp iz, 0x14
	jr lt, LABEL_FE8607
	jrl RhythmBuf_EventDispatchLoop
	call RhythmBuf_ReadAlternate
	ldfr_werp HL, 0xFA
	ldto_werp WA, 0xFA
	cp wa, 0xFFFF
	jrl z, RhythmBuf_EventDispatchLoop
	call RhythmBuf_ReadAlternate
	ld iz, hl
	ld wa, iz
	cp wa, 0xFFFF
	jrl z, RhythmBuf_EventDispatchLoop
	ld wa, (xsp + 4)
	and wa, 0xF
	lda_24 xbc, 0xee8f9a
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	ld (xsp + 4), wa
	ldto_werp WA, 0xFA
	cp wa, 0x10
	jrl z, LABEL_FE87AA
	cps wa, 5
	jrl z, LABEL_FE878C
	cps wa, 4
	jrl z, LABEL_FE875F
	cps wa, 3
	jr z, LABEL_FE8732
	cps wa, 2
	jr z, LABEL_FE86F9
	cps wa, 1
	jrl nz, LABEL_FE87B6
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

LABEL_FE86F9:
	lds wa, 0
	cp iz, 0x40
	jr lt, LABEL_FE8709
	ld wa, iz
	add wa, wa
	sub wa, 0x80

LABEL_FE8709:
	ld bc, iz
	sla bc, 7
	or bc, wa
	ld iz, bc
	ld wa, (xsp + 4)
	ld de, iz
	ldw bc, 0x1B0
	call SndPart_SetParam
	ld wa, (xsp + 4)
	ld bc, iz
	pushw 0x5
	ld de, bc
	ldw bc, 0x1B0
	call SndParam_NotifyAndReturn
	jrl RhythmBuf_EventDispatchLoop

LABEL_FE8732:
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

LABEL_FE875F:
	ld wa, (xsp + 4)
	ld de, iz
	ldw bc, 0xA
	call SndPart_SetParam
	ld wa, (xsp + 4)
	pushw 0x5
	ld de, iz
	ldw bc, 0xA
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 4)
	pushw 0x3
	ld de, iz
	ldw bc, 0xA
	call SndParam_NotifyAndReturn
	jrl RhythmBuf_EventDispatchLoop

LABEL_FE878C:
	ld wa, (xsp + 4)
	ld de, iz
	ldw bc, 0xB
	call SndPart_SetParam
	ld wa, (xsp + 4)
	pushw 0x5
	ld de, iz
	ldw bc, 0xB
	call SndParam_NotifyAndReturn
	jrl RhythmBuf_EventDispatchLoop

LABEL_FE87AA:
	ldto_berp A, 0xF8
	extz wa
	call LABEL_FDDEFF
	jrl RhythmBuf_EventDispatchLoop

LABEL_FE87B6:
	jrl RhythmBuf_EventDispatchLoop

LABEL_FE87B9:
	call Song_SendPartDataBlocks
	pop xiz
	lda xsp, (xsp + 12)
	ret

LABEL_FE87C2:
	dec 6, xsp
	push xiz
	lds iz, 0
	call SeqEvtBuf_SaveReadPos

SeqEvtBuf_NonNoteDispatchLoop:
	call SeqEvtBuf_ReadAlternate
	ld (xsp + 4), hl
	ld wa, (xsp + 4)
	cp wa, 0xFFFF
	jrl z, LABEL_FE8A78
	ld wa, (xsp + 4)
	cp wa, 0xD2
	jrl z, SeqEvtBuf_NoteDispatch
	cp wa, 0xD1
	jrl z, SeqEvtBuf_NoteDispatch
	cp wa, 0xD0
	jrl z, LABEL_FE889A
	cp wa, 0xC2
	jr z, LABEL_FE8800
	cp wa, 0xC1
	jr nz, SeqEvtBuf_NonNoteDispatchLoop

LABEL_FE8800:
	call SeqEvtBuf_ReadAlternate
	ld (xsp + 6), hl
	ld wa, (xsp + 6)
	cp wa, 0xFFFF
	jr z, SeqEvtBuf_NonNoteDispatchLoop
	call SeqEvtBuf_ReadAlternate
	ld (xsp + 8), hl
	ld wa, (xsp + 8)
	cp wa, 0xFFFF
	jr z, SeqEvtBuf_NonNoteDispatchLoop
	ld wa, (xsp + 4)
	and wa, 0xF
	lda_24 xbc, 0xee8fa4
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	ld (xsp + 4), wa
	ld wa, (xsp + 8)
	bit 4, wa
	jr z, LABEL_FE8844
	resm 4, (xsp + 8)
	setm 7, (xsp + 6)

LABEL_FE8844:
	ld wa, (xsp + 4)
	ld de, (xsp + 6)
	lds bc, 0
	call SndPart_SetParam
	ld wa, (xsp + 4)
	ld de, (xsp + 8)
	ldw bc, 0x20
	call SndPart_SetParam
	ld wa, (xsp + 4)
	ldw bc, 0x5E
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
	ldw bc, 0x5E
	lds de, 0
	call SndParam_NotifyAndReturn
	jrl SeqEvtBuf_NonNoteDispatchLoop

LABEL_FE889A:
	call SeqEvtBuf_ReadAlternate
	ldfr_werp HL, 0xFA
	ldto_werp WA, 0xFA
	cp wa, 0xFFFF
	jrl z, SeqEvtBuf_NonNoteDispatchLoop
	call SeqEvtBuf_ReadAlternate
	ld iz, hl
	ld wa, iz
	cp wa, 0xFFFF
	jrl z, SeqEvtBuf_NonNoteDispatchLoop
	cpi_werp 0xFA, 3
	jrl nz, SeqEvtBuf_NonNoteDispatchLoop
	cps iz, 0
	jrl nz, SeqEvtBuf_NonNoteDispatchLoop
	ldw (xsp + 8), 0x17
	cpw (xsp + 8), 0x18
	jrl ge, SeqEvtBuf_NonNoteDispatchLoop

LABEL_FE88D2:
	ld wa, (xsp + 8)
	lds bc, 1
	lds de, 0
	call SndPart_SetParam
	ld wa, (xsp + 8)
	ldw bc, 0x1B0
	ldw de, 0x2000
	call SndPart_SetParam
	ld wa, (xsp + 8)
	ldw bc, 0x40
	lds de, 0
	call SndPart_SetParam
	ld wa, (xsp + 8)
	ldw bc, 0xB
	ldw de, 0x7F
	call SndPart_SetParam
	ld wa, (xsp + 8)
	pushw 0x3
	lds bc, 1
	lds de, 0
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 8)
	pushw 0x3
	ldw bc, 0x1B0
	ldw de, 0x2000
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 8)
	pushw 0x3
	ldw bc, 0x40
	lds de, 0
	call SndParam_NotifyAndReturn
	ld wa, (xsp + 8)
	pushw 0x3
	ldw bc, 0xB
	ldw de, 0x7F
	call SndParam_NotifyAndReturn
	incm 1, (xsp + 8)
	cpw (xsp + 8), 0x18
	jr lt, LABEL_FE88D2
	jrl SeqEvtBuf_NonNoteDispatchLoop

; Sequencer event buffer note dispatch
SeqEvtBuf_NoteDispatch:	; FE894D
	call SeqEvtBuf_ReadAlternate
	ldfr_werp HL, 0xFA
	ldto_werp WA, 0xFA
	cp wa, 0xFFFF
	jrl z, SeqEvtBuf_NonNoteDispatchLoop
	call SeqEvtBuf_ReadAlternate
	ld iz, hl
	ld wa, iz
	cp wa, 0xFFFF
	jrl z, SeqEvtBuf_NonNoteDispatchLoop
	ld wa, (xsp + 4)
	and wa, 0xF
	lda_24 xbc, 0xee8fa4
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	ld (xsp + 4), wa
	ldto_werp WA, 0xFA
	dec 1, wa
	cps wa, 0
	jrl lt, LABEL_FE8A75
	cps wa, 6
	jrl gt, LABEL_FE8A75
	add wa, wa
	lda_24 xix, 0xee8fc0
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xfe89a8
	jp_dri 8, 0x07, 0xF0, 0xE0

; Sequence performance event dispatch (6-entry, table 0xEE8FC0)
SeqPerformance_EventDispatch:	; FE89A8
	ld	wa, (xsp+4)
	ld	de, iz
	lds	bc, 1
	call	16691429
	ld	wa, (xsp+4)
	pushw	3
	ld	de, iz
	lds	bc, 1
	call	16569115
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
	call	16691429
	ld	wa, (xsp+4)
	ld	bc, iz
	pushw	3
	ld	de, bc
	ldw	bc, 432
	call	16569115
	jrl	-562
	ld	wa, (xsp+4)
	ld	de, iz
	ldw	bc, 64
	call	16691429
	ld	wa, (xsp+4)
	pushw	3
	ld	de, iz
	ldw	bc, 64
	call	16569115
	jrl	-592
	ld	wa, (xsp+4)
	ld	de, iz
	ldw	bc, 10
	call	16691429
	ld	wa, (xsp+4)
	pushw	3
	ld	de, iz
	ldw	bc, 10
	call	16569115
	jrl	-622
	ld	wa, (xsp+4)
	ld	de, iz
	ldw	bc, 11
	call	16691429
	ld	wa, (xsp+4)
	pushw	3
	ld	de, iz
	ldw	bc, 11
	call	16569115
	jrl	-652
	ld	wa, (xsp+4)
	ld	de, iz
	ldw	bc, 94
	call	16691429
	ld	wa, (xsp+4)
	pushw	3
	ld	de, iz
	ldw	bc, 94
	call	16569115
	jrl	-682

LABEL_FE8A75:
	jrl SeqEvtBuf_NonNoteDispatchLoop

LABEL_FE8A78:
	call Song_SendPartDataBlocks
	pop xiz
	inc 6, xsp
	ret

LABEL_FE8A80:
	ret

VoiceMap_AllocateSlot:
	ldb l, 0xFF
	cpdi16 52838, 0
	jr nz, LABEL_FE8AB2
	ldada xwa, 52770
	calr NoteMap_GetVoiceData_Entry
	cp l, 0xFF
	jr z, LABEL_FE8AAE
	calr UIParam_ScanAndCollect
	ldmm8 52910, 52959
	ldmm8 52912, 52960
	ldda16 xwa, 52772
	ld l, a
	jr NoteMap_FindBestMatch_Return

LABEL_FE8AAE:
	ldb l, 0xFF
	jr NoteMap_FindBestMatch_Return

LABEL_FE8AB2:
	cpdi16 52770, 0
	jr nz, LABEL_FE8ACF
	calr LABEL_FE8BEE
	stdi8 52910, 255
	stdi8 52912, 255
	ldda16 xwa, 52772
	ld l, a
	jr NoteMap_FindBestMatch_Return

LABEL_FE8ACF:
	ldada xwa, 52770
	calr NoteMap_GetVoiceData_Entry
	cp l, 0xFF
	jr z, LABEL_FE8AF9
	stdi8 59836, 10
	ldda8 a, 52908
	cpda8 a, 52906
	jr nz, LABEL_FE8AF4
	ldda16 xwa, 52772
	cpda16 xwa, 52840
	jr z, LABEL_FE8AF9

LABEL_FE8AF4:
	stdi8 52914, 1

LABEL_FE8AF9:
	ldb l, 0xFF

NoteMap_FindBestMatch_Return:
	ret

; ============================================================================
; NoteMap_FindBestMatch - Find the best voice to steal for a new note
; ============================================================================
; Input:  Implicit (reads from note map state variables at 52770+)
; Output: L = voice index to steal (0xFF if no suitable candidate)
; Implements voice stealing algorithm: compares current note parameters
; against the last-used voice state (addresses 52906-52960) to determine
; if reuse is possible. Falls back to searching for the least-important
; active voice when direct reuse is not available.
; ============================================================================
NoteMap_FindBestMatch:
	ldb l, 0xFF
	stdi8 59836, 0
	cpdi16 52770, 0
	jr z, LABEL_FE8B5B
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
	jr z, LABEL_FE8B57

NoteMap_CheckVoiceReuse:
	ldada xwa, 52770
	calr NoteMap_GetVoiceData_Entry
	cp l, 0xFF
	jr z, LABEL_FE8B53
	calr UIParam_ScanAndCollect
	ldmm8 52910, 52959
	ldmm8 52912, 52960
	ldda16 xwa, 52772
	ld l, a
	jr NoteMap_GetVoiceData_Return

LABEL_FE8B53:
	ldb l, 0xFF
	jr NoteMap_GetVoiceData_Return

LABEL_FE8B57:
	ldb l, 0xFF
	jr NoteMap_GetVoiceData_Return

LABEL_FE8B5B:
	calr LABEL_FE8BEE
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
	jr z, LABEL_FE8BDF
	ld l, (xwa + 5)
	ld h, (xwa + 4)
	lds de, 1
	cp de, (xwa)
	jr nc, LABEL_FE8BBF

LABEL_FE8B91:
	ld bc, de
	extz xbc
	add xbc, xbc
	inc 4, xbc
	add xbc, xwa
	cp l, (xbc + 1)
	jr ule, LABEL_FE8BB9
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

LABEL_FE8BB9:
	inc 1, de
	cp de, (xwa)
	jr c, LABEL_FE8B91

LABEL_FE8BBF:
	cp l, 0x18
	jr ule, LABEL_FE8BD3
	cp l, 0x67
	jr nc, LABEL_FE8BD3
	stda8 52906, l
	stda8 52907, h
	jr LABEL_FE8BE9

LABEL_FE8BD3:
	stdi8 52906, 255
	stdi8 52907, 255
	jr LABEL_FE8BE9

LABEL_FE8BDF:
	stdi8 52906, 255
	stdi8 52907, 255

LABEL_FE8BE9:
	ldda8 l, 52906
	ret

LABEL_FE8BEE:
	stdi16 52838, 0
	stdi8 52914, 0
	ret

UIParam_ScanAndCollect:
	lda xsp, (xsp - 68)
	push_werp 0xFA
	stdi8 52914, 0
	cpdi8 52907, 15
	jr ule, LABEL_FE8C18
	ldda8 a, 52907
	sub a, 0xF
	ldfr_berp A, 0xFB
	jr UIParam_CallbackDispatch

LABEL_FE8C18:
	ldi_berp 0xFB, 1

; UIParam callback dispatch
UIParam_CallbackDispatch:	; FE8C1B
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
	jr z, LABEL_FE8C79
	lds hl, 0
	jr LABEL_FE8C74

; UI parameter callback return (table 0xEEAE04)
UIParam_CallbackReturn:	; FE8C3C
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
	ldto_berp A, 0xFB
	ld (xde), a
	inc 1, hl

LABEL_FE8C74:
	cp hl, (xsp + 2)
	jr c, UIParam_CallbackReturn

LABEL_FE8C79:
	ldda16 xwa, 52772
	stda16 52840, xwa
	ld wa, (xsp + 2)
	stda16 52838, xwa
	pop_werp 0xFA
	lda xsp, (xsp + 68)
	ret

NoteMap_SearchVoiceEntry:
	cpdi16 53087, 0
	jrl z, LABEL_FE8D26
	lds hl, 0
	lds de, 0
	jr LABEL_FE8D18

LABEL_FE8C9E:
	cps de, 4
	jr z, LABEL_FE8D1E
	ld bc, hl
	add bc, bc
	inc 4, bc
	ldada xix, 53088
	extz xbc
	add xbc, xix
	ld c, (xbc)
	ldfr_berp C, 0xEA
	ldda8 c, 52906
	ldto_berp B, 0xEA
	cp b, c
	jr gt, LABEL_FE8CD6
	ldda8 c, 52906
	sub c, 0xC
	ld b, c
	ldto_berp C, 0xEA
	cp c, b
	jr ule, LABEL_FE8CE7
	jr LABEL_FE8CF7

LABEL_FE8CD2:
	sub_erpb 0xEA, 0x0C

LABEL_FE8CD6:
	ldda8 c, 52906
	ldto_berp B, 0xEA
	cp b, c
	jr gt, LABEL_FE8CD2
	jr LABEL_FE8CF7

LABEL_FE8CE3:
	add_erpb 0xEA, 0x0C

LABEL_FE8CE7:
	ldda8 c, 52906
	sub c, 0xC
	ld b, c
	ldto_berp C, 0xEA
	cp c, b
	jr ule, LABEL_FE8CE3

LABEL_FE8CF7:
	ldda8 c, 52906
	sub_berp C, 0xEA
	cps c, 2
	jr ule, LABEL_FE8D16
	ld bc, de
	extz xbc
	add xbc, xbc
	inc 4, xbc
	ld xix, xbc
	add xix, xwa
	ldto_berp C, 0xEA
	ld (xix + 1), c
	inc 1, de

LABEL_FE8D16:
	inc 1, hl

LABEL_FE8D18:
	cpda16 xhl, 53087
	jr c, LABEL_FE8C9E

LABEL_FE8D1E:
	ld c, e
	extz bc
	ld (xwa), bc
	jr LABEL_FE8D2A

LABEL_FE8D26:
	ldw (xwa), 0x0

LABEL_FE8D2A:
	cpw (xwa), 0x1
	jr ule, LABEL_FE8DAE
	ld hl, (xwa)
	sub hl, 0x1
	jr z, LABEL_FE8DAE

LABEL_FE8D38:
	lds de, 0
	cp de, hl
	jr nc, LABEL_FE8DA8

LABEL_FE8D3E:
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
	jr nc, LABEL_FE8DA2
	ld bc, de
	extz xbc
	add xbc, xbc
	inc 4, xbc
	add xbc, xwa
	ld c, (xbc + 1)
	ldfr_berp C, 0xEA
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
	ldto_berp C, 0xEA
	ld (xix + 1), c

LABEL_FE8DA2:
	inc 1, de
	cp de, hl
	jr c, LABEL_FE8D3E

LABEL_FE8DA8:
	sub hl, 0x1
	jr nz, LABEL_FE8D38

LABEL_FE8DAE:
	ld hl, (xwa)
	ret

SoundFX_Handler_12:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr NoteMap_SearchVoiceEntry
	cps l, 0
	jr z, LABEL_FE8DC1
	ldw (xiz), 0x1

LABEL_FE8DC1:
	ld hl, (xiz)
	pop xiz
	ret

SoundFX_Handler_0:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr NoteMap_SearchVoiceEntry
	cps l, 0
	jr z, LABEL_FE8DD5
	submi8 (xiz + 5), 0xC

LABEL_FE8DD5:
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
	jr nz, LABEL_FE8DFD
	ldda8 a, 52906
	sub a, (xiz + 5)
	cp a, 0x8
	jr ugt, SoundFX_SetVolumeOffset_Return
	addmi8 (xiz + 5), 0xC
	jr SoundFX_SetVolumeOffset_Return

LABEL_FE8DFD:
	submi8 (xiz + 5), 0xC
	ld de, (xiz)
	sub de, 0x1
	jr z, SoundFX_SetVolumeOffset_Return

LABEL_FE8E09:
	ld wa, de
	extz xwa
	add xwa, xwa
	inc 4, xwa
	ld xbc, xwa
	add xbc, xiz
	ldda8 a, 52906
	sub a, (xbc + 1)
	cp a, 0x8
	jr ugt, LABEL_FE8E31
	ld wa, de
	extz xwa
	add xwa, xwa
	inc 4, xwa
	add xwa, xiz
	addmi8 (xwa + 1), 0xC
	jr SoundFX_SetVolumeOffset_Return

LABEL_FE8E31:
	djnz xde, LABEL_FE8E09

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
	cp a, 0xFF
	jr z, LABEL_FE8E99
	ldda8 a, 52906
	subda8 a, 52960
	add a, l
	inc 1, a
	ld l, a
	extz wa
	div a, 0xC
	ld l, w
	ld e, l
	extz de
	ldda8 a, 52959
	dec 1, a
	extz wa
	muls wa, 0xC
	lda_24 xbc, 0xee8fce
	exts xwa
	add xwa, xbc
	ld_srib3 C, 0x07, 0xE0, 0xE8
	ldda8 a, 52906
	sub a, c
	ld (xiz + 5), a
	ldw (xiz), 0x1
	jr LABEL_FE8E9D

LABEL_FE8E99:
	ldw (xiz), 0x0

LABEL_FE8E9D:
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
	cp a, 0xFF
	jr z, LABEL_FE8F02
	ldda8 a, 52906
	subda8 a, 52960
	add a, l
	inc 1, a
	ld l, a
	extz wa
	div a, 0xC
	ld l, w
	ld e, l
	extz de
	ldda8 a, 52959
	dec 1, a
	extz wa
	muls wa, 0xC
	lda_24 xbc, 0xee98fe
	exts xwa
	add xwa, xbc
	ld_srib3 C, 0x07, 0xE0, 0xE8
	ldda8 a, 52906
	sub a, c
	ld (xiz + 5), a
	ldw (xiz), 0x1
	jr LABEL_FE8F06

LABEL_FE8F02:
	ldw (xiz), 0x0

LABEL_FE8F06:
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
	cp a, 0xFF
	jr z, LABEL_FE8F9D
	ldda8 a, 52906
	subda8 a, 52960
	add a, l
	inc 1, a
	ld l, a
	extz wa
	div a, 0xC
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
	ld_srib3 C, 0x07, 0xE0, 0xE8
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
	st_dri3b W, 0x07, 0xE0, 0xE8
	ld c, (xwa + 1)
	ldda8 a, 52906
	sub a, c
	ld (xiz + 7), a
	ldw (xiz), 0x2
	jr LABEL_FE8FA1

LABEL_FE8F9D:
	ldw (xiz), 0x0

LABEL_FE8FA1:
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
	cp a, 0xFF
	jrl z, LABEL_FE906D
	ldda8 a, 52906
	subda8 a, 52960
	add a, l
	inc 1, a
	ld l, a
	extz wa
	div a, 0xC
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
	ld_srib3 C, 0x07, 0xE0, 0xE8
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
	st_dri3b W, 0x07, 0xE0, 0xE8
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
	st_dri3b W, 0x07, 0xE0, 0xE8
	ld c, (xwa + 2)
	ldda8 a, 52906
	sub a, c
	ld (xiz + 9), a
	ldw (xiz), 0x3
	jr LABEL_FE9071

LABEL_FE906D:
	ldw (xiz), 0x0

LABEL_FE9071:
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
	cp a, 0xFF
	jrl z, LABEL_FE9169
	ldda8 a, 52906
	subda8 a, 52960
	add a, l
	inc 1, a
	ld l, a
	extz wa
	div a, 0xC
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
	ld_srib3 C, 0x07, 0xE0, 0xE8
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
	st_dri3b W, 0x07, 0xE0, 0xE8
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
	st_dri3b W, 0x07, 0xE0, 0xE8
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
	st_dri3b W, 0x07, 0xE0, 0xE8
	ld c, (xwa + 3)
	ldda8 a, 52906
	sub a, c
	ld (xiz + 11), a
	ldw (xiz), 0x4
	jr LABEL_FE916D

LABEL_FE9169:
	ldw (xiz), 0x0

LABEL_FE916D:
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
	cp a, 0xFF
	jrl z, LABEL_FE9239
	ldda8 a, 52906
	subda8 a, 52960
	add a, l
	inc 1, a
	ld l, a
	extz wa
	div a, 0xC
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
	ld_srib3 C, 0x07, 0xE0, 0xE8
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
	st_dri3b W, 0x07, 0xE0, 0xE8
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
	st_dri3b W, 0x07, 0xE0, 0xE8
	ld c, (xwa + 2)
	ldda8 a, 52906
	sub a, c
	ld (xiz + 9), a
	ldw (xiz), 0x3
	jr LABEL_FE923D

LABEL_FE9239:
	ldw (xiz), 0x0

LABEL_FE923D:
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
	cp a, 0xFF
	jrl z, LABEL_FE9335
	ldda8 a, 52906
	subda8 a, 52960
	add a, l
	inc 1, a
	ld l, a
	extz wa
	div a, 0xC
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
	ld_srib3 C, 0x07, 0xE0, 0xE8
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
	st_dri3b W, 0x07, 0xE0, 0xE8
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
	st_dri3b W, 0x07, 0xE0, 0xE8
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
	st_dri3b W, 0x07, 0xE0, 0xE8
	ld c, (xwa + 3)
	ldda8 a, 52906
	sub a, c
	ld (xiz + 11), a
	ldw (xiz), 0x4
	jr LABEL_FE9339

LABEL_FE9335:
	ldw (xiz), 0x0

LABEL_FE9339:
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
	ldb l, 0xFF
	cps a, 7
	jr z, LABEL_FE93DD
	cps a, 4
	jr z, LABEL_FE93B6
	cps a, 0
	jr nz, LABEL_FE9410
	jr Audio_NullRet1

LABEL_FE93B6:
	cps c, 1
	jr nc, LABEL_FE93BE
	cps c, 4
	jr ugt, LABEL_FE93C2

LABEL_FE93BE:
	ldb l, 0x0
	jr Audio_NullRet1

LABEL_FE93C2:
	cps c, 5
	jr nc, LABEL_FE93CB
	cp c, 0x8
	jr ugt, LABEL_FE93CF

LABEL_FE93CB:
	ldb l, 0x4
	jr Audio_NullRet1

LABEL_FE93CF:
	cp c, 0x9
	jr nc, LABEL_FE93D9
	cp c, 0xC
	ret ugt

LABEL_FE93D9:
	ldb l, 0x8
	jr Audio_NullRet1

LABEL_FE93DD:
	cps c, 1
	jr nc, LABEL_FE93E5
	cps c, 3
	jr ugt, LABEL_FE93E9

LABEL_FE93E5:
	ldb l, 0x0
	jr Audio_NullRet1

LABEL_FE93E9:
	cps c, 4
	jr nc, LABEL_FE93F1
	cps c, 6
	jr ugt, LABEL_FE93F5

LABEL_FE93F1:
	ldb l, 0x3
	jr Audio_NullRet1

LABEL_FE93F5:
	cps c, 7
	jr nc, LABEL_FE93FE
	cp c, 0x9
	jr ugt, LABEL_FE9402

LABEL_FE93FE:
	ldb l, 0x6
	jr Audio_NullRet1

LABEL_FE9402:
	cp c, 0xA
	jr nc, LABEL_FE940C
	cp c, 0xC
	ret ugt

LABEL_FE940C:
	ldb l, 0x9
	jr Audio_NullRet1

LABEL_FE9410:
	ldb l, 0x0

Audio_NullRet1:
	ret

LABEL_FE9413:
	.byte 0x1b, 0x71, 0x96, 0xfe, 0x0e, 0x00, 0x00, 0x00
	.byte 0x0e, 0x00, 0x00, 0x00, 0x0e, 0x00, 0x00, 0x00
	.byte 0x0e, 0x00, 0x00, 0x00, 0x0e, 0x00, 0x00, 0x00
	.byte 0x0e

LABEL_FE942C:
	cpdi8 52917, 0
	jr z, LABEL_FE9439
	decdi8 1, 52917
	jr z, Voice_CheckAndUpdateMode

LABEL_FE9439:
	cpdi8 52916, 0
	jr z, LABEL_FE9446
	decdi8 1, 52916
	jr z, Voice_CheckAndUpdateMode

LABEL_FE9446:
	cpdi8 52915, 0
	jr z, Voice_ProcessControllers_Return
	decdi8 1, 52915
	jr z, Voice_CheckAndUpdateMode

Voice_CheckAndUpdateMode:
	ldda16 xde, 50582
	and de, 0x2000
	jr nz, Voice_ProcessControllers_Return
	call Voice_UpdatePlayModeState
	cp l, 0xFF
	jr z, Voice_ProcessControllers_Return
	call LABEL_FE12B8

Voice_ProcessControllers_Return:
	ret

LABEL_FE946B:
	push xix
	push xiz
	push xde
	ldda16 xde, 50582
	and de, 0x2000
	jr nz, LABEL_FE94CC
	cpdi16_24 52993, 2
	jr z, LABEL_FE948C
	cpdi16_24 52993, 3
	jr z, LABEL_FE948C
	jr LABEL_FE949E

LABEL_FE948C:
	ldda16 xde, 50584
	and de, 0x20
	jr z, LABEL_FE94A6
	ordi8_24 52958, 64
	jr LABEL_FE94A6

LABEL_FE949E:
	anddi8_24 52958, 191
	jr __jrt_nop_FE94A6
__jrt_nop_FE94A6:

LABEL_FE94A6:
	calr LABEL_FE9528
	calr LABEL_FEA502
	anddi8_24 52958, 191
	ld16_24 xhl, 0x00cf01
	anddi16_24 52993, 255
	cp h, 0xFF
	jr z, LABEL_FE94C8
	ldw hl, 0xFF
	jr LABEL_FE94CC

LABEL_FE94C8:
	ldb h, 0x0
	jr __jrt_nop_FE94CC
__jrt_nop_FE94CC:

LABEL_FE94CC:
	pop xde
	pop xiz
	pop xix
	ret

Voice_UpdatePlayModeState:
	push xix
	push xiz
	push xde
	cpdi16_24 52993, 2
	jr z, LABEL_FE94E7
	cpdi16_24 52993, 3
	jr z, LABEL_FE94E7
	jr LABEL_FE94F9

LABEL_FE94E7:
	ldda16 xde, 50584
	and de, 0x20
	jr z, LABEL_FE9501
	ordi8_24 52958, 64
	jr LABEL_FE9501

LABEL_FE94F9:
	anddi8_24 52958, 191
	jr __jrt_nop_FE9501
__jrt_nop_FE9501:

LABEL_FE9501:
	calr Voice_CheckAndResetSlotState
	anddi8_24 52958, 191
	ld16_24 xhl, 0x00cf01
	anddi16_24 52993, 255
	cp h, 0xFF
	jr z, LABEL_FE9520
	ldw hl, 0xFF
	jr LABEL_FE9524

LABEL_FE9520:
	ldb h, 0x0
	jr __jrt_nop_FE9524
__jrt_nop_FE9524:

LABEL_FE9524:
	pop xde
	pop xiz
	pop xix
	ret

LABEL_FE9528:
	ld16_24 xbc, 0x00ceff
	cps bc, 0
	jr z, LABEL_FE953A
	bitda_24 0, 52958
	jr nz, LABEL_FE953A
	jr LABEL_FE953F

LABEL_FE953A:
	calr Voice_CheckAndResetSlotState
	jr Voice_AdjustTiming_Return

LABEL_FE953F:
	bitda_24 6, 52958
	jr z, LABEL_FE954B
	calr Voice_CheckAndResetSlotState
	jr Voice_AdjustTiming_Return

LABEL_FE954B:
	bitda_24 7, 52958
	jr z, LABEL_FE9557
	calr Voice_UpdateVelocity_Entry
	jr Voice_AdjustTiming_Return

LABEL_FE9557:
	cpda16 xbc, 53015
	jr c, LABEL_FE9562
	calr Voice_UpdateVelocity_Entry
	jr Voice_AdjustTiming_Return

LABEL_FE9562:
	cpda16 xbc, 53015
	jr ugt, LABEL_FE956D
	calr LABEL_FE95C5
	jr Voice_AdjustTiming_Return

LABEL_FE956D:
	calr LABEL_FE95E0

Voice_AdjustTiming_Return:
	ret

Voice_UpdateVelocity_Entry:
	bitda_24 6, 52958
	jr nz, Voice_CheckAndUpdateSlot
	cpdi16 53015, 0
	jr z, LABEL_FE959A
	bitda_24 7, 52958
	jr z, LABEL_FE9591
	ldda16 xde, 50582
	and de, 0x2
	jr nz, Voice_CheckAndUpdateSlot

LABEL_FE9591:
	bitda_24 4, 52958
	jr z, Voice_CheckAndUpdateSlot
	jr LABEL_FE95B3

LABEL_FE959A:
	ldda16 xde, 50582
	and de, 0x2
	jr z, Voice_CheckAndUpdateSlot
	bitda_24 4, 52958
	jr z, Voice_CheckAndUpdateSlot
	cpi8_24 0x00cee0, 0x00
	jr z, Voice_CheckAndUpdateSlot

LABEL_FE95B3:
	cpdi8 52915, 0
	jr nz, LABEL_FE95C4
	stdi8 52915, 5
	jr LABEL_FE95C4

Voice_CheckAndUpdateSlot:
	calr Voice_CheckAndResetSlotState

LABEL_FE95C4:
	ret

LABEL_FE95C5:
	ldda16 xde, 50582
	and de, 0x2
	jr z, LABEL_FE95D3
	cps bc, 2
	jr ule, LABEL_FE95DA

LABEL_FE95D3:
	stdi8 52916, 6
	jr LABEL_FE95DF

LABEL_FE95DA:
	stdi8 52916, 22

LABEL_FE95DF:
	ret

LABEL_FE95E0:
	ld xiy, 0xCEFF
	ld bc, (xiy + 256)
	ld xix, 0xCF17

LABEL_FE95ED:
	ld de, (xix + 256)
	ld w, (xiy + 5)

LABEL_FE95F3:
	cp w, (xix + 5)
	jr z, LABEL_FE9603
	inc 2, ix
	dec 1, de
	jr nz, LABEL_FE95F3
	calr Voice_UpdateVelocity_Entry
	jr LABEL_FE9608

LABEL_FE9603:
	inc 2, iy
	djnz xbc, LABEL_FE95ED

LABEL_FE9608:
	ret

Voice_CheckAndResetSlotState:
	ld16_24 xbc, 0x00ceff
	stdi8 52915, 0
	stdi8 52916, 0
	cps bc, 0
	jr z, LABEL_FE9621
	calr LABEL_FE96B4
	jr Voice_NullRet2

LABEL_FE9621:
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
	jr nz, LABEL_FE9650
	bitda_24 6, 52958
	jr nz, LABEL_FE966B

LABEL_FE9650:
	ldda16 xde, 50584
	and de, 0x2
	jr nz, LABEL_FE9661
	bitda_24 6, 52958
	jr nz, LABEL_FE966B

LABEL_FE9661:
	ldda16 xde, 50582
	and de, 0x10
	jr nz, Voice_NullRet2

LABEL_FE966B:
	calr LABEL_FE9671
	jr __jrt_nop_FE9670
__jrt_nop_FE9670:

Voice_NullRet2:
	ret

LABEL_FE9671:
	sti16_24 0x00ceff, 0x0000
	sti8_24 0x00cee5, 0x00
	sti8_24 0x00cef1, 0x00
	sti8_24 0x00cee0, 0x00
	sti8_24 0x00cedf, 0x00
	ordi8_24 52958, 128
	anddi8_24 52958, 249
	sti8_24 0x00cee1, 0x00
	sti8_24 0x00cee4, 0x00
	calr LABEL_FEA044
	ret

LABEL_FE96AC:
	.byte 0x00, 0x0c, 0x18, 0x24, 0x00, 0xdc, 0xe8, 0xf4

LABEL_FE96B4:
	bitda_24 6, 52958
	jr nz, EffectState_Dispatch
	ldda16 xde, 50582
	and de, 0x1
	jr nz, LABEL_FE96E5
	ldda16 xde, 50582
	and de, 0x2
	jr nz, EffectState_Dispatch
	ldda16 xde, 50584
	and de, 0x2
	jr nz, EffectState_Dispatch
	ldda16 xde, 50582
	and de, 0x4
	jr nz, LABEL_FE96EF
	jr EffectState_Dispatch

LABEL_FE96E5:
	calr LABEL_FE96F6
	jr LABEL_FE96F2

EffectState_Dispatch:
	calr LABEL_FE9956
	jr LABEL_FE96F2

LABEL_FE96EF:
	calr LABEL_FE9A9C

LABEL_FE96F2:
	calr LABEL_FEA044
	ret

LABEL_FE96F6:
	sti8_24 0x00cee5, 0x04
	ld16_24 xde, 0x00ceff
	calr LABEL_FE9720
	calr LABEL_FE97AD
	jr __jrt_nop_FE9709
__jrt_nop_FE9709:

LABEL_FE9709:
	st8_24 0x00cedf, a
	st8_24 0x00cee0, w
	sti8_24 0x00cee1, 0x00
	anddi8_24 52958, 249
	ret

LABEL_FE9720:
	sti16_24 0x00cf2f, 0x0000
	ld xiy, 0xCEFF
	ld xix, 0xCF8F
	ld hl, de
	dec 1, hl
	sla hl, 1
	add iy, hl
	cps de, 0
	jr nz, LABEL_FE9746
	sti8_24 0x00cee5, 0x00
	jr LABEL_FE97AC

LABEL_FE9746:
	xor wa, wa
	ldfr_werp WA, 0x30
	xor b, b
	xor h, h

LABEL_FE974F:
	ld l, (xiy + 5)
	ld xiz, 0xFEA356
	ld_srib3 C, 0x03, 0xF8, 0xEC
	ldto_werp WA, 0x30
	ld xiz, 0xFEA514
	and_sriw_rm WA, 0x03, 0xF8, 0xE4
	jr nz, LABEL_FE9780
	or_sriw_rm WA, 0x03, 0xF8, 0xE4
	ldfr_werp WA, 0x30
	ld (xix), l
	inc 1, ix
	inc 1, b
	cpda8_24 b, 52965
	jr nc, LABEL_FE978A

LABEL_FE9780:
	dec 1, iy
	dec 1, iy
	dec 1, de
	cps de, 0
	jr nz, LABEL_FE974F

LABEL_FE978A:
	st8_24 0x00cee5, b
	ld c, b
	xor b, b
	ld xix, 0xCEE6
	ld xiy, 0xCF8F
	add iy, bc
	dec 1, iy

LABEL_FE97A1:
	ld a, (xiy)
	ld (xix), a
	dec 1, iy
	inc 1, ix
	djnz xbc, LABEL_FE97A1

LABEL_FE97AC:
	ret

LABEL_FE97AD:
	ld xiy, 0xCEFF
	ld16_24 xbc, 0x00ceff
	xor a, a
	xor h, h
	cps bc, 0
	jr z, LABEL_FE97E4

LABEL_FE97BF:
	ld l, (xiy + 5)
	cpda8_24 l, 52966
	jr z, LABEL_FE97DF
	ld xiz, 0xFEA356
	ld_srib3 L, 0x07, 0xF8, 0xEC
	dec 1, hl
	ld xiz, 0xFE980C
	or_srib_rm A, 0x07, 0xF8, 0xEC

LABEL_FE97DF:
	inc 2, iy
	djnz xbc, LABEL_FE97BF

LABEL_FE97E4:
	ld l, a
	ld xiz, 0xFE9818
	ld_srib3 A, 0x07, 0xF8, 0xEC
	ld8_24 l, 0x00cee6
	ld xiz, 0xFEA356
	ld_srib3 W, 0x07, 0xF8, 0xEC
	anddi8_24 52958, 127
	anddi8_24 52958, 239
	ret

LABEL_FE980C:
	.byte 0x01, 0x02, 0x01, 0x02, 0x01, 0x01, 0x02, 0x01
	.byte 0x02, 0x01, 0x02, 0x01, 0x01, 0x02, 0x05, 0x06

Voice_ComputeNoteBitPosition:
	ld l, c
	xor h, h
	dec 1, hl
	ld xiz, 0xCEE6
	ld_srib3 W, 0x07, 0xF8, 0xEC
	ld c, b
	xor b, b
	dec 1, bc
	ld iy, hl
	dec 1, iy
	xor de, de

LABEL_FE9838:
	pushw bc
	ld xiz, 0xCEE6
	ld_srib3 L, 0x07, 0xF8, 0xF4
	sub l, w
	ld xiz, 0xFEA356
	ld_srib3 A, 0x07, 0xF8, 0xEC
	dec 1, a
	ldb c, 0xB
	sub c, a
	ldfr_berp A, 0x3C
	ld a, c
	scf
	stcf_a_16 de
	ldto_berp A, 0x3C
	popw bc
	dec 1, iy
	djnz xbc, LABEL_FE9838
	or de, 0x800
	ret

LABEL_FE986B:
	.byte 0xd9, 0x69, 0xda, 0xd2, 0xdb, 0xd3, 0xdd, 0xd5
	.byte 0xd8, 0xd0, 0x29, 0x46, 0xe6, 0xce, 0x00, 0x00
	.byte 0x86, 0x27, 0xc3, 0x07, 0xf8, 0xf4, 0x20, 0xce
	.byte 0xa7, 0xce, 0xd6, 0x46, 0x56, 0xa3, 0xfe, 0x00
	.byte 0xc3, 0x07, 0xf8, 0xec, 0x23, 0xcb, 0x69, 0xc7
	.byte 0x3c, 0x99, 0xcb, 0x89, 0x11, 0xda, 0x2c, 0xc7
	.byte 0x3c, 0x89, 0xcb, 0xf1, 0x6f, 0x02, 0xcb, 0x89
	.byte 0x49, 0xdd, 0x61, 0xd9, 0x1c, 0xcc, 0xda, 0xce
	.byte 0x01, 0x00, 0x23, 0x0b, 0xc9, 0xa3, 0xcb, 0xb9
	.byte 0xda, 0xfc, 0xcb, 0xb9, 0x0e

LABEL_FE98B8:
	stda16 52989, xde
	ld8_24 c, 0x00cee5
	xor b, b

LABEL_FE98C3:
	ldfr_werp DE, 0x3C
	and de, 0x600
	ldto_werp DE, 0x3C
	jr nz, LABEL_FE98E3
	ld hl, de
	and hl, 0x1FF
	ld xiz, 0xEEBE44
	ld_srib3 A, 0x07, 0xF8, 0xEC
	cps a, 0
	jr nz, Voice_PitchCalcStep

LABEL_FE98E3:
	bit 9, de
	jr z, Voice_DecrementCounter
	cpda8_24 c, 52965
	jr nz, Voice_DecrementCounter
	ld hl, de
	and hl, 0x1FF
	ld xiz, 0xEEBE44
	ld_srib3 A, 0x07, 0xF8, 0xEC
	cps a, 1
	jr nz, LABEL_FE9907
	ldb a, 0x28
	jr Voice_PitchCalcStep

LABEL_FE9907:
	cps a, 5
	jr nz, Voice_DecrementCounter
	ldb a, 0x29
	jr Voice_PitchCalcStep

Voice_DecrementCounter:
	dec 1, c
	cps c, 0
	jr z, LABEL_FE994F
	jr __jrt_nop_FE9917
__jrt_nop_FE9917:

LABEL_FE9917:
	inc 1, b
	sla de, 1
	bit 12, de
	jr nz, LABEL_FE9928

LABEL_FE9921:
	bit 11, de
	jr z, LABEL_FE9917
	jr LABEL_FE98C3

LABEL_FE9928:
	or de, 0x1
	jr LABEL_FE9921

Voice_PitchCalcStep:
	ld8_24 l, 0x00cee5
	dec 1, l
	xor h, h
	ld xiz, 0xCEE6
	ld_srib3 L, 0x07, 0xF8, 0xEC
	add l, b
	ld xiz, 0xFEA356
	ld_srib3 W, 0x07, 0xF8, 0xEC
	jr LABEL_FE9955

LABEL_FE994F:
	ldb a, 0x0
	ldb w, 0x0
	jr __jrt_nop_FE9955
__jrt_nop_FE9955:

LABEL_FE9955:
	ret

LABEL_FE9956:
	sti8_24 0x00cee5, 0x04
	ld16_24 xde, 0x00ceff
	calr LABEL_FE9720
	cpi8_24 0x00cee5, 0x02
	jr ugt, LABEL_FE996E
	jr LABEL_FE9984

LABEL_FE996E:
	calr Voice_UpdateNoteBitmap
	cps w, 0
	jr nz, LABEL_FE9989
	decdi8_24 1, 52965
	calr Voice_UpdateNoteBitmap
	incdi8_24 1, 52965
	jr LABEL_FE9989

LABEL_FE9984:
	calr LABEL_FE9A42
	jr __jrt_nop_FE9989
__jrt_nop_FE9989:

LABEL_FE9989:
	cps w, 0
	jr nz, LABEL_FE9999
	ld8_24 a, 0x00cee2
	ld8_24 w, 0x00cee3
	jr LABEL_FE99D0

LABEL_FE9999:
	bitda_24 6, 52958
	jr nz, LABEL_FE99B2
	ldfr_werp DE, 0x3E
	ldda16 xde, 50582
	and de, 0x8
	ldto_werp DE, 0x3E
	jr nz, LABEL_FE99DA
	jr LABEL_FE99D5

LABEL_FE99B2:
	ld8_24 l, 0x00cee5
	xor h, h
	dec 1, hl
	ld xiz, 0xCEE6
	ld d, (xiz)
	ld_srib3 E, 0x07, 0xF8, 0xEC
	sub d, e
	cp d, 0xC
	jr nc, LABEL_FE99DA
	jr LABEL_FE99D5

LABEL_FE99D0:
	calr NoteDisplay_ClearAndSetUpdate
	jr LABEL_FE99DD

LABEL_FE99D5:
	calr NoteDisplay_InitState
	jr LABEL_FE99DD

LABEL_FE99DA:
	calr NoteDisplay_LookupBitmap

LABEL_FE99DD:
	ret

Voice_UpdateNoteBitmap:
	push xix
	push xiz
	ld8_24 c, 0x00cee5
	ld b, c
	calr Voice_ComputeNoteBitPosition
	ld xiy, 0xEEBE44
	calr LABEL_FE98B8
	cps a, 0
	jr z, LABEL_FE9A04
	ordi8_24 52958, 16
	anddi8_24 52958, 127
	jr LABEL_FE9A0A

LABEL_FE9A04:
	ldb a, 0x0
	ldb w, 0x0
	jr __jrt_nop_FE9A0A
__jrt_nop_FE9A0A:

LABEL_FE9A0A:
	ld l, a
	extz hl
	pop xiz
	pop xix
	ret

LABEL_FE9A11:
	.byte 0xc2, 0xe5, 0xce, 0x00, 0x23, 0xcb, 0x8a, 0x1e
	.byte 0x01, 0xfe, 0x45, 0x44, 0xbe, 0xee, 0x00, 0x1e
	.byte 0x95, 0xfe, 0xc9, 0xd8, 0x66, 0x14, 0xc2, 0xde
	.byte 0xce, 0x00, 0x3e, 0x10, 0xc2, 0xde, 0xce, 0x00
	.byte 0x3c, 0x7f, 0xc2, 0xde, 0xce, 0x00, 0x3c, 0xf9
	.byte 0x68, 0x06, 0x21, 0x00, 0x20, 0x00, 0x68, 0x00
	.byte 0x0e

LABEL_FE9A42:
	cpi8_24 0x00cee0, 0x00
	jr z, LABEL_FE9A50
	ldb a, 0x0
	ldb w, 0x0
	jr LABEL_FE9A63

LABEL_FE9A50:
	ldb a, 0x1
	ld8_24 l, 0x00cee6
	xor h, h
	ld xiz, 0xFEA356
	ld_srib3 W, 0x07, 0xF8, 0xEC

LABEL_FE9A63:
	anddi8_24 52958, 127
	ordi8_24 52958, 16
	ret

LABEL_FE9A70:
	.byte 0x21, 0x01, 0xc2, 0xe5, 0xce, 0x00, 0x27, 0xce
	.byte 0xd6, 0xdb, 0x69, 0x46, 0xe6, 0xce, 0x00, 0x00
	.byte 0xc3, 0x07, 0xf8, 0xec, 0x27, 0x46, 0x56, 0xa3
	.byte 0xfe, 0x00, 0xc3, 0x07, 0xf8, 0xec, 0x20, 0xc2
	.byte 0xde, 0xce, 0x00, 0x3e, 0x10, 0xc2, 0xde, 0xce
	.byte 0x00, 0x3c, 0x7f, 0x0e

LABEL_FE9A9C:
	calr LABEL_FE9B49
	ld16_24 xwa, 0x00cf2f
	addda8_24 a, 52965
	cps a, 2
	jr ugt, LABEL_FE9AB0
	jrl Audio_NullRet2

LABEL_FE9AB0:
	bitda_24 1, 52958
	jr nz, LABEL_FE9B2B
	calr Voice_LookupNoteAndComputePitch
	cps w, 0
	jr nz, LABEL_FE9AFA
	ld8_24 l, 0x00cee5
	xor h, h
	dec 1, hl
	extz hl
	ld xiz, 0xCEE6
	add xiz, xhl
	ld c, (xiz)
	ldfr_lerp XIZ, 0x30
	ldfr_berp C, 0x34
	ld8_24 a, 0x00cee5
	dec 1, a
	cps a, 2
	jr ugt, LABEL_FE9AE5
	jr Audio_NullRet2

LABEL_FE9AE5:
	decdi8_24 1, 52965
	calr Voice_LookupNoteAndComputePitch
	incdi8_24 1, 52965
	ldto_berp C, 0x34
	ldto_lerp XIZ, 0x30
	ld (xiz), c

LABEL_FE9AFA:
	cps w, 0
	jr nz, LABEL_FE9B0A
	ld8_24 a, 0x00cee2
	ld8_24 w, 0x00cee3
	jr LABEL_FE9B1C

LABEL_FE9B0A:
	ldfr_werp DE, 0x3E
	ldda16 xde, 50582
	and de, 0x8
	ldto_werp DE, 0x3E
	jr nz, LABEL_FE9B26
	jr LABEL_FE9B21

LABEL_FE9B1C:
	calr NoteDisplay_ClearAndSetUpdate
	jr Audio_NullRet2

LABEL_FE9B21:
	calr NoteDisplay_InitState
	jr Audio_NullRet2

LABEL_FE9B26:
	calr NoteDisplay_LookupBitmap
	jr Audio_NullRet2

LABEL_FE9B2B:
	calr LABEL_FE9E91
	cps a, 0
	jr z, LABEL_FE9B37
	calr LABEL_FEA016
	jr Audio_NullRet2

LABEL_FE9B37:
	calr Voice_LookupNoteAndComputePitch
	cps a, 0
	jr z, LABEL_FE9B43
	calr NoteDisplay_LookupBitmap
	jr Audio_NullRet2

LABEL_FE9B43:
	calr NoteDisplay_ClearAndSetUpdate
	jr __jrt_nop_FE9B48
__jrt_nop_FE9B48:

Audio_NullRet2:
	ret

LABEL_FE9B49:
	push xiz
	ld xiy, 0xCEFF
	ld16_24 xhl, 0x00ceff
	extz xhl
	dec 1, xhl
	sla xhl, 1
	ld xiz, xiy
	add xiz, xhl
	ld a, (xiz + 3)
	sub a, (xiz + 5)
	cp a, 0xC
	jr z, LABEL_FE9BA1
	cp a, 0x8
	jr nc, LABEL_FE9B71
	jr Voice_ProcessSlotEntry

LABEL_FE9B71:
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

LABEL_FE9BA1:
	ld xiz, xiy
	add xiz, xhl
	ld a, (xiz + 1)
	sub a, (xiz + 3)
	cp a, 0x8
	jr c, LABEL_FE9B71
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
	jr c, LABEL_FE9C40
	ldfr_werp DE, 0x3E
	ldda16 xde, 50582
	and de, 0x200
	ldto_werp DE, 0x3E
	jr z, LABEL_FE9C1A
	sti16_24 0x00cf2f, 0x0000
	anddi8_24 52958, 253
	sti8_24 0x00cee5, 0x07
	ld16_24 xde, 0x00ceff
	calr VoiceSlot_CheckPitchIntervals
	calr LABEL_FE9D39
	jr Audio_PopIzRet

LABEL_FE9C1A:
	sti16_24 0x00cf2f, 0x0000
	anddi8_24 52958, 253
	sti8_24 0x00cee1, 0x00
	sti8_24 0x00cee5, 0x07
	ld16_24 xde, 0x00ceff
	calr VoiceSlot_CheckPitchIntervals
	calr LABEL_FE9D39
	jr Audio_PopIzRet

LABEL_FE9C40:
	sti8_24 0x00cee5, 0x00

Audio_PopIzRet:
	pop xiz
	ret

VoiceSlot_CheckPitchIntervals:
	push xiz
	cps de, 0
	jr nz, LABEL_FE9C56
	sti8_24 0x00cee5, 0x00
	jrl LABEL_FE9D1C

LABEL_FE9C56:
	ld xiy, 0xCEFF
	xor xhl, xhl
	lds bc, 1
	cps de, 3
	jr ule, LABEL_FE9C81
	ld bc, de
	sub bc, 0x3

LABEL_FE9C69:
	ld xiz, xiy
	add xiz, xhl
	ld a, (xiz + 5)
	sub a, (xiz + 7)
	add hl, 0x2
	cp a, 0x8
	jr ugt, LABEL_FE9C81
	djnz xbc, LABEL_FE9C69
	xor hl, hl

LABEL_FE9C81:
	cps hl, 0
	jr nz, LABEL_FE9C8D
	anddi8_24 52958, 223
	jr NoteBuffer_CompactEntries

LABEL_FE9C8D:
	cps hl, 2
	jr nz, LABEL_FE9C9E
	stdi8 52917, 2
	ordi8_24 52958, 32
	jr NoteBuffer_CompactEntries

LABEL_FE9C9E:
	cps hl, 4
	jr nz, LABEL_FE9CBA
	bitda_24 5, 52958
	jr z, LABEL_FE9CB0
	cpdi8 52917, 0
	jr z, NoteBuffer_CompactEntries

LABEL_FE9CB0:
	xor hl, hl
	anddi8_24 52958, 223
	jr NoteBuffer_CompactEntries

LABEL_FE9CBA:
	xor hl, hl
	anddi8_24 52958, 223
	jr __jrt_nop_FE9CC4
__jrt_nop_FE9CC4:

NoteBuffer_CompactEntries:
	ld xix, 0xCF8F
	ld xiy, 0xCEFF
	ld wa, de
	dec 1, wa
	sla wa, 1
	add iy, wa
	srl hl, 1
	sub de, hl
	xor b, b
	xor h, h

LABEL_FE9CE0:
	ld l, (xiy + 5)
	ld (xix), l
	inc 1, ix
	inc 1, b
	cpda8_24 b, 52965
	jr nc, LABEL_FE9CFA
	dec 1, iy
	dec 1, iy
	dec 1, de
	cps de, 0
	jr nz, LABEL_FE9CE0

LABEL_FE9CFA:
	st8_24 0x00cee5, b
	ld c, b
	xor b, b
	ld xix, 0xCEE6
	ld xiy, 0xCF8F
	add iy, bc
	dec 1, iy

LABEL_FE9D11:
	ld a, (xiy)
	ld (xix), a
	dec 1, iy
	inc 1, ix
	djnz xbc, LABEL_FE9D11

LABEL_FE9D1C:
	pop xiz
	ret

LABEL_FE9D1E:
	.byte 0x8d, 0x05, 0x20, 0xc9, 0xa0, 0xc8, 0xcf, 0x0c
	.byte 0x6b, 0x08, 0xc2, 0xde, 0xce, 0x00, 0x3c, 0xf7
	.byte 0x68, 0x08, 0xc2, 0xde, 0xce, 0x00, 0x3e, 0x08
	.byte 0x68, 0x00, 0x0e

LABEL_FE9D39:
	cpi8_24 0x00cee4, 0x00
	jr z, NoteBuffer_NullRet
	cpdi16_24 53039, 0
	jr nz, NoteBuffer_NullRet
	ld16_24 xwa, 0x00cf33
	ld16_24 xbc, 0x00ceff
	ld xiy, 0xCEFF

LABEL_FE9D59:
	cp wa, (xiy + 4)
	jr nz, LABEL_FE9D60
	jr NoteBuffer_NullRet

LABEL_FE9D60:
	inc 2, iy
	djnz xbc, LABEL_FE9D59
	ld8_24 l, 0x00cee5
	xor h, h
	dec 1, hl
	ld xiz, 0xCEE6
	ld_srib3 A, 0x07, 0xF8, 0xEC
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
	and xhl, 0x7FF
	sla hl, 1
	ld xiz, 0xEEAE44
	add xiz, xhl
	ld a, (xiz)
	ld w, (xiz + 1)
	bit 7, w
	jr z, LABEL_FE9DBE
	and w, 0x7F
	jrl LABEL_FE9E63

LABEL_FE9DBE:
	cpdi16_24 53039, 0
	jr nz, LABEL_FE9E2F
	ld8_24 c, 0x00cee5
	ldb b, 0x3

LABEL_FE9DCE:
	pushw bc
	calr Voice_ComputeNoteBitPosition
	ld hl, de
	and hl, 0x7FF
	sla hl, 1
	ld xiz, 0xEEAE44
	add xiz, xhl
	ld a, (xiz)
	ld w, (xiz + 1)
	and w, 0x7F
	popw bc
	cps a, 0
	jr nz, LABEL_FE9DFA
	cpda8_24 b, 52965
	jr nc, LABEL_FE9E2F
	inc 1, b
	jr LABEL_FE9DCE

LABEL_FE9DFA:
	ld8_24 l, 0x00cee5
	xor h, h
	dec 1, hl
	ld xiz, 0xCEE6
	ld_srib3 L, 0x07, 0xF8, 0xEC
	add l, w
	ld xiz, 0xFEA356
	ld_srib3 W, 0x07, 0xF8, 0xEC
	dec 1, w
	ld8_24 l, 0x00cee5
	ld xiz, 0xCEE6
	lda_dri3 XWA, 0x07, 0xF8, 0xEC
	incdi8_24 1, 52965

LABEL_FE9E2F:
	ld8_24 l, 0x00cee5
	ld h, l

LABEL_FE9E36:
	ld c, l
	ld b, h
	push xhl
	calr Voice_ComputeNoteBitPosition
	ld hl, de
	and hl, 0x7FF
	sla hl, 1
	ld xiz, 0xEEAE44
	add xiz, xhl
	ld a, (xiz)
	ld w, (xiz + 1)
	and w, 0x7F
	pop xhl
	cps a, 0
	jr nz, LABEL_FE9E63
	dec 1, h
	cps h, 4
	jr c, LABEL_FE9E84
	jr LABEL_FE9E36

LABEL_FE9E63:
	ld8_24 l, 0x00cee5
	dec 1, l
	xor h, h
	ld xiz, 0xCEE6
	ld_srib3 L, 0x07, 0xF8, 0xEC
	add l, w
	ld xiz, 0xFEA356
	ld_srib3 W, 0x07, 0xF8, 0xEC
	jr LABEL_FE9E8A

LABEL_FE9E84:
	ldb a, 0x0
	ldb w, 0x0
	jr __jrt_nop_FE9E8A
__jrt_nop_FE9E8A:

LABEL_FE9E8A:
	popw bc
	st8_24 0x00cee5, c
	ret

LABEL_FE9E91:
	ld8_24 l, 0x00cee5
	xor h, h
	ld8_24 a, 0x00cf34
	ld xiz, 0xCEE6
	lda_dri3 XBC, 0x07, 0xF8, 0xEC
	ld bc, hl
	inc 1, bc
	ld b, c
	calr Voice_ComputeNoteBitPosition
	ld hl, de
	and hl, 0x7FF
	sla hl, 1
	ld xiz, 0xEEAE44
	ld_srib3 A, 0x07, 0xF8, 0xEC
	cps a, 0
	jr z, Voice_ZeroInitConverge
	ld xiz, 0xEEAE44
	add xiz, xhl
	ld w, (xiz + 1)
	and w, 0x7F
	bit 5, w
	jr nz, Voice_ZeroInitConverge
	cps w, 0
	jr nz, Voice_ZeroInitConverge
	ld8_24 l, 0x00cf34
	add l, w
	xor h, h
	ld xiz, 0xFEA356
	ld_srib3 W, 0x07, 0xF8, 0xEC
	jr LABEL_FE9EF8

Voice_ZeroInitConverge:
	ldb a, 0x0
	ldb w, 0x0
	jr __jrt_nop_FE9EF8
__jrt_nop_FE9EF8:

LABEL_FE9EF8:
	ret

NoteDisplay_ClearAndSetUpdate:
	push xix
	push xiz
	cpi8_24 0x00cee1, 0x00
	jr nz, LABEL_FE9F15
	anddi8_24 52958, 249
	ordi8_24 52958, 16
	anddi8_24 52958, 254

LABEL_FE9F15:
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
	jr z, LABEL_FE9F6F
	ld8_24 l, 0x00cf34
	jr LABEL_FE9F80

LABEL_FE9F6F:
	ld8_24 l, 0x00cee5
	dec 1, hl
	ld xiz, 0xCEE6
	ld_srib3 L, 0x07, 0xF8, 0xEC

LABEL_FE9F80:
	ld xiz, 0xFEA356
	ld_srib3 A, 0x07, 0xF8, 0xEC
	cpdm8_24 52960, a
	jr z, LABEL_FE9FD1
	cpdi16_24 53039, 0
	jr z, LABEL_FE9FA6
	st8_24 0x00cee1, a
	st8_24 0x00cee4, a
	jr LABEL_FE9FB1

LABEL_FE9FA6:
	st8_24 0x00cee1, a
	sti8_24 0x00cee4, 0x00

LABEL_FE9FB1:
	anddi8_24 52958, 251
	ordi8_24 52958, 2
	anddi8_24 52958, 254
	anddi8_24 52958, 127
	ordi8_24 52958, 16
	jr LABEL_FEA013

LABEL_FE9FD1:
	cpdi16_24 53039, 0
	jr z, LABEL_FE9FE7
	sti8_24 0x00cee1, 0x00
	st8_24 0x00cee4, w
	jr LABEL_FE9FF3

LABEL_FE9FE7:
	sti8_24 0x00cee1, 0x00
	sti8_24 0x00cee4, 0x00

LABEL_FE9FF3:
	ordi8_24 52958, 4
	anddi8_24 52958, 253
	anddi8_24 52958, 254
	anddi8_24 52958, 127
	ordi8_24 52958, 16
	jr __jrt_nop_FEA013
__jrt_nop_FEA013:

LABEL_FEA013:
	pop xiz
	pop xix
	ret

LABEL_FEA016:
	st8_24 0x00cedf, a
	st8_24 0x00cee0, w
	sti8_24 0x00cee1, 0x00
	st8_24 0x00cee4, w
	ordi8_24 52958, 4
	anddi8_24 52958, 253
	anddi8_24 52958, 127
	ordi8_24 52958, 16
	ret

LABEL_FEA044:
	calr LABEL_FEA066
	calr LABEL_FEA2EF
	ordi16_24 52993, 65280
	ld8_24 a, 0x00cedf
	st8_24 0x00cee2, a
	ld8_24 a, 0x00cee0
	st8_24 0x00cee3, a
	ret

LABEL_FEA066:
	push xix
	push xiz
	cpi8_24 0x00cedf, 0x00
	jr nz, LABEL_FEA075
	calr LABEL_FEA0AC
	jr LABEL_FEA0A9

LABEL_FEA075:
	calr LABEL_FEA0C7
	calr LABEL_FEA15A
	ldfr_werp DE, 0x3E
	ldda16 xde, 50584
	and de, 0x2
	ldto_werp DE, 0x3E
	jr z, LABEL_FEA09A
	bitda_24 4, 52958
	jr z, LABEL_FEA097
	calr LABEL_FEA18A
	jr LABEL_FEA09A

LABEL_FEA097:
	calr LABEL_FEA243

LABEL_FEA09A:
	bitda_24 4, 52958
	jr z, LABEL_FEA0A6
	calr LABEL_FEA29E
	jr LABEL_FEA0A9

LABEL_FEA0A6:
	calr LABEL_FEA2CA

LABEL_FEA0A9:
	pop xiz
	pop xix
	ret

LABEL_FEA0AC:
	sti8_24 0x00cee5, 0x00
	sti16_24 0x00cf5f, 0x0000
	sti16_24 0x00cf77, 0x0000
	sti8_24 0x00cef1, 0x00
	ret

LABEL_FEA0C7:
	bitda_24 4, 52958
	jrl nz, LABEL_FEA159
	ld8_24 l, 0x00cedf
	xor h, h
	dec 1, hl
	ld xiz, 0xFEA3DA
	ld_srib3 A, 0x07, 0xF8, 0xEC
	st8_24 0x00cee5, a
	ld xiz, 0xFEA403
	sla hl, 2
	ld_sriw3 BC, 0x07, 0xF8, 0xEC
	inc 2, hl
	ld_sriw3 DE, 0x07, 0xF8, 0xEC
	ld8_24 l, 0x00cee0
	dec 1, l
	add c, l
	add b, l
	add e, l
	add d, l
	xor h, h
	ld l, c
	sla hl, 1
	ld xiz, 0xFEA4D2
	ld_sriw3 WA, 0x07, 0xF8, 0xEC
	ld l, b
	sla hl, 1
	or_sriw_rm WA, 0x07, 0xF8, 0xEC
	ld l, e
	sla hl, 1
	or_sriw_rm WA, 0x07, 0xF8, 0xEC
	ld l, d
	sla hl, 1
	or_sriw_rm WA, 0x07, 0xF8, 0xEC
	ld xiy, 0xCEE6
	ld8_24 c, 0x00cee5
	xor b, b
	add iy, bc
	dec 1, iy
	ldb e, 0x36

LABEL_FEA14B:
	inc 1, e
	srl wa, 1
	jr nc, LABEL_FEA14B
	ld (xiy), e
	dec 1, iy
	djnz xbc, LABEL_FEA14B

LABEL_FEA159:
	ret

LABEL_FEA15A:
	xor hl, hl
	bitda_24 1, 52958
	jr z, LABEL_FEA16A
	ld8_24 l, 0x00cee1
	jr LABEL_FEA171

LABEL_FEA16A:
	ld8_24 l, 0x00cee0
	jr __jrt_nop_FEA171
__jrt_nop_FEA171:

LABEL_FEA171:
	ld xiz, 0xFEA349
	ld_srib3 W, 0x07, 0xF8, 0xEC
	ldb a, 0x40
	sti16_24 0x00cf77, 0x0001
	st16_24 0x00cf7b, xwa
	ret

LABEL_FEA18A:
	bitda_24 1, 52958
	jr z, LABEL_FEA201
	ld8_24 l, 0x00cedf
	xor h, h
	dec 1, hl
	ld xiz, 0xFEA3DA
	ld_srib3 C, 0x07, 0xF8, 0xEC
	st8_24 0x00cef1, c
	incdi8_24 1, 52977
	xor b, b
	ld xiy, 0xFEA403
	ld xix, 0xCEF2
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

LABEL_FEA1DA:
	ld_srib3 A, 0x07, 0xF4, 0xEC
	add a, e
	cp a, 0x3C
	jr c, LABEL_FEA1E9
	sub a, 0xC

LABEL_FEA1E9:
	cp a, d
	jr z, LABEL_FEA1F3
	ld (xix), a
	inc 1, ix
	jr LABEL_FEA1FA

LABEL_FEA1F3:
	decdi8_24 1, 52977
	jr __jrt_nop_FEA1FA
__jrt_nop_FEA1FA:

LABEL_FEA1FA:
	inc 1, hl
	djnz xbc, LABEL_FEA1DA
	jr LABEL_FEA242

LABEL_FEA201:
	ld8_24 l, 0x00cedf
	xor h, h
	dec 1, hl
	ld xiz, 0xFEA3DA
	ld_srib3 C, 0x07, 0xF8, 0xEC
	st8_24 0x00cef1, c
	xor b, b
	ld xiy, 0xFEA403
	ld xix, 0xCEF2
	sla hl, 2
	ld8_24 e, 0x00cee0
	dec 1, e
	add e, 0x30

LABEL_FEA232:
	ld_srib3 A, 0x07, 0xF4, 0xEC
	add a, e
	ld (xix), a
	inc 1, hl
	inc 1, ix
	djnz xbc, LABEL_FEA232

LABEL_FEA242:
	ret

LABEL_FEA243:
	ld8_24 l, 0x00cedf
	xor h, h
	dec 1, hl
	ld xiz, 0xFEA3DA
	ld_srib3 A, 0x07, 0xF8, 0xEC
	st8_24 0x00cef1, a
	ld xiz, 0xFEA403
	sla hl, 2
	ld_sriw3 BC, 0x07, 0xF8, 0xEC
	inc 2, hl
	ld_sriw3 DE, 0x07, 0xF8, 0xEC
	ld xiz, 0xFEA349
	ld8_24 l, 0x00cee0
	ld_srib3 L, 0x03, 0xF8, 0xEC
	add l, 0xC
	add c, l
	add b, l
	add e, l
	add d, l
	st8_24 0x00cef2, c
	st8_24 0x00cef3, b
	st8_24 0x00cef4, e
	st8_24 0x00cef5, d
	ret

LABEL_FEA29E:
	ld16_24 xbc, 0x00ceff
	st16_24 0x00cf5f, xbc
	cps bc, 0
	jr z, LABEL_FEA2C9
	ld xiy, 0xCF03
	ld xix, 0xCF63

LABEL_FEA2B6:
	ld_spiw WA, 0xF5
	cp w, 0x6B
	jr ugt, LABEL_FEA2C1
	add w, 0xC

LABEL_FEA2C1:
	ldb a, 0x40
	st_dpiw WA, 0xF1
	djnz xbc, LABEL_FEA2B6

LABEL_FEA2C9:
	ret

LABEL_FEA2CA:
	ld xiy, 0xCEE6
	ld xix, 0xCF5F
	ld8_24 c, 0x00cee5
	xor b, b
	ld (xix + 256), bc

LABEL_FEA2DE:
	ld w, (xiy)
	ldb a, 0x40
	ld (xix + 4), wa
	inc 1, iy
	inc 1, ix
	inc 1, ix
	djnz xbc, LABEL_FEA2DE
	ret

LABEL_FEA2EF:
	bitda_24 0, 52958
	jr nz, LABEL_FEA333
	ld8_24 a, 0x00cedf
	ld8_24 w, 0x00cee0
	ld8_24 l, 0x00cee1
	cpda8 a, 36162
	jr nz, LABEL_FEA317
	cpda8 w, 36160
	jr nz, LABEL_FEA317
	cpda8 l, 36164
	jr z, LABEL_FEA348

LABEL_FEA317:
	stda8 36162, a
	stda8 36160, w
	bitda_24 1, 52958
	jr nz, LABEL_FEA32D
	stdi8 36164, 0
	jr LABEL_FEA331

LABEL_FEA32D:
	stda8 36164, l

LABEL_FEA331:
	jr LABEL_FEA344

LABEL_FEA333:
	stdi8 36162, 0
	stdi8 36160, 0
	stdi8 36164, 0
	jr __jrt_nop_FEA344
__jrt_nop_FEA344:

LABEL_FEA344:
	call BitMapOut_CheckDiskAndApply

LABEL_FEA348:
	ret

LABEL_FEA349:
	.byte 0x00
	.ascii "$%&'()*+,!\"#"
	.byte 0x01, 0x02, 0x03
	.byte 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b
	.byte 0x0c, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07
	.byte 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x01, 0x02, 0x03
	.byte 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b
	.byte 0x0c, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07
	.byte 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x01, 0x02, 0x03
	.byte 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b
	.byte 0x0c, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07
	.byte 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x01, 0x02, 0x03
	.byte 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b
	.byte 0x0c, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07
	.byte 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x01, 0x02, 0x03
	.byte 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b
	.byte 0x0c, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07
	.byte 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x01, 0x02, 0x03
	.byte 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b
	.byte 0x0c, 0x03, 0x04, 0x04, 0x03, 0x03, 0x04, 0x04
	.byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x03, 0x04, 0x04
	.byte 0x04, 0x04, 0x04, 0x04, 0x03, 0x04, 0x04, 0x03
	.fill 8, 1, 0x04
	.fill 8, 1, 0x04
	.byte 0x04, 0x04, 0x00, 0x04, 0x07, 0x00, 0x00, 0x04
	.byte 0x07, 0x0a, 0x00, 0x04, 0x07, 0x0b, 0x00, 0x04
	.byte 0x08, 0x00, 0x00, 0x03, 0x07, 0x00, 0x00, 0x03
	.byte 0x07, 0x0a, 0x00, 0x03, 0x06, 0x09, 0x00, 0x03
	.byte 0x06, 0x0a, 0x00, 0x03, 0x07, 0x0b, 0x00, 0x05
	.byte 0x07, 0x0a, 0x00, 0x04, 0x07, 0x09, 0x00, 0x04
	.byte 0x08, 0x0a, 0x00, 0x04, 0x06, 0x00, 0x00, 0x04
	.byte 0x06, 0x0a, 0x04, 0x07, 0x0a, 0x02, 0x04, 0x07
	.byte 0x0a, 0x01, 0x04, 0x07, 0x0b, 0x02, 0x04, 0x07
	.byte 0x09, 0x02, 0x00, 0x03, 0x07, 0x09, 0x00, 0x03
	.byte 0x06, 0x00, 0x03, 0x07, 0x0a, 0x02, 0x03, 0x09
	.byte 0x02, 0x07, 0x00, 0x05, 0x07, 0x00, 0x04, 0x07
	.byte 0x0a, 0x03, 0x00, 0x04, 0x06, 0x0b, 0x00, 0x04
	.byte 0x08, 0x0b, 0x00, 0x03, 0x06, 0x0b, 0x00, 0x04
	.byte 0x09, 0x0a, 0x00, 0x04, 0x08, 0x0a, 0x00, 0x04
	.byte 0x09, 0x0a, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 24
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04
	.byte 0x07, 0x02, 0x00, 0x03, 0x07, 0x02, 0x00, 0x01
	.byte 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09
	.byte 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11
	.byte 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19
	.byte 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f, 0x20, 0x21
	.asciz "\"#$%&'()* "
	ld	xwa, 0x00008000
	.byte 0x01, 0x00, 0x02, 0x00, 0x04, 0x00, 0x08, 0x01
	.byte 0x00, 0x02, 0x00, 0x04, 0x00, 0x08, 0x00, 0x10
	.byte 0x00, 0x20, 0x00, 0x40, 0x00, 0x80, 0x00, 0x00
	.byte 0x01, 0x00, 0x02, 0x00, 0x04, 0x00, 0x08, 0x01
	.byte 0x00, 0x02, 0x00, 0x04, 0x00, 0x08, 0x00, 0x10
	.byte 0x00

LABEL_FEA502:
	ld xiy, 0xCEFF
	ld xix, 0xCF17
	ld bc, (xiy + 256)
	inc 1, bc
	ldirw
	ret

LABEL_FEA514:
	.byte 0x01, 0x00, 0x02, 0x00, 0x04, 0x00, 0x08, 0x00
	.byte 0x10, 0x00, 0x20, 0x00, 0x40, 0x00, 0x80, 0x00
	.byte 0x00, 0x01, 0x00, 0x02, 0x00, 0x04, 0x00, 0x08
	.byte 0x00, 0x10, 0x00, 0x20, 0x00, 0x40, 0x00, 0x80
	.ascii "89;:<=>Â"
	.byte 0xde, 0xce, 0x00, 0x21, 0xf1, 0xc0, 0xce, 0x41
	.byte 0xc2, 0xdf, 0xce, 0x00, 0x21, 0xf1, 0xc1, 0xce
	.byte 0x41, 0xc2, 0xe0, 0xce, 0x00, 0x21, 0xf1, 0xc2
	.byte 0xce, 0x41, 0xc2, 0xe1, 0xce, 0x00, 0x21, 0xf1
	.byte 0xc3, 0xce, 0x41, 0xc2, 0xe2, 0xce, 0x00, 0x21
	.byte 0xf1, 0xc4, 0xce, 0x41, 0xc2, 0xe3, 0xce, 0x00
	.byte 0x21, 0xf1, 0xc5, 0xce, 0x41, 0xc2, 0xe4, 0xce
	.byte 0x00, 0x21, 0xf1, 0xc6, 0xce, 0x41, 0x45, 0xe5
	.byte 0xce, 0x00, 0x00, 0x44, 0xca, 0xce, 0x00, 0x00
	.byte 0x31, 0x0a, 0x00, 0x85, 0x11, 0x45, 0xb6, 0xce
	.byte 0x00, 0x00, 0x44, 0xe5, 0xce, 0x00, 0x00, 0x31
	.byte 0x0a, 0x00, 0x85, 0x11, 0xc2, 0xe5, 0xce, 0x00
	.byte 0x3f, 0x02, 0x73, 0x87, 0x00, 0x1e, 0x3a, 0xf4
	.byte 0xc8, 0xd8, 0x6e, 0x1d, 0xc2, 0xe5, 0xce, 0x00
	.byte 0x69, 0x1e, 0x2e, 0xf4, 0xc2, 0xe5, 0xce, 0x00
	.byte 0x61, 0x68, 0x0e, 0xc8, 0xd8, 0x6e, 0x0a, 0xc2
	.byte 0xe2, 0xce, 0x00, 0x21, 0xc2, 0xe3, 0xce, 0x00
	.byte 0x20, 0xf2, 0xde, 0xce, 0x00, 0xce, 0x6e, 0x12
	.byte 0xd7, 0x3e, 0x9a, 0xd1, 0x96, 0xc5, 0x22, 0xda
	.byte 0xcc, 0x08, 0x00, 0xd7, 0x3e, 0x8a, 0x6e, 0x23
	.byte 0x68, 0x1c, 0xc2, 0xe5, 0xce, 0x00, 0x27, 0xce
	.byte 0xd6, 0xdb, 0x69, 0x46, 0xe6, 0xce, 0x00, 0x00
	.byte 0x86, 0x24, 0xc3, 0x07, 0xf8, 0xec, 0x25, 0xcd
	.byte 0xa4, 0xcc, 0xcf, 0x0c, 0x6f, 0x05, 0x1e, 0x1b
	.byte 0xf9, 0x68, 0x03, 0x1e, 0x4f, 0xf9, 0xc2, 0xdf
	.byte 0xce, 0x00, 0x21, 0xf1, 0xb6, 0xce, 0x41, 0xc2
	.byte 0xe0, 0xce, 0x00, 0x21, 0xf1, 0xb7, 0xce, 0x41
	.byte 0xc2, 0xe1, 0xce, 0x00, 0x21, 0xf1, 0xb8, 0xce
	.byte 0x41, 0xc2, 0xde, 0xce, 0x00, 0x21, 0xf1, 0xb9
	.byte 0xce, 0x41, 0x68, 0x0a, 0xf1, 0xb6, 0xce, 0x00
	.byte 0x00, 0xf1, 0xb7, 0xce, 0x00, 0x00, 0xc1, 0xc0
	.byte 0xce, 0x21, 0xf2, 0xde, 0xce, 0x00, 0x41, 0xc1
	.byte 0xc1, 0xce, 0x21, 0xf2, 0xdf, 0xce, 0x00, 0x41
	.byte 0xc1, 0xc2, 0xce, 0x21, 0xf2, 0xe0, 0xce, 0x00
	.byte 0x41, 0xc1, 0xc3, 0xce, 0x21, 0xf2, 0xe1, 0xce
	.byte 0x00, 0x41, 0xc1, 0xc4, 0xce, 0x21, 0xf2, 0xe2
	.byte 0xce, 0x00, 0x41, 0xc1, 0xc5, 0xce, 0x21, 0xf2
	.byte 0xe3, 0xce, 0x00, 0x41, 0xc1, 0xc6, 0xce, 0x21
	.byte 0xf2, 0xe4, 0xce, 0x00, 0x41, 0x45, 0xca, 0xce
	.byte 0x00, 0x00, 0x44, 0xe5, 0xce, 0x00, 0x00, 0x31
	.byte 0x0a, 0x00, 0x85, 0x11
	.byte 0x5e, 0x5d, 0x5c, 0x5a
	.byte 0x5b, 0x59, 0x58, 0x0e

LABEL_FEA688:
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

LABEL_FEA6A2:
	cp iy, bc
	jr ge, LABEL_FEA6D4
	ld_sriw3 WA, 0x07, 0xF8, 0xF4
	ld ix, iy

LABEL_FEA6AD:
	inc 2, ix
	cp ix, bc
	jr ge, LABEL_FEA6CB
	ldfr_lerp XIZ, 0x38
	extz ix
	add xiz, xix
	ex_werp IZ, 0x38
	cp_srib_mr W, 0x39, 0x01, 0x00
	jr le, LABEL_FEA6AD
	ex_sriw WA, 0x07, 0xF8, 0xF0
	jr LABEL_FEA6AD

LABEL_FEA6CB:
	st_dri3w WA, 0x07, 0xF8, 0xF4
	inc 2, iy
	jr LABEL_FEA6A2

LABEL_FEA6D4:
	pop xde
	pop xix
	pop xiz
	ret

NoteDisplay_StoreAndDispatch:
	lda xsp, (xsp - 20)
	push xiz
	ld xhl, xbc
	ld xiz, xwa
	ldmi16 (xsp + 10), 0xCEDF
	ldmi16 (xsp + 8), 0xCEE0
	ldmi16 (xsp + 6), 0xCEE1
	ldmi16 (xsp + 4), 0xCEDE
	ld xiy, 0xCEE5
	lda xix, (xsp + 12)
	lds bc, 5
	ldirw
	ldi85
	cps e, 3
	jrl z, LABEL_FEA7B5
	cps e, 2
	jr z, LABEL_FEA738
	cps e, 1
	jr z, LABEL_FEA726
	cps e, 0
	jrl nz, MIDI_FinalizeParamBlock
	ld (xiz), 0x0
	ld (xiz + 1), 0x0
	ld (xiz + 2), 0x0
	ld (xiz + 3), 0x0
	jrl MIDI_FinalizeParamBlock

LABEL_FEA726:
	ld (xiz), 0x0
	ld (xiz + 1), 0x0
	ld (xiz + 2), 0x0
	ld (xiz + 3), 0x0
	jrl MIDI_FinalizeParamBlock

LABEL_FEA738:
	ld xiy, xhl
	ld xix, 0xCEE5
	lds bc, 5
	ldirw
	ldi85
	cpdi8 52965, 0
	jr nz, LABEL_FEA761
	call NoteDisplay_ClearAndSetUpdate
	stdi8 52959, 0
	stdi8 52960, 0
	stdi8 52961, 0
	jr LABEL_FEA7A0

LABEL_FEA761:
	ldda8 a, 52965
	dec 1, a
	extz wa
	ldada xbc, 52966
	extz xwa
	add xwa, xbc
	ldda8 c, 52966
	sub c, (xwa)
	ld a, c
	cp a, 0xC
	jr ule, LABEL_FEA798
	call Voice_UpdateNoteBitmap
	cps hl, 0
	jr nz, LABEL_FEA792
	decdi8 1, 52965
	call Voice_UpdateNoteBitmap
	incdi8 1, 52965

LABEL_FEA792:
	call NoteDisplay_LookupBitmap
	jr LABEL_FEA7A0

LABEL_FEA798:
	call Voice_UpdateNoteBitmap
	call NoteDisplay_InitState

LABEL_FEA7A0:
	ldmi16 (xiz), 0xCEDF
	ldmi16 (xiz + 1), 0xCEE0
	ldmi16 (xiz + 2), 0xCEE1
	ldmi16 (xiz + 3), 0xCEDE
	jr MIDI_FinalizeParamBlock

LABEL_FEA7B5:
	ld (xiz), 0x0
	ld (xiz + 1), 0x0
	ld (xiz + 2), 0x0
	ld (xiz + 3), 0x0

MIDI_FinalizeParamBlock:
	mrdb5 0x8F, 0x0A, 0x19, 0xDF, 0xCE
	mrdb5 0x8F, 0x08, 0x19, 0xE0, 0xCE
	mrdb5 0x8F, 0x06, 0x19, 0xE1, 0xCE
	mrdb5 0x8F, 0x04, 0x19, 0xDE, 0xCE
	lda xiy, (xsp + 12)
	ld xix, 0xCEE5
	lds bc, 5
	ldirw
	ldi85
	pop xiz
	lda xsp, (xsp + 20)
	ret

LABEL_FEA7EB:
	dec 6, xsp
	ld (xsp + 256), 0x5
	ld (xsp + 1), 0xC0
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
	.byte 0xef, 0x6c, 0xbf, 0x00, 0x14, 0x80, 0xc0, 0xbf
	.byte 0x01, 0x14, 0x7d, 0xc0, 0xbf, 0x02, 0x14, 0x7e
	.byte 0xc0, 0xbf, 0x03, 0x14, 0x7f, 0xc0, 0x8f, 0x01
	.byte 0x21, 0xd8, 0x12, 0xd8, 0xd8, 0x75, 0xe3, 0x01
	.byte 0xd8, 0xcf, 0x0c, 0x00, 0x7a, 0xdc, 0x01, 0xd8
	.byte 0x80, 0xf2, 0x44, 0xc0, 0xee, 0x34, 0xd3, 0x07
	.byte 0xf0, 0xe0, 0x20, 0xf2, 0x4f, 0xa8, 0xfe, 0x34
	.byte 0xf3, 0x07, 0xf0, 0xe0, 0xd8, 0x8f, 0x03, 0x21
	.byte 0xc9, 0xcc, 0xff, 0x76, 0xbd, 0x01, 0x8f, 0x00
	.byte 0x21, 0xd8, 0x12, 0x1e, 0xbd, 0x16, 0xcf, 0xd8
	.byte 0x7e, 0xb0, 0x01, 0xb7, 0x30, 0xe8, 0x8a, 0x8f
	.byte 0x03, 0x21, 0xc9, 0xcc, 0xff, 0xc9, 0x8b, 0xd9
	.byte 0x12, 0xea, 0x88, 0x1e, 0x0b, 0x08, 0x78, 0x9a
	.byte 0x01, 0x8f, 0x03, 0x21, 0xc9
LABEL_FEA87F:
	.byte 0x30, 0x07, 0xc9
	.byte 0xd8, 0x76, 0x8f, 0x01, 0x8f, 0x00, 0x21, 0xd8
	.byte 0x12, 0x1e, 0x8f, 0x16, 0xcf, 0xd8, 0x7e, 0x82
	.byte 0x01, 0xb7, 0x30, 0xe8, 0x8a, 0x8f, 0x03, 0x21
	.byte 0xc9, 0x30, 0x07, 0xc9, 0x8b, 0xd9, 0x12, 0xea
	.byte 0x88, 0x1e, 0xdd, 0x07, 0x78, 0x6c, 0x01, 0x8f
	.byte 0x03, 0x21, 0xc9, 0xcc, 0xff, 0x76, 0x63, 0x01
	.byte 0xb7, 0x30, 0x31, 0x7f, 0x00, 0x1e, 0xc9, 0x07
	.byte 0x78, 0x58, 0x01, 0x8f, 0x03, 0x21, 0xc9, 0xcc
	.byte 0x07, 0x66, 0x13, 0xb7, 0x30, 0xe8, 0x8a, 0x8f
	.byte 0x03, 0x21, 0xc9, 0xcc, 0x07, 0xc9, 0x8b, 0xd9
	.byte 0x12, 0xea, 0x88, 0x1e, 0xab, 0x07, 0xbf, 0x03
	.byte 0xcb, 0x66, 0x13, 0xb7, 0x30, 0xe8, 0x8a, 0x8f
	.byte 0x03, 0x21, 0xc9, 0xcc, 0x08, 0xc9, 0x8b, 0xd9
	.byte 0x12, 0xea, 0x88, 0x1e, 0x93, 0x07, 0xbf, 0x03
	.byte 0xce, 0x76, 0x1f, 0x01, 0x8f, 0x00, 0x21, 0xd8
	.byte 0x12, 0x1e, 0x1f, 0x16, 0xcf, 0xd8, 0x7e, 0x12
	.byte 0x01, 0xb7, 0x30, 0xe8, 0x8a, 0x8f, 0x03, 0x21
	.byte 0xc9, 0xcc, 0x40, 0xc9, 0x8b, 0xd9, 0x12, 0xea
	.byte 0x88, 0x1e, 0x6d, 0x07, 0x78, 0xfc, 0x00, 0x8f
	.byte 0x03, 0x21, 0xc9, 0x30, 0x07, 0xc9, 0xd8, 0x76
	.byte 0xf1, 0x00, 0xb7, 0x30, 0xe8, 0x8a, 0x8f, 0x03
	.byte 0x21, 0xc9, 0x30, 0x07, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0xea, 0x88, 0x1e, 0x4c, 0x07, 0x78, 0xdb, 0x00
	.byte 0x8f, 0x03, 0x21, 0xc9, 0x30, 0x07, 0xc9, 0xd8
	.byte 0x76, 0xd0, 0x00, 0xb7, 0x30, 0xe8, 0x8a, 0x8f
	.byte 0x03, 0x21, 0xc9, 0x30, 0x07, 0xc9, 0x8b, 0xd9
	.byte 0x12, 0xea, 0x88, 0x1e, 0x2b, 0x07, 0x78, 0xba
	.byte 0x00, 0x8f, 0x03, 0x21, 0xc9, 0x30, 0x07, 0xc9
	.byte 0xd8, 0x76, 0xaf, 0x00, 0x8f, 0x00, 0x21, 0xd8
	.byte 0x12, 0x1e, 0xaf, 0x15, 0xcf, 0xd8, 0x7e, 0xa2
	.byte 0x00, 0xb7, 0x30, 0xe8, 0x8a, 0x8f, 0x03, 0x21
	.byte 0xc9, 0x30, 0x07, 0xc9, 0x8b, 0xd9, 0x12, 0xea
	.byte 0x88, 0x1e, 0xfd, 0x06, 0x78, 0x8c, 0x00, 0x8f
	.byte 0x03, 0x21, 0xc9, 0x30, 0x07, 0xc9, 0xd8, 0x76
	.byte 0x81, 0x00, 0xb7, 0x30, 0xe8, 0x8a, 0x8f, 0x03
	.byte 0x21, 0xc9, 0x30, 0x07, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0xea, 0x88, 0x1e, 0xdc, 0x06, 0x68, 0x6c, 0x8f
	.byte 0x03, 0x21, 0xc9, 0xcc, 0xff, 0x66, 0x64, 0xb7
	.byte 0x30, 0xe8, 0x8a, 0x8f, 0x03, 0x21, 0xc9, 0xcc
	.byte 0xff, 0xc9, 0x8b, 0xd9, 0x12, 0xea, 0x88, 0x1e
	.byte 0xbf, 0x06, 0x68, 0x4f, 0x8f, 0x03, 0x21, 0xc9
	.byte 0x30, 0x07, 0xc9, 0xd8, 0x66, 0x45, 0xb7, 0x30
	.byte 0xe8, 0x8a, 0x8f, 0x03, 0x21, 0xc9, 0x30, 0x07
	.byte 0xc9, 0x8b, 0xd9, 0x12, 0xea, 0x88, 0x1e, 0xa0
	.byte 0x06, 0x68, 0x30, 0xbf, 0x03, 0xcb, 0x66, 0x13
	.byte 0xb7, 0x30, 0xe8, 0x8a, 0x8f, 0x03, 0x21, 0xc9
	.byte 0xcc, 0x08, 0xc9, 0x8b, 0xd9, 0x12, 0xea, 0x88
	.byte 0x1e, 0x86, 0x06, 0xbf, 0x03, 0xcd, 0x66, 0x13
	.byte 0xb7, 0x30, 0xe8, 0x8a, 0x8f, 0x03, 0x21, 0xc9
	.byte 0xcc, 0x20, 0xc9, 0x8b, 0xd9, 0x12, 0xea, 0x88
	.byte 0x1e, 0x6e, 0x06, 0xef, 0x64, 0x0e
LABEL_FEAA18:
	.byte 0xef, 0x6c
	.byte 0xbf, 0x00, 0x14, 0x80, 0xc0, 0xbf, 0x01, 0x14
	.byte 0x7d, 0xc0, 0xbf, 0x02, 0x14, 0x7e, 0xc0, 0xbf
	.byte 0x03, 0x14, 0x7f, 0xc0, 0x8f, 0x01, 0x21, 0xc9
	.byte 0xd9, 0x6e, 0x48, 0xbf, 0x03, 0xcf, 0x66, 0x13
	.byte 0xb7, 0x30, 0xe8, 0x8a, 0x8f, 0x03, 0x21, 0xc9
	.byte 0xcc, 0x80, 0xc9, 0x8b, 0xd9, 0x12, 0xea, 0x88
	.byte 0x1e, 0x36, 0x06, 0xbf, 0x03, 0xce, 0x66, 0x13
	.byte 0xb7, 0x30, 0xe8, 0x8a, 0x8f, 0x03, 0x21, 0xc9
	.byte 0xcc, 0x40, 0xc9, 0x8b, 0xd9, 0x12, 0xea, 0x88
	.byte 0x1e, 0x1e, 0x06, 0xbf, 0x03, 0xcd, 0x66, 0x13
	.byte 0xb7, 0x30, 0xe8, 0x8a, 0x8f, 0x03, 0x21, 0xc9
	.byte 0xcc, 0x20, 0xc9, 0x8b, 0xd9, 0x12, 0xea, 0x88
	.byte 0x1e, 0x06, 0x06, 0xef, 0x64, 0x0e
LABEL_FEAA80:
	.byte 0xef, 0x6c
	.byte 0xbf, 0x00, 0x14, 0x80, 0xc0, 0xbf, 0x01, 0x14
	.byte 0x7d, 0xc0, 0xbf, 0x02, 0x14, 0x7e, 0xc0, 0xbf
	.byte 0x03, 0x14, 0x7f, 0xc0, 0x8f, 0x01, 0x21, 0xc9
	.byte 0xcf, 0x18, 0x6b, 0x23, 0xc9, 0xd8, 0x67, 0x1f
	.byte 0x8f, 0x03, 0x21, 0xc9, 0xcc, 0xff, 0x66, 0x17
	.byte 0xbf, 0x01, 0x00, 0x00, 0xb7, 0x30, 0xe8, 0x8a
	.byte 0x8f, 0x03, 0x21, 0xc9, 0xcc, 0xff, 0xc9, 0x8b
	.byte 0xd9, 0x12, 0xea, 0x88, 0x1e, 0xc2, 0x05, 0xef
	.byte 0x64, 0x0e
LABEL_FEAAC4:
	.byte 0x0e, 0xef, 0x6c, 0xbf, 0x00, 0x14
	.byte 0x80, 0xc0, 0xbf, 0x01, 0x14, 0x7d, 0xc0, 0xbf
	.byte 0x02, 0x14, 0x7e, 0xc0, 0xbf, 0x03, 0x14, 0x7f
	.byte 0xc0, 0x8f, 0x01, 0x21, 0xc9, 0xcf, 0x18, 0x6b
	.byte 0x23, 0xc9, 0xd8, 0x67, 0x1f, 0x8f, 0x03, 0x21
	.byte 0xc9, 0xcc, 0xff, 0x66, 0x17, 0xbf, 0x01, 0x00
	.byte 0x00, 0xb7, 0x30, 0xe8, 0x8a, 0x8f, 0x03, 0x21
	.byte 0xc9, 0xcc, 0xff, 0xc9, 0x8b, 0xd9, 0x12, 0xea
	.byte 0x88, 0x1e, 0x7d, 0x05, 0xef, 0x64, 0x0e
LABEL_FEAB09:
	.byte 0xef
	.byte 0x6c, 0xbf, 0x00, 0x14, 0x80, 0xc0, 0xbf, 0x01
	.byte 0x14, 0x7d, 0xc0, 0xbf, 0x02, 0x14, 0x7e, 0xc0
	.byte 0xbf, 0x03, 0x14, 0x7f, 0xc0, 0x8f, 0x01, 0x21
	.byte 0xc9, 0xcf, 0x18, 0x6b, 0x23, 0xc9, 0xd8, 0x67
	.byte 0x1f, 0x8f, 0x03, 0x21, 0xc9, 0xcc, 0xff, 0x66
	.byte 0x17, 0xbf, 0x01, 0x00, 0x00, 0xb7, 0x30, 0xe8
	.byte 0x8a, 0x8f, 0x03, 0x21, 0xc9, 0xcc, 0xff, 0xc9
	.byte 0x8b, 0xd9, 0x12, 0xea, 0x88, 0x1e, 0x39, 0x05
	.byte 0xef, 0x64, 0x0e
LABEL_FEAB4D:
	.byte 0xef, 0x6c, 0xbf, 0x00, 0x14
	.byte 0x80, 0xc0, 0xbf, 0x01, 0x14, 0x7d, 0xc0, 0xbf
	.byte 0x02, 0x14, 0x7e, 0xc0, 0xbf, 0x03, 0x14, 0x7f
	.byte 0xc0, 0x8f, 0x01, 0x21, 0xc9, 0xcf, 0x18, 0x6b
	.byte 0x23, 0xc9, 0xd8, 0x67, 0x1f, 0x8f, 0x03, 0x21
	.byte 0xc9, 0xcc, 0xff, 0x66, 0x17, 0xbf, 0x01, 0x00
	.byte 0x00, 0xb7, 0x30, 0xe8, 0x8a, 0x8f, 0x03, 0x21
	.byte 0xc9, 0xcc, 0xff, 0xc9, 0x8b, 0xd9, 0x12, 0xea
	.byte 0x88, 0x1e, 0xf5, 0x04, 0xef, 0x64, 0x0e
LABEL_FEAB91:
	.byte 0xef
	.byte 0x6c, 0xbf, 0x00, 0x14, 0x80, 0xc0, 0xbf, 0x01
	.byte 0x14, 0x7d, 0xc0, 0xbf, 0x02, 0x14, 0x7e, 0xc0
	.byte 0xbf, 0x03, 0x14, 0x7f, 0xc0, 0x8f, 0x01, 0x21
	.byte 0xc9, 0xcf, 0x18, 0x6b, 0x23, 0xc9, 0xd8, 0x67
	.byte 0x1f, 0x8f, 0x03, 0x21, 0xc9, 0xcc, 0xff, 0x66
	.byte 0x17, 0xbf, 0x01, 0x00, 0x00, 0xb7, 0x30, 0xe8
	.byte 0x8a, 0x8f, 0x03, 0x21, 0xc9, 0xcc, 0xff, 0xc9
	.byte 0x8b, 0xd9, 0x12, 0xea, 0x88, 0x1e, 0xb1, 0x04
	.byte 0xef, 0x64, 0x0e
LABEL_FEABD5:
	.byte 0x0e, 0x0e
LABEL_FEABD7:
	.byte 0x0e, 0x0e
LABEL_FEABD9:
	.byte 0xef
	.byte 0x6c, 0xbf, 0x00, 0x14, 0x80, 0xc0, 0xbf, 0x01
	.byte 0x14, 0x7d, 0xc0, 0xbf, 0x02, 0x14, 0x7e, 0xc0
	.byte 0xbf, 0x03, 0x14, 0x7f, 0xc0, 0x8f, 0x01, 0x21
	.byte 0xd8, 0x12, 0xd8, 0xd8, 0x75, 0x85, 0x00, 0xd8
	.byte 0xdf, 0x7a, 0x80, 0x00, 0xd8, 0x80, 0xf2, 0x5e
	.byte 0xc0, 0xee, 0x34, 0xd3, 0x07, 0xf0, 0xe0, 0x20
	.byte 0xf2, 0x14, 0xac, 0xfe, 0x34, 0xf3, 0x07, 0xf0
	.byte 0xe0, 0xd8, 0x8f, 0x03, 0x21, 0xc9, 0xcc, 0xff
	.byte 0x66, 0x62, 0xbf, 0x02, 0x31, 0x21, 0x00, 0xbf
	.byte 0x02, 0xcf, 0x6e, 0x06, 0x8f, 0x02, 0x21, 0xc9
	.byte 0x30, 0x07, 0xb1, 0x41, 0x8f, 0x02, 0x21, 0xd8
	.byte 0x12, 0xd8, 0x8a, 0x30, 0x17, 0x00, 0xd9, 0xaf
	.byte 0x1e, 0xda, 0x0e, 0x8f, 0x02, 0x21, 0xd8, 0x12
	.byte 0xd8, 0x8a, 0x30, 0x18, 0x00, 0xd9, 0xaf, 0x1e
	.byte 0xcb, 0x0e, 0x68, 0x30, 0x8f, 0x03, 0x21, 0xc9
	.byte 0x30, 0x07, 0xc9, 0xd8, 0x66, 0x26, 0x8f, 0x02
	.byte 0x21, 0xc9, 0x30, 0x07, 0xd8, 0x12, 0xd8, 0x8a
	.byte 0x30, 0x17, 0x00, 0x31, 0x5b, 0x00, 0x1e, 0xac
	.byte 0x0e, 0x8f, 0x02, 0x21, 0xc9, 0x30, 0x07, 0xd8
	.byte 0x12, 0xd8, 0x8a, 0x30, 0x18, 0x00, 0x31, 0x5b
	.byte 0x00, 0x1e, 0x99, 0x0e, 0xef, 0x64, 0x0e, 0x0e
LABEL_FEAC82:
	.byte 0x0e
UIStateEvt_ProcessHandler:
	.byte 0xef, 0x6c, 0xbf, 0x00, 0x14, 0x80, 0xc0
	.byte 0xbf, 0x01, 0x14, 0x7d, 0xc0, 0xbf, 0x02, 0x14
	.byte 0x7e, 0xc0, 0xbf, 0x03, 0x14, 0x7f, 0xc0, 0x8f
	.byte 0x01, 0x21, 0xc9, 0xdb, 0x66, 0x46, 0xc9, 0xda
	.byte 0x66, 0x5a, 0xc9, 0xd9, 0x66, 0x21, 0xc9, 0xd8
	.byte 0x6e, 0x52, 0x8f, 0x03, 0x21, 0xc9, 0xcc, 0xff
	.byte 0x66, 0x4a, 0xb7, 0x30, 0xe8, 0x8a, 0x8f, 0x03
	.byte 0x21, 0xc9, 0xcc, 0xff, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0xea, 0x88, 0x1e, 0xbc, 0x03, 0x68, 0x35, 0x8f
	.byte 0x03, 0x21, 0xc9, 0xcc, 0xff, 0x66, 0x2d, 0xb7
	.byte 0x30, 0xe8, 0x8a, 0x8f, 0x03, 0x21, 0xc9, 0xcc
	.byte 0xff, 0xc9, 0x8b, 0xd9, 0x12, 0xea, 0x88, 0x1e
	.byte 0x9f, 0x03, 0x68, 0x18, 0xbf, 0x03, 0xc8, 0x66
	.byte 0x13, 0xb7, 0x30, 0xe8, 0x8a, 0x8f, 0x03, 0x21
	.byte 0xc9, 0xcc, 0x01, 0xc9, 0x8b, 0xd9, 0x12, 0xea
	.byte 0x88, 0x1e, 0x85, 0x03, 0xef, 0x64, 0x0e
LABEL_FEAD01:
	.byte 0xef
	.byte 0x6c, 0xbf, 0x00, 0x14, 0x80, 0xc0, 0xbf, 0x01
	.byte 0x14, 0x7d, 0xc0, 0xbf, 0x02, 0x14, 0x7e, 0xc0
	.byte 0xbf, 0x03, 0x14, 0x7f, 0xc0, 0x8f, 0x01, 0x21
	.byte 0xc9, 0xcf, 0x0d, 0x6b, 0x3f, 0xc9, 0xda, 0x6f
	.byte 0x33, 0xc9, 0xd8, 0x66, 0x06, 0xc9, 0xd9, 0x66
	.byte 0x0c, 0x68, 0x31, 0xb7, 0x30, 0x31, 0xff, 0x00
	.byte 0x1e, 0x4e, 0x03, 0x68, 0x27, 0x8f, 0x03, 0x21
	.byte 0xc9, 0xcc, 0x0f, 0x66, 0x08, 0xb7, 0x30, 0x31
	.byte 0x0f, 0x00, 0x1e, 0x3c, 0x03, 0xbf, 0x03, 0xcf
	.byte 0x66, 0x12, 0xb7, 0x30, 0x31, 0x80, 0x00, 0x1e
	.byte 0x2f, 0x03, 0x68, 0x08, 0xb7, 0x30, 0x31, 0xff
	.byte 0x00, 0x1e, 0x25, 0x03, 0xef, 0x64, 0x0e, 0x0e
LABEL_FEAD62:
	.byte 0xef, 0x6c, 0xbf, 0x00, 0x14, 0x80, 0xc0, 0xbf
	.byte 0x01, 0x14, 0x7d, 0xc0, 0xbf, 0x02, 0x14, 0x7e
	.byte 0xc0, 0xbf, 0x03, 0x14, 0x7f, 0xc0, 0x8f, 0x01
	.byte 0x21, 0xc9, 0xdc, 0x66, 0x45, 0xc9, 0xdb, 0x66
	.byte 0x41, 0xc9, 0xda, 0x66, 0x22, 0xc9, 0xd9, 0x66
	.byte 0x39, 0xc9, 0xd8, 0x6e, 0x35, 0xbf, 0x03, 0xca
	.byte 0x66, 0x30, 0xb7, 0x30, 0xe8, 0x8a, 0x8f, 0x03
	.byte 0x21, 0xc9, 0xcc, 0x04, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0xea, 0x88, 0x1e, 0xdc, 0x02, 0x68, 0x1b, 0x8f
	.byte 0x03, 0x21, 0xc9, 0xcc, 0xff, 0x66, 0x13, 0xb7
	.byte 0x30, 0xe8, 0x8a, 0x8f, 0x03, 0x21, 0xc9, 0xcc
	.byte 0xff, 0xc9, 0x8b, 0xd9, 0x12, 0xea, 0x88, 0x1e
	.byte 0xbf, 0x02, 0xef, 0x64, 0x0e
LABEL_FEADC7:
	.byte 0xef, 0x6c, 0xbf
	.byte 0x00, 0x14, 0x80, 0xc0, 0xbf, 0x01, 0x14, 0x7d
	.byte 0xc0, 0xbf, 0x02, 0x14, 0x7e, 0xc0, 0xbf, 0x03
	.byte 0x14, 0x7f, 0xc0, 0x8f, 0x01, 0x21, 0xc9, 0xdc
	.byte 0x66, 0x28, 0xc9, 0xdb, 0x66, 0x4d, 0xc9, 0xda
	.byte 0x66, 0x06, 0xc9, 0xd9
	.ascii "fEhC"
	.byte 0xbf, 0x03, 0xcf, 0x66, 0x3e, 0xb7, 0x30, 0xe8
	.byte 0x8a, 0x8f, 0x03, 0x21, 0xc9, 0xcc, 0x80, 0xc9
	.byte 0x8b, 0xd9, 0x12, 0xea, 0x88, 0x1e, 0x79, 0x02
	.byte 0x68, 0x29, 0x8f, 0x03, 0x21, 0xc9, 0xcc, 0xff
	.byte 0x66, 0x21, 0xbf, 0x02, 0x31, 0x21, 0x00, 0xbf
	.byte 0x02, 0xcf, 0x6e, 0x06, 0x8f, 0x02, 0x21, 0xc9
	.byte 0x30, 0x07, 0xb1, 0x41, 0x8f, 0x02, 0x21, 0xd8
	.byte 0x12, 0xd8, 0x8a, 0x30, 0x19, 0x00, 0xd9, 0xaf
	.byte 0x1e, 0xe2, 0x0c, 0xef, 0x64, 0x0e, 0xef, 0x6c
	.byte 0xbf, 0x00, 0x14, 0x80, 0xc0, 0xbf, 0x01, 0x14
	.byte 0x7d, 0xc0, 0xbf, 0x02, 0x14, 0x7e, 0xc0, 0xbf
	.byte 0x03, 0x14, 0x7f, 0xc0, 0x8f, 0x01, 0x21, 0xc9
	.byte 0xcf, 0x13, 0x6b, 0x45, 0xc9, 0xdc, 0x67, 0x41
	.byte 0x8f, 0x01, 0x21, 0xc9, 0x6c, 0xd8, 0x12, 0xf1
	.byte 0xa0, 0xf1, 0x31, 0xe8, 0x12, 0xe9, 0x80, 0x80
	.byte 0x21, 0xd8, 0x12, 0xf2, 0xa2, 0x8e, 0xee, 0x31
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x25, 0xcd, 0x89, 0xc9
	.byte 0xd9, 0x66, 0x08, 0xc9, 0xda, 0x66, 0x04, 0xc9
	.byte 0xd8, 0x6e, 0x16, 0xda, 0x12, 0x8f, 0x03, 0x21
	.byte 0x8f, 0x02, 0xc1, 0xc9, 0x8b, 0xd9, 0x12, 0xda
	.byte 0x88, 0xd9, 0x8a, 0x31, 0x91, 0x00, 0x1e, 0x7c
	.byte 0x0c, 0xef, 0x64, 0x0e
LABEL_FEAE9E:
	.byte 0xef, 0x6c, 0xbf, 0x00
	.byte 0x14, 0x80, 0xc0, 0xbf, 0x01, 0x14, 0x7d, 0xc0
	.byte 0xbf, 0x02, 0x14, 0x7e, 0xc0, 0xbf, 0x03, 0x14
	.byte 0x7f, 0xc0, 0xb7, 0x30, 0xe8, 0x8a, 0x8f, 0x03
	.byte 0x21, 0xc9, 0x30, 0x07, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0xea, 0x88, 0x1e, 0xbc, 0x01, 0xef, 0x64, 0x0e
LABEL_FEAECA:
	.byte 0xef, 0x6c, 0xbf, 0x00, 0x14, 0x80, 0xc0, 0xbf
	.byte 0x01, 0x14, 0x7d, 0xc0, 0xbf, 0x02, 0x14, 0x7e
	.byte 0xc0, 0xbf, 0x03, 0x14, 0x7f, 0xc0, 0x8f, 0x01
	.byte 0x21, 0xc9, 0xdb, 0x66, 0x2c, 0xc9, 0xd9, 0x66
	.byte 0x16, 0xc9, 0xd8, 0x6e, 0x34, 0xb7, 0x30, 0xe8
	.byte 0x8a, 0x8f, 0x03, 0x21, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0xea, 0x88, 0x1e, 0x84, 0x01, 0x68, 0x22, 0xb7
	.byte 0x30, 0xe8, 0x8a, 0x8f, 0x03, 0x21, 0xc9, 0x8b
	.byte 0xd9, 0x12, 0xea, 0x88, 0x1e, 0x72, 0x01, 0x68
	.byte 0x10, 0xb7, 0x30, 0xe8, 0x8a, 0x8f, 0x03, 0x21
	.byte 0xc9, 0x8b, 0xd9, 0x12, 0xea, 0x88, 0x1e, 0x60
	.byte 0x01, 0xef, 0x64, 0x0e
LABEL_FEAF26:
	.byte 0xef, 0x6c, 0xbf, 0x00
	.byte 0x14, 0x80, 0xc0, 0xbf, 0x01, 0x14, 0x7d, 0xc0
	.byte 0xbf, 0x02, 0x14, 0x7e, 0xc0, 0xbf, 0x03, 0x14
	.byte 0x7f, 0xc0, 0xb7, 0x30, 0xe8, 0x8a, 0x8f, 0x03
	.byte 0x21, 0xc9, 0x30, 0x07, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0xea, 0x88, 0x1e, 0x34, 0x01, 0xef, 0x64, 0x0e
LABEL_FEAF52:
	.byte 0xef, 0x6c, 0xbf, 0x00, 0x14, 0x80, 0xc0, 0xbf
	.byte 0x01, 0x14, 0x7d, 0xc0, 0xbf, 0x02, 0x14, 0x7e
	.byte 0xc0, 0xbf, 0x03, 0x14, 0x7f, 0xc0, 0xb7, 0x30
	.byte 0xe8, 0x8a, 0x8f, 0x03, 0x21, 0xc9, 0x30, 0x07
	.byte 0xc9, 0x8b, 0xd9, 0x12, 0xea, 0x88, 0x1e, 0x08
	.byte 0x01, 0xef, 0x64, 0x0e
LABEL_FEAF7E:
	.byte 0xef, 0x6c, 0xbf, 0x00
	.byte 0x14, 0x80, 0xc0, 0xbf, 0x01, 0x14, 0x7d, 0xc0
	.byte 0xbf, 0x02, 0x14, 0x7e, 0xc0, 0xbf, 0x03, 0x14
	.byte 0x7f, 0xc0, 0x8f, 0x01, 0x3f, 0x10, 0x67, 0x06
	.byte 0x8f, 0x01, 0x3f, 0x14, 0x63, 0x13, 0xb7, 0x30
	.byte 0xe8, 0x8a, 0x8f, 0x03, 0x21, 0xc9, 0x30, 0x07
	.byte 0xc9, 0x8b, 0xd9, 0x12, 0xea, 0x88, 0x1e, 0xd0
	.byte 0x00, 0xef, 0x64, 0x0e
LABEL_FEAFB6:
	.byte 0xef, 0x6c, 0xbf, 0x00
	.byte 0x14, 0x80, 0xc0, 0xbf, 0x01, 0x14, 0x7d, 0xc0
	.byte 0xbf, 0x02, 0x14, 0x7e, 0xc0, 0xbf, 0x03, 0x14
	.byte 0x7f, 0xc0, 0xb7, 0x30, 0xe8, 0x8a, 0x8f, 0x03
	.byte 0x21, 0xc9, 0x30, 0x07, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0xea, 0x88, 0x1e, 0xa4, 0x00, 0xef, 0x64, 0x0e
LABEL_FEAFE2:
	.byte 0xef, 0x6c, 0xbf, 0x00, 0x14, 0x80, 0xc0, 0xbf
	.byte 0x01, 0x14, 0x7d, 0xc0, 0xbf, 0x02, 0x14, 0x7e
	.byte 0xc0, 0xbf, 0x03, 0x14, 0x7f, 0xc0, 0xb7, 0x30
	.byte 0xe8, 0x8a, 0x8f, 0x03, 0x21, 0xc9, 0x30, 0x07
	.byte 0xc9, 0x8b, 0xd9, 0x12, 0xea, 0x88, 0x1e, 0x78
	.byte 0x00, 0xef, 0x64, 0x0e
LABEL_FEB00E:
	.byte 0x0e
LABEL_FEB00F:
	.byte 0x0e
LABEL_FEB010:
	.byte 0xef, 0x6c
	.byte 0xbf, 0x00, 0x14, 0x80, 0xc0, 0xbf, 0x01, 0x14
	.byte 0x7d, 0xc0, 0xbf, 0x02, 0x14, 0x7e, 0xc0, 0xbf
	.byte 0x03, 0x14, 0x7f, 0xc0, 0x8f, 0x01, 0x21, 0xc9
	.byte 0xd9, 0x66, 0x1e, 0xc9, 0xd8, 0x6e, 0x4f, 0xbf
	.byte 0x03, 0xcf, 0x66, 0x4a, 0xb7, 0x30, 0xe8, 0x8a
	.byte 0x8f, 0x03, 0x21, 0xc9, 0xcc, 0x80, 0xc9, 0x8b
	.byte 0xd9, 0x12, 0xea, 0x88, 0x1e, 0x3a, 0x00, 0x68
	.byte 0x35, 0x8f, 0x03, 0x21, 0xc9, 0x30, 0x07, 0xc9
	.byte 0xd8, 0x66, 0x13, 0xb7, 0x30, 0xe8, 0x8a, 0x8f
	.byte 0x03, 0x21, 0xc9, 0x30, 0x07, 0xc9, 0x8b, 0xd9
	.byte 0x12, 0xea, 0x88, 0x1e, 0x1b, 0x00, 0xbf, 0x03
	.byte 0xcf, 0x66, 0x13, 0xb7, 0x30, 0xe8, 0x8a, 0x8f
	.byte 0x03, 0x21, 0xc9, 0xcc, 0x80, 0xc9, 0x8b, 0xd9
	.byte 0x12, 0xea, 0x88, 0x1e, 0x03, 0x00, 0xef, 0x64
	.byte 0x0e, 0xbf, 0xf4, 0x37, 0x3e, 0xe8, 0x8e, 0x8e
	.byte 0x03, 0x21, 0xbf, 0x04, 0x41, 0xbe, 0x03, 0x43
	.byte 0xbf, 0x0c, 0x30, 0xe8, 0x89, 0xbf, 0x0a, 0x30
	.byte 0xe8, 0x8a, 0xee, 0x88, 0x1d, 0xff, 0xd4, 0xfc
	.byte 0xdb, 0xcf, 0xff, 0xff, 0x66, 0x32, 0xbf, 0x0c
	.byte 0x30, 0xe8, 0x8b, 0xbf, 0x08, 0x30, 0xe8, 0x89
	.byte 0xbf, 0x06, 0x30, 0xe8, 0x8a, 0xeb, 0x88, 0x1d
	.byte 0xc5, 0xd7, 0xfc, 0xdb, 0xcf, 0xff, 0xff, 0x66
	.byte 0x0e, 0x9f, 0x08, 0x20, 0x9f, 0x06, 0x21, 0x9f
	.byte 0x0a, 0x22, 0x1e, 0x16, 0x00, 0x68, 0x09, 0xaf
	.byte 0x0c, 0x20, 0x9f, 0x0a, 0x21, 0x1e, 0xe9, 0x01
	.byte 0x8f, 0x04, 0x21, 0xbe, 0x03, 0x41, 0x5e, 0xbf
	.byte 0x0c, 0x37, 0x0e

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
	jrl z, LABEL_FEB2B0
	cp bc, 0x1B2
	jrl z, LABEL_FEB2A6
	cp bc, 0x603
	jrl z, LABEL_FEB28C
	cp bc, 0x602
	jrl z, LABEL_FEB272
	cp bc, 0x1B0
	jrl z, LABEL_FEB268
	cp bc, 0x82
	jrl z, LABEL_FEB259
	cp bc, 0x81
	jrl z, LABEL_FEB24A
	cp bc, 0x80
	jrl z, LABEL_FEB23B
	cp bc, 0x5E
	jrl z, LABEL_FEB229
	cp bc, 0x5D
	jrl z, LABEL_FEB219
	cp bc, 0x5B
	jrl z, LABEL_FEB209
	cp bc, 0x600
	jrl z, LABEL_FEB1F9
	cp bc, 0x40
	jrl z, LABEL_FEB1D9
	cp bc, 0xB
	jr z, LABEL_FEB1C9
	cp bc, 0xA
	jr z, LABEL_FEB1B9
	cps bc, 7
	jr z, LABEL_FEB19A
	cps bc, 1
	jr z, LABEL_FEB18B
	cp bc, 0x20
	jr z, LABEL_FEB179
	cps bc, 0
	jrl nz, MIDI_SendEpilogue
	ld wa, (xsp + 2)
	add wa, wa
	ldada xbc, 53200
	extz xwa
	add xwa, xbc
	ld (xwa), iz
	jrl MIDI_SendEpilogue

LABEL_FEB179:
	ld wa, (xsp + 2)
	add wa, wa
	ldada xbc, 53264
	extz xwa
	add xwa, xbc
	ld (xwa), iz
	jrl MIDI_SendEpilogue

LABEL_FEB18B:
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	lds bc, 1
	calr MIDI_SendControlChange
	jrl MIDI_SendEpilogue

LABEL_FEB19A:
	ld wa, (xsp + 2)
	ldw bc, 0x8
	call SndParam_LookupViaEncode
	cps hl, 1
	jr nz, LABEL_FEB1AA
	lds iz, 0

LABEL_FEB1AA:
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	lds bc, 7
	calr MIDI_SendControlChange
	jrl MIDI_SendEpilogue

LABEL_FEB1B9:
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	ldw bc, 0xA
	calr MIDI_SendControlChange
	jrl MIDI_SendEpilogue

LABEL_FEB1C9:
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	ldw bc, 0xB
	calr MIDI_SendControlChange
	jrl MIDI_SendEpilogue

LABEL_FEB1D9:
	ldw wa, 0x7F
	cps iz, 0
	jr nz, LABEL_FEB1E2
	lds wa, 0

LABEL_FEB1E2:
	ld iz, wa
	ldto_berp A, 0xF8
	ld c, a
	extz bc
	ld wa, (xsp + 2)
	ld de, bc
	ldw bc, 0x40
	calr MIDI_SendControlChange
	jrl MIDI_SendEpilogue

LABEL_FEB1F9:
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	ldw bc, 0x97
	calr MIDI_SendControlChange
	jrl MIDI_SendEpilogue

LABEL_FEB209:
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	ldw bc, 0x5B
	calr MIDI_SendControlChange
	jrl MIDI_SendEpilogue

LABEL_FEB219:
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	ldw bc, 0x5D
	calr MIDI_SendControlChange
	jrl MIDI_SendEpilogue

LABEL_FEB229:
	ld wa, (xsp + 2)
	add wa, wa
	ldada xbc, 53328
	extz xwa
	add xwa, xbc
	ld (xwa), iz
	jrl MIDI_SendEpilogue

LABEL_FEB23B:
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	ldw bc, 0x80
	calr MIDI_SendControlChange
	jr MIDI_SendEpilogue

LABEL_FEB24A:
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	ldw bc, 0x81
	calr MIDI_SendControlChange
	jr MIDI_SendEpilogue

LABEL_FEB259:
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	ldw bc, 0x82
	calr MIDI_SendControlChange
	jr MIDI_SendEpilogue

LABEL_FEB268:
	ld bc, iz
	ld wa, (xsp + 2)
	calr MIDI_SendPitchBend
	jr MIDI_SendEpilogue

LABEL_FEB272:
	ldw wa, 0x7F
	cps iz, 0
	jr nz, LABEL_FEB27B
	lds wa, 0

LABEL_FEB27B:
	ld iz, wa
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	ldw bc, 0x9C
	calr MIDI_SendControlChange
	jr MIDI_SendEpilogue

LABEL_FEB28C:
	ldw wa, 0x7F
	cps iz, 0
	jr nz, LABEL_FEB295
	lds wa, 0

LABEL_FEB295:
	ld iz, wa
	ld bc, iz
	ld wa, (xsp + 2)
	ld de, bc
	ldw bc, 0x95
	calr MIDI_SendControlChange
	jr MIDI_SendEpilogue

LABEL_FEB2A6:
	ld bc, iz
	ld wa, (xsp + 2)
	calr MIDI_SendChannelPressure
	jr MIDI_SendEpilogue

LABEL_FEB2B0:
	ld wa, (xsp + 2)
	ldw bc, 0x78
	lds de, 0
	calr MIDI_SendControlChange

MIDI_SendEpilogue:
	call MIDI_PostSendStub
	popw iz
	inc 2, xsp
	ret

LABEL_FEB2C3:
	.byte 0xef, 0x6c, 0x3e, 0xd9, 0x8e, 0xe8, 0x89, 0xe9
	.byte 0xef, 0x08, 0xd9, 0x8b, 0xe8, 0x89, 0xe9, 0xcc
	.byte 0xff, 0x00, 0x00, 0x00, 0xd9, 0x8a, 0xdb, 0x89
	.byte 0xd9, 0xcf, 0x4e, 0x00, 0x76, 0x44, 0x06, 0xd9
	.byte 0xcf, 0x4d, 0x00, 0x76, 0x37, 0x06, 0xd9, 0xcf
	.byte 0x4c, 0x00, 0x76, 0x2a, 0x06, 0xd9, 0xcf, 0x4b
	.byte 0x00, 0x76, 0x1d, 0x06, 0xd9, 0xcf, 0x49, 0x00
	.byte 0x76, 0x10, 0x06, 0xd9, 0xcf, 0x42, 0x00, 0x76
	.byte 0xc1, 0x01, 0xd9, 0xcf, 0x41, 0x00, 0x76, 0x59
	.byte 0x01, 0xd9, 0xcf, 0x40, 0x00, 0x76, 0xc9, 0x00
	.byte 0xd9, 0xd8, 0x7e, 0x12, 0x06, 0xda, 0x88, 0xd8
	.byte 0xcf, 0xc1, 0x00, 0x76, 0x9d, 0x00, 0xd8, 0xcf
	.byte 0xc0, 0x00, 0x66, 0x7a, 0xd8, 0xdb, 0x66, 0x1c
	.byte 0xd8, 0xd8, 0x7e, 0xfa, 0x05, 0xde, 0xc8, 0x40
	.byte 0x00, 0xc7, 0xf8, 0x89, 0xd8, 0x12, 0xd8, 0x8a
	.byte 0x30, 0x50, 0x00, 0x31, 0x82, 0x00, 0x1e, 0xf2
	.byte 0x08, 0x78, 0xe3, 0x05, 0xde, 0x6d, 0xc7, 0xf8
	.byte 0x89, 0xd8, 0x12, 0xd8, 0x8a, 0x30, 0x50, 0x00
	.byte 0x31, 0x83, 0x00, 0x1e, 0xdd, 0x08, 0xc7, 0xf8
	.byte 0x89, 0xc1, 0xc2, 0xe9, 0xf1, 0x76, 0xc7, 0x05
	.byte 0xd1, 0x96, 0xc5, 0x20, 0xd8, 0xcc, 0x80, 0x00
	.byte 0xd8, 0xcf, 0x80, 0x00, 0x6e, 0x12, 0xd1, 0x96
	.byte 0xc5, 0x20, 0xd8, 0x33, 0x08, 0x6e, 0x09, 0x30
	.byte 0xff, 0x00, 0xd9, 0xaa, 0x1d, 0xa9, 0x1b, 0xfe
	.byte 0x30, 0xff, 0x00, 0x31, 0x15, 0x00, 0x1d, 0xa9
	.byte 0x1b, 0xfe, 0x30, 0xff, 0x00, 0x31, 0x16, 0x00
	.byte 0x1d, 0xa9, 0x1b, 0xfe, 0xc7, 0xf8, 0x89, 0xf1
	.byte 0xc2, 0xe9, 0x41, 0x78, 0x89, 0x05, 0xd8, 0xa9
	.byte 0xde, 0xd8, 0x6e, 0x02, 0xd8, 0xaa, 0xd8, 0x8e
	.byte 0xc7, 0xf8, 0x89, 0xd8, 0x12, 0xd8, 0x8a, 0x30
	.byte 0x7f, 0x00, 0x31, 0x09, 0x00, 0x1e, 0x7b, 0x08
	.byte 0x78, 0x6c, 0x05, 0x30, 0x7f, 0x00, 0xde, 0xd8
	.byte 0x6e, 0x02, 0xd8, 0xa8, 0xd8, 0x8e, 0xc7, 0xf8
	.byte 0x89, 0xd8, 0x12, 0xd8, 0x8a, 0x30, 0x50, 0x00
	.byte 0x31, 0x99, 0x00, 0x1e, 0x5d, 0x08, 0x78, 0x4e
	.byte 0x05, 0xda, 0x88, 0xd8, 0xcf, 0x82, 0x00, 0x76
	.byte 0x45, 0x05, 0xd8, 0xcf, 0x81, 0x00, 0x76, 0x3e
	.byte 0x05, 0xd8, 0xcf, 0x80, 0x00, 0x66, 0x60, 0xd8
	.byte 0xde, 0x7b, 0x33, 0x05, 0xd8, 0x80, 0xf2, 0x8c
	.byte 0xc0, 0xee, 0x34, 0xd3, 0x07, 0xf0, 0xe0, 0x20
	.byte 0xf2, 0x0d, 0xb4, 0xfe, 0x34, 0xf3, 0x07, 0xf0
	.byte 0xe0, 0xd8, 0xc7, 0xf8, 0x89, 0xd8, 0x12, 0x1d
	.byte 0x6e, 0xf7, 0xfe, 0x78, 0x11, 0x05, 0xc7, 0xf8
	.byte 0x89, 0xd8, 0x12, 0x1d, 0x86, 0xf7, 0xfe, 0x78
	.byte 0x05, 0x05, 0xf1, 0xca, 0xcf, 0x56, 0x78, 0xfe
	.byte 0x04, 0xf1, 0xc8, 0xcf, 0x56, 0x78, 0xf7, 0x04
	.byte 0xf1, 0xcc, 0xcf, 0x56, 0x78, 0xf0, 0x04, 0xc7
	.byte 0xf8, 0x89, 0xd8, 0x12, 0x1d, 0x9e, 0xf7, 0xfe
	.byte 0x78, 0xe4, 0x04, 0xc7, 0xf8, 0x89, 0xd8, 0x12
	.byte 0x1d, 0x52, 0xf8, 0xfe, 0x78, 0xd8, 0x04, 0xc7
	.byte 0xf8, 0x89, 0xd8, 0x12, 0xd8, 0x8a, 0x30, 0x50
	.byte 0x00, 0x31, 0x85, 0x00, 0x1e, 0xd4, 0x07, 0x78
	.byte 0xc5, 0x04, 0xda, 0x88, 0xd8, 0xcf, 0x42, 0x00
	.byte 0x66, 0x2f, 0xd8, 0xcf, 0x41, 0x00, 0x66, 0x0e
	.byte 0xd8, 0xcf, 0x40, 0x00, 0x7e, 0xb0, 0x04, 0xf1
	.byte 0xce, 0xcf, 0x56, 0x78, 0xa9, 0x04, 0x40, 0x42
	.byte 0x41, 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xdb
	.byte 0xd9, 0x6e, 0x02, 0xde, 0xa8, 0xc7, 0xf8, 0x89
	.byte 0xd8, 0x12, 0x1d, 0xb6, 0xf7, 0xfe, 0x78, 0x8e
	.byte 0x04, 0x40, 0x42, 0x41, 0x00, 0x00, 0x1d, 0x37
	.byte 0xd4, 0xfc, 0xdb, 0xd9, 0x6e, 0x09, 0xd8, 0xa8
	.byte 0x1d, 0xb6, 0xf7, 0xfe, 0x78, 0x78, 0x04, 0x40
	.byte 0x41, 0x41, 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc
	.byte 0xcf, 0x89, 0xd8, 0x12, 0x1d, 0xb6, 0xf7, 0xfe
	.byte 0x78, 0x64, 0x04, 0xda, 0x88, 0xd8, 0xca, 0x80
	.byte 0x00, 0xd8, 0xd8, 0x77, 0x59, 0x04, 0xd8, 0xcf
	.byte 0x0e, 0x00, 0x7b, 0x52, 0x04, 0xd8, 0x80, 0xf2
	.byte 0x6e, 0xc0, 0xee, 0x34, 0xd3, 0x07, 0xf0, 0xe0
	.byte 0x20, 0xf2, 0xee, 0xb4, 0xfe, 0x34, 0xf3, 0x07
	.byte 0xf0, 0xe0, 0xd8, 0x30, 0x7f, 0x00, 0xde, 0xd8
	.byte 0x6e, 0x02, 0xd8, 0xa8, 0xd8, 0x8e, 0xc7, 0xf8
	.byte 0x89, 0xd8, 0x12, 0xd8, 0x8a, 0x30, 0x50, 0x00
	.byte 0x31, 0xb1, 0x00, 0x1e, 0x2d, 0x07, 0x78, 0x1e
	.byte 0x04, 0xc7, 0xf8, 0x89, 0xd8, 0x12, 0x1e, 0xfa
	.byte 0x07, 0xd7, 0xfa, 0x9b, 0xd7, 0xfa, 0x8a, 0x24
	.byte 0x00, 0x30, 0x50, 0x00, 0x31, 0x86, 0x00, 0x1e
	.byte 0x11, 0x07, 0xd7, 0xfa, 0x88, 0xd8, 0xcc, 0x00
	.byte 0xff, 0x7e, 0xfb, 0x03, 0xc7, 0xf8, 0x89, 0xd8
	.byte 0x12, 0x1e, 0x1f, 0x07, 0xbf, 0x04, 0x63, 0xde
	.byte 0xa8, 0xde, 0xcf, 0x0c, 0x00, 0x79, 0xe7, 0x03
	.byte 0xc1, 0x1d, 0xfd, 0x21, 0xc9, 0xcc, 0x0f, 0xc9
	.byte 0x8b, 0xd9, 0x12, 0xde, 0x81, 0xd9, 0x88, 0xd8
	.byte 0xcf, 0x0c, 0x00, 0x61, 0x04, 0xd9, 0xca, 0x0c
	.byte 0x00, 0xd9, 0x88, 0xd8, 0xc8, 0xa4, 0x00, 0xd8
	.byte 0x89, 0xaf, 0x04, 0x20, 0xc3, 0x07, 0xe0, 0xf8
	.byte 0x21, 0xd8, 0x12, 0xd8, 0x8a, 0x30, 0x50, 0x00
	.byte 0x1e, 0xc0, 0x06, 0xde, 0x61, 0xde, 0xcf, 0x0c
	.byte 0x00, 0x61, 0xc5, 0x78, 0xa9, 0x03, 0x40, 0x81
	.byte 0x42, 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xcf
	.byte 0x89, 0xd8, 0x12, 0x1e, 0x7d, 0x07, 0xd7, 0xfa
	.byte 0x9b, 0xd7, 0xfa, 0x88, 0xd8, 0xcc, 0x00, 0xff
	.byte 0x7e, 0x8c, 0x03, 0x40, 0x81, 0x42, 0x00, 0x00
	.byte 0x1d, 0x37, 0xd4, 0xfc, 0xcf, 0x89, 0xd8, 0x12
	.byte 0x1e, 0xa8, 0x06, 0xbf, 0x04, 0x63, 0xde, 0xa8
	.byte 0xde, 0xcf, 0x0c, 0x00, 0x79, 0x70, 0x03, 0xc1
	.byte 0x1d, 0xfd, 0x21, 0xc9, 0xcc, 0x0f, 0xc9, 0x8b
	.byte 0xd9, 0x12, 0xde, 0x81, 0xd9, 0x88, 0xd8, 0xcf
	.byte 0x0c, 0x00, 0x61, 0x04, 0xd9, 0xca, 0x0c, 0x00
	.byte 0xd9, 0x88, 0xd8, 0xc8, 0xa4, 0x00, 0xd8, 0x89
	.byte 0xaf, 0x04, 0x20, 0xc3, 0x07, 0xe0, 0xf8, 0x21
	.byte 0xd8, 0x12, 0xd8, 0x8a, 0x30, 0x50, 0x00, 0x1e
	.byte 0x49, 0x06, 0xde, 0x61, 0xde, 0xcf, 0x0c, 0x00
	.byte 0x61, 0xc5, 0x78, 0x32, 0x03, 0x40, 0x81, 0x42
	.byte 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0xcf
	.byte 0x80, 0x00, 0x7e, 0x22, 0x03, 0xc1, 0x1d, 0xfd
	.byte 0x21, 0xc9, 0xcc, 0x0f, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0xd9, 0x88, 0xd8, 0xcf, 0x0c, 0x00, 0x61, 0x04
	.byte 0xd9, 0xca, 0x0c, 0x00, 0xd9, 0x88, 0xd8, 0xc8
	.byte 0xa4, 0x00, 0xd8, 0x89, 0xc1, 0x1e, 0xfd, 0x21
	.byte 0xd8, 0x12, 0xd8, 0x8a, 0x30, 0x50, 0x00, 0x1e
	.byte 0x01, 0x06, 0x78, 0xf2, 0x02, 0x40, 0x81, 0x42
	.byte 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0xcf
	.byte 0x80, 0x00, 0x7e, 0xe2, 0x02, 0xc1, 0x1d, 0xfd
	.byte 0x21, 0xc9, 0xcc, 0x0f, 0xc9, 0x61, 0xc9, 0x8b
	.byte 0xd9, 0x12, 0xd9, 0x88, 0xd8, 0xcf, 0x0c, 0x00
	.byte 0x61, 0x04, 0xd9, 0xca, 0x0c, 0x00, 0xd9, 0x88
	.byte 0xd8, 0xc8, 0xa4, 0x00, 0xd8, 0x89, 0xc1, 0x1f
	.byte 0xfd, 0x21, 0xd8, 0x12, 0xd8, 0x8a, 0x30, 0x50
	.byte 0x00, 0x1e, 0xbf, 0x05, 0x78, 0xb0, 0x02, 0x40
	.byte 0x81, 0x42, 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc
	.byte 0xdb, 0xcf, 0x80, 0x00, 0x7e, 0xa0, 0x02, 0xc1
	.byte 0x1d, 0xfd, 0x21, 0xc9, 0xcc, 0x0f, 0xc9, 0x62
	.byte 0xc9, 0x8b, 0xd9, 0x12, 0xd9, 0x88, 0xd8, 0xcf
	.byte 0x0c, 0x00, 0x61, 0x04, 0xd9, 0xca, 0x0c, 0x00
	.byte 0xd9, 0x88, 0xd8, 0xc8, 0xa4, 0x00, 0xd8, 0x89
	.byte 0xc1, 0x20, 0xfd, 0x21, 0xd8, 0x12, 0xd8, 0x8a
	.byte 0x30, 0x50, 0x00, 0x1e, 0x7d, 0x05, 0x78, 0x6e
	.byte 0x02, 0x40, 0x81, 0x42, 0x00, 0x00, 0x1d, 0x37
	.byte 0xd4, 0xfc, 0xdb, 0xcf, 0x80, 0x00, 0x7e, 0x5e
	.byte 0x02, 0xc1, 0x1d, 0xfd, 0x21, 0xc9, 0xcc, 0x0f
	.byte 0xc9, 0x63, 0xc9, 0x8b, 0xd9, 0x12, 0xd9, 0x88
	.byte 0xd8, 0xcf, 0x0c, 0x00, 0x61, 0x04, 0xd9, 0xca
	.byte 0x0c, 0x00, 0xd9, 0x88, 0xd8, 0xc8, 0xa4, 0x00
	.byte 0xd8, 0x89, 0xc1, 0x21, 0xfd, 0x21, 0xd8, 0x12
	.byte 0xd8, 0x8a, 0x30, 0x50, 0x00, 0x1e, 0x3b, 0x05
	.byte 0x78, 0x2c, 0x02, 0x40, 0x81, 0x42, 0x00, 0x00
	.byte 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0xcf, 0x80, 0x00
	.byte 0x7e, 0x1c, 0x02, 0xc1, 0x1d, 0xfd, 0x21, 0xc9
	.byte 0xcc, 0x0f, 0xc9, 0x64, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0xd9, 0x88, 0xd8, 0xcf, 0x0c, 0x00, 0x61, 0x04
	.byte 0xd9, 0xca, 0x0c, 0x00, 0xd9, 0x88, 0xd8, 0xc8
	.byte 0xa4, 0x00, 0xd8, 0x89, 0xc1, 0x22, 0xfd, 0x21
	.byte 0xd8, 0x12, 0xd8, 0x8a, 0x30, 0x50, 0x00, 0x1e
	.byte 0xf9, 0x04, 0x78, 0xea, 0x01, 0x40, 0x81, 0x42
	.byte 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0xcf
	.byte 0x80, 0x00, 0x7e, 0xda, 0x01, 0xc1, 0x1d, 0xfd
	.byte 0x21, 0xc9, 0xcc, 0x0f, 0xc9, 0x65, 0xc9, 0x8b
	.byte 0xd9, 0x12, 0xd9, 0x88, 0xd8, 0xcf, 0x0c, 0x00
	.byte 0x61, 0x04, 0xd9, 0xca, 0x0c, 0x00, 0xd9, 0x88
	.byte 0xd8, 0xc8, 0xa4, 0x00, 0xd8, 0x89, 0xc1, 0x23
	.byte 0xfd, 0x21, 0xd8, 0x12, 0xd8, 0x8a, 0x30, 0x50
	.byte 0x00, 0x1e, 0xb7, 0x04, 0x78, 0xa8, 0x01, 0x40
	.byte 0x81, 0x42, 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc
	.byte 0xdb, 0xcf, 0x80, 0x00, 0x7e, 0x98, 0x01, 0xc1
	.byte 0x1d, 0xfd, 0x21, 0xc9, 0xcc, 0x0f, 0xc9, 0x66
	.byte 0xc9, 0x8b, 0xd9, 0x12, 0xd9, 0x88, 0xd8, 0xcf
	.byte 0x0c, 0x00, 0x61, 0x04, 0xd9, 0xca, 0x0c, 0x00
	.byte 0xd9, 0x88, 0xd8, 0xc8, 0xa4, 0x00, 0xd8, 0x89
	.byte 0xc1, 0x24, 0xfd, 0x21, 0xd8, 0x12, 0xd8, 0x8a
	.byte 0x30, 0x50, 0x00, 0x1e, 0x75, 0x04, 0x78, 0x66
	.byte 0x01, 0x40, 0x81, 0x42, 0x00, 0x00, 0x1d, 0x37
	.byte 0xd4, 0xfc, 0xdb, 0xcf, 0x80, 0x00, 0x7e, 0x56
	.byte 0x01, 0xc1, 0x1d, 0xfd, 0x21, 0xc9, 0xcc, 0x0f
	.byte 0xc9, 0x67, 0xc9, 0x8b, 0xd9, 0x12, 0xd9, 0x88
	.byte 0xd8, 0xcf, 0x0c, 0x00, 0x61, 0x04, 0xd9, 0xca
	.byte 0x0c, 0x00, 0xd9, 0x88, 0xd8, 0xc8, 0xa4, 0x00
	.byte 0xd8, 0x89, 0xc1, 0x25, 0xfd, 0x21, 0xd8, 0x12
	.byte 0xd8, 0x8a, 0x30, 0x50, 0x00, 0x1e, 0x33, 0x04
	.byte 0x78, 0x24, 0x01, 0x40, 0x81, 0x42, 0x00, 0x00
	.byte 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0xcf, 0x80, 0x00
	.byte 0x7e, 0x14, 0x01, 0xc1, 0x1d, 0xfd, 0x21, 0xc9
	.byte 0xcc, 0x0f, 0xc9, 0x60, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0xd9, 0x88, 0xd8, 0xcf, 0x0c, 0x00, 0x61, 0x04
	.byte 0xd9, 0xca, 0x0c, 0x00, 0xd9, 0x88, 0xd8, 0xc8
	.byte 0xa4, 0x00, 0xd8, 0x89, 0xc1, 0x26, 0xfd, 0x21
	.byte 0xd8, 0x12, 0xd8, 0x8a, 0x30, 0x50, 0x00, 0x1e
	.byte 0xf1, 0x03, 0x78, 0xe2, 0x00, 0x40, 0x81, 0x42
	.byte 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0xcf
	.byte 0x80, 0x00, 0x7e, 0xd2, 0x00, 0xc1, 0x1d, 0xfd
	.byte 0x21, 0xc9, 0xcc, 0x0f, 0xc9, 0xc8, 0x09, 0xc9
	.byte 0x8b, 0xd9, 0x12, 0xd9, 0x88, 0xd8, 0xcf, 0x0c
	.byte 0x00, 0x61, 0x04, 0xd9, 0xca, 0x0c, 0x00, 0xd9
	.byte 0x88, 0xd8, 0xc8, 0xa4, 0x00, 0xd8, 0x89, 0xc1
	.byte 0x27, 0xfd, 0x21, 0xd8, 0x12, 0xd8, 0x8a, 0x30
	.byte 0x50, 0x00, 0x1e, 0xae, 0x03, 0x78, 0x9f, 0x00
	.byte 0x40, 0x81, 0x42, 0x00, 0x00, 0x1d, 0x37, 0xd4
	.byte 0xfc, 0xdb, 0xcf, 0x80, 0x00, 0x7e, 0x8f, 0x00
	.byte 0xc1, 0x1d, 0xfd, 0x21, 0xc9, 0xcc, 0x0f, 0xc9
	.byte 0xc8, 0x0a, 0xc9, 0x8b, 0xd9, 0x12, 0xd9, 0x88
	.byte 0xd8, 0xcf, 0x0c, 0x00, 0x61, 0x04, 0xd9, 0xca
	.byte 0x0c, 0x00, 0xd9, 0x88, 0xd8, 0xc8, 0xa4, 0x00
	.byte 0xd8, 0x89, 0xc1, 0x28, 0xfd, 0x21, 0xd8, 0x12
	.byte 0xd8, 0x8a, 0x30, 0x50, 0x00, 0x1e, 0x6b, 0x03
	.byte 0x68, 0x5d, 0x40, 0x81, 0x42, 0x00, 0x00, 0x1d
	.byte 0x37, 0xd4, 0xfc, 0xdb, 0xcf, 0x80, 0x00, 0x6e
	.byte 0x4e, 0xc1, 0x1d, 0xfd, 0x21, 0xc9, 0xcc, 0x0f
	.byte 0xc9, 0xc8, 0x0b, 0xc9, 0x8b, 0xd9, 0x12, 0xd9
	.byte 0x88, 0xd8, 0xcf, 0x0c, 0x00, 0x61, 0x04, 0xd9
	.byte 0xca, 0x0c, 0x00, 0xd9, 0x88, 0xd8, 0xc8, 0xa4
	.byte 0x00, 0xd8, 0x89, 0xc1, 0x29, 0xfd, 0x21, 0xd8
	.byte 0x12, 0xd8, 0x8a, 0x30, 0x50, 0x00, 0x1e, 0x2a
	.byte 0x03, 0x68, 0x1c, 0xf1, 0xb4, 0xcf, 0x60, 0x68
	.byte 0x16, 0xf1, 0xb8, 0xcf, 0x60, 0x68, 0x10, 0xf1
	.byte 0xbc, 0xcf, 0x60, 0x68, 0x0a, 0xf1, 0xc0, 0xcf
	.byte 0x60, 0x68, 0x04, 0xf1, 0xc4, 0xcf, 0x60, 0x1d
	.byte 0x79, 0xbf, 0xfe, 0x5e, 0xef, 0x64, 0x0e

Song_SendPartDataBlocks:
	pushw iz
	ldda32 xwa, 53172
	cp xwa, 0xFFFFFFFF
	jr z, LABEL_FEB945
	lds wa, 0
	call COMM_SendPartDataBlock

LABEL_FEB945:
	ldda32 xwa, 53176
	cp xwa, 0xFFFFFFFF
	jr z, LABEL_FEB957
	lds wa, 1
	call COMM_SendPartDataBlock

LABEL_FEB957:
	ldda32 xwa, 53180
	cp xwa, 0xFFFFFFFF
	jr z, LABEL_FEB969
	lds wa, 4
	call COMM_SendPartDataBlock

LABEL_FEB969:
	ldda32 xwa, 53184
	cp xwa, 0xFFFFFFFF
	jr z, LABEL_FEB97B
	lds wa, 2
	call COMM_SendPartDataBlock

LABEL_FEB97B:
	ldda32 xwa, 53188
	cp xwa, 0xFFFFFFFF
	jr z, LABEL_FEB98D
	lds wa, 3
	call COMM_SendPartDataBlock

LABEL_FEB98D:
	cpdi16 53192, 65535
	jr z, LABEL_FEB99F
	ldda16 xwa, 53192
	extz wa
	call LABEL_FEF810

LABEL_FEB99F:
	cpdi16 53194, 65535
	jr z, LABEL_FEB9B1
	ldda16 xwa, 53194
	extz wa
	call LABEL_FEF7CE

LABEL_FEB9B1:
	cpdi16 53196, 65535
	jr z, LABEL_FEB9C3
	ldda16 xwa, 53196
	extz wa
	call LABEL_FEF7EF

LABEL_FEB9C3:
	cpdi16 53198, 65535
	jr z, LABEL_FEB9D5
	ldda16 xwa, 53198
	extz wa
	call LABEL_FEF831

LABEL_FEB9D5:
	lds iz, 0
	cp iz, 0x18
	jrl gt, LABEL_FEBA88

LABEL_FEB9DE:
	ld wa, iz
	add wa, wa
	ldada xbc, 53200
	extz xwa
	add xwa, xbc
	cpw (xwa), 0xFFFF
	jr z, LABEL_FEBA55
	ld wa, iz
	add wa, wa
	ldada xbc, 53264
	extz xwa
	add xwa, xbc
	cpw (xwa), 0xFFFF
	jr z, LABEL_FEBA55
	ld wa, iz
	add wa, wa
	ldada xbc, 53328
	extz xwa
	add xwa, xbc
	cpw (xwa), 0xFFFF
	jr nz, LABEL_FEBA1F
	ld wa, iz
	ldw bc, 0x5E
	call SndParam_LookupViaEncode
	jr LABEL_FEBA2D

LABEL_FEBA1F:
	ld wa, iz
	add wa, wa
	ldada xbc, 53328
	extz xwa
	add xwa, xbc
	ld hl, (xwa)

LABEL_FEBA2D:
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
	calr LABEL_FEBB86
	jr LABEL_FEBA7F

LABEL_FEBA55:
	ld wa, iz
	add wa, wa
	ldada xbc, 53328
	extz xwa
	add xwa, xbc
	cpw (xwa), 0xFFFF
	jr z, LABEL_FEBA7F
	ld hl, iz
	ld wa, iz
	add wa, wa
	ldada xbc, 53328
	extz xwa
	add xwa, xbc
	ld de, (xwa)
	ld wa, hl
	ldw bc, 0x5E
	calr MIDI_SendControlChange

LABEL_FEBA7F:
	inc 1, iz
	cp iz, 0x18
	jrl le, LABEL_FEB9DE

LABEL_FEBA88:
	call MIDI_PostSendStub
	calr LABEL_FEBA91
	popw iz
	ret

LABEL_FEBA91:
	ld xwa, 0xFFFFFFFF
	stda32 53172, xwa
	ld xwa, 0xFFFFFFFF
	stda32 53176, xwa
	ld xwa, 0xFFFFFFFF
	stda32 53180, xwa
	ld xwa, 0xFFFFFFFF
	stda32 53184, xwa
	ld xwa, 0xFFFFFFFF
	stda32 53188, xwa
	stdi16 53192, 65535
	stdi16 53194, 65535
	stdi16 53196, 65535
	stdi16 53198, 65535
	lds de, 0
	cp de, 0x18
	ret gt

LABEL_FEBADE:
	ld wa, de
	add wa, wa
	ldada xbc, 53200
	extz xwa
	add xwa, xbc
	ldw (xwa), 0xFFFF
	ld wa, de
	add wa, wa
	ldada xbc, 53264
	extz xwa
	add xwa, xbc
	ldw (xwa), 0xFFFF
	ld wa, de
	add wa, wa
	ldada xbc, 53328
	extz xwa
	add xwa, xbc
	ldw (xwa), 0xFFFF
	inc 1, de
	cp de, 0x18
	jr le, LABEL_FEBADE
	ret

; ============================================================================
; MIDI_SendControlChange - Send a MIDI Control Change message
; ============================================================================
; Input:  A = MIDI channel, C = controller number, E = value
; Output: None (sends via SubCPU comm)
; Builds [4, 0xB0, chan, ctrl, val] packet, transmits via MIDI_SendCmdPacket.
; ============================================================================
MIDI_SendControlChange:
	dec 6, xsp
	ld (xsp + 256), 0x4
	ld (xsp + 1), 0xB0
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
	ld (xsp + 1), 0xE0
	ld (xsp + 2), a
	ld a, c
	res 7, a
	ld (xsp + 3), a
	and bc, 0x3FFF
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
	ld (xsp + 1), 0xD0
	ld (xsp + 2), a
	ld (xsp + 3), 0x0
	ld (xsp + 4), c
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	inc 6, xsp
	ret

LABEL_FEBB86:
	lda xsp, (xsp - 12)
	pushw iz
	ld (xsp + 12), wa
	ld iz, (xsp + 18)
	cp iz, 0xFFFF
	jr nz, LABEL_FEBB9A
	lds iz, 0
	jr LABEL_FEBBA5

LABEL_FEBB9A:
	lds wa, 0
	cps iz, 0
	jr z, LABEL_FEBBA3
	ldw wa, 0x7F

LABEL_FEBBA3:
	ld iz, wa

LABEL_FEBBA5:
	ld (xsp + 10), c
	ld (xsp + 8), e
	lda xwa, (xsp + 10)
	ld xde, xwa
	lda xwa, (xsp + 8)
	ld xbc, xwa
	ld xwa, xde
	call SndParam_ApplyMaskClamp
	ld (xsp + 2), 0x5
	ld (xsp + 3), 0xC0
	ld wa, (xsp + 12)
	ld (xsp + 4), a
	ld a, (xsp + 10)
	ld (xsp + 5), a
	ld a, (xsp + 8)
	ld (xsp + 6), a
	ldto_berp A, 0xF8
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
	ldw wa, 0xFF
	lds bc, 2
	call MidiEvent_ConfigChannel

SeqVoice_CheckAndRetry:
	cpw (xsp + 12), 0x15
	jr nz, LABEL_FEBC1E
	ldw wa, 0xFF
	ldw bc, 0x15
	call MidiEvent_ConfigChannel

LABEL_FEBC1E:
	cpw (xsp + 12), 0x16
	jr nz, LABEL_FEBC2F
	ldw wa, 0xFF
	ldw bc, 0x16
	call MidiEvent_ConfigChannel

LABEL_FEBC2F:
	popw iz
	lda xsp, (xsp + 12)
	retd 0x2

LABEL_FEBC36:
	dec 6, xsp
	ld (xsp + 256), 0x4
	ld (xsp + 1), 0xF0
	ld (xsp + 2), a
	ld (xsp + 3), c
	ld (xsp + 4), e
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	inc 6, xsp
	ret

LABEL_FEBC56:
	.byte 0xc9, 0xcf, 0x80, 0x76, 0xa6, 0x00, 0xc9, 0xdd
	.byte 0x66, 0x6a, 0xc9, 0xdc, 0x66, 0x5f, 0xc9, 0xdb
	.byte 0x66, 0x54, 0xc9, 0xcf, 0x42, 0x66, 0x48, 0xc9
	.byte 0xcf, 0x41, 0x66, 0x3c, 0xc9, 0xcf, 0x40, 0x66
	.byte 0x30, 0xc9, 0xd8, 0x66, 0x25, 0xd8, 0x12, 0xd8
	.byte 0xca, 0x10, 0x00, 0xd8, 0xd8, 0x71, 0x82, 0x00
	.byte 0xd8, 0xde, 0x6a, 0x7e, 0xd8, 0x80, 0xf2, 0x5a
	.byte 0xc1, 0xee, 0x34, 0xd3, 0x07, 0xf0, 0xe0, 0x20
	.byte 0xf2, 0xa0, 0xbc, 0xfe, 0x34, 0xf3, 0x07, 0xf0
	.byte 0xe0, 0xd8, 0xf2, 0x9a, 0xc0, 0xee, 0x33, 0x68
	.byte 0x66, 0xf2, 0xa6, 0xc0, 0xee, 0x33, 0x68, 0x5f
	.byte 0xf2, 0xb2, 0xc0, 0xee, 0x33, 0x68, 0x58, 0xf2
	.byte 0xbe, 0xc0, 0xee, 0x33, 0x68, 0x51, 0xf2, 0xe2
	.byte 0xc0, 0xee, 0x33, 0x68, 0x4a, 0xf2, 0xee, 0xc0
	.byte 0xee, 0x33, 0x68, 0x43, 0xf2, 0xfa, 0xc0, 0xee
	.byte 0x33, 0x68, 0x3c, 0xf2, 0x06, 0xc1, 0xee, 0x33
	.byte 0x68, 0x35, 0xf2, 0x12, 0xc1, 0xee, 0x33, 0x68
	.byte 0x2e, 0xf2, 0x1e, 0xc1, 0xee, 0x33, 0x68, 0x27
	.byte 0xf2, 0x2a, 0xc1, 0xee, 0x33, 0x68, 0x20, 0xf2
	.byte 0x36, 0xc1, 0xee, 0x33, 0x68, 0x19, 0xf2, 0x42
	.byte 0xc1, 0xee, 0x33, 0x68, 0x12, 0xf2, 0x4e, 0xc1
	.byte 0xee, 0x33, 0x68, 0x0b, 0xf1, 0x1e, 0xfd, 0x33
	.byte 0x68, 0x05, 0xf2, 0x9a, 0xc0, 0xee, 0x33, 0x0e
	.byte 0xc9, 0xcf, 0x80, 0x76, 0x85, 0x00, 0xc9, 0xdd
	.byte 0x66, 0x5a, 0xc9, 0xdc, 0x66, 0x52, 0xc9, 0xdb
	.byte 0x66, 0x4a, 0xc9, 0xcf, 0x42, 0x66, 0x40, 0xc9
	.byte 0xcf, 0x41, 0x66, 0x36, 0xc9, 0xcf, 0x40, 0x66
	.byte 0x2c, 0xc9, 0xd8, 0x66, 0x24, 0xd8, 0x12, 0xd8
	.byte 0xca, 0x10, 0x00, 0xd8, 0xd8, 0x61, 0x61, 0xd8
	.byte 0xde, 0x6a, 0x5d, 0xd8, 0x80, 0xf2, 0x68, 0xc1
	.byte 0xee, 0x34, 0xd3, 0x07, 0xf0, 0xe0, 0x20, 0xf2
	.byte 0x57, 0xbd, 0xfe, 0x34, 0xf3, 0x07, 0xf0, 0xe0
	.byte 0xd8, 0xdb, 0xa8
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
	ld (xsp + 1), 0xF0
	ld (xsp + 2), 0x50
	ld (xsp + 3), 0x87
	ld (xsp + 4), a
	lda xwa, (xsp)
	call MIDI_SendCmdPacket
	call MIDI_PostSendStub
	inc 6, xsp
	ret

LABEL_FEBDC3:
	.byte 0x30, 0x50, 0x00, 0x31, 0x85, 0x00, 0xda, 0xa8
	.byte 0x1e, 0x68, 0xfe, 0x1b, 0x79, 0xbf, 0xfe

LABEL_FEBDD2:
	dec 4, xsp
	ld (xsp + 2), a
	ldb a, 0x1
	cp (xsp + 2), 0x0
	jr nz, LABEL_FEBDE1
	ldb a, 0x2

LABEL_FEBDE1:
	ld (xsp + 2), a
	extz wa
	ld de, wa
	ldw wa, 0x7F
	ldw bc, 0x9
	calr LABEL_FEBC36
	ldw (xsp), 0x0
	cpw (xsp), 0x16
	jr gt, LABEL_FEBE33

LABEL_FEBDFB:
	ld wa, (xsp)
	ldw bc, 0x8
	call SndParam_LookupViaEncode
	cps hl, 1
	jr nz, LABEL_FEBE0E
	ld (xsp + 2), 0x0
	jr LABEL_FEBE19

LABEL_FEBE0E:
	ld wa, (xsp)
	lds bc, 7
	call SndParam_LookupViaEncode
	ld (xsp + 2), l

LABEL_FEBE19:
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
	jr le, LABEL_FEBDFB

LABEL_FEBE33:
	ld xwa, 0x2880B
	call SndParam_LookupReadOnly
	cps hl, 1
	jr nz, LABEL_FEBE46
	ld (xsp + 2), 0x0
	jr LABEL_FEBE52

LABEL_FEBE46:
	ld xwa, 0x28801
	call SndParam_LookupReadOnly
	ld (xsp + 2), l

LABEL_FEBE52:
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
	jr c, LABEL_FEBE8B
	ld wa, iz
	add wa, wa
	sub wa, 0x80

LABEL_FEBE8B:
	sll iz, 7
	or iz, wa
	ldi_werp 0xFA, 0
	cp_erpw 0xFA, 0x0F, 0x00
	jr ge, LABEL_FEBEB6

LABEL_FEBE9A:
	ldto_werp WA, 0xFA
	ld bc, iz
	calr MIDI_SendPitchBend
	ldto_werp WA, 0xFA
	lds bc, 1
	lds de, 0
	calr MIDI_SendControlChange
	inc1_werp 0xFA
	cp_erpw 0xFA, 0x0F, 0x00
	jr lt, LABEL_FEBE9A

LABEL_FEBEB6:
	ldda8 a, 14235
	and a, 0xF
	jr z, LABEL_FEBEE7
	ldi_erpw 0xFA, 0x10, 0x00
	cp_erpw 0xFA, 0x13, 0x00
	jr ge, LABEL_FEBEE7

LABEL_FEBECB:
	ldto_werp WA, 0xFA
	ld bc, iz
	calr MIDI_SendPitchBend
	ldto_werp WA, 0xFA
	lds bc, 1
	lds de, 0
	calr MIDI_SendControlChange
	inc1_werp 0xFA
	cp_erpw 0xFA, 0x13, 0x00
	jr lt, LABEL_FEBECB

LABEL_FEBEE7:
	call MIDI_PostSendStub
	pop xiz
	ret

LABEL_FEBEED:
	.byte 0x30, 0x50, 0x00, 0x31, 0x92, 0x00, 0xda, 0xa8
	.byte 0x1e, 0x3e, 0xfd, 0x1b, 0x79, 0xbf, 0xfe

MIDI_SendAllSoundOff:
	pushw iz
	lds iz, 0
	cp iz, 0x18
	jr gt, LABEL_FEBF17

LABEL_FEBF05:
	ld wa, iz
	ldw bc, 0x78
	lds de, 0
	calr MIDI_SendControlChange
	inc 1, iz
	cp iz, 0x18
	jr le, LABEL_FEBF05

LABEL_FEBF17:
	call MIDI_PostSendStub
	popw iz
	ret

LABEL_FEBF1D:
	.byte 0x27, 0x00, 0xd8, 0x12, 0xd8, 0xca, 0x10, 0x00
	.byte 0xd8, 0xd8, 0xb0, 0xf1, 0xd8, 0xcf, 0x08, 0x00
	.byte 0xb0, 0xfa, 0xd8, 0x80, 0xf2, 0x76, 0xc1, 0xee
	.byte 0x34, 0xd3, 0x07, 0xf0, 0xe0, 0x20, 0xf2, 0x45
	.byte 0xbf, 0xfe, 0x34, 0xf3, 0x07, 0xf0, 0xe0, 0xd8
	.byte 0x27, 0x01, 0x0e

; ============================================================================
; MIDI_SendCmdPacket - Send a pre-built MIDI command packet
; ============================================================================
; Input:  XWA = pointer to command buffer (first byte = count)
; Output: None
; Iterates channel table at 53392, transmits via sendCOMM (XDE=0xD090).
; Low-level MIDI/audio command packet sender.
; ============================================================================
MIDI_SendCmdPacket:
	lds hl, 0
	jr LABEL_FEBF60

LABEL_FEBF4C:
	ldada xde, 53392
	ld bc, hl
	inc 1, bc
	ld_srib3 C, 0x07, 0xE0, 0xE4
	lda_dri3 XHL, 0x07, 0xE8, 0xEC
	inc 1, hl

LABEL_FEBF60:
	ld c, (xwa)
	extz bc
	cp hl, bc
	jr lt, LABEL_FEBF4C
	ld a, (xwa)
	extz wa
	ld xde, 0xD090
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

LABEL_FEBF7F:
	pushw iz
	calr LABEL_FEBFB1
	ld iz, hl
	ld wa, iz
	cp wa, 0xFFFE
	jr z, LABEL_FEBFA6
	cp wa, 0xFFFF
	jr z, LABEL_FEBFA6
	cp wa, 0xFFFD
	jr nz, LABEL_FEBFAF
	lds iz, 0
	calr Song_AbortPlayback
	ld wa, iz
	call SongMode_VoiceStateDisp
	jr LABEL_FEBFAF

LABEL_FEBFA6:
	calr Song_AbortPlayback
	ld wa, iz
	call SongMode_VoiceStateDisp

LABEL_FEBFAF:
	popw iz
	ret

LABEL_FEBFB1:
	push xiz
	cpdi8 59844, 0
	jr nz, LABEL_FEBFBE
	lds hl, 0
	jrl Acc_PopIzRet

LABEL_FEBFBE:
	ldda16 xwa, 59877
	and wa, 0x2
	cps wa, 2
	jr nz, LABEL_FEBFD7
	ldda16 xwa, 59877
	bit 2, wa
	jr nz, LABEL_FEBFD7
	lds hl, 0
	jr Acc_PopIzRet

LABEL_FEBFD7:
	lds wa, 1
	calr AccWrap_PlayModeStateMachine
	ldda16 xwa, 59877
	ldda16 xbc, 59887
	calr LABEL_FEC405
	ld xiz, xhl
	cpdi8 59876, 4
	jr nz, AccSong_ProcessRecord_Loop
	ld xwa, xiz
	calr LABEL_FEDB57

AccSong_ProcessRecord_Loop:
	cpdm32 59879, xiz
	jr ugt, LABEL_FEC04A
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEC009
	ldw hl, 0xFFFF
	jr Acc_PopIzRet

LABEL_FEC009:
	ldda8 a, 59876
	cps a, 4
	jr z, LABEL_FEC03B
	cps a, 3
	jr z, LABEL_FEC02C
	cps a, 2
	jr z, LABEL_FEC02C
	cps a, 1
	jr nz, AccSong_ProcessRecord_Loop
	ld a, l
	extz wa
	calr LABEL_FEC89A
	ld wa, hl
	cps wa, 0
	jr ge, AccSong_ProcessRecord_Loop
	jr Acc_PopIzRet

LABEL_FEC02C:
	ld a, l
	extz wa
	calr MidiSysMsg_Handler
	ld wa, hl
	cps wa, 0
	jr ge, AccSong_ProcessRecord_Loop
	jr Acc_PopIzRet

LABEL_FEC03B:
	ld a, l
	extz wa
	calr LABEL_FEDA34
	ld wa, hl
	cps wa, 0
	jr ge, AccSong_ProcessRecord_Loop
	jr Acc_PopIzRet

LABEL_FEC04A:
	lds hl, 0

Acc_PopIzRet:
	pop xiz
	ret

Acc_LoadAndStartPlayback:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld (xsp + 6), a
	calr LABEL_FEC400
	calr LABEL_FEE039
	ld a, (xsp + 6)
	stda8 59876, a
	call Audio_ConfigureDSP
	ld xwa, (xsp + 2)
	calr LABEL_FEDF6D
	ld iz, hl
	ld wa, iz
	cps wa, 0
	jr ge, LABEL_FEC07D
	calr Song_AbortPlayback
	ld hl, iz
	jr SeqVoice_PopIzReturn

LABEL_FEC07D:
	ld a, (xsp + 6)
	calr LABEL_FEC0E1
	ld iz, hl
	ld wa, iz
	cps wa, 0
	jr ge, LABEL_FEC092
	calr Song_AbortPlayback
	ld hl, iz
	jr SeqVoice_PopIzReturn

LABEL_FEC092:
	ld a, (xsp + 6)
	calr LABEL_FEC0C7
	ld iz, hl
	ld wa, iz
	cps wa, 0
	jr ge, LABEL_FEC0A7
	calr Song_AbortPlayback
	ld hl, iz
	jr SeqVoice_PopIzReturn

LABEL_FEC0A7:
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

LABEL_FEC0C7:
	cps a, 4
	jr z, LABEL_FEC0DD
	cps a, 2
	jr z, LABEL_FEC0D8
	cps a, 1
	ret nz
	calr LABEL_FEC5D6
	jr LABEL_FEC0E0

LABEL_FEC0D8:
	calr LABEL_FED0A8
	jr LABEL_FEC0E0

LABEL_FEC0DD:
	calr LABEL_FED990

LABEL_FEC0E0:
	ret

LABEL_FEC0E1:
	pushw iz
	cps a, 4
	jr z, LABEL_FEC107
	cps a, 2
	jr z, LABEL_FEC100
	cps a, 3
	jr z, LABEL_FEC0F9
	cps a, 1
	jr nz, SwbtWr_ReinitOutputBank_Wrapper
	calr LABEL_FEC83A
	ld iz, hl
	jr SwbtWr_ReinitOutputBank_Wrapper

LABEL_FEC0F9:
	calr LABEL_FED334
	ld iz, hl
	jr SwbtWr_ReinitOutputBank_Wrapper

LABEL_FEC100:
	calr LABEL_FED406
	ld iz, hl
	jr SwbtWr_ReinitOutputBank_Wrapper

LABEL_FEC107:
	calr LABEL_FED9E6
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
	calr LABEL_FEE008
	jrl LABEL_FEE039

LABEL_FEC12A:
	lda xsp, (xsp - 14)
	pushw iz
	ld (xsp + 14), wa
	ldw (xsp + 2), 0x1
	ld wa, (xsp + 14)
	stda16 59891, xwa
	lds iz, 0
	cp iz, 0x10
	jr ge, LABEL_FEC1BE

LABEL_FEC145:
	ld wa, (xsp + 14)
	and wa, (xsp + 2)
	jr z, LABEL_FEC1B0
	ldto_berp A, 0xF8
	or a, 0xB0
	ld (xsp + 4), a
	ld (xsp + 5), 0x7B
	ld (xsp + 6), 0x0
	ei 6
	lda xwa, (xsp + 4)
	push xwa
	pushw 0x3
	call SeqMain_WriteBytes
	ei 0
	ldto_berp A, 0xF8
	or a, 0xB0
	ld (xsp + 10), a
	ld (xsp + 11), 0x0
	ld (xsp + 12), 0x40
	ei 6
	lda xwa, (xsp + 10)
	push xwa
	pushw 0x3
	call SeqMain_WriteBytes
	ei 0
	ldto_berp A, 0xF8
	or a, 0xB0
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

LABEL_FEC1B0:
	ld wa, (xsp + 2)
	add (xsp + 2), wa
	inc 1, iz
	cp iz, 0x10
	jr lt, LABEL_FEC145

LABEL_FEC1BE:
	popw iz
	lda xsp, (xsp + 14)
	ret

Acc_TransitionPlayMode:
	ldda16 xwa, 59877
	bit 0, wa
	jr z, LABEL_FEC1DA
	lds wa, 4
	calr AccWrap_PlayModeStateMachine
	calr MIDI_ResetAllChannels
	ordi16 59877, 2

LABEL_FEC1DA:
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

LABEL_FEC208:
	.byte 0xd1, 0xe5, 0xe9, 0x3c, 0xfb, 0xff, 0x0e

FileIO_ReadMultiByteRecord:
	push xiz
	calr FileIO_ReadNextRecord
	ld iz, hl
	exts xiz
	ld xwa, xiz
	cp xwa, 0x0
	jr ge, LABEL_FEC228
	ld xhl, 0xFFFFFFFF
	jr LABEL_FEC257

LABEL_FEC228:
	bit 7, iz
	jr z, LABEL_FEC255
	and xiz, 0x7F

LABEL_FEC233:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEC243
	ld xhl, 0xFFFFFFFF
	jr LABEL_FEC257

LABEL_FEC243:
	ld wa, hl
	and wa, 0x7F
	exts xwa
	sla xiz, 7
	add xiz, xwa
	bit 7, hl
	jr nz, LABEL_FEC233

LABEL_FEC255:
	ld xhl, xiz

LABEL_FEC257:
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
	jr ge, LABEL_FEC27B
	ld xhl, 0xFFFFFFFF
	jr LABEL_FEC2DC

LABEL_FEC27B:
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
	jr z, LABEL_FEC2DA
	ld xwa, 0x7F
	and (xsp), xwa

LABEL_FEC29D:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEC2AE
	ld xhl, 0xFFFFFFFF
	jr LABEL_FEC2DC

LABEL_FEC2AE:
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
	and wa, 0x7F
	ld bc, wa
	exts xbc
	ld xwa, (xsp)
	sla xwa, 7
	add xwa, xbc
	ld (xsp), xwa
	bit 7, hl
	jr nz, LABEL_FEC29D

LABEL_FEC2DA:
	ld xhl, (xsp)

LABEL_FEC2DC:
	lda xsp, (xsp + 12)
	ret

LABEL_FEC2E0:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld (xsp + 6), wa
	lds iz, 0
	ld wa, iz
	cp wa, (xsp + 6)
	jr nc, LABEL_FEC312

LABEL_FEC2F2:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEC301
	ldw hl, 0xFFFF
	jr LABEL_FEC314

LABEL_FEC301:
	ld xwa, (xsp + 2)
	lda_dri3 XSP, 0x07, 0xE0, 0xF8
	inc 1, iz
	ld wa, iz
	cp wa, (xsp + 6)
	jr c, LABEL_FEC2F2

LABEL_FEC312:
	lds hl, 0

LABEL_FEC314:
	popw iz
	inc 6, xsp
	ret

AccWrap_PlayModeStateMachine:
	cps wa, 4
	jrl z, LABEL_FEC3C9
	cps wa, 3
	jrl z, LABEL_FEC3B0
	cps wa, 2
	jr z, LABEL_FEC373
	cps wa, 1
	jr z, LABEL_FEC344
	cps wa, 6
	ret nz
	stdi16 53402, 30
	ei 6
	stdi16 1052, 0
	stdi8 1051, 0
	ei 0
	ret

LABEL_FEC344:
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

LABEL_FEC373:
	cpdi16 53402, 0
	jr le, LABEL_FEC382
	stdi16 53402, 0
	ret

LABEL_FEC382:
	call AccWrap_PlayModeDispatch
	lds32 xwa, 0
	cp xwa, 0x7FFE
	jr ugt, LABEL_FEC3A0

LABEL_FEC390:
	bitda 2, 1057
	jr nz, LABEL_FEC3A0
	inc 1, xwa
	cp xwa, 0x7FFE
	jr ule, LABEL_FEC390

LABEL_FEC3A0:
	ei 6
	stdi16 1052, 0
	stdi8 1051, 0
	ei 0
	ret

LABEL_FEC3B0:
	call AccWrap_PlayModeStart
	ei 6
	ldda32 xwa, 53412
	stda16 1052, xwa
	ldda32 xwa, 53408
	stda8 1051, a
	ei 0
	ret

LABEL_FEC3C9:
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
	cp xwa, 0x7FFE
	ret ugt

LABEL_FEC3EF:
	bitda 2, 1057
	ret nz
	inc 1, xwa
	cp xwa, 0x7FFE
	jr ule, LABEL_FEC3EF
	ret

LABEL_FEC400:
	resda 2, 10407
	ret

LABEL_FEC405:
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
	jr z, LABEL_FEC478
	ldda16 xwa, 60430
	decdi16 1, 60430
	cps wa, 0
	jr ge, LABEL_FEC478
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

LABEL_FEC478:
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
	jr ge, LABEL_FEC500

LABEL_FEC4A7:
	ldto_berp A, 0xF8
	or a, 0xB0
	ld (xsp + 2), a
	ld (xsp + 3), 0x7B
	ld (xsp + 4), 0x0
	lda xwa, (xsp + 2)
	ld xbc, xwa
	lds wa, 3
	calr MIDI_SendSinglePacket
	ldto_berp A, 0xF8
	or a, 0xB0
	ld (xsp + 2), a
	ld (xsp + 3), 0x0
	ld (xsp + 4), 0x40
	lda xwa, (xsp + 2)
	ld xbc, xwa
	lds wa, 3
	calr MIDI_SendSinglePacket
	ldto_berp A, 0xF8
	or a, 0xB0
	ld (xsp + 2), a
	ld (xsp + 3), 0x40
	ld (xsp + 4), 0x0
	lda xwa, (xsp + 2)
	ld xbc, xwa
	lds wa, 3
	calr MIDI_SendSinglePacket
	inc 1, iz
	cp iz, 0x10
	jr lt, LABEL_FEC4A7

LABEL_FEC500:
	popw iz
	lda xsp, (xsp + 10)
	ret

MIDI_SendSinglePacket:
	lda xsp, (xsp - 34)
	push xiz
	ld xiz, xbc
	ld (xsp + 36), wa
	lds wa, 1
	ld xiy, 0xEEC188
	lda xix, (xsp + 4)
	ldw bc, 0x10
	ldirw
	cp (xiz), 0xF0
	jr c, LABEL_FEC537
	cp (xiz), 0xF7
	jr ugt, LABEL_FEC537
	ei 6
	push xiz
	pushm (xsp + 40)
	call SeqBuf2_WriteBytes
	inc 6, xsp
	ei 0
	jr LABEL_FEC55C

LABEL_FEC537:
	ld a, (xiz)
	and a, 0xF
	extz wa
	add wa, wa
	lda xbc, (xsp + 4)
	ldda16 xde, 59891
	and_sriw_rm DE, 0x07, 0xE4, 0xE0
	jr nz, LABEL_FEC55C
	ei 6
	push xiz
	pushm (xsp + 40)
	call SeqMain_WriteBytes
	inc 6, xsp
	ei 0

LABEL_FEC55C:
	call GetPlayState2
	cps l, 0
	jr z, LABEL_FEC575
	cpdi8 59876, 1
	jr nz, LABEL_FEC575
	push xiz
	pushm (xsp + 40)
	call SeqOut_WriteTimedBytes
	inc 6, xsp

LABEL_FEC575:
	pop xiz
	lda xsp, (xsp + 34)
	ret

LABEL_FEC57A:	.asciz "¿Þ7>éŽ¿$PØ©E¨Áî"
	.byte 0xbf, 0x04, 0x34, 0x31, 0x10, 0x00, 0x95, 0x11
	.byte 0x86, 0x3f, 0xf0, 0x67, 0x15, 0x86, 0x3f, 0xf7
	.byte 0x6b, 0x10, 0x06, 0x06, 0x3e, 0x9f, 0x28, 0x04
	.byte 0x1d, 0xdf, 0x28, 0xef, 0xef, 0x66, 0x06, 0x00
	.byte 0x68, 0x25, 0x86, 0x21, 0xc9, 0xcc, 0x0f, 0xd8
	.byte 0x12, 0xd8, 0x80, 0xbf, 0x04, 0x31, 0xd1, 0xf3
	.byte 0xe9, 0x22, 0xd3, 0x07, 0xe4, 0xe0, 0xc2, 0x6e
	.byte 0x0e, 0x06, 0x06, 0x3e, 0x9f, 0x28, 0x04, 0x1d
	.byte 0x83, 0x27, 0xef, 0xef, 0x66, 0x06, 0x00, 0x5e
	.byte 0xbf, 0x22, 0x37, 0x0e

LABEL_FEC5D6:
	st_dri3b L, 0xFD, 0x72, 0xFF
	pushw iz
	ld xiy, 0xEEC1C8
	st_dri3b D, 0xFD, 0x88, 0x00
	lds bc, 2
	ldirw
	ldi85
	ld xiy, 0xEEC1CE
	st_dri3b D, 0xFD, 0x82, 0x00
	lds bc, 2
	ldirw
	ldi85
	stiw_dri 0xFD, 0x8E, 0x00, 0x00, 0x00
	cp_sriw_im 0xFD, 0x8E, 0x00, 0x03, 0x00
	jr ugt, LABEL_FEC63C

LABEL_FEC60C:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEC61C
	ldw hl, 0xFFFF
	jrl SeqFile_Epilogue

LABEL_FEC61C:
	ld_sriw WA, (xsp + 0x008e)
	extz xwa
	st_dri3b A, 0xFD, 0x88, 0x00
	add xbc, xwa
	cp l, (xbc)
	jr nz, LABEL_FEC63C
	inc_sriw 1, 0xFD, 0x8E, 0x00
	cp_sriw_im 0xFD, 0x8E, 0x00, 0x03, 0x00
	jr ule, LABEL_FEC60C

LABEL_FEC63C:
	cp_sriw_im 0xFD, 0x8E, 0x00, 0x04, 0x00
	jrl z, LABEL_FEC6E9
	lds iz, 0
	lds wa, 3
	sub_sriw_rm WA, 0xFD, 0x8E, 0x00
	cp iz, wa
	jr ugt, LABEL_FEC66E

LABEL_FEC653:
	call TaskBuf_ReadNextByte
	cps hl, 0
	jr ge, LABEL_FEC661
	ldw hl, 0xFFFF
	jrl SeqFile_Epilogue

LABEL_FEC661:
	inc 1, iz
	lds wa, 3
	sub_sriw_rm WA, 0xFD, 0x8E, 0x00
	cp iz, wa
	jr ule, LABEL_FEC653

LABEL_FEC66E:
	stiw_dri 0xFD, 0x8E, 0x00, 0x00, 0x00
	cp_sriw_im 0xFD, 0x8E, 0x00, 0x7B, 0x00
	jr ugt, LABEL_FEC69A

LABEL_FEC67E:
	call TaskBuf_ReadNextByte
	cps hl, 0
	jr ge, LABEL_FEC68C
	ldw hl, 0xFFFF
	jrl SeqFile_Epilogue

LABEL_FEC68C:
	inc_sriw 1, 0xFD, 0x8E, 0x00
	cp_sriw_im 0xFD, 0x8E, 0x00, 0x7B, 0x00
	jr ule, LABEL_FEC67E

LABEL_FEC69A:
	stiw_dri 0xFD, 0x8E, 0x00, 0x00, 0x00
	cp_sriw_im 0xFD, 0x8E, 0x00, 0x03, 0x00
	jr ugt, LABEL_FEC6DA

LABEL_FEC6AA:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEC6BA
	ldw hl, 0xFFFF
	jrl SeqFile_Epilogue

LABEL_FEC6BA:
	ld_sriw WA, (xsp + 0x008e)
	extz xwa
	st_dri3b A, 0xFD, 0x88, 0x00
	add xbc, xwa
	cp l, (xbc)
	jr nz, LABEL_FEC6DA
	inc_sriw 1, 0xFD, 0x8E, 0x00
	cp_sriw_im 0xFD, 0x8E, 0x00, 0x03, 0x00
	jr ule, LABEL_FEC6AA

LABEL_FEC6DA:
	cp_sriw_im 0xFD, 0x8E, 0x00, 0x04, 0x00
	jr z, LABEL_FEC6E9
	ldw hl, 0xFFFE
	jrl SeqFile_Epilogue

LABEL_FEC6E9:
	stiw_dri 0xFD, 0x8E, 0x00, 0x00, 0x00
	cp_sriw_im 0xFD, 0x8E, 0x00, 0x04, 0x00
	jr ugt, LABEL_FEC715

LABEL_FEC6F9:
	call TaskBuf_ReadNextByte
	cps hl, 0
	jr ge, LABEL_FEC707
	ldw hl, 0xFFFF
	jrl SeqFile_Epilogue

LABEL_FEC707:
	inc_sriw 1, 0xFD, 0x8E, 0x00
	cp_sriw_im 0xFD, 0x8E, 0x00, 0x04, 0x00
	jr ule, LABEL_FEC6F9

LABEL_FEC715:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEC725
	ldw hl, 0xFFFF
	jrl SeqFile_Epilogue

LABEL_FEC725:
	cps hl, 0
	jr z, LABEL_FEC72F
	ldw hl, 0xFFFC
	jrl SeqFile_Epilogue

LABEL_FEC72F:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEC73F
	ldw hl, 0xFFFF
	jrl SeqFile_Epilogue

LABEL_FEC73F:
	ld a, l
	extz wa
	sla wa, 8
	stda16 59889, xwa
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEC75A
	ldw hl, 0xFFFF
	jrl SeqFile_Epilogue

LABEL_FEC75A:
	ld a, l
	extz wa
	adddm16 59889, xwa
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEC772
	ldw hl, 0xFFFF
	jrl SeqFile_Epilogue

LABEL_FEC772:
	ld a, l
	extz wa
	sla wa, 8
	stda16 59887, xwa
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEC78D
	ldw hl, 0xFFFF
	jrl SeqFile_Epilogue

LABEL_FEC78D:
	ld a, l
	extz wa
	adddm16 59887, xwa
	stiw_dri 0xFD, 0x8E, 0x00, 0x00, 0x00
	cp_sriw_im 0xFD, 0x8E, 0x00, 0x03, 0x00
	jr ugt, LABEL_FEC7D4

LABEL_FEC7A5:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEC7B4
	ldw hl, 0xFFFF
	jr SeqFile_Epilogue

LABEL_FEC7B4:
	ld_sriw WA, (xsp + 0x008e)
	extz xwa
	st_dri3b A, 0xFD, 0x82, 0x00
	add xbc, xwa
	cp l, (xbc)
	jr nz, LABEL_FEC7D4
	inc_sriw 1, 0xFD, 0x8E, 0x00
	cp_sriw_im 0xFD, 0x8E, 0x00, 0x03, 0x00
	jr ule, LABEL_FEC7A5

LABEL_FEC7D4:
	cp_sriw_im 0xFD, 0x8E, 0x00, 0x04, 0x00
	jr z, LABEL_FEC7E2
	ldw hl, 0xFFFE
	jr SeqFile_Epilogue

LABEL_FEC7E2:
	stiw_dri 0xFD, 0x8E, 0x00, 0x00, 0x00
	cp_sriw_im 0xFD, 0x8E, 0x00, 0x03, 0x00
	jr ugt, LABEL_FEC80D

LABEL_FEC7F2:
	call TaskBuf_ReadNextByte
	cps hl, 0
	jr ge, LABEL_FEC7FF
	ldw hl, 0xFFFF
	jr SeqFile_Epilogue

LABEL_FEC7FF:
	inc_sriw 1, 0xFD, 0x8E, 0x00
	cp_sriw_im 0xFD, 0x8E, 0x00, 0x03, 0x00
	jr ule, LABEL_FEC7F2

LABEL_FEC80D:
	st_dri3b W, 0xFD, 0x8E, 0x00
	ld xde, xwa
	lda xwa, (xsp + 2)
	ld xbc, xwa
	ld xwa, xde
	calr FileIO_ReadVariableLengthData
	ld xwa, xhl
	cp xwa, 0x0
	jr ge, LABEL_FEC82D
	ldw hl, 0xFFFF
	jr SeqFile_Epilogue

LABEL_FEC82D:
	adddm32 59879, xhl
	lds hl, 0

SeqFile_Epilogue:
	popw iz
	st_dri3b L, 0xFD, 0x8E, 0x00
	ret

LABEL_FEC83A:
	calr MIDI_ResetAllChannels
	call GetPlayState1
	cps l, 0
	jr z, LABEL_FEC84C
	lds wa, 1
	calr SoundParam_InitDefaultBanks
	jr LABEL_FEC851

LABEL_FEC84C:
	lds wa, 0
	calr SoundParam_InitDefaultBanks

LABEL_FEC851:
	lds32 xwa, 4
	call SndParam_LookupReadOnly
	ld wa, hl
	exts xwa
	set 15, wa
	stda16 4597, xwa
	ld xwa, 0xC0
	call SndParam_LookupReadOnly
	cps hl, 1
	jr nz, LABEL_FEC887
	stdi8 4330, 1
	ld xwa, 0xC0
	lds bc, 1
	lds de, 1
	call SoundParam_NotifyChange
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz

LABEL_FEC887:
	stdi16 60153, 0
	stdi16 60411, 0
	call Audio_SendEventPostCmd
	lds hl, 0
	ret

LABEL_FEC89A:
	ld c, a
	cp c, 0xF7
	jr z, LABEL_FEC8CB
	cp c, 0xF0
	jr z, LABEL_FEC8CB
	cp c, 0xFF
	jr nz, LABEL_FEC8EB
	calr LABEL_FEC90A
	ld wa, hl
	cps wa, 0
	ret lt
	calr FileIO_ReadMultiByteRecord
	ld xwa, xhl
	cp xwa, 0x0
	jr ge, LABEL_FEC8C5
	ldw hl, 0xFFFF
	ret

LABEL_FEC8C5:
	adddm32 59879, xhl
	jr LABEL_FEC907

LABEL_FEC8CB:
	calr LABEL_FECA8A
	ld wa, hl
	cps wa, 0
	ret lt
	calr FileIO_ReadMultiByteRecord
	ld xwa, xhl
	cp xwa, 0x0
	jr ge, LABEL_FEC8E5
	ldw hl, 0xFFFF
	ret

LABEL_FEC8E5:
	adddm32 59879, xhl
	jr LABEL_FEC907

LABEL_FEC8EB:
	extz wa
	calr LABEL_FECB8F
	ld wa, hl
	cps wa, 0
	ret lt
	calr FileIO_ReadMultiByteRecord
	ld xwa, xhl
	cp xwa, 0x0
	ret lt
	adddm32 59879, xhl

LABEL_FEC907:
	lds hl, 0
	ret

LABEL_FEC90A:
	st_dri3b L, 0xFD, 0xFC, 0xFE
	push xiz
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEC91F
	ldw hl, 0xFFFF
	jrl FileIO_SeekRecord_Done

LABEL_FEC91F:
	ld a, l
	cp a, 0x51
	jrl z, LABEL_FEC9B6
	cp a, 0x2F
	jr z, LABEL_FEC9A3
	cps a, 5
	jrl nz, LABEL_FECA51
	calr FileIO_ReadNextRecord
	ld wa, hl
	exts xwa
	ld (xsp + 4), xwa
	cp xwa, 0x0
	jr ge, LABEL_FEC949
	ldw hl, 0xFFFF
	jrl FileIO_SeekRecord_Done

LABEL_FEC949:
	lds32 xiz, 0
	cp xiz, (xsp + 4)
	jr ge, LABEL_FEC96F

LABEL_FEC950:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEC95F
	ldw hl, 0xFFFF
	jrl FileIO_SeekRecord_Done

LABEL_FEC95F:
	lda xwa, (xsp + 8)
	ld xbc, xiz
	add xbc, xwa
	ld (xbc), l
	inc 1, xiz
	cp xiz, (xsp + 4)
	jr lt, LABEL_FEC950

LABEL_FEC96F:
	lda xwa, (xsp + 8)
	ld xbc, xiz
	add xbc, xwa
	ld (xbc), 0x0
	ldda32 xwa, 59879
	or xwa, xwa
	jrl z, FileIO_SeekRecord_LoopDone
	ld xwa, (xsp + 4)
	extz wa
	calr LABEL_FEE2F8
	ld xwa, (xsp + 4)
	ld de, wa
	lda xwa, (xsp + 8)
	ld xbc, xwa
	ld wa, de
	calr LABEL_FEE39D
	calr LABEL_FECC0C
	call LABEL_F2AA12
	jrl FileIO_SeekRecord_LoopDone

LABEL_FEC9A3:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, LABEL_FEC9B0
	ldw hl, 0xFFFF
	jrl FileIO_SeekRecord_Done

LABEL_FEC9B0:
	ldw hl, 0xFFFD
	jrl FileIO_SeekRecord_Done

LABEL_FEC9B6:
	calr FileIO_ReadNextRecord
	ld wa, hl
	exts xwa
	ld (xsp + 4), xwa
	cp xwa, 0x0
	jr ge, LABEL_FEC9CE
	ldw hl, 0xFFFF
	jrl FileIO_SeekRecord_Done

LABEL_FEC9CE:
	lds32 xiz, 0
	cp xiz, (xsp + 4)
	jr ge, LABEL_FEC9F4

LABEL_FEC9D5:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEC9E4
	ldw hl, 0xFFFF
	jrl FileIO_SeekRecord_Done

LABEL_FEC9E4:
	lda xwa, (xsp + 8)
	ld xbc, xiz
	add xbc, xwa
	ld (xbc), l
	inc 1, xiz
	cp xiz, (xsp + 4)
	jr lt, LABEL_FEC9D5

LABEL_FEC9F4:
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
	jr ule, LABEL_FECA23
	ld xwa, xiz

LABEL_FECA23:
	ld xiz, xwa
	ld xwa, 0x12C
	cp xiz, 0x12C
	jr nc, LABEL_FECA34
	ld xwa, xiz

LABEL_FECA34:
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

LABEL_FECA51:
	calr FileIO_ReadMultiByteRecord
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	cp xwa, 0x0
	jr ge, LABEL_FECA67
	ldw hl, 0xFFFF
	jr FileIO_SeekRecord_Done

LABEL_FECA67:
	lds32 xiz, 0
	cp xiz, (xsp + 4)
	jr ge, FileIO_SeekRecord_LoopDone

LABEL_FECA6E:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, LABEL_FECA7A
	ldw hl, 0xFFFF
	jr FileIO_SeekRecord_Done

LABEL_FECA7A:
	inc 1, xiz
	cp xiz, (xsp + 4)
	jr lt, LABEL_FECA6E

FileIO_SeekRecord_LoopDone:
	lds hl, 0

FileIO_SeekRecord_Done:
	pop xiz
	st_dri3b L, 0xFD, 0x04, 0x01
	ret

LABEL_FECA8A:
	lda xsp, (xsp - 128)
	push xiz
	calr FileIO_ReadNextRecord
	ldfr_werp HL, 0xFA
	ldto_werp WA, 0xFA
	cps wa, 0
	jr ge, LABEL_FECAA1
	ldw hl, 0xFFFF
	jrl FileIO_SeekRecord_PopReturn

LABEL_FECAA1:
	cp_erpw 0xFA, 0x7F, 0x00
	jr le, LABEL_FECACB
	lds iz, 0
	ldto_werp WA, 0xFA
	cp iz, wa
	jrl nc, FileIO_SeekRecord_Return

LABEL_FECAB2:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, LABEL_FECABF
	ldw hl, 0xFFFF
	jrl FileIO_SeekRecord_PopReturn

LABEL_FECABF:
	inc 1, iz
	ldto_werp WA, 0xFA
	cp iz, wa
	jr c, LABEL_FECAB2
	jrl FileIO_SeekRecord_Return

LABEL_FECACB:
	ld (xsp + 4), 0xF0
	lds iz, 0
	ldto_werp WA, 0xFA
	cp iz, wa
	jr nc, LABEL_FECAFD

LABEL_FECAD8:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FECAE7
	ldw hl, 0xFFFF
	jrl FileIO_SeekRecord_PopReturn

LABEL_FECAE7:
	ld wa, iz
	inc 1, wa
	extz xwa
	lda xbc, (xsp + 4)
	add xbc, xwa
	ld (xbc), l
	inc 1, iz
	ldto_werp WA, 0xFA
	cp iz, wa
	jr c, LABEL_FECAD8

LABEL_FECAFD:
	cp (xsp + 5), 0x5
	jr nz, FileIO_SeekRecord_SendMidi
	cp (xsp + 6), 0x7E
	jr nz, FileIO_SeekRecord_SendMidi
	cp (xsp + 7), 0x7F
	jr nz, FileIO_SeekRecord_SendMidi
	cp (xsp + 8), 0x9
	jr nz, FileIO_SeekRecord_SendMidi
	ld xwa, 0xC0
	call SndParam_LookupReadOnly
	cps hl, 1
	jr nz, LABEL_FECB28
	cp (xsp + 8), 0x1
	jr nz, LABEL_FECB3B

LABEL_FECB28:
	ld xwa, 0xC0
	call SndParam_LookupReadOnly
	cps hl, 0
	jr nz, LABEL_FECB51
	cp (xsp + 8), 0x2
	jr z, LABEL_FECB51

LABEL_FECB3B:
	calr SeqPlay_BusyWaitLoop
	ldto_werp WA, 0xFA
	inc 1, wa
	ld de, wa
	lda xwa, (xsp + 4)
	ld xbc, xwa
	ld wa, de
	calr MIDI_SendSinglePacket
	jr FileIO_SeekRecord_Return

LABEL_FECB51:
	call GetPlayState2
	cps l, 0
	jr z, FileIO_SeekRecord_Return
	cpdi8 59876, 1
	jr nz, FileIO_SeekRecord_Return
	lda xwa, (xsp + 4)
	push xwa
	ldto_werp WA, 0xFA
	inc 1, wa
	pushw wa
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr FileIO_SeekRecord_Return

FileIO_SeekRecord_SendMidi:
	calr SeqPlay_BusyWaitLoop
	ldto_werp WA, 0xFA
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
	st_dri3b L, 0xFD, 0x80, 0x00
	ret

LABEL_FECB8F:
	lda xsp, (xsp - 10)
	push xiz
	ld xiy, 0xEEC1D4
	lda xix, (xsp + 4)
	lds bc, 5
	ldirw
	bit 7, a
	jr z, LABEL_FECBAF
	stda8 53404, a
	ld (xsp + 4), a
	lds iz, 1
	jr LABEL_FECBB9

LABEL_FECBAF:
	ldmi16 (xsp + 4), 0xD09C
	ld (xsp + 5), a
	lds iz, 2

LABEL_FECBB9:
	ldda8 a, 53404
	and a, 0xF0
	cp a, 0xC0
	jr z, LABEL_FECBCA
	cp a, 0xD0
	jr nz, LABEL_FECBCF

LABEL_FECBCA:
	ldi_werp 0xFA, 2
	jr LABEL_FECBD2

LABEL_FECBCF:
	ldi_werp 0xFA, 3

LABEL_FECBD2:
	cp_werp IZ, 0xFA
	jr nc, LABEL_FECBF7

LABEL_FECBD7:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FECBE5
	ldw hl, 0xFFFF
	jr LABEL_FECC04

LABEL_FECBE5:
	ld wa, iz
	extz xwa
	lda xbc, (xsp + 4)
	add xbc, xwa
	ld (xbc), l
	inc 1, iz
	cp_werp IZ, 0xFA
	jr c, LABEL_FECBD7

LABEL_FECBF7:
	lda xwa, (xsp + 4)
	ld xbc, xwa
	ldto_werp WA, 0xFA
	calr MIDI_SendSinglePacket
	lds hl, 0

LABEL_FECC04:
	pop xiz
	lda xsp, (xsp + 10)
	ret

LABEL_FECC09:
	.byte 0xdb, 0xa8, 0x0e

LABEL_FECC0C:
	pushw iz
	lds iz, 0
	cpdi8 59844, 0
	jr nz, LABEL_FECC35
	lds hl, 0
	jr LABEL_FECC69

LABEL_FECC1A:
	calr Seq_CalcAddrOffset
	cp hl, 0x780
	jr le, LABEL_FECC35
	calr LABEL_FEE246
	cp hl, 0x40
	jr gt, LABEL_FECC40
	calr Seq_CalcAddrOffset
	cp hl, 0x7EC
	jr gt, LABEL_FECC40

LABEL_FECC35:
	calr SongFile_DecodeMidiEvent
	ld iz, hl
	ld wa, iz
	cps wa, 0
	jr z, LABEL_FECC1A

LABEL_FECC40:
	calr LABEL_FEE246
	cps hl, 0
	call_24 gt, 0xF2AA02
	ld wa, iz
	cp wa, 0xFFFD
	jr z, LABEL_FECC67
	cp wa, 0xFFFE
	jr z, LABEL_FECC5E
	cp wa, 0xFFFF
	jr nz, LABEL_FECC67

LABEL_FECC5E:
	calr Song_AbortPlayback
	ld wa, iz
	call SongMode_VoiceStateDisp

LABEL_FECC67:
	ld hl, iz

LABEL_FECC69:
	popw iz
	ret

LABEL_FECC6B:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xwa
	calr LABEL_FEE20E
	ld iz, hl
	ld wa, iz
	cps wa, 0
	jr ge, LABEL_FECC84
	ld xwa, (xsp + 2)
	ld (xwa), 0x0
	jr LABEL_FECCA1

LABEL_FECC84:
	ld wa, iz
	ld xbc, (xsp + 2)
	calr LABEL_FEE24E
	cps hl, 0
	jr ge, LABEL_FECC98
	ld xwa, (xsp + 2)
	ld (xwa), 0x0
	jr LABEL_FECCA1

LABEL_FECC98:
	ld xwa, (xsp + 2)
	stib_dri 0x07, 0xE0, 0xF8, 0x00

LABEL_FECCA1:
	popw iz
	inc 4, xsp
	ret

LABEL_FECCA5:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xwa
	calr LABEL_FEE32E
	ld iz, hl
	ld wa, iz
	cps wa, 0
	jr ge, LABEL_FECCBE
	ld xwa, (xsp + 2)
	ld (xwa), 0x0
	jr LABEL_FECCDB

LABEL_FECCBE:
	ld wa, iz
	ld xbc, (xsp + 2)
	calr LABEL_FEE366
	cps hl, 0
	jr ge, LABEL_FECCD2
	ld xwa, (xsp + 2)
	ld (xwa), 0x0
	jr LABEL_FECCDB

LABEL_FECCD2:
	ld xwa, (xsp + 2)
	stib_dri 0x07, 0xE0, 0xF8, 0x00

LABEL_FECCDB:
	popw iz
	inc 4, xsp
	ret

SongFile_DecodeMidiEvent:
	st_dri3b L, 0xFD, 0xF0, 0xFD
	pushw iz
	lds iz, 0
	lds32 xwa, 0
	ld (xsp + 6), xwa
	ldw (xsp + 10), 0x0
	cpdi16 60411, 0
	jr z, LABEL_FECD18
	ldda16 xde, 60411
	ldada xwa, 60155
	ld xbc, xwa
	ld wa, de
	calr MidiRingBuf_WriteBytes
	cps hl, 0
	jr ge, LABEL_FECD12
	ldw hl, 0xFFFD
	jrl SeqPlay_Epilogue

LABEL_FECD12:
	stdi16 60411, 0

LABEL_FECD18:
	cpdi16 60153, 0
	jr z, LABEL_FECD43
	ldda16 xde, 60153
	ldada xwa, 59897
	ld xbc, xwa
	ld wa, de
	calr SysexRingBuf_WriteBytes
	cps hl, 0
	jr ge, LABEL_FECD39
	ldw hl, 0xFFFD
	jrl SeqPlay_Epilogue

LABEL_FECD39:
	call Audio_SendEventPostCmd
	stdi16 60153, 0

LABEL_FECD43:
	ldda16 xwa, 59877
	bit 4, wa
	jr z, LABEL_FECD52
	ldw hl, 0xFFFD
	jrl SeqPlay_Epilogue

LABEL_FECD52:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FECD62
	ldw hl, 0xFFFF
	jrl SeqPlay_Epilogue

LABEL_FECD62:
	ld wa, (xsp + 10)
	incm 1, (xsp + 10)
	lda xbc, (xsp + 12)
	lda_dri3 XSP, 0x07, 0xE4, 0xE0
	ld wa, (xsp + 10)
	lda xbc, (xsp + 11)
	ld_srib3 A, 0x07, 0xE4, 0xE0
	cp a, 0xF7
	jrl z, LABEL_FECE8C
	cp a, 0xF0
	jrl z, LABEL_FECE8C
	cp a, 0xFF
	jrl nz, LABEL_FECF08
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FECD9D
	ldw hl, 0xFFFF
	jrl SeqPlay_Epilogue

LABEL_FECD9D:
	ld wa, (xsp + 10)
	incm 1, (xsp + 10)
	lda xbc, (xsp + 12)
	lda_dri3 XSP, 0x07, 0xE4, 0xE0
	ld wa, (xsp + 10)
	lda xbc, (xsp + 11)
	ld_srib3 A, 0x07, 0xE4, 0xE0
	cp a, 0x2F
	jr nz, LABEL_FECDE2
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FECDCB
	ldw hl, 0xFFFF
	jrl SeqPlay_Epilogue

LABEL_FECDCB:
	ld wa, (xsp + 10)
	incm 1, (xsp + 10)
	lda xbc, (xsp + 12)
	lda_dri3 XSP, 0x07, 0xE4, 0xE0
	ordi16 59877, 16
	jrl SeqPlay_ReadRecord_Entry

LABEL_FECDE2:
	lda xwa, (xsp + 10)
	ld xde, xwa
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, xde
	calr FileIO_ReadVariableLengthData
	ld (xsp + 2), xhl
	ld xwa, (xsp + 2)
	cp xwa, 0x0
	jr ge, LABEL_FECE05
	ldw hl, 0xFFFF
	jrl SeqPlay_Epilogue

LABEL_FECE05:
	ld xwa, (xsp + 2)
	cp xwa, 0x7F
	jr lt, LABEL_FECE4C
	lds iz, 0
	ld wa, iz
	extz xwa
	cp xwa, (xsp + 2)
	jr ge, LABEL_FECE34

LABEL_FECE1B:
	call TaskBuf_ReadNextByte
	cps hl, 0
	jr ge, LABEL_FECE29
	ldw hl, 0xFFFF
	jrl SeqPlay_Epilogue

LABEL_FECE29:
	inc 1, iz
	ld wa, iz
	extz xwa
	cp xwa, (xsp + 2)
	jr lt, LABEL_FECE1B

LABEL_FECE34:
	ld (xsp + 12), 0xFF
	ld (xsp + 13), 0x4
	ld (xsp + 14), 0x1
	ld (xsp + 15), 0x20
	ldw (xsp + 10), 0x4
	jrl SeqPlay_ReadRecord_Entry

LABEL_FECE4C:
	ld xwa, (xsp + 2)
	ld de, wa
	st_dri3b W, 0xFD, 0x10, 0x01
	ld xbc, xwa
	ld wa, de
	calr LABEL_FEC2E0
	cps hl, 0
	jr ge, LABEL_FECE67
	ldw hl, 0xFFFF
	jrl SeqPlay_Epilogue

LABEL_FECE67:
	ld xwa, (xsp + 2)
	pushw wa
	st_dri3b W, 0xFD, 0x12, 0x01
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

LABEL_FECE8C:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FECE9C
	ldw hl, 0xFFFF
	jrl SeqPlay_Epilogue

LABEL_FECE9C:
	ld wa, (xsp + 10)
	incm 1, (xsp + 10)
	lda xbc, (xsp + 12)
	lda_dri3 XSP, 0x07, 0xE4, 0xE0
	ld wa, (xsp + 10)
	lda xbc, (xsp + 11)
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ld e, a
	extz de
	st_dri3b W, 0xFD, 0x10, 0x01
	ld xbc, xwa
	ld wa, de
	calr LABEL_FEC2E0
	cps hl, 0
	jr ge, LABEL_FECECF
	ldw hl, 0xFFFF
	jrl SeqPlay_Epilogue

LABEL_FECECF:
	ld wa, (xsp + 10)
	lda xbc, (xsp + 11)
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	pushw wa
	st_dri3b W, 0xFD, 0x12, 0x01
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
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	add (xsp + 10), wa
	jrl SeqPlay_ReadRecord_Entry

LABEL_FECF08:
	bitm 7, (xsp + 12)
	jr z, LABEL_FECF14
	mrdb5 0x8F, 0x0C, 0x19, 0x10, 0xEC
	jr LABEL_FECF3B

LABEL_FECF14:
	ld wa, (xsp + 10)
	lda xde, (xsp + 11)
	lda xbc, (xsp + 12)
	ld hl, (xsp + 10)
	extz xhl
	add xhl, xbc
	ld_srib3 A, 0x07, 0xE8, 0xE0
	ld (xhl), a
	ld wa, (xsp + 10)
	lda xbc, (xsp + 11)
	ldmmb_dri 0x07, 0xE4, 0xE0, 0x10, 0xEC
	incm 1, (xsp + 10)

LABEL_FECF3B:
	ldda8 a, 60432
	and a, 0xF0
	cp a, 0xC0
	jr z, LABEL_FECF4C
	cp a, 0xD0
	jr nz, LABEL_FECF53

LABEL_FECF4C:
	lds32 xwa, 2
	ld (xsp + 2), xwa
	jr LABEL_FECF58

LABEL_FECF53:
	lds32 xwa, 3
	ld (xsp + 2), xwa

LABEL_FECF58:
	ld wa, (xsp + 10)
	exts xwa
	cp xwa, (xsp + 2)
	jr ge, SeqPlay_ReadRecord_Entry

LABEL_FECF62:
	call TaskBuf_ReadNextByte
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FECF72
	ldw hl, 0xFFFF
	jrl SeqPlay_Epilogue

LABEL_FECF72:
	lda xwa, (xsp + 12)
	ld bc, (xsp + 10)
	extz xbc
	add xbc, xwa
	ld (xbc), l
	incm 1, (xsp + 10)
	ld wa, (xsp + 10)
	exts xwa
	cp xwa, (xsp + 2)
	jr lt, LABEL_FECF62

SeqPlay_ReadRecord_Entry:
	stiw_dri 0xFD, 0x0E, 0x01, 0x00, 0x00
	ldda32 xwa, 59893
	ld (xsp + 6), xwa
	ldda16 xwa, 59877
	bit 4, wa
	jr nz, LABEL_FECFD0
	st_dri3b W, 0xFD, 0x0E, 0x01
	ld xde, xwa
	st_dri3b W, 0xFD, 0x10, 0x01
	ld xbc, xwa
	ld xwa, xde
	calr FileIO_ReadVariableLengthData
	ld (xsp + 2), xhl
	ld xwa, (xsp + 2)
	cp xwa, 0x0
	jr ge, LABEL_FECFC9
	ldw hl, 0xFFFF
	jrl SeqPlay_Epilogue

LABEL_FECFC9:
	ld xwa, (xsp + 2)
	adddm32 59893, xwa

LABEL_FECFD0:
	cp (xsp + 12), 0xFF
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
	jr LABEL_FED006

SeqVoice_InitZeroPath:
	stdi16 60153, 0

LABEL_FED006:
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
	st_dri3b W, 0xFD, 0x1C, 0x01
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
	jr z, LABEL_FED079
	ldda16 xwa, 60153
	dec 2, wa
	ld de, wa
	ldada xwa, 59899
	ld xbc, xwa
	ld wa, de
	calr SysexRingBuf_WriteBytes
	cps hl, 0
	jr ge, LABEL_FED06F
	ldw hl, 0xFFFD
	jr SeqPlay_Epilogue

LABEL_FED06F:
	call Audio_SendEventPostCmd
	stdi16 60153, 0

LABEL_FED079:
	cpdi16 60411, 0
	jr z, LABEL_FED09F
	ldda16 xde, 60411
	ldada xwa, 60155
	ld xbc, xwa
	ld wa, de
	calr MidiRingBuf_WriteBytes
	cps hl, 0
	jr ge, LABEL_FED099
	ldw hl, 0xFFFD
	jr SeqPlay_Epilogue

LABEL_FED099:
	stdi16 60411, 0

LABEL_FED09F:
	lds hl, 0

SeqPlay_Epilogue:
	popw iz
	st_dri3b L, 0xFD, 0x10, 0x02
	ret

LABEL_FED0A8:
	lda xsp, (xsp - 14)
	pushw iz
	ld xiy, 0xEEC1DE
	lda xix, (xsp + 6)
	lds bc, 4
	ldirw
	ldi85
	lds32 xwa, 0
	ld (xsp + 2), xwa
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FED0CE
	ldw hl, 0xFFFF
	jrl FileIO_Epilogue

LABEL_FED0CE:
	cp l, 0xFE
	jr z, LABEL_FED0D9
	ldw hl, 0xFFFE
	jrl FileIO_Epilogue

LABEL_FED0D9:
	lds32 xwa, 0
	stda32 59883, xwa
	lds iz, 0
	cps iz, 6
	jr nc, LABEL_FED0F8

LABEL_FED0E5:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, LABEL_FED0F2
	ldw hl, 0xFFFF
	jrl FileIO_Epilogue

LABEL_FED0F2:
	inc 1, iz
	cps iz, 6
	jr c, LABEL_FED0E5

LABEL_FED0F8:
	lds iz, 0
	cp iz, 0x8
	jr nc, LABEL_FED12A

LABEL_FED100:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FED10F
	ldw hl, 0xFFFF
	jrl FileIO_Epilogue

LABEL_FED10F:
	ld wa, iz
	extz xwa
	lda xbc, (xsp + 6)
	add xbc, xwa
	cp l, (xbc)
	jr z, LABEL_FED122
	ldw hl, 0xFFFE
	jrl FileIO_Epilogue

LABEL_FED122:
	inc 1, iz
	cp iz, 0x8
	jr c, LABEL_FED100

LABEL_FED12A:
	lds iz, 0
	cp iz, 0xA
	jr nc, LABEL_FED147

LABEL_FED132:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, LABEL_FED13F
	ldw hl, 0xFFFF
	jrl FileIO_Epilogue

LABEL_FED13F:
	inc 1, iz
	cp iz, 0xA
	jr c, LABEL_FED132

LABEL_FED147:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FED156
	ldw hl, 0xFFFF
	jrl FileIO_Epilogue

LABEL_FED156:
	ld a, l
	cp a, 0x40
	jr z, LABEL_FED17A
	cp a, 0x21
	jr nz, LABEL_FED181
	stdi8 59876, 2

LABEL_FED167:
	lds iz, 0
	cps iz, 1
	jr nc, LABEL_FED18D

LABEL_FED16D:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, LABEL_FED187
	ldw hl, 0xFFFF
	jrl FileIO_Epilogue

LABEL_FED17A:
	stdi8 59876, 3
	jr LABEL_FED167

LABEL_FED181:
	ldw hl, 0xFFFE
	jrl FileIO_Epilogue

LABEL_FED187:
	inc 1, iz
	cps iz, 1
	jr c, LABEL_FED16D

LABEL_FED18D:
	lds iz, 0
	cps iz, 3
	jr ugt, LABEL_FED1BD

LABEL_FED193:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FED1A2
	ldw hl, 0xFFFF
	jrl FileIO_Epilogue

LABEL_FED1A2:
	ld wa, iz
	sll wa, 3
	ld c, l
	and a, 0xF
	jr z, LABEL_FED1B0
	slla c

LABEL_FED1B0:
	lds32 xwa, 0
	ld a, c
	add (xsp + 2), xwa
	inc 1, iz
	cps iz, 3
	jr ule, LABEL_FED193

LABEL_FED1BD:
	lds iz, 0
	cps iz, 3
	jr ugt, LABEL_FED1D6

LABEL_FED1C3:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, LABEL_FED1D0
	ldw hl, 0xFFFF
	jrl FileIO_Epilogue

LABEL_FED1D0:
	inc 1, iz
	cps iz, 3
	jr ule, LABEL_FED1C3

LABEL_FED1D6:
	stdi16 59887, 384
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FED1EB
	ldw hl, 0xFFFF
	jrl FileIO_Epilogue

LABEL_FED1EB:
	ld a, l
	extz wa
	stda16 59889, xwa
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FED202
	ldw hl, 0xFFFF
	jrl FileIO_Epilogue

LABEL_FED202:
	ld a, l
	add a, 0x1D
	ldb w, 0x0
	extz xwa
	stda32 59883, xwa
	lds iz, 0
	cps iz, 1
	jr ugt, LABEL_FED228

LABEL_FED215:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, LABEL_FED222
	ldw hl, 0xFFFF
	jrl FileIO_Epilogue

LABEL_FED222:
	inc 1, iz
	cps iz, 1
	jr ule, LABEL_FED215

LABEL_FED228:
	cpdi8 59876, 3
	jr nz, LABEL_FED299
	ld xwa, (xsp + 2)
	cp xwa, 0xC
	jr ule, LABEL_FED299
	lds iz, 0
	cp iz, 0xC
	jr nc, LABEL_FED257

LABEL_FED242:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, LABEL_FED24F
	ldw hl, 0xFFFF
	jrl FileIO_Epilogue

LABEL_FED24F:
	inc 1, iz
	cp iz, 0xC
	jr c, LABEL_FED242

LABEL_FED257:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FED266
	ldw hl, 0xFFFF
	jrl FileIO_Epilogue

LABEL_FED266:
	ld a, l
	add a, 0x1D
	ldb w, 0x0
	extz xwa
	stda32 59883, xwa
	lds iz, 0
	jr LABEL_FED286

LABEL_FED277:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, LABEL_FED284
	ldw hl, 0xFFFF
	jrl FileIO_Epilogue

LABEL_FED284:
	inc 1, iz

LABEL_FED286:
	ld xwa, (xsp + 2)
	sub xwa, 0xD
	ld bc, iz
	extz xbc
	cp xbc, xwa
	jr c, LABEL_FED277
	jr LABEL_FED2BB

LABEL_FED299:
	lds iz, 0
	ld wa, iz
	extz xwa
	cp xwa, (xsp + 2)
	jr nc, LABEL_FED2BB

LABEL_FED2A4:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, LABEL_FED2B0
	ldw hl, 0xFFFF
	jr FileIO_Epilogue

LABEL_FED2B0:
	inc 1, iz
	ld wa, iz
	extz xwa
	cp xwa, (xsp + 2)
	jr c, LABEL_FED2A4

LABEL_FED2BB:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FED2C9
	ldw hl, 0xFFFF
	jr FileIO_Epilogue

LABEL_FED2C9:
	cp l, 0xF1
	jr z, LABEL_FED2D3
	ldw hl, 0xFFFE
	jr FileIO_Epilogue

LABEL_FED2D3:
	calr FileIO_ReadNextRecord
	cps hl, 0
	jr ge, LABEL_FED2DF
	ldw hl, 0xFFFF
	jr FileIO_Epilogue

LABEL_FED2DF:
	ldada xde, 59883
	ld xbc, 0x28
	ldda32 xwa, 59883
	cp xwa, 0x28
	jr ule, LABEL_FED2F8
	ldda32 xbc, 59883

LABEL_FED2F8:
	ld (xde), xbc
	ldada xde, 59883
	ld xbc, 0x12C
	ldda32 xwa, 59883
	cp xwa, 0x12C
	jr nc, LABEL_FED313
	ldda32 xbc, 59883

LABEL_FED313:
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

LABEL_FED334:
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
	jr ge, LABEL_FED3D8

LABEL_FED3B7:
	ld bc, iz
	ldada xwa, 64654
	ld_srib3 A, 0x07, 0xE0, 0xF8
	extz wa
	pushw 0xFF
	ld de, wa
	ldw wa, 0x63
	call AssswbWr
	inc 1, iz
	cp iz, 0x8
	jr lt, LABEL_FED3B7

LABEL_FED3D8:
	lds iz, 0
	cp iz, 0x10
	jr ge, LABEL_FED3F6

LABEL_FED3E0:
	ld wa, iz
	pushw 0x2
	ldw bc, 0x80
	lds de, 3
	call SndParam_NotifyAndReturn
	inc 1, iz
	cp iz, 0x10
	jr lt, LABEL_FED3E0

LABEL_FED3F6:
	lds32 xwa, 0
	stda32 60413, xwa
	stdi16 60417, 0
	lds hl, 0
	popw iz
	ret

LABEL_FED406:
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
	ldw wa, 0xA
	lds bc, 0
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xA
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xB
	lds bc, 0
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xB
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xC
	lds bc, 0
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xC
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xD
	lds bc, 0
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xD
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xE
	lds bc, 0
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xE
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xF
	lds bc, 0
	ldw de, 0xF0
	call SndParam_NotifyAndReturn
	pushw 0x2
	ldw wa, 0xF
	ldw bc, 0x20
	lds de, 0
	call SndParam_NotifyAndReturn
	ldw wa, 0x63
	ldw bc, 0x14
	call SysEx_ApplyAndReloadPreset
	stdi8 64660, 80
	lds iz, 0
	cp iz, 0x8
	jr ge, LABEL_FED619

LABEL_FED5F8:
	ld bc, iz
	ldada xwa, 64654
	ld_srib3 A, 0x07, 0xE0, 0xF8
	extz wa
	pushw 0xFF
	ld de, wa
	ldw wa, 0x63
	call AssswbWr
	inc 1, iz
	cp iz, 0x8
	jr lt, LABEL_FED5F8

LABEL_FED619:
	lds iz, 0
	cp iz, 0x10
	jr ge, LABEL_FED637

LABEL_FED621:
	ld wa, iz
	pushw 0x2
	ldw bc, 0x80
	lds de, 3
	call SndParam_NotifyAndReturn
	inc 1, iz
	cp iz, 0x10
	jr lt, LABEL_FED621

LABEL_FED637:
	lds hl, 0
	popw iz
	ret

; MIDI system message handler
MidiSysMsg_Handler:	; FED63B
	lda xsp, (xsp - 10)
	push xiz
	ld c, a
	and c, 0xF0
	cp c, 0xF0
	jrl nz, LABEL_FED78D
	extz wa
	sub wa, 0xF0
	cps wa, 0
	jrl lt, LABEL_FED7CF
	cp wa, 0xF
	jrl gt, LABEL_FED7CF
	add wa, wa
	lda_24 xix, 0xeec1e8
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xfed672
	jp_dri 8, 0x07, 0xF0, 0xE0

; MIDI system message dispatch (15-entry, table 0xEEC1E8)
MidiSysMsg_Dispatch:	; FED672
	.byte 0x1e, 0x47, 0x09, 0xdb, 0x88, 0xd8, 0xd8, 0x69
	.byte 0x06, 0x33, 0xff, 0xff, 0x78, 0x50, 0x01, 0xcf
	.byte 0xcf, 0xf7, 0x6e, 0xec, 0x78, 0x46, 0x01, 0xde
	.byte 0xa8, 0xde, 0xd9, 0x79, 0x3f, 0x01, 0x1e, 0x29
	.byte 0x09, 0xdb, 0xd8, 0x69, 0x06, 0x33, 0xff, 0xff
	.byte 0x78, 0x34, 0x01, 0xde, 0x61, 0xde, 0xd9, 0x61
	.byte 0xed, 0x78, 0x29, 0x01, 0x33, 0xfd, 0xff, 0x78
	.byte 0x25, 0x01, 0xde, 0xa8, 0xde, 0xd9, 0x69, 0x1d
	.byte 0x1e, 0x07, 0x09, 0xdb, 0x88, 0xd8, 0xd8, 0x69
	.byte 0x06, 0x33, 0xff, 0xff, 0x78, 0x10, 0x01, 0xbf
	.byte 0x04, 0x30, 0xf3, 0x07, 0xe0, 0xf8, 0x47, 0xde
	.byte 0x61, 0xde, 0xd9, 0x61, 0xe3, 0xbf, 0x04, 0x30
	.byte 0xe8, 0x89, 0x30, 0xf3, 0x00, 0x1e, 0xfc, 0x00
	.byte 0xe1, 0xe7, 0xe9, 0x8b, 0x78, 0xee, 0x00, 0xde
	.byte 0xa8, 0xde, 0xda, 0x69, 0x1d, 0x1e, 0xd2, 0x08
	.byte 0xdb, 0x88, 0xd8, 0xd8, 0x69, 0x06, 0x33, 0xff
	.byte 0xff, 0x78, 0xdb, 0x00, 0xbf, 0x04, 0x30, 0xf3
	.byte 0x07, 0xe0, 0xf8, 0x47, 0xde, 0x61, 0xde, 0xda
	.byte 0x61, 0xe3, 0xbf, 0x04, 0x30, 0xe8, 0x89, 0x30
	.byte 0xf4, 0x00, 0x1e, 0xc7, 0x00, 0xe1, 0xe7, 0xe9
	.byte 0x8b, 0x78, 0xb9, 0x00, 0xde, 0xa8, 0xde, 0xda
	.byte 0x79, 0xb2, 0x00, 0x1e, 0x9c, 0x08, 0xdb, 0xd8
	.byte 0x69, 0x06, 0x33, 0xff, 0xff, 0x78, 0xa7, 0x00
	.byte 0xde, 0x61, 0xde, 0xda, 0x61, 0xed, 0x78, 0x9c
	.byte 0x00, 0xde, 0xa8, 0xde, 0xda, 0x69, 0x1d, 0x1e
	.byte 0x80, 0x08, 0xdb, 0x88, 0xd8, 0xd8, 0x69, 0x06
	.byte 0x33, 0xff, 0xff, 0x78, 0x89, 0x00, 0xbf, 0x04
	.byte 0x30, 0xf3, 0x07, 0xe0, 0xf8, 0x47, 0xde, 0x61
	.byte 0xde, 0xda, 0x61, 0xe3, 0xbf, 0x04, 0x30, 0x1e
	.byte 0xba, 0x00, 0x68, 0x71, 0xde, 0xa8, 0xde, 0xda
	.byte 0x69, 0x6b, 0x1e, 0x55, 0x08, 0xdb, 0xd8, 0x69
	.byte 0x05, 0x33, 0xff, 0xff, 0x68, 0x61, 0xde, 0x61
	.byte 0xde, 0xda, 0x61, 0xee, 0x68, 0x57, 0x1e, 0x41
	.byte 0x08, 0xdb, 0x88, 0xd8, 0xd8, 0x69, 0x05, 0x33
	.byte 0xff, 0xff, 0x68, 0x4b, 0xcf, 0xcf, 0xf7, 0x6e
	.byte 0xed, 0x68, 0x42

LABEL_FED78D:
	ld (xsp + 4), a
	and a, 0xF0
	cp a, 0xC0
	jr z, LABEL_FED79D
	cp a, 0xD0
	jr nz, LABEL_FED7A2

LABEL_FED79D:
	ldi_werp 0xFA, 2
	jr LABEL_FED7A5

LABEL_FED7A2:
	ldi_werp 0xFA, 3

LABEL_FED7A5:
	lds iz, 1
	cp_werp IZ, 0xFA
	jr ge, LABEL_FED7C9

LABEL_FED7AC:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FED7BA
	ldw hl, 0xFFFF
	jr LABEL_FED7D1

LABEL_FED7BA:
	lda xwa, (xsp + 4)
	lda_dri3 XSP, 0x07, 0xE0, 0xF8
	inc 1, iz
	cp_werp IZ, 0xFA
	jr lt, LABEL_FED7AC

LABEL_FED7C9:
	lda xwa, (xsp + 4)
	calr LABEL_FED8AB

LABEL_FED7CF:
	lds hl, 0

LABEL_FED7D1:
	pop xiz
	lda xsp, (xsp + 10)
	ret

LABEL_FED7D6:
	.byte 0xc9, 0xcf, 0xf4, 0x66, 0x10, 0xc9, 0xcf, 0xf3
	.byte 0x6e, 0x33, 0x81, 0x27, 0xcf, 0x30, 0x07, 0x26
	.byte 0x00, 0xeb, 0x12, 0x68, 0x2a, 0x81, 0x27, 0xcf
	.byte 0x30, 0x07, 0x89, 0x01, 0x25, 0xcd, 0x30, 0x07
	.byte 0xcd, 0x89, 0xc9, 0xee, 0x07, 0xcd, 0xef, 0x01
	.byte 0xc9, 0xe7, 0xcf, 0x8b, 0xd9, 0x12, 0xcd, 0x89
	.byte 0xd8, 0x12, 0xd8, 0xec, 0x08, 0xd9, 0x80, 0xd8
	.byte 0x8b, 0xeb, 0x13, 0x68, 0x02, 0xeb, 0xa8, 0x0e
	.byte 0x3e, 0xe1, 0xeb, 0xe9, 0x21, 0xe9, 0xe1, 0x76
	.byte 0x89, 0x00, 0x80, 0x25, 0x88, 0x01, 0x23, 0xcb
	.byte 0x89, 0xcb, 0xef, 0x01, 0xc9, 0xee, 0x07, 0xcd
	.byte 0x30, 0x07, 0xc9, 0xe5, 0xcb, 0x89, 0xd8, 0x12
	.byte 0xd8, 0xec, 0x08, 0xd8, 0x8e, 0xee, 0x13, 0xe8
	.byte 0xa8, 0xcd, 0x89, 0xe8, 0x86, 0xee, 0x88, 0xe1
	.byte 0xeb, 0xe9, 0x21, 0x1d, 0x5c, 0x0a, 0xff, 0xeb
	.byte 0x8e, 0xee, 0x88, 0x41, 0xe8, 0x03, 0x00, 0x00
	.byte 0x1d, 0x18, 0x0c, 0xff, 0xeb, 0x8e, 0x40, 0x28
	.byte 0x00, 0x00, 0x00, 0xee, 0xcf, 0x28, 0x00, 0x00
	.byte 0x00, 0x63, 0x02, 0xee, 0x88, 0xe8, 0x8e, 0x40
	.byte 0x2c, 0x01, 0x00, 0x00, 0xee, 0xcf, 0x2c, 0x01
	.byte 0x00, 0x00, 0x6f, 0x02, 0xee, 0x88, 0xe8, 0x8e
	.byte 0xee, 0xcf, 0x00, 0x01, 0x00, 0x00, 0x6f, 0x06
	.byte 0xf1, 0x63, 0xfc, 0xb0, 0x68, 0x04, 0xf1, 0x63
	.byte 0xfc, 0xb8, 0xde, 0x88, 0xd8, 0x89, 0xe8, 0xac
	.byte 0xda, 0xab, 0x1d, 0x01, 0xd2, 0xfc, 0x1d, 0x18
	.byte 0xa3, 0xfc, 0xee, 0x88, 0xd8, 0x31, 0x0f, 0xf1
	.byte 0xf5, 0x11, 0x50, 0x5e, 0x0e

LABEL_FED8AB:
	lda xsp, (xsp - 10)
	push xiz
	ld xiz, xwa
	ld a, (xiz)
	and a, 0xF0
	cp a, 0x80
	jr z, LABEL_FED934
	cp a, 0x90
	jr z, LABEL_FED934
	cp a, 0xC0
	jrl nz, LABEL_FED984
	ld a, (xiz + 1)
	extz wa
	lda xbc, (xsp + 12)
	lda xde, (xsp + 10)
	call LABEL_FEE9BD
	ld a, (xiz)
	and a, 0xF
	or a, 0xB0
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
	and a, 0xF
	or a, 0xC0
	ld (xsp + 4), a
	ld a, (xsp + 12)
	res 7, a
	ld (xsp + 5), a
	lda xwa, (xsp + 4)
	ld xbc, xwa
	lds wa, 2
	calr MIDI_SendSinglePacket
	jr ToneGen_PopIzStackReturn

LABEL_FED934:
	cpdi8 59876, 2
	jr nz, LABEL_FED962
	ld a, (xiz)
	and a, 0xF
	cp a, 0xE
	jr nz, LABEL_FED962
	ld a, (xiz + 1)
	extz wa
	pushw wa
	lds wa, 5
	ldw bc, 0xF0
	lds de, 0
	call SndParam_LookupByChannel
	ld (xiz + 1), l
	ld xbc, xiz
	lds wa, 3
	calr MIDI_SendSinglePacket
	jr LABEL_FED969

LABEL_FED962:
	ld xbc, xiz
	lds wa, 3
	calr MIDI_SendSinglePacket

LABEL_FED969:
	lds wa, 0
	cps wa, 0
	jr z, LABEL_FED975
	cp (xiz + 2), 0x0
	jr z, LABEL_FED97B

LABEL_FED975:
	lds wa, 0
	cps wa, 0
	jr z, ToneGen_PopIzStackReturn

LABEL_FED97B:
	ld xbc, xiz
	lds wa, 3
	calr MIDI_SendSinglePacket
	jr ToneGen_PopIzStackReturn

LABEL_FED984:
	ld xbc, xiz
	lds wa, 3
	calr MIDI_SendSinglePacket

ToneGen_PopIzStackReturn:
	pop xiz
	lda xsp, (xsp + 10)
	ret

LABEL_FED990:
	push xiz
	stdi16 59887, 480
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FED9A5
	ldw hl, 0xFFFF
	jr ToneGen_PopIzReturn

LABEL_FED9A5:
	ld a, l
	cp a, 0xFE
	jr nz, LABEL_FED9DA
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FED9BA
	ldw hl, 0xFFFF
	jr ToneGen_PopIzReturn

LABEL_FED9BA:
	lds32 xiz, 0
	ldfr_berp L, 0xF8
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FED9CD
	ldw hl, 0xFFFF
	jr ToneGen_PopIzReturn

LABEL_FED9CD:
	ld a, l
	extz wa
	sla wa, 8
	exts xwa
	add xiz, xwa
	jr LABEL_FED9DE

LABEL_FED9DA:
	ld iz, hl
	exts xiz

LABEL_FED9DE:
	adddm32 59879, xiz
	lds hl, 0

ToneGen_PopIzReturn:
	pop xiz
	ret

LABEL_FED9E6:
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
	ldw de, 0x7F
	call SndParam_NotifyAndReturn
	lds hl, 0
	ret

LABEL_FEDA34:
	lda xsp, (xsp - 128)
	pushw iz
	lds iz, 0
	lds iz, 0
	ldda16 xbc, 59877
	bit 4, bc
	jr z, LABEL_FEDA4B
	ldw hl, 0xFFFD
	jrl MidiRealtime_ProcessByte

LABEL_FEDA4B:
	ld c, a
	cp c, 0xF0
	jr z, LABEL_FEDA61
	cp c, 0xFC
	jrl nz, LABEL_FEDAEC
	ordi16 59877, 16
	jrl LABEL_FEDB4E

LABEL_FEDA61:
	lds iz, 1
	lda xbc, (xsp + 1)
	lda_dri3 XBC, 0x07, 0xE4, 0xF8

LABEL_FEDA6B:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEDA7A
	ldw hl, 0xFFFF
	jrl MidiRealtime_ProcessByte

LABEL_FEDA7A:
	inc 1, iz
	cp iz, 0x80
	jr ge, LABEL_FEDA8C
	lda xwa, (xsp + 1)
	ld c, l
	lda_dri3 XHL, 0x07, 0xE0, 0xF8

LABEL_FEDA8C:
	cp hl, 0xF7
	jr nz, LABEL_FEDA6B
	cp iz, 0x80
	jr gt, LABEL_FEDAA4
	ld de, iz
	lda xwa, (xsp + 2)
	ld xbc, xwa
	ld wa, de
	calr MIDI_SendSinglePacket

LABEL_FEDAA4:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEDAB3
	ldw hl, 0xFFFF
	jrl MidiRealtime_ProcessByte

LABEL_FEDAB3:
	ld a, l
	cp a, 0xFE
	jr nz, LABEL_FEDAE0
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEDAC9
	ldw hl, 0xFFFF
	jrl MidiRealtime_ProcessByte

LABEL_FEDAC9:
	ld iz, hl
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEDAD9
	ldw hl, 0xFFFF
	jr MidiRealtime_ProcessByte

LABEL_FEDAD9:
	sla hl, 8
	add iz, hl
	jr LABEL_FEDAE2

LABEL_FEDAE0:
	ld iz, hl

LABEL_FEDAE2:
	ld wa, iz
	extz xwa
	adddm32 59879, xwa
	jr LABEL_FEDB4E

LABEL_FEDAEC:
	extz wa
	calr LABEL_FEDCA6
	ld wa, hl
	cps wa, 0
	jr lt, MidiRealtime_ProcessByte
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEDB05
	ldw hl, 0xFFFF
	jr MidiRealtime_ProcessByte

LABEL_FEDB05:
	cp l, 0xFF
	jr nz, LABEL_FEDB18
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEDB18
	ldw hl, 0xFFFF
	jr MidiRealtime_ProcessByte

LABEL_FEDB18:
	ld a, l
	cp a, 0xFE
	jr nz, LABEL_FEDB44
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEDB2D
	ldw hl, 0xFFFF
	jr MidiRealtime_ProcessByte

LABEL_FEDB2D:
	ld iz, hl
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEDB3D
	ldw hl, 0xFFFF
	jr MidiRealtime_ProcessByte

LABEL_FEDB3D:
	sla hl, 8
	add iz, hl
	jr LABEL_FEDB46

LABEL_FEDB44:
	ld iz, hl

LABEL_FEDB46:
	ld wa, iz
	extz xwa
	adddm32 59879, xwa

LABEL_FEDB4E:
	lds hl, 0

MidiRealtime_ProcessByte:
	popw iz
	st_dri3b L, 0xFD, 0x80, 0x00
	ret

LABEL_FEDB57:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xwa

ToneGen_ProcessMidiConverge:
	ldda32 xwa, 60413
	cp xwa, (xsp + 2)
	jrl ugt, LABEL_FEDCA2
	cpdi16 60417, 0
	jr z, LABEL_FEDB7C
	ldada xwa, 60419
	ld xbc, xwa
	ldda16 xwa, 60417
	calr MIDI_SendSinglePacket

LABEL_FEDB7C:
	calr RingBuffer_ReadByte
	ld wa, hl
	cps wa, 0
	jrl lt, ToneGen_VoiceReset_Return
	lds32 xwa, 0
	ld a, l
	and xwa, 0xFF
	stda32 60413, xwa
	calr RingBuffer_ReadByte
	ld wa, hl
	cps wa, 0
	jrl lt, ToneGen_VoiceReset_Return
	lds32 xwa, 0
	ld a, l
	sll xwa, 8
	and xwa, 0xFF00
	adddm32 60413, xwa
	calr RingBuffer_ReadByte
	ld wa, hl
	cps wa, 0
	jrl lt, ToneGen_VoiceReset_Return
	lds32 xwa, 0
	ld a, l
	sll xwa, 0
	and xwa, 0xFF0000
	adddm32 60413, xwa
	calr RingBuffer_ReadByte
	ld wa, hl
	cps wa, 0
	jrl lt, ToneGen_VoiceReset_Return
	lds32 xwa, 0
	ld a, l
	sll xwa, 8
	sll xwa, 0
	and xwa, 0xFF000000
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
	and a, 0xF0
	cp a, 0xC0
	jr z, LABEL_FEDC13
	cp a, 0xD0
	jr nz, LABEL_FEDC1B

LABEL_FEDC13:
	stdi16 60417, 2
	jr LABEL_FEDC21

LABEL_FEDC1B:
	stdi16 60417, 3

LABEL_FEDC21:
	lds iz, 1
	jr LABEL_FEDC3C

LABEL_FEDC25:
	calr RingBuffer_ReadByte
	ld wa, hl
	cps wa, 0
	jr lt, LABEL_FEDC42
	ld wa, iz
	ldada xbc, 60419
	extz xwa
	add xwa, xbc
	ld (xwa), l
	inc 1, iz

LABEL_FEDC3C:
	cpda16 xiz, 60417
	jr c, LABEL_FEDC25

LABEL_FEDC42:
	ldda8 a, 60419
	and a, 0xF0
	cp a, 0x90
	jr nz, ToneGen_ValidateRange_Loop
	cpdi8 60421, 0
	jr z, ToneGen_ValidateRange_Loop
	ldda8 a, 60421
	extz wa
	mul wa, 0x4B
	extz xwa
	div wa, 0x64
	add wa, 0x20
	stda8 60421, a
	cpdi8 60421, 127
	jr ule, ToneGen_ValidateRange_Loop
	stdi8 60421, 127

ToneGen_ValidateRange_Loop:
	ldda8 a, 60419
	and a, 0xF0
	cp a, 0xB0
	jrl nz, ToneGen_ProcessMidiConverge
	cpdi8 60420, 7
	jrl nz, ToneGen_ProcessMidiConverge
	stdi8 60421, 127
	jrl ToneGen_ProcessMidiConverge

ToneGen_VoiceReset_Return:
	stdi16 60417, 0
	lds32 xwa, 0
	stda32 60413, xwa

LABEL_FEDCA2:
	popw iz
	inc 4, xsp
	ret

LABEL_FEDCA6:
	lda xsp, (xsp - 10)
	push xiz
	bit 7, a
	jr z, LABEL_FEDCBA
	stda8 53406, a
	ld (xsp + 4), a
	lds iz, 1
	jr LABEL_FEDCC4

LABEL_FEDCBA:
	ldmi16 (xsp + 4), 0xD09E
	ld (xsp + 5), a
	lds iz, 2

LABEL_FEDCC4:
	ldda8 a, 53406
	and a, 0xF0
	cp a, 0xC0
	jr z, LABEL_FEDCD5
	cp a, 0xD0
	jr nz, LABEL_FEDCDA

LABEL_FEDCD5:
	ldi_werp 0xFA, 2
	jr LABEL_FEDCDD

LABEL_FEDCDA:
	ldi_werp 0xFA, 3

LABEL_FEDCDD:
	cp_werp IZ, 0xFA
	jr nc, LABEL_FEDD03

LABEL_FEDCE2:
	calr FileIO_ReadNextRecord
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEDCF1
	ldw hl, 0xFFFF
	jrl LABEL_FEDD9D

LABEL_FEDCF1:
	ld wa, iz
	extz xwa
	lda xbc, (xsp + 4)
	add xbc, xwa
	ld (xbc), l
	inc 1, iz
	cp_werp IZ, 0xFA
	jr c, LABEL_FEDCE2

LABEL_FEDD03:
	ld a, (xsp + 4)
	and a, 0xF
	jrl nz, LABEL_FEDD90
	lds iz, 4
	ldto_werp WA, 0xFA
	inc 4, wa
	cp iz, wa
	jr nc, LABEL_FEDD3C

LABEL_FEDD17:
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
	ldto_werp WA, 0xFA
	inc 4, wa
	cp iz, wa
	jr c, LABEL_FEDD17

LABEL_FEDD3C:
	ldda16 xwa, 59877
	ldda16 xbc, 59887
	calr LABEL_FEC405
	add xhl, 0x3A
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
	inc4_werp 0xFA
	lds iz, 0
	cp_werp IZ, 0xFA
	jr nc, LABEL_FEDD9B

LABEL_FEDD77:
	ld wa, iz
	extz xwa
	lda xbc, (xsp + 4)
	add xbc, xwa
	ld a, (xbc)
	extz wa
	calr LABEL_FEE0AB
	inc 1, iz
	cp_werp IZ, 0xFA
	jr c, LABEL_FEDD77
	jr LABEL_FEDD9B

LABEL_FEDD90:
	lda xwa, (xsp + 4)
	ld xbc, xwa
	ldto_werp WA, 0xFA
	calr MIDI_SendSinglePacket

LABEL_FEDD9B:
	lds hl, 0

LABEL_FEDD9D:
	pop xiz
	lda xsp, (xsp + 10)
	ret

SoundParam_InitDefaultBanks:
	lda xsp, (xsp - 96)
	pushw iz
	ld xiy, 0xEEC208
	lda xix, (xsp + 82)
	ldw bc, 0x8
	ldirw
	ld xiy, 0xEEC218
	lda xix, (xsp + 66)
	ldw bc, 0x8
	ldirw
	ld xiy, 0xEEC228
	lda xix, (xsp + 50)
	ldw bc, 0x8
	ldirw
	ld xiy, 0xEEC238
	lda xix, (xsp + 34)
	ldw bc, 0x8
	ldirw
	ld xiy, 0xEEC248
	lda xix, (xsp + 18)
	ldw bc, 0x8
	ldirw
	ld xiy, 0xEEC258
	lda xix, (xsp + 2)
	ldw bc, 0x8
	ldirw
	cps a, 2
	jrl z, LABEL_FEDEE2
	cps a, 1
	jr z, LABEL_FEDE72
	cps a, 0
	jrl nz, ToneGen_NotifyChangeComplete_Return
	stdi8 4330, 1
	ld xwa, 0xC1
	lds bc, 0
	lds de, 1
	call SoundParam_NotifyChange
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	setda 2, 64941
	ld xwa, 0xC0
	lds bc, 0
	lds de, 1
	call SoundParam_NotifyChange
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	lds iz, 0
	cp iz, 0x10
	jrl ge, ToneGen_NotifyChangeComplete_Return

LABEL_FEDE3A:
	ld de, iz
	lda xwa, (xsp + 82)
	ld_srib3 A, 0x07, 0xE0, 0xF8
	ld c, a
	extz bc
	pushw 0x2
	ld wa, de
	ld de, bc
	ldw bc, 0x401
	call SndParam_NotifyAndReturn
	ldada xbc, 61856
	lda xwa, (xsp + 66)
	ld_srib3 A, 0x07, 0xE0, 0xF8
	lda_dri3 XBC, 0x07, 0xE4, 0xF8
	inc 1, iz
	cp iz, 0x10
	jr lt, LABEL_FEDE3A
	jrl ToneGen_NotifyChangeComplete_Return

LABEL_FEDE72:
	stdi8 4330, 1
	ld xwa, 0xC1
	lds bc, 0
	lds de, 1
	call SoundParam_NotifyChange
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	resda 2, 64941
	ld xwa, 0xC0
	lds bc, 1
	lds de, 1
	call SoundParam_NotifyChange
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	lds iz, 0
	cp iz, 0x10
	jrl ge, ToneGen_NotifyChangeComplete_Return

LABEL_FEDEAA:
	ld de, iz
	lda xwa, (xsp + 50)
	ld_srib3 A, 0x07, 0xE0, 0xF8
	ld c, a
	extz bc
	pushw 0x2
	ld wa, de
	ld de, bc
	ldw bc, 0x401
	call SndParam_NotifyAndReturn
	ldada xbc, 61856
	lda xwa, (xsp + 34)
	ld_srib3 A, 0x07, 0xE0, 0xF8
	lda_dri3 XBC, 0x07, 0xE4, 0xF8
	inc 1, iz
	cp iz, 0x10
	jr lt, LABEL_FEDEAA
	jrl ToneGen_NotifyChangeComplete_Return

LABEL_FEDEE2:
	stdi8 4330, 1
	ld xwa, 0xC0
	lds bc, 0
	lds de, 1
	call SoundParam_NotifyChange
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	resda 0, 64941
	ld xwa, 0xC1
	lds bc, 1
	lds de, 1
	call SoundParam_NotifyChange
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	lds iz, 0
	cp iz, 0x10
	jr ge, LABEL_FEDF4E

LABEL_FEDF19:
	ld de, iz
	lda xwa, (xsp + 18)
	ld_srib3 A, 0x07, 0xE0, 0xF8
	ld c, a
	extz bc
	pushw 0x2
	ld wa, de
	ld de, bc
	ldw bc, 0x401
	call SndParam_NotifyAndReturn
	ldada xbc, 61856
	lda xwa, (xsp + 2)
	ld_srib3 A, 0x07, 0xE0, 0xF8
	lda_dri3 XBC, 0x07, 0xE4, 0xF8
	inc 1, iz
	cp iz, 0x10
	jr lt, LABEL_FEDF19

LABEL_FEDF4E:
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

LABEL_FEDF6D:
	lda xsp, (xsp - 32)
	ld xiy, 0xEEC268
	ld xix, xsp
	ldw bc, 0x10
	ldirw
	ldda8 c, 59876
	cps c, 4
	jr z, LABEL_FEDFA3
	cps c, 3
	jr z, LABEL_FEDF90
	cps c, 2
	jr z, LABEL_FEDF90
	cps c, 1
	jr nz, LABEL_FEDFB5

LABEL_FEDF90:
	push xwa
	lda xwa, (xsp + 4)
	push xwa
	call Strcat
	inc 8, xsp
	lda xwa, (xsp)
	call LABEL_F52FB1
	jr ToneGen_RestoreStackReturn

LABEL_FEDFA3:
	call GetCurrentFileIndexAlt
	ld wa, hl
	cps wa, 0
	jr lt, ToneGen_RestoreStackReturn
	ld wa, hl
	call LABEL_F530F9
	jr ToneGen_RestoreStackReturn

LABEL_FEDFB5:
	ldw hl, 0xFFFF

ToneGen_RestoreStackReturn:
	lda xsp, (xsp + 32)
	ret

; ============================================================================
; FileIO_ReadNextRecord - Read next record from file (state machine)
; ============================================================================
; Dispatches on state variable DRAM[59876] (values 1-4).
; Returns: HL = 0 (success), 0xFFFF (error)
; Used for sequential file record reading during disk operations.
; ============================================================================
FileIO_ReadNextRecord:
	ldda8 a, 59876
	cps a, 4
	jr z, LABEL_FEDFFE
	cps a, 3
	jr z, LABEL_FEDFF8
	cps a, 2
	jr z, LABEL_FEDFF8
	cps a, 1
	jr nz, LABEL_FEE004
	calr Seq_CalcAddrOffset
	cp hl, 0x780
	jr lt, LABEL_FEDFE4
	jr LABEL_FEDFEB

LABEL_FEDFDB:
	calr Seq_CalcAddrOffset
	cp hl, 0x780
	jr ge, LABEL_FEDFEB

LABEL_FEDFE4:
	calr SongFile_DecodeMidiEvent
	cps hl, 0
	jr z, LABEL_FEDFDB

LABEL_FEDFEB:
	calr RingBuffer_ReadByte
	cp hl, 0xFFFD
	ret nz
	lds hl, 0
	jr SndParam_DirectReturn

LABEL_FEDFF8:
	call TaskBuf_ReadNextByte
	jr SndParam_DirectReturn

LABEL_FEDFFE:
	call LABEL_F530B0
	jr SndParam_DirectReturn

LABEL_FEE004:
	ldw hl, 0xFFFF

SndParam_DirectReturn:
	ret

LABEL_FEE008:
	ldda8 a, 59876
	cps a, 4
	jr z, LABEL_FEE02B
	cps a, 3
	jr z, LABEL_FEE025
	cps a, 2
	jr z, LABEL_FEE025
	cps a, 1
	jr nz, SndParam_StoreAndReturn
	call FDC_DrainQueuesAndReset
	calr FileIO_InitTrackSlots
	jr SndParam_StoreAndReturn

LABEL_FEE025:
	call FDC_DrainQueuesAndReset
	jr SndParam_StoreAndReturn

LABEL_FEE02B:
	call LABEL_F530B3
	calr FileIO_InitTrackSlots

SndParam_StoreAndReturn:
	stdi16 4597, 120
	ret

LABEL_FEE039:
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
	calr LABEL_FEE1A9
	jrl LABEL_FEE2C9

FileIO_InitTrackSlots:
	stdi16 53416, 0
	stdi16 53418, 0
	stdi16 53420, 2047
	lds de, 0
	jr LABEL_FEE0A2

LABEL_FEE092:
	ld wa, de
	inc 6, wa
	ldada xbc, 53416
	stib_dri 0x07, 0xE4, 0xE0, 0x00
	inc 1, de

LABEL_FEE0A2:
	ld wa, de
	cpda16 xwa, 53420
	jr c, LABEL_FEE092
	ret

LABEL_FEE0AB:
	cpdi16 53420, 0
	jr nz, LABEL_FEE0B8
	ldw hl, 0xFFFF
	jr LABEL_FEE0E0

LABEL_FEE0B8:
	ldda16 xbc, 53416
	ldada xde, 53422
	extz xbc
	add xbc, xde
	ld (xbc), a
	decdi16 1, 53420
	cpdi16 53416, 2047
	jr nz, LABEL_FEE0DA
	stdi16 53416, 0
	jr LABEL_FEE0DE

LABEL_FEE0DA:
	incdi16 1, 53416

LABEL_FEE0DE:
	lds hl, 0

LABEL_FEE0E0:
	ret

RingBuffer_ReadByte:
	ldda16 xwa, 53416
	cpda16 xwa, 53418
	jr nz, LABEL_FEE0F0
	ldw hl, 0xFFFF
	jr LABEL_FEE118

LABEL_FEE0F0:
	ldda16 xwa, 53418
	ldada xbc, 53422
	extz xwa
	add xwa, xbc
	ld l, (xwa)
	extz hl
	incdi16 1, 53420
	cpdi16 53418, 2047
	jr nz, LABEL_FEE114
	stdi16 53418, 0
	jr LABEL_FEE118

LABEL_FEE114:
	incdi16 1, 53418

LABEL_FEE118:
	ret

Seq_CalcAddrOffset:
	ldw hl, 0x7FF
	subda16 xhl, 53420
	ret

LABEL_FEE121:
	.byte 0xef, 0x6e, 0x2e, 0xbf, 0x02, 0x61, 0xbf, 0x06
	.byte 0x50, 0xde, 0xa8, 0xde, 0x88, 0x9f, 0x06, 0xf0
	.byte 0x6f, 0x1f, 0x1e, 0xab, 0xff, 0xdb, 0x88, 0xd8
	.byte 0xd8, 0x69, 0x05, 0x33, 0xff, 0xff, 0x68, 0x13
	.byte 0xaf, 0x02, 0x20, 0xf3, 0x07, 0xe0, 0xf8, 0x47
	.byte 0xde, 0x61, 0xde, 0x88, 0x9f, 0x06, 0xf0, 0x67
	.byte 0xe1, 0xdb, 0xa8, 0x4e, 0xef, 0x66, 0x0e

MidiRingBuf_WriteBytes:
	dec 6, xsp
	pushw iz
	ld (xsp + 4), xbc
	ld iz, wa
	cps iz, 0
	jr nz, LABEL_FEE168
	lds hl, 0
	jr SndParam_PopStackReturn

LABEL_FEE168:
	cpda16 xiz, 53420
	jr ule, LABEL_FEE173
	ldw hl, 0xFFFF
	jr SndParam_PopStackReturn

LABEL_FEE173:
	cpdm16 53420, xiz
	jr ule, LABEL_FEE1A2
	ldw (xsp + 2), 0x0
	lds wa, 0
	cp wa, iz
	jr nc, LABEL_FEE19E

LABEL_FEE184:
	ld xbc, (xsp + 4)
	ld wa, (xsp + 2)
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	calr LABEL_FEE0AB
	incm 1, (xsp + 2)
	ld wa, (xsp + 2)
	cp wa, iz
	jr c, LABEL_FEE184

LABEL_FEE19E:
	lds hl, 0
	jr SndParam_PopStackReturn

LABEL_FEE1A2:
	ldw hl, 0xFFFF

SndParam_PopStackReturn:
	popw iz
	inc 6, xsp
	ret

LABEL_FEE1A9:
	stdi16 55470, 0
	stdi16 55472, 0
	stdi16 55474, 2047
	lds de, 0
	jr LABEL_FEE1CF

LABEL_FEE1BF:
	ld wa, de
	inc 6, wa
	ldada xbc, 55470
	stib_dri 0x07, 0xE4, 0xE0, 0x00
	inc 1, de

LABEL_FEE1CF:
	ld wa, de
	cpda16 xwa, 55474
	jr c, LABEL_FEE1BF
	ret

LABEL_FEE1D8:
	cpdi16 55474, 0
	jr nz, LABEL_FEE1E5
	ldw hl, 0xFFFF
	jr LABEL_FEE20D

LABEL_FEE1E5:
	ldda16 xbc, 55470
	ldada xde, 55476
	extz xbc
	add xbc, xde
	ld (xbc), a
	decdi16 1, 55474
	cpdi16 55470, 2047
	jr nz, LABEL_FEE207
	stdi16 55470, 0
	jr LABEL_FEE20B

LABEL_FEE207:
	incdi16 1, 55470

LABEL_FEE20B:
	lds hl, 0

LABEL_FEE20D:
	ret

LABEL_FEE20E:
	ldda16 xwa, 55470
	cpda16 xwa, 55472
	jr nz, LABEL_FEE21D
	ldw hl, 0xFFFF
	jr LABEL_FEE245

LABEL_FEE21D:
	ldda16 xwa, 55472
	ldada xbc, 55476
	extz xwa
	add xwa, xbc
	ld l, (xwa)
	extz hl
	incdi16 1, 55474
	cpdi16 55472, 2047
	jr nz, LABEL_FEE241
	stdi16 55472, 0
	jr LABEL_FEE245

LABEL_FEE241:
	incdi16 1, 55472

LABEL_FEE245:
	ret

LABEL_FEE246:
	ldw hl, 0x7FF
	subda16 xhl, 55474
	ret

LABEL_FEE24E:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld (xsp + 6), wa
	lds iz, 0
	ld wa, iz
	cp wa, (xsp + 6)
	jr nc, LABEL_FEE27F

LABEL_FEE260:
	calr LABEL_FEE20E
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEE26E
	ldw hl, 0xFFFF
	jr LABEL_FEE281

LABEL_FEE26E:
	ld xwa, (xsp + 2)
	lda_dri3 XSP, 0x07, 0xE0, 0xF8
	inc 1, iz
	ld wa, iz
	cp wa, (xsp + 6)
	jr c, LABEL_FEE260

LABEL_FEE27F:
	lds hl, 0

LABEL_FEE281:
	popw iz
	inc 6, xsp
	ret

SysexRingBuf_WriteBytes:
	dec 6, xsp
	pushw iz
	ld (xsp + 4), xbc
	ld iz, wa
	cps iz, 0
	jr nz, LABEL_FEE295
	lds hl, 0
	jr LABEL_FEE2C5

LABEL_FEE295:
	cpda16 xiz, 55474
	call_24 ugt, 0xFEE1A9
	ldw (xsp + 2), 0x0
	lds wa, 0
	cp wa, iz
	jr nc, LABEL_FEE2C3

LABEL_FEE2A9:
	ld xbc, (xsp + 4)
	ld wa, (xsp + 2)
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	calr LABEL_FEE1D8
	incm 1, (xsp + 2)
	ld wa, (xsp + 2)
	cp wa, iz
	jr c, LABEL_FEE2A9

LABEL_FEE2C3:
	lds hl, 0

LABEL_FEE2C5:
	popw iz
	inc 6, xsp
	ret

LABEL_FEE2C9:
	stdi16 57524, 0
	stdi16 57526, 0
	stdi16 57528, 127
	lds de, 0
	jr LABEL_FEE2EF

LABEL_FEE2DF:
	ld wa, de
	inc 6, wa
	ldada xbc, 57524
	stib_dri 0x07, 0xE4, 0xE0, 0x00
	inc 1, de

LABEL_FEE2EF:
	ld wa, de
	cpda16 xwa, 57528
	jr c, LABEL_FEE2DF
	ret

LABEL_FEE2F8:
	cpdi16 57528, 0
	jr nz, LABEL_FEE305
	ldw hl, 0xFFFF
	jr LABEL_FEE32D

LABEL_FEE305:
	ldda16 xbc, 57524
	ldada xde, 57530
	extz xbc
	add xbc, xde
	ld (xbc), a
	decdi16 1, 57528
	cpdi16 57524, 127
	jr nz, LABEL_FEE327
	stdi16 57524, 0
	jr LABEL_FEE32B

LABEL_FEE327:
	incdi16 1, 57524

LABEL_FEE32B:
	lds hl, 0

LABEL_FEE32D:
	ret

LABEL_FEE32E:
	ldda16 xwa, 57524
	cpda16 xwa, 57526
	jr nz, LABEL_FEE33D
	ldw hl, 0xFFFF
	jr LABEL_FEE365

LABEL_FEE33D:
	ldda16 xwa, 57526
	ldada xbc, 57530
	extz xwa
	add xwa, xbc
	ld l, (xwa)
	extz hl
	incdi16 1, 57528
	cpdi16 57526, 127
	jr nz, LABEL_FEE361
	stdi16 57526, 0
	jr LABEL_FEE365

LABEL_FEE361:
	incdi16 1, 57526

LABEL_FEE365:
	ret

LABEL_FEE366:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld (xsp + 6), wa
	lds iz, 0
	ld wa, iz
	cp wa, (xsp + 6)
	jr nc, LABEL_FEE397

LABEL_FEE378:
	calr LABEL_FEE32E
	ld wa, hl
	cps wa, 0
	jr ge, LABEL_FEE386
	ldw hl, 0xFFFF
	jr LABEL_FEE399

LABEL_FEE386:
	ld xwa, (xsp + 2)
	lda_dri3 XSP, 0x07, 0xE0, 0xF8
	inc 1, iz
	ld wa, iz
	cp wa, (xsp + 6)
	jr c, LABEL_FEE378

LABEL_FEE397:
	lds hl, 0

LABEL_FEE399:
	popw iz
	inc 6, xsp
	ret

LABEL_FEE39D:
	dec 6, xsp
	pushw iz
	ld (xsp + 4), xbc
	ld iz, wa
	cps iz, 0
	jr nz, LABEL_FEE3AD
	lds hl, 0
	jr LABEL_FEE3DD

LABEL_FEE3AD:
	cpda16 xiz, 57528
	call_24 ugt, 0xFEE2C9
	ldw (xsp + 2), 0x0
	lds wa, 0
	cp wa, iz
	jr nc, LABEL_FEE3DB

LABEL_FEE3C1:
	ld xbc, (xsp + 4)
	ld wa, (xsp + 2)
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	calr LABEL_FEE2F8
	incm 1, (xsp + 2)
	ld wa, (xsp + 2)
	cp wa, iz
	jr c, LABEL_FEE3C1

LABEL_FEE3DB:
	lds hl, 0

LABEL_FEE3DD:
	popw iz
	inc 6, xsp
	ret

LABEL_FEE3E1:
	pushw	iz
	lds	iz, 0
	call	16068239
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
	ld xde, 0xE13A
	lds wa, 5
	lds bc, 2
	jp sendCOMM
LABEL_FEE410:
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
	call	15676148
	ret

LABEL_FEE43F:
	dec 4, xsp
	ld (xsp), c
	ld (xsp + 2), a
	ld xwa, 0xC0
	call SndParam_LookupReadOnly
	ld c, (xsp)
	extz bc
	cps hl, 1
	jr nz, LABEL_FEE475
	ld xwa, 0x48
	cp (xsp + 2), 0xF
	jr nz, LABEL_FEE467
	ld xwa, 0x4C

LABEL_FEE467:
	ldda32 xde, 57678
	add xde, xwa
	extz xbc
	add xbc, (xde)
	ld l, (xbc)
	jr LABEL_FEE4A4

LABEL_FEE475:
	extz xbc
	cp (xsp + 2), 0xF
	jr nz, LABEL_FEE484
	ld xwa, 0x40
	jr LABEL_FEE48F

LABEL_FEE484:
	cp (xsp + 2), 0x14
	jr nz, LABEL_FEE49B
	ld xwa, 0x44

LABEL_FEE48F:
	ldda32 xde, 57678
	add xde, xwa
	add xbc, (xde)
	ld l, (xbc)
	jr LABEL_FEE4A4

LABEL_FEE49B:
	ldda32 xwa, 57678
	add xbc, (xwa + 60)
	ld l, (xbc)

LABEL_FEE4A4:
	inc 4, xsp
	ret

LABEL_FEE4A7:
	dec 2, xsp
	ld (xsp), a
	call GetCurrentPartSelect
	extz hl
	ld c, (xsp)
	extz bc
	ld wa, hl
	calr LABEL_FEE43F
	inc 2, xsp
	ret

SndParam_ApplyMaskClamp:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xiz, xwa
	ld xwa, 0xC0
	call SndParam_LookupReadOnly
	cps hl, 1
	jrl z, SndParam_PopIzSkip4Ret
	ld xwa, (xsp + 4)
	cp (xwa), 0x78
	jr z, SndParam_PopIzSkip4Ret
	cp (xiz), 0x7F
	jr ugt, LABEL_FEE4E8
	ld xwa, (xsp + 4)
	andmi8 (xwa), 0x7
	jr SndParam_PopIzSkip4Ret

LABEL_FEE4E8:
	ld xwa, (xsp + 4)
	cp (xwa), 0x7
	jr nz, LABEL_FEE4F6
	resm 7, (xiz)
	ldb c, 0x70
	jr SndParam_StoreResult_Return

LABEL_FEE4F6:
	cp (xiz), 0xEF
	jr ugt, LABEL_FEE517
	ld xwa, (xsp + 4)
	cp (xwa), 0x0
	jr nz, LABEL_FEE509
	resm 7, (xiz)
	ldb c, 0x10
	jr SndParam_StoreResult_Return

LABEL_FEE509:
	ld xwa, (xsp + 4)
	cp (xwa), 0x5
	jr nz, LABEL_FEE54C
	resm 7, (xiz)
	ldb c, 0x15
	jr SndParam_StoreResult_Return

LABEL_FEE517:
	ld xwa, (xsp + 4)
	cp (xwa), 0x1
	jr ugt, LABEL_FEE52E
	andmi8 (xiz), 0xF
	ld c, (xwa)
	and c, 0x1
	set 6, c
	ld (xwa), c
	jr SndParam_PopIzSkip4Ret

LABEL_FEE52E:
	ld xwa, (xsp + 4)
	cp (xwa), 0x6
	jr nz, LABEL_FEE53D
	ld (xiz), 0x0
	ldb c, 0x50
	jr SndParam_StoreResult_Return

LABEL_FEE53D:
	ld xwa, (xsp + 4)
	cp (xwa), 0x5
	jr nz, LABEL_FEE54C
	andmi8 (xiz), 0x3
	ldb c, 0x55
	jr SndParam_StoreResult_Return

LABEL_FEE54C:
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
	st_dri3b L, 0xFD, 0xD0, 0xFE
	pushw iz
	st_dri3w DE, 0xFD, 0x2C, 0x01
	st_dri3w BC, 0xFD, 0x2E, 0x01
	lda_dri3 XBC, 0xFD, 0x30, 0x01
	ld (xsp + 6), 0xFF
	lds32 xwa, 0
	ld (xsp + 2), xwa
	jr LABEL_FEE5EF

LABEL_FEE57A:
	call SeqAlt3_ReadByte
	cp hl, 0xFFFF
	jr z, LABEL_FEE5DF
	lda xwa, (xsp + 12)
	ld (xsp + 8), xwa
	lds32 xwa, 1
	add (xsp + 8), xwa
	lds iz, 0

LABEL_FEE591:
	call SeqAlt3_ReadByte
	ld xwa, (xsp + 8)
	lda_dpi XSP, 0xE0
	ld (xsp + 8), xwa
	inc 1, iz
	cps iz, 7
	jr c, LABEL_FEE591
	lda xbc, (xsp + 12)
	ld a, (xbc + 7)
	cp_srib_rm A, 0xFD, 0x30, 0x01
	jr nz, LABEL_FEE5DF
	ld (xbc), 0x0
	lds iz, 0
	cp_sriw_im 0xFD, 0x2E, 0x01, 0x00, 0x00
	jr ule, LABEL_FEE5D9

LABEL_FEE5BF:
	call SeqAlt3_ReadByte
	ld_sril XWA, (xsp + 0x0136)
	lda_dpi XSP, 0xE0
	st_dri3l XWA, 0xFD, 0x36, 0x01
	inc 1, iz
	cp_sriw_rm IZ, 0xFD, 0x2E, 0x01
	jr c, LABEL_FEE5BF

LABEL_FEE5D9:
	ld (xsp + 6), 0x0
	jr LABEL_FEE5FC

LABEL_FEE5DF:
	lds32 xwa, 1
	add (xsp + 2), xwa
	ld xwa, (xsp + 2)
	cp xwa, 0xE00
	jr ge, LABEL_FEE5FC

LABEL_FEE5EF:
	ld_sriw WA, (xsp + 0x012c)
	extz xwa
	cp (xsp + 2), xwa
	jrl lt, LABEL_FEE57A

LABEL_FEE5FC:
	ld l, (xsp + 6)
	popw iz
	st_dri3b L, 0xFD, 0x30, 0x01
	retd 0x4

LABEL_FEE608:
	ldda32 xhl, 57678
	ld xde, (xhl + 4)
	dec 1, xde
	lds32 xix, 0
	ldfr_berp A, 0xF0
	cp xix, xde
	jr ugt, LABEL_FEE635
	ld xhl, (xhl)
	extz wa
	sll wa, 4
	extz xwa
	add xhl, xwa
	ld xde, xbc
	lda xbc, (xbc + 16)

LABEL_FEE62A:
	ld_spib A, 0xEC
	lda_dpi XBC, 0xE8
	cp xde, xbc
	jr c, LABEL_FEE62A
	ret

LABEL_FEE635:
	lda_24 xwa, 0xeed298
	ld xde, xwa
	lda xhl, (xwa + 16)

LABEL_FEE63F:
	ld_spib A, 0xE8
	lda_dpi XBC, 0xE4
	cp xde, xhl
	jr c, LABEL_FEE63F
	ret

SndParam_ApplyProgramChangeAsync:
	dec 8, xsp
	push_werp 0xFA
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
	call LABEL_FEF252
	extz hl
	ld xbc, (xsp + 2)
	push xbc
	ld wa, hl
	ldw bc, 0x11
	ldw de, 0xE00
	calr SndParam_StoreDRAMInit
	ldfr_berp L, 0xFB
	lds wa, 5
	call TaskSched_SignalEvent
	cpi_berp 0xFB, 0
	jr z, LABEL_FEE6AB
	lda_24 xwa, 0xeed2a8
	ld xbc, xwa
	ld xde, (xsp + 2)
	lda xhl, (xwa + 17)

LABEL_FEE6A1:
	ld_spib A, 0xE4
	lda_dpi XBC, 0xE8
	cp xbc, xhl
	jr c, LABEL_FEE6A1

LABEL_FEE6AB:
	pop_werp 0xFA
	inc 8, xsp
	ret

LABEL_FEE6B1:
	dec 6, xsp
	push_werp 0xFA
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
	call LABEL_FEF293
	extz hl
	lda xbc, (xsp + 2)
	push xbc
	ld wa, hl
	lds bc, 1
	ldw de, 0xE00
	calr SndParam_StoreDRAMInit
	ldfr_berp L, 0xFB
	lds wa, 5
	call TaskSched_SignalEvent
	cpi_berp 0xFB, 0
	jr z, LABEL_FEE6FD
	ld (xsp + 2), 0x0
	jr LABEL_FEE709

LABEL_FEE6FD:
	ldb a, 0x0
	bitm 7, (xsp + 2)
	jr z, LABEL_FEE706
	ldb a, 0x7F

LABEL_FEE706:
	ld (xsp + 2), a

LABEL_FEE709:
	ld l, (xsp + 2)
	pop_werp 0xFA
	inc 6, xsp
	ret

LABEL_FEE712:
	dec 8, xsp
	push_werp 0xFA
	ld (xsp + 2), xde
	ld (xsp + 6), c
	ld (xsp + 8), a
	lds wa, 5
	call TaskSched_WaitForEvent
	ld a, (xsp + 8)
	extz wa
	ld c, (xsp + 6)
	extz bc
	call LABEL_FEF2D4
	extz hl
	ld xbc, (xsp + 2)
	push xbc
	ld wa, hl
	ldw bc, 0xA
	ldw de, 0xE00
	calr SndParam_StoreDRAMInit
	ldfr_berp L, 0xFB
	lds wa, 5
	call TaskSched_SignalEvent
	cpi_berp 0xFB, 0
	jr z, LABEL_FEE76A
	lda_24 xwa, 0xeed2b9
	ld xbc, xwa
	ld xde, (xsp + 2)
	lda xhl, (xwa + 10)

LABEL_FEE760:
	ld_spib A, 0xE4
	lda_dpi XBC, 0xE8
	cp xbc, xhl
	jr c, LABEL_FEE760

LABEL_FEE76A:
	pop_werp 0xFA
	inc 8, xsp
	ret

LABEL_FEE770:
	ld xwa, 0xC0
	call SndParam_LookupReadOnly
	cps hl, 1
	jr nz, LABEL_FEE78E
	call GetCurrentPartSelect
	cp l, 0xF
	jr z, LABEL_FEE78A
	ldb l, 0x80
	jr LABEL_FEE797

LABEL_FEE78A:
	ldb l, 0x89
	jr LABEL_FEE797

LABEL_FEE78E:
	ldda32 xwa, 57678
	ld xwa, (xwa + 4)
	ld l, a

LABEL_FEE797:
	ret

LABEL_FEE798:
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

LABEL_FEE7D4:
	ld xbc, 0x10
	ldw de, 0x400
	jr LABEL_FEE798

LABEL_FEE7DE:
	ld xbc, 0x20
	ldw de, 0x200
	jr LABEL_FEE798
	jr LABEL_FEE7D4

SndParam_FetchOscTableEntry:
	push xiz
	ld xiz, xwa
	ld xwa, 0xC0
	call SndParam_LookupReadOnly
	cps hl, 1
	jr nz, LABEL_FEE801
	ld xwa, xiz
	calr LABEL_FEE7DE
	jr LABEL_FEE806

LABEL_FEE801:
	ld xwa, xiz
	calr LABEL_FEE7D4

LABEL_FEE806:
	pop xiz
	ret

LABEL_FEE808:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xiz, xwa
	calr LABEL_FEE770
	ldda32 xbc, 57678
	ld xwa, (xbc + 8)
	ld e, a
	cp (xiz), l
	jr nc, LABEL_FEE824
	ld w, (xiz)
	jr LABEL_FEE826

LABEL_FEE824:
	ldb w, 0x0

LABEL_FEE826:
	ldb l, 0x0
	ld a, (xiz + 1)
	cp a, e
	jr nc, LABEL_FEE831
	ld l, a

LABEL_FEE831:
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

LABEL_FEE853:
	ld xbc, 0x14
	jr LABEL_FEE808

LABEL_FEE85A:
	ld xbc, 0x24
	jr LABEL_FEE808

SndParam_ApplyProgramChange:
	push xiz
	ld xiz, xwa
	ld xwa, 0xC0
	call SndParam_LookupReadOnly
	cps hl, 1
	jr nz, LABEL_FEE878
	ld xwa, xiz
	calr LABEL_FEE85A
	jr LABEL_FEE87D

LABEL_FEE878:
	ld xwa, xiz
	calr LABEL_FEE853

LABEL_FEE87D:
	pop xiz
	ret

LABEL_FEE87F:
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

LABEL_FEE8BF:
	ld xbc, 0x18
	ldw de, 0x400
	jr LABEL_FEE87F

SndParam_InitBufferConverge:
	ld xbc, 0x28
	ldw de, 0x200
	jr LABEL_FEE87F

LABEL_FEE8D3:
	push xiz
	ld xiz, xwa
	ld xwa, 0xC0
	call SndParam_LookupReadOnly
	cps hl, 1
	jr nz, LABEL_FEE8EA
	ld xwa, xiz
	calr SndParam_InitBufferConverge
	jr LABEL_FEE8EF

LABEL_FEE8EA:
	ld xwa, xiz
	calr LABEL_FEE8BF

LABEL_FEE8EF:
	pop xiz
	ret

SndParam_LookupOscEnvelope:
	push xiz
	ld xiz, xwa
	ld a, (xiz + 5)
	cp a, 0xF
	jr z, LABEL_FEE941
	extz wa
	lds bc, 0
	call SndParam_LookupViaEncode
	lda xbc, (xiz + 2)
	cp hl, 0xF0
	jr lt, LABEL_FEE916
	ldda32 xwa, 57678
	ld xhl, (xwa + 48)
	jr LABEL_FEE94B

LABEL_FEE916:
	ldda32 xwa, 57678
	ld xde, (xwa + 28)
	lds32 xwa, 0
	ld a, (xbc)
	sll xwa, 2
	add xde, xwa
	ld xhl, (xde)
	ld c, (xiz + 1)
	lda xde, (xhl + 2)
	jr LABEL_FEE934

LABEL_FEE930:
	inc 3, xhl
	inc 3, xde

LABEL_FEE934:
	ld a, (xde)
	cp c, a
	jr nc, LABEL_FEE930
	cp a, 0xFF
	jr nz, LABEL_FEE930
	jr LABEL_FEE957

LABEL_FEE941:
	ldda32 xwa, 57678
	ld xhl, (xwa + 48)
	lda xbc, (xiz + 2)

LABEL_FEE94B:
	ld a, (xbc)
	sll a, 1
	extz wa
	st_dri3b C, 0x07, 0xEC, 0xE0

LABEL_FEE957:
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
	cp a, 0xF
	jr z, LABEL_FEE993
	extz wa
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	lda xbc, (xiz + 4)
	ld a, (xiz + 2)
	ld (xiz + 3), a
	cp hl, 0x78
	jr nz, LABEL_FEE98C
	ld (xbc), 0x78
	jr LABEL_FEE99D

LABEL_FEE98C:
	ld a, (xiz + 1)
	ld (xbc), a
	jr LABEL_FEE99D

LABEL_FEE993:
	ld a, (xiz + 2)
	ld (xiz + 3), a
	ld (xiz + 4), 0x78

LABEL_FEE99D:
	pop xiz
	ret

LABEL_FEE99F:
	push	xiz
	ld	xiz, xwa
	ld	xwa, 192
	call	16569399
	cps	hl, 1
	jr	nz, 7
	ld	xwa, xiz
	calr	65456
	jr	5
	ld	xwa, xiz
	calr	65334
	pop	xiz
	ret

LABEL_FEE9BD:
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

LABEL_FEE9EA:
	dec 6, xsp
	push xiz
	ld e, c
	ldda32 xbc, 57678
	ld xiz, (xbc + 52)
	lda xbc, (xsp + 4)
	ld (xbc + 3), a
	ld (xbc + 4), e
	ld xwa, xbc
	calr LABEL_FEE8D3
	ld a, (xsp + 6)
	extz wa
	extz xwa
	add xwa, xiz
	ld l, (xwa)
	pop xiz
	inc 6, xsp
	ret

LABEL_FEEA13:
	.byte 0xd8, 0x12, 0xf2, 0x46, 0xd3, 0xee, 0x31, 0xc3
	.byte 0x07, 0xe4, 0xe0, 0x21, 0xd8, 0x12, 0xc9, 0x8f
	.byte 0x0e

LABEL_FEEA24:
	dec 6, xsp
	push_werp 0xFA
	ld (xsp + 4), c
	ld (xsp + 6), a
	ld (xsp + 2), 0xFF
	ld xwa, 0xC0
	call SndParam_LookupReadOnly
	cps hl, 1
	jr z, LABEL_FEEABE
	cp (xsp + 4), 0x78
	jr nz, LABEL_FEEA63
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

LABEL_FEEA63:
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
	jr nz, LABEL_FEEABE

SndParam_DispatchProcessParam:
	lds wa, 5
	call TaskSched_WaitForEvent
	ld a, (xsp + 6)
	extz wa
	ld c, (xsp + 4)
	extz bc
	call LABEL_FEF315
	extz hl
	lda xbc, (xsp + 2)
	push xbc
	ld wa, hl
	lds bc, 1
	ldw de, 0xE00
	calr SndParam_StoreDRAMInit
	ldfr_berp L, 0xFB
	lds wa, 5
	call TaskSched_SignalEvent
	ldb a, 0x2
	cpi_berp 0xFB, 0
	jr nz, LABEL_FEEABB
	ld a, (xsp + 2)

LABEL_FEEABB:
	ld (xsp + 2), a

LABEL_FEEABE:
	ld l, (xsp + 2)
	pop_werp 0xFA
	inc 6, xsp
	ret

SndParam_LookupByChannel:
	dec 2, xsp
	ld (xsp), a
	extz bc
	extz de
	ld wa, bc
	ld bc, de
	calr LABEL_FEEA24
	ld c, (xsp + 6)
	cp l, 0xFF
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
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xfeeb06
	jp_dri 8, 0x07, 0xF0, 0xE0

; Sound parameter type dispatch (6-entry, table 0xEED3C6)
SndParam_TypeDispatch:	; FEEB06
	extz hl
	muls hl, 0x18
	jr SndParam_LoadTableConverge

LABEL_FEEB0E:
	extz hl
	muls hl, 0x18
	inc 4, hl
	jr SndParam_LoadTableConverge

LABEL_FEEB18:
	extz hl
	muls hl, 0x18
	inc 8, hl
	jr SndParam_LoadTableConverge

LABEL_FEEB22:
	extz hl
	muls hl, 0x18
	add hl, 0xC

SndParam_LoadTableConverge:
	ldada xde, 60433
	ld_sril3 XDE, 0x07, 0xE8, 0xEC
	ldb b, 0x0
	extz xbc
	add xbc, xde
	ld l, (xbc)
	jr LABEL_FEEB54

LABEL_FEEB3F:
	ld xwa, 0xEED198
	jr LABEL_FEEB4B

LABEL_FEEB46:
	ld xwa, 0xEED218

LABEL_FEEB4B:
	ld_srib3 L, 0x07, 0xE0, 0xE8
	jr LABEL_FEEB54

SndParam_LoadReturnByte:
	ld l, c

LABEL_FEEB54:
	inc 2, xsp
	retd 0x2

; Sound parameter offset dispatch handler
SndParam_OffsetHandler:	; FEEB59
	dec 4, xsp
	ld (xsp), e
	ld (xsp + 2), a
	extz bc
	ld wa, bc
	lds bc, 0
	calr LABEL_FEEA24
	cp l, 0xFF
	jr z, LABEL_FEEBD7
	ld e, (xsp + 2)
	ld c, (xsp)
	extz bc
	extz de
	dec 1, de
	cps de, 0
	jr lt, LABEL_FEEBD7
	cps de, 5
	jr gt, LABEL_FEEBD7
	add de, de
	lda_24 xix, 0xeed3d2
	ld_sriw3 DE, 0x07, 0xF0, 0xE8
	lda_24 xix, 0xfeeb97
	jp_dri 8, 0x07, 0xF0, 0xE8

; Sound parameter offset dispatch (6-entry, table 0xEED3D2)
SndParam_OffsetDispatch:	; FEEB97
	ldw bc, 0x10
	jr SndParam_LookupTableConverge

LABEL_FEEB9C:
	ldw bc, 0x14
	jr SndParam_LookupTableConverge

LABEL_FEEBA1:
	ldw bc, 0x8
	jr SndParam_LookupTableConverge

LABEL_FEEBA6:
	ldw bc, 0xC

SndParam_LookupTableConverge:
	extz hl
	muls hl, 0x18
	add hl, bc
	ldada xbc, 60433
	ld_sril3 XBC, 0x07, 0xE4, 0xEC
	lds32 xwa, 0
	ld a, (xsp)
	add xwa, xbc
	ld l, (xwa)
	jr LABEL_FEEBD9

LABEL_FEEBC4:
	ld xwa, 0xEED198
	jr LABEL_FEEBD0

LABEL_FEEBCB:
	ld xwa, 0xEED218

LABEL_FEEBD0:
	ld_srib3 L, 0x07, 0xE0, 0xE4
	jr LABEL_FEEBD9

LABEL_FEEBD7:
	ld l, (xsp)

LABEL_FEEBD9:
	inc 4, xsp
	ret

Param_SignExtendReturn:
	extz wa
	extz bc
	extz de
	jrl SndParam_OffsetHandler

LABEL_FEEBE5:
	ret

LABEL_FEEBE6:
	ld32_24 xwa, 0xe0239c
	stda32 57678, xwa
	ret

LABEL_FEEBF0:
	jr LABEL_FEEBE6
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

LABEL_FEEC1B:
	.byte 0xeb, 0xa8, 0x88, 0x06, 0x27, 0xeb, 0xee, 0x0e
	.byte 0x88, 0x07, 0x25, 0xcd, 0x30, 0x07, 0x24, 0x00
	.byte 0xea, 0x12, 0xea, 0xee, 0x07, 0x88, 0x08, 0x23
	.byte 0xcb, 0x30, 0x07, 0x22, 0x00, 0xe9, 0x12, 0xea
	.byte 0xe3, 0xe9, 0xe3, 0x0e, 0xd8, 0x8b, 0xd9, 0x06
	.byte 0xd9, 0xc3, 0x0f, 0x04, 0x00, 0xef, 0x6a, 0xb7
	.byte 0x43, 0xe8, 0x89, 0xe9, 0xcf, 0xaa, 0x01, 0x00
	.byte 0x00, 0x67, 0x40, 0xe9, 0xca, 0xaa, 0x01, 0x00
	.byte 0x00, 0xe9, 0x88, 0x41, 0x0b, 0x00, 0x00, 0x00
	.byte 0x1d, 0x12, 0x0c, 0xff, 0xeb, 0xcf, 0x09, 0x00
	.byte 0x00, 0x00, 0x7b, 0x9b, 0x01, 0xeb, 0x83, 0xeb
	.byte 0xc8, 0xa4, 0xd4, 0xee, 0x00, 0x93, 0x23, 0xf2
	.byte 0x84, 0xec, 0xfe, 0x34, 0xf3, 0x07, 0xf0, 0xec
	.byte 0xd8, 0x87, 0x21, 0xd8, 0x13, 0x0b, 0x7f, 0x00
	.byte 0x0b, 0x00, 0x00, 0x31, 0xff, 0xff, 0xda, 0xa8
	.byte 0x78, 0x70, 0x01, 0xe9, 0xcf, 0x66, 0x00, 0x00
	.byte 0x00, 0x77, 0xa7, 0x00, 0xe9, 0xca, 0x66, 0x00
	.byte 0x00, 0x00, 0xe9, 0x88, 0x41, 0x51, 0x00, 0x00
	.byte 0x00, 0x1d, 0x12, 0x0c, 0xff, 0xeb, 0xcf, 0x4c
	.byte 0x00, 0x00, 0x00, 0x7b, 0x52, 0x01, 0xeb, 0xc8
	.byte 0x49, 0xd4, 0xee, 0x00
	.byte 0x93, 0x23, 0xdb, 0x12
	.byte 0xdb, 0xee, 0x01, 0x44, 0x96, 0xd4, 0xee, 0x00
	.byte 0xd3, 0x07, 0xf0, 0xec, 0x23, 0xf2, 0xda, 0xec
	.byte 0xfe, 0x34, 0xf3, 0x07, 0xf0, 0xec, 0xd8, 0x87
	.byte 0x21, 0xd8, 0x13, 0x0b, 0x32, 0x00, 0x0b, 0x00
	.byte 0x00, 0x31, 0xff, 0xff, 0xda, 0xa8, 0x78, 0x1a
	.byte 0x01, 0x87, 0x21, 0xd8, 0x13, 0x0b, 0x80, 0x00
	.byte 0x0b, 0x00, 0x00, 0x31, 0xff, 0xff, 0xda, 0xa8
	.byte 0x78, 0x08, 0x01, 0x87, 0x21, 0xd8, 0x13, 0x0b
	.byte 0x7f, 0x00, 0x0b, 0x00, 0x00, 0x31, 0xff, 0xff
	.byte 0xda, 0xa8, 0x78, 0xf6, 0x00, 0x87, 0x21, 0xd8
	.byte 0x13, 0x0b, 0x18, 0x00, 0x0b, 0xe8, 0xff, 0x31
	.byte 0xff, 0xff, 0xda, 0xa8, 0x78, 0xe4, 0x00, 0x87
	.byte 0x21, 0xd8, 0x13, 0x0b, 0x32, 0x00, 0x0b, 0xce
	.byte 0xff, 0x31, 0xff, 0xff, 0xda, 0xa8, 0x78, 0xd2
	.byte 0x00, 0x87, 0x21, 0xd8, 0x13, 0x0b, 0x64, 0x00
	.byte 0x0b, 0x00, 0x00, 0x31, 0xff, 0xff, 0xda, 0xa8
	.byte 0x78, 0xc0, 0x00, 0xe8, 0x89, 0xe8, 0xcf, 0x0f
	.byte 0x00, 0x00, 0x00, 0x6a, 0x08, 0xe8, 0xcf, 0x00
	.byte 0x00, 0x00, 0x00, 0x69, 0x39, 0xe9, 0xca, 0x10
	.byte 0x00, 0x00, 0x00, 0xe9, 0xcf, 0x00, 0x00, 0x00
	.byte 0x00, 0x71, 0xa4, 0x00, 0xe9, 0xcf, 0x4c, 0x00
	.byte 0x00, 0x00, 0x7a, 0x9b, 0x00, 0xe9, 0xc8, 0xee
	.byte 0xd3, 0xee, 0x00, 0x91, 0x21, 0xd9, 0x12, 0xd9
	.byte 0xee, 0x01, 0x44, 0x3b, 0xd4, 0xee, 0x00, 0xd3
	.byte 0x07, 0xf0, 0xe4, 0x21, 0xf2, 0x91, 0xed, 0xfe
	.byte 0x34, 0xf3, 0x07, 0xf0, 0xe4, 0xd8, 0x87, 0x21
	.byte 0xd8, 0x13, 0x0b, 0x7f, 0x00, 0x0b, 0x20, 0x00
	.byte 0x31, 0xff, 0xff, 0xda, 0xa8, 0x68, 0x64, 0x87
	.byte 0x21, 0xd8, 0x13, 0x0b, 0x42, 0x00, 0x0b, 0x00
	.byte 0x00, 0x31, 0xff, 0xff, 0xda, 0xa8, 0x68, 0x53
	.byte 0x87, 0x21, 0xd8, 0x13, 0x0b, 0x31, 0x00, 0x0b
	.byte 0x00, 0x00, 0x31, 0x7f, 0x00, 0xda, 0xa8, 0x68
	.byte 0x42, 0x87, 0x21, 0xd8, 0x13, 0x0b, 0x7f, 0x00
	.byte 0x0b, 0x00, 0x00, 0x31, 0xff, 0xff, 0xda, 0xa8
	.byte 0x68, 0x31, 0x87, 0x21, 0xd8, 0x13, 0x0b, 0x0a
	.byte 0x00, 0x0b, 0x06, 0x00, 0x31, 0xff, 0xff, 0xda
	.byte 0xa8, 0x68, 0x20, 0x87, 0x21, 0xd8, 0x13, 0x0b
	.byte 0x32, 0x00, 0x0b, 0x00, 0x00, 0x31, 0x7f, 0x00
	.byte 0xda, 0xa8, 0x68, 0x0f, 0x87, 0x21, 0xd8, 0x13
	.byte 0x0b, 0x1e, 0x00, 0x0b, 0x00, 0x00, 0x31, 0x3f
	.byte 0x00, 0xda, 0xa8, 0x1e, 0x36, 0xfe, 0xb7, 0x47
	.byte 0x87, 0x27, 0xef, 0x62, 0x0e, 0xef, 0x6e, 0x3e
	.byte 0xbf, 0x08, 0x43, 0xe8, 0x8e, 0x8f, 0x08, 0x23
	.byte 0xd9, 0x13, 0xbf, 0x06, 0x51, 0xbf, 0x04, 0x51
	.byte 0xee, 0xcf, 0x27, 0x01, 0x00, 0x00, 0x77, 0x35
	.byte 0x01, 0xee, 0x88, 0xe8, 0xca, 0x27, 0x01, 0x00
	.byte 0x00, 0x41, 0x50, 0x00, 0x00, 0x00, 0x1d, 0x18
	.byte 0x0c, 0xff, 0xcf, 0x89, 0xd8, 0x12, 0xd8, 0x09
	.byte 0x50, 0x00, 0xe8, 0x12, 0xf3, 0xe1, 0x27, 0x01
	.byte 0x30, 0xb8, 0x3a, 0x30, 0xe8, 0xf6, 0x67, 0x3d
	.byte 0xee, 0x89, 0xe8, 0xa1, 0xe9, 0x88, 0x41, 0x0b
	.byte 0x00, 0x00, 0x00, 0x1d, 0x12, 0x0c, 0xff, 0xeb
	.byte 0xcf, 0x09, 0x00, 0x00, 0x00, 0x7b, 0x73, 0x01
	.byte 0xeb, 0x83, 0xeb, 0xc8, 0x0c, 0xd5, 0xee, 0x00
	.byte 0x93, 0x23, 0xf2, 0x7f, 0xee, 0xfe, 0x34, 0xf3
	.byte 0x07, 0xf0, 0xec, 0xd8, 0x0b, 0x7f, 0x00, 0x0b
	.byte 0x00, 0x00, 0x9f, 0x0a, 0x20, 0x31, 0xff, 0xff
	.byte 0xda, 0xa8, 0x78, 0x48, 0x01, 0xdb, 0x12, 0xdb
	.byte 0x08, 0x50, 0x00, 0xeb, 0xc8, 0x27, 0x01, 0x00
	.byte 0x00, 0xee, 0x89, 0xeb, 0xa1, 0xe9, 0x88, 0xe9
	.byte 0xcf, 0x0c, 0x00, 0x00, 0x00, 0x6b, 0x08, 0xe9
	.byte 0xcf, 0x00, 0x00, 0x00, 0x00, 0x6f, 0x39, 0xe8
	.byte 0xca, 0x0d, 0x00, 0x00, 0x00, 0xe8, 0xcf, 0x00
	.byte 0x00, 0x00, 0x00, 0x77, 0x1d, 0x01, 0xe8, 0xcf
	.byte 0x28, 0x00, 0x00, 0x00, 0x7b, 0x14, 0x01, 0xe8
	.byte 0xc8, 0xd5, 0xd4, 0xee, 0x00, 0x90, 0x20, 0xd8
	.byte 0x12, 0xd8, 0xee, 0x01, 0x44, 0xfe, 0xd4, 0xee
	.byte 0x00, 0xd3, 0x07, 0xf0, 0xe0, 0x20, 0xf2, 0xeb
	.byte 0xee, 0xfe, 0x34, 0xf3, 0x07, 0xf0, 0xe0, 0xd8
	.byte 0x0b, 0x7f, 0x00, 0x0b, 0x20, 0x00, 0x9f, 0x08
	.byte 0x20, 0x31, 0xff, 0xff, 0xda, 0xa8, 0x78, 0xdc
	.byte 0x00, 0x0b, 0x7f, 0x00, 0x0b, 0x00, 0x00, 0x9f
	.byte 0x0a, 0x20, 0x31, 0xff, 0xff, 0xda, 0xa8, 0x78
	.byte 0xcb, 0x00, 0x0b, 0x32, 0x00, 0x0b, 0x00, 0x00
	.byte 0x9f, 0x0a, 0x20, 0x31, 0xff, 0xff, 0xda, 0xa8
	.byte 0x78, 0xba, 0x00, 0x0b, 0x80, 0x00, 0x0b, 0x00
	.byte 0x00, 0x9f, 0x0a, 0x20, 0x31, 0xff, 0xff, 0xda
	.byte 0xa8, 0x78, 0xa9, 0x00, 0x0b, 0x7f, 0x00, 0x0b
	.byte 0x00, 0x00, 0x9f, 0x0a, 0x20, 0x31, 0xff, 0xff
	.byte 0xda, 0xa8, 0x78, 0x98, 0x00, 0x0b, 0x32, 0x00
	.byte 0x0b, 0xce, 0xff, 0x9f, 0x0a, 0x20, 0x31, 0xff
	.byte 0xff, 0xda, 0xa8, 0x78, 0x87, 0x00, 0x0b, 0x64
	.byte 0x00, 0x0b, 0x00, 0x00, 0x9f, 0x0a, 0x20, 0x31
	.byte 0xff, 0xff, 0xda, 0xa8, 0x68, 0x77, 0xe8, 0x89
	.byte 0xe8, 0xcf, 0x0f, 0x00, 0x00, 0x00, 0x6a, 0x08
	.byte 0xe8, 0xcf, 0x00, 0x00, 0x00, 0x00, 0x69, 0x37
	.byte 0xe9, 0xca, 0x10, 0x00, 0x00, 0x00, 0xe9, 0xcf
	.byte 0x00, 0x00, 0x00, 0x00, 0x61, 0x5d, 0xe9, 0xcf
	.byte 0x16, 0x00, 0x00, 0x00, 0x6a, 0x55, 0xe9, 0xc8
	.byte 0xb8, 0xd4, 0xee, 0x00
	.byte 0x91, 0x21, 0xd9, 0x12
	.byte 0xd9, 0xee, 0x01, 0x44, 0xcf, 0xd4, 0xee, 0x00
	.byte 0xd3, 0x07, 0xf0, 0xe4, 0x21, 0xf2, 0xaa, 0xef
	.byte 0xfe, 0x34, 0xf3, 0x07, 0xf0, 0xe4, 0xd8, 0x0b
	.byte 0x7f, 0x00, 0x0b, 0x20, 0x00, 0x9f, 0x08, 0x20
	.byte 0x31, 0xff, 0xff, 0xda, 0xa8, 0x68, 0x1e, 0x0b
	.byte 0x31, 0x00, 0x0b, 0x00, 0x00, 0x9f, 0x0a, 0x20
	.byte 0x31, 0x7f, 0x00, 0xda, 0xa8, 0x68, 0x0e, 0x0b
	.byte 0x7f, 0x00, 0x0b, 0x00, 0x00, 0x9f, 0x0a, 0x20
	.byte 0x31, 0xff, 0xff, 0xda, 0xa8, 0x1e, 0x64, 0xfc
	.byte 0xbf, 0x08, 0x47, 0x8f, 0x08, 0x27, 0x5e, 0xef
	.byte 0x66, 0x0e, 0x0e, 0xbf, 0xea, 0x37, 0x2e, 0xbf
	.byte 0x14, 0x60, 0xaf, 0x14, 0x20, 0x1e, 0xff, 0xfb
	.byte 0xbf, 0x06, 0x53, 0xaf, 0x14, 0x20, 0x1e, 0x1f
	.byte 0xfc, 0x9f, 0x06, 0x3f, 0x00, 0x00, 0x76, 0xcd
	.byte 0x00, 0x9f, 0x06, 0x3f, 0x78, 0x00, 0x72, 0xc5
	.byte 0x00, 0xeb, 0xe3, 0x76, 0xc0, 0x00, 0xeb, 0x88
	.byte 0xe8, 0xed, 0x0f, 0xe8, 0xed, 0x00, 0xe8, 0xcc
	.byte 0xff, 0x3f, 0x00, 0x00, 0xeb, 0x80, 0xe8, 0xcc
	.byte 0x00, 0xc0, 0xff, 0xff, 0xbf, 0x02, 0x63, 0xaf
	.byte 0x02, 0xa8, 0xaf, 0x02, 0x21, 0x89, 0x10, 0x21
	.byte 0xc9, 0xcc, 0xc0, 0xc9, 0xcf, 0xc0, 0x76, 0x9a
	.byte 0x00, 0xc9, 0xcf, 0x40, 0x76, 0x94, 0x00, 0xc9
	.byte 0xcf, 0x80, 0x66, 0x05, 0xc9, 0xd8, 0x7e, 0x8a
	.byte 0x00, 0xe9, 0xcf, 0xd6, 0x01, 0x00, 0x00, 0x6b
	.byte 0x7d, 0xf1, 0x98, 0xe1, 0x32, 0xb2, 0x00, 0x2d
	.byte 0xaf, 0x14, 0x20, 0xb8, 0x06, 0x33, 0xba, 0x01
	.byte 0x30, 0xbf, 0x0c, 0x60, 0xde, 0xde, 0x6f, 0x0d
	.byte 0xaf, 0x0c, 0x20, 0x83, 0x23, 0xb0, 0x43, 0xde
	.byte 0x61, 0xde, 0xde, 0x67, 0xf3, 0xba, 0x07, 0x00
	.byte 0x00, 0xba, 0x08, 0x30, 0xbf, 0x10, 0x60, 0xbf
	.byte 0x0c, 0x60, 0x9f, 0x06, 0x20, 0xd8, 0xf6, 0x6f
	.byte 0x2e, 0xaf, 0x10, 0x20, 0x88, 0x01, 0x23, 0xcb
	.byte 0xcc, 0x0f, 0xaf, 0x0c, 0x20, 0x80, 0x21, 0xc9
	.byte 0xee, 0x04, 0xcb, 0xe1, 0xc9, 0x8b, 0xaf, 0x02
	.byte 0x20, 0x1e, 0xa1, 0xfb, 0xaf, 0x10, 0x20, 0xb0
	.byte 0x47, 0xde, 0x61, 0xe8, 0xaa, 0xaf, 0x08, 0x88
	.byte 0x9f, 0x06, 0x20, 0xd8, 0xf6, 0x67, 0xd2, 0x9f
	.byte 0x06, 0x21, 0xd9, 0x60, 0xd8, 0xab, 0x42, 0x98
	.byte 0xe1, 0x00, 0x00, 0x1d, 0xf4, 0x32, 0xef, 0xbf
	.byte 0x12, 0x02, 0x00, 0x00, 0x68, 0x05, 0xbf, 0x12
	.byte 0x02, 0x01, 0x00, 0x9f, 0x12, 0x23, 0x4e, 0xbf
	.byte 0x16, 0x37, 0x0e, 0xe8, 0x8a, 0xba, 0x0c, 0x33
	.byte 0x8b, 0x01, 0x23, 0xcb, 0xcc, 0x0f, 0x83, 0x20
	.byte 0xc8, 0xee, 0x04, 0xcb, 0xe0, 0x8b, 0x04, 0x23
	.byte 0xcb, 0xcc, 0x0f, 0x8b, 0x03, 0x21, 0xc9, 0xee
	.byte 0x04, 0xcb, 0xe1, 0xc9, 0xcf, 0x10, 0x66, 0x05
	.byte 0xc9, 0xcf, 0x11, 0x6e, 0x0b, 0xf1, 0x93, 0xe1
	.byte 0x62, 0xd8, 0xab, 0x31, 0x15, 0x00, 0x68, 0x17
	.byte 0xc9, 0xcf, 0x50, 0x66, 0x05, 0xc9, 0xcf, 0x51
	.byte 0x6e, 0x15, 0xc8, 0xda, 0x6f, 0x11, 0xf1, 0x93
	.byte 0xe1, 0x62, 0xd8, 0xab, 0x31, 0x15, 0x00, 0x1d
	.byte 0xf4, 0x32, 0xef, 0xdb, 0xa8, 0x68, 0x02, 0xdb
	.byte 0xa9, 0x0e, 0xef, 0x6a, 0x3e, 0xf1, 0x93, 0xe1
	.byte 0x60, 0xb0, 0x00, 0xf0, 0xe1, 0x93, 0xe1, 0x20
	.byte 0xb8, 0x01, 0x00, 0x50, 0xe1, 0x93, 0xe1, 0x20
	.byte 0xb8, 0x02, 0x00, 0x2c, 0xe1, 0x93, 0xe1, 0x20
	.byte 0xb8, 0x03, 0x00, 0x04, 0xe1, 0x93, 0xe1, 0x20
	.byte 0xb8, 0x04, 0x00, 0x00, 0xe1, 0x93, 0xe1, 0x20
	.byte 0xb8, 0x05, 0x00, 0x11, 0xe1, 0x93, 0xe1, 0x20
	.byte 0x1e, 0x84, 0xfa, 0xbf, 0x04, 0x53, 0x9f, 0x04
	.byte 0x20, 0xe8, 0x13, 0xe8, 0x80, 0xe1, 0x93, 0xe1
	.byte 0x21, 0xe8, 0x81, 0xe9, 0xc8, 0x0c, 0x00, 0x00
	.byte 0x00, 0xe9, 0x8e, 0xee, 0x61, 0xb1, 0x00, 0x00
	.byte 0xe1, 0x93, 0xe1, 0x20, 0x9f, 0x04, 0x21, 0xd9
	.byte 0x81, 0xd9, 0xc8, 0x0d, 0x00, 0x1d, 0xe7, 0x72
	.byte 0xfd, 0xf5, 0xf8, 0x47, 0xb6, 0x00, 0xf7, 0xe1
	.byte 0x93, 0xe1, 0x20, 0x9f, 0x04, 0x21, 0xd9, 0x81
	.byte 0xd9, 0xc8, 0x0f, 0x00, 0x1d, 0x06, 0x73, 0xfd
	.byte 0x5e, 0xef, 0x62, 0x0e, 0xef, 0x6c, 0x3e, 0xe8
	.byte 0x8e, 0xee, 0x88, 0x1e, 0x31, 0xfa, 0xbf, 0x06
	.byte 0x53, 0xee, 0x88, 0x1e, 0x52, 0xfa, 0x9f, 0x06
	.byte 0x21, 0xe9, 0x13, 0x9f, 0x06, 0x3f, 0x00, 0x00
	.byte 0x66, 0x71, 0x9f, 0x06, 0x3f, 0x78, 0x00, 0x62
	.byte 0x6a, 0xeb, 0xe3, 0x66, 0x66, 0xeb, 0x88, 0xe8
	.byte 0xed, 0x0f, 0xe8, 0xed, 0x00, 0xe8, 0xcc, 0xff
	.byte 0x3f, 0x00, 0x00, 0xeb, 0x80, 0xe8, 0xcc, 0x00
	.byte 0xc0, 0xff, 0xff, 0xe8, 0xa3, 0x8b, 0x10, 0x25
	.byte 0xcd, 0xcc, 0xc0, 0xcd, 0xcf, 0xc0, 0x66, 0x48
	.byte 0xe9, 0x83, 0xcd, 0xcf, 0x80, 0x66, 0x1e, 0xcd
	.byte 0xcf, 0x40, 0x66, 0x3c, 0xcd, 0xd8, 0x6e, 0x38
	.byte 0xeb, 0xcf, 0xd6, 0x01, 0x00, 0x00, 0x6b, 0x2b
	.byte 0xf1, 0x93, 0xe1, 0x66, 0xd8, 0xab, 0x9f, 0x06
	.byte 0x21, 0xee, 0x8a, 0x68, 0x13, 0xeb, 0xcf, 0x27
	.byte 0x29, 0x00, 0x00, 0x6b, 0x16, 0xf1, 0x93, 0xe1
	.byte 0x66, 0xd8, 0xab, 0x9f, 0x06, 0x21, 0xee, 0x8a
	.byte 0x1d, 0xf4, 0x32, 0xef, 0xbf, 0x04, 0x02, 0x00
	.byte 0x00, 0x68, 0x05, 0xbf, 0x04, 0x02, 0x01, 0x00
	.byte 0x9f, 0x04, 0x23, 0x5e, 0xef, 0x64, 0x0e

LABEL_FEF252:
	ldada xde, 58040
	ld (xde), 0x2B
	ld (xde + 1), 0x30
	ld (xde + 2), 0x7F
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
	ldw bc, 0xA
	call sendCOMM
	ldda8 l, 58047
	ret

LABEL_FEF293:
	ldada xde, 58050
	ld (xde), 0x2B
	ld (xde + 1), 0x30
	ld (xde + 2), 0x7F
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
	ldw bc, 0xA
	call sendCOMM
	ldda8 l, 58057
	ret

LABEL_FEF2D4:
	ldada xde, 58060
	ld (xde), 0x2B
	ld (xde + 1), 0x30
	ld (xde + 2), 0x7F
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
	ldw bc, 0xA
	call sendCOMM
	ldda8 l, 58067
	ret

LABEL_FEF315:
	ldada xde, 58070
	ld (xde), 0x2B
	ld (xde + 1), 0x30
	ld (xde + 2), 0x7F
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
	ldw bc, 0xA
	call sendCOMM
	ldda8 l, 58077
	ret

LABEL_FEF356:
	cps wa, 4
	jrl ugt, LABEL_FEF3DD
	ldada xde, 58080
	ld (xde), 0x2D
	ld (xde + 1), 0x0
	ld (xde + 3), 0x0
	ld (xde + 4), 0x0
	ld (xde + 5), 0x0
	lda xhl, (xde + 6)
	ld (xhl), 0x38
	ld (xde + 7), c
	lda xbc, (xde + 2)
	cps wa, 4
	jr z, LABEL_FEF3A6
	cps wa, 3
	jr z, LABEL_FEF3A1
	cps wa, 2
	jr z, LABEL_FEF39C
	cps wa, 1
	jr z, LABEL_FEF397
	cps wa, 0
	jr nz, LABEL_FEF3AB
	ld (xbc), 0xA
	jr CommPacket_WriteMeasureCount

LABEL_FEF397:
	ld (xbc), 0xB
	jr CommPacket_WriteMeasureCount

LABEL_FEF39C:
	ld (xbc), 0xC
	jr CommPacket_WriteMeasureCount

LABEL_FEF3A1:
	ld (xbc), 0xD
	jr CommPacket_WriteMeasureCount

LABEL_FEF3A6:
	ld (xbc), 0xE
	jr CommPacket_WriteMeasureCount

LABEL_FEF3AB:
	ld (xhl), 0x0

CommPacket_WriteMeasureCount:
	ld c, (xhl)
	cps c, 0
	jr z, LABEL_FEF3DD
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	ld xiy, 0x3C0FA
	add xiy, xbc
	lda xix, (xde + 8)
	ldw bc, 0x1C
	ldirw
	ld c, (xhl)
	inc 8, c
	extz bc
	lds wa, 3
	call sendCOMM

LABEL_FEF3DD:
	incdi8 1, 57751
	ldda8 l, 57751
	res 7, l
	ret

SendCOMM_VariableLengthPacket:
	push xiz
	ldada xhl, 58144
	ld (xhl), 0x2C
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
	ldi_werp 0xE6, 0
	ldfr_berp E, 0xF0
	extz ix
	cps ix, 0
	jr ule, LABEL_FEF43E
	ld xiy, xwa
	ldw bc, 0x8

LABEL_FEF428:
	ld iz, bc
	extz xiz
	add xiz, xhl
	ld a, (xiy)
	ld (xiz), a
	inc1_werp 0xE6
	inc 1, bc
	ldto_werp WA, 0xE6
	cp wa, ix
	jr c, LABEL_FEF428

LABEL_FEF43E:
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
	ld (xde), 0x2C
	ld (xde + 1), 0x30
	ld (xde + 2), 0x7F
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
	ldw bc, 0xA
	jp sendCOMM

LABEL_FEF491:
	ldada xde, 58174
	ld (xde), 0x2C
	ld (xde + 1), 0x30
	ld (xde + 2), 0x7F
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
	ldw bc, 0xA
	jp sendCOMM

LABEL_FEF4CD:
	ldada xde, 58184
	ld (xde), 0x2C
	ld (xde + 1), 0x30
	ld (xde + 2), 0x7F
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

LABEL_FEF507:
	dec 6, xsp
	push xiz
	ld (xsp + 8), wa
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, 0xEED520
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
	call LABEL_FEF893
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	ld xwa, 0x3C0FA
	add xwa, xbc
	ldw (xwa + 42), 0x1
	ldw (xwa + 2), 0x0
	ld wa, (xsp + 4)
	sll wa, 8
	extz xwa
	add xwa, 0x4904
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xFA
	ld wa, (xsp + 8)
	ldto_werp BC, 0xFA
	call LABEL_FEF8F5
	lds iz, 0
	cpi_werp 0xFA, 0
	jr ule, LABEL_FEF5AE

LABEL_FEF584:
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
	call LABEL_FEF8BC
	inc 1, iz
	cp_werp IZ, 0xFA
	jr c, LABEL_FEF584

LABEL_FEF5AE:
	cpw (xsp + 8), 0x0
	jr nz, LABEL_FEF5CF
	cpw (xsp + 6), 0x35
	jr z, LABEL_FEF5C3
	cpw (xsp + 6), 0xF
	jr nz, LABEL_FEF5CF

LABEL_FEF5C3:
	ld wa, (xsp + 8)
	ldw bc, 0xF
	lds de, 0
	call LABEL_FEF8BC

LABEL_FEF5CF:
	ld wa, (xsp + 4)
	sll wa, 8
	extz xwa
	add xwa, 0x4906
	call DSPCfg_ReadParam_Map0
	ld bc, hl
	ld wa, (xsp + 8)
	call LABEL_FEF918
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	ld xwa, 0x3C0FA
	add xwa, xbc
	ldw (xwa + 46), 0x1
	ldw (xwa + 40), 0x0
	ldw (xwa + 48), 0x63
	ldw (xwa + 50), 0x0
	ldw (xwa + 52), 0x0
	lda xbc, (xwa + 54)
	cpw (xsp + 8), 0x4
	jr z, LABEL_FEF669
	cpw (xsp + 8), 0x3
	jr z, LABEL_FEF65F
	cpw (xsp + 8), 0x2
	jr z, LABEL_FEF655
	cpw (xsp + 8), 0x1
	jr z, LABEL_FEF64B
	cpw (xsp + 8), 0x0
	jr nz, CommParam_SetComplete_Return
	ldda8 a, 58198
	extz wa
	ld (xbc), wa
	jr CommParam_SetComplete_Return

LABEL_FEF64B:
	ldda8 a, 58199
	extz wa
	ld (xbc), wa
	jr CommParam_SetComplete_Return

LABEL_FEF655:
	ldda8 a, 58200
	extz wa
	ld (xbc), wa
	jr CommParam_SetComplete_Return

LABEL_FEF65F:
	ldda8 a, 58201
	extz wa
	ld (xbc), wa
	jr CommParam_SetComplete_Return

LABEL_FEF669:
	ldda8 a, 58202
	extz wa
	ld (xbc), wa

CommParam_SetComplete_Return:
	pop xiz
	inc 6, xsp
	ret

LABEL_FEF675:
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

LABEL_FEF6AD:
	jr LABEL_FEF675

LABEL_FEF6AF:
	ret

LABEL_FEF6B0:
	ret

CommPort_StatusCheckAndSend:
	ldcf_dd8 4, 0x38
	scc8 c, a
	cpda8 a, 58204
	ret z
	ldcf_dd8 4, 0x38
	scc8 c, a
	stda8 58204, a
	ld xwa, 0xE35C
	ldw bc, 0x8
	lds de, 1
	call SendCOMM_VariableLengthPacket
	ret

LABEL_FEF6D4:
	cp a, c
	jr nz, LABEL_FEF6F9
	ldda16 xwa, 36152
	cp a, 0xD6
	jr z, Note_CheckValidityReturn
	cp a, 0xE
	jr z, Note_CheckValidityReturn
	cp a, 0xC
	jr z, Note_CheckValidityReturn
	cp a, 0xB
	jr z, Note_CheckValidityReturn
	cp a, 0xA
	jr nz, LABEL_FEF6F9

Note_CheckValidityReturn:
	ldb l, 0x0
	jr LABEL_FEF6FB

LABEL_FEF6F9:
	ldb l, 0xFF

LABEL_FEF6FB:
	ret

COMM_SendPartDataBlock:
	dec 2, xsp
	push_werp 0xFA
	ld (xsp + 2), a
	cp (xsp + 2), 0x4
	jr ugt, LABEL_FEF768
	ld e, (xsp + 2)
	ld a, e
	extz wa
	muls wa, 0x38
	inc 8, wa
	lda_24 xbc, 0x03c0fa
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	ldfr_berp A, 0xFB
	ld a, e
	extz wa
	calr LABEL_FEF507
	ldto_berp A, 0xFB
	extz wa
	ld c, (xsp + 2)
	extz bc
	muls bc, 0x38
	inc 8, bc
	lda_24 xde, 0x03c0fa
	ld_sriw3 BC, 0x07, 0xE8, 0xE4
	extz bc
	calr LABEL_FEF6D4
	cp (xsp + 2), 0x3
	jr nz, LABEL_FEF75B
	ldda8 a, 58196
	extz wa
	st16_24 0x03c1b6, xwa

LABEL_FEF75B:
	ld a, (xsp + 2)
	extz wa
	extz hl
	ld bc, hl
	call LABEL_FEF356

LABEL_FEF768:
	pop_werp 0xFA
	inc 2, xsp
	ret

LABEL_FEF76E:
	; --- Set-if-changed handlers for E351-E354 (4x24 = 96 bytes) ---
	cpdm8	58193, a
	ret z
	stda8	58193, a
	ld xwa, 0x0000E351
	lds	bc, 1
	lds	de, 1
	call SendCOMM_VariableLengthPacket
	ret
LABEL_FEF786:
	cpdm8	58194, a
	ret z
	stda8	58194, a
	ld xwa, 0x0000E352
	lds	bc, 2
	lds	de, 1
	call SendCOMM_VariableLengthPacket
	ret
LABEL_FEF79E:
	cpdm8	58195, a
	ret z
	stda8	58195, a
	ld xwa, 0x0000E353
	lds	bc, 6
	lds	de, 1
	call SendCOMM_VariableLengthPacket
	ret
LABEL_FEF7B6:
	cpdm8	58196, a
	ret z
	stda8	58196, a
	ld xwa, 0x0000E354
	lds	bc, 7
	lds	de, 1
	call SendCOMM_VariableLengthPacket
	ret


LABEL_FEF7CE:
	ldb c, 0x0
	cps a, 0
	jr z, LABEL_FEF7D6
	ldb c, 0x1

LABEL_FEF7D6:
	cpdm8 58199, c
	ret z
	stda8 58199, c
	ld xwa, 0xE357
	ldw bc, 0x21
	lds de, 1
	call SendCOMM_VariableLengthPacket
	ret

LABEL_FEF7EF:
	ldb c, 0x0
	cps a, 0
	jr z, LABEL_FEF7F7
	ldb c, 0x1

LABEL_FEF7F7:
	cpdm8 58200, c
	ret z
	stda8 58200, c
	ld xwa, 0xE358
	ldw bc, 0x22
	lds de, 1
	call SendCOMM_VariableLengthPacket
	ret

LABEL_FEF810:
	cpdm8 58203, a
	ret z
	ldb c, 0x1
	cps a, 0
	jr nz, LABEL_FEF81E
	ldb c, 0x0

LABEL_FEF81E:
	stda8 58203, c
	ld xwa, 0xE35B
	ldw bc, 0x23
	lds de, 1
	call SendCOMM_VariableLengthPacket
	ret

LABEL_FEF831:
	ldb c, 0x0
	cps a, 0
	jr z, LABEL_FEF839
	ldb c, 0x1

LABEL_FEF839:
	cpdm8 58201, c
	ret z
	stda8 58201, c
	ld xwa, 0xE359
	ldw bc, 0x24
	lds de, 1
	call SendCOMM_VariableLengthPacket
	ret

LABEL_FEF852:
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
	call	16708585
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
	.byte 0x0e

LABEL_FEF893:
	lds hl, 0
	cps wa, 5
	jr nc, LABEL_FEF8B8
	cp bc, 0x63
	jr ugt, LABEL_FEF8B8
	extz xwa
	ld xde, xwa
	sll xde, 3
	sub xde, xwa
	sll xde, 3
	inc 8, xde
	ld xwa, 0x3C0FA
	add xwa, xde
	ld (xwa), bc
	jr LABEL_FEF8BB

LABEL_FEF8B8:
	ldw hl, 0xFFFF

LABEL_FEF8BB:
	ret

LABEL_FEF8BC:
	push xiz
	lds hl, 0
	cps wa, 5
	jr nc, LABEL_FEF8F0
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
	jr nc, LABEL_FEF8F0
	extz xbc
	add xbc, xbc
	add xwa, xbc
	add xix, xwa
	ld (xix + 12), de
	jr LABEL_FEF8F3

LABEL_FEF8F0:
	ldw hl, 0xFFFF

LABEL_FEF8F3:
	pop xiz
	ret

LABEL_FEF8F5:
	lds hl, 0
	cps wa, 5
	jr nc, LABEL_FEF914
	extz xwa
	ld xde, xwa
	sll xde, 3
	sub xde, xwa
	sll xde, 3
	inc 8, xde
	lda_24 xwa, 0x03c126
	add xwa, xde
	ld (xwa), bc
	jr LABEL_FEF917

LABEL_FEF914:
	ldw hl, 0xFFFF

LABEL_FEF917:
	ret

LABEL_FEF918:
	lds hl, 0
	cps wa, 5
	jr nc, LABEL_FEF937
	extz xwa
	ld xde, xwa
	sll xde, 3
	sub xde, xwa
	sll xde, 3
	inc 8, xde
	lda_24 xwa, 0x03c120
	add xwa, xde
	ld (xwa), bc
	jr LABEL_FEF93A

LABEL_FEF937:
	ldw hl, 0xFFFF

LABEL_FEF93A:
	ret

LABEL_FEF93B:
	ldw bc, 0x24B8
	lda_24 xwa, 0x1e0010
	lds de, 0

LABEL_FEF945:
	add_spiw DE, 0xE1
	djnz xbc, LABEL_FEF945
	cpl de
	ld hl, de
	ret

LABEL_FEF950:
	ldb w, 0x0
	lda_24 xde, 0x1e0000
	lda_24 xhl, 0xeed56c

LABEL_FEF95C:
	ld c, w
	extz bc
	ld_srib3 A, 0x07, 0xEC, 0xE4
	cp_srib_rm A, 0x07, 0xE8, 0xE4
	jr nz, LABEL_FEF973
	inc 1, w
	cp w, 0x10
	jr c, LABEL_FEF95C

LABEL_FEF973:
	cp w, 0x10
	jr nz, LABEL_FEF993
	calr LABEL_FEF93B
	lda_24 xwa, 0x1e0000
	cp_sriw_mr HL, 0xE1, 0xA8, 0x72
	jr nz, LABEL_FEF993
	ldw bc, 0x72AA
	ld xde, 0x7800
	jp InterCPU_E1_Bulk_Transfer

LABEL_FEF993:
	ldw wa, 0xFF
	ldw bc, 0xFF
	jp COMM_BuildAndSendPacket

LABEL_FEF99D:
	ret

LABEL_FEF99E:
	call SubCPU_Payload_GetErrorFlag
	cp hl, 0xFFFF
	ret nz
	ldw wa, 0xFF
	ldw bc, 0xFF
	call COMM_BuildAndSendPacket
	ret

LABEL_FEF9B3:
	ret

LABEL_FEF9B4:
	.byte 0xbf, 0xf6, 0x37, 0x3e, 0xbf, 0x0a, 0x61, 0xe8
	.byte 0x8e, 0xee, 0x88, 0x1e, 0x66, 0x03, 0xaf, 0x0a
	.byte 0x22, 0xea, 0x8d, 0xee, 0x8c, 0x31, 0x08, 0x00
	.byte 0x95, 0x11, 0x8a, 0x10, 0x21, 0xbe, 0x10, 0x41
	.byte 0xea, 0x89, 0x89, 0x11, 0x21, 0xbe, 0x11, 0x41
	.byte 0x89, 0x12, 0x21, 0xbe, 0x12, 0x41, 0x89, 0x13
	.byte 0x21, 0xbe, 0x13, 0x41, 0x89, 0x14, 0x21, 0xbe
	.byte 0x18, 0x41, 0x89, 0x15, 0x21, 0xbe, 0x19, 0x41
	.byte 0x89, 0x16, 0x21, 0xbe, 0x24, 0x41, 0x89, 0x17
	.byte 0x21, 0xbe, 0x25, 0x41, 0x89, 0x18, 0x21, 0xbe
	.byte 0x29, 0x41, 0x89, 0x19, 0x21, 0xbe, 0x2a, 0x41
	.byte 0x89, 0x1a, 0x21, 0xbe, 0x2b, 0x41, 0x89, 0x1b
	.byte 0x21, 0xbe, 0x2c, 0x41, 0x89, 0x1c, 0x21, 0xbe
	.byte 0x2d, 0x41, 0x89, 0x1d, 0x21, 0xbe, 0x2e, 0x41
	.byte 0x89, 0x1f, 0x21, 0xbe, 0x5c, 0x41, 0x89, 0x20
	.byte 0x21, 0xbe, 0x5d, 0x41, 0xc7, 0xe6, 0xa8, 0xd9
	.byte 0xa8, 0xd9, 0x8b, 0xdb, 0xc8, 0x5e, 0x00, 0xd9
	.byte 0x8a, 0xda, 0xc8, 0x21, 0x00, 0xaf, 0x0a, 0x20
	.byte 0xc3, 0x07, 0xe0, 0xe8, 0x21, 0xf3, 0x07, 0xf8
	.byte 0xec, 0x41, 0xc7, 0xe6, 0x61, 0xd9, 0x61, 0xc7
	.byte 0xe6, 0xcf, 0x08, 0x67, 0xdc, 0xbf, 0x04, 0x00
	.byte 0x00, 0xbf, 0x08, 0x02, 0x00, 0x00, 0xbf, 0x06
	.byte 0x02, 0x00, 0x00, 0x9f, 0x06, 0x20, 0xd8, 0xc8
	.byte 0x66, 0x00, 0xf3, 0x07, 0xf8, 0xe0, 0x31, 0x9f
	.byte 0x08, 0x22, 0xda, 0xc8, 0x29, 0x00, 0xaf, 0x0a
	.byte 0x20, 0xea, 0x13, 0xe8, 0x82, 0x82, 0x21, 0xb9
	.byte 0x01, 0x41, 0x8a, 0x01, 0x21, 0xb9, 0x02, 0x41
	.byte 0xb9, 0x03, 0x33, 0x8a, 0x02, 0x21, 0xb3, 0x41
	.byte 0xc9, 0xcc, 0xcf, 0xb3, 0x41, 0x8a, 0x03, 0x21
	.byte 0xb9, 0x04, 0x41, 0x8a, 0x04, 0x21, 0xb9, 0x05
	.byte 0x41, 0x8a, 0x05, 0x21, 0xb9, 0x06, 0x41, 0xb9
	.byte 0x07, 0x00, 0x32, 0x8a, 0x06, 0x21, 0xb9, 0x08
	.byte 0x41, 0x8a, 0x07, 0x21, 0xb9, 0x09, 0x41, 0x8a
	.byte 0x08, 0x21, 0xb9, 0x0a, 0x41, 0x8a, 0x09, 0x21
	.byte 0xb9, 0x0b, 0x41, 0x8a, 0x0a, 0x21, 0xb9, 0x17
	.byte 0x41, 0x8a, 0x0b, 0x21, 0xb9, 0x18, 0x41, 0xba
	.byte 0x0c, 0x33, 0x83, 0x21, 0xb9, 0x19, 0x41, 0xb1
	.byte 0xb7, 0x83, 0x21, 0xc9, 0xcc, 0x10, 0xc9, 0xcf
	.byte 0x10, 0x6e, 0x02, 0xb1, 0xbf, 0x8a, 0x0d, 0x21
	.byte 0xb9, 0x1a, 0x41, 0x8a, 0x0e, 0x21, 0xb9, 0x1b
	.byte 0x41, 0x8a, 0x0f, 0x21, 0xb9, 0x1c, 0x41, 0x8a
	.byte 0x10, 0x21, 0xb9, 0x1d, 0x41, 0x8a, 0x11, 0x21
	.byte 0xb9, 0x1e, 0x41, 0x8a, 0x12, 0x21, 0xb9, 0x1f
	.byte 0x41, 0x8a, 0x13, 0x21, 0xb9, 0x20, 0x41, 0x8a
	.byte 0x14, 0x21, 0xb9, 0x21, 0x41, 0x8a, 0x15, 0x21
	.byte 0xb9, 0x22, 0x41, 0x8a, 0x16, 0x21, 0xb9, 0x23
	.byte 0x41, 0x8a, 0x17, 0x21, 0xb9, 0x24, 0x41, 0x8a
	.byte 0x18, 0x21, 0xb9, 0x25, 0x41, 0x8a, 0x19, 0x21
	.byte 0xb9, 0x27, 0x41, 0x8a, 0x1a, 0x21, 0xb9, 0x29
	.byte 0x41, 0x8a, 0x1b, 0x21, 0xb9, 0x2a, 0x41, 0x8a
	.byte 0x1c, 0x21, 0xb9, 0x2b, 0x41, 0x8a, 0x1d, 0x21
	.byte 0xb9, 0x2c, 0x41, 0x8a, 0x1e, 0x21, 0xb9, 0x2d
	.byte 0x41, 0x8a, 0x1f, 0x21, 0xb9, 0x2e, 0x41, 0x8a
	.byte 0x20, 0x21, 0xb9, 0x2f, 0x41, 0x8a, 0x21, 0x21
	.byte 0xb9, 0x30, 0x41, 0x8a, 0x22, 0x21, 0xb9, 0x31
	.byte 0x41, 0x8a, 0x23, 0x21, 0xb9, 0x32, 0x41, 0x8a
	.byte 0x24, 0x21, 0xb9, 0x33, 0x41, 0x8a, 0x25, 0x21
	.byte 0xb9, 0x34, 0x41, 0x8a, 0x26, 0x21, 0xb9, 0x35
	.byte 0x41, 0x8a, 0x27, 0x21, 0xb9, 0x36, 0x41, 0x8a
	.byte 0x28, 0x21, 0xb9, 0x37, 0x41, 0x8a, 0x2a, 0x21
	.byte 0xb9, 0x39, 0x41, 0x8a, 0x2b, 0x21, 0xb9, 0x3a
	.byte 0x41, 0x8a, 0x2c, 0x21, 0xb9, 0x3b, 0x41, 0x8a
	.byte 0x2d, 0x21, 0xb9, 0x3c, 0x41, 0x8a, 0x29, 0x21
	.byte 0xb9, 0x4d, 0x41, 0x8a, 0x2e, 0x21, 0xb9, 0x3d
	.byte 0x41, 0x8a, 0x2f, 0x21, 0xb9, 0x3e, 0x41, 0x8a
	.byte 0x30, 0x21, 0xb9, 0x3f, 0x41, 0x8a, 0x31, 0x21
	.byte 0xb9, 0x40, 0x41, 0x8a, 0x32, 0x21, 0xb9, 0x41
	.byte 0x41, 0x8a, 0x33, 0x21, 0xb9, 0x42, 0x41, 0x8a
	.byte 0x34, 0x21, 0xb9, 0x43, 0x41, 0x8a, 0x35, 0x21
	.byte 0xb9, 0x44, 0x41, 0x8a, 0x36, 0x21, 0xb9, 0x45
	.byte 0x41, 0x8a, 0x37, 0x21, 0xb9, 0x46, 0x41, 0x8a
	.byte 0x38, 0x21, 0xb9, 0x47, 0x41, 0x8a, 0x39, 0x21
	.byte 0xb9, 0x48, 0x41, 0x8a, 0x3a, 0x21, 0xb9, 0x49
	.byte 0x41, 0x8a, 0x3b, 0x21, 0xb9, 0x4a, 0x41, 0x8a
	.byte 0x3c, 0x21, 0xb9, 0x4b, 0x41, 0x8a, 0x3d, 0x21
	.byte 0xb9, 0x4c, 0x41, 0x8f, 0x04, 0x61, 0x9f, 0x06
	.byte 0x38, 0x51, 0x00, 0x9f, 0x08, 0x38, 0x3e, 0x00
	.byte 0x8f, 0x04, 0x3f, 0x04, 0x77, 0x44, 0xfe, 0x5e
	.byte 0xbf, 0x0a, 0x37, 0x0e, 0xb8, 0x10, 0x33, 0x83
	.byte 0x25, 0xcd, 0xcc, 0xb7, 0xb3, 0x45, 0xb8, 0x11
	.byte 0x31, 0xb1, 0xcf, 0x66, 0x05, 0xcd, 0x31, 0x06
	.byte 0xb3, 0x45, 0xb1, 0xc9, 0x66, 0x02, 0xb3, 0xbb
	.byte 0x88, 0x12, 0x23, 0xcb, 0xcc, 0xf0, 0xc7, 0xf0
	.byte 0x9b, 0xcb, 0xef, 0x04, 0xd9, 0x12, 0xf2, 0x8d
	.byte 0xd5, 0xee, 0x33, 0xc3, 0x07, 0xec, 0xe4, 0x23
	.byte 0xc7, 0xf0, 0x9b, 0xc7, 0xf0, 0x8c, 0xcc, 0xee
	.byte 0x06, 0x88, 0x13, 0x25, 0xcd, 0x8b, 0xcb, 0xcc
	.byte 0xf0, 0xc7, 0xf0, 0x9b, 0xcb, 0xef, 0x04, 0xd9
	.byte 0x12, 0xc3, 0x07, 0xec, 0xe4, 0x23, 0xc7, 0xf0
	.byte 0x9b, 0xcb, 0xee, 0x04, 0xcb, 0xe4, 0xcd, 0xcc
	.byte 0x0f, 0xc7, 0xf0, 0x9d, 0xc7, 0xf0, 0x8b, 0xd9
	.byte 0x12, 0xc3, 0x07, 0xec, 0xe4, 0x23, 0xc7, 0xf0
	.byte 0x9b, 0xcb, 0xee, 0x02, 0xcb, 0xe4, 0xb8, 0x11
	.byte 0x44, 0xb8, 0x14, 0x31, 0xe9, 0x8a, 0xb9, 0x7c
	.byte 0x33, 0x82, 0x23, 0xba, 0xfe, 0x43, 0xea, 0x61
	.byte 0xeb, 0xf2, 0x67, 0xf5, 0xdb, 0xa8, 0xdb, 0x8a
	.byte 0xda, 0xc8, 0x28, 0x00, 0xf3, 0x07, 0xe0, 0xe8
	.byte 0x31, 0x89, 0x11, 0x23, 0xc7, 0xf0, 0x9b, 0xf3
	.byte 0x07, 0xe0, 0xe8, 0x35, 0xf3, 0x07, 0xe0, 0xe8
	.byte 0x31, 0x89, 0x10, 0x23, 0xbd, 0x11, 0x43, 0xf3
	.byte 0x07, 0xe0, 0xe8, 0x35, 0xf3, 0x07, 0xe0, 0xe8
	.byte 0x31, 0x89, 0x0f, 0x23, 0xbd, 0x10, 0x43, 0xf3
	.byte 0x07, 0xe0, 0xe8, 0x35, 0xf3, 0x07, 0xe0, 0xe8
	.byte 0x31, 0x89, 0x0e, 0x23, 0xbd, 0x0f, 0x43, 0xf3
	.byte 0x07, 0xe0, 0xe8, 0x35, 0xf3, 0x07, 0xe0, 0xe8
	.byte 0x31, 0x89, 0x0d, 0x23, 0xbd, 0x0e, 0x43, 0xf3
	.byte 0x07, 0xe0, 0xe8, 0x35, 0xf3, 0x07, 0xe0, 0xe8
	.byte 0x31, 0x89, 0x0c, 0x23, 0xbd, 0x0d, 0x43, 0xea
	.byte 0x13, 0xe8, 0x82, 0xc7, 0xf0, 0x8b, 0xba, 0x0c
	.byte 0x43, 0xdb, 0xc8, 0x22, 0x00, 0xdb, 0xcf, 0x66
	.byte 0x00, 0x61, 0x8b, 0x0e, 0xf3, 0xfd, 0x56, 0xfe
	.byte 0x37, 0xe8, 0x8a, 0x45, 0x9d, 0xd5, 0xee, 0x00
	.byte 0xef, 0x8c, 0x31, 0xd5, 0x00, 0x95, 0x11, 0xef
	.byte 0x8d, 0xea, 0x8c, 0x31, 0xd5, 0x00, 0x95, 0x11
	.byte 0xba, 0x66, 0x30, 0xe8, 0x8d, 0xf3, 0xe9, 0xb7
	.byte 0x00, 0x34, 0x31, 0x28, 0x00, 0x95, 0x11, 0x85
	.byte 0x10, 0xe8, 0x8d, 0xf3, 0xe9, 0x08, 0x01, 0x34
	.byte 0x31, 0x28, 0x00, 0x95, 0x11, 0x85, 0x10, 0xe8
	.byte 0x8d, 0xf3, 0xe9, 0x59, 0x01, 0x34, 0x31, 0x28
	.byte 0x00, 0x95, 0x11, 0x85, 0x10, 0xf3, 0xfd, 0xaa
	.byte 0x01, 0x37, 0x0e, 0xbf, 0xe6, 0x37, 0x3e, 0xbf
	.byte 0x16, 0x61, 0xbf, 0x1a, 0x60, 0xaf, 0x1a, 0x20
	.byte 0x1e, 0xa1, 0xff, 0xaf, 0x1a, 0x22, 0xba, 0x10
	.byte 0x33, 0xaf, 0x16, 0x20, 0xe8, 0x8d, 0xea, 0x8c
	.byte 0x31, 0x08, 0x00, 0x95, 0x11, 0xb8, 0x10, 0x30
	.byte 0xb0, 0xcf, 0x66, 0x04, 0xb3, 0xbd, 0x68, 0x02
	.byte 0xb3, 0xb5, 0xb0, 0xca, 0x66, 0x04, 0xb3, 0xbc
	.byte 0x68, 0x02, 0xb3, 0xb4, 0xaf, 0x1a, 0x23, 0xbb
	.byte 0x29, 0x30, 0xbf, 0x0e, 0x60, 0x80, 0x3c, 0xf0
	.byte 0xbb, 0x2a, 0x30, 0xbf, 0x0a, 0x60, 0xb0, 0x00
	.byte 0x00, 0xaf, 0x16, 0x24, 0xbc, 0x11, 0x30, 0xbf
	.byte 0x12, 0x60, 0x80, 0x21, 0xc9, 0xcc, 0xc0, 0xc9
	.byte 0xef, 0x06, 0xc9, 0x67, 0xc9, 0x8b, 0xaf, 0x0e
	.byte 0x20, 0x80, 0xeb, 0xaf, 0x12, 0x25, 0x85, 0x21
	.byte 0xc9, 0xcc, 0x30, 0xc9, 0xef, 0x04, 0xc9, 0x67
	.byte 0xc9, 0xee, 0x04, 0xc9, 0x8d, 0xaf, 0x0a, 0x20
	.byte 0x80, 0x23, 0xcd, 0xe3, 0xaf, 0x0a, 0x22, 0xb2
	.byte 0x43, 0x85, 0x21, 0xc9, 0xcc, 0x0c, 0xc9, 0xef
	.byte 0x02, 0xc9, 0x67, 0xc9, 0xe3, 0xb2, 0x43, 0x8c
	.byte 0x12, 0x21, 0xc9, 0x08, 0x7f, 0xd8, 0x12, 0xc9
	.byte 0x0a, 0x1e, 0xc9, 0x8b, 0xbb, 0x3b, 0x43, 0xec
	.byte 0x8a, 0x8a, 0x13, 0x21, 0xbb, 0x2b, 0x41, 0xba
	.byte 0x14, 0x30, 0xbf, 0x12, 0x60, 0xeb, 0x89, 0xb9
	.byte 0x2c, 0x30, 0xbf, 0x0e, 0x60, 0xb9, 0x3c, 0x30
	.byte 0xbf, 0x0a, 0x60, 0xaf, 0x12, 0x20, 0x80, 0x23
	.byte 0xcb, 0xcf, 0x09, 0x6f, 0x0b, 0xcb, 0x65, 0xaf
	.byte 0x0a, 0x20, 0xb0, 0x43, 0x23, 0x05, 0x68, 0x2f
	.byte 0xcb, 0xcf, 0x18, 0x6f, 0x20, 0xcb, 0x89, 0xcb
	.byte 0x81, 0xc9, 0x6c, 0xc9, 0x8b, 0xaf, 0x0a, 0x20
	.byte 0xb0, 0x43, 0xaf, 0x12, 0x20, 0x80, 0x21, 0xc9
	.byte 0xee, 0x01, 0xc9, 0x6c, 0xc9, 0x8b, 0xaf, 0x0e
	.byte 0x20, 0xb0, 0x43, 0x68, 0x18, 0xcb, 0xc8, 0x13
	.byte 0xaf, 0x0a, 0x20, 0xb0, 0x43, 0x23, 0x13, 0xaf
	.byte 0x12, 0x20, 0x80, 0x21, 0xcb, 0x81, 0xc9, 0x8b
	.byte 0xaf, 0x0e, 0x20, 0xb0, 0x43, 0xaf, 0x16, 0x24
	.byte 0xbc, 0x15, 0x32, 0x82, 0x23, 0xaf, 0x1a, 0x23
	.byte 0xbb, 0x3e, 0x43, 0x82, 0x23, 0xbb, 0x2e, 0x43
	.byte 0x8c, 0x1e, 0x23, 0xcb, 0xee, 0x03, 0xbb, 0x5c
	.byte 0x43, 0xec, 0x88, 0xb8, 0x1f, 0x30, 0xbf, 0x06
	.byte 0x60, 0xeb, 0x8a, 0x80, 0x21, 0xba, 0x5d, 0x41
	.byte 0xbf, 0x04, 0x00, 0x00, 0xda, 0xa8, 0xda, 0x8c
	.byte 0xdc, 0xc8, 0x5e, 0x00, 0xda, 0x8b, 0xdb, 0xc8
	.byte 0x20, 0x00, 0xaf, 0x16, 0x20, 0xaf, 0x1a, 0x21
	.byte 0xc3, 0x07, 0xe0, 0xec, 0x21, 0xf3, 0x07, 0xe4
	.byte 0xf0, 0x41, 0x8f, 0x04, 0x61, 0xda, 0x61, 0x8f
	.byte 0x04, 0x3f, 0x08, 0x67, 0xd9, 0xaf, 0x06, 0x20
	.byte 0x80, 0x21, 0xc9, 0xcc, 0x0f, 0xc9, 0xcf, 0x0a
	.byte 0x66, 0x05, 0xc9, 0xcf, 0x0b, 0x6e, 0x43, 0xaf
	.byte 0x1a, 0x20, 0xb8, 0x60, 0x30, 0xbf, 0x12, 0x60
	.byte 0xaf, 0x16, 0x20, 0x88
	.ascii "\"?2c"
	.byte 0x06, 0xaf, 0x12, 0x20, 0xb0, 0x00, 0x32, 0xaf
	.byte 0x06, 0x20, 0xb0, 0xcf, 0x66, 0x24, 0xaf, 0x16
	.byte 0x23, 0xbb, 0x1c, 0x32, 0x82, 0x21, 0xc9, 0x33
	.byte 0x06, 0x66, 0x17, 0xaf, 0x1a, 0x21, 0xb9, 0x5e
	.byte 0x00, 0x01, 0x8b, 0x1d, 0x21, 0xb9, 0x5f, 0x41
	.byte 0x82, 0x23, 0xcb, 0xcc, 0x3f, 0xaf, 0x12, 0x20
	.byte 0xb0, 0x43, 0xaf, 0x1a, 0x21, 0xb9, 0x11, 0x30
	.byte 0xbf, 0x0a, 0x60, 0x80, 0x3c, 0xaa, 0xb9, 0x66
	.byte 0x31, 0xaf, 0x16, 0x20, 0xb8, 0x28, 0x32, 0xbf
	.byte 0x04, 0x00, 0x00, 0xb2, 0xcf, 0x66, 0x25, 0x8f
	.byte 0x04, 0x3f, 0x00, 0x6e, 0x07, 0xaf, 0x0a, 0x20
	.byte 0xb0, 0xb8, 0x68, 0x18, 0x8f, 0x04, 0x3f, 0x01
	.byte 0x6e, 0x07, 0xaf, 0x0a, 0x20, 0xb0, 0xba, 0x68
	.byte 0x0b, 0x8f, 0x04, 0x3f, 0x02, 0x6e, 0x05, 0xaf
	.byte 0x0a, 0x20, 0xb0, 0xbc, 0xb9, 0x06, 0x30, 0xb0
	.byte 0x00, 0x00, 0xb9, 0x26, 0x33, 0xb3, 0x00, 0x00
	.byte 0xb2, 0xce, 0x66, 0x09, 0xb0, 0xbd, 0x83, 0x21
	.byte 0xc9, 0x31, 0x05, 0xb3, 0x41, 0x8a, 0x01, 0x21
	.byte 0xb9, 0x02, 0x41, 0x8a, 0x02, 0x21, 0xb9, 0x03
	.byte 0x41, 0x8a, 0x03, 0x21, 0xb9, 0x04, 0x41, 0x8a
	.byte 0x04, 0x21, 0xb9, 0x05, 0x41, 0x8a, 0x05, 0x21
	.byte 0xb9, 0x17, 0x41, 0x8a, 0x06, 0x21, 0xb9, 0x18
	.byte 0x41, 0x8a, 0x07, 0x21, 0xc9, 0x63, 0xc9, 0xec
	.byte 0x05, 0xb9, 0x19, 0x41, 0x8a, 0x08, 0x21, 0xb9
	.byte 0x1d, 0x41, 0xb9, 0x1b, 0x34, 0x8a, 0x09, 0x21
	.byte 0xb4, 0x41, 0xb9, 0x1c, 0x35, 0x8a, 0x0a, 0x21
	.byte 0xb5, 0x41, 0xb9, 0x1a, 0x33, 0xb3, 0x00, 0x42
	.byte 0x84, 0x21, 0xc9, 0xcf, 0x42, 0x63, 0x02, 0xb3
	.byte 0x41, 0x85, 0x21, 0x83, 0xf9, 0x63, 0x02, 0xb3
	.byte 0x41, 0x8a, 0x0b, 0x21, 0xc9, 0xee, 0x01, 0xb9
	.byte 0x27, 0x41, 0x8a, 0x0c, 0x21, 0xb9, 0x2e, 0x41
	.byte 0xb9, 0x2f, 0x00, 0x00
LABEL_FF0000:
	.byte 0x8a, 0x0d, 0x21, 0xc9
	.byte 0xee, 0x01, 0xb9, 0x29, 0x41, 0x8a, 0x0e, 0x21
	.byte 0xc9, 0xec, 0x01, 0xb9, 0x2a, 0x41, 0x8a, 0x0f
	.byte 0x21, 0xc9, 0xee
LABEL_FF0017:
	.byte 0x01, 0xb9, 0x2b, 0x41, 0x8a
	.byte 0x10, 0x21, 0xc9, 0xec, 0x01, 0xb9, 0x2c, 0x41
	.byte 0x8a, 0x11, 0x21, 0xc9, 0xee, 0x01, 0xb9, 0x2d
	.byte 0x41, 0xba, 0x12, 0x30, 0xbf, 0x12, 0x60, 0x80
	.byte 0x21, 0xb9, 0x33, 0x41, 0xba, 0x15, 0x30, 0xbf
	.byte 0x0e, 0x60, 0x80, 0x21, 0xb9, 0x34, 0x41, 0xba
	.byte 0x18, 0x36, 0x86, 0x21, 0xb9, 0x35, 0x41, 0xb9
	.byte 0x30, 0x33, 0xb3, 0x00, 0x42, 0xb9, 0x31, 0x34
	.byte 0x8a, 0x13, 0x21, 0xb4, 0x41, 0xb9, 0x32, 0x35
	.byte 0x8a, 0x14, 0x21, 0xb5, 0x41, 0xaf, 0x12, 0x20
	.byte 0x80, 0x3f, 0x00, 0x6e, 0x2b, 0xaf, 0x0e, 0x20
	.byte 0x80, 0x3f, 0x00, 0x66, 0x0c, 0x8a, 0x16, 0x21
	.byte 0xb4, 0x41, 0x40, 0x17, 0x00, 0x00, 0x00, 0x68
	.byte 0x0f, 0x86, 0x3f, 0x00, 0x66, 0x12, 0x8a, 0x19
	.byte 0x21, 0xb4, 0x41, 0x40, 0x1a, 0x00, 0x00, 0x00
	.byte 0xea, 0x8e, 0xe8, 0x86, 0x86, 0x21, 0xb5, 0x41
	.byte 0x84, 0x21, 0x83, 0xf9, 0x6f, 0x02, 0xb3, 0x41
	.byte 0x85, 0x21, 0x83, 0xf9, 0x63, 0x02, 0xb3, 0x41
	.byte 0xb9, 0x36, 0x30, 0xbf, 0x12, 0x60, 0x8a, 0x1d
	.byte 0x21, 0xc9, 0x63, 0xc9, 0xec, 0x05, 0xc9, 0x8f
	.byte 0xaf, 0x12, 0x20, 0xb0, 0x47, 0x8a, 0x1e, 0x3f
	.byte 0xff, 0x66, 0x05, 0xcf
LABEL_FF00C0:
	.byte 0x31, 0x00, 0xb0, 0x47
	.byte 0xb9, 0x4d, 0x34, 0x8a, 0x1b, 0x21, 0xb4, 0x41
	.byte 0xaf, 0x06, 0x20, 0x80, 0x27, 0xcf, 0x89, 0xc9
	.byte 0xcc, 0x80, 0xc9, 0xcf, 0x80, 0x6e, 0x0b, 0xcf
	.byte 0xcc, 0x0f, 0xcf, 0xcf, 0x0a, 0x6e, 0x03, 0xb4
	.byte 0x00, 0x7f, 0x8a, 0x1c, 0x21, 0xb9, 0x37, 0x41
	.byte 0x8a, 0x1f, 0x21, 0xb9, 0x3c, 0x41, 0xb9, 0x3a
	.byte 0x34, 0x8a, 0x20, 0x21, 0xb4, 0x41, 0xb9, 0x3b
	.byte 0x35, 0x8a, 0x21
LABEL_FF00FF:
	.byte 0x21, 0xb5, 0x41, 0xb9, 0x39
	.byte 0x33, 0xb3, 0x00, 0x42, 0x84, 0x21, 0xc9, 0xcf
	.byte 0x42, 0x63, 0x02, 0xb3, 0x41, 0x85, 0x21, 0x83
	.byte 0xf9, 0x63, 0x02, 0xb3, 0x41, 0x8f, 0x04, 0x61
	.byte 0xb9, 0x51, 0x31, 0xba, 0x22, 0x32, 0x8f, 0x04
	.byte 0x3f, 0x03, 0x77, 0x26, 0xfe, 0x5e, 0xbf, 0x1a
	.byte 0x37, 0x0e

LABEL_FF012E:
	lds de, 0
	lda_24 xhl, 0xeed56c

LABEL_FF0135:
	ld bc, de
	extz xbc
	ld xiy, xbc
	add xiy, xwa
	ld xix, xhl
	add xix, xbc
	ld c, (xix)
	cp c, (xiy)
	jr nz, LABEL_FF014F
	inc 1, de
	cp de, 0x10
	jr c, LABEL_FF0135

LABEL_FF014F:
	cp de, 0x10
	jr nz, LABEL_FF0158
	ldb l, 0x6
	ret

LABEL_FF0158:
	lds de, 0
	lda_24 xhl, 0xeed55b

LABEL_FF015F:
	ld bc, de
	extz xbc
	ld xiy, xbc
	add xiy, xwa
	ld xix, xhl
	add xix, xbc
	ld c, (xix)
	cp c, (xiy)
	jr nz, LABEL_FF0179
	inc 1, de
	cp de, 0x10
	jr c, LABEL_FF015F

LABEL_FF0179:
	cp de, 0x10
	jr nz, LABEL_FF0182
	ldb l, 0x5
	ret

LABEL_FF0182:
	lds de, 0
	lda_24 xhl, 0xeed54a

LABEL_FF0189:
	ld bc, de
	extz xbc
	ld xiy, xbc
	add xiy, xwa
	ld xix, xhl
	add xix, xbc
	ld c, (xix)
	cp c, (xiy)
	jr nz, LABEL_FF01A3
	inc 1, de
	cp de, 0x10
	jr c, LABEL_FF0189

LABEL_FF01A3:
	cp de, 0x10
	jr nz, LABEL_FF01AC
	ldb l, 0x4
	ret

LABEL_FF01AC:
	lds de, 0
	lda_24 xhl, 0xeed53b

LABEL_FF01B3:
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
	jr nz, LABEL_FF01D1
	inc 1, de
	cps de, 6
	jr c, LABEL_FF01B3

LABEL_FF01D1:
	cps de, 6
	jr nz, LABEL_FF01D8
	ldb l, 0x1
	ret

LABEL_FF01D8:
	lds de, 0
	lda_24 xhl, 0xeed542

LABEL_FF01DF:
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
	jr nz, LABEL_FF01FD
	inc 1, de
	cps de, 3
	jr c, LABEL_FF01DF

LABEL_FF01FD:
	cps de, 3
	jr nz, LABEL_FF0204
	ldb l, 0x2
	ret

LABEL_FF0204:
	lds de, 0
	lda_24 xhl, 0xeed546

LABEL_FF020B:
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
	jr nz, LABEL_FF0229
	inc 1, de
	cps de, 3
	jr c, LABEL_FF020B

LABEL_FF0229:
	cps de, 3
	jr nz, LABEL_FF0230
	ldb l, 0x3
	ret

LABEL_FF0230:
	ldb l, 0x0
	ret

LABEL_FF0233:
	ldw de, 0x24B8
	lda_24 xbc, 0x1e0000
	lda xwa, (xbc + 16)
	lds hl, 0

LABEL_FF0240:
	add_spiw HL, 0xE1
	djnz xde, LABEL_FF0240
	cpl hl
	st_dri3w HL, 0xE5, 0xA8, 0x72
	ret

; HDAE ROM data dispatch handler
HdaeRom_DataHandler:	; FF024E
	st_dri3b L, 0xFD, 0x48, 0xFE
	push xiz
	lda_dri3 XHL, 0xFD, 0xB8, 0x01
	lda_dri3 XBC, 0xFD, 0xBA, 0x01
	ld xwa, 0x1E0000
	calr LABEL_FF012E
	lda_24 xbc, 0x1e0000
	extz hl
	dec 1, hl
	cps hl, 0
	jrl lt, LABEL_FF03D2
	cps hl, 5
	jrl gt, LABEL_FF03D2
	add hl, hl
	lda_24 xix, 0xeed747
	ld_sriw3 HL, 0x07, 0xF0, 0xEC
	lda_24 xix, 0xff028f
	jp_dri 8, 0x07, 0xF0, 0xEC
; HDAE5000 extension ROM data dispatch (6-entry, table 0xEED747)
HdaeRom_DataDispatch:	; FF028F
	.byte 0xbf, 0x06, 0x61, 0xc3, 0xfd, 0xba, 0x01, 0x3f
	.byte 0xff, 0x7e, 0x33, 0x01, 0xc3, 0xfd, 0xb8, 0x01
	.byte 0x3f, 0xff, 0x7e, 0x2a, 0x01, 0xbf, 0x04, 0x02
	.byte 0x28, 0x00, 0xbf, 0x0e, 0x30, 0xbf, 0x0a, 0x60
	.byte 0x9f, 0x04, 0x20, 0xd8, 0x69, 0xd8, 0x8e, 0xee
	.byte 0x12, 0xee, 0x88, 0x41, 0x21, 0x01, 0x00, 0x00
	.byte 0x1d, 0x5c, 0x0a, 0xff, 0xeb, 0xc8, 0x10, 0x00
	.byte 0x00, 0x00, 0xeb, 0x8d, 0xaf, 0x06, 0x85, 0xaf
	.byte 0x0a, 0x24, 0x31, 0x90, 0x00, 0x95, 0x11, 0x85
	.byte 0x10, 0xee, 0x88, 0x41, 0xd6, 0x01, 0x00, 0x00
	.byte 0x1d, 0x5c, 0x0a, 0xff, 0xeb, 0xc8, 0x10, 0x00
	.byte 0x00, 0x00, 0xaf, 0x06, 0x83, 0xeb, 0x88, 0xaf
	.byte 0x0a, 0x21, 0x1e, 0xc0, 0xf6, 0x9f, 0x04, 0x3a
	.byte 0x01, 0x00, 0x6e, 0xae, 0x78, 0xd0, 0x00, 0xbf
	.byte 0x06, 0x61, 0xc3, 0xfd, 0xba, 0x01, 0x3f, 0xff
	.byte 0x6e, 0x5a, 0xc3, 0xfd, 0xb8, 0x01, 0x3f, 0xff
	.byte 0x6e, 0x52, 0xbf, 0x04, 0x02, 0x24, 0x00, 0xbf
	.byte 0x0e, 0x30, 0xbf, 0x0a, 0x60, 0x9f, 0x04, 0x20
	.byte 0xd8, 0x69, 0xe8, 0x12, 0xe8, 0x89, 0xe9, 0xee
	.byte 0x03, 0xe8, 0x81, 0xe9, 0xee, 0x04, 0xe9, 0xc8
	.byte 0x50, 0x00, 0x00, 0x00, 0xe9, 0x8d, 0xaf, 0x06
	.byte 0x85, 0xaf, 0x0a, 0x24, 0x31, 0x48, 0x00, 0x95
	.byte 0x11, 0x41, 0xd6, 0x01, 0x00, 0x00, 0x1d, 0x5c
	.byte 0x0a, 0xff, 0xeb, 0xc8, 0x10, 0x00, 0x00, 0x00
	.byte 0xaf, 0x06, 0x83, 0xeb, 0x88, 0xaf, 0x0a, 0x21
	.byte 0x1e, 0x1d, 0xfa, 0x9f, 0x04, 0x3a, 0x01, 0x00
	.byte 0x6e, 0xb5, 0x68, 0x6b, 0xc3, 0xfd, 0xb8, 0x01
	.byte 0x21, 0xd8, 0x12, 0xbf, 0x04, 0x50, 0x68, 0x51
	.byte 0x9f, 0x04, 0x20, 0xe8, 0x12, 0xe8, 0x89, 0xe9
	.byte 0xee, 0x03, 0xe8, 0x81, 0xe9, 0xee, 0x04, 0xe9
	.byte 0xc8, 0x50, 0x00, 0x00, 0x00, 0xaf, 0x06, 0x81
	.byte 0xe9, 0x88, 0x1e, 0x9c, 0xf8, 0x9f, 0x04, 0x26
	.byte 0xee, 0x12, 0xee, 0x88, 0x41, 0xd6, 0x01, 0x00
	.byte 0x00, 0x1d, 0x5c, 0x0a, 0xff, 0xeb, 0xc8, 0x10
	.byte 0x00, 0x00, 0x00, 0xaf, 0x06, 0x83, 0xee, 0x89
	.byte 0xe9, 0xee, 0x03, 0xee, 0x81, 0xe9, 0xee, 0x04
	.byte 0xe9, 0xc8, 0x50, 0x00, 0x00, 0x00, 0xaf, 0x06
	.byte 0x81, 0xeb, 0x88, 0x1e, 0xba, 0xf9, 0x9f, 0x04
	.byte 0x61, 0xc3, 0xfd, 0xb8, 0x01, 0x21, 0xc9, 0x61
	.byte 0xd8, 0x12, 0x9f, 0x04, 0xf8, 0x67, 0xa1, 0xdb
	.byte 0xa8, 0x68, 0x03

LABEL_FF03D2:
	ldw hl, 0xFF9A
	pop xiz
	st_dri3b L, 0xFD, 0xB8, 0x01
	ret

LABEL_FF03DC:
	lda_24 xde, 0x1e0000
	lda_24 xwa, 0xeed56c
	ld xbc, xwa
	lda xhl, (xwa + 16)

LABEL_FF03EB:
	ld_spib A, 0xE4
	lda_dpi XBC, 0xE8
	cp xbc, xhl
	jr c, LABEL_FF03EB
	calr LABEL_FF0233
	lds hl, 0
	ret

LABEL_FF03FB:
	.byte 0xf3, 0xe1, 0x91, 0x49, 0x33, 0xf3, 0xe1, 0xa7
	.byte 0x72, 0x34, 0xec, 0x69, 0xeb, 0xf4, 0x67, 0x10
	.byte 0xbc, 0xff, 0x32, 0x82, 0x23, 0xba, 0x01, 0x43
	.byte 0xea, 0x69, 0xec, 0x69, 0xeb, 0xf4, 0x6f, 0xf3
	.byte 0xb3, 0x00, 0x01, 0xc7, 0xea, 0xa8, 0xda, 0xa8
	.byte 0xda, 0x89, 0xd9, 0xc8, 0xa7, 0x49, 0xf3, 0x07
	.byte 0xe0, 0xe4, 0x33, 0x8b, 0x01, 0x3c, 0xcf, 0xe9
	.byte 0x13, 0xe8, 0x81, 0xb9, 0x01, 0xbd, 0xc7, 0xea
	.byte 0x61, 0xda, 0x62, 0xc7, 0xea, 0xcf, 0x80, 0x67
	.byte 0xdf, 0x0e

; HDAE ROM alt dispatch handler
HdaeRom_AltHandler:	; FF0445
	pushw iz
	ld xwa, 0x1E0000
	calr LABEL_FF012E
	extz hl
	dec 1, hl
	cps hl, 0
	jr lt, LABEL_FF047C
	cps hl, 5
	jr gt, LABEL_FF047C
	add hl, hl
	lda_24 xix, 0xeed753
	ld_sriw3 HL, 0x07, 0xF0, 0xEC
	lda_24 xix, 0xff0470
	jp_dri 8, 0x07, 0xF0, 0xEC
; HDAE5000 extension ROM alt dispatch (6-entry, table 0xEED753)
HdaeRom_AltDispatch:	; FF0470
	.byte 0x40, 0x00, 0x00, 0x1e, 0x00, 0x1e, 0x83, 0xff
	.byte 0xde, 0xa8, 0x68, 0x03

LABEL_FF047C:
	ldw iz, 0xFF9A
	lda_24 xde, 0x1e0000
	lda_24 xwa, 0xeed56c
	ld xbc, xwa
	lda xhl, (xwa + 16)

LABEL_FF048E:
	ld_spib A, 0xE4
	lda_dpi XBC, 0xE8
	cp xbc, xhl
	jr c, LABEL_FF048E
	calr LABEL_FF0233
	ld hl, iz
	popw iz
	ret

PreTmLoad:
	ret

PostTmLoad:
	cps wa, 0
	jr lt, LABEL_FF04D6
	ldw wa, 0xFF
	ldw bc, 0xFF
	calr HdaeRom_DataHandler
	ldw wa, 0xFF
	ldw bc, 0xFF
	calr HdaeRom_AltHandler
	calr LABEL_FF03DC
	ld xwa, 0x1E0000
	ldw bc, 0x72AA
	ld xde, 0x7800
	call InterCPU_E1_Bulk_Transfer
	ldw wa, 0xFF
	ldw bc, 0xFF
	call LABEL_FEF491
	jr LABEL_FF04E0

LABEL_FF04D6:
	ldw wa, 0xFF
	ldw bc, 0xFF
	call COMM_BuildAndSendPacket

LABEL_FF04E0:
	jp FDemoText_RefreshFullDisplay

PreTmSave:
	ret

PostTmSave:
	cps wa, 0
	ret ge
	ldw wa, 0xFF
	ldw bc, 0xFF
	call COMM_BuildAndSendPacket
	ret

PostTmSave_ByteBlock:
	.byte 0x1e, 0x37, 0xfc, 0xcf, 0xde, 0x6b, 0x07, 0xcf
	.byte 0xd9, 0x67, 0x03, 0xdb, 0xa8, 0x0e, 0x33, 0x9a
	.byte 0xff, 0x0e

PostTmSave_Success:
	cps wa, 0
	jr lt, PostTmSave_Failure
	ldw wa, 0xFF
	ldw bc, 0xFF
	calr HdaeRom_DataHandler
	ldw wa, 0xFF
	ldw bc, 0xFF
	calr HdaeRom_AltHandler
	calr LABEL_FF03DC
	ld xwa, 0x1E0000
	ldw bc, 0x72AA
	ld xde, 0x7800
	call InterCPU_E1_Bulk_Transfer
	ldw wa, 0xFF
	ldw bc, 0xFF
	call LABEL_FEF491
	jr PostTmSave_JumpToRestore

PostTmSave_Failure:
	ldw wa, 0xFF
	ldw bc, 0xFF
	call COMM_BuildAndSendPacket

PostTmSave_JumpToRestore:
	jp FDemoText_RefreshFullDisplay
TmFlashWrite_Block1:
	.byte 0x0e, 0xef, 0x6c, 0xb7, 0x43, 0xbf, 0x02, 0x41
	.byte 0x8f, 0x02, 0x21, 0xd8, 0x12, 0x87, 0x23, 0xd9
	.byte 0x12, 0xda, 0xd8, 0x61, 0x7b, 0x8f, 0x02, 0x3f
	.byte 0x40, 0x6f, 0x37, 0x1e, 0xe6, 0xfc, 0x1e, 0x71
	.byte 0xfe, 0x87, 0x23, 0xd9, 0x12, 0x8f, 0x02, 0x21
	.byte 0xd8, 0x12, 0xd8, 0x08, 0x14, 0x00, 0xd9, 0x80
	.byte 0xe8, 0x12, 0x41, 0xd6, 0x01, 0x00, 0x00, 0x1d
	.byte 0x5c, 0x0a, 0xff, 0xeb, 0xc8, 0x10, 0x00, 0x00
	.byte 0x00, 0x40, 0x00, 0x00, 0x1e, 0x00, 0xeb, 0x80
	.byte 0xf3, 0xed, 0x00, 0x78, 0x32, 0x31, 0xd6, 0x01
	.byte 0x68, 0x2b, 0x1e, 0xa6, 0xfe, 0x1e, 0x3a, 0xfe
	.byte 0x87, 0x21, 0xd8, 0x12, 0xe8, 0x12, 0xe8, 0x89
	.byte 0xe9, 0xee, 0x02, 0xe8, 0x81, 0xe9, 0xee, 0x04
	.byte 0xe9, 0xc8, 0xa7, 0x4a, 0x00, 0x00, 0x40, 0x00
	.byte 0x00, 0x1e, 0x00, 0xe9, 0x80, 0xf3, 0xe5, 0x00
	.asciz "x21P"
	.byte 0x1d, 0x57, 0x34
	.byte 0xef, 0x8f, 0x02, 0x21, 0xd8, 0x12, 0x87, 0x23
	.byte 0xd9, 0x12, 0x1d, 0x91, 0xf4, 0xfe, 0x68, 0x04
	.byte 0x1d, 0x55, 0xf4, 0xfe, 0x1d, 0xde, 0x51, 0xf8
	.byte 0xef, 0x64, 0x0e, 0x0e, 0xef, 0x6a, 0x3e, 0xbf
	.byte 0x04, 0x41, 0xd9, 0xd8, 0x71, 0x87, 0x00, 0xde
	.byte 0xa8, 0x8f, 0x04
	.ascii "?@oH"
	.byte 0x04, 0x21, 0xd8, 0x12, 0xc7, 0xf8, 0x8b, 0xd9
	.byte 0x12, 0x1e, 0x48, 0xfc, 0xde, 0x61, 0xde, 0xcf
	.byte 0x14, 0x00, 0x67, 0xeb, 0x1e, 0xcb, 0xfd, 0x8f
	.byte 0x04, 0x21, 0xc7, 0xf8, 0x99, 0xde, 0x12, 0xde
	.byte 0x08, 0x14, 0x00, 0xde, 0x88, 0xe8, 0x12, 0x41
	.byte 0xd6, 0x01, 0x00, 0x00, 0x1d, 0x5c, 0x0a, 0xff
	.byte 0xeb, 0xc8, 0x10, 0x00, 0x00, 0x00, 0x40, 0x00
	.byte 0x00, 0x1e, 0x00, 0xeb, 0x80, 0xf3, 0xed, 0x00
	.byte 0x78, 0x32, 0x31, 0xb8, 0x24, 0x68, 0x25, 0x8f
	.byte 0x04, 0x21, 0xd8, 0x12, 0xc7, 0xf8, 0x8b, 0xd9
	.byte 0x12, 0x1e, 0xf7, 0xfd, 0xde, 0x61, 0xde, 0xcf
	.byte 0x80, 0x00, 0x67, 0xeb, 0x1e, 0x83, 0xfd, 0xf2
	.byte 0xa7, 0x4a, 0x1e, 0x30, 0x31, 0x00, 0x28, 0x42
TmFlashWrite_Block2:
	.byte 0xa7, 0xc2, 0x00, 0x00
TmFlashWrite_Block3:
	.byte 0x1d, 0x57, 0x34, 0xef
	.byte 0x8f, 0x04, 0x21, 0xd8, 0x12, 0x31, 0xff, 0x00
	.byte 0x1d, 0x91, 0xf4, 0xfe, 0x68, 0x0c, 0x8f, 0x04
	.byte 0x21, 0xd8, 0x12, 0x31, 0xff, 0x00, 0x1d, 0x55
	.byte 0xf4, 0xfe, 0x1d, 0xde, 0x51, 0xf8, 0x5e, 0xef
	jr	le, 0x0e

TmFlash_CopyToExtMem:
	lda_24 xwa, 0x300000
	add xwa, 0xB0400
	ldw bc, 0xEE1F
	ld xde, 0xA0000
	call InterCPU_E1_Bulk_Transfer
	jp LABEL_FEF4CD
TmFlash_WriteRoutine:
	.byte 0xbf, 0xee, 0x37, 0x3e, 0xbf, 0x0e, 0x62, 0xbf
	.byte 0x12, 0x51, 0xbf, 0x14, 0x41, 0xbf, 0x04, 0x00
	.byte 0x00, 0x9f, 0x12, 0x20, 0xe8, 0x12, 0xbf, 0x0a
	.byte 0x60, 0x41, 0xd6, 0x01, 0x00, 0x00, 0x1d, 0x5c
	.byte 0x0a, 0xff, 0xeb, 0xc8, 0x10, 0x00, 0x00, 0x00
	.byte 0xbf, 0x14, 0xc8, 0x66, 0x60, 0xf2, 0x00, 0x00
	.byte 0x30, 0x36, 0xee, 0xc8, 0x00, 0x04, 0x0b, 0x00
	.byte 0xee, 0x8a, 0xbf, 0x14, 0xc9, 0x66, 0x3b, 0x9f
	.byte 0x12, 0x3f, 0x04, 0x00, 0x6f, 0x24, 0xaf, 0x0e
	.byte 0x20, 0xbf, 0x06, 0x60, 0xaf, 0x0a, 0x20, 0x41
	.byte 0x27, 0x29, 0x00, 0x00, 0x1d, 0x5c, 0x0a, 0xff
	.byte 0xeb, 0xc8, 0x80, 0x49, 0x00, 0x00, 0xee, 0x83
	.byte 0xaf, 0x06, 0x20, 0xb0
	.ascii "c0')hT"
	.byte 0xbf, 0x04, 0x00, 0xff, 0x8f, 0x04
	.byte 0x27, 0xdb, 0x13, 0x5e, 0xbf, 0x12, 0x37, 0x0f
	.byte 0x04, 0x00, 0x9f, 0x12, 0x3f, 0x28, 0x00, 0x6f
	.byte 0xe9, 0xea, 0x83, 0xaf, 0x0e, 0x20, 0xb0, 0x63
	.byte 0x30, 0xd6, 0x01, 0x68, 0x31, 0xf2, 0x00, 0x00
	.byte 0x1e, 0x31, 0xbf, 0x14, 0xc9, 0x66, 0x16, 0x9f
	.byte 0x12, 0x3f, 0x01, 0x00, 0x6f, 0xcc, 0xf3, 0xe5
	.byte 0x80, 0x49, 0x31, 0xaf, 0x0e, 0x20, 0xb0, 0x61
	.ascii "0')h"
	.byte 0x11, 0x9f, 0x12, 0x3f
	.byte 0x28, 0x00, 0x6f, 0xb6, 0xeb, 0x81, 0xaf, 0x0e
	.byte 0x20, 0xb0, 0x61, 0x30, 0xd6, 0x01, 0xaf, 0x1a
	.byte 0x21, 0xb1, 0x50, 0x68, 0xa9, 0x40, 0x00, 0x00
	.byte 0x1e, 0x00, 0x31, 0xaa, 0x72, 0x42, 0x00, 0x78
	.byte 0x00, 0x00, 0x1d, 0x57, 0x34, 0xef, 0x1b, 0xcd
	.byte 0xf4, 0xfe, 0x40, 0x00, 0x00, 0x1e, 0x00, 0x1e
	.byte 0xa5, 0xf9, 0x30, 0x9a, 0xff, 0xcf, 0xde, 0x6e
	.byte 0x02, 0xd8, 0xa8, 0xd8, 0x8b, 0x0e, 0x40, 0x00
	.byte 0x00, 0x1e, 0x00, 0x1e, 0x91, 0xf9, 0xcf, 0xde
	.byte 0x6b, 0x07, 0xcf, 0xd9, 0x67, 0x03, 0xdb, 0xa8
	.byte 0x0e, 0x33, 0x9a, 0xff, 0x0e, 0xe8, 0x12, 0x41
	.byte 0xd6, 0x01, 0x00, 0x00, 0x1d, 0x5c, 0x0a, 0xff
	.byte 0xeb, 0x88, 0xe8, 0xc8, 0x10, 0x00, 0x00, 0x00
	.byte 0x43, 0x00, 0x00, 0x1e, 0x00, 0xe8, 0x83, 0x0e
	.byte 0xef, 0x6c, 0x2e, 0xd9, 0x8e, 0xbf, 0x02, 0x60
	.byte 0xaf, 0x02, 0x20, 0x1e, 0x59, 0xf9, 0xde, 0x88
	.byte 0xe8, 0x12, 0xdb, 0x12, 0xdb, 0x69, 0xdb, 0xd8
	.byte 0x61, 0x4c, 0xdb, 0xdd, 0x6a, 0x48, 0xdb, 0x83
	.byte 0xf2, 0x5f, 0xd7, 0xee, 0x34, 0xd3, 0x07, 0xf0
	.byte 0xec, 0x23, 0xf2, 0xfb, 0x07, 0xff, 0x34, 0xf3
	.byte 0x07, 0xf0, 0xec, 0xd8, 0x41, 0xd6, 0x01, 0x00
	.byte 0x00, 0x68, 0x05, 0x41, 0x21, 0x01, 0x00, 0x00
	.byte 0x1d, 0x5c, 0x0a, 0xff, 0xeb, 0xc8, 0x10, 0x00
	.byte 0x00, 0x00, 0xaf, 0x02, 0x83, 0x68, 0x1c, 0xe8
	.byte 0x89, 0xe9, 0xee, 0x03, 0xe8, 0x81, 0xe9, 0xee
	.byte 0x04, 0xe9, 0xc8, 0x50, 0x00, 0x00, 0x00, 0xaf
	.byte 0x02, 0x81, 0xe9, 0x8b, 0x68, 0x05, 0x43, 0x9a
	.byte 0xff, 0xff, 0xff, 0x4e, 0xef, 0x64, 0x0e, 0xef
	.byte 0x6c, 0x3e, 0xbf, 0x04, 0x62, 0xd8, 0xcf, 0x28
	.byte 0x00, 0x6f, 0x27, 0xe9, 0x8e, 0xe8, 0x12, 0x41
	.byte 0xd6, 0x01, 0x00, 0x00, 0x1d, 0x5c, 0x0a, 0xff
	.byte 0xeb, 0xc8, 0x10, 0x00, 0x00, 0x00, 0x40, 0x00
	.byte 0x00, 0x1e, 0x00, 0xeb, 0x80, 0xb6, 0x60, 0xaf
	.byte 0x04, 0x20, 0xb0, 0x02, 0xd6, 0x01, 0xdb, 0xa8
	.byte 0x68, 0x03, 0x33, 0x38, 0xff, 0x5e, 0xef, 0x64
	.byte 0x0e, 0xef, 0x68, 0x2e, 0xbf, 0x02, 0x62, 0xd9
	.byte 0x8e, 0xbf, 0x06, 0x60, 0xaf, 0x06, 0x20, 0x1e
	.byte 0xad, 0xf8, 0xde, 0x89, 0xe9, 0x12, 0xdb, 0x12
	.byte 0xdb, 0x69, 0xdb, 0xd8, 0x71, 0x86, 0x00, 0xdb
	.byte 0xdd, 0x7a, 0x81, 0x00, 0xdb, 0x83, 0xf2, 0x6b
	.byte 0xd7, 0xee, 0x34, 0xd3, 0x07, 0xf0, 0xec, 0x23
	.byte 0xf2, 0xa9, 0x08, 0xff, 0x34, 0xf3, 0x07, 0xf0
	.byte 0xec, 0xd8, 0xe9, 0x88, 0x41, 0xd6, 0x01, 0x00
	.byte 0x00, 0x1d, 0x5c, 0x0a, 0xff, 0xeb, 0xc8, 0x10
	.byte 0x00, 0x00, 0x00, 0xaf, 0x06, 0x83, 0xaf, 0x06
	.byte 0xa3, 0xaf, 0x02, 0x20, 0xb0, 0x63, 0x30, 0xd6
	.byte 0x01, 0x68, 0x41, 0xe9, 0x88, 0x41, 0x21, 0x01
	.byte 0x00, 0x00, 0x1d, 0x5c, 0x0a, 0xff, 0xeb, 0xc8
	.byte 0x10, 0x00, 0x00, 0x00, 0xaf, 0x06, 0x83, 0xaf
	.byte 0x06, 0xa3, 0xaf, 0x02, 0x20, 0xb0, 0x63, 0x30
	.byte 0x21, 0x01, 0x68, 0x20, 0xe9, 0x88, 0xe8, 0xee
	.byte 0x03, 0xe9, 0x80, 0xe8, 0xee, 0x04, 0xe8, 0xc8
	.byte 0x50, 0x00, 0x00, 0x00, 0xe8, 0x8b, 0xaf, 0x06
	.byte 0x83, 0xaf, 0x06, 0xa3, 0xaf, 0x02, 0x20, 0xb0
	.byte 0x63, 0x30, 0x90, 0x00, 0xaf, 0x0e, 0x21, 0xb1
	.byte 0x50, 0xdb, 0xa8, 0x68, 0x03, 0x33, 0x9a, 0xff
	.byte 0x4e, 0xef, 0x60, 0x0f, 0x04, 0x00, 0xef, 0x6e
	.byte 0x3e, 0xaf, 0x12, 0x20, 0x80, 0x21, 0xbf, 0x08
	.byte 0x41, 0xaf, 0x0e, 0x26, 0x3e, 0x1d, 0xa0, 0x0f
	.byte 0xff, 0xbf, 0x08, 0x53, 0xaf, 0x16, 0x20, 0x38
	.byte 0x1d, 0xa0, 0x0f, 0xff, 0xef, 0x60, 0xbf, 0x06
	.byte 0x53, 0x9f, 0x06, 0x3f, 0x00, 0x00, 0x66, 0x1f
	.byte 0x68, 0x26, 0x8f, 0x08, 0x21, 0x86, 0xf1, 0x6e
	.byte 0x1a, 0x9f, 0x06, 0x04, 0x3e, 0xaf, 0x18, 0x20
	.byte 0x38, 0x1d, 0x1e, 0x0d, 0xff, 0xef, 0xc8, 0x0a
	.byte 0x00, 0x00, 0x00, 0xdb, 0xd8, 0x6e, 0x04, 0xee
	.byte 0x8b, 0x68, 0x0f, 0xee, 0x61, 0x9f, 0x04, 0x69
	.byte 0x9f, 0x06, 0x20, 0x9f, 0x04, 0xf0, 0x63, 0xd2
	.byte 0xeb, 0xa8, 0x5e, 0xef, 0x66, 0x0e

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
	bit_dri 3, 0x07, 0xE4, 0xE0
	jr nz, ParseInt16_SkipWhitespace
	cp (xhl), 0x2D
	jr nz, ParseInt16_CheckMinus
	lds ix, 1
	jr ParseInt16_SkipSign

ParseInt16_CheckMinus:
	cp (xhl), 0x2B
	jr nz, ParseInt16_DigitLoop

ParseInt16_SkipSign:
	inc 1, xhl

ParseInt16_DigitLoop:
	ld_spib E, 0xEC
	exts de
	ld a, e
	extz wa
	bit_dri 2, 0x07, 0xE4, 0xE0
	jr z, ParseInt16_ApplySign
	sub de, 0x30
	muls iy, 0xA
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
	bit_dri 3, 0x07, 0xE4, 0xE0
	jr nz, ParseInt32_SkipWhitespace
	cp (xhl), 0x2D
	jr nz, ParseInt32_CheckMinus
	lds ix, 1
	jr ParseInt32_SkipSign

ParseInt32_CheckMinus:
	cp (xhl), 0x2B
	jr nz, ParseInt32_DigitLoop

ParseInt32_SkipSign:
	inc 1, xhl

ParseInt32_DigitLoop:
	ld_spib E, 0xEC
	exts de
	ld a, e
	extz wa
	bit_dri 2, 0x07, 0xE4, 0xE0
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
	cpl_werp 0xE2
	inc 1, xwa
	ld xhl, xwa
	jr ParseInt32_Return

ParseInt32_Positive:
	ld xhl, xiy

ParseInt32_Return:
	ret

Math_MultiplyAccumulate:
	ldto_werp HL, 0xE2
	mul xhl, xbc
	ldto_werp DE, 0xE6
	mul xde, xwa
	add xhl, xde
	ldfr_werp HL, 0xEE
	lds hl, 0
	mul xwa, xbc
	add xhl, xwa
	ret

; =============================================================================
; Audio_SendCommand -- Send sound parameter command to Sub CPU
; =============================================================================
; Primary interface for all Main CPU -> Sub CPU audio parameter updates.
; Acquires audio lock #7, formats command via Audio_CommandEncoder (printf-like
; format string parser), writes to ring buffer at 0xBD3C via AssswbWr.
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
	pushw 0xFF
	pushw 0xAD8
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

LABEL_FF0AB4:
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
	call	16715848
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
	jr nz, LABEL_FF0B1C
	lds32 xwa, 0
	ld (xbc), xwa
	st32_24 0x03d52c, xbc
	lds wa, 1
	jp TaskSched_SignalEvent

LABEL_FF0B1C:
	ld32_24 xix, 0x03d52c
	ld xde, xix
	or xix, xix
	jr z, LABEL_FF0B33

LABEL_FF0B27:
	cp xbc, xix
	jr ule, LABEL_FF0B33
	ld xde, xix
	ld xix, (xix)
	or xix, xix
	jr nz, LABEL_FF0B27

LABEL_FF0B33:
	cp xbc, xix
	jr nz, LABEL_FF0B3D
	lds wa, 1
	jp TaskSched_SignalEvent

LABEL_FF0B3D:
	ld hl, (xbc + 4)
	extz xhl
	ld xwa, xbc
	inc 6, xwa
	add xwa, xhl
	cpda32_24 xix, 251180
	jr nz, LABEL_FF0B80
	cpda32_24 xwa, 251180
	jr nz, LABEL_FF0B6E
	ld32_24 xwa, 0x03d52c
	ld xwa, (xwa)
	ld (xbc), xwa
	ld32_24 xwa, 0x03d52c
	ld wa, (xwa + 4)
	inc 6, wa
	add (xbc + 4), wa
	jr LABEL_FF0B75

LABEL_FF0B6E:
	ld32_24 xwa, 0x03d52c
	ld (xbc), xwa

LABEL_FF0B75:
	st32_24 0x03d52c, xbc
	lds wa, 1
	jp TaskSched_SignalEvent

LABEL_FF0B80:
	or xix, xix
	jr z, LABEL_FF0B99
	cp xwa, xix
	jr nz, LABEL_FF0B99
	ld xwa, (xix)
	ld (xbc), xwa
	ld wa, (xix + 4)
	add wa, (xbc + 4)
	inc 6, wa
	ld (xbc + 4), wa
	jr LABEL_FF0B9B

LABEL_FF0B99:
	ld (xbc), xix

LABEL_FF0B9B:
	ld hl, (xde + 4)
	extz xhl
	ld xwa, xde
	inc 6, xwa
	add xwa, xhl
	cp xwa, xbc
	jr nz, LABEL_FF0BBB
	ld xwa, (xbc)
	ld (xde), xwa
	ld wa, (xbc + 4)
	add wa, (xde + 4)
	inc 6, wa
	ld (xde + 4), wa
	jr LABEL_FF0BBD

LABEL_FF0BBB:
	ld (xde), xbc

LABEL_FF0BBD:
	lds wa, 1
	jp TaskSched_SignalEvent

LABEL_FF0BC3:
	ldb e, 0x0
	bit_erpw 0xE2, 0x0F
	jr z, LABEL_FF0BD4
	ldb e, 0x1
	cpl_werp 0xE2
	cpl wa
	inc 1, xwa

LABEL_FF0BD4:
	bit_erpw 0xE6, 0x0F
	jr z, LABEL_FF0BE4
	or e, 0x2
	cpl_werp 0xE6
	cpl bc
	inc 1, xbc

LABEL_FF0BE4:
	pushw de
	calr Math_DivideU32
	popw wa
	cps w, 1
	jr z, LABEL_FF0BF6
	ld xhl, xde
	bit 0, a
	scc8 nz, a
	jr LABEL_FF0BFA

LABEL_FF0BF6:
	cps a, 3
	ret z

LABEL_FF0BFA:
	or xhl, xhl
	ret z
	cps a, 0
	ret z
	cpl_werp 0xEE
	cpl hl
	inc 1, xhl
	ret

LABEL_FF0C0A:
	ldb d, 0x0
	jr LABEL_FF0BC3

Math_DivideSigned32:
	ldb d, 0x1
	jr LABEL_FF0BC3

DivMod32:
	calr Math_DivideU32
	ld xhl, xde
	ret

Math_DivideU32:
	cp xbc, 0x1
	jr z, LABEL_FF0C51
	jr c, LABEL_FF0C56
	cp xwa, xbc
	jr ule, LABEL_FF0C5D
	cpi_werp 0xE6, 0
	jr nz, LABEL_FF0C68
	ld xde, xwa
	div xwa, xbc
	jr ov, LABEL_FF0C3B
			; Note: OV (Overflow) is the same as PE = Parity Even
	lds32 xhl, 0
	ld xde, xhl
	ld hl, wa
	ldto_werp DE, 0xE2
	ret

LABEL_FF0C3B:
	ldto_werp WA, 0xEA
	extz xwa
	div xwa, xbc
	ldfr_werp WA, 0xEE
	ld wa, de
	div xwa, xbc
	ld hl, wa
	ldto_werp DE, 0xE2
	extz xde
	ret

LABEL_FF0C51:
	ld xhl, xwa
	lds32 xde, 0
	ret

LABEL_FF0C56:
	lds32 xhl, 0
	ld xde, xhl
	dec 1, xhl
	ret

LABEL_FF0C5D:
	lds32 xhl, 1
	lds32 xde, 0
	ret z
	dec 1, xhl
	ld xde, xwa
	ret

LABEL_FF0C68:
	ldb d, 0x0

LABEL_FF0C6A:
	cp xwa, xbc
	jr c, LABEL_FF0C79
	inc 1, d
	add xbc, xbc
	jr nc, LABEL_FF0C6A
	rr xbc
	jr LABEL_FF0C7C

LABEL_FF0C79:
	srl xbc, 1

LABEL_FF0C7C:
	lds32 xhl, 0

LABEL_FF0C7E:
	add xhl, xhl
	cp xwa, xbc
	jr c, LABEL_FF0C89
	set 0, l
	sub xwa, xbc

LABEL_FF0C89:
	srl xbc, 1
	djnz8 d, LABEL_FF0C7E
	ld xde, xwa
	ret

Strncat:
	ld xix, (xsp + 4)
	ld xhl, xix
	jr LABEL_FF0C9B

LABEL_FF0C99:
	inc 1, xix

LABEL_FF0C9B:
	cp (xix), 0x0
	jr nz, LABEL_FF0C99
	ld xde, (xsp + 8)
	ld bc, (xsp + 12)
	jr LABEL_FF0CB5

LABEL_FF0CA8:
	ld a, (xde)
	ld (xix), a
	cp (xix), 0x0
	ret z
	inc 1, xix
	inc 1, xde

LABEL_FF0CB5:
	ld wa, bc
	dec 1, bc
	cps wa, 0
	jr nz, LABEL_FF0CA8
	ld (xix), 0x0
	ret

String_Compare:
	ld bc, (xsp + 12)
	ld xde, (xsp + 8)
	ld xix, (xsp + 4)
	jr LABEL_FF0CDA

LABEL_FF0CCC:
	cp (xix), 0x0
	jr nz, LABEL_FF0CD4
	lds hl, 0
	ret

LABEL_FF0CD4:
	inc 1, xix
	inc 1, xde
	dec 1, bc

LABEL_FF0CDA:
	cps bc, 0
	jr z, LABEL_FF0CE4
	ld a, (xde)
	cp a, (xix)
	jr z, LABEL_FF0CCC

LABEL_FF0CE4:
	ldb l, 0x0
	cps bc, 0
	jr z, LABEL_FF0CF0
	ld a, (xix)
	sub a, (xde)
	ld l, a

LABEL_FF0CF0:
	exts hl
	ret

; Strncpy -- Copy string with length limit, zero-pad remainder
; Args: (xsp+4)=dest, (xsp+8)=src, (xsp+12)=maxlen
Strncpy:
	ld bc, (xsp + 12)
	ld xde, (xsp + 8)
	ld xix, (xsp + 4)
	ld xhl, xix
	jr LABEL_FF0D08

LABEL_FF0D00:
	ld_spib A, 0xE8
	lda_dpi XBC, 0xF0
	dec 1, bc

LABEL_FF0D08:
	cps bc, 0
	jr z, LABEL_FF0D11
	cp (xde), 0x0
	jr nz, LABEL_FF0D00

LABEL_FF0D11:
	jr LABEL_FF0D19

LABEL_FF0D13:
	stib_dpi 0xF0, 0x00
	dec 1, bc

LABEL_FF0D19:
	cps bc, 0
	jr nz, LABEL_FF0D13
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
	jr z, LABEL_FF0D52

LABEL_FF0D3B:
	ld_spib L, 0xF0
	extz hl
	ld_spib A, 0xF4
	extz wa
	sub hl, wa
	ret nz
	sub bc, 0x1
	ret z
	djnz xde, LABEL_FF0D3B

LABEL_FF0D52:
	ld de, bc
	srl bc, 2
	jr z, LABEL_FF0D81

LABEL_FF0D59:
	ld_spil XHL, 0xF2
	ld_spil XWA, 0xF6
	cp xhl, xwa
	jr z, LABEL_FF0D7C
	cp hl, wa
	jr nz, LABEL_FF0D6D
	ldto_werp HL, 0xEE
	ldto_werp WA, 0xE2

LABEL_FF0D6D:
	cp l, a
	jr nz, LABEL_FF0D75
	ld l, h
	ld a, w

LABEL_FF0D75:
	extz hl
	extz wa
	sub hl, wa
	ret

LABEL_FF0D7C:
	djnz xbc, LABEL_FF0D59
	lds hl, 0

LABEL_FF0D81:
	and de, 0x3
	ret z

LABEL_FF0D87:
	ld_spib L, 0xF0
	extz hl
	ld_spib A, 0xF4
	extz wa
	sub hl, wa
	ret nz
	djnz xde, LABEL_FF0D87
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
	jr z, LABEL_FF0DB5
	ldi85
	ret nov

LABEL_FF0DB5:
	srl bc, 1
	jr z, LABEL_FF0DBC
	ldirw

LABEL_FF0DBC:
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
	jr LABEL_FF0DCA

LABEL_FF0DC8:
	inc 1, xde

LABEL_FF0DCA:
	cp (xde), 0x0
	jr nz, LABEL_FF0DC8
	ld xbc, (xsp + 8)
	jr LABEL_FF0DDA

LABEL_FF0DD4:
	ld_spib A, 0xE4
	lda_dpi XBC, 0xE8

LABEL_FF0DDA:
	cp (xbc), 0x0
	jr nz, LABEL_FF0DD4
	ld (xde), 0x0
	ret

Itoa_Safe:
	lda xsp, (xsp - 18)
	push xiz
	ld xhl, (xsp + 28)
	lds ix, 0
	ld bc, (xsp + 32)
	cps bc, 2
	jr lt, LABEL_FF0DF9
	cp bc, 0x24
	jr le, Itoa

LABEL_FF0DF9:
	ld (xhl), 0x0
	jr LABEL_FF0E68

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
	ldfr_werp WA, 0xE6
	lda xiz, (xsp + 4)
	ld (xiz + 17), 0x0
	lda xiy, (xiz + 16)
	cp bc, 0xA
	jr nz, NumFormat_DivideAndConvert
	ldto_werp WA, 0xE6
	cps wa, 0
	jr ge, NumFormat_DivideAndConvert
	lds ix, 1
	ldto_werp WA, 0xE6
	neg wa
	ldfr_werp WA, 0xE6

NumFormat_DivideAndConvert:
	ld de, bc
	ldto_werp WA, 0xE6
	extz xwa
	div xwa, xde
	ldto_werp WA, 0xE2
	add a, 0x30
	ld (xiy), a
	cp (xiy), 0x39
	jr le, LABEL_FF0E3E
	addmi8 (xiy), 0x27

LABEL_FF0E3E:
	ldto_werp WA, 0xE6
	extz xwa
	div xwa, xde
	ldfr_werp WA, 0xE6
	cpi_werp 0xE6, 0
	jr z, LABEL_FF0E51
	dec 1, xiy
	jr NumFormat_DivideAndConvert

LABEL_FF0E51:
	cps ix, 0
	jr z, LABEL_FF0E59
	stib_dpd 0xF4, 0x2D

LABEL_FF0E59:
	lda xwa, (xiz + 18)
	sub xwa, xiy
	pushw wa
	push xiy
	push xhl
	call Mem_Copy
	lda xsp, (xsp + 10)

LABEL_FF0E68:
	pop xiz
	lda xsp, (xsp + 18)
	ret

LABEL_FF0E6D:
	.byte 0xaf, 0x04, 0x23, 0x9f, 0x08, 0x20, 0x83, 0xf1
	.byte 0xb0, 0xf6, 0xc5, 0xec, 0x3f, 0x00, 0x6e, 0xf6
	.byte 0xeb, 0xa8, 0x0e

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
	jr z, LABEL_FF0EB1

LABEL_FF0EA0:
	ld wa, (xiz + 4)
	cp wa, (xsp + 8)
	jr nc, LABEL_FF0EB1
	ld (xsp + 4), xiz
	ld xiz, (xiz)
	or xiz, xiz
	jr nz, LABEL_FF0EA0

LABEL_FF0EB1:
	or xiz, xiz
	jr z, LABEL_FF0EFC
	ld wa, (xiz + 4)
	sub wa, (xsp + 8)
	cp wa, 0xA
	jr c, LABEL_FF0EE3
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

LABEL_FF0EE3:
	cpda32_24 xiz, 251180
	jr nz, LABEL_FF0EF3
	ld xwa, (xiz)
	st32_24 0x03d52c, xwa
	jr LABEL_FF0F27

LABEL_FF0EF3:
	ld xwa, (xsp + 4)
	ld xbc, (xiz)
	ld (xwa), xbc
	jr LABEL_FF0F27

LABEL_FF0EFC:
	ld wa, (xsp + 8)
	inc 6, wa
	extz xwa
	call Heap_Alloc
	ld xiz, xhl
	ld xwa, xiz
	cp xwa, 0xFFFFFFFF
	jr nz, LABEL_FF0F1D
	lds wa, 1
	call TaskSched_SignalEvent
	lds32 xhl, 0
	jr LABEL_FF0F31

LABEL_FF0F1D:
	lds32 xwa, 0
	ld (xiz), xwa
	ld wa, (xsp + 8)
	ld (xiz + 4), wa

LABEL_FF0F27:
	lds wa, 1
	call TaskSched_SignalEvent
	inc 6, xiz
	ld xhl, xiz

LABEL_FF0F31:
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
	pushw 0xFFFE
	pushw 0x0
	ld xwa, (xsp + 16)
	push xwa
	ld xiz, (xsp + 16)
	push xiz
	call AudioCmd_StringNSearch
	add xsp, 0xC
	or xhl, xhl
	jr nz, LABEL_FF0F75
	ld xwa, xiz
	add xwa, 0xFFFF
	ld (xwa), 0x0

LABEL_FF0F75:
	ld xhl, xiz
	pop xiz
	ret

; ============================================================================
; Heap_Alloc - Allocate memory from the heap (C runtime)
; ============================================================================
; Input:  XWA = size in bytes to allocate (0 = return heap base)
; Output: XHL = pointer to allocated block (0xFFFFFFFF if insufficient space)
; Simple bump allocator: advances the heap pointer at 0x03D524 by the
; requested size. Checks available space at 0x03D528. Falls through to
; Heap_Grow if space is available.
; ============================================================================
Heap_Alloc:
	or xwa, xwa
	jr nz, LABEL_FF0F83
	ld32_24 xhl, 0x03d528
	ret

LABEL_FF0F83:
	cpdm32_24 251176, xwa
	jr nc, Heap_Grow
	ld xhl, 0xFFFFFFFF
	ret

; ============================================================================
; Heap_Grow - Grow the heap by allocating more memory
; ============================================================================
; Input:  XWA = size in bytes to allocate
; Output: XHL = pointer to newly allocated block (previous heap top)
; Advances the heap top pointer (0x03D524) and decreases available space
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
;         Returns 0xFFFF if null terminator not found
; Uses AudioCmd_MemChr to search for 0x00 byte, then computes result - start.
; Located between Strcpy and Memset (standard C library functions).
; ============================================================================
Strlen:
	push xiz
	pushw 0xFFFF
	pushw 0x0
	ld xiz, (xsp + 12)
	push xiz
	call AudioCmd_MemChr
	inc 8, xsp
	or xhl, xhl
	jr nz, LABEL_FF0FBA
	ldw hl, 0xFFFF
	jr LABEL_FF0FBC

LABEL_FF0FBA:
	sub xhl, xiz

LABEL_FF0FBC:
	pop xiz
	ret

LABEL_FF0FBE:
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld wa, (xsp + 12)
	cp wa, 0xA
	jr nz, Itoa_WithBase
	cp xde, 0x0
	jr ge, Itoa_WithBase
	ld (xbc), 0x2D
	pushw wa
	lda xwa, (xbc + 1)
	push xwa
	cpl de
	cpl_werp 0xEA
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
	jr z, LABEL_FF101F

LABEL_FF1013:
	lda_dpi XBC, 0xF0
	sub bc, 0x1
	ret z
	djnz xde, LABEL_FF1013

LABEL_FF101F:
	ld de, bc
	srl bc, 2
	jr z, LABEL_FF1031
	ld w, a
	ldfr_werp WA, 0xE2

LABEL_FF102B:
	st_dpil XWA, 0xF2
	djnz xbc, LABEL_FF102B

LABEL_FF1031:
	and de, 0x3
	ret z

LABEL_FF1037:
	lda_dpi XBC, 0xF0
	djnz xde, LABEL_FF1037
	ret

Math_AbsInt16:
	ld hl, (xsp + 4)
	cps hl, 0
	ret ge
	neg hl
	ret

	.include "audio/audio_cmd_encoder.s"
