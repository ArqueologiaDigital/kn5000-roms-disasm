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
	cp xbc, EVT_INDEXSW_DOWN
	jrl z, AcLswBox_HandleScrollDownEvt
	cp xbc, EVT_INDEXSW_DOWN_AIC
	jrl z, AcLswFuncBoxProc_OnIndexswDownAic
	cp xbc, EVT_INDEXSW_UP
	jrl z, AcLswFuncBoxProc_OnIndexswUp
	cp xbc, EVT_INDEXSW_UP_AIC
	jrl z, AcLswBox_HandleDialIncEvt
	cp xbc, EVT_LSW_DATA
	jrl z, AcLswBox_HandleValueChange
	cp xbc, EVT_REPAINT
	jrl z, AcLswBox_HandleGetLsw
	cp xbc, EVT_PAINT
	jrl z, AcLswBox_HandleGetLsw
	cp xbc, EVT_HIDE
	jrl z, AcLswBox_HandleResetFilter
	cp xbc, EVT_SHOW
	jrl z, AcLswBox_OnCreateEvt
	cp xbc, EVT_CALC_PARAM
	jr z, AcLswBox_HandleAdd
	cp xbc, EVT_SET_PARAM
	jr z, AcLswBox_HandlePut
	cp xbc, EVT_GET_STRING
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
	pushw MdSetupLoadFunc_CaseTable_Strings@hi16
	pushw MdSetupLoadFunc_CaseTable_Strings@lo16

AcLswBox_StrcpyAndReturn:
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	jrl AudioMix_ReturnZeroJmp2

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
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl AudioMix_SendEventAlt

AcLswBox_HandleDialIncEvt:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jrl z, AudioMix_ReturnZeroJmp2
	ld xwa, xiz
	ld xbc, EVT_CALC_PARAM
	ld xde, 1:i3
	jr AudioMix_SendEventAlt

AcLswFuncBoxProc_OnIndexswUp:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AudioMix_ReturnZeroJmp2
	ld xwa, xiz
	ld xbc, EVT_CALC_PARAM
	ld xde, 1:i3
	jr AudioMix_SendEventAlt

AcLswFuncBoxProc_OnIndexswDownAic:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AudioMix_ReturnZeroJmp2
	ld xwa, xiz
	ld xbc, EVT_CALC_PARAM
	ld xde, 0xffffffff
	jr AudioMix_SendEventAlt

AcLswBox_HandleScrollDownEvt:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AudioMix_ReturnZeroJmp2
	ld xwa, xiz
	ld xbc, EVT_CALC_PARAM
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
	cp xbc, EVT_REPAINT
	jr z, TtMdRealMsg_ReturnZero
	cp xbc, EVT_PAINT
	jr z, TtMdRealMsg_ReturnZero
	cp xbc, EVT_HIDE
	jr z, TtMdRealMsg_ReturnZero
	cp xbc, EVT_SHOW
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
	cp xbc, EVT_INDEXSW_DOWN
	jrl z, AcLswEdit_HandleScrollDownEvt
	cp xbc, EVT_INDEXSW_DOWN_AIC
	jrl z, AcLswFuncEditBoxProc_OnIndexswDownAic
	cp xbc, EVT_INDEXSW_UP
	jrl z, AcLswFuncEditBoxProc_OnIndexswUp
	cp xbc, EVT_INDEXSW_UP_AIC
	jrl z, AcLswEdit_HandleDialIncEvt
	cp xbc, EVT_LSW_DATA
	jrl z, AcLswEdit_HandleValueChange
	cp xbc, EVT_REPAINT
	jrl z, AcLswEdit_HandleGetLsw
	cp xbc, EVT_PAINT
	jrl z, AcLswEdit_HandleGetLsw
	cp xbc, EVT_HIDE
	jrl z, AcLswEdit_HandleResetFilter
	cp xbc, EVT_SHOW
	jrl z, AcLswEdit_HandleCreate
	cp xbc, EVT_CALC_PARAM
	jr z, AcLswEdit_HandleAdd
	cp xbc, EVT_SET_PARAM
	jr z, AcLswEdit_HandlePut
	cp xbc, EVT_GET_STRING
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
	pushw AcLswEdit_PushDefaultStr_Str_Error@hi16
	pushw AcLswEdit_PushDefaultStr_Str_Error@lo16

AcLswEdit_StrcpyAndReturn:
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	jrl AudioMix_ReturnZeroJmp

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
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl AudioMix_SendEvent

AcLswEdit_HandleDialIncEvt:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jrl z, AudioMix_ReturnZeroJmp
	ld xwa, xiz
	ld xbc, EVT_CALC_PARAM
	ld xde, 1:i3
	jr AudioMix_SendEvent

AcLswFuncEditBoxProc_OnIndexswUp:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AudioMix_ReturnZeroJmp
	ld xwa, xiz
	ld xbc, EVT_CALC_PARAM
	ld xde, 1:i3
	jr AudioMix_SendEvent

AcLswFuncEditBoxProc_OnIndexswDownAic:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AudioMix_ReturnZeroJmp
	ld xwa, xiz
	ld xbc, EVT_CALC_PARAM
	ld xde, 0xffffffff
	jr AudioMix_SendEvent

