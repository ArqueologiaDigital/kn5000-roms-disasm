; =============================================================================
; file_io/misc_ui.asm - Miscellaneous UI and Utilities
; =============================================================================
; Jump insert, file priority, setup, waiting, and filename box UI.
;
; Key routines:
;   JumpInsertFunc                   - Jump insert function
;   FilePriorityFunc                 - File priority handling
;   SetupOkFunc                      - Setup OK handler
;   SetupExitFunc                    - Setup exit handler
;   WaitingFunc                      - Waiting state handler
;   DiskMedleyShowHideFunc           - Disk medley show/hide
;   PsFileNameBoxProc                - Filename input box UI
; =============================================================================

JumpInsertFunc:
	push xiz
	ld xiz, xwa
	sub xbc, 0x1E0003E
	cp xbc, 0x0
	jr lt, LABEL_F950D6
	cp xbc, 0x9
	jr gt, LABEL_F950D6
	add xbc, xbc
	add xbc, 0xEA96E4
	ld bc, (xbc)
	ldada_24 xix, 16339120
	dri4 0x07, 0xF0, 0xE4, 0xD8
LABEL_F950B0:
	.byte 0xaa, 0x0e, 0x20, 0xe8, 0xee, 0x02, 0x41, 0x8a
	.byte 0x96, 0xea, 0x00, 0xe8, 0x81, 0xa1, 0x20, 0x38
	.byte 0xaa, 0x12, 0x20, 0x38, 0x1d, 0x4d, 0x0f, 0xff
	.byte 0xef, 0x60, 0xee, 0x8b, 0x68, 0x11, 0xeb, 0xa9
	.byte 0x68, 0x0d, 0xeb, 0xac, 0x68, 0x09

LABEL_F950D6:
	lds32 xhl, 0
	jr LABEL_F950DF
	ldada_24 xhl, 213234

LABEL_F950DF:
	pop xiz
	ret

FilePriorityFunc:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1E00065
	jr z, LABEL_F95132
	cp xbc, 0x1E00064
	jr z, LABEL_F9512E
	cp xbc, 0x1E00063
	jr z, LABEL_F95127
	cp xbc, 0x1E00062
	jr nz, LABEL_F95132
	ld wa, (xde + 8)
	and wa, 0x1
	sla wa, 2
	ldada_24 xbc, 15374072
	ld_xwa_sril3 0x07, 0xE4, 0xE0
	push xwa
	ld xwa, (xde + 10)
	push xwa
	call LABEL_FF0F4D
	inc 8, xsp
	ld xhl, xiz
	jr LABEL_F95134

LABEL_F95127:
	ldada_24 xhl, 213236
	jr LABEL_F95134

LABEL_F9512E:
	lds32 xhl, 1
	jr LABEL_F95134

LABEL_F95132:
	lds32 xhl, 0

LABEL_F95134:
	pop xiz
	ret

SetupOkFunc:
	cp xbc, 0x1C00007
	jr nz, LABEL_F9514C
	ld xwa, 0x1450030
	ld xbc, 0x1E5000B
	call 0xFA4A63

LABEL_F9514C:
	lds32 xhl, 0
	ret

SetupExitFunc:
	push xiz
	ld xiz, xde
	cp xbc, 0x1C00002
	jr nz, LABEL_F951B6
	ld xde, xiz
	call 0xFA4409
	or xiz, xiz
	jr nz, LABEL_F951B6
	lds wa, 6
	call LABEL_FC56A1
	cps hl, 0
	jr z, LABEL_F951B6
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9660
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call LABEL_FA9752
	stdi8 32578, 72
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000EE
	call LABEL_FA9752
	ld xwa, 0x1450030
	ld xbc, 0x1E5000C
	ld xde, xiz
	call 0xFA4A63

LABEL_F951B6:
	lds32 xhl, 0
	pop xiz
	ret

