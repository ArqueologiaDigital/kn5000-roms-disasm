HDAE5000_HD_Setup_Drive:	; 0x282E8D (1126 bytes)
	; Configure HD drive parameters; accesses HD config at 0x229D99
	; Checks disk status, identifies drive, formats partition table, registers events
	stb_dri l, 0xFD, 0xF4, 0xFE	; lda xsp, (xsp + 0xfef4) — alloc 268-byte frame
	push xiz					; 3e
	ldw	(xsp+4), 0x0000
	; Check disk status via 0x0e88 vtable
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e88)             ; e3 e1 88 0e 20
	ld xix, (xwa + 0x08)				; a8 08 24
	call (xix)					; b4 e8
	cps l, 3					; cf db
	jr z, .Lsd_status_ok				; 66 05
	cps l, 2					; cf da
	jrl nz, .Lsd_not_ready			; 7e 49 02
.Lsd_status_ok:
	; Register event 0xD2 via vtable 0x0124
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23 — (xwa+0x0124)
	ld xwa, 0x007f00d2				; 40 d2 00 7f 00
	ld xbc, 0x01c00001				; 41 01 00 c0 01
	ld xde, 0xffffffff				; 42 ff ff ff ff
	call (xhl)					; b3 e8
	calr HDAE5000_PPI_Read_Sector			; 1e 5b fe
	; Get drive info via 0x0e88.0x0090 vtable
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e88)             ; e3 e1 88 0e 20
	ld_sril xhl, (xwa + 0x0090)             ; e3 e1 90 00 23
	call (xhl)					; b3 e8
	ld xiz, xhl					; eb 8e
	ld xwa, xiz					; ee 88
	or xwa, xwa					; e8 e0 — test if null
	jr z, .Lsd_skip_copy				; 66 18
	; Copy drive info to 0x22aa9c buffer
	ld xwa, xiz					; ee 88
	push xwa					; 38
	call HDAE5000_Display_Buffer_Validate					; 1d 71 af 29
	pushw hl                                ; push hl (compact)
	ld xwa, xiz					; ee 88
	push xwa					; 38
	lda_24 xwa, (0x22aa9c); f2 9c aa 22 30
	push xwa					; 38
	call HDAE5000_MemCopy					; 1d 9f ae 29
	lda xsp, (xsp + 0x0e)			; bf 0e 37
.Lsd_skip_copy:
	; Register event 0xDE via vtable, with 0x22aa9c as data
	lda_24 xwa, (0x22aa9c); f2 9c aa 22 30
	ld xde, xwa					; e8 8a
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23
	ld xwa, 0x007f00de				; 40 de 00 7f 00
	ld xbc, 0x01ea000a				; 41 0a 00 ea 01
	call (xhl)					; b3 e8
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23
	ld xwa, 0x007f00de				; 40 de 00 7f 00
	ld xbc, 0x01c0000f				; 41 0f 00 c0 01
	ld xde, 0xffffffff				; 42 ff ff ff ff
	call (xhl)					; b3 e8
	; Identify drive: call via 0x0e88.0x0094
	lda_24 xwa, (0x2e22b4); f2 b4 22 2e 30
	ld xde, xwa					; e8 8a
	lda xwa, (xsp + 0x06)			; bf 06 30
	ld xbc, xwa					; e8 89
	ld xwa, xde					; ea 88
	ldl_da xde, (0x23a1a2); e2 a2 a1 23 22
	ld_sril xde, (xde + 0x0e88)             ; e3 e9 88 0e 22
	ld_sril xhl, (xde + 0x0094)             ; e3 e9 94 00 23
	call (xhl)					; b3 e8
	ld xiz, xhl					; eb 8e
	; Check identify result
	ld xwa, xiz					; ee 88
	cp xwa, 0x00000000				; e8 cf 00 00 00 00
	jrl lt, .Lsd_post_loop			; 71 ab 00
	; First pass: process partitions
	lda xwa, (xsp + 0x0c)			; bf 0c 30
	calr HDAE5000_PPI_Transfer_Block		; 1e c4 fe
	ld wa, hl					; db 88
	cp wa, 0xffff					; d8 cf ff ff
	jr z, .Lsd_loop_done				; 66 6e
	ld wa, hl					; db 88
	add wa, 0x0100				; d8 c8 00 01
	lda_24 xbc, (0x22aa9c); f2 9c aa 22 31
	stib_ind 0x07, 0xE4, 0xE0, 0x01	; ld (xbc+wa), 0x01
	pushw 0x0006					; 0b 06 00
	lda xwa, (xsp + 0x10)			; bf 10 30
	push xwa					; 38
	ld wa, hl					; db 88
	muls wa, 0x000c				; d8 09 0c 00
	lda_24 xbc, (0x22aaad); f2 ad aa 22 31
	exts xwa					; e8 13
	add xwa, xbc					; e9 80
	push xwa					; 38
	call HDAE5000_MemCopy					; 1d 9f ae 29
	lda xsp, (xsp + 0x0a)			; bf 0a 37
	jr t, .Lsd_loop_done				; 68 3d
	; Second pass (loop target for retry)
.Lsd_retry:
	lda xwa, (xsp + 0x0c)			; bf 0c 30
	calr HDAE5000_PPI_Transfer_Block		; 1e 85 fe
	ld wa, hl					; db 88
	cp wa, 0xffff					; d8 cf ff ff
	jr z, .Lsd_loop_done				; 66 2f
	ld wa, hl					; db 88
	add wa, 0x0100				; d8 c8 00 01
	lda_24 xbc, (0x22aa9c); f2 9c aa 22 31
	stib_ind 0x07, 0xE4, 0xE0, 0x01	; ld (xbc+wa), 0x01
	pushw 0x0006					; 0b 06 00
	lda xwa, (xsp + 0x10)			; bf 10 30
	push xwa					; 38
	ld wa, hl					; db 88
	muls wa, 0x000c				; d8 09 0c 00
	lda_24 xbc, (0x22aaad); f2 ad aa 22 31
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
	ldl_da xde, (0x23a1a2); e2 a2 a1 23 22
	ld_sril xde, (xde + 0x0e88)             ; e3 e9 88 0e 22
	ld_sril xix, (xde + 0x0098)             ; e3 e9 98 00 24
	call (xix)					; b4 e8
	cps hl, 0					; db d8
	jr z, .Lsd_retry				; 66 a7
	; Cleanup: call via 0x0e88.0x009c
	ld xwa, xiz					; ee 88
	ldl_da xbc, (0x23a1a2); e2 a2 a1 23 21
	ld_sril xbc, (xbc + 0x0e88)             ; e3 e5 88 0e 21
	ld_sril xhl, (xbc + 0x009c)             ; e3 e5 9c 00 23
	call (xhl)					; b3 e8
.Lsd_post_loop:
	; Format partition display table: loop over 20 entries
	lds de, 0					; da a8
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
	lda_24 xwa, (0x22aaaa); f2 aa aa 22 30
	ld xde, xwa					; e8 8a
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23
	ld xwa, 0x007f00d7				; 40 d7 00 7f 00
	ld xbc, 0x01ea000a				; 41 0a 00 ea 01
	call (xhl)					; b3 e8
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23
	ld xwa, 0x007f00d7				; 40 d7 00 7f 00
	ld xbc, 0x01c0000f				; 41 0f 00 c0 01
	ld xde, 0xffffffff				; 42 ff ff ff ff
	call (xhl)					; b3 e8
	; Register event 0xD9 + 0xD8
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23
	ld xwa, 0x007f00d9				; 40 d9 00 7f 00
	ld xbc, 0x01c0000d				; 41 0d 00 c0 01
	lds32 xde, 0					; ea a8
	call (xhl)					; b3 e8
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23
	ld xwa, 0x007f00d8				; 40 d8 00 7f 00
	ld xbc, 0x01c0000d				; 41 0d 00 c0 01
	lds32 xde, 0					; ea a8
	call (xhl)					; b3 e8
	jr t, .Lsd_epilogue				; 68 0a
.Lsd_not_ready:
	; Disk not ready: call shutdown with error code 2
	lds wa, 2					; d8 aa
	calr HDAE5000_HD_Shutdown			; 1e fc 7b
	ldw	(xsp+4), 0xffff
.Lsd_epilogue:
	ld hl, (xsp + 0x04)				; 9f 04 23
	pop xiz					; 5e
	stb_dri l, 0xFD, 0x0C, 0x01	; lda xsp, (xsp + 0x010c) — dealloc frame
	ret						; 0e
	; --- Sub-handler 1: event 0x01C00007 dispatch (0x28310D) ---
.Lsd_sub1:
	cp xbc, 0x01c00007				; e9 cf 07 00 c0 01
	jr nz, .Lsd_sub1_done			; 6e 63
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xix, (xwa + 0x0100)             ; e3 e1 00 01 24
	ld xwa, 0x02600024				; 40 24 00 60 02
	ld xbc, 0x01e00029				; 41 29 00 e0 01
	call (xix)					; b4 e8
	cp xhl, 0x0000000a				; eb cf 0a 00 00 00
	jr z, .Lsd_sub1_evt_0a			; 66 34
	cp xhl, 0x0000008a				; eb cf 8a 00 00 00
	jr nz, .Lsd_sub1_done			; 6e 38
	; Event 0x8A: check 0x229d99 config
	cpib_da (0x229d99), 0x00; c2 99 9d 22 3f 00
	jr nz, .Lsd_sub1_configured			; 6e 05
	calr HDAE5000_HD_Setup_Drive			; 1e 42 fd — recursive setup
	jr t, .Lsd_sub1_done				; 68 2b
.Lsd_sub1_configured:
	; Already configured: register event 0x024A
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23
	ld xwa, 0x007f024a				; 40 4a 02 7f 00
	ld xbc, 0x01c00001				; 41 01 00 c0 01
	lds32 xde, 0					; ea a8
	call (xhl)					; b3 e8
	jr t, .Lsd_sub1_done				; 68 0c
.Lsd_sub1_evt_0a:
	; Event 0x0A: init filesystem
	pushw 0x0000					; 0b 00 00
	lds wa, 0					; d8 a8
	lds bc, 0					; d9 a8
	lds de, 6					; da ae
	calr HDAE5000_FS_Init				; 1e 5e 3f
.Lsd_sub1_done:
	lds32 xhl, 0					; eb a8
	ret						; 0e
	; --- Sub-handler 2: event handler for 0xD9 (0x28317B) ---
.Lsd_sub2:
	push xiz					; 3e
	ld xiz, xwa					; e8 8e
	ld xwa, xbc					; e9 88
	cp xwa, 0x01c00007				; e8 cf 07 00 c0 01
	jr z, .Lsd_sub2_c00007			; 66 63
	cp xwa, 0x01c0000d				; e8 cf 0d 00 c0 01
	jr z, .Lsd_sub2_c0000d			; 66 23
	cp xwa, 0x01e00085				; e8 cf 85 00 e0 01
	jr z, .Lsd_sub2_e00085			; 66 16
	; Default: call cleanup callback
	ld xwa, xiz					; ee 88
	ldl_da xhl, (0x23a1a2); e2 a2 a1 23 23
	ld_sril xhl, (xhl + 0x0e0a)             ; e3 ed 0a 0e 23
	ld_sril xix, (xhl + 0x00dc)             ; e3 ed dc 00 24
	call (xix)					; b4 e8
	jrl t, .Lsd_sub2_done				; 78 87 00
.Lsd_sub2_e00085:
	lds32 xhl, 1					; eb a9
	jrl t, .Lsd_sub2_done				; 78 82 00
.Lsd_sub2_c0000d:
	; Forward event via vtable
	ld xwa, xiz					; ee 88
	ldl_da xhl, (0x23a1a2); e2 a2 a1 23 23
	ld_sril xhl, (xhl + 0x0e0a)             ; e3 ed 0a 0e 23
	ld_sril xhl, (xhl + 0x00dc)             ; e3 ed dc 00 23
	call (xhl)					; b3 e8
	lda_24 xwa, (0x2e22b8); f2 b8 22 2e 30
	ld xbc, xwa					; e8 89
	ld xwa, xiz					; ee 88
	ld xde, xbc					; e9 8a
	ldl_da xbc, (0x23a1a2); e2 a2 a1 23 21
	ld_sril xbc, (xbc + 0x0e0a)             ; e3 e5 0a 0e 21
	ld_sril xhl, (xbc + 0x0100)             ; e3 e5 00 01 23
	ld xbc, 0x01c0000f				; 41 0f 00 c0 01
	call (xhl)					; b3 e8
	lds32 xhl, 0					; eb a8
	jr t, .Lsd_sub2_done				; 68 4a
.Lsd_sub2_c00007:
	; Check for events 0x07 or 0x06
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xix, (xwa + 0x0100)             ; e3 e1 00 01 24
	ld xwa, 0x02600024				; 40 24 00 60 02
	ld xbc, 0x01e00029				; 41 29 00 e0 01
	call (xix)					; b4 e8
	cp xhl, 0x00000007				; eb cf 07 00 00 00
	jr z, .Lsd_sub2_deregister			; 66 08
	cp xhl, 0x00000006				; eb cf 06 00 00 00
	jr nz, .Lsd_sub2_skip_dereg			; 6e 1d
.Lsd_sub2_deregister:
	; Deregister event via vtable 0x0104
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0104)             ; e3 e1 04 01 23
	ld xwa, 0x007f0000				; 40 00 00 7f 00
	ld xbc, 0x01c00001				; 41 01 00 c0 01
	lds32 xde, 0					; ea a8
	call (xhl)					; b3 e8
.Lsd_sub2_skip_dereg:
	lds32 xhl, 0					; eb a8
.Lsd_sub2_done:
	pop xiz					; 5e
	ret						; 0e
	; --- Sub-handler 3: event handler for 0xD8 (0x283237) ---
.Lsd_sub3:
	push xiz					; 3e
	ld xiz, xwa					; e8 8e
	ld xwa, xbc					; e9 88
	cp xwa, 0x01c00007				; e8 cf 07 00 c0 01
	jr z, .Lsd_sub3_c00007			; 66 63
	cp xwa, 0x01c0000d				; e8 cf 0d 00 c0 01
	jr z, .Lsd_sub3_c0000d			; 66 23
	cp xwa, 0x01e00085				; e8 cf 85 00 e0 01
	jr z, .Lsd_sub3_e00085			; 66 16
	; Default: call cleanup callback
	ld xwa, xiz					; ee 88
	ldl_da xhl, (0x23a1a2); e2 a2 a1 23 23
	ld_sril xhl, (xhl + 0x0e0a)             ; e3 ed 0a 0e 23
	ld_sril xix, (xhl + 0x00dc)             ; e3 ed dc 00 24
	call (xix)					; b4 e8
	jrl t, .Lsd_sub3_done				; 78 87 00
.Lsd_sub3_e00085:
	lds32 xhl, 1					; eb a9
	jrl t, .Lsd_sub3_done				; 78 82 00
.Lsd_sub3_c0000d:
	; Forward event via vtable
	ld xwa, xiz					; ee 88
	ldl_da xhl, (0x23a1a2); e2 a2 a1 23 23
	ld_sril xhl, (xhl + 0x0e0a)             ; e3 ed 0a 0e 23
	ld_sril xhl, (xhl + 0x00dc)             ; e3 ed dc 00 23
	call (xhl)					; b3 e8
	lda_24 xwa, (0x2e22be); f2 be 22 2e 30
	ld xbc, xwa					; e8 89
	ld xwa, xiz					; ee 88
	ld xde, xbc					; e9 8a
	ldl_da xbc, (0x23a1a2); e2 a2 a1 23 21
	ld_sril xbc, (xbc + 0x0e0a)             ; e3 e5 0a 0e 21
	ld_sril xhl, (xbc + 0x0100)             ; e3 e5 00 01 23
	ld xbc, 0x01c0000f				; 41 0f 00 c0 01
	call (xhl)					; b3 e8
	lds32 xhl, 0					; eb a8
	jr t, .Lsd_sub3_done				; 68 4a
.Lsd_sub3_c00007:
	; Check for events 0x07 or 0x06
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xix, (xwa + 0x0100)             ; e3 e1 00 01 24
	ld xwa, 0x02600024				; 40 24 00 60 02
	ld xbc, 0x01e00029				; 41 29 00 e0 01
	call (xix)					; b4 e8
	cp xhl, 0x00000007				; eb cf 07 00 00 00
	jr z, .Lsd_sub3_deregister			; 66 08
	cp xhl, 0x00000006				; eb cf 06 00 00 00
	jr nz, .Lsd_sub3_skip_dereg			; 6e 1d
.Lsd_sub3_deregister:
	; Deregister event 0xD2 via vtable 0x0104
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0104)             ; e3 e1 04 01 23
	ld xwa, 0x007f00d2				; 40 d2 00 7f 00
	ld xbc, 0x01c00001				; 41 01 00 c0 01
	lds32 xde, 0					; ea a8
	call (xhl)					; b3 e8
.Lsd_sub3_skip_dereg:
	lds32 xhl, 0					; eb a8
.Lsd_sub3_done:
	pop xiz					; 5e
	ret						; 0e

HDAE5000_HD_Read_Identify:	; 0x2832F3 (1051 bytes)
	; Read HD IDENTIFY data; extracts CHS params from 0x229D99-0x229DAB
	; --- Prologue: allocate 32-byte stack frame ---
	lda	xsp, (xsp-32)

	; --- Format CHS display strings ---
	; Block 1: cylinder type (0x229d99) → display buffer 0x22ada6
	pushw 0x0097
	lda_24 xwa, (0x2e22c4); f2 c4 22 2e 30
	push xwa				; 38
	lda_24 xwa, (0x22ada6); f2 a6 ad 22 30
	push xwa				; 38
	call HDAE5000_MemCopy				; 1d 9f ae 29 — MemCopy
	ldb_da xwa, (0x229d99); c2 99 9d 22 21 — ld a, (0x229d99)
	extz wa					; d8 12
	sla wa, 2				; d8 ec 02
	lda_24 xbc, (0x2e1e3c); f2 3c 1e 2e 31
	ld_sril3 xwa, 0x07, 0xe4, 0xe0		; e3 07 e4 e0 20 — ld xwa, (xbc+wa)
	push xwa				; 38
	pushw 0x002e
	pushw 0x235c
	lda xwa, (xsp + 0x12)			; bf 12 30
	push xwa				; 38
	call HDAE5000_PPI_Block_Copy		; 1d d8 ab 29
	lda xwa, (xsp + 0x16)			; bf 16 30
	push xwa				; 38
	call HDAE5000_Display_Buffer_Validate				; 1d 71 af 29 — Display_Buffer_Validate
	lda xsp, (xsp + 0x1a)			; bf 1a 37

	; Block 2: heads (0x229d9a) → display buffer 0x22adba
	pushw hl                                ; push hl (compact 16-bit)
	lda xwa, (xsp + 0x02)			; bf 02 30
	push xwa				; 38
	lda_24 xwa, (0x22adba); f2 ba ad 22 30
	push xwa				; 38
	call HDAE5000_MemCopy				; 1d 9f ae 29 — MemCopy
	ldb_da xwa, (0x229d9a); c2 9a 9d 22 21 — ld a, (0x229d9a)
	extz wa					; d8 12
	sla wa, 2				; d8 ec 02
	lda_24 xbc, (0x2e1e3c); f2 3c 1e 2e 31
	ld_sril3 xwa, 0x07, 0xe4, 0xe0		; e3 07 e4 e0 20 — ld xwa, (xbc+wa)
	push xwa				; 38
	pushw 0x002e
	pushw 0x2360
	lda xwa, (xsp + 0x12)			; bf 12 30
	push xwa				; 38
	call HDAE5000_PPI_Block_Copy		; 1d d8 ab 29
	lda xwa, (xsp + 0x16)			; bf 16 30
	push xwa				; 38
	call HDAE5000_Display_Buffer_Validate				; 1d 71 af 29 — Display_Buffer_Validate
	lda xsp, (xsp + 0x1a)			; bf 1a 37

	; Block 3: sectors (0x229daa) → display buffer 0x22adec
	pushw hl                                ; push hl (compact 16-bit)
	lda xwa, (xsp + 0x02)			; bf 02 30
	push xwa				; 38
	lda_24 xwa, (0x22adec); f2 ec ad 22 30
	push xwa				; 38
	call HDAE5000_MemCopy				; 1d 9f ae 29 — MemCopy
	ldb_da xwa, (0x229daa); c2 aa 9d 22 21 — ld a, (0x229daa)
	extz wa					; d8 12
	pushw wa                                ; push wa (compact 16-bit)
	pushw 0x002e
	pushw 0x2364
	lda xwa, (xsp + 0x10)			; bf 10 30
	push xwa				; 38
	call HDAE5000_PPI_Block_Copy		; 1d d8 ab 29
	lda xwa, (xsp + 0x14)			; bf 14 30
	push xwa				; 38
	call HDAE5000_Display_Buffer_Validate				; 1d 71 af 29 — Display_Buffer_Validate
	lda xsp, (xsp + 0x18)			; bf 18 37

	; Block 4: cylinder count high (0x229da9) → display buffer 0x22ae1e
	pushw hl                                ; push hl (compact 16-bit)
	lda xwa, (xsp + 0x02)			; bf 02 30
	push xwa				; 38
	lda_24 xwa, (0x22ae1e); f2 1e ae 22 30
	push xwa				; 38
	call HDAE5000_MemCopy				; 1d 9f ae 29 — MemCopy
	ldb_da xwa, (0x229da9); c2 a9 9d 22 21 — ld a, (0x229da9)
	extz wa					; d8 12
	pushw wa                                ; push wa (compact 16-bit)
	pushw 0x002e
	pushw 0x236a
	lda xwa, (xsp + 0x10)			; bf 10 30
	push xwa				; 38
	call HDAE5000_PPI_Block_Copy		; 1d d8 ab 29
	lda xwa, (xsp + 0x14)			; bf 14 30
	push xwa				; 38
	call HDAE5000_Display_Buffer_Validate				; 1d 71 af 29 — Display_Buffer_Validate
	lda xsp, (xsp + 0x18)			; bf 18 37

	; Block 5: cylinder count (0x229dab) → display buffer 0x22add1
	pushw hl                                ; push hl (compact 16-bit)
	lda xwa, (xsp + 0x02)			; bf 02 30
	push xwa				; 38
	lda_24 xwa, (0x22add1); f2 d1 ad 22 30
	push xwa				; 38
	call HDAE5000_MemCopy				; 1d 9f ae 29 — MemCopy
	ldb_da xwa, (0x229dab); c2 ab 9d 22 21 — ld a, (0x229dab)
	extz wa					; d8 12
	pushw wa                                ; push wa (compact 16-bit)
	pushw 0x002e
	pushw 0x2372
	lda xwa, (xsp + 0x10)			; bf 10 30
	push xwa				; 38
	call HDAE5000_PPI_Block_Copy		; 1d d8 ab 29
	lda xwa, (xsp + 0x14)			; bf 14 30
	push xwa				; 38
	call HDAE5000_Display_Buffer_Validate				; 1d 71 af 29 — Display_Buffer_Validate
	lda xsp, (xsp + 0x18)			; bf 18 37

	; Block 6: total size string → display buffer 0x22ae03
	pushw hl                                ; push hl (compact 16-bit)
	lda xwa, (xsp + 0x02)			; bf 02 30
	push xwa				; 38
	lda_24 xwa, (0x22ae03); f2 03 ae 22 30
	push xwa				; 38
	call HDAE5000_MemCopy				; 1d 9f ae 29 — MemCopy
	lda xsp, (xsp + 0x0a)			; bf 0a 37

	; Compute capacity: divide total sectors by 100
	lda xwa, (xsp + 0x10)			; bf 10 30
	call 0x298b6c				; 1d 6c 8b 29
	ld xwa, (xsp + 0x1c)			; af 1c 20 — load dividend
	ld xbc, 0x00000064			; 41 64 00 00 00 — divisor = 100
	call HDAE5000_Divide_Signed		; 1d c5 b8 29
	push xhl				; 3b — push remainder
	pushw 0x002e
	pushw 0x237a
	lda xwa, (xsp + 0x08)			; bf 08 30
	push xwa				; 38
	call HDAE5000_PPI_Block_Copy		; 1d d8 ab 29
	lda xwa, (xsp + 0x0c)			; bf 0c 30
	push xwa				; 38
	call HDAE5000_Display_Buffer_Validate				; 1d 71 af 29 — Display_Buffer_Validate

	; Block 7: capacity text → display buffer 0x22ae35
	pushw hl                                ; push hl (compact 16-bit)
	lda xwa, (xsp + 0x12)			; bf 12 30
	push xwa				; 38
	lda_24 xwa, (0x22ae35); f2 35 ae 22 30
	push xwa				; 38
	call HDAE5000_MemCopy				; 1d 9f ae 29 — MemCopy
	lda xsp, (xsp + 0x1a)			; bf 1a 37

	; --- Register event handlers ---
	; Register event 0x01EA000A with display buffer
	lda_24 xwa, (0x22ada6); f2 a6 ad 22 30
	ld xde, xwa				; e8 8a
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld_sril xhl, (xwa + 0x0100)             ; e3 e1 00 01 23 — ld xhl, (xwa+0x0100)
	ld xwa, 0x007f000a			; 40 0a 00 7f 00
	ld xbc, 0x01ea000a			; 41 0a 00 ea 01
	call (xhl)				; b3 e8

	; Register event 0x01C0000F with XDE=0xFFFFFFFF (deregister)
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld_sril xhl, (xwa + 0x0100)             ; e3 e1 00 01 23 — ld xhl, (xwa+0x0100)
	ld xwa, 0x007f000a			; 40 0a 00 7f 00
	ld xbc, 0x01c0000f			; 41 0f 00 c0 01
	ld xde, 0xffffffff			; 42 ff ff ff ff
	call (xhl)				; b3 e8

	; --- Epilogue ---
	lda xsp, (xsp + 0x20)			; bf 20 37
	ret					; 0e

