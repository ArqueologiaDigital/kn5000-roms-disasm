
	.text

	.include "shared/event_codes.s"

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
;   0x280020  HDAE5000_Handler_Registration - Handler registration entry (DISASSEMBLED)
;   0x28030E  HDAE5000_Get_Display_Dimensions_A1 - Memory allocation parameter check
;   0x28033B  HDAE5000_Get_Display_Width_1 - Utility routine
;   0x280368  HDAE5000_Get_Display_Width_2 - Utility routine
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
;   0x28F9AD  HDAE5000_Get_Display_Dimensions_A1_2F - Memory check routine
;   0x28F9EB  HDAE5000_Count_Invalid_Cells - Count invalid entries
;   0x28FA1E  HDAE5000_Calculate_Row_Address - Calculate address with 0x4C multiplier
;   0x28FA56  HDAE5000_Copy_Display_Cell - Copy table entry
;   0x28FAA0  HDAE5000_Calculate_Tile_Address - Calculate address with 0x90 multiplier
;   0x28FABA  HDAE5000_Copy_Display_Cell_90 - Copy 0x90-stride entry
;   0x28FAE9  HDAE5000_Validate_Cell_Coords - Check table entry validity
;   0x28FB26  HDAE5000_Resolve_Cell_Address - Get entry address with validation
;   0x28FBB1  HDAE5000_Cell_In_Bounds - Validate entry at coordinates
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
;   0x2967B4  HDAE5000_Render_Display_Region - Display utility
;   0x2967E4  HDAE5000_Render_Display_Region2 - Display utility 2
;   0x29AE9F  HDAE5000_MemCopy - Memory copy utility
;   0x29AFF0  HDAE5000_MemCopy_Reverse - Memory copy variant
;   0x29AFBE  HDAE5000_MemCompare_Block - Memory compare
;   0x29AF71  HDAE5000_Display_Buffer_Validate - Memory utility
;   0x29B72D  HDAE5000_Multiply - 32-bit multiply routine
;   0x2971A3  HDAE5000_Check_HD_Present - Hard disk presence detection
;   0x2999B0  HDAE5000_Version_Info - Version string block:
;                "Technics Software section    M. Kitajima"
;                Version "2.33J", "2.21", "TECHNICS KN5000"
;   0x29BFE0  HDAE5000_UI_Config - UI configuration strings
;   0x2BA1A6  HDAE5000_Font_Data - Font bitmap data (large block)
;   0x2E1C82  HDAE5000_Config_Strings - Configuration and version strings
;   0x2E21D8  HDAE5000_Test_Strings - PPORT test and debug strings
;   0x2E2500  HDAE5000_Dir_Strings - Directory management strings
;   0x2E2E76  HDAE5000_Char_Tables - Character set tables
;   0x2E348F  HDAE5000_Path_Strings - File path and config strings
;   0x2E365D  HDAE5000_UI_Icons - UI icon/pattern data with language IDs
;   0x2E3704  HDAE5000_Multilingual_Messages - Trilingual UI messages (EN/DE/FR)
;   0x2E5B80  HDAE5000_Lang_Codes - Language code strings and file types
;   0x2F8DCE  HDAE5000_Display_Params - File extensions, device names, config
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
; Hard Disk RAM Variables (0x229Dxx):
;   0x229D90  HD_STATUS_FLAG - Current drive status
;   0x229D92  HD_RESULT_FLAG - Last operation result (0=no HD, non-zero=present)
;   0x229D99  HD_CONFIG_START - Start of drive configuration flags
;   0x229DAE  HD_CONFIG_END - End of drive configuration flags
;   0x229DC8  HD_CONTROL_FLAG - Control register shadow
;   0x229DD9  HD_ENABLE_FLAG - Drive enabled flag
;   0x23A08E  HD_COMMAND_SHADOW - Shadow of last ATA command sent
;
; Hard Disk Interface:
;   The HD-AE5000 uses an IDE/ATA hard disk accessed via PPI bridge.
;   The disk uses CHS (Cylinder/Head/Sector) addressing.
;   Debug strings reveal parameters: hddtrck, hddhead, hddsctr, hddscby
;
; Filesystem Structures:
;   FSB - File System Block (master metadata)
;   FGB - File Group Block (file grouping)
;   FEB - File Entry Block (individual file metadata)
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


	.org 0x280000 - 0x280000, 0xFF

; ============================================================================
; ROM HEADER
; ============================================================================

HDAE5000_ROM_HEADER:
	.ascii "XAPR4"	; Magic identifier ("XAPR" checked by main CPU)
	.byte 0xa1	; Version byte
	.byte 0x2f, 0x00	; Unknown (possibly size/flags)

; Entry point 1 - Jump to boot initialization
HDAE5000_ENTRY_1:	; 280008h
	jp HDAE5000_Boot_Init	; Called when main CPU validates HDAE5000 presence

; Padding after vector
	ret
	nop
	nop
	nop

; Entry point 2 - Jump to frame handler (called periodically)
HDAE5000_ENTRY_2:	; 280010h
	jp HDAE5000_Frame_Handler	; Called from main loop for HD status updates

; Padding after vector
	ret
	nop
	nop
	nop

; Unused entry vectors (return immediately)
HDAE5000_ENTRY_3:	; 280018h
	ret
	nop
	nop
	nop

HDAE5000_ENTRY_4:	; 28001Ch
	ret
	nop
	nop
	nop

; ============================================================================
; CODE SECTION 1 (0x280020 - 0x28F575)
;
; Key routines:
;   0x280020  Handler_Registration - Register 11 handlers with main CPU workspace
;   0x28030E  Alloc_Memory_1 - Memory lookup (palette at 0x2A898E)
;   0x28033B  Alloc_Memory_2 - Memory lookup (palette at 0x2BB98E)
;   0x280368  Alloc_Memory_3 - Memory lookup (palette at 0x2CE98E)
;   0x280395  Alloc_Memory_4 - Memory lookup (palette at 0x2E198E, small display)
;   0x2803C2  Register_Frame - Register frame handler callback
;   0x28F543  Alloc_Memory - Primary memory lookup (palette at 0x2E61CE)
; ============================================================================

; ----------------------------------------------------------------------------
; HDAE5000_Handler_Registration (0x280020 - 0x28030D)
;
; Registers 11 callback handlers with the main CPU workspace dispatch system,
; plus a final special dispatch call via offset 0x0270.
; Called from HDAE5000_Boot_Init after workspace pointer is stored.
;
; The workspace dispatch system works via function tables:
;   WORKSPACE_PTR (0x23A1A2) -> Handler Table A (offset 0x0E0A)
;   Handler Table A + offset -> Function pointer or sub-table
;
; Registration structure (14 bytes on stack):
;   (XSP+0x00): PPI port address (identifies handler type)
;   (XSP+0x04): Handler function pointer (from workspace table)
;   (XSP+0x08): Data size (byte/word count)
;   (XSP+0x0A): Data pointer (RAM or ROM address)
;
; Handler Registration Table:
;   ID     Port        TableOff  Size   DataPtr    Description
;   0x016A 0x01600004  0x0168    13     0x29C0AA   DISK MENU / UI (13 sub-objects, ClassProc)
;   0x01CA 0x0160000C  0x013C    var    0x2397EA   RAM data area
;   0x01EA 0x0160000D  0x0140    var    0x239824   RAM data area
;   0x012A 0x01600002  0x0248    0x45   0x23952A   Init data copy dest
;   0x042A 0x01600002  0x0248    0x45   0x239642   Init data area
;   0x010A 0x01600001  0x0244    0x0D   0x239872   RAM data
;   0x040A 0x01600001  0x0244    0x0D   0x2398AA   RAM data
;   0x014A 0x01600003  0x024C    0x0E   0x239FD2   RAM data
;   0x044A 0x01600003  0x024C    0x0E   0x23A00E   RAM data
;   0x007F 0x01600010  0x0280    0x315  0x2A5D2C   ROM graphics data
;   0x037F 0x0160000F  0x0148    0x315  0x2A6984   ROM graphics data
;   (special call via 0x0270 with 0x2A849A and params 0x7F, 0x014A0000, 0x7F01EE)
;
; Each registration calls workspace[0x0E0A][0x00E4] with:
;   WA = handler ID
;   XBC = pointer to parameter block on stack
; ----------------------------------------------------------------------------

HDAE5000_Handler_Registration:	; 280020h
	; Allocate 14-byte parameter block on stack
	lda xsp, (xsp - 14)	; lda XSP, XSP - 0Eh  (allocate 14 bytes)

	; === Handler 1: DISK MENU / UI components (ID=0x016A, port=0x01600004) ===
	; Record count = 13 (from ROM at 0x29D97E)
	; Data table = 0x29C0AA (13 records x 24 bytes each)
	; Handler function = ClassProc (0xFA44E2) via workspace[0x0E0A][0x0168]
	ld xwa, 0x1600004	; PPI port address
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA  ; port address
	ldl_da xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)             ; Handler dispatch table
	ld_sril XWA, (xwa + 0x0168)             ; Handler function via table offset 0x0168
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA  ; handler function ptr
	ldw_da xwa, 0x29d97e
	ld (xsp + 8), wa	; ld (XSP+0x08), WA   ; record count (= 13)
	lda_24 xwa, 0x29c0aa
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA  ; data pointer
	lda xwa, (xsp)	; lda XWA, XSP  ; XWA = param block ptr
	ld xbc, xwa	; XBC = param block ptr
	ldl_da xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XHL, (xwa + 0x00e4)             ; RegisterObjectTable function
	ldw wa, 0x16A	; Handler ID
	call (xhl)	; Register handler

	; === Handler 2: RAM data area A (ID=0x01CA, port=0x0160000C) ===
	ld xwa, 0x160000C	; PPI port address
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ldl_da xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XWA, (xwa + 0x013c)             ; Handler function via table offset 0x013C
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldw_da xwa, 0x239822
	ld (xsp + 8), wa	; ld (XSP+0x08), WA   ; data size (variable)
	lda_24 xwa, 0x2397ea
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ldl_da xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XHL, (xwa + 0x00e4)             ; RegisterObjectTable
	ldw wa, 0x1CA	; Handler ID
	call (xhl)

	; === Handler 3: RAM data area B (ID=0x01EA, port=0x0160000D) ===
	ld xwa, 0x160000D	; PPI port address
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ldl_da xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XWA, (xwa + 0x0140)             ; Handler function via table offset 0x0140
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldw_da xwa, 0x239870
	ld (xsp + 8), wa	; ld (XSP+0x08), WA   ; data size (variable)
	lda_24 xwa, 0x239824
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ldl_da xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XHL, (xwa + 0x00e4)             ; RegisterObjectTable
	ldw wa, 0x1EA	; Handler ID
	call (xhl)

	; === Handler 4: Init data primary (ID=0x012A, port=0x01600002) ===
	ld xwa, 0x1600002	; PPI port address
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ldl_da xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XWA, (xwa + 0x0248)             ; Handler function via table offset 0x0248
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldw (xsp + 8), 0x45	; ld (XSP+0x08), 0045h  ; size = 69 bytes
	lda_24 xwa, 0x23952a
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ldl_da xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XHL, (xwa + 0x00e4)             ; RegisterObjectTable
	ldw wa, 0x12A	; Handler ID
	call (xhl)

	; === Handler 5: Init data secondary (ID=0x042A, port=0x01600002) ===
	ld xwa, 0x1600002	; PPI port address
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ldl_da xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XWA, (xwa + 0x0248)             ; Handler function via table offset 0x0248
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldw (xsp + 8), 0x45	; ld (XSP+0x08), 0045h  ; size = 69 bytes
	lda_24 xwa, 0x239642
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ldl_da xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XHL, (xwa + 0x00e4)             ; RegisterObjectTable
	ldw wa, 0x42A	; Handler ID
	call (xhl)

	; === Handler 6: Serial data primary (ID=0x010A, port=0x01600001) ===
	ld xwa, 0x1600001	; PPI port address
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ldl_da xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XWA, (xwa + 0x0244)             ; Handler function via table offset 0x0244
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldw (xsp + 8), 0xD	; ld (XSP+0x08), 000Dh  ; size = 13 bytes
	lda_24 xwa, 0x239872
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ldl_da xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XHL, (xwa + 0x00e4)             ; RegisterObjectTable
	ldw wa, 0x10A	; Handler ID
	call (xhl)

	; === Handler 7: Serial data secondary (ID=0x040A, port=0x01600001) ===
	ld xwa, 0x1600001	; PPI port address
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ldl_da xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XWA, (xwa + 0x0244)             ; Handler function via table offset 0x0244
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldw (xsp + 8), 0xD	; ld (XSP+0x08), 000Dh  ; size = 13 bytes
	lda_24 xwa, 0x2398aa
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ldl_da xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XHL, (xwa + 0x00e4)             ; RegisterObjectTable
	ldw wa, 0x40A	; Handler ID
	call (xhl)

	; === Handler 8: Parallel data primary (ID=0x014A, port=0x01600003) ===
	ld xwa, 0x1600003	; PPI port address
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ldl_da xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XWA, (xwa + 0x024c)             ; Handler function via table offset 0x024C
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldw (xsp + 8), 0xE	; ld (XSP+0x08), 000Eh  ; size = 14 bytes
	lda_24 xwa, 0x239fd2
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ldl_da xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XHL, (xwa + 0x00e4)             ; RegisterObjectTable
	ldw wa, 0x14A	; Handler ID
	call (xhl)

	; === Handler 9: Parallel data secondary (ID=0x044A, port=0x01600003) ===
	ld xwa, 0x1600003	; PPI port address
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ldl_da xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XWA, (xwa + 0x024c)             ; Handler function via table offset 0x024C
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldw (xsp + 8), 0xE	; ld (XSP+0x08), 000Eh  ; size = 14 bytes
	lda_24 xwa, 0x23a00e
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ldl_da xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XHL, (xwa + 0x00e4)             ; RegisterObjectTable
	ldw wa, 0x44A	; Handler ID
	call (xhl)

	; === Handler 10: Graphics data primary (ID=0x007F, port=0x01600010) ===
	ld xwa, 0x1600010	; PPI port address
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ldl_da xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XWA, (xwa + 0x0280)             ; Handler function via table offset 0x0280
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldw (xsp + 8), 0x315	; ld (XSP+0x08), 0315h  ; size = 789 bytes
	lda_24 xwa, 0x2a5d2c
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ldl_da xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XHL, (xwa + 0x00e4)             ; RegisterObjectTable
	ldw wa, 0x7F	; Handler ID
	call (xhl)

	; === Handler 11: Graphics data secondary (ID=0x037F, port=0x0160000F) ===
	ld xwa, 0x160000F	; PPI port address
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ldl_da xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XWA, (xwa + 0x0148)             ; Handler function via table offset 0x0148
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldw (xsp + 8), 0x315	; ld (XSP+0x08), 0315h  ; size = 789 bytes
	lda_24 xwa, 0x2a6984
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ldl_da xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XHL, (xwa + 0x00e4)             ; RegisterObjectTable
	ldw wa, 0x37F	; Handler ID
	call (xhl)

	; === Final special call via workspace dispatch offset 0x0270 ===
	; Passes additional parameters for graphics initialization
	pushw 0xA	; push 10 bytes (param size)
	lda_24 xwa, 0x2a849a
	push xwa	; push pointer to init params
	ldl_da xwa, 0x23a1a2
	ld_sril XWA, (xwa + 0x0e0a)
	ld_sril XHL, (xwa + 0x0270)             ; Special dispatch function
	ld xwa, 0x7F	; Graphics handler ID
	ld xbc, 0x14A0000	; Parallel data handler ref
	ld xde, 0x7F01EE	; Combined handler ID + flags
	call (xhl)

	; Deallocate parameter block + final call stack (14 bytes)
	lda xsp, (xsp + 14)	; lda XSP, XSP + 0Eh  (deallocate 14 bytes)
	ret

; ----------------------------------------------------------------------------
; Memory Allocation Parameter Lookup Routines (0x28030E - 0x2803C1)
;
; Four variants that return display parameters based on request type.
; Called by main CPU to get palette data pointers and display dimensions.
;
; Input: XBC = request type (0x01E000A1, 0x01E000A2, or 0x01E000A3)
; Output: XHL = result
;
; Each variant returns different palette data pointer for A1, but same
; dimensions for A2/A3 (except Alloc_Memory_4 which returns 0x1B for both).
; ----------------------------------------------------------------------------

