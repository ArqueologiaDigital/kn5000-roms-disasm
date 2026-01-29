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
;   0x28F543  HDAE5000_Alloc_Memory - Memory allocation routine
;
; Code Section 2 (0x28F662-0x2FFFFF):
;   0x28F662  HDAE5000_Frame_Handler - Main frame handler entry point
;                Checks workspace pointers, calls registered handlers
;                Jumps to 0x29501C for PPORT state machine
;   0x28F6E0  HDAE5000_Frame_Handler_Part2 - Handler continuation
;   0x28F781  HDAE5000_Frame_Handler_Exit - Exit via JP to PPORT handler
;   0x28F785  HDAE5000_Clear_Work_Buffer - Clear 0xF52A bytes at 0x22A000
;   0x28F7DD  HDAE5000_Delay_Loop - Delay/timing utility
;   0x28F7EE  HDAE5000_VGA_Port_Write - Write to VGA ports 0x3C8/0x3C9
;   0x28F813  HDAE5000_Palette_Setup - Palette configuration
;   0x28F8E0  HDAE5000_Load_Palette - Load 256-entry palette table
;   0x28F90B  HDAE5000_Ret_Stub - Just returns (placeholder)
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
	binclude "includes/code_2803c2_28f575.bin"

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

; Routine addresses in code sections (forward declarations)
HDAE5000_Alloc_Memory	equ	28F543h	; Memory allocation (in code section 1)
HDAE5000_MemCopy	equ	29AE9Fh	; Memory copy utility (in code section 2B)
HDAE5000_Check_HD_Present	equ	2971A3h	; HD presence detection (in code section 2B)

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
	; Frame handler main loop - checks workspace, calls handlers
	; Exits via JP to PPORT handler at 0x29501C
	binclude "includes/code_28f662_28f784.bin"

; ----------------------------------------------------------------------------
; Utility routines (0x28F785 - 0x2953E1)
; ----------------------------------------------------------------------------

HDAE5000_Clear_Work_Buffer:		; 28F785h
	; 1. Clear 0xF52A bytes at 0x22A000 using LDIRW
	; 2. Copy 0x0C82 bytes from 0x2F94B2 to 0x23952A using LDIR
	; Contains: Clear_Work_Buffer, Delay_Loop, VGA_Port_Write, Palette_Setup
	binclude "includes/code_28f785_28f8df.bin"

HDAE5000_Load_Palette:			; 28F8E0h
	; Load all 256 VGA palette entries from ROM data
	; Iterates IZ from 0xFF down to 0, calling Palette_Setup for each
	binclude "includes/code_28f8e0_28f90a.bin"

HDAE5000_Finalize_Init:			; 28F90Bh
	; Final initialization and remaining code section 2A routines
	; First byte is just RET (stub), followed by Display_Init at 0x28F90C
	binclude "includes/code_28f90b_2953e1.bin"

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

HDAE5000_PPORT_Strings:			; 295412h
	binclude "includes/pport_strings_295412_295641.bin"

; ============================================================================
; CODE SECTION 2 PART B (0x295642 - 0x2FFFFF)
; All remaining code and data including:
;   - PPORT command handler implementations
;   - HD file management routines
;   - UI configuration data
;   - Version information
;   - German language error messages
;   - Zero padding at end
; ============================================================================

HDAE5000_Code_2_PartB:			; 295642h
	binclude "includes/code_295642_2fffff.bin"

; ============================================================================
; END OF ROM
; ============================================================================

	end
