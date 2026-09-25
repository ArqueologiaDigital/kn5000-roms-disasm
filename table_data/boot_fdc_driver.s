; =============================================================================
; FIRST-STAGE BOOTLOADER FLOPPY DISK (FDC) COMMAND-LAYER DRIVER
; ROM 0x9FD8A5-0x9FEA9C (boot-time alias 0xFFD8A5-0xFFEA9C), 4600 bytes
;
; NOTE: this region was previously mislabeled "Flash Update Type Handlers /
; Type 1..8 disk types".  It is the complete command layer of the bootloader's
; floppy driver for the uPD72068 FDC at IC208 -- a compact port of the maincpu
; FDC driver (v10/maincpu/storage/fdc_routines.s, 0xF96B13-0xF97E80), rebuilt
; here for the boot-time firmware-update path.  Where a routine has a maincpu
; twin, its header cites the twin's label.
;
; Hardware interfaces:
;   0x110008  uPD72068 main status register (read) / AUXILIARY COMMAND
;             register (write): 0x36 software reset, 0x33 enable external
;             mode, rate|0x0B control internal mode (rate bits: 0x00=250k,
;             0x40=500k, 0x80=600k, 0xC0=300kbps), drives|0x0E enable motors,
;             0x4F select format.  Accessed via FDC_ReadStatus /
;             FDC_WriteStatus (the latter is really an aux-command write).
;   0x11000A  uPD72068 data register (uPD765-style commands, parameters and
;             result bytes) via FDC_ReadData / FDC_WriteData.
;   0x120000  FDC DMA-acknowledge data port used by DMA channel 3 and by the
;             PIO fallback transfers.
;   DMA3      control registers DMAS3/DMAD3/DMAC3/DMAM3 (CR 0x0C/0x2C/0x4C/
;             0x4E) programmed via ldc; mode 0x00 = I/O->memory, 0x08 =
;             memory->I/O.
;   Port A    bit 3 (SFR 0x28) = drive motor/enable line.
;   Port H    bit 0 (SFR 0x44) = FDC TC (terminal count) line, pulsed by
;             FDC_PulseTC.
;   INTE45 (SFR 0xE0) / INTETC23 (SFR 0xED) / INTCLR (SFR 0xF8): INT4 (FDC
;             IRQ) and INTTC3 (DMA3 end) enables, set by FDC_EnableIntAndDMA.
;
; Public entry point: FDC_Request (boot 0xFFE944).  The caller pushes a
; pointer to a 14-byte request block; see that routine's header.  Commands:
;    0 initialize   1 recalibrate      2 seek           3 read sectors
;    4 write sectors 5 format           6 motor on       7 motor off
;    8 get last error 9 set disk-changed 10 controller reset
;   11 sense drive status
; Request validation offsets: FDC_ValidateCmd_Offsets (ROM 0x9FB4A2);
; execution stub offsets: FDC_CommandDispatch_Offsets (ROM 0x9FB4BA);
; media-type stanzas: FDC_DiskTypeStanza_Offsets (ROM 0x9FB496).
;
; RAM state block (all in the 0x0Cxx bootloader work area):
;   0x0C00 u16  system tick counter (timeouts are measured against it)
;   0x0C3E u16  media-probe enable flag (0xFFFF while the boot disk probe runs)
;   0x0C40 u8   track currently being formatted (progress display)
;   0x0C44 u8   busy latch: 0xA5 = request executing, 0x5A = done
;   0x0C4A u16  transfer byte count (DMA3 count / PIO countdown)
;   0x0C4C u16  bytes per sector (512, or 1024 for media format 2)
;   0x0C4E u8   media-configuration recursion guard
;   0x0C52 u8   sticky status of the current request (0 = OK; see FDC_Error)
;   0x0C54 u8   status of the previous request (cmd 8 returns it)
;   0x0C56 u8   FDC opcode currently being issued
;   0x0C57 u8   current head (toggled between sides mid-transfer)
;   0x0C58 u8   drive number         0x0C59 u8  C (track parameter)
;   0x0C5A u8   H (head parameter)   0x0C5B u8  R (sector parameter)
;   0x0C5C u8   N (size code)        0x0C5D u8  EOT (last sector)
;   0x0C5E u8   GPL read/write gap   0x0C5F u8  DTL (0xFF)
;   0x0C60 u8   SC sectors/track     0x0C61 u8  GPL format gap
;   0x0C62 u8   format fill byte (0xE5)  0x0C63 u8  STP for scan commands
;   0x0C64 u8   target track for SEEK    0x0C65 u8  SRT  0x0C66 u8 HUT
;   0x0C67 u8   HLT                      0x0C68 u8  ND
;   0x0C6E-0x0C7D  active request block  0x0C7E-0x0C8D  request mirror
;   0x0C8E u8   result count/valid marker (0xFF = empty), 0x0C8F.. ST0..
;   0x0C96 u8   retry counter        0x0C98 u8  disk-changed flag
;   0x0C9A u8   media format id      0x0C9C u8  media-type code
;   0x0C9E..    format ID-field buffer (C,H,R,N per sector)
;   0x0D2E u8   media-removed flag   0x0D32 u8  track cache (0xFF = unknown)
;   0x0D34 u16  EOT limit            0x0D36 u16 track count
;   0x0D38 u16  sectors per track    0x0D3A u16 sector number limit
;   0x0D3E u16  saved sector         0x0D40 u16 saved count (retry loops)
;   0x0D4E/0x0D50  command history (FDC_SaveCommand)
;
; Error codes (sticky per request, first error wins -- FDC_Error):
;   0x01/0x02/0x03 ready-wait timeouts   0x08 unspecified FDC error
;   0x09 result-phase timeout            0x10 read retries exhausted
;   0x20 write retries exhausted         0x2F write-protected
;   0x31 drive not ready                 0x32 equipment check / fault
;   0x33 no data (sector not found)      0x34 overrun
;   0x35 missing address mark            0x36 data CRC error
;   0x37 end of cylinder                 0xFB driver re-entered
;   0xFC controller not present          0xFE bad request parameters
;   0xFF no such command
; =============================================================================

; -----------------------------------------------------------------------------
; FDC_MediaConfigAndRecalibrate - full drive/media (re)configuration
; Resets the FDC (aux 0x36), drains any pending result phase, sends SPECIFY
; and select-format, then dispatches on the media-type code (0x0C9C) low
; nibble through FDC_DiskTypeStanza_Offsets (ROM 0x9FB496) to pick data
; rate + format id, finishing with control-internal-mode, motor-on and a
; recalibrate.  0x0C4E guards against recursion (error paths re-enter here).
; Inputs:  (0x0C9C) media-type code; request block for the probe predicates
; Outputs: FDC configured for the media; (0x0C52) sticky status on failure
; Callers: FDC_CmdInitialize; retry/recovery paths of FDC_CmdReadSectors,
;          FDC_CmdWriteSectors, FDC_CmdFormat, FDC_FormatOneTrack
; Twin:    maincpu FDC_HardwareSetup region (fdc_routines.s:972)
; -----------------------------------------------------------------------------
FDC_MediaConfigAndRecalibrate:
	push xiz	; push XIZ
	calr FDC_ClearError	; calr 0xffe25a
	calr FDC_IsMediaProbeRead	; calr 0xffe1c8
	cp hl, 0xffff	; cp HL,0xffff
	jr z, FDC_MediaConfigAndRecalibrate__guard_check	; jr Z,0xffd8c0
	calr FDC_IsMediaProbeInit	; calr 0xffe216
	cp hl, 0xffff	; cp HL,0xffff
	jr z, FDC_MediaConfigAndRecalibrate__guard_check	; jr Z,0xffd8c0
	ld (0x0d32:16), 0xff	; ld (0x0d32),0xff
FDC_MediaConfigAndRecalibrate__guard_check:
	cp (0x0c4e:16), 0xff	; cp (0x0c4e),0xff
	jrl z, FDC_MediaConfigAndRecalibrate__done	; jrl Z,0xffda68
	ld (0x0c4e:16), 0xff	; ld (0x0c4e),0xff
	ldw wa, 0x36	; ld WA,0x0036 - aux cmd 0x36 = uPD72068 software reset
	calr FDC_WriteStatus	; calr 0xffd7f4
	ld wa, 2:i3	; ld WA,2
	calr Boot_Delay	; calr 0xffe296
	calr FDC_IsMediaProbeRead	; calr 0xffe1c8
	cp hl, 0xffff	; cp HL,0xffff
	jr z, FDC_MediaConfigAndRecalibrate__send_specify	; jr Z,0xffd950
	calr FDC_IsMediaProbeInit	; calr 0xffe216
	cp hl, 0xffff	; cp HL,0xffff
	jr z, FDC_MediaConfigAndRecalibrate__send_specify	; jr Z,0xffd950
	calr FDC_ClearError	; calr 0xffe25a
	calr FDC_CmdControllerReset	; calr 0xffda6a
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jr z, FDC_MediaConfigAndRecalibrate__drain_results	; jr Z,0xffd8ff
	ld (0x0c4e:16), 0	; ld (0x0c4e),0x00
	jrl FDC_MediaConfigAndRecalibrate__done	; jrl T,0xffda68
FDC_MediaConfigAndRecalibrate__drain_results:
	calr FDC_ReadStatus	; calr 0xffd7e8
	bit 7, l	; bit 0x07,L
	jr z, FDC_MediaConfigAndRecalibrate__drain_results	; jr Z,0xffd8ff
	calr FDC_ReadStatus	; calr 0xffd7e8
	bit 6, l	; bit 0x06,L
	jr nz, FDC_MediaConfigAndRecalibrate__read_results	; jr NZ,0xffd927
	ld l, 0:opc	; ld L,0x00
	cp l, 0x80	; cp L,0x80
	jr z, FDC_MediaConfigAndRecalibrate__send_sense_interrupt	; jr Z,0xffd921
FDC_MediaConfigAndRecalibrate__wait_idle:
	calr FDC_ReadStatus	; calr 0xffd7e8
	and l, 0xf0	; and L,0xf0
	cp l, 0x80	; cp L,0x80
	jr nz, FDC_MediaConfigAndRecalibrate__wait_idle	; jr NZ,0xffd916
FDC_MediaConfigAndRecalibrate__send_sense_interrupt:
	ldw wa, 8	; ld WA,0x0008 - 0x08 = SENSE INTERRUPT STATUS
	calr FDC_WriteData	; calr 0xffd805
FDC_MediaConfigAndRecalibrate__read_results:
	lda xiz, (0x0c8e:16)	; lda XIZ,0x0c8e
	inc 1, xiz	; inc 1,XIZ
FDC_MediaConfigAndRecalibrate__read_next_byte:
	calr FDC_WaitRQM	; calr 0xffdda3
	calr FDC_ReadData	; calr 0xffd7ee
	ld (xiz+), l	; ld (XIZ+),L
FDC_MediaConfigAndRecalibrate__more_results:
	calr FDC_ReadStatus	; calr 0xffd7e8
	bit 7, l	; bit 0x07,L
	jr z, FDC_MediaConfigAndRecalibrate__more_results	; jr Z,0xffd936
	calr FDC_ReadStatus	; calr 0xffd7e8
	bit 6, l	; bit 0x06,L
	jr nz, FDC_MediaConfigAndRecalibrate__read_next_byte	; jr NZ,0xffd92d
	calr FDC_ProcessResults	; calr 0xffdf17
	cp (0x0c8f:16), 0x80	; cp (0x0c8f),0x80
	jr nz, FDC_MediaConfigAndRecalibrate__drain_results	; jr NZ,0xffd8ff
FDC_MediaConfigAndRecalibrate__send_specify:
	ld wa, 3:i3	; ld WA,3 - 0x03 = SPECIFY (params via FDC_SendParams_Specify)
	calr FDC_IssueCommand	; calr 0xffdfc3
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jr z, FDC_MediaConfigAndRecalibrate__select_format	; jr Z,0xffd964
	ld (0x0c4e:16), 0	; ld (0x0c4e),0x00
	jrl FDC_MediaConfigAndRecalibrate__done	; jrl T,0xffda68
FDC_MediaConfigAndRecalibrate__select_format:
	ldw wa, 0x4f	; ld WA,0x004f - 0x4F = aux select format (IBM format)
	calr FDC_IssueCommand	; calr 0xffdfc3
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jr z, FDC_MediaConfigAndRecalibrate__media_dispatch	; jr Z,0xffd979
	ld (0x0c4e:16), 0	; ld (0x0c4e),0x00
	jrl FDC_MediaConfigAndRecalibrate__done	; jrl T,0xffda68
FDC_MediaConfigAndRecalibrate__media_dispatch:
	ld a, (0x0c9c:16)	; ld A,(0x0c9c)
	and a, 0x0f	; and A,0x0f - low nibble of the media-type code selects the stanza
	extz wa	; extz WA
	cp wa, 0:i3	; cp WA,0
	jrl mi, FDC_MediaStanza_Default	; jrl M/MI,0xffda23
	cp wa, 5:i3	; cp WA,5
	jrl gt, FDC_MediaStanza_Default	; jrl GT,0xffda23
	add wa, wa	; add WA,WA
	lda xix, (FDC_DiskTypeStanza_Offsets + 0x600000:24)	; lda XIX,0xffb496 - XIX = FDC_DiskTypeStanza_Offsets (boot alias of ROM 0x9FB496)
	ldw_sri wa, 0x07, 0xf0, 0xe0	; ld WA,(XIX+WA) - fetch stanza offset
	lda xix, (FDC_MediaStanza_Type0 + 0x600000:24)	; lda XIX,0xffd9a2
	jp_ind 8, 0x07, 0xf0, 0xe0	; jp T,XIX+WA

; -----------------------------------------------------------------------------
; FDC_MediaStanza_Type0..Type5 / _Default - media-type configuration stanzas
; Targets of FDC_DiskTypeStanza_Offsets.  Each stores a media format id to
; 0x0C9A, clears 0x0C50, loads the data-rate bits for the aux
; control-internal-mode command into QIZH and records a byte through
; FDC_SaveCommand, then joins FDC_MediaStanza_Submit:
;   type 0: fmt 0, 250 kbps    type 1: fmt 0, 300 kbps
;   type 2: fmt 2, 500 kbps    type 3: fmt 3, 500 kbps (2HD)
;   type 4: fmt 4, 250 kbps    type 5: fmt 5, 250 kbps
; Types 6-15 use the _Default stanza (same body as type 0).
; -----------------------------------------------------------------------------
FDC_MediaStanza_Type0:
	ld (0x0c9a:16), 0	; ld (0x0c9a),0x00
	ldw (0x0c50:16), 0	; ld (0x0c50),0x0000
	ldib_erp 0xfb, 0	; ld QIZH,0
	ld wa, 2:i3	; ld WA,2
	calr FDC_SaveCommand	; calr 0xffd7fa
	jr FDC_MediaStanza_Submit	; jr T,0xffda36
FDC_MediaStanza_Type1:
	ld (0x0c9a:16), 0	; ld (0x0c9a),0x00
	ldw (0x0c50:16), 0	; ld (0x0c50),0x0000
	ldi_erpb 0xfb, 0xc0	; ld QIZH,0xc0
	ld wa, 2:i3	; ld WA,2
	calr FDC_SaveCommand	; calr 0xffd7fa
	jr FDC_MediaStanza_Submit	; jr T,0xffda36
FDC_MediaStanza_Type2:
	ld (0x0c9a:16), 2	; ld (0x0c9a),0x02
	ldw (0x0c50:16), 0	; ld (0x0c50),0x0000
	ldi_erpb 0xfb, 0x40	; ld QIZH,0x40
	ld wa, 0:i3	; ld WA,0
	calr FDC_SaveCommand	; calr 0xffd7fa
	jr FDC_MediaStanza_Submit	; jr T,0xffda36
FDC_MediaStanza_Type3:
	ld (0x0c9a:16), 3	; ld (0x0c9a),0x03
	ldw (0x0c50:16), 0	; ld (0x0c50),0x0000
	ldi_erpb 0xfb, 0x40	; ld QIZH,0x40
	ld wa, 0:i3	; ld WA,0
	calr FDC_SaveCommand	; calr 0xffd7fa
	jr FDC_MediaStanza_Submit	; jr T,0xffda36
FDC_MediaStanza_Type4:
	ld (0x0c9a:16), 4	; ld (0x0c9a),0x04
	ldw (0x0c50:16), 0	; ld (0x0c50),0x0000
	ldib_erp 0xfb, 0	; ld QIZH,0
	ld wa, 2:i3	; ld WA,2
	calr FDC_SaveCommand	; calr 0xffd7fa
	jr FDC_MediaStanza_Submit	; jr T,0xffda36
FDC_MediaStanza_Type5:
	ld (0x0c9a:16), 5	; ld (0x0c9a),0x05
	ldw (0x0c50:16), 0	; ld (0x0c50),0x0000
	ldib_erp 0xfb, 0	; ld QIZH,0
	ld wa, 2:i3	; ld WA,2
	calr FDC_SaveCommand	; calr 0xffd7fa
	jr FDC_MediaStanza_Submit	; jr T,0xffda36
FDC_MediaStanza_Default:
	ld (0x0c9a:16), 0	; ld (0x0c9a),0x00
	ldw (0x0c50:16), 0	; ld (0x0c50),0x0000
	ldib_erp 0xfb, 0	; ld QIZH,0
	ld wa, 2:i3	; ld WA,2
	calr FDC_SaveCommand	; calr 0xffd7fa