TechnicsFileNaming:
	dec 4, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 4), xwa
	cp xiz, 0x1C00007
	jr z, LABEL_F95200
	cp xiz, 0x1E0007C
	jr z, LABEL_F951FC
	cp xiz, 0x1E00084
	jr z, LABEL_F951F8
	cp xiz, 0x1E0003A
	jr nz, LABEL_F9523A
	call 0xFA1FC7
	ld xwa, 0x145000E
	ld xbc, xiz
	ld xde, xhl
	call 0xFA4A63
	ld xhl, (xsp + 4)
	jr LABEL_F9523C

LABEL_F951F8:
	lds32 xhl, 1
	jr LABEL_F9523C

LABEL_F951FC:
	lds32 xhl, 6
	jr LABEL_F9523C

LABEL_F95200:
	call 0xFA1FC7
	ld xwa, xhl
	ld xbc, 0x1E0003A
	ld xde, 0x2742C
	call 0xFA9660
	ld xwa, 0x145000E
	ld xbc, 0x1E00086
	ld xde, 0x2742C
	call 0xFA4A63
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	ld xde, 0x1A00067
	call 0xFA9660

LABEL_F9523A:
	lds32 xhl, 0

LABEL_F9523C:
	pop xiz
	inc 4, xsp
	ret

TechnicsFileRename:
	dec 4, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 4), xwa
	cp xiz, 0x1C00007
	jr z, LABEL_F95286
	cp xiz, 0x1E0007C
	jr z, LABEL_F95282
	cp xiz, 0x1E00084
	jr z, LABEL_F9527E
	cp xiz, 0x1E0003A
	jr nz, LABEL_F952BD
	call 0xFA1FC7
	ld xwa, 0x1450022
	ld xbc, xiz
	ld xde, xhl
	call 0xFA4A63
	ld xhl, (xsp + 4)
	jr LABEL_F952BF

LABEL_F9527E:
	lds32 xhl, 1
	jr LABEL_F952BF

LABEL_F95282:
	lds32 xhl, 6
	jr LABEL_F952BF

LABEL_F95286:
	call 0xFA1FC7
	ld xwa, xhl
	ld xbc, 0x1E0003A
	ld xde, 0x2743E
	call 0xFA9660
	ld xwa, 0x1450022
	ld xbc, 0x1E00086
	ld xde, 0x2743E
	call 0xFA4A63
	ld xwa, 0x7B0000
	ld xbc, 0x1C00001
	lds32 xde, 0
	call LABEL_FA9752

LABEL_F952BD:
	lds32 xhl, 0

LABEL_F952BF:
	pop xiz
	inc 4, xsp
	ret

SmfFileNaming:
	dec 4, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 4), xwa
	cp xiz, 0x1C00007
	jr z, LABEL_F9530C
	cp xiz, 0x1E0007C
	jr z, LABEL_F95305
	cp xiz, 0x1E00084
	jr z, LABEL_F95301
	cp xiz, 0x1E0003A
	jr nz, LABEL_F95346
	call 0xFA1FC7
	ld xwa, 0x145002F
	ld xbc, xiz
	ld xde, xhl
	call 0xFA4A63
	ld xhl, (xsp + 4)
	jr LABEL_F95348

LABEL_F95301:
	lds32 xhl, 1
	jr LABEL_F95348

LABEL_F95305:
	ld xhl, 0x8
	jr LABEL_F95348

LABEL_F9530C:
	call 0xFA1FC7
	ld xwa, xhl
	ld xbc, 0x1E0003A
	ld xde, 0x27450
	call 0xFA9660
	ld xwa, 0x145002F
	ld xbc, 0x1E00086
	ld xde, 0x27450
	call 0xFA4A63
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	ld xde, 0x1A0006B
	call 0xFA9660

LABEL_F95346:
	lds32 xhl, 0

LABEL_F95348:
	pop xiz
	inc 4, xsp
	ret

SmfFileRename:
	dec 4, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 4), xwa
	cp xiz, 0x1C00007
	jr z, LABEL_F95395
	cp xiz, 0x1E0007C
	jr z, LABEL_F9538E
	cp xiz, 0x1E00084
	jr z, LABEL_F9538A
	cp xiz, 0x1E0003A
	jr nz, LABEL_F953CC
	call 0xFA1FC7
	ld xwa, 0x1450023
	ld xbc, xiz
	ld xde, xhl
	call 0xFA4A63
	ld xhl, (xsp + 4)
	jr LABEL_F953CE

