; =============================================================================
; AC/Listener Widget Handlers & TtMd Routines (1.9K lines)
; =============================================================================
;
; AcLswFuncBoxProc event dispatch, parameter processing, mixer
; controls, button handlers, and TtMd (title mode) exclusion
; routines. Sits between computer interface config and SysEx.
; =============================================================================



AcLswFuncBoxProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, 0x1c00018
	jrl z, AcLswBox_HandleScrollDownEvt
	cp xbc, 0x1c0001a
	jrl z, AcLswBox_HandleScrollUpEvt
	cp xbc, 0x1c00017
	jrl z, AcLswBox_HandleDialDecEvt
	cp xbc, 0x1c00019
	jrl z, AcLswBox_HandleDialIncEvt
	cp xbc, 0x1c0001c
	jrl z, AcLswBox_HandleValueChange
	cp xbc, 0x1c0000c
	jrl z, AcLswBox_HandleGetLsw
	cp xbc, 0x1c0000b
	jrl z, AcLswBox_HandleGetLsw
	cp xbc, 0x1c00002
	jrl z, AcLswBox_HandleResetFilter
	cp xbc, 0x1c00001
	jrl z, AcLswBox_OnCreateEvt
	cp xbc, 0x1e0003d
	jr z, AcLswBox_HandleAdd
	cp xbc, 0x1e0003b
	jr z, AcLswBox_HandlePut
	cp xbc, 0x1e0003a
	jrl nz, AcLswBox_DefaultInherited
	ld xwa, xiz
	call GetViewInstance
	lda xwa, (xhl + 36)
	ld xbc, (xwa)
	cpw (xbc), 0x0
	jr nz, AcLswBox_CheckState1
	ld xwa, 0x2c
	jr AcLswBox_AddOffsetAndPush

AcLswBox_CheckState1:
	ld xwa, (xwa)
	cpw (xwa), 0x1
	jr nz, AcLswBox_PushDefaultStr
	ld xwa, 0x28

AcLswBox_AddOffsetAndPush:
	add xhl, xwa
	ld xwa, (xhl)
	push xwa
	jr AcLswBox_StrcpyAndReturn

AcLswBox_PushDefaultStr:
	pushw 0xe7
	pushw 0xf93c

AcLswBox_StrcpyAndReturn:
	ld	xwa, (xsp+8)
	push	xwa
	call	16713584
	inc	8, xsp
	jrl	330
AcLswBox_HandlePut:
	ld xwa, xiz
	call GetViewInstance
	ld xbc, (xsp + 4)
	ld xwa, (xhl + 48)
	ld de, (xhl + 52)
	call MainLswPut
	jrl AudioMix_ReturnZeroJmp2

AcLswBox_HandleAdd:
	ld xwa, xiz
	call GetViewInstance
	ld xbc, (xsp + 4)
	ld xwa, (xhl + 48)
	ld de, (xhl + 52)
	call MainLswAdd
	jrl AudioMix_ReturnZeroJmp2

AcLswBox_OnCreateEvt:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xbc, (xhl + 48)
	ld xwa, xiz
	call SetLswFilter
	jrl AudioMix_ReturnZeroJmp2

AcLswBox_HandleResetFilter:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xbc, (xhl + 48)
	ld xwa, xiz
	call ResetLswFilter
	jrl AudioMix_ReturnZeroJmp2

AcLswBox_HandleGetLsw:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 48)
	call MainLswGet
	jrl AudioMix_ReturnZeroJmp2

AcLswBox_HandleValueChange:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xde, (xsp + 4)
	ld xwa, (xde)
	cp xwa, (xhl + 48)
	jrl nz, AudioMix_ReturnZeroJmp2
	ld xbc, (xhl + 36)
	ld wa, (xde + 4)
	ld (xbc), wa
	ld xwa, xiz
	ld xbc, 0x1c0000f
	ld xde, 0:i3
	jrl AudioMix_SendEventAlt

AcLswBox_HandleDialIncEvt:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jrl z, AudioMix_ReturnZeroJmp2
	ld xwa, xiz
	ld xbc, 0x1e0003d
	ld xde, 1:i3
	jr AudioMix_SendEventAlt

AcLswBox_HandleDialDecEvt:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AudioMix_ReturnZeroJmp2
	ld xwa, xiz
	ld xbc, 0x1e0003d
	ld xde, 1:i3
	jr AudioMix_SendEventAlt

AcLswBox_HandleScrollUpEvt:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AudioMix_ReturnZeroJmp2
	ld xwa, xiz
	ld xbc, 0x1e0003d
	ld xde, 0xffffffff
	jr AudioMix_SendEventAlt

AcLswBox_HandleScrollDownEvt:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AudioMix_ReturnZeroJmp2
	ld xwa, xiz
	ld xbc, 0x1e0003d
	ld xde, 0xffffffff

AudioMix_SendEventAlt:
	call SendEvent

AudioMix_ReturnZeroJmp2:
	ld xhl, 0:i3
	jr AcLswBox_ReturnEpilogue

AcLswBox_DefaultInherited:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc

AcLswBox_ReturnEpilogue:
	pop xiz
	inc 4, xsp
	ret

TtMdRealMsg:
	cp xbc, 0x1c0000c
	jr z, TtMdRealMsg_ReturnZero
	cp xbc, 0x1c0000b
	jr z, TtMdRealMsg_ReturnZero
	cp xbc, 0x1c00002
	jr z, TtMdRealMsg_ReturnZero
	cp xbc, 0x1c00001
	jr nz, TtMdRealMsg_ReturnZero
	or xde, xde
	jr nz, TtMdRealMsg_ReturnZero
	ld xwa, 0x530002
	call GetViewInstance
	ld xwa, (xhl + 46)
	ldw (xwa), 0x1
	ld xwa, 0x530003
	call GetViewInstance
	ld xwa, (xhl + 46)
	ldw (xwa), 0x0

TtMdRealMsg_ReturnZero:
	ld xhl, 0:i3
	ret

AcLswFuncEditBoxProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, 0x1c00018
	jrl z, AcLswEdit_HandleScrollDownEvt
	cp xbc, 0x1c0001a
	jrl z, AcLswEdit_HandleScrollUpEvt
	cp xbc, 0x1c00017
	jrl z, AcLswEdit_HandleDialDecEvt
	cp xbc, 0x1c00019
	jrl z, AcLswEdit_HandleDialIncEvt
	cp xbc, 0x1c0001c
	jrl z, AcLswEdit_HandleValueChange
	cp xbc, 0x1c0000c
	jrl z, AcLswEdit_HandleGetLsw
	cp xbc, 0x1c0000b
	jrl z, AcLswEdit_HandleGetLsw
	cp xbc, 0x1c00002
	jrl z, AcLswEdit_HandleResetFilter
	cp xbc, 0x1c00001
	jrl z, AcLswEdit_HandleCreate
	cp xbc, 0x1e0003d
	jr z, AcLswEdit_HandleAdd
	cp xbc, 0x1e0003b
	jr z, AcLswEdit_HandlePut
	cp xbc, 0x1e0003a
	jrl nz, AcLswEdit_DefaultInherited
	ld xwa, xiz
	call GetViewInstance
	lda xwa, (xhl + 50)
	ld xbc, (xwa)
	cpw (xbc), 0x0
	jr nz, AcLswEdit_CheckState1
	ld xwa, 0x3a
	jr AcLswEdit_AddOffsetAndPush

