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
	cp xbc, 0x1C00018
	jrl z, AcLswBox_HandleScrollDownEvt
	cp xbc, 0x1C0001A
	jrl z, AcLswBox_HandleScrollUpEvt
	cp xbc, 0x1C00017
	jrl z, AcLswBox_HandleDialDecEvt
	cp xbc, 0x1C00019
	jrl z, AcLswBox_HandleDialIncEvt
	cp xbc, 0x1C0001C
	jrl z, AcLswBox_HandleValueChange
	cp xbc, 0x1C0000C
	jrl z, AcLswBox_HandleGetLsw
	cp xbc, 0x1C0000B
	jrl z, AcLswBox_HandleGetLsw
	cp xbc, 0x1C00002
	jrl z, AcLswBox_HandleResetFilter
	cp xbc, 0x1C00001
	jrl z, AcLswBox_OnCreateEvt
	cp xbc, 0x1E0003D
	jr z, AcLswBox_HandleAdd
	cp xbc, 0x1E0003B
	jr z, AcLswBox_HandlePut
	cp xbc, 0x1E0003A
	jrl nz, AcLswBox_DefaultInherited
	ld xwa, xiz
	call GetViewInstance
	lda xwa, (xhl + 36)
	ld xbc, (xwa)
	cpw (xbc), 0x0
	jr nz, AcLswBox_CheckState1
	ld xwa, 0x2C
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
	pushw 0xE7
	pushw 0xF93C

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
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jrl AudioMix_SendEventAlt

AcLswBox_HandleDialIncEvt:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E00050
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jrl z, AudioMix_ReturnZeroJmp2
	ld xwa, xiz
	ld xbc, 0x1E0003D
	lds32 xde, 1
	jr AudioMix_SendEventAlt

AcLswBox_HandleDialDecEvt:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E00050
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AudioMix_ReturnZeroJmp2
	ld xwa, xiz
	ld xbc, 0x1E0003D
	lds32 xde, 1
	jr AudioMix_SendEventAlt

AcLswBox_HandleScrollUpEvt:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E00050
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AudioMix_ReturnZeroJmp2
	ld xwa, xiz
	ld xbc, 0x1E0003D
	ld xde, 0xFFFFFFFF
	jr AudioMix_SendEventAlt

AcLswBox_HandleScrollDownEvt:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E00050
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AudioMix_ReturnZeroJmp2
	ld xwa, xiz
	ld xbc, 0x1E0003D
	ld xde, 0xFFFFFFFF

AudioMix_SendEventAlt:
	call SendEvent

AudioMix_ReturnZeroJmp2:
	lds32 xhl, 0
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
	cp xbc, 0x1C0000C
	jr z, TtMdRealMsg_ReturnZero
	cp xbc, 0x1C0000B
	jr z, TtMdRealMsg_ReturnZero
	cp xbc, 0x1C00002
	jr z, TtMdRealMsg_ReturnZero
	cp xbc, 0x1C00001
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
	lds32 xhl, 0
	ret

AcLswFuncEditBoxProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, 0x1C00018
	jrl z, AcLswEdit_HandleScrollDownEvt
	cp xbc, 0x1C0001A
	jrl z, AcLswEdit_HandleScrollUpEvt
	cp xbc, 0x1C00017
	jrl z, AcLswEdit_HandleDialDecEvt
	cp xbc, 0x1C00019
	jrl z, AcLswEdit_HandleDialIncEvt
	cp xbc, 0x1C0001C
	jrl z, AcLswEdit_HandleValueChange
	cp xbc, 0x1C0000C
	jrl z, AcLswEdit_HandleGetLsw
	cp xbc, 0x1C0000B
	jrl z, AcLswEdit_HandleGetLsw
	cp xbc, 0x1C00002
	jrl z, AcLswEdit_HandleResetFilter
	cp xbc, 0x1C00001
	jrl z, AcLswEdit_HandleCreate
	cp xbc, 0x1E0003D
	jr z, AcLswEdit_HandleAdd
	cp xbc, 0x1E0003B
	jr z, AcLswEdit_HandlePut
	cp xbc, 0x1E0003A
	jrl nz, AcLswEdit_DefaultInherited
	ld xwa, xiz
	call GetViewInstance
	lda xwa, (xhl + 50)
	ld xbc, (xwa)
	cpw (xbc), 0x0
	jr nz, AcLswEdit_CheckState1
	ld xwa, 0x3A
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
	pushw 0xE7
	pushw 0xF942

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
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jrl AudioMix_SendEvent

AcLswEdit_HandleDialIncEvt:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E0003C
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jrl z, AudioMix_ReturnZeroJmp
	ld xwa, xiz
	ld xbc, 0x1E0003D
	lds32 xde, 1
	jr AudioMix_SendEvent

AcLswEdit_HandleDialDecEvt:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E0003C
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AudioMix_ReturnZeroJmp
	ld xwa, xiz
	ld xbc, 0x1E0003D
	lds32 xde, 1
	jr AudioMix_SendEvent

AcLswEdit_HandleScrollUpEvt:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E0003C
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AudioMix_ReturnZeroJmp
	ld xwa, xiz
	ld xbc, 0x1E0003D
	ld xde, 0xFFFFFFFF
	jr AudioMix_SendEvent

AcLswEdit_HandleScrollDownEvt:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E0003C
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AudioMix_ReturnZeroJmp
	ld xwa, xiz
	ld xbc, 0x1E0003D
	ld xde, 0xFFFFFFFF

AudioMix_SendEvent:
	call SendEvent

