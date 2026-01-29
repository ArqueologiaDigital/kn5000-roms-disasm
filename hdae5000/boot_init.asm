; ============================================================================
; HDAE5000 BOOT INITIALIZATION ROUTINE
; Address: 0x28F576 - 0x28F661 (236 bytes)
;
; Called once at startup when main CPU validates HDAE5000 presence.
; This routine:
;   1. Stores the workspace pointer passed from main CPU
;   2. Initializes the HDAE5000 code section
;   3. Copies data to DRAM work areas at 0x1A0000 and 0x1A9600
;   4. Registers HDAE5000 handlers with main CPU's callback system
;   5. Initializes hard disk system state
;
; Entry: XWA = workspace pointer (provided by main CPU)
; Exit:  All registers restored
; ============================================================================

; RAM Variables used by HDAE5000
HDAE5000_WORKSPACE_PTR	EQU	23A1A2h	; Pointer to main workspace structure
HDAE5000_HANDLER_1	EQU	230ECCh	; Handler function pointer 1
HDAE5000_HANDLER_2	EQU	230ED2h	; Handler function pointer 2
HDAE5000_HANDLER_3	EQU	230ED6h	; Handler function pointer 3
HDAE5000_INIT_FLAG	EQU	230EDAh	; Initialization result flag

; Workspace structure offsets (from HDAE5000_WORKSPACE_PTR)
WS_OFFSET_HANDLERS_A	EQU	0E0Ah	; Offset to handler table A
WS_OFFSET_HANDLERS_B	EQU	0E88h	; Offset to handler table B
WS_HANDLER_A_FUNC1	EQU	02C4h	; Function 1 in handler table A
WS_HANDLER_B_FUNC1	EQU	0108h	; Function 1 in handler table B
WS_HANDLER_B_FUNC2	EQU	0100h	; Function 2 in handler table B
WS_HANDLER_B_FUNC3	EQU	0104h	; Function 3 in handler table B
WS_HANDLER_A_FUNC2	EQU	0124h	; Function 2 in handler table A

; DRAM work area addresses
HDAE5000_DRAM_AREA_1	EQU	1A0000h	; First DRAM work area (38400 bytes)
HDAE5000_DRAM_AREA_2	EQU	1A9600h	; Second DRAM work area (38400 bytes)
HDAE5000_DRAM_SIZE	EQU	9600h	; Size of each work area (38400 bytes)

