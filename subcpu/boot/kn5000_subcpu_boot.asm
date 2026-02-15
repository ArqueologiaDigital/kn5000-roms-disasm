; KN5000 Sub CPU Boot ROM Disassembly
; Original ROM: kn5000_subcpu_boot.ic30 (128KB)
; Target CPU: TMP94C241F (TLCS-900/H2)
;
; This is the boot ROM for the sub CPU (tone generator controller).
; It initializes hardware, copies interrupt vector trampolines to RAM,
; and enters a main loop that calls the payload at 0x0400.
;
; Memory Map:
;   0x0000-0x00FF  - Special Function Registers (SFR)
;   0x0100-0x01FF  - Extended SFR / Memory Controller
;   0x0400-0x04E0  - Interrupt vector trampolines (copied from ROM at boot)
;   0x0500+        - RAM / Payload data area
;   0x120000       - Inter-CPU Communication Latches (shared with main CPU)
;   0x130000       - Tone generator registers
;   0xFE0000-0xFFFFFF - This boot ROM (128KB, but mostly 0xFF)
;
; Boot sequence:
;   1. Reset vector at 0xFFFEE0 jumps to 0xFF8290
;   2. Initialize SFR registers (ports, timers, DMA, etc.)
;   3. Copy interrupt trampolines from ROM (0xFF8F6C) to RAM (0x0400)
;   4. Enable interrupts
;   5. Call initialization routines
;   6. Enter main loop, waiting for payload ready flag
;   7. Call payload entry point at 0x0400
;
; Actual code starts at 0xFF8000 (file offset 0x18000)

	cpu	96c141		; Actual CPU is TMP94C241F
	page	0
	maxmode	on
	include	"../../tmp94c241.inc"

; ==============================================================================
; Constants
; ==============================================================================

PAYLOAD_ENTRY		EQU	0400h	; Entry point of loaded payload
PAYLOAD_LOADED_FLAG	EQU	04FEh	; Bit 6: payload ready, Bit 7: transfer complete
DMA_SETUP_PARAMS	EQU	0502h	; DMA setup block: src(4), dst(4), count(2)
E1_XFER_PARAMS		EQU	050Ch	; E1 command params: dest_addr(4), count(2)
DMA_XFER_STATE		EQU	0516h	; DMA state machine: 0=idle, 1=single, 2=two-phase
E2_XFER_PARAMS		EQU	053Eh	; E2 command params: src_addr(4), count(2)
STACK_INIT		EQU	05A2h	; Initial stack pointer
DMA_BURST_CTRL		EQU	0102h	; DMA burst/trigger control register
AUDIO_HW_BASE		EQU	100000h	; Audio hardware registers (DSP/DAC?)
INTER_CPU_LATCH		EQU	120000h	; Inter-CPU communication latch
TONE_GEN_BASE		EQU	130000h	; Tone generator base address

; ==============================================================================
; SFR addresses (directly addressable 0x00-0xFF)
; Based on TMP94C241 datasheet with some variations for this hardware config
; ==============================================================================

; Port Function Control Registers
P0FC			EQU	07h	; Port 0 Function Control
P1FC			EQU	0Bh	; Port 1 Function Control
P2FC			EQU	0Fh	; Port 2 Function Control
P7			EQU	1Ch	; Port 7 Data
P7CR			EQU	1Eh	; Port 7 Control
P7FC			EQU	1Fh	; Port 7 Function Control
P8			EQU	20h	; Port 8 Data (Chip Select/WAIT)
P8CR			EQU	22h	; Port 8 Control
P8FC			EQU	23h	; Port 8 Function Control
PA			EQU	28h	; Port A Data (DRAM signals)
PAFC			EQU	2Bh	; Port A Function Control
PB			EQU	2Ch	; Port B Data (DRAM signals)
PBFC			EQU	2Fh	; Port B Function Control

; Interrupt Control
INTTC01			EQU	30h	; Interrupt control (Timer 0/1)

; Inter-CPU Status Register (at 0x34, directly addressable)
; Used for handshaking between main CPU and sub CPU
; Bit 0: Sub CPU ready flag (set when ready, cleared when starting transfer)
; Bit 1: Used by interrupt handler to signal completion
; Bit 2: Checked in InterCPU_RX_Handler to gate command processing
; Bit 4: Main CPU ready flag (polled by sub CPU, set by main CPU)
INTERCPU_STATUS		EQU	34h

; Port 8 area (legacy names for compatibility)
SC0BUF			EQU	34h	; Alias for INTERCPU_STATUS
SC0CR			EQU	36h
SC0MOD			EQU	38h
SC1BUF			EQU	3Ah
SC1CR			EQU	3Ch
SC1MOD			EQU	3Eh

; Port 8 extended area
P8_DATA			EQU	40h	; Port 8 extended data
P8_FC_LO		EQU	44h	; Port 8 function control low
P8_FC_HI		EQU	46h	; Port 8 function control high
P8_FC_EXT		EQU	47h	; Port 8 function control extended

; Port E area (Timer/Interrupt signals)
PE_DATA			EQU	68h	; Port E Data
PE_CR			EQU	6Ah	; Port E Control

