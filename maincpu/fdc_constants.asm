; =============================================================================
; fdc_constants.asm - Floppy Disk Controller Constants
; =============================================================================
; This file contains all FDC-related constants and memory-mapped I/O addresses
; for the KN5000's floppy disk controller subsystem.
;
; The KN5000 uses a standard PC-compatible FDC (likely uPD765 or equivalent)
; memory-mapped at 0x110000.
; =============================================================================

; =============================================================================
; FDC Memory-Mapped I/O Addresses
; =============================================================================
; The FDC is memory-mapped starting at 0x110000

FDC_MAP__BASE_ADDR		EQU 110000h	; FDC base address
FDC__DMA_ACKNOWLEDGE		EQU 120000h	; DMA acknowledge address

; FDC register offsets from FDC_MAP__BASE_ADDR:
;   +0x00: Main Status Register (read)
;   +0x08: Status Register A (read)
;   +0x0A: Data Register (read/write)

; =============================================================================
; FDC State Variables (in RAM)
; =============================================================================
; These are RAM addresses used by the FDC routines to track state

; FDC_STATE_VARS_BASE	EQU 8A00h	; Base of FDC state variables
; See fdc_routines.asm for detailed variable layout

; =============================================================================
; FDC Command Codes
; =============================================================================
; Standard uPD765/i8272 FDC command codes

FDC_CMD_READ_DATA		EQU 006h	; Read data from disk
FDC_CMD_READ_DELETED		EQU 00Ch	; Read deleted data
FDC_CMD_WRITE_DATA		EQU 005h	; Write data to disk
FDC_CMD_WRITE_DELETED		EQU 009h	; Write deleted data
FDC_CMD_READ_TRACK		EQU 002h	; Read entire track
FDC_CMD_READ_ID			EQU 00Ah	; Read sector ID
FDC_CMD_FORMAT_TRACK		EQU 00Dh	; Format track
FDC_CMD_SCAN_EQUAL		EQU 011h	; Scan equal
FDC_CMD_SCAN_LOW_EQUAL		EQU 019h	; Scan low or equal
FDC_CMD_SCAN_HIGH_EQUAL		EQU 01Dh	; Scan high or equal
FDC_CMD_RECALIBRATE		EQU 007h	; Recalibrate (seek track 0)
FDC_CMD_SENSE_INT		EQU 008h	; Sense interrupt status
FDC_CMD_SPECIFY			EQU 003h	; Specify step/head timings
FDC_CMD_SENSE_DRIVE		EQU 004h	; Sense drive status
FDC_CMD_SEEK			EQU 00Fh	; Seek to track

; =============================================================================
; FDC Status Register Bits
; =============================================================================

; Main Status Register (MSR) bits
FDC_MSR_RQM			EQU 080h	; Request for Master (data ready)
FDC_MSR_DIO			EQU 040h	; Data Input/Output direction
FDC_MSR_NON_DMA			EQU 020h	; Non-DMA mode
FDC_MSR_CMD_BUSY		EQU 010h	; FDC busy
FDC_MSR_DRV3_BUSY		EQU 008h	; Drive 3 seeking
FDC_MSR_DRV2_BUSY		EQU 004h	; Drive 2 seeking
FDC_MSR_DRV1_BUSY		EQU 002h	; Drive 1 seeking
FDC_MSR_DRV0_BUSY		EQU 001h	; Drive 0 seeking

; Status Register 0 (ST0) bits
FDC_ST0_INT_CODE		EQU 0C0h	; Interrupt code (bits 7-6)
FDC_ST0_SEEK_END		EQU 020h	; Seek end
FDC_ST0_EQUIP_CHECK		EQU 010h	; Equipment check
FDC_ST0_NOT_READY		EQU 008h	; Not ready
FDC_ST0_HEAD_ADDR		EQU 004h	; Head address
FDC_ST0_UNIT_SELECT		EQU 003h	; Unit select (bits 1-0)

; End of FDC constants
