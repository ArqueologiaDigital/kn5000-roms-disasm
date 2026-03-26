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
	ld xbc, 0x1e0008c
	jr ParaLoadOptSendEvtReturn

ParaLoadOpt_BuildFromIZ1:
	.incbin "includes/generated/v7_transplant_ParaLoadOpt_BuildFromIZ1.bin"
ParaLoadOpt_BuildFromIZ2:
	.incbin "includes/generated/v7_transplant_ParaLoadOpt_BuildFromIZ2.bin"
ParaLoadOpt_BuildFromIZ3:
	.incbin "includes/generated/v7_transplant_ParaLoadOpt_BuildFromIZ3.bin"
ParaLoadOptSendEvtReturn:
	call SendEvent

ParaLoadOpt_ReturnZero:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 62)
	ret

ParaLoadOptOKFunc:
	cp xbc, 0x1c00007
	jr nz, ParaLoadOptOK_ReturnZero
	ld xwa, 0x1430003
	ld xbc, 0x1e30005
	call MainFuncCall

ParaLoadOptOK_ReturnZero:
	lds32 xhl, 0
	ret

MainFlashFunc:
	.incbin "includes/generated/v7_transplant_MainFlashFunc.bin"
MainFlash_AudioDispatch:
	lds wa, 7
	call Audio_DispatchCommand

MainFlash_ReturnZero:
	lds32 xhl, 0
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
	cp xwa, 0x1c00007
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
	ld xbc, 0x1e00053
	ld xde, (xsp + 8)
	call SendEvent
	cps hl, 0
	jr z, AcTtlJgBox_CallInherited
	ld xde, xiz
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, (xsp + 12)
	call MainFuncCall
	lds32 xhl, 0
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
	cp xwa, 0x1c50000
	jrl z, AcParaStrBox_HandleInit
	cp xwa, 0x1c00002
	jr z, AcParaStrBox_HandleReEnable
	cp xwa, 0x1c0000f
	jr z, AcParaStrBox_HandleTimer
	cp xwa, 0x1c0000b
	jr z, AcParaStrBox_HandleSuspend
	cp xwa, 0x1c00001
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
	lds32 xhl, 0
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
	cp xwa, 0x1c00002
	jrl z, PsWinToggle_HandleReEnable
	cp xwa, 0x1c00007
	jrl z, PsWinToggle_HandleOK
	cp xwa, 0x1c00001
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
	ld xbc, 0x1e0006b
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), hl
	ld xde, (xiz + 40)
	ld xwa, (xiz + 48)
	ld xbc, 0x1e50005
	call MainFuncCall
	ld xde, (xiz + 44)
	ld xwa, (xiz + 48)
	ld xbc, 0x1e50006
	call MainFuncCall
	ld de, (xsp + 4)
	exts xde
	ld xwa, (xiz + 48)
	ld xbc, 0x1e50007
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
	ld xbc, 0x1e00053
	ld xde, (xsp + 10)
	call SendEvent
	cps hl, 0
	jrl z, PsWinToggle_InheritedFallback
	ld xbc, (xsp + 6)
	ld xwa, (xbc + 40)
	cp xwa, 0xffffffff
	jr z, PsWinToggle_ReturnZero
	ld xwa, (xbc + 44)
	cp xwa, 0xffffffff
	jr z, PsWinToggle_ReturnZero
	ld xwa, (xsp + 18)
	ld xbc, 0x1e0006c
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), hl
	ld de, (xsp + 4)
	exts xde
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 48)
	ld xbc, 0x1e50007
	call MainFuncCall
	cpw (xsp + 4), 0x0
	jr z, PsWinToggle_HideChild40
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 44)
	ld xbc, 0x1c00002
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 40)
	ld xbc, 0x1c00001
	lds32 xde, 0
	jr PsWinToggle_SendToggleEvent

PsWinToggle_HideChild40:
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 40)
	ld xbc, 0x1c00002
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 44)
	ld xbc, 0x1c00001
	lds32 xde, 0

PsWinToggle_SendToggleEvent:
	call SendEvent

PsWinToggle_ReturnZero:
	lds32 xhl, 0
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
	ld xbc, 0x1e0006b
	lds32 xde, 0
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
	cp xiz, 0x1c50000
	jrl z, AcFileSfx_HandleInit
	cp xiz, 0x1c00002
	jrl z, AcFileSfx_HandleReEnable
	cp xiz, 0x1e50001
	jr z, AcFileSfx_HandleSfxEvent
	cp xiz, 0x1c0000b
	jr z, AcFileSfx_HandleSuspend
	cp xiz, 0x1c00001
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
	ld xbc, 0x1e50000
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
	lda_24 xhl, (DiskWarning_ConfirmStrings_0xB46)
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
	pushw 0xff
	pushw 0xf5
	jr AcFileSfx_CallDrawString

AcFileSfx_DrawDefault:
	ld xde, (xhl)
	ld xhl, (xix)
	push xhl
	pushw 0xff
	pushw 0xf5

AcFileSfx_CallDrawString:
	call DrawString
	ld wa, (xsp + 6)
	add (xsp + 14), wa
	ld xwa, (xsp + 24)
	srl xwa, 1
	ld (xsp + 24), xwa
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x9
	jr c, AcFileSfx_DrawLoop

AcFileSfx_ReturnZero:
	lds32 xhl, 0
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
	cp xwa, 0x1c00007
	jr z, IvFocus_HandleOK
	cp xwa, 0x1c0000d
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
	ld xbc, 0x1c00017
	jr IvFocus_SendEventReturn

IvFocus_SendListNotEmpty:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00018
	jr IvFocus_SendEventReturn