; --- Event handler sub-function ---
.Lri_event_handler:				; 0x283498
	dec 0, xsp				; ef 68 — allocate 4 bytes
	push xiz				; 3e
	ld (xsp + 0x04), xde			; bf 04 62
	ld xiz, xbc				; e9 8e
	ld (xsp + 0x08), xwa			; bf 08 60
	ld xwa, xiz				; ee 88
	cp xwa, 0x01c0000d			; e8 cf 0d 00 c0 01
	jr z, .Lri_evt_000d			; 66 xx
	cp xwa, 0x01e00085			; e8 cf 85 00 e0 01
	jr z, .Lri_evt_0085			; 66 xx

	; Default: forward to vtable handler at +0x0EDC
	ld xwa, (xsp + 0x08)			; af 08 20
	ld xbc, xiz				; ee 89
	ld xde, (xsp + 0x04)			; af 04 22
	ldl_da xhl, (0x23a1a2); e2 a2 a1 23 23
	ld_sril xhl, (xhl + 0x0e0a)             ; e3 ed 0a 0e 23 — ld xhl, (xhl+0x0e0a)
	ld_sril xix, (xhl + 0x00dc)             ; e3 ed dc 00 24 — ld xix, (xhl+0x00dc)
	call (xix)				; b4 e8
	jr t, .Lri_evt_done			; 68 xx

.Lri_evt_0085:					; 0x2834D0
	lds32 xhl, 1				; eb a9
	jr t, .Lri_evt_done			; 68 xx

.Lri_evt_000d:					; 0x2834D4
	calr HDAE5000_HD_Read_Identify		; 1e xx xx — recursive self-call
	ld xwa, (xsp + 0x08)			; af 08 20
	ld xbc, xiz				; ee 89
	ld xde, (xsp + 0x04)			; af 04 22
	ldl_da xhl, (0x23a1a2); e2 a2 a1 23 23
	ld_sril xhl, (xhl + 0x0e0a)             ; e3 ed 0a 0e 23 — ld xhl, (xhl+0x0e0a)
	ld_sril xhl, (xhl + 0x00dc)             ; e3 ed dc 00 23 — ld xhl, (xhl+0x00dc)
	call (xhl)				; b3 e8
	; Re-register event 0x01C0000F with new handler
	lda_24 xwa, (0x2e2382); f2 82 23 2e 30
	ld xbc, xwa				; e8 89
	ld xwa, (xsp + 0x08)			; af 08 20
	ld xde, xbc				; e9 8a
	ldl_da xbc, (0x23a1a2); e2 a2 a1 23 21
	ld_sril xbc, (xbc + 0x0e0a)             ; e3 e5 0a 0e 21 — ld xbc, (xbc+0x0e0a)
	ld_sril xhl, (xbc + 0x0100)             ; e3 e5 00 01 23 — ld xhl, (xbc+0x0100)
	ld xbc, 0x01c0000f			; 41 0f 00 c0 01
	call (xhl)				; b3 e8
	lds32 xhl, 0				; eb a8

.Lri_evt_done:					; 0x283514
	pop xiz					; 5e
	inc 0, xsp				; ef 60
	ret					; 0e

; --- Jump table dispatcher sub-function ---
.Lri_dispatch:					; 0x283518
	cp xbc, 0x01c00013			; e9 cf 13 00 c0 01
	jrl nz, .Lri_done			; 7e xx xx
	ld xwa, xde				; ea 88
	dec 2, xwa				; e8 6a — subtract 2 (cases start at 2)
	cp xwa, 0x00000000			; e8 cf 00 00 00 00
	jrl c, .Lri_done			; 77 xx xx — unsigned < 0
	cp xwa, 0x00000007			; e8 cf 07 00 00 00
	jrl ugt, .Lri_done			; 7b xx xx — > 7
	add xwa, xwa				; e8 80 — multiply by 2 (word offsets)
	add xwa, 0x002e23ac			; e8 c8 ac 23 2e 00 — add table base
	ld wa, (xwa)				; 90 20 — load 16-bit jump offset
	lda_24 xix, (0x28354b); f2 4b 35 28 34 — jump base
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp t, (xix+wa) — F3 indexed jump

	; === Case 2: main setup — read/write, format, init filesystem ===
.Lri_jt_base:					; 0x28354B (jump table base)
	stib_da (0x22ae3c), 0x00; f2 3c ae 22 00 00
	lda_24 xwa, (0x22ada6); f2 a6 ad 22 30
	ld xde, xwa				; e8 8a
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23 — ld xhl, (xwa+0x0124)
	ld xwa, 0x007f000a			; 40 0a 00 7f 00
	ld xbc, 0x01ea000a			; 41 0a 00 ea 01
	call (xhl)				; b3 e8
	lds wa, 0				; d8 a8
	lds bc, 0				; d9 a8
	calr HDAE5000_HD_Read_Write		; 1e xx xx

	stib_da (0x22aa4a), 0x00; f2 4a aa 22 00 00
	lda_24 xwa, (0x22a2ca); f2 ca a2 22 30
	ld xde, xwa				; e8 8a
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23 — ld xhl, (xwa+0x0124)
	ld xwa, 0x007f00fb			; 40 fb 00 7f 00
	ld xbc, 0x01ea000a			; 41 0a 00 ea 01
	call (xhl)				; b3 e8
	lds wa, 0				; d8 a8
	lds bc, 2				; d9 aa
	calr HDAE5000_FS_Write_FSB		; 1e xx xx

	stib_da (0x22a2c8), 0x00; f2 c8 a2 22 00 00
	lda_24 xwa, (0x22a0d0); f2 d0 a0 22 30
	ld xde, xwa				; e8 8a
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23 — ld xhl, (xwa+0x0124)
	ld xwa, 0x007f0025			; 40 25 00 7f 00
	ld xbc, 0x01ea000a			; 41 0a 00 ea 01
	call (xhl)				; b3 e8
	ld xwa, 0x007f0025			; 40 25 00 7f 00
	calr HDAE5000_HD_Format_Params		; 1e xx xx
	calr HDAE5000_FS_Read_FSB		; 1e xx xx
	pushw 0x0000
	lds wa, 0				; d8 a8
	lds bc, 0				; d9 a8
	lds de, 6				; da ae
	calr HDAE5000_FS_Init			; 1e xx xx

	; Copy volume label string
	pushw 0x0021
	lda_24 xwa, (0x2e1de6); f2 e6 1d 2e 30
	push xwa				; 38
	lda_24 xwa, (0x22abc4); f2 c4 ab 22 30
	push xwa				; 38
	call HDAE5000_MemCopy				; 1d 9f ae 29 — MemCopy
	lda xsp, (xsp + 0x0a)			; bf 0a 37

	; Register event for volume label display
	lda_24 xwa, (0x22abc4); f2 c4 ab 22 30
	ld xde, xwa				; e8 8a
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23 — ld xhl, (xwa+0x0124)
	ld xwa, 0x007f0068			; 40 68 00 7f 00
	ld xbc, 0x01ea000a			; 41 0a 00 ea 01
	call (xhl)				; b3 e8

	; Set initial disk status
	ld xwa, 0x007f0000			; 40 00 00 7f 00
	stl_da (0x23a09a), xwa; f2 9a a0 23 60
	cpib_da (0x22ad9a), 0x01; c2 9a ad 22 3f 01
	jrl nz, .Lri_done			; 7e xx xx
	cpib_da (0x22ad9b), 0x01; c2 9b ad 22 3f 01
	jrl nz, .Lri_done			; 7e xx xx
	ld xwa, 0x007f013a			; 40 3a 01 7f 00
	stl_da (0x23a09a), xwa; f2 9a a0 23 60
	jrl t, .Lri_done			; 78 xx xx

	; === Case 9: check cylinder count, set disk capacity ===
.Lri_case9:					; 0x283649
	ldb_da xwa, (0x229da9); c2 a9 9d 22 21 — ld a, (0x229da9)
	cps a, 3				; c9 db
	jr z, .Lri_case9_cyl3			; 66 xx
	cps a, 2				; c9 da
	jr z, .Lri_case9_cyl2			; 66 xx
	cps a, 1				; c9 d9
	jrl nz, .Lri_done			; 7e xx xx
	ld xwa, 0x007f0018			; 40 18 00 7f 00
	stl_da (0x23a09a), xwa; f2 9a a0 23 60
	jrl t, .Lri_done			; 78 xx xx

.Lri_case9_cyl2:				; 0x283668
	ld xwa, 0x007f008f			; 40 8f 00 7f 00
	stl_da (0x23a09a), xwa; f2 9a a0 23 60
	jrl t, .Lri_done			; 78 xx xx

.Lri_case9_cyl3:				; 0x283675
	ld xwa, 0x007f013a			; 40 3a 01 7f 00
	stl_da (0x23a09a), xwa; f2 9a a0 23 60
	jrl t, .Lri_done			; 78 xx xx

	; === Case 8: dispatch event to sub-device ===
.Lri_case8:					; 0x283682
	ldl_da xwa, (0x23a09a); e2 9a a0 23 20
	ldl_da xbc, (0x23a1a2); e2 a2 a1 23 21
	ld_sril xbc, (xbc + 0x0e0a)             ; e3 e5 0a 0e 21 — ld xbc, (xbc+0x0e0a)
	ld_sril xhl, (xbc + 0x0124)             ; e3 e5 24 01 23 — ld xhl, (xbc+0x0124)
	ld xbc, 0x01c00001			; 41 01 00 c0 01
	lds32 xde, 0				; ea a8
	call (xhl)				; b3 e8

	; Deregister event 0x01C00018
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23 — ld xhl, (xwa+0x0124)
	ld xwa, 0xffffffff			; 40 ff ff ff ff
	ld xbc, 0x01c00018			; 41 18 00 c0 01
	lds32 xde, 0				; ea a8
	call (xhl)				; b3 e8

	; Check disk presence flags
	cpib_da (0x22ad9a), 0x01; c2 9a ad 22 3f 01
	jr nz, .Lri_done			; 6e xx
	cpib_da (0x22ad9b), 0x01; c2 9b ad 22 3f 01
	jr nz, .Lri_done			; 6e xx

	; Clear flag and register event 0x01CA0000
	stib_da (0x22ad9b), 0x00; f2 9b ad 22 00 00
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23 — ld xhl, (xwa+0x0124)
	ld xwa, 0x007f013a			; 40 3a 01 7f 00
	ld xbc, 0x01ca0000			; 41 00 00 ca 01
	lds32 xde, 0				; ea a8
	call (xhl)				; b3 e8
	jr t, .Lri_done				; 68 xx

	; === Case 6: init flag check, set disk size from table ===
.Lri_case6:					; 0x2836F1
	call HDAE5000_Get_Init_Flag		; 1d 70 f5 28
	ld a, l					; cf 89
	extz wa					; d8 12
	sla wa, 2				; d8 ec 02
	lda_24 xbc, (0x2e2388); f2 88 23 2e 31
	ld_sril3 xwa, 0x07, 0xe4, 0xe0		; e3 07 e4 e0 20 — ld xwa, (xbc+wa)
	stl_da (0x23a09a), xwa; f2 9a a0 23 60

	; === Common exit ===
.Lri_done:					; 0x28370B
	lds32 xhl, 0				; eb a8
	ret					; 0e

HDAE5000_HD_Format_Params:	; 0x28370E (702 bytes)
	; Format 24 cylinder/head entries into format buffer at 0x22a0d0
	; Args: XWA = context ptr (stored at XSP+0x18)
	; Uses table at 0x23a08e for base offset

	; --- Prologue ---
	lda	xsp, (xsp-26)
	pushw iz                                ; push iz (compact 1-byte)
	ld (xsp + 0x18), xwa		; save context ptr

	; --- Format 0x01F9 entries into buffer ---
	pushw 0x01f9
	pushw 0x0000
	lda_24 xwa, (0x22a0d0)
	push xwa
	call HDAE5000_MemFill
	inc 0, xsp			; (NOP — callee cleaned stack)

	; --- Loop: format 24 (0x18) entries ---
	lds iz, 0			; IZ = loop counter
	cp iz, 0x0018
	jr ge, .Lfp_loop_done

.Lfp_format_entry:
	; Format field name
	pushw 0x0015
	lda_24 xwa, (0x2e23bc)
	push xwa
	ldw wa, 0x0015
	muls xwa, xiz			; XWA = IZ * 21
	lda_24 xbc, (0x22a0d0)
	exts xwa
	add xwa, xbc			; XWA = buffer + IZ*21
	push xwa
	call HDAE5000_MemCopy
	; Format entry number
	ld wa, iz
	addda16_24 xwa, (0x23a08e); WA += base offset
	inc 1, wa
	pushw wa                                ; push wa (compact 1-byte)
	pushw 0x002e
	pushw 0x23d2
	lda xwa, (xsp + 0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	; Format second field
	pushw 0x0003
	lda xwa, (xsp + 0x18)
	push xwa
	ldw wa, 0x0015
	muls xwa, xiz
	lda_24 xbc, (0x22a0d0)
	exts xwa
	add xwa, xbc
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x1e)		; clean stack (30 bytes)

	; Load sector address for this entry
	ldw_da xwa, (0x23a08e); WA = base offset
	add wa, iz			; WA = base + IZ
	call HDAE5000_Calc_Offset_16			; XHL = sector address
	; Format sector data
	pushw 0x0010
	push xhl
	ldw wa, 0x0015
	muls xwa, xiz
	lda_24 xbc, (0x22a0d4)
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
	lda_24 xwa, (0x22a0d0)
	ld xbc, xwa
	ld xwa, (xsp + 0x18)		; restore context ptr
	ld xde, xbc
	ldl_da xbc, (0x23a1a2)
	ld_sril xbc, (xbc + 0x0e0a)             ; XBC = (XBC + 0x0e0a)
	ld_sril xhl, (xbc + 0x0124)             ; XHL = (XBC + 0x0124)
	ld xbc, 0x01ea000a
	call (xhl)

	ld xwa, (xsp + 0x18)		; restore context ptr
	ldl_da xbc, (0x23a1a2)
	ld_sril xbc, (xbc + 0x0e0a)
	ld_sril xhl, (xbc + 0x0124)
	ld xbc, 0x01c0000f
	ld xde, 0xffffffff
	call (xhl)

	popw iz                                 ; pop iz (compact 1-byte)
	lda xsp, (xsp + 0x1a)		; deallocate 26-byte frame
	ret

; --- HD Format Event Dispatcher (0x2837F2) ---
; Handles event codes 0x01EA0000-0x01EA0008, 0x01C00007
HDAE5000_HD_Format_Dispatch:	; 0x2837F2
	push xiz
	ld xiz, xde			; save XDE in XIZ

	; Dispatch on event code in XBC
	cp xbc, 0x01ea0000
	jrl z, .Lfd_page_down		; 0x01EA0000 = page down
	cp xbc, 0x01ea0001
	jrl z, .Lfd_page_up		; 0x01EA0001 = page up
	cp xbc, 0x01ea0008
	jrl z, .Lfd_seek		; 0x01EA0008 = seek
	cp xbc, 0x01ea0007
	jrl z, .Lfd_set_format		; 0x01EA0007 = set format params
	cp xbc, 0x01ea0006
	jrl z, .Lfd_set_format		; 0x01EA0006 = same handler
	cp xbc, 0x01c00007
	jrl nz, .Lfd_done		; not 0x01C00007 → exit

	; --- Handle 0x01C00007: UI navigation ---
	ld xde, xiz
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)             ; XWA = (XWA + 0x0e0a)
	ld_sril xix, (xwa + 0x0100)             ; XIX = (XWA + 0x0100)
	ld xwa, 0x02600024
	ld xbc, 0x01e00029
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
	stiw_da (0x23a08e), 0x0000
	ld xwa, 0x007f0025
	calr HDAE5000_HD_Format_Params
	jrl t, .Lfd_done

.Lfd_nav_case1:
	; Case 1: offset = 0x0018
	stiw_da (0x23a08e), 0x0018
	ld xwa, 0x007f0025
	calr HDAE5000_HD_Format_Params
	jrl t, .Lfd_done

.Lfd_nav_case5:
	; Case 5: offset = 0x0030
	stiw_da (0x23a08e), 0x0030
	ld xwa, 0x007f0025
	calr HDAE5000_HD_Format_Params
	jrl t, .Lfd_done

.Lfd_nav_case6:
	; Case 6: offset = 0x0048
	stiw_da (0x23a08e), 0x0048
	ld xwa, 0x007f0025
	calr HDAE5000_HD_Format_Params
	jrl t, .Lfd_done

.Lfd_nav_case7:
	; Case 7: offset = 0x0060
	stiw_da (0x23a08e), 0x0060
	ld xwa, 0x007f0025
	calr HDAE5000_HD_Format_Params
	jrl t, .Lfd_done

.Lfd_set_format:
	; Handle 0x01EA0006/0007: set format parameters
	ldw_da xbc, (0x23a08e); BC = base offset
	ld wa, iz
	add wa, bc
	stw_da (0x23a092), xwa; store new position
	lds wa, 0			; WA = 0
	lds bc, 0			; BC = 0
	calr HDAE5000_HD_Read_Write	; call HD read/write

	; Notify UI
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)             ; XHL = vtable method
	ld xwa, 0x007f0018
	ld xbc, 0x01c00001
	lds32 xde, 0
	call (xhl)
	jrl t, .Lfd_done

.Lfd_seek:
	; Handle 0x01EA0008: seek operation
	ldw_da xwa, (0x23a08e); WA = base offset
	ld bc, iz
	add bc, wa
	stw_da (0x23a092), xbc; store seek position
	ld wa, bc
	call HDAE5000_Calc_Offset_16			; XHL = sector address
	ld xde, xhl

	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0250)             ; XHL = (XWA + 0x0250) vtable method
	ld xwa, 0x012a0002
	ld xbc, 0x01e00086
	call (xhl)

	; Send completion notification
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)
	ld xwa, 0x007f0058
	ld xbc, 0x01c00001
	lds32 xde, 0
	call (xhl)
	jr t, .Lfd_done

.Lfd_page_up:
	; Handle 0x01EA0001: page up
	cpw_da (0x23a08e), 0x0018
	jr lt, .Lfd_done		; already at minimum
	subdi16_24 (0x23a08e), 0x0018; subtract 24 from offset
	ld xwa, 0x007f0025
	calr HDAE5000_HD_Format_Params
	; Calculate new entry index
	ld xwa, xiz
	add xwa, 0x00000018
	ld xde, xwa

	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)
	ld xwa, 0x007f0025
	ld xbc, 0x01ea0003
	call (xhl)
	jr t, .Lfd_done

.Lfd_page_down:
	; Handle 0x01EA0000: page down
	cpw_da (0x23a08e), 0x0060
	jr ge, .Lfd_done		; already at maximum
	adddi16_24 (0x23a08e), 0x0018; add 24 to offset
	ld xwa, 0x007f0025
	calr HDAE5000_HD_Format_Params
	; Calculate new entry index
	ld xwa, xiz
	sub xwa, 0x00000018
	ld xde, xwa

	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)
	ld xwa, 0x007f0025
	ld xbc, 0x01ea0003
	call (xhl)

.Lfd_done:
	lds32 xhl, 0
	pop xiz
	ret

HDAE5000_HD_Seek:	; 0x2839CC (412 bytes)
	; Seek to cylinder/head position on HD
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
	lda_24 xwa, (0x2e2458)
	push xwa
	lda_24 xwa, (0x22b274)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)
	jrl t, .Lhsk_epilogue_vtable

.Lhsk_check_bits:
	pushw 0x007f
	lda_24 xwa, (0x2e23d8)
	push xwa
	lda_24 xwa, (0x22b274)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)

	cp iz, 0xffff
	jrl z, .Lhsk_iz_invalid

	; --- Bit 0 ---
	bit 0, iz
	jr nz, .Lhsk_bit1
	pushw 0x000e
	lda_24 xwa, (0x2e24d8)
	push xwa
	lda_24 xwa, (0x22b274)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)

.Lhsk_bit1:
	bit 1, iz
	jr nz, .Lhsk_bit2
	pushw 0x000e
	lda_24 xwa, (0x2e24d8)
	push xwa
	lda_24 xwa, (0x22b282)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)

.Lhsk_bit2:
	bit 2, iz
	jr nz, .Lhsk_bit3
	pushw 0x000e
	lda_24 xwa, (0x2e24d8)
	push xwa
	lda_24 xwa, (0x22b290)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)

.Lhsk_bit3:
	bit 3, iz
	jr nz, .Lhsk_bit4
	pushw 0x000e
	lda_24 xwa, (0x2e24d8)
	push xwa
	lda_24 xwa, (0x22b29e)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)

.Lhsk_bit4:
	bit 4, iz
	jr nz, .Lhsk_bit5
	pushw 0x000e
	lda_24 xwa, (0x2e24d8)
	push xwa
	lda_24 xwa, (0x22b2ac)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)

