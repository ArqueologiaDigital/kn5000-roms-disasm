HDAE5000_FdList_Scan:	; 0x282E8D (1126 bytes)
	; Scan the floppy: needs disk status 2 or 3 from the main CPU (workspace
	; 0x0E88 table +0x08; else HDAE5000_ShowErrorMessageTitle(2) and HL = 0xFFFF),
	; blanks the list (HDAE5000_FdList_Clear), shows the volume label, then
	; walks "*.*" with the find-first/next/close callbacks (+0x94/+0x98/+0x9C):
	; every name whose HDAE5000_FdName_SongNumber is n gets flag 0x22AB9C[n]
	; = 1 and its 6 characters at row n; flagged rows get a "*".  Caller:
	; HDDTitleSwCatch.  (Was "configure HD drive parameters ... formats
	; partition table".)
	lda xsp, (xsp-268)	; lda xsp, (xsp + 0xfef4) — alloc 268-byte frame
	push xiz					; 3e
	ldw	(xsp+4), 0x0000
	; Check disk status via 0x0e88 vtable
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_HamaFnTable)             ; e3 e1 88 0e 20
	ld xix, (xwa + HamaFn_GetMediaType)				; a8 08 24
	call (xix)					; b4 e8
	cp l, 3:i3					; cf db
	jr z, .Lsd_status_ok				; 66 05
	cp l, 2:i3					; cf da
	jrl nz, .Lsd_not_ready			; 7e 49 02
.Lsd_status_ok:
	; Register event 0xD2 via vtable 0x0124
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld xhl, (xwa + RootFn_ApPostEvent)             ; e3 e1 24 01 23 — (xwa+0x0124)
	ld xwa, HDAE5000_OBJ_CP_FD				; 40 d2 00 7f 00
	ld xbc, EVT_SHOW				; 41 01 00 c0 01
	ld xde, 0xffffffff				; 42 ff ff ff ff
	call (xhl)					; b3 e8
	calr HDAE5000_FdList_Clear			; 1e 5b fe
	; Get drive info via 0x0e88.0x0090 vtable
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_HamaFnTable)             ; e3 e1 88 0e 20
	ld_sril xhl, (xwa + HamaFn_GetVolumeLabel)             ; e3 e1 90 00 23
	call (xhl)					; b3 e8
	ld xiz, xhl					; eb 8e
	ld xwa, xiz					; ee 88
	or xwa, xwa					; e8 e0 — test if null
	jr z, .Lsd_skip_copy				; 66 18
	; Copy drive info to 0x22aa9c buffer
	ld xwa, xiz					; ee 88
	push xwa					; 38
	call HDAE5000_StrLen					; 1d 71 af 29
	pushw hl                                ; push hl (compact)
	ld xwa, xiz					; ee 88
	push xwa					; 38
	lda xwa, (0x22aa9c:24); f2 9c aa 22 30
	push xwa					; 38
	call HDAE5000_MemCopy					; 1d 9f ae 29
	lda xsp, (xsp + 0x0e)			; bf 0e 37
.Lsd_skip_copy:
	; Register event 0xDE via vtable, with 0x22aa9c as data
	lda xwa, (0x22aa9c:24); f2 9c aa 22 30
	ld xde, xwa					; e8 8a
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld xhl, (xwa + RootFn_ApPostEvent)             ; e3 e1 24 01 23
	ld xwa, HDAE5000_OBJ_CP_FD_VOLLABEL				; 40 de 00 7f 00
	ld xbc, EVT_HDAE_SET_STR_ADR				; 41 0a 00 ea 01
	call (xhl)					; b3 e8
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld xhl, (xwa + RootFn_ApPostEvent)             ; e3 e1 24 01 23
	ld xwa, HDAE5000_OBJ_CP_FD_VOLLABEL				; 40 de 00 7f 00
	ld xbc, EVT_PARA_DRAW				; 41 0f 00 c0 01
	ld xde, 0xffffffff				; 42 ff ff ff ff
	call (xhl)					; b3 e8
	; Identify drive: call via 0x0e88.0x0094
	lda xwa, (HDAE5000_Str_AllFilesPattern:24); f2 b4 22 2e 30
	ld xde, xwa					; e8 8a
	lda xwa, (xsp + 0x06)			; bf 06 30
	ld xbc, xwa					; e8 89
	ld xwa, xde					; ea 88
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 22
	ld xde, (xde + WS_HamaFnTable)             ; e3 e9 88 0e 22
	ld_sril xhl, (xde + HamaFn__findfirst)             ; e3 e9 94 00 23
	call (xhl)					; b3 e8
	ld xiz, xhl					; eb 8e
	; Check identify result
	ld xwa, xiz					; ee 88
	cp xwa, 0x00000000				; e8 cf 00 00 00 00
	jrl lt, .Lsd_post_loop			; 71 ab 00
	; First pass: process partitions
	lda xwa, (xsp + 0x0c)			; bf 0c 30
	calr HDAE5000_FdName_SongNumber		; 1e c4 fe
	ld wa, hl					; db 88
	cp wa, 0xffff					; d8 cf ff ff
	jr z, .Lsd_loop_done				; 66 6e
	ld wa, hl					; db 88
	add wa, 0x0100				; d8 c8 00 01
	lda xbc, (0x22aa9c:24); f2 9c aa 22 31
	stib_ind 0x07, 0xE4, 0xE0, 0x01	; ld (xbc+wa), 0x01
	pushw 0x0006					; 0b 06 00
	lda xwa, (xsp + 0x10)			; bf 10 30
	push xwa					; 38
	ld wa, hl					; db 88
	muls wa, 0x000c				; d8 09 0c 00
	lda xbc, (0x22aaad:24); f2 ad aa 22 31
	exts xwa					; e8 13
	add xwa, xbc					; e9 80
	push xwa					; 38
	call HDAE5000_MemCopy					; 1d 9f ae 29
	lda xsp, (xsp + 0x0a)			; bf 0a 37
	jr t, .Lsd_loop_done				; 68 3d
	; Second pass (loop target for retry)
.Lsd_retry:
	lda xwa, (xsp + 0x0c)			; bf 0c 30
	calr HDAE5000_FdName_SongNumber		; 1e 85 fe
	ld wa, hl					; db 88
	cp wa, 0xffff					; d8 cf ff ff
	jr z, .Lsd_loop_done				; 66 2f
	ld wa, hl					; db 88
	add wa, 0x0100				; d8 c8 00 01
	lda xbc, (0x22aa9c:24); f2 9c aa 22 31
	stib_ind 0x07, 0xE4, 0xE0, 0x01	; ld (xbc+wa), 0x01
	pushw 0x0006					; 0b 06 00
	lda xwa, (xsp + 0x10)			; bf 10 30
	push xwa					; 38
	ld wa, hl					; db 88
	muls wa, 0x000c				; d8 09 0c 00
	lda xbc, (0x22aaad:24); f2 ad aa 22 31
	exts xwa					; e8 13
	add xwa, xbc					; e9 80
	push xwa					; 38
	call HDAE5000_MemCopy					; 1d 9f ae 29
	lda xsp, (xsp + 0x0a)			; bf 0a 37
.Lsd_loop_done:
	; Get next partition via 0x0e88.0x0098
	lda xwa, (xsp + 0x06)			; bf 06 30
	ld xbc, xwa					; e8 89
	ld xwa, xiz					; ee 88
	ld xde, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 22
	ld xde, (xde + WS_HamaFnTable)             ; e3 e9 88 0e 22
	ld_sril xix, (xde + HamaFn__findnext)             ; e3 e9 98 00 24
	call (xix)					; b4 e8
	cp hl, 0:i3					; db d8
	jr z, .Lsd_retry				; 66 a7
	; Cleanup: call via 0x0e88.0x009c
	ld xwa, xiz					; ee 88
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 21
	ld xbc, (xbc + WS_HamaFnTable)             ; e3 e5 88 0e 21
	ld_sril xhl, (xbc + HamaFn__findclose)             ; e3 e5 9c 00 23
	call (xhl)					; b3 e8
.Lsd_post_loop:
	; Format partition display table: loop over 20 entries
	ld de, 0:i3					; da a8
	cp de, 0x0014					; da cf 14 00
	jr nc, .Lsd_display_done			; 6f 56
.Lsd_display_loop:
	ld wa, de					; da 88
	mul wa, 0x000c				; d8 08 0c 00
	add wa, 0x000a				; d8 c8 0a 00
	extz xwa					; e8 12
	add xwa, 0x0000000e				; e8 c8 0e 00 00 00
	ld xbc, 0x0022aa9c				; 41 9c aa 22 00
	add xbc, xwa					; e8 81
	ld	(xbc), 0x20
	; Check if partition marked active
	ld wa, de					; da 88
	extz xwa					; e8 12
	add xwa, 0x00000114				; e8 c8 14 01 00 00
	ld xbc, 0x0022aa9c				; 41 9c aa 22 00
	add xbc, xwa					; e8 81
	cp	(xbc), 0x01
	jr nz, .Lsd_display_next			; 6e 1c
	; Active partition: mark with asterisk
	ld wa, de					; da 88
	mul wa, 0x000c				; d8 08 0c 00
	add wa, 0x000a				; d8 c8 0a 00
	extz xwa					; e8 12
	add xwa, 0x0000000e				; e8 c8 0e 00 00 00
	ld xbc, 0x0022aa9c				; 41 9c aa 22 00
	add xbc, xwa					; e8 81
	ld	(xbc), 0x2a
.Lsd_display_next:
	inc 1, de					; da 61
	cp de, 0x0014					; da cf 14 00
	jr c, .Lsd_display_loop			; 67 aa
.Lsd_display_done:
	; Register display events via vtable 0x0124
	lda xwa, (0x22aaaa:24); f2 aa aa 22 30
	ld xde, xwa					; e8 8a
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld xhl, (xwa + RootFn_ApPostEvent)             ; e3 e1 24 01 23
	ld xwa, HDAE5000_OBJ_CP_FD_LIST				; 40 d7 00 7f 00
	ld xbc, EVT_HDAE_SET_STR_ADR				; 41 0a 00 ea 01
	call (xhl)					; b3 e8
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld xhl, (xwa + RootFn_ApPostEvent)             ; e3 e1 24 01 23
	ld xwa, HDAE5000_OBJ_CP_FD_LIST				; 40 d7 00 7f 00
	ld xbc, EVT_PARA_DRAW				; 41 0f 00 c0 01
	ld xde, 0xffffffff				; 42 ff ff ff ff
	call (xhl)					; b3 e8
	; Register event 0xD9 + 0xD8
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld xhl, (xwa + RootFn_ApPostEvent)             ; e3 e1 24 01 23
	ld xwa, HDAE5000_OBJ_CP_FD_LINE1				; 40 d9 00 7f 00
	ld xbc, EVT_DRAW				; 41 0d 00 c0 01
	ld xde, 0:i3					; ea a8
	call (xhl)					; b3 e8
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld xhl, (xwa + RootFn_ApPostEvent)             ; e3 e1 24 01 23
	ld xwa, HDAE5000_OBJ_CP_FD_LINE2				; 40 d8 00 7f 00
	ld xbc, EVT_DRAW				; 41 0d 00 c0 01
	ld xde, 0:i3					; ea a8
	call (xhl)					; b3 e8
	jr t, .Lsd_epilogue				; 68 0a
.Lsd_not_ready:
	; Disk not ready: call shutdown with error code 2
	ld wa, 2:i3					; d8 aa
	calr HDAE5000_ShowErrorMessageTitle			; 1e fc 7b
	ldw	(xsp+4), 0xffff
.Lsd_epilogue:
	ld hl, (xsp + 0x04)				; 9f 04 23
	pop xiz					; 5e
	lda xsp, (xsp+268)	; lda xsp, (xsp + 0x010c) — dealloc frame
	ret						; 0e
	; --- Sub-handler 1: event 0x01C00007 dispatch (0x28310D) ---
HDAE5000_HDDTitleSwCatch:
	; registered as "HDDTitleSwCatch" in HDAE5000_ScreenProc_Table
	cp xbc, EVT_SW_IN				; e9 cf 07 00 c0 01
	jr nz, .Lsd_sub1_done			; 6e 63
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld_sril xix, (xwa + RootFn_SendEvent)             ; e3 e1 00 01 24
	ld xwa, 0x02600024				; 40 24 00 60 02
	ld xbc, EVT_MAKE_EDIT_SW_ID				; 41 29 00 e0 01
	call (xix)					; b4 e8
	cp xhl, 0x0000000a				; eb cf 0a 00 00 00
	jr z, .Lsd_sub1_evt_0a			; 66 34
	cp xhl, 0x0000008a				; eb cf 8a 00 00 00
	jr nz, .Lsd_sub1_done			; 6e 38
	; Event 0x8A: check 0x229d99 config
	cp (HDAE5000_RAM_WriteProtect:24), 0x00; c2 99 9d 22 3f 00
	jr nz, .Lsd_sub1_configured			; 6e 05
	calr HDAE5000_FdList_Scan			; 1e 42 fd — recursive setup
	jr t, .Lsd_sub1_done				; 68 2b
.Lsd_sub1_configured:
	; Already configured: register event 0x024A
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld xhl, (xwa + RootFn_ApPostEvent)             ; e3 e1 24 01 23
	ld xwa, HDAE5000_OBJ_ATTEN_CPHD_WR				; 40 4a 02 7f 00
	ld xbc, EVT_SHOW				; 41 01 00 c0 01
	ld xde, 0:i3					; ea a8
	call (xhl)					; b3 e8
	jr t, .Lsd_sub1_done				; 68 0c
.Lsd_sub1_evt_0a:
	; Event 0x0A: init filesystem
	pushw 0x0000					; 0b 00 00
	ld wa, 0:i3					; d8 a8
	ld bc, 0:i3					; d9 a8
	ld de, 6:i3					; da ae
	calr HDAE5000_Lbn_ShowEntry				; 1e 5e 3f
.Lsd_sub1_done:
	ld xhl, 0:i3					; eb a8
	ret						; 0e
	; --- Sub-handler 2: event handler for 0xD9 (0x28317B) ---
HDAE5000_AttenCpToHDSwCatch:
	; registered as "AttenCpToHDSwCatch" in HDAE5000_ObjHandler_Table
	push xiz					; 3e
	ld xiz, xwa					; e8 8e
	ld xwa, xbc					; e9 88
	cp xwa, EVT_SW_IN				; e8 cf 07 00 c0 01
	jr z, .Lsd_sub2_c00007			; 66 63
	cp xwa, EVT_DRAW				; e8 cf 0d 00 c0 01
	jr z, .Lsd_sub2_c0000d			; 66 23
	cp xwa, EVT_ARE_YOU_CLASS_PROC				; e8 cf 85 00 e0 01
	jr z, .Lsd_sub2_e00085			; 66 16
	; Default: call cleanup callback
	ld xwa, xiz					; ee 88
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 23
	ld xhl, (xhl + WS_RootFnTable)             ; e3 ed 0a 0e 23
	ld_sril xix, (xhl + RootFn_InheritedProc)             ; e3 ed dc 00 24
	call (xix)					; b4 e8
	jrl t, .Lsd_sub2_done				; 78 87 00
.Lsd_sub2_e00085:
	ld xhl, 1:i3					; eb a9
	jrl t, .Lsd_sub2_done				; 78 82 00
.Lsd_sub2_c0000d:
	; Forward event via vtable
	ld xwa, xiz					; ee 88
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 23
	ld xhl, (xhl + WS_RootFnTable)             ; e3 ed 0a 0e 23
	ld_sril xhl, (xhl + RootFn_InheritedProc)             ; e3 ed dc 00 23
	call (xhl)					; b3 e8
	lda xwa, (HDAE5000_Str_Cphd:24); f2 b8 22 2e 30
	ld xbc, xwa					; e8 89
	ld xwa, xiz					; ee 88
	ld xde, xbc					; e9 8a
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 21
	ld xbc, (xbc + WS_RootFnTable)             ; e3 e5 0a 0e 21
	ld_sril xhl, (xbc + RootFn_SendEvent)             ; e3 e5 00 01 23
	ld xbc, EVT_PARA_DRAW				; 41 0f 00 c0 01
	call (xhl)					; b3 e8
	ld xhl, 0:i3					; eb a8
	jr t, .Lsd_sub2_done				; 68 4a
.Lsd_sub2_c00007:
	; Check for events 0x07 or 0x06
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld_sril xix, (xwa + RootFn_SendEvent)             ; e3 e1 00 01 24
	ld xwa, 0x02600024				; 40 24 00 60 02
	ld xbc, EVT_MAKE_EDIT_SW_ID				; 41 29 00 e0 01
	call (xix)					; b4 e8
	cp xhl, 0x00000007				; eb cf 07 00 00 00
	jr z, .Lsd_sub2_deregister			; 66 08
	cp xhl, 0x00000006				; eb cf 06 00 00 00
	jr nz, .Lsd_sub2_skip_dereg			; 6e 1d
.Lsd_sub2_deregister:
	; Deregister event via vtable 0x0104
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld xhl, (xwa + RootFn_PostEvent)             ; e3 e1 04 01 23
	ld xwa, HDAE5000_OBJ_HDDMENU				; 40 00 00 7f 00
	ld xbc, EVT_SHOW				; 41 01 00 c0 01
	ld xde, 0:i3					; ea a8
	call (xhl)					; b3 e8
.Lsd_sub2_skip_dereg:
	ld xhl, 0:i3					; eb a8
.Lsd_sub2_done:
	pop xiz					; 5e
	ret						; 0e
	; --- Sub-handler 3: event handler for 0xD8 (0x283237) ---
HDAE5000_AttenCpToMarkSwCatch:
	; registered as "AttenCpToMarkSwCatch" in HDAE5000_ObjHandler_Table
	push xiz					; 3e
	ld xiz, xwa					; e8 8e
	ld xwa, xbc					; e9 88
	cp xwa, EVT_SW_IN				; e8 cf 07 00 c0 01
	jr z, .Lsd_sub3_c00007			; 66 63
	cp xwa, EVT_DRAW				; e8 cf 0d 00 c0 01
	jr z, .Lsd_sub3_c0000d			; 66 23
	cp xwa, EVT_ARE_YOU_CLASS_PROC				; e8 cf 85 00 e0 01
	jr z, .Lsd_sub3_e00085			; 66 16
	; Default: call cleanup callback
	ld xwa, xiz					; ee 88
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 23
	ld xhl, (xhl + WS_RootFnTable)             ; e3 ed 0a 0e 23
	ld_sril xix, (xhl + RootFn_InheritedProc)             ; e3 ed dc 00 24
	call (xix)					; b4 e8
	jrl t, .Lsd_sub3_done				; 78 87 00
.Lsd_sub3_e00085:
	ld xhl, 1:i3					; eb a9
	jrl t, .Lsd_sub3_done				; 78 82 00
.Lsd_sub3_c0000d:
	; Forward event via vtable
	ld xwa, xiz					; ee 88
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 23
	ld xhl, (xhl + WS_RootFnTable)             ; e3 ed 0a 0e 23
	ld_sril xhl, (xhl + RootFn_InheritedProc)             ; e3 ed dc 00 23
	call (xhl)					; b3 e8
	lda xwa, (HDAE5000_Str_Cphd_AttenCpToMarkSwCatch:24); f2 be 22 2e 30
	ld xbc, xwa					; e8 89
	ld xwa, xiz					; ee 88
	ld xde, xbc					; e9 8a
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 21
	ld xbc, (xbc + WS_RootFnTable)             ; e3 e5 0a 0e 21
	ld_sril xhl, (xbc + RootFn_SendEvent)             ; e3 e5 00 01 23
	ld xbc, EVT_PARA_DRAW				; 41 0f 00 c0 01
	call (xhl)					; b3 e8
	ld xhl, 0:i3					; eb a8
	jr t, .Lsd_sub3_done				; 68 4a
.Lsd_sub3_c00007:
	; Check for events 0x07 or 0x06
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld_sril xix, (xwa + RootFn_SendEvent)             ; e3 e1 00 01 24
	ld xwa, 0x02600024				; 40 24 00 60 02
	ld xbc, EVT_MAKE_EDIT_SW_ID				; 41 29 00 e0 01
	call (xix)					; b4 e8
	cp xhl, 0x00000007				; eb cf 07 00 00 00
	jr z, .Lsd_sub3_deregister			; 66 08
	cp xhl, 0x00000006				; eb cf 06 00 00 00
	jr nz, .Lsd_sub3_skip_dereg			; 6e 1d
.Lsd_sub3_deregister:
	; Deregister event 0xD2 via vtable 0x0104
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld xhl, (xwa + RootFn_PostEvent)             ; e3 e1 04 01 23
	ld xwa, HDAE5000_OBJ_CP_FD				; 40 d2 00 7f 00
	ld xbc, EVT_SHOW				; 41 01 00 c0 01
	ld xde, 0:i3					; ea a8
	call (xhl)					; b3 e8
.Lsd_sub3_skip_dereg:
	ld xhl, 0:i3					; eb a8
.Lsd_sub3_done:
	pop xiz					; 5e
	ret						; 0e