; -----------------------------------------------------------------------------
; FDC_MediaStanza_Submit - shared stanza tail
; Issues aux command (rate | 0x0B) = control internal mode, then motor-on
; and recalibrate.  Any failure clears the 0x0C4E guard and exits.
; -----------------------------------------------------------------------------
FDC_MediaStanza_Submit:
	ldto_berp a, 0xfb	; ld A,QIZH - A = data-rate bits saved by the stanza
	or a, 0x0b	; or A,0x0b - 0x0B = aux control internal mode; rate: 0x00=250k 0x40=500k 0xC0=300kbps
	extz wa	; extz WA
	calr FDC_IssueCommand	; calr 0xffdfc3
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jr z, FDC_MediaStanza_Submit__motor_on	; jr Z,0xffda4f
	ld (0x0c4e:16), 0	; ld (0x0c4e),0x00
	jr FDC_MediaConfigAndRecalibrate__done	; jr T,0xffda68
FDC_MediaStanza_Submit__motor_on:
	calr FDC_CmdMotorOn	; calr 0xffe89b
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jr z, FDC_MediaStanza_Submit__recalibrate	; jr Z,0xffda60
	ld (0x0c4e:16), 0	; ld (0x0c4e),0x00
	jr FDC_MediaConfigAndRecalibrate__done	; jr T,0xffda68
FDC_MediaStanza_Submit__recalibrate:
	calr FDC_CmdRecalibrate	; calr 0xffe2d6
	ld (0x0c4e:16), 0	; ld (0x0c4e),0x00
FDC_MediaConfigAndRecalibrate__done:
	pop xiz	; pop XIZ
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_CmdControllerReset - command 10: reset FDC and check presence
; Aux command 0x36 (software reset), short delay, then reads MSR: 0xFF
; means nothing is driving the bus -> error 0xFC.  Returns HL = 0.
; Twin: maincpu FDC_CMD_DISPATCH_SUB (fdc_routines.s FDC_HANDLER_10)
; -----------------------------------------------------------------------------
FDC_CmdControllerReset:
	ldw wa, 0x36	; ld WA,0x0036 - aux cmd 0x36 = software reset
	calr FDC_WriteStatus	; calr 0xffd7f4
	ld wa, 2:i3	; ld WA,2
	calr Boot_Delay	; calr 0xffe296
	calr FDC_ReadStatus	; calr 0xffd7e8
	cp l, 0xff	; cp L,0xff - 0xFF = no controller responding
	jr nz, FDC_CmdControllerReset__present	; jr NZ,0xffda83
	ldw wa, 0xfc	; ld WA,0x00fc - error 0xFC = FDC not present
	calr FDC_Error	; calr 0xffe231
FDC_CmdControllerReset__present:
	ld hl, 0:i3	; ld HL,0
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_ValidateRequest - per-command parameter validation
; Dispatches on the command word (0x0C6E) through FDC_ValidateCmd_Offsets
; (ROM 0x9FB4A2) to one of four validators below.  Returns L = 0 when the
; request is acceptable (out-of-range commands are checked by the executor).
; Callers: FDC_Request (before the execution dispatch)
; Twin:    maincpu FDC_COMMAND_DISPATCHER (fdc_routines.s:329)
; -----------------------------------------------------------------------------
FDC_ValidateRequest:
	ld (0x0c58:16), 0	; ld (0x0c58),0x00
	ld wa, (0x0c6e:16)	; ld WA,(0x0c6e)
	cp wa, 0x0b	; cp WA,0x000b
	jr ugt, FDC_Validate_DriveTrackSector	; jr UGT,0xffdab9
	add wa, wa	; add WA,WA
	lda xix, (FDC_ValidateCmd_Offsets + 0x600000:24)	; lda XIX,0xffb4a2
	ldw_sri wa, 0x07, 0xf0, 0xe0	; ld WA,(XIX+WA) - XIX = FDC_ValidateCmd_Offsets (boot alias of ROM 0x9FB4A2)
	lda xix, (FDC_Validate_FormatParams + 0x600000:24)	; lda XIX,0xffdaab
	jp_ind 8, 0x07, 0xf0, 0xe0	; jp T,XIX+WA - XIX = FDC_Validate_FormatParams (validator base)

; -----------------------------------------------------------------------------
; FDC_Validate_FormatParams (+0x00) - cmd 0: check + program the geometry
; FDC_Validate_AcceptAlways (+0x08) - cmds 6/7/8/10: always accepted
; FDC_Validate_HeadDrive    (+0x0B) - cmd 9: head/drive precheck, then falls
;                                     into the drive/track/sector chain
; FDC_Validate_DriveTrackSector (+0x0E) - cmds 1-5/11: drive <= 1, track
; below the media's track count, sector within the per-format limit
; (8 for the 1024-byte format 2, 18 for 2HD format 3, 9 otherwise; format 4
; also accepts the 0xFF wildcard), head 0/1.  Rejections raise error 0xFE.
; Twin: maincpu FDC_CMD_HANDLER_BASE / FDC_ReturnZero /
;       FDC_ErrorInvalidDrive / FDC_CheckDriveCount (fdc_routines.s:340-360)
; -----------------------------------------------------------------------------
FDC_Validate_FormatParams:
	calr FDC_SetGeometryForDiskType	; calr 0xffdbad
	ld l, (0x0c52:16)	; ld L,(0x0c52)
	ret	; ret
FDC_Validate_AcceptAlways:
	ld l, 0:opc	; ld L,0x00
	ret	; ret
FDC_Validate_HeadDrive:
	calr FDC_ValidateDrive	; calr 0xffdcdf
FDC_Validate_DriveTrackSector:
	ld wa, (0x0c70:16)	; ld WA,(0x0c70)
	ld (0x0c58:16), a	; ld (0x0c58),A
	cp (0x0c58:16), 1	; cp (0x0c58),0x01 - drive number must be 0 or 1
	jr ule, FDC_Validate_DriveTrackSector__check_command	; jr ULE,0xffdace
	ldw wa, 0xfe	; ld WA,0x00fe
	jrl FDC_Error	; jrl T,0xffe231
FDC_Validate_DriveTrackSector__check_command:
	ld wa, (0x0c6e:16)	; ld WA,(0x0c6e)
	cp wa, 4:i3	; cp WA,4
	jr z, FDC_Validate_DriveTrackSector__check_track	; jr Z,0xffdaf7
	cp wa, 3:i3	; cp WA,3
	jr z, FDC_Validate_DriveTrackSector__check_track	; jr Z,0xffdaf7
	cp wa, 2:i3	; cp WA,2
	jr z, FDC_Validate_DriveTrackSector__check_track	; jr Z,0xffdaf7
	cp wa, 5:i3	; cp WA,5
	jr z, FDC_Validate_DriveTrackSector__format_check	; jr Z,0xffdaef
	cp wa, 0x0b	; cp WA,0x000b
	jr z, FDC_Validate_DriveTrackSector__accept	; jr Z,0xffdaec
	cp wa, 1:i3	; cp WA,1
	jr nz, FDC_Validate_DriveTrackSector__check_track	; jr NZ,0xffdaf7
FDC_Validate_DriveTrackSector__accept:
	ld l, 0:opc	; ld L,0x00
	ret	; ret
FDC_Validate_DriveTrackSector__format_check:
	calr FDC_ValidateStub	; calr 0xffdcde
	ld l, (0x0c52:16)	; ld L,(0x0c52)
	ret	; ret
FDC_Validate_DriveTrackSector__check_track:
	ld wa, (0x0c74:16)	; ld WA,(0x0c74)
	ld (0x0c59:16), a	; ld (0x0c59),A
	ld (0x0c64:16), a	; ld (0x0c64),A
	extz wa	; extz WA
	cp wa, (0x0d36:16)	; cp WA,(0x0d36)
	jr c, FDC_Validate_DriveTrackSector__track_ok	; jr C,0xffdb11
	ldw wa, 0xfe	; ld WA,0x00fe
	jrl FDC_Error	; jrl T,0xffe231
FDC_Validate_DriveTrackSector__track_ok:
	cpw (0x0c6e:16), 2	; cp (0x0c6e),0x0002
	jr nz, FDC_Validate_DriveTrackSector__check_count	; jr NZ,0xffdb21
	calr FDC_ValidateHead	; calr 0xffdcbd
	ld l, (0x0c52:16)	; ld L,(0x0c52)
	ret	; ret
FDC_Validate_DriveTrackSector__check_count:
	cpw (0x0c78:16), 0	; cp (0x0c78),0x0000
	jr nz, FDC_Validate_DriveTrackSector__check_sector	; jr NZ,0xffdb2f
	ldw wa, 0xfe	; ld WA,0x00fe
	jrl FDC_Error	; jrl T,0xffe231
FDC_Validate_DriveTrackSector__check_sector:
	ld wa, (0x0c76:16)	; ld WA,(0x0c76)
	ld (0x0c5b:16), a	; ld (0x0c5b),A
	cp (0x0c5b:16), 0	; cp (0x0c5b),0x00
	jr nz, FDC_Validate_DriveTrackSector__sector_by_format	; jr NZ,0xffdb44
	ldw wa, 0xfe	; ld WA,0x00fe
	jrl FDC_Error	; jrl T,0xffe231
FDC_Validate_DriveTrackSector__sector_by_format:
	ld a, (0x0c9a:16)	; ld A,(0x0c9a)
	cp a, 0:i3	; cp A,0
	jr z, FDC_Validate_DriveTrackSector__max9_check	; jr Z,0xffdb92
	cp a, 5:i3	; cp A,5
	jr z, FDC_Validate_DriveTrackSector__max9_check	; jr Z,0xffdb92
	cp a, 4:i3	; cp A,4
	jr z, FDC_Validate_DriveTrackSector__fmt4_wildcard	; jr Z,0xffdb76
	cp a, 3:i3	; cp A,3
	jr z, FDC_Validate_DriveTrackSector__max18_check	; jr Z,0xffdb69
	cp a, 2:i3	; cp A,2
	jr nz, FDC_Validate_DriveTrackSector__bad_param	; jr NZ,0xffdb9f
	cp (0x0c5b:16), 8	; cp (0x0c5b),0x08
	jr ule, FDC_Validate_DriveTrackSector__check_head	; jr ULE,0xffdba5
	ldw wa, 0xfe	; ld WA,0x00fe
	jrl FDC_Error	; jrl T,0xffe231
FDC_Validate_DriveTrackSector__max18_check:
	cp (0x0c5b:16), 0x12	; cp (0x0c5b),0x12
	jr ule, FDC_Validate_DriveTrackSector__check_head	; jr ULE,0xffdba5
	ldw wa, 0xfe	; ld WA,0x00fe
	jrl FDC_Error	; jrl T,0xffe231
FDC_Validate_DriveTrackSector__fmt4_wildcard:
	cp (0x0c5b:16), 0xff	; cp (0x0c5b),0xff
	jr nz, FDC_Validate_DriveTrackSector__max9_check_fmt4	; jr NZ,0xffdb85
	calr FDC_ValidateHead	; calr 0xffdcbd
	ld l, (0x0c52:16)	; ld L,(0x0c52)
	ret	; ret
FDC_Validate_DriveTrackSector__max9_check_fmt4:
	cp (0x0c5b:16), 9	; cp (0x0c5b),0x09
	jr ule, FDC_Validate_DriveTrackSector__check_head	; jr ULE,0xffdba5
	ldw wa, 0xfe	; ld WA,0x00fe
	jrl FDC_Error	; jrl T,0xffe231
FDC_Validate_DriveTrackSector__max9_check:
	cp (0x0c5b:16), 9	; cp (0x0c5b),0x09
	jr ule, FDC_Validate_DriveTrackSector__check_head	; jr ULE,0xffdba5
	ldw wa, 0xfe	; ld WA,0x00fe
	jrl FDC_Error	; jrl T,0xffe231
FDC_Validate_DriveTrackSector__bad_param:
	ldw wa, 0xfe	; ld WA,0x00fe
	jrl FDC_Error	; jrl T,0xffe231
FDC_Validate_DriveTrackSector__check_head:
	calr FDC_ValidateHead	; calr 0xffdcbd
	ld l, (0x0c52:16)	; ld L,(0x0c52)
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_SetGeometryForDiskType - program the geometry preset for the media
; Media-type code (request field +6) low nibble selects one of three
; presets written to 0x0C5C-0x0C68 and 0x0D34-0x0D3A:
;   types 0/4/5: 9 x 512 B, 80 tracks, gaps 0x1B/0x54  (720K 2DD)
;   type 2:      8 x 1024 B, 77 tracks, gaps 0x53/0x74 (1.25MB-style 2DD-8)
;   type 3:      18 x 512 B, 80 tracks, gaps 0x1B/0x6C (1.44MB 2HD)
; The common tail derives SRT from the code's high nibble and fixes
; HUT=0x0F, HLT=1, ND=0, DTL=0xFF, fill byte handling.  Unknown types
; raise error 0xFE.
; Twin: maincpu FDC_SetupFormatParams / FDC_FormatHD/DD/1440K
;       (fdc_routines.s:466-524)
; -----------------------------------------------------------------------------
FDC_SetGeometryForDiskType:
	ld wa, (0x0c74:16)	; ld WA,(0x0c74)
	ld (0x0c9c:16), a	; ld (0x0c9c),A
	and a, 0x0f	; and A,0x0f
	cp a, 3:i3	; cp A,3
	jrl z, FDC_SetGeometryForDiskType__geom_2hd18	; jrl Z,0xffdc3e
	cp a, 2:i3	; cp A,2
	jr z, FDC_SetGeometryForDiskType__geom_2dd8_1024	; jr Z,0xffdc06
	cp a, 5:i3	; cp A,5
	jr z, FDC_SetGeometryForDiskType__geom_2dd9	; jr Z,0xffdbce
	cp a, 4:i3	; cp A,4
	jr z, FDC_SetGeometryForDiskType__geom_2dd9	; jr Z,0xffdbce
	cp a, 0:i3	; cp A,0
	jrl nz, FDC_SetGeometryForDiskType__bad_type	; jrl NZ,0xffdc76
FDC_SetGeometryForDiskType__geom_2dd9:
	ld (0x0c5c:16), 2	; ld (0x0c5c),0x02
	ld (0x0c63:16), 1	; ld (0x0c63),0x01
	ld (0x0c5d:16), 9	; ld (0x0c5d),0x09
	ld (0x0c60:16), 9	; ld (0x0c60),0x09
	ld (0x0c5e:16), 0x1b	; ld (0x0c5e),0x1b
	ld (0x0c61:16), 0x54	; ld (0x0c61),0x54
	ldw (0x0d34:16), 0x4f	; ld (0x0d34),0x004f
	ldw (0x0d36:16), 0x50	; ld (0x0d36),0x0050
	ldw (0x0d38:16), 9	; ld (0x0d38),0x0009
	ldw (0x0d3a:16), 0x0a	; ld (0x0d3a),0x000a
	jr FDC_SetGeometryForDiskType__common	; jr T,0xffdc7c
FDC_SetGeometryForDiskType__geom_2dd8_1024:
	ld (0x0c5c:16), 3	; ld (0x0c5c),0x03
	ld (0x0c63:16), 1	; ld (0x0c63),0x01
	ld (0x0c5d:16), 8	; ld (0x0c5d),0x08
	ld (0x0c60:16), 8	; ld (0x0c60),0x08
	ld (0x0c5e:16), 0x53	; ld (0x0c5e),0x53
	ld (0x0c61:16), 0x74	; ld (0x0c61),0x74
	ldw (0x0d34:16), 0x4c	; ld (0x0d34),0x004c
	ldw (0x0d36:16), 0x4d	; ld (0x0d36),0x004d
	ldw (0x0d38:16), 8	; ld (0x0d38),0x0008
	ldw (0x0d3a:16), 9	; ld (0x0d3a),0x0009
	jr FDC_SetGeometryForDiskType__common	; jr T,0xffdc7c
FDC_SetGeometryForDiskType__geom_2hd18:
	ld (0x0c5c:16), 2	; ld (0x0c5c),0x02
	ld (0x0c63:16), 1	; ld (0x0c63),0x01
	ld (0x0c5d:16), 0x12	; ld (0x0c5d),0x12
	ld (0x0c60:16), 0x12	; ld (0x0c60),0x12
	ld (0x0c5e:16), 0x1b	; ld (0x0c5e),0x1b
	ld (0x0c61:16), 0x6c	; ld (0x0c61),0x6c
	ldw (0x0d34:16), 0x4f	; ld (0x0d34),0x004f
	ldw (0x0d36:16), 0x50	; ld (0x0d36),0x0050
	ldw (0x0d38:16), 0x12	; ld (0x0d38),0x0012
	ldw (0x0d3a:16), 0x13	; ld (0x0d3a),0x0013
	jr FDC_SetGeometryForDiskType__common	; jr T,0xffdc7c
FDC_SetGeometryForDiskType__bad_type:
	ldw wa, 0xfe	; ld WA,0x00fe
	calr FDC_Error	; calr 0xffe231