LABEL_F9538A:
	lds32 xhl, 1
	jr LABEL_F953CE

LABEL_F9538E:
	ld xhl, 0x8
	jr LABEL_F953CE

LABEL_F95395:
	call 0xFA1FC7
	ld xwa, xhl
	ld xbc, 0x1E0003A
	ld xde, 0x27462
	call 0xFA9660
	ld xwa, 0x1450023
	ld xbc, 0x1E00086
	ld xde, 0x27462
	call 0xFA4A63
	ld xwa, 0x7B0019
	ld xbc, 0x1C00001
	lds32 xde, 0
	call LABEL_FA9752

LABEL_F953CC:
	lds32 xhl, 0

LABEL_F953CE:
	pop xiz
	inc 4, xsp
	ret

FormatDiskNaming:
	dec 4, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 4), xwa
	cp xiz, 0x1C00007
	jr z, LABEL_F9541B
	cp xiz, 0x1E0007C
	jr z, LABEL_F95414
	cp xiz, 0x1E00084
	jr z, LABEL_F95410
	cp xiz, 0x1E0003A
	jr nz, LABEL_F95442
	call 0xFA1FC7
	ld xwa, 0x145000B
	ld xbc, xiz
	ld xde, xhl
	call 0xFA4A63
	ld xhl, (xsp + 4)
	jr LABEL_F95444

LABEL_F95410:
	lds32 xhl, 1
	jr LABEL_F95444

LABEL_F95414:
	ld xhl, 0xB
	jr LABEL_F95444

LABEL_F9541B:
	call 0xFA1FC7
	ld xwa, xhl
	ld xbc, 0x1E0003A
	ld xde, 0x27474
	call 0xFA9660
	ld xwa, 0x145000B
	ld xbc, 0x1E00086
	ld xde, 0x27474
	call 0xFA4A63

LABEL_F95442:
	lds32 xhl, 0

LABEL_F95444:
	pop xiz
	inc 4, xsp
	ret

DrawString_Centered:
	lda xsp, (xsp - 12)
	pushw iz
	ld (xsp + 4), de
	ld (xsp + 6), xbc
	ld (xsp + 10), xwa
	ld xwa, (xsp + 6)
	push xwa
	call LABEL_FF0FA0
	inc 4, xsp
	ld (xsp + 2), hl
	lds de, 0
	ld bc, (xsp + 18)
	cpmi16 (xsp + 4), 0x0
	jr ule, LABEL_F954A7

LABEL_F9546E:
	ld iy, (xsp + 2)
	ld iz, de
	add iz, bc
	ld hl, bc
	extz xhl
	ld xwa, (xsp + 10)
	st_d_dri3 0x07, 0xE0, 0xE8
	st_w_dri3 0x07, 0xEC, 0xE8
	add xwa, (xsp + 6)
	cp iz, iy
	jr nc, LABEL_F95493
	ld a, (xwa)
	ld (xix), a
	jr LABEL_F9549E

LABEL_F95493:
	ld hl, (xsp + 2)
	exts xhl
	sub xwa, xhl
	ld a, (xwa)
	ld (xix), a

LABEL_F9549E:
	inc 1, de
	ld wa, de
	cp wa, (xsp + 4)
	jr c, LABEL_F9546E

LABEL_F954A7:
	ld xwa, (xsp + 10)
	dri5 0x07, 0xE0, 0xE8, 0x00, 0x00
	lds hl, 0
	ld de, (xsp + 2)
	inc 1, bc
	cp bc, de
	jr nc, LABEL_F954BD
	ld hl, bc

LABEL_F954BD:
	popw iz
	lda xsp, (xsp + 12)
	retd 0x2

WaitingFunc:
	lda xsp, (xsp - 68)
	push xiz
	ld (xsp + 68), xde
	cp xbc, 0x1C0000B
	jr z, LABEL_F954EC
	cp xbc, 0x1C00001
	jr nz, LABEL_F9552D
	ld xwa, (xsp + 68)
	stda16_24 160906, xwa
	stdi16_24 160908, 0
	jr LABEL_F9552D

