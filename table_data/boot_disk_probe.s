; =============================================================================
; BOOT-TIME FLOPPY DISK-FORMAT PROBE
; =============================================================================
; ROM range 0x9feb2b-0x9fec6d.  Boot-time alias: this code executes from
; 0xffeb2b-0xffec6d (at reset the CPU sees this ROM at 0xe00000-0xffffff;
; labels below are at ROM addresses, all absolute references in comments give
; the boot-time 0xffxxxx form).
;
; Replaces the former "Boot ROM Utility Routines ... motor control / VGA
; display / progress bar" description of includes/bootcode_utils.bin, which
; was wrong: bytes 0x9feb2b-0x9fec6d are the bootloader's floppy-disk-format
; probe helpers sitting on top of the FDC driver's public request interface
; (FDC_Request, boot 0xffe944).  The CP-serial half of the old blob follows
; in boot_cpserial.s.
;
; Disk presence is sensed on Port D bit 6, the floppy disk-change input (same
; line the runtime firmware samples in Check_for_Floppy_Disk_Change; the
; signal is active-low disk-present / disk-change).
; =============================================================================

; -----------------------------------------------------------------------------
; Boot_PulsePD0 - pulse Port D bit 0 high for 10 timer ticks, then low
; Sets PD0, waits 10 ticks (Boot_Delay), clears PD0 and tail-calls a second
; 10-tick delay.
; Inputs:  none (clobbers WA)
; Outputs: none
; Callers: NONE FOUND -- no call/calr/jrl/pointer reference anywhere in the
;          table_data or maincpu ROMs (boot- or run-time address).  Retained
;          factory/diagnostic code.  The board function of the PD0 line is
;          not identified yet; TODO: identify what PD0 drives.
; -----------------------------------------------------------------------------
Boot_PulsePD0:
	set_dd8	0, 0x34			; PD0 = 1
	ldw	wa, 10
	calr	Boot_Delay
	res_dd8	0, 0x34			; PD0 = 0
	ldw	wa, 10
	jrl	t, Boot_Delay		; tail call: second 10-tick delay

; -----------------------------------------------------------------------------
; FDC_ProbeDiskFormat - probe the inserted floppy's format via 5 FDC requests
; Builds five 14-byte FDC request blocks at 0x0d52 (the exact layout
; FDC_Request unpacks into 0x0c6e+: u16 cmd, u16, u16 head, u16 track,
; u16 sector, u16 count, u32 buffer) and submits them by pushing the block
; address:
;   1. cmd 0 (recalibrate), track field 0x00e0 (the 0x00d3 alternative below
;      is dead: A is always 0 here, so the NZ branch never runs)
;   2-5. cmd 3 (read sector), track 0 / 78 / 10 / 40, sector 1, count 1,
;      buffer 0x0d62 -- four single-sector reads at spread-out tracks whose
;      pass/fail pattern reveals the media format (2DD-9/2DD-8/2HD-18, cf.
;      the geometry presets at boot 0xffdbad)
; Afterwards waits 200 ticks and increments the probe-pass counter (0x104c).
; Inputs:  none.  Returns immediately if Port D bit 6 signals no disk.
;          Entry sets PHFC (0x47) = 0x1e (Port H pin function select).
; Outputs: read data at 0x0d62; FDC error state via FDC_Request's sticky
;          error at (0x0c52); (0x104c) incremented
; Callers: NONE FOUND -- no static reference anywhere in table_data or
;          maincpu ROMs.  Retained factory/diagnostic code (the shipped
;          update path drives FDC_Request directly instead).
; -----------------------------------------------------------------------------
FDC_ProbeDiskFormat:
	ldio	0x47, 0x1e		; PHFC = 0x1e
	bit_dd8	6, 0x34			; PD6: disk-change/no-disk strap
	ret	nz			; no disk -> abort probe
	ldb	a, 0
	; --- request 1: recalibrate (cmd 0) ---
	ldw	(0x0d52:16), 0		; +0x00 cmd = 0 (recalibrate)
	ldw	(0x0d54:16), 0		; +0x02 = 0
	ldw	(0x0d56:16), 0		; +0x04 head = 0
	cp	a, 0:i3			; A is 0 -> always EQ (0x00d3 arm is dead)
	jr	nz, FDC_ProbeDiskFormat__recal_alt
	ldw	(0x0d58:16), 0xe0		; +0x06 track/format field = 0x00e0
	jr	FDC_ProbeDiskFormat__recal_done