FDC_SetGeometryForDiskType__common:
	ld a, (0x0c9c:16)	; ld A,(0x0c9c)
	srl a, 4	; srl 0x04,A
	and a, 0x0f	; and A,0x0f
	ld (0x0c65:16), a	; ld (0x0c65),A
	ld (0x0c5f:16), 0xff	; ld (0x0c5f),0xff
	ld (0x0c62:16), 0	; ld (0x0c62),0x00
	ld (0x0c66:16), 0x0f	; ld (0x0c66),0x0f
	ld (0x0c67:16), 1	; ld (0x0c67),0x01
	ld (0x0c6a:16), 0	; ld (0x0c6a),0x00
	ld (0x0c69:16), 0	; ld (0x0c69),0x00
	ld (0x0c6b:16), 0	; ld (0x0c6b),0x00
	ld (0x0c6c:16), 0	; ld (0x0c6c),0x00
	ld (0x0c6d:16), 0	; ld (0x0c6d),0x00
	ld (0x0c68:16), 0	; ld (0x0c68),0x00
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_ValidateHead - head number (request field +4) must be 0 or 1
; Also latches it into 0x0C5A/0x0C57.  Error 0xFE otherwise.
; Twin: maincpu FDC_CheckHead (fdc_routines.s:541)
; -----------------------------------------------------------------------------
FDC_ValidateHead:
	ld wa, (0x0c72:16)	; ld WA,(0x0c72)
	ld (0x0c5a:16), a	; ld (0x0c5a),A
	ld (0x0c57:16), a	; ld (0x0c57),A
	cp (0x0c57:16), 0	; cp (0x0c57),0x00
	ret z	; ret Z
	cp (0x0c57:16), 1	; cp (0x0c57),0x01
	ret z	; ret Z
	ldw wa, 0xfe	; ld WA,0x00fe
	calr FDC_Error	; calr 0xffe231
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_ValidateStub - empty validator kept for its cmd-5 call site
; Twin: maincpu FDC_NoOpReturn
; -----------------------------------------------------------------------------
FDC_ValidateStub:
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_ValidateDrive - drive number (request field +4 as u16) must be 0 or 1
; Twin: maincpu FDC_Validate_Drive_Head (fdc_routines.s:556)
; -----------------------------------------------------------------------------
FDC_ValidateDrive:
	cpw (0x0c72:16), 0	; cp (0x0c72),0x0000
	ret z	; ret Z
	cpw (0x0c72:16), 1	; cp (0x0c72),0x0001
	ret z	; ret Z
	ldw wa, 0xfe	; ld WA,0x00fe
	calr FDC_Error	; calr 0xffe231
	ret	; ret

; -----------------------------------------------------------------------------
; Boot_ShortDelay - busy-wait A iterations of a 10-nop inner loop
; Twin: maincpu FDC_NOP_Delay (fdc_routines.s:566)
; -----------------------------------------------------------------------------
Boot_ShortDelay:
	dec 2, xsp	; dec 2,XSP
	ld (xsp), a	; ld (XSP),A
	ld a, (xsp)	; ld A,(XSP)
	decm8 1, (xsp)	; dec 1,(XSP)
	cp a, 0:i3	; cp A,0
	jr z, Boot_ShortDelay__done	; jr Z,0xffdd14
Boot_ShortDelay__loop:
	nop	; nop
	nop	; nop
	nop	; nop
	nop	; nop
	nop	; nop
	nop	; nop
	nop	; nop
	nop	; nop
	nop	; nop
	nop	; nop
	ld a, (xsp)	; ld A,(XSP)
	decm8 1, (xsp)	; dec 1,(XSP)
	cp a, 0:i3	; cp A,0
	jr nz, Boot_ShortDelay__loop	; jr NZ,0xffdd02
Boot_ShortDelay__done:
	inc 2, xsp	; inc 2,XSP
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_PulseTC - pulse the FDC TC (terminal count) line, Port H bit 0
; (formerly Boot_TimerTick -- it does not tick any timer)
; Raises PH0, waits 10 delay iterations, lowers it.  Terminates the FDC's
; current multi-sector transfer.  Called on PIO-transfer completion and
; periodically from BootTimer_InterruptHandler (INTTC3) so a stuck command
; cannot hang the boot.
; Twin: maincpu FDC_Pulse_PH0 (fdc_routines.s:595)
; -----------------------------------------------------------------------------
FDC_PulseTC:
	set_dd8 0, 0x44	; set 0,(0x44)
	ldw wa, 0x0a	; ld WA,0x000a
	calr Boot_ShortDelay	; calr 0xffdcf6
	res_dd8 0, 0x44	; res 0,(0x44)
	ret	; ret

; -----------------------------------------------------------------------------
; Boot_UpdateDisplayThunk - callable jr into Boot_UpdateDisplay
; -----------------------------------------------------------------------------
Boot_UpdateDisplayThunk:
	jr Boot_UpdateDisplay	; jr T,0xffdd26