AcLswEdit_CheckState1:
	ld xwa, (xwa)
	cpw (xwa), 0x1
	jr nz, AcLswEdit_PushDefaultStr
	ld xwa, 0x36

AcLswEdit_AddOffsetAndPush:
	add xhl, xwa
	ld xwa, (xhl)
	push xwa
	jr AcLswEdit_StrcpyAndReturn

AcLswEdit_PushDefaultStr:
	pushw 0xe7
	pushw 0xf942

AcLswEdit_StrcpyAndReturn:
	ld	xwa, (xsp+8)
	push	xwa
	call	16713584
	inc	8, xsp
	jrl	330
AcLswEdit_HandlePut:
	ld xwa, xiz
	call GetViewInstance
	ld xbc, (xsp + 4)
	ld xwa, (xhl + 62)
	ld de, (xhl + 66)
	call MainLswPut
	jrl AudioMix_ReturnZeroJmp

AcLswEdit_HandleAdd:
	ld xwa, xiz
	call GetViewInstance
	ld xbc, (xsp + 4)
	ld xwa, (xhl + 62)
	ld de, (xhl + 66)
	call MainLswAdd
	jrl AudioMix_ReturnZeroJmp

AcLswEdit_HandleCreate:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xbc, (xhl + 62)
	ld xwa, xiz
	call SetLswFilter
	jrl AudioMix_ReturnZeroJmp

AcLswEdit_HandleResetFilter:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xbc, (xhl + 62)
	ld xwa, xiz
	call ResetLswFilter
	jrl AudioMix_ReturnZeroJmp

AcLswEdit_HandleGetLsw:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 62)
	call MainLswGet
	jrl AudioMix_ReturnZeroJmp

AcLswEdit_HandleValueChange:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xde, (xsp + 4)
	ld xwa, (xde)
	cp xwa, (xhl + 62)
	jrl nz, AudioMix_ReturnZeroJmp
	ld xbc, (xhl + 50)
	ld wa, (xde + 4)
	ld (xbc), wa
	ld xwa, xiz
	ld xbc, 0x1c0000f
	ld xde, 0:i3
	jrl AudioMix_SendEvent

AcLswEdit_HandleDialIncEvt:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e0003c
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jrl z, AudioMix_ReturnZeroJmp
	ld xwa, xiz
	ld xbc, 0x1e0003d
	ld xde, 1:i3
	jr AudioMix_SendEvent

AcLswEdit_HandleDialDecEvt:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e0003c
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AudioMix_ReturnZeroJmp
	ld xwa, xiz
	ld xbc, 0x1e0003d
	ld xde, 1:i3
	jr AudioMix_SendEvent

AcLswEdit_HandleScrollUpEvt:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e0003c
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AudioMix_ReturnZeroJmp
	ld xwa, xiz
	ld xbc, 0x1e0003d
	ld xde, 0xffffffff
	jr AudioMix_SendEvent

AcLswEdit_HandleScrollDownEvt:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e0003c
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AudioMix_ReturnZeroJmp
	ld xwa, xiz
	ld xbc, 0x1e0003d
	ld xde, 0xffffffff

AudioMix_SendEvent:
	call SendEvent

AudioMix_ReturnZeroJmp:
	ld xhl, 0:i3
	jr AcLswEdit_Epilogue

AcLswEdit_DefaultInherited:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc

AcLswEdit_Epilogue:
	pop xiz
	inc 4, xsp
	ret

; =============================================================================
; TtFadeInOut - Fade-in/fade-out state machine handler
;
; Event-driven handler for managing fade animation lifecycle.
; Responds to create (0x01), suspend (0x0b), re-enable (0x02),
; and destroy (0x0c) events. On create, initializes animation state
; variables at workspace offsets +42 and +46 to 1 (start animation).
;
; Input:
;   XWA = workspace ID (0xd80001)
;   XBC = event code
;   XDE = event parameter (must be 0 for create)
;
; Used by: Entertainer mode tone fade effects (TT_ETFADEIN)
; =============================================================================
TtFadeInOut:
	cp xbc, 0x1c0000c
	jr z, TtFadeInOut_ReturnZero
	cp xbc, 0x1c0000b
	jr z, TtFadeInOut_ReturnZero
	cp xbc, 0x1c00002
	jr z, TtFadeInOut_ReturnZero
	cp xbc, 0x1c00001
	jr nz, TtFadeInOut_ReturnZero
	or xde, xde
	jr nz, TtFadeInOut_ReturnZero
	ld xwa, 0xd80001
	call GetViewInstance
	ld xwa, (xhl + 42)
	ldw (xwa), 0x1
	ld xwa, (xhl + 46)
	ldw (xwa), 0x1

TtFadeInOut_ReturnZero:
	ld xhl, 0:i3
	ret

; =============================================================================
; AcFadeSetGridBoxProc - Grid-based fade effect processor
;
; Complex event-driven handler implementing grid-based screen fade transitions.
; Uses two lookup tables for fade timing/interpolation:
;   0xe7f948 - Fade-in grid timing table
;   0xe7f956 - Fade-out grid timing table
; Jump table at 0xe7f964 dispatches to 7 sub-handlers (events 0x17-0x1d).
;
; Handles events:
;   0x1c00001 - Create: initialize grid box, set up animation parameters
;   0x1c00017-0x1c0001d - Animation step events (via jump table)
;   0x1e0008a - Get property at workspace offset +0x3e
;   0x1e0008b - Get property at workspace offset +0x42
;   0x1e0008d - Forward to child widget handler
;   0x1e0008f - Query animation progress counter
;   0x1e00050 - Check fade-in progress
;   0x1e00091 - Check fade-out progress
;
; The grid effect divides the screen into cells and fades them
; individually with staggered timing for a "dissolve" appearance.
; =============================================================================
AcFadeSetGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xde
	ld (xsp + 16), xbc
	ld xiz, xwa
	ld xbc, (xsp + 16)
	cp xbc, 0x1e0008d
	jrl z, VoiceUI_GridCase2
	ld xwa, (xsp + 16)
	cp xwa, 0x1e0008b
	jrl z, VoiceUI_GridCase1
	cp xwa, 0x1e0008a
	jrl z, VoiceUI_GridCase0
	cp xwa, 0x1c00001
	jr z, VoiceParam_ListHandler
	sub xbc, 0x1c00017
	cp xbc, 0x0
	jrl lt, VoiceUI_GridCase3
	cp xbc, 0x6
	jrl gt, VoiceUI_GridCase3
	add xbc, xbc
	add xbc, NakaInst_OFF_WidgetTbl2_0x4E
	ld bc, (xbc)
	lda xix, (VoiceParam_ListHandler:24)
	jp_ind 8, 0x07, 0xf0, 0xe4