.Lhsk_bit5:
	bit 5, iz
	jr nz, .Lhsk_bit6
	pushw 0x000e
	lda_24 xwa, (0x2e24d8)
	push xwa
	lda_24 xwa, (0x22b2ba)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)

.Lhsk_bit6:
	bit 6, iz
	jr nz, .Lhsk_bit7
	pushw 0x000e
	lda_24 xwa, (0x2e24d8)
	push xwa
	lda_24 xwa, (0x22b2c8)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)

.Lhsk_bit7:
	bit 7, iz
	jr nz, .Lhsk_bit8
	pushw 0x000e
	lda_24 xwa, (0x2e24d8)
	push xwa
	lda_24 xwa, (0x22b2d6)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)

.Lhsk_bit8:
	bit 8, iz
	jr nz, .Lhsk_epilogue_vtable
	pushw 0x000e
	lda_24 xwa, (0x2e24d8)
	push xwa
	lda_24 xwa, (0x22b2e4)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)
	jr t, .Lhsk_epilogue_vtable

.Lhsk_iz_invalid:
	pushw 0x007f
	lda_24 xwa, (0x2e2458)
	push xwa
	lda_24 xwa, (0x22b274)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)

.Lhsk_epilogue_vtable:
	; Load vtable and call two methods
	lda_24 xwa, (0x22b274)
	ld xbc, xwa
	ld xwa, (xsp + 0x02)		; restore context ptr
	ld xde, xbc
	ldl_da xbc, (0x23a1a2)
	ld_sril xbc, (xbc + 0x0e0a)             ; XBC = (XBC + 0x0e0a)
	ld_sril xhl, (xbc + 0x0124)             ; XHL = (XBC + 0x0124)
	ld xbc, 0x01ea000a
	call (xhl)

	ld xwa, (xsp + 0x02)		; restore context ptr
	ldl_da xbc, (0x23a1a2)
	ld_sril xbc, (xbc + 0x0e0a)             ; XBC = (XBC + 0x0e0a)
	ld_sril xhl, (xbc + 0x0124)             ; XHL = (XBC + 0x0124)
	ld xbc, 0x01c0000f
	ld xde, 0xffffffff
	call (xhl)

	; --- Epilogue ---
	popw iz                                 ; pop iz (compact 1-byte form)
	inc 4, xsp
	retd 0x0002

HDAE5000_HD_Read_Write:	; 0x283B68 (4737 bytes)
; LHRW: 0x283B68 (4737 bytes)

	lda	xsp, (xsp-26)
	pushw iz                                ; push IZ
	ld	(xsp+24), c
	ld	(xsp+26), a
	cp	(xsp+24), 0x00
	jrl nz, .LHRW_3c5d                     ; [7e e4 00] jrl NZ,0x283c5d
	pushw 0x0020
	pushw 0x0000
	lda_24 xwa, (0x22a038)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2500
	pushw 0x0022
	pushw 0xa038
	call HDAE5000_StrCopy
	ldw_da	wa, (0x23A092)
	inc	1, wa
	pushw wa                                ; push WA
	pushw 0x002e
	pushw 0x250c
	lda	xwa, (xsp+24)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+26)
	lda	xwa, (xsp+2)
	push xwa
	pushw 0x0022
	pushw 0xa038
	call HDAE5000_StrCopy
	pushw 0x002e
	pushw 0x2512
	pushw 0x0022
	pushw 0xa038
	call HDAE5000_StrCopy
	lda	xsp, (xsp+16)
	pushw 0x0010
	ldw_da	wa, (0x23A092)
	call HDAE5000_Calc_Offset_16
	push xhl
	pushw 0x0022
	pushw 0xa038
	call 0x29af8f
	pushw 0x002e
	pushw 0x2514
	pushw 0x0022
	pushw 0xa038
	call HDAE5000_StrCopy
	lda	xsp, (xsp+18)
	ld	a, (xsp+26)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, (0x2e24e8)
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	lda_24 xwa, (0x22a038)
	ld	xbc, xwa
	ld	xwa, xde
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0124)
	ld	xbc, 0x01ea000a
	call	(xhl)
	ld	a, (xsp+26)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, (0x2e24e8)
	ld_sril3 xwa, 0x07, 0xE4, 0xE0	; ld XWA,(XBC+WA)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0124)
	ld	xbc, 0x01c0000f
	ld	xde, 0xffffffff
	call	(xhl)
.LHRW_3c5d:
	cp	(xsp+24), 0x00
	jrl nz, .LHRW_3d45                     ; [7e e1 00] jrl NZ,0x283d45
	lds	iz, 0
	cp	iz, 0x0010
	jr ge, .LHRW_3ce5                      ; [69 79] jr GE,0x283ce5
.LHRW_3c6c:
	pushw 0x001c
	lda_24 xwa, (0x2e2516)
	push xwa
	ldw	wa, 0x001e
	muls	xwa, xiz
	lda_24 xbc, (0x22ae40)
	exts xwa                                ; exts XWA
	add	xwa, xbc
	push xwa
	call HDAE5000_MemCopy
	ld	wa, iz
	inc	1, wa
	pushw wa                                ; push WA
	pushw 0x002e
	pushw 0x2534
	lda	xwa, (xsp+18)
	push xwa
	call HDAE5000_PPI_Block_Copy
	pushw 0x0002
	lda	xwa, (xsp+24)
	push xwa
	ldw	wa, 0x001e
	muls	xwa, xiz
	lda_24 xbc, (0x22ae3e)
	exts xwa                                ; exts XWA
	add	xwa, xbc
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+30)
	ld	bc, iz
	ldw_da	wa, (0x23A092)
	call HDAE5000_Calculate_Row_Address
	pushw 0x001a
	push xhl
	ldw	wa, 0x001e
	muls	xwa, xiz
	lda_24 xbc, (0x22ae41)
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
	lda_24 xbc, (0x2e24f0)
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	lda_24 xwa, (0x22ae3e)
	ld	xbc, xwa
	ld	xwa, xde
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0124)
	ld	xbc, 0x01ea000a
	call	(xhl)
	ld	a, (xsp+26)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, (0x2e24f0)
	ld_sril3 xwa, 0x07, 0xE4, 0xE0	; ld XWA,(XBC+WA)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0124)
	ld	xbc, 0x01c0000f
	ld	xde, 0xffffffff
	call	(xhl)
.LHRW_3d45:
	ldw_da	wa, (0x23A092)
	ldw_da	bc, (0x23A094)
	call HDAE5000_Table_Lookup
	ld	wa, hl
	cp	wa, 0xffff
	jr z, .LHRW_3d7d                       ; [66 22] jr Z,0x283d7d
	ld	a, (xsp+26)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, (0x2e24f8)
	ld_sril3 xwa, 0x07, 0xE4, 0xE0	; ld XWA,(XBC+WA)
	ldw_da	bc, (0x23A092)
	ldw_da	de, (0x23A094)
	pushw hl                                ; push HL
	calr	0xfc51
	jr t, .LHRW_3d9b                       ; [68 1e] jr T,0x283d9b
.LHRW_3d7d:
	ld	a, (xsp+26)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, (0x2e24f8)
	ld_sril3 xwa, 0x07, 0xE4, 0xE0	; ld XWA,(XBC+WA)
	pushw 0xffff
	ldw	bc, 0xffff
	ldw	de, 0xffff
	calr	0xfc31
.LHRW_3d9b:
	popw iz                                 ; pop IZ
	lda	xsp, (xsp+26)
	ret

	push xiz
	ld	xiz, xde
	ld	xwa, xbc
	cp	xwa, 0x01c00007
	jrl z, .LHRW_3f7b                      ; [76 cd 01] jrl Z,0x283f7b
	cp	xwa, 0x01c00001
	jr z, .LHRW_3de2                       ; [66 2c] jr Z,0x283de2
	sub	xwa, 0x01ea0000
	cp	xwa, 0x00000000
	jrl lt, .LHRW_3f7b                     ; [71 b6 01] jrl LT,0x283f7b
	cp	xwa, 0x0000000d
	jrl gt, .LHRW_3f7b                     ; [7a ad 01] jrl GT,0x283f7b
	add	xwa, xwa
	add	xwa, 0x002e253a
	ld	wa, (xwa)
	lda_24 xix, (0x283de2)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
.LHRW_3de2:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0103
	ld	xbc, 0x01ea0002
	lds32	xde, 0
	call	(xhl)
	jrl t, .LHRW_3f7b                      ; [78 79 01] jrl T,0x283f7b
	lda_24 xwa, (0x22aa4c)
	pushw 0x0002
	lda_24 xde, (0x2e1c8a)
	ldw	bc, 0x003f
	calr	0x14cf
	ld	(0x23a094), iz
	ldw_da	wa, (0x23A092)
	ldw_da	bc, (0x23A094)
	call HDAE5000_Calculate_Row_Address
	ld	xde, xhl
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0250)
	ld	xwa, 0x012a0001
	ld	xbc, 0x01e00086
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f004e
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	jrl t, .LHRW_3f7b                      ; [78 16 01] jrl T,0x283f7b
	ld	(0x23a094), iz
	ldw_da	wa, (0x23A092)
	ldw_da	bc, (0x23A094)
	lds	de, 0
	calr	0x675a
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f01c2
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	jrl t, .LHRW_3f7b                      ; [78 e2 00] jrl T,0x283f7b
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f01ef
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	jrl t, .LHRW_3f7b                      ; [78 c2 00] jrl T,0x283f7b
	cpw_da	(0x23A092), 0
	jrl z, .LHRW_3f7b                      ; [76 b8 00] jrl Z,0x283f7b
	decdi16_24	1, (0x23A092)
	lds	wa, 0
	lds	bc, 0
	calr	0xfc99
	ld	xwa, xiz
	add	xwa, 0x00000010
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0103
	ld	xbc, 0x01ea0003
	call	(xhl)
	jrl t, .LHRW_3f7b                      ; [78 84 00] jrl T,0x283f7b
	cpw_da	(0x23A092), 119
	jr nc, .LHRW_3f7b                      ; [6f 7b] jr NC,0x283f7b
	incdi16_24	1, (0x23A092)
	lds	wa, 0
	lds	bc, 0
	calr	0xfc5c
	ld	xwa, xiz
	sub	xwa, 0x00000010
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0103
	ld	xbc, 0x01ea0003
	call	(xhl)
	jr t, .LHRW_3f7b                       ; [68 48] jr T,0x283f7b
	ld	(0x23a094), iz
	ldw_da	wa, (0x23A092)
	ldw_da	bc, (0x23A094)
	call HDAE5000_Table_Lookup
	ld	wa, hl
	cp	wa, 0xffff
	jr z, .LHRW_3f62                       ; [66 14] jr Z,0x283f62
	lda_24 xwa, (0x22aa4c)
	pushw 0x0002
	ld	bc, hl
	lda_24 xde, (0x2e1c96)
	calr	0x1384
	jr t, .LHRW_3f74                       ; [68 12] jr T,0x283f74
.LHRW_3f62:
	lda_24 xwa, (0x22aa4c)
	pushw 0x0002
	lda_24 xde, (0x2e1c96)
	lds	bc, 0
	calr	0x1370
.LHRW_3f74:
	lds	wa, 0
	lds	bc, 1
	calr	0xfbed
.LHRW_3f7b:
	lds32	xhl, 0
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01c00007
	jr z, .LHRW_3ff0                       ; [66 64] jr Z,0x283ff0
	cp	xwa, 0x01c0000d
	jr z, .LHRW_3fb7                       ; [66 23] jr Z,0x283fb7
	cp	xwa, 0x01e00085
	jr z, .LHRW_3fb2                       ; [66 16] jr Z,0x283fb2
	ld	xwa, xiz
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xix, (xhl + 0x00dc)
	call	(xix)
	jrl t, .LHRW_40a1                      ; [78 ef 00] jrl T,0x2840a1
.LHRW_3fb2:
	lds32	xhl, 1
	jrl t, .LHRW_40a1                      ; [78 ea 00] jrl T,0x2840a1
.LHRW_3fb7:
	ld	xwa, xiz
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	lda_24 xwa, (0x2e2556)
	ld	xbc, xwa
	ld	xwa, xiz
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000f
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LHRW_40a1                      ; [78 b1 00] jrl T,0x2840a1
.LHRW_3ff0:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xix, (xwa + 0x0100)
	ld	xwa, 0x02600024
	ld	xbc, 0x01e00029
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
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f01f8
	ld	xbc, 0x01c00001
	lds32	xde, 3
	call	(xhl)
	calr	0x71e4
	ldw_da	wa, (0x23A092)
	lds	bc, 1
	lds	de, 0
	call 0x29320d
	ld	xwa, 0x007f0025
	calr	0xf6b2
	lds	wa, 0
	lds	bc, 0
	calr	0xfb05
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0104)
	ld	xwa, 0x007f0018
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	jr t, .LHRW_409f                       ; [68 1d] jr T,0x28409f
.LHRW_4082:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0104)
	ld	xwa, 0x007f0018
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
.LHRW_409f:
	lds32	xhl, 0
.LHRW_40a1:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01c00007
	jr z, .LHRW_4114                       ; [66 64] jr Z,0x284114
	cp	xwa, 0x01c0000d
	jr z, .LHRW_40db                       ; [66 23] jr Z,0x2840db
	cp	xwa, 0x01e00085
	jr z, .LHRW_40d6                       ; [66 16] jr Z,0x2840d6
	ld	xwa, xiz
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xix, (xhl + 0x00dc)
	call	(xix)
	jrl t, .LHRW_41e3                      ; [78 0d 01] jrl T,0x2841e3
.LHRW_40d6:
	lds32	xhl, 1
	jrl t, .LHRW_41e3                      ; [78 08 01] jrl T,0x2841e3
.LHRW_40db:
	ld	xwa, xiz
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	lda_24 xwa, (0x2e255c)
	ld	xbc, xwa
	ld	xwa, xiz
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000f
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LHRW_41e3                      ; [78 cf 00] jrl T,0x2841e3
.LHRW_4114:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xix, (xwa + 0x0100)
	ld	xwa, 0x02600024
	ld	xbc, 0x01e00029
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
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f0217
	ld	xbc, 0x01c00001
	lds32	xde, 3
	call	(xhl)
	calr	0x70bd
	pushw 0x0001
	pushw 0x0000
	ldw_da	wa, (0x23A092)
	ldw_da	bc, (0x23A094)
	ldw_da	de, (0x22ABE6)
	call HDAE5000_Workspace_Sub_29336B
	ldw_da	wa, (0x23A092)
	ldw_da	bc, (0x23A094)
	lds	de, 1
	calr	0x643d
	ld	xwa, 0x007f0025
	calr	0xf570
	lds	wa, 0
	lds	bc, 0
	calr	0xf9c3
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0018
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	jr t, .LHRW_41e1                       ; [68 1d] jr T,0x2841e1
.LHRW_41c4:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0104)
	ld	xwa, 0x007f01c2
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
.LHRW_41e1:
	lds32	xhl, 0
.LHRW_41e3:
	pop xiz                                 ; pop XIZ
	ret

	cp	xbc, 0x01c00007
	jr nz, .LHRW_4267                      ; [6e 7a] jr NZ,0x284267
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xix, (xwa + 0x0100)
	ld	xwa, 0x02600024
	ld	xbc, 0x01e00029
	call	(xix)
	cp	xhl, 0x00000009
	jr z, .LHRW_4218                       ; [66 08] jr Z,0x284218
	cp	xhl, 0x00000008
	jr nz, .LHRW_4267                      ; [6e 4f] jr NZ,0x284267
.LHRW_4218:
	pushw 0x0000
	ld	xwa, 0x007f0018
	push xwa
	ldw_da	wa, (0x23A092)
	ldw_da	bc, (0x23A094)
	ldw_da	de, (0x22AA4C)
	calr	0x6d05
	cpib_da	(0x229DAC), 2
	jr nz, .LHRW_4267                      ; [6e 2c] jr NZ,0x284267
	ldw_da	wa, (0x22AA4C)
	and	wa, 0x0100
	cp	wa, 0x0100
	jr nz, .LHRW_4267                      ; [6e 1d] jr NZ,0x284267
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f02f0
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
.LHRW_4267:
	lds32	xhl, 0
	ret

	cp	xbc, 0x01c00007
	jr nz, .LHRW_4295                      ; [6e 23] jr NZ,0x284295
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xix, (xwa + 0x0100)
	ld	xwa, 0x02600024
	ld	xbc, 0x01e00029
	call	(xix)
	cp	xhl, 0x0000000b
	jr z, .LHRW_4295                       ; [66 00] jr Z,0x284295
.LHRW_4295:
	lds32	xhl, 0
	ret

	push xiz
	ld	xiz, xwa
	cp	xbc, 0x01c00007
	jr z, .LHRW_42fd                       ; [66 5a] jr Z,0x2842fd
	cp	xbc, 0x01e0007c
	jr z, .LHRW_42f5                       ; [66 4a] jr Z,0x2842f5
	cp	xbc, 0x01e00084
	jr z, .LHRW_42f0                       ; [66 3d] jr Z,0x2842f0
	cp	xbc, 0x01e00086
	jr z, .LHRW_42da                       ; [66 1f] jr Z,0x2842da
	cp	xbc, 0x01e0003a
	jrl nz, .LHRW_4469                     ; [7e a5 01] jrl NZ,0x284469
	pushw 0x001a
	lda_24 xwa, (0x23a04e)
	push xwa
	push xde
	call HDAE5000_MemCopy_Reverse
	lda	xsp, (xsp+10)
	ld	xhl, xiz
	jrl t, .LHRW_446b                      ; [78 91 01] jrl T,0x28446b
.LHRW_42da:
	pushw 0x001a
	push xde
	pushw 0x0023
	pushw 0xa04e
	call HDAE5000_MemCopy_Reverse
	lda	xsp, (xsp+10)
	ld	xhl, xiz
	jrl t, .LHRW_446b                      ; [78 7b 01] jrl T,0x28446b
.LHRW_42f0:
	lds32	xhl, 0
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
	lda_24 xwa, (0x22ac7e)
	calr	0x705c
	ld	xiz, xhl
	ld	xwa, xiz
	or xwa, xwa                             ; or XWA,XWA
	jrl z, .LHRW_4469                      ; [76 41 01] jrl Z,0x284469
	ld	xwa, xiz
	push xwa
	call HDAE5000_Display_Buffer_Validate
	pushw hl                                ; push HL
	ld	xwa, xiz
	push xwa
	lda_24 xwa, (0x23a04e)
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+14)
	lda_24 xwa, (0x23a04e)
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f01ae
	ld	xbc, 0x01e00086
	call	(xhl)
	jrl t, .LHRW_4469                      ; [78 04 01] jrl T,0x284469
.LHRW_4365:
	ldw_da	wa, (0x23A092)
	ldw_da	bc, (0x23A094)
	call HDAE5000_Table_Lookup
	ld	wa, hl
	cp	wa, 0xffff
	jr nz, .LHRW_4390                      ; [6e 15] jr NZ,0x284390
	lda_24 xwa, (0x22aa4c)
	pushw 0x0002
	lda_24 xde, (0x2e1c8a)
	ldw	bc, 0x003f
	calr	0x0f56
	jr t, .LHRW_43a2                       ; [68 12] jr T,0x2843a2
.LHRW_4390:
	lda_24 xwa, (0x22aa4c)
	pushw 0x0002
	ld	bc, hl
	lda_24 xde, (0x2e1c8a)
	calr	0x0f42
.LHRW_43a2:
	lda_24 xwa, (0x23a04e)
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f01ae
	ld	xbc, 0x01e0003a
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0104)
	ld	xwa, 0x007f0182
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	jrl t, .LHRW_4469                      ; [78 85 00] jrl T,0x284469
.LHRW_43e4:
	lda_24 xwa, (0x23a04e)
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f01ae
	ld	xbc, 0x01e0003a
	call	(xhl)
	cpib_da	(0x229D9A), 1
	jr nz, .LHRW_4441                      ; [6e 33] jr NZ,0x284441
	ldw_da	wa, (0x23A092)
	ldw_da	bc, (0x23A094)
	call HDAE5000_Table_Calc_Offset
	cp	hl, 0xffff
	jr z, .LHRW_4441                       ; [66 1f] jr Z,0x284441
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0104)
	ld	xwa, 0x007f023b
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	jr t, .LHRW_4462                       ; [68 21] jr T,0x284462
.LHRW_4441:
	pushw 0x0023
	pushw 0xa04e
	pushw 0x0001
	ld	xwa, 0x007f0018
	push xwa
	ldw_da	wa, (0x23A092)
	ldw_da	bc, (0x23A094)
	ldw_da	de, (0x22AA4C)
	calr	0x6c8f
.LHRW_4462:
	lds	wa, 0
	lds	bc, 0
	calr	0xf6ff
.LHRW_4469:
	lds32	xhl, 0
.LHRW_446b:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	cp	xbc, 0x01c00007
	jr z, .LHRW_44d8                       ; [66 60] jr Z,0x2844d8
	cp	xbc, 0x01e0007c
	jr z, .LHRW_44d0                       ; [66 50] jr Z,0x2844d0
	cp	xbc, 0x01e00084
	jr z, .LHRW_44cb                       ; [66 43] jr Z,0x2844cb
	cp	xbc, 0x01e00086
	jr z, .LHRW_44af                       ; [66 1f] jr Z,0x2844af
	cp	xbc, 0x01e0003a
	jrl nz, .LHRW_4592                     ; [7e f9 00] jrl NZ,0x284592
	pushw 0x0010
	lda_24 xwa, (0x23a06e)
	push xwa
	push xde
	call HDAE5000_MemCopy_Reverse
	lda	xsp, (xsp+10)
	ld	xhl, xiz
	jrl t, .LHRW_4594                      ; [78 e5 00] jrl T,0x284594
.LHRW_44af:
	pushw 0x0010
	push xde
	pushw 0x0023
	pushw 0xa06e
	call HDAE5000_MemCopy_Reverse
	lda	xsp, (xsp+10)
	stib_da	(0x23A07E), 0
	ld	xhl, xiz
	jrl t, .LHRW_4594                      ; [78 c9 00] jrl T,0x284594
.LHRW_44cb:
	lds32	xhl, 0
	jrl t, .LHRW_4594                      ; [78 c4 00] jrl T,0x284594
.LHRW_44d0:
	ld	xhl, 0x00000010
	jrl t, .LHRW_4594                      ; [78 bc 00] jrl T,0x284594
.LHRW_44d8:
	cp	xde, 0x0000000b
	jr z, .LHRW_4546                       ; [66 66] jr Z,0x284546
	cp	xde, 0x0000008a
	jrl nz, .LHRW_4592                     ; [7e a9 00] jrl NZ,0x284592
	lda_24 xwa, (0x22abf2)
	calr	0x6e8a
	ld	xiz, xhl
	ld	xwa, xiz
	or xwa, xwa                             ; or XWA,XWA
	jrl z, .LHRW_4592                      ; [76 98 00] jrl Z,0x284592
	ld	xwa, xiz
	push xwa
	call HDAE5000_Display_Buffer_Validate
	pushw hl                                ; push HL
	ld	xwa, xiz
	push xwa
	lda_24 xwa, (0x23a06e)
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+14)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xix, (xwa + 0x050c)
	call	(xix)
	lda_24 xwa, (0x23a06e)
	ld	xbc, xwa
	ld	xwa, xhl
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01e00086
	call	(xhl)
	jr t, .LHRW_4592                       ; [68 4c] jr T,0x284592
