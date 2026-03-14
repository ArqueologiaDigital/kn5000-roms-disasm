; =============================================================================
; Screen Group Dispatch
; =============================================================================
;
; Boot screen group dispatcher for startup screens and error
; dialogs. Also contains the system reinitialization routine
; called during display mode transitions.
; =============================================================================

LABEL_FDDB2E:
	call MidiParam_ForceResync
	call Audio_UpdateLEDsAndChannels
	call Reset_Floppy_Disk_Controller
	call SndParam_Init
	call LABEL_F9800F
	jp LoadAndRunXapr_Entry

; ===========================================================================
; ScreenGroup_Dispatch - Display a screen group and process its widgets
; ===========================================================================
; Entry: WA = Screen group ID (0-7+)
;          0 = Initial boot screen
;          1 = Normal startup screen
;          2 = Error state screen (leads to error dialogs)
;          3 = Additional initialization
;          4 = Main UI / may trigger Screen Group 7 error dialog
;          7 = Error dialogs including "CPU data transmission" error
; Exit:  All widgets in the screen group have been rendered
; Notes: Uses table at 0xEE8C7E to dispatch to widget handlers.
;        When screen group 2 is selected during boot (error condition),
;        eventually leads to displaying Screen Group 7 error dialog.
;
; See also:
;   - Show_ScreenGroup (Show_ScreenGroup_Entry) - Alternative screen display routine
;   - ErrorDialog_CPUTransmissionError - Error dialog in Screen Group 7
; ===========================================================================
ScreenGroup_Dispatch:
ScreenGroup_DispatchAlt:
	push xiz
	ld iz, wa	; Screen group ID
	cps iz, 0
	jr nz, LABEL_FDDB55
	call LABEL_FDDB9B	; Initialize screen state
	call TmFlash_CopyToExtMem

LABEL_FDDB55:
	ldi_werp 0xFA, 0
	jr LABEL_FDDB7D

; Voice initialization dispatch
VoiceInit_Dispatch:
	push xiz
	ld de, iz
	extz xde
	sll xde, 2
	ldto_werp WA, 0xFA
	extz xwa
	sll xwa, 2
	ld xbc, 0xEE8C7E
	add xbc, xwa
	ld xwa, (xbc)
	add xwa, xde
	ld xhl, (xwa)
	call (xhl)
	pop xiz
	inc1_werp 0xFA

LABEL_FDDB7D:
	ldto_werp WA, 0xFA
	extz xwa
	sll xwa, 2
	ld xbc, 0xEE8C7E
	add xbc, xwa
	ld xwa, (xbc)
	or xwa, xwa
	jr nz, VoiceInit_Dispatch
	cps iz, 0
	call_24 z, 0xFDDB2E
	pop xiz
	ret

LABEL_FDDB9B:
	ldada xbc, 49662
	ld (xbc), 0x1
	ld (xbc + 1), 0xFF
	ld (xbc + 2), 0xFF
	ld (xbc + 3), 0xFF
	ordi8 49858, 127
	anddi8 49859, 1
	ordi8 49860, 254
	anddi8 49861, 1
	ordi8 49862, 127
	anddi8 49863, 1
	ordi8 49864, 254
	anddi8 49865, 1
	ordi8 49866, 127
	anddi8 49867, 1
	ordi8 49868, 254
	anddi8 49869, 1
	ordi8 49870, 127
	anddi8 49871, 1
	ordi8 49872, 254
	anddi8 49873, 1
	ordi8 49874, 127
	anddi8 49875, 1
	ordi8 49876, 254
	anddi8 49877, 1
	lds de, 0
	cp de, 0x20
	jrl ge, LABEL_FDDCCB

