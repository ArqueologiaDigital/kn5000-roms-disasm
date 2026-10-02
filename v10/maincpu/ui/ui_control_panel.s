; =============================================================================
; UI Control Panel (4K lines)
; =============================================================================
;
; Control panel key dispatch, UI task control, slider/scrollbar
; handlers, and the GroupBoxProc container widget. Routes button
; presses and dial events to the appropriate UI handlers.
; =============================================================================

	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 20)
	ld xbc, EVT_GRID_DRAW
	jr ParaLoadOptSendEvtReturn

ParaLoadOpt_BuildFromIZ1:
	ld a, (xiz + 1)
	extz wa
	sla wa, 2
	ld	xwa, (xbc+wa)
	push xwa
	ld xwa, (xsp + 20)
	push xwa
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 20)
	ld xbc, EVT_GRID_DRAW
	jr ParaLoadOptSendEvtReturn

ParaLoadOpt_BuildFromIZ2:
	ld c, (xiz + 2)
	extz bc
	sla bc, 2
	ld xwa, (xsp + 4)
	ld	xwa, (xwa+bc)
	push xwa
	ld xwa, (xsp + 20)
	push xwa
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 20)
	ld xbc, EVT_GRID_DRAW
	jr ParaLoadOptSendEvtReturn

ParaLoadOpt_BuildFromIZ3:
	ld c, (xiz + 3)
	extz bc
	sla bc, 2
	ld xwa, (xsp + 4)
	ld	xwa, (xwa+bc)
	push xwa
	ld xwa, (xsp + 20)
	push xwa
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 20)
	ld xbc, EVT_GRID_DRAW

ParaLoadOptSendEvtReturn:
	call SendEvent

ParaLoadOpt_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 62)
	ret

ParaLoadOptOKFunc:
	cp xbc, EVT_SW_IN
	jr nz, ParaLoadOptOK_ReturnZero
	ld xwa, NAKA_MAINFUNC_MainFlashFunc
	ld xbc, EVT_EAST_FLASH_WRITE
	call MainFuncCall

ParaLoadOptOK_ReturnZero:
	ld xhl, 0:i3
	ret

MainFlashFunc:
	cp xbc, EVT_EAST_FLASH_LOAD
	jr z, MainFlash_AudioDispatch
	cp xbc, EVT_EAST_FLASH_WRITE
	jr nz, MainFlash_ReturnZero
	ld (0x7f42:16), 37
	ld xwa, 0xffffffff
	ld xbc, EVT_INTERRUPT_TITLE
	ld xde, TITLE_MESAGE
	call ApPostEvent
	ld wa, 7:i3
	call CtrlPanel_IndicatorJumpTable
	ld (0x7f42:16), 35
	ld xwa, 0xffffffff
	ld xbc, EVT_INTERRUPT_TITLE
	ld xde, TITLE_MESAGE
	call ApPostEvent
	jr MainFlash_ReturnZero

MainFlash_AudioDispatch:
	ld wa, 7:i3
	call Audio_DispatchCommand

MainFlash_ReturnZero:
	ld xhl, 0:i3
	ret


; Computer Interface PCG Output routines
	.include "midi/computer_interface_pcg.s"
	.include "ui/drawbar_panel_ui.s"
	.include "demo/file_demo_proc.s"
	.include "file_io/disk_operations.s"
	.include "file_io/filename_password.s"
	.include "file_io/composer_filters.s"
	.include "file_io/smf_operations.s"
	.include "file_io/wallpaper.s"
	.include "file_io/single_load.s"
	.include "file_io/medley.s"
	.include "ui/password_slot_routines.s"
	.include "file_io/misc_ui.s"


AcTtlJgBoxProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld xiz, xwa
	ld xwa, (xsp + 12)
	cp xwa, EVT_SW_IN
	jr z, AcTtlJgBox_HandleOK
	ld xwa, xiz
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	jr AcTtlJgBox_InheritedCall

AcTtlJgBox_HandleOK:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, xiz
	ld xbc, EVT_CHECK_EDIT_SW
	ld xde, (xsp + 8)
	call SendEvent
	cp hl, 0:i3
	jr z, AcTtlJgBox_CallInherited
	ld xde, xiz
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, (xsp + 12)
	call MainFuncCall
	ld xhl, 0:i3
	jr AcTtlJgBox_Return

AcTtlJgBox_CallInherited:
	ld xwa, xiz
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)

AcTtlJgBox_InheritedCall:
	call InheritedProc

AcTtlJgBox_Return:
	pop xiz
	lda xsp, (xsp + 12)
	ret

AcParaStrBoxProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld xwa, (xsp + 8)
	cp xwa, EVT_NOT_PARA_DRAW
	jrl z, AcParaStrBox_HandleInit
	cp xwa, EVT_HIDE
	jr z, AcParaStrBox_HandleReEnable
	cp xwa, EVT_PARA_DRAW
	jr z, AcParaStrBox_HandleTimer
	cp xwa, EVT_PAINT
	jr z, AcParaStrBox_HandleSuspend
	cp xwa, EVT_SHOW
	jr z, AcParaStrBox_HandleCreate
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jrl AcParaStrBox_InheritedProcCall

AcParaStrBox_HandleCreate:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 40)
	ldw (xwa), 0x1
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jr AcParaStrBox_InheritedProcCall

AcParaStrBox_HandleSuspend:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xde, xiz
	ld xwa, (xhl + 36)
	ld xbc, (xsp + 8)
	call MainFuncCall
	jr AcParaStrBox_ReturnZero

AcParaStrBox_HandleTimer:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 40)
	cpw (xwa), 0x0
	jr nz, AcParaStrBox_ForwardInherited

AcParaStrBox_ReturnZero:
	ld xhl, 0:i3
	jr AcParaStrBox_Return

AcParaStrBox_ForwardInherited:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jr AcParaStrBox_InheritedProcCall

AcParaStrBox_HandleReEnable:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 40)
	ldw (xwa), 0x0
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jr AcParaStrBox_InheritedProcCall

AcParaStrBox_HandleInit:
	ld xwa, xiz
	call GetViewInstance
	ld xbc, (xhl + 40)
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr z, AcParaStrBox_SetFlagOne
	ldw (xbc), 0x0
	jr AcParaStrBox_AfterFlagSet

AcParaStrBox_SetFlagOne:
	ldw (xbc), 0x1

AcParaStrBox_AfterFlagSet:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)

AcParaStrBox_InheritedProcCall:
	call InheritedProc

AcParaStrBox_Return:
	pop xiz
	inc 8, xsp
	ret

PsWindowToggleProc:
	lda xsp, (xsp - 18)
	push xiz
	ld (xsp + 10), xde
	ld (xsp + 14), xbc
	ld (xsp + 18), xwa
	ld xwa, (xsp + 14)
	cp xwa, EVT_HIDE
	jrl z, PsWinToggle_HandleReEnable
	cp xwa, EVT_SW_IN
	jrl z, PsWinToggle_HandleOK
	cp xwa, EVT_SHOW
	jr z, PsWinToggle_HandleCreate
	ld xwa, (xsp + 18)
	ld xbc, (xsp + 14)
	ld xde, (xsp + 10)
	jrl AcFileSfxChild_InheritedCall

PsWinToggle_HandleCreate:
	ld xwa, (xsp + 18)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 40)
	cp xwa, 0xffffffff
	jr z, PsWinToggle_ForwardInherited
	ld xwa, (xiz + 44)
	cp xwa, 0xffffffff
	jr z, PsWinToggle_ForwardInherited
	ld xwa, (xsp + 18)
	ld xbc, EVT_GET_PARAM
	ld xde, 0:i3
	call SendEvent
	ld (xsp + 4), hl
	ld xde, (xiz + 40)
	ld xwa, (xiz + 48)
	ld xbc, EVT_ON_WINDOW
	call MainFuncCall
	ld xde, (xiz + 44)
	ld xwa, (xiz + 48)
	ld xbc, EVT_OFF_WINDOW
	call MainFuncCall
	ld de, (xsp + 4)
	exts xde
	ld xwa, (xiz + 48)
	ld xbc, EVT_WHICH_WINDOW
	call MainFuncCall
	cpw (xsp + 4), 0x0
	jr z, PsWinToggle_SendToChild44
	ld xwa, (xiz + 40)
	ld xbc, (xsp + 14)
	ld xde, (xsp + 10)
	jr PsWinToggle_SendChildEvent

PsWinToggle_SendToChild44:
	ld xwa, (xiz + 44)
	ld xbc, (xsp + 14)
	ld xde, (xsp + 10)

PsWinToggle_SendChildEvent:
	call SendEvent

PsWinToggle_ForwardInherited:
	ld xwa, (xsp + 18)
	ld xbc, (xsp + 14)
	ld xde, (xsp + 10)
	jrl AcFileSfxChild_InheritedCall

PsWinToggle_HandleOK:
	ld xwa, (xsp + 18)
	call GetViewInstance
	ld (xsp + 6), xhl
	ld xwa, (xsp + 18)
	ld xbc, EVT_CHECK_EDIT_SW
	ld xde, (xsp + 10)
	call SendEvent
	cp hl, 0:i3
	jrl z, PsWinToggle_InheritedFallback
	ld xbc, (xsp + 6)
	ld xwa, (xbc + 40)
	cp xwa, 0xffffffff
	jr z, PsWinToggle_ReturnZero
	ld xwa, (xbc + 44)
	cp xwa, 0xffffffff
	jr z, PsWinToggle_ReturnZero
	ld xwa, (xsp + 18)
	ld xbc, EVT_TOGGLE_PARAM
	ld xde, 0:i3
	call SendEvent
	ld (xsp + 4), hl
	ld de, (xsp + 4)
	exts xde
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 48)
	ld xbc, EVT_WHICH_WINDOW
	call MainFuncCall
	cpw (xsp + 4), 0x0
	jr z, PsWinToggle_HideChild40
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 44)
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 40)
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	jr PsWinToggle_SendToggleEvent

PsWinToggle_HideChild40:
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 40)
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 44)
	ld xbc, EVT_SHOW
	ld xde, 0:i3

PsWinToggle_SendToggleEvent:
	call SendEvent

PsWinToggle_ReturnZero:
	ld xhl, 0:i3
	jr PsWinToggle_Return

PsWinToggle_InheritedFallback:
	ld xwa, (xsp + 18)
	ld xbc, (xsp + 14)
	ld xde, (xsp + 10)
	jr AcFileSfxChild_InheritedCall

PsWinToggle_HandleReEnable:
	ld xwa, (xsp + 18)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 40)
	cp xwa, 0xffffffff
	jr z, PsWinToggle_ForwardToInherited
	ld xwa, (xiz + 44)
	cp xwa, 0xffffffff
	jr z, PsWinToggle_ForwardToInherited
	ld xwa, (xsp + 18)
	ld xbc, EVT_GET_PARAM
	ld xde, 0:i3
	call SendEvent
	ld (xsp + 4), hl
	cpw (xsp + 4), 0x0
	jr z, PsWinToggle_SelectChild44
	ld xwa, (xiz + 40)
	ld xbc, (xsp + 14)
	ld xde, (xsp + 10)
	jr PsWinToggle_SendSelectedChild

PsWinToggle_SelectChild44:
	ld xwa, (xiz + 44)
	ld xbc, (xsp + 14)
	ld xde, (xsp + 10)

PsWinToggle_SendSelectedChild:
	call SendEvent

PsWinToggle_ForwardToInherited:
	ld xwa, (xsp + 18)
	ld xbc, (xsp + 14)
	ld xde, (xsp + 10)

AcFileSfxChild_InheritedCall:
	call InheritedProc

PsWinToggle_Return:
	pop xiz
	lda xsp, (xsp + 18)
	ret

AcFileSfxBoxProc:
	lda xsp, (xsp - 28)
	push xiz
	ld (xsp + 24), xde
	ld xiz, xbc
	ld (xsp + 28), xwa
	cp xiz, EVT_NOT_PARA_DRAW
	jrl z, AcFileSfx_HandleInit
	cp xiz, EVT_HIDE
	jrl z, AcFileSfx_HandleReEnable
	cp xiz, EVT_SET_FILE_SFX
	jr z, AcFileSfx_HandleSfxEvent
	cp xiz, EVT_PAINT
	jr z, AcFileSfx_HandleSuspend
	cp xiz, EVT_SHOW
	jr z, AcFileSfx_HandleCreate
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)
	jrl AcFileSfxBox_InheritedCall

AcFileSfx_HandleCreate:
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld xwa, (xhl + 30)
	ldw (xwa), 0x1
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)
	jrl AcFileSfxBox_InheritedCall

AcFileSfx_HandleSuspend:
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld xiz, xhl
	lda xwa, (xiz + 14)
	ldw bc, 0xff
	call DrawFrame
	ld xde, (xsp + 28)
	ld xwa, (xiz + 26)
	ld xbc, EVT_GET_FILE_SFX
	call MainFuncCall
	jrl AcFileSfx_ReturnZero

AcFileSfx_HandleSfxEvent:
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 30)
	cpw (xwa), 0x0
	jrl z, AcFileSfx_ReturnZero
	lda xbc, (xsp + 16)
	ld xwa, (xsp + 28)
	call GetClientBox
	lda xhl, (xsp + 12)
	lda xde, (xsp + 16)
	ld wa, (xde)
	inc 2, wa
	ld (xhl), wa
	lda xbc, (xde + 2)
	ld wa, (xbc)
	inc 4, wa
	ld (xhl + 2), wa
	ld wa, (xde + 6)
	ld (xsp + 6), wa
	ld wa, (xbc)
	sub (xsp + 6), wa
	ld wa, (xsp + 6)
	exts xwa
	divs wa, 0x8
	ld (xsp + 6), wa
	ldw (xsp + 4), 0x1

AcFileSfx_DrawLoop:
	lda xhl, (AcFileSfx_DrawLoop_PtrTable:24)
	ld xwa, (xsp + 8)
	lda xix, (xwa + 22)
	lda xwa, (xsp + 16)
	lda xbc, (xsp + 12)
	ld xde, (xsp + 24)
	bit 0, de
	jr z, AcFileSfx_DrawDefault
	ld de, (xsp + 4)
	extz xde
	sll xde, 2
	add xhl, xde
	ld xde, (xhl)
	ld xhl, (xix)
	push xhl
	pushw PmBank_DrawRegionInfo_Data@hi16
	pushw PmBank_DrawRegionInfo_Data@lo16
	jr AcFileSfx_CallDrawString

AcFileSfx_DrawDefault:
	ld xde, (xhl)
	ld xhl, (xix)
	push xhl
	pushw PmBank_DrawRegionInfo_Data@hi16
	pushw PmBank_DrawRegionInfo_Data@lo16

AcFileSfx_CallDrawString:
	call DrawString
	ld wa, (xsp + 6)
	add (xsp + 14), wa
	ld xwa, (xsp + 24)
	srl xwa, 1
	ld (xsp + 24), xwa
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0x9
	jr c, AcFileSfx_DrawLoop