LABEL_F954EC:
	ldda8_24 a, 213220
	extz wa
	sla wa, 2
	ldada_24 xbc, 15374104
	ld_xiz_sril3 0x07, 0xE4, 0xE0
	push xiz
	call LABEL_FF0FA0
	inc 4, xsp
	srl hl, 1
	sd24w4 0x8C, 0x74, 0x02, 0x04
	lda xwa, (xsp + 6)
	ld xbc, xiz
	ld de, hl
	calr DrawString_Centered
	stda16_24 160908, xhl
	ld xwa, (xsp + 68)
	lda xde, (xsp + 4)
	ld xbc, 0x1C0000F
	call 0xFA9660

LABEL_F9552D:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 68)
	ret

DiskMedleyShowHideFunc:
	cp xbc, 0x1C00002
	jr z, LABEL_F95554
	cp xbc, 0x1C00001
	jr nz, LABEL_F95554
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9660

LABEL_F95554:
	lds32 xhl, 0
	ret

PsFileNameBoxProc:
	st_l_dri3 0xFD, 0x56, 0xFF
	push xiz
	st_xde_dri3 0xFD, 0xA2, 0x00
	st_xbc_dri3 0xFD, 0xA6, 0x00
	st_xwa_dri3 0xFD, 0xAA, 0x00
	ld_xwa_sril3 0xFD, 0xA6, 0x00
	cp xwa, 0x1C50001
	jrl z, LABEL_F95A80
	cp xwa, 0x1C50000
	jrl z, LABEL_F95A50
	cp xwa, 0x1C00002
	jrl z, LABEL_F95A2F
	cp xwa, 0x1C0001A
	jrl z, LABEL_F959CB
	cp xwa, 0x1C00019
	jrl z, LABEL_F959CB
	cp xwa, 0x1C00018
	jrl z, LABEL_F95957
	cp xwa, 0x1C00017
	jrl z, LABEL_F95957
	cp xwa, 0x1E50002
	jrl z, LABEL_F95941
	cp xwa, 0x1C0000F
	jrl z, LABEL_F95777
	cp xwa, 0x1C0000B
	jrl z, LABEL_F95669
	cp xwa, 0x1C00001
	jrl nz, LABEL_F95AB0
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	call 0xFA6266
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ldmw (xwa), 0x1
	ld xwa, (xiz + 54)
	ldmw (xwa), 0x1
	ld_xde_sril3 0xFD, 0xAA, 0x00
	ld xwa, (xiz + 34)
	ld xbc, 0x1E50004
	call 0xFA4A63
	cpmi16 (xiz + 46), 0x0
	jr z, LABEL_F95657
	cpmi16 (xiz + 40), 0x1
	jr nz, LABEL_F95631
	cpmi16 (xiz + 38), 0x1
	jr nz, LABEL_F95631
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	ld xbc, 0x1C00017
	lds32 xde, 0
	call 0xF9A579
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	ld xbc, 0x1C00018
	lds32 xde, 0
	jr LABEL_F9564D

LABEL_F95631:
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	ld xbc, 0x1C00018
	lds32 xde, 0
	call 0xF9A579
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	ld xbc, 0x1C00017
	lds32 xde, 0

LABEL_F9564D:
	call 0xF9A58A
	lds wa, 1
	call 0xF9A53B

LABEL_F95657:
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	ld_xbc_sril3 0xFD, 0xA6, 0x00
	ld_xde_sril3 0xFD, 0xA2, 0x00
	jrl LABEL_F95ABF