IvFocus_HandleOK:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, xiz
	ld xbc, 0x1e00053
	ld xde, (xsp + 8)
	call SendEvent
	cps hl, 0
	jr z, IvFocus_CallInherited
	ld xwa, xiz
	ld xbc, 0x1e0006c
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 4)
	ld de, (xwa + 40)
	cps de, 0
	jr lt, IvFocus_ReturnZero
	exts xde
	cps hl, 0
	jr z, IvFocus_SendListEmpty
	ld xwa, 0xffffffff
	ld xbc, 0x1c00017
	jr IvFocus_SendEventReturn

IvFocus_SendListEmpty:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00018

IvFocus_SendEventReturn:
	call SendEvent

IvFocus_ReturnZero:
	lds32 xhl, 0
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
	cp xiz, 0x1e5000a
	jrl z, IvTimer_HandleEvent0A
	cp xiz, 0x1e50009
	jr z, IvTimer_HandleEvent09
	cp xiz, 0x1e0003a
	jr z, IvTimer_HandleEvent3A
	cp xiz, 0x1c0000d
	jr z, IvTimer_HandleDestroy
	cp xiz, 0x1c00001
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
	ld xbc, 0x1e50008
	jr IvTimer_CallMainFunc

IvTimer_HandleDestroy:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	jr IvTimer_ReturnZero

IvTimer_HandleEvent3A:
	.incbin "includes/generated/v7_transplant_IvTimer_HandleEvent3A.bin"
IvTimer_HandleEvent09:
	ld xwa, 0x1e5000a
	push xwa
	lds32 xwa, 0
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
	lds32 xwa, 0
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
	lds32 xhl, 0

IvTimer_Cleanup:
	pop xiz
	lda xsp, (xsp + 12)
	ret

VwScreenTitleProc:
	dec 8, xsp
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000d
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
	lds de, 0
	call DrawTitleBar
	lds32 xhl, 0

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
	cps bc, 3
	jr z, DrawProgH_Mode3Setup
	cps bc, 2
	jr z, DrawProgH_Mode2Setup
	cps bc, 1
	scc16 nz, bc
	ld (xsp + 8), bc
	ldw (xsp + 10), 0x0
	ld xiy, xwa
	lda xix, (xsp + 24)
	lds bc, 4
	ldirw

DrawProgH_CalcDimensions:
	lda xhl, (xsp + 24)
	ld bc, (xhl + 4)
	ld wa, bc
	sub wa, (xhl)
	mul xwa, xde
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
	cps iz, 0
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
	incm 1, (xsp + 14)
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
	incm 1, (xsp + 14)
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
	incm 1, (xsp + 14)
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
	cps bc, 3
	jr z, DrawProgV_Mode3Setup
	cps bc, 2
	jr z, DrawProgV_Mode2Setup
	cps bc, 1
	scc16 nz, bc
	ld (xsp + 6), bc
	ldw (xsp + 8), 0x0
	ld xiy, xwa
	lda xix, (xsp + 26)
	lds bc, 4
	ldirw

DrawProgV_CalcDimensions:
	lda xhl, (xsp + 26)
	lda xix, (xhl + 4)
	ld bc, (xix)
	ld wa, bc
	sub wa, (xhl)
	mul xwa, xde
	ldw_erp WA, 0xfa
	extz xwa
	div wa, 0x64
	ldw_erp WA, 0xfa
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
	stw_erp WA, 0xfa
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
	cp xbc, 0x1c0000b
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
	lds32 xhl, 0

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
	cp xiz, 0x1c50003
	jrl z, Slider_Event1E00068
	cp xiz, 0x1c50002
	jrl z, Slider_Event1E00068
	cp xiz, 0x1c0001a
	jrl z, Slider_Event1E00069
	cp xiz, 0x1c00019
	jrl z, Slider_Event1E00069
	cp xiz, 0x1c00018
	jr z, Slider_Case1E0006B
	cp xiz, 0x1c00017
	jr z, Slider_Case1E0006B
	cp xiz, 0x1e0003a
	jr z, Slider_Case1E0006A
	cp xiz, 0x1c0000d
	jr z, Slider_Case1E00067
	cp xiz, 0x1e0003b
	jr z, Slider_Case1E00066
	cp xiz, 0x1c00001
	jrl nz, Slider_Error
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	lds wa, 0
	jrl Slider_ReturnZero

Slider_Case1E00066:
	lds wa, 0
	jrl Slider_ReturnZero

Slider_Case1E00067:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl Slider_UpdateDone

Slider_Case1E0006A:
	.incbin "includes/generated/v7_transplant_Slider_Case1E0006A.bin"
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
	cp xwa, 0x1c00017
	jr nz, Slider_Increment
	ld xwa, (xsp + 12)
	ld xbc, 0x1c00019
	ld xde, (xsp + 8)
	jr Slider_IncrDone

Slider_Increment:
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0001a
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
	ld xbc, 0x1c50003
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 12)
	ld xbc, 0x1c50002
	ld xde, (xsp + 8)
	jr Slider_DecrDone

Slider_Decrement:
	ld xwa, (xsp + 12)
	ld xbc, 0x1c50002
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 12)
	ld xbc, 0x1c50003
	ld xde, (xsp + 8)

Slider_DecrDone:
	call SetDialDown
	lds wa, 1

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
	cp xwa, 0x1c00019
	jr nz, Slider_DragIncr
	ld xwa, 0xffffffff
	ld xbc, 0x1c00017
	ld xde, (xsp + 8)
	jr Slider_UpdateDone

Slider_DragIncr:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00018
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
	cp xwa, 0x1c50002
	jr nz, Slider_SmallIncr
	ld xwa, 0xffffffff
	ld xbc, 0x1c00017
	ld xde, (xsp + 8)
	jr Slider_UpdateDone

Slider_SmallIncr:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00018
	ld xde, (xsp + 8)

Slider_UpdateDone:
	call SendEvent

