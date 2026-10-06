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
; ScreenGroup_Dispatch - run init phase WA of every subsystem
; ===========================================================================
; Entry: WA = slot 0-3.  For each table of Subsys_HandlerTableList (19 subsystems, one 4-pointer table
;        each) it calls table[WA]; the loop counter is ERP bank 0xFA's WA.  The boot code calls it with
;        0 right after the Sub-CPU payload transfer, then 1 if SubCPU_Payload_GetErrorFlag is 0 or 2 if
;        not, then 3 (kn5000_v<N>_program.s); MainSysCtrl_DispatchTable's entry 0 calls slot 2 too.
;        Slot 0 also runs ScreenGroup_InitState first and ScreenGroup_ReInit last.  The audio table reads
;        Audio_InitAllDefaults | Audio_ReinitToneGenAndOutput | Audio_ResetAfterPayloadError |
;        Audio_FullReinitWithPreset.
; Correction (2026-10-06): this header called WA a "screen group ID" (0 = initial boot screen,
; 1 = normal startup, 2 = error, 4 = main UI, 7 = error dialogs); the routine draws nothing itself --
; whatever appears on screen comes from the subsystems' phase handlers.  Its name is kept for now.
; ===========================================================================
ScreenGroup_Dispatch:
ScreenGroup_DispatchAlt:
	push xiz
	ld iz, wa	; Screen group ID
	cp iz, 0:i3
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
	ldto_werp WA, 0xfa
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
	ldto_werp WA, 0xfa
	extz xwa
	sll xwa, 2
	ld xbc, SystemConfig_PointerTable
	add xbc, xwa
	ld xwa, (xbc)
	or xwa, xwa
	jr nz, VoiceInit_Dispatch
	cp iz, 0:i3
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
	ld de, 0:i3
	cp de, 0x20
	jrl ge, ScreenGroup_InitParams16

ScreenGroup_InitVoiceLoop:
	ld wa, de
	inc 4, wa
	ld	(xbc+wa), 0xff
	ld wa, de
	add wa, 0x24
	ld	(xbc+wa), 0xff
	ld wa, de
	add wa, 0x44
	ld	(xbc+wa), 0xff
	ld wa, de
	add wa, 0x64
	ld	(xbc+wa), 0xff
	ld wa, de
	add wa, 0x64
	ld	(xbc+wa), 0xff
	ld wa, de
	add wa, wa
	add wa, 0xe4
	res	7, (xbc+wa)
	ld wa, de
	add wa, wa
	add wa, 0xe4
	and	(xbc+wa), 0x8f
	ld wa, de
	add wa, wa
	add wa, 0x124
	res	7, (xbc+wa)
	ld wa, de
	add wa, wa
	add wa, 0x124
	set	6, (xbc+wa)
	ld wa, de
	add wa, wa
	add wa, 0x124
	set	5, (xbc+wa)
	ld wa, de
	add wa, wa
	add wa, 0x124
	res	4, (xbc+wa)
	ld wa, de
	add wa, wa
	add wa, 0x124
	and	(xbc+wa), 0xf1
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
	ld de, 0:i3
	cp de, 0x10
	jr ge, ScreenGroup_InitParams8

ScreenGroup_InitParam16Loop:
	ld wa, de
	add wa, 0x84
	ld	(xbc+wa), 0xff
	ld wa, de
	add wa, 0x94
	ld	(xbc+wa), 0xff
	ld wa, de
	add wa, 0xa4
	ld	(xbc+wa), 0xff
	inc 1, de
	cp de, 0x10
	jr lt, ScreenGroup_InitParam16Loop

ScreenGroup_InitParams8:
	ld de, 0:i3
	cp de, 0x8
	jr ge, ScreenGroup_InitParams8Complex

ScreenGroup_InitParam8Loop:
	ld wa, de
	add wa, 0xb4
	ld	(xbc+wa), 0xff
	ld wa, de
	add wa, 0xbc
	ld	(xbc+wa), 0xff
	inc 1, de
	cp de, 0x8
	jr lt, ScreenGroup_InitParam8Loop

ScreenGroup_InitParams8Complex:
	ld de, 0:i3
	cp de, 0x8
	jr ge, ScreenGroup_FinalInit

ScreenGroup_InitParam8ComplexLoop:
	ld wa, de
	sla wa, 2
	add wa, 0xc4
	res	7, (xbc+wa)
	ld wa, de
	sla wa, 2
	add wa, 0xc4
	or	(xbc+wa), 0x7f
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
	ld de, 0:i3
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