AcLswEdit_HandleScrollDownEvt:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AudioMix_ReturnZeroJmp
	ld xwa, xiz
	ld xbc, EVT_CALC_PARAM
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
	cp xbc, EVT_REPAINT
	jr z, TtFadeInOut_ReturnZero
	cp xbc, EVT_PAINT
	jr z, TtFadeInOut_ReturnZero
	cp xbc, EVT_HIDE
	jr z, TtFadeInOut_ReturnZero
	cp xbc, EVT_SHOW
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
	cp xbc, EVT_REQUEST_GRID_DRAW
	jrl z, VoiceUI_GridCase2
	ld xwa, (xsp + 16)
	cp xwa, EVT_GET_FIXED_ROW_STR
	jrl z, VoiceUI_GridCase1
	cp xwa, EVT_GET_FIXED_COL_STR
	jrl z, VoiceUI_GridCase0
	cp xwa, EVT_SHOW
	jr z, VoiceParam_ListHandler
	sub xbc, EVT_INDEXSW_UP
	cp xbc, 0x0
	jrl lt, VoiceUI_GridCase3
	cp xbc, 0x6
	jrl gt, VoiceUI_GridCase3
	add xbc, xbc
	add xbc, AcFadeSetGridBoxProc_CaseTable
	ld bc, (xbc)
	lda xix, (VoiceParam_ListHandler:24)
	jp	t, (xix+bc)

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
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 16
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_UP
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 16
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_DOWN
	call SetDialDown
	ld wa, 1:i3
	jrl FadeGrid_SetDialEnable
AcFadeSetGridBoxProc_OnIndexswUp:	; cases 29360151, 29360153
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, FadeGrid_CheckFadeOut
	ld xwa, xiz
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	cp hl, 1:i3
	jrl le, AudioMix_ReturnZeroJmp3
	ld wa, hl
	add wa, wa
	lda xbc, (VoiceParam_ListHandler_Table:24)
	ld	wa, (xbc+wa)
	sub hl, wa
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, EVT_SELE_DRAW
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl AudioMix_ReturnZeroJmp3

FadeGrid_CheckFadeOut:
	ld xwa, xiz
	ld xbc, EVT_CHECK_GRID_INDEX
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
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 12)
	call SetDialDown
	ld wa, 1:i3
	jrl FadeGrid_SetDialEnable
AcFadeSetGridBoxProc_OnIndexswDown:	; cases 29360152, 29360154
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, FadeGrid_CheckFadeOutAlt
	ld xwa, xiz
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld wa, hl
	add wa, wa
	lda xbc, (VoiceParam_ListHandler_Table_2:24)
	ld	wa, (xbc+wa)
	add wa, hl
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, xiz
	ld xbc, EVT_SELE_DRAW
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl AudioMix_ReturnZeroJmp3

FadeGrid_CheckFadeOutAlt:
	ld xwa, xiz
	ld xbc, EVT_CHECK_GRID_INDEX
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
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_DOWN
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
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	jr AudioMix_ReturnZeroJmp3
AcFadeSetGridBoxProc_OnLswData:	; cases 29360156, 29360157
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	jr FadeGrid_ApFuncCallAndReturn

; Voice UI grid case 2
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
	ld xiy, FadeSetGridCheck_LocalInit
	lda xix, (xsp + 12)
	ldw bc, 0x8
	ldirw
	ld xiy, ComSetGridCheck_LocalInit
	lda xix, (xsp + 4)
	ld bc, 4:i3
	ldirw
	ld xwa, xde
	cp xde, EVT_REQUEST_GRID_DRAW
	jrl z, AcInOutGrid_Handler
	sub xwa, EVT_INDEXSW_UP
	cp xwa, 0x0
	jrl lt, SndParam_ReturnZero2
	cp xwa, 0x6
	jrl gt, SndParam_ReturnZero2
	add xwa, xwa
	add xwa, FadeSetGridCheck_CaseTable
	ld wa, (xwa)
	lda xix, (Data_FadeSetGridDispatch:24)
	jp	t, (xix+wa)

Data_FadeSetGridDispatch:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	(xsp+28), xhl
	lda	xbc, (xsp+4)
	ld	xwa, (xsp+28)
	srl	xwa, 16
	ld	qwa, 0
	ld	(xbc), wa
	ld	xwa, (xsp+28)
	ld	(xbc+2), wa
	cpw	(xbc), 1
	jrl	nz, SndParam_ReturnZero2
	sla	wa, 2
	lda	xbc, (Data_FadeSetGridDispatch_Table:24)
	ld	xwa, (xbc+wa)
	cp	xwa, 0xffffffff
	jrl	z, SndParam_ReturnZero2
	ld	bc, 1:i3
	ld	de, 2:i3
	jr	FadeSetGridCheck_Join
FadeSetGridCheck_OnIndexswDown:	; cases 29360152, 29360154
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	(xsp+28), xhl
	lda	xbc, (xsp+4)
	ld	xwa, (xsp+28)
	srl	xwa, 16
	ld	qwa, 0
	ld	(xbc), wa
	ld	xwa, (xsp+28)
	ld	(xbc+2), wa
	cpw	(xbc), 1
	jrl	nz, SndParam_ReturnZero2
	sla	wa, 2
	lda	xbc, (Data_FadeSetGridDispatch_Table:24)
	ld	xwa, (xbc+wa)
	cp	xwa, 0xffffffff
	jrl	z, SndParam_ReturnZero2
	ldw	bc, 0xffff
	ld	de, 2:i3
FadeSetGridCheck_Join:
	call	MainLswAdd
	jrl	SndParam_ReturnZero2
FadeSetGridCheck_OnLswData:	; cases 29360156, 29360157
	lda	xhl, (xsp+4)
	ldw	(xhl), 1
	lda	xde, (xhl+2)
	ldw	(xde), 0
	lda	xix, (Data_FadeSetGridDispatch_Table:24)
	ld	xiz, (xsp+28)
	jr	FadeSetGridCheck_Join2
FadeSetGridCheck_Loop:
	ld	iy, bc
	sla	iy, 2
	ld	xwa, (xiz)
	cp	xwa, (xix+iy)	; the backend cannot spell this form
	jr	z, FadeSetGridCheck_Skip4
	inc	1, bc
	ld	(xde), bc