; -----------------------------------------------------------------------------
; Boot_UpdateDisplay - request a display refresh (writes 0x0C to 0x0103)
; The flag byte is consumed by the boot main loop's progress display.
; -----------------------------------------------------------------------------
Boot_UpdateDisplay:
	ld (0x0103:16), 0x0c	; ld (0x0103),0x0c
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_SetupDMAMode - program DMA channel 3 for the coming transfer
; Loads DMAC3 with the byte count (0x0C4A) and picks the direction from
; the FDC opcode (0x0C56): write-class opcodes 0x4D/0xC9/0xC5 stream
; memory->FDC via FDC_SetupDMA_WriteToFDC; read-class opcodes
; 0xC6/0xCC/0x42/0x4A/0xD1/0xD9/0xDD stream FDC->memory (DMAS3 = the
; 0x120000 acknowledge port, DMAD3 = caller's buffer, mode 0x00).
; Unknown opcodes leave DMA untouched.
; Twin: maincpu FDC_Setup_DMA_Mode (fdc_routines.s:611)
; -----------------------------------------------------------------------------
FDC_SetupDMAMode:
	ld bc, (0x0c4a:16)	; ld BC,(0x0c4a)
	ldc_cr16 bc, 0x4c	; ldc unknown,BC - DMAC3 = transfer byte count
	ld a, (0x0c56:16)	; ld A,(0x0c56)
	cp a, 0x4d	; cp A,0x4d
	jr z, FDC_SetupDMAMode__to_fdc	; jr Z,0xffdd6b
	cp a, 0xc9	; cp A,0xc9
	jr z, FDC_SetupDMAMode__to_fdc	; jr Z,0xffdd6b
	cp a, 0xc5	; cp A,0xc5
	jr z, FDC_SetupDMAMode__to_fdc	; jr Z,0xffdd6b
	cp a, 0xdd	; cp A,0xdd
	jr z, FDC_SetupDMAMode__from_fdc	; jr Z,0xffdd69
	cp a, 0xd9	; cp A,0xd9
	jr z, FDC_SetupDMAMode__from_fdc	; jr Z,0xffdd69
	cp a, 0xd1	; cp A,0xd1
	jr z, FDC_SetupDMAMode__from_fdc	; jr Z,0xffdd69
	cp a, 0x4a	; cp A,0x4a
	jr z, FDC_SetupDMAMode__from_fdc	; jr Z,0xffdd69
	cp a, 0x42	; cp A,0x42
	jr z, FDC_SetupDMAMode__from_fdc	; jr Z,0xffdd69
	cp a, 0xcc	; cp A,0xcc
	jr z, FDC_SetupDMAMode__from_fdc	; jr Z,0xffdd69
	cp a, 0xc6	; cp A,0xc6
	ret nz	; ret NZ
FDC_SetupDMAMode__from_fdc:
	jr FDC_SetupDMAMode__dma_from_fdc	; jr T,0xffdd6f
FDC_SetupDMAMode__to_fdc:
	calr FDC_SetupDMA_WriteToFDC	; calr 0xffdd85
	ret	; ret
FDC_SetupDMAMode__dma_from_fdc:
	ld xhl, 0x120000	; ld XHL,0x00120000
	ldc_cr32 xhl, 0x0c	; ldc DMAS3,XHL - DMAS3 = FDC DMA-acknowledge data port
	ld xhl, (0x0c7a:16)	; ld XHL,(0x0c7a)
	ldc_cr32 xhl, 0x2c	; ldc unknown,XHL - DMAD3 = caller's buffer
	ld a, 0:opc	; ld A,0x00
	ldc_cr8 a, 0x4e	; ldc unknown,A - DMAM3 mode 0x00 = I/O -> memory, destination increments
	jr Boot_UpdateDisplay	; jr T,0xffdd26

; -----------------------------------------------------------------------------
; FDC_SetupDMA_WriteToFDC - DMA3 memory->FDC (DMAS3 = buffer, DMAD3 =
; 0x120000, mode 0x08)
; Twin: maincpu FDC_Setup_DMA_Src_Ack (fdc_routines.s:654)
; -----------------------------------------------------------------------------
FDC_SetupDMA_WriteToFDC:
	ld xhl, (0x0c7a:16)	; ld XHL,(0x0c7a)
	ldc_cr32 xhl, 0x0c	; ldc DMAS3,XHL - DMAS3 = caller's buffer
	ld xhl, 0x120000	; ld XHL,0x00120000
	ldc_cr32 xhl, 0x2c	; ldc unknown,XHL - DMAD3 = FDC DMA-acknowledge data port
	ld a, 8:opc	; ld A,0x08
	ldc_cr8 a, 0x4e	; ldc unknown,A - DMAM3 mode 0x08 = memory -> I/O, source increments
	jr Boot_UpdateDisplay	; jr T,0xffdd26

; -----------------------------------------------------------------------------
; FDC_ReloadDMACount - reload DMAC3 with the byte count (0x0C4A)
; Used before formatting to re-arm the count after the mode setup.
; Twin: unlabeled tail after FDC_Setup_DMA_Src_Ack (fdc_routines.s:662)
; -----------------------------------------------------------------------------
FDC_ReloadDMACount:
	ld bc, (0x0c4a:16)	; ld BC,(0x0c4a)
	ldc_cr16 bc, 0x4c	; ldc unknown,BC - DMAC3 = transfer byte count
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_WaitRQM - wait until the FDC requests a transfer, 500-tick timeout
; Polls MSR with bit 4 (CB) masked off until it reads RQM (0x80) or
; RQM|DIO (0xC0).  On timeout raises error 2.
; Callers: the result drain in FDC_MediaConfigAndRecalibrate,
;          FDC_SendAuxCmdReadResult, FDC_CmdSenseDriveStatus
; Twin: maincpu FDC_Wait_Ready_Timeout (fdc_routines.s:666)
; -----------------------------------------------------------------------------
FDC_WaitRQM:
	push xiz	; push XIZ
	ld iz, (0x0c00:16)	; ld IZ,(0x0c00) - snapshot the tick counter
	ldi_erpw 0xfa, 0x80, 0x00	; ld QIZ,0x0080
	cpw qiz, 0x80	; cp QIZ,0x0080
	jr nz, FDC_WaitRQM__check_result	; jr NZ,0xffdde1
FDC_WaitRQM__poll:
	calr FDC_ReadStatus	; calr 0xffd7e8
	res 4, l	; res 0x04,L - ignore MSR bit 4 (CB)
	ld a, l	; ld A,L
	cp a, 0x80	; cp A,0x80
	jr z, FDC_WaitRQM__check_timeout	; jr Z,0xffddc9
	cp a, 0xc0	; cp A,0xc0
	jr nz, FDC_WaitRQM__check_timeout	; jr NZ,0xffddc9
	ldiw_erp 0xfa, 0	; ld QIZ,0
FDC_WaitRQM__check_timeout:
	ld wa, (0x0c00:16)	; ld WA,(0x0c00)
	sub wa, iz	; sub WA,IZ
	cp wa, 0x01f4	; cp WA,0x01f4 - timed out after 500 ticks
	jr ule, FDC_WaitRQM__continue	; jr ULE,0xffddda
	ldi_erpw 0xfa, 0xff, 0xff	; ld QIZ,0xffff
FDC_WaitRQM__continue:
	cpw qiz, 0x80	; cp QIZ,0x0080
	jr z, FDC_WaitRQM__poll	; jr Z,0xffddb4
FDC_WaitRQM__check_result:
	cp qiz, 0	; cp QIZ,0
	jr z, FDC_WaitRQM__done	; jr Z,0xffddeb
	ld wa, 2:i3	; ld WA,2
	calr FDC_Error	; calr 0xffe231
FDC_WaitRQM__done:
	pop xiz	; pop XIZ
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_WaitRQM_Timeout - wait for RQM / RQM|DIO, masking MSR with 0xE0
; (formerly Boot_ClearWatchdog -- it is an FDC status wait, no watchdog)
; Same 500-tick timeout structure as FDC_WaitRQM but keeps only
; RQM|DIO|NDM.  On timeout raises error 2.
; Callers: Handler_INT4 (the FDC interrupt handler, kn5000_table_data.s)
; Twin: maincpu FDC_Wait_Status_Timeout (fdc_routines.s:705)
; -----------------------------------------------------------------------------
FDC_WaitRQM_Timeout:
	push xiz	; push XIZ
	ld iz, (0x0c00:16)	; ld IZ,(0x0c00) - snapshot the tick counter
	ldi_erpw 0xfa, 0x80, 0x00	; ld QIZ,0x0080
	cpw qiz, 0x80	; cp QIZ,0x0080
	jr nz, FDC_WaitRQM_Timeout__check_result	; jr NZ,0xffde29
FDC_WaitRQM_Timeout__poll:
	calr FDC_ReadStatus	; calr 0xffd7e8
	and l, 0xe0	; and L,0xe0 - keep RQM|DIO|NDM
	cp l, 0x80	; cp L,0x80
	jr z, FDC_WaitRQM_Timeout__check_timeout	; jr Z,0xffde11
	cp l, 0xc0	; cp L,0xc0
	jr nz, FDC_WaitRQM_Timeout__check_timeout	; jr NZ,0xffde11
	ldiw_erp 0xfa, 0	; ld QIZ,0
FDC_WaitRQM_Timeout__check_timeout:
	ld wa, (0x0c00:16)	; ld WA,(0x0c00)
	sub wa, iz	; sub WA,IZ
	cp wa, 0x01f4	; cp WA,0x01f4 - timed out after 500 ticks
	jr ule, FDC_WaitRQM_Timeout__continue	; jr ULE,0xffde22
	ldi_erpw 0xfa, 0xff, 0xff	; ld QIZ,0xffff
FDC_WaitRQM_Timeout__continue:
	cpw qiz, 0x80	; cp QIZ,0x0080
	jr z, FDC_WaitRQM_Timeout__poll	; jr Z,0xffddfe
FDC_WaitRQM_Timeout__check_result:
	cp qiz, 0	; cp QIZ,0
	jr z, FDC_WaitRQM_Timeout__done	; jr Z,0xffde33
	ld wa, 2:i3	; ld WA,2
	calr FDC_Error	; calr 0xffe231
FDC_WaitRQM_Timeout__done:
	pop xiz	; pop XIZ
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_ReadResultPhase - read all result bytes into 0x0C8E..
; Waits for RQM; while DIO stays set, reads data bytes into the result
; buffer (count in 0x0C8E, ST0 at 0x0C8F).  500-tick timeout -> error 3.
; Twin: maincpu FDC_ResultPhase_Read (fdc_routines.s:752)
; -----------------------------------------------------------------------------
FDC_ReadResultPhase:
	dec 2, xsp	; dec 2,XSP
	push xiz	; push XIZ
	ldw (xsp+4), (0x0c00)	; LDW (XSP+0x04), (0x0C00) - snapshot the tick counter (word mem-to-mem store; bf 04 16 00 0c, formerly emitted as .byte because the assembler lacked the form)
	ldi_erpw 0xfa, 0x80, 0x00	; ld QIZ,0x0080
	cpw qiz, 0x80	; cp QIZ,0x0080
	jr nz, FDC_ReadResultPhase__check_result	; jr NZ,0xffde9c
FDC_ReadResultPhase__poll:
	calr FDC_ReadStatus	; calr 0xffd7e8
	res 4, l	; res 0x04,L
	ld a, l	; ld A,L
	cp a, 0xc0	; cp A,0xc0
	jr z, FDC_ReadResultPhase__begin_read	; jr Z,0xffde60
	cp a, 0x80	; cp A,0x80
	jr nz, FDC_ReadResultPhase__check_timeout	; jr NZ,0xffde83
	ldiw_erp 0xfa, 0	; ld QIZ,0
	jr FDC_ReadResultPhase__check_timeout	; jr T,0xffde83
FDC_ReadResultPhase__begin_read:
	ld iz, 1:i3	; ld IZ,1
	ldiw_erp 0xfa, 0	; ld QIZ,0
	cp qiz, 0	; cp QIZ,0
	jr nz, FDC_ReadResultPhase__check_timeout	; jr NZ,0xffde83
FDC_ReadResultPhase__read_loop:
	calr FDC_ReadData	; calr 0xffd7ee
	lda xwa, (0x0c8e:16)	; lda XWA,0x0c8e
	ld bc, iz	; ld BC,IZ
	extz xbc	; extz XBC
	add xbc, xwa	; add XBC,XWA
	ld (xbc), l	; ld (XBC),L
	calr FDC_ReadStatus	; calr 0xffd7e8
	inc 1, iz	; inc 1,IZ
	cp qiz, 0	; cp QIZ,0
	jr z, FDC_ReadResultPhase__read_loop	; jr Z,0xffde6a
FDC_ReadResultPhase__check_timeout:
	ld wa, (0x0c00:16)	; ld WA,(0x0c00)
	sub wa, (xsp+0x04)	; sub WA,(XSP+0x04)
	cp wa, 0x01f4	; cp WA,0x01f4
	jr ule, FDC_ReadResultPhase__continue	; jr ULE,0xffde95
	ldi_erpw 0xfa, 0xff, 0xff	; ld QIZ,0xffff
FDC_ReadResultPhase__continue:
	cpw qiz, 0x80	; cp QIZ,0x0080
	jr z, FDC_ReadResultPhase__poll	; jr Z,0xffde49
FDC_ReadResultPhase__check_result:
	cp qiz, 0	; cp QIZ,0
	jr z, FDC_ReadResultPhase__done	; jr Z,0xffdea6
	ld wa, 3:i3	; ld WA,3
	calr FDC_Error	; calr 0xffe231
FDC_ReadResultPhase__done:
	pop xiz	; pop XIZ
	inc 2, xsp	; inc 2,XSP
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_SendCommandByte - drain the result phase, then write A to the DATA
; register (a uPD765-style command byte)
; -----------------------------------------------------------------------------
FDC_SendCommandByte:
	dec 2, xsp	; dec 2,XSP
	ld (xsp), a	; ld (XSP),A
	calr FDC_ReadResultPhase	; calr 0xffde35
	ld a, (xsp)	; ld A,(XSP)
	extz wa	; extz WA
	calr FDC_WriteData	; calr 0xffd805
	inc 2, xsp	; inc 2,XSP
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_SendParameterByte - wait for parameter-phase ready (MSR RQM|CB),
; then write A to the DATA register
; -----------------------------------------------------------------------------
FDC_SendParameterByte:
	dec 2, xsp	; dec 2,XSP
	ld (xsp), a	; ld (XSP),A
	calr FDC_WaitComplete	; calr 0xffd851
	ld a, (xsp)	; ld A,(XSP)
	extz wa	; extz WA
	calr FDC_WriteData	; calr 0xffd805
	inc 2, xsp	; inc 2,XSP
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_WriteAuxCmdByte - drain the result phase, then write A to the
; AUXILIARY COMMAND register (0x110008)
; -----------------------------------------------------------------------------
FDC_WriteAuxCmdByte:
	dec 2, xsp	; dec 2,XSP
	ld (xsp), a	; ld (XSP),A
	calr FDC_ReadResultPhase	; calr 0xffde35
	ld a, (xsp)	; ld A,(XSP)
	extz wa	; extz WA
	calr FDC_WriteStatus	; calr 0xffd7f4
	inc 2, xsp	; inc 2,XSP
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_SendAuxCmd - checked aux-command send
; Drains the result phase; if no error is pending, sends A through
; FDC_WriteAuxCmdByte.
; -----------------------------------------------------------------------------
FDC_SendAuxCmd:
	dec 2, xsp	; dec 2,XSP
	ld (xsp), a	; ld (XSP),A
	calr FDC_ReadResultPhase	; calr 0xffde35
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jr nz, FDC_SendAuxCmd__done	; jr NZ,0xffdef2
	ld a, (xsp)	; ld A,(XSP)
	extz wa	; extz WA
	calr FDC_WriteAuxCmdByte	; calr 0xffdecc
FDC_SendAuxCmd__done:
	inc 2, xsp	; inc 2,XSP
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_SendAuxCmdReadResult - aux-command send + one result byte
; Like FDC_SendAuxCmd but afterwards waits for RQM and reads one result
; byte into 0x0C8F (used for aux commands that acknowledge with ST0).
; -----------------------------------------------------------------------------
FDC_SendAuxCmdReadResult:
	dec 2, xsp	; dec 2,XSP
	ld (xsp), a	; ld (XSP),A
	calr FDC_ReadResultPhase	; calr 0xffde35
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jr nz, FDC_SendAuxCmdReadResult__done	; jr NZ,0xffdf14
	ld a, (xsp)	; ld A,(XSP)
	extz wa	; extz WA
	calr FDC_WriteAuxCmdByte	; calr 0xffdecc
	calr FDC_WaitRQM	; calr 0xffdda3
	calr FDC_ReadData	; calr 0xffd7ee
	ld (0x0c8f:16), l	; ld (0x0c8f),L
FDC_SendAuxCmdReadResult__done:
	inc 2, xsp	; inc 2,XSP
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_ProcessResults - decode ST0/ST1 from the result buffer into an error
; ST0 bits 7-6: 00 = OK; 10 = invalid command (returns 0); 11 = ready line
; changed (sets the media-removed flag 0x0D2E).  01 = abnormal: ST0 bit 3
; -> 0x31 not ready, bit 4 -> 0x32 equipment check, else decode ST1:
; missing AM 0x35, not writable 0x2F, no data 0x33, overrun 0x34, CRC
; 0x36, end of cylinder 0x37, otherwise 0x08.
; Callers: Handler_INT4, FDC_MediaConfigAndRecalibrate
; Twin: maincpu FDC_Exception_Status_Decoder (fdc_routines.s:875)
; -----------------------------------------------------------------------------
FDC_ProcessResults:
	lda xde, (0x0c8e:16)	; lda XDE,0x0c8e - XDE = result buffer; +1 holds ST0
	ld c, (xde+0x01)	; ld C,(XDE+0x01)
	ld a, c	; ld A,C
	and a, 0xc0	; and A,0xc0
	cp a, 0x40	; cp A,0x40
	jr z, FDC_ProcessResults__st0_abnormal	; jr Z,0xffdf44
	cp a, 0x80	; cp A,0x80
	jr z, FDC_ProcessResults__st0_invalid_command	; jr Z,0xffdf41 - ST0 bits 7-6 = 10: invalid command issued
	cp a, 0xc0	; cp A,0xc0
	jr z, FDC_ProcessResults__st0_ready_changed	; jr Z,0xffdf39
	cp a, 0:i3	; cp A,0
	jr nz, FDC_ProcessResults__unknown_st0	; jr NZ,0xffdf9f
	ld l, 0:opc	; ld L,0x00
	ret	; ret
FDC_ProcessResults__st0_ready_changed:
	ld (0x0d2e:16), 0xff	; ld (0x0d2e),0xff - ST0 = 11: ready line changed (disk removed)
	ld l, 0:opc	; ld L,0x00
	ret	; ret
FDC_ProcessResults__st0_invalid_command:
	ld l, 0:opc	; ld L,0x00
	ret	; ret
FDC_ProcessResults__st0_abnormal:
	bit 3, c	; bit 0x03,C - ST0 = 01: abnormal termination; ST0 bit 3 = drive not ready
	jr z, FDC_ProcessResults__check_equipment	; jr Z,0xffdf4c - error 0x31 = drive not ready
	ld l, 0x31:opc	; ld L,0x31
	ret	; ret
FDC_ProcessResults__check_equipment:
	bit 4, c	; bit 0x04,C - ST0 bit 4 = equipment check (fault)
	jr z, FDC_ProcessResults__decode_st1	; jr Z,0xffdf54 - error 0x32 = equipment check
	ld l, 0x32:opc	; ld L,0x32
	ret	; ret
FDC_ProcessResults__decode_st1:
	ld c, (xde+0x02)	; ld C,(XDE+0x02) - C = ST1
	bit 0, c	; bit 0x00,C
	jr z, FDC_ProcessResults__check_not_writable	; jr Z,0xffdf62
	ldw wa, 0x35	; ld WA,0x0035 - error 0x35 = missing address mark
	jrl FDC_Error	; jrl T,0xffe231
FDC_ProcessResults__check_not_writable:
	bit 1, c	; bit 0x01,C
	jr z, FDC_ProcessResults__check_no_data	; jr Z,0xffdf6d
	ldw wa, 0x2f	; ld WA,0x002f - error 0x2F = not writable (write-protected)
	jrl FDC_Error	; jrl T,0xffe231
FDC_ProcessResults__check_no_data:
	bit 2, c	; bit 0x02,C
	jr z, FDC_ProcessResults__check_overrun	; jr Z,0xffdf78
	ldw wa, 0x33	; ld WA,0x0033 - error 0x33 = no data (sector not found)
	jrl FDC_Error	; jrl T,0xffe231
FDC_ProcessResults__check_overrun:
	bit 4, c	; bit 0x04,C
	jr z, FDC_ProcessResults__check_data_error	; jr Z,0xffdf83
	ldw wa, 0x34	; ld WA,0x0034 - error 0x34 = overrun
	jrl FDC_Error	; jrl T,0xffe231
FDC_ProcessResults__check_data_error:
	bit 5, c	; bit 0x05,C
	jr z, FDC_ProcessResults__check_end_of_cyl	; jr Z,0xffdf8e
	ldw wa, 0x36	; ld WA,0x0036 - error 0x36 = data CRC error
	jrl FDC_Error	; jrl T,0xffe231
FDC_ProcessResults__check_end_of_cyl:
	bit 7, c	; bit 0x07,C
	jr z, FDC_ProcessResults__generic_error	; jr Z,0xffdf99
	ldw wa, 0x37	; ld WA,0x0037 - error 0x37 = end of cylinder
	jrl FDC_Error	; jrl T,0xffe231
FDC_ProcessResults__generic_error:
	ldw wa, 8	; ld WA,0x0008 - error 0x08 = unspecified FDC error
	jrl FDC_Error	; jrl T,0xffe231
FDC_ProcessResults__unknown_st0:
	ld l, 8:opc	; ld L,0x08
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_EnableIntAndDMA - enable the FDC interrupt paths
; Clears pending INT4 (INTCLR = 0x0B) and sets INTE45 to priority 4, then
; clears pending INTTC3 (INTCLR = 0x28) and sets INTETC23's high nibble to
; 5 -- INT4 = FDC IRQ, INTTC3 = DMA3 terminal count.
; Twin: part of maincpu FDC_HardwareSetup (fdc_routines.s:972)
; -----------------------------------------------------------------------------
FDC_EnableIntAndDMA:
	ld (0xf8:8), 0x0b:io	; ld (0xf8),0x0b - INTCLR = 0x0B: clear pending INT4 (FDC IRQ)
	lda_dd8l xbc, 0xe0	; lda XBC,0xe0 - XBC = SFR 0xE0 = INTE45
	ld a, (xbc)	; ld A,(XBC)
	and a, 0xf8	; and A,0xf8
	set 2, a	; set 0x02,A - INT4 priority level 4 (enables the FDC interrupt)
	ld (xbc), a	; ld (XBC),A
	ld (0xf8:8), 0x28:io	; ld (0xf8),0x28 - INTCLR = 0x28: clear pending INTTC3 (DMA3 end)
	lda_dd8l xbc, 0xed	; lda XBC,0xed - XBC = SFR 0xED = INTETC23
	ld a, (xbc)	; ld A,(XBC)
	and a, 0x8f	; and A,0x8f
	or a, 0x50	; or A,0x50 - INTTC3 priority level 5 (enables DMA3 end interrupt)
	ld (xbc), a	; ld (XBC),A
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_IssueCommand - issue one FDC command with all its parameter bytes
; A = opcode.  Waits for ready, records the opcode in 0x0C56, validates it
; (FDC_ValidateOpcode), then routes it:
;   aux 0x33/0x34 -> send + read result; aux 0x35/0x36/0x47 -> plain send;
;   aux select-format 0x4F/0x5F, enable-motors x[0x0E], control-internal-
;   mode x[0x0B] -> send + read result;
;   anything else is a uPD765-style command: the opcode goes to the DATA
;   register, then SENSE INTERRUPT STATUS (0x08) takes no parameters,
;   SPECIFY (0x03) takes SRT/HUT + HLT/ND, and all others get the
;   unit/head byte followed by their specific parameters (SEEK the target
;   track; FORMAT N/SC/GPL/D; RECALIBRATE/SENSE DRIVE STATUS/READ ID
;   nothing more; read/write/scan C,H,R,N,EOT,GPL and DTL or STP).
; Outputs: (0x0C52) sticky status; result bytes via the INT4 path
; Twin: maincpu FDC_HardwareSetup command marshaller (fdc_routines.s:972)
; -----------------------------------------------------------------------------
FDC_IssueCommand:
	dec 2, xsp	; dec 2,XSP
	ld (xsp), a	; ld (XSP),A
	calr FDC_WaitReady	; calr 0xffd80b
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jrl nz, FDC_IssueCommand__done	; jrl NZ,0xffe0a8
	ld a, (xsp)	; ld A,(XSP)
	ld (0x0c56:16), a	; ld (0x0c56),A
	calr FDC_ValidateOpcode	; calr 0xffe0ab
	cp l, 0:i3	; cp L,0
	jrl nz, FDC_IssueCommand__done	; jrl NZ,0xffe0a8
	ld a, (xsp)	; ld A,(XSP)
	cp a, 0x33	; cp A,0x33
	jr z, FDC_IssueCommand__send_aux_result	; jr Z,0xffe005
	cp a, 0x34	; cp A,0x34 - aux commands 0x33 (ext mode) / 0x34 sent with result readback
	jr z, FDC_IssueCommand__send_aux_result	; jr Z,0xffe005
	cp a, 0x36	; cp A,0x36
	jr z, FDC_IssueCommand__send_aux	; jr Z,0xffdffb
	cp a, 0x35	; cp A,0x35
	jr z, FDC_IssueCommand__send_aux	; jr Z,0xffdffb
	cp a, 0x47	; cp A,0x47
	jr nz, FDC_IssueCommand__check_select_format	; jr NZ,0xffe00f
FDC_IssueCommand__send_aux:
	ld a, (xsp)	; ld A,(XSP)
	extz wa	; extz WA
	calr FDC_SendAuxCmd	; calr 0xffdedd
	jrl FDC_IssueCommand__done	; jrl T,0xffe0a8
FDC_IssueCommand__send_aux_result:
	ld a, (xsp)	; ld A,(XSP)
	extz wa	; extz WA
	calr FDC_SendAuxCmdReadResult	; calr 0xffdef5
	jrl FDC_IssueCommand__done	; jrl T,0xffe0a8
FDC_IssueCommand__check_select_format:
	ld a, (xsp)	; ld A,(XSP) - 0x4F/0x5F = aux select format
	res 4, a	; res 0x04,A
	cp a, 0x4f	; cp A,0x4f
	jr nz, FDC_IssueCommand__check_aux_nibble	; jr NZ,0xffe023
	ld a, (xsp)	; ld A,(XSP)
	extz wa	; extz WA
	calr FDC_SendAuxCmdReadResult	; calr 0xffdef5
	jrl FDC_IssueCommand__done	; jrl T,0xffe0a8
FDC_IssueCommand__check_aux_nibble:
	ld a, (xsp)	; ld A,(XSP)
	and a, 0x0f	; and A,0x0f
	cp a, 0x0e	; cp A,0x0e - low nibble 0x0E = aux enable motors
	jr z, FDC_IssueCommand__send_aux_result2	; jr Z,0xffe037
	ld a, (xsp)	; ld A,(XSP)
	and a, 0x0f	; and A,0x0f
	cp a, 0x0b	; cp A,0x0b - low nibble 0x0B = aux control internal mode
	jr nz, FDC_IssueCommand__send_normal_cmd	; jr NZ,0xffe040
FDC_IssueCommand__send_aux_result2:
	ld a, (xsp)	; ld A,(XSP)
	extz wa	; extz WA
	calr FDC_SendAuxCmdReadResult	; calr 0xffdef5
	jr FDC_IssueCommand__done	; jr T,0xffe0a8
FDC_IssueCommand__send_normal_cmd:
	ld a, (xsp)	; ld A,(XSP)
	extz wa	; extz WA
	calr FDC_SendCommandByte	; calr 0xffdeaa
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jr nz, FDC_IssueCommand__done	; jr NZ,0xffe0a8
	cp (xsp), 0x08	; cp (XSP),0x08 - 0x08 = SENSE INTERRUPT STATUS: no parameter bytes
	jr z, FDC_IssueCommand__done	; jr Z,0xffe0a8
	cp (xsp), 0x03	; cp (XSP),0x03 - 0x03 = SPECIFY: send SRT/HUT + HLT/ND
	jr nz, FDC_IssueCommand__send_unit_head	; jr NZ,0xffe05d
	calr FDC_SendParams_Specify	; calr 0xffe106
	jr FDC_IssueCommand__done	; jr T,0xffe0a8
FDC_IssueCommand__send_unit_head:
	ld a, (0x0c57:16)	; ld A,(0x0c57) - build the unit/head parameter byte
	and a, 1	; and A,0x01
	sll a, 2	; sll 0x02,A
	ld e, a	; ld E,A
	ld a, (0x0c58:16)	; ld A,(0x0c58)
	and a, 3	; and A,0x03
	ld c, a	; ld C,A
	ld a, e	; ld A,E
	or a, c	; or A,C - dead code: the OR with the drive bits is discarded by the next insn
	ld a, e	; ld A,E
	set 0, a	; set 0x00,A - the byte actually sent is head<<2 | 1 (unit fixed to 1)
	extz wa	; extz WA
	calr FDC_SendParameterByte	; calr 0xffdebb
	ld a, (xsp)	; ld A,(XSP) - 0x0F = SEEK: send the target track
	cp a, 0x0f	; cp A,0x0f
	jr z, FDC_IssueCommand__seek_param	; jr Z,0xffe0a0
	cp a, 0x4d	; cp A,0x4d - 0x4D = FORMAT TRACK: send N/SC/GPL/D
	jr z, FDC_IssueCommand__format_params	; jr Z,0xffe09b
	cp a, 7:i3	; cp A,7
	jr z, FDC_IssueCommand__no_more_params	; jr Z,0xffe099
	cp a, 4:i3	; cp A,4
	jr z, FDC_IssueCommand__no_more_params	; jr Z,0xffe099
	cp a, 0x4a	; cp A,0x4a
	jr nz, FDC_IssueCommand__rw_params	; jr NZ,0xffe0a5
FDC_IssueCommand__no_more_params:
	jr FDC_IssueCommand__done	; jr T,0xffe0a8
FDC_IssueCommand__format_params:
	calr FDC_SendParams_Format	; calr 0xffe13c
	jr FDC_IssueCommand__done	; jr T,0xffe0a8
FDC_IssueCommand__seek_param:
	calr FDC_SendParam_SeekTrack	; calr 0xffe163
	jr FDC_IssueCommand__done	; jr T,0xffe0a8
FDC_IssueCommand__rw_params:
	calr FDC_SendParams_ReadWrite	; calr 0xffe16c
FDC_IssueCommand__done:
	inc 2, xsp	; inc 2,XSP
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_ValidateOpcode - is (0x0C56) a recognizable FDC opcode?
; Accepts the aux commands 0x4F/0x33/0x34/0x47/0x35 outright; otherwise
; masks with 0x1F and accepts 0x02-0x0F plus the scan opcodes
; 0x11/0x19/0x1D/0x1E.  Returns L = 0 when valid, 1 when not.
; -----------------------------------------------------------------------------
FDC_ValidateOpcode:
	ld a, (0x0c56:16)	; ld A,(0x0c56)
	cp a, 0x4f	; cp A,0x4f
	jr z, FDC_ValidateOpcode__aux_ok	; jr Z,0xffe0c8
	cp a, 0x33	; cp A,0x33
	jr z, FDC_ValidateOpcode__aux_ok	; jr Z,0xffe0c8
	cp a, 0x34	; cp A,0x34
	jr z, FDC_ValidateOpcode__aux_ok	; jr Z,0xffe0c8
	cp a, 0x47	; cp A,0x47
	jr z, FDC_ValidateOpcode__aux_ok	; jr Z,0xffe0c8
	cp a, 0x35	; cp A,0x35
	jr nz, FDC_ValidateOpcode__check_masked	; jr NZ,0xffe0cb
FDC_ValidateOpcode__aux_ok:
	ld l, 0:opc	; ld L,0x00
	ret	; ret
FDC_ValidateOpcode__check_masked:
	ld a, (0x0c56:16)	; ld A,(0x0c56)
	and a, 0x1f	; and A,0x1f
	cp a, 0x1e	; cp A,0x1e
	jr z, FDC_ValidateOpcode__ok	; jr Z,0xffe0f4
	cp a, 0x1d	; cp A,0x1d
	jr z, FDC_ValidateOpcode__ok	; jr Z,0xffe0f4
	cp a, 0x19	; cp A,0x19
	jr z, FDC_ValidateOpcode__ok	; jr Z,0xffe0f4
	cp a, 0x10	; cp A,0x10
	jr z, FDC_ValidateOpcode__invalid	; jr Z,0xffe0f7
	cp a, 0x11	; cp A,0x11
	jr z, FDC_ValidateOpcode__ok	; jr Z,0xffe0f4
	cp a, 0x0f	; cp A,0x0f
	jr ugt, FDC_ValidateOpcode__invalid	; jr UGT,0xffe0f7
	cp a, 2:i3	; cp A,2
	jr c, FDC_ValidateOpcode__invalid	; jr C,0xffe0f7
FDC_ValidateOpcode__ok:
	ld l, 0:opc	; ld L,0x00
	ret	; ret
FDC_ValidateOpcode__invalid:
	ld l, 1:opc	; ld L,0x01
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_SendParam_ScanSTP - send (0x0C63) & 3 = STP for the scan commands
; -----------------------------------------------------------------------------
FDC_SendParam_ScanSTP:
	ld a, (0x0c63:16)	; ld A,(0x0c63)
	and a, 3	; and A,0x03
	extz wa	; extz WA
	jrl FDC_SendParameterByte	; jrl T,0xffdebb

; -----------------------------------------------------------------------------
; FDC_SendParams_Specify - send SRT<<4|HUT then HLT<<1|ND
; -----------------------------------------------------------------------------
FDC_SendParams_Specify:
	ld a, (0x0c65:16)	; ld A,(0x0c65)
	sll a, 4	; sll 0x04,A - SRT in the high nibble
	ld e, a	; ld E,A
	ld a, (0x0c66:16)	; ld A,(0x0c66)
	and a, 0x0f	; and A,0x0f - HUT in the low nibble
	ld c, a	; ld C,A
	ld a, e	; ld A,E
	or a, c	; or A,C
	extz wa	; extz WA
	calr FDC_SendParameterByte	; calr 0xffdebb
	ld a, (0x0c67:16)	; ld A,(0x0c67)
	sll a, 1	; sll 0x01,A - HLT << 1
	ld e, a	; ld E,A
	ld a, (0x0c68:16)	; ld A,(0x0c68) - ND in bit 0
	and a, 1	; and A,0x01
	ld c, a	; ld C,A
	ld a, e	; ld A,E
	or a, c	; or A,C
	extz wa	; extz WA
	jrl FDC_SendParameterByte	; jrl T,0xffdebb

; -----------------------------------------------------------------------------
; FDC_SendParams_Format - send N, SC, GPL(format), D for FORMAT TRACK
; -----------------------------------------------------------------------------
FDC_SendParams_Format:
	ld a, (0x0c5c:16)	; ld A,(0x0c5c)
	and a, 7	; and A,0x07
	extz wa	; extz WA
	calr FDC_SendParameterByte	; calr 0xffdebb
	ld a, (0x0c60:16)	; ld A,(0x0c60) - SC = sectors per track
	extz wa	; extz WA
	calr FDC_SendParameterByte	; calr 0xffdebb
	ld a, (0x0c61:16)	; ld A,(0x0c61) - GPL = format gap length
	extz wa	; extz WA
	calr FDC_SendParameterByte	; calr 0xffdebb
	ld a, (0x0c62:16)	; ld A,(0x0c62) - D = fill byte (0xE5)
	extz wa	; extz WA
	jrl FDC_SendParameterByte	; jrl T,0xffdebb

; -----------------------------------------------------------------------------
; FDC_SendParam_SeekTrack - send (0x0C64) = target track for SEEK
; -----------------------------------------------------------------------------
FDC_SendParam_SeekTrack:
	ld a, (0x0c64:16)	; ld A,(0x0c64) - NCN = target track for SEEK
	extz wa	; extz WA
	jrl FDC_SendParameterByte	; jrl T,0xffdebb

; -----------------------------------------------------------------------------
; FDC_SendParams_ReadWrite - send C,H,R,N,EOT,GPL then DTL (or STP for
; the scan opcodes 0xD1/0xD9/0xDD)
; -----------------------------------------------------------------------------
FDC_SendParams_ReadWrite:
	ld a, (0x0c59:16)	; ld A,(0x0c59) - C = track
	extz wa	; extz WA
	calr FDC_SendParameterByte	; calr 0xffdebb
	ld a, (0x0c5a:16)	; ld A,(0x0c5a) - H = head
	and a, 1	; and A,0x01
	extz wa	; extz WA
	calr FDC_SendParameterByte	; calr 0xffdebb
	ld a, (0x0c5b:16)	; ld A,(0x0c5b) - R = starting sector
	extz wa	; extz WA
	calr FDC_SendParameterByte	; calr 0xffdebb
	ld a, (0x0c5c:16)	; ld A,(0x0c5c) - N = sector-size code
	and a, 7	; and A,0x07
	extz wa	; extz WA
	calr FDC_SendParameterByte	; calr 0xffdebb
	ld a, (0x0c5d:16)	; ld A,(0x0c5d) - EOT = last sector of the burst
	extz wa	; extz WA
	calr FDC_SendParameterByte	; calr 0xffdebb
	ld a, (0x0c5e:16)	; ld A,(0x0c5e) - GPL = read/write gap length
	extz wa	; extz WA
	calr FDC_SendParameterByte	; calr 0xffdebb
	ld a, (0x0c56:16)	; ld A,(0x0c56) - scan commands take STP instead of DTL
	cp a, 0xdd	; cp A,0xdd
	jr z, FDC_SendParams_ReadWrite__send_stp	; jr Z,0xffe1bb
	cp a, 0xd9	; cp A,0xd9
	jr z, FDC_SendParams_ReadWrite__send_stp	; jr Z,0xffe1bb
	cp a, 0xd1	; cp A,0xd1
	jr nz, FDC_SendParams_ReadWrite__send_dtl	; jr NZ,0xffe1be
FDC_SendParams_ReadWrite__send_stp:
	jrl FDC_SendParam_ScanSTP	; jrl T,0xffe0fa
FDC_SendParams_ReadWrite__send_dtl:
	ld a, (0x0c5f:16)	; ld A,(0x0c5f) - DTL = 0xFF (N nonzero, DTL unused)
	extz wa	; extz WA
	calr FDC_SendParameterByte	; calr 0xffdebb
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_IsMediaProbeRead - is the current request the boot-disk probe read?
; Returns HL = 0xFFFF when: drive 0, head 0, cmd 3 (read), count 1, the
; probe flag (0x0C3E) is 0xFFFF and the sector is 2 or 0xFF.  The probe
; issued by FDC_ProbeDiskFormat gets a single retry and forces a re-seek.
; -----------------------------------------------------------------------------
FDC_IsMediaProbeRead:
	cpw (0x0c74:16), 0	; cp (0x0c74),0x0000
	jr z, FDC_IsMediaProbeRead__check_head	; jr Z,0xffe1d3
	ld hl, 0:i3	; ld HL,0
	ret	; ret
FDC_IsMediaProbeRead__check_head:
	cpw (0x0c72:16), 0	; cp (0x0c72),0x0000
	jr z, FDC_IsMediaProbeRead__check_command	; jr Z,0xffe1de
	ld hl, 0:i3	; ld HL,0
	ret	; ret
FDC_IsMediaProbeRead__check_command:
	cpw (0x0c6e:16), 3	; cp (0x0c6e),0x0003
	jr z, FDC_IsMediaProbeRead__check_count	; jr Z,0xffe1e9
	ld hl, 0:i3	; ld HL,0
	ret	; ret
FDC_IsMediaProbeRead__check_count:
	cpw (0x0c78:16), 1	; cp (0x0c78),0x0001
	jr z, FDC_IsMediaProbeRead__check_probe_flag	; jr Z,0xffe1f4
	ld hl, 0:i3	; ld HL,0
	ret	; ret
FDC_IsMediaProbeRead__check_probe_flag:
	cpw (0x0c3e:16), 0xffff	; cp (0x0c3e),0xffff
	jr z, FDC_IsMediaProbeRead__check_sector	; jr Z,0xffe1ff
	ld hl, 0:i3	; ld HL,0
	ret	; ret
FDC_IsMediaProbeRead__check_sector:
	cpw (0x0c76:16), 2	; cp (0x0c76),0x0002
	jr z, FDC_IsMediaProbeRead__is_probe	; jr Z,0xffe20f
	cpw (0x0c76:16), 0xff	; cp (0x0c76),0x00ff
	jr nz, FDC_IsMediaProbeRead__not_probe	; jr NZ,0xffe213
FDC_IsMediaProbeRead__is_probe:
	ldw hl, 0xffff	; ld HL,0xffff
	ret	; ret
FDC_IsMediaProbeRead__not_probe:
	ld hl, 0:i3	; ld HL,0
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_IsMediaProbeInit - probe variant of command 0
; Returns HL = 0xFFFF when count = 0xFFFF (sentinel) and cmd = 0.
; -----------------------------------------------------------------------------
FDC_IsMediaProbeInit:
	cpw (0x0c78:16), 0xffff	; cp (0x0c78),0xffff
	jr z, FDC_IsMediaProbeInit__check_command	; jr Z,0xffe221
	ld hl, 0:i3	; ld HL,0
	ret	; ret
FDC_IsMediaProbeInit__check_command:
	cpw (0x0c6e:16), 0	; cp (0x0c6e),0x0000
	jr z, FDC_IsMediaProbeInit__is_probe	; jr Z,0xffe22c
	ld hl, 0:i3	; ld HL,0
	ret	; ret
FDC_IsMediaProbeInit__is_probe:
	ldw hl, 0xffff	; ld HL,0xffff
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_FormatPrepareStub - empty pre-format hook kept for its call site
; -----------------------------------------------------------------------------
FDC_FormatPrepareStub:
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_Error - record a request error (first error wins)
; A = error code.  Only stored if (0x0C52) is still 0; the nop islands are
; patched-out per-code hooks (codes 0x33/0x35/0x36).  Returns L = status.
; Callers: throughout the driver; also from the already-disassembled
;          helpers FDC_WaitReady/FDC_WaitComplete above this module
; Twin: maincpu FDC_Set_Status (fdc_routines.s:1303)
; -----------------------------------------------------------------------------
FDC_Error:
	cp (0x0c52:16), 0	; cp (0x0c52),0x00 - error codes stick: only the FIRST error of a request is kept
	jr nz, FDC_Error__already_set	; jr NZ,0xffe254
	ld (0x0c52:16), a	; ld (0x0c52),A
	cp a, 0x36	; cp A,0x36
	jr z, FDC_Error__hook_err36	; jr Z,0xffe251
	cp a, 0x35	; cp A,0x35
	jr z, FDC_Error__hook_err35	; jr Z,0xffe24e
	cp a, 0x33	; cp A,0x33
	jr nz, FDC_Error__return	; jr NZ,0xffe255
	nop	; nop
	jr FDC_Error__return	; jr T,0xffe255
FDC_Error__hook_err35:
	nop	; nop
	jr FDC_Error__return	; jr T,0xffe255
FDC_Error__hook_err36:
	nop	; nop
	jr FDC_Error__return	; jr T,0xffe255
FDC_Error__already_set:
	nop	; nop
FDC_Error__return:
	ld l, (0x0c52:16)	; ld L,(0x0c52)
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_ClearError - clear the sticky request status (0x0C52)
; -----------------------------------------------------------------------------
FDC_ClearError:
	ld (0x0c52:16), 0	; ld (0x0c52),0x00
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_ClearResultBuf - mark the result buffer empty (0x0C8E = 0xFF)
; -----------------------------------------------------------------------------
FDC_ClearResultBuf:
	ld (0x0c8e:16), 0xff	; ld (0x0c8e),0xff
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_WaitResult - wait until the INT4 path fills the result buffer
; Polls (0x0C8E) != 0xFF with a 500-tick timeout -> error 9.
; Twin: maincpu FDC_ClearStatus_InitTimer tail (fdc_routines.s:1337)
; -----------------------------------------------------------------------------
FDC_WaitResult:
	push xiz	; push XIZ
	ldi_erpw 0xfa, 0xf4, 0x01	; ld QIZ,0x01f4
	ld iz, (0x0c00:16)	; ld IZ,(0x0c00)
	ld bc, 0:i3	; ld BC,0
FDC_WaitResult__poll:
	cp (0x0c8e:16), 0xff	; cp (0x0c8e),0xff
	jr z, FDC_WaitResult__check_timeout	; jr Z,0xffe27c
	ldw bc, 0xffff	; ld BC,0xffff
FDC_WaitResult__check_timeout:
	ld wa, (0x0c00:16)	; ld WA,(0x0c00)
	sub wa, iz	; sub WA,IZ
	cp wa, qiz	; cp WA,QIZ
	jr ule, FDC_WaitResult__check_done	; jr ULE,0xffe290
	ldw wa, 9	; ld WA,0x0009
	calr FDC_Error	; calr 0xffe231
	ldw bc, 0xffff	; ld BC,0xffff
FDC_WaitResult__check_done:
	cp bc, 0:i3	; cp BC,0
	jr z, FDC_WaitResult__poll	; jr Z,0xffe272
	pop xiz	; pop XIZ
	ret	; ret

; -----------------------------------------------------------------------------
; Boot_Delay - busy-wait WA/2 ticks of the system tick counter (0x0C00)
; Twin: maincpu SOME_DELAY (fdc_routines.s:1370)
; -----------------------------------------------------------------------------
Boot_Delay:
	srl wa, 1	; srl 0x01,WA
	ld de, (0x0c00:16)	; ld DE,(0x0c00)
	ld hl, 0:i3	; ld HL,0
	cp hl, 0xffff	; cp HL,0xffff
	ret nc	; ret NC
Boot_Delay__wait_loop:
	ld bc, (0x0c00:16)	; ld BC,(0x0c00)
	sub bc, de	; sub BC,DE
	cp bc, wa	; cp BC,WA
	ret ugt	; ret UGT
	inc 1, hl	; inc 1,HL
	cp hl, 0xffff	; cp HL,0xffff
	jr c, Boot_Delay__wait_loop	; jr C,0xffe2a5
	ret	; ret

; -----------------------------------------------------------------------------
; Boot_Delay40 - Boot_Delay with a fixed 40-tick argument
; -----------------------------------------------------------------------------
Boot_Delay40:
	ldw wa, 40	; ld WA,0x0028
	jr Boot_Delay	; jr T,0xffe296

; -----------------------------------------------------------------------------
; FDC_CmdInitialize - command 0: full drive initialization
; Display refresh + TC pulse, clears the disk-changed and media-removed
; flags, enables INT4/INTTC3, strobes a seek and runs the full media
; configuration.
; Twin: maincpu FDC_InitSequence_Full (fdc_routines.s:1392)
; -----------------------------------------------------------------------------
FDC_CmdInitialize:
	calr Boot_UpdateDisplayThunk	; calr 0xffdd24 - cmd 0 entry
	calr FDC_PulseTC	; calr 0xffdd17
	ld (0x0c98:16), 0	; ld (0x0c98),0x00
	ld (0x0d2e:16), 0	; ld (0x0d2e),0x00
	calr FDC_EnableIntAndDMA	; calr 0xffdfa2
	calr FDC_Seek	; calr 0xffd894
	jrl FDC_MediaConfigAndRecalibrate	; jrl T,0xffd8a5

; -----------------------------------------------------------------------------
; FDC_CmdRecalibrate - command 1: recalibrate to track 0
; Seeks to track 5 first (head-load settling), then issues RECALIBRATE
; (0x07) and waits for the result.  On failure invalidates the track
; cache.  Preserves the caller's target track.
; Twin: maincpu FDC_CmdRecalibrate (fdc_routines.s:1408)
; -----------------------------------------------------------------------------
FDC_CmdRecalibrate:
	pushw_erp 0xfa	; push QIZ - cmd 1 entry
	ld a, (0x0c64:16)	; ld A,(0x0c64)
	ldfr_berp a, 0xfb	; ld QIZH,A
	ld (0x0c64:16), 5	; ld (0x0c64),0x05
	ld (0x0d32:16), 0xff	; ld (0x0d32),0xff - recalibrate homes via track 5 first (head-load settling)
	calr FDC_CmdSeek	; calr 0xffe31a
	ld (0x0d32:16), 0	; ld (0x0d32),0x00
	calr FDC_ClearResultBuf	; calr 0xffe260
	ld wa, 7:i3	; ld WA,7 - 0x07 = RECALIBRATE
	calr FDC_IssueCommand	; calr 0xffdfc3
	calr FDC_WaitResult	; calr 0xffe266
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jr z, FDC_CmdRecalibrate__restore	; jr Z,0xffe309
	ld (0x0d32:16), 0xff	; ld (0x0d32),0xff
FDC_CmdRecalibrate__restore:
	ldto_berp a, 0xfb	; ld A,QIZH
	ld (0x0c64:16), a	; ld (0x0c64),A
	ldw wa, 0x10	; ld WA,0x0010
	calr Boot_Delay	; calr 0xffe296
	popw_erp 0xfa	; pop QIZ
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_CmdSeek - command 2: seek to the target track (0x0C64)
; No-op when the track cache (0x0D32) already matches.  Issues SEEK (0x0F),
; waits for the result, then settles with WA=0x10 (Boot_Delay waits WA/2).
; Twin: maincpu FDC_CmdSeek (fdc_routines.s dispatch entry 2)
; -----------------------------------------------------------------------------
FDC_CmdSeek:
	ld a, (0x0c64:16)	; ld A,(0x0c64) - cmd 2 entry
	cp a, (0x0d32:16)	; cp A,(0x0d32)
	ret z	; ret Z
	ldmm8 (0x0d32), (0x0c64)	; ld (0x0d32),(0x0c64)
	ld wa, 2:i3	; ld WA,2
	calr Boot_Delay	; calr 0xffe296
	calr FDC_ClearResultBuf	; calr 0xffe260
	ldw wa, 0x0f	; ld WA,0x000f - 0x0F = SEEK
	calr FDC_IssueCommand	; calr 0xffdfc3
	calr FDC_WaitResult	; calr 0xffe266
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jr z, FDC_CmdSeek__settle	; jr Z,0xffe347
	ld (0x0d32:16), 0xff	; ld (0x0d32),0xff
FDC_CmdSeek__settle:
	ldw wa, 16	; ld WA,0x0010
	jrl Boot_Delay	; jrl T,0xffe296

; -----------------------------------------------------------------------------
; FDC_SubmitReadDataCmd - arm DMA and issue MT|MF READ DATA (0xC6)
; -----------------------------------------------------------------------------
FDC_SubmitReadDataCmd:
	ld (0x0c56:16), 0xc6	; ld (0x0c56),0xc6 - 0xC6 = MT|MF READ DATA
	calr FDC_SetupDMAMode	; calr 0xffdd2c
	calr FDC_ClearResultBuf	; calr 0xffe260
	ldw wa, 0xc6	; ld WA,0x00c6
	calr FDC_IssueCommand	; calr 0xffdfc3
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	ret nz	; ret NZ
	jrl FDC_WaitResult	; jrl T,0xffe266

; -----------------------------------------------------------------------------
; FDC_CmdReadSectors - command 3: multi-sector read with retries
; Seeks, then per attempt builds the largest same-track burst (walking
; sector/count, 512 or 1024 bytes per sector), submits READ DATA via DMA3
; and on success advances the buffer, flips the head and steps the track.
; 8 retries (1 for the media probe); error 9 (ready change) aborts via a
; seek strobe; other errors re-run the media configuration first.
; Exhausted retries -> error 0x10.
; Twin: maincpu FDC_CMD_EXEC (fdc_routines.s:1484)
; -----------------------------------------------------------------------------
FDC_CmdReadSectors:
	pushw iz	; push IZ - cmd 3 entry
	calr FDC_IsMediaProbeRead	; calr 0xffe1c8
	cp hl, 0:i3	; cp HL,0
	jr nz, FDC_CmdReadSectors__single_retry	; jr NZ,0xffe378
	ld (0x0c96:16), 8	; ld (0x0c96),0x08 - normal request: up to 8 retries
	jrl FDC_CmdReadSectors__check_remaining	; jrl T,0xffe49f
FDC_CmdReadSectors__single_retry:
	ld (0x0c96:16), 1	; ld (0x0c96),0x01 - media-probe read: a single attempt
	jrl FDC_CmdReadSectors__check_remaining	; jrl T,0xffe49f
FDC_CmdReadSectors__retry:
	ld (0x0c52:16), 0	; ld (0x0c52),0x00
	calr FDC_CmdSeek	; calr 0xffe31a
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jr z, FDC_CmdReadSectors__seek_ok	; jr Z,0xffe3a5
	ld a, (0x0c52:16)	; ld A,(0x0c52)
	ldfr_berp a, 0xf8	; ld IZL,A
	exts iz	; exts IZ
	calr FDC_MediaConfigAndRecalibrate	; calr 0xffd8a5
	ldto_berp a, 0xf8	; ld A,IZL
	ld (0x0c52:16), a	; ld (0x0c52),A
	jrl FDC_CmdReadSectors__done	; jrl T,0xffe4a8
FDC_CmdReadSectors__seek_ok:
	ld wa, (0x0c76:16)	; ld WA,(0x0c76)
	cp wa, (0x0d3a:16)	; cp WA,(0x0d3a)
	jr ule, FDC_CmdReadSectors__save_position	; jr ULE,0xffe3b5
	ldw (0x0c76:16), 1	; ld (0x0c76),0x0001
FDC_CmdReadSectors__save_position:
	ldmm16 (0x0d3e), (0x0c76)	; ldw (0x0d3e),(0x0c76)
	ldw (0x0c4a:16), 0	; ld (0x0c4a),0x0000
	cp (0x0c9a:16), 2	; cp (0x0c9a),0x02 - media format 2 uses 1024-byte sectors
	jr nz, FDC_CmdReadSectors__sector_512	; jr NZ,0xffe3d0
	ldw (0x0c4c:16), 0x0400	; ld (0x0c4c),0x0400
	jr FDC_CmdReadSectors__count_burst	; jr T,0xffe3d6
FDC_CmdReadSectors__sector_512:
	ldw (0x0c4c:16), 0x0200	; ld (0x0c4c),0x0200
FDC_CmdReadSectors__count_burst:
	ldmm16 (0x0d40), (0x0c78)	; ldw (0x0d40),(0x0c78)
	ld iz, 1:i3	; ld IZ,1
FDC_CmdReadSectors__burst_loop:
	ld wa, (0x0c4c:16)	; ld WA,(0x0c4c)
	add (0x0c4a:16), wa	; add (0x0c4a),WA
	lda xwa, (0x0c78:16)	; lda XWA,0x0c78
	decm 1, (xwa)	; decw 1,(XWA)
	ld wa, (xwa)	; ld WA,(XWA)
	cp wa, 0:i3	; cp WA,0
	jr z, FDC_CmdReadSectors__submit	; jr Z,0xffe404
	lda xwa, (0x0c76:16)	; lda XWA,0x0c76
	incw 1, (xwa)	; incw 1,(XWA)
	ld wa, (xwa)	; ld WA,(XWA)
	cp wa, (0x0d3a:16)	; cp WA,(0x0d3a)
	jr ugt, FDC_CmdReadSectors__submit	; jr UGT,0xffe404
	inc 1, iz	; inc 1,IZ
	jr FDC_CmdReadSectors__burst_loop	; jr T,0xffe3de
FDC_CmdReadSectors__submit:
	ld (0x0c78:16), iz	; ld (0x0c78),IZ
	ldmm16 (0x0c76), (0x0d3e)	; ldw (0x0c76),(0x0d3e)
	calr FDC_SubmitReadDataCmd	; calr 0xffe34d
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jr z, FDC_CmdReadSectors__advance	; jr Z,0xffe452
	cp (0x0c52:16), 9	; cp (0x0c52),0x09 - error 9 = ready-line change: strobe seek and abort
	jr nz, FDC_CmdReadSectors__recover	; jr NZ,0xffe425
	calr FDC_Seek	; calr 0xffd894
	jrl FDC_CmdReadSectors__done	; jrl T,0xffe4a8
FDC_CmdReadSectors__recover:
	calr FDC_IsMediaProbeRead	; calr 0xffe1c8
	cp hl, 0xffff	; cp HL,0xffff
	jr z, FDC_CmdReadSectors__next_retry	; jr Z,0xffe439
	calr FDC_MediaConfigAndRecalibrate	; calr 0xffd8a5
	ld (0x0d32:16), 0xff	; ld (0x0d32),0xff
	calr FDC_CmdSeek	; calr 0xffe31a
FDC_CmdReadSectors__next_retry:
	ldmm16 (0x0c78), (0x0d40)	; ldw (0x0c78),(0x0d40)
	dec 1, (0x0c96:16)	; dec 1,(0x0c96)
	ld a, (0x0c96:16)	; ld A,(0x0c96)
	cp a, 0:i3	; cp A,0
	jr nz, FDC_CmdReadSectors__check_remaining	; jr NZ,0xffe49f
	ld (0x0c52:16), 0x10	; ld (0x0c52),0x10 - error 0x10 = read retries exhausted
	jr FDC_CmdReadSectors__done	; jr T,0xffe4a8
FDC_CmdReadSectors__advance:
	ld wa, (0x0d40:16)	; ld WA,(0x0d40)
	sub wa, iz	; sub WA,IZ
	ld (0x0c78:16), wa	; ld (0x0c78),WA
	cpw (0x0c78:16), 0	; cp (0x0c78),0x0000
	jr z, FDC_CmdReadSectors__check_remaining	; jr Z,0xffe49f
	lda xbc, (0x0c7a:16)	; lda XBC,0x0c7a
	ld wa, (0x0c4a:16)	; ld WA,(0x0c4a)
	extz xwa	; extz XWA
	add xwa, (xbc)	; add XWA,(XBC)
	ld (xbc), xwa	; ld (XBC),XWA
	ldw (0x0c76:16), 1	; ld (0x0c76),0x0001
	ld (0x0c5b:16), 1	; ld (0x0c5b),0x01
	ld a, (0x0c57:16)	; ld A,(0x0c57)
	xor a, 1	; xor A,0x01
	ld (0x0c57:16), a	; ld (0x0c57),A
	ld (0x0c5a:16), a	; ld (0x0c5a),A
	cp (0x0c5a:16), 0	; cp (0x0c5a),0x00
	jr nz, FDC_CmdReadSectors__check_remaining	; jr NZ,0xffe49f
	lda xwa, (0x0c59:16)	; lda XWA,0x0c59
	incm8 1, (xwa)	; inc 1,(XWA)
	ld a, (xwa)	; ld A,(XWA)
	ld (0x0c64:16), a	; ld (0x0c64),A
FDC_CmdReadSectors__check_remaining:
	cpw (0x0c78:16), 0	; cp (0x0c78),0x0000
	jrl nz, FDC_CmdReadSectors__retry	; jrl NZ,0xffe380
FDC_CmdReadSectors__done:
	popw iz	; pop IZ
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_CmdWriteSectors - command 4: multi-sector write with retries
; Mirror image of FDC_CmdReadSectors using MT|MF WRITE DATA (0xC5);
; write-protect (0x2F) aborts immediately; exhausted retries -> 0x20.
; Twin: maincpu FDC_SECTOR_XFER (fdc_routines.s dispatch entry 4)
; -----------------------------------------------------------------------------
FDC_CmdWriteSectors:
	pushw iz	; push IZ - cmd 4 entry
	ld (0x0c96:16), 8	; ld (0x0c96),0x08
	jrl FDC_CmdWriteSectors__check_remaining	; jrl T,0xffe5d8
FDC_CmdWriteSectors__retry:
	ld (0x0c52:16), 0	; ld (0x0c52),0x00
	calr FDC_CmdSeek	; calr 0xffe31a
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jr z, FDC_CmdWriteSectors__seek_ok	; jr Z,0xffe4d8
	ld a, (0x0c52:16)	; ld A,(0x0c52)
	ldfr_berp a, 0xf8	; ld IZL,A
	exts iz	; exts IZ
	calr FDC_MediaConfigAndRecalibrate	; calr 0xffd8a5
	ldto_berp a, 0xf8	; ld A,IZL
	ld (0x0c52:16), a	; ld (0x0c52),A
	jrl FDC_CmdWriteSectors__done	; jrl T,0xffe5e1
FDC_CmdWriteSectors__seek_ok:
	ld wa, (0x0c76:16)	; ld WA,(0x0c76)
	cp wa, (0x0d3a:16)	; cp WA,(0x0d3a)
	jr ule, FDC_CmdWriteSectors__save_position	; jr ULE,0xffe4e8
	ldw (0x0c76:16), 1	; ld (0x0c76),0x0001
FDC_CmdWriteSectors__save_position:
	ldmm16 (0x0d3e), (0x0c76)	; ldw (0x0d3e),(0x0c76)
	ldw (0x0c4a:16), 0	; ld (0x0c4a),0x0000
	cp (0x0c9a:16), 2	; cp (0x0c9a),0x02
	jr nz, FDC_CmdWriteSectors__sector_512	; jr NZ,0xffe503
	ldw (0x0c4c:16), 0x0400	; ld (0x0c4c),0x0400 - media format 2 uses 1024-byte sectors
	jr FDC_CmdWriteSectors__count_burst	; jr T,0xffe509
FDC_CmdWriteSectors__sector_512:
	ldw (0x0c4c:16), 0x0200	; ld (0x0c4c),0x0200
FDC_CmdWriteSectors__count_burst:
	ldmm16 (0x0d40), (0x0c78)	; ldw (0x0d40),(0x0c78)
	ld iz, 1:i3	; ld IZ,1
FDC_CmdWriteSectors__burst_loop:
	ld wa, (0x0c4c:16)	; ld WA,(0x0c4c)
	add (0x0c4a:16), wa	; add (0x0c4a),WA
	lda xwa, (0x0c78:16)	; lda XWA,0x0c78
	decm 1, (xwa)	; decw 1,(XWA)
	ld wa, (xwa)	; ld WA,(XWA)
	cp wa, 0:i3	; cp WA,0
	jr z, FDC_CmdWriteSectors__submit	; jr Z,0xffe537
	lda xwa, (0x0c76:16)	; lda XWA,0x0c76
	incw 1, (xwa)	; incw 1,(XWA)
	ld wa, (xwa)	; ld WA,(XWA)
	cp wa, (0x0d3a:16)	; cp WA,(0x0d3a)
	jr ugt, FDC_CmdWriteSectors__submit	; jr UGT,0xffe537
	inc 1, iz	; inc 1,IZ
	jr FDC_CmdWriteSectors__burst_loop	; jr T,0xffe511
FDC_CmdWriteSectors__submit:
	ld (0x0c78:16), iz	; ld (0x0c78),IZ
	ldmm16 (0x0c76), (0x0d3e)	; ldw (0x0c76),(0x0d3e)
	calr FDC_SubmitWriteDataCmd	; calr 0xffe5e3
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jr z, FDC_CmdWriteSectors__advance	; jr Z,0xffe58b
	cp (0x0c52:16), 9	; cp (0x0c52),0x09
	jr nz, FDC_CmdWriteSectors__check_wp	; jr NZ,0xffe55b
	calr FDC_Seek	; calr 0xffd894
	calr FDC_MediaConfigAndRecalibrate	; calr 0xffd8a5
	jrl FDC_CmdWriteSectors__done	; jrl T,0xffe5e1
FDC_CmdWriteSectors__check_wp:
	cp (0x0c52:16), 0x2f	; cp (0x0c52),0x2f - error 0x2F = write-protected: do not retry
	jr nz, FDC_CmdWriteSectors__recover	; jr NZ,0xffe567
	calr FDC_MediaConfigAndRecalibrate	; calr 0xffd8a5
	jr FDC_CmdWriteSectors__done	; jr T,0xffe5e1
FDC_CmdWriteSectors__recover:
	calr FDC_MediaConfigAndRecalibrate	; calr 0xffd8a5
	ld (0x0d32:16), 0xff	; ld (0x0d32),0xff
	calr FDC_CmdSeek	; calr 0xffe31a
	ldmm16 (0x0c78), (0x0d40)	; ldw (0x0c78),(0x0d40)
	dec 1, (0x0c96:16)	; dec 1,(0x0c96)
	ld a, (0x0c96:16)	; ld A,(0x0c96)
	cp a, 0:i3	; cp A,0
	jr nz, FDC_CmdWriteSectors__check_remaining	; jr NZ,0xffe5d8
	ld (0x0c52:16), 0x20	; ld (0x0c52),0x20 - error 0x20 = write retries exhausted
	jr FDC_CmdWriteSectors__done	; jr T,0xffe5e1
FDC_CmdWriteSectors__advance:
	ld wa, (0x0d40:16)	; ld WA,(0x0d40)
	sub wa, iz	; sub WA,IZ
	ld (0x0c78:16), wa	; ld (0x0c78),WA
	cpw (0x0c78:16), 0	; cp (0x0c78),0x0000
	jr z, FDC_CmdWriteSectors__check_remaining	; jr Z,0xffe5d8
	lda xbc, (0x0c7a:16)	; lda XBC,0x0c7a
	ld wa, (0x0c4a:16)	; ld WA,(0x0c4a)
	extz xwa	; extz XWA
	add xwa, (xbc)	; add XWA,(XBC)
	ld (xbc), xwa	; ld (XBC),XWA
	ldw (0x0c76:16), 1	; ld (0x0c76),0x0001
	ld (0x0c5b:16), 1	; ld (0x0c5b),0x01
	ld a, (0x0c57:16)	; ld A,(0x0c57)
	xor a, 1	; xor A,0x01
	ld (0x0c57:16), a	; ld (0x0c57),A
	ld (0x0c5a:16), a	; ld (0x0c5a),A
	cp (0x0c5a:16), 0	; cp (0x0c5a),0x00
	jr nz, FDC_CmdWriteSectors__check_remaining	; jr NZ,0xffe5d8
	lda xwa, (0x0c59:16)	; lda XWA,0x0c59
	incm8 1, (xwa)	; inc 1,(XWA)
	ld a, (xwa)	; ld A,(XWA)
	ld (0x0c64:16), a	; ld (0x0c64),A
FDC_CmdWriteSectors__check_remaining:
	cpw (0x0c78:16), 0	; cp (0x0c78),0x0000
	jrl nz, FDC_CmdWriteSectors__retry	; jrl NZ,0xffe4b3
FDC_CmdWriteSectors__done:
	popw iz	; pop IZ
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_SubmitWriteDataCmd - arm DMA and issue MT|MF WRITE DATA (0xC5)
; -----------------------------------------------------------------------------
FDC_SubmitWriteDataCmd:
	ld (0x0c56:16), 0xc5	; ld (0x0c56),0xc5 - 0xC5 = MT|MF WRITE DATA
	calr FDC_SetupDMAMode	; calr 0xffdd2c
	calr FDC_ClearResultBuf	; calr 0xffe260
	ldw wa, 0xc5	; ld WA,0x00c5
	calr FDC_IssueCommand	; calr 0xffdfc3
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	ret nz	; ret NZ
	jrl FDC_WaitResult	; jrl T,0xffe266

; -----------------------------------------------------------------------------
; FDC_CmdFormat - command 5: format the whole disk
; Sense-drive-status + recalibrate first, then per media format id fixes
; N and the format gap (9spt gap 0x50 / 18spt gap 0x6C / 8x1024 gap 0x74,
; fill byte 0xE5), and formats track by track, alternating heads, until
; the track count is reached.  Any error re-runs the media configuration
; and recalibrates.
; Twin: maincpu FDC_MODE_CONFIG (fdc_routines.s:1809)
; -----------------------------------------------------------------------------
FDC_CmdFormat:
	calr FDC_FormatPrepareStub	; calr 0xffe230 - cmd 5 entry
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jrl nz, FDC_CmdFormat__finish	; jrl NZ,0xffe6b6
	calr FDC_CmdSenseDriveStatus	; calr 0xffe8f6
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jrl nz, FDC_CmdFormat__finish	; jrl NZ,0xffe6b6
	calr FDC_CmdRecalibrate	; calr 0xffe2d6
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jrl nz, FDC_CmdFormat__finish	; jrl NZ,0xffe6b6
	ld a, (0x0c9a:16)	; ld A,(0x0c9a)
	cp a, 2:i3	; cp A,2
	jr z, FDC_CmdFormat__gap_8spt_1024	; jr Z,0xffe64f
	cp a, 3:i3	; cp A,3
	jr z, FDC_CmdFormat__gap_18spt	; jr Z,0xffe643
	cp a, 5:i3	; cp A,5
	jr z, FDC_CmdFormat__gap_9spt	; jr Z,0xffe637
	cp a, 4:i3	; cp A,4
	jr z, FDC_CmdFormat__gap_9spt	; jr Z,0xffe637
	cp a, 0:i3	; cp A,0
	jr nz, FDC_CmdFormat__start	; jr NZ,0xffe659
FDC_CmdFormat__gap_9spt:
	ld (0x0c5c:16), 2	; ld (0x0c5c),0x02
	ld (0x0c61:16), 0x50	; ld (0x0c61),0x50
	jr FDC_CmdFormat__start	; jr T,0xffe659
FDC_CmdFormat__gap_18spt:
	ld (0x0c5c:16), 2	; ld (0x0c5c),0x02
	ld (0x0c61:16), 0x6c	; ld (0x0c61),0x6c
	jr FDC_CmdFormat__start	; jr T,0xffe659
FDC_CmdFormat__gap_8spt_1024:
	ld (0x0c5c:16), 3	; ld (0x0c5c),0x03
	ld (0x0c61:16), 0x74	; ld (0x0c61),0x74
FDC_CmdFormat__start:
	ld (0x0c64:16), 0	; ld (0x0c64),0x00
	ld (0x0c59:16), 0	; ld (0x0c59),0x00
	ld (0x0c62:16), 0xe5	; ld (0x0c62),0xe5
	ld (0x0c5a:16), 0	; ld (0x0c5a),0x00
	ld (0x0c57:16), 0	; ld (0x0c57),0x00
	jr FDC_CmdFormat__check_more_tracks	; jr T,0xffe6aa
FDC_CmdFormat__track_loop:
	ldmm8 (0x0c40), (0x0c64)	; ld (0x0c40),(0x0c64) - publish the track being formatted for the progress display
	calr FDC_FormatOneTrack	; calr 0xffe6c9
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jr nz, FDC_CmdFormat__finish	; jr NZ,0xffe6b6
	ld a, (0x0c57:16)	; ld A,(0x0c57)
	xor a, 1	; xor A,0x01
	ld (0x0c57:16), a	; ld (0x0c57),A
	ld (0x0c5a:16), a	; ld (0x0c5a),A
	cp (0x0c5a:16), 0	; cp (0x0c5a),0x00
	jr nz, FDC_CmdFormat__check_more_tracks	; jr NZ,0xffe6aa
	lda xwa, (0x0c59:16)	; lda XWA,0x0c59
	incm8 1, (xwa)	; inc 1,(XWA)
	ld a, (xwa)	; ld A,(XWA)
	ld (0x0c64:16), a	; ld (0x0c64),A
	ld (0x0c40:16), a	; ld (0x0c40),A
FDC_CmdFormat__check_more_tracks:
	ld a, (0x0c64:16)	; ld A,(0x0c64)
	extz wa	; extz WA
	cp wa, (0x0d36:16)	; cp WA,(0x0d36)
	jr ule, FDC_CmdFormat__track_loop	; jr ULE,0xffe674
FDC_CmdFormat__finish:
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	call nz, (FDC_MediaConfigAndRecalibrate + 0x600000:24)	; call NZ,0xffd8a5 - on error, re-run the media configuration (F2-form CALL cannot take a label; 0xFFD8A5 = FDC_MediaConfigAndRecalibrate)
	calr FDC_CmdRecalibrate	; calr 0xffe2d6
	ld (0x0d32:16), 0xff	; ld (0x0d32),0xff
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_FormatOneTrack - seek + FORMAT TRACK (0x4D) for the current track
; Builds the ID-field buffer, points DMA3 at it (the FDC *reads* the
; C,H,R,N fields during format) and submits the command.
; -----------------------------------------------------------------------------
FDC_FormatOneTrack:
	calr FDC_CmdSeek	; calr 0xffe31a
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jrl nz, FDC_MediaConfigAndRecalibrate	; jrl NZ,0xffd8a5
	calr FDC_BuildFormatFieldBuffer	; calr 0xffe6ed
	ld (0x0c56:16), 0x4d	; ld (0x0c56),0x4d - 0x4D = MF FORMAT TRACK
	lda xwa, (0x0c9e:16)	; lda XWA,0x0c9e
	ld (0x0c7a:16), xwa	; ld (0x0c7a),XWA
	calr FDC_SetupDMAMode	; calr 0xffdd2c
	calr FDC_ReloadDMACount	; calr 0xffdd9b
	jrl FDC_SubmitFormatTrackCmd	; jrl T,0xffe880

; -----------------------------------------------------------------------------
; FDC_BuildFormatFieldBuffer - fill 0x0C9E.. with C,H,R,N per sector
; Two ID fields per loop iteration; the second half of the sectors gets
; R = SC/2 + index when the request's field +6 is nonzero (2:1 interleave
; layout), plus an odd-count tail.  Counts bytes into 0x0C4A for DMA.
; -----------------------------------------------------------------------------
FDC_BuildFormatFieldBuffer:
	ld (0x0c5b:16), 1	; ld (0x0c5b),0x01
	ldw (0x0c4a:16), 0	; ld (0x0c4a),0x0000
	ld ix, (0x0d38:16)	; ld IX,(0x0d38)
	srl ix, 1	; srl 0x01,IX
	ld e, 0:opc	; ld E,0x00
	ld iy, 0:i3	; ld IY,0
	cp iy, ix	; cp IY,IX
	jrl nc, FDC_BuildFormatFieldBuffer__odd_tail	; jrl NC,0xffe80e