; ============================================================================
; HDAE5000_Boot_Init - Main boot initialization entry point
; ============================================================================
HDAE5000_Boot_Init:
	push	XIZ
	ld	XIZ, XWA		; XIZ = workspace pointer from main CPU

	calr	HDAE5000_Setup_Internal	; Initialize internal state (at 0x28F785)

	ld	(HDAE5000_WORKSPACE_PTR), XIZ	; Store workspace pointer for later use

	call	HDAE5000_Handler_Registration	; Register handlers (at 0x280020)

	; Load configuration data address
	lda	XWA, 02E5DCEh		; Source address for configuration
	calr	HDAE5000_Load_Config	; Process configuration (at 0x28F8E0)

	; Allocate DRAM work area 1
	ld	XWA, 0			; Clear destination
	ld	XBC, 01E000A1h		; Allocation parameters
	ld	XDE, 0			; Additional flags
	calr	HDAE5000_Alloc_Memory	; Allocate memory (at 0x28F543)
	ld	XIZ, XHL		; XIZ = allocated address

	; Copy data to DRAM area 1 (0x1A0000, size 0x9600)
	push	HDAE5000_DRAM_SIZE	; Size = 38400 bytes
	ld	XWA, XIZ
	push	XWA			; Source address
	ld	XWA, HDAE5000_DRAM_AREA_1
	push	XWA			; Destination = 0x1A0000
	call	HDAE5000_MemCopy	; Copy routine (at 0x29AE9F)

	; Copy data to DRAM area 2 (0x1A9600, size 0x9600)
	push	HDAE5000_DRAM_SIZE	; Size = 38400 bytes
	ld	XWA, XIZ
	add	XWA, HDAE5000_DRAM_SIZE	; Source + offset
	push	XWA			; Source address
	ld	XWA, HDAE5000_DRAM_AREA_2
	push	XWA			; Destination = 0x1A9600
	call	HDAE5000_MemCopy	; Copy routine (at 0x29AE9F)

	lda	XSP, XSP + 14h		; Clean up stack (5 pushes * 4 bytes = 20)

	; Register HDAE5000 handler with main CPU's callback system
	ld	XWA, (HDAE5000_WORKSPACE_PTR)
	ld	XWA, (XWA + WS_OFFSET_HANDLERS_A)	; Get handler table A
	ld	XIX, (XWA + WS_HANDLER_A_FUNC1)		; Get function pointer
	ld	XWA, 00600002h		; Handler registration ID
	call	T, XIX			; Call registration function

	; Store handler data
	ld	XWA, 016A0005h		; Handler flags/ID
	ld	(XHL), XWA		; Store at returned address
	lda	XWA, 02F8DCEh		; Secondary handler address
	ld	(XHL + 2Ah), XWA	; Store at offset 0x2A

	; Initialize handler 1 (audio?)
	ld	XWA, (HDAE5000_WORKSPACE_PTR)
	ld	XWA, (XWA + WS_OFFSET_HANDLERS_B)	; Get handler table B
	ld	XHL, (XWA + WS_HANDLER_B_FUNC1)		; Get function 1
	call	T, XHL			; Call initialization
	ld	(HDAE5000_HANDLER_1), XHL	; Store returned handler

	; Initialize handler 2 (file system?)
	ld	XWA, (HDAE5000_WORKSPACE_PTR)
	ld	XWA, (XWA + WS_OFFSET_HANDLERS_B)
	ld	XHL, (XWA + WS_HANDLER_B_FUNC2)
	call	T, XHL
	ld	(HDAE5000_HANDLER_2), XHL

	; Initialize handler 3 (disk I/O?)
	ld	XWA, (HDAE5000_WORKSPACE_PTR)
	ld	XWA, (XWA + WS_OFFSET_HANDLERS_B)
	ld	XHL, (XWA + WS_HANDLER_B_FUNC3)
	call	T, XHL
	ld	(HDAE5000_HANDLER_3), XHL

	; Check hard disk presence
	call	HDAE5000_Check_HD_Present	; at 0x2971A3
	ld	(HDAE5000_INIT_FLAG), L		; Store result (0 = no HD, non-zero = HD present)

	cp	L, 0
	jr	Z, .skip_hd_init	; Skip if no hard disk

	; Hard disk is present - initialize it
	ld	XWA, (HDAE5000_WORKSPACE_PTR)
	ld	XWA, (XWA + WS_OFFSET_HANDLERS_A)
	ld	XHL, (XWA + WS_HANDLER_A_FUNC2)	; Get HD init function
	ld	XWA, 0FFFFFFFFh		; Full initialization
	ld	XBC, 01C00016h		; HD parameters
	ld	XDE, 01A0007Fh		; HD buffer address
	call	T, XHL			; Initialize hard disk

.skip_hd_init:
	call	HDAE5000_Finalize_Init	; Final setup (at 0x28F90B)
	call	HDAE5000_Register_Frame	; Register frame handler (at 0x2803C2)

	pop	XIZ
	ret

; ============================================================================
; Forward declarations for routines in other sections
; These will be resolved when the full ROM is disassembled
; ============================================================================
; HDAE5000_Setup_Internal	EQU	28F785h	; In code section
; HDAE5000_Load_Config		EQU	28F8E0h	; In code section
; HDAE5000_Alloc_Memory		EQU	28F543h	; In code section
; HDAE5000_MemCopy		EQU	29AE9Fh	; In code section 2
; HDAE5000_Check_HD_Present	EQU	2971A3h	; In code section 2
; HDAE5000_Finalize_Init	EQU	28F90Bh	; In code section
; HDAE5000_Register_Frame	EQU	2803C2h	; In code section 1