; Voice parameter list handler
VoiceParam_ListHandler:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	ld xbc, 0x1e0008f
	ld xde, 0:i3
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1c00017
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1c00018
	call SetDialDown
	ld wa, 1:i3
	jrl FadeGrid_SetDialEnable
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, FadeGrid_CheckFadeOut
	ld xwa, xiz
	ld xbc, 0x1e0008f
	ld xde, 0:i3
	call SendEvent
	cp hl, 1:i3
	jrl le, AudioMix_ReturnZeroJmp3
	ld wa, hl
	add wa, wa
	lda xbc, (NakaInst_OFF_WidgetTbl2_0x32:24)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	sub hl, wa
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, 0x1c0000e
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl AudioMix_ReturnZeroJmp3

FadeGrid_CheckFadeOut:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, AudioMix_ReturnZeroJmp3
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	call SetDialDown
	ld wa, 1:i3
	jrl FadeGrid_SetDialEnable
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, FadeGrid_CheckFadeOutAlt
	ld xwa, xiz
	ld xbc, 0x1e0008f
	ld xde, 0:i3
	call SendEvent
	ld wa, hl
	add wa, wa
	lda xbc, (NakaInst_OFF_WidgetTbl2_0x40:24)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	add wa, hl
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, xiz
	ld xbc, 0x1c0000e
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl AudioMix_ReturnZeroJmp3

FadeGrid_CheckFadeOutAlt:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, AudioMix_ReturnZeroJmp3
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	call SetDialDown
	ld wa, 1:i3

FadeGrid_SetDialEnable:
	call SetDialEnable
	jr AudioMix_ReturnZeroJmp3

; Voice UI grid case 0
VoiceUI_GridCase0:
	ld xwa, xiz
	ld xiz, 0x3e
	jr FadeGrid_GetViewAndStrcpy

; Voice UI grid case 1
VoiceUI_GridCase1:
	ld xwa, xiz
	ld xiz, 0x42

FadeGrid_GetViewAndStrcpy:
	call	16408153
	add	xhl, xiz
	ld	xwa, (xhl)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	16713584
	inc	8, xsp
	jr	36
	ld	xwa, xiz
	call	16408153
	ld	xwa, (xhl+70)
	ld	xbc, (xsp+16)
	ld	xde, (xsp+12)
	jr	15
VoiceUI_GridCase2:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)

FadeGrid_ApFuncCallAndReturn:
	call ApFuncCall

AudioMix_ReturnZeroJmp3:
	ld xhl, 0:i3
	jr VoiceUI_GridCase4

; Voice UI grid case 3
VoiceUI_GridCase3:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc

; Voice UI grid case 4
VoiceUI_GridCase4:
	pop xiz
	lda xsp, (xsp + 16)
	ret

; =============================================================================
; FadeSetGridCheck - Validate and initialize grid fade parameters
;
; Copies grid configuration from workspace into local buffers:
;   0xe7f98e - 16-byte grid parameter buffer (8 words from workspace)
;   0xe7ed44 - 8-byte grid config buffer (4 words)
; Dispatches to specific grid effect handlers via jump table at 0xe7f9d2.
;
; Input:
;   XBC = event code (0x1e0008d or 0x1c00017-0x1c0001d)
;   XDE = event parameter
; =============================================================================
FadeSetGridCheck:
	lda xsp, (xsp - 28)
	push xiz
	ld (xsp + 28), xde
	ld xde, xbc
	ld xiy, NakaInst_OFF_WidgetTbl2_0x78
	lda xix, (xsp + 12)
	ldw bc, 0x8
	ldirw
	ld xiy, MidiPart_PageStr_1of3_0xA
	lda xix, (xsp + 4)
	ld bc, 4:i3
	ldirw
	ld xwa, xde
	cp xde, 0x1e0008d
	jrl z, AcInOutGrid_Handler
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, SndParam_ReturnZero2
	cp xwa, 0x6
	jrl gt, SndParam_ReturnZero2
	add xwa, xwa
	add xwa, NakaInst_OFF_WidgetTbl2_0xBC
	ld wa, (xwa)
	lda xix, (Data_FadeSetGridDispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe0
Data_FadeSetGridDispatch:
	call	16400579
	ld	xwa, xhl
	ld	xbc, 31457423
	ld	xde, 0:i3
	call	16421459
	ld	(xsp+28), xhl
	lda	xbc, (xsp+4)
	ld	xwa, (xsp+28)
	srl	xwa, 0
	ld	qwa, 0
	ld	(xbc), wa
	ld	xwa, (xsp+28)
	ld	(xbc+2), wa
	.byte 0x91, 0x3f, 0x01, 0x00
	jrl	nz, 463
	sla	wa, 2
	lda	xbc, (15202674:24)
	ld_rrl	xwa, xbc, wa
	cp	xwa, 4294967295
	jrl	z, 441
	ld	bc, 1:i3
	ld	de, 2:i3
	jr	74
	call	16400579
	ld	xwa, xhl
	ld	xbc, 31457423
	ld	xde, 0:i3
	call	16421459
	ld	(xsp+28), xhl
	lda	xbc, (xsp+4)
	ld	xwa, (xsp+28)
	srl	xwa, 0
	ld	qwa, 0
	ld	(xbc), wa
	ld	xwa, (xsp+28)
	ld	(xbc+2), wa
	.byte 0x91, 0x3f, 0x01, 0x00
	jrl	nz, 388
	sla	wa, 2
	lda	xbc, (15202674:24)
	ld_rrl	xwa, xbc, wa
	cp	xwa, 4294967295
	jrl	z, 366
	ldw	bc, 65535
	ld	de, 2:i3
	call	16381237
	jrl	354
	lda	xhl, (xsp+4)
	ldw	(xhl), 1
	lda	xde, (xhl+2)
	ldw	(xde), 0
	lda	xix, (15202674:24)
	ld	xiz, (xsp+28)
	jr	18
	ld	iy, bc
	sla	iy, 2
	ld	xwa, (xiz)
	.byte 0xe3, 0x07, 0xf0, 0xf4, 0xf0
	jr	z, 10
	inc	1, bc
	ld	(xde), bc
	ld	bc, (xde)
	cp	bc, 7:i3
	jr	lt, -24
	lda	xbc, (xsp+12)
	ld	(xhl+4), xbc
	ld	xwa, (xsp+28)
	ld	xhl, (xwa)
	lda	xde, (xwa+4)
	cp	xhl, 10770
	jr	z, 66
	cp	xhl, 10769
	jr	z, 58
	cp	xhl, 10768
	jr	z, 50
	cp	xhl, 10753
	jr	z, 9
	cp	xhl, 10752
	jrl	nz, 251
	.byte 0x92, 0x04, 0x0b, 0xe7, 0x00, 0x0b, 0x9e, 0xf9
	push	xbc
	call	16712341
	lda	xsp, (xsp+10)
	call	16400579
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	214
	ld	xwa, 15202738
	.byte 0x92, 0x3f, 0x00, 0x00
	jr	z, 5
	ld	xwa, 15202732
	push	xwa
	push	xbc
	call	16713584
	inc	8, xsp
	call	16400579
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	173
AcInOutGrid_Handler:
	lda xde, (xsp + 4)
	ld xwa, (xsp + 28)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	ld (xde), wa
	lda xbc, (xde + 2)
	ld xwa, (xsp + 28)
	ld (xbc), wa
	lda xwa, (xsp + 12)
	ld (xde + 4), xwa
	cpw (xde), 0x1
	jrl nz, SndParam_ReturnZero2
	ld wa, (xbc)
	sla wa, 2
	lda xbc, (NakaInst_OFF_WidgetTbl2_0x5C:24)
	ld_sril3 XBC, 0x07, 0xe4, 0xe0
	ld xwa, xbc
	cp xbc, 0x2a12
	jr z, SndParam_FormatAndDisplay
	cp xbc, 0x2a11
	jr z, SndParam_FormatAndDisplay
	cp xbc, 0x2a10
	jr z, SndParam_FormatAndDisplay
	cp xbc, 0x2a01
	jr z, SndParam_LookupAndSendCmd
	cp xbc, 0x2a00
	jr nz, SndParam_ReturnZero2

SndParam_LookupAndSendCmd:
	call	16567398
	pushw	hl
	pushw	231
	pushw	63928
	lda	xwa, (xsp+18)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	call	16400579
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jr	43
SndParam_FormatAndDisplay:
	call	16567398
	lda	xbc, (xsp+12)
	ld	xwa, 15202764
	cp	hl, 0:i3
	jr	z, 5
	ld	xwa, 15202758
SndParam_PushStrAndCopy:
	push	xwa
	push	xbc
	call	16713584
	inc	8, xsp
	call	16400579
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
SndParam_SendEventAndReturn:
	call SendEvent

SndParam_ReturnZero2:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 28)
	ret