HDAE5000_TitleInfo_Build:	; 0x2832F3 (1051 bytes)
	; Build the settings/status text of the HD title screen from the
	; template at 0x2E22C4 into 0x22ADA6 and show it in object 0x7F000A:
	; "WRITE PROTECTION :" <- 0x229D99 (ON/OFF via the pointer pair at
	; 0x2E1E3C), "WRITE CONFIRM :" <- 0x229D9A, "QUICK LOAD MODE:" <- 0x229DA9,
	; "JUMP AFTER LOAD:" <- 0x229DAB, "LOAD BY NUMBER MODE:" <- 0x229DAA,
	; "FREE HDD SPACE :" <- HDAE5000_HD_GetDiskUsage free / 100 in MB.  Caller:
	; HdTitleEventCatch.  (Was "read HD IDENTIFY data; extracts CHS params
	; from 0x229D99-0x229DAB": those bytes are these settings.)
	; --- Prologue: allocate 32-byte stack frame ---
	lda	xsp, (xsp-32)

	; --- Format CHS display strings ---
	; Block 1: cylinder type (0x229d99) → display buffer 0x22ada6
	pushw 0x0097
	lda xwa, (HDAE5000_TitleInfo_Template:24); f2 c4 22 2e 30
	push xwa				; 38
	lda xwa, (0x22ada6:24); f2 a6 ad 22 30
	push xwa				; 38
	call HDAE5000_MemCopy				; 1d 9f ae 29 — MemCopy
	ld a, (HDAE5000_RAM_WriteProtect:24); c2 99 9d 22 21 — ld a, (0x229d99)
	extz wa					; d8 12
	sla wa, 2				; d8 ec 02
	lda xbc, (HDAE5000_TextPtrs_OFF_ON:24); f2 3c 1e 2e 31
	ld_sril3 xwa, 0x07, 0xe4, 0xe0		; e3 07 e4 e0 20 — ld xwa, (xbc+wa)
	push xwa				; 38
	pushw 0x002e
	pushw 0x235c		; low half of HDAE5000_Fmt_s
	lda xwa, (xsp + 0x12)			; bf 12 30
	push xwa				; 38
	call HDAE5000_SPrintf		; 1d d8 ab 29
	lda xwa, (xsp + 0x16)			; bf 16 30
	push xwa				; 38
	call HDAE5000_StrLen				; 1d 71 af 29 — Display_Buffer_Validate
	lda xsp, (xsp + 0x1a)			; bf 1a 37

	; Block 2: heads (0x229d9a) → display buffer 0x22adba
	pushw hl                                ; push hl (compact 16-bit)
	lda xwa, (xsp + 0x02)			; bf 02 30
	push xwa				; 38
	lda xwa, (0x22adba:24); f2 ba ad 22 30
	push xwa				; 38
	call HDAE5000_MemCopy				; 1d 9f ae 29 — MemCopy
	ld a, (HDAE5000_RAM_WriteConfirm:24); c2 9a 9d 22 21 — ld a, (0x229d9a)
	extz wa					; d8 12
	sla wa, 2				; d8 ec 02
	lda xbc, (HDAE5000_TextPtrs_OFF_ON:24); f2 3c 1e 2e 31
	ld_sril3 xwa, 0x07, 0xe4, 0xe0		; e3 07 e4 e0 20 — ld xwa, (xbc+wa)
	push xwa				; 38
	pushw 0x002e
	pushw 0x2360		; low half of HDAE5000_Fmt_s_TitleInfo_Build
	lda xwa, (xsp + 0x12)			; bf 12 30
	push xwa				; 38
	call HDAE5000_SPrintf		; 1d d8 ab 29
	lda xwa, (xsp + 0x16)			; bf 16 30
	push xwa				; 38
	call HDAE5000_StrLen				; 1d 71 af 29 — Display_Buffer_Validate
	lda xsp, (xsp + 0x1a)			; bf 1a 37

	; Block 3: sectors (0x229daa) → display buffer 0x22adec
	pushw hl                                ; push hl (compact 16-bit)
	lda xwa, (xsp + 0x02)			; bf 02 30
	push xwa				; 38
	lda xwa, (0x22adec:24); f2 ec ad 22 30
	push xwa				; 38
	call HDAE5000_MemCopy				; 1d 9f ae 29 — MemCopy
	ld a, (HDAE5000_RAM_LoadByNumberMode:24); c2 aa 9d 22 21 — ld a, (0x229daa)
	extz wa					; d8 12
	pushw wa                                ; push wa (compact 16-bit)
	pushw 0x002e
	pushw 0x2364		; low half of HDAE5000_Fmt_d
	lda xwa, (xsp + 0x10)			; bf 10 30
	push xwa				; 38
	call HDAE5000_SPrintf		; 1d d8 ab 29
	lda xwa, (xsp + 0x14)			; bf 14 30
	push xwa				; 38
	call HDAE5000_StrLen				; 1d 71 af 29 — Display_Buffer_Validate
	lda xsp, (xsp + 0x18)			; bf 18 37

	; Block 4: cylinder count high (0x229da9) → display buffer 0x22ae1e
	pushw hl                                ; push hl (compact 16-bit)
	lda xwa, (xsp + 0x02)			; bf 02 30
	push xwa				; 38
	lda xwa, (0x22ae1e:24); f2 1e ae 22 30
	push xwa				; 38
	call HDAE5000_MemCopy				; 1d 9f ae 29 — MemCopy
	ld a, (HDAE5000_RAM_QuickLoadMode:24); c2 a9 9d 22 21 — ld a, (0x229da9)
	extz wa					; d8 12
	pushw wa                                ; push wa (compact 16-bit)
	pushw 0x002e
	pushw 0x236a		; low half of HDAE5000_Fmt_d_TitleInfo_Build
	lda xwa, (xsp + 0x10)			; bf 10 30
	push xwa				; 38
	call HDAE5000_SPrintf		; 1d d8 ab 29
	lda xwa, (xsp + 0x14)			; bf 14 30
	push xwa				; 38
	call HDAE5000_StrLen				; 1d 71 af 29 — Display_Buffer_Validate
	lda xsp, (xsp + 0x18)			; bf 18 37

	; Block 5: cylinder count (0x229dab) → display buffer 0x22add1
	pushw hl                                ; push hl (compact 16-bit)
	lda xwa, (xsp + 0x02)			; bf 02 30
	push xwa				; 38
	lda xwa, (0x22add1:24); f2 d1 ad 22 30
	push xwa				; 38
	call HDAE5000_MemCopy				; 1d 9f ae 29 — MemCopy
	ld a, (HDAE5000_RAM_JumpAfterLoad:24); c2 ab 9d 22 21 — ld a, (0x229dab)
	extz wa					; d8 12
	pushw wa                                ; push wa (compact 16-bit)
	pushw 0x002e
	pushw 0x2372		; low half of HDAE5000_Fmt_d_TitleInfo_Build_2
	lda xwa, (xsp + 0x10)			; bf 10 30
	push xwa				; 38
	call HDAE5000_SPrintf		; 1d d8 ab 29
	lda xwa, (xsp + 0x14)			; bf 14 30
	push xwa				; 38
	call HDAE5000_StrLen				; 1d 71 af 29 — Display_Buffer_Validate
	lda xsp, (xsp + 0x18)			; bf 18 37

	; Block 6: total size string → display buffer 0x22ae03
	pushw hl                                ; push hl (compact 16-bit)
	lda xwa, (xsp + 0x02)			; bf 02 30
	push xwa				; 38
	lda xwa, (0x22ae03:24); f2 03 ae 22 30
	push xwa				; 38
	call HDAE5000_MemCopy				; 1d 9f ae 29 — MemCopy
	lda xsp, (xsp + 0x0a)			; bf 0a 37

	; Compute capacity: divide total sectors by 100
	lda xwa, (xsp + 0x10)			; bf 10 30
	call HDAE5000_HD_GetDiskUsage				; 1d 6c 8b 29
	ld xwa, (xsp + 0x1c)			; af 1c 20 — load dividend
	ld xbc, 0x00000064			; 41 64 00 00 00 — divisor = 100
	call HDAE5000_UDivMod32		; 1d c5 b8 29
	push xhl				; 3b — push remainder
	pushw 0x002e
	pushw 0x237a		; low half of HDAE5000_Fmt_4ldMB
	lda xwa, (xsp + 0x08)			; bf 08 30
	push xwa				; 38
	call HDAE5000_SPrintf		; 1d d8 ab 29
	lda xwa, (xsp + 0x0c)			; bf 0c 30
	push xwa				; 38
	call HDAE5000_StrLen				; 1d 71 af 29 — Display_Buffer_Validate

	; Block 7: capacity text → display buffer 0x22ae35
	pushw hl                                ; push hl (compact 16-bit)
	lda xwa, (xsp + 0x12)			; bf 12 30
	push xwa				; 38
	lda xwa, (0x22ae35:24); f2 35 ae 22 30
	push xwa				; 38
	call HDAE5000_MemCopy				; 1d 9f ae 29 — MemCopy
	lda xsp, (xsp + 0x1a)			; bf 1a 37

	; --- Register event handlers ---
	; Register event 0x01EA000A with display buffer
	lda xwa, (0x22ada6:24); f2 a6 ad 22 30
	ld xde, xwa				; e8 8a
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld_sril xhl, (xwa + RootFn_SendEvent)             ; e3 e1 00 01 23 — ld xhl, (xwa+0x0100)
	ld xwa, HDAE5000_OBJ_HARD_DISK_OPT			; 40 0a 00 7f 00
	ld xbc, EVT_HDAE_SET_STR_ADR			; 41 0a 00 ea 01
	call (xhl)				; b3 e8

	; Register event 0x01C0000F with XDE=0xFFFFFFFF (deregister)
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld_sril xhl, (xwa + RootFn_SendEvent)             ; e3 e1 00 01 23 — ld xhl, (xwa+0x0100)
	ld xwa, HDAE5000_OBJ_HARD_DISK_OPT			; 40 0a 00 7f 00
	ld xbc, EVT_PARA_DRAW			; 41 0f 00 c0 01
	ld xde, 0xffffffff			; 42 ff ff ff ff
	call (xhl)				; b3 e8

	; --- Epilogue ---
	lda xsp, (xsp + 0x20)			; bf 20 37
	ret					; 0e

; --- Event handler sub-function ---
HDAE5000_HdTitleEventCatch:
	; registered as "HdTitleEventCatch" in HDAE5000_ObjHandler_Table
	dec 8, xsp				; ef 68 — allocate 4 bytes
	push xiz				; 3e
	ld (xsp + 0x04), xde			; bf 04 62
	ld xiz, xbc				; e9 8e
	ld (xsp + 0x08), xwa			; bf 08 60
	ld xwa, xiz				; ee 88
	cp xwa, EVT_DRAW			; e8 cf 0d 00 c0 01
	jr z, .Lri_evt_000d			; 66 xx
	cp xwa, EVT_ARE_YOU_CLASS_PROC			; e8 cf 85 00 e0 01
	jr z, .Lri_evt_0085			; 66 xx

	; Default: forward to vtable handler at +0x0EDC
	ld xwa, (xsp + 0x08)			; af 08 20
	ld xbc, xiz				; ee 89
	ld xde, (xsp + 0x04)			; af 04 22
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 23
	ld xhl, (xhl + WS_RootFnTable)             ; e3 ed 0a 0e 23 — ld xhl, (xhl+0x0e0a)
	ld_sril xix, (xhl + RootFn_InheritedProc)             ; e3 ed dc 00 24 — ld xix, (xhl+0x00dc)
	call (xix)				; b4 e8
	jr t, .Lri_evt_done			; 68 xx

.Lri_evt_0085:					; 0x2834D0
	ld xhl, 1:i3				; eb a9
	jr t, .Lri_evt_done			; 68 xx

.Lri_evt_000d:					; 0x2834D4
	calr HDAE5000_TitleInfo_Build		; 1e xx xx — recursive self-call
	ld xwa, (xsp + 0x08)			; af 08 20
	ld xbc, xiz				; ee 89
	ld xde, (xsp + 0x04)			; af 04 22
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 23
	ld xhl, (xhl + WS_RootFnTable)             ; e3 ed 0a 0e 23 — ld xhl, (xhl+0x0e0a)
	ld_sril xhl, (xhl + RootFn_InheritedProc)             ; e3 ed dc 00 23 — ld xhl, (xhl+0x00dc)
	call (xhl)				; b3 e8
	; Re-register event 0x01C0000F with new handler
	lda xwa, (HDAE5000_Str_HDAE:24); f2 82 23 2e 30
	ld xbc, xwa				; e8 89
	ld xwa, (xsp + 0x08)			; af 08 20
	ld xde, xbc				; e9 8a
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 21
	ld xbc, (xbc + WS_RootFnTable)             ; e3 e5 0a 0e 21 — ld xbc, (xbc+0x0e0a)
	ld_sril xhl, (xbc + RootFn_SendEvent)             ; e3 e5 00 01 23 — ld xhl, (xbc+0x0100)
	ld xbc, EVT_PARA_DRAW			; 41 0f 00 c0 01
	call (xhl)				; b3 e8
	ld xhl, 0:i3				; eb a8

.Lri_evt_done:					; 0x283514
	pop xiz					; 5e
	inc 8, xsp				; ef 60
	ret					; 0e

; --- Jump table dispatcher sub-function ---
HDAE5000_HDAETitleFunc:
	; registered as "HDAETitleFunc" in HDAE5000_ScreenProc_Table
	cp xbc, EVT_ACTIVATE_STATE			; e9 cf 13 00 c0 01
	jrl nz, .Lri_done			; 7e xx xx
	ld xwa, xde				; ea 88
	dec 2, xwa				; e8 6a — subtract 2 (cases start at 2)
	cp xwa, 0x00000000			; e8 cf 00 00 00 00
	jrl c, .Lri_done			; 77 xx xx — unsigned < 0
	cp xwa, 0x00000007			; e8 cf 07 00 00 00
	jrl ugt, .Lri_done			; 7b xx xx — > 7
	add xwa, xwa				; e8 80 — multiply by 2 (word offsets)
	add xwa, HDAE5000_HDAETitleFunc_CaseTable			; e8 c8 ac 23 2e 00 — add table base
	ld wa, (xwa)				; 90 20 — load 16-bit jump offset
	lda xix, (.Lri_jt_base:24); f2 4b 35 28 34 — jump base
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp t, (xix+wa) — F3 indexed jump

	; === Case 2: main setup — read/write, format, init filesystem ===
.Lri_jt_base:					; 0x28354B (jump table base)
	ld (0x22ae3c:24), 0x00; f2 3c ae 22 00 00
	lda xwa, (0x22ada6:24); f2 a6 ad 22 30
	ld xde, xwa				; e8 8a
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld xhl, (xwa + RootFn_ApPostEvent)             ; e3 e1 24 01 23 — ld xhl, (xwa+0x0124)
	ld xwa, HDAE5000_OBJ_HARD_DISK_OPT			; 40 0a 00 7f 00
	ld xbc, EVT_HDAE_SET_STR_ADR			; 41 0a 00 ea 01
	call (xhl)				; b3 e8
	ld wa, 0:i3				; d8 a8
	ld bc, 0:i3				; d9 a8
	calr HDAE5000_SongScreen_Refresh		; 1e xx xx

	ld (0x22aa4a:24), 0x00; f2 4a aa 22 00 00
	lda xwa, (0x22a2ca:24); f2 ca a2 22 30
	ld xde, xwa				; e8 8a
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld xhl, (xwa + RootFn_ApPostEvent)             ; e3 e1 24 01 23 — ld xhl, (xwa+0x0124)
	ld xwa, HDAE5000_OBJ_SEL_FLS			; 40 fb 00 7f 00
	ld xbc, EVT_HDAE_SET_STR_ADR			; 41 0a 00 ea 01
	call (xhl)				; b3 e8
	ld wa, 0:i3				; d8 a8
	ld bc, 2:i3				; d9 aa
	calr HDAE5000_FlsScreen_Refresh		; 1e xx xx

	ld (0x22a2c8:24), 0x00; f2 c8 a2 22 00 00
	lda xwa, (0x22a0d0:24); f2 d0 a0 22 30
	ld xde, xwa				; e8 8a
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld xhl, (xwa + RootFn_ApPostEvent)             ; e3 e1 24 01 23 — ld xhl, (xwa+0x0124)
	ld xwa, HDAE5000_OBJ_SEL_DIR			; 40 25 00 7f 00
	ld xbc, EVT_HDAE_SET_STR_ADR			; 41 0a 00 ea 01
	call (xhl)				; b3 e8
	ld xwa, HDAE5000_OBJ_SEL_DIR			; 40 25 00 7f 00
	calr HDAE5000_DirList_BuildPage		; 1e xx xx
	calr HDAE5000_FlsList_BuildPage		; 1e xx xx
	pushw 0x0000
	ld wa, 0:i3				; d8 a8
	ld bc, 0:i3				; d9 a8
	ld de, 6:i3				; da ae
	calr HDAE5000_Lbn_ShowEntry			; 1e xx xx

	; Copy volume label string
	pushw 0x0021
	lda xwa, (HDAE5000_Str_STATUS:24); f2 e6 1d 2e 30
	push xwa				; 38
	lda xwa, (0x22abc4:24); f2 c4 ab 22 30
	push xwa				; 38
	call HDAE5000_MemCopy				; 1d 9f ae 29 — MemCopy
	lda xsp, (xsp + 0x0a)			; bf 0a 37

	; Register event for volume label display
	lda xwa, (0x22abc4:24); f2 c4 ab 22 30
	ld xde, xwa				; e8 8a
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld xhl, (xwa + RootFn_ApPostEvent)             ; e3 e1 24 01 23 — ld xhl, (xwa+0x0124)
	ld xwa, HDAE5000_OBJ_PP_STATUS			; 40 68 00 7f 00
	ld xbc, EVT_HDAE_SET_STR_ADR			; 41 0a 00 ea 01
	call (xhl)				; b3 e8

	; Set initial disk status
	ld xwa, HDAE5000_OBJ_HDDMENU			; 40 00 00 7f 00
	ld (0x23a09a:24), xwa; f2 9a a0 23 60
	cp (0x22ad9a:24), 0x01; c2 9a ad 22 3f 01
	jrl nz, .Lri_done			; 7e xx xx
	cp (0x22ad9b:24), 0x01; c2 9b ad 22 3f 01
	jrl nz, .Lri_done			; 7e xx xx
	ld xwa, HDAE5000_OBJ_FLS_FILE_LOAD			; 40 3a 01 7f 00
	ld (0x23a09a:24), xwa; f2 9a a0 23 60
	jrl t, .Lri_done			; 78 xx xx

	; === Case 9: check cylinder count, set disk capacity ===
.Lri_case9:					; 0x283649
	ld a, (HDAE5000_RAM_QuickLoadMode:24); c2 a9 9d 22 21 — ld a, (0x229da9)
	cp a, 3:i3				; c9 db
	jr z, .Lri_case9_cyl3			; 66 xx
	cp a, 2:i3				; c9 da
	jr z, .Lri_case9_cyl2			; 66 xx
	cp a, 1:i3				; c9 d9
	jrl nz, .Lri_done			; 7e xx xx
	ld xwa, HDAE5000_OBJ_SELECT_FILE			; 40 18 00 7f 00
	ld (0x23a09a:24), xwa; f2 9a a0 23 60
	jrl t, .Lri_done			; 78 xx xx

.Lri_case9_cyl2:				; 0x283668
	ld xwa, HDAE5000_OBJ_LOAD_BY_NUM			; 40 8f 00 7f 00
	ld (0x23a09a:24), xwa; f2 9a a0 23 60
	jrl t, .Lri_done			; 78 xx xx

.Lri_case9_cyl3:				; 0x283675
	ld xwa, HDAE5000_OBJ_FLS_FILE_LOAD			; 40 3a 01 7f 00
	ld (0x23a09a:24), xwa; f2 9a a0 23 60
	jrl t, .Lri_done			; 78 xx xx

	; === Case 8: dispatch event to sub-device ===
.Lri_case8:					; 0x283682
	ld xwa, (0x23a09a:24); e2 9a a0 23 20
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 21
	ld xbc, (xbc + WS_RootFnTable)             ; e3 e5 0a 0e 21 — ld xbc, (xbc+0x0e0a)
	ld xhl, (xbc + RootFn_ApPostEvent)             ; e3 e5 24 01 23 — ld xhl, (xbc+0x0124)
	ld xbc, EVT_SHOW			; 41 01 00 c0 01
	ld xde, 0:i3				; ea a8
	call (xhl)				; b3 e8

	; Deregister event 0x01C00018
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld xhl, (xwa + RootFn_ApPostEvent)             ; e3 e1 24 01 23 — ld xhl, (xwa+0x0124)
	ld xwa, 0xffffffff			; 40 ff ff ff ff
	ld xbc, EVT_INDEXSW_DOWN			; 41 18 00 c0 01
	ld xde, 0:i3				; ea a8
	call (xhl)				; b3 e8

	; Check disk presence flags
	cp (0x22ad9a:24), 0x01; c2 9a ad 22 3f 01
	jr nz, .Lri_done			; 6e xx
	cp (0x22ad9b:24), 0x01; c2 9b ad 22 3f 01
	jr nz, .Lri_done			; 6e xx

	; Clear flag and register event 0x01CA0000
	ld (0x22ad9b:24), 0x00; f2 9b ad 22 00 00
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld xhl, (xwa + RootFn_ApPostEvent)             ; e3 e1 24 01 23 — ld xhl, (xwa+0x0124)
	ld xwa, HDAE5000_OBJ_FLS_FILE_LOAD			; 40 3a 01 7f 00
	ld xbc, EVT_HDAE_SEQ_STOP			; 41 00 00 ca 01
	ld xde, 0:i3				; ea a8
	call (xhl)				; b3 e8
	jr t, .Lri_done				; 68 xx

	; === Case 6: init flag check, set disk size from table ===
.Lri_case6:					; 0x2836F1
	call HDAE5000_Get_Init_Flag		; 1d 70 f5 28
	ld a, l					; cf 89
	extz wa					; d8 12
	sla wa, 2				; d8 ec 02
	lda xbc, (HDAE5000_HDAETitleFunc_ObjIds:24); f2 88 23 2e 31
	ld_sril3 xwa, 0x07, 0xe4, 0xe0		; e3 07 e4 e0 20 — ld xwa, (xbc+wa)
	ld (0x23a09a:24), xwa; f2 9a a0 23 60

	; === Common exit ===
.Lri_done:					; 0x28370B
	ld xhl, 0:i3				; eb a8
	ret					; 0e

HDAE5000_DirList_BuildPage:	; 0x28370E (702 bytes)
	; Build one page of the directory list: 24 rows of 21 bytes at 0x22A0D0
	; from the row template 0x2E23BC, each "NNN:" (0x23A08E page base + row +
	; 1) and the 16-byte directory name (HDAE5000_DirName_Address); then event
	; 0x01EA000A (buffer) and 0x01C0000F to list object XWA.  (Was "format 24
	; cylinder/head entries".)

	; --- Prologue ---
	lda	xsp, (xsp-26)
	pushw iz                                ; push iz (compact 1-byte)
	ld (xsp + 0x18), xwa		; save context ptr

	; --- Format 0x01F9 entries into buffer ---
	pushw 0x01f9
	pushw 0x0000
	lda xwa, (0x22a0d0:24)
	push xwa
	call HDAE5000_MemFill
	inc 8, xsp			; (NOP — callee cleaned stack)

	; --- Loop: format 24 (0x18) entries ---
	ld iz, 0:i3			; IZ = loop counter
	cp iz, 0x0018
	jr ge, .Lfp_loop_done

.Lfp_format_entry:
	; Format field name
	pushw 0x0015
	lda xwa, (HDAE5000_Str_Chr2020203A2020:24)
	push xwa
	ldw wa, 0x0015
	muls xwa, iz			; XWA = IZ * 21
	lda xbc, (0x22a0d0:24)
	exts xwa
	add xwa, xbc			; XWA = buffer + IZ*21
	push xwa
	call HDAE5000_MemCopy
	; Format entry number
	ld wa, iz
	add wa, (HDAE5000_RAM_DirPageBase:24); WA += base offset
	inc 1, wa
	pushw wa                                ; push wa (compact 1-byte)
	pushw 0x002e
	pushw 0x23d2		; low half of HDAE5000_Fmt_3_3d
	lda xwa, (xsp + 0x12)
	push xwa
	call HDAE5000_SPrintf
	; Format second field
	pushw 0x0003
	lda xwa, (xsp + 0x18)
	push xwa
	ldw wa, 0x0015
	muls xwa, iz
	lda xbc, (0x22a0d0:24)
	exts xwa
	add xwa, xbc
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x1e)		; clean stack (30 bytes)

	; Load sector address for this entry
	ld wa, (HDAE5000_RAM_DirPageBase:24); WA = base offset
	add wa, iz			; WA = base + IZ
	call HDAE5000_DirName_Address			; XHL = sector address
	; Format sector data
	pushw 0x0010
	push xhl
	ldw wa, 0x0015
	muls xwa, iz
	lda xbc, (0x22a0d4:24)
	exts xwa
	add xwa, xbc
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)		; clean stack

	inc 1, iz
	cp iz, 0x0018
	jr lt, .Lfp_format_entry

.Lfp_loop_done:
	; --- Epilogue: vtable calls ---
	lda xwa, (0x22a0d0:24)
	ld xbc, xwa
	ld xwa, (xsp + 0x18)		; restore context ptr
	ld xde, xbc
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_RootFnTable)             ; XBC = (XBC + 0x0e0a)
	ld xhl, (xbc + RootFn_ApPostEvent)             ; XHL = (XBC + 0x0124)
	ld xbc, EVT_HDAE_SET_STR_ADR
	call (xhl)

	ld xwa, (xsp + 0x18)		; restore context ptr
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_RootFnTable)
	ld xhl, (xbc + RootFn_ApPostEvent)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xffffffff
	call (xhl)

	popw iz                                 ; pop iz (compact 1-byte)
	lda xsp, (xsp + 0x1a)		; deallocate 26-byte frame
	ret

; --- HDAE5000_SEL_DIR_Screen (0x2837F2) -------------------------------------
; Firmware's own name: HDAE5000_ScreenProc_Table entry 1 is 0x2837F2 and the
; parallel HDAE5000_ScreenName_Table entry points at 0x2A8570 =
; "SEL_DIR_Screen".  The old label HD_Format_Dispatch was a misnomer: the
; routine formats nothing.  It is the directory-selection screen procedure --
; every arm drives RAM 0x23A08E, which HDAE5000_Browser_State documents as the
; row-base offset added to every browser row address, over the five row slots
; 0x0000/0x0018/0x0030/0x0048/0x0060 (5 x 24 bytes).  0x01EA0000 adds 0x18 to
; that offset and gives up once it has reached the 0x0060 ceiling; 0x01EA0001
; subtracts 0x18 and gives up below the 0x0018 floor; both then post
; 0x01EA0003 back to the UI.  [INFERENCE] which of the two moves the list
; "down" on screen is not proven by this ROM.
;
; INFERENCE (not proven by this ROM): the 0x01EA000n codes index
; HDAE5000_MessageName_Table, giving n=0 MT_OverFlow, n=1 MT_UnderFlow,
; n=3 MT_SetSelNum, n=6/7 MT_SelectOK/MT_SelectOK2, n=8 MT_SelectSAVE.  The
; clamp arithmetic matches OverFlow/UnderFlow, but the main CPU assigns the
; codes and this ROM never spells the mapping out.  The per-arm comments
; below ("page down", "page up", "seek", "set format params") predate this
; note and have NOT been re-verified.
; Dispatches 0x01EA0000, 0x01EA0001, 0x01EA0006, 0x01EA0007, 0x01EA0008 and
; 0x01C00007; every other code falls straight through to .Lfd_done.
HDAE5000_SEL_DIR_Screen:	; 0x2837F2
	push xiz
	ld xiz, xde			; save XDE in XIZ

	; Dispatch on event code in XBC
	cp xbc, EVT_HDAE_OVER_FLOW
	jrl z, .Lfd_page_down		; 0x01EA0000 = page down
	cp xbc, EVT_HDAE_UNDER_FLOW
	jrl z, .Lfd_page_up		; 0x01EA0001 = page up
	cp xbc, EVT_HDAE_SELECT_SAVE
	jrl z, .Lfd_seek		; 0x01EA0008 = seek
	cp xbc, EVT_HDAE_SELECT_OK2
	jrl z, .Lfd_set_format		; 0x01EA0007 = set format params
	cp xbc, EVT_HDAE_SELECT_OK
	jrl z, .Lfd_set_format		; 0x01EA0006 = same handler
	cp xbc, EVT_SW_IN
	jrl nz, .Lfd_done		; not 0x01C00007 → exit

	; --- Handle 0x01C00007: UI navigation ---
	ld xde, xiz
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)             ; XWA = (XWA + 0x0e0a)
	ld_sril xix, (xwa + RootFn_SendEvent)             ; XIX = (XWA + 0x0100)
	ld xwa, 0x02600024
	ld xbc, EVT_MAKE_EDIT_SW_ID
	call (xix)			; call UI handler

	; Dispatch on XHL return value
	cp xhl, 0x00000007
	jr z, .Lfd_nav_case7
	cp xhl, 0x00000006
	jr z, .Lfd_nav_case6
	cp xhl, 0x00000005
	jr z, .Lfd_nav_case5
	cp xhl, 0x00000001
	jr z, .Lfd_nav_case1
	or xhl, xhl
	jrl nz, .Lfd_done		; XHL != 0 → exit

	; Case 0: offset = 0x0000
	ldw (HDAE5000_RAM_DirPageBase:24), 0x0000
	ld xwa, HDAE5000_OBJ_SEL_DIR
	calr HDAE5000_DirList_BuildPage
	jrl t, .Lfd_done

.Lfd_nav_case1:
	; Case 1: offset = 0x0018
	ldw (HDAE5000_RAM_DirPageBase:24), 0x0018
	ld xwa, HDAE5000_OBJ_SEL_DIR
	calr HDAE5000_DirList_BuildPage
	jrl t, .Lfd_done

.Lfd_nav_case5:
	; Case 5: offset = 0x0030
	ldw (HDAE5000_RAM_DirPageBase:24), 0x0030
	ld xwa, HDAE5000_OBJ_SEL_DIR
	calr HDAE5000_DirList_BuildPage
	jrl t, .Lfd_done

.Lfd_nav_case6:
	; Case 6: offset = 0x0048
	ldw (HDAE5000_RAM_DirPageBase:24), 0x0048
	ld xwa, HDAE5000_OBJ_SEL_DIR
	calr HDAE5000_DirList_BuildPage
	jrl t, .Lfd_done

.Lfd_nav_case7:
	; Case 7: offset = 0x0060
	ldw (HDAE5000_RAM_DirPageBase:24), 0x0060
	ld xwa, HDAE5000_OBJ_SEL_DIR
	calr HDAE5000_DirList_BuildPage
	jrl t, .Lfd_done

.Lfd_set_format:
	; Handle 0x01EA0006/0007: set format parameters
	ld bc, (HDAE5000_RAM_DirPageBase:24); BC = base offset
	ld wa, iz
	add wa, bc
	ld (HDAE5000_RAM_CurDir:24), wa; store new position
	ld wa, 0:i3			; WA = 0
	ld bc, 0:i3			; BC = 0
	calr HDAE5000_SongScreen_Refresh	; call HD read/write

	; Notify UI
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_ApPostEvent)             ; XHL = vtable method
	ld xwa, HDAE5000_OBJ_SELECT_FILE
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call (xhl)
	jrl t, .Lfd_done

.Lfd_seek:
	; Handle 0x01EA0008: seek operation
	ld wa, (HDAE5000_RAM_DirPageBase:24); WA = base offset
	ld bc, iz
	add bc, wa
	ld (HDAE5000_RAM_CurDir:24), bc; store seek position
	ld wa, bc
	call HDAE5000_DirName_Address			; XHL = sector address
	ld xde, xhl

	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_ApFuncCall)             ; XHL = (XWA + 0x0250) vtable method
	ld xwa, NAKA_APFUNC_HDD_DIRNAMECheck
	ld xbc, EVT_SET_STRING
	call (xhl)

	; Send completion notification
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_ApPostEvent)
	ld xwa, HDAE5000_OBJ_HDD_DIR_NAMING
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call (xhl)
	jr t, .Lfd_done

.Lfd_page_up:
	; Handle 0x01EA0001: page up
	cpw (HDAE5000_RAM_DirPageBase:24), 0x0018
	jr lt, .Lfd_done		; already at minimum
	subw (HDAE5000_RAM_DirPageBase:24), 0x0018; subtract 24 from offset
	ld xwa, HDAE5000_OBJ_SEL_DIR
	calr HDAE5000_DirList_BuildPage
	; Calculate new entry index
	ld xwa, xiz
	add xwa, 0x00000018
	ld xde, xwa

	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_ApPostEvent)
	ld xwa, HDAE5000_OBJ_SEL_DIR
	ld xbc, EVT_HDAE_SET_SEL_NUM
	call (xhl)
	jr t, .Lfd_done

.Lfd_page_down:
	; Handle 0x01EA0000: page down
	cpw (HDAE5000_RAM_DirPageBase:24), 0x0060
	jr ge, .Lfd_done		; already at maximum
	addw (HDAE5000_RAM_DirPageBase:24), 0x0018; add 24 to offset
	ld xwa, HDAE5000_OBJ_SEL_DIR
	calr HDAE5000_DirList_BuildPage
	; Calculate new entry index
	ld xwa, xiz
	sub xwa, 0x00000018
	ld xde, xwa

	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_ApPostEvent)
	ld xwa, HDAE5000_OBJ_SEL_DIR
	ld xbc, EVT_HDAE_SET_SEL_NUM
	call (xhl)

.Lfd_done:
	ld xhl, 0:i3
	pop xiz
	ret

HDAE5000_PartList_Build:	; 0x2839CC (412 bytes)
	; Build the part list of a song for list object XWA: the nine part names
	; of the table at 0x2E23D8 ("CURRENT PANEL", "PANEL MEMORY", "SEQUENCER",
	; "COMPOSER", "SOUND MEMORY", "MSP", "RHYTHM CUSTOM", "USER MIDI",
	; "LYRICS": parts LSW..TLX in order) go to 0x22B274, and each part whose
	; bit is clear in the stacked mask is blanked (0x2E24D8); all blank when BC
	; (directory) or DE (song) is 0xFFFF.  Then events 0x01EA000A / 0x01C0000F.
	; (Was "seek to cylinder/head position on HD".)
	; Args: XWA = context ptr, BC = cylinder, DE = head, (XSP+0x0a) = flags
	; Calls format function (0x29ae9f) with different params based on IZ flags

	; --- Prologue ---
	dec 4, xsp			; allocate 4 bytes
	pushw iz                                ; push iz (compact 1-byte form)
	ld (xsp + 0x02), xwa		; save context ptr
	ld iz, (xsp + 0x0a)		; IZ = flags

	; --- Check BC == 0xFFFF (invalid cylinder) ---
	cp bc, 0xffff
	jr z, .Lhsk_bc_invalid
	cp de, 0xffff			; check DE == 0xFFFF (invalid head)
	jr nz, .Lhsk_check_bits

.Lhsk_bc_invalid:
	pushw 0x007f
	lda xwa, (HDAE5000_PartNames_BlankText:24)
	push xwa
	lda xwa, (0x22b274:24)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)
	jrl t, .Lhsk_epilogue_vtable

.Lhsk_check_bits:
	pushw 0x007f
	lda xwa, (HDAE5000_PartNames_Text:24)
	push xwa
	lda xwa, (0x22b274:24)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)

	cp iz, 0xffff
	jrl z, .Lhsk_iz_invalid

	; --- Bit 0 ---
	bit 0, iz
	jr nz, .Lhsk_bit1
	pushw 0x000e
	lda xwa, (HDAE5000_PartName_Blank:24)
	push xwa
	lda xwa, (0x22b274:24)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)

.Lhsk_bit1:
	bit 1, iz
	jr nz, .Lhsk_bit2
	pushw 0x000e
	lda xwa, (HDAE5000_PartName_Blank:24)
	push xwa
	lda xwa, (0x22b282:24)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)

.Lhsk_bit2:
	bit 2, iz
	jr nz, .Lhsk_bit3
	pushw 0x000e
	lda xwa, (HDAE5000_PartName_Blank:24)
	push xwa
	lda xwa, (0x22b290:24)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)

.Lhsk_bit3:
	bit 3, iz
	jr nz, .Lhsk_bit4
	pushw 0x000e
	lda xwa, (HDAE5000_PartName_Blank:24)
	push xwa
	lda xwa, (0x22b29e:24)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)

.Lhsk_bit4:
	bit 4, iz
	jr nz, .Lhsk_bit5
	pushw 0x000e
	lda xwa, (HDAE5000_PartName_Blank:24)
	push xwa
	lda xwa, (0x22b2ac:24)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)

.Lhsk_bit5:
	bit 5, iz
	jr nz, .Lhsk_bit6
	pushw 0x000e
	lda xwa, (HDAE5000_PartName_Blank:24)
	push xwa
	lda xwa, (0x22b2ba:24)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)

.Lhsk_bit6:
	bit 6, iz
	jr nz, .Lhsk_bit7
	pushw 0x000e
	lda xwa, (HDAE5000_PartName_Blank:24)
	push xwa
	lda xwa, (0x22b2c8:24)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)

.Lhsk_bit7:
	bit 7, iz
	jr nz, .Lhsk_bit8
	pushw 0x000e
	lda xwa, (HDAE5000_PartName_Blank:24)
	push xwa
	lda xwa, (0x22b2d6:24)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)

.Lhsk_bit8:
	bit 8, iz
	jr nz, .Lhsk_epilogue_vtable
	pushw 0x000e
	lda xwa, (HDAE5000_PartName_Blank:24)
	push xwa
	lda xwa, (0x22b2e4:24)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)
	jr t, .Lhsk_epilogue_vtable

.Lhsk_iz_invalid:
	pushw 0x007f
	lda xwa, (HDAE5000_PartNames_BlankText:24)
	push xwa
	lda xwa, (0x22b274:24)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)

.Lhsk_epilogue_vtable:
	; Load vtable and call two methods
	lda xwa, (0x22b274:24)
	ld xbc, xwa
	ld xwa, (xsp + 0x02)		; restore context ptr
	ld xde, xbc
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_RootFnTable)             ; XBC = (XBC + 0x0e0a)
	ld xhl, (xbc + RootFn_ApPostEvent)             ; XHL = (XBC + 0x0124)
	ld xbc, EVT_HDAE_SET_STR_ADR
	call (xhl)

	ld xwa, (xsp + 0x02)		; restore context ptr
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_RootFnTable)             ; XBC = (XBC + 0x0e0a)
	ld xhl, (xbc + RootFn_ApPostEvent)             ; XHL = (XBC + 0x0124)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xffffffff
	call (xhl)

	; --- Epilogue ---
	popw iz                                 ; pop iz (compact 1-byte form)
	inc 4, xsp
	retd 0x0002

HDAE5000_SongScreen_Refresh:	; 0x283B68 (4737 bytes)
	; Refresh the song-selection screen (variant A selects the object-id
	; pairs at 0x2E24E8/0x2E24F0/0x2E24F8; C != 0 skips the static parts):
	; title "DIRECTORY NN:<name>" (0x22A038), the 16 song rows of directory
	; 0x23A092 (0x22AE3E, 30 bytes each), and the part list of song 0x23A094
	; (HDAE5000_PartList_Build with HDAE5000_Song_PartMask).  (Was HD_Read_Write.)
; LHRW: 0x283B68 (4737 bytes)
	; ^ conversion-region size (local-label prefix .LHRW_), not a routine size.

	lda	xsp, (xsp-26)
	pushw iz                                ; push IZ
	ld	(xsp+24), c
	ld	(xsp+26), a
	cp	(xsp+24), 0x00
	jrl nz, .LHRW_3c5d                     ; [7e e4 00] jrl NZ,0x283c5d
	pushw 0x0020
	pushw 0x0000
	lda xwa, (0x22a038:24)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2500		; low half of HDAE5000_Str_DIRECTORY
	pushw 0x0022
	pushw 0xa038
	call HDAE5000_StrCat
	ld	wa, (HDAE5000_RAM_CurDir:24)
	inc	1, wa
	pushw wa                                ; push WA
	pushw 0x002e
	pushw 0x250c		; low half of HDAE5000_Fmt_2_2d_SongScreen_Refresh
	lda	xwa, (xsp+24)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+26)
	lda	xwa, (xsp+2)
	push xwa
	pushw 0x0022
	pushw 0xa038
	call HDAE5000_StrCat
	pushw 0x002e
	pushw 0x2512		; low half of HDAE5000_Str_Chr3A_SongScreen_Refresh
	pushw 0x0022
	pushw 0xa038
	call HDAE5000_StrCat
	lda	xsp, (xsp+16)
	pushw 0x0010
	ld	wa, (HDAE5000_RAM_CurDir:24)
	call HDAE5000_DirName_Address
	push xhl
	pushw 0x0022
	pushw 0xa038
	call HDAE5000_StrNCat
	pushw 0x002e
	pushw 0x2514		; low half of HDAE5000_Str_Blank0Tab
	pushw 0x0022
	pushw 0xa038
	call HDAE5000_StrCat
	lda	xsp, (xsp+18)
	ld	a, (xsp+26)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda xbc, (HDAE5000_SongScreen_Refresh_ObjIds:24)
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	lda xwa, (0x22a038:24)
	ld	xbc, xwa
	ld	xwa, xde
	ld	xde, xbc
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_ApPostEvent)
	ld	xbc, EVT_HDAE_SET_STR_ADR
	call	(xhl)
	ld	a, (xsp+26)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda xbc, (HDAE5000_SongScreen_Refresh_ObjIds:24)
	ld_sril3 xwa, 0x07, 0xE4, 0xE0	; ld XWA,(XBC+WA)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_ApPostEvent)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0xffffffff
	call	(xhl)