HDAE5000_Alloc_Memory_1:	; 28030Eh
	; Returns 0x2A898E for A1, 0x140 for A2, 0xF0 for A3
	cp xbc, 0x1E000A3
	jr z, HDAE5000_Alloc_Memory_1__type_A3
	cp xbc, 0x1E000A2
	jr z, HDAE5000_Alloc_Memory_1__type_A2
	cp xbc, 0x1E000A1
	jr z, HDAE5000_Alloc_Memory_1__type_A1
	lds32 xhl, 0
	ret
HDAE5000_Alloc_Memory_1__type_A1:
	lda_24 xhl, 0x2a898e                  ; Palette data pointer 1
	ret
HDAE5000_Alloc_Memory_1__type_A2:
	ld xhl, 0x140	; 320 (width)
	ret
HDAE5000_Alloc_Memory_1__type_A3:
	ld xhl, 0xF0	; 240 (height)
	ret

HDAE5000_Alloc_Memory_2:	; 28033Bh
	; Returns 0x2BB98E for A1, 0x140 for A2, 0xF0 for A3
	cp xbc, 0x1E000A3
	jr z, HDAE5000_Alloc_Memory_2__type_A3
	cp xbc, 0x1E000A2
	jr z, HDAE5000_Alloc_Memory_2__type_A2
	cp xbc, 0x1E000A1
	jr z, HDAE5000_Alloc_Memory_2__type_A1
	lds32 xhl, 0
	ret
HDAE5000_Alloc_Memory_2__type_A1:
	lda_24 xhl, 0x2bb98e                  ; Palette data pointer 2
	ret
HDAE5000_Alloc_Memory_2__type_A2:
	ld xhl, 0x140	; 320 (width)
	ret
HDAE5000_Alloc_Memory_2__type_A3:
	ld xhl, 0xF0	; 240 (height)
	ret

HDAE5000_Alloc_Memory_3:	; 280368h
	; Returns 0x2CE98E for A1, 0x140 for A2, 0xF0 for A3
	cp xbc, 0x1E000A3
	jr z, HDAE5000_Alloc_Memory_3__type_A3
	cp xbc, 0x1E000A2
	jr z, HDAE5000_Alloc_Memory_3__type_A2
	cp xbc, 0x1E000A1
	jr z, HDAE5000_Alloc_Memory_3__type_A1
	lds32 xhl, 0
	ret
HDAE5000_Alloc_Memory_3__type_A1:
	lda_24 xhl, 0x2ce98e                  ; Palette data pointer 3
	ret
HDAE5000_Alloc_Memory_3__type_A2:
	ld xhl, 0x140	; 320 (width)
	ret
HDAE5000_Alloc_Memory_3__type_A3:
	ld xhl, 0xF0	; 240 (height)
	ret

HDAE5000_Alloc_Memory_4:	; 280395h
	; Returns 0x2E198E for A1, 0x1B for A2 and A3 (small display mode)
	cp xbc, 0x1E000A3
	jr z, HDAE5000_Alloc_Memory_4__type_A3
	cp xbc, 0x1E000A2
	jr z, HDAE5000_Alloc_Memory_4__type_A2
	cp xbc, 0x1E000A1
	jr z, HDAE5000_Alloc_Memory_4__type_A1
	lds32 xhl, 0
	ret
HDAE5000_Alloc_Memory_4__type_A1:
	lda_24 xhl, 0x2e198e                  ; Palette data pointer 4
	ret
HDAE5000_Alloc_Memory_4__type_A2:
	ld xhl, 0x1B	; 27 (small width)
	ret
HDAE5000_Alloc_Memory_4__type_A3:
	ld xhl, 0x1B	; 27 (small height)
	ret

; ============================================================================
; CODE SECTION 1: Setup, HD interface, filesystem, and UI routines
; 0x2803C2-0x28F542 (61,825 bytes, 64 identified routines)
;
; Hardware access:
;   PPI 8255 ports at 0x160000-0x160006 (IDE/ATA bridge to HD)
;   VGA registers via memory-mapped I/O
;   HD config flags at 0x229D90-0x229DAE
;   Workspace at 0x23A1A2 (shared with main CPU)
;
; Subsystem groups:
;   0x2803C2-0x2827F3  Frame registration and event dispatch (9,266 bytes)
;   0x2827F4-0x282B97  Event handler (932 bytes)
;   0x282B98-0x282E3B  PPI/IDE low-level I/O (1,188 bytes)
;   0x282E8D-0x28541B  HD drive setup and configuration (9,615 bytes)
;   0x28541C-0x287054  HD config manager and CHS geometry (7,225 bytes)
;   0x2870D6-0x28A2EF  Filesystem operations (12,826 bytes)
;   0x28A2F0-0x28B3E9  Display, menu, and utility routines (4,346 bytes)
;   0x28B3EA-0x28F542  UI handler, file ops, path/string utilities (16,857 bytes)
; ============================================================================

HDAE5000_Register_Frame:	; 0x2803C2 (9266 bytes)
; LRF: 0x2803C2 (9266 bytes)

	stiw_da	0x23A08E, 0
	stiw_da	0x23A092, 0
	stiw_da	0x23A094, 0
	ld	xiy, 0x002e1ca2
	ld	xix, 0x0022aa58
	lds	bc, 5
	ldirw                                   ; ldirw
	ld	xiy, 0x002e1c96
	ld	xix, 0x0022aa4c
	lds	bc, 6
	ldirw                                   ; ldirw
	stiw_da	0x22AA4C, 511
	ldw_da	wa, 0x23A092
	ldw_da	bc, 0x23A094
	call HDAE5000_Table_Lookup
	ld	wa, hl
	cp	wa, 0xffff
	jr z, .LRF_0424                        ; [66 14] jr Z,0x280424
	lda_24 xwa, 0x22aa4c
	pushw 0x0002
	ld	bc, hl
	lda_24 xde, 0x2e1c96
	calr	0x4ec2
	jr t, .LRF_0436                        ; [68 12] jr T,0x280436
.LRF_0424:
	lda_24 xwa, 0x22aa4c
	pushw 0x0002
	lda_24 xde, 0x2e1c96
	lds	bc, 0
	calr	0x4eae
.LRF_0436:
	lds	wa, 1
	jp HDAE5000_Set_Menu_Visibility                             ; jp 0x28b258
	dec 0, xsp                              ; dec 0,XSP
	push xiz
	ld (xsp + 0x04), xde                    ; ld (XSP+0x04),XDE
	ld (xsp + 0x08), xbc                    ; ld (XSP+0x08),XBC
	ld	xiz, xwa
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	cp	xwa, 0x01c00001
	jr nz, .LRF_046c                       ; [6e 1a] jr NZ,0x28046c
	ld	xwa, xiz
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01e0007f
	lds32	xde, 1
	call	(xhl)
.LRF_046c:
	ld	xwa, xiz
	ld xbc, (xsp + 0x08)                    ; ld XBC,(XSP+0x08)
	ld xde, (xsp + 0x04)                    ; ld XDE,(XSP+0x04)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xix, (xhl + 0x00dc)
	call	(xix)
	pop xiz                                 ; pop XIZ
	inc 0, xsp                              ; inc 0,XSP
	ret

	dec 0, xsp                              ; dec 0,XSP
	push xiz
	ld (xsp + 0x04), xde                    ; ld (XSP+0x04),XDE
	ld	xiz, xbc
	ld (xsp + 0x08), xwa                    ; ld (XSP+0x08),XWA
	ld	xwa, xiz
	cp	xwa, 0x01c00002
	jrl z, .LRF_0537                       ; [76 98 00] jrl Z,0x280537
	cp	xwa, 0x01c0000d
	jrl nz, .LRF_054a                      ; [7e a2 00] jrl NZ,0x28054a
	lds32	xwa, 0
	ld	xbc, 0x01e000a1
	lds32	xde, 0
	calr	0xfe5a
	or xhl, xhl                             ; or XHL,XHL
	jr z, .LRF_051a                        ; [66 62] jr Z,0x28051a
	pushw 0x9600
	lda_24 xwa, 0x2a898e
	push xwa
	ld	xwa, 0x00056800
	push xwa
	call HDAE5000_MemCopy
	pushw 0x9600
	lda_24 xwa, 0x2b1f8e
	push xwa
	ld	xwa, 0x0005fe00
	push xwa
	call HDAE5000_MemCopy
	pushw 0x0400
	lda_24 xwa, 0x2a858e
	push xwa
	ld	xwa, 0x00069400
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+30)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x013c)
	lds	wa, 3
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0138)
	lds	wa, 3
	call	(xhl)
.LRF_051a:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	xbc, xiz
	ld xde, (xsp + 0x04)                    ; ld XDE,(XSP+0x04)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	lds32	xhl, 0
	jr t, .LRF_0563                        ; [68 2c] jr T,0x280563
.LRF_0537:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0138)
	lds	wa, 2
	call	(xhl)
.LRF_054a:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	xbc, xiz
	ld xde, (xsp + 0x04)                    ; ld XDE,(XSP+0x04)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xix, (xhl + 0x00dc)
	call	(xix)
.LRF_0563:
	pop xiz                                 ; pop XIZ
	inc 0, xsp                              ; inc 0,XSP
	ret

	dec 0, xsp                              ; dec 0,XSP
	push xiz
	ld (xsp + 0x04), xde                    ; ld (XSP+0x04),XDE
	ld	xiz, xbc
	ld (xsp + 0x08), xwa                    ; ld (XSP+0x08),XWA
	ld	xwa, xiz
	cp	xwa, 0x01c00002
	jrl z, .LRF_0615                       ; [76 98 00] jrl Z,0x280615
	cp	xwa, 0x01c0000d
	jrl nz, .LRF_0628                      ; [7e a2 00] jrl NZ,0x280628
	lds32	xwa, 0
	ld	xbc, 0x01e000a1
	lds32	xde, 0
	calr	0xfda9
	or xhl, xhl                             ; or XHL,XHL
	jr z, .LRF_05f8                        ; [66 62] jr Z,0x2805f8
	pushw 0x9600
	lda_24 xwa, 0x2bb98e
	push xwa
	ld	xwa, 0x00056800
	push xwa
	call HDAE5000_MemCopy
	pushw 0x9600
	lda_24 xwa, 0x2c4f8e
	push xwa
	ld	xwa, 0x0005fe00
	push xwa
	call HDAE5000_MemCopy
	pushw 0x0400
	lda_24 xwa, 0x2bb58e
	push xwa
	ld	xwa, 0x00069400
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+30)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x013c)
	lds	wa, 3
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0138)
	lds	wa, 3
	call	(xhl)
.LRF_05f8:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	xbc, xiz
	ld xde, (xsp + 0x04)                    ; ld XDE,(XSP+0x04)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	lds32	xhl, 0
	jr t, .LRF_0641                        ; [68 2c] jr T,0x280641
.LRF_0615:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0138)
	lds	wa, 2
	call	(xhl)
.LRF_0628:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	xbc, xiz
	ld xde, (xsp + 0x04)                    ; ld XDE,(XSP+0x04)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xix, (xhl + 0x00dc)
	call	(xix)
.LRF_0641:
	pop xiz                                 ; pop XIZ
	inc 0, xsp                              ; inc 0,XSP
	ret

	dec 0, xsp                              ; dec 0,XSP
	push xiz
	ld (xsp + 0x04), xde                    ; ld (XSP+0x04),XDE
	ld	xiz, xbc
	ld (xsp + 0x08), xwa                    ; ld (XSP+0x08),XWA
	ld	xwa, xiz
	cp	xwa, 0x01c00002
	jrl z, .LRF_06f3                       ; [76 98 00] jrl Z,0x2806f3
	cp	xwa, 0x01c0000d
	jrl nz, .LRF_0706                      ; [7e a2 00] jrl NZ,0x280706
	lds32	xwa, 0
	ld	xbc, 0x01e000a1
	lds32	xde, 0
	calr	0xfcf8
	or xhl, xhl                             ; or XHL,XHL
	jr z, .LRF_06d6                        ; [66 62] jr Z,0x2806d6
	pushw 0x9600
	lda_24 xwa, 0x2ce98e
	push xwa
	ld	xwa, 0x00056800
	push xwa
	call HDAE5000_MemCopy
	pushw 0x9600
	lda_24 xwa, 0x2d7f8e
	push xwa
	ld	xwa, 0x0005fe00
	push xwa
	call HDAE5000_MemCopy
	pushw 0x0400
	lda_24 xwa, 0x2ce58e
	push xwa
	ld	xwa, 0x00069400
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+30)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x013c)
	lds	wa, 3
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0138)
	lds	wa, 3
	call	(xhl)
.LRF_06d6:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	xbc, xiz
	ld xde, (xsp + 0x04)                    ; ld XDE,(XSP+0x04)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	lds32	xhl, 0
	jr t, .LRF_071f                        ; [68 2c] jr T,0x28071f
.LRF_06f3:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0138)
	lds	wa, 2
	call	(xhl)
.LRF_0706:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	xbc, xiz
	ld xde, (xsp + 0x04)                    ; ld XDE,(XSP+0x04)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xix, (xhl + 0x00dc)
	call	(xix)
.LRF_071f:
	pop xiz                                 ; pop XIZ
	inc 0, xsp                              ; inc 0,XSP
	ret

	dec 0, xsp                              ; dec 0,XSP
	push xiz
	ld (xsp + 0x04), xde                    ; ld (XSP+0x04),XDE
	ld	xiz, xbc
	ld (xsp + 0x08), xwa                    ; ld (XSP+0x08),XWA
	ld	xwa, xiz
	cp	xwa, 0x01c00002
	jr z, .LRF_07a9                        ; [66 71] jr Z,0x2807a9
	cp	xwa, 0x01c0000d
	jr nz, .LRF_07bc                       ; [6e 7c] jr NZ,0x2807bc
	lds32	xwa, 0
	ld	xbc, 0x01e000a1
	lds32	xde, 0
	calr	0xfbef
	or xhl, xhl                             ; or XHL,XHL
	jr z, .LRF_078c                        ; [66 3c] jr Z,0x28078c
	pushw 0x0400
	lda_24 xwa, 0x2bb58e
	push xwa
	ld	xwa, 0x00069400
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+10)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x013c)
	lds	wa, 3
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0138)
	lds	wa, 3
	call	(xhl)
.LRF_078c:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	xbc, xiz
	ld xde, (xsp + 0x04)                    ; ld XDE,(XSP+0x04)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	lds32	xhl, 0
	jr t, .LRF_07d5                        ; [68 2c] jr T,0x2807d5
.LRF_07a9:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e88)
	ld_sril	xhl, (xwa + 0x0138)
	lds	wa, 2
	call	(xhl)
.LRF_07bc:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	xbc, xiz
	ld xde, (xsp + 0x04)                    ; ld XDE,(XSP+0x04)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xix, (xhl + 0x00dc)
	call	(xix)
