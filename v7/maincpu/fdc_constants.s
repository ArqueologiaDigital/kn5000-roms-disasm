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

.equ FDC_MAP__BASE_ADDR, 0x110000	; FDC base address
.equ FDC__DMA_ACKNOWLEDGE, 0x120000	; DMA acknowledge address

; FDC register offsets from FDC_MAP__BASE_ADDR:
;   +0x00: Main Status Register (read)
;   +0x08: Status Register A (read)
;   +0x0a: Data Register (read/write)

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

.equ FDC_CMD_READ_DATA, 0x6	; Read data from disk
.equ FDC_CMD_READ_DELETED, 0xc	; Read deleted data
.equ FDC_CMD_WRITE_DATA, 0x5	; Write data to disk
.equ FDC_CMD_WRITE_DELETED, 0x9	; Write deleted data
.equ FDC_CMD_READ_TRACK, 0x2	; Read entire track
.equ FDC_CMD_READ_ID, 0xa	; Read sector ID
.equ FDC_CMD_FORMAT_TRACK, 0xd	; Format track
.equ FDC_CMD_SCAN_EQUAL, 0x11	; Scan equal
.equ FDC_CMD_SCAN_LOW_EQUAL, 0x19	; Scan low or equal
.equ FDC_CMD_SCAN_HIGH_EQUAL, 0x1d	; Scan high or equal
.equ FDC_CMD_RECALIBRATE, 0x7	; Recalibrate (seek track 0)
.equ FDC_CMD_SENSE_INT, 0x8	; Sense interrupt status
.equ FDC_CMD_SPECIFY, 0x3	; Specify step/head timings
.equ FDC_CMD_SENSE_DRIVE, 0x4	; Sense drive status
.equ FDC_CMD_SEEK, 0xf	; Seek to track

; =============================================================================
; FDC Status Register Bits
; =============================================================================

; Main Status Register (MSR) bits
.equ FDC_MSR_RQM, 0x80	; Request for Master (data ready)
.equ FDC_MSR_DIO, 0x40	; Data Input/Output direction
.equ FDC_MSR_NON_DMA, 0x20	; Non-DMA mode
.equ FDC_MSR_CMD_BUSY, 0x10	; FDC busy
.equ FDC_MSR_DRV3_BUSY, 0x8	; Drive 3 seeking
.equ FDC_MSR_DRV2_BUSY, 0x4	; Drive 2 seeking
.equ FDC_MSR_DRV1_BUSY, 0x2	; Drive 1 seeking
.equ FDC_MSR_DRV0_BUSY, 0x1	; Drive 0 seeking

; Status Register 0 (ST0) bits
.equ FDC_ST0_INT_CODE, 0xc0	; Interrupt code (bits 7-6)
.equ FDC_ST0_SEEK_END, 0x20	; Seek end
.equ FDC_ST0_EQUIP_CHECK, 0x10	; Equipment check
.equ FDC_ST0_NOT_READY, 0x8	; Not ready
.equ FDC_ST0_HEAD_ADDR, 0x4	; Head address
.equ FDC_ST0_UNIT_SELECT, 0x3	; Unit select (bits 1-0)

; End of FDC constants