FDC_BuildFormatFieldBuffer__pair_loop:
	ld a, e	; ld A,E
	inc 1, e	; inc 1,E
	extz wa	; extz WA
	lda xbc, (0x0c9e:16)	; lda XBC,0x0c9e
	ld hl, wa	; ld HL,WA
	extz xhl	; extz XHL
	add xhl, xbc	; add XHL,XBC
	ld a, (0x0c59:16)	; ld A,(0x0c59)
	ld (xhl), a	; ld (XHL),A
	incw 1, (0x0c4a:16)	; incw 1,(0x0c4a)
	ld a, e	; ld A,E
	inc 1, e	; inc 1,E
	extz wa	; extz WA
	lda xbc, (0x0c9e:16)	; lda XBC,0x0c9e
	ld hl, wa	; ld HL,WA
	extz xhl	; extz XHL
	add xhl, xbc	; add XHL,XBC
	ld a, (0x0c5a:16)	; ld A,(0x0c5a)
	ld (xhl), a	; ld (XHL),A
	incw 1, (0x0c4a:16)	; incw 1,(0x0c4a)
	ld a, e	; ld A,E
	inc 1, e	; inc 1,E
	extz wa	; extz WA
	lda xbc, (0x0c9e:16)	; lda XBC,0x0c9e
	ld hl, wa	; ld HL,WA
	extz xhl	; extz XHL
	add xhl, xbc	; add XHL,XBC
	ld a, (0x0c5b:16)	; ld A,(0x0c5b)
	ld (xhl), a	; ld (XHL),A
	incw 1, (0x0c4a:16)	; incw 1,(0x0c4a)
	ld a, e	; ld A,E
	inc 1, e	; inc 1,E
	extz wa	; extz WA
	lda xbc, (0x0c9e:16)	; lda XBC,0x0c9e
	ld hl, wa	; ld HL,WA
	extz xhl	; extz XHL
	add xhl, xbc	; add XHL,XBC
	ld a, (0x0c5c:16)	; ld A,(0x0c5c)
	ld (xhl), a	; ld (XHL),A
	incw 1, (0x0c4a:16)	; incw 1,(0x0c4a)
	ld a, e	; ld A,E
	inc 1, e	; inc 1,E
	extz wa	; extz WA
	lda xbc, (0x0c9e:16)	; lda XBC,0x0c9e
	ld hl, wa	; ld HL,WA
	extz xhl	; extz XHL
	add xhl, xbc	; add XHL,XBC
	ld a, (0x0c59:16)	; ld A,(0x0c59)
	ld (xhl), a	; ld (XHL),A
	incw 1, (0x0c4a:16)	; incw 1,(0x0c4a)
	ld a, e	; ld A,E
	inc 1, e	; inc 1,E
	extz wa	; extz WA
	lda xbc, (0x0c9e:16)	; lda XBC,0x0c9e
	ld hl, wa	; ld HL,WA
	extz xhl	; extz XHL
	add xhl, xbc	; add XHL,XBC
	ld a, (0x0c5a:16)	; ld A,(0x0c5a)
	ld (xhl), a	; ld (XHL),A
	incw 1, (0x0c4a:16)	; incw 1,(0x0c4a)
	cpw (0x0c74:16), 0	; cp (0x0c74),0x0000
	jr nz, FDC_BuildFormatFieldBuffer__offset_numbering	; jr NZ,0xffe7c8
	inc 1, (0x0c5b:16)	; inc 1,(0x0c5b)
	ld a, e	; ld A,E
	inc 1, e	; inc 1,E
	extz wa	; extz WA
	lda xbc, (0x0c9e:16)	; lda XBC,0x0c9e
	ld hl, wa	; ld HL,WA
	extz xhl	; extz XHL
	add xhl, xbc	; add XHL,XBC
	ld a, (0x0c5b:16)	; ld A,(0x0c5b)
	ld (xhl), a	; ld (XHL),A
	jr FDC_BuildFormatFieldBuffer__next_pair	; jr T,0xffe7e5