.LHRW_4546:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xix, (xwa + 0x050c)
	call	(xix)
	lda_24 xwa, (0x23a06e)
	ld	xbc, xwa
	ld	xwa, xhl
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01e0003a
	call	(xhl)
	ldw_da	wa, (0x23A092)
	lda_24 xbc, (0x23a06e)
	ld	xde, 0x007f0022
	calr	0x67be
	ld	xwa, 0x007f0025
	calr	0xf17c
.LHRW_4592:
	lds32	xhl, 0
.LHRW_4594:
	pop xiz                                 ; pop XIZ
	ret

	lda	xsp, (xsp-112)
	push xiz
	ld (xsp + 0x6c), xde                    ; ld (XSP+0x6c),XDE
	ld	xiz, xbc
	ld (xsp + 0x70), xwa                    ; ld (XSP+0x70),XWA
	ld	xwa, xiz
	cp	xwa, 0x01c00007
	jr z, .LHRW_4602                       ; [66 56] jr Z,0x284602
	cp	xwa, 0x01c0000d
	jr z, .LHRW_45c2                       ; [66 0e] jr Z,0x2845c2
	cp	xwa, 0x01e00085
	jrl nz, .LHRW_4d61                     ; [7e a4 07] jrl NZ,0x284d61
	lds32	xhl, 1
	jrl t, .LHRW_4d7a                      ; [78 b8 07] jrl T,0x284d7a
.LHRW_45c2:
	ld xwa, (xsp + 0x70)                    ; ld XWA,(XSP+0x70)
	ld	xbc, xiz
	ld xde, (xsp + 0x6c)                    ; ld XDE,(XSP+0x6c)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	lda_24 xwa, (0x2e2562)
	ld	xbc, xwa
	ld xwa, (xsp + 0x70)                    ; ld XWA,(XSP+0x70)
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000f
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LHRW_4d7a                      ; [78 78 07] jrl T,0x284d7a
.LHRW_4602:
	ld xwa, (xsp + 0x6c)                    ; ld XWA,(XSP+0x6c)
	cp	xwa, 0x0000000b
	jrl nz, .LHRW_4d61                     ; [7e 53 07] jrl NZ,0x284d61
	calr	0xe65d
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0080)
	lds	wa, 0
	call	(xhl)
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2568
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+44)
	calr	0xe1a6
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2582
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1a)                    ; ld XWA,(XSP+0x1a)
	push xwa
	call 0x29ad08
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCopy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	0xe167
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x258a
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1e)                    ; ld XWA,(XSP+0x1e)
	push xwa
	call 0x29ad08
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCopy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	0xe128
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0080)
	lds	wa, 1
	call	(xhl)
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2592
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+44)
	calr	0xe0eb
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x25ac
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1a)                    ; ld XWA,(XSP+0x1a)
	push xwa
	call 0x29ad08
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCopy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	0xe0ac
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x25b4
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1e)                    ; ld XWA,(XSP+0x1e)
	push xwa
	call 0x29ad08
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCopy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	0xe06d
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0080)
	lds	wa, 2
	call	(xhl)
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x25bc
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+44)
	calr	0xe030
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x25d6
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1a)                    ; ld XWA,(XSP+0x1a)
	push xwa
	call 0x29ad08
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCopy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	0xdff1
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x25de
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1e)                    ; ld XWA,(XSP+0x1e)
	push xwa
	call 0x29ad08
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCopy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	0xdfb2
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0080)
	lds	wa, 3
	call	(xhl)
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x25e6
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+44)
	calr	0xdf75
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2600
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1a)                    ; ld XWA,(XSP+0x1a)
	push xwa
	call 0x29ad08
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCopy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	0xdf36
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2608
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1e)                    ; ld XWA,(XSP+0x1e)
	push xwa
	call 0x29ad08
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCopy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	0xdef7
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0080)
	lds	wa, 4
	call	(xhl)
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2610
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+44)
	calr	0xdeba
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x262a
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1a)                    ; ld XWA,(XSP+0x1a)
	push xwa
	call 0x29ad08
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCopy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	0xde7b
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2632
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1e)                    ; ld XWA,(XSP+0x1e)
	push xwa
	call 0x29ad08
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCopy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	0xde3c
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0080)
	lds	wa, 5
	call	(xhl)
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x263a
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+44)
	calr	0xddff
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2654
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1a)                    ; ld XWA,(XSP+0x1a)
	push xwa
	call 0x29ad08
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCopy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	0xddc0
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x265c
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1e)                    ; ld XWA,(XSP+0x1e)
	push xwa
	call 0x29ad08
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCopy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	0xdd81
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0080)
	lds	wa, 6
	call	(xhl)
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2664
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+44)
	calr	0xdd44
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x267c
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1a)                    ; ld XWA,(XSP+0x1a)
	push xwa
	call 0x29ad08
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCopy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	0xdd05
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2684
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1e)                    ; ld XWA,(XSP+0x1e)
	push xwa
	call 0x29ad08
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCopy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	0xdcc6
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0080)
	lds	wa, 7
	call	(xhl)
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x268c
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+44)
	calr	0xdc89
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x26a6
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1a)                    ; ld XWA,(XSP+0x1a)
	push xwa
	call 0x29ad08
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCopy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	0xdc4a
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x26ae
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1e)                    ; ld XWA,(XSP+0x1e)
	push xwa
	call 0x29ad08
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCopy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	0xdc0b
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0080)
	ldw	wa, 0x0008
	call	(xhl)
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x26b6
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+44)
	calr	0xdbcd
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x26d0
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1a)                    ; ld XWA,(XSP+0x1a)
	push xwa
	call 0x29ad08
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCopy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	0xdb8e
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x26d8
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1e)                    ; ld XWA,(XSP+0x1e)
	push xwa
	call 0x29ad08
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCopy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	0xdb4f
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0080)
	ldw	wa, 0x0009
	call	(xhl)
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x26e0
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+44)
	calr	0xdb11
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x26f8
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1a)                    ; ld XWA,(XSP+0x1a)
	push xwa
	call 0x29ad08
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCopy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	0xdad2
	pushw 0x0040
	pushw 0x0000
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_MemFill
	pushw 0x002e
	pushw 0x2700
	lda	xwa, (xsp+56)
	push xwa
	call HDAE5000_MemCopy_Block
	pushw 0x000a
	lda	xwa, (xsp+30)
	push xwa
	ld xwa, (xsp + 0x1e)                    ; ld XWA,(XSP+0x1e)
	push xwa
	call 0x29ad08
	lda	xsp, (xsp+26)
	push xhl
	lda	xwa, (xsp+48)
	push xwa
	call HDAE5000_StrCopy
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+44)
	calr	0xda93
.LHRW_4d61:
	ld xwa, (xsp + 0x70)                    ; ld XWA,(XSP+0x70)
	ld	xbc, xiz
	ld xde, (xsp + 0x6c)                    ; ld XDE,(XSP+0x6c)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xix, (xhl + 0x00dc)
	call	(xix)
.LHRW_4d7a:
	pop xiz                                 ; pop XIZ
	lda	xsp, (xsp+112)
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xiz
	push xwa
	call HDAE5000_Display_Buffer_Validate
	inc 4, xsp                              ; inc 4,XSP
	cp	hl, 0x0019
	jr ule, .LHRW_4d94                     ; [63 03] jr ULE,0x284d94
	ldw	hl, 0x0019
.LHRW_4d94:
	pushw hl                                ; push HL
	ld	xwa, xiz
	push xwa
	lda_24 xwa, (0x22abcb)
	push xwa
	call HDAE5000_MemCopy_Reverse
	lda	xsp, (xsp+10)
	lda_24 xwa, (0x22abc4)
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0068
	ld	xbc, 0x01ea000a
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0068
	ld	xbc, 0x01c0000f
	ld	xde, 0xffffffff
	call	(xhl)
	pop xiz                                 ; pop XIZ
	ret


HDAE5000_HD_Error_Check:	; 0x284DE9 (355 bytes)
	; Part 1: Display error message (0x284DE9)
	; XWA = string address. Validates length, copies to buffer, displays.
	push xiz
	ld xiz, xwa			; save string address
	ld xwa, xiz
	push xwa
	call HDAE5000_Display_Buffer_Validate
	inc 4, xsp			; cleanup arg
	cp hl, 0x0019			; cap length at 25
	jr ule, .Lhec_len_ok
	ldw hl, 0x0019
.Lhec_len_ok:
	pushw hl			; push length
	ld xwa, xiz
	push xwa			; push source
	lda_24 xwa, (0x22abcb); 0x22ABCB — dest buffer
	push xwa
	call HDAE5000_MemCopy_Reverse
	lda xsp, (xsp + 10)		; cleanup 10 bytes of args
	; Display error string
	lda_24 xwa, (0x22abc4); 0x22ABC4 — display buffer
	ld xde, xwa
	ldl_da xwa, (0x23a1a2); (0x23A1A2)
	ld_sril xwa, (xwa + 0x0e0a)             ; (XWA+0x0E0A)
	ld_sril xhl, (xwa + 0x0100)             ; (XWA+0x0100) — display handler
	ld xwa, 0x007F0068		; display params
	ld xbc, 0x01EA000A		; color/position
	call (xhl)
	; Clear display line
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0100)
	ld xwa, 0x007F0068
	ld xbc, 0x01C0000F
	ld xde, 0xFFFFFFFF
	call (xhl)
	pop xiz
	ret
	; Part 2: Error handler dispatcher (0x284E53)
	; XWA = original params, XBC = error code, XDE = extra data
	dec 0, xsp
	push xiz
	ld (xsp + 4), xde		; save extra data
	ld xiz, xbc			; XIZ = error code
	ld (xsp + 8), xwa		; save original params
	; Dispatch on error code
	ld xwa, xiz
	cp xwa, 0x01C00007		; error 7 (command failed)?
	jr z, .Lhd_err7
	cp xwa, 0x01C0000D		; error 13 (retry)?
	jr z, .Lhd_err13
	cp xwa, 0x01E00085		; error 0x85 (fatal)?
	jrl nz, .Lhd_cleanup
	lds32 xhl, 1			; return 1 (fatal)
	jrl .Lhd_exit
.Lhd_err13:
	; Error 13: retry — call callback, copy buffer, redisplay
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	ldl_da xhl, (0x23a1a2)
	ld_sril xhl, (xhl + 0x0e0a)             ; (XHL+0x0E0A)
	ld_sril xhl, (xhl + 0x00dc)             ; (XHL+0x00DC) — callback
	call (xhl)
	lda_24 xwa, (0x2e2708); 0x2E2708 — status buffer
	ld xbc, xwa
	ld xwa, (xsp + 8)
	ld xde, xbc
	ldl_da xbc, (0x23a1a2)
	ld_sril xbc, (xbc + 0x0e0a)             ; (XBC+0x0E0A)
	ld_sril xhl, (xbc + 0x0100)             ; (XBC+0x0100) — display handler
	ld xbc, 0x01C0000F
	call (xhl)
	lds32 xhl, 0			; return 0 (retry ok)
	jrl .Lhd_exit
.Lhd_err7:
	; Error 7: command failed — check sub-code
	ld xde, (xsp + 4)
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xix, (xwa + 0x0100)             ; XIX = display handler
	ld xwa, 0x02600024
	ld xbc, 0x01E00029
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
	lda_24 xwa, (0x2e270e); 0x2E270E — error string
	calr HDAE5000_HD_Error_Check	; recursive: display error
	call HDAE5000_PPORT_Init_Main
	jr .Lhd_cleanup
.Lhd_err7_display:
	call HDAE5000_PPORT_Reset
	lda_24 xwa, (0x2e271e); 0x2E271E — error string
	calr HDAE5000_HD_Error_Check	; recursive: display error
	; Reinit display handler
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0104)             ; (XWA+0x0104) — init handler
	ld xwa, 0x007F0013
	ld xbc, 0x01C00001
	lds32 xde, 0
	call (xhl)
.Lhd_cleanup:
	; Final cleanup: call error callback
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	ldl_da xhl, (0x23a1a2)
	ld_sril xhl, (xhl + 0x0e0a)
	ld_sril xix, (xhl + 0x00dc)             ; XIX = callback
	call (xix)
.Lhd_exit:
	pop xiz
	inc 0, xsp
	ret

HDAE5000_HD_Wait_Ready:	; 0x284F4C (138 bytes)
	; Set up two parameter blocks on stack from template data, then call
	; workspace handler +0x0114 twice. Validates A < 16, L <= 1, E <= 2.
	; Input: A = register index, L = bank, E = mode
	dec 0, xsp			; allocate 8 bytes on stack
	ld l, c				; save C in L
	ld xiy, 0x002E272E		; source template address (first block)
	lda xix, (xsp + 4)		; XIX = destination: stack+4
	ldiw				; copy word (XIY→XIX, both advance)
	ldiw				; copy second word
	ld xiy, 0x002E2732		; source template address (second block)
	ld xix, xsp			; XIX = destination: stack base
	ldiw				; copy word
	ldiw				; copy second word
	; --- Parameter validation ---
	cp a, 0x10			; A must be < 16
	jr nc, .Lwr_exit		; if A >= 16, bail out
	cps l, 1			; L must be <= 1
	jr ugt, .Lwr_exit		; if L > 1, bail out
	cps e, 2			; E must be <= 2
	jr ugt, .Lwr_exit		; if E > 2, bail out
	; --- Fill parameter blocks ---
	ld (xsp + 5), a			; store register index at offset 5
	ld (xsp + 1), a			; store register index at offset 1
	cps l, 0			; check bank
	jr nz, .Lwr_bank1
	ld (xsp + 7), 0x01		; bank 0: store 0x01 at offset 7
	jr t, .Lwr_mode
.Lwr_bank1:
	ld (xsp + 7), 0x20		; bank 1: store 0x20 at offset 7
.Lwr_mode:
	cps e, 0			; check mode
	jr nz, .Lwr_mode1
	ld (xsp + 3), 0x00		; mode 0: store 0x00 at offset 3
	jr t, .Lwr_call
.Lwr_mode1:
	cps e, 1			; mode 1?
	jr nz, .Lwr_mode2
	ld (xsp + 3), 0x01		; mode 1: store 0x01 at offset 3
	jr t, .Lwr_call
.Lwr_mode2:
	ld (xsp + 3), 0x02		; mode 2: store 0x02 at offset 3
.Lwr_call:
	; --- First workspace call (stack+4 block) ---
	lda xwa, (xsp + 4)		; XWA = pointer to first param block
	ld xde, xwa			; XDE = param block ptr
	ldl_da xwa, (0x23a1a2); ld XWA, (0x23A1A2) — workspace ptr
	ld_sril xwa, (xwa + 0x0e88)             ; ld XWA, (XWA + 0x0E88)
	ld_sril xhl, (xwa + 0x0114)             ; ld XHL, (XWA + 0x0114)
	lds wa, 0			; WA = 0
	lds bc, 4			; BC = 4 (param count)
	call (xhl)			; call handler
	; --- Second workspace call (stack base block) ---
	lda xwa, (xsp)			; XWA = pointer to second param block
	ld xde, xwa			; XDE = param block ptr
	ldl_da xwa, (0x23a1a2); ld XWA, (0x23A1A2) — workspace ptr
	ld_sril xwa, (xwa + 0x0e88)             ; ld XWA, (XWA + 0x0E88)
	ld_sril xhl, (xwa + 0x0114)             ; ld XHL, (XWA + 0x0114)
	lds wa, 0			; WA = 0
	lds bc, 4			; BC = 4
	call (xhl)			; call handler
.Lwr_exit:
	inc 0, xsp			; deallocate 8 bytes
	ret

HDAE5000_HD_Status_Check:	; 0x284FD6 (782 bytes)
	; Check HD status flags at 0x22B2F4, 0x23A0A0
	; Part 1: Main status check — dispatch on disk state byte at 0x22B2F4
	ldb_da xwa, (0x22b2f4); ld A, (0x22B2F4)
	extz wa
	ldl_da xbc, (0x23a1a2); ld XBC, (0x23A1A2)
	ld_sril xbc, (xbc + 0x0e88)             ; ld XBC, (XBC + 0x0E88)
	ld_sril xhl, (xbc + 0x0084)             ; ld XHL, (XBC + 0x0084)
	call (xhl)			; callback
	cpib_da (0x23a0a2), 0x00; cp (0x23A0A2), 0
	jr z, .LHD_SC__skip_a2
	ldb_da xwa, (0x23a0a2); ld A, (0x23A0A2)
	dec 1, a
	extz wa
	lds bc, 0
	lds de, 0
	calr HDAE5000_HD_Wait_Ready
	stib_da (0x23a0a2), 0x00; (0x23A0A2) = 0
.LHD_SC__skip_a2:
	cpib_da (0x23a0a4), 0x00; cp (0x23A0A4), 0
	jr z, .LHD_SC__dispatch
	ldb_da xwa, (0x23a0a4); ld A, (0x23A0A4)
	dec 1, a
	extz wa
	lds bc, 0
	lds de, 0
	calr HDAE5000_HD_Wait_Ready
	stib_da (0x23a0a4), 0x00; (0x23A0A4) = 0
.LHD_SC__dispatch:
	ldb_da xwa, (0x22b2f4); re-read state byte
	cps a, 3
	jr z, .LHD_SC__state3
	cps a, 2
	jr z, .LHD_SC__state2
	cps a, 1
	jr z, .LHD_SC__state1
	cps a, 0
	ret z
	ret
.LHD_SC__state1:			; state=1: process A0A0, copy to A0A2
	cpib_da (0x23a0a0), 0x00
	ret z
	ldb_da xwa, (0x23a0a0)
	dec 1, a
	extz wa
	lds bc, 1
	lds de, 0
	calr HDAE5000_HD_Wait_Ready
	ldb_da xwa, (0x23a0a0)
	stb_da (0x23a0a2), a; (0x23A0A2) = A
	ret
.LHD_SC__state2:			; state=2: process A0A0+A09E
	cpib_da (0x23a0a0), 0x00
	jr z, .LHD_SC__s2_check_9e
	ldb_da xwa, (0x23a0a0)
	dec 1, a
	extz wa
	lds bc, 1
	lds de, 0
	calr HDAE5000_HD_Wait_Ready
	ldb_da xwa, (0x23a0a0)
	stb_da (0x23a0a2), a
.LHD_SC__s2_check_9e:
	cpib_da (0x23a09e), 0x00
	ret z
	ldb_da xwa, (0x23a09e)
	dec 1, a
	extz wa
	lds bc, 1
	lds de, 0
	calr HDAE5000_HD_Wait_Ready
	ldb_da xwa, (0x23a09e)
	stb_da (0x23a0a4), a
	ret
.LHD_SC__state3:			; state=3: process A0A0 (DE=2) + A09E (DE=1)
	cpib_da (0x23a0a0), 0x00
	jr z, .LHD_SC__s3_check_9e
	ldb_da xwa, (0x23a0a0)
	dec 1, a
	extz wa
	lds bc, 1
	lds de, 2
	calr HDAE5000_HD_Wait_Ready
	ldb_da xwa, (0x23a0a0)
	stb_da (0x23a0a2), a
.LHD_SC__s3_check_9e:
	cpib_da (0x23a09e), 0x00
	ret z
	ldb_da xwa, (0x23a09e)
	dec 1, a
	extz wa
	lds bc, 1
	lds de, 1
	calr HDAE5000_HD_Wait_Ready
	ldb_da xwa, (0x23a09e)
	stb_da (0x23a0a4), a
	ret
	;
	; Part 2: Event handler 1 (0x2850ED) — jump table dispatch
.LHD_SC__handler1:
	push xiz
	ld xiz, xwa			; save context in XIZ
	ld xwa, xbc			; XWA = event code
	cp xwa, 0x01e00082		; special event?
	jr z, .LHD_SC__h1_event82
	sub xwa, 0x01e0003e		; normalize to 0-based index
	cp xwa, 0x00000000
	jrl lt, .LHD_SC__h1_default
	cp xwa, 0x00000009
	jr gt, .LHD_SC__h1_default
	add xwa, xwa			; index * 2 (16-bit offsets)
	add xwa, 0x002e278a		; + jump table base
	ld wa, (xwa)			; WA = offset
	lda_24 xix, (0x285125); XIX = dispatch base (h1_case9)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp (XIX + WA)
.LHD_SC__h1_case9:			; case 9 (offset 0x0000): PPI block copy
	ld xwa, (xde + 0x0e)
	sll xwa, 2
	ld xbc, 0x002e2736		; secondary data table
	add xbc, xwa
	ld xwa, (xbc)			; load address from table
	push xwa
	pushw 0x002e		; push 0x002E
	pushw 0x2786
	ld xwa, (xde + 0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda xsp, (xsp + 0x0c)		; deallocate 12 bytes
	ld xhl, xiz			; return saved context
	jr t, .LHD_SC__h1_exit
.LHD_SC__h1_case0:			; case 0 (offset 0x0025)
	lds32 xhl, 1
	jr t, .LHD_SC__h1_exit
.LHD_SC__h1_case1:			; case 1 (offset 0x0029)
	lds32 xhl, 1
	jr t, .LHD_SC__h1_exit
.LHD_SC__h1_case5:			; case 5 (offset 0x002D)
	lds32 xhl, 3
	jr t, .LHD_SC__h1_exit
.LHD_SC__h1_case6:			; case 6 (offset 0x0031)
	lds32 xhl, 0
	jr t, .LHD_SC__h1_exit
.LHD_SC__h1_case7:			; case 7 (offset 0x0035)
	lda_24 xhl, (0x22b2f4)
	jr t, .LHD_SC__h1_exit
.LHD_SC__h1_case8:			; case 8 (offset 0x003C)
	lds32 xhl, 1
	jr t, .LHD_SC__h1_exit
.LHD_SC__h1_event82:			; event 0x01E00082: callback chain
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)             ; ld XWA, (XWA + 0x0E0A)
	ld_sril xhl, (xwa + 0x0538)             ; ld XHL, (XWA + 0x0538)
	call (xhl)
	calr HDAE5000_HD_Status_Check	; recursive call
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x053c)             ; ld XHL, (XWA + 0x053C)
	call (xhl)
	lds32 xhl, 0
	jr t, .LHD_SC__h1_exit
.LHD_SC__h1_default:			; out-of-range
	lds32 xhl, 0
.LHD_SC__h1_exit:
	pop xiz
	ret
	;
	; Part 3: Event handler 2 (0x285192) — same structure, different data
.LHD_SC__handler2:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xwa, 0x01e00082
	jr z, .LHD_SC__h2_event82
	sub xwa, 0x01e0003e
	cp xwa, 0x00000000
	jrl lt, .LHD_SC__h2_default
	cp xwa, 0x00000009
	jrl gt, .LHD_SC__h2_default
	add xwa, xwa
	add xwa, 0x002e284c		; jump table 2
	ld wa, (xwa)
	lda_24 xix, (0x2851cb); XIX = dispatch base (h2_case9)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp (XIX + WA)