LABEL_F95669:
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	ld_xbc_sril3 0xFD, 0xA6, 0x00
	ld_xde_sril3 0xFD, 0xA2, 0x00
	call 0xFA4409
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	call 0xFA6266
	ld (xsp + 14), xhl
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 34)
	ld_xbc_sril3 0xFD, 0xA6, 0x00
	ld_xde_sril3 0xFD, 0xA2, 0x00
	call 0xFA4A63
	ld xwa, (xsp + 14)
	cpmi16 (xwa + 38), 0x2
	jr lt, LABEL_F95717
	st_a_dri3 0xFD, 0x92, 0x00
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	call 0xF995DD
	st_b_dri3 0xFD, 0x92, 0x00
	ld bc, (xde + 4)
	sub bc, (xde)
	exts xbc
	ld xwa, (xsp + 14)
	mrdw3 0x98, 0x26, 0x59
	ld (xsp + 8), bc
	ld wa, (xde + 2)
	inc 1, wa
	st_wa_dri3 0xFD, 0xA0, 0x00
	ld wa, (xde + 6)
	dec 1, wa
	st_wa_dri3 0xFD, 0x9C, 0x00
	ldmw (xsp + 12), 0x1
	jr LABEL_F9570C

LABEL_F956E4:
	ld wa, (xsp + 8)
	mrdw3 0x9F, 0x0C, 0x40
	ld_bc_sriw3 0xFD, 0x92, 0x00
	add bc, wa
	dec 1, bc
	st_w_dri3 0xFD, 0x9E, 0x00
	ld (xwa), bc
	st_a_dri3 0xFD, 0x9A, 0x00
	ld de, (xwa)
	ld (xbc), de
	lds de, 7
	call 0xFAA98A
	incm 1, (xsp + 12)

LABEL_F9570C:
	ld xwa, (xsp + 14)
	ld wa, (xwa + 38)
	cp (xsp + 12), wa
	jr c, LABEL_F956E4

LABEL_F95717:
	ld xwa, (xsp + 14)
	cpmi16 (xwa + 46), 0x0
	jrl z, LABEL_F95A2A
	cpmi16 (xwa + 40), 0x1
	jr nz, LABEL_F9574E
	cpmi16 (xwa + 38), 0x1
	jr nz, LABEL_F9574E
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	ld xbc, 0x1C00017
	lds32 xde, 0
	call 0xF9A579
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	ld xbc, 0x1C00018
	lds32 xde, 0
	jr LABEL_F9576A

LABEL_F9574E:
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	ld xbc, 0x1C00018
	lds32 xde, 0
	call 0xF9A579
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	ld xbc, 0x1C00017
	lds32 xde, 0

LABEL_F9576A:
	call 0xF9A58A
	lds wa, 1
	call 0xF9A53B
	jrl LABEL_F95A2A

LABEL_F95777:
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	call 0xFA6266
	ld (xsp + 10), xhl
	ld xwa, (xsp + 10)
	ld (xsp + 4), xwa
	ld xwa, (xwa + 50)
	cpmi16 (xwa), 0x0
	jrl z, LABEL_F95A2A
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	ld_xbc_sril3 0xFD, 0xA6, 0x00
	ld_xde_sril3 0xFD, 0xA2, 0x00
	call 0xFA4409
	ld_xwa_sril3 0xFD, 0xA2, 0x00
	or xwa, xwa
	jrl z, LABEL_F95A2A
	ld xwa, (xsp + 10)
	lda xhl, (xwa + 38)
	ld de, (xwa + 40)
	st_a_dri3 0xFD, 0x92, 0x00
	cps de, 1
	jrl nz, LABEL_F95844
	cpmi16 (xhl), 0x1
	jr nz, LABEL_F95844
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	call 0xF995DD
	st_w_dri3 0xFD, 0x92, 0x00
	st_a_dri3 0xFD, 0x9E, 0x00
	call 0xF9979A
	ld_xwa_sril3 0xFD, 0xA2, 0x00
	inc 1, xwa
	push xwa
	lda xwa, (xsp + 22)
	push xwa
	call LABEL_FF0F4D
	inc 8, xsp
	ld xhl, (xsp + 10)
	ld xbc, (xhl + 42)
	lda xde, (xsp + 18)
	lda xix, (xhl + 22)
	ld xwa, (xsp + 4)
	lda xiy, (xwa + 32)
	lda xhl, (xhl + 28)
	cpmi16 (xbc), 0x0
	jr nz, LABEL_F95826
	st_w_dri3 0xFD, 0x92, 0x00
	st_a_dri3 0xFD, 0x9E, 0x00
	ld xhl, (xhl)
	push xhl
	pushm (xiy)
	pushm (xix)
	pushw 0x0
	pushw 0x1
	jr LABEL_F9583D