.LRF_07d5:
	pop xiz                                 ; pop XIZ
	inc 0, xsp                              ; inc 0,XSP
	ret

	lda	xsp, (xsp-104)
	push xiz
	ld (xsp + 0x60), xde                    ; ld (XSP+0x60),XDE
	ld (xsp + 0x64), xbc                    ; ld (XSP+0x64),XBC
	ld (xsp + 0x68), xwa                    ; ld (XSP+0x68),XWA
	ld xwa, (xsp + 0x64)                    ; ld XWA,(XSP+0x64)
	cp	xwa, 0x01ca0002
	jrl z, .LRF_11d8                       ; [76 e6 09] jrl Z,0x2811d8
	cp	xwa, 0x01ca0001
	jrl z, .LRF_11d8                       ; [76 dd 09] jrl Z,0x2811d8
	cp	xwa, 0x01ca0000
	jrl z, .LRF_11d8                       ; [76 d4 09] jrl Z,0x2811d8
	cp	xwa, 0x01c00018
	jrl z, .LRF_0f6a                       ; [76 5d 07] jrl Z,0x280f6a
	cp	xwa, 0x01c0001a
	jrl z, .LRF_0f6a                       ; [76 54 07] jrl Z,0x280f6a
	cp	xwa, 0x01c00017
	jrl z, .LRF_0f6a                       ; [76 4b 07] jrl Z,0x280f6a
	cp	xwa, 0x01c00019
	jrl z, .LRF_0f6a                       ; [76 42 07] jrl Z,0x280f6a
	cp	xwa, 0x01ea000a
	jrl z, .LRF_0f44                       ; [76 13 07] jrl Z,0x280f44
	cp	xwa, 0x01ea0004
	jrl z, .LRF_0f03                       ; [76 c9 06] jrl Z,0x280f03
	cp	xwa, 0x01ea0003
	jrl z, .LRF_0e6d                       ; [76 2a 06] jrl Z,0x280e6d
	cp	xwa, 0x01ea0002
	jrl z, .LRF_0dcc                       ; [76 80 05] jrl Z,0x280dcc
	cp	xwa, 0x01c0000f
	jrl z, .LRF_0a91                       ; [76 3c 02] jrl Z,0x280a91
	cp	xwa, 0x01c0000b
	jrl z, .LRF_09a4                       ; [76 46 01] jrl Z,0x2809a4
	cp	xwa, 0x01c00002
	jrl z, .LRF_0965                       ; [76 fe 00] jrl Z,0x280965
	cp	xwa, 0x01c00001
	jr z, .LRF_08b5                        ; [66 46] jr Z,0x2808b5
	cp	xwa, 0x01c0000d
	jrl nz, .LRF_120b                      ; [7e 93 09] jrl NZ,0x28120b
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld xbc, (xsp + 0x64)                    ; ld XBC,(XSP+0x64)
	ld xde, (xsp + 0x60)                    ; ld XDE,(XSP+0x60)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000f
	ld	xde, 0xffffffff
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LRF_1225                       ; [78 70 09] jrl T,0x281225
.LRF_08b5:
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld xbc, (xsp + 0x64)                    ; ld XBC,(XSP+0x64)
	ld xde, (xsp + 0x60)                    ; ld XDE,(XSP+0x60)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x02c4)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	ld	xwa, xhl
	ld xwa, (xwa + 0x36)                    ; ld XWA,(XWA+0x36)
	ldw	(xwa), 0x0001
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	cpw	(xwa+50), 0x0000
	jr z, .LRF_0942                        ; [66 49] jr Z,0x280942
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x03c8)
	ld	xbc, 0x01c00018
	lds32	xde, 0
	call	(xhl)
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x03cc)
	ld	xbc, 0x01c00017
	lds32	xde, 0
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x03c4)
	lds	wa, 1
	call	(xhl)
.LRF_0942:
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0254)
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LRF_1225                       ; [78 c0 08] jrl T,0x281225
.LRF_0965:
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld xbc, (xsp + 0x64)                    ; ld XBC,(XSP+0x64)
	ld xde, (xsp + 0x60)                    ; ld XDE,(XSP+0x60)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x02c4)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	ld	xwa, xhl
	ld xwa, (xwa + 0x36)                    ; ld XWA,(XWA+0x36)
	ldw	(xwa), 0x0000
	lds32	xhl, 0
	jrl t, .LRF_1225                       ; [78 81 08] jrl T,0x281225
.LRF_09a4:
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld xbc, (xsp + 0x64)                    ; ld XBC,(XSP+0x64)
	ld xde, (xsp + 0x60)                    ; ld XDE,(XSP+0x60)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x02c4)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	ld	xwa, xhl
	cpw	(xwa+42), 0x0002
	jrl lt, .LRF_0a8c                      ; [71 ad 00] jrl LT,0x280a8c
	lda	xwa, (xsp+80)
	ld	xbc, xwa
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e0a)
	ld_sril	xhl, (xde + 0x02d4)
	call	(xhl)
	ld	bc, (xsp+84)
	sub	bc, (xsp+80)
	exts xbc                                ; exts XBC
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	divs16_rid8 xwa, 0x2a, bc		; divs XBC,(XWA+0x2a)
	ld (xsp + 0x0c), bc
	ld	wa, (xsp+82)
	inc	1, wa
	ld (xsp + 0x5e), wa                     ; ld (XSP+0x5e),WA
	ld	wa, (xsp+86)
	dec	1, wa
	ld (xsp + 0x5a), wa                     ; ld (XSP+0x5a),WA
	ldw (xsp + 0x08), 1
	jr t, .LRF_0a81                        ; [68 61] jr T,0x280a81
.LRF_0a20:
	ld	wa, (xsp+12)
	mul16_rid8 xsp, 0x08, wa		; mul XWA,(XSP+0x08)
	ld	bc, (xsp+80)
	add	bc, wa
	dec	1, bc
	ld (xsp + 0x5c), bc
	ld (xsp + 0x58), bc
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	cpw	(xwa+22), 0x0007
	jr nz, .LRF_0a5f                       ; [6e 22] jr NZ,0x280a5f
	lda	xwa, (xsp+92)
	ld	xde, xwa
	lda	xwa, (xsp+88)
	ld	xbc, xwa
	ld	xwa, xde
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e0a)
	ld_sril	xhl, (xde + 0x009c)
	ldw	de, 0x00ff
	call	(xhl)
	jr t, .LRF_0a7e                        ; [68 1f] jr T,0x280a7e
.LRF_0a5f:
	lda	xwa, (xsp+92)
	ld	xde, xwa
	lda	xwa, (xsp+88)
	ld	xbc, xwa
	ld	xwa, xde
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e0a)
	ld_sril	xhl, (xde + 0x009c)
	lds	de, 7
	call	(xhl)
.LRF_0a7e:
	incm	1, (xsp+8)
.LRF_0a81:
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld	wa, (xwa+42)
	cp	(xsp+8), wa
	jr c, .LRF_0a20                        ; [67 94] jr C,0x280a20
.LRF_0a8c:
	lds32	xhl, 0
	jrl t, .LRF_1225                       ; [78 94 07] jrl T,0x281225
.LRF_0a91:
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x02c4)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	ld	xwa, xhl
	ld xwa, (xwa + 0x26)                    ; ld XWA,(XWA+0x26)
	ld xwa, (xwa)                           ; ld XWA,(XWA)
	or xwa, xwa                             ; or XWA,XWA
	jr nz, .LRF_0abd                       ; [6e 0a] jr NZ,0x280abd
	ld	xwa, (0x2e1e4c)
	ld (xsp + 0x10), xwa                    ; ld (XSP+0x10),XWA
	jr t, .LRF_0ac8                        ; [68 0b] jr T,0x280ac8
.LRF_0abd:
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x26)                    ; ld XWA,(XWA+0x26)
	ld xwa, (xwa)                           ; ld XWA,(XWA)
	ld (xsp + 0x10), xwa                    ; ld (XSP+0x10),XWA
.LRF_0ac8:
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x36)                    ; ld XWA,(XWA+0x36)
	cpw	(xwa), 0x0001
	jr z, .LRF_0ad9                        ; [66 05] jr Z,0x280ad9
	lds32	xhl, 0
	jrl t, .LRF_1225                       ; [78 4c 07] jrl T,0x281225
.LRF_0ad9:
	lda	xwa, (xsp+80)
	ld	xbc, xwa
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e0a)
	ld_sril	xhl, (xde + 0x02d4)
	call	(xhl)
	ld	bc, (xsp+84)
	sub	bc, (xsp+80)
	exts xbc                                ; exts XBC
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	divs16_rid8 xwa, 0x2a, bc		; divs XBC,(XWA+0x2a)
	ld (xsp + 0x0c), bc
	ld	bc, (xsp+86)
	sub	bc, (xsp+82)
	exts xbc                                ; exts XBC
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	divs16_rid8 xwa, 0x2c, bc		; divs XBC,(XWA+0x2c)
	ld (xsp + 0x0e), bc
	ldw (xsp + 0x08), 0
	ldw (xsp + 0x0a), 0
	ldw (xsp + 0x14), 0
	jrl t, .LRF_0db5                       ; [78 8f 02] jrl T,0x280db5
.LRF_0b26:
	ld	(xsp+22), 0x00
	jr t, .LRF_0b6c                        ; [68 40] jr T,0x280b6c
.LRF_0b2c:
	ld	wa, (xsp+10)
	extz xwa
	add	xwa, (xsp+16)
	cp	(xwa), 0x09
	jr nz, .LRF_0b4f                       ; [6e 16] jr NZ,0x280b4f
	lda	xbc, (xsp+22)
	ld	wa, (xsp+20)
	stib_ind 0x07, 0xE4, 0xE0, 0x00	; ld (XBC+WA),0x00
	incm	1, (xsp+10)
	ldw (xsp + 0x14), 0
	jr t, .LRF_0b79                        ; [68 2a] jr T,0x280b79
.LRF_0b4f:
	lda	xde, (xsp+22)
	ld	wa, (xsp+10)
	extz xwa
	ld	xbc, xwa
	add	xbc, (xsp+16)
	ld	wa, (xsp+20)
	ld	c, (xbc)
	lda_dri xhl, 0x07, 0xE8, 0xE0	; ld (XDE+WA),C
	incm	1, (xsp+20)
	incm	1, (xsp+10)
.LRF_0b6c:
	ld	wa, (xsp+10)
	extz xwa
	add	xwa, (xsp+16)
	cp	(xwa), 0x00
	jr nz, .LRF_0b2c                       ; [6e b3] jr NZ,0x280b2c
.LRF_0b79:
	ld xwa, (xsp + 0x60)                    ; ld XWA,(XSP+0x60)
	cp	xwa, 0xffffffff
	jr z, .LRF_0b91                        ; [66 0d] jr Z,0x280b91
	ld	wa, (xsp+8)
	extz xwa
	ld xbc, (xsp + 0x60)                    ; ld XBC,(XSP+0x60)
	cp	xbc, xwa
	jrl nz, .LRF_0db2                      ; [7e 21 02] jrl NZ,0x280db2
.LRF_0b91:
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld	bc, (xwa+44)
	ld	wa, (xsp+8)
	extz xwa
	div	xwa, xbc
	ld	hl, qwa
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld	bc, (xwa+44)
	ld	wa, (xsp+8)
	extz xwa
	div	xwa, xbc
	ld	de, wa
	ld	wa, (xsp+14)
	mul	xwa, xhl
	ld	bc, (xsp+82)
	add	bc, wa
	inc	1, bc
	ld (xsp + 0x4a), bc
	ld	wa, bc
	add	wa, (xsp+14)
	dec	1, wa
	ld (xsp + 0x4e), wa                     ; ld (XSP+0x4e),WA
	ld	wa, (xsp+12)
	mul	xwa, xde
	ld	bc, (xsp+80)
	add	bc, wa
	inc	1, bc
	ld (xsp + 0x48), bc
	ld	wa, bc
	add	wa, (xsp+12)
	dec	4, wa
	ld (xsp + 0x4c), wa                     ; ld (XSP+0x4c),WA
	ld	wa, (xsp+72)
	ld (xsp + 0x5c), wa                     ; ld (XSP+0x5c),WA
	ld	wa, (xsp+14)
	srl	wa, 0x01
	ld	bc, (xsp+74)
	add	bc, wa
	ld (xsp + 0x5e), bc
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x1c)                    ; ld XWA,(XWA+0x1c)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0154)
	call	(xhl)
	ld	iz, hl
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x1c)                    ; ld XWA,(XWA+0x1c)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x0150)
	call	(xix)
	sub	hl, iz
	ld	wa, hl
	neg	wa
	exts xwa                                ; exts XWA
	divs	wa, 0x0002
	ld	iz, wa
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x1c)                    ; ld XWA,(XWA+0x1c)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x0158)
	call	(xix)
	add	hl, iz
	add	(xsp+94), hl
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	wa, (xwa)
	cp	wa, (xsp+8)
	jrl nz, .LRF_0d14                      ; [7e b6 00] jrl NZ,0x280d14
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	cpw	(xwa+58), 0x0000
	jr nz, .LRF_0cb1                       ; [6e 49] jr NZ,0x280cb1
	lda	xwa, (xsp+72)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x00a4)
	ldw	bc, 0x00ff
	call	(xhl)
	lda	xwa, (xsp+72)
	ld	xhl, xwa
	lda	xwa, (xsp+92)
	ld	xbc, xwa
	lda	xwa, (xsp+22)
	ld	xde, xwa
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x1c)                    ; ld XWA,(XWA+0x1c)
	push xwa
	pushw 0x0000
	pushw 0x00f7
	ld	xwa, xhl
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00c4)
	call	(xhl)
	jrl t, .LRF_0db2                       ; [78 01 01] jrl T,0x280db2
.LRF_0cb1:
	lda	xwa, (xsp+72)
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	bc, (xbc+22)
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e0a)
	ld_sril	xhl, (xde + 0x00a4)
	call	(xhl)
	lda	xhl, (xsp+72)
	lda	xbc, (xsp+92)
	lda	xde, (xsp+22)
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x1c)                    ; ld XWA,(XWA+0x1c)
	push xwa
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	pushm	(xwa+32)
	ld xwa, (xsp + 0x0a)                    ; ld XWA,(XSP+0x0a)
	pushm	(xwa+22)
	ld	xwa, xhl
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00c4)
	call	(xhl)
	lda	xwa, (xsp+72)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x00a8)
	ldw	bc, 0x00f2
	call	(xhl)
	jrl t, .LRF_0db2                       ; [78 9e 00] jrl T,0x280db2
.LRF_0d14:
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	cpw	(xwa+58), 0x0000
	jr nz, .LRF_0d69                       ; [6e 4b] jr NZ,0x280d69
	lda	xwa, (xsp+72)
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	bc, (xbc+22)
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e0a)
	ld_sril	xhl, (xde + 0x00a4)
	call	(xhl)
	lda	xhl, (xsp+72)
	lda	xbc, (xsp+92)
	lda	xde, (xsp+22)
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x1c)                    ; ld XWA,(XWA+0x1c)
	push xwa
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	pushm	(xwa+32)
	ld xwa, (xsp + 0x0a)                    ; ld XWA,(XSP+0x0a)
	pushm	(xwa+22)
	ld	xwa, xhl
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00c4)
	call	(xhl)
	jr t, .LRF_0db2                        ; [68 49] jr T,0x280db2
.LRF_0d69:
	lda	xwa, (xsp+72)
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	bc, (xbc+22)
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e0a)
	ld_sril	xhl, (xde + 0x00a4)
	call	(xhl)
	lda	xhl, (xsp+72)
	lda	xbc, (xsp+92)
	lda	xde, (xsp+22)
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x1c)                    ; ld XWA,(XWA+0x1c)
	push xwa
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	pushm	(xwa+32)
	ld xwa, (xsp + 0x0a)                    ; ld XWA,(XSP+0x0a)
	pushm	(xwa+22)
	ld	xwa, xhl
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00c4)
	call	(xhl)
.LRF_0db2:
	incm	1, (xsp+8)
.LRF_0db5:
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld	bc, (xwa+42)
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	muls16_rid8 xwa, 0x2c, bc		; muls XBC,(XWA+0x2c)
	cp	(xsp+8), bc
	jrl c, .LRF_0b26                       ; [77 5f fd] jrl C,0x280b26
	lds32	xhl, 0
	jrl t, .LRF_1225                       ; [78 59 04] jrl T,0x281225
.LRF_0dcc:
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x02c4)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	ld	xwa, xhl
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	de, (xwa)
	ld xwa, (xsp + 0x60)                    ; ld XWA,(XSP+0x60)
	add	de, wa
	jr ge, .LRF_0e15                       ; [69 24] jr GE,0x280e15
	ld	bc, de
	exts xbc                                ; exts XBC
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0254)
	ld	xbc, 0x01ea0001
	call	(xhl)
	jr t, .LRF_0e68                        ; [68 53] jr T,0x280e68
.LRF_0e15:
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld	bc, (xwa+44)
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	muls16_rid8 xwa, 0x2a, bc		; muls XBC,(XWA+0x2a)
	cp	de, bc
	jr lt, .LRF_0e49                       ; [61 24] jr LT,0x280e49
	ld	bc, de
	exts xbc                                ; exts XBC
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0254)
	ld	xbc, 0x01ea0000
	call	(xhl)
	jr t, .LRF_0e68                        ; [68 1f] jr T,0x280e68
.LRF_0e49:
	ld	bc, de
	exts xbc                                ; exts XBC
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01ea0003
	call	(xhl)
.LRF_0e68:
	lds32	xhl, 0
	jrl t, .LRF_1225                       ; [78 b8 03] jrl T,0x281225