AcFileSfx_ReturnZero:
	ld xhl, 0:i3
	jr AcFileSfx_Return

AcFileSfx_HandleReEnable:
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld xwa, (xhl + 30)
	ldw (xwa), 0x0
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)
	jr AcFileSfxBox_InheritedCall

AcFileSfx_HandleInit:
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld xbc, (xhl + 30)
	ld xwa, (xsp + 24)
	or xwa, xwa
	jr z, AcFileSfx_SetFlagOne
	ldw (xbc), 0x0
	jr AcFileSfx_AfterFlagSet

AcFileSfx_SetFlagOne:
	ldw (xbc), 0x1

AcFileSfx_AfterFlagSet:
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)

AcFileSfxBox_InheritedCall:
	call InheritedProc

AcFileSfx_Return:
	pop xiz
	lda xsp, (xsp + 28)
	ret

AcMonoIndexToggleProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld xiz, xwa
	ld xwa, (xsp + 12)
	cp xwa, EVT_SW_IN
	jr z, IvFocus_HandleOK
	cp xwa, EVT_DRAW
	jr z, IvFocus_HandleDestroy
	ld xwa, xiz
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	jrl IvFocus_JumpInherited

IvFocus_HandleDestroy:
	ld xwa, xiz
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	lda xwa, (xhl + 40)
	cpw (xwa), 0x0
	jr lt, IvFocus_ReturnZero
	ld xbc, (xhl + 34)
	ld de, (xwa)
	exts xde
	cpw (xbc), 0x0
	jr z, IvFocus_SendListNotEmpty
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEXSW_UP
	jr IvFocus_SendEventReturn

IvFocus_SendListNotEmpty:
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEXSW_DOWN
	jr IvFocus_SendEventReturn

IvFocus_HandleOK:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, xiz
	ld xbc, EVT_CHECK_EDIT_SW
	ld xde, (xsp + 8)
	call SendEvent
	cp hl, 0:i3
	jr z, IvFocus_CallInherited
	ld xwa, xiz
	ld xbc, EVT_TOGGLE_PARAM
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 4)
	ld de, (xwa + 40)
	cp de, 0:i3
	jr lt, IvFocus_ReturnZero
	exts xde
	cp hl, 0:i3
	jr z, IvFocus_SendListEmpty
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEXSW_UP
	jr IvFocus_SendEventReturn

IvFocus_SendListEmpty:
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEXSW_DOWN

IvFocus_SendEventReturn:
	call SendEvent

IvFocus_ReturnZero:
	ld xhl, 0:i3
	jr IvFocus_Return

IvFocus_CallInherited:
	ld xwa, xiz
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)

IvFocus_JumpInherited:
	call InheritedProc

IvFocus_Return:
	pop xiz
	lda xsp, (xsp + 12)
	ret

; =============================================================================
; IvOneShotTimerProc - Single-shot timer event processor
;
; Manages timer-driven animation events. Used for delayed UI updates,
; animation frame ticks, and timed transitions.
;
; Events handled:
;   0x1c00001 - Create: set up timer, register tick event (0x1e50008)
;   0x1c0000d - Destroy: cancel timer (event 0x1c0000f)
;   0x1e0003a - Timer query: call Strcpy with params (0x9894, 0xea)
;   0x1e50009 - Schedule next tick: queue event 0x1e5000a
;   0x1e5000a - Timer fired: invoke registered callback via workspace +22
;
; Workspace layout:
;   +22: long - callback function pointer
; =============================================================================
IvOneShotTimerProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, EVT_WAKE_UP_NOW
	jrl z, IvTimer_HandleEvent0A
	cp xiz, EVT_WAKE_UP_TIME
	jr z, IvTimer_HandleEvent09
	cp xiz, EVT_GET_STRING
	jr z, IvTimer_HandleEvent3A
	cp xiz, EVT_DRAW
	jr z, IvTimer_HandleDestroy
	cp xiz, EVT_SHOW
	jr z, IvTimer_HandleCreate
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	jrl IvTimer_Cleanup

IvTimer_HandleCreate:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xde, (xsp + 12)
	ld xwa, (xhl + 22)
	ld xbc, EVT_I_WILL_WAKE_UP
	jr IvTimer_CallMainFunc

IvTimer_HandleDestroy:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	jr IvTimer_ReturnZero

IvTimer_HandleEvent3A:
	pushw IvTimer_HandleEvent3A_Str_N1shot@hi16
	pushw IvTimer_HandleEvent3A_Str_N1shot@lo16
	ld xwa, (xsp + 12)
	push xwa
	call Strcpy
	inc 8, xsp
	jr IvTimer_ReturnZero

IvTimer_HandleEvent09:
	ld xwa, EVT_WAKE_UP_NOW
	push xwa
	ld xwa, 0:i3
	push xwa
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 20)
	ld xde, (xsp + 20)
	call SetApTimer
	jr IvTimer_ReturnZero

IvTimer_HandleEvent0A:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld (xsp + 4), xhl
	push xiz
	ld xwa, (xsp + 12)
	push xwa
	ld xwa, 0:i3
	ld xbc, (xsp + 20)
	ld xde, (xsp + 20)
	call KillApTimer
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	ld xbc, xiz
	ld xde, (xsp + 8)

IvTimer_CallMainFunc:
	call MainFuncCall

IvTimer_ReturnZero:
	ld xhl, 0:i3

IvTimer_Cleanup:
	pop xiz
	lda xsp, (xsp + 12)
	ret

VwScreenTitleProc:
	dec 8, xsp
	push xiz
	ld xiz, xwa
	cp xbc, EVT_DRAW
	jr z, VwTitle_HandleDestroy
	ld xwa, xiz
	call InheritedProc
	jr VwTitle_Return

VwTitle_HandleDestroy:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	lda xwa, (xsp + 4)
	ldw (xwa + 2), 0x0
	ldw (xwa + 6), 0x1f
	ldw (xwa), 0x0
	ldw (xwa + 4), 0x13f
	ld xbc, (xhl + 28)
	push xbc
	pushm (xhl + 36)
	ld xbc, (xhl + 32)
	ld de, 0:i3
	call DrawTitleBar
	ld xhl, 0:i3

VwTitle_Return:
	pop xiz
	inc 8, xsp
	ret

DrawLineHelper:
	dec 8, xsp
	ld xhl, xbc
	cpw (xsp + 12), 0x0
	jr z, DrawLine_UseBCCoords
	lda xix, (xsp + 4)
	ld bc, (xwa + 2)
	ld (xix), bc
	ld wa, (xwa)
	ld (xix + 2), wa
	lda xbc, (xsp)
	ld wa, (xhl + 2)
	ld (xbc), wa
	ld wa, (xhl)
	ld (xbc + 2), wa
	ld xwa, xix
	jr DrawLine_Execute

DrawLine_UseBCCoords:
	ld xbc, xhl

DrawLine_Execute:
	call DrawLine
	inc 8, xsp
	retd 0x2

DrawProgressRectH:
	lda xsp, (xsp - 30)
	push xiz
	ld (xsp + 32), bc
	ld bc, (xsp + 38)
	cp bc, 3:i3
	jr z, DrawProgH_Mode3Setup
	cp bc, 2:i3
	jr z, DrawProgH_Mode2Setup
	cp bc, 1:i3
	scc16 nz, bc
	ld (xsp + 8), bc
	ldw (xsp + 10), 0x0
	ld xiy, xwa
	lda xix, (xsp + 24)
	ld bc, 4:i3
	ldirw

DrawProgH_CalcDimensions:
	lda xhl, (xsp + 24)
	ld bc, (xhl + 4)
	ld wa, bc
	sub wa, (xhl)
	mul xwa, de
	ld iz, wa
	extz xiz
	div iz, 0x64
	lda xwa, (xhl + 6)
	ld (xsp + 12), xwa
	lda xde, (xhl + 2)
	ld xwa, (xsp + 12)
	ld wa, (xwa)
	sub wa, (xde)
	mrdw3 0x9f, 0x28, 0x40
	ld ix, wa
	extz xix
	div ix, 0x64
	ld wa, bc
	sub wa, (xhl)
	ld (xsp + 4), wa
	sub (xsp + 4), iz
	cpw (xsp + 8), 0x0
	jr z, DrawProgH_SetLeftPos
	ld (xsp + 20), bc
	ldw (xsp + 6), 0xffff
	jr DrawProgH_SetupCenter

DrawProgH_Mode2Setup:
	ldw (xsp + 8), 0x1
	jr DrawProgH_InitFromRect

DrawProgH_Mode3Setup:
	ldw (xsp + 8), 0x0

DrawProgH_InitFromRect:
	ldw (xsp + 10), 0x1
	lda xhl, (xsp + 24)
	ld bc, (xwa + 2)
	ld (xhl), bc
	ld bc, (xwa)
	ld (xhl + 2), bc
	ld bc, (xwa + 6)
	ld (xhl + 4), bc
	ld wa, (xwa + 4)
	ld (xhl + 6), wa
	jr DrawProgH_CalcDimensions

DrawProgH_SetLeftPos:
	ld wa, (xhl)
	ld (xsp + 20), wa
	ldw (xsp + 6), 0x1

DrawProgH_SetupCenter:
	lda xhl, (xsp + 16)
	lda xiy, (xsp + 20)
	ld wa, (xiy)
	ld (xhl), wa
	ld bc, (xde)
	ld xwa, (xsp + 12)
	ld wa, (xwa)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	srl ix, 1
	ld wa, ix
	add wa, bc
	ld (xiy + 2), wa
	ld bc, (xde)
	ld xwa, (xsp + 12)
	ld wa, (xwa)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	sub bc, ix
	ld (xhl + 2), bc
	ldw (xsp + 14), 0x0
	cp iz, 0:i3
	jr ule, DrawProgH_AfterLoop1

DrawProgH_Loop1:
	lda xwa, (xsp + 20)
	lda xbc, (xsp + 16)
	pushm (xsp + 10)
	ld de, (xsp + 34)
	calr DrawLineHelper
	ld wa, (xsp + 6)
	add (xsp + 20), wa
	add (xsp + 16), wa
	incw 1, (xsp + 14)
	cp (xsp + 14), iz
	jr c, DrawProgH_Loop1

DrawProgH_AfterLoop1:
	lda xwa, (xsp + 24)
	lda xbc, (xsp + 20)
	cpw (xsp + 8), 0x0
	jr z, DrawProgH_SkipFill1
	ld wa, (xwa + 4)
	sub wa, iz
	ld (xbc), wa
	ldw (xsp + 6), 0xffff
	jr DrawProgH_AfterFill1

DrawProgH_SkipFill1:
	ld wa, (xwa)
	add wa, iz
	ld (xbc), wa
	ldw (xsp + 6), 0x1

DrawProgH_AfterFill1:
	lda xix, (xsp + 16)
	lda xhl, (xsp + 20)
	ld wa, (xhl)
	ld (xix), wa
	lda xde, (xsp + 24)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	ld (xhl + 2), wa
	ld bc, (xbc)
	ld wa, (xde + 6)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	ld (xix + 2), bc
	ldw (xsp + 14), 0x0
	cpw (xsp + 4), 0x0
	jr ule, DrawProgH_AfterLoop2

DrawProgH_Loop2:
	lda xwa, (xsp + 20)
	lda xbc, (xsp + 16)
	pushm (xsp + 10)
	ld de, (xsp + 34)
	calr DrawLineHelper
	ld wa, (xsp + 6)
	add (xsp + 16), wa
	incw 1, (xsp + 14)
	ld wa, (xsp + 14)
	cp wa, (xsp + 4)
	jr c, DrawProgH_Loop2

DrawProgH_AfterLoop2:
	lda xix, (xsp + 16)
	lda xhl, (xsp + 20)
	ld wa, (xhl)
	ld (xix), wa
	lda xde, (xsp + 24)
	lda xbc, (xde + 6)
	ld wa, (xbc)
	ld (xhl + 2), wa
	ld bc, (xbc)
	ld wa, bc
	sub wa, (xde + 2)
	exts xwa
	divs wa, 0x2
	sub bc, wa
	ld (xix + 2), bc
	ldw (xsp + 14), 0x0
	cpw (xsp + 4), 0x0
	jr ule, DrawProgH_AfterLoop3

DrawProgH_Loop3:
	lda xwa, (xsp + 20)
	lda xbc, (xsp + 16)
	pushm (xsp + 10)
	ld de, (xsp + 34)
	calr DrawLineHelper
	ld wa, (xsp + 6)
	add (xsp + 16), wa
	incw 1, (xsp + 14)
	ld wa, (xsp + 14)
	cp wa, (xsp + 4)
	jr c, DrawProgH_Loop3

DrawProgH_AfterLoop3:
	pop xiz
	lda xsp, (xsp + 30)
	retd 0x4

DrawProgressRectV:
	lda xsp, (xsp - 32)
	push xiz
	ld (xsp + 34), bc
	ld bc, (xsp + 40)
	cp bc, 3:i3
	jr z, DrawProgV_Mode3Setup
	cp bc, 2:i3
	jr z, DrawProgV_Mode2Setup
	cp bc, 1:i3
	scc16 nz, bc
	ld (xsp + 6), bc
	ldw (xsp + 8), 0x0
	ld xiy, xwa
	lda xix, (xsp + 26)
	ld bc, 4:i3
	ldirw

DrawProgV_CalcDimensions:
	lda xhl, (xsp + 26)
	lda xix, (xhl + 4)
	ld bc, (xix)
	ld wa, bc
	sub wa, (xhl)
	mul xwa, de
	ldfr_werp WA, 0xfa
	extz xwa
	div wa, 0x64
	ldfr_werp WA, 0xfa
	lda xde, (xhl + 6)
	lda xiy, (xhl + 2)
	ld wa, (xde)
	sub wa, (xiy)
	mrdw3 0x9f, 0x2a, 0x40
	ld iz, wa
	extz xwa
	div wa, 0x64
	ld iz, wa
	ld wa, bc
	sub wa, (xhl)
	ld (xsp + 4), wa
	ldto_werp WA, 0xfa
	sub (xsp + 4), wa
	cpw (xsp + 6), 0x0
	jr z, DrawProgV_SetTopPos
	ld (xsp + 22), bc
	ld wa, (xix)
	subw_erp WA, 0xfa
	ld (xsp + 18), wa
	jr DrawProgV_SetupCenter

DrawProgV_Mode2Setup:
	ldw (xsp + 6), 0x1
	jr DrawProgV_InitFromRect

DrawProgV_Mode3Setup:
	ldw (xsp + 6), 0x0

DrawProgV_InitFromRect:
	ldw (xsp + 8), 0x1
	lda xhl, (xsp + 26)
	ld bc, (xwa + 2)
	ld (xhl), bc
	ld bc, (xwa)
	ld (xhl + 2), bc
	ld bc, (xwa + 6)
	ld (xhl + 4), bc
	ld wa, (xwa + 4)
	ld (xhl + 6), wa
	jr DrawProgV_CalcDimensions