FDC_BuildFormatFieldBuffer__offset_numbering:
	ld wa, (0x0d38:16)	; ld WA,(0x0d38)
	srl wa, 1	; srl 0x01,WA
	add a, (0x0c5b:16)	; add A,(0x0c5b)
	ld l, a	; ld L,A
	ld a, e	; ld A,E
	inc 1, e	; inc 1,E
	extz wa	; extz WA
	lda xbc, (0x0c9e:16)	; lda XBC,0x0c9e
	extz xwa	; extz XWA
	add xwa, xbc	; add XWA,XBC
	ld (xwa), l	; ld (XWA),L
FDC_BuildFormatFieldBuffer__next_pair:
	incw 1, (0x0c4a:16)	; incw 1,(0x0c4a)
	ld a, e	; ld A,E
	inc 1, e	; inc 1,E
	extz wa	; extz WA
	lda xbc, (0x0c9e:16)	; lda XBC,0x0c9e
	ld hl, wa	; ld HL,WA
	extz xhl	; extz XHL
	add xhl, xbc	; add XHL,XBC
	ld a, (0x0c5c:16)	; ld A,(0x0c5c)
	ld (xhl), a	; ld (XHL),A
	incw 1, (0x0c4a:16)	; incw 1,(0x0c4a)
	inc 1, (0x0c5b:16)	; inc 1,(0x0c5b)
	inc 1, iy	; inc 1,IY
	cp iy, ix	; cp IY,IX
	jrl c, FDC_BuildFormatFieldBuffer__pair_loop	; jrl C,0xffe708
