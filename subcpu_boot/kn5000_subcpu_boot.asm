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
	include	"../tmp94c241.inc"

; ==============================================================================
; Constants
; ==============================================================================

PAYLOAD_ENTRY		EQU	0400h	; Entry point of loaded payload
STACK_INIT		EQU	05A2h	; Initial stack pointer
INTER_CPU_LATCH		EQU	120000h	; Inter-CPU communication latch
TONE_GEN_BASE		EQU	130000h	; Tone generator base address

; SFR addresses (directly addressable 0x00-0xFF)
P0FC			EQU	07h	; Port 0 Function Control
P1FC			EQU	0Bh	; Port 1 Function Control
P2FC			EQU	0Fh	; Port 2 Function Control
P7			EQU	1Ch	; Port 7 Data
P7CR			EQU	1Eh	; Port 7 Control
P7FC			EQU	1Fh	; Port 7 Function Control
P8			EQU	20h	; Port 8 Data
P8CR			EQU	22h	; Port 8 Control
P8FC			EQU	23h	; Port 8 Function Control
PA			EQU	28h	; Port A Data
PAFC			EQU	2Bh	; Port A Function Control
PB			EQU	2Ch	; Port B Data
PBFC			EQU	2Fh	; Port B Function Control
INTTC01			EQU	30h	; Interrupt control (Timer 0/1)
SC0BUF			EQU	34h	; Serial Channel 0 Buffer
SC0CR			EQU	36h	; Serial Channel 0 Control
SC0MOD			EQU	38h	; Serial Channel 0 Mode
SC1BUF			EQU	3Ah	; Serial Channel 1 Buffer
SC1CR			EQU	3Ch	; Serial Channel 1 Control
SC1MOD			EQU	3Eh	; Serial Channel 1 Mode
REG_40			EQU	40h
REG_44			EQU	44h
REG_46			EQU	46h
REG_47			EQU	47h
REG_68			EQU	68h
REG_6A			EQU	6Ah
WDMOD			EQU	80h	; Watchdog Mode
WDCR			EQU	81h	; Watchdog Control
REG_82			EQU	82h
REG_84			EQU	84h
REG_85			EQU	85h
REG_88			EQU	88h
REG_89			EQU	89h
REG_8A			EQU	8Ah
REG_8B			EQU	8Bh
REG_98			EQU	98h
REG_99			EQU	99h
REG_9E			EQU	9Eh
REG_9F			EQU	9Fh
REG_D1			EQU	0D1h
REG_D2			EQU	0D2h
REG_D3			EQU	0D3h
REG_D5			EQU	0D5h
REG_D6			EQU	0D6h
REG_D7			EQU	0D7h
REG_E5			EQU	0E5h
REG_EC			EQU	0ECh
REG_ED			EQU	0EDh
REG_F0			EQU	0F0h
REG_F6			EQU	0F6h

; Extended SFR (0x0100+)
REG_010A		EQU	010Ah
REG_0110		EQU	0110h
REG_0111		EQU	0111h
REG_0140		EQU	0140h
REG_0141		EQU	0141h
REG_0142		EQU	0142h
REG_0143		EQU	0143h
REG_0144		EQU	0144h
REG_0145		EQU	0145h
REG_0146		EQU	0146h
REG_0147		EQU	0147h
REG_0148		EQU	0148h
REG_0149		EQU	0149h
REG_014A		EQU	014Ah
REG_014B		EQU	014Bh
REG_014C		EQU	014Ch
REG_014D		EQU	014Dh
REG_014E		EQU	014Eh
REG_014F		EQU	014Fh
REG_0150		EQU	0150h
REG_0151		EQU	0151h
REG_0152		EQU	0152h
REG_0153		EQU	0153h
REG_0154		EQU	0154h
REG_0155		EQU	0155h
REG_0156		EQU	0156h
REG_0157		EQU	0157h
REG_0162		EQU	0162h	; DRAM refresh
REG_0163		EQU	0163h
REG_0165		EQU	0165h
REG_0166		EQU	0166h