LABEL_FDDC1B:
	ld wa, de
	inc 4, wa
	stib_dri 0x07, 0xE4, 0xE0, 0xFF
	ld wa, de
	add wa, 0x24
	stib_dri 0x07, 0xE4, 0xE0, 0xFF
	ld wa, de
	add wa, 0x44
	stib_dri 0x07, 0xE4, 0xE0, 0xFF
	ld wa, de
	add wa, 0x64
	stib_dri 0x07, 0xE4, 0xE0, 0xFF
	ld wa, de
	add wa, 0x64
	stib_dri 0x07, 0xE4, 0xE0, 0xFF
	ld wa, de
	add wa, wa
	add wa, 0xE4
	res_dri 7, 0x07, 0xE4, 0xE0
	ld wa, de
	add wa, wa
	add wa, 0xE4
	and_srib_im 0x07, 0xE4, 0xE0, 0x8F
	ld wa, de
	add wa, wa
	add wa, 0x124
	res_dri 7, 0x07, 0xE4, 0xE0
	ld wa, de
	add wa, wa
	add wa, 0x124
	set_dri 6, 0x07, 0xE4, 0xE0
	ld wa, de
	add wa, wa
	add wa, 0x124
	set_dri 5, 0x07, 0xE4, 0xE0
	ld wa, de
	add wa, wa
	add wa, 0x124
	res_dri 4, 0x07, 0xE4, 0xE0
	ld wa, de
	add wa, wa
	add wa, 0x124
	and_srib_im 0x07, 0xE4, 0xE0, 0xF1
	ld wa, de
	add wa, wa
	add wa, 0x124
	exts xwa
	add xwa, xbc
	andmi8 (xwa + 1), 0xF
	inc 1, de
	cp de, 0x20
	jrl lt, LABEL_FDDC1B

LABEL_FDDCCB:
	lds de, 0
	cp de, 0x10
	jr ge, LABEL_FDDCFF

LABEL_FDDCD3:
	ld wa, de
	add wa, 0x84
	stib_dri 0x07, 0xE4, 0xE0, 0xFF
	ld wa, de
	add wa, 0x94
	stib_dri 0x07, 0xE4, 0xE0, 0xFF
	ld wa, de
	add wa, 0xA4
	stib_dri 0x07, 0xE4, 0xE0, 0xFF
	inc 1, de
	cp de, 0x10
	jr lt, LABEL_FDDCD3

LABEL_FDDCFF:
	lds de, 0
	cp de, 0x8
	jr ge, LABEL_FDDD27

LABEL_FDDD07:
	ld wa, de
	add wa, 0xB4
	stib_dri 0x07, 0xE4, 0xE0, 0xFF
	ld wa, de
	add wa, 0xBC
	stib_dri 0x07, 0xE4, 0xE0, 0xFF
	inc 1, de
	cp de, 0x8
	jr lt, LABEL_FDDD07

LABEL_FDDD27:
	lds de, 0
	cp de, 0x8
	jr ge, LABEL_FDDD87

LABEL_FDDD2F:
	ld wa, de
	sla wa, 2
	add wa, 0xC4
	res_dri 7, 0x07, 0xE4, 0xE0
	ld wa, de
	sla wa, 2
	add wa, 0xC4
	or_srib_im 0x07, 0xE4, 0xE0, 0x7F
	ld wa, de
	sla wa, 2
	add wa, 0xC4
	exts xwa
	add xwa, xbc
	andmi8 (xwa + 1), 0x1
	ld wa, de
	sla wa, 2
	add wa, 0xC4
	exts xwa
	add xwa, xbc
	ormi8 (xwa + 2), 0xFE
	ld wa, de
	sla wa, 2
	add wa, 0xC4
	exts xwa
	add xwa, xbc
	andmi8 (xwa + 3), 0x1
	inc 1, de
	cp de, 0x8
	jr lt, LABEL_FDDD2F

LABEL_FDDD87:
	ld (xbc), 0x1
	ld (xbc + 4), 0x0
	ld xiy, 0xC1FE
	ld xix, 0xC364
	ldw bc, 0xB3
	ldirw
	lds de, 0
	cp de, 0xA1
	jr ge, LABEL_FDDDCB

LABEL_FDDDA5:
	ld wa, de
	add wa, wa
	ldada xbc, 50730
	extz xwa
	add xwa, xbc
	ld (xwa), 0x10
	ld wa, de
	add wa, wa
	ldada xbc, 50731
	extz xwa
	add xwa, xbc
	ld (xwa), 0x0
	inc 1, de
	cp de, 0xA1
	jr lt, LABEL_FDDDA5

LABEL_FDDDCB:
	stdi8 51818, 8
	stdi8 51819, 0
	stdi8 51820, 8
	stdi8 51821, 0
	stdi8 51822, 16
	stdi8 51823, 0
	jp COMM_SendDataReturn