TtMdInOut:
	cp xbc, 0x1c0000c
	jr z, TtMdInOut_ReturnZero
	cp xbc, 0x1c0000b
	jr z, TtMdInOut_ReturnZero
	cp xbc, 0x1c00002
	jr z, TtMdInOut_ReturnZero
	cp xbc, 0x1c00001
	jr nz, TtMdInOut_ReturnZero
	or xde, xde
	jr nz, TtMdInOut_ReturnZero
	ld xwa, 0x550001
	call GetViewInstance
	ld xwa, (xhl + 42)
	ldw (xwa), 0x0
	ld xwa, (xhl + 46)
	ldw (xwa), 0x1

TtMdInOut_ReturnZero:
	ld xhl, 0:i3
	ret

AcInOutGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld (xsp + 16), xwa
	ld xbc, (xsp + 12)
	cp xbc, 0x1e0008d
	jrl z, AcInOutGrid_CellSelect
	ld xwa, (xsp + 12)
	cp xwa, 0x1e0008b
	jrl z, AcInOutGrid_GetRowText
	cp xwa, 0x1e0008a
	jrl z, AcInOutGrid_GetColText
	cp xwa, 0x1c00001
	jr z, AcInOutGrid_Init
	sub xbc, 0x1c00017
	cp xbc, 0x0
	jrl lt, AcInOutGrid_Default
	cp xbc, 0x6
	jrl gt, AcInOutGrid_Default
	add xbc, xbc
	add xbc, NakaInst_OFF_WidgetTbl2_0x370
	ld bc, (xbc)
	lda xix, (AcInOutGrid_Init:24)
	jp_ind 8, 0x07, 0xf0, 0xe4
AcInOutGrid_Init:
	ld	xwa, (xsp+16)
	ld	xbc, (xsp+12)
	ld	xde, (xsp+8)
	call	16400380
	ld	xwa, (xsp+16)
	call	16408153
	ld	(xsp+4), xhl
	ld	xwa, (xsp+16)
	ld	xbc, 31457423
	ld	xde, 0:i3
	call	16421459
	ld	xiz, xhl
	ld	xwa, (xsp+4)
	ld	bc, (xwa+26)
	ld	xwa, xiz
	srl	xwa, 0
	ld	qwa, 0
	add	wa, bc
	ld	de, wa
	extz	xde
	ld	xwa, (xsp+16)
	ld	xbc, 29360151
	call	16359788
	ld	xwa, (xsp+4)
	ld	bc, (xwa+26)
	ld	xwa, xiz
	srl	xwa, 0
	ld	qwa, 0
	add	wa, bc
	ld	de, wa
	extz	xde
	ld	xwa, (xsp+16)
	ld	xbc, 29360152
	call	16359805
	ld	wa, 1:i3
	jrl	471
	ld	xwa, (xsp+16)
	ld	xbc, (xsp+12)
	ld	xde, (xsp+8)
	call	16400380
	ld	xwa, (xsp+16)
	ld	xbc, 31457360
	ld	xde, (xsp+8)
	call	16421459
	or	xhl, xhl
	jr	z, 119
	ld	xwa, (xsp+16)
	ld	xbc, 31457423
	ld	xde, 0:i3
	call	16421459
	ld	iz, hl
	ld	xwa, 20480
	call	16567398
	ld	wa, iz
	add	wa, wa
	cp	hl, 0:i3
	jr	nz, 34
	lda	xbc, (15202784:24)
	ld_rrw	wa, xbc, wa
	ld	bc, iz
	sub	bc, wa
	ld	de, bc
	extz	xde
	add	xde, 4294901760
	ld	xwa, (xsp+16)
	ld	xbc, 29360142
	jr	32
AcInOutGrid_ScrollUp_AltTable:
	lda xbc, (NakaInst_OFF_WidgetTbl2_0xDC:24)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	ld bc, iz
	sub bc, wa
	ld de, bc
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0000e

AcInOutGrid_ScrollUp_Dispatch:
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	jrl AcInOutGrid_ReturnZero