DrawProgV_SetTopPos:
	ld wa, (xhl)
	ld (xsp + 22), wa
	ld wa, (xhl)
	addw_erp WA, 0xfa
	ld (xsp + 18), wa

DrawProgV_SetupCenter:
	ld bc, (xiy)
	ld wa, (xde)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	ld wa, iz
	srl wa, 1
	sub bc, wa
	lda xwa, (xsp + 22)
	ld (xwa + 2), bc
	lda xde, (xsp + 18)
	ld (xde + 2), bc
	lda xiy, (xsp + 22)
	lda xix, (xsp + 14)
	ldiw
	ldiw
	pushm (xsp + 8)
	ld xbc, xde
	ld de, (xsp + 36)
	calr DrawLineHelper
	lda xwa, (xsp + 22)
	lda xbc, (xsp + 18)
	ld de, (xbc)
	ld (xwa), de
	ld de, (xsp + 28)
	ld (xwa + 2), de
	pushm (xsp + 8)
	ld de, (xsp + 36)
	calr DrawLineHelper
	lda xwa, (xsp + 22)
	ld bc, (xsp + 14)
	ld (xwa), bc
	lda xbc, (xsp + 26)
	ld de, (xbc + 2)
	ld bc, (xbc + 6)
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	ld bc, iz
	srl bc, 1
	add bc, de
	ld (xwa + 2), bc
	lda xde, (xsp + 18)
	ld (xde + 2), bc
	lda xiy, (xsp + 22)
	lda xix, (xsp + 10)
	ldiw
	ldiw
	pushm (xsp + 8)
	ld xbc, xde
	ld de, (xsp + 36)
	calr DrawLineHelper
	lda xwa, (xsp + 22)
	lda xbc, (xsp + 18)
	ld de, (xbc)
	ld (xwa), de
	ld de, (xsp + 32)
	ld (xwa + 2), de
	pushm (xsp + 8)
	ld de, (xsp + 36)
	calr DrawLineHelper
	lda xiy, (xsp + 14)
	lda xix, (xsp + 22)
	ldiw
	ldiw
	lda xiy, (xsp + 10)
	lda xix, (xsp + 18)
	ldiw
	ldiw
	lda xwa, (xsp + 22)
	lda xbc, (xsp + 18)
	pushm (xsp + 8)
	ld de, (xsp + 36)
	calr DrawLineHelper
	lda xwa, (xsp + 26)
	lda xbc, (xsp + 22)
	lda xde, (xsp + 18)
	cpw (xsp + 6), 0x0
	jr z, DrawProgV_SkipFill
	ld wa, (xwa + 4)
	subw_erp WA, 0xfa
	ld (xbc), wa
	sub wa, (xsp + 4)
	inc 1, wa
	ld (xde), wa
	jr DrawProgV_AfterFill

DrawProgV_SkipFill:
	ld wa, (xwa)
	addw_erp WA, 0xfa
	ld (xbc), wa
	add wa, (xsp + 4)
	dec 1, wa
	ld (xde), wa

DrawProgV_AfterFill:
	lda xwa, (xsp + 22)
	lda xhl, (xsp + 26)
	lda xde, (xhl + 2)
	ld bc, (xde)
	ld (xwa + 2), bc
	ld de, (xde)
	ld bc, (xhl + 6)
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 18)
	ld (xbc + 2), de
	pushm (xsp + 8)
	ld de, (xsp + 36)
	calr DrawLineHelper
	lda xwa, (xsp + 22)
	lda xhl, (xsp + 26)
	lda xde, (xhl + 6)
	ld bc, (xde)
	ld (xwa + 2), bc
	ld de, (xde)
	ld bc, de
	sub bc, (xhl + 2)
	exts xbc
	divs bc, 0x2
	sub de, bc
	lda xbc, (xsp + 18)
	ld (xbc + 2), de
	pushm (xsp + 8)
	ld de, (xsp + 36)
	calr DrawLineHelper
	pop xiz
	lda xsp, (xsp + 32)
	retd 0x4

ArrowProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 16), xwa
	cp xbc, EVT_PAINT
	jr z, DrawDouble_Inner
	ld xwa, (xsp + 16)
	call InheritedProc
	jr DrawDouble_Return

DrawDouble_Inner:
	ld xwa, (xsp + 16)
	call InheritedProc
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xiz, xhl
	ld (xsp + 4), xiz
	lda xbc, (xsp + 8)
	ld xwa, (xsp + 16)
	call GetClientBox
	lda xwa, (xsp + 8)
	lda xhl, (xiz + 26)
	ld xbc, (xsp + 4)
	lda xix, (xbc + 30)
	ld de, (xbc + 28)
	ld bc, (xiz + 22)
	cpw (xiz + 24), 0x0
	jr z, DrawDouble_SkipV
	pushm (xix)
	pushm (xhl)
	calr DrawProgressRectV
	jr DrawDouble_AfterV

DrawDouble_SkipV:
	pushm (xix)
	pushm (xhl)
	calr DrawProgressRectH

DrawDouble_AfterV:
	ld xhl, 0:i3

DrawDouble_Return:
	pop xiz
	lda xsp, (xsp + 16)
	ret

IvIndexSwCtrlProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, EVT_INDEXSW_DOWN_DIAL
	jrl z, Slider_Event1E00068
	cp xiz, EVT_INDEXSW_UP_DIAL
	jrl z, Slider_Event1E00068
	cp xiz, EVT_INDEXSW_DOWN_AIC
	jrl z, Slider_Event1E00069
	cp xiz, EVT_INDEXSW_UP_AIC
	jrl z, Slider_Event1E00069
	cp xiz, EVT_INDEXSW_DOWN
	jr z, Slider_Case1E0006B
	cp xiz, EVT_INDEXSW_UP
	jr z, Slider_Case1E0006B
	cp xiz, EVT_GET_STRING
	jr z, Slider_Case1E0006A
	cp xiz, EVT_DRAW
	jr z, Slider_Case1E00067
	cp xiz, EVT_SET_PARAM
	jr z, Slider_Case1E00066
	cp xiz, EVT_SHOW
	jrl nz, Slider_Error
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld wa, 0:i3
	jrl Slider_ReturnZero

Slider_Case1E00066:
	ld wa, 0:i3
	jrl Slider_ReturnZero

Slider_Case1E00067:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl Slider_UpdateDone

Slider_Case1E0006A:
	pushw IvIndexSwCtrlProc_Str_ISC@hi16
	pushw IvIndexSwCtrlProc_Str_ISC@lo16
	ld xwa, (xsp + 12)
	push xwa
	call Strcpy
	inc 8, xsp
	jrl Slider_NoChange

Slider_Case1E0006B:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xbc, (xsp + 4)
	ld wa, (xbc + 22)
	extz xwa
	cp (xsp + 8), xwa
	jrl c, Slider_NoChange
	ld wa, (xbc + 24)
	extz xwa
	cp (xsp + 8), xwa
	jrl ugt, Slider_NoChange
	cpw (xbc + 30), 0x0
	jr z, Slider_AtMax
	ld xwa, xiz
	cp xwa, EVT_INDEXSW_UP
	jr nz, Slider_Increment
	ld xwa, (xsp + 12)
	ld xbc, EVT_INDEXSW_UP_AIC
	ld xde, (xsp + 8)
	jr Slider_IncrDone

Slider_Increment:
	ld xwa, (xsp + 12)
	ld xbc, EVT_INDEXSW_DOWN_AIC
	ld xde, (xsp + 8)

Slider_IncrDone:
	call SetAutoInc

Slider_AtMax:
	ld xwa, (xsp + 4)
	cpw (xwa + 26), 0x0
	jrl z, Slider_NoChange
	cpw (xwa + 28), 0x0
	jr z, Slider_Decrement
	ld xwa, (xsp + 12)
	ld xbc, EVT_INDEXSW_DOWN_DIAL
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 12)
	ld xbc, EVT_INDEXSW_UP_DIAL
	ld xde, (xsp + 8)
	jr Slider_DecrDone

Slider_Decrement:
	ld xwa, (xsp + 12)
	ld xbc, EVT_INDEXSW_UP_DIAL
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 12)
	ld xbc, EVT_INDEXSW_DOWN_DIAL
	ld xde, (xsp + 8)

Slider_DecrDone:
	call SetDialDown
	ld wa, 1:i3

Slider_ReturnZero:
	call SetDialEnable
	jrl Slider_NoChange

Slider_Event1E00069:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld wa, (xhl + 22)
	extz xwa
	cp (xsp + 8), xwa
	jrl c, Slider_NoChange
	ld wa, (xhl + 24)
	extz xwa
	cp (xsp + 8), xwa
	jrl ugt, Slider_NoChange
	cpw (xhl + 30), 0x0
	jrl z, Slider_NoChange
	ld xwa, xiz
	cp xwa, EVT_INDEXSW_UP_AIC
	jr nz, Slider_DragIncr
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 8)
	jr Slider_UpdateDone

Slider_DragIncr:
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 8)
	jr Slider_UpdateDone

Slider_Event1E00068:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld wa, (xhl + 22)
	extz xwa
	cp (xsp + 8), xwa
	jr c, Slider_NoChange
	ld wa, (xhl + 24)
	extz xwa
	cp (xsp + 8), xwa
	jr ugt, Slider_NoChange
	cpw (xhl + 26), 0x0
	jr z, Slider_NoChange
	ld xwa, xiz
	cp xwa, EVT_INDEXSW_UP_DIAL
	jr nz, Slider_SmallIncr
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 8)
	jr Slider_UpdateDone

Slider_SmallIncr:
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 8)

Slider_UpdateDone:
	call SendEvent

Slider_NoChange:
	ld xhl, 0:i3
	jr Slider_Exit

Slider_Error:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc

Slider_Exit:
	pop xiz
	lda xsp, (xsp + 12)
	ret

; =============================================================================
; AcRotStrBoxProc - Scrollbar/rotary control animation handler
;
; Event-driven handler for smooth scrollbar and rotary encoder UI animations.
; Manages timer-based scrolling with auto-repeat functionality.
;
; Events handled:
;   0x1c00001 - Create: initialize scrollbar, set workspace +44 flag to 1
;   0x1c00002 - Re-enable: reset tracking state at +44 to 0
;   0x1c0000b - Suspend: forward event to parent
;   0x1c0000f - Timer tick: auto-scroll if flag at +44 is set
;   0x1c50000 - Init: set workspace +44 flag based on DE parameter
;   0x1e5000a - Timer event: schedule next auto-scroll tick
;
; Workspace layout:
;   +36: long - child widget pointer (forwarded events)
;   +40: word - scroll step size / timer interval
;   +42: word - scroll direction
;   +44: long - pointer to auto-repeat flag (0=stopped, 1=running)
; =============================================================================
AcRotStrBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld (xsp + 16), xwa
	ld xwa, (xsp + 12)
	cp xwa, EVT_NOT_PARA_DRAW
	jrl z, Scrollbar_Case1C00001
	cp xwa, EVT_PARA_DRAW
	jrl z, Scrollbar_Case1E5000A
	cp xwa, EVT_WAKE_UP_NOW
	jrl z, Scrollbar_Case1E00068
	cp xwa, EVT_PAINT
	jr z, Scrollbar_Case1E00069
	cp xwa, EVT_HIDE
	jr z, Scrollbar_Case1E00067
	cp xwa, EVT_SHOW
	jrl nz, Scrollbar_Error
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 44)
	ldw (xwa), 0x1
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	ld de, (xiz + 42)
	extz xde
	ld xwa, (xiz + 36)
	ld xbc, (xsp + 12)
	jr Scrollbar_Update

Scrollbar_Case1E00067:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 44)
	ldw (xwa), 0x0
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	ld wa, (xiz + 40)
	extz xwa
	ld xbc, EVT_WAKE_UP_NOW
	push xbc
	ld xbc, 0:i3
	push xbc
	ld xbc, (xsp + 24)
	ld xde, (xsp + 24)
	call KillApTimer
	jrl Scrollbar_Done

Scrollbar_Case1E00069:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xde, (xsp + 16)
	ld xwa, (xhl + 36)
	ld xbc, (xsp + 12)
	jr Scrollbar_Update

Scrollbar_Case1E00068:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xde, (xsp + 16)
	ld xwa, (xhl + 36)
	ld xbc, EVT_PAINT

Scrollbar_Update:
	call ApFuncCall
	jr Scrollbar_Done

Scrollbar_Case1E5000A:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld wa, (xwa + 40)
	extz xwa
	ld xbc, EVT_WAKE_UP_NOW
	push xbc
	ld xbc, 0:i3
	push xbc
	ld xbc, (xsp + 24)
	ld xde, (xsp + 24)
	call KillApTimer
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 44)
	cpw (xwa), 0x0
	jr z, Scrollbar_Done
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 4)
	ld wa, (xwa + 40)
	extz xwa
	ld xbc, EVT_WAKE_UP_NOW
	push xbc
	ld xbc, 0:i3
	push xbc
	ld xbc, (xsp + 24)
	ld xde, (xsp + 24)
	call SetApTimer

Scrollbar_Done:
	ld xhl, 0:i3
	jr Scrollbar_Return

Scrollbar_Case1C00001:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xbc, (xhl + 44)
	ld xwa, (xsp + 8)
	or xwa, xwa
	jr z, Scrollbar_SkipInit
	ldw (xbc), 0x0
	jr Scrollbar_InitDone

Scrollbar_SkipInit:
	ldw (xbc), 0x1

Scrollbar_InitDone:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	jr Scrollbar_ErrorExit

Scrollbar_Error:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)

Scrollbar_ErrorExit:
	call InheritedProc

Scrollbar_Return:
	pop xiz
	lda xsp, (xsp + 16)
	ret

IvIndexSwDelayProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xwa
	cp xbc, EVT_INDEXSW_DOWN_AIC
	jrl z, Bounds_Default
	cp xbc, EVT_INDEXSW_UP_AIC
	jrl z, Bounds_Default
	cp xbc, EVT_INDEXSW_DOWN
	jrl z, Bounds_Default
	cp xbc, EVT_INDEXSW_UP
	jr z, Bounds_Default
	cp xbc, EVT_GET_STRING
	jr z, Bounds_Case1E0006A
	cp xbc, EVT_DRAW
	jr z, Bounds_Case1E0006B
	cp xbc, EVT_HIDE
	jrl nz, Bounds_Error
	ld xwa, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 8)
	call GetViewInstance
	lda xde, (xhl + 28)
	cpw (xde), 0x0
	jrl lt, Bounds_Done
	ld wa, (xhl + 26)
	extz xwa
	ld xbc, EVT_INDEXSW_UP
	push xbc
	ld bc, (xde)
	exts xbc
	push xbc
	ld xbc, (xsp + 16)
	ld xde, 0xffffffff
	call KillApTimer
	jrl Bounds_Done

Bounds_Case1E0006B:
	ld xwa, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 8)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	jr Bounds_Done