; RAM variables - Communication and State
SUBCPU_STATUS_FLAGS	EQU	04FEh	; Status flags (bit 6=payload ready, bit 7=xfer complete)
DMA_TARGET_ADDR		EQU	0512h	; Current DMA destination address (4 bytes)
DMA_STATE		EQU	0516h	; DMA state machine (0=idle, 1=pending, 2=in progress)
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
	ld	(REG_0110), 00h
	ld	(REG_0111), 0B1h
	ld	(REG_010A), 04h

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
	ld	(REG_44), 0FFh
	ld	(REG_47), 18h
	ld	(REG_46), 07h
	ld	(REG_68), 00h
	ld	(REG_6A), 0FFh
	ld	(REG_84), 1Dh
	ld	(REG_85), 1Dh
	ld	(REG_82), 00h
	ld	(REG_88), 0Ah
	ld	(REG_89), 10h
	ld	(REG_8A), 40h
	ld	(REG_8B), 20h
	ld	(WDCR), 00h		; Watchdog control
	set	1, (WDMOD)		; Watchdog mode
	ld	(REG_98), 05h
	ld	(REG_99), 00h
	ld	(REG_9F), 00h
	ld	(REG_9E), 00h
	set	7, (REG_9E)

	; Initialize timer registers
	ld	(REG_0143), 10h
	ld	(REG_0147), 11h
	ld	(REG_014B), 0FFh
	ld	(REG_014F), 00h
	ld	(REG_0153), 12h
	ld	(REG_0157), 13h
	ld	(REG_0142), 07h
	ld	(REG_0146), 03h
	ld	(REG_014A), 01h

	; Check bit 0 of register 0x40 for clock configuration
	bit	0, (REG_40)
	jr	NZ, .clock_alt
	ld	(REG_014E), 1Fh
	jr	.clock_done
.clock_alt:
	ld	(REG_014E), 0Fh
.clock_done:
	ld	(REG_0152), 01h
	ld	(REG_0156), 01h

	; Initialize serial/DMA registers
	ld	(REG_D2), 01h
	ld	(REG_D1), 00h
	and	(REG_D3), 0CFh
	and	(REG_D3), 0F0h
	ld	(REG_D6), 29h
	lda	XBC, REG_D6
	ld	A, (XBC)
	and	A, 0FCh
	set	0, A
	ld	(XBC), A
	ld	(REG_D5), 00h
	and	(REG_D7), 0CFh
	and	(REG_D7), 0F0h

	; Initialize DRAM refresh
	ld	(REG_0165), 71h
	ld	(REG_0162), 8Bh
	ld	(REG_0163), 58h
	res	4, (REG_0166)

	; More timer configuration
	ld	(REG_0140), 66h
	ld	(REG_0144), 66h
	ld	(REG_0148), 22h
	ld	(REG_014C), 22h
	ld	(REG_0150), 66h
	ld	(REG_0154), 66h
	ld	(REG_0141), 81h
	ld	(REG_0145), 81h
	ld	(REG_0149), 0C0h

	; Check clock config again
	bit	0, (REG_40)
	jr	NZ, .clock_alt2
	ld	(REG_014D), 8Ah
	jr	.clock_done2
.clock_alt2:
	ld	(REG_014D), 89h
.clock_done2:
	ld	(REG_0151), 80h
	ld	(REG_0155), 81h
	ld	(REG_F6), 00h

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
; SUB_8437 (0xFF8437) - Initialize tone generator channels
; Loops through 4 channels and calls TONE_GEN_WRITE for each
; ==============================================================================

SUB_8437:
	push	QIZ			; Save QIZ (used as loop variable)
	db	0d2h, 0eeh, 0feh, 0ffh, 03fh, 0ffh, 0ffh	; cp (0xFFFEEE), 0xFFFF
	jr	NZ, .done		; Skip if memory not 0xFFFF
	db	0c7h, 0fbh, 0a8h	; Clear loop counter (special reg at 0xFB)
.loop:
	db	0c7h, 0fbh, 089h	; Load A from special reg
	extz	WA			; Zero-extend A to WA
	db	0c7h, 0fbh, 08bh	; Load C from special reg
	extz	BC			; Zero-extend C to BC
	db	0d9h, 0ech, 002h	; sla 2, BC (shift left by 2 = multiply by 4)
	db	0f2h, 0f0h, 0feh, 0ffh, 032h	; lda XDE, 0xFFFEF0
	db	0e3h, 007h, 0e8h, 0e4h, 021h	; ld XBC, (XDE+BC)
	call	TONE_GEN_WRITE		; Write to tone generator
	db	0c7h, 0fbh, 061h	; Increment loop counter
	db	0c7h, 0fbh, 0dch	; Compare counter with 4
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

STUB_8496:
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
; SUB_850E (0xFF850E) - Push registers and call SUB_853A multiple times
; Appears to write multiple register pairs to tone generator
; ==============================================================================

SUB_850E:
	push	XBC
	push	XDE
	PUSH_WORD 1			; Push channel 1
	CALR	SUB_853A
	db	0afh, 00ah, 021h	; ld XBC, (XSP+0x0A)
	db	0eeh, 08ah		; ld XDE, XIZ
	PUSH_WORD 0			; Push channel 0
	CALR	SUB_853A
	ld	XBC, XWA
	ld	XDE, XHL
	PUSH_WORD 2			; Push channel 2
	CALR	SUB_853A
	ld	XBC, XIX
	ld	XDE, XIY
	PUSH_WORD 3			; Push channel 3
	CALR	SUB_853A
	db	0efh, 060h		; inc 0, XSP (adjust stack)
	pop	XDE
	pop	XBC
	ret