.LHD_SC__h2_case9:			; case 9: PPI block copy
	ld xwa, (xde + 0x0e)
	sll xwa, 2
	ld xbc, 0x002e279e		; secondary data table 2
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	pushw 0x002e		; push 0x002E
	pushw 0x2848
	ld xwa, (xde + 0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda xsp, (xsp + 0x0c)
	ld xhl, xiz
	jr t, .LHD_SC__h2_exit
.LHD_SC__h2_case0:
	lds32 xhl, 1
	jr t, .LHD_SC__h2_exit
.LHD_SC__h2_case1:
	lds32 xhl, 1
	jr t, .LHD_SC__h2_exit
.LHD_SC__h2_case5:			; case 5: XHL = 0x10
	ld xhl, 0x00000010
	jr t, .LHD_SC__h2_exit
.LHD_SC__h2_case6:
	lds32 xhl, 0
	jr t, .LHD_SC__h2_exit
.LHD_SC__h2_case7:			; case 7: lda XHL, 0x23A0A0
	lda_24 xhl, (0x23a0a0)
	jr t, .LHD_SC__h2_exit
.LHD_SC__h2_case8:
	lds32 xhl, 1
	jr t, .LHD_SC__h2_exit
.LHD_SC__h2_event82:
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0538)
	call (xhl)
	calr HDAE5000_HD_Status_Check
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x053c)
	call (xhl)
	lds32 xhl, 0
	jr t, .LHD_SC__h2_exit
.LHD_SC__h2_default:
	lds32 xhl, 0
.LHD_SC__h2_exit:
	pop xiz
	ret
	;
	; Part 4: Event handler 3 (0x28523B) — same structure, different data
.LHD_SC__handler3:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xwa, 0x01e00082
	jr z, .LHD_SC__h3_event82
	sub xwa, 0x01e0003e
	cp xwa, 0x00000000
	jrl lt, .LHD_SC__h3_default
	cp xwa, 0x00000009
	jrl gt, .LHD_SC__h3_default
	add xwa, xwa
	add xwa, 0x002e290e		; jump table 3
	ld wa, (xwa)
	lda_24 xix, (0x285274); XIX = dispatch base (h3_case9)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp (XIX + WA)
.LHD_SC__h3_case9:			; case 9: PPI block copy
	ld xwa, (xde + 0x0e)
	sll xwa, 2
	ld xbc, 0x002e2860		; secondary data table 3
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	pushw 0x002e		; push 0x002E
	pushw 0x290a		; push 0x290A
	ld xwa, (xde + 0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda xsp, (xsp + 0x0c)
	ld xhl, xiz
	jr t, .LHD_SC__h3_exit
.LHD_SC__h3_case0:
	lds32 xhl, 1
	jr t, .LHD_SC__h3_exit
.LHD_SC__h3_case1:
	lds32 xhl, 1
	jr t, .LHD_SC__h3_exit
.LHD_SC__h3_case5:			; case 5: XHL = 0x10
	ld xhl, 0x00000010
	jr t, .LHD_SC__h3_exit
.LHD_SC__h3_case6:
	lds32 xhl, 0
	jr t, .LHD_SC__h3_exit
.LHD_SC__h3_case7:			; case 7: lda XHL, 0x23A09E
	lda_24 xhl, (0x23a09e)
	jr t, .LHD_SC__h3_exit
.LHD_SC__h3_case8:
	lds32 xhl, 1
	jr t, .LHD_SC__h3_exit
.LHD_SC__h3_event82:
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0538)
	call (xhl)
	calr HDAE5000_HD_Status_Check
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x053c)
	call (xhl)
	lds32 xhl, 0
	jr t, .LHD_SC__h3_exit
.LHD_SC__h3_default:
	lds32 xhl, 0
.LHD_SC__h3_exit:
	pop xiz
	ret

HDAE5000_HD_Data_Copy:	; 0x2852E4 (92 bytes)
	; Copy 12-byte record from (XDE) to (XWA) via ldirw, then set flag bytes
	; Input: XWA = dest, XDE = src, BC = flags (HL), E from stack = flag value
	; Returns with retd (deallocates 2 bytes from stack)
	ld xix, xde			; save source
	ld hl, bc			; HL = flags
	ld e, (xsp + 4)			; E = flag byte from stack
	ld xiy, xix			; XIY = source
	ld xix, xwa			; XIX = dest (for ldirw)
	lds bc, 6			; count = 6 words (12 bytes)
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

HDAE5000_HD_Buffer_Init:	; 0x285340 (220 bytes)
	; Sub-routine 1: Build bit flags from partition status array
	; Input: XWA = pointer to buffer (byte 0-1 = output flags, bytes 2-10 = status)
	; Sets bit N in (XWA) for each partition N whose status byte == 2
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
	push xiz
	ld xiz, xwa			; save context
	ld xwa, xbc			; command → XWA
	cp xwa, 0x01E00082		; special command?
	jr z, .Lhbi_special
	sub xwa, 0x01E0003E		; normalize to index 0-9
	cp xwa, 0x00000000
	jr lt, .Lhbi_default
	cp xwa, 0x00000009
	jr gt, .Lhbi_default
	add xwa, xwa			; index * 2 (table has 16-bit entries)
	add xwa, 0x002E293E		; jump table base
	ld wa, (xwa + 0)		; load offset from table
	lda_24 xix, (0x2853d6); base of case handlers (0x2853D6)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T, XIX+WA
.Lhbi_case0:
	; Case 0: PPI block copy from device
	pushw 0x0023
	pushw 0xA04E
	pushw 0x002E
	pushw 0x293A
	ld xwa, (xde + 18)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda xsp, (xsp + 12)		; pop args
	ld xhl, xiz			; return context ptr
	jr t, .Lhbi_exit
.Lhbi_case1:
	lds32 xhl, 1
	jr t, .Lhbi_exit
.Lhbi_case2:
	lds32 xhl, 1
	jr t, .Lhbi_exit
.Lhbi_case3:
	lds32 xhl, 0
	jr t, .Lhbi_exit
.Lhbi_case4:
	lds32 xhl, 0
	jr t, .Lhbi_exit
.Lhbi_case5:
	lda_24 xhl, (0x22aa57); 0x22AA57
	jr t, .Lhbi_exit
.Lhbi_case6:
	lds32 xhl, 1
	jr t, .Lhbi_exit
.Lhbi_special:
	; Command 0x01E00082: init buffer then return 0
	lda_24 xwa, (0x22aa4c); 0x22AA4C
	calr HDAE5000_HD_Buffer_Init
	lds32 xhl, 0
	jr t, .Lhbi_exit
.Lhbi_default:
	lds32 xhl, 0
.Lhbi_exit:
	pop xiz
	ret

; --- HD Configuration Manager and CHS Geometry ---
HDAE5000_HD_Config_Manager:	; 0x28541C (3728 bytes)
; LHCM: 0x28541C (3728 bytes)

	ldb_da	a, (0x22AA4E)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, (0x2e2922)
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0104)
	ld	xwa, 0x007f0196
	ld	xbc, 0x01c0000f
	call	(xhl)
	ldb_da	a, (0x22AA4F)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, (0x2e2922)
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0104)
	ld	xwa, 0x007f0197
	ld	xbc, 0x01c0000f
	call	(xhl)
	ldb_da	a, (0x22AA50)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, (0x2e2922)
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0104)
	ld	xwa, 0x007f0198
	ld	xbc, 0x01c0000f
	call	(xhl)
	ldb_da	a, (0x22AA51)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, (0x2e2922)
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0104)
	ld	xwa, 0x007f0194
	ld	xbc, 0x01c0000f
	call	(xhl)
	ldb_da	a, (0x22AA52)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, (0x2e2922)
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0104)
	ld	xwa, 0x007f0199
	ld	xbc, 0x01c0000f
	call	(xhl)
	ldb_da	a, (0x22AA53)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, (0x2e2922)
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0104)
	ld	xwa, 0x007f019a
	ld	xbc, 0x01c0000f
	call	(xhl)
	ldb_da	a, (0x22AA54)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, (0x2e2922)
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0104)
	ld	xwa, 0x007f019b
	ld	xbc, 0x01c0000f
	call	(xhl)
	ldb_da	a, (0x22AA55)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, (0x2e2922)
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0104)
	ld	xwa, 0x007f019c
	ld	xbc, 0x01c0000f
	call	(xhl)
	ldb_da	a, (0x22AA56)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	lda_24 xbc, (0x2e2922)
	ld_sril3 xde, 0x07, 0xE4, 0xE0	; ld XDE,(XBC+WA)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0104)
	ld	xwa, 0x007f01aa
	ld	xbc, 0x01c0000f
	jp	(xhl)
	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01c00007
	jr z, .LHCM_5634                       ; [66 64] jr Z,0x285634
	cp	xwa, 0x01c0000d
	jr z, .LHCM_55fb                       ; [66 23] jr Z,0x2855fb
	cp	xwa, 0x01e00085
	jr z, .LHCM_55f6                       ; [66 16] jr Z,0x2855f6
	ld	xwa, xiz
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xix, (xhl + 0x00dc)
	call	(xix)
	jrl t, .LHCM_577a                      ; [78 84 01] jrl T,0x28577a
.LHCM_55f6:
	lds32	xhl, 1
	jrl t, .LHCM_577a                      ; [78 7f 01] jrl T,0x28577a
.LHCM_55fb:
	ld	xwa, xiz
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	lda_24 xwa, (0x2e2952)
	ld	xbc, xwa
	ld	xwa, xiz
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000f
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LHCM_577a                      ; [78 46 01] jrl T,0x28577a
.LHCM_5634:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xix, (xwa + 0x0100)
	ld	xwa, 0x02600024
	ld	xbc, 0x01e00029
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
	lda_24 xwa, (0x23a04e)
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f01ae
	ld	xbc, 0x01e0003a
	call	(xhl)
	cpib_da	(0x229D9A), 1
	jr nz, .LHCM_56d9                      ; [6e 33] jr NZ,0x2856d9
	ldw_da	wa, (0x23A092)
	ldw_da	bc, (0x23A094)
	call HDAE5000_Table_Calc_Offset
	cp	hl, 0xffff
	jr z, .LHCM_56d9                       ; [66 1f] jr Z,0x2856d9
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0104)
	ld	xwa, 0x007f023b
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	jr t, .LHCM_56fa                       ; [68 21] jr T,0x2856fa
.LHCM_56d9:
	pushw 0x0023
	pushw 0xa04e
	pushw 0x0001
	ld	xwa, 0x007f0018
	push xwa
	ldw_da	wa, (0x23A092)
	ldw_da	bc, (0x23A094)
	ldw_da	de, (0x22AA4C)
	calr	0x59f7
.LHCM_56fa:
	lds	wa, 0
	lds	bc, 0
	calr	0xe467
	jr t, .LHCM_5778                       ; [68 75] jr T,0x285778
.LHCM_5703:
	lda_24 xwa, (0x22aa4c)
	pushw 0x0002
	lda_24 xde, (0x2e1c8a)
	ldw	bc, 0x003f
	calr	0xfbce
	calr	0xfd03
	jr t, .LHCM_5778                       ; [68 5d] jr T,0x285778
.LHCM_571b:
	lda_24 xwa, (0x22aa4c)
	pushw 0x0002
	lda_24 xde, (0x2e1c8a)
	ldw	bc, 0x01ff
	calr	0xfbb6
	calr	0xfceb
	jr t, .LHCM_5778                       ; [68 45] jr T,0x285778
.LHCM_5733:
	lda_24 xwa, (0x22aa4c)
	pushw 0x0002
	lda_24 xde, (0x2e1c8a)
	lds	bc, 0
	calr	0xfb9f
	calr	0xfcd4
	jr t, .LHCM_5778                       ; [68 2e] jr T,0x285778
.LHCM_574a:
	ldw_da	bc, (0x22AA4C)
	ld	wa, bc
	and	wa, 0x0100
	cp	wa, 0x0100
	jr nz, .LHCM_5761                      ; [6e 06] jr NZ,0x285761
	sub	bc, 0x0100
	jr t, .LHCM_5765                       ; [68 04] jr T,0x285765
.LHCM_5761:
	add	bc, 0x0100
.LHCM_5765:
	lda_24 xwa, (0x22aa4c)
	pushw 0x0002
	lda_24 xde, (0x2e1c8a)
	calr	0xfb6f
	calr	0xfca4
.LHCM_5778:
	lds32	xhl, 0