FadeSetGridCheck_Join2:
	ld	bc, (xde)
	cp	bc, 7:i3
	jr	lt, FadeSetGridCheck_Loop
FadeSetGridCheck_Skip4:
	lda	xbc, (xsp+12)
	ld	(xhl+4), xbc
	ld	xwa, (xsp+28)
	ld	xhl, (xwa)
	lda	xde, (xwa+4)
	cp	xhl, 0x2a12
	jr	z, FadeSetGridCheck_Skip2
	cp	xhl, 0x2a11
	jr	z, FadeSetGridCheck_Skip2
	cp	xhl, 0x2a10
	jr	z, FadeSetGridCheck_Skip2
	cp	xhl, 0x2a01
	jr	z, FadeSetGridCheck_Skip
	cp	xhl, 0x2a00
	jrl	nz, SndParam_ReturnZero2
FadeSetGridCheck_Skip:
	pushm	(xde)
	pushw	FadeSetGridCheck_LocalInit_Strings@hi16
	pushw	FadeSetGridCheck_LocalInit_Strings@lo16
	push	xbc
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jrl	SndParam_SendEventAndReturn
FadeSetGridCheck_Skip2:
	ld	xwa, Data_FadeSetGridDispatch_Str
	cpw	(xde), 0
	jr	z, FadeSetGridCheck_Skip3
	ld	xwa, Data_AcGridParamTable
FadeSetGridCheck_Skip3:
	push	xwa
	push	xbc
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jrl	SndParam_SendEventAndReturn

; AcInOutGrid handler
AcInOutGrid_Handler:
	lda xde, (xsp + 4)
	ld xwa, (xsp + 28)
	srl xwa, 16
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
	lda xbc, (Data_FadeSetGridDispatch_Table:24)
	ld	xbc, (xbc+wa)
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
	call SndParam_LookupReadOnly
	pushw hl
	pushw SndParam_LookupAndSendCmd_Str_Fmt2d_measure@hi16
	pushw SndParam_LookupAndSendCmd_Str_Fmt2d_measure@lo16
	lda xwa, (xsp + 18)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, EVT_GRID_DRAW
	jr SndParam_SendEventAndReturn

SndParam_FormatAndDisplay:
	call SndParam_LookupReadOnly
	lda xbc, (xsp + 12)
	ld xwa, SndParam_FormatAndDisplay_Str_2
	cp hl, 0:i3
	jr z, SndParam_PushStrAndCopy
	ld xwa, SndParam_FormatAndDisplay_Str

SndParam_PushStrAndCopy:
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, EVT_GRID_DRAW

SndParam_SendEventAndReturn:
	call SendEvent

SndParam_ReturnZero2:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 28)
	ret

TtMdInOut:
	cp xbc, EVT_REPAINT
	jr z, TtMdInOut_ReturnZero
	cp xbc, EVT_PAINT
	jr z, TtMdInOut_ReturnZero
	cp xbc, EVT_HIDE
	jr z, TtMdInOut_ReturnZero
	cp xbc, EVT_SHOW
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
	cp xbc, EVT_REQUEST_GRID_DRAW
	jrl z, AcInOutGrid_CellSelect
	ld xwa, (xsp + 12)
	cp xwa, EVT_GET_FIXED_ROW_STR
	jrl z, AcInOutGrid_GetRowText
	cp xwa, EVT_GET_FIXED_COL_STR
	jrl z, AcInOutGrid_GetColText
	cp xwa, EVT_SHOW
	jr z, AcInOutGrid_Init
	sub xbc, EVT_INDEXSW_UP
	cp xbc, 0x0
	jrl lt, AcInOutGrid_Default
	cp xbc, 0x6
	jrl gt, AcInOutGrid_Default
	add xbc, xbc
	add xbc, AcInOutGridBoxProc_CaseTable
	ld bc, (xbc)
	lda xix, (AcInOutGrid_Init:24)
	jp	t, (xix+bc)

AcInOutGrid_Init:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 16)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld xiz, xhl
	ld xwa, (xsp + 4)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 16
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_UP
	call SetDialUp
	ld xwa, (xsp + 4)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 16
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN
	call SetDialDown
	ld wa, 1:i3
	jrl AcInOutGrid_SetScrollBounds
AcInOutGridBoxProc_OnIndexswUp:	; cases 29360151, 29360153
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 16)
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jr z, AcInOutGrid_ScrollUp_CheckAlt
	ld xwa, (xsp + 16)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld iz, hl
	ld xwa, 0x5000
	call SndParam_LookupReadOnly
	ld wa, iz
	add wa, wa
	cp hl, 0:i3
	jr nz, AcInOutGrid_ScrollUp_AltTable
	lda xbc, (AcInOutGrid_Init_Table:24)
	ld	wa, (xbc+wa)
	ld bc, iz
	sub bc, wa
	ld de, bc
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 16)
	ld xbc, EVT_SELE_DRAW
	jr AcInOutGrid_ScrollUp_Dispatch

AcInOutGrid_ScrollUp_AltTable:
	lda xbc, (AcInOutGrid_ScrollUp_AltTable_Table:24)
	ld	wa, (xbc+wa)
	ld bc, iz
	sub bc, wa
	ld de, bc
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 16)
	ld xbc, EVT_SELE_DRAW

AcInOutGrid_ScrollUp_Dispatch:
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	jrl AcInOutGrid_ReturnZero

AcInOutGrid_ScrollUp_CheckAlt:
	ld xwa, (xsp + 16)
	ld xbc, EVT_CHECK_GRID_INDEX
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
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 8)
	call SetDialDown
	ld wa, 1:i3
	jrl AcInOutGrid_SetScrollBounds
