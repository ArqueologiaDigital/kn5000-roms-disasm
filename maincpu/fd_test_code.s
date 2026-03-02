; FDLoadSaveTest — Floppy disk save/load diagnostic test
; Allocates a 2KB buffer, fills it with a counting pattern (0..0x3FF),
; opens a test file via LABEL_F4EB97, writes the buffer (LABEL_F4EEB9),
; closes and reopens the file, reads it back (LABEL_F4EE70), then
; compares read-back data against the original pattern byte-by-byte.
; Logs progress and errors via LABEL_F1E396 (diagnostic print).
; Returns: hl = 0 on success, 0xFFFF on any failure
FDLoadSaveTest:
	dec 4, xsp
	push xiz
	lda_24 xwa, 0xe1fe56
	calr LABEL_F1E396
	lda_24 xwa, 0xe1fe46
	push xwa
	call LABEL_F4F21F
	inc 4, xsp
	cps hl, 0
	jr z, LABEL_F1E5FF
	lda_24 xwa, 0xe1fe66
	calr LABEL_F1E396
	jr LABEL_F1E607

LABEL_F1E5FF:
	lda_24 xwa, 0xe1fe6e
	calr LABEL_F1E396

LABEL_F1E607:
	pushw 0x800
	call LABEL_FF0E80
	inc 2, xsp
	ld (xsp + 4), xhl
	ld xwa, xhl
	or xwa, xwa
	jr nz, LABEL_F1E631
	lda_24 xwa, 0xe1fe72
	calr LABEL_F1E396
	ld xwa, (xsp + 4)
	push xwa
	call LABEL_FF0AF2
	inc 4, xsp
	ldw hl, 0xFFFF
	jrl LABEL_F1E796

LABEL_F1E631:
	ld xwa, (xsp + 4)
	lds bc, 0
	cp bc, 0x400
	jr nc, LABEL_F1E647

LABEL_F1E63C:
	st_dpiw BC, 0xE1
	inc 1, bc
	cp bc, 0x400
	jr c, LABEL_F1E63C

LABEL_F1E647:
	lda_24 xwa, 0xe1fe86
	push xwa
	lda_24 xwa, 0xe1fe46
	push xwa
	call LABEL_F4EB97
	inc 8, xsp
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_F1E677
	lda_24 xwa, 0xe1fe8a
	calr LABEL_F1E396
	ld xwa, (xsp + 4)
	push xwa
	call LABEL_FF0AF2
	inc 4, xsp
	ldw hl, 0xFFFF
	jrl LABEL_F1E796

LABEL_F1E677:
	lda_24 xwa, 0xe1fea2
	calr LABEL_F1E396
	push xiz
	pushw 0x800
	pushw 0x1
	ld xwa, (xsp + 12)
	push xwa
	call LABEL_F4EEB9
	lda xsp, (xsp + 12)
	cp hl, 0x800
	jr z, LABEL_F1E6AF
	lda_24 xwa, 0xe1feb2
	calr LABEL_F1E396
	ld xwa, (xsp + 4)
	push xwa
	call LABEL_FF0AF2
	inc 4, xsp
	ldw hl, 0xFFFF
	jrl LABEL_F1E796

LABEL_F1E6AF:
	lda_24 xwa, 0xe1feba
	calr LABEL_F1E396
	push xiz
	call LABEL_F4F05A
	pushw 0x800
	pushw 0x0
	ld xwa, (xsp + 12)
	push xwa
	call LABEL_FF0FFA
	lda xsp, (xsp + 12)
	lda_24 xwa, 0xe1febe
	calr LABEL_F1E396
	lda_24 xwa, 0xe1fecc
	push xwa
	lda_24 xwa, 0xe1fe46
	push xwa
	call LABEL_F4EB97
	inc 8, xsp
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_F1E705
	lda_24 xwa, 0xe1fed0
	calr LABEL_F1E396
	ld xwa, (xsp + 4)
	push xwa
	call LABEL_FF0AF2
	inc 4, xsp
	ldw hl, 0xFFFF
	jrl LABEL_F1E796

LABEL_F1E705:
	push xiz
	pushw 0x800
	pushw 0x1
	ld xwa, (xsp + 12)
	push xwa
	call LABEL_F4EE70
	lda xsp, (xsp + 12)
	cp hl, 0x800
	jr z, LABEL_F1E734
	lda_24 xwa, 0xe1fee8
	calr LABEL_F1E396
	ld xwa, (xsp + 4)
	push xwa
	call LABEL_FF0AF2
	inc 4, xsp
	ldw hl, 0xFFFF
	jr LABEL_F1E796

LABEL_F1E734:
	lda_24 xwa, 0xe1fef0
	calr LABEL_F1E396
	push xiz
	call LABEL_F4F05A
	inc 4, xsp
	ld xwa, (xsp + 4)
	lds iz, 0
	lds bc, 0
	cp bc, 0x400
	jr nc, LABEL_F1E75F

LABEL_F1E750:
	cpm_spiw BC, 0xE1
	jr z, LABEL_F1E757
	inc 1, iz

LABEL_F1E757:
	inc 1, bc
	cp bc, 0x400
	jr c, LABEL_F1E750

