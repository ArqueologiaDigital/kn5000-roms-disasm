; HDAE5000 Hard Disk Expansion ROM Disassembly
; Original file: hd-ae5000_v2_06i.ic4
; Size: 512KB (0x80000 bytes)
; Base address: 0x280000 (mapped in main CPU address space)
;
; This ROM is part of the optional HD-AE5000 hard disk expansion for the
; Technics KN5000 music keyboard. It provides:
;   - Hard disk file management
;   - PC parallel port communication (PPORT)
;   - Additional UI elements for HD operations
;
; Version: 2.33J (as stated in ROM strings)
; Date: Juli-Oktober 1996
; Author: M. Kitajima (Technics Software section)
;
; Entry Points (called by main CPU via validation at boot):
;   0x280008 - JP to HDAE5000_Boot_Init (0x28F576)
;   0x280010 - JP to HDAE5000_Frame_Handler (0x28F662)
;
; Hardware accessed:
;   0x160000-0x160006 - HDAE5000 PPI (8255) ports
;   0x23xxxx - RAM workspace (shared with main CPU)
;
; ROM Layout (file offsets → memory addresses):
;   0x00000-0x0001F  Header with "XAPR4" magic and entry vectors (32 bytes)
;   0x00020-0x0F575  Code section 1 - setup routines (62806 bytes)
;   0x0F576-0x0F661  HDAE5000_Boot_Init routine (236 bytes)
;   0x0F662-0x15421  Code section 2 part A - frame handler (0x28F662-0x295421)
;   0x15422-0x15FC0  PPORT command menu strings (0x295422-0x295FC0, ~1440 bytes)
;                    Contains 20+ menu items: "Exit PPORT", "Read FSB from HD",
;                    "Send data to PC", "Formatting HD", etc.
;   0x15FC1-0x1A3AF  Code section 2 part B - more routines
;   0x1A3B0-0x1A3DF  Version info block (0x2999B0-0x2999DF):
;                    "Technics Software section    M. Kitajima"
;                    Version: "2.33J", also "2.21"
;                    "TECHNICS KN5000"
;   0x1C9FF-0x1D9FF  UI configuration strings (0x29BFE0-0x29CFF0):
;                    "infofont", "reversecolor", "fontcolor", "dial", etc.
;   0x1D000-0x6FFFF  Additional code, lookup tables, German error messages
;   0x70000-0x7FFFF  Padding zeros (last 64KB)
;
; Key Routine Addresses (within code sections):
;
; Code Section 1 (0x280020-0x28F575):
;   0x280020  HDAE5000_Code_Section_1 - Handler registration entry
;   0x28030E  HDAE5000_Alloc_Check - Memory allocation parameter check
;   0x28033B  HDAE5000_Util_033B - Utility routine
;   0x280368  HDAE5000_Util_0368 - Utility routine
;   0x2803C2  HDAE5000_Register_Frame - Register frame handler callback
;   0x28F543  HDAE5000_Alloc_Memory - Display parameter lookup (DISASSEMBLED)
;   0x28F570  HDAE5000_Get_Init_Flag - Return HD presence flag (DISASSEMBLED)
;
; Code Section 2 (0x28F662-0x2FFFFF):
;   0x28F662  HDAE5000_Frame_Handler - Main frame handler entry (DISASSEMBLED)
;                Calculates display offset, calls registered callbacks
;   0x28F6E0  HDAE5000_Frame_Handler_Status - Status check section (DISASSEMBLED)
;                Monitors bit 2, triggers display init on state change
;   0x28F781  HDAE5000_Frame_Handler_Exit - Exit via JP to PPORT (DISASSEMBLED)
;   0x28F785  HDAE5000_Clear_Work_Buffer - Clear/init work buffer (DISASSEMBLED)
;   0x28F7DD  HDAE5000_Delay_Loop - Nested delay loop (DISASSEMBLED)
;   0x28F7EE  HDAE5000_VGA_Port_Write - Write to VGA port (mem-mapped at 0x170000) (DISASSEMBLED)
;   0x28F813  HDAE5000_Palette_Setup - Set one VGA palette entry (DISASSEMBLED)
;   0x28F8E0  HDAE5000_Load_Palette - Load all 256 palette entries (DISASSEMBLED)
;   0x28F90B  HDAE5000_Finalize_Init - Just returns (1-byte stub) (DISASSEMBLED)
;   0x28F90C  HDAE5000_Display_Init - Display/callback initialization (LABEL EXPOSED)
;   0x28F90C  HDAE5000_Display_Init - Display/callback initialization
;   0x28F97E  HDAE5000_Calc_Offset_16 - Calculate 16-byte offset in table
;   0x28F98B  HDAE5000_Copy_To_Table - Copy data to table at 0x201632
;   0x28F9AD  HDAE5000_Alloc_Check_2F - Memory check routine
;   0x28F9EB  HDAE5000_Count_Invalid - Count invalid entries
;   0x28FA1E  HDAE5000_Calc_Addr_4C - Calculate address with 0x4C multiplier
;   0x28FA56  HDAE5000_Copy_Entry - Copy table entry
;   0x28FAA0  HDAE5000_Calc_Addr_90 - Calculate address with 0x90 multiplier
;   0x28FABA  HDAE5000_Copy_Entry_90 - Copy 0x90-stride entry
;   0x28FAE9  HDAE5000_Check_Entry - Check table entry validity
;   0x28FB26  HDAE5000_Get_Entry_Addr - Get entry address with validation
;   0x28FBB1  HDAE5000_Validate_Entry - Validate entry at coordinates
;   0x29501C  HDAE5000_PPORT_Handler - PPORT state machine entry
;   0x295009  HDAE5000_PPORT_Util - PPORT utility function
;   0x295046  HDAE5000_PPORT_Status - PPORT status check
;   0x295058  HDAE5000_PPORT_Init - PPORT initialization
;   0x2950CC  HDAE5000_PPORT_Dispatch - Command dispatcher
;   0x2950F8  HDAE5000_Display_String - Display string routine (heavily used)
;   0x29511C  HDAE5000_PPORT_Setup - PPORT setup routine
;   0x2952D6  HDAE5000_PPORT_Menu - PPORT menu handler
;   0x2952F8  HDAE5000_PPORT_Execute - Execute PPORT command
;   0x2953E2  HDAE5000_PPORT_Cmd_Table - Jump table for PPORT commands
;   0x295412  HDAE5000_PPORT_Strings - Command menu strings
;   0x2958D6  HDAE5000_Cmd01_SendInfo - Handler: Send HD info
;   0x295914  HDAE5000_Cmd02_Exit - Handler: Exit PPORT
;   0x2959F6  HDAE5000_Cmd03_ReadFSB - Handler: Read FSB from HD
;   0x295D3C  HDAE5000_Cmd04_SendFSB - Handler: Send FSB to PC
;   0x29605A  HDAE5000_Cmd05_RcvFSB - Handler: Receive FSB from PC
;   0x296294  HDAE5000_Cmd06_WriteFSB - Handler: Write FSB to HD
;   0x2967B4  HDAE5000_Display_Util - Display utility
;   0x2967E4  HDAE5000_Display_Util2 - Display utility 2
;   0x29AE9F  HDAE5000_MemCopy - Memory copy utility
;   0x29AFF0  HDAE5000_MemCopy2 - Memory copy variant
;   0x29AFBE  HDAE5000_MemCompare - Memory compare
;   0x29AF71  HDAE5000_MemUtil - Memory utility
;   0x29B72D  HDAE5000_Multiply - 32-bit multiply routine
;   0x2971A3  HDAE5000_Check_HD_Present - Hard disk presence detection
;   0x2999B0  HDAE5000_Version_Info - Version string block:
;                "Technics Software section    M. Kitajima"
;                Version "2.33J", "2.21", "TECHNICS KN5000"
;   0x29BFE0  HDAE5000_UI_Config - UI configuration strings:
;                "infofont", "reversecolor", "fontcolor", "dial", etc.
;   0x2F94B2  HDAE5000_Init_Data - Data copied to 0x23952A (0xC82 bytes)
;
; RAM Workspace (0x23xxxx):
;   0x23A19E  HDAE5000_WORKSPACE_PTR2 - Secondary workspace pointer
;   0x23A1A2  HDAE5000_WORKSPACE_PTR - Main workspace structure pointer
;   0x230EC2  HDAE5000_WORK_TEMP - Temporary work variable
;   0x230EC4  HDAE5000_STATE_VAR - State variable
;   0x230EC6  HDAE5000_CALC_RESULT - Calculation result storage
;   0x230ECC  HDAE5000_HANDLER_1 - Handler function pointer 1
;   0x230ED0  HDAE5000_PREV_STATE - Previous state value
;   0x230ED2  HDAE5000_HANDLER_2 - Handler function pointer 2
;   0x230ED6  HDAE5000_HANDLER_3 - Handler function pointer 3
;   0x230EDA  HDAE5000_INIT_FLAG - Initialization result flag
;   0x22A000  HDAE5000_WORK_BUFFER - Work buffer (0xF52A bytes, cleared at init)
;   0x23952A  HDAE5000_DATA_COPY_DEST - Data copy destination
;
; PPORT (PC Parallel Port) Command Menu:
;   The HD-AE5000 provides a parallel port interface for PC communication.
;   Command menu strings at 0x295412 define available operations:
;
;   01>Send Infos About HD   - Send HD information to PC
;   02>Exit PPORT            - Exit PPORT mode
;   03>Read FSB from HD      - Read File System Block from HD
;   04>Sending FSB to PC     - Transfer FSB data to PC
;   05>Rcv FSB from PC       - Receive FSB data from PC
;   06>Writing FSB to HD     - Write FSB data to HD
;   07>Load HD to Memory     - Load HD content to memory
;   08>Send data to PC       - Send data block to PC
;   09>Sending files to PC   - Transfer files to PC
;   10>Rcv data from PC      - Receive data from PC
;   11>Save memory to HD     - Save memory content to HD
;   12>nothing               - (reserved)
;   13>Rcv data from PC      - Receive data from PC (variant)
;   14>Sending infos to PC   - Send info block to PC
;   15>nothing               - (reserved)
;   16>Delete files          - Delete files from HD
;   17>Formating HD          - Format hard disk
;   18>Switch HD-motor off   - Turn off HD motor
;   19>nothing               - (reserved)
;   20>Send XapFile flash    - Flash XapFile data
;
; PPORT Command Handler Jump Table at 0x2953E2:
;   Contains 17 handler addresses for commands 01-17+

	cpu	96c141	; Actual CPU is TMP94C241F (ASL only supports TMP96C141)
	page	0
	maxmode	on
	include "../tmp94c241.inc"

	org	280000h

