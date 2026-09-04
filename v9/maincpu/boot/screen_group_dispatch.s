; =============================================================================
; Screen Group Dispatch
; =============================================================================
;
; Boot screen group dispatcher for startup screens and error
; dialogs. Also contains the system reinitialization routine
; called during display mode transitions.
; =============================================================================

ScreenGroup_ReInit:
	call MidiParam_ForceResync
	call Audio_UpdateLEDsAndChannels
	call Reset_Floppy_Disk_Controller
	call SndParam_Init
	call MainTitle_InitGraphicsAndEvents
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
; Notes: Uses table at 0xee8c7e to dispatch to widget handlers.
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
	jr nz, ScreenGroup_SetupWidgetPtr
	call ScreenGroup_InitState	; Initialize screen state
	call TmFlash_CopyToExtMem

ScreenGroup_SetupWidgetPtr:
	ldiw_erp 0xfa, 0
	jr ScreenGroup_WidgetLoop

; Voice initialization dispatch
VoiceInit_Dispatch:
	push xiz
	ld de, iz
	extz xde
	sll xde, 2
	stw_erp WA, 0xfa
	extz xwa
	sll xwa, 2
	ld xbc, SystemConfig_PointerTable
	add xbc, xwa
	ld xwa, (xbc)
	add xwa, xde
	ld xhl, (xwa)
	call (xhl)
	pop xiz
	inc1w_erp 0xfa

ScreenGroup_WidgetLoop:
	stw_erp WA, 0xfa
	extz xwa
	sll xwa, 2
	ld xbc, SystemConfig_PointerTable
	add xbc, xwa
	ld xwa, (xbc)
	or xwa, xwa
	jr nz, VoiceInit_Dispatch
	cps iz, 0
	call z, (ScreenGroup_ReInit:24)
	pop xiz
	ret

ScreenGroup_InitState:
	lda xbc, (0xc1fe:16)
	ld (xbc), 0x1
	ld (xbc + 1), 0xff
	ld (xbc + 2), 0xff
	ld (xbc + 3), 0xff
	or (0xc2c2:16), 127
	and (0xc2c3:16), 1
	or (0xc2c4:16), 254
	and (0xc2c5:16), 1
	or (0xc2c6:16), 127
	and (0xc2c7:16), 1
	or (0xc2c8:16), 254
	and (0xc2c9:16), 1
	or (0xc2ca:16), 127
	and (0xc2cb:16), 1
	or (0xc2cc:16), 254
	and (0xc2cd:16), 1
	or (0xc2ce:16), 127
	and (0xc2cf:16), 1
	or (0xc2d0:16), 254
	and (0xc2d1:16), 1
	or (0xc2d2:16), 127
	and (0xc2d3:16), 1
	or (0xc2d4:16), 254
	and (0xc2d5:16), 1
	lds de, 0
	cp de, 0x20
	jrl ge, ScreenGroup_InitParams16

ScreenGroup_InitVoiceLoop:
	ld wa, de
	inc 4, wa
	stib_ind 0x07, 0xe4, 0xe0, 0xff
	ld wa, de
	add wa, 0x24
	stib_ind 0x07, 0xe4, 0xe0, 0xff
	ld wa, de
	add wa, 0x44
	stib_ind 0x07, 0xe4, 0xe0, 0xff
	ld wa, de
	add wa, 0x64
	stib_ind 0x07, 0xe4, 0xe0, 0xff
	ld wa, de
	add wa, 0x64
	stib_ind 0x07, 0xe4, 0xe0, 0xff
	ld wa, de
	add wa, wa
	add wa, 0xe4
	res_dri 7, 0x07, 0xe4, 0xe0
	ld wa, de
	add wa, wa
	add wa, 0xe4
	and_srib_im 0x07, 0xe4, 0xe0, 0x8f
	ld wa, de
	add wa, wa
	add wa, 0x124
	res_dri 7, 0x07, 0xe4, 0xe0
	ld wa, de
	add wa, wa
	add wa, 0x124
	set_dri 6, 0x07, 0xe4, 0xe0
	ld wa, de
	add wa, wa
	add wa, 0x124
	set_dri 5, 0x07, 0xe4, 0xe0
	ld wa, de
	add wa, wa
	add wa, 0x124
	res_dri 4, 0x07, 0xe4, 0xe0
	ld wa, de
	add wa, wa
	add wa, 0x124
	and_srib_im 0x07, 0xe4, 0xe0, 0xf1
	ld wa, de
	add wa, wa
	add wa, 0x124
	exts xwa
	add xwa, xbc
	andmi8 (xwa + 1), 0xf
	inc 1, de
	cp de, 0x20
	jrl lt, ScreenGroup_InitVoiceLoop