Bounds_Case1E0006A:
	pushw IvIndexSwDelayProc_Str_ISD@hi16
	pushw IvIndexSwDelayProc_Str_ISD@lo16
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	jr Bounds_Done

Bounds_Default:
	ld xwa, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 8)
	call GetViewInstance
	ld xiz, xhl
	lda xde, (xiz + 28)
	cpw (xde), 0x0
	jr lt, Bounds_Done
	ld wa, (xiz + 22)
	extz xwa
	cp (xsp + 4), xwa
	jr c, Bounds_Done
	ld wa, (xiz + 24)
	extz xwa
	cp (xsp + 4), xwa
	jr ugt, Bounds_Done
	ld wa, (xiz + 26)
	extz xwa
	ld xbc, EVT_INDEXSW_UP
	push xbc
	ld bc, (xde)
	exts xbc
	push xbc
	ld xbc, (xsp + 16)
	ld xde, 0xffffffff
	call KillApTimer
	ld wa, (xiz + 26)
	extz xwa
	ld xbc, EVT_INDEXSW_UP
	push xbc
	ld bc, (xiz + 28)
	exts xbc
	push xbc
	ld xbc, (xsp + 16)
	ld xde, 0xffffffff
	call SetApTimer

Bounds_Done:
	ld xhl, 0:i3
	jr Bounds_Return

Bounds_Error:
	ld xwa, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc

Bounds_Return:
	pop xiz
	inc 8, xsp
	ret

IvWaitWinCtlProc:
	push xiz
	ld xiz, xwa
	cp xbc, EVT_OFF_WINDOW
	jr z, Edit_Default
	cp xbc, EVT_ON_WINDOW
	jr z, Edit_Case1E00068
	cp xbc, EVT_GET_STRING
	jr z, Edit_Case1E00069
	cp xbc, EVT_DRAW
	jr z, Edit_Case1E00067
	ld xwa, xiz
	call InheritedProc
	jr Edit_Return

Edit_Case1E00067:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jr Edit_Update

Edit_Case1E00069:
	pushw IvWaitWinCtlProc_Str_WWC@hi16
	pushw IvWaitWinCtlProc_Str_WWC@lo16
	push xde
	call Strcpy
	inc 8, xsp
	jr Edit_NoChange

Edit_Case1E00068:
	ld xwa, xiz
	call GetViewInstance
	lda xbc, (xhl + 22)
	ld xwa, (xbc)
	cp xwa, 0xffffffff
	jr z, Edit_NoChange
	ld xwa, (xbc)
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	jr Edit_Update

Edit_Default:
	ld xwa, xiz
	call GetViewInstance
	lda xbc, (xhl + 22)
	ld xwa, (xbc)
	cp xwa, 0xffffffff
	jr z, Edit_NoChange
	ld xwa, (xbc)
	ld xbc, EVT_HIDE
	ld xde, 0:i3

Edit_Update:
	call SendEvent

Edit_NoChange:
	ld xhl, 0:i3

Edit_Return:
	pop xiz
	ret

EditControlProc:
	ld	(xwa), 0
	ld	hl, 0:i3
	ret

; =============================================================================
; =============================================================================
	.include "storage/fdc_routines.s"

	.include "boot/main_title_ctrl_panel.s"