LABEL_F95826:
	st_w_dri3 0xFD, 0x92, 0x00
	st_a_dri3 0xFD, 0x9E, 0x00
	ld xhl, (xhl)
	push xhl
	pushm (xiy)
	pushm (xix)
	pushw 0x0
	pushw 0x0

LABEL_F9583D:
	call 0xFAD084
	jrl LABEL_F95A2A

LABEL_F95844:
	ld wa, (xhl)
	muls xwa, xde
	ld de, wa
	ld_xwa_sril3 0xFD, 0xA2, 0x00
	ld a, (xwa)
	exts wa
	cp wa, de
	jrl ge, LABEL_F95A2A
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	call 0xF995DD
	st_a_dri3 0xFD, 0x92, 0x00
	lda xwa, (xbc + 4)
	ld (xsp + 14), xwa
	ld de, (xwa)
	sub de, (xbc)
	exts xde
	ld xwa, (xsp + 10)
	mrdw3 0x98, 0x26, 0x5A
	ld (xsp + 8), de
	lda xiy, (xbc + 6)
	lda xix, (xbc + 2)
	ld hl, (xix)
	ld iz, (xiy)
	sub iz, hl
	ld xwa, (xsp + 4)
	ld de, (xwa + 40)
	exts xiz
	divs xiz, xde
	ld_xwa_sril3 0xFD, 0xA2, 0x00
	ld a, (xwa)
	exts wa
	exts xwa
	divs xwa, xde
	ldto_wa_werp 0xE2
	ldfr_wa_werp 0xEA
	ld_xwa_sril3 0xFD, 0xA2, 0x00
	ld a, (xwa)
	exts wa
	exts xwa
	divs xwa, xde
	ld de, wa
	ld wa, iz
	mul_xwa_werp 0xEA
	inc 2, wa
	add hl, wa
	ld (xix), hl
	add hl, iz
	ld (xiy), hl
	ld wa, (xsp + 8)
	mul xwa, xde
	inc 2, wa
	add (xbc), wa
	ld de, (xbc)
	add de, (xsp + 8)
	ld xwa, (xsp + 14)
	ld (xwa), de
	st_b_dri3 0xFD, 0x9E, 0x00
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xix)
	ld (xde + 2), wa
	ld_xwa_sril3 0xFD, 0xA2, 0x00
	inc 1, xwa
	push xwa
	lda xwa, (xsp + 22)
	push xwa
	call LABEL_FF0F4D
	inc 8, xsp
	ld xwa, (xsp + 10)
	ld xix, (xwa + 42)
	ld_xwa_sril3 0xFD, 0xA2, 0x00
	ld a, (xwa)
	ldfr_a_berp 0xF4
	exts iy
	ld xwa, (xsp + 4)
	lda xhl, (xwa + 28)
	st_a_dri3 0xFD, 0x9E, 0x00
	lda xde, (xsp + 18)
	cp iy, (xix)
	jr nz, LABEL_F95929
	st_w_dri3 0xFD, 0x92, 0x00
	ld xhl, (xhl)
	push xhl
	pushw 0x0
	pushw 0xFF
	jr LABEL_F9593A

LABEL_F95929:
	st_w_dri3 0xFD, 0x92, 0x00
	ld xhl, (xhl)
	push xhl
	ld xhl, (xsp + 14)
	pushm (xhl + 32)
	pushm (xhl + 22)

LABEL_F9593A:
	call 0xFACACA
	jrl LABEL_F95A2A

LABEL_F95941:
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	call 0xFA6266
	ld xbc, (xhl + 42)
	ld_xwa_sril3 0xFD, 0xA2, 0x00
	ld (xbc), wa
	jrl LABEL_F95A2A