Slider_NoChange:
	lds32 xhl, 0
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
	cp xwa, 0x1c50000
	jrl z, Scrollbar_Case1C00001
	cp xwa, 0x1c0000f
	jrl z, Scrollbar_Case1E5000A
	cp xwa, 0x1e5000a
	jrl z, Scrollbar_Case1E00068
	cp xwa, 0x1c0000b
	jr z, Scrollbar_Case1E00069
	cp xwa, 0x1c00002
	jr z, Scrollbar_Case1E00067
	cp xwa, 0x1c00001
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
	ld xbc, 0x1e5000a
	push xbc
	lds32 xbc, 0
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
	ld xbc, 0x1c0000b

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
	ld xbc, 0x1e5000a
	push xbc
	lds32 xbc, 0
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
	ld xbc, 0x1e5000a
	push xbc
	lds32 xbc, 0
	push xbc
	ld xbc, (xsp + 24)
	ld xde, (xsp + 24)
	call SetApTimer

Scrollbar_Done:
	lds32 xhl, 0
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
	cp xbc, 0x1c0001a
	jrl z, Bounds_Default
	cp xbc, 0x1c00019
	jrl z, Bounds_Default
	cp xbc, 0x1c00018
	jrl z, Bounds_Default
	cp xbc, 0x1c00017
	jr z, Bounds_Default
	cp xbc, 0x1e0003a
	jr z, Bounds_Case1E0006A
	cp xbc, 0x1c0000d
	jr z, Bounds_Case1E0006B
	cp xbc, 0x1c00002
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
	ld xbc, 0x1c00017
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
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	jr Bounds_Done

Bounds_Case1E0006A:
	.incbin "includes/generated/v7_transplant_Bounds_Case1E0006A.bin"
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
	ld xbc, 0x1c00017
	push xbc
	ld bc, (xde)
	exts xbc
	push xbc
	ld xbc, (xsp + 16)
	ld xde, 0xffffffff
	call KillApTimer
	ld wa, (xiz + 26)
	extz xwa
	ld xbc, 0x1c00017
	push xbc
	ld bc, (xiz + 28)
	exts xbc
	push xbc
	ld xbc, (xsp + 16)
	ld xde, 0xffffffff
	call SetApTimer

Bounds_Done:
	lds32 xhl, 0
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
	cp xbc, 0x1e50006
	jr z, Edit_Default
	cp xbc, 0x1e50005
	jr z, Edit_Case1E00068
	cp xbc, 0x1e0003a
	jr z, Edit_Case1E00069
	cp xbc, 0x1c0000d
	jr z, Edit_Case1E00067
	ld xwa, xiz
	call InheritedProc
	jr Edit_Return

Edit_Case1E00067:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jr Edit_Update

Edit_Case1E00069:
	.incbin "includes/generated/v7_transplant_Edit_Case1E00069.bin"
Edit_Case1E00068:
	ld xwa, xiz
	call GetViewInstance
	lda xbc, (xhl + 22)
	ld xwa, (xbc)
	cp xwa, 0xffffffff
	jr z, Edit_NoChange
	ld xwa, (xbc)
	ld xbc, 0x1c00001
	lds32 xde, 5
	jr Edit_Update

Edit_Default:
	ld xwa, xiz
	call GetViewInstance
	lda xbc, (xhl + 22)
	ld xwa, (xbc)
	cp xwa, 0xffffffff
	jr z, Edit_NoChange
	ld xwa, (xbc)
	ld xbc, 0x1c00002
	lds32 xde, 0

Edit_Update:
	call SendEvent

Edit_NoChange:
	lds32 xhl, 0

Edit_Return:
	pop xiz
	ret

EditControlProc:
	ld	(xwa), 0
	lds	hl, 0
	ret

; =============================================================================
; =============================================================================
	.include "storage/fdc_routines.s"

	.include "boot/main_title_ctrl_panel.s"


; =============================================================================
; GroupBoxNotify_SendSSFEvent (0xf98697)  [UNDECODED -- still in .byte form]
; =============================================================================
; Sends event 0x1c00038 to trigger GroupBoxProc_StartSSFPresentation.
;
; This function appears as a function-pointer entry in many widget handler
; chains (tables at UIState_HandlerTable_WithProbe, UIState_HandlerTable_Standard, UIState_HandlerTable_Compact, etc.).
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
	.incbin "includes/generated/v7_transplant_UIState_KeyScan_Dispatch.bin"
KeyScan_CheckEmptyMarker:
	.incbin "includes/generated/v7_transplant_KeyScan_CheckEmptyMarker.bin"
KeyScan_ScanLoop:
	.incbin "includes/generated/v7_transplant_KeyScan_ScanLoop.bin"
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
	.incbin "includes/generated/v7_transplant_CtrlPanel_HandleKeyInput.bin"
CtrlPanel_HandleKey10:
	.incbin "includes/generated/v7_transplant_CtrlPanel_HandleKey10.bin"
PartSelect_UpdateDisplayState:
	.incbin "includes/generated/v7_transplant_PartSelect_UpdateDisplayState.bin"
ApTaskControl:
	cp xbc, 0x1e000b0
	jr z, ApTaskCtrl_ReturnZero
	cp xbc, 0x1e000ad
	jr z, ApTaskCtrl_HandleAD
	cp xbc, 0x1e000ac
	jr z, ApTaskCtrl_HandleAC
	cp xbc, 0x1e000af
	jr z, ApTaskCtrl_ReturnZero
	cp xbc, 0x1e000ae
	jr nz, ApTaskCtrl_ReturnZero
	lds wa, 1
	call TaskSched_WakeBySlotID
	jr ApTaskCtrl_ResumeTask

ApTaskCtrl_HandleAC:
	ld xwa, 0x140000c
	call MainFuncCall

ApTaskCtrl_ResumeTask:
	call TaskSched_Resume
	jr ApTaskCtrl_ReturnZero

ApTaskCtrl_HandleAD:
	lds wa, 1
	call TaskSched_WakeBySlotID

ApTaskCtrl_ReturnZero:
	lds32 xhl, 0
	ret