.LHRW_3c5d:
	cp	(xsp+24), 0x00
	jrl nz, .LHRW_3d45                     ; [7e e1 00] jrl NZ,0x283d45
	ld	iz, 0:i3
	cp	iz, 0x0010
	jr ge, .LHRW_3ce5                      ; [69 79] jr GE,0x283ce5
.LHRW_3c6c:
	pushw 0x001c
	lda xwa, (HDAE5000_Str_Chr3A2020202020:24)
	push xwa
	ldw	wa, 0x001e
	muls	xwa, iz
	lda xbc, (0x22ae40:24)
	exts xwa                                ; exts XWA
	add	xwa, xbc
	push xwa
	call HDAE5000_MemCopy
	ld	wa, iz
	inc	1, wa
	pushw wa                                ; push WA
	pushw 0x002e
	pushw 0x2534		; low half of HDAE5000_Fmt_2_2d_SongScreen_Refresh_2
	lda	xwa, (xsp+18)
	push xwa
	call HDAE5000_SPrintf
	pushw 0x0002
	lda	xwa, (xsp+24)
	push xwa
	ldw	wa, 0x001e
	muls	xwa, iz
	lda xbc, (0x22ae3e:24)
	exts xwa                                ; exts XWA
	add	xwa, xbc
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+30)
	ld	bc, iz
	ld	wa, (HDAE5000_RAM_CurDir:24)
	call HDAE5000_SongRecord_Address
	pushw 0x001a
	push xhl
	ldw	wa, 0x001e
	muls	xwa, iz
	lda xbc, (0x22ae41:24)
	exts xwa                                ; exts XWA
	add	xwa, xbc
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+10)
	inc	1, iz
	cp	iz, 0x0010
	jr lt, .LHRW_3c6c                      ; [61 87] jr LT,0x283c6c
.LHRW_3ce5:
	ld	a, (xsp+26)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda xbc, (HDAE5000_SongScreen_Refresh_ObjIds_2:24)
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	lda xwa, (0x22ae3e:24)
	ld	xbc, xwa
	ld	xwa, xde
	ld	xde, xbc
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_ApPostEvent)
	ld	xbc, EVT_HDAE_SET_STR_ADR
	call	(xhl)
	ld	a, (xsp+26)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda xbc, (HDAE5000_SongScreen_Refresh_ObjIds_2:24)
	ld_sril3 xwa, 0x07, 0xE4, 0xE0	; ld XWA,(XBC+WA)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_ApPostEvent)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0xffffffff
	call	(xhl)
.LHRW_3d45:
	ld	wa, (HDAE5000_RAM_CurDir:24)
	ld	bc, (HDAE5000_RAM_CurSong:24)
	call HDAE5000_Song_PartMask
	ld	wa, hl
	cp	wa, 0xffff
	jr z, .LHRW_3d7d                       ; [66 22] jr Z,0x283d7d
	ld	a, (xsp+26)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda xbc, (HDAE5000_SongScreen_Refresh_ObjIds_3:24)
	ld_sril3 xwa, 0x07, 0xE4, 0xE0	; ld XWA,(XBC+WA)
	ld	bc, (HDAE5000_RAM_CurDir:24)
	ld	de, (HDAE5000_RAM_CurSong:24)
	pushw hl                                ; push HL
	calr	HDAE5000_PartList_Build
	jr t, .LHRW_3d9b                       ; [68 1e] jr T,0x283d9b
.LHRW_3d7d:
	ld	a, (xsp+26)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda xbc, (HDAE5000_SongScreen_Refresh_ObjIds_3:24)
	ld_sril3 xwa, 0x07, 0xE4, 0xE0	; ld XWA,(XBC+WA)
	pushw 0xffff
	ldw	bc, 0xffff
	ldw	de, 0xffff
	calr	HDAE5000_PartList_Build
.LHRW_3d9b:
	popw iz                                 ; pop IZ
	lda	xsp, (xsp+26)
	ret

HDAE5000_FILE_LOAD_Screen:
	; registered as "FILE_LOAD_Screen" in HDAE5000_ScreenProc_Table
	push xiz
	ld	xiz, xde
	ld	xwa, xbc
	cp	xwa, EVT_SW_IN
	jrl z, HDAE5000_FILE_LOAD_Screen_Default                      ; [76 cd 01] jrl Z,0x283f7b
	cp	xwa, EVT_SHOW
	jr z, HDAE5000_FILE_LOAD_Screen_Ev01C00001                       ; [66 2c] jr Z,0x283de2
	sub	xwa, EVT_HDAE_OVER_FLOW
	cp	xwa, 0x00000000
	jrl lt, HDAE5000_FILE_LOAD_Screen_Default                     ; [71 b6 01] jrl LT,0x283f7b
	cp	xwa, 0x0000000d
	jrl gt, HDAE5000_FILE_LOAD_Screen_Default                     ; [7a ad 01] jrl GT,0x283f7b
	add	xwa, xwa
	add	xwa, HDAE5000_FILE_LOAD_Screen_CaseTable
	ld	wa, (xwa)
	lda xix, (HDAE5000_FILE_LOAD_Screen_Ev01C00001:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_FILE_LOAD_Screen_Ev01C00001:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_ApPostEvent)
	ld	xwa, HDAE5000_OBJ_HD_FILE_LIST
	ld	xbc, EVT_HDAE_CHANGE_SEL_NUM
	ld	xde, 0:i3
	call	(xhl)
	jrl t, HDAE5000_FILE_LOAD_Screen_Default                      ; [78 79 01] jrl T,0x283f7b
HDAE5000_FILE_LOAD_Screen_Ev01EA0008:
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	pushw 0x0002
	lda xde, (HDAE5000_TypeSel_TemplateAllNo:24)
	ldw	bc, 0x003f
	calr	HDAE5000_TypeSel_Init
	ld	(HDAE5000_RAM_CurSong), iz
	ld	wa, (HDAE5000_RAM_CurDir:24)
	ld	bc, (HDAE5000_RAM_CurSong:24)
	call HDAE5000_SongRecord_Address
	ld	xde, xhl
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_ApFuncCall)
	ld	xwa, NAKA_APFUNC_HDDNamingCheck
	ld	xbc, EVT_SET_STRING
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_ApPostEvent)
	ld	xwa, HDAE5000_OBJ_HDD_FILE_NAMING
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	call	(xhl)
	jrl t, HDAE5000_FILE_LOAD_Screen_Default                      ; [78 16 01] jrl T,0x283f7b
HDAE5000_FILE_LOAD_Screen_Ev01EA000D:
	ld	(HDAE5000_RAM_CurSong), iz
	ld	wa, (HDAE5000_RAM_CurDir:24)
	ld	bc, (HDAE5000_RAM_CurSong:24)
	ld	de, 0:i3
	calr	HDAE5000_DelOpt_InitFromSong
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_ApPostEvent)
	ld	xwa, HDAE5000_OBJ_FILE_DEL_SCREEN
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	call	(xhl)
	jrl t, HDAE5000_FILE_LOAD_Screen_Default                      ; [78 e2 00] jrl T,0x283f7b
HDAE5000_FILE_LOAD_Screen_Ev01EA000C:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_ApPostEvent)
	ld	xwa, HDAE5000_OBJ_ATTEN_DEL_DIR
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	call	(xhl)
	jrl t, HDAE5000_FILE_LOAD_Screen_Default                      ; [78 c2 00] jrl T,0x283f7b
HDAE5000_FILE_LOAD_Screen_Ev01EA0001:
	cpw	(HDAE5000_RAM_CurDir:24), 0
	jrl z, HDAE5000_FILE_LOAD_Screen_Default                      ; [76 b8 00] jrl Z,0x283f7b
	decw	1, (HDAE5000_RAM_CurDir:24)
	ld	wa, 0:i3
	ld	bc, 0:i3
	calr	HDAE5000_SongScreen_Refresh
	ld	xwa, xiz
	add	xwa, 0x00000010
	ld	xde, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_ApPostEvent)
	ld	xwa, HDAE5000_OBJ_HD_FILE_LIST
	ld	xbc, EVT_HDAE_SET_SEL_NUM
	call	(xhl)
	jrl t, HDAE5000_FILE_LOAD_Screen_Default                      ; [78 84 00] jrl T,0x283f7b
HDAE5000_FILE_LOAD_Screen_Ev01EA0000:
	cpw	(HDAE5000_RAM_CurDir:24), 119
	jr nc, HDAE5000_FILE_LOAD_Screen_Default                      ; [6f 7b] jr NC,0x283f7b
	incw	1, (HDAE5000_RAM_CurDir:24)
	ld	wa, 0:i3
	ld	bc, 0:i3
	calr	HDAE5000_SongScreen_Refresh
	ld	xwa, xiz
	sub	xwa, 0x00000010
	ld	xde, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_ApPostEvent)
	ld	xwa, HDAE5000_OBJ_HD_FILE_LIST
	ld	xbc, EVT_HDAE_SET_SEL_NUM
	call	(xhl)
	jr t, HDAE5000_FILE_LOAD_Screen_Default                       ; [68 48] jr T,0x283f7b
HDAE5000_FILE_LOAD_Screen_Ev01EA0002:
	ld	(HDAE5000_RAM_CurSong), iz
	ld	wa, (HDAE5000_RAM_CurDir:24)
	ld	bc, (HDAE5000_RAM_CurSong:24)
	call HDAE5000_Song_PartMask
	ld	wa, hl
	cp	wa, 0xffff
	jr z, .LHRW_3f62                       ; [66 14] jr Z,0x283f62
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	pushw 0x0002
	ld	bc, hl
	lda xde, (HDAE5000_TypeSel_TemplateBlank:24)
	calr	HDAE5000_TypeSel_Init
	jr t, .LHRW_3f74                       ; [68 12] jr T,0x283f74
.LHRW_3f62:
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	pushw 0x0002
	lda xde, (HDAE5000_TypeSel_TemplateBlank:24)
	ld	bc, 0:i3
	calr	HDAE5000_TypeSel_Init
.LHRW_3f74:
	ld	wa, 0:i3
	ld	bc, 1:i3
	calr	HDAE5000_SongScreen_Refresh
HDAE5000_FILE_LOAD_Screen_Default:
	ld	xhl, 0:i3
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_AttenDelDirSwCatch:
	; registered as "AttenDelDirSwCatch" in HDAE5000_ObjHandler_Table
	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, EVT_SW_IN
	jr z, .LHRW_3ff0                       ; [66 64] jr Z,0x283ff0
	cp	xwa, EVT_DRAW
	jr z, .LHRW_3fb7                       ; [66 23] jr Z,0x283fb7
	cp	xwa, EVT_ARE_YOU_CLASS_PROC
	jr z, .LHRW_3fb2                       ; [66 16] jr Z,0x283fb2
	ld	xwa, xiz
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xix, (xhl + RootFn_InheritedProc)
	call	(xix)
	jrl t, .LHRW_40a1                      ; [78 ef 00] jrl T,0x2840a1
.LHRW_3fb2:
	ld	xhl, 1:i3
	jrl t, .LHRW_40a1                      ; [78 ea 00] jrl T,0x2840a1
.LHRW_3fb7:
	ld	xwa, xiz
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	lda xwa, (HDAE5000_Str_DELD:24)
	ld	xbc, xwa
	ld	xwa, xiz
	ld	xde, xbc
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, EVT_PARA_DRAW
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LHRW_40a1                      ; [78 b1 00] jrl T,0x2840a1
.LHRW_3ff0:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xix, (xwa + RootFn_SendEvent)
	ld	xwa, 0x02600024
	ld	xbc, EVT_MAKE_EDIT_SW_ID
	call	(xix)
	cp	xhl, 0x00000007
	jr z, .LHRW_4082                       ; [66 6f] jr Z,0x284082
	cp	xhl, 0x00000006
	jr z, .LHRW_4082                       ; [66 67] jr Z,0x284082
	cp	xhl, 0x00000001
	jr z, .LHRW_4027                       ; [66 04] jr Z,0x284027
	or xhl, xhl                             ; or XHL,XHL
	jr nz, .LHRW_409f                      ; [6e 78] jr NZ,0x28409f
.LHRW_4027:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_WAIT_DEL_DIR
	ld	xbc, EVT_SHOW
	ld	xde, 3:i3
	call	(xhl)
	calr	HDAE5000_YieldUntilSem1Zero
	ld	wa, (HDAE5000_RAM_CurDir:24)
	ld	bc, 1:i3
	ld	de, 0:i3
	call HDAE5000_DeleteDirectory
	ld	xwa, HDAE5000_OBJ_SEL_DIR
	calr	HDAE5000_DirList_BuildPage
	ld	wa, 0:i3
	ld	bc, 0:i3
	calr	HDAE5000_SongScreen_Refresh
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_PostEvent)
	ld	xwa, HDAE5000_OBJ_SELECT_FILE
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	call	(xhl)
	jr t, .LHRW_409f                       ; [68 1d] jr T,0x28409f
.LHRW_4082:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_PostEvent)
	ld	xwa, HDAE5000_OBJ_SELECT_FILE
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	call	(xhl)
.LHRW_409f:
	ld	xhl, 0:i3
.LHRW_40a1:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_AttenDelFileSwCatch:
	; registered as "AttenDelFileSwCatch" in HDAE5000_ObjHandler_Table
	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, EVT_SW_IN
	jr z, .LHRW_4114                       ; [66 64] jr Z,0x284114
	cp	xwa, EVT_DRAW
	jr z, .LHRW_40db                       ; [66 23] jr Z,0x2840db
	cp	xwa, EVT_ARE_YOU_CLASS_PROC
	jr z, .LHRW_40d6                       ; [66 16] jr Z,0x2840d6
	ld	xwa, xiz
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xix, (xhl + RootFn_InheritedProc)
	call	(xix)
	jrl t, .LHRW_41e3                      ; [78 0d 01] jrl T,0x2841e3
.LHRW_40d6:
	ld	xhl, 1:i3
	jrl t, .LHRW_41e3                      ; [78 08 01] jrl T,0x2841e3
.LHRW_40db:
	ld	xwa, xiz
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	lda xwa, (HDAE5000_Str_DELF:24)
	ld	xbc, xwa
	ld	xwa, xiz
	ld	xde, xbc
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, EVT_PARA_DRAW
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LHRW_41e3                      ; [78 cf 00] jrl T,0x2841e3
.LHRW_4114:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xix, (xwa + RootFn_SendEvent)
	ld	xwa, 0x02600024
	ld	xbc, EVT_MAKE_EDIT_SW_ID
	call	(xix)
	cp	xhl, 0x00000007
	jrl z, .LHRW_41c4                      ; [76 8c 00] jrl Z,0x2841c4
	cp	xhl, 0x00000006
	jrl z, .LHRW_41c4                      ; [76 83 00] jrl Z,0x2841c4
	cp	xhl, 0x00000001
	jr z, .LHRW_414e                       ; [66 05] jr Z,0x28414e
	or xhl, xhl                             ; or XHL,XHL
	jrl nz, .LHRW_41e1                     ; [7e 93 00] jrl NZ,0x2841e1
.LHRW_414e:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_WAIT_DEL_FILE
	ld	xbc, EVT_SHOW
	ld	xde, 3:i3
	call	(xhl)
	calr	HDAE5000_YieldUntilSem1Zero
	pushw 0x0001
	pushw 0x0000
	ld	wa, (HDAE5000_RAM_CurDir:24)
	ld	bc, (HDAE5000_RAM_CurSong:24)
	ld	de, (HDAE5000_RAM_DeleteOptions:24)
	call HDAE5000_DeleteSongParts
	ld	wa, (HDAE5000_RAM_CurDir:24)
	ld	bc, (HDAE5000_RAM_CurSong:24)
	ld	de, 1:i3
	calr	HDAE5000_DelOpt_InitFromSong
	ld	xwa, HDAE5000_OBJ_SEL_DIR
	calr	HDAE5000_DirList_BuildPage
	ld	wa, 0:i3
	ld	bc, 0:i3
	calr	HDAE5000_SongScreen_Refresh
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_ApPostEvent)
	ld	xwa, HDAE5000_OBJ_SELECT_FILE
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	call	(xhl)
	jr t, .LHRW_41e1                       ; [68 1d] jr T,0x2841e1
.LHRW_41c4:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_PostEvent)
	ld	xwa, HDAE5000_OBJ_FILE_DEL_SCREEN
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	call	(xhl)
.LHRW_41e1:
	ld	xhl, 0:i3
.LHRW_41e3:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_FileLoadSwCatch:
	; registered as "FileLoadSwCatch" in HDAE5000_ScreenProc_Table
	cp	xbc, EVT_SW_IN
	jr nz, .LHRW_4267                      ; [6e 7a] jr NZ,0x284267
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xix, (xwa + RootFn_SendEvent)
	ld	xwa, 0x02600024
	ld	xbc, EVT_MAKE_EDIT_SW_ID
	call	(xix)
	cp	xhl, 0x00000009
	jr z, .LHRW_4218                       ; [66 08] jr Z,0x284218
	cp	xhl, 0x00000008
	jr nz, .LHRW_4267                      ; [6e 4f] jr NZ,0x284267
.LHRW_4218:
	pushw 0x0000
	ld	xwa, HDAE5000_OBJ_SELECT_FILE
	push xwa
	ld	wa, (HDAE5000_RAM_CurDir:24)
	ld	bc, (HDAE5000_RAM_CurSong:24)
	ld	de, (HDAE5000_RAM_SaveOptions:24)
	calr	HDAE5000_LoadSongWithUi
	cp	(HDAE5000_RAM_LyricJump:24), 2
	jr nz, .LHRW_4267                      ; [6e 2c] jr NZ,0x284267
	ld	wa, (HDAE5000_RAM_SaveOptions:24)
	and	wa, 0x0100
	cp	wa, 0x0100
	jr nz, .LHRW_4267                      ; [6e 1d] jr NZ,0x284267
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_ApPostEvent)
	ld	xwa, HDAE5000_OBJ_Tech_lyrics
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	call	(xhl)
.LHRW_4267:
	ld	xhl, 0:i3
	ret

HDAE5000_FILE_Naming_Screen:
	; registered as "FILE_Naming_Screen" in HDAE5000_ScreenProc_Table
	cp	xbc, EVT_SW_IN
	jr nz, .LHRW_4295                      ; [6e 23] jr NZ,0x284295
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xix, (xwa + RootFn_SendEvent)
	ld	xwa, 0x02600024
	ld	xbc, EVT_MAKE_EDIT_SW_ID
	call	(xix)
	cp	xhl, 0x0000000b
	jr z, .LHRW_4295                       ; [66 00] jr Z,0x284295
.LHRW_4295:
	ld	xhl, 0:i3
	ret

HDAE5000_HDDNamingCheck:
	; registered as "HDDNamingCheck" in HDAE5000_ObjHandler_Table
	push xiz
	ld	xiz, xwa
	cp	xbc, EVT_SW_IN
	jr z, .LHRW_42fd                       ; [66 5a] jr Z,0x2842fd
	cp	xbc, EVT_GET_STRING_LENGTH
	jr z, .LHRW_42f5                       ; [66 4a] jr Z,0x2842f5
	cp	xbc, EVT_GET_NAMING_MODE
	jr z, .LHRW_42f0                       ; [66 3d] jr Z,0x2842f0
	cp	xbc, EVT_SET_STRING
	jr z, .LHRW_42da                       ; [66 1f] jr Z,0x2842da
	cp	xbc, EVT_GET_STRING
	jrl nz, .LHRW_4469                     ; [7e a5 01] jrl NZ,0x284469
	pushw 0x001a
	lda xwa, (0x23a04e:24)
	push xwa
	push xde
	call HDAE5000_StrNCpy
	lda	xsp, (xsp+10)
	ld	xhl, xiz
	jrl t, .LHRW_446b                      ; [78 91 01] jrl T,0x28446b
.LHRW_42da:
	pushw 0x001a
	push xde
	pushw 0x0023
	pushw 0xa04e
	call HDAE5000_StrNCpy
	lda	xsp, (xsp+10)
	ld	xhl, xiz
	jrl t, .LHRW_446b                      ; [78 7b 01] jrl T,0x28446b
.LHRW_42f0:
	ld	xhl, 0:i3
	jrl t, .LHRW_446b                      ; [78 76 01] jrl T,0x28446b
.LHRW_42f5:
	ld	xhl, 0x0000001a
	jrl t, .LHRW_446b                      ; [78 6e 01] jrl T,0x28446b
.LHRW_42fd:
	cp	xde, 0x0000000b
	jrl z, .LHRW_43e4                      ; [76 de 00] jrl Z,0x2843e4
	cp	xde, 0x0000000a
	jr z, .LHRW_4365                       ; [66 57] jr Z,0x284365
	cp	xde, 0x0000008a
	jrl nz, .LHRW_4469                     ; [7e 52 01] jrl NZ,0x284469
	lda xwa, (0x22ac7e:24)
	calr	HDAE5000_NameHistory_Recall
	ld	xiz, xhl
	ld	xwa, xiz
	or xwa, xwa                             ; or XWA,XWA
	jrl z, .LHRW_4469                      ; [76 41 01] jrl Z,0x284469
	ld	xwa, xiz
	push xwa
	call HDAE5000_StrLen
	pushw hl                                ; push HL
	ld	xwa, xiz
	push xwa
	lda xwa, (0x23a04e:24)
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+14)
	lda xwa, (0x23a04e:24)
	ld	xde, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_HddNamingWindow
	ld	xbc, EVT_SET_STRING
	call	(xhl)
	jrl t, .LHRW_4469                      ; [78 04 01] jrl T,0x284469
.LHRW_4365:
	ld	wa, (HDAE5000_RAM_CurDir:24)
	ld	bc, (HDAE5000_RAM_CurSong:24)
	call HDAE5000_Song_PartMask
	ld	wa, hl
	cp	wa, 0xffff
	jr nz, .LHRW_4390                      ; [6e 15] jr NZ,0x284390
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	pushw 0x0002
	lda xde, (HDAE5000_TypeSel_TemplateAllNo:24)
	ldw	bc, 0x003f
	calr	HDAE5000_TypeSel_Init
	jr t, .LHRW_43a2                       ; [68 12] jr T,0x2843a2
.LHRW_4390:
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	pushw 0x0002
	ld	bc, hl
	lda xde, (HDAE5000_TypeSel_TemplateAllNo:24)
	calr	HDAE5000_TypeSel_Init
.LHRW_43a2:
	lda xwa, (0x23a04e:24)
	ld	xde, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_HddNamingWindow
	ld	xbc, EVT_GET_STRING
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_PostEvent)
	ld	xwa, HDAE5000_OBJ_SAVE_OPT_SCREEN
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	call	(xhl)
	jrl t, .LHRW_4469                      ; [78 85 00] jrl T,0x284469
.LHRW_43e4:
	lda xwa, (0x23a04e:24)
	ld	xde, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_HddNamingWindow
	ld	xbc, EVT_GET_STRING
	call	(xhl)
	cp	(HDAE5000_RAM_WriteConfirm:24), 1
	jr nz, .LHRW_4441                      ; [6e 33] jr NZ,0x284441
	ld	wa, (HDAE5000_RAM_CurDir:24)
	ld	bc, (HDAE5000_RAM_CurSong:24)
	call HDAE5000_Song_IsUsed
	cp	hl, 0xffff
	jr z, .LHRW_4441                       ; [66 1f] jr Z,0x284441
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_PostEvent)
	ld	xwa, HDAE5000_OBJ_ATTEN_OVER_FILE
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	call	(xhl)
	jr t, .LHRW_4462                       ; [68 21] jr T,0x284462
.LHRW_4441:
	pushw 0x0023
	pushw 0xa04e
	pushw 0x0001
	ld	xwa, HDAE5000_OBJ_SELECT_FILE
	push xwa
	ld	wa, (HDAE5000_RAM_CurDir:24)
	ld	bc, (HDAE5000_RAM_CurSong:24)
	ld	de, (HDAE5000_RAM_SaveOptions:24)
	calr	HDAE5000_SaveSongWithUi
.LHRW_4462:
	ld	wa, 0:i3
	ld	bc, 0:i3
	calr	HDAE5000_SongScreen_Refresh
.LHRW_4469:
	ld	xhl, 0:i3
.LHRW_446b:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_HDD_DIRNAMECheck:
	; registered as "HDD_DIRNAMECheck" in HDAE5000_ObjHandler_Table
	push xiz
	ld	xiz, xwa
	cp	xbc, EVT_SW_IN
	jr z, .LHRW_44d8                       ; [66 60] jr Z,0x2844d8
	cp	xbc, EVT_GET_STRING_LENGTH
	jr z, .LHRW_44d0                       ; [66 50] jr Z,0x2844d0
	cp	xbc, EVT_GET_NAMING_MODE
	jr z, .LHRW_44cb                       ; [66 43] jr Z,0x2844cb
	cp	xbc, EVT_SET_STRING
	jr z, .LHRW_44af                       ; [66 1f] jr Z,0x2844af
	cp	xbc, EVT_GET_STRING
	jrl nz, .LHRW_4592                     ; [7e f9 00] jrl NZ,0x284592
	pushw 0x0010
	lda xwa, (0x23a06e:24)
	push xwa
	push xde
	call HDAE5000_StrNCpy
	lda	xsp, (xsp+10)
	ld	xhl, xiz
	jrl t, .LHRW_4594                      ; [78 e5 00] jrl T,0x284594
.LHRW_44af:
	pushw 0x0010
	push xde
	pushw 0x0023
	pushw 0xa06e
	call HDAE5000_StrNCpy
	lda	xsp, (xsp+10)
	ld	(0x23A07E:24), 0
	ld	xhl, xiz
	jrl t, .LHRW_4594                      ; [78 c9 00] jrl T,0x284594
.LHRW_44cb:
	ld	xhl, 0:i3
	jrl t, .LHRW_4594                      ; [78 c4 00] jrl T,0x284594
.LHRW_44d0:
	ld	xhl, 0x00000010
	jrl t, .LHRW_4594                      ; [78 bc 00] jrl T,0x284594
.LHRW_44d8:
	cp	xde, 0x0000000b
	jr z, .LHRW_4546                       ; [66 66] jr Z,0x284546
	cp	xde, 0x0000008a
	jrl nz, .LHRW_4592                     ; [7e a9 00] jrl NZ,0x284592
	lda xwa, (0x22abf2:24)
	calr	HDAE5000_NameHistory_Recall
	ld	xiz, xhl
	ld	xwa, xiz
	or xwa, xwa                             ; or XWA,XWA
	jrl z, .LHRW_4592                      ; [76 98 00] jrl Z,0x284592
	ld	xwa, xiz
	push xwa
	call HDAE5000_StrLen
	pushw hl                                ; push HL
	ld	xwa, xiz
	push xwa
	lda xwa, (0x23a06e:24)
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+14)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xix, (xwa + RootFn_GetNamingWindowID)
	call	(xix)
	lda xwa, (0x23a06e:24)
	ld	xbc, xwa
	ld	xwa, xhl
	ld	xde, xbc
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, EVT_SET_STRING
	call	(xhl)
	jr t, .LHRW_4592                       ; [68 4c] jr T,0x284592
.LHRW_4546:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xix, (xwa + RootFn_GetNamingWindowID)
	call	(xix)
	lda xwa, (0x23a06e:24)
	ld	xbc, xwa
	ld	xwa, xhl
	ld	xde, xbc
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, EVT_GET_STRING
	call	(xhl)
	ld	wa, (HDAE5000_RAM_CurDir:24)
	lda xbc, (0x23a06e:24)
	ld	xde, HDAE5000_OBJ_SELECT_DIR
	calr	HDAE5000_DirName_StoreWithUi
	ld	xwa, HDAE5000_OBJ_SEL_DIR
	calr	HDAE5000_DirList_BuildPage
.LHRW_4592:
	ld	xhl, 0:i3
.LHRW_4594:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_HDD_UTIL_PAGE:
	; registered as "HDD_UTIL_PAGE" in HDAE5000_ObjHandler_Table
	lda	xsp, (xsp-112)
	push xiz
	ld (xsp + 0x6c), xde                    ; ld (XSP+0x6c),XDE
	ld	xiz, xbc
	ld (xsp + 0x70), xwa                    ; ld (XSP+0x70),XWA
	ld	xwa, xiz
	cp	xwa, EVT_SW_IN
	jr z, .LHRW_4602                       ; [66 56] jr Z,0x284602
	cp	xwa, EVT_DRAW
	jr z, .LHRW_45c2                       ; [66 0e] jr Z,0x2845c2
	cp	xwa, EVT_ARE_YOU_CLASS_PROC
	jrl nz, .LHRW_4d61                     ; [7e a4 07] jrl NZ,0x284d61
	ld	xhl, 1:i3
	jrl t, .LHRW_4d7a                      ; [78 b8 07] jrl T,0x284d7a