AudioMix_ReturnZeroJmp:
	lds32 xhl, 0
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
; Responds to create (0x01), suspend (0x0B), re-enable (0x02),
; and destroy (0x0C) events. On create, initializes animation state
; variables at workspace offsets +42 and +46 to 1 (start animation).
;
; Input:
;   XWA = workspace ID (0xD80001)
;   XBC = event code
;   XDE = event parameter (must be 0 for create)
;
; Used by: Entertainer mode tone fade effects (TT_ETFADEIN)
; =============================================================================
TtFadeInOut:
	cp xbc, 0x1C0000C
	jr z, TtFadeInOut_ReturnZero
	cp xbc, 0x1C0000B
	jr z, TtFadeInOut_ReturnZero
	cp xbc, 0x1C00002
	jr z, TtFadeInOut_ReturnZero
	cp xbc, 0x1C00001
	jr nz, TtFadeInOut_ReturnZero
	or xde, xde
	jr nz, TtFadeInOut_ReturnZero
	ld xwa, 0xD80001
	call GetViewInstance
	ld xwa, (xhl + 42)
	ldw (xwa), 0x1
	ld xwa, (xhl + 46)
	ldw (xwa), 0x1

TtFadeInOut_ReturnZero:
	lds32 xhl, 0
	ret

; =============================================================================
; AcFadeSetGridBoxProc - Grid-based fade effect processor
;
; Complex event-driven handler implementing grid-based screen fade transitions.
; Uses two lookup tables for fade timing/interpolation:
;   0xE7F948 - Fade-in grid timing table
;   0xE7F956 - Fade-out grid timing table
; Jump table at 0xE7F964 dispatches to 7 sub-handlers (events 0x17-0x1D).
;
; Handles events:
;   0x1C00001 - Create: initialize grid box, set up animation parameters
;   0x1C00017-0x1C0001D - Animation step events (via jump table)
;   0x1E0008A - Get property at workspace offset +0x3E
;   0x1E0008B - Get property at workspace offset +0x42
;   0x1E0008D - Forward to child widget handler
;   0x1E0008F - Query animation progress counter
;   0x1E00050 - Check fade-in progress
;   0x1E00091 - Check fade-out progress
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
	cp xbc, 0x1E0008D
	jrl z, VoiceUI_GridCase2
	ld xwa, (xsp + 16)
	cp xwa, 0x1E0008B
	jrl z, VoiceUI_GridCase1
	cp xwa, 0x1E0008A
	jrl z, VoiceUI_GridCase0
	cp xwa, 0x1C00001
	jr z, VoiceParam_ListHandler
	sub xbc, 0x1C00017
	cp xbc, 0x0
	jrl lt, VoiceUI_GridCase3
	cp xbc, 0x6
	jrl gt, VoiceUI_GridCase3
	add xbc, xbc
	add xbc, 0xE7F964
	ld bc, (xbc)
	lda_24 xix, 0xf7528a
	jp_dri 8, 0x07, 0xF0, 0xE4

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
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1C00017
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1C00018
	call SetDialDown
	lds wa, 1
	jrl FadeGrid_SetDialEnable
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, FadeGrid_CheckFadeOut
	ld xwa, xiz
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	cps hl, 1
	jrl le, AudioMix_ReturnZeroJmp3
	ld wa, hl
	add wa, wa
	lda_24 xbc, 0xe7f948
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	sub hl, wa
	extz xhl
	add xhl, 0xFFFF0000
	ld xwa, xiz
	ld xbc, 0x1C0000E
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl AudioMix_ReturnZeroJmp3

FadeGrid_CheckFadeOut:
	ld xwa, xiz
	ld xbc, 0x1E00091
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
	ld xbc, 0x1C00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1C00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1
	jrl FadeGrid_SetDialEnable
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, FadeGrid_CheckFadeOutAlt
	ld xwa, xiz
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld wa, hl
	add wa, wa
	lda_24 xbc, 0xe7f956
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	add wa, hl
	ld de, wa
	extz xde
	add xde, 0xFFFF0000
	ld xwa, xiz
	ld xbc, 0x1C0000E
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl AudioMix_ReturnZeroJmp3

FadeGrid_CheckFadeOutAlt:
	ld xwa, xiz
	ld xbc, 0x1E00091
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
	ld xbc, 0x1C00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1C00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1

FadeGrid_SetDialEnable:
	call SetDialEnable
	jr AudioMix_ReturnZeroJmp3

; Voice UI grid case 0
VoiceUI_GridCase0:
	ld xwa, xiz
	ld xiz, 0x3E
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
	lds32 xhl, 0
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
;   0xE7F98E - 16-byte grid parameter buffer (8 words from workspace)
;   0xE7ED44 - 8-byte grid config buffer (4 words)
; Dispatches to specific grid effect handlers via jump table at 0xE7F9D2.
;
; Input:
;   XBC = event code (0x1E0008D or 0x1C00017-0x1C0001D)
;   XDE = event parameter
; =============================================================================
FadeSetGridCheck:
	lda xsp, (xsp - 28)
	push xiz
	ld (xsp + 28), xde
	ld xde, xbc
	ld xiy, 0xE7F98E
	lda xix, (xsp + 12)
	ldw bc, 0x8
	ldirw
	ld xiy, 0xE7ED44
	lda xix, (xsp + 4)
	lds bc, 4
	ldirw
	ld xwa, xde
	cp xde, 0x1E0008D
	jrl z, AcInOutGrid_Handler
	sub xwa, 0x1C00017
	cp xwa, 0x0
	jrl lt, SndParam_ReturnZero2
	cp xwa, 0x6
	jrl gt, SndParam_ReturnZero2
	add xwa, xwa
	add xwa, 0xE7F9D2
	ld wa, (xwa)
	lda_24 xix, 0xf75517
	jp_dri 8, 0x07, 0xF0, 0xE0

