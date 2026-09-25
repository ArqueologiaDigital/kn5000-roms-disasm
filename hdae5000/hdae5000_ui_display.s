HDAE5000_RequestMode:	; 0x28AC1F (73 bytes)
	; A = mode number: cancel a queued (0xFFFFFFFF, 0x01C00014) event
	; (RootFn_DeleteEvent) and post it anew with param 0x01800000 + A
	; (RootFn_ApPostEvent).  0x0180nnnn are mode ids: the main CPU's GetModeNow
	; returns them, and its boot posts (0xFFFFFFFF, 0x01C00014, 0x01800001).
	; Caller: HDAE5000_LoadSongWithUi, mode 1 when JUMP AFTER LOAD is on.
	dec 2, xsp			; allocate local space
	ld (xsp), a		; save the mode number
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2) — workspace ptr
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_DeleteEvent)
	ld xwa, 0xFFFFFFFF		; object 0xFFFFFFFF
	ld xbc, 0x01C00014		; event 0x01C00014
	call (xhl)		; RootFn_DeleteEvent
	ld xwa, 0:i3			; clear XWA
	ld a, (xsp)
	add xwa, 0x01800000		; 0x01800000 + mode
	ld xde, xwa		; XDE = mode id
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2) — workspace ptr
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_ApPostEvent)
	ld xwa, 0xFFFFFFFF		; object 0xFFFFFFFF
	ld xbc, 0x01C00014		; event 0x01C00014
	call (xhl)		; RootFn_ApPostEvent
	inc 2, xsp			; deallocate local space
	ret

HDAE5000_RequestTitle15:	; 0x28AC68 (73 bytes)
	; A = title number: cancel a queued (0xFFFFFFFF, 0x01C00015) event and post
	; it anew with param 0x01A00000 + A.  0x01A0nnnn are title ids: the main
	; CPU's GetTitleNow returns them, and title 0x7F is the one this ROM
	; registers as "TT_HDDEXT" (RootFn_RegisterTitle in
	; HDAE5000_Handler_Registration).  Caller: the frame handler, with 0x7F,
	; when the HD title is not the current one.  The routine after it posts
	; event 0x01C00016 instead.
	dec 2, xsp			; allocate local space
	ld (xsp), a		; save the title number
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2) — workspace ptr
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_DeleteEvent)
	ld xwa, 0xFFFFFFFF		; object 0xFFFFFFFF
	ld xbc, 0x01C00015		; event number (0x01C00015 / 0x01C00016)
	call (xhl)		; RootFn_DeleteEvent
	ld xwa, 0:i3			; clear XWA
	ld a, (xsp)
	add xwa, 0x01A00000		; 0x01A00000 + title
	ld xde, xwa		; XDE = title id
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2) — workspace ptr
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_ApPostEvent)
	ld xwa, 0xFFFFFFFF		; object 0xFFFFFFFF
	ld xbc, 0x01C00015		; event number (0x01C00015 / 0x01C00016)
	call (xhl)		; RootFn_ApPostEvent
	inc 2, xsp			; deallocate local space
	ret

HDAE5000_RequestTitle16:
	; As HDAE5000_RequestTitle15 with event 0x01C00016.  No caller was found
	; (scripts/analysis/hdae5000_reachability.py).
	dec 2, xsp			; allocate local space
	ld (xsp), a		; save the title number
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2) — workspace ptr
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_DeleteEvent)
	ld xwa, 0xFFFFFFFF		; object 0xFFFFFFFF
	ld xbc, 0x01C00016		; event number (0x01C00015 / 0x01C00016)
	call (xhl)		; RootFn_DeleteEvent
	ld xwa, 0:i3			; clear XWA
	ld a, (xsp)
	add xwa, 0x01A00000		; 0x01A00000 + title
	ld xde, xwa		; XDE = title id
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2) — workspace ptr
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_ApPostEvent)
	ld xwa, 0xFFFFFFFF		; object 0xFFFFFFFF
	ld xbc, 0x01C00016		; event number (0x01C00015 / 0x01C00016)
	call (xhl)		; RootFn_ApPostEvent
	inc 2, xsp			; deallocate local space
	ret

HDAE5000_ShowErrorMessageTitle:	; 0x28ACFA (78 bytes)
	; WA = error code: HamaFn_SetGlobalError(WA) (the main CPU stores it in
	; byte 0x7F42), then cancel a queued (0xFFFFFFFF, 0x01C00016) event and post
	; it anew with title id 0x01A000EE -- title 0xEE, registered by the main
	; CPU as "TT_MESAGE" (RegTitle 0x1, ..., 0xee in drawbar_panel_ui.s).
	; Caller: HDAE5000_FdList_Scan, code 2 when the floppy is not ready.
	extz wa
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24); ld XBC, (0x23A1A2) — workspace ptr
	ld xbc, (xbc + WS_HamaFnTable)             ; ld XBC, (XBC + 0x0E88)
	ld xhl, (xbc + HamaFn_SetGlobalError)             ; ld XHL, (XBC + 0x012C) — shutdown handler
	call (xhl)		; HamaFn_SetGlobalError(WA)
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2) — workspace ptr
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_DeleteEvent)
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x01C00016		; event 0x01C00016
	call (xhl)		; RootFn_DeleteEvent
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2) — workspace ptr
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_ApPostEvent)             ; ld XHL, (XWA + 0x0124)
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x01C00016
	ld xde, 0x01A000EE		; title 0xEE (TT_MESAGE)
	jp (xhl)		; tail-call RootFn_ApPostEvent

HDAE5000_DirName_StoreWithUi:	; 0x28AD48 (248 bytes)
	; XBC = new directory name (16 bytes), WA = directory number, XDE = the object that
	; asked (a naming window).  Shows HD_PLEASE (SendEvent(obj, 0x01C00001, 3)),
	; waits (HDAE5000_YieldUntilSem1Zero), then HDAE5000_DirName_SetAndStore(WA, name, 0).
	; Success: PostEvent(XDE, 0x01C00001, 0).  Failure (HL = 0xFFFF): show
	; ERR_SAVE, caption ERR_SAVE_EXIT on XDE, and restart its timer
	; (RootFn_KillApTimer / RootFn_SetApTimer 0x14D, ERR_SAVE_CATCH, event
	; 0x01CA0002).  Either way the name is added to the directory name history
	; at 0x22ABF2 (HDAE5000_NameHistory_Push).
	lda xsp, (xsp - 22)		; allocate 22 bytes on stack
	pushw iz
	ld (xsp + 20), xde		; save the requesting object
	ld iz, wa		; IZ = directory number
	pushw 0x0010		; 16 bytes
	push xbc		; the new name
	lda xwa, (xsp + 8)		; local copy
	push xwa
	call HDAE5000_StrNCpy
	lda xsp, (xsp + 10)		; pop 3 args (10 bytes)
	ld (xsp + 18), 0x00		; NUL after the 16 chars
	; --- show HD_PLEASE, wait ---
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2) — workspace ptr
	ld xwa, (xwa + WS_RootFnTable)             ; ld XWA, (XWA + 0x0E0A)
	ld_sril xhl, (xwa + RootFn_SendEvent)             ; ld XHL, (XWA + 0x0100)
	ld xwa, HDAE5000_OBJ_HD_PLEASE		; object HD_PLEASE
	ld xbc, 0x01C00001		; param
	ld xde, 3:i3		; param 3
	call (xhl)
	calr HDAE5000_YieldUntilSem1Zero
	; --- store the name ---
	lda xwa, (xsp + 2)
	ld xbc, xwa			; XBC = buffer
	ld wa, iz		; WA = directory number
	ld de, 0:i3			; DE = 0
	call HDAE5000_DirName_SetAndStore
	cp hl, 0xFFFF		; 0xFFFF = failed
	jr z, .Lmh_alt
	; --- success: PostEvent(requester, 0x01C00001, 0) ---
	ld xwa, (xsp + 20)		; the requester
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24); ld XBC, (0x23A1A2)
	ld xbc, (xbc + WS_RootFnTable)             ; ld XBC, (XBC + 0x0E0A)
	ld xhl, (xbc + RootFn_PostEvent)             ; ld XHL, (XBC + 0x0104)
	ld xbc, 0x01C00001		; param
	ld xde, 0:i3			; mode = 0
	call (xhl)
	jr t, .Lmh_finish
.Lmh_alt:
	; --- failure: ERR_SAVE, caption ERR_SAVE_EXIT ---
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld_sril xhl, (xwa + RootFn_SendEvent)             ; ld XHL, (XWA + 0x0100)
	ld xwa, HDAE5000_OBJ_ERR_SAVE		; object ERR_SAVE
	ld xbc, 0x01C00001
	ld xde, 0:i3
	call (xhl)
	ld xbc, (xsp + 20)		; XBC = the requester
	ld xwa, HDAE5000_OBJ_ERR_SAVE_EXIT
	calr HDAE5000_UiObj_SetCaption
	; --- restart the ERR_SAVE_CATCH timer: KillApTimer, SetApTimer ---
	ld xwa, 0x01CA0002		; event 0x01CA0002
	push xwa
	ld xwa, (xsp + 24)		; the requester
	push xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_KillApTimer)             ; ld XHL, (XWA + 0x0418)
	ld xwa, 0x0000014D		; 0x14D
	ld xbc, HDAE5000_OBJ_ERR_SAVE_CATCH
	ld xde, 0xFFFFFFFF		; param
	call (xhl)
	ld xwa, 0x01CA0002		; event 0x01CA0002
	push xwa
	ld xwa, (xsp + 24)		; the requester
	push xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_SetApTimer)             ; ld XHL, (XWA + 0x0410)
	ld xwa, 0x0000014D
	ld xbc, HDAE5000_OBJ_ERR_SAVE_CATCH
	ld xde, 0xFFFFFFFF
	call (xhl)
.Lmh_finish:
	lda xwa, (0x22abf2:24); lda XWA, 0x22ABF2
	lda xbc, (xsp + 2)		; XBC = stack buffer
	calr HDAE5000_NameHistory_Push
	popw iz
	lda xsp, (xsp + 22)		; deallocate stack
	ret

HDAE5000_FlsName_StoreWithUi:	; 0x28AE40 (248 bytes)
	; XBC = new FLS name (16 bytes), WA = FLS number, XDE = the object that
	; asked (a naming window).  Shows HD_PLEASE (SendEvent(obj, 0x01C00001, 3)),
	; waits (HDAE5000_YieldUntilSem1Zero), then HDAE5000_FlsName_SetAndStore(WA, name, 0).
	; Success: PostEvent(XDE, 0x01C00001, 0).  Failure (HL = 0xFFFF): show
	; ERR_SAVE, caption ERR_SAVE_EXIT on XDE, and restart its timer
	; (RootFn_KillApTimer / RootFn_SetApTimer 0x14D, ERR_SAVE_CATCH, event
	; 0x01CA0002).  Either way the name is added to the FLS name history
	; at 0x22AD0A (HDAE5000_NameHistory_Push).
	lda xsp, (xsp - 22)		; allocate 22 bytes on stack
	pushw iz
	ld (xsp + 20), xde		; save the requesting object
	ld iz, wa		; IZ = FLS number
	pushw 0x0010		; 16 bytes
	push xbc		; the new name
	lda xwa, (xsp + 8)		; local copy
	push xwa
	call HDAE5000_StrNCpy
	lda xsp, (xsp + 10)		; pop 3 args
	ld (xsp + 18), 0x00		; NUL after the 16 chars
	; --- show HD_PLEASE, wait ---
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2)
	ld xwa, (xwa + WS_RootFnTable)             ; ld XWA, (XWA + 0x0E0A)
	ld_sril xhl, (xwa + RootFn_SendEvent)             ; ld XHL, (XWA + 0x0100)
	ld xwa, HDAE5000_OBJ_HD_PLEASE
	ld xbc, 0x01C00001
	ld xde, 3:i3
	call (xhl)
	calr HDAE5000_YieldUntilSem1Zero
	; --- store the name ---
	lda xwa, (xsp + 2)
	ld xbc, xwa
	ld wa, iz
	ld de, 0:i3
	call HDAE5000_FlsName_SetAndStore
	cp hl, 0xFFFF
	jr z, .Lmc_alt
	; --- success: PostEvent(requester, 0x01C00001, 0) ---
	ld xwa, (xsp + 20)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_RootFnTable)
	ld xhl, (xbc + RootFn_PostEvent)             ; ld XHL, (XBC + 0x0104)
	ld xbc, 0x01C00001
	ld xde, 0:i3
	call (xhl)
	jr t, .Lmc_finish
.Lmc_alt:
	; --- failure: ERR_SAVE, caption ERR_SAVE_EXIT ---
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld_sril xhl, (xwa + RootFn_SendEvent)
	ld xwa, HDAE5000_OBJ_ERR_SAVE
	ld xbc, 0x01C00001
	ld xde, 0:i3
	call (xhl)
	ld xbc, (xsp + 20)
	ld xwa, HDAE5000_OBJ_ERR_SAVE_EXIT
	calr HDAE5000_UiObj_SetCaption
	; --- restart the ERR_SAVE_CATCH timer: KillApTimer, SetApTimer ---
	ld xwa, 0x01CA0002
	push xwa
	ld xwa, (xsp + 24)
	push xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_KillApTimer)             ; ld XHL, (XWA + 0x0418)
	ld xwa, 0x0000014D
	ld xbc, HDAE5000_OBJ_ERR_SAVE_CATCH
	ld xde, 0xFFFFFFFF
	call (xhl)
	ld xwa, 0x01CA0002
	push xwa
	ld xwa, (xsp + 24)
	push xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_SetApTimer)             ; ld XHL, (XWA + 0x0410)
	ld xwa, 0x0000014D
	ld xbc, HDAE5000_OBJ_ERR_SAVE_CATCH
	ld xde, 0xFFFFFFFF
	call (xhl)
.Lmc_finish:
	lda xwa, (0x22ad0a:24); lda XWA, 0x22AD0A
	lda xbc, (xsp + 2)
	calr HDAE5000_NameHistory_Push
	popw iz
	lda xsp, (xsp + 22)
	ret

HDAE5000_LoadSongWithUi:	; 0x28AF38 (441 bytes)
	; Manage display state; accesses 0x229DAB
	; ^ corrected: load a song with its screen messages -- shows object
	;   0x7F02C1 ("HD_PLEASE" in HDAE5000_UiObjectName_PtrTable), runs
	;   HDAE5000_LoadSong (WA = directory, BC = song, DE = part mask), and on
	;   failure shows "ERR_LOAD" (0x29D) and arms "ERR_LOAD_EXIT"/"ERR_LOAD_CATCH"
	;   (0x29E/0x29F) with event 0x01CA0002.  Callers: FileLoadSwCatch,
	;   LBNLoadSwCatch, FlsLoadScreen (x2) and the routine at 0x286E50.
	; --- Prologue ---
	dec 0, xsp				; ef 68 — allocate 4 bytes
	pushw iz                                ; push iz (compact 16-bit)
	ld (xsp + 0x04), de			; bf 04 52
	ld (xsp + 0x06), bc			; bf 06 51
	ld (xsp + 0x08), wa			; bf 08 50
	ld iz, (xsp + 0x12)			; 9f 12 26 — load mode arg
	cp iz, 1:i3				; de d9

	; --- Branch on mode ---
	jr nz, .Ldm_mode2			; 6e xx

	; Mode 1: register event via +0x0100 vtable
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld_sril xhl, (xwa + RootFn_SendEvent)             ; e3 e1 00 01 23 — ld xhl, (xwa+0x0100)
	ld xwa, HDAE5000_OBJ_HD_PLEASE			; 40 c1 02 7f 00
	ld xbc, 0x01c00001			; 41 01 00 c0 01
	ld xde, 5:i3				; ea ad
	call (xhl)				; b3 e8
	calr HDAE5000_YieldUntilSem1Zero	; 1e xx xx
	jr t, .Ldm_common			; 68 xx

.Ldm_mode2:					; 0x28AF6D
	; Mode 2: register event via +0x0124 vtable, then call +0x0E88/+0x00E4
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld xhl, (xwa + RootFn_ApPostEvent)             ; e3 e1 24 01 23 — ld xhl, (xwa+0x0124)
	ld xwa, HDAE5000_OBJ_HD_PLEASE			; 40 c1 02 7f 00
	ld xbc, 0x01c00001			; 41 01 00 c0 01
	ld xde, 5:i3				; ea ad
	call (xhl)				; b3 e8
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_HamaFnTable)             ; e3 e1 88 0e 20 — ld xwa, (xwa+0x0e88)
	ld_sril xhl, (xwa + HamaFn_pdly_tim_X)             ; e3 e1 e4 00 23 — ld xhl, (xwa+0x00e4)
	ldw wa, 0x0064				; 30 64 00
	call (xhl)				; b3 e8
	calr HDAE5000_YieldUntilSem1Zero	; 1e xx xx

.Ldm_common:					; 0x28AFA1
	; Common: dispatch via saved args
	pushw iz                                ; push iz (compact 16-bit)
	pushw 0x0000
	ld wa, (xsp + 0x0c)			; 9f 0c 20
	ld bc, (xsp + 0x0a)			; 9f 0a 21
	ld de, (xsp + 0x08)			; 9f 08 22
	call HDAE5000_LoadSong				; 1d e9 05 29
	ld (xsp + 0x02), hl			; bf 02 53 — save result
	ld wa, (xsp + 0x02)			; 9f 02 20
	cp wa, 0xffff				; d8 cf ff ff
	jrl z, .Ldm_fail			; 76 xx xx — WA == -1 → failure

	; --- Success path ---
	cp (HDAE5000_RAM_JumpAfterLoad:24), 0x01; c2 ab 9d 22 3f 01
	jr nz, .Ldm_success_check		; 6e xx
	ld wa, 1:i3				; d8 a9
	calr HDAE5000_RequestMode		; 1e xx xx
	jrl t, .Ldm_done			; 78 xx xx

.Ldm_success_check:				; 0x28AFCF
	cp iz, 1:i3				; de d9
	jr nz, .Ldm_mode2_dereg		; 6e xx

	; Mode 1 deregistration: via +0x0104 vtable
	ld xwa, (xsp + 0x0e)			; af 0e 20
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 21
	ld xbc, (xbc + WS_RootFnTable)             ; e3 e5 0a 0e 21 — ld xbc, (xbc+0x0e0a)
	ld xhl, (xbc + RootFn_PostEvent)             ; e3 e5 04 01 23 — ld xhl, (xbc+0x0104)
	ld xbc, 0x01c00001			; 41 01 00 c0 01
	ld xde, 0:i3				; ea a8
	call (xhl)				; b3 e8
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld xhl, (xwa + RootFn_PostEvent)             ; e3 e1 04 01 23 — ld xhl, (xwa+0x0104)
	ld xwa, 0xffffffff			; 40 ff ff ff ff
	ld xbc, 0x01c00018			; 41 18 00 c0 01
	ld xde, 0:i3				; ea a8
	call (xhl)				; b3 e8
	jrl t, .Ldm_done			; 78 xx xx

.Ldm_mode2_dereg:				; 0x28B00E
	; Mode 2 deregistration: via +0x0124 vtable
	ld xwa, (xsp + 0x0e)			; af 0e 20
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 21
	ld xbc, (xbc + WS_RootFnTable)             ; e3 e5 0a 0e 21 — ld xbc, (xbc+0x0e0a)
	ld xhl, (xbc + RootFn_ApPostEvent)             ; e3 e5 24 01 23 — ld xhl, (xbc+0x0124)
	ld xbc, 0x01c00001			; 41 01 00 c0 01
	ld xde, 0:i3				; ea a8
	call (xhl)				; b3 e8
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld xhl, (xwa + RootFn_ApPostEvent)             ; e3 e1 24 01 23 — ld xhl, (xwa+0x0124)
	ld xwa, 0xffffffff			; 40 ff ff ff ff
	ld xbc, 0x01c00018			; 41 18 00 c0 01
	ld xde, 0:i3				; ea a8
	call (xhl)				; b3 e8
	jrl t, .Ldm_done			; 78 xx xx

.Ldm_fail:					; 0x28B049
	; Failure path: register error event
	cp iz, 1:i3				; de d9
	jr nz, .Ldm_fail_mode2			; 6e xx

	; Fail mode 1: via +0x0100 vtable
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld_sril xhl, (xwa + RootFn_SendEvent)             ; e3 e1 00 01 23 — ld xhl, (xwa+0x0100)
	ld xwa, HDAE5000_OBJ_ERR_LOAD			; 40 9d 02 7f 00
	ld xbc, 0x01c00001			; 41 01 00 c0 01
	ld xde, 0:i3				; ea a8
	call (xhl)				; b3 e8
	jr t, .Ldm_fail_common			; 68 xx

.Ldm_fail_mode2:				; 0x28B06C
	; Fail mode 2: via +0x0124 vtable
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld xhl, (xwa + RootFn_ApPostEvent)             ; e3 e1 24 01 23 — ld xhl, (xwa+0x0124)
	ld xwa, HDAE5000_OBJ_ERR_LOAD			; 40 9d 02 7f 00
	ld xbc, 0x01c00001			; 41 01 00 c0 01
	ld xde, 0:i3				; ea a8
	call (xhl)				; b3 e8

.Ldm_fail_common:				; 0x28B089
	; Register error display handlers
	ld xbc, (xsp + 0x0e)			; af 0e 21
	ld xwa, HDAE5000_OBJ_ERR_LOAD_EXIT			; 40 9e 02 7f 00
	calr HDAE5000_UiObj_SetCaption		; 1e xx xx
	; Register via +0x0418 vtable (timer handler)
	ld xwa, 0x01ca0002			; 40 02 00 ca 01
	push xwa				; 38
	ld xwa, (xsp + 0x12)			; af 12 20
	push xwa				; 38
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld xhl, (xwa + RootFn_KillApTimer)             ; e3 e1 18 04 23 — ld xhl, (xwa+0x0418)
	ld xwa, 0x0000014d			; 40 4d 01 00 00
	ld xbc, HDAE5000_OBJ_ERR_LOAD_CATCH			; 41 9f 02 7f 00
	ld xde, 0xffffffff			; 42 ff ff ff ff
	call (xhl)				; b3 e8
	; Register via +0x0410 vtable (second timer handler)
	ld xwa, 0x01ca0002			; 40 02 00 ca 01
	push xwa				; 38
	ld xwa, (xsp + 0x12)			; af 12 20
	push xwa				; 38
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld xhl, (xwa + RootFn_SetApTimer)             ; e3 e1 10 04 23 — ld xhl, (xwa+0x0410)
	ld xwa, 0x0000014d			; 40 4d 01 00 00
	ld xbc, HDAE5000_OBJ_ERR_LOAD_CATCH			; 41 9f 02 7f 00
	ld xde, 0xffffffff			; 42 ff ff ff ff
	call (xhl)				; b3 e8

.Ldm_done:					; 0x28B0E8
	; --- Epilogue ---
	ld hl, (xsp + 0x02)			; 9f 02 23
	popw iz                                 ; pop iz (compact 16-bit)
	inc 0, xsp				; ef 60
	retd 0x0006				; 0f 06 00

HDAE5000_SaveSongWithUi:	; 0x28B0F1 (271 bytes)
	; Handle display scroll: register handler, copy data, dispatch callback
	; ^ corrected: the save counterpart of HDAE5000_LoadSongWithUi around
	;   HDAE5000_SaveSong.  Callers: HDDNamingCheck, SaveOptSwEventCatch
	;   (part mask = the save-option word 0x22AA4C), WrConfirmEventCatch.
	; Input: WA = index, BC = param, DE = context ptr
	lda xsp, (xsp - 34)		; allocate 34 bytes on stack (0xDE = -34)
	pushw iz
	ld iz, de			; IZ = context ptr
	ld (xsp + 32), bc		; save BC param at offset 0x20
	ld (xsp + 34), wa		; save WA index at offset 0x22
	; --- Register handler via workspace ---
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2)
	ld xwa, (xwa + WS_RootFnTable)             ; ld XWA, (XWA + 0x0E0A)
	ld_sril xhl, (xwa + RootFn_SendEvent)             ; ld XHL, (XWA + 0x0100)
	ld xwa, HDAE5000_OBJ_HD_PLEASE
	ld xbc, 0x01C00001
	ld xde, 0:i3
	call (xhl)
	; --- Copy data to stack buffer ---
	pushw 0x001A			; param: size 26
	ld xwa, (xsp + 48)		; reload source (+2 for pushw) = XSP+0x30
	push xwa
	lda xwa, (xsp + 10)		; destination (stack buffer at +0x0A)
	push xwa
	call HDAE5000_StrNCpy
	lda xsp, (xsp + 10)		; pop 3 args
	ld (xsp + 30), 0x00		; clear status byte at offset 0x1E
	; --- Prepare and call 0x291140 ---
	lda xwa, (xsp + 4)		; XWA = buffer ptr at stack+4
	ld xde, xwa			; XDE = buffer
	pushw iz			; push context ptr
	pushm (xsp + 46)		; push word from (XSP+0x2E)
	pushw 0x0000			; push 0
	ld wa, (xsp + 40)		; WA = saved index (XSP+0x28)
	ld bc, (xsp + 38)		; BC = saved param (XSP+0x26)
	call HDAE5000_SaveSong			; call scroll handler
	ld (xsp + 2), hl		; save result at offset 2
	; --- Check result ---
	ld wa, (xsp + 2)		; reload result
	cp wa, 0xFFFF			; check for failure
	jr z, .Lds_alt			; if failed, try alternate
	; --- Direct dispatch ---
	ld xwa, (xsp + 40)		; load context (XSP+0x28)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_RootFnTable)
	ld xhl, (xbc + RootFn_PostEvent)
	ld xbc, 0x01C00001
	ld xde, 0:i3
	call (xhl)
	jr t, .Lds_finish
.Lds_alt:
	; --- Alternate handler ---
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld_sril xhl, (xwa + RootFn_SendEvent)
	ld xwa, HDAE5000_OBJ_ERR_SAVE
	ld xbc, 0x01C00001
	ld xde, 0:i3
	call (xhl)
	ld xbc, (xsp + 40)		; XBC = context (XSP+0x28)
	ld xwa, HDAE5000_OBJ_ERR_SAVE_EXIT
	calr HDAE5000_UiObj_SetCaption
	; --- Register display handlers ---
	ld xwa, 0x01CA0002
	push xwa
	ld xwa, (xsp + 44)		; XSP+0x2C
	push xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_KillApTimer)             ; +0x0418
	ld xwa, 0x0000014D
	ld xbc, HDAE5000_OBJ_ERR_SAVE_CATCH
	ld xde, 0xFFFFFFFF
	call (xhl)
	ld xwa, 0x01CA0002
	push xwa
	ld xwa, (xsp + 44)		; XSP+0x2C
	push xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_SetApTimer)             ; +0x0410
	ld xwa, 0x0000014D
	ld xbc, HDAE5000_OBJ_ERR_SAVE_CATCH
	ld xde, 0xFFFFFFFF
	call (xhl)
.Lds_finish:
	lda xwa, (0x22ac7e:24); lda XWA, 0x22AC7E
	lda xbc, (xsp + 4)
	calr HDAE5000_NameHistory_Push
	ld hl, (xsp + 2)		; restore result to HL
	popw iz
	lda xsp, (xsp + 34)		; deallocate stack
	retd 0x000A			; return and pop 10 bytes

HDAE5000_Display_Clear:	; 0x28B200 (43 bytes)
	; Clear display area: copy 7 bytes from ROM table, then call buffer validate
	; Input: XWA = pointer to display buffer
	ld ix, 0:i3			; IX = loop counter = 0
	cp ix, 7:i3
	jr nc, HDAE5000_Display_Clear__push
HDAE5000_Display_Clear__loop:
	stb_dpi c, 0xE0		; lda XHL, (XWA+) - get next dest addr, post-inc XWA
	ld bc, ix			; BC = current index
	extz xbc			; zero-extend to 32 bits
	ld xde, HDAE5000_Str_V206i		; ROM source table
	add xde, xbc			; XDE = &table[index]
	ld c, (xde)			; C = table byte
	ld (xhl), c			; store to display buffer
	inc 1, ix			; index++
	cp ix, 7:i3
	jr c, HDAE5000_Display_Clear__loop
HDAE5000_Display_Clear__push:
	pushw 0x002E			; push 0x2E (size param) -- high half of HDAE5000_Str_V206i
	pushw 0x1C82			; push 0x1C82 (offset param)		; low half of HDAE5000_Str_V206i
	call HDAE5000_StrLen
	inc 4, xsp			; deallocate 4 bytes from stack
	ret

HDAE5000_YieldUntilSem1Zero:	; 0x28B22B (45 bytes)
	; Loop: HamaFn_ref_sem_X(1) -- the main CPU returns semaphore 1's count
	; (byte 0x533: ref_sem_X jumps to the routine the v10 build calls
	; AudioLock_GetCount) -- and while it is not 0, HamaFn_rot_rdq_X(3)
	; (rotate ready queue 3: let the other tasks run).  Called before every
	; disk operation that follows a "please wait" screen.
	jr t, .LYieldUntilSem1Zero__poll
.LYieldUntilSem1Zero__yield:
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2) — workspace ptr
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_rot_rdq_X)		; rot_rdq_X
	ld wa, 3:i3		; queue 3
	call (xhl)
.LYieldUntilSem1Zero__poll:
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2) — workspace ptr
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xix, (xwa + HamaFn_ref_sem_X)		; ref_sem_X
	ld wa, 1:i3		; semaphore 1
	call (xix)
	cp hl, 0:i3		; count 0?
	jr nz, .LYieldUntilSem1Zero__yield		; no: yield and look again
	ret

HDAE5000_Set_Menu_Visibility:	; 0x28B258 (229 bytes)
	; Set visibility for 9 menu items via workspace callback +0x0294
	; Input: A = 0 → show (IZ=1), A != 0 → hide (IZ=0)
	pushw iz
	cp a, 0:i3
	jr nz, .Lsmv_hide
	ld iz, 1:i3			; show mode
	jr t, .Lsmv_start
.Lsmv_hide:
	ld iz, 0:i3			; hide mode
.Lsmv_start:
	ld bc, iz			; BC = visibility flag
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2)
	ld xwa, (xwa + WS_RootFnTable)             ; ld XWA, (XWA + 0x0E0A)
	ld xhl, (xwa + RootFn_SetVisible)             ; ld XHL, (XWA + 0x0294)
	ld xwa, HDAE5000_OBJ_SELECT_DIR_SW_EDIT		; menu item 1
	call (xhl)
	ld bc, iz
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_SetVisible)
	ld xwa, HDAE5000_OBJ_HD_FILE_LOAD_SW_SAVE		; menu item 2
	call (xhl)
	ld bc, iz
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_SetVisible)
	ld xwa, HDAE5000_OBJ_HD_FILE_LOAD_SW_DEL		; menu item 3
	call (xhl)
	ld bc, iz
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_SetVisible)
	ld xwa, HDAE5000_OBJ_FLS_SELECT_SW_EDIT		; menu item 4
	call (xhl)
	ld bc, iz
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_SetVisible)
	ld xwa, HDAE5000_OBJ_FLS_FILE_LOAD_SW_EDIT		; menu item 5
	call (xhl)
	ld bc, iz
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_SetVisible)
	ld xwa, HDAE5000_OBJ_HD_FILE_LOAD_SW_DELFILE		; menu item 6
	call (xhl)
	ld bc, iz
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_SetVisible)
	ld xwa, HDAE5000_OBJ_CP_FD_HDSWTO		; menu item 7
	call (xhl)
	ld bc, iz
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_SetVisible)
	ld xwa, HDAE5000_OBJ_CP_FD_HDSWSEL		; menu item 8
	call (xhl)
	ld bc, iz
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_SetVisible)
	ld xwa, HDAE5000_OBJ_SW_HD_FORMAT		; menu item 9
	call (xhl)
	popw iz
	ret

HDAE5000_Return_Stub:	; 0x28B33D (1 bytes)
	ret

HDAE5000_NameHistory_Push:	; 0x28B33E (61 bytes)
	; Add a name to a 5-entry history: XWA = history {u8 count, u8 recall
	; index, u8 next slot, pad, 5 x 27-byte names}, XBC = the name.  Copies
	; it into slot [+2], sets the recall index to that slot, advances the
	; slot modulo 5 and the count up to 5.  Histories: 0x22ABF2 (directory
	; names, HDAE5000_DirName_StoreWithUi) and 0x22AD0A (FLS names,
	; HDAE5000_FlsName_StoreWithUi); read back by HDAE5000_NameHistory_Recall.
	push xiz
	ld xiz, xwa		; XIZ = the history
	push xbc
	ld a, (xiz + 2)		; A = next slot
	extz wa
	muls wa, 0x001B			; offset = index * 27 (entry size)
	inc 4, wa		; past the 4-byte header
	exts xwa			; sign-extend to 32-bit
	add xwa, xiz		; XWA = &name[slot]
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp			; clean up 8 bytes (arg + saved XBC)
	ld a, (xiz + 2)		; recall index = the slot just written
	ld (xiz + 1), a
	lda xwa, (xiz + 2)
	incm8 1, (xwa)		; next slot
	ld a, (xwa)			; read new index value
	cp a, 5:i3
	jr c, .Lgte_no_wrap
	ld (xiz + 2), 0x00		; reset to 0
.Lgte_no_wrap:
	cp (xiz), 0x05		; count < 5?
	jr nc, .Lgte_no_inc
	incm8 1, (xiz)		; count++
.Lgte_no_inc:
	ld xwa, xiz
	calr HDAE5000_Return_Stub	; NOP call (returns immediately)
	pop xiz
	ret

HDAE5000_NameHistory_Recall:	; 0x28B37B (56 bytes)
	; XWA = a name history (see HDAE5000_NameHistory_Push): return XHL = the
	; name at the recall index and step the index back (from 0 to count-1),
	; or XHL = 0 when the history is empty.  Used by the naming windows' recall
	; key (event 0x01C00007, code 0x8A) to cycle through earlier names.
	cp (xwa), 0x00		; empty history?
	jr z, .LNameHistory_Recall__empty
	ld c, (xwa + 1)		; recall index
	extz bc				; zero-extend to 16-bit
	muls bc, 0x001B		; 27 bytes per name
	inc 4, bc		; past the 4-byte header
	lda_dri xhl, 0x07, 0xE0, 0xE4		; XHL = &name[recall index]
	cp (xwa + 1), 0x00		; check if index is non-zero
	jr nz, .LNameHistory_Recall__dec
	ld c, (xwa)			; get count
	cp c, 5:i3			; count == 5?
	jr nz, .LNameHistory_Recall__dec_count
	ld (xwa + 1), 0x04		; wrap: index = 4 (max-1)
	jr t, .LNameHistory_Recall__ret
.LNameHistory_Recall__dec_count:
	ld c, (xwa)			; get count
	dec 1, c			; count - 1
	ld (xwa + 1), c			; index = count - 1
	jr t, .LNameHistory_Recall__ret
.LNameHistory_Recall__dec:
	decm8 1, (xwa + 1)		; index--
	jr t, .LNameHistory_Recall__ret
.LNameHistory_Recall__empty:
	ld xhl, 0:i3			; return NULL
.LNameHistory_Recall__ret:
	ret

HDAE5000_Get_Status_Byte:	; 0x28B3B3 (6 bytes)
	; Return byte from 0x22AD9A in L
	ld l, (0x22ad9a:24); ld L, (0x22AD9A)
	ret

HDAE5000_Set_Status_Byte:	; 0x28B3B9 (6 bytes)
	; Store A to 0x22AD9B
	ld (0x22ad9b:24), a; ld (0x22AD9B), A
	ret

HDAE5000_Count_Active_Files:	; 0x28B3BF (43 bytes)
	; Count active file entries in table at 0x22AA9C
	; Input: none
	; Output: HL = count of entries with status byte == 1
	; Scans 20 entries (0x0014), each 0x0114 bytes apart
	ld hl, 0:i3		; HL = count = 0
	ld de, 0:i3		; DE = index = 0
	cp de, 0x0014		; check if index >= 20
	ret nc			; return if index >= 20 (unsigned)
HDAE5000_Count_Active_Files__loop:
	ld wa, de		; WA = current index
	extz xwa		; zero-extend to 32 bits
	add xwa, 0x00000114	; add entry size offset
	ld xbc, 0x0022AA9C	; table base address
	add xbc, xwa		; XBC = &table[index]
	cp (xbc), 0x01	; compare status byte with 1
	jr nz, HDAE5000_Count_Active_Files__skip
	inc 1, hl		; count++
HDAE5000_Count_Active_Files__skip:
	inc 1, de		; index++
	cp de, 0x0014		; check if index < 20
	jr c, HDAE5000_Count_Active_Files__loop
	ret

; --- UI Handler, File Operations, Path/String Utilities ---
HDAE5000_UiObj_SetCaption:	; 0x28B3EA
	; XWA = UI object id, XBC = string: ask the main CPU for the object's
	; record (workspace 0x0E0A table +0x2C4 -> XHL) and store the string
	; pointer at +0x16 -- the caption slot of the label records (see the
	; header of HDAE5000_UiObject_PtrTable's pool).  (Was UI_Main_Handler,
	; "(8731 bytes)": it is 22 bytes.)
; LUIH: 0x28B3EA (8731 bytes)
	; ^ conversion-region size (local-label prefix .LUIH_), not a routine size.

	push xiz
	ld	xiz, xbc
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xix, (xbc + RootFn_GetViewInstance)
	call	(xix)
	ld (xhl + 0x16), xiz                    ; ld (XHL+0x16),XIZ
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_ErrMsgTimerCatch:
	; registered as "ErrMsgTimerCatch" in HDAE5000_ObjHandler_Table
	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01ca0002
	jr z, .LUIH_b471                       ; [66 61] jr Z,0x28b471
	cp	xwa, 0x01c0000d
	jr z, .LUIH_b439                       ; [66 21] jr Z,0x28b439
	cp	xwa, 0x01e00085
	jr z, .LUIH_b435                       ; [66 15] jr Z,0x28b435
	ld	xwa, xiz
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xix, (xhl + RootFn_InheritedProc)
	call	(xix)
	jr t, .LUIH_b48d                       ; [68 58] jr T,0x28b48d
.LUIH_b435:
	ld	xhl, 1:i3
	jr t, .LUIH_b48d                       ; [68 54] jr T,0x28b48d
.LUIH_b439:
	ld	xwa, xiz
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	lda xwa, (HDAE5000_Str_Timb:24)
	ld	xbc, xwa
	ld	xwa, xiz
	ld	xde, xbc
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01c0000f
	call	(xhl)
	ld	xhl, 0:i3
	jr t, .LUIH_b48d                       ; [68 1c] jr T,0x28b48d
.LUIH_b471:
	ld	xwa, xde
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_PostEvent)
	ld	xbc, 0x01c00001
	ld	xde, 0:i3
	call	(xhl)
	ld	xhl, 0:i3
.LUIH_b48d:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_ErrMsgTimerCatchLBN:
	; registered as "ErrMsgTimerCatchLBN" in HDAE5000_ObjHandler_Table
	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01ca0002
	jr z, .LUIH_b4fd                       ; [66 61] jr Z,0x28b4fd
	cp	xwa, 0x01c0000d
	jr z, .LUIH_b4c5                       ; [66 21] jr Z,0x28b4c5
	cp	xwa, 0x01e00085
	jr z, .LUIH_b4c1                       ; [66 15] jr Z,0x28b4c1
	ld	xwa, xiz
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xix, (xhl + RootFn_InheritedProc)
	call	(xix)
	jr t, .LUIH_b525                       ; [68 64] jr T,0x28b525
.LUIH_b4c1:
	ld	xhl, 1:i3
	jr t, .LUIH_b525                       ; [68 60] jr T,0x28b525
.LUIH_b4c5:
	ld	xwa, xiz
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	lda xwa, (HDAE5000_Str_TLBN:24)
	ld	xbc, xwa
	ld	xwa, xiz
	ld	xde, xbc
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01c0000f
	call	(xhl)
	ld	xhl, 0:i3
	jr t, .LUIH_b525                       ; [68 28] jr T,0x28b525
.LUIH_b4fd:
	ld	xwa, xde
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_PostEvent)
	ld	xbc, 0x01c00001
	ld	xde, 0:i3
	call	(xhl)
	pushw 0x0001
	ld	wa, 0:i3
	ld	bc, 0:i3
	ld	de, 6:i3
	calr	HDAE5000_Lbn_ShowEntry
	ld	xhl, 0:i3
.LUIH_b525:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_BitmapButt01:
	; registered as "BitmapButt01" in HDAE5000_ObjHandler_Table
	cp	xbc, 0x01e000a3
	jr z, .LUIH_b54e                       ; [66 1f] jr Z,0x28b54e
	cp	xbc, 0x01e000a2
	jr z, .LUIH_b548                       ; [66 11] jr Z,0x28b548
	cp	xbc, 0x01e000a1
	jr z, .LUIH_b542                       ; [66 03] jr Z,0x28b542
	ld	xhl, 0:i3
	ret

.LUIH_b542:
	lda xhl, (HDAE5000_Bitmap_Button01:24)
	ret

.LUIH_b548:
	ld	xhl, 0x0000002a
	ret

.LUIH_b54e:
	ld	xhl, 0x0000000f
	ret

HDAE5000_AcLanguageText1Proc:
	; registered as "AcLanguageText1Proc" in HDAE5000_ClassProc_Table
	lda_dri xsp, 0xFD, 0x2A, 0xFF	; lda XSP,XSP+0xff2a
	push xiz
	stl_dri xde, 0xFD, 0xCE, 0x00	; ld (XSP+0x00ce),XDE
	stl_dri xbc, 0xFD, 0xD2, 0x00	; ld (XSP+0x00d2),XBC
	stl_dri xwa, 0xFD, 0xD6, 0x00	; ld (XSP+0x00d6),XWA
	ld_sril	xwa, (xsp + 0x00d2)
	cp	xwa, 0x01c0000f
	jr z, .LUIH_b5a9                       ; [66 33] jr Z,0x28b5a9
	cp	xwa, 0x01e00089
	jr z, .LUIH_b5a1                       ; [66 23] jr Z,0x28b5a1
	ld_sril	xwa, (xsp + 0x00d6)
	ld_sril	xbc, (xsp + 0x00d2)
	ld_sril	xde, (xsp + 0x00ce)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xix, (xhl + RootFn_InheritedProc)
	call	(xix)
	jrl t, .LUIH_cd01                      ; [78 60 17] jrl T,0x28cd01
.LUIH_b5a1:
	lda xhl, (HDAE5000_Str_Aclanguage1:24)
	jrl t, .LUIH_cd01                      ; [78 58 17] jrl T,0x28cd01
.LUIH_b5a9:
	ld_sril	xwa, (xsp + 0x00ce)
	or xwa, xwa                             ; or XWA,XWA
	jr nz, .LUIH_b5fb                      ; [6e 49] jr NZ,0x28b5fb
	ld_sril	xwa, (xsp + 0x00d6)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xix, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01e00089
	ld	xde, 0:i3
	call	(xix)
	ld	xiz, xhl
	cp	(xiz), 0x00
	jr nz, .LUIH_b600                      ; [6e 2a] jr NZ,0x28b600
	ld_sril	xwa, (xsp + 0x00d6)
	ld_sril	xbc, (xsp + 0x00d2)
	ld_sril	xde, (xsp + 0x00ce)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LUIH_cd01                      ; [78 06 17] jrl T,0x28cd01
.LUIH_b5fb:
	ld_sril	xiz, (xsp + 0x00ce)
.LUIH_b600:
	ldw (xsp + 0x04), 65535
	pushw 0x0008
	pushw 0x002e
	pushw 0x36e6		; low half of HDAE5000_Str_LANENG00
	ld	xwa, xiz
	push xwa
	call HDAE5000_StrNCmp
	add	xsp, 0x0000000a
	cp	hl, 0:i3
	jr nz, .LUIH_b624                      ; [6e 05] jr NZ,0x28b624
	ldw (xsp + 0x04), 1
.LUIH_b624:
	pushw 0x0008
	pushw 0x002e
	pushw 0x36f0		; low half of HDAE5000_Str_LANDEU00
	ld	xwa, xiz
	push xwa
	call HDAE5000_StrNCmp
	add	xsp, 0x0000000a
	cp	hl, 0:i3
	jr nz, .LUIH_b643                      ; [6e 05] jr NZ,0x28b643
	ldw (xsp + 0x04), 2
.LUIH_b643:
	pushw 0x0008
	pushw 0x002e
	pushw 0x36fa		; low half of HDAE5000_Str_LANFRA00
	ld	xwa, xiz
	push xwa
	call HDAE5000_StrNCmp
	add	xsp, 0x0000000a
	cp	hl, 0:i3
	jr nz, .LUIH_b662                      ; [6e 05] jr NZ,0x28b662
	ldw (xsp + 0x04), 3
.LUIH_b662:
	cpw	(xsp+4), 0x0000
	jr ge, .LUIH_b68e                      ; [69 25] jr GE,0x28b68e
	ld_sril	xwa, (xsp + 0x00d6)
	ld_sril	xbc, (xsp + 0x00d2)
	ld_sril	xde, (xsp + 0x00ce)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LUIH_cd01                      ; [78 73 16] jrl T,0x28cd01
.LUIH_b68e:
	ld_sril	xwa, (xsp + 0x00d6)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xix, (xbc + RootFn_GetViewInstance)
	call	(xix)
	ld	wa, (xhl+26)
	dec	1, wa
	cp	wa, 0:i3
	jrl lt, HDAE5000_AcLanguageText1Proc_NoMessage                     ; [71 1f 16] jrl LT,0x28cccd
	cp	wa, 0x0042
	jr le, .LUIH_b6c6                      ; [62 12] jr LE,0x28b6c6
	sub	wa, 0x0084
	cp	wa, 0x0043
	jrl lt, HDAE5000_AcLanguageText1Proc_NoMessage                     ; [71 0e 16] jrl LT,0x28cccd
	cp	wa, 0x004f
	jrl gt, HDAE5000_AcLanguageText1Proc_NoMessage                     ; [7a 07 16] jrl GT,0x28cccd
.LUIH_b6c6:
	add	wa, wa
	lda xix, (HDAE5000_LangText_CaseTable:24)
	ldw_sri wa, 0x07, 0xF0, 0xE0	; ld WA,(XIX+WA)
	lda xix, (HDAE5000_AcLanguageText1Proc_Msg001:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_AcLanguageText1Proc_Msg001:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_b6f3                      ; [6e 10] jr NZ,0x28b6f3
	pushw 0x002e
	pushw 0x3704		; low half of HDAE5000_LangMsg_001_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b6f3:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_b70a                      ; [6e 10] jr NZ,0x28b70a
	pushw 0x002e
	pushw 0x3734		; low half of HDAE5000_LangMsg_001_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b70a:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e cb 15] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3770		; low half of HDAE5000_LangMsg_001_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 b8 15] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg002:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_b73c                      ; [6e 10] jr NZ,0x28b73c
	pushw 0x002e
	pushw 0x3792		; low half of HDAE5000_LangMsg_002_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b73c:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_b753                      ; [6e 10] jr NZ,0x28b753
	pushw 0x002e
	pushw 0x37be		; low half of HDAE5000_LangMsg_002_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b753:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 82 15] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x37f6		; low half of HDAE5000_LangMsg_002_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 6f 15] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg003:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_b785                      ; [6e 10] jr NZ,0x28b785
	pushw 0x002e
	pushw 0x3814		; low half of HDAE5000_LangMsg_003_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b785:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_b79c                      ; [6e 10] jr NZ,0x28b79c
	pushw 0x002e
	pushw 0x382a		; low half of HDAE5000_LangMsg_003_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b79c:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 39 15] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3840		; low half of HDAE5000_LangMsg_003_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 26 15] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg004:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_b7ce                      ; [6e 10] jr NZ,0x28b7ce
	pushw 0x002e
	pushw 0x3856		; low half of HDAE5000_LangMsg_004_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b7ce:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_b7e5                      ; [6e 10] jr NZ,0x28b7e5
	pushw 0x002e
	pushw 0x3866		; low half of HDAE5000_LangMsg_004_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b7e5:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e f0 14] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3876		; low half of HDAE5000_LangMsg_004_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 dd 14] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg005:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_b817                      ; [6e 10] jr NZ,0x28b817
	pushw 0x002e
	pushw 0x3886		; low half of HDAE5000_LangMsg_005_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b817:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_b82e                      ; [6e 10] jr NZ,0x28b82e
	pushw 0x002e
	pushw 0x389c		; low half of HDAE5000_LangMsg_005_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b82e:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e a7 14] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x38b2		; low half of HDAE5000_LangMsg_005_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 94 14] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg006:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_b860                      ; [6e 10] jr NZ,0x28b860
	pushw 0x002e
	pushw 0x38c8		; low half of HDAE5000_LangMsg_006_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b860:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_b877                      ; [6e 10] jr NZ,0x28b877
	pushw 0x002e
	pushw 0x38dc		; low half of HDAE5000_LangMsg_006_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b877:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 5e 14] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x38f0		; low half of HDAE5000_LangMsg_006_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 4b 14] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg007:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_b8a9                      ; [6e 10] jr NZ,0x28b8a9
	pushw 0x002e
	pushw 0x3904		; low half of HDAE5000_LangMsg_007_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b8a9:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_b8c0                      ; [6e 10] jr NZ,0x28b8c0
	pushw 0x002e
	pushw 0x391c		; low half of HDAE5000_LangMsg_007_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b8c0:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 15 14] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3934		; low half of HDAE5000_LangMsg_007_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 02 14] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg008:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_b8f2                      ; [6e 10] jr NZ,0x28b8f2
	pushw 0x002e
	pushw 0x394c		; low half of HDAE5000_LangMsg_008_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b8f2:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_b909                      ; [6e 10] jr NZ,0x28b909
	pushw 0x002e
	pushw 0x395c		; low half of HDAE5000_LangMsg_008_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b909:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e cc 13] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x396c		; low half of HDAE5000_LangMsg_008_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 b9 13] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg009:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_b93b                      ; [6e 10] jr NZ,0x28b93b
	pushw 0x002e
	pushw 0x397c		; low half of HDAE5000_LangMsg_009_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b93b:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_b952                      ; [6e 10] jr NZ,0x28b952
	pushw 0x002e
	pushw 0x398c		; low half of HDAE5000_LangMsg_009_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b952:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 83 13] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x399c		; low half of HDAE5000_LangMsg_009_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 70 13] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg010:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_b984                      ; [6e 10] jr NZ,0x28b984
	pushw 0x002e
	pushw 0x39ac		; low half of HDAE5000_LangMsg_010_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b984:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_b99b                      ; [6e 10] jr NZ,0x28b99b
	pushw 0x002e
	pushw 0x39ba		; low half of HDAE5000_LangMsg_010_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b99b:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 3a 13] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x39c8		; low half of HDAE5000_LangMsg_010_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 27 13] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg011:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_b9cd                      ; [6e 10] jr NZ,0x28b9cd
	pushw 0x002e
	pushw 0x39d6		; low half of HDAE5000_LangMsg_011_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b9cd:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_b9e4                      ; [6e 10] jr NZ,0x28b9e4
	pushw 0x002e
	pushw 0x39e2		; low half of HDAE5000_LangMsg_011_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b9e4:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e f1 12] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x39ee		; low half of HDAE5000_LangMsg_011_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 de 12] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg012:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_ba16                      ; [6e 10] jr NZ,0x28ba16
	pushw 0x002e
	pushw 0x39fa		; low half of HDAE5000_LangMsg_012_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_ba16:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_ba2d                      ; [6e 10] jr NZ,0x28ba2d
	pushw 0x002e
	pushw 0x3a0a		; low half of HDAE5000_LangMsg_012_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_ba2d:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e a8 12] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3a1a		; low half of HDAE5000_LangMsg_012_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 95 12] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg013:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_ba5f                      ; [6e 10] jr NZ,0x28ba5f
	pushw 0x002e
	pushw 0x3a2a		; low half of HDAE5000_LangMsg_013_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_ba5f:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_ba76                      ; [6e 10] jr NZ,0x28ba76
	pushw 0x002e
	pushw 0x3a40		; low half of HDAE5000_LangMsg_013_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_ba76:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 5f 12] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3a56		; low half of HDAE5000_LangMsg_013_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 4c 12] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg014:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_baa8                      ; [6e 10] jr NZ,0x28baa8
	pushw 0x002e
	pushw 0x3a6c		; low half of HDAE5000_LangMsg_014_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_baa8:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_babf                      ; [6e 10] jr NZ,0x28babf
	pushw 0x002e
	pushw 0x3a8c		; low half of HDAE5000_LangMsg_014_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_babf:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 16 12] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3aac		; low half of HDAE5000_LangMsg_014_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 03 12] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg015:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_baf1                      ; [6e 10] jr NZ,0x28baf1
	pushw 0x002e
	pushw 0x3acc		; low half of HDAE5000_LangMsg_015_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_baf1:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bb08                      ; [6e 10] jr NZ,0x28bb08
	pushw 0x002e
	pushw 0x3aec		; low half of HDAE5000_LangMsg_015_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bb08:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e cd 11] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3b0c		; low half of HDAE5000_LangMsg_015_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 ba 11] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg016:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bb3a                      ; [6e 10] jr NZ,0x28bb3a
	pushw 0x002e
	pushw 0x3b2c		; low half of HDAE5000_LangMsg_016_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bb3a:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bb51                      ; [6e 10] jr NZ,0x28bb51
	pushw 0x002e
	pushw 0x3b78		; low half of HDAE5000_LangMsg_016_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bb51:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 84 11] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3bc8		; low half of HDAE5000_LangMsg_016_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 71 11] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg017:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bb83                      ; [6e 10] jr NZ,0x28bb83
	pushw 0x002e
	pushw 0x3c18		; low half of HDAE5000_LangMsg_017_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bb83:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bb9a                      ; [6e 10] jr NZ,0x28bb9a
	pushw 0x002e
	pushw 0x3c3c		; low half of HDAE5000_LangMsg_017_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bb9a:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 3b 11] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3c60		; low half of HDAE5000_LangMsg_017_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 28 11] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg018:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bbcc                      ; [6e 10] jr NZ,0x28bbcc
	pushw 0x002e
	pushw 0x3c84		; low half of HDAE5000_LangMsg_018_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bbcc:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bbe3                      ; [6e 10] jr NZ,0x28bbe3
	pushw 0x002e
	pushw 0x3cae		; low half of HDAE5000_LangMsg_018_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bbe3:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e f2 10] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3cda		; low half of HDAE5000_LangMsg_018_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 df 10] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg019:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bc15                      ; [6e 10] jr NZ,0x28bc15
	pushw 0x002e
	pushw 0x3d04		; low half of HDAE5000_LangMsg_019_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bc15:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bc2c                      ; [6e 10] jr NZ,0x28bc2c
	pushw 0x002e
	pushw 0x3d30		; low half of HDAE5000_LangMsg_019_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bc2c:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e a9 10] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3d5a		; low half of HDAE5000_LangMsg_019_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 96 10] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg020:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bc5e                      ; [6e 10] jr NZ,0x28bc5e
	pushw 0x002e
	pushw 0x3d86		; low half of HDAE5000_LangMsg_020_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bc5e:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bc75                      ; [6e 10] jr NZ,0x28bc75
	pushw 0x002e
	pushw 0x3d9a		; low half of HDAE5000_LangMsg_020_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bc75:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 60 10] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3dae		; low half of HDAE5000_LangMsg_020_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 4d 10] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg021:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bca7                      ; [6e 10] jr NZ,0x28bca7
	pushw 0x002e
	pushw 0x3dc2		; low half of HDAE5000_LangMsg_021_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bca7:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bcbe                      ; [6e 10] jr NZ,0x28bcbe
	pushw 0x002e
	pushw 0x3dfa		; low half of HDAE5000_LangMsg_021_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bcbe:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 17 10] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3e46		; low half of HDAE5000_LangMsg_021_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 04 10] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg022:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bcf0                      ; [6e 10] jr NZ,0x28bcf0
	pushw 0x002e
	pushw 0x3e8c		; low half of HDAE5000_LangMsg_022_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bcf0:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bd07                      ; [6e 10] jr NZ,0x28bd07
	pushw 0x002e
	pushw 0x3ebc		; low half of HDAE5000_LangMsg_022_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bd07:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e ce 0f] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3efc		; low half of HDAE5000_LangMsg_022_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 bb 0f] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg023:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bd39                      ; [6e 10] jr NZ,0x28bd39
	pushw 0x002e
	pushw 0x3f2c		; low half of HDAE5000_LangMsg_023_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bd39:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bd50                      ; [6e 10] jr NZ,0x28bd50
	pushw 0x002e
	pushw 0x3f5a		; low half of HDAE5000_LangMsg_023_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bd50:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 85 0f] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3f94		; low half of HDAE5000_LangMsg_023_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 72 0f] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg024:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bd82                      ; [6e 10] jr NZ,0x28bd82
	pushw 0x002e
	pushw 0x3fba		; low half of HDAE5000_LangMsg_024_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bd82:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bd99                      ; [6e 10] jr NZ,0x28bd99
	pushw 0x002e
	pushw 0x3fe2		; low half of HDAE5000_LangMsg_024_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bd99:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 3c 0f] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4014		; low half of HDAE5000_LangMsg_024_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 29 0f] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg025:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bdcb                      ; [6e 10] jr NZ,0x28bdcb
	pushw 0x002e
	pushw 0x4050		; low half of HDAE5000_LangMsg_025_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bdcb:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bde2                      ; [6e 10] jr NZ,0x28bde2
	pushw 0x002e
	pushw 0x40ae		; low half of HDAE5000_LangMsg_025_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bde2:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e f3 0e] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x411a		; low half of HDAE5000_LangMsg_025_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 e0 0e] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg026:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_be14                      ; [6e 10] jr NZ,0x28be14
	pushw 0x002e
	pushw 0x4170		; low half of HDAE5000_LangMsg_026_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_be14:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_be2b                      ; [6e 10] jr NZ,0x28be2b
	pushw 0x002e
	pushw 0x41ac		; low half of HDAE5000_LangMsg_026_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_be2b:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e aa 0e] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x41ee		; low half of HDAE5000_LangMsg_026_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 97 0e] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg027:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_be5d                      ; [6e 10] jr NZ,0x28be5d
	pushw 0x002e
	pushw 0x4230		; low half of HDAE5000_LangMsg_027_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_be5d:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_be74                      ; [6e 10] jr NZ,0x28be74
	pushw 0x002e
	pushw 0x4264		; low half of HDAE5000_LangMsg_027_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_be74:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 61 0e] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x42a8		; low half of HDAE5000_LangMsg_027_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 4e 0e] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg028:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bea6                      ; [6e 10] jr NZ,0x28bea6
	pushw 0x002e
	pushw 0x42ea		; low half of HDAE5000_LangMsg_028_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bea6:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bebd                      ; [6e 10] jr NZ,0x28bebd
	pushw 0x002e
	pushw 0x4320		; low half of HDAE5000_LangMsg_028_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bebd:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 18 0e] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4362		; low half of HDAE5000_LangMsg_028_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 05 0e] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg029:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_beef                      ; [6e 10] jr NZ,0x28beef
	pushw 0x002e
	pushw 0x439a		; low half of HDAE5000_LangMsg_029_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_beef:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bf06                      ; [6e 10] jr NZ,0x28bf06
	pushw 0x002e
	pushw 0x43bc		; low half of HDAE5000_LangMsg_029_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bf06:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e cf 0d] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x43e2		; low half of HDAE5000_LangMsg_029_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 bc 0d] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg030:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bf38                      ; [6e 10] jr NZ,0x28bf38
	pushw 0x002e
	pushw 0x4412		; low half of HDAE5000_LangMsg_030_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bf38:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bf4f                      ; [6e 10] jr NZ,0x28bf4f
	pushw 0x002e
	pushw 0x443c		; low half of HDAE5000_LangMsg_030_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bf4f:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 86 0d] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4472		; low half of HDAE5000_LangMsg_030_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 73 0d] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg031:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bf81                      ; [6e 10] jr NZ,0x28bf81
	pushw 0x002e
	pushw 0x449c		; low half of HDAE5000_LangMsg_031_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bf81:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bf98                      ; [6e 10] jr NZ,0x28bf98
	pushw 0x002e
	pushw 0x44bc		; low half of HDAE5000_LangMsg_031_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bf98:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 3d 0d] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x44e2		; low half of HDAE5000_LangMsg_031_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 2a 0d] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg032:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bfca                      ; [6e 10] jr NZ,0x28bfca
	pushw 0x002e
	pushw 0x4504		; low half of HDAE5000_LangMsg_032_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bfca:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bfe1                      ; [6e 10] jr NZ,0x28bfe1
	pushw 0x002e
	pushw 0x451a		; low half of HDAE5000_LangMsg_032_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bfe1:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e f4 0c] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4548		; low half of HDAE5000_LangMsg_032_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 e1 0c] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg033:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c013                      ; [6e 10] jr NZ,0x28c013
	pushw 0x002e
	pushw 0x4576		; low half of HDAE5000_LangMsg_033_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c013:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c02a                      ; [6e 10] jr NZ,0x28c02a
	pushw 0x002e
	pushw 0x458e		; low half of HDAE5000_LangMsg_033_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c02a:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e ab 0c] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x45c0		; low half of HDAE5000_LangMsg_033_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 98 0c] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg034:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c05c                      ; [6e 10] jr NZ,0x28c05c
	pushw 0x002e
	pushw 0x45e4		; low half of HDAE5000_LangMsg_034_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c05c:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c073                      ; [6e 10] jr NZ,0x28c073
	pushw 0x002e
	pushw 0x45fa		; low half of HDAE5000_LangMsg_034_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c073:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 62 0c] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4630		; low half of HDAE5000_LangMsg_034_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 4f 0c] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg035:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c0a5                      ; [6e 10] jr NZ,0x28c0a5
	pushw 0x002e
	pushw 0x4658		; low half of HDAE5000_LangMsg_035_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c0a5:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c0bc                      ; [6e 10] jr NZ,0x28c0bc
	pushw 0x002e
	pushw 0x4672		; low half of HDAE5000_LangMsg_035_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c0bc:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 19 0c] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x46a6		; low half of HDAE5000_LangMsg_035_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 06 0c] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg036:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c0ee                      ; [6e 10] jr NZ,0x28c0ee
	pushw 0x002e
	pushw 0x46ce		; low half of HDAE5000_LangMsg_036_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c0ee:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c105                      ; [6e 10] jr NZ,0x28c105
	pushw 0x002e
	pushw 0x46e8		; low half of HDAE5000_LangMsg_036_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c105:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e d0 0b] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x471c		; low half of HDAE5000_LangMsg_036_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 bd 0b] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg037:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c137                      ; [6e 10] jr NZ,0x28c137
	pushw 0x002e
	pushw 0x474a		; low half of HDAE5000_LangMsg_037_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c137:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c14e                      ; [6e 10] jr NZ,0x28c14e
	pushw 0x002e
	pushw 0x4764		; low half of HDAE5000_LangMsg_037_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c14e:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 87 0b] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4798		; low half of HDAE5000_LangMsg_037_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 74 0b] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg038:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c180                      ; [6e 10] jr NZ,0x28c180
	pushw 0x002e
	pushw 0x47c2		; low half of HDAE5000_LangMsg_038_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c180:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c197                      ; [6e 10] jr NZ,0x28c197
	pushw 0x002e
	pushw 0x47dc		; low half of HDAE5000_LangMsg_038_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c197:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 3e 0b] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4810		; low half of HDAE5000_LangMsg_038_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 2b 0b] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg039:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c1c9                      ; [6e 10] jr NZ,0x28c1c9
	pushw 0x002e
	pushw 0x483a		; low half of HDAE5000_LangMsg_039_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c1c9:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c1e0                      ; [6e 10] jr NZ,0x28c1e0
	pushw 0x002e
	pushw 0x4864		; low half of HDAE5000_LangMsg_039_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c1e0:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e f5 0a] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4892		; low half of HDAE5000_LangMsg_039_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 e2 0a] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg040:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c212                      ; [6e 10] jr NZ,0x28c212
	pushw 0x002e
	pushw 0x48c4		; low half of HDAE5000_LangMsg_040_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c212:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c229                      ; [6e 10] jr NZ,0x28c229
	pushw 0x002e
	pushw 0x490c		; low half of HDAE5000_LangMsg_040_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c229:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e ac 0a] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4968		; low half of HDAE5000_LangMsg_040_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 99 0a] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg041:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c25b                      ; [6e 10] jr NZ,0x28c25b
	pushw 0x002e
	pushw 0x49c0		; low half of HDAE5000_LangMsg_041_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c25b:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c272                      ; [6e 10] jr NZ,0x28c272
	pushw 0x002e
	pushw 0x4a08		; low half of HDAE5000_LangMsg_041_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c272:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 63 0a] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4a64		; low half of HDAE5000_LangMsg_041_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 50 0a] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg042:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c2a4                      ; [6e 10] jr NZ,0x28c2a4
	pushw 0x002e
	pushw 0x4abc		; low half of HDAE5000_LangMsg_042_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c2a4:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c2bb                      ; [6e 10] jr NZ,0x28c2bb
	pushw 0x002e
	pushw 0x4b20		; low half of HDAE5000_LangMsg_042_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c2bb:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 1a 0a] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4b82		; low half of HDAE5000_LangMsg_042_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 07 0a] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg043:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c2ed                      ; [6e 10] jr NZ,0x28c2ed
	pushw 0x002e
	pushw 0x4bd8		; low half of HDAE5000_LangMsg_043_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c2ed:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c304                      ; [6e 10] jr NZ,0x28c304
	pushw 0x002e
	pushw 0x4c2c		; low half of HDAE5000_LangMsg_043_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c304:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e d1 09] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4c8e		; low half of HDAE5000_LangMsg_043_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 be 09] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg044:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c336                      ; [6e 10] jr NZ,0x28c336
	pushw 0x002e
	pushw 0x4cd4		; low half of HDAE5000_LangMsg_044_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c336:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c34d                      ; [6e 10] jr NZ,0x28c34d
	pushw 0x002e
	pushw 0x4d12		; low half of HDAE5000_LangMsg_044_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c34d:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 88 09] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4d5e		; low half of HDAE5000_LangMsg_044_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 75 09] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg045:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c37f                      ; [6e 10] jr NZ,0x28c37f
	pushw 0x002e
	pushw 0x4d8e		; low half of HDAE5000_LangMsg_045_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c37f:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c396                      ; [6e 10] jr NZ,0x28c396
	pushw 0x002e
	pushw 0x4dc4		; low half of HDAE5000_LangMsg_045_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c396:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 3f 09] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4e06		; low half of HDAE5000_LangMsg_045_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 2c 09] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg046:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c3c8                      ; [6e 10] jr NZ,0x28c3c8
	pushw 0x002e
	pushw 0x4e4c		; low half of HDAE5000_LangMsg_046_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c3c8:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c3df                      ; [6e 10] jr NZ,0x28c3df
	pushw 0x002e
	pushw 0x4e96		; low half of HDAE5000_LangMsg_046_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c3df:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e f6 08] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4eee		; low half of HDAE5000_LangMsg_046_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 e3 08] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg047:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c411                      ; [6e 10] jr NZ,0x28c411
	pushw 0x002e
	pushw 0x4f18		; low half of HDAE5000_LangMsg_047_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c411:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c428                      ; [6e 10] jr NZ,0x28c428
	pushw 0x002e
	pushw 0x4f38		; low half of HDAE5000_LangMsg_047_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c428:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e ad 08] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4f72		; low half of HDAE5000_LangMsg_047_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 9a 08] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg048:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c45a                      ; [6e 10] jr NZ,0x28c45a
	pushw 0x002e
	pushw 0x4f96		; low half of HDAE5000_LangMsg_048_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c45a:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c471                      ; [6e 10] jr NZ,0x28c471
	pushw 0x002e
	pushw 0x4fb8		; low half of HDAE5000_LangMsg_048_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c471:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 64 08] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4fe0		; low half of HDAE5000_LangMsg_048_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 51 08] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg049:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c4a3                      ; [6e 10] jr NZ,0x28c4a3
	pushw 0x002e
	pushw 0x4ffe		; low half of HDAE5000_LangMsg_049_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c4a3:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c4ba                      ; [6e 10] jr NZ,0x28c4ba
	pushw 0x002e
	pushw 0x500e		; low half of HDAE5000_LangMsg_049_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c4ba:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 1b 08] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x5020		; low half of HDAE5000_LangMsg_049_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 08 08] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg050:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c4ec                      ; [6e 10] jr NZ,0x28c4ec
	pushw 0x002e
	pushw 0x5030		; low half of HDAE5000_LangMsg_050_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c4ec:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c503                      ; [6e 10] jr NZ,0x28c503
	pushw 0x002e
	pushw 0x5040		; low half of HDAE5000_LangMsg_050_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c503:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e d2 07] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x5050		; low half of HDAE5000_LangMsg_050_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 bf 07] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg051:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c535                      ; [6e 10] jr NZ,0x28c535
	pushw 0x002e
	pushw 0x5060		; low half of HDAE5000_LangMsg_051_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c535:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c54c                      ; [6e 10] jr NZ,0x28c54c
	pushw 0x002e
	pushw 0x508c		; low half of HDAE5000_LangMsg_051_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c54c:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 89 07] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x50b4		; low half of HDAE5000_LangMsg_051_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 76 07] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg052:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c57e                      ; [6e 10] jr NZ,0x28c57e
	pushw 0x002e
	pushw 0x50f2		; low half of HDAE5000_LangMsg_052_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c57e:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c595                      ; [6e 10] jr NZ,0x28c595
	pushw 0x002e
	pushw 0x5144		; low half of HDAE5000_LangMsg_052_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c595:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 40 07] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x51a8		; low half of HDAE5000_LangMsg_052_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 2d 07] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg053:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c5c7                      ; [6e 10] jr NZ,0x28c5c7
	pushw 0x002e
	pushw 0x520e		; low half of HDAE5000_LangMsg_053_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c5c7:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c5de                      ; [6e 10] jr NZ,0x28c5de
	pushw 0x002e
	pushw 0x521c		; low half of HDAE5000_LangMsg_053_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c5de:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e f7 06] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x522c		; low half of HDAE5000_LangMsg_053_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 e4 06] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg054:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c610                      ; [6e 10] jr NZ,0x28c610
	pushw 0x002e
	pushw 0x5240		; low half of HDAE5000_LangMsg_054_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c610:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c627                      ; [6e 10] jr NZ,0x28c627
	pushw 0x002e
	pushw 0x525e		; low half of HDAE5000_LangMsg_054_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c627:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e ae 06] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x527e		; low half of HDAE5000_LangMsg_054_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 9b 06] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg055:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c659                      ; [6e 10] jr NZ,0x28c659
	pushw 0x002e
	pushw 0x529a		; low half of HDAE5000_LangMsg_055_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c659:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c670                      ; [6e 10] jr NZ,0x28c670
	pushw 0x002e
	pushw 0x52ec		; low half of HDAE5000_LangMsg_055_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c670:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 65 06] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x5350		; low half of HDAE5000_LangMsg_055_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 52 06] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg056:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c6a2                      ; [6e 10] jr NZ,0x28c6a2
	pushw 0x002e
	pushw 0x53ae		; low half of HDAE5000_LangMsg_056_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c6a2:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c6b9                      ; [6e 10] jr NZ,0x28c6b9
	pushw 0x002e
	pushw 0x53ca		; low half of HDAE5000_LangMsg_056_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c6b9:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 1c 06] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x53e8		; low half of HDAE5000_LangMsg_056_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 09 06] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg057:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c6eb                      ; [6e 10] jr NZ,0x28c6eb
	pushw 0x002e
	pushw 0x5406		; low half of HDAE5000_LangMsg_057_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c6eb:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c702                      ; [6e 10] jr NZ,0x28c702
	pushw 0x002e
	pushw 0x5456		; low half of HDAE5000_LangMsg_057_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c702:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e d3 05] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x54a6		; low half of HDAE5000_LangMsg_057_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 c0 05] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg058:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c734                      ; [6e 10] jr NZ,0x28c734
	pushw 0x002e
	pushw 0x54f6		; low half of HDAE5000_LangMsg_058_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c734:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c74b                      ; [6e 10] jr NZ,0x28c74b
	pushw 0x002e
	pushw 0x5542		; low half of HDAE5000_LangMsg_058_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c74b:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 8a 05] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x5592		; low half of HDAE5000_LangMsg_058_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 77 05] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg059:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c77d                      ; [6e 10] jr NZ,0x28c77d
	pushw 0x002e
	pushw 0x55de		; low half of HDAE5000_LangMsg_059_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c77d:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c794                      ; [6e 10] jr NZ,0x28c794
	pushw 0x002e
	pushw 0x55fa		; low half of HDAE5000_LangMsg_059_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c794:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 41 05] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x5616		; low half of HDAE5000_LangMsg_059_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 2e 05] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg060:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c7c6                      ; [6e 10] jr NZ,0x28c7c6
	pushw 0x002e
	pushw 0x5632		; low half of HDAE5000_LangMsg_060_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c7c6:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c7dd                      ; [6e 10] jr NZ,0x28c7dd
	pushw 0x002e
	pushw 0x564e		; low half of HDAE5000_LangMsg_060_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c7dd:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e f8 04] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x566c		; low half of HDAE5000_LangMsg_060_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 e5 04] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg061:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c80f                      ; [6e 10] jr NZ,0x28c80f
	pushw 0x002e
	pushw 0x568e		; low half of HDAE5000_LangMsg_061_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c80f:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c826                      ; [6e 10] jr NZ,0x28c826
	pushw 0x002e
	pushw 0x56b4		; low half of HDAE5000_LangMsg_061_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c826:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e af 04] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x56e8		; low half of HDAE5000_LangMsg_061_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 9c 04] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg062:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c858                      ; [6e 10] jr NZ,0x28c858
	pushw 0x002e
	pushw 0x5718		; low half of HDAE5000_LangMsg_062_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c858:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c86f                      ; [6e 10] jr NZ,0x28c86f
	pushw 0x002e
	pushw 0x572c		; low half of HDAE5000_LangMsg_062_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c86f:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 66 04] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x5742		; low half of HDAE5000_LangMsg_062_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 53 04] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg064:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c8a1                      ; [6e 10] jr NZ,0x28c8a1
	pushw 0x002e
	pushw 0x5758		; low half of HDAE5000_LangMsg_064_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c8a1:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c8b8                      ; [6e 10] jr NZ,0x28c8b8
	pushw 0x002e
	pushw 0x576a		; low half of HDAE5000_LangMsg_064_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c8b8:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 1d 04] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x577c		; low half of HDAE5000_LangMsg_064_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 0a 04] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg065:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c8ea                      ; [6e 10] jr NZ,0x28c8ea
	pushw 0x002e
	pushw 0x578e		; low half of HDAE5000_LangMsg_065_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c8ea:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c901                      ; [6e 10] jr NZ,0x28c901
	pushw 0x002e
	pushw 0x579a		; low half of HDAE5000_LangMsg_065_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c901:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e d4 03] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x57a8		; low half of HDAE5000_LangMsg_065_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 c1 03] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg066:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c933                      ; [6e 10] jr NZ,0x28c933
	pushw 0x002e
	pushw 0x57b6		; low half of HDAE5000_LangMsg_066_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c933:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c94a                      ; [6e 10] jr NZ,0x28c94a
	pushw 0x002e
	pushw 0x57c4		; low half of HDAE5000_LangMsg_066_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c94a:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 8b 03] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x57d2		; low half of HDAE5000_LangMsg_066_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 78 03] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg067:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c97c                      ; [6e 10] jr NZ,0x28c97c
	pushw 0x002e
	pushw 0x57e2		; low half of HDAE5000_LangMsg_067_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c97c:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c993                      ; [6e 10] jr NZ,0x28c993
	pushw 0x002e
	pushw 0x581e		; low half of HDAE5000_LangMsg_067_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c993:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 42 03] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x585e		; low half of HDAE5000_LangMsg_067_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 2f 03] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg200:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c9c5                      ; [6e 10] jr NZ,0x28c9c5
	pushw 0x002e
	pushw 0x58a0		; low half of HDAE5000_LangMsg_200_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c9c5:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c9dc                      ; [6e 10] jr NZ,0x28c9dc
	pushw 0x002e
	pushw 0x58a4		; low half of HDAE5000_LangMsg_200_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c9dc:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e f9 02] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x58a8		; low half of HDAE5000_LangMsg_200_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 e6 02] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg201:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_ca0e                      ; [6e 10] jr NZ,0x28ca0e
	pushw 0x002e
	pushw 0x58ac		; low half of HDAE5000_LangMsg_201_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_ca0e:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_ca25                      ; [6e 10] jr NZ,0x28ca25
	pushw 0x002e
	pushw 0x58b0		; low half of HDAE5000_LangMsg_201_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_ca25:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e b0 02] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x58b6		; low half of HDAE5000_LangMsg_201_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 9d 02] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg202:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_ca57                      ; [6e 10] jr NZ,0x28ca57
	pushw 0x002e
	pushw 0x58ba		; low half of HDAE5000_LangMsg_202_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_ca57:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_ca6e                      ; [6e 10] jr NZ,0x28ca6e
	pushw 0x002e
	pushw 0x58be		; low half of HDAE5000_LangMsg_202_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_ca6e:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 67 02] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x58c2		; low half of HDAE5000_LangMsg_202_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 54 02] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg203:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_caa0                      ; [6e 10] jr NZ,0x28caa0
	pushw 0x002e
	pushw 0x58c6		; low half of HDAE5000_LangMsg_203_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_caa0:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_cab7                      ; [6e 10] jr NZ,0x28cab7
	pushw 0x002e
	pushw 0x58ce		; low half of HDAE5000_LangMsg_203_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cab7:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 1e 02] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x58d6		; low half of HDAE5000_LangMsg_203_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 0b 02] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg206:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_cae9                      ; [6e 10] jr NZ,0x28cae9
	pushw 0x002e
	pushw 0x58de		; low half of HDAE5000_LangMsg_206_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cae9:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_cb00                      ; [6e 10] jr NZ,0x28cb00
	pushw 0x002e
	pushw 0x58f0		; low half of HDAE5000_LangMsg_206_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cb00:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e d5 01] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x5902		; low half of HDAE5000_LangMsg_206_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 c2 01] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg207:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_cb32                      ; [6e 10] jr NZ,0x28cb32
	pushw 0x002e
	pushw 0x5916		; low half of HDAE5000_LangMsg_207_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cb32:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_cb49                      ; [6e 10] jr NZ,0x28cb49
	pushw 0x002e
	pushw 0x5924		; low half of HDAE5000_LangMsg_207_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cb49:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 8c 01] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x5932		; low half of HDAE5000_LangMsg_207_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 79 01] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg208:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_cb7b                      ; [6e 10] jr NZ,0x28cb7b
	pushw 0x002e
	pushw 0x5940		; low half of HDAE5000_LangMsg_208_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cb7b:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_cb92                      ; [6e 10] jr NZ,0x28cb92
	pushw 0x002e
	pushw 0x594e		; low half of HDAE5000_LangMsg_208_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cb92:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 43 01] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x595c		; low half of HDAE5000_LangMsg_208_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 30 01] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg209:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_cbc4                      ; [6e 10] jr NZ,0x28cbc4
	pushw 0x002e
	pushw 0x596a		; low half of HDAE5000_LangMsg_209_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cbc4:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_cbdb                      ; [6e 10] jr NZ,0x28cbdb
	pushw 0x002e
	pushw 0x597a		; low half of HDAE5000_LangMsg_209_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cbdb:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e fa 00] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x598a		; low half of HDAE5000_LangMsg_209_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 e7 00] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg210:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_cc0d                      ; [6e 10] jr NZ,0x28cc0d
	pushw 0x002e
	pushw 0x599a		; low half of HDAE5000_LangMsg_210_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cc0d:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_cc24                      ; [6e 10] jr NZ,0x28cc24
	pushw 0x002e
	pushw 0x59a6		; low half of HDAE5000_LangMsg_210_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cc24:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e b1 00] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x59b0		; low half of HDAE5000_LangMsg_210_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 9e 00] jrl T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg211:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_cc56                      ; [6e 10] jr NZ,0x28cc56
	pushw 0x002e
	pushw 0x59bc		; low half of HDAE5000_LangMsg_211_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cc56:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_cc6d                      ; [6e 10] jr NZ,0x28cc6d
	pushw 0x002e
	pushw 0x59e6		; low half of HDAE5000_LangMsg_211_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cc6d:
	cpw	(xsp+4), 0x0003
	jr nz, .LUIH_ccdd                      ; [6e 69] jr NZ,0x28ccdd
	pushw 0x002e
	pushw 0x5a2c		; low half of HDAE5000_LangMsg_211_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jr t, .LUIH_ccdd                       ; [68 57] jr T,0x28ccdd
HDAE5000_AcLanguageText1Proc_Msg212:
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_cc9d                      ; [6e 10] jr NZ,0x28cc9d
	pushw 0x002e
	pushw 0x5a5c		; low half of HDAE5000_LangMsg_212_EN
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cc9d:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_ccb4                      ; [6e 10] jr NZ,0x28ccb4
	pushw 0x002e
	pushw 0x5a88		; low half of HDAE5000_LangMsg_212_DE
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_ccb4:
	cpw	(xsp+4), 0x0003
	jr nz, .LUIH_ccdd                      ; [6e 22] jr NZ,0x28ccdd
	pushw 0x002e
	pushw 0x5ab0		; low half of HDAE5000_LangMsg_212_FR
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	jr t, .LUIH_ccdd                       ; [68 10] jr T,0x28ccdd
HDAE5000_AcLanguageText1Proc_NoMessage:
	pushw 0x002e
	pushw 0x5ad4		; low half of HDAE5000_LangMsg_NoMessage
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
.LUIH_ccdd:
	lda	xwa, (xsp+6)
	ld	xbc, xwa
	ld_sril	xwa, (xsp + 0x00d6)
	ld	xde, xbc
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01c0000f
	call	(xhl)
	ld	xhl, 0:i3
.LUIH_cd01:
	pop xiz                                 ; pop XIZ
	lda_dri xsp, 0xFD, 0xD6, 0x00	; lda XSP,XSP+0x00d6
	ret

HDAE5000_LyricBoxProc:
	; registered as "LyricBoxProc" in HDAE5000_ClassProc_Table
	lda	xsp, (xsp-16)
	pushw iz                                ; push IZ
	ld (xsp + 0x06), xde                    ; ld (XSP+0x06),XDE
	ld (xsp + 0x0a), xbc                    ; ld (XSP+0x0a),XBC
	ld (xsp + 0x0e), xwa                    ; ld (XSP+0x0e),XWA
	ld xwa, (xsp + 0x0a)                    ; ld XWA,(XSP+0x0a)
	cp	xwa, 0x01c00007
	jrl z, .LUIH_d544                      ; [76 23 08] jrl Z,0x28d544
	cp	xwa, 0x01c00002
	jrl z, .LUIH_d517                      ; [76 ed 07] jrl Z,0x28d517
	cp	xwa, 0x01c00001
	jrl z, .LUIH_d4e5                      ; [76 b2 07] jrl Z,0x28d4e5
	cp	xwa, 0x01c0000b
	jr z, .LUIH_cda9                       ; [66 6e] jr Z,0x28cda9
	cp	xwa, 0x01c0000d
	jr z, HDAE5000_LyricBoxProc_Ev01C0000D                       ; [66 2c] jr Z,0x28cd6f
	sub	xwa, 0x01ca0003
	cp	xwa, 0x00000000
	jrl lt, HDAE5000_LyricBoxProc_Default1                     ; [71 bf 05] jrl LT,0x28d311
	cp	xwa, 0x00000006
	jrl gt, HDAE5000_LyricBoxProc_Default1                     ; [7a b6 05] jrl GT,0x28d311
	add	xwa, xwa
	add	xwa, HDAE5000_LyricBoxProc_CaseTable1
	ld	wa, (xwa)
	lda xix, (HDAE5000_LyricBoxProc_Ev01C0000D:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_LyricBoxProc_Ev01C0000D:
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld xbc, (xsp + 0x0a)                    ; ld XBC,(XSP+0x0a)
	ld xde, (xsp + 0x06)                    ; ld XDE,(XSP+0x06)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01ca0008
	ld	xde, 0:i3
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LUIH_d600                      ; [78 57 08] jrl T,0x28d600
.LUIH_cda9:
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld xbc, (xsp + 0x0a)                    ; ld XBC,(XSP+0x0a)
	ld xde, (xsp + 0x06)                    ; ld XDE,(XSP+0x06)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01ca0003
	ld	xde, 0:i3
	call	(xhl)
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01ca0007
	ld	xde, 0:i3
	call	(xhl)
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01ca0008
	ld	xde, 1:i3
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LUIH_d600                      ; [78 e7 07] jrl T,0x28d600
HDAE5000_LyricBoxProc_Ev01CA0003:
	cp	(0x23A19A:24), 0
	jrl nz, .LUIH_cf93                     ; [7e 71 01] jrl NZ,0x28cf93
	ld	(0x23A19A:24), 1
	lda xwa, (0x22a08c:24)
	ld	xbc, xwa
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_RootFnTable)
	ld	xhl, (xde + RootFn_GetClientBox)
	call	(xhl)
	incw	2, (0x22A08C:24)
	incw	4, (0x22A08E:24)
	decw	1, (0x22A090:24)
	decw	2, (0x22A092:24)
	ld	wa, (0x22A08C:24)
	inc	2, wa
	ld	(0x22a094), wa
	ld	wa, (0x22A08E:24)
	dec	2, wa
	ld	(0x22a096), wa
	ld	wa, (0x22A090:24)
	dec	2, wa
	ld	(0x22a098), wa
	ld	wa, (0x22A096:24)
	add	wa, 0x000d
	ld	(0x22a09a), wa
	ld	wa, (0x22A08C:24)
	inc	6, wa
	ld	(0x22a09c), wa
	ld	wa, (0x22A08E:24)
	inc	2, wa
	ld	(0x22a09e), wa
	lda xwa, (0x22a0a0:24)
	ld	xbc, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_GetClientBox)
	ld	xwa, HDAE5000_OBJ_MeasureinLyric
	call	(xhl)
	ld	wa, (0x22A0A0:24)
	add	wa, 0x0014
	ld	(0x22a0a8), wa
	ld	wa, (0x22A0A2:24)
	inc	5, wa
	ld	(0x22a0aa), wa
	lda xwa, (0x22a0ac:24)
	ld	xbc, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_GetClientBox)
	ld	xwa, HDAE5000_OBJ_TimeSigInLyric
	call	(xhl)
	ld	wa, (0x22A0AC:24)
	add	wa, 0x0014
	ld	(0x22a0b4), wa
	ld	wa, (0x22A0AE:24)
	inc	5, wa
	ld	(0x22a0b6), wa
	ldw	(0x2307B8:24), 0
	ld	hl, 0:i3
	cp	hl, 0x0027
	jr ge, .LUIH_cf4a                      ; [69 2c] jr GE,0x28cf4a
.LUIH_cf1e:
	ld	wa, hl
	sla	wa, 0x02
	ld	bc, wa
	inc	4, bc
	ld	wa, (0x22A08C:24)
	add	wa, 0x009c
	ld	de, wa
	sub	de, bc
	ld	wa, hl
	add	wa, wa
	lda xbc, (0x2307ba:24)
	stw_dri de, 0x07, 0xE4, 0xE0	; ld (XBC+WA),DE
	inc	1, hl
	cp	hl, 0x0027
	jr lt, .LUIH_cf1e                      ; [61 d4] jr LT,0x28cf1e
.LUIH_cf4a:
	ld	hl, 0:i3
	cp	hl, 0x0027
	jr ge, .LUIH_cf6d                      ; [69 1b] jr GE,0x28cf6d
.LUIH_cf52:
	ld	wa, hl
	add	wa, wa
	lda xbc, (0x23080e:24)
	ld	de, hl
	sla	de, 0x03
	stw_dri de, 0x07, 0xE4, 0xE0	; ld (XBC+WA),DE
	inc	1, hl
	cp	hl, 0x0027
	jr lt, .LUIH_cf52                      ; [61 e5] jr LT,0x28cf52
.LUIH_cf6d:
	ld	hl, 0:i3
	cp	hl, 6:i3
	jr ge, .LUIH_cf93                      ; [69 20] jr GE,0x28cf93
.LUIH_cf73:
	ld	wa, hl
	muls	wa, 0x0012
	add	wa, (0x22A08E:24)
	add	a, 0x0f
	ld	c, a
	lda xwa, (0x230808:24)
	stb_dri c, 0x07, 0xE0, 0xEC	; ld (XWA+HL),C
	inc	1, hl
	cp	hl, 6:i3
	jr lt, .LUIH_cf73                      ; [61 e0] jr LT,0x28cf73
.LUIH_cf93:
	ld	xhl, 0:i3
	jrl t, .LUIH_d600                      ; [78 68 06] jrl T,0x28d600
HDAE5000_LyricBoxProc_Ev01CA0007:
	ld xwa, (xsp + 0x06)                    ; ld XWA,(XSP+0x06)
	cp	xwa, 0x00000001
	jr z, .LUIH_d005                       ; [66 62] jr Z,0x28d005
	or xwa, xwa                             ; or XWA,XWA
	jr z, .LUIH_cfac                       ; [66 05] jr Z,0x28cfac
	ld	xhl, 0:i3
	jrl t, .LUIH_d600                      ; [78 54 06] jrl T,0x28d600
.LUIH_cfac:
	cpw	(0x2307B2:24), 0
	jr z, .LUIH_d000                       ; [66 4b] jr Z,0x28d000
	ldw	(0x2307B2:24), 0
	ldw	(0x2307B4:24), 1
	calr	HDAE5000_Lyrics_ResetState
	ld	xwa, 0:i3
	calr	HDAE5000_Lyrics_ReadSongInfo
	ldw	(0x22A0B8:24), 0
	ld	wa, 0:i3
	ld	bc, 0:i3
	calr	HDAE5000_Lyrics_FillLines
	ld	(0x230870), hl
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01c0000d
	ld	xde, 0:i3
	call	(xhl)
	ldw	(0x2307B4:24), 0
.LUIH_d000:
	ld	xhl, 0:i3
	jrl t, .LUIH_d600                      ; [78 fb 05] jrl T,0x28d600
.LUIH_d005:
	calr	HDAE5000_Lyrics_ResetState
	ld	xwa, 0:i3
	calr	HDAE5000_Lyrics_ReadSongInfo
	ldw	(0x22A0B8:24), 0
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01c0000b
	ld	xde, 0:i3
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LUIH_d600                      ; [78 cc 05] jrl T,0x28d600
HDAE5000_LyricBoxProc_Ev01CA0008:
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xix, (xbc + RootFn_GetViewInstance)
	call	(xix)
	ld	(0x22a088), xhl
	ld	iz, 0:i3
	cp	iz, 6:i3
	jrl nc, .LUIH_d1a2                     ; [7f 4e 01] jrl NC,0x28d1a2
.LUIH_d054:
	ld	wa, iz
	extz xwa
	ld	xbc, xwa
	sll	xbc, 0x02
	add	xbc, xwa
	sll	xbc, 0x03
	ld	xwa, HDAE5000_RAM_LyricLines
	add	xwa, xbc
	push xwa
	call HDAE5000_StrLen
	inc 4, xsp                              ; inc 4,XSP
	ld	wa, iz
	extz xwa
	add	xwa, 0x00000010
	ld	xbc, 0x002304d8
	add	xbc, xwa
	ld_dst8_ri xbc, l		; ld (XBC),L
	ld	wa, (0x230806:24)
	ld (xsp + 0x02), wa                     ; ld (XSP+0x02),WA
	ld	wa, iz
	extz xwa
	ld	xbc, 0x00230808
	add	xbc, xwa
	ld	a, (xbc)
	extz wa                                 ; extz WA
	ld (xsp + 0x04), wa                     ; ld (XSP+0x04),WA
	lda xhl, (0x22a08c:24)
	lda	xbc, (xsp+2)
	lda xwa, (HDAE5000_Str_Blank40:24)
	ld	xde, xwa
	ld	xwa, (0x22a088)
	ld xwa, (xwa + 0x20)                    ; ld XWA,(XWA+0x20)
	push xwa
	ld	a, (0x230880:24)
	extz wa                                 ; extz WA
	pushw wa                                ; push WA
	ld	xwa, (0x22a088)
	pushm	(xwa+22)
	ld	xwa, xhl
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_DrawString)
	call	(xhl)
	ld	wa, iz
	extz xwa
	add	xwa, 0x00000010
	ld	xbc, 0x002304d8
	add	xbc, xwa
	ld	a, (xbc)
	extz wa                                 ; extz WA
	add	wa, wa
	lda xbc, (0x2307b8:24)
	ldw_sri wa, 0x07, 0xE4, 0xE0	; ld WA,(XBC+WA)
	ld (xsp + 0x02), wa                     ; ld (XSP+0x02),WA
	ld	a, (0x2304EE:24)
	extz wa                                 ; extz WA
	cp	wa, iz
	jr ule, .LUIH_d152                     ; [63 4b] jr ULE,0x28d152
	lda xhl, (0x22a08c:24)
	lda	xbc, (xsp+2)
	ld	wa, iz
	extz xwa
	ld	xix, xwa
	sll	xix, 0x02
	add	xix, xwa
	sll	xix, 0x03
	ld	xde, HDAE5000_RAM_LyricLines
	add	xde, xix
	ld	xwa, (0x22a088)
	ld xwa, (xwa + 0x20)                    ; ld XWA,(XWA+0x20)
	push xwa
	ld	a, (0x23087E:24)
	extz wa                                 ; extz WA
	pushw wa                                ; push WA
	ld	xwa, (0x22a088)
	pushm	(xwa+22)
	ld	xwa, xhl
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_DrawString)
	call	(xhl)
	jr t, .LUIH_d19b                       ; [68 49] jr T,0x28d19b
.LUIH_d152:
	lda xhl, (0x22a08c:24)
	lda	xbc, (xsp+2)
	ld	wa, iz
	extz xwa
	ld	xix, xwa
	sll	xix, 0x02
	add	xix, xwa
	sll	xix, 0x03
	ld	xde, HDAE5000_RAM_LyricLines
	add	xde, xix
	ld	xwa, (0x22a088)
	ld xwa, (xwa + 0x20)                    ; ld XWA,(XWA+0x20)
	push xwa
	ld	a, (0x230880:24)
	extz wa                                 ; extz WA
	pushw wa                                ; push WA
	ld	xwa, (0x22a088)
	pushm	(xwa+22)
	ld	xwa, xhl
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_DrawString)
	call	(xhl)
.LUIH_d19b:
	inc	1, iz
	cp	iz, 6:i3
	jrl c, .LUIH_d054                      ; [77 b2 fe] jrl C,0x28d054
.LUIH_d1a2:
	lda xwa, (0x22a094:24)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_DrawFrame)
	ldw	bc, 0x00f9
	call	(xhl)
	lda xhl, (0x22a08c:24)
	lda xbc, (0x22a09c:24)
	lda xde, (0x2306b6:24)
	ld	xwa, (0x22a088)
	ld xwa, (xwa + 0x28)                    ; ld XWA,(XWA+0x28)
	push xwa
	ld	xwa, (0x22a088)
	pushm	(xwa+44)
	ld	xwa, (0x22a088)
	pushm	(xwa+22)
	ld	xwa, xhl
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_DrawString)
	call	(xhl)
	ld xwa, (xsp + 0x06)                    ; ld XWA,(XSP+0x06)
	cp	xwa, 0x00000001
	jrl nz, .LUIH_d2a5                     ; [7e a3 00] jrl NZ,0x28d2a5
	lda xwa, (0x230736:24)
	ld	xde, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_Conductor
	ld	xbc, 0x01c0000f
	call	(xhl)
	lda xwa, (0x230768:24)
	ld	xde, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_SongTitle
	ld	xbc, 0x01c0000f
	call	(xhl)
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01ca0009
	ld	xde, 4:i3
	call	(xhl)
	lda xwa, (HDAE5000_Str_Reset:24)
	ld	xde, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_bottom01
	ld	xbc, 0x01c0000f
	call	(xhl)
	lda xwa, (HDAE5000_Str_Load:24)
	ld	xde, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_bottom08
	ld	xbc, 0x01c0000f
	call	(xhl)
.LUIH_d2a5:
	ld	xhl, 0:i3
	jrl t, .LUIH_d600                      ; [78 56 03] jrl T,0x28d600
HDAE5000_LyricBoxProc_Ev01CA0009:
	ld xwa, (xsp + 0x06)                    ; ld XWA,(XSP+0x06)
	cp	xwa, 0x00000004
	jrl z, .LUIH_d3e5                      ; [76 2f 01] jrl Z,0x28d3e5
	cp	xwa, 0x00000003
	jrl z, .LUIH_d3ab                      ; [76 ec 00] jrl Z,0x28d3ab
	cp	xwa, 0x00000002
	jrl z, .LUIH_d36d                      ; [76 a5 00] jrl Z,0x28d36d
	cp	xwa, 0x00000001
	jr z, .LUIH_d32e                       ; [66 5e] jr Z,0x28d32e
	or xwa, xwa                             ; or XWA,XWA
	jr nz, HDAE5000_LyricBoxProc_Default1                      ; [6e 3d] jr NZ,0x28d311
	lda xhl, (0x22a08c:24)
	lda xbc, (0x23087a:24)
	lda xwa, (0x23051e:24)
	ld	xde, xwa
	ld	xwa, (0x22a088)
	ld xwa, (xwa + 0x20)                    ; ld XWA,(XWA+0x20)
	push xwa
	ld	a, (0x23087E:24)
	extz wa                                 ; extz WA
	pushw wa                                ; push WA
	ld	xwa, (0x22a088)
	pushm	(xwa+22)
	ld	xwa, xhl
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_DrawString)
	call	(xhl)
HDAE5000_LyricBoxProc_Default1:
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld xbc, (xsp + 0x0a)                    ; ld XBC,(XSP+0x0a)
	ld xde, (xsp + 0x06)                    ; ld XDE,(XSP+0x06)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xix, (xhl + RootFn_InheritedProc)
	call	(xix)
	jrl t, .LUIH_d600                      ; [78 d2 02] jrl T,0x28d600
.LUIH_d32e:
	lda xhl, (0x22a08c:24)
	lda xbc, (0x23087a:24)
	lda xwa, (0x23051e:24)
	ld	xde, xwa
	ld	xwa, (0x22a088)
	ld xwa, (xwa + 0x20)                    ; ld XWA,(XWA+0x20)
	push xwa
	ld	a, (0x230880:24)
	extz wa                                 ; extz WA
	pushw wa                                ; push WA
	ld	xwa, (0x22a088)
	pushm	(xwa+22)
	ld	xwa, xhl
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_DrawString)
	call	(xhl)
	jr t, HDAE5000_LyricBoxProc_Default1                       ; [68 a4] jr T,0x28d311
.LUIH_d36d:
	lda xhl, (0x22a08c:24)
	lda xbc, (0x22a09c:24)
	lda xde, (0x2306b6:24)
	ld	xwa, (0x22a088)
	ld xwa, (xwa + 0x28)                    ; ld XWA,(XWA+0x28)
	push xwa
	ld	xwa, (0x22a088)
	pushm	(xwa+44)
	ld	xwa, (0x22a088)
	pushm	(xwa+22)
	ld	xwa, xhl
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_DrawString)
	call	(xhl)
	jrl t, HDAE5000_LyricBoxProc_Default1                      ; [78 66 ff] jrl T,0x28d311
.LUIH_d3ab:
	lda xwa, (0x22a0a0:24)
	ld	xhl, xwa
	lda xwa, (0x22a0a8:24)
	ld	xbc, xwa
	lda xwa, (0x23079a:24)
	ld	xde, xwa
	ld	xwa, (0x22a088)
	ld xwa, (xwa + 0x28)                    ; ld XWA,(XWA+0x28)
	push xwa
	pushw 0x00ff
	pushw 0x0008
	ld	xwa, xhl
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_DrawString)
	call	(xhl)
	jrl t, HDAE5000_LyricBoxProc_Default1                      ; [78 2c ff] jrl T,0x28d311
.LUIH_d3e5:
	lda xwa, (0x22a0ac:24)
	ld	xhl, xwa
	lda xwa, (0x22a0b4:24)
	ld	xbc, xwa
	lda xwa, (0x230790:24)
	ld	xde, xwa
	ld	xwa, (0x22a088)
	ld xwa, (xwa + 0x28)                    ; ld XWA,(XWA+0x28)
	push xwa
	pushw 0x00ff
	pushw 0x0008
	ld	xwa, xhl
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_DrawString)
	call	(xhl)
	jrl t, HDAE5000_LyricBoxProc_Default1                      ; [78 f2 fe] jrl T,0x28d311
HDAE5000_LyricBoxProc_Ev01CA0004:
	cpw	(0x2307B4:24), 0
	jrl nz, HDAE5000_LyricBoxProc_Default1                     ; [7e e8 fe] jrl NZ,0x28d311
	ld xwa, (xsp + 0x06)                    ; ld XWA,(XSP+0x06)
	ld	bc, 1:i3
	calr	HDAE5000_Lyrics_PlayToPosition
	ld	wa, (0x230874:24)
	cp	wa, (0x2307B0:24)
	jr c, .LUIH_d470                       ; [67 33] jr C,0x28d470
	ld	wa, (0x2307AE:24)
	ld	(0x2307b0), wa
	incw	1, (0x230872:24)
	ldw	(0x230874:24), 0
	ld	xwa, (HDAE5000_RAM_LyricBoxObj)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01ca0005
	ld	xde, 0:i3
	call	(xhl)
.LUIH_d470:
	incw	1, (0x230874:24)
	ld	xwa, 1:i3
	add	(0x230876:24), xwa
	jrl t, HDAE5000_LyricBoxProc_Default1                      ; [78 92 fe] jrl T,0x28d311
HDAE5000_LyricBoxProc_Ev01CA0005:
	incw	1, (0x2307AC:24)
	ld	a, (0x2307A6:24)
	extz wa                                 ; extz WA
	cp	(0x2307AC:24), wa
	jr ule, .LUIH_d4a8                     ; [63 16] jr ULE,0x28d4a8
	ld	a, (0x2307A4:24)
	ld	(0x2307A6:24), a
	incw	1, (0x2307AA:24)
	ldw	(0x2307AC:24), 1
.LUIH_d4a8:
	ld	wa, (0x2307AC:24)
	pushw wa                                ; push WA
	ld	wa, (0x2307AA:24)
	pushw wa                                ; push WA
	pushw 0x002e
	pushw 0x5bb6		; low half of HDAE5000_Fmt_03i_i
	lda xwa, (0x23079a:24)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01ca0009
	ld	xde, 3:i3
	call	(xhl)
	jrl t, HDAE5000_LyricBoxProc_Default1                      ; [78 2c fe] jrl T,0x28d311
.LUIH_d4e5:
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xix, (xbc + RootFn_GetViewInstance)
	call	(xix)
	ld	(0x22a088), xhl
	ld xwa, (xhl + 0x1c)                    ; ld XWA,(XHL+0x1c)
	ldw	(xwa), 0x0001
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	(HDAE5000_RAM_LyricBoxObj), xwa
	ldw	(0x2307B2:24), 1
	jrl t, HDAE5000_LyricBoxProc_Default1                      ; [78 fa fd] jrl T,0x28d311
.LUIH_d517:
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xix, (xbc + RootFn_GetViewInstance)
	call	(xix)
	ld	(0x22a088), xhl
	ld xwa, (xhl + 0x1c)                    ; ld XWA,(XHL+0x1c)
	ldw	(xwa), 0x0000
	ld	xwa, 0xffffffff
	ld	(HDAE5000_RAM_LyricBoxObj), xwa
	jrl t, HDAE5000_LyricBoxProc_Default1                      ; [78 cd fd] jrl T,0x28d311
.LUIH_d544:
	ld xde, (xsp + 0x06)                    ; ld XDE,(XSP+0x06)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xix, (xwa + RootFn_SendEvent)
	ld	xwa, 0x02600024
	ld	xbc, 0x01e00029
	call	(xix)
	ld	xwa, xhl
	cp	xwa, 0x00000007
	jrl ugt, HDAE5000_LyricBoxProc_Default2                    ; [7b 91 00] jrl UGT,0x28d5fe
	add	xwa, xwa
	add	xwa, HDAE5000_LyricBoxProc_CaseTable2
	ld	wa, (xwa)
	lda xix, (HDAE5000_LyricBoxProc_Case0_2:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_LyricBoxProc_Case0_2:
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01ca0007
	ld	xde, 1:i3
	call	(xhl)
	ld	wa, 0:i3
	ld	bc, 0:i3
	calr	HDAE5000_Lyrics_FillLines
	ld	(0x230870), hl
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01c0000d
	ld	xde, 0:i3
	call	(xhl)
	jr t, HDAE5000_LyricBoxProc_Default2                       ; [68 39] jr T,0x28d5fe
HDAE5000_LyricBoxProc_Case7_2:
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xix, (xbc + RootFn_GetViewInstance)
	call	(xix)
	ld	(0x22a088), xhl
	calr	HDAE5000_Lyrics_ClearBuffer
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_ApPostEvent)
	ld	xwa, HDAE5000_OBJ_LoadLyricFD
	ld	xbc, 0x01c00001
	ld	xde, 0:i3
	call	(xhl)
HDAE5000_LyricBoxProc_Default2:
	ld	xhl, 0:i3
.LUIH_d600:
	popw iz                                 ; pop IZ
	lda	xsp, (xsp+16)
	ret


HDAE5000_Lyrics_ClearBuffer:	; 0x28D605 (32 bytes)
	; Clear the lyric file buffer 0x22B430 (0x5000 bytes), zero (0x2304F2) (the
	; track end, see HDAE5000_Lyrics_CheckTrackChunk) and the loaded flag
	; (0x23A19C).  Called by HDAE5000_LyricBoxProc (case 7) and HDAE5000_LoadSong_Tlx.
	;
	; The lyrics player keeps the whole lyric file in RAM at 0x22B430 (0x5000
	; bytes).  Its layout is that of a one-track Standard MIDI File with the
	; chunk ids renamed: "TLhd" (+0, length 6, format, tracks, division) and
	; "TLtr" (+14, length), events from +22, each <VarLen delta> FF <type>
	; <VarLen length> <data> -- see HDAE5000_Lyrics_CheckHeaderChunk and
	; HDAE5000_Lyrics_ParseEvent.
	pushw 0x5000			; param: size 0x5000
	pushw 0x0000			; param: fill value 0
	lda xwa, (HDAE5000_RAM_LyricBuffer:24)		; XWA = lyric buffer 0x22B430
	push xwa
	call HDAE5000_MemFill
	inc 0, xsp			; deallocate 8 bytes
	ld xwa, 0:i3			; clear XWA
	ld (0x2304f2:24), xwa		; (0x2304F2) = 0: track end
	ld (HDAE5000_RAM_LyricLoaded:24), 0x00		; (0x23A19C) = 0: nothing loaded
	ret

HDAE5000_Lyrics_CheckFile:
	; Check the lyric file in the buffer: HDAE5000_Lyrics_CheckHeaderChunk (-2
	; on failure) and HDAE5000_Lyrics_CheckTrackChunk (-1); on success set the
	; loaded flag (0x23A19C) = 1 and return 0.  No caller was found
	; (scripts/analysis/hdae5000_reachability.py): the file checks are dead code.
	calr HDAE5000_Lyrics_CheckHeaderChunk
	or xhl, xhl			; check result
	jr nz, .Lde_err2		; if nonzero, error
	calr HDAE5000_Lyrics_CheckTrackChunk
	or xhl, xhl			; check result
	jr nz, .Lde_err1		; if nonzero, error
	ld (HDAE5000_RAM_LyricLoaded:24), 0x01		; (0x23A19C) = 1: lyric file loaded
	ld xhl, 0:i3			; return success
	ret
.Lde_err1:
	ld xhl, 0xFFFFFFFF		; return -1
	ret
.Lde_err2:
	ld xhl, 0xFFFFFFFE		; return -2
	ret

HDAE5000_Lyrics_LoadTestFile:
	; Debug loader: when HamaFn_GetMediaType returns 2 or 3, read the file
	; "TESTTEST.TLX" (mode "rb") with the main CPU's fopen_ext/fread_ext/
	; fclose_ext into the lyric buffer (0x5000 bytes), between SleepMainTask
	; and WakeUpMainTask; otherwise return -1.  No caller was found
	; (scripts/analysis/hdae5000_reachability.py).
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2) — workspace ptr
	ld xwa, (xwa + WS_HamaFnTable)             ; ld XWA, (XWA + 0x0E88)
	ld xix, (xwa + HamaFn_GetMediaType)		; XIX = GetMediaType
	call (xix)
	cp l, 3:i3			; check if result == 3
	jr z, .Lde_ready
	cp l, 2:i3			; check if result == 2
	jr z, .Lde_ready
	ld xhl, 0xFFFFFFFF		; return -1: no medium of type 2/3
	ret
	; read the file
.Lde_ready:
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)             ; ld XWA, (XWA + 0x0E0A)
	ld xhl, (xwa + RootFn_SleepMainTask)             ; ld XHL, (XWA + 0x0538)
	call (xhl)
	lda xwa, (HDAE5000_Str_TESTTESTTLX:24); lda XWA, 0x2E5BE4
	lda xbc, (HDAE5000_Str_Rb:24); lda XBC, 0x2E5BE0
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24); ld XDE, (0x23A1A2)
	ld xde, (xde + WS_HamaFnTable)             ; ld XDE, (XDE + 0x0E88)
	ld_sril xhl, (xde + HamaFn_fopen_ext)             ; ld XHL, (XDE + 0x00A0)
	call (xhl)
	lda xwa, (HDAE5000_RAM_LyricBuffer:24); lda XWA, 0x22B430
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24); ld XBC, (0x23A1A2)
	ld xbc, (xbc + WS_HamaFnTable)             ; ld XBC, (XBC + 0x0E88)
	ld_sril xhl, (xbc + HamaFn_fread_ext)             ; ld XHL, (XBC + 0x00A8)
	ld xbc, 0x00005000		; size = 0x5000
	call (xhl)
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_fclose_ext)             ; ld XHL, (XWA + 0x00AC)
	call (xhl)
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_WakeUpMainTask)             ; ld XHL, (XWA + 0x053C)
	call (xhl)
	ld xhl, 0:i3			; return success
	ret

HDAE5000_Lyrics_PlayToPosition:	; 0x28D6D1 (938 bytes)
	; Advance the lyric display to the song position.  XWA = the event
	; parameter of HDAE5000_LyricBoxProc's event 0x01CA0004 (its only caller),
	; C = 1 to redraw.  The target tick is (XWA+4) * (0x230868) (= division / 12,
	; HDAE5000_Lyrics_ResetState); from the last position (0x23086C) it takes
	; event after event with HDAE5000_Lyrics_FindEvent (0x7C = any type) until
	; the running tick passes the target or the end-of-track flag (0x230434)
	; is set, and acts on the meta type in (0x230430):
	;   0x05  lyric syllable: append it to the current line (<= 39 chars) and
	;         move the highlight; CR / LF end the line, and after the third
	;         line HDAE5000_Lyrics_FillLines(1, ...) scrolls the window;
	;   0x58  time signature: numerator (0x2307A4), 2^denominator (0x2307A8),
	;         printed with "%i/%i" (HDAE5000_Fmt_i_i);
	;   0x7E  data "0...": chord name, printed with "Chord : %s".
	; A parse error prints "Fault : No Lyrics loaded or corrupt Data - Code
	; %i %i %i".  Redraw requests go to the lyric box object (0x23A19E) as
	; SendEvent 0x01CA0008 / 0x01CA0009.

	; --- Prologue: allocate 12 bytes, save XIZ ---
	dec 6, xsp
	push xiz
	ld (xsp + 8), c			; save display flag
	ld xiz, xwa			; XIZ = param struct ptr

	; --- Compute sector count, check limits ---
	ld xbc, (0x230868:24); XBC = (0x230868)
	ld xwa, (xiz + 4)		; XWA = param[4]
	call HDAE5000_Multiply		; target tick = (0x230868) * (XWA+4)
	cp (2295908:24), xhl; cp (0x230864), XHL
	jrl z, .Lfo_epilogue		; same tick as last time: nothing to do
	ld (0x230864:24), xhl; (0x230864) = XHL
	ld xwa, (0x230444:24); XWA = (0x230444)
	cp xwa, (2295908:24); cp XWA, (0x230864)
	jrl ugt, .Lfo_epilogue		; running tick already past it: exit
	cpw (2294836:24), 0		; end-of-track flag
	jrl nz, .Lfo_epilogue		; if abort, exit
	ldw (xsp + 6), 0		; iteration counter = 0

	; --- next event ---
.Lfo_loop:				; 0x28D70E
	ld wa, (0x23086c:24)		; WA = (0x23086C): position of the last event
	extz xwa
	push xwa			; push offset arg
	ldw wa, 124			; WA = 0x7C
	ld bc, 2:i3
	ldw de, 65534			; DE = 0xFFFE
	calr HDAE5000_Lyrics_FindEvent
	ld xiz, xhl			; XIZ = result
	cpw (2294836:24), 1		; end-of-track flag
	jrl z, .Lfo_epilogue
	cp xiz, 0
	jr le, .Lfo_display		; result <= 0 → display handler

	; --- event found: advance, dispatch on its meta type ---
	ld wa, iz
	add (2295916:24), wa; (0x23086C) += IZ
	incw 1, (xsp + 6)		; iteration counter++
	ld wa, (0x230430:24)		; WA = (0x230430): meta event type
	cp wa, 126			; type 0x7E?
	jrl z, .Lfo_type_7E
	cp wa, 88			; type 0x58?
	jrl z, .Lfo_type_58
	cp wa, 5:i3			; type 5?
	jrl nz, .Lfo_end_iter		; other types: ignored

	; --- type 0x05 (lyric): CR / LF end the line ---
	cp (0x230636:24), 0x0d; cp (0x230636), 0x0D
	jr z, .Lfo_type5_newline
	cp (0x230636:24), 0x0a; cp (0x230636), 0x0A
	jrl nz, .Lfo_string_handler	; not newline → string handler

.Lfo_type5_newline:			; 0x28D768
	ldw (0x2304e4:24), 0x0000		; (0x2304E4) = 0: column
	cp (0x2304ee:24), 0x02; cp (0x2304EE), 2
	jr nc, .Lfo_file_delete		; from the third line on: scroll
	inc 1, (2295022:24); (0x2304EE)++
	jrl t, .Lfo_epilogue

	; --- parse error: print the fault message ---
.Lfo_display:				; 0x28D77F
	pushm (xsp + 6)		; push iteration counter
	pushw_da 0xb6, 0x07, 0x23	; pushw (0x2307B6)
	push xiz			; push result
	pushw 46			; width -- high half of HDAE5000_Fmt_Fault_No_Lyrics_loaded_o
	pushw 23538			; format 0x5BF2		; low half of HDAE5000_Fmt_Fault_No_Lyrics_loaded_o
	lda xwa, (0x2306b6:24); &0x2306B6
	push xwa
	call HDAE5000_SPrintf			; call display 0x29ABD8
	lda xsp, (xsp + 16)		; pop 16 bytes
	; Vtable call: notify display
	ld xwa, (HDAE5000_RAM_LyricBoxObj:24); XWA = (0x23A19E)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24); XBC = (0x23A1A2)
	ld xbc, (xbc + WS_RootFnTable)             ; XBC = (XBC + 0x0E0A)
	ld_sril xhl, (xbc + RootFn_SendEvent)             ; XHL = (XBC + 0x0100)
	ld xbc, 30015497		; XBC = 0x01CA0009
	ld xde, 2:i3
	call (xhl)
	jrl t, .Lfo_epilogue

	; --- scroll the window one line, refill the last ---
.Lfo_file_delete:			; 0x28D7BB
	ld bc, (0x230870:24); BC = (0x230870)
	ld wa, 1:i3
	calr HDAE5000_Lyrics_FillLines
	ld xiz, xhl
	ld (0x2304f0:24), 0x00; (0x2304F0) = 0
	cp xiz, 0
	jr le, .Lfo_skip_iz_store1
	ld (0x230870:24), iz; (0x230870) = IZ
.Lfo_skip_iz_store1:			; 0x28D7DA
	cp (xsp + 8), 1		; check display flag
	jr nz, .Lfo_after_vtable1
	; Vtable call: update display
	ld xwa, (HDAE5000_RAM_LyricBoxObj:24)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_RootFnTable)
	ld_sril xhl, (xbc + RootFn_SendEvent)
	ld xbc, 30015496		; 0x01CA0008
	ld xde, 0:i3
	call (xhl)
.Lfo_after_vtable1:			; 0x28D7FD
	jrl t, .Lfo_epilogue

	; --- syllable: append to the line ---
.Lfo_string_handler:			; 0x28D800
	lda xwa, (0x230636:24); &0x230636
	push xwa
	call HDAE5000_StrLen			; strlen 0x29AF71
	inc 4, xsp			; pop 8 bytes
	ld (xsp + 4), hl		; save strlen result
	cp hl, 39			; cp HL, 0x27
	jrl gt, .Lfo_epilogue		; if > 39, exit
	lda xwa, (0x230636:24); &0x230636
	push xwa
	lda xwa, (0x23051e:24)		; &0x23051E: syllable copy
	push xwa
	call HDAE5000_StrCpy			; memcpy 0x29AF45
	inc 0, xsp			; pop stack frame
	; Check cumulative length
	ld wa, (xsp + 4)		; WA = strlen result
	add wa, (2295012:24); WA += (0x2304E4)
	cp wa, 39			; cp WA, 0x27
	jr ule, .Lfo_after_trunc	; if <= 39, no overflow
	; line full: next line (scroll from the third)
	ldw (0x2304e4:24), 0x0000; (0x2304E4) = 0
	cp (0x2304ee:24), 0x02; cp (0x2304EE), 2
	jr nc, .Lfo_file_delete2		; from the third line on: scroll
	inc 1, (2295022:24); (0x2304EE)++
	jr t, .Lfo_after_trunc

.Lfo_file_delete2:			; 0x28D84C
	ld bc, (0x230870:24); BC = (0x230870)
	ld wa, 1:i3
	calr HDAE5000_Lyrics_FillLines
	ld xiz, xhl
	cp xiz, 0
	jr le, .Lfo_skip_iz_store2
	ld (0x230870:24), iz; (0x230870) = IZ
.Lfo_skip_iz_store2:			; 0x28D865
	cp (xsp + 8), 1		; check display flag
	jr nz, .Lfo_after_trunc
	; Vtable call
	ld xwa, (HDAE5000_RAM_LyricBoxObj:24)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_RootFnTable)
	ld_sril xhl, (xbc + RootFn_SendEvent)
	ld xbc, 30015496		; 0x01CA0008
	ld xde, 0:i3
	call (xhl)

	; --- highlight: pixel position of the syllable in the line ---
.Lfo_after_trunc:			; 0x28D888
	ld a, (0x2304ee:24); A = (0x2304EE)
	extz wa
	add wa, 16			; WA += 0x10
	lda xbc, (0x2304d8:24); XBC = &0x2304D8
	ldb_sri a, 0x07, 0xe4, 0xe0	; A = (XBC + WA) — table lookup
	extz wa
	ld bc, wa			; BC = index
	add bc, bc			; BC *= 2
	lda xde, (0x2307b8:24); XDE = &0x2307B8
	ld wa, (0x2304e4:24); WA = (0x2304E4)
	extz xwa
	add xwa, xwa			; XWA *= 2
	ld xhl, 2295822		; XHL = 0x0023080E
	add xhl, xwa			; XHL += XWA*2
	ld wa, (xhl)			; WA = offset table[position]
	add_sriw_rm wa, 0x07, 0xe8, 0xe4	; WA += (XDE + BC)
	ld (0x23087a:24), wa; (0x23087A) = WA
	; (0x23087C) = width entry of the current line
	ld a, (0x2304ee:24); A = (0x2304EE)
	extz wa
	lda xbc, (0x230808:24); XBC = &0x230808
	ldb_sri a, 0x07, 0xe4, 0xe0	; A = (XBC + WA)
	extz wa
	ld (0x23087c:24), wa; (0x23087C) = WA
	; Update position
	ld wa, (xsp + 4)		; WA = strlen
	add (2295012:24), wa; (0x2304E4) += strlen
	ld (0x2304f0:24), 0x01; (0x2304F0) = 1
	; Optional vtable call
	cp (xsp + 8), 1		; check display flag
	jr nz, .Lfo_after_vtable3
	ld xwa, (HDAE5000_RAM_LyricBoxObj:24)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_RootFnTable)
	ld_sril xhl, (xbc + RootFn_SendEvent)
	ld xbc, 30015497		; 0x01CA0009
	ld xde, 0:i3
	call (xhl)

	; --- Check if at end position ---
.Lfo_after_vtable3:			; 0x28D90D
	ld wa, (0x2304e4:24); WA = (0x2304E4)
	cp wa, (2295920:24); cp WA, (0x230870)
	jrl nz, .Lfo_end_iter		; if not at end, continue
	; Check terminator byte
	cp (0x230882:24), 0x0d; cp (0x230882), 0x0D
	jr nz, .Lfo_not_cr
	cp (0x230882:24), 0x0a; cp (0x230882), 0x0A
	jrl z, .Lfo_end_iter		; if CR+LF, end iteration
.Lfo_not_cr:				; 0x28D92B
	ldw (0x2304e4:24), 0x0000		; (0x2304E4) = 0: column
	cp (0x2304ee:24), 0x02; cp (0x2304EE), 2
	jr nc, .Lfo_file_delete3
	inc 1, (2295022:24)
	jrl t, .Lfo_end_iter

.Lfo_file_delete3:			; 0x28D942
	ld bc, (0x230870:24); BC = (0x230870)
	ld wa, 1:i3
	calr HDAE5000_Lyrics_FillLines
	ld xiz, xhl
	cp xiz, 0
	jr le, .Lfo_skip_iz_store3
	ld (0x230870:24), iz; (0x230870) = IZ
.Lfo_skip_iz_store3:			; 0x28D95B
	cp (xsp + 8), 1
	jrl nz, .Lfo_end_iter
	; Vtable call
	ld xwa, (HDAE5000_RAM_LyricBoxObj:24)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_RootFnTable)
	ld_sril xhl, (xbc + RootFn_SendEvent)
	ld xbc, 30015496		; 0x01CA0008
	ld xde, 0:i3
	call (xhl)
	jrl t, .Lfo_end_iter

	; --- type 0x58: time signature ---
.Lfo_type_58:				; 0x28D982
	ld a, (0x230636:24)		; A = numerator
	ld (0x2307a4:24), a; (0x2307A4) = A
	cp (0x230637:24), 0x01		; denominator as a power of two
	jr nz, .Lfo_58_check2
	ld (0x2307a8:24), 0x02; (0x2307A8) = 2
	ldw (0x2307ae:24), 0x0018; (0x2307AE) = 0x0018
.Lfo_58_check2:				; 0x28D9A1
	cp (0x230637:24), 0x02
	jr nz, .Lfo_58_check3
	ld (0x2307a8:24), 0x04
	ldw (0x2307ae:24), 0x000c; 0x000C
.Lfo_58_check3:				; 0x28D9B6
	cp (0x230637:24), 0x03
	jr nz, .Lfo_58_check4
	ld (0x2307a8:24), 0x08
	ldw (0x2307ae:24), 0x0006; 0x0006
.Lfo_58_check4:				; 0x28D9CB
	cp (0x230637:24), 0x04
	jr nz, .Lfo_58_done_checks
	ld (0x2307a8:24), 0x10; 0x10
	ldw (0x2307ae:24), 0x0003; 0x0003
.Lfo_58_done_checks:			; 0x28D9E0
	; print "%i/%i"
	ld a, (0x2307a8:24); A = (0x2307A8)
	extz wa
	pushw wa
	ld a, (0x2307a4:24); A = (0x2307A4)
	extz wa
	pushw wa
	pushw 46			; width -- high half of HDAE5000_Fmt_i_i
	pushw 23600			; format 0x5C30		; low half of HDAE5000_Fmt_i_i
	lda xwa, (0x230790:24); &0x230790
	push xwa
	call HDAE5000_SPrintf			; display 0x29ABD8
	lda xsp, (xsp + 12)		; pop 12 bytes
	; Vtable call
	ld xwa, (HDAE5000_RAM_LyricBoxObj:24)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_RootFnTable)
	ld_sril xhl, (xbc + RootFn_SendEvent)
	ld xbc, 30015497		; 0x01CA0009
	ld xde, 4:i3
	call (xhl)
	jr t, .Lfo_end_iter

	; --- type 0x7E: chord name when the data starts with '0' ---
.Lfo_type_7E:				; 0x28DA22
	ld a, (0x230636:24); A = (0x230636)
	cp a, 48			; cp A, 0x30
	jr nz, .Lfo_end_iter
	; print "Chord : %s" with the rest of the data
	lda xwa, (0x230637:24); &0x230637
	push xwa
	pushw 46			; width -- high half of HDAE5000_Fmt_Chord_s
	pushw 23608			; format 0x5C38		; low half of HDAE5000_Fmt_Chord_s
	lda xwa, (0x2306b6:24); &0x2306B6
	push xwa
	call HDAE5000_SPrintf			; display 0x29ABD8
	lda xsp, (xsp + 12)		; pop 12 bytes
	; Vtable call
	ld xwa, (HDAE5000_RAM_LyricBoxObj:24)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_RootFnTable)
	ld_sril xhl, (xbc + RootFn_SendEvent)
	ld xbc, 30015497		; 0x01CA0009
	ld xde, 2:i3
	call (xhl)

	; --- End of iteration: check loop condition ---
.Lfo_end_iter:				; 0x28DA62
	ld xwa, (0x230444:24)		; XWA = (0x230444): running tick
	cp xwa, (2295908:24); cp XWA, (0x230864)
	jr ugt, .Lfo_epilogue		; if past limit, exit
	cp xiz, 0
	jrl gt, .Lfo_loop		; if XIZ > 0, continue loop

	; --- Epilogue ---
.Lfo_epilogue:				; 0x28DA77
	pop xiz
	inc 6, xsp
	ret

	; ============================================================
	; Reset the lyrics player for a newly loaded file (called by
	; HDAE5000_LyricBoxProc, event 0x01CA0007 and its sibling case):
	; clear the line and position state 0x2304D8-0x2304EF and
	; 0x230438-0x230876, blank the six 40-byte text lines at 0x23A0AA,
	; set (0x230864) = -1 (no position yet) and the info line to "Info",
	; and derive (0x230868) = division / 12 from the TLhd chunk
	; (0x22B43C, big-endian: HDAE5000_SwapBytes16).  The two colour
	; settings pick palette codes 0 -> 0xF9, 1 -> 0x02, 2 -> 0xFC,
	; 3 -> 0x00, 4 -> 0xFB: LyricForeColor (0x229DAD) into (0x23087E),
	; default 0xFC, and LyricBackColor (0x229DAE) into (0x230880),
	; default 0x00 (setting names: the firmware's LyricForeColorCheck /
	; LyricBackColorCheck handlers, which read those bytes).
	; Sets (0x23A19A) = 1.  Returns XHL = 0.
	; ============================================================
HDAE5000_Lyrics_ResetState:	; 0x28DA7B (381 bytes)

	; --- clear the line state ---
	ld (0x23a19a:24), 0x01		; (0x23A19A) = 1
	ldw (0x2304e0:24), 0x0000; (0x2304E0) = 0
	ldw (0x2304e2:24), 0x0000; (0x2304E2) = 0
	ldw (0x2304e4:24), 0x0000; (0x2304E4) = 0
	ld (0x2304ee:24), 0x00; (0x2304EE) = 0
	ldw (0x2304e6:24), 0x0000; (0x2304E6) = 0
	ld (0x2304ef:24), 0x00; (0x2304EF) = 0
	ld xwa, 0:i3
	ld (0x2304d8:24), xwa; (0x2304D8) = 0
	; blank the text lines: 240 bytes at 0x23A0AA
	pushw 240		; 240 bytes
	pushw 32		; fill ' '
	lda xwa, (HDAE5000_RAM_LyricLines:24); XWA = &0x23A0AA
	push xwa
	call HDAE5000_MemFill			; call 0x29AEC7

	; --- clear the event/position state ---
	ldw (0x230870:24), 0x0000; (0x230870) = 0
	ldw (0x23086c:24), 0x0000; (0x23086C) = 0
	ldw (0x230438:24), 0x0000; (0x230438) = 0
	ldw (0x23043a:24), 0x0000; (0x23043A) = 0
	ldw (0x23043c:24), 0x0000; (0x23043C) = 0
	ld xwa, 0:i3
	ld (0x230440:24), xwa; (0x230440) = 0
	ld xwa, 0:i3
	ld (0x230444:24), xwa; (0x230444) = 0
	ld xwa, 0:i3
	ld (0x230448:24), xwa; (0x230448) = 0
	ld xwa, 0:i3
	ld (0x23044c:24), xwa; (0x23044C) = 0
	ld xwa, 0:i3
	ld (0x230450:24), xwa; (0x230450) = 0
	ld xwa, 0:i3
	ld (0x230454:24), xwa; (0x230454) = 0
	ld xwa, 4294967295		; 0xFFFFFFFF
	ld (0x230864:24), xwa; (0x230864) = 0xFFFFFFFF
	ldw (0x230872:24), 0x0000; (0x230872) = 0
	ldw (0x230874:24), 0x0000; (0x230874) = 0
	ld xwa, 0:i3
	ld (0x230876:24), xwa; (0x230876) = 0

	; --- info line = "Info" ---
	pushw 46		; high half of HDAE5000_Str_Info
	pushw 23634		; low half of HDAE5000_Str_Info
	lda xwa, (0x2306b6:24)		; &0x2306B6: info line
	push xwa
	call HDAE5000_StrCpy			; call 0x29AF45
	lda xsp, (xsp + 16)		; pop 16 bytes of args

	ldw (0x2307aa:24), 0x0001; (0x2307AA) = 1
	ldw (0x2307ac:24), 0x0000; (0x2307AC) = 0

	; --- (0x230868) = division / 12 ---
	ld wa, (0x22b43c:24)		; WA = TLhd division (big-endian)
	calr HDAE5000_SwapBytes16
	ld wa, hl			; result WA = HL
	extz xwa			; zero-extend to 32-bit
	ld xbc, 12			; divisor
	call HDAE5000_UDivMod32	; divide
	ld (0x230868:24), xhl		; (0x230868) = division / 12

	; --- LyricForeColor (0x229DAD) -> palette code (0x23087E) ---
	ld a, (HDAE5000_RAM_LyricForeColor:24)		; A = LyricForeColor
	cp a, 4:i3
	jr z, .Lfs_type1_4
	cp a, 3:i3
	jr z, .Lfs_type1_3
	cp a, 2:i3
	jr z, .Lfs_type1_2
	cp a, 1:i3
	jr z, .Lfs_type1_1
	cp a, 0:i3
	jr nz, .Lfs_type1_default
	ld (0x23087e:24), 0xf9; (0x23087E) = 0xF9
	jr t, .Lfs_type1_done
.Lfs_type1_1:				; 0x28DB88
	ld (0x23087e:24), 0x02; (0x23087E) = 0x02
	jr t, .Lfs_type1_done
.Lfs_type1_2:				; 0x28DB90
	ld (0x23087e:24), 0xfc; (0x23087E) = 0xFC
	jr t, .Lfs_type1_done
.Lfs_type1_3:				; 0x28DB98
	ld (0x23087e:24), 0x00; (0x23087E) = 0x00
	jr t, .Lfs_type1_done
.Lfs_type1_4:				; 0x28DBA0
	ld (0x23087e:24), 0xfb; (0x23087E) = 0xFB
	jr t, .Lfs_type1_done
.Lfs_type1_default:			; 0x28DBA8
	ld (0x23087e:24), 0xfc; (0x23087E) = 0xFC
.Lfs_type1_done:			; 0x28DBAE

	; --- LyricBackColor (0x229DAE) -> palette code (0x230880) ---
	ld a, (HDAE5000_RAM_LyricBackColor:24)		; A = LyricBackColor
	cp a, 4:i3
	jr z, .Lfs_type2_4
	cp a, 3:i3
	jr z, .Lfs_type2_3
	cp a, 2:i3
	jr z, .Lfs_type2_2
	cp a, 1:i3
	jr z, .Lfs_type2_1
	cp a, 0:i3
	jr nz, .Lfs_type2_default
	ld (0x230880:24), 0xf9; (0x230880) = 0xF9
	jr t, .Lfs_type2_done
.Lfs_type2_1:				; 0x28DBCF
	ld (0x230880:24), 0x02; (0x230880) = 0x02
	jr t, .Lfs_type2_done
.Lfs_type2_2:				; 0x28DBD7
	ld (0x230880:24), 0xfc; (0x230880) = 0xFC
	jr t, .Lfs_type2_done
.Lfs_type2_3:				; 0x28DBDF
	ld (0x230880:24), 0x00; (0x230880) = 0x00
	jr t, .Lfs_type2_done
.Lfs_type2_4:				; 0x28DBE7
	ld (0x230880:24), 0xfb; (0x230880) = 0xFB
	jr t, .Lfs_type2_done
.Lfs_type2_default:			; 0x28DBEF
	ld (0x230880:24), 0x00; (0x230880) = 0x00
.Lfs_type2_done:			; 0x28DBF5
	ld xhl, 0:i3		; return 0
	ret

	; ============================================================
	; Read the song information events of the loaded lyric file
	; (HDAE5000_Lyrics_FindEvent from the start of the track):
	;   meta 0x02 (copyright): up to 50 chars -> 0x230736, else
	;        "No Copyright Info";
	;   meta 0x03 (track name = song title): up to 40 chars ->
	;        0x230768, else "No Song Title" -- copied, as the code
	;        has it, to 0x230736, the copyright line;
	;   meta 0x58 (time signature nn dd): numerator -> (0x2307A4)
	;        and (0x2307A6), 2^dd -> (0x2307A8) for dd = 1..4 (2, 4,
	;        8, 16) with 24 / 12 / 6 / 3 -> (0x2307AE)/(0x2307B0)
	;        (i.e. 48 / 2^dd), else 4/4 and 12; printed with
	;        "%i/%i" into 0x230790.
	; Then SendEvent(lyric box (0x23A19E), 0x01CA0005, 0), reset the
	; parse state and position on the first event.  Returns 0.
	; ============================================================
HDAE5000_Lyrics_ReadSongInfo:	; 0x28DBF8 (564 bytes)

	; --- meta 0x02 (copyright) -> 0x230736, <= 50 chars ---
	ld xwa, 0:i3
	push xwa
	ld wa, 2:i3
	ld bc, 2:i3
	ldw de, 65534			; DE = 0xFFFE
	calr HDAE5000_Lyrics_FindEvent
	cp xhl, 0
	jr le, .Lfl_default1		; if result <= 0, use default

	; found: copy, at most 50
	cpw (2294838:24), 50; cp (0x230436), 0x32
	jr c, .Lfl_short1
	pushw 50
	lda xwa, (0x230636:24); &0x230636
	push xwa
	lda xwa, (0x230736:24); &0x230736
	push xwa
	call HDAE5000_StrNCpy			; call 0x29AFF0 (memcpy)
	lda xsp, (xsp + 10)		; pop 10 bytes
	ld (0x230767:24), 0x00; (0x230767) = null terminator
	jr t, .Lfl_block2
.Lfl_short1:				; 0x28DC34
	; Copy actual length
	ld wa, (0x230436:24); WA = (0x230436)
	pushw wa
	lda xwa, (0x230636:24); &0x230636
	push xwa
	lda xwa, (0x230736:24); &0x230736
	push xwa
	call HDAE5000_StrNCpy			; call 0x29AFF0 (memcpy)
	lda xsp, (xsp + 10)		; pop 10 bytes
	; Null-terminate at actual length
	ld wa, (0x230436:24); WA = (0x230436)
	extz xwa
	ld xbc, 2295606			; XBC = 0x00230736
	add xbc, xwa
	ld (xbc), 0			; *(base + len) = 0
	jr t, .Lfl_block2
.Lfl_default1:				; 0x28DC60
	; not found: "No Copyright Info"
	pushw 46		; high half of HDAE5000_Str_NoCopyrightInfo
	pushw 23670		; low half of HDAE5000_Str_NoCopyrightInfo
	lda xwa, (0x230736:24); &0x230736
	push xwa
	call HDAE5000_StrCpy			; call 0x29AF45
	inc 0, xsp			; pop stack frame

.Lfl_block2:				; 0x28DC72
	; --- meta 0x03 (track name) -> 0x230768, <= 40 chars ---
	ld xwa, 0:i3
	push xwa
	ld wa, 3:i3
	ld bc, 2:i3
	ldw de, 65534			; DE = 0xFFFE
	calr HDAE5000_Lyrics_FindEvent
	cp xhl, 0
	jr le, .Lfl_default2		; if result <= 0, use default

	; found: copy, at most 40
	cpw (2294838:24), 40; cp (0x230436), 0x28
	jr c, .Lfl_short2
	; Truncate at 40
	pushw 40
	lda xwa, (0x230636:24); &0x230636
	push xwa
	lda xwa, (0x230768:24); &0x230768
	push xwa
	call HDAE5000_StrNCpy			; call 0x29AFF0
	lda xsp, (xsp + 10)
	ld (0x23078f:24), 0x00; (0x23078F) = null terminator
	jr t, .Lfl_block3
.Lfl_short2:				; 0x28DCAE
	; Copy actual length
	ld wa, (0x230436:24); WA = (0x230436)
	pushw wa
	lda xwa, (0x230636:24); &0x230636
	push xwa
	lda xwa, (0x230768:24); &0x230768
	push xwa
	call HDAE5000_StrNCpy			; call 0x29AFF0
	lda xsp, (xsp + 10)
	ld wa, (0x230436:24); WA = (0x230436)
	extz xwa
	ld xbc, 2295656			; XBC = 0x00230768
	add xbc, xwa
	ld (xbc), 0			; *(base + len) = 0
	jr t, .Lfl_block3
.Lfl_default2:				; 0x28DCDA
	; not found: "No Song Title" (into 0x230736)
	pushw 46		; high half of HDAE5000_Str_NoSongTitle
	pushw 23688		; low half of HDAE5000_Str_NoSongTitle
	lda xwa, (0x230736:24); &0x230736
	push xwa
	call HDAE5000_StrCpy			; call 0x29AF45
	inc 0, xsp			; pop stack frame

.Lfl_block3:				; 0x28DCEC
	; --- meta 0x58 (time signature) ---
	ld xwa, 0:i3
	push xwa
	ldw wa, 88			; WA = 0x58
	ld bc, 2:i3
	ldw de, 65534			; DE = 0xFFFE
	calr HDAE5000_Lyrics_FindEvent
	cp xhl, 0
	jrl le, .Lfl_audio_default		; not found: 4/4

	; found: nn = numerator, dd = log2(denominator)
	ld a, (0x230636:24)		; numerator
	ld (0x2307a4:24), a; (0x2307A4) = A
	ld (0x2307a6:24), a; (0x2307A6) = A

	; denominator 2^dd -> (0x2307A8), 48 / 2^dd -> (0x2307AE)/(0x2307B0):
	cp (0x230637:24), 0x01		; dd = 1: /2
	jr nz, .Lfl_audio_ch2
	ld (0x2307a8:24), 0x02
	ldw (0x2307ae:24), 0x0018
	ldw (0x2307b0:24), 0x0018
.Lfl_audio_ch2:				; 0x28DD2E
	cp (0x230637:24), 0x02		; dd = 2: /4
	jr nz, .Lfl_audio_ch3
	ld (0x2307a8:24), 0x04
	ldw (0x2307ae:24), 0x000c
	ldw (0x2307b0:24), 0x000c
.Lfl_audio_ch3:				; 0x28DD4A
	cp (0x230637:24), 0x03		; dd = 3: /8
	jr nz, .Lfl_audio_ch4
	ld (0x2307a8:24), 0x08
	ldw (0x2307ae:24), 0x0006
	ldw (0x2307b0:24), 0x0006
.Lfl_audio_ch4:				; 0x28DD66
	cp (0x230637:24), 0x04		; dd = 4: /16
	jr nz, .Lfl_audio_done
	ld (0x2307a8:24), 0x10
	ldw (0x2307ae:24), 0x0003
	ldw (0x2307b0:24), 0x0003
	jr t, .Lfl_audio_done
.Lfl_audio_default:			; 0x28DD84
	; not found: 4/4, 12
	ld (0x2307a6:24), 0x04; (0x2307A6) = 4
	ld (0x2307a4:24), 0x04; (0x2307A4) = 4
	ld (0x2307a8:24), 0x04; (0x2307A8) = 4
	ldw (0x2307ae:24), 0x000c; (0x2307AE) = 12
	ldw (0x2307b0:24), 0x000c; (0x2307B0) = 12

.Lfl_audio_done:			; 0x28DDA4
	; --- print "%i/%i" into 0x230790 ---
	ld a, (0x2307a8:24); A = (0x2307A8)
	extz wa
	pushw wa
	ld a, (0x2307a4:24); A = (0x2307A4)
	extz wa
	pushw wa
	pushw 46			; 0x2E -- high half of HDAE5000_Fmt_i_i_File_Load
	pushw 23702			; 0x5C96		; low half of HDAE5000_Fmt_i_i_File_Load
	lda xwa, (0x230790:24); &0x230790
	push xwa
	call HDAE5000_SPrintf			; call 0x29ABD8
	lda xsp, (xsp + 12)		; pop 12 bytes

	; --- SendEvent(lyric box, 0x01CA0005, 0) ---
	ld xwa, (HDAE5000_RAM_LyricBoxObj:24); XWA = (0x23A19E)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24); XBC = (0x23A1A2)
	ld xbc, (xbc + WS_RootFnTable)
	ld_sril xhl, (xbc + RootFn_SendEvent)
	ld xbc, 30015493		; XBC = 0x01CA0005
	ld xde, 0:i3
	call (xhl)

	; --- reset the parse state ---
	ldw (0x230430:24), 0x00ff; (0x230430) = 0x00FF
	ldw (0x230432:24), 0x0000; (0x230432) = 0
	ldw (0x230434:24), 0x0000; (0x230434) = 0
	ldw (0x230436:24), 0x0000; (0x230436) = 0
	ld (0x2304f0:24), 0x00; (0x2304F0) = 0
	ldw (0x23086e:24), 0x0000; (0x23086E) = 0
	ld xwa, 0:i3
	ld (0x230440:24), xwa; (0x230440) = 0

	; --- position on the first event (0x7C = any type) ---
	ld xwa, 0:i3
	push xwa
	ldw wa, 124			; WA = 0x7C
	ld bc, 2:i3
	ldw de, 65534			; DE = 0xFFFE
	calr HDAE5000_Lyrics_FindEvent
	ld xwa, 0:i3
	ld (0x230440:24), xwa; (0x230440) = 0
	ld xhl, 0:i3		; return 0
	ret

	; ============================================================
	; Fill the lyric text lines: six lines of up to 39 chars, 40
	; bytes apart at 0x23A0AA, their lengths at 0x2304E8+line.
	; A = 1: first scroll lines 1..5 up into 0..4 (line[i] =
	; line[i+1], the copy runs 0x23A0D2+40i -> 0x23A0AA+40i) and fill
	; only line 5; A = 0: fill lines 0..5.  From event position BC
	; it takes lyric events (meta 0x05, HDAE5000_Lyrics_FindEvent)
	; and appends each to the line while it fits; CR (0x0D) ends the
	; line, LF (0x0A) gives an empty line (HDAE5000_Str_Empty_File_
	; Delete).  The running tick and the target (0x230440/0x230444)
	; are saved and restored.  Returns XHL = position after the
	; last event used.  Callers: HDAE5000_Lyrics_PlayToPosition
	; (scroll) and HDAE5000_LyricBoxProc (initial fill).
	; ============================================================
HDAE5000_Lyrics_FillLines:	; 0x28DE2C (579 bytes)

	; --- Prologue: allocate stack frame, save registers ---
	lda xsp, (xsp - 58)		; allocate 58 bytes of locals
	pushw iz			; save IZ
	ld (xsp + 58), bc		; save the event position
	ld xbc, (0x230440:24); XBC = (0x230440)
	ld (xsp + 10), xbc		; save to local[0x0A]
	ld xbc, (0x230444:24); XBC = (0x230444)
	ld (xsp + 14), xbc		; save to local[0x0E]

	; --- A == 1: scroll lines 1..5 up one line ---
	cp a, 1:i3
	jr nz, .Lfd_else

	ldw (xsp + 2), 0		; slot = 0
	cpw (xsp + 2), 5		; while slot < 5
	jr ge, .Lfd_copy_done
.Lfd_copy_loop:				; 0x28DE53
	; second argument: line[slot+1] = 0x23A0D2 + 40*slot
	ld wa, (xsp + 2)
	muls wa, 40
	lda xbc, (0x23a0d2:24); XBC = 0x23A0D2
	exts xwa
	add xwa, xbc
	push xwa
	; first argument: line[slot] = 0x23A0AA + 40*slot
	ld wa, (xsp + 6)		; slot (offset by push)
	muls wa, 40
	lda xbc, (HDAE5000_RAM_LyricLines:24); XBC = 0x23A0AA
	exts xwa
	add xwa, xbc
	push xwa
	call HDAE5000_StrCpy			; call 0x29AF45 (memcpy)
	; and its new length
	ld wa, (xsp + 10)		; slot (offset by 2 pushes)
	muls wa, 40
	lda xbc, (HDAE5000_RAM_LyricLines:24); XBC = 0x23A0AA
	exts xwa
	add xwa, xbc
	push xwa
	call HDAE5000_StrLen			; call 0x29AF71 (strlen)
	lda xsp, (xsp + 12)		; pop 12 bytes
	; Store length at 0x2304D8 + slot + 16
	ld wa, (xsp + 2)		; slot
	add wa, 16
	lda xbc, (0x2304d8:24); XBC = 0x2304D8
	stb_dri l, 0x07, 0xe4, 0xe0	; ld (XBC+WA), L
	incw 1, (xsp + 2)		; slot++
	cpw (xsp + 2), 5
	jr lt, .Lfd_copy_loop
.Lfd_copy_done:				; 0x28DEAC
	ld c, 5:opc		; C = 5: fill only the last line
	jr t, .Lfd_setup_loop
.Lfd_else:				; 0x28DEB0
	ld c, 0:opc			; C = 0

.Lfd_setup_loop:			; 0x28DEB2
	; --- fill lines C..5 ---
	ld wa, (xsp + 58)		; WA = saved BC param
	ld (xsp + 4), wa		; local[4] = event position
	ld a, c				; A = count
	extz wa
	ld (xsp + 2), wa		; local[2] = line
	cpw (xsp + 2), 6		; if count >= 6
	jrl ge, .Lfd_epilogue		;   skip to epilogue

.Lfd_outer_loop:			; 0x28DEC7
	; --- next lyric event (meta 0x05) ---
	ld (xsp + 18), 0		; line being built at local[0x12] = ""
	ld wa, (xsp + 4)		; WA = entry index
	extz xwa
	push xwa
	ld wa, 5:i3		; meta type 0x05: lyric
	ld bc, 2:i3
	ldw de, 65534			; DE = 0xFFFE
	calr HDAE5000_Lyrics_FindEvent
	ld (xsp + 6), xhl		; local[0x06] = result
	cpw (2294836:24), 1; if (0x230434) == 1
	jrl z, .Lfd_tail_copy		; end of track: store the line and stop
	ld xwa, (xsp + 6)		; XWA = result
	cp xwa, 0
	jrl le, .Lfd_no_entry

	; CR: end of line
	cp (0x230636:24), 0x0d; cp (0x230636), 0x0D
	jr nz, .Lfd_try_0a		; if != 0x0D, try next type

	; --- CR: store the line built so far ---
	ld xwa, (xsp + 6)		; result
	ld (xsp + 4), wa		; save low word
	lda xwa, (xsp + 18)		; XWA = &local[0x12]
	push xwa
	ld wa, (xsp + 6)		; slot (offset by push)
	muls wa, 40
	lda xbc, (HDAE5000_RAM_LyricLines:24); XBC = 0x23A0AA
	exts xwa
	add xwa, xbc
	push xwa
	call HDAE5000_StrCpy			; memcpy
	inc 0, xsp			; pop stack frame

.Lfd_strlen_store:			; 0x28DF1D
	; store the line length, next line
	ld wa, (xsp + 2)		; slot
	muls wa, 40
	lda xbc, (HDAE5000_RAM_LyricLines:24); XBC = 0x23A0AA
	exts xwa
	add xwa, xbc
	push xwa
	call HDAE5000_StrLen			; strlen
	inc 4, xsp			; pop 4 bytes
	ld wa, (xsp + 2)		; slot
	add wa, 16
	lda xbc, (0x2304d8:24); XBC = 0x2304D8
	stb_dri l, 0x07, 0xe4, 0xe0	; ld (XBC+WA), L
	incw 1, (xsp + 2)		; slot++
	cpw (xsp + 2), 6		; if slot < 6
	jrl lt, .Lfd_outer_loop		;   continue outer loop

.Lfd_epilogue:				; 0x28DF50
	; --- Restore state and return ---
	ld xwa, (xsp + 10)
	ld (0x230440:24), xwa; restore (0x230440)
	ld xwa, (xsp + 14)
	ld (0x230444:24), xwa; restore (0x230444)
	ld hl, (xsp + 4)		; HL = local[0x04]
	extz xhl			; XHL = zero-extend(HL)
	popw iz				; restore IZ
	lda xsp, (xsp + 58)		; deallocate stack frame
	ret

.Lfd_try_0a:				; 0x28DF6A
	; --- LF: an empty line ---
	cp (0x230636:24), 0x0a; cp (0x230636), 0x0A
	jr nz, .Lfd_other_type
	ld xwa, (xsp + 6)		; result
	ld (xsp + 4), wa		; save
	pushw 46			; max = 0x2E -- high half of HDAE5000_Str_Empty_File_Delete
	pushw 23710			; src = 0x5C9E		; low half of HDAE5000_Str_Empty_File_Delete
	ld wa, (xsp + 6)		; slot (offset)
	muls wa, 40
	lda xbc, (HDAE5000_RAM_LyricLines:24); XBC = 0x23A0AA
	exts xwa
	add xwa, xbc
	push xwa
	call HDAE5000_StrCpy			; memcpy
	inc 0, xsp			; pop frame
	jr t, .Lfd_strlen_store		; goto strlen/store

.Lfd_other_type:			; 0x28DF97
	; --- syllable: append if the line stays <= 39 chars ---
	lda xwa, (0x230636:24); XWA = &0x230636
	push xwa
	call HDAE5000_StrLen			; strlen(0x230636)
	inc 4, xsp			; pop 4 bytes
	cp hl, 39			; if strlen <= 39
	jr ule, .Lfd_short_string	;   handle short string
	; syllable alone longer than a line: skip it
	ld xwa, (xsp + 6)		; result
	ld (xsp + 4), wa
	jrl t, .Lfd_outer_loop

.Lfd_short_string:			; 0x28DFB2
	lda xwa, (xsp + 18)		; &local[0x12]
	push xwa
	call HDAE5000_StrLen			; strlen(&local)
	ld iz, hl			; IZ = local strlen
	lda xwa, (0x230636:24); &0x230636
	push xwa
	call HDAE5000_StrLen			; strlen(0x230636)
	inc 0, xsp			; pop frame
	add hl, iz			; HL = combined length
	cp hl, 39			; if combined > 39
	jr ugt, .Lfd_tail_copy		; does not fit: store the line
	lda xwa, (0x230636:24); &0x230636
	push xwa
	lda xwa, (xsp + 22)		; &local[0x12] (offset by push)
	push xwa
	call HDAE5000_StrCat			; call 0x29AF0B (strcat)
	inc 0, xsp			; pop frame
	ld xwa, (xsp + 6)		; result
	ld (xsp + 4), wa		; save

.Lfd_no_entry:				; 0x28DFE6
	; --- no event (0): empty line ---
	ld xwa, (xsp + 6)		; XWA = result
	or xwa, xwa			; test zero
	jr nz, .Lfd_check_positive	; if nonzero, check further
	pushw 46			; max = 0x2E -- high half of HDAE5000_Str_Empty_File_Delete_2
	pushw 23712			; src = 0x5CA0		; low half of HDAE5000_Str_Empty_File_Delete_2
	ld wa, (xsp + 6)		; slot (offset)
	muls wa, 40
	lda xbc, (HDAE5000_RAM_LyricLines:24); XBC = 0x23A0AA
	exts xwa
	add xwa, xbc
	push xwa
	call HDAE5000_StrCpy			; memcpy
	inc 0, xsp			; pop frame
	jrl t, .Lfd_strlen_store	; goto strlen/store

.Lfd_check_positive:			; 0x28E00D
	ld xwa, (xsp + 6)		; XWA = result
	cp xwa, 0
	jrl gt, .Lfd_outer_loop + 4	; if result > 0, continue (0x28DECB)

.Lfd_tail_copy:				; 0x28E019
	; --- store the built line ---
	lda xwa, (xsp + 18)		; &local[0x12]
	push xwa
	ld wa, (xsp + 6)		; slot (offset)
	muls wa, 40
	lda xbc, (HDAE5000_RAM_LyricLines:24); XBC = 0x23A0AA
	exts xwa
	add xwa, xbc
	push xwa
	call HDAE5000_StrCpy			; memcpy
	ld wa, (xsp + 10)		; slot (offset by 2 pushes)
	muls wa, 40
	lda xbc, (HDAE5000_RAM_LyricLines:24); XBC = 0x23A0AA
	exts xwa
	add xwa, xbc
	push xwa
	call HDAE5000_StrLen			; strlen
	lda xsp, (xsp + 12)		; pop 12 bytes
	ld wa, (xsp + 2)		; slot
	add wa, 16
	lda xbc, (0x2304d8:24); XBC = 0x2304D8
	stb_dri l, 0x07, 0xe4, 0xe0	; ld (XBC+WA), L
	cpw (2294836:24), 1; if (0x230434) != 1
	jrl nz, .Lfd_strlen_store	;   goto strlen/store
	ldw (0x230434:24), 0x0000; (0x230434) = 0
	jrl t, .Lfd_epilogue		; done

	; ============================================================
	; Find a meta event in the lyric track.  A = meta type wanted,
	; 0x7C meaning "the event at the position, whatever its type";
	; C = HDAE5000_Lyrics_ParseEvent flags (bit 1: copy the data to
	; 0x230636); DE = start: >= 0 skip that many events from the
	; track start, -2 start at the position passed on the stack
	; (retd 4), -1 fail.  Walks the events with ParseEvent until the
	; type matches (0x230430) or the track ends.
	; Output: XHL = position after the event found (for 0x7C: its
	; size), -1 when none, 0 for DE < -2.
	; Callers: HDAE5000_Lyrics_PlayToPosition, _ReadSongInfo,
	; _FillLines.
	; ============================================================
HDAE5000_Lyrics_FindEvent:	; 0x28E06F (280 bytes)
	dec 0, xsp			; allocate 8 bytes
	pushw iz
	ld (xsp + 4), de		; DE: events to skip / -1 / -2
	ld (xsp + 6), c		; C: ParseEvent flags
	ld (xsp + 8), a		; A: meta type (0x7C = any)
	cpw (xsp + 4), 0x0000
	jrl lt, .Lfr_negative		; DE < 0
	; DE >= 0: skip DE events from the track start
	ldw (xsp + 2), 0x0000		; position = 0
	ld xwa, 0:i3
	ld (0x230440:24), xwa; clear 0x230440
	ld iz, 0:i3
	cp iz, (xsp + 4)
	jr ge, .Lfr_loop_done
.Lfr_loop_start:
	ld bc, (xsp + 2)		; load counter
	ld wa, 0:i3
	calr HDAE5000_Lyrics_ParseEvent
	ld wa, hl
	add (xsp + 2), wa		; accumulate
	cp hl, 0:i3
	jr nz, .Lfr_loop_next
	ld xhl, 0xFFFFFFFF		; parse error
	jrl .Lfr_exit
.Lfr_loop_next:
	inc 1, iz
	cp iz, (xsp + 4)
	jr lt, .Lfr_loop_start
.Lfr_loop_done:
	cp (xsp + 8), 0x7c		; 0x7C = any type?
	jr nz, .Lfr_search_pos
	; 0x7C: parse the event at the position
	ld a, (xsp + 6)
	extz wa
	ld bc, (xsp + 2)
	calr HDAE5000_Lyrics_ParseEvent
	ld wa, hl
	cp wa, 0:i3
	jr z, .Lfr_7c_error
	ld wa, (xsp + 2)
	extz xwa
	ld bc, hl
	extz xbc
	ld xhl, xbc
	add xhl, xwa		; XHL = position after it
	jrl .Lfr_exit
.Lfr_7c_error:
	ld xhl, 0xFFFFFFFF
	jrl .Lfr_exit
.Lfr_search_pos:
	; other types: parse until (0x230430) matches
	ld a, (xsp + 6)
	extz wa
	ld bc, (xsp + 2)
	calr HDAE5000_Lyrics_ParseEvent
	ld wa, hl
	add (xsp + 2), wa
	cp hl, 0:i3
	jr z, .Lfr_search_pos_check
	ld a, (xsp + 8)
	extz wa
	cp wa, (2294832:24)		; the type wanted?
	jr nz, .Lfr_search_pos		; no: next event
.Lfr_search_pos_check:
	cp hl, 0:i3
	jr z, .Lfr_search_pos_err
	ld hl, (xsp + 2)
	extz xhl
	jr t, .Lfr_exit
.Lfr_search_pos_err:
	ld xhl, 0xFFFFFFFF
	jr t, .Lfr_exit
.Lfr_negative:
	cpw (xsp + 4), 0xFFFF	; DE == -1?
	jr nz, .Lfr_check_fffe
	ld xhl, 0xFFFFFFFF
	jr t, .Lfr_exit
.Lfr_check_fffe:
	cpw (xsp + 4), 0xFFFE	; DE == -2?
	jr nz, .Lfr_return_zero
	cp (xsp + 8), 0x7c
	jr nz, .Lfr_fffe_search
	; DE = -2, 0x7C: the event at the stacked position
	ld a, (xsp + 6)
	ld e, a
	extz de
	ld xwa, (xsp + 14)		; stacked position
	ld bc, wa
	ld wa, de
	calr HDAE5000_Lyrics_ParseEvent
	extz xhl
	jr t, .Lfr_exit
.Lfr_fffe_search:
	; DE = -2: search from the stacked position
	ld xwa, (xsp + 14)
	ld (xsp + 2), wa		; position
.Lfr_fffe_loop:
	ld a, (xsp + 6)
	extz wa
	ld bc, (xsp + 2)
	calr HDAE5000_Lyrics_ParseEvent
	ld wa, hl
	add (xsp + 2), wa
	cp hl, 0:i3
	jr z, .Lfr_fffe_check
	ld a, (xsp + 8)
	extz wa
	cp wa, (2294832:24)		; the type wanted?
	jr nz, .Lfr_fffe_loop
.Lfr_fffe_check:
	cp hl, 0:i3
	jr z, .Lfr_fffe_error
	ld hl, (xsp + 2)
	extz xhl
	jr t, .Lfr_exit
.Lfr_fffe_error:
	ld xhl, 0xFFFFFFFF
	jr t, .Lfr_exit
.Lfr_return_zero:
	ld xhl, 0:i3
.Lfr_exit:
	popw iz
	inc 0, xsp			; deallocate 8 bytes
	retd 0x0004

	; ============================================================
	; Parse one event of the lyric track at position BC (offset from
	; the first event, buffer 0x22B430 + 22 + BC):
	;   <VarLen delta>  -> (0x230860); running tick (0x230440) += it
	;   0xFF             (anything else: error 0xFFFD)
	;   <type>           -> (0x230430); 0x2F (end of track) sets
	;                      (0x230434) = 1 and returns 0
	;   <VarLen length>  -> (0x230436)
	;   <data>           flag bit 0: copied to 0x230458 (<= 127) and the
	;                      previous position/tick kept (0x23043C, 0x230448,
	;                      0x230454); bit 1: copied to 0x230636, NUL-ended
	; The next event's delta is read too: (0x230444) = running tick +
	; that delta (the tick of the next event).
	; Output: HL = event size, or 0 with an error code in (0x2307B6):
	;   0xFFFF position + 4 > 20457 (outside the 0x5000-byte buffer)
	;   0xFFFE / 0xFFFC / 0xFFFA  delta / length / next delta VarLen
	;          longer than 4 bytes (HDAE5000_Lyrics_ReadVarLen = -1)
	;   0xFFFD no 0xFF status byte
	;   0xFFFB event runs past 20457
	; QIZH holds flag bit 0.
	; ============================================================
HDAE5000_Lyrics_ParseEvent:	; 0x28E187 (772 bytes)

	; --- Prologue ---
	dec 4, xsp			; allocate 8 bytes
	push xiz
	ld (xsp + 4), bc		; save the event position
	ld (xsp + 6), a		; save the flags
	ldib_erp 0xfb, 0		; QIZH = 0: flag bit 0 clear

	; --- position + 4 must stay inside the buffer ---
	ld wa, (xsp + 4)		; WA = event position
	inc 4, wa		; WA += 4
	cp wa, 20457			; start+4 within addressable range?
	jr ule, .Lff_start
	ldw (0x2307b6:24), 0xffff; (0x2307B6) = 0xFFFF — error
	ld hl, 0:i3
	jrl t, .Lff_epilogue

.Lff_start:				; 0x28E1AA
	ld iz, (xsp + 4)		; IZ = event position
	ld a, (xsp + 6)		; A = flags
	and a, 1			; isolate bit 0
	cp a, 1:i3
	jr nz, .Lff_skip_backup_flag
	ldib_erp 0xfb, 1		; QIZH = 1: flag bit 0 set

.Lff_skip_backup_flag:			; 0x28E1BA
	cpib_erp 0xfb, 1		; check QIZH == 1
	jr nz, .Lff_skip_backup_save
	; Save current position before overwriting
	ld wa, (0x230438:24); WA = (0x230438)
	ld (0x23043c:24), wa; (0x23043C) = WA
	ld wa, (xsp + 4)
	ld (0x230438:24), wa		; (0x230438) = event position

.Lff_skip_backup_save:			; 0x28E1D1
	ld wa, iz
	calr HDAE5000_Lyrics_ReadVarLen
	ld (0x230860:24), xhl		; (0x230860) = delta time
	cp xhl, 4294967295		; == 0xFFFFFFFF?
	jr nz, .Lff_after_space_check
	ldw (0x2307b6:24), 0xfffe; (0x2307B6) = 0xFFFE — error
	ld hl, 0:i3
	jrl t, .Lff_epilogue

.Lff_after_space_check:			; 0x28E1EF
	cpib_erp 0xfb, 1
	jr nz, .Lff_skip_backup_copy
	; flag bit 0: keep the previous tick values
	ld xwa, (0x230440:24); XWA = (0x230440)
	ld (0x230448:24), xwa; (0x230448) = XWA
	ld xwa, (0x23044c:24); XWA = (0x23044C)
	ld (0x230454:24), xwa; (0x230454) = XWA
	ld xwa, (0x230860:24); XWA = (0x230860)
	ld (0x23044c:24), xwa; (0x23044C) = XWA

.Lff_skip_backup_copy:			; 0x28E212
	ld xwa, (0x230860:24); XWA = (0x230860)
	add (0x230440:24), xwa                ; (0x230440) += XWA
	add iz, (2295902:24); IZ += (0x23085E)
	ld wa, iz
	inc 1, iz			; IZ++
	; status byte at buffer[pos + 22]
	extz xwa
	add xwa, 22		; +22: past the TLhd and TLtr chunk headers
	ld xbc, HDAE5000_RAM_LyricBuffer		; XBC = lyric buffer 0x22B430
	add xbc, xwa
	cp (xbc), 255		; 0xFF: a meta event?
	jr z, .Lff_byte2_read		; yes: read its type
	ldw (0x2307b6:24), 0xfffd		; error 0xFFFD: not a meta event
	ld hl, 0:i3
	jrl t, .Lff_epilogue

.Lff_byte2_read:			; 0x28E245
	ld wa, iz
	inc 1, iz			; IZ++
	extz xwa
	add xwa, 22
	ld xbc, HDAE5000_RAM_LyricBuffer		; lyric buffer
	add xbc, xwa
	ld a, (xbc)		; A = meta event type
	extz wa
	ld (0x230430:24), wa		; (0x230430) = meta event type
	cpw (2294832:24), 47		; type 0x2F: end of track?
	jr nz, .Lff_after_type_check
	; end of track: set the end flag, return 0
	ldw (0x230434:24), 0x0001		; (0x230434) = 1: end of track
	ld xwa, 4294967295		; 0xFFFFFFFF
	ld (0x230860:24), xwa; (0x230860) = -1
	ld hl, 0:i3
	jrl t, .Lff_epilogue

.Lff_after_type_check:			; 0x28E280
	ld wa, iz
	calr HDAE5000_Lyrics_ReadVarLen
	ld xwa, xhl
	cp xwa, 4294967295		; == 0xFFFFFFFF?
	jr nz, .Lff_after_format_calc
	ldw (0x2307b6:24), 0xfffc; (0x2307B6) = 0xFFFC — error
	ld hl, 0:i3
	jrl t, .Lff_epilogue

.Lff_after_format_calc:			; 0x28E29B
	add iz, (2295902:24); IZ += (0x23085E)
	ld (0x230436:24), hl		; (0x230436) = data length
	; the event must end inside the buffer
	ld wa, iz
	add wa, (2294838:24); WA += (0x230436)
	cp wa, 20457			; cp WA, 0x4FE9
	jr ule, .Lff_after_limit2
	ldw (0x2307b6:24), 0xfffb; (0x2307B6) = 0xFFFB — error
	ld hl, 0:i3
	jrl t, .Lff_epilogue

.Lff_after_limit2:			; 0x28E2BE
	ld wa, iz
	add wa, (2294838:24); WA += (0x230436)
	ld (0x23043a:24), wa; (0x23043A) = WA — end position
	; the next event's delta time
	ld wa, iz
	add wa, (2294838:24); WA += (0x230436)
	calr HDAE5000_Lyrics_ReadVarLen
	ld (0x230450:24), xhl; (0x230450) = XHL
	cp xhl, 4294967295
	jr nz, .Lff_after_error3
	ldw (0x2307b6:24), 0xfffa; (0x2307B6) = 0xFFFA — error
	ld hl, 0:i3
	jrl t, .Lff_epilogue

.Lff_after_error3:			; 0x28E2ED
	; byte at next event + its delta size + 4 -> (0x230882)
	ld wa, iz
	add wa, (2294838:24); WA += (0x230436)
	add wa, (2295902:24); WA += (0x23085E)
	inc 4, wa			; WA += 4
	extz xwa
	add xwa, 22
	ld xbc, HDAE5000_RAM_LyricBuffer
	add xbc, xwa
	ld a, (xbc)
	ld (0x230882:24), a; (0x230882) = A

	; --- flag bit 0: data -> 0x230458 (<= 127) ---
	cpib_erp 0xfb, 1
	jr nz, .Lff_after_copy1
	cpw (2294838:24), 127; cp (0x230436), 0x7F
	jr ugt, .Lff_long_copy1	; if > 127, truncate
	; Short copy: actual length
	ld wa, (0x230436:24); WA = (0x230436)
	extz xwa
	pushw wa			; push length
	ld wa, iz
	extz xwa
	add xwa, 22
	ld xbc, HDAE5000_RAM_LyricBuffer
	add xbc, xwa
	push xbc			; push source
	lda xwa, (0x230458:24); &0x230458 — dest
	push xwa
	call HDAE5000_MemCopy			; strcpy_len 0x29AE9F
	lda xsp, (xsp + 10)		; pop 10 bytes
	; Null-terminate
	ld wa, (0x230436:24); WA = length
	extz xwa
	add xwa, 40			; + 0x28
	ld xbc, 2294832			; XBC = 0x00230430
	add xbc, xwa
	ld (xbc), 0			; null terminate
	jr t, .Lff_after_copy1

.Lff_long_copy1:			; 0x28E35F
	pushw 127			; max = 0x7F
	ld wa, iz
	extz xwa
	add xwa, 22
	ld xbc, HDAE5000_RAM_LyricBuffer
	add xbc, xwa
	push xbc			; push source
	lda xwa, (0x230458:24); &0x230458
	push xwa
	call HDAE5000_MemCopy			; strcpy_len
	lda xsp, (xsp + 10)
	ld (0x2304d7:24), 0x00; (0x2304D7) = 0 — null terminate at 127

.Lff_after_copy1:			; 0x28E387
	; --- (0x230444) = tick of the next event ---
	ld xwa, (0x230440:24); XWA = (0x230440)
	add xwa, (2294864:24); XWA += (0x230450)
	ld (0x230444:24), xwa; (0x230444) = XWA — total

	; --- flag bit 1: data -> 0x230636 (<= 127), NUL-ended ---
	ld a, (xsp + 6)		; A = flags
	and a, 2			; isolate bit 1
	cp a, 2:i3
	jr nz, .Lff_after_copy2		; skip if bit 1 not set
	cpw (2294838:24), 127; cp (0x230436), 0x7F
	jr ugt, .Lff_long_copy2
	; Short copy
	ld wa, (0x230436:24)
	extz xwa
	pushw wa
	ld wa, iz
	extz xwa
	add xwa, 22
	ld xbc, HDAE5000_RAM_LyricBuffer
	add xbc, xwa
	push xbc
	lda xwa, (0x230636:24); &0x230636
	push xwa
	call HDAE5000_MemCopy			; strcpy_len
	lda xsp, (xsp + 10)
	; Null-terminate
	ld wa, (0x230436:24)
	extz xwa
	ld xbc, 2295350			; 0x00230636
	add xbc, xwa
	ld (xbc), 0
	jr t, .Lff_after_copy2

.Lff_long_copy2:			; 0x28E3E3
	pushw 127
	ld wa, iz
	extz xwa
	add xwa, 22
	ld xbc, HDAE5000_RAM_LyricBuffer
	add xbc, xwa
	push xbc
	lda xwa, (0x230636:24); &0x230636
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 10)
	ld (0x2306b5:24), 0x00; (0x2306B5) = 0

.Lff_after_copy2:			; 0x28E40B
	ld hl, (0x23043a:24); HL = (0x23043A) — end position
	sub hl, (xsp + 4)		; HL = event size

	; --- Epilogue ---
.Lff_epilogue:				; 0x28E413
	pop xiz
	inc 4, xsp
	ret

	; ============================================================
	; Read 16-bit big-endian word from sector allocation table
	; Reads table[WA+23] as low byte and table[WA+22] as high byte,
	; combining into HL = (high << 8) | low.
	; Input: WA = sector index
	; Output: HL = 16-bit value from two consecutive table entries
	; ============================================================
HDAE5000_Read_Table_Word:		; 0x28E417
	ld bc, wa
	inc 1, bc			; BC = WA + 1
	extz xbc
	add xbc, 22
	ld xde, HDAE5000_RAM_LyricBuffer			; 0x0022B430
	add xde, xbc
	ld c, (xde)			; C = low byte
	ld e, c				; E = C
	extz de				; DE = C (zero-extended)
	extz xwa
	add xwa, 22
	ld xbc, HDAE5000_RAM_LyricBuffer
	add xbc, xwa
	ld a, (xbc)			; A = high byte
	extz wa
	sll wa, 8			; WA = A << 8
	ld hl, wa			; HL = high byte << 8
	or hl, de			; HL |= low byte
	ret

	; ============================================================
	; Read 24-bit big-endian value from sector allocation table
	; Reads up to 3 consecutive bytes from table[WA+22..WA+24],
	; accumulating as XHL = (byte0 << 16) | (byte1 << 8) | byte2.
	; Input: WA = sector index
	; Output: XHL = 24-bit value from 3 consecutive table entries
	; ============================================================
HDAE5000_Read_Table_Multi:		; 0x28E44B
	ld bc, wa
	extz xbc
	add xbc, 22
	ld xde, HDAE5000_RAM_LyricBuffer
	add xde, xbc
	ld c, (xde)			; C = count byte
	ld xhl, 0:i3
	ld l, c				; L = count (initial byte)
	ld ix, 0:i3
	cp ix, 3:i3
	ret nc				; if count >= 3, return early
.Lff_h2_loop:				; 0x28E468
	ld bc, wa
	add bc, ix			; BC = WA + IX
	extz xbc
	add xbc, 22
	ld xde, HDAE5000_RAM_LyricBuffer
	add xde, xbc
	ld xbc, 0:i3
	ld c, (xde)			; C = table byte
	sla xhl, 8			; XHL <<= 8
	add xhl, xbc			; XHL += byte
	inc 1, ix
	cp ix, 3:i3
	jr c, .Lff_h2_loop		; loop while IX < 3
	ret

	; ============================================================
	; Read a MIDI variable-length number (7 bits per byte, most
	; significant first, bit 7 = more bytes follow; at most 4 bytes)
	; at lyric-track position WA (buffer 0x22B430 + 22 + WA).
	; Output: XHL = the value, or -1 when no byte of the first four
	; ends it; (0x23085E) = number of bytes read.
	; ============================================================
HDAE5000_Lyrics_ReadVarLen:	; 0x28E48B (87 bytes)
	ld xhl, 0:i3			; XHL = accumulator (decoded value)
	ld ix, 0:i3			; IX = byte index (0-3)
	cp ix, 4:i3			; guard: max 4 bytes per VarInt
	jr nc, .Lcds_overflow
.Lcds_loop:
	; byte at buffer[WA + IX + 22]
	ld bc, wa		; BC = position
	add bc, ix			; BC += byte offset
	extz xbc
	add xbc, 0x00000016		; +22: past the chunk headers
	ld xde, HDAE5000_RAM_LyricBuffer		; XDE = lyric buffer 0x22B430
	add xde, xbc			; XDE → table[sector + 22]
	ld c, (xde)		; C = VarLen byte
	res 7, c			; strip VarInt continuation bit → 7-bit payload
	ld b, 0x00:opc
	extz xbc			; XBC = payload (zero-extended)
	add xhl, xbc			; accumulate: XHL += payload
	; Re-read byte to check continuation bit (bit 7)
	ld bc, wa
	add bc, ix
	extz xbc
	add xbc, 0x00000016
	ld xde, HDAE5000_RAM_LyricBuffer
	add xde, xbc
	cp (xde), 0x80		; bit 7 set? (continuation)
	jr nc, .Lcds_continue		; yes → more bytes follow
	; Continuation=0 → VarInt complete, return decoded value
	ld wa, ix			; WA = bytes consumed (0-based)
	inc 1, wa			; WA = byte count (1-based)
	ld (0x23085e:24), wa; store bytes consumed to (0x23085E)
	ret		; return XHL = value
.Lcds_continue:
	sll xhl, 7			; make room for next 7-bit chunk
	inc 1, ix
	cp ix, 4:i3			; max 4 continuation bytes
	jr c, .Lcds_loop
.Lcds_overflow:
	ld xhl, 0xFFFFFFFF		; overflow: VarInt > 4 bytes
	ret
	; Finds how many 7-bit chunks are needed, then serializes
	; MSB-first with bit 7 = continuation on all but last byte.
	; Input: XWA = value to encode, XBC = output buffer pointer
	; Output: HL = 0xFFFF (sentinel)

HDAE5000_Lyrics_WriteVarLen:
	; The encoder matching HDAE5000_Lyrics_ReadVarLen: write XWA as a
	; variable-length number to (XBC), at most 5 bytes.  No caller was found
	; (scripts/analysis/hdae5000_reachability.py).
	; Step 1: Count how many 7-bit chunks are needed
	ld xde, xwa			; XDE = value to encode
	ld hl, 1:i3			; HL = chunk count (start at 1)
	cp hl, 5:i3			; max 5 chunks
	jr nc, .Lcds_apply
.Lcds_search:
	srl xde, 7			; shift out 7 bits
	jr nz, .Lcds_next		; still nonzero? need more chunks
	ld ix, hl			; IX = total chunks needed
	jr t, .Lcds_apply		; done counting
.Lcds_next:
	inc 1, hl
	cp hl, 5:i3
	jr c, .Lcds_search
	; Step 2: Serialize chunks MSB-first into buffer
.Lcds_apply:
	ld xde, xwa			; XDE = value (fresh copy)
	ld hl, ix			; HL = chunk count
	cp hl, 0:i3
	jr z, .Lcds_done		; nothing to write
.Lcds_apply_loop:
	ld wa, hl
	dec 1, wa			; WA = output index (HL-1)
	extz xwa
	ld xix, xwa
	add xix, xbc			; XIX = &buffer[index]
	ld a, e				; A = low 7 bits of XDE
	res 7, a			; clear continuation bit (initially)
	ld (xix), a			; buffer[index] = 7-bit payload
	srl xde, 7			; shift out the 7 bits we just wrote
	cp xde, 0x0000007F		; remaining value fits in 7 bits?
	ret ule				; yes → last byte already written, done
	; More bytes needed: set continuation bit on byte we just wrote
	ld wa, hl
	dec 1, wa
	extz xwa
	ld xix, xwa
	add xix, xbc			; XIX = &buffer[index]
	ld wa, hl
	dec 1, wa
	extz xwa
	add xwa, xbc
	ld a, (xwa)			; re-read byte we just stored
	set 7, a			; set continuation bit (more bytes follow)
	ld (xix), a			; write back with continuation
	djnz16 hl, .Lcds_apply_loop	; next chunk
.Lcds_done:
	ldw hl, 0xFFFF			; return sentinel
	ret

HDAE5000_Lyrics_CheckHeaderChunk:	; 0x28E53D (113 bytes)
	; Check the lyric file's header chunk (the SMF MThd checks with its own
	; id): "TLhd" at +0 (HDAE5000_MemCmp against HDAE5000_Str_Tlhd, else -1),
	; big-endian length 6 at +4 (else -2), format <= 0 at +8 (else -3), track
	; count <= 1 at +10 (else -4), division bit 15 (SMPTE) clear at +12 (else
	; -5); returns 0 when all hold.  Only caller: HDAE5000_Lyrics_CheckFile.
	pushw 0x0004		; 4 bytes
	lda xwa, (HDAE5000_Str_Tlhd:24)		; "TLhd"
	push xwa			; push source ptr
	lda xwa, (HDAE5000_RAM_LyricBuffer:24)		; lyric buffer +0
	push xwa			; push dest ptr
	call HDAE5000_MemCmp
	add xsp, 0x0000000A		; clean up 10 bytes (3 args)
	cp hl, 0:i3
	jr z, .Ldn_check1
	ld xhl, 0xFFFFFFFF		; return -1: no TLhd
	ret
.Ldn_check1:
	ld xwa, 6:i3		; 6, byte-swapped
	calr HDAE5000_SwapBytes32
	cp (2274356:24), xhl		; chunk length
	jr z, .Ldn_check2		; if match, continue
	ld xhl, 0xFFFFFFFE		; return -2: length != 6
	ret
.Ldn_check2:
	ld wa, 0:i3		; 0, byte-swapped
	calr HDAE5000_SwapBytes16
	cp (2274360:24), hl		; format
	jr ule, .Ldn_check3		; if <= expected, continue
	ld xhl, 0xFFFFFFFD		; return -3
	ret
.Ldn_check3:
	ld wa, 1:i3		; 1, byte-swapped
	calr HDAE5000_SwapBytes16
	cp (2274362:24), hl		; track count
	jr ule, .Ldn_check4		; if <= expected, continue
	ld xhl, 0xFFFFFFFC		; return -4
	ret
.Ldn_check4:
	ldw wa, 0x8000		; 0x8000, byte-swapped
	calr HDAE5000_SwapBytes16
	ld wa, (0x22b43c:24); ld WA, (0x22B43C)
	and wa, hl		; division & 0x8000 (SMPTE)
	jr z, .Ldn_ok			; if zero, valid
	ld xhl, 0xFFFFFFFB		; return -5
	ret
.Ldn_ok:
	ld xhl, 0:i3			; return 0 (success)
	ret

HDAE5000_Lyrics_CheckTrackChunk:	; 0x28E5AE (59 bytes)
	; Check the lyric file's track chunk: "TLtr" at +14 (else -10), then
	; (0x2304F2) = its big-endian length + 22 = the end of the events.
	; Only caller: HDAE5000_Lyrics_CheckFile.
	pushw 0x0004		; 4 bytes
	lda xwa, (HDAE5000_Str_Tltr:24)		; "TLtr"
	push xwa
	lda xwa, (0x22b43e:24)		; lyric buffer +14
	push xwa
	call HDAE5000_MemCmp
	add xsp, 0x0000000A		; deallocate 10 bytes (3 pushed args)
	cp hl, 0:i3
	jr z, .LLyrics_CheckTrackChunk__ok
	ld xhl, 0xFFFFFFF6		; return -10: no TLtr
	ret
.LLyrics_CheckTrackChunk__ok:
	ld xwa, (0x22b442:24)		; XWA = track length, big-endian
	calr HDAE5000_SwapBytes32
	ld xwa, xhl
	add xwa, 0x00000016		; + 22 (the two chunk headers)
	ld (0x2304f2:24), xwa		; (0x2304F2) = end of the events
	ld xhl, 0:i3			; return 0 (success)
	ret

HDAE5000_SwapBytes32:	; 0x28E5E9 (37 bytes)
	; XHL = XWA with its four bytes reversed (big-endian <-> little-endian).
	; Reads the TLhd/TLtr lengths (HDAE5000_Lyrics_CheckHeaderChunk and
	; _CheckTrackChunk) and two more values in this file.
	ld xhl, xwa
	and xhl, 0x000000FF
	ld de, 0:i3			; loop counter = 0
	cp de, 3:i3			; compare with 3
	ret ge				; return if already done
.LSwapBytes32__loop:
	srl xwa, 8			; next byte
	sll xhl, 8			; shift result left
	ld xbc, xwa
	and xbc, 0x000000FF		; mask byte
	add xhl, xbc			; accumulate
	inc 1, de			; counter++
	cp de, 3:i3
	jr lt, .LSwapBytes32__loop
	ret

HDAE5000_SwapBytes16:	; 0x28E60E (13 bytes)
	; HL = WA with its two bytes swapped (13 bytes; the "2397 bytes" of the
	; label comment ran on over HDAE5000_FDFileSelectProc, which follows).

	ld hl, wa
	ld h, 0:opc			; keep low byte only
	srl wa, 8			; WA = high byte
	sll hl, 8			; HL <<= 8
	add hl, wa			; HL = low*256 + high
	ret

	; --- Main dispatch function (2384 bytes) ---
HDAE5000_FDFileSelectProc:
	; registered as "FDFileSelectProc" in HDAE5000_ClassProc_Table
	lda_dri xsp, 0xfd, 0x7e, 0xff	; lda XSP, XSP-130 (stack frame)
	push xiz
	ld (xsp + 0x7a), xde		; save arg3
	ld (xsp + 0x7e), xbc		; save arg2
	stl_dri xwa, 0xfd, 0x82, 0x00	; save arg1 at (XSP+0x82)

	; --- Case dispatch on arg2 ---
	ld xwa, (xsp + 0x7e)
	cp xwa, 0x01c00007
	jrl z, .Lsc_case_07
	cp xwa, 0x01c00018
	jrl z, .Lsc_case_18
	cp xwa, 0x01c00017
	jrl z, .Lsc_case_17
	cp xwa, 0x01ea0011
	jrl z, .Lsc_case_11_ea
	cp xwa, 0x01ea0010
	jrl z, .Lsc_case_10_ea
	cp xwa, 0x01ea000f
	jrl z, .Lsc_case_0f_ea
	cp xwa, 0x01ea000e
	jrl z, .Lsc_case_0e
	cp xwa, 0x01c0000f
	jrl z, .Lsc_case_0f
	cp xwa, 0x01ca000c
	jrl z, .Lsc_case_0c
	cp xwa, 0x01c00002
	jrl z, .Lsc_case_02
	cp xwa, 0x01c00001
	jr z, .Lsc_case_01
	cp xwa, 0x01c0000d
	jrl nz, .Lsc_default

	; ============================================================
	; Case 0x01C0000D — dispatch vtable calls + send messages
	; ============================================================
.Lsc_case_0d:
	ld_sril XWA, (xsp + 0x0082)             ; reload arg1
	ld xbc, (xsp + 0x7e)
	ld xde, (xsp + 0x7a)
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XHL, (xhl + WS_RootFnTable)             ; vtable base
	ld_sril XHL, (xhl + RootFn_InheritedProc)             ; method 0x00DC
	call (xhl)

	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XBC, (xbc + WS_RootFnTable)
	ld XIX, (xbc + RootFn_GetViewInstance)             ; method 0x02C4
	call (xix)

	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XBC, (xbc + WS_RootFnTable)
	ld_sril XHL, (xbc + RootFn_SendEvent)             ; method 0x0100
	ld xbc, 0x01ca000c
	ld xde, 0:i3
	call (xhl)

	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XBC, (xbc + WS_RootFnTable)
	ld_sril XHL, (xbc + RootFn_SendEvent)             ; method 0x0100
	ld xbc, 0x01c0000f
	ld xde, 0:i3
	call (xhl)

	ld xhl, 0:i3
	jrl t, .Lsc_epilogue

	; ============================================================
	; Case 0x01C00001 — vtable dispatch + display setup
	; ============================================================
.Lsc_case_01:
	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (xsp + 0x7e)
	ld xde, (xsp + 0x7a)
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XHL, (xhl + WS_RootFnTable)
	ld_sril XHL, (xhl + RootFn_InheritedProc)
	call (xhl)

	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XBC, (xbc + WS_RootFnTable)
	ld XIX, (xbc + RootFn_GetViewInstance)
	call (xix)

	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XBC, (xbc + WS_RootFnTable)
	ld XHL, (xbc + RootFn_SetDialUp)             ; method 0x03C8
	ld xbc, 0x01c00018
	ld xde, 0:i3
	call (xhl)

	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XBC, (xbc + WS_RootFnTable)
	ld XHL, (xbc + RootFn_SetDialDown)             ; method 0x03CC
	ld xbc, 0x01c00017
	ld xde, 0:i3
	call (xhl)

	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld XHL, (xwa + RootFn_SetDialEnable)             ; method 0x03C4
	ld wa, 1:i3
	call (xhl)

	pushw 0x002e
	pushw 0x5cae		; low half of HDAE5000_Str_Empty_FDFileSelectProc
	pushw 0x0023
	pushw 0x0e7a
	call HDAE5000_StrCpy
	inc 0, xsp			; clean 8 bytes

	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XBC, (xbc + WS_RootFnTable)
	ld_sril XHL, (xbc + RootFn_SendEvent)             ; method 0x0100
	ld xbc, 0x01ea000e
	ld xde, 0:i3
	call (xhl)

	ldw (0x22a0c8:24), 0x0021
	ldw (0x22a0cc:24), 0x0118
	ldw (0x22a0ca:24), 0x00c5
	ldw (0x22a0ce:24), 0x00d1
	ld wa, (0x22a0c8:24)
	inc 2, wa
	ld (0x22a0bc:24), wa
	ld wa, (0x22a0ca:24)
	inc 3, wa
	ld (0x22a0be:24), wa

	ld xhl, 0:i3
	jrl t, .Lsc_epilogue

	; ============================================================
	; Case 0x01C00002 — simple vtable call
	; ============================================================
.Lsc_case_02:
	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (xsp + 0x7e)
	ld xde, (xsp + 0x7a)
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XHL, (xhl + WS_RootFnTable)
	ld_sril XHL, (xhl + RootFn_InheritedProc)
	call (xhl)
	ld xhl, 0:i3
	jrl t, .Lsc_epilogue

	; ============================================================
	; Case 0x01CA000C — 3-section loop UI setup
	; ============================================================
.Lsc_case_0c:
	ldw (xsp + 0x6e), 0x0016
	ldw wa, 0x0016
	add wa, 0x0037
	ld (xsp + 0x72), wa
	ld wa, (xsp + 0x6e)
	inc 2, wa
	ld (xsp + 0x76), wa
	ldw (xsp + 0x04), 0x0000
	cpw (xsp + 0x04), 0x000c
	jrl nc, .Lsc_0c_sect2

	; --- Section 1 loop: 12 iterations ---
.Lsc_0c_loop1:
	ld wa, (xsp + 0x04)
	mul wa, 0x000c
	add wa, 0x0028
	ld (xsp + 0x70), wa
	add wa, 0x000c
	ld (xsp + 0x74), wa
	ld wa, (xsp + 0x70)
	inc 3, wa
	ld (xsp + 0x78), wa
	lda xwa, (xsp + 0x6e)
	ld xhl, xwa
	lda xwa, (xsp + 0x76)
	ld xbc, xwa
	lda xwa, (HDAE5000_Str_Blank27:24)
	ld xde, xwa
	ld xwa, 3:i3
	push xwa
	pushw 0x00ff
	pushw 0x00f5
	ld xwa, xhl
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XHL, (xhl + WS_RootFnTable)
	ld_sril XHL, (xhl + RootFn_DrawString)             ; method 0x00C4
	call (xhl)

	lda xwa, (xsp + 0x6e)
	ld xix, xwa
	lda xwa, (xsp + 0x76)
	ld xhl, xwa
	ld wa, (0x230e78:24)
	add wa, (xsp + 0x04)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	add xbc, xwa
	ld xde, 0x00230884
	add xde, xbc
	ld xwa, 3:i3
	push xwa
	pushw 0x00ff
	pushw 0x00f5
	ld xwa, xix
	ld xbc, xhl
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XHL, (xhl + WS_RootFnTable)
	ld_sril XHL, (xhl + RootFn_DrawString)
	call (xhl)

	incw 1, (xsp + 0x04)
	cpw (xsp + 0x04), 0x000c
	jrl c, .Lsc_0c_loop1

	; --- Section 2: offset 0x5C, 12 iterations ---
.Lsc_0c_sect2:
	ldw (xsp + 0x6e), 0x005c
	ldw wa, 0x005c
	add wa, 0x00a2
	ld (xsp + 0x72), wa
	ld wa, (xsp + 0x6e)
	inc 2, wa
	ld (xsp + 0x76), wa
	ldw (xsp + 0x04), 0x0000
	cpw (xsp + 0x04), 0x000c
	jrl nc, .Lsc_0c_sect3

.Lsc_0c_loop2:
	ld wa, (xsp + 0x04)
	mul wa, 0x000c
	add wa, 0x0028
	ld (xsp + 0x70), wa
	add wa, 0x000c
	ld (xsp + 0x74), wa
	ld wa, (xsp + 0x70)
	inc 3, wa
	ld (xsp + 0x78), wa
	lda xwa, (xsp + 0x6e)
	ld xhl, xwa
	lda xwa, (xsp + 0x76)
	ld xbc, xwa
	lda xwa, (HDAE5000_Str_Blank27_FDFileSelectProc:24)
	ld xde, xwa
	ld xwa, 3:i3
	push xwa
	pushw 0x00ff
	pushw 0x00f5
	ld xwa, xhl
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XHL, (xhl + WS_RootFnTable)
	ld_sril XHL, (xhl + RootFn_DrawString)
	call (xhl)

	lda xwa, (xsp + 0x6e)
	ld (xsp + 0x06), xwa
	lda xwa, (xsp + 0x76)
	ld xiz, xwa
	ld wa, (0x230e78:24)
	add wa, (xsp + 0x04)
	extz xwa
	ld xbc, 0x0000001b
	call HDAE5000_Multiply
	ld xde, 0x002309f6
	add xde, xhl
	ld xwa, 3:i3
	push xwa
	pushw 0x00ff
	pushw 0x00f5
	ld xwa, (xsp + 0x0e)
	ld xbc, xiz
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XHL, (xhl + WS_RootFnTable)
	ld_sril XHL, (xhl + RootFn_DrawString)
	call (xhl)

	incw 1, (xsp + 0x04)
	cpw (xsp + 0x04), 0x000c
	jrl c, .Lsc_0c_loop2

	; --- Section 3: offset 0x10C, 12 iterations ---
.Lsc_0c_sect3:
	ldw (xsp + 0x6e), 0x010c
	ldw wa, 0x010c
	add wa, 0x001f
	ld (xsp + 0x72), wa
	ld wa, (xsp + 0x6e)
	inc 2, wa
	ld (xsp + 0x76), wa
	ldw (xsp + 0x04), 0x0000
	cpw (xsp + 0x04), 0x000c
	jrl nc, .Lsc_0c_done

.Lsc_0c_loop3:
	ld wa, (xsp + 0x04)
	mul wa, 0x000c
	add wa, 0x0028
	ld (xsp + 0x70), wa
	add wa, 0x000c
	ld (xsp + 0x74), wa
	ld wa, (xsp + 0x70)
	inc 3, wa
	ld (xsp + 0x78), wa
	ld wa, (0x230e78:24)
	add wa, (xsp + 0x04)
	extz xwa
	ld xbc, 0x00230e4a
	add xbc, xwa
	cp (xbc), 0x00
	jr z, .Lsc_0c_z

	; nonzero: slot occupied
.Lsc_0c_nz:
	lda xwa, (xsp + 0x6e)
	ld xhl, xwa
	lda xwa, (xsp + 0x76)
	ld xbc, xwa
	lda xwa, (HDAE5000_Str_Mid:24)
	ld xde, xwa
	ld xwa, 3:i3
	push xwa
	pushw 0x00ff
	pushw 0x00f5
	ld xwa, xhl
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XHL, (xhl + WS_RootFnTable)
	ld_sril XHL, (xhl + RootFn_DrawString)
	call (xhl)
	jr t, .Lsc_0c_loop3end

	; zero: slot empty
.Lsc_0c_z:
	lda xwa, (xsp + 0x6e)
	ld xhl, xwa
	lda xwa, (xsp + 0x76)
	ld xbc, xwa
	lda xwa, (HDAE5000_Str_Blank3:24)
	ld xde, xwa
	ld xwa, 3:i3
	push xwa
	pushw 0x00ff
	pushw 0x00f5
	ld xwa, xhl
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XHL, (xhl + WS_RootFnTable)
	ld_sril XHL, (xhl + RootFn_DrawString)
	call (xhl)

.Lsc_0c_loop3end:
	incw 1, (xsp + 0x04)
	cpw (xsp + 0x04), 0x000c
	jrl c, .Lsc_0c_loop3

.Lsc_0c_done:
	ld xhl, 0:i3
	jrl t, .Lsc_epilogue

	; ============================================================
	; Case 0x01C0000F — display region configuration
	; ============================================================
.Lsc_case_0f:
	ld wa, (0x230e74:24)
	mul wa, 0x000c
	add wa, 0x0028
	ld (xsp + 0x70), wa
	add wa, 0x000c
	ld (xsp + 0x74), wa

	; Region 1: y=0x14
	ldw (xsp + 0x6e), 0x0014
	ldw (0x22a0c0:24), 0x0014
	ld wa, (xsp + 0x6e)
	add wa, 0x0039
	ld (xsp + 0x72), wa
	ld (0x22a0c4:24), wa
	lda xwa, (0x22a0c0:24)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XBC, (xbc + WS_RootFnTable)
	ld_sril XHL, (xbc + RootFn_DrawFrame)             ; method 0x00A8
	ldw bc, 0x00f5
	call (xhl)

	lda xwa, (xsp + 0x6e)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XBC, (xbc + WS_RootFnTable)
	ld_sril XHL, (xbc + RootFn_DrawFrame)
	ldw bc, 0x00f2
	call (xhl)

	; Region 2: y=0x5C
	ldw (xsp + 0x6e), 0x005c
	ldw (0x22a0c0:24), 0x005c
	ld wa, (xsp + 0x6e)
	add wa, 0x00a2
	ld (xsp + 0x72), wa
	ld (0x22a0c4:24), wa
	lda xwa, (0x22a0c0:24)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XBC, (xbc + WS_RootFnTable)
	ld_sril XHL, (xbc + RootFn_DrawFrame)
	ldw bc, 0x00f5
	call (xhl)

	lda xwa, (xsp + 0x6e)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XBC, (xbc + WS_RootFnTable)
	ld_sril XHL, (xbc + RootFn_DrawFrame)
	ldw bc, 0x00f2
	call (xhl)

	; Region 3: y=0x10C
	ldw (xsp + 0x6e), 0x010c
	ldw (0x22a0c0:24), 0x010c
	ld wa, (xsp + 0x6e)
	add wa, 0x001f
	ld (xsp + 0x72), wa
	ld (0x22a0c4:24), wa
	lda xwa, (0x22a0c0:24)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XBC, (xbc + WS_RootFnTable)
	ld_sril XHL, (xbc + RootFn_DrawFrame)
	ldw bc, 0x00f5
	call (xhl)

	lda xwa, (xsp + 0x6e)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XBC, (xbc + WS_RootFnTable)
	ld_sril XHL, (xbc + RootFn_DrawFrame)
	ldw bc, 0x00f2
	call (xhl)

	; Store current slot bounds
	ld wa, (xsp + 0x70)
	ld (0x22a0c2:24), wa
	ld wa, (xsp + 0x74)
	ld (0x22a0c6:24), wa

	; Setup display frame rect
	lda xwa, (0x22a0c8:24)
	ld xhl, xwa
	lda xwa, (0x22a0bc:24)
	ld xbc, xwa
	lda xwa, (HDAE5000_Str_Blank49:24)
	ld xde, xwa
	ld xwa, 3:i3
	push xwa
	pushw 0x00ff
	pushw 0x00f5
	ld xwa, xhl
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XHL, (xhl + WS_RootFnTable)
	ld_sril XHL, (xhl + RootFn_DrawString)
	call (xhl)

	; String lookup for current slot
	ld wa, (0x230e76:24)
	extz xwa
	ld xbc, 0x0000001b
	call HDAE5000_Multiply
	ld xwa, 0x002309f6
	add xwa, xhl
	push xwa
	call HDAE5000_StrLen
	inc 4, xsp
	cp hl, 0:i3
	jr z, .Lsc_0f_notfound

	; Found: format with name
	ld wa, (0x230e76:24)
	extz xwa
	ld xbc, 0x0000001b
	call HDAE5000_Multiply
	ld xwa, 0x002309f6
	add xwa, xhl
	push xwa
	pushw 0x0023
	pushw 0x0e7a
	pushw 0x002e
	pushw 0x5d22		; low half of HDAE5000_Fmt_s_s
	lda xwa, (xsp + 0x16)
	push xwa
	call HDAE5000_SPrintf
	lda xsp, (xsp + 0x10)
	jr t, .Lsc_0f_merge

	; Not found: format with slot index
.Lsc_0f_notfound:
	ld wa, (0x230e76:24)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	add xbc, xwa
	ld xwa, 0x00230884
	add xwa, xbc
	push xwa
	pushw 0x0023
	pushw 0x0e7a
	pushw 0x002e
	pushw 0x5d28		; low half of HDAE5000_Fmt_s_s_FDFileSelectProc
	lda xwa, (xsp + 0x16)
	push xwa
	call HDAE5000_SPrintf
	lda xsp, (xsp + 0x10)

.Lsc_0f_merge:
	lda xwa, (0x22a0c8:24)
	ld xhl, xwa
	lda xwa, (0x22a0bc:24)
	ld xbc, xwa
	lda xwa, (xsp + 0x0a)
	ld xde, xwa
	ld xwa, 3:i3
	push xwa
	pushw 0x00ff
	pushw 0x00f5
	ld xwa, xhl
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XHL, (xhl + WS_RootFnTable)
	ld_sril XHL, (xhl + RootFn_DrawString)
	call (xhl)

	ld xhl, 0:i3
	jrl t, .Lsc_epilogue

	; ============================================================
	; Case 0x01EA000E — memory initialization + path builder
	; ============================================================
.Lsc_case_0e:
	ldw (0x230e76:24), 0x0000
	ldw (0x230e78:24), 0x0000
	ldw (0x230e72:24), 0x0000
	ldw (0x230e74:24), 0x0000

	pushw 0x0171
	pushw 0x0000
	lda xwa, (0x230884:24)
	push xwa
	call HDAE5000_MemFill
	pushw 0x0453
	pushw 0x0000
	lda xwa, (0x2309f6:24)
	push xwa
	call HDAE5000_MemFill
	pushw 0x0028
	pushw 0x0000
	lda xwa, (0x230e4a:24)
	push xwa
	call HDAE5000_MemFill
	lda xsp, (xsp + 0x18)		; clean 24 bytes (3 calls x 8)

	calr HDAE5000_Path_Builder
	ld xhl, 0:i3
	jrl t, .Lsc_epilogue

	; ============================================================
	; Cases 0x01EA000F/0010/0011 — return 0
	; ============================================================
.Lsc_case_0f_ea:
	ld xhl, 0:i3
	jrl t, .Lsc_epilogue
.Lsc_case_10_ea:
	ld xhl, 0:i3
	jrl t, .Lsc_epilogue
.Lsc_case_11_ea:
	ld xhl, 0:i3
	jrl t, .Lsc_epilogue

	; ============================================================
	; Case 0x01C00017 — vtable call + send message 0x01C00007
	; ============================================================
.Lsc_case_17:
	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (xsp + 0x7e)
	ld xde, (xsp + 0x7a)
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XHL, (xhl + WS_RootFnTable)
	ld_sril XHL, (xhl + RootFn_InheritedProc)
	call (xhl)

	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XBC, (xbc + WS_RootFnTable)
	ld_sril XHL, (xbc + RootFn_SendEvent)
	ld xbc, 0x01c00007
	ld xde, 3:i3
	call (xhl)

	; ============================================================
	; Default case — vtable call + forward to case_01
	; ============================================================
.Lsc_default:
	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (xsp + 0x7e)
	ld xde, (xsp + 0x7a)
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XHL, (xhl + WS_RootFnTable)
	ld_sril XIX, (xhl + RootFn_InheritedProc)
	call (xix)
	jrl t, .Lsc_epilogue

	; ============================================================
	; Case 0x01C00018 — vtable calls + send 0x01C00007 with flag
	; ============================================================
.Lsc_case_18:
	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (xsp + 0x7e)
	ld xde, (xsp + 0x7a)
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XHL, (xhl + WS_RootFnTable)
	ld_sril XHL, (xhl + RootFn_InheritedProc)
	call (xhl)

	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XBC, (xbc + WS_RootFnTable)
	ld_sril XHL, (xbc + RootFn_SendEvent)
	ld xbc, 0x01c00007
	ld xde, 0x00000083
	call (xhl)
	jr t, .Lsc_default

	; ============================================================
	; Case 0x01C00007 — button handler with sub-dispatch
	; ============================================================
.Lsc_case_07:
	ld xwa, (xsp + 0x7a)		; XWA = arg3 (button code)
	cp xwa, 0x00000007
	jr ule, .Lsc_07_inrange
	sub xwa, 0x00000078
	cp xwa, 0x00000008
	jrl c, .Lsc_ret0
	cp xwa, 0x0000000f
	jrl ugt, .Lsc_ret0

.Lsc_07_inrange:
	add xwa, HDAE5000_FDFileSelectProc_KeyCaseMap		; byte lookup table
	ld wa, (xwa)
	extz wa
	sll wa, 1			; word offset
	ld xix, HDAE5000_FDFileSelectProc_KeyCaseTable		; offset table base
	ldw_sri wa, 0x07, 0xf0, 0xe0	; WA = (XIX+WA) — load jump offset
	lda xix, (.Lsc_07_btn_down:24); base = .Lsc_07_btn_down
	jp_ind 8, 0x07, 0xf0, 0xe0	; jp T, XIX+WA

	; --- Down button handler ---
.Lsc_07_btn_down:
	cpw (0x230e76:24), 0x0000
	jr nz, .Lsc_down_nz
	ld xhl, 0xffffffff		; return -1
	jrl t, .Lsc_epilogue

.Lsc_down_nz:
	decw 1, (0x230e76:24); slot_index--
	cpw (0x230e74:24), 0x0000
	jr nz, .Lsc_down_74nz

	; page_offset == 0: check scroll_offset
	cpw (0x230e78:24), 0x0000
	jr nz, .Lsc_down_78nz
	ld xhl, 0xffffffff
	jrl t, .Lsc_epilogue

.Lsc_down_78nz:
	decw 1, (0x230e78:24)
	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XBC, (xbc + WS_RootFnTable)
	ld_sril XHL, (xbc + RootFn_SendEvent)
	ld xbc, 0x01c0000d
	ld xde, 0:i3
	call (xhl)
	jr t, .Lsc_down_merge

.Lsc_down_74nz:
	decw 1, (0x230e74:24)
	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XBC, (xbc + WS_RootFnTable)
	ld_sril XHL, (xbc + RootFn_SendEvent)
	ld xbc, 0x01c0000f
	ld xde, 0:i3
	call (xhl)

.Lsc_down_merge:
	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (xsp + 0x7e)
	ld xde, (xsp + 0x7a)
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XHL, (xhl + WS_RootFnTable)
	ld XHL, (xhl + RootFn_SetAutoInc)             ; method 0x042C
	call (xhl)
	jrl t, .Lsc_ret0

	; --- Up button handler ---
.Lsc_07_btn_up:
	ld wa, (0x230e72:24)
	dec 1, wa
	cp (0x230e76:24), wa; compare slot_index with limit
	jr c, .Lsc_up_ok
	ld xhl, 0xffffffff
	jrl t, .Lsc_epilogue

.Lsc_up_ok:
	incw 1, (0x230e76:24)
	cpw (0x230e74:24), 0x000b
	jr c, .Lsc_up_inc74

	; page_offset >= 11: scroll
	incw 1, (0x230e78:24)
	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XBC, (xbc + WS_RootFnTable)
	ld_sril XHL, (xbc + RootFn_SendEvent)
	ld xbc, 0x01c0000d
	ld xde, 0:i3
	call (xhl)
	jr t, .Lsc_up_merge

.Lsc_up_inc74:
	incw 1, (0x230e74:24)
	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XBC, (xbc + WS_RootFnTable)
	ld_sril XHL, (xbc + RootFn_SendEvent)
	ld xbc, 0x01c0000f
	ld xde, 0:i3
	call (xhl)

.Lsc_up_merge:
	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (xsp + 0x7e)
	ld xde, (xsp + 0x7a)
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XHL, (xhl + WS_RootFnTable)
	ld XHL, (xhl + RootFn_SetAutoInc)
	call (xhl)
	jrl t, .Lsc_ret0

	; --- Enter/Select button handler ---
.Lsc_07_btn_enter:
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_HamaFnTable)             ; (XWA+0x0E88) status obj
	ld xix, (xwa + HamaFn_GetMediaType)
	call (xix)			; get status
	cp l, 3:i3
	jr z, .Lsc_enter_active
	cp l, 2:i3
	jrl nz, .Lsc_enter_skip

.Lsc_enter_active:
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld XHL, (xwa + RootFn_SleepMainTask)             ; method 0x0538
	call (xhl)

	ld wa, (0x230e76:24)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	add xbc, xwa
	ld xwa, 0x00230884
	add xwa, xbc
	push xwa			; slot data address
	lda xwa, (xsp + 0x0e)
	push xwa			; format buffer
	call HDAE5000_StrCpy
	pushw 0x002e
	pushw 0x5d2e		; low half of HDAE5000_Str_TLX_FDFileSelectProc
	lda xwa, (xsp + 0x16)
	push xwa
	call HDAE5000_StrCat
	lda xsp, (xsp + 0x10)		; clean 16 bytes

	lda xwa, (xsp + 0x0a)
	lda xbc, (HDAE5000_Str_Rb_FDFileSelectProc:24)
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XDE, (xde + WS_HamaFnTable)
	ld_sril XHL, (xde + HamaFn_fopen_ext)             ; method 0x00A0
	call (xhl)

	lda xwa, (HDAE5000_RAM_LyricBuffer:24)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XBC, (xbc + WS_HamaFnTable)
	ld_sril XHL, (xbc + HamaFn_fread_ext)
	ld xbc, 0x00005000
	call (xhl)

	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_HamaFnTable)
	ld_sril XHL, (xwa + HamaFn_fclose_ext)             ; method 0x00AC
	call (xhl)

	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld XHL, (xwa + RootFn_WakeUpMainTask)             ; method 0x053C
	call (xhl)

.Lsc_enter_skip:
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld XHL, (xwa + RootFn_ApPostEvent)             ; method 0x0124
	ld xwa, HDAE5000_OBJ_Tech_lyrics
	ld xbc, 0x01c00001
	ld xde, 0:i3
	call (xhl)

	; ============================================================
	; Epilogue
	; ============================================================
.Lsc_ret0:
	ld xhl, 0:i3
.Lsc_epilogue:
	pop xiz
	lda_dri xsp, 0xfd, 0x82, 0x00	; lda XSP, XSP+130 (restore stack)
	ret

HDAE5000_Path_Builder:	; 0x28EF6B (556 bytes)
	; Build file path strings using vtable dispatch
	; Scans directory entries, builds path strings, validates filenames
	; Uses nested vtable calls through (0x23A1A2) + offsets

	; --- Prologue: allocate ~370 bytes of stack ---
	lda_dri xsp, 0xfd, 0x8e, 0xfe	; lda XSP, XSP-370
	push xiz			; save XIZ
	ld xwa, 0:i3
	ld (xsp + 4), xwa		; local[0x04] = 0 (result)

	; --- Get vtable, call method at +0x08 via XIX ---
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); XWA = (0x23A1A2) — vtable base
	ld xwa, (xwa + WS_HamaFnTable)             ; XWA = (XWA + 0x0E88)
	ld xix, (xwa + HamaFn_GetMediaType)		; XIX = (XWA + 0x08) — method ptr
	call (xix)			; call method
	cp l, 3:i3			; if L != 3
	jr z, .Lpb_continue		;   (L==3 → continue)
	cp l, 2:i3			; if L != 2 either
	jrl nz, .Lpb_exit		;   return

.Lpb_continue:				; 0x28EF8E
	; --- Call vtable method at +0x0538 ---
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); XWA = (0x23A1A2)
	ld xwa, (xwa + WS_RootFnTable)             ; XWA = (XWA + 0x0E0A)
	ld xhl, (xwa + RootFn_SleepMainTask)             ; XHL = (XWA + 0x0538)
	call (xhl)

	; --- Call vtable method at +0x0090, get XIZ ---
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); XWA = (0x23A1A2)
	ld xwa, (xwa + WS_HamaFnTable)             ; XWA = (XWA + 0x0E88)
	ld_sril xhl, (xwa + HamaFn_GetVolumeLabel)             ; XHL = (XWA + 0x0090)
	call (xhl)
	ld xiz, xhl			; XIZ = result

	; --- If XIZ != 0: get strlen, copy to buffer ---
	ld xwa, xiz
	or xwa, xwa			; test zero
	jr z, .Lpb_empty_path		; if zero, clear buffer

	ld xwa, xiz
	push xwa
	call HDAE5000_StrLen			; strlen(XIZ)
	pushw hl			; push strlen
	ld xwa, xiz
	push xwa
	lda xwa, (0x230e7a:24); XWA = &0x230E7A (path buffer)
	push xwa
	call HDAE5000_MemCopy			; call 0x29AE9F (strcpy with length)
	lda xsp, (xsp + 14)		; pop 14 bytes
	jr t, .Lpb_after_path

.Lpb_empty_path:			; 0x28EFD2
	ld (0x230e7a:24), 0x00; (0x230E7A) = '\0'

.Lpb_after_path:			; 0x28EFD8
	ld (0x230e82:24), 0x00; (0x230E82) = '\0'
	lda xwa, (0x230e7a:24); XWA = &0x230E7A
	push xwa
	call HDAE5000_StrLen			; strlen(path buffer)
	inc 4, xsp
	cp hl, 0:i3			; if strlen > 0
	jr z, .Lpb_no_separator		;   skip separator append

	; Append separator
	pushw 46			; max = 0x2E -- high half of HDAE5000_Str_Chr202D3E
	pushw 23888			; src = 0x5D50 (separator string)		; low half of HDAE5000_Str_Chr202D3E
	pushw 35			; offset = 0x23
	pushw 3706			; dest = 0x0E7A
	call HDAE5000_StrCat			; call 0x29AF0B (strcat)
	inc 0, xsp

.Lpb_no_separator:			; 0x28F000
	; --- Call vtable method at +0x0094 to scan directory ---
	lda xwa, (HDAE5000_Str_Chr2A2E2A:24); XWA = 0x2E5D54 (param)
	ld xde, xwa
	lda xwa, (xsp + 8)		; XWA = &local[0x08]
	ld xbc, xwa
	ld xwa, xde			; restore XWA
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24); XDE = (0x23A1A2)
	ld xde, (xde + WS_HamaFnTable)             ; XDE = (XDE + 0x0E88)
	ld_sril xhl, (xde + HamaFn__findfirst)             ; XHL = (XDE + 0x0094)
	call (xhl)
	ld xiz, xhl			; XIZ = scan result

	; --- Call Directory_Handler for validation ---
	lda xwa, (xsp + 14)		; XWA = &local[0x0E]
	calr HDAE5000_Directory_Handler
	ld (xsp + 4), xhl		; save result

	jr t, .Lpb_validate		; always jump to validation

.Lpb_retry:				; 0x28F02C
	lda xwa, (xsp + 14)
	calr HDAE5000_Directory_Handler
	ld (xsp + 4), xhl

.Lpb_validate:				; 0x28F035
	; --- Call vtable method at +0x0098 (validate/next) ---
	lda xwa, (xsp + 8)		; XWA = &local[0x08]
	ld xbc, xwa
	ld xwa, xiz
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24); XDE = (0x23A1A2)
	ld xde, (xde + WS_HamaFnTable)             ; XDE = (XDE + 0x0E88)
	ld_sril xix, (xde + HamaFn__findnext)             ; XIX = (XDE + 0x0098)
	call (xix)
	cp hl, 0:i3
	jr z, .Lpb_retry		; if HL == 0, retry

	; --- Call vtable method at +0x009C ---
	ld xwa, xiz
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24); XBC = (0x23A1A2)
	ld xbc, (xbc + WS_HamaFnTable)             ; XBC = (XBC + 0x0E88)
	ld_sril xhl, (xbc + HamaFn__findclose)             ; XHL = (XBC + 0x009C)
	call (xhl)

	; --- Directory entry loop ---
	ld iz, 0:i3			; IZ = 0 (loop counter)
	cp iz, (2297458:24); cp IZ, (0x230E72) — entry count
	jrl nc, .Lpb_loop_done		; if IZ >= count, done

.Lpb_entry_loop:			; 0x28F06E
	; Compute entry address: 0x230884 + IZ*9
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 3			; XBC = IZ * 8
	add xbc, xwa			; XBC = IZ * 9
	ld xwa, 2295940			; XWA = 0x00230884
	add xwa, xbc			; XWA = entry address
	push xwa
	lda_dri xwa, 0xfd, 0x16, 0x01	; lda XWA, XSP+0x0116
	push xwa
	call HDAE5000_StrCpy			; call 0x29AF45 (memcpy)

	; Append separator string
	pushw 46			; max = 0x2E -- high half of HDAE5000_Str_TTX
	pushw 23896			; src = 0x5D58		; low half of HDAE5000_Str_TTX
	lda_dri xwa, 0xfd, 0x1e, 0x01	; lda XWA, XSP+0x011E
	push xwa
	call HDAE5000_StrCat			; call 0x29AF0B (strcat)
	lda xsp, (xsp + 16)		; pop 16 bytes

	; --- Call vtable method at +0x00A0 (display entry) ---
	lda_dri xwa, 0xfd, 0x12, 0x01	; lda XWA, XSP+0x0112
	lda xbc, (HDAE5000_Str_Rb_Path_Builder:24); XBC = 0x2E5D5E
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24); XDE = (0x23A1A2)
	ld xde, (xde + WS_HamaFnTable)             ; XDE = (XDE + 0x0E88)
	ld_sril xhl, (xde + HamaFn_fopen_ext)             ; XHL = (XDE + 0x00A0)
	call (xhl)

	; --- Compute entry index * 27, add to base ---
	ld wa, iz
	extz xwa
	ld xbc, 27			; 0x1B
	call HDAE5000_Multiply			; call 0x29B72D (multiply)
	ld xwa, 2296310			; XWA = 0x002309F6
	add xwa, xhl			; XWA = base + IZ*27

	; --- Call vtable method at +0x00A8 ---
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24); XBC = (0x23A1A2)
	ld xbc, (xbc + WS_HamaFnTable)             ; XBC = (XBC + 0x0E88)
	ld_sril xhl, (xbc + HamaFn_fread_ext)             ; XHL = (XBC + 0x00A8)
	ld xbc, 26			; 0x1A
	call (xhl)

	; --- Call vtable method at +0x00AC ---
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); XWA = (0x23A1A2)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_fclose_ext)             ; XHL = (XWA + 0x00AC)
	call (xhl)

	; --- Same pattern: entry address IZ*9, copy, append, display ---
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	add xbc, xwa
	ld xwa, 2295940			; 0x00230884
	add xwa, xbc
	push xwa
	lda_dri xwa, 0xfd, 0x16, 0x01	; lda XWA, XSP+0x0116
	push xwa
	call HDAE5000_StrCpy			; memcpy
	pushw 46
	pushw 23906			; src = 0x5D62		; low half of HDAE5000_Str_MID
	lda_dri xwa, 0xfd, 0x1e, 0x01	; lda XWA, XSP+0x011E
	push xwa
	call HDAE5000_StrCat			; strcat
	lda xsp, (xsp + 16)		; pop 16 bytes

	; --- Call vtable method at +0x00A0 via XIX ---
	lda_dri xwa, 0xfd, 0x12, 0x01	; lda XWA, XSP+0x0112
	lda xbc, (HDAE5000_Str_Rb_Path_Builder_2:24); XBC = 0x2E5D68
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24); XDE = (0x23A1A2)
	ld xde, (xde + WS_HamaFnTable)
	ld_sril xix, (xde + HamaFn_fopen_ext)             ; XIX = (XDE + 0x00A0)
	call (xix)

	; --- Check result and set flag ---
	cp hl, 0:i3
	jr lt, .Lpb_set_zero		; if HL < 0, set 0
	; HL >= 0: set flag to 1
	ld wa, iz
	extz xwa
	ld xbc, 2297418			; XBC = 0x00230E4A
	add xbc, xwa
	ld (xbc), 1			; flag[IZ] = 1
	jr t, .Lpb_entry_next

.Lpb_set_zero:				; 0x28F153
	ld wa, iz
	extz xwa
	ld xbc, 2297418			; XBC = 0x00230E4A
	add xbc, xwa
	ld (xbc), 0			; flag[IZ] = 0

.Lpb_entry_next:			; 0x28F161
	; --- Call vtable method at +0x00AC (advance) ---
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_fclose_ext)
	call (xhl)

	; --- Loop control ---
	inc 1, iz			; IZ++
	cp iz, (2297458:24); cp IZ, (0x230E72)
	jrl c, .Lpb_entry_loop		; if IZ < count, loop

.Lpb_loop_done:				; 0x28F17C
	; --- Call vtable method at +0x053C (finalize) ---
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_WakeUpMainTask)             ; XHL = (XWA + 0x053C)
	call (xhl)

.Lpb_exit:				; 0x28F18D
	; --- Epilogue: return result and deallocate ---
	ld xhl, (xsp + 4)		; XHL = result
	pop xiz				; restore XIZ
	lda_dri xsp, 0xfd, 0x72, 0x01	; lda XSP, XSP+0x0172
	ret

HDAE5000_Directory_Handler:	; 0x28F197 (614 bytes)
	; Directory entry insertion with sorted-position insert logic
	; Calls string format/compare utilities, manages (0x230e72) entry count
	; Max 40 entries (0x28), each 9 bytes in table at 0x230884

	; --- Prologue ---
	lda	xsp, (xsp-100)
	push xiz
	push xwa			; save arg1
	lda xwa, (xsp + 0x3a)
	push xwa
	call HDAE5000_StrCpy			; format string
	lda xwa, (xsp + 0x3e)
	push xwa
	call HDAE5000_StrRev			; parse name
	lda xwa, (xsp + 0x42)
	push xwa
	call HDAE5000_StrUpr			; validate
	pushw 0x0004
	pushw 0x002e
	pushw 0x5d6c		; low half of HDAE5000_Str_XLT
	lda xwa, (xsp + 0x4c)
	push xwa
	call HDAE5000_StrNCmp			; search/match
	add xsp, 0x0000001a		; clean 26 bytes
	cp hl, 0:i3
	jrl nz, .Ldh_ret0

	; Check max entries
	cpw (0x230e72:24), 0x0028
	jr c, .Ldh_under_limit
	ld xhl, 0xffffffff		; return -1 (full)
	jrl t, .Ldh_epilogue

.Ldh_under_limit:
	lda xwa, (xsp + 0x36)
	push xwa
	call HDAE5000_StrRev
	lda xwa, (xsp + 0x3a)
	push xwa
	lda xwa, (xsp + 0x0c)
	push xwa
	call HDAE5000_StrCpy
	lda xwa, (xsp + 0x10)
	push xwa
	call HDAE5000_StrLen			; string compare
	lda xsp, (xsp + 0x10)		; clean 16 bytes
	dec 4, hl
	ld wa, hl
	extz xwa
	lda xbc, (xsp + 0x04)
	add xbc, xwa
	ld (xbc), 0x00		; null-terminate

	; First entry? (count == 0)
	cpw (0x230e72:24), 0x0000
	jr nz, .Ldh_search

	; Direct insert at slot 0
	lda xwa, (xsp + 0x04)
	push xwa
	lda xwa, (0x230884:24)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp			; clean 8 bytes
	incw 1, (0x230e72:24)
	ld xhl, 0:i3
	jrl t, .Ldh_epilogue

	; Sorted insertion search
.Ldh_search:
	ldiw_erp 0xfa, 0		; QIZ = 0 (search index)
	stw_erp wa, 0xfa		; WA = QIZ
	cp wa, (0x230e72:24); compare QIZ with count
	jrl nc, .Ldh_append

.Ldh_search_loop:
	stw_erp wa, 0xfa		; WA = QIZ
	muls wa, 0x0009			; slot offset = QIZ * 9
	lda xbc, (0x230884:24)
	exts xwa
	add xwa, xbc			; XWA = slot address
	push xwa
	lda xwa, (xsp + 0x08)
	push xwa
	call HDAE5000_StrPrefixCmp			; string compare
	inc 0, xsp			; clean 8 bytes
	cp hl, 0:i3
	jr ge, .Ldh_next_slot

	; Found insert position — shift entries down
	ld iz, (0x230e72:24); IZ = total count
	cpw_erp iz, 0xfa		; compare IZ with QIZ
	jr le, .Ldh_do_insert

	; Shift loop: move entries [QIZ..IZ-1] down by one slot
.Ldh_shift_loop:
	ld wa, iz
	muls wa, 0x0009
	lda xbc, (0x23087b:24); offset -9 from table base (src)
	exts xwa
	add xwa, xbc
	push xwa			; source
	ld wa, iz
	muls wa, 0x0009
	lda xbc, (0x230884:24); table base (dst)
	exts xwa
	add xwa, xbc
	push xwa			; destination
	call HDAE5000_StrCpy			; copy 9-byte entry
	inc 0, xsp
	dec 1, iz
	cpw_erp iz, 0xfa
	jr gt, .Ldh_shift_loop

.Ldh_do_insert:
	lda xwa, (xsp + 0x04)
	push xwa
	stw_erp wa, 0xfa
	muls wa, 0x0009
	lda xbc, (0x230884:24)
	exts xwa
	add xwa, xbc
	push xwa
	call HDAE5000_StrCpy			; copy entry to insert position
	inc 0, xsp
	incw 1, (0x230e72:24)
	ld xhl, 0:i3
	jr t, .Ldh_epilogue

.Ldh_next_slot:
	inc1w_erp 0xfa			; QIZ++
	stw_erp wa, 0xfa
	cp wa, (0x230e72:24)
	jrl c, .Ldh_search_loop

	; Append at end (no sorted position found)
.Ldh_append:
	lda xwa, (xsp + 0x04)
	push xwa
	ld wa, (0x230e72:24)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	add xbc, xwa
	ld xwa, 0x00230884
	add xwa, xbc
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp
	incw 1, (0x230e72:24)
	ld xhl, 0:i3
	jr t, .Ldh_epilogue

.Ldh_ret0:
	ld xhl, 0:i3
.Ldh_epilogue:
	pop xiz
	lda xsp, (xsp + 0x64)		; restore stack (+100)
	ret

	; ============================================================
	; Event code matcher — check for 0x01E0009F
	; ============================================================
	; Firmware's own name: HDAE5000_ObjHandler_Table entry 64 is 0x28F2F7
	; and the parallel HDAE5000_ObjName_Table entry points at 0x29BB48 =
	; "LanguageTextReturn".  0x2E5D72 is a table of six 32-bit pointers to
	; the nine-character language-text names "LANENG001" (0x2E5DBC),
	; "LANDEU002" (0x2E5DB2), "LANFRA003" (0x2E5DA8), "LANENG004"
	; (0x2E5D9E), "LANENG005" (0x2E5D94) and "LANENG006" (0x2E5D8A).
	; [INFERENCE] they read as file stems: ".TTX", ".MID" and "XLT." sit a
	; few bytes earlier.  Nothing here concerns directories: the old name
	; Dir_Event_Check was a misnomer.
HDAE5000_LanguageTextReturn:	; 0x28F2F7
	cp xbc, 0x01e0009f
	jr nz, .Ldec_no
	lda xhl, (HDAE5000_TextPtrs_LANENG001_to_LANENG006:24)
	ret
.Ldec_no:
	ld xhl, 0:i3
	ret

	; ============================================================
	; Format + ROM region setup helper
	; ============================================================
HDAE5000_PPORT_Svc28_FlashXapFile:	; 0x28F308
	; PC-link service 28 (HDAE5000_PPORT_ServiceTable[28]; no trace banner):
	; builds a descriptor on the stack -- "XAP" (0x2E5DC6), XBC, 0x280000,
	; 0x2F0000 (this ROM's own range) -- and calls RAM 0x23FEB0 with it;
	; command 20 is "Send XapFile flash".  Nothing in this ROM puts code at
	; 0x23FEB0, so what runs there is not established here.
	lda	xsp, (xsp-24)
	push xiz
	ld xiz, xbc			; save XBC in XIZ
	ld (xsp + 0x18), xwa		; save arg1
	pushw 0x002e
	pushw 0x5dc6		; low half of HDAE5000_Str_XAP
	lda xwa, (xsp + 0x08)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp
	ld (xsp + 0x08), xiz		; store XIZ to stack
	ld xwa, 0x00280000
	ld (xsp + 0x14), xwa
	ld xwa, 0x002f0000
	ld (xsp + 0x0c), xwa
	ld xwa, (xsp + 0x18)
	ld xbc, (xsp + 0x04)
	call 0x23feb0
	pop xiz
	lda xsp, (xsp + 0x18)
	ret

	; ============================================================
	; Vtable helper: call method 0x0538 (flush), return HL=0
	; ^ "flush" is not established: see the header below.
	; ============================================================
HDAE5000_PPORT_Svc29_MainHook0538:		; 0x28F343
	; PC-link service 29: call the main-CPU hook 0x0E0A table +0x538 -- the
	; one HDAE5000_LoadSong/SaveSong call before a long operation when their
	; UI flag is 1 -- and return HL = 0.
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld XHL, (xwa + RootFn_SleepMainTask)             ; method 0x0538
	call (xhl)
	ld hl, 0:i3
	ret

	; ============================================================
	; Vtable helper: call method 0x053C (close), return HL=0
	; ^ "close" is not established: see the header below.
	; ============================================================
HDAE5000_PPORT_Svc30_MainHook053C:		; 0x28F357
	; PC-link service 30: the matching +0x53C hook (called after the
	; operation); HL = 0.
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld XHL, (xwa + RootFn_WakeUpMainTask)             ; method 0x053C
	call (xhl)
	ld hl, 0:i3
	ret

	; ============================================================
	; Variable-length integer encoder (MIDI-style VarInt)
	; Encodes a 32-bit value using 7-bit chunks, MSB-first.
	; Format: bit 7 = 1 means "more bytes follow" (continuation)
	;         bit 7 = 0 means "this is the last byte"
	; Example: 389 (0x185) → [0x83, 0x05]
	;   0x83 = 1_0000011 (cont=1, payload=3)
	;   0x05 = 0_0000101 (cont=0, payload=5)
	;   Decoded: (3 << 7) | 5 = 389
	; Max 5 bytes for 32-bit values (5 × 7 = 35 bits)
	; Algorithm: Extract 7-bit chunks LSB-first into temp buffer,
	;   then reverse into output setting bit 7 on all but last
	; Input: XWA = value to encode, XBC = output buffer pointer
	; Output: XHL = number of bytes written (1-5)
	; ============================================================
HDAE5000_VarInt_Encode:		; 0x28F36B
	dec 6, xsp			; allocate 6-byte temp buffer
	ld xix, xwa			; XIX = value to encode
	ld hl, 0:i3			; HL = byte count

	; --- Phase 1: Extract 7-bit chunks LSB-first into temp buffer ---
.Lve_extract:
	lda xde, (xsp + 0x00)		; XDE = temp buffer base on stack
	ld xwa, xix
	and xwa, 0x0000007f		; extract low 7 bits of remaining value
	stb_dri a, 0x07, 0xe8, 0xec	; temp[HL] = A (store 7-bit chunk)
	srl xix, 7			; shift remaining value right by 7
	inc 1, hl			; HL = chunk count
	or xix, xix			; any bits left?
	jr nz, .Lve_extract		; loop until value fully consumed

	; --- Phase 2: Reverse chunks into output, set continuation bits ---
	; temp[] has chunks in LSB-first order; output needs MSB-first
	ld ix, 1:i3			; IX = reverse index (skip first temp byte)
	cp ix, hl			; only one chunk? skip to last
	jr ge, .Lve_copy_last

.Lve_set_msb:
	ld wa, hl
	sub wa, ix			; WA = count - reverse_index
	ld de, wa
	dec 1, de			; DE = output position
	lda xwa, (xsp + 0x00)
	ldb_sri a, 0x07, 0xe0, 0xf0	; A = temp[IX] — load chunk (MSB-first order)
	set 7, a			; set continuation bit (more bytes follow)
	stb_dri a, 0x07, 0xe4, 0xe8	; output[DE] = A — store to caller's buffer
	inc 1, ix
	cp ix, hl
	jr lt, .Lve_set_msb

	; --- Phase 3: Copy final byte WITHOUT continuation bit ---
.Lve_copy_last:
	ld de, hl
	dec 1, de			; DE = last output position
	ld8_src_rid8 xsp, 0x00, a		; A = temp[0] — LSB chunk (becomes last output byte)
	stb_dri a, 0x07, 0xe4, 0xe8	; output[DE] = A (bit 7 clear = final byte)
	exts xhl			; sign-extend HL to XHL (byte count)
	inc 6, xsp			; free temp buffer
	ret

	; ============================================================
	; Variable-length integer decoder (MIDI-style VarInt)
	; Reads MSB-first 7-bit chunks; bit 7 = 1 means "more bytes"
	; Max 5 bytes (35 bits). Returns -1 if encoding is invalid.
	; Input: XWA = data pointer, XBC = output byte count pointer
	; Output: XHL = decoded value, or 0xFFFFFFFF on error
	; Side effect: stores bytes consumed to (XBC)
	; ============================================================
HDAE5000_VarInt_Decode:		; 0x28F3BD
	ld xde, xwa			; XDE = data pointer
	ld ix, 0:i3			; IX = byte index
	ld xhl, 0:i3			; XHL = accumulator

	ld a, (xde)			; A = first byte (for length check)
	ldb_erp a, 0xf4		; IYL = A (save first byte)

.Lvd_loop:
	ldb_sri a, 0x07, 0xe8, 0xf0	; A = data[IX] — load current byte
	res 7, a			; strip continuation bit → 7-bit payload
	ld w, 0:opc			; W = 0
	extz xwa			; XWA = payload (zero-extended to 32-bit)
	add xhl, xwa			; accumulate: XHL += payload

	bit_dri 7, 0x07, 0xe8, 0xf0	; test continuation bit of data[IX]
	jr nz, .Lvd_continue
	; Continuation=0 → this was the last byte, decoding complete
	stb_erp a, 0xf0		; A = IXL (byte index)
	inc 1, a			; A = bytes consumed
	ld (xbc), a			; store byte count to caller's pointer
	ret

.Lvd_continue:
	; Continuation=1 → more bytes follow
	inc 1, ix			; advance to next byte
	sll xhl, 7			; make room for next 7-bit chunk
	cp ix, 4:i3
	jr le, .Lvd_length_check
	cpib_erp 0xf4, 7		; if first byte > 7 and >4 bytes: invalid
	jr ugt, .Lvd_error

.Lvd_length_check:
	cp ix, 5:i3			; max 5 bytes (35 bits for 32-bit values)
	jr le, .Lvd_loop

.Lvd_error:
	ld xhl, 0xffffffff		; return -1 (invalid VarInt encoding)
	ret

HDAE5000_Filename_Validate:	; 0x28F3FD (59 bytes)
	; Unpack 32-bit value by extracting each byte, shifting and combining
	; Like String_To_Upper but processes all 4 bytes unconditionally
	; Input: XWA = packed 32-bit value
	; Output: XHL = combined result
	ld xbc, xwa
	ld xhl, xbc
	and xhl, 0x000000FF
	srl xbc, 8
	sll xhl, 8
	ld xwa, xbc
	and xwa, 0x000000FF
	add xhl, xwa
	srl xbc, 8
	sll xhl, 8
	ld xwa, xbc
	and xwa, 0x000000FF
	add xhl, xwa
	srl xbc, 8
	sll xhl, 8
	ld xwa, xbc
	and xwa, 0x000000FF
	add xhl, xwa
	ret

HDAE5000_Extension_Check:	; 0x28F438 (153 bytes)
	; Byte-swap helper: swap high/low bytes of WA, return in HL
	; Input: WA = 16-bit value
	; Output: HL = byte-swapped result
	ld hl, wa			; HL = WA
	ld h, 0x00:opc			; clear H (keep L = low byte of WA)
	srl wa, 8			; WA >>= 8 (high byte to low)
	sll hl, 8			; HL <<= 8 (low byte to high)
	ld w, 0x00:opc			; clear W
	add hl, wa			; HL = (orig_low << 8) + orig_high
	ret
.Lec_main:				; 0x28F447 — extension check entry
	push xiz
	ld xiz, xwa			; save parameter in XIZ
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2) — workspace ptr
	ld xwa, (xwa + WS_HamaFnTable)             ; ld XWA, (XWA+0x0E88) — handler table
	ld xix, (xwa + HamaFn_GetMediaType)		; ld XIX, (XWA+0x08)
	call (xix)			; call validation handler
	cp l, 3:i3			; check result == 3?
	jr z, .Lec_process		; if so, process extension
	cp l, 2:i3			; check result == 2?
	jr nz, .Lec_finish		; if neither 2 nor 3, skip to end
.Lec_process:
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2)
	ld xwa, (xwa + WS_RootFnTable)             ; ld XWA, (XWA+0x0E0A) — sub-handler table
	ld xhl, (xwa + RootFn_SleepMainTask)             ; ld XHL, (XWA+0x0538)
	call (xhl)
	ld xwa, xiz			; restore parameter
	lda xbc, (HDAE5000_Str_Rb_Extension_Check:24); lda XBC, 0x2E5DCA — extension data ptr
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24); ld XDE, (0x23A1A2)
	ld xde, (xde + WS_HamaFnTable)             ; ld XDE, (XDE+0x0E88)
	ld_sril xhl, (xde + HamaFn_fopen_ext)             ; ld XHL, (XDE+0x00A0)
	call (xhl)
	lda xwa, (0x230eac:24); lda XWA, 0x230EAC
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24); ld XBC, (0x23A1A2)
	ld xbc, (xbc + WS_HamaFnTable)             ; ld XBC, (XBC+0x0E88)
	ld_sril xhl, (xbc + HamaFn_fread_ext)             ; ld XHL, (XBC+0x00A8)
	ld xbc, 0x0000000E		; count = 14
	call (xhl)
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2)
	ld xwa, (xwa + WS_HamaFnTable)             ; ld XWA, (XWA+0x0E88)
	ld_sril xhl, (xwa + HamaFn_fclose_ext)             ; ld XHL, (XWA+0x00AC)
	call (xhl)
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2)
	ld xwa, (xwa + WS_RootFnTable)             ; ld XWA, (XWA+0x0E0A)
	ld xhl, (xwa + RootFn_WakeUpMainTask)             ; ld XHL, (XWA+0x053C)
	call (xhl)
.Lec_finish:
	lda xwa, (0x230eac:24); lda XWA, 0x230EAC
	calr HDAE5000_Config_Init	; validate config
	pop xiz
	ret

HDAE5000_Config_Init:	; 0x28F4D1 (114 bytes)
	; Initialize configuration: validate filename, check headers, verify extensions
	; Input: XWA = pointer to config data structure (XIZ-indexed fields)
	; Output: XHL = 0 success, -1..-4 error codes
	push xiz
	ld xiz, xwa			; save config ptr in XIZ
	ld xwa, (xiz)			; load filename pointer (field 0x00)
	calr HDAE5000_Filename_Validate
	cp xhl, 0x4D546864		; check magic "MThd" (MIDI header, reversed)
	jr z, .Lci_check1
	ld xhl, 0xFFFFFFFF		; return -1 (invalid magic)
	jr t, .Lci_exit
.Lci_check1:
	ld xwa, (xiz + 4)		; load field at offset 0x04
	calr HDAE5000_Filename_Validate
	cp xhl, 0x00000006		; check header size = 6
	jr z, .Lci_check2
	ld xhl, 0xFFFFFFFE		; return -2 (wrong header size)
	jr t, .Lci_exit
.Lci_check2:
	ld wa, (xiz + 8)		; load 16-bit field at offset 0x08
	calr HDAE5000_Extension_Check
	ld (0x230eba:24), hl; ld (0x230EBA), HL
	cpw (2297530:24), 0x0001; cp (0x230EBA), 1
	jr ule, .Lci_check3		; if <= 1, continue
	ld xhl, 0xFFFFFFFD		; return -3
	jr t, .Lci_exit
.Lci_check3:
	ld wa, (xiz + 10)		; load field at offset 0x0A
	calr HDAE5000_Extension_Check
	ld (0x230ebc:24), hl; ld (0x230EBC), HL
	ld wa, (xiz + 12)		; load field at offset 0x0C
	calr HDAE5000_Extension_Check
	ld (0x230ebe:24), hl; ld (0x230EBE), HL
	ld wa, (0x230ebe:24); ld WA, (0x230EBE)
	bit 15, wa			; test bit 15
	jr z, .Lci_ok			; if not set, success
	ld xhl, 0xFFFFFFFC		; return -4
	jr t, .Lci_exit
.Lci_ok:
	ld xhl, 0:i3			; return 0 (success)
.Lci_exit:
	pop xiz
	ret

HDAE5000_Alloc_Memory:	; 28F543h
	; Bitmap resource descriptor for the boot splash screen.
	; (Despite the name it allocates nothing: it is a constant lookup, the
	;  fifth of five identical descriptors -- 0x28030E/0x28033B/0x280368/
	;  0x280395 describe the Logo, Hands, FilePanel and Icon bitmaps.)
	; Input: XBC = request type (0x01E000A1, A2, or A3)
	; Output: XHL = result based on type:
	;   A1 -> 0x2E61CE (HDAE5000_Bitmap_BootSplash bitmap data, NOT a palette)
	;   A2 -> 0x140 (320 decimal - bitmap width)
	;   A3 -> 0xF0 (240 decimal - bitmap height)
	;   else -> 0 (invalid type)
	; A2/A3 give the splash geometry as 320 x 240; at 8bpp that is 76,800
	; bytes, which agrees with both the 2 x 0x9600 VRAM copy in Boot_Init
	; and the exact fill of 0x2E61CE-0x2F8DCD.  A2/A3 read as raster
	; dimensions for the other descriptors too: 0x280395 answers 0x1B/0x1B
	; and hdae5000_data_tables.s shows HDAE5000_Bitmap_HddIcon is 27 x 27
	; @ 8bpp with a 28-byte row stride (756 B, the .incbin length there).
	; The "784-byte icon / 28 x 28" reading recorded here earlier came from
	; an extraction that over-reads 28 bytes into HDAE5000_Config_Strings.
	cp xbc, 0x1E000A3	; Check for type A3
	jr z, HDAE5000_Alloc_Memory__type_A3
	cp xbc, 0x1E000A2	; Check for type A2
	jr z, HDAE5000_Alloc_Memory__type_A2
	cp xbc, 0x1E000A1	; Check for type A1
	jr z, HDAE5000_Alloc_Memory__type_A1
	ld xhl, 0:i3	; Invalid type - return 0
	ret
HDAE5000_Alloc_Memory__type_A1:
	lda xhl, (0x2e61ce:24); Return HDAE5000_Bitmap_BootSplash bitmap address
	ret
HDAE5000_Alloc_Memory__type_A2:
	ld xhl, 0x140	; Return 320 (width)
	ret
HDAE5000_Alloc_Memory__type_A3:
	ld xhl, 0xF0	; Return 240 (height)
	ret

HDAE5000_Get_Init_Flag:	; 28F570h
	; Returns HD presence flag in L
	; Output: L = value from HDAE5000_INIT_FLAG (0x230EDA)
	ld l, (HDAE5000_RAM_HdPresent:24)
	ret

; ============================================================================
; BOOT INITIALIZATION ROUTINE (0x28F576 - 0x28F661)
; Called once at startup when HDAE5000 is detected via header validation
;
; Input: XWA = workspace structure pointer from main CPU
; Output: L = HD presence flag (stored at 0x230EDA)
;
; This routine:
;   1. Clears work buffer (0xF52A bytes at 0x22A000)
;   2. Registers handlers with main CPU via callback at 0x280020
;   3. Loads the VGA palette HDAE5000_Palette_Data (ROM 0x2E5DCE)
;   4. Blits HDAE5000_Bitmap_BootSplash (ROM 0x2E61CE, 320x240x8bpp = 0x12C00
;      bytes) INTO VRAM at 0x1A0000, as two contiguous 0x9600-byte copies
;   5. Initializes handler function pointers at 0x230ECC/ED2/ED6
;   6. Checks for HD presence via 0x2971A3
;   7. Registers frame handler callback via 0x2803C2
;
; Key addresses called:
;   0x28F785 - Clear work buffer
;   0x280020 - Handler registration (code section 1)
;   0x28F8E0 - Load palette
;   0x28F543 - Memory allocation (code section 1)
;   0x29AE9F - Memory copy
;   0x2971A3 - Check HD present
;   0x28F90B - Finalize init
;   0x2803C2 - Register frame handler (code section 1)
; ============================================================================

; RAM variable addresses
.equ HDAE5000_WORKSPACE_PTR, 0x23A1A2
.equ HDAE5000_HANDLER_1, 0x230ECC
.equ HDAE5000_HANDLER_2, 0x230ED2
.equ HDAE5000_HANDLER_3, 0x230ED6
.equ HDAE5000_INIT_FLAG, 0x230EDA

; Handler registration data addresses (used by HDAE5000_Handler_Registration)
	; (EQU→inline label) HDAE5000_RECORD_COUNT = 0x29D97E
	; (EQU→inline label) HDAE5000_RECORD_TABLE = 0x29C0AA
					; Records: SelectList, DbMemoCl, TtlScreenR, AcHddNamingWindow,
					; IvHddNaming, HDTitleMenu, TtlScreenR2, TtlScreenR3,
					; AcWindowPage1, IvScreenR2, AcLanguageText1, LyricBox, FDFileSelect
.equ HDAE5000_RAM_DATA_A_SIZE, 0x239822	; Size word for RAM data area A (variable)
.equ HDAE5000_RAM_DATA_A, 0x2397EA	; RAM data area A
.equ HDAE5000_RAM_DATA_B_SIZE, 0x239870	; Size word for RAM data area B (variable)
.equ HDAE5000_RAM_DATA_B, 0x239824	; RAM data area B
.equ HDAE5000_DATA_COPY_DEST, 0x23952A	; Init data copy destination
.equ HDAE5000_INIT_DATA_2, 0x239642	; Init data area (secondary)
.equ HDAE5000_SERIAL_DATA_1, 0x239872	; Serial port data (primary)
.equ HDAE5000_SERIAL_DATA_2, 0x2398AA	; Serial port data (secondary)
.equ HDAE5000_PARALLEL_DATA_1, 0x239FD2	; Parallel port data (primary)
.equ HDAE5000_PARALLEL_DATA_2, 0x23A00E	; Parallel port data (secondary)
	; (EQU→inline label) HDAE5000_UiObject_PtrTable = 0x2A5D2C
	; (EQU→inline label) HDAE5000_UiObjectName_PtrTable = 0x2A6984
	; (EQU→inline label) HDAE5000_GFX_INIT_PARAMS = 0x2A849A

; ROM data addresses
	; (EQU→inline label) HDAE5000_Palette_Data = 0x2E5DCE
	; (EQU→inline label) HDAE5000_Bitmap_BootSplash = 0x2E61CE
	; (EQU→inline label) HDAE5000_Display_Params = 0x2F8DCE

; All routine addresses are now exposed as labels in split binary sections

; PPORT state machine handler (in code_28f90c_2953e1.bin)
	; (EQU→inline label) HDAE5000_PPORT_ServicePending = 0x29501C

; PPORT command handler addresses (in code_295642_2fffff.bin)
	; (EQU→inline label) HDAE5000_PPORT_Cmd06_WriteFsbToHd = 0x2958D6
	; (EQU→inline label) HDAE5000_PPORT_Cmd07_LoadHdToMemory = 0x295914
	; (EQU→inline label) HDAE5000_PPORT_Cmd08_SendDataToPc = 0x2959F6
	; (EQU→inline label) HDAE5000_PPORT_Cmd09_SendFilesToPc = 0x295D3C
	; (EQU→inline label) HDAE5000_PPORT_Cmd10_RcvDataFromPc = 0x29605A
	; (EQU→inline label) HDAE5000_PPORT_Cmd11_SaveMemoryToHd = 0x296294
	; (EQU→inline label) HDAE5000_PPORT_Cmd12_Nothing = 0x29632A
	; (EQU→inline label) HDAE5000_PPORT_Cmd13_RcvDataFromPc = 0x29633C
	; (EQU→inline label) HDAE5000_PPORT_Cmd14_SendInfosToPc = 0x2964A6
	; (EQU→inline label) HDAE5000_PPORT_Cmd15_Nothing = 0x296588
	; (EQU→inline label) HDAE5000_PPORT_Cmd16_DeleteFiles = 0x29659A
	; (EQU→inline label) HDAE5000_PPORT_Cmd17_FormatHd = 0x296680

HDAE5000_Boot_Init:	; 28F576h
	push xiz
	ld xiz, xwa	; XIZ = workspace pointer from main CPU

	calr HDAE5000_Clear_Work_Buffer	; Clear 0xF52A bytes at 0x22A000

	ld (HDAE5000_RAM_MainWorkspacePtr:24), xiz; Store workspace pointer

	call HDAE5000_Handler_Registration	; Register handlers with main CPU

	lda xwa, (0x2e5dce:24); HDAE5000_Palette_Data
	calr HDAE5000_Load_Palette	; Load 256-entry VGA palette

	; === Blit the boot splash screen into VRAM ===
	; Fetch the splash bitmap's ROM address from its resource descriptor
	ld xwa, 0:i3
	ld xbc, 0x1E000A1	; Resource query A1 = bitmap data address
	ld xde, 0:i3
	calr HDAE5000_Alloc_Memory	; Returns 0x2E61CE in XHL
	ld xiz, xhl	; XIZ = HDAE5000_Bitmap_BootSplash

	; Copy rows 0-119 of the splash to VRAM (0x1A0000, size 0x9600)
	pushw 0x9600	; push 9600h (16-bit immediate)
	ld xwa, xiz
	push xwa	; Source = HDAE5000_Bitmap_BootSplash
	ld xwa, 0x1A0000	; Destination
	push xwa
	call HDAE5000_MemCopy

	; Copy rows 120-239 to the contiguous VRAM continuation (0x1A9600).
	; Two calls only because MemCopy's length is a 16-bit push and the
	; bitmap is 0x12C00 bytes; the destinations are adjacent.
	pushw 0x9600	; push 9600h (16-bit immediate)
	ld xwa, xiz
	add xwa, 0x9600	; Source + half the bitmap
	push xwa
	ld xwa, 0x1A9600	; Destination
	push xwa
	call HDAE5000_MemCopy

	lda xsp, (xsp + 20)	; Clean stack (5 pushes × 4 bytes = 20)

	; === Create DISK MENU slot ===
	; RootFn_GetViewInstance(0x00600002) returns XHL = that object's instance
	; record, which the code below fills (id 0x016A0005 at +0, name at +0x2A);
	; technics-docs (hdae5000-homebrew.md) reads it as the DISK MENU slot.
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)             ; Handler table A
	ld XIX, (xwa + RootFn_GetViewInstance)
	ld xwa, 0x600002	; Menu group ID
	call (xix)	; Returns XHL = slot pointer
	;
	; Set slot+0x00 = 0x016A0005
	;   0x016A = handler ID (registered above via RegisterObjectTable)
	;   0x0005 = sub-object index (Record 5 = "HDTitleMenu" in data table)
	ld xwa, 0x16A0005
	ld (xhl), xwa	; Link DISK MENU entry to handler 0x016A, record 5
	;
	; Set slot+0x2A = display name string pointer
	;   Points to "HD-AE5000\0" at ROM address 0x2F8DCE
	lda xwa, (0x2f8dce:24)
	ld (xhl + 42), xwa	; Display name shown in DISK MENU
	;
	; NOTE: slot+0x32 (icon ID) is NOT set here.
	; The firmware uses a default icon for HDAE5000.

	; === Addresses of three main-CPU sequencer variables ===
	; WS_HamaFnTable (workspace + 0x0E88) functions GetAdr_sqsrtc / _sqbtof /
	; _sq_beadt each return the address of one main-CPU RAM variable (the v10
	; code: lda xhl,(0x0421) / (0x041C) / (0x041B); ret).  HDAE5000_Frame_Handler
	; reads them every frame: sqsrtc bit 2, and the song position.
	;
	; &sqsrtc -> HDAE5000_RAM_SqSrtcPtr
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_HamaFnTable)             ; Handler table B
	ld XHL, (xwa + HamaFn_GetAdr_sqsrtc)             ; Get callback via table B offset +0x0108
	call (xhl)
	ld (HDAE5000_RAM_SqSrtcPtr:24), xhl; Store at 0x230ECC

	; &sqbtof -> HDAE5000_RAM_SqBtofPtr
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_HamaFnTable)
	ld_sril XHL, (xwa + HamaFn_GetAdr_sqbtof)             ; Table B offset +0x0100
	call (xhl)
	ld (HDAE5000_RAM_SqBtofPtr:24), xhl; Store at 0x230ED2

	; &sq_beadt -> HDAE5000_RAM_SqBeadtPtr
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_HamaFnTable)
	ld XHL, (xwa + HamaFn_GetAdr_sq_beadt)             ; Table B offset +0x0104
	call (xhl)
	ld (HDAE5000_RAM_SqBeadtPtr:24), xhl; Store at 0x230ED6

	; Check for hard disk presence
	call HDAE5000_Check_HD_Present
	ld (HDAE5000_RAM_HdPresent:24), l; Store result

	cp l, 0:i3
	jr z, HDAE5000_Boot_Init__skip_hd_init	; Skip if no HD

	; Hard disk present - initialize it
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld XHL, (xwa + RootFn_ApPostEvent)             ; drive present: go to the HD title
	ld xwa, 0xFFFFFFFF	; object 0xFFFFFFFF, as the main CPU's own title requests
	ld xbc, 0x1C00016	; event 0x01C00016 (see HDAE5000_RequestTitle15)
	ld xde, 0x1A0007F	; title 0x7F, "TT_HDDEXT"
	call (xhl)

HDAE5000_Boot_Init__skip_hd_init:
	call HDAE5000_Finalize_Init	; Final setup
	call HDAE5000_UiState_Reset	; Register frame handler

	pop xiz
	ret

; ============================================================================
; CODE SECTION 2 PART A (0x28F662 - 0x2953E1)
; Frame handler and utility routines before PPORT command table
;
; Key routines in this section:
;   0x28F662  Frame_Handler - Main frame handler entry
;   0x28F781  Frame_Handler_Exit - JP to PPORT handler
;   0x28F785  Clear_Work_Buffer - Clear work area, copy init data
;   0x28F7DD  Delay_Loop - Timing utility
;   0x28F7EE  VGA_Port_Write - Write to VGA DAC registers
;   0x28F813  Palette_Setup - Configure single palette entry
;   0x28F8E0  Load_Palette - Load all 256 palette entries
;   0x28F90B  Finalize_Init - Just returns (stub)
;   0x28F90C  Display_Init - Display initialization
; ============================================================================

HDAE5000_Frame_Handler:	; 28F662h
	; Frame handler main entry - called periodically from main loop
	; 1. While a lyric box is open (HDAE5000_RAM_LyricBoxObj != -1): read the
	;    main CPU's sequencer position through the pointers HDAE5000_Boot_Init
	;    fetched (HamaFn_GetAdr_sqbtof / _sq_beadt), LyricPosition = sqbtof * 12
	;    + (sq_beadt >> 3) + 2, and when (sq_beadt >> 3) + 1 changed, post
	;    RootFn_ApPostEvent(lyric box, 0x01CA0004, &HDAE5000_RAM_LyricPosEvt) --
	;    the event on which HDAE5000_LyricBoxProc runs
	;    HDAE5000_Lyrics_PlayToPosition.
	; 2. (_Status) When bit 2 of the main CPU's sqsrtc byte falls to 0 and
	;    HDAE5000_Get_Status_Byte is 1: on the HD title (GetTitleNow ==
	;    0x01A0007F) post the file-load events, else HDAE5000_RequestTitle15(0x7F).
	;
	ld xwa, (HDAE5000_RAM_LyricBoxObj:24); the open lyric box, or -1
	cp xwa, 0xFFFFFFFF	; no lyric box open?
	jr z, HDAE5000_Frame_Handler_Status	; then nothing to advance
	;
	; song position from the main CPU's sequencer variables
	ld xwa, (HDAE5000_RAM_SqBeadtPtr:24); &sq_beadt
	ld a, (xwa)	; Read state byte
	srl a, 3	; srl 3, A  ; divide by 8
	ld e, a	; Save in E
	;
	ld xwa, (HDAE5000_RAM_SqBtofPtr:24); &sqbtof
	ld wa, (xwa)	; sqbtof
	extz xwa	; Zero-extend to 32-bit
	ld xbc, xwa	; XBC = state value
	add xbc, xbc	; XBC *= 2
	add xbc, xwa	; XBC *= 3 (total: state * 3)
	sll xbc, 2	; sll 2, XBC  ; XBC *= 4 (total: state * 12)
	ld xwa, 0:i3	; Clear XWA
	ld a, e	; Restore shifted value
	inc 2, xwa	; inc 2, XWA  ; Add 2 (?) to low word
	add xwa, xbc	; Combine offsets
	ld (HDAE5000_RAM_LyricPosition:24), xwa; LyricPosition = sqbtof * 12 + (sq_beadt >> 3) + 2
	;
	; Check if state changed
	inc 1, e	; inc 1, E
	ld a, e
	extz wa
	cp wa, (HDAE5000_RAM_LyricPosStep:24); same step as at the last post?
	jr z, HDAE5000_Frame_Handler_Status	; Skip if unchanged
	;
	; new step: post event 0x01CA0004 to the lyric box
	ld a, e
	extz wa
	ld (HDAE5000_RAM_LyricPosStep:24), wa; LyricPosStep = (sq_beadt >> 3) + 1
	ld xwa, (HDAE5000_RAM_SqBtofPtr:24); &sqbtof
	ld wa, (xwa)	; sqbtof
	ld (HDAE5000_RAM_LyricPosEvt:24), wa; LyricPosEvt +0 = sqbtof
	lda xwa, (HDAE5000_RAM_LyricPosEvt:24); the parameter block
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_LyricBoxObj:24); the lyric box
	ld xde, xbc	; XDE = &LyricPosEvt
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24); Main workspace pointer
	ld XBC, (xbc + WS_RootFnTable)             ; Handler table A
	ld XHL, (xbc + RootFn_ApPostEvent)
	ld xbc, 0x1CA0004	; event 0x01CA0004: advance the lyrics
	call (xhl)	; RootFn_ApPostEvent

HDAE5000_Frame_Handler_Status:	; 28F6E0h
	; Frame handler status check section
	; Watches bit 2 of the main CPU's sqsrtc byte; acts when it falls to 0
	;
	ld xwa, (HDAE5000_RAM_SqSrtcPtr:24); &sqsrtc
	ld a, (xwa)	; Read status byte
	and a, 0x4	; Isolate bit 2
	cp a, (HDAE5000_RAM_SqSrtcBit2Prev:24); Compare with previous state
	jrl z, HDAE5000_Frame_Handler_Exit	; jrl Z, Frame_Handler_Exit  ; Skip if unchanged
	;
	; Status changed - update previous state
	ld (HDAE5000_RAM_SqSrtcBit2Prev:24), a; Store new state
	cp a, 0:i3	; Check if bit 2 now clear
	jrl nz, HDAE5000_Frame_Handler_Exit	; jrl NZ, Frame_Handler_Exit  ; Skip if bit still set
	;
	; Bit 2 cleared - check if display init needed
	call HDAE5000_Get_Status_Byte	; Call status check routine
	cp l, 1:i3	; Check return value
	jr nz, HDAE5000_Frame_Handler_Exit	; Skip if not 1
	;
	; Initialize display - call workspace callback
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); Main workspace pointer
	ld XWA, (xwa + WS_RootFnTable)             ; Handler table A
	ld XIX, (xwa + RootFn_GetTitleNow)             ; Get display callback
	call (xix)	; Call if valid
	cp xhl, 0x1A0007F	; Check return value
	jr z, HDAE5000_Frame_Handler_Status__init_display	; If match, do full init
	;
	; Partial update
	ld wa, 1:i3
	call HDAE5000_Set_Status_Byte	; Call update routine
	ldw wa, 0x7F
	call HDAE5000_RequestTitle15	; Call UI update
	jr HDAE5000_Frame_Handler_Exit
	;
HDAE5000_Frame_Handler_Status__init_display:
	; Full display initialization sequence
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld XHL, (xwa + RootFn_ApPostEvent)             ; Init callback 1
	ld xwa, HDAE5000_OBJ_FLS_FILE_LOAD_SW_EDIT	; Display params
	ld xbc, 0x1C00001	; Display initialization flags
	ld xde, 0:i3
	call (xhl)
	;
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld XHL, (xwa + RootFn_DeleteEvent)             ; Init callback 2
	ld xwa, HDAE5000_OBJ_FLS_FILE_LOAD_SW_EDIT
	ld xbc, 0x1CA0000
	call (xhl)
	;
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld XHL, (xwa + RootFn_ApPostEvent)             ; Init callback 3
	ld xwa, HDAE5000_OBJ_FLS_FILE_LOAD_SW_EDIT
	ld xbc, 0x1CA0000
	ld xde, 0:i3
	call (xhl)

HDAE5000_Frame_Handler_Exit:	; 28F781h
	; Exit frame handler by jumping to PPORT handler
	jp HDAE5000_PPORT_ServicePending

; ----------------------------------------------------------------------------
; Utility routines (0x28F785 - 0x2953E1)
; ----------------------------------------------------------------------------

HDAE5000_Clear_Work_Buffer:	; 28F785h
	; Clear work buffer and copy initialization data from ROM
	; Part 1: Clear 0xF52A bytes (62,762) at 0x22A000 using word operations
	; Part 2: Copy 0x0C82 bytes (3,202) from ROM 0x2F94B2 to RAM 0x23952A
	;
	; Uses LDIRW for word block copy, LDIR for byte copy
	; Handles large counts via QBC (high word of XBC) loop
	;
	; === Part 1: Clear work buffer ===
	ld xde, 0x22A000	; Destination = work buffer
	ld xbc, 0xF52A	; Count = 62,762 bytes
	ld ix, bc	; Save low word for odd byte check
	srl xbc, 1	; srl 1, XBC  ; divide by 2 for word ops
	jr z, HDAE5000_Clear_Work_Buffer__clear_done	; Skip if count was 0 or 1
	ld xhl, xde	; Source = destination (for LDIRW)
	stiw_dsp 0xE9, 0x00, 0x00	; ld (XDE+), 0x0000  ; store first word
	dec 1, xbc	; dec 1, XBC
	or xbc, xbc
	jr z, HDAE5000_Clear_Work_Buffer__clear_done
	mriw2 0x93, 0x11	; ldirw  ; copy words (fills with zeros)
	cpiw_erp 0xE6, 0	; cp QBC, 0  ; check high word
	jr z, HDAE5000_Clear_Work_Buffer__clear_done
	stw_erp WA, 0xE6	; ld WA, QBC  ; get high word count
HDAE5000_Clear_Work_Buffer__clear_loop:
	mriw2 0x93, 0x11	; ldirw  ; continue word copy
	djnz xwa, HDAE5000_Clear_Work_Buffer__clear_loop	; djnz WA, .clear_loop
HDAE5000_Clear_Work_Buffer__clear_done:
	bit 0, ix	; bit 0, IX  ; check if odd byte
	jr z, HDAE5000_Clear_Work_Buffer__no_odd_byte
	ld (xde), 0x0	; Clear final odd byte
HDAE5000_Clear_Work_Buffer__no_odd_byte:
	; === Part 2: Copy init data from ROM to RAM ===
	ld xde, 0x23952A	; Destination = RAM init area
	ld xhl, 0x2F94B2	; Source = ROM init data
	ld xbc, 0xC82	; Count = 3,202 bytes
	or xbc, xbc
	jr z, HDAE5000_Clear_Work_Buffer__copy_done
	ldir83	; ldir  ; copy bytes
	cpiw_erp 0xE6, 0	; cp QBC, 0
	jr z, HDAE5000_Clear_Work_Buffer__copy_done
	stw_erp WA, 0xE6	; ld WA, QBC
HDAE5000_Clear_Work_Buffer__copy_loop:
	ldir83	; ldir
	djnz xwa, HDAE5000_Clear_Work_Buffer__copy_loop	; djnz WA, .copy_loop
HDAE5000_Clear_Work_Buffer__copy_done:
	ret

HDAE5000_Delay_Loop:	; 28F7DDh
	; Simple nested delay loop - decrements XWA until zero
	; Input: XWA = delay count (outer loop iterations)
	; Clobbers: XWA, XBC
	; Algorithm: Outer loop decrements XWA, inner loop spins on XBC copy
	ld xbc, xwa	; Copy count for comparison
	dec 1, xwa	; dec 1, XWA (decrement outer counter)
	or xbc, xbc	; Check if original was zero
	ret z	; Return immediately if zero
HDAE5000_Delay_Loop__inner_loop:
	ld xbc, xwa	; Copy remaining count
	dec 1, xwa	; dec 1, XWA (decrement inner counter)
	or xbc, xbc	; Check if done
	jr nz, HDAE5000_Delay_Loop__inner_loop	; Continue spinning until zero
	ret

HDAE5000_VGA_Port_Write:	; 28F7EEh
	; Write byte to VGA I/O port (memory-mapped at 0x170000)
	; Input: WA = VGA port number (e.g., 0x3C8, 0x3C9)
	;        C = data byte to write
	; VGA DAC ports: 0x3C8 = palette index, 0x3C9 = R/G/B data
	; Includes 0x100 delay before write to ensure VGA timing
	dec 2, xsp	; dec 2, XSP (allocate 2 bytes)
	pushw iz
	ld (xsp + 2), c	; ld (XSP+0x02), C  ; save data byte
	ld iz, wa	; save port number in IZ
	ld xwa, 0x100	; delay count = 256
	calr HDAE5000_Delay_Loop	; wait for VGA timing
	ld wa, iz	; restore port number
	extz xwa	; zero-extend to 32-bit
	add xwa, 0x170000	; add XWA, 0x00170000
	ld xbc, xwa	; XBC = 0x170000 + port
	ld a, (xsp + 2)	; ld A, (XSP+0x02)  ; restore data byte
	ld (xbc), a	; write byte to VGA port
	popw iz
	inc 2, xsp	; inc 2, XSP (deallocate)
	ret

HDAE5000_Palette_Setup:	; 28F813h
	; Set one VGA palette entry - converts 8-bit RGB to VGA 6-bit format
	; Input: A = palette index (0-255)
	;        XBC = pointer to RGBX color data (4 bytes: R, G, B, unused)
	;
	; VGA DAC format: 6-bit per channel (0-63), ROM has 8-bit (0-255)
	; Conversion: value >> 4, with rounding if bit 3 set and value < 0xF0
	;
	; === Write palette index to port 0x3C8 ===
	push xiz
	ld xiz, xbc	; XIZ = pointer to RGBX data
	extz wa	; A = palette index, zero-extend
	ld bc, wa
	ldw wa, 0x3C8	; VGA palette index port
	calr HDAE5000_VGA_Port_Write
	;
	; === Process Red component (XIZ+0) ===
	bitm 3, (xiz)	; bit 3, (XIZ)  ; check rounding flag
	jr z, HDAE5000_Palette_Setup__red_no_round
	cp (xiz), 0xF0	; cp (XIZ), 0xF0
	jr nc, HDAE5000_Palette_Setup__red_high
	ld a, (xiz)	; ld A, (XIZ)
	srl a, 4	; srl 4, A  ; divide by 16
	inc 1, a	; inc 1, A  ; round up
	extz wa
	ld bc, wa
	ldw wa, 0x3C9	; VGA palette data port
	calr HDAE5000_VGA_Port_Write
	jr HDAE5000_Palette_Setup__green_start
HDAE5000_Palette_Setup__red_high:
	ld a, (xiz)	; ld A, (XIZ)
	srl a, 4	; srl 4, A
	extz wa
	ld bc, wa
	ldw wa, 0x3C9
	calr HDAE5000_VGA_Port_Write
	jr HDAE5000_Palette_Setup__green_start
HDAE5000_Palette_Setup__red_no_round:
	ld a, (xiz)	; ld A, (XIZ)
	srl a, 4	; srl 4, A
	extz wa
	ld bc, wa
	ldw wa, 0x3C9
	calr HDAE5000_VGA_Port_Write
	;
	; === Process Green component (XIZ+1) ===
HDAE5000_Palette_Setup__green_start:
	bitm 3, (xiz + 1)	; bit 3, (XIZ+1)
	jr z, HDAE5000_Palette_Setup__green_no_round
	cp (xiz + 1), 0xF0	; cp (XIZ+1), 0xF0
	jr nc, HDAE5000_Palette_Setup__green_high
	ld a, (xiz + 1)	; ld A, (XIZ+1)
	srl a, 4	; srl 4, A
	inc 1, a	; inc 1, A
	extz wa
	ld bc, wa
	ldw wa, 0x3C9
	calr HDAE5000_VGA_Port_Write
	jr HDAE5000_Palette_Setup__blue_start
HDAE5000_Palette_Setup__green_high:
	ld a, (xiz + 1)	; ld A, (XIZ+1)
	srl a, 4	; srl 4, A
	extz wa
	ld bc, wa
	ldw wa, 0x3C9
	calr HDAE5000_VGA_Port_Write
	jr HDAE5000_Palette_Setup__blue_start
HDAE5000_Palette_Setup__green_no_round:
	ld a, (xiz + 1)	; ld A, (XIZ+1)
	srl a, 4	; srl 4, A
	extz wa
	ld bc, wa
	ldw wa, 0x3C9
	calr HDAE5000_VGA_Port_Write
	;
	; === Process Blue component (XIZ+2) ===
HDAE5000_Palette_Setup__blue_start:
	bitm 3, (xiz + 2)	; bit 3, (XIZ+2)
	jr z, HDAE5000_Palette_Setup__blue_no_round
	cp (xiz + 2), 0xF0	; cp (XIZ+2), 0xF0
	jr nc, HDAE5000_Palette_Setup__blue_high
	ld a, (xiz + 2)	; ld A, (XIZ+2)
	srl a, 4	; srl 4, A
	inc 1, a	; inc 1, A
	extz wa
	ld bc, wa
	ldw wa, 0x3C9
	calr HDAE5000_VGA_Port_Write
	jr HDAE5000_Palette_Setup__done
HDAE5000_Palette_Setup__blue_high:
	ld a, (xiz + 2)	; ld A, (XIZ+2)
	srl a, 4	; srl 4, A
	extz wa
	ld bc, wa
	ldw wa, 0x3C9
	calr HDAE5000_VGA_Port_Write
	jr HDAE5000_Palette_Setup__done
HDAE5000_Palette_Setup__blue_no_round:
	ld a, (xiz + 2)	; ld A, (XIZ+2)
	srl a, 4	; srl 4, A
	extz wa
	ld bc, wa
	ldw wa, 0x3C9
	calr HDAE5000_VGA_Port_Write
HDAE5000_Palette_Setup__done:
	pop xiz
	ret

HDAE5000_Load_Palette:	; 28F8E0h
	; Load all 256 VGA palette entries from ROM data
	; Input: XWA = pointer to palette data (256 entries × 4 bytes)
	; Iterates from index 255 down to 0, calling Palette_Setup for each
	;
	; Each palette entry is 4 bytes: RGBX (X unused)
	; VGA DAC ports: 0x3C8 = index, 0x3C9 = R/G/B data (mapped at 0x170000+port)
	dec 4, xsp	; dec 4, XSP (allocate 4 bytes on stack)
	pushw iz
	ld (xsp + 2), xwa	; ld (XSP+0x02), XWA  ; store palette ptr
	ldw iz, 0xFF	; IZ = 255 (palette index counter)
	cp iz, 0:i3	; initial check
	jr lt, HDAE5000_Load_Palette__done	; skip loop if IZ < 0 (never happens here)
HDAE5000_Load_Palette__loop:
	stb_erp E, 0xF8	; E = current palette index
	ld wa, iz
	exts xwa	; sign-extend WA to XWA
	sll xwa, 2	; sll 2, XWA  ; XWA = index × 4
	ld xbc, xwa	; XBC = offset
	add xbc, (xsp + 2)	; add XBC, (XSP+0x02)  ; XBC = palette_ptr + offset
	ld a, e	; A = palette index
	calr HDAE5000_Palette_Setup	; Set one palette entry
	sub iz, 0x1	; IZ--
	jr ge, HDAE5000_Load_Palette__loop	; continue while IZ >= 0
HDAE5000_Load_Palette__done:
	popw iz
	inc 4, xsp	; inc 4, XSP (deallocate stack)
	ret

HDAE5000_Finalize_Init:	; 28F90Bh
	; Stub that just returns (placeholder)
	ret

HDAE5000_HD_FormatDrive:	; 28F90Ch (114 bytes)
	; Format the hard disk (HDAE5000_HD_Format) bracketed by main-CPU
	; callbacks: workspace (0x23A1A2)->0x0E88 table +0xE8 (with WA=1) before,
	; +0xEC and +0xF0 after; with IZ = WA = 1 also the 0x0E0A table +0x538
	; before and +0x53C after.  Returns HL = HDAE5000_HD_Format's result
	; (0 = formatted).  Callers: HDAE5000_AttenHDFormatSwCatch and
	; HDAE5000_PPORT_Svc17_FormatHd.  (It registers nothing: an earlier
	; header called it "display and callback initialization".)
	; Input: WA = display mode (1 = with sub-handlers)
	dec 2, xsp			; allocate 2 bytes on stack
	pushw iz			; save IZ
	ld iz, wa			; IZ = mode parameter
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2) — workspace pointer
	ld xwa, (xwa + WS_HamaFnTable)             ; ld XWA, (XWA+0x0E88) — display handler table
	ld_sril xhl, (xwa + HamaFn_PlayHalt)             ; ld XHL, (XWA+0x00E8) — init callback
	ld wa, 1:i3			; WA = 1
	call (xhl)			; call init callback
	cp iz, 1:i3			; mode == 1?
	jr nz, .Ldi_skip1		; skip sub-handler if not
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2)
	ld xwa, (xwa + WS_RootFnTable)             ; ld XWA, (XWA+0x0E0A) — sub-handler table
	ld xhl, (xwa + RootFn_SleepMainTask)             ; ld XHL, (XWA+0x0538) — sub-handler callback
	call (xhl)			; call sub-handler
.Ldi_skip1:
	call HDAE5000_HD_Format
	ld (xsp + 2), hl		; save result on stack
	cp iz, 1:i3			; mode == 1?
	jr nz, .Ldi_skip2		; skip sub-handler if not
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2)
	ld xwa, (xwa + WS_RootFnTable)             ; ld XWA, (XWA+0x0E0A)
	ld xhl, (xwa + RootFn_WakeUpMainTask)             ; ld XHL, (XWA+0x053C) — post-render callback
	call (xhl)			; call post-render sub-handler
.Ldi_skip2:
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2)
	ld xwa, (xwa + WS_HamaFnTable)             ; ld XWA, (XWA+0x0E88)
	ld_sril xhl, (xwa + HamaFn_PlayStandBy)             ; ld XHL, (XWA+0x00EC) — cleanup callback
	call (xhl)			; call cleanup
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2)
	ld xwa, (xwa + WS_HamaFnTable)             ; ld XWA, (XWA+0x0E88)
	ld_sril xhl, (xwa + HamaFn_EditSwRefresh)             ; ld XHL, (XWA+0x00F0) — final callback
	call (xhl)			; call final callback
	ld hl, (xsp + 2)		; restore result from stack
	popw iz				; restore IZ
	inc 2, xsp			; deallocate 2 bytes
	ret

HDAE5000_DirName_Address:	; 0x28F97E (13 bytes)
	; Calculate 16-byte offset in table at 0x201632
	; Input: WA = table index
	; Output: XHL = pointer to 16-byte entry
	; (The table is the directory-name block, 16 bytes x 120 --
	; HDAE5000_HD_GetBlockInfo block 0 -- so WA is a directory index.)
	extz xwa		; zero-extend index to 32 bits
	sll xwa, 4		; multiply by 16
	ld xhl, HDAE5000_RAM_DirNames	; table base address
	add xhl, xwa		; XHL = base + index*16
	ret

HDAE5000_DirName_SetAndStore:	; 0x28F98B (34 bytes)
	; Copy 16 bytes to table entry, then call Display_Callback
	; Input: WA = table index, XBC = source pointer, DE = param
	; (= set directory WA's name from XBC, then HDAE5000_HD_StoreTables(DE):
	; "Display_Callback" is the table writer, DE its keep-spinning flag.)
	pushw iz
	ld iz, de			; save DE param
	pushw 0x0010			; push 16 (byte count)
	push xbc			; push source pointer
	extz xwa			; zero-extend index
	sll xwa, 4			; index * 16
	ld xbc, HDAE5000_RAM_DirNames		; table base
	add xbc, xwa			; XBC = dest ptr
	push xbc			; push dest pointer
	call HDAE5000_StrNCpy	; memcpy(dest, src, 16)
	lda xsp, (xsp + 0x0A)		; deallocate 10 bytes
	ld wa, iz			; restore param
	calr HDAE5000_HD_StoreTables
	popw iz
	ret

HDAE5000_Dir_IsBlankName:	; 0x28F9AD (62 bytes)
	; Is directory WA's 16-byte name the blank string at 0x2F8DE0 (16
	; spaces)?  HL = 0xFFFF if it is (unused directory), 0 otherwise.
	; (Was "tile entry ... HL = 0 (match) or 0xFFFF (mismatch)": the entry is a
	; directory name and the result is the other way round -- `jr nz` skips
	; the 0xFFFF only on a MISmatch.)
	push xiz		; save XIZ
	ld iz, wa		; IZ = tile index
	ld	qiz, 0
	pushw 0x002F		; push max length (47)
	pushw 0x8DE0		; push reference string address
	call HDAE5000_StrLen
	pushw hl		; push reference length
	pushw 0x002F		; push max length
	pushw 0x8DE0		; push reference string
	ld wa, iz		; restore tile index
	extz xwa		; zero-extend
	sll xwa, 4		; XWA *= 16
	ld xbc, HDAE5000_RAM_DirNames	; table base address
	add xbc, xwa		; XBC = base + index*16
	push xbc		; push tile address
	call HDAE5000_StrNCmp
	add xsp, 0x0000000E	; clean up 14 bytes
	cp hl, 0:i3		; check compare result
	jr nz, .Lgdd_done	; skip if mismatch
	ldw	qiz, 0xffff
.Lgdd_done:
	ld	hl, qiz
	pop xiz			; restore XIZ
	ret

HDAE5000_Dir_CountEmptySongs:	; 0x28F9EB (51 bytes)
	; Number of the 16 songs of directory WA that hold no part at all
	; (HDAE5000_Song_IsUsed = 0xFFFF).  Output: HL = that count.
	; (Was "16 tile entries"; they are song records.)
	dec 2, xsp		; allocate 2 bytes
	push xiz		; save XIZ
	ld (xsp + 4), wa	; save WA param on stack
	ld iz, 0:i3		; IZ = 0 (invalid counter)
	ld	qiz, 0
	cpw	qiz, 0x0010
	jr nc, .Lcic_done	; if >= 16, done
.Lcic_loop:
	ld wa, (xsp + 4)	; restore WA param
	ld	bc, qiz
	calr HDAE5000_Song_IsUsed
	cp hl, 0xFFFF		; check if invalid (-1)
	jr nz, .Lcic_skip	; skip if valid
	inc 1, iz		; count invalid
.Lcic_skip:
	inc	1, qiz
	cpw	qiz, 0x0010
	jr c, .Lcic_loop	; if < 16, continue loop
.Lcic_done:
	ld hl, iz		; HL = invalid count
	pop xiz			; restore XIZ
	inc 2, xsp		; deallocate 2 bytes
	ret

HDAE5000_SongRecord_Address:	; 0x28FA1E (56 bytes)
	; Calculate table address: base + row*1216 + 1920 + col*76
	; Input: WA = row, BC = column
	; Output: XHL = pointer to entry
	; (row = directory, column = song: XHL = 0x201DB2 + dir*0x4C0 +
	; song*0x4C, the 76-byte song record.)
	dec 4, xsp		; allocate 4 bytes
	pushw iz		; save IZ
	ld iz, wa		; IZ = row
	ld wa, bc		; WA = column
	extz xwa		; zero-extend to 32-bit
	ld xbc, 0x0000004C	; multiplier = 76
	call HDAE5000_Multiply	; XHL = col * 76
	ld (xsp + 2), xhl	; save col_offset on stack
	ld wa, iz		; WA = row
	extz xwa		; zero-extend
	ld xbc, 0x000004C0	; multiplier = 1216
	call HDAE5000_Multiply	; XHL = row * 1216
	add xhl, 0x780		; XHL += 1920 (header offset)
	ld xwa, xhl		; XWA = row_offset
	add xwa, (xsp + 2)	; XWA += col_offset
	ld xhl, HDAE5000_RAM_DirNames	; table base address
	add xhl, xwa		; XHL = base + total_offset
	popw iz			; restore IZ
	inc 4, xsp		; deallocate 4 bytes
	ret

HDAE5000_SongName_SetAndStore:	; 0x28FA56 (74 bytes)
	; Set the 26-byte name of song record (WA = dir, BC = song) from XDE,
	; then HDAE5000_HD_StoreTables(stacked word).  No reference to it was
	; found (scripts/analysis/hdae5000_reachability.py).
	; (Was "copy table entry ... stack+2 = copy size": XDE is the source,
	; the record the destination, and the stacked word is the store flag.)
	dec 4, xsp		; allocate 4 bytes
	pushw iz		; save IZ
	ld iz, wa		; IZ = row
	pushw 0x001A		; push 26 (entry size)
	push xde		; push source (the new name)
	ld wa, bc		; WA = column
	extz xwa		; zero-extend
	ld xbc, 0x0000004C	; multiplier = 76
	call HDAE5000_Multiply	; XHL = col * 76
	ld (xsp + 8), xhl	; save col_offset on stack
	ld wa, iz		; WA = row
	extz xwa		; zero-extend
	ld xbc, 0x000004C0	; multiplier = 1216
	call HDAE5000_Multiply	; XHL = row * 1216
	add xhl, 0x780		; XHL += 1920
	add xhl, (xsp + 8)	; XHL += col_offset
	ld xwa, HDAE5000_RAM_DirNames	; table base address
	add xwa, xhl		; XWA = base + total_offset
	push xwa		; push destination (the record)
	call HDAE5000_StrNCpy
	lda xsp, (xsp + 0x0A)	; deallocate 10 bytes
	ld wa, (xsp + 0x0A)	; the stacked store flag
	calr HDAE5000_HD_StoreTables
	popw iz			; restore IZ
	inc 4, xsp		; deallocate 4 bytes
	retd 0x0002		; return and pop 2 bytes

HDAE5000_FlsRecord_Address:	; 0x28FAA0 (26 bytes)
	; FLS record address: 0x201632 + 0x24180 + WA*0x90 = 0x2257B2 + fls*144
	; (HDAE5000_HD_GetBlockInfo block 2).  Input: WA = FLS index.
	; (Was "tile address"/"tile index".)
	; Algorithm: index*144 = index*(128+16) = (index<<3 + index)<<4
	extz xwa		; zero-extend index to 32 bits
	ld xbc, xwa		; XBC = index
	sll xbc, 3		; XBC = index * 8
	add xbc, xwa		; XBC = index * 9
	sll xbc, 4		; XBC = index * 144
	add xbc, 0x00024180	; add tile table offset
	ld xhl, HDAE5000_RAM_DirNames	; table base address
	add xhl, xbc		; XHL = base + offset
	ret

HDAE5000_FlsName_SetAndStore:	; 0x28FABA (47 bytes)
	; Set FLS record WA's 16-byte name from XBC, then
	; HDAE5000_HD_StoreTables(DE).  (Was "tile index" / "callback param".)
	pushw iz		; save IZ
	ld iz, de		; IZ = callback param
	pushw 0x0010		; push 16 (copy size)
	push xbc		; push dest pointer
	extz xwa		; zero-extend tile index
	ld xbc, xwa		; XBC = index
	sll xbc, 3		; XBC = index * 8
	add xbc, xwa		; XBC = index * 9
	sll xbc, 4		; XBC = index * 144
	add xbc, 0x00024180	; add entry table offset
	ld xwa, HDAE5000_RAM_DirNames	; table base address
	add xwa, xbc		; XWA = base + offset
	push xwa		; push source pointer
	call HDAE5000_StrNCpy	; copy 16 bytes
	lda xsp, (xsp + 0x0A)	; deallocate 10 bytes
	ld wa, iz		; restore callback param
	calr HDAE5000_HD_StoreTables
	popw iz			; restore IZ
	ret

HDAE5000_Fls_IsBlankName:	; 0x28FAE9 (61 bytes)
	; Is FLS record WA's name the blank string at 0x2F8DF2 (16 spaces)?
	; Output: HL = 0xFFFF if blank (unused), 0 otherwise.  (Was "tile entry".)
	dec 2, xsp		; allocate 2 bytes for result
	pushw iz		; save IZ
	ld iz, wa		; IZ = tile index
	ldw (xsp + 2), 0x0000	; result = 0 (valid)
	pushw 0x002F		; push max length (47)
	pushw 0x8DF2		; push reference string address
	call HDAE5000_StrLen
	inc 4, xsp		; clean up 2 args
	pushw hl		; push reference length
	pushw 0x002F		; push max length
	pushw 0x8DF2		; push reference string address
	ld wa, iz		; restore tile index
	calr HDAE5000_FlsRecord_Address	; XHL = tile address
	push xhl		; push tile address (32-bit)
	call HDAE5000_StrNCmp
	add xsp, 0x0000000A	; clean up 10 bytes
	cp hl, 0:i3		; compare result
	jr nz, .Lvcc_done	; if not equal, valid (keep 0)
	ldw (xsp + 2), 0xFFFF	; mark invalid (-1)
.Lvcc_done:
	ld hl, (xsp + 2)	; load result
	popw iz			; restore IZ
	inc 2, xsp		; deallocate 2 bytes
	ret

HDAE5000_FlsItem_SongRecord:	; 0x28FB26 (139 bytes)
	; Song record of item BC of FLS record WA: XHL = 0x201DB2 +
	; (dir+1 byte - 1)*0x4C0 + (song+1 byte - 1)*0x4C, or 0x2F8E04 (26
	; spaces, a blank name) when the item is empty (HDAE5000_FlsItem_IsSet).
	; (Was "row"/"column" and "row/col dimension table".)
	dec 4, xsp		; allocate 4 bytes
	pushw iz		; save IZ
	ld iz, bc		; IZ = column
	ld (xsp + 4), wa	; save row on stack
	; First: validate the cell
	ld wa, (xsp + 4)	; WA = row
	ld bc, iz		; BC = column
	calr HDAE5000_FlsItem_IsSet
	cp hl, 0xFFFF		; invalid?
	jr z, .Lrca_fail	; if -1, use fallback address
	; song offset: the item's song+1 byte (FLS record +48+item, 0x2257E2 base)
	ld bc, iz		; BC = column
	extz xbc		; zero-extend column
	ld wa, (xsp + 4)	; WA = row
	extz xwa		; zero-extend row
	ld xde, xwa		; XDE = row
	sll xde, 3		; XDE = row * 8
	add xde, xwa		; XDE = row * 9
	sll xde, 4		; XDE = row * 144
	add xde, xbc		; XDE = row*144 + col
	lda xwa, (0x2257e2:24); song+1 bytes of the FLS items
	add xwa, xde		; XWA = table + row*144 + col
	ld a, (xwa)		; A = dimension value
	dec 1, a		; A -= 1
	extz wa			; zero-extend A to WA
	muls wa, 0x004C		; WA = (dim-1) * 76
	ld (xsp + 2), wa	; save row_offset
	; directory offset: the item's dir+1 byte (FLS record +16+item, 0x2257C2 base)
	ld bc, iz		; BC = column
	extz xbc		; zero-extend
	ld wa, (xsp + 4)	; WA = row
	extz xwa		; zero-extend
	ld xde, xwa		; XDE = row
	sll xde, 3		; XDE = row * 8
	add xde, xwa		; XDE = row * 9
	sll xde, 4		; XDE = row * 144
	add xde, xbc		; XDE = row*144 + col
	lda xwa, (0x2257c2:24); dir+1 bytes of the FLS items
	add xwa, xde		; XWA = table + index
	ld a, (xwa)		; A = directory + 1
	dec 1, a		; A -= 1
	ld w, 0x00:opc		; W = 0 (zero-extend A to WA manually)
	extz xwa		; zero-extend WA to XWA
	ld xbc, 0x000004C0	; multiplier = 1216
	call HDAE5000_Multiply	; XHL = col_dim * 1216
	add xhl, 0x780		; XHL += 1920
	ld wa, (xsp + 2)	; WA = row_offset
	exts xwa		; sign-extend WA to XWA
	add xwa, xhl		; XWA = total offset
	ld xhl, HDAE5000_RAM_DirNames	; table base address
	add xhl, xwa		; XHL = final entry address
	jr t, .Lrca_done	; jump to epilogue
.Lrca_fail:
	lda xhl, (0x2f8e04:24); lda XHL, (0x2F8E04) - fallback/error address
.Lrca_done:
	popw iz			; restore IZ
	inc 4, xsp		; deallocate 4 bytes
	ret

; ============================================================================
; Display Table Management and UI Cell Rendering (0x28FBB1-0x295008)
; ^ PROVEN WRONG TITLE, kept for the record: this is the song/FLS record
;   layer and the song load/save/copy/delete code (see
;   scripts/renaming/rename_hdae5000_songio.sed and each header).
; 21,592 bytes, 50 routines
;
; Table operations use 0x4C (76) byte stride for row addressing
; and 0x90 (144) byte stride for tile addressing.
; Eight routines at 0x2934C8-0x293BB8 are exactly 222 bytes each,
; likely one per UI cell/widget type.
; ^ They are one per song PART: HDAE5000_DeleteSongPart_Lsw .. _Tlx, and
;   there are nine (0x2934C8-0x293C95), not eight.
; ============================================================================

HDAE5000_FlsItem_IsSet:	; 0x28FBB1 (1497 bytes)
	; Validate entry at coordinates; calculates table offset
	; (= HL = 0 if item BC of FLS record WA is set -- both its dir+1 byte
	; at 0x2257C2 and its song+1 byte at 0x2257E2 are non-zero -- else 0xFFFF)
; LCIB: 0x28FBB1 (1497 bytes)
	; ^ conversion-region size (local-label prefix .LCIB_), not a routine
	;   size: HDAE5000_FlsItem_IsSet .. HDAE5000_FlsItem_SetByte112.

	ld	hl, 0:i3
	ld	ix, bc
	extz xix                                ; extz XIX
	ld	de, wa
	extz xde                                ; extz XDE
	ld	xiy, xde
	sll	xiy, 0x03
	add	xiy, xde
	sll	xiy, 0x04
	add	xiy, xix
	lda xde, (0x2257c2:24)
	add	xde, xiy
	cp	(xde), 0x00
	jr z, .LCIB_fbef                       ; [66 1c] jr Z,0x28fbef
	extz xbc                                ; extz XBC
	extz xwa
	ld	xde, xwa
	sll	xde, 0x03
	add	xde, xwa
	sll	xde, 0x04
	add	xde, xbc
	lda xwa, (0x2257e2:24)
	add	xwa, xde
	cp	(xwa), 0x00
	ret nz                                  ; ret NZ

.LCIB_fbef:
	ldw	hl, 0xffff
	ret

HDAE5000_FlsItem_Get:
	; XDE = destination {u16 dir; u16 song; u8 byte80; u8 byte112} of item BC of
	; FLS record WA (the 1-based dir/song bytes minus 1); nothing when the item
	; is empty (HDAE5000_FlsItem_IsSet).
	dec	6, xsp
	pushw iz                                ; push IZ
	ld (xsp + 0x02), xde                    ; ld (XSP+0x02),XDE
	ld	iz, bc
	ld (xsp + 0x06), wa                     ; ld (XSP+0x06),WA
	ld	wa, (xsp+6)
	ld	bc, iz
	calr	HDAE5000_FlsItem_IsSet
	ld	wa, hl
	cp	wa, 0xffff
	jrl z, .LCIB_fcae                      ; [76 9f 00] jrl Z,0x28fcae
	ld	bc, iz
	extz xbc                                ; extz XBC
	ld	wa, (xsp+6)
	extz xwa
	ld	xde, xwa
	sll	xde, 0x03
	add	xde, xwa
	sll	xde, 0x04
	add	xde, xbc
	lda xwa, (0x2257c2:24)
	add	xwa, xde
	ld	a, (xwa)
	dec	1, a
	ld	c, a
	extz bc                                 ; extz BC
	ld xwa, (xsp + 0x02)                    ; ld XWA,(XSP+0x02)
	ld (xwa), bc                            ; ld (XWA),BC
	ld	bc, iz
	extz xbc                                ; extz XBC
	ld	wa, (xsp+6)
	extz xwa
	ld	xde, xwa
	sll	xde, 0x03
	add	xde, xwa
	sll	xde, 0x04
	add	xde, xbc
	lda xwa, (0x2257e2:24)
	add	xwa, xde
	ld	a, (xwa)
	dec	1, a
	ld	c, a
	extz bc                                 ; extz BC
	ld xwa, (xsp + 0x02)                    ; ld XWA,(XSP+0x02)
	ld (xwa + 0x02), bc                     ; ld (XWA+0x02),BC
	ld	bc, iz
	extz xbc                                ; extz XBC
	ld	wa, (xsp+6)
	extz xwa
	ld	xde, xwa
	sll	xde, 0x03
	add	xde, xwa
	sll	xde, 0x04
	add	xde, xbc
	lda xwa, (0x225802:24)
	ld	xbc, xwa
	add	xbc, xde
	ld xwa, (xsp + 0x02)                    ; ld XWA,(XSP+0x02)
	ld	c, (xbc)
	ld	(xwa+4), c
	ld	bc, iz
	extz xbc                                ; extz XBC
	ld	wa, (xsp+6)
	extz xwa
	ld	xde, xwa
	sll	xde, 0x03
	add	xde, xwa
	sll	xde, 0x04
	add	xde, xbc
	lda xwa, (0x225822:24)
	ld	xbc, xwa
	add	xbc, xde
	ld xwa, (xsp + 0x02)                    ; ld XWA,(XSP+0x02)
	ld	c, (xbc)
	ld	(xwa+5), c
.LCIB_fcae:
	popw iz                                 ; pop IZ
	inc	6, xsp
	ret

HDAE5000_FlsItem_Clear:
	; zero the four bytes of item BC of FLS record WA (+16, +48, +80, +112); HL = 0
	ld	hl, bc
	extz xhl                                ; extz XHL
	ld	de, wa
	extz xde                                ; extz XDE
	ld	xix, xde
	sll	xix, 0x03
	add	xix, xde
	sll	xix, 0x04
	add	xix, xhl
	lda xde, (0x2257c2:24)
	add	xde, xix
	ld	(xde), 0x00
	ld	hl, bc
	extz xhl                                ; extz XHL
	ld	de, wa
	extz xde                                ; extz XDE
	ld	xix, xde
	sll	xix, 0x03
	add	xix, xde
	sll	xix, 0x04
	add	xix, xhl
	lda xde, (0x2257e2:24)
	add	xde, xix
	ld	(xde), 0x00
	ld	hl, bc
	extz xhl                                ; extz XHL
	ld	de, wa
	extz xde                                ; extz XDE
	ld	xix, xde
	sll	xix, 0x03
	add	xix, xde
	sll	xix, 0x04
	add	xix, xhl
	lda xde, (0x225802:24)
	add	xde, xix
	ld	(xde), 0x00
	extz xbc                                ; extz XBC
	extz xwa
	ld	xde, xwa
	sll	xde, 0x03
	add	xde, xwa
	sll	xde, 0x04
	add	xde, xbc
	lda xwa, (0x225822:24)
	add	xwa, xde
	ld	(xwa), 0x00
	ld	hl, 0:i3
	ret

HDAE5000_FlsItem_Remove:
	; remove item BC of FLS record WA: items BC+1..31 move down one, item 31
	; is zeroed; HL = 0
	ld	ix, bc
	inc	1, ix
	cp	ix, 0x0020
	jrl nc, .LCIB_fe35                     ; [7f 01 01] jrl NC,0x28fe35
.LCIB_fd34:
	ld	bc, ix
	dec	1, bc
	ld	de, bc
	extz xde                                ; extz XDE
	ld	bc, wa
	extz xbc                                ; extz XBC
	ld	xhl, xbc
	sll	xhl, 0x03
	add	xhl, xbc
	sll	xhl, 0x04
	add	xhl, xde
	lda xiy, (0x2257c2:24)
	add	xiy, xhl
	ld	de, ix
	extz xde                                ; extz XDE
	ld	bc, wa
	extz xbc                                ; extz XBC
	ld	xhl, xbc
	sll	xhl, 0x03
	add	xhl, xbc
	sll	xhl, 0x04
	add	xhl, xde
	lda xbc, (0x2257c2:24)
	add	xbc, xhl
	ld	c, (xbc)
	ld	(xiy), c
	ld	bc, ix
	dec	1, bc
	ld	de, bc
	extz xde                                ; extz XDE
	ld	bc, wa
	extz xbc                                ; extz XBC
	ld	xhl, xbc
	sll	xhl, 0x03
	add	xhl, xbc
	sll	xhl, 0x04
	add	xhl, xde
	lda xiy, (0x2257e2:24)
	add	xiy, xhl
	ld	de, ix
	extz xde                                ; extz XDE
	ld	bc, wa
	extz xbc                                ; extz XBC
	ld	xhl, xbc
	sll	xhl, 0x03
	add	xhl, xbc
	sll	xhl, 0x04
	add	xhl, xde
	lda xbc, (0x2257e2:24)
	add	xbc, xhl
	ld	c, (xbc)
	ld	(xiy), c
	ld	bc, ix
	dec	1, bc
	ld	de, bc
	extz xde                                ; extz XDE
	ld	bc, wa
	extz xbc                                ; extz XBC
	ld	xhl, xbc
	sll	xhl, 0x03
	add	xhl, xbc
	sll	xhl, 0x04
	add	xhl, xde
	lda xiy, (0x225802:24)
	add	xiy, xhl
	ld	de, ix
	extz xde                                ; extz XDE
	ld	bc, wa
	extz xbc                                ; extz XBC
	ld	xhl, xbc
	sll	xhl, 0x03
	add	xhl, xbc
	sll	xhl, 0x04
	add	xhl, xde
	lda xbc, (0x225802:24)
	add	xbc, xhl
	ld	c, (xbc)
	ld	(xiy), c
	ld	bc, ix
	dec	1, bc
	ld	de, bc
	extz xde                                ; extz XDE
	ld	bc, wa
	extz xbc                                ; extz XBC
	ld	xhl, xbc
	sll	xhl, 0x03
	add	xhl, xbc
	sll	xhl, 0x04
	add	xhl, xde
	lda xiy, (0x225822:24)
	add	xiy, xhl
	ld	de, ix
	extz xde                                ; extz XDE
	ld	bc, wa
	extz xbc                                ; extz XBC
	ld	xhl, xbc
	sll	xhl, 0x03
	add	xhl, xbc
	sll	xhl, 0x04
	add	xhl, xde
	lda xbc, (0x225822:24)
	add	xbc, xhl
	ld	c, (xbc)
	ld	(xiy), c
	inc	1, ix
	cp	ix, 0x0020
	jrl c, .LCIB_fd34                      ; [77 ff fe] jrl C,0x28fd34
.LCIB_fe35:
	ld	bc, wa
	extz xbc                                ; extz XBC
	ld	xde, xbc
	sll	xde, 0x03
	add	xde, xbc
	sll	xde, 0x04
	add	xde, 0x00024180
	lda xbc, (0x201661:24)
	add	xbc, xde
	ld	(xbc), 0x00
	ld	bc, wa
	extz xbc                                ; extz XBC
	ld	xde, xbc
	sll	xde, 0x03
	add	xde, xbc
	sll	xde, 0x04
	add	xde, 0x00024180
	lda xbc, (0x201681:24)
	add	xbc, xde
	ld	(xbc), 0x00
	ld	bc, wa
	extz xbc                                ; extz XBC
	ld	xde, xbc
	sll	xde, 0x03
	add	xde, xbc
	sll	xde, 0x04
	add	xde, 0x00024180
	lda xbc, (0x2016a1:24)
	add	xbc, xde
	ld	(xbc), 0x00
	extz xwa
	ld	xbc, xwa
	sll	xbc, 0x03
	add	xbc, xwa
	sll	xbc, 0x04
	add	xbc, 0x00024180
	lda xwa, (0x2016c1:24)
	add	xwa, xbc
	ld	(xwa), 0x00
	ld	hl, 0:i3
	ret

HDAE5000_FlsItem_Insert:
	; open a gap at item BC of FLS record WA: items BC..30 move up one (item
	; 31 is lost) and item BC is zeroed; HL = 0
	push xiz
	ldw	iy, 0x001f
	cp	iy, bc
	jrl ule, .LCIB_ffb6                    ; [73 ff 00] jrl ULE,0x28ffb6
.LCIB_feb7:
	ld	hl, iy
	extz xhl                                ; extz XHL
	ld	de, wa
	extz xde                                ; extz XDE
	ld	xix, xde
	sll	xix, 0x03
	add	xix, xde
	sll	xix, 0x04
	add	xix, xhl
	lda xiz, (0x2257c2:24)
	add	xiz, xix
	ld	de, iy
	dec	1, de
	ld	hl, de
	extz xhl                                ; extz XHL
	ld	de, wa
	extz xde                                ; extz XDE
	ld	xix, xde
	sll	xix, 0x03
	add	xix, xde
	sll	xix, 0x04
	add	xix, xhl
	lda xde, (0x2257c2:24)
	add	xde, xix
	ld	e, (xde)
	ld	(xiz), e
	ld	hl, iy
	extz xhl                                ; extz XHL
	ld	de, wa
	extz xde                                ; extz XDE
	ld	xix, xde
	sll	xix, 0x03
	add	xix, xde
	sll	xix, 0x04
	add	xix, xhl
	lda xiz, (0x2257e2:24)
	add	xiz, xix
	ld	de, iy
	dec	1, de
	ld	hl, de
	extz xhl                                ; extz XHL
	ld	de, wa
	extz xde                                ; extz XDE
	ld	xix, xde
	sll	xix, 0x03
	add	xix, xde
	sll	xix, 0x04
	add	xix, xhl
	lda xde, (0x2257e2:24)
	add	xde, xix
	ld	e, (xde)
	ld	(xiz), e
	ld	hl, iy
	extz xhl                                ; extz XHL
	ld	de, wa
	extz xde                                ; extz XDE
	ld	xix, xde
	sll	xix, 0x03
	add	xix, xde
	sll	xix, 0x04
	add	xix, xhl
	lda xiz, (0x225802:24)
	add	xiz, xix
	ld	de, iy
	dec	1, de
	ld	hl, de
	extz xhl                                ; extz XHL
	ld	de, wa
	extz xde                                ; extz XDE
	ld	xix, xde
	sll	xix, 0x03
	add	xix, xde
	sll	xix, 0x04
	add	xix, xhl
	lda xde, (0x225802:24)
	add	xde, xix
	ld	e, (xde)
	ld	(xiz), e
	ld	hl, iy
	extz xhl                                ; extz XHL
	ld	de, wa
	extz xde                                ; extz XDE
	ld	xix, xde
	sll	xix, 0x03
	add	xix, xde
	sll	xix, 0x04
	add	xix, xhl
	lda xiz, (0x225822:24)
	add	xiz, xix
	ld	de, iy
	dec	1, de
	ld	hl, de
	extz xhl                                ; extz XHL
	ld	de, wa
	extz xde                                ; extz XDE
	ld	xix, xde
	sll	xix, 0x03
	add	xix, xde
	sll	xix, 0x04
	add	xix, xhl
	lda xde, (0x225822:24)
	add	xde, xix
	ld	e, (xde)
	ld	(xiz), e
	dec	1, iy
	cp	iy, bc
	jrl ugt, .LCIB_feb7                    ; [7b 01 ff] jrl UGT,0x28feb7
.LCIB_ffb6:
	ld	hl, bc
	extz xhl                                ; extz XHL
	ld	de, wa
	extz xde                                ; extz XDE
	ld	xix, xde
	sll	xix, 0x03
	add	xix, xde
	sll	xix, 0x04
	add	xix, xhl
	lda xde, (0x2257c2:24)
	add	xde, xix
	ld	(xde), 0x00
	ld	hl, bc
	extz xhl                                ; extz XHL
	ld	de, wa
	extz xde                                ; extz XDE
	ld	xix, xde
	sll	xix, 0x03
	add	xix, xde
	sll	xix, 0x04
	add	xix, xhl
	lda xde, (0x2257e2:24)
	add	xde, xix
	ld	(xde), 0x00
	ld	hl, bc
	extz xhl                                ; extz XHL
	ld	de, wa
	extz xde                                ; extz XDE
	ld	xix, xde
	sll	xix, 0x03
	add	xix, xde
	sll	xix, 0x04
	add	xix, xhl
	lda xde, (0x225802:24)
	add	xde, xix
	ld	(xde), 0x00
	extz xbc                                ; extz XBC
	extz xwa
	ld	xde, xwa
	sll	xde, 0x03
	add	xde, xwa
	sll	xde, 0x04
	add	xde, xbc
	lda xwa, (0x225822:24)
	add	xwa, xde
	ld	(xwa), 0x00
	ld	hl, 0:i3
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_FlsItem_Set:
	; item BC of FLS record WA = XDE {u16 dir; u16 song; u8 byte80; u8 byte112}
	; (stored as dir+1, song+1), then HDAE5000_HD_StoreTables(stacked word);
	; retd 2.  No reference to 0x29002E was found: the one LE32 hit of a
	; nearby address (0x290030, at 0x29E158) lies inside a UI object
	; descriptor record, so this looks unreachable.
	ld	hl, wa
	ld	ix, bc
	extz xix                                ; extz XIX
	ld	wa, hl
	extz xwa
	ld	xiy, xwa
	sll	xiy, 0x03
	add	xiy, xwa
	sll	xiy, 0x04
	add	xiy, xix
	lda xwa, (0x2257c2:24)
	ld	xix, xwa
	add	xix, xiy
	ld	wa, (xde)
	inc	1, a
	ld	(xix), a
	ld	ix, bc
	extz xix                                ; extz XIX
	ld	wa, hl
	extz xwa
	ld	xiy, xwa
	sll	xiy, 0x03
	add	xiy, xwa
	sll	xiy, 0x04
	add	xiy, xix
	lda xwa, (0x2257e2:24)
	ld	xix, xwa
	add	xix, xiy
	ld	wa, (xde+2)
	inc	1, a
	ld	(xix), a
	ld	ix, bc
	extz xix                                ; extz XIX
	ld	wa, hl
	extz xwa
	ld	xiy, xwa
	sll	xiy, 0x03
	add	xiy, xwa
	sll	xiy, 0x04
	add	xiy, xix
	lda xwa, (0x225802:24)
	ld	xix, xwa
	add	xix, xiy
	ld	a, (xde+4)
	ld	(xix), a
	extz xbc                                ; extz XBC
	ld	wa, hl
	extz xwa
	ld	xhl, xwa
	sll	xhl, 0x03
	add	xhl, xwa
	sll	xhl, 0x04
	add	xhl, xbc
	lda xwa, (0x225822:24)
	ld	xbc, xwa
	add	xbc, xhl
	ld	a, (xde+5)
	ld	(xbc), a
	ld	wa, (xsp+4)
	calr	HDAE5000_HD_StoreTables
	retd 0x0002		; retd 0x0002

HDAE5000_FlsItem_SetDir:
	; item BC of FLS record WA: dir+1 byte = E+1; HL = 0
	extz xbc                                ; extz XBC
	extz xwa
	ld	xhl, xwa
	sll	xhl, 0x03
	add	xhl, xwa
	sll	xhl, 0x04
	add	xhl, xbc
	lda xwa, (0x2257c2:24)
	ld	xbc, xwa
	add	xbc, xhl
	ld	a, e
	inc	1, a
	ld	(xbc), a
	ld	hl, 0:i3
	ret

HDAE5000_FlsItem_SetSong:
	; item BC of FLS record WA: song+1 byte = E+1; HL = 0
	extz xbc                                ; extz XBC
	extz xwa
	ld	xhl, xwa
	sll	xhl, 0x03
	add	xhl, xwa
	sll	xhl, 0x04
	add	xhl, xbc
	lda xwa, (0x2257e2:24)
	ld	xbc, xwa
	add	xbc, xhl
	ld	a, e
	inc	1, a
	ld	(xbc), a
	ld	hl, 0:i3
	ret

HDAE5000_FlsItem_SetByte80:
	; item BC of FLS record WA, if set: byte at +80 = E
	dec	4, xsp
	pushw iz                                ; push IZ
	ld	(xsp+2), e
	ld	iz, bc
	ld (xsp + 0x04), wa                     ; ld (XSP+0x04),WA
	ld	wa, (xsp+4)
	ld	bc, iz
	calr	HDAE5000_FlsItem_IsSet
	ld	wa, hl
	cp	wa, 0xffff
	jr z, .LCIB_0144                       ; [66 23] jr Z,0x290144
	ld	bc, iz
	extz xbc                                ; extz XBC
	ld	wa, (xsp+4)
	extz xwa
	ld	xde, xwa
	sll	xde, 0x03
	add	xde, xwa
	sll	xde, 0x04
	add	xde, xbc
	lda xwa, (0x225802:24)
	ld	xbc, xwa
	add	xbc, xde
	ld	a, (xsp+2)
	ld	(xbc), a
.LCIB_0144:
	popw iz                                 ; pop IZ
	inc 4, xsp                              ; inc 4,XSP
	ret

HDAE5000_FlsItem_SetByte112:
	; item BC of FLS record WA, if set: byte at +112 = E
	dec	4, xsp
	pushw iz                                ; push IZ
	ld	(xsp+2), e
	ld	iz, bc
	ld (xsp + 0x04), wa                     ; ld (XSP+0x04),WA
	ld	wa, (xsp+4)
	ld	bc, iz
	calr	HDAE5000_FlsItem_IsSet
	ld	wa, hl
	cp	wa, 0xffff
	jr z, .LCIB_0186                       ; [66 23] jr Z,0x290186
	ld	bc, iz
	extz xbc                                ; extz XBC
	ld	wa, (xsp+4)
	extz xwa
	ld	xde, xwa
	sll	xde, 0x03
	add	xde, xwa
	sll	xde, 0x04
	add	xde, xbc
	lda xwa, (0x225822:24)
	ld	xbc, xwa
	add	xbc, xde
	ld	a, (xsp+2)
	ld	(xbc), a
.LCIB_0186:
	popw iz                                 ; pop IZ
	inc 4, xsp                              ; inc 4,XSP
	ret


HDAE5000_Song_IsUsed:	; 0x29018A (553 bytes)
	; Check 9 table slots for availability (-1 = free)
	; WA = row index, BC = column index
	; Returns HL=0 if any slot occupied, HL=0xFFFF if all free
	; (WA = directory, BC = song; the nine slots are the part first-cluster
	; longs at +36.. of the song record, 0xFFFFFFFF = part absent.)
	dec 4, xsp
	push xiz
	ld (xsp + 4), bc		; save column
	ld (xsp + 6), wa		; save row
	; --- Slot 0: base 0x201656 ---
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl			; XIZ = column * 0x4C
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780		; + base offset
	add xhl, xiz			; + column offset
	lda xwa, (0x201656:24); 0x201656
	add xwa, xhl
	ld xwa, (xwa)			; load slot value
	cp xwa, 0xFFFFFFFF		; free?
	jr z, .Ltco_slot1
	ld hl, 0:i3			; occupied → return 0
	jrl .Ltco_exit
	; --- Slot 1: base 0x20165A ---
.Ltco_slot1:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	lda xwa, (0x20165a:24); 0x20165A
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_slot2
	ld hl, 0:i3
	jrl .Ltco_exit
	; --- Slot 2: base 0x20165E ---
.Ltco_slot2:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	lda xwa, (0x20165e:24); 0x20165E
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_slot3
	ld hl, 0:i3
	jrl .Ltco_exit
	; --- Slot 3: base 0x201662 ---
.Ltco_slot3:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	lda xwa, (0x201662:24); 0x201662
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_slot4
	ld hl, 0:i3
	jrl .Ltco_exit
	; --- Slot 4: base 0x201666 ---
.Ltco_slot4:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	lda xwa, (0x201666:24); 0x201666
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_slot5
	ld hl, 0:i3
	jrl .Ltco_exit
	; --- Slot 5: base 0x20166A ---
.Ltco_slot5:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	lda xwa, (0x20166a:24); 0x20166A
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_slot6
	ld hl, 0:i3
	jrl .Ltco_exit
	; --- Slot 6: base 0x20166E ---
.Ltco_slot6:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	lda xwa, (0x20166e:24); 0x20166E
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_slot7
	ld hl, 0:i3
	jr .Ltco_exit
	; --- Slot 7: base 0x201672 ---
.Ltco_slot7:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	lda xwa, (0x201672:24); 0x201672
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_slot8
	ld hl, 0:i3
	jr .Ltco_exit
	; --- Slot 8: base 0x201676 ---
.Ltco_slot8:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	lda xwa, (0x201676:24); 0x201676
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_all_free
	ld hl, 0:i3
	jr .Ltco_exit
.Ltco_all_free:
	ldw hl, 0xFFFF			; all slots free
.Ltco_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_Song_PartMask:	; 0x2903B3 (928 bytes)
	; Part 1: Build occupied-slot bitmask (bits 0-8)
	; (= the mask of the parts song (WA = dir, BC = song) holds, bit k for
	; part k LSW PMT SQT CMP TM MSP RCM MD TLX; 0xFFFF if it holds none)
	; WA = row, BC = column. Returns HL = bitmask or 0xFFFF if all free.
	dec 6, xsp
	push xiz
	ld (xsp + 6), bc		; save column
	ld (xsp + 8), wa		; save row
	ldw (xsp + 4), 0x0000		; init bitmask = 0
	; First check if ALL slots are free (call Table_Calc_Offset)
	ld wa, (xsp + 8)
	ld bc, (xsp + 6)
	calr HDAE5000_Song_IsUsed
	cp hl, 0xFFFF
	jrl z, .Ltl_all_free
	; --- Check slot 0: 0x201656 ---
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	lda xwa, (0x201656:24); 0x201656
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltl_chk1
	setm 0, (xsp + 4)		; bit 0
	; --- Check slot 1: 0x20165A ---
.Ltl_chk1:
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	lda xwa, (0x20165a:24); 0x20165A
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltl_chk2
	setm 1, (xsp + 4)		; bit 1
	; --- Check slot 2: 0x20165E ---
.Ltl_chk2:
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	lda xwa, (0x20165e:24); 0x20165E
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltl_chk3
	setm 2, (xsp + 4)		; bit 2
	; --- Check slot 3: 0x201662 ---
.Ltl_chk3:
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	lda xwa, (0x201662:24); 0x201662
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltl_chk4
	setm 3, (xsp + 4)		; bit 3
	; --- Check slot 4: 0x201666 ---
.Ltl_chk4:
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	lda xwa, (0x201666:24); 0x201666
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltl_chk5
	setm 4, (xsp + 4)		; bit 4
	; --- Check slot 5: 0x20166A ---
.Ltl_chk5:
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	lda xwa, (0x20166a:24); 0x20166A
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltl_chk6
	setm 5, (xsp + 4)		; bit 5
	; --- Check slot 6: 0x20166E ---
.Ltl_chk6:
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	lda xwa, (0x20166e:24); 0x20166E
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltl_chk7
	setm 6, (xsp + 4)		; bit 6
	; --- Check slot 7: 0x201672 ---
.Ltl_chk7:
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	lda xwa, (0x201672:24); 0x201672
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltl_chk8
	setm 7, (xsp + 4)		; bit 7
	; --- Check slot 8: 0x201676 ---
.Ltl_chk8:
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	lda xwa, (0x201676:24); 0x201676
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltl_bitmask_done
	setm 0, (xsp + 5)		; bit 8 (high byte)
	jr .Ltl_bitmask_done
.Ltl_all_free:
	ldw (xsp + 4), 0xFFFF		; all free marker
.Ltl_bitmask_done:
	ld hl, (xsp + 4)		; return bitmask
	pop xiz
	inc 6, xsp
	ret
	; Part 2: Entry setup handler (0x2905E9)
	; Uses bitmask in WA, dispatches Cell_Render routines per bit
	; ^ corrected: WA = directory, BC = song, DE = part mask; bit k calls
	;   HDAE5000_LoadSong_<part k>, stopping at the first that returns
	;   0xFFFF.  Bracketed by the main-CPU callbacks (0x0E88 table +0xE8, +0xEC,
	;   +0xF0; with the stacked flag = 1 also 0x0E0A +0x538/+0x53C).  HL = the
	;   last loader's result.  Callers: HDAE5000_LoadSongWithUi and PC-link
	;   service 14 ("LoadSongFromHdToMemory").
	; IZ = entry ID, DE = param, BC = flags
HDAE5000_LoadSong:
	dec 4, xsp
	push xiz
	ld (xsp + 4), de		; save DE
	ld (xsp + 6), bc		; save BC (flags)
	ld iz, wa			; IZ = bitmask
	; Workspace handler init
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); (0x23A1A2)
	ld xwa, (xwa + WS_HamaFnTable)             ; XWA = (XWA+0x0E88)
	ld_sril xhl, (xwa + HamaFn_PlayHalt)             ; XHL = (XWA+0x00E8)
	ld wa, 1:i3
	call (xhl)
	; Conditional extra handler (if BC == 1)
	cpw (xsp + 14), 0x0001
	jr nz, .Ltl2_skip_extra
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_SleepMainTask)
	call (xhl)
.Ltl2_skip_extra:
	call HDAE5000_ATA_SoftReset_Status
	; Test bits 0-8, calling the part loaders (was "Cell_Render subroutines")
	ld wa, (xsp + 4)		; reload DE (bitmask param)
	; --- Bit 0 ---
	bit 0, wa
	jr z, .Ltl2_bit1
	ld wa, iz
	ld bc, (xsp + 6)
	calr HDAE5000_LoadSong_Lsw
	ld qiz, hl		; ld QIZ, HL (previous-bank store)
	; --- Bit 1 ---
.Ltl2_bit1:
	cpw qiz, 0xffff		; cp QIZ, 0xFFFF
	jr z, .Ltl2_bit2
	ld wa, (xsp + 4)
	bit 1, wa
	jr z, .Ltl2_bit2
	ld wa, iz
	ld bc, (xsp + 6)
	calr HDAE5000_LoadSong_Pmt
	ld qiz, hl		; ld QIZ, HL
	; --- Bit 2 ---
.Ltl2_bit2:
	cpw qiz, 0xffff		; cp QIZ, 0xFFFF
	jr z, .Ltl2_bit3
	ld wa, (xsp + 4)
	bit 2, wa
	jr z, .Ltl2_bit3
	ld wa, iz
	ld bc, (xsp + 6)
	calr HDAE5000_LoadSong_Sqt
	ld qiz, hl		; ld QIZ, HL
	; --- Bit 3 ---
.Ltl2_bit3:
	cpw qiz, 0xffff		; cp QIZ, 0xFFFF
	jr z, .Ltl2_bit4
	ld wa, (xsp + 4)
	bit 3, wa
	jr z, .Ltl2_bit4
	ld wa, iz
	ld bc, (xsp + 6)
	calr HDAE5000_LoadSong_Cmp
	ld qiz, hl		; ld QIZ, HL
	; --- Bit 4 ---
.Ltl2_bit4:
	cpw qiz, 0xffff		; cp QIZ, 0xFFFF
	jr z, .Ltl2_bit5
	ld wa, (xsp + 4)
	bit 4, wa
	jr z, .Ltl2_bit5
	ld wa, iz
	ld bc, (xsp + 6)
	calr HDAE5000_LoadSong_Tm
	ld qiz, hl		; ld QIZ, HL
	; --- Bit 5 ---
.Ltl2_bit5:
	cpw qiz, 0xffff		; cp QIZ, 0xFFFF
	jr z, .Ltl2_bit6
	ld wa, (xsp + 4)
	bit 5, wa
	jr z, .Ltl2_bit6
	ld wa, iz
	ld bc, (xsp + 6)
	calr HDAE5000_LoadSong_Msp
	ld qiz, hl		; ld QIZ, HL
	; --- Bit 6 ---
.Ltl2_bit6:
	cpw qiz, 0xffff		; cp QIZ, 0xFFFF
	jr z, .Ltl2_bit7
	ld wa, (xsp + 4)
	bit 6, wa
	jr z, .Ltl2_bit7
	ld wa, iz
	ld bc, (xsp + 6)
	calr HDAE5000_LoadSong_Rcm
	ld qiz, hl		; ld QIZ, HL
	; --- Bit 7 ---
.Ltl2_bit7:
	cpw qiz, 0xffff		; cp QIZ, 0xFFFF
	jr z, .Ltl2_bit8
	ld wa, (xsp + 4)
	bit 7, wa
	jr z, .Ltl2_bit8
	ld wa, iz
	ld bc, (xsp + 6)
	calr HDAE5000_LoadSong_Md
	ld qiz, hl		; ld QIZ, HL
	; --- Bit 8 ---
.Ltl2_bit8:
	cpw qiz, 0xffff		; cp QIZ, 0xFFFF
	jr z, .Ltl2_final
	ld wa, (xsp + 4)
	bit 8, wa
	jr z, .Ltl2_final
	ld wa, iz
	ld bc, (xsp + 6)
	calr HDAE5000_LoadSong_Tlx
	ld qiz, hl		; ld QIZ, HL
	; --- Final workspace cleanup ---
.Ltl2_final:
	cpw (xsp + 12), 0x0001	; check param
	call nz, (HDAE5000_ATA_Standby_Status:24)		; call nz, 0x2974B5
	cpw (xsp + 14), 0x0001	; check BC == 1?
	jr nz, .Ltl2_skip_final
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_WakeUpMainTask)
	call (xhl)
.Ltl2_skip_final:
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_PlayStandBy)
	call (xhl)
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_EditSwRefresh)
	call (xhl)
	ld hl, qiz		; ld HL, QIZ (load from previous-bank)
	pop xiz
	inc 4, xsp
	retd 4

HDAE5000_LoadSong_Lsw:	; 0x290753 (350 bytes)
	; Load part 0 (LSW) of song (WA = directory, BC = song): if its slot (song
	; record +36, 0x201656 + dir*0x4C0 + song*0x4C) is not 0xFFFFFFFF, read the
	; chain with HDAE5000_HD_ReadFile and hand the data to the main CPU
	; (workspace 0x0E88 table callbacks).  HL = 0 when there is no such part,
	; else ReadFile's result.  Called by HDAE5000_LoadSong for mask bit 0.
	lda xsp, (xsp - 28)
	push xiz
	ld (xsp + 28), bc	; save file number
	ld (xsp + 30), wa	; save directory
	ldw (xsp + 10), 0x0000	; init result = 0
	; First multiply: compute table offset
	ld wa, (xsp + 28)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	; Check if entry exists
	lda xwa, (0x201656:24); 0x201656 (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lts907_load	; entry doesn't exist, result stays 0
	; Workspace dispatch with WA=0 (buffer at xsp+20)
	lda xwa, (xsp + 20)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); 0x23A1A2
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)
	ld wa, 0:i3
	call (xhl)
	; Workspace dispatch with WA=1 (buffer at xsp+12)
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)
	ld wa, 1:i3
	call (xhl)
	; Compute arg and call Cell_Get_Params
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	calr HDAE5000_RoundUpToSector
	ld (xsp + 4), xhl
	; Workspace dispatch (d8 displacement 0x0C)
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_PreLswLoad)	; (XWA+0x0C)
	call (xhl)
	; Save workspace ptr
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ld (xsp + 8), xwa
	; Second multiply: compute table offset
	ld wa, (xsp + 28)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	; Table lookup via 0x29811C
	lda xwa, (0x201656:24); 0x201656
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	call HDAE5000_HD_ReadFile
	ld (xsp + 10), hl	; save result
	; Call 0x29AE9F with args (first)
	ld xwa, (xsp + 24)
	pushw wa
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	push xwa
	ld xwa, (xsp + 26)
	push xwa
	call HDAE5000_MemCopy
	; Call 0x29AE9F with args (second)
	ld xwa, (xsp + 26)
	pushw wa
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	add xwa, (xsp + 36)
	push xwa
	ld xwa, (xsp + 28)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 20)	; clean up pushed args
	; Read metadata FROM table and store to globals
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	ld xbc, HDAE5000_RAM_HdStreamBuffer
	add xbc, xwa
	ld a, (xbc)
	ld (HDAE5000_RAM_SeparateOutputMode:24), a; (0x22B2F4)
	; Read at offset+1
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	inc 1, xwa
	ld xbc, HDAE5000_RAM_HdStreamBuffer
	add xbc, xwa
	ld a, (xbc)
	ld (HDAE5000_RAM_SeparateDrumPart:24), a; (0x23A0A0)
	; Read at offset+2
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	inc 2, xwa
	ld xbc, HDAE5000_RAM_HdStreamBuffer
	add xbc, xwa
	ld a, (xbc)
	ld (HDAE5000_RAM_SeparateBassPart:24), a; (0x23A09E)
	; Call 0x284FD6
	call HDAE5000_SeparateOutput_Apply
	; Final workspace dispatch
	ld wa, (xsp + 10)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_HamaFnTable)
	ld xhl, (xbc + HamaFn_PostLswLoad)	; (XBC+0x10)
	call (xhl)
.Lts907_load:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 28)
	ret

HDAE5000_LoadSong_Pmt:	; 0x2908B1 (335 bytes)
	; Load part 1 (PMT) of song (WA = directory, BC = song): if its slot (song
	; record +40, 0x20165A + dir*0x4C0 + song*0x4C) is not 0xFFFFFFFF, read the
	; chain with HDAE5000_HD_ReadFile and hand the data to the main CPU
	; (workspace 0x0E88 table callbacks).  HL = 0 when there is no such part,
	; else ReadFile's result.  Called by HDAE5000_LoadSong for mask bit 1.
	lda xsp, (xsp - 38)
	push xiz
	ld (xsp + 38), bc	; save file number
	ld (xsp + 40), wa	; save directory
	ldw (xsp + 12), 0x0000	; init result = 0
	ldw (xsp + 4), 0x0000	; init flag = 0
	; First multiply: compute table offset
	ld wa, (xsp + 38)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 40)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	; Check if entry exists
	lda xwa, (0x20165a:24); 0x20165A (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lts8b1_load	; entry doesn't exist
	; Workspace dispatch with WA=2 (buffer at xsp+30)
	lda xwa, (xsp + 30)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); 0x23A1A2
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)
	ld wa, 2:i3
	call (xhl)
	; Save cell_params ptr
	lda xwa, (xsp + 14)
	ld (xsp + 10), xwa
	; Second multiply: compute table offset
	ld wa, (xsp + 38)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 40)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	; Table lookup via 0x29811C
	lda xwa, (0x20165a:24); 0x20165A
	add xwa, xhl
	ld xbc, xwa
	ld xwa, (xsp + 10)
	ld xde, xbc
	ld xbc, 0x00000010
	call HDAE5000_HD_ReadFile
	ld (xsp + 12), hl	; save result
	; Check workspace byte
	cp (xsp + 29), 0x08
	jr nz, .Lts8b1_skip
	; Set flag and override
	ldw (xsp + 4), 0x0001
	ld xwa, 0x00001EB0
	ld (xsp + 34), xwa
.Lts8b1_skip:
	; Workspace dispatch (d8 0x1C)
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); 0x23A1A2
	ld xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_PrePmLoad)	; (XWA+0x1C)
	call (xhl)
	; Save workspace and params ptrs
	lda xwa, (xsp + 30)
	ld (xsp + 6), xwa
	lda xwa, (xsp + 34)
	ld (xsp + 10), xwa
	; Third multiply: compute table offset
	ld wa, (xsp + 38)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 40)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	; Table update via 0x29811C (with double dereference)
	lda xwa, (0x20165a:24); 0x20165A
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 6)
	ld xwa, (xwa)
	ld xbc, (xsp + 10)
	ld xbc, (xbc)
	call HDAE5000_HD_ReadFile
	ld (xsp + 12), hl	; save result
	; Check flag
	cpw (xsp + 4), 0x0001
	jr nz, .Lts8b1_final
	; Conditional: store 0x50 and call 0x29AE9F
	ld (xsp + 29), 0x50
	pushw 0x0010
	lda xwa, (xsp + 16)
	push xwa
	ld xwa, (xsp + 36)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 10)	; cleanup pushed args
.Lts8b1_final:
	; Final workspace dispatch
	ld wa, (xsp + 12)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24); 0x23A1A2
	ld xbc, (xbc + WS_HamaFnTable)
	ld xhl, (xbc + HamaFn_PostPmLoad)	; (XBC+0x20)
	call (xhl)
.Lts8b1_load:
	ld hl, (xsp + 12)
	pop xiz
	lda xsp, (xsp + 38)
	ret

HDAE5000_LoadSong_Sqt:	; 0x290A00 (390 bytes)
	; Load part 2 (SQT) of song (WA = directory, BC = song): if its slot (song
	; record +44, 0x20165E + dir*0x4C0 + song*0x4C) is not 0xFFFFFFFF, read the
	; chain with HDAE5000_HD_ReadFile and hand the data to the main CPU
	; (workspace 0x0E88 table callbacks).  HL = 0 when there is no such part,
	; else ReadFile's result.  Called by HDAE5000_LoadSong for mask bit 2.
	lda xsp, (xsp - 28)
	push xiz
	ld (xsp + 28), bc	; save file number
	ld (xsp + 30), wa	; save directory
	ldw (xsp + 10), 0x0000	; init result = 0
	; First multiply: compute table offset
	ld wa, (xsp + 28)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	; Check if entry exists
	lda xwa, (0x20165e:24); 0x20165E (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lts0a0_load	; entry doesn't exist
	; Workspace dispatch WA=3 (buffer at xsp+20)
	lda xwa, (xsp + 20)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); 0x23A1A2
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)
	ld wa, 3:i3
	call (xhl)
	; Workspace dispatch WA=4 (buffer at xsp+12)
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)
	ld wa, 4:i3
	call (xhl)
	; Save workspace ptr
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ld (xsp + 8), xwa
	; Second multiply: compute table offset
	ld wa, (xsp + 28)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	; Table lookup via 0x29811C
	lda xwa, (0x20165e:24); 0x20165E
	add xwa, xhl
	ld xbc, xwa
	ld xwa, (xsp + 8)
	ld xde, xbc
	ld xbc, 0x00005000
	call HDAE5000_HD_ReadFile
	; Check result
	cp hl, 0xFFFF
	jr nz, .Lts0a0_process
	ldw hl, 0xFFFF
	jrl .Lts0a0_exit	; skip result load
.Lts0a0_process:
	; Compute slot address from workspace data
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ldb_sri0 e, (xwa + 0x00c7)               ; ld E, (XWA+0x00C7)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ld xbc, xwa
	ld a, e
	extz wa
	sla wa, 10
	exts xwa
	add xwa, xwa
	add xbc, xwa
	lda xwa, (xbc + 78)	; XBC + 0x4E
	ld xbc, xwa
	ld wa, (xbc)
	extz xwa
	ld (xsp + 4), xwa
	sll xwa, 4
	ld (xsp + 4), xwa
	ld xwa, (xsp + 24)
	add (xsp + 4), xwa	; add workspace value to slot
	; Workspace dispatch (d8 0x2C)
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); 0x23A1A2
	ld xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_SeqLoadPre)	; (XWA+0x2C)
	call (xhl)
	; Save ptr
	lda xwa, (xsp + 20)
	ld (xsp + 8), xwa
	; Third multiply: compute table offset
	ld wa, (xsp + 28)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	; Table update via 0x29811C
	lda xwa, (0x20165e:24); 0x20165E
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xwa, (xwa)
	ld xbc, (xsp + 4)
	call HDAE5000_HD_ReadFile
	ld (xsp + 10), hl	; save result
	; Final workspace dispatch at (XBC+0x30)
	ld wa, (xsp + 10)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24); 0x23A1A2
	ld xbc, (xbc + WS_HamaFnTable)
	ld xhl, (xbc + HamaFn_SeqLoadPost)	; (XBC+0x30)
	call (xhl)
	; Extra function call via workspace chain
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); 0x23A1A2
	ld xwa, (xwa + 0x11fa)             ; ld XWA, (XWA+0x11FA)
	ld xhl, (xwa + 24)	; (XWA+0x18)
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x01C00013
	ld xde, 0:i3
	call (xhl)
.Lts0a0_load:
	ld hl, (xsp + 10)
.Lts0a0_exit:
	pop xiz
	lda xsp, (xsp + 28)
	ret

HDAE5000_LoadSong_Cmp:	; 0x290B86 (303 bytes)
	; Load part 3 (CMP) of song (WA = directory, BC = song): if its slot (song
	; record +48, 0x201662 + dir*0x4C0 + song*0x4C) is not 0xFFFFFFFF, read the
	; chain with HDAE5000_HD_ReadFile and hand the data to the main CPU
	; (workspace 0x0E88 table callbacks).  HL = 0 when there is no such part,
	; else ReadFile's result.  Called by HDAE5000_LoadSong for mask bit 3.
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), bc	; save file number
	ld (xsp + 22), wa	; save directory
	ldw (xsp + 10), 0x0000	; init result = 0
	; 1st multiply: check entry existence
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201662:24); 0x201662 (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lts90b_load
	; Workspace dispatch with WA=5
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); workspace ptr
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)             ; (XWA+0x0080)
	ld wa, 5:i3
	call (xhl)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ld (xsp + 8), xwa
	; 2nd multiply: table lookup
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201662:24); 0x201662
	add xwa, xhl
	ld xbc, xwa
	ld xwa, (xsp + 8)
	ld xde, xbc
	ld xbc, 0x00000200
	call HDAE5000_HD_ReadFile
	cp hl, 0xFFFF
	jr nz, .Lts90b_ok
	ldw hl, 0xFFFF
	jr .Lts90b_exit
.Lts90b_ok:
	; Load workspace param and shift
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ld wa, (xwa + 46)	; workspace offset 0x2E
	extz xwa
	ld (xsp + 4), xwa
	sll xwa, 4
	ld (xsp + 4), xwa
	; Dispatch workspace handler
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_cmp_ld_mae)	; handler at offset 0x3C
	call (xhl)
	; 3rd multiply: final table lookup
	lda xwa, (xsp + 12)
	ld (xsp + 8), xwa
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201662:24); 0x201662
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xwa, (xwa)
	ld xbc, (xsp + 4)
	call HDAE5000_HD_ReadFile
	ld (xsp + 10), hl
	; Post-processing dispatch
	ld wa, (xsp + 10)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_HamaFnTable)
	ld xhl, (xbc + HamaFn_cmp_ld_ato)	; post offset 0x40
	call (xhl)
.Lts90b_load:
	ld hl, (xsp + 10)	; load result
.Lts90b_exit:
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_LoadSong_Tm:	; 0x290CB5 (220 bytes)
	; Load part 4 (TM) of song (WA = directory, BC = song): if its slot (song
	; record +52, 0x201666 + dir*0x4C0 + song*0x4C) is not 0xFFFFFFFF, read the
	; chain with HDAE5000_HD_ReadFile and hand the data to the main CPU
	; (workspace 0x0E88 table callbacks).  HL = 0 when there is no such part,
	; else ReadFile's result.  Called by HDAE5000_LoadSong for mask bit 4.
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), bc
	ld (xsp + 22), wa
	ldw (xsp + 10), 0x0000	; init result = 0
	; Check if table entry exists
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201666:24); 0x201666
	add xwa, xhl
	ld xwa, (xwa)		; load table entry
	cp xwa, 0xFFFFFFFF	; empty?
	jrl z, .Lts90c_exit	; skip all if -1
	; Workspace dispatch 1
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)
	ld wa, 6:i3
	call (xhl)
	ld xwa, 0x000072AA
	ld (xsp + 16), xwa
	; Workspace dispatch 2
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_PreTmLoad)	; (XWA+0x4C)
	call (xhl)
	; Table lookup
	lda xwa, (xsp + 12)
	ld (xsp + 4), xwa
	lda xwa, (xsp + 16)
	ld (xsp + 8), xwa
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201666:24); 0x201666
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld xbc, (xsp + 8)
	ld xbc, (xbc)
	call HDAE5000_HD_ReadFile		; write entry
	ld (xsp + 10), hl	; save result
	; Post-processing
	ld wa, (xsp + 10)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_HamaFnTable)
	ld xhl, (xbc + HamaFn_PostTmLoad)	; (XBC+0x50)
	call (xhl)
.Lts90c_exit:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_LoadSong_Msp:	; 0x290D91 (303 bytes)
	; Load part 5 (MSP) of song (WA = directory, BC = song): if its slot (song
	; record +56, 0x20166A + dir*0x4C0 + song*0x4C) is not 0xFFFFFFFF, read the
	; chain with HDAE5000_HD_ReadFile and hand the data to the main CPU
	; (workspace 0x0E88 table callbacks).  HL = 0 when there is no such part,
	; else ReadFile's result.  Called by HDAE5000_LoadSong for mask bit 5.
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), bc
	ld (xsp + 22), wa
	ldw (xsp + 10), 0x0000
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20166a:24); 0x20166A (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lts90d_load
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)
	ld wa, 7:i3
	call (xhl)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld (xsp + 8), xwa
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20166a:24); 0x20166A
	add xwa, xhl
	ld xbc, xwa
	ld xwa, (xsp + 8)
	ld xde, xbc
	ld xbc, 0x00000200
	call HDAE5000_HD_ReadFile
	cp hl, 0xFFFF
	jr nz, .Lts90d_ok
	ldw hl, 0xFFFF
	jr .Lts90d_exit
.Lts90d_ok:
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld wa, (xwa + 28)	; workspace offset 0x1C
	extz xwa
	ld (xsp + 4), xwa
	sll xwa, 4
	ld (xsp + 4), xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_msp_ld_mae)	; handler at offset 0x5C
	call (xhl)
	lda xwa, (xsp + 12)
	ld (xsp + 8), xwa
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20166a:24); 0x20166A
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xwa, (xwa)
	ld xbc, (xsp + 4)
	call HDAE5000_HD_ReadFile
	ld (xsp + 10), hl
	ld wa, (xsp + 10)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_HamaFnTable)
	ld xhl, (xbc + HamaFn_msp_ld_ato)	; post offset 0x60
	call (xhl)
.Lts90d_load:
	ld hl, (xsp + 10)
.Lts90d_exit:
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_LoadSong_Rcm:	; 0x290EC0 (133 bytes)
	; Load part 6 (RCM) of song (WA = directory, BC = song): if its slot (song
	; record +60, 0x20166E + dir*0x4C0 + song*0x4C) is not 0xFFFFFFFF, read the
	; chain with HDAE5000_HD_ReadFile and hand the data to the main CPU
	; (workspace 0x0E88 table callbacks).  HL = 0 when there is no such part,
	; else ReadFile's result.  Called by HDAE5000_LoadSong for mask bit 6.
	dec 4, xsp		; allocate 4 bytes on stack
	push xiz		; save XIZ
	ld (xsp + 4), bc	; save BC (file number param)
	ld (xsp + 6), wa	; save WA (partition param)
	ld wa, (xsp + 4)	; WA = file number
	extz xwa		; zero-extend to 32-bit
	ld xbc, 0x0000004C	; multiplier = 76
	call HDAE5000_Multiply		; multiply XWA * XBC
	ld xiz, xhl		; XIZ = file_number * 76
	ld wa, (xsp + 6)	; WA = partition
	extz xwa		; zero-extend to 32-bit
	ld xbc, 0x000004C0	; multiplier = 1216
	call HDAE5000_Multiply		; multiply XWA * XBC
	add xhl, 0x780		; XHL += 1920 (header offset)
	add xhl, xiz		; XHL += file_number * 76
	lda xwa, (0x20166e:24); XWA = 0x20166E (table base)
	add xwa, xhl		; XWA = base + computed offset
	ld xwa, (xwa)		; XWA = table entry value
	cp xwa, 0xFFFFFFFF	; empty entry?
	jr z, .Lts290_exit	; skip if -1
	ld xiy, 0x002F8DD8	; destination for ldirw
	ld xix, HDAE5000_RAM_HdStreamBufferEnd	; source for ldirw
	ld bc, 4:i3		; count = 4 words (8 bytes)
	mriw2 0x95, 0x11	; ldirw — copy from XIX to XIY
	ld wa, (xsp + 6)	; reload partition
	ld (0x238f1e:24), wa; ld (0x238F1E), WA
	ld wa, (xsp + 4)	; reload file number
	ld (0x238f20:24), wa; ld (0x238F20), WA
	lda xwa, (HDAE5000_RcmStream_Read:24); XWA = 0x293F96 (function ptr 1)
	ld xde, xwa		; XDE = function ptr 1
	lda xwa, (HDAE5000_RcmStream_LastResult:24); XWA = 0x29414C (function ptr 2)
	ld xbc, xwa		; XBC = function ptr 2
	ld xwa, xde		; XWA = function ptr 1
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24); XDE = (0x23A1A2) workspace ptr
	ld xde, (xde + WS_HamaFnTable)             ; XDE = (XDE+0x0E88)
	ld_sril xhl, (xde + HamaFn_rcm_ld_XAPR_j)             ; XHL = (XDE+0x00B0) handler
	call (xhl)		; dispatch handler
.Lts290_exit:
	ld hl, 0:i3		; return 0
	pop xiz			; restore XIZ
	inc 4, xsp		; deallocate 4 bytes
	ret

HDAE5000_LoadSong_Md:	; 0x290F45 (248 bytes)
	; Load part 7 (MD) of song (WA = directory, BC = song): if its slot (song
	; record +64, 0x201672 + dir*0x4C0 + song*0x4C) is not 0xFFFFFFFF, read the
	; chain with HDAE5000_HD_ReadFile and hand the data to the main CPU
	; (workspace 0x0E88 table callbacks).  HL = 0 when there is no such part,
	; else ReadFile's result.  Called by HDAE5000_LoadSong for mask bit 7.
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), bc	; save file number
	ld (xsp + 22), wa	; save directory
	ldw (xsp + 10), 0x0000	; init result = 0
	; First multiply: compute table offset
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	; Check if entry exists
	lda xwa, (0x201672:24); 0x201672 (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lts90f_load	; entry doesn't exist, result stays 0
	; Workspace dispatch with WA=9
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); 0x23A1A2
	ld xwa, (xwa + WS_HamaFnTable)             ; (XWA+0x0E88)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)             ; (XWA+0x0080)
	ldw wa, 0x0009
	call (xhl)
	; Another workspace dispatch (d8 displacement)
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_PreMidiLoad)	; (XWA+0x6C)
	call (xhl)
	; Save workspace ptr and buffer ptr
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ld (xsp + 4), xwa
	lda xwa, (xsp + 16)
	ld (xsp + 8), xwa
	; Second multiply: compute table offset
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	; Table lookup via 0x29811C
	lda xwa, (0x201672:24); 0x201672
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xsp + 8)
	ld xbc, (xbc)		; dereference buffer ptr
	call HDAE5000_HD_ReadFile
	ld (xsp + 10), hl	; save result
	; Post-processing: push arg and dispatch
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ld xbc, xwa
	ld xwa, (xsp + 16)
	ld de, wa
	ld xwa, 0x003D3000
	push xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_FlashWrite)	; (XWA+0x7C)
	ld wa, 1:i3
	call (xhl)
	; Read result and call final handler
	ld wa, (xsp + 10)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_HamaFnTable)
	ld xhl, (xbc + HamaFn_PostMidiLoad)	; (XBC+0x70)
	call (xhl)
.Lts90f_load:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_LoadSong_Tlx:	; 0x29103D (1023 bytes)
	; Load part 8 (TLX) of song (WA = directory, BC = song): if its slot (song
	; record +68, 0x201676 + dir*0x4C0 + song*0x4C) is not 0xFFFFFFFF, read the
	; chain with HDAE5000_HD_ReadFile and hand the data to the main CPU
	; (workspace 0x0E88 table callbacks).  HL = 0 when there is no such part,
	; else ReadFile's result.  Called by HDAE5000_LoadSong for mask bit 8.
; LTS: 0x29103D (1023 bytes)
	; ^ conversion-region size (local-label prefix .LTS_), not a routine size.

	lda	xsp, (xsp-24)
	pushw iz                                ; push IZ
	ld (xsp + 0x16), bc
	ld (xsp + 0x18), wa                     ; ld (XSP+0x18),WA
	ld	iz, 0:i3
	ld	wa, (xsp+22)
	extz xwa
	ld	xbc, 0x0000004c
	call HDAE5000_Multiply
	ld (xsp + 0x0a), xhl                    ; ld (XSP+0x0a),XHL
	ld	wa, (xsp+24)
	extz xwa
	ld	xbc, 0x000004c0
	call HDAE5000_Multiply
	add	xhl, 0x00000780
	add	xhl, (xsp+10)
	lda xwa, (0x201676:24)
	add	xwa, xhl
	ld xwa, (xwa)                           ; ld XWA,(XWA)
	cp	xwa, 0xffffffff
	jrl z, .LTS_1139                       ; [76 b6 00] jrl Z,0x291139
	call HDAE5000_Lyrics_ClearBuffer
	lda	xwa, (xsp+14)
	ld	xbc, xwa
	ldw	wa, 0x000a
	calr	HDAE5000_TlxPart_Describe
	lda	xwa, (xsp+14)
	ld (xsp + 0x06), xwa                    ; ld (XSP+0x06),XWA
	ld	wa, (xsp+22)
	extz xwa
	ld	xbc, 0x0000004c
	call HDAE5000_Multiply
	ld (xsp + 0x0a), xhl                    ; ld (XSP+0x0a),XHL
	ld	wa, (xsp+24)
	extz xwa
	ld	xbc, 0x000004c0
	call HDAE5000_Multiply
	add	xhl, 0x00000780
	add	xhl, (xsp+10)
	lda xwa, (0x201676:24)
	add	xwa, xhl
	ld	xbc, xwa
	ld xwa, (xsp + 0x06)                    ; ld XWA,(XSP+0x06)
	ld xwa, (xwa)                           ; ld XWA,(XWA)
	ld	xde, xbc
	ld	xbc, 0x00000016
	call HDAE5000_HD_ReadFile
	ld	iz, hl
	cp	iz, 0xffff
	jr z, .LTS_1139                        ; [66 58] jr Z,0x291139
	lda	xwa, (xsp+14)
	ld	xbc, xwa
	ldw	wa, 0x000a
	calr	HDAE5000_TlxPart_Describe
	lda	xwa, (xsp+14)
	ld (xsp + 0x02), xwa                    ; ld (XSP+0x02),XWA
	lda	xwa, (xsp+18)
	ld (xsp + 0x06), xwa                    ; ld (XSP+0x06),XWA
	ld	wa, (xsp+22)
	extz xwa
	ld	xbc, 0x0000004c
	call HDAE5000_Multiply
	ld (xsp + 0x0a), xhl                    ; ld (XSP+0x0a),XHL
	ld	wa, (xsp+24)
	extz xwa
	ld	xbc, 0x000004c0
	call HDAE5000_Multiply
	add	xhl, 0x00000780
	add	xhl, (xsp+10)
	lda xwa, (0x201676:24)
	add	xwa, xhl
	ld	xde, xwa
	ld xwa, (xsp + 0x02)                    ; ld XWA,(XSP+0x02)
	ld xwa, (xwa)                           ; ld XWA,(XWA)
	ld xbc, (xsp + 0x06)                    ; ld XBC,(XSP+0x06)
	ld xbc, (xbc)                           ; ld XBC,(XBC)
	call HDAE5000_HD_ReadFile
	ld	iz, hl
.LTS_1139:
	ld	hl, iz
	popw iz                                 ; pop IZ
	lda	xsp, (xsp+24)
	ret

HDAE5000_SaveSong:
	; Save a song: WA = directory, BC = song, XDE = its new name; stacked
	; words: part mask, UI flag, keep-spinning flag.  Mask 0 -> HL = 0 at once;
	; not enough free clusters (HDAE5000_Song_CheckFreeSpace) -> HL = 0xFFFF.
	; Otherwise, between the main-CPU callbacks, for k = 0..8: bit k set ->
	; HDAE5000_SaveSong_<part k> (a failed part is deleted again and ends the
	; run), bit k clear -> HDAE5000_DeleteSongPart_<part k>: the song ends up
	; holding exactly the parts of the mask.  Callers: HDAE5000_SaveSongWithUi
	; and PC-link service 15 ("SaveSongInMemoryToHd").
	lda	xsp, (xsp-10)
	push xiz
	ld (xsp + 0x06), xde                    ; ld (XSP+0x06),XDE
	ld (xsp + 0x0a), bc
	ld (xsp + 0x0c), wa                     ; ld (XSP+0x0c),WA
	ldw (xsp + 0x04), 0
	cpw	(xsp+22), 0x0000
	jr nz, .LTS_115f                       ; [6e 06] jr NZ,0x29115f
	ld	hl, (xsp+4)
	jrl t, .LTS_1435                       ; [78 d6 02] jrl T,0x291435
.LTS_115f:
	ld	wa, (xsp+22)
	calr	HDAE5000_Song_CheckFreeSpace
	cp	hl, 0xffff
	jrl z, .LTS_142d                       ; [76 c1 02] jrl Z,0x29142d
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_PlayHalt)
	ld	wa, 1:i3
	call	(xhl)
	cpw	(xsp+20), 0x0001
	jr nz, .LTS_1197                       ; [6e 11] jr NZ,0x291197
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_SleepMainTask)
	call	(xhl)
.LTS_1197:
	call HDAE5000_ATA_SoftReset_Status
	ld	wa, (xsp+22)
	bit	0x00, wa
	jr z, .LTS_11c3                        ; [66 20] jr Z,0x2911c3
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_SaveSong_Lsw
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTS_11cc                       ; [6e 14] jr NZ,0x2911cc
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_DeleteSongPart_Lsw
	jr t, .LTS_11cc                        ; [68 09] jr T,0x2911cc
.LTS_11c3:
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_DeleteSongPart_Lsw
.LTS_11cc:
	cpw	(xsp+4), 0xffff
	jr z, .LTS_11fb                        ; [66 28] jr Z,0x2911fb
	ld	wa, (xsp+22)
	bit	0x01, wa
	jr z, .LTS_11fb                        ; [66 20] jr Z,0x2911fb
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_SaveSong_Pmt
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTS_1204                       ; [6e 14] jr NZ,0x291204
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_DeleteSongPart_Pmt
	jr t, .LTS_1204                        ; [68 09] jr T,0x291204
.LTS_11fb:
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_DeleteSongPart_Pmt
.LTS_1204:
	cpw	(xsp+4), 0xffff
	jr z, .LTS_1233                        ; [66 28] jr Z,0x291233
	ld	wa, (xsp+22)
	bit	0x02, wa
	jr z, .LTS_1233                        ; [66 20] jr Z,0x291233
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_SaveSong_Sqt
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTS_123c                       ; [6e 14] jr NZ,0x29123c
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_DeleteSongPart_Sqt
	jr t, .LTS_123c                        ; [68 09] jr T,0x29123c
.LTS_1233:
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_DeleteSongPart_Sqt
.LTS_123c:
	cpw	(xsp+4), 0xffff
	jr z, .LTS_126b                        ; [66 28] jr Z,0x29126b
	ld	wa, (xsp+22)
	bit	0x03, wa
	jr z, .LTS_126b                        ; [66 20] jr Z,0x29126b
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_SaveSong_Cmp
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTS_1274                       ; [6e 14] jr NZ,0x291274
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_DeleteSongPart_Cmp
	jr t, .LTS_1274                        ; [68 09] jr T,0x291274
.LTS_126b:
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_DeleteSongPart_Cmp
.LTS_1274:
	cpw	(xsp+4), 0xffff
	jr z, .LTS_12a3                        ; [66 28] jr Z,0x2912a3
	ld	wa, (xsp+22)
	bit	0x04, wa
	jr z, .LTS_12a3                        ; [66 20] jr Z,0x2912a3
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_SaveSong_Tm
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTS_12ac                       ; [6e 14] jr NZ,0x2912ac
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_DeleteSongPart_Tm
	jr t, .LTS_12ac                        ; [68 09] jr T,0x2912ac
.LTS_12a3:
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_DeleteSongPart_Tm
.LTS_12ac:
	cpw	(xsp+4), 0xffff
	jr z, .LTS_12db                        ; [66 28] jr Z,0x2912db
	ld	wa, (xsp+22)
	bit	0x05, wa
	jr z, .LTS_12db                        ; [66 20] jr Z,0x2912db
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_SaveSong_Msp
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTS_12e4                       ; [6e 14] jr NZ,0x2912e4
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_DeleteSongPart_Msp
	jr t, .LTS_12e4                        ; [68 09] jr T,0x2912e4
.LTS_12db:
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_DeleteSongPart_Msp
.LTS_12e4:
	cpw	(xsp+4), 0xffff
	jr z, .LTS_1313                        ; [66 28] jr Z,0x291313
	ld	wa, (xsp+22)
	bit	0x06, wa
	jr z, .LTS_1313                        ; [66 20] jr Z,0x291313
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_SaveSong_Rcm
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTS_131c                       ; [6e 14] jr NZ,0x29131c
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_DeleteSongPart_Rcm
	jr t, .LTS_131c                        ; [68 09] jr T,0x29131c
.LTS_1313:
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_DeleteSongPart_Rcm
.LTS_131c:
	cpw	(xsp+4), 0xffff
	jr z, .LTS_134b                        ; [66 28] jr Z,0x29134b
	ld	wa, (xsp+22)
	bit	0x07, wa
	jr z, .LTS_134b                        ; [66 20] jr Z,0x29134b
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_SaveSong_Md
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTS_1354                       ; [6e 14] jr NZ,0x291354
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_DeleteSongPart_Md
	jr t, .LTS_1354                        ; [68 09] jr T,0x291354
.LTS_134b:
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_DeleteSongPart_Md
.LTS_1354:
	cpw	(xsp+4), 0xffff
	jr z, .LTS_1383                        ; [66 28] jr Z,0x291383
	ld	wa, (xsp+22)
	bit	0x08, wa
	jr z, .LTS_1383                        ; [66 20] jr Z,0x291383
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_SaveSong_Tlx
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTS_138c                       ; [6e 14] jr NZ,0x29138c
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_DeleteSongPart_Tlx
	jr t, .LTS_138c                        ; [68 09] jr T,0x29138c
.LTS_1383:
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	HDAE5000_DeleteSongPart_Tlx
.LTS_138c:
	cpw	(xsp+4), 0xffff
	jr z, .LTS_13d5                        ; [66 42] jr Z,0x2913d5
	pushw 0x001a
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	push xwa
	ld	wa, (xsp+16)
	extz xwa
	ld	xbc, 0x0000004c
	call HDAE5000_Multiply
	ld	xiz, xhl
	ld	wa, (xsp+18)
	extz xwa
	ld	xbc, 0x000004c0
	call HDAE5000_Multiply
	add	xhl, 0x00000780
	add	xhl, xiz
	ld	xwa, HDAE5000_RAM_DirNames
	add	xwa, xhl
	push xwa
	call HDAE5000_StrNCpy
	lda	xsp, (xsp+10)
	call HDAE5000_HD_WriteTables_Status
	jr t, .LTS_13e7                        ; [68 12] jr T,0x2913e7
.LTS_13d5:
	pushw 0x0000
	pushm	(xsp+20)
	ld	wa, (xsp+16)
	ld	bc, (xsp+14)
	ldw	de, 0x01ff
	calr	HDAE5000_DeleteSongParts
.LTS_13e7:
	cpw	(xsp+18), 0x0001
	call	nz, (HDAE5000_ATA_Standby_Status:24)
	cpw	(xsp+20), 0x0001
	jr nz, .LTS_1409                       ; [6e 11] jr NZ,0x291409
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_WakeUpMainTask)
	call	(xhl)
.LTS_1409:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_EditSwRefresh)
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_PlayStandBy)
	call	(xhl)
	jr t, .LTS_1432                        ; [68 05] jr T,0x291432
.LTS_142d:
	ldw (xsp + 0x04), 65535
.LTS_1432:
	ld	hl, (xsp+4)
.LTS_1435:
	pop xiz                                 ; pop XIZ
	lda	xsp, (xsp+10)
	retd 0x0006		; retd 0x0006


HDAE5000_SaveSong_Lsw:	; 0x29143C (359 bytes)
	; Save part 0 (LSW) of song (WA = directory, BC = song) from the main
	; CPU's memory (workspace 0x0E88 table callbacks) to a new cluster chain
	; (HDAE5000_HD_WriteFile, streamed parts continue with
	; HDAE5000_HD_AppendFile) whose first cluster goes to slot +36; the part
	; byte +26 is set.  HL = 0 / 0xFFFF.  Called by HDAE5000_SaveSong, bit 0.
	lda xsp, (xsp - 28)
	push xiz
	ld (xsp + 28), bc	; save file number
	ld (xsp + 30), wa	; save directory
	; Workspace dispatch with WA=0 (buffer at xsp+20)
	lda xwa, (xsp + 20)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); 0x23A1A2
	ld xwa, (xwa + WS_HamaFnTable)             ; (XWA+0x0E88)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)             ; (XWA+0x0080)
	ld wa, 0:i3
	call (xhl)
	; Workspace dispatch with WA=1 (buffer at xsp+12)
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)
	ld wa, 1:i3
	call (xhl)
	; Compute arg and call Cell_Get_Params
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	calr HDAE5000_RoundUpToSector
	ld (xsp + 4), xhl
	; Workspace dispatch (d8 displacement 0x14)
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_PreLswSave)	; (XWA+0x14)
	call (xhl)
	; Call 0x29AEC7 with args
	ld xwa, (xsp + 4)
	pushw wa
	pushw 0x0000
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	push xwa
	call HDAE5000_MemFill
	; Call 0x29AE9F with args (first)
	ld xwa, (xsp + 32)
	pushw wa
	ld xwa, (xsp + 30)
	push xwa
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	push xwa
	call HDAE5000_MemCopy
	; Call 0x29AE9F with args (second)
	ld xwa, (xsp + 34)
	pushw wa
	ld xwa, (xsp + 32)
	push xwa
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	add xwa, (xsp + 48)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 28)	; clean up pushed args
	; Store metadata at 0x230F1C + offset
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	ld xbc, HDAE5000_RAM_HdStreamBuffer
	add xbc, xwa
	ld a, (HDAE5000_RAM_SeparateOutputMode:24); 0x22B2F4
	ld (xbc), a
	; Store at offset+1
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	inc 1, xwa
	ld xbc, HDAE5000_RAM_HdStreamBuffer
	add xbc, xwa
	ld a, (HDAE5000_RAM_SeparateDrumPart:24); 0x23A0A0
	ld (xbc), a
	; Store at offset+2
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	inc 2, xwa
	ld xbc, HDAE5000_RAM_HdStreamBuffer
	add xbc, xwa
	ld a, (HDAE5000_RAM_SeparateBassPart:24); 0x23A09E
	ld (xbc), a
	; Save workspace ptr
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ld (xsp + 8), xwa
	; Multiply: compute table offset
	ld wa, (xsp + 28)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	; Table lookup
	lda xwa, (0x201656:24); 0x201656 (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	call HDAE5000_HD_WriteFile
	ld (xsp + 10), hl	; save result
	ld wa, (xsp + 10)
	cp wa, 0xFFFF
	jr z, .Lti914_flag_done
	; Set flag
	ld wa, (xsp + 28)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20164c:24); 0x20164C (flag base)
	add xwa, xhl
	ld (xwa), 0x01
.Lti914_flag_done:
	; Final workspace dispatch
	ld wa, (xsp + 10)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_HamaFnTable)
	ld xhl, (xbc + HamaFn_PostLswSave)	; (XBC+0x18)
	call (xhl)
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 28)
	ret

HDAE5000_SaveSong_Pmt:	; 0x2915A3 (217 bytes)
	; Save part 1 (PMT) of song (WA = directory, BC = song) from the main
	; CPU's memory (workspace 0x0E88 table callbacks) to a new cluster chain
	; (HDAE5000_HD_WriteFile, streamed parts continue with
	; HDAE5000_HD_AppendFile) whose first cluster goes to slot +40; the part
	; byte +27 is set.  HL = 0 / 0xFFFF.  Called by HDAE5000_SaveSong, bit 1.
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), bc
	ld (xsp + 22), wa
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)
	ld wa, 2:i3		; operation code = 2
	call (xhl)
	ld xwa, (xsp + 16)
	calr HDAE5000_RoundUpToSector
	ld (xsp + 16), xhl	; save result
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_PrePmSave)	; (XWA+0x24)
	call (xhl)
	lda xwa, (xsp + 12)
	ld (xsp + 4), xwa
	lda xwa, (xsp + 16)
	ld (xsp + 8), xwa
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20165a:24); 0x20165A
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld xbc, (xsp + 8)
	ld xbc, (xbc)
	call HDAE5000_HD_WriteFile
	ld (xsp + 10), hl
	ld wa, (xsp + 10)
	cp wa, 0xFFFF
	jr z, .Lts915_post
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20164d:24); 0x20164D
	add xwa, xhl
	ld (xwa), 0x01
.Lts915_post:
	ld wa, (xsp + 10)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_HamaFnTable)
	ld xhl, (xbc + HamaFn_PostPmSave)	; (XBC+0x28)
	call (xhl)
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_SaveSong_Sqt:	; 0x29167C (226 bytes)
	; Save part 2 (SQT) of song (WA = directory, BC = song) from the main
	; CPU's memory (workspace 0x0E88 table callbacks) to a new cluster chain
	; (HDAE5000_HD_WriteFile, streamed parts continue with
	; HDAE5000_HD_AppendFile) whose first cluster goes to slot +44; the part
	; byte +28 is set.  HL = 0 / 0xFFFF.  Called by HDAE5000_SaveSong, bit 2.
	lda xsp, (xsp - 30)	; larger stack frame
	push xiz
	ld (xsp + 30), bc	; save file number
	ld (xsp + 32), wa	; save directory
	; Workspace dispatch 1: buffer at XSP+22
	lda xwa, (xsp + 22)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)
	ld wa, 3:i3		; operation code = 3
	call (xhl)
	; Workspace dispatch 2: buffer at XSP+14
	lda xwa, (xsp + 14)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)
	ld wa, 4:i3		; operation code = 4
	call (xhl)
	; Workspace dispatch 3: compute address
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld xix, (xwa + HamaFn_SeqSavePre)	; (XWA+0x34)
	call (xix)
	ld xwa, (xsp + 26)	; load base value
	add xwa, xhl		; add dispatch result
	ld (xsp + 6), xwa	; save computed address
	; Setup pointers
	lda xwa, (xsp + 22)
	ld (xsp + 10), xwa
	; Table lookup
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20165e:24); 0x20165E
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 10)
	ld xwa, (xwa)
	ld xbc, (xsp + 6)
	call HDAE5000_HD_WriteFile
	cp hl, 0xFFFF		; check result (HL, not WA)
	jr z, .Lts916_post	; skip flag if failed
	; Recompute for flag table
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20164e:24); 0x20164E
	add xwa, xhl
	ld (xwa), 0x01
.Lts916_post:
	ld wa, (xsp + 4)	; WA = result param
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_HamaFnTable)
	ld xhl, (xbc + HamaFn_SeqSavePost)	; (XBC+0x38)
	call (xhl)
	ld hl, (xsp + 4)	; HL = result
	pop xiz
	lda xsp, (xsp + 30)	; deallocate 30 bytes
	ret

HDAE5000_SaveSong_Cmp:	; 0x29175E (211 bytes)
	; Save part 3 (CMP) of song (WA = directory, BC = song) from the main
	; CPU's memory (workspace 0x0E88 table callbacks) to a new cluster chain
	; (HDAE5000_HD_WriteFile, streamed parts continue with
	; HDAE5000_HD_AppendFile) whose first cluster goes to slot +48; the part
	; byte +29 is set.  HL = 0 / 0xFFFF.  Called by HDAE5000_SaveSong, bit 3.
	lda xsp, (xsp - 20)	; allocate 20 bytes
	push xiz
	ld (xsp + 20), bc	; save file number
	ld (xsp + 22), wa	; save directory
	lda xwa, (xsp + 12)
	ld xbc, xwa		; XBC = buffer addr
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); workspace ptr
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)
	ld wa, 5:i3		; operation code = 5
	call (xhl)
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); reload workspace
	ld xwa, (xwa + WS_HamaFnTable)
	ld xix, (xwa + HamaFn_cmp_sv_mae)	; (XWA+0x44)
	call (xix)
	ld (xsp + 16), xhl	; save dispatch result
	lda xwa, (xsp + 12)
	ld (xsp + 4), xwa
	lda xwa, (xsp + 16)
	ld (xsp + 8), xwa
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201662:24); 0x201662
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld xbc, (xsp + 8)
	ld xbc, (xbc)
	call HDAE5000_HD_WriteFile
	ld (xsp + 10), hl
	ld wa, (xsp + 10)
	cp wa, 0xFFFF
	jr z, .Lts917_post
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20164f:24); 0x20164F
	add xwa, xhl
	ld (xwa), 0x01
.Lts917_post:
	ld wa, (xsp + 10)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_HamaFnTable)
	ld xhl, (xbc + HamaFn_cmp_sv_ato)	; (XBC+0x48)
	call (xhl)
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_SaveSong_Tm:	; 0x291831 (216 bytes)
	; Save part 4 (TM) of song (WA = directory, BC = song) from the main
	; CPU's memory (workspace 0x0E88 table callbacks) to a new cluster chain
	; (HDAE5000_HD_WriteFile, streamed parts continue with
	; HDAE5000_HD_AppendFile) whose first cluster goes to slot +52; the part
	; byte +30 is set.  HL = 0 / 0xFFFF.  Called by HDAE5000_SaveSong, bit 4.
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), bc
	ld (xsp + 22), wa
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)
	ld wa, 6:i3		; operation code = 6
	call (xhl)
	ld xwa, 0x000072AA	; constant for XSP+16
	ld (xsp + 16), xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_PreTmSave)	; (XWA+0x54)
	call (xhl)
	lda xwa, (xsp + 12)
	ld (xsp + 4), xwa
	lda xwa, (xsp + 16)
	ld (xsp + 8), xwa
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201666:24); 0x201666
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld xbc, (xsp + 8)
	ld xbc, (xbc)
	call HDAE5000_HD_WriteFile
	ld (xsp + 10), hl
	ld wa, (xsp + 10)
	cp wa, 0xFFFF
	jr z, .Lts918_post
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201650:24); 0x201650
	add xwa, xhl
	ld (xwa), 0x01
.Lts918_post:
	ld wa, (xsp + 10)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_HamaFnTable)
	ld xhl, (xbc + HamaFn_PostTmSave)	; (XBC+0x58)
	call (xhl)
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_SaveSong_Msp:	; 0x291909 (211 bytes)
	; Save part 5 (MSP) of song (WA = directory, BC = song) from the main
	; CPU's memory (workspace 0x0E88 table callbacks) to a new cluster chain
	; (HDAE5000_HD_WriteFile, streamed parts continue with
	; HDAE5000_HD_AppendFile) whose first cluster goes to slot +56; the part
	; byte +31 is set.  HL = 0 / 0xFFFF.  Called by HDAE5000_SaveSong, bit 5.
	lda xsp, (xsp - 20)	; allocate 20 bytes
	push xiz
	ld (xsp + 20), bc	; save file number
	ld (xsp + 22), wa	; save directory
	lda xwa, (xsp + 12)
	ld xbc, xwa		; XBC = buffer addr
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); workspace ptr
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)
	ld wa, 7:i3		; operation code = 7
	call (xhl)
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); reload workspace
	ld xwa, (xwa + WS_HamaFnTable)
	ld xix, (xwa + HamaFn_msp_sv_mae)	; (XWA+0x64)
	call (xix)
	ld (xsp + 16), xhl	; save dispatch result
	lda xwa, (xsp + 12)
	ld (xsp + 4), xwa
	lda xwa, (xsp + 16)
	ld (xsp + 8), xwa
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20166a:24); 0x20166A
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld xbc, (xsp + 8)
	ld xbc, (xbc)
	call HDAE5000_HD_WriteFile
	ld (xsp + 10), hl
	ld wa, (xsp + 10)
	cp wa, 0xFFFF
	jr z, .Lts919b_post
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201651:24); 0x201651
	add xwa, xhl
	ld (xwa), 0x01
.Lts919b_post:
	ld wa, (xsp + 10)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_HamaFnTable)
	ld xhl, (xbc + HamaFn_msp_sv_ato)	; (XBC+0x68)
	call (xhl)
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_SaveSong_Rcm:	; 0x2919DC (134 bytes)
	; Save part 6 (RCM) of song (WA = directory, BC = song) from the main
	; CPU's memory (workspace 0x0E88 table callbacks) to a new cluster chain
	; (HDAE5000_HD_WriteFile, streamed parts continue with
	; HDAE5000_HD_AppendFile) whose first cluster goes to slot +60; the part
	; byte +32 is set.  HL = 0 / 0xFFFF.  Called by HDAE5000_SaveSong, bit 6.
	push xiz		; save XIZ
	ld de, bc		; DE = BC (file number param)
	ld hl, 0:i3		; HL = 0
	ld xiy, 0x002F8DD8	; destination for ldirw
	ld xix, HDAE5000_RAM_HdStreamBufferEnd	; source for ldirw
	ld bc, 4:i3		; count = 4 words
	mriw2 0x95, 0x11	; ldirw — copy from XIX to XIY
	ld (0x238f1e:24), wa; ld (0x238F1E), WA — partition
	ld (0x238f20:24), de; ld (0x238F20), DE — file number
	ld wa, (0x238f20:24); WA = (0x238F20) file number
	extz xwa		; zero-extend to 32-bit
	ld xbc, 0x0000004C	; multiplier = 76
	call HDAE5000_Multiply		; multiply
	ld xiz, xhl		; XIZ = file_number * 76
	ld wa, (0x238f1e:24); WA = (0x238F1E) partition
	extz xwa		; zero-extend to 32-bit
	ld xbc, 0x000004C0	; multiplier = 1216
	call HDAE5000_Multiply		; multiply
	add xhl, 0x780		; XHL += 1920 (header offset)
	add xhl, xiz		; XHL += file_number * 76
	lda xwa, (0x20166e:24); XWA = 0x20166E (table base)
	add xwa, xhl		; XWA = base + computed offset
	calr HDAE5000_HD_WriteOpen
	ld wa, hl		; WA = result
	cp wa, 0xFFFF		; check for failure
	jr z, .Lts919_exit	; skip if failed
	lda xwa, (HDAE5000_RcmStream_FreeSpace:24); XWA = 0x294152
	ld xhl, xwa		; XHL = handler 1
	lda xwa, (HDAE5000_RcmStream_Write:24); XWA = 0x294069
	ld xbc, xwa		; XBC = handler 2
	lda xwa, (HDAE5000_RcmStream_LastResult:24); XWA = 0x29414C
	ld xde, xwa		; XDE = handler 3
	ld xwa, xhl		; XWA = handler 1
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24); XHL = (0x23A1A2) workspace ptr
	ld xhl, (xhl + WS_HamaFnTable)             ; XHL = (XHL+0x0E88)
	ld_sril xix, (xhl + HamaFn_rcm_sv_XAPR_j)             ; XIX = (XHL+0x00B4)
	call (xix)		; dispatch handler
	calr HDAE5000_HD_WriteClose
.Lts919_exit:
	pop xiz			; restore XIZ
	ret

HDAE5000_SaveSong_Md:	; 0x291A62 (209 bytes)
	; Save part 7 (MD) of song (WA = directory, BC = song) from the main
	; CPU's memory (workspace 0x0E88 table callbacks) to a new cluster chain
	; (HDAE5000_HD_WriteFile, streamed parts continue with
	; HDAE5000_HD_AppendFile) whose first cluster goes to slot +64; the part
	; byte +33 is set.  HL = 0 / 0xFFFF.  Called by HDAE5000_SaveSong, bit 7.
	lda xsp, (xsp - 20)	; allocate 20 bytes on stack
	push xiz		; save XIZ
	ld (xsp + 20), bc	; save BC param (file number)
	ld (xsp + 22), wa	; save WA param (partition)
	lda xwa, (xsp + 12)	; XWA = addr of local buffer
	ld xbc, xwa		; XBC = buffer address
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); XWA = (0x23A1A2) workspace ptr
	ld xwa, (xwa + WS_HamaFnTable)             ; XWA = (XWA+0x0E88)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)             ; XHL = (XWA+0x0080) handler
	ldw wa, 0x0009		; WA = 9 (operation code)
	call (xhl)		; dispatch
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); reload workspace ptr
	ld xwa, (xwa + WS_HamaFnTable)             ; XWA = (XWA+0x0E88)
	ld xhl, (xwa + HamaFn_PreMidiSave)	; XHL = (XWA+0x74) handler
	call (xhl)		; dispatch
	lda xwa, (xsp + 12)	; XWA = addr of local buffer
	ld (xsp + 4), xwa	; store buffer ptr
	lda xwa, (xsp + 16)	; XWA = addr of result area
	ld (xsp + 8), xwa	; store result ptr
	ld wa, (xsp + 20)	; WA = file number
	extz xwa
	ld xbc, 0x0000004C	; multiplier = 76
	call HDAE5000_Multiply		; multiply
	ld xiz, xhl		; XIZ = file_number * 76
	ld wa, (xsp + 22)	; WA = partition
	extz xwa
	ld xbc, 0x000004C0	; multiplier = 1216
	call HDAE5000_Multiply		; multiply
	add xhl, 0x780		; XHL += 1920
	add xhl, xiz		; XHL += file_number * 76
	lda xwa, (0x201672:24); XWA = 0x201672 (table base)
	add xwa, xhl		; XWA = base + offset
	ld xde, xwa		; XDE = table address
	ld xwa, (xsp + 4)	; XWA = buffer ptr
	ld xwa, (xwa)		; dereference
	ld xbc, (xsp + 8)	; XBC = result ptr
	ld xbc, (xbc)		; dereference
	call HDAE5000_HD_WriteFile		; compare/process
	ld (xsp + 10), hl	; save HL result
	ld wa, (xsp + 10)	; WA = result
	cp wa, 0xFFFF		; check for failure
	jr z, .Lts91a_post	; skip if failed
	ld wa, (xsp + 20)	; WA = file number (reload)
	extz xwa
	ld xbc, 0x0000004C	; multiplier = 76
	call HDAE5000_Multiply		; multiply
	ld xiz, xhl		; XIZ = file_number * 76
	ld wa, (xsp + 22)	; WA = partition (reload)
	extz xwa
	ld xbc, 0x000004C0	; multiplier = 1216
	call HDAE5000_Multiply		; multiply
	add xhl, 0x780		; XHL += 1920
	add xhl, xiz		; XHL += file_number * 76
	lda xwa, (0x201653:24); XWA = 0x201653 (flag table)
	add xwa, xhl		; XWA = base + offset
	ld (xwa), 0x01	; set flag byte to 1
.Lts91a_post:
	ld wa, (xsp + 10)	; WA = result (param for handler)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24); XBC = (0x23A1A2) workspace ptr
	ld xbc, (xbc + WS_HamaFnTable)             ; XBC = (XBC+0x0E88)
	ld xhl, (xbc + HamaFn_PostMidiSave)	; XHL = (XBC+0x78) handler
	call (xhl)		; dispatch
	ld hl, (xsp + 10)	; HL = result
	pop xiz			; restore XIZ
	lda xsp, (xsp + 20)	; deallocate 20 bytes
	ret

HDAE5000_SaveSong_Tlx:	; 0x291B33 (171 bytes)
	; Save part 8 (TLX) of song (WA = directory, BC = song) from the main
	; CPU's memory (workspace 0x0E88 table callbacks) to a new cluster chain
	; (HDAE5000_HD_WriteFile, streamed parts continue with
	; HDAE5000_HD_AppendFile) whose first cluster goes to slot +68; the part
	; byte +34 is set.  HL = 0 / 0xFFFF.  Called by HDAE5000_SaveSong, bit 8.
	lda xsp, (xsp - 20)	; allocate 20 bytes on stack
	push xiz		; save XIZ
	ld (xsp + 20), bc	; save BC param (file number)
	ld (xsp + 22), wa	; save WA param (partition)
	lda xwa, (xsp + 12)	; XWA = addr of local buffer
	ld xbc, xwa		; XBC = buffer address
	ldw wa, 0x000A		; WA = 10 (string length)
	calr HDAE5000_TlxPart_Describe	; init table entry
	ld xwa, (xsp + 16)	; XWA = param block
	calr HDAE5000_RoundUpToSector
	ld (xsp + 16), xhl	; save result XHL
	lda xwa, (xsp + 12)	; XWA = addr of local buffer
	ld (xsp + 4), xwa	; store buffer ptr
	lda xwa, (xsp + 16)	; XWA = addr of result
	ld (xsp + 8), xwa	; store result ptr
	ld wa, (xsp + 20)	; WA = file number
	extz xwa
	ld xbc, 0x0000004C	; multiplier = 76
	call HDAE5000_Multiply		; multiply
	ld xiz, xhl		; XIZ = file_number * 76
	ld wa, (xsp + 22)	; WA = partition
	extz xwa
	ld xbc, 0x000004C0	; multiplier = 1216
	call HDAE5000_Multiply		; multiply
	add xhl, 0x780		; XHL += 1920
	add xhl, xiz		; XHL += file_number * 76
	lda xwa, (0x201676:24); XWA = 0x201676 (table base)
	add xwa, xhl		; XWA = base + offset
	ld xde, xwa		; XDE = table address
	ld xwa, (xsp + 4)	; XWA = buffer ptr
	ld xwa, (xwa)		; dereference
	ld xbc, (xsp + 8)	; XBC = result ptr
	ld xbc, (xbc)		; dereference
	call HDAE5000_HD_WriteFile		; compare/process
	ld (xsp + 10), hl	; save HL result
	ld wa, (xsp + 10)	; WA = result
	cp wa, 0xFFFF		; check for failure
	jr z, .Lts91b_exit	; skip if failed
	ld wa, (xsp + 20)	; WA = file number (reload)
	extz xwa
	ld xbc, 0x0000004C	; multiplier = 76
	call HDAE5000_Multiply		; multiply
	ld xiz, xhl		; XIZ = file_number * 76
	ld wa, (xsp + 22)	; WA = partition (reload)
	extz xwa
	ld xbc, 0x000004C0	; multiplier = 1216
	call HDAE5000_Multiply		; multiply
	add xhl, 0x780		; XHL += 1920
	add xhl, xiz		; XHL += file_number * 76
	lda xwa, (0x201654:24); XWA = 0x201654 (flag table)
	add xwa, xhl		; XWA = base + offset
	ld (xwa), 0x01	; set flag byte to 1
.Lts91b_exit:
	ld hl, (xsp + 10)	; HL = result
	pop xiz			; restore XIZ
	lda xsp, (xsp + 20)	; deallocate 20 bytes
	ret

HDAE5000_TlxPart_Describe:	; 0x291BDE (47 bytes)
	; Initialize table entry structure with string address
	; Input: WA = offset, XBC = structure pointer
	; Output: HL = offset
	; (= the TLX part's extent for the part loaders/savers and PC-link
	; service 13: XBC = {long 0x22B430; long length}, length =
	; HDAE5000_SwapBytes32(0x22B442 pointer) + 22, also stored to 0x2304F2;
	; HL = WA.  0x5000 is the TLX size HDAE5000_Song_CheckFreeSpace reserves.)
	dec 2, xsp
	push xiz
	ld xiz, xbc			; XIZ = structure pointer
	ld (xsp + 4), wa		; save offset on stack
	lda xwa, (HDAE5000_RAM_LyricBuffer:24); 0x22B430 - base string address
	ld (xiz), xwa			; store string pointer in structure
	ld xwa, (0x22b442:24); 0x22B442 - load source string pointer
	call HDAE5000_SwapBytes32
	add hl, 0x0016			; add 22 to string length
	ld wa, hl
	exts xwa			; sign-extend to 32-bit
	ld (xiz + 4), xwa		; store computed size
	ld (0x2304f2:24), xwa; 0x2304F2 - global size variable
	ld hl, (xsp + 4)		; return saved offset
	pop xiz
	inc 2, xsp
	ret

HDAE5000_CheckFileSignature:	; 0x291C0D (2171 bytes)
	; Complex table initialization (large stack frame)
	; ^ corrected: HL = 0 if the file data at XBC carries part WA's
	;   signature, else 0xFFFF.  The signature table at 0x2F8E20 has 8-byte
	;   records {long string; u16 offset; u16 length} indexed by part: "HK"
	;   at +4 (LSW), "HK" (PMT), 01 08 at +5 (SQT), "HK\0" (CMP),
	;   "KN5000 SOUND RAM" (TM), "H\0K" (MSP, RCM), "HK" (MD), "TLhd" (TLX);
	;   compared with HDAE5000_StrNCmp.  Caller: HDAE5000_FdSong_CheckFiles.
; LTCI: 0x291C0D (2171 bytes)
	; ^ conversion-region size (local-label prefix .LTCI_), not a routine
	;   size: HDAE5000_CheckFileSignature (0x291C0D-0x291C57) and
	;   HDAE5000_FdSong_CheckFiles (0x291C58-0x292150).

	ld	de, wa
	extz xde                                ; extz XDE
	sll	xde, 0x03
	lda xhl, (0x2f8e26:24)
	add	xhl, xde
	ld	de, (xhl)
	pushw de                                ; push DE
	ld	de, wa
	extz xde                                ; extz XDE
	sll	xde, 0x03
	lda xhl, (0x2f8e24:24)
	add	xhl, xde
	ld	de, (xhl)
	extz xde                                ; extz XDE
	add	xde, xbc
	push xde
	extz xwa
	sll	xwa, 0x03
	ld	xbc, 0x002f8e20
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	call HDAE5000_StrNCmp
	add	xsp, 0x0000000a
	cp	hl, 0:i3
	jr nz, .LTCI_1c54                      ; [6e 04] jr NZ,0x291c54
	ld	hl, 0:i3
	jr t, .LTCI_1c57                       ; [68 03] jr T,0x291c57
.LTCI_1c54:
	ldw	hl, 0xffff
.LTCI_1c57:
	ret

HDAE5000_FdSong_CheckFiles:
	; Check a song on floppy before copying it: XWA = its 8-character name,
	; BC = part mask.  Fails (HL = 0xFFFF) if a "<name>.SEQ" or the file named
	; by 0x2F8EA2 opens (main-CPU callback 0x0E88 table +0x94, closed with
	; +0x9C), or if, for any part k in the mask, the first 512 bytes of
	; "<name><ext k>" (opened "rb" with +0xA0, read with +0xA8, closed with
	; +0xAC) fail HDAE5000_CheckFileSignature(k).  HL = 0 otherwise.
	lda_dri xsp, 0xFD, 0xE6, 0xFE	; lda XSP,XSP+0xfee6
	push xiz
	stw_dri bc, 0xFD, 0x1C, 0x01	; ld (XSP+0x011c),BC
	ld	xiz, xwa
	pushw 0x000d
	pushw 0x0000
	lda	xwa, (xsp+8)
	push xwa
	call HDAE5000_MemFill
	pushw 0x0008
	ld	xwa, xiz
	push xwa
	lda	xwa, (xsp+18)
	push xwa
	call HDAE5000_MemCopy
	pushw 0x002f
	pushw 0x8e9c
	lda	xwa, (xsp+34)
	push xwa
	call HDAE5000_StrCpy
	lda	xsp, (xsp+26)
	lda	xwa, (xsp+18)
	ld	xbc, xwa
	lda	xwa, (xsp+4)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_HamaFnTable)
	ld_sril	xix, (xde + HamaFn__findfirst)
	call	(xix)
	ld	xwa, xhl
	cp	xwa, 0xffffffff
	jr z, .LTCI_1cce                       ; [66 19] jr Z,0x291cce
	ld	xwa, xhl
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_HamaFnTable)
	ld_sril	xhl, (xbc + HamaFn__findclose)
	call	(xhl)
	ldw	hl, 0xffff
	jrl t, .LTCI_214a                      ; [78 7c 04] jrl T,0x29214a
.LTCI_1cce:
	pushw 0x002f
	pushw 0x8ea2
	lda	xwa, (xsp+16)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+18)
	ld	xbc, xwa
	lda	xwa, (xsp+4)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_HamaFnTable)
	ld_sril	xix, (xde + HamaFn__findfirst)
	call	(xix)
	ld	xwa, xhl
	cp	xwa, 0xffffffff
	jr z, .LTCI_1d1a                       ; [66 19] jr Z,0x291d1a
	ld	xwa, xhl
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_HamaFnTable)
	ld_sril	xhl, (xbc + HamaFn__findclose)
	call	(xhl)
	ldw	hl, 0xffff
	jrl t, .LTCI_214a                      ; [78 30 04] jrl T,0x29214a
.LTCI_1d1a:
	ldw_sri0	wa, (xsp + 0x011c)
	bit	0x00, wa
	jr z, .LTCI_1d91                       ; [66 6d] jr Z,0x291d91
	pushw 0x002f
	pushw 0x8ea8
	lda	xwa, (xsp+16)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+4)
	lda xbc, (0x2f8eae:24)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_HamaFnTable)
	ld_sril	xhl, (xde + HamaFn_fopen_ext)
	call	(xhl)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_HamaFnTable)
	ld_sril	xhl, (xbc + HamaFn_fread_ext)
	ld	xbc, 0x00000200
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_fclose_ext)
	call	(xhl)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld	xbc, xwa
	ld	wa, 0:i3
	calr	HDAE5000_CheckFileSignature
	cp	hl, 0xffff
	jr nz, .LTCI_1d91                      ; [6e 06] jr NZ,0x291d91
	ldw	hl, 0xffff
	jrl t, .LTCI_214a                      ; [78 b9 03] jrl T,0x29214a
.LTCI_1d91:
	ldw_sri0	wa, (xsp + 0x011c)
	bit	0x01, wa
	jr z, .LTCI_1e08                       ; [66 6d] jr Z,0x291e08
	pushw 0x002f
	pushw 0x8eb2
	lda	xwa, (xsp+16)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+4)
	lda xbc, (0x2f8eb8:24)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_HamaFnTable)
	ld_sril	xhl, (xde + HamaFn_fopen_ext)
	call	(xhl)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_HamaFnTable)
	ld_sril	xhl, (xbc + HamaFn_fread_ext)
	ld	xbc, 0x00000200
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_fclose_ext)
	call	(xhl)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld	xbc, xwa
	ld	wa, 1:i3
	calr	HDAE5000_CheckFileSignature
	cp	hl, 0xffff
	jr nz, .LTCI_1e08                      ; [6e 06] jr NZ,0x291e08
	ldw	hl, 0xffff
	jrl t, .LTCI_214a                      ; [78 42 03] jrl T,0x29214a
.LTCI_1e08:
	ldw_sri0	wa, (xsp + 0x011c)
	bit	0x02, wa
	jr z, .LTCI_1e7f                       ; [66 6d] jr Z,0x291e7f
	pushw 0x002f
	pushw 0x8ebc
	lda	xwa, (xsp+16)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+4)
	lda xbc, (0x2f8ec2:24)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_HamaFnTable)
	ld_sril	xhl, (xde + HamaFn_fopen_ext)
	call	(xhl)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_HamaFnTable)
	ld_sril	xhl, (xbc + HamaFn_fread_ext)
	ld	xbc, 0x00000200
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_fclose_ext)
	call	(xhl)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld	xbc, xwa
	ld	wa, 2:i3
	calr	HDAE5000_CheckFileSignature
	cp	hl, 0xffff
	jr nz, .LTCI_1e7f                      ; [6e 06] jr NZ,0x291e7f
	ldw	hl, 0xffff
	jrl t, .LTCI_214a                      ; [78 cb 02] jrl T,0x29214a
.LTCI_1e7f:
	ldw_sri0	wa, (xsp + 0x011c)
	bit	0x03, wa
	jr z, .LTCI_1ef6                       ; [66 6d] jr Z,0x291ef6
	pushw 0x002f
	pushw 0x8ec6
	lda	xwa, (xsp+16)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+4)
	lda xbc, (0x2f8ecc:24)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_HamaFnTable)
	ld_sril	xhl, (xde + HamaFn_fopen_ext)
	call	(xhl)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_HamaFnTable)
	ld_sril	xhl, (xbc + HamaFn_fread_ext)
	ld	xbc, 0x00000200
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_fclose_ext)
	call	(xhl)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld	xbc, xwa
	ld	wa, 3:i3
	calr	HDAE5000_CheckFileSignature
	cp	hl, 0xffff
	jr nz, .LTCI_1ef6                      ; [6e 06] jr NZ,0x291ef6
	ldw	hl, 0xffff
	jrl t, .LTCI_214a                      ; [78 54 02] jrl T,0x29214a
.LTCI_1ef6:
	ldw_sri0	wa, (xsp + 0x011c)
	bit	0x04, wa
	jr z, .LTCI_1f6d                       ; [66 6d] jr Z,0x291f6d
	pushw 0x002f
	pushw 0x8ed0
	lda	xwa, (xsp+16)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+4)
	lda xbc, (0x2f8ed4:24)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_HamaFnTable)
	ld_sril	xhl, (xde + HamaFn_fopen_ext)
	call	(xhl)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_HamaFnTable)
	ld_sril	xhl, (xbc + HamaFn_fread_ext)
	ld	xbc, 0x00000200
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_fclose_ext)
	call	(xhl)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld	xbc, xwa
	ld	wa, 4:i3
	calr	HDAE5000_CheckFileSignature
	cp	hl, 0xffff
	jr nz, .LTCI_1f6d                      ; [6e 06] jr NZ,0x291f6d
	ldw	hl, 0xffff
	jrl t, .LTCI_214a                      ; [78 dd 01] jrl T,0x29214a
.LTCI_1f6d:
	ldw_sri0	wa, (xsp + 0x011c)
	bit	0x05, wa
	jr z, .LTCI_1fe4                       ; [66 6d] jr Z,0x291fe4
	pushw 0x002f
	pushw 0x8ed8
	lda	xwa, (xsp+16)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+4)
	lda xbc, (0x2f8ede:24)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_HamaFnTable)
	ld_sril	xhl, (xde + HamaFn_fopen_ext)
	call	(xhl)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_HamaFnTable)
	ld_sril	xhl, (xbc + HamaFn_fread_ext)
	ld	xbc, 0x00000200
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_fclose_ext)
	call	(xhl)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld	xbc, xwa
	ld	wa, 5:i3
	calr	HDAE5000_CheckFileSignature
	cp	hl, 0xffff
	jr nz, .LTCI_1fe4                      ; [6e 06] jr NZ,0x291fe4
	ldw	hl, 0xffff
	jrl t, .LTCI_214a                      ; [78 66 01] jrl T,0x29214a
.LTCI_1fe4:
	ldw_sri0	wa, (xsp + 0x011c)
	bit	0x06, wa
	jr z, .LTCI_205b                       ; [66 6d] jr Z,0x29205b
	pushw 0x002f
	pushw 0x8ee2
	lda	xwa, (xsp+16)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+4)
	lda xbc, (0x2f8ee8:24)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_HamaFnTable)
	ld_sril	xhl, (xde + HamaFn_fopen_ext)
	call	(xhl)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_HamaFnTable)
	ld_sril	xhl, (xbc + HamaFn_fread_ext)
	ld	xbc, 0x00000200
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_fclose_ext)
	call	(xhl)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld	xbc, xwa
	ld	wa, 6:i3
	calr	HDAE5000_CheckFileSignature
	cp	hl, 0xffff
	jr nz, .LTCI_205b                      ; [6e 06] jr NZ,0x29205b
	ldw	hl, 0xffff
	jrl t, .LTCI_214a                      ; [78 ef 00] jrl T,0x29214a
.LTCI_205b:
	ldw_sri0	wa, (xsp + 0x011c)
	bit	0x07, wa
	jr z, .LTCI_20d1                       ; [66 6c] jr Z,0x2920d1
	pushw 0x002f
	pushw 0x8eec
	lda	xwa, (xsp+16)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+4)
	lda xbc, (0x2f8ef0:24)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_HamaFnTable)
	ld_sril	xhl, (xde + HamaFn_fopen_ext)
	call	(xhl)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_HamaFnTable)
	ld_sril	xhl, (xbc + HamaFn_fread_ext)
	ld	xbc, 0x00000200
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_fclose_ext)
	call	(xhl)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld	xbc, xwa
	ld	wa, 7:i3
	calr	HDAE5000_CheckFileSignature
	cp	hl, 0xffff
	jr nz, .LTCI_20d1                      ; [6e 05] jr NZ,0x2920d1
	ldw	hl, 0xffff
	jr t, .LTCI_214a                       ; [68 79] jr T,0x29214a
.LTCI_20d1:
	ldw_sri0	wa, (xsp + 0x011c)
	bit	0x08, wa
	jr z, .LTCI_2148                       ; [66 6d] jr Z,0x292148
	pushw 0x002f
	pushw 0x8ef4
	lda	xwa, (xsp+16)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+4)
	lda xbc, (0x2f8efa:24)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_HamaFnTable)
	ld_sril	xhl, (xde + HamaFn_fopen_ext)
	call	(xhl)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_HamaFnTable)
	ld_sril	xhl, (xbc + HamaFn_fread_ext)
	ld	xbc, 0x00000200
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_fclose_ext)
	call	(xhl)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld	xbc, xwa
	ldw	wa, 0x0008
	calr	HDAE5000_CheckFileSignature
	cp	hl, 0xffff
	jr nz, .LTCI_2148                      ; [6e 05] jr NZ,0x292148
	ldw	hl, 0xffff
	jr t, .LTCI_214a                       ; [68 02] jr T,0x29214a
.LTCI_2148:
	ld	hl, 0:i3
.LTCI_214a:
	pop xiz                                 ; pop XIZ
	lda_dri xsp, 0xFD, 0x1A, 0x01	; lda XSP,XSP+0x011a
	ret

HDAE5000_CopyFdSongToHd:
	; Copy a floppy song into song (WA = directory, BC = song): XDE = its name,
	; stacked: part mask and flags.  Checks the free space
	; (HDAE5000_Song_CheckFreeSpace), then per bit k HDAE5000_CopyFdSongToHd_<k>
	; (clear bits delete that part, HDAE5000_DeleteSongParts).  Caller:
	; HDAE5000_CopyToHd_Execute (the copy-to-HD screen).
	lda	xsp, (xsp-52)
	push xiz
	ld (xsp + 0x30), xde                    ; ld (XSP+0x30),XDE
	ld (xsp + 0x34), bc
	ld (xsp + 0x36), wa                     ; ld (XSP+0x36),WA
	ldw (xsp + 0x04), 0
	ld	wa, (xsp+64)
	calr	HDAE5000_Song_CheckFreeSpace
	cp	hl, 0xffff
	jrl z, .LTCI_2479                      ; [76 09 03] jrl Z,0x292479
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_PlayHalt)
	ld	wa, 1:i3
	call	(xhl)
	cpw	(xsp+62), 0x0001
	jr nz, .LTCI_219b                      ; [6e 11] jr NZ,0x29219b
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_SleepMainTask)
	call	(xhl)
.LTCI_219b:
	call HDAE5000_ATA_SoftReset_Status
	ld	wa, (xsp+64)
	bit	0x00, wa
	jr z, .LTCI_21c8                       ; [66 21] jr Z,0x2921c8
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	ld xde, (xsp + 0x30)                    ; ld XDE,(XSP+0x30)
	calr	HDAE5000_CopyFdSongToHd_Lsw
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTCI_21c8                      ; [6e 09] jr NZ,0x2921c8
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	calr	HDAE5000_DeleteSongPart_Lsw
.LTCI_21c8:
	cpw	(xsp+4), 0xffff
	jr z, .LTCI_21f8                       ; [66 29] jr Z,0x2921f8
	ld	wa, (xsp+64)
	bit	0x01, wa
	jr z, .LTCI_21f8                       ; [66 21] jr Z,0x2921f8
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	ld xde, (xsp + 0x30)                    ; ld XDE,(XSP+0x30)
	calr	HDAE5000_CopyFdSongToHd_Pmt
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTCI_21f8                      ; [6e 09] jr NZ,0x2921f8
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	calr	HDAE5000_DeleteSongPart_Pmt
.LTCI_21f8:
	cpw	(xsp+4), 0xffff
	jr z, .LTCI_2228                       ; [66 29] jr Z,0x292228
	ld	wa, (xsp+64)
	bit	0x02, wa
	jr z, .LTCI_2228                       ; [66 21] jr Z,0x292228
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	ld xde, (xsp + 0x30)                    ; ld XDE,(XSP+0x30)
	calr	HDAE5000_CopyFdSongToHd_Sqt
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTCI_2228                      ; [6e 09] jr NZ,0x292228
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	calr	HDAE5000_DeleteSongPart_Sqt
.LTCI_2228:
	cpw	(xsp+4), 0xffff
	jr z, .LTCI_2258                       ; [66 29] jr Z,0x292258
	ld	wa, (xsp+64)
	bit	0x03, wa
	jr z, .LTCI_2258                       ; [66 21] jr Z,0x292258
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	ld xde, (xsp + 0x30)                    ; ld XDE,(XSP+0x30)
	calr	HDAE5000_CopyFdSongToHd_Cmp
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTCI_2258                      ; [6e 09] jr NZ,0x292258
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	calr	HDAE5000_DeleteSongPart_Cmp
.LTCI_2258:
	cpw	(xsp+4), 0xffff
	jr z, .LTCI_2288                       ; [66 29] jr Z,0x292288
	ld	wa, (xsp+64)
	bit	0x04, wa
	jr z, .LTCI_2288                       ; [66 21] jr Z,0x292288
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	ld xde, (xsp + 0x30)                    ; ld XDE,(XSP+0x30)
	calr	HDAE5000_CopyFdSongToHd_Tm
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTCI_2288                      ; [6e 09] jr NZ,0x292288
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	calr	HDAE5000_DeleteSongPart_Tm
.LTCI_2288:
	cpw	(xsp+4), 0xffff
	jr z, .LTCI_22b8                       ; [66 29] jr Z,0x2922b8
	ld	wa, (xsp+64)
	bit	0x05, wa
	jr z, .LTCI_22b8                       ; [66 21] jr Z,0x2922b8
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	ld xde, (xsp + 0x30)                    ; ld XDE,(XSP+0x30)
	calr	HDAE5000_CopyFdSongToHd_Msp
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTCI_22b8                      ; [6e 09] jr NZ,0x2922b8
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	calr	HDAE5000_DeleteSongPart_Msp
.LTCI_22b8:
	cpw	(xsp+4), 0xffff
	jr z, .LTCI_22e8                       ; [66 29] jr Z,0x2922e8
	ld	wa, (xsp+64)
	bit	0x06, wa
	jr z, .LTCI_22e8                       ; [66 21] jr Z,0x2922e8
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	ld xde, (xsp + 0x30)                    ; ld XDE,(XSP+0x30)
	calr	HDAE5000_CopyFdSongToHd_Rcm
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTCI_22e8                      ; [6e 09] jr NZ,0x2922e8
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	calr	HDAE5000_DeleteSongPart_Rcm
.LTCI_22e8:
	cpw	(xsp+4), 0xffff
	jr z, .LTCI_2318                       ; [66 29] jr Z,0x292318
	ld	wa, (xsp+64)
	bit	0x07, wa
	jr z, .LTCI_2318                       ; [66 21] jr Z,0x292318
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	ld xde, (xsp + 0x30)                    ; ld XDE,(XSP+0x30)
	calr	HDAE5000_CopyFdSongToHd_Md
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTCI_2318                      ; [6e 09] jr NZ,0x292318
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	calr	HDAE5000_DeleteSongPart_Md
.LTCI_2318:
	cpw	(xsp+4), 0xffff
	jr z, .LTCI_2348                       ; [66 29] jr Z,0x292348
	ld	wa, (xsp+64)
	bit	0x08, wa
	jr z, .LTCI_2348                       ; [66 21] jr Z,0x292348
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	ld xde, (xsp + 0x30)                    ; ld XDE,(XSP+0x30)
	calr	HDAE5000_CopyFdSongToHd_Tlx
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTCI_2348                      ; [6e 09] jr NZ,0x292348
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	calr	HDAE5000_DeleteSongPart_Tlx
.LTCI_2348:
	cpw	(xsp+4), 0xffff
	jrl z, .LTCI_2421                      ; [76 d1 00] jrl Z,0x292421
	pushw 0x001a
	pushw 0x0020
	lda	xwa, (xsp+24)
	push xwa
	call HDAE5000_MemFill
	ld	(xsp+54), 0x00
	pushw 0x0008
	ld xwa, (xsp + 0x3a)                    ; ld XWA,(XSP+0x3a)
	push xwa
	lda	xwa, (xsp+20)
	push xwa
	call HDAE5000_MemCopy
	pushw 0x002f
	pushw 0x8efe
	lda	xwa, (xsp+36)
	push xwa
	call HDAE5000_StrCpy
	lda	xsp, (xsp+26)
	lda	xwa, (xsp+6)
	lda xbc, (0x2f8f04:24)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_HamaFnTable)
	ld_sril	xix, (xde + HamaFn_fopen_ext)
	call	(xix)
	cp	hl, 0:i3
	jr lt, .LTCI_23ba                      ; [61 1b] jr LT,0x2923ba
	lda	xwa, (xsp+20)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_HamaFnTable)
	ld_sril	xhl, (xbc + HamaFn_fread_ext)
	ld	xbc, 0x0000001a
	call	(xhl)
	jr t, .LTCI_23ce                       ; [68 14] jr T,0x2923ce
.LTCI_23ba:
	pushw 0x0006
	ld xwa, (xsp + 0x32)                    ; ld XWA,(XSP+0x32)
	inc 2, xwa                              ; inc 2,XWA
	push xwa
	lda	xwa, (xsp+26)
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+10)
.LTCI_23ce:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_fclose_ext)
	call	(xhl)
	pushw 0x001a
	lda	xwa, (xsp+22)
	push xwa
	ld	wa, (xsp+58)
	extz xwa
	ld	xbc, 0x0000004c
	call HDAE5000_Multiply
	ld	xiz, xhl
	ld	wa, (xsp+60)
	extz xwa
	ld	xbc, 0x000004c0
	call HDAE5000_Multiply
	add	xhl, 0x00000780
	add	xhl, xiz
	ld	xwa, HDAE5000_RAM_DirNames
	add	xwa, xhl
	push xwa
	call HDAE5000_StrNCpy
	lda	xsp, (xsp+10)
	call HDAE5000_HD_WriteTables_Status
	jr t, .LTCI_2433                       ; [68 12] jr T,0x292433
.LTCI_2421:
	pushw 0x0000
	pushm	(xsp+62)
	ld	wa, (xsp+58)
	ld	bc, (xsp+56)
	ldw	de, 0x01ff
	calr	HDAE5000_DeleteSongParts
.LTCI_2433:
	cpw	(xsp+60), 0x0001
	call	nz, (HDAE5000_ATA_Standby_Status:24)
	cpw	(xsp+62), 0x0001
	jr nz, .LTCI_2455                      ; [6e 11] jr NZ,0x292455
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_WakeUpMainTask)
	call	(xhl)
.LTCI_2455:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_PlayStandBy)
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_EditSwRefresh)
	call	(xhl)
	jr t, .LTCI_247e                       ; [68 05] jr T,0x29247e
.LTCI_2479:
	ldw (xsp + 0x04), 65535
.LTCI_247e:
	ld	hl, (xsp+4)
	pop xiz                                 ; pop XIZ
	lda	xsp, (xsp+52)
	retd 0x0006		; retd 0x0006


HDAE5000_CopyFdSongToHd_Lsw:	; 0x292488 (359 bytes)
	; Copy the floppy file of part 0 (LSW) into song (WA = directory, BC =
	; song): read through the main-CPU file callbacks (workspace 0x0E88 table
	; +0xA0 with the name and mode "rb", +0xA8 in 0x8000-byte chunks into
	; 0x230F1C, +0xAC) and written with HDAE5000_HD_WriteFile /
	; HDAE5000_HD_AppendFile to slot +36.  Called by HDAE5000_CopyFdSongToHd.
	lda xsp, (xsp - 42)
	push xiz
	ld (xsp + 42), bc	; save file number
	ld (xsp + 44), wa	; save directory
	ldw (xsp + 10), 0x0000	; init result = 0
	; Call 0x29AE9F with args
	pushw 0x0008
	push xde
	lda xwa, (xsp + 18)
	push xwa
	call HDAE5000_MemCopy
	; Call 0x29AF45 with args
	pushw 0x002F
	pushw 0x8F08
	lda xwa, (xsp + 34)
	push xwa
	call HDAE5000_StrCpy
	lda xsp, (xsp + 18)	; cleanup 18 bytes
	; Workspace dispatch WA=0 (buffer at xsp+34)
	lda xwa, (xsp + 34)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); 0x23A1A2
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)
	ld wa, 0:i3
	call (xhl)
	; Workspace dispatch WA=1 (buffer at xsp+26)
	lda xwa, (xsp + 26)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)
	ld wa, 1:i3
	call (xhl)
	; Cell_Get_Params
	ld xwa, (xsp + 30)
	add xwa, (xsp + 38)
	calr HDAE5000_RoundUpToSector
	ld (xsp + 4), xhl
	; Call workspace handler via XIX chain
	lda xwa, (xsp + 12)
	lda xbc, (0x2f8f0e:24); 0x2F8F0E
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24); 0x23A1A2
	ld xde, (xde + WS_HamaFnTable)
	ld_sril xix, (xde + HamaFn_fopen_ext)
	call (xix)
	; Check if result < 0
	cp hl, 0:i3
	jrl lt, .Lts488_error
	; Workspace dispatch via XDE chain at 0xA8
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ld xbc, (xsp + 4)
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xde, (xde + WS_HamaFnTable)
	ld_sril xhl, (xde + HamaFn_fread_ext)
	call (xhl)
	; Write metadata: store 0x00, 0x10, 0x00 at workspace+offset
	ld xwa, (xsp + 30)
	add xwa, (xsp + 38)
	ld xbc, HDAE5000_RAM_HdStreamBuffer
	add xbc, xwa
	ld (xbc), 0x00
	; offset+1: store 0x10
	ld xwa, (xsp + 30)
	add xwa, (xsp + 38)
	inc 1, xwa
	ld xbc, HDAE5000_RAM_HdStreamBuffer
	add xbc, xwa
	ld (xbc), 0x10
	; offset+2: store 0x00
	ld xwa, (xsp + 30)
	add xwa, (xsp + 38)
	inc 2, xwa
	ld xbc, HDAE5000_RAM_HdStreamBuffer
	add xbc, xwa
	ld (xbc), 0x00
	; Save workspace ptr
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ld (xsp + 8), xwa
	; First multiply: compute table offset
	ld wa, (xsp + 42)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 44)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	; Table write via 0x297E16
	lda xwa, (0x201656:24); 0x201656 (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	call HDAE5000_HD_WriteFile
	ld (xsp + 10), hl	; save result
	; Second multiply: compute table offset
	ld wa, (xsp + 42)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 44)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	; Set flag byte to 1
	lda xwa, (0x20164c:24); 0x20164C (flag base)
	add xwa, xhl
	ld (xwa), 0x01
	; Final workspace dispatch at 0xAC
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); 0x23A1A2
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_fclose_ext)
	call (xhl)
	jr .Lts488_done
.Lts488_error:
	ldw (xsp + 10), 0xFFFF
.Lts488_done:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 42)
	ret

HDAE5000_CopyFdSongToHd_Pmt:	; 0x2925EF (425 bytes)
	; Copy the floppy file of part 1 (PMT) into song (WA = directory, BC =
	; song): read through the main-CPU file callbacks (workspace 0x0E88 table
	; +0xA0 with the name and mode "rb", +0xA8 in 0x8000-byte chunks into
	; 0x230F1C, +0xAC) and written with HDAE5000_HD_WriteFile /
	; HDAE5000_HD_AppendFile to slot +40.  Called by HDAE5000_CopyFdSongToHd.
	lda xsp, (xsp - 30)
	push xiz
	ld (xsp + 30), bc	; save file number
	ld (xsp + 32), wa	; save directory
	ldw (xsp + 14), 0x0000	; init result = 0
	; Call 0x29AE9F with args
	pushw 0x0008
	push xde
	lda xwa, (xsp + 22)
	push xwa
	call HDAE5000_MemCopy
	; Call 0x29AF45 with args
	pushw 0x002F
	pushw 0x8F12
	lda xwa, (xsp + 38)
	push xwa
	call HDAE5000_StrCpy
	lda xsp, (xsp + 18)	; clean up pushed args
	; First workspace dispatch
	lda xwa, (xsp + 16)
	lda xbc, (0x2f8f18:24); 0x2F8F18
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24); workspace ptr (0x23A1A2)
	ld xde, (xde + WS_HamaFnTable)             ; (XDE+0x0E88)
	ld_sril xix, (xde + HamaFn_fopen_ext)             ; (XDE+0x00A0)
	call (xix)
	; Check result
	cp hl, 0:i3
	jr ge, .Lts925_1
	ldw hl, 0xFFFF
	jrl .Lts925_exit
.Lts925_1:
	; Second workspace dispatch
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_HamaFnTable)             ; (XBC+0x0E88)
	ld_sril xhl, (xbc + HamaFn_fread_ext)             ; (XBC+0x00A8)
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 4), xhl
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ld (xsp + 8), xwa
	ld xwa, (xsp + 4)
	calr HDAE5000_RoundUpToSector
	ld (xsp + 12), xhl
	; Multiply: compute table offset
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	; Table lookup
	lda xwa, (0x20165a:24); 0x20165A (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 12)
	call HDAE5000_HD_WriteFile
	ld (xsp + 14), hl	; store result
	ld wa, (xsp + 14)	; reload for compare
	cp wa, 0xFFFF
	jr nz, .Lts925_2
	ldw hl, 0xFFFF
	jrl .Lts925_exit
.Lts925_2:
	; Check if dispatch returned 0x8000
	ld xwa, (xsp + 4)
	cp xwa, 0x00008000
	jrl nz, .Lts925_5
.Lts925_loop:
	; Re-dispatch
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_HamaFnTable)
	ld_sril xhl, (xbc + HamaFn_fread_ext)
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	cp xwa, 0x00000000
	jr le, .Lts925_4
	; Retry with new params
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ld (xsp + 8), xwa
	ld xwa, (xsp + 4)
	calr HDAE5000_RoundUpToSector
	ld (xsp + 12), xhl
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20165a:24); 0x20165A
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 12)
	call HDAE5000_HD_AppendFile
	ld (xsp + 14), hl
	ld wa, (xsp + 14)
	cp wa, 0xFFFF
	jr z, .Lts925_5
.Lts925_4:
	ld xwa, (xsp + 4)
	cp xwa, 0x00008000
	jrl z, .Lts925_loop
.Lts925_5:
	; Post-processing: set flag
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20164d:24); 0x20164D (flag base)
	add xwa, xhl
	ld (xwa), 0x01
	; Final workspace dispatch
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)             ; (XWA+0x0E88)
	ld_sril xhl, (xwa + HamaFn_fclose_ext)             ; (XWA+0x00AC)
	call (xhl)
	ld hl, (xsp + 14)	; normal exit: load result
.Lts925_exit:			; error exit: HL already set
	pop xiz
	lda xsp, (xsp + 30)
	ret

HDAE5000_CopyFdSongToHd_Sqt:	; 0x292798 (419 bytes)
	; Copy the floppy file of part 2 (SQT) into song (WA = directory, BC =
	; song): read through the main-CPU file callbacks (workspace 0x0E88 table
	; +0xA0 with the name and mode "rb", +0xA8 in 0x8000-byte chunks into
	; 0x230F1C, +0xAC) and written with HDAE5000_HD_WriteFile /
	; HDAE5000_HD_AppendFile to slot +44.  Called by HDAE5000_CopyFdSongToHd.
	lda xsp, (xsp - 32)
	push xiz
	ld (xsp + 32), bc	; save file number
	ld (xsp + 34), wa	; save directory
	ldw (xsp + 4), 0x0000	; init result = 0
	; Call 0x29AE9F with args
	pushw 0x0008
	push xde
	lda xwa, (xsp + 24)
	push xwa
	call HDAE5000_MemCopy
	; Call 0x29AF45 with args
	pushw 0x002F
	pushw 0x8F1C
	lda xwa, (xsp + 40)
	push xwa
	call HDAE5000_StrCpy
	lda xsp, (xsp + 18)	; clean up pushed args
	; First workspace dispatch
	lda xwa, (xsp + 18)
	lda xbc, (0x2f8f22:24); 0x2F8F22
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24); workspace ptr (0x23A1A2)
	ld xde, (xde + WS_HamaFnTable)             ; (XDE+0x0E88)
	ld_sril xix, (xde + HamaFn_fopen_ext)             ; (XDE+0x00A0)
	call (xix)
	; Check result
	cp hl, 0:i3
	jr ge, .Lts927_1
	ldw hl, 0xFFFF
	jrl .Lts927_exit
.Lts927_1:
	; Second workspace dispatch
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_HamaFnTable)             ; (XBC+0x0E88)
	ld_sril xhl, (xbc + HamaFn_fread_ext)             ; (XBC+0x00A8)
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 6), xhl
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ld (xsp + 10), xwa
	ld xwa, (xsp + 6)
	calr HDAE5000_RoundUpToSector
	ld (xsp + 14), xhl
	; Multiply: compute table offset
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	; Table lookup
	lda xwa, (0x20165e:24); 0x20165E (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	call HDAE5000_HD_WriteFile
	cp hl, 0xFFFF
	jr nz, .Lts927_2
	ldw hl, 0xFFFF
	jrl .Lts927_exit
.Lts927_2:
	; Check if dispatch returned 0x8000
	ld xwa, (xsp + 6)
	cp xwa, 0x00008000
	jrl nz, .Lts927_5
.Lts927_loop:
	; Re-dispatch
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_HamaFnTable)
	ld_sril xhl, (xbc + HamaFn_fread_ext)
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	cp xwa, 0x00000000
	jr le, .Lts927_4
	; Retry with new params
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ld (xsp + 10), xwa
	ld xwa, (xsp + 6)
	calr HDAE5000_RoundUpToSector
	ld (xsp + 14), xhl
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20165e:24); 0x20165E
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	call HDAE5000_HD_AppendFile
	ld (xsp + 4), hl
	ld wa, (xsp + 4)
	cp wa, 0xFFFF
	jr z, .Lts927_5
.Lts927_4:
	ld xwa, (xsp + 6)
	cp xwa, 0x00008000
	jrl z, .Lts927_loop
.Lts927_5:
	; Post-processing: set flag
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20164e:24); 0x20164E (flag base)
	add xwa, xhl
	ld (xwa), 0x01
	; Final workspace dispatch
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)             ; (XWA+0x0E88)
	ld_sril xhl, (xwa + HamaFn_fclose_ext)             ; (XWA+0x00AC)
	call (xhl)
	ld hl, (xsp + 4)	; normal exit: load result
.Lts927_exit:			; error exit: HL already set
	pop xiz
	lda xsp, (xsp + 32)
	ret

HDAE5000_CopyFdSongToHd_Cmp:	; 0x29293B (419 bytes)
	; Copy the floppy file of part 3 (CMP) into song (WA = directory, BC =
	; song): read through the main-CPU file callbacks (workspace 0x0E88 table
	; +0xA0 with the name and mode "rb", +0xA8 in 0x8000-byte chunks into
	; 0x230F1C, +0xAC) and written with HDAE5000_HD_WriteFile /
	; HDAE5000_HD_AppendFile to slot +48.  Called by HDAE5000_CopyFdSongToHd.
	lda xsp, (xsp - 32)
	push xiz
	ld (xsp + 32), bc
	ld (xsp + 34), wa
	ldw (xsp + 4), 0x0000
	pushw 0x0008
	push xde
	lda xwa, (xsp + 24)
	push xwa
	call HDAE5000_MemCopy
	pushw 0x002F
	pushw 0x8F26
	lda xwa, (xsp + 40)
	push xwa
	call HDAE5000_StrCpy
	lda xsp, (xsp + 18)
	lda xwa, (xsp + 18)
	lda xbc, (0x2f8f2c:24); 0x2F8F2C
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xde, (xde + WS_HamaFnTable)
	ld_sril xix, (xde + HamaFn_fopen_ext)
	call (xix)
	cp hl, 0:i3
	jr ge, .Lts929_1
	ldw hl, 0xFFFF
	jrl .Lts929_exit
.Lts929_1:
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_HamaFnTable)
	ld_sril xhl, (xbc + HamaFn_fread_ext)
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 6), xhl
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld (xsp + 10), xwa
	ld xwa, (xsp + 6)
	calr HDAE5000_RoundUpToSector
	ld (xsp + 14), xhl
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201662:24); 0x201662 (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	call HDAE5000_HD_WriteFile
	cp hl, 0xFFFF
	jr nz, .Lts929_2
	ldw hl, 0xFFFF
	jrl .Lts929_exit
.Lts929_2:
	ld xwa, (xsp + 6)
	cp xwa, 0x00008000
	jrl nz, .Lts929_5
.Lts929_loop:
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_HamaFnTable)
	ld_sril xhl, (xbc + HamaFn_fread_ext)
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	cp xwa, 0x00000000
	jr le, .Lts929_4
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld (xsp + 10), xwa
	ld xwa, (xsp + 6)
	calr HDAE5000_RoundUpToSector
	ld (xsp + 14), xhl
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201662:24); 0x201662
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	call HDAE5000_HD_AppendFile
	ld (xsp + 4), hl
	ld wa, (xsp + 4)
	cp wa, 0xFFFF
	jr z, .Lts929_5
.Lts929_4:
	ld xwa, (xsp + 6)
	cp xwa, 0x00008000
	jrl z, .Lts929_loop
.Lts929_5:
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20164f:24); 0x20164F (flag base)
	add xwa, xhl
	ld (xwa), 0x01
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_fclose_ext)
	call (xhl)
	ld hl, (xsp + 4)
.Lts929_exit:
	pop xiz
	lda xsp, (xsp + 32)
	ret

HDAE5000_CopyFdSongToHd_Tm:	; 0x292ADE (288 bytes)
	; Copy the floppy file of part 4 (TM) into song (WA = directory, BC =
	; song): read through the main-CPU file callbacks (workspace 0x0E88 table
	; +0xA0 with the name and mode "rb", +0xA8 in 0x8000-byte chunks into
	; 0x230F1C, +0xAC) and written with HDAE5000_HD_WriteFile /
	; HDAE5000_HD_AppendFile to slot +52.  Called by HDAE5000_CopyFdSongToHd.
	lda xsp, (xsp - 34)
	push xiz
	ld (xsp + 34), bc	; save file number
	ld (xsp + 36), wa	; save directory
	ldw (xsp + 10), 0x0000	; init result = 0
	; Call 0x29AE9F with args
	pushw 0x0008
	push xde
	lda xwa, (xsp + 18)
	push xwa
	call HDAE5000_MemCopy
	; Call 0x29AF45 with args
	pushw 0x002F
	pushw 0x8F30
	lda xwa, (xsp + 34)
	push xwa
	call HDAE5000_StrCpy
	lda xsp, (xsp + 18)	; clean up pushed args
	; Workspace dispatch with WA=6
	lda xwa, (xsp + 26)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)             ; (XWA+0x0080)
	ld wa, 6:i3
	call (xhl)
	; Load constant and save
	ld xwa, 0x000072AA
	ld (xsp + 30), xwa
	; Second dispatch via XIX
	lda xwa, (xsp + 12)
	lda xbc, (0x2f8f34:24); 0x2F8F34
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xde, (xde + WS_HamaFnTable)
	ld_sril xix, (xde + HamaFn_fopen_ext)
	call (xix)
	cp hl, 0:i3
	jrl lt, .Lts92a_error
	; Workspace dispatch: get handler
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ld xbc, (xsp + 30)
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xde, (xde + WS_HamaFnTable)
	ld_sril xhl, (xde + HamaFn_fread_ext)             ; (XDE+0x00A8)
	call (xhl)
	; Save workspace base and get cell params
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld (xsp + 4), xwa
	ld xwa, (xsp + 30)
	calr HDAE5000_RoundUpToSector
	ld (xsp + 8), xhl
	; Multiply: compute table offset
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 36)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	; Table lookup
	lda xwa, (0x201666:24); 0x201666 (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xsp + 8)
	call HDAE5000_HD_WriteFile
	ld (xsp + 10), hl
	; Set flag
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 36)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201650:24); 0x201650 (flag base)
	add xwa, xhl
	ld (xwa), 0x01
	; Final workspace dispatch
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_fclose_ext)             ; (XWA+0x00AC)
	call (xhl)
	jr .Lts92a_load
.Lts92a_error:
	ldw (xsp + 10), 0xFFFF	; error: result = -1
.Lts92a_load:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 34)
	ret

HDAE5000_CopyFdSongToHd_Msp:	; 0x292BFE (280 bytes)
	; Copy the floppy file of part 5 (MSP) into song (WA = directory, BC =
	; song): read through the main-CPU file callbacks (workspace 0x0E88 table
	; +0xA0 with the name and mode "rb", +0xA8 in 0x8000-byte chunks into
	; 0x230F1C, +0xAC) and written with HDAE5000_HD_WriteFile /
	; HDAE5000_HD_AppendFile to slot +56.  Called by HDAE5000_CopyFdSongToHd.
	lda xsp, (xsp - 34)
	push xiz
	ld (xsp + 34), bc
	ld (xsp + 36), wa
	ldw (xsp + 10), 0x0000
	pushw 0x0008
	push xde
	lda xwa, (xsp + 18)
	push xwa
	call HDAE5000_MemCopy
	pushw 0x002F
	pushw 0x8F38
	lda xwa, (xsp + 34)
	push xwa
	call HDAE5000_StrCpy
	lda xsp, (xsp + 18)
	; Workspace dispatch with WA=7
	lda xwa, (xsp + 26)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)
	ld wa, 7:i3
	call (xhl)
	; Second dispatch via XIX (no constant store)
	lda xwa, (xsp + 12)
	lda xbc, (0x2f8f3e:24); 0x2F8F3E
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xde, (xde + WS_HamaFnTable)
	ld_sril xix, (xde + HamaFn_fopen_ext)
	call (xix)
	cp hl, 0:i3
	jrl lt, .Lts92b_error
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld xbc, (xsp + 30)
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xde, (xde + WS_HamaFnTable)
	ld_sril xhl, (xde + HamaFn_fread_ext)
	call (xhl)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld (xsp + 4), xwa
	ld xwa, (xsp + 30)
	calr HDAE5000_RoundUpToSector
	ld (xsp + 8), xhl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 36)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20166a:24); 0x20166A (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xsp + 8)
	call HDAE5000_HD_WriteFile
	ld (xsp + 10), hl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 36)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201651:24); 0x201651 (flag base)
	add xwa, xhl
	ld (xwa), 0x01
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_fclose_ext)
	call (xhl)
	jr .Lts92b_load
.Lts92b_error:
	ldw (xsp + 10), 0xFFFF
.Lts92b_load:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 34)
	ret

HDAE5000_CopyFdSongToHd_Rcm:	; 0x292D16 (419 bytes)
	; Copy the floppy file of part 6 (RCM) into song (WA = directory, BC =
	; song): read through the main-CPU file callbacks (workspace 0x0E88 table
	; +0xA0 with the name and mode "rb", +0xA8 in 0x8000-byte chunks into
	; 0x230F1C, +0xAC) and written with HDAE5000_HD_WriteFile /
	; HDAE5000_HD_AppendFile to slot +60.  Called by HDAE5000_CopyFdSongToHd.
	lda xsp, (xsp - 32)
	push xiz
	ld (xsp + 32), bc
	ld (xsp + 34), wa
	ldw (xsp + 4), 0x0000
	pushw 0x0008
	push xde
	lda xwa, (xsp + 24)
	push xwa
	call HDAE5000_MemCopy
	pushw 0x002F
	pushw 0x8F42
	lda xwa, (xsp + 40)
	push xwa
	call HDAE5000_StrCpy
	lda xsp, (xsp + 18)
	lda xwa, (xsp + 18)
	lda xbc, (0x2f8f48:24); 0x2F8F48
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xde, (xde + WS_HamaFnTable)
	ld_sril xix, (xde + HamaFn_fopen_ext)
	call (xix)
	cp hl, 0:i3
	jr ge, .Lts92d_1
	ldw hl, 0xFFFF
	jrl .Lts92d_exit
.Lts92d_1:
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_HamaFnTable)
	ld_sril xhl, (xbc + HamaFn_fread_ext)
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 6), xhl
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld (xsp + 10), xwa
	ld xwa, (xsp + 6)
	calr HDAE5000_RoundUpToSector
	ld (xsp + 14), xhl
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20166e:24); 0x20166E (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	call HDAE5000_HD_WriteFile
	cp hl, 0xFFFF
	jr nz, .Lts92d_2
	ldw hl, 0xFFFF
	jrl .Lts92d_exit
.Lts92d_2:
	ld xwa, (xsp + 6)
	cp xwa, 0x00008000
	jrl nz, .Lts92d_5
.Lts92d_loop:
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_HamaFnTable)
	ld_sril xhl, (xbc + HamaFn_fread_ext)
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	cp xwa, 0x00000000
	jr le, .Lts92d_4
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld (xsp + 10), xwa
	ld xwa, (xsp + 6)
	calr HDAE5000_RoundUpToSector
	ld (xsp + 14), xhl
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20166e:24); 0x20166E
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	call HDAE5000_HD_AppendFile
	ld (xsp + 4), hl
	ld wa, (xsp + 4)
	cp wa, 0xFFFF
	jr z, .Lts92d_5
.Lts92d_4:
	ld xwa, (xsp + 6)
	cp xwa, 0x00008000
	jrl z, .Lts92d_loop
.Lts92d_5:
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201652:24); 0x201652 (flag base)
	add xwa, xhl
	ld (xwa), 0x01
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_fclose_ext)
	call (xhl)
	ld hl, (xsp + 4)
.Lts92d_exit:
	pop xiz
	lda xsp, (xsp + 32)
	ret

HDAE5000_CopyFdSongToHd_Md:	; 0x292EB9 (281 bytes)
	; Copy the floppy file of part 7 (MD) into song (WA = directory, BC =
	; song): read through the main-CPU file callbacks (workspace 0x0E88 table
	; +0xA0 with the name and mode "rb", +0xA8 in 0x8000-byte chunks into
	; 0x230F1C, +0xAC) and written with HDAE5000_HD_WriteFile /
	; HDAE5000_HD_AppendFile to slot +64.  Called by HDAE5000_CopyFdSongToHd.
	lda xsp, (xsp - 34)
	push xiz
	ld (xsp + 34), bc
	ld (xsp + 36), wa
	ldw (xsp + 10), 0x0000
	pushw 0x0008
	push xde
	lda xwa, (xsp + 18)
	push xwa
	call HDAE5000_MemCopy
	pushw 0x002F
	pushw 0x8F4C
	lda xwa, (xsp + 34)
	push xwa
	call HDAE5000_StrCpy
	lda xsp, (xsp + 18)
	; Workspace dispatch with WA=9
	lda xwa, (xsp + 26)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)
	ldw wa, 0x0009
	call (xhl)
	; Second dispatch via XIX
	lda xwa, (xsp + 12)
	lda xbc, (0x2f8f50:24); 0x2F8F50
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xde, (xde + WS_HamaFnTable)
	ld_sril xix, (xde + HamaFn_fopen_ext)
	call (xix)
	cp hl, 0:i3
	jrl lt, .Lts92e_error
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld xbc, (xsp + 30)
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xde, (xde + WS_HamaFnTable)
	ld_sril xhl, (xde + HamaFn_fread_ext)
	call (xhl)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld (xsp + 4), xwa
	ld xwa, (xsp + 30)
	calr HDAE5000_RoundUpToSector
	ld (xsp + 8), xhl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 36)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201672:24); 0x201672 (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xsp + 8)
	call HDAE5000_HD_WriteFile
	ld (xsp + 10), hl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 36)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201653:24); 0x201653 (flag base)
	add xwa, xhl
	ld (xwa), 0x01
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_fclose_ext)
	call (xhl)
	jr .Lts92e_load
.Lts92e_error:
	ldw (xsp + 10), 0xFFFF
.Lts92e_load:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 34)
	ret

HDAE5000_CopyFdSongToHd_Tlx:	; 0x292FD2 (329 bytes)
	; Copy the floppy file of part 8 (TLX) into song (WA = directory, BC =
	; song): read through the main-CPU file callbacks (workspace 0x0E88 table
	; +0xA0 with the name and mode "rb", +0xA8 in 0x8000-byte chunks into
	; 0x230F1C, +0xAC) and written with HDAE5000_HD_WriteFile /
	; HDAE5000_HD_AppendFile to slot +68.  Called by HDAE5000_CopyFdSongToHd.
	lda xsp, (xsp - 34)
	push xiz
	ld (xsp + 34), bc
	ld (xsp + 36), wa
	ldw (xsp + 10), 0x0000
	pushw 0x0008
	push xde
	lda xwa, (xsp + 18)
	push xwa
	call HDAE5000_MemCopy
	pushw 0x002F
	pushw 0x8F54
	lda xwa, (xsp + 34)
	push xwa
	call HDAE5000_StrCpy
	lda xsp, (xsp + 18)
	; Dispatch via XIX
	lda xwa, (xsp + 12)
	lda xbc, (0x2f8f5a:24); 0x2F8F5A
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xde, (xde + WS_HamaFnTable)
	ld_sril xix, (xde + HamaFn_fopen_ext)
	call (xix)
	cp hl, 0:i3
	jrl lt, .Lts92f_error
	; Call 0x29AEC7 with args (8 bytes pushed, cleaned by inc 0)
	pushw 0x8000
	pushw 0x0000
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	push xwa
	call HDAE5000_MemFill
	inc 0, xsp		; clean up 8 bytes
	; Workspace dispatch with XBC=0x16
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_HamaFnTable)
	ld_sril xhl, (xbc + HamaFn_fread_ext)
	ld xbc, 0x00000016
	call (xhl)
	; Load param, call 0x28E5E9, sign extend result
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld xwa, (xwa + 18)	; offset 0x12
	call HDAE5000_SwapBytes32
	ld iz, hl		; 16-bit result to IZ
	exts xiz		; sign extend to 32-bit
	ld xwa, xiz
	add xwa, 0x00000016
	calr HDAE5000_RoundUpToSector
	ld (xsp + 30), xhl
	; Dispatch with XIZ as XBC param
	lda xwa, (0x230f32:24); 0x230F32
	ld xbc, xiz
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xde, (xde + WS_HamaFnTable)
	ld_sril xhl, (xde + HamaFn_fread_ext)
	call (xhl)
	; Table lookup
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24)
	ld (xsp + 4), xwa
	lda xwa, (xsp + 30)
	ld (xsp + 8), xwa
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 36)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201676:24); 0x201676 (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xsp + 8)
	ld xbc, (xbc)		; double dereference
	call HDAE5000_HD_WriteFile
	ld (xsp + 10), hl
	; Set flag
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 36)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201654:24); 0x201654 (flag base)
	add xwa, xhl
	ld (xwa), 0x01
	; Final workspace dispatch
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_fclose_ext)
	call (xhl)
	jr .Lts92f_load
.Lts92f_error:
	ldw (xsp + 10), 0xFFFF
.Lts92f_load:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 34)
	ret

HDAE5000_Fls_ForgetSong:	; 0x29311B (592 bytes)
	; Part 1: Clear matching entries in workspace tables
	; ^ i.e. remove song (WA = directory, BC = song) from every FLS list:
	;   the "workspace tables" are the 120 FLS records at 0x2257B2 (HDAE5000_HD_GetBlockInfo
	;   block 2), 32 items each.
	; Nested loop: IZ = 0..119, IY = 0..31
	; For each (IZ,IY), computes table index = IZ*9*16 + IY
	; If table[index] matches WA+1 AND table[index+0x20] matches BC+1,
	; clears 4 related entries at offsets 0xC2, 0xE2, 0x02, 0x22
	pushw iz
	ld iz, 0:i3			; IZ = 0 (outer counter)
	cp iz, 0x0078
	jrl nc, .Lwh_outer_done		; skip if IZ >= 120
.Lwh_outer_loop:
	ld iy, 0:i3			; IY = 0 (inner counter)
	cp iy, 0x0020
	jrl nc, .Lwh_inner_done		; skip if IY >= 32
.Lwh_inner_loop:
	; Compute table index: XIX = IZ * 144 + IY
	ld hl, iy
	extz xhl
	ld de, iz
	extz xde
	ld xix, xde
	sll xix, 3			; XIX = IZ * 8
	add xix, xde			; XIX = IZ * 9
	sll xix, 4			; XIX = IZ * 144
	add xix, xhl			; XIX = IZ * 144 + IY
	; Check WA match at base 0x2257C2
	lda xde, (0x2257c2:24); XDE = 0x2257C2
	add xde, xix
	ld e, (xde)			; E = table entry
	ld l, e
	extz hl
	ld de, wa			; DE = WA
	inc 1, de			; DE = WA + 1
	cp de, hl			; match?
	jrl nz, .Lwh_next_inner
	; Check BC match at base 0x2257E2
	ld hl, iy
	extz xhl
	ld de, iz
	extz xde
	ld xix, xde
	sll xix, 3
	add xix, xde
	sll xix, 4
	add xix, xhl
	lda xde, (0x2257e2:24); XDE = 0x2257E2
	add xde, xix
	ld e, (xde)
	ld l, e
	extz hl
	ld de, bc			; DE = BC
	inc 1, de			; DE = BC + 1
	cp de, hl
	jr nz, .Lwh_next_inner
	; Both match — clear 4 table entries
	; Clear entry at base 0x2257C2
	ld hl, iy
	extz xhl
	ld de, iz
	extz xde
	ld xix, xde
	sll xix, 3
	add xix, xde
	sll xix, 4
	add xix, xhl
	lda xde, (0x2257c2:24); 0x2257C2
	add xde, xix
	ld (xde), 0x00
	; Clear entry at base 0x2257E2
	ld hl, iy
	extz xhl
	ld de, iz
	extz xde
	ld xix, xde
	sll xix, 3
	add xix, xde
	sll xix, 4
	add xix, xhl
	lda xde, (0x2257e2:24); 0x2257E2
	add xde, xix
	ld (xde), 0x00
	; Clear entry at base 0x225802
	ld hl, iy
	extz xhl
	ld de, iz
	extz xde
	ld xix, xde
	sll xix, 3
	add xix, xde
	sll xix, 4
	add xix, xhl
	lda xde, (0x225802:24); 0x225802
	add xde, xix
	ld (xde), 0x00
	; Clear entry at base 0x225822
	ld hl, iy
	extz xhl
	ld de, iz
	extz xde
	ld xix, xde
	sll xix, 3
	add xix, xde
	sll xix, 4
	add xix, xhl
	lda xde, (0x225822:24); 0x225822
	add xde, xix
	ld (xde), 0x00
.Lwh_next_inner:
	inc 1, iy
	cp iy, 0x0020
	jrl c, .Lwh_inner_loop
.Lwh_inner_done:
	inc 1, iz
	cp iz, 0x0078
	jrl c, .Lwh_outer_loop
.Lwh_outer_done:
	popw iz
	ret
	; Part 2: Main workspace handler entry (0x29320D)
	; Called by firmware — saves regs, dispatches through handler chain
HDAE5000_DeleteDirectory:
	; Delete directory WA: every used song of it loses its nine parts
	; (HDAE5000_DeleteSongPart_*) and its FLS references
	; (HDAE5000_Fls_ForgetSong) and gets a blank name (26 spaces); the
	; directory name is blanked (16 spaces); tables written
	; (HDAE5000_HD_WriteTables_Status).  BC = 1: also the 0x0E0A +0x538/+0x53C
	; UI callbacks; DE != 1: spin down.  Caller: AttenDelDirSwCatch.
	dec 0, xsp			; callee cleanup placeholder
	push xiz
	ld (xsp + 6), de		; save DE (param)
	ld (xsp + 8), bc		; save BC (param)
	ld (xsp + 10), wa		; save WA (param)
	; Get handler through workspace chain
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); (0x23A1A2) — workspace ptr
	ld xwa, (xwa + WS_HamaFnTable)             ; XWA = (XWA+0x0E88)
	ld_sril xhl, (xwa + HamaFn_PlayHalt)             ; XHL = (XWA+0x00E8) — handler
	ld wa, 1:i3			; param = 1
	call (xhl)
	; Conditional: if BC == 1, call extra handler
	cpw (xsp + 8), 0x0001
	jr nz, .Lwh_skip_extra
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)             ; XWA = (XWA+0x0E0A)
	ld xhl, (xwa + RootFn_SleepMainTask)             ; XHL = (XWA+0x0538)
	call (xhl)
.Lwh_skip_extra:
	call HDAE5000_ATA_SoftReset_Status
	ldw (xsp + 4), 0x0000		; slot counter = 0
	; Loop over 16 slots
	cpw (xsp + 4), 0x0010
	jrl nc, .Lwh_loop_done
.Lwh_slot_loop:
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Song_IsUsed
	cp hl, 0xFFFF
	jr z, .Lwh_slot_fill
	; Process slot — call all 10 render types
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_DeleteSongPart_Lsw
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_DeleteSongPart_Pmt
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_DeleteSongPart_Sqt
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_DeleteSongPart_Cmp
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_DeleteSongPart_Tm
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_DeleteSongPart_Msp
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_DeleteSongPart_Rcm
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_DeleteSongPart_Md
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_DeleteSongPart_Tlx
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Fls_ForgetSong	; recursive call (clear matching)
.Lwh_slot_fill:
	; Compute fill address and call MemFill
	pushw 0x001A			; fill count
	pushw 0x0020			; fill value/params
	ld wa, (xsp + 8)		; BC (adjusted for pushes)
	extz xwa
	ld xbc, 0x0000004C		; stride
	call HDAE5000_Multiply
	ld xiz, xhl			; save offset
	ld wa, (xsp + 14)		; WA (adjusted)
	extz xwa
	ld xbc, 0x000004C0		; stride
	call HDAE5000_Multiply
	add xhl, 0x00000780		; base offset
	add xhl, xiz			; total offset
	ld xwa, HDAE5000_RAM_DirNames		; table base address
	add xwa, xhl			; absolute address
	push xwa			; push fill dest
	call HDAE5000_MemFill
	inc 0, xsp			; stack cleanup (no-op)
	incw 1, (xsp + 4)		; slot counter++
	cpw (xsp + 4), 0x0010
	jrl c, .Lwh_slot_loop
.Lwh_loop_done:
	; Post-loop: fill final block
	pushw 0x0010			; block count
	pushw 0x0020			; block params
	ld wa, (xsp + 14)		; WA (adjusted)
	extz xwa
	sll xwa, 4			; * 16
	ld xbc, HDAE5000_RAM_DirNames		; table base
	add xbc, xwa
	push xbc			; push fill dest
	call HDAE5000_MemFill
	inc 0, xsp			; stack cleanup
	; Final handler calls
	call HDAE5000_HD_WriteTables_Status
	cpw (xsp + 6), 0x0001	; DE == 1?
	call nz, (HDAE5000_ATA_Standby_Status:24)		; call nz, 0x2974B5
	cpw (xsp + 8), 0x0001	; BC == 1?
	jr nz, .Lwh_skip_final
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)             ; XWA = (XWA+0x0E0A)
	ld xhl, (xwa + RootFn_WakeUpMainTask)             ; XHL = (XWA+0x053C)
	call (xhl)
.Lwh_skip_final:
	; Workspace cleanup calls
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_PlayStandBy)             ; XHL = (XWA+0x00EC)
	call (xhl)
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_EditSwRefresh)             ; XHL = (XWA+0x00F0)
	call (xhl)
	pop xiz
	inc 0, xsp			; stack cleanup
	ret

HDAE5000_DeleteSongParts:	; 0x29336B (349 bytes)
	; Delete the parts in mask DE of song (WA = directory, BC = song)
	; (HDAE5000_DeleteSongPart_<k> per bit), between the main-CPU callbacks;
	; a song left with no part also leaves the FLS lists
	; (HDAE5000_Fls_ForgetSong).  Callers: AttenDelFileSwCatch, SaveSong,
	; CopyFdSongToHd, PC-link service 27.
	dec 4, xsp
	push xiz
	ld iz, de
	ld (xsp + 4), bc	; save file number
	ld (xsp + 6), wa	; save directory
	cp iz, 0:i3
	jrl z, .Lws36b_exit	; nothing to do
	; Workspace dispatch at 0xE8
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); 0x23A1A2
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_PlayHalt)
	ld wa, 1:i3
	call (xhl)
	; Check workspace flag at (xsp+14)
	cpw (xsp + 14), 0x0001
	jr nz, .Lws36b_skip1
	; Workspace dispatch at 0x0538
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_SleepMainTask)
	call (xhl)
.Lws36b_skip1:
	call HDAE5000_ATA_SoftReset_Status
	; Bitmask dispatch: test bits of IZ, call corresponding renderers
	bit 0, iz
	jr z, .Lws36b_bit1
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_DeleteSongPart_Lsw
.Lws36b_bit1:
	bit 1, iz
	jr z, .Lws36b_bit2
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_DeleteSongPart_Pmt
.Lws36b_bit2:
	bit 2, iz
	jr z, .Lws36b_bit3
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_DeleteSongPart_Sqt
.Lws36b_bit3:
	bit 3, iz
	jr z, .Lws36b_bit4
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_DeleteSongPart_Cmp
.Lws36b_bit4:
	bit 4, iz
	jr z, .Lws36b_bit5
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_DeleteSongPart_Tm
.Lws36b_bit5:
	bit 5, iz
	jr z, .Lws36b_bit6
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_DeleteSongPart_Msp
.Lws36b_bit6:
	bit 6, iz
	jr z, .Lws36b_bit7
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_DeleteSongPart_Rcm
.Lws36b_bit7:
	bit 7, iz
	jr z, .Lws36b_bit8
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_DeleteSongPart_Md
.Lws36b_bit8:
	bit 8, iz
	jr z, .Lws36b_calc
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_DeleteSongPart_Tlx
.Lws36b_calc:
	; Calculate table offset
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Song_IsUsed
	cp hl, 0xFFFF
	jr nz, .Lws36b_post
	; Push args and call 0x29AEC7
	pushw 0x001A
	pushw 0x0020
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 10)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	ld xwa, HDAE5000_RAM_DirNames
	add xwa, xhl
	push xwa
	call HDAE5000_MemFill
	inc 0, xsp
	; Call workspace handler
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Fls_ForgetSong
.Lws36b_post:
	call HDAE5000_HD_WriteTables_Status
	; Conditional call NZ to 0x2974B5
	cpw (xsp + 12), 0x0001
	call nz, (HDAE5000_ATA_Standby_Status:24)	; call nz, 0x2974B5
	; Check workspace flag at (xsp+14)
	cpw (xsp + 14), 0x0001
	jr nz, .Lws36b_skip2
	; Workspace dispatch at 0x053C
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_WakeUpMainTask)
	call (xhl)
.Lws36b_skip2:
	; Workspace dispatch at 0xEC
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_PlayStandBy)
	call (xhl)
	; Workspace dispatch at 0xF0
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_EditSwRefresh)
	call (xhl)
.Lws36b_exit:
	pop xiz
	inc 4, xsp
	retd 4

; --- UI Cell Renderers (9 x 222 bytes each) ---
; Delete table entry: check existence, call handler, clear entry (-1), clear flag (0)
HDAE5000_DeleteSongPart_Lsw:	; 0x2934C8 (222 bytes)
	; Delete part 0 (LSW) of song (WA = directory, BC = song): if slot +36 is
	; not 0xFFFFFFFF, free its chain (HDAE5000_HD_FreeChain), set the slot to
	; 0xFFFFFFFF and the part byte +26 to 0.
	dec 4, xsp
	push xiz
	ld (xsp + 4), bc	; save file number
	ld (xsp + 6), wa	; save directory
	; --- Check if entry exists ---
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C	; multiplier = 76
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0	; multiplier = 1216
	call HDAE5000_Multiply
	add xhl, 0x780		; += 1920
	add xhl, xiz
	lda xwa, (0x201656:24); 0x201656 (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lcr0_exit
	; --- Get entry value and call handler ---
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201656:24); 0x201656
	add xwa, xhl
	ld xwa, (xwa)
	call HDAE5000_HD_FreeChain
	; --- Clear entry (store -1) ---
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201656:24); 0x201656
	ld xbc, xwa
	add xbc, xhl
	ld xwa, 0xFFFFFFFF
	ld (xbc), xwa
	; --- Clear flag (store 0) ---
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20164c:24); 0x20164C (flag base)
	add xwa, xhl
	ld (xwa), 0x00
.Lcr0_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_DeleteSongPart_Pmt:	; 0x2935A6 (222 bytes)
	; Delete part 1 (PMT) of song (WA = directory, BC = song): if slot +40 is
	; not 0xFFFFFFFF, free its chain (HDAE5000_HD_FreeChain), set the slot to
	; 0xFFFFFFFF and the part byte +27 to 0.
	dec 4, xsp
	push xiz
	ld (xsp + 4), bc
	ld (xsp + 6), wa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20165a:24); 0x20165A (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lcr1_exit
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20165a:24); 0x20165A
	add xwa, xhl
	ld xwa, (xwa)
	call HDAE5000_HD_FreeChain
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20165a:24); 0x20165A
	ld xbc, xwa
	add xbc, xhl
	ld xwa, 0xFFFFFFFF
	ld (xbc), xwa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20164d:24); 0x20164D (flag base)
	add xwa, xhl
	ld (xwa), 0x00
.Lcr1_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_DeleteSongPart_Sqt:	; 0x293684 (222 bytes)
	; Delete part 2 (SQT) of song (WA = directory, BC = song): if slot +44 is
	; not 0xFFFFFFFF, free its chain (HDAE5000_HD_FreeChain), set the slot to
	; 0xFFFFFFFF and the part byte +28 to 0.
	dec 4, xsp
	push xiz
	ld (xsp + 4), bc
	ld (xsp + 6), wa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20165e:24); 0x20165E (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lcr2_exit
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20165e:24); 0x20165E
	add xwa, xhl
	ld xwa, (xwa)
	call HDAE5000_HD_FreeChain
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20165e:24); 0x20165E
	ld xbc, xwa
	add xbc, xhl
	ld xwa, 0xFFFFFFFF
	ld (xbc), xwa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20164e:24); 0x20164E (flag base)
	add xwa, xhl
	ld (xwa), 0x00
.Lcr2_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_DeleteSongPart_Cmp:	; 0x293762 (222 bytes)
	; Delete part 3 (CMP) of song (WA = directory, BC = song): if slot +48 is
	; not 0xFFFFFFFF, free its chain (HDAE5000_HD_FreeChain), set the slot to
	; 0xFFFFFFFF and the part byte +29 to 0.
	dec 4, xsp
	push xiz
	ld (xsp + 4), bc
	ld (xsp + 6), wa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201662:24); 0x201662 (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lcr3_exit
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201662:24); 0x201662
	add xwa, xhl
	ld xwa, (xwa)
	call HDAE5000_HD_FreeChain
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201662:24); 0x201662
	ld xbc, xwa
	add xbc, xhl
	ld xwa, 0xFFFFFFFF
	ld (xbc), xwa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20164f:24); 0x20164F (flag base)
	add xwa, xhl
	ld (xwa), 0x00
.Lcr3_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_DeleteSongPart_Tm:	; 0x293840 (222 bytes)
	; Delete part 4 (TM) of song (WA = directory, BC = song): if slot +52 is
	; not 0xFFFFFFFF, free its chain (HDAE5000_HD_FreeChain), set the slot to
	; 0xFFFFFFFF and the part byte +30 to 0.
	dec 4, xsp
	push xiz
	ld (xsp + 4), bc
	ld (xsp + 6), wa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201666:24); 0x201666 (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lcr4_exit
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201666:24); 0x201666
	add xwa, xhl
	ld xwa, (xwa)
	call HDAE5000_HD_FreeChain
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201666:24); 0x201666
	ld xbc, xwa
	add xbc, xhl
	ld xwa, 0xFFFFFFFF
	ld (xbc), xwa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201650:24); 0x201650 (flag base)
	add xwa, xhl
	ld (xwa), 0x00
.Lcr4_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_DeleteSongPart_Msp:	; 0x29391E (222 bytes)
	; Delete part 5 (MSP) of song (WA = directory, BC = song): if slot +56 is
	; not 0xFFFFFFFF, free its chain (HDAE5000_HD_FreeChain), set the slot to
	; 0xFFFFFFFF and the part byte +31 to 0.
	dec 4, xsp
	push xiz
	ld (xsp + 4), bc
	ld (xsp + 6), wa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20166a:24); 0x20166A (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lcr5_exit
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20166a:24); 0x20166A
	add xwa, xhl
	ld xwa, (xwa)
	call HDAE5000_HD_FreeChain
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20166a:24); 0x20166A
	ld xbc, xwa
	add xbc, xhl
	ld xwa, 0xFFFFFFFF
	ld (xbc), xwa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201651:24); 0x201651 (flag base)
	add xwa, xhl
	ld (xwa), 0x00
.Lcr5_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_DeleteSongPart_Rcm:	; 0x2939FC (222 bytes)
	; Delete part 6 (RCM) of song (WA = directory, BC = song): if slot +60 is
	; not 0xFFFFFFFF, free its chain (HDAE5000_HD_FreeChain), set the slot to
	; 0xFFFFFFFF and the part byte +32 to 0.
	dec 4, xsp
	push xiz
	ld (xsp + 4), bc
	ld (xsp + 6), wa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20166e:24); 0x20166E (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lcr6_exit
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20166e:24); 0x20166E
	add xwa, xhl
	ld xwa, (xwa)
	call HDAE5000_HD_FreeChain
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x20166e:24); 0x20166E
	ld xbc, xwa
	add xbc, xhl
	ld xwa, 0xFFFFFFFF
	ld (xbc), xwa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201652:24); 0x201652 (flag base)
	add xwa, xhl
	ld (xwa), 0x00
.Lcr6_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_DeleteSongPart_Md:	; 0x293ADA (222 bytes)
	; Delete part 7 (MD) of song (WA = directory, BC = song): if slot +64 is
	; not 0xFFFFFFFF, free its chain (HDAE5000_HD_FreeChain), set the slot to
	; 0xFFFFFFFF and the part byte +33 to 0.
	dec 4, xsp
	push xiz
	ld (xsp + 4), bc
	ld (xsp + 6), wa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201672:24); 0x201672 (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lcr7_exit
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201672:24); 0x201672
	add xwa, xhl
	ld xwa, (xwa)
	call HDAE5000_HD_FreeChain
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201672:24); 0x201672
	ld xbc, xwa
	add xbc, xhl
	ld xwa, 0xFFFFFFFF
	ld (xbc), xwa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201653:24); 0x201653 (flag base)
	add xwa, xhl
	ld (xwa), 0x00
.Lcr7_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_DeleteSongPart_Tlx:	; 0x293BB8 (222 bytes)
	; Delete part 8 (TLX) of song (WA = directory, BC = song): if slot +68 is
	; not 0xFFFFFFFF, free its chain (HDAE5000_HD_FreeChain), set the slot to
	; 0xFFFFFFFF and the part byte +34 to 0.
	dec 4, xsp
	push xiz
	ld (xsp + 4), bc
	ld (xsp + 6), wa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201676:24); 0x201676 (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lcr8_exit
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201676:24); 0x201676
	add xwa, xhl
	ld xwa, (xwa)
	call HDAE5000_HD_FreeChain
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201676:24); 0x201676
	ld xbc, xwa
	add xbc, xhl
	ld xwa, 0xFFFFFFFF
	ld (xbc), xwa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x780
	add xhl, xiz
	lda xwa, (0x201654:24); 0x201654 (flag base)
	add xwa, xhl
	ld (xwa), 0x00
.Lcr8_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_Song_CheckFreeSpace:	; 0x293C96 (347 bytes)
	; Validate cell rendering — tests bits 0-8, accumulates sizes in XIZ
	; ^ corrected: HL = 0 if the parts of mask WA fit in the free clusters
	;   (HDAE5000_HD_CountFreeClusters_Status), else 0xFFFF.  Sizes come from
	;   the main CPU (0x0E88 table +0x80 per area, +0x34, +0x44, +0x64);
	;   TM counts 0x72AA bytes and TLX 0x5000.
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 14), wa		; save bitmask
	ldw (xsp + 4), 0x0000		; init result = 0
	ld xiz, 0:i3			; accumulator = 0
	; --- Bit 0: call handler(0) and handler(1) ---
	ld wa, (xsp + 14)
	bit 0, wa
	jr z, .Lcv_bit1
	lda xwa, (xsp + 6)		; XWA = scratch buffer address
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); (0x23A1A2) — workspace ptr
	ld xwa, (xwa + WS_HamaFnTable)             ; XWA = (XWA+0x0E88)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)             ; XHL = (XWA+0x0080) — handler
	ld wa, 0:i3			; param = 0
	call (xhl)
	add xiz, (xsp + 10)		; accumulate size
	lda xwa, (xsp + 6)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)
	ld wa, 1:i3			; param = 1
	call (xhl)
	add xiz, (xsp + 10)
	; --- Bit 1: call handler(2) ---
.Lcv_bit1:
	ld wa, (xsp + 14)
	bit 1, wa
	jr z, .Lcv_bit2
	lda xwa, (xsp + 6)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)
	ld wa, 2:i3			; param = 2
	call (xhl)
	add xiz, (xsp + 10)
	; --- Bit 2: call handler(3) + extra handler at +0x34 ---
.Lcv_bit2:
	ld wa, (xsp + 14)
	bit 2, wa
	jr z, .Lcv_bit3
	lda xwa, (xsp + 6)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)
	ld wa, 3:i3			; param = 3
	call (xhl)
	add xiz, (xsp + 10)
	; Extra handler at +0x34
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld xix, (xwa + HamaFn_SeqSavePre)
	call (xix)
	add xiz, xhl
	; --- Bit 3: handler at +0x44 ---
.Lcv_bit3:
	ld wa, (xsp + 14)
	bit 3, wa
	jr z, .Lcv_bit4
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld xix, (xwa + HamaFn_cmp_sv_mae)
	call (xix)
	add xiz, xhl
	; --- Bit 4: fixed constant 0x72AA ---
.Lcv_bit4:
	ld wa, (xsp + 14)
	bit 4, wa
	jr z, .Lcv_bit5
	ld xwa, 0x000072AA
	ld (xsp + 10), xwa
	add xiz, (xsp + 10)
	; --- Bit 5: handler at +0x64 ---
.Lcv_bit5:
	ld wa, (xsp + 14)
	bit 5, wa
	jr z, .Lcv_bit6
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld xix, (xwa + HamaFn_msp_sv_mae)
	call (xix)
	add xiz, xhl
	; --- Bit 6: call handler(8) ---
.Lcv_bit6:
	ld wa, (xsp + 14)
	bit 6, wa
	jr z, .Lcv_bit7
	lda xwa, (xsp + 6)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)
	ldw wa, 8			; param = 8
	call (xhl)
	add xiz, (xsp + 10)
	; --- Bit 7: call handler(9) ---
.Lcv_bit7:
	ld wa, (xsp + 14)
	bit 7, wa
	jr z, .Lcv_bit8
	lda xwa, (xsp + 6)
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_HamaFnTable)
	ld_sril xhl, (xwa + HamaFn_GetResouceInfo)
	ldw wa, 9			; param = 9
	call (xhl)
	add xiz, (xsp + 10)
	; --- Bit 8: fixed constant 0x5000 ---
.Lcv_bit8:
	ld wa, (xsp + 14)
	bit 8, wa
	jr z, .Lcv_final
	add xiz, 0x00005000
	; --- Final validation ---
.Lcv_final:
	ld xwa, xiz			; total accumulated size
	call HDAE5000_HD_ClusterCount			; validate total
	ld xiz, xhl			; save result
	call HDAE5000_HD_CountFreeClusters_Status			; get available space
	cp xhl, xiz			; available > needed?
	jr ugt, .Lcv_done
	ldw (xsp + 4), 0xFFFF		; set error flag
.Lcv_done:
	ld hl, (xsp + 4)
	pop xiz
	lda xsp, (xsp + 12)
	ret

HDAE5000_RoundUpToSector:	; 0x293DF1 (61 bytes)
	; Get cell rendering parameters from data source
	; Input: XWA = source pointer (0 = use default address 0x200)
	; Output: XHL = parameter block pointer
	; ^ corrected: XWA is a BYTE COUNT: XHL = XWA rounded up to a multiple of
	;   512 (HDAE5000_LDiv by 0x200), and 0x200 for 0.  Used for part sizes.
	dec 0, xsp			; allocate 8 bytes
	push xiz
	ld xiz, xwa			; XIZ = source pointer
	or xwa, xwa			; test if source is NULL
	jr z, .Lcgp_default
	ld xbc, 0x00000200		; buffer size = 512
	push xbc
	push xwa			; source pointer
	lda xwa, (xsp + 0x0C)		; pointer to local buffer
	push xwa
	call HDAE5000_LDiv
	lda xsp, (xsp + 0x0C)		; clean up 12 bytes from stack
	ld xwa, (xsp + 8)		; check copied length
	or xwa, xwa
	jr z, .Lcgp_result
	ld xwa, (xsp + 4)		; get offset field
	sla xwa, 9			; multiply by 512
	add xwa, 0x00000200		; add base address
	ld xiz, xwa			; XIZ = computed address
	jr t, .Lcgp_result
.Lcgp_default:
	ld xiz, 0x00000200		; default: address 0x200
.Lcgp_result:
	ld xhl, xiz			; return value in XHL
	pop xiz
	inc 0, xsp			; deallocate 8 bytes
	ret

HDAE5000_HD_StoreTables:	; 0x293E2E (1093 bytes)
	; Display callback handler via workspace
	; ^ corrected: write the filesystem tables to disk.  Main-CPU callback
	;   0x0E88 table +0xE8, ATA soft reset, HDAE5000_HD_WriteTables_Status,
	;   standby unless WA = 1, callbacks +0xEC/+0xF0; HL = the OR of the
	;   statuses (0 = ok).  PC-link services 10-12 and 22 call it.
; LDC: 0x293E2E (1093 bytes)
	; ^ conversion-region size (local-label prefix .LDC_), not a routine
	;   size: HD_StoreTables .. HD_WriteStream.

	dec	2, xsp
	pushw iz                                ; push IZ
	ld (xsp + 0x02), wa                     ; ld (XSP+0x02),WA
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_PlayHalt)
	ld	wa, 1:i3
	call	(xhl)
	call HDAE5000_ATA_SoftReset_Status
	ld	iz, hl
	call HDAE5000_HD_WriteTables_Status
	or	iz, hl
	cpw	(xsp+2), 0x0001
	jr z, .LDC_3e60                        ; [66 06] jr Z,0x293e60
	call HDAE5000_ATA_Standby_Status
	or	iz, hl
.LDC_3e60:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_PlayStandBy)
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_EditSwRefresh)
	call	(xhl)
	ld	hl, iz
	popw iz                                 ; pop IZ
	inc 2, xsp                              ; inc 2,XSP
	ret

HDAE5000_HD_LoadTables:
	; read the filesystem tables from disk: the same bracket as
	; HDAE5000_HD_StoreTables around HDAE5000_HD_ReadTables_Status.  PC-link
	; services 7-9 and PPI_Write_Sector call it.
	dec	2, xsp
	pushw iz                                ; push IZ
	ld (xsp + 0x02), wa                     ; ld (XSP+0x02),WA
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_PlayHalt)
	ld	wa, 1:i3
	call	(xhl)
	call HDAE5000_ATA_SoftReset_Status
	ld	iz, hl
	call HDAE5000_HD_ReadTables_Status
	or	iz, hl
	cpw	(xsp+2), 0x0001
	jr z, .LDC_3eba                        ; [66 06] jr Z,0x293eba
	call HDAE5000_ATA_Standby_Status
	or	iz, hl
.LDC_3eba:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_PlayStandBy)
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_EditSwRefresh)
	call	(xhl)
	ld	hl, iz
	popw iz                                 ; pop IZ
	inc 2, xsp                              ; inc 2,XSP
	ret

HDAE5000_HD_RestoreSettings:
	; The HDAE5000_HD_LoadSettings counterpart of HDAE5000_HD_StoreSettings
	; (same main-CPU bracket).  No reference to it was found
	; (scripts/analysis/hdae5000_reachability.py): unreachable.
	dec	2, xsp
	pushw iz                                ; push IZ
	ld (xsp + 0x02), wa                     ; ld (XSP+0x02),WA
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_PlayHalt)
	ld	wa, 1:i3
	call	(xhl)
	call HDAE5000_ATA_SoftReset_Status
	ld	iz, hl
	call HDAE5000_HD_LoadSettings
	or	iz, hl
	cpw	(xsp+2), 0x0001
	jr z, .LDC_3f14                        ; [66 06] jr Z,0x293f14
	call HDAE5000_ATA_Standby_Status
	or	iz, hl
.LDC_3f14:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_PlayStandBy)
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_EditSwRefresh)
	call	(xhl)
	ld	hl, iz
	popw iz                                 ; pop IZ
	inc 2, xsp                              ; inc 2,XSP
	ret

HDAE5000_HD_StoreSettings:
	; write the settings sector (HDAE5000_HD_SaveSettings) inside the same
	; main-CPU bracket as HDAE5000_HD_StoreTables; WA = 1 keeps the drive
	; spinning.  Callers: SetupP2SwCatch, AttenHDFormatSwCatch (case 6).
	dec	2, xsp
	pushw iz                                ; push IZ
	ld (xsp + 0x02), wa                     ; ld (XSP+0x02),WA
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_PlayHalt)
	ld	wa, 1:i3
	call	(xhl)
	call HDAE5000_ATA_SoftReset_Status
	ld	iz, hl
	call HDAE5000_HD_SaveSettings
	or	iz, hl
	cpw	(xsp+2), 0x0001
	jr z, .LDC_3f6e                        ; [66 06] jr Z,0x293f6e
	call HDAE5000_ATA_Standby_Status
	or	iz, hl
.LDC_3f6e:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_PlayStandBy)
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_EditSwRefresh)
	call	(xhl)
	ld	hl, iz
	popw iz                                 ; pop IZ
	inc 2, xsp                              ; inc 2,XSP
	ret

HDAE5000_RcmStream_Read:
	; Read callback handed to the main CPU by HDAE5000_LoadSong_Rcm (workspace
	; 0x0E88 table +0xB0, with HDAE5000_RcmStream_LastResult): XWA = buffer,
	; XBC = byte count.  The first call (state 0x238F1C = 0) starts
	; HDAE5000_HD_ReadFile on the RCM slot (+60) of song (0x238F1E dir,
	; 0x238F20 song), later calls continue with HDAE5000_HD_ReadFileNext
	; (state 1); the result goes to 0x238F22.  Returns XHL = XBC.
	lda	xsp, (xsp-12)
	push xiz
	ld (xsp + 0x0c), xbc                    ; ld (XSP+0x0c),XBC
	ld	bc, (HDAE5000_RAM_HdStreamBufferEnd:24)
	cp	bc, 1:i3
	jr z, .LDC_3fff                        ; [66 59] jr Z,0x293fff
	cp	bc, 0:i3
	jrl nz, .LDC_4053                      ; [7e a8 00] jrl NZ,0x294053
	ld (xsp + 0x04), xwa                    ; ld (XSP+0x04),XWA
	ld xwa, (xsp + 0x0c)                    ; ld XWA,(XSP+0x0c)
	ld (xsp + 0x08), xwa                    ; ld (XSP+0x08),XWA
	ld	wa, (0x238F20:24)
	extz xwa
	ld	xbc, 0x0000004c
	call HDAE5000_Multiply
	ld	xiz, xhl
	ld	wa, (0x238F1E:24)
	extz xwa
	ld	xbc, 0x000004c0
	call HDAE5000_Multiply
	add	xhl, 0x00000780
	add	xhl, xiz
	lda xwa, (0x20166e:24)
	add	xwa, xhl
	ld	xde, xwa
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xbc, (xsp + 0x08)                    ; ld XBC,(XSP+0x08)
	call HDAE5000_HD_ReadFile
	ld	(0x238f22), hl
	ldw	(HDAE5000_RAM_HdStreamBufferEnd:24), 1
	jr t, .LDC_4061                        ; [68 62] jr T,0x294061
.LDC_3fff:
	ld (xsp + 0x04), xwa                    ; ld (XSP+0x04),XWA
	ld xwa, (xsp + 0x0c)                    ; ld XWA,(XSP+0x0c)
	ld (xsp + 0x08), xwa                    ; ld (XSP+0x08),XWA
	ld	wa, (0x238F20:24)
	extz xwa
	ld	xbc, 0x0000004c
	call HDAE5000_Multiply
	ld	xiz, xhl
	ld	wa, (0x238F1E:24)
	extz xwa
	ld	xbc, 0x000004c0
	call HDAE5000_Multiply
	add	xhl, 0x00000780
	add	xhl, xiz
	lda xwa, (0x20166e:24)
	add	xwa, xhl
	ld	xde, xwa
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xbc, (xsp + 0x08)                    ; ld XBC,(XSP+0x08)
	call HDAE5000_HD_ReadFileNext
	ld	(0x238f22), hl
	ldw	(HDAE5000_RAM_HdStreamBufferEnd:24), 1
	jr t, .LDC_4061                        ; [68 0e] jr T,0x294061
.LDC_4053:
	ldw	(0x238F22:24), 65535
	ldw	(HDAE5000_RAM_HdStreamBufferEnd:24), 0
.LDC_4061:
	ld xhl, (xsp + 0x0c)                    ; ld XHL,(XSP+0x0c)
	pop xiz                                 ; pop XIZ
	lda	xsp, (xsp+12)
	ret

HDAE5000_RcmStream_Write:
	; Write callback handed to the main CPU by HDAE5000_SaveSong_Rcm (workspace
	; 0x0E88 table +0xB4, after HDAE5000_HD_WriteOpen on the RCM slot): XWA =
	; data, XBC = byte count, through HDAE5000_HD_WriteStream; marks the RCM
	; part byte (+32) of song (0x238F1E, 0x238F20); state 0x238F1C -> 2,
	; result -> 0x238F22.  Returns XHL = XBC.
	dec	6, xsp
	push xiz
	ld (xsp + 0x06), xbc                    ; ld (XSP+0x06),XBC
	ld	bc, (HDAE5000_RAM_HdStreamBufferEnd:24)
	cp	bc, 2:i3
	jr z, .LDC_40da                        ; [66 62] jr Z,0x2940da
	cp	bc, 0:i3
	jrl nz, .LDC_4137                      ; [7e ba 00] jrl NZ,0x294137
	ld xbc, (xsp + 0x06)                    ; ld XBC,(XSP+0x06)
	calr	HDAE5000_HD_WriteStream
	cp	hl, 0xffff
	jr z, .LDC_40cb                        ; [66 42] jr Z,0x2940cb
	ldw (xsp + 0x04), 0
	ld	wa, (0x238F20:24)
	extz xwa
	ld	xbc, 0x0000004c
	call HDAE5000_Multiply
	ld	xiz, xhl
	ld	wa, (0x238F1E:24)
	extz xwa
	ld	xbc, 0x000004c0
	call HDAE5000_Multiply
	add	xhl, 0x00000780
	add	xhl, xiz
	lda xwa, (0x201652:24)
	add	xwa, xhl
	ld	(xwa), 0x01
	ldw	(HDAE5000_RAM_HdStreamBufferEnd:24), 2
	jr t, .LDC_40d0                        ; [68 05] jr T,0x2940d0
.LDC_40cb:
	ldw (xsp + 0x04), 65535
.LDC_40d0:
	ld	wa, (xsp+4)
	ld	(0x238f22), wa
	jr t, .LDC_4145                        ; [68 6b] jr T,0x294145
.LDC_40da:
	ld xbc, (xsp + 0x06)                    ; ld XBC,(XSP+0x06)
	calr	HDAE5000_HD_WriteStream
	cp	hl, 0xffff
	jr z, .LDC_4128                        ; [66 42] jr Z,0x294128
	ldw (xsp + 0x04), 0
	ld	wa, (0x238F20:24)
	extz xwa
	ld	xbc, 0x0000004c
	call HDAE5000_Multiply
	ld	xiz, xhl
	ld	wa, (0x238F1E:24)
	extz xwa
	ld	xbc, 0x000004c0
	call HDAE5000_Multiply
	add	xhl, 0x00000780
	add	xhl, xiz
	lda xwa, (0x201652:24)
	add	xwa, xhl
	ld	(xwa), 0x01
	ldw	(HDAE5000_RAM_HdStreamBufferEnd:24), 2
	jr t, .LDC_412d                        ; [68 05] jr T,0x29412d
.LDC_4128:
	ldw (xsp + 0x04), 65535
.LDC_412d:
	ld	wa, (xsp+4)
	ld	(0x238f22), wa
	jr t, .LDC_4145                        ; [68 0e] jr T,0x294145
.LDC_4137:
	ldw	(0x238F22:24), 65535
	ldw	(HDAE5000_RAM_HdStreamBufferEnd:24), 0
.LDC_4145:
	ld xhl, (xsp + 0x06)                    ; ld XHL,(XSP+0x06)
	pop xiz                                 ; pop XIZ
	inc	6, xsp
	ret

HDAE5000_RcmStream_LastResult:
	; HL = the result of the last RCM stream read/write (0x238F22); handed to
	; the main CPU by HDAE5000_LoadSong_Rcm and HDAE5000_SaveSong_Rcm.
	ld	hl, (0x238F22:24)
	ret

HDAE5000_RcmStream_FreeSpace:
	; XHL = the free-space field of HDAE5000_HD_GetDiskUsage (units of
	; 10,000 bytes) shifted left by 10; handed to the main CPU by
	; HDAE5000_SaveSong_Rcm.
	lda	xsp, (xsp-16)
	lda	xwa, (xsp)
	call HDAE5000_HD_GetDiskUsage
	ld xhl, (xsp + 0x0c)                    ; ld XHL,(XSP+0x0c)
	sll	xhl, 0x0a
	lda	xsp, (xsp+16)
	ret

HDAE5000_HD_GetBlockInfo:
	; WA = block (0 dir, 1 file system, 2 FLS), XBC = destination: stores
	; {long address; u16 record width; u16 record count[; u16 items]} of the
	; in-RAM filesystem table -- 0: 0x201632, 16, 120 (the directory names,
	; the "FGB" of the service-4 trace); 1: 0x201DB2, 76, 1920 (the file
	; records, "FEB"); 2: 0x2257B2, 144, 120, 32 ("FLS").  Callers: PC-link
	; services 4-6 (SendInfosAbout{Dir,FileSystem,Fls}Block).
	cp	wa, 2:i3
	jr z, .LDC_4195                        ; [66 2c] jr Z,0x294195
	cp	wa, 1:i3
	jr z, .LDC_4183                        ; [66 16] jr Z,0x294183
	cp	wa, 0:i3
	ret nz                                  ; ret NZ

	lda xwa, (HDAE5000_RAM_DirNames:24)
	ld (xbc), xwa                           ; ld (XBC),XWA
	ldw	(xbc+4), 0x0010
	ldw	(xbc+6), 0x0078
	ret

.LDC_4183:
	lda xwa, (HDAE5000_RAM_SongRecords:24)
	ld (xbc), xwa                           ; ld (XBC),XWA
	ldw	(xbc+4), 0x004c
	ldw	(xbc+6), 0x0780
	ret

.LDC_4195:
	lda xwa, (HDAE5000_RAM_FlsRecords:24)
	ld (xbc), xwa                           ; ld (XBC),XWA
	ldw	(xbc+4), 0x0090
	ldw	(xbc+6), 0x0078
	ldw	(xbc+8), 0x0020
	ret

HDAE5000_HD_GetSongInfo:
	; (WA = directory, BC = file, XDE = destination; PC-link service 13,
	; SendInfosAboutSong): dest+0 = HDAE5000_Song_PartMask(WA, BC) (0xFFFF
	; -> return HL = 0xFFFF), dest+2 = the 16-byte directory name, dest+18 =
	; the 26-byte file name, dest+44 = bytes 26..35 of the 76-byte file
	; record.  HL = 0.
	dec 0, xsp                              ; dec 0,XSP
	push xiz
	ld (xsp + 0x04), xde                    ; ld (XSP+0x04),XDE
	ld (xsp + 0x08), bc
	ld (xsp + 0x0a), wa                     ; ld (XSP+0x0a),WA
	ld	wa, (xsp+10)
	ld	bc, (xsp+8)
	calr	HDAE5000_Song_PartMask
	ld	wa, hl
	cp	wa, 0xffff
	jrl z, .LDC_426f                       ; [76 a5 00] jrl Z,0x29426f
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld (xwa), hl                            ; ld (XWA),HL
	pushw 0x0010
	ld	wa, (xsp+12)
	extz xwa
	sll	xwa, 0x04
	ld	xbc, HDAE5000_RAM_DirNames
	add	xbc, xwa
	push xbc
	ld xwa, (xsp + 0x0a)                    ; ld XWA,(XSP+0x0a)
	inc 2, xwa                              ; inc 2,XWA
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+10)
	pushw 0x001a
	ld	wa, (xsp+10)
	extz xwa
	ld	xbc, 0x0000004c
	call HDAE5000_Multiply
	ld	xiz, xhl
	ld	wa, (xsp+12)
	extz xwa
	ld	xbc, 0x000004c0
	call HDAE5000_Multiply
	add	xhl, 0x00000780
	add	xhl, xiz
	ld	xwa, HDAE5000_RAM_DirNames
	add	xwa, xhl
	push xwa
	ld xwa, (xsp + 0x0a)                    ; ld XWA,(XSP+0x0a)
	lda	xwa, (xwa+18)
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+10)
	pushw 0x000a
	ld	wa, (xsp+10)
	extz xwa
	ld	xbc, 0x0000004c
	call HDAE5000_Multiply
	ld	xiz, xhl
	ld	wa, (xsp+12)
	extz xwa
	ld	xbc, 0x000004c0
	call HDAE5000_Multiply
	add	xhl, 0x00000780
	add	xhl, xiz
	lda xwa, (0x20164c:24)
	add	xwa, xhl
	push xwa
	ld xwa, (xsp + 0x0a)                    ; ld XWA,(XSP+0x0a)
	lda	xwa, (xwa+44)
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+10)
	ld	hl, 0:i3
.LDC_426f:
	pop xiz                                 ; pop XIZ
	inc 0, xsp                              ; inc 0,XSP
	ret


HDAE5000_HD_WriteOpen:	; 0x294273 (43 bytes)
	; Open a buffered write (the "WriteOpenHD" of PC-link service 21,
	; HDAE5000_PPORT_Svc21_WriteOpenHD, which calls it):
	; Input: XWA = pointer to the file's first-cluster slot, kept in
	;        0x238F28 and later passed as XDE to HDAE5000_HD_WriteFile /
	;        HDAE5000_HD_AppendFile
	; Output: HL = 0 (opened; fill pointer 0x238F24 = the 0x8000-byte buffer
	;         0x230F1C, state 0x238F2C = 1) or 0xFFFF (a write was already
	;         open: state reset to 0)
	; (An earlier header read 0x238F28 as a "callback function pointer";
	; it is only ever used as that XDE.)
	cp (HDAE5000_RAM_HdStreamState:24), 0x00; write state 0x238F2C: 0 = closed
	jr z, .Lds273_setup
	ld (HDAE5000_RAM_HdStreamState:24), 0x00; clear active flag
	ldw hl, 0xFFFF			; return -1 (already active)
	jr t, .Lds273_done
.Lds273_setup:
	lda xbc, (HDAE5000_RAM_HdStreamBuffer:24); the 0x8000-byte write buffer 0x230F1C
	ld (HDAE5000_RAM_HdStreamFill:24), xbc; fill pointer 0x238F24 = buffer start
	ld (HDAE5000_RAM_HdStreamSlot:24), xwa; 0x238F28 = the first-cluster slot pointer
	ld (HDAE5000_RAM_HdStreamState:24), 0x01; state 1 = open, nothing written yet
	ld hl, 0:i3			; return 0 (success)
.Lds273_done:
	ret

HDAE5000_HD_WriteClose:	; 0x29429E (99 bytes)
	; Close a buffered write ("WriteCloseHD", PC-link service 22): the
	; bytes still in the buffer (fill pointer 0x238F24 - 0x230F1C) go out
	; with HDAE5000_HD_WriteFile while state 0x238F2C is 1 (nothing written
	; yet) or HDAE5000_HD_AppendFile otherwise; state -> 0.
	; (Was described as executing a "display callback".)
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); buffer start 0x230F1C
	cp xwa, (HDAE5000_RAM_HdStreamFill:24); buffer empty (fill pointer 0x238F24 at start)?
	jr z, .Lds29e_clear
	cp (HDAE5000_RAM_HdStreamState:24), 0x01; state 1: nothing on disk yet
	jr nz, .Lds29e_restore
	; State 1: the buffer is the whole file -> HD_WriteFile
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); XWA = buffer start
	ld xhl, xwa			; XHL = buffer start
	lda xbc, (HDAE5000_RAM_HdStreamBuffer:24); XBC = base
	ld xwa, (HDAE5000_RAM_HdStreamFill:24); XWA = fill pointer
	sub xwa, xbc			; XWA = bytes in the buffer
	ld xbc, xwa			; XBC = byte count
	ld xde, (HDAE5000_RAM_HdStreamSlot:24); XDE = first-cluster slot pointer (0x238F28)
	ld xwa, xhl			; XWA = source (buffer start)
	call HDAE5000_HD_WriteFile
	ld (HDAE5000_RAM_HdStreamState:24), 0x02; set state to 2
	jr t, .Lds29e_clear
.Lds29e_restore:
	; State 2: earlier chunks written -> HD_AppendFile
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); XWA = buffer start
	ld xhl, xwa
	lda xbc, (HDAE5000_RAM_HdStreamBuffer:24); XBC = base
	ld xwa, (HDAE5000_RAM_HdStreamFill:24); XWA = fill pointer
	sub xwa, xbc			; XWA = bytes in the buffer
	ld xbc, xwa			; XBC = byte count
	ld xde, (HDAE5000_RAM_HdStreamSlot:24); XDE = first-cluster slot pointer
	ld xwa, xhl			; XWA = source (buffer start)
	call HDAE5000_HD_AppendFile
.Lds29e_clear:
	ld (HDAE5000_RAM_HdStreamState:24), 0x00; state 0 = closed
	ret

HDAE5000_HD_WriteStream:	; 0x294301 (275 bytes)
	; Buffered write ("WriteFileHD", PC-link service 23): XWA = source,
	; XBC = byte count.  Copies into the 0x8000-byte buffer 0x230F1C (at
	; fill pointer 0x238F24, in HDAE5000_MemCopy pieces of at most 0xFFFF);
	; each time it fills, the buffer goes to disk -- HDAE5000_HD_WriteFile
	; the first time (state 0x238F2C 1 -> 2), HDAE5000_HD_AppendFile after
	; that.  HL = 0, or 0xFFFF when no write is open or a disk write fails.
	lda xsp, (xsp - 14)
	push xiz
	ld (xsp + 10), xbc		; save arg1
	ld (xsp + 14), xwa		; save arg0
	ldw (xsp + 8), 0x0000		; init result = 0
	ld a, (HDAE5000_RAM_HdStreamState:24); write state 0x238F2C (1 or 2 = open)
	cp a, 2:i3
	jr z, .Lds301_mode2
	cp a, 1:i3
	jr nz, .Lds301_err1
.Lds301_mode2:
	ld xwa, (xsp + 10)		; reload arg1
	or xwa, xwa			; test if zero
	jr nz, .Lds301_compute
	ldw hl, 0xFFFF
	jrl .Lds301_exit
.Lds301_err1:
	ldw hl, 0xFFFF
	jrl .Lds301_exit
.Lds301_compute:
	lda xwa, (HDAE5000_RAM_HdStreamBufferEnd:24); XWA = 0x238F1C, the END of the buffer
	sub xwa, (HDAE5000_RAM_HdStreamFill:24); XWA -= fill pointer (0x238F24) => room left
	ld (xsp + 4), xwa		; save remaining
	ld xwa, (xsp + 10)		; reload arg1 (requested size)
	cp xwa, (xsp + 4)		; compare requested vs remaining
	jr ugt, .Lds301_use_remaining
	ld xiz, (xsp + 10)		; XIZ = requested (fits)
	jr .Lds301_check_limit
.Lds301_use_remaining:
	ld xiz, (xsp + 4)		; XIZ = remaining (capped)
.Lds301_check_limit:
	cp xiz, 0x0000FFFF		; compare with 0xFFFF
	jr ule, .Lds301_small
	; Large transfer: split into two calls
	pushw 0xFFFF			; count = 0xFFFF
	ld xwa, (xsp + 16)		; reload arg0 (adjusted for push)
	push xwa			; push source
	ld xwa, (HDAE5000_RAM_HdStreamFill:24); XWA = current position
	push xwa			; push dest
	call HDAE5000_MemCopy
	ld xwa, xiz			; XWA = total size
	sub xwa, 0x0000FFFF		; remainder after first chunk
	pushw wa			; push remainder count
	ld xwa, (xsp + 26)		; reload arg0 (deep stack)
	add xwa, 0x0000FFFF		; advance source by 0xFFFF
	push xwa			; push adjusted source
	ld xwa, (HDAE5000_RAM_HdStreamFill:24); reload current position
	add xwa, 0x0000FFFF		; advance dest by 0xFFFF
	push xwa			; push adjusted dest
	call HDAE5000_MemCopy
	lda xsp, (xsp + 20)		; cleanup 20 bytes of args
	jr .Lds301_update
.Lds301_small:
	ld wa, iz			; WA = count (16-bit)
	pushw wa			; push count
	ld xwa, (xsp + 16)		; reload arg0
	push xwa			; push source
	ld xwa, (HDAE5000_RAM_HdStreamFill:24); current position
	push xwa			; push dest
	call HDAE5000_MemCopy
	lda xsp, (xsp + 10)		; cleanup 10 bytes of args
.Lds301_update:
	add (xsp + 14), xiz		; advance arg0 by transferred size
	add (HDAE5000_RAM_HdStreamFill:24), xiz                ; advance current position
	sub (xsp + 4), xiz		; decrease remaining
	ld xwa, (xsp + 4)		; check if remaining > 0
	or xwa, xwa
	jr nz, .Lds301_finalize
	; Remaining exhausted — handle based on active flag
	cp (HDAE5000_RAM_HdStreamState:24), 0x01; active flag == 1?
	jr nz, .Lds301_flag2
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ld xde, (HDAE5000_RAM_HdStreamSlot:24); XDE = first-cluster slot pointer
	ld xbc, 0x00008000
	call HDAE5000_HD_WriteFile
	ld (xsp + 8), hl		; save result
	ld (HDAE5000_RAM_HdStreamState:24), 0x02; set active flag = 2
	jr .Lds301_check_result
.Lds301_flag2:
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C
	ld xde, (HDAE5000_RAM_HdStreamSlot:24); XDE = first-cluster slot pointer
	ld xbc, 0x00008000
	call HDAE5000_HD_AppendFile
	ld (xsp + 8), hl		; save result
.Lds301_check_result:
	cpw (xsp + 8), 0x0000	; result == 0?
	jr nz, .Lds301_exit_result
	lda xwa, (HDAE5000_RAM_HdStreamBuffer:24); 0x230F1C — reset position
	ld (HDAE5000_RAM_HdStreamFill:24), xwa; store to current position
.Lds301_finalize:
	sub (xsp + 10), xiz		; decrease arg1 by transferred
	ld xwa, (xsp + 10)		; check if arg1 > 0
	or xwa, xwa
	jrl nz, .Lds301_compute	; loop if more to transfer
.Lds301_exit_result:
	ld hl, (xsp + 8)		; load result
.Lds301_exit:
	pop xiz
	lda xsp, (xsp + 14)
	ret

HDAE5000_DebugTrace:	; 0x294414 (3061 bytes)
	; debug trace output, COMPILED OUT: the whole routine is this one `ret`.
	; 60 call sites load XWA with a string and call it -- either a banner
	; "---[ <FunctionName> ]---" (ROM 0x2F8F5E..0x2F9361, in the block under
	; HDAE5000_Display_Params) or a line just formatted into a stack buffer
	; with HDAE5000_SPrintf ("FGB wid : %d" ...).  The banners are the only
	; surviving developer names of the PC-link services below, which is how
	; HDAE5000_PPORT_Svc01..Svc25 are named.
	; (The old header "Large display management routine" described nothing
	; here: 0x294414 is a lone 0x0E.)
; LDS: 0x294414 (3061 bytes)
	; ^ region size: the stub plus the 26 PC-link service routines that
	;   follow, up to HDAE5000_PPORT_Svc27 at 0x295009.

	ret

	; a second one-byte `ret` (0x294415); nothing in this ROM calls or
	; points at it (searched: symbolic references and the literal 0x294415).
	ret

HDAE5000_PPORT_Svc01_GetInfoBlockPointer:
	; PC-link service 1: HDAE5000_PPORT_ServiceTable[1], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F8F5E):
	; "GetInfoBlockPointer".
	lda	xsp, (xsp-32)
	lda xwa, (0x2f8f5e:24)
	calr	HDAE5000_DebugTrace
	lda xwa, (0x238f2e:24)
	push xwa
	pushw 0x002f
	pushw 0x8f7c
	lda	xwa, (xsp+8)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	lda	xwa, (xsp)
	calr	HDAE5000_DebugTrace
	lda xwa, (0x2f8f8c:24)
	calr	HDAE5000_DebugTrace
	lda xhl, (0x238f2e:24)
	lda	xsp, (xsp+32)
	ret

HDAE5000_PPORT_Svc02_TurnHdMotorOff:
	; PC-link service 2: HDAE5000_PPORT_ServiceTable[2], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F8F8E):
	; "TurnHdMotorOff".
	pushw iz                                ; push IZ
	ld	iz, 0:i3
	call HDAE5000_ATA_Standby_Status
	cp	hl, 0xffff
	jr nz, .LDS_445d                       ; [6e 02] jr NZ,0x29445d
	ld	iz, 1:i3
.LDS_445d:
	lda xwa, (0x2f8f8e:24)
	calr	HDAE5000_DebugTrace
	lda xwa, (0x2f8fa8:24)
	calr	HDAE5000_DebugTrace
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

HDAE5000_PPORT_Svc03_SendInfosAboutHd:
	; PC-link service 3: HDAE5000_PPORT_ServiceTable[3], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F8FAA):
	; "SendInfosAboutHd".
	lda	xsp, (xsp-116)
	lda	xwa, (xsp+64)
	call HDAE5000_HD_GetGeometry
	pushw 0x001e
	lda	xwa, (xsp+76)
	push xwa
	lda xwa, (0x238fc5:24)
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+10)
	ld	wa, (xsp+64)
	extz xwa
	ld	(0x238fe3), xwa
	ld	wa, (xsp+66)
	ld	(0x238fe7), wa
	ld	wa, (xsp+68)
	ld	(0x238fe9), wa
	ldw	(0x238FEB:24), 512
	ld	a, (0x23A04A:24)
	ld	(0x238FF6:24), a
	ld	a, (0x23A04C:24)
	ld	(0x238FF7:24), a
	lda xwa, (0x2f8faa:24)
	calr	HDAE5000_DebugTrace
	pushw 0x002f
	pushw 0x8fc6
	lda	xwa, (xsp+4)
	push xwa
	call HDAE5000_SPrintf
	pushw 0x001e
	lda xwa, (0x238fc5:24)
	push xwa
	lda	xwa, (xsp+24)
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+18)
	lda	xwa, (xsp)
	calr	HDAE5000_DebugTrace
	ld	xwa, (0x238fe3)
	push xwa
	pushw 0x002f
	pushw 0x8fd2
	lda	xwa, (xsp+8)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	lda	xwa, (xsp)
	calr	HDAE5000_DebugTrace
	pushw	(0x238FE7:24)
	pushw 0x002f
	pushw 0x8fe0
	lda	xwa, (xsp+6)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+10)
	lda	xwa, (xsp)
	calr	HDAE5000_DebugTrace
	pushw	(0x238FE9:24)
	pushw 0x002f
	pushw 0x8fee
	lda	xwa, (xsp+6)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+10)
	lda	xwa, (xsp)
	calr	HDAE5000_DebugTrace
	pushw	(0x238FEB:24)
	pushw 0x002f
	pushw 0x8ffc
	lda	xwa, (xsp+6)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+10)
	lda	xwa, (xsp)
	calr	HDAE5000_DebugTrace
	lda xwa, (0x2f900a:24)
	calr	HDAE5000_DebugTrace
	ld	hl, 0:i3
	lda	xsp, (xsp+116)
	ret

HDAE5000_PPORT_Svc04_SendInfosAboutDirBlock:
	; PC-link service 4: HDAE5000_PPORT_ServiceTable[4], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F900C):
	; "SendInfosAboutDirBlock".
	lda	xsp, (xsp-74)
	lda	xwa, (xsp+64)
	ld	xbc, xwa
	ld	wa, 0:i3
	call HDAE5000_HD_GetBlockInfo
	ld xwa, (xsp + 0x40)                    ; ld XWA,(XSP+0x40)
	ld	(0x238f5a), xwa
	ld	wa, (xsp+68)
	ld	(0x238f5e), wa
	ld	wa, (xsp+70)
	ld	(0x238f60), wa
	lda xwa, (0x2f900c:24)
	calr	HDAE5000_DebugTrace
	ld	xwa, (0x238f5a)
	push xwa
	pushw 0x002f
	pushw 0x902e
	lda	xwa, (xsp+8)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	lda	xwa, (xsp)
	calr	HDAE5000_DebugTrace
	pushw	(0x238F5E:24)
	pushw 0x002f
	pushw 0x903c
	lda	xwa, (xsp+6)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+10)
	lda	xwa, (xsp)
	calr	HDAE5000_DebugTrace
	pushw	(0x238F60:24)
	pushw 0x002f
	pushw 0x904a
	lda	xwa, (xsp+6)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+10)
	lda	xwa, (xsp)
	calr	HDAE5000_DebugTrace
	lda xwa, (0x2f9058:24)
	calr	HDAE5000_DebugTrace
	lda	xsp, (xsp+74)
	ret

HDAE5000_PPORT_Svc05_SendInfosAboutFileSystemBlock:
	; PC-link service 5: HDAE5000_PPORT_ServiceTable[5], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F905A):
	; "SendInfosAboutFileSystemBlock".
	lda	xsp, (xsp-74)
	lda	xwa, (xsp+64)
	ld	xbc, xwa
	ld	wa, 1:i3
	call HDAE5000_HD_GetBlockInfo
	ld xwa, (xsp + 0x40)                    ; ld XWA,(XSP+0x40)
	ld	(0x238f62), xwa
	ld	wa, (xsp+68)
	ld	(0x238f66), wa
	ld	wa, (xsp+70)
	ld	(0x238f68), wa
	lda xwa, (0x2f905a:24)
	calr	HDAE5000_DebugTrace
	ld	xwa, (0x238f62)
	push xwa
	pushw 0x002f
	pushw 0x9082
	lda	xwa, (xsp+8)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	lda	xwa, (xsp)
	calr	HDAE5000_DebugTrace
	pushw	(0x238F66:24)
	pushw 0x002f
	pushw 0x9090
	lda	xwa, (xsp+6)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+10)
	lda	xwa, (xsp)
	calr	HDAE5000_DebugTrace
	pushw	(0x238F68:24)
	pushw 0x002f
	pushw 0x909e
	lda	xwa, (xsp+6)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+10)
	lda	xwa, (xsp)
	calr	HDAE5000_DebugTrace
	lda xwa, (0x2f90ac:24)
	calr	HDAE5000_DebugTrace
	lda	xsp, (xsp+74)
	ret

HDAE5000_PPORT_Svc06_SendInfosAboutFlsBlock:
	; PC-link service 6: HDAE5000_PPORT_ServiceTable[6], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F90AE):
	; "SendInfosAboutFlsBlock".
	lda	xsp, (xsp-74)
	lda	xwa, (xsp+64)
	ld	xbc, xwa
	ld	wa, 2:i3
	call HDAE5000_HD_GetBlockInfo
	ld xwa, (xsp + 0x40)                    ; ld XWA,(XSP+0x40)
	ld	(0x238f6a), xwa
	ld	wa, (xsp+68)
	ld	(0x238f6e), wa
	ld	wa, (xsp+70)
	ld	(0x238f70), wa
	ld	wa, (xsp+72)
	ld	(0x238f72), wa
	lda xwa, (0x2f90ae:24)
	calr	HDAE5000_DebugTrace
	ld	xwa, (0x238f6a)
	push xwa
	pushw 0x002f
	pushw 0x90d0
	lda	xwa, (xsp+8)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	lda	xwa, (xsp)
	calr	HDAE5000_DebugTrace
	pushw	(0x238F6E:24)
	pushw 0x002f
	pushw 0x90de
	lda	xwa, (xsp+6)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+10)
	lda	xwa, (xsp)
	calr	HDAE5000_DebugTrace
	pushw	(0x238F70:24)
	pushw 0x002f
	pushw 0x90ec
	lda	xwa, (xsp+6)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+10)
	lda	xwa, (xsp)
	calr	HDAE5000_DebugTrace
	pushw	(0x238F72:24)
	pushw 0x002f
	pushw 0x90fa
	lda	xwa, (xsp+6)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+10)
	lda	xwa, (xsp)
	calr	HDAE5000_DebugTrace
	lda xwa, (0x2f9108:24)
	calr	HDAE5000_DebugTrace
	lda	xsp, (xsp+74)
	ret

HDAE5000_PPORT_Svc07_ReadDirBlockFromHd:
	; PC-link service 7: HDAE5000_PPORT_ServiceTable[7], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F910A):
	; "ReadDirBlockFromHd".
	pushw iz                                ; push IZ
	ld	iz, 0:i3
	ld	wa, 1:i3
	call HDAE5000_HD_LoadTables
	cp	hl, 0xffff
	jr nz, .LDS_4746                       ; [6e 02] jr NZ,0x294746
	ld	iz, 1:i3
.LDS_4746:
	lda xwa, (0x2f910a:24)
	calr	HDAE5000_DebugTrace
	lda xwa, (0x2f9128:24)
	calr	HDAE5000_DebugTrace
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

HDAE5000_PPORT_Svc08_ReadFileBlockFromHd:
	; PC-link service 8: HDAE5000_PPORT_ServiceTable[8], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F912A):
	; "ReadFileBlockFromHd".
	pushw iz                                ; push IZ
	ld	iz, 0:i3
	ld	wa, 1:i3
	call HDAE5000_HD_LoadTables
	cp	hl, 0xffff
	jr nz, .LDS_476b                       ; [6e 02] jr NZ,0x29476b
	ld	iz, 1:i3
.LDS_476b:
	lda xwa, (0x2f912a:24)
	calr	HDAE5000_DebugTrace
	lda xwa, (0x2f9148:24)
	calr	HDAE5000_DebugTrace
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

HDAE5000_PPORT_Svc09_ReadFlsBlockFromHd:
	; PC-link service 9: HDAE5000_PPORT_ServiceTable[9], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F914A):
	; "ReadFlsBlockFromHd".
	pushw iz                                ; push IZ
	ld	iz, 0:i3
	ld	wa, 1:i3
	call HDAE5000_HD_LoadTables
	cp	hl, 0xffff
	jr nz, .LDS_4790                       ; [6e 02] jr NZ,0x294790
	ld	iz, 1:i3
.LDS_4790:
	lda xwa, (0x2f914a:24)
	calr	HDAE5000_DebugTrace
	lda xwa, (0x2f9168:24)
	calr	HDAE5000_DebugTrace
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

HDAE5000_PPORT_Svc10_WriteDirBlockToHd:
	; PC-link service 10: HDAE5000_PPORT_ServiceTable[10], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F916A):
	; "WriteDirBlockToHd".
	pushw iz                                ; push IZ
	ld	iz, 0:i3
	ld	wa, 1:i3
	call HDAE5000_HD_StoreTables
	cp	hl, 0xffff
	jr nz, .LDS_47b5                       ; [6e 02] jr NZ,0x2947b5
	ld	iz, 1:i3
.LDS_47b5:
	lda xwa, (0x2f916a:24)
	calr	HDAE5000_DebugTrace
	lda xwa, (0x2f9186:24)
	calr	HDAE5000_DebugTrace
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

HDAE5000_PPORT_Svc11_WriteFileSystemBlockToHd:
	; PC-link service 11: HDAE5000_PPORT_ServiceTable[11], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F9188):
	; "WriteFileSystemBlockToHd".
	pushw iz                                ; push IZ
	ld	iz, 0:i3
	ld	wa, 1:i3
	call HDAE5000_HD_StoreTables
	cp	hl, 0xffff
	jr nz, .LDS_47da                       ; [6e 02] jr NZ,0x2947da
	ld	iz, 1:i3
.LDS_47da:
	lda xwa, (0x2f9188:24)
	calr	HDAE5000_DebugTrace
	lda xwa, (0x2f91ac:24)
	calr	HDAE5000_DebugTrace
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

HDAE5000_PPORT_Svc12_WriteFlsBlockToHd:
	; PC-link service 12: HDAE5000_PPORT_ServiceTable[12], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F91AE):
	; "WriteFlsBlockToHd".
	pushw iz                                ; push IZ
	ld	iz, 0:i3
	ld	wa, 1:i3
	call HDAE5000_HD_StoreTables
	cp	hl, 0xffff
	jr nz, .LDS_47ff                       ; [6e 02] jr NZ,0x2947ff
	ld	iz, 1:i3
.LDS_47ff:
	lda xwa, (0x2f91ae:24)
	calr	HDAE5000_DebugTrace
	lda xwa, (0x2f91ca:24)
	calr	HDAE5000_DebugTrace
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

HDAE5000_PPORT_Svc13_SendInfosAboutSong:
	; PC-link service 13: HDAE5000_PPORT_ServiceTable[13], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F91CC):
	; "SendInfosAboutSong".
	lda	xsp, (xsp-128)
	push xiz
	stw_dri bc, 0xFD, 0x82, 0x00	; ld (XSP+0x0082),BC
	ld	iz, wa
	ld	qiz, 1
	ldw	(0x238F2E:24), 0
	pushw 0x0010
	pushw 0x0020
	lda xwa, (0x238f4a:24)
	push xwa
	call HDAE5000_MemFill
	pushw 0x001a
	pushw 0x0020
	lda xwa, (0x238f30:24)
	push xwa
	call HDAE5000_MemFill
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+68)
	ld	xbc, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_GetResouceInfo)
	ld	wa, 0:i3
	call	(xhl)
	ld xwa, (xsp + 0x44)                    ; ld XWA,(XSP+0x44)
	ld	(0x238f74), xwa
	ld xwa, (xsp + 0x48)                    ; ld XWA,(XSP+0x48)
	ld	(0x238f78), xwa
	ld	(0x238F7C:24), 0
	lda	xwa, (xsp+68)
	ld	xbc, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_GetResouceInfo)
	ld	wa, 1:i3
	call	(xhl)
	ld xwa, (xsp + 0x44)                    ; ld XWA,(XSP+0x44)
	ld	(0x238f7d), xwa
	ld xwa, (xsp + 0x48)                    ; ld XWA,(XSP+0x48)
	ld	(0x238f81), xwa
	ld	(0x238F85:24), 0
	lda	xwa, (xsp+68)
	ld	xbc, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_GetResouceInfo)
	ld	wa, 2:i3
	call	(xhl)
	ld xwa, (xsp + 0x44)                    ; ld XWA,(XSP+0x44)
	ld	(0x238f86), xwa
	ld xwa, (xsp + 0x48)                    ; ld XWA,(XSP+0x48)
	ld	(0x238f8a), xwa
	ld	(0x238F8E:24), 0
	lda	xwa, (xsp+68)
	ld	xbc, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_GetResouceInfo)
	ld	wa, 3:i3
	call	(xhl)
	ld xwa, (xsp + 0x44)                    ; ld XWA,(XSP+0x44)
	ld	(0x238f8f), xwa
	ld xwa, (xsp + 0x48)                    ; ld XWA,(XSP+0x48)
	ld	(0x238f93), xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld xix, (xwa + HamaFn_SeqSavePre)                    ; ld XIX,(XWA+0x34)
	call	(xix)
	add	(0x238F93:24), xhl
	ld	(0x238F97:24), 0
	lda	xwa, (xsp+68)
	ld	xbc, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_GetResouceInfo)
	ld	wa, 5:i3
	call	(xhl)
	ld xwa, (xsp + 0x44)                    ; ld XWA,(XSP+0x44)
	ld	(0x238f98), xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld xix, (xwa + HamaFn_cmp_sv_mae)                    ; ld XIX,(XWA+0x44)
	call	(xix)
	ld	(0x238f9c), xhl
	ld	(0x238FA0:24), 0
	lda	xwa, (xsp+68)
	ld	xbc, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_GetResouceInfo)
	ld	wa, 6:i3
	call	(xhl)
	ld xwa, (xsp + 0x44)                    ; ld XWA,(XSP+0x44)
	ld	(0x238fa1), xwa
	ld	xwa, 0x000072aa
	ld	(0x238fa5), xwa
	ld	(0x238FA9:24), 0
	lda	xwa, (xsp+68)
	ld	xbc, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_GetResouceInfo)
	ld	wa, 7:i3
	call	(xhl)
	ld xwa, (xsp + 0x44)                    ; ld XWA,(XSP+0x44)
	ld	(0x238faa), xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld xix, (xwa + HamaFn_msp_sv_mae)                    ; ld XIX,(XWA+0x64)
	call	(xix)
	ld	(0x238fae), xhl
	ld	(0x238FB2:24), 0
	lda	xwa, (xsp+68)
	ld	xbc, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_GetResouceInfo)
	ldw	wa, 0x0008
	call	(xhl)
	ld xwa, (xsp + 0x44)                    ; ld XWA,(XSP+0x44)
	ld	(0x238fb3), xwa
	ld	xwa, 0x000ad000
	ld	(0x238fb7), xwa
	ld	(0x238FBB:24), 0
	lda	xwa, (xsp+68)
	ld	xbc, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_GetResouceInfo)
	ldw	wa, 0x0009
	call	(xhl)
	ld xwa, (xsp + 0x44)                    ; ld XWA,(XSP+0x44)
	ld	(0x238fbc), xwa
	ld xwa, (xsp + 0x48)                    ; ld XWA,(XSP+0x48)
	ld	(0x238fc0), xwa
	ld	(0x238FC4:24), 0
	lda	xwa, (xsp+68)
	ld	xbc, xwa
	ldw	wa, 0x000a
	call HDAE5000_TlxPart_Describe
	ld xwa, (xsp + 0x44)                    ; ld XWA,(XSP+0x44)
	ld	(0x238fed), xwa
	ld xwa, (xsp + 0x48)                    ; ld XWA,(XSP+0x48)
	ld	(0x238ff1), xwa
	ld	(0x238FF5:24), 0
	lda	xwa, (xsp+76)
	ld	xde, xwa
	ld	wa, iz
	ldw_sri0	bc, (xsp + 0x0082)
	call HDAE5000_HD_GetSongInfo
	cp	hl, 0xffff
	jr z, .LDS_4acd                        ; [66 7a] jr Z,0x294acd
	ld	wa, (xsp+76)
	ld	(0x238f2e), wa
	pushw 0x0010
	lda	xwa, (xsp+80)
	push xwa
	lda xwa, (0x238f4a:24)
	push xwa
	call HDAE5000_MemCopy
	pushw 0x001a
	lda	xwa, (xsp+106)
	push xwa
	lda xwa, (0x238f30:24)
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+20)
	ld	a, (xsp+120)
	ld	(0x238F7C:24), a
	ld	a, (xsp+121)
	ld	(0x238F8E:24), a
	ld	a, (xsp+122)
	ld	(0x238F97:24), a
	ld	a, (xsp+123)
	ld	(0x238FA0:24), a
	ld	a, (xsp+124)
	ld	(0x238FA9:24), a
	ld	a, (xsp+125)
	ld	(0x238FB2:24), a
	ld	a, (xsp+126)
	ld	(0x238FBB:24), a
	ld	a, (xsp+127)
	ld	(0x238FC4:24), a
	ldb_sri0	a, (xsp + 0x0080)
	ld	(0x238FF5:24), a
	ld	qiz, 0
.LDS_4acd:
	lda xwa, (0x2f91cc:24)
	calr	HDAE5000_DebugTrace
	lda xwa, (0x238f4a:24)
	push xwa
	pushw 0x002f
	pushw 0x91ea
	lda	xwa, (xsp+12)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	lda	xwa, (xsp+4)
	calr	HDAE5000_DebugTrace
	lda xwa, (0x238f30:24)
	push xwa
	pushw 0x002f
	pushw 0x91f8
	lda	xwa, (xsp+12)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	lda	xwa, (xsp+4)
	calr	HDAE5000_DebugTrace
	lda xwa, (0x2f9206:24)
	calr	HDAE5000_DebugTrace
	ld	hl, qiz
	pop xiz                                 ; pop XIZ
	lda_dri xsp, 0xFD, 0x80, 0x00	; lda XSP,XSP+0x0080
	ret

HDAE5000_PPORT_Svc14_LoadSongFromHdToMemory:
	; PC-link service 14: HDAE5000_PPORT_ServiceTable[14], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F9208):
	; "LoadSongFromHdToMemory".
	pushw iz                                ; push IZ
	ld	iz, 0:i3
	pushw 0x0000
	pushw 0x0001
	ld	de, (0x238F2E:24)
	call HDAE5000_LoadSong
	cp	hl, 0xffff
	jr nz, .LDS_4b3b                       ; [6e 02] jr NZ,0x294b3b
	ld	iz, 1:i3
.LDS_4b3b:
	lda xwa, (0x2f9208:24)
	calr	HDAE5000_DebugTrace
	lda xwa, (0x2f922a:24)
	calr	HDAE5000_DebugTrace
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

HDAE5000_PPORT_Svc15_SaveSongInMemoryToHd:
	; PC-link service 15: HDAE5000_PPORT_ServiceTable[15], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F922C):
	; "SaveSongInMemoryToHd".
	pushw iz                                ; push IZ
	ld	iz, 0:i3
	lda xde, (0x238f30:24)
	pushw	(0x238F2E:24)
	pushw 0x0000
	pushw 0x0001
	call HDAE5000_SaveSong
	cp	hl, 0xffff
	jr nz, .LDS_4b6e                       ; [6e 02] jr NZ,0x294b6e
	ld	iz, 1:i3
.LDS_4b6e:
	lda xwa, (0x2f922c:24)
	calr	HDAE5000_DebugTrace
	lda xwa, (0x2f924c:24)
	calr	HDAE5000_DebugTrace
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

HDAE5000_PPORT_Svc16_InitWholeSongInMemory:
	; PC-link service 16: HDAE5000_PPORT_ServiceTable[16], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F924E):
	; "InitWholeSongInMemory".
	ld	wa, (0x238F2E:24)
	bit	0x00, wa
	jr z, .LDS_4b9d                        ; [66 11] jr Z,0x294b9d
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_PostLswLoad)                    ; ld XHL,(XWA+0x10)
	ld	wa, 0:i3
	call	(xhl)
.LDS_4b9d:
	ld	wa, (0x238F2E:24)
	bit	0x01, wa
	jr z, .LDS_4bb8                        ; [66 11] jr Z,0x294bb8
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_PostPmLoad)                    ; ld XHL,(XWA+0x20)
	ld	wa, 0:i3
	call	(xhl)
.LDS_4bb8:
	ld	wa, (0x238F2E:24)
	bit	0x02, wa
	jr z, .LDS_4bee                        ; [66 2c] jr Z,0x294bee
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_SeqLoadPost)                    ; ld XHL,(XWA+0x30)
	ld	wa, 0:i3
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + 0x11fa)
	ld xhl, (xwa + 0x18)                    ; ld XHL,(XWA+0x18)
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00013
	ld	xde, 0:i3
	call	(xhl)
.LDS_4bee:
	ld	wa, (0x238F2E:24)
	bit	0x03, wa
	jr z, .LDS_4c09                        ; [66 11] jr Z,0x294c09
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_cmp_ld_ato)                    ; ld XHL,(XWA+0x40)
	ld	wa, 0:i3
	call	(xhl)
.LDS_4c09:
	ld	wa, (0x238F2E:24)
	bit	0x04, wa
	jr z, .LDS_4c24                        ; [66 11] jr Z,0x294c24
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_PostTmLoad)                    ; ld XHL,(XWA+0x50)
	ld	wa, 0:i3
	call	(xhl)
.LDS_4c24:
	ld	wa, (0x238F2E:24)
	bit	0x05, wa
	jr z, .LDS_4c3f                        ; [66 11] jr Z,0x294c3f
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_msp_ld_ato)                    ; ld XHL,(XWA+0x60)
	ld	wa, 0:i3
	call	(xhl)
.LDS_4c3f:
	ld	wa, (0x238F2E:24)
	bit	0x07, wa
	jr z, .LDS_4c5a                        ; [66 11] jr Z,0x294c5a
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_PostMidiLoad)                    ; ld XHL,(XWA+0x70)
	ld	wa, 0:i3
	call	(xhl)
.LDS_4c5a:
	lda xwa, (0x2f924e:24)
	calr	HDAE5000_DebugTrace
	lda xwa, (0x2f926e:24)
	jrl	t, HDAE5000_DebugTrace
HDAE5000_PPORT_Svc17_FormatHd:
	; PC-link service 17: HDAE5000_PPORT_ServiceTable[17], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F9270):
	; "FormatHd".
	pushw iz                                ; push IZ
	ld	iz, 0:i3
	ld	wa, 0:i3
	call HDAE5000_HD_FormatDrive
	cp	hl, 0:i3
	jr z, .LDS_4c79                        ; [66 02] jr Z,0x294c79
	ld	iz, 1:i3
.LDS_4c79:
	lda xwa, (0x2f9270:24)
	calr	HDAE5000_DebugTrace
	lda xwa, (0x2f9284:24)
	calr	HDAE5000_DebugTrace
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

HDAE5000_PPORT_Svc18:
	; PC-link service 18: HDAE5000_PPORT_ServiceTable[18].  Tail-calls
	; RootFn_ApPostEvent(0xFFFFFFFF, 0x01C00014, 0x01800001): a request for
	; mode 1, the post the main CPU's own boot makes (see HDAE5000_RequestMode,
	; which does the same after cancelling a queued one).  It prints no trace
	; banner.  (workspace[0x0E0A]+0x0124 is ApPostEvent by the firmware's own
	; name table: scripts/converters/hdae5000_symbolize_fn_tables.py.)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_ApPostEvent)
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00014
	ld	xde, 0x01800001
	jp	(xhl)
HDAE5000_PPORT_Svc19_SendPointerToFreeBufferSpace:
	; PC-link service 19: HDAE5000_PPORT_ServiceTable[19], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F9286):
	; "SendPointerToFreeBufferSpace".
	lda	xsp, (xsp-64)
	lda xwa, (0x2f9286:24)
	calr	HDAE5000_DebugTrace
	ld	xwa, 0:i3
	ld	a, (0x238FF8:24)
	push xwa
	pushw 0x002f
	pushw 0x92ae
	lda	xwa, (xsp+8)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	lda xwa, (0x2f92be:24)
	calr	HDAE5000_DebugTrace
	lda xhl, (0x238ff8:24)
	lda	xsp, (xsp+64)
	ret

HDAE5000_PPORT_Svc20_PreWholeSongInMemory:
	; PC-link service 20: HDAE5000_PPORT_ServiceTable[20], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F92C0):
	; "PreWholeSongInMemory".
	ld	wa, (0x238F2E:24)
	bit	0x00, wa
	jr z, .LDS_4cfb                        ; [66 0f] jr Z,0x294cfb
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_PreLswLoad)                    ; ld XHL,(XWA+0x0c)
	call	(xhl)
.LDS_4cfb:
	ld	wa, (0x238F2E:24)
	bit	0x01, wa
	jr z, .LDS_4d14                        ; [66 0f] jr Z,0x294d14
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_PrePmLoad)                    ; ld XHL,(XWA+0x1c)
	call	(xhl)
.LDS_4d14:
	ld	wa, (0x238F2E:24)
	bit	0x02, wa
	jr z, .LDS_4d2d                        ; [66 0f] jr Z,0x294d2d
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_SeqLoadPre)                    ; ld XHL,(XWA+0x2c)
	call	(xhl)
.LDS_4d2d:
	ld	wa, (0x238F2E:24)
	bit	0x03, wa
	jr z, .LDS_4d46                        ; [66 0f] jr Z,0x294d46
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_cmp_ld_mae)                    ; ld XHL,(XWA+0x3c)
	call	(xhl)
.LDS_4d46:
	ld	wa, (0x238F2E:24)
	bit	0x04, wa
	jr z, .LDS_4d5f                        ; [66 0f] jr Z,0x294d5f
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_PreTmLoad)                    ; ld XHL,(XWA+0x4c)
	call	(xhl)
.LDS_4d5f:
	ld	wa, (0x238F2E:24)
	bit	0x05, wa
	jr z, .LDS_4d78                        ; [66 0f] jr Z,0x294d78
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_msp_ld_mae)                    ; ld XHL,(XWA+0x5c)
	call	(xhl)
.LDS_4d78:
	ld	wa, (0x238F2E:24)
	bit	0x07, wa
	jr z, .LDS_4d91                        ; [66 0f] jr Z,0x294d91
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld xhl, (xwa + HamaFn_PreMidiLoad)                    ; ld XHL,(XWA+0x6c)
	call	(xhl)
.LDS_4d91:
	lda xwa, (0x2f92c0:24)
	calr	HDAE5000_DebugTrace
	lda xwa, (0x2f92e0:24)
	jrl	t, HDAE5000_DebugTrace
HDAE5000_PPORT_Svc21_WriteOpenHD:
	; PC-link service 21: HDAE5000_PPORT_ServiceTable[21], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F92E2):
	; "WriteOpenHD".
	lda	xsp, (xsp-28)
	push xiz
	ld (xsp + 0x1c), bc
	ld (xsp + 0x1e), wa                     ; ld (XSP+0x1e),WA
	ldw (xsp + 0x04), 1
	lda xwa, (0x2f92e2:24)
	calr	HDAE5000_DebugTrace
	ld	wa, (0x238F2E:24)
	ld	(xsp+6), 0x00
	cp	(xsp+6), 0x09
	jrl nc, .LDS_4ec0                      ; [7f f8 00] jrl NC,0x294ec0
.LDS_4dc8:
	bit	0x00, wa
	jrl z, .LDS_4eb3                       ; [76 e5 00] jrl Z,0x294eb3
	ld	wa, (xsp+28)
	extz xwa
	ld	xbc, 0x0000004c
	call HDAE5000_Multiply
	ld	xiz, xhl
	ld	wa, (xsp+30)
	extz xwa
	ld	xbc, 0x000004c0
	call HDAE5000_Multiply
	add	xhl, 0x00000780
	add	xhl, xiz
	ld	xbc, HDAE5000_RAM_DirNames
	add	xbc, xhl
	ld	a, (xsp+6)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	add	wa, 0x0024
	exts xwa                                ; exts XWA
	add	xwa, xbc
	call HDAE5000_HD_WriteOpen
	cp	hl, 0xffff
	jr z, .LDS_4e94                        ; [66 7f] jr Z,0x294e94
	pushw 0x001a
	lda xwa, (0x238f30:24)
	push xwa
	ld	wa, (xsp+34)
	extz xwa
	ld	xbc, 0x0000004c
	call HDAE5000_Multiply
	ld	xiz, xhl
	ld	wa, (xsp+36)
	extz xwa
	ld	xbc, 0x000004c0
	call HDAE5000_Multiply
	add	xhl, 0x00000780
	add	xhl, xiz
	ld	xwa, HDAE5000_RAM_DirNames
	add	xwa, xhl
	push xwa
	call HDAE5000_StrNCpy
	lda	xsp, (xsp+10)
	ld	wa, (xsp+28)
	extz xwa
	ld	xbc, 0x0000004c
	call HDAE5000_Multiply
	ld	xiz, xhl
	ld	wa, (xsp+30)
	extz xwa
	ld	xbc, 0x000004c0
	call HDAE5000_Multiply
	add	xhl, 0x00000780
	add	xhl, xiz
	ld	xbc, HDAE5000_RAM_DirNames
	add	xbc, xhl
	ld	a, (xsp+6)
	extz wa                                 ; extz WA
	add	wa, 0x001a
	stib_ind 0x07, 0xE4, 0xE0, 0x01	; ld (XBC+WA),0x01
	ldw (xsp + 0x04), 0
.LDS_4e94:
	ld	a, (xsp+6)
	extz wa                                 ; extz WA
	pushw wa                                ; push WA
	pushw 0x002f
	pushw 0x92fa
	lda	xwa, (xsp+14)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+10)
	lda	xwa, (xsp+8)
	calr	HDAE5000_DebugTrace
	jr t, .LDS_4ec0                        ; [68 0d] jr T,0x294ec0
.LDS_4eb3:
	srl	wa, 0x01
	incm8	1, (xsp+6)
	cp	(xsp+6), 0x09
	jrl c, .LDS_4dc8                       ; [77 08 ff] jrl C,0x294dc8
.LDS_4ec0:
	ld	hl, (xsp+4)
	pop xiz                                 ; pop XIZ
	lda	xsp, (xsp+28)
	ret

HDAE5000_PPORT_Svc22_WriteCloseHD:
	; PC-link service 22: HDAE5000_PPORT_ServiceTable[22], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F9306):
	; "WriteCloseHD".
	pushw iz                                ; push IZ
	ld	iz, 1:i3
	call HDAE5000_HD_WriteClose
	cp	hl, 0xffff
	jr z, .LDS_4ee3                        ; [66 0e] jr Z,0x294ee3
	ld	wa, 1:i3
	call HDAE5000_HD_StoreTables
	cp	hl, 0xffff
	jr z, .LDS_4ee3                        ; [66 02] jr Z,0x294ee3
	ld	iz, 0:i3
.LDS_4ee3:
	lda xwa, (0x2f9306:24)
	calr	HDAE5000_DebugTrace
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

HDAE5000_PPORT_Svc23_WriteFileHD:
	; PC-link service 23: HDAE5000_PPORT_ServiceTable[23], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F931E):
	; "WriteFileHD".
	pushw iz                                ; push IZ
	ld	iz, 1:i3
	call HDAE5000_HD_WriteStream
	cp	hl, 0xffff
	jr z, .LDS_4efe                        ; [66 02] jr Z,0x294efe
	ld	iz, 0:i3
.LDS_4efe:
	lda xwa, (0x2f931e:24)
	calr	HDAE5000_DebugTrace
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

HDAE5000_PPORT_Svc24_ReadOpenHD:
	; PC-link service 24: HDAE5000_PPORT_ServiceTable[24], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F9336):
	; "ReadOpenHD".
	dec 0, xsp                              ; dec 0,XSP
	push	qiz
	ld (xsp + 0x06), bc
	ld (xsp + 0x08), wa                     ; ld (XSP+0x08),WA
	ldw (xsp + 0x04), 1
	lda xwa, (0x2f9336:24)
	calr	HDAE5000_DebugTrace
	ld	wa, (0x238F2E:24)
	ldib_erp 0xfb, 0		; ld QIZH,0
	cp_erpb 0xfb, 0x09		; cp QIZH,0x09
	jr nc, .LDS_4f92                       ; [6f 62] jr NC,0x294f92
.LDS_4f30:
	bit	0x00, wa
	jr z, .LDS_4f86                        ; [66 51] jr Z,0x294f86
	ld	wa, (xsp+6)
	extz xwa
	ld	xbc, 0x0000004c
	call HDAE5000_Multiply
	ld (xsp + 0x02), xhl                    ; ld (XSP+0x02),XHL
	ld	wa, (xsp+8)
	extz xwa
	ld	xbc, 0x000004c0
	call HDAE5000_Multiply
	add	xhl, 0x00000780
	add	xhl, (xsp+2)
	ld	xbc, HDAE5000_RAM_DirNames
	add	xbc, xhl
	stb_erp a, 0xfb		; ld A,QIZH
	extz wa                                 ; extz WA
	sla	wa, 0x02
	add	wa, 0x0024
	exts xwa                                ; exts XWA
	add	xwa, xbc
	ld	(0x238ffc), xwa
	ld	(0x23A1A6:24), 1
	ldw (xsp + 0x04), 0
	jr t, .LDS_4f92                        ; [68 0c] jr T,0x294f92
.LDS_4f86:
	srl	wa, 0x01
	incb_erp 0xfb, 1		; inc 1,QIZH
	cp_erpb 0xfb, 0x09		; cp QIZH,0x09
	jr c, .LDS_4f30                        ; [67 9e] jr C,0x294f30
.LDS_4f92:
	ld	hl, (xsp+4)
	pop	qiz
	inc 0, xsp                              ; inc 0,XSP
	ret

HDAE5000_PPORT_Svc25_ReadFileHD:
	; PC-link service 25: HDAE5000_PPORT_ServiceTable[25], run on the main
	; context by HDAE5000_PPORT_ServiceDispatch.  Developer's name from the
	; trace banner it passes to HDAE5000_DebugTrace (ROM 0x2F934C):
	; "ReadFileHD".
	dec	6, xsp
	push xiz
	ld (xsp + 0x06), xbc                    ; ld (XSP+0x06),XBC
	ld	xiz, xwa
	ldw (xsp + 0x04), 1
	lda xwa, (0x2f934c:24)
	calr	HDAE5000_DebugTrace
	cp	(0x23A1A6:24), 1
	jr nz, .LDS_4fd9                       ; [6e 21] jr NZ,0x294fd9
	ld	(0x23A1A6:24), 2
	ld	xwa, xiz
	ld xbc, (xsp + 0x06)                    ; ld XBC,(XSP+0x06)
	ld	xde, (0x238ffc)
	call HDAE5000_HD_ReadFile
	cp	hl, 0xffff
	jr z, .LDS_5002                        ; [66 30] jr Z,0x295002
	ldw (xsp + 0x04), 0
	jr t, .LDS_5002                        ; [68 29] jr T,0x295002
.LDS_4fd9:
	cp	(0x23A1A6:24), 2
	jr nz, .LDS_4ffc                       ; [6e 1b] jr NZ,0x294ffc
	ld	xwa, xiz
	ld xbc, (xsp + 0x06)                    ; ld XBC,(XSP+0x06)
	ld	xde, (0x238ffc)
	call HDAE5000_HD_ReadFileNext
	cp	hl, 0xffff
	jr z, .LDS_5002                        ; [66 0d] jr Z,0x295002
	ldw (xsp + 0x04), 0
	jr t, .LDS_5002                        ; [68 06] jr T,0x295002
.LDS_4ffc:
	ld	(0x23A1A6:24), 0
.LDS_5002:
	ld	hl, (xsp+4)
	pop xiz                                 ; pop XIZ
	inc	6, xsp
	ret


HDAE5000_PPORT_Svc27:	; 0x295009
	; PC-link service 27: HDAE5000_PPORT_ServiceTable[27].  Calls
	; HDAE5000_DeleteSongParts with DE = RAM (0x238F2E) and two word
	; arguments 1, 0; returns HL = 0.  What that callee does for the link is
	; not established.
	; PPORT utility - push params and call workspace handler
	pushw 0x0000			; arg 1
	pushw 0x0001			; arg 2
	ld de, (0x238f2e:24); DE = (0x238F2E) - callback ID
	call HDAE5000_DeleteSongParts
	ld hl, 0:i3			; return 0
	ret
	nop

; ============================================================================
; PC-LINK (PPORT) COROUTINE
; The parallel-port link to HD-TechManager runs as a second execution context
; with its own stack, switched by swapping XSP through two RAM slots:
;   0x239002  the link context's saved XSP   0x239006  the main context's
;   0x239000  1 = link active                0x239014  1 = service requested
;   0x23900A  service number (WA); -1 once the link has ended
;   0x23900C  argument XBC                   0x239010  argument XDE
; HDAE5000_PPORT_StartLink builds the link stack at 0x23FFFC with
; HDAE5000_PPORT_LinkEntry as its return address and switches to it.  The
; link never touches the HD itself: HDAE5000_PPORT_CallService posts a
; service number in the mailbox and yields; HDAE5000_PPORT_ServicePending
; (entered from the end of HDAE5000_Frame_Handler, via its _Exit jp) runs it on the
; main context and switches back.  Service 0 is an empty `ret`, so
; CallService(0) is a plain "yield until next frame" (the link's polling
; loops use it).
; ============================================================================
HDAE5000_PPORT_ServicePending:	; 0x29501C
	; main context, once per frame-handler pass: if a link is active, run the service it
	; posted (HDAE5000_PPORT_ServiceDispatch) and resume it
	; (HDAE5000_PPORT_ReturnToLink).
	; PPORT state machine entry - check active, load params, dispatch
	cp (0x239000:24), 0x01; check if PPORT active (0x239000)
	jr nz, .Lpph_done
	ld wa, (0x23900a:24); WA = cmd param (0x23900A)
	nop
	ld xbc, (0x23900c:24); XBC = data ptr (0x23900C)
	nop
	ld xde, (0x239010:24); XDE = size (0x239010)
	nop
	call HDAE5000_PPORT_ServiceDispatch
	call HDAE5000_PPORT_ReturnToLink
.Lpph_done:
	ret
	nop
	; --- Secondary entry: menu init ---
HDAE5000_PPORT_LinkEntry:
	; first code the link context runs (HDAE5000_PPORT_StartLink plants this
	; address at the top of the link stack); when the link program returns,
	; it yields for good with the request flag clear, which
	; HDAE5000_PPORT_ReturnToLink / _StartLink read as "link finished".
	call HDAE5000_PPORT_LinkMain
	jr t, HDAE5000_PPORT_YieldToMain

HDAE5000_PPORT_SwitchToLink:	; 0x295046
	; main -> link: saves XSP in 0x239006, loads the link's from 0x239002,
	; and the `ret` resumes the link wherever it last yielded.
	; Switch to PPORT stack context for status check
	ei 0x06				; disable interrupts (level 6)
	ld (0x239006:24), xsp; save current SP (0x239006)
	nop
	ld xsp, (0x239002:24); load PPORT SP (0x239002)
	nop
	ei 0x00				; re-enable interrupts
	ret
	nop

HDAE5000_PPORT_YieldToMain:	; 0x295058 (116 bytes, 3 entry points)
	; link -> main: the mirror image of HDAE5000_PPORT_SwitchToLink.
	; Entry 1: Stack context switch (save/restore SP for PPORT workspace)
	ei 0x06				; disable interrupts
	ld (0x239002:24), xsp; save current SP to (0x239002)
	nop
	ld xsp, (0x239006:24); load the MAIN context's SP from (0x239006)
	nop
	ei 0x00				; re-enable interrupts
	ret
	nop
HDAE5000_PPORT_StartLink:	; 0x29506A
	; create and enter the link context (A = mode for
	; HDAE5000_PPORT_Execute); returns when the link first yields.
	; Entry 2: Initialize PPORT state machine
	push xhl
	nop
	push xwa
	nop
	cp (0x239000:24), 0x01; cp (0x239000), 1 — already initialized?
	jr z, .Lpi_exit		; if already init, just return
	ld (0x239014:24), 0x00; clear abort flag (0x239014)
	ld (0x239000:24), 0x01; set state = initialized (0x239000)
	ld xhl, 0x0023FFFC	; stack top for PPORT workspace
	nop
	ld (0x239002:24), xhl; store as PPORT SP (0x239002)
	nop
	ld xwa, HDAE5000_PPORT_LinkEntry	; PPORT entry callback address
	nop
	ld (xhl), xwa		; store callback at stack top
	ld a, 0x00:opc		; param = 0
	call HDAE5000_PPORT_SwitchToLink	; switch to PPORT stack and call
	cp (0x239014:24), 0x00; check abort flag (0x239014)
	jr nz, .Lpi_exit	; if aborted, exit
	ldw hl, 0xFFFF		; HL = -1 (error/timeout)
	nop
	ld (0x23900a:24), hl; store result (0x23900A)
	nop
	ld (0x239000:24), 0x00; clear state = uninitialized
.Lpi_exit:
	pop xwa
	nop
	pop xhl
	nop
	ret
	nop
HDAE5000_PPORT_Reset:		; 0x2950BA
	; Entry 3: Reset PPORT state
	ldw hl, 0xFFFF		; HL = -1
	nop
	ld (0x23900a:24), hl; store result (0x23900A)
	nop
	ld (0x239000:24), 0x00; clear state = uninitialized
	ret
	nop

HDAE5000_PPORT_ReturnToLink:	; 0x2950CC
	; resume the link after a service; when it yields back WITHOUT a new
	; request (0x239014 = 0) the link program has ended: result := -1 and
	; the active flag is cleared.
	; Command dispatcher - switch to PPORT context, check for command
	push xhl
	nop
	call HDAE5000_PPORT_SwitchToLink	; switch stacks
	cp (0x239014:24), 0x00; check command flag (0x239014)
	jr nz, .Lppd_done
	ldw hl, 0xFFFF			; no command: mark result = -1
	nop
	ld (0x23900a:24), hl; store result (0x23900A)
	nop
	ld (0x239000:24), 0x00; clear PPORT active flag (0x239000)
.Lppd_done:
	pop xhl
	nop
	ret
	nop
	; --- Secondary entry: get result ---
HDAE5000_PPORT_GetResult:
	; no caller in this ROM (searched: symbolic references and the literal
	; 0x2950EE).
	ld hl, (0x23900a:24); HL = command result (0x23900A)
	nop
	exts xhl			; sign-extend to 32-bit
	ret
	nop

HDAE5000_PPORT_CallService:	; 0x2950F8
	; link context: ask the main context to run service WA (0..30, see
	; HDAE5000_PPORT_ServiceTable) with arguments XBC, XDE; returns when the
	; service has run, with its result in WA or XIX (only XSP is swapped by
	; the context switch, so the service stub's registers come back).  Named
	; Display_String before: it displays nothing -- its 59 call sites pass
	; service numbers (0 = yield, 1 = GetInfoBlockPointer, 0x1A = the
	; PP_STATUS text of HDAE5000_PPORT_Svc26_ShowStatus, ...).
	; Display string on screen via PPORT protocol
	; Input: WA = position, XBC = string ptr, XDE = format params
	ld (0x23900a:24), wa; store position (0x23900A)
	nop
	ld (0x23900c:24), xbc; store string ptr (0x23900C)
	nop
	ld (0x239010:24), xde; store format (0x239010)
	nop
	ld (0x239014:24), 0x01; set command flag (0x239014)
	call HDAE5000_PPORT_YieldToMain	; initialize PPORT transfer
	ld (0x239014:24), 0x00; clear command flag
	ret
	nop

HDAE5000_PPORT_ServiceDispatch:	; 0x29511C (442 bytes)
	; main context: run service WA through HDAE5000_PPORT_ServiceTable
	; (1..30; <= 0 or > 30 returns WA = 1).  Each table entry is a short stub
	; below that shuffles XBC/XDE into the service's argument registers.
	; PPORT command dispatcher — WA = command ID (1-30)
	cp wa, 0:i3
	jr le, .Lpps_error		; WA <= 0 → error
	cp wa, 0x001E
	jr gt, .Lpps_error		; WA > 30 → error
	push xhl
	nop
	ld hl, wa			; HL = command number
	sla xhl, 2			; XHL *= 4 (table offset)
	nop
	extz xhl			; zero-extend
	ld xix, HDAE5000_PPORT_ServiceTable	; table base
	nop
	ld_sril3 xhl, 0x07, 0xF0, 0xEC	; XHL = (XIX + HL) — load handler addr
	nop
	call (xhl)			; call handler
	pop xhl
	nop
	ret
	nop
.Lpps_error:
	ld wa, 1:i3			; return 1 (error)
	ret
	nop
HDAE5000_PPORT_ServiceTable:
	; 31-entry jump table (entry 0 unused, entries 1-30 = commands)
	.long .Lpps_handler_0	; entry 0 (unused)
	.long .Lpps_handler_1	; entry 1
	.long .Lpps_handler_2	; entry 2
	.long .Lpps_handler_3	; entry 3
	.long .Lpps_handler_4	; entry 4
	.long .Lpps_handler_5	; entry 5
	.long .Lpps_handler_6	; entry 6
	.long .Lpps_handler_7	; entry 7
	.long .Lpps_handler_8	; entry 8
	.long .Lpps_handler_9	; entry 9
	.long .Lpps_handler_10	; entry 10
	.long .Lpps_handler_11	; entry 11
	.long .Lpps_handler_12	; entry 12
	.long .Lpps_handler_13	; entry 13
	.long .Lpps_handler_14	; entry 14
	.long .Lpps_handler_15	; entry 15
	.long .Lpps_handler_16	; entry 16
	.long .Lpps_handler_17	; entry 17
	.long .Lpps_handler_18	; entry 18
	.long .Lpps_handler_19	; entry 19
	.long .Lpps_handler_20	; entry 20
	.long .Lpps_handler_21	; entry 21
	.long .Lpps_handler_22	; entry 22
	.long .Lpps_handler_23	; entry 23
	.long .Lpps_handler_24	; entry 24
	.long .Lpps_handler_25	; entry 25
	.long .Lpps_handler_26	; entry 26
	.long .Lpps_handler_27	; entry 27
	.long .Lpps_handler_28	; entry 28
	.long .Lpps_handler_29	; entry 29
	.long .Lpps_handler_30	; entry 30
	; --- Handler stubs (commands 0-30) ---
.Lpps_handler_0:			; 0x2951C2
	ret
	nop
.Lpps_handler_1:			; 0x2951C4
	call HDAE5000_PPORT_Svc01_GetInfoBlockPointer
	ld xix, xhl
	ret
	nop
.Lpps_handler_2:			; 0x2951CC
	call HDAE5000_PPORT_Svc02_TurnHdMotorOff
	ld wa, hl
	ret
	nop
.Lpps_handler_3:			; 0x2951D4
	call HDAE5000_PPORT_Svc03_SendInfosAboutHd
	ld wa, hl
	ret
	nop
.Lpps_handler_4:			; 0x2951DC
	call HDAE5000_PPORT_Svc04_SendInfosAboutDirBlock
	ret
	nop
.Lpps_handler_5:			; 0x2951E2
	call HDAE5000_PPORT_Svc05_SendInfosAboutFileSystemBlock
	ret
	nop
.Lpps_handler_6:			; 0x2951E8
	call HDAE5000_PPORT_Svc06_SendInfosAboutFlsBlock
	ret
	nop
.Lpps_handler_7:			; 0x2951EE
	call HDAE5000_PPORT_Svc07_ReadDirBlockFromHd
	ld wa, hl
	ret
	nop
.Lpps_handler_8:			; 0x2951F6
	call HDAE5000_PPORT_Svc08_ReadFileBlockFromHd
	ld wa, hl
	ret
	nop
.Lpps_handler_9:			; 0x2951FE
	call HDAE5000_PPORT_Svc09_ReadFlsBlockFromHd
	ld wa, hl
	ret
	nop
.Lpps_handler_10:			; 0x295206
	call HDAE5000_PPORT_Svc10_WriteDirBlockToHd
	ld wa, hl
	ret
	nop
.Lpps_handler_11:			; 0x29520E
	call HDAE5000_PPORT_Svc11_WriteFileSystemBlockToHd
	ld wa, hl
	ret
	nop
.Lpps_handler_12:			; 0x295216
	call HDAE5000_PPORT_Svc12_WriteFlsBlockToHd
	ld wa, hl
	ret
	nop
.Lpps_handler_13:			; 0x29521E
	ld wa, bc			; shuffle args
	ld bc, de
	call HDAE5000_PPORT_Svc13_SendInfosAboutSong
	ld wa, hl
	ret
	nop
.Lpps_handler_14:			; 0x29522A
	ld wa, bc
	ld bc, de
	call HDAE5000_PPORT_Svc14_LoadSongFromHdToMemory
	ld wa, hl
	ret
	nop
.Lpps_handler_15:			; 0x295236
	ld wa, bc
	ld bc, de
	call HDAE5000_PPORT_Svc15_SaveSongInMemoryToHd
	ld wa, hl
	ret
	nop
.Lpps_handler_16:			; 0x295242
	call HDAE5000_PPORT_Svc16_InitWholeSongInMemory
	ret
	nop
.Lpps_handler_17:			; 0x295248
	call HDAE5000_PPORT_Svc17_FormatHd
	ld wa, hl
	ret
	nop
.Lpps_handler_18:			; 0x295250
	call HDAE5000_PPORT_Svc18
	ret
	nop
.Lpps_handler_19:			; 0x295256
	call HDAE5000_PPORT_Svc19_SendPointerToFreeBufferSpace
	ld xix, xhl
	ret
	nop
.Lpps_handler_20:			; 0x29525E
	call HDAE5000_PPORT_Svc20_PreWholeSongInMemory
	ret
	nop
.Lpps_handler_21:			; 0x295264
	ld wa, bc
	ld bc, de
	call HDAE5000_PPORT_Svc21_WriteOpenHD
	ld wa, hl
	ret
	nop
.Lpps_handler_22:			; 0x295270
	call HDAE5000_PPORT_Svc22_WriteCloseHD
	ld wa, hl
	ret
	nop
.Lpps_handler_23:			; 0x295278
	ld xwa, xbc			; 32-bit arg shuffle
	ld xbc, xde
	call HDAE5000_PPORT_Svc23_WriteFileHD
	ld wa, hl
	ret
	nop
.Lpps_handler_24:			; 0x295284
	ld wa, bc
	ld bc, de
	call HDAE5000_PPORT_Svc24_ReadOpenHD
	ld wa, hl
	ret
	nop
.Lpps_handler_25:			; 0x295290
	ld xwa, xbc
	ld xbc, xde
	call HDAE5000_PPORT_Svc25_ReadFileHD
	ld wa, hl
	ret
	nop
.Lpps_handler_26:			; 0x29529C
	ld xwa, xbc
	call HDAE5000_PPORT_Svc26_ShowStatus
	ld wa, 0:i3
	ret
	nop
.Lpps_handler_27:			; 0x2952A6
	ld wa, bc
	ld bc, de
	call HDAE5000_PPORT_Svc27
	ld wa, hl
	ret
	nop
.Lpps_handler_28:			; 0x2952B2
	ld xwa, xbc
	ld xbc, xde
	call HDAE5000_PPORT_Svc28_FlashXapFile
	ld wa, hl
	ret
	nop
.Lpps_handler_29:			; 0x2952BE
	ld xwa, xbc
	ld xbc, xde
	call HDAE5000_PPORT_Svc29_MainHook0538
	ld wa, hl
	ret
	nop
.Lpps_handler_30:			; 0x2952CA
	ld xwa, xbc
	ld xbc, xde
	call HDAE5000_PPORT_Svc30_MainHook053C
	ld wa, hl
	ret
	nop

HDAE5000_PPORT_LinkMain:	; 0x2952D6
	; PPORT menu handler - save all registers, execute, restore
	push xwa
	nop
	push xbc
	nop
	push xde
	nop
	push xhl
	nop
	push xix
	nop
	push xiy
	nop
	push xiz
	nop
	call HDAE5000_PPORT_Execute
	pop xiz
	nop
	pop xiy
	nop
	pop xix
	nop
	pop xhl
	nop
	pop xde
	nop
	pop xbc
	nop
	pop xwa
	nop
	ret
	nop

HDAE5000_PPORT_Execute:	; 0x2952F8 (234 bytes)
	; Execute PPORT command — dispatch on A register (command ID 0-7)
	; ^ A = 0 or 1 enters the command loop (HDAE5000_PPORT_CommandLoop); every
	;   other value returns at once.  The link commands 1..20 are dispatched
	;   by the loop through HDAE5000_PPORT_CommandTable, not here.
	and a, 0x7F			; mask high bit
	nop
	cp a, 0:i3
	jr nz, .Lppe_cmd1
	jp HDAE5000_PPORT_CommandLoop		; cmd 0 → read/execute
.Lppe_cmd1:
	cp a, 1:i3
	jr nz, .Lppe_cmd2
	jp HDAE5000_PPORT_CommandLoop		; cmd 1 → read/execute
.Lppe_cmd2:
	cp a, 2:i3
	jr nz, .Lppe_cmd3
	jp .Lppe_simple_ret		; cmd 2 → simple ret
.Lppe_cmd3:
	cp a, 3:i3
	jr nz, .Lppe_cmd4
	jp .Lppe_simple_ret		; cmd 3 → simple ret
.Lppe_cmd4:
	cp a, 4:i3
	jr nz, .Lppe_cmd5
	jp .Lppe_simple_ret		; cmd 4 → simple ret
.Lppe_cmd5:
	cp a, 5:i3
	jr nz, .Lppe_cmd6
	jp .Lppe_simple_ret		; cmd 5 → simple ret
.Lppe_cmd6:
	cp a, 6:i3
	jr nz, .Lppe_cmd7
	jp .Lppe_simple_ret		; cmd 6 → simple ret
.Lppe_cmd7:
	cp a, 7:i3
	jr nz, .Lppe_default
	jp .Lppe_simple_ret		; cmd 7 → simple ret
.Lppe_default:
	jp .Lppe_simple_ret		; unknown → simple ret
.Lppe_simple_ret:
	ret
	; Padding (17 bytes)
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
HDAE5000_PPORT_InitPort:
	; Write I/O registers and clear flag
	ld a, 0x89:opc
	ld (0x160006:24), a; (0x160006) = 0x89
	nop
	ld a, 0x28:opc
	ld (0x160002:24), a; (0x160002) = 0x28
	nop
	ld (HDAE5000_RAM_PportError:24), 0x00; (0x2390D4) = 0
	ret
	nop
HDAE5000_PPORT_CommandLoop:
	; Read/execute with polling loop
	ei 0x07				; IFF=7: masks every maskable level -- this IS the real DI (06 07)
	ld a, 0x89:opc
	ld (0x160006:24), a; (0x160006) = 0x89
	nop
HDAE5000_PPORT_CommandLoop_Poll:
	ld wa, 0:i3			; WA = 0
	call HDAE5000_PPORT_CallService	; 0x2950F8
	ld a, (0x160004:24); read (0x160004)
	nop
	and a, 0x04			; test bit 2
	nop
	cp a, 4:i3			; bit 2 set?
	jr nz, HDAE5000_PPORT_CommandLoop_Poll		; keep polling if not
	ld a, 0x18:opc
	ld (0x160002:24), a; (0x160002) = 0x18
	nop
	ld (HDAE5000_RAM_PportError:24), 0x00; (0x2390D4) = 0
	call HDAE5000_PPORT_RecvPacket
	cp (HDAE5000_RAM_PportError:24), 0x01; (0x2390D4) == 1?
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)		; if Z, go back to polling (0x295374)
	nop
	lda xix, (HDAE5000_RAM_PportPacket:24); XIX = 0x239168
	nop
	xor xwa, xwa			; XWA = 0
	ld a, (xix)			; A = command index
	cp xwa, 0x00000014		; compare with 20
	jp ugt, (HDAE5000_PPORT_CommandLoop_Poll:24)		; if UGT 20, invalid → repoll (0x295374)
	nop
	dec 1, xwa			; XWA = index - 1
	sll xwa, 2			; XWA *= 4 (table entry size)
	nop
	lda xix, (HDAE5000_PPORT_CommandTable:24); XIX = jump table base (0x2953CE)
	nop
	add xix, xwa			; XIX += offset
	ld xiy, (xix)			; XIY = handler address
	jp (xiy)			; jump to handler
; ----------------------------------------------------------------------------
; HDAE5000_PPORT_CommandTable (0x2953CE, 20 x .long): the PC-link command
; handlers.  Reader: HDAE5000_PPORT_CommandLoop, which takes the command byte n
; (packet 0x239168 byte 0, rejected above 20), and jumps through entry n-1:
; `dec 1,xwa / sll xwa,2 / lda xix,(HDAE5000_PPORT_CommandTable) / add xix,xwa
; / ld xiy,(xix) / jp (xiy)`.  The table runs on through the labels
; HDAE5000_PPORT_Cmd_Table (entries 6-17) and HDAE5000_PPORT_Ptrs (18-20); the
; handler names come from the "NN>..." status record each one shows first.
; ----------------------------------------------------------------------------
HDAE5000_PPORT_CommandTable:
	; 5-entry jump table (4 bytes each)
	; ^ entries 1-5 of the 20: see the header above
	.long HDAE5000_PPORT_Cmd01_SendInfosAboutHd		; entry 0
	.long HDAE5000_PPORT_Cmd02_ExitPport		; entry 1
	.long HDAE5000_PPORT_Cmd03_ReadFsbFromHd		; entry 2
	.long HDAE5000_PPORT_Cmd04_SendFsbToPc		; entry 3
	.long HDAE5000_PPORT_Cmd05_RcvFsbFromPc		; entry 4

; ============================================================================
; PPORT COMMAND HANDLER JUMP TABLE (0x2953E2 - 0x295411)
; 12 entries × 4 bytes = 48 bytes
; ^ CORRECTION: these are entries 6-17 of HDAE5000_PPORT_CommandTable
;   (0x2953CE), i.e. commands 6..17; the index list below numbered them 1..12
;   ("Cmd01_SendInfo" is the handler of command 06, "Writing FSB to HD").
; Each entry is a 32-bit pointer to a command handler routine
;
; Index  Address   Description
;   0    0x2958D6  Cmd01_SendInfo - Send HD info to PC
;   1    0x295914  Cmd02_Exit - Exit PPORT mode
;   2    0x2959F6  Cmd03_ReadFSB - Read FSB from HD
;   3    0x295D3C  Cmd04_SendFSB - Send FSB to PC
;   4    0x29605A  Cmd05_RcvFSB - Receive FSB from PC
;   5    0x296294  Cmd06_WriteFSB - Write FSB to HD
;   6    0x29632A  Cmd07_LoadHD - Load HD to Memory
;   7    0x29633C  Cmd08_SendData - Send data to PC
;   8    0x2964A6  Cmd09_SendFiles - Send files to PC
;   9    0x296588  Cmd10_RcvData - Receive data from PC
;  10    0x29659A  Cmd11_SaveMem - Save memory to HD
;  11    0x296680  Cmd12_Nothing - (reserved)
; ============================================================================

HDAE5000_PPORT_Cmd_Table:	; 2953E2h
	.long HDAE5000_PPORT_Cmd06_WriteFsbToHd
	.long HDAE5000_PPORT_Cmd07_LoadHdToMemory
	.long HDAE5000_PPORT_Cmd08_SendDataToPc
	.long HDAE5000_PPORT_Cmd09_SendFilesToPc
	.long HDAE5000_PPORT_Cmd10_RcvDataFromPc
	.long HDAE5000_PPORT_Cmd11_SaveMemoryToHd
	.long HDAE5000_PPORT_Cmd12_Nothing
	.long HDAE5000_PPORT_Cmd13_RcvDataFromPc
	.long HDAE5000_PPORT_Cmd14_SendInfosToPc
	.long HDAE5000_PPORT_Cmd15_Nothing
	.long HDAE5000_PPORT_Cmd16_DeleteFiles
	.long HDAE5000_PPORT_Cmd17_FormatHd

; ============================================================================
; PPORT COMMAND MENU STRINGS (0x295412 - 0x295641)
; 21 null-terminated strings for PPORT menu display
; Format: "NN>Description" where NN is the command number (01-20)
;
; Strings:
;   01>Send Infos About HD
;   02>Exit PPORT
;   03>Read FSB from HD
;   04>Sending FSB to PC
;   05>Rcv FSB from PC
;   06>Writing FSB to HD
;   07>Load HD to Memory
;   08>Send data to PC
;   09>Sending files to PC
;   10>Rcv data from PC
;   11>Save memory to HD
;   12>nothing
;   13>Rcv data from PC
;   14>Sending infos to PC
;   15>nothing
;   16>Delete files
;   17>Formating HD
;   18>Switch HD-motor off
;   19>nothing
;   20>Send XapFile flash
;   20>End flash right.
;   20>End flash false.
;   Error : Wrong Dll Ver
; ============================================================================

HDAE5000_PPORT_Ptrs:	; 295412h
	; 3 pointers to PPORT utility routines (in code_295642_2971a2.bin)
	; ^ = entries 18-20 of HDAE5000_PPORT_CommandTable (commands 18, 19, 20)
	.long HDAE5000_PPORT_Cmd18_SwitchHdMotorOff
	.long HDAE5000_PPORT_Cmd19_Nothing
	.long HDAE5000_PPORT_Cmd20_SendXapFileFlash

; -----------------------------------------------------------------------------
; PPORT status/menu string table -- FIXED 24-BYTE RECORD STRIDE, PROVEN BY THE
; CONSUMER, not just by how the strings happen to be padded.
;
; 23 records, 0x29541E-0x29562A(+len): 20 numbered "NN>Description" command
; strings (22 chars, space-padded, .asciz -> 23B + one closing .byte 0x00 pad
; = 24B/record), 2 irregular 22-byte flash-result continuations of command 20
; ("End flash right"/"End flash false", .ascii + a literal 0x09 TAB, two
; spaces and a NUL instead of the usual pad -- same 22-char field width,
; different filler bytes), then a final 24-byte "Error : Wrong Dll Ver"
; record back on the regular pad.
;
; EVIDENCE: HDAE5000_PPORT_Cmd01_SendInfosAboutHd's PPORT command handlers load a status
; ["Cmd01..'s handlers" was "Code_2_PartB's", the name of the whole
;  conversion region: all twenty HDAE5000_PPORT_CmdNN handlers are meant]
; string via `lda_24 xbc, (0x2954xx/0x2955xx)` before every
; HDAE5000_PPORT_CallService call. There are 23 such literals in this file, one
; per record, and ALL 23 land exactly on a record start computed
; independently from these lines' own linked addresses (get_lprobe_addrs.py) --
; including both irregular 22-byte records and the trailing "Error" one.
; Reproduce: hdae5000/tools/verify_pport_strings_stride.py (23/23 PASS).
; This makes each `.byte` below a proven per-record terminator/pad, not
; unexplained filler: shortening or lengthening any string here (other than
; swapping its trailing spaces) would desync every one of those 23 call sites.
; -----------------------------------------------------------------------------
HDAE5000_PPORT_Strings:	; 29541Eh
	; PPORT command menu strings (21 null-terminated strings)
	; Format: "NN>Description" where NN = command number
	.asciz "01>Send Infos About HD"
	.byte 0x00                            ; record terminator (24B stride; see header above)
	.asciz "02>Exit PPORT         "
	.byte 0x00                            ; record terminator (24B stride; see header above)
	.asciz "03>Read FSB from HD   "
	.byte 0x00                            ; record terminator (24B stride; see header above)
	.asciz "04>Sending FSB to PC  "
	.byte 0x00                            ; record terminator (24B stride; see header above)
	.asciz "05>Rcv FSB from PC    "
	.byte 0x00                            ; record terminator (24B stride; see header above)
	.asciz "06>Writing FSB to HD  "
	.byte 0x00                            ; record terminator (24B stride; see header above)
	.asciz "07>Load HD to Memory  "
	.byte 0x00                            ; record terminator (24B stride; see header above)
	.asciz "08>Send data to PC    "
	.byte 0x00                            ; record terminator (24B stride; see header above)
	.asciz "09>Sending files to PC"
	.byte 0x00                            ; record terminator (24B stride; see header above)
	.asciz "10>Rcv data from PC   "
	.byte 0x00                            ; record terminator (24B stride; see header above)
	.asciz "11>Save memory to HD  "
	.byte 0x00                            ; record terminator (24B stride; see header above)
	.asciz "12>nothing            "
	.byte 0x00                            ; record terminator (24B stride; see header above)
	.asciz "13>Rcv data from PC   "
	.byte 0x00                            ; record terminator (24B stride; see header above)
	.asciz "14>Sending infos to PC"
	.byte 0x00                            ; record terminator (24B stride; see header above)
	.asciz "15>nothing            "
	.byte 0x00                            ; record terminator (24B stride; see header above)
	.asciz "16>Delete files       "
	.byte 0x00                            ; record terminator (24B stride; see header above)
	.asciz "17>Formating HD       "
	.byte 0x00                            ; record terminator (24B stride; see header above)
	.asciz "18>Switch HD-motor off"
	.byte 0x00                            ; record terminator (24B stride; see header above)
	.asciz "19>nothing            "
	.byte 0x00                            ; record terminator (24B stride; see header above)
	.asciz "20>Send XapFile flash "
	.byte 0x00                            ; record terminator (24B stride; see header above)
	.ascii "20>End flash right"
	.byte 0x09, 0x20, 0x20, 0x00          ; 22B record filler: TAB + 2 spaces + NUL (record start 0x2955FE is a direct call-site literal, see header above)
	.ascii "20>End flash false"
	.byte 0x09, 0x20, 0x20, 0x00          ; 22B record filler: TAB + 2 spaces + NUL (record start 0x295614 is a direct call-site literal, see header above)
	.asciz "Error : Wrong Dll Ver "
	.byte 0x00                            ; record terminator (24B stride; see header above)

; ============================================================================
; CODE SECTION 2 PART B (0x295642 - 0x2FFFFF)
; All remaining code and data including:
;   - PPORT command handler implementations (Cmd01-Cmd12)
;   - HD file management routines
;   - Check_HD_Present (0x2971A3)
;   - MemCopy utility (0x29AE9F)
;   - UI configuration data
;   - Version information (0x2999B0)
;   - German language error messages
;   - Zero padding at end (~65KB)
; ============================================================================

HDAE5000_PPORT_Cmd01_SendInfosAboutHd:	; 0x295642 (660 bytes)
	; PC-link command 01: HDAE5000_PPORT_CommandTable entry 0; first shows the
	; status record "01>Send Infos About HD" (HDAE5000_PPORT_Strings + 0, service 26).
	; The description lines below predate this name and are not re-verified.
	; PPORT command handler: initialize HD — display status, read flag bytes,
	; check compatibility, call utility with params, sum buffer
	ldw wa, 0x001A				; display command
	nop
	lda xbc, (0x29541e:24); lda XBC, 0x29541E — status string
	nop
	call HDAE5000_PPORT_CallService
	lda xix, (HDAE5000_RAM_PportPacket:24); lda XIX, 0x239168
	nop
	ld a, (xix + 1)			; read flag byte 1
	nop
	ld (0x2390f4:24), a; st (0x2390F4), A
	nop
	ld a, (xix + 2)			; read flag byte 2
	nop
	ld (0x2390f6:24), a; st (0x2390F6), A
	nop
	call HDAE5000_PPORT_ClearPacket
	ld wa, 3:i3				; display command
	ei	0
	call HDAE5000_PPORT_CallService
	ei 7
	cp wa, 0:i3				; check result
	jp z, (.Lc2b_check_compat:24)			; jp Z, 0x295684 — success path
	nop
	jp .Lc2b_do_cleanup
.Lc2b_check_compat:			; 0x295684
	ld a, (0x23a04a:24); ld A, (0x23A04A) — compatibility byte
	nop
	cp (2330868:24), a; cp (0x2390F4), A — match?
	nop
	jp z, (.Lc2b_compat_ok:24)			; jp Z, 0x2956AC — match, skip error
	nop
	ldw wa, 0x001A
	nop
	lda xbc, (0x29562a:24); lda XBC, 0x29562A — error string
	nop
	call HDAE5000_PPORT_CallService
.Lc2b_do_cleanup:			; 0x2956A4
	call HDAE5000_PPORT_FlagPacketError
	jp .Lc2b_sum_and_done
.Lc2b_compat_ok:			; 0x2956AC
	ldw bc, 0x0097				; BC param
	nop
	ldw hl, 0x00CA				; HL param
	nop
	call HDAE5000_PPORT_CopyInfoToPacket				; call 0x296AC4 — utility
.Lc2b_sum_and_done:			; 0x2956B8
	call HDAE5000_PPORT_SendPacket
	cp (HDAE5000_RAM_PportError:24), 0x01; error check
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)			; jp Z, abort
	nop
	jp HDAE5000_PPORT_CommandDone

HDAE5000_PPORT_Cmd02_ExitPport:			; 0x2956CC — command 02 "Exit PPORT" (was: Format HD command handler)
	; PC-link command 02: HDAE5000_PPORT_CommandTable entry 1; first shows the
	; status record "02>Exit PPORT" (HDAE5000_PPORT_Strings + 24, service 26).
	; The description lines below predate this name and are not re-verified.
	ei	0
	ldw wa, 0x001A
	nop
	lda xbc, (0x295436:24); lda XBC, 0x295436 — format string
	nop
	call HDAE5000_PPORT_CallService
	ld wa, 1:i3				; display command
	call HDAE5000_PPORT_CallService
	xor wa, wa				; WA = 0
	ld a, 0xFF:opc				; A = 0xFF, so WA = 0x00FF
	ld (xix), wa				; store to PPORT data
	ldw wa, 0x0012				; display command
	nop
	call HDAE5000_PPORT_CallService
	ret
	nop

HDAE5000_PPORT_Cmd03_ReadFsbFromHd:			; 0x2956F2 — command 03 "Read FSB from HD" (was: Read status command handler)
	; PC-link command 03: HDAE5000_PPORT_CommandTable entry 2; first shows the
	; status record "03>Read FSB from HD" (HDAE5000_PPORT_Strings + 48, service 26).
	; The description lines below predate this name and are not re-verified.
	ldw wa, 0x001A
	nop
	lda xbc, (0x29544e:24); lda XBC, 0x29544E — status string
	nop
	call HDAE5000_PPORT_CallService
	call HDAE5000_PPORT_ClearPacket
	ld wa, 7:i3				; display command
	ei	0
	call HDAE5000_PPORT_CallService
	ei 7
	cp wa, 0:i3
	jp z, (.Lc2b_rs_sum:24)			; jp Z, 0x29571A — skip cleanup
	nop
	call HDAE5000_PPORT_FlagPacketError
.Lc2b_rs_sum:				; 0x29571A
	call HDAE5000_PPORT_SendPacket
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
	jp HDAE5000_PPORT_CommandDone

HDAE5000_PPORT_Cmd04_SendFsbToPc:			; 0x29572E — command 04 "Sending FSB to PC" (was: Read HD sectors command handler)
	; PC-link command 04: HDAE5000_PPORT_CommandTable entry 3; first shows the
	; status record "04>Sending FSB to PC" (HDAE5000_PPORT_Strings + 72, service 26).
	; The description lines below predate this name and are not re-verified.
	; Display status, read 3 CHS parameter sets, call read function for each
	ldw wa, 0x001A
	nop
	lda xbc, (0x295466:24); lda XBC, 0x295466 — status string
	nop
	call HDAE5000_PPORT_CallService
	call HDAE5000_PPORT_ClearPacket
	ld wa, 4:i3				; display progress step 1
	ei	0
	call HDAE5000_PPORT_CallService
	ei 7
	ldw bc, 0x002C
	nop
	ldw hl, 0x0034
	nop
	call HDAE5000_PPORT_CopyInfoToPacket				; call 0x296AC4
	ld wa, 5:i3				; step 2
	ei	0
	call HDAE5000_PPORT_CallService
	ei 7
	ldw bc, 0x0034
	nop
	ldw hl, 0x003C
	nop
	call HDAE5000_PPORT_CopyInfoToPacket
	ld wa, 6:i3				; step 3
	ei	0
	call HDAE5000_PPORT_CallService
	ei 7
	ldw bc, 0x003C
	nop
	ldw hl, 0x0046
	nop
	call HDAE5000_PPORT_CopyInfoToPacket
	call HDAE5000_PPORT_SendPacket
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
	; Read 3 CHS regions from PPORT data
	lda xix, (HDAE5000_RAM_PportPacket:24); lda XIX, 0x239168
	nop
	ld bc, (xix + 0x30)			; sectors low
	nop
	ld de, (xix + 0x32)			; sectors high
	nop
	mul xde, xbc				; XDE = DE × BC (total sectors)
	ld xiy, (xix + 0x2C)			; region start
	nop
	call HDAE5000_PPORT_SendBlock				; call 0x296AF8 — read region
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
	lda xix, (HDAE5000_RAM_PportPacket:24)
	nop
	ld bc, (xix + 0x38)
	nop
	ld de, (xix + 0x3A)
	nop
	mul xde, xbc
	ld xiy, (xix + 0x34)
	nop
	call HDAE5000_PPORT_SendBlock
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
	lda xix, (HDAE5000_RAM_PportPacket:24)
	nop
	ld bc, (xix + 0x40)
	nop
	ld de, (xix + 0x42)
	nop
	mul xde, xbc
	ld xiy, (xix + 0x3C)
	nop
	call HDAE5000_PPORT_SendBlock
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
	jp HDAE5000_PPORT_CommandDone

HDAE5000_PPORT_Cmd05_RcvFsbFromPc:			; 0x295802 — command 05 "Rcv FSB from PC" (was: Write HD sectors command handler)
	; PC-link command 05: HDAE5000_PPORT_CommandTable entry 4; first shows the
	; status record "05>Rcv FSB from PC" (HDAE5000_PPORT_Strings + 96, service 26).
	; The description lines below predate this name and are not re-verified.
	; Same as read but calls write function (0x296B7E) instead
	ldw wa, 0x001A
	nop
	lda xbc, (0x29547e:24); lda XBC, 0x29547E — status string
	nop
	call HDAE5000_PPORT_CallService
	call HDAE5000_PPORT_ClearPacket
	ld wa, 4:i3
	ei	0
	call HDAE5000_PPORT_CallService
	ei 7
	ldw bc, 0x002C
	nop
	ldw hl, 0x0034
	nop
	call HDAE5000_PPORT_CopyInfoToPacket
	ld wa, 5:i3
	ei	0
	call HDAE5000_PPORT_CallService
	ei 7
	ldw bc, 0x0034
	nop
	ldw hl, 0x003C
	nop
	call HDAE5000_PPORT_CopyInfoToPacket
	ld wa, 6:i3
	ei	0
	call HDAE5000_PPORT_CallService
	ei 7
	ldw bc, 0x003C
	nop
	ldw hl, 0x0046
	nop
	call HDAE5000_PPORT_CopyInfoToPacket
	call HDAE5000_PPORT_SendPacket
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
	; Write 3 CHS regions from PPORT data
	lda xix, (HDAE5000_RAM_PportPacket:24)
	nop
	ld bc, (xix + 0x30)
	nop
	ld de, (xix + 0x32)
	nop
	mul xde, xbc
	ld xiy, (xix + 0x2C)
	nop
	call HDAE5000_PPORT_RecvBlock				; call 0x296B7E — write region
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
	lda xix, (HDAE5000_RAM_PportPacket:24)
	nop
	ld bc, (xix + 0x38)
	nop
	ld de, (xix + 0x3A)
	nop
	mul xde, xbc
	ld xiy, (xix + 0x34)
	nop
	call HDAE5000_PPORT_RecvBlock
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
	lda xix, (HDAE5000_RAM_PportPacket:24)
	nop
	ld bc, (xix + 0x40)
	nop
	ld de, (xix + 0x42)
	nop
	mul xde, xbc
	ld xiy, (xix + 0x3C)
	nop
	call HDAE5000_PPORT_RecvBlock
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
	jp HDAE5000_PPORT_CommandDone

HDAE5000_PPORT_Cmd06_WriteFsbToHd:	; 0x2958D6 (62 bytes)
	; PC-link command 06: HDAE5000_PPORT_CommandTable entry 5; first shows the
	; status record "06>Writing FSB to HD" (HDAE5000_PPORT_Strings + 120, service 26).
	; The description lines below predate this name and are not re-verified.
	; Handler: Send HD info - display status, clear buffer, check result
	ldw wa, 0x001A			; display row/column
	nop
	lda xbc, (0x295496:24); lda XBC, (0x295496) - status string
	nop
	call HDAE5000_PPORT_CallService
	call HDAE5000_PPORT_ClearPacket
	ldw wa, 0x000A			; display row/column
	nop
	ei 0x00				; enable interrupts
	call HDAE5000_PPORT_CallService
	ei 0x07				; disable interrupts
	cp wa, 0:i3			; check result
	jp z, (.LPPORT_Cmd06_WriteFsbToHd_Skip1:24)		; jp Z - skip cleanup if zero
	nop
	call HDAE5000_PPORT_FlagPacketError
.LPPORT_Cmd06_WriteFsbToHd_Skip1:
	call HDAE5000_PPORT_SendPacket
	cp (HDAE5000_RAM_PportError:24), 0x01; cp (0x2390D4), 1
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)		; jp Z - exit to PPORT finish
	nop
	jp HDAE5000_PPORT_CommandDone

HDAE5000_PPORT_Cmd07_LoadHdToMemory:	; 0x295914 (226 bytes)
	; PC-link command 07: HDAE5000_PPORT_CommandTable entry 6; first shows the
	; status record "07>Load HD to Memory" (HDAE5000_PPORT_Strings + 144, service 26).
	; The description lines below predate this name and are not re-verified.
	; Handler: Exit PPORT — display status, render, read sector/head masks,
	; AND with data bytes, write back, sum buffer, check results
	ldw wa, 0x001A				; display command
	nop
	lda xbc, (0x2954ae:24); lda XBC, 0x2954AE — status string
	nop
	call HDAE5000_PPORT_CallService
	call HDAE5000_PPORT_LatchPacketArgs
	call HDAE5000_PPORT_RequestSongInfo
	call HDAE5000_PPORT_GetInfoBlock				; call 0x296802 — register XIX
	call HDAE5000_PPORT_ClearPacket
	ld bc, 0:i3				; BC = 0
	ldw hl, 0x00C8				; HL = 200
	nop
	call HDAE5000_PPORT_CopyInfoToPacket				; call 0x296AC4 — utility
	lda xix, (HDAE5000_RAM_PportPacket:24); lda XIX, 0x239168
	nop
	ld a, (xix)				; read byte 0 from PPORT data
	ld (0x2390de:24), a; st (0x2390DE), A — save sector byte
	nop
	ld w, (0x2390da:24); ld W, (0x2390DA) — sector mask
	nop
	and w, a				; W = mask AND data
	ld (0x2390e2:24), w; st (0x2390E2), W — masked sector
	nop
	ld a, (xix + 1)			; read byte 1 from PPORT data
	nop
	ld (0x2390e0:24), a; st (0x2390E0), A — save head byte
	nop
	ld w, (0x2390dc:24); ld W, (0x2390DC) — head mask
	nop
	and w, a				; W = mask AND data
	ld (0x2390e4:24), w; st (0x2390E4), W — masked head
	nop
	ld (xix), w				; write masked head to PPORT[0]
	call HDAE5000_PPORT_SendPacket
	cp (HDAE5000_RAM_PportError:24), 0x01; cp (0x2390D4), 1 — error?
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)			; jp Z, 0x295374 — abort
	nop
	cp (0x2390e2:24), 0x00; cp (0x2390E2), 0 — masked sector=0?
	jp z, (.LPPORT_Cmd07_LoadHdToMemory_Skip1:24)			; jp Z, 0x2959F2 — skip to end
	nop
	jp .Lce_continue
.Lce_check_head:			; 0x295992
	cp (0x2390e4:24), 0x00; cp (0x2390E4), 0 — masked head=0?
	jp z, (.LPPORT_Cmd07_LoadHdToMemory_Skip1:24)			; jp Z, 0x2959F2 — skip to end
	nop
.Lce_continue:				; 0x29599E
	call HDAE5000_PPORT_ClearPacket
	ld xix, (0x239100:24); ld XIX, (0x239100) — data source ptr
	nop
	ld a, (0x2390e2:24); ld A, (0x2390E2) — masked sector
	nop
	ld (xix), a				; write sector to buffer[0]
	ld a, (0x2390e4:24); ld A, (0x2390E4) — masked head
	nop
	ld (xix + 1), a			; write head to buffer[1]
	nop
	xor xbc, xbc
	xor xde, xde
	ld c, (0x2390d6:24); ld C, (0x2390D6)
	nop
	ld e, (0x2390d8:24); ld E, (0x2390D8)
	nop
	ldw wa, 0x000E				; display command
	nop
	ei	0
	call HDAE5000_PPORT_CallService
	ei 7
	cp wa, 0:i3				; check result
	jp z, (.Lce_final_sum:24)			; jp Z, 0x2959E2 — skip cleanup
	nop
	call HDAE5000_PPORT_FlagPacketError
.Lce_final_sum:				; 0x2959E2
	call HDAE5000_PPORT_SendPacket
	cp (HDAE5000_RAM_PportError:24), 0x01; cp (0x2390D4), 1 — error?
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)			; jp Z, 0x295374 — abort
	nop
.LPPORT_Cmd07_LoadHdToMemory_Skip1:
	jp HDAE5000_PPORT_CommandDone

HDAE5000_PPORT_Cmd08_SendDataToPc:	; 0x2959F6 (838 bytes)
	; PC-link command 08: HDAE5000_PPORT_CommandTable entry 7; first shows the
	; status record "08>Send data to PC" (HDAE5000_PPORT_Strings + 168, service 26).
	; The description lines below predate this name and are not re-verified.
	; Handler: Read FSB from HD — display status, render, read sector/head masks,
	; copy 18 region descriptors from PPORT buffer, then read each flagged region
	ldw wa, 0x001A				; display command
	nop
	lda xbc, (0x2954c6:24); lda XBC, 0x2954C6 — status string
	nop
	call HDAE5000_PPORT_CallService
	call HDAE5000_PPORT_LatchPacketArgs
	call HDAE5000_PPORT_RequestSongInfo
	call HDAE5000_PPORT_GetInfoBlock				; call 0x296802 — register XIX
	call HDAE5000_PPORT_ClearPacket
	ld bc, 0:i3
	ldw hl, 0x002C
	nop
	call HDAE5000_PPORT_CopyInfoToPacket				; call 0x296AC4
	lda xix, (HDAE5000_RAM_PportPacket:24); lda XIX, 0x239168
	nop
	ld a, (xix)				; sector mask byte
	ld (0x2390de:24), a; st (0x2390DE), A
	nop
	ld w, (0x2390da:24); ld W, (0x2390DA)
	nop
	and w, a				; apply mask
	and w, 0xBF				; clear bit 6
	nop
	ld (0x2390e2:24), w; st (0x2390E2), W — masked sector
	nop
	ld a, (xix + 1)			; head mask byte
	nop
	ld (0x2390e0:24), a; st (0x2390E0), A
	nop
	ld w, (0x2390dc:24); ld W, (0x2390DC)
	nop
	and w, a
	ld (0x2390e4:24), w; st (0x2390E4), W — masked head
	nop
	ld (xix + 1), w			; write back
	nop
	call HDAE5000_PPORT_SendPacket
	cp (HDAE5000_RAM_PportError:24), 0x01; error check
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)			; jp Z, abort
	nop
	cp (0x2390e2:24), 0x00; masked sector = 0?
	jp z, (.Lrfsb_exit:24)			; jp Z, 0x295D38 — skip to end
	nop
	jp .Lrfsb_continue
.Lrfsb_check_head:			; 0x295A7A
	cp (0x2390e4:24), 0x00; masked head = 0?
	jp z, (.Lrfsb_exit:24)			; jp Z, skip to end
	nop
.Lrfsb_continue:			; 0x295A86
	ld (0x2390e6:24), 0x00; st (0x2390E6), 0 — clear error flag
	call HDAE5000_PPORT_ClearPacket
	ld xix, (0x239100:24); ld XIX, (0x239100) — data ptr
	nop
	ld a, (0x2390e2:24); ld A, (0x2390E2)
	nop
	ld (xix), a
	ld a, (0x2390e4:24); ld A, (0x2390E4)
	nop
	ld (xix + 1), a
	nop
	xor xbc, xbc
	xor xde, xde
	ld c, (0x2390d6:24)
	nop
	ld e, (0x2390d8:24)
	nop
	ldw wa, 0x000E				; display command
	nop
	ei	0
	call HDAE5000_PPORT_CallService
	ei 7
	cp wa, 0:i3
	jr z, .Lrfsb_no_error_flag
	ld (0x2390e6:24), 0x01; set error flag
.Lrfsb_no_error_flag:			; 0x295ACE
	call HDAE5000_PPORT_RequestSongInfo
	ld xix, (0x239100:24); ld XIX, (0x239100)
	nop
	; Copy 18 region descriptors from PPORT buffer to memory
	; Short displacement (8-bit signed): offsets 0x46-0x7C
	ld xwa, (xix + 0x46)
	nop
	ld (0x239108:24), xwa; st (0x239108)
	nop
	ld xwa, (xix + 0x4A)
	nop
	ld (0x23910c:24), xwa; st (0x23910C)
	nop
	ld xwa, (xix + 0x4F)
	nop
	ld (0x239110:24), xwa; st (0x239110)
	nop
	ld xwa, (xix + 0x53)
	nop
	ld (0x239114:24), xwa; st (0x239114)
	nop
	ld xwa, (xix + 0x58)
	nop
	ld (0x239118:24), xwa; st (0x239118)
	nop
	ld xwa, (xix + 0x5C)
	nop
	ld (0x23911c:24), xwa; st (0x23911C)
	nop
	ld xwa, (xix + 0x61)
	nop
	ld (0x239120:24), xwa; st (0x239120)
	nop
	ld xwa, (xix + 0x65)
	nop
	ld (0x239124:24), xwa; st (0x239124)
	nop
	ld xwa, (xix + 0x6A)
	nop
	ld (0x239128:24), xwa; st (0x239128)
	nop
	ld xwa, (xix + 0x6E)
	nop
	ld (0x23912c:24), xwa; st (0x23912C)
	nop
	ld xwa, (xix + 0x73)
	nop
	ld (0x239130:24), xwa; st (0x239130)
	nop
	ld xwa, (xix + 0x77)
	nop
	ld (0x239134:24), xwa; st (0x239134)
	nop
	ld xwa, (xix + 0x7C)
	nop
	ld (0x239138:24), xwa; st (0x239138)
	nop
	; Extended displacement (16-bit): offsets >= 0x80
	ld_sril	xwa, (xix + 0x0080)
	nop
	ld (0x23913c:24), xwa; st (0x23913C)
	nop
	ld_sril	xwa, (xix + 0x008e)
	nop
	ld (0x239144:24), xwa; st (0x239144)
	nop
	ld_sril	xwa, (xix + 0x0092)
	nop
	ld (0x239148:24), xwa; st (0x239148)
	nop
	ld_sril	xwa, (xix + 0x00bf)
	nop
	ld (0x23914c:24), xwa; st (0x23914C)
	nop
	ld_sril	xwa, (xix + 0x00c3)
	nop
	ld (0x239150:24), xwa; st (0x239150)
	nop
	; Setup for final sum/check
	call HDAE5000_PPORT_ClearPacket
	ld bc, 0:i3
	ldw hl, 0x00C8
	nop
	call HDAE5000_PPORT_CopyInfoToPacket				; call 0x296AC4
	cp (0x2390e6:24), 0x00; error flag clear?
	jr z, .Lrfsb_sum
	call HDAE5000_PPORT_FlagPacketError
.Lrfsb_sum:				; 0x295BB0
	call HDAE5000_PPORT_SendPacket
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)			; jp Z, abort
	nop
	cp (0x2390e6:24), 0x01; error flag set?
	jp z, (.Lrfsb_exit:24)			; jp Z, exit
	nop
	; Test flag bits and read corresponding regions
	; Bit 0: custom region
	ld a, (0x2390e2:24); ld A, (0x2390E2)
	nop
	and a, 0x01
	nop
	cp a, 1:i3
	jp nz, (.Lrfsb_bit1:24)			; jp NZ, skip
	nop
	call HDAE5000_PPORT_SendTwoRegions				; call 0x296CA0 — read custom region
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
.Lrfsb_bit1:				; 0x295BEE — Bit 1
	ld a, (0x2390e2:24)
	nop
	and a, 0x02
	nop
	cp a, 2:i3
	jp nz, (.Lrfsb_bit2:24)			; jp NZ, skip
	nop
	ld xiy, (0x239118:24); ld XIY, (0x239118)
	nop
	ld xde, (0x23911c:24); ld XDE, (0x23911C)
	nop
	call HDAE5000_PPORT_SendBlock				; call 0x296AF8 — read region
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
.Lrfsb_bit2:				; 0x295C1C — Bit 2
	ld a, (0x2390e2:24)
	nop
	and a, 0x04
	nop
	cp a, 4:i3
	jp nz, (.Lrfsb_bit3:24)
	nop
	ld xiy, (0x239120:24); ld XIY, (0x239120)
	nop
	ld xde, (0x239124:24); ld XDE, (0x239124)
	nop
	call HDAE5000_PPORT_SendBlock
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
.Lrfsb_bit3:				; 0x295C4A — Bit 3
	ld a, (0x2390e2:24)
	nop
	and a, 0x08
	nop
	cp a, 0x08
	nop
	jp nz, (.Lrfsb_bit4:24)
	nop
	ld xiy, (0x239128:24); ld XIY, (0x239128)
	nop
	ld xde, (0x23912c:24); ld XDE, (0x23912C)
	nop
	call HDAE5000_PPORT_SendBlock
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
.Lrfsb_bit4:				; 0x295C7A — Bit 4
	ld a, (0x2390e2:24)
	nop
	and a, 0x10
	nop
	cp a, 0x10
	nop
	jp nz, (.Lrfsb_bit5:24)
	nop
	ld xiy, (0x239130:24); ld XIY, (0x239130)
	nop
	ld xde, (0x239134:24); ld XDE, (0x239134)
	nop
	call HDAE5000_PPORT_SendBlock
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
.Lrfsb_bit5:				; 0x295CAA — Bit 5
	ld a, (0x2390e2:24)
	nop
	and a, 0x20
	nop
	cp a, 0x20
	nop
	jp nz, (.Lrfsb_bit7:24)
	nop
	ld xiy, (0x239138:24); ld XIY, (0x239138)
	nop
	ld xde, (0x23913c:24); ld XDE, (0x23913C)
	nop
	call HDAE5000_PPORT_SendBlock
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
.Lrfsb_bit7:				; 0x295CDA — Bit 7
	ld a, (0x2390e2:24)
	nop
	and a, 0x80
	nop
	cp a, 0x80
	nop
	jp nz, (.Lrfsb_flag2_bit0:24)
	nop
	ld xiy, (0x239144:24); ld XIY, (0x239144)
	nop
	ld xde, (0x239148:24); ld XDE, (0x239148)
	nop
	call HDAE5000_PPORT_SendBlock
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
.Lrfsb_flag2_bit0:			; 0x295D0A — Head flag bit 0
	ld a, (0x2390e4:24); ld A, (0x2390E4) — masked head
	nop
	and a, 0x01
	nop
	cp a, 1:i3
	jp nz, (.Lrfsb_exit:24)			; jp NZ, exit
	nop
	ld xiy, (0x23914c:24); ld XIY, (0x23914C)
	nop
	ld xde, (0x239150:24); ld XDE, (0x239150)
	nop
	call HDAE5000_PPORT_SendBlock
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
.Lrfsb_exit:				; 0x295D38
	jp HDAE5000_PPORT_CommandDone

HDAE5000_PPORT_Cmd09_SendFilesToPc:	; 0x295D3C (798 bytes)
	; PC-link command 09: HDAE5000_PPORT_CommandTable entry 8; first shows the
	; status record "09>Sending files to PC" (HDAE5000_PPORT_Strings + 192, service 26).
	; The description lines below predate this name and are not re-verified.
	; Handler: Send FSB to PC — display status, read sector/head masks,
	; build transfer buffer (masked bytes + 9 region descriptors),
	; send to PC via PPORT, then conditionally send each region
	; based on flag bits (8 bits from byte 1 + 1 bit from byte 2)
	ldw wa, 0x001A				; display command
	nop
	lda xbc, (0x2954de:24); lda XBC, 0x2954DE — status string
	nop
	call HDAE5000_PPORT_CallService
	call HDAE5000_PPORT_LatchPacketArgs
	call HDAE5000_PPORT_RequestSongInfo
	call HDAE5000_PPORT_GetInfoBlock				; call 0x296802 — register XIX
	ld xix, (0x239100:24); ld XIX, (0x239100) — data source ptr
	nop
	ld a, (xix)				; read byte 0 from data source
	ld (0x2390de:24), a; st (0x2390DE), A — save sector raw
	nop
	ld w, (0x2390da:24); ld W, (0x2390DA) — sector mask
	nop
	and w, a				; W = mask AND data
	ld (0x2390e2:24), w; st (0x2390E2), W — masked sector
	nop
	ld a, (xix + 1)			; read byte 1 from data source
	nop
	ld (0x2390e0:24), a; st (0x2390E0), A — save head raw
	nop
	ld w, (0x2390dc:24); ld W, (0x2390DC) — head mask
	nop
	and w, a				; W = mask AND data
	ld (0x2390e4:24), w; st (0x2390E4), W — masked head
	nop
	call HDAE5000_PPORT_InitRegionDescriptors				; call 0x296E08
	call HDAE5000_PPORT_RequestSongInfo
	call HDAE5000_PPORT_ClearPacket
	ld bc, 0:i3				; BC = 0 (offset)
	ldw hl, 0x002C				; HL = 44 (length)
	nop
	call HDAE5000_PPORT_CopyInfoToPacket				; call 0x296AC4 — utility
	cp (0x2390e6:24), 0x00; cp (0x2390E6), 0 — cleanup needed?
	jp z, (.Lsfsb_build_buffer:24)			; jp Z, .Lsfsb_build_buffer — skip cleanup
	nop
	call HDAE5000_PPORT_FlagPacketError
.Lsfsb_build_buffer:			; 0x295DB0 — Build transfer buffer
	lda xix, (HDAE5000_RAM_PportPacket:24); lda XIX, 0x239168
	nop
	ld a, (0x2390e2:24); ld A, (0x2390E2) — masked sector
	nop
	ld (xix), a				; store to buffer[0]
	ld a, (0x2390e4:24); ld A, (0x2390E4) — masked head
	nop
	ld (xix + 1), a			; store to buffer[1]
	nop
	add xix, 44				; advance XIX by 0x2C (44 bytes)
	; Copy 9 × 32-bit region descriptors to buffer
	ld xwa, (0x23910c:24); ld XWA, (0x23910C) — region 0
	nop
	ld (xix), xwa
	inc 4, xix
	ld xwa, (0x23911c:24); ld XWA, (0x23911C) — region 1
	nop
	ld (xix), xwa
	inc 4, xix
	ld xwa, (0x239124:24); ld XWA, (0x239124) — region 2
	nop
	ld (xix), xwa
	inc 4, xix
	ld xwa, (0x23912c:24); ld XWA, (0x23912C) — region 3
	nop
	ld (xix), xwa
	inc 4, xix
	ld xwa, (0x239134:24); ld XWA, (0x239134) — region 4
	nop
	ld (xix), xwa
	inc 4, xix
	ld xwa, (0x23913c:24); ld XWA, (0x23913C) — region 5
	nop
	ld (xix), xwa
	inc 4, xix
	ld xwa, (0x239140:24); ld XWA, (0x239140) — region 6
	nop
	ld (xix), xwa
	inc 4, xix
	ld xwa, (0x239148:24); ld XWA, (0x239148) — region 7
	nop
	ld (xix), xwa
	inc 4, xix
	ld xwa, (0x239150:24); ld XWA, (0x239150) — region 8
	nop
	ld (xix), xwa
	; Send buffer via PPORT
	call HDAE5000_PPORT_SendPacket
	cp (HDAE5000_RAM_PportError:24), 0x01; cp (0x2390D4), 1 — error?
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)			; jp Z, 0x295374 — abort
	nop
	cp (0x2390e6:24), 0x01; cp (0x2390E6), 1 — skip bit tests?
	jp z, (.Lsfsb_exit:24)			; jp Z, .Lsfsb_exit
	nop
	; Test flag byte 1 bit by bit, send corresponding region data
	; Bit 0 (0x01)
	ld a, (0x2390e2:24); ld A, (0x2390E2) — masked sector
	nop
	and a, 0x01
	nop
	cp a, 1:i3
	jp nz, (.Lsfsb_bit1:24)			; jp NZ, .Lsfsb_bit1
	nop
	ld xwa, (0x23910c:24); ld XWA, (0x23910C) — region 0
	nop
	ld (0x239164:24), xwa; st (0x239164), XWA
	nop
	ld (0x2390f0:24), 0x01; st (0x2390F0), 0x01
	ld (0x2390f2:24), 0x00; st (0x2390F2), 0x00
	call HDAE5000_PPORT_SendRegionToPc				; call 0x297054 — send region
	cp (HDAE5000_RAM_PportError:24), 0x01; error check
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)			; jp Z, abort
	nop
.Lsfsb_bit1:				; 0x295E7C — Bit 1 (0x02)
	ld a, (0x2390e2:24)
	nop
	and a, 0x02
	nop
	cp a, 2:i3
	jp nz, (.Lsfsb_bit2:24)			; jp NZ, .Lsfsb_bit2
	nop
	ld xwa, (0x23911c:24); ld XWA, (0x23911C) — region 1
	nop
	ld (0x239164:24), xwa; st (0x239164), XWA
	nop
	ld (0x2390f0:24), 0x02; st (0x2390F0), 0x02
	ld (0x2390f2:24), 0x00; st (0x2390F2), 0x00
	call HDAE5000_PPORT_SendRegionToPc
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
.Lsfsb_bit2:				; 0x295EB6 — Bit 2 (0x04)
	ld a, (0x2390e2:24)
	nop
	and a, 0x04
	nop
	cp a, 4:i3
	jp nz, (.Lsfsb_bit3:24)			; jp NZ, .Lsfsb_bit3
	nop
	ld xwa, (0x239124:24); ld XWA, (0x239124) — region 2
	nop
	ld (0x239164:24), xwa; st (0x239164), XWA
	nop
	ld (0x2390f0:24), 0x04; st (0x2390F0), 0x04
	ld (0x2390f2:24), 0x00; st (0x2390F2), 0x00
	call HDAE5000_PPORT_SendRegionToPc
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
.Lsfsb_bit3:				; 0x295EF0 — Bit 3 (0x08)
	ld a, (0x2390e2:24)
	nop
	and a, 0x08
	nop
	cp a, 0x08
	nop
	jp nz, (.Lsfsb_bit4:24)			; jp NZ, .Lsfsb_bit4
	nop
	ld xwa, (0x23912c:24); ld XWA, (0x23912C) — region 3
	nop
	ld (0x239164:24), xwa; st (0x239164), XWA
	nop
	ld (0x2390f0:24), 0x08; st (0x2390F0), 0x08
	ld (0x2390f2:24), 0x00; st (0x2390F2), 0x00
	call HDAE5000_PPORT_SendRegionToPc
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
.Lsfsb_bit4:				; 0x295F2C — Bit 4 (0x10)
	ld a, (0x2390e2:24)
	nop
	and a, 0x10
	nop
	cp a, 0x10
	nop
	jp nz, (.Lsfsb_bit5:24)			; jp NZ, .Lsfsb_bit5
	nop
	ld xwa, (0x239134:24); ld XWA, (0x239134) — region 4
	nop
	ld (0x239164:24), xwa; st (0x239164), XWA
	nop
	ld (0x2390f0:24), 0x10; st (0x2390F0), 0x10
	ld (0x2390f2:24), 0x00; st (0x2390F2), 0x00
	call HDAE5000_PPORT_SendRegionToPc
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
.Lsfsb_bit5:				; 0x295F68 — Bit 5 (0x20)
	ld a, (0x2390e2:24)
	nop
	and a, 0x20
	nop
	cp a, 0x20
	nop
	jp nz, (.Lsfsb_bit6:24)			; jp NZ, .Lsfsb_bit6
	nop
	ld xwa, (0x23913c:24); ld XWA, (0x23913C) — region 5
	nop
	ld (0x239164:24), xwa; st (0x239164), XWA
	nop
	ld (0x2390f0:24), 0x20; st (0x2390F0), 0x20
	ld (0x2390f2:24), 0x00; st (0x2390F2), 0x00
	call HDAE5000_PPORT_SendRegionToPc
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
.Lsfsb_bit6:				; 0x295FA4 — Bit 6 (0x40)
	ld a, (0x2390e2:24)
	nop
	and a, 0x40
	nop
	cp a, 0x40
	nop
	jp nz, (.Lsfsb_bit7:24)			; jp NZ, .Lsfsb_bit7
	nop
	ld xwa, (0x239140:24); ld XWA, (0x239140) — region 6
	nop
	ld (0x239164:24), xwa; st (0x239164), XWA
	nop
	ld (0x2390f0:24), 0x40; st (0x2390F0), 0x40
	ld (0x2390f2:24), 0x00; st (0x2390F2), 0x00
	call HDAE5000_PPORT_SendRegionToPc
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
.Lsfsb_bit7:				; 0x295FE0 — Bit 7 (0x80)
	ld a, (0x2390e2:24)
	nop
	and a, 0x80
	nop
	cp a, 0x80
	nop
	jp nz, (.Lsfsb_bit8:24)			; jp NZ, .Lsfsb_bit8
	nop
	ld xwa, (0x239148:24); ld XWA, (0x239148) — region 7
	nop
	ld (0x239164:24), xwa; st (0x239164), XWA
	nop
	ld (0x2390f0:24), 0x80; st (0x2390F0), 0x80
	ld (0x2390f2:24), 0x00; st (0x2390F2), 0x00
	call HDAE5000_PPORT_SendRegionToPc
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
.Lsfsb_bit8:				; 0x29601C — Flag byte 2, bit 0 (0x01)
	ld a, (0x2390e4:24); ld A, (0x2390E4) — masked head
	nop
	and a, 0x01
	nop
	cp a, 1:i3
	jp nz, (.Lsfsb_exit:24)			; jp NZ, .Lsfsb_exit
	nop
	ld xwa, (0x239150:24); ld XWA, (0x239150) — region 8
	nop
	ld (0x239164:24), xwa; st (0x239164), XWA
	nop
	ld (0x2390f0:24), 0x00; st (0x2390F0), 0x00 — byte 1 = 0
	ld (0x2390f2:24), 0x01; st (0x2390F2), 0x01 — byte 2 = 1
	call HDAE5000_PPORT_SendRegionToPc
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
.Lsfsb_exit:				; 0x296056
	jp HDAE5000_PPORT_CommandDone

HDAE5000_PPORT_Cmd10_RcvDataFromPc:	; 0x29605A (570 bytes)
	; PC-link command 10: HDAE5000_PPORT_CommandTable entry 9; first shows the
	; status record "10>Rcv data from PC" (HDAE5000_PPORT_Strings + 216, service 26).
	; The description lines below predate this name and are not re-verified.
	; Handler: Receive FSB from PC — reads command params (flag bytes +
	; 8 × 32-bit region descriptors), then conditionally writes each
	; region to HD based on flag bits
	ldw wa, 0x001A				; display command
	nop
	lda xbc, (0x2954f6:24); lda XBC, 0x2954F6 — status string
	nop
	call HDAE5000_PPORT_CallService
	lda xix, (HDAE5000_RAM_PportPacket:24); lda XIX, 0x239168
	nop
	ld a, (xix + 1)			; flag byte 1
	nop
	ld (0x2390e8:24), a; st (0x2390E8), A
	nop
	ld a, (xix + 2)			; flag byte 2
	nop
	ld (0x2390ea:24), a; st (0x2390EA), A
	nop
	; Copy 8 × 32-bit region descriptors from PPORT data to memory
	ld xwa, (xix + 3)
	nop
	ld (0x23910c:24), xwa; st (0x23910C), XWA
	nop
	ld xwa, (xix + 7)
	nop
	ld (0x23911c:24), xwa; st (0x23911C), XWA
	nop
	ld xwa, (xix + 0x0B)
	nop
	ld (0x239124:24), xwa; st (0x239124), XWA
	nop
	ld xwa, (xix + 0x0F)
	nop
	ld (0x23912c:24), xwa; st (0x23912C), XWA
	nop
	ld xwa, (xix + 0x13)
	nop
	ld (0x239134:24), xwa; st (0x239134), XWA
	nop
	ld xwa, (xix + 0x17)
	nop
	ld (0x23913c:24), xwa; st (0x23913C), XWA
	nop
	ld xwa, (xix + 0x1B)
	nop
	ld (0x239148:24), xwa; st (0x239148), XWA
	nop
	ld xwa, (xix + 0x1F)
	nop
	ld (0x239150:24), xwa; st (0x239150), XWA
	nop
	ld wa, 1:i3				; display command
	ei	0
	call HDAE5000_PPORT_CallService
	ei 7
	ld (0x239100:24), xix; st (0x239100), XIX — save data ptr
	nop
	; Write saved flag bytes back to buffer
	ld a, (0x2390e8:24); ld A, (0x2390E8)
	nop
	ld (xix), a
	ld a, (0x2390ea:24); ld A, (0x2390EA)
	nop
	ld (xix + 1), a
	nop
	ldw wa, 0x0014				; display progress command
	nop
	ei	0
	call HDAE5000_PPORT_CallService
	ei 7
	; Test flag byte 1 bit by bit, write corresponding region to HD
	; Bit 0: custom region
	ld a, (0x2390e8:24); ld A, (0x2390E8)
	nop
	and a, 0x01
	nop
	cp a, 1:i3
	jp nz, (.Lrcv_bit1:24)			; jp NZ, skip bit 0
	nop
	call HDAE5000_PPORT_RecvCustomData				; call 0x296D54 — write custom region
	cp (HDAE5000_RAM_PportError:24), 0x01; error check
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)			; jp Z, abort
	nop
.Lrcv_bit1:				; 0x296122 — Bit 1
	ld a, (0x2390e8:24)
	nop
	and a, 0x02
	nop
	cp a, 2:i3
	jp nz, (.Lrcv_bit2:24)			; jp NZ, skip
	nop
	ld xiy, 0x001ED350			; region size
	nop
	ld xde, (0x23911c:24); ld XDE, (0x23911C) — sector count
	nop
	call HDAE5000_PPORT_RecvBlock				; call 0x296B7E — write region
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
.Lrcv_bit2:				; 0x296150 — Bit 2
	ld a, (0x2390e8:24)
	nop
	and a, 0x04
	nop
	cp a, 4:i3
	jp nz, (.Lrcv_bit3:24)			; jp NZ, skip
	nop
	ld xiy, 0x000AB000
	nop
	ld xde, (0x239124:24); ld XDE, (0x239124)
	nop
	call HDAE5000_PPORT_RecvBlock
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
.Lrcv_bit3:				; 0x29617E — Bit 3
	ld a, (0x2390e8:24)
	nop
	and a, 0x08
	nop
	cp a, 0x08
	nop
	jp nz, (.Lrcv_bit4:24)			; jp NZ, skip
	nop
	ld xiy, 0x00094800
	nop
	ld xde, (0x23912c:24); ld XDE, (0x23912C)
	nop
	call HDAE5000_PPORT_RecvBlock
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
.Lrcv_bit4:				; 0x2961AE — Bit 4
	ld a, (0x2390e8:24)
	nop
	and a, 0x10
	nop
	cp a, 0x10
	nop
	jp nz, (.Lrcv_bit5:24)			; jp NZ, skip
	nop
	ld xiy, 0x001E0000
	nop
	ld xde, (0x239134:24); ld XDE, (0x239134)
	nop
	call HDAE5000_PPORT_RecvBlock
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
.Lrcv_bit5:				; 0x2961DE — Bit 5
	ld a, (0x2390e8:24)
	nop
	and a, 0x20
	nop
	cp a, 0x20
	nop
	jp nz, (.Lrcv_bit7:24)			; jp NZ, skip
	nop
	ld xiy, 0x001E8800
	nop
	ld xde, (0x23913c:24); ld XDE, (0x23913C)
	nop
	call HDAE5000_PPORT_RecvBlock
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
.Lrcv_bit7:				; 0x29620E — Bit 7
	ld a, (0x2390e8:24)
	nop
	and a, 0x80
	nop
	cp a, 0x80
	nop
	jp nz, (.Lrcv_flag2_bit0:24)			; jp NZ, skip
	nop
	ld xiy, 0x003D3000
	nop
	ld xde, (0x239148:24); ld XDE, (0x239148)
	nop
	call HDAE5000_PPORT_RecvBlock
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
.Lrcv_flag2_bit0:			; 0x29623E — Flag byte 2, bit 0
	ld a, (0x2390ea:24); ld A, (0x2390EA)
	nop
	and a, 0x01
	nop
	cp a, 1:i3
	jp nz, (.Lrcv_finish:24)			; jp NZ, skip
	nop
	ld xiy, HDAE5000_RAM_LyricBuffer
	nop
	ld xde, (0x239150:24); ld XDE, (0x239150)
	nop
	call HDAE5000_PPORT_RecvBlock
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)
	nop
.Lrcv_finish:				; 0x29626C
	; Restore XIX, write flag bytes back, display final status
	ld xix, (0x239100:24); ld XIX, (0x239100)
	nop
	ld a, (0x2390e8:24); ld A, (0x2390E8)
	nop
	ld (xix), a
	ld a, (0x2390ea:24); ld A, (0x2390EA)
	nop
	ld (xix + 1), a
	nop
	ldw wa, 0x0010				; display final command
	nop
	ei	0
	call HDAE5000_PPORT_CallService
	ei 7
	jp HDAE5000_PPORT_CommandDone

HDAE5000_PPORT_Cmd11_SaveMemoryToHd:	; 0x296294 (150 bytes)
	; PC-link command 11: HDAE5000_PPORT_CommandTable entry 10; first shows the
	; status record "11>Save memory to HD" (HDAE5000_PPORT_Strings + 240, service 26).
	; The description lines below predate this name and are not re-verified.
	; Handler: Write FSB (File System Block) to HD
	; Displays "Write FSB" status, calls render, copies PPORT data to XIX buffer,
	; loads sector/head params, calls Display_String with result, sums and cleans up.
	ldw wa, 0x001A			; display row/column
	nop
	lda xbc, (0x29550e:24); 0x29550E - "Write FSB" string
	nop
	call HDAE5000_PPORT_CallService
	call HDAE5000_PPORT_LatchPacketArgs
	ld wa, 1:i3			; WA = 1
	ei 0x00				; IFF=0: accepts every interrupt level (06 00; was mis-spelled `di`)
	call HDAE5000_PPORT_CallService
	ei 0x07				; IFF=7: masks every maskable level -- this IS the real DI (06 07)
	xor wa, wa			; WA = 0
	ld a, (0x2390da:24); A = [0x2390DA] (FSB byte 0)
	nop
	ld (xix), a			; store to buffer[0]
	ld a, (0x2390dc:24); A = [0x2390DC] (FSB byte 1)
	nop
	ld (xix + 1), a			; store to buffer[1]
	nop
	add xix, 0x00000002		; advance buffer pointer past header
	ld bc, 0:i3			; BC = 0 (loop counter)
	lda xiy, (HDAE5000_RAM_PportPacket:24); XIY = 0x239168 (PPORT command area)
	nop
	add xiy, 0x00000005		; skip 5-byte header
.Lwfsb_copy_loop:
	cp bc, 0x001A			; copied 26 bytes?
	jr z, .Lwfsb_done_copy		; yes, done
	ldb_sri a, 0x07, 0xF4, 0xE4	; A = (XIY + BC) — read from PPORT data
	nop
	stb_dri a, 0x07, 0xF0, 0xE4	; (XIX + BC) = A — write to buffer
	nop
	inc 1, bc			; BC++
	jr t, .Lwfsb_copy_loop		; always loop
.Lwfsb_done_copy:
	xor xbc, xbc			; XBC = 0
	xor xde, xde			; XDE = 0
	ld c, (0x2390d6:24); C = [0x2390D6] (sector)
	nop
	ld e, (0x2390d8:24); E = [0x2390D8] (head)
	nop
	ldw wa, 0x000F			; WA = 0x0F (command code)
	nop
	ei 0x00				; IFF=0: accepts every interrupt level (06 00; was mis-spelled `di`)
	call HDAE5000_PPORT_CallService
	ei 0x07				; IFF=7: masks every maskable level -- this IS the real DI (06 07)
	cp wa, 0:i3			; result == 0?
	jp z, (.Lwfsb_after_error:24)		; jp Z, skip error handling (0x296316)
	nop
	call HDAE5000_PPORT_FlagPacketError
.Lwfsb_after_error:			; 0x296316
	call HDAE5000_PPORT_SendPacket
	cp (HDAE5000_RAM_PportError:24), 0x01; [0x2390D4] == 1? (status check)
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)		; jp Z, exit to PPORT finish (0x295374)
	nop
	jp HDAE5000_PPORT_CommandDone

HDAE5000_PPORT_Cmd12_Nothing:	; 0x29632A
	; PC-link command 12: HDAE5000_PPORT_CommandTable entry 11; first shows the
	; status record "12>nothing" (HDAE5000_PPORT_Strings + 264, service 26).
	; The description lines below predate this name and are not re-verified.
	; Load HD to memory - display status and finish
	ldw wa, 0x001A			; display row/column
	nop
	lda xbc, (0x295526:24); 0x295526 - "Load HD" string
	nop
	call HDAE5000_PPORT_CallService
	jp HDAE5000_PPORT_CommandDone

HDAE5000_PPORT_Cmd13_RcvDataFromPc:	; 0x29633C (362 bytes)
	; PC-link command 13: HDAE5000_PPORT_CommandTable entry 12; first shows the
	; status record "13>Rcv data from PC" (HDAE5000_PPORT_Strings + 288, service 26).
	; The description lines below predate this name and are not re-verified.
	; Send data block to PC — display status, render, build transfer buffer
	; from PPORT data, then loop sending 512-byte sectors until count exhausted
	ldw wa, 0x001A				; display command
	nop
	lda xbc, (0x29553e:24); lda XBC, 0x29553E — status string
	nop
	call HDAE5000_PPORT_CallService
	call HDAE5000_PPORT_LatchPacketArgs
	lda xix, (HDAE5000_RAM_PportPacket:24); lda XIX, 0x239168
	nop
	add xix, 0x00000005			; advance to data offset +5
	ld xwa, (xix)				; read 32-bit sector count
	ld (0x239154:24), xwa; st (0x239154), XWA — save count
	nop
	ld wa, 1:i3				; WA = 1 (display command)
	ei	0
	call HDAE5000_PPORT_CallService
	ei 7
	xor wa, wa				; clear WA
	ld a, (0x2390da:24); ld A, (0x2390DA) — sector mask
	nop
	ld (xix), a				; store to buffer
	ld a, (0x2390dc:24); ld A, (0x2390DC) — head mask
	nop
	ld (xix + 1), a			; store to buffer+1
	nop
	add xix, 0x00000002			; advance past sector/head bytes
	ld bc, 0:i3				; counter = 0
	lda xiy, (HDAE5000_RAM_PportPacket:24); lda XIY, 0x239168
	nop
	add xiy, 0x00000009			; XIY points to source data offset +9
.Lsdb_copy_loop:			; 0x296394 — copy 26 bytes from XIY+BC to XIX+BC
	cp bc, 0x001A				; 26 bytes?
	jr z, .Lsdb_copy_done			; exit loop
	ldb_sri a, 0x07, 0xF4, 0xE4		; ld A, (XIY+BC) — source byte
	nop
	stb_dri a, 0x07, 0xF0, 0xE4		; ld (XIX+BC), A — store to dest
	nop
	inc 1, bc
	jr t, .Lsdb_copy_loop
.Lsdb_copy_done:			; 0x2963AA
	ld (0x2390e6:24), 0x00; st (0x2390E6), 0 — clear error flag
	xor xbc, xbc
	xor xde, xde
	ld c, (0x2390d6:24); ld C, (0x2390D6)
	nop
	ld e, (0x2390d8:24); ld E, (0x2390D8)
	nop
	ldw wa, 0x0015				; display command
	nop
	ei	0
	call HDAE5000_PPORT_CallService
	ei 7
	cp wa, 0:i3				; check display result
	jp z, (.Lsdb_send_header:24)			; jp Z, 0x2963DE — skip error setup
	nop
	ldw wa, 0xFF00				; error indicator
	nop
	ld (0x2390e6:24), 0x01; st (0x2390E6), 1 — set error flag
.Lsdb_send_header:			; 0x2963DE
	call HDAE5000_PPORT_SendByte			; send header byte via PPORT
	cp (HDAE5000_RAM_PportError:24), 0x01; error check
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)			; jp Z, abort
	nop
	cp (0x2390e6:24), 0x01; cp (0x2390E6), 1 — error flag set?
	jp z, (.LPPORT_Cmd13_RcvDataFromPc_Skip1:24)			; jp Z, 0x2964A2 — exit
	nop
.Lsdb_sector_loop:			; 0x2963FA — main sector send loop
	ld xwa, (0x239154:24); ld XWA, (0x239154) — remaining count
	nop
	cp xwa, 0x00000000			; all done?
	jp z, (.Lsdb_send_final:24)			; jp Z, 0x29647A — send final status
	nop
	call HDAE5000_PPORT_RecvSector				; call 0x296C2A — read sector from HD
	cp (HDAE5000_RAM_PportError:24), 0x01; error check
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)			; jp Z, abort
	nop
	ld (0x2390e6:24), 0x00; clear error flag
	lda xbc, (0x239268:24); lda XBC, 0x239268 — sector data buffer
	nop
	ld xde, 0x00000200			; 512 bytes
	nop
	ldw wa, 0x0017				; display command (send data)
	nop
	ei	0
	call HDAE5000_PPORT_CallService
	ei 7
	cp wa, 0:i3				; check result
	jp z, (.Lsdb_send_sector:24)			; jp Z, 0x29644C — skip error
	nop
	ldw wa, 0xFF00				; error indicator
	nop
	ld (0x2390e6:24), 0x01; set error flag
.Lsdb_send_sector:			; 0x29644C
	call HDAE5000_PPORT_SendByte			; send byte
	cp (HDAE5000_RAM_PportError:24), 0x01; error check
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)			; jp Z, abort
	nop
	cp (0x2390e6:24), 0x01; error flag?
	jp z, (.LPPORT_Cmd13_RcvDataFromPc_Skip1:24)			; jp Z, exit
	nop
	ld xwa, (0x239154:24); reload count
	nop
	dec 1, xwa				; decrement sector count
	ld (0x239154:24), xwa; store back
	nop
	jp .Lsdb_sector_loop			; next sector
.Lsdb_send_final:			; 0x29647A — send final status byte
	ldw wa, 0x0016				; display command (final)
	nop
	ei	0
	call HDAE5000_PPORT_CallService
	ei 7
	cp wa, 0:i3
	jp z, (.Lsdb_send_final2:24)			; jp Z, 0x296492 — skip error
	nop
	ldw wa, 0xFF00				; error indicator
	nop
.Lsdb_send_final2:			; 0x296492
	call HDAE5000_PPORT_SendByte			; send final byte
	cp (HDAE5000_RAM_PportError:24), 0x01; error check
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)			; jp Z, abort
	nop
.LPPORT_Cmd13_RcvDataFromPc_Skip1:
	jp HDAE5000_PPORT_CommandDone

HDAE5000_PPORT_Cmd14_SendInfosToPc:	; 0x2964A6 (226 bytes)
	; PC-link command 14: HDAE5000_PPORT_CommandTable entry 13; first shows the
	; status record "14>Sending infos to PC" (HDAE5000_PPORT_Strings + 312, service 26).
	; The description lines below predate this name and are not re-verified.
	; Send file list to PC - displays status, builds transfer buffer
	; with disk info from 0x23910C-0x239150, then sends via PPORT.
	ldw wa, 0x001A			; display row/column
	nop
	lda xbc, (0x295556:24); 0x295556 - "Send File List" string
	nop
	call HDAE5000_PPORT_CallService
	call HDAE5000_PPORT_LatchPacketArgs
	call HDAE5000_PPORT_RequestSongInfo
	call HDAE5000_PPORT_GetInfoBlock			; call 0x296802 (prepare file list)
	ld xix, (0x239100:24); XIX = [0x239100] (data source ptr)
	nop
	ld a, (xix)			; A = first byte
	ld (0x2390e2:24), a; [0x2390E2] = first byte
	nop
	ld a, (xix + 1)			; A = second byte
	nop
	ld (0x2390e4:24), a; [0x2390E4] = second byte
	nop
	call HDAE5000_PPORT_InitRegionDescriptors			; call 0x296E08 (process file list)
	call HDAE5000_PPORT_RequestSongInfo
	call HDAE5000_PPORT_ClearPacket
	ld bc, 0:i3			; BC = 0 (offset)
	ldw hl, 0x002C			; HL = 44 (block size)
	nop
	call HDAE5000_PPORT_CopyInfoToPacket			; call 0x296AC4 (transfer setup)
	cp (0x2390e6:24), 0x00; [0x2390E6] == 0? (error check)
	jp z, (.Lsfl_build_buffer:24)		; jp Z, skip cleanup (0x2964FE)
	nop
	call HDAE5000_PPORT_FlagPacketError
.Lsfl_build_buffer:			; 0x2964FE
	lda xix, (HDAE5000_RAM_PportPacket:24); XIX = 0x239168 (PPORT cmd area)
	nop
	ld a, (0x2390e2:24); A = [0x2390E2]
	nop
	ld (xix), a			; store to cmd[0]
	ld a, (0x2390e4:24); A = [0x2390E4]
	nop
	ld (xix + 1), a			; store to cmd[1]
	nop
	add xix, 0x0000002C		; advance past header (44 bytes)
	; Copy 9 disk info fields (32-bit each) from 0x23910C-0x239150
	ld xwa, (0x23910c:24); [0x23910C]
	nop
	ld (xix), xwa
	inc 4, xix
	ld xwa, (0x23911c:24); [0x23911C]
	nop
	ld (xix), xwa
	inc 4, xix
	ld xwa, (0x239124:24); [0x239124]
	nop
	ld (xix), xwa
	inc 4, xix
	ld xwa, (0x23912c:24); [0x23912C]
	nop
	ld (xix), xwa
	inc 4, xix
	ld xwa, (0x239134:24); [0x239134]
	nop
	ld (xix), xwa
	inc 4, xix
	ld xwa, (0x23913c:24); [0x23913C]
	nop
	ld (xix), xwa
	inc 4, xix
	ld xwa, (0x239140:24); [0x239140]
	nop
	ld (xix), xwa
	inc 4, xix
	ld xwa, (0x239148:24); [0x239148]
	nop
	ld (xix), xwa
	inc 4, xix
	ld xwa, (0x239150:24); [0x239150]
	nop
	ld (xix), xwa
	call HDAE5000_PPORT_SendPacket
	cp (HDAE5000_RAM_PportError:24), 0x01; [0x2390D4] == 1? (status check)
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)		; jp Z, exit to PPORT finish (0x295374)
	nop
	jp HDAE5000_PPORT_CommandDone

HDAE5000_PPORT_Cmd15_Nothing:	; 0x296588
	; PC-link command 15: HDAE5000_PPORT_CommandTable entry 14; first shows the
	; status record "15>nothing" (HDAE5000_PPORT_Strings + 336, service 26).
	; The description lines below predate this name and are not re-verified.
	; Receive data from PC - display status and finish
	ldw wa, 0x001A			; display row/column
	nop
	lda xbc, (0x29556e:24); 0x29556E - "Receive Data" string
	nop
	call HDAE5000_PPORT_CallService
	jp HDAE5000_PPORT_CommandDone

HDAE5000_PPORT_Cmd16_DeleteFiles:	; 0x29659A (230 bytes)
	; PC-link command 16: HDAE5000_PPORT_CommandTable entry 15; first shows the
	; status record "16>Delete files" (HDAE5000_PPORT_Strings + 360, service 26).
	; The description lines below predate this name and are not re-verified.
	; Save memory to HD with sector/head masking and multi-step transfer.
	ldw wa, 0x001A			; display row/column
	nop
	lda xbc, (0x295586:24); 0x295586 - "Write Memory" string
	nop
	call HDAE5000_PPORT_CallService
	call HDAE5000_PPORT_LatchPacketArgs
	call HDAE5000_PPORT_RequestSongInfo
	call HDAE5000_PPORT_GetInfoBlock			; call 0x296802 (prepare data)
	call HDAE5000_PPORT_ClearPacket
	ld bc, 0:i3			; BC = 0
	ldw hl, 0x00C8			; HL = 200 (block size)
	nop
	call HDAE5000_PPORT_CopyInfoToPacket			; call 0x296AC4 (transfer setup)
	lda xix, (HDAE5000_RAM_PportPacket:24); XIX = 0x239168 (PPORT cmd area)
	nop
	ld a, (xix)			; A = cmd[0]
	ld (0x2390de:24), a; [0x2390DE] = cmd[0] (raw sector byte)
	nop
	ld w, (0x2390da:24); W = [0x2390DA] (sector mask)
	nop
	and w, a			; W = cmd[0] AND sector_mask
	ld (0x2390e2:24), w; [0x2390E2] = masked sector
	nop
	ld (xix), w			; update cmd[0] with masked value
	ld a, (xix + 1)			; A = cmd[1]
	nop
	ld (0x2390e0:24), a; [0x2390E0] = cmd[1] (raw head byte)
	nop
	ld w, (0x2390dc:24); W = [0x2390DC] (head mask)
	nop
	and w, a			; W = cmd[1] AND head_mask
	ld (0x2390e4:24), w; [0x2390E4] = masked head
	nop
	ld (xix + 1), w			; update cmd[1] with masked value
	nop
	call HDAE5000_PPORT_SendPacket
	cp (HDAE5000_RAM_PportError:24), 0x01; [0x2390D4] == 1? (status check)
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)		; jp Z → exit to PPORT finish (0x295374)
	nop
	cp (0x2390e2:24), 0x00; masked sector == 0?
	jp z, (.Lwmhd_check_head:24)		; jp Z → check head (0x29661C)
	nop
	jp .Lwmhd_do_write			; jp → do write (0x296628)
.Lwmhd_check_head:			; 0x29661C
	cp (0x2390e4:24), 0x00; masked head == 0?
	jp z, (.Lwmhd_done:24)		; jp Z → done (0x29667C)
	nop
.Lwmhd_do_write:			; 0x296628
	call HDAE5000_PPORT_ClearPacket
	ld xix, (0x239100:24); XIX = [0x239100] (data source ptr)
	nop
	ld a, (0x2390e2:24); A = masked sector
	nop
	ld (xix), a			; store to data[0]
	ld a, (0x2390e4:24); A = masked head
	nop
	ld (xix + 1), a			; store to data[1]
	nop
	xor xbc, xbc			; XBC = 0
	xor xde, xde			; XDE = 0
	ld c, (0x2390d6:24); C = [0x2390D6] (sector param)
	nop
	ld e, (0x2390d8:24); E = [0x2390D8] (head param)
	nop
	ldw wa, 0x001B			; WA = 0x1B (write command)
	nop
	ei 0x00				; IFF=0: accepts every interrupt level (06 00; was mis-spelled `di`)
	call HDAE5000_PPORT_CallService
	ei 0x07				; IFF=7: masks every maskable level -- this IS the real DI (06 07)
	cp wa, 0:i3			; result == 0?
	jp z, (.Lwmhd_after_write:24)		; jp Z → skip error (0x29666C)
	nop
	call HDAE5000_PPORT_FlagPacketError
.Lwmhd_after_write:			; 0x29666C
	call HDAE5000_PPORT_SendPacket
	cp (HDAE5000_RAM_PportError:24), 0x01; [0x2390D4] == 1?
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)		; jp Z → exit (0x295374)
	nop
.Lwmhd_done:				; 0x29667C
	jp HDAE5000_PPORT_CommandDone

HDAE5000_PPORT_Cmd17_FormatHd:	; 0x296680 (62 bytes)
	; PC-link command 17: HDAE5000_PPORT_CommandTable entry 16; first shows the
	; status record "17>Formating HD" (HDAE5000_PPORT_Strings + 384, service 26).
	; The description lines below predate this name and are not re-verified.
	; Reserved PPORT command - display status, clear buffer, check result
	ldw wa, 0x001A			; display row/column
	nop
	lda xbc, (0x29559e:24); lda XBC, (0x29559E) - status string
	nop
	call HDAE5000_PPORT_CallService
	call HDAE5000_PPORT_ClearPacket
	ldw wa, 0x0011			; display row/column
	nop
	ei 0x00				; enable interrupts
	call HDAE5000_PPORT_CallService
	ei 0x07				; disable interrupts
	cp wa, 0:i3			; check result
	jp z, (.LPPORT_Cmd17_FormatHd_Skip1:24)		; jp Z - skip cleanup if zero
	nop
	call HDAE5000_PPORT_FlagPacketError
.LPPORT_Cmd17_FormatHd_Skip1:
	call HDAE5000_PPORT_SendPacket
	cp (HDAE5000_RAM_PportError:24), 0x01; cp (0x2390D4), 1
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)		; jp Z - exit to PPORT finish
	nop
	jp HDAE5000_PPORT_CommandDone

HDAE5000_PPORT_Cmd18_SwitchHdMotorOff:	; 0x2966BE (60 bytes)
	; PC-link command 18: HDAE5000_PPORT_CommandTable entry 17; first shows the
	; status record "18>Switch HD-motor off" (HDAE5000_PPORT_Strings + 408, service 26).
	; The description lines below predate this name and are not re-verified.
	; PPORT utility - display status, clear buffer, check result
	ldw wa, 0x001A			; display row/column
	nop
	lda xbc, (0x2955b6:24); lda XBC, (0x2955B6) - status string
	nop
	call HDAE5000_PPORT_CallService
	call HDAE5000_PPORT_ClearPacket
	ld wa, 2:i3			; WA = 2
	ei 0x00				; enable interrupts
	call HDAE5000_PPORT_CallService
	ei 0x07				; disable interrupts
	cp wa, 0:i3			; check result
	jp z, (.LPPORT_Cmd18_SwitchHdMotorOff_Skip1:24)		; jp Z - skip cleanup if zero
	nop
	call HDAE5000_PPORT_FlagPacketError
.LPPORT_Cmd18_SwitchHdMotorOff_Skip1:
	call HDAE5000_PPORT_SendPacket
	cp (HDAE5000_RAM_PportError:24), 0x01; cp (0x2390D4), 1
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)		; jp Z - exit to PPORT finish
	nop
	jp HDAE5000_PPORT_CommandDone

HDAE5000_PPORT_Cmd19_Nothing:	; 0x2966FA
	; PC-link command 19: HDAE5000_PPORT_CommandTable entry 18; first shows the
	; status record "19>nothing" (HDAE5000_PPORT_Strings + 432, service 26).
	; The description lines below predate this name and are not re-verified.
	; PPORT utility routine 2 - display status and finish
	ldw wa, 0x001A			; display row/column
	nop
	lda xbc, (0x2955ce:24); 0x2955CE - status string
	nop
	call HDAE5000_PPORT_CallService
	jp HDAE5000_PPORT_CommandDone

HDAE5000_PPORT_Cmd20_SendXapFileFlash:	; 0x29670C (164 bytes)
	; PC-link command 20: HDAE5000_PPORT_CommandTable entry 19; first shows the
	; status record "20>Send XapFile flash" (HDAE5000_PPORT_Strings + 456, service 26).
	; The description lines below predate this name and are not re-verified.
	; PPORT utility routine 3 — display string, read PPORT data, execute,
	; check status, display result string (success or error)
	ldw wa, 0x001A				; display command
	nop
	lda xbc, (0x2955e6:24); lda XBC, 0x2955E6 — string pointer
	nop
	call HDAE5000_PPORT_CallService
	ld xbc, 0:i3
	ld xde, 0:i3
	ldw wa, 0x001D				; display command
	nop
	call HDAE5000_PPORT_CallService
	ei 7					; IFF=7: masks every maskable level -- this IS the real DI (06 07)
	lda xix, (HDAE5000_RAM_PportPacket:24); lda XIX, 0x239168 — PPORT command area
	nop
	ld xwa, (xix + 2)			; read 32-bit parameter
	nop
	ld (0x239104:24), xwa; st (0x239104), XWA — store parameter
	nop
	ld xiy, 0x00010000			; block size 64KB
	nop
	ld xde, (0x239104:24); ld XDE, (0x239104)
	nop
	call HDAE5000_PPORT_RecvBlock				; call 0x296B7E — execute operation
	cp (HDAE5000_RAM_PportError:24), 0x01; cp (0x2390D4), 1 — check status flag
	jp z, (HDAE5000_PPORT_CommandLoop_Poll:24)			; jp Z, 0x295374 — abort if status=1
	nop
	ld xbc, 0x00010000			; block size
	nop
	ld xde, 0x00239104			; data address (immediate)
	nop
	ldw wa, 0x001C				; display command
	nop
	call HDAE5000_PPORT_CallService
	ld (0x2390fa:24), wa; st (0x2390FA), WA — save result
	nop
	ei	0					; IFF=0: accepts every interrupt level (06 00; was mis-spelled `di`)
	ld xbc, 0:i3
	ld xde, 0:i3
	ldw wa, 0x001E				; display command
	nop
	call HDAE5000_PPORT_CallService
	ld wa, (0x2390fa:24); ld WA, (0x2390FA) — reload result
	nop
	cp wa, 0x0058				; check result value
	jp z, (.Lpu3_success:24)			; jp Z, 0x29679E — jump if success
	nop
	; Error path
	ldw wa, 0x001A				; display command
	nop
	lda xbc, (0x295614:24); lda XBC, 0x295614 — error string
	nop
	call HDAE5000_PPORT_CallService
	jp HDAE5000_PPORT_CommandDone
.Lpu3_success:
	; Success path
	ldw wa, 0x001A				; display command
	nop
	lda xbc, (0x2955fe:24); lda XBC, 0x2955FE — success string
	nop
	call HDAE5000_PPORT_CallService
	jp HDAE5000_PPORT_CommandDone

HDAE5000_PPORT_CommandDone:	; 0x2967B0 (4 bytes)
	; PPORT command completion - jump to finish handler
	jp HDAE5000_PPORT_CommandLoop_Poll

HDAE5000_PPORT_LatchPacketArgs:	; 0x2967B4 (48 bytes)
	; Copy 4 display region parameters from (XIX+1..4) to direct memory
	; ^ i.e. latch bytes 1..4 of the link packet 0x239168 (the command's
	;   arguments) into 0x2390D6/D8/DA/DC; nothing is displayed.
	lda xix, (HDAE5000_RAM_PportPacket:24); lda XIX, (0x239168)
	nop
	ld a, (xix + 1)
	nop
	ld (0x2390d6:24), a; st (0x2390D6), A
	nop
	ld a, (xix + 2)
	nop
	ld (0x2390d8:24), a; st (0x2390D8), A
	nop
	ld a, (xix + 3)
	nop
	ld (0x2390da:24), a; st (0x2390DA), A
	nop
	ld a, (xix + 4)
	nop
	ld (0x2390dc:24), a; st (0x2390DC), A
	nop
	ret
	nop

HDAE5000_PPORT_RequestSongInfo:	; 0x2967E4 (166 bytes)
	; Display region rendering 2 — load display params and call Display_String
	; ^ corrected: PC-link service 13 (SendInfosAboutSong) with C = 0x2390D6
	;   and E = 0x2390D8, the first two latched packet arguments;
	;   "Display_String" was the old name of HDAE5000_PPORT_CallService.
	xor xbc, xbc				; clear XBC
	xor xde, xde				; clear XDE
	ld c, (0x2390d6:24); ld C, (0x2390D6) — column
	nop
	ld e, (0x2390d8:24); ld E, (0x2390D8) — row
	nop
	ldw wa, 0x000D				; display command
	nop
	ei	0					; IFF=0: accepts every interrupt level (06 00; was mis-spelled `di`)
	call HDAE5000_PPORT_CallService
	ei 7					; IFF=7: masks every maskable level -- this IS the real DI (06 07)
	ret
	nop
HDAE5000_PPORT_GetInfoBlock:			; 0x296802
	; Set WA=1, call Display_String, store XIX to data source ptr
	ld wa, 1:i3
	ei	0
	call HDAE5000_PPORT_CallService
	ei 7
	ld (0x239100:24), xix; st (0x239100), XIX — data source ptr
	nop
	ret
	nop
HDAE5000_PPORT_RecvPacket:				; 0x296814
	; Buffer read loop: read 256 bytes via I/O, accumulate 32-bit checksum,
	; then send 4 checksum bytes, finalize
	xor xwa, xwa
	ld (HDAE5000_RAM_PportChecksum:24), xwa; st (0x2390FC), XWA — clear checksum
	nop
	ld bc, 0:i3				; counter = 0
	lda xix, (HDAE5000_RAM_PportPacket:24); lda XIX, 0x239168
	nop
.Lrdr2_loop1:				; 0x296824
	cp bc, 0x0100				; 256 iterations?
	jp z, (.Lrdr2_send_checksum:24)			; jp Z, 0x296852 — exit loop
	nop
	call HDAE5000_PPORT_RecvByte				; call 0x296900 — read one byte → W
	cp (HDAE5000_RAM_PportError:24), 0x01; cp (0x2390D4), 1 — error check
	jp z, (.Lrdr2_exit:24)			; jp Z, 0x296888 — exit on error
	nop
	stb_dri w, 0x07, 0xF0, 0xE4		; ld (XIX+BC), W — store byte to buffer
	nop
	xor xhl, xhl				; XHL = 0
	ld l, w					; L = W (zero-extend byte to 32-bit)
	add (HDAE5000_RAM_PportChecksum:24), xhl                ; add (0x2390FC), XHL — accumulate checksum
	nop
	inc 1, bc				; BC++
	jr t, .Lrdr2_loop1			; loop
.Lrdr2_send_checksum:			; 0x296852
	; Send 4 checksum bytes
	ld bc, 0:i3				; counter = 0
	lda xix, (HDAE5000_RAM_PportChecksum:24); lda XIX, 0x2390FC — checksum
	nop
.Lrdr2_loop2:				; 0x29685A
	cp bc, 4:i3				; 4 bytes?
	jp z, (.Lrdr2_finalize:24)			; jp Z, 0x29687C — exit loop
	nop
	ldb_sri w, 0x07, 0xF0, 0xE4		; ld W, (XIX+BC) — load checksum byte
	nop
	call HDAE5000_PPORT_SendByte				; call 0x2969A0 — send one byte
	cp (HDAE5000_RAM_PportError:24), 0x01; cp (0x2390D4), 1 — error check
	jp z, (.Lrdr2_exit:24)			; jp Z, 0x296888 — exit on error
	nop
	inc 1, bc				; BC++
	jr t, .Lrdr2_loop2			; loop
.Lrdr2_finalize:			; 0x29687C
	call HDAE5000_PPORT_EndBlock				; call 0x296A30 — finalize transfer
	cp w, 0:i3				; check result
	jr z, .Lrdr2_exit			; exit if done
	jp HDAE5000_PPORT_RecvPacket				; retry main loop
.Lrdr2_exit:				; 0x296888
	ret
	nop

HDAE5000_PPORT_SendPacket:	; 0x29688A (530 bytes)
	; Sum 256 bytes from buffer, send checksum, then send buffer bytes;
	; retry on success, return on error. Uses PPORT I/O read/write sub-routines.
	xor xwa, xwa
	ld (HDAE5000_RAM_PportChecksum:24), xwa; st (0x2390FC), XWA — clear 32-bit checksum
	nop
	ld bc, 0:i3				; counter = 0
	lda xix, (HDAE5000_RAM_PportPacket:24); lda XIX, 0x239168
	nop
.Lpsb_loop1:				; 0x29689A — send buffer bytes and accumulate checksum
	cp bc, 0x0100				; 256 iterations?
	jp z, (.Lpsb_send_checksum:24)			; jp Z, 0x2968C8 — done, send checksum
	nop
	ldb_sri w, 0x07, 0xF0, 0xE4		; ld W, (XIX+BC) — read buffer byte
	nop
	xor xhl, xhl
	ld l, w					; L = W (zero-extend to 32-bit)
	add (HDAE5000_RAM_PportChecksum:24), xhl                ; add (0x2390FC), XHL — accumulate
	nop
	call HDAE5000_PPORT_SendByte			; send byte via PPORT
	cp (HDAE5000_RAM_PportError:24), 0x01; cp (0x2390D4), 1 — error?
	jp z, (.Lpsb_exit:24)			; jp Z, 0x2968FE — exit on error
	nop
	inc 1, bc
	jr t, .Lpsb_loop1
.Lpsb_send_checksum:			; 0x2968C8
	ld bc, 0:i3
	lda xix, (HDAE5000_RAM_PportChecksum:24); lda XIX, 0x2390FC — checksum bytes
	nop
.Lpsb_loop2:				; 0x2968D0 — send 4 checksum bytes
	cp bc, 4:i3
	jp z, (.Lpsb_finalize:24)			; jp Z, 0x2968F2 — done
	nop
	ldb_sri w, 0x07, 0xF0, 0xE4		; ld W, (XIX+BC) — checksum byte
	nop
	call HDAE5000_PPORT_SendByte			; send byte
	cp (HDAE5000_RAM_PportError:24), 0x01; error check
	jp z, (.Lpsb_exit:24)			; jp Z, 0x2968FE — exit on error
	nop
	inc 1, bc
	jr t, .Lpsb_loop2
.Lpsb_finalize:				; 0x2968F2
	call HDAE5000_PPORT_EndBlock			; finalize transfer
	cp w, 0:i3				; check result
	jr z, .Lpsb_exit
	jp HDAE5000_PPORT_SendPacket		; retry
.Lpsb_exit:				; 0x2968FE
	ret
	nop
HDAE5000_PPORT_RecvByte:			; 0x296900 — Read one byte from parallel port → W
	; Handshake: wait for BUSY=1 (bit2=1), then DATA_READY (bit0=1),
	; read data, acknowledge, wait for completion
	ld a, (0x160004:24); ld A, (0x160004) — read status
	nop
	ld l, a
	and l, 0x04				; test bit 2
	nop
	cp l, 4:i3				; BUSY?
	jp nz, (.Lpsb_read_error:24)			; jp NZ, 0x296998 — error if not busy
	nop
	and a, 0x01				; test bit 0
	nop
	cp a, 1:i3				; DATA_READY?
	jp nz, (HDAE5000_PPORT_RecvByte:24)			; jp NZ, 0x296900 — retry
	nop
.Lpsb_read_phase2:			; 0x296920
	ld a, (0x160004:24); ld A, (0x160004)
	nop
	ld l, a
	and l, 0x04
	nop
	cp l, 4:i3
	jp nz, (.Lpsb_read_error:24)			; jp NZ, error
	nop
	and a, 0x02				; test bit 1
	nop
	cp a, 0:i3				; wait for bit1=0
	jp nz, (.Lpsb_read_phase2:24)			; jp NZ, 0x296920 — retry
	nop
	ld a, 0x99:opc				; command byte — request read
	ld (0x160006:24), a; st (0x160006), A — send command
	nop
	ld a, (0x160002:24); ld A, (0x160002) — control register
	nop
	and a, 0xF7				; clear bit 3
	nop
	ld (0x160002:24), a; st (0x160002), A
	nop
.Lpsb_read_phase3:			; 0x296958
	ld a, (0x160004:24); ld A, (0x160004) — status
	nop
	ld l, a
	and l, 0x04
	nop
	cp l, 4:i3
	jp nz, (.Lpsb_read_error:24)			; jp NZ, error
	nop
	and a, 0x02
	nop
	cp a, 2:i3				; wait for bit1=1
	jp nz, (.Lpsb_read_phase3:24)			; jp NZ, 0x296958 — retry
	nop
	ld w, (0x160000:24); ld W, (0x160000) — read data byte
	nop
	ld a, 0x89:opc				; acknowledge byte
	ld (0x160006:24), a; st (0x160006), A
	nop
	ld a, (0x160002:24); ld A, (0x160002)
	nop
	or a, 0x08				; set bit 3
	nop
	ld (0x160002:24), a; st (0x160002), A
	nop
	ret
	nop
.Lpsb_read_error:			; 0x296998
	ld (HDAE5000_RAM_PportError:24), 0x01; st (0x2390D4), 1 — set error flag
	ret
	nop
HDAE5000_PPORT_SendByte:			; 0x2969A0 — Write byte W to parallel port
	; Handshake: wait for BUSY=1 (bit2=1), then READY (bit0=0),
	; write data, signal, wait for ack
	ld a, (0x160004:24); ld A, (0x160004) — status
	nop
	ld l, a
	and l, 0x04
	nop
	cp l, 4:i3
	jp nz, (.Lpsb_write_error:24)			; jp NZ, 0x296A28 — error
	nop
	and a, 0x01
	nop
	cp a, 0:i3				; wait for bit0=0
	jp nz, (HDAE5000_PPORT_SendByte:24)			; jp NZ, 0x2969A0 — retry
	nop
	ld (0x160000:24), w; st (0x160000), W — write data
	nop
	ld a, (0x160002:24); ld A, (0x160002)
	nop
	and a, 0xF7				; clear bit 3
	nop
	ld (0x160002:24), a; st (0x160002), A
	nop
.Lpsb_write_phase2:			; 0x2969D6
	ld a, (0x160004:24); ld A, (0x160004)
	nop
	ld l, a
	and l, 0x04
	nop
	cp l, 4:i3
	jp nz, (.Lpsb_write_error:24)			; jp NZ, error
	nop
	and a, 0x02
	nop
	cp a, 0:i3				; wait for bit1=0
	jp nz, (.Lpsb_write_phase2:24)			; jp NZ, 0x2969D6 — retry
	nop
	ld a, (0x160002:24); ld A, (0x160002)
	nop
	or a, 0x08				; set bit 3
	nop
	ld (0x160002:24), a; st (0x160002), A
	nop
.Lpsb_write_phase3:			; 0x296A06
	ld a, (0x160004:24); ld A, (0x160004)
	nop
	ld l, a
	and l, 0x04
	nop
	cp l, 4:i3
	jp nz, (.Lpsb_write_error:24)			; jp NZ, error
	nop
	and a, 0x02
	nop
	cp a, 2:i3				; wait for bit1=1
	jp nz, (.Lpsb_write_phase3:24)			; jp NZ, 0x296A06 — retry
	nop
	ret
	nop
.Lpsb_write_error:			; 0x296A28
	ld (HDAE5000_RAM_PportError:24), 0x01; st (0x2390D4), 1 — set error flag
	ret
	nop
HDAE5000_PPORT_EndBlock:				; 0x296A30 — Finalize parallel port transfer
	; Deassert, wait for completion, read final status bit
	ld a, (0x160002:24); ld A, (0x160002)
	nop
	and a, 0xF7				; clear bit 3
	nop
	ld (0x160002:24), a; st (0x160002), A
	nop
.Lpsb_fin_wait1:			; 0x296A40
	ld a, (0x160004:24); ld A, (0x160004)
	nop
	ld l, a
	and l, 0x04
	nop
	cp l, 4:i3
	jp nz, (.Lpsb_fin_error:24)			; jp NZ, 0x296A94 — error
	nop
	and a, 0x02
	nop
	cp a, 0:i3				; wait for bit1=0
	jr nz, .Lpsb_fin_wait1			; retry
	ld w, (0x160004:24); ld W, (0x160004) — final status
	nop
	and w, 0x01				; extract bit 0 → result
	nop
	ld a, (0x160002:24); ld A, (0x160002)
	nop
	or a, 0x08				; set bit 3
	nop
	ld (0x160002:24), a; st (0x160002), A
	nop
.Lpsb_fin_wait2:			; 0x296A76
	ld a, (0x160004:24); ld A, (0x160004)
	nop
	ld l, a
	and l, 0x04
	nop
	cp l, 4:i3
	jp nz, (.Lpsb_fin_error:24)			; jp NZ, error
	nop
	and a, 0x02
	nop
	cp a, 2:i3				; wait for bit1=1
	jr nz, .Lpsb_fin_wait2			; retry
	ret
	nop
.Lpsb_fin_error:			; 0x296A94
	ld (HDAE5000_RAM_PportError:24), 0x01; st (0x2390D4), 1 — set error flag
	ret
	nop

HDAE5000_PPORT_ClearPacket:	; 0x296A9C (26 bytes)
	; Clear 256 bytes of memory at (XIX + 0..255) using register-indexed store
	lda xix, (HDAE5000_RAM_PportPacket:24); lda XIX, (0x239168)
	nop
	ld bc, 0:i3		; BC = 0 (loop counter)
.Lprc_loop:
	cp bc, 0x0100		; compare BC with 256
	jr z, .Lprc_done	; if BC == 256, done
	stib_ind 0x07, 0xF0, 0xE4, 0x00	; ld (XIX+BC), 0x00
	inc 1, bc		; BC++
	jr t, .Lprc_loop	; always loop back
.Lprc_done:
	ret
	nop

HDAE5000_PPORT_FlagPacketError:	; 0x296AB6 (1773 bytes — 10 sub-routines)
	; PPORT cleanup — mark end of buffer with 0xFF sentinel
	; ^ byte 255 of the reply packet 0x239168 = 0xFF: the handlers call it
	;   when a step fails (e.g. the version check of command 01), before
	;   HDAE5000_PPORT_SendPacket.
	lda xix, (HDAE5000_RAM_PportPacket:24); lda XIX, 0x239168
	nop
	stib_ind 0xF1, 0xFF, 0x00, 0xFF	; ld (XIX+0x00FF), 0xFF
	ret
	nop

HDAE5000_PPORT_CopyInfoToPacket:				; 0x296AC4 — Display + save XIX + copy buffer
	; Push BC/HL, display command 1, save XIX to data ptr, copy BC..HL bytes
	pushw bc
	nop
	pushw hl
	nop
	ld wa, 1:i3				; display command
	ei	0
	call HDAE5000_PPORT_CallService
	ei 7
	ld (0x239100:24), xix; st (0x239100), XIX
	nop
	popw hl
	nop
	popw bc
	nop
	lda xiy, (HDAE5000_RAM_PportPacket:24); lda XIY, 0x239168
	nop
.Lutl_copy_loop:			; 0x296AE2
	cp bc, hl
	jr z, .Lutl_ret
	ldb_sri a, 0x07, 0xF0, 0xE4		; ld A, (XIX+BC)
	nop
	stb_dri a, 0x07, 0xF4, 0xE4	; ld (XIY+BC), A
	nop
	inc 1, bc
	jr t, .Lutl_copy_loop
.Lutl_ret:				; 0x296AF6
	ret
	nop

HDAE5000_PPORT_SendBlock:			; 0x296AF8 — Send XIY bytes to PPORT with checksum
	; Send XDE bytes starting at XIY, accumulate checksum in (0x2390FC)
	; Then send 4 checksum bytes, finalize, retry on failure
	ld (0x239158:24), xiy; st (0x239158), XIY — save start
	nop
	ld (0x23915c:24), xde; st (0x23915C), XDE — save count
	nop
.Lsb_loop_start:			; 0x296B04
	xor xwa, xwa
	ld (HDAE5000_RAM_PportChecksum:24), xwa; st (0x2390FC), XWA — clear checksum
	nop
	ld xbc, 0:i3				; XBC = 0 (byte counter)
.Lsb_send_loop:			; 0x296B0E
	cp xde, xbc
	jp z, (.Lsb_checksum:24)			; jp Z, .Lsb_checksum
	nop
	ld w, (xiy)				; load byte from source
	xor xhl, xhl
	ld l, w					; XHL = byte value
	add (HDAE5000_RAM_PportChecksum), xhl			; add to checksum at (0x2390FC)
	nop
	call HDAE5000_PPORT_SendByte			; send byte via PPORT
	cp (HDAE5000_RAM_PportError:24), 0x01; error check
	jp z, (.Lsb_ret:24)			; jp Z, .Lsb_ret
	nop
	inc 1, xbc
	inc 1, xiy
	jp .Lsb_send_loop
.Lsb_checksum:				; 0x296B3A — Send 4 checksum bytes
	ld bc, 0:i3
	lda xix, (HDAE5000_RAM_PportChecksum:24); lda XIX, 0x2390FC
	nop
.Lsb_cksum_loop:			; 0x296B42
	cp bc, 4:i3
	jp z, (.Lsb_finalize:24)			; jp Z, .Lsb_finalize
	nop
	ldb_sri w, 0x07, 0xF0, 0xE4		; ld W, (XIX+BC)
	nop
	call HDAE5000_PPORT_SendByte
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (.Lsb_ret:24)			; jp Z, .Lsb_ret
	nop
	inc 1, bc
	jr t, .Lsb_cksum_loop
.Lsb_finalize:				; 0x296B64
	call HDAE5000_PPORT_EndBlock
	cp w, 0:i3
	jr z, .Lsb_ret
	ld xiy, (0x239158:24); reload XIY from (0x239158)
	nop
	ld xde, (0x23915c:24); reload XDE from (0x23915C)
	nop
	jp .Lsb_loop_start			; retry
.Lsb_ret:				; 0x296B7C
	ret
	nop

HDAE5000_PPORT_RecvBlock:		; 0x296B7E — Receive XDE bytes into XIY with checksum
	; Receive XDE bytes from PPORT into XIY buffer, accumulate checksum
	; Check status port, receive 4 checksum bytes, finalize, retry on failure
	ld (0x239158:24), xiy; st (0x239158), XIY — save start
	nop
	ld (0x23915c:24), xde; st (0x23915C), XDE — save count
	nop
.Lrb_loop_start:			; 0x296B8A
	xor xwa, xwa
	ld (HDAE5000_RAM_PportChecksum:24), xwa; st (0x2390FC), XWA — clear checksum
	nop
	ld xbc, 0:i3
.Lrb_recv_loop:			; 0x296B94
	cp xde, xbc
	jp z, (.Lrb_status_check:24)			; jp Z, .Lrb_status_check
	nop
	call HDAE5000_PPORT_RecvByte			; receive byte from PPORT
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (.Lrb_ret:24)			; jp Z, .Lrb_ret
	nop
	ld (xiy), w				; store received byte
	xor xhl, xhl
	ld l, w
	add (HDAE5000_RAM_PportChecksum), xhl			; add to checksum
	nop
	inc 1, xbc
	inc 1, xiy
	jp .Lrb_recv_loop
.Lrb_status_check:			; 0x296BC0 — Check PPORT status port
	ld a, (0x160004:24); ld A, (0x160004) — status port
	nop
	ld l, a
	and l, 0x04
	nop
	cp l, 4:i3
	jp nz, (.Lrb_set_error:24)			; jp NZ, .Lrb_set_error
	nop
	and a, 0x01
	nop
	cp a, 0:i3
	jr nz, .Lrb_status_check		; wait for ready
.Lrb_recv_cksum:			; 0x296BDC — Receive 4 checksum bytes
	ld bc, 0:i3
	lda xix, (HDAE5000_RAM_PportChecksum:24); lda XIX, 0x2390FC
	nop
.Lrb_cksum_loop:			; 0x296BE4
	cp bc, 4:i3
	jp z, (.Lrb_finalize:24)			; jp Z, .Lrb_finalize
	nop
	ldb_sri w, 0x07, 0xF0, 0xE4		; ld W, (XIX+BC)
	nop
	call HDAE5000_PPORT_SendByte
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (.Lrb_ret:24)			; jp Z, .Lrb_ret
	nop
	inc 1, bc
	jr t, .Lrb_cksum_loop
.Lrb_finalize:				; 0x296C06
	call HDAE5000_PPORT_EndBlock
	cp w, 0:i3
	jp z, (.Lrb_ret:24)			; jp Z, .Lrb_ret
	nop
	ld xiy, (0x239158:24); reload saved start
	nop
	ld xde, (0x23915c:24); reload saved count
	nop
	jp .Lrb_loop_start			; retry
.Lrb_set_error:			; 0x296C22
	ld (HDAE5000_RAM_PportError:24), 0x01; set error flag (0x2390D4)
.Lrb_ret:				; 0x296C28
	ret
	nop

HDAE5000_PPORT_RecvSector:		; 0x296C2A — Receive 512-byte sector block
	; Receive 512 bytes into sector buffer (0x239268), checksum, verify
	xor xwa, xwa
	ld (HDAE5000_RAM_PportChecksum:24), xwa; clear checksum
	nop
	ld bc, 0:i3
	lda xix, (0x239268:24); lda XIX, 0x239268
	nop
.Lrs_recv_loop:			; 0x296C3A
	cp bc, 0x0200
	jp z, (.Lrs_checksum:24)			; jp Z, .Lrs_checksum
	nop
	call HDAE5000_PPORT_RecvByte
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (.Lrs_ret:24)			; jp Z, .Lrs_ret
	nop
	stb_dri w, 0x07, 0xF0, 0xE4	; ld (XIX+BC), W
	nop
	xor xhl, xhl
	ld l, w
	add (HDAE5000_RAM_PportChecksum), xhl			; add to checksum
	nop
	inc 1, bc
	jr t, .Lrs_recv_loop
.Lrs_checksum:				; 0x296C68 — Send 4 checksum bytes
	ld bc, 0:i3
	lda xix, (HDAE5000_RAM_PportChecksum:24); lda XIX, 0x2390FC
	nop
.Lrs_cksum_loop:			; 0x296C70
	cp bc, 4:i3
	jp z, (.Lrs_finalize:24)			; jp Z, .Lrs_finalize
	nop
	ldb_sri w, 0x07, 0xF0, 0xE4		; ld W, (XIX+BC)
	nop
	call HDAE5000_PPORT_SendByte
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (.Lrs_ret:24)			; jp Z, .Lrs_ret
	nop
	inc 1, bc
	jr t, .Lrs_cksum_loop
.Lrs_finalize:				; 0x296C92
	call HDAE5000_PPORT_EndBlock
	cp w, 0:i3
	jr z, .Lrs_ret
	jp HDAE5000_PPORT_RecvSector		; retry
.Lrs_ret:				; 0x296C9E
	ret
	nop

HDAE5000_PPORT_SendTwoRegions:			; 0x296CA0 — Send two descriptor regions + checksum
	; Send from (0x239108)/XDE then (0x239110)/XDE, verify checksum
	ld xiy, (0x239108:24); ld XIY, (0x239108)
	nop
	ld xde, (0x23910c:24); ld XDE, (0x23910C)
	nop
	xor xwa, xwa
	ld (HDAE5000_RAM_PportChecksum:24), xwa; clear checksum
	nop
	ld xbc, 0:i3
.Lsr_loop1:				; 0x296CB6 — Send first region
	cp xde, xbc
	jp z, (.Lsr_region2:24)			; jp Z, .Lsr_region2
	nop
	ld w, (xiy)
	xor xhl, xhl
	ld l, w
	add (HDAE5000_RAM_PportChecksum), xhl
	nop
	call HDAE5000_PPORT_SendByte
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (.Lsr_ret:24)			; jp Z, .Lsr_ret
	nop
	inc 1, xbc
	inc 1, xiy
	jp .Lsr_loop1
.Lsr_region2:				; 0x296CE2 — Load second region
	ld xiy, (0x239110:24); ld XIY, (0x239110)
	nop
	ld xde, (0x239114:24); ld XDE, (0x239114)
	nop
	ld xbc, 0:i3
.Lsr_loop2:				; 0x296CF0 — Send second region
	cp xde, xbc
	jp z, (.Lsr_checksum:24)			; jp Z, .Lsr_checksum
	nop
	ld w, (xiy)
	xor xhl, xhl
	ld l, w
	add (HDAE5000_RAM_PportChecksum), xhl
	nop
	call HDAE5000_PPORT_SendByte
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (.Lsr_ret:24)			; jp Z, .Lsr_ret
	nop
	inc 1, xbc
	inc 1, xiy
	jp .Lsr_loop2
.Lsr_checksum:				; 0x296D1C — Send 4 checksum bytes
	ld bc, 0:i3
	lda xix, (HDAE5000_RAM_PportChecksum:24); lda XIX, 0x2390FC
	nop
.Lsr_cksum_loop:			; 0x296D24
	cp bc, 4:i3
	jp z, (.Lsr_finalize:24)			; jp Z, .Lsr_finalize
	nop
	ldb_sri w, 0x07, 0xF0, 0xE4
	nop
	call HDAE5000_PPORT_SendByte
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (.Lsr_ret:24)			; jp Z, .Lsr_ret
	nop
	inc 1, bc
	jr t, .Lsr_cksum_loop
.Lsr_finalize:				; 0x296D46
	call HDAE5000_PPORT_EndBlock
	cp w, 0:i3
	jr z, .Lsr_ret
	jp HDAE5000_PPORT_SendTwoRegions			; retry
.Lsr_ret:				; 0x296D52
	ret
	nop

HDAE5000_PPORT_RecvCustomData:		; 0x296D54 — Receive custom ROM data
	; Phase 1: receive 0x640 bytes into 0xF980
	; Phase 2: receive 0x800 bytes into 0x1E7800
	; Then send checksum, finalize, retry on failure
	ld xiy, 0x0000F980
	nop
	ld xde, 0x00000640
	nop
	xor xwa, xwa
	ld (HDAE5000_RAM_PportChecksum:24), xwa; clear checksum
	nop
	ld xbc, 0:i3
.Lrc_loop1:				; 0x296D6A — Receive phase 1
	cp xde, xbc
	jp z, (.Lrc_phase2:24)			; jp Z, .Lrc_phase2
	nop
	call HDAE5000_PPORT_RecvByte
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (.Lrc_ret:24)			; jp Z, .Lrc_ret
	nop
	ld (xiy), w
	xor xhl, xhl
	ld l, w
	add (HDAE5000_RAM_PportChecksum), xhl
	nop
	inc 1, xbc
	inc 1, xiy
	jp .Lrc_loop1
.Lrc_phase2:				; 0x296D96 — Receive phase 2
	ld xiy, 0x001E7800
	nop
	ld xde, 0x00000800
	nop
	ld xbc, 0:i3
.Lrc_loop2:				; 0x296DA4
	cp xde, xbc
	jp z, (.Lrc_checksum:24)			; jp Z, .Lrc_checksum
	nop
	call HDAE5000_PPORT_RecvByte
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (.Lrc_ret:24)			; jp Z, .Lrc_ret
	nop
	ld (xiy), w
	xor xhl, xhl
	ld l, w
	add (HDAE5000_RAM_PportChecksum), xhl
	nop
	inc 1, xbc
	inc 1, xiy
	jp .Lrc_loop2
.Lrc_checksum:				; 0x296DD0 — Send 4 checksum bytes
	ld bc, 0:i3
	lda xix, (HDAE5000_RAM_PportChecksum:24); lda XIX, 0x2390FC
	nop
.Lrc_cksum_loop:			; 0x296DD8
	cp bc, 4:i3
	jp z, (.Lrc_finalize:24)			; jp Z, .Lrc_finalize
	nop
	ldb_sri w, 0x07, 0xF0, 0xE4
	nop
	call HDAE5000_PPORT_SendByte
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (.Lrc_ret:24)			; jp Z, .Lrc_ret
	nop
	inc 1, bc
	jr t, .Lrc_cksum_loop
.Lrc_finalize:				; 0x296DFA
	call HDAE5000_PPORT_EndBlock
	cp w, 0:i3
	jr z, .Lrc_ret
	jp HDAE5000_PPORT_RecvCustomData		; retry
.Lrc_ret:				; 0x296E06
	ret
	nop

HDAE5000_PPORT_InitRegionDescriptors:	; 0x296E08 — Initialize region descriptors
	; Clear all 10 region descriptor slots to 0, then test each flag bit
	; and load the corresponding region size constant
	ld xwa, 0:i3				; XWA = 0
	ld (0x23910c:24), xwa; (0x23910C) = 0
	nop
	ld (0x239114:24), xwa; (0x239114) = 0
	nop
	ld (0x23911c:24), xwa; (0x23911C) = 0
	nop
	ld (0x239124:24), xwa; (0x239124) = 0
	nop
	ld (0x23912c:24), xwa; (0x23912C) = 0
	nop
	ld (0x239134:24), xwa; (0x239134) = 0
	nop
	ld (0x23913c:24), xwa; (0x23913C) = 0
	nop
	ld (0x239140:24), xwa; (0x239140) = 0
	nop
	ld (0x239148:24), xwa; (0x239148) = 0
	nop
	ld (0x239150:24), xwa; (0x239150) = 0
	nop
	; Bit 0: custom region size
	ld a, (0x2390e2:24); ld A, (0x2390E2) — masked sector
	nop
	and a, 0x01
	nop
	cp a, 1:i3
	jp nz, (.Lir_bit1:24)			; jp NZ, .Lir_bit1
	nop
	ld xwa, 0x00000E40
	nop
	ld (0x23910c:24), xwa; st (0x23910C), XWA
	nop
.Lir_bit1:				; 0x296E64 — Bit 1: region 1 size
	ld a, (0x2390e2:24)
	nop
	and a, 0x02
	nop
	cp a, 2:i3
	jp nz, (.Lir_bit2:24)			; jp NZ, .Lir_bit2
	nop
	ld xwa, 0x00012CB0
	nop
	ld (0x23911c:24), xwa; st (0x23911C), XWA
	nop
.Lir_bit2:				; 0x296E82 — Bit 2: compute from HD
	ld a, (0x2390e2:24)
	nop
	and a, 0x04
	nop
	cp a, 4:i3
	jp nz, (.Lir_bit3:24)			; jp NZ, .Lir_bit3
	nop
	ld e, 0x04:opc				; E = flag bit value
	ld (0x2390ee:24), 0x10; st (0x2390EE), 0x10 — sectors per track
	ld (0x2390ec:24), 0x4E; st (0x2390EC), 0x4E — sector offset
	call HDAE5000_PPORT_InitRegionDescriptors_Lookup
	cp (0x2390e6:24), 0x01; cp (0x2390E6), 1
	jp z, (.Lir_ret:24)			; jp Z, .Lir_ret
	nop
	add xiy, 0x00005000
	ld (0x239124:24), xiy; st (0x239124), XIY
	nop
.Lir_bit3:				; 0x296EBE — Bit 3: compute from HD
	ld a, (0x2390e2:24)
	nop
	and a, 0x08
	nop
	cp a, 0x08
	nop
	jp nz, (.Lir_bit4:24)			; jp NZ, .Lir_bit4
	nop
	ld e, 0x08:opc
	ld (0x2390ee:24), 0x10; sectors per track
	ld (0x2390ec:24), 0x2E; sector offset
	call HDAE5000_PPORT_InitRegionDescriptors_Lookup
	cp (0x2390e6:24), 0x01
	jp z, (.Lir_ret:24)			; jp Z, .Lir_ret
	nop
	ld (0x23912c:24), xiy; st (0x23912C), XIY
	nop
.Lir_bit4:				; 0x296EF6 — Bit 4: fixed size
	ld a, (0x2390e2:24)
	nop
	and a, 0x10
	nop
	cp a, 0x10
	nop
	jp nz, (.Lir_bit5:24)			; jp NZ, .Lir_bit5
	nop
	ld xwa, 0x000072AA
	nop
	ld (0x239134:24), xwa; st (0x239134), XWA
	nop
.Lir_bit5:				; 0x296F16 — Bit 5: compute from HD
	ld a, (0x2390e2:24)
	nop
	and a, 0x20
	nop
	cp a, 0x20
	nop
	jp nz, (.Lir_bit6:24)			; jp NZ, .Lir_bit6
	nop
	ld e, 0x20:opc
	ld (0x2390ee:24), 0x10; sectors per track
	ld (0x2390ec:24), 0x1E; sector offset
	call HDAE5000_PPORT_InitRegionDescriptors_Lookup
	cp (0x2390e6:24), 0x01
	jp z, (.Lir_ret:24)			; jp Z, .Lir_ret
	nop
	ld (0x23913c:24), xiy; st (0x23913C), XIY
	nop
.Lir_bit6:				; 0x296F4E — Bit 6: compute from HD
	ld a, (0x2390e2:24)
	nop
	and a, 0x40
	nop
	cp a, 0x40
	nop
	jp nz, (.Lir_bit7:24)			; jp NZ, .Lir_bit7
	nop
	ld e, 0x40:opc
	ld (0x2390ee:24), 0x20; sectors per track
	ld (0x2390ec:24), 0x1C; sector offset
	call HDAE5000_PPORT_InitRegionDescriptors_Lookup
	cp (0x2390e6:24), 0x01
	jp z, (.Lir_ret:24)			; jp Z, .Lir_ret
	nop
	ld (0x239140:24), xiy; st (0x239140), XIY
	nop
.Lir_bit7:				; 0x296F86 — Bit 7: fixed size
	ld a, (0x2390e2:24)
	nop
	and a, 0x80
	nop
	cp a, 0x80
	nop
	jp nz, (.Lir_flag2_bit0:24)			; jp NZ, .Lir_flag2_bit0
	nop
	ld xwa, 0x00000400
	nop
	ld (0x239148:24), xwa; st (0x239148), XWA
	nop
.Lir_flag2_bit0:			; 0x296FA6 — Flag byte 2, bit 0
	ld a, (0x2390e4:24); ld A, (0x2390E4) — masked head
	nop
	and a, 0x01
	nop
	cp a, 1:i3
	jp nz, (.Lir_ret:24)			; jp NZ, .Lir_ret
	nop
	ld xwa, 0x002304F2
	nop
	ld (0x239150:24), xwa; st (0x239150), XWA
	nop
.Lir_ret:				; 0x296FC4
	ret
	nop

HDAE5000_PPORT_InitRegionDescriptors_Lookup:		; 0x296FC6 — Compute sector descriptor
	; Read HD sector using display commands, compute XIY from sector data
	ld xix, (0x239100:24); ld XIX, (0x239100)
	nop
	ld (0x2390e6:24), 0x00; clear error flag (0x2390E6)
	xor wa, wa
	ld a, e					; A = flag bit value
	ld (xix), wa				; store to buffer
	xor xbc, xbc
	xor xde, xde
	ld c, (0x2390d6:24); ld C, (0x2390D6)
	nop
	ld e, (0x2390d8:24); ld E, (0x2390D8)
	nop
	ldw wa, 0x0018				; display command — HD read
	nop
	ei	0
	call HDAE5000_PPORT_CallService
	ei 7
	cp wa, 0:i3				; check result
	jp z, (.Lcs_read_sector:24)			; jp Z, .Lcs_read_sector
	nop
	ld (0x2390e6:24), 0x01; set error flag
	jr t, .Lcs_ret
.Lcs_read_sector:			; 0x297004
	lda xbc, (0x239268:24); lda XBC, 0x239268
	nop
	ld xde, 0x00000200			; 512 bytes
	nop
	ldw wa, 0x0019				; display command — sector read
	nop
	ei	0
	call HDAE5000_PPORT_CallService
	ei 7
	cp wa, 0:i3
	jp z, (.Lcs_process:24)			; jp Z, .Lcs_process
	nop
	ld (0x2390e6:24), 0x01; set error flag
	jr t, .Lcs_ret
.Lcs_process:				; 0x29702C — Process sector data
	xor xwa, xwa
	lda xix, (0x239268:24); lda XIX, 0x239268
	nop
	ld a, (0x2390ec:24); ld A, (0x2390EC) — sector offset
	nop
	add xix, xwa				; XIX += offset (A in low byte)
	cp (0x2390ee:24), 0x20; cp (0x2390EE), 0x20 — check sectors/track
	jr z, .Lcs_load_xiy			; if 32 sectors, load 32-bit directly
	xor xwa, xwa
	ld wa, (xix)				; load 16-bit value
	mul wa, 0x0010				; multiply by 16
	ld xiy, xwa				; XIY = result
	jr t, .Lcs_ret
.Lcs_load_xiy:				; 0x297050
	ld xiy, (xix)				; load 32-bit value directly
.Lcs_ret:				; 0x297052
	ret
	nop

HDAE5000_PPORT_SendRegionToPc:		; 0x297054 — Send region data to PC
	; Main send routine: reads region descriptor, sets up PPORT buffer,
	; sends sectors in 512-byte blocks with checksum verification
	ld xwa, (0x239164:24); ld XWA, (0x239164) — region descriptor
	nop
	ld (0x239158:24), xwa; st (0x239158), XWA — save for retry
	nop
	xor xwa, xwa
	ld (HDAE5000_RAM_PportChecksum:24), xwa; clear checksum
	nop
	ld (0x2390e6:24), 0x00; clear error flag
	call HDAE5000_PPORT_GetInfoBlock				; call 0x296802 — register XIX
	ld xix, (0x239100:24); ld XIX, (0x239100)
	nop
	xor wa, wa
	ld a, (0x2390f0:24); ld A, (0x2390F0) — flag byte 1
	nop
	ld (xix), a				; store to buffer[0]
	ld a, (0x2390f2:24); ld A, (0x2390F2) — flag byte 2
	nop
	ld (xix + 1), a			; store to buffer[1]
	nop
	xor bc, bc
	xor de, de
	ld c, (0x2390d6:24); ld C, (0x2390D6)
	nop
	ld e, (0x2390d8:24); ld E, (0x2390D8)
	nop
	ldw wa, 0x0018				; display command — HD read
	nop
	ei	0
	call HDAE5000_PPORT_CallService
	ei 7
	cp wa, 0:i3
	jp z, (.Lsrpc_send_init:24)			; jp Z, .Lsrpc_send_init
	nop
	ldw wa, 0xFF00				; error marker
	nop
	ld (0x2390e6:24), 0x01; set error flag
.Lsrpc_send_init:			; 0x2970BA — Send WA byte + start transfer
	call HDAE5000_PPORT_SendByte
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (.Lsrpc_ret:24)			; jp Z, .Lsrpc_ret
	nop
	cp (0x2390e6:24), 0x01; check error flag
	jp z, (.Lsrpc_ret:24)			; jp Z, .Lsrpc_ret
	nop
	lda xix, (0x239268:24); lda XIX, 0x239268
	nop
	ldw (0x2390f8:24), 0x0200; st (0x2390F8), 0x0200 — block size
	nop
.Lsrpc_main_loop:			; 0x2970E4 — Main send loop
	ld xwa, (0x239164:24); ld XWA, (0x239164) — remaining bytes
	nop
	cp xwa, 0				; all bytes sent?
	jp z, (.Lsrpc_final_checksum:24)			; jp Z, .Lsrpc_final_checksum
	nop
	cpw (2330872:24), 0x0200; cp (0x2390F8), 0x0200
	nop
	jr z, .Lsrpc_read_block		; if block counter = 512, read new block
	jr t, .Lsrpc_send_byte		; otherwise send next byte
.Lsrpc_read_block:			; 0x297102 — Read 512-byte block from HD
	push xix
	nop
	lda xbc, (xix)
	ld xde, 0x00000200			; 512 bytes
	nop
	ldw wa, 0x0019				; display command — sector read
	nop
	ei	0
	call HDAE5000_PPORT_CallService
	ei 7
	pop xix
	nop
	ldw (0x2390f8:24), 0x0000; reset block counter
	nop
.Lsrpc_send_byte:			; 0x297122 — Send one byte
	ld bc, (0x2390f8:24); ld BC, (0x2390F8) — block offset
	nop
	ldb_sri w, 0x07, 0xF0, 0xE4		; ld W, (XIX+BC) — load byte
	nop
	xor xhl, xhl
	ld l, w
	add (HDAE5000_RAM_PportChecksum), xhl			; add to checksum
	nop
	call HDAE5000_PPORT_SendByte
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (.Lsrpc_ret:24)			; jp Z, .Lsrpc_ret
	nop
	incw	1, (0x2390F8:24)
	nop
	ld xwa, (0x239164:24); ld XWA, (0x239164)
	nop
	dec 1, xwa
	ld (0x239164:24), xwa; st (0x239164), XWA
	nop
	jp .Lsrpc_main_loop
.Lsrpc_final_checksum:		; 0x297160 — Send 4 checksum bytes
	ld bc, 0:i3
	lda xix, (HDAE5000_RAM_PportChecksum:24); lda XIX, 0x2390FC
	nop
.Lsrpc_cksum_loop:			; 0x297168
	cp bc, 4:i3
	jp z, (.Lsrpc_finalize:24)			; jp Z, .Lsrpc_finalize
	nop
	ldb_sri w, 0x07, 0xF0, 0xE4
	nop
	call HDAE5000_PPORT_SendByte
	cp (HDAE5000_RAM_PportError:24), 0x01
	jp z, (.Lsrpc_ret:24)			; jp Z, .Lsrpc_ret
	nop
	inc 1, bc
	jr t, .Lsrpc_cksum_loop
.Lsrpc_finalize:			; 0x29718A
	call HDAE5000_PPORT_EndBlock
	cp w, 0:i3
	jr z, .Lsrpc_ret
	ld xwa, (0x239158:24); reload saved region descriptor
	nop
	ld (0x239164:24), xwa; st (0x239164), XWA
	nop
	jp HDAE5000_PPORT_SendRegionToPc		; retry
.Lsrpc_ret:				; 0x2971A2
	ret

HDAE5000_Check_HD_Present:	; 2971A3h
	; Entry wrapper for HD presence detection
	; Clears result flag, calls internal RAM test routine, returns result
	; Output: L = the HDAE5000_HD_Init error code: 0 = drive up and ready,
	;         non-zero = the step that failed (a missing drive times out in
	;         HDAE5000_ATA_WaitReady and reports 3)
	push xiz
	ld (HDAE5000_RAM_HdInitResult:24), 0x00; ld (229D92h), 0 - clear result flag
	call HDAE5000_HD_Init	; Call internal test routine
	pop xiz
	xor hl, hl	; Clear HL
	ld l, (HDAE5000_RAM_HdInitResult:24); ld L, (229D92h) - get result
	ret

; ============================================================================
; HD Detection, RAM Test, and String Formatting Library
; 0x2971B7-0x29AE9E (15,592 bytes, 11 identified routines)
;
; Contains:
;   - RAM test and verification (32KB at 0x230F1C-0x238F1C)
;   - HD initialization and drive detection (ATA IDENTIFY)
;   - CHS geometry configuration
;   - Version strings ("Technics Software section M. Kitajima", "2.33J")
;   - sprintf-like string formatting library (decimal/hex/octal conversion)
; ============================================================================

HDAE5000_HD_Init:	; 0x2971B7 (1902 bytes)
	; HD bring-up.  Each step's failure stores its code in RAM 0x229D92
	; (read back by HDAE5000_Check_HD_Present) and ends at HDAE5000_HD_Init_Fail:
	;   2  the 32 KB SRAM at 0x230F1C-0x238F1B does not hold 0x5A5A
	;   3  HDAE5000_ATA_SoftReset failed      5  HDAE5000_ATA_IdentifyDevice failed
	;   6  reading sector 1 (to 0x200628) failed
	;   1  sector 1 lacks the AA55AA55 F4F1F2F3 signature (not formatted);
	;      the free-cluster count 0x229C80 is zeroed
	;   7  HDAE5000_HD_CountFreeClusters failed
	;   8  HDAE5000_HD_ReadTables failed
	; Between those: HDAE5000_HD_ParseIdentify (via HDAE5000_ATA_IdentifyDevice's
	; data), six setting bytes copied from sector 1's image (0x2006A0) to
	; 0x229DA9..AE, blank tables (HDAE5000_HD_InitTables).  Always ends with
	; HDAE5000_ATA_Standby.  0 in 0x229D92 = drive ready and formatted.
	; RAM test: fill/verify 32KB at 0x230F1C-0x238F1C with 0x5A5A pattern
; LRT: 0x2971B7 (1902 bytes)
	; ^ region size, not routine size: the ATA primitives, geometry and
	;   table I/O routines below each carry their own label now.

	ldw	wa, 0x5a5a
	lda xiy, (HDAE5000_RAM_HdStreamBuffer:24)
HDAE5000_HD_Init_SramFillLoop:
	cp	xiy, HDAE5000_RAM_HdStreamBufferEnd
	jp	z, (.LHD_Init_SramFillLoop_Skip1:24)
	ld (xiy), wa                            ; ld (XIY),WA
	inc 2, xiy                              ; inc 2,XIY
	jp HDAE5000_HD_Init_SramFillLoop                             ; jp 0x2971bf
.LHD_Init_SramFillLoop_Skip1:
	lda xiy, (HDAE5000_RAM_HdStreamBuffer:24)
HDAE5000_HD_Init_SramVerifyLoop:
	cp	xiy, HDAE5000_RAM_HdStreamBufferEnd
	jp	z, (.LHD_Init_SramVerifyLoop_Skip2:24)
	cp	(xiy), wa
	jp	z, (.LHD_Init_SramVerifyLoop_Skip1:24)
	ld	a, 0x02:opc
	jp HDAE5000_HD_Init_Fail                             ; jp 0x29742f
.LHD_Init_SramVerifyLoop_Skip1:
	inc 2, xiy                              ; inc 2,XIY
	jp HDAE5000_HD_Init_SramVerifyLoop                             ; jp 0x2971d7
.LHD_Init_SramVerifyLoop_Skip2:
	xor	wa, wa
	lda xiy, (HDAE5000_RAM_HdStreamBuffer:24)
HDAE5000_HD_Init_SramClearLoop:
	cp	xiy, HDAE5000_RAM_HdStreamBufferEnd
	jp	z, (.LHD_Init_SramClearLoop_Skip1:24)
	ld (xiy), wa                            ; ld (XIY),WA
	inc 2, xiy                              ; inc 2,XIY
	jp HDAE5000_HD_Init_SramClearLoop                             ; jp 0x2971fc
.LHD_Init_SramClearLoop_Skip1:
	call HDAE5000_HD_ClearStatusBytes
	call HDAE5000_PPORT_InitPort
	lda xwa, (HDAE5000_HD_CheckVersionKey:24)
	ld	(0x229d6c), xwa
	ld	(0x229D90:24), 0
	ld	(HDAE5000_RAM_HdInitResult:24), 0
	ld	(HDAE5000_RAM_WriteProtect:24), 1
	ld	(HDAE5000_RAM_WriteConfirm:24), 1
	ld	(HDAE5000_RAM_QuickLoadMode:24), 1
	ld	(HDAE5000_RAM_LoadByNumberMode:24), 1
	ld	(HDAE5000_RAM_JumpAfterLoad:24), 1
	ld	(HDAE5000_RAM_LyricJump:24), 1
	ld	(HDAE5000_RAM_LyricForeColor:24), 1
	ld	(HDAE5000_RAM_LyricBackColor:24), 1
	ld	(0x229DC8:24), 0
	ld	(0x229DD9:24), 1
	ld	xwa, 0x000017a8
	ld	(0x229d78), xwa
	lda xix, (0x2013b2:24)
	ld	xbc, 0x00000186
	ld	(0x229DC2:24), 0
	ld	(0x229DC3:24), 0
	ld	(0x229DC4:24), 0
	ld	(0x229DC5:24), 0
	ld	(0x229DC6:24), 0
	ld	(0x229DC7:24), 0
HDAE5000_HD_Init_SpaceFillLoop:
	cp	xbc, 0x00000000
	jp	z, (.LHD_Init_SpaceFillLoop_Skip1:24)
	ld	(xix), 0x20
	dec	1, xbc
	inc 1, xix                              ; inc 1,XIX
	jp HDAE5000_HD_Init_SpaceFillLoop                             ; jp 0x2972a1
.LHD_Init_SpaceFillLoop_Skip1:
	ld	(0x229D9F:24), 0
	ld	(0x229DDA:24), 0
	ld	(0x229DDB:24), 0
	ld	(0x229DDC:24), 0
	ld	(0x229DDD:24), 0
	ld	(0x229DDE:24), 0
	ld	(0x229DDF:24), 0
	ld	(0x229DD6:24), 0
	ld	(0x229DA0:24), 0
	ld	(0x229E57:24), 0
	ld	(0x229E58:24), 0
	ld	(0x229E59:24), 0
	ld	(0x229E5A:24), 0
	ld	(0x229E5B:24), 0
	ld	(0x229E5C:24), 0
	xor	bc, bc
	lda xix, (0x229e5c:24)
HDAE5000_HD_Init_ClearLoop1:
	cp	bc, 0x0078
	jp	z, (.LHD_Init_ClearLoop1_Skip1:24)
	ld	(xix), 0x00
	inc 1, xix                              ; inc 1,XIX
	inc	1, bc
	jp HDAE5000_HD_Init_ClearLoop1                             ; jp 0x297318
.LHD_Init_ClearLoop1_Skip1:
	xor	bc, bc
	lda xix, (0x229ddf:24)
HDAE5000_HD_Init_ClearLoop2:
	cp	bc, 0x0078
	jp	z, (.LHD_Init_ClearLoop2_Skip1:24)
	ld	(xix), 0x00
	inc 1, xix                              ; inc 1,XIX
	inc	1, bc
	jp HDAE5000_HD_Init_ClearLoop2                             ; jp 0x297333
.LHD_Init_ClearLoop2_Skip1:
	call HDAE5000_ATA_SoftReset
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	z, (.LHD_Init_ClearLoop2_Skip2:24)
	ld	a, 0x03:opc
	jp HDAE5000_HD_Init_Fail                             ; jp 0x29742f
.LHD_Init_ClearLoop2_Skip2:
	call HDAE5000_ATA_IdentifyDevice
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	z, (.LHD_Init_ClearLoop2_Skip3:24)
	ld	a, 0x05:opc
	jp HDAE5000_HD_Init_Fail                             ; jp 0x29742f
.LHD_Init_ClearLoop2_Skip3:
	call HDAE5000_HD_ParseIdentify
	ld	xhl, 1:i3
	lda xix, (0x200628:24)
	ld	xde, 0x00000200
	call HDAE5000_ATA_ReadSector
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	z, (.LHD_Init_ClearLoop2_Skip4:24)
	ld	a, 0x06:opc
	jp HDAE5000_HD_Init_Fail                             ; jp 0x29742f
.LHD_Init_ClearLoop2_Skip4:
	call HDAE5000_HD_CheckSignature
	cp	(HDAE5000_RAM_HdSignatureOk:24), 1
	jp	z, (.LHD_Init_ClearLoop2_Skip5:24)
	ld	xwa, 0:i3
	ld	(HDAE5000_RAM_FreeClusters), xwa
	ld	a, 0x01:opc
	jp HDAE5000_HD_Init_Fail                             ; jp 0x29742f
.LHD_Init_ClearLoop2_Skip5:
	lda xix, (0x2006a0:24)
	ld	a, (xix)
	ld	(HDAE5000_RAM_QuickLoadMode:24), a
	inc 1, xix                              ; inc 1,XIX
	ld	a, (xix)
	ld	(HDAE5000_RAM_LoadByNumberMode:24), a
	inc 1, xix                              ; inc 1,XIX
	ld	a, (xix)
	ld	(HDAE5000_RAM_JumpAfterLoad:24), a
	inc 1, xix                              ; inc 1,XIX
	ld	a, (xix)
	ld	(HDAE5000_RAM_LyricJump:24), a
	inc 1, xix                              ; inc 1,XIX
	ld	a, (xix)
	ld	(HDAE5000_RAM_LyricForeColor:24), a
	inc 1, xix                              ; inc 1,XIX
	ld	a, (xix)
	ld	(HDAE5000_RAM_LyricBackColor:24), a
	call HDAE5000_HD_CountFreeClusters
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	z, (.LHD_Init_ClearLoop2_Skip6:24)
	ld	a, 0x07:opc
	jp HDAE5000_HD_Init_Fail                             ; jp 0x29742f
.LHD_Init_ClearLoop2_Skip6:
	call HDAE5000_HD_InitTables
	cp	(HDAE5000_RAM_HdSignatureOk:24), 1
	jp	nz, (.LHD_Init_ClearLoop2_Skip7:24)
	call HDAE5000_HD_ReadTables
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	z, (.LHD_Init_ClearLoop2_Skip7:24)
	ld	a, 0x08:opc
	jp HDAE5000_HD_Init_Fail                             ; jp 0x29742f
.LHD_Init_ClearLoop2_Skip7:
	ld	(HDAE5000_RAM_HdInitResult:24), 0
HDAE5000_HD_Init_Exit:
	call HDAE5000_ATA_Standby
	ret

HDAE5000_HD_Init_Fail:
	ld	(HDAE5000_RAM_HdInitResult:24), a
	jp HDAE5000_HD_Init_Exit                             ; jp 0x29742a
HDAE5000_ATA_WaitReady:
	; poll the ATA status register (0x13001E) until (status & 0xC0) == 0x40
	; (BSY clear, DRDY set); after 0x3FFFFF polls give up with the error
	; flag RAM 0x200222 = 1.  Preserves XIX, WA.
	push xix
	pushw wa                                ; push WA
	ld	xix, 0:i3
HDAE5000_ATA_WaitReady_Poll:
	cp	xix, 0x003fffff
	jp	z, (.LATA_WaitReady_Poll_Skip1:24)
	ld	a, (0x13001E:24)
	and	a, 0xc0
	cp	a, 0x40
	jp	z, (.LATA_WaitReady_Poll_Skip2:24)
	inc 1, xix                              ; inc 1,XIX
	jp HDAE5000_ATA_WaitReady_Poll                             ; jp 0x29743c
.LATA_WaitReady_Poll_Skip1:
	ld	(HDAE5000_RAM_AtaError:24), 1
.LATA_WaitReady_Poll_Skip2:
	popw wa                                 ; pop WA
	pop xix                                 ; pop XIX
	ret

HDAE5000_ATA_SoftReset_Status:
	; C-callable wrapper: HDAE5000_ATA_SoftReset, returns HL = 0 or 0xFFFF.
	push xiz
	call HDAE5000_ATA_SoftReset
	xor	hl, hl
	cp	(HDAE5000_RAM_AtaError:24), 0
	jr z, .LRT_7478                        ; [66 03] jr Z,0x297478
	ldw	hl, 0xffff
.LRT_7478:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_ATA_SoftReset:
	; ATA software reset: wait ready, write device control 0x130020 = 0x0E
	; (SRST + nIEN) then 0x0A (nIEN), wait ready again.  Error flag 0x200222.
	ld	(HDAE5000_RAM_AtaError:24), 0
	call HDAE5000_ATA_WaitReady
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	z, (.LATA_SoftReset_Skip1:24)
	jp HDAE5000_ATA_SoftReset_Return                             ; jp 0x2974b4
.LATA_SoftReset_Skip1:
	ld	(0x130020:24), 14
	ld	(0x130020:24), 10
	call HDAE5000_ATA_WaitReady
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	z, (HDAE5000_ATA_SoftReset_Return:24)
	ld	(HDAE5000_RAM_AtaError:24), 1
HDAE5000_ATA_SoftReset_Return:
	ret

HDAE5000_ATA_Standby_Status:
	; C-callable wrapper: HDAE5000_ATA_Standby, returns HL = 0 or 0xFFFF.
	; Reached through `call nz, (0x2974B5:24)` from several UI paths.
	call HDAE5000_ATA_Standby
	xor	hl, hl
	cp	(HDAE5000_RAM_AtaError:24), 0
	jr z, .LRT_74c6                        ; [66 03] jr Z,0x2974c6
	ldw	hl, 0xffff
.LRT_74c6:
	ret

HDAE5000_ATA_Standby:
	; spin the drive down: wait ready, features/sector/cylinder registers =
	; 0xFF, sector count = 0, device/head = 0xA0, command 0x94 (STANDBY
	; IMMEDIATE in the ATA-1/2 opcode map).  Saves all registers.
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	call HDAE5000_ATA_WaitReady
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	nz, (.LATA_Standby_Skip1:24)
	ld	(0x130012:24), 255
	ld	(0x130014:24), 0
	ld	(0x130016:24), 255
	ld	(0x130018:24), 255
	ld	(0x13001A:24), 255
	ld	(0x13001C:24), 160
	ld	(0x13001E:24), 148
.LATA_Standby_Skip1:
	pop xiz                                 ; pop XIZ
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	pop xhl                                 ; pop XHL
	pop xde                                 ; pop XDE
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

HDAE5000_HD_CheckSignature:
	; RAM 0x229D98 = 1 if the sector-1 image at 0x200628 starts with the
	; longs 0xAA55AA55, 0xF4F1F2F3 (the signature
	; HDAE5000_HD_SaveSettings builds there and writes to sector 1),
	; else 0.
	push xix
	push xbc
	push xwa
	lda xix, (0x200628:24)
	ld xwa, (xix)                           ; ld XWA,(XIX)
	ld xbc, (xix + 0x04)                    ; ld XBC,(XIX+0x04)
	cp	xwa, 0xaa55aa55
	jp	z, (.LHD_CheckSignature_Skip1:24)
	ld	(HDAE5000_RAM_HdSignatureOk:24), 0
	jp HDAE5000_HD_CheckSignature_Done                             ; jp 0x29754c
.LHD_CheckSignature_Skip1:
	cp	xbc, 0xf4f1f2f3
	jp	z, (.LHD_CheckSignature_Skip2:24)
	ld	(HDAE5000_RAM_HdSignatureOk:24), 0
	jp HDAE5000_HD_CheckSignature_Done                             ; jp 0x29754c
.LHD_CheckSignature_Skip2:
	ld	(HDAE5000_RAM_HdSignatureOk:24), 1
HDAE5000_HD_CheckSignature_Done:
	call HDAE5000_HD_ResetVersionKeyWord
	pop xwa                                 ; pop XWA
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

	push xwa
	push xbc
	push xix
	lda xix, (HDAE5000_Version_Key:24)
	ld xwa, (xix)                           ; ld XWA,(XIX)
	ld	xbc, (0x229c60)
	cp	xwa, xbc
	jp	z, (.LHD_CheckSignature_Done_Skip1:24)
	pop xix                                 ; pop XIX
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	pop xwa                                 ; pop XWA
	ret

.LHD_CheckSignature_Done_Skip1:
	pop xix                                 ; pop XIX
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

HDAE5000_HD_GetGeometry:
	; (XWA = dest) HDAE5000_HD_ParseIdentify, then store cylinders (0x229C32),
	; heads (0x229C34), sectors per track (0x200220), usable sectors
	; (0x200223) and the 40-byte model string (0x20083C) at dest.
	push xiz
	push xwa
	call HDAE5000_HD_ParseIdentify
	pop xwa                                 ; pop XWA
	ld	xix, xwa
	ld	wa, (0x229C32:24)
	ld (xix), wa                            ; ld (XIX),WA
	ld	wa, (0x229C34:24)
	ld (xix + 0x02), wa                     ; ld (XIX+0x02),WA
	ld	wa, (0x200220:24)
	ld (xix + 0x04), wa                     ; ld (XIX+0x04),WA
	ld	xwa, (0x200223)
	ld (xix + 0x06), xwa                    ; ld (XIX+0x06),XWA
	add	xix, 0x0000000a
	ld	xiy, 0x0020083c
	ldw	bc, 0x0014
	ldirw                                   ; ldirw
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_HD_ParseIdentify:
	; read the IDENTIFY DEVICE block at 0x200000 (HDAE5000_ATA_IdentifyDevice):
	; words 54/55/56 (+108/+110/+112: current cylinders, heads, sectors per
	; track) and 57-58 (+114: current capacity, minus 2) into
	; 0x229C32/0x229C34/0x200220/0x200223, then derive the disk layout:
	;   cluster = 0x20 sectors, or 0x40 if the capacity is >= 0x14DC93
	;   (0x229C5C);  cylinders x sectors (0x200200, the head stride used by
	;   HDAE5000_ATA_ReadSector/WriteSector);  FAT at sector 2 (0x229C68),
	;   the 323 table sectors at 3908 (0x229C64), data from 4231 (0x229C6C),
	;   data sector count (0x229C94) and FAT entry count (0x229C70, whole
	;   128-entry FAT sectors).  Finally words 27-46 (the model number) are
	;   copied byte-swapped to 0x20083C.
	lda xix, (0x200000:24)
	ld	wa, (xix+108)
	ld	(0x229c32), wa
	ld	wa, (xix+110)
	ld	(0x229c34), wa
	ld	wa, (xix+112)
	ld	(0x200220), wa
	ld xwa, (xix + 0x72)                    ; ld XWA,(XIX+0x72)
	dec	2, xwa
	ld	(0x200223), xwa
	ld	xbc, 0x0014dc93
	cp	xwa, xbc
	jp	ge, (.LHD_ParseIdentify_Skip1:24)
	ld	xwa, 0x00000020
	ld	(HDAE5000_RAM_SectorsPerCluster), xwa
	jp HDAE5000_HD_ParseIdentify_ClusterSet                             ; jp 0x2975f8
.LHD_ParseIdentify_Skip1:
	ld	xwa, 0x00000040
	ld	(HDAE5000_RAM_SectorsPerCluster), xwa
HDAE5000_HD_ParseIdentify_ClusterSet:
	ld	xbc, 0x00000200
	call HDAE5000_HD_Mul32
	ld	(HDAE5000_RAM_ClusterBytes), xwa
	xor	xwa, xwa
	xor	xbc, xbc
	ld	wa, (0x229C32:24)
	ld	bc, (0x200220:24)
	call HDAE5000_HD_Mul32
	ld	(0x200200), xwa
	ld	xwa, 2:i3
	ld	(HDAE5000_RAM_FatStartSector), xwa
	add	xwa, 0x00000f42
	ld	(HDAE5000_RAM_TablesStartSector), xwa
	add	xwa, 0x00000143
	ld	(HDAE5000_RAM_DataStartSector), xwa
	ld	xwa, (0x200223)
	ld	xbc, (HDAE5000_RAM_DataStartSector)
	sub	xwa, xbc
	inc 1, xwa                              ; inc 1,XWA
	ld	(HDAE5000_RAM_DataSectorCount), xwa
	ld	xwa, (HDAE5000_RAM_SectorsPerCluster)
	ld	xbc, 0x00000080
	call HDAE5000_HD_Mul32
	ld	xbc, xwa
	ld	xwa, (HDAE5000_RAM_DataSectorCount)
	call HDAE5000_HD_UDiv32
	ld	xbc, 0x00000080
	call HDAE5000_HD_Mul32
	ld	(HDAE5000_RAM_FatEntryCount), xwa
	lda xiy, (0x20083c:24)
	lda xix, (0x200036:24)
	ld	bc, 0:i3
HDAE5000_HD_ParseIdentify_ModelLoop:
	cp	bc, 0x0028
	jp	z, (.LHD_ParseIdentify_ModelLoop_Return1:24)
	ld	wa, (xix)
	ld	(xiy), w
	ld	(xiy+1), a
	inc	2, bc
	inc 2, xix                              ; inc 2,XIX
	inc 2, xiy                              ; inc 2,XIY
	jp HDAE5000_HD_ParseIdentify_ModelLoop                             ; jp 0x297680
.LHD_ParseIdentify_ModelLoop_Return1:
	ret

HDAE5000_ATA_WriteSector:
	; write one 512-byte sector: XHL = sector number (1-based), XIX = data.
	; The number is split with HDAE5000_HD_UDiv32 by the head stride
	; (0x200200) and by sectors per track (0x200220) into head (device/head
	; 0x13001C |= 0xA0), cylinder (0x130018/1A) and sector (0x130016);
	; sector count 1, command 0x30 (WRITE SECTORS), wait DRQ ((status &
	; 0xC8) == 0x48), 256 words to the data port 0x130010, wait ready;
	; error flag 0x200222 = status bit 0 (ERR).
	ld	(0x200204), xhl
	ld	(0x200208), xix
	ld	(HDAE5000_RAM_AtaError:24), 0
HDAE5000_ATA_WriteSector_WaitReady:
	ld	a, (0x13001E:24)
	and	a, 0xc0
	cp	a, 0x40
	jp	z, (.LATA_WriteSector_WaitReady_Skip1:24)
	jp HDAE5000_ATA_WriteSector_WaitReady                             ; jp 0x2976ab
.LATA_WriteSector_WaitReady_Skip1:
	ld	(0x130014:24), 1
	ld	xwa, (0x200204)
	dec	1, xwa
	ld	xbc, (0x200200)
	calr	HDAE5000_HD_UDiv32
	ld	e, a
	or	a, 0xa0
	ld	(0x13001C:24), a
	xor	xwa, xwa
	ld	a, e
	ld	xbc, (0x200200)
	calr	HDAE5000_HD_Mul32
	ld	(0x200218), xwa
	ld	xbc, xwa
	ld	xwa, (0x200204)
	sub	xwa, xbc
	dec	1, xwa
	xor	xbc, xbc
	ld	bc, (0x200220:24)
	calr	HDAE5000_HD_UDiv32
	ld	(0x130018:24), a
	ld	(0x13001A:24), w
	xor	xbc, xbc
	ld	bc, (0x200220:24)
	calr	HDAE5000_HD_Mul32
	ld	xbc, (0x200218)
	add	xbc, xwa
	ld	xwa, (0x200204)
	sub	xwa, xbc
	ld	(0x130016:24), a
	ld	(0x13001E:24), 48
HDAE5000_ATA_WriteSector_WaitDrq:
	ld	a, (0x13001E:24)
	and	a, 0xc8
	cp	a, 0x48
	jp	z, (.LATA_WriteSector_WaitDrq_Skip1:24)
	jp HDAE5000_ATA_WriteSector_WaitDrq                             ; jp 0x297731
.LATA_WriteSector_WaitDrq_Skip1:
	ld	bc, 0:i3
	ld	xix, (0x200208)
HDAE5000_ATA_WriteSector_DataLoop:
	cp	bc, 0x0200
	jp	nc, (HDAE5000_ATA_WriteSector_WaitDone:24)
	ld	wa, (xix)
	ld	(0x130010), wa
	inc 2, xix                              ; inc 2,XIX
	inc 2, xiy                              ; inc 2,XIY
	inc	2, bc
	jp HDAE5000_ATA_WriteSector_DataLoop                             ; jp 0x29774c
HDAE5000_ATA_WriteSector_WaitDone:
	ld	a, (0x13001E:24)
	and	a, 0xc0
	cp	a, 0x40
	jp	z, (.LATA_WriteSector_WaitDone_Skip1:24)
	jp HDAE5000_ATA_WriteSector_WaitDone                             ; jp 0x297766
.LATA_WriteSector_WaitDone_Skip1:
	ld	a, (0x13001E:24)
	and	a, 0x01
	ld	(HDAE5000_RAM_AtaError:24), a
	ret

HDAE5000_ATA_ReadSector:
	; read one sector: XHL = sector number (1-based), XIX = buffer, XDE =
	; bytes to keep (all 512 are read from 0x130010).  Same CHS split and
	; handshake as HDAE5000_ATA_WriteSector with command 0x20 (READ SECTORS).
	ld	(0x20020c), xhl
	ld	(0x200210), xix
	ld	(0x200214), xde
	ld	(HDAE5000_RAM_AtaError:24), 0
HDAE5000_ATA_ReadSector_WaitReady:
	ld	a, (0x13001E:24)
	and	a, 0xc0
	cp	a, 0x40
	jp	z, (.LATA_ReadSector_WaitReady_Skip1:24)
	jp HDAE5000_ATA_ReadSector_WaitReady                             ; jp 0x29779d
.LATA_ReadSector_WaitReady_Skip1:
	ld	(0x130014:24), 1
	ld	xwa, (0x20020c)
	dec	1, xwa
	ld	xbc, (0x200200)
	calr	HDAE5000_HD_UDiv32
	ld	e, a
	or	a, 0xa0
	ld	(0x13001C:24), a
	xor	xwa, xwa
	ld	a, e
	ld	xbc, (0x200200)
	calr	HDAE5000_HD_Mul32
	ld	(0x20021c), xwa
	ld	xbc, xwa
	ld	xwa, (0x20020c)
	sub	xwa, xbc
	dec	1, xwa
	xor	xbc, xbc
	ld	bc, (0x200220:24)
	calr	HDAE5000_HD_UDiv32
	ld	(0x130018:24), a
	ld	(0x13001A:24), w
	xor	xbc, xbc
	ld	bc, (0x200220:24)
	calr	HDAE5000_HD_Mul32
	ld	xbc, (0x20021c)
	add	xbc, xwa
	ld	xwa, (0x20020c)
	sub	xwa, xbc
	ld	(0x130016:24), a
	ld	(0x13001E:24), 32
HDAE5000_ATA_ReadSector_WaitDrq:
	ld	a, (0x13001E:24)
	and	a, 0xc8
	cp	a, 0x48
	jp	z, (.LATA_ReadSector_WaitDrq_Skip1:24)
	jp HDAE5000_ATA_ReadSector_WaitDrq                             ; jp 0x297823
.LATA_ReadSector_WaitDrq_Skip1:
	ld	bc, 0:i3
	ld	xix, (0x200210)
	ld	xde, (0x200214)
HDAE5000_ATA_ReadSector_DataLoop:
	cp	bc, 0x0200
	jp	nc, (HDAE5000_ATA_ReadSector_WaitDone:24)
	ld	wa, (0x130010:24)
	cp	bc, de
	jp	nc, (.LATA_ReadSector_DataLoop_Skip1:24)
	ld (xix), wa                            ; ld (XIX),WA
.LATA_ReadSector_DataLoop_Skip1:
	inc 2, xix                              ; inc 2,XIX
	inc	2, bc
	jp HDAE5000_ATA_ReadSector_DataLoop                             ; jp 0x297843
HDAE5000_ATA_ReadSector_WaitDone:
	ld	a, (0x13001E:24)
	and	a, 0xc0
	cp	a, 0x40
	jp	z, (.LATA_ReadSector_WaitDone_Skip1:24)
	jp HDAE5000_ATA_ReadSector_WaitDone                             ; jp 0x297862
.LATA_ReadSector_WaitDone_Skip1:
	ld	a, (0x13001E:24)
	and	a, 0x01
	ld	(HDAE5000_RAM_AtaError:24), a
	ret

HDAE5000_ATA_IdentifyDevice:
	; command 0xEC (IDENTIFY DEVICE) with 0xFF in the task-file registers and
	; device/head 0xA0; the 512-byte answer goes to RAM 0x200000 (parsed by
	; HDAE5000_HD_ParseIdentify).  Error flag 0x200222 = status bit 0.
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
HDAE5000_ATA_Identify_WaitReady:
	ld	a, (0x13001E:24)
	and	a, 0xc0
	cp	a, 0x40
	jp	z, (.LATA_Identify_WaitReady_Skip1:24)
	jp HDAE5000_ATA_Identify_WaitReady                             ; jp 0x29788b
.LATA_Identify_WaitReady_Skip1:
	ld	(0x130012:24), 255
	ld	(0x130014:24), 255
	ld	(0x130016:24), 255
	ld	(0x130018:24), 255
	ld	(0x13001A:24), 255
	ld	(0x13001C:24), 160
	ld	(0x13001E:24), 236
HDAE5000_ATA_Identify_WaitDrq:
	ld	a, (0x13001E:24)
	and	a, 0xc8
	cp	a, 0x48
	jp	z, (.LATA_Identify_WaitDrq_Skip1:24)
	jp HDAE5000_ATA_Identify_WaitDrq                             ; jp 0x2978c9
.LATA_Identify_WaitDrq_Skip1:
	ld	bc, 0:i3
	ld	xix, 0x00200000
HDAE5000_ATA_Identify_DataLoop:
	cp	bc, 0x0200
	jp	nc, (HDAE5000_ATA_Identify_WaitDone:24)
	ld	wa, (0x130010:24)
	ld (xix), wa                            ; ld (XIX),WA
	inc 2, xix                              ; inc 2,XIX
	inc	2, bc
	jp HDAE5000_ATA_Identify_DataLoop                             ; jp 0x2978e4
HDAE5000_ATA_Identify_WaitDone:
	ld	a, (0x13001E:24)
	and	a, 0xc0
	cp	a, 0x40
	jp	z, (.LATA_Identify_WaitDone_Skip1:24)
	jp HDAE5000_ATA_Identify_WaitDone                             ; jp 0x2978fc
.LATA_Identify_WaitDone_Skip1:
	ld	a, (0x13001E:24)
	and	a, 0x01
	ld	(HDAE5000_RAM_AtaError:24), a
	pop xiz                                 ; pop XIZ
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	pop xhl                                 ; pop XHL
	pop xde                                 ; pop XDE
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret


HDAE5000_HD_Mul32:	; 0x297925 (37 bytes)
	; 32x32 -> 32-bit multiply using partial products (the high products are
	; added into the upper half only; nothing above bit 31 is kept)
	; Computes XWA = BC * WA (full 32-bit result via 3 partial 16×16 multiplies)
	; Input: WA = multiplicand, BC = multiplier (16-bit halves)
	; Output: XWA = 32-bit product
	push xhl
	push xix
	ld hl, bc			; HL = low(BC)
	mul xhl, xwa			; XHL = low(BC) * WA
	ld xix, xhl			; accumulate in XIX
	ld hl, bc			; HL = low(BC) again
	mul	hl, qwa
	ld	qhl, hl
	ld hl, 0:i3			; clear low HL
	add xix, xhl			; add shifted partial product
	ld	hl, qbc
	mul xhl, xwa			; XHL = high(BC) * WA
	ld	qhl, hl
	ld hl, 0:i3			; clear low HL
	add xix, xhl			; add shifted partial product
	ld xwa, xix			; result in XWA
	pop xix
	pop xhl
	ret

HDAE5000_HD_UDiv32:	; 0x29794A (392 bytes)
	; Contains: 32-bit division, memory region init, HD config init (start)

	; --- 32-bit unsigned division ---
	; Input: XWA = dividend, XBC = divisor
	; Output: XWA = quotient, XBC = remainder
	push xix
	push xiy
	push xiz
	xor xix, xix			; remainder = 0
	xor xiy, xiy			; quotient = 0
	ldw iz, 32			; 32-bit counter
.Lhciv_div_loop:
	cp iz, 0:i3
	jr z, .Lhciv_div_done
	dec 1, iz
	sll xix, 1			; shift remainder left
	sll xiy, 1			; shift quotient left
	sll xwa, 1			; shift dividend (MSB → carry)
	jr nc, .Lhciv_div_no_carry
	inc 1, xix			; shift carry into remainder
.Lhciv_div_no_carry:
	cp xix, xbc			; remainder >= divisor?
	jr nc, .Lhciv_div_sub
	jp .Lhciv_div_loop
.Lhciv_div_sub:
	sub xix, xbc			; remainder -= divisor
	inc 1, xiy			; quotient++
	jp .Lhciv_div_loop
.Lhciv_div_done:
	ld xwa, xiy			; quotient → XWA
	ld xbc, xix			; remainder → XBC
	pop xiz
	pop xiy
	pop xix
	ret

	; --- Memory region initialization ---
	; Fill HD file allocation tables with spaces, zeros, 0xFFFFFFFF markers
	; (blank images of the filesystem tables before HDAE5000_HD_ReadTables
	; or a format; called from HDAE5000_HD_Init and one other site)
HDAE5000_HD_InitTables:				; 0x29797F
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	; Region 1: fill 0x201632-0x201DB2 with 0x20 (space)
	ld xix, HDAE5000_RAM_DirNames		; 0x201632
	ld xiy, HDAE5000_RAM_SongRecords		; 0x201DB2
.Lhciv_fill1:
	cp xix, xiy
	jp z, (.Lhciv_section2:24)		; jp Z, .Lhciv_section2
	ld (xix), 32		; store 0x20 (space)
	inc 1, xix
	jp .Lhciv_fill1
	; Region 2: structured fill 0x201DB2-0x2257B2 (76-byte records)
.Lhciv_section2:			; 0x2979A0
	ld xix, HDAE5000_RAM_SongRecords		; 0x201DB2
	ld xiy, HDAE5000_RAM_FlsRecords		; 0x2257B2
.Lhciv_outer2:				; 0x2979AA
	cp xix, xiy
	jp z, (.Lhciv_section3:24)		; jp Z, .Lhciv_section3
	; Inner: 26 bytes of 0x20 (space)
	xor xbc, xbc
.Lhciv_space26:				; 0x2979B3
	cp xbc, 26
	jp z, (.Lhciv_zeros:24)		; jp Z, .Lhciv_zeros
	push xix
	add xix, xbc
	ld (xix), 32
	pop xix
	inc 1, xbc
	jp .Lhciv_space26
	; Inner: 10 bytes of 0x00 at offset 26
.Lhciv_zeros:				; 0x2979CB
	ld bc, 0:i3
.Lhciv_zeros_loop:			; 0x2979CD
	cp bc, 10
	jp z, (.Lhciv_ff:24)		; jp Z, .Lhciv_ff
	pushw bc
	ldw wa, 26
	add bc, wa			; offset = counter + 26
	stib_ind 0x07, 0xF0, 0xE4, 0x00	; ld (XIX+BC), 0x00
	popw bc
	inc 1, bc
	jp .Lhciv_zeros_loop
	; Inner: 10 × 32-bit 0xFFFFFFFF at offset 36
.Lhciv_ff:				; 0x2979E9
	xor xbc, xbc
.Lhciv_ff_loop:				; 0x2979EB
	cp xbc, 10
	jp z, (.Lhciv_next_record:24)		; jp Z, .Lhciv_next_record
	push xbc
	ld xwa, 4:i3			; entry size = 4 bytes
	call HDAE5000_HD_Mul32	; XWA = XBC * 4 (multiply)
	add xwa, 36			; offset = 4*i + 36
	ld xbc, xwa
	push xix
	add xix, xbc
	ld xwa, 4294967295		; 0xFFFFFFFF marker
	ld (xix), xwa
	inc 1, xiz
	pop xix
	pop xbc
	inc 1, xbc
	jp .Lhciv_ff_loop
	; Advance to next 76-byte record
.Lhciv_next_record:			; 0x297A19
	add xix, 76
	jp .Lhciv_outer2
	; Region 3: fill 0x2257B2-0x229B32 with 0x00
.Lhciv_section3:			; 0x297A23
	ld xix, HDAE5000_RAM_FlsRecords		; 0x2257B2
	ld xiy, 2267954		; 0x229B32
.Lhciv_fill_zero:			; 0x297A2D
	cp xix, xiy
	jp z, (.Lhciv_section4:24)		; jp Z, .Lhciv_section4
	ld (xix), 0
	inc 1, xix
	jp .Lhciv_fill_zero
	; Region 4: fill 0x2257B2 in blocks of 144-byte rows, 120 rows,
	; 16 bytes of 0x20 per row
.Lhciv_section4:			; 0x297A3D
	ld xix, HDAE5000_RAM_FlsRecords		; 0x2257B2
	ld hl, 0:i3			; row counter
.Lhciv_row_loop:			; 0x297A44
	cp hl, 120			; 0x78 rows total
	jp z, (.Lhciv_mem_exit:24)		; jp Z, .Lhciv_mem_exit
	ld bc, 0:i3			; column counter
.Lhciv_col_loop:			; 0x297A4F
	cp bc, 16			; 16 bytes per row
	jp z, (.Lhciv_next_row:24)		; jp Z, .Lhciv_next_row
	stib_ind 0x07, 0xF0, 0xE4, 0x20	; ld (XIX+BC), 0x20
	inc 1, bc
	jp .Lhciv_col_loop
.Lhciv_next_row:			; 0x297A64
	add xix, 144			; 0x90 bytes per row stride
	inc 1, hl
	jp .Lhciv_row_loop
.Lhciv_mem_exit:			; 0x297A70
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

	; --- HD presence check wrapper ---
	; Calls HD config init, returns HL = 0 (success) or 0xFFFF (error)
	; (C-callable wrapper of HDAE5000_HD_WriteTables, not a presence check.)
HDAE5000_HD_WriteTables_Status:			; 0x297A78
	call HDAE5000_HD_WriteTables
	xor hl, hl
	cp (HDAE5000_RAM_AtaError:24), 0x00; cp (0x200222), 0
	jp z, (.LHD_WriteTables_Status_Return1:24)		; jp Z, ret (no error)
	ldw hl, 65535			; HL = 0xFFFF (error)
.LHD_WriteTables_Status_Return1:
	ret

	; --- HD config initialization (start — continues in next block) ---
	; Write all 323 sectors from RAM to HD, with retry
	; The 323 sectors are the filesystem tables held in RAM 0x201632-
	; 0x229B31 (HDAE5000_HD_InitTables' regions), written to sector
	; (0x229C64) = 3908 on; then every sector is read back into 0x200228 and
	; compared 4 bytes at a time.  7 retries; failure -> 0x200222 = 1.
HDAE5000_HD_WriteTables:			; 0x297A8D
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	ld (0x229d93:24), 0x07; (0x229D93) = 7 — retry counter
.Lhciv_config_restart:			; 0x297A9A
	ld xwa, (HDAE5000_RAM_TablesStartSector:24); XWA = (0x229C64) — HD base sector
	ld (0x229c74:24), xwa; (0x229C74) = current sector
	ld xwa, HDAE5000_RAM_DirNames		; 0x201632 — RAM buffer base
	ld (0x229c78:24), xwa; (0x229C78) = buffer ptr
	xor xwa, xwa
	ld (0x229c7c:24), xwa; (0x229C7C) = sector counter = 0
.Lhciv_write_loop:			; 0x297AB5
	ld xwa, 323			; 0x143 — total sectors
	cp (2268284:24), xwa; cp (0x229C7C), XWA — counter == 323?
	jp z, (.Lhdd_verify1:24)		; jp Z, verify phase (0x297B09 in next block)
	ld xhl, (0x229c74:24); XHL = (0x229C74) — current sector
	ld xix, (0x229c78:24); XIX = (0x229C78) — current buffer ptr
	call HDAE5000_ATA_WriteSector			; call 0x29769B — write sector to HD
	; Function continues in next block (HD_Detect_Drive)

HDAE5000_HD_WriteTables_Next:	; 0x297AD2 (836 bytes)
	; (no caller: this label sits inside HDAE5000_HD_WriteTables, right after
	; its HDAE5000_ATA_WriteSector call; it was HD_Detect_Drive, a region
	; name.  The region also holds HDAE5000_HD_ReadTables and
	; HDAE5000_HD_CountFreeClusters below.)
	; HD config write+verify (continuation), read+verify, sector counting

	; --- Write phase continuation (from HDAE5000_HD_WriteTables in prev block) ---
	; After calling write sector, check error and increment counters
	cp (HDAE5000_RAM_AtaError:24), 0x00; cp (0x200222), 0 — error?
	jp nz, (.Lhdd_error1:24)		; jp NZ, .Lhdd_error1
	ld xwa, (0x229c74:24); XWA = (0x229C74) sector++
	inc 1, xwa
	ld (0x229c74:24), xwa
	ld xwa, (0x229c7c:24); XWA = (0x229C7C) counter++
	inc 1, xwa
	ld (0x229c7c:24), xwa
	ld xwa, (0x229c78:24); XWA = (0x229C78) buffer += 512
	add xwa, 512
	ld (0x229c78:24), xwa
	jp .Lhciv_write_loop		; loop back to write phase

	; --- Verify phase: read back each sector, compare with RAM ---
.Lhdd_verify1:				; 0x297B09
	ld xwa, (HDAE5000_RAM_TablesStartSector:24); base sector → (0x229C74)
	ld (0x229c74:24), xwa
	ld xwa, HDAE5000_RAM_DirNames		; 0x201632 → (0x229C78)
	ld (0x229c78:24), xwa
	xor xwa, xwa
	ld (0x229c7c:24), xwa; counter = 0
.Lhdd_verify_loop1:			; 0x297B24
	ld xwa, 323
	cp (2268284:24), xwa; counter == 323?
	jp z, (.Lhdd_success1:24)		; jp Z, .Lhdd_success1
	ld xhl, (0x229c74:24); XHL = current sector
	ld xde, 512			; 512 bytes
	ld xix, 2097704			; 0x200228 read buffer
	call HDAE5000_ATA_ReadSector			; read sector to buffer
	cp (HDAE5000_RAM_AtaError:24), 0x00; error check
	jp nz, (.Lhdd_error1:24)		; jp NZ, .Lhdd_error1
	ld xix, (0x229c78:24); XIX = RAM buffer ptr
	ld xiy, 2097704			; XIY = read buffer
	ld bc, 0:i3
.Lhdd_compare_loop1:			; 0x297B5D
	cp bc, 512			; compared all 512 bytes?
	jp z, (.Lhdd_verify_next1:24)		; jp Z, .Lhdd_verify_next1
	ld_sril3 xwa, 0x07, 0xF0, 0xE4	; XWA = (XIX+BC)
	cpl_sri_rm xwa, 0x07, 0xF4, 0xE4	; cp XWA, (XIY+BC)
	jp nz, (.Lhdd_error1:24)		; jp NZ, .Lhdd_error1
	inc 4, bc			; 4 bytes at a time
	jp .Lhdd_compare_loop1
.Lhdd_verify_next1:			; 0x297B7B
	ld xwa, (0x229c74:24); sector++
	inc 1, xwa
	ld (0x229c74:24), xwa
	ld xwa, (0x229c7c:24); counter++
	inc 1, xwa
	ld (0x229c7c:24), xwa
	ld xwa, (0x229c78:24); buffer += 512
	add xwa, 512
	ld (0x229c78:24), xwa
	jp .Lhdd_verify_loop1

	; --- Success exit 1 ---
.Lhdd_success1:			; 0x297BA7
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

	; --- Error handler 1: retry or set error flag ---
.Lhdd_error1:				; 0x297BAF
	cp (0x229d93:24), 0x00; (0x229D93) retry == 0?
	jp z, (.Lhdd_final_error1:24)		; jp Z, .Lhdd_final_error1
	dec 1, (2268563:24); retry--
	jp .Lhciv_config_restart	; restart from scratch
.Lhdd_final_error1:			; 0x297BC3
	ld (HDAE5000_RAM_AtaError:24), 0x01; (0x200222) = 1 error flag
	xor xwa, xwa
	ld (HDAE5000_RAM_FreeClusters:24), xwa; clear (0x229C80)
	jp .Lhdd_success1		; clean up and return

	; === HD Config Read+Verify Wrapper ===
	; Calls config init 2, returns HL = 0 (ok) or 0xFFFF (error)
HDAE5000_HD_ReadTables_Status:				; 0x297BD4
	call HDAE5000_HD_ReadTables
	xor hl, hl
	cp (HDAE5000_RAM_AtaError:24), 0x00; error?
	jp z, (.Lhdd_wrapper2_ret:24)		; jp Z, .Lhdd_wrapper2_ret
	ldw hl, 65535
.Lhdd_wrapper2_ret:			; 0x297BE8
	ret

	; === HD Config Init 2: Read all sectors, then verify by re-reading ===
	; (the 323 filesystem-table sectors at (0x229C64) into RAM 0x201632)
HDAE5000_HD_ReadTables:			; 0x297BE9
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	ld (0x229d93:24), 0x07; retry = 7
.Lhdd_restart2:				; 0x297BF6
	ld xwa, (HDAE5000_RAM_TablesStartSector:24); base sector
	ld (0x229c74:24), xwa
	ld xwa, HDAE5000_RAM_DirNames
	ld (0x229c78:24), xwa; buffer = 0x201632
	xor xwa, xwa
	ld (0x229c7c:24), xwa; counter = 0
	; Read phase: read each of 323 sectors into RAM
.Lhdd_read_loop2:			; 0x297C11
	ld xwa, 323
	cp (2268284:24), xwa; counter == 323?
	jp z, (.Lhdd_verify_start2:24)		; jp Z, .Lhdd_verify_start2
	ld xde, 512
	ld xhl, (0x229c74:24); current sector
	ld xix, (0x229c78:24); current buffer ptr
	call HDAE5000_ATA_ReadSector			; read sector
	cp (HDAE5000_RAM_AtaError:24), 0x00
	jp nz, (.Lhdd_error2:24)		; jp NZ, .Lhdd_error2
	ld xwa, (0x229c7c:24); counter++
	inc 1, xwa
	ld (0x229c7c:24), xwa
	ld xwa, (0x229c74:24); sector++
	inc 1, xwa
	ld (0x229c74:24), xwa
	ld xwa, (0x229c78:24); buffer += 512
	add xwa, 512
	ld (0x229c78:24), xwa
	jp .Lhdd_read_loop2
	; Verify phase: re-read each sector, compare with RAM copy
.Lhdd_verify_start2:			; 0x297C6A
	ld xwa, (HDAE5000_RAM_TablesStartSector:24)
	ld (0x229c74:24), xwa
	ld xwa, HDAE5000_RAM_DirNames
	ld (0x229c78:24), xwa
	xor xwa, xwa
	ld (0x229c7c:24), xwa
.Lhdd_verify_loop2:			; 0x297C85
	ld xwa, 323
	cp (2268284:24), xwa
	jp z, (.Lhdd_success2:24)		; jp Z, .Lhdd_success2
	ld xhl, (0x229c74:24)
	ld xde, 512
	ld xix, 2097704			; read into 0x200228
	call HDAE5000_ATA_ReadSector
	cp (HDAE5000_RAM_AtaError:24), 0x00
	jp nz, (.Lhdd_error2:24)		; jp NZ, .Lhdd_error2
	ld xix, (0x229c78:24); RAM buffer
	ld xiy, 2097704			; read buffer
	ld bc, 0:i3
.Lhdd_compare_loop2:			; 0x297CBE
	cp bc, 512
	jp z, (.Lhdd_verify_next2:24)		; jp Z, .Lhdd_verify_next2
	ld_sril3 xwa, 0x07, 0xF0, 0xE4	; XWA = (XIX+BC)
	cpl_sri_rm xwa, 0x07, 0xF4, 0xE4	; cp XWA, (XIY+BC)
	jp nz, (.Lhdd_error2:24)		; jp NZ, .Lhdd_error2
	inc 4, bc
	jp .Lhdd_compare_loop2
.Lhdd_verify_next2:			; 0x297CDC
	ld xwa, (0x229c74:24)
	inc 1, xwa
	ld (0x229c74:24), xwa
	ld xwa, (0x229c7c:24)
	inc 1, xwa
	ld (0x229c7c:24), xwa
	ld xwa, (0x229c78:24)
	add xwa, 512
	ld (0x229c78:24), xwa
	jp .Lhdd_verify_loop2

.Lhdd_success2:			; 0x297D08
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

.Lhdd_error2:				; 0x297D10
	cp (0x229d93:24), 0x00
	jp z, (.Lhdd_final_error2:24)		; jp Z, .Lhdd_final_error2
	dec 1, (2268563:24)
	jp .Lhdd_restart2
.Lhdd_final_error2:			; 0x297D24
	ld (HDAE5000_RAM_AtaError:24), 0x01
	xor xwa, xwa
	ld (HDAE5000_RAM_FreeClusters:24), xwa
	jp .Lhdd_success2

	; === HD Count Used Sectors Wrapper ===
	; Returns XHL = the FREE-cluster count (0x229C80), or 0 on error.
HDAE5000_HD_CountFreeClusters_Status:				; 0x297D35
	call HDAE5000_HD_CountFreeClusters
	ld xhl, (HDAE5000_RAM_FreeClusters:24); XHL = (0x229C80) free-cluster count
	cp (HDAE5000_RAM_AtaError:24), 0x00
	jr z, .Lhdd_wrapper3_ret
	xor xhl, xhl			; error → return 0
.Lhdd_wrapper3_ret:			; 0x297D48
	ret

	; === Count Used Sectors ===
	; Reads the FAT from sector (0x229C68) = 2 and counts its ZERO 32-bit
	; entries, (0x229C70) entries in all, into 0x229C80.  Zero = free: the
	; allocator at 0x297E16 writes chains ending 0xFFFFFFFE and then
	; subtracts the clusters it took from this same count.  5 retries.
HDAE5000_HD_CountFreeClusters:			; 0x297D49
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	ld (0x229d93:24), 0x05; retry = 5
.Lhdd_restart3:				; 0x297D56
	xor xwa, xwa
	ld (HDAE5000_RAM_FreeClusters:24), xwa; free count = 0
	ld xwa, (HDAE5000_RAM_FatStartSector:24); base sector from (0x229C68)
	ld (0x229c84:24), xwa; → (0x229C84) current sector
	xor xwa, xwa
	ld (0x229c88:24), xwa; (0x229C88) = 0 counter
.Lhdd_outer3:				; 0x297D6E
	ld xwa, (HDAE5000_RAM_FatEntryCount:24); total sectors (0x229C70)
	cp (2268296:24), xwa; counter >= total?
	jp nc, (.Lhdd_success3:24)		; jp NC, .Lhdd_success3
	ld xde, 512
	ld xhl, (0x229c84:24); current sector
	lda xix, (0x200228:24); XIX = &0x200228
	call HDAE5000_ATA_ReadSector			; read sector
	cp (HDAE5000_RAM_AtaError:24), 0x00
	jp nz, (.Lhdd_error3:24)		; jp NZ, .Lhdd_error3
	lda xix, (0x200228:24)
	ld bc, 0:i3
.Lhdd_inner3:				; 0x297DA2
	cp bc, 512			; scanned all bytes?
	jp z, (.Lhdd_next_sector3:24)		; jp Z, .Lhdd_next_sector3
	ld xwa, (0x229c88:24); increment scan counter
	inc 1, xwa
	ld (0x229c88:24), xwa
	ld_sril3 xwa, 0x07, 0xF0, 0xE4	; XWA = (XIX+BC)
	inc 4, bc
	cp xwa, 0			; is this 32-bit word zero?
	jp nz, (.Lhdd_inner3:24)		; jp NZ, .Lhdd_inner3 (non-zero, keep scanning)
	ld xwa, (HDAE5000_RAM_FreeClusters:24); free count++ (this entry is 0)
	inc 1, xwa
	ld (HDAE5000_RAM_FreeClusters:24), xwa
	jp .Lhdd_inner3			; continue scanning
.Lhdd_next_sector3:			; 0x297DD9
	ld xwa, (0x229c84:24); sector++
	inc 1, xwa
	ld (0x229c84:24), xwa
	jp .Lhdd_outer3

.Lhdd_success3:			; 0x297DE9
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

.Lhdd_error3:				; 0x297DF1
	cp (0x229d93:24), 0x00
	jp z, (.Lhdd_final_error3:24)		; jp Z, .Lhdd_final_error3
	dec 1, (2268563:24)
	jp .Lhdd_restart3
.Lhdd_final_error3:			; 0x297E05
	ld (HDAE5000_RAM_AtaError:24), 0x01
	xor xwa, xwa
	ld (HDAE5000_RAM_FreeClusters:24), xwa
	jp .Lhdd_success3

HDAE5000_HD_WriteFile:	; 0x297E16 (443 bytes)
	; Write XBC bytes from XWA to the disk as a NEW cluster chain.
	;   in:  XWA = source, XBC = byte count, XDE = pointer to the file's
	;        first-cluster slot (the savers in this file pass one of the ten
	;        longs at +36.. of a 76-byte file record 0x201DB2 + dir*0x4C0 +
	;        file*0x4C; HDAE5000_HD_WriteClose/_WriteStream pass the slot
	;        given to HDAE5000_HD_WriteOpen)
	;   out: HL = 0, or 0xFFFF when the drive error byte 0x200222 is set.
	; An old chain (*XDE != 0xFFFFFFFF) is released first
	; (HDAE5000_HD_FreeChain_Worker).  ceil(XBC / cluster bytes 0x229C58)
	; clusters (0x229C98) are then taken one by one with
	; HDAE5000_HD_FindFreeCluster, written with HDAE5000_HD_WriteCluster and
	; linked from the previous one (0x229C9C) with HDAE5000_HD_FatSetEntry;
	; the last gets 0xFFFFFFFE (end of chain).  The first cluster goes to
	; *XDE, the count comes off the free-cluster count 0x229C80, and
	; 0x229C9C is left on the last cluster for HDAE5000_HD_AppendFile.
	; Disk full (FindFreeCluster -> 0xFFFFFFFD) sets 0x229DBC = 1 and stops.
	; (An earlier header read this as a copy "into display buffer".)

	; --- Wrapper: save params, call main, return status in HL ---
	push xiz
	ldw hl, 65535			; assume error
	cp (HDAE5000_RAM_AtaError:24), 0x00; HD error flag set?
	jp nz, (.Ldc_exit:24)		; jp NZ, .Ldc_exit
	ld (0x229d40:24), xwa; save XWA → (0x229D40)
	ld (0x229d38:24), xbc; save XBC → (0x229D38) = total bytes
	ld (0x229d2c:24), xde; save XDE → (0x229D2C) = entry list ptr
	call .Ldc_main
	xor hl, hl			; assume success
	cp (HDAE5000_RAM_AtaError:24), 0x00
	jp z, (.Ldc_exit:24)		; jp Z, .Ldc_exit
	ldw hl, 65535			; error
.Ldc_exit:				; 0x297E48
	pop xiz
	ret

	; --- Main display copy function ---
.Ldc_main:				; 0x297E4A
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	; Compute sector count = ceil(total_bytes / sector_size)
	xor xwa, xwa
	xor xbc, xbc
	ld xwa, (0x229d38:24); total bytes
	ld xbc, (HDAE5000_RAM_ClusterBytes:24); sector size (0x229C58)
	call HDAE5000_HD_UDiv32	; divide XWA/XBC
	cp xbc, 0			; remainder?
	jp z, (.Ldc_no_roundup:24)		; jp Z, no round-up
	inc 1, xwa			; round up
.Ldc_no_roundup:			; 0x297E70
	ld (0x229c98:24), xwa; sector count → (0x229C98)
	ld (0x229dbc:24), 0x00; (0x229DBC) = 0 — boundary flag
	; Check first entry in list
	ld xix, (0x229d2c:24); XIX = entry list ptr
	ld xwa, (xix)			; first entry
	cp xwa, 4294967295		; == 0xFFFFFFFF? (empty)
	jp z, (.Ldc_skip_first:24)		; jp Z, skip store
	ld (0x229cb8:24), xwa; → (0x229CB8) start sector
	call HDAE5000_HD_FreeChain_Worker			; call 0x29859A
.Ldc_skip_first:			; 0x297E96
	; Initialize config registers
	ld xwa, (HDAE5000_RAM_FatStartSector:24); base sector (0x229C68)
	ld (0x229cb4:24), xwa; → (0x229CB4)
	xor xwa, xwa
	ld (0x229cb0:24), xwa; (0x229CB0) = 0
	ld xwa, 512
	ld (0x229cac:24), xwa; (0x229CAC) = 512 sector size
	ld xwa, 4294967295
	ld (0x229d28:24), xwa; (0x229D28) = 0xFFFFFFFF
	xor xwa, xwa
	ld (0x229ca4:24), xwa; (0x229CA4) = 0 iteration counter
	ld (0x229d94:24), 0x00; (0x229D94) = 0 — first-sector flag
	ld (0x229d95:24), 0x00; (0x229D95) = 0 — first-alloc flag
	ld (0x229d96:24), 0x00; (0x229D96) = 0
	; Main allocation loop
.Ldc_loop:				; 0x297ED4
	call HDAE5000_HD_FindFreeCluster			; call 0x298243 — find next free sector
	ld xwa, (0x229ca8:24); result (0x229CA8)
	cp xwa, 4294967293		; == 0xFFFFFFFD? (disk full)
	jp nz, (.Ldc_not_full:24)		; jp NZ, .Ldc_not_full
	ld (0x229dbc:24), 0x01; boundary flag = 1
	jp .Ldc_cleanup			; done
.Ldc_not_full:				; 0x297EF2
	ld xwa, (0x229ca8:24); re-load result
	cp (0x229d94:24), 0x00; first-sector flag?
	jp nz, (.Ldc_not_first:24)		; jp NZ, .Ldc_not_first
	ld (0x229c9c:24), xwa; (0x229C9C) = first result
	ld (0x229ca0:24), xwa; (0x229CA0) = current result
	jp .Ldc_after_first		; skip
.Ldc_not_first:				; 0x297F10
	ld (0x229ca0:24), xwa; (0x229CA0) = current result
.Ldc_after_first:			; 0x297F15
	call HDAE5000_HD_WriteCluster			; call 0x29831B — allocate sector
	cp (0x229d97:24), 0x00; (0x229D97) alloc error?
	jp z, (.Ldc_alloc_ok:24)		; jp Z, .Ldc_alloc_ok
	; Alloc failed — mark as end, retry
	ld xwa, 4294967295
	ld (0x229ca0:24), xwa; (0x229CA0) = 0xFFFFFFFF
	call HDAE5000_HD_FatSetEntry			; call 0x2983AA — commit
	jp .Ldc_loop
.Ldc_alloc_ok:				; 0x297F36
	cp (0x229d95:24), 0x00; first-alloc flag?
	jp nz, (.Ldc_after_alloc:24)		; jp NZ, .Ldc_after_alloc
	ld (0x229d95:24), 0x01; set first-alloc flag
	ld xwa, (0x229ca8:24); store to entry list
	ld xix, (0x229d2c:24)
	ld (xix), xwa
.Ldc_after_alloc:			; 0x297F53
	ld xwa, (0x229ca4:24); iteration++
	inc 1, xwa
	ld (0x229ca4:24), xwa
	cp xwa, (2268312:24); == sector count?
	jp z, (.Ldc_all_done:24)		; jp Z, .Ldc_all_done
	cp (0x229d94:24), 0x00; first-sector flag?
	jp nz, (.Ldc_mid_sector:24)		; jp NZ, .Ldc_mid_sector
	ld (0x229d94:24), 0x01; set first-sector flag
	jp .Ldc_loop
.Ldc_mid_sector:			; 0x297F7E
	call HDAE5000_HD_FatSetEntry			; commit current sector
	ld xwa, (0x229ca0:24); current → (0x229C9C)
	ld (0x229c9c:24), xwa
	jp .Ldc_loop
.Ldc_all_done:				; 0x297F90
	call HDAE5000_HD_FatSetEntry			; commit final sector
	ld xwa, (0x229ca0:24)
	ld (0x229c9c:24), xwa
	ld xwa, 4294967294		; 0xFFFFFFFE = end marker
	ld (0x229ca0:24), xwa
	call HDAE5000_HD_FatSetEntry			; commit end marker
	; Adjust used sector count
	ld xwa, (HDAE5000_RAM_FreeClusters:24); (0x229C80) used count
	ld xbc, (0x229c98:24); sector count
	sub xwa, xbc			; used -= allocated
	ld (HDAE5000_RAM_FreeClusters:24), xwa
	jp ge, (.Ldc_cleanup:24)		; jp GE, .Ldc_cleanup (no underflow)
	xor xwa, xwa			; clamp to 0
	ld (HDAE5000_RAM_FreeClusters:24), xwa
.Ldc_cleanup:				; 0x297FC9
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

HDAE5000_HD_AppendFile:	; 0x297FD1
	; Same arguments and result as HDAE5000_HD_WriteFile, but the new
	; clusters CONTINUE the chain whose last cluster is in 0x229C9C (left
	; there by the previous WriteFile/AppendFile), *XDE is only tested
	; (0xFFFFFFFF: nothing to append to) and the FAT scan position
	; (0x229CAC/0x229CB0/0x229CB4) is not reset.  Every caller streams a
	; file through the 0x8000-byte RAM buffer 0x230F1C: first chunk with
	; WriteFile, the rest with this (HDAE5000_HD_WriteClose/_WriteStream and
	; four savers in this file).
	; AS WRITTEN, when one call needs more than one cluster the first new
	; cluster is written but never linked: the first pass neither links
	; 0x229C9C to it nor makes it the new tail (WriteFile's first pass
	; does), so the second cluster is linked straight from the old tail and
	; the first stays 0 (free) in the FAT.  With 64-sector clusters (drives
	; of >= 0x14DC93 sectors, HDAE5000_HD_ParseIdentify) a 0x8000-byte chunk
	; is one cluster and this never happens; with 32-sector clusters every
	; full chunk would lose 16 KB.
	; (Was "Display_Restore", "(9217 bytes)": neither a display routine nor
	; that size.)
; LDR: 0x297FD1 (1617 bytes)
	; ^ conversion-region size (local-label prefix .LDR_), not a routine
	;   size: it holds HD_AppendFile .. HD_FreeChain_Worker, 16 routines.

	push xiz
	ldw	hl, 0xffff
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	nz, (.LHD_AppendFile_Skip1:24)
	ld	(0x229d40), xwa
	ld	(0x229d38), xbc
	ld	(0x229d2c), xde
	call HDAE5000_HD_AppendFile_Worker
	xor	hl, hl
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	z, (.LHD_AppendFile_Skip1:24)
	ldw	hl, 0xffff
.LHD_AppendFile_Skip1:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_HD_AppendFile_Worker:
	; register-preserving body of HDAE5000_HD_AppendFile
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	xor	xwa, xwa
	xor	xbc, xbc
	ld	xwa, (0x229d38)
	ld	xbc, (HDAE5000_RAM_ClusterBytes)
	call HDAE5000_HD_UDiv32
	cp	xbc, 0x00000000
	jp	z, (.LHD_AppendFile_Worker_Skip1:24)
	inc 1, xwa                              ; inc 1,XWA
.LHD_AppendFile_Worker_Skip1:
	ld	(0x229c98), xwa
	ld	(0x229DBC:24), 0
	ld	xix, (0x229d2c)
	ld xwa, (xix)                           ; ld XWA,(XIX)
	cp	xwa, 0xffffffff
	jp	z, (HDAE5000_HD_AppendFile_Exit:24)
	xor	xwa, xwa
	ld	(0x229ca4), xwa
	ld	(0x229D94:24), 0
HDAE5000_HD_AppendFile_Loop:
	call HDAE5000_HD_FindFreeCluster
	ld	xwa, (0x229ca8)
	cp	xwa, 0xfffffffd
	jp	nz, (.LHD_AppendFile_Worker_Skip2:24)
	ld	(0x229DBC:24), 1
	jp HDAE5000_HD_AppendFile_Exit                             ; jp 0x298114
.LHD_AppendFile_Worker_Skip2:
	ld	xwa, (0x229ca8)
	ld	(0x229ca0), xwa
	call HDAE5000_HD_WriteCluster
	cp	(0x229D97:24), 0
	jp	z, (.LHD_AppendFile_Worker_Skip3:24)
	ld	xwa, 0xffffffff
	ld	(0x229ca0), xwa
	call HDAE5000_HD_FatSetEntry
	jp HDAE5000_HD_AppendFile_Loop                             ; jp 0x298055
.LHD_AppendFile_Worker_Skip3:
	ld	xwa, (0x229ca4)
	inc 1, xwa                              ; inc 1,XWA
	ld	(0x229ca4), xwa
	cp	xwa, (0x229c98)
	jp	z, (.LHD_AppendFile_Worker_Skip5:24)
	cp	(0x229D94:24), 0
	jp	nz, (.LHD_AppendFile_Worker_Skip4:24)
	ld	(0x229D94:24), 1
	jp HDAE5000_HD_AppendFile_Loop                             ; jp 0x298055
.LHD_AppendFile_Worker_Skip4:
	call HDAE5000_HD_FatSetEntry
	ld	xwa, (0x229ca0)
	ld	(0x229c9c), xwa
	jp HDAE5000_HD_AppendFile_Loop                             ; jp 0x298055
.LHD_AppendFile_Worker_Skip5:
	call HDAE5000_HD_FatSetEntry
	ld	xwa, (0x229ca0)
	ld	(0x229c9c), xwa
	ld	xwa, 0xfffffffe
	ld	(0x229ca0), xwa
	call HDAE5000_HD_FatSetEntry
	ld	xwa, (HDAE5000_RAM_FreeClusters)
	ld	xbc, (0x229c98)
	sub	xwa, xbc
	ld	(HDAE5000_RAM_FreeClusters), xwa
	jp	ge, (HDAE5000_HD_AppendFile_Exit:24)
	xor	xwa, xwa
	ld	(HDAE5000_RAM_FreeClusters), xwa
HDAE5000_HD_AppendFile_Exit:
	pop xiz                                 ; pop XIZ
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	pop xhl                                 ; pop XHL
	pop xde                                 ; pop XDE
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

HDAE5000_HD_ReadFile:
	; Read a file's cluster chain into memory.
	;   in:  XWA = destination, XBC = byte count, XDE = pointer to the
	;        first-cluster slot (as HDAE5000_HD_WriteFile)
	;   out: HL = 0, or 0xFFFF when the drive error byte 0x200222 is set.
	; Follows the chain (HDAE5000_HD_ReadCluster, HDAE5000_HD_FatNextCluster)
	; to the end marker 0xFFFFFFFE or until the byte count runs out; the
	; position stays in 0x229D30 (cluster) / 0x229D34 (sector within it) for
	; HDAE5000_HD_ReadFileNext.  A read error sets 0x200222 = 1.
	push xiz
	ldw	hl, 0xffff
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	nz, (.LHD_ReadFile_Skip1:24)
	ld	(0x229d40), xwa
	ld	(0x229d38), xbc
	ld	(0x229d2c), xde
	call HDAE5000_HD_ReadFile_Worker
	xor	hl, hl
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	z, (.LHD_ReadFile_Skip1:24)
	ldw	hl, 0xffff
.LHD_ReadFile_Skip1:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_HD_ReadFile_Worker:
	; register-preserving body of HDAE5000_HD_ReadFile
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	ld	xwa, 0xffffffff
	ld	(0x229d28), xwa
	ld	xix, (0x229d2c)
	ld xwa, (xix)                           ; ld XWA,(XIX)
	ld	(0x229d30), xwa
	cp	xwa, 0xffffffff
	jp	z, (HDAE5000_HD_ReadFile_Exit:24)
HDAE5000_HD_ReadFile_Loop:
	ld	xwa, (0x229d30)
	cp	xwa, 0xfffffffe
	jp	nz, (.LHD_ReadFile_Worker_Skip1:24)
	jp HDAE5000_HD_ReadFile_Exit                             ; jp 0x2981b8
.LHD_ReadFile_Worker_Skip1:
	call HDAE5000_HD_ReadCluster
	cp	(0x229DBE:24), 0
	jp	z, (.LHD_ReadFile_Worker_Skip2:24)
	ld	(HDAE5000_RAM_AtaError:24), 1
	jp HDAE5000_HD_ReadFile_Exit                             ; jp 0x2981b8
.LHD_ReadFile_Worker_Skip2:
	cp	(0x229DBF:24), 1
	jp	z, (HDAE5000_HD_ReadFile_Exit:24)
	call HDAE5000_HD_FatNextCluster
	jp HDAE5000_HD_ReadFile_Loop                             ; jp 0x298178
HDAE5000_HD_ReadFile_Exit:
	pop xiz                                 ; pop XIZ
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	pop xhl                                 ; pop XHL
	pop xde                                 ; pop XDE
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

HDAE5000_HD_ReadFileNext:
	; Continue a read begun by HDAE5000_HD_ReadFile: XWA = destination,
	; XBC = byte count (XDE is stored in 0x229D2C but not used); resumes at
	; cluster 0x229D30, sector 0x229D34 (HDAE5000_HD_ReadClusterFrom).
	; HL = 0 / 0xFFFF as ReadFile.
	push xiz
	ldw	hl, 0xffff
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	nz, (.LHD_ReadFileNext_Skip1:24)
	ld	(0x229d40), xwa
	ld	(0x229d38), xbc
	ld	(0x229d2c), xde
	call HDAE5000_HD_ReadFileNext_Worker
	xor	hl, hl
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	z, (.LHD_ReadFileNext_Skip1:24)
	ldw	hl, 0xffff
.LHD_ReadFileNext_Skip1:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_HD_ReadFileNext_Worker:
	; register-preserving body of HDAE5000_HD_ReadFileNext
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
HDAE5000_HD_ReadFileNext_Loop:
	ld	xwa, (0x229d30)
	cp	xwa, 0xfffffffe
	jp	nz, (.LHD_ReadFileNext_Worker_Skip1:24)
	jp HDAE5000_HD_ReadFileNext_Exit                             ; jp 0x29823b
.LHD_ReadFileNext_Worker_Skip1:
	call HDAE5000_HD_ReadClusterFrom
	cp	(0x229DBE:24), 0
	jp	z, (.LHD_ReadFileNext_Worker_Skip2:24)
	ld	(HDAE5000_RAM_AtaError:24), 1
	jp HDAE5000_HD_ReadFileNext_Exit                             ; jp 0x29823b
.LHD_ReadFileNext_Worker_Skip2:
	cp	(0x229DBF:24), 1
	jp	z, (HDAE5000_HD_ReadFileNext_Exit:24)
	call HDAE5000_HD_FatNextCluster
	jp HDAE5000_HD_ReadFileNext_Loop                             ; jp 0x2981fb
HDAE5000_HD_ReadFileNext_Exit:
	pop xiz                                 ; pop XIZ
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	pop xhl                                 ; pop XHL
	pop xde                                 ; pop XDE
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

HDAE5000_HD_FindFreeCluster:
	; Next FREE (zero) FAT entry, scanning on from the saved position: byte
	; offset 0x229CAC in the FAT sector buffer 0x200898, FAT sector index
	; 0x229CB0, disk sector 0x229CB4 (both advanced by 0x229D96, which is 0
	; until the first sector has been loaded, then 1).  Returns the cluster
	; number, 1-based (sector index * 128 + offset / 4 + 1), in 0x229CA8 and
	; steps past it; 0xFFFFFFFD when a read fails or the sector index equals
	; 0x229C70 (note: HDAE5000_HD_ParseIdentify sets 0x229C70 to the number
	; of FAT ENTRIES, which HDAE5000_HD_CountFreeClusters compares with an
	; entry counter; here it is compared with a sector index).
	ld	xwa, 0x00000200
	cp	(0x229cac), xwa
	jp	nz, (.LHD_FindFreeCluster_Skip2:24)
	xor	xwa, xwa
	ld	(0x229cac), xwa
	ld	a, (0x229D96:24)
	add	(0x229CB0:24), xwa
	add	(0x229CB4:24), xwa
	ld	(0x229D96:24), 1
	ld	xwa, (HDAE5000_RAM_FatEntryCount)
	cp	(0x229cb0), xwa
	jp	nz, (.LHD_FindFreeCluster_Skip1:24)
	ld	xwa, 0xfffffffd
	ld	(0x229ca8), xwa
	jp HDAE5000_HD_FindFreeCluster_Return                             ; jp 0x29831a
.LHD_FindFreeCluster_Skip1:
	ld	xhl, (0x229cb4)
	ld	xde, 0x00000200
	lda xix, (0x200898:24)
	call HDAE5000_ATA_ReadSector
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	z, (.LHD_FindFreeCluster_Skip2:24)
	ld	xwa, 0xfffffffd
	ld	(0x229ca8), xwa
	jp HDAE5000_HD_FindFreeCluster_Return                             ; jp 0x29831a
.LHD_FindFreeCluster_Skip2:
	lda xix, (0x200898:24)
	ld	xbc, (0x229cac)
	add	xix, xbc
	ld xwa, (xix)                           ; ld XWA,(XIX)
	cp	xwa, 0x00000000
	jp	z, (.LHD_FindFreeCluster_Skip3:24)
	ld	xwa, (0x229cac)
	add	xwa, 0x00000004
	ld	(0x229cac), xwa
	jp HDAE5000_HD_FindFreeCluster                             ; jp 0x298243
.LHD_FindFreeCluster_Skip3:
	ld	xwa, (0x229cb0)
	ld	xbc, 0x00000080
	call HDAE5000_HD_Mul32
	push xwa
	ld	xwa, (0x229cac)
	ld	xbc, 4:i3
	call HDAE5000_HD_UDiv32
	ld	xbc, xwa
	pop xwa                                 ; pop XWA
	add	xwa, xbc
	inc 1, xwa                              ; inc 1,XWA
	ld	(0x229ca8), xwa
	ld	xwa, (0x229cac)
	add	xwa, 0x00000004
	ld	(0x229cac), xwa
HDAE5000_HD_FindFreeCluster_Return:
	ret

HDAE5000_HD_WriteCluster:
	; Write cluster 0x229CA8: its 0x229C5C sectors, disk sector 0x229C6C +
	; (cluster-1)*0x229C5C + i, from the buffer pointer 0x229D40, which it
	; advances by 512 per sector.  A write error sets 0x229D97 = 1 and puts
	; 0x229D40 back to its value on entry.
	ld	(0x229D97:24), 0
	xor	xwa, xwa
	ld	(0x229cc0), xwa
	ld	xwa, (0x229d40)
	ld	(0x229cbc), xwa
HDAE5000_HD_WriteCluster_Loop:
	ld	xwa, (HDAE5000_RAM_SectorsPerCluster)
	cp	(0x229cc0), xwa
	jp	z, (HDAE5000_HD_WriteCluster_Return:24)
	ld	xwa, (0x229ca8)
	dec	1, xwa
	ld	xbc, (HDAE5000_RAM_SectorsPerCluster)
	call HDAE5000_HD_Mul32
	ld	xbc, (HDAE5000_RAM_DataStartSector)
	add	xwa, xbc
	ld	xbc, (0x229cc0)
	add	xwa, xbc
	ld	xhl, xwa
	ld	xix, (0x229d40)
	call HDAE5000_ATA_WriteSector
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	z, (.LHD_WriteCluster_Skip1:24)
	ld	(0x229D97:24), 1
	ld	xwa, (0x229cbc)
	ld	(0x229d40), xwa
	jp HDAE5000_HD_WriteCluster_Return                             ; jp 0x2983a9
.LHD_WriteCluster_Skip1:
	ld	xwa, (0x229cc0)
	inc 1, xwa                              ; inc 1,XWA
	ld	(0x229cc0), xwa
	ld	xwa, (0x229d40)
	add	xwa, 0x00000200
	ld	(0x229d40), xwa
	jp HDAE5000_HD_WriteCluster_Loop                             ; jp 0x298332
HDAE5000_HD_WriteCluster_Return:
	ret

HDAE5000_HD_FatSetEntry:
	; FAT[cluster 0x229C9C] = 0x229CA0.  Entry cluster-1 lives in FAT sector
	; (cluster-1)/128 (-> 0x229D48) at byte ((cluster-1)%128)*4 (-> 0x229D4C).
	; One FAT sector is cached in 0x200A98, its index in 0x229D28
	; (0xFFFFFFFF = none): a different sector is flushed and then loaded
	; (HDAE5000_HD_FatFlushSector, HDAE5000_HD_FatLoadSector); storing the
	; end marker 0xFFFFFFFE also flushes.
	ld	xwa, (0x229c9c)
	dec	1, xwa
	ld	xbc, 0x00000080
	call HDAE5000_HD_UDiv32
	push xwa
	ld	xwa, 4:i3
	call HDAE5000_HD_Mul32
	ld	xbc, xwa
	pop xwa                                 ; pop XWA
	ld	(0x229d48), xwa
	ld	(0x229d4c), xbc
	ld	xwa, (0x229d28)
	cp	xwa, 0xffffffff
	jp	nz, (.LHD_FatSetEntry_Skip1:24)
	call HDAE5000_HD_FatLoadSector
	jp HDAE5000_HD_FatSetEntry_Store                             ; jp 0x2983f7
.LHD_FatSetEntry_Skip1:
	ld	xwa, (0x229d48)
	ld	xbc, (0x229d28)
	cp	xwa, xbc
	jp	nz, (.LHD_FatSetEntry_Store_Skip1:24)
HDAE5000_HD_FatSetEntry_Store:
	lda xix, (0x200a98:24)
	ld	xbc, (0x229d4c)
	add	xix, xbc
	ld	xwa, (0x229ca0)
	ld (xix), xwa                           ; ld (XIX),XWA
	cp	xwa, 0xfffffffe
	jp	nz, (HDAE5000_HD_FatSetEntry_Return:24)
	call HDAE5000_HD_FatFlushSector
	jp HDAE5000_HD_FatSetEntry_Return                             ; jp 0x298429
.LHD_FatSetEntry_Store_Skip1:
	call HDAE5000_HD_FatFlushSector
	call HDAE5000_HD_FatLoadSector
	jp HDAE5000_HD_FatSetEntry_Store                             ; jp 0x2983f7
HDAE5000_HD_FatSetEntry_Return:
	ret

HDAE5000_HD_FatLoadSector:
	; read FAT sector 0x229D48 (disk sector 0x229C68 + it) into the cache 0x200A98; 0x229D28 = 0x229D48
	ld	xhl, (HDAE5000_RAM_FatStartSector)
	ld	xwa, (0x229d48)
	add	xhl, xwa
	ld	xde, 0x00000200
	lda xix, (0x200a98:24)
	call HDAE5000_ATA_ReadSector
	ld	xwa, (0x229d48)
	ld	(0x229d28), xwa
	ret

HDAE5000_HD_FatFlushSector:
	; write the cache 0x200A98 back to FAT sector 0x229D28 (disk sector 0x229C68 + it)
	ld	xhl, (HDAE5000_RAM_FatStartSector)
	ld	xwa, (0x229d28)
	add	xhl, xwa
	lda xix, (0x200a98:24)
	call HDAE5000_ATA_WriteSector
	ret

HDAE5000_HD_ReadCluster:
	; read cluster 0x229D30 from its first sector: 0x229D34 = 0, then falls
	; into HDAE5000_HD_ReadClusterFrom
	ld	xwa, 0:i3
	ld	(0x229d34), xwa
HDAE5000_HD_ReadClusterFrom:
	; Read cluster 0x229D30 from sector 0x229D34 on into the buffer pointer
	; 0x229D40 (advanced by 512 per sector), consuming the byte count 0x229D38;
	; a last sector with fewer than 512 bytes left is read partially (count
	; 0x229D3C) and sets 0x229DBF = 1 (done).  0x229D34 goes back to 0 once
	; the whole cluster is read.  A read error sets 0x229DBE = 1.
	ld	(0x229DBF:24), 0
	ld	(0x229DBE:24), 0
HDAE5000_HD_ReadClusterFrom_Loop:
	ld	xwa, (0x229d34)
	cp	xwa, (HDAE5000_RAM_SectorsPerCluster)
	jp	nz, (.LHD_ReadClusterFrom_Skip1:24)
	ld	xwa, 0:i3
	ld	(0x229d34), xwa
	jp HDAE5000_HD_ReadClusterFrom_Return                             ; jp 0x298540
.LHD_ReadClusterFrom_Skip1:
	ld	xwa, (0x229d30)
	dec	1, xwa
	ld	xbc, (HDAE5000_RAM_SectorsPerCluster)
	call HDAE5000_HD_Mul32
	ld	xbc, (HDAE5000_RAM_DataStartSector)
	add	xwa, xbc
	ld	xbc, (0x229d34)
	add	xwa, xbc
	ld	xhl, xwa
	ld	xwa, (0x229d38)
	cp	xwa, 0x00000200
	jp	nc, (.LHD_ReadClusterFrom_Skip2:24)
	ld	xwa, (0x229d38)
	ld	(0x229d3c), xwa
	ld	(0x229DBF:24), 1
	jp HDAE5000_HD_ReadClusterFrom_Read                             ; jp 0x2984e0
.LHD_ReadClusterFrom_Skip2:
	ld	xwa, 0x00000200
	ld	(0x229d3c), xwa
HDAE5000_HD_ReadClusterFrom_Read:
	ld	xix, (0x229d40)
	ld	xde, (0x229d3c)
	call HDAE5000_ATA_ReadSector
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	z, (.LHD_ReadClusterFrom_Read_Skip1:24)
	ld	(0x229DBE:24), 1
	jp HDAE5000_HD_ReadClusterFrom_Return                             ; jp 0x298540
.LHD_ReadClusterFrom_Read_Skip1:
	cp	(0x229DBF:24), 1
	jp	z, (HDAE5000_HD_ReadClusterFrom_Return:24)
	ld	xwa, (0x229d38)
	ld	xbc, 0x00000200
	sub	xwa, xbc
	ld	(0x229d38), xwa
	ld	xwa, (0x229d34)
	inc 1, xwa                              ; inc 1,XWA
	ld	(0x229d34), xwa
	ld	xwa, (0x229d40)
	ld	xbc, 0x00000200
	add	xwa, xbc
	ld	(0x229d40), xwa
	jp HDAE5000_HD_ReadClusterFrom_Loop                             ; jp 0x298478
HDAE5000_HD_ReadClusterFrom_Return:
	ret

HDAE5000_HD_FatNextCluster:
	; 0x229D30 = FAT[0x229D30], the next cluster of the chain (the entry's
	; offset is left in 0x229D4C).  Loads the FAT sector into the 0x200A98
	; cache when it is not the cached one -- without flushing: read-only.
	ld	xwa, (0x229d30)
	dec	1, xwa
	ld	xbc, 0x00000080
	call HDAE5000_HD_UDiv32
	ld	(0x229d48), xwa
	ld	xwa, 4:i3
	call HDAE5000_HD_Mul32
	ld	(0x229d4c), xwa
	ld	xwa, (0x229d48)
	cp	xwa, (0x229d28)
	jp	nz, (.LHD_FatNextCluster_Read_Skip1:24)
HDAE5000_HD_FatNextCluster_Read:
	lda xix, (0x200a98:24)
	ld	xwa, (0x229d4c)
	add	xix, xwa
	ld xwa, (xix)                           ; ld XWA,(XIX)
	ld	(0x229d30), xwa
	jp HDAE5000_HD_FatNextCluster_Return                             ; jp 0x29858f
.LHD_FatNextCluster_Read_Skip1:
	call HDAE5000_HD_FatLoadSector
	jp HDAE5000_HD_FatNextCluster_Read                             ; jp 0x298570
HDAE5000_HD_FatNextCluster_Return:
	ret

HDAE5000_HD_FreeChain:
	; XWA = first cluster: release that chain (HDAE5000_HD_FreeChain_Worker)
	ld	(0x229cb8), xwa
	call HDAE5000_HD_FreeChain_Worker
	ret

HDAE5000_HD_FreeChain_Worker:
	; Release the chain starting at cluster 0x229CB8: each entry is set to 0
	; (free) and its FAT sector written back, up to the end marker
	; 0xFFFFFFFE; the count released is added to the free-cluster count
	; 0x229C80.  An entry that is already 0 stops it early, without that
	; update.
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	ld	xwa, 0xffffffff
	xor	xbc, xbc
	ld	(0x229d28), xwa
	ld	(0x229d4c), xbc
	ld	(0x229d24), xbc
	ld	xwa, (0x229cb8)
	ld	(0x229d30), xwa
.LHD_FreeChain_Worker_Loop1:
	call HDAE5000_HD_FatNextCluster
	ld	xwa, (0x229d30)
	cp	xwa, 0x00000000
	jp	z, (.LHD_FreeChain_Worker_Skip1:24)
	lda xix, (0x200a98:24)
	ld	xbc, (0x229d4c)
	add	xix, xbc
	xor	xwa, xwa
	ld (xix), xwa                           ; ld (XIX),XWA
	ld	xwa, (0x229d24)
	inc 1, xwa                              ; inc 1,XWA
	ld	(0x229d24), xwa
	call HDAE5000_HD_FatFlushSector
	ld	xwa, (0x229d30)
	cp	xwa, 0xfffffffe
	jp	nz, (.LHD_FreeChain_Worker_Loop1:24)
	call HDAE5000_HD_FatFlushSector
	ld	xwa, (HDAE5000_RAM_FreeClusters)
	ld	xbc, (0x229d24)
	add	xwa, xbc
	ld	(HDAE5000_RAM_FreeClusters), xwa
.LHD_FreeChain_Worker_Skip1:
	pop xiz                                 ; pop XIZ
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	pop xhl                                 ; pop XHL
	pop xde                                 ; pop XDE
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

HDAE5000_HD_Format:	; 0x298622 (cross-reference from Display_Init)
	; (Display_Init is now HDAE5000_HD_FormatDrive, its only caller.)
	; C-callable: HDAE5000_HD_Format_Worker, then HDAE5000_ATA_Standby and
	; HDAE5000_HD_ClearStatusBytes; returns L = the drive error byte
	; 0x200222 (0 = formatted).
; LDSR: 0x298622 (7600 bytes)
	; ^ conversion-region size (local-label prefix .LDSR_), not a routine
	;   size: the format code, the disk-usage helpers, the settings-sector
	;   routines and an unreachable browser library (see below).

	call HDAE5000_HD_Format_Worker
	xor	hl, hl
	ld	l, (HDAE5000_RAM_AtaError:24)
	pushw hl                                ; push HL
	call HDAE5000_ATA_Standby
	call HDAE5000_HD_ClearStatusBytes
	popw hl                                 ; pop HL
	ret

HDAE5000_HD_Format_Worker:
	; 1. IDENTIFY and HDAE5000_HD_ParseIdentify; blank tables
	;    (HDAE5000_HD_InitTables) written (HDAE5000_HD_WriteTables; error 1).
	;    An IDENTIFY failure loads 6 into A, which the register restore at
	;    the exit discards: 0x200222 keeps ATA_IdentifyDevice's own code.
	; 2. Zero the 3,906 sectors from the FAT start 0x229C68 (= 2) -- the whole
	;    FAT area, up to the tables at 3908 (write error 2) -- then read every
	;    one back and compare it with the zero buffer 0x200228 (3 = read
	;    error, 4 = mismatch).
	; 3. Build the settings sector (HDAE5000_HD_BuildSettingsSector) and write
	;    it to sector 1 (error 5).
	; 4. Remount as HDAE5000_HD_Init does: soft reset (11), IDENTIFY (6), read
	;    sector 1 (7), signature (8), its six setting bytes to 0x229DA9..AE,
	;    free clusters (9), tables (10).
	; Codes go to the drive error byte 0x200222; always ends with
	; HDAE5000_ATA_Standby.
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	call HDAE5000_ATA_IdentifyDevice
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	z, (.LHD_Format_Worker_Skip1:24)
	ld	a, 0x06:opc
	jp HDAE5000_HD_Format_Exit                             ; jp 0x29888a
.LHD_Format_Worker_Skip1:
	call HDAE5000_HD_ParseIdentify
	call HDAE5000_HD_InitTables
	call HDAE5000_HD_WriteTables
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	z, (.LHD_Format_Worker_Skip2:24)
	ld	(HDAE5000_RAM_AtaError:24), 1
	jp HDAE5000_HD_Format_Exit                             ; jp 0x29888a
.LHD_Format_Worker_Skip2:
	lda xix, (0x200228:24)
	call HDAE5000_HD_ZeroSector
	ld	xwa, (HDAE5000_RAM_FatStartSector)
	ld	(0x229c8c), xwa
	xor	xwa, xwa
	ld	(0x229c90), xwa
HDAE5000_HD_Format_ClearLoop:
	ld	xwa, (0x229c90)
	cp	xwa, 0x00000f42
	jp	z, (.LHD_Format_ClearLoop_Skip2:24)
	ld	xhl, (0x229c8c)
	lda xix, (0x200228:24)
	call HDAE5000_ATA_WriteSector
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	z, (.LHD_Format_ClearLoop_Skip1:24)
	ld	(HDAE5000_RAM_AtaError:24), 2
	jp HDAE5000_HD_Format_Exit                             ; jp 0x29888a
.LHD_Format_ClearLoop_Skip1:
	ld	xwa, (0x229c8c)
	add	xwa, 0x00000001
	ld	(0x229c8c), xwa
	ld	xwa, (0x229c90)
	add	xwa, 0x00000001
	ld	(0x229c90), xwa
	jp HDAE5000_HD_Format_ClearLoop                             ; jp 0x29868f
.LHD_Format_ClearLoop_Skip2:
	ld	xwa, (HDAE5000_RAM_FatStartSector)
	ld	(0x229c8c), xwa
	xor	xwa, xwa
	ld	(0x229c90), xwa
HDAE5000_HD_Format_VerifyLoop:
	ld	xwa, (0x229c90)
	cp	xwa, 0x00000f42
	jp	z, (.LHD_Format_CompareLoop_Skip2:24)
	ld	xhl, (0x229c8c)
	ld	xde, 0x00000200
	lda xix, (0x200428:24)
	call HDAE5000_ATA_ReadSector
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	z, (.LHD_Format_VerifyLoop_Skip1:24)
	ld	(HDAE5000_RAM_AtaError:24), 3
	jp HDAE5000_HD_Format_Exit                             ; jp 0x29888a
.LHD_Format_VerifyLoop_Skip1:
	lda xix, (0x200228:24)
	lda xiy, (0x200428:24)
	ld	bc, 0:i3
HDAE5000_HD_Format_CompareLoop:
	cp	bc, 0x0200
	jp	z, (.LHD_Format_CompareLoop_Skip1:24)
	ld_sril3 xwa, 0x07, 0xF0, 0xE4	; ld XWA,(XIX+BC)
	cpl_sri_rm xwa, 0x07, 0xF4, 0xE4	; cp XWA,(XIY+BC)
	jr z, .LDSR_875a                       ; [66 0a] jr Z,0x29875a
	ld	(HDAE5000_RAM_AtaError:24), 4
	jp HDAE5000_HD_Format_Exit                             ; jp 0x29888a
.LDSR_875a:
	inc	4, bc
	jp HDAE5000_HD_Format_CompareLoop                             ; jp 0x29873b
.LHD_Format_CompareLoop_Skip1:
	ld	xwa, (0x229c8c)
	add	xwa, 0x00000001
	ld	(0x229c8c), xwa
	ld	xwa, (0x229c90)
	add	xwa, 0x00000001
	ld	(0x229c90), xwa
	jp HDAE5000_HD_Format_VerifyLoop                             ; jp 0x2986f7
.LHD_Format_CompareLoop_Skip2:
	call HDAE5000_HD_BuildSettingsSector
	ld	xhl, 1:i3
	lda xix, (0x200628:24)
	call HDAE5000_ATA_WriteSector
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	z, (.LHD_Format_CompareLoop_Skip3:24)
	ld	(HDAE5000_RAM_AtaError:24), 5
	jp HDAE5000_HD_Format_Exit                             ; jp 0x29888a
.LHD_Format_CompareLoop_Skip3:
	call HDAE5000_ATA_SoftReset
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	z, (.LHD_Format_CompareLoop_Skip4:24)
	ld	(HDAE5000_RAM_AtaError:24), 11
	jp HDAE5000_HD_Format_Exit                             ; jp 0x29888a
.LHD_Format_CompareLoop_Skip4:
	call HDAE5000_ATA_IdentifyDevice
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	z, (.LHD_Format_CompareLoop_Skip5:24)
	ld	(HDAE5000_RAM_AtaError:24), 6
	jp HDAE5000_HD_Format_Exit                             ; jp 0x29888a
.LHD_Format_CompareLoop_Skip5:
	call HDAE5000_HD_ParseIdentify
	ld	xhl, 1:i3
	lda xix, (0x200628:24)
	ld	xde, 0x00000200
	call HDAE5000_ATA_ReadSector
	cp	(HDAE5000_RAM_AtaError:24), 0
	jr z, .LDSR_8800                       ; [66 0a] jr Z,0x298800
	ld	(HDAE5000_RAM_AtaError:24), 7
	jp HDAE5000_HD_Format_Exit                             ; jp 0x29888a
.LDSR_8800:
	call HDAE5000_HD_CheckSignature
	cp	(HDAE5000_RAM_HdSignatureOk:24), 1
	jp	z, (.LHD_Format_CompareLoop_Skip6:24)
	ld	(HDAE5000_RAM_AtaError:24), 8
	jp HDAE5000_HD_Format_Exit                             ; jp 0x29888a
.LHD_Format_CompareLoop_Skip6:
	ld	xix, 0x002006a0
	ld	a, (xix)
	ld	(HDAE5000_RAM_QuickLoadMode:24), a
	inc 1, xix                              ; inc 1,XIX
	ld	a, (xix)
	ld	(HDAE5000_RAM_LoadByNumberMode:24), a
	inc 1, xix                              ; inc 1,XIX
	ld	a, (xix)
	ld	(HDAE5000_RAM_JumpAfterLoad:24), a
	inc 1, xix                              ; inc 1,XIX
	ld	a, (xix)
	ld	(HDAE5000_RAM_LyricJump:24), a
	inc 1, xix                              ; inc 1,XIX
	ld	a, (xix)
	ld	(HDAE5000_RAM_LyricForeColor:24), a
	inc 1, xix                              ; inc 1,XIX
	ld	a, (xix)
	ld	(HDAE5000_RAM_LyricBackColor:24), a
	call HDAE5000_HD_CountFreeClusters
	cp	(HDAE5000_RAM_AtaError:24), 0
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	z, (.LHD_Format_CompareLoop_Skip7:24)
	ld	(HDAE5000_RAM_AtaError:24), 9
	jp HDAE5000_HD_Format_Exit                             ; jp 0x29888a
.LHD_Format_CompareLoop_Skip7:
	call HDAE5000_HD_ReadTables
	cp	(HDAE5000_RAM_AtaError:24), 0
	jp	z, (HDAE5000_HD_Format_Exit:24)
	ld	(HDAE5000_RAM_AtaError:24), 10
	jp HDAE5000_HD_Format_Exit                             ; jp 0x29888a
HDAE5000_HD_Format_Exit:
	call HDAE5000_ATA_Standby
	pop xiz                                 ; pop XIZ
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	pop xhl                                 ; pop XHL
	pop xde                                 ; pop XDE
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

HDAE5000_HD_ZeroSector:
	; 512 zero bytes at XIX
	ld	a, 0x00:opc
	xor	bc, bc
HDAE5000_HD_ZeroSector_Loop:
	cp	bc, 0x0200
	jp	z, (.LHD_ZeroSector_Return1:24)
	stb_dri a, 0x07, 0xF0, 0xE4	; ld (XIX+BC),A
	inc	1, bc
	jp HDAE5000_HD_ZeroSector_Loop                             ; jp 0x29889a
.LHD_ZeroSector_Return1:
	ret

HDAE5000_HD_BuildSettingsSector:
	; Build a fresh sector-1 image at 0x200628: zeroed, the signature
	; AA55AA55 F4F1F2F3, the 112-byte HDAE5000_Version_Info, the six setting
	; bytes = 1 (also stored to 0x229DA9..AE), then 0xFFFFFFFF.  The format's
	; counterpart of HDAE5000_HD_SaveSettings, which writes the current
	; settings instead of 1s.
	lda xix, (0x200628:24)
	call HDAE5000_HD_ZeroSector
	lda xix, (0x200628:24)
	ld	xwa, 0xaa55aa55
	ld (xix), xwa                           ; ld (XIX),XWA
	inc 4, xix                              ; inc 4,XIX
	ld	xwa, 0xf4f1f2f3
	ld (xix), xwa                           ; ld (XIX),XWA
	inc 4, xix                              ; inc 4,XIX
	lda xiy, (HDAE5000_Version_Info:24)
	lda xiz, (HDAE5000_Version_Info_End:24)
HDAE5000_HD_BuildSettingsSector_CopyVersion:
	cp	xiy, xiz
	jp	z, (.LHD_BuildSettingsSector_CopyVersion_Skip1:24)
	ld	a, (xiy)
	ld	(xix), a
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp HDAE5000_HD_BuildSettingsSector_CopyVersion                             ; jp 0x2988d9
.LHD_BuildSettingsSector_CopyVersion_Skip1:
	ld	(xix), 0x01
	ld	(HDAE5000_RAM_QuickLoadMode:24), 1
	inc 1, xix                              ; inc 1,XIX
	ld	(xix), 0x01
	ld	(HDAE5000_RAM_LoadByNumberMode:24), 1
	inc 1, xix                              ; inc 1,XIX
	ld	(xix), 0x01
	ld	(HDAE5000_RAM_JumpAfterLoad:24), 1
	inc 1, xix                              ; inc 1,XIX
	ld	(xix), 0x01
	ld	(HDAE5000_RAM_LyricJump:24), 1
	inc 1, xix                              ; inc 1,XIX
	ld	(xix), 0x01
	ld	(HDAE5000_RAM_LyricForeColor:24), 1
	inc 1, xix                              ; inc 1,XIX
	ld	(xix), 0x01
	ld	(HDAE5000_RAM_LyricBackColor:24), 1
	inc 1, xix                              ; inc 1,XIX
	ld	xwa, 0xffffffff
	ld (xix), xwa                           ; ld (XIX),XWA
	ret

	ld	xix, (0x229d80)
	lda xiy, (0x201556:24)
	ld	bc, 0:i3
HDAE5000_DeadLib_Block64Differs_Loop:
	cp	bc, 0x0040
	jp	z, (.LHD_BuildSettingsSector_CopyVersion_Skip3:24)
	ld	a, (xix)
	cp	a, (xiy)
	jp	nz, (.LHD_BuildSettingsSector_CopyVersion_Skip2:24)
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	inc	1, bc
	jp HDAE5000_DeadLib_Block64Differs_Loop                             ; jp 0x298942
.LHD_BuildSettingsSector_CopyVersion_Skip2:
	ld	a, 0x01:opc
	jp HDAE5000_DeadLib_Block64Differs_Return                             ; jp 0x298966
.LHD_BuildSettingsSector_CopyVersion_Skip3:
	ld	a, 0x00:opc
HDAE5000_DeadLib_Block64Differs_Return:
	ret

	push xix
	push xiy
	push xbc
	push xwa
	ld	bc, 0:i3
	lda xix, (0x200c98:24)
	lda xiy, (0x201538:24)
HDAE5000_DeadLib_CopyName26_Loop:
	cp	bc, 0x001a
	jp	z, (.LHD_BuildSettingsSector_CopyVersion_Skip4:24)
	ld	a, (xiy)
	ld	(xix), a
	inc	1, bc
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp HDAE5000_DeadLib_CopyName26_Loop                             ; jp 0x298977
.LHD_BuildSettingsSector_CopyVersion_Skip4:
	pop xwa                                 ; pop XWA
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

HDAE5000_HD_ResetVersionKeyWord:
	; RAM 0x229C60 = 0x0000FFEE: the long HDAE5000_HD_CheckVersionKey compares
	; with the "XXXX" of HDAE5000_Version_Key.  Called by
	; HDAE5000_HD_CheckSignature.
	ld	xwa, 0x0000ffee
	ld	(0x229c60), xwa
	ret

; ----------------------------------------------------------------------------
; UNREACHABLE CODE, 0x298936-0x298B6B and 0x298C52-0x298C7C, 0x298CBC-0x29992A
; minus the live routines labelled in it (HDAE5000_HD_GetDiskUsage,
; HDAE5000_HD_ComputeDiskUsage, HDAE5000_HD_ClearStatusBytes,
; HDAE5000_HD_ClusterCount, HDAE5000_HD_BytesToClusters,
; HDAE5000_HD_CheckVersionKey, HDAE5000_HD_LoadSettings,
; HDAE5000_HD_SaveSettings):
; no path from any entry reaches it (scripts/analysis/hdae5000_reachability.py:
; no symbolic or numeric operand, no .long pointer, no switch table names
; it).  It is a browser/name-history library over the in-RAM tables that
; HDAE5000_HD_GetBlockInfo describes -- a cursor per page of 24 rows for the
; directory names (page 0x229D9F, cursors 0x229DDA[5], per-row byte
; 0x229DDF[120]) and for the FLS rows (page 0x229DA0, cursors 0x229E57[5],
; per-row byte 0x229E5C[120]), 5-deep rings of recent names (0x201434 x26,
; 0x2013B2 x16, 0x2014B6 x16, indexes 0x229DC2..0x229DC7) and the name
; buffers 0x200C98 / 0x200870.  Routines with no label are left unlabelled;
; labels inside them carry the prefix HDAE5000_DeadLib_.  Some of it does
; not fit the live layout (it uses 0x229C94, the data-sector count of
; HDAE5000_HD_ParseIdentify, as a pointer), so it may predate it.
; ----------------------------------------------------------------------------
HDAE5000_NameList5_Contains:
	; A = 1 if the 26 bytes at XIY equal one of the five 26-byte entries at XIX, else 0 (unreachable)
	ld	xbc, 0:i3
HDAE5000_NameList5_Contains_EntryLoop:
	cp	xbc, 0x00000005
	jp	z, (.LNameList5_Contains_CharLoop_Skip3:24)
	ld	xhl, 0:i3
HDAE5000_NameList5_Contains_CharLoop:
	cp	xhl, 0x0000001a
	jp	z, (.LNameList5_Contains_CharLoop_Skip2:24)
	ldb_sri a, 0x07, 0xF4, 0xEC	; ld A,(XIY+HL)
	cpb_sri_mr a, 0x07, 0xF0, 0xEC	; cp (XIX+HL),A
	jp	nz, (.LNameList5_Contains_CharLoop_Skip1:24)
	inc 1, xhl                              ; inc 1,XHL
	jp HDAE5000_NameList5_Contains_CharLoop                             ; jp 0x2989ad
.LNameList5_Contains_CharLoop_Skip1:
	add	xix, 0x0000001a
	inc 1, xbc                              ; inc 1,XBC
	jp HDAE5000_NameList5_Contains_EntryLoop                             ; jp 0x2989a0
.LNameList5_Contains_CharLoop_Skip2:
	ld	a, 0x01:opc
	jp HDAE5000_NameList5_Contains_Return                             ; jp 0x2989e1
.LNameList5_Contains_CharLoop_Skip3:
	ld	a, 0x00:opc
HDAE5000_NameList5_Contains_Return:
	ret

HDAE5000_Name26_IsBlank:
	; A = 1 if the 26 bytes at XIX are all spaces, else 0 (unreachable)
	ld	xbc, 0:i3
HDAE5000_Name26_IsBlank_Loop:
	cp	xbc, 0x0000001a
	jp	z, (.LName26_IsBlank_Skip1:24)
	cpib_sri 0x07, 0xF0, 0xE4, 0x20	; cp (XIX+BC),0x20
	jp	nz, (.LName26_IsBlank_Skip2:24)
	inc 1, xbc                              ; inc 1,XBC
	jp HDAE5000_Name26_IsBlank_Loop                             ; jp 0x2989e4
.LName26_IsBlank_Skip1:
	ld	a, 0x01:opc
	jp HDAE5000_Name26_IsBlank_Return                             ; jp 0x298a08
.LName26_IsBlank_Skip2:
	ld	a, 0x00:opc
HDAE5000_Name26_IsBlank_Return:
	ret

	push xix
	push xbc
	push xwa
	xor	xwa, xwa
	ld	a, (0x229D9E:24)
	add	xix, xwa
	ld	c, (xix)
	lda xix, (0x200c98:24)
	xor	xwa, xwa
	ld	a, (0x229D9D:24)
	add	xix, xwa
	ld	(xix), c
	pop xwa                                 ; pop XWA
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

HDAE5000_Field12_FillZeros:
	; fill the 12-byte field 0x200864 with "0" (unreachable)
	push xix
	push xbc
	lda xix, (0x200864:24)
	ld	bc, 0:i3
HDAE5000_Field12_FillZeros_Loop:
	cp	bc, 0x000c
	jp	z, (.LField12_FillZeros_Skip1:24)
	stib_ind 0x07, 0xF0, 0xE4, 0x30	; ld (XIX+BC),0x30
	inc	1, bc
	jp HDAE5000_Field12_FillZeros_Loop                             ; jp 0x298a34
.LField12_FillZeros_Skip1:
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

HDAE5000_Field12_FillSpaces:
	; fill the 12-byte field 0x200864 with spaces (unreachable)
	push xix
	push xbc
	lda xix, (0x200864:24)
	ld	bc, 0:i3
HDAE5000_Field12_FillSpaces_Loop:
	cp	bc, 0x000c
	jp	z, (.LField12_FillSpaces_Skip1:24)
	stib_ind 0x07, 0xF0, 0xE4, 0x20	; ld (XIX+BC),0x20
	inc	1, bc
	jp HDAE5000_Field12_FillSpaces_Loop                             ; jp 0x298a55
.LField12_FillSpaces_Skip1:
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

	push xix
	push xbc
	lda xix, (0x200870:24)
	ld	bc, 0:i3
HDAE5000_DeadLib_Fill40Spaces_Loop:
	cp	bc, 0x0028
	jp	z, (.LField12_FillSpaces_Skip2:24)
	stib_ind 0x07, 0xF0, 0xE4, 0x20	; ld (XIX+BC),0x20
	inc	1, bc
	jp HDAE5000_DeadLib_Fill40Spaces_Loop                             ; jp 0x298a76
.LField12_FillSpaces_Skip2:
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

HDAE5000_FormatDecimal12_ZeroFill:
	; XWA in decimal, right-aligned in the field ending at 0x20086E, zero-filled; digits from HDAE5000_DecimalDigits (unreachable)
	push xix
	push xiy
	push xde
	push xbc
	call HDAE5000_Field12_FillZeros
HDAE5000_FormatDecimal12_Digits:
	ld	xde, 0:i3
.LFormatDecimal12_Digits_Loop1:
	ld	xbc, 0x0000000a
	call HDAE5000_HD_UDiv32
	push xbc
	inc 1, xde                              ; inc 1,XDE
	cp	xwa, 0x00000000
	jp	nz, (.LFormatDecimal12_Digits_Loop1:24)
	lda xix, (0x20086e:24)
	sub	xix, xde
.LFormatDecimal12_Digits_Loop2:
	lda xiy, (HDAE5000_DecimalDigits:24)
	pop xbc                                 ; pop XBC
	ld	qbc, 0
	add	xiy, xbc
	ld	a, (xiy)
	ld	(xix), a
	inc 1, xix                              ; inc 1,XIX
	dec	1, xde
	cp	xde, 0x00000000
	jp	nz, (.LFormatDecimal12_Digits_Loop2:24)
	pop xbc                                 ; pop XBC
	pop xde                                 ; pop XDE
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xde
	push xbc
	call HDAE5000_Field12_FillSpaces
	jp HDAE5000_FormatDecimal12_Digits                             ; jp 0x298a96
	push xwa
	push xbc
	ld	xwa, 6:i3
HDAE5000_DeadLib_Delay6x4095_Outer:
	cp	xwa, 0x00000000
	jp	z, (.LDeadLib_Delay6x4095_Inner_Skip2:24)
	ld	xbc, 0:i3
HDAE5000_DeadLib_Delay6x4095_Inner:
	cp	xbc, 0x00000fff
	jp	z, (.LDeadLib_Delay6x4095_Inner_Skip1:24)
	inc 1, xbc                              ; inc 1,XBC
	jp HDAE5000_DeadLib_Delay6x4095_Inner                             ; jp 0x298af6
.LDeadLib_Delay6x4095_Inner_Skip1:
	dec	1, xwa
	jp HDAE5000_DeadLib_Delay6x4095_Outer                             ; jp 0x298ae9
.LDeadLib_Delay6x4095_Inner_Skip2:
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

	push xwa
	push xbc
	ld	xwa, 0x00000046
HDAE5000_DeadLib_Delay70x4095_Outer:
	cp	xwa, 0x00000000
	jp	z, (.LDeadLib_Delay70x4095_Inner_Skip2:24)
	ld	xbc, 0:i3
HDAE5000_DeadLib_Delay70x4095_Inner:
	cp	xbc, 0x00000fff
	jp	z, (.LDeadLib_Delay70x4095_Inner_Skip1:24)
	inc 1, xbc                              ; inc 1,XBC
	jp HDAE5000_DeadLib_Delay70x4095_Inner                             ; jp 0x298b24
.LDeadLib_Delay70x4095_Inner_Skip1:
	dec	1, xwa
	jp HDAE5000_DeadLib_Delay70x4095_Outer                             ; jp 0x298b17
.LDeadLib_Delay70x4095_Inner_Skip2:
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

	push xwa
	push xbc
	ld	xwa, 0x00000025
HDAE5000_DeadLib_Delay37x4095_Outer:
	cp	xwa, 0x00000000
	jp	z, (.LDeadLib_Delay37x4095_Inner_Skip2:24)
	ld	xbc, 0:i3
HDAE5000_DeadLib_Delay37x4095_Inner:
	cp	xbc, 0x00000fff
	jp	z, (.LDeadLib_Delay37x4095_Inner_Skip1:24)
	inc 1, xbc                              ; inc 1,XBC
	jp HDAE5000_DeadLib_Delay37x4095_Inner                             ; jp 0x298b52
.LDeadLib_Delay37x4095_Inner_Skip1:
	dec	1, xwa
	jp HDAE5000_DeadLib_Delay37x4095_Outer                             ; jp 0x298b45
.LDeadLib_Delay37x4095_Inner_Skip2:
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

HDAE5000_HD_GetDiskUsage:
	; XWA = destination of four longs, each in units of 10,000 bytes
	; (HDAE5000_HD_ComputeDiskUsage): +0 the drive (0x200223 sectors), +4 the
	; system area (data-area start 0x229C6C + 1 sectors), +8 the data area
	; (cluster bytes x FAT entries 0x229C70), +12 the free space (cluster
	; bytes x free clusters 0x229C80).
	push xiz
	call HDAE5000_HD_ComputeDiskUsage
	ld	xbc, (0x229d18)
	ld (xwa), xbc                           ; ld (XWA),XBC
	ld	xbc, (0x229d1c)
	ld (xwa + 0x04), xbc                    ; ld (XWA+0x04),XBC
	ld	xbc, (0x229d10)
	ld (xwa + 0x08), xbc                    ; ld (XWA+0x08),XBC
	ld	xbc, (0x229d14)
	ld (xwa + 0x0c), xbc                    ; ld (XWA+0x0c),XBC
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_HD_ComputeDiskUsage:
	; fills 0x229D18 (drive), 0x229D1C (system area), 0x229D10 (data area), 0x229D14 (free) for HDAE5000_HD_GetDiskUsage
	push xwa
	push xbc
	ld	xwa, (0x200223)
	ld	xbc, 0x00000200
	call HDAE5000_HD_Mul32
	ld	xbc, 0x00002710
	call HDAE5000_HD_UDiv32
	ld	(0x229d18), xwa
	ld	xwa, (HDAE5000_RAM_DataStartSector)
	dec	1, xwa
	add	xwa, 0x00000002
	ld	xbc, 0x00000200
	call HDAE5000_HD_Mul32
	ld	xbc, 0x00002710
	call HDAE5000_HD_UDiv32
	ld	(0x229d1c), xwa
	ld	xwa, (HDAE5000_RAM_SectorsPerCluster)
	ld	xbc, 0x00000200
	call HDAE5000_HD_Mul32
	push xwa
	ld	xbc, (HDAE5000_RAM_FatEntryCount)
	call HDAE5000_HD_Mul32
	ld	xbc, 0x00002710
	call HDAE5000_HD_UDiv32
	ld	(0x229d10), xwa
	pop xwa                                 ; pop XWA
	ld	xbc, (HDAE5000_RAM_FreeClusters)
	call HDAE5000_HD_Mul32
	ld	xbc, 0x00002710
	call HDAE5000_HD_UDiv32
	ld	(0x229d14), xwa
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

HDAE5000_HD_ClearStatusBytes:
	; zero the ten bytes 0x229DAF..0x229DB8.  No reader of them was found
	; (each address literal searched in all seven hdae5000 sources).
	; Callers: HDAE5000_HD_Init, HDAE5000_HD_Format.
	ld	(0x229DAF:24), 0
	ld	(0x229DB0:24), 0
	ld	(0x229DB1:24), 0
	ld	(0x229DB2:24), 0
	ld	(0x229DB3:24), 0
	ld	(0x229DB4:24), 0
	ld	(0x229DB5:24), 0
	ld	(0x229DB6:24), 0
	ld	(0x229DB7:24), 0
	ld	(0x229DB8:24), 0
	ret

HDAE5000_NameBuf_IsNotBlank:
	; A = 1 if the 26-byte name buffer 0x200C98 holds a non-space, else 0 (unreachable)
	push xbc
	push xix
	ld	a, 0x00:opc
	ld	xbc, 0:i3
	ld	xix, 0x00200c98
HDAE5000_NameBuf_IsNotBlank_Loop:
	cp	xbc, 0x0000001a
	jp	z, (.LNameBuf_IsNotBlank_Skip2:24)
	cp	(xix), 0x20
	jp	nz, (.LNameBuf_IsNotBlank_Skip1:24)
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	jp HDAE5000_NameBuf_IsNotBlank_Loop                             ; jp 0x298c5d
.LNameBuf_IsNotBlank_Skip1:
	ld	a, 0x01:opc
.LNameBuf_IsNotBlank_Skip2:
	pop xix                                 ; pop XIX
	pop xbc                                 ; pop XBC
	ret

HDAE5000_HD_ClusterCount:
	; XWA = byte count -> XHL = clusters needed (HDAE5000_HD_BytesToClusters)
	push xiz
	call HDAE5000_HD_BytesToClusters
	ld	xhl, xwa
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_HD_BytesToClusters:
	; XWA = ceil(XWA / cluster bytes 0x229C58)
	ld	xbc, (HDAE5000_RAM_ClusterBytes)
	call HDAE5000_HD_UDiv32
	cp	xbc, 0x00000000
	jp	z, (.LHD_BytesToClusters_Return1:24)
	inc 1, xwa                              ; inc 1,XWA
.LHD_BytesToClusters_Return1:
	ret

HDAE5000_HD_CheckVersionKey:
	; compares the long at HDAE5000_Version_Key ("XXXX") with RAM 0x229C60;
	; on a mismatch it pops one extra long and returns to its caller's
	; caller.  Not called directly: HDAE5000_HD_Init stores its address in
	; RAM 0x229D6C (`lda xwa,(...)` / `ld (0x229d6c),xwa`), and no read of
	; 0x229D6C was found in this ROM (searched the literal).
	push xwa
	push xbc
	push xix
	lda xix, (HDAE5000_Version_Key:24)
	ld xwa, (xix)                           ; ld XWA,(XIX)
	ld	xbc, (0x229c60)
	cp	xwa, xbc
	jp	z, (.LHD_CheckVersionKey_Skip1:24)
	pop xix                                 ; pop XIX
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	pop xwa                                 ; pop XWA
	ret

.LHD_CheckVersionKey_Skip1:
	pop xix                                 ; pop XIX
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

	xor	xwa, xwa
	xor	xbc, xbc
	ld	wa, (0x229C4E:24)
	dec	1, wa
	ld	xbc, 0x000004c0
	call HDAE5000_HD_Mul32
	ld	xix, xwa
	xor	xwa, xwa
	ld	wa, (0x229C50:24)
	dec	1, wa
	ld	xbc, 0x0000004c
	call HDAE5000_HD_Mul32
	add	xix, xwa
	lda xwa, (HDAE5000_RAM_SongRecords:24)
	add	xix, xwa
	ld	(0x229cf0), xix
	ret

	lda xix, (0x201556:24)
	ld	bc, 0:i3
HDAE5000_DeadLib_FindFreeSlot32_Loop:
	cp	bc, 0x0020
	jp	z, (.LHD_CheckVersionKey_Skip3:24)
	ld xiy, (xix + 0x04)                    ; ld XIY,(XIX+0x04)
	cp	xiy, 0x00000000
	jp	nz, (.LHD_CheckVersionKey_Skip2:24)
	ld	xwa, xix
	jp HDAE5000_DeadLib_FindFreeSlot32_Return                             ; jp 0x298d25
.LHD_CheckVersionKey_Skip2:
	add	xix, 0x00000008
	inc	1, bc
	jp HDAE5000_DeadLib_FindFreeSlot32_Loop                             ; jp 0x298cfa
.LHD_CheckVersionKey_Skip3:
	ld	xwa, 0:i3
HDAE5000_DeadLib_FindFreeSlot32_Return:
	ret

	ld	(0x229DC8:24), 0
	call HDAE5000_DirBrowser_GetRowByte
	cp	a, 0x0f
	jp	c, (.LHD_CheckVersionKey_Skip4:24)
	jp HDAE5000_DeadLib_SelectNextFile_NextDir                             ; jp 0x298d44
.LHD_CheckVersionKey_Skip4:
	call HDAE5000_DirBrowser_IncRowByte
	jp HDAE5000_DeadLib_SelectNextFile_Return                             ; jp 0x298d8e
HDAE5000_DeadLib_SelectNextFile_NextDir:
	xor	xwa, xwa
	ld	a, (0x229D9F:24)
	ld	xbc, 0x00000018
	call HDAE5000_HD_Mul32
	ld	xix, xwa
	xor	xwa, xwa
	call HDAE5000_DirBrowser_GetCursor
	add	xwa, xix
	cp	xwa, 0x00000077
	jp	z, (HDAE5000_DeadLib_SelectNextFile_Return:24)
	call HDAE5000_DirBrowser_GetCursor
	cp	a, 0x17
	jp	c, (.LDeadLib_SelectNextFile_NextDir_Skip1:24)
	inc	1, (0x229D9F:24)
	call HDAE5000_DirBrowser_ClearCursor
	call HDAE5000_DirBrowser_ClearRowByte
	jp HDAE5000_DeadLib_SelectNextFile_Return                             ; jp 0x298d8e
.LDeadLib_SelectNextFile_NextDir_Skip1:
	call HDAE5000_DirBrowser_IncCursor
	call HDAE5000_DirBrowser_ClearRowByte
HDAE5000_DeadLib_SelectNextFile_Return:
	ret

	ld	(0x229DC8:24), 0
	call HDAE5000_FlsBrowser_GetRowByte
	cp	a, 0x1f
	jp	c, (.LDeadLib_SelectNextFile_NextDir_Skip2:24)
	jp HDAE5000_DeadLib_SelectNextFlsItem_NextRow                             ; jp 0x298dad
.LDeadLib_SelectNextFile_NextDir_Skip2:
	call HDAE5000_FlsBrowser_IncRowByte
	jp HDAE5000_DeadLib_SelectNextFlsItem_Return                             ; jp 0x298e17
HDAE5000_DeadLib_SelectNextFlsItem_NextRow:
	xor	xwa, xwa
	ld	a, (0x229DA0:24)
	ld	xbc, 0x00000018
	call HDAE5000_HD_Mul32
	ld	xix, xwa
	xor	xwa, xwa
	call HDAE5000_FlsBrowser_GetCursor
	add	xwa, xix
	cp	xwa, 0x00000077
	jp	z, (HDAE5000_DeadLib_SelectNextFlsItem_Return:24)
	call HDAE5000_FlsBrowser_GetCursor
	cp	a, 0x17
	jp	c, (.LDeadLib_SelectNextFlsItem_NextRow_Skip1:24)
	inc	1, (0x229DA0:24)
	call HDAE5000_FlsBrowser_ClearCursor
	call HDAE5000_FlsBrowser_ClearRowByte
	call HDAE5000_FlsBrowser_RowAddress
	ld	xbc, 0x00000010
	add	xwa, xbc
	ld	(0x229d7c), xwa
	jp HDAE5000_DeadLib_SelectNextFlsItem_Return                             ; jp 0x298e17
.LDeadLib_SelectNextFlsItem_NextRow_Skip1:
	call HDAE5000_FlsBrowser_IncCursor
	call HDAE5000_FlsBrowser_ClearRowByte
	call HDAE5000_FlsBrowser_RowAddress
	ld	xbc, 0x00000010
	add	xwa, xbc
	ld	(0x229d7c), xwa
HDAE5000_DeadLib_SelectNextFlsItem_Return:
	ret

	lda xix, (0x2257c2:24)
	ld	xiy, 0:i3
HDAE5000_DeadLib_ClearRefsToEntry_RowLoop:
	cp	xiy, 0x00000078
	jp	z, (.LDeadLib_ClearRefsToEntry_ItemLoop_Return1:24)
	ld	bc, 0:i3
HDAE5000_DeadLib_ClearRefsToEntry_ItemLoop:
	cp	bc, 0x0020
	jp	z, (.LDeadLib_ClearRefsToEntry_ItemLoop_Skip2:24)
	ld xwa, (xix + 0x04)                    ; ld XWA,(XIX+0x04)
	cp	xwa, (0x229cf0)
	jp	nz, (.LDeadLib_ClearRefsToEntry_ItemLoop_Skip1:24)
	xor	xwa, xwa
	ld (xix), xwa                           ; ld (XIX),XWA
	ld (xix + 0x04), xwa                    ; ld (XIX+0x04),XWA
.LDeadLib_ClearRefsToEntry_ItemLoop_Skip1:
	add	xix, 0x00000002
	inc	1, bc
	jp HDAE5000_DeadLib_ClearRefsToEntry_ItemLoop                             ; jp 0x298e2c
.LDeadLib_ClearRefsToEntry_ItemLoop_Skip2:
	add	xix, 0x00000010
	inc 1, xiy                              ; inc 1,XIY
	jp HDAE5000_DeadLib_ClearRefsToEntry_RowLoop                             ; jp 0x298e1f
.LDeadLib_ClearRefsToEntry_ItemLoop_Return1:
	ret

	ld	xix, (HDAE5000_RAM_DataSectorCount)
	lda xiy, (0x20158e:24)
HDAE5000_DeadLib_DeleteSlotShift_Loop:
	cp	xix, xiy
	jp	z, (.LDeadLib_ClearRefsToEntry_ItemLoop_Skip3:24)
	ld xwa, (xix + 0x08)                    ; ld XWA,(XIX+0x08)
	ld (xix), xwa                           ; ld (XIX),XWA
	ld xwa, (xix + 0x0c)                    ; ld XWA,(XIX+0x0c)
	ld (xix + 0x04), xwa                    ; ld (XIX+0x04),XWA
	add	xix, 0x00000008
	jp HDAE5000_DeadLib_DeleteSlotShift_Loop                             ; jp 0x298e6c
.LDeadLib_ClearRefsToEntry_ItemLoop_Skip3:
	xor	xwa, xwa
	lda xix, (0x20158e:24)
	ld (xix), xwa                           ; ld (XIX),XWA
	ld (xix + 0x04), xwa                    ; ld (XIX+0x04),XWA
	ret

	ld	xix, (0x229d84)
	add	xix, 0x00000002
	lda xiy, (0x201596:24)
	xor	xwa, xwa
	ld	(0x229d8c), xwa
HDAE5000_DeadLib_FindNextUsedSlot_Loop:
	cp	xix, xiy
	jp	z, (HDAE5000_DeadLib_FindNextUsedSlot_Return:24)
	ld xwa, (xix + 0x04)                    ; ld XWA,(XIX+0x04)
	cp	xwa, 0x00000000
	jp	z, (.LDeadLib_ClearRefsToEntry_ItemLoop_Skip4:24)
	ld	(0x229d8c), xix
	jp HDAE5000_DeadLib_FindNextUsedSlot_Return                             ; jp 0x298ed4
.LDeadLib_ClearRefsToEntry_ItemLoop_Skip4:
	add	xix, 0x00000002
	jp HDAE5000_DeadLib_FindNextUsedSlot_Loop                             ; jp 0x298eac
HDAE5000_DeadLib_FindNextUsedSlot_Return:
	ret

	lda xix, (0x201596:24)
	sub	xix, 0x00000002
	ld	xiy, (0x229d84)
	xor	xwa, xwa
	ld	(0x229d88), xwa
HDAE5000_DeadLib_FindLastFreeSlot_Loop:
	cp	xix, xiy
	jp	z, (HDAE5000_DeadLib_FindLastFreeSlot_Return:24)
	ld xwa, (xix + 0x04)                    ; ld XWA,(XIX+0x04)
	cp	xwa, 0x00000000
	jp	nz, (.LDeadLib_ClearRefsToEntry_ItemLoop_Skip5:24)
	ld	(0x229d88), xix
	jp HDAE5000_DeadLib_FindLastFreeSlot_Return                             ; jp 0x298f14
.LDeadLib_ClearRefsToEntry_ItemLoop_Skip5:
	sub	xix, 0x00000002
	jp HDAE5000_DeadLib_FindLastFreeSlot_Loop                             ; jp 0x298eec
HDAE5000_DeadLib_FindLastFreeSlot_Return:
	ret

	ld	xix, (0x229d88)
	ld	xiy, (0x229d84)
HDAE5000_DeadLib_InsertSlotShift_Loop:
	cp	xix, xiy
	jp	z, (.LDeadLib_ClearRefsToEntry_ItemLoop_Skip6:24)
	ld	xwa, (xix-8)
	ld (xix), xwa                           ; ld (XIX),XWA
	ld	xwa, (xix-4)
	ld (xix + 0x04), xwa                    ; ld (XIX+0x04),XWA
	sub	xix, 0x00000002
	jp HDAE5000_DeadLib_InsertSlotShift_Loop                             ; jp 0x298f1f
.LDeadLib_ClearRefsToEntry_ItemLoop_Skip6:
	xor	xwa, xwa
	ld	xix, (0x229d84)
	ld (xix), xwa                           ; ld (XIX),XWA
	ld (xix + 0x04), xwa                    ; ld (XIX+0x04),XWA
	ret

	push xix
	push xiy
	push xbc
	push xwa
	ld	xbc, 0:i3
	ld	xix, (0x229cf0)
	lda xiy, (0x200c98:24)
HDAE5000_DeadLib_LoadFileName_Loop:
	cp	xbc, 0x0000001a
	jp	z, (.LDeadLib_ClearRefsToEntry_ItemLoop_Skip7:24)
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp HDAE5000_DeadLib_LoadFileName_Loop                             ; jp 0x298f58
.LDeadLib_ClearRefsToEntry_ItemLoop_Skip7:
	pop xwa                                 ; pop XWA
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	push xwa
	ld	xbc, 0:i3
	ld	xix, (0x229cf0)
	lda xiy, (0x200c98:24)
HDAE5000_DeadLib_StoreFileName_Loop:
	cp	xbc, 0x0000001a
	jp	z, (.LDeadLib_ClearRefsToEntry_ItemLoop_Skip8:24)
	ld	a, (xiy)
	ld	(xix), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp HDAE5000_DeadLib_StoreFileName_Loop                             ; jp 0x298f86
.LDeadLib_ClearRefsToEntry_ItemLoop_Skip8:
	pop xwa                                 ; pop XWA
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	call HDAE5000_NameBuf_IsNotBlank
	cp	a, 0:i3
	jp	z, (.LDeadLib_RememberFileName_Copy_Skip2:24)
	lda xix, (0x201434:24)
	lda xiy, (0x200c98:24)
	call HDAE5000_NameList5_Contains
	cp	a, 1:i3
	jp	z, (.LDeadLib_RememberFileName_Copy_Skip2:24)
	cp	(0x229DC3:24), 5
	jp	c, (.LDeadLib_ClearRefsToEntry_ItemLoop_Skip9:24)
	ld	(0x229DC3:24), 0
.LDeadLib_ClearRefsToEntry_ItemLoop_Skip9:
	lda xix, (0x201434:24)
	xor	xwa, xwa
	ld	a, (0x229DC3:24)
	ld	xbc, 0x0000001a
	call HDAE5000_HD_Mul32
	add	xix, xwa
	lda xiy, (0x200c98:24)
	ld	xbc, 0:i3
HDAE5000_DeadLib_RememberFileName_Copy:
	cp	xbc, 0x0000001a
	jp	z, (.LDeadLib_RememberFileName_Copy_Skip1:24)
	ld	a, (xiy)
	ld	(xix), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp HDAE5000_DeadLib_RememberFileName_Copy                             ; jp 0x298ff6
.LDeadLib_RememberFileName_Copy_Skip1:
	inc	1, (0x229DC3:24)
.LDeadLib_RememberFileName_Copy_Skip2:
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	lda xix, (0x201434:24)
	ld	xiy, (0x229cf0)
	call HDAE5000_NameList5_Contains
	cp	a, 1:i3
	jp	z, (.LDeadLib_RememberEntryName_Copy_Skip2:24)
	cp	(0x229DC3:24), 5
	jp	c, (.LDeadLib_RememberFileName_Copy_Skip3:24)
	ld	(0x229DC3:24), 0
.LDeadLib_RememberFileName_Copy_Skip3:
	lda xix, (0x201434:24)
	xor	xwa, xwa
	ld	a, (0x229DC3:24)
	ld	xbc, 0x0000001a
	call HDAE5000_HD_Mul32
	add	xix, xwa
	ld	xiy, (0x229cf0)
	ld	xbc, 0:i3
HDAE5000_DeadLib_RememberEntryName_Copy:
	cp	xbc, 0x0000001a
	jp	z, (.LDeadLib_RememberEntryName_Copy_Skip1:24)
	ld	a, (xiy)
	ld	(xix), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp HDAE5000_DeadLib_RememberEntryName_Copy                             ; jp 0x29905f
.LDeadLib_RememberEntryName_Copy_Skip1:
	inc	1, (0x229DC3:24)
.LDeadLib_RememberEntryName_Copy_Skip2:
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	cp	(0x229DC6:24), 5
	jp	c, (.LDeadLib_RememberEntryName_Copy_Skip3:24)
	ld	(0x229DC6:24), 0
.LDeadLib_RememberEntryName_Copy_Skip3:
	lda xix, (0x201434:24)
	xor	xwa, xwa
	ld	a, (0x229DC6:24)
	ld	xbc, 0x0000001a
	call HDAE5000_HD_Mul32
	add	xix, xwa
	push xix
	call HDAE5000_Name26_IsBlank
	pop xix                                 ; pop XIX
	cp	a, 1:i3
	jp	nz, (.LDeadLib_RememberEntryName_Copy_Skip4:24)
	ld	(0x229DC6:24), 0
	jp HDAE5000_DeadLib_RecallRecentFileName_Exit                             ; jp 0x2990e8
.LDeadLib_RememberEntryName_Copy_Skip4:
	lda xiy, (0x200c98:24)
	ld	xbc, 0:i3
HDAE5000_DeadLib_RecallRecentFileName_Copy:
	cp	xbc, 0x0000001a
	jp	z, (.LDeadLib_RecallRecentFileName_Copy_Skip1:24)
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp HDAE5000_DeadLib_RecallRecentFileName_Copy                             ; jp 0x2990ca
.LDeadLib_RecallRecentFileName_Copy_Skip1:
	inc	1, (0x229DC6:24)
HDAE5000_DeadLib_RecallRecentFileName_Exit:
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	push xwa
	ld	xbc, 0:i3
	ld	xix, (0x229cf0)
	lda xiy, (0x201618:24)
HDAE5000_DeadLib_CopyEntryNameOut_Loop:
	cp	xbc, 0x0000001a
	jp	z, (.LDeadLib_RecallRecentFileName_Exit_Skip1:24)
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp HDAE5000_DeadLib_CopyEntryNameOut_Loop                             ; jp 0x2990fc
.LDeadLib_RecallRecentFileName_Exit_Skip1:
	pop xwa                                 ; pop XWA
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	xor	xwa, xwa
	call HDAE5000_DirBrowser_GetRowByte
	inc 1, xwa                              ; inc 1,XWA
	call HDAE5000_FormatDecimal12_ZeroFill
	ret

	push xbc
	push xix
	xor	xwa, xwa
	xor	xbc, xbc
	ld	a, (0x229D9F:24)
	ld	xbc, 0x00000180
	call HDAE5000_HD_Mul32
	ld	xix, xwa
	xor	xwa, xwa
	call HDAE5000_DirBrowser_GetCursor
	ld	xbc, 0x00000010
	call HDAE5000_HD_Mul32
	add	xwa, xix
	ld	xbc, 0x0000004c
	call HDAE5000_HD_Mul32
	lda xix, (HDAE5000_RAM_SongRecords:24)
	add	xwa, xix
	ld	(0x229cf0), xwa
	pop xix                                 ; pop XIX
	pop xbc                                 ; pop XBC
	ret

	push xbc
	push xix
	xor	xwa, xwa
	xor	xbc, xbc
	ld	a, (0x229D9F:24)
	ld	xbc, 0x00000180
	call HDAE5000_HD_Mul32
	ld	xix, xwa
	xor	xwa, xwa
	call HDAE5000_DirBrowser_GetCursor
	ld	xbc, 0x00000010
	call HDAE5000_HD_Mul32
	add	xix, xwa
	xor	xwa, xwa
	call HDAE5000_DirBrowser_GetRowByte
	add	xwa, xix
	ld	xbc, 0x0000004c
	call HDAE5000_HD_Mul32
	lda xix, (HDAE5000_RAM_SongRecords:24)
	add	xwa, xix
	ld	(0x229cf0), xwa
	pop xix                                 ; pop XIX
	pop xbc                                 ; pop XBC
	ret

HDAE5000_DirBrowser_GetRowByte:
	; A = 0x229DDF[page 0x229D9F * 24 + its cursor] (unreachable)
	push xix
	push xbc
	xor	xwa, xwa
	ld	a, (0x229D9F:24)
	ld	xbc, 0x00000018
	call HDAE5000_HD_Mul32
	ld	xix, xwa
	xor	xwa, xwa
	call HDAE5000_DirBrowser_GetCursor
	add	xwa, xix
	lda xix, (0x229ddf:24)
	add	xix, xwa
	ld	a, (xix)
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

HDAE5000_DirBrowser_IncRowByte:
	; 0x229DDF[page * 24 + cursor] += 1 (unreachable)
	push xix
	push xbc
	xor	xwa, xwa
	ld	a, (0x229D9F:24)
	ld	xbc, 0x00000018
	call HDAE5000_HD_Mul32
	ld	xix, xwa
	xor	xwa, xwa
	call HDAE5000_DirBrowser_GetCursor
	add	xwa, xix
	lda xix, (0x229ddf:24)
	add	xix, xwa
	incm8	1, (xix)
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

	push xix
	push xbc
	xor	xwa, xwa
	ld	a, (0x229D9F:24)
	ld	xbc, 0x00000018
	call HDAE5000_HD_Mul32
	ld	xix, xwa
	xor	xwa, xwa
	call HDAE5000_DirBrowser_GetCursor
	add	xwa, xix
	lda xix, (0x229ddf:24)
	add	xix, xwa
	decm8	1, (xix)
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

HDAE5000_DirBrowser_ClearRowByte:
	; 0x229DDF[page * 24 + cursor] = 0 (unreachable)
	push xix
	push xbc
	xor	xwa, xwa
	ld	a, (0x229D9F:24)
	ld	xbc, 0x00000018
	call HDAE5000_HD_Mul32
	ld	xix, xwa
	xor	xwa, xwa
	call HDAE5000_DirBrowser_GetCursor
	add	xwa, xix
	lda xix, (0x229ddf:24)
	add	xix, xwa
	ld	(xix), 0x00
	ld	a, (xix)
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

	push xix
	push xbc
	xor	xwa, xwa
	ld	a, (0x229D9F:24)
	ld	xbc, 0x00000018
	call HDAE5000_HD_Mul32
	ld	xix, xwa
	xor	xwa, xwa
	call HDAE5000_DirBrowser_GetCursor
	add	xwa, xix
	lda xix, (0x229ddf:24)
	add	xix, xwa
	ld	(xix), 0x0f
	ld	a, (xix)
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	push xwa
	xor	xwa, xwa
	xor	xbc, xbc
	ld	a, (0x229D9F:24)
	ld	xbc, 0x00000180
	call HDAE5000_HD_Mul32
	lda xix, (HDAE5000_RAM_DirNames:24)
	add	xix, xwa
	xor	xwa, xwa
	call HDAE5000_DirBrowser_GetCursor
	ld	xbc, 0x00000010
	call HDAE5000_HD_Mul32
	add	xix, xwa
	ld	(0x229cec), xix
	ld	xbc, 0:i3
	lda xiy, (0x200c98:24)
HDAE5000_DeadLib_LoadDirName_Loop:
	cp	xbc, 0x00000010
	jp	z, (.LDirBrowser_ClearRowByte_Skip1:24)
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp HDAE5000_DeadLib_LoadDirName_Loop                             ; jp 0x2992b5
.LDirBrowser_ClearRowByte_Skip1:
	pop xwa                                 ; pop XWA
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	lda xix, (0x200c98:24)
	ld	xiy, (0x229cec)
	ld	xbc, 0:i3
HDAE5000_DeadLib_StoreDirName_Loop:
	cp	xbc, 0x00000010
	jp	z, (.LDirBrowser_ClearRowByte_Skip2:24)
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp HDAE5000_DeadLib_StoreDirName_Loop                             ; jp 0x2992e2
.LDirBrowser_ClearRowByte_Skip2:
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	call HDAE5000_NameBuf_IsNotBlank
	cp	a, 0:i3
	jp	z, (.LDeadLib_RememberDirName_Copy_Skip2:24)
	lda xix, (0x2013b2:24)
	lda xiy, (0x200c98:24)
	call HDAE5000_NameList5_Contains
	cp	a, 1:i3
	jp	z, (.LDeadLib_RememberDirName_Copy_Skip2:24)
	cp	(0x229DC2:24), 5
	jp	c, (.LDirBrowser_ClearRowByte_Skip3:24)
	ld	(0x229DC2:24), 0
.LDirBrowser_ClearRowByte_Skip3:
	lda xix, (0x2013b2:24)
	xor	xwa, xwa
	ld	a, (0x229DC2:24)
	ld	xbc, 0x00000010
	call HDAE5000_HD_Mul32
	add	xix, xwa
	lda xiy, (0x200c98:24)
	ld	xbc, 0:i3
HDAE5000_DeadLib_RememberDirName_Copy:
	cp	xbc, 0x00000010
	jp	z, (.LDeadLib_RememberDirName_Copy_Skip1:24)
	ld	a, (xiy)
	ld	(xix), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp HDAE5000_DeadLib_RememberDirName_Copy                             ; jp 0x299351
.LDeadLib_RememberDirName_Copy_Skip1:
	inc	1, (0x229DC2:24)
.LDeadLib_RememberDirName_Copy_Skip2:
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	cp	(0x229DC5:24), 5
	jp	c, (.LDeadLib_RememberDirName_Copy_Skip3:24)
	ld	(0x229DC5:24), 0
.LDeadLib_RememberDirName_Copy_Skip3:
	lda xix, (0x2013b2:24)
	xor	xwa, xwa
	ld	a, (0x229DC5:24)
	ld	xbc, 0x00000010
	call HDAE5000_HD_Mul32
	add	xix, xwa
	push xix
	call HDAE5000_Name26_IsBlank
	pop xix                                 ; pop XIX
	cp	a, 1:i3
	jp	nz, (.LDeadLib_RememberDirName_Copy_Skip4:24)
	ld	(0x229DC5:24), 0
	jp HDAE5000_DeadLib_RecallRecentDirName_Exit                             ; jp 0x2993da
.LDeadLib_RememberDirName_Copy_Skip4:
	lda xiy, (0x200c98:24)
	ld	xbc, 0:i3
HDAE5000_DeadLib_RecallRecentDirName_Copy:
	cp	xbc, 0x00000010
	jp	z, (.LDeadLib_RecallRecentDirName_Copy_Skip1:24)
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp HDAE5000_DeadLib_RecallRecentDirName_Copy                             ; jp 0x2993bc
.LDeadLib_RecallRecentDirName_Copy_Skip1:
	inc	1, (0x229DC5:24)
HDAE5000_DeadLib_RecallRecentDirName_Exit:
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	push xwa
	xor	xwa, xwa
	xor	xbc, xbc
	ld	a, (0x229D9F:24)
	ld	xbc, 0x00000180
	call HDAE5000_HD_Mul32
	lda xix, (HDAE5000_RAM_DirNames:24)
	add	xix, xwa
	xor	xwa, xwa
	call HDAE5000_DirBrowser_GetCursor
	ld	xbc, 0x00000010
	call HDAE5000_HD_Mul32
	add	xix, xwa
	ld	xbc, 0:i3
	lda xiy, (0x200870:24)
HDAE5000_DeadLib_CopyDirNameOut_Loop:
	cp	xbc, 0x00000010
	jp	z, (.LDeadLib_RecallRecentDirName_Exit_Skip1:24)
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp HDAE5000_DeadLib_CopyDirNameOut_Loop                             ; jp 0x299413
.LDeadLib_RecallRecentDirName_Exit_Skip1:
	pop xwa                                 ; pop XWA
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	xor	xwa, xwa
	ld	a, (0x229D9F:24)
	ld	xbc, 0x00000018
	call HDAE5000_HD_Mul32
	ld	xix, xwa
	xor	xwa, xwa
	call HDAE5000_DirBrowser_GetCursor
	add	xwa, xix
	inc 1, xwa                              ; inc 1,XWA
	call HDAE5000_FormatDecimal12_ZeroFill
	ret

	push xbc
	xor	xwa, xwa
	ld	a, (0x229D9F:24)
	ld	xbc, 0x00000018
	call HDAE5000_HD_Mul32
	inc 1, xwa                              ; inc 1,XWA
	pop xbc                                 ; pop XBC
	ret

	push xbc
	push xde
	xor	xwa, xwa
	xor	xbc, xbc
	xor	xde, xde
	ld	xde, HDAE5000_RAM_DirNames
	ld	a, (0x229D9F:24)
	ld	xbc, 0x00000180
	call HDAE5000_HD_Mul32
	add	xwa, xde
	pop xde                                 ; pop XDE
	pop xbc                                 ; pop XBC
	ret

HDAE5000_DirBrowser_GetCursor:
	; A = cursor 0x229DDA[page 0x229D9F] (unreachable)
	push xix
	lda xix, (0x229dda:24)
	xor	xwa, xwa
	ld	a, (0x229D9F:24)
	add	xix, xwa
	ld	a, (xix)
	pop xix                                 ; pop XIX
	ret

HDAE5000_DirBrowser_IncCursor:
	; cursor 0x229DDA[page] += 1, A = it (unreachable)
	push xix
	lda xix, (0x229dda:24)
	xor	xwa, xwa
	ld	a, (0x229D9F:24)
	add	xix, xwa
	incm8	1, (xix)
	ld	a, (xix)
	pop xix                                 ; pop XIX
	ret

	push xix
	lda xix, (0x229dda:24)
	xor	xwa, xwa
	ld	a, (0x229D9F:24)
	add	xix, xwa
	decm8	1, (xix)
	ld	a, (xix)
	pop xix                                 ; pop XIX
	ret

HDAE5000_DirBrowser_ClearCursor:
	; cursor 0x229DDA[page] = 0 (unreachable)
	push xix
	lda xix, (0x229dda:24)
	xor	xwa, xwa
	ld	a, (0x229D9F:24)
	add	xix, xwa
	ld	(xix), 0x00
	pop xix                                 ; pop XIX
	ret

	push xix
	lda xix, (0x229dda:24)
	xor	xwa, xwa
	ld	a, (0x229D9F:24)
	add	xix, xwa
	ld	(xix), 0x17
	pop xix                                 ; pop XIX
	ret

	push xix
	push xwa
	lda xix, (0x229dda:24)
	xor	xwa, xwa
	ld	a, (0x229D9F:24)
	add	xix, xwa
	pop xwa                                 ; pop XWA
	ld	(xix), a
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	push xwa
	xor	xwa, xwa
	xor	xbc, xbc
	ld	a, (0x229DA0:24)
	ld	xbc, 0x00000d80
	call HDAE5000_HD_Mul32
	lda xix, (HDAE5000_RAM_FlsRecords:24)
	add	xix, xwa
	xor	xwa, xwa
	call HDAE5000_FlsBrowser_GetCursor
	ld	xbc, 0x00000090
	call HDAE5000_HD_Mul32
	add	xix, xwa
	ld	(0x229cec), xix
	ld	xbc, 0:i3
	lda xiy, (0x200c98:24)
HDAE5000_DeadLib_LoadFlsName_Loop:
	cp	xbc, 0x00000010
	jp	z, (.LDirBrowser_ClearCursor_Skip1:24)
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp HDAE5000_DeadLib_LoadFlsName_Loop                             ; jp 0x29953b
.LDirBrowser_ClearCursor_Skip1:
	pop xwa                                 ; pop XWA
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	lda xix, (0x200c98:24)
	ld	xiy, (0x229cec)
	ld	xbc, 0:i3
HDAE5000_DeadLib_StoreFlsName_Loop:
	cp	xbc, 0x00000010
	jp	z, (.LDirBrowser_ClearCursor_Skip2:24)
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp HDAE5000_DeadLib_StoreFlsName_Loop                             ; jp 0x299568
.LDirBrowser_ClearCursor_Skip2:
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	call HDAE5000_NameBuf_IsNotBlank
	cp	a, 0:i3
	jp	z, (.LDeadLib_RememberFlsName_Copy_Skip2:24)
	lda xix, (0x2014b6:24)
	lda xiy, (0x200c98:24)
	call HDAE5000_NameList5_Contains
	cp	a, 1:i3
	jp	z, (.LDeadLib_RememberFlsName_Copy_Skip2:24)
	cp	(0x229DC4:24), 5
	jp	c, (.LDirBrowser_ClearCursor_Skip3:24)
	ld	(0x229DC4:24), 0
.LDirBrowser_ClearCursor_Skip3:
	lda xix, (0x2014b6:24)
	xor	xwa, xwa
	ld	a, (0x229DC4:24)
	ld	xbc, 0x00000010
	call HDAE5000_HD_Mul32
	add	xix, xwa
	lda xiy, (0x200c98:24)
	ld	xbc, 0:i3
HDAE5000_DeadLib_RememberFlsName_Copy:
	cp	xbc, 0x00000010
	jp	z, (.LDeadLib_RememberFlsName_Copy_Skip1:24)
	ld	a, (xiy)
	ld	(xix), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp HDAE5000_DeadLib_RememberFlsName_Copy                             ; jp 0x2995d7
.LDeadLib_RememberFlsName_Copy_Skip1:
	inc	1, (0x229DC4:24)
.LDeadLib_RememberFlsName_Copy_Skip2:
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	cp	(0x229DC7:24), 5
	jp	c, (.LDeadLib_RememberFlsName_Copy_Skip3:24)
	ld	(0x229DC7:24), 0
.LDeadLib_RememberFlsName_Copy_Skip3:
	lda xix, (0x2014b6:24)
	xor	xwa, xwa
	ld	a, (0x229DC7:24)
	ld	xbc, 0x00000010
	call HDAE5000_HD_Mul32
	add	xix, xwa
	push xix
	call HDAE5000_Name26_IsBlank
	pop xix                                 ; pop XIX
	cp	a, 1:i3
	jp	nz, (.LDeadLib_RememberFlsName_Copy_Skip4:24)
	ld	(0x229DC7:24), 0
	jp HDAE5000_DeadLib_RecallRecentFlsName_Exit                             ; jp 0x299660
.LDeadLib_RememberFlsName_Copy_Skip4:
	lda xiy, (0x200c98:24)
	ld	xbc, 0:i3
HDAE5000_DeadLib_RecallRecentFlsName_Copy:
	cp	xbc, 0x00000010
	jp	z, (.LDeadLib_RecallRecentFlsName_Copy_Skip1:24)
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp HDAE5000_DeadLib_RecallRecentFlsName_Copy                             ; jp 0x299642
.LDeadLib_RecallRecentFlsName_Copy_Skip1:
	inc	1, (0x229DC7:24)
HDAE5000_DeadLib_RecallRecentFlsName_Exit:
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	push xwa
	xor	xwa, xwa
	xor	xbc, xbc
	ld	a, (0x229DA0:24)
	ld	xbc, 0x00000d80
	call HDAE5000_HD_Mul32
	lda xix, (HDAE5000_RAM_FlsRecords:24)
	add	xix, xwa
	xor	xwa, xwa
	call HDAE5000_FlsBrowser_GetCursor
	ld	xbc, 0x00000090
	call HDAE5000_HD_Mul32
	add	xix, xwa
	ld	xbc, 0:i3
	lda xiy, (0x200870:24)
HDAE5000_DeadLib_CopyFlsNameOut_Loop:
	cp	xbc, 0x00000010
	jp	z, (.LDeadLib_RecallRecentFlsName_Exit_Skip1:24)
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp HDAE5000_DeadLib_CopyFlsNameOut_Loop                             ; jp 0x299699
.LDeadLib_RecallRecentFlsName_Exit_Skip1:
	pop xwa                                 ; pop XWA
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

HDAE5000_FlsBrowser_RowAddress:
	; XWA = 0x2257B2 + page 0x229DA0 * 0xD80 + cursor * 0x90, the current FLS row (unreachable)
	push xbc
	push xde
	xor	xwa, xwa
	xor	xbc, xbc
	xor	xde, xde
	ld	xde, HDAE5000_RAM_FlsRecords
	ld	a, (0x229DA0:24)
	ld	xbc, 0x00000d80
	call HDAE5000_HD_Mul32
	add	xde, xwa
	xor	xwa, xwa
	call HDAE5000_FlsBrowser_GetCursor
	ld	xbc, 0x00000090
	call HDAE5000_HD_Mul32
	add	xwa, xde
	pop xde                                 ; pop XDE
	pop xbc                                 ; pop XBC
	ret

	push xbc
	xor	xwa, xwa
	ld	a, (0x229DA0:24)
	ld	xbc, 0x00000018
	call HDAE5000_HD_Mul32
	inc 1, xwa                              ; inc 1,XWA
	pop xbc                                 ; pop XBC
	ret

	push xbc
	push xde
	xor	xwa, xwa
	xor	xbc, xbc
	xor	xde, xde
	ld	xde, HDAE5000_RAM_FlsRecords
	ld	a, (0x229DA0:24)
	ld	xbc, 0x00000d80
	call HDAE5000_HD_Mul32
	add	xwa, xde
	pop xde                                 ; pop XDE
	pop xbc                                 ; pop XBC
	ret

	xor	xwa, xwa
	xor	xbc, xbc
	ld	a, (0x229D9F:24)
	ld	xbc, 0x00000018
	call HDAE5000_HD_Mul32
	ld	xix, xwa
	xor	xwa, xwa
	call HDAE5000_DirBrowser_GetCursor
	add	xwa, xix
	ld	(0x229c54), wa
	ret

HDAE5000_FlsBrowser_GetCursor:
	; A = cursor 0x229E57[page 0x229DA0] (unreachable)
	push xix
	lda xix, (0x229e57:24)
	xor	xwa, xwa
	ld	a, (0x229DA0:24)
	add	xix, xwa
	ld	a, (xix)
	pop xix                                 ; pop XIX
	ret

HDAE5000_FlsBrowser_GetRowByte:
	; A = 0x229E5C[page * 24 + cursor] (unreachable)
	push xix
	push xbc
	xor	xwa, xwa
	ld	a, (0x229DA0:24)
	ld	xbc, 0x00000018
	call HDAE5000_HD_Mul32
	ld	xix, xwa
	xor	xwa, xwa
	call HDAE5000_FlsBrowser_GetCursor
	add	xwa, xix
	lda xix, (0x229e5c:24)
	add	xix, xwa
	ld	a, (xix)
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

HDAE5000_FlsBrowser_IncCursor:
	; cursor 0x229E57[page] += 1, A = it (unreachable)
	push xix
	lda xix, (0x229e57:24)
	xor	xwa, xwa
	ld	a, (0x229DA0:24)
	add	xix, xwa
	incm8	1, (xix)
	ld	a, (xix)
	pop xix                                 ; pop XIX
	ret

	push xix
	lda xix, (0x229e57:24)
	xor	xwa, xwa
	ld	a, (0x229DA0:24)
	add	xix, xwa
	decm8	1, (xix)
	ld	a, (xix)
	pop xix                                 ; pop XIX
	ret

HDAE5000_FlsBrowser_IncRowByte:
	; 0x229E5C[page * 24 + cursor] += 1 (unreachable)
	push xix
	push xbc
	xor	xwa, xwa
	ld	a, (0x229DA0:24)
	ld	xbc, 0x00000018
	call HDAE5000_HD_Mul32
	ld	xix, xwa
	xor	xwa, xwa
	call HDAE5000_FlsBrowser_GetCursor
	add	xwa, xix
	lda xix, (0x229e5c:24)
	add	xix, xwa
	incm8	1, (xix)
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

	push xix
	push xbc
	xor	xwa, xwa
	ld	a, (0x229DA0:24)
	ld	xbc, 0x00000018
	call HDAE5000_HD_Mul32
	ld	xix, xwa
	xor	xwa, xwa
	call HDAE5000_FlsBrowser_GetCursor
	add	xwa, xix
	lda xix, (0x229e5c:24)
	add	xix, xwa
	decm8	1, (xix)
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

HDAE5000_FlsBrowser_ClearCursor:
	; cursor 0x229E57[page] = 0 (unreachable)
	push xix
	lda xix, (0x229e57:24)
	xor	xwa, xwa
	ld	a, (0x229DA0:24)
	add	xix, xwa
	ld	(xix), 0x00
	pop xix                                 ; pop XIX
	ret

	push xix
	lda xix, (0x229e57:24)
	xor	xwa, xwa
	ld	a, (0x229DA0:24)
	add	xix, xwa
	ld	(xix), 0x17
	pop xix                                 ; pop XIX
	ret

HDAE5000_FlsBrowser_ClearRowByte:
	; 0x229E5C[page * 24 + cursor] = 0 (unreachable)
	push xix
	push xbc
	xor	xwa, xwa
	ld	a, (0x229DA0:24)
	ld	xbc, 0x00000018
	call HDAE5000_HD_Mul32
	ld	xix, xwa
	xor	xwa, xwa
	call HDAE5000_FlsBrowser_GetCursor
	add	xwa, xix
	lda xix, (0x229e5c:24)
	add	xix, xwa
	ld	(xix), 0x00
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

	push xix
	push xbc
	xor	xwa, xwa
	ld	a, (0x229DA0:24)
	ld	xbc, 0x00000018
	call HDAE5000_HD_Mul32
	ld	xix, xwa
	xor	xwa, xwa
	call HDAE5000_FlsBrowser_GetCursor
	add	xwa, xix
	lda xix, (0x229e5c:24)
	add	xix, xwa
	ld	(xix), 0x1f
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

	call HDAE5000_FlsBrowser_RowAddress
	ld	xbc, 0x00000010
	add	xwa, xbc
	ld	xix, xwa
	ld	(0x229d80), xix
	lda xiy, (0x201556:24)
	ld	bc, 0:i3
HDAE5000_DeadLib_Copy64Out_Loop:
	cp	bc, 0x0040
	jp	z, (.LFlsBrowser_ClearRowByte_Return1:24)
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	inc	1, bc
	jp HDAE5000_DeadLib_Copy64Out_Loop                             ; jp 0x299887
.LFlsBrowser_ClearRowByte_Return1:
	ret

	ld	xix, (0x229d80)
	lda xiy, (0x201556:24)
	ld	bc, 0:i3
HDAE5000_DeadLib_Copy64Back_Loop:
	cp	bc, 0x0040
	jp	z, (.LFlsBrowser_ClearRowByte_Return2:24)
	ld	a, (xiy)
	ld	(xix), a
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	inc	1, bc
	jp HDAE5000_DeadLib_Copy64Back_Loop                             ; jp 0x2998ab
.LFlsBrowser_ClearRowByte_Return2:
	ret

	ld	xix, (0x229d7c)
	xor	xwa, xwa
	xor	xbc, xbc
	call HDAE5000_FlsBrowser_GetRowByte
	ld	xbc, 2:i3
	call HDAE5000_HD_Mul32
	add	xwa, xix
	ret

; HDAE5000_DecimalDigits (0x2998D9, 11 bytes): "0123456789 ", the digit table
; of HDAE5000_FormatDecimal12_ZeroFill (0x298A8E), which divides by 10
; with HDAE5000_HD_UDiv32 and then indexes this string with each remainder
; (`lda xiy,(HDAE5000_DecimalDigits:24)` / `add xiy,xbc` / `ld a,(xiy)`).
; It used to be decoded as `ldw wa,0x3231 / ldw hl,0x3534 / ldw iz,0x3837 /
; push xbc` plus `ld w,0x3e`, whose 0x3E was really the first opcode of
; HDAE5000_HD_LoadSettings -- the misframe behind the branch symboliser's
; "mid-line" refusal of `call 0x2998e4` (a call into the middle of `ld w`).
HDAE5000_DecimalDigits:
	.ascii	"0123456789 "
HDAE5000_HD_LoadSettings:
	; read sector 1 (the signature sector) into RAM 0x200628 and restore the
	; six setting bytes it carries at +0x78 (0x2006A0) into 0x229DA9..AE --
	; the mirror image of HDAE5000_HD_SaveSettings.  Called from 0x293F01.
	push	xiz
	ld	xhl, 1:i3
	lda xix, (0x200628:24)
	ld	xde, 0x00000200
	call HDAE5000_ATA_ReadSector
	lda xix, (0x2006a0:24)
	ldb_spi a, 0xf0		; ld A,(XIX+)
	ld	(HDAE5000_RAM_QuickLoadMode:24), a
	ldb_spi a, 0xf0		; ld A,(XIX+)
	ld	(HDAE5000_RAM_LoadByNumberMode:24), a
	ldb_spi a, 0xf0		; ld A,(XIX+)
	ld	(HDAE5000_RAM_JumpAfterLoad:24), a
	ldb_spi a, 0xf0		; ld A,(XIX+)
	ld	(HDAE5000_RAM_LyricJump:24), a
	ldb_spi a, 0xf0		; ld A,(XIX+)
	ld	(HDAE5000_RAM_LyricForeColor:24), a
	ld	a, (xix)
	ld	(HDAE5000_RAM_LyricBackColor:24), a
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_HD_SaveSettings:
	; build and write the signature sector: at RAM 0x200628, after
	; HDAE5000_HD_ZeroSector, the longs 0xAA55AA55 and
	; 0xF4F1F2F3 (what HDAE5000_HD_CheckSignature looks for), the 112-byte
	; HDAE5000_Version_Info record copied byte by byte (_CopyLoop, up to
	; HDAE5000_Version_Info_End), the six setting bytes 0x229DA9..AE at +0x78
	; (0x2006A0), a 0xFFFFFFFF long, then HDAE5000_ATA_WriteSector(1).
	; (Was Display_Callback_Helper3.)
	push xiz
	lda xix, (0x200628:24)
	call HDAE5000_HD_ZeroSector
	lda xix, (0x200628:24)
	ld	xwa, 0xaa55aa55
	ld (xix), xwa                           ; ld (XIX),XWA
	inc 4, xix                              ; inc 4,XIX
	ld	xwa, 0xf4f1f2f3
	ld (xix), xwa                           ; ld (XIX),XWA
	inc 4, xix                              ; inc 4,XIX
	lda xiy, (HDAE5000_Version_Info:24)
	lda xiz, (HDAE5000_Version_Info_End:24)
HDAE5000_HD_SaveSettings_CopyLoop:
	cp	xiy, xiz
	jp	z, (.LHD_SaveSettings_CopyLoop_Skip1:24)
	ld	a, (xiy)
	ld	(xix), a
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp HDAE5000_HD_SaveSettings_CopyLoop                             ; jp 0x299956
.LHD_SaveSettings_CopyLoop_Skip1:
	lda xix, (0x2006a0:24)
	ld	a, (HDAE5000_RAM_QuickLoadMode:24)
	lda_dpi xbc, 0xf0		; ld (XIX+),A
	ld	a, (HDAE5000_RAM_LoadByNumberMode:24)
	lda_dpi xbc, 0xf0		; ld (XIX+),A
	ld	a, (HDAE5000_RAM_JumpAfterLoad:24)
	lda_dpi xbc, 0xf0		; ld (XIX+),A
	ld	a, (HDAE5000_RAM_LyricJump:24)
	lda_dpi xbc, 0xf0		; ld (XIX+),A
	ld	a, (HDAE5000_RAM_LyricForeColor:24)
	lda_dpi xbc, 0xf0		; ld (XIX+),A
	ld	a, (HDAE5000_RAM_LyricBackColor:24)
	lda_dpi xbc, 0xf0		; ld (XIX+),A
	ld	xwa, 0xffffffff
	ld (xix), xwa                           ; ld (XIX),XWA
	ld	xhl, 1:i3
	lda xix, (0x200628:24)
	call HDAE5000_ATA_WriteSector
	pop xiz                                 ; pop XIZ
	ret

	; The 148 lines this replaces (through the old `ld xde, 0x3e37b6bf`) were NOT code:
	; llvm-mc's disassembler happened to find a valid TLCS900 encoding in every one of these
	; 309 bytes, chained by internal .LDSR_9a18/25/46/49/ab8 jr/jrl targets that referenced
	; nothing outside this span -- a self-contained illusion of code. The bytes are the
	; firmware's own version-info block plus a charset/reference-digit table, confirmed
	; directly against original_ROMs/hd-ae5000_v2_06i.ic4 at 0x2999B2-0x299AE6 (309 bytes).
	; Real code resumes at 0x299AE7; the old fake `ld xde,...` opcode byte (0x42, the 'B' of
	; "CVNB" here) had swallowed the first real instruction's bytes with it, so the true next
	; two instructions are given explicitly below and match ROM bytes 0x299AE7-0x299AEA.
; HDAE5000_Version_Info (0x2999B2, 112 bytes): four space-padded fields --
; author (40), version "2.33J" (24), "2.21" (24), "TECHNICS KN5000" (24).
; READERS: HDAE5000_HD_SaveSettings copies exactly these 112 bytes
; (HDAE5000_Version_Info .. HDAE5000_Version_Info_End) into the signature
; sector; the routine at 0x2988CF copies the same range.
HDAE5000_Version_Info:
	.ascii "Technics Software section    M. Kitajima"
	.ascii "2.33J                   "
	.ascii "2.21                    "
	.ascii "TECHNICS KN5000         "
HDAE5000_Version_Info_End:
	.ascii "                        "
	.ascii "Juli-Oktober 1996"
; HDAE5000_Version_Key (0x299A4B): the long "XXXX" that
; HDAE5000_HD_CheckVersionKey (0x298C9D) and the identical unlabelled copy
; at 0x297551 compare with RAM 0x229C60.
HDAE5000_Version_Key:
	.ascii "XXXXXXXX"
	.byte 0x1b, 0x1c, 0x1f                ; non-ASCII control bytes inside the confirmed-data version/reference-digit block documented above (0x2999B2-0x299AE6) -- not code, individual meaning not determined
	.ascii "\"VE \""
	.ascii "E12345678910111213141516171819202122232425ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvw #.-,;:_portuoirutoiurtUPOTRUJRNGERIUT7457890CVNB"
;
; HDAE5000_DoPrintf -- the C library's formatted-output engine (_doprnt shape)
;   in:  (xsp+4) const char *fmt, (xsp+8) va_list *ap, (xsp+0xC) void (*putc)(int)
;   out: HL = number of characters emitted
; Walks fmt; every byte that is not '%' (0x25, first compare below) is passed to
; the putc callback (`ld xwa,(xsp+0x5c) / call (xwa)` = the third argument once
; the 74-byte frame and a pushed word are allowed for).  After '%' it parses
; flags/width/precision and dispatches: integers through
; HDAE5000_Int_To_Decimal_String / _UInt_ / _Hex_ / _Octal_, doubles through
; HDAE5000_FormatFloat (8-byte va_arg fetched by HDAE5000_Copy8, or 10 bytes by
; HDAE5000_Copy10 when flag bit 7 is set).
; Callers: HDAE5000_SPrintf and HDAE5000_VSPrintf, which pass
; HDAE5000_SPrintf_PutChar as putc.  It was named PPI_Block_Copy_Helper, after
; nothing in its code: it touches no PPI port.
HDAE5000_DoPrintf:
	lda xsp, (xsp - 74)
	push xiz
	ldw (xsp + 0x04), 0
	jrl t, HDAE5000_DoPrintf_NextChar                      ; [78 c4 08] jrl T,0x29a3b7
.LDSR_9af3:
	cp	iz, 0x0025
	jr z, .LDSR_9b07                       ; [66 0e] jr Z,0x299b07
	pushw iz                                ; push IZ
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incw	1, (xsp+4)
	jrl t, HDAE5000_DoPrintf_NextChar                      ; [78 b0 08] jrl T,0x29a3b7
.LDSR_9b07:
	ldw (xsp + 0x08), 0
	ldw (xsp + 0x0a), 0
	ldw (xsp + 0x06), 0
	ldw	(0x239486:24), 32
.LDSR_9b1d:
	ld xwa, (xsp + 0x52)                    ; ld XWA,(XSP+0x52)
	ldb_spi c, 0xe0		; ld C,(XWA+)
	ld (xsp + 0x52), xwa                    ; ld (XSP+0x52),XWA
	ldb_erp c, 0xf8		; ld IZL,C
	exts	iz
	ld	wa, iz
	cp	iz, 0x0030
	jr z, .LDSR_9b96                       ; [66 63] jr Z,0x299b96
	cp	wa, 0x002d
	jr z, .LDSR_9b91                       ; [66 58] jr Z,0x299b91
	cp	wa, 0x002b
	jr z, .LDSR_9b8c                       ; [66 4d] jr Z,0x299b8c
	cp	wa, 0x0023
	jr z, .LDSR_9b87                       ; [66 42] jr Z,0x299b87
	cp	wa, 0x0020
	jr z, .LDSR_9b82                       ; [66 37] jr Z,0x299b82
	cp	iz, 0x002a
	jr nz, .LDSR_9bc1                      ; [6e 70] jr NZ,0x299bc1
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	ld	xwa, 2:i3
	add	(xbc), xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld	wa, (xwa-2)
	ld (xsp + 0x08), wa                     ; ld (XSP+0x08),WA
	cpw	(xsp+8), 0x0000
	jr ge, .LDSR_9b72                      ; [69 0b] jr GE,0x299b72
	ld	wa, (xsp+8)
	neg	wa
	ld (xsp + 0x08), wa                     ; ld (XSP+0x08),WA
	setm	1, (xsp+6)
.LDSR_9b72:
	ld xwa, (xsp + 0x52)                    ; ld XWA,(XSP+0x52)
	ldb_spi c, 0xe0		; ld C,(XWA+)
	ld (xsp + 0x52), xwa                    ; ld (XSP+0x52),XWA
	ldb_erp c, 0xf8		; ld IZL,C
	exts	iz
	jr t, .LDSR_9bd2                       ; [68 50] jr T,0x299bd2
.LDSR_9b82:
	setm	2, (xsp+6)
	jr t, .LDSR_9b1d                       ; [68 96] jr T,0x299b1d
.LDSR_9b87:
	setm	3, (xsp+6)
	jr t, .LDSR_9b1d                       ; [68 91] jr T,0x299b1d
.LDSR_9b8c:
	setm	0, (xsp+6)
	jr t, .LDSR_9b1d                       ; [68 8c] jr T,0x299b1d
.LDSR_9b91:
	setm	1, (xsp+6)
	jr t, .LDSR_9b1d                       ; [68 87] jr T,0x299b1d
.LDSR_9b96:
	ldw	(0x239486:24), 48
	jrl t, .LDSR_9b1d                      ; [78 7d ff] jrl T,0x299b1d
.LDSR_9ba0:
	ld	bc, iz
	sub	bc, 0x0030
	ld	wa, (xsp+8)
	muls	wa, 0x000a
	ld (xsp + 0x08), wa                     ; ld (XSP+0x08),WA
	add	(xsp+8), bc
	ld xwa, (xsp + 0x52)                    ; ld XWA,(XSP+0x52)
	ldb_spi c, 0xe0		; ld C,(XWA+)
	ld (xsp + 0x52), xwa                    ; ld (XSP+0x52),XWA
	ldb_erp c, 0xf8		; ld IZL,C
	exts	iz
.LDSR_9bc1:
	stb_erp a, 0xf8		; ld A,IZL
	extz wa                                 ; extz WA
	lda xbc, (HDAE5000_CType_Table:24)
	bit_dri 2, 0x07, 0xE4, 0xE0	; bit 2,(XBC+WA)
	jr nz, .LDSR_9ba0                      ; [6e ce] jr NZ,0x299ba0
.LDSR_9bd2:
	cp	iz, 0x002e
	jr nz, .LDSR_9c4a                      ; [6e 72] jr NZ,0x299c4a
	setm	4, (xsp+6)
	ld xwa, (xsp + 0x52)                    ; ld XWA,(XSP+0x52)
	ldb_spi c, 0xe0		; ld C,(XWA+)
	ld (xsp + 0x52), xwa                    ; ld (XSP+0x52),XWA
	ldb_erp c, 0xf8		; ld IZL,C
	exts	iz
	cp	iz, 0x002a
	jr nz, .LDSR_9c39                      ; [6e 4a] jr NZ,0x299c39
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	ld	xwa, 2:i3
	add	(xbc), xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld	wa, (xwa-2)
	ld (xsp + 0x0a), wa                     ; ld (XSP+0x0a),WA
	cpw	(xsp+10), 0x0000
	jr ge, .LDSR_9c08                      ; [69 03] jr GE,0x299c08
	resm	4, (xsp+6)
.LDSR_9c08:
	ld xwa, (xsp + 0x52)                    ; ld XWA,(XSP+0x52)
	ldb_spi c, 0xe0		; ld C,(XWA+)
	ld (xsp + 0x52), xwa                    ; ld (XSP+0x52),XWA
	ldb_erp c, 0xf8		; ld IZL,C
	exts	iz
	jr t, .LDSR_9c4a                       ; [68 32] jr T,0x299c4a
.LDSR_9c18:
	ld	bc, iz
	sub	bc, 0x0030
	ld	wa, (xsp+10)
	muls	wa, 0x000a
	ld (xsp + 0x0a), wa                     ; ld (XSP+0x0a),WA
	add	(xsp+10), bc
	ld xwa, (xsp + 0x52)                    ; ld XWA,(XSP+0x52)
	ldb_spi c, 0xe0		; ld C,(XWA+)
	ld (xsp + 0x52), xwa                    ; ld (XSP+0x52),XWA
	ldb_erp c, 0xf8		; ld IZL,C
	exts	iz
.LDSR_9c39:
	stb_erp a, 0xf8		; ld A,IZL
	extz wa                                 ; extz WA
	lda xbc, (HDAE5000_CType_Table:24)
	bit_dri 2, 0x07, 0xE4, 0xE0	; bit 2,(XBC+WA)
	jr nz, .LDSR_9c18                      ; [6e ce] jr NZ,0x299c18
.LDSR_9c4a:
	cp	iz, 0x0068
	jr nz, .LDSR_9c63                      ; [6e 13] jr NZ,0x299c63
	setm	5, (xsp+6)
	ld xwa, (xsp + 0x52)                    ; ld XWA,(XSP+0x52)
	ldb_spi c, 0xe0		; ld C,(XWA+)
	ld (xsp + 0x52), xwa                    ; ld (XSP+0x52),XWA
	ldb_erp c, 0xf8		; ld IZL,C
	exts	iz
	jr t, .LDSR_9c93                       ; [68 30] jr T,0x299c93
.LDSR_9c63:
	cp	iz, 0x006c
	jr nz, .LDSR_9c7c                      ; [6e 13] jr NZ,0x299c7c
	setm	6, (xsp+6)
	ld xwa, (xsp + 0x52)                    ; ld XWA,(XSP+0x52)
	ldb_spi c, 0xe0		; ld C,(XWA+)
	ld (xsp + 0x52), xwa                    ; ld (XSP+0x52),XWA
	ldb_erp c, 0xf8		; ld IZL,C
	exts	iz
	jr t, .LDSR_9c93                       ; [68 17] jr T,0x299c93
.LDSR_9c7c:
	cp	iz, 0x004c
	jr nz, .LDSR_9c93                      ; [6e 11] jr NZ,0x299c93
	setm	7, (xsp+6)
	ld xwa, (xsp + 0x52)                    ; ld XWA,(XSP+0x52)
	ldb_spi c, 0xe0		; ld C,(XWA+)
	ld (xsp + 0x52), xwa                    ; ld (XSP+0x52),XWA
	ldb_erp c, 0xf8		; ld IZL,C
	exts	iz
.LDSR_9c93:
	ld	wa, iz
	cp	iz, 0x0047
	jrl z, HDAE5000_DoPrintf_Case_Float                      ; [76 c4 06] jrl Z,0x29a360
	cp	wa, 0x0045
	jrl z, HDAE5000_DoPrintf_Case_Float                      ; [76 bd 06] jrl Z,0x29a360
	cp	wa, 0x0058
	jrl z, HDAE5000_DoPrintf_Case_Hex                      ; [76 de 03] jrl Z,0x29a088
	cp	wa, 0x0025
	jr z, HDAE5000_DoPrintf_Case_Char                       ; [66 26] jr Z,0x299cd6
	sub	wa, 0x0063
	cp	wa, 0:i3
	jrl lt, HDAE5000_DoPrintf_NextChar                     ; [71 fe 06] jrl LT,0x29a3b7
	cp	wa, 0x0015
	jrl gt, HDAE5000_DoPrintf_NextChar                     ; [7a f7 06] jrl GT,0x29a3b7
	add	wa, wa
	lda xix, (HDAE5000_DoPrintf_ConvTable:24)
	ldw_sri wa, 0x07, 0xF0, 0xE0	; ld WA,(XIX+WA)
	lda xix, (HDAE5000_DoPrintf_Case_Char:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_DoPrintf_Case_Char:
	ld	wa, (xsp+6)
	bit	0x01, wa
	jr z, .LDSR_9cef                       ; [66 11] jr Z,0x299cef
	jr t, .LDSR_9cf9                       ; [68 19] jr T,0x299cf9
.LDSR_9ce0:
	incw	1, (xsp+4)
	pushw	(0x239486:24)
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_9cef:
	decm	1, (xsp+8)
	cpw	(xsp+8), 0x0000
	jr gt, .LDSR_9ce0                      ; [6a e7] jr GT,0x299ce0
.LDSR_9cf9:
	incw	1, (xsp+4)
	cp	iz, 0x0063
	jr nz, .LDSR_9d10                      ; [6e 0e] jr NZ,0x299d10
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	ld	xwa, 2:i3
	add	(xbc), xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	pushm	(xwa-2)
	jr t, .LDSR_9d13                       ; [68 03] jr T,0x299d13
.LDSR_9d10:
	pushw 0x0025
.LDSR_9d13:
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	ld	wa, (xsp+6)
	bit	0x01, wa
	jr nz, .LDSR_9d32                      ; [6e 10] jr NZ,0x299d32
	jrl t, HDAE5000_DoPrintf_NextChar                      ; [78 92 06] jrl T,0x29a3b7
.LDSR_9d25:
	incw	1, (xsp+4)
	pushw 0x0020
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_9d32:
	decm	1, (xsp+8)
	cpw	(xsp+8), 0x0000
	jr gt, .LDSR_9d25                      ; [6a e9] jr GT,0x299d25
	jrl t, HDAE5000_DoPrintf_NextChar                      ; [78 78 06] jrl T,0x29a3b7
HDAE5000_DoPrintf_Case_String:
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	ld	xwa, 4:i3
	add	(xbc), xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld	xwa, (xwa-4)
	ld (xsp + 0x10), xwa                    ; ld (XSP+0x10),XWA
	push xwa
	call HDAE5000_StrLen
	inc 4, xsp                              ; inc 4,XSP
	ld	wa, (xsp+6)
	bit	0x04, wa
	jr z, .LDSR_9d62                       ; [66 05] jr Z,0x299d62
	cp	(xsp+10), hl
	jr lt, .LDSR_9d67                      ; [61 05] jr LT,0x299d67
.LDSR_9d62:
	ld (xsp + 0x0a), hl
	jr t, .LDSR_9d6a                       ; [68 03] jr T,0x299d6a
.LDSR_9d67:
	ld	hl, (xsp+10)
.LDSR_9d6a:
	cp	hl, (xsp+8)
	jr le, .LDSR_9d79                      ; [62 0a] jr LE,0x299d79
	ldw (xsp + 0x08), 0
	add	(xsp+4), hl
	jr t, .LDSR_9d82                       ; [68 09] jr T,0x299d82
.LDSR_9d79:
	ld	wa, (xsp+8)
	add	(xsp+4), wa
	sub	(xsp+8), hl
.LDSR_9d82:
	ld	wa, (xsp+6)
	bit	0x01, wa
	jr z, .LDSR_9d98                       ; [66 0e] jr Z,0x299d98
	jr t, .LDSR_9db7                       ; [68 2b] jr T,0x299db7
.LDSR_9d8c:
	pushw	(0x239486:24)
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_9d98:
	ld	wa, (xsp+8)
	decm	1, (xsp+8)
	cp	wa, 0:i3
	jr nz, .LDSR_9d8c                      ; [6e ea] jr NZ,0x299d8c
	jr t, .LDSR_9db7                       ; [68 13] jr T,0x299db7
.LDSR_9da4:
	ld xwa, (xsp + 0x10)                    ; ld XWA,(XSP+0x10)
	ldb_spi c, 0xe0		; ld C,(XWA+)
	ld (xsp + 0x10), xwa                    ; ld (XSP+0x10),XWA
	exts bc                                 ; exts BC
	pushw bc                                ; push BC
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_9db7:
	ld	wa, (xsp+10)
	decm	1, (xsp+10)
	cp	wa, 0:i3
	jr nz, .LDSR_9da4                      ; [6e e3] jr NZ,0x299da4
	ld	wa, (xsp+6)
	bit	0x01, wa
	jr nz, .LDSR_9dd6                      ; [6e 0d] jr NZ,0x299dd6
	jrl t, HDAE5000_DoPrintf_NextChar                      ; [78 eb 05] jrl T,0x29a3b7
.LDSR_9dcc:
	pushw 0x0020
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_9dd6:
	ld	wa, (xsp+8)
	decm	1, (xsp+8)
	cp	wa, 0:i3
	jr nz, .LDSR_9dcc                      ; [6e ec] jr NZ,0x299dcc
	jrl t, HDAE5000_DoPrintf_NextChar                      ; [78 d4 05] jrl T,0x29a3b7
HDAE5000_DoPrintf_Case_Int:
	ld	wa, (xsp+6)
	bit	0x06, wa
	jr z, .LDSR_9dfc                       ; [66 11] jr Z,0x299dfc
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	ld	xwa, 4:i3
	add	(xbc), xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld	xwa, (xwa-4)
	ld (xsp + 0x10), xwa                    ; ld (XSP+0x10),XWA
	jr t, .LDSR_9e0d                       ; [68 11] jr T,0x299e0d
.LDSR_9dfc:
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	ld	xwa, 2:i3
	add	(xbc), xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld	wa, (xwa-2)
	exts xwa                                ; exts XWA
	ld (xsp + 0x10), xwa                    ; ld (XSP+0x10),XWA
.LDSR_9e0d:
	ldw (xsp + 0x0e), 0
	lda	xbc, (xsp+56)
	ld	wa, (xsp+6)
	bit	0x04, wa
	jr z, .LDSR_9e35                       ; [66 18] jr Z,0x299e35
	cpw	(xsp+10), 0x0000
	jr nz, .LDSR_9e35                      ; [6e 11] jr NZ,0x299e35
	ld xwa, (xsp + 0x10)                    ; ld XWA,(XSP+0x10)
	or xwa, xwa                             ; or XWA,XWA
	jr nz, .LDSR_9e35                      ; [6e 0a] jr NZ,0x299e35
	ld	(xbc), 0x00
	ldw (xsp + 0x0c), 0
	jr t, .LDSR_9e5b                       ; [68 26] jr T,0x299e5b
.LDSR_9e35:
	ld xwa, (xsp + 0x10)                    ; ld XWA,(XSP+0x10)
	push xwa
	push xbc
	calr	HDAE5000_Int_To_Decimal_String
	lda	xwa, (xsp+64)
	push xwa
	call HDAE5000_StrLen
	lda	xsp, (xsp+12)
	ld (xsp + 0x0c), hl
	ld xwa, (xsp + 0x10)                    ; ld XWA,(XSP+0x10)
	cp	xwa, 0x00000000
	jr ge, .LDSR_9e5b                      ; [69 05] jr GE,0x299e5b
	ldw (xsp + 0x0e), 1
.LDSR_9e5b:
	ld	wa, (xsp+6)
	bit	0x04, wa
	jr z, .LDSR_9e6b                       ; [66 08] jr Z,0x299e6b
	ld	wa, (xsp+10)
	cp	wa, (xsp+12)
	jr ge, .LDSR_9e72                      ; [69 07] jr GE,0x299e72
.LDSR_9e6b:
	ldw (xsp + 0x0a), 0
	jr t, .LDSR_9e78                       ; [68 06] jr T,0x299e78
.LDSR_9e72:
	ld	wa, (xsp+12)
	sub	(xsp+10), wa
.LDSR_9e78:
	ld	wa, (xsp+6)
	and	wa, 0x0005
	jr z, .LDSR_9e86                       ; [66 05] jr Z,0x299e86
	ldw (xsp + 0x0e), 1
.LDSR_9e86:
	ld	wa, (xsp+12)
	add	wa, (xsp+10)
	add	wa, (xsp+14)
	sub	(xsp+8), wa
	jr ge, .LDSR_9e99                      ; [69 05] jr GE,0x299e99
	ldw (xsp + 0x08), 0
.LDSR_9e99:
	ld	wa, (xsp+8)
	add	wa, (xsp+12)
	add	wa, (xsp+10)
	add	wa, (xsp+14)
	add	(xsp+4), wa
	cpw	(xsp+8), 0x0000
	jr z, .LDSR_9ee0                       ; [66 31] jr Z,0x299ee0
	ld	wa, (xsp+6)
	bit	0x01, wa
	jr nz, .LDSR_9ee0                      ; [6e 29] jr NZ,0x299ee0
	cpw	(0x239486:24), 32
	jr z, .LDSR_9ed1                       ; [66 11] jr Z,0x299ed1
	bit	0x04, wa
	jr nz, .LDSR_9ed1                      ; [6e 0c] jr NZ,0x299ed1
	jr t, .LDSR_9ee0                       ; [68 19] jr T,0x299ee0
.LDSR_9ec7:
	pushw 0x0020
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_9ed1:
	ld	wa, (xsp+8)
	decm	1, (xsp+8)
	cp	wa, 0:i3
	jr nz, .LDSR_9ec7                      ; [6e ec] jr NZ,0x299ec7
	ldw (xsp + 0x08), 0
.LDSR_9ee0:
	ld xwa, (xsp + 0x10)                    ; ld XWA,(XSP+0x10)
	cp	xwa, 0x00000000
	jr ge, .LDSR_9ef0                      ; [69 05] jr GE,0x299ef0
	pushw 0x002d
	jr t, .LDSR_9f08                       ; [68 18] jr T,0x299f08
.LDSR_9ef0:
	ld	wa, (xsp+6)
	bit	0x00, wa
	jr z, .LDSR_9efd                       ; [66 05] jr Z,0x299efd
	pushw 0x002b
	jr t, .LDSR_9f08                       ; [68 0b] jr T,0x299f08
.LDSR_9efd:
	ld	wa, (xsp+6)
	bit	0x02, wa
	jr z, .LDSR_9f0f                       ; [66 0a] jr Z,0x299f0f
	pushw 0x0020
.LDSR_9f08:
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_9f0f:
	ld	wa, (xsp+6)
	bit	0x01, wa
	jr nz, .LDSR_9f42                      ; [6e 2b] jr NZ,0x299f42
	cpw	(0x239486:24), 48
	jr z, .LDSR_9f2c                       ; [66 0c] jr Z,0x299f2c
	jr t, .LDSR_9f42                       ; [68 20] jr T,0x299f42
.LDSR_9f22:
	pushw 0x0030
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_9f2c:
	ld	wa, (xsp+8)
	decm	1, (xsp+8)
	cp	wa, 0:i3
	jr nz, .LDSR_9f22                      ; [6e ec] jr NZ,0x299f22
	jr t, .LDSR_9f42                       ; [68 0a] jr T,0x299f42
.LDSR_9f38:
	pushw 0x0030
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_9f42:
	ld	wa, (xsp+10)
	decm	1, (xsp+10)
	cp	wa, 0:i3
	jr nz, .LDSR_9f38                      ; [6e ec] jr NZ,0x299f38
	jr t, .LDSR_9f66                       ; [68 18] jr T,0x299f66
.LDSR_9f4e:
	decm	1, (xsp+12)
	lda	xbc, (xsp+56)
	ld	wa, (xsp+12)
	ldb_sri a, 0x07, 0xE4, 0xE0	; ld A,(XBC+WA)
	exts wa                                 ; exts WA
	pushw wa                                ; push WA
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_9f66:
	cpw	(xsp+12), 0x0000
	jr nz, .LDSR_9f4e                      ; [6e e1] jr NZ,0x299f4e
	ld	wa, (xsp+6)
	bit	0x01, wa
	jr nz, .LDSR_9f82                      ; [6e 0d] jr NZ,0x299f82
	jrl t, HDAE5000_DoPrintf_NextChar                      ; [78 3f 04] jrl T,0x29a3b7
.LDSR_9f78:
	pushw 0x0020
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_9f82:
	ld	wa, (xsp+8)
	decm	1, (xsp+8)
	cp	wa, 0:i3
	jr nz, .LDSR_9f78                      ; [6e ec] jr NZ,0x299f78
	jrl t, HDAE5000_DoPrintf_NextChar                      ; [78 28 04] jrl T,0x29a3b7
HDAE5000_DoPrintf_Case_Unsigned:
	ld	wa, (xsp+6)
	bit	0x06, wa
	jr z, .LDSR_9fa5                       ; [66 0e] jr Z,0x299fa5
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	ld	xwa, 4:i3
	add	(xbc), xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld	xde, (xwa-4)
	jr t, .LDSR_9fb3                       ; [68 0e] jr T,0x299fb3
.LDSR_9fa5:
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	ld	xwa, 2:i3
	add	(xbc), xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld	de, (xwa-2)
	extz xde                                ; extz XDE
.LDSR_9fb3:
	lda	xbc, (xsp+44)
	ld	wa, (xsp+6)
	bit	0x04, wa
	jr z, .LDSR_9fd0                       ; [66 12] jr Z,0x299fd0
	cpw	(xsp+10), 0x0000
	jr nz, .LDSR_9fd0                      ; [6e 0b] jr NZ,0x299fd0
	or xde, xde                             ; or XDE,XDE
	jr nz, .LDSR_9fd0                      ; [6e 07] jr NZ,0x299fd0
	ld	(xbc), 0x00
	ld	iz, 0:i3
	jr t, .LDSR_9fe2                       ; [68 12] jr T,0x299fe2
.LDSR_9fd0:
	push xde
	push xbc
	calr	HDAE5000_UInt_To_Decimal_String
	lda	xwa, (xsp+52)
	push xwa
	call HDAE5000_StrLen
	lda	xsp, (xsp+12)
	ld	iz, hl
.LDSR_9fe2:
	ld	wa, (xsp+6)
	bit	0x04, wa
	jr z, .LDSR_9fef                       ; [66 05] jr Z,0x299fef
	cp	(xsp+10), iz
	jr ge, .LDSR_9ff6                      ; [69 07] jr GE,0x299ff6
.LDSR_9fef:
	ldw (xsp + 0x0a), 0
	jr t, .LDSR_9ff9                       ; [68 03] jr T,0x299ff9
.LDSR_9ff6:
	sub	(xsp+10), iz
.LDSR_9ff9:
	ld	wa, iz
	add	wa, (xsp+10)
	sub	(xsp+8), wa
	jr ge, .LDSR_a008                      ; [69 05] jr GE,0x29a008
	ldw (xsp + 0x08), 0
.LDSR_a008:
	ld	wa, (xsp+8)
	add	wa, iz
	add	wa, (xsp+10)
	add	(xsp+4), wa
	ld	wa, (xsp+6)
	bit	0x01, wa
	jr z, .LDSR_a029                       ; [66 0e] jr Z,0x29a029
	jr t, .LDSR_a03f                       ; [68 22] jr T,0x29a03f
.LDSR_a01d:
	pushw	(0x239486:24)
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_a029:
	ld	wa, (xsp+8)
	decm	1, (xsp+8)
	cp	wa, 0:i3
	jr nz, .LDSR_a01d                      ; [6e ea] jr NZ,0x29a01d
	jr t, .LDSR_a03f                       ; [68 0a] jr T,0x29a03f
.LDSR_a035:
	pushw 0x0030
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_a03f:
	ld	wa, (xsp+10)
	decm	1, (xsp+10)
	cp	wa, 0:i3
	jr nz, .LDSR_a035                      ; [6e ec] jr NZ,0x29a035
	jr t, .LDSR_a05f                       ; [68 14] jr T,0x29a05f
.LDSR_a04b:
	dec	1, iz
	lda	xwa, (xsp+44)
	ldb_sri a, 0x07, 0xE0, 0xF8	; ld A,(XWA+IZ)
	exts wa                                 ; exts WA
	pushw wa                                ; push WA
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_a05f:
	cp	iz, 0:i3
	jr nz, .LDSR_a04b                      ; [6e e8] jr NZ,0x29a04b
	ld	wa, (xsp+6)
	bit	0x01, wa
	jr nz, .LDSR_a078                      ; [6e 0d] jr NZ,0x29a078
	jrl t, HDAE5000_DoPrintf_NextChar                      ; [78 49 03] jrl T,0x29a3b7
.LDSR_a06e:
	pushw 0x0020
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_a078:
	ld	wa, (xsp+8)
	decm	1, (xsp+8)
	cp	wa, 0:i3
	jr nz, .LDSR_a06e                      ; [6e ec] jr NZ,0x29a06e
	jrl t, HDAE5000_DoPrintf_NextChar                      ; [78 32 03] jrl T,0x29a3b7
HDAE5000_DoPrintf_Case_Pointer:
	setm	6, (xsp+6)
HDAE5000_DoPrintf_Case_Hex:
	ld	wa, (xsp+6)
	bit	0x06, wa
	jr z, .LDSR_a09e                       ; [66 0e] jr Z,0x29a09e
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	ld	xwa, 4:i3
	add	(xbc), xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld	xde, (xwa-4)
	jr t, .LDSR_a0ac                       ; [68 0e] jr T,0x29a0ac
.LDSR_a09e:
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	ld	xwa, 2:i3
	add	(xbc), xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld	de, (xwa-2)
	extz xde                                ; extz XDE
.LDSR_a0ac:
	lda	xbc, (xsp+32)
	ld	wa, (xsp+6)
	bit	0x04, wa
	jr z, .LDSR_a0cc                       ; [66 15] jr Z,0x29a0cc
	cpw	(xsp+10), 0x0000
	jr nz, .LDSR_a0cc                      ; [6e 0e] jr NZ,0x29a0cc
	or xde, xde                             ; or XDE,XDE
	jr nz, .LDSR_a0cc                      ; [6e 0a] jr NZ,0x29a0cc
	ld	(xbc), 0x00
	ldw (xsp + 0x12), 0
	jr t, .LDSR_a0e0                       ; [68 14] jr T,0x29a0e0
.LDSR_a0cc:
	pushw iz                                ; push IZ
	push xde
	push xbc
	calr	HDAE5000_Int_To_Hex_String
	lda	xwa, (xsp+42)
	push xwa
	call HDAE5000_StrLen
	lda	xsp, (xsp+14)
	ld (xsp + 0x12), hl
.LDSR_a0e0:
	ld	wa, (xsp+6)
	bit	0x04, wa
	jr z, .LDSR_a0f0                       ; [66 08] jr Z,0x29a0f0
	ld	wa, (xsp+10)
	cp	wa, (xsp+18)
	jr ge, .LDSR_a0f7                      ; [69 07] jr GE,0x29a0f7
.LDSR_a0f0:
	ldw (xsp + 0x0a), 0
	jr t, .LDSR_a0fd                       ; [68 06] jr T,0x29a0fd
.LDSR_a0f7:
	ld	wa, (xsp+18)
	sub	(xsp+10), wa
.LDSR_a0fd:
	ld	qiz, 0
	ld	wa, (xsp+6)
	bit	0x03, wa
	jr z, .LDSR_a10b                       ; [66 03] jr Z,0x29a10b
	ld	qiz, 2
.LDSR_a10b:
	ld	wa, (xsp+18)
	add	wa, (xsp+10)
	add	wa, qiz
	sub	(xsp+8), wa
	jr ge, .LDSR_a11e                      ; [69 05] jr GE,0x29a11e
	ldw (xsp + 0x08), 0
.LDSR_a11e:
	ld	wa, (xsp+8)
	add	wa, (xsp+18)
	add	wa, (xsp+10)
	add	wa, qiz
	add	(xsp+4), wa
	ld	wa, (xsp+6)
	bit	0x01, wa
	jr nz, .LDSR_a154                      ; [6e 1f] jr NZ,0x29a154
	cpw	(0x239486:24), 32
	jr z, .LDSR_a14a                       ; [66 0c] jr Z,0x29a14a
	jr t, .LDSR_a154                       ; [68 14] jr T,0x29a154
.LDSR_a140:
	pushw 0x0020
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_a14a:
	ld	wa, (xsp+8)
	decm	1, (xsp+8)
	cp	wa, 0:i3
	jr nz, .LDSR_a140                      ; [6e ec] jr NZ,0x29a140
.LDSR_a154:
	cp	qiz, 0
	jr z, .LDSR_a170                       ; [66 17] jr Z,0x29a170
	cpw	(xsp+18), 0x0000
	jr z, .LDSR_a170                       ; [66 10] jr Z,0x29a170
	pushw 0x0030
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	pushw iz                                ; push IZ
	ld xwa, (xsp + 0x5e)                    ; ld XWA,(XSP+0x5e)
	call	(xwa)
	inc 4, xsp                              ; inc 4,XSP
.LDSR_a170:
	ld	wa, (xsp+6)
	bit	0x01, wa
	jr nz, .LDSR_a1a3                      ; [6e 2b] jr NZ,0x29a1a3
	cpw	(0x239486:24), 48
	jr z, .LDSR_a18d                       ; [66 0c] jr Z,0x29a18d
	jr t, .LDSR_a1a3                       ; [68 20] jr T,0x29a1a3
.LDSR_a183:
	pushw 0x0030
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_a18d:
	ld	wa, (xsp+8)
	decm	1, (xsp+8)
	cp	wa, 0:i3
	jr nz, .LDSR_a183                      ; [6e ec] jr NZ,0x29a183
	jr t, .LDSR_a1a3                       ; [68 0a] jr T,0x29a1a3
.LDSR_a199:
	pushw 0x0030
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_a1a3:
	ld	wa, (xsp+10)
	decm	1, (xsp+10)
	cp	wa, 0:i3
	jr nz, .LDSR_a199                      ; [6e ec] jr NZ,0x29a199
	jr t, .LDSR_a1c7                       ; [68 18] jr T,0x29a1c7
.LDSR_a1af:
	decm	1, (xsp+18)
	lda	xbc, (xsp+32)
	ld	wa, (xsp+18)
	ldb_sri a, 0x07, 0xE4, 0xE0	; ld A,(XBC+WA)
	exts wa                                 ; exts WA
	pushw wa                                ; push WA
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_a1c7:
	cpw	(xsp+18), 0x0000
	jr nz, .LDSR_a1af                      ; [6e e1] jr NZ,0x29a1af
	ld	wa, (xsp+6)
	bit	0x01, wa
	jr nz, .LDSR_a1e3                      ; [6e 0d] jr NZ,0x29a1e3
	jrl t, HDAE5000_DoPrintf_NextChar                      ; [78 de 01] jrl T,0x29a3b7
.LDSR_a1d9:
	pushw 0x0020
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_a1e3:
	ld	wa, (xsp+8)
	decm	1, (xsp+8)
	cp	wa, 0:i3
	jr nz, .LDSR_a1d9                      ; [6e ec] jr NZ,0x29a1d9
	jrl t, HDAE5000_DoPrintf_NextChar                      ; [78 c7 01] jrl T,0x29a3b7
HDAE5000_DoPrintf_Case_Octal:
	ld	wa, (xsp+6)
	bit	0x06, wa
	jr z, .LDSR_a206                       ; [66 0e] jr Z,0x29a206
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	ld	xwa, 4:i3
	add	(xbc), xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld	xde, (xwa-4)
	jr t, .LDSR_a214                       ; [68 0e] jr T,0x29a214
.LDSR_a206:
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	ld	xwa, 2:i3
	add	(xbc), xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld	de, (xwa-2)
	extz xde                                ; extz XDE
.LDSR_a214:
	lda	xbc, (xsp+20)
	ld	wa, (xsp+6)
	bit	0x04, wa
	jr z, .LDSR_a231                       ; [66 12] jr Z,0x29a231
	cpw	(xsp+10), 0x0000
	jr nz, .LDSR_a231                      ; [6e 0b] jr NZ,0x29a231
	or xde, xde                             ; or XDE,XDE
	jr nz, .LDSR_a231                      ; [6e 07] jr NZ,0x29a231
	ld	(xbc), 0x00
	ld	iz, 0:i3
	jr t, .LDSR_a243                       ; [68 12] jr T,0x29a243
.LDSR_a231:
	push xde
	push xbc
	calr	HDAE5000_Int_To_Octal_String
	lda	xwa, (xsp+28)
	push xwa
	call HDAE5000_StrLen
	lda	xsp, (xsp+12)
	ld	iz, hl
.LDSR_a243:
	ld	wa, (xsp+6)
	bit	0x04, wa
	jr z, .LDSR_a250                       ; [66 05] jr Z,0x29a250
	cp	(xsp+10), iz
	jr ge, .LDSR_a257                      ; [69 07] jr GE,0x29a257
.LDSR_a250:
	ldw (xsp + 0x0a), 0
	jr t, .LDSR_a25a                       ; [68 03] jr T,0x29a25a
.LDSR_a257:
	sub	(xsp+10), iz
.LDSR_a25a:
	ld	wa, (xsp+6)
	and	wa, 0x0008
	cp	wa, 0:i3
	scc16	nz, wa
	ld (xsp + 0x12), wa                     ; ld (XSP+0x12),WA
	ld	wa, iz
	add	wa, (xsp+10)
	add	wa, (xsp+18)
	sub	(xsp+8), wa
	jr ge, .LDSR_a27a                      ; [69 05] jr GE,0x29a27a
	ldw (xsp + 0x08), 0
.LDSR_a27a:
	ld	wa, (xsp+8)
	add	wa, iz
	add	wa, (xsp+10)
	add	wa, (xsp+18)
	add	(xsp+4), wa
	ld	wa, (xsp+6)
	bit	0x01, wa
	jr nz, .LDSR_a2af                      ; [6e 1f] jr NZ,0x29a2af
	cpw	(0x239486:24), 32
	jr z, .LDSR_a2a5                       ; [66 0c] jr Z,0x29a2a5
	jr t, .LDSR_a2af                       ; [68 14] jr T,0x29a2af
.LDSR_a29b:
	pushw 0x0020
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_a2a5:
	ld	wa, (xsp+8)
	decm	1, (xsp+8)
	cp	wa, 0:i3
	jr nz, .LDSR_a29b                      ; [6e ec] jr NZ,0x29a29b
.LDSR_a2af:
	cpw	(xsp+18), 0x0000
	jr z, .LDSR_a2c4                       ; [66 0e] jr Z,0x29a2c4
	cp	iz, 0:i3
	jr z, .LDSR_a2c4                       ; [66 0a] jr Z,0x29a2c4
	pushw 0x0030
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_a2c4:
	ld	wa, (xsp+6)
	bit	0x01, wa
	jr nz, .LDSR_a2f7                      ; [6e 2b] jr NZ,0x29a2f7
	cpw	(0x239486:24), 48
	jr z, .LDSR_a2e1                       ; [66 0c] jr Z,0x29a2e1
	jr t, .LDSR_a2f7                       ; [68 20] jr T,0x29a2f7
.LDSR_a2d7:
	pushw 0x0030
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_a2e1:
	ld	wa, (xsp+8)
	decm	1, (xsp+8)
	cp	wa, 0:i3
	jr nz, .LDSR_a2d7                      ; [6e ec] jr NZ,0x29a2d7
	jr t, .LDSR_a2f7                       ; [68 0a] jr T,0x29a2f7
.LDSR_a2ed:
	pushw 0x0030
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_a2f7:
	ld	wa, (xsp+10)
	decm	1, (xsp+10)
	cp	wa, 0:i3
	jr nz, .LDSR_a2ed                      ; [6e ec] jr NZ,0x29a2ed
	jr t, .LDSR_a317                       ; [68 14] jr T,0x29a317
.LDSR_a303:
	dec	1, iz
	lda	xwa, (xsp+20)
	ldb_sri a, 0x07, 0xE0, 0xF8	; ld A,(XWA+IZ)
	exts wa                                 ; exts WA
	pushw wa                                ; push WA
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_a317:
	cp	iz, 0:i3
	jr nz, .LDSR_a303                      ; [6e e8] jr NZ,0x29a303
	ld	wa, (xsp+6)
	bit	0x01, wa
	jr nz, .LDSR_a330                      ; [6e 0d] jr NZ,0x29a330
	jrl t, HDAE5000_DoPrintf_NextChar                      ; [78 91 00] jrl T,0x29a3b7
.LDSR_a326:
	pushw 0x0020
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_a330:
	ld	wa, (xsp+8)
	decm	1, (xsp+8)
	cp	wa, 0:i3
	jr nz, .LDSR_a326                      ; [6e ec] jr NZ,0x29a326
	jr t, HDAE5000_DoPrintf_NextChar                       ; [68 7b] jr T,0x29a3b7
HDAE5000_DoPrintf_Case_Count:
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	ld	xwa, 4:i3
	add	(xbc), xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld	xbc, (xwa-4)
	ld	wa, (xsp+6)
	bit	0x06, wa
	jr z, .LDSR_a359                       ; [66 09] jr Z,0x29a359
	ld	wa, (xsp+4)
	exts xwa                                ; exts XWA
	ld (xbc), xwa                           ; ld (XBC),XWA
	jr t, HDAE5000_DoPrintf_NextChar                       ; [68 5e] jr T,0x29a3b7
.LDSR_a359:
	ld	wa, (xsp+4)
	ld (xbc), wa                            ; ld (XBC),WA
	jr t, HDAE5000_DoPrintf_NextChar                       ; [68 57] jr T,0x29a3b7
HDAE5000_DoPrintf_Case_Float:
	lda	xbc, (xsp+68)
	ld	wa, (xsp+6)
	bit	0x07, wa
	jr z, .LDSR_a380                       ; [66 15] jr Z,0x29a380
	ld	xwa, xbc
	ld xde, (xsp + 0x56)                    ; ld XDE,(XSP+0x56)
	lda_dd8l	xbc, (10); lda XBC,0x0a (F0 8-bit direct)
	add	(xde), xbc
	ld xbc, (xde)                           ; ld XBC,(XDE)
	lda	xbc, (xbc-10)
	call HDAE5000_Copy10
	jr t, .LDSR_a392                       ; [68 12] jr T,0x29a392
.LDSR_a380:
	ld	xwa, xbc
	ld xde, (xsp + 0x56)                    ; ld XDE,(XSP+0x56)
	lda_dd8l	xbc, (8); lda XBC,0x08 (F0 8-bit direct)
	add	(xde), xbc
	ld xbc, (xde)                           ; ld XBC,(XDE)
	dec 0, xbc                              ; dec 0,XBC
	call HDAE5000_Copy8
.LDSR_a392:
	pushm	(xsp+10)
	pushm	(xsp+10)
	pushm	(xsp+10)
	lda	xwa, (xsp+74)
	push xwa
	ld xwa, (xsp + 0x64)                    ; ld XWA,(XSP+0x64)
	push xwa
	stb_erp a, 0xf8		; ld A,IZL
	exts wa                                 ; exts WA
	pushw wa                                ; push WA
	calr	HDAE5000_FormatFloat
	lda	xsp, (xsp+16)
	ld	wa, (0x239488:24)
	add	(xsp+4), wa
HDAE5000_DoPrintf_NextChar:
	ld xwa, (xsp + 0x52)                    ; ld XWA,(XSP+0x52)
	ldb_spi c, 0xe0		; ld C,(XWA+)
	ld (xsp + 0x52), xwa                    ; ld (XSP+0x52),XWA
	ldb_erp c, 0xf8		; ld IZL,C
	exts	iz
	cp	iz, 0:i3
	jrl nz, .LDSR_9af3                     ; [7e 29 f7] jrl NZ,0x299af3
	ld	hl, (xsp+4)
	pop xiz                                 ; pop XIZ
	lda	xsp, (xsp+74)
	ret


; --- String Formatting Library (sprintf-like) ---
HDAE5000_Int_To_Decimal_String:	; 0x29A3D2 (80 bytes)
	; Convert signed 32-bit integer to decimal string
	; Stack: [+0x0C] = output buffer ptr (with write-ahead), [+0x10] = signed value
	; Negates if negative, then extracts digits via repeated /10
	dec 4, xsp			; allocate local scratch space
	push xiz
	ld xwa, (xsp + 16)		; load signed value
	cp xwa, 0x00000000		; check sign
	jr ge, .LInt_To_Dec__positive
	cpl wa				; negate low word
	cpl	qwa
	inc 1, xwa			; two's complement
.LInt_To_Dec__positive:
	ld xiz, xwa			; XIZ = |value|
.LInt_To_Dec__loop:
	ld xwa, (xsp + 12)		; get buffer state
	stb_dpi a, 0xE0			; lda XBC, (XWA+) — advance write ptr
	ld (xsp + 4), xbc		; save digit write position
	ld (xsp + 12), xwa		; save advanced buffer ptr
	ld xwa, xiz			; value to divide
	lda_dd8l xbc, (0x0A); divisor = 10
	call HDAE5000_UMod32	; XHL = remainder
	add xhl, 0x00000030		; remainder + '0' → ASCII digit
	ld xwa, (xsp + 4)		; get digit write position
	ld (xwa), l			; store digit character
	ld xwa, xiz			; reload value
	lda_dd8l xbc, (0x0A); divisor = 10
	call HDAE5000_UDivMod32	; XHL = quotient
	ld xiz, xhl			; update remaining value
	or xiz, xiz			; check if zero
	jr nz, .LInt_To_Dec__loop	; continue if non-zero
	ld xwa, (xsp + 12)		; get end-of-string position
	ld (xwa), 0x00		; null-terminate
	pop xiz
	inc 4, xsp			; deallocate scratch space
	ret

HDAE5000_UInt_To_Decimal_String:	; 0x29A422 (63 bytes)
	; Convert unsigned 32-bit integer to decimal string
	; Stack: [+0x0C] = output buffer ptr (with write-ahead), [+0x10] = unsigned value
	dec 4, xsp			; allocate local scratch space
	push xiz
	ld xiz, (xsp + 16)		; load unsigned value
.LUInt_To_Dec__loop:
	ld xwa, (xsp + 12)		; get buffer state
	stb_dpi a, 0xE0			; lda XBC, (XWA+) — advance write ptr
	ld (xsp + 4), xbc		; save digit write position
	ld (xsp + 12), xwa		; save advanced buffer ptr
	ld xwa, xiz			; value to divide
	lda_dd8l xbc, (0x0A); divisor = 10
	call HDAE5000_UMod32	; XHL = remainder
	add xhl, 0x00000030		; remainder + '0' → ASCII digit
	ld xwa, (xsp + 4)		; get digit write position
	ld (xwa), l			; store digit character
	ld xwa, xiz			; reload value
	lda_dd8l xbc, (0x0A); divisor = 10
	call HDAE5000_UDivMod32	; XHL = quotient
	ld xiz, xhl			; update remaining value
	or xiz, xiz			; check if zero
	jr nz, .LUInt_To_Dec__loop	; continue if non-zero
	ld xwa, (xsp + 12)		; get end-of-string position
	ld (xwa), 0x00		; null-terminate
	pop xiz
	inc 4, xsp			; deallocate scratch space
	ret

HDAE5000_Int_To_Hex_String:	; 0x29A461 (51 bytes)
	; Convert integer to hex string using nibble extraction
	; Stack: [+0x04] = output buffer ptr, [+0x08] = value, [+0x0C] = format char
	; If format char == 'x' (0x78), use lowercase hex digits; else uppercase
	ld xwa, HDAE5000_HexDigits_Upper	; uppercase hex digit table (default)
	cpw (xsp + 12), 0x0078	; format == 'x'?
	jr nz, .LInt_To_Hex__start
	ld xwa, HDAE5000_HexDigits_Lower	; lowercase hex digit table (format == 'x')
.LInt_To_Hex__start:
	ld xix, xwa			; XIX = digit table pointer
	ld xhl, (xsp + 4)		; buffer pointer
	ld xde, (xsp + 8)		; value to convert
.LInt_To_Hex__loop:
	stb_dpi a, 0xEC			; lda XBC, (XHL+) — post-increment buffer ptr
	ld xwa, xde
	and xwa, 0x0000000F		; mask low nibble
	add xwa, xix			; index into digit table
	ld a, (xwa)			; get hex digit char
	ld (xbc), a			; store to buffer
	srl xde, 4			; shift to next nibble
	jr nz, .LInt_To_Hex__loop
	ld (xhl), 0x00		; null-terminate
	ret

HDAE5000_Int_To_Octal_String:	; 0x29A494 (34 bytes)
	; Convert integer to octal string using 3-bit extraction
	; Stack: [+0x04] = output buffer ptr, [+0x08] = value
	ld xde, (xsp + 8)		; value to convert
	ld xhl, (xsp + 4)		; buffer pointer
.LInt_To_Octal__loop:
	stb_dpi a, 0xEC			; lda XBC, (XHL+) — post-increment buffer ptr
	ld xwa, xde
	and xwa, 0x00000007		; mask low 3 bits
	add xwa, 0x00000030		; convert to ASCII '0'-'7'
	ld (xbc), a			; store digit
	srl xde, 3			; shift to next octal digit
	jr nz, .LInt_To_Octal__loop
	ld (xhl), 0x00		; null-terminate
	ret

HDAE5000_FormatFloat:	; 0x29A4B6 (173 bytes)
	; sprintf-like formatter entry point (handles %e, %E, %f, %F, %g, %G)
	; Allocates 26-byte stack frame, dispatches to HDAE5000_FormatFloat_Fixed
	; (%f/%F) or HDAE5000_FormatFloat_Exp (%e/%E) based on format specifier
	; character in C register; %g/%G picks one by comparing the decimal
	; exponent HDAE5000_FltDec_Convert returns with -4 and with the precision.
	lda xsp, (xsp - 26)		; allocate 26-byte stack frame
	push xiz			; save XIZ
	ldw (xsp + 4), 0x0000		; clear local variable
	lda xwa, (xsp + 6)		; XWA = &local[2]
	push xwa			; push output buffer ptr
	lda xwa, (xsp + 8)		; XWA = &local[4] (adjusted)
	push xwa			; push another ptr
	pushm (xsp + 0x34)		; push caller param
	lda xwa, (xsp + 0x12)		; XWA = &local[14]
	push xwa			; push ptr
	ld xwa, (xsp + 0x36)		; load caller's 32-bit param
	push xwa			; push value
	call HDAE5000_FltDec_Convert			; call 0x29B07A (setup utility)
	lda xsp, (xsp + 0x12)		; deallocate 18 bytes of args
	ldw (0x239488:24), 0x0000; [0x239488] = 0 (clear format state)
	lda xde, (xsp + 8)		; XDE = &local[4]
	ld xiy, xde			; XIY = format output ptr
	ld c, (xsp + 0x22)		; C = format specifier char
	ld xiz, (xsp + 0x24)		; XIZ = caller param
	ld ix, (xsp + 0x2E)		; IX = precision
	ld hl, (xsp + 0x30)		; HL = width
	ld a, c				; A = specifier char
	exts wa				; sign-extend A to WA
	cp c, 0x65			; specifier == 'e'?
	jr z, .Lsf_e_format
	cp c, 0x45			; specifier == 'E'?
	jr nz, .Lsf_not_eE
.Lsf_e_format:
	pushm (xsp + 0x06)		; push param
	pushm (xsp + 0x06)		; push param
	push xiy			; push output ptr
	pushw hl			; push width
	pushw ix			; push precision
	pushm (xsp + 0x38)		; push caller param
	push xiz			; push XIZ
	pushw wa			; push specifier
	jr t, .Lsf_call_output		; always → String_Format_Output
.Lsf_not_eE:
	cp c, 0x66			; specifier == 'f'?
	jr z, .Lsf_f_format
	cp c, 0x46			; specifier == 'F'?
	jr nz, .Lsf_not_fF
.Lsf_f_format:
	pushm (xsp + 0x06)		; push param
	pushm (xsp + 0x06)		; push param
	push xiy			; push output ptr
	pushw hl			; push width
	pushw ix			; push precision
	pushm (xsp + 0x38)		; push caller param
	push xiz			; push XIZ
	pushw wa			; push specifier
.Lsf_call_core:
	calr HDAE5000_FormatFloat_Fixed
	lda xsp, (xsp + 0x14)		; deallocate 20 bytes of args
	jr t, .Lsf_cleanup		; always → cleanup
.Lsf_not_fF:				; g/G format handling
	ld wa, (xsp + 0x2C)		; WA = flags
	bit 4, wa			; bit 4 set?
	jr nz, .Lsf_have_precision
	ld hl, 6:i3			; default precision = 6
	setm 4, (xsp + 0x2C)		; set precision flag
.Lsf_have_precision:
	exts bc				; sign-extend C to BC
	pushm (xsp + 0x06)		; push param
	pushm (xsp + 0x06)		; push param
	push xde			; push XDE
	pushw hl			; push width
	pushw ix			; push precision
	pushm (xsp + 0x38)		; push caller param
	push xiz			; push XIZ
	pushw bc			; push specifier (extended)
	cpw (xsp + 0x18), 0xFFFC	; compare local with -4?
	jr le, .Lsf_call_output		; if LE → output
	cp (xsp + 0x18), hl		; compare local with width
	jr le, .Lsf_call_core		; if LE → use Core formatter
.Lsf_call_output:
	calr HDAE5000_FormatFloat_Exp
	lda xsp, (xsp + 0x14)		; deallocate 20 bytes of args
.Lsf_cleanup:
	pop xiz				; restore XIZ
	lda xsp, (xsp + 0x1A)		; deallocate 26-byte stack frame
	ret

HDAE5000_FormatFloat_Fixed:	; 0x29A563 (805 bytes)
	; Core string format engine - processes format specifiers
	; Fixed-point (%f / %F, and %g in fixed range) conversion of the decimal
	; digits HDAE5000_FltDec_Convert produced: pads/rounds to the precision
	; and emits every character through the putc callback (the same
	; `call (xwa)` convention as HDAE5000_DoPrintf).  Called only by
	; HDAE5000_FormatFloat.
; LSFC: 0x29A563 (805 bytes)

	dec	4, xsp
	pushw iz                                ; push IZ
	ldw (xsp + 0x04), 15
	cpw	(xsp+26), 0x0001
	jr ge, .LSFC_a579                      ; [69 07] jr GE,0x29a579
	ldw (xsp + 0x02), 0
	jr t, .LSFC_a57f                       ; [68 06] jr T,0x29a57f
.LSFC_a579:
	ld	wa, (xsp+26)
	ld (xsp + 0x02), wa                     ; ld (XSP+0x02),WA
.LSFC_a57f:
	ld	wa, (xsp+16)
	bit	0x04, wa
	jr nz, .LSFC_a58c                      ; [6e 05] jr NZ,0x29a58c
	ldw (xsp + 0x14), 6
.LSFC_a58c:
	ld	wa, (xsp+16)
	bit	0x07, wa
	jr z, .LSFC_a599                       ; [66 05] jr Z,0x29a599
	ldw (xsp + 0x04), 18
.LSFC_a599:
	ld	c, (xsp+10)
	ld	a, c
	extz wa                                 ; extz WA
	lda xde, (HDAE5000_CType_Table:24)
	lda_dri xde, 0x07, 0xE8, 0xE0	; lda XDE,XDE+WA
	bitm	1, (xde)
	jr z, .LSFC_a5b5                       ; [66 07] jr Z,0x29a5b5
	ld	a, c
	sub	a, 0x20
	jr t, .LSFC_a5b7                       ; [68 02] jr T,0x29a5b7
.LSFC_a5b5:
	ld	a, c
.LSFC_a5b7:
	cp	a, 0x47
	jr nz, .LSFC_a5c1                      ; [6e 05] jr NZ,0x29a5c1
	ld	iz, (xsp+20)
	jr t, .LSFC_a5c7                       ; [68 06] jr T,0x29a5c7
.LSFC_a5c1:
	ld	iz, (xsp+20)
	add	iz, (xsp+26)
.LSFC_a5c7:
	ld	wa, (xsp+4)
	inc	1, wa
	cp	iz, wa
	jr ge, .LSFC_a600                      ; [69 30] jr GE,0x29a600
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	cpib_sri 0x07, 0xE0, 0xF8, 0x34	; cp (XWA+IZ),0x34
	jr le, .LSFC_a600                      ; [62 25] jr LE,0x29a600
	cp	iz, 0:i3
	jr ge, .LSFC_a5ea                      ; [69 0b] jr GE,0x29a5ea
	jr t, .LSFC_a600                       ; [68 1f] jr T,0x29a600
.LSFC_a5e1:
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	stib_ind 0x07, 0xE0, 0xF8, 0x30	; ld (XWA+IZ),0x30
.LSFC_a5ea:
	dec	1, iz
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	inc_srib 1, 0x07, 0xE0, 0xF8	; inc 1,(XWA+IZ)
	cp	iz, 0:i3
	jr le, .LSFC_a600                      ; [62 08] jr LE,0x29a600
	cpib_sri 0x07, 0xE0, 0xF8, 0x39	; cp (XWA+IZ),0x39
	jr gt, .LSFC_a5e1                      ; [6a e1] jr GT,0x29a5e1
.LSFC_a600:
	ld	e, (xde)
	bit	0x01, e
	jr z, .LSFC_a60e                       ; [66 07] jr Z,0x29a60e
	ld	a, c
	sub	a, 0x20
	jr t, .LSFC_a610                       ; [68 02] jr T,0x29a610
.LSFC_a60e:
	ld	a, c
.LSFC_a610:
	cp	a, 0x47
	jr nz, .LSFC_a622                      ; [6e 0d] jr NZ,0x29a622
	ld	iz, (xsp+20)
	dec	1, iz
	ld	wa, (xsp+26)
	neg	wa
	add	(xsp+20), wa
.LSFC_a622:
	bit	0x01, e
	jr z, .LSFC_a62a                       ; [66 03] jr Z,0x29a62a
	sub	c, 0x20
.LSFC_a62a:
	cp	c, 0x47
	jr nz, .LSFC_a649                      ; [6e 1a] jr NZ,0x29a649
	ld	wa, (xsp+16)
	bit	0x03, wa
	jr z, .LSFC_a63e                       ; [66 07] jr Z,0x29a63e
	jr t, .LSFC_a649                       ; [68 10] jr T,0x29a649
.LSFC_a639:
	dec	1, iz
	decm	1, (xsp+20)
.LSFC_a63e:
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	cpib_sri 0x07, 0xE0, 0xF8, 0x30	; cp (XWA+IZ),0x30
	jr z, .LSFC_a639                       ; [66 f0] jr Z,0x29a639
.LSFC_a649:
	ld	wa, (xsp+16)
	bit	0x04, wa
	jr z, .LSFC_a658                       ; [66 07] jr Z,0x29a658
	cpw	(xsp+20), 0x0000
	jr z, .LSFC_a65b                       ; [66 03] jr Z,0x29a65b
.LSFC_a658:
	decm	1, (xsp+18)
.LSFC_a65b:
	ld	iz, (xsp+28)
	cp	iz, 0:i3
	jr nz, .LSFC_a66b                      ; [6e 09] jr NZ,0x29a66b
	ld	wa, (xsp+16)
	and	wa, 0x0005
	jr z, .LSFC_a66e                       ; [66 03] jr Z,0x29a66e
.LSFC_a66b:
	decm	1, (xsp+18)
.LSFC_a66e:
	ld	wa, (xsp+2)
	add	wa, (xsp+20)
	sub	(xsp+18), wa
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	cp	(xwa), 0x39
	jr le, .LSFC_a682                      ; [62 03] jr LE,0x29a682
	decm	1, (xsp+18)
.LSFC_a682:
	cpw	(xsp+18), 0x0000
	jr ge, .LSFC_a68e                      ; [69 05] jr GE,0x29a68e
	ldw (xsp + 0x12), 0
.LSFC_a68e:
	ld	wa, (xsp+16)
	bit	0x01, wa
	jr nz, .LSFC_a6ba                      ; [6e 24] jr NZ,0x29a6ba
	cpw	(0x239486:24), 32
	jr z, .LSFC_a6b0                       ; [66 11] jr Z,0x29a6b0
	jr t, .LSFC_a6ba                       ; [68 19] jr T,0x29a6ba
.LSFC_a6a1:
	pushw 0x0020
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incw	1, (0x239488:24)
.LSFC_a6b0:
	ld	wa, (xsp+18)
	decm	1, (xsp+18)
	cp	wa, 0:i3
	jr gt, .LSFC_a6a1                      ; [6a e7] jr GT,0x29a6a1
.LSFC_a6ba:
	cp	iz, 0:i3
	jr z, .LSFC_a6c3                       ; [66 05] jr Z,0x29a6c3
	pushw 0x002d
	jr t, .LSFC_a6db                       ; [68 18] jr T,0x29a6db
.LSFC_a6c3:
	ld	wa, (xsp+16)
	bit	0x00, wa
	jr z, .LSFC_a6d0                       ; [66 05] jr Z,0x29a6d0
	pushw 0x002b
	jr t, .LSFC_a6db                       ; [68 0b] jr T,0x29a6db
.LSFC_a6d0:
	ld	wa, (xsp+16)
	bit	0x02, wa
	jr z, .LSFC_a6e7                       ; [66 0f] jr Z,0x29a6e7
	pushw 0x0020
.LSFC_a6db:
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incw	1, (0x239488:24)
.LSFC_a6e7:
	ld	wa, (xsp+16)
	bit	0x01, wa
	jr nz, .LSFC_a713                      ; [6e 24] jr NZ,0x29a713
	cpw	(0x239486:24), 48
	jr z, .LSFC_a709                       ; [66 11] jr Z,0x29a709
	jr t, .LSFC_a713                       ; [68 19] jr T,0x29a713
.LSFC_a6fa:
	pushw 0x0030
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incw	1, (0x239488:24)
.LSFC_a709:
	ld	wa, (xsp+18)
	decm	1, (xsp+18)
	cp	wa, 0:i3
	jr gt, .LSFC_a6fa                      ; [6a e7] jr GT,0x29a6fa
.LSFC_a713:
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	cp	(xwa), 0x39
	jr le, .LSFC_a734                      ; [62 19] jr LE,0x29a734
	cpw	(xsp+26), 0x0000
	jr lt, .LSFC_a734                      ; [61 12] jr LT,0x29a734
	pushw 0x0031
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	ld	(xwa), 0x30
	jr t, .LSFC_a745                       ; [68 11] jr T,0x29a745
.LSFC_a734:
	cpw	(xsp+26), 0x0000
	jr gt, .LSFC_a74a                      ; [6a 0f] jr GT,0x29a74a
	pushw 0x0030
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LSFC_a745:
	incw	1, (0x239488:24)
.LSFC_a74a:
	ld	iz, 0:i3
	jr t, .LSFC_a767                       ; [68 19] jr T,0x29a767
.LSFC_a74e:
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	ldb_sri a, 0x07, 0xE0, 0xF8	; ld A,(XWA+IZ)
	exts wa                                 ; exts WA
	pushw wa                                ; push WA
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incw	1, (0x239488:24)
	inc	1, iz
.LSFC_a767:
	ld	wa, (xsp+4)
	inc	1, wa
	cp	iz, wa
	jr ge, .LSFC_a78b                      ; [69 1b] jr GE,0x29a78b
	ld	wa, (xsp+2)
	decm	1, (xsp+2)
	cp	wa, 0:i3
	jr gt, .LSFC_a74e                      ; [6a d4] jr GT,0x29a74e
	jr t, .LSFC_a78b                       ; [68 0f] jr T,0x29a78b
.LSFC_a77c:
	pushw 0x0030
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incw	1, (0x239488:24)
.LSFC_a78b:
	ld	wa, (xsp+2)
	decm	1, (xsp+2)
	cp	wa, 0:i3
	jr gt, .LSFC_a77c                      ; [6a e7] jr GT,0x29a77c
	ld	wa, (xsp+16)
	bit	0x03, wa
	jr nz, .LSFC_a7a4                      ; [6e 07] jr NZ,0x29a7a4
	cpw	(xsp+20), 0x0000
	jr z, .LSFC_a7ea                       ; [66 46] jr Z,0x29a7ea
.LSFC_a7a4:
	pushw 0x002e
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incw	1, (0x239488:24)
	jr t, .LSFC_a7ea                       ; [68 35] jr T,0x29a7ea
.LSFC_a7b5:
	ld	wa, (xsp+26)
	add	wa, 0x0001
	jr nz, .LSFC_a7d8                      ; [6e 1a] jr NZ,0x29a7d8
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	cp	(xwa), 0x39
	jr le, .LSFC_a7d8                      ; [62 12] jr LE,0x29a7d8
	pushw 0x0031
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	ld	(xwa), 0x30
	jr t, .LSFC_a7e2                       ; [68 0a] jr T,0x29a7e2
.LSFC_a7d8:
	pushw 0x0030
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LSFC_a7e2:
	incw	1, (0x239488:24)
	incw	1, (xsp+26)
.LSFC_a7ea:
	cpw	(xsp+26), 0x0000
	jr ge, .LSFC_a7fb                      ; [69 0a] jr GE,0x29a7fb
	ld	wa, (xsp+20)
	decm	1, (xsp+20)
	cp	wa, 0:i3
	jr nz, .LSFC_a7b5                      ; [6e ba] jr NZ,0x29a7b5
.LSFC_a7fb:
	ld	wa, (xsp+4)
	inc	1, wa
	cp	iz, wa
	jr lt, .LSFC_a81f                      ; [61 1b] jr LT,0x29a81f
	jr t, .LSFC_a843                       ; [68 3d] jr T,0x29a843
.LSFC_a806:
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	ldb_sri a, 0x07, 0xE0, 0xF8	; ld A,(XWA+IZ)
	exts wa                                 ; exts WA
	pushw wa                                ; push WA
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incw	1, (0x239488:24)
	inc	1, iz
.LSFC_a81f:
	ld	wa, (xsp+4)
	inc	1, wa
	cp	iz, wa
	jr ge, .LSFC_a843                      ; [69 1b] jr GE,0x29a843
	ld	wa, (xsp+20)
	decm	1, (xsp+20)
	cp	wa, 0:i3
	jr gt, .LSFC_a806                      ; [6a d4] jr GT,0x29a806
	jr t, .LSFC_a843                       ; [68 0f] jr T,0x29a843
.LSFC_a834:
	pushw 0x0030
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incw	1, (0x239488:24)
.LSFC_a843:
	ld	wa, (xsp+20)
	decm	1, (xsp+20)
	cp	wa, 0:i3
	jr gt, .LSFC_a834                      ; [6a e7] jr GT,0x29a834
	ld	wa, (xsp+16)
	bit	0x01, wa
	jr nz, .LSFC_a866                      ; [6e 11] jr NZ,0x29a866
	jr t, .LSFC_a870                       ; [68 19] jr T,0x29a870
.LSFC_a857:
	pushw 0x0020
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incw	1, (0x239488:24)
.LSFC_a866:
	ld	wa, (xsp+18)
	decm	1, (xsp+18)
	cp	wa, 0:i3
	jr gt, .LSFC_a857                      ; [6a e7] jr GT,0x29a857
.LSFC_a870:
	popw iz                                 ; pop IZ
	inc 4, xsp                              ; inc 4,XSP
	ret

	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
.LSFC_a877:
	cp	(xwa), 0x00
	jr nz, .LSFC_a87f                      ; [6e 03] jr NZ,0x29a87f
	ld	hl, 1:i3
	ret

.LSFC_a87f:
	cp_spib_im	224, 48                 ; cp (XWA+), 0x30
	jr z, .LSFC_a877                       ; [66 f2] jr Z,0x29a877
	ld	hl, 0:i3
	ret


HDAE5000_FormatFloat_Exp:	; 0x29A888 (848 bytes)
	; Output handler for string formatter
	; Exponential (%e / %E, and %g out of fixed range) conversion: emits
	; d.ddd, then the exponent letter (toupper(spec)=='G' -> spec-2, i.e.
	; 'e'/'E') and the exponent through HDAE5000_Int_To_Decimal_String.
	; Case tests use HDAE5000_CType_Table bit 1 (lower case).  Called only by
	; HDAE5000_FormatFloat.
; LSFO: 0x29A888 (848 bytes)

	dec	2, xsp
	push xiz
	ldw (xsp + 0x04), 15
	ld	wa, (xsp+16)
	bit	0x04, wa
	jr nz, .LSFO_a89d                      ; [6e 05] jr NZ,0x29a89d
	ldw (xsp + 0x14), 6
.LSFO_a89d:
	ld	a, (xsp+10)
	extz wa                                 ; extz WA
	lda xbc, (HDAE5000_CType_Table:24)
	lda_dri xbc, 0x07, 0xE4, 0xE0	; lda XBC,XBC+WA
	bitm	1, (xbc)
	jr z, .LSFO_a8b8                       ; [66 08] jr Z,0x29a8b8
	ld	a, (xsp+10)
	sub	a, 0x20
	jr t, .LSFO_a8bb                       ; [68 03] jr T,0x29a8bb
.LSFO_a8b8:
	ld	a, (xsp+10)
.LSFO_a8bb:
	cp	a, 0x47
	jr nz, .LSFO_a8ca                      ; [6e 0a] jr NZ,0x29a8ca
	cpw	(xsp+20), 0x0000
	jr z, .LSFO_a8ca                       ; [66 03] jr Z,0x29a8ca
	decm	1, (xsp+20)
.LSFO_a8ca:
	ld	wa, (xsp+20)
	inc	1, wa
	ld	qiz, wa
	ld	wa, (xsp+16)
	bit	0x07, wa
	jr z, .LSFO_a8df                       ; [66 05] jr Z,0x29a8df
	ldw (xsp + 0x04), 18
.LSFO_a8df:
	ld	de, (xsp+4)
	inc	1, de
	ld	wa, qiz
	cp	wa, de
	jr ge, .LSFO_a91f                      ; [69 34] jr GE,0x29a91f
	ld	de, qiz
	dec	1, qiz
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	cpib_sri 0x07, 0xE0, 0xE8, 0x34	; cp (XWA+DE),0x34
	jr gt, .LSFO_a90a                      ; [6a 0e] jr GT,0x29a90a
	jr t, .LSFO_a91f                       ; [68 21] jr T,0x29a91f
.LSFO_a8fe:
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	stib_ind 0x07, 0xE0, 0xFA, 0x30	; ld (XWA+QIZ),0x30
	dec	1, qiz
.LSFO_a90a:
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	inc_srib 1, 0x07, 0xE0, 0xFA	; inc 1,(XWA+QIZ)
	cp	qiz, 0
	jr le, .LSFO_a91f                      ; [62 08] jr LE,0x29a91f
	cpib_sri 0x07, 0xE0, 0xFA, 0x39	; cp (XWA+QIZ),0x39
	jr gt, .LSFO_a8fe                      ; [6a df] jr GT,0x29a8fe
.LSFO_a91f:
	bitm	1, (xbc)
	jr z, .LSFO_a92b                       ; [66 08] jr Z,0x29a92b
	ld	a, (xsp+10)
	sub	a, 0x20
	jr t, .LSFO_a92e                       ; [68 03] jr T,0x29a92e
.LSFO_a92b:
	ld	a, (xsp+10)
.LSFO_a92e:
	cp	a, 0x47
	jr nz, .LSFO_a959                      ; [6e 26] jr NZ,0x29a959
	ld	wa, (xsp+16)
	bit	0x03, wa
	jr nz, .LSFO_a959                      ; [6e 1e] jr NZ,0x29a959
	ld	wa, (xsp+20)
	ld	qiz, wa
	jr t, .LSFO_a949                       ; [68 06] jr T,0x29a949
.LSFO_a943:
	dec	1, qiz
	decm	1, (xsp+20)
.LSFO_a949:
	cp	qiz, 0
	jr le, .LSFO_a959                      ; [62 0b] jr LE,0x29a959
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	cpib_sri 0x07, 0xE0, 0xFA, 0x30	; cp (XWA+QIZ),0x30
	jr z, .LSFO_a943                       ; [66 ea] jr Z,0x29a943
.LSFO_a959:
	decm	5, (xsp+18)
	ld	wa, (xsp+16)
	bit	0x04, wa
	jr z, .LSFO_a96b                       ; [66 07] jr Z,0x29a96b
	cpw	(xsp+20), 0x0000
	jr z, .LSFO_a96e                       ; [66 03] jr Z,0x29a96e
.LSFO_a96b:
	decm	1, (xsp+18)
.LSFO_a96e:
	ld	iz, (xsp+28)
	cp	iz, 0:i3
	jr nz, .LSFO_a97e                      ; [6e 09] jr NZ,0x29a97e
	ld	wa, (xsp+16)
	and	wa, 0x0005
	jr z, .LSFO_a981                       ; [66 03] jr Z,0x29a981
.LSFO_a97e:
	decm	1, (xsp+18)
.LSFO_a981:
	ld	wa, (xsp+20)
	sub	(xsp+18), wa
	jr ge, .LSFO_a98e                      ; [69 05] jr GE,0x29a98e
	ldw (xsp + 0x12), 0
.LSFO_a98e:
	ld	wa, (xsp+16)
	bit	0x01, wa
	jr nz, .LSFO_a9ba                      ; [6e 24] jr NZ,0x29a9ba
	cpw	(0x239486:24), 32
	jr z, .LSFO_a9b0                       ; [66 11] jr Z,0x29a9b0
	jr t, .LSFO_a9ba                       ; [68 19] jr T,0x29a9ba
.LSFO_a9a1:
	pushw 0x0020
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incw	1, (0x239488:24)
.LSFO_a9b0:
	decm	1, (xsp+18)
	cpw	(xsp+18), 0x0000
	jr gt, .LSFO_a9a1                      ; [6a e7] jr GT,0x29a9a1
.LSFO_a9ba:
	cp	iz, 0:i3
	jr z, .LSFO_a9c3                       ; [66 05] jr Z,0x29a9c3
	pushw 0x002d
	jr t, .LSFO_a9db                       ; [68 18] jr T,0x29a9db
.LSFO_a9c3:
	ld	wa, (xsp+16)
	bit	0x00, wa
	jr z, .LSFO_a9d0                       ; [66 05] jr Z,0x29a9d0
	pushw 0x002b
	jr t, .LSFO_a9db                       ; [68 0b] jr T,0x29a9db
.LSFO_a9d0:
	ld	wa, (xsp+16)
	bit	0x02, wa
	jr z, .LSFO_a9e7                       ; [66 0f] jr Z,0x29a9e7
	pushw 0x0020
.LSFO_a9db:
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incw	1, (0x239488:24)
.LSFO_a9e7:
	ld	wa, (xsp+16)
	bit	0x01, wa
	jr nz, .LSFO_aa13                      ; [6e 24] jr NZ,0x29aa13
	cpw	(0x239486:24), 48
	jr z, .LSFO_aa09                       ; [66 11] jr Z,0x29aa09
	jr t, .LSFO_aa13                       ; [68 19] jr T,0x29aa13
.LSFO_a9fa:
	pushw 0x0030
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incw	1, (0x239488:24)
.LSFO_aa09:
	decm	1, (xsp+18)
	cpw	(xsp+18), 0x0000
	jr gt, .LSFO_a9fa                      ; [6a e7] jr GT,0x29a9fa
.LSFO_aa13:
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	cp	(xwa), 0x39
	jr le, .LSFO_aa44                      ; [62 29] jr LE,0x29aa44
	pushw 0x0031
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	ld	(xwa), 0x30
	ld	qiz, 0
	incw	1, (0x239488:24)
	cpw	(xsp+26), 0x0000
	jr ge, .LSFO_aa3f                      ; [69 05] jr GE,0x29aa3f
	incw	1, (xsp+26)
	jr t, .LSFO_aa5b                       ; [68 1c] jr T,0x29aa5b
.LSFO_aa3f:
	decm	1, (xsp+26)
	jr t, .LSFO_aa5b                       ; [68 17] jr T,0x29aa5b
.LSFO_aa44:
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	ld	a, (xwa)
	exts wa                                 ; exts WA
	pushw wa                                ; push WA
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incw	1, (0x239488:24)
	ld	qiz, 1
.LSFO_aa5b:
	cpw	(xsp+20), 0x0000
	jr nz, .LSFO_aa6a                      ; [6e 08] jr NZ,0x29aa6a
	ld	wa, (xsp+16)
	bit	0x03, wa
	jr z, .LSFO_aa79                       ; [66 0f] jr Z,0x29aa79
.LSFO_aa6a:
	pushw 0x002e
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incw	1, (0x239488:24)
.LSFO_aa79:
	ld	c, (xsp+10)
	extz bc                                 ; extz BC
	lda xwa, (HDAE5000_CType_Table:24)
	bit_dri 1, 0x07, 0xE0, 0xE4	; bit 1,(XWA+BC)
	jr z, .LSFO_aa92                       ; [66 08] jr Z,0x29aa92
	ld	a, (xsp+10)
	sub	a, 0x20
	jr t, .LSFO_aa95                       ; [68 03] jr T,0x29aa95
.LSFO_aa92:
	ld	a, (xsp+10)
.LSFO_aa95:
	cp	a, 0x47
	jr nz, .LSFO_aaa9                      ; [6e 0f] jr NZ,0x29aaa9
	cpw	(xsp+20), 0x0000
	jr nz, .LSFO_aaa9                      ; [6e 08] jr NZ,0x29aaa9
	cpw	(xsp+26), 0x0001
	jrl z, .LSFO_abd4                      ; [76 2b 01] jrl Z,0x29abd4
.LSFO_aaa9:
	ld	bc, (xsp+4)
	inc	1, bc
	ld	wa, qiz
	cp	wa, bc
	jr lt, .LSFO_aad1                      ; [61 1c] jr LT,0x29aad1
	jr t, .LSFO_aaf8                       ; [68 41] jr T,0x29aaf8
.LSFO_aab7:
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	ldb_sri a, 0x07, 0xE0, 0xFA	; ld A,(XWA+QIZ)
	exts wa                                 ; exts WA
	pushw wa                                ; push WA
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incw	1, (0x239488:24)
	inc	1, qiz
.LSFO_aad1:
	ld	bc, (xsp+4)
	inc	1, bc
	ld	wa, qiz
	cp	wa, bc
	jr ge, .LSFO_aaf8                      ; [69 1b] jr GE,0x29aaf8
	ld	wa, (xsp+20)
	decm	1, (xsp+20)
	cp	wa, 0:i3
	jr gt, .LSFO_aab7                      ; [6a d0] jr GT,0x29aab7
	jr t, .LSFO_aaf8                       ; [68 0f] jr T,0x29aaf8
.LSFO_aae9:
	pushw 0x0030
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incw	1, (0x239488:24)
.LSFO_aaf8:
	ld	wa, (xsp+20)
	decm	1, (xsp+20)
	cp	wa, 0:i3
	jr gt, .LSFO_aae9                      ; [6a e7] jr GT,0x29aae9
	decm	1, (xsp+26)
	ld	wa, (xsp+26)
	exts xwa                                ; exts XWA
	push xwa
	ld xwa, (xsp + 0x1a)                    ; ld XWA,(XSP+0x1a)
	push xwa
	calr	HDAE5000_Int_To_Decimal_String
	ld xwa, (xsp + 0x1e)                    ; ld XWA,(XSP+0x1e)
	push xwa
	call HDAE5000_StrLen
	lda	xsp, (xsp+12)
	ld	iz, hl
	ld	c, (xsp+10)
	extz bc                                 ; extz BC
	lda xwa, (HDAE5000_CType_Table:24)
	bit_dri 1, 0x07, 0xE0, 0xE4	; bit 1,(XWA+BC)
	jr z, .LSFO_ab38                       ; [66 08] jr Z,0x29ab38
	ld	a, (xsp+10)
	sub	a, 0x20
	jr t, .LSFO_ab3b                       ; [68 03] jr T,0x29ab3b
.LSFO_ab38:
	ld	a, (xsp+10)
.LSFO_ab3b:
	cp	a, 0x47
	jr nz, .LSFO_ab47                      ; [6e 07] jr NZ,0x29ab47
	ld	a, (xsp+10)
	dec	2, a
	jr t, .LSFO_ab4a                       ; [68 03] jr T,0x29ab4a
.LSFO_ab47:
	ld	a, (xsp+10)
.LSFO_ab4a:
	exts wa                                 ; exts WA
	pushw wa                                ; push WA
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incw	1, (0x239488:24)
	cpw	(xsp+26), 0x0000
	jr ge, .LSFO_ab65                      ; [69 05] jr GE,0x29ab65
	pushw 0x002d
	jr t, .LSFO_ab68                       ; [68 03] jr T,0x29ab68
.LSFO_ab65:
	pushw 0x002b
.LSFO_ab68:
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incw	1, (0x239488:24)
	ld	qiz, iz
	jr t, .LSFO_ab88                       ; [68 0f] jr T,0x29ab88
.LSFO_ab79:
	pushw 0x0030
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incw	1, (0x239488:24)
.LSFO_ab88:
	ld	wa, qiz
	inc	1, qiz
	cp	wa, 3:i3
	jr lt, .LSFO_ab79                      ; [61 e7] jr LT,0x29ab79
	jr t, .LSFO_abad                       ; [68 19] jr T,0x29abad
.LSFO_ab94:
	dec	1, iz
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	ldb_sri a, 0x07, 0xE0, 0xF8	; ld A,(XWA+IZ)
	exts wa                                 ; exts WA
	pushw wa                                ; push WA
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incw	1, (0x239488:24)
.LSFO_abad:
	cp	iz, 0:i3
	jr nz, .LSFO_ab94                      ; [6e e3] jr NZ,0x29ab94
	ld	wa, (xsp+16)
	bit	0x01, wa
	jr nz, .LSFO_abca                      ; [6e 11] jr NZ,0x29abca
	jr t, .LSFO_abd4                       ; [68 19] jr T,0x29abd4
.LSFO_abbb:
	pushw 0x0020
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incw	1, (0x239488:24)
.LSFO_abca:
	decm	1, (xsp+18)
	cpw	(xsp+18), 0x0000
	jr gt, .LSFO_abbb                      ; [6a e7] jr GT,0x29abbb
.LSFO_abd4:
	pop xiz                                 ; pop XIZ
	inc 2, xsp                              ; inc 2,XSP
	ret


HDAE5000_SPrintf:	; 0x29ABD8 (237 bytes)
	; sprintf(buf, fmt, ...): stores buf in the output cursor at RAM
	; 0x239482, NUL-terminates it, and runs HDAE5000_DoPrintf(fmt, &ap,
	; HDAE5000_SPrintf_PutChar) with ap = the address of the first variadic
	; argument.  95 call sites in this ROM.
	; Contains 4 sub-routines: 2 setup variants, 1 callback, 1 int-to-string converter.
	; (sprintf, HDAE5000_VSPrintf, HDAE5000_SPrintf_PutChar, HDAE5000_IToA;
	;  the 237 bytes above are all four -- sprintf itself is 40.)
	;
	; --- Sub 1: Setup variant 1 (with extra stack param) ---
	; Stack: [+0x08] = buffer ptr, [+0x10] = params, [+0x14] = format data
	dec 4, xsp			; allocate 4 bytes
	ld xwa, (xsp + 8)		; XWA = buffer ptr
	ld (0x239482:24), xwa; [0x239482] = buffer ptr
	ld (xwa), 0x00		; null-terminate buffer
	lda xwa, (xsp + 0x10)		; XWA = &param area
	ld (xsp), xwa			; save to local
	pushw 0x0029			; push callback addr high word
	pushw 0xAC21			; push callback addr low (→ 0x0029AC21)
	lda xwa, (xsp + 4)		; XWA = &ap (the local saved above): va_list *
	push xwa			; push &ap (the callback long just pushed is arg 3)
	ld xwa, (xsp + 0x14)		; XWA = format data
	push xwa			; push
	call HDAE5000_DoPrintf			; call 0x299AE7 (formatted-output engine)
	lda xsp, (xsp + 0x10)		; cleanup 16 bytes
	ret
	;
	; --- Sub 2: Setup variant 2 (simpler) ---
	; vsprintf(buf, fmt, ap): as HDAE5000_SPrintf, but passes the address of
	; its own ap argument as the va_list *.  No caller in this ROM (searched:
	; symbolic call/calr/jp to this label, which did not exist before, and
	; the literal 0x29AC00 in every hdae5000 source).
HDAE5000_VSPrintf:
	ld xwa, (xsp + 4)		; XWA = buffer ptr
	ld (0x239482:24), xwa; [0x239482] = buffer ptr
	ld (xwa), 0x00		; null-terminate buffer
	pushw 0x0029			; push callback addr high word
	pushw 0xAC21			; push callback addr low
	lda xwa, (xsp + 0x10)		; XWA = &ap argument: va_list *
	push xwa			; push &ap (the callback long just pushed is arg 3)
	ld xwa, (xsp + 0x10)		; XWA = format data
	push xwa			; push
	call HDAE5000_DoPrintf			; call 0x299AE7
	lda xsp, (xsp + 0x0C)		; cleanup 12 bytes
	ret
	;
	; --- Sub 3: Byte-write callback (called by HDAE5000_DoPrintf) ---
	; Appends one byte to buffer at [0x239482], advances pointer, null-terminates.
HDAE5000_SPrintf_PutChar:				; 0x29AC21
	ld xbc, (0x239482:24); XBC = [0x239482] (current buffer ptr)
	ld xwa, 1:i3			; XWA = 1
	add (0x239482:24), xwa                ; [0x239482]++ (advance ptr)
	ld wa, (xsp + 4)		; WA = character to write
	ld (xbc), a			; store character at buffer
	ld xwa, (0x239482:24); XWA = new buffer ptr
	ld (xwa), 0x00		; null-terminate
	ret
	;
	; --- Sub 4: Integer to base-N string converter ---
	; itoa(int value, char *buf, int radix) on a 16-bit int: HDAE5000_IToA.
	; Stack: [+0x1A] = value, [+0x1C] = output ptr, [+0x20] = radix
	; Handles signed decimal (radix 10), validates radix 2-36.
	; Uses QBC (previous register bank) to hold the working value.
HDAE5000_IToA:
	lda xsp, (xsp - 18)		; allocate 18-byte frame
	push xiz			; save XIZ
	ld xhl, (xsp + 0x1C)		; XHL = output buffer ptr
	ld ix, 0:i3			; IX = 0 (sign = positive)
	ld bc, (xsp + 0x20)		; BC = radix
	cp bc, 2:i3			; radix < 2?
	jr lt, .Lppi_empty		; → invalid, output empty string
	cp bc, 0x0024			; radix > 36?
	jr le, .Lppi_convert		; → valid, start conversion
.Lppi_empty:
	ld (xhl), 0x00		; *output = '\0'
	jr t, .Lppi_done		; → exit
.Lppi_convert:
	ld wa, (xsp + 0x1A)		; WA = value to convert
	ld qbc, wa		; ld QBC, WA (save value in prev bank)
	lda xiz, (xsp + 4)		; XIZ = &local scratch buffer
	ld (xiz + 0x11), 0x00	; null-terminate scratch[17]
	lda xiy, (xiz + 0x10)		; XIY = scratch end pointer
	cp bc, 0x000A			; radix == 10? (decimal)
	jr nz, .Lppi_div_loop		; → unsigned for other radixes
	ld wa, qbc		; ld WA, QBC (reload value)
	cp wa, 0:i3			; value < 0? (signed check)
	jr ge, .Lppi_div_loop		; → non-negative
	ld ix, 1:i3			; IX = 1 (negative flag)
	ld wa, qbc		; ld WA, QBC (reload value)
	neg wa				; negate (make positive)
	ld qbc, wa		; ld QBC, WA (save positive value)
.Lppi_div_loop:
	ld de, bc			; DE = radix (divisor)
	ld wa, qbc		; ld WA, QBC (current value)
	extz xwa			; zero-extend WA to XWA
	div xwa, xde			; XWA = WA / DE (quot in WA, rem in high)
	ld wa, qwa		; ld WA, QWA (get remainder)
	add a, 0x30			; convert to ASCII '0'-'9'
	ld (xiy), a			; store digit
	cp (xiy), 0x39		; digit > '9'?
	jr le, .Lppi_digit_ok		; → it's 0-9
	addmi8 (xiy), 0x27		; adjust for 'a'-'z' (0x30+0x27=0x57→'W'+n)
.Lppi_digit_ok:
	ld wa, qbc		; ld WA, QBC (reload quotient)
	extz xwa			; zero-extend
	div xwa, xde			; divide again to get next quotient
	ld qbc, wa		; ld QBC, WA (save new quotient)
	cp qbc, 0		; cp QBC, 0 (quotient == 0?)
	jr z, .Lppi_digits_done		; → all digits extracted
	dec 1, xiy			; move digit pointer back
	jr t, .Lppi_div_loop		; → next digit
.Lppi_digits_done:
	cp ix, 0:i3			; negative flag set?
	jr z, .Lppi_copy_digits		; → no sign needed
	stib_dpd 0xF4, 0x2D		; ld (-XIY), '-' (pre-decrement, store minus sign)
.Lppi_copy_digits:
	lda xwa, (xiz + 0x12)		; XWA = &scratch[18] (past null-terminator)
	sub xwa, xiy			; XWA = string length (including null)
	pushw wa			; push length
	push xiy			; push source ptr
	push xhl			; push destination ptr
	call HDAE5000_MemCopy		; copy digit string to output
	lda xsp, (xsp + 0x0A)		; cleanup 10 bytes
.Lppi_done:
	pop xiz				; restore XIZ
	lda xsp, (xsp + 0x12)		; deallocate 18-byte frame
	ret

HDAE5000_LDiv:	; 0x29ACC5 (263 bytes)
	; ldiv(ldiv_t *result, long num, long den): result->quot = num / den
	; (HDAE5000_SDiv32), result->rem = num % den (HDAE5000_SMod32), built in a
	; local and copied out with 4 x LDIRW.  den == 0 skips both calls.
	; Three routines share these 263 bytes: this one (67 B), HDAE5000_LToA
	; and HDAE5000_ULToA.
	;
	; --- Sub 1: Cell copy buffer (0x29ACC5-0x29AD07, 67 bytes) ---
	; Calls divide/modulo utilities, copies 8 bytes via LDIRW.
	lda xsp, (xsp - 16)		; allocate 16-byte frame
	push xiz			; save XIZ
	ld xwa, (xsp + 0x20)		; XWA = param (format ptr?)
	or xwa, xwa			; zero check
	jr z, .Lccb_copy		; skip if null
	lda xwa, (xsp + 0x0C)		; XWA = &local[12]
	ld (xsp + 8), xwa		; save ptr A
	ld (xsp + 4), xwa		; save ptr B
	ld xiz, (xsp + 0x1C)		; XIZ = source data ptr
	ld xwa, xiz			; XWA = source ptr
	ld xbc, (xsp + 0x20)		; XBC = format param
	call HDAE5000_SDiv32			; call 0x29B8BB: XHL = num / den (signed)
	ld xwa, (xsp + 4)		; reload ptr B
	ld (xwa), xhl			; store result to local
	ld xwa, xiz			; XWA = source ptr
	ld xbc, (xsp + 0x20)		; XBC = format param
	call HDAE5000_SMod32			; call 0x29B8B7: XHL = num % den (signed)
	ld xwa, (xsp + 8)		; reload ptr A
	ld (xwa + 4), xhl		; store result to local+4
.Lccb_copy:
	ld xix, (xsp + 0x18)		; XIX = destination ptr
	lda xiy, (xsp + 0x0C)		; XIY = &local[12] (source)
	ld bc, 4:i3			; BC = 4 (copy 4 words = 8 bytes)
	ldirw				; block copy 16-bit × 4
	pop xiz				; restore XIZ
	lda xsp, (xsp + 0x10)		; deallocate 16-byte frame
	ret
	;
	; --- Sub 2: Signed number format handler (0x29AD08-0x29AD43, 60 bytes) ---
	; Prepends '-' for negative values when radix==10, then calls Sub 3.
	; ltoa(long value, char *buf, int radix); returns XHL = buf (the
	; negative path hands buf+1 to HDAE5000_ULToA and backs the result up).
HDAE5000_LToA:			; 0x29AD08
	ld xbc, (xsp + 8)		; XBC = output buffer ptr
	ld xde, (xsp + 4)		; XDE = value to convert
	ld wa, (xsp + 0x0C)		; WA = radix
	cp wa, 0x000A			; radix == 10? (decimal)
	jr nz, .Lccb_unsigned		; → unsigned conversion
	cp xde, 0x00000000		; value < 0? (signed check)
	jr ge, .Lccb_unsigned		; → non-negative
	; Negative decimal: prepend '-' and negate
	ld (xbc), 0x2D		; store '-' at buffer start
	pushw wa			; push radix
	lda xwa, (xbc + 1)		; XWA = buffer+1 (past '-')
	push xwa			; push output ptr
	cpl de				; complement DE (bitwise NOT)
	cpl qde		; cpl QDE (complement high word)
	inc 1, xde			; +1 → two's complement negate
	push xde			; push negated value
	call HDAE5000_ULToA		; call base-N converter
	lda xsp, (xsp + 0x0A)		; cleanup 10 bytes
	dec 1, xhl			; adjust string length for '-'
	ret
.Lccb_unsigned:
	pushw wa			; push radix
	push xbc			; push output ptr
	push xde			; push value
	call HDAE5000_ULToA		; call base-N converter
	lda xsp, (xsp + 0x0A)		; cleanup 10 bytes
	ret
	;
	; --- Sub 3: General base-N string converter (0x29AD44-0x29ADCB, 136 bytes) ---
	; Converts integer to string with radix 2-36.
	; Stack: [+0x36] = value, [+0x3A] = output ptr, [+0x3E] = radix
	; ultoa(unsigned long value, char *buf, int radix); returns XHL = buf.
	; Digits come from HDAE5000_UMod32 (remainder) and HDAE5000_UDivMod32
	; (quotient), i.e. the conversion is unsigned.
HDAE5000_ULToA:			; 0x29AD44
	lda xsp, (xsp - 46)		; allocate 46-byte frame
	push xiz			; save XIZ
	cpw (xsp + 0x3E), 0x0002	; radix < 2?
	jr lt, .Lccb_invalid		; → invalid
	cpw (xsp + 0x3E), 0x0024	; radix > 36?
	jr le, .Lccb_start		; → valid
.Lccb_invalid:
	ld xwa, (xsp + 0x3A)		; XWA = output buffer
	ld (xwa), 0x00		; output empty string
	jr t, .Lccb_conv_done		; → exit
.Lccb_start:
	lda xwa, (xsp + 0x10)		; XWA = &local scratch
	ld (xsp + 8), xwa		; save scratch base ptr
	ld (xwa + 0x20), 0x00	; null-terminate scratch[32]
	ld xwa, (xsp + 8)		; reload scratch ptr
	lda xwa, (xwa + 0x1F)		; XWA = &scratch[31] (digit fill ptr)
	ld (xsp + 4), xwa		; save digit ptr
	ld xiz, (xsp + 0x36)		; XIZ = value to convert
.Lccb_digit_loop:
	ld wa, (xsp + 0x3E)		; WA = radix
	exts xwa			; sign-extend radix to XWA
	ld (xsp + 0x0C), xwa		; save 32-bit radix
	ld xwa, xiz			; XWA = current value
	ld xbc, (xsp + 0x0C)		; XBC = radix
	call HDAE5000_UMod32	; XHL = remainder (value % radix)
	add l, 0x30			; convert remainder to ASCII '0'-'9'
	ld xwa, (xsp + 4)		; reload digit ptr
	ld (xwa), l			; store digit char
	cp (xwa), 0x39		; digit > '9'?
	jr le, .Lccb_digit_ok		; → it's 0-9
	addmi8 (xwa), 0x27		; adjust for 'a'-'f' (+0x27)
.Lccb_digit_ok:
	ld xwa, xiz			; XWA = current value
	ld xbc, (xsp + 0x0C)		; XBC = radix
	call HDAE5000_UDivMod32	; XHL = quotient
	ld xiz, xhl			; XIZ = new quotient
	or xiz, xiz			; quotient == 0?
	jr z, .Lccb_copy_result	; → all digits extracted
	ld xwa, 1:i3			; XWA = 1
	sub (xsp + 4), xwa		; digit ptr-- (move backward)
	jr t, .Lccb_digit_loop		; → next digit
.Lccb_copy_result:
	ld xwa, (xsp + 8)		; reload scratch base
	lda xwa, (xwa + 0x21)		; XWA = &scratch[33] (past null-terminator)
	sub xwa, (xsp + 4)		; XWA = string length
	push xwa			; push length
	ld xwa, (xsp + 8)		; reload digit ptr
	push xwa			; push source
	ld xwa, (xsp + 0x42)		; XWA = output buffer (deep stack offset)
	push xwa			; push destination
	call HDAE5000_MemCopy		; copy digits to output
	lda xsp, (xsp + 0x0C)		; cleanup 12 bytes
.Lccb_conv_done:
	ld xhl, (xsp + 0x3A)		; XHL = output buffer (return value)
	pop xiz				; restore XIZ
	lda xsp, (xsp + 0x2E)		; deallocate 46-byte frame
	ret

HDAE5000_MemCCpy:	; 0x29ADCC (64 bytes)
	; memccpy(dest, src, c, n): p = HDAE5000_MemChr(src, c, n); copies
	; (p ? p - src + 1 : n) bytes with HDAE5000_MemCopy.  NOTE the return
	; value is p itself -- the position of c in SRC, or 0 -- not the ISO
	; pointer into dest; HDAE5000_StrCpy only tests it against 0.
	; String copy with length limit
	; Stack: [+0x0C] dest, [+0x10] source, [+0x14] limit (IZ), [+0x14] flags
	; Uses String_Length to find end, then MemCopy to copy data
	; Returns: XHL = end pointer (or 0 if not found)
	dec 4, xsp			; allocate 4 bytes
	pushw iz
	ld iz, (xsp + 0x14)		; IZ = limit/count
	pushw iz			; arg: count
	pushm (xsp + 0x14)		; arg: search char/flags
	ld xwa, (xsp + 0x12)		; source pointer
	push xwa			; arg: string ptr
	call HDAE5000_MemChr
	inc 0, xsp			; clean up 8 bytes
	ld (xsp + 2), xhl		; save result
	ld xwa, (xsp + 2)		; reload result
	or xwa, xwa			; test if found
	jr nz, .Lscn_found
	pushw iz			; not found: use full limit
	jr t, .Lscn_copy
.Lscn_found:
	ld xwa, (xsp + 2)		; found position
	sub xwa, (xsp + 0x0E)		; subtract source base = length
	inc 1, xwa			; include found byte
	pushw wa			; push 16-bit length
.Lscn_copy:
	ld xwa, (xsp + 0x10)		; dest pointer
	push xwa
	ld xwa, (xsp + 0x10)		; source pointer
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0A)		; clean up 10 bytes
	ld xhl, (xsp + 2)		; return saved end pointer
	popw iz
	inc 4, xsp			; deallocate 4 bytes
	ret

HDAE5000_MemChr:	; 0x29AE0C (24 bytes)
	; memchr(s, c, n)
	; Find character in string using block search (cpir)
	; Stack: [+0x04] string ptr, [+0x08] search char (WA), [+0x0A] max count (BC)
	; Returns: XHL = pointer TO the found char (cpir leaves XHL one past it;
	;          the `dec 1, xhl` backs up), or 0 if not found
	ld xhl, 0:i3			; default: not found
	ld bc, (xsp + 0x0A)		; BC = max count
	cp bc, 0:i3
	ret z				; count=0: return 0
	ld xhl, (xsp + 4)		; XHL = string pointer
	ld wa, (xsp + 8)		; WA (low byte = search char)
	cpir83				; search for A in (XHL), decrement BC
	dec 1, xhl			; back up to found position
	ret z				; found: return pointer
	ld xhl, 0:i3			; not found: return 0
	ret

HDAE5000_MemCmp:	; 0x29AE24 (123 bytes)
	; memcmp(p1, p2, n).  (Was named File_Read: it reads no file.)
	; Memory comparison (memcmp-like): compares BC bytes at XIX vs XIY
	; Stack: [+0x04] ptr1, [+0x08] ptr2, [+0x0C] length
	; Returns: HL = 0 if equal, HL = signed byte difference if not
	; Optimized: aligns to 4-byte boundary, then compares 32-bit words
	ld bc, (xsp + 12)		; BC = length
	ld hl, 0:i3			; result = 0 (equal)
	cp bc, 0:i3			; length == 0?
	ret z				; return if zero length
	ld xix, (xsp + 4)		; XIX = ptr1
	ld xiy, (xsp + 8)		; XIY = ptr2
	cp xix, xiy			; same pointer?
	ret z				; return if same
	ld de, ix			; DE = low 16 bits of ptr1
	neg de				; negate
	and de, 0x0003			; DE = bytes to 4-byte alignment
	jr z, .Lfr_aligned		; skip if already aligned
.Lfr_byte_loop1:
	ldb_spi l, 0xF0			; L = *(XIX++)
	extz hl				; zero-extend L to HL
	ldb_spi a, 0xF4			; A = *(XIY++)
	extz wa				; zero-extend A to WA
	sub hl, wa			; compare
	ret nz				; return if different
	sub bc, 0x0001			; decrement length
	ret z				; return if done
	djnz16 de, .Lfr_byte_loop1	; loop for alignment bytes
.Lfr_aligned:
	ld de, bc			; save remaining length
	srl bc, 2			; BC = number of 32-bit words
	jr z, .Lfr_remainder		; skip if no full words
.Lfr_word_loop:
	ld_spil xhl, 0xF2		; XHL = *(XIX++) (32-bit)
	ld_spil xwa, 0xF6		; XWA = *(XIY++) (32-bit)
	cp xhl, xwa			; compare 32-bit words
	jr z, .Lfr_word_next		; skip if equal
	; Words differ — find which byte differs
	cp hl, wa			; compare low 16 bits
	jr nz, .Lfr_check_byte		; if low halves differ
	ld hl, qhl		; ld hl, qhl (high word from prev bank)
	ld wa, qwa		; ld wa, qwa (high word from prev bank)
.Lfr_check_byte:
	cp l, a				; compare low bytes
	jr nz, .Lfr_found_diff		; if different
	ld l, h				; move high byte to L
	ld a, w				; move high byte to A
.Lfr_found_diff:
	extz hl				; zero-extend L to HL
	extz wa				; zero-extend A to WA
	sub hl, wa			; HL = difference
	ret				; return
.Lfr_word_next:
	djnz16 bc, .Lfr_word_loop	; loop for remaining words
	ld hl, 0:i3			; clear result (equal so far)
.Lfr_remainder:
	and de, 0x0003			; DE = remaining bytes
	ret z				; return if none
.Lfr_byte_loop2:
	ldb_spi l, 0xF0			; L = *(XIX++)
	extz hl				; zero-extend L to HL
	ldb_spi a, 0xF4			; A = *(XIY++)
	extz wa				; zero-extend A to WA
	sub hl, wa			; compare
	ret nz				; return if different
	djnz16 de, .Lfr_byte_loop2	; loop for remaining
	ret				; return (HL = 0, equal)

; ----------------------------------------------------------------------------
; Memory Utility Routines (0x29AE9F - 0x29AF2C)
;
; Optimized memory manipulation functions used throughout HDAE5000 firmware.
; All routines take parameters on the stack (C calling convention).
; ----------------------------------------------------------------------------

HDAE5000_MemCopy:	; 29AE9Fh
	; Copy memory block using word operations where possible
	; Stack: [+0x04] = dest (XHL), [+0x08] = src (XIY), [+0x0C] = count (BC)
	; Uses LDIRW for word copies, handles odd byte at start/end
	ld bc, (xsp + 12)	; ld BC, (XSP+0x0C) - count
	ld xhl, (xsp + 4)	; ld XHL, (XSP+0x04) - dest
	cp bc, 0:i3
	ret z	; Return if count = 0
	ld xix, xhl	; XIX = dest
	ld xiy, (xsp + 8)	; ld XIY, (XSP+0x08) - src
	cp xix, xiy
	ret z	; Return if src = dest
	bit 0, ix	; bit 0, IX - check odd alignment
	jr z, HDAE5000_MemCopy__copy_words
	ldi85	; ldi - copy one byte
	ret nov	; ret PO - return if count exhausted
HDAE5000_MemCopy__copy_words:
	srl bc, 1	; srl 1, BC - divide count by 2
	jr z, HDAE5000_MemCopy__check_odd
	mriw2 0x95, 0x11	; ldirw - copy words
HDAE5000_MemCopy__check_odd:
	ret nc	; ret NC - return if no odd byte
	ldi85	; ldi - copy final odd byte
	ret

HDAE5000_MemFill:	; 29AEC7h
	; Fill memory with byte value, optimized for 32-bit writes
	; Stack: [+0x04] = dest (XHL), [+0x08] = value (WA), [+0x0A] = count (BC)
	; Aligns to 4-byte boundary, uses 32-bit writes for bulk fill
	ld bc, (xsp + 10)	; ld BC, (XSP+0x0A) - count
	ld xhl, (xsp + 4)	; ld XHL, (XSP+0x04) - dest
	cp bc, 0:i3
	ret z	; Return if count = 0
	ld xix, xhl	; XIX = dest
	ld wa, (xsp + 8)	; ld WA, (XSP+0x08) - fill value in A
	ld de, ix	; DE = low word of dest address
	neg de	; Negate for alignment calc
	and de, 0x3	; DE = bytes to align (0-3)
	jr z, HDAE5000_MemFill__aligned
HDAE5000_MemFill__align_loop:
	lda_dpi XBC, 0xF0	; ld (XIX+), A - store byte
	sub bc, 0x1	; sub BC, 1 - decrement count
	ret z	; Return if done
	djnz xde, HDAE5000_MemFill__align_loop	; djnz DE, .align_loop
HDAE5000_MemFill__aligned:
	ld de, bc	; Save count for remainder calc
	srl bc, 2	; srl 2, BC - divide by 4
	jr z, HDAE5000_MemFill__remainder
	ld w, a	; W = A (fill byte)
	ldw_erp WA, 0xE2	; ld QWA, WA - expand to 32-bit
HDAE5000_MemFill__fill_dwords:
	stl_dpi XWA, 0xF2	; ld (XIX+), XWA - store 4 bytes
	djnz xbc, HDAE5000_MemFill__fill_dwords	; djnz BC, .fill_dwords
HDAE5000_MemFill__remainder:
	and de, 0x3	; DE = remaining bytes (0-3)
	ret z	; Return if none
HDAE5000_MemFill__fill_bytes:
	lda_dpi XBC, 0xF0	; ld (XIX+), A
	djnz xde, HDAE5000_MemFill__fill_bytes	; djnz DE, .fill_bytes
	ret

HDAE5000_StrCat:	; 29AF0Bh
	; Copy null-terminated string including terminator
	; strcat(dest, src); returns XHL = dest.  (Was named StrCopy: the first
	; loop below walks to dest's terminator, so it appends, not copies.)
	; Stack: [+0x04] = dest (XDE), [+0x08] = src (XBC)
	; Finds end of dest string, then copies src to that position
	ld xde, (xsp + 4)	; ld XDE, (XSP+0x04) - dest
	ld xhl, xde	; Save original dest
	jr HDAE5000_StrCat__find_end
HDAE5000_StrCat__find_loop:
	inc 1, xde	; inc 1, XDE
HDAE5000_StrCat__find_end:
	cp (xde), 0x0	; cp (XDE), 0 - check for null
	jr nz, HDAE5000_StrCat__find_loop
	ld xbc, (xsp + 8)	; ld XBC, (XSP+0x08) - src
	jr HDAE5000_StrCat__copy_check
HDAE5000_StrCat__copy_loop:
	ldb_spi A, 0xE4	; ld A, (XBC+) - read src byte
	lda_dpi XBC, 0xE8	; ld (XDE+), A - write to dest
HDAE5000_StrCat__copy_check:
	cp (xbc), 0x0	; cp (XBC), 0 - check for null
	jr nz, HDAE5000_StrCat__copy_loop
	ld (xde), 0x0	; ld (XDE), 0 - write null terminator
	ret

; ----------------------------------------------------------------------------
; Remaining Code and Data (0x29AF2D - 0x2FA134)
; Contains additional utility routines, lookup tables, and data:
;   - String manipulation utilities (strlen, strncpy, etc.)
;   - Memory utilities (compare, search)
;   - Number formatting (itoa, hex conversion)
;   - 32-bit multiply routine (0x29B72D)
;   - UI configuration tables
;   - Graphics/image data
;
; Followed by 24,267 bytes of zero padding (0x2FA135 - 0x2FFFFF)
; ----------------------------------------------------------------------------