AcInOutGrid_ScrollUp_CheckAlt:
	ld	xwa, (xsp+16)
	ld	xbc, 31457425
	ld	xde, (xsp+8)
	call	SendEvent
	or	xhl, xhl
	jrl	z, 410	; -> 0xF75669
	ld	xwa, (xsp+16)
	call	GetViewInstance
	ld	xwa, (xhl+70)
	ld	xbc, (xsp+12)
	ld	xde, (xsp+8)
	call	ApFuncCall
	ld	xwa, (xsp+16)
	ld	xbc, (xsp+12)
	ld	xde, (xsp+8)
	call	SetAutoInc
	ld	xwa, (xsp+16)
	ld	xbc, 29360151
	ld	xde, (xsp+8)
	call	SetDialUp
	ld	xwa, (xsp+16)
	ld	xbc, 29360152
	ld	xde, (xsp+8)
	call	SetDialDown
	ld	wa, 1:i3
	jrl	232	; -> 0xF755FB
	ld	xwa, (xsp+16)
	ld	xbc, (xsp+12)
	ld	xde, (xsp+8)
	call	InheritedProc
	ld	xwa, (xsp+16)
	ld	xbc, 31457360
	ld	xde, (xsp+8)
	call	SendEvent
	or	xhl, xhl
	jr	z, 115	; -> 0xF755A6
	ld	xwa, (xsp+16)
	ld	xbc, 31457423
	ld	xde, 0:i3
	call	SendEvent
	ld	iz, hl
	ld	xwa, 20480
	call	16567398
	ld	wa, iz
	add	wa, wa
	cp	hl, 0:i3
	jr	nz, 32	; -> 0xF75574
	lda	xbc, (15202820:24)
	ld_rrw	wa, xbc, wa
	add	wa, iz
	ld	de, wa
	extz	xde
	add	xde, 4294901760
	ld	xwa, (xsp+16)
	ld	xbc, 29360142
	jr	30	; -> 0xF75592
AcInOutGrid_ScrollDown_AltTable:
	lda xbc, (NakaInst_OFF_WidgetTbl2_0x100:24)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	add wa, iz
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0000e

AcInOutGrid_ScrollDown_Dispatch:
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	jrl AcInOutGrid_ReturnZero

AcInOutGrid_ScrollDown_CheckAlt:
	ld xwa, (xsp + 16)
	ld xbc, 0x1e00091
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jrl z, AcInOutGrid_ReturnZero
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call ApFuncCall
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00017
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00018
	ld xde, (xsp + 8)
	call SetDialDown
	ld wa, 1:i3

AcInOutGrid_SetScrollBounds:
	call SetDialEnable
	jr AcInOutGrid_ReturnZero

AcInOutGrid_GetColText:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 62)
	push xwa
	jr AcInOutGrid_Strcpy

AcInOutGrid_GetRowText:
	ld	xwa, 20480
	call	16567398
	cp	hl, 2:i3
	jr	z, 22
	cp	hl, 1:i3
	jr	z, 11
	cp	hl, 0:i3
	jr	nz, 70
	ld	xwa, 15202856
	jr	12
AcInOutGrid_GetRowText_Src1:
	ld xwa, NakaInst_OFF_WidgetTbl2_0x1CC
	jr AcInOutGrid_GetRowText_Push

AcInOutGrid_GetRowText_Src2:
	ld xwa, NakaInst_OFF_WidgetTbl2_0x29E

AcInOutGrid_GetRowText_Push:
	push xwa

AcInOutGrid_Strcpy:
	ld	xwa, (xsp+12)
	push	xwa
	call	16713584
	inc	8, xsp
	jr	38
	ld	xwa, (xsp+16)
	call	16408153
	ld	xwa, (xhl+70)
	ld	xbc, (xsp+12)
	ld	xde, (xsp+8)
	jr	16
AcInOutGrid_CellSelect:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)

AcInOutGrid_CellSelect_Call:
	call ApFuncCall

AcInOutGrid_ReturnZero:
	ld xhl, 0:i3
	jr AcInOutGrid_Epilogue

AcInOutGrid_Default:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc

AcInOutGrid_Epilogue:
	pop xiz
	lda xsp, (xsp + 16)
	ret