Data_FadeSetGridDispatch:
	call	16401616
	ld	xwa, xhl
	ld	xbc, 31457423
	lds32	xde, 0
	call	16422496
	ld	(xsp+28), xhl
	lda	xbc, (xsp+4)
	ld	xwa, (xsp+28)
	srl	xwa, 0
	ld	qwa, 0
	ld	(xbc), wa
	ld	xwa, (xsp+28)
	ld	(xbc+2), wa
	cpw	(xbc), 1
	jrl	nz, 463
	sla	wa, 2
	lda_24	xbc, 15202674
	ld_rrl	xwa, xbc, wa
	cp	xwa, 4294967295
	jrl	z, 441
	lds	bc, 1
	lds	de, 2
	jr	74
	call	16401616
	ld	xwa, xhl
	ld	xbc, 31457423
	lds32	xde, 0
	call	16422496
	ld	(xsp+28), xhl
	lda	xbc, (xsp+4)
	ld	xwa, (xsp+28)
	srl	xwa, 0
	ld	qwa, 0
	ld	(xbc), wa
	ld	xwa, (xsp+28)
	ld	(xbc+2), wa
	cpw	(xbc), 1
	jrl	nz, 388
	sla	wa, 2
	lda_24	xbc, 15202674
	ld_rrl	xwa, xbc, wa
	cp	xwa, 4294967295
	jrl	z, 366
	ldw	bc, 65535
	lds	de, 2
	call	16382274
	jrl	354
	lda	xhl, (xsp+4)
	ldw	(xhl), 1
	lda	xde, (xhl+2)
	ldw	(xde), 0
	lda_24	xix, 15202674
	ld	xiz, (xsp+28)
	jr	18
	ld	iy, bc
	sla	iy, 2
	ld	xwa, (xiz)
	.byte 0xe3
	reti
	.byte 0xf0, 0xf4, 0xf0
	jr	z, 10
	inc	1, bc
	ld	(xde), bc
	ld	bc, (xde)
	cps	bc, 7
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
	pushm	(xde)
	pushw 231
	pushw 63902
	push	xbc
	call	16714340
	lda	xsp, (xsp+10)
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	214
	ld	xwa, 15202738
	cpw	(xde), 0
	jr	z, 5
	.byte 0x40
	.long Data_AcGridParamTable
	push	xwa
	push	xbc
	call	16715583
	inc	8, xsp
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	173

; AcInOutGrid handler
AcInOutGrid_Handler:
	lda xde, (xsp + 4)
	ld xwa, (xsp + 28)
	srl xwa, 0
	ldi_werp 0xE2, 0
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
	lda_24 xbc, 0xe7f972
	ld_sril3 XBC, 0x07, 0xE4, 0xE0
	ld xwa, xbc
	cp xbc, 0x2A12
	jr z, SndParam_FormatAndDisplay
	cp xbc, 0x2A11
	jr z, SndParam_FormatAndDisplay
	cp xbc, 0x2A10
	jr z, SndParam_FormatAndDisplay
	cp xbc, 0x2A01
	jr z, SndParam_LookupAndSendCmd
	cp xbc, 0x2A00
	jr nz, SndParam_ReturnZero2

SndParam_LookupAndSendCmd:
	call SndParam_LookupReadOnly
	pushw hl
	pushw 0xE7
	pushw 0xF9B8
	lda xwa, (xsp + 18)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1E0008C
	jr SndParam_SendEventAndReturn

SndParam_FormatAndDisplay:
	call SndParam_LookupReadOnly
	lda xbc, (xsp + 12)
	ld xwa, 0xE7F9CC
	cps hl, 0
	jr z, SndParam_PushStrAndCopy
	ld xwa, 0xE7F9C6

SndParam_PushStrAndCopy:
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1E0008C

SndParam_SendEventAndReturn:
	call SendEvent

SndParam_ReturnZero2:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 28)
	ret

TtMdInOut:
	cp xbc, 0x1C0000C
	jr z, TtMdInOut_ReturnZero
	cp xbc, 0x1C0000B
	jr z, TtMdInOut_ReturnZero
	cp xbc, 0x1C00002
	jr z, TtMdInOut_ReturnZero
	cp xbc, 0x1C00001
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
	lds32 xhl, 0
	ret

AcInOutGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld (xsp + 16), xwa
	ld xbc, (xsp + 12)
	cp xbc, 0x1E0008D
	jrl z, AcInOutGrid_CellSelect
	ld xwa, (xsp + 12)
	cp xwa, 0x1E0008B
	jrl z, AcInOutGrid_GetRowText
	cp xwa, 0x1E0008A
	jrl z, AcInOutGrid_GetColText
	cp xwa, 0x1C00001
	jr z, AcInOutGrid_Init
	sub xbc, 0x1C00017
	cp xbc, 0x0
	jrl lt, AcInOutGrid_Default
	cp xbc, 0x6
	jrl gt, AcInOutGrid_Default
	add xbc, xbc
	add xbc, 0xE7FC86
	ld bc, (xbc)
	lda_24 xix, 0xf757bc
	jp_dri 8, 0x07, 0xF0, 0xE4