.LHRW_45c2:
	ld xwa, (xsp + 0x70)                    ; ld XWA,(XSP+0x70)
	ld	xbc, xiz
	ld xde, (xsp + 0x6c)                    ; ld XDE,(XSP+0x6c)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	lda xwa, (HDAE5000_Str_UTIL:24)
	ld	xbc, xwa
	ld xwa, (xsp + 0x70)                    ; ld XWA,(XSP+0x70)
	ld	xde, xbc
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, EVT_PARA_DRAW
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LHRW_4d7a                      ; [78 78 07] jrl T,0x284d7a
.LHRW_4602:
	ld xwa, (xsp + 0x6c)                    ; ld XWA,(XSP+0x6c)
	cp	xwa, 0x0000000b
	jrl nz, .LHRW_4d61                     ; [7e 53 07] jrl NZ,0x284d61
	calr	HDAE5000_HardTest_HddIdRead
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_GetResouceInfo)
	ld	wa, 0:i3
	call	(xhl)
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2568		; low half of HDAE5000_Str_LSWFileInfo
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2582		; low half of HDAE5000_Str_Adr
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1a)                    ; ld XWA,(XSP+0x1a)
	push xwa
	call HDAE5000_LToA
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCat
	inc 8, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x258a		; low half of HDAE5000_Str_Size
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1e)                    ; ld XWA,(XSP+0x1e)
	push xwa
	call HDAE5000_LToA
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCat
	inc 8, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_GetResouceInfo)
	ld	wa, 1:i3
	call	(xhl)
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2592		; low half of HDAE5000_Str_SDAFileInfo
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x25ac		; low half of HDAE5000_Str_Adr_HDD_UTIL_PAGE
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1a)                    ; ld XWA,(XSP+0x1a)
	push xwa
	call HDAE5000_LToA
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCat
	inc 8, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x25b4		; low half of HDAE5000_Str_Size_HDD_UTIL_PAGE
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1e)                    ; ld XWA,(XSP+0x1e)
	push xwa
	call HDAE5000_LToA
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCat
	inc 8, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_GetResouceInfo)
	ld	wa, 2:i3
	call	(xhl)
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x25bc		; low half of HDAE5000_Str_PMTFileInfo
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x25d6		; low half of HDAE5000_Str_Adr_HDD_UTIL_PAGE_2
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1a)                    ; ld XWA,(XSP+0x1a)
	push xwa
	call HDAE5000_LToA
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCat
	inc 8, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x25de		; low half of HDAE5000_Str_Size_HDD_UTIL_PAGE_2
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1e)                    ; ld XWA,(XSP+0x1e)
	push xwa
	call HDAE5000_LToA
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCat
	inc 8, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_GetResouceInfo)
	ld	wa, 3:i3
	call	(xhl)
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x25e6		; low half of HDAE5000_Str_SQFFileInfo
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2600		; low half of HDAE5000_Str_Adr_HDD_UTIL_PAGE_3
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1a)                    ; ld XWA,(XSP+0x1a)
	push xwa
	call HDAE5000_LToA
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCat
	inc 8, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2608		; low half of HDAE5000_Str_Size_HDD_UTIL_PAGE_3
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1e)                    ; ld XWA,(XSP+0x1e)
	push xwa
	call HDAE5000_LToA
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCat
	inc 8, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_GetResouceInfo)
	ld	wa, 4:i3
	call	(xhl)
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2610		; low half of HDAE5000_Str_SEQFileInfo
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x262a		; low half of HDAE5000_Str_Adr_HDD_UTIL_PAGE_4
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1a)                    ; ld XWA,(XSP+0x1a)
	push xwa
	call HDAE5000_LToA
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCat
	inc 8, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2632		; low half of HDAE5000_Str_Size_HDD_UTIL_PAGE_4
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1e)                    ; ld XWA,(XSP+0x1e)
	push xwa
	call HDAE5000_LToA
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCat
	inc 8, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_GetResouceInfo)
	ld	wa, 5:i3
	call	(xhl)
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x263a		; low half of HDAE5000_Str_CMPFileInfo
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2654		; low half of HDAE5000_Str_Adr_HDD_UTIL_PAGE_5
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1a)                    ; ld XWA,(XSP+0x1a)
	push xwa
	call HDAE5000_LToA
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCat
	inc 8, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x265c		; low half of HDAE5000_Str_Size_HDD_UTIL_PAGE_5
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1e)                    ; ld XWA,(XSP+0x1e)
	push xwa
	call HDAE5000_LToA
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCat
	inc 8, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_GetResouceInfo)
	ld	wa, 6:i3
	call	(xhl)
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2664		; low half of HDAE5000_Str_TMFileInfo
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x267c		; low half of HDAE5000_Str_Adr_HDD_UTIL_PAGE_6
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1a)                    ; ld XWA,(XSP+0x1a)
	push xwa
	call HDAE5000_LToA
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCat
	inc 8, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2684		; low half of HDAE5000_Str_Size_HDD_UTIL_PAGE_6
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1e)                    ; ld XWA,(XSP+0x1e)
	push xwa
	call HDAE5000_LToA
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCat
	inc 8, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_GetResouceInfo)
	ld	wa, 7:i3
	call	(xhl)
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x268c		; low half of HDAE5000_Str_MSPFileInfo
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x26a6		; low half of HDAE5000_Str_Adr_HDD_UTIL_PAGE_7
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1a)                    ; ld XWA,(XSP+0x1a)
	push xwa
	call HDAE5000_LToA
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCat
	inc 8, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x26ae		; low half of HDAE5000_Str_Size_HDD_UTIL_PAGE_7
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1e)                    ; ld XWA,(XSP+0x1e)
	push xwa
	call HDAE5000_LToA
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCat
	inc 8, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_GetResouceInfo)
	ldw	wa, 0x0008
	call	(xhl)
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x26b6		; low half of HDAE5000_Str_RCMFileInfo
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x26d0		; low half of HDAE5000_Str_Adr_HDD_UTIL_PAGE_8
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1a)                    ; ld XWA,(XSP+0x1a)
	push xwa
	call HDAE5000_LToA
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCat
	inc 8, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x26d8		; low half of HDAE5000_Str_Size_HDD_UTIL_PAGE_8
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1e)                    ; ld XWA,(XSP+0x1e)
	push xwa
	call HDAE5000_LToA
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCat
	inc 8, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld_sril	xhl, (xwa + HamaFn_GetResouceInfo)
	ldw	wa, 0x0009
	call	(xhl)
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x26e0		; low half of HDAE5000_Str_MDFileInfo
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x26f8		; low half of HDAE5000_Str_Adr_HDD_UTIL_PAGE_9
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1a)                    ; ld XWA,(XSP+0x1a)
	push xwa
	call HDAE5000_LToA
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCat
	inc 8, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2700		; low half of HDAE5000_Str_Size_HDD_UTIL_PAGE_9
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_StrCpy
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1e)                    ; ld XWA,(XSP+0x1e)
	push xwa
	call HDAE5000_LToA
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCat
	inc 8, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	HDAE5000_HardTest_Print
.LHRW_4d61:
	ld xwa, (xsp + 0x70)                    ; ld XWA,(XSP+0x70)
	ld	xbc, xiz
	ld xde, (xsp + 0x6c)                    ; ld XDE,(XSP+0x6c)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xix, (xhl + RootFn_InheritedProc)
	call	(xix)
.LHRW_4d7a:
	pop xiz                                 ; pop XIZ
	lda	xsp, (xsp+112)
	ret

HDAE5000_PPORT_Svc26_ShowStatus:
	; PC-link service 26: HDAE5000_PPORT_ServiceTable[26] (argument XBC =
	; string).  Copies at most 25 characters (HDAE5000_StrLen, clamp 0x19,
	; HDAE5000_StrNCpy) to RAM 0x22ABCB and makes two host calls through
	; workspace[0x0E0A]+0x0124 addressed to 0x007F0068 = object set 0x7F
	; (this ROM's UI objects), object 0x68 = 104, whose resource name in
	; HDAE5000_UiObjectName_PtrTable is "PP_STATUS".  The PC-link loop uses
	; it for its status and error strings (service 0x1A = 26).
	push xiz
	ld	xiz, xwa
	ld	xwa, xiz
	push xwa
	call HDAE5000_StrLen
	inc 4, xsp                              ; inc 4,XSP
	cp	hl, 0x0019
	jr ule, .LHRW_4d94                     ; [63 03] jr ULE,0x284d94
	ldw	hl, 0x0019
.LHRW_4d94:
	pushw hl                                ; push HL
	ld	xwa, xiz
	push xwa
	lda xwa, (0x22abcb:24)
	push xwa
	call HDAE5000_StrNCpy
	lda	xsp, (xsp+10)
	lda xwa, (0x22abc4:24)
	ld	xde, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_ApPostEvent)
	ld	xwa, HDAE5000_OBJ_PP_STATUS
	ld	xbc, EVT_HDAE_SET_STR_ADR
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_ApPostEvent)
	ld	xwa, HDAE5000_OBJ_PP_STATUS
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0xffffffff
	call	(xhl)
	pop xiz                                 ; pop XIZ
	ret


HDAE5000_PcLink_ShowStatus:	; 0x284DE9 (355 bytes)
	; Part 1: Display error message (0x284DE9)
	; XWA = string address. Validates length, copies to buffer, displays.
	; (= the PC-link page status line: up to 25 characters into 0x22ABCB,
	; shown in object 0x7F0068, "PP_STATUS" in HDAE5000_UiObjectName_PtrTable.)
	push xiz
	ld xiz, xwa			; save string address
	ld xwa, xiz
	push xwa
	call HDAE5000_StrLen
	inc 4, xsp			; cleanup arg
	cp hl, 0x0019			; cap length at 25
	jr ule, .Lhec_len_ok
	ldw hl, 0x0019
.Lhec_len_ok:
	pushw hl			; push length
	ld xwa, xiz
	push xwa			; push source
	lda xwa, (0x22abcb:24); 0x22ABCB — dest buffer
	push xwa
	call HDAE5000_StrNCpy
	lda xsp, (xsp + 10)		; cleanup 10 bytes of args
	; Display error string
	lda xwa, (0x22abc4:24); 0x22ABC4 — display buffer
	ld xde, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); (0x23A1A2)
	ld xwa, (xwa + WS_RootFnTable)             ; (XWA+0x0E0A)
	ld_sril xhl, (xwa + RootFn_SendEvent)             ; (XWA+0x0100) — display handler
	ld xwa, HDAE5000_OBJ_PP_STATUS		; display params
	ld xbc, EVT_HDAE_SET_STR_ADR		; color/position
	call (xhl)
	; Clear display line
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld_sril xhl, (xwa + RootFn_SendEvent)
	ld xwa, HDAE5000_OBJ_PP_STATUS
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xFFFFFFFF
	call (xhl)
	pop xiz
	ret
	; Part 2: Error handler dispatcher (0x284E53)
	; XWA = original params, XBC = error code, XDE = extra data

HDAE5000_PC_DATA_LINK_PAGE:
	; registered as "PC_DATA_LINK_PAGE" in HDAE5000_ObjHandler_Table
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde		; save extra data
	ld xiz, xbc			; XIZ = error code
	ld (xsp + 8), xwa		; save original params
	; Dispatch on error code
	ld xwa, xiz
	cp xwa, EVT_SW_IN		; error 7 (command failed)?
	jr z, .Lhd_err7
	cp xwa, EVT_DRAW		; error 13 (retry)?
	jr z, .Lhd_err13
	cp xwa, EVT_ARE_YOU_CLASS_PROC		; error 0x85 (fatal)?
	jrl nz, .Lhd_cleanup
	ld xhl, 1:i3			; return 1 (fatal)
	jrl .Lhd_exit
.Lhd_err13:
	; Error 13: retry — call callback, copy buffer, redisplay
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xhl, (xhl + WS_RootFnTable)             ; (XHL+0x0E0A)
	ld_sril xhl, (xhl + RootFn_InheritedProc)             ; (XHL+0x00DC) — callback
	call (xhl)
	lda xwa, (HDAE5000_Str_PCLK:24); 0x2E2708 — status buffer
	ld xbc, xwa
	ld xwa, (xsp + 8)
	ld xde, xbc
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_RootFnTable)             ; (XBC+0x0E0A)
	ld_sril xhl, (xbc + RootFn_SendEvent)             ; (XBC+0x0100) — display handler
	ld xbc, EVT_PARA_DRAW
	call (xhl)
	ld xhl, 0:i3			; return 0 (retry ok)
	jrl .Lhd_exit
.Lhd_err7:
	; Error 7: command failed — check sub-code
	ld xde, (xsp + 4)
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld_sril xix, (xwa + RootFn_SendEvent)             ; XIX = display handler
	ld xwa, 0x02600024
	ld xbc, EVT_MAKE_EDIT_SW_ID
	call (xix)
	cp xhl, 0x00000007		; sub-code 7?
	jr z, .Lhd_err7_display
	cp xhl, 0x00000006		; sub-code 6?
	jr z, .Lhd_err7_display
	cp xhl, 0x00000001		; sub-code 1?
	jr z, .Lhd_err7_minor
	or xhl, xhl			; sub-code 0?
	jr nz, .Lhd_cleanup
.Lhd_err7_minor:
	lda xwa, (HDAE5000_Str_PORTISACTIVE:24); 0x2E270E — error string
	calr HDAE5000_PcLink_ShowStatus	; recursive: display error
	call HDAE5000_PPORT_StartLink
	jr .Lhd_cleanup
.Lhd_err7_display:
	call HDAE5000_PPORT_Reset
	lda xwa, (HDAE5000_Str_Blank14:24); 0x2E271E — error string
	calr HDAE5000_PcLink_ShowStatus	; recursive: display error
	; Reinit display handler
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_PostEvent)             ; (XWA+0x0104) — init handler
	ld xwa, HDAE5000_OBJ_SETUPS_TOOLS
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call (xhl)
.Lhd_cleanup:
	; Final cleanup: call error callback
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xhl, (xhl + WS_RootFnTable)
	ld_sril xix, (xhl + RootFn_InheritedProc)             ; XIX = callback
	call (xix)
.Lhd_exit:
	pop xiz
	inc 8, xsp
	ret

HDAE5000_SeparateOutput_SendPartMsg:	; 0x284F4C (138 bytes)
	; Set up two parameter blocks on stack from template data, then call
	; workspace handler +0x0114 twice. Validates A < 16, L <= 1, E <= 2.
	; Input: A = register index, L = bank, E = mode
	; (The two 4-byte templates are B0 00 9B 00 / B0 00 9D 00 (0x2E272E /
	; 0x2E2732); A = part - 1 goes to byte 1 of both, L selects 0x01/0x20 for
	; byte 3 of the first, E is byte 3 of the second; each block goes to the
	; main CPU with WA = 0, BC = 4.  Only caller: HDAE5000_SeparateOutput_Apply.
	; What the main CPU does with them is not established here.)
	dec 8, xsp			; allocate 8 bytes on stack
	ld l, c				; save C in L
	ld xiy, HDAE5000_SeparateOutput_SendPartMsg_Data		; source template address (first block)
	lda xix, (xsp + 4)		; XIX = destination: stack+4
	ldiw				; copy word (XIY→XIX, both advance)
	ldiw				; copy second word
	ld xiy, HDAE5000_SeparateOutput_SendPartMsg_Data_2		; source template address (second block)
	ld xix, xsp			; XIX = destination: stack base
	ldiw				; copy word
	ldiw				; copy second word
	; --- Parameter validation ---
	cp a, 0x10			; A must be < 16
	jr nc, .Lwr_exit		; if A >= 16, bail out
	cp l, 1:i3			; L must be <= 1
	jr ugt, .Lwr_exit		; if L > 1, bail out
	cp e, 2:i3			; E must be <= 2
	jr ugt, .Lwr_exit		; if E > 2, bail out
	; --- Fill parameter blocks ---
	ld (xsp + 5), a			; store register index at offset 5
	ld (xsp + 1), a			; store register index at offset 1
	cp l, 0:i3			; check bank
	jr nz, .Lwr_bank1
	ld (xsp + 7), 0x01		; bank 0: store 0x01 at offset 7
	jr t, .Lwr_mode
.Lwr_bank1:
	ld (xsp + 7), 0x20		; bank 1: store 0x20 at offset 7
.Lwr_mode:
	cp e, 0:i3			; check mode
	jr nz, .Lwr_mode1
	ld (xsp + 3), 0x00		; mode 0: store 0x00 at offset 3
	jr t, .Lwr_call
.Lwr_mode1:
	cp e, 1:i3			; mode 1?
	jr nz, .Lwr_mode2
	ld (xsp + 3), 0x01		; mode 1: store 0x01 at offset 3
	jr t, .Lwr_call
.Lwr_mode2:
	ld (xsp + 3), 0x02		; mode 2: store 0x02 at offset 3
.Lwr_call:
	; --- First workspace call (stack+4 block) ---
	lda xwa, (xsp + 4)		; XWA = pointer to first param block
	ld xde, xwa			; XDE = param block ptr
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2) — workspace ptr
	ld xwa, (xwa + WS_HamaFnTable)             ; ld XWA, (XWA + 0x0E88)
	ld xhl, (xwa + HamaFn_sendCOMM)             ; ld XHL, (XWA + 0x0114)
	ld wa, 0:i3			; WA = 0
	ld bc, 4:i3			; BC = 4 (param count)
	call (xhl)			; call handler
	; --- Second workspace call (stack base block) ---
	lda xwa, (xsp)			; XWA = pointer to second param block
	ld xde, xwa			; XDE = param block ptr
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); ld XWA, (0x23A1A2) — workspace ptr
	ld xwa, (xwa + WS_HamaFnTable)             ; ld XWA, (XWA + 0x0E88)
	ld xhl, (xwa + HamaFn_sendCOMM)             ; ld XHL, (XWA + 0x0114)
	ld wa, 0:i3			; WA = 0
	ld bc, 4:i3			; BC = 4
	call (xhl)			; call handler
.Lwr_exit:
	inc 8, xsp			; deallocate 8 bytes
	ret

HDAE5000_SeparateOutput_Apply:	; 0x284FD6 (782 bytes)
	; Apply the SEPARATE OUTPUT setting: mode byte 0x22B2F4 (shown by
	; SeparateOutputModeCheck through the name pointers at 0x2E2736: "OFF",
	; "DRUMS L/R", "BASS+DRUMS MIX", "BASS/DRUMS MONO"), the drum part
	; 0x23A0A0 and the bass part 0x23A09E (SeparateDrumPartCheck /
	; SeparateBassPartCheck).  First reports the mode to the main CPU
	; (workspace 0x0E88 +0x84), undoes the previous parts 0x23A0A2/0x23A0A4
	; and sends the new ones with HDAE5000_SeparateOutput_SendPartMsg.
	; (Was "check HD status flags ... disk state byte": no disk involved.)
	ld a, (HDAE5000_RAM_SeparateOutputMode:24); ld A, (0x22B2F4)
	extz wa
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24); ld XBC, (0x23A1A2)
	ld xbc, (xbc + WS_HamaFnTable)             ; ld XBC, (XBC + 0x0E88)
	ld_sril xhl, (xbc + HamaFn_SetSepaOutMode)             ; ld XHL, (XBC + 0x0084)
	call (xhl)			; callback
	cp (HDAE5000_RAM_SeparateDrumPartSent:24), 0x00; cp (0x23A0A2), 0
	jr z, .LHD_SC__skip_a2
	ld a, (HDAE5000_RAM_SeparateDrumPartSent:24); ld A, (0x23A0A2)
	dec 1, a
	extz wa
	ld bc, 0:i3
	ld de, 0:i3
	calr HDAE5000_SeparateOutput_SendPartMsg
	ld (HDAE5000_RAM_SeparateDrumPartSent:24), 0x00; (0x23A0A2) = 0
.LHD_SC__skip_a2:
	cp (HDAE5000_RAM_SeparateBassPartSent:24), 0x00; cp (0x23A0A4), 0
	jr z, .LHD_SC__dispatch
	ld a, (HDAE5000_RAM_SeparateBassPartSent:24); ld A, (0x23A0A4)
	dec 1, a
	extz wa
	ld bc, 0:i3
	ld de, 0:i3
	calr HDAE5000_SeparateOutput_SendPartMsg
	ld (HDAE5000_RAM_SeparateBassPartSent:24), 0x00; (0x23A0A4) = 0
.LHD_SC__dispatch:
	ld a, (HDAE5000_RAM_SeparateOutputMode:24); re-read state byte
	cp a, 3:i3
	jr z, .LHD_SC__state3
	cp a, 2:i3
	jr z, .LHD_SC__state2
	cp a, 1:i3
	jr z, .LHD_SC__state1
	cp a, 0:i3
	ret z
	ret
.LHD_SC__state1:			; state=1: process A0A0, copy to A0A2
	cp (HDAE5000_RAM_SeparateDrumPart:24), 0x00
	ret z
	ld a, (HDAE5000_RAM_SeparateDrumPart:24)
	dec 1, a
	extz wa
	ld bc, 1:i3
	ld de, 0:i3
	calr HDAE5000_SeparateOutput_SendPartMsg
	ld a, (HDAE5000_RAM_SeparateDrumPart:24)
	ld (HDAE5000_RAM_SeparateDrumPartSent:24), a; (0x23A0A2) = A
	ret
.LHD_SC__state2:			; state=2: process A0A0+A09E
	cp (HDAE5000_RAM_SeparateDrumPart:24), 0x00
	jr z, .LHD_SC__s2_check_9e
	ld a, (HDAE5000_RAM_SeparateDrumPart:24)
	dec 1, a
	extz wa
	ld bc, 1:i3
	ld de, 0:i3
	calr HDAE5000_SeparateOutput_SendPartMsg
	ld a, (HDAE5000_RAM_SeparateDrumPart:24)
	ld (HDAE5000_RAM_SeparateDrumPartSent:24), a
.LHD_SC__s2_check_9e:
	cp (HDAE5000_RAM_SeparateBassPart:24), 0x00
	ret z
	ld a, (HDAE5000_RAM_SeparateBassPart:24)
	dec 1, a
	extz wa
	ld bc, 1:i3
	ld de, 0:i3
	calr HDAE5000_SeparateOutput_SendPartMsg
	ld a, (HDAE5000_RAM_SeparateBassPart:24)
	ld (HDAE5000_RAM_SeparateBassPartSent:24), a
	ret
.LHD_SC__state3:			; state=3: process A0A0 (DE=2) + A09E (DE=1)
	cp (HDAE5000_RAM_SeparateDrumPart:24), 0x00
	jr z, .LHD_SC__s3_check_9e
	ld a, (HDAE5000_RAM_SeparateDrumPart:24)
	dec 1, a
	extz wa
	ld bc, 1:i3
	ld de, 2:i3
	calr HDAE5000_SeparateOutput_SendPartMsg
	ld a, (HDAE5000_RAM_SeparateDrumPart:24)
	ld (HDAE5000_RAM_SeparateDrumPartSent:24), a
.LHD_SC__s3_check_9e:
	cp (HDAE5000_RAM_SeparateBassPart:24), 0x00
	ret z
	ld a, (HDAE5000_RAM_SeparateBassPart:24)
	dec 1, a
	extz wa
	ld bc, 1:i3
	ld de, 1:i3
	calr HDAE5000_SeparateOutput_SendPartMsg
	ld a, (HDAE5000_RAM_SeparateBassPart:24)
	ld (HDAE5000_RAM_SeparateBassPartSent:24), a
	ret
	;
	; Part 2: Event handler 1 (0x2850ED) — jump table dispatch
HDAE5000_SeparateOutputModeCheck:
	; registered as "SeparateOutputModeCheck" in HDAE5000_ObjHandler_Table
	push xiz
	ld xiz, xwa			; save context in XIZ
	ld xwa, xbc			; XWA = event code
	cp xwa, EVT_RAM_DATA_REQ		; special event?
	jr z, .LHD_SC__h1_event82
	sub xwa, EVT_GET_LARGE_STEP		; normalize to 0-based index
	cp xwa, 0x00000000
	jrl lt, .LHD_SC__h1_default
	cp xwa, 0x00000009
	jr gt, .LHD_SC__h1_default
	add xwa, xwa			; index * 2 (16-bit offsets)
	add xwa, HDAE5000_SeparateOutputModeCheck_CaseTable		; + jump table base
	ld wa, (xwa)			; WA = offset
	lda xix, (.LHD_SC__h1_case9:24); XIX = dispatch base (h1_case9)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp (XIX + WA)
.LHD_SC__h1_case9:			; case 9 (offset 0x0000): PPI block copy
	ld xwa, (xde + 0x0e)
	sll xwa, 2
	ld xbc, HDAE5000_TextPtrs_OFF_DRUMSLR_BASSDRUMSMIX_BASSDRUMSMONO		; secondary data table
	add xbc, xwa
	ld xwa, (xbc)			; load address from table
	push xwa
	pushw 0x002e		; push 0x002E -- high half of HDAE5000_Fmt_s_SeparateOutputModeCheck
	pushw 0x2786		; low half of HDAE5000_Fmt_s_SeparateOutputModeCheck
	ld xwa, (xde + 0x12)
	push xwa
	call HDAE5000_SPrintf
	lda xsp, (xsp + 0x0c)		; deallocate 12 bytes
	ld xhl, xiz			; return saved context
	jr t, .LHD_SC__h1_exit
.LHD_SC__h1_case0:			; case 0 (offset 0x0025)
	ld xhl, 1:i3
	jr t, .LHD_SC__h1_exit
.LHD_SC__h1_case1:			; case 1 (offset 0x0029)
	ld xhl, 1:i3
	jr t, .LHD_SC__h1_exit
.LHD_SC__h1_case5:			; case 5 (offset 0x002D)
	ld xhl, 3:i3
	jr t, .LHD_SC__h1_exit
.LHD_SC__h1_case6:			; case 6 (offset 0x0031)
	ld xhl, 0:i3
	jr t, .LHD_SC__h1_exit
.LHD_SC__h1_case7:			; case 7 (offset 0x0035)
	lda xhl, (HDAE5000_RAM_SeparateOutputMode:24)
	jr t, .LHD_SC__h1_exit
.LHD_SC__h1_case8:			; case 8 (offset 0x003C)
	ld xhl, 1:i3
	jr t, .LHD_SC__h1_exit
.LHD_SC__h1_event82:			; event 0x01E00082: callback chain
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)             ; ld XWA, (XWA + 0x0E0A)
	ld xhl, (xwa + RootFn_SleepMainTask)             ; ld XHL, (XWA + 0x0538)
	call (xhl)
	calr HDAE5000_SeparateOutput_Apply	; recursive call
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_WakeUpMainTask)             ; ld XHL, (XWA + 0x053C)
	call (xhl)
	ld xhl, 0:i3
	jr t, .LHD_SC__h1_exit
.LHD_SC__h1_default:			; out-of-range
	ld xhl, 0:i3
.LHD_SC__h1_exit:
	pop xiz
	ret
	;
	; Part 3: Event handler 2 (0x285192) — same structure, different data
HDAE5000_SeparateDrumPartCheck:
	; registered as "SeparateDrumPartCheck" in HDAE5000_ObjHandler_Table
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xwa, EVT_RAM_DATA_REQ
	jr z, .LHD_SC__h2_event82
	sub xwa, EVT_GET_LARGE_STEP
	cp xwa, 0x00000000
	jrl lt, .LHD_SC__h2_default
	cp xwa, 0x00000009
	jrl gt, .LHD_SC__h2_default
	add xwa, xwa
	add xwa, HDAE5000_SeparateDrumPartCheck_CaseTable		; jump table 2
	ld wa, (xwa)
	lda xix, (.LHD_SC__h2_case9:24); XIX = dispatch base (h2_case9)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp (XIX + WA)
.LHD_SC__h2_case9:			; case 9: PPI block copy
	ld xwa, (xde + 0x0e)
	sll xwa, 2
	ld xbc, HDAE5000_TextPtrs_NONE_to_16		; secondary data table 2
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	pushw 0x002e		; push 0x002E -- high half of HDAE5000_Fmt_s_SeparateDrumPartCheck
	pushw 0x2848		; low half of HDAE5000_Fmt_s_SeparateDrumPartCheck
	ld xwa, (xde + 0x12)
	push xwa
	call HDAE5000_SPrintf
	lda xsp, (xsp + 0x0c)
	ld xhl, xiz
	jr t, .LHD_SC__h2_exit
.LHD_SC__h2_case0:
	ld xhl, 1:i3
	jr t, .LHD_SC__h2_exit
.LHD_SC__h2_case1:
	ld xhl, 1:i3
	jr t, .LHD_SC__h2_exit
.LHD_SC__h2_case5:			; case 5: XHL = 0x10
	ld xhl, 0x00000010
	jr t, .LHD_SC__h2_exit
.LHD_SC__h2_case6:
	ld xhl, 0:i3
	jr t, .LHD_SC__h2_exit
.LHD_SC__h2_case7:			; case 7: lda XHL, 0x23A0A0
	lda xhl, (HDAE5000_RAM_SeparateDrumPart:24)
	jr t, .LHD_SC__h2_exit
.LHD_SC__h2_case8:
	ld xhl, 1:i3
	jr t, .LHD_SC__h2_exit
.LHD_SC__h2_event82:
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_SleepMainTask)
	call (xhl)
	calr HDAE5000_SeparateOutput_Apply
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_WakeUpMainTask)
	call (xhl)
	ld xhl, 0:i3
	jr t, .LHD_SC__h2_exit
.LHD_SC__h2_default:
	ld xhl, 0:i3
.LHD_SC__h2_exit:
	pop xiz
	ret
	;
	; Part 4: Event handler 3 (0x28523B) — same structure, different data
HDAE5000_SeparateBassPartCheck:
	; registered as "SeparateBassPartCheck" in HDAE5000_ObjHandler_Table
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xwa, EVT_RAM_DATA_REQ
	jr z, .LHD_SC__h3_event82
	sub xwa, EVT_GET_LARGE_STEP
	cp xwa, 0x00000000
	jrl lt, .LHD_SC__h3_default
	cp xwa, 0x00000009
	jrl gt, .LHD_SC__h3_default
	add xwa, xwa
	add xwa, HDAE5000_SeparateBassPartCheck_CaseTable		; jump table 3
	ld wa, (xwa)
	lda xix, (.LHD_SC__h3_case9:24); XIX = dispatch base (h3_case9)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp (XIX + WA)
.LHD_SC__h3_case9:			; case 9: PPI block copy
	ld xwa, (xde + 0x0e)
	sll xwa, 2
	ld xbc, HDAE5000_TextPtrs_NONE_to_16_2		; secondary data table 3
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	pushw 0x002e		; push 0x002E -- high half of HDAE5000_Fmt_s_SeparateBassPartCheck
	pushw 0x290a		; push 0x290A		; low half of HDAE5000_Fmt_s_SeparateBassPartCheck
	ld xwa, (xde + 0x12)
	push xwa
	call HDAE5000_SPrintf
	lda xsp, (xsp + 0x0c)
	ld xhl, xiz
	jr t, .LHD_SC__h3_exit
.LHD_SC__h3_case0:
	ld xhl, 1:i3
	jr t, .LHD_SC__h3_exit
.LHD_SC__h3_case1:
	ld xhl, 1:i3
	jr t, .LHD_SC__h3_exit
.LHD_SC__h3_case5:			; case 5: XHL = 0x10
	ld xhl, 0x00000010
	jr t, .LHD_SC__h3_exit
.LHD_SC__h3_case6:
	ld xhl, 0:i3
	jr t, .LHD_SC__h3_exit
.LHD_SC__h3_case7:			; case 7: lda XHL, 0x23A09E
	lda xhl, (HDAE5000_RAM_SeparateBassPart:24)
	jr t, .LHD_SC__h3_exit
.LHD_SC__h3_case8:
	ld xhl, 1:i3
	jr t, .LHD_SC__h3_exit
.LHD_SC__h3_event82:
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_SleepMainTask)
	call (xhl)
	calr HDAE5000_SeparateOutput_Apply
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_WakeUpMainTask)
	call (xhl)
	ld xhl, 0:i3
	jr t, .LHD_SC__h3_exit
.LHD_SC__h3_default:
	ld xhl, 0:i3
.LHD_SC__h3_exit:
	pop xiz
	ret