; ==============================================================================
; SUB_853A (0xFF853A) - Write register pair to tone generator channel
; ==============================================================================

SUB_853A:
	push	XIY
	push	WA
	push	BC
	db	08fh, 00ch, 021h	; ld A, (XSP+0x0C) - get channel from stack
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
	db	0d7h, 0e6h, 089h	; ld BC, QBC (high word of XBC)
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
	db	0d7h, 0eah, 089h	; ld BC, QDE (high word of XDE)
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
	db	095h, 011h		; ldirw (word block copy)
	ret

; ==============================================================================
; FILL_WORDS (0xFF8594) - Fill memory at XWA with BC, count in DE
; ==============================================================================

FILL_WORDS:
	db	0f5h, 0e1h, 051h	; ld (XWA+), BC
	db	0dah, 01ch, 0fah	; djnz DE, FILL_WORDS
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
	db	0e5h, 0e2h, 083h	; add XHL, (XWA+)
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
; INIT_DMA_SERIAL (0xFF85AE) - Initialize DMA and serial for inter-CPU comm
; ==============================================================================

INIT_DMA_SERIAL:
	and	(REG_E5), 0F8h		; Clear E5 bits
	res	2, (WDMOD)		; Watchdog mode
	lda	XBC, REG_EC
	ld	A, (XBC)
	and	A, 0F8h
	or	A, 05h
	ld	(XBC), A
	lda	XBC, REG_ED
	ld	A, (XBC)
	and	A, 0F8h
	or	A, 05h
	ld	(XBC), A
	lda	XBC, REG_F0
	ld	A, (XBC)
	and	A, 0F8h
	set	0, A
	ld	(XBC), A
	ld	(REG_8A), 0Ah

	; Set up DMA for inter-CPU latch at 0x120000
	lda	XWA, INTER_CPU_LATCH
	LDC_DMAD2_XWA			; DMA channel 2 destination = 0x120000
	ld	A, 08h
	LDC_DMAC2_A			; DMA channel 2 count = 8
	lda	XWA, INTER_CPU_LATCH
	LDC_DMAS0_XWA			; DMA channel 0 source = 0x120000
	LD_A	0			; TMP94C241 encoding (21 00)
	LDC_DMAC0_A			; DMA channel 0 mode = 0

	; Clear variables
	ld	(DMA_STATE), 00h
	ld	(CMD_PROCESSING_STATE), 00h
	ret

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
	call	MEM_TEST_ROUTINE	; 0xFF89FC
	ld	(MEMTEST_RESULT), L
	extz	HL
	ld	WA, HL
	call	ROM_CHECKSUM		; 0xFF8AB4
	ld	(MEMTEST_RESULT), L
	call	SUB_8C80		; 0xFF8C80
	cp	HL, 0FFFFh
	jr	NZ, .no_error
	set	3, (MEMTEST_RESULT)
.no_error:
	ld	A, (MEMTEST_RESULT)
	extz	WA
	call	DELAY_ROUTINE		; 0xFF89A9

	; Clear serial buffer area
	ld	(110002h), 0003h
	lda	XBC, SERIAL_STATUS
	ld	XWA, XBC
	INC_0_XBC			; Increment XBC by 1
.clear_loop:
	ld	(XWA+), 00h
	cp	XWA, XBC
	jr	C, .clear_loop

.serial_loop:
	call	SERIAL_INIT		; 0xFF8B07
	jr	.serial_loop		; Loop calling serial init forever

; ==============================================================================
; Interrupt Handler 9 (0xFF881F) - Serial Receive Interrupt
; Handles commands from main CPU via inter-CPU latch at 0x120000
; Commands: E1=DMA 6 bytes, E2=DMA 10 bytes, E3=Set payload ready flag
; ==============================================================================

	org	0FF881Fh

INT_HANDLER_9:
	push	XWA
	bit	2, (SC0BUF)		; Check serial status
	jr	NZ, .exit
	ld	A, (INTER_CPU_LATCH)	; Read command from main CPU
	ld	(LAST_CMD_BYTE), A		; Save received byte
	cp	A, 0E1h			; Command E1?
	jr	NZ, .not_e1
	; E1: Set up DMA for 6 bytes
	ld	(CMD_PROCESSING_STATE), 02h
	lda	XWA, 0544h
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
	lda	XWA, 054Ah
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
	lda	XWA, 051Eh
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
; Interrupt Handler 37 (0xFF889A) - DMA Complete Interrupt
; Updates state machine variable DMA_STATE
; ==============================================================================

	org	0FF889Ah