; =============================================================================
; GroupBoxNotify_SendSSFEvent (0xf98697) -- ADJUDICATED 2026-09-02: NOT UNDECODED.
; The marker here used to carry this project's self-tagged undecoded/still-in-
; .byte-form tag (spelled out only in the script below, so this line no longer
; trips kn5000_source_coverage.py's scanner), and it was STALE. 0xF98697 is
; UIState_KeyScan_Dispatch, spelled out below as 29 instruction directives with
; ZERO .byte. An independent MAME unidasm decode of
; original_ROMs/kn5000_v10_program.rom at that address names exactly the same 12
; absolute addresses as the source block (0x8d38, 0xe01f80, 0xef0797, 0xf986ef,
; 0xf9873b, 0xc07d..0xc080, 0xc00038, 0xfffe, 0xffffff), 12/12.
; ! Mnemonic TEXT does not compare: this tree spells cps/ldb_d8/lda_24/ld_rrl
; where unidasm prints cp/ld/lda/ld -- comparing opcode words scores 7/12 and
; would report a false "undecoded". Re-check with
;   python3 scripts/analysis/adjudicate_groupbox_ssf_marker.py
; =============================================================================
; Sends event 0x1c00038 to trigger GroupBoxProc_StartSSFPresentation.
;
; This function appears as a function-pointer entry in many widget handler
; chains (SwbtWr bank-2 listener lists SwbtB2_Code00_Listeners, SwbtB2_Code01_Listeners, SwbtB2_Code02_Listeners, etc.).
; It fires when a widget in one of those chains processes user-interaction events.
;
; Logic (decoded via unidasm):
;   1. Call 0xef0797 -- check bit 7 of DRAM 0x0406 (set once after boot by
;      Boot_DisplayScreen, cleared only during flash update). Returns HL=1
;      if set; returns early (HL=0) if not.
;   2. Read *(0x8d38) = index R into SSF_PresentationGateTable (ROM 0xe01f80).
;   3. Read P = SSF_PresentationGateTable[R] -- base of a ROM state-value array.
;   4. If P == 0 (null), return.
;   5. Walk the 16-bit array at P:
;      - If first entry == 0xfffe: send event unconditionally.
;      - If first entry == 0xffff: no entries, return.
;      - Otherwise: compare each entry to BC=(0xc080<<8)|(0xc07d) until match
;        or 0xffff sentinel. If match found, send event.
;   6. Send: XWA=0xffffffff XBC=0x1c00038 XDE=(0xc07d-0xc080 packed), jp FA9945.
;
; FA9945 routes 0x1c00038 to widgets registered via FA9752 whose match value
; (upper 16 bits of XDE) matches (0xc080<<8)|(0xc07d).
;
; =============================================================================
; KeyPress_StateDispatch -- Key press dispatcher
;
; Reads current state from 8D38, looks up pointer table at E01F80 to get
; the key mapping array for that state. Then either:
;   - PASS-THROUGH (0xfffe): broadcasts ANY key as event 0x1c00038
;   - SCAN (normal): searches for matching key code in the array
;   - EMPTY (0xffff): returns immediately
;
; Event data in XDE = (chain << 24) | (param << 16) | (C07E << 8) | C07F
; Target: XWA = 0xffffffff (broadcast to all handlers)
; Event: XBC = 0x01c00038 (key press event)
;
; Entry: Called from control panel key processing
; Uses: EF0797 (check key-scan enable), FA9945 (EventDispatch_Direct)
; =============================================================================
; ============================================================================
; UIState_KeyScan_Dispatch - Key scanning and event dispatch
; ============================================================================
; Checks if scanning enabled (bit 7 of RAM[0x0406]), loads current UI state
; from 0x8d38, indexes into keymap table at 0xe01f80. If map entry is
; 0xfffe, broadcasts pass-through event (0x01c00038). Otherwise searches
; for matching (chain<<8)|param key code and dispatches corresponding event.
; Plugged into each UI state as the standard key-scan handler.
; ============================================================================
UIState_KeyScan_Dispatch:
	call Boot_CheckConfigFlag7				; Check key-scan enable (bit 7 of RAM[0x0406])
	cp hl, 0:i3				; Returns HL=1 if enabled
	ret z					; Return if scanning disabled
	ld a, (0x8d38:16); Load current UI state ID
	extz wa					; Zero-extend to 16-bit
	sla wa, 2				; state * 4 (pointer table stride)
	lda xbc, (SSF_PresentationGateTable:24); Base of state->key-map pointer table
	ld	xix, (xbc+wa)
	or xix, xix				; Test if pointer is null
	ret z					; Return if no key map for this state
	cpw (xix), 0xfffe			; Check for PASS-THROUGH marker
	jr nz, KeyScan_CheckEmptyMarker			; Not pass-through, try normal scan
	; --- Pass-through path: broadcast any key press ---
	; Build XDE = (C080 << 24) | (C07D << 16) | (C07E << 8) | C07F
	ld	xde, 0:i3
	ld e, (0xc080:16); chain byte
	sll xde, 8				; shift up
	ld	xwa, 0:i3
	ld a, (0xc07d:16); param byte
	add xde, xwa				; merge into XDE
	sll xde, 8
	ld	xwa, 0:i3
	ld a, (0xc07e:16); additional key data
	add xde, xwa
	sll xde, 8
	ld	xwa, 0:i3
	ld a, (0xc07f:16); additional key data
	add xde, xwa
	ld xwa, 0xffffffff			; broadcast target (all handlers)
	ld xbc, EVT_ASSSWB			; key press event code
	jr KeyScan_DispatchEvent				; dispatch event
KeyScan_CheckEmptyMarker:
	cpw (xix), 0xffff			; Check for EMPTY marker
	ret z					; Return if no keys for this state
	; --- Normal scan: search array for matching (chain<<8)|param ---
	ld a, (0xc07d:16); param byte
	ld l, a
	extz hl
	ld e, (0xc080:16); chain byte
	ld c, e
	extz bc
	sll bc, 8				; BC = chain << 8
	add bc, hl				; BC = (chain << 8) | param = key code
KeyScan_ScanLoop:
	cp	(xix), bc
	jr nz, KeyScan_AdvanceEntry			; No match, advance to next entry
	; --- Match found: build XDE = (D<<24)|(E<<16)|(C07E<<8)|C07F ---
	ld d, 0x00:opc
	extz xde				; Zero-extend DE -> XDE
	sll xde, 8
	ld w, 0x00:opc
	extz xwa				; Zero-extend WA -> XWA
	add xde, xwa
	sll xde, 8
	ld	xwa, 0:i3
	ld a, (0xc07e:16)
	add xde, xwa
	sll xde, 8
	ld	xwa, 0:i3
	ld a, (0xc07f:16)
	add xde, xwa
	ld xwa, 0xffffffff			; broadcast target
	ld xbc, EVT_ASSSWB			; key press event code
KeyScan_DispatchEvent:
	jp EventDispatch_Direct				; tail-call EventDispatch_Direct
KeyScan_AdvanceEntry:
	inc 2, xix				; advance to next 16-bit entry
	cpw (xix), 0xffff			; check for end-of-list
	jr nz, KeyScan_ScanLoop			; continue scanning
	ret
; =============================================================================
; CtrlPanel_HandleKeyInput -- Alternate key handler (special key codes 0x00, 0x10)
;
; Key code 0x10: calls FDDFA7, then dispatches event with state from 8D3A
; Key code 0x00: if C07F bits 1:0 set and 26E2 bits 1:0 clear, jumps to
;                PartSelect_UpdateDisplayState (activation handler)
; =============================================================================
CtrlPanel_HandleKeyInput:
	ld a, (0xc07d:16); param byte (key code low)
	cp a, 0x10				; Check for special key 0x10
	jr z, CtrlPanel_HandleKey10			; Handle key 0x10
	cp a, 0:i3				; Check for key 0x00
	ret nz					; Other keys: return
	ld a, (0xc07f:16); additional key data
	and a, 0x03				; check bits 1:0
	ret z					; return if both clear
	ld a, (0x26e2:16); load activation state
	and a, 0x03				; check bits 1:0
	ret nz					; return if already active
	jr PartSelect_UpdateDisplayState				; activate
CtrlPanel_HandleKey10:
	call AudioMode_ResetVoiceState				; handler for key 0x10
	ld	xde, 0:i3
	ld e, (0x8d3a:16); load current state
	ld xwa, 0xffffffff			; broadcast target
	ld xbc, EVT_PART_SELECT			; key event code (different from main handler)
	call ApPostEvent				; dispatch event
	ret

PartSelect_UpdateDisplayState:
	ld a, (0xfc66:16)
	and a, 0x1
	cp a, 0:i3
	scc8 z, e
	ld (0x8d3a:16), e
	extz de
	pushw 0xff
	ldw wa, 0x90
	ldw bc, 0x10
	call AddswbWr
	ret

ApTaskControl:
	cp xbc, EVT_REFRESH_AP_TASK
	jr z, ApTaskCtrl_ReturnZero
	cp xbc, EVT_WAKE_UP_MAIN_TASK
	jr z, ApTaskCtrl_HandleAD
	cp xbc, EVT_SLEEP_MAIN_TASK
	jr z, ApTaskCtrl_HandleAC
	cp xbc, EVT_WAKE_UP_AP_TASK
	jr z, ApTaskCtrl_ReturnZero
	cp xbc, EVT_SLEEP_AP_TASK
	jr nz, ApTaskCtrl_ReturnZero
	ld wa, 1:i3
	call TaskSched_WakeBySlotID
	jr ApTaskCtrl_ResumeTask

ApTaskCtrl_HandleAC:
	ld xwa, NAKA_MAINFUNC_MainTaskControl
	call MainFuncCall

ApTaskCtrl_ResumeTask:
	call TaskSched_Resume
	jr ApTaskCtrl_ReturnZero

ApTaskCtrl_HandleAD:
	ld wa, 1:i3
	call TaskSched_WakeBySlotID

ApTaskCtrl_ReturnZero:
	ld xhl, 0:i3
	ret

MainTaskControl:
	cp xbc, EVT_REFRESH_AP_TASK
	jr z, MainTaskCtrl_HandleB0
	cp xbc, EVT_WAKE_UP_MAIN_TASK
	jr z, MainTaskCtrl_ReturnZero
	cp xbc, EVT_SLEEP_MAIN_TASK
	jr z, MainTaskCtrl_HandleAC
	cp xbc, EVT_WAKE_UP_AP_TASK
	jr z, MainTaskCtrl_HandleAF
	cp xbc, EVT_SLEEP_AP_TASK
	jr nz, MainTaskCtrl_ReturnZero
	ld xwa, 0xffffffff
	call ApPostEvent
	jr MainTaskCtrl_ResumeTask

MainTaskCtrl_HandleAF:
	ld wa, 4:i3
	call TaskSched_WakeBySlotID
	jr MainTaskCtrl_ReturnZero

MainTaskCtrl_HandleAC:
	ld wa, 4:i3
	call TaskSched_WakeBySlotID

MainTaskCtrl_ResumeTask:
	call TaskSched_Resume
	jr MainTaskCtrl_ReturnZero

MainTaskCtrl_HandleB0:
	ld xwa, 0xffffffff
	call ApPostEvent

MainTaskCtrl_ReturnZero:
	ld xhl, 0:i3
	ret
SleepMainTask:
	ld xwa, NAKA_APFUNC_ApTaskControl
	ld xbc, EVT_SLEEP_MAIN_TASK
	ld xde, 0:i3
	jrl ApTaskControl

WakeUpMainTask:
	ld xwa, NAKA_APFUNC_ApTaskControl
	ld xbc, EVT_WAKE_UP_MAIN_TASK
	ld xde, 0:i3
	jrl ApTaskControl

SleepApTask:
	ld xwa, NAKA_APFUNC_ApTaskControl
	ld xbc, EVT_SLEEP_AP_TASK
	ld xde, 0:i3
	jr MainTaskControl

WakeUpApTask:
	ld xwa, NAKA_APFUNC_ApTaskControl
	ld xbc, EVT_WAKE_UP_AP_TASK
	ld xde, 0:i3
	jrl MainTaskControl

RefreshApTask:
	ld (0xe3dc:16), 0
	ld (0xe3de:16), 0
	ld (0xe3e0:16), 0
	ld (0xe3e2:16), 0
	ld (0xe3e4:16), 255
	ld (0xe3e6:16), 255
	ld xwa, 0:i3
	ld (0x02749a:24), xwa
	ld (0x02749e:24), xwa
	ld (0x0274a2:24), xwa
	ld xwa, 0xffffffff
	ld xbc, EVT_SW_ON
	call DeleteEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SW_IN
	call DeleteEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SW_OFF
	call DeleteEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_DIAL
	call DeleteEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_LSW_DATA
	call DeleteEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_MODE
	call DeleteEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	call DeleteEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_INTERRUPT_TITLE
	call DeleteEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_REFRESH_AP_TASK
	ld xde, 0:i3
	jp ApPostEvent

RefreshSwEvent:
	ld xwa, 0:i3
	ld (0x02749a:24), xwa
	ld (0x02749e:24), xwa
	ld (0x0274a2:24), xwa
	ld xwa, 0xffffffff
	ld xbc, EVT_SW_ON
	call DeleteEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SW_IN
	call DeleteEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SW_OFF
	call DeleteEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_REFRESH_SW_EVENT
	ld xde, 0:i3
	jp ApPostEvent

KeyScan_Enable:
	ldw (0x03ef4e:24), 0x0001
	ret

KeyScan_Disable:
	ldw (0x03ef4e:24), 0x0000
	ret

MainAutoFree:
	push xde
	call Free
	inc 4, xsp
	ld xhl, 0:i3
	ret

MainRamControl:
	lda xsp, (xsp - 16)
	cp xbc, EVT_RAM_GET
	jrl z, RamCtrl_Set_Entry
	cp xbc, EVT_RAM_ADD
	jrl z, RamCtrl_Adjust_Entry
	cp xbc, EVT_RAM_PUT
	jrl nz, RamCtrl_Return
	ld (xsp), xde
	ld xwa, (xde)
	ld (xsp + 4), xwa
	pushw 0x16
	call Malloc
	inc 2, xsp
	ld (xsp + 12), xhl
	ld xhl, (xsp)
	ld xde, (xsp + 12)
	ld xiy, xhl
	ld xix, xde
	ldw bc, 0xb
	ldirw
	ld wa, (xhl + 4)
	cp wa, 4:i3
	jr z, RamCtrl_Read_Dword
	cp wa, 2:i3
	jr z, RamCtrl_Read_Word
	cp wa, 1:i3
	jr nz, RamCtrl_Read_InvalidSize
	ld xbc, xhl
	lda xbc, (xbc + 14)
	ld xwa, (xbc)
	ld e, a
	ld xwa, (xsp + 4)
	ld (xwa), e
	ld xwa, 0xff
	and (xbc), xwa
	jr RamCtrl_Read_Dispatch

RamCtrl_Read_Word:
	ld xwa, (xsp)
	lda xbc, (xwa + 14)
	ld xde, (xbc)
	ld xwa, (xsp + 4)
	ld (xwa), de
	ld xwa, 0xffff
	and (xbc), xwa
	jr RamCtrl_Read_Dispatch

RamCtrl_Read_Dword:
	ld xwa, (xsp)
	ld xbc, (xsp + 4)
	ld xwa, (xwa + 14)
	ld (xbc), xwa
	jr RamCtrl_Read_Dispatch

RamCtrl_Read_InvalidSize:
	ld xwa, (xsp)
	ld xbc, 0:i3
	ld (xwa + 14), xbc

RamCtrl_Read_Dispatch:
	ld xwa, 0xffffffff
	ld xbc, EVT_RAM_DATA
	ld xde, (xsp + 12)
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_AUTO_FREE
	ld xde, (xsp + 12)
	jrl RamCtrl_DispatchAndReturn

RamCtrl_Adjust_Entry:
	ld (xsp), xde
	ld xwa, (xde)
	ld (xsp + 4), xwa
	ld xwa, (xsp)
	ld de, (xwa + 4)
	cp de, 4:i3
	jr z, RamCtrl_Adjust_Dword
	ld xbc, (xwa + 10)
	ld xwa, (xwa + 6)
	cp de, 2:i3
	jr z, RamCtrl_Adjust_Word_CheckRange
	cp de, 1:i3
	jr nz, RamCtrl_Adjust_InvalidSize
	cp xwa, xbc
	jr ule, RamCtrl_Adjust_Byte_SignExt
	ld xbc, 0xff
	jr RamCtrl_Adjust_MaskAndStore

RamCtrl_Adjust_Byte_SignExt:
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	and xwa, 0xff
	exts wa
	exts xwa
	ld (xsp + 8), xwa
	jr RamCtrl_Adjust_ClampLow

RamCtrl_Adjust_Word_CheckRange:
	cp xwa, xbc
	jr ule, RamCtrl_Adjust_Word_SignExt
	ld xbc, 0xffff

RamCtrl_Adjust_MaskAndStore:
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	and xwa, xbc
	ld (xsp + 8), xwa
	jr RamCtrl_Adjust_ClampLow

RamCtrl_Adjust_Word_SignExt:
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ldiw_erp 0xe2, 0
	exts xwa
	ld (xsp + 8), xwa
	jr RamCtrl_Adjust_ClampLow

RamCtrl_Adjust_Dword:
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld (xsp + 8), xwa
	jr RamCtrl_Adjust_ClampLow

RamCtrl_Adjust_InvalidSize:
	ld xwa, 0:i3
	ld (xsp + 8), xwa

RamCtrl_Adjust_ClampLow:
	ld xwa, (xsp)
	ld xbc, (xwa + 14)
	cp xbc, 0x0
	jr le, RamCtrl_Adjust_ClampHigh
	ld xwa, (xwa + 6)
	ld xde, xwa
	sub xde, xbc
	cp xde, (xsp + 8)
	jr ge, RamCtrl_Adjust_ApplyOffset
	ld (xsp + 8), xwa
	jr RamCtrl_Adjust_WriteBack

RamCtrl_Adjust_ClampHigh:
	ld xwa, (xsp)
	ld xwa, (xwa + 10)
	ld xde, xwa
	sub xde, xbc
	cp xde, (xsp + 8)
	jr gt, RamCtrl_Adjust_StoreMax

RamCtrl_Adjust_ApplyOffset:
	add (xsp + 8), xbc
	jr RamCtrl_Adjust_WriteBack

RamCtrl_Adjust_StoreMax:
	ld (xsp + 8), xwa

RamCtrl_Adjust_WriteBack:
	pushw 0x16
	call Malloc
	inc 2, xsp
	ld (xsp + 12), xhl
	ld xhl, (xsp)
	ld xwa, (xsp + 12)
	ld xiy, xhl
	ld xix, xwa
	ldw bc, 0xb
	ldirw
	ld xbc, (xsp + 8)
	ld (xwa + 14), xbc
	ld wa, (xhl + 4)
	cp wa, 4:i3
	jr z, RamCtrl_Adjust_Write_Dword
	cp wa, 2:i3
	jr z, RamCtrl_Adjust_Write_Word
	cp wa, 1:i3
	jr nz, RamCtrl_Adjust_Write_InvalidSize
	ld xwa, (xsp + 4)
	ld (xwa), c
	jr RamCtrl_Adjust_Dispatch

RamCtrl_Adjust_Write_Word:
	ld xbc, (xsp + 8)
	ld xwa, (xsp + 4)
	ld (xwa), bc
	jr RamCtrl_Adjust_Dispatch

RamCtrl_Adjust_Write_Dword:
	ld xwa, (xsp + 4)
	ld xbc, (xsp + 8)
	ld (xwa), xbc
	jr RamCtrl_Adjust_Dispatch

RamCtrl_Adjust_Write_InvalidSize:
	ld xwa, (xsp)
	ld xbc, 0:i3
	ld (xwa + 14), xbc

RamCtrl_Adjust_Dispatch:
	ld xwa, 0xffffffff
	ld xbc, EVT_RAM_DATA
	ld xde, (xsp + 12)
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_AUTO_FREE
	ld xde, (xsp + 12)
	jr RamCtrl_DispatchAndReturn

RamCtrl_Set_Entry:
	ld (xsp), xde
	ld xwa, (xde)
	ld (xsp + 4), xwa
	ld xwa, (xsp)
	ld bc, (xwa + 4)
	cp bc, 4:i3
	jr z, RamCtrl_Set_Dword
	lda xde, (xwa + 14)
	cp bc, 2:i3
	jr z, RamCtrl_Set_Word_Mask
	cp bc, 1:i3
	jr nz, RamCtrl_Set_InvalidSize
	ld xbc, 0xff
	jr RamCtrl_Set_MaskAndWrite

RamCtrl_Set_Word_Mask:
	ld xbc, 0xffff

RamCtrl_Set_MaskAndWrite:
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	and xwa, xbc
	ld (xde), xwa
	jr RamCtrl_Set_Dispatch

RamCtrl_Set_Dword:
	ld xwa, (xsp + 4)
	ld xbc, (xsp)
	ld xwa, (xwa)
	ld (xbc + 14), xwa
	jr RamCtrl_Set_Dispatch

RamCtrl_Set_InvalidSize:
	ld xwa, 0:i3
	ld (xde), xwa

RamCtrl_Set_Dispatch:
	pushw 0x16
	call Malloc
	inc 2, xsp
	ld (xsp + 12), xhl
	ld xwa, (xsp)
	ld xde, (xsp + 12)
	ld xiy, xwa
	ld xix, xde
	ldw bc, 0xb
	ldirw
	ld xwa, 0xffffffff
	ld xbc, EVT_RAM_DATA
	ld xde, (xsp + 12)
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_AUTO_FREE
	ld xde, (xsp + 12)

RamCtrl_DispatchAndReturn:
	call ApPostEvent

RamCtrl_Return:
	ld xhl, 0:i3
	lda xsp, (xsp + 16)
	ret

MainBitControl:
	dec 8, xsp
	push xiz
	cp xbc, EVT_BIT_GET
	jr z, BitCtrl_ReadBit
	cp xbc, EVT_BIT_PUT
	jrl nz, BitCtrl_Return
	ld xiz, xde
	ld xwa, (xiz)
	ld (xsp + 4), xwa
	pushw 0xe
	call Malloc
	inc 2, xsp
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld xiy, xiz
	ld xix, xwa
	ld bc, 7:i3
	ldirw
	lda xbc, (xiz + 4)
	lda xde, (xwa + 8)
	cpw (xiz + 8), 0x0
	jr z, BitCtrl_ClearBit
	ld xwa, (xsp + 4)
	ld xbc, (xbc)
	or (xwa), xbc
	ldw (xde), 0x1
	jr BitCtrl_PostBitChangeEvent

BitCtrl_ClearBit:
	ld xbc, (xbc)
	xor xbc, 0xffffffff
	ld xwa, (xsp + 4)
	and (xwa), xbc
	ldw (xde), 0x0

BitCtrl_PostBitChangeEvent:
	ld xwa, 0xffffffff
	ld xbc, EVT_BIT_DATA
	ld xde, (xsp + 8)
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_AUTO_FREE
	ld xde, (xsp + 8)
	jr BitCtrl_PostFinalEvent

BitCtrl_ReadBit:
	ld xiz, xde
	ld xwa, (xiz)
	ld (xsp + 4), xwa
	ld xbc, (xiz + 4)
	ld xwa, (xsp + 4)
	and xbc, (xwa)
	lda xwa, (xiz + 8)
	or xbc, xbc
	jr z, BitCtrl_ReadBitZero
	ldw (xwa), 0x1
	jr BitCtrl_ReadBitDone

BitCtrl_ReadBitZero:
	ldw (xwa), 0x0

BitCtrl_ReadBitDone:
	pushw 0xe
	call Malloc
	inc 2, xsp
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld xiy, xiz
	ld xix, xwa
	ld bc, 7:i3
	ldirw
	ld xwa, 0xffffffff
	ld xbc, EVT_BIT_DATA
	ld xde, (xsp + 8)
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_AUTO_FREE
	ld xde, (xsp + 8)

BitCtrl_PostFinalEvent:
	call ApPostEvent

BitCtrl_Return:
	ld xhl, 0:i3
	pop xiz
	inc 8, xsp
	ret


	.include "audio/sound_navigation.s"


MainPmanControl:
	dec 4, xsp
	push xiz
	ld xwa, xbc
	cp xbc, EVT_PART_SELECT_PUT
	jrl z, MainPmanCtrl_HandleA0
	sub xwa, EVT_LSW_PUT
	cp xwa, 0x0
	jrl lt, MainTitle_SendEventDone
	cp xwa, 0x5
	jrl gt, MainTitle_SendEventDone
	add xwa, xwa
	add xwa, MainPmanControl_Data
	ld wa, (xwa)
	lda xix, (MainPmanCtrl_DispatchTable:24)
	jp	t, (xix+wa)

; MainPmanControl's six switch cases, not a table: it takes event - 0x1E00057 as
; the case, `ld wa,(<offset word>)` from the six s16 at 0xEA99F8 (0, 17, 34, 100,
; 125, 150; spelled MainPmanControl_Data above), then `lda xix,(<this>);
; jp t,xix+wa`.  Held as `.byte` (v10/v9) or a romslice `.incbin` (v7) before
; scripts/converters/convert_mainpman_switch.py; each case offset is an
; instruction boundary and every instruction re-encodes to the ROM bytes.
MainPmanCtrl_DispatchTable:
MainPmanCtrl_Case0:
	ld xiz, xde
	ld xwa, (xiz)
	ld bc, (xiz+4)
	ld de, (xiz+6)
	call SoundParam_NotifyChange
	jrl MainTitle_SendEventDone
MainPmanCtrl_Case1:
	ld xiz, xde
	ld xwa, (xiz)
	ld bc, (xiz+4)
	ld de, (xiz+6)
	call SndParam_LookupByKey
	jrl MainTitle_SendEventDone
MainPmanCtrl_Case2:
	ld xiz, xde
	ld xwa, (xiz)
	call SndParam_LookupReadOnly
	ld (xiz+4), hl
	pushw 12
	call Malloc
	inc 2, xsp
	ld (xsp+4), xhl
	ld xwa, (xsp+4)
	ld xiy, xiz
	ld xix, xwa
	ld bc, 6:i3
	ldirw
	ld xwa, 4294967295
	ld xbc, EVT_LSW_DATA
	ld xde, (xsp+4)
	call ApPostEvent
	ld xwa, 4294967295
	ld xbc, EVT_AUTO_FREE
	ld xde, (xsp+4)
	jr KeyScan_Disable_Join
MainPmanCtrl_Case3:
	ld xiz, xde
	ld xwa, (xiz)
	srl xwa, 16
	ld qwa, 0
	ld xbc, (xiz)
	pushm (xiz+6)
	ld de, (xiz+4)
	call SndParam_NotifyAndReturn
	jrl MainTitle_SendEventDone
MainPmanCtrl_Case4:
	ld xiz, xde
	ld xwa, (xiz)
	srl xwa, 16
	ld qwa, 0
	ld xbc, (xiz)
	pushm (xiz+6)
	ld de, (xiz+4)
	call SndParam_WrapNotify2
	jrl MainTitle_SendEventDone
MainPmanCtrl_Case5:
	ld xiz, xde
	ld xwa, (xiz)
	srl xwa, 16
	ld qwa, 0
	ld xbc, (xiz)
	call SndParam_LookupViaEncode
	ld (xiz+4), hl
	pushw 12
	call Malloc
	inc 2, xsp
	ld (xsp+4), xhl
	ld xwa, (xsp+4)
	ld xiy, xiz
	ld xix, xwa
	ld bc, 6:i3
	ldirw
	ld xwa, 4294967295
	ld xbc, EVT_LSW_DATA
	ld xde, (xsp+4)
	call ApPostEvent
	ld xwa, 4294967295
	ld xbc, EVT_AUTO_FREE
	ld xde, (xsp+4)
KeyScan_Disable_Join:
	call ApPostEvent
	jr MainTitle_SendEventDone

MainPmanCtrl_HandleA0:
	ldmi16 (xsp + 6), 0x8d3a
	cp xde, 0x10
	jr c, MainPmanCtrl_StorePartSelect
	cp xde, 0x15
	jr z, MainPmanCtrl_StorePartSelect
	cp xde, 0x16
	jr nz, MainPmanCtrl_CheckSoundParam

MainPmanCtrl_StorePartSelect:
	ld (0x8d3a:16), e
	jr MainPmanCtrl_LoadPartSelect

MainPmanCtrl_CheckSoundParam:
	ld xwa, 0x4100
	call SndParam_LookupReadOnly
	cp l, 1:i3
	jr z, MainPmanCtrl_SetPartSelectOne
	cp l, 5:i3
	jr nz, MainPmanCtrl_SetPartSelectZero

MainPmanCtrl_SetPartSelectOne:
	ld (0x8d3a:16), 1
	ld e, 0x1:opc
	jr MainPmanCtrl_CompareAndUpdate

MainPmanCtrl_SetPartSelectZero:
	ld (0x8d3a:16), 0

MainPmanCtrl_LoadPartSelect:
	ld e, (0x8d3a:16)

MainPmanCtrl_CompareAndUpdate:
	cp e, (xsp + 6)
	jr z, MainTitle_SendEventDone
	extz de
	pushw 0xff
	ldw wa, 0x90
	ldw bc, 0x10
	call AddswbWr

MainTitle_SendEventDone:
	ld xhl, 0:i3
	pop xiz
	inc 4, xsp
	ret

MainTitleControl:
	ld xwa, xde
	and xwa, 0xffff
	cp xbc, EVT_MAIN_LOOP_COUNT
	jrl z, MainTitleCtrl_HandleBB
	ld hl, wa
	cp xbc, EVT_SET_TITLE_FLAG
	jrl z, MainTitleCtrl_HandleBA
	cp xbc, EVT_OTHER_PART_LED
	jrl z, MainTitleCtrl_HandleAB
	ld a, (0x8d36:16)
	cp xbc, EVT_ACTIVATE_STATE
	jrl z, SeqState_DemoModeHandler
	cp xbc, EVT_RETURN_TITLE
	jr z, MainTitleCtrl_SaveAndTransition
	cp xbc, EVT_INTERRUPT_TITLE
	jr z, MainTitleCtrl_SaveAndTransition
	cp xbc, EVT_CHANGE_TITLE
	jr z, SeqState_TransitionMode
	cp xbc, EVT_CHANGE_MODE
	jrl nz, UIWidget_ReturnZero
	ldmm8 0x8d35, 0x8d34
	ld (0x8d34:16), l
	ldw wa, 0x48
	call CtrlPanel_SetIndicatorBit
	ld xwa, 0:i3
	ld (0x0274a2:24), xwa
	ld (0x02749e:24), xwa
	ld (0x02749a:24), xwa
	jrl UIWidget_ReturnZero

; =============================================================================
; SeqState_TransitionMode - Screen transition state handler
;
; Manages state transitions for the sequencer/demo screen mode changes.
; Saves current display state bytes (SFR 36150-36153) and clears animation
; state variables at 0x0274a2, 0x02749e, 0x02749a. Calls CtrlPanel_SetIndicatorBit
; to initiate the actual screen transition, then AudioMode_ResetVoiceState for cleanup.
;
; Animation state addresses:
;   0x02749a - Transition progress counter
;   0x02749e - Transition timer
;   0x0274a2 - Transition type/flags
;   0x0274a8-0x0274ae - Additional transition parameters
; =============================================================================
SeqState_TransitionMode:
	ld (0x8d37:16), a
	ldmm8 0x8d39, 0x8d38
	ld (0x8d36:16), l
	ld (0x8d38:16), l
	ldw wa, 0x61
	jr MainTitleCtrl_SetIndicatorAndClear

MainTitleCtrl_SaveAndTransition:
	ldmm8 0x8d39, 0x8d38
	ld (0x8d38:16), l
	ldw wa, 0x61

MainTitleCtrl_SetIndicatorAndClear:
	call CtrlPanel_SetIndicatorBit
	ld xwa, 0:i3
	ld (0x0274a2:24), xwa
	ld (0x02749e:24), xwa
	ld (0x02749a:24), xwa
	call AudioMode_ResetVoiceState
	jrl UIWidget_ReturnZero

SeqState_DemoModeHandler:
	cp xde, 0x8
	jrl nz, UIWidget_ReturnZero
	cp (0x8d38:16), a
	jr nz, SeqDemo_SaveCurrentState
	ld (0x8d37:16), a

SeqDemo_SaveCurrentState:
	ldmm8 0x8d39, 0x8d38
	ldmm8 0x8d35, 0x8d34
	jr UIWidget_ReturnZero

MainTitleCtrl_HandleAB:
	ld (0x0274ac:24), de
	ldw (0x0274ae:24), 0x000a
	jr UIWidget_ReturnZero

MainTitleCtrl_HandleBA:
	ld (0x0274a8:24), de
	ldw (0x0274aa:24), 0x000a
	jr UIWidget_ReturnZero

MainTitleCtrl_HandleBB:
	ld wa, (0x0274aa:24)
	cp wa, 0:i3
	jr z, MainTitleCtrl_CheckSecondTimer
	dec 1, wa
	ld (0x0274aa:24), wa
	cp wa, 0:i3
	jr nz, MainTitleCtrl_CheckSecondTimer
	ld wa, (0x0274a8:24)
	ld (0x0274a6:24), wa

MainTitleCtrl_CheckSecondTimer:
	ld wa, (0x0274ae:24)
	cp wa, 0:i3
	jr z, UIWidget_ReturnZero
	dec 1, wa
	ld (0x0274ae:24), wa
	cp wa, 0:i3
	jr nz, UIWidget_ReturnZero
	cpw (0x274ac:24), 0
	jr z, MainTitleCtrl_ClearIndicatorBit
	set 0, (0x8f5c:16)
	jr MainTitleCtrl_SetIndicator60

MainTitleCtrl_ClearIndicatorBit:
	res 0, (0x8f5c:16)

MainTitleCtrl_SetIndicator60:
	ldw wa, 0x60
	call CtrlPanel_SetIndicatorBit

UIWidget_ReturnZero:
	ld xhl, 0:i3
	ret

CtrlPanel_GetSelectionState:
	ld wa, (0x0274a6:24)
	bit 0, wa
	jr z, CtrlPanel_CheckBit1
	ld hl, 1:i3
	ret

CtrlPanel_CheckBit1:
	bit 1, wa
	jr z, CtrlPanel_SelectionReturnZero
	and wa, 0x18
	jr nz, CtrlPanel_SelectionReturnZero
	ld hl, 2:i3
	ret

CtrlPanel_SelectionReturnZero:
	ld hl, 0:i3
	ret

GetPartSelect:
	ld l, (0x8d3a:16)
	extz hl
	ret

GetCurrentPartSelect:
	ld l, (0x8d3a:16)
	ret

UI_PostPartChangeEvent:
	dec 2, xsp
	ld (xsp), a
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_MODE
	call DeleteEvent
	ld xde, 0:i3
	ld e, (xsp)
	add xde, NAKA_MODE_MD_PS
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_MODE
	call ApPostEvent
	inc 2, xsp
	ret

UI_PostModeChangeEvent:
	dec 2, xsp
	ld (xsp), a
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	call DeleteEvent
	ld xde, 0:i3
	ld e, (xsp)
	add xde, TITLE_PS
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	call ApPostEvent
	inc 2, xsp
	ret

; ============================================================================
; SoundCtrl_SendCommand - Send a command to the sound controller
; ============================================================================
; Input:  A = command parameter (sound control value)
; Output: None
; Sends a message (event 0x1c00016) to the sound controller subsystem.
; Packs the parameter into address 0x1a00000+param and dispatches via the
; system event handler at 0xfa9d58.
; ============================================================================
SoundCtrl_SendCommand:
	dec 2, xsp
	ld (xsp), a
	ld xwa, 0xffffffff
	ld xbc, EVT_INTERRUPT_TITLE
	call DeleteEvent
	ld xde, 0:i3
	ld e, (xsp)
	add xde, TITLE_PS
	ld xwa, 0xffffffff
	ld xbc, EVT_INTERRUPT_TITLE
	call ApPostEvent
	inc 2, xsp
	ret

UI_PostRefreshEvent:
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	jp ApPostEvent

UI_PostTimerResetEvent:
	ld xwa, 0xffffffff
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	jp ApPostEvent

SeqState_HasModeChanged:
	ld a, (0x8d36:16)
	cp a, (0x8d38:16)
	scc16 nz, hl
	ret

UI_PostDialEnable:
	ld e, a
	ld d, 0x0:opc
	extz xde
	ld xwa, 0xffffffff
	ld xbc, EVT_VALEN_SET
	jp ApPostEvent
; Two setters, `ld (RAM),a; ret`, for RAM 0x27494 and 0x27495.  Nothing
; calls or points at either: no 24- or 32-bit value in the ROM and no
; jr/jrl/calr displacement reaches 0xF99539 or 0xF9953F.  (Formerly UI_DialRangeData,
; held as `.byte`; it is not data.)
UI_StoreA_Ram27494:
	ld (0x027494:24), a
	ret
UI_StoreA_Ram27495:
	ld (0x027495:24), a
	ret

UI_PostEvent_0x6E:
	ld e, a
	ld d, 0x0:opc
	extz xde
	ld xwa, 0xffffffff
	ld xbc, EVT_AICEN_SET
	jp ApPostEvent

UI_PostDialRangeEvent:
	ld e, a
	ld d, 0x0:opc
	extz xde
	ld xwa, 0xffffffff
	ld xbc, EVT_EDIT_DOWN_SET
	jp ApPostEvent

UI_PostDialValueEvent:
	ld e, a
	ld d, 0x0:opc
	extz xde
	ld xwa, 0xffffffff
	ld xbc, EVT_EDIT_UP_SET
	jp ApPostEvent

BoxProc:
	push xiz
	ld xiz, xwa
	cp xbc, EVT_GET_BOX_COLOR
	jr z, BoxProc_HandleB2
	cp xbc, EVT_GET_BOX_BORDER
	jr z, BoxProc_HandleB1
	cp xbc, EVT_DRAW
	jr z, BoxProc_HandleDestroy
	ld xwa, xiz
	call ViewableProc
	jr BoxProc_Return

BoxProc_HandleDestroy:
	ld xwa, xiz
	call ViewableProc
	ld xwa, xiz
	call GetViewInstance
	lda xwa, (xhl + 14)
	ld bc, (xhl + 24)
	ld de, (xhl + 22)
	call DrawDesignBox
	ld xhl, 0:i3
	jr BoxProc_Return

BoxProc_HandleB1:
	ld xwa, xiz
	ld xiz, 0x18
	jr BoxProc_ReadFieldByOffset

BoxProc_HandleB2:
	ld xwa, xiz
	ld xiz, 0x16

BoxProc_ReadFieldByOffset:
	call GetViewInstance
	add xhl, xiz
	ld hl, (xhl)
	exts xhl

BoxProc_Return:
	pop xiz
	ret

GetClientBox:
	dec 8, xsp
	push xiz
	ld xiz, xbc
	call GetViewInstance
	lda xiy, (xhl + 14)
	lda xix, (xsp + 4)
	ld bc, 4:i3
	ldirw
	lda xbc, (xsp + 4)
	ld wa, (xhl + 24)
	ld xde, xiz
	calr GetClientBox2
	pop xiz
	inc 8, xsp
	ret

GetClientBox2:
	dec 4, xsp
	push xiz
	ld xiz, xde
	ld xde, 0:i3
	ld xiy, xbc
	ld xix, xiz
	ld bc, 4:i3
	ldirw
	cp wa, 0:i3
	jr mi, CtrlPanel_InvalidIndexHandler
	cp wa, 0xb
	jr le, CtrlPanel_DispatchByIndex
	sub wa, 0x74
	cp wa, 0xc
	jr lt, CtrlPanel_InvalidIndexHandler
	cp wa, 0x14
	jr le, CtrlPanel_DispatchByIndex
	sub wa, 0x17
	cp wa, 0x15
	jr lt, CtrlPanel_InvalidIndexHandler
	cp wa, 0x1d
	jr le, CtrlPanel_DispatchByIndex
	sub wa, 0x17
	cp wa, 0x1e
	jr lt, CtrlPanel_InvalidIndexHandler
	cp wa, 0x2a
	jr gt, CtrlPanel_InvalidIndexHandler

CtrlPanel_DispatchByIndex:
	add wa, wa
	lda xix, (CtrlPanel_DispatchByIndex_Data:24)
	ld	wa, (xix+wa)
	lda xix, (CtrlPanel_FrameDispatchTable:24)
	jp	t, (xix+wa)

CtrlPanel_FrameDispatchTable:
	ld	xde, 4:i3
	jr	CtrlPanel_ApplyMarginLoop
	ld	xde, 3:i3
	jr	CtrlPanel_ApplyMarginLoop
	ld	xde, 1:i3
	decm	2, (xiz+4)
	ld	wa, 2:i3

CtrlPanel_SubFrameOffset:
	sub (xiz + 6), wa

CtrlPanel_InvalidIndexHandler:
	or xde, xde
	jr z, CtrlPanel_MarginDone

CtrlPanel_ApplyMarginLoop:
	ld xiy, 0:i3
	cp xde, 0x0
	jr le, CtrlPanel_MarginDone
	lda xix, (xiz + 2)
	lda xhl, (xiz + 6)
	ld xbc, xiz
	lda xwa, (xiz + 4)

CtrlPanel_MarginAdjustStep:
	incw 1, (xix)
	decm 1, (xhl)
	incw 1, (xbc)
	decm 1, (xwa)
	inc 1, xiy
	cp xiy, xde
	jr lt, CtrlPanel_MarginAdjustStep

CtrlPanel_MarginDone:
	jrl CtrlPanel_FrameReturn
	lda xbc, (xsp + 6)
	lda xde, (xsp + 4)
	ldw wa, 0x1c
	jr CtrlFrame_AddLeftMargin
	lda xbc, (xsp + 6)
	lda xde, (xsp + 4)
	ldw wa, 0x17
	jr CtrlFrame_SubRightMargin
	lda xbc, (xsp + 6)
	lda xde, (xsp + 4)
	ldw wa, 0x1d
	jr CtrlFrame_AddLeftMargin
	lda xbc, (xsp + 6)
	lda xde, (xsp + 4)
	ldw wa, 0x18
	jr CtrlFrame_SubRightMargin
	lda xbc, (xsp + 6)
	lda xde, (xsp + 4)
	ldw wa, 0x20
	jr CtrlFrame_AddLeftMargin
	lda xbc, (xsp + 6)
	lda xde, (xsp + 4)
	ldw wa, 0x21

CtrlFrame_AddLeftMargin:
	call GetFrameSPSize
	ld wa, (xsp + 6)
	add (xiz), wa
	jr CtrlPanel_AfterLeftMargin
	lda xbc, (xsp + 6)
	lda xde, (xsp + 4)
	ldw wa, 0x24
	jr CtrlFrame_SubRightMargin
	lda xbc, (xsp + 6)
	lda xde, (xsp + 4)
	ldw wa, 0x25

CtrlFrame_SubRightMargin:
	call GetFrameSPSize
	ld wa, (xsp + 6)
	sub (xiz + 4), wa

CtrlPanel_AfterLeftMargin:
	ld xde, 2:i3
	jrl CtrlPanel_ApplyMarginLoop
	ld xde, 1:i3
	decm 1, (xiz + 4)
	ld wa, 1:i3
	jrl CtrlPanel_SubFrameOffset
	lda xbc, (xsp + 6)
	lda xde, (xsp + 4)
	ldw wa, 0x19
	jr CtrlPanel_Frame_AddLeftMargin
	lda xbc, (xsp + 6)
	lda xde, (xsp + 4)
	ldw wa, 0x14
	jr CtrlPanel_Frame_SubtractTopMargin
	lda xbc, (xsp + 6)
	lda xde, (xsp + 4)
	ldw wa, 0x1a
	jr CtrlPanel_Frame_AddLeftMargin
	lda xbc, (xsp + 6)
	lda xde, (xsp + 4)
	ldw wa, 0x15
	jr CtrlPanel_Frame_SubtractTopMargin
	lda xbc, (xsp + 6)
	lda xde, (xsp + 4)
	ldw wa, 0x1b
	jr CtrlPanel_Frame_AddLeftMargin
	lda xbc, (xsp + 6)
	lda xde, (xsp + 4)
	ldw wa, 0x16
	jr CtrlPanel_Frame_SubtractTopMargin
	lda xbc, (xsp + 6)
	lda xde, (xsp + 4)
	ldw wa, 0x1e
	jr CtrlPanel_Frame_AddLeftMargin
	lda xbc, (xsp + 6)
	lda xde, (xsp + 4)
	ldw wa, 0x1f

CtrlPanel_Frame_AddLeftMargin:
	call GetFrameSPSize
	ld wa, (xsp + 6)
	add (xiz), wa
	jr CtrlPanel_AfterTopMargin
	lda xbc, (xsp + 6)
	lda xde, (xsp + 4)
	ldw wa, 0x22
	jr CtrlPanel_Frame_SubtractTopMargin
	lda xbc, (xsp + 6)
	lda xde, (xsp + 4)
	ldw wa, 0x23

CtrlPanel_Frame_SubtractTopMargin:
	call GetFrameSPSize
	ld wa, (xsp + 6)
	sub (xiz + 4), wa

CtrlPanel_AfterTopMargin:
	ld xde, 1:i3
	jrl CtrlPanel_ApplyMarginLoop

CtrlPanel_FrameReturn:
	pop xiz
	inc 4, xsp
	ret

GetBoxCenter:
	ld de, (xwa + 4)
	sub de, (xwa)
	inc 1, de
	exts xde
	divs de, 0x2
	ld hl, (xwa)
	add hl, de
	ld (xbc), hl
	ld de, (xwa + 2)
	ld wa, (xwa + 6)
	sub wa, de
	inc 1, wa
	exts xwa
	divs wa, 0x2
	add de, wa
	ld (xbc + 2), de
	ret

GetFrameColor:
	call GetViewInstance
	ld wa, (xhl + 24)
	cp wa, 0xa4
	jr z, BoxCheck_ReturnZero
	cp wa, 0x84
	jr z, BoxCheck_ReturnZero
	cp wa, 0xa3
	jr z, BoxCheck_ReturnZero
	cp wa, 0x83
	jr z, BoxCheck_ReturnZero
	cp wa, 0xa2
	jr z, BoxCheck_ReturnZero
	cp wa, 0x82
	jr z, BoxCheck_ReturnZero
	cp wa, 0xa1
	jr z, BoxCheck_ReturnZero
	cp wa, 0x81
	jr z, BoxCheck_ReturnZero
	cp wa, 0xa0
	jr z, BoxCheck_ReturnZero
	cp wa, 0x80
	jr z, BoxCheck_ReturnZero
	cp wa, 0xcc
	jr gt, BoxCheck_ReturnZero
	cp wa, 0xc0
	jr ge, BoxCheck_ReturnZero
	cp wa, 0xb
	jr gt, BoxCheck_ReturnZero

BoxCheck_ReturnZero:
	ld hl, 0:i3
	ret

BoxLeftCheck:
	cp wa, 0x88
	jr gt, BoxLeftCheck_ReturnZero
	cp wa, 0x80
	jr lt, BoxLeftCheck_ReturnZero
	ld hl, 1:i3
	ret

BoxLeftCheck_ReturnZero:
	ld hl, 0:i3
	ret

BoxRightCheck:
	cp wa, 0xa8
	jr gt, BoxRightCheck_ReturnZero
	cp wa, 0xa0
	jr lt, BoxRightCheck_ReturnZero
	ld hl, 1:i3
	ret

BoxRightCheck_ReturnZero:
	ld hl, 0:i3
	ret

; =============================================================================
; GroupBoxProc (approx. 0xf998xx)
; =============================================================================
; Event handler for a "group box" UI container widget.  Dispatches on XBC
; (event code) to one of ~20 sub-handlers covering layout, focus, display,
; and interactive item events.
;
; Key event dispatch entries relevant to the Feature Demo / SSF system:
;   0x1c00038 -> GroupBoxProc_StartSSFPresentation (direct)
;   0x1c00030 -> GroupBoxProc_Ev1C00030 -> GroupBoxProc_StartSSFPresentation
;
; GroupBoxProc_StartSSFPresentation (0xf9a273) is the CORRECT code path that
; initiates SSF presentation playback: it builds a workspace with type-tag
; 0x0000b80a and sends event 0x1c0001c via direct SendEvent (FA9660), causing
; AcPresentationControlProc to pass its B80A check and send 0x1c00006
; (which starts SSF parsing and loading FTBMP images).
;
; MAME investigation (Feb 2026): event 0x1c00038 is never routed to
; GroupBoxProc during Feature Demo navigation, so GroupBoxProc_StartSSFPresentation
; never fires.  This is the confirmed root cause of the Feature Demo image
; display failure.
; =============================================================================
GroupBoxProc:
	lda xsp, (xsp - 40)
	pushw iz
	ld (xsp + 30), xde
	ld (xsp + 34), xbc
	ld (xsp + 38), xwa
	ld xde, (xsp + 34)
	ld (xsp + 4), xde
	cp xde, EVT_UPDATE_SCREEN
	jrl z, GroupBox_DisplayUpdate
	cp xde, EVT_INTERRUPT_EXIT
	jrl z, GroupBox_NavUpDown
	cp xde, EVT_RESET_INTERRUPT_TIME
	jrl z, GroupBox_NavUpDown
	ld xwa, (xsp + 30)
	cp xde, EVT_SET_DIAL_FOCUS
	jrl z, GroupBox_SetDialFocus
	cp xde, EVT_GET_DIAL_FOCUS
	jrl z, GroupBox_GetDialFocus
	cp xde, EVT_EDIT_UP_SET
	jrl z, GroupBox_DialUp
	cp xde, EVT_EDIT_DOWN_SET
	jrl z, GroupBox_DialDown
	ld xbc, (xsp + 30)
	cp xde, EVT_VALEN_SET
	jrl z, GroupBox_DialEnable
	cp xde, EVT_AICEN_SET
	jrl z, GroupBox_CancelBack
	cp xde, EVT_ASSSWB
	jrl z, GroupBoxProc_StartSSFPresentation
	cp xde, EVT_SW_BOTH
	jrl z, GroupBoxProc_Ev1C00030
	cp xde, EVT_AUTO_INC
	jrl z, GroupBox_HandleKeyRepeatTimer
	cp xde, EVT_DIAL
	jrl z, GroupBox_HandleCursorNav
	cp xde, EVT_SW_IN_MODE
	jrl z, GroupBox_HandleStateCompare
	ld xwa, xde
	cp xwa, EVT_RETURN_TITLE
	jrl z, GroupBox_HandleRefresh
	cp xwa, EVT_INTERRUPT_TITLE
	jrl z, GroupBox_HandleSoundCommand
	cp xwa, EVT_CHANGE_TITLE
	jrl z, GroupBox_HandleModeChange
	cp xwa, EVT_CHANGE_MODE
	jr z, GroupBox_HandlePartChange
	ld xwa, (xsp + 4)
	sub xwa, EVT_SHOW
	cp xwa, 0x0
	jrl lt, GroupBox_ForwardToBoxProc
	cp xwa, 0x9
	jr le, CtrlPanel_FuncDispatch
	sub xwa, 0x20008a
	cp xwa, 0xa
	jrl lt, GroupBox_ForwardToBoxProc
	cp xwa, 0x13
	jr le, CtrlPanel_FuncDispatch
	dec 6, xwa
	cp xwa, 0x14
	jrl lt, GroupBox_ForwardToBoxProc
	cp xwa, 0x26
	jrl gt, GroupBox_ForwardToBoxProc

; Control panel function dispatch
CtrlPanel_FuncDispatch:
	add xwa, CtrlPanel_FuncDispatch_Data
	ld wa, (xwa)
	extz wa
	sll wa, 1
	ld xix, CtrlPanel_FuncDispatch_Data_2
	ld	wa, (xix+wa)
	lda xix, (GroupBox_HandlePartChange:24)
	jp	t, (xix+wa)

GroupBox_HandlePartChange:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_CHECK_HOLD
	ld xde, 0:i3
	call SendEvent
	ld (xsp + 2), hl
	cpw (xsp + 2), 0x0
	jrl nz, GroupBox_ReturnZero
	call CheckNotDrawFlag
	cp hl, 0:i3
	scc16 z, wa
	ld (xsp + 6), wa
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_IS_INTERRUPT
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr z, GroupBox_PartChange_SendEvents

GroupBox_PartChange_DrawLoop:
	cpw (xsp + 6), 0x0
	jr nz, GroupBox_PartChange_SendRefresh
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call SendEvent

GroupBox_PartChange_SendRefresh:
	ld xwa, 0xffffffff
	ld xbc, EVT_RETURN_TITLE
	ld xde, 0:i3
	call SendEvent
	cpw (xsp + 6), 0x0
	jr nz, GroupBox_PartChange_CheckDraw
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call SendEvent

GroupBox_PartChange_CheckDraw:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_IS_INTERRUPT
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr nz, GroupBox_PartChange_DrawLoop

GroupBox_PartChange_SendEvents:
	ld xwa, (xsp + 30)
	ld xde, xwa
	ld xbc, (xsp + 34)
	call SendEvent
	call GetTitleOld
	ld xwa, xhl
	ld xbc, EVT_ACTIVATE_STATE
	ld xde, 3:i3
	call SendEvent
	call GetModeOld
	ld xwa, xhl
	ld xbc, EVT_ACTIVATE_STATE
	ld xde, 1:i3
	call SendEvent
	call GetModeNow
	ld xwa, xhl
	ld xbc, EVT_ACTIVATE_STATE
	ld xde, 0:i3
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_ACTIVATE_STATE
	ld xde, 2:i3
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_GET_START_SCREEN
	ld xde, 0:i3
	call SendEvent
	ld xwa, xhl
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_ACTIVATE_STATE
	ld xde, 0x8
	jrl GroupBox_NavDispatch

GroupBox_HandleModeChange:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_CHECK_HOLD
	ld xde, 0:i3
	call SendEvent
	ld (xsp + 2), hl
	cpw (xsp + 2), 0x0
	jrl nz, GroupBox_ReturnZero
	call CheckNotDrawFlag
	cp hl, 0:i3
	scc16 z, wa
	ld (xsp + 6), wa
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_IS_INTERRUPT
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr z, GroupBox_ModeChange_SendEvents

GroupBox_ModeChange_DrawLoop:
	cpw (xsp + 6), 0x0
	jr nz, GroupBox_ModeChange_SendRefresh
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call SendEvent

GroupBox_ModeChange_SendRefresh:
	ld xwa, 0xffffffff
	ld xbc, EVT_RETURN_TITLE
	ld xde, 0:i3
	call SendEvent
	cpw (xsp + 6), 0x0
	jr nz, GroupBox_ModeChange_CheckDraw
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call SendEvent

GroupBox_ModeChange_CheckDraw:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_IS_INTERRUPT
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr nz, GroupBox_ModeChange_DrawLoop

GroupBox_ModeChange_SendEvents:
	ld xwa, (xsp + 30)
	ld xde, xwa
	ld xbc, (xsp + 34)
	call SendEvent
	call GetTitleOld
	ld xwa, xhl
	ld xbc, EVT_ACTIVATE_STATE
	ld xde, 3:i3
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_ACTIVATE_STATE
	ld xde, 2:i3
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_GET_START_SCREEN
	ld xde, 0:i3
	call SendEvent
	ld xwa, xhl
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_ACTIVATE_STATE
	ld xde, 0x8
	jrl GroupBox_NavDispatch

GroupBox_HandleSoundCommand:
	ld xwa, (xsp + 30)
	cp xwa, TITLE_MESAGE
	jr nz, GroupBox_SndCmd_GetTitle
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_HOLD
	ld xde, 0:i3
	call SendEvent

GroupBox_SndCmd_GetTitle:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_CHECK_HOLD
	ld xde, 0:i3
	call SendEvent
	ld (xsp + 4), hl
	ld wa, (xsp + 4)
	ld (xsp + 2), wa
	call CheckNotDrawFlag
	cp hl, 0:i3
	scc16 z, wa
	ld (xsp + 6), wa
	ld xwa, (xsp + 30)
	ld xbc, EVT_GET_START_SCREEN
	ld xde, 0:i3
	call SendEvent
	ld xwa, xhl
	ld xbc, EVT_SEARCH_CLASS
	ld xde, NAKA_CLASS_IvIntVari
	call SendEvent
	or xhl, xhl
	jr z, GroupBox_SndCmd_CheckDraw
	call GetTitleNow
	cp xhl, TITLE_MESAGE
	jr z, GroupBox_SndCmd_CheckDraw
	call GetTitleNow
	cp xhl, TITLE_WELCOM
	jrl nz, GroupBox_SndCmd_CheckTitleWidget

GroupBox_SndCmd_CheckDraw:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_IS_INTERRUPT
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr z, GroupBox_TitleCheck

GroupBox_SndCmd_DrawLoop:
	cpw (xsp + 6), 0x0
	jr nz, GroupBox_SndCmd_SendRefresh
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call SendEvent

GroupBox_SndCmd_SendRefresh:
	ld xwa, 0xffffffff
	ld xbc, EVT_RETURN_TITLE
	ld xde, 0:i3
	call SendEvent
	cpw (xsp + 6), 0x0
	jr nz, GroupBox_SndCmd_ClearStatus
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call SendEvent

GroupBox_SndCmd_ClearStatus:
	ldw (xsp + 2), 0x0
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_IS_INTERRUPT
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr nz, GroupBox_SndCmd_DrawLoop

GroupBox_TitleCheck:
	cpw (xsp + 2), 0x0
	jrl nz, GroupBox_ReturnZero

GroupBox_SndCmd_ProcessTitle:
	ld xwa, (xsp + 30)
	ld xbc, EVT_GET_START_SCREEN
	ld xde, 0:i3
	call SendEvent
	ld xwa, xhl
	ld xbc, EVT_SEARCH_LINK
	ld xde, EVT_INTERRUPT_OFF
	call SendEvent
	or xhl, xhl
	jrl nz, GroupBox_SndCmd_PostRefreshEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_INTERRUPT_HOLD
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 30)
	ld xde, xwa
	ld xbc, (xsp + 34)
	call SendEvent
	call GetTitleOld
	ld xwa, xhl
	ld xbc, EVT_ACTIVATE_STATE
	ld xde, 4:i3
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_ACTIVATE_STATE
	ld xde, 2:i3
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_ACTIVATE_STATE
	ld xde, 6:i3
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_GET_RETURN_SCREEN
	ld xde, 0:i3
	call SendEvent
	ld xwa, xhl
	ld xbc, EVT_SHOW
	ld xde, 3:i3
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_ACTIVATE_STATE
	ld xde, 0x8
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_SET_INTERRUPT_TIME
	ld xde, 0:i3
	call SendEvent
	cpw (xsp + 4), 0x0
	jrl z, GroupBox_ReturnZero
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_GET_START_SCREEN
	ld xde, 0:i3
	call SendEvent
	ld xwa, xhl
	ld xbc, EVT_SEARCH_CLASS
	ld xde, NAKA_CLASS_IvIntVari
	call SendEvent
	or xhl, xhl
	jrl z, GroupBox_ReturnZero
	ld de, (xsp + 4)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_HOLD
	jrl GroupBox_NavDispatch