; ============================================================================
; ROM HEADER
; ============================================================================

HDAE5000_ROM_HEADER:
	db	"XAPR4"			; Magic identifier ("XAPR" checked by main CPU)
	db	0A1h			; Version byte
	db	02Fh, 000h		; Unknown (possibly size/flags)

; Entry point 1 - Jump to boot initialization
HDAE5000_ENTRY_1:			; 280008h
	jp	HDAE5000_Boot_Init	; Called when main CPU validates HDAE5000 presence

; Padding after vector
	ret
	nop
	nop
	nop

; Entry point 2 - Jump to frame handler (called periodically)
HDAE5000_ENTRY_2:			; 280010h
	jp	HDAE5000_Frame_Handler	; Called from main loop for HD status updates

; Padding after vector
	ret
	nop
	nop
	nop

; Unused entry vectors (return immediately)
HDAE5000_ENTRY_3:			; 280018h
	ret
	nop
	nop
	nop

HDAE5000_ENTRY_4:			; 28001Ch
	ret
	nop
	nop
	nop

; ============================================================================
; CODE SECTION 1 (0x280020 - 0x28F575)
;
; Key routines:
;   0x280020  Code_Section_1 - Handler registration entry (called from boot_init)
;   0x28030E  Alloc_Check - Memory allocation parameter check
;   0x28033B  Utility routine
;   0x280368  Utility routine
;   0x2803C2  Register_Frame - Register frame handler callback
;   0x28F543  Alloc_Memory - Memory allocation routine
; ============================================================================