AcInOutGridBoxProc_OnIndexswDown:	; cases 29360152, 29360154
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 16)
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jr z, AcInOutGrid_ScrollDown_CheckAlt
	ld xwa, (xsp + 16)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld iz, hl
	ld xwa, 0x5000
	call SndParam_LookupReadOnly
	ld wa, iz
	add wa, wa
	cp hl, 0:i3
	jr nz, AcInOutGrid_ScrollDown_AltTable
	lda xbc, (AcInOutGrid_ScrollUp_Dispatch_Table:24)
	ld	wa, (xbc+wa)
	add wa, iz
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 16)
	ld xbc, EVT_SELE_DRAW
	jr AcInOutGrid_ScrollDown_Dispatch

AcInOutGrid_ScrollDown_AltTable:
	lda xbc, (AcInOutGrid_ScrollDown_AltTable_Table:24)
	ld	wa, (xbc+wa)
	add wa, iz
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 16)
	ld xbc, EVT_SELE_DRAW

AcInOutGrid_ScrollDown_Dispatch:
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	jrl AcInOutGrid_ReturnZero

AcInOutGrid_ScrollDown_CheckAlt:
	ld xwa, (xsp + 16)
	ld xbc, EVT_CHECK_GRID_INDEX
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
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN
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
	ld xwa, 0x5000
	call SndParam_LookupReadOnly
	cp hl, 2:i3
	jr z, AcInOutGrid_GetRowText_Src2
	cp hl, 1:i3
	jr z, AcInOutGrid_GetRowText_Src1
	cp hl, 0:i3
	jr nz, AcInOutGrid_ReturnZero
	ld xwa, AcInOutGrid_GetRowText_Str
	jr AcInOutGrid_GetRowText_Push

AcInOutGrid_GetRowText_Src1:
	ld xwa, AcInOutGrid_GetRowText_Src1_Str
	jr AcInOutGrid_GetRowText_Push

AcInOutGrid_GetRowText_Src2:
	ld xwa, AcInOutGrid_GetRowText_Src2_Str

AcInOutGrid_GetRowText_Push:
	push xwa

AcInOutGrid_Strcpy:
	ld xwa, (xsp + 12)
	push xwa
	call Strcpy
	inc 8, xsp
	jr AcInOutGrid_ReturnZero
AcInOutGridBoxProc_OnLswData:	; cases 29360156, 29360157
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	jr AcInOutGrid_CellSelect_Call

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
	ld xiy, InOutGridCheck_LocalInit
	lda xix, (xsp + 12)
	ldw bc, 0x8
	ldirw
	ld xiy, ComSetGridCheck_LocalInit
	lda xix, (xsp + 4)
	ld bc, 4:i3
	ldirw
	ld xwa, xde
	lda xbc, (xsp + 12)
	cp xde, EVT_REQUEST_GRID_DRAW
	jrl z, InOutGridCheck_OnRequestGridDraw
	sub xwa, EVT_INDEXSW_UP
	cp xwa, 0x0
	jrl lt, MdPreset_ReturnZero2
	cp xwa, 0x6
	jrl gt, MdPreset_ReturnZero2
	add xwa, xwa
	add xwa, InOutGridCheck_CaseTable
	ld wa, (xwa)
	lda xix, (Data_InOutGridDispatch:24)
	jp	t, (xix+wa)

Data_InOutGridDispatch:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	xiz, xhl
	lda	xwa, (xsp+4)
	ld	xbc, xiz
	srl	xbc, 16
	ld	qbc, 0
	ld	(xwa), bc
	ld	bc, iz
	ld	(xwa+2), bc
	cpw	(xwa), 1
	jrl	nz, MdPreset_ReturnZero2
	cp	bc, 0:i3
	jrl	mi, MdPreset_ReturnZero2
	cp	bc, 8
	jrl	gt, MdPreset_ReturnZero2
	add	bc, bc
	lda	xix, (Data_InOutGridDispatch_CaseTable_3:24)
	ld	bc, (xix+bc)
	lda	xix, (Data_InOutGridDispatch_Code:24)
	jp	t, (xix+bc)
Data_InOutGridDispatch_Code:
	ld	xwa, 0x2100
	ld	bc, 1:i3
	ld	de, 1:i3
	jrl	InOutGridCheck_Join
InOutGridCheck_IncAutoPlayChordInput:
	ld	xwa, 0x2101
	ld	bc, 1:i3
	ld	de, 1:i3
	jrl	InOutGridCheck_Join
InOutGridCheck_IncVelocityInputMode:
	ld	xwa, 0x5000
	ld	bc, 1:i3
	ld	de, 1:i3
	jrl	InOutGridCheck_Join
InOutGridCheck_IncVelocityOffsetOrFixed:
	ld	xwa, 0x5000
	call	SndParam_LookupReadOnly
	cp	hl, 2:i3
	jr	z, InOutGridCheck_Skip
	cp	hl, 1:i3
	jrl	nz, MdPreset_ReturnZero2
	ld	xwa, 0x5001
	ld	bc, 1:i3
	ld	de, 1:i3
	jrl	InOutGridCheck_Join
InOutGridCheck_Skip:
	ld	xwa, 0x5002
	ld	bc, 1:i3
	ld	de, 1:i3
	jrl	InOutGridCheck_Join
InOutGridCheck_IncTechniChordOutput:
	ld	xwa, 0x2181
	ld	bc, 1:i3
	ld	de, 1:i3
	jrl	InOutGridCheck_Join
InOutGridCheck_IncTransposeOutput:
	ld	xwa, 0x2184
	ld	bc, 1:i3
	ld	de, 1:i3
	jrl	InOutGridCheck_Join
InOutGridCheck_IncDrumPatternOutput:
	ld	xwa, 0x2182
	ld	bc, 1:i3
	ld	de, 1:i3
	jrl	InOutGridCheck_Join