GroupBox_SndCmd_CheckTitleWidget:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_IS_INTERRUPT
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jrl z, GroupBox_TitleCheck
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_GET_RETURN_SCREEN
	ld xde, 0:i3
	call SendEvent
	ld xwa, xhl
	ld xbc, EVT_SEARCH_CLASS
	ld xde, NAKA_CLASS_IvIntVari
	call SendEvent
	or xhl, xhl
	jrl z, GroupBox_TitleCheck
	cpw (xsp + 6), 0x0
	jr nz, GroupBox_SndCmd_RefreshAfterDraw
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call SendEvent

GroupBox_SndCmd_RefreshAfterDraw:
	ld xwa, 0xffffffff
	ld xbc, EVT_RETURN_TITLE
	ld xde, 0:i3
	call SendEvent
	cpw (xsp + 6), 0x0
	jrl nz, GroupBox_SndCmd_ProcessTitle
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call SendEvent
	jrl GroupBox_SndCmd_ProcessTitle

GroupBox_SndCmd_PostRefreshEvent:
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	jrl GroupBox_NavDispatch

GroupBox_HandleRefresh:
	call GetTitleNow
	ld xwa, xhl
	ld xde, (xsp + 30)
	ld xbc, (xsp + 34)
	call SendEvent
	call GetTitleOld
	ld xwa, xhl
	ld xbc, EVT_ACTIVATE_STATE
	ld xde, 7:i3
	call SendEvent
	call GetTitleOld
	ld xwa, xhl
	ld xbc, EVT_ACTIVATE_STATE
	ld xde, 3:i3
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_ACTIVATE_STATE
	ld xde, 5:i3
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_GET_RETURN_SCREEN
	ld xde, 0:i3
	call SendEvent
	ld xwa, xhl
	ld xbc, EVT_SHOW
	ld xde, 4:i3
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_ACTIVATE_STATE
	ld xde, 0x8
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_SET_INTERRUPT_TIME
	ld xde, 0:i3
	jrl GroupBox_NavDispatch