.LHCM_577a:
	pop xiz                                 ; pop XIZ
	ret

	dec	4, xsp
	push xiz
	ld (xsp + 0x04), xwa                    ; ld (XSP+0x04),XWA
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jr z, .LHCM_57f8                       ; [66 6c] jr Z,0x2857f8
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jr lt, .LHCM_57fc                      ; [61 62] jr LT,0x2857fc
	cp	xwa, 0x00000009
	jr gt, .LHCM_57fc                      ; [6a 5a] jr GT,0x2857fc
	add	xwa, xwa
	add	xwa, 0x002e295c
	ld	wa, (xwa)
	lda_24 xix, (0x2857b6)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	ld	xiz, xde
	ldw_da	wa, (0x23A092)
	ldw_da	bc, (0x23A094)
	call HDAE5000_Calculate_Row_Address
	push xhl
	pushw 0x002e
	pushw 0x2958
	ld xwa, (xiz + 0x12)                    ; ld XWA,(XIZ+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	ld xhl, (xsp + 0x04)                    ; ld XHL,(XSP+0x04)
	jr t, .LHCM_57fe                       ; [68 21] jr T,0x2857fe
	lds32	xhl, 1
	jr t, .LHCM_57fe                       ; [68 1d] jr T,0x2857fe
	lds32	xhl, 1
	jr t, .LHCM_57fe                       ; [68 19] jr T,0x2857fe
	lds32	xhl, 0
	jr t, .LHCM_57fe                       ; [68 15] jr T,0x2857fe
	lds32	xhl, 0
	jr t, .LHCM_57fe                       ; [68 11] jr T,0x2857fe
	lda_24 xhl, (0x22aa57)
	jr t, .LHCM_57fe                       ; [68 0a] jr T,0x2857fe
	lds32	xhl, 1
	jr t, .LHCM_57fe                       ; [68 06] jr T,0x2857fe
.LHCM_57f8:
	lds32	xhl, 0
	jr t, .LHCM_57fe                       ; [68 02] jr T,0x2857fe
.LHCM_57fc:
	lds32	xhl, 0
.LHCM_57fe:
	pop xiz                                 ; pop XIZ
	inc 4, xsp                              ; inc 4,XSP
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jrl z, .LHCM_5890                      ; [76 80 00] jrl Z,0x285890
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jrl lt, .LHCM_58b4                     ; [71 95 00] jrl LT,0x2858b4
	cp	xwa, 0x00000009
	jrl gt, .LHCM_58b4                     ; [7a 8c 00] jrl GT,0x2858b4
	add	xwa, xwa
	add	xwa, 0x002e2974
	ld	wa, (xwa)
	lda_24 xix, (0x28583c)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, 0x002e2922
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2970
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_58b6                       ; [68 55] jr T,0x2858b6
	lds32	xhl, 1
	jr t, .LHCM_58b6                       ; [68 51] jr T,0x2858b6
	lds32	xhl, 1
	jr t, .LHCM_58b6                       ; [68 4d] jr T,0x2858b6
	lds32	xhl, 2
	cpib_da	(0x22AA4E), 0
	jr nz, .LHCM_5875                      ; [6e 02] jr NZ,0x285875
	lds32	xhl, 0
.LHCM_5875:
	jr t, .LHCM_58b6                       ; [68 3f] jr T,0x2858b6
	lds32	xhl, 1
	cpib_da	(0x22AA4E), 0
	jr nz, .LHCM_5883                      ; [6e 02] jr NZ,0x285883
	lds32	xhl, 0
.LHCM_5883:
	jr t, .LHCM_58b6                       ; [68 31] jr T,0x2858b6
	lda_24 xhl, (0x22aa4e)
	jr t, .LHCM_58b6                       ; [68 2a] jr T,0x2858b6
	lds32	xhl, 1
	jr t, .LHCM_58b6                       ; [68 26] jr T,0x2858b6
.LHCM_5890:
	lda_24 xwa, (0x22aa4c)
	calr	0xfaa8
	ldw_da	bc, (0x23A092)
	ldw_da	de, (0x23A094)
	ldw_da	wa, (0x22AA4C)
	pushw wa                                ; push WA
	ld	xwa, 0x007f0102
	calr	0xe11c
	lds32	xhl, 0
	jr t, .LHCM_58b6                       ; [68 02] jr T,0x2858b6
.LHCM_58b4:
	lds32	xhl, 0
.LHCM_58b6:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jrl z, .LHCM_5946                      ; [76 80 00] jrl Z,0x285946
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jrl lt, .LHCM_596a                     ; [71 95 00] jrl LT,0x28596a
	cp	xwa, 0x00000009
	jrl gt, .LHCM_596a                     ; [7a 8c 00] jrl GT,0x28596a
	add	xwa, xwa
	add	xwa, 0x002e298c
	ld	wa, (xwa)
	lda_24 xix, (0x2858f2)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, 0x002e2922
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2988
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_596c                       ; [68 55] jr T,0x28596c
	lds32	xhl, 1
	jr t, .LHCM_596c                       ; [68 51] jr T,0x28596c
	lds32	xhl, 1
	jr t, .LHCM_596c                       ; [68 4d] jr T,0x28596c
	lds32	xhl, 2
	cpib_da	(0x22AA4F), 0
	jr nz, .LHCM_592b                      ; [6e 02] jr NZ,0x28592b
	lds32	xhl, 0
.LHCM_592b:
	jr t, .LHCM_596c                       ; [68 3f] jr T,0x28596c
	lds32	xhl, 1
	cpib_da	(0x22AA4F), 0
	jr nz, .LHCM_5939                      ; [6e 02] jr NZ,0x285939
	lds32	xhl, 0
.LHCM_5939:
	jr t, .LHCM_596c                       ; [68 31] jr T,0x28596c
	lda_24 xhl, (0x22aa4f)
	jr t, .LHCM_596c                       ; [68 2a] jr T,0x28596c
	lds32	xhl, 1
	jr t, .LHCM_596c                       ; [68 26] jr T,0x28596c
.LHCM_5946:
	lda_24 xwa, (0x22aa4c)
	calr	0xf9f2
	ldw_da	bc, (0x23A092)
	ldw_da	de, (0x23A094)
	ldw_da	wa, (0x22AA4C)
	pushw wa                                ; push WA
	ld	xwa, 0x007f0102
	calr	0xe066
	lds32	xhl, 0
	jr t, .LHCM_596c                       ; [68 02] jr T,0x28596c
.LHCM_596a:
	lds32	xhl, 0
.LHCM_596c:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jrl z, .LHCM_59fc                      ; [76 80 00] jrl Z,0x2859fc
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jrl lt, .LHCM_5a20                     ; [71 95 00] jrl LT,0x285a20
	cp	xwa, 0x00000009
	jrl gt, .LHCM_5a20                     ; [7a 8c 00] jrl GT,0x285a20
	add	xwa, xwa
	add	xwa, 0x002e29a4
	ld	wa, (xwa)
	lda_24 xix, (0x2859a8)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, 0x002e2922
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x29a0
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_5a22                       ; [68 55] jr T,0x285a22
	lds32	xhl, 1
	jr t, .LHCM_5a22                       ; [68 51] jr T,0x285a22
	lds32	xhl, 1
	jr t, .LHCM_5a22                       ; [68 4d] jr T,0x285a22
	lds32	xhl, 2
	cpib_da	(0x22AA50), 0
	jr nz, .LHCM_59e1                      ; [6e 02] jr NZ,0x2859e1
	lds32	xhl, 0
.LHCM_59e1:
	jr t, .LHCM_5a22                       ; [68 3f] jr T,0x285a22
	lds32	xhl, 1
	cpib_da	(0x22AA50), 0
	jr nz, .LHCM_59ef                      ; [6e 02] jr NZ,0x2859ef
	lds32	xhl, 0
.LHCM_59ef:
	jr t, .LHCM_5a22                       ; [68 31] jr T,0x285a22
	lda_24 xhl, (0x22aa50)
	jr t, .LHCM_5a22                       ; [68 2a] jr T,0x285a22
	lds32	xhl, 1
	jr t, .LHCM_5a22                       ; [68 26] jr T,0x285a22
.LHCM_59fc:
	lda_24 xwa, (0x22aa4c)
	calr	0xf93c
	ldw_da	bc, (0x23A092)
	ldw_da	de, (0x23A094)
	ldw_da	wa, (0x22AA4C)
	pushw wa                                ; push WA
	ld	xwa, 0x007f0102
	calr	0xdfb0
	lds32	xhl, 0
	jr t, .LHCM_5a22                       ; [68 02] jr T,0x285a22
.LHCM_5a20:
	lds32	xhl, 0
.LHCM_5a22:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jrl z, .LHCM_5ab2                      ; [76 80 00] jrl Z,0x285ab2
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jrl lt, .LHCM_5ad6                     ; [71 95 00] jrl LT,0x285ad6
	cp	xwa, 0x00000009
	jrl gt, .LHCM_5ad6                     ; [7a 8c 00] jrl GT,0x285ad6
	add	xwa, xwa
	add	xwa, 0x002e29bc
	ld	wa, (xwa)
	lda_24 xix, (0x285a5e)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, 0x002e2922
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x29b8
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_5ad8                       ; [68 55] jr T,0x285ad8
	lds32	xhl, 1
	jr t, .LHCM_5ad8                       ; [68 51] jr T,0x285ad8
	lds32	xhl, 1
	jr t, .LHCM_5ad8                       ; [68 4d] jr T,0x285ad8
	lds32	xhl, 2
	cpib_da	(0x22AA51), 0
	jr nz, .LHCM_5a97                      ; [6e 02] jr NZ,0x285a97
	lds32	xhl, 0
.LHCM_5a97:
	jr t, .LHCM_5ad8                       ; [68 3f] jr T,0x285ad8
	lds32	xhl, 1
	cpib_da	(0x22AA51), 0
	jr nz, .LHCM_5aa5                      ; [6e 02] jr NZ,0x285aa5
	lds32	xhl, 0
.LHCM_5aa5:
	jr t, .LHCM_5ad8                       ; [68 31] jr T,0x285ad8
	lda_24 xhl, (0x22aa51)
	jr t, .LHCM_5ad8                       ; [68 2a] jr T,0x285ad8
	lds32	xhl, 1
	jr t, .LHCM_5ad8                       ; [68 26] jr T,0x285ad8
.LHCM_5ab2:
	lda_24 xwa, (0x22aa4c)
	calr	0xf886
	ldw_da	bc, (0x23A092)
	ldw_da	de, (0x23A094)
	ldw_da	wa, (0x22AA4C)
	pushw wa                                ; push WA
	ld	xwa, 0x007f0102
	calr	0xdefa
	lds32	xhl, 0
	jr t, .LHCM_5ad8                       ; [68 02] jr T,0x285ad8
.LHCM_5ad6:
	lds32	xhl, 0
.LHCM_5ad8:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jrl z, .LHCM_5b68                      ; [76 80 00] jrl Z,0x285b68
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jrl lt, .LHCM_5b8c                     ; [71 95 00] jrl LT,0x285b8c
	cp	xwa, 0x00000009
	jrl gt, .LHCM_5b8c                     ; [7a 8c 00] jrl GT,0x285b8c
	add	xwa, xwa
	add	xwa, 0x002e29d4
	ld	wa, (xwa)
	lda_24 xix, (0x285b14)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, 0x002e2922
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x29d0
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_5b8e                       ; [68 55] jr T,0x285b8e
	lds32	xhl, 1
	jr t, .LHCM_5b8e                       ; [68 51] jr T,0x285b8e
	lds32	xhl, 1
	jr t, .LHCM_5b8e                       ; [68 4d] jr T,0x285b8e
	lds32	xhl, 2
	cpib_da	(0x22AA52), 0
	jr nz, .LHCM_5b4d                      ; [6e 02] jr NZ,0x285b4d
	lds32	xhl, 0
.LHCM_5b4d:
	jr t, .LHCM_5b8e                       ; [68 3f] jr T,0x285b8e
	lds32	xhl, 1
	cpib_da	(0x22AA52), 0
	jr nz, .LHCM_5b5b                      ; [6e 02] jr NZ,0x285b5b
	lds32	xhl, 0
.LHCM_5b5b:
	jr t, .LHCM_5b8e                       ; [68 31] jr T,0x285b8e
	lda_24 xhl, (0x22aa52)
	jr t, .LHCM_5b8e                       ; [68 2a] jr T,0x285b8e
	lds32	xhl, 1
	jr t, .LHCM_5b8e                       ; [68 26] jr T,0x285b8e
.LHCM_5b68:
	lda_24 xwa, (0x22aa4c)
	calr	0xf7d0
	ldw_da	bc, (0x23A092)
	ldw_da	de, (0x23A094)
	ldw_da	wa, (0x22AA4C)
	pushw wa                                ; push WA
	ld	xwa, 0x007f0102
	calr	0xde44
	lds32	xhl, 0
	jr t, .LHCM_5b8e                       ; [68 02] jr T,0x285b8e
.LHCM_5b8c:
	lds32	xhl, 0
.LHCM_5b8e:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jrl z, .LHCM_5c1e                      ; [76 80 00] jrl Z,0x285c1e
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jrl lt, .LHCM_5c42                     ; [71 95 00] jrl LT,0x285c42
	cp	xwa, 0x00000009
	jrl gt, .LHCM_5c42                     ; [7a 8c 00] jrl GT,0x285c42
	add	xwa, xwa
	add	xwa, 0x002e29ec
	ld	wa, (xwa)
	lda_24 xix, (0x285bca)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, 0x002e2922
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x29e8
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_5c44                       ; [68 55] jr T,0x285c44
	lds32	xhl, 1
	jr t, .LHCM_5c44                       ; [68 51] jr T,0x285c44
	lds32	xhl, 1
	jr t, .LHCM_5c44                       ; [68 4d] jr T,0x285c44
	lds32	xhl, 2
	cpib_da	(0x22AA53), 0
	jr nz, .LHCM_5c03                      ; [6e 02] jr NZ,0x285c03
	lds32	xhl, 0
.LHCM_5c03:
	jr t, .LHCM_5c44                       ; [68 3f] jr T,0x285c44
	lds32	xhl, 1
	cpib_da	(0x22AA53), 0
	jr nz, .LHCM_5c11                      ; [6e 02] jr NZ,0x285c11
	lds32	xhl, 0
.LHCM_5c11:
	jr t, .LHCM_5c44                       ; [68 31] jr T,0x285c44
	lda_24 xhl, (0x22aa53)
	jr t, .LHCM_5c44                       ; [68 2a] jr T,0x285c44
	lds32	xhl, 1
	jr t, .LHCM_5c44                       ; [68 26] jr T,0x285c44
.LHCM_5c1e:
	lda_24 xwa, (0x22aa4c)
	calr	0xf71a
	ldw_da	bc, (0x23A092)
	ldw_da	de, (0x23A094)
	ldw_da	wa, (0x22AA4C)
	pushw wa                                ; push WA
	ld	xwa, 0x007f0102
	calr	0xdd8e
	lds32	xhl, 0
	jr t, .LHCM_5c44                       ; [68 02] jr T,0x285c44
.LHCM_5c42:
	lds32	xhl, 0
.LHCM_5c44:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jrl z, .LHCM_5cd4                      ; [76 80 00] jrl Z,0x285cd4
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jrl lt, .LHCM_5cf8                     ; [71 95 00] jrl LT,0x285cf8
	cp	xwa, 0x00000009
	jrl gt, .LHCM_5cf8                     ; [7a 8c 00] jrl GT,0x285cf8
	add	xwa, xwa
	add	xwa, 0x002e2a04
	ld	wa, (xwa)
	lda_24 xix, (0x285c80)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, 0x002e2922
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2a00
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_5cfa                       ; [68 55] jr T,0x285cfa
	lds32	xhl, 1
	jr t, .LHCM_5cfa                       ; [68 51] jr T,0x285cfa
	lds32	xhl, 1
	jr t, .LHCM_5cfa                       ; [68 4d] jr T,0x285cfa
	lds32	xhl, 2
	cpib_da	(0x22AA54), 0
	jr nz, .LHCM_5cb9                      ; [6e 02] jr NZ,0x285cb9
	lds32	xhl, 0
.LHCM_5cb9:
	jr t, .LHCM_5cfa                       ; [68 3f] jr T,0x285cfa
	lds32	xhl, 1
	cpib_da	(0x22AA54), 0
	jr nz, .LHCM_5cc7                      ; [6e 02] jr NZ,0x285cc7
	lds32	xhl, 0
.LHCM_5cc7:
	jr t, .LHCM_5cfa                       ; [68 31] jr T,0x285cfa
	lda_24 xhl, (0x22aa54)
	jr t, .LHCM_5cfa                       ; [68 2a] jr T,0x285cfa
	lds32	xhl, 1
	jr t, .LHCM_5cfa                       ; [68 26] jr T,0x285cfa
.LHCM_5cd4:
	lda_24 xwa, (0x22aa4c)
	calr	0xf664
	ldw_da	bc, (0x23A092)
	ldw_da	de, (0x23A094)
	ldw_da	wa, (0x22AA4C)
	pushw wa                                ; push WA
	ld	xwa, 0x007f0102
	calr	0xdcd8
	lds32	xhl, 0
	jr t, .LHCM_5cfa                       ; [68 02] jr T,0x285cfa
.LHCM_5cf8:
	lds32	xhl, 0
.LHCM_5cfa:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jrl z, .LHCM_5d8a                      ; [76 80 00] jrl Z,0x285d8a
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jrl lt, .LHCM_5dae                     ; [71 95 00] jrl LT,0x285dae
	cp	xwa, 0x00000009
	jrl gt, .LHCM_5dae                     ; [7a 8c 00] jrl GT,0x285dae
	add	xwa, xwa
	add	xwa, 0x002e2a1c
	ld	wa, (xwa)
	lda_24 xix, (0x285d36)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, 0x002e2922
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2a18
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_5db0                       ; [68 55] jr T,0x285db0
	lds32	xhl, 1
	jr t, .LHCM_5db0                       ; [68 51] jr T,0x285db0
	lds32	xhl, 1
	jr t, .LHCM_5db0                       ; [68 4d] jr T,0x285db0
	lds32	xhl, 2
	cpib_da	(0x22AA55), 0
	jr nz, .LHCM_5d6f                      ; [6e 02] jr NZ,0x285d6f
	lds32	xhl, 0
.LHCM_5d6f:
	jr t, .LHCM_5db0                       ; [68 3f] jr T,0x285db0
	lds32	xhl, 1
	cpib_da	(0x22AA55), 0
	jr nz, .LHCM_5d7d                      ; [6e 02] jr NZ,0x285d7d
	lds32	xhl, 0
.LHCM_5d7d:
	jr t, .LHCM_5db0                       ; [68 31] jr T,0x285db0
	lda_24 xhl, (0x22aa55)
	jr t, .LHCM_5db0                       ; [68 2a] jr T,0x285db0
	lds32	xhl, 1
	jr t, .LHCM_5db0                       ; [68 26] jr T,0x285db0
.LHCM_5d8a:
	lda_24 xwa, (0x22aa4c)
	calr	0xf5ae
	ldw_da	bc, (0x23A092)
	ldw_da	de, (0x23A094)
	ldw_da	wa, (0x22AA4C)
	pushw wa                                ; push WA
	ld	xwa, 0x007f0102
	calr	0xdc22
	lds32	xhl, 0
	jr t, .LHCM_5db0                       ; [68 02] jr T,0x285db0
.LHCM_5dae:
	lds32	xhl, 0
.LHCM_5db0:
	pop xiz                                 ; pop XIZ
	ret

	dec	4, xsp
	push xiz
	ld (xsp + 0x04), xwa                    ; ld (XSP+0x04),XWA
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jrl z, .LHCM_5e6d                      ; [76 aa 00] jrl Z,0x285e6d
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jrl lt, .LHCM_5e91                     ; [71 bf 00] jrl LT,0x285e91
	cp	xwa, 0x00000009
	jrl gt, .LHCM_5e91                     ; [7a b6 00] jrl GT,0x285e91
	add	xwa, xwa
	add	xwa, 0x002e2a34
	ld	wa, (xwa)
	lda_24 xix, (0x285def)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	ld	xiz, xde
	ld xwa, (xiz + 0x0e)                    ; ld XWA,(XIZ+0x0e)
	sll	xwa, 0x02
	ld	xbc, 0x002e2922
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2a30
	ld xwa, (xiz + 0x12)                    ; ld XWA,(XIZ+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	ld xwa, (xiz + 0x0e)                    ; ld XWA,(XIZ+0x0e)
	ld	(0x23a0a6), xwa
	ld xhl, (xsp + 0x04)                    ; ld XHL,(XSP+0x04)
	jr t, .LHCM_5e93                       ; [68 74] jr T,0x285e93
	lds32	xhl, 1
	jr t, .LHCM_5e93                       ; [68 70] jr T,0x285e93
	lds32	xhl, 1
	jr t, .LHCM_5e93                       ; [68 6c] jr T,0x285e93
	lds32	xhl, 2
	cpib_da	(0x22AA56), 0
	jr nz, .LHCM_5e33                      ; [6e 02] jr NZ,0x285e33
	lds32	xhl, 0
.LHCM_5e33:
	jr t, .LHCM_5e93                       ; [68 5e] jr T,0x285e93
	ld	xwa, (0x23a0a6)
	cp	xwa, 0x00000001
	jr nz, .LHCM_5e4d                      ; [6e 0b] jr NZ,0x285e4d
	lds32	xwa, 2
	ld	(0x23a0a6), xwa
	lds32	xhl, 2
	jr t, .LHCM_5e56                       ; [68 09] jr T,0x285e56
.LHCM_5e4d:
	lds32	xwa, 1
	ld	(0x23a0a6), xwa
	lds32	xhl, 1
.LHCM_5e56:
	cpib_da	(0x22AA56), 0
	jr nz, .LHCM_5e60                      ; [6e 02] jr NZ,0x285e60
	lds32	xhl, 0
.LHCM_5e60:
	jr t, .LHCM_5e93                       ; [68 31] jr T,0x285e93
	lda_24 xhl, (0x22aa56)
	jr t, .LHCM_5e93                       ; [68 2a] jr T,0x285e93
	lds32	xhl, 1
	jr t, .LHCM_5e93                       ; [68 26] jr T,0x285e93
.LHCM_5e6d:
	lda_24 xwa, (0x22aa4c)
	calr	0xf4cb
	ldw_da	bc, (0x23A092)
	ldw_da	de, (0x23A094)
	ldw_da	wa, (0x22AA4C)
	pushw wa                                ; push WA
	ld	xwa, 0x007f0102
	calr	0xdb3f
	lds32	xhl, 0
	jr t, .LHCM_5e93                       ; [68 02] jr T,0x285e93
.LHCM_5e91:
	lds32	xhl, 0
.LHCM_5e93:
	pop xiz                                 ; pop XIZ
	inc 4, xsp                              ; inc 4,XSP
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jr z, .LHCM_5f0a                       ; [66 66] jr Z,0x285f0a
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jr lt, .LHCM_5f18                      ; [61 66] jr LT,0x285f18
	cp	xwa, 0x00000009
	jr gt, .LHCM_5f18                      ; [6a 5e] jr GT,0x285f18
	add	xwa, xwa
	add	xwa, 0x002e2a4c
	ld	wa, (xwa)
	lda_24 xix, (0x285ece)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, 0x002e1e3c
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2a48
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_5f1a                       ; [68 27] jr T,0x285f1a
	lds32	xhl, 1
	jr t, .LHCM_5f1a                       ; [68 23] jr T,0x285f1a
	lds32	xhl, 1
	jr t, .LHCM_5f1a                       ; [68 1f] jr T,0x285f1a
	lds32	xhl, 0
	jr t, .LHCM_5f1a                       ; [68 1b] jr T,0x285f1a
	lda_24 xhl, (0x229d99)
	jr t, .LHCM_5f1a                       ; [68 14] jr T,0x285f1a
	lds32	xhl, 1
	jr t, .LHCM_5f1a                       ; [68 10] jr T,0x285f1a
.LHCM_5f0a:
	ldb_da	a, (0x229D99)
	extz wa                                 ; extz WA
	calr	0x5344
	lds32	xhl, 0
	jr t, .LHCM_5f1a                       ; [68 02] jr T,0x285f1a
.LHCM_5f18:
	lds32	xhl, 0
.LHCM_5f1a:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jr z, .LHCM_5f83                       ; [66 5a] jr Z,0x285f83
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jr lt, .LHCM_5f87                      ; [61 50] jr LT,0x285f87
	cp	xwa, 0x00000009
	jr gt, .LHCM_5f87                      ; [6a 48] jr GT,0x285f87
	add	xwa, xwa
	add	xwa, 0x002e2a64
	ld	wa, (xwa)
	lda_24 xix, (0x285f53)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	push xwa
	pushw 0x002e
	pushw 0x2a60
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_5f89                       ; [68 1d] jr T,0x285f89
	lds32	xhl, 1
	jr t, .LHCM_5f89                       ; [68 19] jr T,0x285f89
	lds32	xhl, 2
	jr t, .LHCM_5f89                       ; [68 15] jr T,0x285f89
	lds32	xhl, 1
	jr t, .LHCM_5f89                       ; [68 11] jr T,0x285f89
	lda_24 xhl, (0x229dac)
	jr t, .LHCM_5f89                       ; [68 0a] jr T,0x285f89
	lds32	xhl, 1
	jr t, .LHCM_5f89                       ; [68 06] jr T,0x285f89
.LHCM_5f83:
	lds32	xhl, 0
	jr t, .LHCM_5f89                       ; [68 02] jr T,0x285f89
.LHCM_5f87:
	lds32	xhl, 0
.LHCM_5f89:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	cp	xbc, 0x01c00007
	jr z, .LHCM_5fc3                       ; [66 2d] jr Z,0x285fc3
	cp	xbc, 0x01e00082
	jr z, .LHCM_5fbf                       ; [66 21] jr Z,0x285fbf
	cp	xbc, 0x01e00047
	jr nz, .LHCM_5fe2                      ; [6e 3c] jr NZ,0x285fe2
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	push xwa
	pushw 0x002e
	pushw 0x2a78
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_5fe4                       ; [68 25] jr T,0x285fe4
.LHCM_5fbf:
	lds32	xhl, 0
	jr t, .LHCM_5fe4                       ; [68 21] jr T,0x285fe4
.LHCM_5fc3:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xix, (xwa + 0x0100)
	ld	xwa, 0x02600024
	ld	xbc, 0x01e00029
	call	(xix)
	or xhl, xhl                             ; or XHL,XHL
	jr z, .LHCM_5fe2                       ; [66 00] jr Z,0x285fe2
.LHCM_5fe2:
	lds32	xhl, 0
.LHCM_5fe4:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jr z, .LHCM_605d                       ; [66 6a] jr Z,0x28605d
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jr lt, .LHCM_6061                      ; [61 60] jr LT,0x286061
	cp	xwa, 0x00000009
	jr gt, .LHCM_6061                      ; [6a 58] jr GT,0x286061
	add	xwa, xwa
	add	xwa, 0x002e2abc
	ld	wa, (xwa)
	lda_24 xix, (0x28601d)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, 0x002e2a7c
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2ab8
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_6063                       ; [68 21] jr T,0x286063
	lds32	xhl, 1
	jr t, .LHCM_6063                       ; [68 1d] jr T,0x286063
	lds32	xhl, 1
	jr t, .LHCM_6063                       ; [68 19] jr T,0x286063
	lds32	xhl, 4
	jr t, .LHCM_6063                       ; [68 15] jr T,0x286063
	lds32	xhl, 0
	jr t, .LHCM_6063                       ; [68 11] jr T,0x286063
	lda_24 xhl, (0x229dad)
	jr t, .LHCM_6063                       ; [68 0a] jr T,0x286063
	lds32	xhl, 1
	jr t, .LHCM_6063                       ; [68 06] jr T,0x286063
.LHCM_605d:
	lds32	xhl, 0
	jr t, .LHCM_6063                       ; [68 02] jr T,0x286063
.LHCM_6061:
	lds32	xhl, 0
.LHCM_6063:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jr z, .LHCM_60dc                       ; [66 6a] jr Z,0x2860dc
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jr lt, .LHCM_60e0                      ; [61 60] jr LT,0x2860e0
	cp	xwa, 0x00000009
	jr gt, .LHCM_60e0                      ; [6a 58] jr GT,0x2860e0
	add	xwa, xwa
	add	xwa, 0x002e2b10
	ld	wa, (xwa)
	lda_24 xix, (0x28609c)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, 0x002e2ad0
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2b0c
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_60e2                       ; [68 21] jr T,0x2860e2
	lds32	xhl, 1
	jr t, .LHCM_60e2                       ; [68 1d] jr T,0x2860e2
	lds32	xhl, 1
	jr t, .LHCM_60e2                       ; [68 19] jr T,0x2860e2
	lds32	xhl, 4
	jr t, .LHCM_60e2                       ; [68 15] jr T,0x2860e2
	lds32	xhl, 0
	jr t, .LHCM_60e2                       ; [68 11] jr T,0x2860e2
	lda_24 xhl, (0x229dae)
	jr t, .LHCM_60e2                       ; [68 0a] jr T,0x2860e2
	lds32	xhl, 1
	jr t, .LHCM_60e2                       ; [68 06] jr T,0x2860e2
.LHCM_60dc:
	lds32	xhl, 0
	jr t, .LHCM_60e2                       ; [68 02] jr T,0x2860e2
.LHCM_60e0:
	lds32	xhl, 0
.LHCM_60e2:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jr z, .LHCM_6157                       ; [66 66] jr Z,0x286157
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jr lt, .LHCM_615b                      ; [61 5c] jr LT,0x28615b
	cp	xwa, 0x00000009
	jr gt, .LHCM_615b                      ; [6a 54] jr GT,0x28615b
	add	xwa, xwa
	add	xwa, 0x002e2b28
	ld	wa, (xwa)
	lda_24 xix, (0x28611b)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	sll	xwa, 0x02
	ld	xbc, 0x002e1e3c
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	push xwa
	pushw 0x002e
	pushw 0x2b24
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_615d                       ; [68 1d] jr T,0x28615d
	lds32	xhl, 1
	jr t, .LHCM_615d                       ; [68 19] jr T,0x28615d
	lds32	xhl, 1
	jr t, .LHCM_615d                       ; [68 15] jr T,0x28615d
	lds32	xhl, 0
	jr t, .LHCM_615d                       ; [68 11] jr T,0x28615d
	lda_24 xhl, (0x229d9a)
	jr t, .LHCM_615d                       ; [68 0a] jr T,0x28615d
	lds32	xhl, 1
	jr t, .LHCM_615d                       ; [68 06] jr T,0x28615d
.LHCM_6157:
	lds32	xhl, 0
	jr t, .LHCM_615d                       ; [68 02] jr T,0x28615d
.LHCM_615b:
	lds32	xhl, 0
.LHCM_615d:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jr z, .LHCM_61c6                       ; [66 5a] jr Z,0x2861c6
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jr lt, .LHCM_61ca                      ; [61 50] jr LT,0x2861ca
	cp	xwa, 0x00000009
	jr gt, .LHCM_61ca                      ; [6a 48] jr GT,0x2861ca
	add	xwa, xwa
	add	xwa, 0x002e2b40
	ld	wa, (xwa)
	lda_24 xix, (0x286196)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	push xwa
	pushw 0x002e
	pushw 0x2b3c
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_61cc                       ; [68 1d] jr T,0x2861cc
	lds32	xhl, 1
	jr t, .LHCM_61cc                       ; [68 19] jr T,0x2861cc
	lds32	xhl, 3
	jr t, .LHCM_61cc                       ; [68 15] jr T,0x2861cc
	lds32	xhl, 1
	jr t, .LHCM_61cc                       ; [68 11] jr T,0x2861cc
	lda_24 xhl, (0x229da9)
	jr t, .LHCM_61cc                       ; [68 0a] jr T,0x2861cc
	lds32	xhl, 1
	jr t, .LHCM_61cc                       ; [68 06] jr T,0x2861cc
.LHCM_61c6:
	lds32	xhl, 0
	jr t, .LHCM_61cc                       ; [68 02] jr T,0x2861cc
.LHCM_61ca:
	lds32	xhl, 0
.LHCM_61cc:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jr z, .LHCM_6235                       ; [66 5a] jr Z,0x286235
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jr lt, .LHCM_6239                      ; [61 50] jr LT,0x286239
	cp	xwa, 0x00000009
	jr gt, .LHCM_6239                      ; [6a 48] jr GT,0x286239
	add	xwa, xwa
	add	xwa, 0x002e2b58
	ld	wa, (xwa)
	lda_24 xix, (0x286205)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	push xwa
	pushw 0x002e
	pushw 0x2b54
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_623b                       ; [68 1d] jr T,0x28623b
	lds32	xhl, 1
	jr t, .LHCM_623b                       ; [68 19] jr T,0x28623b
	lds32	xhl, 2
	jr t, .LHCM_623b                       ; [68 15] jr T,0x28623b
	lds32	xhl, 1
	jr t, .LHCM_623b                       ; [68 11] jr T,0x28623b
	lda_24 xhl, (0x229daa)
	jr t, .LHCM_623b                       ; [68 0a] jr T,0x28623b
	lds32	xhl, 1
	jr t, .LHCM_623b                       ; [68 06] jr T,0x28623b
.LHCM_6235:
	lds32	xhl, 0
	jr t, .LHCM_623b                       ; [68 02] jr T,0x28623b
.LHCM_6239:
	lds32	xhl, 0
.LHCM_623b:
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01e00082
	jr z, .LHCM_62a4                       ; [66 5a] jr Z,0x2862a4
	sub	xwa, 0x01e0003e
	cp	xwa, 0x00000000
	jr lt, .LHCM_62a8                      ; [61 50] jr LT,0x2862a8
	cp	xwa, 0x00000009
	jr gt, .LHCM_62a8                      ; [6a 48] jr GT,0x2862a8
	add	xwa, xwa
	add	xwa, 0x002e2b70
	ld	wa, (xwa)
	lda_24 xix, (0x286274)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	ld xwa, (xde + 0x0e)                    ; ld XWA,(XDE+0x0e)
	push xwa
	pushw 0x002e
	pushw 0x2b6c
	ld xwa, (xde + 0x12)                    ; ld XWA,(XDE+0x12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr t, .LHCM_62aa                       ; [68 1d] jr T,0x2862aa
	lds32	xhl, 1
	jr t, .LHCM_62aa                       ; [68 19] jr T,0x2862aa
	lds32	xhl, 2
	jr t, .LHCM_62aa                       ; [68 15] jr T,0x2862aa
	lds32	xhl, 1
	jr t, .LHCM_62aa                       ; [68 11] jr T,0x2862aa
	lda_24 xhl, (0x229dab)
	jr t, .LHCM_62aa                       ; [68 0a] jr T,0x2862aa
	lds32	xhl, 1
	jr t, .LHCM_62aa                       ; [68 06] jr T,0x2862aa
.LHCM_62a4:
	lds32	xhl, 0
	jr t, .LHCM_62aa                       ; [68 02] jr T,0x2862aa
.LHCM_62a8:
	lds32	xhl, 0
.LHCM_62aa:
	pop xiz                                 ; pop XIZ
	ret


HDAE5000_HD_Partition_Setup:	; 0x2862AC (818 bytes)
	; Set up HD partition parameters
	; Part 1: Display partition info — allocate stack frame, format strings
	lda	xsp, (xsp-108)
	pushw 0x0139
	lda_24 xwa, (0x2e2b84)
	push xwa
	lda_24 xwa, (0x22b2f6)
	push xwa
	call HDAE5000_MemCopy			; HDAE5000_MemCopy
	lda xsp, (xsp + 0x0a)
	lda xwa, (xsp + 0x38)
	call 0x297573
	pushw 0x0010
	lda xwa, (xsp + 0x44)
	push xwa
	lda_24 xwa, (0x22b30c)
	push xwa
	call HDAE5000_MemCopy
	pushw 0x000a		; push 0x000A
	lda xwa, (xsp + 0x24)
	push xwa
	ld wa, (xsp + 0x48)
	pushw wa                                ; push wa (compact)
	call 0x29ac3b
	lda xwa, (xsp + 0x2a)
	push xwa
	call HDAE5000_Display_Buffer_Validate			; HDAE5000_Display_Buffer_Validate
	pushw hl                                ; push hl (compact)
	lda xwa, (xsp + 0x30)
	push xwa
	lda_24 xwa, (0x22b333)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x20)
	pushw 0x000a		; push 0x000A
	lda xwa, (xsp + 0x1a)
	push xwa
	ld wa, (xsp + 0x40)
	pushw wa                                ; push wa
	call 0x29ac3b
	lda xwa, (xsp + 0x20)
	push xwa
	call HDAE5000_Display_Buffer_Validate
	pushw hl                                ; push hl
	lda xwa, (xsp + 0x26)
	push xwa
	lda_24 xwa, (0x22b35a)
	push xwa
	call HDAE5000_MemCopy
	pushw 0x000a		; push 0x000A
	lda xwa, (xsp + 0x30)
	push xwa
	ld wa, (xsp + 0x58)
	pushw wa                                ; push wa
	call 0x29ac3b
	lda xsp, (xsp + 0x1e)
	lda xwa, (xsp + 0x18)
	push xwa
	call HDAE5000_Display_Buffer_Validate
	pushw hl                                ; push hl
	lda xwa, (xsp + 0x1e)
	push xwa
	lda_24 xwa, (0x22b381)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0e)
	lda xwa, (xsp + 0x28)
	call 0x298b6c
	pushw 0x0010
	pushw 0x0000
	lda xwa, (xsp + 0x1c)
	push xwa
	call HDAE5000_MemFill			; HDAE5000_MemFill
	lda xbc, (xsp + 0x30)
	lda xwa, (xsp + 0x14)
	call 0x29b815
	lda xbc, (xsp + 0x14)
	lda_24 xde, (0x2e2cd0)
	lda xwa, (xsp + 0x14)
	call 0x29b840
	lda xbc, (xsp + 0x14)
	lda xwa, (xsp + 0x18)
	call 0x29ba20
	lda xiy, (xsp + 0x18)
	ld xix, (xiy + 0x04)
	push xix
	ld xix, (xiy)
	push xix
	pushw 0x002e		; push 0x002E
	pushw 0x2cbe		; push 0x2CBE
	lda xwa, (xsp + 0x2c)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda xwa, (xsp + 0x30)
	push xwa
	call HDAE5000_Display_Buffer_Validate
	lda xsp, (xsp + 0x1c)
	pushw hl                                ; push hl
	lda xwa, (xsp + 0x1a)
	push xwa
	lda_24 xwa, (0x22b3a8)
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
	call 0x29b815
	lda xbc, (xsp + 0x0c)
	lda_24 xde, (0x2e2cd4)
	lda xwa, (xsp + 0x0c)
	call 0x29b840
	lda xbc, (xsp + 0x0c)
	lda xwa, (xsp + 0x10)
	call 0x29ba20
	lda xiy, (xsp + 0x10)
	ld xix, (xiy + 0x04)
	push xix
	ld xix, (xiy)
	push xix
	pushw 0x002e		; push 0x002E
	pushw 0x2cc4		; push 0x2CC4
	lda xwa, (xsp + 0x24)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda xwa, (xsp + 0x28)
	push xwa
	call HDAE5000_Display_Buffer_Validate
	pushw hl                                ; push hl
	lda xwa, (xsp + 0x2e)
	push xwa
	lda_24 xwa, (0x22b3cf)
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
	call 0x29b815
	lda xbc, (xsp + 0x14)
	lda_24 xde, (0x2e2cd8)
	lda xwa, (xsp + 0x14)
	call 0x29b840
	lda xbc, (xsp + 0x14)
	lda xwa, (xsp + 0x18)
	call 0x29ba20
	lda xiy, (xsp + 0x18)
	ld xix, (xiy + 0x04)
	push xix
	ld xix, (xiy)
	push xix
	pushw 0x002e		; push 0x002E
	pushw 0x2cca		; push 0x2CCA
	lda xwa, (xsp + 0x2c)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda xwa, (xsp + 0x30)
	push xwa
	call HDAE5000_Display_Buffer_Validate
	lda xsp, (xsp + 0x1c)
	pushw hl                                ; push hl
	lda xwa, (xsp + 0x1a)
	push xwa
	lda_24 xwa, (0x22b3f6)
	push xwa
	call HDAE5000_MemCopy
	pushw 0x0010
	pushw 0x0000
	lda xwa, (xsp + 0x26)
	push xwa
	call HDAE5000_MemFill
	lda xsp, (xsp + 0x12)
	lda xwa, (xsp + 0x18)
	calr HDAE5000_Display_Clear
	lda xwa, (xsp + 0x18)
	push xwa
	call HDAE5000_Display_Buffer_Validate
	pushw hl                                ; push hl
	lda xwa, (xsp + 0x1e)
	push xwa
	lda_24 xwa, (0x22b41d)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0e)
	; Register partition display handler
	lda_24 xwa, (0x22b2f6)
	ld xde, xwa
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)             ; ld XHL, (XWA + 0x0124)
	ld xwa, 0x007f022a
	ld xbc, 0x01ea000a
	call (xhl)
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)
	ld xwa, 0x007f022a
	ld xbc, 0x01c0000f
	ld xde, 0xffffffff
	call (xhl)
	lda xsp, (xsp + 0x6c)		; deallocate stack frame
	ret
	;
	; Part 2: Event handler (0x286502)