HDAE5000_Code_Section_1:		; 280020h
	; Handler registration and utility routines
	; Contains multiple indirect callback registrations via workspace pointers
	binclude "includes/code_280020_2803c1.bin"

HDAE5000_Register_Frame:		; 2803C2h
	; Register frame handler callback with main CPU
	; Clears 0x23A08E, 0x23A092, 0x23A094 and initializes display data
	binclude "includes/code_2803c2_28f542.bin"

HDAE5000_Alloc_Memory:			; 28F543h
	; Memory/display parameter lookup routine
	; Input: XBC = request type (0x01E000A1, A2, or A3)
	; Output: XHL = result based on type:
	;   A1 -> 0x2E61CE (ROM palette data pointer)
	;   A2 -> 0x140 (320 decimal - display width)
	;   A3 -> 0xF0 (240 decimal - display height)
	;   else -> 0 (invalid type)
	cp	XBC, 01E000A3h		; Check for type A3
	jr	Z, .type_A3
	cp	XBC, 01E000A2h		; Check for type A2
	jr	Z, .type_A2
	cp	XBC, 01E000A1h		; Check for type A1
	jr	Z, .type_A1
	ld	XHL, 0			; Invalid type - return 0
	ret
.type_A1:
	lda	XHL, 2E61CEh		; Return palette data pointer
	ret
.type_A2:
	ld	XHL, 00000140h		; Return 320 (width)
	ret
.type_A3:
	ld	XHL, 000000F0h		; Return 240 (height)
	ret

HDAE5000_Get_Init_Flag:			; 28F570h
	; Returns HD presence flag in L
	; Output: L = value from HDAE5000_INIT_FLAG (0x230EDA)
	ld	L, (HDAE5000_INIT_FLAG)
	ret

; ============================================================================
; BOOT INITIALIZATION ROUTINE (0x28F576 - 0x28F661)
; Called once at startup when HDAE5000 is detected via header validation
;
; Input: XWA = workspace structure pointer from main CPU
; Output: L = HD presence flag (stored at 0x230EDA)
;
; This routine:
;   1. Clears work buffer (0xF52A bytes at 0x22A000)
;   2. Registers handlers with main CPU via callback at 0x280020
;   3. Loads VGA palette from ROM at 0x2E5DCE
;   4. Allocates 0x12C00 bytes and copies VRAM data from 0x1A0000
;   5. Initializes handler function pointers at 0x230ECC/ED2/ED6
;   6. Checks for HD presence via 0x2971A3
;   7. Registers frame handler callback via 0x2803C2
;
; Key addresses called:
;   0x28F785 - Clear work buffer
;   0x280020 - Handler registration (code section 1)
;   0x28F8E0 - Load palette
;   0x28F543 - Memory allocation (code section 1)
;   0x29AE9F - Memory copy
;   0x2971A3 - Check HD present
;   0x28F90B - Finalize init
;   0x2803C2 - Register frame handler (code section 1)
; ============================================================================

; RAM variable addresses
HDAE5000_WORKSPACE_PTR	equ	23A1A2h
HDAE5000_HANDLER_1	equ	230ECCh
HDAE5000_HANDLER_2	equ	230ED2h
HDAE5000_HANDLER_3	equ	230ED6h
HDAE5000_INIT_FLAG	equ	230EDAh

; ROM data addresses
HDAE5000_Palette_Data	equ	2E5DCEh
HDAE5000_Display_Params	equ	2F8DCEh

; All routine addresses are now exposed as labels in split binary sections

; PPORT state machine handler (in code_28f90c_2953e1.bin)
HDAE5000_PPORT_Handler	equ	29501Ch	; PPORT state machine entry point

; PPORT command handler addresses (in code_295642_2fffff.bin)
HDAE5000_Cmd01_SendInfo	equ	2958D6h	; Send HD info to PC
HDAE5000_Cmd02_Exit	equ	295914h	; Exit PPORT mode
HDAE5000_Cmd03_ReadFSB	equ	2959F6h	; Read FSB from HD
HDAE5000_Cmd04_SendFSB	equ	295D3Ch	; Send FSB to PC
HDAE5000_Cmd05_RcvFSB	equ	29605Ah	; Receive FSB from PC
HDAE5000_Cmd06_WriteFSB	equ	296294h	; Write FSB to HD
HDAE5000_Cmd07_LoadHD	equ	29632Ah	; Load HD to Memory
HDAE5000_Cmd08_SendData	equ	29633Ch	; Send data to PC
HDAE5000_Cmd09_SendFiles	equ	2964A6h	; Send files to PC
HDAE5000_Cmd10_RcvData	equ	296588h	; Receive data from PC
HDAE5000_Cmd11_SaveMem	equ	29659Ah	; Save memory to HD
HDAE5000_Cmd12_Nothing	equ	296680h	; (reserved)