.LRF_0e6d:
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x02c4)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	ld	xwa, xhl
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	de, (xwa)
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xbc, (xwa + 0x2e)                    ; ld XBC,(XWA+0x2e)
	ld xwa, (xsp + 0x60)                    ; ld XWA,(XSP+0x60)
	ld (xbc), wa                            ; ld (XBC),WA
	ld	bc, de
	exts xbc                                ; exts XBC
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000f
	call	(xhl)
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	de, (xwa)
	exts xde                                ; exts XDE
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000f
	call	(xhl)
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	de, (xwa)
	exts xde                                ; exts XDE
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0254)
	ld	xbc, 0x01ea0002
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LRF_1225                       ; [78 22 03] jrl T,0x281225
.LRF_0f03:
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x02c4)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	ld	xwa, xhl
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	de, (xwa)
	exts xde                                ; exts XDE
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0254)
	ld	xbc, 0x01ea0005
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LRF_1225                       ; [78 e1 02] jrl T,0x281225
.LRF_0f44:
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x02c4)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	ld	xwa, xhl
	ld xbc, (xwa + 0x26)                    ; ld XBC,(XWA+0x26)
	ld xwa, (xsp + 0x60)                    ; ld XWA,(XSP+0x60)
	ld (xbc), xwa                           ; ld (XBC),XWA
	lds32	xhl, 0
	jrl t, .LRF_1225                       ; [78 bb 02] jrl T,0x281225
.LRF_0f6a:
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld xbc, (xsp + 0x64)                    ; ld XBC,(XSP+0x64)
	ld xde, (xsp + 0x60)                    ; ld XDE,(XSP+0x60)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	lds	wa, 0
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01e00051
	lds32	xde, 0
	call	(xhl)
	ld	xiz, xhl
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x02c4)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	cp	(xsp+96), xiz
	jrl nz, .LRF_1077                      ; [7e b7 00] jrl NZ,0x281077
	ld xwa, (xsp + 0x64)                    ; ld XWA,(XSP+0x64)
	cp	xwa, 0x01c00017
	jr z, .LRF_0fd4                        ; [66 09] jr Z,0x280fd4
	cp	xwa, 0x01c00019
	jrl nz, .LRF_1072                      ; [7e 9e 00] jrl NZ,0x281072
.LRF_0fd4:
	ldw	wa, 0xffff
.LRF_0fd7:
	ld	bc, wa
	exts xbc                                ; exts XBC
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01ea0002
	call	(xhl)
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	cpw	(xwa+52), 0x0000
	jr z, .LRF_101a                        ; [66 1a] jr Z,0x28101a
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld xbc, (xsp + 0x64)                    ; ld XBC,(XSP+0x64)
	ld xde, (xsp + 0x60)                    ; ld XDE,(XSP+0x60)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x042c)
	call	(xhl)
.LRF_101a:
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	cpw	(xwa+50), 0x0000
	jr z, .LRF_106d                        ; [66 49] jr Z,0x28106d
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xde, xiz
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x03c8)
	ld	xbc, 0x01c00018
	call	(xhl)
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xde, xiz
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x03cc)
	ld	xbc, 0x01c00017
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x03c4)
	lds	wa, 1
	call	(xhl)
.LRF_106d:
	lds32	xhl, 0
	jrl t, .LRF_1225                       ; [78 b3 01] jrl T,0x281225
.LRF_1072:
	lds	wa, 1
	jrl t, .LRF_0fd7                       ; [78 60 ff] jrl T,0x280fd7
.LRF_1077:
	ld	xwa, xiz
	inc 1, xwa                              ; inc 1,XWA
	cp	xwa, (xsp+96)
	jr nz, .LRF_1089                       ; [6e 09] jr NZ,0x281089
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld	wa, (xwa+44)
	jrl t, .LRF_0fd7                       ; [78 4e ff] jrl T,0x280fd7
.LRF_1089:
	ld	xwa, xiz
	inc 2, xwa                              ; inc 2,XWA
	cp	xwa, (xsp+96)
	jr nz, .LRF_109d                       ; [6e 0b] jr NZ,0x28109d
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld	wa, (xwa+44)
	neg	wa
	jrl t, .LRF_0fd7                       ; [78 3a ff] jrl T,0x280fd7
.LRF_109d:
	ld	xwa, xiz
	inc	3, xwa
	cp	xwa, (xsp+96)
	jr nz, .LRF_10d1                       ; [6e 2b] jr NZ,0x2810d1
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	de, (xwa)
	exts xde                                ; exts XDE
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0254)
	ld	xbc, 0x01ea0006
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LRF_1225                       ; [78 54 01] jrl T,0x281225
.LRF_10d1:
	ld	xwa, xiz
	inc 4, xwa                              ; inc 4,XWA
	cp	xwa, (xsp+96)
	jr nz, .LRF_1105                       ; [6e 2b] jr NZ,0x281105
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	de, (xwa)
	exts xde                                ; exts XDE
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0254)
	ld	xbc, 0x01ea0008
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LRF_1225                       ; [78 20 01] jrl T,0x281225
.LRF_1105:
	ld	xwa, xiz
	inc	5, xwa
	cp	xwa, (xsp+96)
	jr nz, .LRF_1139                       ; [6e 2b] jr NZ,0x281139
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	de, (xwa)
	exts xde                                ; exts XDE
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0254)
	ld	xbc, 0x01ea000d
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LRF_1225                       ; [78 ec 00] jrl T,0x281225
.LRF_1139:
	ld	xwa, xiz
	inc	6, xwa
	cp	xwa, (xsp+96)
	jr nz, .LRF_116d                       ; [6e 2b] jr NZ,0x28116d
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	de, (xwa)
	exts xde                                ; exts XDE
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0254)
	ld	xbc, 0x01ea0007
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LRF_1225                       ; [78 b8 00] jrl T,0x281225
.LRF_116d:
	ld	xwa, xiz
	inc	7, xwa
	cp	xwa, (xsp+96)
	jr nz, .LRF_11a1                       ; [6e 2b] jr NZ,0x2811a1
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	de, (xwa)
	exts xde                                ; exts XDE
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0254)
	ld	xbc, 0x01ea000c
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LRF_1225                       ; [78 84 00] jrl T,0x281225
.LRF_11a1:
	ld	xwa, xiz
	inc 0, xwa		; inc 0,XWA
	cp	xwa, (xsp+96)
	jr nz, .LRF_11d4                       ; [6e 2a] jr NZ,0x2811d4
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	de, (xwa)
	exts xde                                ; exts XDE
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0254)
	ld	xbc, 0x01ea0009
	call	(xhl)
	lds32	xhl, 0
	jr t, .LRF_1225                        ; [68 51] jr T,0x281225
.LRF_11d4:
	lds32	xhl, 0
	jr t, .LRF_1225                        ; [68 4d] jr T,0x281225
.LRF_11d8:
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x02c4)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	ld	xwa, xhl
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld xbc, (xsp + 0x64)                    ; ld XBC,(XSP+0x64)
	ld xde, (xsp + 0x60)                    ; ld XDE,(XSP+0x60)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x0254)
	call	(xhl)
.LRF_120b:
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld xbc, (xsp + 0x64)                    ; ld XBC,(XSP+0x64)
	ld xde, (xsp + 0x60)                    ; ld XDE,(XSP+0x60)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xix, (xhl + 0x00dc)
	call	(xix)
.LRF_1225:
	pop xiz                                 ; pop XIZ
	lda	xsp, (xsp+104)
	ret

	lda	xsp, (xsp-106)
	push xiz
	ld (xsp + 0x6a), xde                    ; ld (XSP+0x6a),XDE
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01c00025
	jrl z, .LRF_12f0                       ; [76 b2 00] jrl Z,0x2812f0
	cp	xwa, 0x01c0000d
	jr z, .LRF_125f                        ; [66 19] jr Z,0x28125f
	ld	xwa, xiz
	ld xde, (xsp + 0x6a)                    ; ld XDE,(XSP+0x6a)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xix, (xhl + 0x00dc)
	call	(xix)
	jrl t, .LRF_140c                       ; [78 ad 01] jrl T,0x28140c
.LRF_125f:
	ld	xwa, xiz
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x02c4)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	ld	xwa, xhl
	lda	xwa, (xwa+14)
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	de, (xbc+22)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x02dc)
	ldw	bc, 0x00c5
	call	(xhl)
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	lda	xiy, (xwa+14)
	lda	xix, (xsp+98)
	lds	bc, 4
	ldirw                                   ; ldirw
	incm	4, (xsp+100)
	incm	4, (xsp+98)
	decm	4, (xsp+102)
	decm	4, (xsp+104)
	lda	xwa, (xsp+98)
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	de, (xbc+22)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x02dc)
	ldw	bc, 0x00c6
	call	(xhl)
	lda_24 xwa, 0x2e1eb6
	ld	xbc, xwa
	ld	xwa, xiz
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c00025
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LRF_140c                       ; [78 1c 01] jrl T,0x28140c
.LRF_12f0:
	ld	xwa, xiz
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x02c4)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	ld	xwa, xhl
	lda	xiy, (xwa+14)
	lda	xix, (xsp+98)
	lds	bc, 4
	ldirw                                   ; ldirw
	incm	5, (xsp+100)
	incm	5, (xsp+98)
	decm	5, (xsp+102)
	decm	5, (xsp+104)
	ld	wa, (xsp+102)
	sub	wa, (xsp+98)
	exts xwa                                ; exts XWA
	divs	wa, 0x0006
	ld (xsp + 0x08), wa                     ; ld (XSP+0x08),WA
	ld	wa, (xsp+98)
	ld (xsp + 0x4e), wa                     ; ld (XSP+0x4e),WA
	ld	wa, (xsp+104)
	dec 0, wa		; dec 0,WA
	ld (xsp + 0x50), wa                     ; ld (XSP+0x50),WA
	lda	xiy, (xsp+98)
	lda	xix, (xsp+90)
	lds	bc, 4
	ldirw                                   ; ldirw
	incm	8, (xsp+92)
	lda	xiy, (xsp+98)
	lda	xix, (xsp+82)
	lds	bc, 4
	ldirw                                   ; ldirw
	ld	wa, (xsp+88)
	dec 0, wa		; dec 0,WA
	ld (xsp + 0x54), wa                     ; ld (XSP+0x54),WA
	ld	wa, (xsp+98)
	ld (xsp + 0x4a), wa                     ; ld (XSP+0x4a),WA
	ld	wa, (xsp+100)
	ld (xsp + 0x4c), wa                     ; ld (XSP+0x4c),WA
	ld xwa, (xsp + 0x6a)                    ; ld XWA,(XSP+0x6a)
	ld (xsp + 0x0a), xwa                    ; ld (XSP+0x0a),XWA
.LRF_136c:
	lda	xwa, (xsp+90)
	ld	xde, xwa
	lda	xwa, (xsp+74)
	ld	xbc, xwa
	ld	xwa, xde
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e0a)
	ld_sril	xhl, (xde + 0x00b0)
	call	(xhl)
	lda	xwa, (xsp+82)
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	bc, (xbc+22)
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e0a)
	ld_sril	xhl, (xde + 0x00a4)
	call	(xhl)
	ld	wa, (xsp+8)
	pushw wa                                ; push WA
	ld xwa, (xsp + 0x0c)                    ; ld XWA,(XSP+0x0c)
	push xwa
	lda	xwa, (xsp+20)
	push xwa
	call HDAE5000_MemCopy_Reverse
	lda	xsp, (xsp+10)
	ld	wa, (xsp+8)
	extz xwa
	lda	xbc, (xsp+14)
	add	xbc, xwa
	ld	(xbc), 0x00
	lda	xhl, (xsp+98)
	lda	xbc, (xsp+78)
	lda	xwa, (xsp+14)
	ld	xde, xwa
	lds32	xwa, 3
	push xwa
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	pushm	(xwa+24)
	ld xwa, (xsp + 0x0a)                    ; ld XWA,(XSP+0x0a)
	pushm	(xwa+22)
	ld	xwa, xhl
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00c4)
	call	(xhl)
	lda	xwa, (xsp+14)
	push xwa
	call HDAE5000_Display_Buffer_Validate
	inc 4, xsp                              ; inc 4,XSP
	cp	hl, (xsp+8)
	jr nz, .LRF_140a                       ; [6e 0b] jr NZ,0x28140a
	ld	wa, (xsp+8)
	extz xwa
	add	(xsp+10), xwa
	jrl t, .LRF_136c                       ; [78 62 ff] jrl T,0x28136c
.LRF_140a:
	lds32	xhl, 0
.LRF_140c:
	pop xiz                                 ; pop XIZ
	lda	xsp, (xsp+106)
	ret

	lda	xsp, (xsp-48)
	push xiz
	ld (xsp + 0x28), xde                    ; ld (XSP+0x28),XDE
	ld (xsp + 0x2c), xbc                    ; ld (XSP+0x2c),XBC
	ld (xsp + 0x30), xwa                    ; ld (XSP+0x30),XWA
	ld xwa, (xsp + 0x2c)                    ; ld XWA,(XSP+0x2c)
	cp	xwa, 0x01c00029
	jrl z, .LRF_251f                       ; [76 f5 10] jrl Z,0x28251f
	cp	xwa, 0x01e00081
	jrl z, .LRF_24e7                       ; [76 b4 10] jrl Z,0x2824e7
	cp	xwa, 0x01e00080
	jrl z, .LRF_22b7                       ; [76 7b 0e] jrl Z,0x2822b7
	cp	xwa, 0x01e0007f
	jrl z, .LRF_2231                       ; [76 ec 0d] jrl Z,0x282231
	cp	xwa, 0x01e0007b
	jrl z, .LRF_2224                       ; [76 d6 0d] jrl Z,0x282224
	cp	xwa, 0x01e0003a
	jrl z, .LRF_220f                       ; [76 b8 0d] jrl Z,0x28220f
	cp	xwa, 0x01e00086
	jrl z, .LRF_21df                       ; [76 7f 0d] jrl Z,0x2821df
	cp	xwa, 0x01c00018
	jrl z, .LRF_19ba                       ; [76 51 05] jrl Z,0x2819ba
	cp	xwa, 0x01c0001a
	jrl z, .LRF_19ba                       ; [76 48 05] jrl Z,0x2819ba
	cp	xwa, 0x01c00017
	jrl z, .LRF_19ba                       ; [76 3f 05] jrl Z,0x2819ba
	cp	xwa, 0x01c00019
	jrl z, .LRF_19ba                       ; [76 36 05] jrl Z,0x2819ba
	cp	xwa, 0x01c0000f
	jrl z, .LRF_18c3                       ; [76 36 04] jrl Z,0x2818c3
	cp	xwa, 0x01c0000e
	jrl z, .LRF_172c                       ; [76 96 02] jrl Z,0x28172c
	cp	xwa, 0x01c00002
	jrl z, .LRF_170d                       ; [76 6e 02] jrl Z,0x28170d
	cp	xwa, 0x01c0000c
	jrl z, .LRF_16c0                       ; [76 18 02] jrl Z,0x2816c0
	cp	xwa, 0x01c0000b
	jrl z, .LRF_16c0                       ; [76 0f 02] jrl Z,0x2816c0
	cp	xwa, 0x01c00001
	jrl nz, .LRF_2662                      ; [7e a8 11] jrl NZ,0x282662
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	or xwa, xwa                             ; or XWA,XWA
	jr z, .LRF_14d8                        ; [66 17] jr Z,0x2814d8
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	cp	xwa, 0x00000003
	jr z, .LRF_14d8                        ; [66 0c] jr Z,0x2814d8
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	cp	xwa, 0x00000005
	jrl nz, .LRF_1658                      ; [7e 80 01] jrl NZ,0x281658
.LRF_14d8:
	ld	xwa, (0x22a022)
	or xwa, xwa                             ; or XWA,XWA
	jr nz, .LRF_14eb                       ; [6e 0a] jr NZ,0x2814eb
	ld	xwa, 0x01200005
	ld	(0x22a022), xwa
.LRF_14eb:
	stiw_da	0x22A028, 0
	stiw_da	0x22A02A, 0
	ld	xwa, (0x22a022)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x0250)
	ld	xbc, 0x01e0007c
	lds32	xde, 0
	call	(xix)
	ld	(0x22a026), hl
	cpw_da	0x22A026, 32
	jr ule, .LRF_152b                      ; [63 07] jr ULE,0x28152b
	stiw_da	0x22A026, 32