MainTaskControl:
	cp xbc, 0x1e000b0
	jr z, MainTaskCtrl_HandleB0
	cp xbc, 0x1e000ad
	jr z, MainTaskCtrl_ReturnZero
	cp xbc, 0x1e000ac
	jr z, MainTaskCtrl_HandleAC
	cp xbc, 0x1e000af
	jr z, MainTaskCtrl_HandleAF
	cp xbc, 0x1e000ae
	jr nz, MainTaskCtrl_ReturnZero
	ld xwa, 0xffffffff
	call ApPostEvent
	jr MainTaskCtrl_ResumeTask

MainTaskCtrl_HandleAF:
	lds wa, 4
	call TaskSched_WakeBySlotID
	jr MainTaskCtrl_ReturnZero

MainTaskCtrl_HandleAC:
	lds wa, 4
	call TaskSched_WakeBySlotID

MainTaskCtrl_ResumeTask:
	call TaskSched_Resume
	jr MainTaskCtrl_ReturnZero

MainTaskCtrl_HandleB0:
	ld xwa, 0xffffffff
	call ApPostEvent

MainTaskCtrl_ReturnZero:
	lds32 xhl, 0
	ret
SleepMainTask:
	ld xwa, 0x120000b
	ld xbc, 0x1e000ac
	lds32 xde, 0
	jrl ApTaskControl

WakeUpMainTask:
	ld xwa, 0x120000b
	ld xbc, 0x1e000ad
	lds32 xde, 0
	jrl ApTaskControl

SleepApTask:
	ld xwa, 0x120000b
	ld xbc, 0x1e000ae
	lds32 xde, 0
	jr MainTaskControl

WakeUpApTask:
	ld xwa, 0x120000b
	ld xbc, 0x1e000af
	lds32 xde, 0
	jrl MainTaskControl

RefreshApTask:
	.incbin "includes/generated/v7_transplant_RefreshApTask.bin"
RefreshSwEvent:
	lds32 xwa, 0
	stl_da (0x02749a), xwa
	stl_da (0x02749e), xwa
	stl_da (0x0274a2), xwa
	ld xwa, 0xffffffff
	ld xbc, 0x1c00008
	call DeleteEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c00007
	call DeleteEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c00009
	call DeleteEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e000b4
	lds32 xde, 0
	jp ApPostEvent

KeyScan_Enable:
	stiw_da (0x03ef4e), 0x0001
	ret

KeyScan_Disable:
	stiw_da (0x03ef4e), 0x0000
	ret

MainAutoFree:
	.incbin "includes/generated/v7_transplant_MainAutoFree.bin"
MainRamControl:
	.incbin "includes/generated/v7_transplant_MainRamControl.bin"
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
	lds32 xbc, 0
	ld (xwa + 14), xbc

RamCtrl_Read_Dispatch:
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001d
	ld xde, (xsp + 12)
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, (xsp + 12)
	jrl RamCtrl_DispatchAndReturn

RamCtrl_Adjust_Entry:
	ld (xsp), xde
	ld xwa, (xde)
	ld (xsp + 4), xwa
	ld xwa, (xsp)
	ld de, (xwa + 4)
	cps de, 4
	jr z, RamCtrl_Adjust_Dword
	ld xbc, (xwa + 10)
	ld xwa, (xwa + 6)
	cps de, 2
	jr z, RamCtrl_Adjust_Word_CheckRange
	cps de, 1
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
	lds32 xwa, 0
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
	.incbin "includes/generated/v7_transplant_RamCtrl_Adjust_WriteBack.bin"
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
	lds32 xbc, 0
	ld (xwa + 14), xbc

RamCtrl_Adjust_Dispatch:
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001d
	ld xde, (xsp + 12)
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, (xsp + 12)
	jr RamCtrl_DispatchAndReturn

RamCtrl_Set_Entry:
	ld (xsp), xde
	ld xwa, (xde)
	ld (xsp + 4), xwa
	ld xwa, (xsp)
	ld bc, (xwa + 4)
	cps bc, 4
	jr z, RamCtrl_Set_Dword
	lda xde, (xwa + 14)
	cps bc, 2
	jr z, RamCtrl_Set_Word_Mask
	cps bc, 1
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
	lds32 xwa, 0
	ld (xde), xwa

RamCtrl_Set_Dispatch:
	.incbin "includes/generated/v7_transplant_RamCtrl_Set_Dispatch.bin"
RamCtrl_DispatchAndReturn:
	call ApPostEvent

RamCtrl_Return:
	lds32 xhl, 0
	lda xsp, (xsp + 16)
	ret

MainBitControl:
	.incbin "includes/generated/v7_transplant_MainBitControl.bin"
BitCtrl_ClearBit:
	ld xbc, (xbc)
	xor xbc, 0xffffffff
	ld xwa, (xsp + 4)
	and (xwa), xbc
	ldw (xde), 0x0

BitCtrl_PostBitChangeEvent:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00024
	ld xde, (xsp + 8)
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
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
	.incbin "includes/generated/v7_transplant_BitCtrl_ReadBitDone.bin"
BitCtrl_PostFinalEvent:
	call ApPostEvent

BitCtrl_Return:
	lds32 xhl, 0
	pop xiz
	inc 8, xsp
	ret


	.include "audio/sound_navigation.s"


MainPmanControl:
	dec 4, xsp
	push xiz
	ld xwa, xbc
	cp xbc, 0x1e000a0
	jrl z, MainPmanCtrl_HandleA0
	sub xwa, 0x1e00057
	cp xwa, 0x0
	jrl lt, MainTitle_SendEventDone
	cp xwa, 0x5
	jrl gt, MainTitle_SendEventDone
	add xwa, xwa
	add xwa, DiskWarning_ConfirmStrings_0xD4C
	ld wa, (xwa)
	lda_24 xix, (MainPmanCtrl_DispatchTable)
	jp_ind 8, 0x07, 0xf0, 0xe0

