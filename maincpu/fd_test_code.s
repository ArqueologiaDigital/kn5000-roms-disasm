; FDLoadSaveTest — Floppy disk save/load diagnostic test
; Allocates a 2KB buffer, fills it with a counting pattern (0..0x3FF),
; opens a test file via FileOpen, writes the buffer (FileWrite),
; closes and reopens the file, reads it back (FileRead), then
; compares read-back data against the original pattern byte-by-byte.
; Logs progress and errors via FDTest_PrintDiag (diagnostic print).
; Returns: hl = 0 on success, 0xFFFF on any failure
FDLoadSaveTest:
	dec 4, xsp
	push xiz
	lda_24 xwa, 0xe1fe56
	calr FDTest_PrintDiag
	lda_24 xwa, 0xe1fe46
	push xwa
	call FileOpenDefault
	inc 4, xsp
	cps hl, 0
	jr z, FDTest_OpenFailed
	lda_24 xwa, 0xe1fe66
	calr FDTest_PrintDiag
	jr FDTest_AllocBuffer

FDTest_OpenFailed:
	lda_24 xwa, 0xe1fe6e
	calr FDTest_PrintDiag

FDTest_AllocBuffer:
	pushw 0x800
	call Malloc
	inc 2, xsp
	ld (xsp + 4), xhl
	ld xwa, xhl
	or xwa, xwa
	jr nz, FDTest_FillBuffer
	lda_24 xwa, 0xe1fe72
	calr FDTest_PrintDiag
	ld xwa, (xsp + 4)
	push xwa
	call Free
	inc 4, xsp
	ldw hl, 0xFFFF
	jrl FDTest_Return

FDTest_FillBuffer:
	ld xwa, (xsp + 4)
	lds bc, 0
	cp bc, 0x400
	jr nc, FDTest_OpenForWrite

FDTest_FillLoop:
	st_dpiw BC, 0xE1
	inc 1, bc
	cp bc, 0x400
	jr c, FDTest_FillLoop

FDTest_OpenForWrite:
	lda_24 xwa, 0xe1fe86
	push xwa
	lda_24 xwa, 0xe1fe46
	push xwa
	call FileOpen
	inc 8, xsp
	ld xiz, xhl
	or xiz, xiz
	jr nz, FDTest_WriteBuffer
	lda_24 xwa, 0xe1fe8a
	calr FDTest_PrintDiag
	ld xwa, (xsp + 4)
	push xwa
	call Free
	inc 4, xsp
	ldw hl, 0xFFFF
	jrl FDTest_Return

FDTest_WriteBuffer:
	lda_24 xwa, 0xe1fea2
	calr FDTest_PrintDiag
	push xiz
	pushw 0x800
	pushw 0x1
	ld xwa, (xsp + 12)
	push xwa
	call FileWrite
	lda xsp, (xsp + 12)
	cp hl, 0x800
	jr z, FDTest_CloseAndReopen
	lda_24 xwa, 0xe1feb2
	calr FDTest_PrintDiag
	ld xwa, (xsp + 4)
	push xwa
	call Free
	inc 4, xsp
	ldw hl, 0xFFFF
	jrl FDTest_Return

FDTest_CloseAndReopen:
	lda_24 xwa, 0xe1feba
	calr FDTest_PrintDiag
	push xiz
	call FileClose
	pushw 0x800
	pushw 0x0
	ld xwa, (xsp + 12)
	push xwa
	call Memset
	lda xsp, (xsp + 12)
	lda_24 xwa, 0xe1febe
	calr FDTest_PrintDiag
	lda_24 xwa, 0xe1fecc
	push xwa
	lda_24 xwa, 0xe1fe46
	push xwa
	call FileOpen
	inc 8, xsp
	ld xiz, xhl
	or xiz, xiz
	jr nz, FDTest_ReadBack
	lda_24 xwa, 0xe1fed0
	calr FDTest_PrintDiag
	ld xwa, (xsp + 4)
	push xwa
	call Free
	inc 4, xsp
	ldw hl, 0xFFFF
	jrl FDTest_Return

FDTest_ReadBack:
	push xiz
	pushw 0x800
	pushw 0x1
	ld xwa, (xsp + 12)
	push xwa
	call FileRead
	lda xsp, (xsp + 12)
	cp hl, 0x800
	jr z, FDTest_VerifyData
	lda_24 xwa, 0xe1fee8
	calr FDTest_PrintDiag
	ld xwa, (xsp + 4)
	push xwa
	call Free
	inc 4, xsp
	ldw hl, 0xFFFF
	jr FDTest_Return

FDTest_VerifyData:
	lda_24 xwa, 0xe1fef0
	calr FDTest_PrintDiag
	push xiz
	call FileClose
	inc 4, xsp
	ld xwa, (xsp + 4)
	lds iz, 0
	lds bc, 0
	cp bc, 0x400
	jr nc, FDTest_CompareResult