; 8-Bit Timer Registers (0x80-0x8F)
T01MOD			EQU	80h	; Timer 0/1 Mode (NOT watchdog - that's at 110h)
				; Bit 0: PRRUN (Prescaler run)
				; Bit 1-2: T0CLK (Timer 0 clock source)
				; Bit 3-4: T01M (Timer 0/1 mode)
				; Bit 5: PWM0
				; Bit 6-7: T1CLK (Timer 1 clock source)
T01FFCR			EQU	81h	; Timer 0/1 Flip-Flop Control
T8RUN			EQU	82h	; 8-bit Timer Run Control (T0RUN, T1RUN, T2RUN, T3RUN)
TRDC			EQU	83h	; Timer Register Double-buffer Control
TREG0			EQU	84h	; Timer 0 Register (write-only)
TREG1			EQU	85h	; Timer 1 Register (write-only)
T23MOD			EQU	88h	; Timer 2/3 Mode
T23FFCR			EQU	89h	; Timer 2/3 Flip-Flop Control
TREG2			EQU	8Ah	; Timer 2 Register (write-only)
TREG3			EQU	8Bh	; Timer 3 Register (write-only)

; Legacy aliases for backward compatibility with existing code
WDMOD			EQU	80h	; Legacy alias - actually T01MOD, not watchdog!
WDCR			EQU	81h	; Legacy alias - actually T01FFCR
REG_40			EQU	40h	; = P8_DATA
REG_44			EQU	44h	; = P8_FC_LO
REG_46			EQU	46h	; = P8_FC_HI
REG_47			EQU	47h	; = P8_FC_EXT
REG_68			EQU	68h	; = PE_DATA
REG_6A			EQU	6Ah	; = PE_CR

; 16-Bit Timer 4 Registers (0x98-0x9F)
T4MOD			EQU	98h	; Timer 4 Mode
T4FFCR			EQU	99h	; Timer 4 Flip-Flop Control
CAP4L			EQU	9Eh	; Timer 4 Capture Low
CAP4H			EQU	9Fh	; Timer 4 Capture High

; Serial Channel 0 Registers (0xD0-0xD3)
SER0_BUF		EQU	0D0h	; Serial 0 Buffer (TX/RX)
SER0_CR			EQU	0D1h	; Serial 0 Control
SER0_MOD		EQU	0D2h	; Serial 0 Mode
SER0_BAUD		EQU	0D3h	; Serial 0 Baud Rate Control

; Serial Channel 1 Registers (0xD4-0xD7)
SER1_BUF		EQU	0D4h	; Serial 1 Buffer (TX/RX)
SER1_CR			EQU	0D5h	; Serial 1 Control
SER1_MOD		EQU	0D6h	; Serial 1 Mode
SER1_BAUD		EQU	0D7h	; Serial 1 Baud Rate Control

; (Legacy aliases removed - now using primary names SER0_CR, SER0_MOD, etc.)

; Port F area (Serial I/O pins)
PF_FC			EQU	0E5h	; Port F Function Control

; Other Port Function Controls
PORT_FC_1		EQU	0ECh	; Port function control
PORT_FC_2		EQU	0EDh	; Port function control
PORT_FC_3		EQU	0F0h	; Port function control
PORT_FC_4		EQU	0F6h	; Port function control

; ==============================================================================
; Extended SFR (0x0100+)
; ==============================================================================

; DMA/Interrupt Controller Area (0x100-0x10F)
DMA_VECTOR		EQU	0102h	; DMA interrupt vector/control

; Interrupt Controller (0x10A area)
INT_CTRL		EQU	010Ah	; Interrupt controller

; Watchdog Timer (0x110-0x111) - The REAL watchdog registers!
WDMOD_REAL		EQU	0110h	; Watchdog Mode Register
				; Bit 0-1: WDTP (Detection time)
				; Bit 4-5: HALTM (HALT mode)
				; Bit 6: DRVE (Drive enable in STOP)
				; Bit 7: WDTE (Watchdog enable)
WDCR_REAL		EQU	0111h	; Watchdog Control (write 4Eh to clear)

; Memory Controller - Block 0 (0x140-0x143)
B0CSL			EQU	0140h	; Block 0 Control Low (wait states)
B0CSH			EQU	0141h	; Block 0 Control High (bus width, mode)
MAMR0			EQU	0142h	; Block 0 Address Mask
MSAR0			EQU	0143h	; Block 0 Start Address

; Memory Controller - Block 1 (0x144-0x147)
B1CSL			EQU	0144h	; Block 1 Control Low
B1CSH			EQU	0145h	; Block 1 Control High
MAMR1			EQU	0146h	; Block 1 Address Mask
MSAR1			EQU	0147h	; Block 1 Start Address

; Memory Controller - Block 2 (0x148-0x14B)
B2CSL			EQU	0148h	; Block 2 Control Low
B2CSH			EQU	0149h	; Block 2 Control High
MAMR2			EQU	014Ah	; Block 2 Address Mask
MSAR2			EQU	014Bh	; Block 2 Start Address

; Memory Controller - Block 3 (0x14C-0x14F)
B3CSL			EQU	014Ch	; Block 3 Control Low
B3CSH			EQU	014Dh	; Block 3 Control High
MAMR3			EQU	014Eh	; Block 3 Address Mask
MSAR3			EQU	014Fh	; Block 3 Start Address

; Memory Controller - Block 4 (0x150-0x153)
B4CSL			EQU	0150h	; Block 4 Control Low
B4CSH			EQU	0151h	; Block 4 Control High
MAMR4			EQU	0152h	; Block 4 Address Mask
MSAR4			EQU	0153h	; Block 4 Start Address

; Memory Controller - Block 5 (0x154-0x157)
B5CSL			EQU	0154h	; Block 5 Control Low
B5CSH			EQU	0155h	; Block 5 Control High
MAMR5			EQU	0156h	; Block 5 Address Mask
MSAR5			EQU	0157h	; Block 5 Start Address

; DRAM Controller (0x160-0x167)
DRAM_REFRESH		EQU	0162h	; DRAM Refresh Control
DRAM_CTRL		EQU	0163h	; DRAM Controller Mode
DRAM_TIMING1		EQU	0165h	; DRAM Timing 1
DRAM_TIMING2		EQU	0166h	; DRAM Timing 2

; RAM variables - Communication and State
SUBCPU_STATUS_FLAGS	EQU	04FEh	; Status flags (bit 6=payload ready, bit 7=xfer complete)
DMA_TARGET_ADDR		EQU	0512h	; Current DMA destination address (4 bytes)
; Note: DMA_XFER_STATE was here but is same address as DMA_XFER_STATE (0x0516)
CMD_PROCESSING_STATE	EQU	0518h	; Command processing state (0-4)
LAST_CMD_BYTE		EQU	051Ah	; Last received command byte from main CPU

; RAM variables - Data Buffers
CMD_DATA_BUFFER		EQU	051Eh	; Variable-length command data (32 bytes max)
CMD_E1_BUFFER		EQU	0544h	; E1 command data buffer (6 bytes)
CMD_E2_BUFFER		EQU	054Ah	; E2 command data buffer (10 bytes)

; RAM variables - Diagnostics
MEMTEST_RESULT		EQU	0556h	; Memory test result flags
SERIAL_STATUS		EQU	0558h	; Serial status bytes (8 bytes)

; ==============================================================================
; ROM starts with 96KB of 0xFF (erased flash)
; Actual data begins at 0xFF8000 (file offset 0x18000)
; ==============================================================================

	org	0FE0000h

	; Fill first 96KB with 0xFF
	rept	98304
	db	0FFh
	endm

; ==============================================================================
; Data Tables (0xFF8000 - 0xFF828F)
; These appear to be lookup tables (possibly for audio/DSP)
; ==============================================================================

	org	0FF8000h

DATA_TABLE_8000:
	; TODO: Analyze and document these data tables
	; For now, include as binary
	binclude	"subcpu_boot_data_8000.bin"

; ==============================================================================
; Boot Entry Point (0xFF8290)
; Jumped to from reset handler at 0xFFFEE0
; ==============================================================================

	org	0FF8290h

BOOT_INIT:
	; Initialize memory controller registers
	ld	(WDMOD_REAL), 00h
	ld	(WDCR_REAL), 0B1h
	ld	(INT_CTRL), 04h

	; Initialize port function control registers (set all pins to function mode)
	ld	(P0FC), 0FFh		; Port 0 all function
	ld	(P1FC), 0FFh		; Port 1 all function
	ld	(P2FC), 0FFh		; Port 2 all function
	ld	(P7), 0FFh		; Port 7 data
	ld	(P7FC), 07h		; Port 7 function
	ld	(P7CR), 78h		; Port 7 control
	ld	(P8), 3Bh		; Port 8 data
	ld	(P8FC), 3Fh		; Port 8 function
	ld	(P8CR), 0FFh		; Port 8 control
	ld	(PA), 0FFh		; Port A data
	ld	(PAFC), 08h		; Port A function
	ld	(PB), 0FFh		; Port B data
	ld	(PBFC), 1Fh		; Port B function

	; Initialize interrupt control
	ld	(INTTC01), 03h
	ld	(33h), 00h
	ld	(32h), 02h
	ld	(SC0BUF), 0FFh
	ld	(37h), 00h
	ld	(SC0CR), 63h
	ld	(SC0MOD), 0FEh
	ld	(3Bh), 00h
	ld	(SC1BUF), 71h
	ld	(SC1CR), 0FFh
	ld	(3Fh), 70h
	ld	(SC1MOD), 17h

	; Initialize more registers
	ld	(P8_FC_LO), 0FFh
	ld	(P8_FC_EXT), 18h
	ld	(P8_FC_HI), 07h
	ld	(PE_DATA), 00h
	ld	(PE_CR), 0FFh
	ld	(TREG0), 1Dh
	ld	(TREG1), 1Dh
	ld	(T8RUN), 00h
	ld	(T23MOD), 0Ah
	ld	(T23FFCR), 10h
	ld	(TREG2), 40h
	ld	(TREG3), 20h
	ld	(WDCR), 00h		; Watchdog control
	set	1, (WDMOD)		; Watchdog mode
	ld	(T4MOD), 05h
	ld	(T4FFCR), 00h
	ld	(CAP4H), 00h
	ld	(CAP4L), 00h
	set	7, (CAP4L)

	; Initialize timer registers
	ld	(MSAR0), 10h
	ld	(MSAR1), 11h
	ld	(MSAR2), 0FFh
	ld	(MSAR3), 00h
	ld	(MSAR4), 12h
	ld	(MSAR5), 13h
	ld	(MAMR0), 07h
	ld	(MAMR1), 03h
	ld	(MAMR2), 01h

	; Check bit 0 of register 0x40 for clock configuration
	bit	0, (P8_DATA)
	jr	NZ, .clock_alt
	ld	(MAMR3), 1Fh
	jr	.clock_done
.clock_alt:
	ld	(MAMR3), 0Fh
.clock_done:
	ld	(MAMR4), 01h
	ld	(MAMR5), 01h

	; Initialize serial/DMA registers
	ld	(SER0_MOD), 01h
	ld	(SER0_CR), 00h
	and	(SER0_BAUD), 0CFh
	and	(SER0_BAUD), 0F0h
	ld	(SER1_MOD), 29h
	lda	XBC, SER1_MOD
	ld	A, (XBC)
	and	A, 0FCh
	set	0, A
	ld	(XBC), A
	ld	(SER1_CR), 00h
	and	(SER1_BAUD), 0CFh
	and	(SER1_BAUD), 0F0h

	; Initialize DRAM refresh
	ld	(DRAM_TIMING1), 71h
	ld	(DRAM_REFRESH), 8Bh
	ld	(DRAM_CTRL), 58h
	res	4, (DRAM_TIMING2)

	; More timer configuration
	ld	(B0CSL), 66h
	ld	(B1CSL), 66h
	ld	(B2CSL), 22h
	ld	(B3CSL), 22h
	ld	(B4CSL), 66h
	ld	(B5CSL), 66h
	ld	(B0CSH), 81h
	ld	(B1CSH), 81h
	ld	(B2CSH), 0C0h

	; Check clock config again
	bit	0, (P8_DATA)
	jr	NZ, .clock_alt2
	ld	(B3CSH), 8Ah
	jr	.clock_done2
.clock_alt2:
	ld	(B3CSH), 89h
.clock_done2:
	ld	(B4CSH), 80h
	ld	(B5CSH), 81h
	ld	(PORT_FC_4), 00h

	; Set up stack pointer
	LDA_XWA_IMM24 STACK_INIT	; lda XWA, 0x0005a2 (24-bit encoding)
	ld	XSP, XWA

	; Copy interrupt vector trampolines to RAM at 0x0400
	CALR COPY_VECTORS		; calr is shorter than call

	; Enable interrupts at level 0
	ei	0

	; Call initialization routines
	call	INIT_MEMORY_TEST	; 0xFF8956 - Memory test
	call	INIT_DMA_SERIAL		; 0xFF85AE - DMA/Serial init
	call	INIT_TONE_GEN		; 0xFF84A8 - Tone generator init

	jr	T, MAIN_LOOP		; Jump to main loop (2-byte NOP in fall-through)

; ==============================================================================
; Main Loop - Wait for payload ready, then call it
; ==============================================================================

MAIN_LOOP:
	res	6, (SUBCPU_STATUS_FLAGS)		; Clear ready flag
.wait_loop:
	bit	6, (SUBCPU_STATUS_FLAGS)		; Check if payload ready
	jr	Z, .check_status
	ei	6			; Enable interrupt level 6
	CALL_ABS24 PAYLOAD_ENTRY	; Call payload at 0x0400 (4-byte encoding)
.check_status:
	; Read serial status and update control
	ldcf	1, (INTTC01)
	scc	C, A
	cpl	A
	and	A, 01h
	sla	1, A
	and	(INTTC01), 0FDh
	or	(INTTC01), A
	jr	.wait_loop

; ==============================================================================
; DEFAULT_HANDLER (0xFF8432) - Default interrupt handler (just returns)
; ==============================================================================

	org	0FF8432h

DEFAULT_HANDLER:
	reti

; ==============================================================================
; RESET_ENTRY (0xFF8433) - Alternative reset/NMI handler
; ==============================================================================

RESET_ENTRY:
	JRL_T	BOOT_INIT		; Jump back to boot init (3-byte relative jump)
	reti				; 0xFF8436: Alternate entry point

; ==============================================================================
; TONE_GEN_CHANNEL_INIT (0xFF8437) - Initialize tone generator channels
; Loops through 4 channels and calls TONE_GEN_WRITE for each
; ==============================================================================

TONE_GEN_CHANNEL_INIT:
	push	QIZ			; Save QIZ (QIZH used as loop counter)
	CP_MEM24_IMM16 0FFFEEEh, 0FFFFh	; cp (0xFFFEEE), 0xFFFF - check init flag
	jr	NZ, .done		; Skip if memory not 0xFFFF (already initialized)
	LD_QIZH_0			; Clear loop counter (QIZH = 0)
.loop:
	LD_A_QIZH			; A = loop counter (QIZH)
	extz	WA			; Zero-extend A to WA
	LD_C_QIZH			; C = loop counter (QIZH)
	extz	BC			; Zero-extend C to BC
	SLA_2_BC			; BC <<= 2 (multiply by 4 for table index)
	LDA_XDE_IMM24 0FFFEF0h		; XDE = pointer to channel config table
	LD_XBC_pXDE_BC			; XBC = config[channel] (4 bytes per entry)
	call	TONE_GEN_WRITE		; Write config to tone generator
	INC_1_QIZH			; Increment loop counter
	CP_QIZH_4			; Compare counter with 4
	jr	C, .loop		; Loop while counter < 4
.done:
	pop	QIZ			; Restore QIZ
	ret

; ==============================================================================
; COPY_VECTORS (0xFF846D) - Copy interrupt trampolines to RAM
; ==============================================================================

COPY_VECTORS:
	ld	XDE, 00000400h		; Destination: RAM at 0x0400
	ld	XHL, 0FF8F6Ch		; Source: Trampoline data in ROM
	ld	XBC, 0000000E1h		; Count: 225 bytes (45 handlers x 5 bytes)
	or	XBC, XBC
	jr	Z, .done
	LDIR_94				; Block copy (TMP94C241 encoding)
	cp	QBC, 0
	jr	Z, .done
	ld	WA, QBC
.copy_rest:
	LDIR_94				; TMP94C241 encoding
	djnz	WA, .copy_rest
.done:
	ret

; ==============================================================================
; HALT_LOOP (0xFF8490) - Halt and loop forever (error condition)
; ==============================================================================

	org	0FF8490h

HALT_LOOP:
	res	0, (SC0MOD)		; Disable serial
.halt:
	halt				; Halt CPU
	jr	T, .halt		; Loop forever if we wake (jump to halt, not start)

; ==============================================================================
; Stub routines (0xFF8496) - Return 0 in HL
; These are placeholder/unused routines
; ==============================================================================

OUTPUT_NOP_RET:
	ld	HL, 0
	ret

STUB_8499:
	ld	HL, 0
	ret

STUB_849C:
	ld	HL, 0
	ret

STUB_849F:
	ld	HL, 0
	ret

STUB_84A2:
	ld	HL, 0
	ret

STUB_84A5:
	ld	HL, 0
	ret

; ==============================================================================
; INIT_TONE_GEN (0xFF84A8) - Initialize tone generator at 0x130000
; ==============================================================================

INIT_TONE_GEN:
	link	XIZ, -8			; Reserve 8 bytes on stack
	xor	XWA, XWA
	ld	XWA, 5A5A5A5Ah		; Test pattern
	ld	(XIZ-8), XWA
	ld	(XIZ-4), XWA
	lda	XWA, XIZ-8
	push	XWA
	ld	BC, 0
	CALR	TONE_GEN_WRITE		; Call relative (3-byte encoding)
	pop	XWA
	push	XWA
	ld	BC, 1
	CALR	TONE_GEN_WRITE
	pop	XWA
	push	XWA
	ld	BC, 2
	CALR	TONE_GEN_WRITE
	pop	XWA
	push	XWA
	ld	BC, 3
	CALR	TONE_GEN_WRITE
	pop	XWA

	; Initialize tone generator registers
	ld	XBC, TONE_GEN_BASE
	ld	XWA, 0101001Fh
	LD_D	4			; TMP94C241 encoding (24 04)
.init_loop:
	ld	W, A
	ld	(XBC), XWA
	add	A, 20h
	djnz	D, .init_loop
	unlk	XIZ
	ret

; ==============================================================================
; TONE_GEN_WRITE (0xFF84F1) - Write to tone generator
; ==============================================================================

	org	0FF84F1h

TONE_GEN_WRITE:
	push	DE
	sll	5, A			; A = A << 5
	set	4, A			; A |= 0x10
	ld	XHL, TONE_GEN_BASE
	ld	D, 8
.write_loop:
	ld	(XHL), A
	ld	E, (XBC+)
	ld	(XHL+2), E
	inc	1, A
	djnz	D, .write_loop
	pop	DE
	ret

; ==============================================================================
; WRITE_TONE_REG_MULTI_CHANNEL (0xFF850E) - Push registers and call WRITE_TONE_REG_SINGLE_CHANNEL multiple times
; Appears to write multiple register pairs to tone generator
; ==============================================================================

WRITE_TONE_REG_MULTI_CHANNEL:
	push	XBC
	push	XDE
	PUSH_WORD 1			; Push channel 1
	CALR	WRITE_TONE_REG_SINGLE_CHANNEL
	LD_XBC_pXSP_d 0Ah		; ld XBC, (XSP+0x0A)
	LD_XDE_XIZ			; ld XDE, XIZ
	PUSH_WORD 0			; Push channel 0
	CALR	WRITE_TONE_REG_SINGLE_CHANNEL
	ld	XBC, XWA
	ld	XDE, XHL
	PUSH_WORD 2			; Push channel 2
	CALR	WRITE_TONE_REG_SINGLE_CHANNEL
	ld	XBC, XIX
	ld	XDE, XIY
	PUSH_WORD 3			; Push channel 3
	CALR	WRITE_TONE_REG_SINGLE_CHANNEL
	INC_0_XSP			; inc 0, XSP (adjust stack)
	pop	XDE
	pop	XBC
	ret

; ==============================================================================
; WRITE_TONE_REG_SINGLE_CHANNEL (0xFF853A) - Write register pair to tone generator channel
; ==============================================================================

WRITE_TONE_REG_SINGLE_CHANNEL:
	push	XIY
	push	WA
	push	BC
	LD_A_pXSP_d 0Ch			; ld A, (XSP+0x0C) - get channel from stack
	sll	5, A			; A = A << 5
	set	4, A			; A |= 0x10
	ld	XIY, TONE_GEN_BASE
	ld	(XIY), A		; Write register address
	ld	(XIY+2), C		; Write C
	inc	1, A
	ld	(XIY), A
	ld	(XIY+2), B		; Write B
	inc	1, A
	ld	(XIY), A
	LD_BC_QBC			; ld BC, QBC (high word of XBC)
	ld	(XIY+2), C
	inc	1, A
	ld	(XIY), A
	ld	(XIY+2), B
	inc	1, A
	ld	(XIY), A
	ld	(XIY+2), E		; Write E
	inc	1, A
	ld	(XIY), A
	ld	(XIY+2), D		; Write D
	inc	1, A
	ld	(XIY), A
	LD_BC_QDE			; ld BC, QDE (high word of XDE)
	ld	(XIY+2), C
	inc	1, A
	ld	(XIY), A
	ld	(XIY+2), B
	pop	BC
	pop	WA
	pop	XIY
	ret

; ==============================================================================
; COPY_WORDS (0xFF858B) - Copy words from XBC to XDE, count in DE
; ==============================================================================

COPY_WORDS:
	ld	XIX, XWA
	ld	XIY, XBC
	ld	BC, DE
	LDIRW_95			; ldirw (word block copy)
	ret

; ==============================================================================
; FILL_WORDS (0xFF8594) - Fill memory at XWA with BC, count in DE
; ==============================================================================

FILL_WORDS:
	LD_pXWA_plus_BC			; ld (XWA+), BC
	DJNZ_DE FILL_WORDS		; djnz DE, FILL_WORDS
	ret

; ==============================================================================
; CHECKSUM_CALC (0xFF859B) - Calculate checksum from XWA to XWA+XBC
; Returns complemented sum in HL
; ==============================================================================

CHECKSUM_CALC:
	xor	XHL, XHL		; Clear XHL
	extz	XBC			; Zero-extend BC to XBC
	add	XBC, XWA		; End address = start + count
.loop:
	ADD_XHL_pXWA_plus		; add XHL, (XWA+)
	cp	XWA, XBC
	jr	LT, .loop		; Loop while XWA < end
	cpl	HL			; Complement result
	ret

; ==============================================================================
; STUB_85AB (0xFF85AB) - Return 0 in HL
; ==============================================================================

STUB_85AB:
	ld	HL, 0
	ret

; ==============================================================================
; INIT_DMA_SERIAL (0xFF85AE) - Initialize DMA for payload reception
; ==============================================================================
;
; Configures DMA channels and serial hardware for inter-CPU communication.
; Called once during boot before the main loop begins waiting for payload.
;
; DMA Channel Configuration:
;   Channel 0: Receive from latch (source = 0x120000, fixed)
;   Channel 2: Send to latch (dest = 0x120000, used for responses)
;
; After this initialization:
;   - DMA_XFER_STATE = 0 (idle)
;   - CMD_PROCESSING_STATE = 0 (idle)
;   - Sub CPU is ready to receive payload from main CPU
; ==============================================================================

INIT_DMA_SERIAL:
	and	(PF_FC), 0F8h		; Clear E5 bits
	res	2, (WDMOD)		; Watchdog mode
	lda	XBC, PORT_FC_1
	ld	A, (XBC)
	and	A, 0F8h
	or	A, 05h
	ld	(XBC), A
	lda	XBC, PORT_FC_2
	ld	A, (XBC)
	and	A, 0F8h
	or	A, 05h
	ld	(XBC), A
	lda	XBC, PORT_FC_3
	ld	A, (XBC)
	and	A, 0F8h
	set	0, A
	ld	(XBC), A
	ld	(TREG2), 0Ah

	; Set up DMA for inter-CPU latch at 0x120000
	lda	XWA, INTER_CPU_LATCH
	LDC_DMAD2_XWA			; DMA channel 2 destination = 0x120000
	ld	A, 08h
	LDC_DMAM2_A			; DMA channel 2 mode = 8 (byte, src inc, dest fixed)
	lda	XWA, INTER_CPU_LATCH
	LDC_DMAS0_XWA			; DMA channel 0 source = 0x120000
	LD_A	0			; TMP94C241 encoding (21 00)
	LDC_DMAM0_A			; DMA channel 0 mode = 0 (byte, dest inc, src fixed)

	; Clear variables
	ld	(DMA_XFER_STATE), 00h
	ld	(CMD_PROCESSING_STATE), 00h
	ret

; ==============================================================================
; INTER-CPU DMA TRANSFER ROUTINES (0xFF8604-0xFF881E) - 539 bytes
; ==============================================================================
;
; These routines implement the sub CPU's side of the 192KB payload loading
; protocol. The main CPU sends firmware payload data to the sub CPU via DMA
; through the inter-CPU latch at 0x120000.
;
; PAYLOAD LOADING PROTOCOL:
; -------------------------
; 1. Main CPU sends command byte with count via latch
; 2. Sub CPU receives interrupt, sets up DMA to receive data
; 3. Data is DMA'd from latch to sub CPU RAM
; 4. Sub CPU acknowledges via INTERCPU_STATUS handshake flags
; 5. Repeat until all 192KB is transferred
; 6. Main CPU sends E3 command to signal payload complete
; 7. Sub CPU jumps to payload entry point at 0x0400
;
; COMMAND TYPES:
; --------------
; E1: Two-phase transfer setup (6 bytes: dest_addr[4] + count[2])
; E2: Parameter block transfer (10 bytes: src[4] + dest[4] + count[2])
; E3: Payload complete signal (no data, just sets ready flag)
; 00-1F: Variable-length data (low 5 bits = count-1, high 3 bits = handler)
;
; DMA STATE MACHINE (DMA_XFER_STATE):
; -----------------------------------
; 0 = Idle (no transfer in progress)
; 1 = Single transfer pending (waiting for completion)
; 2 = Two-phase transfer (E1 mode: phase 1 done, phase 2 pending)
;
; ROUTINES:
; ---------
; SendData_Chunked  (0xFF8604): Break large transfers into 32-byte chunks
; SendData_Block    (0xFF8649): Send single data block with handshaking
; SendCmd_E3        (0xFF86AC): Signal payload ready to main CPU
; SendParams_E2     (0xFF86DC): Wait for DMA, then send E2 parameters
; TwoPhase_Transfer (0xFF874C): Execute E1 two-phase DMA sequence
; ==============================================================================

; ------------------------------------------------------------------------------
; SendData_Chunked (0xFF8604) - Send large data buffer in 32-byte chunks
; ------------------------------------------------------------------------------
; Breaks a large transfer into manageable 32-byte chunks to avoid overwhelming
; the inter-CPU communication channel. Used for bulk payload transfers.
;
; Input:  A   = command/channel byte
;         BC  = total byte count
;         XDE = source address in sub CPU memory
; Output: None (data sent via DMA)
; Modifies: IZ used as remaining count, stack frame for parameters
; ------------------------------------------------------------------------------
SendData_Chunked:
	DEC_6_XSP			; Allocate 6 bytes on stack
	push	IZ			; Save IZ
	LD_pXSP_d_XDE	02h		; Save source address at (SP+2)
	LD_IZ_BC			; IZ = total byte count
	LD_pXSP_d_A	06h		; Save channel/command at (SP+6)
	CP_IZ_imm16	0020h		; Is count <= 32?
	jr	ULE, .send_final	; Yes - send final chunk directly
.chunk_loop:
	LD_A_pXSP_d	06h		; A = channel/command
	EXTZ_WA				; Zero-extend A to WA
	ld	BC, 0020h		; BC = 32 (chunk size)
	LD_XDE_pXSP_d	02h		; XDE = current source address
	calr	SendData_Block		; Send 32-byte chunk
	ld	XWA, 00000020h		; XWA = 32
	ADD_pXSP_d_XWA	02h		; Advance source address by 32
	SUB_IZ_imm16	0020h		; Subtract 32 from remaining count
	CP_IZ_imm16	0020h		; Is remaining > 32?
	jr	UGT, .chunk_loop	; Yes - continue chunking
.send_final:
	LD_A_pXSP_d	06h		; A = channel/command
	EXTZ_WA				; Zero-extend A to WA
	LD_C_IZL			; C = remaining count (low byte)
	EXTZ_BC				; Zero-extend C to BC
	LD_XDE_pXSP_d	02h		; XDE = current source address
	calr	SendData_Block		; Send final chunk
	pop	IZ			; Restore IZ
	INC_6_XSP			; Deallocate 6 bytes from stack
	ret

; ------------------------------------------------------------------------------
; SendData_Block (0xFF8649) - Send single data block with handshaking
; ------------------------------------------------------------------------------
; Core DMA send routine. Implements the full handshaking protocol:
; 1. Wait for main CPU ready (bit 4 of INTERCPU_STATUS)
; 2. Clear our ready flag, set DMA_XFER_STATE = 1
; 3. Send command byte: (channel << 5) | (count - 1)
; 4. Wait for main CPU acknowledgment
; 5. Set up DMA source/count, trigger transfer
; 6. Wait for DMA_XFER_STATE to return to 0
;
; Input:  A   = command/channel byte (used in high 3 bits)
;         BC  = byte count (1-32 bytes)
;         XDE = source address
; Output: None
; Timeout: 60000 iterations (~0.3 sec at 20MHz) before giving up
; ------------------------------------------------------------------------------
SendData_Block:
	cp	C, 0			; Is count zero?
	ret	Z			; Yes - nothing to send
	ld	IX, 0			; IX = timeout counter
.wait_ready1:
	bit	4, (INTERCPU_STATUS)	; Check if other CPU ready
	jr	Z, .timeout1		; Not ready - check timeout
	res	0, (INTERCPU_STATUS)	; Clear our ready flag
	ld	(DMA_XFER_STATE), 01h	; Set DMA sync flag
	ld	L, C			; L = byte count
	dec	1, L			; L = count - 1
	sll	5, A			; A = command << 5
	or	A, L			; A = (command << 5) | (count - 1)
	ld	(INTER_CPU_LATCH), A	; Send command+count to main CPU
	ld	IX, 0			; Reset timeout counter
.wait_ready2:
	bit	4, (INTERCPU_STATUS)	; Check if main CPU acknowledged
	jr	NZ, .timeout2		; Main CPU responded - check timeout
	set	0, (INTERCPU_STATUS)	; Set our ready flag
	LDC_DMAS2_XDE			; DMA source = XDE
	EXTZ_BC				; Zero-extend BC (count)
	LDC_DMAC2_BC			; DMA count = BC
	ld	(DMA_BURST_CTRL), 16h	; Set DMA mode
	set	2, (T01MOD)		; Start DMA transfer
	cp	(DMA_XFER_STATE), 00h	; Is DMA complete?
	ret	Z			; Yes - return
.wait_dma_done:
	cp	(DMA_XFER_STATE), 00h	; Check DMA sync flag
	jr	NZ, .wait_dma_done	; Wait until cleared
	ret
.timeout1:
	ld	HL, IX			; HL = timeout counter
	inc	1, IX			; Increment counter
	cp	HL, 0EA60h		; Timeout limit (60000 iterations)
	jr	ULE, .wait_ready1	; Keep waiting if not timed out
	ret				; Timeout - give up
.timeout2:
	ld	WA, IX			; WA = timeout counter
	inc	1, IX			; Increment counter
	cp	WA, 0EA60h		; Timeout limit
	jr	ULE, .wait_ready2	; Keep waiting if not timed out
	set	0, (INTERCPU_STATUS)	; Set ready flag before returning
	ret

; ------------------------------------------------------------------------------
; SendCmd_E3 (0xFF86AC) - Signal payload transfer complete
; ------------------------------------------------------------------------------
; Sends the E3 command to main CPU indicating that the 192KB payload has been
; successfully received and the sub CPU is ready to execute it.
;
; After this command, the main CPU knows the sub CPU will jump to 0x0400.
;
; Protocol:
; 1. Wait for main CPU ready
; 2. Send 0xE3 to inter-CPU latch
; 3. Wait for acknowledgment
; 4. Set our ready flag
;
; Input:  None
; Output: None
; Timeout: 60000 iterations before giving up
; ------------------------------------------------------------------------------
SendCmd_E3:
	ld	BC, 0			; BC = timeout counter
.wait_ready:
	bit	4, (INTERCPU_STATUS)	; Check if main CPU ready
	jr	Z, .timeout1		; Not ready - check timeout
	res	0, (INTERCPU_STATUS)	; Clear our ready flag
	ld	(INTER_CPU_LATCH), 0E3h	; Send E3 command to main CPU
.wait_ack:
	bit	4, (INTERCPU_STATUS)	; Check for acknowledgment
	jr	NZ, .timeout2		; Got response - handle in timeout2
.set_flag_ret:				; Success path AND timeout2 target
	set	0, (INTERCPU_STATUS)	; Set our ready flag
	ret				; Done
.timeout1:
	ld	WA, BC			; WA = timeout counter
	inc	1, BC			; Increment counter
	cp	WA, 0EA60h		; Timeout limit (60000)
	jr	ULE, .wait_ready	; Keep waiting if not timed out
	ret				; Timeout - give up
.timeout2:
	ld	WA, BC			; WA = timeout counter
	inc	1, BC			; Increment counter
	cp	WA, 0EA60h		; Timeout limit
	jr	UGT, .set_flag_ret	; Timed out - set flag and return
	jr	T, .wait_ack		; Not timed out - keep waiting

; ------------------------------------------------------------------------------
; SendParams_E2 (0xFF86DC) - Send E2 parameter block to main CPU
; ------------------------------------------------------------------------------
; Waits for any pending DMA to complete, then sends an E2 command with a
; 10-byte parameter block containing transfer parameters.
;
; E2 Parameter Block (DMA_SETUP_PARAMS, 10 bytes):
;   Offset 0-3: XWA value (source address or parameter 1)
;   Offset 4-7: XDE value (destination address or parameter 2)
;   Offset 8-9: BC value (count or parameter 3)
;
; Protocol:
; 1. Wait for DMA_XFER_STATE = 0
; 2. Send 0xE2 command
; 3. Wait for main CPU ready
; 4. Build parameter block at DMA_SETUP_PARAMS
; 5. DMA transfer 10 bytes to main CPU
; 6. Wait for completion
;
; Input:  XWA, XDE, BC = parameters to pack into block
; Output: Parameter block sent to main CPU
; ------------------------------------------------------------------------------
SendParams_E2:
	ld	IX, 0			; IX = timeout counter
.wait_sync_clear:
	cp	(DMA_XFER_STATE), 00h	; Is DMA sync flag clear?
	jr	Z, .sync_cleared	; Yes - proceed
.timeout_wait:
	ld	HL, IX			; HL = timeout counter
	inc	1, IX			; Increment counter
	cp	HL, 0EA60h		; Timeout limit (60000)
	ret	UGT			; Timeout - give up and return
	cp	(DMA_XFER_STATE), 00h	; Check sync flag again
	jr	NZ, .timeout_wait	; Still not clear - keep waiting
.sync_cleared:
	res	0, (INTERCPU_STATUS)	; Clear our ready flag
	ld	(DMA_XFER_STATE), 01h	; Set DMA sync flag
	ld	(INTER_CPU_LATCH), 0E2h	; Send E2 command to main CPU
	ld	IX, 0			; Reset timeout counter
.wait_cpu_ready:
	bit	4, (INTERCPU_STATUS)	; Check if main CPU ready
	jr	NZ, .timeout2		; Not ready yet - check timeout
	set	0, (INTERCPU_STATUS)	; Set our ready flag
	lda	XHL, DMA_SETUP_PARAMS	; XHL = address of DMA parameter block
	ld	(XHL), XWA		; Store XWA parameter
	ld	(XHL+04h), XDE		; Store XDE parameter
	ld	(XHL+08h), BC		; Store BC parameter
	LDC_DMAS2_XHL			; DMA source = XHL (param block addr)
	ld	WA, 000Ah		; WA = 10 (DMA count)
	LDC_DMAC2_WA			; DMA count = 10
	ld	(DMA_BURST_CTRL), 16h	; Set DMA mode
	set	2, (T01MOD)		; Start DMA transfer
	set	7, (PAYLOAD_LOADED_FLAG)	; Set DMA ready flag
	cp	(DMA_XFER_STATE), 00h	; Is DMA complete?
	ret	Z			; Yes - return
.wait_dma_done:
	cp	(DMA_XFER_STATE), 00h	; Check DMA sync flag
	jr	NZ, .wait_dma_done	; Wait until cleared
	ret
.timeout2:
	ld	HL, IX			; HL = timeout counter
	inc	1, IX			; Increment counter
	cp	HL, 0EA60h		; Timeout limit
	jr	ULE, .wait_cpu_ready	; Keep waiting if not timed out
	set	0, (INTERCPU_STATUS)	; Set ready flag before returning
	ret

; ------------------------------------------------------------------------------
; TwoPhase_Transfer (0xFF874C) - Execute E1 two-phase DMA sequence
; ------------------------------------------------------------------------------
; Implements the E1 command protocol for transferring data that requires
; setup parameters before the actual data. Used for complex transfers where
; the destination and count need to be communicated first.
;
; PHASE 1: Send 6-byte setup block
;   - Source: E1_XFER_PARAMS (0x050C)
;   - Contains: dest_addr[4] + count[2]
;   - DMA_XFER_STATE: 2 -> 1 on completion
;
; DELAY: 200 iteration pause (hardware settling time)
;
; PHASE 2: Send actual data
;   - Source: Address from E2_XFER_PARAMS (0x053E)
;   - Count: From E2_XFER_PARAMS + 4
;   - DMA_XFER_STATE: 1 -> 0 on completion
;
; Input:  XWA = source address for phase 2 data
;         XDE = destination address (stored to both buffers)
;         BC  = byte count (stored to both buffers)
; Output: Data transferred in two phases
; Timing: 200-cycle delays between phases for hardware sync
; ------------------------------------------------------------------------------
TwoPhase_Transfer:
	push	IZ			; Save IZ
	ld	IZ, 0			; IZ = timeout counter
.wait_sync:
	cp	(DMA_XFER_STATE), 00h	; Is DMA sync clear?
	jr	Z, .sync_cleared	; Yes - proceed
.timeout_sync:
	ld	HL, IZ			; HL = timeout counter
	inc	1, IZ			; Increment counter
	cp	HL, 0EA60h		; Timeout limit (60000)
	jrl	UGT, .exit		; Timeout - exit
	cp	(DMA_XFER_STATE), 00h	; Check sync again
	jr	NZ, .timeout_sync	; Still not clear - keep waiting
.sync_cleared:
	ld	IZ, 0			; Reset timeout counter
.wait_cpu_ready:
	bit	4, (INTERCPU_STATUS)	; Check if CPU ready
	jrl	Z, .timeout_ready1	; Not ready - timeout handler
	res	0, (INTERCPU_STATUS)	; Clear our ready flag
	ld	(DMA_XFER_STATE), 02h	; Set sync flag to E1 mode
	ld	(INTER_CPU_LATCH), 0E1h	; Send E1 command
	ld	IZ, 0			; Reset timeout counter
.wait_ack:
	bit	4, (INTERCPU_STATUS)	; Check for acknowledgment
	jrl	NZ, .timeout_ack	; Not acknowledged - timeout handler
	set	0, (INTERCPU_STATUS)	; Set our ready flag
	; Phase 1: Set up first DMA transfer
	lda	XHL, E2_XFER_PARAMS	; XHL = 0x053E (second buffer)
	ld	(XHL), XWA		; Store XWA to buffer
	lda	XWA, E1_XFER_PARAMS	; XWA = 0x050C (first buffer)
	ld	(XWA), XDE		; Store XDE to first buffer
	ld	(XHL+04h), BC		; Store BC to second buffer+4
	ld	(XWA+04h), BC		; Store BC to first buffer+4
	LDC_DMAS2_XWA			; DMA source = first buffer (0x050C)
	ld	WA, 6			; WA = 6 (DMA count)
	LDC_DMAC2_WA			; DMA count = 6
	ld	(DMA_BURST_CTRL), 16h	; Set DMA mode
	set	2, (T01MOD)		; Start DMA transfer
	; Wait for first transfer to complete (sync flag = 1)
	cp	(DMA_XFER_STATE), 01h	; Is sync flag = 1?
	jr	Z, .phase1_done		; Yes - phase 1 complete
.wait_phase1:
	cp	(DMA_XFER_STATE), 01h	; Check sync flag
	jr	NZ, .wait_phase1	; Wait until = 1
.phase1_done:
	; Delay loop (200 iterations)
	ld	IZ, 0			; IZ = delay counter
	cp	IZ, 00C8h		; Counter reached 200?
	jr	NC, .delay1_done	; Yes - done
.delay1_loop:
	nop				; Small delay
	inc	1, IZ			; Increment counter
	cp	IZ, 00C8h		; Check again
	jr	C, .delay1_loop		; Continue if < 200
.delay1_done:
	; Phase 2: Set up second DMA transfer
	lda	XWA, E2_XFER_PARAMS	; XWA = 0x053E (second buffer)
	ld	XBC, (XWA)		; XBC = contents of second buffer
	LDC_DMAS2_XBC			; DMA source = XBC
	ld	WA, (XWA+04h)		; WA = count from buffer+4
	LDC_DMAC2_WA			; DMA count = WA
	ld	(DMA_BURST_CTRL), 16h	; Set DMA mode
	set	2, (T01MOD)		; Start DMA transfer
	; Wait for second transfer to complete (sync flag = 0)
	cp	(DMA_XFER_STATE), 00h	; Is sync flag = 0?
	jr	Z, .phase2_done		; Yes - phase 2 complete
.wait_phase2:
	cp	(DMA_XFER_STATE), 00h	; Check sync flag
	jr	NZ, .wait_phase2	; Wait until = 0
.phase2_done:
	; Second delay loop (200 iterations)
	ld	IZ, 0			; IZ = delay counter
	cp	IZ, 00C8h		; Counter reached 200?
	jr	NC, .delay2_done	; Yes - skip to exit jump
.delay2_loop:
	nop				; Small delay
	inc	1, IZ			; Increment counter
	cp	IZ, 00C8h		; Check again
	jr	C, .delay2_loop		; Continue if < 200
.delay2_done:
	jr	T, .exit		; Unconditional jump to exit
.timeout_ready1:
	ld	HL, IZ			; HL = timeout counter
	inc	1, IZ			; Increment counter
	cp	HL, 0EA60h		; Timeout limit
	jrl	ULE, .wait_cpu_ready	; Keep waiting if not timed out
	jr	T, .exit		; Timeout - exit
.timeout_ack:
	ld	HL, IZ			; HL = timeout counter
	inc	1, IZ			; Increment counter
	cp	HL, 0EA60h		; Timeout limit
	jrl	ULE, .wait_ack		; Keep waiting if not timed out
	set	0, (INTERCPU_STATUS)	; Set ready flag before exit
.exit:
	pop	IZ			; Restore IZ
	ret

; ==============================================================================
; InterCPU_RX_Handler (0xFF881F) - Inter-CPU Command Receive Interrupt
; ==============================================================================
;
; Called when data arrives from main CPU via inter-CPU latch at 0x120000.
; This is the primary entry point for all incoming payload data during boot.
;
; The handler reads the command byte, decodes it, and sets up DMA to receive
; the associated data payload into the appropriate buffer.
;
; COMMAND DECODING:
; -----------------
; E1: Two-phase transfer setup
;     - Receives 6 bytes to E1_XFER_PARAMS (dest_addr[4] + count[2])
;     - Sets CMD_PROCESSING_STATE = 2 for phase 2 execution
;
; E2: Parameter block for bulk transfer
;     - Receives 10 bytes to CMD_E2_BUFFER (src[4] + dest[4] + count[2])
;     - Used for large payload chunks
;
; E3: Payload complete signal
;     - No data, just sets bit 6 of SUBCPU_STATUS_FLAGS
;     - Sub CPU can now jump to payload at 0x0400
;
; 00-1F: Variable-length data packets
;     - Low 5 bits = byte count - 1 (so 0x00 = 1 byte, 0x1F = 32 bytes)
;     - High 3 bits = handler index (looked up in table at 0x8000)
;     - Data received to CMD_DATA_BUFFER for handler processing
; ==============================================================================

	org	0FF881Fh

InterCPU_RX_Handler:
	push	XWA
	bit	2, (SC0BUF)		; Check serial status
	jr	NZ, .exit
	ld	A, (INTER_CPU_LATCH)	; Read command from main CPU
	ld	(LAST_CMD_BYTE), A	; Save received byte
	cp	A, 0E1h			; Command E1?
	jr	NZ, .not_e1
	; E1: Set up DMA for 6 bytes
	ld	(CMD_PROCESSING_STATE), 02h
	lda	XWA, CMD_E1_BUFFER
	ld	(DMA_TARGET_ADDR), XWA
	LDC_DMAD0_XWA			; DMA channel 0 destination
	ld	WA, 6
	LDC_DMAC0_WA			; DMA channel 0 count = 6
	jr	.start_dma
.not_e1:
	cp	A, 0E2h			; Command E2?
	jr	NZ, .not_e2
	; E2: Set up DMA for 10 bytes
	ld	(CMD_PROCESSING_STATE), 03h
	lda	XWA, CMD_E2_BUFFER
	ld	(DMA_TARGET_ADDR), XWA
	LDC_DMAD0_XWA			; DMA channel 0 destination
	ld	WA, 000Ah
	LDC_DMAC0_WA			; DMA channel 0 count = 10
	jr	.start_dma
.not_e2:
	cp	A, 0E3h			; Command E3?
	jr	NZ, .default_cmd
	; E3: Signal payload ready
	set	6, (SUBCPU_STATUS_FLAGS)
	jr	.clear_flag
.default_cmd:
	; Other commands: variable-length DMA based on low 5 bits
	ld	(CMD_PROCESSING_STATE), 01h
	lda	XWA, CMD_DATA_BUFFER
	ld	(DMA_TARGET_ADDR), XWA
	LDC_DMAD0_XWA			; DMA channel 0 destination
	ld	A, (LAST_CMD_BYTE)
	and	A, 1Fh			; Low 5 bits = count - 1
	inc	1, A
	extz	WA
	LDC_DMAC0_WA			; DMA channel 0 count
.start_dma:
	ld	(0100h), 0Ah		; Trigger DMA
.clear_flag:
	res	1, (SC0BUF)
.exit:
	pop	XWA
	reti

; ==============================================================================
; DMA_Complete_Handler (0xFF889A) - DMA Transfer Complete Interrupt
; ==============================================================================
;
; Called when a DMA channel completes its transfer. Advances the DMA state
; machine to track multi-phase transfer progress:
;
;   State 2 (two-phase) -> State 1 (phase 1 done, phase 2 pending)
;   State 1 (single)    -> State 0 (idle, transfer complete)
;
; This handler is critical for the E1 two-phase transfer protocol, where
; phase 1 sends parameters and phase 2 sends the actual data.
; ==============================================================================

	org	0FF889Ah

DMA_Complete_Handler:
	res	2, (WDMOD)		; Clear watchdog bit
	cp	(DMA_XFER_STATE), 01h	; State 1?
	jr	NZ, .not_state1
	ld	(DMA_XFER_STATE), 00h	; -> State 0
	jr	.done
.not_state1:
	cp	(DMA_XFER_STATE), 02h	; State 2?
	jr	NZ, .done
	ld	(DMA_XFER_STATE), 01h	; -> State 1
.done:
	reti

; ==============================================================================
; CMD_Dispatch_Handler (0xFF88B8) - Command Processing Dispatcher
; ==============================================================================
;
; Main processing handler that executes after DMA receives data. Dispatches
; based on CMD_PROCESSING_STATE to handle different phases of command processing.
;
; STATE MACHINE:
; --------------
; State 0: Idle - check watchdog only
; State 1: Data received - call handler from jump table based on command byte
; State 2: E1 phase 2 - set up secondary DMA from E1_XFER_PARAMS
; State 3: Completion - set status flags for main CPU acknowledgment
; State 4: Final - clear ready flag, return to idle
;
; The jump table at 0x8000 (DATA_TABLE_8000) contains handler addresses
; indexed by the high 3 bits of the command byte.
; ==============================================================================

	org	0FF88B8h

CMD_Dispatch_Handler:
	push	XIZ
	push	XIY
	push	XIX
	push	XHL
	push	XDE
	push	XBC
	push	XWA
	ld	A, (CMD_PROCESSING_STATE)
	cp	A, 4			; State 4?
	jr	Z, .state4
	cp	A, 3			; State 3?
	jr	Z, .state3
	cp	A, 2			; State 2?
	jr	Z, .state2
	cp	A, 1			; State 1?
	jr	NZ, .check_watchdog
	; State 1: Process received data, call handler from table
	PUSH_WORD 0000h
	PUSH_WORD CMD_DATA_BUFFER
	ld	C, (LAST_CMD_BYTE)
	ld	A, C
	and	A, 1Fh			; Low 5 bits = count
	inc	1, A
	extz	WA
	push	WA
	srl	5, C			; High 3 bits = handler index
	ld	A, C
	extz	WA
	sla	2, WA			; index * 4
	lda	XBC, DATA_TABLE_8000	; Jump table at ROM start
	ld	XWA, (XBC+WA)		; Get handler address
	call	T, XWA			; Call handler (if valid)
	inc	6, XSP			; Clean up stack
	ld	(CMD_PROCESSING_STATE), 00h
	jr	.set_flag_exit
.state2:
	; State 2: Set up secondary DMA transfer
	lda	XWA, CMD_E1_BUFFER
	ld	XBC, (XWA)
	LDC_DMAD0_XBC			; DMA channel 0 destination (from XBC)
	ld	WA, (XWA+4)
	LDC_DMAC0_WA			; DMA channel 0 count
	ld	(0100h), 0Ah		; Trigger DMA
	ld	(CMD_PROCESSING_STATE), 04h	; -> State 4
	jr	.check_watchdog
.state3:
	; State 3: Set completion flags
	ld	(051Ch), 0FFh
	ld	(CMD_PROCESSING_STATE), 00h
	set	1, (SC0BUF)
	set	7, (0554h)
	jr	.check_watchdog
.state4:
	; State 4: Final state, clear ready flag
	ld	(CMD_PROCESSING_STATE), 00h
	res	7, (SUBCPU_STATUS_FLAGS)
.set_flag_exit:
	set	1, (SC0BUF)
.check_watchdog:
	bit	2, (WDMOD)
	jr	Z, .exit
	res	2, (WDMOD)
	nop
	nop
	set	2, (WDMOD)
.exit:
	pop	XWA
	pop	XBC
	pop	XDE
	pop	XHL
	pop	XIX
	pop	XIY
	pop	XIZ
	reti
	ret			; 0xFF8955: Extra return instruction

; ==============================================================================
; INIT_MEMORY_TEST (0xFF8956) - Memory test/initialization
; ==============================================================================

	org	0FF8956h

INIT_MEMORY_TEST:
	ld	(MEMTEST_RESULT), 00h
	set	1, (INTTC01)
	bit	0, (INTTC01)
	ret	NZ			; Return if bit set

	ld	WA, 0
	CALR	MEM_TEST_ROUTINE	; 0xFF89FC (3-byte relative call)
	ld	(MEMTEST_RESULT), L
	extz	HL
	ld	WA, HL
	CALR	ROM_CHECKSUM		; 0xFF8AB4 (3-byte relative call)
	ld	(MEMTEST_RESULT), L
	CALR	HARDWARE_CALIBRATION_SEQUENCE		; 0xFF8C80 (3-byte relative call)
	cp	HL, 0FFFFh
	jr	NZ, .no_error
	set	3, (MEMTEST_RESULT)
.no_error:
	ld	A, (MEMTEST_RESULT)
	extz	WA
	CALR	DELAY_ROUTINE		; 0xFF89A9 (3-byte relative call)

	; Clear serial buffer area
	LD_MEM24_IMM16	110002h, 0003h	; 7-byte encoding: f2 02 00 11 02 03 00
	lda	XBC, SERIAL_STATUS
	ld	XWA, XBC
	INC_0_XBC			; Increment XBC by 1
.clear_loop:
	ld	(XWA+), 00h
	cp	XWA, XBC
	jr	C, .clear_loop

.serial_loop:
	CALR	SERIAL_INIT		; 0xFF8B07 (3-byte relative call)
	jr	.serial_loop		; Loop calling serial init forever

; ==============================================================================
; DELAY_ROUTINE (0xFF89A9) - Variable delay based on bit pattern in A
; Uses nested loops with timer register 0x30
; ==============================================================================

	org	0FF89A9h

DELAY_ROUTINE:
	LD_L	0			; ld L, 00h (TMP94C241 encoding)
.outer_loop:
	res	1, (INTTC01)
	ld	BC, 4000h		; Default count
	bit	0, A			; Check current bit
	jr	Z, .skip_long
	ld	BC, 0C000h		; Longer delay if bit set
	jr	.delay_loop
.skip_long:
	cp	BC, 0
	jr	Z, .next_bit
.delay_loop:
	LD_E	0			; ld E, 00h (TMP94C241 encoding)
.inner_loop:
	inc	1, E
	cp	E, 20h
	jr	C, .inner_loop
	djnz	BC, .delay_loop
.next_bit:
	set	1, (INTTC01)
	ld	BC, 4000h
.delay2_outer:
	LD_E	0			; ld E, 00h (TMP94C241 encoding)
.delay2_inner:
	inc	1, E
	cp	E, 20h
	jr	C, .delay2_inner
	djnz	BC, .delay2_outer
	srl	1, A			; Next bit
	inc	1, L
	cp	L, 3
	jr	ULE, .outer_loop
	ret

; ==============================================================================
; LONG_DELAY (0xFF89E7) - Fixed long delay loop
; ==============================================================================

	org	0FF89E7h

LONG_DELAY:
	ld	BC, 0
.outer:
	ld	WA, 0
.inner:
	inc	1, WA
	cp	WA, 0100h
	jr	C, .inner
	inc	1, BC
	cp	BC, 1000h
	jr	C, .outer
	ret

; ==============================================================================
; MEM_TEST_ROUTINE (0xFF89FC) - RAM Test
; Tests memory regions with patterns 0x5A5A5A5A and 0xA5A5A5A5
; Uses test configuration table at 0xFF8020
; Returns: L = error flags
; ==============================================================================

	org	0FF89FCh

MEM_TEST_ROUTINE:
	lda	XSP, XSP-12		; Reserve 12 bytes on stack
	push	XIZ
	ld	(XSP+14), A		; Save error accumulator
	ld	(XSP+4), 00h		; Test index = 0
.next_region:
	ld	A, (XSP+4)
	extz	WA
	MULS_WA	000Ah			; Each entry is 10 bytes (TMP94C241 encoding)
	lda	XBC, 0FF8020h		; Test config table
	lda	XDE, XBC+WA		; Point to current entry
	ld	XHL, (XDE)		; Memory start address
	ld	XIZ, (XDE+4)		; Size in dwords
	srl	3, XIZ			; Convert to iteration count
	or	XIZ, XIZ
	jr	Z, .region_done
.test_loop:
	; Save original value
	ld	XWA, (XHL)
	ld	(XSP+6), XWA
	; Write pattern 1: 0x5A5A5A5A
	ld	XWA, 5A5A5A5Ah
	ld	(XHL), XWA
	ld	XIY, XHL
	lda	XIX, XSP+10
	ldiw				; Copy to temp
	ldiw
	; Verify pattern 1
	lda	XWA, XSP+10
	ld	XBC, XWA
	CP_pXWA_WORD 5A5Ah		; Check low word
	jr	Z, .low1_ok
	ld	A, (XDE+8)		; Error code for low word
	or	(XSP+14), A
.low1_ok:
	CP_pXBC_d_WORD 2, 5A5Ah		; Check high word at (XBC+2)
	jr	Z, .high1_ok
	ld	A, (XDE+9)		; Error code for high word
	or	(XSP+14), A
.high1_ok:
	; Restore and test pattern 2
	ld	XWA, (XSP+6)
	ld	(XHL+), XWA		; Restore and advance
	ld	XWA, (XHL)
	ld	(XSP+6), XWA
	; Write pattern 2: 0xA5A5A5A5
	ld	XWA, 0A5A5A5A5h
	ld	(XHL), XWA
	ld	XIY, XHL
	lda	XIX, XSP+10
	ldiw
	ldiw
	; Verify pattern 2
	lda	XWA, XSP+10
	ld	XBC, XWA
	CP_pXWA_WORD 0A5A5h		; Check low word
	jr	Z, .low2_ok
	ld	A, (XDE+8)
	or	(XSP+14), A
.low2_ok:
	CP_pXBC_d_WORD 2, 0A5A5h	; Check high word at (XBC+2)
	jr	Z, .high2_ok
	ld	A, (XDE+9)
	or	(XSP+14), A
.high2_ok:
	; Restore original
	ld	XWA, (XSP+6)
	ld	(XHL+), XWA
	sub	XIZ, 1
	jr	NZ, .test_loop
.region_done:
	inc	1, (XSP+4)
	cp	(XSP+4), 01h		; Only 1 region in boot ROM
	jrl	NZ, .next_region	; Long relative jump needed (distance > 127)
	ld	L, (XSP+14)
	extz	HL
	pop	XIZ
	lda	XSP, XSP+12
	ret

; ==============================================================================
; ROM_CHECKSUM (0xFF8AB4) - Calculate and verify boot ROM checksum
; Sums 0x800 words from 0xFE0000, compares against expected
; Returns: L = error flags (bit 2 set on mismatch)
; ==============================================================================

	org	0FF8AB4h

ROM_CHECKSUM:
	dec	4, XSP			; Reserve 4 bytes
	push	XIZ
	lda	XIX, XSP+4
	LD_pXIX_IMM16	0000h		; Checksum accumulator 1 (TMP94C241 encoding)
	lda	XHL, XIX+2
	LD_pXHL_IMM16	0000h		; Checksum accumulator 2 (TMP94C241 encoding)
	LD_W	0			; Bank counter (TMP94C241 encoding)
.bank_loop:
	ld	XIY, 00FE0000h		; Boot ROM base
	ld	XIZ, 0			; Word counter
.word_loop:
	ld	C, W
	extz	BC
	add	BC, BC			; Bank offset
	lda	XDE, XIX+BC
	ld	BC, (XDE)		; Get current sum
	ld	QWA, BC
	ld	BC, (XIY+)		; Read word from ROM
	add	BC, QWA			; Add to sum
	ld	(XDE), BC		; Store result
	inc	1, XIZ
	cp	XIZ, 00000800h
	jr	C, .word_loop
	inc	1, W
	cp	W, 2
	jr	C, .bank_loop
	; Compare checksums
	ld	BC, (XHL)
	cp	BC, (XIX)
	jr	Z, .match
	set	2, A			; Mismatch error
.match:
	ld	L, A
	extz	HL
	pop	XIZ
	inc	4, XSP
	ret

; ==============================================================================
; SERIAL_INIT (0xFF8B07) - Initialize serial communication
; Checks status bytes and sets interrupt flag accordingly
; ==============================================================================

	org	0FF8B07h

SERIAL_INIT:
	push	QIZ
	ld	QIZH, 0			; Error accumulator
	calr	CONTROL_PANEL_BIT_SET_CLEAR		; Initialize serial subsystem
	lda	XWA, SERIAL_STATUS
	ld	XBC, XWA
	lda	XDE, XWA+8
.check_loop:
	ld	A, QIZH
	or	A, (XBC+)		; OR all status bytes
	ld	QIZH, A
	cp	XBC, XDE
	jr	C, .check_loop
	cp	QIZH, 0
	jr	Z, .no_error
	res	1, (INTTC01)		; Disable timer interrupt on error
	jr	.done
.no_error:
	set	1, (INTTC01)		; Enable timer interrupt
.done:
	pop	QIZ
	ret

; ==============================================================================
; CONTROL_PANEL_BIT_SET_CLEAR (0xFF8B37) - LED/Output bit manipulation routine
;
; This routine sets or clears bits in an output buffer based on input parameters.
; Parameters are passed on stack:
;   (SP+0): Button/LED index (0x24-based offset)
;   (SP+1): Action (0 = clear bit, non-zero = set bit)
;
; The routine calculates:
;   - Byte offset = (index - 0x24) >> 3 (which byte in buffer)
;   - Bit position = (index - 0x24) & 7 (which bit in byte)
;   - Buffer base = 0x0558
;
; Uses INTER_CPU_LATCH_READ_DISPATCH to send/receive data to hardware.
; ==============================================================================

	org	0FF8B37h

CONTROL_PANEL_BIT_SET_CLEAR:
	dec	2, XSP			; Reserve 2 bytes on stack for local vars
	lda	XWA, XSP		; XWA = pointer to stack frame
	calr	INTER_CPU_LATCH_READ_DISPATCH		; Call to get/send data
	cp	HL, 0FFFFh		; Check return value
	jr	Z, .done		; If -1 (error), skip to done

.loop:
	lda	XBC, XSP		; XBC = pointer to parameters
	db	81h, 25h		; ld E, (XBC) - Load LED/button index
	sub	E, 24h			; E = index - 0x24 (normalize to 0-based)
	ld	L, E			; L = normalized index
	srl	3, L			; L = index >> 3 (byte offset)
	and	L, 07h			; L = byte offset (mask to 0-7)
	and	E, 07h			; E = bit position (index & 7)
	ld	A, E			; A = bit position
	ld	E, L			; E = byte offset
	extz	DE			; Zero-extend DE (byte offset in DE)
	lda	XIX, 0558h		; XIX = buffer base address
	ld	HL, 1			; HL = initial bit mask (1)
	and	A, 0Fh			; Mask bit position to 0-15
	jr	Z, .skip_shift		; If A=0, skip shift (bit already = 1)
	sla	A, HL			; HL = HL << A (create bit mask)
.skip_shift:
	extz	XDE			; Zero-extend XDE (32-bit offset)
	add	XDE, XIX		; XDE = buffer base + byte offset
	cp	(XBC+1), 0		; Check action parameter
	jr	Z, .clear_bit		; If 0, clear the bit
	or	(XDE), L		; Set bit: buffer[offset] |= mask
	jr	T, .next		; Jump to next iteration (always)
.clear_bit:
	cpl	HL			; Complement mask (for AND)
	and	(XDE), L		; Clear bit: buffer[offset] &= ~mask
.next:
	ld	XWA, XBC		; XWA = parameter pointer
	calr	INTER_CPU_LATCH_READ_DISPATCH		; Call to send/get next item
	cp	HL, 0FFFFh		; Check return value
	jr	NZ, .loop		; If not -1, continue loop

.done:
	inc	2, XSP			; Release 2 bytes from stack
	ret

; ==============================================================================
; INTER_CPU_LATCH_READ_DISPATCH (0xFF8B89) - Inter-CPU communication handler
;
; Reads data from inter-CPU communication latches at 0x110000-0x110002.
; Checks status bits and dispatches to NOTE_VELOCITY_LOOKUP_CALCULATE for processing.
;
; Input: XWA = pointer to parameter buffer
; Output: HL = 0 on success, 0xFFFF on error/no data
; ==============================================================================

	org	0FF8B89h

INTER_CPU_LATCH_READ_DISPATCH:
	push	XIZ
	ld	XIZ, XWA		; Save parameter pointer in XIZ
	ld	HL, (110002h)		; Read status register
	bit	0, HL			; Check bit 0 (data available?)
	jr	Z, .error		; If not set, return error

	ld	WA, (110000h)		; Read data word from latch
	ld	B, A			; B = low byte
	and	B, 0FFh			; Mask to byte
	srl	8, WA			; WA >>= 8 (get high byte in A)
	and	A, 0FFh			; Mask to byte
	ld	C, B			; C = copy of low byte
	ld	E, A			; E = high byte
	cp	A, 0FFh			; Check if high byte is 0xFF
	jr	Z, .check_bit7		; If so, check bit 7 path
	bit	1, HL			; Check bit 1 of status
	jr	Z, .process_normal	; If not set, process normally

.check_bit7:
	bit	7, B			; Check bit 7 of low byte
	jr	NZ, .error		; If set, return error
	ld	XWA, XIZ		; Restore parameter pointer
	calr	NOTE_VELOCITY_LOOKUP_CALCULATE		; Call processing routine
	ld	(XIZ+1), 0		; Clear byte at param+1
	jr	T, .success		; Jump to success (always)

.process_normal:
	ld	XWA, XIZ		; Restore parameter pointer
	calr	NOTE_VELOCITY_LOOKUP_CALCULATE		; Call processing routine

.success:
	ld	HL, 0			; Return success
	jr	T, .done		; Jump to done (always)

.error:
	ld	HL, 0FFFFh		; Return error (-1)

.done:
	pop	XIZ
	ret

; ==============================================================================
; NOTE_VELOCITY_LOOKUP_CALCULATE (0xFF8BD2) - Note/velocity calculation routine
;
; Calculates velocity values based on note index and lookup tables.
; Uses tables at 0xFF804C, 0xFF8040, 0xFF802A, 0xFF802C, 0xFF814C.
;
; Input: XWA = pointer to output buffer
;        C = note index (low byte from latch)
;        E = velocity index (high byte from latch)
; ==============================================================================

	org	0FF8BD2h

NOTE_VELOCITY_LOOKUP_CALCULATE:
	ld	(0560h), 06h		; Set mode/flag byte
	ld	L, C			; L = note index
	res	7, L			; Clear bit 7
	add	L, 24h			; Add 0x24 offset
	ld	(XWA), L		; Store adjusted note to output[0]
	bit	7, C			; Check bit 7 of original C
	jrl	Z, .zero_velocity	; If clear, set velocity to 0

	; Calculate velocity from tables
	ld	C, E			; C = velocity index
	extz	BC			; Zero-extend BC
	lda	XDE, 0FF804Ch		; XDE = velocity curve table base
	ld	XHL, 0			; Clear XHL
	ld	L, (XDE+BC)		; L = table[velocity_index]
	ld	BC, (0FF802Ah)		; BC = parameter from table
	sub	HL, BC			; HL = L - BC
	lda	XDE, 0FF8040h		; XDE = another table
	ld	C, (XDE)		; C = table[0]
	extz	BC			; Zero-extend BC
	muls	XBC, HL			; XBC = BC * HL (signed)
	ld	HL, (0FF802Ch)		; HL = divisor from table
	exts	XBC			; Sign-extend XBC
	divs	XBC, HL			; XBC = XBC / HL (signed)
	ld	HL, BC			; HL = quotient
	ld	C, (XDE+1)		; C = table[1] (offset)
	extz	BC			; Zero-extend BC
	add	BC, HL			; BC = BC + HL
	ld	HL, BC			; HL = result
	exts	XHL			; Sign-extend XHL

	; Get note and check for special semitones
	ld	C, (XWA)		; C = adjusted note
	extz	BC			; Zero-extend BC
	DIV_C	0Ch			; C = note / 12, B = note % 12 (semitone)
	ld	C, B			; C = semitone (0-11)
	cp	C, 0Ah			; Is it A# (10)?
	jr	Z, .apply_offset
	cp	C, 08h			; Is it G# (8)?
	jr	Z, .apply_offset
	cp	C, 6			; Is it F# (6)?
	jr	Z, .apply_offset
	cp	C, 3			; Is it D# (3)?
	jr	Z, .apply_offset
	cp	C, 1			; Is it C# (1)?
	jr	NZ, .clamp_velocity	; If not a sharp, skip offset

.apply_offset:
	ld	XBC, 0			; Clear XBC
	ld	C, (XDE+2)		; C = offset for sharp notes
	sub	XHL, XBC		; XHL = XHL - offset

.clamp_velocity:
	; Clamp velocity to 0-255 range
	ld	XDE, 000000FFh		; Max velocity = 255
	cp	XHL, 000000FFh		; Compare with max
	jr	GT, .use_max		; If greater, use max
	ld	XDE, XHL		; Otherwise use calculated value
.use_max:
	ld	XBC, 0			; Min velocity = 0
	cp	XDE, 00000000h		; Compare with min
	jr	LT, .use_min		; If less, use min
	ld	XBC, XDE		; Otherwise use clamped value
.use_min:
	; Look up final velocity in curve table
	extz	BC			; Zero-extend BC (velocity 0-255)
	lda	XDE, 0FF814Ch		; XDE = final velocity curve table
	ld	C, (XDE+BC)		; C = curve[velocity]
	ld	(XWA+1), C		; Store final velocity to output[1]
	ret

.zero_velocity:
	ld	(XWA+1), 0		; Store 0 velocity to output[1]
	ret

; ==============================================================================
; AUDIO_HW_WRITE_READ (0xFF8C75) - Hardware register write helper
;
; Writes WA to address 0x100000, reads HL from 0x100004.
; ==============================================================================

	org	0FF8C75h

AUDIO_HW_WRITE_READ:
	ld	(100000h), WA		; Write WA to hardware register
	ld	HL, (100004h)		; Read status/result
	ret

; ==============================================================================
; HARDWARE_CALIBRATION_SEQUENCE (0xFF8C80) - Hardware communication/calibration routine
;
; Complex routine that communicates with hardware at 0x100000.
; Performs some kind of calibration or initialization sequence.
; Loops up to 1000 times (0x3E8) checking for hardware response.
; Returns IZ value (0 on success, 0xFFFF on timeout/error).
; ==============================================================================

	org	0FF8C80h

HARDWARE_CALIBRATION_SEQUENCE:
	push	XIZ
	ld	IZ, 0FFFFh		; Initialize error flag to -1

	; First hardware write sequence
	LD_MEM24_IMM16 100000h, 0840h	; Write 0x0840 to hardware reg
	nop
	LD_MEM24_IMM16 100002h, 0FF00h	; Write 0xFF00 to hardware reg+2
	jr	T, $+2			; Short delay (jump to next instruction)
	nop
	nop
	nop

	; Second hardware write sequence
	LD_MEM24_IMM16 100000h, 0800h	; Write 0x0800 to hardware reg
	nop
	LD_MEM24_IMM16 100002h, 0FF80h	; Write 0xFF80 to hardware reg+2
	jr	T, $+2			; Short delay
	nop
	nop
	nop

	; Call HARDWARE_PARAM_BLOCK_WRITE with parameter block at 0xFF824C
	ld	WA, 0
	ld	XBC, 00FF824Ch		; Parameter block address
	calr	HARDWARE_PARAM_BLOCK_WRITE		; Write parameters to hardware

	; Read back and verify
	ld	BC, (0FF824Ch)		; Read first word from param block
	ld	WA, 0
	calr	HARDWARE_VERIFY_WRITE		; Call verification routine

	; Check timeout counter
	cp	QIZ, 03E8h		; Compare with 1000
	jr	NC, .exit		; If >= 1000, exit (timeout)

.retry_loop:
	ld	WA, 0
	calr	AUDIO_HW_WRITE_READ		; Read hardware status
	cp	HL, 0			; Check result
	jr	Z, .success		; If 0, hardware responded

	; Hardware still busy, reset and retry
	ld	IZ, 0			; Clear error flag (will succeed)

	; Repeat first hardware write sequence
	LD_MEM24_IMM16 100000h, 0840h
	nop
	LD_MEM24_IMM16 100002h, 0FF00h
	jr	T, $+2
	nop
	nop
	nop

	; Repeat second hardware write sequence
	LD_MEM24_IMM16 100000h, 0800h
	nop
	LD_MEM24_IMM16 100002h, 0FF80h
	jr	T, $+2
	nop
	nop
	nop
	jr	T, .exit		; Exit after reset sequence

.success:
	inc	1, QIZ			; Increment retry counter
	cp	QIZ, 03E8h		; Compare with 1000
	jr	C, .retry_loop		; If < 1000, continue loop

.exit:
	ld	HL, IZ			; Return IZ as result
	pop	XIZ
	ret

; ==============================================================================
; HARDWARE_PARAM_BLOCK_WRITE (0xFF8D0A) - Audio hardware parameter write routine
;
; Writes 21 parameter pairs from memory to AUDIO_HW_BASE (0x100000).
; Each pair: address written to 0x100000, data written to 0x100002.
; Hardware offsets: 0x40, 0x80, 0xC0, 0x100, 0x140, 0x180, 0x400, 0x440,
;                   0x480, 0x4C0, 0x500, 0x800, (base), 0x840, 0x880, 0x8C0,
;                   0x900, 0x940, 0x980, 0x9C0, 0xA00, 0xA40, then 0x80 again
;
; Input: WA = base offset for hardware addresses
;        XBC = pointer to 44-byte parameter block (offsets 0x00-0x2A)
; ==============================================================================

	org	0FF8D0Ah

HARDWARE_PARAM_BLOCK_WRITE:
	dec	4, XSP			; Reserve 4 bytes on stack
	push	IZ
	ld	(XSP+2), XBC		; Save XBC to stack
	ld	IZ, WA			; IZ = base offset

	; Write parameter 0 (offset +0x40)
	ld	WA, IZ
	add	WA, 0040h
	ld	(100000h), WA		; Address = base + 0x40
	nop
	ld	XBC, (XSP+2)		; Restore XBC
	ld	WA, (XBC+2)		; Get param[2:3]
	ld	(100002h), WA		; Write data
	jr	T, $+2
	nop
	nop
	nop

	; Write parameter 1 (offset +0x80)
	ld	WA, IZ
	add	WA, 0080h
	ld	(100000h), WA
	nop
	ld	WA, (XBC+4)		; Get param[4:5]
	set	15, WA			; Set bit 15
	ld	(100002h), WA
	jr	T, $+2
	nop
	nop
	nop

	; Write parameter 2 (offset +0xC0)
	ld	WA, IZ
	add	WA, 00C0h
	ld	(100000h), WA
	nop
	ld	WA, (XBC+6)		; Get param[6:7]
	ld	(100002h), WA
	jr	T, $+2
	nop
	nop
	nop

	; Write parameter 3 (offset +0x100)
	ld	WA, IZ
	add	WA, 0100h
	ld	(100000h), WA
	nop
	ld	WA, (XBC+8)		; Get param[8:9]
	ld	(100002h), WA
	jr	T, $+2
	nop
	nop
	nop

	; Write parameter 4 (offset +0x140)
	ld	WA, IZ
	add	WA, 0140h
	ld	(100000h), WA
	nop
	ld	WA, (XBC+0Ah)		; Get param[10:11]
	ld	(100002h), WA
	jr	T, $+2
	nop
	nop
	nop

	; Write parameter 5 (offset +0x180)
	ld	WA, IZ
	add	WA, 0180h
	ld	(100000h), WA
	nop
	ld	WA, (XBC+0Ch)		; Get param[12:13]
	ld	(100002h), WA
	jr	T, $+2
	nop
	nop
	nop

	; Write parameter 6 (offset +0x400)
	ld	WA, IZ
	add	WA, 0400h
	ld	(100000h), WA
	nop
	ld	WA, (XBC+0Eh)		; Get param[14:15]
	ld	(100002h), WA
	jr	T, $+2
	nop
	nop
	nop

	; Write parameter 7 (offset +0x440)
	ld	WA, IZ
	add	WA, 0440h
	ld	(100000h), WA
	nop
	ld	WA, (XBC+10h)		; Get param[16:17]
	ld	(100002h), WA
	jr	T, $+2
	nop
	nop
	nop

	; Write parameter 8 (offset +0x480)
	ld	WA, IZ
	add	WA, 0480h
	ld	(100000h), WA
	nop
	ld	WA, (XBC+12h)		; Get param[18:19]
	ld	(100002h), WA
	jr	T, $+2
	nop
	nop
	nop

	; Write parameter 9 (offset +0x4C0)
	ld	WA, IZ
	add	WA, 04C0h
	ld	(100000h), WA
	nop
	ld	WA, (XBC+14h)		; Get param[20:21]
	ld	(100002h), WA
	jr	T, $+2
	nop
	nop
	nop

	; Write parameter 10 (offset +0x500)
	ld	WA, IZ
	add	WA, 0500h
	ld	(100000h), WA
	nop
	ld	WA, (XBC+16h)		; Get param[22:23]
	ld	(100002h), WA
	jr	T, $+2
	nop
	nop
	nop

	; Write parameter 11 (offset +0x800)
	ld	WA, IZ
	add	WA, 0800h
	ld	(100000h), WA
	nop
	ld	WA, (XBC+18h)		; Get param[24:25]
	ld	(100002h), WA
	jr	T, $+2
	nop
	nop
	nop

	; Write IZ directly with constant 0x8100
	ld	(100000h), IZ		; Write base offset
	nop
	LD_MEM24_IMM16 100002h, 8100h	; Write 0x8100
	jr	T, $+2
	nop
	nop
	nop

	; Write parameter 12 (offset +0x840)
	ld	WA, IZ
	add	WA, 0840h
	ld	(100000h), WA
	nop
	ld	WA, (XBC+1Ah)		; Get param[26:27]
	ld	(100002h), WA
	jr	T, $+2
	nop
	nop
	nop

	; Write parameter 13 (offset +0x880)
	ld	WA, IZ
	add	WA, 0880h
	ld	(100000h), WA
	nop
	ld	WA, (XBC+1Ch)		; Get param[28:29]
	ld	(100002h), WA
	jr	T, $+2
	nop
	nop
	nop

	; Write parameter 14 (offset +0x8C0)
	ld	WA, IZ
	add	WA, 08C0h
	ld	(100000h), WA
	nop
	ld	WA, (XBC+1Eh)		; Get param[30:31]
	ld	(100002h), WA
	jr	T, $+2
	nop
	nop
	nop

	; Write parameter 15 (offset +0x900)
	ld	WA, IZ
	add	WA, 0900h
	ld	(100000h), WA
	nop
	ld	WA, (XBC+20h)		; Get param[32:33]
	ld	(100002h), WA
	jr	T, $+2
	nop
	nop
	nop

	; Write parameter 16 (offset +0x940)
	ld	WA, IZ
	add	WA, 0940h
	ld	(100000h), WA
	nop
	ld	WA, (XBC+22h)		; Get param[34:35]
	ld	(100002h), WA
	jr	T, $+2
	nop
	nop
	nop

	; Write parameter 17 (offset +0x980)
	ld	WA, IZ
	add	WA, 0980h
	ld	(100000h), WA
	nop
	ld	WA, (XBC+24h)		; Get param[36:37]
	ld	(100002h), WA
	jr	T, $+2
	nop
	nop
	nop

	; Write parameter 18 (offset +0x9C0)
	ld	WA, IZ
	add	WA, 09C0h
	ld	(100000h), WA
	nop
	ld	WA, (XBC+26h)		; Get param[38:39]
	ld	(100002h), WA
	jr	T, $+2
	nop
	nop
	nop

	; Write parameter 19 (offset +0xA00)
	ld	WA, IZ
	add	WA, 0A00h
	ld	(100000h), WA
	nop
	ld	WA, (XBC+28h)		; Get param[40:41]
	ld	(100002h), WA
	jr	T, $+2
	nop
	nop
	nop

	; Write parameter 20 (offset +0xA40)
	ld	WA, IZ
	add	WA, 0A40h
	ld	(100000h), WA
	nop
	ld	WA, (XBC+2Ah)		; Get param[42:43]
	ld	(100002h), WA
	jr	T, $+2
	nop
	nop
	nop

	; Final write - parameter 1 again with bit 15 cleared (offset +0x80)
	ld	WA, IZ
	add	WA, 0080h
	ld	(100000h), WA
	nop
	ld	WA, (XBC+4)		; Get param[4:5] again
	res	15, WA			; Clear bit 15 (was set earlier)
	ld	(100002h), WA
	jr	T, $+2
	nop
	nop
	nop

	pop	IZ
	inc	4, XSP			; Release 4 bytes from stack
	ret

; ==============================================================================
; HARDWARE_VERIFY_WRITE (0xFF8F57) - Hardware write routine
;
; Writes WA to 0x100000, then IZ (from BC) to 0x100002.
; Simple write with timing delays (nops and jr T).
;
; Input: WA = value to write to 0x100000
;        BC = value to write to 0x100002
; ==============================================================================

	org	0FF8F57h

HARDWARE_VERIFY_WRITE:
	push	IZ
	ld	IZ, BC			; Save BC in IZ
	ld	(100000h), WA		; Write address/command
	nop
	ld	(100002h), IZ		; Write data from IZ
	jr	T, $+2			; Short delay
	nop
	nop
	nop
	pop	IZ
	ret

; ==============================================================================
; Vector Trampoline Data (0xFF8F6C)
; This data gets copied to RAM at 0x0400 during boot.
; Each entry is: JP addr (4 bytes) + RET (1 byte) = 5 bytes per handler
; Total: 45 handlers x 5 bytes = 225 (0xE1) bytes
; ==============================================================================

	org	0FF8F6Ch

VECTOR_TRAMPOLINES:
	; Handler 0 - Reset/Main entry
	jp	0FFFEE0h		; Jump to ROM reset handler
	ret
	; Handler 1
	jp	DEFAULT_HANDLER
	ret
	; Handler 2
	jp	DEFAULT_HANDLER
	ret
	; Handler 3
	jp	DEFAULT_HANDLER
	ret
	; Handler 4
	jp	DEFAULT_HANDLER
	ret
	; Handler 5
	jp	DEFAULT_HANDLER
	ret
	; Handler 6
	jp	DEFAULT_HANDLER
	ret
	; Handler 7
	jp	DEFAULT_HANDLER
	ret
	; Handler 8 - Uses RESET_ENTRY (software reset)
	jp	RESET_ENTRY
	ret
	; Handler 9 - Serial Receive Interrupt (inter-CPU communication)
	jp	InterCPU_RX_Handler
	ret
	; Handlers 10-35: Default (26 handlers)
	rept	26
	jp	DEFAULT_HANDLER
	ret
	endm
	; Handler 36 - Timer/Processing Interrupt (main work handler)
	jp	CMD_Dispatch_Handler		; Note: Handler 36 uses CMD_Dispatch_Handler code
	ret
	; Handler 37 - Default
	jp	DEFAULT_HANDLER
	ret
	; Handler 38 - DMA Complete Interrupt
	jp	DMA_Complete_Handler		; Note: Handler 38 uses DMA_Complete_Handler code
	ret
	; Handlers 39-43: Default (5 handlers)
	rept	5
	jp	DEFAULT_HANDLER
	ret
	endm
	; Handler 44 - Error/Halt handler
	jp	HALT_LOOP
	ret

; ==============================================================================
; Debug/Utility Routines (0xFFFE80 - 0xFFFED1)
;
; These appear to be debug or diagnostic routines, possibly for serial output.
; DEBUG_OUTPUT_BYTE_HEX: Wrapper that calls SUB_FEC1
; HEX_BYTE_TO_ASCII: Output hex byte (calls NIBBLE_TO_HEX_ASCII for nibble conversion, SUB_FEC1 for output)
; DEBUG_OUTPUT_STRING: Output null-terminated string from (XIX)
; NIBBLE_TO_HEX_ASCII: Convert nibble (0-15) to ASCII hex character ('0'-'9', 'a'-'f')
; SUB_FEC1: Output character (loads IZ with 0xFE00, placeholder NOPs)
; ==============================================================================

	org	0FFFE80h

DEBUG_OUTPUT_BYTE_HEX:
	push	XIZ
	calr	SUB_FEC1
	pop	XIZ
	ret

HEX_BYTE_TO_ASCII:
	push	XIZ
	ld	W, A			; Save A in W
	srl	4, A			; A >>= 4 (high nibble)
	calr	NIBBLE_TO_HEX_ASCII		; Convert to hex char
	push	WA
	calr	SUB_FEC1		; Output character
	pop	WA
	ld	A, W			; Restore original A
	and	A, 0Fh			; Mask low nibble
	calr	NIBBLE_TO_HEX_ASCII		; Convert to hex char
	calr	SUB_FEC1		; Output character
	pop	XIZ
	ret

DEBUG_OUTPUT_STRING:
	push	XIZ
	ld	XIX, XWA		; XIX = string pointer
.loop:
	ld	A, (XIX+)		; Load next char, increment
	cp	A, 0			; Check for null terminator
	jr	Z, .done		; If null, exit
	push	XIX
	calr	SUB_FEC1		; Output character
	pop	XIX
	jr	T, .loop		; Continue loop
.done:
	pop	XIZ
	ret

NIBBLE_TO_HEX_ASCII:
	cp	A, 0Ah			; Compare with 10
	jr	NC, .letter		; If >= 10, use letter
	add	A, 30h			; '0' = 0x30
	ret
.letter:
	add	A, 57h			; 'a' - 10 = 0x57
	ret

SUB_FEC1:
	ld	IZ, 0FE00h		; Output port address (placeholder)
	nop				; Timing/placeholder
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
	ret

; ==============================================================================
; Reserved area (0xFFFED2 - 0xFFFEDF)
; ==============================================================================

	org	0FFFED2h

	db	0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh	; 0xFFFED2-0xFFFED9
	db	0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh			; 0xFFFEDA-0xFFFEDF

; ==============================================================================
; Reset Handler (0xFFFEE0)
; This is the actual reset entry point, called from vector table
; ==============================================================================

	org	0FFFEE0h

RESET_HANDLER:
	jp	BOOT_INIT		; Jump to main boot initialization
	ret				; Never reached

; ==============================================================================
; Reserved area (0xFFFEE5 - 0xFFFEEF)
; ==============================================================================

	org	0FFFEE5h

	db	0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh	; 0xFFFEE5-0xFFFEED
	db	00h, 00h			; 0xFFFEEE-0xFFFEEF

; ==============================================================================
; Reserved data area (0xFFFEF0 - 0xFFFEFF)
; Appears to be some kind of configuration or padding data
; ==============================================================================

	org	0FFFEF0h

	db	00h, 04h, 00h, 00h	; 0xFFFEF0-0xFFFEF3
	db	00h, 04h, 00h, 00h	; 0xFFFEF4-0xFFFEF7
	db	00h, 04h, 00h, 00h	; 0xFFFEF8-0xFFFEFB
	db	00h, 04h, 00h, 00h	; 0xFFFEFC-0xFFFEFF

; ==============================================================================
; Interrupt Vector Table (0xFFFF00 - 0xFFFFFF)
; 4-byte entries pointing to handlers in RAM at 0x04xx
; These addresses point to the trampolines copied to RAM
; ==============================================================================

	org	0FFFF00h

VECTOR_TABLE:
	dd	00FFFEe0h		; Reset - points to ROM handler at 0xFFFEE0
	dd	00000405h		; Handler 1 at 0x0405
	dd	0000040Ah		; Handler 2 at 0x040A
	dd	0000040Fh		; Handler 3 at 0x040F
	dd	00000414h		; Handler 4 at 0x0414
	dd	00000419h		; Handler 5 at 0x0419
	dd	0000041Eh		; Handler 6 at 0x041E
	dd	00000423h		; Handler 7 at 0x0423
	dd	000004DCh		; Handler 8 at 0x04DC (different!)
	dd	00000428h		; Handler 9 at 0x0428
	dd	0000042Dh		; Handler 10
	dd	00000432h		; Handler 11
	dd	00000437h		; Handler 12
	dd	0000043Ch		; Handler 13
	dd	00000441h		; Handler 14
	dd	00000446h		; Handler 15
	dd	0000044Bh		; Handler 16
	dd	00000450h		; Handler 17
	dd	00000455h		; Handler 18
	dd	0000045Ah		; Handler 19
	dd	0000045Fh		; Handler 20
	dd	00000464h		; Handler 21
	dd	00000469h		; Handler 22
	dd	0000046Eh		; Handler 23
	dd	00000473h		; Handler 24
	dd	00000478h		; Handler 25
	dd	0000047Dh		; Handler 26
	dd	00000482h		; Handler 27
	dd	00000487h		; Handler 28
	dd	0000048Ch		; Handler 29
	dd	00000491h		; Handler 30
	dd	00000496h		; Handler 31
	dd	0000049Bh		; Handler 32
	dd	000004A0h		; Handler 33
	dd	000004A5h		; Handler 34
	dd	000004AAh		; Handler 35
	dd	000004AFh		; Handler 36
	dd	000004B4h		; Handler 37
	dd	000004B9h		; Handler 38
	dd	000004BEh		; Handler 39
	dd	000004C3h		; Handler 40
	dd	000004C8h		; Handler 41
	dd	000004CDh		; Handler 42
	dd	000004D2h		; Handler 43
	dd	000004D7h		; Handler 44
	; Fill rest with FF
	db	0FFh, 0FFh, 0FFh, 0FFh
	db	0FFh, 0FFh, 0FFh, 0FFh
	db	0FFh, 0FFh, 0FFh, 0FFh

	org	0FFFFF0h

RESET_VECTORS:
	; TMP94C241 reserved area (0xFFFFF0-0xFFFFFF)
	; Per datasheet: "Do not use" / reserved for system configuration
	; Pattern 41 B1 62 1B repeated 4 times - may be factory calibration data
	; or ROM identification/checksum (not part of interrupt vector table)
	db	41h, 0B1h, 62h, 1Bh
	db	41h, 0B1h, 62h, 1Bh
	db	41h, 0B1h, 62h, 1Bh
	db	41h, 0B1h, 62h, 1Bh

	end