HDAE5000_Boot_Init:			; 28F576h
	push	XIZ
	ld	XIZ, XWA		; XIZ = workspace pointer from main CPU

	calr	HDAE5000_Clear_Work_Buffer	; Clear 0xF52A bytes at 0x22A000

	ld	(HDAE5000_WORKSPACE_PTR), XIZ	; Store workspace pointer

	call	HDAE5000_Code_Section_1	; Register handlers with main CPU

	lda	XWA, HDAE5000_Palette_Data	; Load palette data address
	calr	HDAE5000_Load_Palette	; Load 256-entry VGA palette

	; Allocate memory for VRAM copy
	ld	XWA, 0
	ld	XBC, 01E000A1h		; Allocation type A1
	ld	XDE, 0
	calr	HDAE5000_Alloc_Memory	; Returns address in XHL
	ld	XIZ, XHL		; XIZ = allocated buffer

	; Copy from allocated buffer to VRAM area 1 (0x1A0000, size 0x9600)
	db	0Bh, 00h, 96h		; push 9600h (16-bit immediate)
	ld	XWA, XIZ
	push	XWA			; Source
	ld	XWA, 001A0000h		; Destination
	push	XWA
	call	HDAE5000_MemCopy

	; Copy from allocated buffer + offset to VRAM area 2 (0x1A9600)
	db	0Bh, 00h, 96h		; push 9600h (16-bit immediate)
	ld	XWA, XIZ
	add	XWA, 00009600h		; Source + offset
	push	XWA
	ld	XWA, 001A9600h		; Destination
	push	XWA
	call	HDAE5000_MemCopy

	lda	XSP, XSP + 14h		; Clean stack (5 pushes × 4 bytes = 20)

	; Register callback handler 1
	ld	XWA, (HDAE5000_WORKSPACE_PTR)
	ld	XWA, (XWA + 0E0Ah)	; Handler table A
	ld	XIX, (XWA + 02C4h)	; Registration function
	ld	XWA, 00600002h		; Handler ID
	call	T, XIX			; Call registration
	ld	XWA, 016A0005h		; Handler flags
	ld	(XHL), XWA		; Store at returned address
	lda	XWA, HDAE5000_Display_Params
	ld	(XHL + 2Ah), XWA	; Store display params pointer

	; Initialize handler 1 pointer
	ld	XWA, (HDAE5000_WORKSPACE_PTR)
	ld	XWA, (XWA + 0E88h)	; Handler table B
	ld	XHL, (XWA + 0108h)	; Init function
	call	T, XHL
	ld	(HDAE5000_HANDLER_1), XHL

	; Initialize handler 2 pointer
	ld	XWA, (HDAE5000_WORKSPACE_PTR)
	ld	XWA, (XWA + 0E88h)
	ld	XHL, (XWA + 0100h)
	call	T, XHL
	ld	(HDAE5000_HANDLER_2), XHL

	; Initialize handler 3 pointer
	ld	XWA, (HDAE5000_WORKSPACE_PTR)
	ld	XWA, (XWA + 0E88h)
	ld	XHL, (XWA + 0104h)
	call	T, XHL
	ld	(HDAE5000_HANDLER_3), XHL

	; Check for hard disk presence
	call	HDAE5000_Check_HD_Present
	ld	(HDAE5000_INIT_FLAG), L	; Store result

	cp	L, 0
	jr	Z, .skip_hd_init	; Skip if no HD

	; Hard disk present - initialize it
	ld	XWA, (HDAE5000_WORKSPACE_PTR)
	ld	XWA, (XWA + 0E0Ah)
	ld	XHL, (XWA + 0124h)	; HD init function
	ld	XWA, 0FFFFFFFFh		; Full init
	ld	XBC, 01C00016h		; HD params
	ld	XDE, 01A0007Fh		; Buffer
	call	T, XHL

.skip_hd_init:
	call	HDAE5000_Finalize_Init	; Final setup
	call	HDAE5000_Register_Frame	; Register frame handler

	pop	XIZ
	ret

; ============================================================================
; CODE SECTION 2 PART A (0x28F662 - 0x2953E1)
; Frame handler and utility routines before PPORT command table
;
; Key routines in this section:
;   0x28F662  Frame_Handler - Main frame handler entry
;   0x28F781  Frame_Handler_Exit - JP to PPORT handler
;   0x28F785  Clear_Work_Buffer - Clear work area, copy init data
;   0x28F7DD  Delay_Loop - Timing utility
;   0x28F7EE  VGA_Port_Write - Write to VGA DAC registers
;   0x28F813  Palette_Setup - Configure single palette entry
;   0x28F8E0  Load_Palette - Load all 256 palette entries
;   0x28F90B  Finalize_Init - Just returns (stub)
;   0x28F90C  Display_Init - Display initialization
; ============================================================================