FDC_ProbeDiskFormat__recal_alt:
	ldw	(0x0d58:16), 0xd3		; dead code: alternate format field
FDC_ProbeDiskFormat__recal_done:
	ldw	(0x0d5a:16), 0		; +0x08 sector = 0
	ldw	(0x0d5c:16), 0		; +0x0a count = 0
	ld	xwa, 0:i3
	ld	(0x0d5e:16), xwa		; +0x0c buffer = NULL
	lda	xwa, (0x0d52:16)
	push	xwa
	calr	FDC_Request
	; --- request 2: read track 0, sector 1, count 1 ---
	ldw	(0x0d52:16), 3		; cmd = 3 (read sectors)
	ldw	(0x0d54:16), 0
	ldw	(0x0d56:16), 0
	ldw	(0x0d58:16), 0		; track 0
	ldw	(0x0d5a:16), 1		; sector 1
	ldw	(0x0d5c:16), 1		; count 1
	lda	xwa, (0x0d62:16)
	ld	(0x0d5e:16), xwa		; buffer = 0x0d62
	lda	xwa, (0x0d52:16)
	push	xwa
	calr	FDC_Request
	; --- request 3: read track 78 ---
	ldw	(0x0d52:16), 3
	ldw	(0x0d54:16), 0
	ldw	(0x0d56:16), 0
	ldw	(0x0d58:16), 78
	ldw	(0x0d5a:16), 1
	ldw	(0x0d5c:16), 1
	lda	xwa, (0x0d62:16)
	ld	(0x0d5e:16), xwa
	lda	xwa, (0x0d52:16)
	push	xwa
	calr	FDC_Request
	; --- request 4: read track 10 ---
	ldw	(0x0d52:16), 3
	ldw	(0x0d54:16), 0
	ldw	(0x0d56:16), 0
	ldw	(0x0d58:16), 10
	ldw	(0x0d5a:16), 1
	ldw	(0x0d5c:16), 1
	lda	xwa, (0x0d62:16)
	ld	(0x0d5e:16), xwa
	lda	xwa, (0x0d52:16)
	push	xwa
	calr	FDC_Request
	; --- request 5: read track 40 ---
	ldw	(0x0d52:16), 3
	ldw	(0x0d54:16), 0
	ldw	(0x0d56:16), 0
	ldw	(0x0d58:16), 40
	ldw	(0x0d5a:16), 1
	ldw	(0x0d5c:16), 1
	lda	xwa, (0x0d62:16)
	ld	(0x0d5e:16), xwa
	lda	xwa, (0x0d52:16)
	push	xwa
	calr	FDC_Request
	lda	xsp, (xsp + 20)		; drop the five pushed block pointers
	ldw	wa, 200
	calr	Boot_Delay
	incw	1, (0x104c:16)		; probe-pass counter
	ret

; -----------------------------------------------------------------------------
; Boot_CheckDiskPresent - sample the floppy disk-present line
; Inputs:  none
; Outputs: L = 1 disk present (Port D bit 6 low),
;          L = 0 no disk / disk-change asserted (PD6 high)
; Callers: Boot_Init (boot 0xffb661: gate for the whole CP-serial device
;          probe / flash-update path), BOOT_WAITDISKINSERT (0xffc383,
;          0xffc38b, 0xffc39f, 0xffc3a7: insertion poll loop),
;          BOOT_FLASHUPDATE_MAIN (0xffcc2d)
; Boot-time twin of the runtime Check_for_Floppy_Disk_Change (maincpu), which
; samples the same active-low Port D bit 6 line.
; -----------------------------------------------------------------------------
Boot_CheckDiskPresent:
	bit_dd8	6, 0x34			; PD6
	jr	z, Boot_CheckDiskPresent__present
	ldb	l, 0
	ret
Boot_CheckDiskPresent__present:
	ldb	l, 1
	ret