HDAE5000_TypeSel_Init:	; 0x2852E4 (92 bytes)
	; Copy 12-byte record from (XDE) to (XWA) via ldirw, then set flag bytes
	; (The record is a part selection: +0 u16 mask, +2..+10 one flag per
	; part LSW..TLX (0 "---", 1 "NO ", 2 "YES" -- the pointer table at
	; 0x2E2922); the flags of the parts in BC get the stacked value.  Records:
	; the save options 0x22AA4C, the delete options 0x22ABE6.)
	; Input: XWA = dest, XDE = src, BC = flags (HL), E from stack = flag value
	; Returns with retd (deallocates 2 bytes from stack)
	ld xix, xde			; save source
	ld hl, bc			; HL = flags
	ld e, (xsp + 4)			; E = flag byte from stack
	ld xiy, xix			; XIY = source
	ld xix, xwa			; XIX = dest (for ldirw)
	ld bc, 6:i3			; count = 6 words (12 bytes)
	mriw2 0x95, 0x11		; ldirw — copy 6 words
	ld (xwa), hl			; store flags at dest[0..1]
	bit 0, hl			; bit 0 set?
	jr z, .LHD_Data_Copy__bit1
	ld (xwa + 2), e			; dest[2] = flag value
.LHD_Data_Copy__bit1:
	bit 1, hl
	jr z, .LHD_Data_Copy__bit2
	ld (xwa + 3), e
.LHD_Data_Copy__bit2:
	bit 2, hl
	jr z, .LHD_Data_Copy__bit3
	ld (xwa + 4), e
.LHD_Data_Copy__bit3:
	bit 3, hl
	jr z, .LHD_Data_Copy__bit4
	ld (xwa + 5), e
.LHD_Data_Copy__bit4:
	bit 4, hl
	jr z, .LHD_Data_Copy__bit5
	ld (xwa + 6), e
.LHD_Data_Copy__bit5:
	bit 5, hl
	jr z, .LHD_Data_Copy__bit6
	ld (xwa + 7), e
.LHD_Data_Copy__bit6:
	bit 6, hl
	jr z, .LHD_Data_Copy__bit7
	ld (xwa + 8), e
.LHD_Data_Copy__bit7:
	bit 7, hl
	jr z, .LHD_Data_Copy__bit8
	ld (xwa + 9), e
.LHD_Data_Copy__bit8:
	bit 8, hl
	jr z, .LHD_Data_Copy__done
	ld (xwa + 10), e
.LHD_Data_Copy__done:
	retd 0x0002

HDAE5000_TypeSel_BuildMask:	; 0x285340 (220 bytes)
	; Mask word (XWA+0) = bit k for every part k whose flag byte (XWA+2+k)
	; is 2 ("YES"), in a part-selection record (see HDAE5000_TypeSel_Init).
	; (Was "partition status array": the bytes are per-part flags.)
	ldw (xwa + 0), 0x0000		; clear output flags
	cp (xwa + 2), 0x02
	jr nz, .Lhbi_skip0
	ldw (xwa + 0), 0x0001		; set bit 0
.Lhbi_skip0:
	cp (xwa + 3), 0x02
	jr nz, .Lhbi_skip1
	ormi16 (xwa + 0), 0x0002	; set bit 1
.Lhbi_skip1:
	cp (xwa + 4), 0x02
	jr nz, .Lhbi_skip2
	ormi16 (xwa + 0), 0x0004	; set bit 2
.Lhbi_skip2:
	cp (xwa + 5), 0x02
	jr nz, .Lhbi_skip3
	ormi16 (xwa + 0), 0x0008	; set bit 3
.Lhbi_skip3:
	cp (xwa + 6), 0x02
	jr nz, .Lhbi_skip4
	ormi16 (xwa + 0), 0x0010	; set bit 4
.Lhbi_skip4:
	cp (xwa + 7), 0x02
	jr nz, .Lhbi_skip5
	ormi16 (xwa + 0), 0x0020	; set bit 5
.Lhbi_skip5:
	cp (xwa + 8), 0x02
	jr nz, .Lhbi_skip6
	ormi16 (xwa + 0), 0x0040	; set bit 6
.Lhbi_skip6:
	cp (xwa + 9), 0x02
	jr nz, .Lhbi_skip7
	ormi16 (xwa + 0), 0x0080	; set bit 7
.Lhbi_skip7:
	cp (xwa + 10), 0x02
	ret nz
	ormi16 (xwa + 0), 0x0100	; set bit 8
	ret
	; Sub-routine 2: Command dispatcher with computed jump table
	; Input: XWA = context pointer (saved as XIZ), XBC = command ID
	; Returns XHL = result

HDAE5000_SaveOptNameCheck:
	; registered as "SaveOptNameCheck" in HDAE5000_ObjHandler_Table
	push xiz
	ld xiz, xwa			; save context
	ld xwa, xbc			; command → XWA
	cp xwa, EVT_RAM_DATA_REQ		; special command?
	jr z, .Lhbi_special
	sub xwa, EVT_GET_LARGE_STEP		; normalize to index 0-9
	cp xwa, 0x00000000
	jr lt, .Lhbi_default
	cp xwa, 0x00000009
	jr gt, .Lhbi_default
	add xwa, xwa			; index * 2 (table has 16-bit entries)
	add xwa, HDAE5000_SaveOptNameCheck_CaseTable		; jump table base
	ld wa, (xwa + 0)		; load offset from table
	lda xix, (.Lhbi_case0:24); base of case handlers (0x2853D6)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T, XIX+WA
.Lhbi_case0:
	; Case 0: PPI block copy from device
	pushw 0x0023
	pushw 0xA04E
	pushw 0x002E
	pushw 0x293A		; low half of HDAE5000_Fmt_s_SaveOptNameCheck
	ld xwa, (xde + 18)
	push xwa
	call HDAE5000_SPrintf
	lda xsp, (xsp + 12)		; pop args
	ld xhl, xiz			; return context ptr
	jr t, .Lhbi_exit
.Lhbi_case1:
	ld xhl, 1:i3
	jr t, .Lhbi_exit
.Lhbi_case2:
	ld xhl, 1:i3
	jr t, .Lhbi_exit
.Lhbi_case3:
	ld xhl, 0:i3
	jr t, .Lhbi_exit
.Lhbi_case4:
	ld xhl, 0:i3
	jr t, .Lhbi_exit
.Lhbi_case5:
	lda xhl, (0x22aa57:24); 0x22AA57
	jr t, .Lhbi_exit
.Lhbi_case6:
	ld xhl, 1:i3
	jr t, .Lhbi_exit
.Lhbi_special:
	; Command 0x01E00082: init buffer then return 0
	lda xwa, (HDAE5000_RAM_SaveOptions:24); 0x22AA4C
	calr HDAE5000_TypeSel_BuildMask
	ld xhl, 0:i3
	jr t, .Lhbi_exit
.Lhbi_default:
	ld xhl, 0:i3
.Lhbi_exit:
	pop xiz
	ret

; --- HD Configuration Manager and CHS Geometry ---
HDAE5000_TypeSel_ShowSaveFlags:	; 0x28541C (3728 bytes)
	; Show the nine save-option flags (0x22AA4E..56) as "---"/"NO "/"YES"
	; (pointer table 0x2E2922) in the objects "RAM_EDIT_LSW".."RAM_EDIT_TLX"
	; (0x7F0196.., names from HDAE5000_UiObjectName_PtrTable), event
	; 0x01C0000F.  (Was HD_Config_Manager.)
; LHCM: 0x28541C (3728 bytes)
	; ^ conversion-region size (local-label prefix .LHCM_), not a routine size.

	ld	a, (0x22AA4E:24)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda xbc, (HDAE5000_TextPtrs_Chr2D2D2D_NO_YES:24)
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_PostEvent)
	ld	xwa, HDAE5000_OBJ_RAM_EDIT_LSW
	ld	xbc, EVT_PARA_DRAW
	call	(xhl)
	ld	a, (0x22AA4F:24)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda xbc, (HDAE5000_TextPtrs_Chr2D2D2D_NO_YES:24)
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_PostEvent)
	ld	xwa, HDAE5000_OBJ_RAM_EDIT_PMT
	ld	xbc, EVT_PARA_DRAW
	call	(xhl)
	ld	a, (0x22AA50:24)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda xbc, (HDAE5000_TextPtrs_Chr2D2D2D_NO_YES:24)
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_PostEvent)
	ld	xwa, HDAE5000_OBJ_RAM_EDIT_SQT
	ld	xbc, EVT_PARA_DRAW
	call	(xhl)
	ld	a, (0x22AA51:24)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda xbc, (HDAE5000_TextPtrs_Chr2D2D2D_NO_YES:24)
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_PostEvent)
	ld	xwa, HDAE5000_OBJ_RAM_EDIT_CMP
	ld	xbc, EVT_PARA_DRAW
	call	(xhl)
	ld	a, (0x22AA52:24)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda xbc, (HDAE5000_TextPtrs_Chr2D2D2D_NO_YES:24)
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_PostEvent)
	ld	xwa, HDAE5000_OBJ_RAM_EDIT_TM
	ld	xbc, EVT_PARA_DRAW
	call	(xhl)
	ld	a, (0x22AA53:24)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda xbc, (HDAE5000_TextPtrs_Chr2D2D2D_NO_YES:24)
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_PostEvent)
	ld	xwa, HDAE5000_OBJ_RAM_EDIT_MSP
	ld	xbc, EVT_PARA_DRAW
	call	(xhl)
	ld	a, (0x22AA54:24)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda xbc, (HDAE5000_TextPtrs_Chr2D2D2D_NO_YES:24)
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_PostEvent)
	ld	xwa, HDAE5000_OBJ_RAM_EDIT_RCM
	ld	xbc, EVT_PARA_DRAW
	call	(xhl)
	ld	a, (0x22AA55:24)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda xbc, (HDAE5000_TextPtrs_Chr2D2D2D_NO_YES:24)
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_PostEvent)
	ld	xwa, HDAE5000_OBJ_RAM_EDIT_MD
	ld	xbc, EVT_PARA_DRAW
	call	(xhl)
	ld	a, (0x22AA56:24)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda xbc, (HDAE5000_TextPtrs_Chr2D2D2D_NO_YES:24)
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_PostEvent)
	ld	xwa, HDAE5000_OBJ_RAM_EDIT_TLX
	ld	xbc, EVT_PARA_DRAW
	jp	(xhl)

HDAE5000_SaveOptSwEventCatch:
	; registered as "SaveOptSwEventCatch" in HDAE5000_ObjHandler_Table
	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, EVT_SW_IN
	jr z, .LHCM_5634                       ; [66 64] jr Z,0x285634
	cp	xwa, EVT_DRAW
	jr z, .LHCM_55fb                       ; [66 23] jr Z,0x2855fb
	cp	xwa, EVT_ARE_YOU_CLASS_PROC
	jr z, .LHCM_55f6                       ; [66 16] jr Z,0x2855f6
	ld	xwa, xiz
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xix, (xhl + RootFn_InheritedProc)
	call	(xix)
	jrl t, .LHCM_577a                      ; [78 84 01] jrl T,0x28577a
.LHCM_55f6:
	ld	xhl, 1:i3
	jrl t, .LHCM_577a                      ; [78 7f 01] jrl T,0x28577a
.LHCM_55fb:
	ld	xwa, xiz
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	lda xwa, (HDAE5000_Str_SVOP:24)
	ld	xbc, xwa
	ld	xwa, xiz
	ld	xde, xbc
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, EVT_PARA_DRAW
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LHCM_577a                      ; [78 46 01] jrl T,0x28577a
.LHCM_5634:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xix, (xwa + RootFn_SendEvent)
	ld	xwa, 0x02600024
	ld	xbc, EVT_MAKE_EDIT_SW_ID
	call	(xix)
	cp	xhl, 0x0000008b
	jrl z, .LHCM_574a                      ; [76 f2 00] jrl Z,0x28574a
	cp	xhl, 0x0000000b
	jrl z, .LHCM_5733                      ; [76 d2 00] jrl Z,0x285733
	cp	xhl, 0x0000000a
	jrl z, .LHCM_571b                      ; [76 b1 00] jrl Z,0x28571b
	cp	xhl, 0x00000009
	jrl z, .LHCM_5703                      ; [76 90 00] jrl Z,0x285703
	cp	xhl, 0x00000008
	jrl nz, .LHCM_5778                     ; [7e fc 00] jrl NZ,0x285778
	lda xwa, (0x23a04e:24)
	ld	xde, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_HddNamingWindow
	ld	xbc, EVT_GET_STRING
	call	(xhl)
	cp	(HDAE5000_RAM_WriteConfirm:24), 1
	jr nz, .LHCM_56d9                      ; [6e 33] jr NZ,0x2856d9
	ld	wa, (HDAE5000_RAM_CurDir:24)
	ld	bc, (HDAE5000_RAM_CurSong:24)
	call HDAE5000_Song_IsUsed
	cp	hl, 0xffff
	jr z, .LHCM_56d9                       ; [66 1f] jr Z,0x2856d9
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_PostEvent)
	ld	xwa, HDAE5000_OBJ_ATTEN_OVER_FILE
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	call	(xhl)
	jr t, .LHCM_56fa                       ; [68 21] jr T,0x2856fa
.LHCM_56d9:
	pushw 0x0023
	pushw 0xa04e
	pushw 0x0001
	ld	xwa, HDAE5000_OBJ_SELECT_FILE
	push xwa
	ld	wa, (HDAE5000_RAM_CurDir:24)
	ld	bc, (HDAE5000_RAM_CurSong:24)
	ld	de, (HDAE5000_RAM_SaveOptions:24)
	calr	HDAE5000_SaveSongWithUi
.LHCM_56fa:
	ld	wa, 0:i3
	ld	bc, 0:i3
	calr	HDAE5000_SongScreen_Refresh
	jr t, .LHCM_5778                       ; [68 75] jr T,0x285778
.LHCM_5703:
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	pushw 0x0002
	lda xde, (HDAE5000_TypeSel_TemplateAllNo:24)
	ldw	bc, 0x003f
	calr	HDAE5000_TypeSel_Init
	calr	HDAE5000_TypeSel_ShowSaveFlags
	jr t, .LHCM_5778                       ; [68 5d] jr T,0x285778
.LHCM_571b:
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	pushw 0x0002
	lda xde, (HDAE5000_TypeSel_TemplateAllNo:24)
	ldw	bc, 0x01ff
	calr	HDAE5000_TypeSel_Init
	calr	HDAE5000_TypeSel_ShowSaveFlags
	jr t, .LHCM_5778                       ; [68 45] jr T,0x285778
.LHCM_5733:
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	pushw 0x0002
	lda xde, (HDAE5000_TypeSel_TemplateAllNo:24)
	ld	bc, 0:i3
	calr	HDAE5000_TypeSel_Init
	calr	HDAE5000_TypeSel_ShowSaveFlags
	jr t, .LHCM_5778                       ; [68 2e] jr T,0x285778
.LHCM_574a:
	ld	bc, (HDAE5000_RAM_SaveOptions:24)
	ld	wa, bc
	and	wa, 0x0100
	cp	wa, 0x0100
	jr nz, .LHCM_5761                      ; [6e 06] jr NZ,0x285761
	sub	bc, 0x0100
	jr t, .LHCM_5765                       ; [68 04] jr T,0x285765
.LHCM_5761:
	add	bc, 0x0100
.LHCM_5765:
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	pushw 0x0002
	lda xde, (HDAE5000_TypeSel_TemplateAllNo:24)
	calr	HDAE5000_TypeSel_Init
	calr	HDAE5000_TypeSel_ShowSaveFlags
.LHCM_5778:
	ld	xhl, 0:i3