.LHD_PS__handler:
	cp xbc, 0x01c00007
	jrl nz, .LHD_PS__exit
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xix, (xwa + 0x0100)             ; ld XIX, (XWA + 0x0100)
	ld xwa, 0x02600024
	ld xbc, 0x01e00029
	call (xix)
	; Check return value
	cp xhl, 0x0000000c
	jrl z, .LHD_PS__case_0c
	cp xhl, 0x00000009
	jr z, .LHD_PS__case_09
	cp xhl, 0x0000008c
	jrl nz, .LHD_PS__exit
	; Case 0x8C: update display with error code
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)
	ld xwa, 0x007f02c1
	ld xbc, 0x01c00001
	lds32 xde, 5
	call (xhl)
	lds wa, 0
	call 0x293f3c
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)
	ld xwa, 0x007f0013
	ld xbc, 0x01c00001
	lds32 xde, 0
	call (xhl)
	jr t, .LHD_PS__exit
.LHD_PS__case_09:			; case 0x09: format and validate
	pushw 0x000a		; push 0x000A
	pushw 0x0000
	lda_24 xwa, (0x22ad9c)
	push xwa
	call HDAE5000_MemFill
	inc 0, xsp			; deallocate 8 bytes
	cpib_da (0x229d99), 0x00
	jr nz, .LHD_PS__exit
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)
	ld xwa, 0x007f021a
	ld xbc, 0x01c00001
	lds32 xde, 0
	call (xhl)
	jr t, .LHD_PS__exit
.LHD_PS__case_0c:			; case 0x0C: recursive re-setup
	calr HDAE5000_HD_Partition_Setup
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)
	ld xwa, 0x007f0227
	ld xbc, 0x01c00001
	lds32 xde, 0
	call (xhl)
.LHD_PS__exit:
	lds32 xhl, 0
	ret

HDAE5000_HD_CHS_Calculate:	; 0x2865DE (1098 bytes)
	; Part 1: CHS digit accumulator — stores digit, checks for 6-digit match
	dec 0, xsp			; alloc 4 bytes
	pushw iz                                ; push iz (compact)
	pushw 0x000a
	lda xbc, (xsp + 0x04)
	push xbc
	pushw wa                                ; push wa (compact)
	call 0x29ac3b
	inc 0, xsp			; dealloc 4 bytes
	ldb_da xwa, (0x22ad9c); A = current count
	extz wa
	ld bc, wa
	inc 2, bc			; BC = count + 2
	lda_24 xde, (0x22ad9c); XDE = buffer base
	ld a, (xsp + 0x02)		; A = digit param
	lda_dri xbc, 0x07, 0xE8, 0xE4	; ld (XDE+BC), A
	incdi8_24	1, (0x22AD9C)
	cpib_da (0x22ad9c), 0x06; count == 6?
	jr nz, .LCHSC__not_full
	; 6 digits entered — match against patterns
	pushw 0x002e
	pushw 0x1e2c
	lda_24 xwa, (0x22ad9e)
	push xwa
	call HDAE5000_Code_Remainder			; string compare
	inc 0, xsp
	cps hl, 0
	jr nz, .LCHSC__try2
	lds iz, 2			; match pattern 1 → IZ=2
	jr t, .LCHSC__clear
.LCHSC__try2:
	pushw 0x002e
	pushw 0x1e34
	lda_24 xwa, (0x22ad9e)
	push xwa
	call HDAE5000_Code_Remainder			; string compare
	inc 0, xsp
	cps hl, 0
	jr nz, .LCHSC__no_match
	lds iz, 3			; match pattern 2 → IZ=3
	jr t, .LCHSC__clear
.LCHSC__no_match:
	lds iz, 1			; no match → IZ=1
.LCHSC__clear:
	pushw 0x000a
	pushw 0x0000
	lda_24 xwa, (0x22ad9c)
	push xwa
	call HDAE5000_MemFill			; MemFill (clear buffer)
	inc 0, xsp
	jr t, .LCHSC__return
.LCHSC__not_full:
	lds iz, 0			; not full → IZ=0
.LCHSC__return:
	ld hl, iz			; return value in HL
	popw iz                                 ; pop iz (compact)
	inc 0, xsp			; dealloc 4 bytes
	ret
	;
	; Part 2: Event handler (0x286666)
.LCHSC__handler:
	dec 6, xsp			; alloc 24 bytes
	push xiz
	ld xiz, xde			; XIZ = param
	ld (xsp + 0x06), xwa		; save event code
	ld xwa, xbc			; XWA = event code
	cp xwa, 0x01ca0002
	jrl z, .LCHSC__ev_close
	cp xwa, 0x01c00007
	jr z, .LCHSC__ev_key
	cp xwa, 0x01c0000d
	jr z, .LCHSC__ev_0d
	cp xwa, 0x01e00085
	jr z, .LCHSC__ev_85
	; Default: pass through to registered handler
	ld xwa, (xsp + 0x06)
	ld xde, xiz
	ldl_da xhl, (0x23a1a2)
	ld_sril xhl, (xhl + 0x0e0a)             ; XHL = (XHL + 0x0E0A)
	ld_sril xix, (xhl + 0x00dc)             ; XIX = (XHL + 0x00DC)
	call (xix)
	jrl t, .LCHSC__exit
.LCHSC__ev_85:				; Event 0x01E00085
	lds32 xhl, 1
	jrl t, .LCHSC__exit
.LCHSC__ev_0d:				; Event 0x01C0000D
	ld xwa, (xsp + 0x06)
	ld xde, xiz
	ldl_da xhl, (0x23a1a2)
	ld_sril xhl, (xhl + 0x0e0a)
	ld_sril xhl, (xhl + 0x00dc)             ; XHL = (XHL + 0x00DC)
	call (xhl)
	lda_24 xwa, (0x2e2cdc)
	ld xbc, xwa
	ld xwa, (xsp + 0x06)
	ld xde, xbc
	ldl_da xbc, (0x23a1a2)
	ld_sril xbc, (xbc + 0x0e0a)             ; XBC = (XBC + 0x0E0A)
	ld_sril xhl, (xbc + 0x0100)             ; XHL = (XBC + 0x0100)
	ld xbc, 0x01c0000f
	call (xhl)
	lds32 xhl, 0
	jrl t, .LCHSC__exit
.LCHSC__ev_key:				; Event 0x01C00007
	ldw	(xsp+4), 0x0000
	ld xde, xiz
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)             ; XWA = (XWA + 0x0E0A)
	ld_sril xix, (xwa + 0x0100)             ; XIX = (XWA + 0x0100)
	ld xwa, 0x02600024
	ld xbc, 0x01e00029
	call (xix)
	ld xwa, xhl
	cp xwa, 0x00000007
	jrl ugt, .LCHSC__post_switch		; > 7 → skip
	add xwa, xwa				; XWA * 2
	add xwa, 0x002e2ce2			; jump table base
	ld wa, (xwa)				; WA = offset
	lda_24 xix, (0x28672d); dispatch base
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp (XIX + WA)
	; Case 0: bit test → call with 0/1
	bit 0x07, iz
	jr z, .LCHSC__c0_even
	lds wa, 0
	jr t, .LCHSC__c0_call
.LCHSC__c0_even:
	lds wa, 1
.LCHSC__c0_call:
	calr HDAE5000_HD_CHS_Calculate		; recursive
	ld (xsp + 0x04), hl
	jr t, .LCHSC__post_switch
	; Case 1: bit test → call with 2/3
	bit 0x07, iz
	jr z, .LCHSC__c1_even
	lds wa, 2
	jr t, .LCHSC__c1_call
.LCHSC__c1_even:
	lds wa, 3
.LCHSC__c1_call:
	calr HDAE5000_HD_CHS_Calculate
	ld (xsp + 0x04), hl
	jr t, .LCHSC__post_switch
	; Case 2: bit test → call with 4/5
	bit 0x07, iz
	jr z, .LCHSC__c2_even
	lds wa, 4
	jr t, .LCHSC__c2_call
.LCHSC__c2_even:
	lds wa, 5
.LCHSC__c2_call:
	calr HDAE5000_HD_CHS_Calculate
	ld (xsp + 0x04), hl
	jr t, .LCHSC__post_switch
	; Case 3: bit test → call with 6/7
	bit 0x07, iz
	jr z, .LCHSC__c3_even
	lds wa, 6
	jr t, .LCHSC__c3_call
.LCHSC__c3_even:
	lds wa, 7
.LCHSC__c3_call:
	calr HDAE5000_HD_CHS_Calculate
	ld (xsp + 0x04), hl
	jr t, .LCHSC__post_switch
	; Case 4: bit test → call with 8/9 (ldw for values > 7)
	bit 0x07, iz
	jr z, .LCHSC__c4_even
	ldw wa, 0x0008
	jr t, .LCHSC__c4_call
.LCHSC__c4_even:
	ldw wa, 0x0009
.LCHSC__c4_call:
	calr HDAE5000_HD_CHS_Calculate
	ld (xsp + 0x04), hl
	jr t, .LCHSC__post_switch
	; Case 6/7: clear buffer + display setup
	pushw 0x000a
	pushw 0x0000
	lda_24 xwa, (0x22ad9c)
	push xwa
	call HDAE5000_MemFill			; MemFill
	inc 0, xsp
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0104)             ; XHL = (XWA + 0x0104)
	ld xwa, 0x007f0013
	ld xbc, 0x01c00001
	lds32 xde, 0
	call (xhl)
	; Post-switch: dispatch on result
.LCHSC__post_switch:
	ld wa, (xsp + 0x04)
	cps wa, 3
	jrl z, .LCHSC__res3
	cps wa, 2
	jr z, .LCHSC__res2
	cps wa, 1
	jrl nz, .LCHSC__done
	; Result 1: setup with 0x007f02cb + two dialog boxes
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0100)             ; XHL = (XWA + 0x0100)
	ld xwa, 0x007f02cb
	ld xbc, 0x01c00001
	lds32 xde, 3
	call (xhl)
	ld xwa, 0x01ca0002
	push xwa
	ld xwa, 0x007f021a
	push xwa
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0418)             ; XHL = (XWA + 0x0418)
	ld xwa, 0x0000014d
	ld xbc, 0x007f02cd
	ld xde, 0xffffffff
	call (xhl)
	ld xwa, 0x01ca0002
	push xwa
	ld xwa, 0x007f021a
	push xwa
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0410)             ; XHL = (XWA + 0x0410)
	ld xwa, 0x0000014d
	ld xbc, 0x007f02cd
	ld xde, 0xffffffff
	call (xhl)
	jrl t, .LCHSC__done
.LCHSC__res2:				; Result 2: display setup + validate + FS init
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0100)
	ld xwa, 0x007f0223
	ld xbc, 0x01c00001
	lds32 xde, 0
	call (xhl)
	calr HDAE5000_Wait_Callback_Loop
	lds wa, 1
	call HDAE5000_Display_Init
	cps hl, 0
	jr nz, .LCHSC__res2_err
	; Success: display + FS read
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0104)
	ld xwa, 0x007f0013
	ld xbc, 0x01c00001
	lds32 xde, 0
	call (xhl)
	ld xwa, 0x007f0025
	calr HDAE5000_HD_Format_Params
	lds wa, 0
	lds bc, 0
	calr HDAE5000_HD_Read_Write
	calr HDAE5000_FS_Read_FSB
	lds wa, 0
	lds bc, 2
	calr HDAE5000_FS_Write_FSB
	jrl t, .LCHSC__done
.LCHSC__res2_err:			; Error: display error + two dialog boxes
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0104)
	ld xwa, 0x007f02c4
	ld xbc, 0x01c00001
	lds32 xde, 3
	call (xhl)
	ld xwa, 0x01ca0002
	push xwa
	ld xwa, 0x007f021a
	push xwa
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0418)
	ld xwa, 0x0000014d
	ld xbc, 0x007f02c6
	ld xde, 0xffffffff
	call (xhl)
	ld xwa, 0x01ca0002
	push xwa
	ld xwa, 0x007f021a
	push xwa
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0410)
	ld xwa, 0x0000014d
	ld xbc, 0x007f02c6
	ld xde, 0xffffffff
	call (xhl)
	jrl t, .LCHSC__done
.LCHSC__res3:				; Result 3: set flags + validate + check match
	stib_da (0x229da9), 0x01
	stib_da (0x229daa), 0x01
	stib_da (0x229dab), 0x01
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0100)
	ld xwa, 0x007f0294
	ld xbc, 0x01c00001
	lds32 xde, 0
	call (xhl)
	calr HDAE5000_Wait_Callback_Loop
	lds wa, 0
	call 0x293f3c
	cp hl, 0xffff
	jr z, .LCHSC__res3_nomatch
	; Match found
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0104)
	ld xwa, 0x007f0013
	ld xbc, 0x01c00001
	lds32 xde, 0
	call (xhl)
	jrl t, .LCHSC__done
.LCHSC__res3_nomatch:			; No match — setup error display + dialog boxes
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0104)
	ld xwa, 0x007f0297
	ld xbc, 0x01c00001
	lds32 xde, 3
	call (xhl)
	ld xwa, 0x007f0298
	ld xbc, 0x007f021a
	calr HDAE5000_UI_Main_Handler
	ld xwa, 0x01ca0002
	push xwa
	ld xwa, 0x007f021a
	push xwa
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0418)
	ld xwa, 0x0000014d
	ld xbc, 0x007f0299
	ld xde, 0xffffffff
	call (xhl)
	ld xwa, 0x01ca0002
	push xwa
	ld xwa, 0x007f021a
	push xwa
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0410)
	ld xwa, 0x0000014d
	ld xbc, 0x007f0299
	ld xde, 0xffffffff
	call (xhl)
.LCHSC__done:				; Common exit
	lds32 xhl, 0
	jr t, .LCHSC__exit
.LCHSC__ev_close:			; Event 0x01CA0002: close display
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0104)
	ld xwa, 0x007f021a
	ld xbc, 0x01c00001
	lds32 xde, 0
	call (xhl)
	lds32 xhl, 0
.LCHSC__exit:
	pop xiz
	inc 6, xsp			; dealloc 24 bytes
	ret

HDAE5000_HD_Sector_Read:	; 0x286A28 (1064 bytes)
	; Read sectors from HD; accesses 0x229DAC
	; Part 1: CHS input state machine with jump table dispatch
	pushw iz                                ; push iz (compact)
	ld hl, (xsp + 0x06)		; HL = param from stack
	ld de, wa			; DE = input digit
	ldw_da xwa, (0x22aa5c); load current state
	cps wa, 5			; state >= 6? (unsigned)
	jrl ugt, .LHD_SR__apply	; yes → apply values
	add wa, wa			; state * 2
	lda_24 xix, (0x2e2cf2); jump table base
	ldw_sri wa, 0x07, 0xF0, 0xE0	; ld WA, (XIX + WA)
	lda_24 xix, (0x286a4e); dispatch base
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp (XIX + WA)
	; Case 0 (offset 0x0000): jump to FS_Init directly
	jrl t, .LHD_SR__cleanup
	; Case 1 (offset 0x0003): cylinder digit * 100
	ld wa, hl
	muls wa, 0x0064			; WA = digit * 100
	add de, wa			; DE += WA
	cp de, 0x0064			; DE >= 100?
	jr lt, .LHD_SR__c1_lo
	ldw de, 0x0064			; clamp to 100
	jr t, .LHD_SR__apply
.LHD_SR__c1_lo:
	cps de, 0			; DE > 0?
	jr gt, .LHD_SR__apply
	lds de, 0			; clamp to 0
	jr t, .LHD_SR__apply
	; Case 2 (offset 0x001E): cylinder digit * 10
	ld wa, hl
	muls wa, 0x000a			; WA = digit * 10
	add de, wa
	cp de, 0x0078			; DE >= 120?
	jr lt, .LHD_SR__c2_lo
	ldw de, 0x0078			; clamp to 120
	jr t, .LHD_SR__apply
.LHD_SR__c2_lo:
	cps de, 1			; DE > 1?
	jr gt, .LHD_SR__apply
	lds de, 0
	jr t, .LHD_SR__apply
	; Case 3 (offset 0x0039): cylinder unit digit
	add de, hl
	cp de, 0x0078
	jr le, .LHD_SR__c3_lo
	ldw de, 0x0078
	jr t, .LHD_SR__apply
.LHD_SR__c3_lo:
	cps de, 0
	jr gt, .LHD_SR__apply
	lds de, 1
	jr t, .LHD_SR__apply
	; Case 4 (offset 0x004E): head digit * 10
	ld wa, hl
	muls wa, 0x000a
	add bc, wa
	cp bc, 0x000a			; BC >= 10?
	jr lt, .LHD_SR__c4_lo
	ldw bc, 0x000a
	jr t, .LHD_SR__apply