InOutGridCheck:
	lda xsp, (xsp - 24)
	push xiz
	ld xiz, xde
	ld xde, xbc
	ld xiy, NakaInst_DIRECT_E7FCE4_0xA
	lda xix, (xsp + 12)
	ldw bc, 0x8
	ldirw
	ld xiy, MidiPart_PageStr_1of3_0xA
	lda xix, (xsp + 4)
	ld bc, 4:i3
	ldirw
	ld xwa, xde
	lda xbc, (xsp + 12)
	cp xde, 0x1e0008d
	jrl z, ParaLoadOpt_Entry
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, MdPreset_ReturnZero2
	cp xwa, 0x6
	jrl gt, MdPreset_ReturnZero2
	add xwa, xwa
	add xwa, NakaInst_DIRECT_E7FCE4_0x8C
	ld wa, (xwa)
	lda xix, (Data_InOutGridDispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

Data_InOutGridDispatch:
	; framing ported from v10's source for the same label (same span length, statement for statement); 308 of 360 slots byte-identical
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 31457423
	ld	xde, 0:i3
	call	SendEvent
	ld	xiz, xhl
	lda	xwa, (xsp+4)
	ld	xbc, xiz
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	bc, iz
	ld	(xwa+2), bc
	cpw	(xwa), 1
	jrl	nz, 1774
	cp	bc, 0:i3
	jrl	mi, 1769
	cp	bc, 8
	jrl	gt, 1762
	add	bc, bc
	lda	xix, (NakaInst_DIRECT_E7FCE4_0x7A:24)
	ld_rrw	bc, xix, bc
	lda	xix, (16209704:24)
	jp_rr	8, xix, bc
	ld	xwa, 8448
	ld	bc, 1:i3
	ld	de, 1:i3
	jrl	316
	ld	xwa, 8449
	ld	bc, 1:i3
	ld	de, 1:i3
	jrl	304
	ld	xwa, 20480
	ld	bc, 1:i3
	ld	de, 1:i3
	jrl	292
	ld	xwa, 20480
	call	16567398
	cp	hl, 2:i3
	jr	z, 17
	cp	hl, 1:i3
	jrl	nz, 1686
	ld	xwa, 20481
	ld	bc, 1:i3
	ld	de, 1:i3
	jrl	262
	ld	xwa, 20482
	ld	bc, 1:i3
	ld	de, 1:i3
	jrl	250
	ld	xwa, 8577
	ld	bc, 1:i3
	ld	de, 1:i3
	jrl	238
	ld	xwa, 8580
	ld	bc, 1:i3
	.byte 0xda	; v10 does not spell this byte either
	.byte 0xa9	; v10 does not spell this byte either
	.byte 0x78	; v10 does not spell this byte either
	.byte 0xe2	; v10 does not spell this byte either
	.byte 0x00	; v10 does not spell this byte either
	ld	xwa, 8578
	ld	bc, 1:i3
	ld	de, 1:i3
	jrl	214
	ld	xwa, 8579
	ld	bc, 1:i3
	ld	de, 1:i3
	jrl	202
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 31457423
	ld	xde, 0:i3
	call	SendEvent
	ld	xiz, xhl
	lda	xwa, (xsp+4)
	ld	xbc, xiz
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	bc, iz
	ld	(xwa+2), bc
	cpw	(xwa), 1
	jrl	nz, 1570
	cp	bc, 0:i3
	jrl	mi, 1565
	cp	bc, 8
	jrl	gt, 1558
	add	bc, bc
	lda	xix, (NakaInst_DIRECT_E7FCE4_0x68:24)
	ld_rrw	bc, xix, bc
	lda	xix, (16209908:24)
	jp_rr	8, xix, bc
	ld	xwa, 8448
	ldw	bc, 65535
	ld	de, 1:i3
	jr	112
	ld	xwa, 8449
	ldw	bc, 65535
	ld	de, 1:i3
	jr	100
	ld	xwa, 20480
	ldw	bc, 65535
	ld	de, 1:i3
	jr	88
	ld	xwa, 20480
	call	16567398
	cp	hl, 2:i3
	jr	z, 17
	cp	hl, 1:i3
	jrl	nz, 1482
	ld	xwa, 20481
	ldw	bc, 65535
	ld	de, 1:i3
	jr	58
	ld	xwa, 20482
	ldw	bc, 65535
	ld	de, 1:i3
	jr	46
	ld	xwa, 8577
	ldw	bc, 65535
	ld	de, 1:i3
	jr	34
	ld	xwa, 8580
	ldw	bc, 65535
	ld	de, 1:i3
	jr	22
	ld	xwa, 8578
	ldw	bc, 65535
	ld	de, 1:i3
	jr	10
	ld	xwa, 8579
	ldw	bc, 65535
	ld	de, 1:i3
	call	MainLswAdd
	jrl	1405
	lda	xwa, (xsp+4)
	ldw	(xwa), 1
	ld	xde, xbc
	ld	(xwa+4), xbc
	ld	xix, (xiz)
	lda	xbc, (xwa+2)
	lda	xhl, (NakaInst_OFF_WidgetTbl2_0x37E:24)
	cp	xix, 8579
	jrl	z, 612
	cp	xix, 8578
	jrl	z, 563
	cp	xix, 8580
	jrl	z, 514
	lda	xwa, (xiz+4)
	cp	xix, 8577
	jrl	z, 463
	cp	xix, 20482
	jrl	z, 382
	cp	xix, 20481
	jrl	z, 298
	cp	xix, 20480
	jr	z, 100
	cp	xix, 8449
	jr	z, 53
	cp	xix, 8448
	jrl	nz, 1301
	ldw	(xbc), 0
	ld	wa, (xwa)
	sla	wa, 2
	lda	xbc, (NakaInst_OFF_E7FCA2_0x6:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	push	xde
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	1253
	ldw	(xbc), 1
	ld	wa, (xwa)
	sla	wa, 2
	ld_rrl	xwa, xhl, wa
	push	xwa
	push	xde
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	1214
	ld	xix, xwa
	ld	wa, (xwa)
	lda	xhl, (ControlMode_Option_Table_0xA:24)
	cp	wa, 2:i3
	jr	z, 121
	cp	wa, 1:i3
	jr	z, 61
	cp	wa, 0:i3
	jrl	nz, 1196
	ldw	(xbc), 2
	ld	wa, (xix)
	sla	wa, 2
	ld_rrl	xwa, xhl, wa
	push	xwa
	push	xde
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	call	SendEvent
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 29360140
	ld	xde, 0:i3
	jrl	1136
	ldw	(xbc), 2
	ld	wa, (xix)
	sla	wa, 2
	ld_rrl	xwa, xhl, wa
	push	xwa
	push	xde
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	call	SendEvent
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 29360140
	ld	xde, 0:i3
	jrl	1080
	ldw	(xbc), 2
	ld	wa, (xix)
	sla	wa, 2
	ld_rrl	xwa, xhl, wa
	push	xwa
	push	xde
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	call	SendEvent
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 29360140
	ld	xde, 0:i3
	jrl	1024
	ldw	(xbc), 3
	ld	xwa, 20480
	call	16567398
	cp	hl, 1:i3
	jr	nz, 25
	ld	wa, (xiz+4)
	exts	wa
	pushw	wa
	pushw	231
	pushw	64766
	lda	xwa, (xsp+18)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	jr	16
	pushw	231
	pushw	64772
	lda	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	949
	ldw	(xbc), 3
	ld	xwa, 20480
	call	16567398
	cp	hl, 2:i3
	jr	nz, 22
	.byte 0x9e	; v10 does not spell this byte either
	.byte 0x04	; v10 does not spell this byte either
	.byte 0x04	; v10 does not spell this byte either
	pushw	231
	pushw	64778
	lda	xwa, (xsp+18)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	jr	16
	pushw	231
	pushw	64784
	lda	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	877
	ldw	(xbc), 5
	ld	wa, (xwa)
	sla	wa, 2
	ld_rrl	xwa, xhl, wa
	push	xwa
	push	xde
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	838
	ldw	(xbc), 6
	ld	wa, (xiz+4)
	sla	wa, 2
	ld_rrl	xwa, xhl, wa
	push	xwa
	push	xde
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	798
	ldw	(xbc), 7
	ld	wa, (xiz+4)
	sla	wa, 2
	ld_rrl	xwa, xhl, wa
	push	xwa
	push	xde
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	758
	.byte 0xb1	; v10 does not spell this byte either
	push	sr
	ld	(0:8), 158:io
	.byte 0x04	; v10 does not spell this byte either
	ld	a, 217:opc
	.byte 0xec	; v10 does not spell this byte either
	push	sr
	ld_rrl	xwa, xhl, bc
	push	xwa
	push	xde
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	718
ParaLoadOpt_Entry:
	lda xde, (xsp + 4)
	ld xwa, xiz
	srl xwa, 0
	ldiw_erp 0xe2, 0
	ld (xde), wa
	lda xwa, (xde + 2)
	ld hl, iz
	ld (xwa), hl
	ld (xde + 4), xbc
	cpw (xde), 0x1
	jrl nz, MdPreset_ReturnZero2
	ld wa, (xwa)
	cp wa, 0:i3
	jrl mi, MdPreset_ReturnZero2
	cp wa, 0x8
	jrl gt, MdPreset_ReturnZero2
	add wa, wa
	lda xix, (NakaInst_DIRECT_E7FCE4_0x56:24)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda xix, (Data_ParaLoadOptDispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

Data_ParaLoadOptDispatch:
	ld	xwa, 8448
	call	16567398
	sla	hl, 2
	lda	xwa, (15203496:24)
	ld_rrl	xwa, xwa, hl
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	602	; -> 0xF75DF0
	ld	xwa, 8449
	call	16567398
	sla	hl, 2
	lda	xwa, (15203476:24)
	ld_rrl	xwa, xwa, hl
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	552	; -> 0xF75DF0
	ld	xwa, 20480
	call	16567398
	sla	hl, 2
	lda	xwa, (15203524:24)
	ld_rrl	xwa, xwa, hl
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	call	SendEvent
	ld	xwa, 20480
	call	16567398
	cp	hl, 2:i3
	jr	z, 99	; -> 0xF75C6B
	lda	xwa, (xsp+6)
	cp	hl, 1:i3
	jr	z, 42	; -> 0xF75C39
	cp	hl, 0:i3
	jrl	nz, 480	; -> 0xF75DF4
	ldw	(xwa), 3
	pushw	231
	pushw	64790
	lda	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	439	; -> 0xF75DF0
	ldw	(xwa), 3
	ld	xwa, 20481
	call	16567398
	exts	hl
	pushw	hl
	pushw	231
	pushw	64796
	lda	xwa, (xsp+18)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	389	; -> 0xF75DF0
	ldw	(xsp+6), 3
	ld	xwa, 20482
	call	16567398
	pushw	hl
	pushw	231
	pushw	64802
	lda	xwa, (xsp+18)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	340	; -> 0xF75DF0
	ld	xwa, 20480
	call	16567398
	cp	hl, 2:i3
	jr	z, 88	; -> 0xF75D01
	cp	hl, 1:i3
	jr	z, 38	; -> 0xF75CD3
	cp	hl, 0:i3
	jrl	nz, 322	; -> 0xF75DF4
	pushw	231
	pushw	64808
	lda	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	285	; -> 0xF75DF0
	ld	xwa, 20481
	call	16567398
	exts	hl
	pushw	hl
	pushw	231
	pushw	64814
	lda	xwa, (xsp+18)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	239	; -> 0xF75DF0
	ld	xwa, 20482
	call	16567398
	pushw	hl
	pushw	231
	pushw	64820
	lda	xwa, (xsp+18)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	195	; -> 0xF75DF0
	ld	xwa, 8577
	call	16567398
	sla	hl, 2
	lda	xwa, (15203476:24)
	ld_rrl	xwa, xwa, hl
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	145	; -> 0xF75DF0
	ld	xwa, 8580
	call	16567398
	sla	hl, 2
	lda	xwa, (15203476:24)
	ld_rrl	xwa, xwa, hl
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jr	96	; -> 0xF75DF0
	ld	xwa, 8578
	call	16567398
	sla	hl, 2
	lda	xwa, (15203476:24)
	ld_rrl	xwa, xwa, hl
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jr	47	; -> 0xF75DF0
	ld	xwa, 8579
	call	16567398
	sla	hl, 2
	lda	xwa, (15203476:24)
	ld_rrl	xwa, xwa, hl
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	call	SendEvent
MdPreset_ReturnZero2:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 24)
	ret

TtMdPreset:
	cp xbc, 0x1c0000c
	jr z, TtMdPreset_ReturnZero
	cp xbc, 0x1c0000b
	jr z, TtMdPreset_ReturnZero
	cp xbc, 0x1c00002
	jr z, TtMdPreset_ReturnZero
	cp xbc, 0x1c00001
	jr nz, TtMdPreset_ReturnZero
	or xde, xde
	jr nz, TtMdPreset_ReturnZero
	ld xwa, 0x560001
	ld xbc, 0x1e0007f
	ld xde, 1:i3
	call SendEvent

TtMdPreset_ReturnZero:
	ld xhl, 0:i3
	ret

IvMpstPageControlProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld (xsp + 12), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x1c0001e
	jr z, IvMpst_HandlePageSwitch
	cp xwa, 0x1e0003a
	jr z, IvMpst_HandleGetName
	cp xwa, 0x1c0000d
	jr z, IvMpst_HandleClose
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	jrl IvMpst_Epilogue

IvMpst_HandleClose:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0000f
	ld xde, 0:i3
	jrl IvMpst_SendEventEpilogue

IvMpst_HandleGetName:
	pushw	231
	pushw	64894
	ld	xwa, (xsp+8)
	push	xwa
	call	16713584
	inc	8, xsp
	jrl	130
IvMpst_HandlePageSwitch:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 24)
	ld xbc, 0x1e00094
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr z, IvMpst_CheckSecondView
	ld xwa, (xiz + 24)
	ld xbc, 0x1c00002
	ld xde, 0:i3
	call SendEvent

IvMpst_CheckSecondView:
	ld xwa, (xiz + 28)
	ld xbc, 0x1e00094
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr z, IvMpst_InheritAndCheck
	ld xwa, (xiz + 28)
	ld xbc, 0x1c00002
	ld xde, 0:i3
	call SendEvent

IvMpst_InheritAndCheck:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld wa, (xiz + 22)
	exts xwa
	cp xwa, (xsp + 4)
	jr nz, IvMpst_ReturnZero
	cp (0x024756:24), 0x00
	jr nz, IvMpst_ActivateSecondView
	ld xwa, (xiz + 24)
	ld xbc, 0x1c00001
	ld xde, 0:i3
	jr IvMpst_SendEventEpilogue

IvMpst_ActivateSecondView:
	ld xwa, (xiz + 28)
	ld xbc, 0x1c00001
	ld xde, 0:i3

IvMpst_SendEventEpilogue:
	call SendEvent

IvMpst_ReturnZero:
	ld xhl, 0:i3

IvMpst_Epilogue:
	pop xiz
	lda xsp, (xsp + 12)
	ret

MdPresetWithoutFunc:
	push xiz
	cp xbc, 0x1c00007
	jr nz, MdPresetWith_ReturnSuccess
	cp (0x024756:24), 0x00
	jr z, MdPresetWith_ReturnSuccess
	ld (0x024756:24), 0x00
	ld xwa, 0x560001
	ld xbc, 0x1e00056
	ld xde, 0:i3
	call SendEvent
	cp l, 2:i3
	jr z, MdPresetWithout_Slot2Path
	cp l, 1:i3
	jr nz, MdPresetWith_ReturnSuccess
	ld xwa, 0x560004
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 28)
	ld xbc, 0x1c00002
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xiz + 24)
	ld xbc, 0x1c00001
	ld xde, 0:i3
	jr MdPresetWithout_SendCreate