.LRF_152b:
	ld	xwa, (0x22a022)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x0250)
	ld	xbc, 0x01e00084
	lds32	xde, 0
	call	(xix)
	ld	(0x22a032), hl
	ldw_da	wa, 0x22A032
	extz xwa
	sll	xwa, 0x02
	ld	xbc, 0x002e21ba
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld	(0x22a034), xwa
	cpw_da	0x22A032, 0
	jr z, .LRF_15b8                        ; [66 4a] jr Z,0x2815b8
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0294)
	ld	xwa, 0x007f01bb
	lds	bc, 0
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0294)
	ld	xwa, 0x007f01bc
	lds	bc, 0
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0294)
	ld	xwa, 0x007f01bd
	lds	bc, 0
	call	(xhl)
	jr t, .LRF_1600                        ; [68 48] jr T,0x281600
.LRF_15b8:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0294)
	ld	xwa, 0x007f01bb
	lds	bc, 1
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0294)
	ld	xwa, 0x007f01bc
	lds	bc, 1
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0294)
	ld	xwa, 0x007f01bd
	lds	bc, 1
	call	(xhl)
.LRF_1600:
	lds	iz, 0
	cpda16_24	iz, 0x22A026
	jr nc, .LRF_1626                       ; [6f 1d] jr NC,0x281626
.LRF_1609:
	ld	wa, iz
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	xwa, (0x22a034)
	ld	a, (xwa)
	ld	(xbc), a
	inc	1, iz
	cpda16_24	iz, 0x22A026
	jr c, .LRF_1609                        ; [67 e3] jr C,0x281609
.LRF_1626:
	ld	wa, iz
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	(xbc), 0x00
	lda_24 xwa, 0x22a000
	ld	xbc, xwa
	ld	xwa, (0x22a022)
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0250)
	ld	xbc, 0x01e0003a
	call	(xhl)
.LRF_1658:
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x03c8)
	ld	xbc, 0x01c00017
	lds32	xde, 5
	call	(xhl)
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x03cc)
	ld	xbc, 0x01c00018
	lds32	xde, 3
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x03c4)
	lds	wa, 1
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LRF_267c                       ; [78 bc 0f] jrl T,0x28267c
.LRF_16c0:
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	stiw_da	0x22A02C, 65535
	stiw_da	0x22A030, 65535
	ldw_da	de, 0x22A028
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01e00080
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LRF_267c                       ; [78 6f 0f] jrl T,0x28267c
.LRF_170d:
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LRF_267c                       ; [78 50 0f] jrl T,0x28267c
.LRF_172c:
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	ld	(0x22a02e), wa
	ldw_da	wa, 0x22A030
	cpda16_24	wa, 0x22A02E
	jrl z, .LRF_18be                       ; [76 7d 01] jrl Z,0x2818be
	lda	xwa, (xsp+32)
	ld	xbc, xwa
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e0a)
	ld_sril	xhl, (xde + 0x02d4)
	call	(xhl)
	ldw_da	wa, 0x22A02A
	extz xwa
	sll	xwa, 0x02
	ld	xbc, 0x002e21a2
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld (xsp + 0x06), xwa                    ; ld (XSP+0x06),XWA
	cpw_da	0x22A030, 65535
	jrl z, .LRF_1817                       ; [76 9d 00] jrl Z,0x281817
	ldw_da	wa, 0x22A030
	extz xwa
	sll	xwa, 0x02
	ld	xde, xwa
	add	xde, (xsp+6)
	lda	xwa, (xsp+10)
	ld	xbc, xwa
	ld xwa, (xde)                           ; ld XWA,(XDE)
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e0a)
	ld_sril	xhl, (xde + 0x015c)
	call	(xhl)
	ldw_da	wa, 0x22A030
	extz xwa
	div wa, 0x000d
	mul	wa, 0x0018
	ld	bc, wa
	ld	wa, (xsp+34)
	add	wa, 0x000a
	add	wa, bc
	ld (xsp + 0x1a), wa                     ; ld (XSP+0x1a),WA
	ldw_da	wa, 0x22A030
	extz xwa
	div wa, 0x000d
	ld	wa, qwa
	ld	bc, wa
	sll	bc, 0x04
	ld	wa, (xsp+32)
	add	wa, 0x000e
	add	wa, bc
	dec	1, wa
	ld (xsp + 0x18), wa                     ; ld (XSP+0x18),WA
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_Display_Buffer_Validate
	inc 4, xsp                              ; inc 4,XSP
	sll	hl, 0x03
	ld	wa, (xsp+24)
	add	wa, hl
	inc	2, wa
	ld (xsp + 0x1c), wa                     ; ld (XSP+0x1c),WA
	ld	wa, (xsp+26)
	add	wa, 0x0011
	ld (xsp + 0x1e), wa                     ; ld (XSP+0x1e),WA
	lda	xwa, (xsp+24)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x00a8)
	ldw	bc, 0x00f5
	call	(xhl)
.LRF_1817:
	ldw_da	wa, 0x22A02E
	extz xwa
	sll	xwa, 0x02
	ld	xde, xwa
	add	xde, (xsp+6)
	lda	xwa, (xsp+10)
	ld	xbc, xwa
	ld xwa, (xde)                           ; ld XWA,(XDE)
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e0a)
	ld_sril	xhl, (xde + 0x015c)
	call	(xhl)
	ldw_da	wa, 0x22A02E
	extz xwa
	div wa, 0x000d
	mul	wa, 0x0018
	ld	bc, wa
	ld	wa, (xsp+34)
	add	wa, 0x000a
	add	wa, bc
	ld (xsp + 0x1a), wa                     ; ld (XSP+0x1a),WA
	ldw_da	wa, 0x22A02E
	extz xwa
	div wa, 0x000d
	ld	wa, qwa
	ld	bc, wa
	sll	bc, 0x04
	ld	wa, (xsp+32)
	add	wa, 0x000e
	add	wa, bc
	dec	1, wa
	ld (xsp + 0x18), wa                     ; ld (XSP+0x18),WA
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_Display_Buffer_Validate
	inc 4, xsp                              ; inc 4,XSP
	sll	hl, 0x03
	ld	wa, (xsp+24)
	add	wa, hl
	inc	2, wa
	ld (xsp + 0x1c), wa                     ; ld (XSP+0x1c),WA
	ld	wa, (xsp+26)
	add	wa, 0x0011
	ld (xsp + 0x1e), wa                     ; ld (XSP+0x1e),WA
	lda	xwa, (xsp+24)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x00a8)
	ldw	bc, 0x00f2
	call	(xhl)
	ldw_da	wa, 0x22A02E
	ld	(0x22a030), wa
.LRF_18be:
	lds32	xhl, 0
	jrl t, .LRF_267c                       ; [78 b9 0d] jrl T,0x28267c
.LRF_18c3:
	ldw_da	wa, 0x22A02C
	cpda16_24	wa, 0x22A02A
	jrl z, .LRF_19b5                       ; [76 e5 00] jrl Z,0x2819b5
	stiw_da	0x22A030, 65535
	lda	xwa, (xsp+32)
	ld	xbc, xwa
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e0a)
	ld_sril	xhl, (xde + 0x02d4)
	call	(xhl)
	lda	xwa, (xsp+32)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x00a4)
	ldw	bc, 0x00f5
	call	(xhl)
	ldw_da	wa, 0x22A02A
	extz xwa
	sll	xwa, 0x02
	ld	xbc, 0x002e21a2
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld (xsp + 0x06), xwa                    ; ld (XSP+0x06),XWA
	lds	iz, 0
	jr t, .LRF_198d                        ; [68 6c] jr T,0x28198d
.LRF_1921:
	ld	wa, iz
	extz xwa
	div wa, 0x000d
	ld	wa, qwa
	ld	bc, wa
	sll	bc, 0x04
	ld	wa, (xsp+32)
	add	wa, 0x000e
	add	wa, bc
	ld (xsp + 0x14), wa                     ; ld (XSP+0x14),WA
	ld	wa, iz
	extz xwa
	div wa, 0x000d
	mul	wa, 0x0018
	ld	bc, wa
	ld	wa, (xsp+34)
	add	wa, 0x000a
	add	wa, bc
	ld (xsp + 0x16), wa                     ; ld (XSP+0x16),WA
	lda	xwa, (xsp+32)
	ld	xhl, xwa
	lda	xwa, (xsp+20)
	ld	xbc, xwa
	ld	wa, iz
	extz xwa
	sll	xwa, 0x02
	ld	xde, xwa
	add	xde, (xsp+6)
	lds32	xwa, 0
	push xwa
	pushw 0x00ff
	pushw 0x00f7
	ld	xwa, xhl
	ld xde, (xde)                           ; ld XDE,(XDE)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00c4)
	call	(xhl)
	inc	1, iz
.LRF_198d:
	ldw_da	wa, 0x22A032
	mul	wa, 0x0003
	addda16_24	wa, 0x22A02A
	extz xwa
	add	xwa, xwa
	ld	xbc, 0x002e21ae
	add	xbc, xwa
	cp	iz, (xbc)
	jrl ule, .LRF_1921                     ; [73 76 ff] jrl ULE,0x281921
	ldw_da	wa, 0x22A02A
	ld	(0x22a02c), wa
.LRF_19b5:
	lds32	xhl, 0
	jrl t, .LRF_267c                       ; [78 c2 0c] jrl T,0x28267c
.LRF_19ba:
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	dec	1, xwa
	cp	xwa, 0x00000000
	jrl c, .LRF_21da                       ; [77 f8 07] jrl C,0x2821da
	cp	xwa, 0x00000008
	jrl ugt, .LRF_21da                     ; [7b ef 07] jrl UGT,0x2821da
	add	xwa, xwa
	add	xwa, 0x002e21c6
	ld	wa, (xwa)
	lda_24 xix, 0x2819ff
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
	cpw_da	0x22A028, 0
	jrl z, .LRF_21da                       ; [76 d1 07] jrl Z,0x2821da
	decdi16_24	1, 0x22A028
	ldw_da	de, 0x22A028
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01e00080
	call	(xhl)
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x042c)
	call	(xhl)
	jrl t, .LRF_21da                       ; [78 8f 07] jrl T,0x2821da
	ldw_da	wa, 0x22A028
	inc	1, wa
	cpda16_24	wa, 0x22A026
	jrl nc, .LRF_21da                      ; [7f 80 07] jrl NC,0x2821da
	incdi16_24	1, 0x22A028
	ldw_da	de, 0x22A028
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01e00080
	call	(xhl)
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x042c)
	call	(xhl)
	jrl t, .LRF_21da                       ; [78 3e 07] jrl T,0x2821da
	cpw_da	0x22A02E, 0
	jrl z, .LRF_21da                       ; [76 34 07] jrl Z,0x2821da
	ldw_da	wa, 0x22A02A
	extz xwa
	sll	xwa, 0x02
	ld	xbc, 0x002e21a2
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld (xsp + 0x06), xwa                    ; ld (XSP+0x06),XWA
	decdi16_24	1, 0x22A02E
	ldw_da	wa, 0x22A02E
	extz xwa
	sll	xwa, 0x02
	ld	xde, xwa
	add	xde, (xsp+6)
	lda	xwa, (xsp+10)
	ld	xbc, xwa
	ld xwa, (xde)                           ; ld XWA,(XDE)
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e0a)
	ld_sril	xhl, (xde + 0x015c)
	call	(xhl)
	ldw_da	wa, 0x22A028
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xsp+10)
	ld	(xbc), a
	lda_24 xwa, 0x22a000
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f01ba
	ld	xbc, 0x01c0000f
	call	(xhl)
	ldw_da	de, 0x22A02E
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000e
	call	(xhl)
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x042c)
	call	(xhl)
	jrl t, .LRF_21da                       ; [78 80 06] jrl T,0x2821da
	ld xwa, (xsp + 0x2c)                    ; ld XWA,(XSP+0x2c)
	cp	xwa, 0x01c00018
	jrl z, .LRF_1c40                       ; [76 da 00] jrl Z,0x281c40
	cp	xwa, 0x01c0001a
	jrl z, .LRF_1c40                       ; [76 d1 00] jrl Z,0x281c40
	cp	xwa, 0x01c00017
	jr z, .LRF_1b80                        ; [66 09] jr Z,0x281b80
	cp	xwa, 0x01c00019
	jrl nz, .LRF_21da                      ; [7e 5a 06] jrl NZ,0x2821da
.LRF_1b80:
	cpw_da	0x22A02E, 13
	jrl c, .LRF_21da                       ; [77 50 06] jrl C,0x2821da
	subdi16_24	0x22A02E, 13
	ldw_da	wa, 0x22A02A
	extz xwa
	sll	xwa, 0x02
	ld	xbc, 0x002e21a2
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld (xsp + 0x06), xwa                    ; ld (XSP+0x06),XWA
	ldw_da	wa, 0x22A02E
	extz xwa
	sll	xwa, 0x02
	ld	xde, xwa
	add	xde, (xsp+6)
	lda	xwa, (xsp+10)
	ld	xbc, xwa
	ld xwa, (xde)                           ; ld XWA,(XDE)
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e0a)
	ld_sril	xhl, (xde + 0x015c)
	call	(xhl)
	ldw_da	wa, 0x22A028
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xsp+10)
	ld	(xbc), a
	lda_24 xwa, 0x22a000
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f01ba
	ld	xbc, 0x01c0000f
	call	(xhl)
	ldw_da	de, 0x22A02E
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000e
	call	(xhl)
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x042c)
	call	(xhl)
	jrl t, .LRF_21da                       ; [78 9a 05] jrl T,0x2821da
.LRF_1c40:
	ldw_da	wa, 0x22A02A
	extz xwa
	sll	xwa, 0x02
	ld	xbc, 0x002e21a2
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld (xsp + 0x06), xwa                    ; ld (XSP+0x06),XWA
	ldw_da	wa, 0x22A02E
	extz xwa
	sll	xwa, 0x02
	ld	xde, xwa
	add	xde, (xsp+6)
	lda	xwa, (xsp+10)
	ld	xbc, xwa
	ld xwa, (xde)                           ; ld XWA,(XDE)
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e0a)
	ld_sril	xhl, (xde + 0x015c)
	call	(xhl)
	ldw_da	wa, 0x22A032
	mul	wa, 0x0003
	addda16_24	wa, 0x22A02A
	extz xwa
	add	xwa, xwa
	ld	xbc, 0x002e21ae
	add	xbc, xwa
	ldw_da	wa, 0x22A02E
	add	wa, 0x000c
	cp	wa, (xbc)
	jr ugt, .LRF_1cb4                      ; [6b 11] jr UGT,0x281cb4
	cp	(xsp+10), 0x5a
	jr z, .LRF_1caf                        ; [66 06] jr Z,0x281caf
	cp	(xsp+10), 0x7a
	jr nz, .LRF_1cb4                       ; [6e 05] jr NZ,0x281cb4
.LRF_1caf:
	decdi16_24	1, 0x22A02E
.LRF_1cb4:
	ldw_da	wa, 0x22A032
	mul	wa, 0x0003
	addda16_24	wa, 0x22A02A
	extz xwa
	add	xwa, xwa
	ld	xbc, 0x002e21ae
	add	xbc, xwa
	ldw_da	wa, 0x22A02E
	add	wa, 0x000d
	cp	wa, (xbc)
	jrl ugt, .LRF_21da                     ; [7b ff 04] jrl UGT,0x2821da
	adddi16_24	0x22A02E, 13
	ldw_da	wa, 0x22A02A
	extz xwa
	sll	xwa, 0x02
	ld	xbc, 0x002e21a2
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld (xsp + 0x06), xwa                    ; ld (XSP+0x06),XWA
	ldw_da	wa, 0x22A02E
	extz xwa
	sll	xwa, 0x02
	ld	xde, xwa
	add	xde, (xsp+6)
	lda	xwa, (xsp+10)
	ld	xbc, xwa
	ld xwa, (xde)                           ; ld XWA,(XDE)
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e0a)
	ld_sril	xhl, (xde + 0x015c)
	call	(xhl)
	cp	(xsp+10), 0x53
	jr nz, .LRF_1d44                       ; [6e 1f] jr NZ,0x281d44
	cp	(xsp+11), 0x50
	jr nz, .LRF_1d44                       ; [6e 19] jr NZ,0x281d44
	ldw_da	wa, 0x22A028
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	xwa, (0x22a034)
	ld	a, (xwa)
	ld	(xbc), a
	jr t, .LRF_1d57                        ; [68 13] jr T,0x281d57