HDAE5000_Frame_Handler:			; 28F662h
	; Frame handler main entry - called periodically from main loop
	; 1. Check workspace pointer at 0x23A19E (skip if -1)
	; 2. Read handler states from 0x230ED2, 0x230ED6
	; 3. Calculate display offset = (WA * 3) << 2, store at 0x230EC6
	; 4. Call registered callback via workspace[0x0E0A][0x0124]
	;
	ld	XWA, (23A19Eh)		; Load secondary workspace pointer
	cp	XWA, 0FFFFFFFFh		; Check if uninitialized (-1)
	jr	Z, HDAE5000_Frame_Handler_Status	; Skip to status check if no workspace
	;
	; Calculate display offset from handler states
	ld	XWA, (230ED6h)		; Load handler 3 pointer
	ld	A, (XWA)		; Read state byte
	db	0C9h, 0EFh, 03h		; srl 3, A  ; divide by 8
	ld	E, A			; Save in E
	;
	ld	XWA, (230ED2h)		; Load handler 2 pointer
	ld	WA, (XWA)		; Read state word
	extz	XWA			; Zero-extend to 32-bit
	ld	XBC, XWA		; XBC = state value
	add	XBC, XBC		; XBC *= 2
	add	XBC, XWA		; XBC *= 3 (total: state * 3)
	db	0E9h, 0EEh, 02h		; sll 2, XBC  ; XBC *= 4 (total: state * 12)
	ld	XWA, 0			; Clear XWA
	ld	A, E			; Restore shifted value
	db	0E8h, 62h		; inc 2, XWA  ; Add 2 (?) to low word
	add	XWA, XBC		; Combine offsets
	ld	(230EC6h), XWA		; Store calculated display offset
	;
	; Check if state changed
	db	0CDh, 61h		; inc 1, E
	ld	A, E
	extz	WA
	cp	WA, (230EC4h)		; Compare with previous state
	jr	Z, HDAE5000_Frame_Handler_Status	; Skip if unchanged
	;
	; State changed - update and call callback
	ld	A, E
	extz	WA
	ld	(230EC4h), WA		; Update state variable
	ld	XWA, (230ED2h)		; Load handler 2 pointer
	ld	WA, (XWA)		; Read state
	ld	(230EC2h), WA		; Store in temp
	lda	XWA, 230EC2h		; Load address of temp
	ld	XBC, XWA		; XBC = temp address
	ld	XWA, (23A19Eh)		; Secondary workspace pointer
	ld	XDE, XBC		; XDE = temp address
	ld	XBC, (23A1A2h)		; Main workspace pointer
	ld	XBC, (XBC + 0E0Ah)	; Handler table A
	ld	XHL, (XBC + 0124h)	; Get callback function
	ld	XBC, 01CA0004h		; Callback parameter
	call	T, XHL			; Call callback if valid

HDAE5000_Frame_Handler_Status:		; 28F6E0h
	; Frame handler status check section
	; Monitors handler 1 status bit 2, triggers display init when it transitions to 0
	;
	ld	XWA, (230ECCh)		; Load handler 1 pointer
	ld	A, (XWA)		; Read status byte
	and	A, 04h			; Isolate bit 2
	cp	A, (230ED0h)		; Compare with previous state
	db	76h, 8Fh, 00h		; jrl Z, Frame_Handler_Exit  ; Skip if unchanged
	;
	; Status changed - update previous state
	ld	(230ED0h), A		; Store new state
	cp	A, 0			; Check if bit 2 now clear
	db	7Eh, 85h, 00h		; jrl NZ, Frame_Handler_Exit  ; Skip if bit still set
	;
	; Bit 2 cleared - check if display init needed
	call	28B3B3h			; Call status check routine
	cp	L, 1			; Check return value
	jr	NZ, HDAE5000_Frame_Handler_Exit	; Skip if not 1
	;
	; Initialize display - call workspace callback
	ld	XWA, (23A1A2h)		; Main workspace pointer
	ld	XWA, (XWA + 0E0Ah)	; Handler table A
	ld	XIX, (XWA + 0278h)	; Get display callback
	call	T, XIX			; Call if valid
	cp	XHL, 01A0007Fh		; Check return value
	jr	Z, .init_display	; If match, do full init
	;
	; Partial update
	ld	WA, 1
	call	28B3B9h			; Call update routine
	ld	WA, 007Fh
	call	28AC68h			; Call UI update
	jr	T, HDAE5000_Frame_Handler_Exit
	;
.init_display:
	; Full display initialization sequence
	ld	XWA, (23A1A2h)
	ld	XWA, (XWA + 0E0Ah)
	ld	XHL, (XWA + 0124h)	; Init callback 1
	ld	XWA, 007F013Eh		; Display params
	ld	XBC, 01C00001h		; Init flags
	ld	XDE, 0
	call	T, XHL
	;
	ld	XWA, (23A1A2h)
	ld	XWA, (XWA + 0E0Ah)
	ld	XHL, (XWA + 0534h)	; Init callback 2
	ld	XWA, 007F013Eh
	ld	XBC, 01CA0000h
	call	T, XHL
	;
	ld	XWA, (23A1A2h)
	ld	XWA, (XWA + 0E0Ah)
	ld	XHL, (XWA + 0124h)	; Init callback 3
	ld	XWA, 007F013Eh
	ld	XBC, 01CA0000h
	ld	XDE, 0
	call	T, XHL

HDAE5000_Frame_Handler_Exit:		; 28F781h
	; Exit frame handler by jumping to PPORT handler
	jp	HDAE5000_PPORT_Handler

; ----------------------------------------------------------------------------
; Utility routines (0x28F785 - 0x2953E1)
; ----------------------------------------------------------------------------