GroupBox_HandleStateCompare:
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_HOLD
	ld xde, 0:i3
	call SendEvent
	call GetModeNow
	ldiw_erp 0xee, 0
	extz xhl
	sll xhl, 2
	lda xwa, (GroupBox_HandleStateCompare_Data:24)
	ld xde, xwa
	add xde, xhl
	ld xbc, (xsp + 30)
	ldiw_erp 0xe6, 0
	extz xbc
	sll xbc, 2
	add xwa, xbc
	ld xwa, (xwa)
	cp xwa, (xde)
	jr z, GroupBox_StateCompare_Default
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, EVT_CHANGE_MODE
	jrl GroupBox_NavDispatch

GroupBox_StateCompare_Default:
	ld xwa, (xsp + 38)
	ld xbc, EVT_CHANGE_MODE
	ld xde, NAKA_MODE_MD_NORMAL
	jrl GroupBox_NavDispatch
	ld xwa, (xsp + 38)
	call SetCurrentTarget
	ldw (0x03ef50:24), 0x0000
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, (xsp + 34)
	calr BoxProc
	call GetCurrentTarget
	cp xhl, (xsp + 38)
	jrl nz, GroupBox_ReturnZero
	call CheckNotDrawFlag
	cp hl, 0:i3
	jrl z, GroupBox_ReturnZero
	ld xwa, (xsp + 30)
	cp xwa, 0x5
	jr z, GroupBox_Nav_SendSuspend
	ld xwa, (xsp + 38)
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	jr GroupBox_Nav_SendEventAndUpdate