AcInOutGrid_Init:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 16)
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld xiz, xhl
	ld xwa, (xsp + 4)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, 0x1C00017
	call SetDialUp
	ld xwa, (xsp + 4)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, 0x1C00018
	call SetDialDown
	lds wa, 1
	jrl AcInOutGrid_SetScrollBounds
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 16)
	ld xbc, 0x1E00050
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jr z, AcInOutGrid_ScrollUp_CheckAlt
	ld xwa, (xsp + 16)
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld iz, hl
	ld xwa, 0x5000
	call SndParam_LookupReadOnly
	ld wa, iz
	add wa, wa
	cps hl, 0
	jr nz, AcInOutGrid_ScrollUp_AltTable
	lda_24 xbc, 0xe7f9e0
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	ld bc, iz
	sub bc, wa
	ld de, bc
	extz xde
	add xde, 0xFFFF0000
	ld xwa, (xsp + 16)
	ld xbc, 0x1C0000E
	jr AcInOutGrid_ScrollUp_Dispatch

AcInOutGrid_ScrollUp_AltTable:
	lda_24 xbc, 0xe7f9f2
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	ld bc, iz
	sub bc, wa
	ld de, bc
	extz xde
	add xde, 0xFFFF0000
	ld xwa, (xsp + 16)
	ld xbc, 0x1C0000E

AcInOutGrid_ScrollUp_Dispatch:
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	jrl AcInOutGrid_ReturnZero

AcInOutGrid_ScrollUp_CheckAlt:
	ld xwa, (xsp + 16)
	ld xbc, 0x1E00091
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
	ld xbc, 0x1C00017
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, 0x1C00018
	ld xde, (xsp + 8)
	call SetDialDown
	lds wa, 1
	jrl AcInOutGrid_SetScrollBounds
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 16)
	ld xbc, 0x1E00050
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jr z, AcInOutGrid_ScrollDown_CheckAlt
	ld xwa, (xsp + 16)
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld iz, hl
	ld xwa, 0x5000
	call SndParam_LookupReadOnly
	ld wa, iz
	add wa, wa
	cps hl, 0
	jr nz, AcInOutGrid_ScrollDown_AltTable
	lda_24 xbc, 0xe7fa04
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	add wa, iz
	ld de, wa
	extz xde
	add xde, 0xFFFF0000
	ld xwa, (xsp + 16)
	ld xbc, 0x1C0000E
	jr AcInOutGrid_ScrollDown_Dispatch

AcInOutGrid_ScrollDown_AltTable:
	lda_24 xbc, 0xe7fa16
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	add wa, iz
	ld de, wa
	extz xde
	add xde, 0xFFFF0000
	ld xwa, (xsp + 16)
	ld xbc, 0x1C0000E

AcInOutGrid_ScrollDown_Dispatch:
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	jrl AcInOutGrid_ReturnZero

AcInOutGrid_ScrollDown_CheckAlt:
	ld xwa, (xsp + 16)
	ld xbc, 0x1E00091
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
	ld xbc, 0x1C00017
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, 0x1C00018
	ld xde, (xsp + 8)
	call SetDialDown
	lds wa, 1

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
	cps hl, 2
	jr z, AcInOutGrid_GetRowText_Src2
	cps hl, 1
	jr z, AcInOutGrid_GetRowText_Src1
	cps hl, 0
	jr nz, AcInOutGrid_ReturnZero
	ld xwa, 0xE7FA28
	jr AcInOutGrid_GetRowText_Push

AcInOutGrid_GetRowText_Src1:
	ld xwa, 0xE7FAE2
	jr AcInOutGrid_GetRowText_Push

AcInOutGrid_GetRowText_Src2:
	ld xwa, 0xE7FBB4

AcInOutGrid_GetRowText_Push:
	push xwa

AcInOutGrid_Strcpy:
	ld xwa, (xsp + 12)
	push xwa
	call Strcpy
	inc 8, xsp
	jr AcInOutGrid_ReturnZero
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
	lds32 xhl, 0
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
	ld xiy, 0xE7FCEE
	lda xix, (xsp + 12)
	ldw bc, 0x8
	ldirw
	ld xiy, 0xE7ED44
	lda xix, (xsp + 4)
	lds bc, 4
	ldirw
	ld xwa, xde
	lda xbc, (xsp + 12)
	cp xde, 0x1E0008D
	jrl z, ParaLoadOpt_Entry
	sub xwa, 0x1C00017
	cp xwa, 0x0
	jrl lt, MdPreset_ReturnZero2
	cp xwa, 0x6
	jrl gt, MdPreset_ReturnZero2
	add xwa, xwa
	add xwa, 0xE7FD70
	ld wa, (xwa)
	lda_24 xix, 0xf75ade
	jp_dri 8, 0x07, 0xF0, 0xE0