HDAE5000_Clear_Work_Buffer:		; 28F785h
	; Clear work buffer and copy initialization data from ROM
	; Part 1: Clear 0xF52A bytes (62,762) at 0x22A000 using word operations
	; Part 2: Copy 0x0C82 bytes (3,202) from ROM 0x2F94B2 to RAM 0x23952A
	;
	; Uses LDIRW for word block copy, LDIR for byte copy
	; Handles large counts via QBC (high word of XBC) loop
	;
	; === Part 1: Clear work buffer ===
	ld	XDE, 0022A000h		; Destination = work buffer
	ld	XBC, 0000F52Ah		; Count = 62,762 bytes
	ld	IX, BC			; Save low word for odd byte check
	db	0E9h, 0EFh, 01h		; srl 1, XBC  ; divide by 2 for word ops
	jr	Z, .clear_done		; Skip if count was 0 or 1
	ld	XHL, XDE		; Source = destination (for LDIRW)
	db	0F5h, 0E9h, 02h, 00h, 00h	; ld (XDE+), 0x0000  ; store first word
	db	0E9h, 69h		; dec 1, XBC
	or	XBC, XBC
	jr	Z, .clear_done
	db	93h, 11h		; ldirw  ; copy words (fills with zeros)
	db	0D7h, 0E6h, 0D8h	; cp QBC, 0  ; check high word
	jr	Z, .clear_done
	db	0D7h, 0E6h, 88h		; ld WA, QBC  ; get high word count
.clear_loop:
	db	93h, 11h		; ldirw  ; continue word copy
	db	0D8h, 1Ch, 0FBh		; djnz WA, .clear_loop
.clear_done:
	db	0DCh, 33h, 00h		; bit 0, IX  ; check if odd byte
	jr	Z, .no_odd_byte
	ld	(XDE), 00h		; Clear final odd byte
.no_odd_byte:
	; === Part 2: Copy init data from ROM to RAM ===
	ld	XDE, 0023952Ah		; Destination = RAM init area
	ld	XHL, 002F94B2h		; Source = ROM init data
	ld	XBC, 00000C82h		; Count = 3,202 bytes
	or	XBC, XBC
	jr	Z, .copy_done
	db	83h, 11h		; ldir  ; copy bytes
	db	0D7h, 0E6h, 0D8h	; cp QBC, 0
	jr	Z, .copy_done
	db	0D7h, 0E6h, 88h		; ld WA, QBC
.copy_loop:
	db	83h, 11h		; ldir
	db	0D8h, 1Ch, 0FBh		; djnz WA, .copy_loop
.copy_done:
	ret

HDAE5000_Delay_Loop:			; 28F7DDh
	; Simple nested delay loop - decrements XWA until zero
	; Input: XWA = delay count (outer loop iterations)
	; Clobbers: XWA, XBC
	; Algorithm: Outer loop decrements XWA, inner loop spins on XBC copy
	ld	XBC, XWA		; Copy count for comparison
	db	0E8h, 69h		; dec 1, XWA (decrement outer counter)
	or	XBC, XBC		; Check if original was zero
	ret	Z			; Return immediately if zero
.inner_loop:
	ld	XBC, XWA		; Copy remaining count
	db	0E8h, 69h		; dec 1, XWA (decrement inner counter)
	or	XBC, XBC		; Check if done
	jr	NZ, .inner_loop		; Continue spinning until zero
	ret

HDAE5000_VGA_Port_Write:		; 28F7EEh
	; Write byte to VGA I/O port (memory-mapped at 0x170000)
	; Input: WA = VGA port number (e.g., 0x3C8, 0x3C9)
	;        C = data byte to write
	; VGA DAC ports: 0x3C8 = palette index, 0x3C9 = R/G/B data
	; Includes 0x100 delay before write to ensure VGA timing
	db	0EFh, 6Ah		; dec 2, XSP (allocate 2 bytes)
	push	IZ
	db	0BFh, 02h, 43h		; ld (XSP+0x02), C  ; save data byte
	ld	IZ, WA			; save port number in IZ
	ld	XWA, 00000100h		; delay count = 256
	calr	HDAE5000_Delay_Loop	; wait for VGA timing
	ld	WA, IZ			; restore port number
	extz	XWA			; zero-extend to 32-bit
	db	0E8h, 0C8h, 00h, 00h, 17h, 00h	; add XWA, 0x00170000
	ld	XBC, XWA		; XBC = 0x170000 + port
	db	8Fh, 02h, 21h		; ld A, (XSP+0x02)  ; restore data byte
	ld	(XBC), A		; write byte to VGA port
	pop	IZ
	db	0EFh, 62h		; inc 2, XSP (deallocate)
	ret

HDAE5000_Palette_Setup:			; 28F813h
	; Set one VGA palette entry - converts 8-bit RGB to VGA 6-bit format
	; Input: A = palette index (0-255)
	;        XBC = pointer to RGBX color data (4 bytes: R, G, B, unused)
	;
	; VGA DAC format: 6-bit per channel (0-63), ROM has 8-bit (0-255)
	; Conversion: value >> 4, with rounding if bit 3 set and value < 0xF0
	;
	; === Write palette index to port 0x3C8 ===
	push	XIZ
	ld	XIZ, XBC		; XIZ = pointer to RGBX data
	extz	WA			; A = palette index, zero-extend
	ld	BC, WA
	ld	WA, 03C8h		; VGA palette index port
	calr	HDAE5000_VGA_Port_Write
	;
	; === Process Red component (XIZ+0) ===
	db	0B6h, 0CBh		; bit 3, (XIZ)  ; check rounding flag
	jr	Z, .red_no_round
	db	86h, 3Fh, 0F0h		; cp (XIZ), 0xF0
	jr	NC, .red_high
	db	86h, 21h		; ld A, (XIZ)
	db	0C9h, 0EFh, 04h		; srl 4, A  ; divide by 16
	db	0C9h, 61h		; inc 1, A  ; round up
	extz	WA
	ld	BC, WA
	ld	WA, 03C9h		; VGA palette data port
	calr	HDAE5000_VGA_Port_Write
	jr	T, .green_start