MdPresetWithout_Slot2Path:
	ld xwa, 0x560005
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 28)
	ld xbc, 0x1c00002
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xiz + 24)
	ld xbc, 0x1c00001
	ld xde, 0:i3

MdPresetWithout_SendCreate:
	call SendEvent

MdPresetWith_ReturnSuccess:
	ld xhl, 0:i3
	pop xiz
	ret

MdPresetWithFunc:
	push xiz
	cp xbc, 0x1c00007
	jr nz, MdPreset_ReturnSuccess
	cp (0x024756:24), 0x01
	jr z, MdPreset_ReturnSuccess
	ld (0x024756:24), 0x01
	ld xwa, 0x560001
	ld xbc, 0x1e00056
	ld xde, 0:i3
	call SendEvent
	cp l, 2:i3
	jr z, MdPresetWith_Slot2Path
	cp l, 1:i3
	jr nz, MdPreset_ReturnSuccess
	ld xwa, 0x560004
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 24)
	ld xbc, 0x1c00002
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xiz + 28)
	ld xbc, 0x1c00001
	ld xde, 0:i3
	jr MdPresetWith_SendCreate

MdPresetWith_Slot2Path:
	ld xwa, 0x560005
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 24)
	ld xbc, 0x1c00002
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xiz + 28)
	ld xbc, 0x1c00001
	ld xde, 0:i3