Data_InOutGridDispatch:
	call	16401616
	ld	xwa, xhl
	ld	xbc, 31457423
	lds32	xde, 0
	call	16422496
	ld	xiz, xhl
	lda	xwa, (xsp+4)
	ld	xbc, xiz
	srl	xbc, 0
	.byte 0xd7, 0xe6, 0xa8
	ld	(xwa), bc
	ld	bc, iz
	ld	(xwa+2), bc
	cpw	(xwa), 1
	jrl	nz, 1774
	cps	bc, 0
	jrl	mi, 1769
	cp	bc, 8
	jrl	gt, 1762
	add	bc, bc
	lda_24	xix, 15203678
	.byte 0xd3
	reti
	.byte 0xf0, 0xe4
	ldb	a, 242
	pushw	ix
	pop	xhl
	ldx
	ldw	ix, 2035
	.byte 0xf0, 0xe4
	mul	xwa, xwa
	nop
	ldb	a, 0
	nop
	lds	bc, 1
	lds	de, 1
	jrl	316
	ld	xwa, 8449
	lds	bc, 1
	lds	de, 1
	jrl	304
	ld	xwa, 20480
	lds	bc, 1
	lds	de, 1
	jrl	292
	ld	xwa, 20480
	call	16569399
	cps	hl, 2
	jr	z, 17
	cps	hl, 1
	jrl	nz, 1686
	ld	xwa, 20481
	lds	bc, 1
	lds	de, 1
	jrl	262
	ld	xwa, 20482
	lds	bc, 1
	lds	de, 1
	jrl	250
	ld	xwa, 8577
	lds	bc, 1
	lds	de, 1
	jrl	238
	ld	xwa, 8580
	lds	bc, 1
	.byte 0xda
	.long Data_NakaPresetConfig
	ld	xwa, 8578
	lds	bc, 1
	lds	de, 1
	jrl	214
	ld	xwa, 8579
	lds	bc, 1
	lds	de, 1
	jrl	202
	call	16401616
	ld	xwa, xhl
	ld	xbc, 31457423
	lds32	xde, 0
	call	16422496
	ld	xiz, xhl
	lda	xwa, (xsp+4)
	ld	xbc, xiz
	srl	xbc, 0
	.byte 0xd7, 0xe6, 0xa8
	ld	(xwa), bc
	ld	bc, iz
	ld	(xwa+2), bc
	cpw	(xwa), 1
	jrl	nz, 1570
	cps	bc, 0
	jrl	mi, 1565
	cp	bc, 8
	jrl	gt, 1558
	add	bc, bc
	lda_24	xix, 15203660
	.byte 0xd3
	reti
	.byte 0xf0, 0xe4
	ldb	a, 242
	swi	0
	pop	xhl
	ldx
	ldw	ix, 2035
	.byte 0xf0, 0xe4
	mul	xwa, xwa
	nop
	ldb	a, 0
	nop
	ldw	bc, 65535
	lds	de, 1
	jr	112
	ld	xwa, 8449
	ldw	bc, 65535
	lds	de, 1
	jr	100
	ld	xwa, 20480
	ldw	bc, 65535
	lds	de, 1
	jr	88
	ld	xwa, 20480
	call	16569399
	cps	hl, 2
	jr	z, 17
	cps	hl, 1
	jrl	nz, 1482
	ld	xwa, 20481
	ldw	bc, 65535
	lds	de, 1
	jr	58
	ld	xwa, 20482
	ldw	bc, 65535
	lds	de, 1
	jr	46
	ld	xwa, 8577
	ldw	bc, 65535
	lds	de, 1
	jr	34
	ld	xwa, 8580
	ldw	bc, 65535
	lds	de, 1
	jr	22
	ld	xwa, 8578
	ldw	bc, 65535
	lds	de, 1
	jr	10
	ld	xwa, 8579
	ldw	bc, 65535
	lds	de, 1
	call	16382274
	jrl	1405
	lda	xwa, (xsp+4)
	ldw	(xwa), 1
	ld	xde, xbc
	ld	(xwa+4), xbc
	ld	xix, (xiz)
	lda	xbc, (xwa+2)
	lda_24	xhl, 15203476
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
	lda_24	xbc, 15203496
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 56
	push	xde
	call	16715583
	inc	8, xsp
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	1253
	ldw	(xbc), 1
	ld	wa, (xwa)
	sla	wa, 2
	.byte 0xe3
	reti
	or	xwa, xix
	ldb	w, 56
	push	xde
	call	16715583
	inc	8, xsp
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	1214
	ld	xix, xwa
	ld	wa, (xwa)
	lda_24	xhl, 15203524
	cps	wa, 2
	jr	z, 121
	cps	wa, 1
	jr	z, 61
	cps	wa, 0
	jrl	nz, 1196
	ldw	(xbc), 2
	ld	wa, (xix)
	sla	wa, 2
	.byte 0xe3
	reti
	or	xwa, xix
	ldb	w, 56
	push	xde
	call	16715583
	inc	8, xsp
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	call	16422496
	call	16401616
	ld	xwa, xhl
	ld	xbc, 29360140
	lds32	xde, 0
	jrl	1136
	ldw	(xbc), 2
	ld	wa, (xix)
	sla	wa, 2
	.byte 0xe3
	reti
	or	xwa, xix
	ldb	w, 56
	push	xde
	call	16715583
	inc	8, xsp
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	call	16422496
	call	16401616
	ld	xwa, xhl
	ld	xbc, 29360140
	lds32	xde, 0
	jrl	1080
	ldw	(xbc), 2
	ld	wa, (xix)
	sla	wa, 2
	.byte 0xe3
	reti
	or	xwa, xix
	ldb	w, 56
	push	xde
	call	16715583
	inc	8, xsp
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	call	16422496
	call	16401616
	ld	xwa, xhl
	ld	xbc, 29360140
	lds32	xde, 0
	jrl	1024
	ldw	(xbc), 3
	ld	xwa, 20480
	call	16569399
	cps	hl, 1
	jr	nz, 25
	ld	wa, (xiz+4)
	exts	wa
	pushw	wa
	pushw	231
	pushw	64766
	lda	xwa, (xsp+18)
	push	xwa
	call	16714340
	lda	xsp, (xsp+10)
	jr	16
	pushw	231
	pushw	64772
	lda	xwa, (xsp+16)
	push	xwa
	call	16715583
	inc	8, xsp
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	949
	.byte 0xb1
	push_sr
	pop_sr
	nop
	ld	xwa, 20480
	call	16569399
	cps	hl, 2
	jr	nz, 22
	.byte 0x9e, 0x04, 0x04
	pushw	231
	pushw	64778
	lda	xwa, (xsp+18)
	push	xwa
	call	16714340
	lda	xsp, (xsp+10)
	jr	16
	pushw	231
	pushw	64784
	lda	xwa, (xsp+16)
	push	xwa
	call	16715583
	inc	8, xsp
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	877
	.byte 0xb1
	push_sr
	halt
	nop
	ld	wa, (xwa)
	sla	wa, 2
	.byte 0xe3
	reti
	or	xwa, xix
	ldb	w, 56
	push	xde
	call	16715583
	inc	8, xsp
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	838
	.byte 0xb1
	push_sr
	di
	ld	wa, (xiz+4)
	sla	wa, 2
	.byte 0xe3
	reti
	or	xwa, xix
	ldb	w, 56
	push	xde
	call	16715583
	inc	8, xsp
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	798
	.byte 0xb1
	push_sr
	reti
	nop
	ld	wa, (xiz+4)
	sla	wa, 2
	.byte 0xe3
	reti
	or	xwa, xix
	ldb	w, 56
	push	xde
	call	16715583
	inc	8, xsp
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	758
	.byte 0xb1
	push_sr
	ldio	0, 158
	.byte 0x04
	ldb	a, 217
	.byte 0xec
	push_sr
	.byte 0xe3
	reti
	or	xix, xix
	ldb	w, 56
	push	xde
	call	16715583
	inc	8, xsp
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	718