FDC_BuildFormatFieldBuffer__odd_tail:
	ld wa, (0x0d38:16)	; ld WA,(0x0d38)
	bit 0, wa	; bit 0x00,WA
	ret z	; ret Z
	ld a, e	; ld A,E
	inc 1, e	; inc 1,E
	extz wa	; extz WA
	lda xbc, (0x0c9e:16)	; lda XBC,0x0c9e
	ld hl, wa	; ld HL,WA
	extz xhl	; extz XHL
	add xhl, xbc	; add XHL,XBC
	ld a, (0x0c59:16)	; ld A,(0x0c59)
	ld (xhl), a	; ld (XHL),A
	incw 1, (0x0c4a:16)	; incw 1,(0x0c4a)
	ld a, e	; ld A,E
	inc 1, e	; inc 1,E
	extz wa	; extz WA
	lda xbc, (0x0c9e:16)	; lda XBC,0x0c9e
	ld hl, wa	; ld HL,WA
	extz xhl	; extz XHL
	add xhl, xbc	; add XHL,XBC
	ld a, (0x0c5a:16)	; ld A,(0x0c5a)
	ld (xhl), a	; ld (XHL),A
	incw 1, (0x0c4a:16)	; incw 1,(0x0c4a)
	ld a, e	; ld A,E
	inc 1, e	; inc 1,E
	extz wa	; extz WA
	lda xbc, (0x0c9e:16)	; lda XBC,0x0c9e
	ld hl, wa	; ld HL,WA
	extz xhl	; extz XHL
	add xhl, xbc	; add XHL,XBC
	ld wa, (0x0d38:16)	; ld WA,(0x0d38)
	ld (xhl), a	; ld (XHL),A
	incw 1, (0x0c4a:16)	; incw 1,(0x0c4a)
	ld a, e	; ld A,E
	inc 1, e	; inc 1,E
	extz wa	; extz WA
	lda xbc, (0x0c9e:16)	; lda XBC,0x0c9e
	ld de, wa	; ld DE,WA
	extz xde	; extz XDE
	add xde, xbc	; add XDE,XBC
	ld a, (0x0c5c:16)	; ld A,(0x0c5c)
	ld (xde), a	; ld (XDE),A
	incw 1, (0x0c4a:16)	; incw 1,(0x0c4a)
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_SubmitFormatTrackCmd - arm DMA and issue MF FORMAT TRACK (0x4D)
; -----------------------------------------------------------------------------
FDC_SubmitFormatTrackCmd:
	ld (0x0c56:16), 0x4d	; ld (0x0c56),0x4d - cmd submit: 0x4D = MF FORMAT TRACK
	calr FDC_SetupDMAMode	; calr 0xffdd2c
	calr FDC_ClearResultBuf	; calr 0xffe260
	ldw wa, 0x4d	; ld WA,0x004d
	calr FDC_IssueCommand	; calr 0xffdfc3
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	ret nz	; ret NZ
	jrl FDC_WaitResult	; jrl T,0xffe266