.LRF_1d44:
	ldw_da	wa, 0x22A028
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xsp+10)
	ld	(xbc), a
.LRF_1d57:
	lda_24 xwa, 0x22a000
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f01ba
	ld	xbc, 0x01c0000f
	call	(xhl)
	ldw_da	de, 0x22A02E
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000e
	call	(xhl)
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x042c)
	call	(xhl)
	jrl t, .LRF_21da                       ; [78 24 04] jrl T,0x2821da
	ldw_da	wa, 0x22A02A
	extz xwa
	sll	xwa, 0x02
	ld	xbc, 0x002e21a2
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld (xsp + 0x06), xwa                    ; ld (XSP+0x06),XWA
	ldw_da	wa, 0x22A032
	mul	wa, 0x0003
	addda16_24	wa, 0x22A02A
	extz xwa
	add	xwa, xwa
	ld	xbc, 0x002e21ae
	add	xbc, xwa
	ldw_da	wa, 0x22A02E
	inc	1, wa
	cp	wa, (xbc)
	jrl ugt, .LRF_21da                     ; [7b e9 03] jrl UGT,0x2821da
	incdi16_24	1, 0x22A02E
	ldw_da	wa, 0x22A02E
	extz xwa
	sll	xwa, 0x02
	ld	xde, xwa
	add	xde, (xsp+6)
	lda	xwa, (xsp+10)
	ld	xbc, xwa
	ld xwa, (xde)                           ; ld XWA,(XDE)
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e0a)
	ld_sril	xhl, (xde + 0x015c)
	call	(xhl)
	cp	(xsp+10), 0x53
	jr nz, .LRF_1e42                       ; [6e 1f] jr NZ,0x281e42
	cp	(xsp+11), 0x50
	jr nz, .LRF_1e42                       ; [6e 19] jr NZ,0x281e42
	ldw_da	wa, 0x22A028
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	xwa, (0x22a034)
	ld	a, (xwa)
	ld	(xbc), a
	jr t, .LRF_1e55                        ; [68 13] jr T,0x281e55
.LRF_1e42:
	ldw_da	wa, 0x22A028
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xsp+10)
	ld	(xbc), a
.LRF_1e55:
	lda_24 xwa, 0x22a000
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f01ba
	ld	xbc, 0x01c0000f
	call	(xhl)
	ldw_da	de, 0x22A02E
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000e
	call	(xhl)
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x042c)
	call	(xhl)
	jrl t, .LRF_21da                       ; [78 26 03] jrl T,0x2821da
	ldw_da	iz, 0x22A026
	dec	1, iz
	cpda16_24	iz, 0x22A028
	jr ule, .LRF_1ee7                      ; [63 25] jr ULE,0x281ee7
.LRF_1ec2:
	ld	wa, iz
	extz xwa
	ld	xde, 0x0022a000
	add	xde, xwa
	ld	wa, iz
	dec	1, wa
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xbc)
	ld	(xde), a
	dec	1, iz
	cpda16_24	iz, 0x22A028
	jr ugt, .LRF_1ec2                      ; [6b db] jr UGT,0x281ec2
.LRF_1ee7:
	ldw_da	wa, 0x22A028
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	xwa, (0x22a034)
	ld	a, (xwa)
	ld	(xbc), a
	lda_24 xwa, 0x22a000
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f01ba
	ld	xbc, 0x01c0000f
	call	(xhl)
	ldw_da	de, 0x22A028
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01e00080
	call	(xhl)
	jrl t, .LRF_21da                       ; [78 97 02] jrl T,0x2821da
	ldw_da	iz, 0x22A028
	cpda16_24	iz, 0x22A026
	jr nc, .LRF_1f74                       ; [6f 25] jr NC,0x281f74
.LRF_1f4f:
	ld	wa, iz
	extz xwa
	ld	xde, 0x0022a000
	add	xde, xwa
	ld	wa, iz
	inc	1, wa
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xbc)
	ld	(xde), a
	inc	1, iz
	cpda16_24	iz, 0x22A026
	jr c, .LRF_1f4f                        ; [67 db] jr C,0x281f4f
.LRF_1f74:
	ldw_da	wa, 0x22A026
	dec	1, wa
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	xwa, (0x22a034)
	ld	a, (xwa)
	ld	(xbc), a
	lda_24 xwa, 0x22a000
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f01ba
	ld	xbc, 0x01c0000f
	call	(xhl)
	ldw_da	de, 0x22A028
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01e00080
	call	(xhl)
	jrl t, .LRF_21da                       ; [78 08 02] jrl T,0x2821da
	ldw (xsp + 0x04), 0
	lds	iz, 0
	cpda16_24	iz, 0x22A026
	jr nc, .LRF_2002                       ; [6f 22] jr NC,0x282002
.LRF_1fe0:
	ld	wa, iz
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	xwa, (0x22a034)
	ld	a, (xwa)
	cp	a, (xbc)
	jr nz, .LRF_2002                       ; [6e 0c] jr NZ,0x282002
	incm	1, (xsp+4)
	inc	1, iz
	cpda16_24	iz, 0x22A026
	jr c, .LRF_1fe0                        ; [67 de] jr C,0x281fe0
.LRF_2002:
	ld	wa, (xsp+4)
	cpda16_24	wa, 0x22A026
	jrl z, .LRF_21da                       ; [76 cd 01] jrl Z,0x2821da
	ldw (xsp + 0x06), 0
	lds	iz, 0
	cpda16_24	iz, 0x22A026
	jr nc, .LRF_2044                       ; [6f 29] jr NC,0x282044
.LRF_201b:
	ldw_da	wa, 0x22A026
	sub	wa, iz
	dec	1, wa
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	xwa, (0x22a034)
	ld	a, (xwa)
	cp	a, (xbc)
	jr nz, .LRF_2044                       ; [6e 0c] jr NZ,0x282044
	incm	1, (xsp+6)
	inc	1, iz
	cpda16_24	iz, 0x22A026
	jr c, .LRF_201b                        ; [67 d7] jr C,0x28201b
.LRF_2044:
	ld	wa, (xsp+4)
	ld (xsp + 0x08), wa                     ; ld (XSP+0x08),WA
	ld	wa, (xsp+6)
	add	(xsp+8), wa
	srlw_rid8 xsp, 0x08		; srlw (XSP+0x08)
	ldw_da	wa, 0x22A026
	inc	1, wa
	extz xwa
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e88)
	ld_sril	xix, (xbc + 0x0130)
	call	(xix)
	ld	xiz, xhl
	ld	wa, (xsp+4)
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	push xbc
	ld	xwa, xiz
	push xwa
	call HDAE5000_MemCopy_Block
	ldw_da	wa, 0x22A026
	sub	wa, (xsp+12)
	sub	wa, (xsp+14)
	extz xwa
	add	xwa, xiz
	ld	(xwa), 0x00
	ld	xwa, xiz
	push xwa
	ld	wa, (xsp+20)
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	push xbc
	call HDAE5000_MemCopy_Block
	lda	xsp, (xsp+16)
	ld	xwa, xiz
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e88)
	ld_sril	xhl, (xbc + 0x0134)
	call	(xhl)
	lds	iz, 0
	cp	iz, (xsp+8)
	jr nc, .LRF_20e1                       ; [6f 1b] jr NC,0x2820e1
.LRF_20c6:
	ld	wa, iz
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	xwa, (0x22a034)
	ld	a, (xwa)
	ld	(xbc), a
	inc	1, iz
	cp	iz, (xsp+8)
	jr c, .LRF_20c6                        ; [67 e5] jr C,0x2820c6
.LRF_20e1:
	ld	wa, (xsp+4)
	add	wa, (xsp+6)
	sub	wa, (xsp+8)
	ldw_da	iz, 0x22A026
	sub	iz, wa
	cpda16_24	iz, 0x22A026
	jr nc, .LRF_2115                       ; [6f 1d] jr NC,0x282115
.LRF_20f8:
	ld	wa, iz
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	xwa, (0x22a034)
	ld	a, (xwa)
	ld	(xbc), a
	inc	1, iz
	cpda16_24	iz, 0x22A026
	jr c, .LRF_20f8                        ; [67 e3] jr C,0x2820f8
.LRF_2115:
	lda_24 xwa, 0x22a000
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f01ba
	ld	xbc, 0x01c0000f
	call	(xhl)
	ldw_da	de, 0x22A028
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01e00080
	call	(xhl)
	jrl t, .LRF_21da                       ; [78 80 00] jrl T,0x2821da
	lds	iz, 0
	cpda16_24	iz, 0x22A026
	jr nc, .LRF_2180                       ; [6f 1d] jr NC,0x282180
.LRF_2163:
	ld	wa, iz
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	xwa, (0x22a034)
	ld	a, (xwa)
	ld	(xbc), a
	inc	1, iz
	cpda16_24	iz, 0x22A026
	jr c, .LRF_2163                        ; [67 e3] jr C,0x282163
.LRF_2180:
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f01ba
	ld	xbc, 0x01e00080
	lds32	xde, 0
	call	(xhl)
	lda_24 xwa, 0x22a000
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f01ba
	ld	xbc, 0x01c0000f
	call	(xhl)
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01e00080
	lds32	xde, 0
	call	(xhl)
.LRF_21da:
	lds32	xhl, 0
	jrl t, .LRF_267c                       ; [78 9d 04] jrl T,0x28267c
.LRF_21df:
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	push xwa
	lda_24 xwa, 0x22a000
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01e00080
	lds32	xde, 0
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LRF_267c                       ; [78 6d 04] jrl T,0x28267c
.LRF_220f:
	lda_24 xwa, 0x22a000
	push xwa
	ld xwa, (xsp + 0x2c)                    ; ld XWA,(XSP+0x2c)
	push xwa
	call HDAE5000_MemCopy_Block
	inc 0, xsp                              ; inc 0,XSP
	lds32	xhl, 0
	jrl t, .LRF_267c                       ; [78 58 04] jrl T,0x28267c
.LRF_2224:
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	ld	(0x22a022), xwa
	lds32	xhl, 0
	jrl t, .LRF_267c                       ; [78 4b 04] jrl T,0x28267c
.LRF_2231:
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	ld	(0x22a02a), wa
	cpw_da	0x22A032, 0
	jr nz, .LRF_2264                       ; [6e 22] jr NZ,0x282264
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	extz xwa
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c0002a
	call	(xhl)
.LRF_2264:
	ldw_da	de, 0x22A02A
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000f
	call	(xhl)
	ldw_da	wa, 0x22A02A
	extz xwa
	sll	xwa, 0x02
	ld	xbc, 0x002e1ec2
	add	xbc, xwa
	ld xde, (xbc)                           ; ld XDE,(XBC)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f01c1
	ld	xbc, 0x01c0000f
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LRF_267c                       ; [78 c5 03] jrl T,0x28267c
.LRF_22b7:
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	ld	(0x22a028), wa
	ldw_da	de, 0x22A028
	extz xde                                ; extz XDE
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f01ba
	ld	xbc, 0x01e00080
	call	(xhl)
	lda_24 xwa, 0x22a000
	ld	xde, xwa
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f01ba
	ld	xbc, 0x01c0000f
	call	(xhl)
	ldw_da	wa, 0x22A028
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xbc)
	extz wa                                 ; extz WA
	lda_24 xbc, 0x2f9362
	bit_dri 0, 0x07, 0xE4, 0xE0	; bit 0,(XBC+WA)
	jr z, .LRF_2345                        ; [66 24] jr Z,0x282345
	stiw_da	0x22A02A, 0
	ldw_da	wa, 0x22A028
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xbc)
	sub	a, 0x41
	extz wa                                 ; extz WA
	ld	(0x22a02e), wa
	jrl t, .LRF_24a2                       ; [78 5d 01] jrl T,0x2824a2
.LRF_2345:
	ldw_da	wa, 0x22A028
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xbc)
	extz wa                                 ; extz WA
	lda_24 xbc, 0x2f9362
	bit_dri 1, 0x07, 0xE4, 0xE0	; bit 1,(XBC+WA)
	jr z, .LRF_2387                        ; [66 24] jr Z,0x282387
	stiw_da	0x22A02A, 1
	ldw_da	wa, 0x22A028
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xbc)
	sub	a, 0x61
	extz wa                                 ; extz WA
	ld	(0x22a02e), wa
	jrl t, .LRF_24a2                       ; [78 1b 01] jrl T,0x2824a2
.LRF_2387:
	ldw_da	wa, 0x22A028
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xbc)
	extz wa                                 ; extz WA
	lda_24 xbc, 0x2f9362
	bit_dri 2, 0x07, 0xE4, 0xE0	; bit 2,(XBC+WA)
	jr z, .LRF_23d2                        ; [66 2d] jr Z,0x2823d2
	cpw_da	0x22A02A, 2
	jr nz, .LRF_23b5                       ; [6e 07] jr NZ,0x2823b5
	stiw_da	0x22A02A, 0
.LRF_23b5:
	ldw_da	wa, 0x22A028
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xbc)
	sub	a, 0x15
	extz wa                                 ; extz WA
	ld	(0x22a02e), wa
	jrl t, .LRF_24a2                       ; [78 d0 00] jrl T,0x2824a2
.LRF_23d2:
	ldw_da	wa, 0x22A028
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	cp	(xbc), 0x20
	jr nz, .LRF_2409                       ; [6e 24] jr NZ,0x282409
	cpw_da	0x22A032, 0
	jrl nz, .LRF_24a2                      ; [7e b3 00] jrl NZ,0x2824a2
	cpw_da	0x22A02A, 2
	jr nz, .LRF_23ff                       ; [6e 07] jr NZ,0x2823ff
	stiw_da	0x22A02A, 0
.LRF_23ff:
	stiw_da	0x22A02E, 37
	jrl t, .LRF_24a2                       ; [78 99 00] jrl T,0x2824a2
.LRF_2409:
	ldw_da	wa, 0x22A028
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	cp	(xbc), 0x5f
	jr nz, .LRF_2435                       ; [6e 19] jr NZ,0x282435
	cpw_da	0x22A02A, 2
	jr nz, .LRF_242c                       ; [6e 07] jr NZ,0x28242c
	stiw_da	0x22A02A, 0
.LRF_242c:
	stiw_da	0x22A02E, 26
	jr t, .LRF_24a2                        ; [68 6d] jr T,0x2824a2
.LRF_2435:
	lda_24 xwa, 0x2e20d0
	ld (xsp + 0x06), xwa                    ; ld (XSP+0x06),XWA
	lds	iz, 0
	jr t, .LRF_2488                        ; [68 47] jr T,0x282488
.LRF_2441:
	ld	wa, iz
	extz xwa
	sll	xwa, 0x02
	ld	xde, xwa
	add	xde, (xsp+6)
	lda	xwa, (xsp+10)
	ld	xbc, xwa
	ld xwa, (xde)                           ; ld XWA,(XDE)
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e0a)
	ld_sril	xhl, (xde + 0x015c)
	call	(xhl)
	ldw_da	wa, 0x22A028
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xbc)
	cp	a, (xsp+10)
	jr nz, .LRF_2486                       ; [6e 0c] jr NZ,0x282486
	stiw_da	0x22A02A, 2
	ld	(0x22a02e), iz
.LRF_2486:
	inc	1, iz
.LRF_2488:
	ldw_da	wa, 0x22A032
	mul	wa, 0x0003
	inc	2, wa
	extz xwa
	add	xwa, xwa
	ld	xbc, 0x002e21ae
	add	xbc, xwa
	cp	iz, (xbc)
	jr ule, .LRF_2441                      ; [63 9f] jr ULE,0x282441
.LRF_24a2:
	ldw_da	de, 0x22A02A
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01e0007f
	call	(xhl)
	ldw_da	de, 0x22A02E
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000e
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LRF_267c                       ; [78 95 01] jrl T,0x28267c
.LRF_24e7:
	ldw_da	wa, 0x22A028
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	ld	(xbc), a
	ldw_da	de, 0x22A028
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01e00080
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LRF_267c                       ; [78 5d 01] jrl T,0x28267c
.LRF_251f:
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	srl	xwa, 0x00
	ld	qwa, 0
	cps	wa, 0
	jrl nz, .LRF_265e                      ; [7e 17 01] jrl NZ,0x28265e
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	ld	bc, wa
	extz xbc                                ; extz XBC
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01e0007f
	call	(xhl)
	ldw_da	wa, 0x22A032
	mul	wa, 0x0003
	addda16_24	wa, 0x22A02A
	extz xwa
	add	xwa, xwa
	ld	xbc, 0x002e21ae
	add	xbc, xwa
	ldw_da	wa, 0x22A02E
	cp	wa, (xbc)
	jr ule, .LRF_25ab                      ; [63 20] jr ULE,0x2825ab
	ldw_da	wa, 0x22A032
	mul	wa, 0x0003
	addda16_24	wa, 0x22A02A
	extz xwa
	add	xwa, xwa
	ld	xbc, 0x002e21ae
	add	xbc, xwa
	ld	wa, (xbc)
	ld	(0x22a02e), wa