InOutGridCheck_IncAutoPlayChordOutput:
	ld	xwa, 0x2183
	ld	bc, 1:i3
	ld	de, 1:i3
	jrl	InOutGridCheck_Join
InOutGridCheck_OnIndexswDown:	; cases 29360152, 29360154
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	xiz, xhl
	lda	xwa, (xsp+4)
	ld	xbc, xiz
	srl	xbc, 16
	ld	qbc, 0
	ld	(xwa), bc
	ld	bc, iz
	ld	(xwa+2), bc
	cpw	(xwa), 1
	jrl	nz, MdPreset_ReturnZero2
	cp	bc, 0:i3
	jrl	mi, MdPreset_ReturnZero2
	cp	bc, 8
	jrl	gt, MdPreset_ReturnZero2
	add	bc, bc
	lda	xix, (Data_InOutGridDispatch_CaseTable_2:24)
	ld	bc, (xix+bc)
	lda	xix, (Data_InOutGridDispatch_Code_2:24)
	jp	t, (xix+bc)
Data_InOutGridDispatch_Code_2:
	ld	xwa, 0x2100
	ldw	bc, 0xffff
	ld	de, 1:i3
	jr	InOutGridCheck_Join
InOutGridCheck_DecAutoPlayChordInput:
	ld	xwa, 0x2101
	ldw	bc, 0xffff
	ld	de, 1:i3
	jr	InOutGridCheck_Join
InOutGridCheck_DecVelocityInputMode:
	ld	xwa, 0x5000
	ldw	bc, 0xffff
	ld	de, 1:i3
	jr	InOutGridCheck_Join
InOutGridCheck_DecVelocityOffsetOrFixed:
	ld	xwa, 0x5000
	call	SndParam_LookupReadOnly
	cp	hl, 2:i3
	jr	z, InOutGridCheck_Skip2
	cp	hl, 1:i3
	jrl	nz, MdPreset_ReturnZero2
	ld	xwa, 0x5001
	ldw	bc, 0xffff
	ld	de, 1:i3
	jr	InOutGridCheck_Join
InOutGridCheck_Skip2:
	ld	xwa, 0x5002
	ldw	bc, 0xffff
	ld	de, 1:i3
	jr	InOutGridCheck_Join
InOutGridCheck_DecTechniChordOutput:
	ld	xwa, 0x2181
	ldw	bc, 0xffff
	ld	de, 1:i3
	jr	InOutGridCheck_Join
InOutGridCheck_DecTransposeOutput:
	ld	xwa, 0x2184
	ldw	bc, 0xffff
	ld	de, 1:i3
	jr	InOutGridCheck_Join
InOutGridCheck_DecDrumPatternOutput:
	ld	xwa, 0x2182
	ldw	bc, 0xffff
	ld	de, 1:i3
	jr	InOutGridCheck_Join
InOutGridCheck_DecAutoPlayChordOutput:
	ld	xwa, 0x2183
	ldw	bc, 0xffff
	ld	de, 1:i3
InOutGridCheck_Join:
	call	MainLswAdd
	jrl	MdPreset_ReturnZero2
InOutGridCheck_OnLswData:
	lda	xwa, (xsp+4)
	ldw	(xwa), 1
	ld	xde, xbc
	ld	(xwa+4), xbc
	ld	xix, (xiz)
	lda	xbc, (xwa+2)
	lda	xhl, (Data_InOutGridDispatch_PtrTable:24)
	cp	xix, 0x2183
	jrl	z, InOutGridCheck_Entry
	cp	xix, 0x2182
	jrl	z, InOutGridCheck_Skip13
	cp	xix, 0x2184
	jrl	z, InOutGridCheck_Skip12
	lda	xwa, (xiz+4)
	cp	xix, 0x2181
	jrl	z, InOutGridCheck_Skip11
	cp	xix, 0x5002
	jrl	z, InOutGridCheck_Skip9
	cp	xix, 0x5001
	jrl	z, InOutGridCheck_Skip7
	cp	xix, 0x5000
	jr	z, InOutGridCheck_Skip4
	cp	xix, 0x2101
	jr	z, InOutGridCheck_Skip3
	cp	xix, 0x2100
	jrl	nz, MdPreset_ReturnZero2
	ldw	(xbc), 0
	ld	wa, (xwa)
	sla	wa, 2
	lda	xbc, (Data_InOutGridDispatch_PtrTable_2:24)
	ld	xwa, (xbc+wa)
	push	xwa
	push	xde
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jrl	InOutGridCheck_Join4
InOutGridCheck_Skip3:
	ldw	(xbc), 1
	ld	wa, (xwa)
	sla	wa, 2
	ld	xwa, (xhl+wa)
	push	xwa
	push	xde
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jrl	InOutGridCheck_Join4
InOutGridCheck_Skip4:
	ld	xix, xwa
	ld	wa, (xwa)
	lda	xhl, (Data_InOutGridDispatch_PtrTable_3:24)
	cp	wa, 2:i3
	jr	z, InOutGridCheck_Skip6
	cp	wa, 1:i3
	jr	z, InOutGridCheck_Skip5
	cp	wa, 0:i3
	jrl	nz, MdPreset_ReturnZero2
	ldw	(xbc), 2
	ld	wa, (xix)
	sla	wa, 2
	ld	xwa, (xhl+wa)
	push	xwa
	push	xde
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	call	SendEvent
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	InOutGridCheck_Join4
InOutGridCheck_Skip5:
	ldw	(xbc), 2
	ld	wa, (xix)
	sla	wa, 2
	ld	xwa, (xhl+wa)
	push	xwa
	push	xde
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	call	SendEvent
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	InOutGridCheck_Join4
InOutGridCheck_Skip6:
	ldw	(xbc), 2
	ld	wa, (xix)
	sla	wa, 2
	ld	xwa, (xhl+wa)
	push	xwa
	push	xde
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	call	SendEvent
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	InOutGridCheck_Join4
InOutGridCheck_Skip7:
	ldw	(xbc), 3
	ld	xwa, 0x5000
	call	SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr	nz, InOutGridCheck_Skip8
	ld	wa, (xiz+4)
	exts	wa
	pushw	wa
	pushw	InOutGridCheck_LocalInit_Strings@hi16
	pushw	InOutGridCheck_LocalInit_Strings@lo16
	lda	xwa, (xsp+18)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	jr	InOutGridCheck_Join2