; -----------------------------------------------------------------------------
; FDC_CmdMotorOn - command 6: motor on
; Raises Port A bit 3 and sends aux 0xFE (enable motors, all drive bits),
; then waits one 10-tick spin-up delay.  Failure -> error 0x31.
; Twin: maincpu FDC_CMD_ENABLE (fdc_routines.s dispatch entry 6)
; -----------------------------------------------------------------------------
FDC_CmdMotorOn:
	pushw iz	; push IZ - cmd 6 entry
	set_dd8 3, 0x28	; set 3,(0x28) - Port A bit 3 = drive motor/enable line
	ldw wa, 0xfe	; ld WA,0x00fe - aux 0xFE = enable motors, drive bits 4-7 set
	calr FDC_IssueCommand	; calr 0xffdfc3 - aux 0xFE = enable motors, drive bits 4-7 set
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jr z, FDC_CmdMotorOn__spinup	; jr Z,0xffe8b4
	ldw wa, 0x31	; ld WA,0x0031 - error 0x31 = drive not ready
	calr FDC_Error	; calr 0xffe231
	jr FDC_CmdMotorOn__done	; jr T,0xffe8c3
FDC_CmdMotorOn__spinup:
	ld iz, 1:i3	; ld IZ,1
	cp iz, 0:i3	; cp IZ,0
	jr z, FDC_CmdMotorOn__done	; jr Z,0xffe8c3
FDC_CmdMotorOn__spin_wait:
	ldw wa, 10	; ld WA,0x000a
	calr Boot_Delay	; calr 0xffe296
	djnz16 iz, -9	; djnz IZ,0xffe8ba
FDC_CmdMotorOn__done:
	popw iz	; pop IZ
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_CmdMotorOff - command 7: motor off
; Clears Port A bit 3 and sends aux 0x0E (enable motors, no drive bits).
; Twin: maincpu FDC_CMD_DISABLE (fdc_routines.s dispatch entry 7)
; -----------------------------------------------------------------------------
FDC_CmdMotorOff:
	res_dd8 3, 0x28	; res 3,(0x28) - cmd 7 entry; Port A bit 3 off
	ldw wa, 0x0e	; ld WA,0x000e - aux 0x0E = enable motors with all drive bits clear
	jrl FDC_IssueCommand	; jrl T,0xffdfc3

; -----------------------------------------------------------------------------
; FDC_CmdGetLastError - command 8: return the previous request's status
; Copies 0x0C54 back into 0x0C52 (FDC_Request returns it in HL).
; Twin: maincpu FDC_STATUS_COPY (fdc_routines.s:2096)
; -----------------------------------------------------------------------------
FDC_CmdGetLastError:
	ldmm8 (0x0c52), (0x0c54)	; ld (0x0c52),(0x0c54) - cmd 8 entry
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_CmdSetDiskChanged - command 9: set/clear the disk-changed flag
; Request field +4: 1 = set 0x0C98 to 0xFF, 0 = clear; else error 0xFE.
; Twin: maincpu FDC_OUTPUT_CTRL (fdc_routines.s dispatch entry 9)
; -----------------------------------------------------------------------------
FDC_CmdSetDiskChanged:
	ld wa, (0x0c72:16)	; ld WA,(0x0c72) - cmd 9 entry
	cp wa, 1:i3	; cp WA,1
	jr z, FDC_CmdSetDiskChanged__set	; jr Z,0xffe8ea
	cp wa, 0:i3	; cp WA,0
	jr nz, FDC_CmdSetDiskChanged__bad_flag	; jr NZ,0xffe8e3
	jr FDC_CmdSetDiskChanged__clear	; jr T,0xffe8f0
FDC_CmdSetDiskChanged__bad_flag:
	ldw wa, 0xfe	; ld WA,0x00fe
	calr FDC_Error	; calr 0xffe231
	ret	; ret
FDC_CmdSetDiskChanged__set:
	ld (0x0c98:16), 0xff	; ld (0x0c98),0xff
	ret	; ret
FDC_CmdSetDiskChanged__clear:
	ld (0x0c98:16), 0	; ld (0x0c98),0x00
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_CmdSenseDriveStatus - command 11: SENSE DRIVE STATUS (0x04)
; Reads ST3 and raises: bit 7 fault -> 0x32, bit 5 ready clear -> 0x31,
; bit 6 write-protect -> 0x2F.
; Twin: maincpu FDC_INTERRUPT_HANDLER (fdc_routines.s:2122)
; -----------------------------------------------------------------------------
FDC_CmdSenseDriveStatus:
	pushw_erp 0xfa	; push QIZ - cmd 11 entry
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jr nz, FDC_CmdSenseDriveStatus__done	; jr NZ,0xffe940
	ld wa, 4:i3	; ld WA,4 - 0x04 = SENSE DRIVE STATUS
	calr FDC_IssueCommand	; calr 0xffdfc3
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jr nz, FDC_CmdSenseDriveStatus__done	; jr NZ,0xffe940
	calr FDC_WaitRQM	; calr 0xffdda3
	cp (0x0c52:16), 0	; cp (0x0c52),0x00
	jr nz, FDC_CmdSenseDriveStatus__done	; jr NZ,0xffe940
	calr FDC_ReadData	; calr 0xffd7ee
	ldfr_berp l, 0xfb	; ld QIZH,L - QIZH = ST3
	bit_erpb 0xfb, 7	; bit 0x07,QIZH - ST3 bit 7 = fault
	jr z, FDC_CmdSenseDriveStatus__check_ready	; jr Z,0xffe928
	ldw wa, 0x32	; ld WA,0x0032 - error 0x32 = drive fault
	calr FDC_Error	; calr 0xffe231
FDC_CmdSenseDriveStatus__check_ready:
	bit_erpb 0xfb, 5	; bit 0x05,QIZH - ST3 bit 5 = ready
	jr nz, FDC_CmdSenseDriveStatus__check_wp	; jr NZ,0xffe934
	ldw wa, 0x31	; ld WA,0x0031 - error 0x31 = drive not ready
	calr FDC_Error	; calr 0xffe231
FDC_CmdSenseDriveStatus__check_wp:
	bit_erpb 0xfb, 6	; bit 0x06,QIZH - ST3 bit 6 = write protected
	jr z, FDC_CmdSenseDriveStatus__done	; jr Z,0xffe940
	ldw wa, 0x2f	; ld WA,0x002f - error 0x2F = write protected
	calr FDC_Error	; calr 0xffe231
FDC_CmdSenseDriveStatus__done:
	popw_erp 0xfa	; pop QIZ
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_Request - PUBLIC ENTRY: execute one floppy request
; Called with a pointer to a 14-byte request block at (XSP+8):
;   +0x00 u16 command (0-11)      +0x02 u16 drive
;   +0x04 u16 head / flag         +0x06 u16 track / media-type code
;   +0x08 u16 starting sector     +0x0A u16 sector count
;   +0x0C u32 buffer address
; Re-entrancy guard: busy latch 0x0C44 == 0xA5 -> error 0xFB (command 0
; may always preempt).  Copies the block to 0x0C6E.. and mirrors it at
; 0x0C7E.., rotates the status history, validates via FDC_ValidateRequest,
; then dispatches through FDC_CommandDispatch_Offsets (ROM 0x9FB4BA) into
; the twelve calr stubs below.  Returns HL = sign-extended sticky status.
; Callers: FDC_RESET/FDC_READSECTOR wrappers at ROM 0x9FBF2F/0x9FBFB1 and
;          five request builders in bootcode_utils (0xFFEB82..0xFFEC52)
; Twin:    maincpu FDC_CommandEntry (fdc_routines.s:2168)
; -----------------------------------------------------------------------------
FDC_Request:
	push xiz	; push XIZ
	ld xiz, (xsp+0x08)	; ld XIZ,(XSP+0x08)
	cpw (xiz), 0	; cp (XIZ),0x0000 - cmd 0 (initialize) may always preempt: clear the busy latch
	jr nz, FDC_Request__check_busy	; jr NZ,0xffe953
	ld (0x0c44:16), 0	; ld (0x0c44),0x00
FDC_Request__check_busy:
	ei 0x06	; ei 0x06
	cp (0x0c44:16), 0xa5	; cp (0x0c44),0xa5 - busy latch still 0xA5: request already executing
	jr nz, FDC_Request__start	; jr NZ,0xffe969
	ei 0x00	; ei 0x00
	ldw wa, 0xfb	; ld WA,0x00fb - error 0xFB = driver re-entered
	calr FDC_Error	; calr 0xffe231
	extz hl	; extz HL
	jrl FDC_Request__return	; jrl T,0xffea54
FDC_Request__start:
	ld (0x0c44:16), 0xa5	; ld (0x0c44),0xa5 - mark busy
	ei 0x00	; ei 0x00
	ld wa, (xiz)	; ld WA,(XIZ)
	ld (0x0c6e:16), wa	; ld (0x0c6e),WA
	ld wa, (xiz+0x02)	; ld WA,(XIZ+0x02)
	ld (0x0c70:16), wa	; ld (0x0c70),WA
	ld wa, (xiz+0x04)	; ld WA,(XIZ+0x04)
	ld (0x0c72:16), wa	; ld (0x0c72),WA
	ld wa, (xiz+0x06)	; ld WA,(XIZ+0x06)
	ld (0x0c74:16), wa	; ld (0x0c74),WA
	ld wa, (xiz+0x08)	; ld WA,(XIZ+0x08)
	ld (0x0c76:16), wa	; ld (0x0c76),WA
	ld wa, (xiz+0x0a)	; ld WA,(XIZ+0x0a)
	ld (0x0c78:16), wa	; ld (0x0c78),WA
	ld xwa, (xiz+0x0c)	; ld XWA,(XIZ+0x0c)
	ld (0x0c7a:16), xwa	; ld (0x0c7a),XWA
	ld wa, (xiz)	; ld WA,(XIZ)
	ld (0x0c7e:16), wa	; ld (0x0c7e),WA
	ld wa, (xiz+0x02)	; ld WA,(XIZ+0x02)
	ld (0x0c80:16), wa	; ld (0x0c80),WA
	ld wa, (xiz+0x04)	; ld WA,(XIZ+0x04)
	ld (0x0c82:16), wa	; ld (0x0c82),WA
	ld wa, (xiz+0x06)	; ld WA,(XIZ+0x06)
	ld (0x0c84:16), wa	; ld (0x0c84),WA
	ld wa, (xiz+0x08)	; ld WA,(XIZ+0x08)
	ld (0x0c86:16), wa	; ld (0x0c86),WA
	ld wa, (xiz+0x0a)	; ld WA,(XIZ+0x0a)
	ld (0x0c88:16), wa	; ld (0x0c88),WA
	ld xwa, (xiz+0x0c)	; ld XWA,(XIZ+0x0c)
	ld (0x0c8a:16), xwa	; ld (0x0c8a),XWA
	ld (0x0c4e:16), 0	; ld (0x0c4e),0x00
	ldmm8 (0x0c54), (0x0c52)	; ld (0x0c54),(0x0c52)
	ld (0x0c52:16), 0	; ld (0x0c52),0x00
	calr FDC_ValidateRequest	; calr 0xffda86
	cp l, 0:i3	; cp L,0
	jr nz, FDC_Request__finish	; jr NZ,0xffea49 - L != 0: validation rejected the request
	ld wa, (0x0c6e:16)	; ld WA,(0x0c6e)
	cp wa, 0x0b	; cp WA,0x000b - commands are 0..11
	jr ugt, FDC_Request__invalid_command	; jr UGT,0xffea43
	add wa, wa	; add WA,WA
	lda xix, (FDC_CommandDispatch_Offsets + 0x600000:24)	; lda XIX,0xffb4ba - XIX = FDC_CommandDispatch_Offsets (boot alias of ROM 0x9FB4BA)
	ldw_sri wa, 0x07, 0xf0, 0xe0	; ld WA,(XIX+WA) - fetch stub offset (entries are 5 bytes apart)
	lda xix, (FDC_Dispatch_Initialize + 0x600000:24)	; lda XIX,0xffea07 - XIX = FDC_Dispatch_Initialize (stub base)
	jp_ind 8, 0x07, 0xf0, 0xe0	; jp T,XIX+WA

; -----------------------------------------------------------------------------
; FDC_Dispatch_* - the twelve command execution stubs
; Uniform 5-byte stanzas 'calr handler; jr FDC_Request__finish' indexed by
; FDC_CommandDispatch_Offsets (ROM 0x9FB4BA).
; Twin: maincpu FDC_HANDLER_DISPATCH_BASE.. (fdc_routines.s:2270)
; -----------------------------------------------------------------------------
FDC_Dispatch_Initialize:
	calr FDC_CmdInitialize	; calr 0xffe2bd
	jr FDC_Request__finish	; jr T,0xffea49
FDC_Dispatch_Recalibrate:
	calr FDC_CmdRecalibrate	; calr 0xffe2d6
	jr FDC_Request__finish	; jr T,0xffea49
FDC_Dispatch_Seek:
	calr FDC_CmdSeek	; calr 0xffe31a
	jr FDC_Request__finish	; jr T,0xffea49
FDC_Dispatch_ReadSectors:
	calr FDC_CmdReadSectors	; calr 0xffe368
	jr FDC_Request__finish	; jr T,0xffea49
FDC_Dispatch_WriteSectors:
	calr FDC_CmdWriteSectors	; calr 0xffe4aa
	jr FDC_Request__finish	; jr T,0xffea49
FDC_Dispatch_Format:
	calr FDC_CmdFormat	; calr 0xffe5fe
	jr FDC_Request__finish	; jr T,0xffea49
FDC_Dispatch_MotorOn:
	calr FDC_CmdMotorOn	; calr 0xffe89b
	jr FDC_Request__finish	; jr T,0xffea49
FDC_Dispatch_MotorOff:
	calr FDC_CmdMotorOff	; calr 0xffe8c5
	jr FDC_Request__finish	; jr T,0xffea49
FDC_Dispatch_GetLastError:
	calr FDC_CmdGetLastError	; calr 0xffe8ce
	jr FDC_Request__finish	; jr T,0xffea49
FDC_Dispatch_SetDiskChanged:
	calr FDC_CmdSetDiskChanged	; calr 0xffe8d5
	jr FDC_Request__finish	; jr T,0xffea49
FDC_Dispatch_ControllerReset:
	calr FDC_CmdControllerReset	; calr 0xffda6a
	jr FDC_Request__finish	; jr T,0xffea49
FDC_Dispatch_SenseDriveStatus:
	calr FDC_CmdSenseDriveStatus	; calr 0xffe8f6
	jr FDC_Request__finish	; jr T,0xffea49
FDC_Request__invalid_command:
	ldw wa, 0xff	; ld WA,0x00ff - error 0xFF = no such command
	calr FDC_Error	; calr 0xffe231
FDC_Request__finish:
	ld (0x0c44:16), 0x5a	; ld (0x0c44),0x5a - release the busy latch
	ld l, (0x0c52:16)	; ld L,(0x0c52) - return the sticky status, sign-extended into HL
	exts hl	; exts HL
FDC_Request__return:
	pop xiz	; pop XIZ
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_PIO_ReadTransfer - non-DMA fallback: move ONE byte per call
; Read direction for command 3, write for command 4 (below); transfers a
; byte between the 0x120000 acknowledge port and the caller's buffer and
; decrements the remaining count (0x0C4A); at zero pulses TC and refreshes
; the display.  Called from the INT4 path when DMA is not armed.
; Twin: maincpu FDC_ByteTransfer_PIO (fdc_routines.s:2345)
; -----------------------------------------------------------------------------
FDC_PIO_ReadTransfer:
	cpw (0x0c4a:16), 0	; cp (0x0c4a),0x0000
	ret z	; ret Z
	ld wa, (0x0c6e:16)	; ld WA,(0x0c6e) - cmd 4 = write, cmd 3 = read; anything else has no PIO path
	cp wa, 4:i3	; cp WA,4
	jr z, FDC_PIO_WriteTransfer	; jr Z,0xffea8a
	cp wa, 3:i3	; cp WA,3
	ret nz	; ret NZ
	ld c, (0x120000:24)	; ld C,(0x120000) - read one byte from the FDC DMA-acknowledge port
	ld xhl, (0x0c7c:16)	; ld XHL,(0x0c7c) - NOTE: pointer kept at 0x0C7C = +2 into the 32-bit buffer field at 0x0C7A; the maincpu twin has the same +2 quirk (0x8A4E vs buffer at 0x8A4C) -- apparent shared latent defect; the DMA path is what ships
	ld (xhl), c	; ld (XHL),C
	inc 1, xhl	; inc 1,XHL
	ld (0x0c7c:16), xhl	; ld (0x0c7c),XHL
FDC_PIO_CountAndFinish:
	subw (0x0c4a:16), 1	; sub (0x0c4a),0x0001
	ret nz	; ret NZ
	calr FDC_PulseTC	; calr 0xffdd17 - transfer complete: pulse TC and refresh the display
	calr Boot_UpdateDisplay	; calr 0xffdd26
	ret	; ret

; -----------------------------------------------------------------------------
; FDC_PIO_WriteTransfer - PIO write direction (see FDC_PIO_ReadTransfer)
; -----------------------------------------------------------------------------
FDC_PIO_WriteTransfer:
	ld xhl, (0x0c7c:16)	; ld XHL,(0x0c7c)
	ld c, (xhl)	; ld C,(XHL)
	ld (0x120000:24), c	; ld (0x120000),C - write one byte to the FDC DMA-acknowledge port
	inc 1, xhl	; inc 1,XHL
	ld (0x0c7c:16), xhl	; ld (0x0c7c),XHL
	jr FDC_PIO_CountAndFinish	; jr T,0xffea7b