FDTest_CompareLoop:
	cpm_spiw BC, 0xE1
	jr z, FDTest_CompareNext
	inc 1, iz

FDTest_CompareNext:
	inc 1, bc
	cp bc, 0x400
	jr c, FDTest_CompareLoop

FDTest_CompareResult:
	lda_24 xwa, 0xe1fef4
	calr FDTest_PrintDiag
	cps iz, 0
	jr z, FDTest_Pass
	lda_24 xwa, 0xe1ff06
	calr FDTest_PrintDiag
	ld xwa, (xsp + 4)
	push xwa
	call Free
	inc 4, xsp
	ldw hl, 0xFFFF
	jr FDTest_Return

FDTest_Pass:
	ld xwa, (xsp + 4)
	push xwa
	call Free
	inc 4, xsp
	lda_24 xwa, 0xe1ff16
	calr FDTest_PrintDiag
	lds hl, 0

FDTest_Return:
	pop xiz
	inc 4, xsp
	ret

; ListDirectoryEntries (FDListDirectory)
; Opens a directory (via 0xF5298A) using the path at (xsp+4) and the
; format string at 0xE1FF1A.  Iterates all entries with ReadNextEntry
; (0xF52AE8), logging each via FDTest_PrintDiag.  Closes the directory
; handle (0xF52AAA) when done.
; Args: (xsp+4) = path string pointer
; Returns: hl = 0 on success, 0xFFFF on open failure
; Stack frame: 266 bytes (local buffer at xsp+10 used as formatted string)
FDListDirectory:
	lda xsp, (xsp - 266)
	push xiz
	lds wa, 0
	lda_24 xwa, 0xe1ff1a
	lda xbc, (xsp + 4)
	call 0xF5298A
	ld xiz, xhl
	ld xwa, xiz
	cp xwa, 0xFFFFFFFF
	jr nz, FDListDir_LogEntry
	ldw hl, 0xFFFF
	jr FDListDir_Return

FDListDir_LogEntry:
	lda xwa, (xsp + 10)
	calr FDTest_PrintDiag
	ld xwa, xiz
	lda xbc, (xsp + 4)
	call 0xF52AE8
	cp hl, 0xFFFF
	jr z, FDListDir_CloseDir

FDListDir_NextEntry:
	lda xwa, (xsp + 10)
	calr FDTest_PrintDiag
	ld xwa, xiz
	lda xbc, (xsp + 4)
	call 0xF52AE8
	cp hl, 0xFFFF
	jr nz, FDListDir_NextEntry

FDListDir_CloseDir:
	ld xwa, xiz
	call 0xF52AAA
	lds hl, 0

FDListDir_Return:
	pop xiz
	lda xsp, (xsp + 266)
	ret

; FDTestDialogEventHandler (FDTestDialogProc)
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
FDTestDialogProc:
	lda xsp, (xsp - 264)
	ld (xsp + 8), 0x0
	ld xwa, xbc
	cp xwa, 0x1E0008D
	jr z, FDTestDlg_FormatDisplay
	sub xwa, 0x1C00017
	cp xwa, 0x0
	jr lt, FDTestDlg_Unhandled
	cp xwa, 0x6
	jr gt, FDTestDlg_Unhandled
	add xwa, xwa
	add xwa, 0xE1FF34
	ld wa, (xwa)
	lda_24 xix, FDTestDlg_DefaultCase
	jp_dri 8, 0x07, 0xF0, 0xE0

FDTestDlg_DefaultCase:
	lds32 xhl, 0
	jr FDTestDlg_Return

FDTestDlg_FormatDisplay:
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
	jr FDTestDlg_Return

FDTestDlg_Unhandled:
	lds32 xhl, 0

FDTestDlg_Return:
	lda xsp, (xsp + 264)
	ret

; HamaListProc — Event handler for the FD test list widget
; Handles event 0x1E00086 (list item selection): calls 0xFA6266 to get
; the widget state, reads the data pointer at offset 42, then calls
; Strcpy to load/save the selected file.
; All other events are forwarded to the default handler (0xFA4409).
; Args: xbc = event ID, xde = event parameter
; Returns: xhl = 0 (handled) or forwarded result
HamaListProc:
	push xiz
	ld xiz, xde
	ld xde, xbc
	cp xde, 0x1E00086
	jr z, HamaList_HandleSelect
	ld xde, xiz
	call 0xFA4409
	jr HamaList_Return

HamaList_HandleSelect:
	call 0xFA6266
	ld xwa, xiz
	push xwa
	ld xwa, (xhl + 42)
	push xwa
	call Strcpy
	inc 8, xsp
	lds32 xhl, 0

HamaList_Return:
	pop xiz
	ret