.LHCM_577a:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_FileOptNameCheck:
	; registered as "FileOptNameCheck" in HDAE5000_ObjHandler_Table
	dec	4, xsp
	push xiz
	ld (xsp + 0x04), xwa                    ; ld (XSP+0x04),XWA
	ld	xwa, xbc
	cp	xwa, EVT_RAM_DATA_REQ
	jr z, .LHCM_57f8                       ; [66 6c] jr Z,0x2857f8
	sub	xwa, EVT_GET_LARGE_STEP
	cp	xwa, 0x00000000
	jr lt, HDAE5000_FileOptNameCheck_Default                      ; [61 62] jr LT,0x2857fc
	cp	xwa, 0x00000009
	jr gt, HDAE5000_FileOptNameCheck_Default                      ; [6a 5a] jr GT,0x2857fc
	add	xwa, xwa
	add	xwa, HDAE5000_FileOptNameCheck_CaseTable
	ld	wa, (xwa)
	lda xix, (HDAE5000_FileOptNameCheck_Ev01E00047:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_FileOptNameCheck_Ev01E00047:
	ld	xiz, xde
	ld	wa, (HDAE5000_RAM_CurDir:24)
	ld	bc, (HDAE5000_RAM_CurSong:24)
	call HDAE5000_SongRecord_Address
	push xhl
	pushw 0x002e
	pushw 0x2958		; low half of HDAE5000_Fmt_s_FileOptNameCheck
	ld xwa, (xiz + 0x12)                    ; ld XWA,(XIZ+0x12)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	ld xhl, (xsp + 0x04)                    ; ld XHL,(XSP+0x04)
	jr t, .LHCM_57fe                       ; [68 21] jr T,0x2857fe
HDAE5000_FileOptNameCheck_Ev01E0003E:
	ld	xhl, 1:i3
	jr t, .LHCM_57fe                       ; [68 1d] jr T,0x2857fe
HDAE5000_FileOptNameCheck_Ev01E0003F:
	ld	xhl, 1:i3
	jr t, .LHCM_57fe                       ; [68 19] jr T,0x2857fe
HDAE5000_FileOptNameCheck_Ev01E00043:
	ld	xhl, 0:i3
	jr t, .LHCM_57fe                       ; [68 15] jr T,0x2857fe
HDAE5000_FileOptNameCheck_Ev01E00044:
	ld	xhl, 0:i3
	jr t, .LHCM_57fe                       ; [68 11] jr T,0x2857fe
HDAE5000_FileOptNameCheck_Ev01E00045:
	lda xhl, (0x22aa57:24)
	jr t, .LHCM_57fe                       ; [68 0a] jr T,0x2857fe
HDAE5000_FileOptNameCheck_Ev01E00046:
	ld	xhl, 1:i3
	jr t, .LHCM_57fe                       ; [68 06] jr T,0x2857fe
.LHCM_57f8:
	ld	xhl, 0:i3
	jr t, .LHCM_57fe                       ; [68 02] jr T,0x2857fe
HDAE5000_FileOptNameCheck_Default:
	ld	xhl, 0:i3
.LHCM_57fe:
	pop xiz                                 ; pop XIZ
	inc 4, xsp                              ; inc 4,XSP
	ret

HDAE5000_SfxLswBitCheck:
	; registered as "SfxLswBitCheck" in HDAE5000_ObjHandler_Table
	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, EVT_RAM_DATA_REQ
	jrl z, .LHCM_5890                      ; [76 80 00] jrl Z,0x285890
	sub	xwa, EVT_GET_LARGE_STEP
	cp	xwa, 0x00000000
	jrl lt, HDAE5000_SfxLswBitCheck_Default                     ; [71 95 00] jrl LT,0x2858b4
	cp	xwa, 0x00000009
	jrl gt, HDAE5000_SfxLswBitCheck_Default                     ; [7a 8c 00] jrl GT,0x2858b4
	add	xwa, xwa
	add	xwa, HDAE5000_SfxLswBitCheck_CaseTable
	ld	wa, (xwa)
	lda xix, (HDAE5000_SfxLswBitCheck_Ev01E00047:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_SfxLswBitCheck_Ev01E00047:
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, HDAE5000_TextPtrs_Chr2D2D2D_NO_YES
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2970		; low half of HDAE5000_Fmt_s_SfxLswBitCheck
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_58b6                       ; [68 55] jr T,0x2858b6
HDAE5000_SfxLswBitCheck_Ev01E0003E:
	ld	xhl, 1:i3
	jr t, .LHCM_58b6                       ; [68 51] jr T,0x2858b6
HDAE5000_SfxLswBitCheck_Ev01E0003F:
	ld	xhl, 1:i3
	jr t, .LHCM_58b6                       ; [68 4d] jr T,0x2858b6
HDAE5000_SfxLswBitCheck_Ev01E00043:
	ld	xhl, 2:i3
	cp	(0x22AA4E:24), 0
	jr nz, .LHCM_5875                      ; [6e 02] jr NZ,0x285875
	ld	xhl, 0:i3
.LHCM_5875:
	jr t, .LHCM_58b6                       ; [68 3f] jr T,0x2858b6
HDAE5000_SfxLswBitCheck_Ev01E00044:
	ld	xhl, 1:i3
	cp	(0x22AA4E:24), 0
	jr nz, .LHCM_5883                      ; [6e 02] jr NZ,0x285883
	ld	xhl, 0:i3
.LHCM_5883:
	jr t, .LHCM_58b6                       ; [68 31] jr T,0x2858b6
HDAE5000_SfxLswBitCheck_Ev01E00045:
	lda xhl, (0x22aa4e:24)
	jr t, .LHCM_58b6                       ; [68 2a] jr T,0x2858b6
HDAE5000_SfxLswBitCheck_Ev01E00046:
	ld	xhl, 1:i3
	jr t, .LHCM_58b6                       ; [68 26] jr T,0x2858b6
.LHCM_5890:
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	calr	HDAE5000_TypeSel_BuildMask
	ld	bc, (HDAE5000_RAM_CurDir:24)
	ld	de, (HDAE5000_RAM_CurSong:24)
	ld	wa, (HDAE5000_RAM_SaveOptions:24)
	pushw wa                                ; push WA
	ld	xwa, HDAE5000_OBJ_HD_FILE_OPTION
	calr	HDAE5000_PartList_Build
	ld	xhl, 0:i3
	jr t, .LHCM_58b6                       ; [68 02] jr T,0x2858b6
HDAE5000_SfxLswBitCheck_Default:
	ld	xhl, 0:i3
.LHCM_58b6:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_SfxPmtBitCheck:
	; registered as "SfxPmtBitCheck" in HDAE5000_ObjHandler_Table
	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, EVT_RAM_DATA_REQ
	jrl z, .LHCM_5946                      ; [76 80 00] jrl Z,0x285946
	sub	xwa, EVT_GET_LARGE_STEP
	cp	xwa, 0x00000000
	jrl lt, HDAE5000_SfxPmtBitCheck_Default                     ; [71 95 00] jrl LT,0x28596a
	cp	xwa, 0x00000009
	jrl gt, HDAE5000_SfxPmtBitCheck_Default                     ; [7a 8c 00] jrl GT,0x28596a
	add	xwa, xwa
	add	xwa, HDAE5000_SfxPmtBitCheck_CaseTable
	ld	wa, (xwa)
	lda xix, (HDAE5000_SfxPmtBitCheck_Ev01E00047:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_SfxPmtBitCheck_Ev01E00047:
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, HDAE5000_TextPtrs_Chr2D2D2D_NO_YES
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2988		; low half of HDAE5000_Fmt_s_SfxPmtBitCheck
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_596c                       ; [68 55] jr T,0x28596c
HDAE5000_SfxPmtBitCheck_Ev01E0003E:
	ld	xhl, 1:i3
	jr t, .LHCM_596c                       ; [68 51] jr T,0x28596c
HDAE5000_SfxPmtBitCheck_Ev01E0003F:
	ld	xhl, 1:i3
	jr t, .LHCM_596c                       ; [68 4d] jr T,0x28596c
HDAE5000_SfxPmtBitCheck_Ev01E00043:
	ld	xhl, 2:i3
	cp	(0x22AA4F:24), 0
	jr nz, .LHCM_592b                      ; [6e 02] jr NZ,0x28592b
	ld	xhl, 0:i3
.LHCM_592b:
	jr t, .LHCM_596c                       ; [68 3f] jr T,0x28596c
HDAE5000_SfxPmtBitCheck_Ev01E00044:
	ld	xhl, 1:i3
	cp	(0x22AA4F:24), 0
	jr nz, .LHCM_5939                      ; [6e 02] jr NZ,0x285939
	ld	xhl, 0:i3
.LHCM_5939:
	jr t, .LHCM_596c                       ; [68 31] jr T,0x28596c
HDAE5000_SfxPmtBitCheck_Ev01E00045:
	lda xhl, (0x22aa4f:24)
	jr t, .LHCM_596c                       ; [68 2a] jr T,0x28596c
HDAE5000_SfxPmtBitCheck_Ev01E00046:
	ld	xhl, 1:i3
	jr t, .LHCM_596c                       ; [68 26] jr T,0x28596c
.LHCM_5946:
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	calr	HDAE5000_TypeSel_BuildMask
	ld	bc, (HDAE5000_RAM_CurDir:24)
	ld	de, (HDAE5000_RAM_CurSong:24)
	ld	wa, (HDAE5000_RAM_SaveOptions:24)
	pushw wa                                ; push WA
	ld	xwa, HDAE5000_OBJ_HD_FILE_OPTION
	calr	HDAE5000_PartList_Build
	ld	xhl, 0:i3
	jr t, .LHCM_596c                       ; [68 02] jr T,0x28596c
HDAE5000_SfxPmtBitCheck_Default:
	ld	xhl, 0:i3
.LHCM_596c:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_SfxSqtBitCheck:
	; registered as "SfxSqtBitCheck" in HDAE5000_ObjHandler_Table
	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, EVT_RAM_DATA_REQ
	jrl z, .LHCM_59fc                      ; [76 80 00] jrl Z,0x2859fc
	sub	xwa, EVT_GET_LARGE_STEP
	cp	xwa, 0x00000000
	jrl lt, HDAE5000_SfxSqtBitCheck_Default                     ; [71 95 00] jrl LT,0x285a20
	cp	xwa, 0x00000009
	jrl gt, HDAE5000_SfxSqtBitCheck_Default                     ; [7a 8c 00] jrl GT,0x285a20
	add	xwa, xwa
	add	xwa, HDAE5000_SfxSqtBitCheck_CaseTable
	ld	wa, (xwa)
	lda xix, (HDAE5000_SfxSqtBitCheck_Ev01E00047:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_SfxSqtBitCheck_Ev01E00047:
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, HDAE5000_TextPtrs_Chr2D2D2D_NO_YES
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x29a0		; low half of HDAE5000_Fmt_s_SfxSqtBitCheck
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_5a22                       ; [68 55] jr T,0x285a22
HDAE5000_SfxSqtBitCheck_Ev01E0003E:
	ld	xhl, 1:i3
	jr t, .LHCM_5a22                       ; [68 51] jr T,0x285a22
HDAE5000_SfxSqtBitCheck_Ev01E0003F:
	ld	xhl, 1:i3
	jr t, .LHCM_5a22                       ; [68 4d] jr T,0x285a22
HDAE5000_SfxSqtBitCheck_Ev01E00043:
	ld	xhl, 2:i3
	cp	(0x22AA50:24), 0
	jr nz, .LHCM_59e1                      ; [6e 02] jr NZ,0x2859e1
	ld	xhl, 0:i3
.LHCM_59e1:
	jr t, .LHCM_5a22                       ; [68 3f] jr T,0x285a22
HDAE5000_SfxSqtBitCheck_Ev01E00044:
	ld	xhl, 1:i3
	cp	(0x22AA50:24), 0
	jr nz, .LHCM_59ef                      ; [6e 02] jr NZ,0x2859ef
	ld	xhl, 0:i3
.LHCM_59ef:
	jr t, .LHCM_5a22                       ; [68 31] jr T,0x285a22
HDAE5000_SfxSqtBitCheck_Ev01E00045:
	lda xhl, (0x22aa50:24)
	jr t, .LHCM_5a22                       ; [68 2a] jr T,0x285a22
HDAE5000_SfxSqtBitCheck_Ev01E00046:
	ld	xhl, 1:i3
	jr t, .LHCM_5a22                       ; [68 26] jr T,0x285a22
.LHCM_59fc:
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	calr	HDAE5000_TypeSel_BuildMask
	ld	bc, (HDAE5000_RAM_CurDir:24)
	ld	de, (HDAE5000_RAM_CurSong:24)
	ld	wa, (HDAE5000_RAM_SaveOptions:24)
	pushw wa                                ; push WA
	ld	xwa, HDAE5000_OBJ_HD_FILE_OPTION
	calr	HDAE5000_PartList_Build
	ld	xhl, 0:i3
	jr t, .LHCM_5a22                       ; [68 02] jr T,0x285a22
HDAE5000_SfxSqtBitCheck_Default:
	ld	xhl, 0:i3
.LHCM_5a22:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_SfxCmpBitCheck:
	; registered as "SfxCmpBitCheck" in HDAE5000_ObjHandler_Table
	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, EVT_RAM_DATA_REQ
	jrl z, .LHCM_5ab2                      ; [76 80 00] jrl Z,0x285ab2
	sub	xwa, EVT_GET_LARGE_STEP
	cp	xwa, 0x00000000
	jrl lt, HDAE5000_SfxCmpBitCheck_Default                     ; [71 95 00] jrl LT,0x285ad6
	cp	xwa, 0x00000009
	jrl gt, HDAE5000_SfxCmpBitCheck_Default                     ; [7a 8c 00] jrl GT,0x285ad6
	add	xwa, xwa
	add	xwa, HDAE5000_SfxCmpBitCheck_CaseTable
	ld	wa, (xwa)
	lda xix, (HDAE5000_SfxCmpBitCheck_Ev01E00047:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_SfxCmpBitCheck_Ev01E00047:
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, HDAE5000_TextPtrs_Chr2D2D2D_NO_YES
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x29b8		; low half of HDAE5000_Fmt_s_SfxCmpBitCheck
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_5ad8                       ; [68 55] jr T,0x285ad8
HDAE5000_SfxCmpBitCheck_Ev01E0003E:
	ld	xhl, 1:i3
	jr t, .LHCM_5ad8                       ; [68 51] jr T,0x285ad8
HDAE5000_SfxCmpBitCheck_Ev01E0003F:
	ld	xhl, 1:i3
	jr t, .LHCM_5ad8                       ; [68 4d] jr T,0x285ad8
HDAE5000_SfxCmpBitCheck_Ev01E00043:
	ld	xhl, 2:i3
	cp	(0x22AA51:24), 0
	jr nz, .LHCM_5a97                      ; [6e 02] jr NZ,0x285a97
	ld	xhl, 0:i3
.LHCM_5a97:
	jr t, .LHCM_5ad8                       ; [68 3f] jr T,0x285ad8
HDAE5000_SfxCmpBitCheck_Ev01E00044:
	ld	xhl, 1:i3
	cp	(0x22AA51:24), 0
	jr nz, .LHCM_5aa5                      ; [6e 02] jr NZ,0x285aa5
	ld	xhl, 0:i3
.LHCM_5aa5:
	jr t, .LHCM_5ad8                       ; [68 31] jr T,0x285ad8
HDAE5000_SfxCmpBitCheck_Ev01E00045:
	lda xhl, (0x22aa51:24)
	jr t, .LHCM_5ad8                       ; [68 2a] jr T,0x285ad8
HDAE5000_SfxCmpBitCheck_Ev01E00046:
	ld	xhl, 1:i3
	jr t, .LHCM_5ad8                       ; [68 26] jr T,0x285ad8
.LHCM_5ab2:
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	calr	HDAE5000_TypeSel_BuildMask
	ld	bc, (HDAE5000_RAM_CurDir:24)
	ld	de, (HDAE5000_RAM_CurSong:24)
	ld	wa, (HDAE5000_RAM_SaveOptions:24)
	pushw wa                                ; push WA
	ld	xwa, HDAE5000_OBJ_HD_FILE_OPTION
	calr	HDAE5000_PartList_Build
	ld	xhl, 0:i3
	jr t, .LHCM_5ad8                       ; [68 02] jr T,0x285ad8
HDAE5000_SfxCmpBitCheck_Default:
	ld	xhl, 0:i3
.LHCM_5ad8:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_SfxTmBitCheck:
	; registered as "SfxTmBitCheck" in HDAE5000_ObjHandler_Table
	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, EVT_RAM_DATA_REQ
	jrl z, .LHCM_5b68                      ; [76 80 00] jrl Z,0x285b68
	sub	xwa, EVT_GET_LARGE_STEP
	cp	xwa, 0x00000000
	jrl lt, HDAE5000_SfxTmBitCheck_Default                     ; [71 95 00] jrl LT,0x285b8c
	cp	xwa, 0x00000009
	jrl gt, HDAE5000_SfxTmBitCheck_Default                     ; [7a 8c 00] jrl GT,0x285b8c
	add	xwa, xwa
	add	xwa, HDAE5000_SfxTmBitCheck_CaseTable
	ld	wa, (xwa)
	lda xix, (HDAE5000_SfxTmBitCheck_Ev01E00047:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_SfxTmBitCheck_Ev01E00047:
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, HDAE5000_TextPtrs_Chr2D2D2D_NO_YES
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x29d0		; low half of HDAE5000_Fmt_s_SfxTmBitCheck
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_5b8e                       ; [68 55] jr T,0x285b8e
HDAE5000_SfxTmBitCheck_Ev01E0003E:
	ld	xhl, 1:i3
	jr t, .LHCM_5b8e                       ; [68 51] jr T,0x285b8e
HDAE5000_SfxTmBitCheck_Ev01E0003F:
	ld	xhl, 1:i3
	jr t, .LHCM_5b8e                       ; [68 4d] jr T,0x285b8e
HDAE5000_SfxTmBitCheck_Ev01E00043:
	ld	xhl, 2:i3
	cp	(0x22AA52:24), 0
	jr nz, .LHCM_5b4d                      ; [6e 02] jr NZ,0x285b4d
	ld	xhl, 0:i3
.LHCM_5b4d:
	jr t, .LHCM_5b8e                       ; [68 3f] jr T,0x285b8e
HDAE5000_SfxTmBitCheck_Ev01E00044:
	ld	xhl, 1:i3
	cp	(0x22AA52:24), 0
	jr nz, .LHCM_5b5b                      ; [6e 02] jr NZ,0x285b5b
	ld	xhl, 0:i3
.LHCM_5b5b:
	jr t, .LHCM_5b8e                       ; [68 31] jr T,0x285b8e
HDAE5000_SfxTmBitCheck_Ev01E00045:
	lda xhl, (0x22aa52:24)
	jr t, .LHCM_5b8e                       ; [68 2a] jr T,0x285b8e
HDAE5000_SfxTmBitCheck_Ev01E00046:
	ld	xhl, 1:i3
	jr t, .LHCM_5b8e                       ; [68 26] jr T,0x285b8e
.LHCM_5b68:
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	calr	HDAE5000_TypeSel_BuildMask
	ld	bc, (HDAE5000_RAM_CurDir:24)
	ld	de, (HDAE5000_RAM_CurSong:24)
	ld	wa, (HDAE5000_RAM_SaveOptions:24)
	pushw wa                                ; push WA
	ld	xwa, HDAE5000_OBJ_HD_FILE_OPTION
	calr	HDAE5000_PartList_Build
	ld	xhl, 0:i3
	jr t, .LHCM_5b8e                       ; [68 02] jr T,0x285b8e
HDAE5000_SfxTmBitCheck_Default:
	ld	xhl, 0:i3
.LHCM_5b8e:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_SfxMspBitCheck:
	; registered as "SfxMspBitCheck" in HDAE5000_ObjHandler_Table
	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, EVT_RAM_DATA_REQ
	jrl z, .LHCM_5c1e                      ; [76 80 00] jrl Z,0x285c1e
	sub	xwa, EVT_GET_LARGE_STEP
	cp	xwa, 0x00000000
	jrl lt, HDAE5000_SfxMspBitCheck_Default                     ; [71 95 00] jrl LT,0x285c42
	cp	xwa, 0x00000009
	jrl gt, HDAE5000_SfxMspBitCheck_Default                     ; [7a 8c 00] jrl GT,0x285c42
	add	xwa, xwa
	add	xwa, HDAE5000_SfxMspBitCheck_CaseTable
	ld	wa, (xwa)
	lda xix, (HDAE5000_SfxMspBitCheck_Ev01E00047:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_SfxMspBitCheck_Ev01E00047:
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, HDAE5000_TextPtrs_Chr2D2D2D_NO_YES
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x29e8		; low half of HDAE5000_Fmt_s_SfxMspBitCheck
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_5c44                       ; [68 55] jr T,0x285c44
HDAE5000_SfxMspBitCheck_Ev01E0003E:
	ld	xhl, 1:i3
	jr t, .LHCM_5c44                       ; [68 51] jr T,0x285c44
HDAE5000_SfxMspBitCheck_Ev01E0003F:
	ld	xhl, 1:i3
	jr t, .LHCM_5c44                       ; [68 4d] jr T,0x285c44
HDAE5000_SfxMspBitCheck_Ev01E00043:
	ld	xhl, 2:i3
	cp	(0x22AA53:24), 0
	jr nz, .LHCM_5c03                      ; [6e 02] jr NZ,0x285c03
	ld	xhl, 0:i3
.LHCM_5c03:
	jr t, .LHCM_5c44                       ; [68 3f] jr T,0x285c44
HDAE5000_SfxMspBitCheck_Ev01E00044:
	ld	xhl, 1:i3
	cp	(0x22AA53:24), 0
	jr nz, .LHCM_5c11                      ; [6e 02] jr NZ,0x285c11
	ld	xhl, 0:i3
.LHCM_5c11:
	jr t, .LHCM_5c44                       ; [68 31] jr T,0x285c44
HDAE5000_SfxMspBitCheck_Ev01E00045:
	lda xhl, (0x22aa53:24)
	jr t, .LHCM_5c44                       ; [68 2a] jr T,0x285c44
HDAE5000_SfxMspBitCheck_Ev01E00046:
	ld	xhl, 1:i3
	jr t, .LHCM_5c44                       ; [68 26] jr T,0x285c44
.LHCM_5c1e:
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	calr	HDAE5000_TypeSel_BuildMask
	ld	bc, (HDAE5000_RAM_CurDir:24)
	ld	de, (HDAE5000_RAM_CurSong:24)
	ld	wa, (HDAE5000_RAM_SaveOptions:24)
	pushw wa                                ; push WA
	ld	xwa, HDAE5000_OBJ_HD_FILE_OPTION
	calr	HDAE5000_PartList_Build
	ld	xhl, 0:i3
	jr t, .LHCM_5c44                       ; [68 02] jr T,0x285c44
HDAE5000_SfxMspBitCheck_Default:
	ld	xhl, 0:i3
.LHCM_5c44:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_SfxRcmBitCheck:
	; registered as "SfxRcmBitCheck" in HDAE5000_ObjHandler_Table
	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, EVT_RAM_DATA_REQ
	jrl z, .LHCM_5cd4                      ; [76 80 00] jrl Z,0x285cd4
	sub	xwa, EVT_GET_LARGE_STEP
	cp	xwa, 0x00000000
	jrl lt, HDAE5000_SfxRcmBitCheck_Default                     ; [71 95 00] jrl LT,0x285cf8
	cp	xwa, 0x00000009
	jrl gt, HDAE5000_SfxRcmBitCheck_Default                     ; [7a 8c 00] jrl GT,0x285cf8
	add	xwa, xwa
	add	xwa, HDAE5000_SfxRcmBitCheck_CaseTable
	ld	wa, (xwa)
	lda xix, (HDAE5000_SfxRcmBitCheck_Ev01E00047:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_SfxRcmBitCheck_Ev01E00047:
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, HDAE5000_TextPtrs_Chr2D2D2D_NO_YES
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2a00		; low half of HDAE5000_Fmt_s_SfxRcmBitCheck
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_5cfa                       ; [68 55] jr T,0x285cfa
HDAE5000_SfxRcmBitCheck_Ev01E0003E:
	ld	xhl, 1:i3
	jr t, .LHCM_5cfa                       ; [68 51] jr T,0x285cfa
HDAE5000_SfxRcmBitCheck_Ev01E0003F:
	ld	xhl, 1:i3
	jr t, .LHCM_5cfa                       ; [68 4d] jr T,0x285cfa
HDAE5000_SfxRcmBitCheck_Ev01E00043:
	ld	xhl, 2:i3
	cp	(0x22AA54:24), 0
	jr nz, .LHCM_5cb9                      ; [6e 02] jr NZ,0x285cb9
	ld	xhl, 0:i3
.LHCM_5cb9:
	jr t, .LHCM_5cfa                       ; [68 3f] jr T,0x285cfa
HDAE5000_SfxRcmBitCheck_Ev01E00044:
	ld	xhl, 1:i3
	cp	(0x22AA54:24), 0
	jr nz, .LHCM_5cc7                      ; [6e 02] jr NZ,0x285cc7
	ld	xhl, 0:i3
.LHCM_5cc7:
	jr t, .LHCM_5cfa                       ; [68 31] jr T,0x285cfa
HDAE5000_SfxRcmBitCheck_Ev01E00045:
	lda xhl, (0x22aa54:24)
	jr t, .LHCM_5cfa                       ; [68 2a] jr T,0x285cfa
HDAE5000_SfxRcmBitCheck_Ev01E00046:
	ld	xhl, 1:i3
	jr t, .LHCM_5cfa                       ; [68 26] jr T,0x285cfa
.LHCM_5cd4:
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	calr	HDAE5000_TypeSel_BuildMask
	ld	bc, (HDAE5000_RAM_CurDir:24)
	ld	de, (HDAE5000_RAM_CurSong:24)
	ld	wa, (HDAE5000_RAM_SaveOptions:24)
	pushw wa                                ; push WA
	ld	xwa, HDAE5000_OBJ_HD_FILE_OPTION
	calr	HDAE5000_PartList_Build
	ld	xhl, 0:i3
	jr t, .LHCM_5cfa                       ; [68 02] jr T,0x285cfa
HDAE5000_SfxRcmBitCheck_Default:
	ld	xhl, 0:i3
.LHCM_5cfa:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_SfxMdBitCheck:
	; registered as "SfxMdBitCheck" in HDAE5000_ObjHandler_Table
	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, EVT_RAM_DATA_REQ
	jrl z, .LHCM_5d8a                      ; [76 80 00] jrl Z,0x285d8a
	sub	xwa, EVT_GET_LARGE_STEP
	cp	xwa, 0x00000000
	jrl lt, HDAE5000_SfxMdBitCheck_Default                     ; [71 95 00] jrl LT,0x285dae
	cp	xwa, 0x00000009
	jrl gt, HDAE5000_SfxMdBitCheck_Default                     ; [7a 8c 00] jrl GT,0x285dae
	add	xwa, xwa
	add	xwa, HDAE5000_SfxMdBitCheck_CaseTable
	ld	wa, (xwa)
	lda xix, (HDAE5000_SfxMdBitCheck_Ev01E00047:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_SfxMdBitCheck_Ev01E00047:
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, HDAE5000_TextPtrs_Chr2D2D2D_NO_YES
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2a18		; low half of HDAE5000_Fmt_s_SfxMdBitCheck
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_5db0                       ; [68 55] jr T,0x285db0
HDAE5000_SfxMdBitCheck_Ev01E0003E:
	ld	xhl, 1:i3
	jr t, .LHCM_5db0                       ; [68 51] jr T,0x285db0
HDAE5000_SfxMdBitCheck_Ev01E0003F:
	ld	xhl, 1:i3
	jr t, .LHCM_5db0                       ; [68 4d] jr T,0x285db0
HDAE5000_SfxMdBitCheck_Ev01E00043:
	ld	xhl, 2:i3
	cp	(0x22AA55:24), 0
	jr nz, .LHCM_5d6f                      ; [6e 02] jr NZ,0x285d6f
	ld	xhl, 0:i3
.LHCM_5d6f:
	jr t, .LHCM_5db0                       ; [68 3f] jr T,0x285db0
HDAE5000_SfxMdBitCheck_Ev01E00044:
	ld	xhl, 1:i3
	cp	(0x22AA55:24), 0
	jr nz, .LHCM_5d7d                      ; [6e 02] jr NZ,0x285d7d
	ld	xhl, 0:i3
.LHCM_5d7d:
	jr t, .LHCM_5db0                       ; [68 31] jr T,0x285db0
HDAE5000_SfxMdBitCheck_Ev01E00045:
	lda xhl, (0x22aa55:24)
	jr t, .LHCM_5db0                       ; [68 2a] jr T,0x285db0
HDAE5000_SfxMdBitCheck_Ev01E00046:
	ld	xhl, 1:i3
	jr t, .LHCM_5db0                       ; [68 26] jr T,0x285db0
.LHCM_5d8a:
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	calr	HDAE5000_TypeSel_BuildMask
	ld	bc, (HDAE5000_RAM_CurDir:24)
	ld	de, (HDAE5000_RAM_CurSong:24)
	ld	wa, (HDAE5000_RAM_SaveOptions:24)
	pushw wa                                ; push WA
	ld	xwa, HDAE5000_OBJ_HD_FILE_OPTION
	calr	HDAE5000_PartList_Build
	ld	xhl, 0:i3
	jr t, .LHCM_5db0                       ; [68 02] jr T,0x285db0
HDAE5000_SfxMdBitCheck_Default:
	ld	xhl, 0:i3
.LHCM_5db0:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_SfxTlxBitCheck:
	; registered as "SfxTlxBitCheck" in HDAE5000_ObjHandler_Table
	dec	4, xsp
	push xiz
	ld (xsp + 0x04), xwa                    ; ld (XSP+0x04),XWA
	ld	xwa, xbc
	cp	xwa, EVT_RAM_DATA_REQ
	jrl z, .LHCM_5e6d                      ; [76 aa 00] jrl Z,0x285e6d
	sub	xwa, EVT_GET_LARGE_STEP
	cp	xwa, 0x00000000
	jrl lt, HDAE5000_SfxTlxBitCheck_Default                     ; [71 bf 00] jrl LT,0x285e91
	cp	xwa, 0x00000009
	jrl gt, HDAE5000_SfxTlxBitCheck_Default                     ; [7a b6 00] jrl GT,0x285e91
	add	xwa, xwa
	add	xwa, HDAE5000_SfxTlxBitCheck_CaseTable
	ld	wa, (xwa)
	lda xix, (HDAE5000_SfxTlxBitCheck_Ev01E00047:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_SfxTlxBitCheck_Ev01E00047:
	ld	xiz, xde
	ld xwa, (xiz + 0x0e)                    ; ld XWA,(XIZ+0x0e)
	sll	xwa, 0x02
	ld	xbc, HDAE5000_TextPtrs_Chr2D2D2D_NO_YES
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2a30		; low half of HDAE5000_Fmt_s_SfxTlxBitCheck
	ld xwa, (xiz + 0x12)                    ; ld XWA,(XIZ+0x12)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	ld xwa, (xiz + 0x0e)                    ; ld XWA,(XIZ+0x0e)
	ld	(0x23a0a6), xwa
	ld xhl, (xsp + 0x04)                    ; ld XHL,(XSP+0x04)
	jr t, .LHCM_5e93                       ; [68 74] jr T,0x285e93
HDAE5000_SfxTlxBitCheck_Ev01E0003E:
	ld	xhl, 1:i3
	jr t, .LHCM_5e93                       ; [68 70] jr T,0x285e93
HDAE5000_SfxTlxBitCheck_Ev01E0003F:
	ld	xhl, 1:i3
	jr t, .LHCM_5e93                       ; [68 6c] jr T,0x285e93
HDAE5000_SfxTlxBitCheck_Ev01E00043:
	ld	xhl, 2:i3
	cp	(0x22AA56:24), 0
	jr nz, .LHCM_5e33                      ; [6e 02] jr NZ,0x285e33
	ld	xhl, 0:i3
.LHCM_5e33:
	jr t, .LHCM_5e93                       ; [68 5e] jr T,0x285e93
HDAE5000_SfxTlxBitCheck_Ev01E00044:
	ld	xwa, (0x23a0a6)
	cp	xwa, 0x00000001
	jr nz, .LHCM_5e4d                      ; [6e 0b] jr NZ,0x285e4d
	ld	xwa, 2:i3
	ld	(0x23a0a6), xwa
	ld	xhl, 2:i3
	jr t, .LHCM_5e56                       ; [68 09] jr T,0x285e56
.LHCM_5e4d:
	ld	xwa, 1:i3
	ld	(0x23a0a6), xwa
	ld	xhl, 1:i3
.LHCM_5e56:
	cp	(0x22AA56:24), 0
	jr nz, .LHCM_5e60                      ; [6e 02] jr NZ,0x285e60
	ld	xhl, 0:i3
.LHCM_5e60:
	jr t, .LHCM_5e93                       ; [68 31] jr T,0x285e93
HDAE5000_SfxTlxBitCheck_Ev01E00045:
	lda xhl, (0x22aa56:24)
	jr t, .LHCM_5e93                       ; [68 2a] jr T,0x285e93
HDAE5000_SfxTlxBitCheck_Ev01E00046:
	ld	xhl, 1:i3
	jr t, .LHCM_5e93                       ; [68 26] jr T,0x285e93
.LHCM_5e6d:
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	calr	HDAE5000_TypeSel_BuildMask
	ld	bc, (HDAE5000_RAM_CurDir:24)
	ld	de, (HDAE5000_RAM_CurSong:24)
	ld	wa, (HDAE5000_RAM_SaveOptions:24)
	pushw wa                                ; push WA
	ld	xwa, HDAE5000_OBJ_HD_FILE_OPTION
	calr	HDAE5000_PartList_Build
	ld	xhl, 0:i3
	jr t, .LHCM_5e93                       ; [68 02] jr T,0x285e93
HDAE5000_SfxTlxBitCheck_Default:
	ld	xhl, 0:i3
.LHCM_5e93:
	pop xiz                                 ; pop XIZ
	inc 4, xsp                              ; inc 4,XSP
	ret

HDAE5000_WriteProtectEditCheck:
	; registered as "WriteProtectEditCheck" in HDAE5000_ObjHandler_Table
	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, EVT_RAM_DATA_REQ
	jr z, .LHCM_5f0a                       ; [66 66] jr Z,0x285f0a
	sub	xwa, EVT_GET_LARGE_STEP
	cp	xwa, 0x00000000
	jr lt, HDAE5000_WriteProtectEditCheck_Default                      ; [61 66] jr LT,0x285f18
	cp	xwa, 0x00000009
	jr gt, HDAE5000_WriteProtectEditCheck_Default                      ; [6a 5e] jr GT,0x285f18
	add	xwa, xwa
	add	xwa, HDAE5000_WriteProtectEditCheck_CaseTable
	ld	wa, (xwa)
	lda xix, (HDAE5000_WriteProtectEditCheck_Ev01E00047:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_WriteProtectEditCheck_Ev01E00047:
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, HDAE5000_TextPtrs_OFF_ON
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2a48		; low half of HDAE5000_Fmt_s_WriteProtectEditCheck
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_5f1a                       ; [68 27] jr T,0x285f1a
HDAE5000_WriteProtectEditCheck_Ev01E0003E:
	ld	xhl, 1:i3
	jr t, .LHCM_5f1a                       ; [68 23] jr T,0x285f1a
HDAE5000_WriteProtectEditCheck_Ev01E00043:
	ld	xhl, 1:i3
	jr t, .LHCM_5f1a                       ; [68 1f] jr T,0x285f1a
HDAE5000_WriteProtectEditCheck_Ev01E00044:
	ld	xhl, 0:i3
	jr t, .LHCM_5f1a                       ; [68 1b] jr T,0x285f1a
HDAE5000_WriteProtectEditCheck_Ev01E00045:
	lda xhl, (HDAE5000_RAM_WriteProtect:24)
	jr t, .LHCM_5f1a                       ; [68 14] jr T,0x285f1a
HDAE5000_WriteProtectEditCheck_Ev01E00046:
	ld	xhl, 1:i3
	jr t, .LHCM_5f1a                       ; [68 10] jr T,0x285f1a
.LHCM_5f0a:
	ld	a, (HDAE5000_RAM_WriteProtect:24)
	extz wa                                 ; extz WA
	calr	HDAE5000_Set_Menu_Visibility
	ld	xhl, 0:i3
	jr t, .LHCM_5f1a                       ; [68 02] jr T,0x285f1a
HDAE5000_WriteProtectEditCheck_Default:
	ld	xhl, 0:i3
.LHCM_5f1a:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_LyricJumpEditCheck:
	; registered as "LyricJumpEditCheck" in HDAE5000_ObjHandler_Table
	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, EVT_RAM_DATA_REQ
	jr z, .LHCM_5f83                       ; [66 5a] jr Z,0x285f83
	sub	xwa, EVT_GET_LARGE_STEP
	cp	xwa, 0x00000000
	jr lt, HDAE5000_LyricJumpEditCheck_Default                      ; [61 50] jr LT,0x285f87
	cp	xwa, 0x00000009
	jr gt, HDAE5000_LyricJumpEditCheck_Default                      ; [6a 48] jr GT,0x285f87
	add	xwa, xwa
	add	xwa, HDAE5000_LyricJumpEditCheck_CaseTable
	ld	wa, (xwa)
	lda xix, (HDAE5000_LyricJumpEditCheck_Ev01E00047:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_LyricJumpEditCheck_Ev01E00047:
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	push xwa
	pushw 0x002e
	pushw 0x2a60		; low half of HDAE5000_Fmt_1d
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_5f89                       ; [68 1d] jr T,0x285f89
HDAE5000_LyricJumpEditCheck_Ev01E0003E:
	ld	xhl, 1:i3
	jr t, .LHCM_5f89                       ; [68 19] jr T,0x285f89
HDAE5000_LyricJumpEditCheck_Ev01E00043:
	ld	xhl, 2:i3
	jr t, .LHCM_5f89                       ; [68 15] jr T,0x285f89
HDAE5000_LyricJumpEditCheck_Ev01E00044:
	ld	xhl, 1:i3
	jr t, .LHCM_5f89                       ; [68 11] jr T,0x285f89
HDAE5000_LyricJumpEditCheck_Ev01E00045:
	lda xhl, (HDAE5000_RAM_LyricJump:24)
	jr t, .LHCM_5f89                       ; [68 0a] jr T,0x285f89
HDAE5000_LyricJumpEditCheck_Ev01E00046:
	ld	xhl, 1:i3
	jr t, .LHCM_5f89                       ; [68 06] jr T,0x285f89
.LHCM_5f83:
	ld	xhl, 0:i3
	jr t, .LHCM_5f89                       ; [68 02] jr T,0x285f89
HDAE5000_LyricJumpEditCheck_Default:
	ld	xhl, 0:i3
.LHCM_5f89:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	cp	xbc, EVT_SW_IN
	jr z, .LHCM_5fc3                       ; [66 2d] jr Z,0x285fc3
	cp	xbc, EVT_RAM_DATA_REQ
	jr z, .LHCM_5fbf                       ; [66 21] jr Z,0x285fbf
	cp	xbc, EVT_GET_RAM_STRING
	jr nz, .LHCM_5fe2                      ; [6e 3c] jr NZ,0x285fe2
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	push xwa
	pushw 0x002e
	pushw 0x2a78		; low half of HDAE5000_Fmt_1d_LyricJumpEditCheck
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_5fe4                       ; [68 25] jr T,0x285fe4
.LHCM_5fbf:
	ld	xhl, 0:i3
	jr t, .LHCM_5fe4                       ; [68 21] jr T,0x285fe4
.LHCM_5fc3:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xix, (xwa + RootFn_SendEvent)
	ld	xwa, 0x02600024
	ld	xbc, EVT_MAKE_EDIT_SW_ID
	call	(xix)
	or xhl, xhl                             ; or XHL,XHL
	jr z, .LHCM_5fe2                       ; [66 00] jr Z,0x285fe2
.LHCM_5fe2:
	ld	xhl, 0:i3
.LHCM_5fe4:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_LyricForeColorCheck:
	; registered as "LyricForeColorCheck" in HDAE5000_ObjHandler_Table
	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, EVT_RAM_DATA_REQ
	jr z, .LHCM_605d                       ; [66 6a] jr Z,0x28605d
	sub	xwa, EVT_GET_LARGE_STEP
	cp	xwa, 0x00000000
	jr lt, HDAE5000_LyricForeColorCheck_Default                      ; [61 60] jr LT,0x286061
	cp	xwa, 0x00000009
	jr gt, HDAE5000_LyricForeColorCheck_Default                      ; [6a 58] jr GT,0x286061
	add	xwa, xwa
	add	xwa, HDAE5000_LyricForeColorCheck_CaseTable
	ld	wa, (xwa)
	lda xix, (HDAE5000_LyricForeColorCheck_Ev01E00047:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_LyricForeColorCheck_Ev01E00047:
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, HDAE5000_TextPtrs_RED_to_YELLOW
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2ab8		; low half of HDAE5000_Fmt_s_LyricForeColorCheck
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_6063                       ; [68 21] jr T,0x286063
HDAE5000_LyricForeColorCheck_Ev01E0003E:
	ld	xhl, 1:i3
	jr t, .LHCM_6063                       ; [68 1d] jr T,0x286063
HDAE5000_LyricForeColorCheck_Ev01E0003F:
	ld	xhl, 1:i3
	jr t, .LHCM_6063                       ; [68 19] jr T,0x286063
HDAE5000_LyricForeColorCheck_Ev01E00043:
	ld	xhl, 4:i3
	jr t, .LHCM_6063                       ; [68 15] jr T,0x286063
HDAE5000_LyricForeColorCheck_Ev01E00044:
	ld	xhl, 0:i3
	jr t, .LHCM_6063                       ; [68 11] jr T,0x286063
HDAE5000_LyricForeColorCheck_Ev01E00045:
	lda xhl, (HDAE5000_RAM_LyricForeColor:24)
	jr t, .LHCM_6063                       ; [68 0a] jr T,0x286063
HDAE5000_LyricForeColorCheck_Ev01E00046:
	ld	xhl, 1:i3
	jr t, .LHCM_6063                       ; [68 06] jr T,0x286063
.LHCM_605d:
	ld	xhl, 0:i3
	jr t, .LHCM_6063                       ; [68 02] jr T,0x286063
HDAE5000_LyricForeColorCheck_Default:
	ld	xhl, 0:i3
.LHCM_6063:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_LyricBackColorCheck:
	; registered as "LyricBackColorCheck" in HDAE5000_ObjHandler_Table
	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, EVT_RAM_DATA_REQ
	jr z, .LHCM_60dc                       ; [66 6a] jr Z,0x2860dc
	sub	xwa, EVT_GET_LARGE_STEP
	cp	xwa, 0x00000000
	jr lt, HDAE5000_LyricBackColorCheck_Default                      ; [61 60] jr LT,0x2860e0
	cp	xwa, 0x00000009
	jr gt, HDAE5000_LyricBackColorCheck_Default                      ; [6a 58] jr GT,0x2860e0
	add	xwa, xwa
	add	xwa, HDAE5000_LyricBackColorCheck_CaseTable
	ld	wa, (xwa)
	lda xix, (HDAE5000_LyricBackColorCheck_Ev01E00047:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_LyricBackColorCheck_Ev01E00047:
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, HDAE5000_TextPtrs_RED_to_YELLOW_2
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2b0c		; low half of HDAE5000_Fmt_s_LyricBackColorCheck
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_60e2                       ; [68 21] jr T,0x2860e2
HDAE5000_LyricBackColorCheck_Ev01E0003E:
	ld	xhl, 1:i3
	jr t, .LHCM_60e2                       ; [68 1d] jr T,0x2860e2
HDAE5000_LyricBackColorCheck_Ev01E0003F:
	ld	xhl, 1:i3
	jr t, .LHCM_60e2                       ; [68 19] jr T,0x2860e2
HDAE5000_LyricBackColorCheck_Ev01E00043:
	ld	xhl, 4:i3
	jr t, .LHCM_60e2                       ; [68 15] jr T,0x2860e2
HDAE5000_LyricBackColorCheck_Ev01E00044:
	ld	xhl, 0:i3
	jr t, .LHCM_60e2                       ; [68 11] jr T,0x2860e2
HDAE5000_LyricBackColorCheck_Ev01E00045:
	lda xhl, (HDAE5000_RAM_LyricBackColor:24)
	jr t, .LHCM_60e2                       ; [68 0a] jr T,0x2860e2
HDAE5000_LyricBackColorCheck_Ev01E00046:
	ld	xhl, 1:i3
	jr t, .LHCM_60e2                       ; [68 06] jr T,0x2860e2
.LHCM_60dc:
	ld	xhl, 0:i3
	jr t, .LHCM_60e2                       ; [68 02] jr T,0x2860e2
HDAE5000_LyricBackColorCheck_Default:
	ld	xhl, 0:i3
.LHCM_60e2:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_WriteConfirmEditCheck:
	; registered as "WriteConfirmEditCheck" in HDAE5000_ObjHandler_Table
	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, EVT_RAM_DATA_REQ
	jr z, .LHCM_6157                       ; [66 66] jr Z,0x286157
	sub	xwa, EVT_GET_LARGE_STEP
	cp	xwa, 0x00000000
	jr lt, HDAE5000_WriteConfirmEditCheck_Default                      ; [61 5c] jr LT,0x28615b
	cp	xwa, 0x00000009
	jr gt, HDAE5000_WriteConfirmEditCheck_Default                      ; [6a 54] jr GT,0x28615b
	add	xwa, xwa
	add	xwa, HDAE5000_WriteConfirmEditCheck_CaseTable
	ld	wa, (xwa)
	lda xix, (HDAE5000_WriteConfirmEditCheck_Ev01E00047:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_WriteConfirmEditCheck_Ev01E00047:
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, HDAE5000_TextPtrs_OFF_ON
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2b24		; low half of HDAE5000_Fmt_s_WriteConfirmEditCheck
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_615d                       ; [68 1d] jr T,0x28615d
HDAE5000_WriteConfirmEditCheck_Ev01E0003E:
	ld	xhl, 1:i3
	jr t, .LHCM_615d                       ; [68 19] jr T,0x28615d
HDAE5000_WriteConfirmEditCheck_Ev01E00043:
	ld	xhl, 1:i3
	jr t, .LHCM_615d                       ; [68 15] jr T,0x28615d
HDAE5000_WriteConfirmEditCheck_Ev01E00044:
	ld	xhl, 0:i3
	jr t, .LHCM_615d                       ; [68 11] jr T,0x28615d
HDAE5000_WriteConfirmEditCheck_Ev01E00045:
	lda xhl, (HDAE5000_RAM_WriteConfirm:24)
	jr t, .LHCM_615d                       ; [68 0a] jr T,0x28615d
HDAE5000_WriteConfirmEditCheck_Ev01E00046:
	ld	xhl, 1:i3
	jr t, .LHCM_615d                       ; [68 06] jr T,0x28615d
.LHCM_6157:
	ld	xhl, 0:i3
	jr t, .LHCM_615d                       ; [68 02] jr T,0x28615d
HDAE5000_WriteConfirmEditCheck_Default:
	ld	xhl, 0:i3
.LHCM_615d:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_QuickLoadModeEditCheck:
	; registered as "QuickLoadModeEditCheck" in HDAE5000_ObjHandler_Table
	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, EVT_RAM_DATA_REQ
	jr z, .LHCM_61c6                       ; [66 5a] jr Z,0x2861c6
	sub	xwa, EVT_GET_LARGE_STEP
	cp	xwa, 0x00000000
	jr lt, HDAE5000_QuickLoadModeEditCheck_Default                      ; [61 50] jr LT,0x2861ca
	cp	xwa, 0x00000009
	jr gt, HDAE5000_QuickLoadModeEditCheck_Default                      ; [6a 48] jr GT,0x2861ca
	add	xwa, xwa
	add	xwa, HDAE5000_QuickLoadModeEditCheck_CaseTable
	ld	wa, (xwa)
	lda xix, (HDAE5000_QuickLoadModeEditCheck_Ev01E00047:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_QuickLoadModeEditCheck_Ev01E00047:
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	push xwa
	pushw 0x002e
	pushw 0x2b3c		; low half of HDAE5000_Fmt_1d_QuickLoadModeEditCheck
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_61cc                       ; [68 1d] jr T,0x2861cc
HDAE5000_QuickLoadModeEditCheck_Ev01E0003E:
	ld	xhl, 1:i3
	jr t, .LHCM_61cc                       ; [68 19] jr T,0x2861cc
HDAE5000_QuickLoadModeEditCheck_Ev01E00043:
	ld	xhl, 3:i3
	jr t, .LHCM_61cc                       ; [68 15] jr T,0x2861cc
HDAE5000_QuickLoadModeEditCheck_Ev01E00044:
	ld	xhl, 1:i3
	jr t, .LHCM_61cc                       ; [68 11] jr T,0x2861cc
HDAE5000_QuickLoadModeEditCheck_Ev01E00045:
	lda xhl, (HDAE5000_RAM_QuickLoadMode:24)
	jr t, .LHCM_61cc                       ; [68 0a] jr T,0x2861cc
HDAE5000_QuickLoadModeEditCheck_Ev01E00046:
	ld	xhl, 1:i3
	jr t, .LHCM_61cc                       ; [68 06] jr T,0x2861cc
.LHCM_61c6:
	ld	xhl, 0:i3
	jr t, .LHCM_61cc                       ; [68 02] jr T,0x2861cc
HDAE5000_QuickLoadModeEditCheck_Default:
	ld	xhl, 0:i3
.LHCM_61cc:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_LoadByNumberModeEditCheck:
	; registered as "LoadByNumberModeEditCheck" in HDAE5000_ObjHandler_Table
	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, EVT_RAM_DATA_REQ
	jr z, .LHCM_6235                       ; [66 5a] jr Z,0x286235
	sub	xwa, EVT_GET_LARGE_STEP
	cp	xwa, 0x00000000
	jr lt, HDAE5000_LoadByNumberModeEditCheck_Default                      ; [61 50] jr LT,0x286239
	cp	xwa, 0x00000009
	jr gt, HDAE5000_LoadByNumberModeEditCheck_Default                      ; [6a 48] jr GT,0x286239
	add	xwa, xwa
	add	xwa, HDAE5000_LoadByNumberModeEditCheck_CaseTable
	ld	wa, (xwa)
	lda xix, (HDAE5000_LoadByNumberModeEditCheck_Ev01E00047:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_LoadByNumberModeEditCheck_Ev01E00047:
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	push xwa
	pushw 0x002e
	pushw 0x2b54		; low half of HDAE5000_Fmt_1d_LoadByNumberModeEditCheck
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_623b                       ; [68 1d] jr T,0x28623b
HDAE5000_LoadByNumberModeEditCheck_Ev01E0003E:
	ld	xhl, 1:i3
	jr t, .LHCM_623b                       ; [68 19] jr T,0x28623b
HDAE5000_LoadByNumberModeEditCheck_Ev01E00043:
	ld	xhl, 2:i3
	jr t, .LHCM_623b                       ; [68 15] jr T,0x28623b
HDAE5000_LoadByNumberModeEditCheck_Ev01E00044:
	ld	xhl, 1:i3
	jr t, .LHCM_623b                       ; [68 11] jr T,0x28623b
HDAE5000_LoadByNumberModeEditCheck_Ev01E00045:
	lda xhl, (HDAE5000_RAM_LoadByNumberMode:24)
	jr t, .LHCM_623b                       ; [68 0a] jr T,0x28623b
HDAE5000_LoadByNumberModeEditCheck_Ev01E00046:
	ld	xhl, 1:i3
	jr t, .LHCM_623b                       ; [68 06] jr T,0x28623b
.LHCM_6235:
	ld	xhl, 0:i3
	jr t, .LHCM_623b                       ; [68 02] jr T,0x28623b
HDAE5000_LoadByNumberModeEditCheck_Default:
	ld	xhl, 0:i3
.LHCM_623b:
	pop xiz                                 ; pop XIZ
	ret

HDAE5000_JumpAfterLoadModeEditCheck:
	; registered as "JumpAfterLoadModeEditCheck" in HDAE5000_ObjHandler_Table
	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, EVT_RAM_DATA_REQ
	jr z, .LHCM_62a4                       ; [66 5a] jr Z,0x2862a4
	sub	xwa, EVT_GET_LARGE_STEP
	cp	xwa, 0x00000000
	jr lt, HDAE5000_JumpAfterLoadModeEditCheck_Default                      ; [61 50] jr LT,0x2862a8
	cp	xwa, 0x00000009
	jr gt, HDAE5000_JumpAfterLoadModeEditCheck_Default                      ; [6a 48] jr GT,0x2862a8
	add	xwa, xwa
	add	xwa, HDAE5000_JumpAfterLoadModeEditCheck_CaseTable
	ld	wa, (xwa)
	lda xix, (HDAE5000_JumpAfterLoadModeEditCheck_Ev01E00047:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_JumpAfterLoadModeEditCheck_Ev01E00047:
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	push xwa
	pushw 0x002e
	pushw 0x2b6c		; low half of HDAE5000_Fmt_1d_JumpAfterLoadModeEditCheck
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_SPrintf
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_62aa                       ; [68 1d] jr T,0x2862aa
HDAE5000_JumpAfterLoadModeEditCheck_Ev01E0003E:
	ld	xhl, 1:i3
	jr t, .LHCM_62aa                       ; [68 19] jr T,0x2862aa
HDAE5000_JumpAfterLoadModeEditCheck_Ev01E00043:
	ld	xhl, 2:i3
	jr t, .LHCM_62aa                       ; [68 15] jr T,0x2862aa
HDAE5000_JumpAfterLoadModeEditCheck_Ev01E00044:
	ld	xhl, 1:i3
	jr t, .LHCM_62aa                       ; [68 11] jr T,0x2862aa
HDAE5000_JumpAfterLoadModeEditCheck_Ev01E00045:
	lda xhl, (HDAE5000_RAM_JumpAfterLoad:24)
	jr t, .LHCM_62aa                       ; [68 0a] jr T,0x2862aa
HDAE5000_JumpAfterLoadModeEditCheck_Ev01E00046:
	ld	xhl, 1:i3
	jr t, .LHCM_62aa                       ; [68 06] jr T,0x2862aa
.LHCM_62a4:
	ld	xhl, 0:i3
	jr t, .LHCM_62aa                       ; [68 02] jr T,0x2862aa
HDAE5000_JumpAfterLoadModeEditCheck_Default:
	ld	xhl, 0:i3
.LHCM_62aa:
	pop xiz                                 ; pop XIZ
	ret


HDAE5000_SetupPage_BuildDriveInfo:	; 0x2862AC (818 bytes)
	; Build the drive-information page of SetupP2 from the template at
	; 0x2E2B84 ("HD-TYPE", "TRACKS", "HEADS", "SECTORS PER TRACK", "TOTAL HD
	; (MB)", "USED BY SYSTEM (MB)", "FREE FOR USE (MB)", "SOFTWARE RELEASE")
	; filled from HDAE5000_HD_GetGeometry and HDAE5000_HD_GetDiskUsage.
	; (Was "set up HD partition parameters": there are no partitions.)
	lda	xsp, (xsp-108)
	pushw 0x0139
	lda xwa, (HDAE5000_DriveInfo_Template:24)
	push xwa
	lda xwa, (0x22b2f6:24)
	push xwa
	call HDAE5000_MemCopy			; HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)
	lda xwa, (xsp + 0x38)
	call HDAE5000_HD_GetGeometry
	pushw 0x0010
	lda xwa, (xsp + 0x44)
	push xwa
	lda xwa, (0x22b30c:24)
	push xwa
	call HDAE5000_MemCopy
	pushw 0x000a		; push 0x000A
	lda xwa, (xsp + 0x24)
	push xwa
	ld wa, (xsp + 0x48)
	pushw wa                                ; push wa (compact)
	call HDAE5000_IToA
	lda xwa, (xsp + 0x2a)
	push xwa
	call HDAE5000_StrLen			; HDAE5000_StrLen
	pushw hl                                ; push hl (compact)
	lda xwa, (xsp + 0x30)
	push xwa
	lda xwa, (0x22b333:24)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x20)
	pushw 0x000a		; push 0x000A
	lda xwa, (xsp + 0x1a)
	push xwa
	ld wa, (xsp + 0x40)
	pushw wa                                ; push wa
	call HDAE5000_IToA
	lda xwa, (xsp + 0x20)
	push xwa
	call HDAE5000_StrLen
	pushw hl                                ; push hl
	lda xwa, (xsp + 0x26)
	push xwa
	lda xwa, (0x22b35a:24)
	push xwa
	call HDAE5000_MemCopy
	pushw 0x000a		; push 0x000A
	lda xwa, (xsp + 0x30)
	push xwa
	ld wa, (xsp + 0x58)
	pushw wa                                ; push wa
	call HDAE5000_IToA
	lda xsp, (xsp + 0x1e)
	lda xwa, (xsp + 0x18)
	push xwa
	call HDAE5000_StrLen
	pushw hl                                ; push hl
	lda xwa, (xsp + 0x1e)
	push xwa
	lda xwa, (0x22b381:24)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0e)
	lda xwa, (xsp + 0x28)
	call HDAE5000_HD_GetDiskUsage
	pushw 0x0010
	pushw 0x0000
	lda xwa, (xsp + 0x1c)
	push xwa
	call HDAE5000_MemFill			; HDAE5000_MemFill
	lda xbc, (xsp + 0x30)
	lda xwa, (xsp + 0x14)
	call HDAE5000_ULongToFloat
	lda xbc, (xsp + 0x14)
	lda xde, (HDAE5000_Float_100_DriveInfo:24)
	lda xwa, (xsp + 0x14)
	call HDAE5000_FloatDiv
	lda xbc, (xsp + 0x14)
	lda xwa, (xsp + 0x18)
	call HDAE5000_FloatToDouble
	lda xiy, (xsp + 0x18)
	ld xix, (xiy + 0x04)
	push xix
	ld xix, (xiy)
	push xix
	pushw 0x002e		; push 0x002E -- high half of HDAE5000_Fmt_6_1f
	pushw 0x2cbe		; push 0x2CBE		; low half of HDAE5000_Fmt_6_1f
	lda xwa, (xsp + 0x2c)
	push xwa
	call HDAE5000_SPrintf
	lda xwa, (xsp + 0x30)
	push xwa
	call HDAE5000_StrLen
	lda xsp, (xsp + 0x1c)
	pushw hl                                ; push hl
	lda xwa, (xsp + 0x1a)
	push xwa
	lda xwa, (0x22b3a8:24)
	push xwa
	call HDAE5000_MemCopy
	pushw 0x0010
	pushw 0x0000
	lda xwa, (xsp + 0x26)
	push xwa
	call HDAE5000_MemFill
	lda xsp, (xsp + 0x12)
	lda xbc, (xsp + 0x2c)
	lda xwa, (xsp + 0x0c)
	call HDAE5000_ULongToFloat
	lda xbc, (xsp + 0x0c)
	lda xde, (HDAE5000_Float_100_DriveInfo_2:24)
	lda xwa, (xsp + 0x0c)
	call HDAE5000_FloatDiv
	lda xbc, (xsp + 0x0c)
	lda xwa, (xsp + 0x10)
	call HDAE5000_FloatToDouble
	lda xiy, (xsp + 0x10)
	ld xix, (xiy + 0x04)
	push xix
	ld xix, (xiy)
	push xix
	pushw 0x002e		; push 0x002E -- high half of HDAE5000_Fmt_6_1f_SetupPage_BuildDriveInfo
	pushw 0x2cc4		; push 0x2CC4		; low half of HDAE5000_Fmt_6_1f_SetupPage_BuildDriveInfo
	lda xwa, (xsp + 0x24)
	push xwa
	call HDAE5000_SPrintf
	lda xwa, (xsp + 0x28)
	push xwa
	call HDAE5000_StrLen
	pushw hl                                ; push hl
	lda xwa, (xsp + 0x2e)
	push xwa
	lda xwa, (0x22b3cf:24)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x1e)
	pushw 0x0010
	pushw 0x0000
	lda xwa, (xsp + 0x1c)
	push xwa
	call HDAE5000_MemFill
	lda xbc, (xsp + 0x3c)
	lda xwa, (xsp + 0x14)
	call HDAE5000_ULongToFloat
	lda xbc, (xsp + 0x14)
	lda xde, (HDAE5000_Float_100_DriveInfo_3:24)
	lda xwa, (xsp + 0x14)
	call HDAE5000_FloatDiv
	lda xbc, (xsp + 0x14)
	lda xwa, (xsp + 0x18)
	call HDAE5000_FloatToDouble
	lda xiy, (xsp + 0x18)
	ld xix, (xiy + 0x04)
	push xix
	ld xix, (xiy)
	push xix
	pushw 0x002e		; push 0x002E -- high half of HDAE5000_Fmt_6_1f_SetupPage_BuildDriveInfo_2
	pushw 0x2cca		; push 0x2CCA		; low half of HDAE5000_Fmt_6_1f_SetupPage_BuildDriveInfo_2
	lda xwa, (xsp + 0x2c)
	push xwa
	call HDAE5000_SPrintf
	lda xwa, (xsp + 0x30)
	push xwa
	call HDAE5000_StrLen
	lda xsp, (xsp + 0x1c)
	pushw hl                                ; push hl
	lda xwa, (xsp + 0x1a)
	push xwa
	lda xwa, (0x22b3f6:24)
	push xwa
	call HDAE5000_MemCopy
	pushw 0x0010
	pushw 0x0000
	lda xwa, (xsp + 0x26)
	push xwa
	call HDAE5000_MemFill
	lda xsp, (xsp + 0x12)
	lda xwa, (xsp + 0x18)
	calr HDAE5000_CopyVersionString
	lda xwa, (xsp + 0x18)
	push xwa
	call HDAE5000_StrLen
	pushw hl                                ; push hl
	lda xwa, (xsp + 0x1e)
	push xwa
	lda xwa, (0x22b41d:24)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0e)
	; Register partition display handler
	lda xwa, (0x22b2f6:24)
	ld xde, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_ApPostEvent)             ; ld XHL, (XWA + 0x0124)
	ld xwa, HDAE5000_OBJ_HD_INFO_LIST
	ld xbc, EVT_HDAE_SET_STR_ADR
	call (xhl)
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_ApPostEvent)
	ld xwa, HDAE5000_OBJ_HD_INFO_LIST
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xffffffff
	call (xhl)
	lda xsp, (xsp + 0x6c)		; deallocate stack frame
	ret
	;
	; Part 2: Event handler (0x286502)
HDAE5000_SetupP2SwCatch:
	; registered as "SetupP2SwCatch" in HDAE5000_ScreenProc_Table
	cp xbc, EVT_SW_IN
	jrl nz, .LHD_PS__exit
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld_sril xix, (xwa + RootFn_SendEvent)             ; ld XIX, (XWA + 0x0100)
	ld xwa, 0x02600024
	ld xbc, EVT_MAKE_EDIT_SW_ID
	call (xix)
	; Check return value
	cp xhl, 0x0000000c
	jrl z, .LHD_PS__case_0c
	cp xhl, 0x00000009
	jr z, .LHD_PS__case_09
	cp xhl, 0x0000008c
	jrl nz, .LHD_PS__exit
	; Case 0x8C: update display with error code
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_ApPostEvent)
	ld xwa, HDAE5000_OBJ_HD_PLEASE
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	call (xhl)
	ld wa, 0:i3
	call HDAE5000_HD_StoreSettings
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_ApPostEvent)
	ld xwa, HDAE5000_OBJ_SETUPS_TOOLS
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call (xhl)
	jr t, .LHD_PS__exit
.LHD_PS__case_09:			; case 0x09: format and validate
	pushw 0x000a		; push 0x000A
	pushw 0x0000
	lda xwa, (0x22ad9c:24)
	push xwa
	call HDAE5000_MemFill
	inc 8, xsp			; deallocate 8 bytes
	cp (HDAE5000_RAM_WriteProtect:24), 0x00
	jr nz, .LHD_PS__exit
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_ApPostEvent)
	ld xwa, HDAE5000_OBJ_ATTEN_HD_FORMAT
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call (xhl)
	jr t, .LHD_PS__exit
.LHD_PS__case_0c:			; case 0x0C: recursive re-setup
	calr HDAE5000_SetupPage_BuildDriveInfo
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_ApPostEvent)
	ld xwa, HDAE5000_OBJ_SETUP_HDINFO
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call (xhl)
.LHD_PS__exit:
	ld xhl, 0:i3
	ret

HDAE5000_FormatDialog_CodeDigit:	; 0x2865DE (1098 bytes)
	; Part 1: CHS digit accumulator — stores digit, checks for 6-digit match
	; (Not CHS: the digits typed on the HD-format attention dialog are
	; collected at 0x22AD9E; after six, "050354" (0x2E1E2C) gives IZ = 2,
	; "965768" (0x2E1E34) gives 3, anything else 1.  What 2 and 3 unlock is
	; decided by the caller, AttenHDFormatSwCatch.)
	dec 8, xsp			; alloc 4 bytes
	pushw iz                                ; push iz (compact)
	pushw 0x000a
	lda xbc, (xsp + 0x04)
	push xbc
	pushw wa                                ; push wa (compact)
	call HDAE5000_IToA
	inc 8, xsp			; dealloc 4 bytes
	ld a, (0x22ad9c:24); A = current count
	extz wa
	ld bc, wa
	inc 2, bc			; BC = count + 2
	lda xde, (0x22ad9c:24); XDE = buffer base
	ld a, (xsp + 0x02)		; A = digit param
	stb_dri a, 0x07, 0xE8, 0xE4	; ld (XDE+BC), A
	inc	1, (0x22AD9C:24)
	cp (0x22ad9c:24), 0x06; count == 6?
	jr nz, .LCHSC__not_full
	; 6 digits entered — match against patterns
	pushw 0x002e
	pushw 0x1e2c		; low half of HDAE5000_Str_050354
	lda xwa, (0x22ad9e:24)
	push xwa
	call HDAE5000_StrPrefixCmp			; string compare
	inc 8, xsp
	cp hl, 0:i3
	jr nz, .LCHSC__try2
	ld iz, 2:i3			; match pattern 1 → IZ=2
	jr t, .LCHSC__clear
.LCHSC__try2:
	pushw 0x002e
	pushw 0x1e34		; low half of HDAE5000_Str_965768
	lda xwa, (0x22ad9e:24)
	push xwa
	call HDAE5000_StrPrefixCmp			; string compare
	inc 8, xsp
	cp hl, 0:i3
	jr nz, .LCHSC__no_match
	ld iz, 3:i3			; match pattern 2 → IZ=3
	jr t, .LCHSC__clear
.LCHSC__no_match:
	ld iz, 1:i3			; no match → IZ=1
.LCHSC__clear:
	pushw 0x000a
	pushw 0x0000
	lda xwa, (0x22ad9c:24)
	push xwa
	call HDAE5000_MemFill			; MemFill (clear buffer)
	inc 8, xsp
	jr t, .LCHSC__return
.LCHSC__not_full:
	ld iz, 0:i3			; not full → IZ=0
.LCHSC__return:
	ld hl, iz			; return value in HL
	popw iz                                 ; pop iz (compact)
	inc 8, xsp			; dealloc 4 bytes
	ret
	;
	; Part 2: Event handler (0x286666)
HDAE5000_AttenHDFormatSwCatch:
	; registered as "AttenHDFormatSwCatch" in HDAE5000_ObjHandler_Table
	dec 6, xsp			; alloc 24 bytes
	push xiz
	ld xiz, xde			; XIZ = param
	ld (xsp + 0x06), xwa		; save event code
	ld xwa, xbc			; XWA = event code
	cp xwa, EVT_HDAE_TIMER_BACK
	jrl z, .LCHSC__ev_close
	cp xwa, EVT_SW_IN
	jr z, .LCHSC__ev_key
	cp xwa, EVT_DRAW
	jr z, .LCHSC__ev_0d
	cp xwa, EVT_ARE_YOU_CLASS_PROC
	jr z, .LCHSC__ev_85
	; Default: pass through to registered handler
	ld xwa, (xsp + 0x06)
	ld xde, xiz
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xhl, (xhl + WS_RootFnTable)             ; XHL = (XHL + 0x0E0A)
	ld_sril xix, (xhl + RootFn_InheritedProc)             ; XIX = (XHL + 0x00DC)
	call (xix)
	jrl t, .LCHSC__exit
.LCHSC__ev_85:				; Event 0x01E00085
	ld xhl, 1:i3
	jrl t, .LCHSC__exit
.LCHSC__ev_0d:				; Event 0x01C0000D
	ld xwa, (xsp + 0x06)
	ld xde, xiz
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xhl, (xhl + WS_RootFnTable)
	ld_sril xhl, (xhl + RootFn_InheritedProc)             ; XHL = (XHL + 0x00DC)
	call (xhl)
	lda xwa, (HDAE5000_Str_FMT:24)
	ld xbc, xwa
	ld xwa, (xsp + 0x06)
	ld xde, xbc
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_RootFnTable)             ; XBC = (XBC + 0x0E0A)
	ld_sril xhl, (xbc + RootFn_SendEvent)             ; XHL = (XBC + 0x0100)
	ld xbc, EVT_PARA_DRAW
	call (xhl)
	ld xhl, 0:i3
	jrl t, .LCHSC__exit
.LCHSC__ev_key:				; Event 0x01C00007
	ldw	(xsp+4), 0x0000
	ld xde, xiz
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)             ; XWA = (XWA + 0x0E0A)
	ld_sril xix, (xwa + RootFn_SendEvent)             ; XIX = (XWA + 0x0100)
	ld xwa, 0x02600024
	ld xbc, EVT_MAKE_EDIT_SW_ID
	call (xix)
	ld xwa, xhl
	cp xwa, 0x00000007
	jrl ugt, .LCHSC__post_switch		; > 7 → skip
	add xwa, xwa				; XWA * 2
	add xwa, HDAE5000_AttenHDFormatSwCatch_CaseTable			; jump table base
	ld wa, (xwa)				; WA = offset
	lda xix, (HDAE5000_AttenHDFormatSwCatch_Case0:24); dispatch base
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp (XIX + WA)
	; Case 0: bit test → call with 0/1
HDAE5000_AttenHDFormatSwCatch_Case0:
	bit 0x07, iz
	jr z, .LCHSC__c0_even
	ld wa, 0:i3
	jr t, .LCHSC__c0_call
.LCHSC__c0_even:
	ld wa, 1:i3
.LCHSC__c0_call:
	calr HDAE5000_FormatDialog_CodeDigit		; recursive
	ld (xsp + 0x04), hl
	jr t, .LCHSC__post_switch
	; Case 1: bit test → call with 2/3
HDAE5000_AttenHDFormatSwCatch_Case1:
	bit 0x07, iz
	jr z, .LCHSC__c1_even
	ld wa, 2:i3
	jr t, .LCHSC__c1_call
.LCHSC__c1_even:
	ld wa, 3:i3
.LCHSC__c1_call:
	calr HDAE5000_FormatDialog_CodeDigit
	ld (xsp + 0x04), hl
	jr t, .LCHSC__post_switch
	; Case 2: bit test → call with 4/5
HDAE5000_AttenHDFormatSwCatch_Case2:
	bit 0x07, iz
	jr z, .LCHSC__c2_even
	ld wa, 4:i3
	jr t, .LCHSC__c2_call
.LCHSC__c2_even:
	ld wa, 5:i3
.LCHSC__c2_call:
	calr HDAE5000_FormatDialog_CodeDigit
	ld (xsp + 0x04), hl
	jr t, .LCHSC__post_switch
	; Case 3: bit test → call with 6/7
HDAE5000_AttenHDFormatSwCatch_Case3:
	bit 0x07, iz
	jr z, .LCHSC__c3_even
	ld wa, 6:i3
	jr t, .LCHSC__c3_call
.LCHSC__c3_even:
	ld wa, 7:i3
.LCHSC__c3_call:
	calr HDAE5000_FormatDialog_CodeDigit
	ld (xsp + 0x04), hl
	jr t, .LCHSC__post_switch
	; Case 4: bit test → call with 8/9 (ldw for values > 7)
HDAE5000_AttenHDFormatSwCatch_Case4:
	bit 0x07, iz
	jr z, .LCHSC__c4_even
	ldw wa, 0x0008
	jr t, .LCHSC__c4_call
.LCHSC__c4_even:
	ldw wa, 0x0009
.LCHSC__c4_call:
	calr HDAE5000_FormatDialog_CodeDigit
	ld (xsp + 0x04), hl
	jr t, .LCHSC__post_switch
	; Case 6/7: clear buffer + display setup
HDAE5000_AttenHDFormatSwCatch_Case6:
	pushw 0x000a
	pushw 0x0000
	lda xwa, (0x22ad9c:24)
	push xwa
	call HDAE5000_MemFill			; MemFill
	inc 8, xsp
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_PostEvent)             ; XHL = (XWA + 0x0104)
	ld xwa, HDAE5000_OBJ_SETUPS_TOOLS
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call (xhl)
	; Post-switch: dispatch on result
.LCHSC__post_switch:
	ld wa, (xsp + 0x04)
	cp wa, 3:i3
	jrl z, .LCHSC__res3
	cp wa, 2:i3
	jr z, .LCHSC__res2
	cp wa, 1:i3
	jrl nz, .LCHSC__done
	; Result 1: setup with 0x007f02cb + two dialog boxes
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld_sril xhl, (xwa + RootFn_SendEvent)             ; XHL = (XWA + 0x0100)
	ld xwa, HDAE5000_OBJ_AGAIN_HD_FORMAT
	ld xbc, EVT_SHOW
	ld xde, 3:i3
	call (xhl)
	ld xwa, EVT_HDAE_TIMER_BACK
	push xwa
	ld xwa, HDAE5000_OBJ_ATTEN_HD_FORMAT
	push xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_KillApTimer)             ; XHL = (XWA + 0x0418)
	ld xwa, 0x0000014d
	ld xbc, HDAE5000_OBJ_AGAIN_HD_FORMAT_CATCH
	ld xde, 0xffffffff
	call (xhl)
	ld xwa, EVT_HDAE_TIMER_BACK
	push xwa
	ld xwa, HDAE5000_OBJ_ATTEN_HD_FORMAT
	push xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_SetApTimer)             ; XHL = (XWA + 0x0410)
	ld xwa, 0x0000014d
	ld xbc, HDAE5000_OBJ_AGAIN_HD_FORMAT_CATCH
	ld xde, 0xffffffff
	call (xhl)
	jrl t, .LCHSC__done
.LCHSC__res2:				; Result 2: display setup + validate + FS init
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld_sril xhl, (xwa + RootFn_SendEvent)
	ld xwa, HDAE5000_OBJ_WAIT_HD_FORMAT
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call (xhl)
	calr HDAE5000_YieldUntilSem1Zero
	ld wa, 1:i3
	call HDAE5000_HD_FormatDrive
	cp hl, 0:i3
	jr nz, .LCHSC__res2_err
	; Success: display + FS read
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_PostEvent)
	ld xwa, HDAE5000_OBJ_SETUPS_TOOLS
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call (xhl)
	ld xwa, HDAE5000_OBJ_SEL_DIR
	calr HDAE5000_DirList_BuildPage
	ld wa, 0:i3
	ld bc, 0:i3
	calr HDAE5000_SongScreen_Refresh
	calr HDAE5000_FlsList_BuildPage
	ld wa, 0:i3
	ld bc, 2:i3
	calr HDAE5000_FlsScreen_Refresh
	jrl t, .LCHSC__done
.LCHSC__res2_err:			; Error: display error + two dialog boxes
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_PostEvent)
	ld xwa, HDAE5000_OBJ_ERR_HD_FORMAT
	ld xbc, EVT_SHOW
	ld xde, 3:i3
	call (xhl)
	ld xwa, EVT_HDAE_TIMER_BACK
	push xwa
	ld xwa, HDAE5000_OBJ_ATTEN_HD_FORMAT
	push xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_KillApTimer)
	ld xwa, 0x0000014d
	ld xbc, HDAE5000_OBJ_ERR_HD_FORMAT_CATCH
	ld xde, 0xffffffff
	call (xhl)
	ld xwa, EVT_HDAE_TIMER_BACK
	push xwa
	ld xwa, HDAE5000_OBJ_ATTEN_HD_FORMAT
	push xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_SetApTimer)
	ld xwa, 0x0000014d
	ld xbc, HDAE5000_OBJ_ERR_HD_FORMAT_CATCH
	ld xde, 0xffffffff
	call (xhl)
	jrl t, .LCHSC__done