.red_high:
	db	86h, 21h		; ld A, (XIZ)
	db	0C9h, 0EFh, 04h		; srl 4, A
	extz	WA
	ld	BC, WA
	ld	WA, 03C9h
	calr	HDAE5000_VGA_Port_Write
	jr	T, .green_start
.red_no_round:
	db	86h, 21h		; ld A, (XIZ)
	db	0C9h, 0EFh, 04h		; srl 4, A
	extz	WA
	ld	BC, WA
	ld	WA, 03C9h
	calr	HDAE5000_VGA_Port_Write
	;
	; === Process Green component (XIZ+1) ===
.green_start:
	db	0BEh, 01h, 0CBh		; bit 3, (XIZ+1)
	jr	Z, .green_no_round
	db	8Eh, 01h, 3Fh, 0F0h	; cp (XIZ+1), 0xF0
	jr	NC, .green_high
	db	8Eh, 01h, 21h		; ld A, (XIZ+1)
	db	0C9h, 0EFh, 04h		; srl 4, A
	db	0C9h, 61h		; inc 1, A
	extz	WA
	ld	BC, WA
	ld	WA, 03C9h
	calr	HDAE5000_VGA_Port_Write
	jr	T, .blue_start
.green_high:
	db	8Eh, 01h, 21h		; ld A, (XIZ+1)
	db	0C9h, 0EFh, 04h		; srl 4, A
	extz	WA
	ld	BC, WA
	ld	WA, 03C9h
	calr	HDAE5000_VGA_Port_Write
	jr	T, .blue_start
.green_no_round:
	db	8Eh, 01h, 21h		; ld A, (XIZ+1)
	db	0C9h, 0EFh, 04h		; srl 4, A
	extz	WA
	ld	BC, WA
	ld	WA, 03C9h
	calr	HDAE5000_VGA_Port_Write
	;
	; === Process Blue component (XIZ+2) ===
.blue_start:
	db	0BEh, 02h, 0CBh		; bit 3, (XIZ+2)
	jr	Z, .blue_no_round
	db	8Eh, 02h, 3Fh, 0F0h	; cp (XIZ+2), 0xF0
	jr	NC, .blue_high
	db	8Eh, 02h, 21h		; ld A, (XIZ+2)
	db	0C9h, 0EFh, 04h		; srl 4, A
	db	0C9h, 61h		; inc 1, A
	extz	WA
	ld	BC, WA
	ld	WA, 03C9h
	calr	HDAE5000_VGA_Port_Write
	jr	T, .done
.blue_high:
	db	8Eh, 02h, 21h		; ld A, (XIZ+2)
	db	0C9h, 0EFh, 04h		; srl 4, A
	extz	WA
	ld	BC, WA
	ld	WA, 03C9h
	calr	HDAE5000_VGA_Port_Write
	jr	T, .done
.blue_no_round:
	db	8Eh, 02h, 21h		; ld A, (XIZ+2)
	db	0C9h, 0EFh, 04h		; srl 4, A
	extz	WA
	ld	BC, WA
	ld	WA, 03C9h
	calr	HDAE5000_VGA_Port_Write
.done:
	pop	XIZ
	ret

HDAE5000_Load_Palette:			; 28F8E0h
	; Load all 256 VGA palette entries from ROM data
	; Input: XWA = pointer to palette data (256 entries × 4 bytes)
	; Iterates from index 255 down to 0, calling Palette_Setup for each
	;
	; Each palette entry is 4 bytes: RGBX (X unused)
	; VGA DAC ports: 0x3C8 = index, 0x3C9 = R/G/B data (mapped at 0x170000+port)
	db	0EFh, 06Ch		; dec 4, XSP (allocate 4 bytes on stack)
	push	IZ
	db	0BFh, 02h, 60h		; ld (XSP+0x02), XWA  ; store palette ptr
	ld	IZ, 00FFh		; IZ = 255 (palette index counter)
	cp	IZ, 0			; initial check
	jr	LT, .done		; skip loop if IZ < 0 (never happens here)
.loop:
	ld	E, IZL			; E = current palette index
	ld	WA, IZ
	exts	XWA			; sign-extend WA to XWA
	db	0E8h, 0EEh, 02h		; sll 2, XWA  ; XWA = index × 4
	ld	XBC, XWA		; XBC = offset
	db	0AFh, 02h, 81h		; add XBC, (XSP+0x02)  ; XBC = palette_ptr + offset
	ld	A, E			; A = palette index
	calr	HDAE5000_Palette_Setup	; Set one palette entry
	sub	IZ, 0001h		; IZ--
	jr	GE, .loop		; continue while IZ >= 0
.done:
	pop	IZ
	db	0EFh, 64h		; inc 4, XSP (deallocate stack)
	ret

HDAE5000_Finalize_Init:			; 28F90Bh
	; Stub that just returns (placeholder)
	ret

HDAE5000_Display_Init:			; 28F90Ch
	; Display and callback initialization
	; Registers callbacks via workspace function tables
	; at 0x23A1A2 -> (XWA+0xE88) -> (XWA+0xE8)
	; Calls Display_String routine at 0x298622
	binclude "includes/code_28f90c_2953e1.bin"