MainPmanCtrl_DispatchTable:
	.incbin "includes/generated/v7_transplant_MainPmanCtrl_DispatchTable.bin"
MainPmanCtrl_HandleA0:
	.incbin "includes/generated/v7_transplant_MainPmanCtrl_HandleA0.bin"
MainPmanCtrl_StorePartSelect:
	.incbin "includes/generated/v7_transplant_MainPmanCtrl_StorePartSelect.bin"
MainPmanCtrl_CheckSoundParam:
	.incbin "includes/generated/v7_transplant_MainPmanCtrl_CheckSoundParam.bin"
MainPmanCtrl_SetPartSelectOne:
	.incbin "includes/generated/v7_transplant_MainPmanCtrl_SetPartSelectOne.bin"
MainPmanCtrl_SetPartSelectZero:
	.incbin "includes/generated/v7_transplant_MainPmanCtrl_SetPartSelectZero.bin"
MainPmanCtrl_LoadPartSelect:
	.incbin "includes/generated/v7_transplant_MainPmanCtrl_LoadPartSelect.bin"
MainPmanCtrl_CompareAndUpdate:
	.incbin "includes/generated/v7_transplant_MainPmanCtrl_CompareAndUpdate.bin"
MainTitle_SendEventDone:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

MainTitleControl:
	.incbin "includes/generated/v7_transplant_MainTitleControl.bin"
SeqState_TransitionMode:
	.incbin "includes/generated/v7_transplant_SeqState_TransitionMode.bin"
MainTitleCtrl_SaveAndTransition:
	.incbin "includes/generated/v7_transplant_MainTitleCtrl_SaveAndTransition.bin"
MainTitleCtrl_SetIndicatorAndClear:
	.incbin "includes/generated/v7_transplant_MainTitleCtrl_SetIndicatorAndClear.bin"
SeqState_DemoModeHandler:
	.incbin "includes/generated/v7_transplant_SeqState_DemoModeHandler.bin"
SeqDemo_SaveCurrentState:
	.incbin "includes/generated/v7_transplant_SeqDemo_SaveCurrentState.bin"
MainTitleCtrl_HandleAB:
	stw_da (0x0274ac), xde
	stiw_da (0x0274ae), 0x000a
	jr UIWidget_ReturnZero

MainTitleCtrl_HandleBA:
	stw_da (0x0274a8), xde
	stiw_da (0x0274aa), 0x000a
	jr UIWidget_ReturnZero

MainTitleCtrl_HandleBB:
	ldw_da xwa, (0x0274aa)
	cps wa, 0
	jr z, MainTitleCtrl_CheckSecondTimer
	dec 1, wa
	stw_da (0x0274aa), xwa
	cps wa, 0
	jr nz, MainTitleCtrl_CheckSecondTimer
	ldw_da xwa, (0x0274a8)
	stw_da (0x0274a6), xwa

MainTitleCtrl_CheckSecondTimer:
	.incbin "includes/generated/v7_transplant_MainTitleCtrl_CheckSecondTimer.bin"
MainTitleCtrl_ClearIndicatorBit:
	.incbin "includes/generated/v7_transplant_MainTitleCtrl_ClearIndicatorBit.bin"
MainTitleCtrl_SetIndicator60:
	ldw wa, 0x60
	call CtrlPanel_SetIndicatorBit

UIWidget_ReturnZero:
	lds32 xhl, 0
	ret

CtrlPanel_GetSelectionState:
	ldw_da xwa, (0x0274a6)
	bit 0, wa
	jr z, CtrlPanel_CheckBit1
	lds hl, 1
	ret

CtrlPanel_CheckBit1:
	bit 1, wa
	jr z, CtrlPanel_SelectionReturnZero
	and wa, 0x18
	jr nz, CtrlPanel_SelectionReturnZero
	lds hl, 2
	ret

CtrlPanel_SelectionReturnZero:
	lds hl, 0
	ret

GetPartSelect:
	.incbin "includes/generated/v7_transplant_GetPartSelect.bin"
GetCurrentPartSelect:
	.incbin "includes/generated/v7_transplant_GetCurrentPartSelect.bin"
UI_PostPartChangeEvent:
	dec 2, xsp
	ld (xsp), a
	ld xwa, 0xffffffff
	ld xbc, 0x1c00014
	call DeleteEvent
	lds32 xde, 0
	ld e, (xsp)
	add xde, 0x1800000
	ld xwa, 0xffffffff
	ld xbc, 0x1c00014
	call ApPostEvent
	inc 2, xsp
	ret

UI_PostModeChangeEvent:
	dec 2, xsp
	ld (xsp), a
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	call DeleteEvent
	lds32 xde, 0
	ld e, (xsp)
	add xde, 0x1a00000
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
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
	ld xbc, 0x1c00016
	call DeleteEvent
	lds32 xde, 0
	ld e, (xsp)
	add xde, 0x1a00000
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	call ApPostEvent
	inc 2, xsp
	ret

UI_PostRefreshEvent:
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	jp ApPostEvent

UI_PostTimerResetEvent:
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000e
	lds32 xde, 0
	jp ApPostEvent

SeqState_HasModeChanged:
	.incbin "includes/generated/v7_transplant_SeqState_HasModeChanged.bin"
UI_PostDialEnable:
	ld e, a
	ldb d, 0x0
	extz xde
	ld xwa, 0xffffffff
	ld xbc, 0x1e0006f
	jp ApPostEvent
UI_DialRangeData:
	.byte 0xf2, 0x94, 0x74, 0x02, 0x41, 0x0e, 0xf2, 0x95
	.byte 0x74, 0x02, 0x41, 0x0e

UI_PostEvent_0x6E:
	ld e, a
	ldb d, 0x0
	extz xde
	ld xwa, 0xffffffff
	ld xbc, 0x1e0006e
	jp ApPostEvent