; ParaLoadOpt entry handler
ParaLoadOpt_Entry:
	lda xde, (xsp + 4)
	ld xwa, xiz
	srl xwa, 0
	ldi_werp 0xE2, 0
	ld (xde), wa
	lda xwa, (xde + 2)
	ld hl, iz
	ld (xwa), hl
	ld (xde + 4), xbc
	cpw (xde), 0x1
	jrl nz, MdPreset_ReturnZero2
	ld wa, (xwa)
	cps wa, 0
	jrl mi, MdPreset_ReturnZero2
	cp wa, 0x8
	jrl gt, MdPreset_ReturnZero2
	add wa, wa
	lda_24 xix, 0xe7fd3a
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf75f68
	jp_dri 8, 0x07, 0xF0, 0xE0

Data_ParaLoadOptDispatch:
	ld	xwa, 8448
	call	16569399
	sla	hl, 2
	lda_24	xwa, 15203496
	.byte 0xe3
	reti
	.byte 0xe0, 0xec
	ldb	w, 56
	lda	xwa, (xsp+16)
	push	xwa
	call	16715583
	inc	8, xsp
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	602
	ld	xwa, 8449
	call	16569399
	sla	hl, 2
	lda_24	xwa, 15203476
	.byte 0xe3
	reti
	.byte 0xe0, 0xec
	ldb	w, 56
	lda	xwa, (xsp+16)
	push	xwa
	call	16715583
	inc	8, xsp
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	552
	ld	xwa, 20480
	call	16569399
	sla	hl, 2
	lda_24	xwa, 15203524
	.byte 0xe3
	reti
	.byte 0xe0, 0xec
	ldb	w, 56
	lda	xwa, (xsp+16)
	push	xwa
	call	16715583
	inc	8, xsp
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	call	16422496
	ld	xwa, 20480
	call	16569399
	cps	hl, 2
	jr	z, 99
	lda	xwa, (xsp+6)
	cps	hl, 1
	jr	z, 42
	cps	hl, 0
	jrl	nz, 480
	ldw	(xwa), 3
	pushw	231
	pushw	64790
	lda	xwa, (xsp+16)
	push	xwa
	call	16715583
	inc	8, xsp
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	439
	ldw	(xwa), 3
	ld	xwa, 20481
	call	16569399
	exts	hl
	pushw	hl
	pushw	231
	pushw	64796
	lda	xwa, (xsp+18)
	push	xwa
	call	16714340
	lda	xsp, (xsp+10)
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	389
	ldw	(xsp+6), 3
	ld	xwa, 20482
	call	16569399
	pushw	hl
	pushw	231
	pushw	64802
	lda	xwa, (xsp+18)
	push	xwa
	call	16714340
	lda	xsp, (xsp+10)
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	340
	ld	xwa, 20480
	call	16569399
	cps	hl, 2
	jr	z, 88
	cps	hl, 1
	jr	z, 38
	cps	hl, 0
	jrl	nz, 322
	pushw	231
	pushw	64808
	lda	xwa, (xsp+16)
	push	xwa
	call	16715583
	inc	8, xsp
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	285
	ld	xwa, 20481
	call	16569399
	exts	hl
	pushw	hl
	pushw	231
	pushw	64814
	lda	xwa, (xsp+18)
	push	xwa
	call	16714340
	lda	xsp, (xsp+10)
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	239
	ld	xwa, 20482
	call	16569399
	pushw	hl
	pushw	231
	pushw	64820
	lda	xwa, (xsp+18)
	push	xwa
	call	16714340
	lda	xsp, (xsp+10)
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	195
	ld	xwa, 8577
	call	16569399
	sla	hl, 2
	lda_24	xwa, 15203476
	.byte 0xe3
	reti
	.byte 0xe0, 0xec
	ldb	w, 56
	lda	xwa, (xsp+16)
	push	xwa
	call	16715583
	inc	8, xsp
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	145
	ld	xwa, 8580
	call	16569399
	sla	hl, 2
	lda_24	xwa, 15203476
	.byte 0xe3
	reti
	.byte 0xe0, 0xec
	ldb	w, 56
	lda	xwa, (xsp+16)
	push	xwa
	call	16715583
	inc	8, xsp
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jr	96
	ld	xwa, 8578
	call	16569399
	sla	hl, 2
	lda_24	xwa, 15203476
	.byte 0xe3
	reti
	.byte 0xe0, 0xec
	ldb	w, 56
	lda	xwa, (xsp+16)
	push	xwa
	call	16715583
	inc	8, xsp
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jr	47
	ld	xwa, 8579
	call	16569399
	sla	hl, 2
	lda_24	xwa, 15203476
	.byte 0xe3
	reti
	.byte 0xe0, 0xec
	ldb	w, 56
	lda	xwa, (xsp+16)
	push	xwa
	call	16715583
	inc	8, xsp
	call	16401616
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	call	16422496