LABEL_F95957:
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	call 0xFA6266
	ld xiz, xhl
	ld xwa, (xiz + 34)
	ld_xbc_sril3 0xFD, 0xA6, 0x00
	ld_xde_sril3 0xFD, 0xA2, 0x00
	call 0xFA4A63
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	ld_xbc_sril3 0xFD, 0xA6, 0x00
	ld_xde_sril3 0xFD, 0xA2, 0x00
	call 0xFA4409
	cpmi16 (xiz + 48), 0x0
	jrl z, LABEL_F95A2A
	ld_xwa_sril3 0xFD, 0xA2, 0x00
	or xwa, xwa
	jrl nz, LABEL_F95A2A
	ld_xwa_sril3 0xFD, 0xA6, 0x00
	cp xwa, 0x1C00017
	jr nz, LABEL_F959B6
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	ld xbc, 0x1C00019
	ld_xde_sril3 0xFD, 0xA2, 0x00
	jr LABEL_F959C5

LABEL_F959B6:
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	ld xbc, 0x1C0001A
	ld_xde_sril3 0xFD, 0xA2, 0x00

LABEL_F959C5:
	call 0xF9A5BD
	jr LABEL_F95A2A

LABEL_F959CB:
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	ld_xbc_sril3 0xFD, 0xA6, 0x00
	ld_xde_sril3 0xFD, 0xA2, 0x00
	call 0xFA4409
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	call 0xFA6266
	cpmi16 (xhl + 48), 0x0
	jr z, LABEL_F95A2A
	ld_xwa_sril3 0xFD, 0xA2, 0x00
	or xwa, xwa
	jr nz, LABEL_F95A2A
	ld xwa, (xhl + 54)
	cpmi16 (xwa), 0x0
	jr z, LABEL_F95A2A
	ld_xbc_sril3 0xFD, 0xA6, 0x00
	ld xwa, (xhl + 34)
	cp xbc, 0x1C00019
	jr nz, LABEL_F95A1C
	ld xbc, 0x1C00017
	ld_xde_sril3 0xFD, 0xA2, 0x00
	jr LABEL_F95A26

LABEL_F95A1C:
	ld xbc, 0x1C00018
	ld_xde_sril3 0xFD, 0xA2, 0x00

LABEL_F95A26:
	call 0xFA4A63

LABEL_F95A2A:
	lds32 xhl, 0
	jrl LABEL_F95AC3

LABEL_F95A2F:
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	call 0xFA6266
	ld xwa, (xhl + 50)
	ldmw (xwa), 0x0
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	ld_xbc_sril3 0xFD, 0xA6, 0x00
	ld_xde_sril3 0xFD, 0xA2, 0x00
	jr LABEL_F95ABF

LABEL_F95A50:
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	call 0xFA6266
	ld xbc, (xhl + 50)
	ld_xwa_sril3 0xFD, 0xA2, 0x00
	or xwa, xwa
	jr z, LABEL_F95A6B
	ldmw (xbc), 0x0
	jr LABEL_F95A6F

LABEL_F95A6B:
	ldmw (xbc), 0x1

LABEL_F95A6F:
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	ld_xbc_sril3 0xFD, 0xA6, 0x00
	ld_xde_sril3 0xFD, 0xA2, 0x00
	jr LABEL_F95ABF

LABEL_F95A80:
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	call 0xFA6266
	ld xbc, (xhl + 54)
	ld_xwa_sril3 0xFD, 0xA2, 0x00
	or xwa, xwa
	jr z, LABEL_F95A9B
	ldmw (xbc), 0x0
	jr LABEL_F95A9F

LABEL_F95A9B:
	ldmw (xbc), 0x1

LABEL_F95A9F:
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	ld_xbc_sril3 0xFD, 0xA6, 0x00
	ld_xde_sril3 0xFD, 0xA2, 0x00
	jr LABEL_F95ABF

LABEL_F95AB0:
	ld_xwa_sril3 0xFD, 0xAA, 0x00
	ld_xbc_sril3 0xFD, 0xA6, 0x00
	ld_xde_sril3 0xFD, 0xA2, 0x00

LABEL_F95ABF:
	call 0xFA4409

LABEL_F95AC3:
	pop xiz
	st_l_dri3 0xFD, 0xAA, 0x00
	ret