InOutGridCheck_Skip8:
	pushw	Data_InOutGridDispatch_Str_Blank5@hi16
	pushw	Data_InOutGridDispatch_Str_Blank5@lo16
	lda	xwa, (xsp+16)
	push	xwa
	call	Strcpy
	inc	8, xsp
InOutGridCheck_Join2:
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jrl	InOutGridCheck_Join4
InOutGridCheck_Skip9:
	ldw	(xbc), 3
	ld	xwa, 0x5000
	call	SndParam_LookupReadOnly
	cp	hl, 2:i3
	jr	nz, InOutGridCheck_Skip10
	pushm	(xiz+4)
	pushw	Data_InOutGridDispatch_Str_Fmt3d@hi16
	pushw	Data_InOutGridDispatch_Str_Fmt3d@lo16
	lda	xwa, (xsp+18)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	jr	InOutGridCheck_Join3
InOutGridCheck_Skip10:
	pushw	Data_InOutGridDispatch_Str_Blank5_2@hi16
	pushw	Data_InOutGridDispatch_Str_Blank5_2@lo16
	lda	xwa, (xsp+16)
	push	xwa
	call	Strcpy
	inc	8, xsp
InOutGridCheck_Join3:
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jrl	InOutGridCheck_Join4
InOutGridCheck_Skip11:
	ldw	(xbc), 5
	ld	wa, (xwa)
	sla	wa, 2
	ld	xwa, (xhl+wa)
	push	xwa
	push	xde
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jrl	InOutGridCheck_Join4
InOutGridCheck_Skip12:
	ldw	(xbc), 6
	ld	wa, (xiz+4)
	sla	wa, 2
	ld	xwa, (xhl+wa)
	push	xwa
	push	xde
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jrl	InOutGridCheck_Join4
InOutGridCheck_Skip13:
	ldw	(xbc), 7
	ld	wa, (xiz+4)
	sla	wa, 2
	ld	xwa, (xhl+wa)
	push	xwa
	push	xde
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jrl	InOutGridCheck_Join4
InOutGridCheck_Entry:
	ldw	(xbc), 8
	ld	bc, (xiz+4)
	sla	bc, 2
	ld	xwa, (xhl+bc)
	push	xwa
	push	xde
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jrl	InOutGridCheck_Join4

; ParaLoadOpt entry handler
InOutGridCheck_OnRequestGridDraw:
	lda xde, (xsp + 4)
	ld xwa, xiz
	srl xwa, 16
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
	lda xix, (Data_InOutGridDispatch_CaseTable:24)
	ld	wa, (xix+wa)
	lda xix, (Data_ParaLoadOptDispatch:24)
	jp	t, (xix+wa)

Data_ParaLoadOptDispatch:
	ld	xwa, 8448
	call	SndParam_LookupReadOnly
	sla	hl, 2
	lda	xwa, (Data_InOutGridDispatch_PtrTable_2:24)
	ld	xwa, (xwa+hl)
	push xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jrl	InOutGridCheck_Join4
Data_InOutGridDispatch_Case1:
	ld	xwa, 8449
	call	SndParam_LookupReadOnly
	sla	hl, 2
	lda	xwa, (Data_InOutGridDispatch_PtrTable:24)
	ld	xwa, (xwa+hl)
	push xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jrl	InOutGridCheck_Join4
Data_InOutGridDispatch_Case2:
	ld	xwa, 0x5000
	call	SndParam_LookupReadOnly
	sla	hl, 2
	lda	xwa, (Data_InOutGridDispatch_PtrTable_3:24)
	ld	xwa, (xwa+hl)
	push xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	call	SendEvent
	ld	xwa, 0x5000
	call	SndParam_LookupReadOnly
	cp	hl, 2:i3
	jr	z, InOutGridCheck_Skip15
	lda	xwa, (xsp+6)
	cp	hl, 1:i3
	jr	z, InOutGridCheck_Skip14
	cp	hl, 0:i3
	jrl	nz, MdPreset_ReturnZero2
	ldw	(xwa), 3
	pushw	Data_ParaLoadOptDispatch_Str_Blank5@hi16
	pushw	Data_ParaLoadOptDispatch_Str_Blank5@lo16
	lda	xwa, (xsp+16)
	push	xwa
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jrl	InOutGridCheck_Join4
InOutGridCheck_Skip14:
	ldw	(xwa), 3
	ld	xwa, 0x5001
	call	SndParam_LookupReadOnly
	exts	hl
	pushw	hl
	pushw	Data_ParaLoadOptDispatch_Str_Fmt3d@hi16
	pushw	Data_ParaLoadOptDispatch_Str_Fmt3d@lo16
	lda	xwa, (xsp+18)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jrl	InOutGridCheck_Join4
InOutGridCheck_Skip15:
	ldw	(xsp+6), 3
	ld	xwa, 0x5002
	call	SndParam_LookupReadOnly
	pushw	hl
	pushw	Data_ParaLoadOptDispatch_Str_Fmt3d_2@hi16
	pushw	Data_ParaLoadOptDispatch_Str_Fmt3d_2@lo16
	lda	xwa, (xsp+18)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jrl	InOutGridCheck_Join4