MdPreset_ReturnZero2:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 24)
	ret

TtMdPreset:
	cp xbc, 0x1C0000C
	jr z, TtMdPreset_ReturnZero
	cp xbc, 0x1C0000B
	jr z, TtMdPreset_ReturnZero
	cp xbc, 0x1C00002
	jr z, TtMdPreset_ReturnZero
	cp xbc, 0x1C00001
	jr nz, TtMdPreset_ReturnZero
	or xde, xde
	jr nz, TtMdPreset_ReturnZero
	ld xwa, 0x560001
	ld xbc, 0x1E0007F
	lds32 xde, 1
	call SendEvent

TtMdPreset_ReturnZero:
	lds32 xhl, 0
	ret

IvMpstPageControlProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld (xsp + 12), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x1C0001E
	jr z, IvMpst_HandlePageSwitch
	cp xwa, 0x1E0003A
	jr z, IvMpst_HandleGetName
	cp xwa, 0x1C0000D
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
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jrl IvMpst_SendEventEpilogue

IvMpst_HandleGetName:
	pushw 0xE7
	pushw 0xFD7E
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
	ld xbc, 0x1E00094
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, IvMpst_CheckSecondView
	ld xwa, (xiz + 24)
	ld xbc, 0x1C00002
	lds32 xde, 0
	call SendEvent

IvMpst_CheckSecondView:
	ld xwa, (xiz + 28)
	ld xbc, 0x1E00094
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, IvMpst_InheritAndCheck
	ld xwa, (xiz + 28)
	ld xbc, 0x1C00002
	lds32 xde, 0
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
	cpi8_24 0x024756, 0x00
	jr nz, IvMpst_ActivateSecondView
	ld xwa, (xiz + 24)
	ld xbc, 0x1C00001
	lds32 xde, 0
	jr IvMpst_SendEventEpilogue

IvMpst_ActivateSecondView:
	ld xwa, (xiz + 28)
	ld xbc, 0x1C00001
	lds32 xde, 0

IvMpst_SendEventEpilogue:
	call SendEvent

IvMpst_ReturnZero:
	lds32 xhl, 0

IvMpst_Epilogue:
	pop xiz
	lda xsp, (xsp + 12)
	ret

MdPresetWithoutFunc:
	push xiz
	cp xbc, 0x1C00007
	jr nz, MdPresetWith_ReturnSuccess
	cpi8_24 0x024756, 0x00
	jr z, MdPresetWith_ReturnSuccess
	sti8_24 0x024756, 0x00
	ld xwa, 0x560001
	ld xbc, 0x1E00056
	lds32 xde, 0
	call SendEvent
	cps l, 2
	jr z, MdPresetWithout_Slot2Path
	cps l, 1
	jr nz, MdPresetWith_ReturnSuccess
	ld xwa, 0x560004
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 28)
	ld xbc, 0x1C00002
	lds32 xde, 0
	call SendEvent
	ld xwa, (xiz + 24)
	ld xbc, 0x1C00001
	lds32 xde, 0
	jr MdPresetWithout_SendCreate

MdPresetWithout_Slot2Path:
	ld xwa, 0x560005
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 28)
	ld xbc, 0x1C00002
	lds32 xde, 0
	call SendEvent
	ld xwa, (xiz + 24)
	ld xbc, 0x1C00001
	lds32 xde, 0

MdPresetWithout_SendCreate:
	call SendEvent

MdPresetWith_ReturnSuccess:
	lds32 xhl, 0
	pop xiz
	ret

MdPresetWithFunc:
	push xiz
	cp xbc, 0x1C00007
	jr nz, MdPreset_ReturnSuccess
	cpi8_24 0x024756, 0x01
	jr z, MdPreset_ReturnSuccess
	sti8_24 0x024756, 0x01
	ld xwa, 0x560001
	ld xbc, 0x1E00056
	lds32 xde, 0
	call SendEvent
	cps l, 2
	jr z, MdPresetWith_Slot2Path
	cps l, 1
	jr nz, MdPreset_ReturnSuccess
	ld xwa, 0x560004
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 24)
	ld xbc, 0x1C00002
	lds32 xde, 0
	call SendEvent
	ld xwa, (xiz + 28)
	ld xbc, 0x1C00001
	lds32 xde, 0
	jr MdPresetWith_SendCreate