INT_HANDLER_37:
	res	2, (WDMOD)		; Clear watchdog bit
	cp	(DMA_STATE), 01h		; State 1?
	jr	NZ, .not_state1
	ld	(DMA_STATE), 00h		; -> State 0
	jr	.done
.not_state1:
	cp	(DMA_STATE), 02h		; State 2?
	jr	NZ, .done
	ld	(DMA_STATE), 01h		; -> State 1
.done:
	reti

; ==============================================================================
; Interrupt Handler 35 (0xFF88B8) - Timer/Processing Interrupt
; Main processing handler, dispatches based on CMD_PROCESSING_STATE state
; ==============================================================================

	org	0FF88B8h

INT_HANDLER_35:
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
	PUSH_WORD 051Eh
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
	lda	XWA, 0544h
	ld	XBC, (XWA)
	LDC_DMAD0_XBC			; DMA channel 0 destination (from XBC)
	ld	WA, (XWA+4)
	LDC_DMAC0_WA			; DMA channel 0 count
	ld	(0100h), 0Ah		; Trigger DMA
	ld	(CMD_PROCESSING_STATE), 04h		; -> State 4
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

; ==============================================================================
; DELAY_ROUTINE (0xFF89A9) - Variable delay based on bit pattern in A
; Uses nested loops with timer register 0x30
; ==============================================================================

	org	0FF89A9h

DELAY_ROUTINE:
	ld	L, 00h
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
	ld	E, 00h
.inner_loop:
	inc	1, E
	cp	E, 20h
	jr	C, .inner_loop
	djnz	BC, .delay_loop
.next_bit:
	set	1, (INTTC01)
	ld	BC, 4000h
.delay2_outer:
	ld	E, 00h
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
	muls	WA, 000Ah		; Each entry is 10 bytes
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
	ld	(XIX), 0000h		; Checksum accumulator 1
	lda	XHL, XIX+2
	ld	(XHL), 0000h		; Checksum accumulator 2
	ld	W, 00h			; Bank counter
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
	calr	SUB_8B37		; Initialize serial subsystem
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
; SUB_8B37 (0xFF8B37) - Serial subsystem helper
; ==============================================================================

	org	0FF8B37h

SUB_8B37:
	dec	2, XSP
	lda	XWA, XSP
	calr	SUB_8B89
	cp	HL, 0FFFFh
	jr	Z, .done
	lda	XBC, XSP
	ld	E, (XBC)
	; ... continues with more initialization
.done:
	; Stub - full routine TBD
	ret

; ==============================================================================
; SUB_8B89 (0xFF8B89) - Serial subsystem helper 2
; ==============================================================================

	org	0FF8B89h

SUB_8B89:
	; Stub - TBD
	ret

; ==============================================================================
; SUB_8C80 (0xFF8C80) - Additional initialization
; Returns 0xFFFF on error
; ==============================================================================

	org	0FF8C80h

SUB_8C80:
	; Stub - TBD
	ld	HL, 0
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
	jp	INT_HANDLER_9
	ret
	; Handlers 10-34: Default (25 handlers)
	rept	25
	jp	DEFAULT_HANDLER
	ret
	endm
	; Handler 35 - Timer/Processing Interrupt (main work handler)
	jp	INT_HANDLER_35
	ret
	; Handler 36 - Default
	jp	DEFAULT_HANDLER
	ret
	; Handler 37 - DMA Complete Interrupt
	jp	INT_HANDLER_37
	ret
	; Handlers 38-43: Default (6 handlers)
	rept	6
	jp	DEFAULT_HANDLER
	ret
	endm
	; Handler 44 - Error/Halt handler
	jp	HALT_LOOP
	ret

; ==============================================================================
; Reset Handler (0xFFFEE0)
; This is the actual reset entry point, called from vector table
; ==============================================================================

	org	0FFFEE0h

RESET_HANDLER:
	jp	BOOT_INIT		; Jump to main boot initialization
	ret				; Never reached

; ==============================================================================
; Interrupt Vector Table (0xFFFF00 - 0xFFFFFF)
; 4-byte entries pointing to handlers in RAM at 0x04xx
; These addresses point to the trampolines copied to RAM
; ==============================================================================

	org	0FFFF00h

VECTOR_TABLE:
	dd	0000FEE0h		; Reset - points to ROM handler
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
	; Reset vector area - these bytes form a specific pattern
	; 41 B1 62 1B repeated 4 times
	; Analysis: Could be checksum or configuration data
	db	41h, 0B1h, 62h, 1Bh
	db	41h, 0B1h, 62h, 1Bh
	db	41h, 0B1h, 62h, 1Bh
	db	41h, 0B1h, 62h, 1Bh

	end