.LCHSC__res3:				; Result 3: set flags + validate + check match
	ld (HDAE5000_RAM_QuickLoadMode:24), 0x01
	ld (HDAE5000_RAM_LoadByNumberMode:24), 0x01
	ld (HDAE5000_RAM_JumpAfterLoad:24), 0x01
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld_sril xhl, (xwa + RootFn_SendEvent)
	ld xwa, HDAE5000_OBJ_WAIT_TR0_RECOVER
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call (xhl)
	calr HDAE5000_YieldUntilSem1Zero
	ld wa, 0:i3
	call HDAE5000_HD_StoreSettings
	cp hl, 0xffff
	jr z, .LCHSC__res3_nomatch
	; Match found
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_PostEvent)
	ld xwa, HDAE5000_OBJ_SETUPS_TOOLS
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call (xhl)
	jrl t, .LCHSC__done
.LCHSC__res3_nomatch:			; No match — setup error display + dialog boxes
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_PostEvent)
	ld xwa, HDAE5000_OBJ_ERR_SAVE
	ld xbc, EVT_SHOW
	ld xde, 3:i3
	call (xhl)
	ld xwa, HDAE5000_OBJ_ERR_SAVE_EXIT
	ld xbc, HDAE5000_OBJ_ATTEN_HD_FORMAT
	calr HDAE5000_UiObj_SetCaption
	ld xwa, EVT_HDAE_TIMER_BACK
	push xwa
	ld xwa, HDAE5000_OBJ_ATTEN_HD_FORMAT
	push xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_KillApTimer)
	ld xwa, 0x0000014d
	ld xbc, HDAE5000_OBJ_ERR_SAVE_CATCH
	ld xde, 0xffffffff
	call (xhl)
	ld xwa, EVT_HDAE_TIMER_BACK
	push xwa
	ld xwa, HDAE5000_OBJ_ATTEN_HD_FORMAT
	push xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_SetApTimer)
	ld xwa, 0x0000014d
	ld xbc, HDAE5000_OBJ_ERR_SAVE_CATCH
	ld xde, 0xffffffff
	call (xhl)