MdPresetWith_Slot2Path:
	ld xwa, 0x560005
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 24)
	ld xbc, 0x1C00002
	lds32 xde, 0
	call SendEvent
	ld xwa, (xiz + 28)
	ld xbc, 0x1C00001
	lds32 xde, 0

MdPresetWith_SendCreate:
	call SendEvent

MdPreset_ReturnSuccess:
	lds32 xhl, 0
	pop xiz
	ret

MdPresetOKFunc:
	ld xhl, xde
	cp xbc, 0x1C00007
	jrl nz, MdPreset_PostMainFunc
	ld xwa, 0x560001
	ld xbc, 0x1E00056
	lds32 xde, 0
	call SendEvent
	cps l, 4
	jrl z, MdPresetOK_Slot4Path
	cps l, 3
	jrl z, MdPresetOK_Slot3Path
	ld8_24 a, 0x024756
	cps l, 2
	jr z, MdPresetOK_CheckSlotB
	cps l, 1
	jrl nz, MdPreset_PostMainFunc
	cps a, 1
	jr z, MdPresetOK_Slot1Func
	cps a, 0
	jrl nz, MdPreset_PostMainFunc
	ld xwa, 0x56000C
	ld xbc, 0x1E00090
	lds32 xde, 0
	call SendEvent
	add l, 0x44
	ldb h, 0x0
	extz xhl
	ld xwa, 0x1430002
	ld xbc, 0x1E30003
	ld xde, xhl
	jrl MdPreset_CallMainFunc

MdPresetOK_Slot1Func:
	ld xwa, 0x560015
	ld xbc, 0x1E00090
	lds32 xde, 0
	call SendEvent
	add l, 0x4D
	ldb h, 0x0
	extz xhl
	ld xwa, 0x1430002
	ld xbc, 0x1E30003
	ld xde, xhl
	jrl MdPreset_CallMainFunc

MdPresetOK_CheckSlotB:
	cps a, 1
	jr z, MdPresetOK_SlotBFunc
	cps a, 0
	jrl nz, MdPreset_PostMainFunc
	ld xwa, 0x56002D
	ld xbc, 0x1E00090
	lds32 xde, 0
	call SendEvent
	add l, 0x41
	ldb h, 0x0
	extz xhl
	ld xwa, 0x1430002
	ld xbc, 0x1E30003
	ld xde, xhl
	jrl MdPreset_CallMainFunc

MdPresetOK_SlotBFunc:
	ld xwa, 0x560039
	ld xbc, 0x1E00090
	lds32 xde, 0
	call SendEvent
	add l, 0x4A
	ldb h, 0x0
	extz xhl
	ld xwa, 0x1430002
	ld xbc, 0x1E30003
	ld xde, xhl
	jr MdPreset_CallMainFunc

MdPresetOK_Slot3Path:
	ld xwa, 0x560020
	ld xbc, 0x1E00090
	lds32 xde, 0
	call SendEvent
	add l, 0x1B
	ldb h, 0x0
	extz xhl
	ld xwa, 0x1430002
	ld xbc, 0x1E30003
	ld xde, xhl
	jr MdPreset_CallMainFunc

MdPresetOK_Slot4Path:
	ld xwa, 0x560029
	ld xbc, 0x1E0006B
	lds32 xde, 0
	call SendEvent
	st8_24 0x024758, l
	ld xwa, 0x560025
	ld xbc, 0x1E00090
	lds32 xde, 0
	call SendEvent
	ldb h, 0x0
	extz xhl
	ld xwa, 0x1430002
	ld xbc, 0x1E30004
	ld xde, xhl

MdPreset_CallMainFunc:
	call MainFuncCall

MdPreset_PostMainFunc:
	lds32 xhl, 0
	ret

MainMpstFunc:
	dec 4, xsp
	ld (xsp), xde
	cp xbc, 0x1E30004
	jr z, MainMpst_HandlePresetCopy
	cp xbc, 0x1E30003
	jr nz, MainMpst_ReturnZero
	ld xwa, (xsp)
	stda8 47084, a
	call SndParam_ApplyAndSync
	stdi8 32578, 35
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000EE
	jr MainMpst_PostEvent

MainMpst_HandlePresetCopy:
	stdi8 32578, 37
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000EE
	call ApPostEvent
	ld xwa, (xsp)
	extz wa
	call SndParam_AllocAndCopyPreset
	stdi8 32578, 35
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000EE

MainMpst_PostEvent:
	call ApPostEvent

MainMpst_ReturnZero:
	lds32 xhl, 0
	inc 4, xsp
	ret

MainMpst_ReadPresetIndex:
	ld8_24 l, 0x024758
	ret

TtMdExc:
	cp xbc, 0x1C0000C
	jr z, TtMdExc_ReturnZero
	cp xbc, 0x1C0000B
	jr z, TtMdExc_ReturnZero
	cp xbc, 0x1C00002
	jr z, TtMdExc_HandleClose
	cp xbc, 0x1C00001
	jr nz, TtMdExc_ReturnZero
	or xde, xde
	jr nz, TtMdExc_ReturnZero
	setda 6, 47074
	ld xwa, 0x570003
	call GetViewInstance
	ld xwa, (xhl + 38)
	ldw (xwa), 0x0
	jr TtMdExc_ReturnZero

TtMdExc_HandleClose:
	or xde, xde
	jr nz, TtMdExc_ReturnZero
	resda 6, 47074

TtMdExc_ReturnZero:
	lds32 xhl, 0
	ret