Data_InOutGridDispatch_Case3:
	ld	xwa, 0x5000
	call	SndParam_LookupReadOnly
	cp	hl, 2:i3
	jr	z, InOutGridCheck_Skip17
	cp	hl, 1:i3
	jr	z, InOutGridCheck_Skip16
	cp	hl, 0:i3
	jrl	nz, MdPreset_ReturnZero2
	pushw	Data_ParaLoadOptDispatch_Str_Blank5_2@hi16
	pushw	Data_ParaLoadOptDispatch_Str_Blank5_2@lo16
	lda	xwa, (xsp+16)
	push	xwa
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jrl	InOutGridCheck_Join4
InOutGridCheck_Skip16:
	ld	xwa, 0x5001
	call	SndParam_LookupReadOnly
	exts	hl
	pushw	hl
	pushw	Data_ParaLoadOptDispatch_Str_Fmt3d_3@hi16
	pushw	Data_ParaLoadOptDispatch_Str_Fmt3d_3@lo16
	lda	xwa, (xsp+18)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jrl	InOutGridCheck_Join4
InOutGridCheck_Skip17:
	ld	xwa, 0x5002
	call	SndParam_LookupReadOnly
	pushw	hl
	pushw	Data_ParaLoadOptDispatch_Str_Fmt3d_4@hi16
	pushw	Data_ParaLoadOptDispatch_Str_Fmt3d_4@lo16
	lda	xwa, (xsp+18)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jrl	InOutGridCheck_Join4
Data_InOutGridDispatch_Case5:
	ld	xwa, 8577
	call	SndParam_LookupReadOnly
	sla	hl, 2
	lda	xwa, (Data_InOutGridDispatch_PtrTable:24)
	ld	xwa, (xwa+hl)
	push xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jrl	InOutGridCheck_Join4
Data_InOutGridDispatch_Case6:
	ld	xwa, 8580
	call	SndParam_LookupReadOnly
	sla	hl, 2
	lda	xwa, (Data_InOutGridDispatch_PtrTable:24)
	ld	xwa, (xwa+hl)
	push xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jr	InOutGridCheck_Join4
Data_InOutGridDispatch_Case7:
	ld	xwa, 8578
	call	SndParam_LookupReadOnly
	sla	hl, 2
	lda	xwa, (Data_InOutGridDispatch_PtrTable:24)
	ld	xwa, (xwa+hl)
	push xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jr	InOutGridCheck_Join4
Data_InOutGridDispatch_Case8:
	ld	xwa, 8579
	call	SndParam_LookupReadOnly
	sla	hl, 2
	lda	xwa, (Data_InOutGridDispatch_PtrTable:24)
	ld	xwa, (xwa+hl)
	push xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
InOutGridCheck_Join4:
	call	SendEvent

MdPreset_ReturnZero2:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 24)
	ret

TtMdPreset:
	cp xbc, EVT_REPAINT
	jr z, TtMdPreset_ReturnZero
	cp xbc, EVT_PAINT
	jr z, TtMdPreset_ReturnZero
	cp xbc, EVT_HIDE
	jr z, TtMdPreset_ReturnZero
	cp xbc, EVT_SHOW
	jr nz, TtMdPreset_ReturnZero
	or xde, xde
	jr nz, TtMdPreset_ReturnZero
	ld xwa, 0x560001
	ld xbc, EVT_SET_PAGE
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
	cp xwa, EVT_PAGE_CHANGE
	jr z, IvMpst_HandlePageSwitch
	cp xwa, EVT_GET_STRING
	jr z, IvMpst_HandleGetName
	cp xwa, EVT_DRAW
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
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl IvMpst_SendEventEpilogue

IvMpst_HandleGetName:
	pushw InOutGridCheck_CaseTable_Strings@hi16
	pushw InOutGridCheck_CaseTable_Strings@lo16
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	jrl IvMpst_ReturnZero

IvMpst_HandlePageSwitch:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 24)
	ld xbc, EVT_CHECK_SHOW_WINDOW
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr z, IvMpst_CheckSecondView
	ld xwa, (xiz + 24)
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call SendEvent

IvMpst_CheckSecondView:
	ld xwa, (xiz + 28)
	ld xbc, EVT_CHECK_SHOW_WINDOW
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr z, IvMpst_InheritAndCheck
	ld xwa, (xiz + 28)
	ld xbc, EVT_HIDE
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
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	jr IvMpst_SendEventEpilogue

IvMpst_ActivateSecondView:
	ld xwa, (xiz + 28)
	ld xbc, EVT_SHOW
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
	cp xbc, EVT_SW_IN
	jr nz, MdPresetWith_ReturnSuccess
	cp (0x024756:24), 0x00
	jr z, MdPresetWith_ReturnSuccess
	ld (0x024756:24), 0x00
	ld xwa, 0x560001
	ld xbc, EVT_GET_PAGE_NOW
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
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xiz + 24)
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	jr MdPresetWithout_SendCreate

MdPresetWithout_Slot2Path:
	ld xwa, 0x560005
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 28)
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xiz + 24)
	ld xbc, EVT_SHOW
	ld xde, 0:i3

MdPresetWithout_SendCreate:
	call SendEvent

MdPresetWith_ReturnSuccess:
	ld xhl, 0:i3
	pop xiz
	ret

MdPresetWithFunc:
	push xiz
	cp xbc, EVT_SW_IN
	jr nz, MdPreset_ReturnSuccess
	cp (0x024756:24), 0x01
	jr z, MdPreset_ReturnSuccess
	ld (0x024756:24), 0x01
	ld xwa, 0x560001
	ld xbc, EVT_GET_PAGE_NOW
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
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xiz + 28)
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	jr MdPresetWith_SendCreate