LABEL_F1E75F:
	lda_24 xwa, 0xe1fef4
	calr LABEL_F1E396
	cps iz, 0
	jr z, LABEL_F1E782
	lda_24 xwa, 0xe1ff06
	calr LABEL_F1E396
	ld xwa, (xsp + 4)
	push xwa
	call LABEL_FF0AF2
	inc 4, xsp
	ldw hl, 0xFFFF
	jr LABEL_F1E796

LABEL_F1E782:
	ld xwa, (xsp + 4)
	push xwa
	call LABEL_FF0AF2
	inc 4, xsp
	lda_24 xwa, 0xe1ff16
	calr LABEL_F1E396
	lds hl, 0

LABEL_F1E796:
	pop xiz
	inc 4, xsp
	ret

; ListDirectoryEntries (LABEL_F1E79A)
; Opens a directory (via 0xF5298A) using the path at (xsp+4) and the
; format string at 0xE1FF1A.  Iterates all entries with ReadNextEntry
; (0xF52AE8), logging each via LABEL_F1E396.  Closes the directory
; handle (0xF52AAA) when done.
; Args: (xsp+4) = path string pointer
; Returns: hl = 0 on success, 0xFFFF on open failure
; Stack frame: 266 bytes (local buffer at xsp+10 used as formatted string)
LABEL_F1E79A:
	lda xsp, (xsp - 266)
	push xiz
	lds wa, 0
	lda_24 xwa, 0xe1ff1a
	lda xbc, (xsp + 4)
	call 0xF5298A
	ld xiz, xhl
	ld xwa, xiz
	cp xwa, 0xFFFFFFFF
	jr nz, LABEL_F1E7BF
	ldw hl, 0xFFFF
	jr LABEL_F1E7F1

LABEL_F1E7BF:
	lda xwa, (xsp + 10)
	calr LABEL_F1E396
	ld xwa, xiz
	lda xbc, (xsp + 4)
	call 0xF52AE8
	cp hl, 0xFFFF
	jr z, LABEL_F1E7E9

LABEL_F1E7D4:
	lda xwa, (xsp + 10)
	calr LABEL_F1E396
	ld xwa, xiz
	lda xbc, (xsp + 4)
	call 0xF52AE8
	cp hl, 0xFFFF
	jr nz, LABEL_F1E7D4

LABEL_F1E7E9:
	ld xwa, xiz
	call 0xF52AAA
	lds hl, 0

LABEL_F1E7F1:
	pop xiz
	lda xsp, (xsp + 266)
	ret

; FDTestDialogEventHandler (LABEL_F1E7F8)
; Event handler for the FD SAVE/LOAD TEST dialog.
; Dispatches on the 32-bit event ID in xbc:
;   0x1E0008D  → Format and display event parameter (xde) via 0xFA44D0,
;                 then send event 0x1E0008C via 0xFA9660.
;   0x1C00017..0x1C0001D (7 entries) → Jump table at 0xE1FF34 (word offsets
;                 added to xix base, dispatched via jp_dri).
;   All others → Return 0 (unhandled).
; Args: xbc = event ID, xde = event parameter
; Returns: xhl = 0
; Stack frame: 264 bytes
LABEL_F1E7F8:
	lda xsp, (xsp - 264)
	ld (xsp + 8), 0x0
	ld xwa, xbc
	cp xwa, 0x1E0008D
	jr z, LABEL_F1E839
	sub xwa, 0x1C00017
	cp xwa, 0x0
	jr lt, LABEL_F1E868
	cp xwa, 0x6
	jr gt, LABEL_F1E868
	add xwa, xwa
	add xwa, 0xE1FF34
	ld wa, (xwa)
	lda_24 xix, LABEL_F1E835
	jp_dri 8, 0x07, 0xF0, 0xE0

LABEL_F1E835:
	lds32 xhl, 0
	jr LABEL_F1E86A

LABEL_F1E839:
	ld xwa, xde
	srl xwa, 0
	ldi_werp 0xE2, 0
	.byte 0xbf, 0x00, 0x50	; ld (xsp + 0), wa
	ld (xsp + 2), de
	lda_24 xwa, 0xe1ff1e
	ld (xsp + 4), xwa
	call 0xFA44D0
	lda xwa, (xsp)
	ld xbc, xwa
	ld xwa, xhl
	ld xde, xbc
	ld xbc, 0x1E0008C
	call 0xFA9660
	lds32 xhl, 0
	jr LABEL_F1E86A

LABEL_F1E868:
	lds32 xhl, 0

LABEL_F1E86A:
	lda xsp, (xsp + 264)
	ret

; HamaListProc — Event handler for the FD test list widget
; Handles event 0x1E00086 (list item selection): calls 0xFA6266 to get
; the widget state, reads the data pointer at offset 42, then calls
; LABEL_FF0F4D to load/save the selected file.
; All other events are forwarded to the default handler (0xFA4409).
; Args: xbc = event ID, xde = event parameter
; Returns: xhl = 0 (handled) or forwarded result
HamaListProc:
	push xiz
	ld xiz, xde
	ld xde, xbc
	cp xde, 0x1E00086
	jr z, LABEL_F1E885
	ld xde, xiz
	call 0xFA4409
	jr LABEL_F1E898

LABEL_F1E885:
	call 0xFA6266
	ld xwa, xiz
	push xwa
	ld xwa, (xhl + 42)
	push xwa
	call LABEL_FF0F4D
	inc 8, xsp
	lds32 xhl, 0

LABEL_F1E898:
	pop xiz
	ret