MdPresetWith_SendCreate:
	call SendEvent

MdPreset_ReturnSuccess:
	ld xhl, 0:i3
	pop xiz
	ret

MdPresetOKFunc:
	ld xhl, xde
	cp xbc, 0x1c00007
	jrl nz, MdPreset_PostMainFunc
	ld xwa, 0x560001
	ld xbc, 0x1e00056
	ld xde, 0:i3
	call SendEvent
	cp l, 4:i3
	jrl z, MdPresetOK_Slot4Path
	cp l, 3:i3
	jrl z, MdPresetOK_Slot3Path
	ld a, (0x024756:24)
	cp l, 2:i3
	jr z, MdPresetOK_CheckSlotB
	cp l, 1:i3
	jrl nz, MdPreset_PostMainFunc
	cp a, 1:i3
	jr z, MdPresetOK_Slot1Func
	cp a, 0:i3
	jrl nz, MdPreset_PostMainFunc
	ld xwa, 0x56000c
	ld xbc, 0x1e00090
	ld xde, 0:i3
	call SendEvent
	add l, 0x44
	ld h, 0x0:opc
	extz xhl
	ld xwa, 0x1430002
	ld xbc, 0x1e30003
	ld xde, xhl
	jrl MdPreset_CallMainFunc

MdPresetOK_Slot1Func:
	ld xwa, 0x560015
	ld xbc, 0x1e00090
	ld xde, 0:i3
	call SendEvent
	add l, 0x4d
	ld h, 0x0:opc
	extz xhl
	ld xwa, 0x1430002
	ld xbc, 0x1e30003
	ld xde, xhl
	jrl MdPreset_CallMainFunc

MdPresetOK_CheckSlotB:
	cp a, 1:i3
	jr z, MdPresetOK_SlotBFunc
	cp a, 0:i3
	jrl nz, MdPreset_PostMainFunc
	ld xwa, 0x56002d
	ld xbc, 0x1e00090
	ld xde, 0:i3
	call SendEvent
	add l, 0x41
	ld h, 0x0:opc
	extz xhl
	ld xwa, 0x1430002
	ld xbc, 0x1e30003
	ld xde, xhl
	jrl MdPreset_CallMainFunc

MdPresetOK_SlotBFunc:
	ld xwa, 0x560039
	ld xbc, 0x1e00090
	ld xde, 0:i3
	call SendEvent
	add l, 0x4a
	ld h, 0x0:opc
	extz xhl
	ld xwa, 0x1430002
	ld xbc, 0x1e30003
	ld xde, xhl
	jr MdPreset_CallMainFunc

MdPresetOK_Slot3Path:
	ld xwa, 0x560020
	ld xbc, 0x1e00090
	ld xde, 0:i3
	call SendEvent
	add l, 0x1b
	ld h, 0x0:opc
	extz xhl
	ld xwa, 0x1430002
	ld xbc, 0x1e30003
	ld xde, xhl
	jr MdPreset_CallMainFunc

MdPresetOK_Slot4Path:
	ld xwa, 0x560029
	ld xbc, 0x1e0006b
	ld xde, 0:i3
	call SendEvent
	ld (0x024758:24), l
	ld xwa, 0x560025
	ld xbc, 0x1e00090
	ld xde, 0:i3
	call SendEvent
	ld h, 0x0:opc
	extz xhl
	ld xwa, 0x1430002
	ld xbc, 0x1e30004
	ld xde, xhl

MdPreset_CallMainFunc:
	call MainFuncCall

MdPreset_PostMainFunc:
	ld xhl, 0:i3
	ret

MainMpstFunc:
	dec	4, xsp
	ld	(xsp), xde
	cp	xbc, 31653892
	jr	z, 40
	cp	xbc, 31653891
	jr	nz, 88
	ld	xwa, (xsp)
	ld	(46928:16), a
	call	16600229
	ld	(32422:16), 35
	ld	xwa, 4294967295
	ld	xbc, 29360150
	ld	xde, 27263214
	jr	52
MainMpst_HandlePresetCopy:
	ld	(32422:16), 37
	ld	xwa, 4294967295
	ld	xbc, 29360150
	ld	xde, 27263214
	call	16423243
	ld	xwa, (xsp)
	extz	wa
	call	16600558
	ld	(32422:16), 35
	ld	xwa, 4294967295
	ld	xbc, 29360150
	ld	xde, 27263214
MainMpst_PostEvent:
	call ApPostEvent

MainMpst_ReturnZero:
	ld xhl, 0:i3
	inc 4, xsp
	ret

MainMpst_ReadPresetIndex:
	ld l, (0x024758:24)
	ret

TtMdExc:
	.byte 0xe9, 0xcf, 0x0c, 0x00, 0xc0, 0x01, 0x66, 0x3a
	.byte 0xe9, 0xcf, 0x0b, 0x00, 0xc0, 0x01, 0x66, 0x32
	.byte 0xe9, 0xcf, 0x02, 0x00, 0xc0, 0x01, 0x66, 0x22
	.byte 0xe9, 0xcf, 0x01, 0x00, 0xc0, 0x01, 0x6e, 0x22
	.byte 0xea, 0xe2, 0x6e, 0x1e, 0xf1, 0x46, 0xb7, 0xbe
	.byte 0x40, 0x03, 0x00, 0x57, 0x00, 0x1d, 0x59, 0x5e
	.byte 0xfa, 0xab, 0x26, 0x20, 0xb0, 0x02, 0x00, 0x00
	.byte 0x68, 0x08
TtMdExc_HandleClose:
	.byte 0xea, 0xe2, 0x6e, 0x04, 0xf1, 0x46, 0xb7, 0xb6
TtMdExc_ReturnZero:
	ld xhl, 0:i3
	ret