UI_PostDialRangeEvent:
	ld e, a
	ldb d, 0x0
	extz xde
	ld xwa, 0xffffffff
	ld xbc, 0x1e00070
	jp ApPostEvent

UI_PostDialValueEvent:
	ld e, a
	ldb d, 0x0
	extz xde
	ld xwa, 0xffffffff
	ld xbc, 0x1e00071
	jp ApPostEvent

BoxProc:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1e000b2
	jr z, BoxProc_HandleB2
	cp xbc, 0x1e000b1
	jr z, BoxProc_HandleB1
	cp xbc, 0x1c0000d
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
	lds32 xhl, 0
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
	lds bc, 4
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
	lds32 xde, 0
	ld xiy, xbc
	ld xix, xiz
	lds bc, 4
	ldirw
	cps wa, 0
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
	lda_24 xix, (DiskWarning_ConfirmStrings_0xD58)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda_24 xix, (CtrlPanel_FrameDispatchTable)
	jp_ind 8, 0x07, 0xf0, 0xe0

CtrlPanel_FrameDispatchTable:
	lds32	xde, 4
	jr	18
	lds32	xde, 3
	jr	14
	lds32	xde, 1
	decm	2, (xiz+4)
	lds	wa, 2

CtrlPanel_SubFrameOffset:
	sub (xiz + 6), wa

CtrlPanel_InvalidIndexHandler:
	or xde, xde
	jr z, CtrlPanel_MarginDone

CtrlPanel_ApplyMarginLoop:
	lds32 xiy, 0
	cp xde, 0x0
	jr le, CtrlPanel_MarginDone
	lda xix, (xiz + 2)
	lda xhl, (xiz + 6)
	ld xbc, xiz
	lda xwa, (xiz + 4)

CtrlPanel_MarginAdjustStep:
	incm 1, (xix)
	decm 1, (xhl)
	incm 1, (xbc)
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
	lds32 xde, 2
	jrl CtrlPanel_ApplyMarginLoop
	lds32 xde, 1
	decm 1, (xiz + 4)
	lds wa, 1
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
	lds32 xde, 1
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
	lds hl, 0
	ret

BoxLeftCheck:
	cp wa, 0x88
	jr gt, BoxLeftCheck_ReturnZero
	cp wa, 0x80
	jr lt, BoxLeftCheck_ReturnZero
	lds hl, 1
	ret

BoxLeftCheck_ReturnZero:
	lds hl, 0
	ret

BoxRightCheck:
	cp wa, 0xa8
	jr gt, BoxRightCheck_ReturnZero
	cp wa, 0xa0
	jr lt, BoxRightCheck_ReturnZero
	lds hl, 1
	ret

BoxRightCheck_ReturnZero:
	lds hl, 0
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
	cp xde, 0x1c00036
	jrl z, GroupBox_DisplayUpdate
	cp xde, 0x1e00079
	jrl z, GroupBox_NavUpDown
	cp xde, 0x1e00078
	jrl z, GroupBox_NavUpDown
	ld xwa, (xsp + 30)
	cp xde, 0x1e00087
	jrl z, GroupBox_SetDialFocus
	cp xde, 0x1e00088
	jrl z, GroupBox_GetDialFocus
	cp xde, 0x1e00071
	jrl z, GroupBox_DialUp
	cp xde, 0x1e00070
	jrl z, GroupBox_DialDown
	ld xbc, (xsp + 30)
	cp xde, 0x1e0006f
	jrl z, GroupBox_DialEnable
	cp xde, 0x1e0006e
	jrl z, GroupBox_CancelBack
	cp xde, 0x1c00038
	jrl z, GroupBoxProc_StartSSFPresentation
	cp xde, 0x1c00030
	jrl z, GroupBoxProc_Ev1C00030
	cp xde, 0x1c00026
	jrl z, GroupBox_HandleKeyRepeatTimer
	cp xde, 0x1c0001f
	jrl z, GroupBox_HandleCursorNav
	cp xde, 0x1c0003b
	jrl z, GroupBox_HandleStateCompare
	ld xwa, xde
	cp xwa, 0x1c00028
	jrl z, GroupBox_HandleRefresh
	cp xwa, 0x1c00016
	jrl z, GroupBox_HandleSoundCommand
	cp xwa, 0x1c00015
	jrl z, GroupBox_HandleModeChange
	cp xwa, 0x1c00014
	jr z, GroupBox_HandlePartChange
	ld xwa, (xsp + 4)
	sub xwa, 0x1c00001
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
	add xwa, DiskWarning_ConfirmStrings_0xE2E
	ld wa, (xwa)
	extz wa
	sll wa, 1
	ld xix, DiskWarning_ConfirmStrings_0xE56
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda_24 xix, (GroupBox_HandlePartChange)
	jp_ind 8, 0x07, 0xf0, 0xe0

GroupBox_HandlePartChange:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e000aa
	lds32 xde, 0
	call SendEvent
	ld (xsp + 2), hl
	cpw (xsp + 2), 0x0
	jrl nz, GroupBox_ReturnZero
	call CheckNotDrawFlag
	cps hl, 0
	scc16 z, wa
	ld (xsp + 6), wa
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0007a
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, GroupBox_PartChange_SendEvents

GroupBox_PartChange_DrawLoop:
	cpw (xsp + 6), 0x0
	jr nz, GroupBox_PartChange_SendRefresh
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call SendEvent

GroupBox_PartChange_SendRefresh:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00028
	lds32 xde, 0
	call SendEvent
	cpw (xsp + 6), 0x0
	jr nz, GroupBox_PartChange_CheckDraw
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call SendEvent

