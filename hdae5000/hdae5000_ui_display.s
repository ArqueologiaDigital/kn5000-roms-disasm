HDAE5000_Menu_Register_A:	; 0x28AC1F (73 bytes)
	; Register menu handler (variant A)
	; Input: A = menu index
	; Uses workspace callbacks at +0x0E0A to register menu entries
	dec 2, xsp			; allocate local space
	ld (xsp), a			; save menu index
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril xwa, (xwa + 0x0e0a)             ; ld XWA, (XWA + 0x0E0A) — menu table
	ld_sril xhl, (xwa + 0x0534)             ; ld XHL, (XWA + 0x0534) — register fn
	ld xwa, 0xFFFFFFFF		; param: all bits set
	ld xbc, 0x01C00014		; param: menu geometry
	call (xhl)			; register first entry
	lds32 xwa, 0			; clear XWA
	ld a, (xsp)			; restore menu index
	add xwa, 0x01800000		; construct second entry ID
	ld xde, xwa			; XDE = entry ID
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril xwa, (xwa + 0x0e0a)             ; ld XWA, (XWA + 0x0E0A) — menu table
	ld_sril xhl, (xwa + 0x0124)             ; ld XHL, (XWA + 0x0124) — alternate fn
	ld xwa, 0xFFFFFFFF		; param: all bits set
	ld xbc, 0x01C00014		; param: menu geometry
	call (xhl)			; register second entry
	inc 2, xsp			; deallocate local space
	ret

HDAE5000_Menu_Register_B:	; 0x28AC68 (146 bytes)
	; Register menu handler (variant B) — two sub-routines
	; First sub-routine: register with 0x01C00015
	dec 2, xsp			; allocate local space
	ld (xsp), a			; save menu index
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril xwa, (xwa + 0x0e0a)             ; ld XWA, (XWA + 0x0E0A) — menu table
	ld_sril xhl, (xwa + 0x0534)             ; ld XHL, (XWA + 0x0534) — register fn
	ld xwa, 0xFFFFFFFF		; param: all bits set
	ld xbc, 0x01C00015		; param: menu geometry
	call (xhl)			; register first entry
	lds32 xwa, 0			; clear XWA
	ld a, (xsp)			; restore menu index
	add xwa, 0x01A00000		; construct entry ID
	ld xde, xwa			; XDE = entry ID
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril xwa, (xwa + 0x0e0a)             ; ld XWA, (XWA + 0x0E0A) — menu table
	ld_sril xhl, (xwa + 0x0124)             ; ld XHL, (XWA + 0x0124) — alternate fn
	ld xwa, 0xFFFFFFFF		; param: all bits set
	ld xbc, 0x01C00015		; param: menu geometry
	call (xhl)			; register second entry
	inc 2, xsp			; deallocate local space
	ret
	; Second sub-routine: register with 0x01C00016
	dec 2, xsp			; allocate local space
	ld (xsp), a			; save menu index
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril xwa, (xwa + 0x0e0a)             ; ld XWA, (XWA + 0x0E0A) — menu table
	ld_sril xhl, (xwa + 0x0534)             ; ld XHL, (XWA + 0x0534) — register fn
	ld xwa, 0xFFFFFFFF		; param: all bits set
	ld xbc, 0x01C00016		; param: menu geometry
	call (xhl)			; register first entry
	lds32 xwa, 0			; clear XWA
	ld a, (xsp)			; restore menu index
	add xwa, 0x01A00000		; construct entry ID
	ld xde, xwa			; XDE = entry ID
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril xwa, (xwa + 0x0e0a)             ; ld XWA, (XWA + 0x0E0A) — menu table
	ld_sril xhl, (xwa + 0x0124)             ; ld XHL, (XWA + 0x0124) — alternate fn
	ld xwa, 0xFFFFFFFF		; param: all bits set
	ld xbc, 0x01C00016		; param: menu geometry
	call (xhl)			; register second entry
	inc 2, xsp			; deallocate local space
	ret

HDAE5000_HD_Shutdown:	; 0x28ACFA (78 bytes)
	; Shut down HD extension — unregister menu entries via workspace callbacks
	; Input: WA = parameter (zero-extended)
	; Tail-calls via jp (xhl) for final unregistration
	extz wa				; zero-extend parameter
	ld32_24 xbc, 0x23a1a2                 ; ld XBC, (0x23A1A2) — workspace ptr
	ld_sril xbc, (xbc + 0x0e88)             ; ld XBC, (XBC + 0x0E88)
	ld_sril xhl, (xbc + 0x012c)             ; ld XHL, (XBC + 0x012C) — shutdown handler
	call (xhl)			; invoke shutdown
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril xwa, (xwa + 0x0e0a)             ; ld XWA, (XWA + 0x0E0A) — menu table
	ld_sril xhl, (xwa + 0x0534)             ; ld XHL, (XWA + 0x0534) — register fn
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x01C00016		; unregister params
	call (xhl)			; unregister first entry
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril xwa, (xwa + 0x0e0a)             ; ld XWA, (XWA + 0x0E0A) — menu table
	ld_sril xhl, (xwa + 0x0124)             ; ld XHL, (XWA + 0x0124)
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x01C00016
	ld xde, 0x01A000EE		; entry ID
	jp (xhl)			; tail-call: unregister second entry

HDAE5000_Menu_Handler:	; 0x28AD48 (248 bytes)
	; Handle menu events: copy params, register handler, dispatch callback
	; Input: WA = menu ID, XBC = param block, XDE = context
	lda xsp, (xsp - 22)		; allocate 22 bytes on stack
	pushw iz
	ld (xsp + 20), xde		; save context
	ld iz, wa			; IZ = menu ID
	pushw 0x0010			; param: size 16
	push xbc			; param: source block
	lda xwa, (xsp + 8)		; XWA = destination (stack buffer)
	push xwa
	call HDAE5000_MemCopy_Reverse	; copy param block to stack
	lda xsp, (xsp + 10)		; pop 3 args (10 bytes)
	ld (xsp + 18), 0x00		; clear status byte
	; --- Register menu handler ---
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril xwa, (xwa + 0x0e0a)             ; ld XWA, (XWA + 0x0E0A)
	ld_sril xhl, (xwa + 0x0100)             ; ld XHL, (XWA + 0x0100)
	ld xwa, 0x007F02C1		; handler ID
	ld xbc, 0x01C00001		; param
	lds32 xde, 3			; mode = 3
	call (xhl)
	calr HDAE5000_Wait_Callback_Loop
	; --- Copy to table ---
	lda xwa, (xsp + 2)		; XWA = stack buffer ptr
	ld xbc, xwa			; XBC = buffer
	ld wa, iz			; WA = menu ID
	lds de, 0			; DE = 0
	call HDAE5000_Copy_To_Table
	cp hl, 0xFFFF			; check if copy failed
	jr z, .Lmh_alt			; if failed, try alternate path
	; --- Direct dispatch ---
	ld xwa, (xsp + 20)		; reload context
	ld32_24 xbc, 0x23a1a2                 ; ld XBC, (0x23A1A2)
	ld_sril xbc, (xbc + 0x0e0a)             ; ld XBC, (XBC + 0x0E0A)
	ld_sril xhl, (xbc + 0x0104)             ; ld XHL, (XBC + 0x0104)
	ld xbc, 0x01C00001		; param
	lds32 xde, 0			; mode = 0
	call (xhl)
	jr t, .Lmh_finish
.Lmh_alt:
	; --- Alternate handler ---
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0100)             ; ld XHL, (XWA + 0x0100)
	ld xwa, 0x007F0297		; alternate handler ID
	ld xbc, 0x01C00001
	lds32 xde, 0
	call (xhl)
	ld xbc, (xsp + 20)		; XBC = context
	ld xwa, 0x007F0298		; event ID
	calr HDAE5000_UI_Main_Handler
	; --- Register display handlers ---
	ld xwa, 0x01CA0002		; display param
	push xwa
	ld xwa, (xsp + 24)		; reload context (+4 for push)
	push xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0418)             ; ld XHL, (XWA + 0x0418)
	ld xwa, 0x0000014D		; display handler ID
	ld xbc, 0x007F0299		; event ID
	ld xde, 0xFFFFFFFF		; param
	call (xhl)
	ld xwa, 0x01CA0002		; display param
	push xwa
	ld xwa, (xsp + 24)		; reload context (+4 for push)
	push xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0410)             ; ld XHL, (XWA + 0x0410)
	ld xwa, 0x0000014D
	ld xbc, 0x007F0299
	ld xde, 0xFFFFFFFF
	call (xhl)
.Lmh_finish:
	lda_24 xwa, 0x22abf2                  ; lda XWA, 0x22ABF2
	lda xbc, (xsp + 2)		; XBC = stack buffer
	calr HDAE5000_Get_Table_Entry
	popw iz
	lda xsp, (xsp + 22)		; deallocate stack
	ret

HDAE5000_Menu_Callback:	; 0x28AE40 (248 bytes)
	; Menu callback processor: same structure as Menu_Handler with different
	; call target (Copy_Display_Cell_90) and table address (0x22AD0A)
	lda xsp, (xsp - 22)		; allocate 22 bytes on stack
	pushw iz
	ld (xsp + 20), xde		; save context
	ld iz, wa			; IZ = menu ID
	pushw 0x0010			; param: size 16
	push xbc			; param: source block
	lda xwa, (xsp + 8)		; XWA = destination (stack buffer)
	push xwa
	call HDAE5000_MemCopy_Reverse	; copy param block to stack
	lda xsp, (xsp + 10)		; pop 3 args
	ld (xsp + 18), 0x00		; clear status byte
	; --- Register menu handler ---
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2)
	ld_sril xwa, (xwa + 0x0e0a)             ; ld XWA, (XWA + 0x0E0A)
	ld_sril xhl, (xwa + 0x0100)             ; ld XHL, (XWA + 0x0100)
	ld xwa, 0x007F02C1
	ld xbc, 0x01C00001
	lds32 xde, 3
	call (xhl)
	calr HDAE5000_Wait_Callback_Loop
	; --- Copy display cell ---
	lda xwa, (xsp + 2)
	ld xbc, xwa
	ld wa, iz
	lds de, 0
	call HDAE5000_Copy_Display_Cell_90
	cp hl, 0xFFFF
	jr z, .Lmc_alt
	; --- Direct dispatch ---
	ld xwa, (xsp + 20)
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e0a)
	ld_sril xhl, (xbc + 0x0104)             ; ld XHL, (XBC + 0x0104)
	ld xbc, 0x01C00001
	lds32 xde, 0
	call (xhl)
	jr t, .Lmc_finish
.Lmc_alt:
	; --- Alternate handler ---
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0100)
	ld xwa, 0x007F0297
	ld xbc, 0x01C00001
	lds32 xde, 0
	call (xhl)
	ld xbc, (xsp + 20)
	ld xwa, 0x007F0298
	calr HDAE5000_UI_Main_Handler
	; --- Register display handlers ---
	ld xwa, 0x01CA0002
	push xwa
	ld xwa, (xsp + 24)
	push xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0418)             ; ld XHL, (XWA + 0x0418)
	ld xwa, 0x0000014D
	ld xbc, 0x007F0299
	ld xde, 0xFFFFFFFF
	call (xhl)
	ld xwa, 0x01CA0002
	push xwa
	ld xwa, (xsp + 24)
	push xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0410)             ; ld XHL, (XWA + 0x0410)
	ld xwa, 0x0000014D
	ld xbc, 0x007F0299
	ld xde, 0xFFFFFFFF
	call (xhl)
.Lmc_finish:
	lda_24 xwa, 0x22ad0a                  ; lda XWA, 0x22AD0A
	lda xbc, (xsp + 2)
	calr HDAE5000_Get_Table_Entry
	popw iz
	lda xsp, (xsp + 22)
	ret

HDAE5000_Display_Manager:	; 0x28AF38 (441 bytes)
	; Manage display state; accesses 0x229DAB
	; --- Prologue ---
	dec 0, xsp				; ef 68 — allocate 4 bytes
	pushw iz                                ; push iz (compact 16-bit)
	ld (xsp + 0x04), de			; bf 04 52
	ld (xsp + 0x06), bc			; bf 06 51
	ld (xsp + 0x08), wa			; bf 08 50
	ld iz, (xsp + 0x12)			; 9f 12 26 — load mode arg
	cps iz, 1				; de d9

	; --- Branch on mode ---
	jr nz, .Ldm_mode2			; 6e xx

	; Mode 1: register event via +0x0100 vtable
	ld32_24 xwa, 0x23a1a2		; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld_sril xhl, (xwa + 0x0100)             ; e3 e1 00 01 23 — ld xhl, (xwa+0x0100)
	ld xwa, 0x007f02c1			; 40 c1 02 7f 00
	ld xbc, 0x01c00001			; 41 01 00 c0 01
	lds32 xde, 5				; ea ad
	call (xhl)				; b3 e8
	calr HDAE5000_Wait_Callback_Loop	; 1e xx xx
	jr t, .Ldm_common			; 68 xx

.Ldm_mode2:					; 0x28AF6D
	; Mode 2: register event via +0x0124 vtable, then call +0x0E88/+0x00E4
	ld32_24 xwa, 0x23a1a2		; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23 — ld xhl, (xwa+0x0124)
	ld xwa, 0x007f02c1			; 40 c1 02 7f 00
	ld xbc, 0x01c00001			; 41 01 00 c0 01
	lds32 xde, 5				; ea ad
	call (xhl)				; b3 e8
	ld32_24 xwa, 0x23a1a2		; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e88)             ; e3 e1 88 0e 20 — ld xwa, (xwa+0x0e88)
	ld_sril xhl, (xwa + 0x00e4)             ; e3 e1 e4 00 23 — ld xhl, (xwa+0x00e4)
	ldw wa, 0x0064				; 30 64 00
	call (xhl)				; b3 e8
	calr HDAE5000_Wait_Callback_Loop	; 1e xx xx

.Ldm_common:					; 0x28AFA1
	; Common: dispatch via saved args
	pushw iz                                ; push iz (compact 16-bit)
	pushw 0x0000
	ld wa, (xsp + 0x0c)			; 9f 0c 20
	ld bc, (xsp + 0x0a)			; 9f 0a 21
	ld de, (xsp + 0x08)			; 9f 08 22
	call 0x2905e9				; 1d e9 05 29
	ld (xsp + 0x02), hl			; bf 02 53 — save result
	ld wa, (xsp + 0x02)			; 9f 02 20
	cp wa, 0xffff				; d8 cf ff ff
	jrl z, .Ldm_fail			; 76 xx xx — WA == -1 → failure

	; --- Success path ---
	cpi8_24 0x229dab, 0x01			; c2 ab 9d 22 3f 01
	jr nz, .Ldm_success_check		; 6e xx
	lds wa, 1				; d8 a9
	calr HDAE5000_Menu_Register_A		; 1e xx xx
	jrl t, .Ldm_done			; 78 xx xx

.Ldm_success_check:				; 0x28AFCF
	cps iz, 1				; de d9
	jr nz, .Ldm_mode2_dereg		; 6e xx

	; Mode 1 deregistration: via +0x0104 vtable
	ld xwa, (xsp + 0x0e)			; af 0e 20
	ld32_24 xbc, 0x23a1a2		; e2 a2 a1 23 21
	ld_sril xbc, (xbc + 0x0e0a)             ; e3 e5 0a 0e 21 — ld xbc, (xbc+0x0e0a)
	ld_sril xhl, (xbc + 0x0104)             ; e3 e5 04 01 23 — ld xhl, (xbc+0x0104)
	ld xbc, 0x01c00001			; 41 01 00 c0 01
	lds32 xde, 0				; ea a8
	call (xhl)				; b3 e8
	ld32_24 xwa, 0x23a1a2		; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld_sril xhl, (xwa + 0x0104)             ; e3 e1 04 01 23 — ld xhl, (xwa+0x0104)
	ld xwa, 0xffffffff			; 40 ff ff ff ff
	ld xbc, 0x01c00018			; 41 18 00 c0 01
	lds32 xde, 0				; ea a8
	call (xhl)				; b3 e8
	jrl t, .Ldm_done			; 78 xx xx

.Ldm_mode2_dereg:				; 0x28B00E
	; Mode 2 deregistration: via +0x0124 vtable
	ld xwa, (xsp + 0x0e)			; af 0e 20
	ld32_24 xbc, 0x23a1a2		; e2 a2 a1 23 21
	ld_sril xbc, (xbc + 0x0e0a)             ; e3 e5 0a 0e 21 — ld xbc, (xbc+0x0e0a)
	ld_sril xhl, (xbc + 0x0124)             ; e3 e5 24 01 23 — ld xhl, (xbc+0x0124)
	ld xbc, 0x01c00001			; 41 01 00 c0 01
	lds32 xde, 0				; ea a8
	call (xhl)				; b3 e8
	ld32_24 xwa, 0x23a1a2		; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23 — ld xhl, (xwa+0x0124)
	ld xwa, 0xffffffff			; 40 ff ff ff ff
	ld xbc, 0x01c00018			; 41 18 00 c0 01
	lds32 xde, 0				; ea a8
	call (xhl)				; b3 e8
	jrl t, .Ldm_done			; 78 xx xx

.Ldm_fail:					; 0x28B049
	; Failure path: register error event
	cps iz, 1				; de d9
	jr nz, .Ldm_fail_mode2			; 6e xx

	; Fail mode 1: via +0x0100 vtable
	ld32_24 xwa, 0x23a1a2		; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld_sril xhl, (xwa + 0x0100)             ; e3 e1 00 01 23 — ld xhl, (xwa+0x0100)
	ld xwa, 0x007f029d			; 40 9d 02 7f 00
	ld xbc, 0x01c00001			; 41 01 00 c0 01
	lds32 xde, 0				; ea a8
	call (xhl)				; b3 e8
	jr t, .Ldm_fail_common			; 68 xx

.Ldm_fail_mode2:				; 0x28B06C
	; Fail mode 2: via +0x0124 vtable
	ld32_24 xwa, 0x23a1a2		; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld_sril xhl, (xwa + 0x0124)             ; e3 e1 24 01 23 — ld xhl, (xwa+0x0124)
	ld xwa, 0x007f029d			; 40 9d 02 7f 00
	ld xbc, 0x01c00001			; 41 01 00 c0 01
	lds32 xde, 0				; ea a8
	call (xhl)				; b3 e8

.Ldm_fail_common:				; 0x28B089
	; Register error display handlers
	ld xbc, (xsp + 0x0e)			; af 0e 21
	ld xwa, 0x007f029e			; 40 9e 02 7f 00
	calr HDAE5000_UI_Main_Handler		; 1e xx xx
	; Register via +0x0418 vtable (timer handler)
	ld xwa, 0x01ca0002			; 40 02 00 ca 01
	push xwa				; 38
	ld xwa, (xsp + 0x12)			; af 12 20
	push xwa				; 38
	ld32_24 xwa, 0x23a1a2		; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld_sril xhl, (xwa + 0x0418)             ; e3 e1 18 04 23 — ld xhl, (xwa+0x0418)
	ld xwa, 0x0000014d			; 40 4d 01 00 00
	ld xbc, 0x007f029f			; 41 9f 02 7f 00
	ld xde, 0xffffffff			; 42 ff ff ff ff
	call (xhl)				; b3 e8
	; Register via +0x0410 vtable (second timer handler)
	ld xwa, 0x01ca0002			; 40 02 00 ca 01
	push xwa				; 38
	ld xwa, (xsp + 0x12)			; af 12 20
	push xwa				; 38
	ld32_24 xwa, 0x23a1a2		; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20 — ld xwa, (xwa+0x0e0a)
	ld_sril xhl, (xwa + 0x0410)             ; e3 e1 10 04 23 — ld xhl, (xwa+0x0410)
	ld xwa, 0x0000014d			; 40 4d 01 00 00
	ld xbc, 0x007f029f			; 41 9f 02 7f 00
	ld xde, 0xffffffff			; 42 ff ff ff ff
	call (xhl)				; b3 e8

.Ldm_done:					; 0x28B0E8
	; --- Epilogue ---
	ld hl, (xsp + 0x02)			; 9f 02 23
	popw iz                                 ; pop iz (compact 16-bit)
	inc 0, xsp				; ef 60
	retd 0x0006				; 0f 06 00

HDAE5000_Display_Scroll:	; 0x28B0F1 (271 bytes)
	; Handle display scroll: register handler, copy data, dispatch callback
	; Input: WA = index, BC = param, DE = context ptr
	lda xsp, (xsp - 34)		; allocate 34 bytes on stack (0xDE = -34)
	pushw iz
	ld iz, de			; IZ = context ptr
	ld (xsp + 32), bc		; save BC param at offset 0x20
	ld (xsp + 34), wa		; save WA index at offset 0x22
	; --- Register handler via workspace ---
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2)
	ld_sril xwa, (xwa + 0x0e0a)             ; ld XWA, (XWA + 0x0E0A)
	ld_sril xhl, (xwa + 0x0100)             ; ld XHL, (XWA + 0x0100)
	ld xwa, 0x007F02C1
	ld xbc, 0x01C00001
	lds32 xde, 0
	call (xhl)
	; --- Copy data to stack buffer ---
	pushw 0x001A			; param: size 26
	ld xwa, (xsp + 48)		; reload source (+2 for pushw) = XSP+0x30
	push xwa
	lda xwa, (xsp + 10)		; destination (stack buffer at +0x0A)
	push xwa
	call HDAE5000_MemCopy_Reverse
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
	call 0x291140			; call scroll handler
	ld (xsp + 2), hl		; save result at offset 2
	; --- Check result ---
	ld wa, (xsp + 2)		; reload result
	cp wa, 0xFFFF			; check for failure
	jr z, .Lds_alt			; if failed, try alternate
	; --- Direct dispatch ---
	ld xwa, (xsp + 40)		; load context (XSP+0x28)
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e0a)
	ld_sril xhl, (xbc + 0x0104)
	ld xbc, 0x01C00001
	lds32 xde, 0
	call (xhl)
	jr t, .Lds_finish
.Lds_alt:
	; --- Alternate handler ---
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0100)
	ld xwa, 0x007F0297
	ld xbc, 0x01C00001
	lds32 xde, 0
	call (xhl)
	ld xbc, (xsp + 40)		; XBC = context (XSP+0x28)
	ld xwa, 0x007F0298
	calr HDAE5000_UI_Main_Handler
	; --- Register display handlers ---
	ld xwa, 0x01CA0002
	push xwa
	ld xwa, (xsp + 44)		; XSP+0x2C
	push xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0418)             ; +0x0418
	ld xwa, 0x0000014D
	ld xbc, 0x007F0299
	ld xde, 0xFFFFFFFF
	call (xhl)
	ld xwa, 0x01CA0002
	push xwa
	ld xwa, (xsp + 44)		; XSP+0x2C
	push xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0410)             ; +0x0410
	ld xwa, 0x0000014D
	ld xbc, 0x007F0299
	ld xde, 0xFFFFFFFF
	call (xhl)
.Lds_finish:
	lda_24 xwa, 0x22ac7e                  ; lda XWA, 0x22AC7E
	lda xbc, (xsp + 4)
	calr HDAE5000_Get_Table_Entry
	ld hl, (xsp + 2)		; restore result to HL
	popw iz
	lda xsp, (xsp + 34)		; deallocate stack
	retd 0x000A			; return and pop 10 bytes

HDAE5000_Display_Clear:	; 0x28B200 (43 bytes)
	; Clear display area: copy 7 bytes from ROM table, then call buffer validate
	; Input: XWA = pointer to display buffer
	lds ix, 0			; IX = loop counter = 0
	cps ix, 7
	jr nc, HDAE5000_Display_Clear__push
HDAE5000_Display_Clear__loop:
	st_dpib c, 0xE0		; lda XHL, (XWA+) - get next dest addr, post-inc XWA
	ld bc, ix			; BC = current index
	extz xbc			; zero-extend to 32 bits
	ld xde, 0x002E1C82		; ROM source table
	add xde, xbc			; XDE = &table[index]
	ld c, (xde)			; C = table byte
	ld (xhl), c			; store to display buffer
	inc 1, ix			; index++
	cps ix, 7
	jr c, HDAE5000_Display_Clear__loop
HDAE5000_Display_Clear__push:
	pushw 0x002E			; push 0x2E (size param)
	pushw 0x1C82			; push 0x1C82 (offset param)
	call HDAE5000_Display_Buffer_Validate
	inc 4, xsp			; deallocate 4 bytes from stack
	ret

HDAE5000_Wait_Callback_Loop:	; 0x28B22B (45 bytes)
	; Poll workspace callback until HL returns 0
	; Uses workspace ptr at (0x23A1A2) → callback table at +0x0E88
	; Calls callback at +0x00B8 (type 3), then polls at +0x00D0 (type 1)
	jr t, .LWait_Callback__poll
.LWait_Callback__invoke:
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril xwa, (xwa + 0x0e88)             ; ld XWA, (XWA + 0x0E88) — callback table
	ld_sril xhl, (xwa + 0x00b8)             ; ld XHL, (XWA + 0x00B8) — callback fn
	lds wa, 3			; callback type = 3
	call (xhl)			; invoke callback
.LWait_Callback__poll:
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril xwa, (xwa + 0x0e88)             ; ld XWA, (XWA + 0x0E88) — callback table
	ld_sril xix, (xwa + 0x00d0)             ; ld XIX, (XWA + 0x00D0) — poll fn
	lds wa, 1			; poll type = 1
	call (xix)			; invoke poll
	cps hl, 0			; result == 0?
	jr nz, .LWait_Callback__invoke	; keep polling if non-zero
	ret

HDAE5000_Set_Menu_Visibility:	; 0x28B258 (229 bytes)
	; Set visibility for 9 menu items via workspace callback +0x0294
	; Input: A = 0 → show (IZ=1), A != 0 → hide (IZ=0)
	pushw iz
	cps a, 0
	jr nz, .Lsmv_hide
	lds iz, 1			; show mode
	jr t, .Lsmv_start
.Lsmv_hide:
	lds iz, 0			; hide mode
.Lsmv_start:
	ld bc, iz			; BC = visibility flag
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2)
	ld_sril xwa, (xwa + 0x0e0a)             ; ld XWA, (XWA + 0x0E0A)
	ld_sril xhl, (xwa + 0x0294)             ; ld XHL, (XWA + 0x0294)
	ld xwa, 0x007F002C		; menu item 1
	call (xhl)
	ld bc, iz
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0294)
	ld xwa, 0x007F0100		; menu item 2
	call (xhl)
	ld bc, iz
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0294)
	ld xwa, 0x007F010A		; menu item 3
	call (xhl)
	ld bc, iz
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0294)
	ld xwa, 0x007F00F9		; menu item 4
	call (xhl)
	ld bc, iz
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0294)
	ld xwa, 0x007F013E		; menu item 5
	call (xhl)
	ld bc, iz
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0294)
	ld xwa, 0x007F010D		; menu item 6
	call (xhl)
	ld bc, iz
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0294)
	ld xwa, 0x007F00DA		; menu item 7
	call (xhl)
	ld bc, iz
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0294)
	ld xwa, 0x007F00DC		; menu item 8
	call (xhl)
	ld bc, iz
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0294)
	ld xwa, 0x007F0080		; menu item 9
	call (xhl)
	popw iz
	ret

HDAE5000_Return_Stub:	; 0x28B33D (1 bytes)
	ret

HDAE5000_Get_Table_Entry:	; 0x28B33E (61 bytes)
	; Retrieve entry from data table by index
	; Input: XWA = pointer to table context structure
	; Field +0: counter, +1: previous index, +2: current index
	push xiz
	ld xiz, xwa			; XIZ = table context pointer
	push xbc
	ld a, (xiz + 2)		; A = current index
	extz wa
	muls wa, 0x001B			; offset = index * 27 (entry size)
	inc 4, wa			; skip 4-byte header
	exts xwa			; sign-extend to 32-bit
	add xwa, xiz			; XWA = pointer to entry
	push xwa			; arg: entry pointer
	call HDAE5000_MemCopy_Block
	inc 0, xsp			; clean up 8 bytes (arg + saved XBC)
	ld a, (xiz + 2)		; save current index
	ld (xiz + 1), a		; as previous index
	lda xwa, (xiz + 2)		; XWA = pointer to current index
	incm8 1, (xwa)			; increment current index
	ld a, (xwa)			; read new index value
	cps a, 5			; wrap at 5?
	jr c, .Lgte_no_wrap
	ld (xiz + 2), 0x00		; reset to 0
.Lgte_no_wrap:
	cp (xiz), 0x05		; check counter < 5
	jr nc, .Lgte_no_inc
	incm8 1, (xiz)			; increment counter
.Lgte_no_inc:
	ld xwa, xiz			; return context pointer
	calr HDAE5000_Return_Stub	; NOP call (returns immediately)
	pop xiz
	ret

HDAE5000_Validate_String:	; 0x28B37B (56 bytes)
	; Validate/navigate null-terminated record at (XWA)
	; Record format: [count][index][data...]
	; Returns XHL = pointer to data section, or 0 if record is empty
	cp (xwa), 0x00		; check if record is empty
	jr z, .LValidate_String__empty
	ld c, (xwa + 1)			; get current index
	extz bc				; zero-extend to 16-bit
	muls bc, 0x001B			; index * 27 (record stride)
	inc 4, bc			; skip 4-byte header
	st_dri3b c, 0x07, 0xE0, 0xE4	; lda XHL, (XWA + BC) — pointer to data
	cp (xwa + 1), 0x00		; check if index is non-zero
	jr nz, .LValidate_String__dec
	ld c, (xwa)			; get count
	cps c, 5			; count == 5?
	jr nz, .LValidate_String__dec_count
	ld (xwa + 1), 0x04		; wrap: index = 4 (max-1)
	jr t, .LValidate_String__ret
.LValidate_String__dec_count:
	ld c, (xwa)			; get count
	dec 1, c			; count - 1
	ld (xwa + 1), c			; index = count - 1
	jr t, .LValidate_String__ret
.LValidate_String__dec:
	decm8 1, (xwa + 1)		; index--
	jr t, .LValidate_String__ret
.LValidate_String__empty:
	lds32 xhl, 0			; return NULL
.LValidate_String__ret:
	ret

HDAE5000_Get_Status_Byte:	; 0x28B3B3 (6 bytes)
	; Return byte from 0x22AD9A in L
	ld8_24 l, 0x22ad9a                    ; ld L, (0x22AD9A)
	ret

HDAE5000_Set_Status_Byte:	; 0x28B3B9 (6 bytes)
	; Store A to 0x22AD9B
	st8_24 0x22ad9b, a                    ; ld (0x22AD9B), A
	ret

HDAE5000_Count_Active_Files:	; 0x28B3BF (43 bytes)
	; Count active file entries in table at 0x22AA9C
	; Input: none
	; Output: HL = count of entries with status byte == 1
	; Scans 20 entries (0x0014), each 0x0114 bytes apart
	lds hl, 0		; HL = count = 0
	lds de, 0		; DE = index = 0
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
HDAE5000_UI_Main_Handler:	; 0x28B3EA (8731 bytes)
; LUIH: 0x28B3EA (8731 bytes)

	push xiz
	ld	xiz, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x02c4)
	call	(xix)
	ld (xhl + 0x16), xiz                    ; ld (XHL+0x16),XIZ
	pop xiz                                 ; pop XIZ
	ret

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
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xix, (xhl + 0x00dc)
	call	(xix)
	jr t, .LUIH_b48d                       ; [68 58] jr T,0x28b48d
.LUIH_b435:
	lds32	xhl, 1
	jr t, .LUIH_b48d                       ; [68 54] jr T,0x28b48d
.LUIH_b439:
	ld	xwa, xiz
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	lda_24 xwa, 0x2e3058
	ld	xbc, xwa
	ld	xwa, xiz
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000f
	call	(xhl)
	lds32	xhl, 0
	jr t, .LUIH_b48d                       ; [68 1c] jr T,0x28b48d
.LUIH_b471:
	ld	xwa, xde
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0104)
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	lds32	xhl, 0
.LUIH_b48d:
	pop xiz                                 ; pop XIZ
	ret

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
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xix, (xhl + 0x00dc)
	call	(xix)
	jr t, .LUIH_b525                       ; [68 64] jr T,0x28b525
.LUIH_b4c1:
	lds32	xhl, 1
	jr t, .LUIH_b525                       ; [68 60] jr T,0x28b525
.LUIH_b4c5:
	ld	xwa, xiz
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	lda_24 xwa, 0x2e305e
	ld	xbc, xwa
	ld	xwa, xiz
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000f
	call	(xhl)
	lds32	xhl, 0
	jr t, .LUIH_b525                       ; [68 28] jr T,0x28b525
.LUIH_b4fd:
	ld	xwa, xde
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0104)
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	pushw 0x0001
	lds	wa, 0
	lds	bc, 0
	lds	de, 6
	calr	0xbbb3
	lds32	xhl, 0
.LUIH_b525:
	pop xiz                                 ; pop XIZ
	ret

	cp	xbc, 0x01e000a3
	jr z, .LUIH_b54e                       ; [66 1f] jr Z,0x28b54e
	cp	xbc, 0x01e000a2
	jr z, .LUIH_b548                       ; [66 11] jr Z,0x28b548
	cp	xbc, 0x01e000a1
	jr z, .LUIH_b542                       ; [66 03] jr Z,0x28b542
	lds32	xhl, 0
	ret

.LUIH_b542:
	lda_24 xhl, 0x2e3464
	ret

.LUIH_b548:
	ld	xhl, 0x0000002a
	ret

.LUIH_b54e:
	ld	xhl, 0x0000000f
	ret

	st_dri3b l, 0xFD, 0x2A, 0xFF	; lda XSP,XSP+0xff2a
	push xiz
	st_dri3l xde, 0xFD, 0xCE, 0x00	; ld (XSP+0x00ce),XDE
	st_dri3l xbc, 0xFD, 0xD2, 0x00	; ld (XSP+0x00d2),XBC
	st_dri3l xwa, 0xFD, 0xD6, 0x00	; ld (XSP+0x00d6),XWA
	ld_sril	xwa, (xsp + 0x00d2)
	cp	xwa, 0x01c0000f
	jr z, .LUIH_b5a9                       ; [66 33] jr Z,0x28b5a9
	cp	xwa, 0x01e00089
	jr z, .LUIH_b5a1                       ; [66 23] jr Z,0x28b5a1
	ld_sril	xwa, (xsp + 0x00d6)
	ld_sril	xbc, (xsp + 0x00d2)
	ld_sril	xde, (xsp + 0x00ce)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xix, (xhl + 0x00dc)
	call	(xix)
	jrl t, .LUIH_cd01                      ; [78 60 17] jrl T,0x28cd01
.LUIH_b5a1:
	lda_24 xhl, 0x2e36da
	jrl t, .LUIH_cd01                      ; [78 58 17] jrl T,0x28cd01
.LUIH_b5a9:
	ld_sril	xwa, (xsp + 0x00ce)
	or xwa, xwa                             ; or XWA,XWA
	jr nz, .LUIH_b5fb                      ; [6e 49] jr NZ,0x28b5fb
	ld_sril	xwa, (xsp + 0x00d6)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x0100)
	ld	xbc, 0x01e00089
	lds32	xde, 0
	call	(xix)
	ld	xiz, xhl
	cp	(xiz), 0x00
	jr nz, .LUIH_b600                      ; [6e 2a] jr NZ,0x28b600
	ld_sril	xwa, (xsp + 0x00d6)
	ld_sril	xbc, (xsp + 0x00d2)
	ld_sril	xde, (xsp + 0x00ce)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LUIH_cd01                      ; [78 06 17] jrl T,0x28cd01
.LUIH_b5fb:
	ld_sril	xiz, (xsp + 0x00ce)
.LUIH_b600:
	ldw (xsp + 0x04), 65535
	pushw 0x0008
	pushw 0x002e
	pushw 0x36e6
	ld	xwa, xiz
	push xwa
	call HDAE5000_MemCompare_Block
	add	xsp, 0x0000000a
	cps	hl, 0
	jr nz, .LUIH_b624                      ; [6e 05] jr NZ,0x28b624
	ldw (xsp + 0x04), 1
.LUIH_b624:
	pushw 0x0008
	pushw 0x002e
	pushw 0x36f0
	ld	xwa, xiz
	push xwa
	call HDAE5000_MemCompare_Block
	add	xsp, 0x0000000a
	cps	hl, 0
	jr nz, .LUIH_b643                      ; [6e 05] jr NZ,0x28b643
	ldw (xsp + 0x04), 2
.LUIH_b643:
	pushw 0x0008
	pushw 0x002e
	pushw 0x36fa
	ld	xwa, xiz
	push xwa
	call HDAE5000_MemCompare_Block
	add	xsp, 0x0000000a
	cps	hl, 0
	jr nz, .LUIH_b662                      ; [6e 05] jr NZ,0x28b662
	ldw (xsp + 0x04), 3
.LUIH_b662:
	cpw	(xsp+4), 0x0000
	jr ge, .LUIH_b68e                      ; [69 25] jr GE,0x28b68e
	ld_sril	xwa, (xsp + 0x00d6)
	ld_sril	xbc, (xsp + 0x00d2)
	ld_sril	xde, (xsp + 0x00ce)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LUIH_cd01                      ; [78 73 16] jrl T,0x28cd01
.LUIH_b68e:
	ld_sril	xwa, (xsp + 0x00d6)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x02c4)
	call	(xix)
	ld	wa, (xhl+26)
	dec	1, wa
	cps	wa, 0
	jrl lt, .LUIH_cccd                     ; [71 1f 16] jrl LT,0x28cccd
	cp	wa, 0x0042
	jr le, .LUIH_b6c6                      ; [62 12] jr LE,0x28b6c6
	sub	wa, 0x0084
	cp	wa, 0x0043
	jrl lt, .LUIH_cccd                     ; [71 0e 16] jrl LT,0x28cccd
	cp	wa, 0x004f
	jrl gt, .LUIH_cccd                     ; [7a 07 16] jrl GT,0x28cccd
.LUIH_b6c6:
	add	wa, wa
	lda_24 xix, 0x2e5ae0
	ld_sriw3 wa, 0x07, 0xF0, 0xE0	; ld WA,(XIX+WA)
	lda_24 xix, 0x28b6dc
	jp_dri 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_b6f3                      ; [6e 10] jr NZ,0x28b6f3
	pushw 0x002e
	pushw 0x3704
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b6f3:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_b70a                      ; [6e 10] jr NZ,0x28b70a
	pushw 0x002e
	pushw 0x3734
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b70a:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e cb 15] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3770
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 b8 15] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_b73c                      ; [6e 10] jr NZ,0x28b73c
	pushw 0x002e
	pushw 0x3792
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b73c:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_b753                      ; [6e 10] jr NZ,0x28b753
	pushw 0x002e
	pushw 0x37be
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b753:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 82 15] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x37f6
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 6f 15] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_b785                      ; [6e 10] jr NZ,0x28b785
	pushw 0x002e
	pushw 0x3814
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b785:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_b79c                      ; [6e 10] jr NZ,0x28b79c
	pushw 0x002e
	pushw 0x382a
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b79c:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 39 15] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3840
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 26 15] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_b7ce                      ; [6e 10] jr NZ,0x28b7ce
	pushw 0x002e
	pushw 0x3856
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b7ce:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_b7e5                      ; [6e 10] jr NZ,0x28b7e5
	pushw 0x002e
	pushw 0x3866
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b7e5:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e f0 14] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3876
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 dd 14] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_b817                      ; [6e 10] jr NZ,0x28b817
	pushw 0x002e
	pushw 0x3886
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b817:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_b82e                      ; [6e 10] jr NZ,0x28b82e
	pushw 0x002e
	pushw 0x389c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b82e:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e a7 14] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x38b2
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 94 14] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_b860                      ; [6e 10] jr NZ,0x28b860
	pushw 0x002e
	pushw 0x38c8
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b860:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_b877                      ; [6e 10] jr NZ,0x28b877
	pushw 0x002e
	pushw 0x38dc
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b877:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 5e 14] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x38f0
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 4b 14] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_b8a9                      ; [6e 10] jr NZ,0x28b8a9
	pushw 0x002e
	pushw 0x3904
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b8a9:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_b8c0                      ; [6e 10] jr NZ,0x28b8c0
	pushw 0x002e
	pushw 0x391c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b8c0:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 15 14] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3934
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 02 14] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_b8f2                      ; [6e 10] jr NZ,0x28b8f2
	pushw 0x002e
	pushw 0x394c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b8f2:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_b909                      ; [6e 10] jr NZ,0x28b909
	pushw 0x002e
	pushw 0x395c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b909:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e cc 13] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x396c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 b9 13] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_b93b                      ; [6e 10] jr NZ,0x28b93b
	pushw 0x002e
	pushw 0x397c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b93b:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_b952                      ; [6e 10] jr NZ,0x28b952
	pushw 0x002e
	pushw 0x398c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b952:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 83 13] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x399c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 70 13] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_b984                      ; [6e 10] jr NZ,0x28b984
	pushw 0x002e
	pushw 0x39ac
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b984:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_b99b                      ; [6e 10] jr NZ,0x28b99b
	pushw 0x002e
	pushw 0x39ba
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b99b:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 3a 13] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x39c8
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 27 13] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_b9cd                      ; [6e 10] jr NZ,0x28b9cd
	pushw 0x002e
	pushw 0x39d6
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b9cd:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_b9e4                      ; [6e 10] jr NZ,0x28b9e4
	pushw 0x002e
	pushw 0x39e2
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_b9e4:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e f1 12] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x39ee
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 de 12] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_ba16                      ; [6e 10] jr NZ,0x28ba16
	pushw 0x002e
	pushw 0x39fa
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_ba16:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_ba2d                      ; [6e 10] jr NZ,0x28ba2d
	pushw 0x002e
	pushw 0x3a0a
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_ba2d:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e a8 12] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3a1a
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 95 12] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_ba5f                      ; [6e 10] jr NZ,0x28ba5f
	pushw 0x002e
	pushw 0x3a2a
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_ba5f:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_ba76                      ; [6e 10] jr NZ,0x28ba76
	pushw 0x002e
	pushw 0x3a40
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_ba76:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 5f 12] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3a56
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 4c 12] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_baa8                      ; [6e 10] jr NZ,0x28baa8
	pushw 0x002e
	pushw 0x3a6c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_baa8:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_babf                      ; [6e 10] jr NZ,0x28babf
	pushw 0x002e
	pushw 0x3a8c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_babf:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 16 12] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3aac
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 03 12] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_baf1                      ; [6e 10] jr NZ,0x28baf1
	pushw 0x002e
	pushw 0x3acc
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_baf1:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bb08                      ; [6e 10] jr NZ,0x28bb08
	pushw 0x002e
	pushw 0x3aec
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bb08:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e cd 11] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3b0c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 ba 11] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bb3a                      ; [6e 10] jr NZ,0x28bb3a
	pushw 0x002e
	pushw 0x3b2c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bb3a:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bb51                      ; [6e 10] jr NZ,0x28bb51
	pushw 0x002e
	pushw 0x3b78
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bb51:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 84 11] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3bc8
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 71 11] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bb83                      ; [6e 10] jr NZ,0x28bb83
	pushw 0x002e
	pushw 0x3c18
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bb83:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bb9a                      ; [6e 10] jr NZ,0x28bb9a
	pushw 0x002e
	pushw 0x3c3c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bb9a:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 3b 11] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3c60
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 28 11] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bbcc                      ; [6e 10] jr NZ,0x28bbcc
	pushw 0x002e
	pushw 0x3c84
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bbcc:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bbe3                      ; [6e 10] jr NZ,0x28bbe3
	pushw 0x002e
	pushw 0x3cae
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bbe3:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e f2 10] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3cda
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 df 10] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bc15                      ; [6e 10] jr NZ,0x28bc15
	pushw 0x002e
	pushw 0x3d04
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bc15:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bc2c                      ; [6e 10] jr NZ,0x28bc2c
	pushw 0x002e
	pushw 0x3d30
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bc2c:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e a9 10] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3d5a
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 96 10] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bc5e                      ; [6e 10] jr NZ,0x28bc5e
	pushw 0x002e
	pushw 0x3d86
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bc5e:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bc75                      ; [6e 10] jr NZ,0x28bc75
	pushw 0x002e
	pushw 0x3d9a
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bc75:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 60 10] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3dae
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 4d 10] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bca7                      ; [6e 10] jr NZ,0x28bca7
	pushw 0x002e
	pushw 0x3dc2
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bca7:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bcbe                      ; [6e 10] jr NZ,0x28bcbe
	pushw 0x002e
	pushw 0x3dfa
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bcbe:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 17 10] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3e46
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 04 10] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bcf0                      ; [6e 10] jr NZ,0x28bcf0
	pushw 0x002e
	pushw 0x3e8c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bcf0:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bd07                      ; [6e 10] jr NZ,0x28bd07
	pushw 0x002e
	pushw 0x3ebc
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bd07:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e ce 0f] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3efc
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 bb 0f] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bd39                      ; [6e 10] jr NZ,0x28bd39
	pushw 0x002e
	pushw 0x3f2c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bd39:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bd50                      ; [6e 10] jr NZ,0x28bd50
	pushw 0x002e
	pushw 0x3f5a
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bd50:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 85 0f] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x3f94
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 72 0f] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bd82                      ; [6e 10] jr NZ,0x28bd82
	pushw 0x002e
	pushw 0x3fba
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bd82:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bd99                      ; [6e 10] jr NZ,0x28bd99
	pushw 0x002e
	pushw 0x3fe2
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bd99:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 3c 0f] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4014
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 29 0f] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bdcb                      ; [6e 10] jr NZ,0x28bdcb
	pushw 0x002e
	pushw 0x4050
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bdcb:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bde2                      ; [6e 10] jr NZ,0x28bde2
	pushw 0x002e
	pushw 0x40ae
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bde2:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e f3 0e] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x411a
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 e0 0e] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_be14                      ; [6e 10] jr NZ,0x28be14
	pushw 0x002e
	pushw 0x4170
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_be14:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_be2b                      ; [6e 10] jr NZ,0x28be2b
	pushw 0x002e
	pushw 0x41ac
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_be2b:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e aa 0e] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x41ee
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 97 0e] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_be5d                      ; [6e 10] jr NZ,0x28be5d
	pushw 0x002e
	pushw 0x4230
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_be5d:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_be74                      ; [6e 10] jr NZ,0x28be74
	pushw 0x002e
	pushw 0x4264
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_be74:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 61 0e] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x42a8
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 4e 0e] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bea6                      ; [6e 10] jr NZ,0x28bea6
	pushw 0x002e
	pushw 0x42ea
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bea6:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bebd                      ; [6e 10] jr NZ,0x28bebd
	pushw 0x002e
	pushw 0x4320
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bebd:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 18 0e] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4362
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 05 0e] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_beef                      ; [6e 10] jr NZ,0x28beef
	pushw 0x002e
	pushw 0x439a
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_beef:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bf06                      ; [6e 10] jr NZ,0x28bf06
	pushw 0x002e
	pushw 0x43bc
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bf06:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e cf 0d] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x43e2
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 bc 0d] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bf38                      ; [6e 10] jr NZ,0x28bf38
	pushw 0x002e
	pushw 0x4412
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bf38:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bf4f                      ; [6e 10] jr NZ,0x28bf4f
	pushw 0x002e
	pushw 0x443c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bf4f:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 86 0d] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4472
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 73 0d] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bf81                      ; [6e 10] jr NZ,0x28bf81
	pushw 0x002e
	pushw 0x449c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bf81:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bf98                      ; [6e 10] jr NZ,0x28bf98
	pushw 0x002e
	pushw 0x44bc
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bf98:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 3d 0d] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x44e2
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 2a 0d] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_bfca                      ; [6e 10] jr NZ,0x28bfca
	pushw 0x002e
	pushw 0x4504
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bfca:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_bfe1                      ; [6e 10] jr NZ,0x28bfe1
	pushw 0x002e
	pushw 0x451a
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_bfe1:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e f4 0c] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4548
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 e1 0c] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c013                      ; [6e 10] jr NZ,0x28c013
	pushw 0x002e
	pushw 0x4576
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c013:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c02a                      ; [6e 10] jr NZ,0x28c02a
	pushw 0x002e
	pushw 0x458e
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c02a:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e ab 0c] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x45c0
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 98 0c] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c05c                      ; [6e 10] jr NZ,0x28c05c
	pushw 0x002e
	pushw 0x45e4
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c05c:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c073                      ; [6e 10] jr NZ,0x28c073
	pushw 0x002e
	pushw 0x45fa
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c073:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 62 0c] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4630
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 4f 0c] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c0a5                      ; [6e 10] jr NZ,0x28c0a5
	pushw 0x002e
	pushw 0x4658
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c0a5:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c0bc                      ; [6e 10] jr NZ,0x28c0bc
	pushw 0x002e
	pushw 0x4672
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c0bc:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 19 0c] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x46a6
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 06 0c] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c0ee                      ; [6e 10] jr NZ,0x28c0ee
	pushw 0x002e
	pushw 0x46ce
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c0ee:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c105                      ; [6e 10] jr NZ,0x28c105
	pushw 0x002e
	pushw 0x46e8
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c105:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e d0 0b] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x471c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 bd 0b] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c137                      ; [6e 10] jr NZ,0x28c137
	pushw 0x002e
	pushw 0x474a
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c137:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c14e                      ; [6e 10] jr NZ,0x28c14e
	pushw 0x002e
	pushw 0x4764
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c14e:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 87 0b] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4798
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 74 0b] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c180                      ; [6e 10] jr NZ,0x28c180
	pushw 0x002e
	pushw 0x47c2
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c180:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c197                      ; [6e 10] jr NZ,0x28c197
	pushw 0x002e
	pushw 0x47dc
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c197:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 3e 0b] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4810
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 2b 0b] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c1c9                      ; [6e 10] jr NZ,0x28c1c9
	pushw 0x002e
	pushw 0x483a
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c1c9:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c1e0                      ; [6e 10] jr NZ,0x28c1e0
	pushw 0x002e
	pushw 0x4864
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c1e0:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e f5 0a] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4892
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 e2 0a] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c212                      ; [6e 10] jr NZ,0x28c212
	pushw 0x002e
	pushw 0x48c4
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c212:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c229                      ; [6e 10] jr NZ,0x28c229
	pushw 0x002e
	pushw 0x490c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c229:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e ac 0a] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4968
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 99 0a] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c25b                      ; [6e 10] jr NZ,0x28c25b
	pushw 0x002e
	pushw 0x49c0
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c25b:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c272                      ; [6e 10] jr NZ,0x28c272
	pushw 0x002e
	pushw 0x4a08
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c272:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 63 0a] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4a64
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 50 0a] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c2a4                      ; [6e 10] jr NZ,0x28c2a4
	pushw 0x002e
	pushw 0x4abc
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c2a4:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c2bb                      ; [6e 10] jr NZ,0x28c2bb
	pushw 0x002e
	pushw 0x4b20
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c2bb:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 1a 0a] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4b82
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 07 0a] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c2ed                      ; [6e 10] jr NZ,0x28c2ed
	pushw 0x002e
	pushw 0x4bd8
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c2ed:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c304                      ; [6e 10] jr NZ,0x28c304
	pushw 0x002e
	pushw 0x4c2c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c304:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e d1 09] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4c8e
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 be 09] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c336                      ; [6e 10] jr NZ,0x28c336
	pushw 0x002e
	pushw 0x4cd4
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c336:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c34d                      ; [6e 10] jr NZ,0x28c34d
	pushw 0x002e
	pushw 0x4d12
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c34d:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 88 09] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4d5e
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 75 09] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c37f                      ; [6e 10] jr NZ,0x28c37f
	pushw 0x002e
	pushw 0x4d8e
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c37f:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c396                      ; [6e 10] jr NZ,0x28c396
	pushw 0x002e
	pushw 0x4dc4
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c396:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 3f 09] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4e06
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 2c 09] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c3c8                      ; [6e 10] jr NZ,0x28c3c8
	pushw 0x002e
	pushw 0x4e4c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c3c8:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c3df                      ; [6e 10] jr NZ,0x28c3df
	pushw 0x002e
	pushw 0x4e96
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c3df:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e f6 08] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4eee
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 e3 08] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c411                      ; [6e 10] jr NZ,0x28c411
	pushw 0x002e
	pushw 0x4f18
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c411:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c428                      ; [6e 10] jr NZ,0x28c428
	pushw 0x002e
	pushw 0x4f38
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c428:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e ad 08] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4f72
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 9a 08] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c45a                      ; [6e 10] jr NZ,0x28c45a
	pushw 0x002e
	pushw 0x4f96
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c45a:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c471                      ; [6e 10] jr NZ,0x28c471
	pushw 0x002e
	pushw 0x4fb8
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c471:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 64 08] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x4fe0
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 51 08] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c4a3                      ; [6e 10] jr NZ,0x28c4a3
	pushw 0x002e
	pushw 0x4ffe
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c4a3:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c4ba                      ; [6e 10] jr NZ,0x28c4ba
	pushw 0x002e
	pushw 0x500e
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c4ba:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 1b 08] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x5020
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 08 08] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c4ec                      ; [6e 10] jr NZ,0x28c4ec
	pushw 0x002e
	pushw 0x5030
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c4ec:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c503                      ; [6e 10] jr NZ,0x28c503
	pushw 0x002e
	pushw 0x5040
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c503:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e d2 07] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x5050
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 bf 07] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c535                      ; [6e 10] jr NZ,0x28c535
	pushw 0x002e
	pushw 0x5060
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c535:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c54c                      ; [6e 10] jr NZ,0x28c54c
	pushw 0x002e
	pushw 0x508c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c54c:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 89 07] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x50b4
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 76 07] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c57e                      ; [6e 10] jr NZ,0x28c57e
	pushw 0x002e
	pushw 0x50f2
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c57e:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c595                      ; [6e 10] jr NZ,0x28c595
	pushw 0x002e
	pushw 0x5144
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c595:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 40 07] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x51a8
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 2d 07] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c5c7                      ; [6e 10] jr NZ,0x28c5c7
	pushw 0x002e
	pushw 0x520e
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c5c7:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c5de                      ; [6e 10] jr NZ,0x28c5de
	pushw 0x002e
	pushw 0x521c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c5de:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e f7 06] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x522c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 e4 06] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c610                      ; [6e 10] jr NZ,0x28c610
	pushw 0x002e
	pushw 0x5240
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c610:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c627                      ; [6e 10] jr NZ,0x28c627
	pushw 0x002e
	pushw 0x525e
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c627:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e ae 06] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x527e
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 9b 06] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c659                      ; [6e 10] jr NZ,0x28c659
	pushw 0x002e
	pushw 0x529a
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c659:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c670                      ; [6e 10] jr NZ,0x28c670
	pushw 0x002e
	pushw 0x52ec
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c670:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 65 06] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x5350
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 52 06] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c6a2                      ; [6e 10] jr NZ,0x28c6a2
	pushw 0x002e
	pushw 0x53ae
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c6a2:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c6b9                      ; [6e 10] jr NZ,0x28c6b9
	pushw 0x002e
	pushw 0x53ca
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c6b9:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 1c 06] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x53e8
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 09 06] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c6eb                      ; [6e 10] jr NZ,0x28c6eb
	pushw 0x002e
	pushw 0x5406
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c6eb:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c702                      ; [6e 10] jr NZ,0x28c702
	pushw 0x002e
	pushw 0x5456
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c702:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e d3 05] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x54a6
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 c0 05] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c734                      ; [6e 10] jr NZ,0x28c734
	pushw 0x002e
	pushw 0x54f6
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c734:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c74b                      ; [6e 10] jr NZ,0x28c74b
	pushw 0x002e
	pushw 0x5542
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c74b:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 8a 05] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x5592
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 77 05] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c77d                      ; [6e 10] jr NZ,0x28c77d
	pushw 0x002e
	pushw 0x55de
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c77d:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c794                      ; [6e 10] jr NZ,0x28c794
	pushw 0x002e
	pushw 0x55fa
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c794:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 41 05] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x5616
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 2e 05] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c7c6                      ; [6e 10] jr NZ,0x28c7c6
	pushw 0x002e
	pushw 0x5632
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c7c6:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c7dd                      ; [6e 10] jr NZ,0x28c7dd
	pushw 0x002e
	pushw 0x564e
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c7dd:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e f8 04] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x566c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 e5 04] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c80f                      ; [6e 10] jr NZ,0x28c80f
	pushw 0x002e
	pushw 0x568e
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c80f:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c826                      ; [6e 10] jr NZ,0x28c826
	pushw 0x002e
	pushw 0x56b4
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c826:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e af 04] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x56e8
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 9c 04] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c858                      ; [6e 10] jr NZ,0x28c858
	pushw 0x002e
	pushw 0x5718
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c858:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c86f                      ; [6e 10] jr NZ,0x28c86f
	pushw 0x002e
	pushw 0x572c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c86f:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 66 04] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x5742
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 53 04] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c8a1                      ; [6e 10] jr NZ,0x28c8a1
	pushw 0x002e
	pushw 0x5758
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c8a1:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c8b8                      ; [6e 10] jr NZ,0x28c8b8
	pushw 0x002e
	pushw 0x576a
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c8b8:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 1d 04] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x577c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 0a 04] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c8ea                      ; [6e 10] jr NZ,0x28c8ea
	pushw 0x002e
	pushw 0x578e
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c8ea:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c901                      ; [6e 10] jr NZ,0x28c901
	pushw 0x002e
	pushw 0x579a
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c901:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e d4 03] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x57a8
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 c1 03] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c933                      ; [6e 10] jr NZ,0x28c933
	pushw 0x002e
	pushw 0x57b6
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c933:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c94a                      ; [6e 10] jr NZ,0x28c94a
	pushw 0x002e
	pushw 0x57c4
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c94a:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 8b 03] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x57d2
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 78 03] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c97c                      ; [6e 10] jr NZ,0x28c97c
	pushw 0x002e
	pushw 0x57e2
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c97c:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c993                      ; [6e 10] jr NZ,0x28c993
	pushw 0x002e
	pushw 0x581e
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c993:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 42 03] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x585e
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 2f 03] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_c9c5                      ; [6e 10] jr NZ,0x28c9c5
	pushw 0x002e
	pushw 0x58a0
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c9c5:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_c9dc                      ; [6e 10] jr NZ,0x28c9dc
	pushw 0x002e
	pushw 0x58a4
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_c9dc:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e f9 02] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x58a8
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 e6 02] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_ca0e                      ; [6e 10] jr NZ,0x28ca0e
	pushw 0x002e
	pushw 0x58ac
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_ca0e:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_ca25                      ; [6e 10] jr NZ,0x28ca25
	pushw 0x002e
	pushw 0x58b0
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_ca25:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e b0 02] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x58b6
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 9d 02] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_ca57                      ; [6e 10] jr NZ,0x28ca57
	pushw 0x002e
	pushw 0x58ba
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_ca57:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_ca6e                      ; [6e 10] jr NZ,0x28ca6e
	pushw 0x002e
	pushw 0x58be
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_ca6e:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 67 02] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x58c2
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 54 02] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_caa0                      ; [6e 10] jr NZ,0x28caa0
	pushw 0x002e
	pushw 0x58c6
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_caa0:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_cab7                      ; [6e 10] jr NZ,0x28cab7
	pushw 0x002e
	pushw 0x58ce
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cab7:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 1e 02] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x58d6
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 0b 02] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_cae9                      ; [6e 10] jr NZ,0x28cae9
	pushw 0x002e
	pushw 0x58de
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cae9:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_cb00                      ; [6e 10] jr NZ,0x28cb00
	pushw 0x002e
	pushw 0x58f0
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cb00:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e d5 01] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x5902
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 c2 01] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_cb32                      ; [6e 10] jr NZ,0x28cb32
	pushw 0x002e
	pushw 0x5916
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cb32:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_cb49                      ; [6e 10] jr NZ,0x28cb49
	pushw 0x002e
	pushw 0x5924
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cb49:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 8c 01] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x5932
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 79 01] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_cb7b                      ; [6e 10] jr NZ,0x28cb7b
	pushw 0x002e
	pushw 0x5940
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cb7b:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_cb92                      ; [6e 10] jr NZ,0x28cb92
	pushw 0x002e
	pushw 0x594e
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cb92:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e 43 01] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x595c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 30 01] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_cbc4                      ; [6e 10] jr NZ,0x28cbc4
	pushw 0x002e
	pushw 0x596a
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cbc4:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_cbdb                      ; [6e 10] jr NZ,0x28cbdb
	pushw 0x002e
	pushw 0x597a
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cbdb:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e fa 00] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x598a
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 e7 00] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_cc0d                      ; [6e 10] jr NZ,0x28cc0d
	pushw 0x002e
	pushw 0x599a
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cc0d:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_cc24                      ; [6e 10] jr NZ,0x28cc24
	pushw 0x002e
	pushw 0x59a6
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cc24:
	cpw	(xsp+4), 0x0003
	jrl nz, .LUIH_ccdd                     ; [7e b1 00] jrl NZ,0x28ccdd
	pushw 0x002e
	pushw 0x59b0
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jrl t, .LUIH_ccdd                      ; [78 9e 00] jrl T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_cc56                      ; [6e 10] jr NZ,0x28cc56
	pushw 0x002e
	pushw 0x59bc
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cc56:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_cc6d                      ; [6e 10] jr NZ,0x28cc6d
	pushw 0x002e
	pushw 0x59e6
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cc6d:
	cpw	(xsp+4), 0x0003
	jr nz, .LUIH_ccdd                      ; [6e 69] jr NZ,0x28ccdd
	pushw 0x002e
	pushw 0x5a2c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jr t, .LUIH_ccdd                       ; [68 57] jr T,0x28ccdd
	cpw	(xsp+4), 0x0001
	jr nz, .LUIH_cc9d                      ; [6e 10] jr NZ,0x28cc9d
	pushw 0x002e
	pushw 0x5a5c
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_cc9d:
	cpw	(xsp+4), 0x0002
	jr nz, .LUIH_ccb4                      ; [6e 10] jr NZ,0x28ccb4
	pushw 0x002e
	pushw 0x5a88
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_ccb4:
	cpw	(xsp+4), 0x0003
	jr nz, .LUIH_ccdd                      ; [6e 22] jr NZ,0x28ccdd
	pushw 0x002e
	pushw 0x5ab0
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	jr t, .LUIH_ccdd                       ; [68 10] jr T,0x28ccdd
.LUIH_cccd:
	pushw 0x002e
	pushw 0x5ad4
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
.LUIH_ccdd:
	lda	xwa, (xsp+6)
	ld	xbc, xwa
	ld_sril	xwa, (xsp + 0x00d6)
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000f
	call	(xhl)
	lds32	xhl, 0
.LUIH_cd01:
	pop xiz                                 ; pop XIZ
	st_dri3b l, 0xFD, 0xD6, 0x00	; lda XSP,XSP+0x00d6
	ret

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
	jr z, .LUIH_cd6f                       ; [66 2c] jr Z,0x28cd6f
	sub	xwa, 0x01ca0003
	cp	xwa, 0x00000000
	jrl lt, .LUIH_d311                     ; [71 bf 05] jrl LT,0x28d311
	cp	xwa, 0x00000006
	jrl gt, .LUIH_d311                     ; [7a b6 05] jrl GT,0x28d311
	add	xwa, xwa
	add	xwa, 0x002e5bd2
	ld	wa, (xwa)
	lda_24 xix, 0x28cd6f
	jp_dri 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
.LUIH_cd6f:
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld xbc, (xsp + 0x0a)                    ; ld XBC,(XSP+0x0a)
	ld xde, (xsp + 0x06)                    ; ld XDE,(XSP+0x06)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01ca0008
	lds32	xde, 0
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LUIH_d600                      ; [78 57 08] jrl T,0x28d600
.LUIH_cda9:
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld xbc, (xsp + 0x0a)                    ; ld XBC,(XSP+0x0a)
	ld xde, (xsp + 0x06)                    ; ld XDE,(XSP+0x06)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01ca0003
	lds32	xde, 0
	call	(xhl)
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01ca0007
	lds32	xde, 0
	call	(xhl)
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01ca0008
	lds32	xde, 1
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LUIH_d600                      ; [78 e7 07] jrl T,0x28d600
	cpi8_24	0x23A19A, 0
	jrl nz, .LUIH_cf93                     ; [7e 71 01] jrl NZ,0x28cf93
	sti8_24	0x23A19A, 1
	lda_24 xwa, 0x22a08c
	ld	xbc, xwa
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e0a)
	ld_sril	xhl, (xde + 0x02d4)
	call	(xhl)
	incdi16_24	2, 0x22A08C
	incdi16_24	4, 0x22A08E
	decdi16_24	1, 0x22A090
	decdi16_24	2, 0x22A092
	ld16_24	wa, 0x22A08C
	inc	2, wa
	ld	(0x22a094), wa
	ld16_24	wa, 0x22A08E
	dec	2, wa
	ld	(0x22a096), wa
	ld16_24	wa, 0x22A090
	dec	2, wa
	ld	(0x22a098), wa
	ld16_24	wa, 0x22A096
	add	wa, 0x000d
	ld	(0x22a09a), wa
	ld16_24	wa, 0x22A08C
	inc	6, wa
	ld	(0x22a09c), wa
	ld16_24	wa, 0x22A08E
	inc	2, wa
	ld	(0x22a09e), wa
	lda_24 xwa, 0x22a0a0
	ld	xbc, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x02d4)
	ld	xwa, 0x007f0301
	call	(xhl)
	ld16_24	wa, 0x22A0A0
	add	wa, 0x0014
	ld	(0x22a0a8), wa
	ld16_24	wa, 0x22A0A2
	inc	5, wa
	ld	(0x22a0aa), wa
	lda_24 xwa, 0x22a0ac
	ld	xbc, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x02d4)
	ld	xwa, 0x007f0302
	call	(xhl)
	ld16_24	wa, 0x22A0AC
	add	wa, 0x0014
	ld	(0x22a0b4), wa
	ld16_24	wa, 0x22A0AE
	inc	5, wa
	ld	(0x22a0b6), wa
	sti16_24	0x2307B8, 0
	lds	hl, 0
	cp	hl, 0x0027
	jr ge, .LUIH_cf4a                      ; [69 2c] jr GE,0x28cf4a
.LUIH_cf1e:
	ld	wa, hl
	sla	wa, 0x02
	ld	bc, wa
	inc	4, bc
	ld16_24	wa, 0x22A08C
	add	wa, 0x009c
	ld	de, wa
	sub	de, bc
	ld	wa, hl
	add	wa, wa
	lda_24 xbc, 0x2307ba
	st_dri3w de, 0x07, 0xE4, 0xE0	; ld (XBC+WA),DE
	inc	1, hl
	cp	hl, 0x0027
	jr lt, .LUIH_cf1e                      ; [61 d4] jr LT,0x28cf1e
.LUIH_cf4a:
	lds	hl, 0
	cp	hl, 0x0027
	jr ge, .LUIH_cf6d                      ; [69 1b] jr GE,0x28cf6d
.LUIH_cf52:
	ld	wa, hl
	add	wa, wa
	lda_24 xbc, 0x23080e
	ld	de, hl
	sla	de, 0x03
	st_dri3w de, 0x07, 0xE4, 0xE0	; ld (XBC+WA),DE
	inc	1, hl
	cp	hl, 0x0027
	jr lt, .LUIH_cf52                      ; [61 e5] jr LT,0x28cf52
.LUIH_cf6d:
	lds	hl, 0
	cps	hl, 6
	jr ge, .LUIH_cf93                      ; [69 20] jr GE,0x28cf93
.LUIH_cf73:
	ld	wa, hl
	muls	wa, 0x0012
	addda16_24	wa, 0x22A08E
	add	a, 0x0f
	ld	c, a
	lda_24 xwa, 0x230808
	lda_dri3 xhl, 0x07, 0xE0, 0xEC	; ld (XWA+HL),C
	inc	1, hl
	cps	hl, 6
	jr lt, .LUIH_cf73                      ; [61 e0] jr LT,0x28cf73
.LUIH_cf93:
	lds32	xhl, 0
	jrl t, .LUIH_d600                      ; [78 68 06] jrl T,0x28d600
	ld xwa, (xsp + 0x06)                    ; ld XWA,(XSP+0x06)
	cp	xwa, 0x00000001
	jr z, .LUIH_d005                       ; [66 62] jr Z,0x28d005
	or xwa, xwa                             ; or XWA,XWA
	jr z, .LUIH_cfac                       ; [66 05] jr Z,0x28cfac
	lds32	xhl, 0
	jrl t, .LUIH_d600                      ; [78 54 06] jrl T,0x28d600
.LUIH_cfac:
	cpdi16_24	0x2307B2, 0
	jr z, .LUIH_d000                       ; [66 4b] jr Z,0x28d000
	sti16_24	0x2307B2, 0
	sti16_24	0x2307B4, 1
	calr	0x0ab5
	lds32	xwa, 0
	calr	0x0c2d
	sti16_24	0x22A0B8, 0
	lds	wa, 0
	lds	bc, 0
	calr	0x0e53
	ld	(0x230870), hl
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000d
	lds32	xde, 0
	call	(xhl)
	sti16_24	0x2307B4, 0
.LUIH_d000:
	lds32	xhl, 0
	jrl t, .LUIH_d600                      ; [78 fb 05] jrl T,0x28d600
.LUIH_d005:
	calr	0x0a73
	lds32	xwa, 0
	calr	0x0beb
	sti16_24	0x22A0B8, 0
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LUIH_d600                      ; [78 cc 05] jrl T,0x28d600
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x02c4)
	call	(xix)
	ld	(0x22a088), xhl
	lds	iz, 0
	cps	iz, 6
	jrl nc, .LUIH_d1a2                     ; [7f 4e 01] jrl NC,0x28d1a2
.LUIH_d054:
	ld	wa, iz
	extz xwa
	ld	xbc, xwa
	sll	xbc, 0x02
	add	xbc, xwa
	sll	xbc, 0x03
	ld	xwa, 0x0023a0aa
	add	xwa, xbc
	push xwa
	call HDAE5000_Display_Buffer_Validate
	inc 4, xsp                              ; inc 4,XSP
	ld	wa, iz
	extz xwa
	add	xwa, 0x00000010
	ld	xbc, 0x002304d8
	add	xbc, xwa
	ld_dst8_ri xbc, l		; ld (XBC),L
	ld16_24	wa, 0x230806
	ld (xsp + 0x02), wa                     ; ld (XSP+0x02),WA
	ld	wa, iz
	extz xwa
	ld	xbc, 0x00230808
	add	xbc, xwa
	ld	a, (xbc)
	extz wa                                 ; extz WA
	ld (xsp + 0x04), wa                     ; ld (XSP+0x04),WA
	lda_24 xhl, 0x22a08c
	lda	xbc, (xsp+2)
	lda_24 xwa, 0x2e5b80
	ld	xde, xwa
	ld	xwa, (0x22a088)
	ld xwa, (xwa + 0x20)                    ; ld XWA,(XWA+0x20)
	push xwa
	ld8_24	a, 0x230880
	extz wa                                 ; extz WA
	pushw wa                                ; push WA
	ld	xwa, (0x22a088)
	pushm	(xwa+22)
	ld	xwa, xhl
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00c4)
	call	(xhl)
	ld	wa, iz
	extz xwa
	add	xwa, 0x00000010
	ld	xbc, 0x002304d8
	add	xbc, xwa
	ld	a, (xbc)
	extz wa                                 ; extz WA
	add	wa, wa
	lda_24 xbc, 0x2307b8
	ld_sriw3 wa, 0x07, 0xE4, 0xE0	; ld WA,(XBC+WA)
	ld (xsp + 0x02), wa                     ; ld (XSP+0x02),WA
	ld8_24	a, 0x2304EE
	extz wa                                 ; extz WA
	cp	wa, iz
	jr ule, .LUIH_d152                     ; [63 4b] jr ULE,0x28d152
	lda_24 xhl, 0x22a08c
	lda	xbc, (xsp+2)
	ld	wa, iz
	extz xwa
	ld	xix, xwa
	sll	xix, 0x02
	add	xix, xwa
	sll	xix, 0x03
	ld	xde, 0x0023a0aa
	add	xde, xix
	ld	xwa, (0x22a088)
	ld xwa, (xwa + 0x20)                    ; ld XWA,(XWA+0x20)
	push xwa
	ld8_24	a, 0x23087E
	extz wa                                 ; extz WA
	pushw wa                                ; push WA
	ld	xwa, (0x22a088)
	pushm	(xwa+22)
	ld	xwa, xhl
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00c4)
	call	(xhl)
	jr t, .LUIH_d19b                       ; [68 49] jr T,0x28d19b
.LUIH_d152:
	lda_24 xhl, 0x22a08c
	lda	xbc, (xsp+2)
	ld	wa, iz
	extz xwa
	ld	xix, xwa
	sll	xix, 0x02
	add	xix, xwa
	sll	xix, 0x03
	ld	xde, 0x0023a0aa
	add	xde, xix
	ld	xwa, (0x22a088)
	ld xwa, (xwa + 0x20)                    ; ld XWA,(XWA+0x20)
	push xwa
	ld8_24	a, 0x230880
	extz wa                                 ; extz WA
	pushw wa                                ; push WA
	ld	xwa, (0x22a088)
	pushm	(xwa+22)
	ld	xwa, xhl
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00c4)
	call	(xhl)
.LUIH_d19b:
	inc	1, iz
	cps	iz, 6
	jrl c, .LUIH_d054                      ; [77 b2 fe] jrl C,0x28d054
.LUIH_d1a2:
	lda_24 xwa, 0x22a094
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x00a8)
	ldw	bc, 0x00f9
	call	(xhl)
	lda_24 xhl, 0x22a08c
	lda_24 xbc, 0x22a09c
	lda_24 xde, 0x2306b6
	ld	xwa, (0x22a088)
	ld xwa, (xwa + 0x28)                    ; ld XWA,(XWA+0x28)
	push xwa
	ld	xwa, (0x22a088)
	pushm	(xwa+44)
	ld	xwa, (0x22a088)
	pushm	(xwa+22)
	ld	xwa, xhl
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00c4)
	call	(xhl)
	ld xwa, (xsp + 0x06)                    ; ld XWA,(XSP+0x06)
	cp	xwa, 0x00000001
	jrl nz, .LUIH_d2a5                     ; [7e a3 00] jrl NZ,0x28d2a5
	lda_24 xwa, 0x230736
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f02f5
	ld	xbc, 0x01c0000f
	call	(xhl)
	lda_24 xwa, 0x230768
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f02f3
	ld	xbc, 0x01c0000f
	call	(xhl)
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01ca0009
	lds32	xde, 4
	call	(xhl)
	lda_24 xwa, 0x2e5baa
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f02f6
	ld	xbc, 0x01c0000f
	call	(xhl)
	lda_24 xwa, 0x2e5bb0
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f02fd
	ld	xbc, 0x01c0000f
	call	(xhl)
.LUIH_d2a5:
	lds32	xhl, 0
	jrl t, .LUIH_d600                      ; [78 56 03] jrl T,0x28d600
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
	jr nz, .LUIH_d311                      ; [6e 3d] jr NZ,0x28d311
	lda_24 xhl, 0x22a08c
	lda_24 xbc, 0x23087a
	lda_24 xwa, 0x23051e
	ld	xde, xwa
	ld	xwa, (0x22a088)
	ld xwa, (xwa + 0x20)                    ; ld XWA,(XWA+0x20)
	push xwa
	ld8_24	a, 0x23087E
	extz wa                                 ; extz WA
	pushw wa                                ; push WA
	ld	xwa, (0x22a088)
	pushm	(xwa+22)
	ld	xwa, xhl
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00c4)
	call	(xhl)
.LUIH_d311:
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld xbc, (xsp + 0x0a)                    ; ld XBC,(XSP+0x0a)
	ld xde, (xsp + 0x06)                    ; ld XDE,(XSP+0x06)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xix, (xhl + 0x00dc)
	call	(xix)
	jrl t, .LUIH_d600                      ; [78 d2 02] jrl T,0x28d600
.LUIH_d32e:
	lda_24 xhl, 0x22a08c
	lda_24 xbc, 0x23087a
	lda_24 xwa, 0x23051e
	ld	xde, xwa
	ld	xwa, (0x22a088)
	ld xwa, (xwa + 0x20)                    ; ld XWA,(XWA+0x20)
	push xwa
	ld8_24	a, 0x230880
	extz wa                                 ; extz WA
	pushw wa                                ; push WA
	ld	xwa, (0x22a088)
	pushm	(xwa+22)
	ld	xwa, xhl
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00c4)
	call	(xhl)
	jr t, .LUIH_d311                       ; [68 a4] jr T,0x28d311
.LUIH_d36d:
	lda_24 xhl, 0x22a08c
	lda_24 xbc, 0x22a09c
	lda_24 xde, 0x2306b6
	ld	xwa, (0x22a088)
	ld xwa, (xwa + 0x28)                    ; ld XWA,(XWA+0x28)
	push xwa
	ld	xwa, (0x22a088)
	pushm	(xwa+44)
	ld	xwa, (0x22a088)
	pushm	(xwa+22)
	ld	xwa, xhl
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00c4)
	call	(xhl)
	jrl t, .LUIH_d311                      ; [78 66 ff] jrl T,0x28d311
.LUIH_d3ab:
	lda_24 xwa, 0x22a0a0
	ld	xhl, xwa
	lda_24 xwa, 0x22a0a8
	ld	xbc, xwa
	lda_24 xwa, 0x23079a
	ld	xde, xwa
	ld	xwa, (0x22a088)
	ld xwa, (xwa + 0x28)                    ; ld XWA,(XWA+0x28)
	push xwa
	pushw 0x00ff
	pushw 0x0008
	ld	xwa, xhl
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00c4)
	call	(xhl)
	jrl t, .LUIH_d311                      ; [78 2c ff] jrl T,0x28d311
.LUIH_d3e5:
	lda_24 xwa, 0x22a0ac
	ld	xhl, xwa
	lda_24 xwa, 0x22a0b4
	ld	xbc, xwa
	lda_24 xwa, 0x230790
	ld	xde, xwa
	ld	xwa, (0x22a088)
	ld xwa, (xwa + 0x28)                    ; ld XWA,(XWA+0x28)
	push xwa
	pushw 0x00ff
	pushw 0x0008
	ld	xwa, xhl
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00c4)
	call	(xhl)
	jrl t, .LUIH_d311                      ; [78 f2 fe] jrl T,0x28d311
	cpdi16_24	0x2307B4, 0
	jrl nz, .LUIH_d311                     ; [7e e8 fe] jrl NZ,0x28d311
	ld xwa, (xsp + 0x06)                    ; ld XWA,(XSP+0x06)
	lds	bc, 1
	calr	0x02a0
	ld16_24	wa, 0x230874
	cpda16_24	wa, 0x2307B0
	jr c, .LUIH_d470                       ; [67 33] jr C,0x28d470
	ld16_24	wa, 0x2307AE
	ld	(0x2307b0), wa
	incdi16_24	1, 0x230872
	sti16_24	0x230874, 0
	ld	xwa, (0x23a19e)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01ca0005
	lds32	xde, 0
	call	(xhl)
.LUIH_d470:
	incdi16_24	1, 0x230874
	lds32	xwa, 1
	addm32_24	0x230876, xwa
	jrl t, .LUIH_d311                      ; [78 92 fe] jrl T,0x28d311
	incdi16_24	1, 0x2307AC
	ld8_24	a, 0x2307A6
	extz wa                                 ; extz WA
	cpdm16_24	0x2307AC, wa
	jr ule, .LUIH_d4a8                     ; [63 16] jr ULE,0x28d4a8
	ld8_24	a, 0x2307A4
	st8_24	0x2307A6, a
	incdi16_24	1, 0x2307AA
	sti16_24	0x2307AC, 1
.LUIH_d4a8:
	ld16_24	wa, 0x2307AC
	pushw wa                                ; push WA
	ld16_24	wa, 0x2307AA
	pushw wa                                ; push WA
	pushw 0x002e
	pushw 0x5bb6
	lda_24 xwa, 0x23079a
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01ca0009
	lds32	xde, 3
	call	(xhl)
	jrl t, .LUIH_d311                      ; [78 2c fe] jrl T,0x28d311
.LUIH_d4e5:
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x02c4)
	call	(xix)
	ld	(0x22a088), xhl
	ld xwa, (xhl + 0x1c)                    ; ld XWA,(XHL+0x1c)
	ldw	(xwa), 0x0001
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	(0x23a19e), xwa
	sti16_24	0x2307B2, 1
	jrl t, .LUIH_d311                      ; [78 fa fd] jrl T,0x28d311
.LUIH_d517:
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x02c4)
	call	(xix)
	ld	(0x22a088), xhl
	ld xwa, (xhl + 0x1c)                    ; ld XWA,(XHL+0x1c)
	ldw	(xwa), 0x0000
	ld	xwa, 0xffffffff
	ld	(0x23a19e), xwa
	jrl t, .LUIH_d311                      ; [78 cd fd] jrl T,0x28d311
.LUIH_d544:
	ld xde, (xsp + 0x06)                    ; ld XDE,(XSP+0x06)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xix, (xwa + 0x0100)
	ld	xwa, 0x02600024
	ld	xbc, 0x01e00029
	call	(xix)
	ld	xwa, xhl
	cp	xwa, 0x00000007
	jrl ugt, .LUIH_d5fe                    ; [7b 91 00] jrl UGT,0x28d5fe
	add	xwa, xwa
	add	xwa, 0x002e5bc2
	ld	wa, (xwa)
	lda_24 xix, 0x28d581
	jp_dri 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01ca0007
	lds32	xde, 1
	call	(xhl)
	lds	wa, 0
	lds	bc, 0
	calr	0x0889
	ld	(0x230870), hl
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000d
	lds32	xde, 0
	call	(xhl)
	jr t, .LUIH_d5fe                       ; [68 39] jr T,0x28d5fe
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x02c4)
	call	(xix)
	ld	(0x22a088), xhl
	calr	0x0024
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0x007f0304
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
.LUIH_d5fe:
	lds32	xhl, 0
.LUIH_d600:
	popw iz                                 ; pop IZ
	lda	xsp, (xsp+16)
	ret


HDAE5000_Display_Error:	; 0x28D605 (204 bytes)
	; Four sub-routines for error display and device initialization
	; Sub-routine 1: Clear display buffer at 0x22B430, reset state
	pushw 0x5000			; param: size 0x5000
	pushw 0x0000			; param: fill value 0
	lda_24 xwa, 0x22b430                  ; lda XWA, 0x22B430 — buffer base
	push xwa
	call HDAE5000_MemFill		; clear buffer
	inc 0, xsp			; deallocate 8 bytes
	lds32 xwa, 0			; clear XWA
	st32_24 0x2304f2, xwa                 ; ld (0x2304F2), XWA — clear state ptr
	sti8_24 0x23a19c, 0x00                 ; ld (0x23A19C), 0x00 — clear flag
	ret
	; Sub-routine 2: Validate and setup display
.Lde_validate:
	calr HDAE5000_Display_Notify	; validate notification
	or xhl, xhl			; check result
	jr nz, .Lde_err2		; if nonzero, error
	calr HDAE5000_Display_Progress	; show progress
	or xhl, xhl			; check result
	jr nz, .Lde_err1		; if nonzero, error
	sti8_24 0x23a19c, 0x01                 ; ld (0x23A19C), 0x01 — set flag
	lds32 xhl, 0			; return success
	ret
.Lde_err1:
	ld xhl, 0xFFFFFFFF		; return -1
	ret
.Lde_err2:
	ld xhl, 0xFFFFFFFE		; return -2
	ret
	; Sub-routine 3: Check device status via workspace
.Lde_devcheck:
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril xwa, (xwa + 0x0e88)             ; ld XWA, (XWA + 0x0E88)
	ld xix, (xwa + 8)		; XIX = device status callback
	call (xix)			; call device check
	cps l, 3			; check if result == 3
	jr z, .Lde_ready		; if so, device ready
	cps l, 2			; check if result == 2
	jr z, .Lde_ready		; if so, device ready
	ld xhl, 0xFFFFFFFF		; return -1 (not ready)
	ret
	; Sub-routine 4: Full initialization with workspace callbacks
.Lde_ready:
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)             ; ld XWA, (XWA + 0x0E0A)
	ld_sril xhl, (xwa + 0x0538)             ; ld XHL, (XWA + 0x0538)
	call (xhl)
	lda_24 xwa, 0x2e5be4                  ; lda XWA, 0x2E5BE4
	lda_24 xbc, 0x2e5be0                  ; lda XBC, 0x2E5BE0
	ld32_24 xde, 0x23a1a2                 ; ld XDE, (0x23A1A2)
	ld_sril xde, (xde + 0x0e88)             ; ld XDE, (XDE + 0x0E88)
	ld_sril xhl, (xde + 0x00a0)             ; ld XHL, (XDE + 0x00A0)
	call (xhl)
	lda_24 xwa, 0x22b430                  ; lda XWA, 0x22B430
	ld32_24 xbc, 0x23a1a2                 ; ld XBC, (0x23A1A2)
	ld_sril xbc, (xbc + 0x0e88)             ; ld XBC, (XBC + 0x0E88)
	ld_sril xhl, (xbc + 0x00a8)             ; ld XHL, (XBC + 0x00A8)
	ld xbc, 0x00005000		; size = 0x5000
	call (xhl)
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x00ac)             ; ld XHL, (XWA + 0x00AC)
	call (xhl)
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x053c)             ; ld XHL, (XWA + 0x053C)
	call (xhl)
	lds32 xhl, 0			; return success
	ret

HDAE5000_File_Operation:	; 0x28D6D1 (938 bytes)
	; Execute file operation on HD
	; Main loop: process file entries, handle types 0x7E/0x58/5
	; Multiple vtable dispatch calls, File_Delete/Rename sub-calls
	; Input: XWA = param struct ptr, C = display flag

	; --- Prologue: allocate 12 bytes, save XIZ ---
	dec 6, xsp
	push xiz
	ld (xsp + 8), c			; save display flag
	ld xiz, xwa			; XIZ = param struct ptr

	; --- Compute sector count, check limits ---
	ld32_24 xbc, 0x230868                 ; XBC = (0x230868)
	ld xwa, (xiz + 4)		; XWA = param[4]
	call 2733869			; call multiply 0x29B72D
	cpdm32_24 2295908, xhl		; cp (0x230864), XHL
	jrl z, .Lfo_epilogue		; if equal, nothing to do
	st32_24 0x230864, xhl                 ; (0x230864) = XHL
	ld32_24 xwa, 0x230444                 ; XWA = (0x230444)
	cpda32_24 xwa, 2295908		; cp XWA, (0x230864)
	jrl ugt, .Lfo_epilogue		; if limit exceeded, exit
	cpdi16_24 2294836, 0		; cp (0x230434), 0 — abort flag
	jrl nz, .Lfo_epilogue		; if abort, exit
	ldw (xsp + 6), 0		; iteration counter = 0

	; --- Main loop: process entries ---
.Lfo_loop:				; 0x28D70E
	ld16_24 xwa, 0x23086c                 ; WA = (0x23086C) — current offset
	extz xwa
	push xwa			; push offset arg
	ldw wa, 124			; WA = 0x7C
	lds bc, 2
	ldw de, 65534			; DE = 0xFFFE
	calr HDAE5000_File_Rename
	ld xiz, xhl			; XIZ = result
	cpdi16_24 2294836, 1		; check abort flag
	jrl z, .Lfo_epilogue
	cp xiz, 0
	jr le, .Lfo_display		; result <= 0 → display handler

	; --- Result > 0: advance offset, dispatch on type ---
	ld wa, iz
	adddm16_24 2295916, xwa	; (0x23086C) += IZ
	incm 1, (xsp + 6)		; iteration counter++
	ld16_24 xwa, 0x230430                 ; WA = (0x230430) — file type
	cp wa, 126			; type 0x7E?
	jrl z, .Lfo_type_7E
	cp wa, 88			; type 0x58?
	jrl z, .Lfo_type_58
	cps wa, 5			; type 5?
	jrl nz, .Lfo_end_iter		; unknown type → skip

	; --- Type 5: check for newline (0x0D/0x0A) ---
	cpi8_24 0x230636, 0x0d                 ; cp (0x230636), 0x0D
	jr z, .Lfo_type5_newline
	cpi8_24 0x230636, 0x0a                 ; cp (0x230636), 0x0A
	jrl nz, .Lfo_string_handler	; not newline → string handler

.Lfo_type5_newline:			; 0x28D768
	sti16_24 0x2304e4, 0x0000              ; (0x2304E4) = 0 — reset position
	cpi8_24 0x2304ee, 0x02                 ; cp (0x2304EE), 2
	jr nc, .Lfo_file_delete		; if >= 2, do file delete
	incdi8_24 1, 2295022		; (0x2304EE)++
	jrl t, .Lfo_epilogue

	; --- Display handler: show entry info ---
.Lfo_display:				; 0x28D77F
	pushm (xsp + 6)		; push iteration counter
	push_sd24w 0xb6, 0x07, 0x23	; pushw (0x2307B6)
	push xiz			; push result
	pushw 46			; width
	pushw 23538			; format 0x5BF2
	lda_24 xwa, 0x2306b6                  ; &0x2306B6
	push xwa
	call 2730968			; call display 0x29ABD8
	lda xsp, (xsp + 16)		; pop 16 bytes
	; Vtable call: notify display
	ld32_24 xwa, 0x23a19e                 ; XWA = (0x23A19E)
	ld32_24 xbc, 0x23a1a2                 ; XBC = (0x23A1A2)
	ld_sril xbc, (xbc + 0x0e0a)             ; XBC = (XBC + 0x0E0A)
	ld_sril xhl, (xbc + 0x0100)             ; XHL = (XBC + 0x0100)
	ld xbc, 30015497		; XBC = 0x01CA0009
	lds32 xde, 2
	call (xhl)
	jrl t, .Lfo_epilogue

	; --- File delete block ---
.Lfo_file_delete:			; 0x28D7BB
	ld16_24 xbc, 0x230870                 ; BC = (0x230870)
	lds wa, 1
	calr HDAE5000_File_Delete
	ld xiz, xhl
	sti8_24 0x2304f0, 0x00                 ; (0x2304F0) = 0
	cp xiz, 0
	jr le, .Lfo_skip_iz_store1
	st16_24 0x230870, xiz                 ; (0x230870) = IZ
.Lfo_skip_iz_store1:			; 0x28D7DA
	cp (xsp + 8), 1		; check display flag
	jr nz, .Lfo_after_vtable1
	; Vtable call: update display
	ld32_24 xwa, 0x23a19e
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e0a)
	ld_sril xhl, (xbc + 0x0100)
	ld xbc, 30015496		; 0x01CA0008
	lds32 xde, 0
	call (xhl)
.Lfo_after_vtable1:			; 0x28D7FD
	jrl t, .Lfo_epilogue

	; --- String handler: copy and accumulate ---
.Lfo_string_handler:			; 0x28D800
	lda_24 xwa, 0x230636                  ; &0x230636
	push xwa
	call 2731889			; strlen 0x29AF71
	inc 4, xsp			; pop 8 bytes
	ld (xsp + 4), hl		; save strlen result
	cp hl, 39			; cp HL, 0x27
	jrl gt, .Lfo_epilogue		; if > 39, exit
	; memcpy string
	lda_24 xwa, 0x230636                  ; &0x230636
	push xwa
	lda_24 xwa, 0x23051e                  ; &0x23051E — dest buffer
	push xwa
	call 2731845			; memcpy 0x29AF45
	inc 0, xsp			; pop stack frame
	; Check cumulative length
	ld wa, (xsp + 4)		; WA = strlen result
	addda16_24 xwa, 2295012	; WA += (0x2304E4)
	cp wa, 39			; cp WA, 0x27
	jr ule, .Lfo_after_trunc	; if <= 39, no overflow
	; Overflow: reset and try file delete
	sti16_24 0x2304e4, 0x0000              ; (0x2304E4) = 0
	cpi8_24 0x2304ee, 0x02                 ; cp (0x2304EE), 2
	jr nc, .Lfo_file_delete2	; if >= 2, delete
	incdi8_24 1, 2295022		; (0x2304EE)++
	jr t, .Lfo_after_trunc

.Lfo_file_delete2:			; 0x28D84C
	ld16_24 xbc, 0x230870                 ; BC = (0x230870)
	lds wa, 1
	calr HDAE5000_File_Delete
	ld xiz, xhl
	cp xiz, 0
	jr le, .Lfo_skip_iz_store2
	st16_24 0x230870, xiz                 ; (0x230870) = IZ
.Lfo_skip_iz_store2:			; 0x28D865
	cp (xsp + 8), 1		; check display flag
	jr nz, .Lfo_after_trunc
	; Vtable call
	ld32_24 xwa, 0x23a19e
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e0a)
	ld_sril xhl, (xbc + 0x0100)
	ld xbc, 30015496		; 0x01CA0008
	lds32 xde, 0
	call (xhl)

	; --- Compute table entry and store pointers ---
.Lfo_after_trunc:			; 0x28D888
	ld8_24 a, 0x2304ee                    ; A = (0x2304EE)
	extz wa
	add wa, 16			; WA += 0x10
	lda_24 xbc, 0x2304d8                  ; XBC = &0x2304D8
	ld_srib3 a, 0x07, 0xe4, 0xe0	; A = (XBC + WA) — table lookup
	extz wa
	ld bc, wa			; BC = index
	add bc, bc			; BC *= 2
	lda_24 xde, 0x2307b8                  ; XDE = &0x2307B8
	ld16_24 xwa, 0x2304e4                 ; WA = (0x2304E4)
	extz xwa
	add xwa, xwa			; XWA *= 2
	ld xhl, 2295822		; XHL = 0x0023080E
	add xhl, xwa			; XHL += XWA*2
	ld wa, (xhl)			; WA = offset table[position]
	add_sriw_rm wa, 0x07, 0xe8, 0xe4	; WA += (XDE + BC)
	st16_24 0x23087a, xwa                 ; (0x23087A) = WA
	; Compute sector size
	ld8_24 a, 0x2304ee                    ; A = (0x2304EE)
	extz wa
	lda_24 xbc, 0x230808                  ; XBC = &0x230808
	ld_srib3 a, 0x07, 0xe4, 0xe0	; A = (XBC + WA)
	extz wa
	st16_24 0x23087c, xwa                 ; (0x23087C) = WA
	; Update position
	ld wa, (xsp + 4)		; WA = strlen
	adddm16_24 2295012, xwa	; (0x2304E4) += strlen
	sti8_24 0x2304f0, 0x01                 ; (0x2304F0) = 1
	; Optional vtable call
	cp (xsp + 8), 1		; check display flag
	jr nz, .Lfo_after_vtable3
	ld32_24 xwa, 0x23a19e
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e0a)
	ld_sril xhl, (xbc + 0x0100)
	ld xbc, 30015497		; 0x01CA0009
	lds32 xde, 0
	call (xhl)

	; --- Check if at end position ---
.Lfo_after_vtable3:			; 0x28D90D
	ld16_24 xwa, 0x2304e4                 ; WA = (0x2304E4)
	cpda16_24 xwa, 2295920		; cp WA, (0x230870)
	jrl nz, .Lfo_end_iter		; if not at end, continue
	; Check terminator byte
	cpi8_24 0x230882, 0x0d                 ; cp (0x230882), 0x0D
	jr nz, .Lfo_not_cr
	cpi8_24 0x230882, 0x0a                 ; cp (0x230882), 0x0A
	jrl z, .Lfo_end_iter		; if CR+LF, end iteration
.Lfo_not_cr:				; 0x28D92B
	sti16_24 0x2304e4, 0x0000              ; reset position
	cpi8_24 0x2304ee, 0x02                 ; cp (0x2304EE), 2
	jr nc, .Lfo_file_delete3
	incdi8_24 1, 2295022
	jrl t, .Lfo_end_iter

.Lfo_file_delete3:			; 0x28D942
	ld16_24 xbc, 0x230870                 ; BC = (0x230870)
	lds wa, 1
	calr HDAE5000_File_Delete
	ld xiz, xhl
	cp xiz, 0
	jr le, .Lfo_skip_iz_store3
	st16_24 0x230870, xiz                 ; (0x230870) = IZ
.Lfo_skip_iz_store3:			; 0x28D95B
	cp (xsp + 8), 1
	jrl nz, .Lfo_end_iter
	; Vtable call
	ld32_24 xwa, 0x23a19e
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e0a)
	ld_sril xhl, (xbc + 0x0100)
	ld xbc, 30015496		; 0x01CA0008
	lds32 xde, 0
	call (xhl)
	jrl t, .Lfo_end_iter

	; --- Type 0x58: audio parameter handler ---
.Lfo_type_58:				; 0x28D982
	ld8_24 a, 0x230636                    ; A = (0x230636) — type byte
	st8_24 0x2307a4, a                    ; (0x2307A4) = A
	cpi8_24 0x230637, 0x01                 ; cp (0x230637), 1 — subtype
	jr nz, .Lfo_58_check2
	sti8_24 0x2307a8, 0x02                 ; (0x2307A8) = 2
	sti16_24 0x2307ae, 0x0018              ; (0x2307AE) = 0x0018
.Lfo_58_check2:				; 0x28D9A1
	cpi8_24 0x230637, 0x02
	jr nz, .Lfo_58_check3
	sti8_24 0x2307a8, 0x04
	sti16_24 0x2307ae, 0x000c              ; 0x000C
.Lfo_58_check3:				; 0x28D9B6
	cpi8_24 0x230637, 0x03
	jr nz, .Lfo_58_check4
	sti8_24 0x2307a8, 0x08
	sti16_24 0x2307ae, 0x0006              ; 0x0006
.Lfo_58_check4:				; 0x28D9CB
	cpi8_24 0x230637, 0x04
	jr nz, .Lfo_58_done_checks
	sti8_24 0x2307a8, 0x10                 ; 0x10
	sti16_24 0x2307ae, 0x0003              ; 0x0003
.Lfo_58_done_checks:			; 0x28D9E0
	; Format and display audio params
	ld8_24 a, 0x2307a8                    ; A = (0x2307A8)
	extz wa
	pushw wa
	ld8_24 a, 0x2307a4                    ; A = (0x2307A4)
	extz wa
	pushw wa
	pushw 46			; width
	pushw 23600			; format 0x5C30
	lda_24 xwa, 0x230790                  ; &0x230790
	push xwa
	call 2730968			; display 0x29ABD8
	lda xsp, (xsp + 12)		; pop 12 bytes
	; Vtable call
	ld32_24 xwa, 0x23a19e
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e0a)
	ld_sril xhl, (xbc + 0x0100)
	ld xbc, 30015497		; 0x01CA0009
	lds32 xde, 4
	call (xhl)
	jr t, .Lfo_end_iter

	; --- Type 0x7E: directory reference handler ---
.Lfo_type_7E:				; 0x28DA22
	ld8_24 a, 0x230636                    ; A = (0x230636)
	cp a, 48			; cp A, 0x30
	jr nz, .Lfo_end_iter
	; Build path string and display
	lda_24 xwa, 0x230637                  ; &0x230637
	push xwa
	pushw 46			; width
	pushw 23608			; format 0x5C38
	lda_24 xwa, 0x2306b6                  ; &0x2306B6
	push xwa
	call 2730968			; display 0x29ABD8
	lda xsp, (xsp + 12)		; pop 12 bytes
	; Vtable call
	ld32_24 xwa, 0x23a19e
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e0a)
	ld_sril xhl, (xbc + 0x0100)
	ld xbc, 30015497		; 0x01CA0009
	lds32 xde, 2
	call (xhl)

	; --- End of iteration: check loop condition ---
.Lfo_end_iter:				; 0x28DA62
	ld32_24 xwa, 0x230444                 ; XWA = (0x230444) — limit
	cpda32_24 xwa, 2295908		; cp XWA, (0x230864)
	jr ugt, .Lfo_epilogue		; if past limit, exit
	cp xiz, 0
	jrl gt, .Lfo_loop		; if XIZ > 0, continue loop

	; --- Epilogue ---
.Lfo_epilogue:				; 0x28DA77
	pop xiz
	inc 6, xsp
	ret

	; ============================================================
	; Save file to HD — initialize allocation and set file type codes
	; Clears all file descriptor fields (0x230438-0x230876), copies
	; filename to 0x2306B6, computes sector count, then sets the
	; file type codes based on content type at (0x229DAD)/(0x229DAE).
	;
	; File type code mapping (stored to 0x23087E / 0x230880):
	;   Content type 0 → 0xF9    Content type 1 → 0x02
	;   Content type 2 → 0xFC    Content type 3 → 0x00
	;   Content type 4 → 0xFB    Default → 0xFC / 0x00
	;
	; Input: (implicit — reads globals at 0x229DAD/0x229DAE)
	; Output: XHL = 0 (always succeeds after setup)
	; ============================================================
HDAE5000_File_Save:	; 0x28DA7B (381 bytes)

	; --- Initialization: clear file save state ---
	sti8_24 0x23a19a, 0x01                 ; (0x23A19A) = 1 — save in progress
	sti16_24 0x2304e0, 0x0000              ; (0x2304E0) = 0
	sti16_24 0x2304e2, 0x0000              ; (0x2304E2) = 0
	sti16_24 0x2304e4, 0x0000              ; (0x2304E4) = 0
	sti8_24 0x2304ee, 0x00                 ; (0x2304EE) = 0
	sti16_24 0x2304e6, 0x0000              ; (0x2304E6) = 0
	sti8_24 0x2304ef, 0x00                 ; (0x2304EF) = 0
	lds32 xwa, 0
	st32_24 0x2304d8, xwa                 ; (0x2304D8) = 0
	; Push args and call display init
	pushw 240			; height = 0xF0
	pushw 32			; width = 0x20
	lda_24 xwa, 0x23a0aa                  ; XWA = &0x23A0AA
	push xwa
	call 2731719			; call 0x29AEC7

	; --- Clear file descriptor ---
	sti16_24 0x230870, 0x0000              ; (0x230870) = 0
	sti16_24 0x23086c, 0x0000              ; (0x23086C) = 0
	sti16_24 0x230438, 0x0000              ; (0x230438) = 0
	sti16_24 0x23043a, 0x0000              ; (0x23043A) = 0
	sti16_24 0x23043c, 0x0000              ; (0x23043C) = 0
	lds32 xwa, 0
	st32_24 0x230440, xwa                 ; (0x230440) = 0
	lds32 xwa, 0
	st32_24 0x230444, xwa                 ; (0x230444) = 0
	lds32 xwa, 0
	st32_24 0x230448, xwa                 ; (0x230448) = 0
	lds32 xwa, 0
	st32_24 0x23044c, xwa                 ; (0x23044C) = 0
	lds32 xwa, 0
	st32_24 0x230450, xwa                 ; (0x230450) = 0
	lds32 xwa, 0
	st32_24 0x230454, xwa                 ; (0x230454) = 0
	ld xwa, 4294967295		; 0xFFFFFFFF
	st32_24 0x230864, xwa                 ; (0x230864) = 0xFFFFFFFF
	sti16_24 0x230872, 0x0000              ; (0x230872) = 0
	sti16_24 0x230874, 0x0000              ; (0x230874) = 0
	lds32 xwa, 0
	st32_24 0x230876, xwa                 ; (0x230876) = 0

	; --- Copy filename ---
	pushw 46			; max length = 0x2E
	pushw 23634			; source offset = 0x5C52
	lda_24 xwa, 0x2306b6                  ; XWA = &0x2306B6 (filename dest)
	push xwa
	call 2731845			; call 0x29AF45
	lda xsp, (xsp + 16)		; pop 16 bytes of args

	; --- Set file params ---
	sti16_24 0x2307aa, 0x0001              ; (0x2307AA) = 1
	sti16_24 0x2307ac, 0x0000              ; (0x2307AC) = 0

	; --- Compute file size in sectors ---
	ld16_24 xwa, 0x22b43c                 ; WA = (0x22B43C) — bytes per sector
	calr HDAE5000_String_Compare	; (multiply helper: WA * something)
	ld wa, hl			; result WA = HL
	extz xwa			; zero-extend to 32-bit
	ld xbc, 12			; divisor
	call HDAE5000_Divide_Signed	; divide
	st32_24 0x230868, xhl                 ; (0x230868) = XHL (quotient)

	; --- File type code switch on (0x229DAD) → 0x23087E ---
	ld8_24 a, 0x229dad                    ; A = content type 1
	cps a, 4
	jr z, .Lfs_type1_4
	cps a, 3
	jr z, .Lfs_type1_3
	cps a, 2
	jr z, .Lfs_type1_2
	cps a, 1
	jr z, .Lfs_type1_1
	cps a, 0
	jr nz, .Lfs_type1_default
	sti8_24 0x23087e, 0xf9                 ; (0x23087E) = 0xF9
	jr t, .Lfs_type1_done
.Lfs_type1_1:				; 0x28DB88
	sti8_24 0x23087e, 0x02                 ; (0x23087E) = 0x02
	jr t, .Lfs_type1_done
.Lfs_type1_2:				; 0x28DB90
	sti8_24 0x23087e, 0xfc                 ; (0x23087E) = 0xFC
	jr t, .Lfs_type1_done
.Lfs_type1_3:				; 0x28DB98
	sti8_24 0x23087e, 0x00                 ; (0x23087E) = 0x00
	jr t, .Lfs_type1_done
.Lfs_type1_4:				; 0x28DBA0
	sti8_24 0x23087e, 0xfb                 ; (0x23087E) = 0xFB
	jr t, .Lfs_type1_done
.Lfs_type1_default:			; 0x28DBA8
	sti8_24 0x23087e, 0xfc                 ; (0x23087E) = 0xFC
.Lfs_type1_done:			; 0x28DBAE

	; --- File type code switch on (0x229DAE) → 0x230880 ---
	ld8_24 a, 0x229dae                    ; A = content type 2
	cps a, 4
	jr z, .Lfs_type2_4
	cps a, 3
	jr z, .Lfs_type2_3
	cps a, 2
	jr z, .Lfs_type2_2
	cps a, 1
	jr z, .Lfs_type2_1
	cps a, 0
	jr nz, .Lfs_type2_default
	sti8_24 0x230880, 0xf9                 ; (0x230880) = 0xF9
	jr t, .Lfs_type2_done
.Lfs_type2_1:				; 0x28DBCF
	sti8_24 0x230880, 0x02                 ; (0x230880) = 0x02
	jr t, .Lfs_type2_done
.Lfs_type2_2:				; 0x28DBD7
	sti8_24 0x230880, 0xfc                 ; (0x230880) = 0xFC
	jr t, .Lfs_type2_done
.Lfs_type2_3:				; 0x28DBDF
	sti8_24 0x230880, 0x00                 ; (0x230880) = 0x00
	jr t, .Lfs_type2_done
.Lfs_type2_4:				; 0x28DBE7
	sti8_24 0x230880, 0xfb                 ; (0x230880) = 0xFB
	jr t, .Lfs_type2_done
.Lfs_type2_default:			; 0x28DBEF
	sti8_24 0x230880, 0x00                 ; (0x230880) = 0x00
.Lfs_type2_done:			; 0x28DBF5
	lds32 xhl, 0			; return XHL = 0 (success)
	ret

	; ============================================================
	; Load file from HD — populate file descriptors from directory
	; Uses File_Rename as a directory lookup (not actual rename):
	;   Block 1: filename slot 1 (type 2, max 50 chars → 0x230736)
	;   Block 2: filename slot 2 (type 3, max 40 chars → 0x230768)
	;   Block 3: audio settings (type 0x58 → 0x2307A4-0x2307B0)
	;     Audio channel mapping:
	;       type 1 → 2ch, 24 samples   type 2 → 4ch, 12 samples
	;       type 3 → 8ch, 6 samples    type 4 → 16ch, 3 samples
	;     Default: 4ch, 12 samples
	;   Final: additional data via type 0x7C lookup
	;
	; Input: (implicit — reads directory via File_Rename)
	; Output: XHL = 0 (always succeeds)
	; ============================================================
HDAE5000_File_Load:	; 0x28DBF8 (564 bytes)

	; --- Block 1: Load filename slot 1 (WA=2, BC=2, max 0x32 chars) ---
	lds32 xwa, 0
	push xwa
	lds wa, 2
	lds bc, 2
	ldw de, 65534			; DE = 0xFFFE
	calr HDAE5000_File_Rename
	cp xhl, 0
	jr le, .Lfl_default1		; if result <= 0, use default

	; Result > 0: copy filename, cap at 50 bytes
	cpdi16_24 2294838, 50		; cp (0x230436), 0x32
	jr c, .Lfl_short1		; if length < 50, copy actual length
	; Length >= 50: truncate
	pushw 50
	lda_24 xwa, 0x230636                  ; &0x230636
	push xwa
	lda_24 xwa, 0x230736                  ; &0x230736
	push xwa
	call 2732016			; call 0x29AFF0 (memcpy)
	lda xsp, (xsp + 10)		; pop 10 bytes
	sti8_24 0x230767, 0x00                 ; (0x230767) = null terminator
	jr t, .Lfl_block2
.Lfl_short1:				; 0x28DC34
	; Copy actual length
	ld16_24 xwa, 0x230436                 ; WA = (0x230436)
	pushw wa
	lda_24 xwa, 0x230636                  ; &0x230636
	push xwa
	lda_24 xwa, 0x230736                  ; &0x230736
	push xwa
	call 2732016			; call 0x29AFF0 (memcpy)
	lda xsp, (xsp + 10)		; pop 10 bytes
	; Null-terminate at actual length
	ld16_24 xwa, 0x230436                 ; WA = (0x230436)
	extz xwa
	ld xbc, 2295606			; XBC = 0x00230736
	add xbc, xwa
	ld (xbc), 0			; *(base + len) = 0
	jr t, .Lfl_block2
.Lfl_default1:				; 0x28DC60
	; No entry found: copy default string
	pushw 46			; max length = 0x2E
	pushw 23670			; source = 0x5C76
	lda_24 xwa, 0x230736                  ; &0x230736
	push xwa
	call 2731845			; call 0x29AF45
	inc 0, xsp			; pop stack frame

.Lfl_block2:				; 0x28DC72
	; --- Block 2: Load filename slot 2 (WA=3, BC=2, max 0x28 chars) ---
	lds32 xwa, 0
	push xwa
	lds wa, 3
	lds bc, 2
	ldw de, 65534			; DE = 0xFFFE
	calr HDAE5000_File_Rename
	cp xhl, 0
	jr le, .Lfl_default2		; if result <= 0, use default

	; Result > 0: copy, cap at 40 bytes
	cpdi16_24 2294838, 40		; cp (0x230436), 0x28
	jr c, .Lfl_short2
	; Truncate at 40
	pushw 40
	lda_24 xwa, 0x230636                  ; &0x230636
	push xwa
	lda_24 xwa, 0x230768                  ; &0x230768
	push xwa
	call 2732016			; call 0x29AFF0
	lda xsp, (xsp + 10)
	sti8_24 0x23078f, 0x00                 ; (0x23078F) = null terminator
	jr t, .Lfl_block3
.Lfl_short2:				; 0x28DCAE
	; Copy actual length
	ld16_24 xwa, 0x230436                 ; WA = (0x230436)
	pushw wa
	lda_24 xwa, 0x230636                  ; &0x230636
	push xwa
	lda_24 xwa, 0x230768                  ; &0x230768
	push xwa
	call 2732016			; call 0x29AFF0
	lda xsp, (xsp + 10)
	ld16_24 xwa, 0x230436                 ; WA = (0x230436)
	extz xwa
	ld xbc, 2295656			; XBC = 0x00230768
	add xbc, xwa
	ld (xbc), 0			; *(base + len) = 0
	jr t, .Lfl_block3
.Lfl_default2:				; 0x28DCDA
	; Copy default string
	pushw 46			; max = 0x2E
	pushw 23688			; source = 0x5C88
	lda_24 xwa, 0x230736                  ; &0x230736
	push xwa
	call 2731845			; call 0x29AF45
	inc 0, xsp			; pop stack frame

.Lfl_block3:				; 0x28DCEC
	; --- Block 3: Load audio settings (WA=0x58, BC=2) ---
	lds32 xwa, 0
	push xwa
	ldw wa, 88			; WA = 0x58
	lds bc, 2
	ldw de, 65534			; DE = 0xFFFE
	calr HDAE5000_File_Rename
	cp xhl, 0
	jrl le, .Lfl_audio_default	; long relative jump if no entry

	; Entry found: read channel count and type
	ld8_24 a, 0x230636                    ; A = (0x230636) — channel count
	st8_24 0x2307a4, a                    ; (0x2307A4) = A
	st8_24 0x2307a6, a                    ; (0x2307A6) = A

	; Switch on audio type at (0x230637):
	;   Stores: channel count → 0x2307A8, samples/ch → 0x2307AE/0x2307B0
	cpi8_24 0x230637, 0x01                 ; type 1?
	jr nz, .Lfl_audio_ch2
	sti8_24 0x2307a8, 0x02                 ; channels = 2
	sti16_24 0x2307ae, 0x0018              ; samples per channel = 24
	sti16_24 0x2307b0, 0x0018              ; samples per channel (copy) = 24
.Lfl_audio_ch2:				; 0x28DD2E
	cpi8_24 0x230637, 0x02                 ; type 2?
	jr nz, .Lfl_audio_ch3
	sti8_24 0x2307a8, 0x04                 ; channels = 4
	sti16_24 0x2307ae, 0x000c              ; samples per channel = 12
	sti16_24 0x2307b0, 0x000c              ; samples per channel (copy) = 12
.Lfl_audio_ch3:				; 0x28DD4A
	cpi8_24 0x230637, 0x03                 ; type 3?
	jr nz, .Lfl_audio_ch4
	sti8_24 0x2307a8, 0x08                 ; channels = 8
	sti16_24 0x2307ae, 0x0006              ; samples per channel = 6
	sti16_24 0x2307b0, 0x0006              ; samples per channel (copy) = 6
.Lfl_audio_ch4:				; 0x28DD66
	cpi8_24 0x230637, 0x04                 ; type 4?
	jr nz, .Lfl_audio_done
	sti8_24 0x2307a8, 0x10                 ; channels = 16
	sti16_24 0x2307ae, 0x0003              ; samples per channel = 3
	sti16_24 0x2307b0, 0x0003              ; samples per channel (copy) = 3
	jr t, .Lfl_audio_done
.Lfl_audio_default:			; 0x28DD84
	; No entry: default to 4ch/12
	sti8_24 0x2307a6, 0x04                 ; (0x2307A6) = 4
	sti8_24 0x2307a4, 0x04                 ; (0x2307A4) = 4
	sti8_24 0x2307a8, 0x04                 ; (0x2307A8) = 4
	sti16_24 0x2307ae, 0x000c              ; (0x2307AE) = 12
	sti16_24 0x2307b0, 0x000c              ; (0x2307B0) = 12

.Lfl_audio_done:			; 0x28DDA4
	; --- Build format string and display ---
	ld8_24 a, 0x2307a8                    ; A = (0x2307A8)
	extz wa
	pushw wa
	ld8_24 a, 0x2307a4                    ; A = (0x2307A4)
	extz wa
	pushw wa
	pushw 46			; 0x2E
	pushw 23702			; 0x5C96
	lda_24 xwa, 0x230790                  ; &0x230790
	push xwa
	call 2730968			; call 0x29ABD8
	lda xsp, (xsp + 12)		; pop 12 bytes

	; --- Call via function pointer (nested indirection) ---
	ld32_24 xwa, 0x23a19e                 ; XWA = (0x23A19E)
	ld32_24 xbc, 0x23a1a2                 ; XBC = (0x23A1A2)
	ld_sril xbc, (xbc + 0x0e0a)             ; XBC = (XBC + 0x0E0A) — vtable ptr
	ld_sril xhl, (xbc + 0x0100)             ; XHL = (XBC + 0x0100) — function ptr
	ld xbc, 30015493		; XBC = 0x01CA0005
	lds32 xde, 0
	call (xhl)			; call function ptr

	; --- Clear state variables ---
	sti16_24 0x230430, 0x00ff              ; (0x230430) = 0x00FF
	sti16_24 0x230432, 0x0000              ; (0x230432) = 0
	sti16_24 0x230434, 0x0000              ; (0x230434) = 0
	sti16_24 0x230436, 0x0000              ; (0x230436) = 0
	sti8_24 0x2304f0, 0x00                 ; (0x2304F0) = 0
	sti16_24 0x23086e, 0x0000              ; (0x23086E) = 0
	lds32 xwa, 0
	st32_24 0x230440, xwa                 ; (0x230440) = 0

	; --- Final call: slot 0x7C ---
	lds32 xwa, 0
	push xwa
	ldw wa, 124			; WA = 0x7C
	lds bc, 2
	ldw de, 65534			; DE = 0xFFFE
	calr HDAE5000_File_Rename
	lds32 xwa, 0
	st32_24 0x230440, xwa                 ; (0x230440) = 0
	lds32 xhl, 0			; return XHL = 0 (success)
	ret

	; ============================================================
	; Delete file from HD — manage directory entries
	; If mode=1: backup 5 entries (40 bytes each, 0x23A0AA → 0x23A0D2)
	; before modifying. Then iterates up to 6 directory slots,
	; calling File_Rename(type=5) to look up each entry.
	;
	; File type dispatch on byte at (0x230636):
	;   0x0D: directory entry → copy raw entry to local buffer
	;   0x0A: named entry → fill with default string (ROM 0x5C9E)
	;   Other: concatenate entry names (max 39 chars combined)
	;
	; String lengths tracked at 0x2304D8[slot + 16].
	; Restores original allocation state on exit.
	;
	; Input: A = mode (1=backup first), BC = starting entry index
	; Output: XHL = final entry index (zero-extended)
	; ============================================================
HDAE5000_File_Delete:	; 0x28DE2C (579 bytes)

	; --- Prologue: allocate stack frame, save registers ---
	lda xsp, (xsp - 58)		; allocate 58 bytes of locals
	pushw iz			; save IZ
	ld (xsp + 58), bc		; save BC param at [0x3A]
	ld32_24 xbc, 0x230440                 ; XBC = (0x230440)
	ld (xsp + 10), xbc		; save to local[0x0A]
	ld32_24 xbc, 0x230444                 ; XBC = (0x230444)
	ld (xsp + 14), xbc		; save to local[0x0E]

	; --- If A == 1: backup 5 directory entries (40 bytes each) ---
	cps a, 1
	jr nz, .Lfd_else		; skip backup if mode != 1

	ldw (xsp + 2), 0		; slot = 0
	cpw (xsp + 2), 5		; while slot < 5
	jr ge, .Lfd_copy_done
.Lfd_copy_loop:				; 0x28DE53
	; Compute dest = 0x23A0D2 + slot*40
	ld wa, (xsp + 2)
	muls wa, 40
	lda_24 xbc, 0x23a0d2                  ; XBC = 0x23A0D2
	exts xwa
	add xwa, xbc
	push xwa
	; Compute src = 0x23A0AA + slot*40
	ld wa, (xsp + 6)		; slot (offset by push)
	muls wa, 40
	lda_24 xbc, 0x23a0aa                  ; XBC = 0x23A0AA
	exts xwa
	add xwa, xbc
	push xwa
	call 2731845			; call 0x29AF45 (memcpy)
	; Get strlen of source entry
	ld wa, (xsp + 10)		; slot (offset by 2 pushes)
	muls wa, 40
	lda_24 xbc, 0x23a0aa                  ; XBC = 0x23A0AA
	exts xwa
	add xwa, xbc
	push xwa
	call 2731889			; call 0x29AF71 (strlen)
	lda xsp, (xsp + 12)		; pop 12 bytes
	; Store length at 0x2304D8 + slot + 16
	ld wa, (xsp + 2)		; slot
	add wa, 16
	lda_24 xbc, 0x2304d8                  ; XBC = 0x2304D8
	lda_dri3 xsp, 0x07, 0xe4, 0xe0	; ld (XBC+WA), L
	incm 1, (xsp + 2)		; slot++
	cpw (xsp + 2), 5
	jr lt, .Lfd_copy_loop
.Lfd_copy_done:				; 0x28DEAC
	ldb c, 5			; C = 5 (entry count)
	jr t, .Lfd_setup_loop
.Lfd_else:				; 0x28DEB0
	ldb c, 0			; C = 0

.Lfd_setup_loop:			; 0x28DEB2
	; --- Setup outer loop ---
	ld wa, (xsp + 58)		; WA = saved BC param
	ld (xsp + 4), wa		; local[0x04] = entry index
	ld a, c				; A = count
	extz wa
	ld (xsp + 2), wa		; local[0x02] = count
	cpw (xsp + 2), 6		; if count >= 6
	jrl ge, .Lfd_epilogue		;   skip to epilogue

.Lfd_outer_loop:			; 0x28DEC7
	; --- Outer loop: process each directory entry ---
	ld (xsp + 18), 0		; clear string buffer at local[0x12]
	ld wa, (xsp + 4)		; WA = entry index
	extz xwa
	push xwa
	lds wa, 5			; type = 5
	lds bc, 2
	ldw de, 65534			; DE = 0xFFFE
	calr HDAE5000_File_Rename
	ld (xsp + 6), xhl		; local[0x06] = result
	cpdi16_24 2294836, 1		; if (0x230434) == 1
	jrl z, .Lfd_tail_copy		;   goto tail_copy
	ld xwa, (xsp + 6)		; XWA = result
	cp xwa, 0
	jrl le, .Lfd_no_entry		; if result <= 0, no entry

	; Check file type byte
	cpi8_24 0x230636, 0x0d                 ; cp (0x230636), 0x0D
	jr nz, .Lfd_try_0a		; if != 0x0D, try next type

	; --- File type 0x0D: raw directory entry → copy to local stack buffer ---
	ld xwa, (xsp + 6)		; result
	ld (xsp + 4), wa		; save low word
	lda xwa, (xsp + 18)		; XWA = &local[0x12]
	push xwa
	ld wa, (xsp + 6)		; slot (offset by push)
	muls wa, 40
	lda_24 xbc, 0x23a0aa                  ; XBC = 0x23A0AA
	exts xwa
	add xwa, xbc
	push xwa
	call 2731845			; memcpy
	inc 0, xsp			; pop stack frame

.Lfd_strlen_store:			; 0x28DF1D
	; Get strlen and store length, then advance slot
	ld wa, (xsp + 2)		; slot
	muls wa, 40
	lda_24 xbc, 0x23a0aa                  ; XBC = 0x23A0AA
	exts xwa
	add xwa, xbc
	push xwa
	call 2731889			; strlen
	inc 4, xsp			; pop 4 bytes
	ld wa, (xsp + 2)		; slot
	add wa, 16
	lda_24 xbc, 0x2304d8                  ; XBC = 0x2304D8
	lda_dri3 xsp, 0x07, 0xe4, 0xe0	; ld (XBC+WA), L
	incm 1, (xsp + 2)		; slot++
	cpw (xsp + 2), 6		; if slot < 6
	jrl lt, .Lfd_outer_loop		;   continue outer loop

.Lfd_epilogue:				; 0x28DF50
	; --- Restore state and return ---
	ld xwa, (xsp + 10)
	st32_24 0x230440, xwa                 ; restore (0x230440)
	ld xwa, (xsp + 14)
	st32_24 0x230444, xwa                 ; restore (0x230444)
	ld hl, (xsp + 4)		; HL = local[0x04]
	extz xhl			; XHL = zero-extend(HL)
	popw iz				; restore IZ
	lda xsp, (xsp + 58)		; deallocate stack frame
	ret

.Lfd_try_0a:				; 0x28DF6A
	; --- File type 0x0A: named entry → fill with default name ---
	cpi8_24 0x230636, 0x0a                 ; cp (0x230636), 0x0A
	jr nz, .Lfd_other_type
	ld xwa, (xsp + 6)		; result
	ld (xsp + 4), wa		; save
	pushw 46			; max = 0x2E
	pushw 23710			; src = 0x5C9E
	ld wa, (xsp + 6)		; slot (offset)
	muls wa, 40
	lda_24 xbc, 0x23a0aa                  ; XBC = 0x23A0AA
	exts xwa
	add xwa, xbc
	push xwa
	call 2731845			; memcpy
	inc 0, xsp			; pop frame
	jr t, .Lfd_strlen_store		; goto strlen/store

.Lfd_other_type:			; 0x28DF97
	; --- Other file type: concatenate entry name if it fits ---
	lda_24 xwa, 0x230636                  ; XWA = &0x230636
	push xwa
	call 2731889			; strlen(0x230636)
	inc 4, xsp			; pop 4 bytes
	cp hl, 39			; if strlen <= 39
	jr ule, .Lfd_short_string	;   handle short string
	; String too long: save and restart loop
	ld xwa, (xsp + 6)		; result
	ld (xsp + 4), wa
	jrl t, .Lfd_outer_loop		; restart

.Lfd_short_string:			; 0x28DFB2
	; Get local buffer length
	lda xwa, (xsp + 18)		; &local[0x12]
	push xwa
	call 2731889			; strlen(&local)
	ld iz, hl			; IZ = local strlen
	; Get source string length
	lda_24 xwa, 0x230636                  ; &0x230636
	push xwa
	call 2731889			; strlen(0x230636)
	inc 0, xsp			; pop frame
	add hl, iz			; HL = combined length
	cp hl, 39			; if combined > 39
	jr ugt, .Lfd_tail_copy		;   no room, goto tail_copy
	; Concatenate strings
	lda_24 xwa, 0x230636                  ; &0x230636
	push xwa
	lda xwa, (xsp + 22)		; &local[0x12] (offset by push)
	push xwa
	call 2731787			; call 0x29AF0B (strcat)
	inc 0, xsp			; pop frame
	ld xwa, (xsp + 6)		; result
	ld (xsp + 4), wa		; save

.Lfd_no_entry:				; 0x28DFE6
	; --- No entry found or zero result: use default ---
	ld xwa, (xsp + 6)		; XWA = result
	or xwa, xwa			; test zero
	jr nz, .Lfd_check_positive	; if nonzero, check further
	; Result is zero: copy default string
	pushw 46			; max = 0x2E
	pushw 23712			; src = 0x5CA0
	ld wa, (xsp + 6)		; slot (offset)
	muls wa, 40
	lda_24 xbc, 0x23a0aa                  ; XBC = 0x23A0AA
	exts xwa
	add xwa, xbc
	push xwa
	call 2731845			; memcpy
	inc 0, xsp			; pop frame
	jrl t, .Lfd_strlen_store	; goto strlen/store

.Lfd_check_positive:			; 0x28E00D
	ld xwa, (xsp + 6)		; XWA = result
	cp xwa, 0
	jrl gt, .Lfd_outer_loop + 4	; if result > 0, continue (0x28DECB)

.Lfd_tail_copy:				; 0x28E019
	; --- Copy entry to directory slot ---
	lda xwa, (xsp + 18)		; &local[0x12]
	push xwa
	ld wa, (xsp + 6)		; slot (offset)
	muls wa, 40
	lda_24 xbc, 0x23a0aa                  ; XBC = 0x23A0AA
	exts xwa
	add xwa, xbc
	push xwa
	call 2731845			; memcpy
	ld wa, (xsp + 10)		; slot (offset by 2 pushes)
	muls wa, 40
	lda_24 xbc, 0x23a0aa                  ; XBC = 0x23A0AA
	exts xwa
	add xwa, xbc
	push xwa
	call 2731889			; strlen
	lda xsp, (xsp + 12)		; pop 12 bytes
	ld wa, (xsp + 2)		; slot
	add wa, 16
	lda_24 xbc, 0x2304d8                  ; XBC = 0x2304D8
	lda_dri3 xsp, 0x07, 0xe4, 0xe0	; ld (XBC+WA), L
	cpdi16_24 2294836, 1		; if (0x230434) != 1
	jrl nz, .Lfd_strlen_store	;   goto strlen/store
	sti16_24 0x230434, 0x0000              ; (0x230434) = 0
	jrl t, .Lfd_epilogue		; done

	; ============================================================
	; Directory search/lookup — traverse partitions to find entries
	; Despite the name, this is NOT a rename operation. It walks
	; partitions by calling File_Format, searching for entries
	; whose type code at (0x230430) matches the requested type.
	;
	; Modes based on DE (file count):
	;   DE >= 0: iterate DE partitions starting from sector 0
	;     Type 0x7C: single format at partition C, return offset
	;     Other: search loop until type matches at (0x230430)
	;   DE == -1: return error (-1) immediately
	;   DE == -2: use caller's 32-bit stack arg as start sector
	;     Same sub-modes as DE >= 0 (0x7C vs search)
	;
	; Input: WA = operation/entry type to find
	;        BC = partition type byte
	;        DE = file count (-1=error, -2=use stack arg)
	;        (xsp+14) = 32-bit caller arg (for DE==-2 mode)
	; Output: XHL = sector offset of found entry, or -1 on error
	; ============================================================
HDAE5000_File_Rename:	; 0x28E06F (280 bytes)
	dec 0, xsp			; allocate 8 bytes
	pushw iz
	ld (xsp + 4), de		; save file count
	ld (xsp + 6), c		; save partition
	ld (xsp + 8), a		; save operation type
	cpw (xsp + 4), 0x0000
	jrl lt, .Lfr_negative		; negative count → special handler
	; Positive count: iterate and accumulate
	ldw (xsp + 2), 0x0000		; counter = 0
	lds32 xwa, 0
	st32_24 0x230440, xwa                 ; clear 0x230440
	lds iz, 0
	cp iz, (xsp + 4)
	jr ge, .Lfr_loop_done
.Lfr_loop_start:
	ld bc, (xsp + 2)		; load counter
	lds wa, 0
	calr HDAE5000_File_Format
	ld wa, hl
	add (xsp + 2), wa		; accumulate
	cps hl, 0
	jr nz, .Lfr_loop_next
	ld xhl, 0xFFFFFFFF		; format returned 0 → error
	jrl .Lfr_exit
.Lfr_loop_next:
	inc 1, iz
	cp iz, (xsp + 4)
	jr lt, .Lfr_loop_start
.Lfr_loop_done:
	cp (xsp + 8), 0x7c		; check operation type
	jr nz, .Lfr_search_pos
	; Operation 0x7C: single format call, compute offset
	ld a, (xsp + 6)
	extz wa
	ld bc, (xsp + 2)
	calr HDAE5000_File_Format
	ld wa, hl
	cps wa, 0
	jr z, .Lfr_7c_error
	ld wa, (xsp + 2)
	extz xwa
	ld bc, hl
	extz xbc
	ld xhl, xbc
	add xhl, xwa			; result = format_result + counter
	jrl .Lfr_exit
.Lfr_7c_error:
	ld xhl, 0xFFFFFFFF
	jrl .Lfr_exit
.Lfr_search_pos:
	; Not 0x7C: search loop — walk partitions until type matches
	ld a, (xsp + 6)
	extz wa
	ld bc, (xsp + 2)
	calr HDAE5000_File_Format
	ld wa, hl
	add (xsp + 2), wa
	cps hl, 0
	jr z, .Lfr_search_pos_check
	ld a, (xsp + 8)
	extz wa
	cpda16_24 xwa, 2294832		; type == (0x230430)? (file type from partition)
	jr nz, .Lfr_search_pos		; no match → try next partition
.Lfr_search_pos_check:
	cps hl, 0
	jr z, .Lfr_search_pos_err
	ld hl, (xsp + 2)
	extz xhl
	jr t, .Lfr_exit
.Lfr_search_pos_err:
	ld xhl, 0xFFFFFFFF
	jr t, .Lfr_exit
.Lfr_negative:
	; DE < 0: check special values
	cpw (xsp + 4), 0xFFFF	; DE == -1?
	jr nz, .Lfr_check_fffe
	ld xhl, 0xFFFFFFFF
	jr t, .Lfr_exit
.Lfr_check_fffe:
	cpw (xsp + 4), 0xFFFE	; DE == -2?
	jr nz, .Lfr_return_zero
	cp (xsp + 8), 0x7c
	jr nz, .Lfr_fffe_search
	; DE==-2, op==0x7C: use caller's stack arg
	ld a, (xsp + 6)
	ld e, a
	extz de
	ld xwa, (xsp + 14)		; caller's 32-bit argument
	ld bc, wa
	ld wa, de
	calr HDAE5000_File_Format
	extz xhl
	jr t, .Lfr_exit
.Lfr_fffe_search:
	; DE==-2, op!=0x7C: search loop with caller's arg
	ld xwa, (xsp + 14)
	ld (xsp + 2), wa		; use lower 16 bits as counter
.Lfr_fffe_loop:
	ld a, (xsp + 6)
	extz wa
	ld bc, (xsp + 2)
	calr HDAE5000_File_Format
	ld wa, hl
	add (xsp + 2), wa
	cps hl, 0
	jr z, .Lfr_fffe_check
	ld a, (xsp + 8)
	extz wa
	cpda16_24 xwa, 2294832		; compare with (0x230430)
	jr nz, .Lfr_fffe_loop
.Lfr_fffe_check:
	cps hl, 0
	jr z, .Lfr_fffe_error
	ld hl, (xsp + 2)
	extz xhl
	jr t, .Lfr_exit
.Lfr_fffe_error:
	ld xhl, 0xFFFFFFFF
	jr t, .Lfr_exit
.Lfr_return_zero:
	lds32 xhl, 0
.Lfr_exit:
	popw iz
	inc 0, xsp			; deallocate 8 bytes
	retd 0x0004

	; ============================================================
	; Format disk partition
	; Validates sector range, reads VarInt-encoded allocation data
	; from sector table at 0x22B430, and maps the partition layout.
	; Supports backup mode (preserves previous allocation state) and
	; filename copy mode (copies sector data as filename string).
	;
	; Error codes stored to (0x2307B6):
	;   0xFFFF = start+4 exceeds max sector limit (20,457)
	;   0xFFFE = Calc_Disk_Space returned -1 (VarInt overflow)
	;   0xFFFD = first sector byte ≠ 0xFF (sector not free)
	;   0xFFFC = second Calc_Disk_Space failed
	;   0xFFFB = total allocation exceeds max sector limit
	;   0xFFFA = third Calc_Disk_Space failed
	;
	; Input: BC = start sector, A = flags (bit0=backup, bit1=copy filename)
	; Output: HL = sectors consumed (end - start), or 0 on error
	; Uses QIZH (XIZ high byte) as backup flag
	; ============================================================
HDAE5000_File_Format:	; 0x28E187 (772 bytes)

	; --- Prologue ---
	dec 4, xsp			; allocate 8 bytes
	push xiz
	ld (xsp + 4), bc		; save start sector
	ld (xsp + 6), a		; save flags
	ldi_berp 0xfb, 0		; QIZH = 0 (no backup)

	; --- Check sector limit (max 20,457 = 0x4FE9) ---
	ld wa, (xsp + 4)		; WA = start sector
	inc 4, wa			; WA += 4 (need 4 header sectors)
	cp wa, 20457			; start+4 within addressable range?
	jr ule, .Lff_start
	sti16_24 0x2307b6, 0xffff              ; (0x2307B6) = 0xFFFF — error
	lds hl, 0
	jrl t, .Lff_epilogue

.Lff_start:				; 0x28E1AA
	ld iz, (xsp + 4)		; IZ = start sector
	ld a, (xsp + 6)		; A = flags
	and a, 1			; isolate bit 0
	cps a, 1
	jr nz, .Lff_skip_backup_flag
	ldi_berp 0xfb, 1		; QIZH = 1 (backup mode)

.Lff_skip_backup_flag:			; 0x28E1BA
	cpi_berp 0xfb, 1		; check QIZH == 1
	jr nz, .Lff_skip_backup_save
	; Save current position before overwriting
	ld16_24 xwa, 0x230438                 ; WA = (0x230438)
	st16_24 0x23043c, xwa                 ; (0x23043C) = WA
	ld wa, (xsp + 4)
	st16_24 0x230438, xwa                 ; (0x230438) = start sector

.Lff_skip_backup_save:			; 0x28E1D1
	ld wa, iz
	calr HDAE5000_Calc_Disk_Space
	st32_24 0x230860, xhl                 ; (0x230860) = free space
	cp xhl, 4294967295		; == 0xFFFFFFFF?
	jr nz, .Lff_after_space_check
	sti16_24 0x2307b6, 0xfffe              ; (0x2307B6) = 0xFFFE — error
	lds hl, 0
	jrl t, .Lff_epilogue

.Lff_after_space_check:			; 0x28E1EF
	cpi_berp 0xfb, 1
	jr nz, .Lff_skip_backup_copy
	; Backup: save old values
	ld32_24 xwa, 0x230440                 ; XWA = (0x230440)
	st32_24 0x230448, xwa                 ; (0x230448) = XWA
	ld32_24 xwa, 0x23044c                 ; XWA = (0x23044C)
	st32_24 0x230454, xwa                 ; (0x230454) = XWA
	ld32_24 xwa, 0x230860                 ; XWA = (0x230860)
	st32_24 0x23044c, xwa                 ; (0x23044C) = XWA

.Lff_skip_backup_copy:			; 0x28E212
	ld32_24 xwa, 0x230860                 ; XWA = (0x230860)
	addm32_24 0x230440, xwa                ; (0x230440) += XWA
	addda16_24 xiz, 2295902	; IZ += (0x23085E)
	ld wa, iz
	inc 1, iz			; IZ++
	; Read sector type byte: table[sector + 22]
	extz xwa
	add xwa, 22			; +22 = descriptor offset in table
	ld xbc, 2274352			; XBC = 0x0022B430 (table base)
	add xbc, xwa
	cp (xbc), 255		; 0xFF = free sector?
	jr z, .Lff_byte2_read		; yes → sector available for formatting
	sti16_24 0x2307b6, 0xfffd              ; error: sector not free (0xFFFD)
	lds hl, 0
	jrl t, .Lff_epilogue

.Lff_byte2_read:			; 0x28E245
	ld wa, iz
	inc 1, iz			; IZ++
	extz xwa
	add xwa, 22
	ld xbc, 2274352			; table base
	add xbc, xwa
	ld a, (xbc)			; A = sector type byte
	extz wa
	st16_24 0x230430, xwa                 ; (0x230430) = file type code
	cpdi16_24 2294832, 47		; type == 0x2F (reserved/invalid)?
	jr nz, .Lff_after_type_check
	; Type 0x2F = reserved sector — abort formatting
	sti16_24 0x230434, 0x0001              ; (0x230434) = 1 — abort flag
	ld xwa, 4294967295		; 0xFFFFFFFF
	st32_24 0x230860, xwa                 ; (0x230860) = -1
	lds hl, 0
	jrl t, .Lff_epilogue

.Lff_after_type_check:			; 0x28E280
	ld wa, iz
	calr HDAE5000_Calc_Disk_Space
	ld xwa, xhl
	cp xwa, 4294967295		; == 0xFFFFFFFF?
	jr nz, .Lff_after_format_calc
	sti16_24 0x2307b6, 0xfffc              ; (0x2307B6) = 0xFFFC — error
	lds hl, 0
	jrl t, .Lff_epilogue

.Lff_after_format_calc:			; 0x28E29B
	addda16_24 xiz, 2295902	; IZ += (0x23085E)
	st16_24 0x230436, xhl                 ; (0x230436) = HL — file length
	; Check combined length
	ld wa, iz
	addda16_24 xwa, 2294838	; WA += (0x230436)
	cp wa, 20457			; cp WA, 0x4FE9
	jr ule, .Lff_after_limit2
	sti16_24 0x2307b6, 0xfffb              ; (0x2307B6) = 0xFFFB — error
	lds hl, 0
	jrl t, .Lff_epilogue

.Lff_after_limit2:			; 0x28E2BE
	ld wa, iz
	addda16_24 xwa, 2294838	; WA += (0x230436)
	st16_24 0x23043a, xwa                 ; (0x23043A) = WA — end position
	; Compute free space for remaining
	ld wa, iz
	addda16_24 xwa, 2294838	; WA += (0x230436)
	calr HDAE5000_Calc_Disk_Space
	st32_24 0x230450, xhl                 ; (0x230450) = XHL
	cp xhl, 4294967295
	jr nz, .Lff_after_error3
	sti16_24 0x2307b6, 0xfffa              ; (0x2307B6) = 0xFFFA — error
	lds hl, 0
	jrl t, .Lff_epilogue

.Lff_after_error3:			; 0x28E2ED
	; Read terminator byte
	ld wa, iz
	addda16_24 xwa, 2294838	; WA += (0x230436)
	addda16_24 xwa, 2295902	; WA += (0x23085E)
	inc 4, wa			; WA += 4
	extz xwa
	add xwa, 22
	ld xbc, 2274352
	add xbc, xwa
	ld a, (xbc)
	st8_24 0x230882, a                    ; (0x230882) = A

	; --- Copy string block 1 (if QIZH == 1) ---
	cpi_berp 0xfb, 1
	jr nz, .Lff_after_copy1		; skip if not backup mode
	cpdi16_24 2294838, 127		; cp (0x230436), 0x7F
	jr ugt, .Lff_long_copy1	; if > 127, truncate
	; Short copy: actual length
	ld16_24 xwa, 0x230436                 ; WA = (0x230436)
	extz xwa
	pushw wa			; push length
	ld wa, iz
	extz xwa
	add xwa, 22
	ld xbc, 2274352
	add xbc, xwa
	push xbc			; push source
	lda_24 xwa, 0x230458                  ; &0x230458 — dest
	push xwa
	call 2731679			; strcpy_len 0x29AE9F
	lda xsp, (xsp + 10)		; pop 10 bytes
	; Null-terminate
	ld16_24 xwa, 0x230436                 ; WA = length
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
	ld xbc, 2274352
	add xbc, xwa
	push xbc			; push source
	lda_24 xwa, 0x230458                  ; &0x230458
	push xwa
	call 2731679			; strcpy_len
	lda xsp, (xsp + 10)
	sti8_24 0x2304d7, 0x00                 ; (0x2304D7) = 0 — null terminate at 127

.Lff_after_copy1:			; 0x28E387
	; Compute total allocation
	ld32_24 xwa, 0x230440                 ; XWA = (0x230440)
	addda32_24 xwa, 2294864	; XWA += (0x230450)
	st32_24 0x230444, xwa                 ; (0x230444) = XWA — total

	; --- Copy string block 2 (if flag bit 1 set) ---
	ld a, (xsp + 6)		; A = flags
	and a, 2			; isolate bit 1
	cps a, 2
	jr nz, .Lff_after_copy2		; skip if bit 1 not set
	cpdi16_24 2294838, 127		; cp (0x230436), 0x7F
	jr ugt, .Lff_long_copy2
	; Short copy
	ld16_24 xwa, 0x230436
	extz xwa
	pushw wa
	ld wa, iz
	extz xwa
	add xwa, 22
	ld xbc, 2274352
	add xbc, xwa
	push xbc
	lda_24 xwa, 0x230636                  ; &0x230636
	push xwa
	call 2731679			; strcpy_len
	lda xsp, (xsp + 10)
	; Null-terminate
	ld16_24 xwa, 0x230436
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
	ld xbc, 2274352
	add xbc, xwa
	push xbc
	lda_24 xwa, 0x230636                  ; &0x230636
	push xwa
	call 2731679
	lda xsp, (xsp + 10)
	sti8_24 0x2306b5, 0x00                 ; (0x2306B5) = 0

.Lff_after_copy2:			; 0x28E40B
	ld16_24 xhl, 0x23043a                 ; HL = (0x23043A) — end position
	sub hl, (xsp + 4)		; HL -= start sector

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
	ld xde, 2274352			; 0x0022B430
	add xde, xbc
	ld c, (xde)			; C = low byte
	ld e, c				; E = C
	extz de				; DE = C (zero-extended)
	extz xwa
	add xwa, 22
	ld xbc, 2274352
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
	ld xde, 2274352
	add xde, xbc
	ld c, (xde)			; C = count byte
	lds32 xhl, 0
	ld l, c				; L = count (initial byte)
	lds ix, 0
	cps ix, 3
	ret nc				; if count >= 3, return early
.Lff_h2_loop:				; 0x28E468
	ld bc, wa
	add bc, ix			; BC = WA + IX
	extz xbc
	add xbc, 22
	ld xde, 2274352
	add xde, xbc
	lds32 xbc, 0
	ld c, (xde)			; C = table byte
	sla xhl, 8			; XHL <<= 8
	add xhl, xbc			; XHL += byte
	inc 1, ix
	cps ix, 3
	jr c, .Lff_h2_loop		; loop while IX < 3
	ret

	; ============================================================
	; Calculate free disk space from sector allocation table
	;
	; Sector Allocation Table (0x22B430, ~20KB):
	;   Each sector's descriptor byte is at table[sector_index + 22].
	;   Descriptors are VarInt-encoded (7-bit payload, bit 7 = continuation).
	;   Special type codes: 0xFF = free, 0x2F = reserved/invalid.
	;   Max addressable sector: 20,457 (0x4FE9).
	;
	; Sub-routine 1 (entry point): Decode VarInt from up to 4 consecutive
	;   table entries starting at table[base_sector + 22]. Accumulates
	;   7-bit chunks into XHL using MSB-first ordering.
	; Sub-routine 2 (.Lcds_find): Encode a bitmap value as VarInt bytes
	;   into a caller-provided buffer.
	;
	; Input: WA = base sector index
	; Output: XHL = decoded free space value, or -1 on overflow
	; Side effect: stores bytes consumed + 1 to (0x23085E)
	; ============================================================
HDAE5000_Calc_Disk_Space:	; 0x28E48B (178 bytes)
	; --- Sub-routine 1: Inline VarInt decode from sector table ---
	lds32 xhl, 0			; XHL = accumulator (decoded value)
	lds ix, 0			; IX = byte index (0-3)
	cps ix, 4			; guard: max 4 bytes per VarInt
	jr nc, .Lcds_overflow
.Lcds_loop:
	; Read descriptor byte: table[base_sector + IX + 22]
	ld bc, wa			; BC = base sector index
	add bc, ix			; BC += byte offset
	extz xbc
	add xbc, 0x00000016		; +22 = descriptor offset within table
	ld xde, 0x0022B430		; XDE = sector allocation table base
	add xde, xbc			; XDE → table[sector + 22]
	ld c, (xde)			; C = descriptor byte
	res 7, c			; strip VarInt continuation bit → 7-bit payload
	ldb b, 0x00
	extz xbc			; XBC = payload (zero-extended)
	add xhl, xbc			; accumulate: XHL += payload
	; Re-read byte to check continuation bit (bit 7)
	ld bc, wa
	add bc, ix
	extz xbc
	add xbc, 0x00000016
	ld xde, 0x0022B430
	add xde, xbc
	cp (xde), 0x80		; bit 7 set? (continuation)
	jr nc, .Lcds_continue		; yes → more bytes follow
	; Continuation=0 → VarInt complete, return decoded value
	ld wa, ix			; WA = bytes consumed (0-based)
	inc 1, wa			; WA = byte count (1-based)
	st16_24 0x23085e, xwa                 ; store bytes consumed to (0x23085E)
	ret				; return XHL = free space value
.Lcds_continue:
	sll xhl, 7			; make room for next 7-bit chunk
	inc 1, ix
	cps ix, 4			; max 4 continuation bytes
	jr c, .Lcds_loop
.Lcds_overflow:
	ld xhl, 0xFFFFFFFF		; overflow: VarInt > 4 bytes
	ret
	; --- Sub-routine 2: Encode value as VarInt into buffer ---
	; Finds how many 7-bit chunks are needed, then serializes
	; MSB-first with bit 7 = continuation on all but last byte.
	; Input: XWA = value to encode, XBC = output buffer pointer
	; Output: HL = 0xFFFF (sentinel)
.Lcds_find:
	; Step 1: Count how many 7-bit chunks are needed
	ld xde, xwa			; XDE = value to encode
	lds hl, 1			; HL = chunk count (start at 1)
	cps hl, 5			; max 5 chunks
	jr nc, .Lcds_apply
.Lcds_search:
	srl xde, 7			; shift out 7 bits
	jr nz, .Lcds_next		; still nonzero? need more chunks
	ld ix, hl			; IX = total chunks needed
	jr t, .Lcds_apply		; done counting
.Lcds_next:
	inc 1, hl
	cps hl, 5
	jr c, .Lcds_search
	; Step 2: Serialize chunks MSB-first into buffer
.Lcds_apply:
	ld xde, xwa			; XDE = value (fresh copy)
	ld hl, ix			; HL = chunk count
	cps hl, 0
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

HDAE5000_Display_Notify:	; 0x28E53D (113 bytes)
	; Validate notification file: read, check header, compare fields
	; Returns XHL = 0 on success, negative error code on failure
	pushw 0x0004			; push mode = 4
	lda_24 xwa, 0x2e5ca2                  ; lda XWA, (0x2E5CA2) - source data
	push xwa			; push source ptr
	lda_24 xwa, 0x22b430                  ; lda XWA, (0x22B430) - dest buffer
	push xwa			; push dest ptr
	call HDAE5000_File_Read
	add xsp, 0x0000000A		; clean up 10 bytes (3 args)
	cps hl, 0			; check read result
	jr z, .Ldn_check1		; if OK, continue validation
	ld xhl, 0xFFFFFFFF		; return -1 (read error)
	ret
.Ldn_check1:
	lds32 xwa, 6			; param = 6
	calr HDAE5000_String_To_Upper	; convert to uppercase
	cpdm32_24 2274356, xhl		; cp (0x22B434), XHL - check header
	jr z, .Ldn_check2		; if match, continue
	ld xhl, 0xFFFFFFFE		; return -2 (header mismatch)
	ret
.Ldn_check2:
	lds wa, 0			; param = 0
	calr HDAE5000_String_Compare
	cpdm16_24 2274360, xhl		; cp (0x22B438), HL
	jr ule, .Ldn_check3		; if <= expected, continue
	ld xhl, 0xFFFFFFFD		; return -3
	ret
.Ldn_check3:
	lds wa, 1			; param = 1
	calr HDAE5000_String_Compare
	cpdm16_24 2274362, xhl		; cp (0x22B43A), HL
	jr ule, .Ldn_check4		; if <= expected, continue
	ld xhl, 0xFFFFFFFC		; return -4
	ret
.Ldn_check4:
	ldw wa, 0x8000			; param = 0x8000
	calr HDAE5000_String_Compare
	ld16_24 xwa, 0x22b43c                 ; ld WA, (0x22B43C)
	and wa, hl			; WA = WA & HL (mask check)
	jr z, .Ldn_ok			; if zero, valid
	ld xhl, 0xFFFFFFFB		; return -5
	ret
.Ldn_ok:
	lds32 xhl, 0			; return 0 (success)
	ret

HDAE5000_Display_Progress:	; 0x28E5AE (59 bytes)
	; Read file and process display progress string
	; Returns XHL = 0 on success, -10 on error
	pushw 0x0004			; push mode = 4
	lda_24 xwa, 0x2e5ca8                  ; lda XWA, 0x2E5CA8 (source data ptr)
	push xwa
	lda_24 xwa, 0x22b43e                  ; lda XWA, 0x22B43E (dest buffer)
	push xwa
	call HDAE5000_File_Read		; read file data
	add xsp, 0x0000000A		; deallocate 10 bytes (3 pushed args)
	cps hl, 0			; check result
	jr z, .LDisplay_Progress__ok
	ld xhl, 0xFFFFFFF6		; return -10 (error)
	ret
.LDisplay_Progress__ok:
	ld32_24 xwa, 0x22b442                 ; ld XWA, (0x22B442) — get result data
	calr HDAE5000_String_To_Upper	; unpack string bytes
	ld xwa, xhl
	add xwa, 0x00000016		; add offset 22
	st32_24 0x2304f2, xwa                 ; ld (0x2304F2), XWA — store processed ptr
	lds32 xhl, 0			; return 0 (success)
	ret

HDAE5000_String_To_Upper:	; 0x28E5E9 (37 bytes)
	; Unpack 32-bit value into sum of byte-shifted components
	; Input: XWA = packed 32-bit value
	; Output: XHL = result (each byte shifted left 8 and added)
	ld xhl, xwa			; copy input
	and xhl, 0x000000FF		; mask lowest byte
	lds de, 0			; loop counter = 0
	cps de, 3			; compare with 3
	ret ge				; return if already done
.LString_To_Upper__loop:
	srl xwa, 8			; next byte
	sll xhl, 8			; shift result left
	ld xbc, xwa
	and xbc, 0x000000FF		; mask byte
	add xhl, xbc			; accumulate
	inc 1, de			; counter++
	cps de, 3
	jr lt, .LString_To_Upper__loop
	ret

HDAE5000_String_Compare:	; 0x28E60E (2397 bytes)
	; Multiply helper + event dispatch function for UI management
	; Handles button events (up/down/enter) and display region setup
	; Dispatches on arg2 (XBC) to 13+ case handlers

	; --- Multiply helper (13 bytes): byte-split multiply ---
	ld hl, wa
	ldb h, 0			; keep low byte only
	srl wa, 8			; WA = high byte
	sll hl, 8			; HL <<= 8
	add hl, wa			; HL = low*256 + high
	ret

	; --- Main dispatch function (2384 bytes) ---
.Lsc_dispatch:
	st_dri3b l, 0xfd, 0x7e, 0xff	; lda XSP, XSP-130 (stack frame)
	push xiz
	ld (xsp + 0x7a), xde		; save arg3
	ld (xsp + 0x7e), xbc		; save arg2
	st_dri3l xwa, 0xfd, 0x82, 0x00	; save arg1 at (XSP+0x82)

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
	ld32_24 xhl, 0x23a1a2
	ld_sril XHL, (xhl + 0x0e0a)             ; vtable base
	ld_sril XHL, (xhl + 0x00dc)             ; method 0x00DC
	call (xhl)

	ld_sril XWA, (xsp + 0x0082)
	ld32_24 xbc, 0x23a1a2
	ld_sril XBC, (xbc + 0x0e0a)
	ld_sril XIX, (xbc + 0x02c4)             ; method 0x02C4
	call (xix)

	ld_sril XWA, (xsp + 0x0082)
	ld32_24 xbc, 0x23a1a2
	ld_sril XBC, (xbc + 0x0e0a)
	ld_sril XHL, (xbc + 0x0100)             ; method 0x0100
	ld xbc, 0x01ca000c
	lds32 xde, 0
	call (xhl)

	ld_sril XWA, (xsp + 0x0082)
	ld32_24 xbc, 0x23a1a2
	ld_sril XBC, (xbc + 0x0e0a)
	ld_sril XHL, (xbc + 0x0100)             ; method 0x0100
	ld xbc, 0x01c0000f
	lds32 xde, 0
	call (xhl)

	lds32 xhl, 0
	jrl t, .Lsc_epilogue

	; ============================================================
	; Case 0x01C00001 — vtable dispatch + display setup
	; ============================================================
.Lsc_case_01:
	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (xsp + 0x7e)
	ld xde, (xsp + 0x7a)
	ld32_24 xhl, 0x23a1a2
	ld_sril XHL, (xhl + 0x0e0a)
	ld_sril XHL, (xhl + 0x00dc)
	call (xhl)

	ld_sril XWA, (xsp + 0x0082)
	ld32_24 xbc, 0x23a1a2
	ld_sril XBC, (xbc + 0x0e0a)
	ld_sril XIX, (xbc + 0x02c4)
	call (xix)

	ld_sril XWA, (xsp + 0x0082)
	ld32_24 xbc, 0x23a1a2
	ld_sril XBC, (xbc + 0x0e0a)
	ld_sril XHL, (xbc + 0x03c8)             ; method 0x03C8
	ld xbc, 0x01c00018
	lds32 xde, 0
	call (xhl)

	ld_sril XWA, (xsp + 0x0082)
	ld32_24 xbc, 0x23a1a2
	ld_sril XBC, (xbc + 0x0e0a)
	ld_sril XHL, (xbc + 0x03cc)             ; method 0x03CC
	ld xbc, 0x01c00017
	lds32 xde, 0
	call (xhl)

	ld32_24 xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XHL, (xwa + 0x03c4)             ; method 0x03C4
	lds wa, 1
	call (xhl)

	pushw 0x002e
	pushw 0x5cae
	pushw 0x0023
	pushw 0x0e7a
	call HDAE5000_MemCopy_Block
	inc 0, xsp			; clean 8 bytes

	ld_sril XWA, (xsp + 0x0082)
	ld32_24 xbc, 0x23a1a2
	ld_sril XBC, (xbc + 0x0e0a)
	ld_sril XHL, (xbc + 0x0100)             ; method 0x0100
	ld xbc, 0x01ea000e
	lds32 xde, 0
	call (xhl)

	sti16_24 0x22a0c8, 0x0021
	sti16_24 0x22a0cc, 0x0118
	sti16_24 0x22a0ca, 0x00c5
	sti16_24 0x22a0ce, 0x00d1
	ld16_24 xwa, 0x22a0c8
	inc 2, wa
	st16_24 0x22a0bc, xwa
	ld16_24 xwa, 0x22a0ca
	inc 3, wa
	st16_24 0x22a0be, xwa

	lds32 xhl, 0
	jrl t, .Lsc_epilogue

	; ============================================================
	; Case 0x01C00002 — simple vtable call
	; ============================================================
.Lsc_case_02:
	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (xsp + 0x7e)
	ld xde, (xsp + 0x7a)
	ld32_24 xhl, 0x23a1a2
	ld_sril XHL, (xhl + 0x0e0a)
	ld_sril XHL, (xhl + 0x00dc)
	call (xhl)
	lds32 xhl, 0
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
	lda_24 xwa, 0x2e5cb0
	ld xde, xwa
	lds32 xwa, 3
	push xwa
	pushw 0x00ff
	pushw 0x00f5
	ld xwa, xhl
	ld32_24 xhl, 0x23a1a2
	ld_sril XHL, (xhl + 0x0e0a)
	ld_sril XHL, (xhl + 0x00c4)             ; method 0x00C4
	call (xhl)

	lda xwa, (xsp + 0x6e)
	ld xix, xwa
	lda xwa, (xsp + 0x76)
	ld xhl, xwa
	ld16_24 xwa, 0x230e78
	add wa, (xsp + 0x04)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	add xbc, xwa
	ld xde, 0x00230884
	add xde, xbc
	lds32 xwa, 3
	push xwa
	pushw 0x00ff
	pushw 0x00f5
	ld xwa, xix
	ld xbc, xhl
	ld32_24 xhl, 0x23a1a2
	ld_sril XHL, (xhl + 0x0e0a)
	ld_sril XHL, (xhl + 0x00c4)
	call (xhl)

	incm 1, (xsp + 0x04)
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
	lda_24 xwa, 0x2e5ccc
	ld xde, xwa
	lds32 xwa, 3
	push xwa
	pushw 0x00ff
	pushw 0x00f5
	ld xwa, xhl
	ld32_24 xhl, 0x23a1a2
	ld_sril XHL, (xhl + 0x0e0a)
	ld_sril XHL, (xhl + 0x00c4)
	call (xhl)

	lda xwa, (xsp + 0x6e)
	ld (xsp + 0x06), xwa
	lda xwa, (xsp + 0x76)
	ld xiz, xwa
	ld16_24 xwa, 0x230e78
	add wa, (xsp + 0x04)
	extz xwa
	ld xbc, 0x0000001b
	call HDAE5000_Multiply
	ld xde, 0x002309f6
	add xde, xhl
	lds32 xwa, 3
	push xwa
	pushw 0x00ff
	pushw 0x00f5
	ld xwa, (xsp + 0x0e)
	ld xbc, xiz
	ld32_24 xhl, 0x23a1a2
	ld_sril XHL, (xhl + 0x0e0a)
	ld_sril XHL, (xhl + 0x00c4)
	call (xhl)

	incm 1, (xsp + 0x04)
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
	ld16_24 xwa, 0x230e78
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
	lda_24 xwa, 0x2e5ce8
	ld xde, xwa
	lds32 xwa, 3
	push xwa
	pushw 0x00ff
	pushw 0x00f5
	ld xwa, xhl
	ld32_24 xhl, 0x23a1a2
	ld_sril XHL, (xhl + 0x0e0a)
	ld_sril XHL, (xhl + 0x00c4)
	call (xhl)
	jr t, .Lsc_0c_loop3end

	; zero: slot empty
.Lsc_0c_z:
	lda xwa, (xsp + 0x6e)
	ld xhl, xwa
	lda xwa, (xsp + 0x76)
	ld xbc, xwa
	lda_24 xwa, 0x2e5cec
	ld xde, xwa
	lds32 xwa, 3
	push xwa
	pushw 0x00ff
	pushw 0x00f5
	ld xwa, xhl
	ld32_24 xhl, 0x23a1a2
	ld_sril XHL, (xhl + 0x0e0a)
	ld_sril XHL, (xhl + 0x00c4)
	call (xhl)

.Lsc_0c_loop3end:
	incm 1, (xsp + 0x04)
	cpw (xsp + 0x04), 0x000c
	jrl c, .Lsc_0c_loop3

.Lsc_0c_done:
	lds32 xhl, 0
	jrl t, .Lsc_epilogue

	; ============================================================
	; Case 0x01C0000F — display region configuration
	; ============================================================
.Lsc_case_0f:
	ld16_24 xwa, 0x230e74
	mul wa, 0x000c
	add wa, 0x0028
	ld (xsp + 0x70), wa
	add wa, 0x000c
	ld (xsp + 0x74), wa

	; Region 1: y=0x14
	ldw (xsp + 0x6e), 0x0014
	sti16_24 0x22a0c0, 0x0014
	ld wa, (xsp + 0x6e)
	add wa, 0x0039
	ld (xsp + 0x72), wa
	st16_24 0x22a0c4, xwa
	lda_24 xwa, 0x22a0c0
	ld32_24 xbc, 0x23a1a2
	ld_sril XBC, (xbc + 0x0e0a)
	ld_sril XHL, (xbc + 0x00a8)             ; method 0x00A8
	ldw bc, 0x00f5
	call (xhl)

	lda xwa, (xsp + 0x6e)
	ld32_24 xbc, 0x23a1a2
	ld_sril XBC, (xbc + 0x0e0a)
	ld_sril XHL, (xbc + 0x00a8)
	ldw bc, 0x00f2
	call (xhl)

	; Region 2: y=0x5C
	ldw (xsp + 0x6e), 0x005c
	sti16_24 0x22a0c0, 0x005c
	ld wa, (xsp + 0x6e)
	add wa, 0x00a2
	ld (xsp + 0x72), wa
	st16_24 0x22a0c4, xwa
	lda_24 xwa, 0x22a0c0
	ld32_24 xbc, 0x23a1a2
	ld_sril XBC, (xbc + 0x0e0a)
	ld_sril XHL, (xbc + 0x00a8)
	ldw bc, 0x00f5
	call (xhl)

	lda xwa, (xsp + 0x6e)
	ld32_24 xbc, 0x23a1a2
	ld_sril XBC, (xbc + 0x0e0a)
	ld_sril XHL, (xbc + 0x00a8)
	ldw bc, 0x00f2
	call (xhl)

	; Region 3: y=0x10C
	ldw (xsp + 0x6e), 0x010c
	sti16_24 0x22a0c0, 0x010c
	ld wa, (xsp + 0x6e)
	add wa, 0x001f
	ld (xsp + 0x72), wa
	st16_24 0x22a0c4, xwa
	lda_24 xwa, 0x22a0c0
	ld32_24 xbc, 0x23a1a2
	ld_sril XBC, (xbc + 0x0e0a)
	ld_sril XHL, (xbc + 0x00a8)
	ldw bc, 0x00f5
	call (xhl)

	lda xwa, (xsp + 0x6e)
	ld32_24 xbc, 0x23a1a2
	ld_sril XBC, (xbc + 0x0e0a)
	ld_sril XHL, (xbc + 0x00a8)
	ldw bc, 0x00f2
	call (xhl)

	; Store current slot bounds
	ld wa, (xsp + 0x70)
	st16_24 0x22a0c2, xwa
	ld wa, (xsp + 0x74)
	st16_24 0x22a0c6, xwa

	; Setup display frame rect
	lda_24 xwa, 0x22a0c8
	ld xhl, xwa
	lda_24 xwa, 0x22a0bc
	ld xbc, xwa
	lda_24 xwa, 0x2e5cf0
	ld xde, xwa
	lds32 xwa, 3
	push xwa
	pushw 0x00ff
	pushw 0x00f5
	ld xwa, xhl
	ld32_24 xhl, 0x23a1a2
	ld_sril XHL, (xhl + 0x0e0a)
	ld_sril XHL, (xhl + 0x00c4)
	call (xhl)

	; String lookup for current slot
	ld16_24 xwa, 0x230e76
	extz xwa
	ld xbc, 0x0000001b
	call HDAE5000_Multiply
	ld xwa, 0x002309f6
	add xwa, xhl
	push xwa
	call HDAE5000_Display_Buffer_Validate
	inc 4, xsp
	cps hl, 0
	jr z, .Lsc_0f_notfound

	; Found: format with name
	ld16_24 xwa, 0x230e76
	extz xwa
	ld xbc, 0x0000001b
	call HDAE5000_Multiply
	ld xwa, 0x002309f6
	add xwa, xhl
	push xwa
	pushw 0x0023
	pushw 0x0e7a
	pushw 0x002e
	pushw 0x5d22
	lda xwa, (xsp + 0x16)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda xsp, (xsp + 0x10)
	jr t, .Lsc_0f_merge

	; Not found: format with slot index
.Lsc_0f_notfound:
	ld16_24 xwa, 0x230e76
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
	pushw 0x5d28
	lda xwa, (xsp + 0x16)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda xsp, (xsp + 0x10)

.Lsc_0f_merge:
	lda_24 xwa, 0x22a0c8
	ld xhl, xwa
	lda_24 xwa, 0x22a0bc
	ld xbc, xwa
	lda xwa, (xsp + 0x0a)
	ld xde, xwa
	lds32 xwa, 3
	push xwa
	pushw 0x00ff
	pushw 0x00f5
	ld xwa, xhl
	ld32_24 xhl, 0x23a1a2
	ld_sril XHL, (xhl + 0x0e0a)
	ld_sril XHL, (xhl + 0x00c4)
	call (xhl)

	lds32 xhl, 0
	jrl t, .Lsc_epilogue

	; ============================================================
	; Case 0x01EA000E — memory initialization + path builder
	; ============================================================
.Lsc_case_0e:
	sti16_24 0x230e76, 0x0000
	sti16_24 0x230e78, 0x0000
	sti16_24 0x230e72, 0x0000
	sti16_24 0x230e74, 0x0000

	pushw 0x0171
	pushw 0x0000
	lda_24 xwa, 0x230884
	push xwa
	call HDAE5000_MemFill
	pushw 0x0453
	pushw 0x0000
	lda_24 xwa, 0x2309f6
	push xwa
	call HDAE5000_MemFill
	pushw 0x0028
	pushw 0x0000
	lda_24 xwa, 0x230e4a
	push xwa
	call HDAE5000_MemFill
	lda xsp, (xsp + 0x18)		; clean 24 bytes (3 calls x 8)

	calr HDAE5000_Path_Builder
	lds32 xhl, 0
	jrl t, .Lsc_epilogue

	; ============================================================
	; Cases 0x01EA000F/0010/0011 — return 0
	; ============================================================
.Lsc_case_0f_ea:
	lds32 xhl, 0
	jrl t, .Lsc_epilogue
.Lsc_case_10_ea:
	lds32 xhl, 0
	jrl t, .Lsc_epilogue
.Lsc_case_11_ea:
	lds32 xhl, 0
	jrl t, .Lsc_epilogue

	; ============================================================
	; Case 0x01C00017 — vtable call + send message 0x01C00007
	; ============================================================
.Lsc_case_17:
	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (xsp + 0x7e)
	ld xde, (xsp + 0x7a)
	ld32_24 xhl, 0x23a1a2
	ld_sril XHL, (xhl + 0x0e0a)
	ld_sril XHL, (xhl + 0x00dc)
	call (xhl)

	ld_sril XWA, (xsp + 0x0082)
	ld32_24 xbc, 0x23a1a2
	ld_sril XBC, (xbc + 0x0e0a)
	ld_sril XHL, (xbc + 0x0100)
	ld xbc, 0x01c00007
	lds32 xde, 3
	call (xhl)

	; ============================================================
	; Default case — vtable call + forward to case_01
	; ============================================================
.Lsc_default:
	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (xsp + 0x7e)
	ld xde, (xsp + 0x7a)
	ld32_24 xhl, 0x23a1a2
	ld_sril XHL, (xhl + 0x0e0a)
	ld_sril XIX, (xhl + 0x00dc)
	call (xix)
	jrl t, .Lsc_epilogue

	; ============================================================
	; Case 0x01C00018 — vtable calls + send 0x01C00007 with flag
	; ============================================================
.Lsc_case_18:
	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (xsp + 0x7e)
	ld xde, (xsp + 0x7a)
	ld32_24 xhl, 0x23a1a2
	ld_sril XHL, (xhl + 0x0e0a)
	ld_sril XHL, (xhl + 0x00dc)
	call (xhl)

	ld_sril XWA, (xsp + 0x0082)
	ld32_24 xbc, 0x23a1a2
	ld_sril XBC, (xbc + 0x0e0a)
	ld_sril XHL, (xbc + 0x0100)
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
	add xwa, 0x002e5d38		; byte lookup table
	ld wa, (xwa)
	extz wa
	sll wa, 1			; word offset
	ld xix, 0x002e5d48		; offset table base
	ld_sriw3 wa, 0x07, 0xf0, 0xe0	; WA = (XIX+WA) — load jump offset
	lda_24 xix, 0x28ed79		; base = .Lsc_07_btn_down
	jp_dri 8, 0x07, 0xf0, 0xe0	; jp T, XIX+WA

	; --- Down button handler ---
.Lsc_07_btn_down:
	cpdi16_24 0x230e76, 0x0000
	jr nz, .Lsc_down_nz
	ld xhl, 0xffffffff		; return -1
	jrl t, .Lsc_epilogue

.Lsc_down_nz:
	decdi16_24 1, 0x230e76		; slot_index--
	cpdi16_24 0x230e74, 0x0000
	jr nz, .Lsc_down_74nz

	; page_offset == 0: check scroll_offset
	cpdi16_24 0x230e78, 0x0000
	jr nz, .Lsc_down_78nz
	ld xhl, 0xffffffff
	jrl t, .Lsc_epilogue

.Lsc_down_78nz:
	decdi16_24 1, 0x230e78
	ld_sril XWA, (xsp + 0x0082)
	ld32_24 xbc, 0x23a1a2
	ld_sril XBC, (xbc + 0x0e0a)
	ld_sril XHL, (xbc + 0x0100)
	ld xbc, 0x01c0000d
	lds32 xde, 0
	call (xhl)
	jr t, .Lsc_down_merge

.Lsc_down_74nz:
	decdi16_24 1, 0x230e74
	ld_sril XWA, (xsp + 0x0082)
	ld32_24 xbc, 0x23a1a2
	ld_sril XBC, (xbc + 0x0e0a)
	ld_sril XHL, (xbc + 0x0100)
	ld xbc, 0x01c0000f
	lds32 xde, 0
	call (xhl)

.Lsc_down_merge:
	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (xsp + 0x7e)
	ld xde, (xsp + 0x7a)
	ld32_24 xhl, 0x23a1a2
	ld_sril XHL, (xhl + 0x0e0a)
	ld_sril XHL, (xhl + 0x042c)             ; method 0x042C
	call (xhl)
	jrl t, .Lsc_ret0

	; --- Up button handler ---
.Lsc_07_btn_up:
	ld16_24 xwa, 0x230e72
	dec 1, wa
	cpdm16_24 0x230e76, xwa		; compare slot_index with limit
	jr c, .Lsc_up_ok
	ld xhl, 0xffffffff
	jrl t, .Lsc_epilogue

.Lsc_up_ok:
	incdi16_24 1, 0x230e76
	cpdi16_24 0x230e74, 0x000b
	jr c, .Lsc_up_inc74

	; page_offset >= 11: scroll
	incdi16_24 1, 0x230e78
	ld_sril XWA, (xsp + 0x0082)
	ld32_24 xbc, 0x23a1a2
	ld_sril XBC, (xbc + 0x0e0a)
	ld_sril XHL, (xbc + 0x0100)
	ld xbc, 0x01c0000d
	lds32 xde, 0
	call (xhl)
	jr t, .Lsc_up_merge

.Lsc_up_inc74:
	incdi16_24 1, 0x230e74
	ld_sril XWA, (xsp + 0x0082)
	ld32_24 xbc, 0x23a1a2
	ld_sril XBC, (xbc + 0x0e0a)
	ld_sril XHL, (xbc + 0x0100)
	ld xbc, 0x01c0000f
	lds32 xde, 0
	call (xhl)

.Lsc_up_merge:
	ld_sril XWA, (xsp + 0x0082)
	ld xbc, (xsp + 0x7e)
	ld xde, (xsp + 0x7a)
	ld32_24 xhl, 0x23a1a2
	ld_sril XHL, (xhl + 0x0e0a)
	ld_sril XHL, (xhl + 0x042c)
	call (xhl)
	jrl t, .Lsc_ret0

	; --- Enter/Select button handler ---
.Lsc_07_btn_enter:
	ld32_24 xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e88)             ; (XWA+0x0E88) status obj
	ld xix, (xwa + 0x08)
	call (xix)			; get status
	cps l, 3
	jr z, .Lsc_enter_active
	cps l, 2
	jrl nz, .Lsc_enter_skip

.Lsc_enter_active:
	ld32_24 xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XHL, (xwa + 0x0538)             ; method 0x0538
	call (xhl)

	ld16_24 xwa, 0x230e76
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	add xbc, xwa
	ld xwa, 0x00230884
	add xwa, xbc
	push xwa			; slot data address
	lda xwa, (xsp + 0x0e)
	push xwa			; format buffer
	call HDAE5000_MemCopy_Block
	pushw 0x002e
	pushw 0x5d2e
	lda xwa, (xsp + 0x16)
	push xwa
	call HDAE5000_StrCopy
	lda xsp, (xsp + 0x10)		; clean 16 bytes

	lda xwa, (xsp + 0x0a)
	lda_24 xbc, 0x2e5d34
	ld32_24 xde, 0x23a1a2
	ld_sril XDE, (xde + 0x0e88)
	ld_sril XHL, (xde + 0x00a0)             ; method 0x00A0
	call (xhl)

	lda_24 xwa, 0x22b430
	ld32_24 xbc, 0x23a1a2
	ld_sril XBC, (xbc + 0x0e88)
	ld_sril XHL, (xbc + 0x00a8)
	ld xbc, 0x00005000
	call (xhl)

	ld32_24 xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e88)
	ld_sril XHL, (xwa + 0x00ac)             ; method 0x00AC
	call (xhl)

	ld32_24 xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XHL, (xwa + 0x053c)             ; method 0x053C
	call (xhl)

.Lsc_enter_skip:
	ld32_24 xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XHL, (xwa + 0x0124)             ; method 0x0124
	ld xwa, 0x007f02f0
	ld xbc, 0x01c00001
	lds32 xde, 0
	call (xhl)

	; ============================================================
	; Epilogue
	; ============================================================
.Lsc_ret0:
	lds32 xhl, 0
.Lsc_epilogue:
	pop xiz
	st_dri3b l, 0xfd, 0x82, 0x00	; lda XSP, XSP+130 (restore stack)
	ret

HDAE5000_Path_Builder:	; 0x28EF6B (556 bytes)
	; Build file path strings using vtable dispatch
	; Scans directory entries, builds path strings, validates filenames
	; Uses nested vtable calls through (0x23A1A2) + offsets

	; --- Prologue: allocate ~370 bytes of stack ---
	st_dri3b l, 0xfd, 0x8e, 0xfe	; lda XSP, XSP-370
	push xiz			; save XIZ
	lds32 xwa, 0
	ld (xsp + 4), xwa		; local[0x04] = 0 (result)

	; --- Get vtable, call method at +0x08 via XIX ---
	ld32_24 xwa, 0x23a1a2                 ; XWA = (0x23A1A2) — vtable base
	ld_sril xwa, (xwa + 0x0e88)             ; XWA = (XWA + 0x0E88)
	ld xix, (xwa + 8)		; XIX = (XWA + 0x08) — method ptr
	call (xix)			; call method
	cps l, 3			; if L != 3
	jr z, .Lpb_continue		;   (L==3 → continue)
	cps l, 2			; if L != 2 either
	jrl nz, .Lpb_exit		;   return

.Lpb_continue:				; 0x28EF8E
	; --- Call vtable method at +0x0538 ---
	ld32_24 xwa, 0x23a1a2                 ; XWA = (0x23A1A2)
	ld_sril xwa, (xwa + 0x0e0a)             ; XWA = (XWA + 0x0E0A)
	ld_sril xhl, (xwa + 0x0538)             ; XHL = (XWA + 0x0538)
	call (xhl)

	; --- Call vtable method at +0x0090, get XIZ ---
	ld32_24 xwa, 0x23a1a2                 ; XWA = (0x23A1A2)
	ld_sril xwa, (xwa + 0x0e88)             ; XWA = (XWA + 0x0E88)
	ld_sril xhl, (xwa + 0x0090)             ; XHL = (XWA + 0x0090)
	call (xhl)
	ld xiz, xhl			; XIZ = result

	; --- If XIZ != 0: get strlen, copy to buffer ---
	ld xwa, xiz
	or xwa, xwa			; test zero
	jr z, .Lpb_empty_path		; if zero, clear buffer

	ld xwa, xiz
	push xwa
	call 2731889			; strlen(XIZ)
	pushw hl			; push strlen
	ld xwa, xiz
	push xwa
	lda_24 xwa, 0x230e7a                  ; XWA = &0x230E7A (path buffer)
	push xwa
	call 2731679			; call 0x29AE9F (strcpy with length)
	lda xsp, (xsp + 14)		; pop 14 bytes
	jr t, .Lpb_after_path

.Lpb_empty_path:			; 0x28EFD2
	sti8_24 0x230e7a, 0x00                 ; (0x230E7A) = '\0'

.Lpb_after_path:			; 0x28EFD8
	sti8_24 0x230e82, 0x00                 ; (0x230E82) = '\0'
	lda_24 xwa, 0x230e7a                  ; XWA = &0x230E7A
	push xwa
	call 2731889			; strlen(path buffer)
	inc 4, xsp
	cps hl, 0			; if strlen > 0
	jr z, .Lpb_no_separator		;   skip separator append

	; Append separator
	pushw 46			; max = 0x2E
	pushw 23888			; src = 0x5D50 (separator string)
	pushw 35			; offset = 0x23
	pushw 3706			; dest = 0x0E7A
	call 2731787			; call 0x29AF0B (strcat)
	inc 0, xsp

.Lpb_no_separator:			; 0x28F000
	; --- Call vtable method at +0x0094 to scan directory ---
	lda_24 xwa, 0x2e5d54                  ; XWA = 0x2E5D54 (param)
	ld xde, xwa
	lda xwa, (xsp + 8)		; XWA = &local[0x08]
	ld xbc, xwa
	ld xwa, xde			; restore XWA
	ld32_24 xde, 0x23a1a2                 ; XDE = (0x23A1A2)
	ld_sril xde, (xde + 0x0e88)             ; XDE = (XDE + 0x0E88)
	ld_sril xhl, (xde + 0x0094)             ; XHL = (XDE + 0x0094)
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
	ld32_24 xde, 0x23a1a2                 ; XDE = (0x23A1A2)
	ld_sril xde, (xde + 0x0e88)             ; XDE = (XDE + 0x0E88)
	ld_sril xix, (xde + 0x0098)             ; XIX = (XDE + 0x0098)
	call (xix)
	cps hl, 0
	jr z, .Lpb_retry		; if HL == 0, retry

	; --- Call vtable method at +0x009C ---
	ld xwa, xiz
	ld32_24 xbc, 0x23a1a2                 ; XBC = (0x23A1A2)
	ld_sril xbc, (xbc + 0x0e88)             ; XBC = (XBC + 0x0E88)
	ld_sril xhl, (xbc + 0x009c)             ; XHL = (XBC + 0x009C)
	call (xhl)

	; --- Directory entry loop ---
	lds iz, 0			; IZ = 0 (loop counter)
	cpda16_24 xiz, 2297458		; cp IZ, (0x230E72) — entry count
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
	st_dri3b w, 0xfd, 0x16, 0x01	; lda XWA, XSP+0x0116
	push xwa
	call 2731845			; call 0x29AF45 (memcpy)

	; Append separator string
	pushw 46			; max = 0x2E
	pushw 23896			; src = 0x5D58
	st_dri3b w, 0xfd, 0x1e, 0x01	; lda XWA, XSP+0x011E
	push xwa
	call 2731787			; call 0x29AF0B (strcat)
	lda xsp, (xsp + 16)		; pop 16 bytes

	; --- Call vtable method at +0x00A0 (display entry) ---
	st_dri3b w, 0xfd, 0x12, 0x01	; lda XWA, XSP+0x0112
	lda_24 xbc, 0x2e5d5e                  ; XBC = 0x2E5D5E
	ld32_24 xde, 0x23a1a2                 ; XDE = (0x23A1A2)
	ld_sril xde, (xde + 0x0e88)             ; XDE = (XDE + 0x0E88)
	ld_sril xhl, (xde + 0x00a0)             ; XHL = (XDE + 0x00A0)
	call (xhl)

	; --- Compute entry index * 27, add to base ---
	ld wa, iz
	extz xwa
	ld xbc, 27			; 0x1B
	call 2733869			; call 0x29B72D (multiply)
	ld xwa, 2296310			; XWA = 0x002309F6
	add xwa, xhl			; XWA = base + IZ*27

	; --- Call vtable method at +0x00A8 ---
	ld32_24 xbc, 0x23a1a2                 ; XBC = (0x23A1A2)
	ld_sril xbc, (xbc + 0x0e88)             ; XBC = (XBC + 0x0E88)
	ld_sril xhl, (xbc + 0x00a8)             ; XHL = (XBC + 0x00A8)
	ld xbc, 26			; 0x1A
	call (xhl)

	; --- Call vtable method at +0x00AC ---
	ld32_24 xwa, 0x23a1a2                 ; XWA = (0x23A1A2)
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x00ac)             ; XHL = (XWA + 0x00AC)
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
	st_dri3b w, 0xfd, 0x16, 0x01	; lda XWA, XSP+0x0116
	push xwa
	call 2731845			; memcpy
	pushw 46
	pushw 23906			; src = 0x5D62
	st_dri3b w, 0xfd, 0x1e, 0x01	; lda XWA, XSP+0x011E
	push xwa
	call 2731787			; strcat
	lda xsp, (xsp + 16)		; pop 16 bytes

	; --- Call vtable method at +0x00A0 via XIX ---
	st_dri3b w, 0xfd, 0x12, 0x01	; lda XWA, XSP+0x0112
	lda_24 xbc, 0x2e5d68                  ; XBC = 0x2E5D68
	ld32_24 xde, 0x23a1a2                 ; XDE = (0x23A1A2)
	ld_sril xde, (xde + 0x0e88)
	ld_sril xix, (xde + 0x00a0)             ; XIX = (XDE + 0x00A0)
	call (xix)

	; --- Check result and set flag ---
	cps hl, 0
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
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x00ac)
	call (xhl)

	; --- Loop control ---
	inc 1, iz			; IZ++
	cpda16_24 xiz, 2297458		; cp IZ, (0x230E72)
	jrl c, .Lpb_entry_loop		; if IZ < count, loop

.Lpb_loop_done:				; 0x28F17C
	; --- Call vtable method at +0x053C (finalize) ---
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x053c)             ; XHL = (XWA + 0x053C)
	call (xhl)

.Lpb_exit:				; 0x28F18D
	; --- Epilogue: return result and deallocate ---
	ld xhl, (xsp + 4)		; XHL = result
	pop xiz				; restore XIZ
	st_dri3b l, 0xfd, 0x72, 0x01	; lda XSP, XSP+0x0172
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
	call HDAE5000_MemCopy_Block			; format string
	lda xwa, (xsp + 0x3e)
	push xwa
	call 0x29b01b			; parse name
	lda xwa, (xsp + 0x42)
	push xwa
	call 0x29b04e			; validate
	pushw 0x0004
	pushw 0x002e
	pushw 0x5d6c
	lda xwa, (xsp + 0x4c)
	push xwa
	call HDAE5000_MemCompare_Block			; search/match
	add xsp, 0x0000001a		; clean 26 bytes
	cps hl, 0
	jrl nz, .Ldh_ret0

	; Check max entries
	cpdi16_24 0x230e72, 0x0028
	jr c, .Ldh_under_limit
	ld xhl, 0xffffffff		; return -1 (full)
	jrl t, .Ldh_epilogue

.Ldh_under_limit:
	lda xwa, (xsp + 0x36)
	push xwa
	call 0x29b01b
	lda xwa, (xsp + 0x3a)
	push xwa
	lda xwa, (xsp + 0x0c)
	push xwa
	call HDAE5000_MemCopy_Block
	lda xwa, (xsp + 0x10)
	push xwa
	call HDAE5000_Display_Buffer_Validate			; string compare
	lda xsp, (xsp + 0x10)		; clean 16 bytes
	dec 4, hl
	ld wa, hl
	extz xwa
	lda xbc, (xsp + 0x04)
	add xbc, xwa
	ld (xbc), 0x00		; null-terminate

	; First entry? (count == 0)
	cpdi16_24 0x230e72, 0x0000
	jr nz, .Ldh_search

	; Direct insert at slot 0
	lda xwa, (xsp + 0x04)
	push xwa
	lda_24 xwa, 0x230884
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp			; clean 8 bytes
	incdi16_24 1, 0x230e72
	lds32 xhl, 0
	jrl t, .Ldh_epilogue

	; Sorted insertion search
.Ldh_search:
	ldi_werp 0xfa, 0		; QIZ = 0 (search index)
	ldto_werp wa, 0xfa		; WA = QIZ
	cpda16_24 xwa, 0x230e72	; compare QIZ with count
	jrl nc, .Ldh_append

.Ldh_search_loop:
	ldto_werp wa, 0xfa		; WA = QIZ
	muls wa, 0x0009			; slot offset = QIZ * 9
	lda_24 xbc, 0x230884
	exts xwa
	add xwa, xbc			; XWA = slot address
	push xwa
	lda xwa, (xsp + 0x08)
	push xwa
	call HDAE5000_Code_Remainder			; string compare
	inc 0, xsp			; clean 8 bytes
	cps hl, 0
	jr ge, .Ldh_next_slot

	; Found insert position — shift entries down
	ld16_24 xiz, 0x230e72		; IZ = total count
	cp_werp iz, 0xfa		; compare IZ with QIZ
	jr le, .Ldh_do_insert

	; Shift loop: move entries [QIZ..IZ-1] down by one slot
.Ldh_shift_loop:
	ld wa, iz
	muls wa, 0x0009
	lda_24 xbc, 0x23087b		; offset -9 from table base (src)
	exts xwa
	add xwa, xbc
	push xwa			; source
	ld wa, iz
	muls wa, 0x0009
	lda_24 xbc, 0x230884		; table base (dst)
	exts xwa
	add xwa, xbc
	push xwa			; destination
	call HDAE5000_MemCopy_Block			; copy 9-byte entry
	inc 0, xsp
	dec 1, iz
	cp_werp iz, 0xfa
	jr gt, .Ldh_shift_loop

.Ldh_do_insert:
	lda xwa, (xsp + 0x04)
	push xwa
	ldto_werp wa, 0xfa
	muls wa, 0x0009
	lda_24 xbc, 0x230884
	exts xwa
	add xwa, xbc
	push xwa
	call HDAE5000_MemCopy_Block			; copy entry to insert position
	inc 0, xsp
	incdi16_24 1, 0x230e72
	lds32 xhl, 0
	jr t, .Ldh_epilogue

.Ldh_next_slot:
	inc1_werp 0xfa			; QIZ++
	ldto_werp wa, 0xfa
	cpda16_24 xwa, 0x230e72
	jrl c, .Ldh_search_loop

	; Append at end (no sorted position found)
.Ldh_append:
	lda xwa, (xsp + 0x04)
	push xwa
	ld16_24 xwa, 0x230e72
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	add xbc, xwa
	ld xwa, 0x00230884
	add xwa, xbc
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp
	incdi16_24 1, 0x230e72
	lds32 xhl, 0
	jr t, .Ldh_epilogue

.Ldh_ret0:
	lds32 xhl, 0
.Ldh_epilogue:
	pop xiz
	lda xsp, (xsp + 0x64)		; restore stack (+100)
	ret

	; ============================================================
	; Event code matcher — check for 0x01E0009F
	; ============================================================
HDAE5000_Dir_Event_Check:	; 0x28F2F7
	cp xbc, 0x01e0009f
	jr nz, .Ldec_no
	lda_24 xhl, 0x2e5d72
	ret
.Ldec_no:
	lds32 xhl, 0
	ret

	; ============================================================
	; Format + ROM region setup helper
	; ============================================================
HDAE5000_Dir_Format_Setup:	; 0x28F308
	lda	xsp, (xsp-24)
	push xiz
	ld xiz, xbc			; save XBC in XIZ
	ld (xsp + 0x18), xwa		; save arg1
	pushw 0x002e
	pushw 0x5dc6
	lda xwa, (xsp + 0x08)
	push xwa
	call HDAE5000_MemCopy_Block
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
	; ============================================================
HDAE5000_Dir_Flush:		; 0x28F343
	ld32_24 xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XHL, (xwa + 0x0538)             ; method 0x0538
	call (xhl)
	lds hl, 0
	ret

	; ============================================================
	; Vtable helper: call method 0x053C (close), return HL=0
	; ============================================================
HDAE5000_Dir_Close:		; 0x28F357
	ld32_24 xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XHL, (xwa + 0x053c)             ; method 0x053C
	call (xhl)
	lds hl, 0
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
	lds hl, 0			; HL = byte count

	; --- Phase 1: Extract 7-bit chunks LSB-first into temp buffer ---
.Lve_extract:
	lda xde, (xsp + 0x00)		; XDE = temp buffer base on stack
	ld xwa, xix
	and xwa, 0x0000007f		; extract low 7 bits of remaining value
	lda_dri3 xbc, 0x07, 0xe8, 0xec	; temp[HL] = A (store 7-bit chunk)
	srl xix, 7			; shift remaining value right by 7
	inc 1, hl			; HL = chunk count
	or xix, xix			; any bits left?
	jr nz, .Lve_extract		; loop until value fully consumed

	; --- Phase 2: Reverse chunks into output, set continuation bits ---
	; temp[] has chunks in LSB-first order; output needs MSB-first
	lds ix, 1			; IX = reverse index (skip first temp byte)
	cp ix, hl			; only one chunk? skip to last
	jr ge, .Lve_copy_last

.Lve_set_msb:
	ld wa, hl
	sub wa, ix			; WA = count - reverse_index
	ld de, wa
	dec 1, de			; DE = output position
	lda xwa, (xsp + 0x00)
	ld_srib3 a, 0x07, 0xe0, 0xf0	; A = temp[IX] — load chunk (MSB-first order)
	set 7, a			; set continuation bit (more bytes follow)
	lda_dri3 xbc, 0x07, 0xe4, 0xe8	; output[DE] = A — store to caller's buffer
	inc 1, ix
	cp ix, hl
	jr lt, .Lve_set_msb

	; --- Phase 3: Copy final byte WITHOUT continuation bit ---
.Lve_copy_last:
	ld de, hl
	dec 1, de			; DE = last output position
	ld8_src_rid8 xsp, 0x00, a		; A = temp[0] — LSB chunk (becomes last output byte)
	lda_dri3 xbc, 0x07, 0xe4, 0xe8	; output[DE] = A (bit 7 clear = final byte)
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
	lds ix, 0			; IX = byte index
	lds32 xhl, 0			; XHL = accumulator

	ld a, (xde)			; A = first byte (for length check)
	ldfr_berp a, 0xf4		; IYL = A (save first byte)

.Lvd_loop:
	ld_srib3 a, 0x07, 0xe8, 0xf0	; A = data[IX] — load current byte
	res 7, a			; strip continuation bit → 7-bit payload
	ldb w, 0			; W = 0
	extz xwa			; XWA = payload (zero-extended to 32-bit)
	add xhl, xwa			; accumulate: XHL += payload

	bit_dri 7, 0x07, 0xe8, 0xf0	; test continuation bit of data[IX]
	jr nz, .Lvd_continue
	; Continuation=0 → this was the last byte, decoding complete
	ldto_berp a, 0xf0		; A = IXL (byte index)
	inc 1, a			; A = bytes consumed
	ld (xbc), a			; store byte count to caller's pointer
	ret

.Lvd_continue:
	; Continuation=1 → more bytes follow
	inc 1, ix			; advance to next byte
	sll xhl, 7			; make room for next 7-bit chunk
	cps ix, 4
	jr le, .Lvd_length_check
	cpi_berp 0xf4, 7		; if first byte > 7 and >4 bytes: invalid
	jr ugt, .Lvd_error

.Lvd_length_check:
	cps ix, 5			; max 5 bytes (35 bits for 32-bit values)
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
	ldb h, 0x00			; clear H (keep L = low byte of WA)
	srl wa, 8			; WA >>= 8 (high byte to low)
	sll hl, 8			; HL <<= 8 (low byte to high)
	ldb w, 0x00			; clear W
	add hl, wa			; HL = (orig_low << 8) + orig_high
	ret
.Lec_main:				; 0x28F447 — extension check entry
	push xiz
	ld xiz, xwa			; save parameter in XIZ
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril xwa, (xwa + 0x0e88)             ; ld XWA, (XWA+0x0E88) — handler table
	ld xix, (xwa + 8)		; ld XIX, (XWA+0x08)
	call (xix)			; call validation handler
	cps l, 3			; check result == 3?
	jr z, .Lec_process		; if so, process extension
	cps l, 2			; check result == 2?
	jr nz, .Lec_finish		; if neither 2 nor 3, skip to end
.Lec_process:
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2)
	ld_sril xwa, (xwa + 0x0e0a)             ; ld XWA, (XWA+0x0E0A) — sub-handler table
	ld_sril xhl, (xwa + 0x0538)             ; ld XHL, (XWA+0x0538)
	call (xhl)
	ld xwa, xiz			; restore parameter
	lda_24 xbc, 0x2e5dca                  ; lda XBC, 0x2E5DCA — extension data ptr
	ld32_24 xde, 0x23a1a2                 ; ld XDE, (0x23A1A2)
	ld_sril xde, (xde + 0x0e88)             ; ld XDE, (XDE+0x0E88)
	ld_sril xhl, (xde + 0x00a0)             ; ld XHL, (XDE+0x00A0)
	call (xhl)
	lda_24 xwa, 0x230eac                  ; lda XWA, 0x230EAC
	ld32_24 xbc, 0x23a1a2                 ; ld XBC, (0x23A1A2)
	ld_sril xbc, (xbc + 0x0e88)             ; ld XBC, (XBC+0x0E88)
	ld_sril xhl, (xbc + 0x00a8)             ; ld XHL, (XBC+0x00A8)
	ld xbc, 0x0000000E		; count = 14
	call (xhl)
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2)
	ld_sril xwa, (xwa + 0x0e88)             ; ld XWA, (XWA+0x0E88)
	ld_sril xhl, (xwa + 0x00ac)             ; ld XHL, (XWA+0x00AC)
	call (xhl)
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2)
	ld_sril xwa, (xwa + 0x0e0a)             ; ld XWA, (XWA+0x0E0A)
	ld_sril xhl, (xwa + 0x053c)             ; ld XHL, (XWA+0x053C)
	call (xhl)
.Lec_finish:
	lda_24 xwa, 0x230eac                  ; lda XWA, 0x230EAC
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
	st16_24 0x230eba, xhl                 ; ld (0x230EBA), HL
	cpdi16_24 2297530, 0x0001	; cp (0x230EBA), 1
	jr ule, .Lci_check3		; if <= 1, continue
	ld xhl, 0xFFFFFFFD		; return -3
	jr t, .Lci_exit
.Lci_check3:
	ld wa, (xiz + 10)		; load field at offset 0x0A
	calr HDAE5000_Extension_Check
	st16_24 0x230ebc, xhl                 ; ld (0x230EBC), HL
	ld wa, (xiz + 12)		; load field at offset 0x0C
	calr HDAE5000_Extension_Check
	st16_24 0x230ebe, xhl                 ; ld (0x230EBE), HL
	ld16_24 xwa, 0x230ebe                 ; ld WA, (0x230EBE)
	bit 15, wa			; test bit 15
	jr z, .Lci_ok			; if not set, success
	ld xhl, 0xFFFFFFFC		; return -4
	jr t, .Lci_exit
.Lci_ok:
	lds32 xhl, 0			; return 0 (success)
.Lci_exit:
	pop xiz
	ret

HDAE5000_Alloc_Memory:	; 28F543h
	; Memory/display parameter lookup routine
	; Input: XBC = request type (0x01E000A1, A2, or A3)
	; Output: XHL = result based on type:
	;   A1 -> 0x2E61CE (ROM palette data pointer)
	;   A2 -> 0x140 (320 decimal - display width)
	;   A3 -> 0xF0 (240 decimal - display height)
	;   else -> 0 (invalid type)
	cp xbc, 0x1E000A3	; Check for type A3
	jr z, HDAE5000_Alloc_Memory__type_A3
	cp xbc, 0x1E000A2	; Check for type A2
	jr z, HDAE5000_Alloc_Memory__type_A2
	cp xbc, 0x1E000A1	; Check for type A1
	jr z, HDAE5000_Alloc_Memory__type_A1
	lds32 xhl, 0	; Invalid type - return 0
	ret
HDAE5000_Alloc_Memory__type_A1:
	lda_24 xhl, 0x2e61ce                  ; Return palette data pointer
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
	ld8_24 l, 0x230eda
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
;   3. Loads VGA palette from ROM at 0x2E5DCE
;   4. Allocates 0x12C00 bytes and copies VRAM data from 0x1A0000
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
	; (EQU→inline label) HDAE5000_GFX_DATA_1 = 0x2A5D2C
	; (EQU→inline label) HDAE5000_GFX_DATA_2 = 0x2A6984
	; (EQU→inline label) HDAE5000_GFX_INIT_PARAMS = 0x2A849A

; ROM data addresses
	; (EQU→inline label) HDAE5000_Palette_Data = 0x2E5DCE
	; (EQU→inline label) HDAE5000_Display_Params = 0x2F8DCE

; All routine addresses are now exposed as labels in split binary sections

; PPORT state machine handler (in code_28f90c_2953e1.bin)
	; (EQU→inline label) HDAE5000_PPORT_Handler = 0x29501C

; PPORT command handler addresses (in code_295642_2fffff.bin)
	; (EQU→inline label) HDAE5000_Cmd01_SendInfo = 0x2958D6
	; (EQU→inline label) HDAE5000_Cmd02_Exit = 0x295914
	; (EQU→inline label) HDAE5000_Cmd03_ReadFSB = 0x2959F6
	; (EQU→inline label) HDAE5000_Cmd04_SendFSB = 0x295D3C
	; (EQU→inline label) HDAE5000_Cmd05_RcvFSB = 0x29605A
	; (EQU→inline label) HDAE5000_Cmd06_WriteFSB = 0x296294
	; (EQU→inline label) HDAE5000_PPORT_Cmd_LoadHDtoMemory = 0x29632A
	; (EQU→inline label) HDAE5000_PPORT_Cmd_SendDataBlock = 0x29633C
	; (EQU→inline label) HDAE5000_PPORT_Cmd_SendFileList = 0x2964A6
	; (EQU→inline label) HDAE5000_PPORT_Cmd_ReceiveDataBlock = 0x296588
	; (EQU→inline label) HDAE5000_PPORT_Cmd_WriteMemoryToHD = 0x29659A
	; (EQU→inline label) HDAE5000_PPORT_Cmd_Reserved = 0x296680

HDAE5000_Boot_Init:	; 28F576h
	push xiz
	ld xiz, xwa	; XIZ = workspace pointer from main CPU

	calr HDAE5000_Clear_Work_Buffer	; Clear 0xF52A bytes at 0x22A000

	st32_24 0x23a1a2, xiz                 ; Store workspace pointer

	call HDAE5000_Handler_Registration	; Register handlers with main CPU

	lda_24 xwa, 0x2e5dce                  ; Load palette data address
	calr HDAE5000_Load_Palette	; Load 256-entry VGA palette

	; Allocate memory for VRAM copy
	lds32 xwa, 0
	ld xbc, 0x1E000A1	; Allocation type A1
	lds32 xde, 0
	calr HDAE5000_Alloc_Memory	; Returns address in XHL
	ld xiz, xhl	; XIZ = allocated buffer

	; Copy from allocated buffer to VRAM area 1 (0x1A0000, size 0x9600)
	pushw 0x9600	; push 9600h (16-bit immediate)
	ld xwa, xiz
	push xwa	; Source
	ld xwa, 0x1A0000	; Destination
	push xwa
	call HDAE5000_MemCopy

	; Copy from allocated buffer + offset to VRAM area 2 (0x1A9600)
	pushw 0x9600	; push 9600h (16-bit immediate)
	ld xwa, xiz
	add xwa, 0x9600	; Source + offset
	push xwa
	ld xwa, 0x1A9600	; Destination
	push xwa
	call HDAE5000_MemCopy

	lda xsp, (xsp + 20)	; Clean stack (5 pushes × 4 bytes = 20)

	; === Create DISK MENU slot ===
	; Call workspace[0x0E0A][0x02C4] to register a DISK MENU entry.
	; Returns XHL = pointer to menu slot structure.
	ld32_24 xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)             ; Handler table A
	ld_sril XIX, (xwa + 0x02c4)             ; DISK MENU slot registration function
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
	lda_24 xwa, 0x2f8dce
	ld (xhl + 42), xwa	; Display name shown in DISK MENU
	;
	; NOTE: slot+0x32 (icon ID) is NOT set here.
	; The firmware uses a default icon for HDAE5000.

	; === Initialize callback pointers via Handler Table B ===
	; Table B is at workspace[+0x0E88].
	; Each call returns a callback pointer stored in local RAM.
	; These pointers are used by Frame_Handler to monitor state changes.
	;
	; Handler 1: status monitor (used to check bit 2 for display init)
	ld32_24 xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e88)             ; Handler table B
	ld_sril XHL, (xwa + 0x0108)             ; Get callback via table B offset +0x0108
	call (xhl)
	st32_24 0x230ecc, xhl                 ; Store at 0x230ECC

	; Handler 2: display offset calculator (state value read for display offset)
	ld32_24 xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e88)
	ld_sril XHL, (xwa + 0x0100)             ; Table B offset +0x0100
	call (xhl)
	st32_24 0x230ed2, xhl                 ; Store at 0x230ED2

	; Handler 3: display state reader (state byte shifted for offset calc)
	ld32_24 xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e88)
	ld_sril XHL, (xwa + 0x0104)             ; Table B offset +0x0104
	call (xhl)
	st32_24 0x230ed6, xhl                 ; Store at 0x230ED6

	; Check for hard disk presence
	call HDAE5000_Check_HD_Present
	st8_24 0x230eda, l                    ; Store result

	cps l, 0
	jr z, HDAE5000_Boot_Init__skip_hd_init	; Skip if no HD

	; Hard disk present - initialize it
	ld32_24 xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XHL, (xwa + 0x0124)             ; HD init function
	ld xwa, 0xFFFFFFFF	; Full init
	ld xbc, 0x1C00016	; HD initialization parameters
	ld xde, 0x1A0007F	; Buffer
	call (xhl)

HDAE5000_Boot_Init__skip_hd_init:
	call HDAE5000_Finalize_Init	; Final setup
	call HDAE5000_Register_Frame	; Register frame handler

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
	; 1. Check workspace pointer at 0x23A19E (skip if -1)
	; 2. Read handler states from 0x230ED2, 0x230ED6
	; 3. Calculate display offset = (WA * 3) << 2, store at 0x230EC6
	; 4. Call registered callback via workspace[0x0E0A][0x0124]
	;
	ld32_24 xwa, 0x23a19e                 ; Load secondary workspace pointer
	cp xwa, 0xFFFFFFFF	; Check if uninitialized (-1)
	jr z, HDAE5000_Frame_Handler_Status	; Skip to status check if no workspace
	;
	; Calculate display offset from handler states
	ld32_24 xwa, 0x230ed6                 ; Load handler 3 pointer
	ld a, (xwa)	; Read state byte
	srl a, 3	; srl 3, A  ; divide by 8
	ld e, a	; Save in E
	;
	ld32_24 xwa, 0x230ed2                 ; Load handler 2 pointer
	ld wa, (xwa)	; Read state word
	extz xwa	; Zero-extend to 32-bit
	ld xbc, xwa	; XBC = state value
	add xbc, xbc	; XBC *= 2
	add xbc, xwa	; XBC *= 3 (total: state * 3)
	sll xbc, 2	; sll 2, XBC  ; XBC *= 4 (total: state * 12)
	lds32 xwa, 0	; Clear XWA
	ld a, e	; Restore shifted value
	inc 2, xwa	; inc 2, XWA  ; Add 2 (?) to low word
	add xwa, xbc	; Combine offsets
	st32_24 0x230ec6, xwa                 ; Store calculated display offset
	;
	; Check if state changed
	inc 1, e	; inc 1, E
	ld a, e
	extz wa
	cpda16_24 xwa, 2297540	; Compare with previous state
	jr z, HDAE5000_Frame_Handler_Status	; Skip if unchanged
	;
	; State changed - update and call callback
	ld a, e
	extz wa
	st16_24 0x230ec4, xwa                 ; Update state variable
	ld32_24 xwa, 0x230ed2                 ; Load handler 2 pointer
	ld wa, (xwa)	; Read state
	st16_24 0x230ec2, xwa                 ; Store in temp
	lda_24 xwa, 0x230ec2                  ; Load address of temp
	ld xbc, xwa	; XBC = temp address
	ld32_24 xwa, 0x23a19e                 ; Secondary workspace pointer
	ld xde, xbc	; XDE = temp address
	ld32_24 xbc, 0x23a1a2                 ; Main workspace pointer
	ld_sril XBC, (xbc + 0x0e0a)             ; Handler table A
	ld_sril XHL, (xbc + 0x0124)             ; Get callback function
	ld xbc, 0x1CA0004	; Display state update callback
	call (xhl)	; Call callback if valid

HDAE5000_Frame_Handler_Status:	; 28F6E0h
	; Frame handler status check section
	; Monitors handler 1 status bit 2, triggers display init when it transitions to 0
	;
	ld32_24 xwa, 0x230ecc                 ; Load handler 1 pointer
	ld a, (xwa)	; Read status byte
	and a, 0x4	; Isolate bit 2
	cpda8_24 a, 2297552	; Compare with previous state
	jrl z, HDAE5000_Frame_Handler_Exit	; jrl Z, Frame_Handler_Exit  ; Skip if unchanged
	;
	; Status changed - update previous state
	st8_24 0x230ed0, a                    ; Store new state
	cps a, 0	; Check if bit 2 now clear
	jrl nz, HDAE5000_Frame_Handler_Exit	; jrl NZ, Frame_Handler_Exit  ; Skip if bit still set
	;
	; Bit 2 cleared - check if display init needed
	call HDAE5000_Get_Status_Byte	; Call status check routine
	cps l, 1	; Check return value
	jr nz, HDAE5000_Frame_Handler_Exit	; Skip if not 1
	;
	; Initialize display - call workspace callback
	ld32_24 xwa, 0x23a1a2                 ; Main workspace pointer
	ld_sril XWA, (xwa + 0x0e0a)             ; Handler table A
	ld_sril XIX, (xwa + 0x0278)             ; Get display callback
	call (xix)	; Call if valid
	cp xhl, 0x1A0007F	; Check return value
	jr z, HDAE5000_Frame_Handler_Status__init_display	; If match, do full init
	;
	; Partial update
	lds wa, 1
	call HDAE5000_Set_Status_Byte	; Call update routine
	ldw wa, 0x7F
	call HDAE5000_Menu_Register_B	; Call UI update
	jr HDAE5000_Frame_Handler_Exit
	;
HDAE5000_Frame_Handler_Status__init_display:
	; Full display initialization sequence
	ld32_24 xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XHL, (xwa + 0x0124)             ; Init callback 1
	ld xwa, 0x7F013E	; Display params
	ld xbc, 0x1C00001	; Display initialization flags
	lds32 xde, 0
	call (xhl)
	;
	ld32_24 xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XHL, (xwa + 0x0534)             ; Init callback 2
	ld xwa, 0x7F013E
	ld xbc, 0x1CA0000
	call (xhl)
	;
	ld32_24 xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XHL, (xwa + 0x0124)             ; Init callback 3
	ld xwa, 0x7F013E
	ld xbc, 0x1CA0000
	lds32 xde, 0
	call (xhl)

HDAE5000_Frame_Handler_Exit:	; 28F781h
	; Exit frame handler by jumping to PPORT handler
	jp HDAE5000_PPORT_Handler

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
	stiw_dpi 0xE9, 0x00, 0x00	; ld (XDE+), 0x0000  ; store first word
	dec 1, xbc	; dec 1, XBC
	or xbc, xbc
	jr z, HDAE5000_Clear_Work_Buffer__clear_done
	mriw2 0x93, 0x11	; ldirw  ; copy words (fills with zeros)
	cpi_werp 0xE6, 0	; cp QBC, 0  ; check high word
	jr z, HDAE5000_Clear_Work_Buffer__clear_done
	ldto_werp WA, 0xE6	; ld WA, QBC  ; get high word count
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
	cpi_werp 0xE6, 0	; cp QBC, 0
	jr z, HDAE5000_Clear_Work_Buffer__copy_done
	ldto_werp WA, 0xE6	; ld WA, QBC
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
	cps iz, 0	; initial check
	jr lt, HDAE5000_Load_Palette__done	; skip loop if IZ < 0 (never happens here)
HDAE5000_Load_Palette__loop:
	ldto_berp E, 0xF8	; E = current palette index
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

HDAE5000_Display_Init:	; 28F90Ch (114 bytes)
	; Display and callback initialization
	; Registers callbacks via workspace function tables
	; Input: WA = display mode (1 = with sub-handlers)
	dec 2, xsp			; allocate 2 bytes on stack
	pushw iz			; save IZ
	ld iz, wa			; IZ = mode parameter
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2) — workspace pointer
	ld_sril xwa, (xwa + 0x0e88)             ; ld XWA, (XWA+0x0E88) — display handler table
	ld_sril xhl, (xwa + 0x00e8)             ; ld XHL, (XWA+0x00E8) — init callback
	lds wa, 1			; WA = 1
	call (xhl)			; call init callback
	cps iz, 1			; mode == 1?
	jr nz, .Ldi_skip1		; skip sub-handler if not
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2)
	ld_sril xwa, (xwa + 0x0e0a)             ; ld XWA, (XWA+0x0E0A) — sub-handler table
	ld_sril xhl, (xwa + 0x0538)             ; ld XHL, (XWA+0x0538) — sub-handler callback
	call (xhl)			; call sub-handler
.Ldi_skip1:
	call HDAE5000_Display_String_Render
	ld (xsp + 2), hl		; save result on stack
	cps iz, 1			; mode == 1?
	jr nz, .Ldi_skip2		; skip sub-handler if not
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2)
	ld_sril xwa, (xwa + 0x0e0a)             ; ld XWA, (XWA+0x0E0A)
	ld_sril xhl, (xwa + 0x053c)             ; ld XHL, (XWA+0x053C) — post-render callback
	call (xhl)			; call post-render sub-handler
.Ldi_skip2:
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2)
	ld_sril xwa, (xwa + 0x0e88)             ; ld XWA, (XWA+0x0E88)
	ld_sril xhl, (xwa + 0x00ec)             ; ld XHL, (XWA+0x00EC) — cleanup callback
	call (xhl)			; call cleanup
	ld32_24 xwa, 0x23a1a2                 ; ld XWA, (0x23A1A2)
	ld_sril xwa, (xwa + 0x0e88)             ; ld XWA, (XWA+0x0E88)
	ld_sril xhl, (xwa + 0x00f0)             ; ld XHL, (XWA+0x00F0) — final callback
	call (xhl)			; call final callback
	ld hl, (xsp + 2)		; restore result from stack
	popw iz				; restore IZ
	inc 2, xsp			; deallocate 2 bytes
	ret

HDAE5000_Calc_Offset_16:	; 0x28F97E (13 bytes)
	; Calculate 16-byte offset in table at 0x201632
	; Input: WA = table index
	; Output: XHL = pointer to 16-byte entry
	extz xwa		; zero-extend index to 32 bits
	sll xwa, 4		; multiply by 16
	ld xhl, 0x201632	; table base address
	add xhl, xwa		; XHL = base + index*16
	ret

HDAE5000_Copy_To_Table:	; 0x28F98B (34 bytes)
	; Copy 16 bytes to table entry, then call Display_Callback
	; Input: WA = table index, XBC = source pointer, DE = param
	pushw iz
	ld iz, de			; save DE param
	pushw 0x0010			; push 16 (byte count)
	push xbc			; push source pointer
	extz xwa			; zero-extend index
	sll xwa, 4			; index * 16
	ld xbc, 0x00201632		; table base
	add xbc, xwa			; XBC = dest ptr
	push xbc			; push dest pointer
	call HDAE5000_MemCopy_Reverse	; memcpy(dest, src, 16)
	lda xsp, (xsp + 0x0A)		; deallocate 10 bytes
	ld wa, iz			; restore param
	calr HDAE5000_Display_Callback
	popw iz
	ret

HDAE5000_Get_Display_Dimensions_A1_2F:	; 0x28F9AD (62 bytes)
	; Check if tile entry matches reference; return 0 or -1
	; Input: WA = tile index, Output: HL = 0 (match) or 0xFFFF (mismatch)
	push xiz		; save XIZ
	ld iz, wa		; IZ = tile index
	ld	qiz, 0
	pushw 0x002F		; push max length (47)
	pushw 0x8DE0		; push reference string address
	call HDAE5000_Display_Buffer_Validate
	pushw hl		; push reference length
	pushw 0x002F		; push max length
	pushw 0x8DE0		; push reference string
	ld wa, iz		; restore tile index
	extz xwa		; zero-extend
	sll xwa, 4		; XWA *= 16
	ld xbc, 0x00201632	; table base address
	add xbc, xwa		; XBC = base + index*16
	push xbc		; push tile address
	call HDAE5000_MemCompare_Block
	add xsp, 0x0000000E	; clean up 14 bytes
	cps hl, 0		; check compare result
	jr nz, .Lgdd_done	; skip if mismatch
	ldw	qiz, 0xffff
.Lgdd_done:
	ld	hl, qiz
	pop xiz			; restore XIZ
	ret

HDAE5000_Count_Invalid_Cells:	; 0x28F9EB (51 bytes)
	; Count how many of 16 tile entries are invalid (-1)
	; Input: WA = row param, Output: HL = count of invalid entries
	dec 2, xsp		; allocate 2 bytes
	push xiz		; save XIZ
	ld (xsp + 4), wa	; save WA param on stack
	lds iz, 0		; IZ = 0 (invalid counter)
	ld	qiz, 0
	cpw	qiz, 0x0010
	jr nc, .Lcic_done	; if >= 16, done
.Lcic_loop:
	ld wa, (xsp + 4)	; restore WA param
	ld	bc, qiz
	calr HDAE5000_Table_Calc_Offset
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

HDAE5000_Calculate_Row_Address:	; 0x28FA1E (56 bytes)
	; Calculate table address: base + row*1216 + 1920 + col*76
	; Input: WA = row, BC = column
	; Output: XHL = pointer to entry
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
	ld xhl, 0x00201632	; table base address
	add xhl, xwa		; XHL = base + total_offset
	popw iz			; restore IZ
	inc 4, xsp		; deallocate 4 bytes
	ret

HDAE5000_Copy_Display_Cell:	; 0x28FA56 (74 bytes)
	; Copy table entry using row*1216 + 1920 + col*76 addressing, then callback
	; Input: WA = row, BC = column, stack+2 = copy size
	dec 4, xsp		; allocate 4 bytes
	pushw iz		; save IZ
	ld iz, wa		; IZ = row
	pushw 0x001A		; push 26 (entry size)
	push xde		; push dest pointer
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
	ld xwa, 0x00201632	; table base address
	add xwa, xhl		; XWA = base + total_offset
	push xwa		; push source pointer
	call HDAE5000_MemCopy_Reverse
	lda xsp, (xsp + 0x0A)	; deallocate 10 bytes
	ld wa, (xsp + 0x0A)	; load copy size param from stack
	calr HDAE5000_Display_Callback
	popw iz			; restore IZ
	inc 4, xsp		; deallocate 4 bytes
	retd 0x0002		; return and pop 2 bytes

HDAE5000_Calculate_Tile_Address:	; 0x28FAA0 (26 bytes)
	; Calculate tile address: base + index * 0x90 (144)
	; Input: WA = tile index
	; Output: XHL = pointer to tile entry
	; Algorithm: index*144 = index*(128+16) = (index<<3 + index)<<4
	extz xwa		; zero-extend index to 32 bits
	ld xbc, xwa		; XBC = index
	sll xbc, 3		; XBC = index * 8
	add xbc, xwa		; XBC = index * 9
	sll xbc, 4		; XBC = index * 144
	add xbc, 0x00024180	; add tile table offset
	ld xhl, 0x201632	; table base address
	add xhl, xbc		; XHL = base + offset
	ret

HDAE5000_Copy_Display_Cell_90:	; 0x28FABA (47 bytes)
	; Copy entry with 0x90 stride: base + index*144 + 0x24180, then callback
	; Input: WA = tile index, DE = callback param
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
	ld xwa, 0x00201632	; table base address
	add xwa, xbc		; XWA = base + offset
	push xwa		; push source pointer
	call HDAE5000_MemCopy_Reverse	; copy 16 bytes
	lda xsp, (xsp + 0x0A)	; deallocate 10 bytes
	ld wa, iz		; restore callback param
	calr HDAE5000_Display_Callback
	popw iz			; restore IZ
	ret

HDAE5000_Validate_Cell_Coords:	; 0x28FAE9 (61 bytes)
	; Compare tile entry with reference, return 0 if valid or -1 if invalid
	; Input: WA = tile index
	; Output: HL = 0 (valid) or 0xFFFF (invalid)
	dec 2, xsp		; allocate 2 bytes for result
	pushw iz		; save IZ
	ld iz, wa		; IZ = tile index
	ldw (xsp + 2), 0x0000	; result = 0 (valid)
	pushw 0x002F		; push max length (47)
	pushw 0x8DF2		; push reference string address
	call HDAE5000_Display_Buffer_Validate
	inc 4, xsp		; clean up 2 args
	pushw hl		; push reference length
	pushw 0x002F		; push max length
	pushw 0x8DF2		; push reference string address
	ld wa, iz		; restore tile index
	calr HDAE5000_Calculate_Tile_Address	; XHL = tile address
	push xhl		; push tile address (32-bit)
	call HDAE5000_MemCompare_Block
	add xsp, 0x0000000A	; clean up 10 bytes
	cps hl, 0		; compare result
	jr nz, .Lvcc_done	; if not equal, valid (keep 0)
	ldw (xsp + 2), 0xFFFF	; mark invalid (-1)
.Lvcc_done:
	ld hl, (xsp + 2)	; load result
	popw iz			; restore IZ
	inc 2, xsp		; deallocate 2 bytes
	ret

HDAE5000_Resolve_Cell_Address:	; 0x28FB26 (139 bytes)
	; Get entry address with validation; returns XHL = entry ptr or error ptr
	; Input: WA = row, BC = column
	; Output: XHL = pointer to entry (or fallback if invalid)
	dec 4, xsp		; allocate 4 bytes
	pushw iz		; save IZ
	ld iz, bc		; IZ = column
	ld (xsp + 4), wa	; save row on stack
	; First: validate the cell
	ld wa, (xsp + 4)	; WA = row
	ld bc, iz		; BC = column
	calr HDAE5000_Cell_In_Bounds
	cp hl, 0xFFFF		; invalid?
	jr z, .Lrca_fail	; if -1, use fallback address
	; Calculate row offset: look up row dimension table at 0x2257E2
	ld bc, iz		; BC = column
	extz xbc		; zero-extend column
	ld wa, (xsp + 4)	; WA = row
	extz xwa		; zero-extend row
	ld xde, xwa		; XDE = row
	sll xde, 3		; XDE = row * 8
	add xde, xwa		; XDE = row * 9
	sll xde, 4		; XDE = row * 144
	add xde, xbc		; XDE = row*144 + col
	lda_24 xwa, 0x2257e2                  ; lda XWA, (0x2257E2) - row dimension table
	add xwa, xde		; XWA = table + row*144 + col
	ld a, (xwa)		; A = dimension value
	dec 1, a		; A -= 1
	extz wa			; zero-extend A to WA
	muls wa, 0x004C		; WA = (dim-1) * 76
	ld (xsp + 2), wa	; save row_offset
	; Calculate column offset: look up col dimension table at 0x2257C2
	ld bc, iz		; BC = column
	extz xbc		; zero-extend
	ld wa, (xsp + 4)	; WA = row
	extz xwa		; zero-extend
	ld xde, xwa		; XDE = row
	sll xde, 3		; XDE = row * 8
	add xde, xwa		; XDE = row * 9
	sll xde, 4		; XDE = row * 144
	add xde, xbc		; XDE = row*144 + col
	lda_24 xwa, 0x2257c2                  ; lda XWA, (0x2257C2) - col dimension table
	add xwa, xde		; XWA = table + index
	ld a, (xwa)		; A = col dimension
	dec 1, a		; A -= 1
	ldb w, 0x00		; W = 0 (zero-extend A to WA manually)
	extz xwa		; zero-extend WA to XWA
	ld xbc, 0x000004C0	; multiplier = 1216
	call HDAE5000_Multiply	; XHL = col_dim * 1216
	add xhl, 0x780		; XHL += 1920
	ld wa, (xsp + 2)	; WA = row_offset
	exts xwa		; sign-extend WA to XWA
	add xwa, xhl		; XWA = total offset
	ld xhl, 0x00201632	; table base address
	add xhl, xwa		; XHL = final entry address
	jr t, .Lrca_done	; jump to epilogue
.Lrca_fail:
	lda_24 xhl, 0x2f8e04                  ; lda XHL, (0x2F8E04) - fallback/error address
.Lrca_done:
	popw iz			; restore IZ
	inc 4, xsp		; deallocate 4 bytes
	ret

; ============================================================================
; Display Table Management and UI Cell Rendering (0x28FBB1-0x295008)
; 21,592 bytes, 50 routines
;
; Table operations use 0x4C (76) byte stride for row addressing
; and 0x90 (144) byte stride for tile addressing.
; Eight routines at 0x2934C8-0x293BB8 are exactly 222 bytes each,
; likely one per UI cell/widget type.
; ============================================================================

HDAE5000_Cell_In_Bounds:	; 0x28FBB1 (1497 bytes)
	; Validate entry at coordinates; calculates table offset
; LCIB: 0x28FBB1 (1497 bytes)

	lds	hl, 0
	ld	ix, bc
	extz xix                                ; extz XIX
	ld	de, wa
	extz xde                                ; extz XDE
	ld	xiy, xde
	sll	xiy, 0x03
	add	xiy, xde
	sll	xiy, 0x04
	add	xiy, xix
	lda_24 xde, 0x2257c2
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
	lda_24 xwa, 0x2257e2
	add	xwa, xde
	cp	(xwa), 0x00
	ret nz                                  ; ret NZ

.LCIB_fbef:
	ldw	hl, 0xffff
	ret

	dec	6, xsp
	pushw iz                                ; push IZ
	ld (xsp + 0x02), xde                    ; ld (XSP+0x02),XDE
	ld	iz, bc
	ld (xsp + 0x06), wa                     ; ld (XSP+0x06),WA
	ld	wa, (xsp+6)
	ld	bc, iz
	calr	0xffab
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
	lda_24 xwa, 0x2257c2
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
	lda_24 xwa, 0x2257e2
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
	lda_24 xwa, 0x225802
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
	lda_24 xwa, 0x225822
	ld	xbc, xwa
	add	xbc, xde
	ld xwa, (xsp + 0x02)                    ; ld XWA,(XSP+0x02)
	ld	c, (xbc)
	ld	(xwa+5), c
.LCIB_fcae:
	popw iz                                 ; pop IZ
	inc	6, xsp
	ret

	ld	hl, bc
	extz xhl                                ; extz XHL
	ld	de, wa
	extz xde                                ; extz XDE
	ld	xix, xde
	sll	xix, 0x03
	add	xix, xde
	sll	xix, 0x04
	add	xix, xhl
	lda_24 xde, 0x2257c2
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
	lda_24 xde, 0x2257e2
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
	lda_24 xde, 0x225802
	add	xde, xix
	ld	(xde), 0x00
	extz xbc                                ; extz XBC
	extz xwa
	ld	xde, xwa
	sll	xde, 0x03
	add	xde, xwa
	sll	xde, 0x04
	add	xde, xbc
	lda_24 xwa, 0x225822
	add	xwa, xde
	ld	(xwa), 0x00
	lds	hl, 0
	ret

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
	lda_24 xiy, 0x2257c2
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
	lda_24 xbc, 0x2257c2
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
	lda_24 xiy, 0x2257e2
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
	lda_24 xbc, 0x2257e2
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
	lda_24 xiy, 0x225802
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
	lda_24 xbc, 0x225802
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
	lda_24 xiy, 0x225822
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
	lda_24 xbc, 0x225822
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
	lda_24 xbc, 0x201661
	add	xbc, xde
	ld	(xbc), 0x00
	ld	bc, wa
	extz xbc                                ; extz XBC
	ld	xde, xbc
	sll	xde, 0x03
	add	xde, xbc
	sll	xde, 0x04
	add	xde, 0x00024180
	lda_24 xbc, 0x201681
	add	xbc, xde
	ld	(xbc), 0x00
	ld	bc, wa
	extz xbc                                ; extz XBC
	ld	xde, xbc
	sll	xde, 0x03
	add	xde, xbc
	sll	xde, 0x04
	add	xde, 0x00024180
	lda_24 xbc, 0x2016a1
	add	xbc, xde
	ld	(xbc), 0x00
	extz xwa
	ld	xbc, xwa
	sll	xbc, 0x03
	add	xbc, xwa
	sll	xbc, 0x04
	add	xbc, 0x00024180
	lda_24 xwa, 0x2016c1
	add	xwa, xbc
	ld	(xwa), 0x00
	lds	hl, 0
	ret

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
	lda_24 xiz, 0x2257c2
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
	lda_24 xde, 0x2257c2
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
	lda_24 xiz, 0x2257e2
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
	lda_24 xde, 0x2257e2
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
	lda_24 xiz, 0x225802
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
	lda_24 xde, 0x225802
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
	lda_24 xiz, 0x225822
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
	lda_24 xde, 0x225822
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
	lda_24 xde, 0x2257c2
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
	lda_24 xde, 0x2257e2
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
	lda_24 xde, 0x225802
	add	xde, xix
	ld	(xde), 0x00
	extz xbc                                ; extz XBC
	extz xwa
	ld	xde, xwa
	sll	xde, 0x03
	add	xde, xwa
	sll	xde, 0x04
	add	xde, xbc
	lda_24 xwa, 0x225822
	add	xwa, xde
	ld	(xwa), 0x00
	lds	hl, 0
	pop xiz                                 ; pop XIZ
	ret

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
	lda_24 xwa, 0x2257c2
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
	lda_24 xwa, 0x2257e2
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
	lda_24 xwa, 0x225802
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
	lda_24 xwa, 0x225822
	ld	xbc, xwa
	add	xbc, xhl
	ld	a, (xde+5)
	ld	(xbc), a
	ld	wa, (xsp+4)
	calr	0x3d6f
	retd 0x0002		; retd 0x0002

	extz xbc                                ; extz XBC
	extz xwa
	ld	xhl, xwa
	sll	xhl, 0x03
	add	xhl, xwa
	sll	xhl, 0x04
	add	xhl, xbc
	lda_24 xwa, 0x2257c2
	ld	xbc, xwa
	add	xbc, xhl
	ld	a, e
	inc	1, a
	ld	(xbc), a
	lds	hl, 0
	ret

	extz xbc                                ; extz XBC
	extz xwa
	ld	xhl, xwa
	sll	xhl, 0x03
	add	xhl, xwa
	sll	xhl, 0x04
	add	xhl, xbc
	lda_24 xwa, 0x2257e2
	ld	xbc, xwa
	add	xbc, xhl
	ld	a, e
	inc	1, a
	ld	(xbc), a
	lds	hl, 0
	ret

	dec	4, xsp
	pushw iz                                ; push IZ
	ld	(xsp+2), e
	ld	iz, bc
	ld (xsp + 0x04), wa                     ; ld (XSP+0x04),WA
	ld	wa, (xsp+4)
	ld	bc, iz
	calr	0xfa98
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
	lda_24 xwa, 0x225802
	ld	xbc, xwa
	add	xbc, xde
	ld	a, (xsp+2)
	ld	(xbc), a
.LCIB_0144:
	popw iz                                 ; pop IZ
	inc 4, xsp                              ; inc 4,XSP
	ret

	dec	4, xsp
	pushw iz                                ; push IZ
	ld	(xsp+2), e
	ld	iz, bc
	ld (xsp + 0x04), wa                     ; ld (XSP+0x04),WA
	ld	wa, (xsp+4)
	ld	bc, iz
	calr	0xfa56
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
	lda_24 xwa, 0x225822
	ld	xbc, xwa
	add	xbc, xde
	ld	a, (xsp+2)
	ld	(xbc), a
.LCIB_0186:
	popw iz                                 ; pop IZ
	inc 4, xsp                              ; inc 4,XSP
	ret


HDAE5000_Table_Calc_Offset:	; 0x29018A (553 bytes)
	; Check 9 table slots for availability (-1 = free)
	; WA = row index, BC = column index
	; Returns HL=0 if any slot occupied, HL=0xFFFF if all free
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
	lda_24 xwa, 0x201656                  ; 0x201656
	add xwa, xhl
	ld xwa, (xwa)			; load slot value
	cp xwa, 0xFFFFFFFF		; free?
	jr z, .Ltco_slot1
	lds hl, 0			; occupied → return 0
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
	lda_24 xwa, 0x20165a                  ; 0x20165A
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_slot2
	lds hl, 0
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
	lda_24 xwa, 0x20165e                  ; 0x20165E
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_slot3
	lds hl, 0
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
	lda_24 xwa, 0x201662                  ; 0x201662
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_slot4
	lds hl, 0
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
	lda_24 xwa, 0x201666                  ; 0x201666
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_slot5
	lds hl, 0
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
	lda_24 xwa, 0x20166a                  ; 0x20166A
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_slot6
	lds hl, 0
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
	lda_24 xwa, 0x20166e                  ; 0x20166E
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_slot7
	lds hl, 0
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
	lda_24 xwa, 0x201672                  ; 0x201672
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_slot8
	lds hl, 0
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
	lda_24 xwa, 0x201676                  ; 0x201676
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_all_free
	lds hl, 0
	jr .Ltco_exit
.Ltco_all_free:
	ldw hl, 0xFFFF			; all slots free
.Ltco_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_Table_Lookup:	; 0x2903B3 (928 bytes)
	; Part 1: Build occupied-slot bitmask (bits 0-8)
	; WA = row, BC = column. Returns HL = bitmask or 0xFFFF if all free.
	dec 6, xsp
	push xiz
	ld (xsp + 6), bc		; save column
	ld (xsp + 8), wa		; save row
	ldw (xsp + 4), 0x0000		; init bitmask = 0
	; First check if ALL slots are free (call Table_Calc_Offset)
	ld wa, (xsp + 8)
	ld bc, (xsp + 6)
	calr HDAE5000_Table_Calc_Offset
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
	lda_24 xwa, 0x201656                  ; 0x201656
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
	lda_24 xwa, 0x20165a                  ; 0x20165A
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
	lda_24 xwa, 0x20165e                  ; 0x20165E
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
	lda_24 xwa, 0x201662                  ; 0x201662
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
	lda_24 xwa, 0x201666                  ; 0x201666
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
	lda_24 xwa, 0x20166a                  ; 0x20166A
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
	lda_24 xwa, 0x20166e                  ; 0x20166E
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
	lda_24 xwa, 0x201672                  ; 0x201672
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
	lda_24 xwa, 0x201676                  ; 0x201676
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
	; IZ = entry ID, DE = param, BC = flags
	dec 4, xsp
	push xiz
	ld (xsp + 4), de		; save DE
	ld (xsp + 6), bc		; save BC (flags)
	ld iz, wa			; IZ = bitmask
	; Workspace handler init
	ld32_24 xwa, 0x23a1a2                 ; (0x23A1A2)
	ld_sril xwa, (xwa + 0x0e88)             ; XWA = (XWA+0x0E88)
	ld_sril xhl, (xwa + 0x00e8)             ; XHL = (XWA+0x00E8)
	lds wa, 1
	call (xhl)
	; Conditional extra handler (if BC == 1)
	cpw (xsp + 14), 0x0001
	jr nz, .Ltl2_skip_extra
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0538)
	call (xhl)
.Ltl2_skip_extra:
	call 0x297466
	; Test bits 0-8, calling Cell_Render subroutines
	ld wa, (xsp + 4)		; reload DE (bitmask param)
	; --- Bit 0 ---
	bit 0, wa
	jr z, .Ltl2_bit1
	ld wa, iz
	ld bc, (xsp + 6)
	calr HDAE5000_Table_Sub_290753
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
	calr HDAE5000_Table_Sub_2908B1
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
	calr HDAE5000_Table_Sub_290A00
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
	calr HDAE5000_Table_Sub_290B86
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
	calr HDAE5000_Table_Sub_290CB5
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
	calr HDAE5000_Table_Sub_290D91
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
	calr HDAE5000_Table_Sub_290EC0
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
	calr HDAE5000_Table_Sub_290F45
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
	calr HDAE5000_Table_Sub_29103D
	ld qiz, hl		; ld QIZ, HL
	; --- Final workspace cleanup ---
.Ltl2_final:
	cpw (xsp + 12), 0x0001	; check param
	call_24 nz, 2716853		; call nz, 0x2974B5
	cpw (xsp + 14), 0x0001	; check BC == 1?
	jr nz, .Ltl2_skip_final
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x053c)
	call (xhl)
.Ltl2_skip_final:
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x00ec)
	call (xhl)
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x00f0)
	call (xhl)
	ld hl, qiz		; ld HL, QIZ (load from previous-bank)
	pop xiz
	inc 4, xsp
	retd 4

HDAE5000_Table_Sub_290753:	; 0x290753 (350 bytes)
	lda xsp, (xsp - 28)
	push xiz
	ld (xsp + 28), bc	; save file number
	ld (xsp + 30), wa	; save partition
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
	lda_24 xwa, 0x201656                  ; 0x201656 (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lts907_load	; entry doesn't exist, result stays 0
	; Workspace dispatch with WA=0 (buffer at xsp+20)
	lda xwa, (xsp + 20)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2                 ; 0x23A1A2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)
	lds wa, 0
	call (xhl)
	; Workspace dispatch with WA=1 (buffer at xsp+12)
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)
	lds wa, 1
	call (xhl)
	; Compute arg and call Cell_Get_Params
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	calr HDAE5000_Cell_Get_Params
	ld (xsp + 4), xhl
	; Workspace dispatch (d8 displacement 0x0C)
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 12)	; (XWA+0x0C)
	call (xhl)
	; Save workspace ptr
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
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
	lda_24 xwa, 0x201656                  ; 0x201656
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	call 0x29811C
	ld (xsp + 10), hl	; save result
	; Call 0x29AE9F with args (first)
	ld xwa, (xsp + 24)
	pushw wa
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
	push xwa
	ld xwa, (xsp + 26)
	push xwa
	call HDAE5000_MemCopy
	; Call 0x29AE9F with args (second)
	ld xwa, (xsp + 26)
	pushw wa
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
	add xwa, (xsp + 36)
	push xwa
	ld xwa, (xsp + 28)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 20)	; clean up pushed args
	; Read metadata FROM table and store to globals
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	ld xbc, 0x00230F1C
	add xbc, xwa
	ld a, (xbc)
	st8_24 0x22b2f4, a                    ; (0x22B2F4)
	; Read at offset+1
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	inc 1, xwa
	ld xbc, 0x00230F1C
	add xbc, xwa
	ld a, (xbc)
	st8_24 0x23a0a0, a                    ; (0x23A0A0)
	; Read at offset+2
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	inc 2, xwa
	ld xbc, 0x00230F1C
	add xbc, xwa
	ld a, (xbc)
	st8_24 0x23a09e, a                    ; (0x23A09E)
	; Call 0x284FD6
	call HDAE5000_HD_Status_Check
	; Final workspace dispatch
	ld wa, (xsp + 10)
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld xhl, (xbc + 16)	; (XBC+0x10)
	call (xhl)
.Lts907_load:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 28)
	ret

HDAE5000_Table_Sub_2908B1:	; 0x2908B1 (335 bytes)
	lda xsp, (xsp - 38)
	push xiz
	ld (xsp + 38), bc	; save file number
	ld (xsp + 40), wa	; save partition
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
	lda_24 xwa, 0x20165a                  ; 0x20165A (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lts8b1_load	; entry doesn't exist
	; Workspace dispatch with WA=2 (buffer at xsp+30)
	lda xwa, (xsp + 30)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2                 ; 0x23A1A2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)
	lds wa, 2
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
	lda_24 xwa, 0x20165a                  ; 0x20165A
	add xwa, xhl
	ld xbc, xwa
	ld xwa, (xsp + 10)
	ld xde, xbc
	ld xbc, 0x00000010
	call 0x29811C
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
	ld32_24 xwa, 0x23a1a2                 ; 0x23A1A2
	ld_sril xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 28)	; (XWA+0x1C)
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
	lda_24 xwa, 0x20165a                  ; 0x20165A
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 6)
	ld xwa, (xwa)
	ld xbc, (xsp + 10)
	ld xbc, (xbc)
	call 0x29811C
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
	ld32_24 xbc, 0x23a1a2                 ; 0x23A1A2
	ld_sril xbc, (xbc + 0x0e88)
	ld xhl, (xbc + 32)	; (XBC+0x20)
	call (xhl)
.Lts8b1_load:
	ld hl, (xsp + 12)
	pop xiz
	lda xsp, (xsp + 38)
	ret

HDAE5000_Table_Sub_290A00:	; 0x290A00 (390 bytes)
	lda xsp, (xsp - 28)
	push xiz
	ld (xsp + 28), bc	; save file number
	ld (xsp + 30), wa	; save partition
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
	lda_24 xwa, 0x20165e                  ; 0x20165E (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lts0a0_load	; entry doesn't exist
	; Workspace dispatch WA=3 (buffer at xsp+20)
	lda xwa, (xsp + 20)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2                 ; 0x23A1A2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)
	lds wa, 3
	call (xhl)
	; Workspace dispatch WA=4 (buffer at xsp+12)
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)
	lds wa, 4
	call (xhl)
	; Save workspace ptr
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
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
	lda_24 xwa, 0x20165e                  ; 0x20165E
	add xwa, xhl
	ld xbc, xwa
	ld xwa, (xsp + 8)
	ld xde, xbc
	ld xbc, 0x00005000
	call 0x29811C
	; Check result
	cp hl, 0xFFFF
	jr nz, .Lts0a0_process
	ldw hl, 0xFFFF
	jrl .Lts0a0_exit	; skip result load
.Lts0a0_process:
	; Compute slot address from workspace data
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
	ld_srib e, (xwa + 0x00c7)               ; ld E, (XWA+0x00C7)
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
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
	ld32_24 xwa, 0x23a1a2                 ; 0x23A1A2
	ld_sril xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 44)	; (XWA+0x2C)
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
	lda_24 xwa, 0x20165e                  ; 0x20165E
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xwa, (xwa)
	ld xbc, (xsp + 4)
	call 0x29811C
	ld (xsp + 10), hl	; save result
	; Final workspace dispatch at (XBC+0x30)
	ld wa, (xsp + 10)
	ld32_24 xbc, 0x23a1a2                 ; 0x23A1A2
	ld_sril xbc, (xbc + 0x0e88)
	ld xhl, (xbc + 48)	; (XBC+0x30)
	call (xhl)
	; Extra function call via workspace chain
	ld32_24 xwa, 0x23a1a2                 ; 0x23A1A2
	ld_sril xwa, (xwa + 0x11fa)             ; ld XWA, (XWA+0x11FA)
	ld xhl, (xwa + 24)	; (XWA+0x18)
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x01C00013
	lds32 xde, 0
	call (xhl)
.Lts0a0_load:
	ld hl, (xsp + 10)
.Lts0a0_exit:
	pop xiz
	lda xsp, (xsp + 28)
	ret

HDAE5000_Table_Sub_290B86:	; 0x290B86 (303 bytes)
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), bc	; save file number
	ld (xsp + 22), wa	; save partition
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
	lda_24 xwa, 0x201662                  ; 0x201662 (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lts90b_load
	; Workspace dispatch with WA=5
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2                 ; workspace ptr
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)             ; (XWA+0x0080)
	lds wa, 5
	call (xhl)
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
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
	lda_24 xwa, 0x201662                  ; 0x201662
	add xwa, xhl
	ld xbc, xwa
	ld xwa, (xsp + 8)
	ld xde, xbc
	ld xbc, 0x00000200
	call 0x29811C
	cp hl, 0xFFFF
	jr nz, .Lts90b_ok
	ldw hl, 0xFFFF
	jr .Lts90b_exit
.Lts90b_ok:
	; Load workspace param and shift
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
	ld wa, (xwa + 46)	; workspace offset 0x2E
	extz xwa
	ld (xsp + 4), xwa
	sll xwa, 4
	ld (xsp + 4), xwa
	; Dispatch workspace handler
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 60)	; handler at offset 0x3C
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
	lda_24 xwa, 0x201662                  ; 0x201662
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xwa, (xwa)
	ld xbc, (xsp + 4)
	call 0x29811C
	ld (xsp + 10), hl
	; Post-processing dispatch
	ld wa, (xsp + 10)
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld xhl, (xbc + 64)	; post offset 0x40
	call (xhl)
.Lts90b_load:
	ld hl, (xsp + 10)	; load result
.Lts90b_exit:
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_Table_Sub_290CB5:	; 0x290CB5 (220 bytes)
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
	lda_24 xwa, 0x201666                  ; 0x201666
	add xwa, xhl
	ld xwa, (xwa)		; load table entry
	cp xwa, 0xFFFFFFFF	; empty?
	jrl z, .Lts90c_exit	; skip all if -1
	; Workspace dispatch 1
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)
	lds wa, 6
	call (xhl)
	ld xwa, 0x000072AA
	ld (xsp + 16), xwa
	; Workspace dispatch 2
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 76)	; (XWA+0x4C)
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
	lda_24 xwa, 0x201666                  ; 0x201666
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld xbc, (xsp + 8)
	ld xbc, (xbc)
	call 0x29811C		; write entry
	ld (xsp + 10), hl	; save result
	; Post-processing
	ld wa, (xsp + 10)
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld xhl, (xbc + 80)	; (XBC+0x50)
	call (xhl)
.Lts90c_exit:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_Table_Sub_290D91:	; 0x290D91 (303 bytes)
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
	lda_24 xwa, 0x20166a                  ; 0x20166A (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lts90d_load
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)
	lds wa, 7
	call (xhl)
	lda_24 xwa, 0x230f1c
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
	lda_24 xwa, 0x20166a                  ; 0x20166A
	add xwa, xhl
	ld xbc, xwa
	ld xwa, (xsp + 8)
	ld xde, xbc
	ld xbc, 0x00000200
	call 0x29811C
	cp hl, 0xFFFF
	jr nz, .Lts90d_ok
	ldw hl, 0xFFFF
	jr .Lts90d_exit
.Lts90d_ok:
	lda_24 xwa, 0x230f1c
	ld wa, (xwa + 28)	; workspace offset 0x1C
	extz xwa
	ld (xsp + 4), xwa
	sll xwa, 4
	ld (xsp + 4), xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 92)	; handler at offset 0x5C
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
	lda_24 xwa, 0x20166a                  ; 0x20166A
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xwa, (xwa)
	ld xbc, (xsp + 4)
	call 0x29811C
	ld (xsp + 10), hl
	ld wa, (xsp + 10)
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld xhl, (xbc + 96)	; post offset 0x60
	call (xhl)
.Lts90d_load:
	ld hl, (xsp + 10)
.Lts90d_exit:
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_Table_Sub_290EC0:	; 0x290EC0 (133 bytes)
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
	lda_24 xwa, 0x20166e                  ; XWA = 0x20166E (table base)
	add xwa, xhl		; XWA = base + computed offset
	ld xwa, (xwa)		; XWA = table entry value
	cp xwa, 0xFFFFFFFF	; empty entry?
	jr z, .Lts290_exit	; skip if -1
	ld xiy, 0x002F8DD8	; destination for ldirw
	ld xix, 0x00238F1C	; source for ldirw
	lds bc, 4		; count = 4 words (8 bytes)
	mriw2 0x95, 0x11	; ldirw — copy from XIX to XIY
	ld wa, (xsp + 6)	; reload partition
	st16_24 0x238f1e, xwa                 ; ld (0x238F1E), WA
	ld wa, (xsp + 4)	; reload file number
	st16_24 0x238f20, xwa                 ; ld (0x238F20), WA
	lda_24 xwa, 0x293f96                  ; XWA = 0x293F96 (function ptr 1)
	ld xde, xwa		; XDE = function ptr 1
	lda_24 xwa, 0x29414c                  ; XWA = 0x29414C (function ptr 2)
	ld xbc, xwa		; XBC = function ptr 2
	ld xwa, xde		; XWA = function ptr 1
	ld32_24 xde, 0x23a1a2                 ; XDE = (0x23A1A2) workspace ptr
	ld_sril xde, (xde + 0x0e88)             ; XDE = (XDE+0x0E88)
	ld_sril xhl, (xde + 0x00b0)             ; XHL = (XDE+0x00B0) handler
	call (xhl)		; dispatch handler
.Lts290_exit:
	lds hl, 0		; return 0
	pop xiz			; restore XIZ
	inc 4, xsp		; deallocate 4 bytes
	ret

HDAE5000_Table_Sub_290F45:	; 0x290F45 (248 bytes)
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), bc	; save file number
	ld (xsp + 22), wa	; save partition
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
	lda_24 xwa, 0x201672                  ; 0x201672 (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lts90f_load	; entry doesn't exist, result stays 0
	; Workspace dispatch with WA=9
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2                 ; 0x23A1A2
	ld_sril xwa, (xwa + 0x0e88)             ; (XWA+0x0E88)
	ld_sril xhl, (xwa + 0x0080)             ; (XWA+0x0080)
	ldw wa, 0x0009
	call (xhl)
	; Another workspace dispatch (d8 displacement)
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 108)	; (XWA+0x6C)
	call (xhl)
	; Save workspace ptr and buffer ptr
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
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
	lda_24 xwa, 0x201672                  ; 0x201672
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xsp + 8)
	ld xbc, (xbc)		; dereference buffer ptr
	call 0x29811C
	ld (xsp + 10), hl	; save result
	; Post-processing: push arg and dispatch
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
	ld xbc, xwa
	ld xwa, (xsp + 16)
	ld de, wa
	ld xwa, 0x003D3000
	push xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 124)	; (XWA+0x7C)
	lds wa, 1
	call (xhl)
	; Read result and call final handler
	ld wa, (xsp + 10)
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld xhl, (xbc + 112)	; (XBC+0x70)
	call (xhl)
.Lts90f_load:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_Table_Sub_29103D:	; 0x29103D (1023 bytes)
; LTS: 0x29103D (1023 bytes)

	lda	xsp, (xsp-24)
	pushw iz                                ; push IZ
	ld (xsp + 0x16), bc
	ld (xsp + 0x18), wa                     ; ld (XSP+0x18),WA
	lds	iz, 0
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
	lda_24 xwa, 0x201676
	add	xwa, xhl
	ld xwa, (xwa)                           ; ld XWA,(XWA)
	cp	xwa, 0xffffffff
	jrl z, .LTS_1139                       ; [76 b6 00] jrl Z,0x291139
	call HDAE5000_Display_Error
	lda	xwa, (xsp+14)
	ld	xbc, xwa
	ldw	wa, 0x000a
	calr	0x0b4c
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
	lda_24 xwa, 0x201676
	add	xwa, xhl
	ld	xbc, xwa
	ld xwa, (xsp + 0x06)                    ; ld XWA,(XSP+0x06)
	ld xwa, (xwa)                           ; ld XWA,(XWA)
	ld	xde, xbc
	ld	xbc, 0x00000016
	call 0x29811c
	ld	iz, hl
	cp	iz, 0xffff
	jr z, .LTS_1139                        ; [66 58] jr Z,0x291139
	lda	xwa, (xsp+14)
	ld	xbc, xwa
	ldw	wa, 0x000a
	calr	0x0af2
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
	lda_24 xwa, 0x201676
	add	xwa, xhl
	ld	xde, xwa
	ld xwa, (xsp + 0x02)                    ; ld XWA,(XSP+0x02)
	ld xwa, (xwa)                           ; ld XWA,(XWA)
	ld xbc, (xsp + 0x06)                    ; ld XBC,(XSP+0x06)
	ld xbc, (xbc)                           ; ld XBC,(XBC)
	call 0x29811c
	ld	iz, hl
.LTS_1139:
	ld	hl, iz
	popw iz                                 ; pop IZ
	lda	xsp, (xsp+24)
	ret

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
	calr	0x2b31
	cp	hl, 0xffff
	jrl z, .LTS_142d                       ; [76 c1 02] jrl Z,0x29142d
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00e8)
	lds	wa, 1
	call	(xhl)
	cpw	(xsp+20), 0x0001
	jr nz, .LTS_1197                       ; [6e 11] jr NZ,0x291197
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0538)
	call	(xhl)
.LTS_1197:
	call 0x297466
	ld	wa, (xsp+22)
	bit	0x00, wa
	jr z, .LTS_11c3                        ; [66 20] jr Z,0x2911c3
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x0290
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTS_11cc                       ; [6e 14] jr NZ,0x2911cc
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x2307
	jr t, .LTS_11cc                        ; [68 09] jr T,0x2911cc
.LTS_11c3:
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x22fc
.LTS_11cc:
	cpw	(xsp+4), 0xffff
	jr z, .LTS_11fb                        ; [66 28] jr Z,0x2911fb
	ld	wa, (xsp+22)
	bit	0x01, wa
	jr z, .LTS_11fb                        ; [66 20] jr Z,0x2911fb
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x03bf
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTS_1204                       ; [6e 14] jr NZ,0x291204
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x23ad
	jr t, .LTS_1204                        ; [68 09] jr T,0x291204
.LTS_11fb:
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x23a2
.LTS_1204:
	cpw	(xsp+4), 0xffff
	jr z, .LTS_1233                        ; [66 28] jr Z,0x291233
	ld	wa, (xsp+22)
	bit	0x02, wa
	jr z, .LTS_1233                        ; [66 20] jr Z,0x291233
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x0460
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTS_123c                       ; [6e 14] jr NZ,0x29123c
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x2453
	jr t, .LTS_123c                        ; [68 09] jr T,0x29123c
.LTS_1233:
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x2448
.LTS_123c:
	cpw	(xsp+4), 0xffff
	jr z, .LTS_126b                        ; [66 28] jr Z,0x29126b
	ld	wa, (xsp+22)
	bit	0x03, wa
	jr z, .LTS_126b                        ; [66 20] jr Z,0x29126b
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x050a
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTS_1274                       ; [6e 14] jr NZ,0x291274
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x24f9
	jr t, .LTS_1274                        ; [68 09] jr T,0x291274
.LTS_126b:
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x24ee
.LTS_1274:
	cpw	(xsp+4), 0xffff
	jr z, .LTS_12a3                        ; [66 28] jr Z,0x2912a3
	ld	wa, (xsp+22)
	bit	0x04, wa
	jr z, .LTS_12a3                        ; [66 20] jr Z,0x2912a3
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x05a5
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTS_12ac                       ; [6e 14] jr NZ,0x2912ac
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x259f
	jr t, .LTS_12ac                        ; [68 09] jr T,0x2912ac
.LTS_12a3:
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x2594
.LTS_12ac:
	cpw	(xsp+4), 0xffff
	jr z, .LTS_12db                        ; [66 28] jr Z,0x2912db
	ld	wa, (xsp+22)
	bit	0x05, wa
	jr z, .LTS_12db                        ; [66 20] jr Z,0x2912db
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x0645
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTS_12e4                       ; [6e 14] jr NZ,0x2912e4
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x2645
	jr t, .LTS_12e4                        ; [68 09] jr T,0x2912e4
.LTS_12db:
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x263a
.LTS_12e4:
	cpw	(xsp+4), 0xffff
	jr z, .LTS_1313                        ; [66 28] jr Z,0x291313
	ld	wa, (xsp+22)
	bit	0x06, wa
	jr z, .LTS_1313                        ; [66 20] jr Z,0x291313
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x06e0
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTS_131c                       ; [6e 14] jr NZ,0x29131c
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x26eb
	jr t, .LTS_131c                        ; [68 09] jr T,0x29131c
.LTS_1313:
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x26e0
.LTS_131c:
	cpw	(xsp+4), 0xffff
	jr z, .LTS_134b                        ; [66 28] jr Z,0x29134b
	ld	wa, (xsp+22)
	bit	0x07, wa
	jr z, .LTS_134b                        ; [66 20] jr Z,0x29134b
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x072e
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTS_1354                       ; [6e 14] jr NZ,0x291354
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x2791
	jr t, .LTS_1354                        ; [68 09] jr T,0x291354
.LTS_134b:
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x2786
.LTS_1354:
	cpw	(xsp+4), 0xffff
	jr z, .LTS_1383                        ; [66 28] jr Z,0x291383
	ld	wa, (xsp+22)
	bit	0x08, wa
	jr z, .LTS_1383                        ; [66 20] jr Z,0x291383
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x07c7
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTS_138c                       ; [6e 14] jr NZ,0x29138c
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x2837
	jr t, .LTS_138c                        ; [68 09] jr T,0x29138c
.LTS_1383:
	ld	wa, (xsp+12)
	ld	bc, (xsp+10)
	calr	0x282c
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
	ld	xwa, 0x00201632
	add	xwa, xhl
	push xwa
	call HDAE5000_MemCopy_Reverse
	lda	xsp, (xsp+10)
	call 0x297a78
	jr t, .LTS_13e7                        ; [68 12] jr T,0x2913e7
.LTS_13d5:
	pushw 0x0000
	pushm	(xsp+20)
	ld	wa, (xsp+16)
	ld	bc, (xsp+14)
	ldw	de, 0x01ff
	calr	0x1f84
.LTS_13e7:
	cpw	(xsp+18), 0x0001
	call_24	nz, 0x2974B5
	cpw	(xsp+20), 0x0001
	jr nz, .LTS_1409                       ; [6e 11] jr NZ,0x291409
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x053c)
	call	(xhl)
.LTS_1409:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00f0)
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00ec)
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


HDAE5000_Table_Init_Entry:	; 0x29143C (359 bytes)
	lda xsp, (xsp - 28)
	push xiz
	ld (xsp + 28), bc	; save file number
	ld (xsp + 30), wa	; save partition
	; Workspace dispatch with WA=0 (buffer at xsp+20)
	lda xwa, (xsp + 20)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2                 ; 0x23A1A2
	ld_sril xwa, (xwa + 0x0e88)             ; (XWA+0x0E88)
	ld_sril xhl, (xwa + 0x0080)             ; (XWA+0x0080)
	lds wa, 0
	call (xhl)
	; Workspace dispatch with WA=1 (buffer at xsp+12)
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)
	lds wa, 1
	call (xhl)
	; Compute arg and call Cell_Get_Params
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	calr HDAE5000_Cell_Get_Params
	ld (xsp + 4), xhl
	; Workspace dispatch (d8 displacement 0x14)
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 20)	; (XWA+0x14)
	call (xhl)
	; Call 0x29AEC7 with args
	ld xwa, (xsp + 4)
	pushw wa
	pushw 0x0000
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
	push xwa
	call HDAE5000_MemFill
	; Call 0x29AE9F with args (first)
	ld xwa, (xsp + 32)
	pushw wa
	ld xwa, (xsp + 30)
	push xwa
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
	push xwa
	call HDAE5000_MemCopy
	; Call 0x29AE9F with args (second)
	ld xwa, (xsp + 34)
	pushw wa
	ld xwa, (xsp + 32)
	push xwa
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
	add xwa, (xsp + 48)
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 28)	; clean up pushed args
	; Store metadata at 0x230F1C + offset
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	ld xbc, 0x00230F1C
	add xbc, xwa
	ld8_24 a, 0x22b2f4                    ; 0x22B2F4
	ld (xbc), a
	; Store at offset+1
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	inc 1, xwa
	ld xbc, 0x00230F1C
	add xbc, xwa
	ld8_24 a, 0x23a0a0                    ; 0x23A0A0
	ld (xbc), a
	; Store at offset+2
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	inc 2, xwa
	ld xbc, 0x00230F1C
	add xbc, xwa
	ld8_24 a, 0x23a09e                    ; 0x23A09E
	ld (xbc), a
	; Save workspace ptr
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
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
	lda_24 xwa, 0x201656                  ; 0x201656 (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	call HDAE5000_Display_Copy
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
	lda_24 xwa, 0x20164c                  ; 0x20164C (flag base)
	add xwa, xhl
	ld (xwa), 0x01
.Lti914_flag_done:
	; Final workspace dispatch
	ld wa, (xsp + 10)
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld xhl, (xbc + 24)	; (XBC+0x18)
	call (xhl)
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 28)
	ret

HDAE5000_Table_Sub_2915A3:	; 0x2915A3 (217 bytes)
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), bc
	ld (xsp + 22), wa
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)
	lds wa, 2		; operation code = 2
	call (xhl)
	ld xwa, (xsp + 16)
	calr HDAE5000_Cell_Get_Params
	ld (xsp + 16), xhl	; save result
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 36)	; (XWA+0x24)
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
	lda_24 xwa, 0x20165a                  ; 0x20165A
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld xbc, (xsp + 8)
	ld xbc, (xbc)
	call HDAE5000_Display_Copy
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
	lda_24 xwa, 0x20164d                  ; 0x20164D
	add xwa, xhl
	ld (xwa), 0x01
.Lts915_post:
	ld wa, (xsp + 10)
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld xhl, (xbc + 40)	; (XBC+0x28)
	call (xhl)
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_Table_Sub_29167C:	; 0x29167C (226 bytes)
	lda xsp, (xsp - 30)	; larger stack frame
	push xiz
	ld (xsp + 30), bc	; save file number
	ld (xsp + 32), wa	; save partition
	; Workspace dispatch 1: buffer at XSP+22
	lda xwa, (xsp + 22)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)
	lds wa, 3		; operation code = 3
	call (xhl)
	; Workspace dispatch 2: buffer at XSP+14
	lda xwa, (xsp + 14)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)
	lds wa, 4		; operation code = 4
	call (xhl)
	; Workspace dispatch 3: compute address
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld xix, (xwa + 52)	; (XWA+0x34)
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
	lda_24 xwa, 0x20165e                  ; 0x20165E
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 10)
	ld xwa, (xwa)
	ld xbc, (xsp + 6)
	call HDAE5000_Display_Copy
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
	lda_24 xwa, 0x20164e                  ; 0x20164E
	add xwa, xhl
	ld (xwa), 0x01
.Lts916_post:
	ld wa, (xsp + 4)	; WA = result param
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld xhl, (xbc + 56)	; (XBC+0x38)
	call (xhl)
	ld hl, (xsp + 4)	; HL = result
	pop xiz
	lda xsp, (xsp + 30)	; deallocate 30 bytes
	ret

HDAE5000_Table_Sub_29175E:	; 0x29175E (211 bytes)
	lda xsp, (xsp - 20)	; allocate 20 bytes
	push xiz
	ld (xsp + 20), bc	; save file number
	ld (xsp + 22), wa	; save partition
	lda xwa, (xsp + 12)
	ld xbc, xwa		; XBC = buffer addr
	ld32_24 xwa, 0x23a1a2                 ; workspace ptr
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)
	lds wa, 5		; operation code = 5
	call (xhl)
	ld32_24 xwa, 0x23a1a2                 ; reload workspace
	ld_sril xwa, (xwa + 0x0e88)
	ld xix, (xwa + 68)	; (XWA+0x44)
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
	lda_24 xwa, 0x201662                  ; 0x201662
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld xbc, (xsp + 8)
	ld xbc, (xbc)
	call HDAE5000_Display_Copy
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
	lda_24 xwa, 0x20164f                  ; 0x20164F
	add xwa, xhl
	ld (xwa), 0x01
.Lts917_post:
	ld wa, (xsp + 10)
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld xhl, (xbc + 72)	; (XBC+0x48)
	call (xhl)
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_Table_Sub_291831:	; 0x291831 (216 bytes)
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), bc
	ld (xsp + 22), wa
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)
	lds wa, 6		; operation code = 6
	call (xhl)
	ld xwa, 0x000072AA	; constant for XSP+16
	ld (xsp + 16), xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 84)	; (XWA+0x54)
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
	lda_24 xwa, 0x201666                  ; 0x201666
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld xbc, (xsp + 8)
	ld xbc, (xbc)
	call HDAE5000_Display_Copy
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
	lda_24 xwa, 0x201650                  ; 0x201650
	add xwa, xhl
	ld (xwa), 0x01
.Lts918_post:
	ld wa, (xsp + 10)
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld xhl, (xbc + 88)	; (XBC+0x58)
	call (xhl)
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_Table_Sub_291909:	; 0x291909 (211 bytes)
	lda xsp, (xsp - 20)	; allocate 20 bytes
	push xiz
	ld (xsp + 20), bc	; save file number
	ld (xsp + 22), wa	; save partition
	lda xwa, (xsp + 12)
	ld xbc, xwa		; XBC = buffer addr
	ld32_24 xwa, 0x23a1a2                 ; workspace ptr
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)
	lds wa, 7		; operation code = 7
	call (xhl)
	ld32_24 xwa, 0x23a1a2                 ; reload workspace
	ld_sril xwa, (xwa + 0x0e88)
	ld xix, (xwa + 100)	; (XWA+0x64)
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
	lda_24 xwa, 0x20166a                  ; 0x20166A
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld xbc, (xsp + 8)
	ld xbc, (xbc)
	call HDAE5000_Display_Copy
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
	lda_24 xwa, 0x201651                  ; 0x201651
	add xwa, xhl
	ld (xwa), 0x01
.Lts919b_post:
	ld wa, (xsp + 10)
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld xhl, (xbc + 104)	; (XBC+0x68)
	call (xhl)
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_Table_Sub_2919DC:	; 0x2919DC (134 bytes)
	push xiz		; save XIZ
	ld de, bc		; DE = BC (file number param)
	lds hl, 0		; HL = 0
	ld xiy, 0x002F8DD8	; destination for ldirw
	ld xix, 0x00238F1C	; source for ldirw
	lds bc, 4		; count = 4 words
	mriw2 0x95, 0x11	; ldirw — copy from XIX to XIY
	st16_24 0x238f1e, xwa                 ; ld (0x238F1E), WA — partition
	st16_24 0x238f20, xde                 ; ld (0x238F20), DE — file number
	ld16_24 xwa, 0x238f20                 ; WA = (0x238F20) file number
	extz xwa		; zero-extend to 32-bit
	ld xbc, 0x0000004C	; multiplier = 76
	call HDAE5000_Multiply		; multiply
	ld xiz, xhl		; XIZ = file_number * 76
	ld16_24 xwa, 0x238f1e                 ; WA = (0x238F1E) partition
	extz xwa		; zero-extend to 32-bit
	ld xbc, 0x000004C0	; multiplier = 1216
	call HDAE5000_Multiply		; multiply
	add xhl, 0x780		; XHL += 1920 (header offset)
	add xhl, xiz		; XHL += file_number * 76
	lda_24 xwa, 0x20166e                  ; XWA = 0x20166E (table base)
	add xwa, xhl		; XWA = base + computed offset
	calr HDAE5000_Display_Sub_294273
	ld wa, hl		; WA = result
	cp wa, 0xFFFF		; check for failure
	jr z, .Lts919_exit	; skip if failed
	lda_24 xwa, 0x294152                  ; XWA = 0x294152
	ld xhl, xwa		; XHL = handler 1
	lda_24 xwa, 0x294069                  ; XWA = 0x294069
	ld xbc, xwa		; XBC = handler 2
	lda_24 xwa, 0x29414c                  ; XWA = 0x29414C
	ld xde, xwa		; XDE = handler 3
	ld xwa, xhl		; XWA = handler 1
	ld32_24 xhl, 0x23a1a2                 ; XHL = (0x23A1A2) workspace ptr
	ld_sril xhl, (xhl + 0x0e88)             ; XHL = (XHL+0x0E88)
	ld_sril xix, (xhl + 0x00b4)             ; XIX = (XHL+0x00B4)
	call (xix)		; dispatch handler
	calr HDAE5000_Display_Sub_29429E
.Lts919_exit:
	pop xiz			; restore XIZ
	ret

HDAE5000_Table_Sub_291A62:	; 0x291A62 (209 bytes)
	lda xsp, (xsp - 20)	; allocate 20 bytes on stack
	push xiz		; save XIZ
	ld (xsp + 20), bc	; save BC param (file number)
	ld (xsp + 22), wa	; save WA param (partition)
	lda xwa, (xsp + 12)	; XWA = addr of local buffer
	ld xbc, xwa		; XBC = buffer address
	ld32_24 xwa, 0x23a1a2                 ; XWA = (0x23A1A2) workspace ptr
	ld_sril xwa, (xwa + 0x0e88)             ; XWA = (XWA+0x0E88)
	ld_sril xhl, (xwa + 0x0080)             ; XHL = (XWA+0x0080) handler
	ldw wa, 0x0009		; WA = 9 (operation code)
	call (xhl)		; dispatch
	ld32_24 xwa, 0x23a1a2                 ; reload workspace ptr
	ld_sril xwa, (xwa + 0x0e88)             ; XWA = (XWA+0x0E88)
	ld xhl, (xwa + 116)	; XHL = (XWA+0x74) handler
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
	lda_24 xwa, 0x201672                  ; XWA = 0x201672 (table base)
	add xwa, xhl		; XWA = base + offset
	ld xde, xwa		; XDE = table address
	ld xwa, (xsp + 4)	; XWA = buffer ptr
	ld xwa, (xwa)		; dereference
	ld xbc, (xsp + 8)	; XBC = result ptr
	ld xbc, (xbc)		; dereference
	call HDAE5000_Display_Copy		; compare/process
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
	lda_24 xwa, 0x201653                  ; XWA = 0x201653 (flag table)
	add xwa, xhl		; XWA = base + offset
	ld (xwa), 0x01	; set flag byte to 1
.Lts91a_post:
	ld wa, (xsp + 10)	; WA = result (param for handler)
	ld32_24 xbc, 0x23a1a2                 ; XBC = (0x23A1A2) workspace ptr
	ld_sril xbc, (xbc + 0x0e88)             ; XBC = (XBC+0x0E88)
	ld xhl, (xbc + 120)	; XHL = (XBC+0x78) handler
	call (xhl)		; dispatch
	ld hl, (xsp + 10)	; HL = result
	pop xiz			; restore XIZ
	lda xsp, (xsp + 20)	; deallocate 20 bytes
	ret

HDAE5000_Table_Sub_291B33:	; 0x291B33 (171 bytes)
	lda xsp, (xsp - 20)	; allocate 20 bytes on stack
	push xiz		; save XIZ
	ld (xsp + 20), bc	; save BC param (file number)
	ld (xsp + 22), wa	; save WA param (partition)
	lda xwa, (xsp + 12)	; XWA = addr of local buffer
	ld xbc, xwa		; XBC = buffer address
	ldw wa, 0x000A		; WA = 10 (string length)
	calr HDAE5000_Table_Sub_291BDE	; init table entry
	ld xwa, (xsp + 16)	; XWA = param block
	calr HDAE5000_Cell_Get_Params
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
	lda_24 xwa, 0x201676                  ; XWA = 0x201676 (table base)
	add xwa, xhl		; XWA = base + offset
	ld xde, xwa		; XDE = table address
	ld xwa, (xsp + 4)	; XWA = buffer ptr
	ld xwa, (xwa)		; dereference
	ld xbc, (xsp + 8)	; XBC = result ptr
	ld xbc, (xbc)		; dereference
	call HDAE5000_Display_Copy		; compare/process
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
	lda_24 xwa, 0x201654                  ; XWA = 0x201654 (flag table)
	add xwa, xhl		; XWA = base + offset
	ld (xwa), 0x01	; set flag byte to 1
.Lts91b_exit:
	ld hl, (xsp + 10)	; HL = result
	pop xiz			; restore XIZ
	lda xsp, (xsp + 20)	; deallocate 20 bytes
	ret

HDAE5000_Table_Sub_291BDE:	; 0x291BDE (47 bytes)
	; Initialize table entry structure with string address
	; Input: WA = offset, XBC = structure pointer
	; Output: HL = offset
	dec 2, xsp
	push xiz
	ld xiz, xbc			; XIZ = structure pointer
	ld (xsp + 4), wa		; save offset on stack
	lda_24 xwa, 0x22b430                  ; 0x22B430 - base string address
	ld (xiz), xwa			; store string pointer in structure
	ld32_24 xwa, 0x22b442                 ; 0x22B442 - load source string pointer
	call HDAE5000_String_To_Upper
	add hl, 0x0016			; add 22 to string length
	ld wa, hl
	exts xwa			; sign-extend to 32-bit
	ld (xiz + 4), xwa		; store computed size
	st32_24 0x2304f2, xwa                 ; 0x2304F2 - global size variable
	ld hl, (xsp + 4)		; return saved offset
	pop xiz
	inc 2, xsp
	ret

HDAE5000_Table_Complex_Init:	; 0x291C0D (2171 bytes)
	; Complex table initialization (large stack frame)
; LTCI: 0x291C0D (2171 bytes)

	ld	de, wa
	extz xde                                ; extz XDE
	sll	xde, 0x03
	lda_24 xhl, 0x2f8e26
	add	xhl, xde
	ld	de, (xhl)
	pushw de                                ; push DE
	ld	de, wa
	extz xde                                ; extz XDE
	sll	xde, 0x03
	lda_24 xhl, 0x2f8e24
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
	call HDAE5000_MemCompare_Block
	add	xsp, 0x0000000a
	cps	hl, 0
	jr nz, .LTCI_1c54                      ; [6e 04] jr NZ,0x291c54
	lds	hl, 0
	jr t, .LTCI_1c57                       ; [68 03] jr T,0x291c57
.LTCI_1c54:
	ldw	hl, 0xffff
.LTCI_1c57:
	ret

	st_dri3b l, 0xFD, 0xE6, 0xFE	; lda XSP,XSP+0xfee6
	push xiz
	st_dri3w bc, 0xFD, 0x1C, 0x01	; ld (XSP+0x011c),BC
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
	call HDAE5000_MemCopy_Block
	lda	xsp, (xsp+26)
	lda	xwa, (xsp+18)
	ld	xbc, xwa
	lda	xwa, (xsp+4)
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e88)
	ld_sril	xix, (xde + 0x0094)
	call	(xix)
	ld	xwa, xhl
	cp	xwa, 0xffffffff
	jr z, .LTCI_1cce                       ; [66 19] jr Z,0x291cce
	ld	xwa, xhl
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e88)
	ld_sril	xhl, (xbc + 0x009c)
	call	(xhl)
	ldw	hl, 0xffff
	jrl t, .LTCI_214a                      ; [78 7c 04] jrl T,0x29214a
.LTCI_1cce:
	pushw 0x002f
	pushw 0x8ea2
	lda	xwa, (xsp+16)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+18)
	ld	xbc, xwa
	lda	xwa, (xsp+4)
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e88)
	ld_sril	xix, (xde + 0x0094)
	call	(xix)
	ld	xwa, xhl
	cp	xwa, 0xffffffff
	jr z, .LTCI_1d1a                       ; [66 19] jr Z,0x291d1a
	ld	xwa, xhl
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e88)
	ld_sril	xhl, (xbc + 0x009c)
	call	(xhl)
	ldw	hl, 0xffff
	jrl t, .LTCI_214a                      ; [78 30 04] jrl T,0x29214a
.LTCI_1d1a:
	ld_sriw	wa, (xsp + 0x011c)
	bit	0x00, wa
	jr z, .LTCI_1d91                       ; [66 6d] jr Z,0x291d91
	pushw 0x002f
	pushw 0x8ea8
	lda	xwa, (xsp+16)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+4)
	lda_24 xbc, 0x2f8eae
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e88)
	ld_sril	xhl, (xde + 0x00a0)
	call	(xhl)
	lda_24 xwa, 0x230f1c
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e88)
	ld_sril	xhl, (xbc + 0x00a8)
	ld	xbc, 0x00000200
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00ac)
	call	(xhl)
	lda_24 xwa, 0x230f1c
	ld	xbc, xwa
	lds	wa, 0
	calr	0xfe88
	cp	hl, 0xffff
	jr nz, .LTCI_1d91                      ; [6e 06] jr NZ,0x291d91
	ldw	hl, 0xffff
	jrl t, .LTCI_214a                      ; [78 b9 03] jrl T,0x29214a
.LTCI_1d91:
	ld_sriw	wa, (xsp + 0x011c)
	bit	0x01, wa
	jr z, .LTCI_1e08                       ; [66 6d] jr Z,0x291e08
	pushw 0x002f
	pushw 0x8eb2
	lda	xwa, (xsp+16)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+4)
	lda_24 xbc, 0x2f8eb8
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e88)
	ld_sril	xhl, (xde + 0x00a0)
	call	(xhl)
	lda_24 xwa, 0x230f1c
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e88)
	ld_sril	xhl, (xbc + 0x00a8)
	ld	xbc, 0x00000200
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00ac)
	call	(xhl)
	lda_24 xwa, 0x230f1c
	ld	xbc, xwa
	lds	wa, 1
	calr	0xfe11
	cp	hl, 0xffff
	jr nz, .LTCI_1e08                      ; [6e 06] jr NZ,0x291e08
	ldw	hl, 0xffff
	jrl t, .LTCI_214a                      ; [78 42 03] jrl T,0x29214a
.LTCI_1e08:
	ld_sriw	wa, (xsp + 0x011c)
	bit	0x02, wa
	jr z, .LTCI_1e7f                       ; [66 6d] jr Z,0x291e7f
	pushw 0x002f
	pushw 0x8ebc
	lda	xwa, (xsp+16)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+4)
	lda_24 xbc, 0x2f8ec2
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e88)
	ld_sril	xhl, (xde + 0x00a0)
	call	(xhl)
	lda_24 xwa, 0x230f1c
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e88)
	ld_sril	xhl, (xbc + 0x00a8)
	ld	xbc, 0x00000200
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00ac)
	call	(xhl)
	lda_24 xwa, 0x230f1c
	ld	xbc, xwa
	lds	wa, 2
	calr	0xfd9a
	cp	hl, 0xffff
	jr nz, .LTCI_1e7f                      ; [6e 06] jr NZ,0x291e7f
	ldw	hl, 0xffff
	jrl t, .LTCI_214a                      ; [78 cb 02] jrl T,0x29214a
.LTCI_1e7f:
	ld_sriw	wa, (xsp + 0x011c)
	bit	0x03, wa
	jr z, .LTCI_1ef6                       ; [66 6d] jr Z,0x291ef6
	pushw 0x002f
	pushw 0x8ec6
	lda	xwa, (xsp+16)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+4)
	lda_24 xbc, 0x2f8ecc
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e88)
	ld_sril	xhl, (xde + 0x00a0)
	call	(xhl)
	lda_24 xwa, 0x230f1c
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e88)
	ld_sril	xhl, (xbc + 0x00a8)
	ld	xbc, 0x00000200
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00ac)
	call	(xhl)
	lda_24 xwa, 0x230f1c
	ld	xbc, xwa
	lds	wa, 3
	calr	0xfd23
	cp	hl, 0xffff
	jr nz, .LTCI_1ef6                      ; [6e 06] jr NZ,0x291ef6
	ldw	hl, 0xffff
	jrl t, .LTCI_214a                      ; [78 54 02] jrl T,0x29214a
.LTCI_1ef6:
	ld_sriw	wa, (xsp + 0x011c)
	bit	0x04, wa
	jr z, .LTCI_1f6d                       ; [66 6d] jr Z,0x291f6d
	pushw 0x002f
	pushw 0x8ed0
	lda	xwa, (xsp+16)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+4)
	lda_24 xbc, 0x2f8ed4
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e88)
	ld_sril	xhl, (xde + 0x00a0)
	call	(xhl)
	lda_24 xwa, 0x230f1c
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e88)
	ld_sril	xhl, (xbc + 0x00a8)
	ld	xbc, 0x00000200
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00ac)
	call	(xhl)
	lda_24 xwa, 0x230f1c
	ld	xbc, xwa
	lds	wa, 4
	calr	0xfcac
	cp	hl, 0xffff
	jr nz, .LTCI_1f6d                      ; [6e 06] jr NZ,0x291f6d
	ldw	hl, 0xffff
	jrl t, .LTCI_214a                      ; [78 dd 01] jrl T,0x29214a
.LTCI_1f6d:
	ld_sriw	wa, (xsp + 0x011c)
	bit	0x05, wa
	jr z, .LTCI_1fe4                       ; [66 6d] jr Z,0x291fe4
	pushw 0x002f
	pushw 0x8ed8
	lda	xwa, (xsp+16)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+4)
	lda_24 xbc, 0x2f8ede
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e88)
	ld_sril	xhl, (xde + 0x00a0)
	call	(xhl)
	lda_24 xwa, 0x230f1c
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e88)
	ld_sril	xhl, (xbc + 0x00a8)
	ld	xbc, 0x00000200
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00ac)
	call	(xhl)
	lda_24 xwa, 0x230f1c
	ld	xbc, xwa
	lds	wa, 5
	calr	0xfc35
	cp	hl, 0xffff
	jr nz, .LTCI_1fe4                      ; [6e 06] jr NZ,0x291fe4
	ldw	hl, 0xffff
	jrl t, .LTCI_214a                      ; [78 66 01] jrl T,0x29214a
.LTCI_1fe4:
	ld_sriw	wa, (xsp + 0x011c)
	bit	0x06, wa
	jr z, .LTCI_205b                       ; [66 6d] jr Z,0x29205b
	pushw 0x002f
	pushw 0x8ee2
	lda	xwa, (xsp+16)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+4)
	lda_24 xbc, 0x2f8ee8
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e88)
	ld_sril	xhl, (xde + 0x00a0)
	call	(xhl)
	lda_24 xwa, 0x230f1c
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e88)
	ld_sril	xhl, (xbc + 0x00a8)
	ld	xbc, 0x00000200
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00ac)
	call	(xhl)
	lda_24 xwa, 0x230f1c
	ld	xbc, xwa
	lds	wa, 6
	calr	0xfbbe
	cp	hl, 0xffff
	jr nz, .LTCI_205b                      ; [6e 06] jr NZ,0x29205b
	ldw	hl, 0xffff
	jrl t, .LTCI_214a                      ; [78 ef 00] jrl T,0x29214a
.LTCI_205b:
	ld_sriw	wa, (xsp + 0x011c)
	bit	0x07, wa
	jr z, .LTCI_20d1                       ; [66 6c] jr Z,0x2920d1
	pushw 0x002f
	pushw 0x8eec
	lda	xwa, (xsp+16)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+4)
	lda_24 xbc, 0x2f8ef0
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e88)
	ld_sril	xhl, (xde + 0x00a0)
	call	(xhl)
	lda_24 xwa, 0x230f1c
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e88)
	ld_sril	xhl, (xbc + 0x00a8)
	ld	xbc, 0x00000200
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00ac)
	call	(xhl)
	lda_24 xwa, 0x230f1c
	ld	xbc, xwa
	lds	wa, 7
	calr	0xfb47
	cp	hl, 0xffff
	jr nz, .LTCI_20d1                      ; [6e 05] jr NZ,0x2920d1
	ldw	hl, 0xffff
	jr t, .LTCI_214a                       ; [68 79] jr T,0x29214a
.LTCI_20d1:
	ld_sriw	wa, (xsp + 0x011c)
	bit	0x08, wa
	jr z, .LTCI_2148                       ; [66 6d] jr Z,0x292148
	pushw 0x002f
	pushw 0x8ef4
	lda	xwa, (xsp+16)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	lda	xwa, (xsp+4)
	lda_24 xbc, 0x2f8efa
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e88)
	ld_sril	xhl, (xde + 0x00a0)
	call	(xhl)
	lda_24 xwa, 0x230f1c
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e88)
	ld_sril	xhl, (xbc + 0x00a8)
	ld	xbc, 0x00000200
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00ac)
	call	(xhl)
	lda_24 xwa, 0x230f1c
	ld	xbc, xwa
	ldw	wa, 0x0008
	calr	0xfad0
	cp	hl, 0xffff
	jr nz, .LTCI_2148                      ; [6e 05] jr NZ,0x292148
	ldw	hl, 0xffff
	jr t, .LTCI_214a                       ; [68 02] jr T,0x29214a
.LTCI_2148:
	lds	hl, 0
.LTCI_214a:
	pop xiz                                 ; pop XIZ
	st_dri3b l, 0xFD, 0x1A, 0x01	; lda XSP,XSP+0x011a
	ret

	lda	xsp, (xsp-52)
	push xiz
	ld (xsp + 0x30), xde                    ; ld (XSP+0x30),XDE
	ld (xsp + 0x34), bc
	ld (xsp + 0x36), wa                     ; ld (XSP+0x36),WA
	ldw (xsp + 0x04), 0
	ld	wa, (xsp+64)
	calr	0x1b2d
	cp	hl, 0xffff
	jrl z, .LTCI_2479                      ; [76 09 03] jrl Z,0x292479
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00e8)
	lds	wa, 1
	call	(xhl)
	cpw	(xsp+62), 0x0001
	jr nz, .LTCI_219b                      ; [6e 11] jr NZ,0x29219b
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0538)
	call	(xhl)
.LTCI_219b:
	call 0x297466
	ld	wa, (xsp+64)
	bit	0x00, wa
	jr z, .LTCI_21c8                       ; [66 21] jr Z,0x2921c8
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	ld xde, (xsp + 0x30)                    ; ld XDE,(XSP+0x30)
	calr	0x02d5
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTCI_21c8                      ; [6e 09] jr NZ,0x2921c8
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	calr	0x1300
.LTCI_21c8:
	cpw	(xsp+4), 0xffff
	jr z, .LTCI_21f8                       ; [66 29] jr Z,0x2921f8
	ld	wa, (xsp+64)
	bit	0x01, wa
	jr z, .LTCI_21f8                       ; [66 21] jr Z,0x2921f8
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	ld xde, (xsp + 0x30)                    ; ld XDE,(XSP+0x30)
	calr	0x040c
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTCI_21f8                      ; [6e 09] jr NZ,0x2921f8
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	calr	0x13ae
.LTCI_21f8:
	cpw	(xsp+4), 0xffff
	jr z, .LTCI_2228                       ; [66 29] jr Z,0x292228
	ld	wa, (xsp+64)
	bit	0x02, wa
	jr z, .LTCI_2228                       ; [66 21] jr Z,0x292228
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	ld xde, (xsp + 0x30)                    ; ld XDE,(XSP+0x30)
	calr	0x0585
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTCI_2228                      ; [6e 09] jr NZ,0x292228
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	calr	0x145c
.LTCI_2228:
	cpw	(xsp+4), 0xffff
	jr z, .LTCI_2258                       ; [66 29] jr Z,0x292258
	ld	wa, (xsp+64)
	bit	0x03, wa
	jr z, .LTCI_2258                       ; [66 21] jr Z,0x292258
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	ld xde, (xsp + 0x30)                    ; ld XDE,(XSP+0x30)
	calr	0x06f8
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTCI_2258                      ; [6e 09] jr NZ,0x292258
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	calr	0x150a
.LTCI_2258:
	cpw	(xsp+4), 0xffff
	jr z, .LTCI_2288                       ; [66 29] jr Z,0x292288
	ld	wa, (xsp+64)
	bit	0x04, wa
	jr z, .LTCI_2288                       ; [66 21] jr Z,0x292288
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	ld xde, (xsp + 0x30)                    ; ld XDE,(XSP+0x30)
	calr	0x086b
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTCI_2288                      ; [6e 09] jr NZ,0x292288
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	calr	0x15b8
.LTCI_2288:
	cpw	(xsp+4), 0xffff
	jr z, .LTCI_22b8                       ; [66 29] jr Z,0x2922b8
	ld	wa, (xsp+64)
	bit	0x05, wa
	jr z, .LTCI_22b8                       ; [66 21] jr Z,0x2922b8
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	ld xde, (xsp + 0x30)                    ; ld XDE,(XSP+0x30)
	calr	0x095b
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTCI_22b8                      ; [6e 09] jr NZ,0x2922b8
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	calr	0x1666
.LTCI_22b8:
	cpw	(xsp+4), 0xffff
	jr z, .LTCI_22e8                       ; [66 29] jr Z,0x2922e8
	ld	wa, (xsp+64)
	bit	0x06, wa
	jr z, .LTCI_22e8                       ; [66 21] jr Z,0x2922e8
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	ld xde, (xsp + 0x30)                    ; ld XDE,(XSP+0x30)
	calr	0x0a43
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTCI_22e8                      ; [6e 09] jr NZ,0x2922e8
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	calr	0x1714
.LTCI_22e8:
	cpw	(xsp+4), 0xffff
	jr z, .LTCI_2318                       ; [66 29] jr Z,0x292318
	ld	wa, (xsp+64)
	bit	0x07, wa
	jr z, .LTCI_2318                       ; [66 21] jr Z,0x292318
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	ld xde, (xsp + 0x30)                    ; ld XDE,(XSP+0x30)
	calr	0x0bb6
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTCI_2318                      ; [6e 09] jr NZ,0x292318
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	calr	0x17c2
.LTCI_2318:
	cpw	(xsp+4), 0xffff
	jr z, .LTCI_2348                       ; [66 29] jr Z,0x292348
	ld	wa, (xsp+64)
	bit	0x08, wa
	jr z, .LTCI_2348                       ; [66 21] jr Z,0x292348
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	ld xde, (xsp + 0x30)                    ; ld XDE,(XSP+0x30)
	calr	0x0c9f
	ld (xsp + 0x04), hl
	ld	wa, (xsp+4)
	cp	wa, 0xffff
	jr nz, .LTCI_2348                      ; [6e 09] jr NZ,0x292348
	ld	wa, (xsp+54)
	ld	bc, (xsp+52)
	calr	0x1870
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
	call HDAE5000_MemCopy_Block
	lda	xsp, (xsp+26)
	lda	xwa, (xsp+6)
	lda_24 xbc, 0x2f8f04
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e88)
	ld_sril	xix, (xde + 0x00a0)
	call	(xix)
	cps	hl, 0
	jr lt, .LTCI_23ba                      ; [61 1b] jr LT,0x2923ba
	lda	xwa, (xsp+20)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e88)
	ld_sril	xhl, (xbc + 0x00a8)
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
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00ac)
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
	ld	xwa, 0x00201632
	add	xwa, xhl
	push xwa
	call HDAE5000_MemCopy_Reverse
	lda	xsp, (xsp+10)
	call 0x297a78
	jr t, .LTCI_2433                       ; [68 12] jr T,0x292433
.LTCI_2421:
	pushw 0x0000
	pushm	(xsp+62)
	ld	wa, (xsp+58)
	ld	bc, (xsp+56)
	ldw	de, 0x01ff
	calr	0x0f38
.LTCI_2433:
	cpw	(xsp+60), 0x0001
	call_24	nz, 0x2974B5
	cpw	(xsp+62), 0x0001
	jr nz, .LTCI_2455                      ; [6e 11] jr NZ,0x292455
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x053c)
	call	(xhl)
.LTCI_2455:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00ec)
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00f0)
	call	(xhl)
	jr t, .LTCI_247e                       ; [68 05] jr T,0x29247e
.LTCI_2479:
	ldw (xsp + 0x04), 65535
.LTCI_247e:
	ld	hl, (xsp+4)
	pop xiz                                 ; pop XIZ
	lda	xsp, (xsp+52)
	retd 0x0006		; retd 0x0006


HDAE5000_Table_Sub_292488:	; 0x292488 (359 bytes)
	lda xsp, (xsp - 42)
	push xiz
	ld (xsp + 42), bc	; save file number
	ld (xsp + 44), wa	; save partition
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
	call HDAE5000_MemCopy_Block
	lda xsp, (xsp + 18)	; cleanup 18 bytes
	; Workspace dispatch WA=0 (buffer at xsp+34)
	lda xwa, (xsp + 34)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2                 ; 0x23A1A2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)
	lds wa, 0
	call (xhl)
	; Workspace dispatch WA=1 (buffer at xsp+26)
	lda xwa, (xsp + 26)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)
	lds wa, 1
	call (xhl)
	; Cell_Get_Params
	ld xwa, (xsp + 30)
	add xwa, (xsp + 38)
	calr HDAE5000_Cell_Get_Params
	ld (xsp + 4), xhl
	; Call workspace handler via XIX chain
	lda xwa, (xsp + 12)
	lda_24 xbc, 0x2f8f0e                  ; 0x2F8F0E
	ld32_24 xde, 0x23a1a2                 ; 0x23A1A2
	ld_sril xde, (xde + 0x0e88)
	ld_sril xix, (xde + 0x00a0)
	call (xix)
	; Check if result < 0
	cps hl, 0
	jrl lt, .Lts488_error
	; Workspace dispatch via XDE chain at 0xA8
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
	ld xbc, (xsp + 4)
	ld32_24 xde, 0x23a1a2
	ld_sril xde, (xde + 0x0e88)
	ld_sril xhl, (xde + 0x00a8)
	call (xhl)
	; Write metadata: store 0x00, 0x10, 0x00 at workspace+offset
	ld xwa, (xsp + 30)
	add xwa, (xsp + 38)
	ld xbc, 0x00230F1C
	add xbc, xwa
	ld (xbc), 0x00
	; offset+1: store 0x10
	ld xwa, (xsp + 30)
	add xwa, (xsp + 38)
	inc 1, xwa
	ld xbc, 0x00230F1C
	add xbc, xwa
	ld (xbc), 0x10
	; offset+2: store 0x00
	ld xwa, (xsp + 30)
	add xwa, (xsp + 38)
	inc 2, xwa
	ld xbc, 0x00230F1C
	add xbc, xwa
	ld (xbc), 0x00
	; Save workspace ptr
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
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
	lda_24 xwa, 0x201656                  ; 0x201656 (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	call HDAE5000_Display_Copy
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
	lda_24 xwa, 0x20164c                  ; 0x20164C (flag base)
	add xwa, xhl
	ld (xwa), 0x01
	; Final workspace dispatch at 0xAC
	ld32_24 xwa, 0x23a1a2                 ; 0x23A1A2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x00ac)
	call (xhl)
	jr .Lts488_done
.Lts488_error:
	ldw (xsp + 10), 0xFFFF
.Lts488_done:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 42)
	ret

HDAE5000_Table_Sub_2925EF:	; 0x2925EF (425 bytes)
	lda xsp, (xsp - 30)
	push xiz
	ld (xsp + 30), bc	; save file number
	ld (xsp + 32), wa	; save partition
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
	call HDAE5000_MemCopy_Block
	lda xsp, (xsp + 18)	; clean up pushed args
	; First workspace dispatch
	lda xwa, (xsp + 16)
	lda_24 xbc, 0x2f8f18                  ; 0x2F8F18
	ld32_24 xde, 0x23a1a2                 ; workspace ptr (0x23A1A2)
	ld_sril xde, (xde + 0x0e88)             ; (XDE+0x0E88)
	ld_sril xix, (xde + 0x00a0)             ; (XDE+0x00A0)
	call (xix)
	; Check result
	cps hl, 0
	jr ge, .Lts925_1
	ldw hl, 0xFFFF
	jrl .Lts925_exit
.Lts925_1:
	; Second workspace dispatch
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)             ; (XBC+0x0E88)
	ld_sril xhl, (xbc + 0x00a8)             ; (XBC+0x00A8)
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 4), xhl
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
	ld (xsp + 8), xwa
	ld xwa, (xsp + 4)
	calr HDAE5000_Cell_Get_Params
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
	lda_24 xwa, 0x20165a                  ; 0x20165A (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 12)
	call HDAE5000_Display_Copy
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
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld_sril xhl, (xbc + 0x00a8)
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	cp xwa, 0x00000000
	jr le, .Lts925_4
	; Retry with new params
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
	ld (xsp + 8), xwa
	ld xwa, (xsp + 4)
	calr HDAE5000_Cell_Get_Params
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
	lda_24 xwa, 0x20165a                  ; 0x20165A
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 12)
	call HDAE5000_Display_Restore
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
	lda_24 xwa, 0x20164d                  ; 0x20164D (flag base)
	add xwa, xhl
	ld (xwa), 0x01
	; Final workspace dispatch
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)             ; (XWA+0x0E88)
	ld_sril xhl, (xwa + 0x00ac)             ; (XWA+0x00AC)
	call (xhl)
	ld hl, (xsp + 14)	; normal exit: load result
.Lts925_exit:			; error exit: HL already set
	pop xiz
	lda xsp, (xsp + 30)
	ret

HDAE5000_Table_Sub_292798:	; 0x292798 (419 bytes)
	lda xsp, (xsp - 32)
	push xiz
	ld (xsp + 32), bc	; save file number
	ld (xsp + 34), wa	; save partition
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
	call HDAE5000_MemCopy_Block
	lda xsp, (xsp + 18)	; clean up pushed args
	; First workspace dispatch
	lda xwa, (xsp + 18)
	lda_24 xbc, 0x2f8f22                  ; 0x2F8F22
	ld32_24 xde, 0x23a1a2                 ; workspace ptr (0x23A1A2)
	ld_sril xde, (xde + 0x0e88)             ; (XDE+0x0E88)
	ld_sril xix, (xde + 0x00a0)             ; (XDE+0x00A0)
	call (xix)
	; Check result
	cps hl, 0
	jr ge, .Lts927_1
	ldw hl, 0xFFFF
	jrl .Lts927_exit
.Lts927_1:
	; Second workspace dispatch
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)             ; (XBC+0x0E88)
	ld_sril xhl, (xbc + 0x00a8)             ; (XBC+0x00A8)
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 6), xhl
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
	ld (xsp + 10), xwa
	ld xwa, (xsp + 6)
	calr HDAE5000_Cell_Get_Params
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
	lda_24 xwa, 0x20165e                  ; 0x20165E (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	call HDAE5000_Display_Copy
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
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld_sril xhl, (xbc + 0x00a8)
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	cp xwa, 0x00000000
	jr le, .Lts927_4
	; Retry with new params
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
	ld (xsp + 10), xwa
	ld xwa, (xsp + 6)
	calr HDAE5000_Cell_Get_Params
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
	lda_24 xwa, 0x20165e                  ; 0x20165E
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	call HDAE5000_Display_Restore
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
	lda_24 xwa, 0x20164e                  ; 0x20164E (flag base)
	add xwa, xhl
	ld (xwa), 0x01
	; Final workspace dispatch
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)             ; (XWA+0x0E88)
	ld_sril xhl, (xwa + 0x00ac)             ; (XWA+0x00AC)
	call (xhl)
	ld hl, (xsp + 4)	; normal exit: load result
.Lts927_exit:			; error exit: HL already set
	pop xiz
	lda xsp, (xsp + 32)
	ret

HDAE5000_Table_Sub_29293B:	; 0x29293B (419 bytes)
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
	call HDAE5000_MemCopy_Block
	lda xsp, (xsp + 18)
	lda xwa, (xsp + 18)
	lda_24 xbc, 0x2f8f2c                  ; 0x2F8F2C
	ld32_24 xde, 0x23a1a2
	ld_sril xde, (xde + 0x0e88)
	ld_sril xix, (xde + 0x00a0)
	call (xix)
	cps hl, 0
	jr ge, .Lts929_1
	ldw hl, 0xFFFF
	jrl .Lts929_exit
.Lts929_1:
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld_sril xhl, (xbc + 0x00a8)
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 6), xhl
	lda_24 xwa, 0x230f1c
	ld (xsp + 10), xwa
	ld xwa, (xsp + 6)
	calr HDAE5000_Cell_Get_Params
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
	lda_24 xwa, 0x201662                  ; 0x201662 (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	call HDAE5000_Display_Copy
	cp hl, 0xFFFF
	jr nz, .Lts929_2
	ldw hl, 0xFFFF
	jrl .Lts929_exit
.Lts929_2:
	ld xwa, (xsp + 6)
	cp xwa, 0x00008000
	jrl nz, .Lts929_5
.Lts929_loop:
	lda_24 xwa, 0x230f1c
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld_sril xhl, (xbc + 0x00a8)
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	cp xwa, 0x00000000
	jr le, .Lts929_4
	lda_24 xwa, 0x230f1c
	ld (xsp + 10), xwa
	ld xwa, (xsp + 6)
	calr HDAE5000_Cell_Get_Params
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
	lda_24 xwa, 0x201662                  ; 0x201662
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	call HDAE5000_Display_Restore
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
	lda_24 xwa, 0x20164f                  ; 0x20164F (flag base)
	add xwa, xhl
	ld (xwa), 0x01
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x00ac)
	call (xhl)
	ld hl, (xsp + 4)
.Lts929_exit:
	pop xiz
	lda xsp, (xsp + 32)
	ret

HDAE5000_Table_Sub_292ADE:	; 0x292ADE (288 bytes)
	lda xsp, (xsp - 34)
	push xiz
	ld (xsp + 34), bc	; save file number
	ld (xsp + 36), wa	; save partition
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
	call HDAE5000_MemCopy_Block
	lda xsp, (xsp + 18)	; clean up pushed args
	; Workspace dispatch with WA=6
	lda xwa, (xsp + 26)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)             ; (XWA+0x0080)
	lds wa, 6
	call (xhl)
	; Load constant and save
	ld xwa, 0x000072AA
	ld (xsp + 30), xwa
	; Second dispatch via XIX
	lda xwa, (xsp + 12)
	lda_24 xbc, 0x2f8f34                  ; 0x2F8F34
	ld32_24 xde, 0x23a1a2
	ld_sril xde, (xde + 0x0e88)
	ld_sril xix, (xde + 0x00a0)
	call (xix)
	cps hl, 0
	jrl lt, .Lts92a_error
	; Workspace dispatch: get handler
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
	ld xbc, (xsp + 30)
	ld32_24 xde, 0x23a1a2
	ld_sril xde, (xde + 0x0e88)
	ld_sril xhl, (xde + 0x00a8)             ; (XDE+0x00A8)
	call (xhl)
	; Save workspace base and get cell params
	lda_24 xwa, 0x230f1c
	ld (xsp + 4), xwa
	ld xwa, (xsp + 30)
	calr HDAE5000_Cell_Get_Params
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
	lda_24 xwa, 0x201666                  ; 0x201666 (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xsp + 8)
	call HDAE5000_Display_Copy
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
	lda_24 xwa, 0x201650                  ; 0x201650 (flag base)
	add xwa, xhl
	ld (xwa), 0x01
	; Final workspace dispatch
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x00ac)             ; (XWA+0x00AC)
	call (xhl)
	jr .Lts92a_load
.Lts92a_error:
	ldw (xsp + 10), 0xFFFF	; error: result = -1
.Lts92a_load:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 34)
	ret

HDAE5000_Table_Sub_292BFE:	; 0x292BFE (280 bytes)
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
	call HDAE5000_MemCopy_Block
	lda xsp, (xsp + 18)
	; Workspace dispatch with WA=7
	lda xwa, (xsp + 26)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)
	lds wa, 7
	call (xhl)
	; Second dispatch via XIX (no constant store)
	lda xwa, (xsp + 12)
	lda_24 xbc, 0x2f8f3e                  ; 0x2F8F3E
	ld32_24 xde, 0x23a1a2
	ld_sril xde, (xde + 0x0e88)
	ld_sril xix, (xde + 0x00a0)
	call (xix)
	cps hl, 0
	jrl lt, .Lts92b_error
	lda_24 xwa, 0x230f1c
	ld xbc, (xsp + 30)
	ld32_24 xde, 0x23a1a2
	ld_sril xde, (xde + 0x0e88)
	ld_sril xhl, (xde + 0x00a8)
	call (xhl)
	lda_24 xwa, 0x230f1c
	ld (xsp + 4), xwa
	ld xwa, (xsp + 30)
	calr HDAE5000_Cell_Get_Params
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
	lda_24 xwa, 0x20166a                  ; 0x20166A (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xsp + 8)
	call HDAE5000_Display_Copy
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
	lda_24 xwa, 0x201651                  ; 0x201651 (flag base)
	add xwa, xhl
	ld (xwa), 0x01
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x00ac)
	call (xhl)
	jr .Lts92b_load
.Lts92b_error:
	ldw (xsp + 10), 0xFFFF
.Lts92b_load:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 34)
	ret

HDAE5000_Table_Sub_292D16:	; 0x292D16 (419 bytes)
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
	call HDAE5000_MemCopy_Block
	lda xsp, (xsp + 18)
	lda xwa, (xsp + 18)
	lda_24 xbc, 0x2f8f48                  ; 0x2F8F48
	ld32_24 xde, 0x23a1a2
	ld_sril xde, (xde + 0x0e88)
	ld_sril xix, (xde + 0x00a0)
	call (xix)
	cps hl, 0
	jr ge, .Lts92d_1
	ldw hl, 0xFFFF
	jrl .Lts92d_exit
.Lts92d_1:
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld_sril xhl, (xbc + 0x00a8)
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 6), xhl
	lda_24 xwa, 0x230f1c
	ld (xsp + 10), xwa
	ld xwa, (xsp + 6)
	calr HDAE5000_Cell_Get_Params
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
	lda_24 xwa, 0x20166e                  ; 0x20166E (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	call HDAE5000_Display_Copy
	cp hl, 0xFFFF
	jr nz, .Lts92d_2
	ldw hl, 0xFFFF
	jrl .Lts92d_exit
.Lts92d_2:
	ld xwa, (xsp + 6)
	cp xwa, 0x00008000
	jrl nz, .Lts92d_5
.Lts92d_loop:
	lda_24 xwa, 0x230f1c
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld_sril xhl, (xbc + 0x00a8)
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	cp xwa, 0x00000000
	jr le, .Lts92d_4
	lda_24 xwa, 0x230f1c
	ld (xsp + 10), xwa
	ld xwa, (xsp + 6)
	calr HDAE5000_Cell_Get_Params
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
	lda_24 xwa, 0x20166e                  ; 0x20166E
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	call HDAE5000_Display_Restore
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
	lda_24 xwa, 0x201652                  ; 0x201652 (flag base)
	add xwa, xhl
	ld (xwa), 0x01
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x00ac)
	call (xhl)
	ld hl, (xsp + 4)
.Lts92d_exit:
	pop xiz
	lda xsp, (xsp + 32)
	ret

HDAE5000_Table_Sub_292EB9:	; 0x292EB9 (281 bytes)
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
	call HDAE5000_MemCopy_Block
	lda xsp, (xsp + 18)
	; Workspace dispatch with WA=9
	lda xwa, (xsp + 26)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)
	ldw wa, 0x0009
	call (xhl)
	; Second dispatch via XIX
	lda xwa, (xsp + 12)
	lda_24 xbc, 0x2f8f50                  ; 0x2F8F50
	ld32_24 xde, 0x23a1a2
	ld_sril xde, (xde + 0x0e88)
	ld_sril xix, (xde + 0x00a0)
	call (xix)
	cps hl, 0
	jrl lt, .Lts92e_error
	lda_24 xwa, 0x230f1c
	ld xbc, (xsp + 30)
	ld32_24 xde, 0x23a1a2
	ld_sril xde, (xde + 0x0e88)
	ld_sril xhl, (xde + 0x00a8)
	call (xhl)
	lda_24 xwa, 0x230f1c
	ld (xsp + 4), xwa
	ld xwa, (xsp + 30)
	calr HDAE5000_Cell_Get_Params
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
	lda_24 xwa, 0x201672                  ; 0x201672 (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xsp + 8)
	call HDAE5000_Display_Copy
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
	lda_24 xwa, 0x201653                  ; 0x201653 (flag base)
	add xwa, xhl
	ld (xwa), 0x01
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x00ac)
	call (xhl)
	jr .Lts92e_load
.Lts92e_error:
	ldw (xsp + 10), 0xFFFF
.Lts92e_load:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 34)
	ret

HDAE5000_Table_Sub_292FD2:	; 0x292FD2 (329 bytes)
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
	call HDAE5000_MemCopy_Block
	lda xsp, (xsp + 18)
	; Dispatch via XIX
	lda xwa, (xsp + 12)
	lda_24 xbc, 0x2f8f5a                  ; 0x2F8F5A
	ld32_24 xde, 0x23a1a2
	ld_sril xde, (xde + 0x0e88)
	ld_sril xix, (xde + 0x00a0)
	call (xix)
	cps hl, 0
	jrl lt, .Lts92f_error
	; Call 0x29AEC7 with args (8 bytes pushed, cleaned by inc 0)
	pushw 0x8000
	pushw 0x0000
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
	push xwa
	call HDAE5000_MemFill
	inc 0, xsp		; clean up 8 bytes
	; Workspace dispatch with XBC=0x16
	lda_24 xwa, 0x230f1c
	ld32_24 xbc, 0x23a1a2
	ld_sril xbc, (xbc + 0x0e88)
	ld_sril xhl, (xbc + 0x00a8)
	ld xbc, 0x00000016
	call (xhl)
	; Load param, call 0x28E5E9, sign extend result
	lda_24 xwa, 0x230f1c
	ld xwa, (xwa + 18)	; offset 0x12
	call HDAE5000_String_To_Upper
	ld iz, hl		; 16-bit result to IZ
	exts xiz		; sign extend to 32-bit
	ld xwa, xiz
	add xwa, 0x00000016
	calr HDAE5000_Cell_Get_Params
	ld (xsp + 30), xhl
	; Dispatch with XIZ as XBC param
	lda_24 xwa, 0x230f32                  ; 0x230F32
	ld xbc, xiz
	ld32_24 xde, 0x23a1a2
	ld_sril xde, (xde + 0x0e88)
	ld_sril xhl, (xde + 0x00a8)
	call (xhl)
	; Table lookup
	lda_24 xwa, 0x230f1c
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
	lda_24 xwa, 0x201676                  ; 0x201676 (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xsp + 8)
	ld xbc, (xbc)		; double dereference
	call HDAE5000_Display_Copy
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
	lda_24 xwa, 0x201654                  ; 0x201654 (flag base)
	add xwa, xhl
	ld (xwa), 0x01
	; Final workspace dispatch
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x00ac)
	call (xhl)
	jr .Lts92f_load
.Lts92f_error:
	ldw (xsp + 10), 0xFFFF
.Lts92f_load:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 34)
	ret

HDAE5000_Workspace_Handler:	; 0x29311B (592 bytes)
	; Part 1: Clear matching entries in workspace tables
	; Nested loop: IZ = 0..119, IY = 0..31
	; For each (IZ,IY), computes table index = IZ*9*16 + IY
	; If table[index] matches WA+1 AND table[index+0x20] matches BC+1,
	; clears 4 related entries at offsets 0xC2, 0xE2, 0x02, 0x22
	pushw iz
	lds iz, 0			; IZ = 0 (outer counter)
	cp iz, 0x0078
	jrl nc, .Lwh_outer_done		; skip if IZ >= 120
.Lwh_outer_loop:
	lds iy, 0			; IY = 0 (inner counter)
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
	lda_24 xde, 0x2257c2                  ; XDE = 0x2257C2
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
	lda_24 xde, 0x2257e2                  ; XDE = 0x2257E2
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
	lda_24 xde, 0x2257c2                  ; 0x2257C2
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
	lda_24 xde, 0x2257e2                  ; 0x2257E2
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
	lda_24 xde, 0x225802                  ; 0x225802
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
	lda_24 xde, 0x225822                  ; 0x225822
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
	dec 0, xsp			; callee cleanup placeholder
	push xiz
	ld (xsp + 6), de		; save DE (param)
	ld (xsp + 8), bc		; save BC (param)
	ld (xsp + 10), wa		; save WA (param)
	; Get handler through workspace chain
	ld32_24 xwa, 0x23a1a2                 ; (0x23A1A2) — workspace ptr
	ld_sril xwa, (xwa + 0x0e88)             ; XWA = (XWA+0x0E88)
	ld_sril xhl, (xwa + 0x00e8)             ; XHL = (XWA+0x00E8) — handler
	lds wa, 1			; param = 1
	call (xhl)
	; Conditional: if BC == 1, call extra handler
	cpw (xsp + 8), 0x0001
	jr nz, .Lwh_skip_extra
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)             ; XWA = (XWA+0x0E0A)
	ld_sril xhl, (xwa + 0x0538)             ; XHL = (XWA+0x0538)
	call (xhl)
.Lwh_skip_extra:
	call 0x297466
	ldw (xsp + 4), 0x0000		; slot counter = 0
	; Loop over 16 slots
	cpw (xsp + 4), 0x0010
	jrl nc, .Lwh_loop_done
.Lwh_slot_loop:
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Table_Calc_Offset
	cp hl, 0xFFFF
	jr z, .Lwh_slot_fill
	; Process slot — call all 10 render types
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type0
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type1
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type2
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type3
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type4
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type5
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type6
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type7
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type8
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Workspace_Handler	; recursive call (clear matching)
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
	ld xwa, 0x00201632		; table base address
	add xwa, xhl			; absolute address
	push xwa			; push fill dest
	call HDAE5000_MemFill
	inc 0, xsp			; stack cleanup (no-op)
	incm 1, (xsp + 4)		; slot counter++
	cpw (xsp + 4), 0x0010
	jrl c, .Lwh_slot_loop
.Lwh_loop_done:
	; Post-loop: fill final block
	pushw 0x0010			; block count
	pushw 0x0020			; block params
	ld wa, (xsp + 14)		; WA (adjusted)
	extz xwa
	sll xwa, 4			; * 16
	ld xbc, 0x00201632		; table base
	add xbc, xwa
	push xbc			; push fill dest
	call HDAE5000_MemFill
	inc 0, xsp			; stack cleanup
	; Final handler calls
	call 0x297A78
	cpw (xsp + 6), 0x0001	; DE == 1?
	call_24 nz, 2716853		; call nz, 0x2974B5
	cpw (xsp + 8), 0x0001	; BC == 1?
	jr nz, .Lwh_skip_final
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)             ; XWA = (XWA+0x0E0A)
	ld_sril xhl, (xwa + 0x053c)             ; XHL = (XWA+0x053C)
	call (xhl)
.Lwh_skip_final:
	; Workspace cleanup calls
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x00ec)             ; XHL = (XWA+0x00EC)
	call (xhl)
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x00f0)             ; XHL = (XWA+0x00F0)
	call (xhl)
	pop xiz
	inc 0, xsp			; stack cleanup
	ret

HDAE5000_Workspace_Sub_29336B:	; 0x29336B (349 bytes)
	dec 4, xsp
	push xiz
	ld iz, de
	ld (xsp + 4), bc	; save file number
	ld (xsp + 6), wa	; save partition
	cps iz, 0
	jrl z, .Lws36b_exit	; nothing to do
	; Workspace dispatch at 0xE8
	ld32_24 xwa, 0x23a1a2                 ; 0x23A1A2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x00e8)
	lds wa, 1
	call (xhl)
	; Check workspace flag at (xsp+14)
	cpw (xsp + 14), 0x0001
	jr nz, .Lws36b_skip1
	; Workspace dispatch at 0x0538
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0538)
	call (xhl)
.Lws36b_skip1:
	call 0x297466
	; Bitmask dispatch: test bits of IZ, call corresponding renderers
	bit 0, iz
	jr z, .Lws36b_bit1
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type0
.Lws36b_bit1:
	bit 1, iz
	jr z, .Lws36b_bit2
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type1
.Lws36b_bit2:
	bit 2, iz
	jr z, .Lws36b_bit3
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type2
.Lws36b_bit3:
	bit 3, iz
	jr z, .Lws36b_bit4
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type3
.Lws36b_bit4:
	bit 4, iz
	jr z, .Lws36b_bit5
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type4
.Lws36b_bit5:
	bit 5, iz
	jr z, .Lws36b_bit6
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type5
.Lws36b_bit6:
	bit 6, iz
	jr z, .Lws36b_bit7
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type6
.Lws36b_bit7:
	bit 7, iz
	jr z, .Lws36b_bit8
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type7
.Lws36b_bit8:
	bit 8, iz
	jr z, .Lws36b_calc
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type8
.Lws36b_calc:
	; Calculate table offset
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Table_Calc_Offset
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
	ld xwa, 0x00201632
	add xwa, xhl
	push xwa
	call HDAE5000_MemFill
	inc 0, xsp
	; Call workspace handler
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Workspace_Handler
.Lws36b_post:
	call 0x297A78
	; Conditional call NZ to 0x2974B5
	cpw (xsp + 12), 0x0001
	call_24 nz, 2716853	; call nz, 0x2974B5
	; Check workspace flag at (xsp+14)
	cpw (xsp + 14), 0x0001
	jr nz, .Lws36b_skip2
	; Workspace dispatch at 0x053C
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x053c)
	call (xhl)
.Lws36b_skip2:
	; Workspace dispatch at 0xEC
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x00ec)
	call (xhl)
	; Workspace dispatch at 0xF0
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x00f0)
	call (xhl)
.Lws36b_exit:
	pop xiz
	inc 4, xsp
	retd 4

; --- UI Cell Renderers (9 x 222 bytes each) ---
; Delete table entry: check existence, call handler, clear entry (-1), clear flag (0)
HDAE5000_Cell_Render_Type0:	; 0x2934C8 (222 bytes)
	dec 4, xsp
	push xiz
	ld (xsp + 4), bc	; save file number
	ld (xsp + 6), wa	; save partition
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
	lda_24 xwa, 0x201656                  ; 0x201656 (table base)
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
	lda_24 xwa, 0x201656                  ; 0x201656
	add xwa, xhl
	ld xwa, (xwa)
	call 0x298590
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
	lda_24 xwa, 0x201656                  ; 0x201656
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
	lda_24 xwa, 0x20164c                  ; 0x20164C (flag base)
	add xwa, xhl
	ld (xwa), 0x00
.Lcr0_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_Cell_Render_Type1:	; 0x2935A6 (222 bytes)
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
	lda_24 xwa, 0x20165a                  ; 0x20165A (table base)
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
	lda_24 xwa, 0x20165a                  ; 0x20165A
	add xwa, xhl
	ld xwa, (xwa)
	call 0x298590
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
	lda_24 xwa, 0x20165a                  ; 0x20165A
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
	lda_24 xwa, 0x20164d                  ; 0x20164D (flag base)
	add xwa, xhl
	ld (xwa), 0x00
.Lcr1_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_Cell_Render_Type2:	; 0x293684 (222 bytes)
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
	lda_24 xwa, 0x20165e                  ; 0x20165E (table base)
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
	lda_24 xwa, 0x20165e                  ; 0x20165E
	add xwa, xhl
	ld xwa, (xwa)
	call 0x298590
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
	lda_24 xwa, 0x20165e                  ; 0x20165E
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
	lda_24 xwa, 0x20164e                  ; 0x20164E (flag base)
	add xwa, xhl
	ld (xwa), 0x00
.Lcr2_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_Cell_Render_Type3:	; 0x293762 (222 bytes)
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
	lda_24 xwa, 0x201662                  ; 0x201662 (table base)
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
	lda_24 xwa, 0x201662                  ; 0x201662
	add xwa, xhl
	ld xwa, (xwa)
	call 0x298590
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
	lda_24 xwa, 0x201662                  ; 0x201662
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
	lda_24 xwa, 0x20164f                  ; 0x20164F (flag base)
	add xwa, xhl
	ld (xwa), 0x00
.Lcr3_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_Cell_Render_Type4:	; 0x293840 (222 bytes)
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
	lda_24 xwa, 0x201666                  ; 0x201666 (table base)
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
	lda_24 xwa, 0x201666                  ; 0x201666
	add xwa, xhl
	ld xwa, (xwa)
	call 0x298590
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
	lda_24 xwa, 0x201666                  ; 0x201666
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
	lda_24 xwa, 0x201650                  ; 0x201650 (flag base)
	add xwa, xhl
	ld (xwa), 0x00
.Lcr4_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_Cell_Render_Type5:	; 0x29391E (222 bytes)
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
	lda_24 xwa, 0x20166a                  ; 0x20166A (table base)
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
	lda_24 xwa, 0x20166a                  ; 0x20166A
	add xwa, xhl
	ld xwa, (xwa)
	call 0x298590
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
	lda_24 xwa, 0x20166a                  ; 0x20166A
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
	lda_24 xwa, 0x201651                  ; 0x201651 (flag base)
	add xwa, xhl
	ld (xwa), 0x00
.Lcr5_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_Cell_Render_Type6:	; 0x2939FC (222 bytes)
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
	lda_24 xwa, 0x20166e                  ; 0x20166E (table base)
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
	lda_24 xwa, 0x20166e                  ; 0x20166E
	add xwa, xhl
	ld xwa, (xwa)
	call 0x298590
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
	lda_24 xwa, 0x20166e                  ; 0x20166E
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
	lda_24 xwa, 0x201652                  ; 0x201652 (flag base)
	add xwa, xhl
	ld (xwa), 0x00
.Lcr6_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_Cell_Render_Type7:	; 0x293ADA (222 bytes)
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
	lda_24 xwa, 0x201672                  ; 0x201672 (table base)
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
	lda_24 xwa, 0x201672                  ; 0x201672
	add xwa, xhl
	ld xwa, (xwa)
	call 0x298590
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
	lda_24 xwa, 0x201672                  ; 0x201672
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
	lda_24 xwa, 0x201653                  ; 0x201653 (flag base)
	add xwa, xhl
	ld (xwa), 0x00
.Lcr7_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_Cell_Render_Type8:	; 0x293BB8 (222 bytes)
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
	lda_24 xwa, 0x201676                  ; 0x201676 (table base)
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
	lda_24 xwa, 0x201676                  ; 0x201676
	add xwa, xhl
	ld xwa, (xwa)
	call 0x298590
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
	lda_24 xwa, 0x201676                  ; 0x201676
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
	lda_24 xwa, 0x201654                  ; 0x201654 (flag base)
	add xwa, xhl
	ld (xwa), 0x00
.Lcr8_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_Cell_Validate:	; 0x293C96 (347 bytes)
	; Validate cell rendering — tests bits 0-8, accumulates sizes in XIZ
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 14), wa		; save bitmask
	ldw (xsp + 4), 0x0000		; init result = 0
	lds32 xiz, 0			; accumulator = 0
	; --- Bit 0: call handler(0) and handler(1) ---
	ld wa, (xsp + 14)
	bit 0, wa
	jr z, .Lcv_bit1
	lda xwa, (xsp + 6)		; XWA = scratch buffer address
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2                 ; (0x23A1A2) — workspace ptr
	ld_sril xwa, (xwa + 0x0e88)             ; XWA = (XWA+0x0E88)
	ld_sril xhl, (xwa + 0x0080)             ; XHL = (XWA+0x0080) — handler
	lds wa, 0			; param = 0
	call (xhl)
	add xiz, (xsp + 10)		; accumulate size
	lda xwa, (xsp + 6)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)
	lds wa, 1			; param = 1
	call (xhl)
	add xiz, (xsp + 10)
	; --- Bit 1: call handler(2) ---
.Lcv_bit1:
	ld wa, (xsp + 14)
	bit 1, wa
	jr z, .Lcv_bit2
	lda xwa, (xsp + 6)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)
	lds wa, 2			; param = 2
	call (xhl)
	add xiz, (xsp + 10)
	; --- Bit 2: call handler(3) + extra handler at +0x34 ---
.Lcv_bit2:
	ld wa, (xsp + 14)
	bit 2, wa
	jr z, .Lcv_bit3
	lda xwa, (xsp + 6)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)
	lds wa, 3			; param = 3
	call (xhl)
	add xiz, (xsp + 10)
	; Extra handler at +0x34
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld xix, (xwa + 0x34)
	call (xix)
	add xiz, xhl
	; --- Bit 3: handler at +0x44 ---
.Lcv_bit3:
	ld wa, (xsp + 14)
	bit 3, wa
	jr z, .Lcv_bit4
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld xix, (xwa + 0x44)
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
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld xix, (xwa + 0x64)
	call (xix)
	add xiz, xhl
	; --- Bit 6: call handler(8) ---
.Lcv_bit6:
	ld wa, (xsp + 14)
	bit 6, wa
	jr z, .Lcv_bit7
	lda xwa, (xsp + 6)
	ld xbc, xwa
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)
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
	ld32_24 xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e88)
	ld_sril xhl, (xwa + 0x0080)
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
	call 0x298C7D			; validate total
	ld xiz, xhl			; save result
	call 0x297D35			; get available space
	cp xhl, xiz			; available > needed?
	jr ugt, .Lcv_done
	ldw (xsp + 4), 0xFFFF		; set error flag
.Lcv_done:
	ld hl, (xsp + 4)
	pop xiz
	lda xsp, (xsp + 12)
	ret

HDAE5000_Cell_Get_Params:	; 0x293DF1 (61 bytes)
	; Get cell rendering parameters from data source
	; Input: XWA = source pointer (0 = use default address 0x200)
	; Output: XHL = parameter block pointer
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
	call HDAE5000_Cell_Copy_Buffer
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

HDAE5000_Display_Callback:	; 0x293E2E (1093 bytes)
	; Display callback handler via workspace
; LDC: 0x293E2E (1093 bytes)

	dec	2, xsp
	pushw iz                                ; push IZ
	ld (xsp + 0x02), wa                     ; ld (XSP+0x02),WA
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00e8)
	lds	wa, 1
	call	(xhl)
	call 0x297466
	ld	iz, hl
	call 0x297a78
	or	iz, hl
	cpw	(xsp+2), 0x0001
	jr z, .LDC_3e60                        ; [66 06] jr Z,0x293e60
	call 0x2974b5
	or	iz, hl
.LDC_3e60:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00ec)
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00f0)
	call	(xhl)
	ld	hl, iz
	popw iz                                 ; pop IZ
	inc 2, xsp                              ; inc 2,XSP
	ret

	dec	2, xsp
	pushw iz                                ; push IZ
	ld (xsp + 0x02), wa                     ; ld (XSP+0x02),WA
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00e8)
	lds	wa, 1
	call	(xhl)
	call 0x297466
	ld	iz, hl
	call 0x297bd4
	or	iz, hl
	cpw	(xsp+2), 0x0001
	jr z, .LDC_3eba                        ; [66 06] jr Z,0x293eba
	call 0x2974b5
	or	iz, hl
.LDC_3eba:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00ec)
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00f0)
	call	(xhl)
	ld	hl, iz
	popw iz                                 ; pop IZ
	inc 2, xsp                              ; inc 2,XSP
	ret

	dec	2, xsp
	pushw iz                                ; push IZ
	ld (xsp + 0x02), wa                     ; ld (XSP+0x02),WA
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00e8)
	lds	wa, 1
	call	(xhl)
	call 0x297466
	ld	iz, hl
	call 0x2998e4
	or	iz, hl
	cpw	(xsp+2), 0x0001
	jr z, .LDC_3f14                        ; [66 06] jr Z,0x293f14
	call 0x2974b5
	or	iz, hl
.LDC_3f14:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00ec)
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00f0)
	call	(xhl)
	ld	hl, iz
	popw iz                                 ; pop IZ
	inc 2, xsp                              ; inc 2,XSP
	ret

	dec	2, xsp
	pushw iz                                ; push IZ
	ld (xsp + 0x02), wa                     ; ld (XSP+0x02),WA
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00e8)
	lds	wa, 1
	call	(xhl)
	call 0x297466
	ld	iz, hl
	call 0x29992b
	or	iz, hl
	cpw	(xsp+2), 0x0001
	jr z, .LDC_3f6e                        ; [66 06] jr Z,0x293f6e
	call 0x2974b5
	or	iz, hl
.LDC_3f6e:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00ec)
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x00f0)
	call	(xhl)
	ld	hl, iz
	popw iz                                 ; pop IZ
	inc 2, xsp                              ; inc 2,XSP
	ret

	lda	xsp, (xsp-12)
	push xiz
	ld (xsp + 0x0c), xbc                    ; ld (XSP+0x0c),XBC
	ld16_24	bc, 0x238F1C
	cps	bc, 1
	jr z, .LDC_3fff                        ; [66 59] jr Z,0x293fff
	cps	bc, 0
	jrl nz, .LDC_4053                      ; [7e a8 00] jrl NZ,0x294053
	ld (xsp + 0x04), xwa                    ; ld (XSP+0x04),XWA
	ld xwa, (xsp + 0x0c)                    ; ld XWA,(XSP+0x0c)
	ld (xsp + 0x08), xwa                    ; ld (XSP+0x08),XWA
	ld16_24	wa, 0x238F20
	extz xwa
	ld	xbc, 0x0000004c
	call HDAE5000_Multiply
	ld	xiz, xhl
	ld16_24	wa, 0x238F1E
	extz xwa
	ld	xbc, 0x000004c0
	call HDAE5000_Multiply
	add	xhl, 0x00000780
	add	xhl, xiz
	lda_24 xwa, 0x20166e
	add	xwa, xhl
	ld	xde, xwa
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xbc, (xsp + 0x08)                    ; ld XBC,(XSP+0x08)
	call 0x29811c
	ld	(0x238f22), hl
	sti16_24	0x238F1C, 1
	jr t, .LDC_4061                        ; [68 62] jr T,0x294061
.LDC_3fff:
	ld (xsp + 0x04), xwa                    ; ld (XSP+0x04),XWA
	ld xwa, (xsp + 0x0c)                    ; ld XWA,(XSP+0x0c)
	ld (xsp + 0x08), xwa                    ; ld (XSP+0x08),XWA
	ld16_24	wa, 0x238F20
	extz xwa
	ld	xbc, 0x0000004c
	call HDAE5000_Multiply
	ld	xiz, xhl
	ld16_24	wa, 0x238F1E
	extz xwa
	ld	xbc, 0x000004c0
	call HDAE5000_Multiply
	add	xhl, 0x00000780
	add	xhl, xiz
	lda_24 xwa, 0x20166e
	add	xwa, xhl
	ld	xde, xwa
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xbc, (xsp + 0x08)                    ; ld XBC,(XSP+0x08)
	call 0x2981c0
	ld	(0x238f22), hl
	sti16_24	0x238F1C, 1
	jr t, .LDC_4061                        ; [68 0e] jr T,0x294061
.LDC_4053:
	sti16_24	0x238F22, 65535
	sti16_24	0x238F1C, 0
.LDC_4061:
	ld xhl, (xsp + 0x0c)                    ; ld XHL,(XSP+0x0c)
	pop xiz                                 ; pop XIZ
	lda	xsp, (xsp+12)
	ret

	dec	6, xsp
	push xiz
	ld (xsp + 0x06), xbc                    ; ld (XSP+0x06),XBC
	ld16_24	bc, 0x238F1C
	cps	bc, 2
	jr z, .LDC_40da                        ; [66 62] jr Z,0x2940da
	cps	bc, 0
	jrl nz, .LDC_4137                      ; [7e ba 00] jrl NZ,0x294137
	ld xbc, (xsp + 0x06)                    ; ld XBC,(XSP+0x06)
	calr	0x027e
	cp	hl, 0xffff
	jr z, .LDC_40cb                        ; [66 42] jr Z,0x2940cb
	ldw (xsp + 0x04), 0
	ld16_24	wa, 0x238F20
	extz xwa
	ld	xbc, 0x0000004c
	call HDAE5000_Multiply
	ld	xiz, xhl
	ld16_24	wa, 0x238F1E
	extz xwa
	ld	xbc, 0x000004c0
	call HDAE5000_Multiply
	add	xhl, 0x00000780
	add	xhl, xiz
	lda_24 xwa, 0x201652
	add	xwa, xhl
	ld	(xwa), 0x01
	sti16_24	0x238F1C, 2
	jr t, .LDC_40d0                        ; [68 05] jr T,0x2940d0
.LDC_40cb:
	ldw (xsp + 0x04), 65535
.LDC_40d0:
	ld	wa, (xsp+4)
	ld	(0x238f22), wa
	jr t, .LDC_4145                        ; [68 6b] jr T,0x294145
.LDC_40da:
	ld xbc, (xsp + 0x06)                    ; ld XBC,(XSP+0x06)
	calr	0x0221
	cp	hl, 0xffff
	jr z, .LDC_4128                        ; [66 42] jr Z,0x294128
	ldw (xsp + 0x04), 0
	ld16_24	wa, 0x238F20
	extz xwa
	ld	xbc, 0x0000004c
	call HDAE5000_Multiply
	ld	xiz, xhl
	ld16_24	wa, 0x238F1E
	extz xwa
	ld	xbc, 0x000004c0
	call HDAE5000_Multiply
	add	xhl, 0x00000780
	add	xhl, xiz
	lda_24 xwa, 0x201652
	add	xwa, xhl
	ld	(xwa), 0x01
	sti16_24	0x238F1C, 2
	jr t, .LDC_412d                        ; [68 05] jr T,0x29412d
.LDC_4128:
	ldw (xsp + 0x04), 65535
.LDC_412d:
	ld	wa, (xsp+4)
	ld	(0x238f22), wa
	jr t, .LDC_4145                        ; [68 0e] jr T,0x294145
.LDC_4137:
	sti16_24	0x238F22, 65535
	sti16_24	0x238F1C, 0
.LDC_4145:
	ld xhl, (xsp + 0x06)                    ; ld XHL,(XSP+0x06)
	pop xiz                                 ; pop XIZ
	inc	6, xsp
	ret

	ld16_24	hl, 0x238F22
	ret

	lda	xsp, (xsp-16)
	lda	xwa, (xsp)
	call 0x298b6c
	ld xhl, (xsp + 0x0c)                    ; ld XHL,(XSP+0x0c)
	sll	xhl, 0x0a
	lda	xsp, (xsp+16)
	ret

	cps	wa, 2
	jr z, .LDC_4195                        ; [66 2c] jr Z,0x294195
	cps	wa, 1
	jr z, .LDC_4183                        ; [66 16] jr Z,0x294183
	cps	wa, 0
	ret nz                                  ; ret NZ

	lda_24 xwa, 0x201632
	ld (xbc), xwa                           ; ld (XBC),XWA
	ldw	(xbc+4), 0x0010
	ldw	(xbc+6), 0x0078
	ret

.LDC_4183:
	lda_24 xwa, 0x201db2
	ld (xbc), xwa                           ; ld (XBC),XWA
	ldw	(xbc+4), 0x004c
	ldw	(xbc+6), 0x0780
	ret

.LDC_4195:
	lda_24 xwa, 0x2257b2
	ld (xbc), xwa                           ; ld (XBC),XWA
	ldw	(xbc+4), 0x0090
	ldw	(xbc+6), 0x0078
	ldw	(xbc+8), 0x0020
	ret

	dec 0, xsp                              ; dec 0,XSP
	push xiz
	ld (xsp + 0x04), xde                    ; ld (XSP+0x04),XDE
	ld (xsp + 0x08), bc
	ld (xsp + 0x0a), wa                     ; ld (XSP+0x0a),WA
	ld	wa, (xsp+10)
	ld	bc, (xsp+8)
	calr	0xc1f2
	ld	wa, hl
	cp	wa, 0xffff
	jrl z, .LDC_426f                       ; [76 a5 00] jrl Z,0x29426f
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld (xwa), hl                            ; ld (XWA),HL
	pushw 0x0010
	ld	wa, (xsp+12)
	extz xwa
	sll	xwa, 0x04
	ld	xbc, 0x00201632
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
	ld	xwa, 0x00201632
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
	lda_24 xwa, 0x20164c
	add	xwa, xhl
	push xwa
	ld xwa, (xsp + 0x0a)                    ; ld XWA,(XSP+0x0a)
	lda	xwa, (xwa+44)
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+10)
	lds	hl, 0
.LDC_426f:
	pop xiz                                 ; pop XIZ
	inc 0, xsp                              ; inc 0,XSP
	ret


HDAE5000_Display_Sub_294273:	; 0x294273 (43 bytes)
	; Set up display callback with function pointer
	; Input: XWA = callback function pointer
	; Output: HL = 0 (success) or 0xFFFF (already active)
	cpi8_24 0x238f2c, 0x00                 ; check if callback is active (0x238F2C)
	jr z, .Lds273_setup
	sti8_24 0x238f2c, 0x00                 ; clear active flag
	ldw hl, 0xFFFF			; return -1 (already active)
	jr t, .Lds273_done
.Lds273_setup:
	lda_24 xbc, 0x230f1c                  ; 0x230F1C - callback table base
	st32_24 0x238f24, xbc                 ; 0x238F24 - store table pointer
	st32_24 0x238f28, xwa                 ; 0x238F28 - store callback function
	sti8_24 0x238f2c, 0x01                 ; 0x238F2C - set active flag
	lds hl, 0			; return 0 (success)
.Lds273_done:
	ret

HDAE5000_Display_Sub_29429E:	; 0x29429E (99 bytes)
	; Execute display callback and restore display state
	; Checks callback state flag and dispatches to copy or restore
	lda_24 xwa, 0x230f1c                  ; 0x230F1C - RAM test area base
	cpda32_24 xwa, 2330404		; compare with stored table pointer (0x238F24)
	jr z, .Lds29e_clear
	cpi8_24 0x238f2c, 0x01                 ; check active flag == 1 (0x238F2C)
	jr nz, .Lds29e_restore
	; State 1: copy display block
	lda_24 xwa, 0x230f1c                  ; XWA = base address
	ld xhl, xwa			; XHL = dest (base)
	lda_24 xbc, 0x230f1c                  ; XBC = base
	ld32_24 xwa, 0x238f24                 ; XWA = stored table pointer
	sub xwa, xbc			; XWA = offset (table - base)
	ld xbc, xwa			; XBC = size
	ld32_24 xde, 0x238f28                 ; XDE = callback function (0x238F28)
	ld xwa, xhl			; XWA = dest address
	call HDAE5000_Display_Copy
	sti8_24 0x238f2c, 0x02                 ; set state to 2
	jr t, .Lds29e_clear
.Lds29e_restore:
	; State 2+: restore display block
	lda_24 xwa, 0x230f1c                  ; XWA = base address
	ld xhl, xwa
	lda_24 xbc, 0x230f1c                  ; XBC = base
	ld32_24 xwa, 0x238f24                 ; XWA = stored table pointer
	sub xwa, xbc			; XWA = offset
	ld xbc, xwa			; XBC = size
	ld32_24 xde, 0x238f28                 ; XDE = callback function
	ld xwa, xhl			; XWA = dest address
	call HDAE5000_Display_Restore
.Lds29e_clear:
	sti8_24 0x238f2c, 0x00                 ; clear active flag
	ret

HDAE5000_Display_Sub_294301:	; 0x294301 (275 bytes)
	lda xsp, (xsp - 14)
	push xiz
	ld (xsp + 10), xbc		; save arg1
	ld (xsp + 14), xwa		; save arg0
	ldw (xsp + 8), 0x0000		; init result = 0
	ld8_24 a, 0x238f2c                    ; load active flag (0x238F2C)
	cps a, 2
	jr z, .Lds301_mode2
	cps a, 1
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
	lda_24 xwa, 0x238f1c                  ; XWA = 0x238F1C (base address)
	sub32_24 xwa, 0x238f24                ; XWA -= (0x238F24) => remaining space
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
	ld32_24 xwa, 0x238f24                 ; XWA = current position
	push xwa			; push dest
	call HDAE5000_MemCopy
	ld xwa, xiz			; XWA = total size
	sub xwa, 0x0000FFFF		; remainder after first chunk
	pushw wa			; push remainder count
	ld xwa, (xsp + 26)		; reload arg0 (deep stack)
	add xwa, 0x0000FFFF		; advance source by 0xFFFF
	push xwa			; push adjusted source
	ld32_24 xwa, 0x238f24                 ; reload current position
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
	ld32_24 xwa, 0x238f24                 ; current position
	push xwa			; push dest
	call HDAE5000_MemCopy
	lda xsp, (xsp + 10)		; cleanup 10 bytes of args
.Lds301_update:
	add (xsp + 14), xiz		; advance arg0 by transferred size
	addm32_24 0x238f24, xiz                ; advance current position
	sub (xsp + 4), xiz		; decrease remaining
	ld xwa, (xsp + 4)		; check if remaining > 0
	or xwa, xwa
	jr nz, .Lds301_finalize
	; Remaining exhausted — handle based on active flag
	cpi8_24 0x238f2c, 0x01                 ; active flag == 1?
	jr nz, .Lds301_flag2
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
	ld32_24 xde, 0x238f28                 ; XDE = callback
	ld xbc, 0x00008000
	call HDAE5000_Display_Copy
	ld (xsp + 8), hl		; save result
	sti8_24 0x238f2c, 0x02                 ; set active flag = 2
	jr .Lds301_check_result
.Lds301_flag2:
	lda_24 xwa, 0x230f1c                  ; 0x230F1C
	ld32_24 xde, 0x238f28                 ; XDE = callback
	ld xbc, 0x00008000
	call HDAE5000_Display_Restore
	ld (xsp + 8), hl		; save result
.Lds301_check_result:
	cpw (xsp + 8), 0x0000	; result == 0?
	jr nz, .Lds301_exit_result
	lda_24 xwa, 0x230f1c                  ; 0x230F1C — reset position
	st32_24 0x238f24, xwa                 ; store to current position
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

HDAE5000_Display_Sub_294414:	; 0x294414 (3061 bytes)
	; Large display management routine
; LDS: 0x294414 (3061 bytes)

	ret

	ret

	lda	xsp, (xsp-32)
	lda_24 xwa, 0x2f8f5e
	calr	0xfff3
	lda_24 xwa, 0x238f2e
	push xwa
	pushw 0x002f
	pushw 0x8f7c
	lda	xwa, (xsp+8)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	lda	xwa, (xsp)
	calr	0xffd7
	lda_24 xwa, 0x2f8f8c
	calr	0xffcf
	lda_24 xhl, 0x238f2e
	lda	xsp, (xsp+32)
	ret

	pushw iz                                ; push IZ
	lds	iz, 0
	call 0x2974b5
	cp	hl, 0xffff
	jr nz, .LDS_445d                       ; [6e 02] jr NZ,0x29445d
	lds	iz, 1
.LDS_445d:
	lda_24 xwa, 0x2f8f8e
	calr	0xffaf
	lda_24 xwa, 0x2f8fa8
	calr	0xffa7
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

	lda	xsp, (xsp-116)
	lda	xwa, (xsp+64)
	call 0x297573
	pushw 0x001e
	lda	xwa, (xsp+76)
	push xwa
	lda_24 xwa, 0x238fc5
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
	sti16_24	0x238FEB, 512
	ld8_24	a, 0x23A04A
	st8_24	0x238FF6, a
	ld8_24	a, 0x23A04C
	st8_24	0x238FF7, a
	lda_24 xwa, 0x2f8faa
	calr	0xff48
	pushw 0x002f
	pushw 0x8fc6
	lda	xwa, (xsp+4)
	push xwa
	call HDAE5000_PPI_Block_Copy
	pushw 0x001e
	lda_24 xwa, 0x238fc5
	push xwa
	lda	xwa, (xsp+24)
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+18)
	lda	xwa, (xsp)
	calr	0xff21
	ld	xwa, (0x238fe3)
	push xwa
	pushw 0x002f
	pushw 0x8fd2
	lda	xwa, (xsp+8)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	lda	xwa, (xsp)
	calr	0xff05
	pushdi_24	0x238FE7
	pushw 0x002f
	pushw 0x8fe0
	lda	xwa, (xsp+6)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+10)
	lda	xwa, (xsp)
	calr	0xfeea
	pushdi_24	0x238FE9
	pushw 0x002f
	pushw 0x8fee
	lda	xwa, (xsp+6)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+10)
	lda	xwa, (xsp)
	calr	0xfecf
	pushdi_24	0x238FEB
	pushw 0x002f
	pushw 0x8ffc
	lda	xwa, (xsp+6)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+10)
	lda	xwa, (xsp)
	calr	0xfeb4
	lda_24 xwa, 0x2f900a
	calr	0xfeac
	lds	hl, 0
	lda	xsp, (xsp+116)
	ret

	lda	xsp, (xsp-74)
	lda	xwa, (xsp+64)
	ld	xbc, xwa
	lds	wa, 0
	call 0x294165
	ld xwa, (xsp + 0x40)                    ; ld XWA,(XSP+0x40)
	ld	(0x238f5a), xwa
	ld	wa, (xsp+68)
	ld	(0x238f5e), wa
	ld	wa, (xsp+70)
	ld	(0x238f60), wa
	lda_24 xwa, 0x2f900c
	calr	0xfe78
	ld	xwa, (0x238f5a)
	push xwa
	pushw 0x002f
	pushw 0x902e
	lda	xwa, (xsp+8)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	lda	xwa, (xsp)
	calr	0xfe5c
	pushdi_24	0x238F5E
	pushw 0x002f
	pushw 0x903c
	lda	xwa, (xsp+6)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+10)
	lda	xwa, (xsp)
	calr	0xfe41
	pushdi_24	0x238F60
	pushw 0x002f
	pushw 0x904a
	lda	xwa, (xsp+6)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+10)
	lda	xwa, (xsp)
	calr	0xfe26
	lda_24 xwa, 0x2f9058
	calr	0xfe1e
	lda	xsp, (xsp+74)
	ret

	lda	xsp, (xsp-74)
	lda	xwa, (xsp+64)
	ld	xbc, xwa
	lds	wa, 1
	call 0x294165
	ld xwa, (xsp + 0x40)                    ; ld XWA,(XSP+0x40)
	ld	(0x238f62), xwa
	ld	wa, (xsp+68)
	ld	(0x238f66), wa
	ld	wa, (xsp+70)
	ld	(0x238f68), wa
	lda_24 xwa, 0x2f905a
	calr	0xfdec
	ld	xwa, (0x238f62)
	push xwa
	pushw 0x002f
	pushw 0x9082
	lda	xwa, (xsp+8)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	lda	xwa, (xsp)
	calr	0xfdd0
	pushdi_24	0x238F66
	pushw 0x002f
	pushw 0x9090
	lda	xwa, (xsp+6)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+10)
	lda	xwa, (xsp)
	calr	0xfdb5
	pushdi_24	0x238F68
	pushw 0x002f
	pushw 0x909e
	lda	xwa, (xsp+6)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+10)
	lda	xwa, (xsp)
	calr	0xfd9a
	lda_24 xwa, 0x2f90ac
	calr	0xfd92
	lda	xsp, (xsp+74)
	ret

	lda	xsp, (xsp-74)
	lda	xwa, (xsp+64)
	ld	xbc, xwa
	lds	wa, 2
	call 0x294165
	ld xwa, (xsp + 0x40)                    ; ld XWA,(XSP+0x40)
	ld	(0x238f6a), xwa
	ld	wa, (xsp+68)
	ld	(0x238f6e), wa
	ld	wa, (xsp+70)
	ld	(0x238f70), wa
	ld	wa, (xsp+72)
	ld	(0x238f72), wa
	lda_24 xwa, 0x2f90ae
	calr	0xfd58
	ld	xwa, (0x238f6a)
	push xwa
	pushw 0x002f
	pushw 0x90d0
	lda	xwa, (xsp+8)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	lda	xwa, (xsp)
	calr	0xfd3c
	pushdi_24	0x238F6E
	pushw 0x002f
	pushw 0x90de
	lda	xwa, (xsp+6)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+10)
	lda	xwa, (xsp)
	calr	0xfd21
	pushdi_24	0x238F70
	pushw 0x002f
	pushw 0x90ec
	lda	xwa, (xsp+6)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+10)
	lda	xwa, (xsp)
	calr	0xfd06
	pushdi_24	0x238F72
	pushw 0x002f
	pushw 0x90fa
	lda	xwa, (xsp+6)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+10)
	lda	xwa, (xsp)
	calr	0xfceb
	lda_24 xwa, 0x2f9108
	calr	0xfce3
	lda	xsp, (xsp+74)
	ret

	pushw iz                                ; push IZ
	lds	iz, 0
	lds	wa, 1
	call 0x293e88
	cp	hl, 0xffff
	jr nz, .LDS_4746                       ; [6e 02] jr NZ,0x294746
	lds	iz, 1
.LDS_4746:
	lda_24 xwa, 0x2f910a
	calr	0xfcc6
	lda_24 xwa, 0x2f9128
	calr	0xfcbe
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

	pushw iz                                ; push IZ
	lds	iz, 0
	lds	wa, 1
	call 0x293e88
	cp	hl, 0xffff
	jr nz, .LDS_476b                       ; [6e 02] jr NZ,0x29476b
	lds	iz, 1
.LDS_476b:
	lda_24 xwa, 0x2f912a
	calr	0xfca1
	lda_24 xwa, 0x2f9148
	calr	0xfc99
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

	pushw iz                                ; push IZ
	lds	iz, 0
	lds	wa, 1
	call 0x293e88
	cp	hl, 0xffff
	jr nz, .LDS_4790                       ; [6e 02] jr NZ,0x294790
	lds	iz, 1
.LDS_4790:
	lda_24 xwa, 0x2f914a
	calr	0xfc7c
	lda_24 xwa, 0x2f9168
	calr	0xfc74
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

	pushw iz                                ; push IZ
	lds	iz, 0
	lds	wa, 1
	call HDAE5000_Display_Callback
	cp	hl, 0xffff
	jr nz, .LDS_47b5                       ; [6e 02] jr NZ,0x2947b5
	lds	iz, 1
.LDS_47b5:
	lda_24 xwa, 0x2f916a
	calr	0xfc57
	lda_24 xwa, 0x2f9186
	calr	0xfc4f
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

	pushw iz                                ; push IZ
	lds	iz, 0
	lds	wa, 1
	call HDAE5000_Display_Callback
	cp	hl, 0xffff
	jr nz, .LDS_47da                       ; [6e 02] jr NZ,0x2947da
	lds	iz, 1
.LDS_47da:
	lda_24 xwa, 0x2f9188
	calr	0xfc32
	lda_24 xwa, 0x2f91ac
	calr	0xfc2a
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

	pushw iz                                ; push IZ
	lds	iz, 0
	lds	wa, 1
	call HDAE5000_Display_Callback
	cp	hl, 0xffff
	jr nz, .LDS_47ff                       ; [6e 02] jr NZ,0x2947ff
	lds	iz, 1
.LDS_47ff:
	lda_24 xwa, 0x2f91ae
	calr	0xfc0d
	lda_24 xwa, 0x2f91ca
	calr	0xfc05
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

	lda	xsp, (xsp-128)
	push xiz
	st_dri3w bc, 0xFD, 0x82, 0x00	; ld (XSP+0x0082),BC
	ld	iz, wa
	ld	qiz, 1
	sti16_24	0x238F2E, 0
	pushw 0x0010
	pushw 0x0020
	lda_24 xwa, 0x238f4a
	push xwa
	call HDAE5000_MemFill
	pushw 0x001a
	pushw 0x0020
	lda_24 xwa, 0x238f30
	push xwa
	call HDAE5000_MemFill
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+68)
	ld	xbc, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0080)
	lds	wa, 0
	call	(xhl)
	ld xwa, (xsp + 0x44)                    ; ld XWA,(XSP+0x44)
	ld	(0x238f74), xwa
	ld xwa, (xsp + 0x48)                    ; ld XWA,(XSP+0x48)
	ld	(0x238f78), xwa
	sti8_24	0x238F7C, 0
	lda	xwa, (xsp+68)
	ld	xbc, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0080)
	lds	wa, 1
	call	(xhl)
	ld xwa, (xsp + 0x44)                    ; ld XWA,(XSP+0x44)
	ld	(0x238f7d), xwa
	ld xwa, (xsp + 0x48)                    ; ld XWA,(XSP+0x48)
	ld	(0x238f81), xwa
	sti8_24	0x238F85, 0
	lda	xwa, (xsp+68)
	ld	xbc, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0080)
	lds	wa, 2
	call	(xhl)
	ld xwa, (xsp + 0x44)                    ; ld XWA,(XSP+0x44)
	ld	(0x238f86), xwa
	ld xwa, (xsp + 0x48)                    ; ld XWA,(XSP+0x48)
	ld	(0x238f8a), xwa
	sti8_24	0x238F8E, 0
	lda	xwa, (xsp+68)
	ld	xbc, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0080)
	lds	wa, 3
	call	(xhl)
	ld xwa, (xsp + 0x44)                    ; ld XWA,(XSP+0x44)
	ld	(0x238f8f), xwa
	ld xwa, (xsp + 0x48)                    ; ld XWA,(XSP+0x48)
	ld	(0x238f93), xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld xix, (xwa + 0x34)                    ; ld XIX,(XWA+0x34)
	call	(xix)
	addm32_24	0x238F93, xhl
	sti8_24	0x238F97, 0
	lda	xwa, (xsp+68)
	ld	xbc, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0080)
	lds	wa, 5
	call	(xhl)
	ld xwa, (xsp + 0x44)                    ; ld XWA,(XSP+0x44)
	ld	(0x238f98), xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld xix, (xwa + 0x44)                    ; ld XIX,(XWA+0x44)
	call	(xix)
	ld	(0x238f9c), xhl
	sti8_24	0x238FA0, 0
	lda	xwa, (xsp+68)
	ld	xbc, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0080)
	lds	wa, 6
	call	(xhl)
	ld xwa, (xsp + 0x44)                    ; ld XWA,(XSP+0x44)
	ld	(0x238fa1), xwa
	ld	xwa, 0x000072aa
	ld	(0x238fa5), xwa
	sti8_24	0x238FA9, 0
	lda	xwa, (xsp+68)
	ld	xbc, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0080)
	lds	wa, 7
	call	(xhl)
	ld xwa, (xsp + 0x44)                    ; ld XWA,(XSP+0x44)
	ld	(0x238faa), xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld xix, (xwa + 0x64)                    ; ld XIX,(XWA+0x64)
	call	(xix)
	ld	(0x238fae), xhl
	sti8_24	0x238FB2, 0
	lda	xwa, (xsp+68)
	ld	xbc, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0080)
	ldw	wa, 0x0008
	call	(xhl)
	ld xwa, (xsp + 0x44)                    ; ld XWA,(XSP+0x44)
	ld	(0x238fb3), xwa
	ld	xwa, 0x000ad000
	ld	(0x238fb7), xwa
	sti8_24	0x238FBB, 0
	lda	xwa, (xsp+68)
	ld	xbc, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0080)
	ldw	wa, 0x0009
	call	(xhl)
	ld xwa, (xsp + 0x44)                    ; ld XWA,(XSP+0x44)
	ld	(0x238fbc), xwa
	ld xwa, (xsp + 0x48)                    ; ld XWA,(XSP+0x48)
	ld	(0x238fc0), xwa
	sti8_24	0x238FC4, 0
	lda	xwa, (xsp+68)
	ld	xbc, xwa
	ldw	wa, 0x000a
	call HDAE5000_Table_Sub_291BDE
	ld xwa, (xsp + 0x44)                    ; ld XWA,(XSP+0x44)
	ld	(0x238fed), xwa
	ld xwa, (xsp + 0x48)                    ; ld XWA,(XSP+0x48)
	ld	(0x238ff1), xwa
	sti8_24	0x238FF5, 0
	lda	xwa, (xsp+76)
	ld	xde, xwa
	ld	wa, iz
	ld_sriw	bc, (xsp + 0x0082)
	call 0x2941ac
	cp	hl, 0xffff
	jr z, .LDS_4acd                        ; [66 7a] jr Z,0x294acd
	ld	wa, (xsp+76)
	ld	(0x238f2e), wa
	pushw 0x0010
	lda	xwa, (xsp+80)
	push xwa
	lda_24 xwa, 0x238f4a
	push xwa
	call HDAE5000_MemCopy
	pushw 0x001a
	lda	xwa, (xsp+106)
	push xwa
	lda_24 xwa, 0x238f30
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+20)
	ld	a, (xsp+120)
	st8_24	0x238F7C, a
	ld	a, (xsp+121)
	st8_24	0x238F8E, a
	ld	a, (xsp+122)
	st8_24	0x238F97, a
	ld	a, (xsp+123)
	st8_24	0x238FA0, a
	ld	a, (xsp+124)
	st8_24	0x238FA9, a
	ld	a, (xsp+125)
	st8_24	0x238FB2, a
	ld	a, (xsp+126)
	st8_24	0x238FBB, a
	ld	a, (xsp+127)
	st8_24	0x238FC4, a
	ld_srib	a, (xsp + 0x0080)
	st8_24	0x238FF5, a
	ld	qiz, 0
.LDS_4acd:
	lda_24 xwa, 0x2f91cc
	calr	0xf93f
	lda_24 xwa, 0x238f4a
	push xwa
	pushw 0x002f
	pushw 0x91ea
	lda	xwa, (xsp+12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	lda	xwa, (xsp+4)
	calr	0xf922
	lda_24 xwa, 0x238f30
	push xwa
	pushw 0x002f
	pushw 0x91f8
	lda	xwa, (xsp+12)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	lda	xwa, (xsp+4)
	calr	0xf905
	lda_24 xwa, 0x2f9206
	calr	0xf8fd
	ld	hl, qiz
	pop xiz                                 ; pop XIZ
	st_dri3b l, 0xFD, 0x80, 0x00	; lda XSP,XSP+0x0080
	ret

	pushw iz                                ; push IZ
	lds	iz, 0
	pushw 0x0000
	pushw 0x0001
	ld16_24	de, 0x238F2E
	call 0x2905e9
	cp	hl, 0xffff
	jr nz, .LDS_4b3b                       ; [6e 02] jr NZ,0x294b3b
	lds	iz, 1
.LDS_4b3b:
	lda_24 xwa, 0x2f9208
	calr	0xf8d1
	lda_24 xwa, 0x2f922a
	calr	0xf8c9
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

	pushw iz                                ; push IZ
	lds	iz, 0
	lda_24 xde, 0x238f30
	pushdi_24	0x238F2E
	pushw 0x0000
	pushw 0x0001
	call 0x291140
	cp	hl, 0xffff
	jr nz, .LDS_4b6e                       ; [6e 02] jr NZ,0x294b6e
	lds	iz, 1
.LDS_4b6e:
	lda_24 xwa, 0x2f922c
	calr	0xf89e
	lda_24 xwa, 0x2f924c
	calr	0xf896
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

	ld16_24	wa, 0x238F2E
	bit	0x00, wa
	jr z, .LDS_4b9d                        ; [66 11] jr Z,0x294b9d
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 0x10)                    ; ld XHL,(XWA+0x10)
	lds	wa, 0
	call	(xhl)
.LDS_4b9d:
	ld16_24	wa, 0x238F2E
	bit	0x01, wa
	jr z, .LDS_4bb8                        ; [66 11] jr Z,0x294bb8
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 0x20)                    ; ld XHL,(XWA+0x20)
	lds	wa, 0
	call	(xhl)
.LDS_4bb8:
	ld16_24	wa, 0x238F2E
	bit	0x02, wa
	jr z, .LDS_4bee                        ; [66 2c] jr Z,0x294bee
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 0x30)                    ; ld XHL,(XWA+0x30)
	lds	wa, 0
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x11fa)
	ld xhl, (xwa + 0x18)                    ; ld XHL,(XWA+0x18)
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00013
	lds32	xde, 0
	call	(xhl)
.LDS_4bee:
	ld16_24	wa, 0x238F2E
	bit	0x03, wa
	jr z, .LDS_4c09                        ; [66 11] jr Z,0x294c09
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 0x40)                    ; ld XHL,(XWA+0x40)
	lds	wa, 0
	call	(xhl)
.LDS_4c09:
	ld16_24	wa, 0x238F2E
	bit	0x04, wa
	jr z, .LDS_4c24                        ; [66 11] jr Z,0x294c24
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 0x50)                    ; ld XHL,(XWA+0x50)
	lds	wa, 0
	call	(xhl)
.LDS_4c24:
	ld16_24	wa, 0x238F2E
	bit	0x05, wa
	jr z, .LDS_4c3f                        ; [66 11] jr Z,0x294c3f
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 0x60)                    ; ld XHL,(XWA+0x60)
	lds	wa, 0
	call	(xhl)
.LDS_4c3f:
	ld16_24	wa, 0x238F2E
	bit	0x07, wa
	jr z, .LDS_4c5a                        ; [66 11] jr Z,0x294c5a
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 0x70)                    ; ld XHL,(XWA+0x70)
	lds	wa, 0
	call	(xhl)
.LDS_4c5a:
	lda_24 xwa, 0x2f924e
	calr	0xf7b2
	lda_24 xwa, 0x2f926e
	jrl	t, 0xf7aa
	pushw iz                                ; push IZ
	lds	iz, 0
	lds	wa, 0
	call HDAE5000_Display_Init
	cps	hl, 0
	jr z, .LDS_4c79                        ; [66 02] jr Z,0x294c79
	lds	iz, 1
.LDS_4c79:
	lda_24 xwa, 0x2f9270
	calr	0xf793
	lda_24 xwa, 0x2f9284
	calr	0xf78b
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0124)
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00014
	ld	xde, 0x01800001
	jp	(xhl)
	lda	xsp, (xsp-64)
	lda_24 xwa, 0x2f9286
	calr	0xf75c
	lds32	xwa, 0
	ld8_24	a, 0x238FF8
	push xwa
	pushw 0x002f
	pushw 0x92ae
	lda	xwa, (xsp+8)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+12)
	lda_24 xwa, 0x2f92be
	calr	0xf73b
	lda_24 xhl, 0x238ff8
	lda	xsp, (xsp+64)
	ret

	ld16_24	wa, 0x238F2E
	bit	0x00, wa
	jr z, .LDS_4cfb                        ; [66 0f] jr Z,0x294cfb
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 0x0c)                    ; ld XHL,(XWA+0x0c)
	call	(xhl)
.LDS_4cfb:
	ld16_24	wa, 0x238F2E
	bit	0x01, wa
	jr z, .LDS_4d14                        ; [66 0f] jr Z,0x294d14
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 0x1c)                    ; ld XHL,(XWA+0x1c)
	call	(xhl)
.LDS_4d14:
	ld16_24	wa, 0x238F2E
	bit	0x02, wa
	jr z, .LDS_4d2d                        ; [66 0f] jr Z,0x294d2d
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 0x2c)                    ; ld XHL,(XWA+0x2c)
	call	(xhl)
.LDS_4d2d:
	ld16_24	wa, 0x238F2E
	bit	0x03, wa
	jr z, .LDS_4d46                        ; [66 0f] jr Z,0x294d46
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 0x3c)                    ; ld XHL,(XWA+0x3c)
	call	(xhl)
.LDS_4d46:
	ld16_24	wa, 0x238F2E
	bit	0x04, wa
	jr z, .LDS_4d5f                        ; [66 0f] jr Z,0x294d5f
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 0x4c)                    ; ld XHL,(XWA+0x4c)
	call	(xhl)
.LDS_4d5f:
	ld16_24	wa, 0x238F2E
	bit	0x05, wa
	jr z, .LDS_4d78                        ; [66 0f] jr Z,0x294d78
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 0x5c)                    ; ld XHL,(XWA+0x5c)
	call	(xhl)
.LDS_4d78:
	ld16_24	wa, 0x238F2E
	bit	0x07, wa
	jr z, .LDS_4d91                        ; [66 0f] jr Z,0x294d91
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld xhl, (xwa + 0x6c)                    ; ld XHL,(XWA+0x6c)
	call	(xhl)
.LDS_4d91:
	lda_24 xwa, 0x2f92c0
	calr	0xf67b
	lda_24 xwa, 0x2f92e0
	jrl	t, 0xf673
	lda	xsp, (xsp-28)
	push xiz
	ld (xsp + 0x1c), bc
	ld (xsp + 0x1e), wa                     ; ld (XSP+0x1e),WA
	ldw (xsp + 0x04), 1
	lda_24 xwa, 0x2f92e2
	calr	0xf65c
	ld16_24	wa, 0x238F2E
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
	ld	xbc, 0x00201632
	add	xbc, xhl
	ld	a, (xsp+6)
	extz wa                                 ; extz WA
	sla	wa, 0x02
	add	wa, 0x0024
	exts xwa                                ; exts XWA
	add	xwa, xbc
	call HDAE5000_Display_Sub_294273
	cp	hl, 0xffff
	jr z, .LDS_4e94                        ; [66 7f] jr Z,0x294e94
	pushw 0x001a
	lda_24 xwa, 0x238f30
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
	ld	xwa, 0x00201632
	add	xwa, xhl
	push xwa
	call HDAE5000_MemCopy_Reverse
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
	ld	xbc, 0x00201632
	add	xbc, xhl
	ld	a, (xsp+6)
	extz wa                                 ; extz WA
	add	wa, 0x001a
	stib_dri 0x07, 0xE4, 0xE0, 0x01	; ld (XBC+WA),0x01
	ldw (xsp + 0x04), 0
.LDS_4e94:
	ld	a, (xsp+6)
	extz wa                                 ; extz WA
	pushw wa                                ; push WA
	pushw 0x002f
	pushw 0x92fa
	lda	xwa, (xsp+14)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda	xsp, (xsp+10)
	lda	xwa, (xsp+8)
	calr	0xf563
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

	pushw iz                                ; push IZ
	lds	iz, 1
	call HDAE5000_Display_Sub_29429E
	cp	hl, 0xffff
	jr z, .LDS_4ee3                        ; [66 0e] jr Z,0x294ee3
	lds	wa, 1
	call HDAE5000_Display_Callback
	cp	hl, 0xffff
	jr z, .LDS_4ee3                        ; [66 02] jr Z,0x294ee3
	lds	iz, 0
.LDS_4ee3:
	lda_24 xwa, 0x2f9306
	calr	0xf529
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

	pushw iz                                ; push IZ
	lds	iz, 1
	call HDAE5000_Display_Sub_294301
	cp	hl, 0xffff
	jr z, .LDS_4efe                        ; [66 02] jr Z,0x294efe
	lds	iz, 0
.LDS_4efe:
	lda_24 xwa, 0x2f931e
	calr	0xf50e
	ld	hl, iz
	popw iz                                 ; pop IZ
	ret

	dec 0, xsp                              ; dec 0,XSP
	push	qiz
	ld (xsp + 0x06), bc
	ld (xsp + 0x08), wa                     ; ld (XSP+0x08),WA
	ldw (xsp + 0x04), 1
	lda_24 xwa, 0x2f9336
	calr	0xf4f2
	ld16_24	wa, 0x238F2E
	ldi_berp 0xfb, 0		; ld QIZH,0
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
	ld	xbc, 0x00201632
	add	xbc, xhl
	ldto_berp a, 0xfb		; ld A,QIZH
	extz wa                                 ; extz WA
	sla	wa, 0x02
	add	wa, 0x0024
	exts xwa                                ; exts XWA
	add	xwa, xbc
	ld	(0x238ffc), xwa
	sti8_24	0x23A1A6, 1
	ldw (xsp + 0x04), 0
	jr t, .LDS_4f92                        ; [68 0c] jr T,0x294f92
.LDS_4f86:
	srl	wa, 0x01
	inc_berp 0xfb, 1		; inc 1,QIZH
	cp_erpb 0xfb, 0x09		; cp QIZH,0x09
	jr c, .LDS_4f30                        ; [67 9e] jr C,0x294f30
.LDS_4f92:
	ld	hl, (xsp+4)
	pop	qiz
	inc 0, xsp                              ; inc 0,XSP
	ret

	dec	6, xsp
	push xiz
	ld (xsp + 0x06), xbc                    ; ld (XSP+0x06),XBC
	ld	xiz, xwa
	ldw (xsp + 0x04), 1
	lda_24 xwa, 0x2f934c
	calr	0xf464
	cpi8_24	0x23A1A6, 1
	jr nz, .LDS_4fd9                       ; [6e 21] jr NZ,0x294fd9
	sti8_24	0x23A1A6, 2
	ld	xwa, xiz
	ld xbc, (xsp + 0x06)                    ; ld XBC,(XSP+0x06)
	ld	xde, (0x238ffc)
	call 0x29811c
	cp	hl, 0xffff
	jr z, .LDS_5002                        ; [66 30] jr Z,0x295002
	ldw (xsp + 0x04), 0
	jr t, .LDS_5002                        ; [68 29] jr T,0x295002
.LDS_4fd9:
	cpi8_24	0x23A1A6, 2
	jr nz, .LDS_4ffc                       ; [6e 1b] jr NZ,0x294ffc
	ld	xwa, xiz
	ld xbc, (xsp + 0x06)                    ; ld XBC,(XSP+0x06)
	ld	xde, (0x238ffc)
	call 0x2981c0
	cp	hl, 0xffff
	jr z, .LDS_5002                        ; [66 0d] jr Z,0x295002
	ldw (xsp + 0x04), 0
	jr t, .LDS_5002                        ; [68 06] jr T,0x295002
.LDS_4ffc:
	sti8_24	0x23A1A6, 0
.LDS_5002:
	ld	hl, (xsp+4)
	pop xiz                                 ; pop XIZ
	inc	6, xsp
	ret


HDAE5000_PPORT_Util:	; 0x295009
	; PPORT utility - push params and call workspace handler
	pushw 0x0000			; arg 1
	pushw 0x0001			; arg 2
	ld16_24 xde, 0x238f2e                 ; DE = (0x238F2E) - callback ID
	call HDAE5000_Workspace_Sub_29336B
	lds hl, 0			; return 0
	ret
	nop

HDAE5000_PPORT_Handler:	; 0x29501C
	; PPORT state machine entry - check active, load params, dispatch
	cpi8_24 0x239000, 0x01                 ; check if PPORT active (0x239000)
	jr nz, .Lpph_done
	ld16_24 xwa, 0x23900a                 ; WA = cmd param (0x23900A)
	nop
	ld32_24 xbc, 0x23900c                 ; XBC = data ptr (0x23900C)
	nop
	ld32_24 xde, 0x239010                 ; XDE = size (0x239010)
	nop
	call HDAE5000_PPORT_Setup
	call HDAE5000_PPORT_Dispatch
.Lpph_done:
	ret
	nop
	; --- Secondary entry: menu init ---
	call HDAE5000_PPORT_Menu
	jr t, HDAE5000_PPORT_Init

HDAE5000_PPORT_Status:	; 0x295046
	; Switch to PPORT stack context for status check
	ei 0x06				; disable interrupts (level 6)
	st32_24 0x239006, xsp                 ; save current SP (0x239006)
	nop
	ld32_24 xsp, 0x239002                 ; load PPORT SP (0x239002)
	nop
	ei 0x00				; re-enable interrupts
	ret
	nop

HDAE5000_PPORT_Init:	; 0x295058 (116 bytes, 3 entry points)
	; Entry 1: Stack context switch (save/restore SP for PPORT workspace)
	ei 0x06				; disable interrupts
	st32_24 0x239002, xsp                 ; save current SP to (0x239002)
	nop
	ld32_24 xsp, 0x239006                 ; load PPORT SP from (0x239006)
	nop
	ei 0x00				; re-enable interrupts
	ret
	nop
HDAE5000_PPORT_Init_Main:	; 0x29506A
	; Entry 2: Initialize PPORT state machine
	push xhl
	nop
	push xwa
	nop
	cpi8_24 0x239000, 0x01                 ; cp (0x239000), 1 — already initialized?
	jr z, .Lpi_exit		; if already init, just return
	sti8_24 0x239014, 0x00                 ; clear abort flag (0x239014)
	sti8_24 0x239000, 0x01                 ; set state = initialized (0x239000)
	ld xhl, 0x0023FFFC	; stack top for PPORT workspace
	nop
	st32_24 0x239002, xhl                 ; store as PPORT SP (0x239002)
	nop
	ld xwa, 0x00295040	; PPORT entry callback address
	nop
	ld (xhl), xwa		; store callback at stack top
	ldb a, 0x00		; param = 0
	call HDAE5000_PPORT_Status	; switch to PPORT stack and call
	cpi8_24 0x239014, 0x00                 ; check abort flag (0x239014)
	jr nz, .Lpi_exit	; if aborted, exit
	ldw hl, 0xFFFF		; HL = -1 (error/timeout)
	nop
	st16_24 0x23900a, xhl                 ; store result (0x23900A)
	nop
	sti8_24 0x239000, 0x00                 ; clear state = uninitialized
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
	st16_24 0x23900a, xhl                 ; store result (0x23900A)
	nop
	sti8_24 0x239000, 0x00                 ; clear state = uninitialized
	ret
	nop

HDAE5000_PPORT_Dispatch:	; 0x2950CC
	; Command dispatcher - switch to PPORT context, check for command
	push xhl
	nop
	call HDAE5000_PPORT_Status	; switch stacks
	cpi8_24 0x239014, 0x00                 ; check command flag (0x239014)
	jr nz, .Lppd_done
	ldw hl, 0xFFFF			; no command: mark result = -1
	nop
	st16_24 0x23900a, xhl                 ; store result (0x23900A)
	nop
	sti8_24 0x239000, 0x00                 ; clear PPORT active flag (0x239000)
.Lppd_done:
	pop xhl
	nop
	ret
	nop
	; --- Secondary entry: get result ---
	ld16_24 xhl, 0x23900a                 ; HL = command result (0x23900A)
	nop
	exts xhl			; sign-extend to 32-bit
	ret
	nop

HDAE5000_Display_String:	; 0x2950F8
	; Display string on screen via PPORT protocol
	; Input: WA = position, XBC = string ptr, XDE = format params
	st16_24 0x23900a, xwa                 ; store position (0x23900A)
	nop
	st32_24 0x23900c, xbc                 ; store string ptr (0x23900C)
	nop
	st32_24 0x239010, xde                 ; store format (0x239010)
	nop
	sti8_24 0x239014, 0x01                 ; set command flag (0x239014)
	call HDAE5000_PPORT_Init	; initialize PPORT transfer
	sti8_24 0x239014, 0x00                 ; clear command flag
	ret
	nop

HDAE5000_PPORT_Setup:	; 0x29511C (442 bytes)
	; PPORT command dispatcher — WA = command ID (1-30)
	cps wa, 0
	jr le, .Lpps_error		; WA <= 0 → error
	cp wa, 0x001E
	jr gt, .Lpps_error		; WA > 30 → error
	push xhl
	nop
	ld hl, wa			; HL = command number
	sla xhl, 2			; XHL *= 4 (table offset)
	nop
	extz xhl			; zero-extend
	ld xix, 0x00295146		; table base
	nop
	ld_sril3 xhl, 0x07, 0xF0, 0xEC	; XHL = (XIX + HL) — load handler addr
	nop
	call (xhl)			; call handler
	pop xhl
	nop
	ret
	nop
.Lpps_error:
	lds wa, 1			; return 1 (error)
	ret
	nop
.Lpps_jump_table:
	; 31-entry jump table (entry 0 unused, entries 1-30 = commands)
	.long 0x002951C2		; entry 0 (unused)
	.long 0x002951C4		; entry 1
	.long 0x002951CC		; entry 2
	.long 0x002951D4		; entry 3
	.long 0x002951DC		; entry 4
	.long 0x002951E2		; entry 5
	.long 0x002951E8		; entry 6
	.long 0x002951EE		; entry 7
	.long 0x002951F6		; entry 8
	.long 0x002951FE		; entry 9
	.long 0x00295206		; entry 10
	.long 0x0029520E		; entry 11
	.long 0x00295216		; entry 12
	.long 0x0029521E		; entry 13
	.long 0x0029522A		; entry 14
	.long 0x00295236		; entry 15
	.long 0x00295242		; entry 16
	.long 0x00295248		; entry 17
	.long 0x00295250		; entry 18
	.long 0x00295256		; entry 19
	.long 0x0029525E		; entry 20
	.long 0x00295264		; entry 21
	.long 0x00295270		; entry 22
	.long 0x00295278		; entry 23
	.long 0x00295284		; entry 24
	.long 0x00295290		; entry 25
	.long 0x0029529C		; entry 26
	.long 0x002952A6		; entry 27
	.long 0x002952B2		; entry 28
	.long 0x002952BE		; entry 29
	.long 0x002952CA		; entry 30
	; --- Handler stubs (commands 0-30) ---
.Lpps_handler_0:			; 0x2951C2
	ret
	nop
.Lpps_handler_1:			; 0x2951C4
	call 0x294416
	ld xix, xhl
	ret
	nop
.Lpps_handler_2:			; 0x2951CC
	call 0x29444E
	ld wa, hl
	ret
	nop
.Lpps_handler_3:			; 0x2951D4
	call 0x294471
	ld wa, hl
	ret
	nop
.Lpps_handler_4:			; 0x2951DC
	call 0x29456E
	ret
	nop
.Lpps_handler_5:			; 0x2951E2
	call 0x2945FA
	ret
	nop
.Lpps_handler_6:			; 0x2951E8
	call 0x294686
	ret
	nop
.Lpps_handler_7:			; 0x2951EE
	call 0x294735
	ld wa, hl
	ret
	nop
.Lpps_handler_8:			; 0x2951F6
	call 0x29475A
	ld wa, hl
	ret
	nop
.Lpps_handler_9:			; 0x2951FE
	call 0x29477F
	ld wa, hl
	ret
	nop
.Lpps_handler_10:			; 0x295206
	call 0x2947A4
	ld wa, hl
	ret
	nop
.Lpps_handler_11:			; 0x29520E
	call 0x2947C9
	ld wa, hl
	ret
	nop
.Lpps_handler_12:			; 0x295216
	call 0x2947EE
	ld wa, hl
	ret
	nop
.Lpps_handler_13:			; 0x29521E
	ld wa, bc			; shuffle args
	ld bc, de
	call 0x294813
	ld wa, hl
	ret
	nop
.Lpps_handler_14:			; 0x29522A
	ld wa, bc
	ld bc, de
	call 0x294B21
	ld wa, hl
	ret
	nop
.Lpps_handler_15:			; 0x295236
	ld wa, bc
	ld bc, de
	call 0x294B4F
	ld wa, hl
	ret
	nop
.Lpps_handler_16:			; 0x295242
	call 0x294B82
	ret
	nop
.Lpps_handler_17:			; 0x295248
	call 0x294C6A
	ld wa, hl
	ret
	nop
.Lpps_handler_18:			; 0x295250
	call 0x294C8D
	ret
	nop
.Lpps_handler_19:			; 0x295256
	call 0x294CAD
	ld xix, xhl
	ret
	nop
.Lpps_handler_20:			; 0x29525E
	call 0x294CE2
	ret
	nop
.Lpps_handler_21:			; 0x295264
	ld wa, bc
	ld bc, de
	call 0x294DA1
	ld wa, hl
	ret
	nop
.Lpps_handler_22:			; 0x295270
	call 0x294EC8
	ld wa, hl
	ret
	nop
.Lpps_handler_23:			; 0x295278
	ld xwa, xbc			; 32-bit arg shuffle
	ld xbc, xde
	call 0x294EEF
	ld wa, hl
	ret
	nop
.Lpps_handler_24:			; 0x295284
	ld wa, bc
	ld bc, de
	call 0x294F0A
	ld wa, hl
	ret
	nop
.Lpps_handler_25:			; 0x295290
	ld xwa, xbc
	ld xbc, xde
	call 0x294F9B
	ld wa, hl
	ret
	nop
.Lpps_handler_26:			; 0x29529C
	ld xwa, xbc
	call 0x284D7F
	lds wa, 0
	ret
	nop
.Lpps_handler_27:			; 0x2952A6
	ld wa, bc
	ld bc, de
	call HDAE5000_PPORT_Util
	ld wa, hl
	ret
	nop
.Lpps_handler_28:			; 0x2952B2
	ld xwa, xbc
	ld xbc, xde
	call HDAE5000_Dir_Format_Setup
	ld wa, hl
	ret
	nop
.Lpps_handler_29:			; 0x2952BE
	ld xwa, xbc
	ld xbc, xde
	call HDAE5000_Dir_Flush
	ld wa, hl
	ret
	nop
.Lpps_handler_30:			; 0x2952CA
	ld xwa, xbc
	ld xbc, xde
	call HDAE5000_Dir_Close
	ld wa, hl
	ret
	nop

HDAE5000_PPORT_Menu:	; 0x2952D6
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
	and a, 0x7F			; mask high bit
	nop
	cps a, 0
	jr nz, .Lppe_cmd1
	jp .Lppe_read_exec		; cmd 0 → read/execute
.Lppe_cmd1:
	cps a, 1
	jr nz, .Lppe_cmd2
	jp .Lppe_read_exec		; cmd 1 → read/execute
.Lppe_cmd2:
	cps a, 2
	jr nz, .Lppe_cmd3
	jp .Lppe_simple_ret		; cmd 2 → simple ret
.Lppe_cmd3:
	cps a, 3
	jr nz, .Lppe_cmd4
	jp .Lppe_simple_ret		; cmd 3 → simple ret
.Lppe_cmd4:
	cps a, 4
	jr nz, .Lppe_cmd5
	jp .Lppe_simple_ret		; cmd 4 → simple ret
.Lppe_cmd5:
	cps a, 5
	jr nz, .Lppe_cmd6
	jp .Lppe_simple_ret		; cmd 5 → simple ret
.Lppe_cmd6:
	cps a, 6
	jr nz, .Lppe_cmd7
	jp .Lppe_simple_ret		; cmd 6 → simple ret
.Lppe_cmd7:
	cps a, 7
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
.Lppe_write_setup:
	; Write I/O registers and clear flag
	ldb a, 0x89
	st8_24 0x160006, a                    ; (0x160006) = 0x89
	nop
	ldb a, 0x28
	st8_24 0x160002, a                    ; (0x160002) = 0x28
	nop
	sti8_24 0x2390d4, 0x00                 ; (0x2390D4) = 0
	ret
	nop
.Lppe_read_exec:
	; Read/execute with polling loop
	ei 0x07				; enable interrupts
	ldb a, 0x89
	st8_24 0x160006, a                    ; (0x160006) = 0x89
	nop
.Lppe_poll:
	lds wa, 0			; WA = 0
	call HDAE5000_Display_String	; 0x2950F8
	ld8_24 a, 0x160004                    ; read (0x160004)
	nop
	and a, 0x04			; test bit 2
	nop
	cps a, 4			; bit 2 set?
	jr nz, .Lppe_poll		; keep polling if not
	ldb a, 0x18
	st8_24 0x160002, a                    ; (0x160002) = 0x18
	nop
	sti8_24 0x2390d4, 0x00                 ; (0x2390D4) = 0
	call 0x296814
	cpi8_24 0x2390d4, 0x01                 ; (0x2390D4) == 1?
	jp_24 z, 2708340		; if Z, go back to polling (0x295374)
	nop
	lda_24 xix, 0x239168                  ; XIX = 0x239168
	nop
	xor xwa, xwa			; XWA = 0
	ld a, (xix)			; A = command index
	cp xwa, 0x00000014		; compare with 20
	jp_24 ugt, 2708340		; if UGT 20, invalid → repoll (0x295374)
	nop
	dec 1, xwa			; XWA = index - 1
	sll xwa, 2			; XWA *= 4 (table entry size)
	nop
	lda_24 xix, 0x2953ce                  ; XIX = jump table base (0x2953CE)
	nop
	add xix, xwa			; XIX += offset
	ld xiy, (xix)			; XIY = handler address
	jp (xiy)			; jump to handler
.Lppe_jump_table:
	; 5-entry jump table (4 bytes each)
	.long 0x00295642		; entry 0
	.long 0x002956CC		; entry 1
	.long 0x002956F2		; entry 2
	.long 0x0029572E		; entry 3
	.long 0x00295802		; entry 4

; ============================================================================
; PPORT COMMAND HANDLER JUMP TABLE (0x2953E2 - 0x295411)
; 12 entries × 4 bytes = 48 bytes
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
	.long HDAE5000_Cmd01_SendInfo
	.long HDAE5000_Cmd02_Exit
	.long HDAE5000_Cmd03_ReadFSB
	.long HDAE5000_Cmd04_SendFSB
	.long HDAE5000_Cmd05_RcvFSB
	.long HDAE5000_Cmd06_WriteFSB
	.long HDAE5000_PPORT_Cmd_LoadHDtoMemory
	.long HDAE5000_PPORT_Cmd_SendDataBlock
	.long HDAE5000_PPORT_Cmd_SendFileList
	.long HDAE5000_PPORT_Cmd_ReceiveDataBlock
	.long HDAE5000_PPORT_Cmd_WriteMemoryToHD
	.long HDAE5000_PPORT_Cmd_Reserved

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
	.long PPORT_Utility_1
	.long PPORT_Utility_2
	.long PPORT_Utility_3

HDAE5000_PPORT_Strings:	; 29541Eh
	; PPORT command menu strings (21 null-terminated strings)
	; Format: "NN>Description" where NN = command number
	.asciz "01>Send Infos About HD"
	.byte 0x00
	.asciz "02>Exit PPORT         "
	.byte 0x00
	.asciz "03>Read FSB from HD   "
	.byte 0x00
	.asciz "04>Sending FSB to PC  "
	.byte 0x00
	.asciz "05>Rcv FSB from PC    "
	.byte 0x00
	.asciz "06>Writing FSB to HD  "
	.byte 0x00
	.asciz "07>Load HD to Memory  "
	.byte 0x00
	.asciz "08>Send data to PC    "
	.byte 0x00
	.asciz "09>Sending files to PC"
	.byte 0x00
	.asciz "10>Rcv data from PC   "
	.byte 0x00
	.asciz "11>Save memory to HD  "
	.byte 0x00
	.asciz "12>nothing            "
	.byte 0x00
	.asciz "13>Rcv data from PC   "
	.byte 0x00
	.asciz "14>Sending infos to PC"
	.byte 0x00
	.asciz "15>nothing            "
	.byte 0x00
	.asciz "16>Delete files       "
	.byte 0x00
	.asciz "17>Formating HD       "
	.byte 0x00
	.asciz "18>Switch HD-motor off"
	.byte 0x00
	.asciz "19>nothing            "
	.byte 0x00
	.asciz "20>Send XapFile flash "
	.byte 0x00
	.ascii "20>End flash right"
	.byte 0x09, 0x20, 0x20, 0x00
	.ascii "20>End flash false"
	.byte 0x09, 0x20, 0x20, 0x00
	.asciz "Error : Wrong Dll Ver "
	.byte 0x00

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

HDAE5000_Code_2_PartB:	; 0x295642 (660 bytes)
	; PPORT command handler: initialize HD — display status, read flag bytes,
	; check compatibility, call utility with params, sum buffer
	ldw wa, 0x001A				; display command
	nop
	lda_24 xbc, 0x29541e                  ; lda XBC, 0x29541E — status string
	nop
	call HDAE5000_Display_String
	lda_24 xix, 0x239168                  ; lda XIX, 0x239168
	nop
	ld a, (xix + 1)			; read flag byte 1
	nop
	st8_24 0x2390f4, a                    ; st (0x2390F4), A
	nop
	ld a, (xix + 2)			; read flag byte 2
	nop
	st8_24 0x2390f6, a                    ; st (0x2390F6), A
	nop
	call HDAE5000_PPORT_Ready_Check
	lds wa, 3				; display command
	di
	call HDAE5000_Display_String
	ei 7
	cps wa, 0				; check result
	jp_24 z, 2709124			; jp Z, 0x295684 — success path
	nop
	jp .Lc2b_do_cleanup
.Lc2b_check_compat:			; 0x295684
	ld8_24 a, 0x23a04a                    ; ld A, (0x23A04A) — compatibility byte
	nop
	cpdm8_24 2330868, a			; cp (0x2390F4), A — match?
	nop
	jp_24 z, 2709164			; jp Z, 0x2956AC — match, skip error
	nop
	ldw wa, 0x001A
	nop
	lda_24 xbc, 0x29562a                  ; lda XBC, 0x29562A — error string
	nop
	call HDAE5000_Display_String
.Lc2b_do_cleanup:			; 0x2956A4
	call HDAE5000_PPORT_Cleanup
	jp .Lc2b_sum_and_done
.Lc2b_compat_ok:			; 0x2956AC
	ldw bc, 0x0097				; BC param
	nop
	ldw hl, 0x00CA				; HL param
	nop
	call 2714308				; call 0x296AC4 — utility
.Lc2b_sum_and_done:			; 0x2956B8
	call HDAE5000_PPORT_Sum_Buffer
	cpi8_24 0x2390d4, 0x01                 ; error check
	jp_24 z, 2708340			; jp Z, abort
	nop
	jp HDAE5000_PPORT_Cmd_Done

.Lc2b_cmd_format:			; 0x2956CC — Format HD command handler
	di
	ldw wa, 0x001A
	nop
	lda_24 xbc, 0x295436                  ; lda XBC, 0x295436 — format string
	nop
	call HDAE5000_Display_String
	lds wa, 1				; display command
	call HDAE5000_Display_String
	xor wa, wa				; WA = 0
	ldb a, 0xFF				; A = 0xFF, so WA = 0x00FF
	ld (xix), wa				; store to PPORT data
	ldw wa, 0x0012				; display command
	nop
	call HDAE5000_Display_String
	ret
	nop

.Lc2b_cmd_read_status:			; 0x2956F2 — Read status command handler
	ldw wa, 0x001A
	nop
	lda_24 xbc, 0x29544e                  ; lda XBC, 0x29544E — status string
	nop
	call HDAE5000_Display_String
	call HDAE5000_PPORT_Ready_Check
	lds wa, 7				; display command
	di
	call HDAE5000_Display_String
	ei 7
	cps wa, 0
	jp_24 z, 2709274			; jp Z, 0x29571A — skip cleanup
	nop
	call HDAE5000_PPORT_Cleanup
.Lc2b_rs_sum:				; 0x29571A
	call HDAE5000_PPORT_Sum_Buffer
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
	jp HDAE5000_PPORT_Cmd_Done

.Lc2b_cmd_read_hd:			; 0x29572E — Read HD sectors command handler
	; Display status, read 3 CHS parameter sets, call read function for each
	ldw wa, 0x001A
	nop
	lda_24 xbc, 0x295466                  ; lda XBC, 0x295466 — status string
	nop
	call HDAE5000_Display_String
	call HDAE5000_PPORT_Ready_Check
	lds wa, 4				; display progress step 1
	di
	call HDAE5000_Display_String
	ei 7
	ldw bc, 0x002C
	nop
	ldw hl, 0x0034
	nop
	call 2714308				; call 0x296AC4
	lds wa, 5				; step 2
	di
	call HDAE5000_Display_String
	ei 7
	ldw bc, 0x0034
	nop
	ldw hl, 0x003C
	nop
	call 2714308
	lds wa, 6				; step 3
	di
	call HDAE5000_Display_String
	ei 7
	ldw bc, 0x003C
	nop
	ldw hl, 0x0046
	nop
	call 2714308
	call HDAE5000_PPORT_Sum_Buffer
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
	; Read 3 CHS regions from PPORT data
	lda_24 xix, 0x239168                  ; lda XIX, 0x239168
	nop
	ld bc, (xix + 0x30)			; sectors low
	nop
	ld de, (xix + 0x32)			; sectors high
	nop
	mul xde, xbc				; XDE = DE × BC (total sectors)
	ld xiy, (xix + 0x2C)			; region start
	nop
	call 2714360				; call 0x296AF8 — read region
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
	lda_24 xix, 0x239168
	nop
	ld bc, (xix + 0x38)
	nop
	ld de, (xix + 0x3A)
	nop
	mul xde, xbc
	ld xiy, (xix + 0x34)
	nop
	call 2714360
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
	lda_24 xix, 0x239168
	nop
	ld bc, (xix + 0x40)
	nop
	ld de, (xix + 0x42)
	nop
	mul xde, xbc
	ld xiy, (xix + 0x3C)
	nop
	call 2714360
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
	jp HDAE5000_PPORT_Cmd_Done

.Lc2b_cmd_write_hd:			; 0x295802 — Write HD sectors command handler
	; Same as read but calls write function (0x296B7E) instead
	ldw wa, 0x001A
	nop
	lda_24 xbc, 0x29547e                  ; lda XBC, 0x29547E — status string
	nop
	call HDAE5000_Display_String
	call HDAE5000_PPORT_Ready_Check
	lds wa, 4
	di
	call HDAE5000_Display_String
	ei 7
	ldw bc, 0x002C
	nop
	ldw hl, 0x0034
	nop
	call 2714308
	lds wa, 5
	di
	call HDAE5000_Display_String
	ei 7
	ldw bc, 0x0034
	nop
	ldw hl, 0x003C
	nop
	call 2714308
	lds wa, 6
	di
	call HDAE5000_Display_String
	ei 7
	ldw bc, 0x003C
	nop
	ldw hl, 0x0046
	nop
	call 2714308
	call HDAE5000_PPORT_Sum_Buffer
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
	; Write 3 CHS regions from PPORT data
	lda_24 xix, 0x239168
	nop
	ld bc, (xix + 0x30)
	nop
	ld de, (xix + 0x32)
	nop
	mul xde, xbc
	ld xiy, (xix + 0x2C)
	nop
	call 2714494				; call 0x296B7E — write region
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
	lda_24 xix, 0x239168
	nop
	ld bc, (xix + 0x38)
	nop
	ld de, (xix + 0x3A)
	nop
	mul xde, xbc
	ld xiy, (xix + 0x34)
	nop
	call 2714494
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
	lda_24 xix, 0x239168
	nop
	ld bc, (xix + 0x40)
	nop
	ld de, (xix + 0x42)
	nop
	mul xde, xbc
	ld xiy, (xix + 0x3C)
	nop
	call 2714494
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
	jp HDAE5000_PPORT_Cmd_Done

HDAE5000_Cmd01_SendInfo:	; 0x2958D6 (62 bytes)
	; Handler: Send HD info - display status, clear buffer, check result
	ldw wa, 0x001A			; display row/column
	nop
	lda_24 xbc, 0x295496                  ; lda XBC, (0x295496) - status string
	nop
	call HDAE5000_Display_String
	call HDAE5000_PPORT_Ready_Check
	ldw wa, 0x000A			; display row/column
	nop
	ei 0x00				; enable interrupts
	call HDAE5000_Display_String
	ei 0x07				; disable interrupts
	cps wa, 0			; check result
	jp_24 z, 0x295900		; jp Z - skip cleanup if zero
	nop
	call HDAE5000_PPORT_Cleanup
	call HDAE5000_PPORT_Sum_Buffer
	cpi8_24 0x2390d4, 0x01                 ; cp (0x2390D4), 1
	jp_24 z, 0x295374		; jp Z - exit to PPORT finish
	nop
	jp HDAE5000_PPORT_Cmd_Done

HDAE5000_Cmd02_Exit:	; 0x295914 (226 bytes)
	; Handler: Exit PPORT — display status, render, read sector/head masks,
	; AND with data bytes, write back, sum buffer, check results
	ldw wa, 0x001A				; display command
	nop
	lda_24 xbc, 0x2954ae                  ; lda XBC, 0x2954AE — status string
	nop
	call HDAE5000_Display_String
	call HDAE5000_Render_Display_Region
	call HDAE5000_Render_Display_Region2
	call 2713602				; call 0x296802 — register XIX
	call HDAE5000_PPORT_Ready_Check
	lds bc, 0				; BC = 0
	ldw hl, 0x00C8				; HL = 200
	nop
	call 2714308				; call 0x296AC4 — utility
	lda_24 xix, 0x239168                  ; lda XIX, 0x239168
	nop
	ld a, (xix)				; read byte 0 from PPORT data
	st8_24 0x2390de, a                    ; st (0x2390DE), A — save sector byte
	nop
	ld8_24 w, 0x2390da                    ; ld W, (0x2390DA) — sector mask
	nop
	and w, a				; W = mask AND data
	st8_24 0x2390e2, w                    ; st (0x2390E2), W — masked sector
	nop
	ld a, (xix + 1)			; read byte 1 from PPORT data
	nop
	st8_24 0x2390e0, a                    ; st (0x2390E0), A — save head byte
	nop
	ld8_24 w, 0x2390dc                    ; ld W, (0x2390DC) — head mask
	nop
	and w, a				; W = mask AND data
	st8_24 0x2390e4, w                    ; st (0x2390E4), W — masked head
	nop
	ld (xix), w				; write masked head to PPORT[0]
	call HDAE5000_PPORT_Sum_Buffer
	cpi8_24 0x2390d4, 0x01                 ; cp (0x2390D4), 1 — error?
	jp_24 z, 2708340			; jp Z, 0x295374 — abort
	nop
	cpi8_24 0x2390e2, 0x00                 ; cp (0x2390E2), 0 — masked sector=0?
	jp_24 z, 2710002			; jp Z, 0x2959F2 — skip to end
	nop
	jp .Lce_continue
.Lce_check_head:			; 0x295992
	cpi8_24 0x2390e4, 0x00                 ; cp (0x2390E4), 0 — masked head=0?
	jp_24 z, 2710002			; jp Z, 0x2959F2 — skip to end
	nop
.Lce_continue:				; 0x29599E
	call HDAE5000_PPORT_Ready_Check
	ld32_24 xix, 0x239100                 ; ld XIX, (0x239100) — data source ptr
	nop
	ld8_24 a, 0x2390e2                    ; ld A, (0x2390E2) — masked sector
	nop
	ld (xix), a				; write sector to buffer[0]
	ld8_24 a, 0x2390e4                    ; ld A, (0x2390E4) — masked head
	nop
	ld (xix + 1), a			; write head to buffer[1]
	nop
	xor xbc, xbc
	xor xde, xde
	ld8_24 c, 0x2390d6                    ; ld C, (0x2390D6)
	nop
	ld8_24 e, 0x2390d8                    ; ld E, (0x2390D8)
	nop
	ldw wa, 0x000E				; display command
	nop
	di
	call HDAE5000_Display_String
	ei 7
	cps wa, 0				; check result
	jp_24 z, 2709986			; jp Z, 0x2959E2 — skip cleanup
	nop
	call HDAE5000_PPORT_Cleanup
.Lce_final_sum:				; 0x2959E2
	call HDAE5000_PPORT_Sum_Buffer
	cpi8_24 0x2390d4, 0x01                 ; cp (0x2390D4), 1 — error?
	jp_24 z, 2708340			; jp Z, 0x295374 — abort
	nop
	jp HDAE5000_PPORT_Cmd_Done

HDAE5000_Cmd03_ReadFSB:	; 0x2959F6 (838 bytes)
	; Handler: Read FSB from HD — display status, render, read sector/head masks,
	; copy 18 region descriptors from PPORT buffer, then read each flagged region
	ldw wa, 0x001A				; display command
	nop
	lda_24 xbc, 0x2954c6                  ; lda XBC, 0x2954C6 — status string
	nop
	call HDAE5000_Display_String
	call HDAE5000_Render_Display_Region
	call HDAE5000_Render_Display_Region2
	call 2713602				; call 0x296802 — register XIX
	call HDAE5000_PPORT_Ready_Check
	lds bc, 0
	ldw hl, 0x002C
	nop
	call 2714308				; call 0x296AC4
	lda_24 xix, 0x239168                  ; lda XIX, 0x239168
	nop
	ld a, (xix)				; sector mask byte
	st8_24 0x2390de, a                    ; st (0x2390DE), A
	nop
	ld8_24 w, 0x2390da                    ; ld W, (0x2390DA)
	nop
	and w, a				; apply mask
	and w, 0xBF				; clear bit 6
	nop
	st8_24 0x2390e2, w                    ; st (0x2390E2), W — masked sector
	nop
	ld a, (xix + 1)			; head mask byte
	nop
	st8_24 0x2390e0, a                    ; st (0x2390E0), A
	nop
	ld8_24 w, 0x2390dc                    ; ld W, (0x2390DC)
	nop
	and w, a
	st8_24 0x2390e4, w                    ; st (0x2390E4), W — masked head
	nop
	ld (xix + 1), w			; write back
	nop
	call HDAE5000_PPORT_Sum_Buffer
	cpi8_24 0x2390d4, 0x01                 ; error check
	jp_24 z, 2708340			; jp Z, abort
	nop
	cpi8_24 0x2390e2, 0x00                 ; masked sector = 0?
	jp_24 z, 2710840			; jp Z, 0x295D38 — skip to end
	nop
	jp .Lrfsb_continue
.Lrfsb_check_head:			; 0x295A7A
	cpi8_24 0x2390e4, 0x00                 ; masked head = 0?
	jp_24 z, 2710840			; jp Z, skip to end
	nop
.Lrfsb_continue:			; 0x295A86
	sti8_24 0x2390e6, 0x00                 ; st (0x2390E6), 0 — clear error flag
	call HDAE5000_PPORT_Ready_Check
	ld32_24 xix, 0x239100                 ; ld XIX, (0x239100) — data ptr
	nop
	ld8_24 a, 0x2390e2                    ; ld A, (0x2390E2)
	nop
	ld (xix), a
	ld8_24 a, 0x2390e4                    ; ld A, (0x2390E4)
	nop
	ld (xix + 1), a
	nop
	xor xbc, xbc
	xor xde, xde
	ld8_24 c, 0x2390d6
	nop
	ld8_24 e, 0x2390d8
	nop
	ldw wa, 0x000E				; display command
	nop
	di
	call HDAE5000_Display_String
	ei 7
	cps wa, 0
	jr z, .Lrfsb_no_error_flag
	sti8_24 0x2390e6, 0x01                 ; set error flag
.Lrfsb_no_error_flag:			; 0x295ACE
	call HDAE5000_Render_Display_Region2
	ld32_24 xix, 0x239100                 ; ld XIX, (0x239100)
	nop
	; Copy 18 region descriptors from PPORT buffer to memory
	; Short displacement (8-bit signed): offsets 0x46-0x7C
	ld xwa, (xix + 0x46)
	nop
	st32_24 0x239108, xwa                 ; st (0x239108)
	nop
	ld xwa, (xix + 0x4A)
	nop
	st32_24 0x23910c, xwa                 ; st (0x23910C)
	nop
	ld xwa, (xix + 0x4F)
	nop
	st32_24 0x239110, xwa                 ; st (0x239110)
	nop
	ld xwa, (xix + 0x53)
	nop
	st32_24 0x239114, xwa                 ; st (0x239114)
	nop
	ld xwa, (xix + 0x58)
	nop
	st32_24 0x239118, xwa                 ; st (0x239118)
	nop
	ld xwa, (xix + 0x5C)
	nop
	st32_24 0x23911c, xwa                 ; st (0x23911C)
	nop
	ld xwa, (xix + 0x61)
	nop
	st32_24 0x239120, xwa                 ; st (0x239120)
	nop
	ld xwa, (xix + 0x65)
	nop
	st32_24 0x239124, xwa                 ; st (0x239124)
	nop
	ld xwa, (xix + 0x6A)
	nop
	st32_24 0x239128, xwa                 ; st (0x239128)
	nop
	ld xwa, (xix + 0x6E)
	nop
	st32_24 0x23912c, xwa                 ; st (0x23912C)
	nop
	ld xwa, (xix + 0x73)
	nop
	st32_24 0x239130, xwa                 ; st (0x239130)
	nop
	ld xwa, (xix + 0x77)
	nop
	st32_24 0x239134, xwa                 ; st (0x239134)
	nop
	ld xwa, (xix + 0x7C)
	nop
	st32_24 0x239138, xwa                 ; st (0x239138)
	nop
	; Extended displacement (16-bit): offsets >= 0x80
	ld_sril	xwa, (xix + 0x0080)
	nop
	st32_24 0x23913c, xwa                 ; st (0x23913C)
	nop
	ld_sril	xwa, (xix + 0x008e)
	nop
	st32_24 0x239144, xwa                 ; st (0x239144)
	nop
	ld_sril	xwa, (xix + 0x0092)
	nop
	st32_24 0x239148, xwa                 ; st (0x239148)
	nop
	ld_sril	xwa, (xix + 0x00bf)
	nop
	st32_24 0x23914c, xwa                 ; st (0x23914C)
	nop
	ld_sril	xwa, (xix + 0x00c3)
	nop
	st32_24 0x239150, xwa                 ; st (0x239150)
	nop
	; Setup for final sum/check
	call HDAE5000_PPORT_Ready_Check
	lds bc, 0
	ldw hl, 0x00C8
	nop
	call 2714308				; call 0x296AC4
	cpi8_24 0x2390e6, 0x00                 ; error flag clear?
	jr z, .Lrfsb_sum
	call HDAE5000_PPORT_Cleanup
.Lrfsb_sum:				; 0x295BB0
	call HDAE5000_PPORT_Sum_Buffer
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340			; jp Z, abort
	nop
	cpi8_24 0x2390e6, 0x01                 ; error flag set?
	jp_24 z, 2710840			; jp Z, exit
	nop
	; Test flag bits and read corresponding regions
	; Bit 0: custom region
	ld8_24 a, 0x2390e2                    ; ld A, (0x2390E2)
	nop
	and a, 0x01
	nop
	cps a, 1
	jp_24 nz, 2710510			; jp NZ, skip
	nop
	call 2714784				; call 0x296CA0 — read custom region
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
.Lrfsb_bit1:				; 0x295BEE — Bit 1
	ld8_24 a, 0x2390e2
	nop
	and a, 0x02
	nop
	cps a, 2
	jp_24 nz, 2710556			; jp NZ, skip
	nop
	ld32_24 xiy, 0x239118                 ; ld XIY, (0x239118)
	nop
	ld32_24 xde, 0x23911c                 ; ld XDE, (0x23911C)
	nop
	call 2714360				; call 0x296AF8 — read region
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
.Lrfsb_bit2:				; 0x295C1C — Bit 2
	ld8_24 a, 0x2390e2
	nop
	and a, 0x04
	nop
	cps a, 4
	jp_24 nz, 2710602
	nop
	ld32_24 xiy, 0x239120                 ; ld XIY, (0x239120)
	nop
	ld32_24 xde, 0x239124                 ; ld XDE, (0x239124)
	nop
	call 2714360
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
.Lrfsb_bit3:				; 0x295C4A — Bit 3
	ld8_24 a, 0x2390e2
	nop
	and a, 0x08
	nop
	cp a, 0x08
	nop
	jp_24 nz, 2710650
	nop
	ld32_24 xiy, 0x239128                 ; ld XIY, (0x239128)
	nop
	ld32_24 xde, 0x23912c                 ; ld XDE, (0x23912C)
	nop
	call 2714360
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
.Lrfsb_bit4:				; 0x295C7A — Bit 4
	ld8_24 a, 0x2390e2
	nop
	and a, 0x10
	nop
	cp a, 0x10
	nop
	jp_24 nz, 2710698
	nop
	ld32_24 xiy, 0x239130                 ; ld XIY, (0x239130)
	nop
	ld32_24 xde, 0x239134                 ; ld XDE, (0x239134)
	nop
	call 2714360
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
.Lrfsb_bit5:				; 0x295CAA — Bit 5
	ld8_24 a, 0x2390e2
	nop
	and a, 0x20
	nop
	cp a, 0x20
	nop
	jp_24 nz, 2710746
	nop
	ld32_24 xiy, 0x239138                 ; ld XIY, (0x239138)
	nop
	ld32_24 xde, 0x23913c                 ; ld XDE, (0x23913C)
	nop
	call 2714360
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
.Lrfsb_bit7:				; 0x295CDA — Bit 7
	ld8_24 a, 0x2390e2
	nop
	and a, 0x80
	nop
	cp a, 0x80
	nop
	jp_24 nz, 2710794
	nop
	ld32_24 xiy, 0x239144                 ; ld XIY, (0x239144)
	nop
	ld32_24 xde, 0x239148                 ; ld XDE, (0x239148)
	nop
	call 2714360
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
.Lrfsb_flag2_bit0:			; 0x295D0A — Head flag bit 0
	ld8_24 a, 0x2390e4                    ; ld A, (0x2390E4) — masked head
	nop
	and a, 0x01
	nop
	cps a, 1
	jp_24 nz, 2710840			; jp NZ, exit
	nop
	ld32_24 xiy, 0x23914c                 ; ld XIY, (0x23914C)
	nop
	ld32_24 xde, 0x239150                 ; ld XDE, (0x239150)
	nop
	call 2714360
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
.Lrfsb_exit:				; 0x295D38
	jp HDAE5000_PPORT_Cmd_Done

HDAE5000_Cmd04_SendFSB:	; 0x295D3C (798 bytes)
	; Handler: Send FSB to PC — display status, read sector/head masks,
	; build transfer buffer (masked bytes + 9 region descriptors),
	; send to PC via PPORT, then conditionally send each region
	; based on flag bits (8 bits from byte 1 + 1 bit from byte 2)
	ldw wa, 0x001A				; display command
	nop
	lda_24 xbc, 0x2954de                  ; lda XBC, 0x2954DE — status string
	nop
	call HDAE5000_Display_String
	call HDAE5000_Render_Display_Region
	call HDAE5000_Render_Display_Region2
	call 2713602				; call 0x296802 — register XIX
	ld32_24 xix, 0x239100                 ; ld XIX, (0x239100) — data source ptr
	nop
	ld a, (xix)				; read byte 0 from data source
	st8_24 0x2390de, a                    ; st (0x2390DE), A — save sector raw
	nop
	ld8_24 w, 0x2390da                    ; ld W, (0x2390DA) — sector mask
	nop
	and w, a				; W = mask AND data
	st8_24 0x2390e2, w                    ; st (0x2390E2), W — masked sector
	nop
	ld a, (xix + 1)			; read byte 1 from data source
	nop
	st8_24 0x2390e0, a                    ; st (0x2390E0), A — save head raw
	nop
	ld8_24 w, 0x2390dc                    ; ld W, (0x2390DC) — head mask
	nop
	and w, a				; W = mask AND data
	st8_24 0x2390e4, w                    ; st (0x2390E4), W — masked head
	nop
	call 2715144				; call 0x296E08
	call HDAE5000_Render_Display_Region2
	call HDAE5000_PPORT_Ready_Check
	lds bc, 0				; BC = 0 (offset)
	ldw hl, 0x002C				; HL = 44 (length)
	nop
	call 2714308				; call 0x296AC4 — utility
	cpi8_24 0x2390e6, 0x00                 ; cp (0x2390E6), 0 — cleanup needed?
	jp_24 z, 2710960			; jp Z, .Lsfsb_build_buffer — skip cleanup
	nop
	call HDAE5000_PPORT_Cleanup
.Lsfsb_build_buffer:			; 0x295DB0 — Build transfer buffer
	lda_24 xix, 0x239168                  ; lda XIX, 0x239168
	nop
	ld8_24 a, 0x2390e2                    ; ld A, (0x2390E2) — masked sector
	nop
	ld (xix), a				; store to buffer[0]
	ld8_24 a, 0x2390e4                    ; ld A, (0x2390E4) — masked head
	nop
	ld (xix + 1), a			; store to buffer[1]
	nop
	add xix, 44				; advance XIX by 0x2C (44 bytes)
	; Copy 9 × 32-bit region descriptors to buffer
	ld32_24 xwa, 0x23910c                 ; ld XWA, (0x23910C) — region 0
	nop
	ld (xix), xwa
	inc 4, xix
	ld32_24 xwa, 0x23911c                 ; ld XWA, (0x23911C) — region 1
	nop
	ld (xix), xwa
	inc 4, xix
	ld32_24 xwa, 0x239124                 ; ld XWA, (0x239124) — region 2
	nop
	ld (xix), xwa
	inc 4, xix
	ld32_24 xwa, 0x23912c                 ; ld XWA, (0x23912C) — region 3
	nop
	ld (xix), xwa
	inc 4, xix
	ld32_24 xwa, 0x239134                 ; ld XWA, (0x239134) — region 4
	nop
	ld (xix), xwa
	inc 4, xix
	ld32_24 xwa, 0x23913c                 ; ld XWA, (0x23913C) — region 5
	nop
	ld (xix), xwa
	inc 4, xix
	ld32_24 xwa, 0x239140                 ; ld XWA, (0x239140) — region 6
	nop
	ld (xix), xwa
	inc 4, xix
	ld32_24 xwa, 0x239148                 ; ld XWA, (0x239148) — region 7
	nop
	ld (xix), xwa
	inc 4, xix
	ld32_24 xwa, 0x239150                 ; ld XWA, (0x239150) — region 8
	nop
	ld (xix), xwa
	; Send buffer via PPORT
	call HDAE5000_PPORT_Sum_Buffer
	cpi8_24 0x2390d4, 0x01                 ; cp (0x2390D4), 1 — error?
	jp_24 z, 2708340			; jp Z, 0x295374 — abort
	nop
	cpi8_24 0x2390e6, 0x01                 ; cp (0x2390E6), 1 — skip bit tests?
	jp_24 z, 2711638			; jp Z, .Lsfsb_exit
	nop
	; Test flag byte 1 bit by bit, send corresponding region data
	; Bit 0 (0x01)
	ld8_24 a, 0x2390e2                    ; ld A, (0x2390E2) — masked sector
	nop
	and a, 0x01
	nop
	cps a, 1
	jp_24 nz, 2711164			; jp NZ, .Lsfsb_bit1
	nop
	ld32_24 xwa, 0x23910c                 ; ld XWA, (0x23910C) — region 0
	nop
	st32_24 0x239164, xwa                 ; st (0x239164), XWA
	nop
	sti8_24 0x2390f0, 0x01                 ; st (0x2390F0), 0x01
	sti8_24 0x2390f2, 0x00                 ; st (0x2390F2), 0x00
	call 2715732				; call 0x297054 — send region
	cpi8_24 0x2390d4, 0x01                 ; error check
	jp_24 z, 2708340			; jp Z, abort
	nop
.Lsfsb_bit1:				; 0x295E7C — Bit 1 (0x02)
	ld8_24 a, 0x2390e2
	nop
	and a, 0x02
	nop
	cps a, 2
	jp_24 nz, 2711222			; jp NZ, .Lsfsb_bit2
	nop
	ld32_24 xwa, 0x23911c                 ; ld XWA, (0x23911C) — region 1
	nop
	st32_24 0x239164, xwa                 ; st (0x239164), XWA
	nop
	sti8_24 0x2390f0, 0x02                 ; st (0x2390F0), 0x02
	sti8_24 0x2390f2, 0x00                 ; st (0x2390F2), 0x00
	call 2715732
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
.Lsfsb_bit2:				; 0x295EB6 — Bit 2 (0x04)
	ld8_24 a, 0x2390e2
	nop
	and a, 0x04
	nop
	cps a, 4
	jp_24 nz, 2711280			; jp NZ, .Lsfsb_bit3
	nop
	ld32_24 xwa, 0x239124                 ; ld XWA, (0x239124) — region 2
	nop
	st32_24 0x239164, xwa                 ; st (0x239164), XWA
	nop
	sti8_24 0x2390f0, 0x04                 ; st (0x2390F0), 0x04
	sti8_24 0x2390f2, 0x00                 ; st (0x2390F2), 0x00
	call 2715732
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
.Lsfsb_bit3:				; 0x295EF0 — Bit 3 (0x08)
	ld8_24 a, 0x2390e2
	nop
	and a, 0x08
	nop
	cp a, 0x08
	nop
	jp_24 nz, 2711340			; jp NZ, .Lsfsb_bit4
	nop
	ld32_24 xwa, 0x23912c                 ; ld XWA, (0x23912C) — region 3
	nop
	st32_24 0x239164, xwa                 ; st (0x239164), XWA
	nop
	sti8_24 0x2390f0, 0x08                 ; st (0x2390F0), 0x08
	sti8_24 0x2390f2, 0x00                 ; st (0x2390F2), 0x00
	call 2715732
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
.Lsfsb_bit4:				; 0x295F2C — Bit 4 (0x10)
	ld8_24 a, 0x2390e2
	nop
	and a, 0x10
	nop
	cp a, 0x10
	nop
	jp_24 nz, 2711400			; jp NZ, .Lsfsb_bit5
	nop
	ld32_24 xwa, 0x239134                 ; ld XWA, (0x239134) — region 4
	nop
	st32_24 0x239164, xwa                 ; st (0x239164), XWA
	nop
	sti8_24 0x2390f0, 0x10                 ; st (0x2390F0), 0x10
	sti8_24 0x2390f2, 0x00                 ; st (0x2390F2), 0x00
	call 2715732
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
.Lsfsb_bit5:				; 0x295F68 — Bit 5 (0x20)
	ld8_24 a, 0x2390e2
	nop
	and a, 0x20
	nop
	cp a, 0x20
	nop
	jp_24 nz, 2711460			; jp NZ, .Lsfsb_bit6
	nop
	ld32_24 xwa, 0x23913c                 ; ld XWA, (0x23913C) — region 5
	nop
	st32_24 0x239164, xwa                 ; st (0x239164), XWA
	nop
	sti8_24 0x2390f0, 0x20                 ; st (0x2390F0), 0x20
	sti8_24 0x2390f2, 0x00                 ; st (0x2390F2), 0x00
	call 2715732
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
.Lsfsb_bit6:				; 0x295FA4 — Bit 6 (0x40)
	ld8_24 a, 0x2390e2
	nop
	and a, 0x40
	nop
	cp a, 0x40
	nop
	jp_24 nz, 2711520			; jp NZ, .Lsfsb_bit7
	nop
	ld32_24 xwa, 0x239140                 ; ld XWA, (0x239140) — region 6
	nop
	st32_24 0x239164, xwa                 ; st (0x239164), XWA
	nop
	sti8_24 0x2390f0, 0x40                 ; st (0x2390F0), 0x40
	sti8_24 0x2390f2, 0x00                 ; st (0x2390F2), 0x00
	call 2715732
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
.Lsfsb_bit7:				; 0x295FE0 — Bit 7 (0x80)
	ld8_24 a, 0x2390e2
	nop
	and a, 0x80
	nop
	cp a, 0x80
	nop
	jp_24 nz, 2711580			; jp NZ, .Lsfsb_bit8
	nop
	ld32_24 xwa, 0x239148                 ; ld XWA, (0x239148) — region 7
	nop
	st32_24 0x239164, xwa                 ; st (0x239164), XWA
	nop
	sti8_24 0x2390f0, 0x80                 ; st (0x2390F0), 0x80
	sti8_24 0x2390f2, 0x00                 ; st (0x2390F2), 0x00
	call 2715732
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
.Lsfsb_bit8:				; 0x29601C — Flag byte 2, bit 0 (0x01)
	ld8_24 a, 0x2390e4                    ; ld A, (0x2390E4) — masked head
	nop
	and a, 0x01
	nop
	cps a, 1
	jp_24 nz, 2711638			; jp NZ, .Lsfsb_exit
	nop
	ld32_24 xwa, 0x239150                 ; ld XWA, (0x239150) — region 8
	nop
	st32_24 0x239164, xwa                 ; st (0x239164), XWA
	nop
	sti8_24 0x2390f0, 0x00                 ; st (0x2390F0), 0x00 — byte 1 = 0
	sti8_24 0x2390f2, 0x01                 ; st (0x2390F2), 0x01 — byte 2 = 1
	call 2715732
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
.Lsfsb_exit:				; 0x296056
	jp HDAE5000_PPORT_Cmd_Done

HDAE5000_Cmd05_RcvFSB:	; 0x29605A (570 bytes)
	; Handler: Receive FSB from PC — reads command params (flag bytes +
	; 8 × 32-bit region descriptors), then conditionally writes each
	; region to HD based on flag bits
	ldw wa, 0x001A				; display command
	nop
	lda_24 xbc, 0x2954f6                  ; lda XBC, 0x2954F6 — status string
	nop
	call HDAE5000_Display_String
	lda_24 xix, 0x239168                  ; lda XIX, 0x239168
	nop
	ld a, (xix + 1)			; flag byte 1
	nop
	st8_24 0x2390e8, a                    ; st (0x2390E8), A
	nop
	ld a, (xix + 2)			; flag byte 2
	nop
	st8_24 0x2390ea, a                    ; st (0x2390EA), A
	nop
	; Copy 8 × 32-bit region descriptors from PPORT data to memory
	ld xwa, (xix + 3)
	nop
	st32_24 0x23910c, xwa                 ; st (0x23910C), XWA
	nop
	ld xwa, (xix + 7)
	nop
	st32_24 0x23911c, xwa                 ; st (0x23911C), XWA
	nop
	ld xwa, (xix + 0x0B)
	nop
	st32_24 0x239124, xwa                 ; st (0x239124), XWA
	nop
	ld xwa, (xix + 0x0F)
	nop
	st32_24 0x23912c, xwa                 ; st (0x23912C), XWA
	nop
	ld xwa, (xix + 0x13)
	nop
	st32_24 0x239134, xwa                 ; st (0x239134), XWA
	nop
	ld xwa, (xix + 0x17)
	nop
	st32_24 0x23913c, xwa                 ; st (0x23913C), XWA
	nop
	ld xwa, (xix + 0x1B)
	nop
	st32_24 0x239148, xwa                 ; st (0x239148), XWA
	nop
	ld xwa, (xix + 0x1F)
	nop
	st32_24 0x239150, xwa                 ; st (0x239150), XWA
	nop
	lds wa, 1				; display command
	di
	call HDAE5000_Display_String
	ei 7
	st32_24 0x239100, xix                 ; st (0x239100), XIX — save data ptr
	nop
	; Write saved flag bytes back to buffer
	ld8_24 a, 0x2390e8                    ; ld A, (0x2390E8)
	nop
	ld (xix), a
	ld8_24 a, 0x2390ea                    ; ld A, (0x2390EA)
	nop
	ld (xix + 1), a
	nop
	ldw wa, 0x0014				; display progress command
	nop
	di
	call HDAE5000_Display_String
	ei 7
	; Test flag byte 1 bit by bit, write corresponding region to HD
	; Bit 0: custom region
	ld8_24 a, 0x2390e8                    ; ld A, (0x2390E8)
	nop
	and a, 0x01
	nop
	cps a, 1
	jp_24 nz, 2711842			; jp NZ, skip bit 0
	nop
	call 2714964				; call 0x296D54 — write custom region
	cpi8_24 0x2390d4, 0x01                 ; error check
	jp_24 z, 2708340			; jp Z, abort
	nop
.Lrcv_bit1:				; 0x296122 — Bit 1
	ld8_24 a, 0x2390e8
	nop
	and a, 0x02
	nop
	cps a, 2
	jp_24 nz, 2711888			; jp NZ, skip
	nop
	ld xiy, 0x001ED350			; region size
	nop
	ld32_24 xde, 0x23911c                 ; ld XDE, (0x23911C) — sector count
	nop
	call 2714494				; call 0x296B7E — write region
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
.Lrcv_bit2:				; 0x296150 — Bit 2
	ld8_24 a, 0x2390e8
	nop
	and a, 0x04
	nop
	cps a, 4
	jp_24 nz, 2711934			; jp NZ, skip
	nop
	ld xiy, 0x000AB000
	nop
	ld32_24 xde, 0x239124                 ; ld XDE, (0x239124)
	nop
	call 2714494
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
.Lrcv_bit3:				; 0x29617E — Bit 3
	ld8_24 a, 0x2390e8
	nop
	and a, 0x08
	nop
	cp a, 0x08
	nop
	jp_24 nz, 2711982			; jp NZ, skip
	nop
	ld xiy, 0x00094800
	nop
	ld32_24 xde, 0x23912c                 ; ld XDE, (0x23912C)
	nop
	call 2714494
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
.Lrcv_bit4:				; 0x2961AE — Bit 4
	ld8_24 a, 0x2390e8
	nop
	and a, 0x10
	nop
	cp a, 0x10
	nop
	jp_24 nz, 2712030			; jp NZ, skip
	nop
	ld xiy, 0x001E0000
	nop
	ld32_24 xde, 0x239134                 ; ld XDE, (0x239134)
	nop
	call 2714494
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
.Lrcv_bit5:				; 0x2961DE — Bit 5
	ld8_24 a, 0x2390e8
	nop
	and a, 0x20
	nop
	cp a, 0x20
	nop
	jp_24 nz, 2712078			; jp NZ, skip
	nop
	ld xiy, 0x001E8800
	nop
	ld32_24 xde, 0x23913c                 ; ld XDE, (0x23913C)
	nop
	call 2714494
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
.Lrcv_bit7:				; 0x29620E — Bit 7
	ld8_24 a, 0x2390e8
	nop
	and a, 0x80
	nop
	cp a, 0x80
	nop
	jp_24 nz, 2712126			; jp NZ, skip
	nop
	ld xiy, 0x003D3000
	nop
	ld32_24 xde, 0x239148                 ; ld XDE, (0x239148)
	nop
	call 2714494
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
.Lrcv_flag2_bit0:			; 0x29623E — Flag byte 2, bit 0
	ld8_24 a, 0x2390ea                    ; ld A, (0x2390EA)
	nop
	and a, 0x01
	nop
	cps a, 1
	jp_24 nz, 2712172			; jp NZ, skip
	nop
	ld xiy, 0x0022B430
	nop
	ld32_24 xde, 0x239150                 ; ld XDE, (0x239150)
	nop
	call 2714494
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2708340
	nop
.Lrcv_finish:				; 0x29626C
	; Restore XIX, write flag bytes back, display final status
	ld32_24 xix, 0x239100                 ; ld XIX, (0x239100)
	nop
	ld8_24 a, 0x2390e8                    ; ld A, (0x2390E8)
	nop
	ld (xix), a
	ld8_24 a, 0x2390ea                    ; ld A, (0x2390EA)
	nop
	ld (xix + 1), a
	nop
	ldw wa, 0x0010				; display final command
	nop
	di
	call HDAE5000_Display_String
	ei 7
	jp HDAE5000_PPORT_Cmd_Done

HDAE5000_Cmd06_WriteFSB:	; 0x296294 (150 bytes)
	; Handler: Write FSB (File System Block) to HD
	; Displays "Write FSB" status, calls render, copies PPORT data to XIX buffer,
	; loads sector/head params, calls Display_String with result, sums and cleans up.
	ldw wa, 0x001A			; display row/column
	nop
	lda_24 xbc, 0x29550e                  ; 0x29550E - "Write FSB" string
	nop
	call HDAE5000_Display_String
	call HDAE5000_Render_Display_Region
	lds wa, 1			; WA = 1
	ei 0x00				; disable interrupts
	call HDAE5000_Display_String
	ei 0x07				; enable interrupts
	xor wa, wa			; WA = 0
	ld8_24 a, 0x2390da                    ; A = [0x2390DA] (FSB byte 0)
	nop
	ld (xix), a			; store to buffer[0]
	ld8_24 a, 0x2390dc                    ; A = [0x2390DC] (FSB byte 1)
	nop
	ld (xix + 1), a			; store to buffer[1]
	nop
	add xix, 0x00000002		; advance buffer pointer past header
	lds bc, 0			; BC = 0 (loop counter)
	lda_24 xiy, 0x239168                  ; XIY = 0x239168 (PPORT command area)
	nop
	add xiy, 0x00000005		; skip 5-byte header
.Lwfsb_copy_loop:
	cp bc, 0x001A			; copied 26 bytes?
	jr z, .Lwfsb_done_copy		; yes, done
	ld_srib3 a, 0x07, 0xF4, 0xE4	; A = (XIY + BC) — read from PPORT data
	nop
	lda_dri3 xbc, 0x07, 0xF0, 0xE4	; (XIX + BC) = A — write to buffer
	nop
	inc 1, bc			; BC++
	jr t, .Lwfsb_copy_loop		; always loop
.Lwfsb_done_copy:
	xor xbc, xbc			; XBC = 0
	xor xde, xde			; XDE = 0
	ld8_24 c, 0x2390d6                    ; C = [0x2390D6] (sector)
	nop
	ld8_24 e, 0x2390d8                    ; E = [0x2390D8] (head)
	nop
	ldw wa, 0x000F			; WA = 0x0F (command code)
	nop
	ei 0x00				; disable interrupts
	call HDAE5000_Display_String
	ei 0x07				; enable interrupts
	cps wa, 0			; result == 0?
	jp_24 z, 2712342		; jp Z, skip error handling (0x296316)
	nop
	call HDAE5000_PPORT_Cleanup
.Lwfsb_after_error:			; 0x296316
	call HDAE5000_PPORT_Sum_Buffer
	cpi8_24 0x2390d4, 0x01                 ; [0x2390D4] == 1? (status check)
	jp_24 z, 2708340		; jp Z, exit to PPORT finish (0x295374)
	nop
	jp HDAE5000_PPORT_Cmd_Done

HDAE5000_PPORT_Cmd_LoadHDtoMemory:	; 0x29632A
	; Load HD to memory - display status and finish
	ldw wa, 0x001A			; display row/column
	nop
	lda_24 xbc, 0x295526                  ; 0x295526 - "Load HD" string
	nop
	call HDAE5000_Display_String
	jp HDAE5000_PPORT_Cmd_Done

HDAE5000_PPORT_Cmd_SendDataBlock:	; 0x29633C (362 bytes)
	; Send data block to PC — display status, render, build transfer buffer
	; from PPORT data, then loop sending 512-byte sectors until count exhausted
	ldw wa, 0x001A				; display command
	nop
	lda_24 xbc, 0x29553e                  ; lda XBC, 0x29553E — status string
	nop
	call HDAE5000_Display_String
	call HDAE5000_Render_Display_Region
	lda_24 xix, 0x239168                  ; lda XIX, 0x239168
	nop
	add xix, 0x00000005			; advance to data offset +5
	ld xwa, (xix)				; read 32-bit sector count
	st32_24 0x239154, xwa                 ; st (0x239154), XWA — save count
	nop
	lds wa, 1				; WA = 1 (display command)
	di
	call HDAE5000_Display_String
	ei 7
	xor wa, wa				; clear WA
	ld8_24 a, 0x2390da                    ; ld A, (0x2390DA) — sector mask
	nop
	ld (xix), a				; store to buffer
	ld8_24 a, 0x2390dc                    ; ld A, (0x2390DC) — head mask
	nop
	ld (xix + 1), a			; store to buffer+1
	nop
	add xix, 0x00000002			; advance past sector/head bytes
	lds bc, 0				; counter = 0
	lda_24 xiy, 0x239168                  ; lda XIY, 0x239168
	nop
	add xiy, 0x00000009			; XIY points to source data offset +9
.Lsdb_copy_loop:			; 0x296394 — copy 26 bytes from XIY+BC to XIX+BC
	cp bc, 0x001A				; 26 bytes?
	jr z, .Lsdb_copy_done			; exit loop
	ld_srib3 a, 0x07, 0xF4, 0xE4		; ld A, (XIY+BC) — source byte
	nop
	lda_dri3 xbc, 0x07, 0xF0, 0xE4		; ld (XIX+BC), A — store to dest
	nop
	inc 1, bc
	jr t, .Lsdb_copy_loop
.Lsdb_copy_done:			; 0x2963AA
	sti8_24 0x2390e6, 0x00                 ; st (0x2390E6), 0 — clear error flag
	xor xbc, xbc
	xor xde, xde
	ld8_24 c, 0x2390d6                    ; ld C, (0x2390D6)
	nop
	ld8_24 e, 0x2390d8                    ; ld E, (0x2390D8)
	nop
	ldw wa, 0x0015				; display command
	nop
	di
	call HDAE5000_Display_String
	ei 7
	cps wa, 0				; check display result
	jp_24 z, 2712542			; jp Z, 0x2963DE — skip error setup
	nop
	ldw wa, 0xFF00				; error indicator
	nop
	sti8_24 0x2390e6, 0x01                 ; st (0x2390E6), 1 — set error flag
.Lsdb_send_header:			; 0x2963DE
	call .Lpsb_write_byte			; send header byte via PPORT
	cpi8_24 0x2390d4, 0x01                 ; error check
	jp_24 z, 2708340			; jp Z, abort
	nop
	cpi8_24 0x2390e6, 0x01                 ; cp (0x2390E6), 1 — error flag set?
	jp_24 z, 2712738			; jp Z, 0x2964A2 — exit
	nop
.Lsdb_sector_loop:			; 0x2963FA — main sector send loop
	ld32_24 xwa, 0x239154                 ; ld XWA, (0x239154) — remaining count
	nop
	cp xwa, 0x00000000			; all done?
	jp_24 z, 2712698			; jp Z, 0x29647A — send final status
	nop
	call 2714666				; call 0x296C2A — read sector from HD
	cpi8_24 0x2390d4, 0x01                 ; error check
	jp_24 z, 2708340			; jp Z, abort
	nop
	sti8_24 0x2390e6, 0x00                 ; clear error flag
	lda_24 xbc, 0x239268                  ; lda XBC, 0x239268 — sector data buffer
	nop
	ld xde, 0x00000200			; 512 bytes
	nop
	ldw wa, 0x0017				; display command (send data)
	nop
	di
	call HDAE5000_Display_String
	ei 7
	cps wa, 0				; check result
	jp_24 z, 2712652			; jp Z, 0x29644C — skip error
	nop
	ldw wa, 0xFF00				; error indicator
	nop
	sti8_24 0x2390e6, 0x01                 ; set error flag
.Lsdb_send_sector:			; 0x29644C
	call .Lpsb_write_byte			; send byte
	cpi8_24 0x2390d4, 0x01                 ; error check
	jp_24 z, 2708340			; jp Z, abort
	nop
	cpi8_24 0x2390e6, 0x01                 ; error flag?
	jp_24 z, 2712738			; jp Z, exit
	nop
	ld32_24 xwa, 0x239154                 ; reload count
	nop
	dec 1, xwa				; decrement sector count
	st32_24 0x239154, xwa                 ; store back
	nop
	jp .Lsdb_sector_loop			; next sector
.Lsdb_send_final:			; 0x29647A — send final status byte
	ldw wa, 0x0016				; display command (final)
	nop
	di
	call HDAE5000_Display_String
	ei 7
	cps wa, 0
	jp_24 z, 2712722			; jp Z, 0x296492 — skip error
	nop
	ldw wa, 0xFF00				; error indicator
	nop
.Lsdb_send_final2:			; 0x296492
	call .Lpsb_write_byte			; send final byte
	cpi8_24 0x2390d4, 0x01                 ; error check
	jp_24 z, 2708340			; jp Z, abort
	nop
	jp HDAE5000_PPORT_Cmd_Done

HDAE5000_PPORT_Cmd_SendFileList:	; 0x2964A6 (226 bytes)
	; Send file list to PC - displays status, builds transfer buffer
	; with disk info from 0x23910C-0x239150, then sends via PPORT.
	ldw wa, 0x001A			; display row/column
	nop
	lda_24 xbc, 0x295556                  ; 0x295556 - "Send File List" string
	nop
	call HDAE5000_Display_String
	call HDAE5000_Render_Display_Region
	call HDAE5000_Render_Display_Region2
	call 2713602			; call 0x296802 (prepare file list)
	ld32_24 xix, 0x239100                 ; XIX = [0x239100] (data source ptr)
	nop
	ld a, (xix)			; A = first byte
	st8_24 0x2390e2, a                    ; [0x2390E2] = first byte
	nop
	ld a, (xix + 1)			; A = second byte
	nop
	st8_24 0x2390e4, a                    ; [0x2390E4] = second byte
	nop
	call 2715144			; call 0x296E08 (process file list)
	call HDAE5000_Render_Display_Region2
	call HDAE5000_PPORT_Ready_Check
	lds bc, 0			; BC = 0 (offset)
	ldw hl, 0x002C			; HL = 44 (block size)
	nop
	call 2714308			; call 0x296AC4 (transfer setup)
	cpi8_24 0x2390e6, 0x00                 ; [0x2390E6] == 0? (error check)
	jp_24 z, 2712830		; jp Z, skip cleanup (0x2964FE)
	nop
	call HDAE5000_PPORT_Cleanup
.Lsfl_build_buffer:			; 0x2964FE
	lda_24 xix, 0x239168                  ; XIX = 0x239168 (PPORT cmd area)
	nop
	ld8_24 a, 0x2390e2                    ; A = [0x2390E2]
	nop
	ld (xix), a			; store to cmd[0]
	ld8_24 a, 0x2390e4                    ; A = [0x2390E4]
	nop
	ld (xix + 1), a			; store to cmd[1]
	nop
	add xix, 0x0000002C		; advance past header (44 bytes)
	; Copy 9 disk info fields (32-bit each) from 0x23910C-0x239150
	ld32_24 xwa, 0x23910c                 ; [0x23910C]
	nop
	ld (xix), xwa
	inc 4, xix
	ld32_24 xwa, 0x23911c                 ; [0x23911C]
	nop
	ld (xix), xwa
	inc 4, xix
	ld32_24 xwa, 0x239124                 ; [0x239124]
	nop
	ld (xix), xwa
	inc 4, xix
	ld32_24 xwa, 0x23912c                 ; [0x23912C]
	nop
	ld (xix), xwa
	inc 4, xix
	ld32_24 xwa, 0x239134                 ; [0x239134]
	nop
	ld (xix), xwa
	inc 4, xix
	ld32_24 xwa, 0x23913c                 ; [0x23913C]
	nop
	ld (xix), xwa
	inc 4, xix
	ld32_24 xwa, 0x239140                 ; [0x239140]
	nop
	ld (xix), xwa
	inc 4, xix
	ld32_24 xwa, 0x239148                 ; [0x239148]
	nop
	ld (xix), xwa
	inc 4, xix
	ld32_24 xwa, 0x239150                 ; [0x239150]
	nop
	ld (xix), xwa
	call HDAE5000_PPORT_Sum_Buffer
	cpi8_24 0x2390d4, 0x01                 ; [0x2390D4] == 1? (status check)
	jp_24 z, 2708340		; jp Z, exit to PPORT finish (0x295374)
	nop
	jp HDAE5000_PPORT_Cmd_Done

HDAE5000_PPORT_Cmd_ReceiveDataBlock:	; 0x296588
	; Receive data from PC - display status and finish
	ldw wa, 0x001A			; display row/column
	nop
	lda_24 xbc, 0x29556e                  ; 0x29556E - "Receive Data" string
	nop
	call HDAE5000_Display_String
	jp HDAE5000_PPORT_Cmd_Done

HDAE5000_PPORT_Cmd_WriteMemoryToHD:	; 0x29659A (230 bytes)
	; Save memory to HD with sector/head masking and multi-step transfer.
	ldw wa, 0x001A			; display row/column
	nop
	lda_24 xbc, 0x295586                  ; 0x295586 - "Write Memory" string
	nop
	call HDAE5000_Display_String
	call HDAE5000_Render_Display_Region
	call HDAE5000_Render_Display_Region2
	call 2713602			; call 0x296802 (prepare data)
	call HDAE5000_PPORT_Ready_Check
	lds bc, 0			; BC = 0
	ldw hl, 0x00C8			; HL = 200 (block size)
	nop
	call 2714308			; call 0x296AC4 (transfer setup)
	lda_24 xix, 0x239168                  ; XIX = 0x239168 (PPORT cmd area)
	nop
	ld a, (xix)			; A = cmd[0]
	st8_24 0x2390de, a                    ; [0x2390DE] = cmd[0] (raw sector byte)
	nop
	ld8_24 w, 0x2390da                    ; W = [0x2390DA] (sector mask)
	nop
	and w, a			; W = cmd[0] AND sector_mask
	st8_24 0x2390e2, w                    ; [0x2390E2] = masked sector
	nop
	ld (xix), w			; update cmd[0] with masked value
	ld a, (xix + 1)			; A = cmd[1]
	nop
	st8_24 0x2390e0, a                    ; [0x2390E0] = cmd[1] (raw head byte)
	nop
	ld8_24 w, 0x2390dc                    ; W = [0x2390DC] (head mask)
	nop
	and w, a			; W = cmd[1] AND head_mask
	st8_24 0x2390e4, w                    ; [0x2390E4] = masked head
	nop
	ld (xix + 1), w			; update cmd[1] with masked value
	nop
	call HDAE5000_PPORT_Sum_Buffer
	cpi8_24 0x2390d4, 0x01                 ; [0x2390D4] == 1? (status check)
	jp_24 z, 2708340		; jp Z → exit to PPORT finish (0x295374)
	nop
	cpi8_24 0x2390e2, 0x00                 ; masked sector == 0?
	jp_24 z, 2713116		; jp Z → check head (0x29661C)
	nop
	jp 2713128			; jp → do write (0x296628)
.Lwmhd_check_head:			; 0x29661C
	cpi8_24 0x2390e4, 0x00                 ; masked head == 0?
	jp_24 z, 2713212		; jp Z → done (0x29667C)
	nop
.Lwmhd_do_write:			; 0x296628
	call HDAE5000_PPORT_Ready_Check
	ld32_24 xix, 0x239100                 ; XIX = [0x239100] (data source ptr)
	nop
	ld8_24 a, 0x2390e2                    ; A = masked sector
	nop
	ld (xix), a			; store to data[0]
	ld8_24 a, 0x2390e4                    ; A = masked head
	nop
	ld (xix + 1), a			; store to data[1]
	nop
	xor xbc, xbc			; XBC = 0
	xor xde, xde			; XDE = 0
	ld8_24 c, 0x2390d6                    ; C = [0x2390D6] (sector param)
	nop
	ld8_24 e, 0x2390d8                    ; E = [0x2390D8] (head param)
	nop
	ldw wa, 0x001B			; WA = 0x1B (write command)
	nop
	ei 0x00				; disable interrupts
	call HDAE5000_Display_String
	ei 0x07				; enable interrupts
	cps wa, 0			; result == 0?
	jp_24 z, 2713196		; jp Z → skip error (0x29666C)
	nop
	call HDAE5000_PPORT_Cleanup
.Lwmhd_after_write:			; 0x29666C
	call HDAE5000_PPORT_Sum_Buffer
	cpi8_24 0x2390d4, 0x01                 ; [0x2390D4] == 1?
	jp_24 z, 2708340		; jp Z → exit (0x295374)
	nop
.Lwmhd_done:				; 0x29667C
	jp HDAE5000_PPORT_Cmd_Done

HDAE5000_PPORT_Cmd_Reserved:	; 0x296680 (62 bytes)
	; Reserved PPORT command - display status, clear buffer, check result
	ldw wa, 0x001A			; display row/column
	nop
	lda_24 xbc, 0x29559e                  ; lda XBC, (0x29559E) - status string
	nop
	call HDAE5000_Display_String
	call HDAE5000_PPORT_Ready_Check
	ldw wa, 0x0011			; display row/column
	nop
	ei 0x00				; enable interrupts
	call HDAE5000_Display_String
	ei 0x07				; disable interrupts
	cps wa, 0			; check result
	jp_24 z, 0x2966AA		; jp Z - skip cleanup if zero
	nop
	call HDAE5000_PPORT_Cleanup
	call HDAE5000_PPORT_Sum_Buffer
	cpi8_24 0x2390d4, 0x01                 ; cp (0x2390D4), 1
	jp_24 z, 0x295374		; jp Z - exit to PPORT finish
	nop
	jp HDAE5000_PPORT_Cmd_Done

PPORT_Utility_1:	; 0x2966BE (60 bytes)
	; PPORT utility - display status, clear buffer, check result
	ldw wa, 0x001A			; display row/column
	nop
	lda_24 xbc, 0x2955b6                  ; lda XBC, (0x2955B6) - status string
	nop
	call HDAE5000_Display_String
	call HDAE5000_PPORT_Ready_Check
	lds wa, 2			; WA = 2
	ei 0x00				; enable interrupts
	call HDAE5000_Display_String
	ei 0x07				; disable interrupts
	cps wa, 0			; check result
	jp_24 z, 0x2966E6		; jp Z - skip cleanup if zero
	nop
	call HDAE5000_PPORT_Cleanup
	call HDAE5000_PPORT_Sum_Buffer
	cpi8_24 0x2390d4, 0x01                 ; cp (0x2390D4), 1
	jp_24 z, 0x295374		; jp Z - exit to PPORT finish
	nop
	jp HDAE5000_PPORT_Cmd_Done

PPORT_Utility_2:	; 0x2966FA
	; PPORT utility routine 2 - display status and finish
	ldw wa, 0x001A			; display row/column
	nop
	lda_24 xbc, 0x2955ce                  ; 0x2955CE - status string
	nop
	call HDAE5000_Display_String
	jp HDAE5000_PPORT_Cmd_Done

PPORT_Utility_3:	; 0x29670C (164 bytes)
	; PPORT utility routine 3 — display string, read PPORT data, execute,
	; check status, display result string (success or error)
	ldw wa, 0x001A				; display command
	nop
	lda_24 xbc, 0x2955e6                  ; lda XBC, 0x2955E6 — string pointer
	nop
	call HDAE5000_Display_String
	lds32 xbc, 0
	lds32 xde, 0
	ldw wa, 0x001D				; display command
	nop
	call HDAE5000_Display_String
	ei 7					; enable interrupts
	lda_24 xix, 0x239168                  ; lda XIX, 0x239168 — PPORT command area
	nop
	ld xwa, (xix + 2)			; read 32-bit parameter
	nop
	st32_24 0x239104, xwa                 ; st (0x239104), XWA — store parameter
	nop
	ld xiy, 0x00010000			; block size 64KB
	nop
	ld32_24 xde, 0x239104                 ; ld XDE, (0x239104)
	nop
	call 2714494				; call 0x296B7E — execute operation
	cpi8_24 0x2390d4, 0x01                 ; cp (0x2390D4), 1 — check status flag
	jp_24 z, 2708340			; jp Z, 0x295374 — abort if status=1
	nop
	ld xbc, 0x00010000			; block size
	nop
	ld xde, 0x00239104			; data address (immediate)
	nop
	ldw wa, 0x001C				; display command
	nop
	call HDAE5000_Display_String
	st16_24 0x2390fa, xwa                 ; st (0x2390FA), WA — save result
	nop
	di					; disable interrupts
	lds32 xbc, 0
	lds32 xde, 0
	ldw wa, 0x001E				; display command
	nop
	call HDAE5000_Display_String
	ld16_24 xwa, 0x2390fa                 ; ld WA, (0x2390FA) — reload result
	nop
	cp wa, 0x0058				; check result value
	jp_24 z, 2713502			; jp Z, 0x29679E — jump if success
	nop
	; Error path
	ldw wa, 0x001A				; display command
	nop
	lda_24 xbc, 0x295614                  ; lda XBC, 0x295614 — error string
	nop
	call HDAE5000_Display_String
	jp HDAE5000_PPORT_Cmd_Done
.Lpu3_success:
	; Success path
	ldw wa, 0x001A				; display command
	nop
	lda_24 xbc, 0x2955fe                  ; lda XBC, 0x2955FE — success string
	nop
	call HDAE5000_Display_String
	jp HDAE5000_PPORT_Cmd_Done

HDAE5000_PPORT_Cmd_Done:	; 0x2967B0 (4 bytes)
	; PPORT command completion - jump to finish handler
	jp 0x295374

HDAE5000_Render_Display_Region:	; 0x2967B4 (48 bytes)
	; Copy 4 display region parameters from (XIX+1..4) to direct memory
	lda_24 xix, 0x239168                  ; lda XIX, (0x239168)
	nop
	ld a, (xix + 1)
	nop
	st8_24 0x2390d6, a                    ; st (0x2390D6), A
	nop
	ld a, (xix + 2)
	nop
	st8_24 0x2390d8, a                    ; st (0x2390D8), A
	nop
	ld a, (xix + 3)
	nop
	st8_24 0x2390da, a                    ; st (0x2390DA), A
	nop
	ld a, (xix + 4)
	nop
	st8_24 0x2390dc, a                    ; st (0x2390DC), A
	nop
	ret
	nop

HDAE5000_Render_Display_Region2:	; 0x2967E4 (166 bytes)
	; Display region rendering 2 — load display params and call Display_String
	xor xbc, xbc				; clear XBC
	xor xde, xde				; clear XDE
	ld8_24 c, 0x2390d6                    ; ld C, (0x2390D6) — column
	nop
	ld8_24 e, 0x2390d8                    ; ld E, (0x2390D8) — row
	nop
	ldw wa, 0x000D				; display command
	nop
	di					; disable interrupts
	call HDAE5000_Display_String
	ei 7					; enable interrupts
	ret
	nop
.Lrdr2_register:			; 0x296802
	; Set WA=1, call Display_String, store XIX to data source ptr
	lds wa, 1
	di
	call HDAE5000_Display_String
	ei 7
	st32_24 0x239100, xix                 ; st (0x239100), XIX — data source ptr
	nop
	ret
	nop
.Lrdr2_main:				; 0x296814
	; Buffer read loop: read 256 bytes via I/O, accumulate 32-bit checksum,
	; then send 4 checksum bytes, finalize
	xor xwa, xwa
	st32_24 0x2390fc, xwa                 ; st (0x2390FC), XWA — clear checksum
	nop
	lds bc, 0				; counter = 0
	lda_24 xix, 0x239168                  ; lda XIX, 0x239168
	nop
.Lrdr2_loop1:				; 0x296824
	cp bc, 0x0100				; 256 iterations?
	jp_24 z, 2713682			; jp Z, 0x296852 — exit loop
	nop
	call 2713856				; call 0x296900 — read one byte → W
	cpi8_24 0x2390d4, 0x01                 ; cp (0x2390D4), 1 — error check
	jp_24 z, 2713736			; jp Z, 0x296888 — exit on error
	nop
	lda_dri3 xwa, 0x07, 0xF0, 0xE4		; ld (XIX+BC), W — store byte to buffer
	nop
	xor xhl, xhl				; XHL = 0
	ld l, w					; L = W (zero-extend byte to 32-bit)
	addm32_24 0x2390fc, xhl                ; add (0x2390FC), XHL — accumulate checksum
	nop
	inc 1, bc				; BC++
	jr t, .Lrdr2_loop1			; loop
.Lrdr2_send_checksum:			; 0x296852
	; Send 4 checksum bytes
	lds bc, 0				; counter = 0
	lda_24 xix, 0x2390fc                  ; lda XIX, 0x2390FC — checksum
	nop
.Lrdr2_loop2:				; 0x29685A
	cps bc, 4				; 4 bytes?
	jp_24 z, 2713724			; jp Z, 0x29687C — exit loop
	nop
	ld_srib3 w, 0x07, 0xF0, 0xE4		; ld W, (XIX+BC) — load checksum byte
	nop
	call 2714016				; call 0x2969A0 — send one byte
	cpi8_24 0x2390d4, 0x01                 ; cp (0x2390D4), 1 — error check
	jp_24 z, 2713736			; jp Z, 0x296888 — exit on error
	nop
	inc 1, bc				; BC++
	jr t, .Lrdr2_loop2			; loop
.Lrdr2_finalize:			; 0x29687C
	call 2714160				; call 0x296A30 — finalize transfer
	cps w, 0				; check result
	jr z, .Lrdr2_exit			; exit if done
	jp .Lrdr2_main				; retry main loop
.Lrdr2_exit:				; 0x296888
	ret
	nop

HDAE5000_PPORT_Sum_Buffer:	; 0x29688A (530 bytes)
	; Sum 256 bytes from buffer, send checksum, then send buffer bytes;
	; retry on success, return on error. Uses PPORT I/O read/write sub-routines.
	xor xwa, xwa
	st32_24 0x2390fc, xwa                 ; st (0x2390FC), XWA — clear 32-bit checksum
	nop
	lds bc, 0				; counter = 0
	lda_24 xix, 0x239168                  ; lda XIX, 0x239168
	nop
.Lpsb_loop1:				; 0x29689A — send buffer bytes and accumulate checksum
	cp bc, 0x0100				; 256 iterations?
	jp_24 z, 2713800			; jp Z, 0x2968C8 — done, send checksum
	nop
	ld_srib3 w, 0x07, 0xF0, 0xE4		; ld W, (XIX+BC) — read buffer byte
	nop
	xor xhl, xhl
	ld l, w					; L = W (zero-extend to 32-bit)
	addm32_24 0x2390fc, xhl                ; add (0x2390FC), XHL — accumulate
	nop
	call .Lpsb_write_byte			; send byte via PPORT
	cpi8_24 0x2390d4, 0x01                 ; cp (0x2390D4), 1 — error?
	jp_24 z, 2713854			; jp Z, 0x2968FE — exit on error
	nop
	inc 1, bc
	jr t, .Lpsb_loop1
.Lpsb_send_checksum:			; 0x2968C8
	lds bc, 0
	lda_24 xix, 0x2390fc                  ; lda XIX, 0x2390FC — checksum bytes
	nop
.Lpsb_loop2:				; 0x2968D0 — send 4 checksum bytes
	cps bc, 4
	jp_24 z, 2713842			; jp Z, 0x2968F2 — done
	nop
	ld_srib3 w, 0x07, 0xF0, 0xE4		; ld W, (XIX+BC) — checksum byte
	nop
	call .Lpsb_write_byte			; send byte
	cpi8_24 0x2390d4, 0x01                 ; error check
	jp_24 z, 2713854			; jp Z, 0x2968FE — exit on error
	nop
	inc 1, bc
	jr t, .Lpsb_loop2
.Lpsb_finalize:				; 0x2968F2
	call .Lpsb_finish			; finalize transfer
	cps w, 0				; check result
	jr z, .Lpsb_exit
	jp HDAE5000_PPORT_Sum_Buffer		; retry
.Lpsb_exit:				; 0x2968FE
	ret
	nop
.Lpsb_read_byte:			; 0x296900 — Read one byte from parallel port → W
	; Handshake: wait for BUSY=1 (bit2=1), then DATA_READY (bit0=1),
	; read data, acknowledge, wait for completion
	ld8_24 a, 0x160004                    ; ld A, (0x160004) — read status
	nop
	ld l, a
	and l, 0x04				; test bit 2
	nop
	cps l, 4				; BUSY?
	jp_24 nz, 2714008			; jp NZ, 0x296998 — error if not busy
	nop
	and a, 0x01				; test bit 0
	nop
	cps a, 1				; DATA_READY?
	jp_24 nz, 2713856			; jp NZ, 0x296900 — retry
	nop
.Lpsb_read_phase2:			; 0x296920
	ld8_24 a, 0x160004                    ; ld A, (0x160004)
	nop
	ld l, a
	and l, 0x04
	nop
	cps l, 4
	jp_24 nz, 2714008			; jp NZ, error
	nop
	and a, 0x02				; test bit 1
	nop
	cps a, 0				; wait for bit1=0
	jp_24 nz, 2713888			; jp NZ, 0x296920 — retry
	nop
	ldb a, 0x99				; command byte — request read
	st8_24 0x160006, a                    ; st (0x160006), A — send command
	nop
	ld8_24 a, 0x160002                    ; ld A, (0x160002) — control register
	nop
	and a, 0xF7				; clear bit 3
	nop
	st8_24 0x160002, a                    ; st (0x160002), A
	nop
.Lpsb_read_phase3:			; 0x296958
	ld8_24 a, 0x160004                    ; ld A, (0x160004) — status
	nop
	ld l, a
	and l, 0x04
	nop
	cps l, 4
	jp_24 nz, 2714008			; jp NZ, error
	nop
	and a, 0x02
	nop
	cps a, 2				; wait for bit1=1
	jp_24 nz, 2713944			; jp NZ, 0x296958 — retry
	nop
	ld8_24 w, 0x160000                    ; ld W, (0x160000) — read data byte
	nop
	ldb a, 0x89				; acknowledge byte
	st8_24 0x160006, a                    ; st (0x160006), A
	nop
	ld8_24 a, 0x160002                    ; ld A, (0x160002)
	nop
	or a, 0x08				; set bit 3
	nop
	st8_24 0x160002, a                    ; st (0x160002), A
	nop
	ret
	nop
.Lpsb_read_error:			; 0x296998
	sti8_24 0x2390d4, 0x01                 ; st (0x2390D4), 1 — set error flag
	ret
	nop
.Lpsb_write_byte:			; 0x2969A0 — Write byte W to parallel port
	; Handshake: wait for BUSY=1 (bit2=1), then READY (bit0=0),
	; write data, signal, wait for ack
	ld8_24 a, 0x160004                    ; ld A, (0x160004) — status
	nop
	ld l, a
	and l, 0x04
	nop
	cps l, 4
	jp_24 nz, 2714152			; jp NZ, 0x296A28 — error
	nop
	and a, 0x01
	nop
	cps a, 0				; wait for bit0=0
	jp_24 nz, 2714016			; jp NZ, 0x2969A0 — retry
	nop
	st8_24 0x160000, w                    ; st (0x160000), W — write data
	nop
	ld8_24 a, 0x160002                    ; ld A, (0x160002)
	nop
	and a, 0xF7				; clear bit 3
	nop
	st8_24 0x160002, a                    ; st (0x160002), A
	nop
.Lpsb_write_phase2:			; 0x2969D6
	ld8_24 a, 0x160004                    ; ld A, (0x160004)
	nop
	ld l, a
	and l, 0x04
	nop
	cps l, 4
	jp_24 nz, 2714152			; jp NZ, error
	nop
	and a, 0x02
	nop
	cps a, 0				; wait for bit1=0
	jp_24 nz, 2714070			; jp NZ, 0x2969D6 — retry
	nop
	ld8_24 a, 0x160002                    ; ld A, (0x160002)
	nop
	or a, 0x08				; set bit 3
	nop
	st8_24 0x160002, a                    ; st (0x160002), A
	nop
.Lpsb_write_phase3:			; 0x296A06
	ld8_24 a, 0x160004                    ; ld A, (0x160004)
	nop
	ld l, a
	and l, 0x04
	nop
	cps l, 4
	jp_24 nz, 2714152			; jp NZ, error
	nop
	and a, 0x02
	nop
	cps a, 2				; wait for bit1=1
	jp_24 nz, 2714118			; jp NZ, 0x296A06 — retry
	nop
	ret
	nop
.Lpsb_write_error:			; 0x296A28
	sti8_24 0x2390d4, 0x01                 ; st (0x2390D4), 1 — set error flag
	ret
	nop
.Lpsb_finish:				; 0x296A30 — Finalize parallel port transfer
	; Deassert, wait for completion, read final status bit
	ld8_24 a, 0x160002                    ; ld A, (0x160002)
	nop
	and a, 0xF7				; clear bit 3
	nop
	st8_24 0x160002, a                    ; st (0x160002), A
	nop
.Lpsb_fin_wait1:			; 0x296A40
	ld8_24 a, 0x160004                    ; ld A, (0x160004)
	nop
	ld l, a
	and l, 0x04
	nop
	cps l, 4
	jp_24 nz, 2714260			; jp NZ, 0x296A94 — error
	nop
	and a, 0x02
	nop
	cps a, 0				; wait for bit1=0
	jr nz, .Lpsb_fin_wait1			; retry
	ld8_24 w, 0x160004                    ; ld W, (0x160004) — final status
	nop
	and w, 0x01				; extract bit 0 → result
	nop
	ld8_24 a, 0x160002                    ; ld A, (0x160002)
	nop
	or a, 0x08				; set bit 3
	nop
	st8_24 0x160002, a                    ; st (0x160002), A
	nop
.Lpsb_fin_wait2:			; 0x296A76
	ld8_24 a, 0x160004                    ; ld A, (0x160004)
	nop
	ld l, a
	and l, 0x04
	nop
	cps l, 4
	jp_24 nz, 2714260			; jp NZ, error
	nop
	and a, 0x02
	nop
	cps a, 2				; wait for bit1=1
	jr nz, .Lpsb_fin_wait2			; retry
	ret
	nop
.Lpsb_fin_error:			; 0x296A94
	sti8_24 0x2390d4, 0x01                 ; st (0x2390D4), 1 — set error flag
	ret
	nop

HDAE5000_PPORT_Ready_Check:	; 0x296A9C (26 bytes)
	; Clear 256 bytes of memory at (XIX + 0..255) using register-indexed store
	lda_24 xix, 0x239168                  ; lda XIX, (0x239168)
	nop
	lds bc, 0		; BC = 0 (loop counter)
.Lprc_loop:
	cp bc, 0x0100		; compare BC with 256
	jr z, .Lprc_done	; if BC == 256, done
	stib_dri 0x07, 0xF0, 0xE4, 0x00	; ld (XIX+BC), 0x00
	inc 1, bc		; BC++
	jr t, .Lprc_loop	; always loop back
.Lprc_done:
	ret
	nop

HDAE5000_PPORT_Cleanup:	; 0x296AB6 (1773 bytes — 10 sub-routines)
	; PPORT cleanup — mark end of buffer with 0xFF sentinel
	lda_24 xix, 0x239168                  ; lda XIX, 0x239168
	nop
	stib_dri 0xF1, 0xFF, 0x00, 0xFF	; ld (XIX+0x00FF), 0xFF
	ret
	nop

.Lppc_utility:				; 0x296AC4 — Display + save XIX + copy buffer
	; Push BC/HL, display command 1, save XIX to data ptr, copy BC..HL bytes
	pushw bc
	nop
	pushw hl
	nop
	lds wa, 1				; display command
	di
	call HDAE5000_Display_String
	ei 7
	st32_24 0x239100, xix                 ; st (0x239100), XIX
	nop
	popw hl
	nop
	popw bc
	nop
	lda_24 xiy, 0x239168                  ; lda XIY, 0x239168
	nop
.Lutl_copy_loop:			; 0x296AE2
	cp bc, hl
	jr z, .Lutl_ret
	ld_srib3 a, 0x07, 0xF0, 0xE4		; ld A, (XIX+BC)
	nop
	lda_dri3 xbc, 0x07, 0xF4, 0xE4	; ld (XIY+BC), A
	nop
	inc 1, bc
	jr t, .Lutl_copy_loop
.Lutl_ret:				; 0x296AF6
	ret
	nop

.Lppc_send_bytes:			; 0x296AF8 — Send XIY bytes to PPORT with checksum
	; Send XDE bytes starting at XIY, accumulate checksum in (0x2390FC)
	; Then send 4 checksum bytes, finalize, retry on failure
	st32_24 0x239158, xiy                 ; st (0x239158), XIY — save start
	nop
	st32_24 0x23915c, xde                 ; st (0x23915C), XDE — save count
	nop
.Lsb_loop_start:			; 0x296B04
	xor xwa, xwa
	st32_24 0x2390fc, xwa                 ; st (0x2390FC), XWA — clear checksum
	nop
	lds32 xbc, 0				; XBC = 0 (byte counter)
.Lsb_send_loop:			; 0x296B0E
	cp xde, xbc
	jp_24 z, 2714426			; jp Z, .Lsb_checksum
	nop
	ld w, (xiy)				; load byte from source
	xor xhl, xhl
	ld l, w					; XHL = byte value
	add (2330876), xhl			; add to checksum at (0x2390FC)
	nop
	call .Lpsb_write_byte			; send byte via PPORT
	cpi8_24 0x2390d4, 0x01                 ; error check
	jp_24 z, 2714492			; jp Z, .Lsb_ret
	nop
	inc 1, xbc
	inc 1, xiy
	jp .Lsb_send_loop
.Lsb_checksum:				; 0x296B3A — Send 4 checksum bytes
	lds bc, 0
	lda_24 xix, 0x2390fc                  ; lda XIX, 0x2390FC
	nop
.Lsb_cksum_loop:			; 0x296B42
	cps bc, 4
	jp_24 z, 2714468			; jp Z, .Lsb_finalize
	nop
	ld_srib3 w, 0x07, 0xF0, 0xE4		; ld W, (XIX+BC)
	nop
	call .Lpsb_write_byte
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2714492			; jp Z, .Lsb_ret
	nop
	inc 1, bc
	jr t, .Lsb_cksum_loop
.Lsb_finalize:				; 0x296B64
	call .Lpsb_finish
	cps w, 0
	jr z, .Lsb_ret
	ld32_24 xiy, 0x239158                 ; reload XIY from (0x239158)
	nop
	ld32_24 xde, 0x23915c                 ; reload XDE from (0x23915C)
	nop
	jp .Lsb_loop_start			; retry
.Lsb_ret:				; 0x296B7C
	ret
	nop

.Lppc_recv_write_bytes:		; 0x296B7E — Receive XDE bytes into XIY with checksum
	; Receive XDE bytes from PPORT into XIY buffer, accumulate checksum
	; Check status port, receive 4 checksum bytes, finalize, retry on failure
	st32_24 0x239158, xiy                 ; st (0x239158), XIY — save start
	nop
	st32_24 0x23915c, xde                 ; st (0x23915C), XDE — save count
	nop
.Lrb_loop_start:			; 0x296B8A
	xor xwa, xwa
	st32_24 0x2390fc, xwa                 ; st (0x2390FC), XWA — clear checksum
	nop
	lds32 xbc, 0
.Lrb_recv_loop:			; 0x296B94
	cp xde, xbc
	jp_24 z, 2714560			; jp Z, .Lrb_status_check
	nop
	call .Lpsb_read_byte			; receive byte from PPORT
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2714664			; jp Z, .Lrb_ret
	nop
	ld (xiy), w				; store received byte
	xor xhl, xhl
	ld l, w
	add (2330876), xhl			; add to checksum
	nop
	inc 1, xbc
	inc 1, xiy
	jp .Lrb_recv_loop
.Lrb_status_check:			; 0x296BC0 — Check PPORT status port
	ld8_24 a, 0x160004                    ; ld A, (0x160004) — status port
	nop
	ld l, a
	and l, 0x04
	nop
	cps l, 4
	jp_24 nz, 2714658			; jp NZ, .Lrb_set_error
	nop
	and a, 0x01
	nop
	cps a, 0
	jr nz, .Lrb_status_check		; wait for ready
.Lrb_recv_cksum:			; 0x296BDC — Receive 4 checksum bytes
	lds bc, 0
	lda_24 xix, 0x2390fc                  ; lda XIX, 0x2390FC
	nop
.Lrb_cksum_loop:			; 0x296BE4
	cps bc, 4
	jp_24 z, 2714630			; jp Z, .Lrb_finalize
	nop
	ld_srib3 w, 0x07, 0xF0, 0xE4		; ld W, (XIX+BC)
	nop
	call .Lpsb_write_byte
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2714664			; jp Z, .Lrb_ret
	nop
	inc 1, bc
	jr t, .Lrb_cksum_loop
.Lrb_finalize:				; 0x296C06
	call .Lpsb_finish
	cps w, 0
	jp_24 z, 2714664			; jp Z, .Lrb_ret
	nop
	ld32_24 xiy, 0x239158                 ; reload saved start
	nop
	ld32_24 xde, 0x23915c                 ; reload saved count
	nop
	jp .Lrb_loop_start			; retry
.Lrb_set_error:			; 0x296C22
	sti8_24 0x2390d4, 0x01                 ; set error flag (0x2390D4)
.Lrb_ret:				; 0x296C28
	ret
	nop

.Lppc_recv_sector_data:		; 0x296C2A — Receive 512-byte sector block
	; Receive 512 bytes into sector buffer (0x239268), checksum, verify
	xor xwa, xwa
	st32_24 0x2390fc, xwa                 ; clear checksum
	nop
	lds bc, 0
	lda_24 xix, 0x239268                  ; lda XIX, 0x239268
	nop
.Lrs_recv_loop:			; 0x296C3A
	cp bc, 0x0200
	jp_24 z, 2714728			; jp Z, .Lrs_checksum
	nop
	call .Lpsb_read_byte
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2714782			; jp Z, .Lrs_ret
	nop
	lda_dri3 xwa, 0x07, 0xF0, 0xE4	; ld (XIX+BC), W
	nop
	xor xhl, xhl
	ld l, w
	add (2330876), xhl			; add to checksum
	nop
	inc 1, bc
	jr t, .Lrs_recv_loop
.Lrs_checksum:				; 0x296C68 — Send 4 checksum bytes
	lds bc, 0
	lda_24 xix, 0x2390fc                  ; lda XIX, 0x2390FC
	nop
.Lrs_cksum_loop:			; 0x296C70
	cps bc, 4
	jp_24 z, 2714770			; jp Z, .Lrs_finalize
	nop
	ld_srib3 w, 0x07, 0xF0, 0xE4		; ld W, (XIX+BC)
	nop
	call .Lpsb_write_byte
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2714782			; jp Z, .Lrs_ret
	nop
	inc 1, bc
	jr t, .Lrs_cksum_loop
.Lrs_finalize:				; 0x296C92
	call .Lpsb_finish
	cps w, 0
	jr z, .Lrs_ret
	jp .Lppc_recv_sector_data		; retry
.Lrs_ret:				; 0x296C9E
	ret
	nop

.Lppc_send_regions:			; 0x296CA0 — Send two descriptor regions + checksum
	; Send from (0x239108)/XDE then (0x239110)/XDE, verify checksum
	ld32_24 xiy, 0x239108                 ; ld XIY, (0x239108)
	nop
	ld32_24 xde, 0x23910c                 ; ld XDE, (0x23910C)
	nop
	xor xwa, xwa
	st32_24 0x2390fc, xwa                 ; clear checksum
	nop
	lds32 xbc, 0
.Lsr_loop1:				; 0x296CB6 — Send first region
	cp xde, xbc
	jp_24 z, 2714850			; jp Z, .Lsr_region2
	nop
	ld w, (xiy)
	xor xhl, xhl
	ld l, w
	add (2330876), xhl
	nop
	call .Lpsb_write_byte
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2714962			; jp Z, .Lsr_ret
	nop
	inc 1, xbc
	inc 1, xiy
	jp .Lsr_loop1
.Lsr_region2:				; 0x296CE2 — Load second region
	ld32_24 xiy, 0x239110                 ; ld XIY, (0x239110)
	nop
	ld32_24 xde, 0x239114                 ; ld XDE, (0x239114)
	nop
	lds32 xbc, 0
.Lsr_loop2:				; 0x296CF0 — Send second region
	cp xde, xbc
	jp_24 z, 2714908			; jp Z, .Lsr_checksum
	nop
	ld w, (xiy)
	xor xhl, xhl
	ld l, w
	add (2330876), xhl
	nop
	call .Lpsb_write_byte
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2714962			; jp Z, .Lsr_ret
	nop
	inc 1, xbc
	inc 1, xiy
	jp .Lsr_loop2
.Lsr_checksum:				; 0x296D1C — Send 4 checksum bytes
	lds bc, 0
	lda_24 xix, 0x2390fc                  ; lda XIX, 0x2390FC
	nop
.Lsr_cksum_loop:			; 0x296D24
	cps bc, 4
	jp_24 z, 2714950			; jp Z, .Lsr_finalize
	nop
	ld_srib3 w, 0x07, 0xF0, 0xE4
	nop
	call .Lpsb_write_byte
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2714962			; jp Z, .Lsr_ret
	nop
	inc 1, bc
	jr t, .Lsr_cksum_loop
.Lsr_finalize:				; 0x296D46
	call .Lpsb_finish
	cps w, 0
	jr z, .Lsr_ret
	jp .Lppc_send_regions			; retry
.Lsr_ret:				; 0x296D52
	ret
	nop

.Lppc_recv_custom_data:		; 0x296D54 — Receive custom ROM data
	; Phase 1: receive 0x640 bytes into 0xF980
	; Phase 2: receive 0x800 bytes into 0x1E7800
	; Then send checksum, finalize, retry on failure
	ld xiy, 0x0000F980
	nop
	ld xde, 0x00000640
	nop
	xor xwa, xwa
	st32_24 0x2390fc, xwa                 ; clear checksum
	nop
	lds32 xbc, 0
.Lrc_loop1:				; 0x296D6A — Receive phase 1
	cp xde, xbc
	jp_24 z, 2715030			; jp Z, .Lrc_phase2
	nop
	call .Lpsb_read_byte
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2715142			; jp Z, .Lrc_ret
	nop
	ld (xiy), w
	xor xhl, xhl
	ld l, w
	add (2330876), xhl
	nop
	inc 1, xbc
	inc 1, xiy
	jp .Lrc_loop1
.Lrc_phase2:				; 0x296D96 — Receive phase 2
	ld xiy, 0x001E7800
	nop
	ld xde, 0x00000800
	nop
	lds32 xbc, 0
.Lrc_loop2:				; 0x296DA4
	cp xde, xbc
	jp_24 z, 2715088			; jp Z, .Lrc_checksum
	nop
	call .Lpsb_read_byte
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2715142			; jp Z, .Lrc_ret
	nop
	ld (xiy), w
	xor xhl, xhl
	ld l, w
	add (2330876), xhl
	nop
	inc 1, xbc
	inc 1, xiy
	jp .Lrc_loop2
.Lrc_checksum:				; 0x296DD0 — Send 4 checksum bytes
	lds bc, 0
	lda_24 xix, 0x2390fc                  ; lda XIX, 0x2390FC
	nop
.Lrc_cksum_loop:			; 0x296DD8
	cps bc, 4
	jp_24 z, 2715130			; jp Z, .Lrc_finalize
	nop
	ld_srib3 w, 0x07, 0xF0, 0xE4
	nop
	call .Lpsb_write_byte
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2715142			; jp Z, .Lrc_ret
	nop
	inc 1, bc
	jr t, .Lrc_cksum_loop
.Lrc_finalize:				; 0x296DFA
	call .Lpsb_finish
	cps w, 0
	jr z, .Lrc_ret
	jp .Lppc_recv_custom_data		; retry
.Lrc_ret:				; 0x296E06
	ret
	nop

.Lppc_init_region_descriptors:	; 0x296E08 — Initialize region descriptors
	; Clear all 10 region descriptor slots to 0, then test each flag bit
	; and load the corresponding region size constant
	lds32 xwa, 0				; XWA = 0
	st32_24 0x23910c, xwa                 ; (0x23910C) = 0
	nop
	st32_24 0x239114, xwa                 ; (0x239114) = 0
	nop
	st32_24 0x23911c, xwa                 ; (0x23911C) = 0
	nop
	st32_24 0x239124, xwa                 ; (0x239124) = 0
	nop
	st32_24 0x23912c, xwa                 ; (0x23912C) = 0
	nop
	st32_24 0x239134, xwa                 ; (0x239134) = 0
	nop
	st32_24 0x23913c, xwa                 ; (0x23913C) = 0
	nop
	st32_24 0x239140, xwa                 ; (0x239140) = 0
	nop
	st32_24 0x239148, xwa                 ; (0x239148) = 0
	nop
	st32_24 0x239150, xwa                 ; (0x239150) = 0
	nop
	; Bit 0: custom region size
	ld8_24 a, 0x2390e2                    ; ld A, (0x2390E2) — masked sector
	nop
	and a, 0x01
	nop
	cps a, 1
	jp_24 nz, 2715236			; jp NZ, .Lir_bit1
	nop
	ld xwa, 0x00000E40
	nop
	st32_24 0x23910c, xwa                 ; st (0x23910C), XWA
	nop
.Lir_bit1:				; 0x296E64 — Bit 1: region 1 size
	ld8_24 a, 0x2390e2
	nop
	and a, 0x02
	nop
	cps a, 2
	jp_24 nz, 2715266			; jp NZ, .Lir_bit2
	nop
	ld xwa, 0x00012CB0
	nop
	st32_24 0x23911c, xwa                 ; st (0x23911C), XWA
	nop
.Lir_bit2:				; 0x296E82 — Bit 2: compute from HD
	ld8_24 a, 0x2390e2
	nop
	and a, 0x04
	nop
	cps a, 4
	jp_24 nz, 2715326			; jp NZ, .Lir_bit3
	nop
	ldb e, 0x04				; E = flag bit value
	sti8_24 0x2390ee, 0x10                 ; st (0x2390EE), 0x10 — sectors per track
	sti8_24 0x2390ec, 0x4E                 ; st (0x2390EC), 0x4E — sector offset
	call .Lppc_compute_sector
	cpi8_24 0x2390e6, 0x01                 ; cp (0x2390E6), 1
	jp_24 z, 2715588			; jp Z, .Lir_ret
	nop
	add xiy, 0x00005000
	st32_24 0x239124, xiy                 ; st (0x239124), XIY
	nop
.Lir_bit3:				; 0x296EBE — Bit 3: compute from HD
	ld8_24 a, 0x2390e2
	nop
	and a, 0x08
	nop
	cp a, 0x08
	nop
	jp_24 nz, 2715382			; jp NZ, .Lir_bit4
	nop
	ldb e, 0x08
	sti8_24 0x2390ee, 0x10                 ; sectors per track
	sti8_24 0x2390ec, 0x2E                 ; sector offset
	call .Lppc_compute_sector
	cpi8_24 0x2390e6, 0x01
	jp_24 z, 2715588			; jp Z, .Lir_ret
	nop
	st32_24 0x23912c, xiy                 ; st (0x23912C), XIY
	nop
.Lir_bit4:				; 0x296EF6 — Bit 4: fixed size
	ld8_24 a, 0x2390e2
	nop
	and a, 0x10
	nop
	cp a, 0x10
	nop
	jp_24 nz, 2715414			; jp NZ, .Lir_bit5
	nop
	ld xwa, 0x000072AA
	nop
	st32_24 0x239134, xwa                 ; st (0x239134), XWA
	nop
.Lir_bit5:				; 0x296F16 — Bit 5: compute from HD
	ld8_24 a, 0x2390e2
	nop
	and a, 0x20
	nop
	cp a, 0x20
	nop
	jp_24 nz, 2715470			; jp NZ, .Lir_bit6
	nop
	ldb e, 0x20
	sti8_24 0x2390ee, 0x10                 ; sectors per track
	sti8_24 0x2390ec, 0x1E                 ; sector offset
	call .Lppc_compute_sector
	cpi8_24 0x2390e6, 0x01
	jp_24 z, 2715588			; jp Z, .Lir_ret
	nop
	st32_24 0x23913c, xiy                 ; st (0x23913C), XIY
	nop
.Lir_bit6:				; 0x296F4E — Bit 6: compute from HD
	ld8_24 a, 0x2390e2
	nop
	and a, 0x40
	nop
	cp a, 0x40
	nop
	jp_24 nz, 2715526			; jp NZ, .Lir_bit7
	nop
	ldb e, 0x40
	sti8_24 0x2390ee, 0x20                 ; sectors per track
	sti8_24 0x2390ec, 0x1C                 ; sector offset
	call .Lppc_compute_sector
	cpi8_24 0x2390e6, 0x01
	jp_24 z, 2715588			; jp Z, .Lir_ret
	nop
	st32_24 0x239140, xiy                 ; st (0x239140), XIY
	nop
.Lir_bit7:				; 0x296F86 — Bit 7: fixed size
	ld8_24 a, 0x2390e2
	nop
	and a, 0x80
	nop
	cp a, 0x80
	nop
	jp_24 nz, 2715558			; jp NZ, .Lir_flag2_bit0
	nop
	ld xwa, 0x00000400
	nop
	st32_24 0x239148, xwa                 ; st (0x239148), XWA
	nop
.Lir_flag2_bit0:			; 0x296FA6 — Flag byte 2, bit 0
	ld8_24 a, 0x2390e4                    ; ld A, (0x2390E4) — masked head
	nop
	and a, 0x01
	nop
	cps a, 1
	jp_24 nz, 2715588			; jp NZ, .Lir_ret
	nop
	ld xwa, 0x002304F2
	nop
	st32_24 0x239150, xwa                 ; st (0x239150), XWA
	nop
.Lir_ret:				; 0x296FC4
	ret
	nop

.Lppc_compute_sector:		; 0x296FC6 — Compute sector descriptor
	; Read HD sector using display commands, compute XIY from sector data
	ld32_24 xix, 0x239100                 ; ld XIX, (0x239100)
	nop
	sti8_24 0x2390e6, 0x00                 ; clear error flag (0x2390E6)
	xor wa, wa
	ld a, e					; A = flag bit value
	ld (xix), wa				; store to buffer
	xor xbc, xbc
	xor xde, xde
	ld8_24 c, 0x2390d6                    ; ld C, (0x2390D6)
	nop
	ld8_24 e, 0x2390d8                    ; ld E, (0x2390D8)
	nop
	ldw wa, 0x0018				; display command — HD read
	nop
	di
	call HDAE5000_Display_String
	ei 7
	cps wa, 0				; check result
	jp_24 z, 2715652			; jp Z, .Lcs_read_sector
	nop
	sti8_24 0x2390e6, 0x01                 ; set error flag
	jr t, .Lcs_ret
.Lcs_read_sector:			; 0x297004
	lda_24 xbc, 0x239268                  ; lda XBC, 0x239268
	nop
	ld xde, 0x00000200			; 512 bytes
	nop
	ldw wa, 0x0019				; display command — sector read
	nop
	di
	call HDAE5000_Display_String
	ei 7
	cps wa, 0
	jp_24 z, 2715692			; jp Z, .Lcs_process
	nop
	sti8_24 0x2390e6, 0x01                 ; set error flag
	jr t, .Lcs_ret
.Lcs_process:				; 0x29702C — Process sector data
	xor xwa, xwa
	lda_24 xix, 0x239268                  ; lda XIX, 0x239268
	nop
	ld8_24 a, 0x2390ec                    ; ld A, (0x2390EC) — sector offset
	nop
	add xix, xwa				; XIX += offset (A in low byte)
	cpi8_24 0x2390ee, 0x20                 ; cp (0x2390EE), 0x20 — check sectors/track
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

.Lppc_send_region_to_pc:		; 0x297054 — Send region data to PC
	; Main send routine: reads region descriptor, sets up PPORT buffer,
	; sends sectors in 512-byte blocks with checksum verification
	ld32_24 xwa, 0x239164                 ; ld XWA, (0x239164) — region descriptor
	nop
	st32_24 0x239158, xwa                 ; st (0x239158), XWA — save for retry
	nop
	xor xwa, xwa
	st32_24 0x2390fc, xwa                 ; clear checksum
	nop
	sti8_24 0x2390e6, 0x00                 ; clear error flag
	call 2713602				; call 0x296802 — register XIX
	ld32_24 xix, 0x239100                 ; ld XIX, (0x239100)
	nop
	xor wa, wa
	ld8_24 a, 0x2390f0                    ; ld A, (0x2390F0) — flag byte 1
	nop
	ld (xix), a				; store to buffer[0]
	ld8_24 a, 0x2390f2                    ; ld A, (0x2390F2) — flag byte 2
	nop
	ld (xix + 1), a			; store to buffer[1]
	nop
	xor bc, bc
	xor de, de
	ld8_24 c, 0x2390d6                    ; ld C, (0x2390D6)
	nop
	ld8_24 e, 0x2390d8                    ; ld E, (0x2390D8)
	nop
	ldw wa, 0x0018				; display command — HD read
	nop
	di
	call HDAE5000_Display_String
	ei 7
	cps wa, 0
	jp_24 z, 2715834			; jp Z, .Lsrpc_send_init
	nop
	ldw wa, 0xFF00				; error marker
	nop
	sti8_24 0x2390e6, 0x01                 ; set error flag
.Lsrpc_send_init:			; 0x2970BA — Send WA byte + start transfer
	call .Lpsb_write_byte
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2716066			; jp Z, .Lsrpc_ret
	nop
	cpi8_24 0x2390e6, 0x01                 ; check error flag
	jp_24 z, 2716066			; jp Z, .Lsrpc_ret
	nop
	lda_24 xix, 0x239268                  ; lda XIX, 0x239268
	nop
	sti16_24 0x2390f8, 0x0200              ; st (0x2390F8), 0x0200 — block size
	nop
.Lsrpc_main_loop:			; 0x2970E4 — Main send loop
	ld32_24 xwa, 0x239164                 ; ld XWA, (0x239164) — remaining bytes
	nop
	cp xwa, 0				; all bytes sent?
	jp_24 z, 2716000			; jp Z, .Lsrpc_final_checksum
	nop
	cpdi16_24 2330872, 0x0200		; cp (0x2390F8), 0x0200
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
	di
	call HDAE5000_Display_String
	ei 7
	pop xix
	nop
	sti16_24 0x2390f8, 0x0000              ; reset block counter
	nop
.Lsrpc_send_byte:			; 0x297122 — Send one byte
	ld16_24 xbc, 0x2390f8                 ; ld BC, (0x2390F8) — block offset
	nop
	ld_srib3 w, 0x07, 0xF0, 0xE4		; ld W, (XIX+BC) — load byte
	nop
	xor xhl, xhl
	ld l, w
	add (2330876), xhl			; add to checksum
	nop
	call .Lpsb_write_byte
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2716066			; jp Z, .Lsrpc_ret
	nop
	incdi16_24	1, 0x2390F8
	nop
	ld32_24 xwa, 0x239164                 ; ld XWA, (0x239164)
	nop
	dec 1, xwa
	st32_24 0x239164, xwa                 ; st (0x239164), XWA
	nop
	jp .Lsrpc_main_loop
.Lsrpc_final_checksum:		; 0x297160 — Send 4 checksum bytes
	lds bc, 0
	lda_24 xix, 0x2390fc                  ; lda XIX, 0x2390FC
	nop
.Lsrpc_cksum_loop:			; 0x297168
	cps bc, 4
	jp_24 z, 2716042			; jp Z, .Lsrpc_finalize
	nop
	ld_srib3 w, 0x07, 0xF0, 0xE4
	nop
	call .Lpsb_write_byte
	cpi8_24 0x2390d4, 0x01
	jp_24 z, 2716066			; jp Z, .Lsrpc_ret
	nop
	inc 1, bc
	jr t, .Lsrpc_cksum_loop
.Lsrpc_finalize:			; 0x29718A
	call .Lpsb_finish
	cps w, 0
	jr z, .Lsrpc_ret
	ld32_24 xwa, 0x239158                 ; reload saved region descriptor
	nop
	st32_24 0x239164, xwa                 ; st (0x239164), XWA
	nop
	jp .Lppc_send_region_to_pc		; retry
.Lsrpc_ret:				; 0x2971A2
	ret

HDAE5000_Check_HD_Present:	; 2971A3h
	; Entry wrapper for HD presence detection
	; Clears result flag, calls internal RAM test routine, returns result
	; Output: L = 0 if no HD, non-zero if HD detected
	push xiz
	sti8_24 0x229d92, 0x00                 ; ld (229D92h), 0 - clear result flag
	call HDAE5000_RAM_Test	; Call internal test routine
	pop xiz
	xor hl, hl	; Clear HL
	ld8_24 l, 0x229d92                    ; ld L, (229D92h) - get result
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

HDAE5000_RAM_Test:	; 0x2971B7 (1902 bytes)
	; RAM test: fill/verify 32KB at 0x230F1C-0x238F1C with 0x5A5A pattern
; LRT: 0x2971B7 (1902 bytes)

	ldw	wa, 0x5a5a
	lda_24 xiy, 0x230f1c
	cp	xiy, 0x00238f1c
	jp_24	z, 0x2971D2
	ld (xiy), wa                            ; ld (XIY),WA
	inc 2, xiy                              ; inc 2,XIY
	jp 0x2971bf                             ; jp 0x2971bf
	lda_24 xiy, 0x230f1c
	cp	xiy, 0x00238f1c
	jp_24	z, 0x2971F5
	cp	(xiy), wa
	jp_24	z, 0x2971EF
	ldb	a, 0x02
	jp 0x29742f                             ; jp 0x29742f
	inc 2, xiy                              ; inc 2,XIY
	jp 0x2971d7                             ; jp 0x2971d7
	xor	wa, wa
	lda_24 xiy, 0x230f1c
	cp	xiy, 0x00238f1c
	jp_24	z, 0x29720F
	ld (xiy), wa                            ; ld (XIY),WA
	inc 2, xiy                              ; inc 2,XIY
	jp 0x2971fc                             ; jp 0x2971fc
	call 0x298c15
	call 0x295352
	lda_24 xwa, 0x298c9d
	ld	(0x229d6c), xwa
	sti8_24	0x229D90, 0
	sti8_24	0x229D92, 0
	sti8_24	0x229D99, 1
	sti8_24	0x229D9A, 1
	sti8_24	0x229DA9, 1
	sti8_24	0x229DAA, 1
	sti8_24	0x229DAB, 1
	sti8_24	0x229DAC, 1
	sti8_24	0x229DAD, 1
	sti8_24	0x229DAE, 1
	sti8_24	0x229DC8, 0
	sti8_24	0x229DD9, 1
	ld	xwa, 0x000017a8
	ld	(0x229d78), xwa
	lda_24 xix, 0x2013b2
	ld	xbc, 0x00000186
	sti8_24	0x229DC2, 0
	sti8_24	0x229DC3, 0
	sti8_24	0x229DC4, 0
	sti8_24	0x229DC5, 0
	sti8_24	0x229DC6, 0
	sti8_24	0x229DC7, 0
	cp	xbc, 0x00000000
	jp_24	z, 0x2972B7
	ld	(xix), 0x20
	dec	1, xbc
	inc 1, xix                              ; inc 1,XIX
	jp 0x2972a1                             ; jp 0x2972a1
	sti8_24	0x229D9F, 0
	sti8_24	0x229DDA, 0
	sti8_24	0x229DDB, 0
	sti8_24	0x229DDC, 0
	sti8_24	0x229DDD, 0
	sti8_24	0x229DDE, 0
	sti8_24	0x229DDF, 0
	sti8_24	0x229DD6, 0
	sti8_24	0x229DA0, 0
	sti8_24	0x229E57, 0
	sti8_24	0x229E58, 0
	sti8_24	0x229E59, 0
	sti8_24	0x229E5A, 0
	sti8_24	0x229E5B, 0
	sti8_24	0x229E5C, 0
	xor	bc, bc
	lda_24 xix, 0x229e5c
	cp	bc, 0x0078
	jp_24	z, 0x29732C
	ld	(xix), 0x00
	inc 1, xix                              ; inc 1,XIX
	inc	1, bc
	jp 0x297318                             ; jp 0x297318
	xor	bc, bc
	lda_24 xix, 0x229ddf
	cp	bc, 0x0078
	jp_24	z, 0x297347
	ld	(xix), 0x00
	inc 1, xix                              ; inc 1,XIX
	inc	1, bc
	jp 0x297333                             ; jp 0x297333
	call 0x29747a
	cpi8_24	0x200222, 0
	jp_24	z, 0x29735C
	ldb	a, 0x03
	jp 0x29742f                             ; jp 0x29742f
	call 0x297884
	cpi8_24	0x200222, 0
	jp_24	z, 0x297371
	ldb	a, 0x05
	jp 0x29742f                             ; jp 0x29742f
	call 0x2975ad
	lds32	xhl, 1
	lda_24 xix, 0x200628
	ld	xde, 0x00000200
	call 0x297788
	cpi8_24	0x200222, 0
	jp_24	z, 0x297396
	ldb	a, 0x06
	jp 0x29742f                             ; jp 0x29742f
	call 0x29750f
	cpi8_24	0x229D98, 1
	jp_24	z, 0x2973B2
	lds32	xwa, 0
	ld	(0x229c80), xwa
	ldb	a, 0x01
	jp 0x29742f                             ; jp 0x29742f
	lda_24 xix, 0x2006a0
	ld	a, (xix)
	st8_24	0x229DA9, a
	inc 1, xix                              ; inc 1,XIX
	ld	a, (xix)
	st8_24	0x229DAA, a
	inc 1, xix                              ; inc 1,XIX
	ld	a, (xix)
	st8_24	0x229DAB, a
	inc 1, xix                              ; inc 1,XIX
	ld	a, (xix)
	st8_24	0x229DAC, a
	inc 1, xix                              ; inc 1,XIX
	ld	a, (xix)
	st8_24	0x229DAD, a
	inc 1, xix                              ; inc 1,XIX
	ld	a, (xix)
	st8_24	0x229DAE, a
	call 0x297d49
	cpi8_24	0x200222, 0
	jp_24	z, 0x297400
	ldb	a, 0x07
	jp 0x29742f                             ; jp 0x29742f
	call 0x29797f
	cpi8_24	0x229D98, 1
	jp_24	nz, 0x297424
	call 0x297be9
	cpi8_24	0x200222, 0
	jp_24	z, 0x297424
	ldb	a, 0x08
	jp 0x29742f                             ; jp 0x29742f
	sti8_24	0x229D92, 0
	call 0x2974c7
	ret

	st8_24	0x229D92, a
	jp 0x29742a                             ; jp 0x29742a
	push xix
	pushw wa                                ; push WA
	lds32	xix, 0
	cp	xix, 0x003fffff
	jp_24	z, 0x29745D
	ld8_24	a, 0x13001E
	and	a, 0xc0
	cp	a, 0x40
	jp_24	z, 0x297463
	inc 1, xix                              ; inc 1,XIX
	jp 0x29743c                             ; jp 0x29743c
	sti8_24	0x200222, 1
	popw wa                                 ; pop WA
	pop xix                                 ; pop XIX
	ret

	push xiz
	call 0x29747a
	xor	hl, hl
	cpi8_24	0x200222, 0
	jr z, .LRT_7478                        ; [66 03] jr Z,0x297478
	ldw	hl, 0xffff
.LRT_7478:
	pop xiz                                 ; pop XIZ
	ret

	sti8_24	0x200222, 0
	call 0x297438
	cpi8_24	0x200222, 0
	jp_24	z, 0x297493
	jp 0x2974b4                             ; jp 0x2974b4
	sti8_24	0x130020, 14
	sti8_24	0x130020, 10
	call 0x297438
	cpi8_24	0x200222, 0
	jp_24	z, 0x2974B4
	sti8_24	0x200222, 1
	ret

	call 0x2974c7
	xor	hl, hl
	cpi8_24	0x200222, 0
	jr z, .LRT_74c6                        ; [66 03] jr Z,0x2974c6
	ldw	hl, 0xffff
.LRT_74c6:
	ret

	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	call 0x297438
	cpi8_24	0x200222, 0
	jp_24	nz, 0x297507
	sti8_24	0x130012, 255
	sti8_24	0x130014, 0
	sti8_24	0x130016, 255
	sti8_24	0x130018, 255
	sti8_24	0x13001A, 255
	sti8_24	0x13001C, 160
	sti8_24	0x13001E, 148
	pop xiz                                 ; pop XIZ
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	pop xhl                                 ; pop XHL
	pop xde                                 ; pop XDE
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

	push xix
	push xbc
	push xwa
	lda_24 xix, 0x200628
	ld xwa, (xix)                           ; ld XWA,(XIX)
	ld xbc, (xix + 0x04)                    ; ld XBC,(XIX+0x04)
	cp	xwa, 0xaa55aa55
	jp_24	z, 0x297531
	sti8_24	0x229D98, 0
	jp 0x29754c                             ; jp 0x29754c
	cp	xbc, 0xf4f1f2f3
	jp_24	z, 0x297546
	sti8_24	0x229D98, 0
	jp 0x29754c                             ; jp 0x29754c
	sti8_24	0x229D98, 1
	call 0x298993
	pop xwa                                 ; pop XWA
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

	push xwa
	push xbc
	push xix
	lda_24 xix, 0x299a4b
	ld xwa, (xix)                           ; ld XWA,(XIX)
	ld	xbc, (0x229c60)
	cp	xwa, xbc
	jp_24	z, 0x29756F
	pop xix                                 ; pop XIX
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	pop xwa                                 ; pop XWA
	ret

	pop xix                                 ; pop XIX
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

	push xiz
	push xwa
	call 0x2975ad
	pop xwa                                 ; pop XWA
	ld	xix, xwa
	ld16_24	wa, 0x229C32
	ld (xix), wa                            ; ld (XIX),WA
	ld16_24	wa, 0x229C34
	ld (xix + 0x02), wa                     ; ld (XIX+0x02),WA
	ld16_24	wa, 0x200220
	ld (xix + 0x04), wa                     ; ld (XIX+0x04),WA
	ld	xwa, (0x200223)
	ld (xix + 0x06), xwa                    ; ld (XIX+0x06),XWA
	add	xix, 0x0000000a
	ld	xiy, 0x0020083c
	ldw	bc, 0x0014
	ldirw                                   ; ldirw
	pop xiz                                 ; pop XIZ
	ret

	lda_24 xix, 0x200000
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
	jp_24	ge, 0x2975EE
	ld	xwa, 0x00000020
	ld	(0x229c5c), xwa
	jp 0x2975f8                             ; jp 0x2975f8
	ld	xwa, 0x00000040
	ld	(0x229c5c), xwa
	ld	xbc, 0x00000200
	call HDAE5000_HD_Init_Variables
	ld	(0x229c58), xwa
	xor	xwa, xwa
	xor	xbc, xbc
	ld16_24	wa, 0x229C32
	ld16_24	bc, 0x200220
	call HDAE5000_HD_Init_Variables
	ld	(0x200200), xwa
	lds32	xwa, 2
	ld	(0x229c68), xwa
	add	xwa, 0x00000f42
	ld	(0x229c64), xwa
	add	xwa, 0x00000143
	ld	(0x229c6c), xwa
	ld	xwa, (0x200223)
	ld	xbc, (0x229c6c)
	sub	xwa, xbc
	inc 1, xwa                              ; inc 1,XWA
	ld	(0x229c94), xwa
	ld	xwa, (0x229c5c)
	ld	xbc, 0x00000080
	call HDAE5000_HD_Init_Variables
	ld	xbc, xwa
	ld	xwa, (0x229c94)
	call HDAE5000_HD_Config_Init_Values
	ld	xbc, 0x00000080
	call HDAE5000_HD_Init_Variables
	ld	(0x229c70), xwa
	lda_24 xiy, 0x20083c
	lda_24 xix, 0x200036
	lds	bc, 0
	cp	bc, 0x0028
	jp_24	z, 0x29769A
	ld	wa, (xix)
	ld	(xiy), w
	ld	(xiy+1), a
	inc	2, bc
	inc 2, xix                              ; inc 2,XIX
	inc 2, xiy                              ; inc 2,XIY
	jp 0x297680                             ; jp 0x297680
	ret

	ld	(0x200204), xhl
	ld	(0x200208), xix
	sti8_24	0x200222, 0
	ld8_24	a, 0x13001E
	and	a, 0xc0
	cp	a, 0x40
	jp_24	z, 0x2976BF
	jp 0x2976ab                             ; jp 0x2976ab
	sti8_24	0x130014, 1
	ld	xwa, (0x200204)
	dec	1, xwa
	ld	xbc, (0x200200)
	calr	0x0276
	ld	e, a
	or	a, 0xa0
	st8_24	0x13001C, a
	xor	xwa, xwa
	ld	a, e
	ld	xbc, (0x200200)
	calr	0x023b
	ld	(0x200218), xwa
	ld	xbc, xwa
	ld	xwa, (0x200204)
	sub	xwa, xbc
	dec	1, xwa
	xor	xbc, xbc
	ld16_24	bc, 0x200220
	calr	0x0246
	st8_24	0x130018, a
	st8_24	0x13001A, w
	xor	xbc, xbc
	ld16_24	bc, 0x200220
	calr	0x020d
	ld	xbc, (0x200218)
	add	xbc, xwa
	ld	xwa, (0x200204)
	sub	xwa, xbc
	st8_24	0x130016, a
	sti8_24	0x13001E, 48
	ld8_24	a, 0x13001E
	and	a, 0xc8
	cp	a, 0x48
	jp_24	z, 0x297745
	jp 0x297731                             ; jp 0x297731
	lds	bc, 0
	ld	xix, (0x200208)
	cp	bc, 0x0200
	jp_24	nc, 0x297766
	ld	wa, (xix)
	ld	(0x130010), wa
	inc 2, xix                              ; inc 2,XIX
	inc 2, xiy                              ; inc 2,XIY
	inc	2, bc
	jp 0x29774c                             ; jp 0x29774c
	ld8_24	a, 0x13001E
	and	a, 0xc0
	cp	a, 0x40
	jp_24	z, 0x29777A
	jp 0x297766                             ; jp 0x297766
	ld8_24	a, 0x13001E
	and	a, 0x01
	st8_24	0x200222, a
	ret

	ld	(0x20020c), xhl
	ld	(0x200210), xix
	ld	(0x200214), xde
	sti8_24	0x200222, 0
	ld8_24	a, 0x13001E
	and	a, 0xc0
	cp	a, 0x40
	jp_24	z, 0x2977B1
	jp 0x29779d                             ; jp 0x29779d
	sti8_24	0x130014, 1
	ld	xwa, (0x20020c)
	dec	1, xwa
	ld	xbc, (0x200200)
	calr	0x0184
	ld	e, a
	or	a, 0xa0
	st8_24	0x13001C, a
	xor	xwa, xwa
	ld	a, e
	ld	xbc, (0x200200)
	calr	0x0149
	ld	(0x20021c), xwa
	ld	xbc, xwa
	ld	xwa, (0x20020c)
	sub	xwa, xbc
	dec	1, xwa
	xor	xbc, xbc
	ld16_24	bc, 0x200220
	calr	0x0154
	st8_24	0x130018, a
	st8_24	0x13001A, w
	xor	xbc, xbc
	ld16_24	bc, 0x200220
	calr	0x011b
	ld	xbc, (0x20021c)
	add	xbc, xwa
	ld	xwa, (0x20020c)
	sub	xwa, xbc
	st8_24	0x130016, a
	sti8_24	0x13001E, 32
	ld8_24	a, 0x13001E
	and	a, 0xc8
	cp	a, 0x48
	jp_24	z, 0x297837
	jp 0x297823                             ; jp 0x297823
	lds	bc, 0
	ld	xix, (0x200210)
	ld	xde, (0x200214)
	cp	bc, 0x0200
	jp_24	nc, 0x297862
	ld16_24	wa, 0x130010
	cp	bc, de
	jp_24	nc, 0x29785A
	ld (xix), wa                            ; ld (XIX),WA
	inc 2, xix                              ; inc 2,XIX
	inc	2, bc
	jp 0x297843                             ; jp 0x297843
	ld8_24	a, 0x13001E
	and	a, 0xc0
	cp	a, 0x40
	jp_24	z, 0x297876
	jp 0x297862                             ; jp 0x297862
	ld8_24	a, 0x13001E
	and	a, 0x01
	st8_24	0x200222, a
	ret

	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	ld8_24	a, 0x13001E
	and	a, 0xc0
	cp	a, 0x40
	jp_24	z, 0x29789F
	jp 0x29788b                             ; jp 0x29788b
	sti8_24	0x130012, 255
	sti8_24	0x130014, 255
	sti8_24	0x130016, 255
	sti8_24	0x130018, 255
	sti8_24	0x13001A, 255
	sti8_24	0x13001C, 160
	sti8_24	0x13001E, 236
	ld8_24	a, 0x13001E
	and	a, 0xc8
	cp	a, 0x48
	jp_24	z, 0x2978DD
	jp 0x2978c9                             ; jp 0x2978c9
	lds	bc, 0
	ld	xix, 0x00200000
	cp	bc, 0x0200
	jp_24	nc, 0x2978FC
	ld16_24	wa, 0x130010
	ld (xix), wa                            ; ld (XIX),WA
	inc 2, xix                              ; inc 2,XIX
	inc	2, bc
	jp 0x2978e4                             ; jp 0x2978e4
	ld8_24	a, 0x13001E
	and	a, 0xc0
	cp	a, 0x40
	jp_24	z, 0x297910
	jp 0x2978fc                             ; jp 0x2978fc
	ld8_24	a, 0x13001E
	and	a, 0x01
	st8_24	0x200222, a
	pop xiz                                 ; pop XIZ
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	pop xhl                                 ; pop XHL
	pop xde                                 ; pop XDE
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret


HDAE5000_HD_Init_Variables:	; 0x297925 (37 bytes)
	; 32x32 → 64-bit multiply using partial products
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
	lds hl, 0			; clear low HL
	add xix, xhl			; add shifted partial product
	ld	hl, qbc
	mul xhl, xwa			; XHL = high(BC) * WA
	ld	qhl, hl
	lds hl, 0			; clear low HL
	add xix, xhl			; add shifted partial product
	ld xwa, xix			; result in XWA
	pop xix
	pop xhl
	ret

HDAE5000_HD_Config_Init_Values:	; 0x29794A (392 bytes)
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
	cps iz, 0
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
.Lhciv_mem_init:				; 0x29797F
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	; Region 1: fill 0x201632-0x201DB2 with 0x20 (space)
	ld xix, 2102834		; 0x201632
	ld xiy, 2104754		; 0x201DB2
.Lhciv_fill1:
	cp xix, xiy
	jp_24 z, 2718112		; jp Z, .Lhciv_section2
	ld (xix), 32		; store 0x20 (space)
	inc 1, xix
	jp .Lhciv_fill1
	; Region 2: structured fill 0x201DB2-0x2257B2 (76-byte records)
.Lhciv_section2:			; 0x2979A0
	ld xix, 2104754		; 0x201DB2
	ld xiy, 2250674		; 0x2257B2
.Lhciv_outer2:				; 0x2979AA
	cp xix, xiy
	jp_24 z, 2718243		; jp Z, .Lhciv_section3
	; Inner: 26 bytes of 0x20 (space)
	xor xbc, xbc
.Lhciv_space26:				; 0x2979B3
	cp xbc, 26
	jp_24 z, 2718155		; jp Z, .Lhciv_zeros
	push xix
	add xix, xbc
	ld (xix), 32
	pop xix
	inc 1, xbc
	jp .Lhciv_space26
	; Inner: 10 bytes of 0x00 at offset 26
.Lhciv_zeros:				; 0x2979CB
	lds bc, 0
.Lhciv_zeros_loop:			; 0x2979CD
	cp bc, 10
	jp_24 z, 2718185		; jp Z, .Lhciv_ff
	pushw bc
	ldw wa, 26
	add bc, wa			; offset = counter + 26
	stib_dri 0x07, 0xF0, 0xE4, 0x00	; ld (XIX+BC), 0x00
	popw bc
	inc 1, bc
	jp .Lhciv_zeros_loop
	; Inner: 10 × 32-bit 0xFFFFFFFF at offset 36
.Lhciv_ff:				; 0x2979E9
	xor xbc, xbc
.Lhciv_ff_loop:				; 0x2979EB
	cp xbc, 10
	jp_24 z, 2718233		; jp Z, .Lhciv_next_record
	push xbc
	lds32 xwa, 4			; entry size = 4 bytes
	call HDAE5000_HD_Init_Variables	; XWA = XBC * 4 (multiply)
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
	ld xix, 2250674		; 0x2257B2
	ld xiy, 2267954		; 0x229B32
.Lhciv_fill_zero:			; 0x297A2D
	cp xix, xiy
	jp_24 z, 2718269		; jp Z, .Lhciv_section4
	ld (xix), 0
	inc 1, xix
	jp .Lhciv_fill_zero
	; Region 4: fill 0x2257B2 in blocks of 144-byte rows, 120 rows,
	; 16 bytes of 0x20 per row
.Lhciv_section4:			; 0x297A3D
	ld xix, 2250674		; 0x2257B2
	lds hl, 0			; row counter
.Lhciv_row_loop:			; 0x297A44
	cp hl, 120			; 0x78 rows total
	jp_24 z, 2718320		; jp Z, .Lhciv_mem_exit
	lds bc, 0			; column counter
.Lhciv_col_loop:			; 0x297A4F
	cp bc, 16			; 16 bytes per row
	jp_24 z, 2718308		; jp Z, .Lhciv_next_row
	stib_dri 0x07, 0xF0, 0xE4, 0x20	; ld (XIX+BC), 0x20
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
.Lhciv_hd_check:			; 0x297A78
	call .Lhciv_hd_config_init
	xor hl, hl
	cpi8_24 0x200222, 0x00                 ; cp (0x200222), 0
	jp_24 z, 2718348		; jp Z, ret (no error)
	ldw hl, 65535			; HL = 0xFFFF (error)
	ret

	; --- HD config initialization (start — continues in next block) ---
	; Write all 323 sectors from RAM to HD, with retry
.Lhciv_hd_config_init:			; 0x297A8D
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	sti8_24 0x229d93, 0x07                 ; (0x229D93) = 7 — retry counter
.Lhciv_config_restart:			; 0x297A9A
	ld32_24 xwa, 0x229c64                 ; XWA = (0x229C64) — HD base sector
	st32_24 0x229c74, xwa                 ; (0x229C74) = current sector
	ld xwa, 2102834		; 0x201632 — RAM buffer base
	st32_24 0x229c78, xwa                 ; (0x229C78) = buffer ptr
	xor xwa, xwa
	st32_24 0x229c7c, xwa                 ; (0x229C7C) = sector counter = 0
.Lhciv_write_loop:			; 0x297AB5
	ld xwa, 323			; 0x143 — total sectors
	cpdm32_24 2268284, xwa		; cp (0x229C7C), XWA — counter == 323?
	jp_24 z, 2718473		; jp Z, verify phase (0x297B09 in next block)
	ld32_24 xhl, 0x229c74                 ; XHL = (0x229C74) — current sector
	ld32_24 xix, 0x229c78                 ; XIX = (0x229C78) — current buffer ptr
	call 2717339			; call 0x29769B — write sector to HD
	; Function continues in next block (HD_Detect_Drive)

HDAE5000_HD_Detect_Drive:	; 0x297AD2 (836 bytes)
	; HD config write+verify (continuation), read+verify, sector counting

	; --- Write phase continuation (from .Lhciv_hd_config_init in prev block) ---
	; After calling write sector, check error and increment counters
	cpi8_24 0x200222, 0x00                 ; cp (0x200222), 0 — error?
	jp_24 nz, 2718639		; jp NZ, .Lhdd_error1
	ld32_24 xwa, 0x229c74                 ; XWA = (0x229C74) sector++
	inc 1, xwa
	st32_24 0x229c74, xwa
	ld32_24 xwa, 0x229c7c                 ; XWA = (0x229C7C) counter++
	inc 1, xwa
	st32_24 0x229c7c, xwa
	ld32_24 xwa, 0x229c78                 ; XWA = (0x229C78) buffer += 512
	add xwa, 512
	st32_24 0x229c78, xwa
	jp .Lhciv_write_loop		; loop back to write phase

	; --- Verify phase: read back each sector, compare with RAM ---
.Lhdd_verify1:				; 0x297B09
	ld32_24 xwa, 0x229c64                 ; base sector → (0x229C74)
	st32_24 0x229c74, xwa
	ld xwa, 2102834		; 0x201632 → (0x229C78)
	st32_24 0x229c78, xwa
	xor xwa, xwa
	st32_24 0x229c7c, xwa                 ; counter = 0
.Lhdd_verify_loop1:			; 0x297B24
	ld xwa, 323
	cpdm32_24 2268284, xwa		; counter == 323?
	jp_24 z, 2718631		; jp Z, .Lhdd_success1
	ld32_24 xhl, 0x229c74                 ; XHL = current sector
	ld xde, 512			; 512 bytes
	ld xix, 2097704			; 0x200228 read buffer
	call 2717576			; read sector to buffer
	cpi8_24 0x200222, 0x00                 ; error check
	jp_24 nz, 2718639		; jp NZ, .Lhdd_error1
	ld32_24 xix, 0x229c78                 ; XIX = RAM buffer ptr
	ld xiy, 2097704			; XIY = read buffer
	lds bc, 0
.Lhdd_compare_loop1:			; 0x297B5D
	cp bc, 512			; compared all 512 bytes?
	jp_24 z, 2718587		; jp Z, .Lhdd_verify_next1
	ld_sril3 xwa, 0x07, 0xF0, 0xE4	; XWA = (XIX+BC)
	cp_sril_rm xwa, 0x07, 0xF4, 0xE4	; cp XWA, (XIY+BC)
	jp_24 nz, 2718639		; jp NZ, .Lhdd_error1
	inc 4, bc			; 4 bytes at a time
	jp .Lhdd_compare_loop1
.Lhdd_verify_next1:			; 0x297B7B
	ld32_24 xwa, 0x229c74                 ; sector++
	inc 1, xwa
	st32_24 0x229c74, xwa
	ld32_24 xwa, 0x229c7c                 ; counter++
	inc 1, xwa
	st32_24 0x229c7c, xwa
	ld32_24 xwa, 0x229c78                 ; buffer += 512
	add xwa, 512
	st32_24 0x229c78, xwa
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
	cpi8_24 0x229d93, 0x00                 ; (0x229D93) retry == 0?
	jp_24 z, 2718659		; jp Z, .Lhdd_final_error1
	decdi8_24 1, 2268563		; retry--
	jp .Lhciv_config_restart	; restart from scratch
.Lhdd_final_error1:			; 0x297BC3
	sti8_24 0x200222, 0x01                 ; (0x200222) = 1 error flag
	xor xwa, xwa
	st32_24 0x229c80, xwa                 ; clear (0x229C80)
	jp .Lhdd_success1		; clean up and return

	; === HD Config Read+Verify Wrapper ===
	; Calls config init 2, returns HL = 0 (ok) or 0xFFFF (error)
.Lhdd_wrapper2:				; 0x297BD4
	call .Lhdd_config_init2
	xor hl, hl
	cpi8_24 0x200222, 0x00                 ; error?
	jp_24 z, 2718696		; jp Z, .Lhdd_wrapper2_ret
	ldw hl, 65535
.Lhdd_wrapper2_ret:			; 0x297BE8
	ret

	; === HD Config Init 2: Read all sectors, then verify by re-reading ===
.Lhdd_config_init2:			; 0x297BE9
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	sti8_24 0x229d93, 0x07                 ; retry = 7
.Lhdd_restart2:				; 0x297BF6
	ld32_24 xwa, 0x229c64                 ; base sector
	st32_24 0x229c74, xwa
	ld xwa, 2102834
	st32_24 0x229c78, xwa                 ; buffer = 0x201632
	xor xwa, xwa
	st32_24 0x229c7c, xwa                 ; counter = 0
	; Read phase: read each of 323 sectors into RAM
.Lhdd_read_loop2:			; 0x297C11
	ld xwa, 323
	cpdm32_24 2268284, xwa		; counter == 323?
	jp_24 z, 2718826		; jp Z, .Lhdd_verify_start2
	ld xde, 512
	ld32_24 xhl, 0x229c74                 ; current sector
	ld32_24 xix, 0x229c78                 ; current buffer ptr
	call 2717576			; read sector
	cpi8_24 0x200222, 0x00
	jp_24 nz, 2718992		; jp NZ, .Lhdd_error2
	ld32_24 xwa, 0x229c7c                 ; counter++
	inc 1, xwa
	st32_24 0x229c7c, xwa
	ld32_24 xwa, 0x229c74                 ; sector++
	inc 1, xwa
	st32_24 0x229c74, xwa
	ld32_24 xwa, 0x229c78                 ; buffer += 512
	add xwa, 512
	st32_24 0x229c78, xwa
	jp .Lhdd_read_loop2
	; Verify phase: re-read each sector, compare with RAM copy
.Lhdd_verify_start2:			; 0x297C6A
	ld32_24 xwa, 0x229c64
	st32_24 0x229c74, xwa
	ld xwa, 2102834
	st32_24 0x229c78, xwa
	xor xwa, xwa
	st32_24 0x229c7c, xwa
.Lhdd_verify_loop2:			; 0x297C85
	ld xwa, 323
	cpdm32_24 2268284, xwa
	jp_24 z, 2718984		; jp Z, .Lhdd_success2
	ld32_24 xhl, 0x229c74
	ld xde, 512
	ld xix, 2097704			; read into 0x200228
	call 2717576
	cpi8_24 0x200222, 0x00
	jp_24 nz, 2718992		; jp NZ, .Lhdd_error2
	ld32_24 xix, 0x229c78                 ; RAM buffer
	ld xiy, 2097704			; read buffer
	lds bc, 0
.Lhdd_compare_loop2:			; 0x297CBE
	cp bc, 512
	jp_24 z, 2718940		; jp Z, .Lhdd_verify_next2
	ld_sril3 xwa, 0x07, 0xF0, 0xE4	; XWA = (XIX+BC)
	cp_sril_rm xwa, 0x07, 0xF4, 0xE4	; cp XWA, (XIY+BC)
	jp_24 nz, 2718992		; jp NZ, .Lhdd_error2
	inc 4, bc
	jp .Lhdd_compare_loop2
.Lhdd_verify_next2:			; 0x297CDC
	ld32_24 xwa, 0x229c74
	inc 1, xwa
	st32_24 0x229c74, xwa
	ld32_24 xwa, 0x229c7c
	inc 1, xwa
	st32_24 0x229c7c, xwa
	ld32_24 xwa, 0x229c78
	add xwa, 512
	st32_24 0x229c78, xwa
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
	cpi8_24 0x229d93, 0x00
	jp_24 z, 2719012		; jp Z, .Lhdd_final_error2
	decdi8_24 1, 2268563
	jp .Lhdd_restart2
.Lhdd_final_error2:			; 0x297D24
	sti8_24 0x200222, 0x01
	xor xwa, xwa
	st32_24 0x229c80, xwa
	jp .Lhdd_success2

	; === HD Count Used Sectors Wrapper ===
	; Returns XHL = count of used sectors (or 0 on error)
.Lhdd_wrapper3:				; 0x297D35
	call .Lhdd_count_sectors
	ld32_24 xhl, 0x229c80                 ; XHL = (0x229C80) used count
	cpi8_24 0x200222, 0x00
	jr z, .Lhdd_wrapper3_ret
	xor xhl, xhl			; error → return 0
.Lhdd_wrapper3_ret:			; 0x297D48
	ret

	; === Count Used Sectors ===
	; Reads each sector, counts those with non-zero 32-bit words
.Lhdd_count_sectors:			; 0x297D49
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	sti8_24 0x229d93, 0x05                 ; retry = 5
.Lhdd_restart3:				; 0x297D56
	xor xwa, xwa
	st32_24 0x229c80, xwa                 ; used count = 0
	ld32_24 xwa, 0x229c68                 ; base sector from (0x229C68)
	st32_24 0x229c84, xwa                 ; → (0x229C84) current sector
	xor xwa, xwa
	st32_24 0x229c88, xwa                 ; (0x229C88) = 0 counter
.Lhdd_outer3:				; 0x297D6E
	ld32_24 xwa, 0x229c70                 ; total sectors (0x229C70)
	cpdm32_24 2268296, xwa		; counter >= total?
	jp_24 nc, 2719209		; jp NC, .Lhdd_success3
	ld xde, 512
	ld32_24 xhl, 0x229c84                 ; current sector
	lda_24 xix, 0x200228                  ; XIX = &0x200228
	call 2717576			; read sector
	cpi8_24 0x200222, 0x00
	jp_24 nz, 2719217		; jp NZ, .Lhdd_error3
	lda_24 xix, 0x200228
	lds bc, 0
.Lhdd_inner3:				; 0x297DA2
	cp bc, 512			; scanned all bytes?
	jp_24 z, 2719193		; jp Z, .Lhdd_next_sector3
	ld32_24 xwa, 0x229c88                 ; increment scan counter
	inc 1, xwa
	st32_24 0x229c88, xwa
	ld_sril3 xwa, 0x07, 0xF0, 0xE4	; XWA = (XIX+BC)
	inc 4, bc
	cp xwa, 0			; is this 32-bit word zero?
	jp_24 nz, 2719138		; jp NZ, .Lhdd_inner3 (non-zero, keep scanning)
	ld32_24 xwa, 0x229c80                 ; used count++
	inc 1, xwa
	st32_24 0x229c80, xwa
	jp .Lhdd_inner3			; continue scanning
.Lhdd_next_sector3:			; 0x297DD9
	ld32_24 xwa, 0x229c84                 ; sector++
	inc 1, xwa
	st32_24 0x229c84, xwa
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
	cpi8_24 0x229d93, 0x00
	jp_24 z, 2719237		; jp Z, .Lhdd_final_error3
	decdi8_24 1, 2268563
	jp .Lhdd_restart3
.Lhdd_final_error3:			; 0x297E05
	sti8_24 0x200222, 0x01
	xor xwa, xwa
	st32_24 0x229c80, xwa
	jp .Lhdd_success3

HDAE5000_Display_Copy:	; 0x297E16 (443 bytes)
	; Copy HD sectors into display buffer, tracking allocation

	; --- Wrapper: save params, call main, return status in HL ---
	push xiz
	ldw hl, 65535			; assume error
	cpi8_24 0x200222, 0x00                 ; HD error flag set?
	jp_24 nz, 2719304		; jp NZ, .Ldc_exit
	st32_24 0x229d40, xwa                 ; save XWA → (0x229D40)
	st32_24 0x229d38, xbc                 ; save XBC → (0x229D38) = total bytes
	st32_24 0x229d2c, xde                 ; save XDE → (0x229D2C) = entry list ptr
	call .Ldc_main
	xor hl, hl			; assume success
	cpi8_24 0x200222, 0x00
	jp_24 z, 2719304		; jp Z, .Ldc_exit
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
	ld32_24 xwa, 0x229d38                 ; total bytes
	ld32_24 xbc, 0x229c58                 ; sector size (0x229C58)
	call HDAE5000_HD_Config_Init_Values	; divide XWA/XBC
	cp xbc, 0			; remainder?
	jp_24 z, 2719344		; jp Z, no round-up
	inc 1, xwa			; round up
.Ldc_no_roundup:			; 0x297E70
	st32_24 0x229c98, xwa                 ; sector count → (0x229C98)
	sti8_24 0x229dbc, 0x00                 ; (0x229DBC) = 0 — boundary flag
	; Check first entry in list
	ld32_24 xix, 0x229d2c                 ; XIX = entry list ptr
	ld xwa, (xix)			; first entry
	cp xwa, 4294967295		; == 0xFFFFFFFF? (empty)
	jp_24 z, 2719382		; jp Z, skip store
	st32_24 0x229cb8, xwa                 ; → (0x229CB8) start sector
	call 2721178			; call 0x29859A
.Ldc_skip_first:			; 0x297E96
	; Initialize config registers
	ld32_24 xwa, 0x229c68                 ; base sector (0x229C68)
	st32_24 0x229cb4, xwa                 ; → (0x229CB4)
	xor xwa, xwa
	st32_24 0x229cb0, xwa                 ; (0x229CB0) = 0
	ld xwa, 512
	st32_24 0x229cac, xwa                 ; (0x229CAC) = 512 sector size
	ld xwa, 4294967295
	st32_24 0x229d28, xwa                 ; (0x229D28) = 0xFFFFFFFF
	xor xwa, xwa
	st32_24 0x229ca4, xwa                 ; (0x229CA4) = 0 iteration counter
	sti8_24 0x229d94, 0x00                 ; (0x229D94) = 0 — first-sector flag
	sti8_24 0x229d95, 0x00                 ; (0x229D95) = 0 — first-alloc flag
	sti8_24 0x229d96, 0x00                 ; (0x229D96) = 0
	; Main allocation loop
.Ldc_loop:				; 0x297ED4
	call 2720323			; call 0x298243 — find next free sector
	ld32_24 xwa, 0x229ca8                 ; result (0x229CA8)
	cp xwa, 4294967293		; == 0xFFFFFFFD? (disk full)
	jp_24 nz, 2719474		; jp NZ, .Ldc_not_full
	sti8_24 0x229dbc, 0x01                 ; boundary flag = 1
	jp .Ldc_cleanup			; done
.Ldc_not_full:				; 0x297EF2
	ld32_24 xwa, 0x229ca8                 ; re-load result
	cpi8_24 0x229d94, 0x00                 ; first-sector flag?
	jp_24 nz, 2719504		; jp NZ, .Ldc_not_first
	st32_24 0x229c9c, xwa                 ; (0x229C9C) = first result
	st32_24 0x229ca0, xwa                 ; (0x229CA0) = current result
	jp .Ldc_after_first		; skip
.Ldc_not_first:				; 0x297F10
	st32_24 0x229ca0, xwa                 ; (0x229CA0) = current result
.Ldc_after_first:			; 0x297F15
	call 2720539			; call 0x29831B — allocate sector
	cpi8_24 0x229d97, 0x00                 ; (0x229D97) alloc error?
	jp_24 z, 2719542		; jp Z, .Ldc_alloc_ok
	; Alloc failed — mark as end, retry
	ld xwa, 4294967295
	st32_24 0x229ca0, xwa                 ; (0x229CA0) = 0xFFFFFFFF
	call 2720682			; call 0x2983AA — commit
	jp .Ldc_loop
.Ldc_alloc_ok:				; 0x297F36
	cpi8_24 0x229d95, 0x00                 ; first-alloc flag?
	jp_24 nz, 2719571		; jp NZ, .Ldc_after_alloc
	sti8_24 0x229d95, 0x01                 ; set first-alloc flag
	ld32_24 xwa, 0x229ca8                 ; store to entry list
	ld32_24 xix, 0x229d2c
	ld (xix), xwa
.Ldc_after_alloc:			; 0x297F53
	ld32_24 xwa, 0x229ca4                 ; iteration++
	inc 1, xwa
	st32_24 0x229ca4, xwa
	cpda32_24 xwa, 2268312		; == sector count?
	jp_24 z, 2719632		; jp Z, .Ldc_all_done
	cpi8_24 0x229d94, 0x00                 ; first-sector flag?
	jp_24 nz, 2719614		; jp NZ, .Ldc_mid_sector
	sti8_24 0x229d94, 0x01                 ; set first-sector flag
	jp .Ldc_loop
.Ldc_mid_sector:			; 0x297F7E
	call 2720682			; commit current sector
	ld32_24 xwa, 0x229ca0                 ; current → (0x229C9C)
	st32_24 0x229c9c, xwa
	jp .Ldc_loop
.Ldc_all_done:				; 0x297F90
	call 2720682			; commit final sector
	ld32_24 xwa, 0x229ca0
	st32_24 0x229c9c, xwa
	ld xwa, 4294967294		; 0xFFFFFFFE = end marker
	st32_24 0x229ca0, xwa
	call 2720682			; commit end marker
	; Adjust used sector count
	ld32_24 xwa, 0x229c80                 ; (0x229C80) used count
	ld32_24 xbc, 0x229c98                 ; sector count
	sub xwa, xbc			; used -= allocated
	st32_24 0x229c80, xwa
	jp_24 ge, 2719689		; jp GE, .Ldc_cleanup (no underflow)
	xor xwa, xwa			; clamp to 0
	st32_24 0x229c80, xwa
.Ldc_cleanup:				; 0x297FC9
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

HDAE5000_Display_Restore:	; 0x297FD1 (9217 bytes)
	; Display restore/update operation
; LDR: 0x297FD1 (1617 bytes)

	push xiz
	ldw	hl, 0xffff
	cpi8_24	0x200222, 0
	jp_24	nz, 0x298003
	ld	(0x229d40), xwa
	ld	(0x229d38), xbc
	ld	(0x229d2c), xde
	call 0x298005
	xor	hl, hl
	cpi8_24	0x200222, 0
	jp_24	z, 0x298003
	ldw	hl, 0xffff
	pop xiz                                 ; pop XIZ
	ret

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
	ld	xbc, (0x229c58)
	call HDAE5000_HD_Config_Init_Values
	cp	xbc, 0x00000000
	jp_24	z, 0x29802B
	inc 1, xwa                              ; inc 1,XWA
	ld	(0x229c98), xwa
	sti8_24	0x229DBC, 0
	ld	xix, (0x229d2c)
	ld xwa, (xix)                           ; ld XWA,(XIX)
	cp	xwa, 0xffffffff
	jp_24	z, 0x298114
	xor	xwa, xwa
	ld	(0x229ca4), xwa
	sti8_24	0x229D94, 0
	call 0x298243
	ld	xwa, (0x229ca8)
	cp	xwa, 0xfffffffd
	jp_24	nz, 0x298073
	sti8_24	0x229DBC, 1
	jp 0x298114                             ; jp 0x298114
	ld	xwa, (0x229ca8)
	ld	(0x229ca0), xwa
	call 0x29831b
	cpi8_24	0x229D97, 0
	jp_24	z, 0x29809E
	ld	xwa, 0xffffffff
	ld	(0x229ca0), xwa
	call 0x2983aa
	jp 0x298055                             ; jp 0x298055
	ld	xwa, (0x229ca4)
	inc 1, xwa                              ; inc 1,XWA
	ld	(0x229ca4), xwa
	cp	xwa, (0x229c98)
	jp_24	z, 0x2980DB
	cpi8_24	0x229D94, 0
	jp_24	nz, 0x2980C9
	sti8_24	0x229D94, 1
	jp 0x298055                             ; jp 0x298055
	call 0x2983aa
	ld	xwa, (0x229ca0)
	ld	(0x229c9c), xwa
	jp 0x298055                             ; jp 0x298055
	call 0x2983aa
	ld	xwa, (0x229ca0)
	ld	(0x229c9c), xwa
	ld	xwa, 0xfffffffe
	ld	(0x229ca0), xwa
	call 0x2983aa
	ld	xwa, (0x229c80)
	ld	xbc, (0x229c98)
	sub	xwa, xbc
	ld	(0x229c80), xwa
	jp_24	ge, 0x298114
	xor	xwa, xwa
	ld	(0x229c80), xwa
	pop xiz                                 ; pop XIZ
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	pop xhl                                 ; pop XHL
	pop xde                                 ; pop XDE
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

	push xiz
	ldw	hl, 0xffff
	cpi8_24	0x200222, 0
	jp_24	nz, 0x29814E
	ld	(0x229d40), xwa
	ld	(0x229d38), xbc
	ld	(0x229d2c), xde
	call 0x298150
	xor	hl, hl
	cpi8_24	0x200222, 0
	jp_24	z, 0x29814E
	ldw	hl, 0xffff
	pop xiz                                 ; pop XIZ
	ret

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
	jp_24	z, 0x2981B8
	ld	xwa, (0x229d30)
	cp	xwa, 0xfffffffe
	jp_24	nz, 0x29818C
	jp 0x2981b8                             ; jp 0x2981b8
	call 0x298465
	cpi8_24	0x229DBE, 0
	jp_24	z, 0x2981A5
	sti8_24	0x200222, 1
	jp 0x2981b8                             ; jp 0x2981b8
	cpi8_24	0x229DBF, 1
	jp_24	z, 0x2981B8
	call 0x298541
	jp 0x298178                             ; jp 0x298178
	pop xiz                                 ; pop XIZ
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	pop xhl                                 ; pop XHL
	pop xde                                 ; pop XDE
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

	push xiz
	ldw	hl, 0xffff
	cpi8_24	0x200222, 0
	jp_24	nz, 0x2981F2
	ld	(0x229d40), xwa
	ld	(0x229d38), xbc
	ld	(0x229d2c), xde
	call 0x2981f4
	xor	hl, hl
	cpi8_24	0x200222, 0
	jp_24	z, 0x2981F2
	ldw	hl, 0xffff
	pop xiz                                 ; pop XIZ
	ret

	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	ld	xwa, (0x229d30)
	cp	xwa, 0xfffffffe
	jp_24	nz, 0x29820F
	jp 0x29823b                             ; jp 0x29823b
	call 0x29846c
	cpi8_24	0x229DBE, 0
	jp_24	z, 0x298228
	sti8_24	0x200222, 1
	jp 0x29823b                             ; jp 0x29823b
	cpi8_24	0x229DBF, 1
	jp_24	z, 0x29823B
	call 0x298541
	jp 0x2981fb                             ; jp 0x2981fb
	pop xiz                                 ; pop XIZ
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	pop xhl                                 ; pop XHL
	pop xde                                 ; pop XDE
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

	ld	xwa, 0x00000200
	cp	(0x229cac), xwa
	jp_24	nz, 0x2982B7
	xor	xwa, xwa
	ld	(0x229cac), xwa
	ld8_24	a, 0x229D96
	addm32_24	0x229CB0, xwa
	addm32_24	0x229CB4, xwa
	sti8_24	0x229D96, 1
	ld	xwa, (0x229c70)
	cp	(0x229cb0), xwa
	jp_24	nz, 0x29828B
	ld	xwa, 0xfffffffd
	ld	(0x229ca8), xwa
	jp 0x29831a                             ; jp 0x29831a
	ld	xhl, (0x229cb4)
	ld	xde, 0x00000200
	lda_24 xix, 0x200898
	call 0x297788
	cpi8_24	0x200222, 0
	jp_24	z, 0x2982B7
	ld	xwa, 0xfffffffd
	ld	(0x229ca8), xwa
	jp 0x29831a                             ; jp 0x29831a
	lda_24 xix, 0x200898
	ld	xbc, (0x229cac)
	add	xix, xbc
	ld xwa, (xix)                           ; ld XWA,(XIX)
	cp	xwa, 0x00000000
	jp_24	z, 0x2982E4
	ld	xwa, (0x229cac)
	add	xwa, 0x00000004
	ld	(0x229cac), xwa
	jp 0x298243                             ; jp 0x298243
	ld	xwa, (0x229cb0)
	ld	xbc, 0x00000080
	call HDAE5000_HD_Init_Variables
	push xwa
	ld	xwa, (0x229cac)
	lds32	xbc, 4
	call HDAE5000_HD_Config_Init_Values
	ld	xbc, xwa
	pop xwa                                 ; pop XWA
	add	xwa, xbc
	inc 1, xwa                              ; inc 1,XWA
	ld	(0x229ca8), xwa
	ld	xwa, (0x229cac)
	add	xwa, 0x00000004
	ld	(0x229cac), xwa
	ret

	sti8_24	0x229D97, 0
	xor	xwa, xwa
	ld	(0x229cc0), xwa
	ld	xwa, (0x229d40)
	ld	(0x229cbc), xwa
	ld	xwa, (0x229c5c)
	cp	(0x229cc0), xwa
	jp_24	z, 0x2983A9
	ld	xwa, (0x229ca8)
	dec	1, xwa
	ld	xbc, (0x229c5c)
	call HDAE5000_HD_Init_Variables
	ld	xbc, (0x229c6c)
	add	xwa, xbc
	ld	xbc, (0x229cc0)
	add	xwa, xbc
	ld	xhl, xwa
	ld	xix, (0x229d40)
	call 0x29769b
	cpi8_24	0x200222, 0
	jp_24	z, 0x298389
	sti8_24	0x229D97, 1
	ld	xwa, (0x229cbc)
	ld	(0x229d40), xwa
	jp 0x2983a9                             ; jp 0x2983a9
	ld	xwa, (0x229cc0)
	inc 1, xwa                              ; inc 1,XWA
	ld	(0x229cc0), xwa
	ld	xwa, (0x229d40)
	add	xwa, 0x00000200
	ld	(0x229d40), xwa
	jp 0x298332                             ; jp 0x298332
	ret

	ld	xwa, (0x229c9c)
	dec	1, xwa
	ld	xbc, 0x00000080
	call HDAE5000_HD_Config_Init_Values
	push xwa
	lds32	xwa, 4
	call HDAE5000_HD_Init_Variables
	ld	xbc, xwa
	pop xwa                                 ; pop XWA
	ld	(0x229d48), xwa
	ld	(0x229d4c), xbc
	ld	xwa, (0x229d28)
	cp	xwa, 0xffffffff
	jp_24	nz, 0x2983E6
	call 0x29842a
	jp 0x2983f7                             ; jp 0x2983f7
	ld	xwa, (0x229d48)
	ld	xbc, (0x229d28)
	cp	xwa, xbc
	jp_24	nz, 0x29841D
	lda_24 xix, 0x200a98
	ld	xbc, (0x229d4c)
	add	xix, xbc
	ld	xwa, (0x229ca0)
	ld (xix), xwa                           ; ld (XIX),XWA
	cp	xwa, 0xfffffffe
	jp_24	nz, 0x298429
	call 0x29844f
	jp 0x298429                             ; jp 0x298429
	call 0x29844f
	call 0x29842a
	jp 0x2983f7                             ; jp 0x2983f7
	ret

	ld	xhl, (0x229c68)
	ld	xwa, (0x229d48)
	add	xhl, xwa
	ld	xde, 0x00000200
	lda_24 xix, 0x200a98
	call 0x297788
	ld	xwa, (0x229d48)
	ld	(0x229d28), xwa
	ret

	ld	xhl, (0x229c68)
	ld	xwa, (0x229d28)
	add	xhl, xwa
	lda_24 xix, 0x200a98
	call 0x29769b
	ret

	lds32	xwa, 0
	ld	(0x229d34), xwa
	sti8_24	0x229DBF, 0
	sti8_24	0x229DBE, 0
	ld	xwa, (0x229d34)
	cp	xwa, (0x229c5c)
	jp_24	nz, 0x298492
	lds32	xwa, 0
	ld	(0x229d34), xwa
	jp 0x298540                             ; jp 0x298540
	ld	xwa, (0x229d30)
	dec	1, xwa
	ld	xbc, (0x229c5c)
	call HDAE5000_HD_Init_Variables
	ld	xbc, (0x229c6c)
	add	xwa, xbc
	ld	xbc, (0x229d34)
	add	xwa, xbc
	ld	xhl, xwa
	ld	xwa, (0x229d38)
	cp	xwa, 0x00000200
	jp_24	nc, 0x2984D6
	ld	xwa, (0x229d38)
	ld	(0x229d3c), xwa
	sti8_24	0x229DBF, 1
	jp 0x2984e0                             ; jp 0x2984e0
	ld	xwa, 0x00000200
	ld	(0x229d3c), xwa
	ld	xix, (0x229d40)
	ld	xde, (0x229d3c)
	call 0x297788
	cpi8_24	0x200222, 0
	jp_24	z, 0x298503
	sti8_24	0x229DBE, 1
	jp 0x298540                             ; jp 0x298540
	cpi8_24	0x229DBF, 1
	jp_24	z, 0x298540
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
	jp 0x298478                             ; jp 0x298478
	ret

	ld	xwa, (0x229d30)
	dec	1, xwa
	ld	xbc, 0x00000080
	call HDAE5000_HD_Config_Init_Values
	ld	(0x229d48), xwa
	lds32	xwa, 4
	call HDAE5000_HD_Init_Variables
	ld	(0x229d4c), xwa
	ld	xwa, (0x229d48)
	cp	xwa, (0x229d28)
	jp_24	nz, 0x298587
	lda_24 xix, 0x200a98
	ld	xwa, (0x229d4c)
	add	xix, xwa
	ld xwa, (xix)                           ; ld XWA,(XIX)
	ld	(0x229d30), xwa
	jp 0x29858f                             ; jp 0x29858f
	call 0x29842a
	jp 0x298570                             ; jp 0x298570
	ret

	ld	(0x229cb8), xwa
	call 0x29859a
	ret

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
	call 0x298541
	ld	xwa, (0x229d30)
	cp	xwa, 0x00000000
	jp_24	z, 0x29861A
	lda_24 xix, 0x200a98
	ld	xbc, (0x229d4c)
	add	xix, xbc
	xor	xwa, xwa
	ld (xix), xwa                           ; ld (XIX),XWA
	ld	xwa, (0x229d24)
	inc 1, xwa                              ; inc 1,XWA
	ld	(0x229d24), xwa
	call 0x29844f
	ld	xwa, (0x229d30)
	cp	xwa, 0xfffffffe
	jp_24	nz, 0x2985C1
	call 0x29844f
	ld	xwa, (0x229c80)
	ld	xbc, (0x229d24)
	add	xwa, xbc
	ld	(0x229c80), xwa
	pop xiz                                 ; pop XIZ
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	pop xhl                                 ; pop XHL
	pop xde                                 ; pop XDE
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

HDAE5000_Display_String_Render:	; 0x298622 (cross-reference from Display_Init)
; LDSR: 0x298622 (7600 bytes)

	call 0x298638
	xor	hl, hl
	ld8_24	l, 0x200222
	pushw hl                                ; push HL
	call 0x2974c7
	call 0x298c15
	popw hl                                 ; pop HL
	ret

	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	call 0x297884
	cpi8_24	0x200222, 0
	jp_24	z, 0x298654
	ldb	a, 0x06
	jp 0x29888a                             ; jp 0x29888a
	call 0x2975ad
	call 0x29797f
	call 0x297a8d
	cpi8_24	0x200222, 0
	jp_24	z, 0x298675
	sti8_24	0x200222, 1
	jp 0x29888a                             ; jp 0x29888a
	lda_24 xix, 0x200228
	call 0x298896
	ld	xwa, (0x229c68)
	ld	(0x229c8c), xwa
	xor	xwa, xwa
	ld	(0x229c90), xwa
	ld	xwa, (0x229c90)
	cp	xwa, 0x00000f42
	jp_24	z, 0x2986E6
	ld	xhl, (0x229c8c)
	lda_24 xix, 0x200228
	call 0x29769b
	cpi8_24	0x200222, 0
	jp_24	z, 0x2986C2
	sti8_24	0x200222, 2
	jp 0x29888a                             ; jp 0x29888a
	ld	xwa, (0x229c8c)
	add	xwa, 0x00000001
	ld	(0x229c8c), xwa
	ld	xwa, (0x229c90)
	add	xwa, 0x00000001
	ld	(0x229c90), xwa
	jp 0x29868f                             ; jp 0x29868f
	ld	xwa, (0x229c68)
	ld	(0x229c8c), xwa
	xor	xwa, xwa
	ld	(0x229c90), xwa
	ld	xwa, (0x229c90)
	cp	xwa, 0x00000f42
	jp_24	z, 0x298784
	ld	xhl, (0x229c8c)
	ld	xde, 0x00000200
	lda_24 xix, 0x200428
	call 0x297788
	cpi8_24	0x200222, 0
	jp_24	z, 0x29872F
	sti8_24	0x200222, 3
	jp 0x29888a                             ; jp 0x29888a
	lda_24 xix, 0x200228
	lda_24 xiy, 0x200428
	lds	bc, 0
	cp	bc, 0x0200
	jp_24	z, 0x298760
	ld_sril3 xwa, 0x07, 0xF0, 0xE4	; ld XWA,(XIX+BC)
	cp_sril_rm xwa, 0x07, 0xF4, 0xE4	; cp XWA,(XIY+BC)
	jr z, .LDSR_875a                       ; [66 0a] jr Z,0x29875a
	sti8_24	0x200222, 4
	jp 0x29888a                             ; jp 0x29888a
.LDSR_875a:
	inc	4, bc
	jp 0x29873b                             ; jp 0x29873b
	ld	xwa, (0x229c8c)
	add	xwa, 0x00000001
	ld	(0x229c8c), xwa
	ld	xwa, (0x229c90)
	add	xwa, 0x00000001
	ld	(0x229c90), xwa
	jp 0x2986f7                             ; jp 0x2986f7
	call 0x2988af
	lds32	xhl, 1
	lda_24 xix, 0x200628
	call 0x29769b
	cpi8_24	0x200222, 0
	jp_24	z, 0x2987A8
	sti8_24	0x200222, 5
	jp 0x29888a                             ; jp 0x29888a
	call 0x29747a
	cpi8_24	0x200222, 0
	jp_24	z, 0x2987C1
	sti8_24	0x200222, 11
	jp 0x29888a                             ; jp 0x29888a
	call 0x297884
	cpi8_24	0x200222, 0
	jp_24	z, 0x2987DA
	sti8_24	0x200222, 6
	jp 0x29888a                             ; jp 0x29888a
	call 0x2975ad
	lds32	xhl, 1
	lda_24 xix, 0x200628
	ld	xde, 0x00000200
	call 0x297788
	cpi8_24	0x200222, 0
	jr z, .LDSR_8800                       ; [66 0a] jr Z,0x298800
	sti8_24	0x200222, 7
	jp 0x29888a                             ; jp 0x29888a
.LDSR_8800:
	call 0x29750f
	cpi8_24	0x229D98, 1
	jp_24	z, 0x298819
	sti8_24	0x200222, 8
	jp 0x29888a                             ; jp 0x29888a
	ld	xix, 0x002006a0
	ld	a, (xix)
	st8_24	0x229DA9, a
	inc 1, xix                              ; inc 1,XIX
	ld	a, (xix)
	st8_24	0x229DAA, a
	inc 1, xix                              ; inc 1,XIX
	ld	a, (xix)
	st8_24	0x229DAB, a
	inc 1, xix                              ; inc 1,XIX
	ld	a, (xix)
	st8_24	0x229DAC, a
	inc 1, xix                              ; inc 1,XIX
	ld	a, (xix)
	st8_24	0x229DAD, a
	inc 1, xix                              ; inc 1,XIX
	ld	a, (xix)
	st8_24	0x229DAE, a
	call 0x297d49
	cpi8_24	0x200222, 0
	cpi8_24	0x200222, 0
	jp_24	z, 0x298871
	sti8_24	0x200222, 9
	jp 0x29888a                             ; jp 0x29888a
	call 0x297be9
	cpi8_24	0x200222, 0
	jp_24	z, 0x29888A
	sti8_24	0x200222, 10
	jp 0x29888a                             ; jp 0x29888a
	call 0x2974c7
	pop xiz                                 ; pop XIZ
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	pop xhl                                 ; pop XHL
	pop xde                                 ; pop XDE
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

	ldb	a, 0x00
	xor	bc, bc
	cp	bc, 0x0200
	jp_24	z, 0x2988AE
	lda_dri3 xbc, 0x07, 0xF0, 0xE4	; ld (XIX+BC),A
	inc	1, bc
	jp 0x29889a                             ; jp 0x29889a
	ret

	lda_24 xix, 0x200628
	call 0x298896
	lda_24 xix, 0x200628
	ld	xwa, 0xaa55aa55
	ld (xix), xwa                           ; ld (XIX),XWA
	inc 4, xix                              ; inc 4,XIX
	ld	xwa, 0xf4f1f2f3
	ld (xix), xwa                           ; ld (XIX),XWA
	inc 4, xix                              ; inc 4,XIX
	lda_24 xiy, 0x2999b2
	lda_24 xiz, 0x299a22
	cp	xiy, xiz
	jp_24	z, 0x2988EC
	ld	a, (xiy)
	ld	(xix), a
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp 0x2988d9                             ; jp 0x2988d9
	ld	(xix), 0x01
	sti8_24	0x229DA9, 1
	inc 1, xix                              ; inc 1,XIX
	ld	(xix), 0x01
	sti8_24	0x229DAA, 1
	inc 1, xix                              ; inc 1,XIX
	ld	(xix), 0x01
	sti8_24	0x229DAB, 1
	inc 1, xix                              ; inc 1,XIX
	ld	(xix), 0x01
	sti8_24	0x229DAC, 1
	inc 1, xix                              ; inc 1,XIX
	ld	(xix), 0x01
	sti8_24	0x229DAD, 1
	inc 1, xix                              ; inc 1,XIX
	ld	(xix), 0x01
	sti8_24	0x229DAE, 1
	inc 1, xix                              ; inc 1,XIX
	ld	xwa, 0xffffffff
	ld (xix), xwa                           ; ld (XIX),XWA
	ret

	ld	xix, (0x229d80)
	lda_24 xiy, 0x201556
	lds	bc, 0
	cp	bc, 0x0040
	jp_24	z, 0x298964
	ld	a, (xix)
	cp	a, (xiy)
	jp_24	nz, 0x29895E
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	inc	1, bc
	jp 0x298942                             ; jp 0x298942
	ldb	a, 0x01
	jp 0x298966                             ; jp 0x298966
	ldb	a, 0x00
	ret

	push xix
	push xiy
	push xbc
	push xwa
	lds	bc, 0
	lda_24 xix, 0x200c98
	lda_24 xiy, 0x201538
	cp	bc, 0x001a
	jp_24	z, 0x29898E
	ld	a, (xiy)
	ld	(xix), a
	inc	1, bc
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp 0x298977                             ; jp 0x298977
	pop xwa                                 ; pop XWA
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	ld	xwa, 0x0000ffee
	ld	(0x229c60), xwa
	ret

	lds32	xbc, 0
	cp	xbc, 0x00000005
	jp_24	z, 0x2989DF
	lds32	xhl, 0
	cp	xhl, 0x0000001a
	jp_24	z, 0x2989D9
	ld_srib3 a, 0x07, 0xF4, 0xEC	; ld A,(XIY+HL)
	cp_srib_mr a, 0x07, 0xF0, 0xEC	; cp (XIX+HL),A
	jp_24	nz, 0x2989CD
	inc 1, xhl                              ; inc 1,XHL
	jp 0x2989ad                             ; jp 0x2989ad
	add	xix, 0x0000001a
	inc 1, xbc                              ; inc 1,XBC
	jp 0x2989a0                             ; jp 0x2989a0
	ldb	a, 0x01
	jp 0x2989e1                             ; jp 0x2989e1
	ldb	a, 0x00
	ret

	lds32	xbc, 0
	cp	xbc, 0x0000001a
	jp_24	z, 0x298A00
	cp_srib_im 0x07, 0xF0, 0xE4, 0x20	; cp (XIX+BC),0x20
	jp_24	nz, 0x298A06
	inc 1, xbc                              ; inc 1,XBC
	jp 0x2989e4                             ; jp 0x2989e4
	ldb	a, 0x01
	jp 0x298a08                             ; jp 0x298a08
	ldb	a, 0x00
	ret

	push xix
	push xbc
	push xwa
	xor	xwa, xwa
	ld8_24	a, 0x229D9E
	add	xix, xwa
	ld	c, (xix)
	lda_24 xix, 0x200c98
	xor	xwa, xwa
	ld8_24	a, 0x229D9D
	add	xix, xwa
	ld	(xix), c
	pop xwa                                 ; pop XWA
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

	push xix
	push xbc
	lda_24 xix, 0x200864
	lds	bc, 0
	cp	bc, 0x000c
	jp_24	z, 0x298A49
	stib_dri 0x07, 0xF0, 0xE4, 0x30	; ld (XIX+BC),0x30
	inc	1, bc
	jp 0x298a34                             ; jp 0x298a34
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

	push xix
	push xbc
	lda_24 xix, 0x200864
	lds	bc, 0
	cp	bc, 0x000c
	jp_24	z, 0x298A6A
	stib_dri 0x07, 0xF0, 0xE4, 0x20	; ld (XIX+BC),0x20
	inc	1, bc
	jp 0x298a55                             ; jp 0x298a55
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

	push xix
	push xbc
	lda_24 xix, 0x200870
	lds	bc, 0
	cp	bc, 0x0028
	jp_24	z, 0x298A8B
	stib_dri 0x07, 0xF0, 0xE4, 0x20	; ld (XIX+BC),0x20
	inc	1, bc
	jp 0x298a76                             ; jp 0x298a76
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xde
	push xbc
	call 0x298a2b
	lds32	xde, 0
	ld	xbc, 0x0000000a
	call HDAE5000_HD_Config_Init_Values
	push xbc
	inc 1, xde                              ; inc 1,XDE
	cp	xwa, 0x00000000
	jp_24	nz, 0x298A98
	lda_24 xix, 0x20086e
	sub	xix, xde
	lda_24 xiy, 0x2998d9
	pop xbc                                 ; pop XBC
	ld	qbc, 0
	add	xiy, xbc
	ld	a, (xiy)
	ld	(xix), a
	inc 1, xix                              ; inc 1,XIX
	dec	1, xde
	cp	xde, 0x00000000
	jp_24	nz, 0x298AB6
	pop xbc                                 ; pop XBC
	pop xde                                 ; pop XDE
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xde
	push xbc
	call 0x298a4c
	jp 0x298a96                             ; jp 0x298a96
	push xwa
	push xbc
	lds32	xwa, 6
	cp	xwa, 0x00000000
	jp_24	z, 0x298B0D
	lds32	xbc, 0
	cp	xbc, 0x00000fff
	jp_24	z, 0x298B07
	inc 1, xbc                              ; inc 1,XBC
	jp 0x298af6                             ; jp 0x298af6
	dec	1, xwa
	jp 0x298ae9                             ; jp 0x298ae9
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

	push xwa
	push xbc
	ld	xwa, 0x00000046
	cp	xwa, 0x00000000
	jp_24	z, 0x298B3B
	lds32	xbc, 0
	cp	xbc, 0x00000fff
	jp_24	z, 0x298B35
	inc 1, xbc                              ; inc 1,XBC
	jp 0x298b24                             ; jp 0x298b24
	dec	1, xwa
	jp 0x298b17                             ; jp 0x298b17
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

	push xwa
	push xbc
	ld	xwa, 0x00000025
	cp	xwa, 0x00000000
	jp_24	z, 0x298B69
	lds32	xbc, 0
	cp	xbc, 0x00000fff
	jp_24	z, 0x298B63
	inc 1, xbc                              ; inc 1,XBC
	jp 0x298b52                             ; jp 0x298b52
	dec	1, xwa
	jp 0x298b45                             ; jp 0x298b45
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

	push xiz
	call 0x298b92
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

	push xwa
	push xbc
	ld	xwa, (0x200223)
	ld	xbc, 0x00000200
	call HDAE5000_HD_Init_Variables
	ld	xbc, 0x00002710
	call HDAE5000_HD_Config_Init_Values
	ld	(0x229d18), xwa
	ld	xwa, (0x229c6c)
	dec	1, xwa
	add	xwa, 0x00000002
	ld	xbc, 0x00000200
	call HDAE5000_HD_Init_Variables
	ld	xbc, 0x00002710
	call HDAE5000_HD_Config_Init_Values
	ld	(0x229d1c), xwa
	ld	xwa, (0x229c5c)
	ld	xbc, 0x00000200
	call HDAE5000_HD_Init_Variables
	push xwa
	ld	xbc, (0x229c70)
	call HDAE5000_HD_Init_Variables
	ld	xbc, 0x00002710
	call HDAE5000_HD_Config_Init_Values
	ld	(0x229d10), xwa
	pop xwa                                 ; pop XWA
	ld	xbc, (0x229c80)
	call HDAE5000_HD_Init_Variables
	ld	xbc, 0x00002710
	call HDAE5000_HD_Config_Init_Values
	ld	(0x229d14), xwa
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

	sti8_24	0x229DAF, 0
	sti8_24	0x229DB0, 0
	sti8_24	0x229DB1, 0
	sti8_24	0x229DB2, 0
	sti8_24	0x229DB3, 0
	sti8_24	0x229DB4, 0
	sti8_24	0x229DB5, 0
	sti8_24	0x229DB6, 0
	sti8_24	0x229DB7, 0
	sti8_24	0x229DB8, 0
	ret

	push xbc
	push xix
	ldb	a, 0x00
	lds32	xbc, 0
	ld	xix, 0x00200c98
	cp	xbc, 0x0000001a
	jp_24	z, 0x298C7A
	cp	(xix), 0x20
	jp_24	nz, 0x298C78
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	jp 0x298c5d                             ; jp 0x298c5d
	ldb	a, 0x01
	pop xix                                 ; pop XIX
	pop xbc                                 ; pop XBC
	ret

	push xiz
	call 0x298c86
	ld	xhl, xwa
	pop xiz                                 ; pop XIZ
	ret

	ld	xbc, (0x229c58)
	call HDAE5000_HD_Config_Init_Values
	cp	xbc, 0x00000000
	jp_24	z, 0x298C9C
	inc 1, xwa                              ; inc 1,XWA
	ret

	push xwa
	push xbc
	push xix
	lda_24 xix, 0x299a4b
	ld xwa, (xix)                           ; ld XWA,(XIX)
	ld	xbc, (0x229c60)
	cp	xwa, xbc
	jp_24	z, 0x298CB8
	pop xix                                 ; pop XIX
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	pop xwa                                 ; pop XWA
	ret

	pop xix                                 ; pop XIX
	pop xbc                                 ; pop XBC
	pop xwa                                 ; pop XWA
	ret

	xor	xwa, xwa
	xor	xbc, xbc
	ld16_24	wa, 0x229C4E
	dec	1, wa
	ld	xbc, 0x000004c0
	call HDAE5000_HD_Init_Variables
	ld	xix, xwa
	xor	xwa, xwa
	ld16_24	wa, 0x229C50
	dec	1, wa
	ld	xbc, 0x0000004c
	call HDAE5000_HD_Init_Variables
	add	xix, xwa
	lda_24 xwa, 0x201db2
	add	xix, xwa
	ld	(0x229cf0), xix
	ret

	lda_24 xix, 0x201556
	lds	bc, 0
	cp	bc, 0x0020
	jp_24	z, 0x298D23
	ld xiy, (xix + 0x04)                    ; ld XIY,(XIX+0x04)
	cp	xiy, 0x00000000
	jp_24	nz, 0x298D17
	ld	xwa, xix
	jp 0x298d25                             ; jp 0x298d25
	add	xix, 0x00000008
	inc	1, bc
	jp 0x298cfa                             ; jp 0x298cfa
	lds32	xwa, 0
	ret

	sti8_24	0x229DC8, 0
	call 0x2991ad
	cp	a, 0x0f
	jp_24	c, 0x298D3C
	jp 0x298d44                             ; jp 0x298d44
	call 0x2991d5
	jp 0x298d8e                             ; jp 0x298d8e
	xor	xwa, xwa
	ld8_24	a, 0x229D9F
	ld	xbc, 0x00000018
	call HDAE5000_HD_Init_Variables
	ld	xix, xwa
	xor	xwa, xwa
	call 0x299487
	add	xwa, xix
	cp	xwa, 0x00000077
	jp_24	z, 0x298D8E
	call 0x299487
	cp	a, 0x17
	jp_24	c, 0x298D86
	incdi8_24	1, 0x229D9F
	call 0x2994c4
	call 0x299225
	jp 0x298d8e                             ; jp 0x298d8e
	call 0x29949a
	call 0x299225
	ret

	sti8_24	0x229DC8, 0
	call 0x299752
	cp	a, 0x1f
	jp_24	c, 0x298DA5
	jp 0x298dad                             ; jp 0x298dad
	call 0x2997a4
	jp 0x298e17                             ; jp 0x298e17
	xor	xwa, xwa
	ld8_24	a, 0x229DA0
	ld	xbc, 0x00000018
	call HDAE5000_HD_Init_Variables
	ld	xix, xwa
	xor	xwa, xwa
	call 0x29973f
	add	xwa, xix
	cp	xwa, 0x00000077
	jp_24	z, 0x298E17
	call 0x29973f
	cp	a, 0x17
	jp_24	c, 0x298DFF
	incdi8_24	1, 0x229DA0
	call 0x2997f4
	call 0x29981c
	call 0x2996b7
	ld	xbc, 0x00000010
	add	xwa, xbc
	ld	(0x229d7c), xwa
	jp 0x298e17                             ; jp 0x298e17
	call 0x29977a
	call 0x29981c
	call 0x2996b7
	ld	xbc, 0x00000010
	add	xwa, xbc
	ld	(0x229d7c), xwa
	ret

	lda_24 xix, 0x2257c2
	lds32	xiy, 0
	cp	xiy, 0x00000078
	jp_24	z, 0x298E61
	lds	bc, 0
	cp	bc, 0x0020
	jp_24	z, 0x298E55
	ld xwa, (xix + 0x04)                    ; ld XWA,(XIX+0x04)
	cp	xwa, (0x229cf0)
	jp_24	nz, 0x298E49
	xor	xwa, xwa
	ld (xix), xwa                           ; ld (XIX),XWA
	ld (xix + 0x04), xwa                    ; ld (XIX+0x04),XWA
	add	xix, 0x00000002
	inc	1, bc
	jp 0x298e2c                             ; jp 0x298e2c
	add	xix, 0x00000010
	inc 1, xiy                              ; inc 1,XIY
	jp 0x298e1f                             ; jp 0x298e1f
	ret

	ld	xix, (0x229c94)
	lda_24 xiy, 0x20158e
	cp	xix, xiy
	jp_24	z, 0x298E88
	ld xwa, (xix + 0x08)                    ; ld XWA,(XIX+0x08)
	ld (xix), xwa                           ; ld (XIX),XWA
	ld xwa, (xix + 0x0c)                    ; ld XWA,(XIX+0x0c)
	ld (xix + 0x04), xwa                    ; ld (XIX+0x04),XWA
	add	xix, 0x00000008
	jp 0x298e6c                             ; jp 0x298e6c
	xor	xwa, xwa
	lda_24 xix, 0x20158e
	ld (xix), xwa                           ; ld (XIX),XWA
	ld (xix + 0x04), xwa                    ; ld (XIX+0x04),XWA
	ret

	ld	xix, (0x229d84)
	add	xix, 0x00000002
	lda_24 xiy, 0x201596
	xor	xwa, xwa
	ld	(0x229d8c), xwa
	cp	xix, xiy
	jp_24	z, 0x298ED4
	ld xwa, (xix + 0x04)                    ; ld XWA,(XIX+0x04)
	cp	xwa, 0x00000000
	jp_24	z, 0x298ECA
	ld	(0x229d8c), xix
	jp 0x298ed4                             ; jp 0x298ed4
	add	xix, 0x00000002
	jp 0x298eac                             ; jp 0x298eac
	ret

	lda_24 xix, 0x201596
	sub	xix, 0x00000002
	ld	xiy, (0x229d84)
	xor	xwa, xwa
	ld	(0x229d88), xwa
	cp	xix, xiy
	jp_24	z, 0x298F14
	ld xwa, (xix + 0x04)                    ; ld XWA,(XIX+0x04)
	cp	xwa, 0x00000000
	jp_24	nz, 0x298F0A
	ld	(0x229d88), xix
	jp 0x298f14                             ; jp 0x298f14
	sub	xix, 0x00000002
	jp 0x298eec                             ; jp 0x298eec
	ret

	ld	xix, (0x229d88)
	ld	xiy, (0x229d84)
	cp	xix, xiy
	jp_24	z, 0x298F3B
	ld	xwa, (xix-8)
	ld (xix), xwa                           ; ld (XIX),XWA
	ld	xwa, (xix-4)
	ld (xix + 0x04), xwa                    ; ld (XIX+0x04),XWA
	sub	xix, 0x00000002
	jp 0x298f1f                             ; jp 0x298f1f
	xor	xwa, xwa
	ld	xix, (0x229d84)
	ld (xix), xwa                           ; ld (XIX),XWA
	ld (xix + 0x04), xwa                    ; ld (XIX+0x04),XWA
	ret

	push xix
	push xiy
	push xbc
	push xwa
	lds32	xbc, 0
	ld	xix, (0x229cf0)
	lda_24 xiy, 0x200c98
	cp	xbc, 0x0000001a
	jp_24	z, 0x298F71
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp 0x298f58                             ; jp 0x298f58
	pop xwa                                 ; pop XWA
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	push xwa
	lds32	xbc, 0
	ld	xix, (0x229cf0)
	lda_24 xiy, 0x200c98
	cp	xbc, 0x0000001a
	jp_24	z, 0x298F9F
	ld	a, (xiy)
	ld	(xix), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp 0x298f86                             ; jp 0x298f86
	pop xwa                                 ; pop XWA
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	call 0x298c52
	cps	a, 0
	jp_24	z, 0x299014
	lda_24 xix, 0x201434
	lda_24 xiy, 0x200c98
	call 0x29899e
	cps	a, 1
	jp_24	z, 0x299014
	cpi8_24	0x229DC3, 5
	jp_24	c, 0x298FD8
	sti8_24	0x229DC3, 0
	lda_24 xix, 0x201434
	xor	xwa, xwa
	ld8_24	a, 0x229DC3
	ld	xbc, 0x0000001a
	call HDAE5000_HD_Init_Variables
	add	xix, xwa
	lda_24 xiy, 0x200c98
	lds32	xbc, 0
	cp	xbc, 0x0000001a
	jp_24	z, 0x29900F
	ld	a, (xiy)
	ld	(xix), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp 0x298ff6                             ; jp 0x298ff6
	incdi8_24	1, 0x229DC3
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	lda_24 xix, 0x201434
	ld	xiy, (0x229cf0)
	call 0x29899e
	cps	a, 1
	jp_24	z, 0x29907D
	cpi8_24	0x229DC3, 5
	jp_24	c, 0x299041
	sti8_24	0x229DC3, 0
	lda_24 xix, 0x201434
	xor	xwa, xwa
	ld8_24	a, 0x229DC3
	ld	xbc, 0x0000001a
	call HDAE5000_HD_Init_Variables
	add	xix, xwa
	ld	xiy, (0x229cf0)
	lds32	xbc, 0
	cp	xbc, 0x0000001a
	jp_24	z, 0x299078
	ld	a, (xiy)
	ld	(xix), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp 0x29905f                             ; jp 0x29905f
	incdi8_24	1, 0x229DC3
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	cpi8_24	0x229DC6, 5
	jp_24	c, 0x299095
	sti8_24	0x229DC6, 0
	lda_24 xix, 0x201434
	xor	xwa, xwa
	ld8_24	a, 0x229DC6
	ld	xbc, 0x0000001a
	call HDAE5000_HD_Init_Variables
	add	xix, xwa
	push xix
	call 0x2989e2
	pop xix                                 ; pop XIX
	cps	a, 1
	jp_24	nz, 0x2990C3
	sti8_24	0x229DC6, 0
	jp 0x2990e8                             ; jp 0x2990e8
	lda_24 xiy, 0x200c98
	lds32	xbc, 0
	cp	xbc, 0x0000001a
	jp_24	z, 0x2990E3
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp 0x2990ca                             ; jp 0x2990ca
	incdi8_24	1, 0x229DC6
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	push xwa
	lds32	xbc, 0
	ld	xix, (0x229cf0)
	lda_24 xiy, 0x201618
	cp	xbc, 0x0000001a
	jp_24	z, 0x299115
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp 0x2990fc                             ; jp 0x2990fc
	pop xwa                                 ; pop XWA
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	xor	xwa, xwa
	call 0x2991ad
	inc 1, xwa                              ; inc 1,XWA
	call 0x298a8e
	ret

	push xbc
	push xix
	xor	xwa, xwa
	xor	xbc, xbc
	ld8_24	a, 0x229D9F
	ld	xbc, 0x00000180
	call HDAE5000_HD_Init_Variables
	ld	xix, xwa
	xor	xwa, xwa
	call 0x299487
	ld	xbc, 0x00000010
	call HDAE5000_HD_Init_Variables
	add	xwa, xix
	ld	xbc, 0x0000004c
	call HDAE5000_HD_Init_Variables
	lda_24 xix, 0x201db2
	add	xwa, xix
	ld	(0x229cf0), xwa
	pop xix                                 ; pop XIX
	pop xbc                                 ; pop XBC
	ret

	push xbc
	push xix
	xor	xwa, xwa
	xor	xbc, xbc
	ld8_24	a, 0x229D9F
	ld	xbc, 0x00000180
	call HDAE5000_HD_Init_Variables
	ld	xix, xwa
	xor	xwa, xwa
	call 0x299487
	ld	xbc, 0x00000010
	call HDAE5000_HD_Init_Variables
	add	xix, xwa
	xor	xwa, xwa
	call 0x2991ad
	add	xwa, xix
	ld	xbc, 0x0000004c
	call HDAE5000_HD_Init_Variables
	lda_24 xix, 0x201db2
	add	xwa, xix
	ld	(0x229cf0), xwa
	pop xix                                 ; pop XIX
	pop xbc                                 ; pop XBC
	ret

	push xix
	push xbc
	xor	xwa, xwa
	ld8_24	a, 0x229D9F
	ld	xbc, 0x00000018
	call HDAE5000_HD_Init_Variables
	ld	xix, xwa
	xor	xwa, xwa
	call 0x299487
	add	xwa, xix
	lda_24 xix, 0x229ddf
	add	xix, xwa
	ld	a, (xix)
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

	push xix
	push xbc
	xor	xwa, xwa
	ld8_24	a, 0x229D9F
	ld	xbc, 0x00000018
	call HDAE5000_HD_Init_Variables
	ld	xix, xwa
	xor	xwa, xwa
	call 0x299487
	add	xwa, xix
	lda_24 xix, 0x229ddf
	add	xix, xwa
	incm8	1, (xix)
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

	push xix
	push xbc
	xor	xwa, xwa
	ld8_24	a, 0x229D9F
	ld	xbc, 0x00000018
	call HDAE5000_HD_Init_Variables
	ld	xix, xwa
	xor	xwa, xwa
	call 0x299487
	add	xwa, xix
	lda_24 xix, 0x229ddf
	add	xix, xwa
	decm8	1, (xix)
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

	push xix
	push xbc
	xor	xwa, xwa
	ld8_24	a, 0x229D9F
	ld	xbc, 0x00000018
	call HDAE5000_HD_Init_Variables
	ld	xix, xwa
	xor	xwa, xwa
	call 0x299487
	add	xwa, xix
	lda_24 xix, 0x229ddf
	add	xix, xwa
	ld	(xix), 0x00
	ld	a, (xix)
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

	push xix
	push xbc
	xor	xwa, xwa
	ld8_24	a, 0x229D9F
	ld	xbc, 0x00000018
	call HDAE5000_HD_Init_Variables
	ld	xix, xwa
	xor	xwa, xwa
	call 0x299487
	add	xwa, xix
	lda_24 xix, 0x229ddf
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
	ld8_24	a, 0x229D9F
	ld	xbc, 0x00000180
	call HDAE5000_HD_Init_Variables
	lda_24 xix, 0x201632
	add	xix, xwa
	xor	xwa, xwa
	call 0x299487
	ld	xbc, 0x00000010
	call HDAE5000_HD_Init_Variables
	add	xix, xwa
	ld	(0x229cec), xix
	lds32	xbc, 0
	lda_24 xiy, 0x200c98
	cp	xbc, 0x00000010
	jp_24	z, 0x2992CE
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp 0x2992b5                             ; jp 0x2992b5
	pop xwa                                 ; pop XWA
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	lda_24 xix, 0x200c98
	ld	xiy, (0x229cec)
	lds32	xbc, 0
	cp	xbc, 0x00000010
	jp_24	z, 0x2992FB
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp 0x2992e2                             ; jp 0x2992e2
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	call 0x298c52
	cps	a, 0
	jp_24	z, 0x29936F
	lda_24 xix, 0x2013b2
	lda_24 xiy, 0x200c98
	call 0x29899e
	cps	a, 1
	jp_24	z, 0x29936F
	cpi8_24	0x229DC2, 5
	jp_24	c, 0x299333
	sti8_24	0x229DC2, 0
	lda_24 xix, 0x2013b2
	xor	xwa, xwa
	ld8_24	a, 0x229DC2
	ld	xbc, 0x00000010
	call HDAE5000_HD_Init_Variables
	add	xix, xwa
	lda_24 xiy, 0x200c98
	lds32	xbc, 0
	cp	xbc, 0x00000010
	jp_24	z, 0x29936A
	ld	a, (xiy)
	ld	(xix), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp 0x299351                             ; jp 0x299351
	incdi8_24	1, 0x229DC2
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	cpi8_24	0x229DC5, 5
	jp_24	c, 0x299387
	sti8_24	0x229DC5, 0
	lda_24 xix, 0x2013b2
	xor	xwa, xwa
	ld8_24	a, 0x229DC5
	ld	xbc, 0x00000010
	call HDAE5000_HD_Init_Variables
	add	xix, xwa
	push xix
	call 0x2989e2
	pop xix                                 ; pop XIX
	cps	a, 1
	jp_24	nz, 0x2993B5
	sti8_24	0x229DC5, 0
	jp 0x2993da                             ; jp 0x2993da
	lda_24 xiy, 0x200c98
	lds32	xbc, 0
	cp	xbc, 0x00000010
	jp_24	z, 0x2993D5
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp 0x2993bc                             ; jp 0x2993bc
	incdi8_24	1, 0x229DC5
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
	ld8_24	a, 0x229D9F
	ld	xbc, 0x00000180
	call HDAE5000_HD_Init_Variables
	lda_24 xix, 0x201632
	add	xix, xwa
	xor	xwa, xwa
	call 0x299487
	ld	xbc, 0x00000010
	call HDAE5000_HD_Init_Variables
	add	xix, xwa
	lds32	xbc, 0
	lda_24 xiy, 0x200870
	cp	xbc, 0x00000010
	jp_24	z, 0x29942C
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp 0x299413                             ; jp 0x299413
	pop xwa                                 ; pop XWA
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	xor	xwa, xwa
	ld8_24	a, 0x229D9F
	ld	xbc, 0x00000018
	call HDAE5000_HD_Init_Variables
	ld	xix, xwa
	xor	xwa, xwa
	call 0x299487
	add	xwa, xix
	inc 1, xwa                              ; inc 1,XWA
	call 0x298a8e
	ret

	push xbc
	xor	xwa, xwa
	ld8_24	a, 0x229D9F
	ld	xbc, 0x00000018
	call HDAE5000_HD_Init_Variables
	inc 1, xwa                              ; inc 1,XWA
	pop xbc                                 ; pop XBC
	ret

	push xbc
	push xde
	xor	xwa, xwa
	xor	xbc, xbc
	xor	xde, xde
	ld	xde, 0x00201632
	ld8_24	a, 0x229D9F
	ld	xbc, 0x00000180
	call HDAE5000_HD_Init_Variables
	add	xwa, xde
	pop xde                                 ; pop XDE
	pop xbc                                 ; pop XBC
	ret

	push xix
	lda_24 xix, 0x229dda
	xor	xwa, xwa
	ld8_24	a, 0x229D9F
	add	xix, xwa
	ld	a, (xix)
	pop xix                                 ; pop XIX
	ret

	push xix
	lda_24 xix, 0x229dda
	xor	xwa, xwa
	ld8_24	a, 0x229D9F
	add	xix, xwa
	incm8	1, (xix)
	ld	a, (xix)
	pop xix                                 ; pop XIX
	ret

	push xix
	lda_24 xix, 0x229dda
	xor	xwa, xwa
	ld8_24	a, 0x229D9F
	add	xix, xwa
	decm8	1, (xix)
	ld	a, (xix)
	pop xix                                 ; pop XIX
	ret

	push xix
	lda_24 xix, 0x229dda
	xor	xwa, xwa
	ld8_24	a, 0x229D9F
	add	xix, xwa
	ld	(xix), 0x00
	pop xix                                 ; pop XIX
	ret

	push xix
	lda_24 xix, 0x229dda
	xor	xwa, xwa
	ld8_24	a, 0x229D9F
	add	xix, xwa
	ld	(xix), 0x17
	pop xix                                 ; pop XIX
	ret

	push xix
	push xwa
	lda_24 xix, 0x229dda
	xor	xwa, xwa
	ld8_24	a, 0x229D9F
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
	ld8_24	a, 0x229DA0
	ld	xbc, 0x00000d80
	call HDAE5000_HD_Init_Variables
	lda_24 xix, 0x2257b2
	add	xix, xwa
	xor	xwa, xwa
	call 0x29973f
	ld	xbc, 0x00000090
	call HDAE5000_HD_Init_Variables
	add	xix, xwa
	ld	(0x229cec), xix
	lds32	xbc, 0
	lda_24 xiy, 0x200c98
	cp	xbc, 0x00000010
	jp_24	z, 0x299554
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp 0x29953b                             ; jp 0x29953b
	pop xwa                                 ; pop XWA
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	lda_24 xix, 0x200c98
	ld	xiy, (0x229cec)
	lds32	xbc, 0
	cp	xbc, 0x00000010
	jp_24	z, 0x299581
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp 0x299568                             ; jp 0x299568
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	call 0x298c52
	cps	a, 0
	jp_24	z, 0x2995F5
	lda_24 xix, 0x2014b6
	lda_24 xiy, 0x200c98
	call 0x29899e
	cps	a, 1
	jp_24	z, 0x2995F5
	cpi8_24	0x229DC4, 5
	jp_24	c, 0x2995B9
	sti8_24	0x229DC4, 0
	lda_24 xix, 0x2014b6
	xor	xwa, xwa
	ld8_24	a, 0x229DC4
	ld	xbc, 0x00000010
	call HDAE5000_HD_Init_Variables
	add	xix, xwa
	lda_24 xiy, 0x200c98
	lds32	xbc, 0
	cp	xbc, 0x00000010
	jp_24	z, 0x2995F0
	ld	a, (xiy)
	ld	(xix), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp 0x2995d7                             ; jp 0x2995d7
	incdi8_24	1, 0x229DC4
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xix
	push xiy
	push xbc
	cpi8_24	0x229DC7, 5
	jp_24	c, 0x29960D
	sti8_24	0x229DC7, 0
	lda_24 xix, 0x2014b6
	xor	xwa, xwa
	ld8_24	a, 0x229DC7
	ld	xbc, 0x00000010
	call HDAE5000_HD_Init_Variables
	add	xix, xwa
	push xix
	call 0x2989e2
	pop xix                                 ; pop XIX
	cps	a, 1
	jp_24	nz, 0x29963B
	sti8_24	0x229DC7, 0
	jp 0x299660                             ; jp 0x299660
	lda_24 xiy, 0x200c98
	lds32	xbc, 0
	cp	xbc, 0x00000010
	jp_24	z, 0x29965B
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp 0x299642                             ; jp 0x299642
	incdi8_24	1, 0x229DC7
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
	ld8_24	a, 0x229DA0
	ld	xbc, 0x00000d80
	call HDAE5000_HD_Init_Variables
	lda_24 xix, 0x2257b2
	add	xix, xwa
	xor	xwa, xwa
	call 0x29973f
	ld	xbc, 0x00000090
	call HDAE5000_HD_Init_Variables
	add	xix, xwa
	lds32	xbc, 0
	lda_24 xiy, 0x200870
	cp	xbc, 0x00000010
	jp_24	z, 0x2996B2
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xbc                              ; inc 1,XBC
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp 0x299699                             ; jp 0x299699
	pop xwa                                 ; pop XWA
	pop xbc                                 ; pop XBC
	pop xiy                                 ; pop XIY
	pop xix                                 ; pop XIX
	ret

	push xbc
	push xde
	xor	xwa, xwa
	xor	xbc, xbc
	xor	xde, xde
	ld	xde, 0x002257b2
	ld8_24	a, 0x229DA0
	ld	xbc, 0x00000d80
	call HDAE5000_HD_Init_Variables
	add	xde, xwa
	xor	xwa, xwa
	call 0x29973f
	ld	xbc, 0x00000090
	call HDAE5000_HD_Init_Variables
	add	xwa, xde
	pop xde                                 ; pop XDE
	pop xbc                                 ; pop XBC
	ret

	push xbc
	xor	xwa, xwa
	ld8_24	a, 0x229DA0
	ld	xbc, 0x00000018
	call HDAE5000_HD_Init_Variables
	inc 1, xwa                              ; inc 1,XWA
	pop xbc                                 ; pop XBC
	ret

	push xbc
	push xde
	xor	xwa, xwa
	xor	xbc, xbc
	xor	xde, xde
	ld	xde, 0x002257b2
	ld8_24	a, 0x229DA0
	ld	xbc, 0x00000d80
	call HDAE5000_HD_Init_Variables
	add	xwa, xde
	pop xde                                 ; pop XDE
	pop xbc                                 ; pop XBC
	ret

	xor	xwa, xwa
	xor	xbc, xbc
	ld8_24	a, 0x229D9F
	ld	xbc, 0x00000018
	call HDAE5000_HD_Init_Variables
	ld	xix, xwa
	xor	xwa, xwa
	call 0x299487
	add	xwa, xix
	ld	(0x229c54), wa
	ret

	push xix
	lda_24 xix, 0x229e57
	xor	xwa, xwa
	ld8_24	a, 0x229DA0
	add	xix, xwa
	ld	a, (xix)
	pop xix                                 ; pop XIX
	ret

	push xix
	push xbc
	xor	xwa, xwa
	ld8_24	a, 0x229DA0
	ld	xbc, 0x00000018
	call HDAE5000_HD_Init_Variables
	ld	xix, xwa
	xor	xwa, xwa
	call 0x29973f
	add	xwa, xix
	lda_24 xix, 0x229e5c
	add	xix, xwa
	ld	a, (xix)
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

	push xix
	lda_24 xix, 0x229e57
	xor	xwa, xwa
	ld8_24	a, 0x229DA0
	add	xix, xwa
	incm8	1, (xix)
	ld	a, (xix)
	pop xix                                 ; pop XIX
	ret

	push xix
	lda_24 xix, 0x229e57
	xor	xwa, xwa
	ld8_24	a, 0x229DA0
	add	xix, xwa
	decm8	1, (xix)
	ld	a, (xix)
	pop xix                                 ; pop XIX
	ret

	push xix
	push xbc
	xor	xwa, xwa
	ld8_24	a, 0x229DA0
	ld	xbc, 0x00000018
	call HDAE5000_HD_Init_Variables
	ld	xix, xwa
	xor	xwa, xwa
	call 0x29973f
	add	xwa, xix
	lda_24 xix, 0x229e5c
	add	xix, xwa
	incm8	1, (xix)
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

	push xix
	push xbc
	xor	xwa, xwa
	ld8_24	a, 0x229DA0
	ld	xbc, 0x00000018
	call HDAE5000_HD_Init_Variables
	ld	xix, xwa
	xor	xwa, xwa
	call 0x29973f
	add	xwa, xix
	lda_24 xix, 0x229e5c
	add	xix, xwa
	decm8	1, (xix)
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

	push xix
	lda_24 xix, 0x229e57
	xor	xwa, xwa
	ld8_24	a, 0x229DA0
	add	xix, xwa
	ld	(xix), 0x00
	pop xix                                 ; pop XIX
	ret

	push xix
	lda_24 xix, 0x229e57
	xor	xwa, xwa
	ld8_24	a, 0x229DA0
	add	xix, xwa
	ld	(xix), 0x17
	pop xix                                 ; pop XIX
	ret

	push xix
	push xbc
	xor	xwa, xwa
	ld8_24	a, 0x229DA0
	ld	xbc, 0x00000018
	call HDAE5000_HD_Init_Variables
	ld	xix, xwa
	xor	xwa, xwa
	call 0x29973f
	add	xwa, xix
	lda_24 xix, 0x229e5c
	add	xix, xwa
	ld	(xix), 0x00
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

	push xix
	push xbc
	xor	xwa, xwa
	ld8_24	a, 0x229DA0
	ld	xbc, 0x00000018
	call HDAE5000_HD_Init_Variables
	ld	xix, xwa
	xor	xwa, xwa
	call 0x29973f
	add	xwa, xix
	lda_24 xix, 0x229e5c
	add	xix, xwa
	ld	(xix), 0x1f
	pop xbc                                 ; pop XBC
	pop xix                                 ; pop XIX
	ret

	call 0x2996b7
	ld	xbc, 0x00000010
	add	xwa, xbc
	ld	xix, xwa
	ld	(0x229d80), xix
	lda_24 xiy, 0x201556
	lds	bc, 0
	cp	bc, 0x0040
	jp_24	z, 0x29989E
	ld	a, (xix)
	ld	(xiy), a
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	inc	1, bc
	jp 0x299887                             ; jp 0x299887
	ret

	ld	xix, (0x229d80)
	lda_24 xiy, 0x201556
	lds	bc, 0
	cp	bc, 0x0040
	jp_24	z, 0x2998C2
	ld	a, (xiy)
	ld	(xix), a
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	inc	1, bc
	jp 0x2998ab                             ; jp 0x2998ab
	ret

	ld	xix, (0x229d7c)
	xor	xwa, xwa
	xor	xbc, xbc
	call 0x299752
	lds32	xbc, 2
	call HDAE5000_HD_Init_Variables
	add	xwa, xix
	ret

	ldw	wa, 0x3231
	ldw	hl, 0x3534
	ldw	iz, 0x3837
	push xbc
	ldb	w, 0x3e
	lds32	xhl, 1
	lda_24 xix, 0x200628
	ld	xde, 0x00000200
	call 0x297788
	lda_24 xix, 0x2006a0
	ld_spib a, 0xf0		; ld A,(XIX+)
	st8_24	0x229DA9, a
	ld_spib a, 0xf0		; ld A,(XIX+)
	st8_24	0x229DAA, a
	ld_spib a, 0xf0		; ld A,(XIX+)
	st8_24	0x229DAB, a
	ld_spib a, 0xf0		; ld A,(XIX+)
	st8_24	0x229DAC, a
	ld_spib a, 0xf0		; ld A,(XIX+)
	st8_24	0x229DAD, a
	ld	a, (xix)
	st8_24	0x229DAE, a
	pop xiz                                 ; pop XIZ
	ret

	push xiz
	lda_24 xix, 0x200628
	call 0x298896
	lda_24 xix, 0x200628
	ld	xwa, 0xaa55aa55
	ld (xix), xwa                           ; ld (XIX),XWA
	inc 4, xix                              ; inc 4,XIX
	ld	xwa, 0xf4f1f2f3
	ld (xix), xwa                           ; ld (XIX),XWA
	inc 4, xix                              ; inc 4,XIX
	lda_24 xiy, 0x2999b2
	lda_24 xiz, 0x299a22
	cp	xiy, xiz
	jp_24	z, 0x299969
	ld	a, (xiy)
	ld	(xix), a
	inc 1, xix                              ; inc 1,XIX
	inc 1, xiy                              ; inc 1,XIY
	jp 0x299956                             ; jp 0x299956
	lda_24 xix, 0x2006a0
	ld8_24	a, 0x229DA9
	lda_dpi xbc, 0xf0		; ld (XIX+),A
	ld8_24	a, 0x229DAA
	lda_dpi xbc, 0xf0		; ld (XIX+),A
	ld8_24	a, 0x229DAB
	lda_dpi xbc, 0xf0		; ld (XIX+),A
	ld8_24	a, 0x229DAC
	lda_dpi xbc, 0xf0		; ld (XIX+),A
	ld8_24	a, 0x229DAD
	lda_dpi xbc, 0xf0		; ld (XIX+),A
	ld8_24	a, 0x229DAE
	lda_dpi xbc, 0xf0		; ld (XIX+),A
	ld	xwa, 0xffffffff
	ld (xix), xwa                           ; ld (XIX),XWA
	lds32	xhl, 1
	lda_24 xix, 0x200628
	call 0x29769b
	pop xiz                                 ; pop XIZ
	ret

	.byte 0x54                             ; db
	jr	mi, 0x63
	jr t, .LDSR_9a25                       ; [68 6e] jr T,0x299a25
	jr	ge, 0x63
	jrl	ule, 0x5320
	jr	nc, 0x66
	jrl	ov, 0x6177
	jrl	le, 0x2065
	jrl	ule, 0x6365
	jrl	ov, 0x6f69
	jr	nz, 0x20
	ldb	w, 0x20
	ldb	w, 0x4d
	pushw iz                                ; push IZ
	ldb	w, 0x4b
	jr ge, .LDSR_9a49                      ; [69 74] jr GE,0x299a49
	jr	lt, 0x6a
	jr ge, .LDSR_9a46                      ; [69 6d] jr GE,0x299a46
	jr	lt, 0x32
	pushw iz                                ; push IZ
	ldw	hl, 0x4a33
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x32
	pushw iz                                ; push IZ
	ldw	de, 0x2031
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x54
	ld	xiy, 0x494e4843
	ld	xhl, 0x4e4b2053
	ldw	iy, 0x3030
.LDSR_9a18:
	ldw	wa, 0x2020
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
.LDSR_9a25:
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x20
	ldb	w, 0x4a
	jrl	mi, 0x696c
	pushw iy                                ; push IY
	.byte 0x4f                             ; pop SP
	jr	ugt, 0x74
	jr	nc, 0x62
	jr	mi, 0x72
.LDSR_9a46:
	ldb	w, 0x31
	push xbc
.LDSR_9a49:
	push xbc
	ldw	iz, 0x5858
	pop xwa                                 ; pop XWA
	pop xwa                                 ; pop XWA
	pop xwa                                 ; pop XWA
	pop xwa                                 ; pop XWA
	pop xwa                                 ; pop XWA
	pop xwa                                 ; pop XWA
	jp 0x221f1c                             ; jp 0x221f1c
	.byte 0x56                             ; db
	ld	xiy, 0x31452220
	ldw	de, 0x3433
	ldw	iy, 0x3736
	push xwa
	push xbc
	ldw	bc, 0x3130
	ldw	bc, 0x3231
	ldw	bc, 0x3133
	ldw	ix, 0x3531
	ldw	bc, 0x3136
	.byte 0x37, 0x31, 0x38                 ; ld SP,0x3831
	ldw	bc, 0x3239
	ldw	wa, 0x3132
	ldw	de, 0x3232
	ldw	hl, 0x3432
	ldw	de, 0x4135
	ld	xde, 0x46454443
	ld	xsp, 0x4b4a4948
	popw ix                                 ; pop IX
	popw iy                                 ; pop IY
	popw iz                                 ; pop IZ
	.byte 0x4f                             ; pop SP
	.byte 0x50                             ; db
	.byte 0x51                             ; db
	.byte 0x52                             ; db
	.byte 0x53                             ; db
	.byte 0x54                             ; db
	.byte 0x55                             ; db
	.byte 0x56                             ; db
	.byte 0x57                             ; db
	pop xwa                                 ; pop XWA
	pop xbc                                 ; pop XBC
	pop xde                                 ; pop XDE
	jr	lt, 0x62
	jr ule, .LDSR_9b07                     ; [63 64] jr ULE,0x299b07
	jr	mi, 0x66
	jr	c, 0x68
	jr	ge, 0x6a
	jr	ugt, 0x6c
	jr	pl, 0x6e
	jr	nc, 0x70
	jrl	lt, 0x7372
	jrl	ov, 0x7675
	jrl	c, 0x2320
.LDSR_9ab8:
	pushw iz                                ; push IZ
	pushw iy                                ; push IY
	pushw ix                                ; push IX
	push xhl
	push xde
	pop xsp                                 ; pop XSP
	jrl	f, 0x726f
	jrl	ov, 0x6f75
	jr	ge, 0x72
	jrl	mi, 0x6f74
	jr	ge, 0x75
	jrl	le, 0x5574
	.byte 0x50                             ; db
	.byte 0x4f                             ; pop SP
	.byte 0x54                             ; db
	.byte 0x52                             ; db
	.byte 0x55                             ; db
	popw de                                 ; pop DE
	.byte 0x52                             ; db
	popw iz                                 ; pop IZ
	ld	xsp, 0x55495245
	.byte 0x54                             ; db
	.byte 0x37, 0x34, 0x35                 ; ld SP,0x3534
	.byte 0x37, 0x38, 0x39                 ; ld SP,0x3938
	ldw	wa, 0x5643
	popw iz                                 ; pop IZ
	ld	xde, 0x3e37b6bf
	ldw (xsp + 0x04), 0
	jrl t, .LDSR_a3b7                      ; [78 c4 08] jrl T,0x29a3b7
.LDSR_9af3:
	cp	iz, 0x0025
	jr z, .LDSR_9b07                       ; [66 0e] jr Z,0x299b07
	pushw iz                                ; push IZ
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incm	1, (xsp+4)
	jrl t, .LDSR_a3b7                      ; [78 b0 08] jrl T,0x29a3b7
.LDSR_9b07:
	ldw (xsp + 0x08), 0
	ldw (xsp + 0x0a), 0
	ldw (xsp + 0x06), 0
	sti16_24	0x239486, 32
.LDSR_9b1d:
	ld xwa, (xsp + 0x52)                    ; ld XWA,(XSP+0x52)
	ld_spib c, 0xe0		; ld C,(XWA+)
	ld (xsp + 0x52), xwa                    ; ld (XSP+0x52),XWA
	ldfr_berp c, 0xf8		; ld IZL,C
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
	lds32	xwa, 2
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
	ld_spib c, 0xe0		; ld C,(XWA+)
	ld (xsp + 0x52), xwa                    ; ld (XSP+0x52),XWA
	ldfr_berp c, 0xf8		; ld IZL,C
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
	sti16_24	0x239486, 48
	jrl t, .LDSR_9b1d                      ; [78 7d ff] jrl T,0x299b1d
.LDSR_9ba0:
	ld	bc, iz
	sub	bc, 0x0030
	ld	wa, (xsp+8)
	muls	wa, 0x000a
	ld (xsp + 0x08), wa                     ; ld (XSP+0x08),WA
	add	(xsp+8), bc
	ld xwa, (xsp + 0x52)                    ; ld XWA,(XSP+0x52)
	ld_spib c, 0xe0		; ld C,(XWA+)
	ld (xsp + 0x52), xwa                    ; ld (XSP+0x52),XWA
	ldfr_berp c, 0xf8		; ld IZL,C
	exts	iz
.LDSR_9bc1:
	ldto_berp a, 0xf8		; ld A,IZL
	extz wa                                 ; extz WA
	lda_24 xbc, 0x2f9362
	bit_dri 2, 0x07, 0xE4, 0xE0	; bit 2,(XBC+WA)
	jr nz, .LDSR_9ba0                      ; [6e ce] jr NZ,0x299ba0
.LDSR_9bd2:
	cp	iz, 0x002e
	jr nz, .LDSR_9c4a                      ; [6e 72] jr NZ,0x299c4a
	setm	4, (xsp+6)
	ld xwa, (xsp + 0x52)                    ; ld XWA,(XSP+0x52)
	ld_spib c, 0xe0		; ld C,(XWA+)
	ld (xsp + 0x52), xwa                    ; ld (XSP+0x52),XWA
	ldfr_berp c, 0xf8		; ld IZL,C
	exts	iz
	cp	iz, 0x002a
	jr nz, .LDSR_9c39                      ; [6e 4a] jr NZ,0x299c39
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	lds32	xwa, 2
	add	(xbc), xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld	wa, (xwa-2)
	ld (xsp + 0x0a), wa                     ; ld (XSP+0x0a),WA
	cpw	(xsp+10), 0x0000
	jr ge, .LDSR_9c08                      ; [69 03] jr GE,0x299c08
	resm	4, (xsp+6)
.LDSR_9c08:
	ld xwa, (xsp + 0x52)                    ; ld XWA,(XSP+0x52)
	ld_spib c, 0xe0		; ld C,(XWA+)
	ld (xsp + 0x52), xwa                    ; ld (XSP+0x52),XWA
	ldfr_berp c, 0xf8		; ld IZL,C
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
	ld_spib c, 0xe0		; ld C,(XWA+)
	ld (xsp + 0x52), xwa                    ; ld (XSP+0x52),XWA
	ldfr_berp c, 0xf8		; ld IZL,C
	exts	iz
.LDSR_9c39:
	ldto_berp a, 0xf8		; ld A,IZL
	extz wa                                 ; extz WA
	lda_24 xbc, 0x2f9362
	bit_dri 2, 0x07, 0xE4, 0xE0	; bit 2,(XBC+WA)
	jr nz, .LDSR_9c18                      ; [6e ce] jr NZ,0x299c18
.LDSR_9c4a:
	cp	iz, 0x0068
	jr nz, .LDSR_9c63                      ; [6e 13] jr NZ,0x299c63
	setm	5, (xsp+6)
	ld xwa, (xsp + 0x52)                    ; ld XWA,(XSP+0x52)
	ld_spib c, 0xe0		; ld C,(XWA+)
	ld (xsp + 0x52), xwa                    ; ld (XSP+0x52),XWA
	ldfr_berp c, 0xf8		; ld IZL,C
	exts	iz
	jr t, .LDSR_9c93                       ; [68 30] jr T,0x299c93
.LDSR_9c63:
	cp	iz, 0x006c
	jr nz, .LDSR_9c7c                      ; [6e 13] jr NZ,0x299c7c
	setm	6, (xsp+6)
	ld xwa, (xsp + 0x52)                    ; ld XWA,(XSP+0x52)
	ld_spib c, 0xe0		; ld C,(XWA+)
	ld (xsp + 0x52), xwa                    ; ld (XSP+0x52),XWA
	ldfr_berp c, 0xf8		; ld IZL,C
	exts	iz
	jr t, .LDSR_9c93                       ; [68 17] jr T,0x299c93
.LDSR_9c7c:
	cp	iz, 0x004c
	jr nz, .LDSR_9c93                      ; [6e 11] jr NZ,0x299c93
	setm	7, (xsp+6)
	ld xwa, (xsp + 0x52)                    ; ld XWA,(XSP+0x52)
	ld_spib c, 0xe0		; ld C,(XWA+)
	ld (xsp + 0x52), xwa                    ; ld (XSP+0x52),XWA
	ldfr_berp c, 0xf8		; ld IZL,C
	exts	iz
.LDSR_9c93:
	ld	wa, iz
	cp	iz, 0x0047
	jrl z, .LDSR_a360                      ; [76 c4 06] jrl Z,0x29a360
	cp	wa, 0x0045
	jrl z, .LDSR_a360                      ; [76 bd 06] jrl Z,0x29a360
	cp	wa, 0x0058
	jrl z, .LDSR_a088                      ; [76 de 03] jrl Z,0x29a088
	cp	wa, 0x0025
	jr z, .LDSR_9cd6                       ; [66 26] jr Z,0x299cd6
	sub	wa, 0x0063
	cps	wa, 0
	jrl lt, .LDSR_a3b7                     ; [71 fe 06] jrl LT,0x29a3b7
	cp	wa, 0x0015
	jrl gt, .LDSR_a3b7                     ; [7a f7 06] jrl GT,0x29a3b7
	add	wa, wa
	lda_24 xix, 0x2f9462
	ld_sriw3 wa, 0x07, 0xF0, 0xE0	; ld WA,(XIX+WA)
	lda_24 xix, 0x299cd6
	jp_dri 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
.LDSR_9cd6:
	ld	wa, (xsp+6)
	bit	0x01, wa
	jr z, .LDSR_9cef                       ; [66 11] jr Z,0x299cef
	jr t, .LDSR_9cf9                       ; [68 19] jr T,0x299cf9
.LDSR_9ce0:
	incm	1, (xsp+4)
	pushdi_24	0x239486
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_9cef:
	decm	1, (xsp+8)
	cpw	(xsp+8), 0x0000
	jr gt, .LDSR_9ce0                      ; [6a e7] jr GT,0x299ce0
.LDSR_9cf9:
	incm	1, (xsp+4)
	cp	iz, 0x0063
	jr nz, .LDSR_9d10                      ; [6e 0e] jr NZ,0x299d10
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	lds32	xwa, 2
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
	jrl t, .LDSR_a3b7                      ; [78 92 06] jrl T,0x29a3b7
.LDSR_9d25:
	incm	1, (xsp+4)
	pushw 0x0020
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_9d32:
	decm	1, (xsp+8)
	cpw	(xsp+8), 0x0000
	jr gt, .LDSR_9d25                      ; [6a e9] jr GT,0x299d25
	jrl t, .LDSR_a3b7                      ; [78 78 06] jrl T,0x29a3b7
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	lds32	xwa, 4
	add	(xbc), xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld	xwa, (xwa-4)
	ld (xsp + 0x10), xwa                    ; ld (XSP+0x10),XWA
	push xwa
	call HDAE5000_Display_Buffer_Validate
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
	pushdi_24	0x239486
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_9d98:
	ld	wa, (xsp+8)
	decm	1, (xsp+8)
	cps	wa, 0
	jr nz, .LDSR_9d8c                      ; [6e ea] jr NZ,0x299d8c
	jr t, .LDSR_9db7                       ; [68 13] jr T,0x299db7
.LDSR_9da4:
	ld xwa, (xsp + 0x10)                    ; ld XWA,(XSP+0x10)
	ld_spib c, 0xe0		; ld C,(XWA+)
	ld (xsp + 0x10), xwa                    ; ld (XSP+0x10),XWA
	exts bc                                 ; exts BC
	pushw bc                                ; push BC
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_9db7:
	ld	wa, (xsp+10)
	decm	1, (xsp+10)
	cps	wa, 0
	jr nz, .LDSR_9da4                      ; [6e e3] jr NZ,0x299da4
	ld	wa, (xsp+6)
	bit	0x01, wa
	jr nz, .LDSR_9dd6                      ; [6e 0d] jr NZ,0x299dd6
	jrl t, .LDSR_a3b7                      ; [78 eb 05] jrl T,0x29a3b7
.LDSR_9dcc:
	pushw 0x0020
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_9dd6:
	ld	wa, (xsp+8)
	decm	1, (xsp+8)
	cps	wa, 0
	jr nz, .LDSR_9dcc                      ; [6e ec] jr NZ,0x299dcc
	jrl t, .LDSR_a3b7                      ; [78 d4 05] jrl T,0x29a3b7
	ld	wa, (xsp+6)
	bit	0x06, wa
	jr z, .LDSR_9dfc                       ; [66 11] jr Z,0x299dfc
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	lds32	xwa, 4
	add	(xbc), xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld	xwa, (xwa-4)
	ld (xsp + 0x10), xwa                    ; ld (XSP+0x10),XWA
	jr t, .LDSR_9e0d                       ; [68 11] jr T,0x299e0d
.LDSR_9dfc:
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	lds32	xwa, 2
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
	calr	0x0595
	lda	xwa, (xsp+64)
	push xwa
	call HDAE5000_Display_Buffer_Validate
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
	cpdi16_24	0x239486, 32
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
	cps	wa, 0
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
	cpdi16_24	0x239486, 48
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
	cps	wa, 0
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
	cps	wa, 0
	jr nz, .LDSR_9f38                      ; [6e ec] jr NZ,0x299f38
	jr t, .LDSR_9f66                       ; [68 18] jr T,0x299f66
.LDSR_9f4e:
	decm	1, (xsp+12)
	lda	xbc, (xsp+56)
	ld	wa, (xsp+12)
	ld_srib3 a, 0x07, 0xE4, 0xE0	; ld A,(XBC+WA)
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
	jrl t, .LDSR_a3b7                      ; [78 3f 04] jrl T,0x29a3b7
.LDSR_9f78:
	pushw 0x0020
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_9f82:
	ld	wa, (xsp+8)
	decm	1, (xsp+8)
	cps	wa, 0
	jr nz, .LDSR_9f78                      ; [6e ec] jr NZ,0x299f78
	jrl t, .LDSR_a3b7                      ; [78 28 04] jrl T,0x29a3b7
	ld	wa, (xsp+6)
	bit	0x06, wa
	jr z, .LDSR_9fa5                       ; [66 0e] jr Z,0x299fa5
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	lds32	xwa, 4
	add	(xbc), xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld	xde, (xwa-4)
	jr t, .LDSR_9fb3                       ; [68 0e] jr T,0x299fb3
.LDSR_9fa5:
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	lds32	xwa, 2
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
	lds	iz, 0
	jr t, .LDSR_9fe2                       ; [68 12] jr T,0x299fe2
.LDSR_9fd0:
	push xde
	push xbc
	calr	0x044d
	lda	xwa, (xsp+52)
	push xwa
	call HDAE5000_Display_Buffer_Validate
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
	pushdi_24	0x239486
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_a029:
	ld	wa, (xsp+8)
	decm	1, (xsp+8)
	cps	wa, 0
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
	cps	wa, 0
	jr nz, .LDSR_a035                      ; [6e ec] jr NZ,0x29a035
	jr t, .LDSR_a05f                       ; [68 14] jr T,0x29a05f
.LDSR_a04b:
	dec	1, iz
	lda	xwa, (xsp+44)
	ld_srib3 a, 0x07, 0xE0, 0xF8	; ld A,(XWA+IZ)
	exts wa                                 ; exts WA
	pushw wa                                ; push WA
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_a05f:
	cps	iz, 0
	jr nz, .LDSR_a04b                      ; [6e e8] jr NZ,0x29a04b
	ld	wa, (xsp+6)
	bit	0x01, wa
	jr nz, .LDSR_a078                      ; [6e 0d] jr NZ,0x29a078
	jrl t, .LDSR_a3b7                      ; [78 49 03] jrl T,0x29a3b7
.LDSR_a06e:
	pushw 0x0020
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_a078:
	ld	wa, (xsp+8)
	decm	1, (xsp+8)
	cps	wa, 0
	jr nz, .LDSR_a06e                      ; [6e ec] jr NZ,0x29a06e
	jrl t, .LDSR_a3b7                      ; [78 32 03] jrl T,0x29a3b7
	setm	6, (xsp+6)
.LDSR_a088:
	ld	wa, (xsp+6)
	bit	0x06, wa
	jr z, .LDSR_a09e                       ; [66 0e] jr Z,0x29a09e
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	lds32	xwa, 4
	add	(xbc), xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld	xde, (xwa-4)
	jr t, .LDSR_a0ac                       ; [68 0e] jr T,0x29a0ac
.LDSR_a09e:
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	lds32	xwa, 2
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
	calr	0x038f
	lda	xwa, (xsp+42)
	push xwa
	call HDAE5000_Display_Buffer_Validate
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
	cpdi16_24	0x239486, 32
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
	cps	wa, 0
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
	cpdi16_24	0x239486, 48
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
	cps	wa, 0
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
	cps	wa, 0
	jr nz, .LDSR_a199                      ; [6e ec] jr NZ,0x29a199
	jr t, .LDSR_a1c7                       ; [68 18] jr T,0x29a1c7
.LDSR_a1af:
	decm	1, (xsp+18)
	lda	xbc, (xsp+32)
	ld	wa, (xsp+18)
	ld_srib3 a, 0x07, 0xE4, 0xE0	; ld A,(XBC+WA)
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
	jrl t, .LDSR_a3b7                      ; [78 de 01] jrl T,0x29a3b7
.LDSR_a1d9:
	pushw 0x0020
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_a1e3:
	ld	wa, (xsp+8)
	decm	1, (xsp+8)
	cps	wa, 0
	jr nz, .LDSR_a1d9                      ; [6e ec] jr NZ,0x29a1d9
	jrl t, .LDSR_a3b7                      ; [78 c7 01] jrl T,0x29a3b7
	ld	wa, (xsp+6)
	bit	0x06, wa
	jr z, .LDSR_a206                       ; [66 0e] jr Z,0x29a206
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	lds32	xwa, 4
	add	(xbc), xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld	xde, (xwa-4)
	jr t, .LDSR_a214                       ; [68 0e] jr T,0x29a214
.LDSR_a206:
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	lds32	xwa, 2
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
	lds	iz, 0
	jr t, .LDSR_a243                       ; [68 12] jr T,0x29a243
.LDSR_a231:
	push xde
	push xbc
	calr	0x025e
	lda	xwa, (xsp+28)
	push xwa
	call HDAE5000_Display_Buffer_Validate
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
	cps	wa, 0
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
	cpdi16_24	0x239486, 32
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
	cps	wa, 0
	jr nz, .LDSR_a29b                      ; [6e ec] jr NZ,0x29a29b
.LDSR_a2af:
	cpw	(xsp+18), 0x0000
	jr z, .LDSR_a2c4                       ; [66 0e] jr Z,0x29a2c4
	cps	iz, 0
	jr z, .LDSR_a2c4                       ; [66 0a] jr Z,0x29a2c4
	pushw 0x0030
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_a2c4:
	ld	wa, (xsp+6)
	bit	0x01, wa
	jr nz, .LDSR_a2f7                      ; [6e 2b] jr NZ,0x29a2f7
	cpdi16_24	0x239486, 48
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
	cps	wa, 0
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
	cps	wa, 0
	jr nz, .LDSR_a2ed                      ; [6e ec] jr NZ,0x29a2ed
	jr t, .LDSR_a317                       ; [68 14] jr T,0x29a317
.LDSR_a303:
	dec	1, iz
	lda	xwa, (xsp+20)
	ld_srib3 a, 0x07, 0xE0, 0xF8	; ld A,(XWA+IZ)
	exts wa                                 ; exts WA
	pushw wa                                ; push WA
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_a317:
	cps	iz, 0
	jr nz, .LDSR_a303                      ; [6e e8] jr NZ,0x29a303
	ld	wa, (xsp+6)
	bit	0x01, wa
	jr nz, .LDSR_a330                      ; [6e 0d] jr NZ,0x29a330
	jrl t, .LDSR_a3b7                      ; [78 91 00] jrl T,0x29a3b7
.LDSR_a326:
	pushw 0x0020
	ld xwa, (xsp + 0x5c)                    ; ld XWA,(XSP+0x5c)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
.LDSR_a330:
	ld	wa, (xsp+8)
	decm	1, (xsp+8)
	cps	wa, 0
	jr nz, .LDSR_a326                      ; [6e ec] jr NZ,0x29a326
	jr t, .LDSR_a3b7                       ; [68 7b] jr T,0x29a3b7
	ld xbc, (xsp + 0x56)                    ; ld XBC,(XSP+0x56)
	lds32	xwa, 4
	add	(xbc), xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld	xbc, (xwa-4)
	ld	wa, (xsp+6)
	bit	0x06, wa
	jr z, .LDSR_a359                       ; [66 09] jr Z,0x29a359
	ld	wa, (xsp+4)
	exts xwa                                ; exts XWA
	ld (xbc), xwa                           ; ld (XBC),XWA
	jr t, .LDSR_a3b7                       ; [68 5e] jr T,0x29a3b7
.LDSR_a359:
	ld	wa, (xsp+4)
	ld (xbc), wa                            ; ld (XBC),WA
	jr t, .LDSR_a3b7                       ; [68 57] jr T,0x29a3b7
.LDSR_a360:
	lda	xbc, (xsp+68)
	ld	wa, (xsp+6)
	bit	0x07, wa
	jr z, .LDSR_a380                       ; [66 15] jr Z,0x29a380
	ld	xwa, xbc
	ld xde, (xsp + 0x56)                    ; ld XDE,(XSP+0x56)
	.byte 0xf0, 0x0a, 0x31                 ; lda XBC,0x0a
	add	(xde), xbc
	ld xbc, (xde)                           ; ld XBC,(XDE)
	lda	xbc, (xbc-10)
	call 0x29b7e8
	jr t, .LDSR_a392                       ; [68 12] jr T,0x29a392
.LDSR_a380:
	ld	xwa, xbc
	ld xde, (xsp + 0x56)                    ; ld XDE,(XSP+0x56)
	.byte 0xf0, 0x08, 0x31                 ; lda XBC,0x08
	add	(xde), xbc
	ld xbc, (xde)                           ; ld XBC,(XDE)
	dec 0, xbc                              ; dec 0,XBC
	call 0x29b7dc
.LDSR_a392:
	pushm	(xsp+10)
	pushm	(xsp+10)
	pushm	(xsp+10)
	lda	xwa, (xsp+74)
	push xwa
	ld xwa, (xsp + 0x64)                    ; ld XWA,(XSP+0x64)
	push xwa
	ldto_berp a, 0xf8		; ld A,IZL
	exts wa                                 ; exts WA
	pushw wa                                ; push WA
	calr	0x010a
	lda	xsp, (xsp+16)
	ld16_24	wa, 0x239488
	add	(xsp+4), wa
.LDSR_a3b7:
	ld xwa, (xsp + 0x52)                    ; ld XWA,(XSP+0x52)
	ld_spib c, 0xe0		; ld C,(XWA+)
	ld (xsp + 0x52), xwa                    ; ld (XSP+0x52),XWA
	ldfr_berp c, 0xf8		; ld IZL,C
	exts	iz
	cps	iz, 0
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
	st_dpib a, 0xE0			; lda XBC, (XWA+) — advance write ptr
	ld (xsp + 4), xbc		; save digit write position
	ld (xsp + 12), xwa		; save advanced buffer ptr
	ld xwa, xiz			; value to divide
	lda_dd8l xbc, 0x0A		; divisor = 10
	call HDAE5000_Divide_Unsigned	; XHL = remainder
	add xhl, 0x00000030		; remainder + '0' → ASCII digit
	ld xwa, (xsp + 4)		; get digit write position
	ld (xwa), l			; store digit character
	ld xwa, xiz			; reload value
	lda_dd8l xbc, 0x0A		; divisor = 10
	call HDAE5000_Divide_Signed	; XHL = quotient
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
	st_dpib a, 0xE0			; lda XBC, (XWA+) — advance write ptr
	ld (xsp + 4), xbc		; save digit write position
	ld (xsp + 12), xwa		; save advanced buffer ptr
	ld xwa, xiz			; value to divide
	lda_dd8l xbc, 0x0A		; divisor = 10
	call HDAE5000_Divide_Unsigned	; XHL = remainder
	add xhl, 0x00000030		; remainder + '0' → ASCII digit
	ld xwa, (xsp + 4)		; get digit write position
	ld (xwa), l			; store digit character
	ld xwa, xiz			; reload value
	lda_dd8l xbc, 0x0A		; divisor = 10
	call HDAE5000_Divide_Signed	; XHL = quotient
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
	ld xwa, 0x002F94A0		; lowercase hex digit table
	cpw (xsp + 12), 0x0078	; format == 'x'?
	jr nz, .LInt_To_Hex__start
	ld xwa, 0x002F948E		; uppercase hex digit table
.LInt_To_Hex__start:
	ld xix, xwa			; XIX = digit table pointer
	ld xhl, (xsp + 4)		; buffer pointer
	ld xde, (xsp + 8)		; value to convert
.LInt_To_Hex__loop:
	st_dpib a, 0xEC			; lda XBC, (XHL+) — post-increment buffer ptr
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
	st_dpib a, 0xEC			; lda XBC, (XHL+) — post-increment buffer ptr
	ld xwa, xde
	and xwa, 0x00000007		; mask low 3 bits
	add xwa, 0x00000030		; convert to ASCII '0'-'7'
	ld (xbc), a			; store digit
	srl xde, 3			; shift to next octal digit
	jr nz, .LInt_To_Octal__loop
	ld (xhl), 0x00		; null-terminate
	ret

HDAE5000_String_Format:	; 0x29A4B6 (173 bytes)
	; sprintf-like formatter entry point (handles %e, %E, %f, %F, %g, %G)
	; Allocates 26-byte stack frame, dispatches to String_Format_Core or
	; String_Format_Output based on format specifier character in C register.
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
	call 2732154			; call 0x29B07A (setup utility)
	lda xsp, (xsp + 0x12)		; deallocate 18 bytes of args
	sti16_24 0x239488, 0x0000              ; [0x239488] = 0 (clear format state)
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
	calr HDAE5000_String_Format_Core
	lda xsp, (xsp + 0x14)		; deallocate 20 bytes of args
	jr t, .Lsf_cleanup		; always → cleanup
.Lsf_not_fF:				; g/G format handling
	ld wa, (xsp + 0x2C)		; WA = flags
	bit 4, wa			; bit 4 set?
	jr nz, .Lsf_have_precision
	lds hl, 6			; default precision = 6
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
	calr HDAE5000_String_Format_Output
	lda xsp, (xsp + 0x14)		; deallocate 20 bytes of args
.Lsf_cleanup:
	pop xiz				; restore XIZ
	lda xsp, (xsp + 0x1A)		; deallocate 26-byte stack frame
	ret

HDAE5000_String_Format_Core:	; 0x29A563 (805 bytes)
	; Core string format engine - processes format specifiers
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
	lda_24 xde, 0x2f9362
	st_dri3b b, 0x07, 0xE8, 0xE0	; lda XDE,XDE+WA
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
	cp_srib_im 0x07, 0xE0, 0xF8, 0x34	; cp (XWA+IZ),0x34
	jr le, .LSFC_a600                      ; [62 25] jr LE,0x29a600
	cps	iz, 0
	jr ge, .LSFC_a5ea                      ; [69 0b] jr GE,0x29a5ea
	jr t, .LSFC_a600                       ; [68 1f] jr T,0x29a600
.LSFC_a5e1:
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	stib_dri 0x07, 0xE0, 0xF8, 0x30	; ld (XWA+IZ),0x30
.LSFC_a5ea:
	dec	1, iz
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	inc_srib 1, 0x07, 0xE0, 0xF8	; inc 1,(XWA+IZ)
	cps	iz, 0
	jr le, .LSFC_a600                      ; [62 08] jr LE,0x29a600
	cp_srib_im 0x07, 0xE0, 0xF8, 0x39	; cp (XWA+IZ),0x39
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
	cp_srib_im 0x07, 0xE0, 0xF8, 0x30	; cp (XWA+IZ),0x30
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
	cps	iz, 0
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
	cpdi16_24	0x239486, 32
	jr z, .LSFC_a6b0                       ; [66 11] jr Z,0x29a6b0
	jr t, .LSFC_a6ba                       ; [68 19] jr T,0x29a6ba
.LSFC_a6a1:
	pushw 0x0020
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incdi16_24	1, 0x239488
.LSFC_a6b0:
	ld	wa, (xsp+18)
	decm	1, (xsp+18)
	cps	wa, 0
	jr gt, .LSFC_a6a1                      ; [6a e7] jr GT,0x29a6a1
.LSFC_a6ba:
	cps	iz, 0
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
	incdi16_24	1, 0x239488
.LSFC_a6e7:
	ld	wa, (xsp+16)
	bit	0x01, wa
	jr nz, .LSFC_a713                      ; [6e 24] jr NZ,0x29a713
	cpdi16_24	0x239486, 48
	jr z, .LSFC_a709                       ; [66 11] jr Z,0x29a709
	jr t, .LSFC_a713                       ; [68 19] jr T,0x29a713
.LSFC_a6fa:
	pushw 0x0030
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incdi16_24	1, 0x239488
.LSFC_a709:
	ld	wa, (xsp+18)
	decm	1, (xsp+18)
	cps	wa, 0
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
	incdi16_24	1, 0x239488
.LSFC_a74a:
	lds	iz, 0
	jr t, .LSFC_a767                       ; [68 19] jr T,0x29a767
.LSFC_a74e:
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	ld_srib3 a, 0x07, 0xE0, 0xF8	; ld A,(XWA+IZ)
	exts wa                                 ; exts WA
	pushw wa                                ; push WA
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incdi16_24	1, 0x239488
	inc	1, iz
.LSFC_a767:
	ld	wa, (xsp+4)
	inc	1, wa
	cp	iz, wa
	jr ge, .LSFC_a78b                      ; [69 1b] jr GE,0x29a78b
	ld	wa, (xsp+2)
	decm	1, (xsp+2)
	cps	wa, 0
	jr gt, .LSFC_a74e                      ; [6a d4] jr GT,0x29a74e
	jr t, .LSFC_a78b                       ; [68 0f] jr T,0x29a78b
.LSFC_a77c:
	pushw 0x0030
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incdi16_24	1, 0x239488
.LSFC_a78b:
	ld	wa, (xsp+2)
	decm	1, (xsp+2)
	cps	wa, 0
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
	incdi16_24	1, 0x239488
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
	incdi16_24	1, 0x239488
	incm	1, (xsp+26)
.LSFC_a7ea:
	cpw	(xsp+26), 0x0000
	jr ge, .LSFC_a7fb                      ; [69 0a] jr GE,0x29a7fb
	ld	wa, (xsp+20)
	decm	1, (xsp+20)
	cps	wa, 0
	jr nz, .LSFC_a7b5                      ; [6e ba] jr NZ,0x29a7b5
.LSFC_a7fb:
	ld	wa, (xsp+4)
	inc	1, wa
	cp	iz, wa
	jr lt, .LSFC_a81f                      ; [61 1b] jr LT,0x29a81f
	jr t, .LSFC_a843                       ; [68 3d] jr T,0x29a843
.LSFC_a806:
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	ld_srib3 a, 0x07, 0xE0, 0xF8	; ld A,(XWA+IZ)
	exts wa                                 ; exts WA
	pushw wa                                ; push WA
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incdi16_24	1, 0x239488
	inc	1, iz
.LSFC_a81f:
	ld	wa, (xsp+4)
	inc	1, wa
	cp	iz, wa
	jr ge, .LSFC_a843                      ; [69 1b] jr GE,0x29a843
	ld	wa, (xsp+20)
	decm	1, (xsp+20)
	cps	wa, 0
	jr gt, .LSFC_a806                      ; [6a d4] jr GT,0x29a806
	jr t, .LSFC_a843                       ; [68 0f] jr T,0x29a843
.LSFC_a834:
	pushw 0x0030
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incdi16_24	1, 0x239488
.LSFC_a843:
	ld	wa, (xsp+20)
	decm	1, (xsp+20)
	cps	wa, 0
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
	incdi16_24	1, 0x239488
.LSFC_a866:
	ld	wa, (xsp+18)
	decm	1, (xsp+18)
	cps	wa, 0
	jr gt, .LSFC_a857                      ; [6a e7] jr GT,0x29a857
.LSFC_a870:
	popw iz                                 ; pop IZ
	inc 4, xsp                              ; inc 4,XSP
	ret

	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
.LSFC_a877:
	cp	(xwa), 0x00
	jr nz, .LSFC_a87f                      ; [6e 03] jr NZ,0x29a87f
	lds	hl, 1
	ret

.LSFC_a87f:
	.byte 0xc5, 0xe0, 0x3f, 0x30           ; cp (XWA+),0x30
	jr z, .LSFC_a877                       ; [66 f2] jr Z,0x29a877
	lds	hl, 0
	ret


HDAE5000_String_Format_Output:	; 0x29A888 (848 bytes)
	; Output handler for string formatter
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
	lda_24 xbc, 0x2f9362
	st_dri3b a, 0x07, 0xE4, 0xE0	; lda XBC,XBC+WA
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
	cp_srib_im 0x07, 0xE0, 0xE8, 0x34	; cp (XWA+DE),0x34
	jr gt, .LSFO_a90a                      ; [6a 0e] jr GT,0x29a90a
	jr t, .LSFO_a91f                       ; [68 21] jr T,0x29a91f
.LSFO_a8fe:
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	stib_dri 0x07, 0xE0, 0xFA, 0x30	; ld (XWA+QIZ),0x30
	dec	1, qiz
.LSFO_a90a:
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	inc_srib 1, 0x07, 0xE0, 0xFA	; inc 1,(XWA+QIZ)
	cp	qiz, 0
	jr le, .LSFO_a91f                      ; [62 08] jr LE,0x29a91f
	cp_srib_im 0x07, 0xE0, 0xFA, 0x39	; cp (XWA+QIZ),0x39
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
	cp_srib_im 0x07, 0xE0, 0xFA, 0x30	; cp (XWA+QIZ),0x30
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
	cps	iz, 0
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
	cpdi16_24	0x239486, 32
	jr z, .LSFO_a9b0                       ; [66 11] jr Z,0x29a9b0
	jr t, .LSFO_a9ba                       ; [68 19] jr T,0x29a9ba
.LSFO_a9a1:
	pushw 0x0020
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incdi16_24	1, 0x239488
.LSFO_a9b0:
	decm	1, (xsp+18)
	cpw	(xsp+18), 0x0000
	jr gt, .LSFO_a9a1                      ; [6a e7] jr GT,0x29a9a1
.LSFO_a9ba:
	cps	iz, 0
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
	incdi16_24	1, 0x239488
.LSFO_a9e7:
	ld	wa, (xsp+16)
	bit	0x01, wa
	jr nz, .LSFO_aa13                      ; [6e 24] jr NZ,0x29aa13
	cpdi16_24	0x239486, 48
	jr z, .LSFO_aa09                       ; [66 11] jr Z,0x29aa09
	jr t, .LSFO_aa13                       ; [68 19] jr T,0x29aa13
.LSFO_a9fa:
	pushw 0x0030
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incdi16_24	1, 0x239488
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
	incdi16_24	1, 0x239488
	cpw	(xsp+26), 0x0000
	jr ge, .LSFO_aa3f                      ; [69 05] jr GE,0x29aa3f
	incm	1, (xsp+26)
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
	incdi16_24	1, 0x239488
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
	incdi16_24	1, 0x239488
.LSFO_aa79:
	ld	c, (xsp+10)
	extz bc                                 ; extz BC
	lda_24 xwa, 0x2f9362
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
	ld_srib3 a, 0x07, 0xE0, 0xFA	; ld A,(XWA+QIZ)
	exts wa                                 ; exts WA
	pushw wa                                ; push WA
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incdi16_24	1, 0x239488
	inc	1, qiz
.LSFO_aad1:
	ld	bc, (xsp+4)
	inc	1, bc
	ld	wa, qiz
	cp	wa, bc
	jr ge, .LSFO_aaf8                      ; [69 1b] jr GE,0x29aaf8
	ld	wa, (xsp+20)
	decm	1, (xsp+20)
	cps	wa, 0
	jr gt, .LSFO_aab7                      ; [6a d0] jr GT,0x29aab7
	jr t, .LSFO_aaf8                       ; [68 0f] jr T,0x29aaf8
.LSFO_aae9:
	pushw 0x0030
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incdi16_24	1, 0x239488
.LSFO_aaf8:
	ld	wa, (xsp+20)
	decm	1, (xsp+20)
	cps	wa, 0
	jr gt, .LSFO_aae9                      ; [6a e7] jr GT,0x29aae9
	decm	1, (xsp+26)
	ld	wa, (xsp+26)
	exts xwa                                ; exts XWA
	push xwa
	ld xwa, (xsp + 0x1a)                    ; ld XWA,(XSP+0x1a)
	push xwa
	calr	0xf8c0
	ld xwa, (xsp + 0x1e)                    ; ld XWA,(XSP+0x1e)
	push xwa
	call HDAE5000_Display_Buffer_Validate
	lda	xsp, (xsp+12)
	ld	iz, hl
	ld	c, (xsp+10)
	extz bc                                 ; extz BC
	lda_24 xwa, 0x2f9362
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
	incdi16_24	1, 0x239488
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
	incdi16_24	1, 0x239488
	ld	qiz, iz
	jr t, .LSFO_ab88                       ; [68 0f] jr T,0x29ab88
.LSFO_ab79:
	pushw 0x0030
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incdi16_24	1, 0x239488
.LSFO_ab88:
	ld	wa, qiz
	inc	1, qiz
	cps	wa, 3
	jr lt, .LSFO_ab79                      ; [61 e7] jr LT,0x29ab79
	jr t, .LSFO_abad                       ; [68 19] jr T,0x29abad
.LSFO_ab94:
	dec	1, iz
	ld xwa, (xsp + 0x16)                    ; ld XWA,(XSP+0x16)
	ld_srib3 a, 0x07, 0xE0, 0xF8	; ld A,(XWA+IZ)
	exts wa                                 ; exts WA
	pushw wa                                ; push WA
	ld xwa, (xsp + 0x0e)                    ; ld XWA,(XSP+0x0e)
	call	(xwa)
	inc 2, xsp                              ; inc 2,XSP
	incdi16_24	1, 0x239488
.LSFO_abad:
	cps	iz, 0
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
	incdi16_24	1, 0x239488
.LSFO_abca:
	decm	1, (xsp+18)
	cpw	(xsp+18), 0x0000
	jr gt, .LSFO_abbb                      ; [6a e7] jr GT,0x29abbb
.LSFO_abd4:
	pop xiz                                 ; pop XIZ
	inc 2, xsp                              ; inc 2,XSP
	ret


HDAE5000_PPI_Block_Copy:	; 0x29ABD8 (237 bytes)
	; PPI block copy/transfer with callback-based byte output.
	; Contains 4 sub-routines: 2 setup variants, 1 callback, 1 int-to-string converter.
	;
	; --- Sub 1: Setup variant 1 (with extra stack param) ---
	; Stack: [+0x08] = buffer ptr, [+0x10] = params, [+0x14] = format data
	dec 4, xsp			; allocate 4 bytes
	ld xwa, (xsp + 8)		; XWA = buffer ptr
	st32_24 0x239482, xwa                 ; [0x239482] = buffer ptr
	ld (xwa), 0x00		; null-terminate buffer
	lda xwa, (xsp + 0x10)		; XWA = &param area
	ld (xsp), xwa			; save to local
	pushw 0x0029			; push callback addr high word
	pushw 0xAC21			; push callback addr low (→ 0x0029AC21)
	lda xwa, (xsp + 4)		; XWA = &callback addr on stack
	push xwa			; push callback ptr
	ld xwa, (xsp + 0x14)		; XWA = format data
	push xwa			; push
	call 2726631			; call 0x299AE7 (PPI transfer engine)
	lda xsp, (xsp + 0x10)		; cleanup 16 bytes
	ret
	;
	; --- Sub 2: Setup variant 2 (simpler) ---
	ld xwa, (xsp + 4)		; XWA = buffer ptr
	st32_24 0x239482, xwa                 ; [0x239482] = buffer ptr
	ld (xwa), 0x00		; null-terminate buffer
	pushw 0x0029			; push callback addr high word
	pushw 0xAC21			; push callback addr low
	lda xwa, (xsp + 0x10)		; XWA = &callback addr on stack
	push xwa			; push callback ptr
	ld xwa, (xsp + 0x10)		; XWA = format data
	push xwa			; push
	call 2726631			; call 0x299AE7
	lda xsp, (xsp + 0x0C)		; cleanup 12 bytes
	ret
	;
	; --- Sub 3: Byte-write callback (called by PPI engine) ---
	; Appends one byte to buffer at [0x239482], advances pointer, null-terminates.
.Lppi_callback:				; 0x29AC21
	ld32_24 xbc, 0x239482                 ; XBC = [0x239482] (current buffer ptr)
	lds32 xwa, 1			; XWA = 1
	addm32_24 0x239482, xwa                ; [0x239482]++ (advance ptr)
	ld wa, (xsp + 4)		; WA = character to write
	ld (xbc), a			; store character at buffer
	ld32_24 xwa, 0x239482                 ; XWA = new buffer ptr
	ld (xwa), 0x00		; null-terminate
	ret
	;
	; --- Sub 4: Integer to base-N string converter ---
	; Stack: [+0x1A] = value, [+0x1C] = output ptr, [+0x20] = radix
	; Handles signed decimal (radix 10), validates radix 2-36.
	; Uses QBC (previous register bank) to hold the working value.
	lda xsp, (xsp - 18)		; allocate 18-byte frame
	push xiz			; save XIZ
	ld xhl, (xsp + 0x1C)		; XHL = output buffer ptr
	lds ix, 0			; IX = 0 (sign = positive)
	ld bc, (xsp + 0x20)		; BC = radix
	cps bc, 2			; radix < 2?
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
	cps wa, 0			; value < 0? (signed check)
	jr ge, .Lppi_div_loop		; → non-negative
	lds ix, 1			; IX = 1 (negative flag)
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
	cps ix, 0			; negative flag set?
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

HDAE5000_Cell_Copy_Buffer:	; 0x29ACC5 (263 bytes)
	; Cell buffer copy + integer-to-string conversion (3 sub-routines).
	;
	; --- Sub 1: Cell copy buffer (0x29ACC5-0x29AD07, 67 bytes) ---
	; Calls multiply/divide utilities, copies 8 bytes via LDIRW.
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
	call 2734267			; call 0x29B8BB (multiply variant 1)
	ld xwa, (xsp + 4)		; reload ptr B
	ld (xwa), xhl			; store result to local
	ld xwa, xiz			; XWA = source ptr
	ld xbc, (xsp + 0x20)		; XBC = format param
	call 2734263			; call 0x29B8B7 (multiply variant 2)
	ld xwa, (xsp + 8)		; reload ptr A
	ld (xwa + 4), xhl		; store result to local+4
.Lccb_copy:
	ld xix, (xsp + 0x18)		; XIX = destination ptr
	lda xiy, (xsp + 0x0C)		; XIY = &local[12] (source)
	lds bc, 4			; BC = 4 (copy 4 words = 8 bytes)
	ldirw				; block copy 16-bit × 4
	pop xiz				; restore XIZ
	lda xsp, (xsp + 0x10)		; deallocate 16-byte frame
	ret
	;
	; --- Sub 2: Signed number format handler (0x29AD08-0x29AD43, 60 bytes) ---
	; Prepends '-' for negative values when radix==10, then calls Sub 3.
.Lccb_sign_handler:			; 0x29AD08
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
	call .Lccb_converter		; call base-N converter
	lda xsp, (xsp + 0x0A)		; cleanup 10 bytes
	dec 1, xhl			; adjust string length for '-'
	ret
.Lccb_unsigned:
	pushw wa			; push radix
	push xbc			; push output ptr
	push xde			; push value
	call .Lccb_converter		; call base-N converter
	lda xsp, (xsp + 0x0A)		; cleanup 10 bytes
	ret
	;
	; --- Sub 3: General base-N string converter (0x29AD44-0x29ADCB, 136 bytes) ---
	; Converts integer to string with radix 2-36.
	; Stack: [+0x36] = value, [+0x3A] = output ptr, [+0x3E] = radix
.Lccb_converter:			; 0x29AD44
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
	call HDAE5000_Divide_Unsigned	; XHL = quotient, XDE = remainder
	add l, 0x30			; convert remainder to ASCII '0'-'9'
	ld xwa, (xsp + 4)		; reload digit ptr
	ld (xwa), l			; store digit char
	cp (xwa), 0x39		; digit > '9'?
	jr le, .Lccb_digit_ok		; → it's 0-9
	addmi8 (xwa), 0x27		; adjust for 'a'-'f' (+0x27)
.Lccb_digit_ok:
	ld xwa, xiz			; XWA = current value
	ld xbc, (xsp + 0x0C)		; XBC = radix
	call HDAE5000_Divide_Signed	; XHL = quotient
	ld xiz, xhl			; XIZ = new quotient
	or xiz, xiz			; quotient == 0?
	jr z, .Lccb_copy_result	; → all digits extracted
	lds32 xwa, 1			; XWA = 1
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

HDAE5000_String_Copy_N:	; 0x29ADCC (64 bytes)
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
	call HDAE5000_String_Length
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

HDAE5000_String_Length:	; 0x29AE0C (24 bytes)
	; Find character in string using block search (cpir)
	; Stack: [+0x04] string ptr, [+0x08] search char (WA), [+0x0A] max count (BC)
	; Returns: XHL = pointer past found char, or 0 if not found
	lds32 xhl, 0			; default: not found
	ld bc, (xsp + 0x0A)		; BC = max count
	cps bc, 0
	ret z				; count=0: return 0
	ld xhl, (xsp + 4)		; XHL = string pointer
	ld wa, (xsp + 8)		; WA (low byte = search char)
	cpir83				; search for A in (XHL), decrement BC
	dec 1, xhl			; back up to found position
	ret z				; found: return pointer
	lds32 xhl, 0			; not found: return 0
	ret

HDAE5000_File_Read:	; 0x29AE24 (123 bytes)
	; Memory comparison (memcmp-like): compares BC bytes at XIX vs XIY
	; Stack: [+0x04] ptr1, [+0x08] ptr2, [+0x0C] length
	; Returns: HL = 0 if equal, HL = signed byte difference if not
	; Optimized: aligns to 4-byte boundary, then compares 32-bit words
	ld bc, (xsp + 12)		; BC = length
	lds hl, 0			; result = 0 (equal)
	cps bc, 0			; length == 0?
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
	ld_spib l, 0xF0			; L = *(XIX++)
	extz hl				; zero-extend L to HL
	ld_spib a, 0xF4			; A = *(XIY++)
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
	lds hl, 0			; clear result (equal so far)
.Lfr_remainder:
	and de, 0x0003			; DE = remaining bytes
	ret z				; return if none
.Lfr_byte_loop2:
	ld_spib l, 0xF0			; L = *(XIX++)
	extz hl				; zero-extend L to HL
	ld_spib a, 0xF4			; A = *(XIY++)
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
	cps bc, 0
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
	cps bc, 0
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
	ldfr_werp WA, 0xE2	; ld QWA, WA - expand to 32-bit
HDAE5000_MemFill__fill_dwords:
	st_dpil XWA, 0xF2	; ld (XIX+), XWA - store 4 bytes
	djnz xbc, HDAE5000_MemFill__fill_dwords	; djnz BC, .fill_dwords
HDAE5000_MemFill__remainder:
	and de, 0x3	; DE = remaining bytes (0-3)
	ret z	; Return if none
HDAE5000_MemFill__fill_bytes:
	lda_dpi XBC, 0xF0	; ld (XIX+), A
	djnz xde, HDAE5000_MemFill__fill_bytes	; djnz DE, .fill_bytes
	ret

HDAE5000_StrCopy:	; 29AF0Bh
	; Copy null-terminated string including terminator
	; Stack: [+0x04] = dest (XDE), [+0x08] = src (XBC)
	; Finds end of dest string, then copies src to that position
	ld xde, (xsp + 4)	; ld XDE, (XSP+0x04) - dest
	ld xhl, xde	; Save original dest
	jr HDAE5000_StrCopy__find_end
HDAE5000_StrCopy__find_loop:
	inc 1, xde	; inc 1, XDE
HDAE5000_StrCopy__find_end:
	cp (xde), 0x0	; cp (XDE), 0 - check for null
	jr nz, HDAE5000_StrCopy__find_loop
	ld xbc, (xsp + 8)	; ld XBC, (XSP+0x08) - src
	jr HDAE5000_StrCopy__copy_check
HDAE5000_StrCopy__copy_loop:
	ld_spib A, 0xE4	; ld A, (XBC+) - read src byte
	lda_dpi XBC, 0xE8	; ld (XDE+), A - write to dest
HDAE5000_StrCopy__copy_check:
	cp (xbc), 0x0	; cp (XBC), 0 - check for null
	jr nz, HDAE5000_StrCopy__copy_loop
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