GroupBox_Nav_SendSuspend:
	ld xwa, (xsp + 38)
	ld xbc, EVT_PAINT
	ld xde, 0:i3

GroupBox_Nav_SendEventAndUpdate:
	call SendEvent
	ld wa, 1:i3
	call SetNeedUpdate
	call UpdateScreen
	ld wa, 0:i3
	jrl GroupBox_DisableDisplay
	ld wa, 0:i3
	calr SetDialEnable
	ld xwa, 0xffffffff
	ld (0x03ef6a:24), xwa
	lda xde, (0x0274e8:24)
	lda xbc, (xde + 15)
	ld xwa, xbc
	inc 1, xde
	lda xbc, (xbc+448)

GroupBox_Nav_ClearWidgetFlags:
	ld (xde), 0x0
	ld (xwa), 0x0
	lda xde, (xde + 28)
	lda xwa, (xwa + 28)
	cp xwa, xbc
	jr ule, GroupBox_Nav_ClearWidgetFlags
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, (xsp + 34)
	calr BoxProc
	jrl GroupBox_ReturnZero
	ld xwa, (xsp + 38)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	jrl GroupBox_NavDispatch

GroupBox_HandleCursorNav:
	cpw (0x3ef50:24), 0
	jr z, GroupBox_CursorNav_AddLsw
	cp xwa, 0x0
	jr ge, GroupBox_CursorNav_LoadPositive
	ld xwa, (0x03ef56:24)
	ld xbc, (0x03ef5e:24)
	ld xde, (0x03ef66:24)
	jr GroupBox_CursorNav_SendAndTitle

GroupBox_CursorNav_LoadPositive:
	ld xwa, (0x03ef52:24)
	ld xbc, (0x03ef5a:24)
	ld xde, (0x03ef62:24)

GroupBox_CursorNav_SendAndTitle:
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_RESET_INTERRUPT_TIME
	ld xde, 0:i3
	call SendEvent
	jr GroupBox_CursorNav_UpdateScreen

GroupBox_CursorNav_AddLsw:
	ld xwa, 4:i3
	ld de, 4:i3
	calr MainLswAdd

GroupBox_CursorNav_UpdateScreen:
	ld wa, 1:i3
	call SetNeedUpdate
	call UpdateScreen
	ld wa, 0:i3
	jrl GroupBox_DisableDisplay
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, (xsp + 34)
	calr BoxProc
	ld xwa, (xsp + 38)
	ld xbc, EVT_SEARCH_CLASS
	ld xde, NAKA_CLASS_IvMainEditSw
	call SendEvent
	or xhl, xhl
	jr z, GroupBox_KeyPress_CheckRange
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, EVT_SEND_SW_ON
	call SendEvent

GroupBox_KeyPress_CheckRange:
	ld xwa, (xsp + 30)
	cp xwa, 0xff
	jrl ugt, GroupBox_ReturnZero
	ld xwa, (xsp + 30)
	and xwa, 0x1f
	ld (xsp + 4), wa
	ld xwa, (xsp + 30)
	srl xwa, 7
	and xwa, 0x1
	ld (xsp + 6), wa
	ld bc, (xsp + 6)
	extz xbc
	ld xwa, xbc
	sll xwa, 3
	sub xwa, xbc
	add xwa, xwa
	ld de, (xsp + 4)
	extz xde
	ld xbc, xde
	sll xbc, 3
	sub xbc, xde
	sll xbc, 2
	add xbc, xwa
	ld xwa, 0x274e8
	add xwa, xbc
	ld (xwa), 0x1
	cp (xwa + 1), 0x1
	jrl nz, GroupBox_ReturnZero
	ld xwa, EVT_AUTO_INC
	push xwa
	ld xwa, (xsp + 34)
	push xwa
	ld xwa, 0x10
	ld xbc, (xsp + 46)
	ld xde, (xsp + 46)
	call SetApTimer
	jrl GroupBox_ReturnZero
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, (xsp + 34)
	calr BoxProc
	ld xwa, (xsp + 38)
	ld xbc, EVT_SEARCH_CLASS
	ld xde, NAKA_CLASS_IvMainEditSw
	call SendEvent
	or xhl, xhl
	jr z, GroupBox_KeyRelease_CheckRange
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, EVT_SEND_SW_OFF
	call SendEvent

GroupBox_KeyRelease_CheckRange:
	ld xwa, (xsp + 30)
	cp xwa, 0xff
	jrl ugt, GroupBox_ReturnZero
	ld xwa, (xsp + 30)
	and xwa, 0x1f
	ld (xsp + 4), wa
	ld xwa, (xsp + 30)
	srl xwa, 7
	and xwa, 0x1
	ld (xsp + 6), wa
	ld bc, (xsp + 6)
	extz xbc
	ld xwa, xbc
	sll xwa, 3
	sub xwa, xbc
	add xwa, xwa
	ld de, (xsp + 4)
	extz xde
	ld xbc, xde
	sll xbc, 3
	sub xbc, xde
	sll xbc, 2
	add xbc, xwa
	ld xwa, 0x274e8
	add xwa, xbc
	ld (xwa+), 0x00
	cp (xwa), 0x0
	jrl z, GroupBox_ReturnZero
	ld (xwa), 0x0
	ld xwa, EVT_AUTO_INC
	push xwa
	ld xwa, (xsp + 34)
	push xwa
	ld xwa, 0x10
	ld xbc, (xsp + 46)
	ld xde, (xsp + 46)
	call KillApTimer
	jrl GroupBox_ReturnZero
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, (xsp + 34)
	calr BoxProc
	ld xwa, (xsp + 38)
	ld xbc, EVT_SEARCH_CLASS
	ld xde, NAKA_CLASS_IvMainEditSw
	call SendEvent
	or xhl, xhl
	jr z, GroupBox_KeyHold_CheckRange
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, EVT_SEND_SW_IN
	call SendEvent

GroupBox_KeyHold_CheckRange:
	ld xwa, (xsp + 30)
	cp xwa, 0xff
	jrl ugt, GroupBox_ReturnZero
	ld xwa, (xsp + 30)
	cp xwa, 0xf
	jr nz, GroupBox_TimerRepeat_SendNav
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_IS_INTERRUPT
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jrl nz, GroupBox_ReturnZero
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_SET_HOLD
	ld xde, 0:i3
	jrl GroupBox_NavDispatch

GroupBox_TimerRepeat_SendNav:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_RESET_INTERRUPT_TIME
	ld xde, 0:i3
	jrl GroupBox_NavDispatch

GroupBox_HandleKeyRepeatTimer:
	ld xwa, (xsp + 30)
	and xwa, 0x1f
	ld (xsp + 4), wa
	ld xwa, (xsp + 30)
	srl xwa, 7
	and xwa, 0x1
	ld (xsp + 6), wa
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	ld wa, (xsp + 4)
	extz xwa
	ld xde, xwa
	sll xde, 3
	sub xde, xwa
	sll xde, 2
	add xde, xbc
	lda xwa, (0x0274e9:24)
	add xwa, xde
	cp (xwa), 0x0
	jrl z, GroupBox_ReturnZero
	ld xwa, EVT_AUTO_INC
	push xwa
	ld xwa, (xsp + 34)
	push xwa
	ld xwa, 3:i3
	ld xbc, (xsp + 46)
	ld xde, (xsp + 46)
	call SetApTimer
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	ld de, (xsp + 4)
	extz xde
	ld xwa, xde
	sll xwa, 3
	sub xwa, xde
	sll xwa, 2
	add xwa, xbc
	ld xde, 0x274e8
	add xde, xwa
	ld xwa, (xde + 2)
	ld xbc, (xde + 6)
	ld xde, (xde + 10)
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_RESET_INTERRUPT_TIME
	ld xde, 0:i3
	jrl GroupBox_NavDispatch

; Handler for event 0x1c00030 within GroupBoxProc.
; Calls BoxProc, then queries widget status (event 0x1e00024).
; Falls through to GroupBoxProc_StartSSFPresentation regardless of result.
GroupBoxProc_Ev1C00030:
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, (xsp + 34)
	calr BoxProc
	ld xwa, (xsp + 38)
	ld xbc, EVT_SEARCH_CLASS
	ld xde, NAKA_CLASS_IvMainEditSw
	call SendEvent
	or xhl, xhl
	jr z, GroupBoxProc_StartSSFPresentation
	ld xde, (xsp + 30)
	ld xwa, 0xffffffff
	ld xbc, EVT_SW_OFF