MdPresetWith_Slot2Path:
	ld xwa, 0x560005
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 24)
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xiz + 28)
	ld xbc, EVT_SHOW
	ld xde, 0:i3

MdPresetWith_SendCreate:
	call SendEvent

MdPreset_ReturnSuccess:
	ld xhl, 0:i3
	pop xiz
	ret

MdPresetOKFunc:
	ld xhl, xde
	cp xbc, EVT_SW_IN
	jrl nz, MdPreset_PostMainFunc
	ld xwa, 0x560001
	ld xbc, EVT_GET_PAGE_NOW
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
	ld xbc, EVT_GET_SELECTED
	ld xde, 0:i3
	call SendEvent
	add l, 0x44
	ld h, 0x0:opc
	extz xhl
	ld xwa, NAKA_MAINFUNC_MainMpstFunc
	ld xbc, EVT_MPST_LOAD
	ld xde, xhl
	jrl MdPreset_CallMainFunc

MdPresetOK_Slot1Func:
	ld xwa, 0x560015
	ld xbc, EVT_GET_SELECTED
	ld xde, 0:i3
	call SendEvent
	add l, 0x4d
	ld h, 0x0:opc
	extz xhl
	ld xwa, NAKA_MAINFUNC_MainMpstFunc
	ld xbc, EVT_MPST_LOAD
	ld xde, xhl
	jrl MdPreset_CallMainFunc

MdPresetOK_CheckSlotB:
	cp a, 1:i3
	jr z, MdPresetOK_SlotBFunc
	cp a, 0:i3
	jrl nz, MdPreset_PostMainFunc
	ld xwa, 0x56002d
	ld xbc, EVT_GET_SELECTED
	ld xde, 0:i3
	call SendEvent
	add l, 0x41
	ld h, 0x0:opc
	extz xhl
	ld xwa, NAKA_MAINFUNC_MainMpstFunc
	ld xbc, EVT_MPST_LOAD
	ld xde, xhl
	jrl MdPreset_CallMainFunc

MdPresetOK_SlotBFunc:
	ld xwa, 0x560039
	ld xbc, EVT_GET_SELECTED
	ld xde, 0:i3
	call SendEvent
	add l, 0x4a
	ld h, 0x0:opc
	extz xhl
	ld xwa, NAKA_MAINFUNC_MainMpstFunc
	ld xbc, EVT_MPST_LOAD
	ld xde, xhl
	jr MdPreset_CallMainFunc

MdPresetOK_Slot3Path:
	ld xwa, 0x560020
	ld xbc, EVT_GET_SELECTED
	ld xde, 0:i3
	call SendEvent
	add l, 0x1b
	ld h, 0x0:opc
	extz xhl
	ld xwa, NAKA_MAINFUNC_MainMpstFunc
	ld xbc, EVT_MPST_LOAD
	ld xde, xhl
	jr MdPreset_CallMainFunc

MdPresetOK_Slot4Path:
	ld xwa, 0x560029
	ld xbc, EVT_GET_PARAM
	ld xde, 0:i3
	call SendEvent
	ld (0x024758:24), l
	ld xwa, 0x560025
	ld xbc, EVT_GET_SELECTED
	ld xde, 0:i3
	call SendEvent
	ld h, 0x0:opc
	extz xhl
	ld xwa, NAKA_MAINFUNC_MainMpstFunc
	ld xbc, EVT_MPST_WRITE
	ld xde, xhl

MdPreset_CallMainFunc:
	call MainFuncCall

MdPreset_PostMainFunc:
	ld xhl, 0:i3
	ret

MainMpstFunc:
	dec 4, xsp
	ld (xsp), xde
	cp xbc, EVT_MPST_WRITE
	jr z, MainMpst_HandlePresetCopy
	cp xbc, EVT_MPST_LOAD
	jr nz, MainMpst_ReturnZero
	ld xwa, (xsp)
	ld (0xb7ec:16), a
	call SndParam_ApplyAndSync
	ld (GLOBAL_ERROR_CODE:16), 35
	ld xwa, 0xffffffff
	ld xbc, EVT_INTERRUPT_TITLE
	ld xde, TITLE_MESAGE
	jr MainMpst_PostEvent

MainMpst_HandlePresetCopy:
	ld (GLOBAL_ERROR_CODE:16), 37
	ld xwa, 0xffffffff
	ld xbc, EVT_INTERRUPT_TITLE
	ld xde, TITLE_MESAGE
	call ApPostEvent
	ld xwa, (xsp)
	extz wa
	call SndParam_AllocAndCopyPreset
	ld (GLOBAL_ERROR_CODE:16), 35
	ld xwa, 0xffffffff
	ld xbc, EVT_INTERRUPT_TITLE
	ld xde, TITLE_MESAGE

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
	cp xbc, EVT_REPAINT
	jr z, TtMdExc_ReturnZero
	cp xbc, EVT_PAINT
	jr z, TtMdExc_ReturnZero
	cp xbc, EVT_HIDE
	jr z, TtMdExc_HandleClose
	cp xbc, EVT_SHOW
	jr nz, TtMdExc_ReturnZero
	or xde, xde
	jr nz, TtMdExc_ReturnZero
	set 6, (0xb7e2:16)
	ld xwa, 0x570003
	call GetViewInstance
	ld xwa, (xhl + 38)
	ldw (xwa), 0x0
	jr TtMdExc_ReturnZero

TtMdExc_HandleClose:
	or xde, xde
	jr nz, TtMdExc_ReturnZero
	res 6, (0xb7e2:16)

TtMdExc_ReturnZero:
	ld xhl, 0:i3
	ret