; ============================================================================
; PPORT COMMAND HANDLER JUMP TABLE (0x2953E2 - 0x295411)
; 12 entries × 4 bytes = 48 bytes
; Each entry is a 32-bit pointer to a command handler routine
;
; Index  Address   Description
;   0    0x2958D6  Cmd01_SendInfo - Send HD info to PC
;   1    0x295914  Cmd02_Exit - Exit PPORT mode
;   2    0x2959F6  Cmd03_ReadFSB - Read FSB from HD
;   3    0x295D3C  Cmd04_SendFSB - Send FSB to PC
;   4    0x29605A  Cmd05_RcvFSB - Receive FSB from PC
;   5    0x296294  Cmd06_WriteFSB - Write FSB to HD
;   6    0x29632A  Cmd07_LoadHD - Load HD to Memory
;   7    0x29633C  Cmd08_SendData - Send data to PC
;   8    0x2964A6  Cmd09_SendFiles - Send files to PC
;   9    0x296588  Cmd10_RcvData - Receive data from PC
;  10    0x29659A  Cmd11_SaveMem - Save memory to HD
;  11    0x296680  Cmd12_Nothing - (reserved)
; ============================================================================

HDAE5000_PPORT_Cmd_Table:		; 2953E2h
	dd	HDAE5000_Cmd01_SendInfo		; 0: Send HD info to PC
	dd	HDAE5000_Cmd02_Exit		; 1: Exit PPORT mode
	dd	HDAE5000_Cmd03_ReadFSB		; 2: Read FSB from HD
	dd	HDAE5000_Cmd04_SendFSB		; 3: Send FSB to PC
	dd	HDAE5000_Cmd05_RcvFSB		; 4: Receive FSB from PC
	dd	HDAE5000_Cmd06_WriteFSB		; 5: Write FSB to HD
	dd	HDAE5000_Cmd07_LoadHD		; 6: Load HD to Memory
	dd	HDAE5000_Cmd08_SendData		; 7: Send data to PC
	dd	HDAE5000_Cmd09_SendFiles	; 8: Send files to PC
	dd	HDAE5000_Cmd10_RcvData		; 9: Receive data from PC
	dd	HDAE5000_Cmd11_SaveMem		; 10: Save memory to HD
	dd	HDAE5000_Cmd12_Nothing		; 11: (reserved)

; ============================================================================
; PPORT COMMAND MENU STRINGS (0x295412 - 0x295641)
; 21 null-terminated strings for PPORT menu display
; Format: "NN>Description" where NN is the command number (01-20)
;
; Strings:
;   01>Send Infos About HD
;   02>Exit PPORT
;   03>Read FSB from HD
;   04>Sending FSB to PC
;   05>Rcv FSB from PC
;   06>Writing FSB to HD
;   07>Load HD to Memory
;   08>Send data to PC
;   09>Sending files to PC
;   10>Rcv data from PC
;   11>Save memory to HD
;   12>nothing
;   13>Rcv data from PC
;   14>Sending infos to PC
;   15>nothing
;   16>Delete files
;   17>Formating HD
;   18>Switch HD-motor off
;   19>nothing
;   20>Send XapFile flash
;   20>End flash right.
;   20>End flash false.
;   Error : Wrong Dll Ver
; ============================================================================

HDAE5000_PPORT_Ptrs:			; 295412h
	; 3 pointers to PPORT utility routines
	dd	002966BEh	; Pointer to utility 1
	dd	002966FAh	; Pointer to utility 2
	dd	0029670Ch	; Pointer to utility 3

HDAE5000_PPORT_Strings:			; 29541Eh
	; PPORT command menu strings (21 null-terminated strings)
	; Format: "NN>Description" where NN = command number
	db	"01>Send Infos About HD", 0, 0
	db	"02>Exit PPORT         ", 0, 0
	db	"03>Read FSB from HD   ", 0, 0
	db	"04>Sending FSB to PC  ", 0, 0
	db	"05>Rcv FSB from PC    ", 0, 0
	db	"06>Writing FSB to HD  ", 0, 0
	db	"07>Load HD to Memory  ", 0, 0
	db	"08>Send data to PC    ", 0, 0
	db	"09>Sending files to PC", 0, 0
	db	"10>Rcv data from PC   ", 0, 0
	db	"11>Save memory to HD  ", 0, 0
	db	"12>nothing            ", 0, 0
	db	"13>Rcv data from PC   ", 0, 0
	db	"14>Sending infos to PC", 0, 0
	db	"15>nothing            ", 0, 0
	db	"16>Delete files       ", 0, 0
	db	"17>Formating HD       ", 0, 0
	db	"18>Switch HD-motor off", 0, 0
	db	"19>nothing            ", 0, 0
	db	"20>Send XapFile flash ", 0, 0
	db	"20>End flash right", 09h, "  ", 0
	db	"20>End flash false", 09h, "  ", 0
	db	"Error : Wrong Dll Ver ", 0, 0

; ============================================================================
; CODE SECTION 2 PART B (0x295642 - 0x2FFFFF)
; All remaining code and data including:
;   - PPORT command handler implementations (Cmd01-Cmd12)
;   - HD file management routines
;   - Check_HD_Present (0x2971A3)
;   - MemCopy utility (0x29AE9F)
;   - UI configuration data
;   - Version information (0x2999B0)
;   - German language error messages
;   - Zero padding at end (~65KB)
; ============================================================================

HDAE5000_Code_2_PartB:			; 295642h
	; PPORT command handlers and HD routines
	binclude "includes/code_295642_2971a2.bin"

HDAE5000_Check_HD_Present:		; 2971A3h
	; Check for hard disk presence
	; Writes 0 to 0x229D92, calls internal routine at 0x2971B7
	; Returns: HL = 0 (result stored in HDAE5000_INIT_FLAG)
	binclude "includes/code_2971a3_29ae9e.bin"

HDAE5000_MemCopy:			; 29AE9Fh
	; Memory copy utility
	; Stack parameters: [+0x04] = dest, [+0x08] = src, [+0x0C] = count
	; Handles overlapping regions correctly (forward/backward copy)
	binclude "includes/code_29ae9f_2fffff.bin"

; ============================================================================
; END OF ROM
; ============================================================================

	end