.LHD_SR__c4_lo:
	cps bc, 0
	jr gt, .LHD_SR__apply
	lds bc, 0
	jr t, .LHD_SR__apply
	; Case 5 (offset 0x0069): head unit digit
	add bc, hl
	cp bc, 0x0010			; BC >= 16?
	jr le, .LHD_SR__c5_lo
	ldw bc, 0x0010
	jr t, .LHD_SR__apply
.LHD_SR__c5_lo:
	cps bc, 0
	jr gt, .LHD_SR__apply
	lds bc, 1
.LHD_SR__apply:				; store results
	stw_da (0x22aa5e), xde; store cylinder
	stw_da (0x22aa60), xbc; store head
	cpw_da (0x22aa5c), 0x0005; state == 5?
	jr nz, .LHD_SR__fs_init
	; State 5: complete — do table lookup and seek
	ldw_da xwa, (0x22aa5e)
	dec 1, wa
	stw_da (0x23a092), xwa
	ldw_da xwa, (0x22aa60)
	dec 1, wa
	stw_da (0x23a094), xwa
	ldw_da xwa, (0x23a092)
	ldw_da xbc, (0x23a094)
	call HDAE5000_Table_Lookup
	ld iz, hl
	ld wa, iz
	cp wa, 0xffff
	jr z, .LHD_SR__no_match
	; Match found — copy data and seek
	lda_24 xwa, (0x22aa4c)
	ld bc, iz
	pushw 0x0002
	lda_24 xde, (0x2e1c96)
	calr HDAE5000_HD_Data_Copy
	ldw_da xbc, (0x23a092)
	ldw_da xde, (0x23a094)
	ld wa, iz
	pushw wa                                ; push wa (compact)
	ld xwa, 0x007f0098
	calr HDAE5000_HD_Seek
	jr t, .LHD_SR__fs_init
.LHD_SR__no_match:			; No match — clear and seek with 0xFFFF
	lda_24 xwa, (0x22aa4c)
	pushw 0x0002
	lda_24 xde, (0x2e1c96)
	lds bc, 0
	calr HDAE5000_HD_Data_Copy
	pushw 0xffff		; push 0xFFFF
	ld xwa, 0x007f0098
	ldw bc, 0xffff
	ldw de, 0xffff
	calr HDAE5000_HD_Seek
.LHD_SR__fs_init:			; Re-init filesystem display
	pushw 0x0001
	ldw_da xwa, (0x22aa5e)
	ldw_da xbc, (0x22aa60)
	ldw_da xde, (0x22aa5c)
	calr HDAE5000_FS_Init
.LHD_SR__cleanup:
	popw iz                                 ; pop iz (compact)
	retd 0x0002			; return, dealloc 2 bytes
	;
	; Part 2: Event handler A (0x286B72)
.LHD_SR__handlerA:
	dec 0, xsp			; alloc 8 bytes
	push xiz
	ld (xsp + 0x04), xde
	ld (xsp + 0x08), xbc
	ld xiz, xwa
	ld xwa, (xsp + 0x08)		; XWA = event code
	cp xwa, 0x01c00007
	jr z, .LHD_SR__a_evt07
	cp xwa, 0x01c0000d
	jr z, .LHD_SR__a_evt0d
	cp xwa, 0x01e00085
	jrl nz, .LHD_SR__a_exit
	lds32 xhl, 1			; event 0x85: XHL = 1
	jrl t, .LHD_SR__a_epilogue
.LHD_SR__a_evt0d:			; event 0x0D: display update
	ld xwa, xiz
	ld xbc, (xsp + 0x08)
	ld xde, (xsp + 0x04)
	ldl_da xhl, (0x23a1a2)
	ld_sril xhl, (xhl + 0x0e0a)
	ld_sril xhl, (xhl + 0x00dc)
	call (xhl)
	lda_24 xwa, (0x2e2cfe)
	ld xbc, xwa
	ld xwa, xiz
	ld xde, xbc
	ldl_da xbc, (0x23a1a2)
	ld_sril xbc, (xbc + 0x0e0a)
	ld_sril xhl, (xbc + 0x0100)
	ld xbc, 0x01c0000f
	call (xhl)
	lds32 xhl, 0
	jrl t, .LHD_SR__a_epilogue
.LHD_SR__a_evt07:			; event 0x07: jump table dispatch
	ld xde, (xsp + 0x04)
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xix, (xwa + 0x0100)
	ld xwa, 0x02600024
	ld xbc, 0x01e00029
	call (xix)
	ld xwa, xhl
	cp xwa, 0x0000000c		; case > 12?
	jrl ugt, .LHD_SR__a_exit
	add xwa, xwa			; index * 2
	add xwa, 0x002e2d04
	ld wa, (xwa)
	lda_24 xix, (0x286c1a); dispatch base
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp (XIX + WA)
	; Case 0: re-init FS
	pushw 0x0001
	lds wa, 0
	lds bc, 0
	lds de, 6
	calr HDAE5000_FS_Init
	jrl t, .LHD_SR__a_exit
	; Case 1: toggle read/write direction
	ld xwa, (xsp + 0x04)
	bit 0x07, wa			; bit 7?
	jr nz, .LHD_SR__a_c1_set
	lds wa, 1
	jr t, .LHD_SR__a_c1_push
.LHD_SR__a_c1_set:
	ldw wa, 0xffff
.LHD_SR__a_c1_push:
	pushw wa                                ; push wa
	ldw_da xwa, (0x22aa5e)
	ldw_da xbc, (0x22aa60)
	ldw_da xde, (0x22aa5c)
	calr HDAE5000_HD_Sector_Read	; recursive call
	jrl t, .LHD_SR__a_exit
	; Case 2: sector write (BC=0 or 1)
	ld xwa, (xsp + 0x04)
	bit 0x07, wa
	jr z, .LHD_SR__a_c2b
	ld xwa, xiz
	lds bc, 0
	calr HDAE5000_HD_Sector_Write
	jr t, .LHD_SR__a_exit
.LHD_SR__a_c2b:
	ld xwa, xiz
	lds bc, 1
	calr HDAE5000_HD_Sector_Write
	jr t, .LHD_SR__a_exit
	; Case 3: sector write (BC=2 or 3)
	ld xwa, (xsp + 0x04)
	bit 0x07, wa
	jr z, .LHD_SR__a_c3b
	ld xwa, xiz
	lds bc, 2
	calr HDAE5000_HD_Sector_Write
	jr t, .LHD_SR__a_exit
.LHD_SR__a_c3b:
	ld xwa, xiz
	lds bc, 3
	calr HDAE5000_HD_Sector_Write
	jr t, .LHD_SR__a_exit
	; Case 4: sector write (BC=4 or 5)
	ld xwa, (xsp + 0x04)
	bit 0x07, wa
	jr z, .LHD_SR__a_c4b
	ld xwa, xiz
	lds bc, 4
	calr HDAE5000_HD_Sector_Write
	jr t, .LHD_SR__a_exit
.LHD_SR__a_c4b:
	ld xwa, xiz
	lds bc, 5
	calr HDAE5000_HD_Sector_Write
	jr t, .LHD_SR__a_exit
	; Case 5: sector write (BC=6 or 7)
	ld xwa, (xsp + 0x04)
	bit 0x07, wa
	jr z, .LHD_SR__a_c5b
	ld xwa, xiz
	lds bc, 6
	calr HDAE5000_HD_Sector_Write
	jr t, .LHD_SR__a_exit
.LHD_SR__a_c5b:
	ld xwa, xiz
	lds bc, 7
	calr HDAE5000_HD_Sector_Write
	jr t, .LHD_SR__a_exit
	; Case 6: sector write (BC=8 or 9)
	ld xwa, (xsp + 0x04)
	bit 0x07, wa
	jr z, .LHD_SR__a_c6b
	ld xwa, xiz
	ldw bc, 0x0008
	calr HDAE5000_HD_Sector_Write
	jr t, .LHD_SR__a_exit
.LHD_SR__a_c6b:
	ld xwa, xiz
	ldw bc, 0x0009
	calr HDAE5000_HD_Sector_Write
.LHD_SR__a_exit:			; common exit for handler A
	ld xwa, xiz
	ld xbc, (xsp + 0x08)
	ld xde, (xsp + 0x04)
	ldl_da xhl, (0x23a1a2)
	ld_sril xhl, (xhl + 0x0e0a)
	ld_sril xix, (xhl + 0x00dc)
	call (xix)
.LHD_SR__a_epilogue:
	pop xiz
	inc 0, xsp
	ret
	;
	; Part 3: Event handler B (0x286CED)
.LHD_SR__handlerB:
	dec 0, xsp
	push xiz
	ld (xsp + 0x04), xde
	ld xiz, xbc			; save event code in XIZ
	ld (xsp + 0x08), xwa
	ld xwa, xiz			; XWA = event code
	cp xwa, 0x01c00007
	jrl z, .LHD_SR__b_evt07
	cp xwa, 0x01c0000d
	jr z, .LHD_SR__b_evt0d
	cp xwa, 0x01e00085
	jr z, .LHD_SR__b_evt85
	cp xwa, 0x01c00001
	jrl nz, .LHD_SR__b_exit
	; Event 0x01: table lookup and copy
	ldw_da xwa, (0x23a092)
	ldw_da xbc, (0x23a094)
	call HDAE5000_Table_Lookup
	ld wa, hl
	cp wa, 0xffff
	jr z, .LHD_SR__b_nomatch
	lda_24 xwa, (0x22aa4c)
	pushw 0x0002
	ld bc, hl
	lda_24 xde, (0x2e1c96)
	calr HDAE5000_HD_Data_Copy
	jrl t, .LHD_SR__b_exit
.LHD_SR__b_nomatch:
	lda_24 xwa, (0x22aa4c)
	pushw 0x0002
	lda_24 xde, (0x2e1c96)
	lds bc, 0
	calr HDAE5000_HD_Data_Copy
	jrl t, .LHD_SR__b_exit
.LHD_SR__b_evt85:			; event 0x85: XHL = 1
	lds32 xhl, 1
	jrl t, .LHD_SR__b_epilogue
.LHD_SR__b_evt0d:			; event 0x0D: display update
	ld xwa, (xsp + 0x08)
	ld xbc, xiz
	ld xde, (xsp + 0x04)
	ldl_da xhl, (0x23a1a2)
	ld_sril xhl, (xhl + 0x0e0a)
	ld_sril xhl, (xhl + 0x00dc)
	call (xhl)
	lda_24 xwa, (0x2e2d1e)
	ld xbc, xwa
	ld xwa, (xsp + 0x08)
	ld xde, xbc
	ldl_da xbc, (0x23a1a2)
	ld_sril xbc, (xbc + 0x0e0a)
	ld_sril xhl, (xbc + 0x0100)
	ld xbc, 0x01c0000f
	call (xhl)
	lds32 xhl, 0
	jrl t, .LHD_SR__b_epilogue
.LHD_SR__b_evt07:			; event 0x07: sector operations
	ld xde, (xsp + 0x04)
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xix, (xwa + 0x0100)
	ld xwa, 0x02600024
	ld xbc, 0x01e00029
	call (xix)
	cp xhl, 0x00000009
	jr z, .LHD_SR__b_check_state
	cp xhl, 0x00000008
	jr nz, .LHD_SR__b_exit
.LHD_SR__b_check_state:
	cpw_da (0x22aa5c), 0x0005; state == 5?
	jr nz, .LHD_SR__b_exit
	; State 5: display manager call + sector read
	pushw 0x0001
	ld xwa, 0x007f008f
	push xwa
	ldw_da xwa, (0x23a092)
	ldw_da xbc, (0x23a094)
	ldw_da xde, (0x22aa4c)
	calr HDAE5000_Display_Manager
	pushw 0x0001
	lds wa, 0
	lds bc, 0
	lds de, 6
	calr HDAE5000_FS_Init
	cpib_da (0x229dac), 0x02
	jr nz, .LHD_SR__b_exit
	ldw_da xwa, (0x22aa4c)
	and wa, 0x0100
	cp wa, 0x0100
	jr nz, .LHD_SR__b_exit
	; Flag set: register display handler
	ldl_da xwa, (0x23a1a2)
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)
	ld xwa, 0x007f02f0
	ld xbc, 0x01c00001
	lds32 xde, 0
	call (xhl)
.LHD_SR__b_exit:			; common exit
	ld xwa, (xsp + 0x08)
	ld xbc, xiz
	ld xde, (xsp + 0x04)
	ldl_da xhl, (0x23a1a2)
	ld_sril xhl, (xhl + 0x0e0a)
	ld_sril xix, (xhl + 0x00dc)
	call (xix)
.LHD_SR__b_epilogue:
	pop xiz
	inc 0, xsp
	ret

HDAE5000_HD_Sector_Write:	; 0x286E50 (646 bytes)
	; Write sectors to HD; accesses 0x229DAA, 0x229DAC
	; --- Prologue ---
	push xiz				; 3e
	ld	qiz, 0

	; --- Switch on state variable at 0x22AA5C ---
	ldw_da xwa, (0x22aa5c); d2 5c aa 22 20 — ld wa, (0x22aa5c)
	cps wa, 4				; d8 dc
	jrl z, .Lsw_case4			; 76 xx xx
	cps wa, 3				; d8 db
	jrl z, .Lsw_case3			; 76 xx xx
	cps wa, 2				; d8 da
	jr z, .Lsw_case2			; 66 xx
	cps wa, 1				; d8 d9
	jr z, .Lsw_case1			; 66 xx
	cps wa, 0				; d8 d8
	jrl nz, .Lsw_exit			; 7e xx xx

	; === Case 0: initialize cylinder from BC*100, set state=1 ===
	ld wa, bc				; d9 88
	mul wa, 0x0064				; d8 08 64 00
	stw_da (0x22aa5e), xwa; f2 5e aa 22 50 — ld (0x22aa5e), wa
	stiw_da (0x22aa60), 0x0000; f2 60 aa 22 02 00 00
	stiw_da (0x22aa5c), 0x0001; f2 5c aa 22 02 01 00
	pushw 0x0001
	ldw_da xwa, (0x22aa5e); d2 5e aa 22 20
	ldw_da xbc, (0x22aa60); d2 60 aa 22 21
	ldw_da xde, (0x22aa5c); d2 5c aa 22 22
	calr HDAE5000_FS_Init			; 1e xx xx
	ld	qiz, hl
	jrl t, .Lsw_exit			; 78 xx xx

	; === Case 1: add BC*10 to cylinder, set state=2 ===
.Lsw_case1:					; 0x286EA4
	ld wa, bc				; d9 88
	mul wa, 0x000a				; d8 08 0a 00
	adddm16_24 (0x22aa5e), xwa; d2 5e aa 22 88
	stiw_da (0x22aa5c), 0x0002; f2 5c aa 22 02 02 00
	pushw 0x0001
	ldw_da xwa, (0x22aa5e); d2 5e aa 22 20
	ldw_da xbc, (0x22aa60); d2 60 aa 22 21
	ldw_da xde, (0x22aa5c); d2 5c aa 22 22
	calr HDAE5000_FS_Init			; 1e xx xx
	ld	qiz, hl
	jrl t, .Lsw_exit			; 78 xx xx

	; === Case 2: add BC to cylinder, set state=3 ===
.Lsw_case2:					; 0x286ED1
	adddm16_24 (0x22aa5e), xbc; d2 5e aa 22 89
	stiw_da (0x22aa5c), 0x0003; f2 5c aa 22 02 03 00
	pushw 0x0001
	ldw_da xwa, (0x22aa5e); d2 5e aa 22 20
	ldw_da xbc, (0x22aa60); d2 60 aa 22 21
	ldw_da xde, (0x22aa5c); d2 5c aa 22 22
	calr HDAE5000_FS_Init			; 1e xx xx
	ld	qiz, hl
	jrl t, .Lsw_exit			; 78 xx xx

	; === Case 3: set head from BC*10, set state=4 ===
.Lsw_case3:					; 0x286EF8
	ld wa, bc				; d9 88
	mul wa, 0x000a				; d8 08 0a 00
	stw_da (0x22aa60), xwa; f2 60 aa 22 50
	stiw_da (0x22aa5c), 0x0004; f2 5c aa 22 02 04 00
	pushw 0x0001
	ldw_da xwa, (0x22aa5e); d2 5e aa 22 20
	ldw_da xbc, (0x22aa60); d2 60 aa 22 21
	ldw_da xde, (0x22aa5c); d2 5c aa 22 22
	calr HDAE5000_FS_Init			; 1e xx xx
	ld	qiz, hl
	jrl t, .Lsw_exit			; 78 xx xx

	; === Case 4: add BC to head, set state=5, then process ===
.Lsw_case4:					; 0x286F25
	adddm16_24 (0x22aa60), xbc; d2 60 aa 22 89
	stiw_da (0x22aa5c), 0x0005; f2 5c aa 22 02 05 00
	pushw 0x0001
	ldw_da xwa, (0x22aa5e); d2 5e aa 22 20
	ldw_da xbc, (0x22aa60); d2 60 aa 22 21
	ldw_da xde, (0x22aa5c); d2 5c aa 22 22
	calr HDAE5000_FS_Init			; 1e xx xx
	ld	qiz, hl

	; --- After all cases: check result ---
	ld	wa, qiz
	cps wa, 0				; d8 d8
	jrl nz, .Lsw_exit			; 7e xx xx — error → exit

	; --- Compute sector address and look up in table ---
	ldw_da xwa, (0x22aa5e); d2 5e aa 22 20 — cylinder
	dec 1, wa				; d8 69
	stw_da (0x23a092), xwa; f2 92 a0 23 50
	ldw_da xwa, (0x22aa60); d2 60 aa 22 20 — head
	dec 1, wa				; d8 69
	stw_da (0x23a094), xwa; f2 94 a0 23 50
	ldw_da xwa, (0x23a092); d2 92 a0 23 20
	ldw_da xbc, (0x23a094); d2 94 a0 23 21
	call HDAE5000_Table_Lookup		; 1d b3 03 29
	ld iz, hl				; db 8e
	ld wa, iz				; de 88
	cp wa, 0xffff				; d8 cf ff ff
	jr z, .Lsw_lookup_notfound		; 66 xx

	; --- Found: copy data and seek ---
.Lsw_lookup_found:				; 0x286F81
	lda_24 xwa, (0x22aa4c); f2 4c aa 22 30
	ld bc, iz				; de 89
	pushw 0x0002
	lda_24 xde, (0x2e1c96); f2 96 1c 2e 32
	calr HDAE5000_HD_Data_Copy		; 1e xx xx
	ldw_da xbc, (0x23a092); d2 92 a0 23 21
	ldw_da xde, (0x23a094); d2 94 a0 23 22
	ld wa, iz				; de 88
	pushw wa                                ; push wa (compact 16-bit)
	ld xwa, 0x007f0098			; 40 98 00 7f 00
	calr HDAE5000_HD_Seek			; 1e xx xx
	jr t, .Lsw_after_lookup			; 68 xx

	; --- Not found: copy default data and seek with -1 ---
.Lsw_lookup_notfound:				; 0x286FAA
	lda_24 xwa, (0x22aa4c); f2 4c aa 22 30
	pushw 0x0002
	lda_24 xde, (0x2e1c96); f2 96 1c 2e 32
	lds bc, 0				; d9 a8
	calr HDAE5000_HD_Data_Copy		; 1e xx xx
	pushw 0xffff
	ld xwa, 0x007f0098			; 40 98 00 7f 00
	ldw bc, 0xffff				; 31 ff ff
	ldw de, 0xffff				; 32 ff ff
	calr HDAE5000_HD_Seek			; 1e xx xx

	; --- After table lookup: check sectors per track ---
.Lsw_after_lookup:				; 0x286FCD
	cpib_da (0x229daa), 0x02; c2 aa 9d 22 3f 02
	jr nz, .Lsw_exit			; 6e xx
	; Sectors per track == 2: do display and FS operations
	pushw 0x0001
	ld xwa, 0x007f008f			; 40 8f 00 7f 00
	push xwa				; 38
	ldw_da xwa, (0x23a092); d2 92 a0 23 20
	ldw_da xbc, (0x23a094); d2 94 a0 23 21
	ldw_da xde, (0x22aa4c); d2 4c aa 22 22
	calr HDAE5000_Display_Manager		; 1e xx xx
	pushw 0x0001
	lds wa, 0				; d8 a8
	lds bc, 0				; d9 a8
	lds de, 6				; da ae
	calr HDAE5000_FS_Init			; 1e xx xx
	; Check second disk flag
	cpib_da (0x229dac), 0x02; c2 ac 9d 22 3f 02
	jr nz, .Lsw_exit			; 6e xx
	; Check bit 8 of aa4c entry
	ldw_da xwa, (0x22aa4c); d2 4c aa 22 20
	and wa, 0x0100				; d8 cc 00 01
	cp wa, 0x0100				; d8 cf 00 01
	jr nz, .Lsw_exit			; 6e xx
	; Register event: format complete
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23
	ld xwa, 0x007f02f0			; 40 f0 02 7f 00
	ld xbc, 0x01c00001			; 41 01 00 c0 01
	lds32 xde, 0				; ea a8
	call (xhl)				; b3 e8

	; === Exit: check QIZ result ===
.Lsw_exit:					; 0x287030
	ld	wa, qiz
	cp wa, 0xfffe				; d8 cf fe ff
	jr z, .Lsw_err_fffe			; 66 xx
	cp wa, 0xffff				; d8 cf ff ff
	jrl nz, .Lsw_done			; 7e xx xx

	; --- Error 0xFFFF: register error + timer ---
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0104)             ; e3 e1 04 01 23 — ld xhl, (xwa+0x0104)
	ld xwa, 0x007f02b7			; 40 b7 02 7f 00
	ld xbc, 0x01c00001			; 41 01 00 c0 01
	lds32 xde, 5				; ea ad
	call (xhl)				; b3 e8
	ld xwa, 0x01ca0002			; 40 02 00 ca 01
	push xwa				; 38
	ld xwa, 0x007f008f			; 40 8f 00 7f 00
	push xwa				; 38
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0410)             ; e3 e1 10 04 23 — ld xhl, (xwa+0x0410)
	ld xwa, 0x00000021			; 40 21 00 00 00
	ld xbc, 0x007f02b8			; 41 b8 02 7f 00
	ld xde, 0xffffffff			; 42 ff ff ff ff
	call (xhl)				; b3 e8
	jr t, .Lsw_done				; 68 xx

	; --- Error 0xFFFE: register different error + timer ---
.Lsw_err_fffe:					; 0x28708B
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0104)             ; e3 e1 04 01 23 — ld xhl, (xwa+0x0104)
	ld xwa, 0x007f02bc			; 40 bc 02 7f 00
	ld xbc, 0x01c00001			; 41 01 00 c0 01
	lds32 xde, 5				; ea ad
	call (xhl)				; b3 e8
	ld xwa, 0x01ca0002			; 40 02 00 ca 01
	push xwa				; 38
	ld xwa, 0x007f008f			; 40 8f 00 7f 00
	push xwa				; 38
	ldl_da xwa, (0x23a1a2); e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0410)             ; e3 e1 10 04 23 — ld xhl, (xwa+0x0410)
	ld xwa, 0x00000021			; 40 21 00 00 00
	ld xbc, 0x007f02bd			; 41 bd 02 7f 00
	ld xde, 0xffffffff			; 42 ff ff ff ff
	call (xhl)				; b3 e8

	; --- Epilogue ---
.Lsw_done:					; 0x2870D4
	pop xiz					; 5e
	ret					; 0e

; --- Filesystem Operations ---