.LCHSC__done:				; Common exit
	ld xhl, 0:i3
	jr t, .LCHSC__exit
.LCHSC__ev_close:			; Event 0x01CA0002: close display
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_PostEvent)
	ld xwa, HDAE5000_OBJ_ATTEN_HD_FORMAT
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call (xhl)
	ld xhl, 0:i3
.LCHSC__exit:
	pop xiz
	inc 6, xsp			; dealloc 24 bytes
	ret

HDAE5000_Lbn_StepDigit:	; 0x286A28 (1064 bytes)
	; Load-by-number: step the digit at position 0x22AA5C of the number
	; being entered (hundreds/tens/units of the directory, clamped to
	; 0..120, then the song) by the key value on the stack, and redraw
	; (HDAE5000_Lbn_ShowEntry).  (Was "read sectors from HD ... CHS input
	; state machine".)
	pushw iz                                ; push iz (compact)
	ld hl, (xsp + 0x06)		; HL = param from stack
	ld de, wa			; DE = input digit
	ld wa, (HDAE5000_RAM_LbnDigitPos:24); load current state
	cp wa, 5:i3			; state >= 6? (unsigned)
	jrl ugt, .LHD_SR__apply	; yes → apply values
	add wa, wa			; state * 2
	lda xix, (HDAE5000_Lbn_StepDigit_CaseTable:24); jump table base
	ldw_sri wa, 0x07, 0xF0, 0xE0	; ld WA, (XIX + WA)
	lda xix, (HDAE5000_Lbn_StepDigit_Case0:24); dispatch base
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp (XIX + WA)
	; Case 0 (offset 0x0000): jump to FS_Init directly
HDAE5000_Lbn_StepDigit_Case0:
	jrl t, .LHD_SR__cleanup
	; Case 1 (offset 0x0003): cylinder digit * 100
HDAE5000_Lbn_StepDigit_Case1:
	ld wa, hl
	muls wa, 0x0064			; WA = digit * 100
	add de, wa			; DE += WA
	cp de, 0x0064			; DE >= 100?
	jr lt, .LHD_SR__c1_lo
	ldw de, 0x0064			; clamp to 100
	jr t, .LHD_SR__apply
.LHD_SR__c1_lo:
	cp de, 0:i3			; DE > 0?
	jr gt, .LHD_SR__apply
	ld de, 0:i3			; clamp to 0
	jr t, .LHD_SR__apply
	; Case 2 (offset 0x001E): cylinder digit * 10
HDAE5000_Lbn_StepDigit_Case2:
	ld wa, hl
	muls wa, 0x000a			; WA = digit * 10
	add de, wa
	cp de, 0x0078			; DE >= 120?
	jr lt, .LHD_SR__c2_lo
	ldw de, 0x0078			; clamp to 120
	jr t, .LHD_SR__apply
.LHD_SR__c2_lo:
	cp de, 1:i3			; DE > 1?
	jr gt, .LHD_SR__apply
	ld de, 0:i3
	jr t, .LHD_SR__apply
	; Case 3 (offset 0x0039): cylinder unit digit
HDAE5000_Lbn_StepDigit_Case3:
	add de, hl
	cp de, 0x0078
	jr le, .LHD_SR__c3_lo
	ldw de, 0x0078
	jr t, .LHD_SR__apply
.LHD_SR__c3_lo:
	cp de, 0:i3
	jr gt, .LHD_SR__apply
	ld de, 1:i3
	jr t, .LHD_SR__apply
	; Case 4 (offset 0x004E): head digit * 10
HDAE5000_Lbn_StepDigit_Case4:
	ld wa, hl
	muls wa, 0x000a
	add bc, wa
	cp bc, 0x000a			; BC >= 10?
	jr lt, .LHD_SR__c4_lo
	ldw bc, 0x000a
	jr t, .LHD_SR__apply
.LHD_SR__c4_lo:
	cp bc, 0:i3
	jr gt, .LHD_SR__apply
	ld bc, 0:i3
	jr t, .LHD_SR__apply
	; Case 5 (offset 0x0069): head unit digit
HDAE5000_Lbn_StepDigit_Case5:
	add bc, hl
	cp bc, 0x0010			; BC >= 16?
	jr le, .LHD_SR__c5_lo
	ldw bc, 0x0010
	jr t, .LHD_SR__apply
.LHD_SR__c5_lo:
	cp bc, 0:i3
	jr gt, .LHD_SR__apply
	ld bc, 1:i3
.LHD_SR__apply:				; store results
	ld (HDAE5000_RAM_LbnDir:24), de; store cylinder
	ld (HDAE5000_RAM_LbnSong:24), bc; store head
	cpw (HDAE5000_RAM_LbnDigitPos:24), 0x0005; state == 5?
	jr nz, .LHD_SR__fs_init
	; State 5: complete — do table lookup and seek
	ld wa, (HDAE5000_RAM_LbnDir:24)
	dec 1, wa
	ld (HDAE5000_RAM_CurDir:24), wa
	ld wa, (HDAE5000_RAM_LbnSong:24)
	dec 1, wa
	ld (HDAE5000_RAM_CurSong:24), wa
	ld wa, (HDAE5000_RAM_CurDir:24)
	ld bc, (HDAE5000_RAM_CurSong:24)
	call HDAE5000_Song_PartMask
	ld iz, hl
	ld wa, iz
	cp wa, 0xffff
	jr z, .LHD_SR__no_match
	; Match found — copy data and seek
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	ld bc, iz
	pushw 0x0002
	lda xde, (HDAE5000_TypeSel_TemplateBlank:24)
	calr HDAE5000_TypeSel_Init
	ld bc, (HDAE5000_RAM_CurDir:24)
	ld de, (HDAE5000_RAM_CurSong:24)
	ld wa, iz
	pushw wa                                ; push wa (compact)
	ld xwa, HDAE5000_OBJ_LBN_OPTION
	calr HDAE5000_PartList_Build
	jr t, .LHD_SR__fs_init
.LHD_SR__no_match:			; No match — clear and seek with 0xFFFF
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	pushw 0x0002
	lda xde, (HDAE5000_TypeSel_TemplateBlank:24)
	ld bc, 0:i3
	calr HDAE5000_TypeSel_Init
	pushw 0xffff		; push 0xFFFF
	ld xwa, HDAE5000_OBJ_LBN_OPTION
	ldw bc, 0xffff
	ldw de, 0xffff
	calr HDAE5000_PartList_Build
.LHD_SR__fs_init:			; Re-init filesystem display
	pushw 0x0001
	ld wa, (HDAE5000_RAM_LbnDir:24)
	ld bc, (HDAE5000_RAM_LbnSong:24)
	ld de, (HDAE5000_RAM_LbnDigitPos:24)
	calr HDAE5000_Lbn_ShowEntry
.LHD_SR__cleanup:
	popw iz                                 ; pop iz (compact)
	retd 0x0002			; return, dealloc 2 bytes
	;
	; Part 2: Event handler A (0x286B72)
HDAE5000_LBNPage1SwCatch:
	; registered as "LBNPage1SwCatch" in HDAE5000_ObjHandler_Table
	dec 8, xsp			; alloc 8 bytes
	push xiz
	ld (xsp + 0x04), xde
	ld (xsp + 0x08), xbc
	ld xiz, xwa
	ld xwa, (xsp + 0x08)		; XWA = event code
	cp xwa, EVT_SW_IN
	jr z, .LHD_SR__a_evt07
	cp xwa, EVT_DRAW
	jr z, .LHD_SR__a_evt0d
	cp xwa, EVT_ARE_YOU_CLASS_PROC
	jrl nz, .LHD_SR__a_exit
	ld xhl, 1:i3			; event 0x85: XHL = 1
	jrl t, .LHD_SR__a_epilogue
.LHD_SR__a_evt0d:			; event 0x0D: display update
	ld xwa, xiz
	ld xbc, (xsp + 0x08)
	ld xde, (xsp + 0x04)
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xhl, (xhl + WS_RootFnTable)
	ld_sril xhl, (xhl + RootFn_InheritedProc)
	call (xhl)
	lda xwa, (HDAE5000_Str_LBNS:24)
	ld xbc, xwa
	ld xwa, xiz
	ld xde, xbc
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_RootFnTable)
	ld_sril xhl, (xbc + RootFn_SendEvent)
	ld xbc, EVT_PARA_DRAW
	call (xhl)
	ld xhl, 0:i3
	jrl t, .LHD_SR__a_epilogue
.LHD_SR__a_evt07:			; event 0x07: jump table dispatch
	ld xde, (xsp + 0x04)
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld_sril xix, (xwa + RootFn_SendEvent)
	ld xwa, 0x02600024
	ld xbc, EVT_MAKE_EDIT_SW_ID
	call (xix)
	ld xwa, xhl
	cp xwa, 0x0000000c		; case > 12?
	jrl ugt, .LHD_SR__a_exit
	add xwa, xwa			; index * 2
	add xwa, HDAE5000_LBNPage1SwCatch_CaseTable
	ld wa, (xwa)
	lda xix, (HDAE5000_LBNPage1SwCatch_Case12:24); dispatch base
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp (XIX + WA)
	; Case 0: re-init FS
HDAE5000_LBNPage1SwCatch_Case12:
	pushw 0x0001
	ld wa, 0:i3
	ld bc, 0:i3
	ld de, 6:i3
	calr HDAE5000_Lbn_ShowEntry
	jrl t, .LHD_SR__a_exit
	; Case 1: toggle read/write direction
HDAE5000_LBNPage1SwCatch_Case5:
	ld xwa, (xsp + 0x04)
	bit 0x07, wa			; bit 7?
	jr nz, .LHD_SR__a_c1_set
	ld wa, 1:i3
	jr t, .LHD_SR__a_c1_push
.LHD_SR__a_c1_set:
	ldw wa, 0xffff
.LHD_SR__a_c1_push:
	pushw wa                                ; push wa
	ld wa, (HDAE5000_RAM_LbnDir:24)
	ld bc, (HDAE5000_RAM_LbnSong:24)
	ld de, (HDAE5000_RAM_LbnDigitPos:24)
	calr HDAE5000_Lbn_StepDigit	; recursive call
	jrl t, .LHD_SR__a_exit
	; Case 2: sector write (BC=0 or 1)
HDAE5000_LBNPage1SwCatch_Case0:
	ld xwa, (xsp + 0x04)
	bit 0x07, wa
	jr z, .LHD_SR__a_c2b
	ld xwa, xiz
	ld bc, 0:i3
	calr HDAE5000_Lbn_TypeDigit
	jr t, .LHD_SR__a_exit
.LHD_SR__a_c2b:
	ld xwa, xiz
	ld bc, 1:i3
	calr HDAE5000_Lbn_TypeDigit
	jr t, .LHD_SR__a_exit
	; Case 3: sector write (BC=2 or 3)
HDAE5000_LBNPage1SwCatch_Case1:
	ld xwa, (xsp + 0x04)
	bit 0x07, wa
	jr z, .LHD_SR__a_c3b
	ld xwa, xiz
	ld bc, 2:i3
	calr HDAE5000_Lbn_TypeDigit
	jr t, .LHD_SR__a_exit
.LHD_SR__a_c3b:
	ld xwa, xiz
	ld bc, 3:i3
	calr HDAE5000_Lbn_TypeDigit
	jr t, .LHD_SR__a_exit
	; Case 4: sector write (BC=4 or 5)
HDAE5000_LBNPage1SwCatch_Case2:
	ld xwa, (xsp + 0x04)
	bit 0x07, wa
	jr z, .LHD_SR__a_c4b
	ld xwa, xiz
	ld bc, 4:i3
	calr HDAE5000_Lbn_TypeDigit
	jr t, .LHD_SR__a_exit
.LHD_SR__a_c4b:
	ld xwa, xiz
	ld bc, 5:i3
	calr HDAE5000_Lbn_TypeDigit
	jr t, .LHD_SR__a_exit
	; Case 5: sector write (BC=6 or 7)
HDAE5000_LBNPage1SwCatch_Case3:
	ld xwa, (xsp + 0x04)
	bit 0x07, wa
	jr z, .LHD_SR__a_c5b
	ld xwa, xiz
	ld bc, 6:i3
	calr HDAE5000_Lbn_TypeDigit
	jr t, .LHD_SR__a_exit
.LHD_SR__a_c5b:
	ld xwa, xiz
	ld bc, 7:i3
	calr HDAE5000_Lbn_TypeDigit
	jr t, .LHD_SR__a_exit
	; Case 6: sector write (BC=8 or 9)
HDAE5000_LBNPage1SwCatch_Case4:
	ld xwa, (xsp + 0x04)
	bit 0x07, wa
	jr z, .LHD_SR__a_c6b
	ld xwa, xiz
	ldw bc, 0x0008
	calr HDAE5000_Lbn_TypeDigit
	jr t, .LHD_SR__a_exit
.LHD_SR__a_c6b:
	ld xwa, xiz
	ldw bc, 0x0009
	calr HDAE5000_Lbn_TypeDigit
.LHD_SR__a_exit:			; common exit for handler A
	ld xwa, xiz
	ld xbc, (xsp + 0x08)
	ld xde, (xsp + 0x04)
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xhl, (xhl + WS_RootFnTable)
	ld_sril xix, (xhl + RootFn_InheritedProc)
	call (xix)
.LHD_SR__a_epilogue:
	pop xiz
	inc 8, xsp
	ret
	;
	; Part 3: Event handler B (0x286CED)
HDAE5000_LBNLoadSwCatch:
	; registered as "LBNLoadSwCatch" in HDAE5000_ObjHandler_Table
	dec 8, xsp
	push xiz
	ld (xsp + 0x04), xde
	ld xiz, xbc			; save event code in XIZ
	ld (xsp + 0x08), xwa
	ld xwa, xiz			; XWA = event code
	cp xwa, EVT_SW_IN
	jrl z, .LHD_SR__b_evt07
	cp xwa, EVT_DRAW
	jr z, .LHD_SR__b_evt0d
	cp xwa, EVT_ARE_YOU_CLASS_PROC
	jr z, .LHD_SR__b_evt85
	cp xwa, EVT_SHOW
	jrl nz, .LHD_SR__b_exit
	; Event 0x01: table lookup and copy
	ld wa, (HDAE5000_RAM_CurDir:24)
	ld bc, (HDAE5000_RAM_CurSong:24)
	call HDAE5000_Song_PartMask
	ld wa, hl
	cp wa, 0xffff
	jr z, .LHD_SR__b_nomatch
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	pushw 0x0002
	ld bc, hl
	lda xde, (HDAE5000_TypeSel_TemplateBlank:24)
	calr HDAE5000_TypeSel_Init
	jrl t, .LHD_SR__b_exit
.LHD_SR__b_nomatch:
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	pushw 0x0002
	lda xde, (HDAE5000_TypeSel_TemplateBlank:24)
	ld bc, 0:i3
	calr HDAE5000_TypeSel_Init
	jrl t, .LHD_SR__b_exit
.LHD_SR__b_evt85:			; event 0x85: XHL = 1
	ld xhl, 1:i3
	jrl t, .LHD_SR__b_epilogue
.LHD_SR__b_evt0d:			; event 0x0D: display update
	ld xwa, (xsp + 0x08)
	ld xbc, xiz
	ld xde, (xsp + 0x04)
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xhl, (xhl + WS_RootFnTable)
	ld_sril xhl, (xhl + RootFn_InheritedProc)
	call (xhl)
	lda xwa, (HDAE5000_Str_LBN:24)
	ld xbc, xwa
	ld xwa, (xsp + 0x08)
	ld xde, xbc
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xbc, (xbc + WS_RootFnTable)
	ld_sril xhl, (xbc + RootFn_SendEvent)
	ld xbc, EVT_PARA_DRAW
	call (xhl)
	ld xhl, 0:i3
	jrl t, .LHD_SR__b_epilogue
.LHD_SR__b_evt07:			; event 0x07: sector operations
	ld xde, (xsp + 0x04)
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld_sril xix, (xwa + RootFn_SendEvent)
	ld xwa, 0x02600024
	ld xbc, EVT_MAKE_EDIT_SW_ID
	call (xix)
	cp xhl, 0x00000009
	jr z, .LHD_SR__b_check_state
	cp xhl, 0x00000008
	jr nz, .LHD_SR__b_exit
.LHD_SR__b_check_state:
	cpw (HDAE5000_RAM_LbnDigitPos:24), 0x0005; state == 5?
	jr nz, .LHD_SR__b_exit
	; State 5: display manager call + sector read
	pushw 0x0001
	ld xwa, HDAE5000_OBJ_LOAD_BY_NUM
	push xwa
	ld wa, (HDAE5000_RAM_CurDir:24)
	ld bc, (HDAE5000_RAM_CurSong:24)
	ld de, (HDAE5000_RAM_SaveOptions:24)
	calr HDAE5000_LoadSongWithUi
	pushw 0x0001
	ld wa, 0:i3
	ld bc, 0:i3
	ld de, 6:i3
	calr HDAE5000_Lbn_ShowEntry
	cp (HDAE5000_RAM_LyricJump:24), 0x02
	jr nz, .LHD_SR__b_exit
	ld wa, (HDAE5000_RAM_SaveOptions:24)
	and wa, 0x0100
	cp wa, 0x0100
	jr nz, .LHD_SR__b_exit
	; Flag set: register display handler
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_ApPostEvent)
	ld xwa, HDAE5000_OBJ_Tech_lyrics
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call (xhl)
.LHD_SR__b_exit:			; common exit
	ld xwa, (xsp + 0x08)
	ld xbc, xiz
	ld xde, (xsp + 0x04)
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xhl, (xhl + WS_RootFnTable)
	ld_sril xix, (xhl + RootFn_InheritedProc)
	call (xix)
.LHD_SR__b_epilogue:
	pop xiz
	inc 8, xsp
	ret

HDAE5000_Lbn_TypeDigit:	; 0x286E50 (646 bytes)
	; Load-by-number: type digit BC at position 0x22AA5C -- hundreds, tens
	; and units of the directory number 0x22AA5E, tens and units of the song
	; number 0x22AA60 -- redraw (HDAE5000_Lbn_ShowEntry) and after the last
	; digit load the song (HDAE5000_LoadSongWithUi).  (Was "write sectors
	; to HD".)
	; --- Prologue ---
	push xiz				; 3e
	ld	qiz, 0

	; --- Switch on state variable at 0x22AA5C ---
	ld wa, (HDAE5000_RAM_LbnDigitPos:24); d2 5c aa 22 20 — ld wa, (0x22aa5c)
	cp wa, 4:i3				; d8 dc
	jrl z, .Lsw_case4			; 76 xx xx
	cp wa, 3:i3				; d8 db
	jrl z, .Lsw_case3			; 76 xx xx
	cp wa, 2:i3				; d8 da
	jr z, .Lsw_case2			; 66 xx
	cp wa, 1:i3				; d8 d9
	jr z, .Lsw_case1			; 66 xx
	cp wa, 0:i3				; d8 d8
	jrl nz, .Lsw_exit			; 7e xx xx

	; === Case 0: initialize cylinder from BC*100, set state=1 ===
	ld wa, bc				; d9 88
	mul wa, 0x0064				; d8 08 64 00
	ld (HDAE5000_RAM_LbnDir:24), wa; f2 5e aa 22 50 — ld (0x22aa5e), wa
	ldw (HDAE5000_RAM_LbnSong:24), 0x0000; f2 60 aa 22 02 00 00
	ldw (HDAE5000_RAM_LbnDigitPos:24), 0x0001; f2 5c aa 22 02 01 00
	pushw 0x0001
	ld wa, (HDAE5000_RAM_LbnDir:24); d2 5e aa 22 20
	ld bc, (HDAE5000_RAM_LbnSong:24); d2 60 aa 22 21
	ld de, (HDAE5000_RAM_LbnDigitPos:24); d2 5c aa 22 22
	calr HDAE5000_Lbn_ShowEntry			; 1e xx xx
	ld	qiz, hl
	jrl t, .Lsw_exit			; 78 xx xx

	; === Case 1: add BC*10 to cylinder, set state=2 ===
.Lsw_case1:					; 0x286EA4
	ld wa, bc				; d9 88
	mul wa, 0x000a				; d8 08 0a 00
	add (HDAE5000_RAM_LbnDir:24), wa; d2 5e aa 22 88
	ldw (HDAE5000_RAM_LbnDigitPos:24), 0x0002; f2 5c aa 22 02 02 00
	pushw 0x0001
	ld wa, (HDAE5000_RAM_LbnDir:24); d2 5e aa 22 20
	ld bc, (HDAE5000_RAM_LbnSong:24); d2 60 aa 22 21
	ld de, (HDAE5000_RAM_LbnDigitPos:24); d2 5c aa 22 22
	calr HDAE5000_Lbn_ShowEntry			; 1e xx xx
	ld	qiz, hl
	jrl t, .Lsw_exit			; 78 xx xx

	; === Case 2: add BC to cylinder, set state=3 ===
.Lsw_case2:					; 0x286ED1
	add (HDAE5000_RAM_LbnDir:24), bc; d2 5e aa 22 89
	ldw (HDAE5000_RAM_LbnDigitPos:24), 0x0003; f2 5c aa 22 02 03 00
	pushw 0x0001
	ld wa, (HDAE5000_RAM_LbnDir:24); d2 5e aa 22 20
	ld bc, (HDAE5000_RAM_LbnSong:24); d2 60 aa 22 21
	ld de, (HDAE5000_RAM_LbnDigitPos:24); d2 5c aa 22 22
	calr HDAE5000_Lbn_ShowEntry			; 1e xx xx
	ld	qiz, hl
	jrl t, .Lsw_exit			; 78 xx xx

	; === Case 3: set head from BC*10, set state=4 ===
.Lsw_case3:					; 0x286EF8
	ld wa, bc				; d9 88
	mul wa, 0x000a				; d8 08 0a 00
	ld (HDAE5000_RAM_LbnSong:24), wa; f2 60 aa 22 50
	ldw (HDAE5000_RAM_LbnDigitPos:24), 0x0004; f2 5c aa 22 02 04 00
	pushw 0x0001
	ld wa, (HDAE5000_RAM_LbnDir:24); d2 5e aa 22 20
	ld bc, (HDAE5000_RAM_LbnSong:24); d2 60 aa 22 21
	ld de, (HDAE5000_RAM_LbnDigitPos:24); d2 5c aa 22 22
	calr HDAE5000_Lbn_ShowEntry			; 1e xx xx
	ld	qiz, hl
	jrl t, .Lsw_exit			; 78 xx xx

	; === Case 4: add BC to head, set state=5, then process ===
.Lsw_case4:					; 0x286F25
	add (HDAE5000_RAM_LbnSong:24), bc; d2 60 aa 22 89
	ldw (HDAE5000_RAM_LbnDigitPos:24), 0x0005; f2 5c aa 22 02 05 00
	pushw 0x0001
	ld wa, (HDAE5000_RAM_LbnDir:24); d2 5e aa 22 20
	ld bc, (HDAE5000_RAM_LbnSong:24); d2 60 aa 22 21
	ld de, (HDAE5000_RAM_LbnDigitPos:24); d2 5c aa 22 22
	calr HDAE5000_Lbn_ShowEntry			; 1e xx xx
	ld	qiz, hl

	; --- After all cases: check result ---
	ld	wa, qiz
	cp wa, 0:i3				; d8 d8
	jrl nz, .Lsw_exit			; 7e xx xx — error → exit

	; --- Compute sector address and look up in table ---
	ld wa, (HDAE5000_RAM_LbnDir:24); d2 5e aa 22 20 — cylinder
	dec 1, wa				; d8 69
	ld (HDAE5000_RAM_CurDir:24), wa; f2 92 a0 23 50
	ld wa, (HDAE5000_RAM_LbnSong:24); d2 60 aa 22 20 — head
	dec 1, wa				; d8 69
	ld (HDAE5000_RAM_CurSong:24), wa; f2 94 a0 23 50
	ld wa, (HDAE5000_RAM_CurDir:24); d2 92 a0 23 20
	ld bc, (HDAE5000_RAM_CurSong:24); d2 94 a0 23 21
	call HDAE5000_Song_PartMask		; 1d b3 03 29
	ld iz, hl				; db 8e
	ld wa, iz				; de 88
	cp wa, 0xffff				; d8 cf ff ff
	jr z, .Lsw_lookup_notfound		; 66 xx

	; --- Found: copy data and seek ---
.Lsw_lookup_found:				; 0x286F81
	lda xwa, (HDAE5000_RAM_SaveOptions:24); f2 4c aa 22 30
	ld bc, iz				; de 89
	pushw 0x0002
	lda xde, (HDAE5000_TypeSel_TemplateBlank:24); f2 96 1c 2e 32
	calr HDAE5000_TypeSel_Init		; 1e xx xx
	ld bc, (HDAE5000_RAM_CurDir:24); d2 92 a0 23 21
	ld de, (HDAE5000_RAM_CurSong:24); d2 94 a0 23 22
	ld wa, iz				; de 88
	pushw wa                                ; push wa (compact 16-bit)
	ld xwa, HDAE5000_OBJ_LBN_OPTION			; 40 98 00 7f 00
	calr HDAE5000_PartList_Build			; 1e xx xx
	jr t, .Lsw_after_lookup			; 68 xx

	; --- Not found: copy default data and seek with -1 ---
.Lsw_lookup_notfound:				; 0x286FAA
	lda xwa, (HDAE5000_RAM_SaveOptions:24); f2 4c aa 22 30
	pushw 0x0002
	lda xde, (HDAE5000_TypeSel_TemplateBlank:24); f2 96 1c 2e 32
	ld bc, 0:i3				; d9 a8
	calr HDAE5000_TypeSel_Init		; 1e xx xx
	pushw 0xffff
	ld xwa, HDAE5000_OBJ_LBN_OPTION			; 40 98 00 7f 00
	ldw bc, 0xffff				; 31 ff ff
	ldw de, 0xffff				; 32 ff ff
	calr HDAE5000_PartList_Build			; 1e xx xx

	; --- After table lookup: check sectors per track ---
.Lsw_after_lookup:				; 0x286FCD
	cp (HDAE5000_RAM_LoadByNumberMode:24), 0x02; c2 aa 9d 22 3f 02
	jr nz, .Lsw_exit			; 6e xx
	; Sectors per track == 2: do display and FS operations
	pushw 0x0001
	ld xwa, HDAE5000_OBJ_LOAD_BY_NUM			; 40 8f 00 7f 00
	push xwa				; 38
	ld wa, (HDAE5000_RAM_CurDir:24); d2 92 a0 23 20
	ld bc, (HDAE5000_RAM_CurSong:24); d2 94 a0 23 21
	ld de, (HDAE5000_RAM_SaveOptions:24); d2 4c aa 22 22
	calr HDAE5000_LoadSongWithUi		; 1e xx xx
	pushw 0x0001
	ld wa, 0:i3				; d8 a8
	ld bc, 0:i3				; d9 a8
	ld de, 6:i3				; da ae
	calr HDAE5000_Lbn_ShowEntry			; 1e xx xx
	; Check second disk flag
	cp (HDAE5000_RAM_LyricJump:24), 0x02; c2 ac 9d 22 3f 02
	jr nz, .Lsw_exit			; 6e xx
	; Check bit 8 of aa4c entry
	ld wa, (HDAE5000_RAM_SaveOptions:24); d2 4c aa 22 20
	and wa, 0x0100				; d8 cc 00 01
	cp wa, 0x0100				; d8 cf 00 01
	jr nz, .Lsw_exit			; 6e xx
	; Register event: format complete
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld xhl, (xwa + RootFn_ApPostEvent)             ; e3 e1 24 01 23
	ld xwa, HDAE5000_OBJ_Tech_lyrics			; 40 f0 02 7f 00
	ld xbc, EVT_SHOW			; 41 01 00 c0 01
	ld xde, 0:i3				; ea a8
	call (xhl)				; b3 e8

	; === Exit: check QIZ result ===
.Lsw_exit:					; 0x287030
	ld	wa, qiz
	cp wa, 0xfffe				; d8 cf fe ff
	jr z, .Lsw_err_fffe			; 66 xx
	cp wa, 0xffff				; d8 cf ff ff
	jrl nz, .Lsw_done			; 7e xx xx

	; --- Error 0xFFFF: register error + timer ---
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld xhl, (xwa + RootFn_PostEvent)             ; e3 e1 04 01 23 — ld xhl, (xwa+0x0104)
	ld xwa, HDAE5000_OBJ_DIR_OUT_RANGE			; 40 b7 02 7f 00
	ld xbc, EVT_SHOW			; 41 01 00 c0 01
	ld xde, 5:i3				; ea ad
	call (xhl)				; b3 e8
	ld xwa, EVT_HDAE_TIMER_BACK			; 40 02 00 ca 01
	push xwa				; 38
	ld xwa, HDAE5000_OBJ_LOAD_BY_NUM			; 40 8f 00 7f 00
	push xwa				; 38
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld xhl, (xwa + RootFn_SetApTimer)             ; e3 e1 10 04 23 — ld xhl, (xwa+0x0410)
	ld xwa, 0x00000021			; 40 21 00 00 00
	ld xbc, HDAE5000_OBJ_DIR_OUT_RANGE_CATCH			; 41 b8 02 7f 00
	ld xde, 0xffffffff			; 42 ff ff ff ff
	call (xhl)				; b3 e8
	jr t, .Lsw_done				; 68 xx

	; --- Error 0xFFFE: register different error + timer ---
.Lsw_err_fffe:					; 0x28708B
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld xhl, (xwa + RootFn_PostEvent)             ; e3 e1 04 01 23 — ld xhl, (xwa+0x0104)
	ld xwa, HDAE5000_OBJ_FILE_OUT_RANGE			; 40 bc 02 7f 00
	ld xbc, EVT_SHOW			; 41 01 00 c0 01
	ld xde, 5:i3				; ea ad
	call (xhl)				; b3 e8
	ld xwa, EVT_HDAE_TIMER_BACK			; 40 02 00 ca 01
	push xwa				; 38
	ld xwa, HDAE5000_OBJ_LOAD_BY_NUM			; 40 8f 00 7f 00
	push xwa				; 38
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld xhl, (xwa + RootFn_SetApTimer)             ; e3 e1 10 04 23 — ld xhl, (xwa+0x0410)
	ld xwa, 0x00000021			; 40 21 00 00 00
	ld xbc, HDAE5000_OBJ_FILE_OUT_RANGE_CATCH			; 41 bd 02 7f 00
	ld xde, 0xffffffff			; 42 ff ff ff ff
	call (xhl)				; b3 e8

	; --- Epilogue ---
.Lsw_done:					; 0x2870D4
	pop xiz					; 5e
	ret					; 0e

; --- Filesystem Operations ---