GroupBox_PartChange_CheckDraw:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0007a
	lds32 xde, 0
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
	ld xbc, 0x1c00013
	lds32 xde, 3
	call SendEvent
	call GetModeOld
	ld xwa, xhl
	ld xbc, 0x1c00013
	lds32 xde, 1
	call SendEvent
	call GetModeNow
	ld xwa, xhl
	ld xbc, 0x1c00013
	lds32 xde, 0
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1c00013
	lds32 xde, 2
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00033
	lds32 xde, 0
	call SendEvent
	ld xwa, xhl
	ld xbc, 0x1c00001
	lds32 xde, 0
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1c00013
	ld xde, 0x8
	jrl GroupBox_NavDispatch

GroupBox_HandleModeChange:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e000aa
	lds32 xde, 0
	call SendEvent
	ld (xsp + 2), hl
	cpw (xsp + 2), 0x0
	jrl nz, GroupBox_ReturnZero
	call CheckNotDrawFlag
	cps hl, 0
	scc16 z, wa
	ld (xsp + 6), wa
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0007a
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, GroupBox_ModeChange_SendEvents

GroupBox_ModeChange_DrawLoop:
	cpw (xsp + 6), 0x0
	jr nz, GroupBox_ModeChange_SendRefresh
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call SendEvent

GroupBox_ModeChange_SendRefresh:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00028
	lds32 xde, 0
	call SendEvent
	cpw (xsp + 6), 0x0
	jr nz, GroupBox_ModeChange_CheckDraw
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call SendEvent

GroupBox_ModeChange_CheckDraw:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0007a
	lds32 xde, 0
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
	ld xbc, 0x1c00013
	lds32 xde, 3
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1c00013
	lds32 xde, 2
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00033
	lds32 xde, 0
	call SendEvent
	ld xwa, xhl
	ld xbc, 0x1c00001
	lds32 xde, 0
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1c00013
	ld xde, 0x8
	jrl GroupBox_NavDispatch

GroupBox_HandleSoundCommand:
	ld xwa, (xsp + 30)
	cp xwa, 0x1a000ee
	jr nz, GroupBox_SndCmd_GetTitle
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 0
	call SendEvent

GroupBox_SndCmd_GetTitle:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e000aa
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), hl
	ld wa, (xsp + 4)
	ld (xsp + 2), wa
	call CheckNotDrawFlag
	cps hl, 0
	scc16 z, wa
	ld (xsp + 6), wa
	ld xwa, (xsp + 30)
	ld xbc, 0x1e00033
	lds32 xde, 0
	call SendEvent
	ld xwa, xhl
	ld xbc, 0x1e00024
	ld xde, 0x1600062
	call SendEvent
	or xhl, xhl
	jr z, GroupBox_SndCmd_CheckDraw
	call GetTitleNow
	cp xhl, 0x1a000ee
	jr z, GroupBox_SndCmd_CheckDraw
	call GetTitleNow
	cp xhl, 0x1a000ef
	jrl nz, GroupBox_SndCmd_CheckTitleWidget

GroupBox_SndCmd_CheckDraw:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0007a
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, GroupBox_TitleCheck

GroupBox_SndCmd_DrawLoop:
	cpw (xsp + 6), 0x0
	jr nz, GroupBox_SndCmd_SendRefresh
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call SendEvent

GroupBox_SndCmd_SendRefresh:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00028
	lds32 xde, 0
	call SendEvent
	cpw (xsp + 6), 0x0
	jr nz, GroupBox_SndCmd_ClearStatus
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call SendEvent

GroupBox_SndCmd_ClearStatus:
	ldw (xsp + 2), 0x0
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0007a
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr nz, GroupBox_SndCmd_DrawLoop

GroupBox_TitleCheck:
	cpw (xsp + 2), 0x0
	jrl nz, GroupBox_ReturnZero

GroupBox_SndCmd_ProcessTitle:
	ld xwa, (xsp + 30)
	ld xbc, 0x1e00033
	lds32 xde, 0
	call SendEvent
	ld xwa, xhl
	ld xbc, 0x1e000b5
	ld xde, 0x1e000b6
	call SendEvent
	or xhl, xhl
	jrl nz, GroupBox_SndCmd_PostRefreshEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00098
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 30)
	ld xde, xwa
	ld xbc, (xsp + 34)
	call SendEvent
	call GetTitleOld
	ld xwa, xhl
	ld xbc, 0x1c00013
	lds32 xde, 4
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1c00013
	lds32 xde, 2
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1c00013
	lds32 xde, 6
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00076
	lds32 xde, 0
	call SendEvent
	ld xwa, xhl
	ld xbc, 0x1c00001
	lds32 xde, 3
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1c00013
	ld xde, 0x8
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00099
	lds32 xde, 0
	call SendEvent
	cpw (xsp + 4), 0x0
	jrl z, GroupBox_ReturnZero
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00033
	lds32 xde, 0
	call SendEvent
	ld xwa, xhl
	ld xbc, 0x1e00024
	ld xde, 0x1600062
	call SendEvent
	or xhl, xhl
	jrl z, GroupBox_ReturnZero
	ld de, (xsp + 4)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	jrl GroupBox_NavDispatch

GroupBox_SndCmd_CheckTitleWidget:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0007a
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jrl z, GroupBox_TitleCheck
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00076
	lds32 xde, 0
	call SendEvent
	ld xwa, xhl
	ld xbc, 0x1e00024
	ld xde, 0x1600062
	call SendEvent
	or xhl, xhl
	jrl z, GroupBox_TitleCheck
	cpw (xsp + 6), 0x0
	jr nz, GroupBox_SndCmd_RefreshAfterDraw
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call SendEvent

GroupBox_SndCmd_RefreshAfterDraw:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00028
	lds32 xde, 0
	call SendEvent
	cpw (xsp + 6), 0x0
	jrl nz, GroupBox_SndCmd_ProcessTitle
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call SendEvent
	jrl GroupBox_SndCmd_ProcessTitle

GroupBox_SndCmd_PostRefreshEvent:
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	jrl GroupBox_NavDispatch