.LRF_25ab:
	ldw_da	wa, 0x22A02A
	extz xwa
	sll	xwa, 0x02
	ld	xbc, 0x002e21a2
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld (xsp + 0x06), xwa                    ; ld (XSP+0x06),XWA
	ldw_da	wa, 0x22A02E
	extz xwa
	sll	xwa, 0x02
	ld	xde, xwa
	add	xde, (xsp+6)
	lda	xwa, (xsp+10)
	ld	xbc, xwa
	ld xwa, (xde)                           ; ld XWA,(XDE)
	ld	xde, (0x23a1a2)
	ld_sril	xde, (xde + 0x0e0a)
	ld_sril	xhl, (xde + 0x015c)
	call	(xhl)
	cp	(xsp+10), 0x53
	jr nz, .LRF_261c                       ; [6e 2e] jr NZ,0x28261c
	cp	(xsp+11), 0x50
	jr nz, .LRF_261c                       ; [6e 28] jr NZ,0x28261c
	ld	xwa, (0x22a034)
	ld	a, (xwa)
	lds32	xbc, 0
	ld	c, a
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01e00081
	call	(xhl)
	jr t, .LRF_263e                        ; [68 22] jr T,0x28263e
.LRF_261c:
	ld	a, (xsp+10)
	lds32	xbc, 0
	ld	c, a
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01e00081
	call	(xhl)
.LRF_263e:
	ldw_da	de, 0x22A02E
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000e
	call	(xhl)
.LRF_265e:
	lds32	xhl, 0
	jr t, .LRF_267c                        ; [68 1a] jr T,0x28267c
.LRF_2662:
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xix, (xhl + 0x00dc)
	call	(xix)
.LRF_267c:
	pop xiz                                 ; pop XIZ
	lda	xsp, (xsp+48)
	ret

	dec 0, xsp                              ; dec 0,XSP
	push xiz
	ld	xiz, xde
	ld (xsp + 0x04), xbc                    ; ld (XSP+0x04),XBC
	ld (xsp + 0x08), xwa                    ; ld (XSP+0x08),XWA
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	cp	xwa, 0x01c00002
	jrl z, .LRF_276e                       ; [76 d6 00] jrl Z,0x28276e
	cp	xwa, 0x01c00001
	jr z, .LRF_2704                        ; [66 64] jr Z,0x282704
	cp	xwa, 0x01c0000d
	jr z, .LRF_26c4                        ; [66 1c] jr Z,0x2826c4
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	xde, xiz
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xix, (xhl + 0x00dc)
	call	(xix)
	jrl t, .LRF_27a4                       ; [78 e0 00] jrl T,0x2827a4
.LRF_26c4:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	xde, xiz
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	lda_24 xwa, 0x2e21d8
	ld	xbc, xwa
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	xde, xbc
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xhl, (xbc + 0x0100)
	ld	xbc, 0x01c0000f
	call	(xhl)
	lds32	xhl, 0
	jrl t, .LRF_27a4                       ; [78 a0 00] jrl T,0x2827a4
.LRF_2704:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	xde, xiz
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	xbc, (0x23a1a2)
	ld_sril	xbc, (xbc + 0x0e0a)
	ld_sril	xix, (xbc + 0x02c4)
	call	(xix)
	ld xde, (xhl + 0x16)                    ; ld XDE,(XHL+0x16)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f01ae
	ld	xbc, 0x01e0007b
	call	(xhl)
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f01ae
	lds32	xde, 0
	call	(xhl)
	lds32	xhl, 0
	jr t, .LRF_27a4                        ; [68 36] jr T,0x2827a4
.LRF_276e:
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f01ae
	lds32	xde, 0
	call	(xhl)
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	xde, xiz
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	lds32	xhl, 0
.LRF_27a4:
	pop xiz                                 ; pop XIZ
	inc 0, xsp                              ; inc 0,XSP
	ret

	ld	xhl, xbc
	cp	xhl, 0x01c0000f
	jr z, .LRF_27c3                        ; [66 11] jr Z,0x2827c3
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xix, (xhl + 0x00dc)
	jp	(xix)
.LRF_27c3:
	ld	xhl, (0x23a1a2)
	ld_sril	xhl, (xhl + 0x0e0a)
	ld_sril	xhl, (xhl + 0x00dc)
	call	(xhl)
	ld	xwa, (0x23a1a2)
	ld_sril	xwa, (xwa + 0x0e0a)
	ld_sril	xhl, (xwa + 0x0100)
	ld	xwa, 0x007f01ed
	ld	xbc, 0x01c0000d
	lds32	xde, 0
	call	(xhl)
	lds32	xhl, 0
	ret


HDAE5000_Event_Handler:	; 0x2827F4 (932 bytes)
	; Event handler - processes firmware events dispatched to HDAE5000
	; Entry point 1: vtable trampoline — registers callback via vtable, then jp (xhl)
	ld xde, xwa					; e8 8a
	ldl_da xwa, 0x23a1a2			; e2 a2 a1 23 20 — load context base
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20 — xwa = (xwa+0x0e0a) vtable ptr
	ld_sril xhl, (xwa + 0x0100)             ; e3 e1 00 01 23 — xhl = (xwa+0x0100) callback
	ld xwa, 0xffffffff				; 40 ff ff ff ff
	ld xbc, 0x01c00025				; 41 25 00 c0 01
	jp (xhl)					; b3 d8
	; Entry point 2: main event handler dispatcher
.Leh_main:
	dec 0, xsp					; ef 68 — allocate stack frame
	push xiz					; 3e
	ld (xsp + 0x04), xde				; bf 04 62 — save XDE
	ld (xsp + 0x08), xbc				; bf 08 61 — save XBC
	ld xiz, xwa					; e8 8e — save context in XIZ
	ld xwa, (xsp + 0x08)				; af 08 20 — load event code
	cp xwa, 0x01c00007				; e8 cf 07 00 c0 01
	jr z, .Leh_event_c00007			; 66 55
	cp xwa, 0x01c0000d				; e8 cf 0d 00 c0 01
	jr z, .Leh_event_c0000d			; 66 0e
	cp xwa, 0x01e00085				; e8 cf 85 00 e0 01
	jrl nz, .Leh_epilogue				; 7e 43 03
	; Event 0x01E00085: return 1 (acknowledge)
	lds32 xhl, 1					; eb a9
	jrl t, .Leh_return				; 78 57 03
	; Event 0x01C0000D: forward to vtable callback
.Leh_event_c0000d:
	ld xwa, xiz					; ee 88 — restore context
	ld xbc, (xsp + 0x08)				; af 08 21
	ld xde, (xsp + 0x04)				; af 04 22
	ldl_da xhl, 0x23a1a2			; e2 a2 a1 23 23
	ld_sril xhl, (xhl + 0x0e0a)             ; e3 ed 0a 0e 23 — xhl = (xhl+0x0e0a)
	ld_sril xhl, (xhl + 0x00dc)             ; e3 ed dc 00 23 — xhl = (xhl+0x00dc) indirect call
	call (xhl)					; b3 e8
	lda_24 xwa, 0x2e21de			; f2 de 21 2e 30
	ld xbc, xwa					; e8 89
	ld xwa, xiz					; ee 88
	ld xde, xbc					; e9 8a
	ldl_da xbc, 0x23a1a2			; e2 a2 a1 23 21
	ld_sril xbc, (xbc + 0x0e0a)             ; e3 e5 0a 0e 21 — xbc = (xbc+0x0e0a)
	ld_sril xhl, (xbc + 0x0100)             ; e3 e5 00 01 23 — xhl = (xbc+0x0100) callback
	ld xbc, 0x01c0000f				; 41 0f 00 c0 01
	call (xhl)					; b3 e8
	lds32 xhl, 0					; eb a8
	jrl t, .Leh_return				; 78 18 03
	; Event 0x01C00007: sub-dispatch on XDE value
.Leh_event_c00007:
	ld xwa, (xsp + 0x04)				; af 04 20 — load XDE arg
	cp xwa, 0x0000000c				; e8 cf 0c 00 00 00
	jrl z, .Leh_xde_0c				; 76 62 02
	cp xwa, 0x0000000b				; e8 cf 0b 00 00 00
	jrl z, .Leh_xde_0b				; 76 6a 01
	cp xwa, 0x0000000a				; e8 cf 0a 00 00 00
	jrl z, .Leh_xde_0a				; 76 b5 00
	cp xwa, 0x00000009				; e8 cf 09 00 00 00
	jrl nz, .Leh_epilogue				; 7e d8 02
	; XDE == 0x09: register event 0x4B, call init, register vtable callback
.Leh_xde_09:
	ldl_da xwa, 0x23a1a2			; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0100)             ; e3 e1 00 01 23 — callback ptr
	ld xwa, 0x007f004b				; 40 4b 00 7f 00
	ld xbc, 0x01c0000f				; 41 0f 00 c0 01
	lds32 xde, 1					; ea a9
	call (xhl)					; b3 e8 — register event
	ldl_da xwa, 0x23a1a2			; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0084)             ; e3 e1 84 00 23 — (xwa+0x0084) init fn
	call (xhl)					; b3 e8 — call init
	call HDAE5000_Wait_Callback_Loop		; 1d 2b b2 28
	lda_24 xwa, 0x2e21e4			; f2 e4 21 2e 30
	calr HDAE5000_Event_Handler			; 1e 17 ff — register handler
	calr HDAE5000_PPI_Read_Register		; 1e 47 03
	ldl_da xwa, 0x23a1a2			; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0100)             ; e3 e1 00 01 23
	ld xwa, 0x007f004b				; 40 4b 00 7f 00
	ld xbc, 0x01c0000f				; 41 0f 00 c0 01
	lds32 xde, 0					; ea a8
	call (xhl)					; b3 e8 — unregister event
	ldl_da xwa, 0x23a1a2			; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xix, (xwa + 0x0100)             ; e3 e1 00 01 24 — xix = callback
	ld xwa, 0x007f0049				; 40 49 00 7f 00
	ld xbc, 0x01e0006b				; 41 6b 00 e0 01
	lds32 xde, 0					; ea a8
	call (xix)					; b4 e8
	cp xhl, 0x00000001				; eb cf 01 00 00 00
	jrl nz, .Leh_epilogue				; 7e 58 02
	; Post-call: push event/subcode, invoke dispatch
	ld xwa, 0x01c00007				; 40 07 00 c0 01
	push xwa					; 38
	ld xwa, 0x0000000a				; 40 0a 00 00 00
	push xwa					; 38
	ld xbc, xiz					; ee 89
	ldl_da xwa, 0x23a1a2			; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0410)             ; e3 e1 10 04 23 — (xwa+0x0410) dispatch
	ld xwa, 0x00000029				; 40 29 00 00 00
	ld xde, 0xffffffff				; 42 ff ff ff ff
	call (xhl)					; b3 e8
	jrl t, .Leh_epilogue				; 78 2c 02
	; XDE == 0x0A: register event 0x4D, write sector
.Leh_xde_0a:
	ldl_da xwa, 0x23a1a2			; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0100)             ; e3 e1 00 01 23
	ld xwa, 0x007f004d				; 40 4d 00 7f 00
	ld xbc, 0x01c0000f				; 41 0f 00 c0 01
	lds32 xde, 1					; ea a9
	call (xhl)					; b3 e8
	ldl_da xwa, 0x23a1a2			; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0084)             ; e3 e1 84 00 23 — init fn
	call (xhl)					; b3 e8
	call HDAE5000_Wait_Callback_Loop		; 1d 2b b2 28
	lda_24 xwa, 0x2e21f0			; f2 f0 21 2e 30
	calr HDAE5000_Event_Handler			; 1e 6b fe
	calr HDAE5000_PPI_Write_Sector			; 1e e2 02
	ldl_da xwa, 0x23a1a2			; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0100)             ; e3 e1 00 01 23
	ld xwa, 0x007f004d				; 40 4d 00 7f 00
	ld xbc, 0x01c0000f				; 41 0f 00 c0 01
	lds32 xde, 0					; ea a8
	call (xhl)					; b3 e8
	ldl_da xwa, 0x23a1a2			; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xix, (xwa + 0x0100)             ; e3 e1 00 01 24
	ld xwa, 0x007f0049				; 40 49 00 7f 00
	ld xbc, 0x01e0006b				; 41 6b 00 e0 01
	lds32 xde, 0					; ea a8
	call (xix)					; b4 e8
	cp xhl, 0x00000001				; eb cf 01 00 00 00
	jrl nz, .Leh_epilogue				; 7e ac 01
	ld xwa, 0x01c00007				; 40 07 00 c0 01
	push xwa					; 38
	ld xwa, 0x0000000b				; 40 0b 00 00 00
	push xwa					; 38
	ld xbc, xiz					; ee 89
	ldl_da xwa, 0x23a1a2			; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0410)             ; e3 e1 10 04 23
	ld xwa, 0x00000029				; 40 29 00 00 00
	ld xde, 0xffffffff				; 42 ff ff ff ff
	call (xhl)					; b3 e8
	jrl t, .Leh_epilogue				; 78 80 01
	; XDE == 0x0B: register event 0x4C, read/check disk status
.Leh_xde_0b:
	ldl_da xwa, 0x23a1a2			; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0100)             ; e3 e1 00 01 23
	ld xwa, 0x007f004c				; 40 4c 00 7f 00
	ld xbc, 0x01c0000f				; 41 0f 00 c0 01
	lds32 xde, 1					; ea a9
	call (xhl)					; b3 e8
	ldl_da xwa, 0x23a1a2			; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0084)             ; e3 e1 84 00 23
	call (xhl)					; b3 e8
	call HDAE5000_Wait_Callback_Loop		; 1d 2b b2 28
	lda_24 xwa, 0x2e21fc			; f2 fc 21 2e 30
	calr HDAE5000_Event_Handler			; 1e bf fd
	; Check disk status via 0x0e88 table
	ldl_da xwa, 0x23a1a2			; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e88)             ; e3 e1 88 0e 20 — (xwa+0x0e88)
	ld xix, (xwa + 0x08)				; a8 08 24
	call (xix)					; b4 e8
	cps l, 3					; cf db
	jr z, .Leh_status_2or3			; 66 04
	cps l, 2					; cf da
	jr nz, .Leh_status_other			; 6e 27
.Leh_status_2or3:
	ldl_da xwa, 0x23a1a2			; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e88)             ; e3 e1 88 0e 20
	ld xix, (xwa + 0x04)				; a8 04 24
	call (xix)					; b4 e8
	cps hl, 0					; db d8
	jr nz, .Leh_status_nonzero			; 6e 0a
	lda_24 xwa, 0x2e2204			; f2 04 22 2e 30
	calr HDAE5000_Event_Handler			; 1e 8d fd
	jr t, .Leh_after_status			; 68 12
.Leh_status_nonzero:
	lda_24 xwa, 0x2e2208			; f2 08 22 2e 30
	calr HDAE5000_Event_Handler			; 1e 83 fd
	jr t, .Leh_after_status			; 68 08
.Leh_status_other:
	lda_24 xwa, 0x2e220e			; f2 0e 22 2e 30
	calr HDAE5000_Event_Handler			; 1e 79 fd