ScreenGroup_InitParams16:
	lds de, 0
	cp de, 0x10
	jr ge, ScreenGroup_InitParams8

ScreenGroup_InitParam16Loop:
	ld wa, de
	add wa, 0x84
	stib_ind 0x07, 0xe4, 0xe0, 0xff
	ld wa, de
	add wa, 0x94
	stib_ind 0x07, 0xe4, 0xe0, 0xff
	ld wa, de
	add wa, 0xa4
	stib_ind 0x07, 0xe4, 0xe0, 0xff
	inc 1, de
	cp de, 0x10
	jr lt, ScreenGroup_InitParam16Loop

ScreenGroup_InitParams8:
	lds de, 0
	cp de, 0x8
	jr ge, ScreenGroup_InitParams8Complex

ScreenGroup_InitParam8Loop:
	ld wa, de
	add wa, 0xb4
	stib_ind 0x07, 0xe4, 0xe0, 0xff
	ld wa, de
	add wa, 0xbc
	stib_ind 0x07, 0xe4, 0xe0, 0xff
	inc 1, de
	cp de, 0x8
	jr lt, ScreenGroup_InitParam8Loop

ScreenGroup_InitParams8Complex:
	lds de, 0
	cp de, 0x8
	jr ge, ScreenGroup_FinalInit

ScreenGroup_InitParam8ComplexLoop:
	ld wa, de
	sla wa, 2
	add wa, 0xc4
	res_dri 7, 0x07, 0xe4, 0xe0
	ld wa, de
	sla wa, 2
	add wa, 0xc4
	or_srib_im 0x07, 0xe4, 0xe0, 0x7f
	ld wa, de
	sla wa, 2
	add wa, 0xc4
	exts xwa
	add xwa, xbc
	andmi8 (xwa + 1), 0x1
	ld wa, de
	sla wa, 2
	add wa, 0xc4
	exts xwa
	add xwa, xbc
	ormi8 (xwa + 2), 0xfe
	ld wa, de
	sla wa, 2
	add wa, 0xc4
	exts xwa
	add xwa, xbc
	andmi8 (xwa + 3), 0x1
	inc 1, de
	cp de, 0x8
	jr lt, ScreenGroup_InitParam8ComplexLoop

ScreenGroup_FinalInit:
	ld (xbc), 0x1
	ld (xbc + 4), 0x0
	ld xiy, 0xc1fe
	ld xix, 0xc364
	ldw bc, 0xb3
	ldirw
	lds de, 0
	cp de, 0xa1
	jr ge, ScreenGroup_InitFinalize

ScreenGroup_InitWordPairsLoop:
	ld wa, de
	add wa, wa
	lda xbc, (0xc62a:16)
	extz xwa
	add xwa, xbc
	ld (xwa), 0x10
	ld wa, de
	add wa, wa
	lda xbc, (0xc62b:16)
	extz xwa
	add xwa, xbc
	ld (xwa), 0x0
	inc 1, de
	cp de, 0xa1
	jr lt, ScreenGroup_InitWordPairsLoop

ScreenGroup_InitFinalize:
	ld (0xca6a:16), 8
	ld (0xca6b:16), 0
	ld (0xca6c:16), 8
	ld (0xca6d:16), 0
	ld (0xca6e:16), 16
	ld (0xca6f:16), 0
	jp COMM_SendDataReturn