GroupBox_HandleRefresh:
	call GetTitleNow
	ld xwa, xhl
	ld xde, (xsp + 30)
	ld xbc, (xsp + 34)
	call SendEvent
	call GetTitleOld
	ld xwa, xhl
	ld xbc, 0x1c00013
	lds32 xde, 7
	call SendEvent
	call GetTitleOld
	ld xwa, xhl
	ld xbc, 0x1c00013
	lds32 xde, 3
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1c00013
	lds32 xde, 5
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00076
	lds32 xde, 0
	call SendEvent
	ld xwa, xhl
	ld xbc, 0x1c00001
	lds32 xde, 4
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1c00013
	ld xde, 0x8
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00099
	lds32 xde, 0
	jrl GroupBox_NavDispatch

GroupBox_HandleStateCompare:
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 0
	call SendEvent
	call GetModeNow
	ldiw_erp 0xee, 0
	extz xhl
	sll xhl, 2
	lda_24 xwa, (DiskWarning_ConfirmStrings_0xDAE)
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
	ld xbc, 0x1c00014
	jrl GroupBox_NavDispatch

GroupBox_StateCompare_Default:
	ld xwa, (xsp + 38)
	ld xbc, 0x1c00014
	ld xde, 0x1800001
	jrl GroupBox_NavDispatch
	ld xwa, (xsp + 38)
	call SetCurrentTarget
	stiw_da (0x03ef50), 0x0000
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, (xsp + 34)
	calr BoxProc
	call GetCurrentTarget
	cp xhl, (xsp + 38)
	jrl nz, GroupBox_ReturnZero
	call CheckNotDrawFlag
	cps hl, 0
	jrl z, GroupBox_ReturnZero
	ld xwa, (xsp + 30)
	cp xwa, 0x5
	jr z, GroupBox_Nav_SendSuspend
	ld xwa, (xsp + 38)
	ld xbc, 0x1c0000a
	lds32 xde, 0
	jr GroupBox_Nav_SendEventAndUpdate

GroupBox_Nav_SendSuspend:
	ld xwa, (xsp + 38)
	ld xbc, 0x1c0000b
	lds32 xde, 0

GroupBox_Nav_SendEventAndUpdate:
	call SendEvent
	lds wa, 1
	call SetNeedUpdate
	call UpdateScreen
	lds wa, 0
	jrl GroupBox_DisableDisplay
	lds wa, 0
	calr SetDialEnable
	ld xwa, 0xffffffff
	stl_da (0x03ef6a), xwa
	lda_24 xde, (0x0274e8)
	lda xbc, (xde + 15)
	ld xwa, xbc
	inc 1, xde
	stb_dri A, 0xe5, 0xc0, 0x01

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
	ld xbc, 0x1c0000b
	lds32 xde, 0
	jrl GroupBox_NavDispatch

GroupBox_HandleCursorNav:
	cpw_da (0x3ef50), 0
	jr z, GroupBox_CursorNav_AddLsw
	cp xwa, 0x0
	jr ge, GroupBox_CursorNav_LoadPositive
	ldl_da xwa, (0x03ef56)
	ldl_da xbc, (0x03ef5e)
	ldl_da xde, (0x03ef66)
	jr GroupBox_CursorNav_SendAndTitle

GroupBox_CursorNav_LoadPositive:
	ldl_da xwa, (0x03ef52)
	ldl_da xbc, (0x03ef5a)
	ldl_da xde, (0x03ef62)

GroupBox_CursorNav_SendAndTitle:
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00078
	lds32 xde, 0
	call SendEvent
	jr GroupBox_CursorNav_UpdateScreen

GroupBox_CursorNav_AddLsw:
	lds32 xwa, 4
	lds de, 4
	calr MainLswAdd

GroupBox_CursorNav_UpdateScreen:
	lds wa, 1
	call SetNeedUpdate
	call UpdateScreen
	lds wa, 0
	jrl GroupBox_DisableDisplay
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, (xsp + 34)
	calr BoxProc
	ld xwa, (xsp + 38)
	ld xbc, 0x1e00024
	ld xde, 0x1600029
	call SendEvent
	or xhl, xhl
	jr z, GroupBox_KeyPress_CheckRange
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, 0x1c00032
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
	ld xwa, 0x1c00026
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
	ld xbc, 0x1e00024
	ld xde, 0x1600029
	call SendEvent
	or xhl, xhl
	jr z, GroupBox_KeyRelease_CheckRange
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, 0x1c00033
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
	stib_dsp 0xe0, 0x00
	cp (xwa), 0x0
	jrl z, GroupBox_ReturnZero
	ld (xwa), 0x0
	ld xwa, 0x1c00026
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
	ld xbc, 0x1e00024
	ld xde, 0x1600029
	call SendEvent
	or xhl, xhl
	jr z, GroupBox_KeyHold_CheckRange
	ld xde, (xsp + 30)
	ld xwa, (xsp + 38)
	ld xbc, 0x1c0002b
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
	ld xbc, 0x1e0007a
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jrl nz, GroupBox_ReturnZero
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0009a
	lds32 xde, 0
	jrl GroupBox_NavDispatch

GroupBox_TimerRepeat_SendNav:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00078
	lds32 xde, 0
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
	lda_24 xwa, (0x0274e9)
	add xwa, xde
	cp (xwa), 0x0
	jrl z, GroupBox_ReturnZero
	ld xwa, 0x1c00026
	push xwa
	ld xwa, (xsp + 34)
	push xwa
	lds32 xwa, 3
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
	ld xbc, 0x1e00078
	lds32 xde, 0
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
	ld xbc, 0x1e00024
	ld xde, 0x1600029
	call SendEvent
	or xhl, xhl
	jr z, GroupBoxProc_StartSSFPresentation
	ld xde, (xsp + 30)
	ld xwa, 0xffffffff
	ld xbc, 0x1c00009