.Leh_after_status:
	ldl_da xwa, 0x23a1a2			; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0100)             ; e3 e1 00 01 23
	ld xwa, 0x007f004c				; 40 4c 00 7f 00
	ld xbc, 0x01c0000f				; 41 0f 00 c0 01
	lds32 xde, 0					; ea a8
	call (xhl)					; b3 e8
	ldl_da xwa, 0x23a1a2			; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xix, (xwa + 0x0100)             ; e3 e1 00 01 24
	ld xwa, 0x007f0049				; 40 49 00 7f 00
	ld xbc, 0x01e0006b				; 41 6b 00 e0 01
	lds32 xde, 0					; ea a8
	call (xix)					; b4 e8
	cp xhl, 0x00000001				; eb cf 01 00 00 00
	jrl nz, .Leh_epilogue				; 7e bd 00
	ld xwa, 0x01c00007				; 40 07 00 c0 01
	push xwa					; 38
	ld xwa, 0x00000009				; 40 09 00 00 00
	push xwa					; 38
	ld xbc, xiz					; ee 89
	ldl_da xwa, 0x23a1a2			; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0410)             ; e3 e1 10 04 23
	ld xwa, 0x00000029				; 40 29 00 00 00
	ld xde, 0xffffffff				; 42 ff ff ff ff
	call (xhl)					; b3 e8
	jrl t, .Leh_epilogue				; 78 91 00
	; XDE == 0x0C: check device, show status messages
.Leh_xde_0c:
	ldl_da xwa, 0x23a1a2			; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xix, (xwa + 0x0100)             ; e3 e1 00 01 24
	ld xwa, 0x007f0049				; 40 49 00 7f 00
	ld xbc, 0x01e0006b				; 41 6b 00 e0 01
	lds32 xde, 0					; ea a8
	call (xix)					; b4 e8
	cp xhl, 0x00000001				; eb cf 01 00 00 00
	jr nz, .Leh_xde_0c_no_device			; 6e 27
	; Device present: show "connected" message
	ldl_da xwa, 0x23a1a2			; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0100)             ; e3 e1 00 01 23
	ld xwa, 0x007f0049				; 40 49 00 7f 00
	ld xbc, 0x01e0003b				; 41 3b 00 e0 01
	lds32 xde, 0					; ea a8
	call (xhl)					; b3 e8
	lda_24 xwa, 0x2e2214			; f2 14 22 2e 30
	calr HDAE5000_Event_Handler			; 1e c0 fc
	jr t, .Leh_epilogue				; 68 45
.Leh_xde_0c_no_device:
	; Device not present: show "not connected" message
	ldl_da xwa, 0x23a1a2			; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0100)             ; e3 e1 00 01 23
	ld xwa, 0x007f0049				; 40 49 00 7f 00
	ld xbc, 0x01e0003b				; 41 3b 00 e0 01
	lds32 xde, 1					; ea a9
	call (xhl)					; b3 e8
	lda_24 xwa, 0x2e2224			; f2 24 22 2e 30
	calr HDAE5000_Event_Handler			; 1e 99 fc
	; Final cleanup: call deregister via vtable
	ldl_da xwa, 0x23a1a2			; e2 a2 a1 23 20
	ld_sril xwa, (xwa + 0x0e0a)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + 0x0104)             ; e3 e1 04 01 23 — (xwa+0x0104) deregister
	ld xwa, 0xffffffff				; 40 ff ff ff ff
	ld xbc, 0x01c00007				; 41 07 00 c0 01
	ld xde, 0x00000009				; 42 09 00 00 00
	call (xhl)					; b3 e8
	; Epilogue: restore regs, call cleanup callback, return
.Leh_epilogue:
	ld xwa, xiz					; ee 88
	ld xbc, (xsp + 0x08)				; af 08 21
	ld xde, (xsp + 0x04)				; af 04 22
	ldl_da xhl, 0x23a1a2			; e2 a2 a1 23 23
	ld_sril xhl, (xhl + 0x0e0a)             ; e3 ed 0a 0e 23 — xhl = (xhl+0x0e0a)
	ld_sril xix, (xhl + 0x00dc)             ; e3 ed dc 00 24 — xix = (xhl+0x00dc)
	call (xix)					; b4 e8
.Leh_return:
	pop xiz					; 5e
	inc 0, xsp					; ef 60 — deallocate stack frame
	ret						; 0e

; --- PPI/IDE Low-Level I/O ---
HDAE5000_PPI_Init:	; 0x282B98 (13 bytes)
	; Initialize 8255 PPI: control=0x90 (mode set), port A=0xFF (all bits high)
	stib_da 0x160006, 0x90                 ; ld (0x160006), 0x90 - PPI control: mode 0, all output
	stib_da 0x160000, 0xff                 ; ld (0x160000), 0xFF - Port A: set all bits
	ret

HDAE5000_PPI_Transfer_Byte:	; 0x282BA5 (130 bytes)
	; Transfer one byte via PPI to/from IDE bus
	; Input: A = byte to transfer. Returns: L = 0x00 on match, 0xFF on mismatch
	; --- Low nibble phase ---
	ld l, a				; save original byte
	and a, 0x0f			; mask low nibble
	set 4, a			; set bit 4 (data strobe)
	sll a, 3			; shift left 3
	stb_da 0x160002, a                    ; ld (0x160002), A — PPI port B
	ld c, a				; save port B value
	srl c, 6			; shift right 6 for port C
	stb_da 0x160004, c                    ; ld (0x160004), C — PPI port C
	res 7, a			; clear bit 7 (handshake low)
	srl a, 6			; shift right 6
	stb_da 0x160004, a                    ; ld (0x160004), A — PPI port C
	ld xwa, 0x000003E8		; timeout counter (1000)
.Lppi_wait_high:
	bitda_24 4, 1441792		; bit 4, (0x160000) — check ACK
	jr z, .Lppi_wait_high		; wait until bit 4 set
	ldb_da a, 0x160000                    ; ld A, (0x160000) — read port A
	and a, 0x0f			; mask low nibble
	ld e, a				; save low nibble in E
	; --- High nibble phase ---
	ld a, l				; restore original byte
	srl a, 1			; shift right 1
	res 7, a			; clear bit 7
	stb_da 0x160002, a                    ; ld (0x160002), A — PPI port B
	ld c, a				; save port B value
	srl c, 6			; shift right 6 for port C
	stb_da 0x160004, c                    ; ld (0x160004), C — PPI port C
	set 7, a			; set bit 7 (handshake high)
	srl a, 6			; shift right 6
	stb_da 0x160004, a                    ; ld (0x160004), A — PPI port C
	ld xwa, 0x000003E8		; timeout counter (1000)
.Lppi_wait_low:
	bitda_24 4, 1441792		; bit 4, (0x160000) — check ACK
	jr nz, .Lppi_wait_low		; wait until bit 4 clear
	; --- Reassemble and verify ---
	ld c, e				; C = low nibble
	ldb_da a, 0x160000                    ; ld A, (0x160000) — read port A
	and a, 0x0f			; mask low nibble (high nibble of result)
	sll a, 4			; shift left 4 to high position
	or a, c				; combine with low nibble
	cp a, l				; compare with original byte
	jr nz, .Lppi_fail		; if mismatch, fail
	ldb l, 0x00			; success: L = 0
	ret
.Lppi_fail:
	ldb l, 0xFF			; failure: L = 0xFF
	ret

HDAE5000_PPI_Read_Register:	; 0x282C27 (71 bytes)
	; Read an IDE register value via PPI
	; Reads register pair (low byte at IZ=0, high byte at IZ=1)
	; Returns 16-bit value in (XSP+2), reports event on success
	dec 2, xsp
	pushw iz
	ldw (xsp + 2), 0x0000		; result = 0
	calr HDAE5000_PPI_Init
	lds iz, 0			; IZ = 0 (loop counter)
	cp iz, 0x0100
	jr ge, .Lppi_rd_loop_end
.Lppi_rd_loop:
	stb_erp a, 0xf8		; ld a, izl (extended register)
	extz wa
	calr HDAE5000_PPI_Transfer_Byte
	ld a, l				; result byte from transfer
	exts wa				; sign-extend to 16-bit
	or (xsp + 2), wa		; OR into result word
	inc 1, iz
	cp iz, 0x0100
	jr lt, .Lppi_rd_loop
.Lppi_rd_loop_end:
	cpw (xsp + 2), 0x0000	; test if result is zero
	jr nz, .Lppi_rd_nonzero
	lda_24 xwa, 0x2e2234                  ; 0x2E2234 - error event string
	calr HDAE5000_Event_Handler
	jr t, .Lppi_rd_done
.Lppi_rd_nonzero:
	lda_24 xwa, 0x2e224a                  ; 0x2E224A - success event string
	calr HDAE5000_Event_Handler
.Lppi_rd_done:
	popw iz
	inc 2, xsp
	ret

HDAE5000_PPI_Write_Sector:	; 0x282C6E (192 bytes)
	; Write a sector of data to HD via PPI
	; Large 124-byte stack frame for sector buffer and parameter blocks
	lda xsp, (xsp - 124)		; allocate stack frame
	lds wa, 0
	call 0x293E88
	cps hl, 0
	jrl nz, .Lpws_error
	lda xwa, (xsp + 72)
	call 0x297573
	; MemFill: clear 32-byte buffer
	pushw 0x0020			; count = 32
	pushw 0x0000			; fill value = 0
	lda xwa, (xsp + 28)
	push xwa			; buffer address
	call HDAE5000_MemFill
	; MemCopy_Block: copy 46 bytes from 0x2264 offset
	pushw 0x002E			; count = 46
	pushw 0x2264			; source offset
	lda xwa, (xsp + 36)
	push xwa			; dest address
	call HDAE5000_MemCopy_Block
	; MemCopy: copy 10 bytes between buffers
	pushw 0x000A			; count = 10
	lda xwa, (xsp + 100)
	push xwa			; source
	lda xwa, (xsp + 56)
	push xwa			; dest
	call HDAE5000_MemCopy
	lda xsp, (xsp + 26)		; pop all args (26 bytes)
	; Transfer byte to PPI
	lda xwa, (xsp + 24)
	calr HDAE5000_Event_Handler
	; Write sector data
	lda xwa, (xsp + 56)
	call 0x298B6C
	; MemFill: clear buffer again
	pushw 0x0020			; count = 32
	pushw 0x0000			; fill value = 0
	lda xwa, (xsp + 28)
	push xwa			; buffer address
	call HDAE5000_MemFill
	; Compare and copy operations
	lda xbc, (xsp + 76)
	lda xwa, (xsp + 20)
	call 0x29B815
	lda xbc, (xsp + 20)
	lda_24 xde, 0x2e22aa                  ; 0x2E22AA
	lda xwa, (xsp + 20)
	call 0x29B840
	lda xbc, (xsp + 20)
	lda xwa, (xsp + 24)
	call 0x29BA20
	; Copy block via PPI
	lda xiy, (xsp + 24)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy + 0)
	push xix
	pushw 0x002E			; count = 46
	pushw 0x2270			; offset
	lda xwa, (xsp + 44)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda xsp, (xsp + 24)		; pop args
	; Transfer results
	lda xwa, (xsp + 24)
	calr HDAE5000_Event_Handler
	lda_24 xwa, 0x2e2286                  ; 0x2E2286
	calr HDAE5000_Event_Handler
	lda_24 xwa, 0x2e2288                  ; 0x2E2288
	calr HDAE5000_Event_Handler
	jr t, .Lpws_done
.Lpws_error:
	lda_24 xwa, 0x2e2298                  ; 0x2E2298
	calr HDAE5000_Event_Handler
.Lpws_done:
	lda xsp, (xsp + 124)		; deallocate stack frame
	ret

HDAE5000_PPI_Read_Sector:	; 0x282D2E (270 bytes)
	; Read a sector of data from HD via PPI
	; Registers PPI device handlers for read operations via workspace dispatch
	; Copy 14 bytes: source table → PPI buffer
	pushw 0x000E			; count = 14
	lda_24 xwa, 0x2e1ce6                  ; 0x2E1CE6
	push xwa			; source
	lda_24 xwa, 0x22aa9c                  ; 0x22AA9C
	push xwa			; dest
	call HDAE5000_MemCopy
	lda xsp, (xsp + 10)		; pop args
	; Register PPI device: first handler pair (0xDE)
	lda_24 xwa, 0x22aa9c                  ; 0x22AA9C - buffer ptr
	ld xde, xwa
	ldl_da xwa, 0x23a1a2                 ; workspace ptr (0x23A1A2)
	ld_sril xwa, (xwa + 0x0e0a)             ; (XWA + 0x0E0A)
	ld_sril xhl, (xwa + 0x0124)             ; (XWA + 0x0124)
	ld xwa, 0x007F00DE
	ld xbc, 0x01EA000A
	call (xhl)
	; Register second handler (0xDE, different params)
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)
	ld xwa, 0x007F00DE
	ld xbc, 0x01C0000F
	ld xde, 0xFFFFFFFF
	call (xhl)
	; Copy 241 bytes: second table → PPI buffer
	pushw 0x00F1			; count = 241
	lda_24 xwa, 0x2e1cf4                  ; 0x2E1CF4
	push xwa			; source
	lda_24 xwa, 0x22aaaa                  ; 0x22AAAA
	push xwa			; dest
	call HDAE5000_MemCopy
	lda xsp, (xsp + 10)		; pop args
	; Register PPI device: second handler pair (0xD7)
	lda_24 xwa, 0x22aaaa                  ; 0x22AAAA
	ld xde, xwa
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)
	ld xwa, 0x007F00D7
	ld xbc, 0x01EA000A
	call (xhl)
	; Second handler (0xD7, different params)
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)
	ld xwa, 0x007F00D7
	ld xbc, 0x01C0000F
	ld xde, 0xFFFFFFFF
	call (xhl)
	; Register third handler (0xD9)
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)
	ld xwa, 0x007F00D9
	ld xbc, 0x01C0000D
	lds32 xde, 0
	call (xhl)
	; Register fourth handler (0xD8)
	ldl_da xwa, 0x23a1a2
	ld_sril xwa, (xwa + 0x0e0a)
	ld_sril xhl, (xwa + 0x0124)
	ld xwa, 0x007F00D8
	ld xbc, 0x01C0000D
	lds32 xde, 0
	call (xhl)
	; Clear two 20-byte buffers
	pushw 0x0014			; count = 20
	pushw 0x0000			; fill = 0
	lda_24 xwa, 0x22ab9c                  ; 0x22AB9C
	push xwa
	call HDAE5000_MemFill
	pushw 0x0014			; count = 20
	pushw 0x0000			; fill = 0
	lda_24 xwa, 0x22abb0                  ; 0x22ABB0
	push xwa
	call HDAE5000_MemFill
	lda xsp, (xsp + 16)		; pop all args (16 bytes)
	ret

HDAE5000_PPI_Transfer_Block:	; 0x282E3C (81 bytes)
	; Transfer a block of data via PPI
	; Iterates entries 1..20, copies block via PPI_Block_Copy, validates buffer,
	; then compares with MemCompare_Block. Returns matching index-1 or 0xFFFF.
	dec 0, xsp			; allocate 8 bytes on stack
	pushw iz
	ld (xsp + 6), xwa		; save input parameter
	lds iz, 1			; IZ = 1 (entry counter)
	cp iz, 0x0014
	jr gt, .Lptb_not_found
.Lptb_loop:
	pushw iz
	pushw 0x002E			; block size = 46
	pushw 0x22AE			; source base address
	lda xwa, (xsp + 8)		; pointer to local buffer
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda xwa, (xsp + 0x0C)		; pointer to compare buffer
	push xwa
	call HDAE5000_Display_Buffer_Validate
	pushw hl			; save validation result
	ld xwa, (xsp + 0x16)		; reload input parameter
	push xwa
	lda xwa, (xsp + 0x16)		; pointer to local buffer
	push xwa
	call HDAE5000_MemCompare_Block
	add xsp, 0x00000018		; clean up stack (24 bytes)
	cps hl, 0			; check compare result
	jr nz, .Lptb_found
	ld hl, iz			; return index - 1
	dec 1, hl
	jr t, .Lptb_done
.Lptb_found:
	inc 1, iz
	cp iz, 0x0014
	jr le, .Lptb_loop
.Lptb_not_found:
	ldw hl, 0xFFFF			; return -1 (not found)
.Lptb_done:
	popw iz
	inc 0, xsp			; deallocate 8 bytes
	ret

; --- HD Drive Setup and Configuration ---

; --- HD (IDE/ATA) Driver ---
	.include "hdae5000_hd_driver.s"

; --- FAT16 Filesystem ---
	.include "hdae5000_filesystem.s"

; --- Menu UI & Display ---
	.include "hdae5000_ui_display.s"

; --- Utility & Math Functions ---
	.include "hdae5000_utilities.s"

; --- Data Tables, Config, Graphics & Strings ---
	.include "hdae5000_data_tables.s"

