
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
	jp 0x28F576	; Called when main CPU validates HDAE5000 presence

; Padding after vector
	ret
	nop
	nop
	nop

; Entry point 2 - Jump to frame handler (called periodically)
HDAE5000_ENTRY_2:	; 280010h
	jp 0x28F662	; Called from main loop for HD status updates

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
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E	; Handler dispatch table
	ld_sril3 XWA, 0xE1, 0x68, 0x01	; Handler function via table offset 0x0168
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA  ; handler function ptr
	ldda16_24 xwa, 2742654
	ld (xsp + 8), wa	; ld (XSP+0x08), WA   ; record count (= 13)
	ldada_24 xwa, 2736298
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA  ; data pointer
	lda xwa, (xsp)	; lda XWA, XSP  ; XWA = param block ptr
	ld xbc, xwa	; XBC = param block ptr
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XHL, 0xE1, 0xE4, 0x00	; RegisterObjectTable function
	ldw wa, 0x16A	; Handler ID
	call (xhl)	; Register handler

	; === Handler 2: RAM data area A (ID=0x01CA, port=0x0160000C) ===
	ld xwa, 0x160000C	; PPI port address
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XWA, 0xE1, 0x3C, 0x01	; Handler function via table offset 0x013C
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldda16_24 xwa, 2332706
	ld (xsp + 8), wa	; ld (XSP+0x08), WA   ; data size (variable)
	ldada_24 xwa, 2332650
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XHL, 0xE1, 0xE4, 0x00	; RegisterObjectTable
	ldw wa, 0x1CA	; Handler ID
	call (xhl)

	; === Handler 3: RAM data area B (ID=0x01EA, port=0x0160000D) ===
	ld xwa, 0x160000D	; PPI port address
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XWA, 0xE1, 0x40, 0x01	; Handler function via table offset 0x0140
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldda16_24 xwa, 2332784
	ld (xsp + 8), wa	; ld (XSP+0x08), WA   ; data size (variable)
	ldada_24 xwa, 2332708
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XHL, 0xE1, 0xE4, 0x00	; RegisterObjectTable
	ldw wa, 0x1EA	; Handler ID
	call (xhl)

	; === Handler 4: Init data primary (ID=0x012A, port=0x01600002) ===
	ld xwa, 0x1600002	; PPI port address
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XWA, 0xE1, 0x48, 0x02	; Handler function via table offset 0x0248
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldmw (xsp + 8), 0x45	; ld (XSP+0x08), 0045h  ; size = 69 bytes
	ldada_24 xwa, 2331946
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XHL, 0xE1, 0xE4, 0x00	; RegisterObjectTable
	ldw wa, 0x12A	; Handler ID
	call (xhl)

	; === Handler 5: Init data secondary (ID=0x042A, port=0x01600002) ===
	ld xwa, 0x1600002	; PPI port address
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XWA, 0xE1, 0x48, 0x02	; Handler function via table offset 0x0248
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldmw (xsp + 8), 0x45	; ld (XSP+0x08), 0045h  ; size = 69 bytes
	ldada_24 xwa, 2332226
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XHL, 0xE1, 0xE4, 0x00	; RegisterObjectTable
	ldw wa, 0x42A	; Handler ID
	call (xhl)

	; === Handler 6: Serial data primary (ID=0x010A, port=0x01600001) ===
	ld xwa, 0x1600001	; PPI port address
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XWA, 0xE1, 0x44, 0x02	; Handler function via table offset 0x0244
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldmw (xsp + 8), 0xD	; ld (XSP+0x08), 000Dh  ; size = 13 bytes
	ldada_24 xwa, 2332786
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XHL, 0xE1, 0xE4, 0x00	; RegisterObjectTable
	ldw wa, 0x10A	; Handler ID
	call (xhl)

	; === Handler 7: Serial data secondary (ID=0x040A, port=0x01600001) ===
	ld xwa, 0x1600001	; PPI port address
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XWA, 0xE1, 0x44, 0x02	; Handler function via table offset 0x0244
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldmw (xsp + 8), 0xD	; ld (XSP+0x08), 000Dh  ; size = 13 bytes
	ldada_24 xwa, 2332842
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XHL, 0xE1, 0xE4, 0x00	; RegisterObjectTable
	ldw wa, 0x40A	; Handler ID
	call (xhl)

	; === Handler 8: Parallel data primary (ID=0x014A, port=0x01600003) ===
	ld xwa, 0x1600003	; PPI port address
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XWA, 0xE1, 0x4C, 0x02	; Handler function via table offset 0x024C
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldmw (xsp + 8), 0xE	; ld (XSP+0x08), 000Eh  ; size = 14 bytes
	ldada_24 xwa, 2334674
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XHL, 0xE1, 0xE4, 0x00	; RegisterObjectTable
	ldw wa, 0x14A	; Handler ID
	call (xhl)

	; === Handler 9: Parallel data secondary (ID=0x044A, port=0x01600003) ===
	ld xwa, 0x1600003	; PPI port address
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XWA, 0xE1, 0x4C, 0x02	; Handler function via table offset 0x024C
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldmw (xsp + 8), 0xE	; ld (XSP+0x08), 000Eh  ; size = 14 bytes
	ldada_24 xwa, 2334734
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XHL, 0xE1, 0xE4, 0x00	; RegisterObjectTable
	ldw wa, 0x44A	; Handler ID
	call (xhl)

	; === Handler 10: Graphics data primary (ID=0x007F, port=0x01600010) ===
	ld xwa, 0x1600010	; PPI port address
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XWA, 0xE1, 0x80, 0x02	; Handler function via table offset 0x0280
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldmw (xsp + 8), 0x315	; ld (XSP+0x08), 0315h  ; size = 789 bytes
	ldada_24 xwa, 2776364
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XHL, 0xE1, 0xE4, 0x00	; RegisterObjectTable
	ldw wa, 0x7F	; Handler ID
	call (xhl)

	; === Handler 11: Graphics data secondary (ID=0x037F, port=0x0160000F) ===
	ld xwa, 0x160000F	; PPI port address
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XWA, 0xE1, 0x48, 0x01	; Handler function via table offset 0x0148
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldmw (xsp + 8), 0x315	; ld (XSP+0x08), 0315h  ; size = 789 bytes
	ldada_24 xwa, 2779524
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XHL, 0xE1, 0xE4, 0x00	; RegisterObjectTable
	ldw wa, 0x37F	; Handler ID
	call (xhl)

	; === Final special call via workspace dispatch offset 0x0270 ===
	; Passes additional parameters for graphics initialization
	pushw 0xA	; push 10 bytes (param size)
	ldada_24 xwa, 2786458
	push xwa	; push pointer to init params
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XHL, 0xE1, 0x70, 0x02	; Special dispatch function
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
	ldada_24 xhl, 2787726	; Palette data pointer 1
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
	ldada_24 xhl, 2865550	; Palette data pointer 2
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
	ldada_24 xhl, 2943374	; Palette data pointer 3
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
	ldada_24 xhl, 3021198	; Palette data pointer 4
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
	; Register frame handler callback with main CPU
	; Clears 0x23A08E, 0x23A092, 0x23A094 and initializes display data
	; Contains multiple sub-routines for event registration and dispatch
	.incbin "includes/code_2803c2_28f542.bin", 0, 9266

HDAE5000_Event_Handler:	; 0x2827F4 (932 bytes)
	; Event handler - processes firmware events dispatched to HDAE5000
	.incbin "includes/code_2803c2_28f542.bin", 9266, 932

; --- PPI/IDE Low-Level I/O ---
HDAE5000_PPI_Init:	; 0x282B98 (13 bytes)
	; Initialize 8255 PPI: control=0x90 (mode set), port A=0xFF (all bits high)
	stdi8_24 1441798, 144	; ld (0x160006), 0x90 - PPI control: mode 0, all output
	stdi8_24 1441792, 255	; ld (0x160000), 0xFF - Port A: set all bits
	ret

HDAE5000_PPI_Transfer_Byte:	; 0x282BA5 (130 bytes)
	; Transfer one byte via PPI to/from IDE bus
	; Writes to ports B,C; reads from port A with handshake
	.incbin "includes/code_2803c2_28f542.bin", 10211, 130

HDAE5000_PPI_Read_Register:	; 0x282C27 (71 bytes)
	; Read an IDE register value via PPI
	; Reads register pair (low byte at IZ=0, high byte at IZ=1)
	; Returns 16-bit value in (XSP+2), reports event on success
	dec 2, xsp
	pushw iz
	ldmw (xsp + 2), 0x0000		; result = 0
	calr HDAE5000_PPI_Init
	lds iz, 0			; IZ = 0 (loop counter)
	cp iz, 0x0100
	jr ge, .Lppi_rd_loop_end
.Lppi_rd_loop:
	.byte 0xc7, 0xf8, 0x89		; ld a, izl (extended register)
	extz wa
	calr HDAE5000_PPI_Transfer_Byte
	ld a, l				; result byte from transfer
	exts wa				; sign-extend to 16-bit
	or (xsp + 2), wa		; OR into result word
	inc 1, iz
	cp iz, 0x0100
	jr lt, .Lppi_rd_loop
.Lppi_rd_loop_end:
	cpmi16 (xsp + 2), 0x0000	; test if result is zero
	jr nz, .Lppi_rd_nonzero
	ldada_24 xwa, 3023412		; 0x2E2234 - error event string
	calr HDAE5000_Event_Handler
	jr t, .Lppi_rd_done
.Lppi_rd_nonzero:
	ldada_24 xwa, 3023434		; 0x2E224A - success event string
	calr HDAE5000_Event_Handler
.Lppi_rd_done:
	popw iz
	inc 2, xsp
	ret

HDAE5000_PPI_Write_Sector:	; 0x282C6E (192 bytes)
	; Write a sector of data to HD via PPI
	.incbin "includes/code_2803c2_28f542.bin", 10412, 192

HDAE5000_PPI_Read_Sector:	; 0x282D2E (270 bytes)
	; Read a sector of data from HD via PPI
	.incbin "includes/code_2803c2_28f542.bin", 10604, 270

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
HDAE5000_HD_Setup_Drive:	; 0x282E8D (1126 bytes)
	; Configure HD drive parameters; accesses HD config at 0x229D99
	.incbin "includes/code_2803c2_28f542.bin", 10955, 1126

HDAE5000_HD_Read_Identify:	; 0x2832F3 (1051 bytes)
	; Read HD IDENTIFY data; extracts CHS params from 0x229D99-0x229DAB
	.incbin "includes/code_2803c2_28f542.bin", 12081, 1051

HDAE5000_HD_Format_Params:	; 0x28370E (702 bytes)
	; Calculate format parameters for HD
	.incbin "includes/code_2803c2_28f542.bin", 13132, 702

HDAE5000_HD_Seek:	; 0x2839CC (412 bytes)
	; Seek to a cylinder/head position on HD
	.incbin "includes/code_2803c2_28f542.bin", 13834, 412

HDAE5000_HD_Read_Write:	; 0x283B68 (4737 bytes)
	; Core HD read/write operation; accesses 0x229D9A, 0x229DAC
	.incbin "includes/code_2803c2_28f542.bin", 14246, 4737

HDAE5000_HD_Error_Check:	; 0x284DE9 (355 bytes)
	; Check HD operation result and handle errors
	.incbin "includes/code_2803c2_28f542.bin", 18983, 355

HDAE5000_HD_Wait_Ready:	; 0x284F4C (138 bytes)
	; Wait for HD to become ready (poll status)
	.incbin "includes/code_2803c2_28f542.bin", 19338, 138

HDAE5000_HD_Status_Check:	; 0x284FD6 (782 bytes)
	; Check HD status flags at 0x22B2F4, 0x23A0A0
	.incbin "includes/code_2803c2_28f542.bin", 19476, 782

HDAE5000_HD_Data_Copy:	; 0x2852E4 (92 bytes)
	; Copy 12-byte record from (XDE) to (XWA) via ldirw, then set flag bytes
	; Input: XWA = dest, XDE = src, BC = flags (HL), E from stack = flag value
	; Returns with retd (deallocates 2 bytes from stack)
	ld xix, xde			; save source
	ld hl, bc			; HL = flags
	ld e, (xsp + 4)			; E = flag byte from stack
	ld xiy, xix			; XIY = source
	ld xix, xwa			; XIX = dest (for ldirw)
	lds bc, 6			; count = 6 words (12 bytes)
	mriw2 0x95, 0x11		; ldirw — copy 6 words
	ld (xwa), hl			; store flags at dest[0..1]
	bit 0, hl			; bit 0 set?
	jr z, .LHD_Data_Copy__bit1
	ld (xwa + 2), e			; dest[2] = flag value
.LHD_Data_Copy__bit1:
	bit 1, hl
	jr z, .LHD_Data_Copy__bit2
	ld (xwa + 3), e
.LHD_Data_Copy__bit2:
	bit 2, hl
	jr z, .LHD_Data_Copy__bit3
	ld (xwa + 4), e
.LHD_Data_Copy__bit3:
	bit 3, hl
	jr z, .LHD_Data_Copy__bit4
	ld (xwa + 5), e
.LHD_Data_Copy__bit4:
	bit 4, hl
	jr z, .LHD_Data_Copy__bit5
	ld (xwa + 6), e
.LHD_Data_Copy__bit5:
	bit 5, hl
	jr z, .LHD_Data_Copy__bit6
	ld (xwa + 7), e
.LHD_Data_Copy__bit6:
	bit 6, hl
	jr z, .LHD_Data_Copy__bit7
	ld (xwa + 8), e
.LHD_Data_Copy__bit7:
	bit 7, hl
	jr z, .LHD_Data_Copy__bit8
	ld (xwa + 9), e
.LHD_Data_Copy__bit8:
	bit 8, hl
	jr z, .LHD_Data_Copy__done
	ld (xwa + 10), e
.LHD_Data_Copy__done:
	retd 0x0002

HDAE5000_HD_Buffer_Init:	; 0x285340 (220 bytes)
	; Initialize HD data buffer
	.incbin "includes/code_2803c2_28f542.bin", 20350, 220

; --- HD Configuration Manager and CHS Geometry ---
HDAE5000_HD_Config_Manager:	; 0x28541C (3728 bytes)
	; Manage HD configuration; heavy access to 0x229D99-0x229DAE
	.incbin "includes/code_2803c2_28f542.bin", 20570, 3728

HDAE5000_HD_Partition_Setup:	; 0x2862AC (818 bytes)
	; Set up HD partition parameters
	.incbin "includes/code_2803c2_28f542.bin", 24298, 818

HDAE5000_HD_CHS_Calculate:	; 0x2865DE (1098 bytes)
	; Calculate CHS (Cylinder/Head/Sector) addresses
	.incbin "includes/code_2803c2_28f542.bin", 25116, 1098

HDAE5000_HD_Sector_Read:	; 0x286A28 (1064 bytes)
	; Read sectors from HD; accesses 0x229DAC
	.incbin "includes/code_2803c2_28f542.bin", 26214, 1064

HDAE5000_HD_Sector_Write:	; 0x286E50 (646 bytes)
	; Write sectors to HD; accesses 0x229DAA, 0x229DAC
	.incbin "includes/code_2803c2_28f542.bin", 27278, 646

; --- Filesystem Operations ---
HDAE5000_FS_Init:	; 0x2870D6 (3711 bytes)
	; Initialize filesystem structures
	.incbin "includes/code_2803c2_28f542.bin", 27924, 3711

HDAE5000_FS_Read_FSB:	; 0x287F55 (832 bytes)
	; Read File System Block from HD
	.incbin "includes/code_2803c2_28f542.bin", 31635, 832

HDAE5000_FS_Write_FSB:	; 0x288295 (5072 bytes)
	; Write File System Block to HD; accesses 0x229DAC
	.incbin "includes/code_2803c2_28f542.bin", 32467, 5072

HDAE5000_FS_Buffer_Setup:	; 0x289665 (548 bytes)
	; Set up filesystem buffers at 0x22AA9C
	.incbin "includes/code_2803c2_28f542.bin", 37539, 548

HDAE5000_FS_Scan_Directory:	; 0x289889 (2663 bytes)
	; Scan directory entries on HD
	.incbin "includes/code_2803c2_28f542.bin", 38087, 2663

HDAE5000_FS_Entry_Lookup:	; 0x28A2F0 (739 bytes)
	; Look up a file entry in the filesystem
	.incbin "includes/code_2803c2_28f542.bin", 40750, 739

; --- Display, Menu, and Utility Routines ---
HDAE5000_Display_Update_Offset:	; 0x28A5D3 (1612 bytes)
	; Update display offset from 0x23A092/0x23A094
	.incbin "includes/code_2803c2_28f542.bin", 41489, 1612

HDAE5000_Menu_Register_A:	; 0x28AC1F (73 bytes)
	; Register menu handler (variant A)
	; Input: A = menu index
	; Uses workspace callbacks at +0x0E0A to register menu entries
	dec 2, xsp			; allocate local space
	ld (xsp), a			; save menu index
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E	; ld XWA, (XWA + 0x0E0A) — menu table
	ld_sril3 xhl, 0xE1, 0x34, 0x05	; ld XHL, (XWA + 0x0534) — register fn
	ld xwa, 0xFFFFFFFF		; param: all bits set
	ld xbc, 0x01C00014		; param: menu geometry
	call (xhl)			; register first entry
	lds32 xwa, 0			; clear XWA
	ld a, (xsp)			; restore menu index
	add xwa, 0x01800000		; construct second entry ID
	ld xde, xwa			; XDE = entry ID
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E	; ld XWA, (XWA + 0x0E0A) — menu table
	ld_sril3 xhl, 0xE1, 0x24, 0x01	; ld XHL, (XWA + 0x0124) — alternate fn
	ld xwa, 0xFFFFFFFF		; param: all bits set
	ld xbc, 0x01C00014		; param: menu geometry
	call (xhl)			; register second entry
	inc 2, xsp			; deallocate local space
	ret

HDAE5000_Menu_Register_B:	; 0x28AC68 (146 bytes)
	; Register menu handler (variant B) - called from outside this block
	.incbin "includes/code_2803c2_28f542.bin", 43174, 146

HDAE5000_HD_Shutdown:	; 0x28ACFA (78 bytes)
	; Shut down HD extension — unregister menu entries via workspace callbacks
	; Input: WA = parameter (zero-extended)
	; Tail-calls via jp (xhl) for final unregistration
	extz wa				; zero-extend parameter
	ldda32_24 xbc, 2335138		; ld XBC, (0x23A1A2) — workspace ptr
	ld_sril3 xbc, 0xE5, 0x88, 0x0E	; ld XBC, (XBC + 0x0E88)
	ld_sril3 xhl, 0xE5, 0x2C, 0x01	; ld XHL, (XBC + 0x012C) — shutdown handler
	call (xhl)			; invoke shutdown
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E	; ld XWA, (XWA + 0x0E0A) — menu table
	ld_sril3 xhl, 0xE1, 0x34, 0x05	; ld XHL, (XWA + 0x0534) — register fn
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x01C00016		; unregister params
	call (xhl)			; unregister first entry
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E	; ld XWA, (XWA + 0x0E0A) — menu table
	ld_sril3 xhl, 0xE1, 0x24, 0x01	; ld XHL, (XWA + 0x0124)
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x01C00016
	ld xde, 0x01A000EE		; entry ID
	jp (xhl)			; tail-call: unregister second entry

HDAE5000_Menu_Handler:	; 0x28AD48 (248 bytes)
	; Handle menu events and dispatch
	.incbin "includes/code_2803c2_28f542.bin", 43398, 248

HDAE5000_Menu_Callback:	; 0x28AE40 (248 bytes)
	; Menu callback processor
	.incbin "includes/code_2803c2_28f542.bin", 43646, 248

HDAE5000_Display_Manager:	; 0x28AF38 (441 bytes)
	; Manage display state; accesses 0x229DAB
	.incbin "includes/code_2803c2_28f542.bin", 43894, 441

HDAE5000_Display_Scroll:	; 0x28B0F1 (271 bytes)
	; Handle display scrolling
	.incbin "includes/code_2803c2_28f542.bin", 44335, 271

HDAE5000_Display_Clear:	; 0x28B200 (43 bytes)
	; Clear display area: copy 7 bytes from ROM table, then call buffer validate
	; Input: XWA = pointer to display buffer
	lds ix, 0			; IX = loop counter = 0
	cps ix, 7
	jr nc, HDAE5000_Display_Clear__push
HDAE5000_Display_Clear__loop:
	st_dpib c, 0xE0		; lda XHL, (XWA+) - get next dest addr, post-inc XWA
	ld bc, ix			; BC = current index
	extz xbc			; zero-extend to 32 bits
	ld xde, 0x002E1C82		; ROM source table
	add xde, xbc			; XDE = &table[index]
	ld c, (xde)			; C = table byte
	ld (xhl), c			; store to display buffer
	inc 1, ix			; index++
	cps ix, 7
	jr c, HDAE5000_Display_Clear__loop
HDAE5000_Display_Clear__push:
	pushw 0x002E			; push 0x2E (size param)
	pushw 0x1C82			; push 0x1C82 (offset param)
	call HDAE5000_Display_Buffer_Validate
	inc 4, xsp			; deallocate 4 bytes from stack
	ret

HDAE5000_Wait_Callback_Loop:	; 0x28B22B (45 bytes)
	; Poll workspace callback until HL returns 0
	; Uses workspace ptr at (0x23A1A2) → callback table at +0x0E88
	; Calls callback at +0x00B8 (type 3), then polls at +0x00D0 (type 1)
	jr t, .LWait_Callback__poll
.LWait_Callback__invoke:
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril3 xwa, 0xE1, 0x88, 0x0E	; ld XWA, (XWA + 0x0E88) — callback table
	ld_sril3 xhl, 0xE1, 0xB8, 0x00	; ld XHL, (XWA + 0x00B8) — callback fn
	lds wa, 3			; callback type = 3
	call (xhl)			; invoke callback
.LWait_Callback__poll:
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril3 xwa, 0xE1, 0x88, 0x0E	; ld XWA, (XWA + 0x0E88) — callback table
	ld_sril3 xix, 0xE1, 0xD0, 0x00	; ld XIX, (XWA + 0x00D0) — poll fn
	lds wa, 1			; poll type = 1
	call (xix)			; invoke poll
	cps hl, 0			; result == 0?
	jr nz, .LWait_Callback__invoke	; keep polling if non-zero
	ret

HDAE5000_Set_Menu_Visibility:	; 0x28B258 (229 bytes)
	; Set menu item visibility via workspace callbacks
	.incbin "includes/code_2803c2_28f542.bin", 44694, 229

HDAE5000_Return_Stub:	; 0x28B33D (1 bytes)
	ret

HDAE5000_Get_Table_Entry:	; 0x28B33E (61 bytes)
	; Retrieve entry from data table by index
	; Input: XWA = pointer to table context structure
	; Field +0: counter, +1: previous index, +2: current index
	push xiz
	ld xiz, xwa			; XIZ = table context pointer
	push xbc
	ld a, (xiz + 2)		; A = current index
	extz wa
	muls wa, 0x001B			; offset = index * 27 (entry size)
	inc 4, wa			; skip 4-byte header
	exts xwa			; sign-extend to 32-bit
	add xwa, xiz			; XWA = pointer to entry
	push xwa			; arg: entry pointer
	call HDAE5000_MemCopy_Block
	inc 0, xsp			; clean up 8 bytes (arg + saved XBC)
	ld a, (xiz + 2)		; save current index
	ld (xiz + 1), a		; as previous index
	lda xwa, (xiz + 2)		; XWA = pointer to current index
	incm8 1, (xwa)			; increment current index
	ld a, (xwa)			; read new index value
	cps a, 5			; wrap at 5?
	jr c, .Lgte_no_wrap
	ldmi8 (xiz + 2), 0x00		; reset to 0
.Lgte_no_wrap:
	cpmi8 (xiz), 0x05		; check counter < 5
	jr nc, .Lgte_no_inc
	incm8 1, (xiz)			; increment counter
.Lgte_no_inc:
	ld xwa, xiz			; return context pointer
	calr HDAE5000_Return_Stub	; NOP call (returns immediately)
	pop xiz
	ret

HDAE5000_Validate_String:	; 0x28B37B (56 bytes)
	; Validate/navigate null-terminated record at (XWA)
	; Record format: [count][index][data...]
	; Returns XHL = pointer to data section, or 0 if record is empty
	cpmi8 (xwa), 0x00		; check if record is empty
	jr z, .LValidate_String__empty
	ld c, (xwa + 1)			; get current index
	extz bc				; zero-extend to 16-bit
	muls bc, 0x001B			; index * 27 (record stride)
	inc 4, bc			; skip 4-byte header
	st_dri3b c, 0x07, 0xE0, 0xE4	; lda XHL, (XWA + BC) — pointer to data
	cpmi8 (xwa + 1), 0x00		; check if index is non-zero
	jr nz, .LValidate_String__dec
	ld c, (xwa)			; get count
	cps c, 5			; count == 5?
	jr nz, .LValidate_String__dec_count
	ldmi8 (xwa + 1), 0x04		; wrap: index = 4 (max-1)
	jr t, .LValidate_String__ret
.LValidate_String__dec_count:
	ld c, (xwa)			; get count
	dec 1, c			; count - 1
	ld (xwa + 1), c			; index = count - 1
	jr t, .LValidate_String__ret
.LValidate_String__dec:
	decm8 1, (xwa + 1)		; index--
	jr t, .LValidate_String__ret
.LValidate_String__empty:
	lds32 xhl, 0			; return NULL
.LValidate_String__ret:
	ret

HDAE5000_Get_Status_Byte:	; 0x28B3B3 (6 bytes)
	; Return byte from 0x22AD9A in L
	ldda8_24 l, 2272666	; ld L, (0x22AD9A)
	ret

HDAE5000_Set_Status_Byte:	; 0x28B3B9 (6 bytes)
	; Store A to 0x22AD9B
	stda8_24 2272667, a	; ld (0x22AD9B), A
	ret

HDAE5000_Count_Active_Files:	; 0x28B3BF (43 bytes)
	; Count active file entries in table at 0x22AA9C
	; Input: none
	; Output: HL = count of entries with status byte == 1
	; Scans 20 entries (0x0014), each 0x0114 bytes apart
	lds hl, 0		; HL = count = 0
	lds de, 0		; DE = index = 0
	cp de, 0x0014		; check if index >= 20
	ret nc			; return if index >= 20 (unsigned)
HDAE5000_Count_Active_Files__loop:
	ld wa, de		; WA = current index
	extz xwa		; zero-extend to 32 bits
	add xwa, 0x00000114	; add entry size offset
	ld xbc, 0x0022AA9C	; table base address
	add xbc, xwa		; XBC = &table[index]
	cpmi8 (xbc), 0x01	; compare status byte with 1
	jr nz, HDAE5000_Count_Active_Files__skip
	inc 1, hl		; count++
HDAE5000_Count_Active_Files__skip:
	inc 1, de		; index++
	cp de, 0x0014		; check if index < 20
	jr c, HDAE5000_Count_Active_Files__loop
	ret

; --- UI Handler, File Operations, Path/String Utilities ---
HDAE5000_UI_Main_Handler:	; 0x28B3EA (8731 bytes)
	; Main UI event handler - largest routine in this section
	.incbin "includes/code_2803c2_28f542.bin", 45096, 8731

HDAE5000_Display_Error:	; 0x28D605 (204 bytes)
	; Display error message to user
	.incbin "includes/code_2803c2_28f542.bin", 53827, 204

HDAE5000_File_Operation:	; 0x28D6D1 (938 bytes)
	; Execute file operation on HD
	.incbin "includes/code_2803c2_28f542.bin", 54031, 938

HDAE5000_File_Save:	; 0x28DA7B (381 bytes)
	; Save file to HD; accesses 0x229DAD, 0x229DAE
	.incbin "includes/code_2803c2_28f542.bin", 54969, 381

HDAE5000_File_Load:	; 0x28DBF8 (564 bytes)
	; Load file from HD
	.incbin "includes/code_2803c2_28f542.bin", 55350, 564

HDAE5000_File_Delete:	; 0x28DE2C (579 bytes)
	; Delete file from HD
	.incbin "includes/code_2803c2_28f542.bin", 55914, 579

HDAE5000_File_Rename:	; 0x28E06F (280 bytes)
	; Rename file on HD
	.incbin "includes/code_2803c2_28f542.bin", 56493, 280

HDAE5000_File_Format:	; 0x28E187 (772 bytes)
	; Format HD or partition
	.incbin "includes/code_2803c2_28f542.bin", 56773, 772

HDAE5000_Calc_Disk_Space:	; 0x28E48B (178 bytes)
	; Calculate available disk space
	.incbin "includes/code_2803c2_28f542.bin", 57545, 178

HDAE5000_Display_Notify:	; 0x28E53D (113 bytes)
	; Validate notification file: read, check header, compare fields
	; Returns XHL = 0 on success, negative error code on failure
	pushw 0x0004			; push mode = 4
	ldada_24 xwa, 3038370		; lda XWA, (0x2E5CA2) - source data
	push xwa			; push source ptr
	ldada_24 xwa, 2274352		; lda XWA, (0x22B430) - dest buffer
	push xwa			; push dest ptr
	call HDAE5000_File_Read
	add xsp, 0x0000000A		; clean up 10 bytes (3 args)
	cps hl, 0			; check read result
	jr z, .Ldn_check1		; if OK, continue validation
	ld xhl, 0xFFFFFFFF		; return -1 (read error)
	ret
.Ldn_check1:
	lds32 xwa, 6			; param = 6
	calr HDAE5000_String_To_Upper	; convert to uppercase
	cpdm32_24 2274356, xhl		; cp (0x22B434), XHL - check header
	jr z, .Ldn_check2		; if match, continue
	ld xhl, 0xFFFFFFFE		; return -2 (header mismatch)
	ret
.Ldn_check2:
	lds wa, 0			; param = 0
	calr HDAE5000_String_Compare
	cpdm16_24 2274360, xhl		; cp (0x22B438), HL
	jr ule, .Ldn_check3		; if <= expected, continue
	ld xhl, 0xFFFFFFFD		; return -3
	ret
.Ldn_check3:
	lds wa, 1			; param = 1
	calr HDAE5000_String_Compare
	cpdm16_24 2274362, xhl		; cp (0x22B43A), HL
	jr ule, .Ldn_check4		; if <= expected, continue
	ld xhl, 0xFFFFFFFC		; return -4
	ret
.Ldn_check4:
	ldw wa, 0x8000			; param = 0x8000
	calr HDAE5000_String_Compare
	ldda16_24 xwa, 2274364		; ld WA, (0x22B43C)
	and wa, hl			; WA = WA & HL (mask check)
	jr z, .Ldn_ok			; if zero, valid
	ld xhl, 0xFFFFFFFB		; return -5
	ret
.Ldn_ok:
	lds32 xhl, 0			; return 0 (success)
	ret

HDAE5000_Display_Progress:	; 0x28E5AE (59 bytes)
	; Read file and process display progress string
	; Returns XHL = 0 on success, -10 on error
	pushw 0x0004			; push mode = 4
	ldada_24 xwa, 3038376		; lda XWA, 0x2E5CA8 (source data ptr)
	push xwa
	ldada_24 xwa, 2274366		; lda XWA, 0x22B43E (dest buffer)
	push xwa
	call HDAE5000_File_Read		; read file data
	add xsp, 0x0000000A		; deallocate 10 bytes (3 pushed args)
	cps hl, 0			; check result
	jr z, .LDisplay_Progress__ok
	ld xhl, 0xFFFFFFF6		; return -10 (error)
	ret
.LDisplay_Progress__ok:
	ldda32_24 xwa, 2274370		; ld XWA, (0x22B442) — get result data
	calr HDAE5000_String_To_Upper	; unpack string bytes
	ld xwa, xhl
	add xwa, 0x00000016		; add offset 22
	stda32_24 2295026, xwa		; ld (0x2304F2), XWA — store processed ptr
	lds32 xhl, 0			; return 0 (success)
	ret

HDAE5000_String_To_Upper:	; 0x28E5E9 (37 bytes)
	; Unpack 32-bit value into sum of byte-shifted components
	; Input: XWA = packed 32-bit value
	; Output: XHL = result (each byte shifted left 8 and added)
	ld xhl, xwa			; copy input
	and xhl, 0x000000FF		; mask lowest byte
	lds de, 0			; loop counter = 0
	cps de, 3			; compare with 3
	ret ge				; return if already done
.LString_To_Upper__loop:
	srl xwa, 8			; next byte
	sll xhl, 8			; shift result left
	ld xbc, xwa
	and xbc, 0x000000FF		; mask byte
	add xhl, xbc			; accumulate
	inc 1, de			; counter++
	cps de, 3
	jr lt, .LString_To_Upper__loop
	ret

HDAE5000_String_Compare:	; 0x28E60E (2397 bytes)
	; String comparison and manipulation utilities
	.incbin "includes/code_2803c2_28f542.bin", 57932, 2397

HDAE5000_Path_Builder:	; 0x28EF6B (556 bytes)
	; Build file path strings
	.incbin "includes/code_2803c2_28f542.bin", 60329, 556

HDAE5000_Directory_Handler:	; 0x28F197 (614 bytes)
	; Handle directory listing and navigation
	.incbin "includes/code_2803c2_28f542.bin", 60885, 614

HDAE5000_Filename_Validate:	; 0x28F3FD (59 bytes)
	; Unpack 32-bit value by extracting each byte, shifting and combining
	; Like String_To_Upper but processes all 4 bytes unconditionally
	; Input: XWA = packed 32-bit value
	; Output: XHL = combined result
	ld xbc, xwa
	ld xhl, xbc
	and xhl, 0x000000FF
	srl xbc, 8
	sll xhl, 8
	ld xwa, xbc
	and xwa, 0x000000FF
	add xhl, xwa
	srl xbc, 8
	sll xhl, 8
	ld xwa, xbc
	and xwa, 0x000000FF
	add xhl, xwa
	srl xbc, 8
	sll xhl, 8
	ld xwa, xbc
	and xwa, 0x000000FF
	add xhl, xwa
	ret

HDAE5000_Extension_Check:	; 0x28F438 (153 bytes)
	; Check and process file extensions
	.incbin "includes/code_2803c2_28f542.bin", 61558, 153

HDAE5000_Config_Init:	; 0x28F4D1 (114 bytes)
	; Initialize configuration: validate filename, check headers, verify extensions
	; Input: XWA = pointer to config data structure (XIZ-indexed fields)
	; Output: XHL = 0 success, -1..-4 error codes
	push xiz
	ld xiz, xwa			; save config ptr in XIZ
	ld xwa, (xiz)			; load filename pointer (field 0x00)
	calr HDAE5000_Filename_Validate
	cp xhl, 0x4D546864		; check magic "MThd" (MIDI header, reversed)
	jr z, .Lci_check1
	ld xhl, 0xFFFFFFFF		; return -1 (invalid magic)
	jr t, .Lci_exit
.Lci_check1:
	ld xwa, (xiz + 4)		; load field at offset 0x04
	calr HDAE5000_Filename_Validate
	cp xhl, 0x00000006		; check header size = 6
	jr z, .Lci_check2
	ld xhl, 0xFFFFFFFE		; return -2 (wrong header size)
	jr t, .Lci_exit
.Lci_check2:
	ld wa, (xiz + 8)		; load 16-bit field at offset 0x08
	calr HDAE5000_Extension_Check
	stda16_24 2297530, xhl		; ld (0x230EBA), HL
	cpdi16_24 2297530, 0x0001	; cp (0x230EBA), 1
	jr ule, .Lci_check3		; if <= 1, continue
	ld xhl, 0xFFFFFFFD		; return -3
	jr t, .Lci_exit
.Lci_check3:
	ld wa, (xiz + 10)		; load field at offset 0x0A
	calr HDAE5000_Extension_Check
	stda16_24 2297532, xhl		; ld (0x230EBC), HL
	ld wa, (xiz + 12)		; load field at offset 0x0C
	calr HDAE5000_Extension_Check
	stda16_24 2297534, xhl		; ld (0x230EBE), HL
	ldda16_24 xwa, 2297534		; ld WA, (0x230EBE)
	bit 15, wa			; test bit 15
	jr z, .Lci_ok			; if not set, success
	ld xhl, 0xFFFFFFFC		; return -4
	jr t, .Lci_exit
.Lci_ok:
	lds32 xhl, 0			; return 0 (success)
.Lci_exit:
	pop xiz
	ret

HDAE5000_Alloc_Memory:	; 28F543h
	; Memory/display parameter lookup routine
	; Input: XBC = request type (0x01E000A1, A2, or A3)
	; Output: XHL = result based on type:
	;   A1 -> 0x2E61CE (ROM palette data pointer)
	;   A2 -> 0x140 (320 decimal - display width)
	;   A3 -> 0xF0 (240 decimal - display height)
	;   else -> 0 (invalid type)
	cp xbc, 0x1E000A3	; Check for type A3
	jr z, HDAE5000_Alloc_Memory__type_A3
	cp xbc, 0x1E000A2	; Check for type A2
	jr z, HDAE5000_Alloc_Memory__type_A2
	cp xbc, 0x1E000A1	; Check for type A1
	jr z, HDAE5000_Alloc_Memory__type_A1
	lds32 xhl, 0	; Invalid type - return 0
	ret
HDAE5000_Alloc_Memory__type_A1:
	ldada_24 xhl, 3039694	; Return palette data pointer
	ret
HDAE5000_Alloc_Memory__type_A2:
	ld xhl, 0x140	; Return 320 (width)
	ret
HDAE5000_Alloc_Memory__type_A3:
	ld xhl, 0xF0	; Return 240 (height)
	ret

HDAE5000_Get_Init_Flag:	; 28F570h
	; Returns HD presence flag in L
	; Output: L = value from HDAE5000_INIT_FLAG (0x230EDA)
	ldda8_24 l, 2297562
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
.equ HDAE5000_WORKSPACE_PTR, 0x23A1A2
.equ HDAE5000_HANDLER_1, 0x230ECC
.equ HDAE5000_HANDLER_2, 0x230ED2
.equ HDAE5000_HANDLER_3, 0x230ED6
.equ HDAE5000_INIT_FLAG, 0x230EDA

; Handler registration data addresses (used by HDAE5000_Handler_Registration)
	; (EQU→inline label) HDAE5000_RECORD_COUNT = 0x29D97E
	; (EQU→inline label) HDAE5000_RECORD_TABLE = 0x29C0AA
					; Records: SelectList, DbMemoCl, TtlScreenR, AcHddNamingWindow,
					; IvHddNaming, HDTitleMenu, TtlScreenR2, TtlScreenR3,
					; AcWindowPage1, IvScreenR2, AcLanguageText1, LyricBox, FDFileSelect
.equ HDAE5000_RAM_DATA_A_SIZE, 0x239822	; Size word for RAM data area A (variable)
.equ HDAE5000_RAM_DATA_A, 0x2397EA	; RAM data area A
.equ HDAE5000_RAM_DATA_B_SIZE, 0x239870	; Size word for RAM data area B (variable)
.equ HDAE5000_RAM_DATA_B, 0x239824	; RAM data area B
.equ HDAE5000_DATA_COPY_DEST, 0x23952A	; Init data copy destination
.equ HDAE5000_INIT_DATA_2, 0x239642	; Init data area (secondary)
.equ HDAE5000_SERIAL_DATA_1, 0x239872	; Serial port data (primary)
.equ HDAE5000_SERIAL_DATA_2, 0x2398AA	; Serial port data (secondary)
.equ HDAE5000_PARALLEL_DATA_1, 0x239FD2	; Parallel port data (primary)
.equ HDAE5000_PARALLEL_DATA_2, 0x23A00E	; Parallel port data (secondary)
	; (EQU→inline label) HDAE5000_GFX_DATA_1 = 0x2A5D2C
	; (EQU→inline label) HDAE5000_GFX_DATA_2 = 0x2A6984
	; (EQU→inline label) HDAE5000_GFX_INIT_PARAMS = 0x2A849A

; ROM data addresses
	; (EQU→inline label) HDAE5000_Palette_Data = 0x2E5DCE
	; (EQU→inline label) HDAE5000_Display_Params = 0x2F8DCE

; All routine addresses are now exposed as labels in split binary sections

; PPORT state machine handler (in code_28f90c_2953e1.bin)
	; (EQU→inline label) HDAE5000_PPORT_Handler = 0x29501C

; PPORT command handler addresses (in code_295642_2fffff.bin)
	; (EQU→inline label) HDAE5000_Cmd01_SendInfo = 0x2958D6
	; (EQU→inline label) HDAE5000_Cmd02_Exit = 0x295914
	; (EQU→inline label) HDAE5000_Cmd03_ReadFSB = 0x2959F6
	; (EQU→inline label) HDAE5000_Cmd04_SendFSB = 0x295D3C
	; (EQU→inline label) HDAE5000_Cmd05_RcvFSB = 0x29605A
	; (EQU→inline label) HDAE5000_Cmd06_WriteFSB = 0x296294
	; (EQU→inline label) HDAE5000_PPORT_Cmd_LoadHDtoMemory = 0x29632A
	; (EQU→inline label) HDAE5000_PPORT_Cmd_SendDataBlock = 0x29633C
	; (EQU→inline label) HDAE5000_PPORT_Cmd_SendFileList = 0x2964A6
	; (EQU→inline label) HDAE5000_PPORT_Cmd_ReceiveDataBlock = 0x296588
	; (EQU→inline label) HDAE5000_PPORT_Cmd_WriteMemoryToHD = 0x29659A
	; (EQU→inline label) HDAE5000_PPORT_Cmd_Reserved = 0x296680

HDAE5000_Boot_Init:	; 28F576h
	push xiz
	ld xiz, xwa	; XIZ = workspace pointer from main CPU

	calr HDAE5000_Clear_Work_Buffer	; Clear 0xF52A bytes at 0x22A000

	stda32_24 2335138, xiz	; Store workspace pointer

	call 0x280020	; Register handlers with main CPU

	ldada_24 xwa, 3038670	; Load palette data address
	calr HDAE5000_Load_Palette	; Load 256-entry VGA palette

	; Allocate memory for VRAM copy
	lds32 xwa, 0
	ld xbc, 0x1E000A1	; Allocation type A1
	lds32 xde, 0
	calr HDAE5000_Alloc_Memory	; Returns address in XHL
	ld xiz, xhl	; XIZ = allocated buffer

	; Copy from allocated buffer to VRAM area 1 (0x1A0000, size 0x9600)
	pushw 0x9600	; push 9600h (16-bit immediate)
	ld xwa, xiz
	push xwa	; Source
	ld xwa, 0x1A0000	; Destination
	push xwa
	call 0x29AE9F

	; Copy from allocated buffer + offset to VRAM area 2 (0x1A9600)
	pushw 0x9600	; push 9600h (16-bit immediate)
	ld xwa, xiz
	add xwa, 0x9600	; Source + offset
	push xwa
	ld xwa, 0x1A9600	; Destination
	push xwa
	call 0x29AE9F

	lda xsp, (xsp + 20)	; Clean stack (5 pushes × 4 bytes = 20)

	; === Create DISK MENU slot ===
	; Call workspace[0x0E0A][0x02C4] to register a DISK MENU entry.
	; Returns XHL = pointer to menu slot structure.
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E	; Handler table A
	ld_sril3 XIX, 0xE1, 0xC4, 0x02	; DISK MENU slot registration function
	ld xwa, 0x600002	; Menu group ID
	call (xix)	; Returns XHL = slot pointer
	;
	; Set slot+0x00 = 0x016A0005
	;   0x016A = handler ID (registered above via RegisterObjectTable)
	;   0x0005 = sub-object index (Record 5 = "HDTitleMenu" in data table)
	ld xwa, 0x16A0005
	ld (xhl), xwa	; Link DISK MENU entry to handler 0x016A, record 5
	;
	; Set slot+0x2A = display name string pointer
	;   Points to "HD-AE5000\0" at ROM address 0x2F8DCE
	ldada_24 xwa, 3116494
	ld (xhl + 42), xwa	; Display name shown in DISK MENU
	;
	; NOTE: slot+0x32 (icon ID) is NOT set here.
	; The firmware uses a default icon for HDAE5000.

	; === Initialize callback pointers via Handler Table B ===
	; Table B is at workspace[+0x0E88].
	; Each call returns a callback pointer stored in local RAM.
	; These pointers are used by Frame_Handler to monitor state changes.
	;
	; Handler 1: status monitor (used to check bit 2 for display init)
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x88, 0x0E	; Handler table B
	ld_sril3 XHL, 0xE1, 0x08, 0x01	; Get callback via table B offset +0x0108
	call (xhl)
	stda32_24 2297548, xhl	; Store at 0x230ECC

	; Handler 2: display offset calculator (state value read for display offset)
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x88, 0x0E
	ld_sril3 XHL, 0xE1, 0x00, 0x01	; Table B offset +0x0100
	call (xhl)
	stda32_24 2297554, xhl	; Store at 0x230ED2

	; Handler 3: display state reader (state byte shifted for offset calc)
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x88, 0x0E
	ld_sril3 XHL, 0xE1, 0x04, 0x01	; Table B offset +0x0104
	call (xhl)
	stda32_24 2297558, xhl	; Store at 0x230ED6

	; Check for hard disk presence
	call 0x2971A3
	stda8_24 2297562, l	; Store result

	cps l, 0
	jr z, HDAE5000_Boot_Init__skip_hd_init	; Skip if no HD

	; Hard disk present - initialize it
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XHL, 0xE1, 0x24, 0x01	; HD init function
	ld xwa, 0xFFFFFFFF	; Full init
	ld xbc, 0x1C00016	; HD initialization parameters
	ld xde, 0x1A0007F	; Buffer
	call (xhl)

HDAE5000_Boot_Init__skip_hd_init:
	call 0x28F90B	; Final setup
	call 0x2803C2	; Register frame handler

	pop xiz
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

HDAE5000_Frame_Handler:	; 28F662h
	; Frame handler main entry - called periodically from main loop
	; 1. Check workspace pointer at 0x23A19E (skip if -1)
	; 2. Read handler states from 0x230ED2, 0x230ED6
	; 3. Calculate display offset = (WA * 3) << 2, store at 0x230EC6
	; 4. Call registered callback via workspace[0x0E0A][0x0124]
	;
	ldda32_24 xwa, 2335134	; Load secondary workspace pointer
	cp xwa, 0xFFFFFFFF	; Check if uninitialized (-1)
	jr z, HDAE5000_Frame_Handler_Status	; Skip to status check if no workspace
	;
	; Calculate display offset from handler states
	ldda32_24 xwa, 2297558	; Load handler 3 pointer
	ld a, (xwa)	; Read state byte
	srl a, 3	; srl 3, A  ; divide by 8
	ld e, a	; Save in E
	;
	ldda32_24 xwa, 2297554	; Load handler 2 pointer
	ld wa, (xwa)	; Read state word
	extz xwa	; Zero-extend to 32-bit
	ld xbc, xwa	; XBC = state value
	add xbc, xbc	; XBC *= 2
	add xbc, xwa	; XBC *= 3 (total: state * 3)
	sll xbc, 2	; sll 2, XBC  ; XBC *= 4 (total: state * 12)
	lds32 xwa, 0	; Clear XWA
	ld a, e	; Restore shifted value
	inc 2, xwa	; inc 2, XWA  ; Add 2 (?) to low word
	add xwa, xbc	; Combine offsets
	stda32_24 2297542, xwa	; Store calculated display offset
	;
	; Check if state changed
	inc 1, e	; inc 1, E
	ld a, e
	extz wa
	cpda16_24 xwa, 2297540	; Compare with previous state
	jr z, HDAE5000_Frame_Handler_Status	; Skip if unchanged
	;
	; State changed - update and call callback
	ld a, e
	extz wa
	stda16_24 2297540, xwa	; Update state variable
	ldda32_24 xwa, 2297554	; Load handler 2 pointer
	ld wa, (xwa)	; Read state
	stda16_24 2297538, xwa	; Store in temp
	ldada_24 xwa, 2297538	; Load address of temp
	ld xbc, xwa	; XBC = temp address
	ldda32_24 xwa, 2335134	; Secondary workspace pointer
	ld xde, xbc	; XDE = temp address
	ldda32_24 xbc, 2335138	; Main workspace pointer
	ld_sril3 XBC, 0xE5, 0x0A, 0x0E	; Handler table A
	ld_sril3 XHL, 0xE5, 0x24, 0x01	; Get callback function
	ld xbc, 0x1CA0004	; Display state update callback
	call (xhl)	; Call callback if valid

HDAE5000_Frame_Handler_Status:	; 28F6E0h
	; Frame handler status check section
	; Monitors handler 1 status bit 2, triggers display init when it transitions to 0
	;
	ldda32_24 xwa, 2297548	; Load handler 1 pointer
	ld a, (xwa)	; Read status byte
	and a, 0x4	; Isolate bit 2
	cpda8_24 a, 2297552	; Compare with previous state
	jrl z, HDAE5000_Frame_Handler_Exit	; jrl Z, Frame_Handler_Exit  ; Skip if unchanged
	;
	; Status changed - update previous state
	stda8_24 2297552, a	; Store new state
	cps a, 0	; Check if bit 2 now clear
	jrl nz, HDAE5000_Frame_Handler_Exit	; jrl NZ, Frame_Handler_Exit  ; Skip if bit still set
	;
	; Bit 2 cleared - check if display init needed
	call 0x28B3B3	; Call status check routine
	cps l, 1	; Check return value
	jr nz, HDAE5000_Frame_Handler_Exit	; Skip if not 1
	;
	; Initialize display - call workspace callback
	ldda32_24 xwa, 2335138	; Main workspace pointer
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E	; Handler table A
	ld_sril3 XIX, 0xE1, 0x78, 0x02	; Get display callback
	call (xix)	; Call if valid
	cp xhl, 0x1A0007F	; Check return value
	jr z, HDAE5000_Frame_Handler_Status__init_display	; If match, do full init
	;
	; Partial update
	lds wa, 1
	call 0x28B3B9	; Call update routine
	ldw wa, 0x7F
	call 0x28AC68	; Call UI update
	jr HDAE5000_Frame_Handler_Exit
	;
HDAE5000_Frame_Handler_Status__init_display:
	; Full display initialization sequence
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XHL, 0xE1, 0x24, 0x01	; Init callback 1
	ld xwa, 0x7F013E	; Display params
	ld xbc, 0x1C00001	; Display initialization flags
	lds32 xde, 0
	call (xhl)
	;
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XHL, 0xE1, 0x34, 0x05	; Init callback 2
	ld xwa, 0x7F013E
	ld xbc, 0x1CA0000
	call (xhl)
	;
	ldda32_24 xwa, 2335138
	ld_sril3 XWA, 0xE1, 0x0A, 0x0E
	ld_sril3 XHL, 0xE1, 0x24, 0x01	; Init callback 3
	ld xwa, 0x7F013E
	ld xbc, 0x1CA0000
	lds32 xde, 0
	call (xhl)

HDAE5000_Frame_Handler_Exit:	; 28F781h
	; Exit frame handler by jumping to PPORT handler
	jp HDAE5000_PPORT_Handler

; ----------------------------------------------------------------------------
; Utility routines (0x28F785 - 0x2953E1)
; ----------------------------------------------------------------------------

HDAE5000_Clear_Work_Buffer:	; 28F785h
	; Clear work buffer and copy initialization data from ROM
	; Part 1: Clear 0xF52A bytes (62,762) at 0x22A000 using word operations
	; Part 2: Copy 0x0C82 bytes (3,202) from ROM 0x2F94B2 to RAM 0x23952A
	;
	; Uses LDIRW for word block copy, LDIR for byte copy
	; Handles large counts via QBC (high word of XBC) loop
	;
	; === Part 1: Clear work buffer ===
	ld xde, 0x22A000	; Destination = work buffer
	ld xbc, 0xF52A	; Count = 62,762 bytes
	ld ix, bc	; Save low word for odd byte check
	srl xbc, 1	; srl 1, XBC  ; divide by 2 for word ops
	jr z, HDAE5000_Clear_Work_Buffer__clear_done	; Skip if count was 0 or 1
	ld xhl, xde	; Source = destination (for LDIRW)
	stiw_dpi 0xE9, 0x00, 0x00	; ld (XDE+), 0x0000  ; store first word
	dec 1, xbc	; dec 1, XBC
	or xbc, xbc
	jr z, HDAE5000_Clear_Work_Buffer__clear_done
	mriw2 0x93, 0x11	; ldirw  ; copy words (fills with zeros)
	cpi_werp 0xE6, 0	; cp QBC, 0  ; check high word
	jr z, HDAE5000_Clear_Work_Buffer__clear_done
	ldto_werp WA, 0xE6	; ld WA, QBC  ; get high word count
HDAE5000_Clear_Work_Buffer__clear_loop:
	mriw2 0x93, 0x11	; ldirw  ; continue word copy
	djnz xwa, HDAE5000_Clear_Work_Buffer__clear_loop	; djnz WA, .clear_loop
HDAE5000_Clear_Work_Buffer__clear_done:
	bit 0, ix	; bit 0, IX  ; check if odd byte
	jr z, HDAE5000_Clear_Work_Buffer__no_odd_byte
	ldmi8 (xde), 0x0	; Clear final odd byte
HDAE5000_Clear_Work_Buffer__no_odd_byte:
	; === Part 2: Copy init data from ROM to RAM ===
	ld xde, 0x23952A	; Destination = RAM init area
	ld xhl, 0x2F94B2	; Source = ROM init data
	ld xbc, 0xC82	; Count = 3,202 bytes
	or xbc, xbc
	jr z, HDAE5000_Clear_Work_Buffer__copy_done
	ldir83	; ldir  ; copy bytes
	cpi_werp 0xE6, 0	; cp QBC, 0
	jr z, HDAE5000_Clear_Work_Buffer__copy_done
	ldto_werp WA, 0xE6	; ld WA, QBC
HDAE5000_Clear_Work_Buffer__copy_loop:
	ldir83	; ldir
	djnz xwa, HDAE5000_Clear_Work_Buffer__copy_loop	; djnz WA, .copy_loop
HDAE5000_Clear_Work_Buffer__copy_done:
	ret

HDAE5000_Delay_Loop:	; 28F7DDh
	; Simple nested delay loop - decrements XWA until zero
	; Input: XWA = delay count (outer loop iterations)
	; Clobbers: XWA, XBC
	; Algorithm: Outer loop decrements XWA, inner loop spins on XBC copy
	ld xbc, xwa	; Copy count for comparison
	dec 1, xwa	; dec 1, XWA (decrement outer counter)
	or xbc, xbc	; Check if original was zero
	ret z	; Return immediately if zero
HDAE5000_Delay_Loop__inner_loop:
	ld xbc, xwa	; Copy remaining count
	dec 1, xwa	; dec 1, XWA (decrement inner counter)
	or xbc, xbc	; Check if done
	jr nz, HDAE5000_Delay_Loop__inner_loop	; Continue spinning until zero
	ret

HDAE5000_VGA_Port_Write:	; 28F7EEh
	; Write byte to VGA I/O port (memory-mapped at 0x170000)
	; Input: WA = VGA port number (e.g., 0x3C8, 0x3C9)
	;        C = data byte to write
	; VGA DAC ports: 0x3C8 = palette index, 0x3C9 = R/G/B data
	; Includes 0x100 delay before write to ensure VGA timing
	dec 2, xsp	; dec 2, XSP (allocate 2 bytes)
	pushw iz
	ld (xsp + 2), c	; ld (XSP+0x02), C  ; save data byte
	ld iz, wa	; save port number in IZ
	ld xwa, 0x100	; delay count = 256
	calr HDAE5000_Delay_Loop	; wait for VGA timing
	ld wa, iz	; restore port number
	extz xwa	; zero-extend to 32-bit
	add xwa, 0x170000	; add XWA, 0x00170000
	ld xbc, xwa	; XBC = 0x170000 + port
	ld a, (xsp + 2)	; ld A, (XSP+0x02)  ; restore data byte
	ld (xbc), a	; write byte to VGA port
	popw iz
	inc 2, xsp	; inc 2, XSP (deallocate)
	ret

HDAE5000_Palette_Setup:	; 28F813h
	; Set one VGA palette entry - converts 8-bit RGB to VGA 6-bit format
	; Input: A = palette index (0-255)
	;        XBC = pointer to RGBX color data (4 bytes: R, G, B, unused)
	;
	; VGA DAC format: 6-bit per channel (0-63), ROM has 8-bit (0-255)
	; Conversion: value >> 4, with rounding if bit 3 set and value < 0xF0
	;
	; === Write palette index to port 0x3C8 ===
	push xiz
	ld xiz, xbc	; XIZ = pointer to RGBX data
	extz wa	; A = palette index, zero-extend
	ld bc, wa
	ldw wa, 0x3C8	; VGA palette index port
	calr HDAE5000_VGA_Port_Write
	;
	; === Process Red component (XIZ+0) ===
	bitm 3, (xiz)	; bit 3, (XIZ)  ; check rounding flag
	jr z, HDAE5000_Palette_Setup__red_no_round
	cpmi8 (xiz), 0xF0	; cp (XIZ), 0xF0
	jr nc, HDAE5000_Palette_Setup__red_high
	ld a, (xiz)	; ld A, (XIZ)
	srl a, 4	; srl 4, A  ; divide by 16
	inc 1, a	; inc 1, A  ; round up
	extz wa
	ld bc, wa
	ldw wa, 0x3C9	; VGA palette data port
	calr HDAE5000_VGA_Port_Write
	jr HDAE5000_Palette_Setup__green_start
HDAE5000_Palette_Setup__red_high:
	ld a, (xiz)	; ld A, (XIZ)
	srl a, 4	; srl 4, A
	extz wa
	ld bc, wa
	ldw wa, 0x3C9
	calr HDAE5000_VGA_Port_Write
	jr HDAE5000_Palette_Setup__green_start
HDAE5000_Palette_Setup__red_no_round:
	ld a, (xiz)	; ld A, (XIZ)
	srl a, 4	; srl 4, A
	extz wa
	ld bc, wa
	ldw wa, 0x3C9
	calr HDAE5000_VGA_Port_Write
	;
	; === Process Green component (XIZ+1) ===
HDAE5000_Palette_Setup__green_start:
	bitm 3, (xiz + 1)	; bit 3, (XIZ+1)
	jr z, HDAE5000_Palette_Setup__green_no_round
	cpmi8 (xiz + 1), 0xF0	; cp (XIZ+1), 0xF0
	jr nc, HDAE5000_Palette_Setup__green_high
	ld a, (xiz + 1)	; ld A, (XIZ+1)
	srl a, 4	; srl 4, A
	inc 1, a	; inc 1, A
	extz wa
	ld bc, wa
	ldw wa, 0x3C9
	calr HDAE5000_VGA_Port_Write
	jr HDAE5000_Palette_Setup__blue_start
HDAE5000_Palette_Setup__green_high:
	ld a, (xiz + 1)	; ld A, (XIZ+1)
	srl a, 4	; srl 4, A
	extz wa
	ld bc, wa
	ldw wa, 0x3C9
	calr HDAE5000_VGA_Port_Write
	jr HDAE5000_Palette_Setup__blue_start
HDAE5000_Palette_Setup__green_no_round:
	ld a, (xiz + 1)	; ld A, (XIZ+1)
	srl a, 4	; srl 4, A
	extz wa
	ld bc, wa
	ldw wa, 0x3C9
	calr HDAE5000_VGA_Port_Write
	;
	; === Process Blue component (XIZ+2) ===
HDAE5000_Palette_Setup__blue_start:
	bitm 3, (xiz + 2)	; bit 3, (XIZ+2)
	jr z, HDAE5000_Palette_Setup__blue_no_round
	cpmi8 (xiz + 2), 0xF0	; cp (XIZ+2), 0xF0
	jr nc, HDAE5000_Palette_Setup__blue_high
	ld a, (xiz + 2)	; ld A, (XIZ+2)
	srl a, 4	; srl 4, A
	inc 1, a	; inc 1, A
	extz wa
	ld bc, wa
	ldw wa, 0x3C9
	calr HDAE5000_VGA_Port_Write
	jr HDAE5000_Palette_Setup__done
HDAE5000_Palette_Setup__blue_high:
	ld a, (xiz + 2)	; ld A, (XIZ+2)
	srl a, 4	; srl 4, A
	extz wa
	ld bc, wa
	ldw wa, 0x3C9
	calr HDAE5000_VGA_Port_Write
	jr HDAE5000_Palette_Setup__done
HDAE5000_Palette_Setup__blue_no_round:
	ld a, (xiz + 2)	; ld A, (XIZ+2)
	srl a, 4	; srl 4, A
	extz wa
	ld bc, wa
	ldw wa, 0x3C9
	calr HDAE5000_VGA_Port_Write
HDAE5000_Palette_Setup__done:
	pop xiz
	ret

HDAE5000_Load_Palette:	; 28F8E0h
	; Load all 256 VGA palette entries from ROM data
	; Input: XWA = pointer to palette data (256 entries × 4 bytes)
	; Iterates from index 255 down to 0, calling Palette_Setup for each
	;
	; Each palette entry is 4 bytes: RGBX (X unused)
	; VGA DAC ports: 0x3C8 = index, 0x3C9 = R/G/B data (mapped at 0x170000+port)
	dec 4, xsp	; dec 4, XSP (allocate 4 bytes on stack)
	pushw iz
	ld (xsp + 2), xwa	; ld (XSP+0x02), XWA  ; store palette ptr
	ldw iz, 0xFF	; IZ = 255 (palette index counter)
	cps iz, 0	; initial check
	jr lt, HDAE5000_Load_Palette__done	; skip loop if IZ < 0 (never happens here)
HDAE5000_Load_Palette__loop:
	ldto_berp E, 0xF8	; E = current palette index
	ld wa, iz
	exts xwa	; sign-extend WA to XWA
	sll xwa, 2	; sll 2, XWA  ; XWA = index × 4
	ld xbc, xwa	; XBC = offset
	add xbc, (xsp + 2)	; add XBC, (XSP+0x02)  ; XBC = palette_ptr + offset
	ld a, e	; A = palette index
	calr HDAE5000_Palette_Setup	; Set one palette entry
	sub iz, 0x1	; IZ--
	jr ge, HDAE5000_Load_Palette__loop	; continue while IZ >= 0
HDAE5000_Load_Palette__done:
	popw iz
	inc 4, xsp	; inc 4, XSP (deallocate stack)
	ret

HDAE5000_Finalize_Init:	; 28F90Bh
	; Stub that just returns (placeholder)
	ret

HDAE5000_Display_Init:	; 28F90Ch (114 bytes)
	; Display and callback initialization
	; Registers callbacks via workspace function tables
	; Input: WA = display mode (1 = with sub-handlers)
	dec 2, xsp			; allocate 2 bytes on stack
	pushw iz			; save IZ
	ld iz, wa			; IZ = mode parameter
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2) — workspace pointer
	.byte 0xe3, 0xe1		; ld XWA, (XWA+0x0E88) — display handler table
	.short 0x0E88
	.byte 0x20
	.byte 0xe3, 0xe1		; ld XHL, (XWA+0x00E8) — init callback
	.short 0x00E8
	.byte 0x23
	lds wa, 1			; WA = 1
	call (xhl)			; call init callback
	cps iz, 1			; mode == 1?
	jr nz, .Ldi_skip1		; skip sub-handler if not
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2)
	.byte 0xe3, 0xe1		; ld XWA, (XWA+0x0E0A) — sub-handler table
	.short 0x0E0A
	.byte 0x20
	.byte 0xe3, 0xe1		; ld XHL, (XWA+0x0538) — sub-handler callback
	.short 0x0538
	.byte 0x23
	call (xhl)			; call sub-handler
.Ldi_skip1:
	call HDAE5000_Display_String_Render
	ld (xsp + 2), hl		; save result on stack
	cps iz, 1			; mode == 1?
	jr nz, .Ldi_skip2		; skip sub-handler if not
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2)
	.byte 0xe3, 0xe1		; ld XWA, (XWA+0x0E0A)
	.short 0x0E0A
	.byte 0x20
	.byte 0xe3, 0xe1		; ld XHL, (XWA+0x053C) — post-render callback
	.short 0x053C
	.byte 0x23
	call (xhl)			; call post-render sub-handler
.Ldi_skip2:
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2)
	.byte 0xe3, 0xe1		; ld XWA, (XWA+0x0E88)
	.short 0x0E88
	.byte 0x20
	.byte 0xe3, 0xe1		; ld XHL, (XWA+0x00EC) — cleanup callback
	.short 0x00EC
	.byte 0x23
	call (xhl)			; call cleanup
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2)
	.byte 0xe3, 0xe1		; ld XWA, (XWA+0x0E88)
	.short 0x0E88
	.byte 0x20
	.byte 0xe3, 0xe1		; ld XHL, (XWA+0x00F0) — final callback
	.short 0x00F0
	.byte 0x23
	call (xhl)			; call final callback
	ld hl, (xsp + 2)		; restore result from stack
	popw iz				; restore IZ
	inc 2, xsp			; deallocate 2 bytes
	ret

HDAE5000_Calc_Offset_16:	; 0x28F97E (13 bytes)
	; Calculate 16-byte offset in table at 0x201632
	; Input: WA = table index
	; Output: XHL = pointer to 16-byte entry
	extz xwa		; zero-extend index to 32 bits
	sll xwa, 4		; multiply by 16
	ld xhl, 0x201632	; table base address
	add xhl, xwa		; XHL = base + index*16
	ret

HDAE5000_Copy_To_Table:	; 0x28F98B (34 bytes)
	; Copy 16 bytes to table entry, then call Display_Callback
	; Input: WA = table index, XBC = source pointer, DE = param
	pushw iz
	ld iz, de			; save DE param
	pushw 0x0010			; push 16 (byte count)
	push xbc			; push source pointer
	extz xwa			; zero-extend index
	sll xwa, 4			; index * 16
	ld xbc, 0x00201632		; table base
	add xbc, xwa			; XBC = dest ptr
	push xbc			; push dest pointer
	call HDAE5000_MemCopy_Reverse	; memcpy(dest, src, 16)
	lda xsp, (xsp + 0x0A)		; deallocate 10 bytes
	ld wa, iz			; restore param
	calr HDAE5000_Display_Callback
	popw iz
	ret

HDAE5000_Get_Display_Dimensions_A1_2F:	; 0x28F9AD (62 bytes)
	; Check if tile entry matches reference; return 0 or -1
	; Input: WA = tile index, Output: HL = 0 (match) or 0xFFFF (mismatch)
	push xiz		; save XIZ
	ld iz, wa		; IZ = tile index
	.byte 0xd7, 0xfa, 0xa8	; ld QIZ, 0 (Q-bank: init result)
	pushw 0x002F		; push max length (47)
	pushw 0x8DE0		; push reference string address
	call HDAE5000_Display_Buffer_Validate
	pushw hl		; push reference length
	pushw 0x002F		; push max length
	pushw 0x8DE0		; push reference string
	ld wa, iz		; restore tile index
	extz xwa		; zero-extend
	sll xwa, 4		; XWA *= 16
	ld xbc, 0x00201632	; table base address
	add xbc, xwa		; XBC = base + index*16
	push xbc		; push tile address
	call HDAE5000_MemCompare_Block
	add xsp, 0x0000000E	; clean up 14 bytes
	cps hl, 0		; check compare result
	jr nz, .Lgdd_done	; skip if mismatch
	.byte 0xd7, 0xfa, 0x03, 0xff, 0xff	; ld QIZ, 0xFFFF (Q-bank: mark invalid)
.Lgdd_done:
	.byte 0xd7, 0xfa, 0x8b	; ld HL, QIZ (Q-bank: load result)
	pop xiz			; restore XIZ
	ret

HDAE5000_Count_Invalid_Cells:	; 0x28F9EB (51 bytes)
	; Count how many of 16 tile entries are invalid (-1)
	; Input: WA = row param, Output: HL = count of invalid entries
	dec 2, xsp		; allocate 2 bytes
	push xiz		; save XIZ
	ld (xsp + 4), wa	; save WA param on stack
	lds iz, 0		; IZ = 0 (invalid counter)
	.byte 0xd7, 0xfa, 0xa8	; ld QIZ, 0 (Q-bank: loop index)
	.byte 0xd7, 0xfa, 0xcf, 0x10, 0x00	; cp QIZ, 16 (Q-bank)
	jr nc, .Lcic_done	; if >= 16, done
.Lcic_loop:
	ld wa, (xsp + 4)	; restore WA param
	.byte 0xd7, 0xfa, 0x89	; ld BC, QIZ (Q-bank: loop index)
	calr HDAE5000_Table_Calc_Offset
	cp hl, 0xFFFF		; check if invalid (-1)
	jr nz, .Lcic_skip	; skip if valid
	inc 1, iz		; count invalid
.Lcic_skip:
	.byte 0xd7, 0xfa, 0x61	; inc 1, QIZ (Q-bank: loop++)
	.byte 0xd7, 0xfa, 0xcf, 0x10, 0x00	; cp QIZ, 16 (Q-bank)
	jr c, .Lcic_loop	; if < 16, continue loop
.Lcic_done:
	ld hl, iz		; HL = invalid count
	pop xiz			; restore XIZ
	inc 2, xsp		; deallocate 2 bytes
	ret

HDAE5000_Calculate_Row_Address:	; 0x28FA1E (56 bytes)
	; Calculate table address: base + row*1216 + 1920 + col*76
	; Input: WA = row, BC = column
	; Output: XHL = pointer to entry
	dec 4, xsp		; allocate 4 bytes
	pushw iz		; save IZ
	ld iz, wa		; IZ = row
	ld wa, bc		; WA = column
	extz xwa		; zero-extend to 32-bit
	ld xbc, 0x0000004C	; multiplier = 76
	call HDAE5000_Multiply	; XHL = col * 76
	ld (xsp + 2), xhl	; save col_offset on stack
	ld wa, iz		; WA = row
	extz xwa		; zero-extend
	ld xbc, 0x000004C0	; multiplier = 1216
	call HDAE5000_Multiply	; XHL = row * 1216
	add xhl, 0x780		; XHL += 1920 (header offset)
	ld xwa, xhl		; XWA = row_offset
	add xwa, (xsp + 2)	; XWA += col_offset
	ld xhl, 0x00201632	; table base address
	add xhl, xwa		; XHL = base + total_offset
	popw iz			; restore IZ
	inc 4, xsp		; deallocate 4 bytes
	ret

HDAE5000_Copy_Display_Cell:	; 0x28FA56 (74 bytes)
	; Copy table entry using row*1216 + 1920 + col*76 addressing, then callback
	; Input: WA = row, BC = column, stack+2 = copy size
	dec 4, xsp		; allocate 4 bytes
	pushw iz		; save IZ
	ld iz, wa		; IZ = row
	pushw 0x001A		; push 26 (entry size)
	push xde		; push dest pointer
	ld wa, bc		; WA = column
	extz xwa		; zero-extend
	ld xbc, 0x0000004C	; multiplier = 76
	call HDAE5000_Multiply	; XHL = col * 76
	ld (xsp + 8), xhl	; save col_offset on stack
	ld wa, iz		; WA = row
	extz xwa		; zero-extend
	ld xbc, 0x000004C0	; multiplier = 1216
	call HDAE5000_Multiply	; XHL = row * 1216
	add xhl, 0x780		; XHL += 1920
	add xhl, (xsp + 8)	; XHL += col_offset
	ld xwa, 0x00201632	; table base address
	add xwa, xhl		; XWA = base + total_offset
	push xwa		; push source pointer
	call HDAE5000_MemCopy_Reverse
	lda xsp, (xsp + 0x0A)	; deallocate 10 bytes
	ld wa, (xsp + 0x0A)	; load copy size param from stack
	calr HDAE5000_Display_Callback
	popw iz			; restore IZ
	inc 4, xsp		; deallocate 4 bytes
	retd 0x0002		; return and pop 2 bytes

HDAE5000_Calculate_Tile_Address:	; 0x28FAA0 (26 bytes)
	; Calculate tile address: base + index * 0x90 (144)
	; Input: WA = tile index
	; Output: XHL = pointer to tile entry
	; Algorithm: index*144 = index*(128+16) = (index<<3 + index)<<4
	extz xwa		; zero-extend index to 32 bits
	ld xbc, xwa		; XBC = index
	sll xbc, 3		; XBC = index * 8
	add xbc, xwa		; XBC = index * 9
	sll xbc, 4		; XBC = index * 144
	add xbc, 0x00024180	; add tile table offset
	ld xhl, 0x201632	; table base address
	add xhl, xbc		; XHL = base + offset
	ret

HDAE5000_Copy_Display_Cell_90:	; 0x28FABA (47 bytes)
	; Copy entry with 0x90 stride: base + index*144 + 0x24180, then callback
	; Input: WA = tile index, DE = callback param
	pushw iz		; save IZ
	ld iz, de		; IZ = callback param
	pushw 0x0010		; push 16 (copy size)
	push xbc		; push dest pointer
	extz xwa		; zero-extend tile index
	ld xbc, xwa		; XBC = index
	sll xbc, 3		; XBC = index * 8
	add xbc, xwa		; XBC = index * 9
	sll xbc, 4		; XBC = index * 144
	add xbc, 0x00024180	; add entry table offset
	ld xwa, 0x00201632	; table base address
	add xwa, xbc		; XWA = base + offset
	push xwa		; push source pointer
	call HDAE5000_MemCopy_Reverse	; copy 16 bytes
	lda xsp, (xsp + 0x0A)	; deallocate 10 bytes
	ld wa, iz		; restore callback param
	calr HDAE5000_Display_Callback
	popw iz			; restore IZ
	ret

HDAE5000_Validate_Cell_Coords:	; 0x28FAE9 (61 bytes)
	; Compare tile entry with reference, return 0 if valid or -1 if invalid
	; Input: WA = tile index
	; Output: HL = 0 (valid) or 0xFFFF (invalid)
	dec 2, xsp		; allocate 2 bytes for result
	pushw iz		; save IZ
	ld iz, wa		; IZ = tile index
	ldmw (xsp + 2), 0x0000	; result = 0 (valid)
	pushw 0x002F		; push max length (47)
	pushw 0x8DF2		; push reference string address
	call HDAE5000_Display_Buffer_Validate
	inc 4, xsp		; clean up 2 args
	pushw hl		; push reference length
	pushw 0x002F		; push max length
	pushw 0x8DF2		; push reference string address
	ld wa, iz		; restore tile index
	calr HDAE5000_Calculate_Tile_Address	; XHL = tile address
	push xhl		; push tile address (32-bit)
	call HDAE5000_MemCompare_Block
	add xsp, 0x0000000A	; clean up 10 bytes
	cps hl, 0		; compare result
	jr nz, .Lvcc_done	; if not equal, valid (keep 0)
	ldmw (xsp + 2), 0xFFFF	; mark invalid (-1)
.Lvcc_done:
	ld hl, (xsp + 2)	; load result
	popw iz			; restore IZ
	inc 2, xsp		; deallocate 2 bytes
	ret

HDAE5000_Resolve_Cell_Address:	; 0x28FB26 (139 bytes)
	; Get entry address with validation; returns XHL = entry ptr or error ptr
	; Input: WA = row, BC = column
	; Output: XHL = pointer to entry (or fallback if invalid)
	dec 4, xsp		; allocate 4 bytes
	pushw iz		; save IZ
	ld iz, bc		; IZ = column
	ld (xsp + 4), wa	; save row on stack
	; First: validate the cell
	ld wa, (xsp + 4)	; WA = row
	ld bc, iz		; BC = column
	calr HDAE5000_Cell_In_Bounds
	cp hl, 0xFFFF		; invalid?
	jr z, .Lrca_fail	; if -1, use fallback address
	; Calculate row offset: look up row dimension table at 0x2257E2
	ld bc, iz		; BC = column
	extz xbc		; zero-extend column
	ld wa, (xsp + 4)	; WA = row
	extz xwa		; zero-extend row
	ld xde, xwa		; XDE = row
	sll xde, 3		; XDE = row * 8
	add xde, xwa		; XDE = row * 9
	sll xde, 4		; XDE = row * 144
	add xde, xbc		; XDE = row*144 + col
	ldada_24 xwa, 2250722	; lda XWA, (0x2257E2) - row dimension table
	add xwa, xde		; XWA = table + row*144 + col
	ld a, (xwa)		; A = dimension value
	dec 1, a		; A -= 1
	extz wa			; zero-extend A to WA
	muls wa, 0x004C		; WA = (dim-1) * 76
	ld (xsp + 2), wa	; save row_offset
	; Calculate column offset: look up col dimension table at 0x2257C2
	ld bc, iz		; BC = column
	extz xbc		; zero-extend
	ld wa, (xsp + 4)	; WA = row
	extz xwa		; zero-extend
	ld xde, xwa		; XDE = row
	sll xde, 3		; XDE = row * 8
	add xde, xwa		; XDE = row * 9
	sll xde, 4		; XDE = row * 144
	add xde, xbc		; XDE = row*144 + col
	ldada_24 xwa, 2250690	; lda XWA, (0x2257C2) - col dimension table
	add xwa, xde		; XWA = table + index
	ld a, (xwa)		; A = col dimension
	dec 1, a		; A -= 1
	ldb w, 0x00		; W = 0 (zero-extend A to WA manually)
	extz xwa		; zero-extend WA to XWA
	ld xbc, 0x000004C0	; multiplier = 1216
	call HDAE5000_Multiply	; XHL = col_dim * 1216
	add xhl, 0x780		; XHL += 1920
	ld wa, (xsp + 2)	; WA = row_offset
	exts xwa		; sign-extend WA to XWA
	add xwa, xhl		; XWA = total offset
	ld xhl, 0x00201632	; table base address
	add xhl, xwa		; XHL = final entry address
	jr t, .Lrca_done	; jump to epilogue
.Lrca_fail:
	ldada_24 xhl, 3116548	; lda XHL, (0x2F8E04) - fallback/error address
.Lrca_done:
	popw iz			; restore IZ
	inc 4, xsp		; deallocate 4 bytes
	ret

; ============================================================================
; Display Table Management and UI Cell Rendering (0x28FBB1-0x295008)
; 21,592 bytes, 50 routines
;
; Table operations use 0x4C (76) byte stride for row addressing
; and 0x90 (144) byte stride for tile addressing.
; Eight routines at 0x2934C8-0x293BB8 are exactly 222 bytes each,
; likely one per UI cell/widget type.
; ============================================================================

HDAE5000_Cell_In_Bounds:	; 0x28FBB1 (1497 bytes)
	; Validate entry at coordinates; calculates table offset
	.incbin "includes/code_28f90c_2953e1.bin", 677, 1497

HDAE5000_Table_Calc_Offset:	; 0x29018A (553 bytes)
	; Calculate table offset using 0x4C multiplier
	.incbin "includes/code_28f90c_2953e1.bin", 2174, 553

HDAE5000_Table_Lookup:	; 0x2903B3 (928 bytes)
	; Look up entry in display table; returns 0xFFFF on failure
	.incbin "includes/code_28f90c_2953e1.bin", 2727, 928

HDAE5000_Table_Sub_290753:	; 0x290753 (350 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 3655, 350

HDAE5000_Table_Sub_2908B1:	; 0x2908B1 (335 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 4005, 335

HDAE5000_Table_Sub_290A00:	; 0x290A00 (390 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 4340, 390

HDAE5000_Table_Sub_290B86:	; 0x290B86 (303 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 4730, 303

HDAE5000_Table_Sub_290CB5:	; 0x290CB5 (220 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 5033, 220

HDAE5000_Table_Sub_290D91:	; 0x290D91 (303 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 5253, 303

HDAE5000_Table_Sub_290EC0:	; 0x290EC0 (133 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 5556, 133

HDAE5000_Table_Sub_290F45:	; 0x290F45 (248 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 5689, 248

HDAE5000_Table_Sub_29103D:	; 0x29103D (1023 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 5937, 1023

HDAE5000_Table_Init_Entry:	; 0x29143C (359 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 6960, 359

HDAE5000_Table_Sub_2915A3:	; 0x2915A3 (217 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 7319, 217

HDAE5000_Table_Sub_29167C:	; 0x29167C (226 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 7536, 226

HDAE5000_Table_Sub_29175E:	; 0x29175E (211 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 7762, 211

HDAE5000_Table_Sub_291831:	; 0x291831 (216 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 7973, 216

HDAE5000_Table_Sub_291909:	; 0x291909 (211 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 8189, 211

HDAE5000_Table_Sub_2919DC:	; 0x2919DC (134 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 8400, 134

HDAE5000_Table_Sub_291A62:	; 0x291A62 (209 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 8534, 209

HDAE5000_Table_Sub_291B33:	; 0x291B33 (171 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 8743, 171

HDAE5000_Table_Sub_291BDE:	; 0x291BDE (47 bytes)
	; Initialize table entry structure with string address
	; Input: WA = offset, XBC = structure pointer
	; Output: HL = offset
	dec 2, xsp
	push xiz
	ld xiz, xbc			; XIZ = structure pointer
	ld (xsp + 4), wa		; save offset on stack
	ldada_24 xwa, 2274352		; 0x22B430 - base string address
	ld (xiz), xwa			; store string pointer in structure
	ldda32_24 xwa, 2274370		; 0x22B442 - load source string pointer
	call HDAE5000_String_To_Upper
	add hl, 0x0016			; add 22 to string length
	ld wa, hl
	exts xwa			; sign-extend to 32-bit
	ld (xiz + 4), xwa		; store computed size
	stda32_24 2295026, xwa		; 0x2304F2 - global size variable
	ld hl, (xsp + 4)		; return saved offset
	pop xiz
	inc 2, xsp
	ret

HDAE5000_Table_Complex_Init:	; 0x291C0D (2171 bytes)
	; Complex table initialization (large stack frame)
	.incbin "includes/code_28f90c_2953e1.bin", 8961, 2171

HDAE5000_Table_Sub_292488:	; 0x292488 (359 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 11132, 359

HDAE5000_Table_Sub_2925EF:	; 0x2925EF (425 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 11491, 425

HDAE5000_Table_Sub_292798:	; 0x292798 (419 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 11916, 419

HDAE5000_Table_Sub_29293B:	; 0x29293B (419 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 12335, 419

HDAE5000_Table_Sub_292ADE:	; 0x292ADE (288 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 12754, 288

HDAE5000_Table_Sub_292BFE:	; 0x292BFE (280 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 13042, 280

HDAE5000_Table_Sub_292D16:	; 0x292D16 (419 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 13322, 419

HDAE5000_Table_Sub_292EB9:	; 0x292EB9 (281 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 13741, 281

HDAE5000_Table_Sub_292FD2:	; 0x292FD2 (329 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 14022, 329

HDAE5000_Workspace_Handler:	; 0x29311B (592 bytes)
	; Firmware workspace callback handler
	.incbin "includes/code_28f90c_2953e1.bin", 14351, 592

HDAE5000_Workspace_Sub_29336B:	; 0x29336B (349 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 14943, 349

; --- UI Cell Renderers (8 x 222 bytes each) ---
HDAE5000_Cell_Render_Type0:	; 0x2934C8 (222 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 15292, 222

HDAE5000_Cell_Render_Type1:	; 0x2935A6 (222 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 15514, 222

HDAE5000_Cell_Render_Type2:	; 0x293684 (222 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 15736, 222

HDAE5000_Cell_Render_Type3:	; 0x293762 (222 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 15958, 222

HDAE5000_Cell_Render_Type4:	; 0x293840 (222 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 16180, 222

HDAE5000_Cell_Render_Type5:	; 0x29391E (222 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 16402, 222

HDAE5000_Cell_Render_Type6:	; 0x2939FC (222 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 16624, 222

HDAE5000_Cell_Render_Type7:	; 0x293ADA (222 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 16846, 222

HDAE5000_Cell_Render_Type8:	; 0x293BB8 (222 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 17068, 222

HDAE5000_Cell_Validate:	; 0x293C96 (347 bytes)
	; Validate cell rendering parameters
	.incbin "includes/code_28f90c_2953e1.bin", 17290, 347

HDAE5000_Cell_Get_Params:	; 0x293DF1 (61 bytes)
	; Get cell rendering parameters from data source
	; Input: XWA = source pointer (0 = use default address 0x200)
	; Output: XHL = parameter block pointer
	dec 0, xsp			; allocate 8 bytes
	push xiz
	ld xiz, xwa			; XIZ = source pointer
	or xwa, xwa			; test if source is NULL
	jr z, .Lcgp_default
	ld xbc, 0x00000200		; buffer size = 512
	push xbc
	push xwa			; source pointer
	lda xwa, (xsp + 0x0C)		; pointer to local buffer
	push xwa
	call HDAE5000_Cell_Copy_Buffer
	lda xsp, (xsp + 0x0C)		; clean up 12 bytes from stack
	ld xwa, (xsp + 8)		; check copied length
	or xwa, xwa
	jr z, .Lcgp_result
	ld xwa, (xsp + 4)		; get offset field
	sla xwa, 9			; multiply by 512
	add xwa, 0x00000200		; add base address
	ld xiz, xwa			; XIZ = computed address
	jr t, .Lcgp_result
.Lcgp_default:
	ld xiz, 0x00000200		; default: address 0x200
.Lcgp_result:
	ld xhl, xiz			; return value in XHL
	pop xiz
	inc 0, xsp			; deallocate 8 bytes
	ret

HDAE5000_Display_Callback:	; 0x293E2E (1093 bytes)
	; Display callback handler via workspace
	.incbin "includes/code_28f90c_2953e1.bin", 17698, 1093

HDAE5000_Display_Sub_294273:	; 0x294273 (43 bytes)
	; Set up display callback with function pointer
	; Input: XWA = callback function pointer
	; Output: HL = 0 (success) or 0xFFFF (already active)
	cpdi8_24 2330412, 0x00		; check if callback is active (0x238F2C)
	jr z, .Lds273_setup
	stdi8_24 2330412, 0x00		; clear active flag
	ldw hl, 0xFFFF			; return -1 (already active)
	jr t, .Lds273_done
.Lds273_setup:
	ldada_24 xbc, 2297628		; 0x230F1C - callback table base
	stda32_24 2330404, xbc		; 0x238F24 - store table pointer
	stda32_24 2330408, xwa		; 0x238F28 - store callback function
	stdi8_24 2330412, 0x01		; 0x238F2C - set active flag
	lds hl, 0			; return 0 (success)
.Lds273_done:
	ret

HDAE5000_Display_Sub_29429E:	; 0x29429E (99 bytes)
	; Execute display callback and restore display state
	; Checks callback state flag and dispatches to copy or restore
	ldada_24 xwa, 2297628		; 0x230F1C - RAM test area base
	cpda32_24 xwa, 2330404		; compare with stored table pointer (0x238F24)
	jr z, .Lds29e_clear
	cpdi8_24 2330412, 0x01		; check active flag == 1 (0x238F2C)
	jr nz, .Lds29e_restore
	; State 1: copy display block
	ldada_24 xwa, 2297628		; XWA = base address
	ld xhl, xwa			; XHL = dest (base)
	ldada_24 xbc, 2297628		; XBC = base
	ldda32_24 xwa, 2330404		; XWA = stored table pointer
	sub xwa, xbc			; XWA = offset (table - base)
	ld xbc, xwa			; XBC = size
	ldda32_24 xde, 2330408		; XDE = callback function (0x238F28)
	ld xwa, xhl			; XWA = dest address
	call HDAE5000_Display_Copy
	stdi8_24 2330412, 0x02		; set state to 2
	jr t, .Lds29e_clear
.Lds29e_restore:
	; State 2+: restore display block
	ldada_24 xwa, 2297628		; XWA = base address
	ld xhl, xwa
	ldada_24 xbc, 2297628		; XBC = base
	ldda32_24 xwa, 2330404		; XWA = stored table pointer
	sub xwa, xbc			; XWA = offset
	ld xbc, xwa			; XBC = size
	ldda32_24 xde, 2330408		; XDE = callback function
	ld xwa, xhl			; XWA = dest address
	call HDAE5000_Display_Restore
.Lds29e_clear:
	stdi8_24 2330412, 0x00		; clear active flag
	ret

HDAE5000_Display_Sub_294301:	; 0x294301 (275 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 18933, 275

HDAE5000_Display_Sub_294414:	; 0x294414 (3061 bytes)
	; Large display management routine
	.incbin "includes/code_28f90c_2953e1.bin", 19208, 3061

HDAE5000_PPORT_Util:	; 0x295009
	; PPORT utility - push params and call workspace handler
	pushw 0x0000			; arg 1
	pushw 0x0001			; arg 2
	ldda16_24 xde, 2330414		; DE = (0x238F2E) - callback ID
	call HDAE5000_Workspace_Sub_29336B
	lds hl, 0			; return 0
	ret
	nop

HDAE5000_PPORT_Handler:	; 0x29501C
	; PPORT state machine entry - check active, load params, dispatch
	cpdi8_24 2330624, 0x01		; check if PPORT active (0x239000)
	jr nz, .Lpph_done
	ldda16_24 xwa, 2330634		; WA = cmd param (0x23900A)
	nop
	ldda32_24 xbc, 2330636		; XBC = data ptr (0x23900C)
	nop
	ldda32_24 xde, 2330640		; XDE = size (0x239010)
	nop
	call HDAE5000_PPORT_Setup
	call HDAE5000_PPORT_Dispatch
.Lpph_done:
	ret
	nop
	; --- Secondary entry: menu init ---
	call HDAE5000_PPORT_Menu
	jr t, HDAE5000_PPORT_Init

HDAE5000_PPORT_Status:	; 0x295046
	; Switch to PPORT stack context for status check
	ei 0x06				; disable interrupts (level 6)
	stda32_24 2330630, xsp		; save current SP (0x239006)
	nop
	ldda32_24 xsp, 2330626		; load PPORT SP (0x239002)
	nop
	ei 0x00				; re-enable interrupts
	ret
	nop

HDAE5000_PPORT_Init:	; 0x295058 (116 bytes, 3 entry points)
	; Entry 1: Stack context switch (save/restore SP for PPORT workspace)
	ei 0x06				; disable interrupts
	stda32_24 2330626, xsp	; save current SP to (0x239002)
	nop
	ldda32_24 xsp, 2330630	; load PPORT SP from (0x239006)
	nop
	ei 0x00				; re-enable interrupts
	ret
	nop
HDAE5000_PPORT_Init_Main:	; 0x29506A
	; Entry 2: Initialize PPORT state machine
	push xhl
	nop
	push xwa
	nop
	cpdi8_24 2330624, 0x01	; cp (0x239000), 1 — already initialized?
	jr z, .Lpi_exit		; if already init, just return
	stdi8_24 2330644, 0x00	; clear abort flag (0x239014)
	stdi8_24 2330624, 0x01	; set state = initialized (0x239000)
	ld xhl, 0x0023FFFC	; stack top for PPORT workspace
	nop
	stda32_24 2330626, xhl	; store as PPORT SP (0x239002)
	nop
	ld xwa, 0x00295040	; PPORT entry callback address
	nop
	ld (xhl), xwa		; store callback at stack top
	ldb a, 0x00		; param = 0
	call HDAE5000_PPORT_Status	; switch to PPORT stack and call
	cpdi8_24 2330644, 0x00	; check abort flag (0x239014)
	jr nz, .Lpi_exit	; if aborted, exit
	ldw hl, 0xFFFF		; HL = -1 (error/timeout)
	nop
	stda16_24 2330634, xhl	; store result (0x23900A)
	nop
	stdi8_24 2330624, 0x00	; clear state = uninitialized
.Lpi_exit:
	pop xwa
	nop
	pop xhl
	nop
	ret
	nop
HDAE5000_PPORT_Reset:		; 0x2950BA
	; Entry 3: Reset PPORT state
	ldw hl, 0xFFFF		; HL = -1
	nop
	stda16_24 2330634, xhl	; store result (0x23900A)
	nop
	stdi8_24 2330624, 0x00	; clear state = uninitialized
	ret
	nop

HDAE5000_PPORT_Dispatch:	; 0x2950CC
	; Command dispatcher - switch to PPORT context, check for command
	push xhl
	nop
	call HDAE5000_PPORT_Status	; switch stacks
	cpdi8_24 2330644, 0x00		; check command flag (0x239014)
	jr nz, .Lppd_done
	ldw hl, 0xFFFF			; no command: mark result = -1
	nop
	stda16_24 2330634, xhl		; store result (0x23900A)
	nop
	stdi8_24 2330624, 0x00		; clear PPORT active flag (0x239000)
.Lppd_done:
	pop xhl
	nop
	ret
	nop
	; --- Secondary entry: get result ---
	ldda16_24 xhl, 2330634		; HL = command result (0x23900A)
	nop
	exts xhl			; sign-extend to 32-bit
	ret
	nop

HDAE5000_Display_String:	; 0x2950F8
	; Display string on screen via PPORT protocol
	; Input: WA = position, XBC = string ptr, XDE = format params
	stda16_24 2330634, xwa		; store position (0x23900A)
	nop
	stda32_24 2330636, xbc		; store string ptr (0x23900C)
	nop
	stda32_24 2330640, xde		; store format (0x239010)
	nop
	stdi8_24 2330644, 0x01		; set command flag (0x239014)
	call HDAE5000_PPORT_Init	; initialize PPORT transfer
	stdi8_24 2330644, 0x00		; clear command flag
	ret
	nop

HDAE5000_PPORT_Setup:	; 0x29511C
	; PPORT setup routine
	.incbin "includes/code_28f90c_2953e1.bin", 22544, 442

HDAE5000_PPORT_Menu:	; 0x2952D6
	; PPORT menu handler - save all registers, execute, restore
	push xwa
	nop
	push xbc
	nop
	push xde
	nop
	push xhl
	nop
	push xix
	nop
	push xiy
	nop
	push xiz
	nop
	call HDAE5000_PPORT_Execute
	pop xiz
	nop
	pop xiy
	nop
	pop xix
	nop
	pop xhl
	nop
	pop xde
	nop
	pop xbc
	nop
	pop xwa
	nop
	ret
	nop

HDAE5000_PPORT_Execute:	; 0x2952F8
	; Execute PPORT command
	.incbin "includes/code_28f90c_2953e1.bin", 23020, 234

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

HDAE5000_PPORT_Cmd_Table:	; 2953E2h
	.long HDAE5000_Cmd01_SendInfo
	.long HDAE5000_Cmd02_Exit
	.long HDAE5000_Cmd03_ReadFSB
	.long HDAE5000_Cmd04_SendFSB
	.long HDAE5000_Cmd05_RcvFSB
	.long HDAE5000_Cmd06_WriteFSB
	.long HDAE5000_PPORT_Cmd_LoadHDtoMemory
	.long HDAE5000_PPORT_Cmd_SendDataBlock
	.long HDAE5000_PPORT_Cmd_SendFileList
	.long HDAE5000_PPORT_Cmd_ReceiveDataBlock
	.long HDAE5000_PPORT_Cmd_WriteMemoryToHD
	.long HDAE5000_PPORT_Cmd_Reserved

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

HDAE5000_PPORT_Ptrs:	; 295412h
	; 3 pointers to PPORT utility routines (in code_295642_2971a2.bin)
	.long PPORT_Utility_1
	.long PPORT_Utility_2
	.long PPORT_Utility_3

HDAE5000_PPORT_Strings:	; 29541Eh
	; PPORT command menu strings (21 null-terminated strings)
	; Format: "NN>Description" where NN = command number
	.asciz "01>Send Infos About HD"
	.byte 0x00
	.asciz "02>Exit PPORT         "
	.byte 0x00
	.asciz "03>Read FSB from HD   "
	.byte 0x00
	.asciz "04>Sending FSB to PC  "
	.byte 0x00
	.asciz "05>Rcv FSB from PC    "
	.byte 0x00
	.asciz "06>Writing FSB to HD  "
	.byte 0x00
	.asciz "07>Load HD to Memory  "
	.byte 0x00
	.asciz "08>Send data to PC    "
	.byte 0x00
	.asciz "09>Sending files to PC"
	.byte 0x00
	.asciz "10>Rcv data from PC   "
	.byte 0x00
	.asciz "11>Save memory to HD  "
	.byte 0x00
	.asciz "12>nothing            "
	.byte 0x00
	.asciz "13>Rcv data from PC   "
	.byte 0x00
	.asciz "14>Sending infos to PC"
	.byte 0x00
	.asciz "15>nothing            "
	.byte 0x00
	.asciz "16>Delete files       "
	.byte 0x00
	.asciz "17>Formating HD       "
	.byte 0x00
	.asciz "18>Switch HD-motor off"
	.byte 0x00
	.asciz "19>nothing            "
	.byte 0x00
	.asciz "20>Send XapFile flash "
	.byte 0x00
	.ascii "20>End flash right"
	.byte 0x09, 0x20, 0x20, 0x00
	.ascii "20>End flash false"
	.byte 0x09, 0x20, 0x20, 0x00
	.asciz "Error : Wrong Dll Ver "
	.byte 0x00

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

HDAE5000_Code_2_PartB:	; 295642h
	; PPORT command handlers and HD routines
	.incbin "includes/code_295642_2971a2.bin", 0, 660

HDAE5000_Cmd01_SendInfo:	; 0x2958D6 (62 bytes)
	; Handler: Send HD info - display status, clear buffer, check result
	ldw wa, 0x001A			; display row/column
	nop
	ldada_24 xbc, 2708630	; lda XBC, (0x295496) - status string
	nop
	call HDAE5000_Display_String
	call HDAE5000_PPORT_Ready_Check
	ldw wa, 0x000A			; display row/column
	nop
	ei 0x00				; enable interrupts
	call HDAE5000_Display_String
	ei 0x07				; disable interrupts
	cps wa, 0			; check result
	jpcc_24 6, 0x295900		; jp Z - skip cleanup if zero
	nop
	call HDAE5000_PPORT_Cleanup
	call HDAE5000_PPORT_Sum_Buffer
	cpdi8_24 2330836, 0x01	; cp (0x2390D4), 1
	jpcc_24 6, 0x295374		; jp Z - exit to PPORT finish
	nop
	jp HDAE5000_PPORT_Cmd_Done

HDAE5000_Cmd02_Exit:	; 0x295914
	; Handler: Exit PPORT
	.incbin "includes/code_295642_2971a2.bin", 722, 226

HDAE5000_Cmd03_ReadFSB:	; 0x2959F6
	; Handler: Read FSB from HD
	.incbin "includes/code_295642_2971a2.bin", 948, 838

HDAE5000_Cmd04_SendFSB:	; 0x295D3C
	; Handler: Send FSB to PC
	.incbin "includes/code_295642_2971a2.bin", 1786, 798

HDAE5000_Cmd05_RcvFSB:	; 0x29605A
	; Handler: Receive FSB from PC
	.incbin "includes/code_295642_2971a2.bin", 2584, 570

HDAE5000_Cmd06_WriteFSB:	; 0x296294
	; Handler: Write FSB to HD
	.incbin "includes/code_295642_2971a2.bin", 3154, 150

HDAE5000_PPORT_Cmd_LoadHDtoMemory:	; 0x29632A
	; Load HD to memory - display status and finish
	ldw wa, 0x001A			; display row/column
	nop
	ldada_24 xbc, 2708774		; 0x295526 - "Load HD" string
	nop
	call HDAE5000_Display_String
	jp HDAE5000_PPORT_Cmd_Done

HDAE5000_PPORT_Cmd_SendDataBlock:	; 0x29633C
	; Send data block to PC
	.incbin "includes/code_295642_2971a2.bin", 3322, 362

HDAE5000_PPORT_Cmd_SendFileList:	; 0x2964A6
	; Send file list to PC
	.incbin "includes/code_295642_2971a2.bin", 3684, 226

HDAE5000_PPORT_Cmd_ReceiveDataBlock:	; 0x296588
	; Receive data from PC - display status and finish
	ldw wa, 0x001A			; display row/column
	nop
	ldada_24 xbc, 2708846		; 0x29556E - "Receive Data" string
	nop
	call HDAE5000_Display_String
	jp HDAE5000_PPORT_Cmd_Done

HDAE5000_PPORT_Cmd_WriteMemoryToHD:	; 0x29659A
	; Save memory to HD
	.incbin "includes/code_295642_2971a2.bin", 3928, 230

HDAE5000_PPORT_Cmd_Reserved:	; 0x296680 (62 bytes)
	; Reserved PPORT command - display status, clear buffer, check result
	ldw wa, 0x001A			; display row/column
	nop
	ldada_24 xbc, 2708894	; lda XBC, (0x29559E) - status string
	nop
	call HDAE5000_Display_String
	call HDAE5000_PPORT_Ready_Check
	ldw wa, 0x0011			; display row/column
	nop
	ei 0x00				; enable interrupts
	call HDAE5000_Display_String
	ei 0x07				; disable interrupts
	cps wa, 0			; check result
	jpcc_24 6, 0x2966AA		; jp Z - skip cleanup if zero
	nop
	call HDAE5000_PPORT_Cleanup
	call HDAE5000_PPORT_Sum_Buffer
	cpdi8_24 2330836, 0x01	; cp (0x2390D4), 1
	jpcc_24 6, 0x295374		; jp Z - exit to PPORT finish
	nop
	jp HDAE5000_PPORT_Cmd_Done

PPORT_Utility_1:	; 0x2966BE (60 bytes)
	; PPORT utility - display status, clear buffer, check result
	ldw wa, 0x001A			; display row/column
	nop
	ldada_24 xbc, 2708918	; lda XBC, (0x2955B6) - status string
	nop
	call HDAE5000_Display_String
	call HDAE5000_PPORT_Ready_Check
	lds wa, 2			; WA = 2
	ei 0x00				; enable interrupts
	call HDAE5000_Display_String
	ei 0x07				; disable interrupts
	cps wa, 0			; check result
	jpcc_24 6, 0x2966E6		; jp Z - skip cleanup if zero
	nop
	call HDAE5000_PPORT_Cleanup
	call HDAE5000_PPORT_Sum_Buffer
	cpdi8_24 2330836, 0x01	; cp (0x2390D4), 1
	jpcc_24 6, 0x295374		; jp Z - exit to PPORT finish
	nop
	jp HDAE5000_PPORT_Cmd_Done

PPORT_Utility_2:	; 0x2966FA
	; PPORT utility routine 2 - display status and finish
	ldw wa, 0x001A			; display row/column
	nop
	ldada_24 xbc, 2708942		; 0x2955CE - status string
	nop
	call HDAE5000_Display_String
	jp HDAE5000_PPORT_Cmd_Done

PPORT_Utility_3:	; 0x29670C (164 bytes)
	; PPORT utility routine 3
	.incbin "includes/code_295642_2971a2.bin", 4298, 164

HDAE5000_PPORT_Cmd_Done:	; 0x2967B0 (4 bytes)
	; PPORT command completion - jump to finish handler
	jp 0x295374

HDAE5000_Render_Display_Region:	; 0x2967B4 (48 bytes)
	; Copy 4 display region parameters from (XIX+1..4) to direct memory
	ldada_24 xix, 2330984	; lda XIX, (0x239168)
	nop
	ld a, (xix + 1)
	nop
	stda8_24 2330838, a	; st (0x2390D6), A
	nop
	ld a, (xix + 2)
	nop
	stda8_24 2330840, a	; st (0x2390D8), A
	nop
	ld a, (xix + 3)
	nop
	stda8_24 2330842, a	; st (0x2390DA), A
	nop
	ld a, (xix + 4)
	nop
	stda8_24 2330844, a	; st (0x2390DC), A
	nop
	ret
	nop

HDAE5000_Render_Display_Region2:	; 0x2967E4
	; Display region rendering 2
	.incbin "includes/code_295642_2971a2.bin", 4514, 166

HDAE5000_PPORT_Sum_Buffer:	; 0x29688A
	; Sum 256 bytes of buffer memory, clear status word
	.incbin "includes/code_295642_2971a2.bin", 4680, 530

HDAE5000_PPORT_Ready_Check:	; 0x296A9C (26 bytes)
	; Clear 256 bytes of memory at (XIX + 0..255) using register-indexed store
	ldada_24 xix, 2330984	; lda XIX, (0x239168)
	nop
	lds bc, 0		; BC = 0 (loop counter)
.Lprc_loop:
	cp bc, 0x0100		; compare BC with 256
	jr z, .Lprc_done	; if BC == 256, done
	stib_dri 0x07, 0xF0, 0xE4, 0x00	; ld (XIX+BC), 0x00
	inc 1, bc		; BC++
	jr t, .Lprc_loop	; always loop back
.Lprc_done:
	ret
	nop

HDAE5000_PPORT_Cleanup:	; 0x296AB6
	; PPORT cleanup routine
	.incbin "includes/code_295642_2971a2.bin", 5236, 1773

HDAE5000_Check_HD_Present:	; 2971A3h
	; Entry wrapper for HD presence detection
	; Clears result flag, calls internal RAM test routine, returns result
	; Output: L = 0 if no HD, non-zero if HD detected
	push xiz
	stdi8_24 2268562, 0	; ld (229D92h), 0 - clear result flag
	call 0x2971B7	; Call internal test routine
	pop xiz
	xor hl, hl	; Clear HL
	ldda8_24 l, 2268562	; ld L, (229D92h) - get result
	ret

; ============================================================================
; HD Detection, RAM Test, and String Formatting Library
; 0x2971B7-0x29AE9E (15,592 bytes, 11 identified routines)
;
; Contains:
;   - RAM test and verification (32KB at 0x230F1C-0x238F1C)
;   - HD initialization and drive detection (ATA IDENTIFY)
;   - CHS geometry configuration
;   - Version strings ("Technics Software section M. Kitajima", "2.33J")
;   - sprintf-like string formatting library (decimal/hex/octal conversion)
; ============================================================================

HDAE5000_RAM_Test:	; 0x2971B7 (1902 bytes)
	; RAM test: fill/verify 32KB at 0x230F1C-0x238F1C with 0x5A5A pattern
	.incbin "includes/code_2971b7_29ae9e.bin", 0, 1902

HDAE5000_HD_Init_Variables:	; 0x297925 (37 bytes)
	; 32x32 → 64-bit multiply using partial products
	; Computes XWA = BC * WA (full 32-bit result via 3 partial 16×16 multiplies)
	; Input: WA = multiplicand, BC = multiplier (16-bit halves)
	; Output: XWA = 32-bit product
	push xhl
	push xix
	ld hl, bc			; HL = low(BC)
	mul xhl, xwa			; XHL = low(BC) * WA
	ld xix, xhl			; accumulate in XIX
	ld hl, bc			; HL = low(BC) again
	.byte 0xd7, 0xe2, 0x43		; mul XHL, QWA — HL * high(WA)
	.byte 0xd7, 0xee, 0x9b		; ld QHL, HL — save partial to prev bank
	lds hl, 0			; clear low HL
	add xix, xhl			; add shifted partial product
	.byte 0xd7, 0xe6, 0x8b		; ld HL, QBC — high(BC)
	mul xhl, xwa			; XHL = high(BC) * WA
	.byte 0xd7, 0xee, 0x9b		; ld QHL, HL — save partial
	lds hl, 0			; clear low HL
	add xix, xhl			; add shifted partial product
	ld xwa, xix			; result in XWA
	pop xix
	pop xhl
	ret

HDAE5000_HD_Config_Init_Values:	; 0x29794A (389 bytes)
	; Set initial HD config values at 0x229Dxx
	.incbin "includes/code_2971b7_29ae9e.bin", 1939, 389

HDAE5000_HD_Detect_Drive:	; 0x297ACF (839 bytes)
	; Detect HD presence via ATA IDENTIFY, configure CHS geometry
	; Contains version strings at 0x2999B2:
	;   "Technics Software section    M. Kitajima"
	;   "2.33J", "2.21", "TECHNICS KN5000"
	.incbin "includes/code_2971b7_29ae9e.bin", 2328, 839

HDAE5000_Display_Copy:	; 0x297E16 (443 bytes)
	; Display block copy operation
	.incbin "includes/code_2971b7_29ae9e.bin", 3167, 443

HDAE5000_Display_Restore:	; 0x297FD1 (9217 bytes)
	; Display restore/update operation
	.incbin "includes/code_2971b7_29ae9e.bin", 3610, 1617
HDAE5000_Display_String_Render:	; 0x298622 (cross-reference from Display_Init)
	.incbin "includes/code_2971b7_29ae9e.bin", 5227, 7600

; --- String Formatting Library (sprintf-like) ---
HDAE5000_Int_To_Decimal_String:	; 0x29A3D2 (80 bytes)
	; Convert signed 32-bit integer to decimal string
	; Stack: [+0x0C] = output buffer ptr (with write-ahead), [+0x10] = signed value
	; Negates if negative, then extracts digits via repeated /10
	dec 4, xsp			; allocate local scratch space
	push xiz
	ld xwa, (xsp + 16)		; load signed value
	cp xwa, 0x00000000		; check sign
	jr ge, .LInt_To_Dec__positive
	cpl wa				; negate low word
	.byte 0xd7, 0xe2, 0x06		; cpl QWA — negate high word
	inc 1, xwa			; two's complement
.LInt_To_Dec__positive:
	ld xiz, xwa			; XIZ = |value|
.LInt_To_Dec__loop:
	ld xwa, (xsp + 12)		; get buffer state
	st_dpib a, 0xE0			; lda XBC, (XWA+) — advance write ptr
	ld (xsp + 4), xbc		; save digit write position
	ld (xsp + 12), xwa		; save advanced buffer ptr
	ld xwa, xiz			; value to divide
	lda_dd8l xbc, 0x0A		; divisor = 10
	call HDAE5000_Divide_Unsigned	; XHL = remainder
	add xhl, 0x00000030		; remainder + '0' → ASCII digit
	ld xwa, (xsp + 4)		; get digit write position
	ld (xwa), l			; store digit character
	ld xwa, xiz			; reload value
	lda_dd8l xbc, 0x0A		; divisor = 10
	call HDAE5000_Divide_Signed	; XHL = quotient
	ld xiz, xhl			; update remaining value
	or xiz, xiz			; check if zero
	jr nz, .LInt_To_Dec__loop	; continue if non-zero
	ld xwa, (xsp + 12)		; get end-of-string position
	ldmi8 (xwa), 0x00		; null-terminate
	pop xiz
	inc 4, xsp			; deallocate scratch space
	ret

HDAE5000_UInt_To_Decimal_String:	; 0x29A422 (63 bytes)
	; Convert unsigned 32-bit integer to decimal string
	; Stack: [+0x0C] = output buffer ptr (with write-ahead), [+0x10] = unsigned value
	dec 4, xsp			; allocate local scratch space
	push xiz
	ld xiz, (xsp + 16)		; load unsigned value
.LUInt_To_Dec__loop:
	ld xwa, (xsp + 12)		; get buffer state
	st_dpib a, 0xE0			; lda XBC, (XWA+) — advance write ptr
	ld (xsp + 4), xbc		; save digit write position
	ld (xsp + 12), xwa		; save advanced buffer ptr
	ld xwa, xiz			; value to divide
	lda_dd8l xbc, 0x0A		; divisor = 10
	call HDAE5000_Divide_Unsigned	; XHL = remainder
	add xhl, 0x00000030		; remainder + '0' → ASCII digit
	ld xwa, (xsp + 4)		; get digit write position
	ld (xwa), l			; store digit character
	ld xwa, xiz			; reload value
	lda_dd8l xbc, 0x0A		; divisor = 10
	call HDAE5000_Divide_Signed	; XHL = quotient
	ld xiz, xhl			; update remaining value
	or xiz, xiz			; check if zero
	jr nz, .LUInt_To_Dec__loop	; continue if non-zero
	ld xwa, (xsp + 12)		; get end-of-string position
	ldmi8 (xwa), 0x00		; null-terminate
	pop xiz
	inc 4, xsp			; deallocate scratch space
	ret

HDAE5000_Int_To_Hex_String:	; 0x29A461 (51 bytes)
	; Convert integer to hex string using nibble extraction
	; Stack: [+0x04] = output buffer ptr, [+0x08] = value, [+0x0C] = format char
	; If format char == 'x' (0x78), use lowercase hex digits; else uppercase
	ld xwa, 0x002F94A0		; lowercase hex digit table
	cpmi16 (xsp + 12), 0x0078	; format == 'x'?
	jr nz, .LInt_To_Hex__start
	ld xwa, 0x002F948E		; uppercase hex digit table
.LInt_To_Hex__start:
	ld xix, xwa			; XIX = digit table pointer
	ld xhl, (xsp + 4)		; buffer pointer
	ld xde, (xsp + 8)		; value to convert
.LInt_To_Hex__loop:
	st_dpib a, 0xEC			; lda XBC, (XHL+) — post-increment buffer ptr
	ld xwa, xde
	and xwa, 0x0000000F		; mask low nibble
	add xwa, xix			; index into digit table
	ld a, (xwa)			; get hex digit char
	ld (xbc), a			; store to buffer
	srl xde, 4			; shift to next nibble
	jr nz, .LInt_To_Hex__loop
	ldmi8 (xhl), 0x00		; null-terminate
	ret

HDAE5000_Int_To_Octal_String:	; 0x29A494 (34 bytes)
	; Convert integer to octal string using 3-bit extraction
	; Stack: [+0x04] = output buffer ptr, [+0x08] = value
	ld xde, (xsp + 8)		; value to convert
	ld xhl, (xsp + 4)		; buffer pointer
.LInt_To_Octal__loop:
	st_dpib a, 0xEC			; lda XBC, (XHL+) — post-increment buffer ptr
	ld xwa, xde
	and xwa, 0x00000007		; mask low 3 bits
	add xwa, 0x00000030		; convert to ASCII '0'-'7'
	ld (xbc), a			; store digit
	srl xde, 3			; shift to next octal digit
	jr nz, .LInt_To_Octal__loop
	ldmi8 (xhl), 0x00		; null-terminate
	ret

HDAE5000_String_Format:	; 0x29A4B6 (173 bytes)
	; sprintf-like formatter entry point (handles %e, %E, %f, %g, %d, %u, %x, %o, %s, %c)
	.incbin "includes/code_2971b7_29ae9e.bin", 13055, 173

HDAE5000_String_Format_Core:	; 0x29A563 (805 bytes)
	; Core string format engine - processes format specifiers
	.incbin "includes/code_2971b7_29ae9e.bin", 13228, 805

HDAE5000_String_Format_Output:	; 0x29A888 (848 bytes)
	; Output handler for string formatter
	.incbin "includes/code_2971b7_29ae9e.bin", 14033, 848

HDAE5000_PPI_Block_Copy:	; 0x29ABD8 (237 bytes)
	; PPI block copy/transfer utility
	.incbin "includes/code_2971b7_29ae9e.bin", 14881, 237

HDAE5000_Cell_Copy_Buffer:	; 0x29ACC5 (263 bytes)
	; Cell buffer copy routine (called by Cell_Get_Params)
	.incbin "includes/code_2971b7_29ae9e.bin", 15118, 263

HDAE5000_String_Copy_N:	; 0x29ADCC (64 bytes)
	; String copy with length limit
	; Stack: [+0x0C] dest, [+0x10] source, [+0x14] limit (IZ), [+0x14] flags
	; Uses String_Length to find end, then MemCopy to copy data
	; Returns: XHL = end pointer (or 0 if not found)
	dec 4, xsp			; allocate 4 bytes
	pushw iz
	ld iz, (xsp + 0x14)		; IZ = limit/count
	pushw iz			; arg: count
	pushm (xsp + 0x14)		; arg: search char/flags
	ld xwa, (xsp + 0x12)		; source pointer
	push xwa			; arg: string ptr
	call HDAE5000_String_Length
	inc 0, xsp			; clean up 8 bytes
	ld (xsp + 2), xhl		; save result
	ld xwa, (xsp + 2)		; reload result
	or xwa, xwa			; test if found
	jr nz, .Lscn_found
	pushw iz			; not found: use full limit
	jr t, .Lscn_copy
.Lscn_found:
	ld xwa, (xsp + 2)		; found position
	sub xwa, (xsp + 0x0E)		; subtract source base = length
	inc 1, xwa			; include found byte
	pushw wa			; push 16-bit length
.Lscn_copy:
	ld xwa, (xsp + 0x10)		; dest pointer
	push xwa
	ld xwa, (xsp + 0x10)		; source pointer
	push xwa
	call HDAE5000_MemCopy
	lda xsp, (xsp + 0x0A)		; clean up 10 bytes
	ld xhl, (xsp + 2)		; return saved end pointer
	popw iz
	inc 4, xsp			; deallocate 4 bytes
	ret

HDAE5000_String_Length:	; 0x29AE0C (24 bytes)
	; Find character in string using block search (cpir)
	; Stack: [+0x04] string ptr, [+0x08] search char (WA), [+0x0A] max count (BC)
	; Returns: XHL = pointer past found char, or 0 if not found
	lds32 xhl, 0			; default: not found
	ld bc, (xsp + 0x0A)		; BC = max count
	cps bc, 0
	ret z				; count=0: return 0
	ld xhl, (xsp + 4)		; XHL = string pointer
	ld wa, (xsp + 8)		; WA (low byte = search char)
	cpir83				; search for A in (XHL), decrement BC
	dec 1, xhl			; back up to found position
	ret z				; found: return pointer
	lds32 xhl, 0			; not found: return 0
	ret

HDAE5000_File_Read:	; 0x29AE24 (123 bytes)
	; File read operation (called by Display_Progress)
	.incbin "includes/code_2971b7_29ae9e.bin", 15469, 123

; ----------------------------------------------------------------------------
; Memory Utility Routines (0x29AE9F - 0x29AF2C)
;
; Optimized memory manipulation functions used throughout HDAE5000 firmware.
; All routines take parameters on the stack (C calling convention).
; ----------------------------------------------------------------------------

HDAE5000_MemCopy:	; 29AE9Fh
	; Copy memory block using word operations where possible
	; Stack: [+0x04] = dest (XHL), [+0x08] = src (XIY), [+0x0C] = count (BC)
	; Uses LDIRW for word copies, handles odd byte at start/end
	ld bc, (xsp + 12)	; ld BC, (XSP+0x0C) - count
	ld xhl, (xsp + 4)	; ld XHL, (XSP+0x04) - dest
	cps bc, 0
	ret z	; Return if count = 0
	ld xix, xhl	; XIX = dest
	ld xiy, (xsp + 8)	; ld XIY, (XSP+0x08) - src
	cp xix, xiy
	ret z	; Return if src = dest
	bit 0, ix	; bit 0, IX - check odd alignment
	jr z, HDAE5000_MemCopy__copy_words
	ldi85	; ldi - copy one byte
	ret nov	; ret PO - return if count exhausted
HDAE5000_MemCopy__copy_words:
	srl bc, 1	; srl 1, BC - divide count by 2
	jr z, HDAE5000_MemCopy__check_odd
	mriw2 0x95, 0x11	; ldirw - copy words
HDAE5000_MemCopy__check_odd:
	ret nc	; ret NC - return if no odd byte
	ldi85	; ldi - copy final odd byte
	ret

HDAE5000_MemFill:	; 29AEC7h
	; Fill memory with byte value, optimized for 32-bit writes
	; Stack: [+0x04] = dest (XHL), [+0x08] = value (WA), [+0x0A] = count (BC)
	; Aligns to 4-byte boundary, uses 32-bit writes for bulk fill
	ld bc, (xsp + 10)	; ld BC, (XSP+0x0A) - count
	ld xhl, (xsp + 4)	; ld XHL, (XSP+0x04) - dest
	cps bc, 0
	ret z	; Return if count = 0
	ld xix, xhl	; XIX = dest
	ld wa, (xsp + 8)	; ld WA, (XSP+0x08) - fill value in A
	ld de, ix	; DE = low word of dest address
	neg de	; Negate for alignment calc
	and de, 0x3	; DE = bytes to align (0-3)
	jr z, HDAE5000_MemFill__aligned
HDAE5000_MemFill__align_loop:
	lda_dpi XBC, 0xF0	; ld (XIX+), A - store byte
	sub bc, 0x1	; sub BC, 1 - decrement count
	ret z	; Return if done
	djnz xde, HDAE5000_MemFill__align_loop	; djnz DE, .align_loop
HDAE5000_MemFill__aligned:
	ld de, bc	; Save count for remainder calc
	srl bc, 2	; srl 2, BC - divide by 4
	jr z, HDAE5000_MemFill__remainder
	ld w, a	; W = A (fill byte)
	ldfr_werp WA, 0xE2	; ld QWA, WA - expand to 32-bit
HDAE5000_MemFill__fill_dwords:
	st_dpil XWA, 0xF2	; ld (XIX+), XWA - store 4 bytes
	djnz xbc, HDAE5000_MemFill__fill_dwords	; djnz BC, .fill_dwords
HDAE5000_MemFill__remainder:
	and de, 0x3	; DE = remaining bytes (0-3)
	ret z	; Return if none
HDAE5000_MemFill__fill_bytes:
	lda_dpi XBC, 0xF0	; ld (XIX+), A
	djnz xde, HDAE5000_MemFill__fill_bytes	; djnz DE, .fill_bytes
	ret

HDAE5000_StrCopy:	; 29AF0Bh
	; Copy null-terminated string including terminator
	; Stack: [+0x04] = dest (XDE), [+0x08] = src (XBC)
	; Finds end of dest string, then copies src to that position
	ld xde, (xsp + 4)	; ld XDE, (XSP+0x04) - dest
	ld xhl, xde	; Save original dest
	jr HDAE5000_StrCopy__find_end
HDAE5000_StrCopy__find_loop:
	inc 1, xde	; inc 1, XDE
HDAE5000_StrCopy__find_end:
	cpmi8 (xde), 0x0	; cp (XDE), 0 - check for null
	jr nz, HDAE5000_StrCopy__find_loop
	ld xbc, (xsp + 8)	; ld XBC, (XSP+0x08) - src
	jr HDAE5000_StrCopy__copy_check
HDAE5000_StrCopy__copy_loop:
	ld_spib A, 0xE4	; ld A, (XBC+) - read src byte
	lda_dpi XBC, 0xE8	; ld (XDE+), A - write to dest
HDAE5000_StrCopy__copy_check:
	cpmi8 (xbc), 0x0	; cp (XBC), 0 - check for null
	jr nz, HDAE5000_StrCopy__copy_loop
	ldmi8 (xde), 0x0	; ld (XDE), 0 - write null terminator
	ret

; ----------------------------------------------------------------------------
; Remaining Code and Data (0x29AF2D - 0x2FA134)
; Contains additional utility routines, lookup tables, and data:
;   - String manipulation utilities (strlen, strncpy, etc.)
;   - Memory utilities (compare, search)
;   - Number formatting (itoa, hex conversion)
;   - 32-bit multiply routine (0x29B72D)
;   - UI configuration tables
;   - Graphics/image data
;
; Followed by 24,267 bytes of zero padding (0x2FA135 - 0x2FFFFF)
; ----------------------------------------------------------------------------

HDAE5000_Code_Remainder:	; 29AF2Dh
	; Validate display buffer and read file data
	; Input: (XSP+8) = XIZ context, (XSP+0x12) = XWA file params
	push xiz
	ld xiz, (xsp + 8)		; load context pointer
	push xiz			; arg for Display_Buffer_Validate
	call HDAE5000_Display_Buffer_Validate
	pushw hl			; save validation result
	ld xwa, (xsp + 0x12)		; load file params
	push xwa			; arg 2
	push xiz			; arg 1
	call HDAE5000_File_Read
	lda xsp, (xsp + 0x0E)		; clean up 14 bytes
	pop xiz
	ret

HDAE5000_MemCopy_Block:	; 0x29AF45
	; Block memory copy with null-termination
	; Stack: [+0x10] source ptr, [+0x0C] dest ptr (XIZ context)
	; Calls String_Copy_N with limit 0xFFFE, null-terminates if successful
	; Returns: XHL = dest pointer (XIZ)
	push xiz
	pushw 0xFFFE			; max length
	pushw 0x0000			; flags
	ld xwa, (xsp + 0x10)		; source pointer
	push xwa
	ld xiz, (xsp + 0x10)		; dest pointer
	push xiz
	call HDAE5000_String_Copy_N
	add xsp, 0x0000000C		; clean up 12 bytes
	or xhl, xhl			; test result
	jr nz, .Lmcb_done
	ld xwa, xiz			; get dest pointer
	add xwa, 0x0000FFFF		; point to last byte
	ldmi8 (xwa), 0x00		; null-terminate
.Lmcb_done:
	ld xhl, xiz			; return dest pointer
	pop xiz
	ret

HDAE5000_Display_Buffer_Validate:	; 0x29AF71
	; Validate display buffer - call String_Length, return offset or -1
	; Stack: [+0x0C] = buffer pointer (XIZ)
	; Returns: HL = offset from XIZ or -1 on failure
	push xiz
	pushw 0xFFFF			; sentinel
	pushw 0x0000			; flags
	ld xiz, (xsp + 0x0C)		; buffer pointer
	push xiz
	call HDAE5000_String_Length
	inc 0, xsp			; clean up 8 bytes
	or xhl, xhl			; test result
	jr nz, .Ldbv_ok
	ldw hl, 0xFFFF			; return -1
	jr t, .Ldbv_done
.Ldbv_ok:
	sub xhl, xiz			; HL = length (offset from base)
.Ldbv_done:
	pop xiz
	ret
	; --- String copy with length limit (secondary entry) ---
	; Stack: [+0x04] dest, [+0x08] source, [+0x0C] count
	; Returns: XHL = end of copied string
	ld xix, (xsp + 4)		; XIX = dest
	ld xhl, xix			; XHL = dest (for return)
	jr t, .Lscl_entry
.Lscl_next:
	inc 1, xix
.Lscl_entry:
	cpmi8 (xix), 0x00		; find end of dest string
	jr nz, .Lscl_next
	ld xde, (xsp + 8)		; XDE = source
	ld bc, (xsp + 0x0C)		; BC = count
	jr t, .Lscl_check
.Lscl_copy:
	ld a, (xde)			; load source byte
	ld (xix), a			; store to dest
	cpmi8 (xix), 0x00		; was it null terminator?
	ret z				; yes - done
	inc 1, xix
	inc 1, xde
.Lscl_check:
	ld wa, bc			; save current count
	dec 1, bc			; decrement remaining
	cps wa, 0			; was count zero?
	jr nz, .Lscl_copy		; no - copy next byte
	ldmi8 (xix), 0x00		; null-terminate
	ret

HDAE5000_MemCompare_Block:	; 0x29AFBE
	; Compare two memory blocks byte-by-byte
	; Stack: [+0x04] block A (XIX), [+0x08] block B (XDE), [+0x0C] count (BC)
	; Returns: HL = 0 if match, else sign-extended difference of first mismatch
	ld bc, (xsp + 0x0C)		; BC = count
	ld xde, (xsp + 8)		; XDE = block B
	ld xix, (xsp + 4)		; XIX = block A
	jr t, .Lmcmp_check
.Lmcmp_loop:
	cpmi8 (xix), 0x00		; block A byte is null?
	jr nz, .Lmcmp_advance
	lds hl, 0			; return 0 (match up to null)
	ret
.Lmcmp_advance:
	inc 1, xix
	inc 1, xde
	dec 1, bc
.Lmcmp_check:
	cps bc, 0			; count exhausted?
	jr z, .Lmcmp_result
	ld a, (xde)			; B byte
	cp a, (xix)			; compare with A byte
	jr z, .Lmcmp_loop		; equal - continue
.Lmcmp_result:
	ldb l, 0x00			; default L = 0
	cps bc, 0			; if count exhausted, return 0
	jr z, .Lmcmp_done
	ld a, (xix)			; A byte
	sub a, (xde)			; difference = A - B
	ld l, a
.Lmcmp_done:
	exts hl				; sign-extend L to HL
	ret

HDAE5000_MemCopy_Reverse:	; 0x29AFF0
	; Memory copy (reverse direction)
	.incbin "includes/code_29af2d_2fffff.bin", 195, 1853

HDAE5000_Multiply:	; 0x29B72D
	; 32-bit multiply routine
	.incbin "includes/code_29af2d_2fffff.bin", 2048, 402

HDAE5000_Divide_Unsigned:	; 0x29B8BF (6 bytes)
	; Unsigned 32÷32 divide - calls signed divide then copies result
	calr HDAE5000_Divide_Signed
	ld xhl, xde		; copy quotient from XDE to XHL
	ret

HDAE5000_Divide_Signed:	; 0x29B8C5
	; Signed 32÷32 divide (used by decimal string conversion)
	.incbin "includes/code_29af2d_2fffff.bin", 2456, 1819

HDAE5000_UI_Config:	; 0x29BFE0
	; UI configuration strings
	.asciz "adraw"
	.asciz "auto_inc"
	.byte 0x00
	.asciz "dial"
	.byte 0x00
	.asciz "sel_num"
	.asciz "row"
	.asciz "column"
	.byte 0x00
	.asciz "str_adr"
	.asciz "main_func"
	.asciz "fontcolor"
	.asciz "font"
	.zero 3
	.asciz "fontcolor"
	.asciz "color"
	.zero 6
	.asciz "func"
	.zero 15
	.asciz "infocolor"
	.asciz "infofont"
	.byte 0x00
	.asciz "reversecolor"
	.byte 0x00
	.asciz "fontcolor"
	.asciz "font"
	.byte 0x00
	.asciz "pEnable"
	.zero 2
	.asciz "sel_pos"
	.asciz "sel_num"
	.asciz "dial"
	.byte 0x00

HDAE5000_RECORD_TABLE:	; 0x29C0AA
	; Record/entry data table
	.incbin "includes/code_29af2d_2fffff.bin", 4477, 6356

HDAE5000_RECORD_COUNT:	; 0x29D97E
	; Record count data
	.byte 0x0d
	.byte 0x00
	.asciz "EV_DrawFDText"
	.asciz "EV_InitFDFileSelect"
	.asciz "EV_Scrollline"
	.asciz "EV_Drawsyllable"
	.asciz "EV_Alldraw"
	.byte 0x00
	.asciz "EV_Initlyrics"
	.asciz "EV_SETPOSITION"
	.byte 0x00
	.asciz "EV_BEATMESSAGE"
	.byte 0x00
	.asciz "EV_TICKS"
	.byte 0x00
	.asciz "EV_INITLYRICPARAM"
	.asciz "EV_TimerBack"
	.byte 0x00
	.asciz "EV_AfterLoad"
	.byte 0x00
	.asciz "EV_SeqStop"
	.byte 0x00
	.asciz "MT_FdSaveLyric"
	.byte 0x00
	.asciz "MT_FdLoadLyric"
	.byte 0x00
	.asciz "MT_FdInfo"
	.asciz "MT_FdFreshUp"
	.byte 0x00
	.asciz "MT_SelectDelFile"
	.byte 0x00
	.asciz "MT_SelectDEL"
	.byte 0x00
	.asciz "MT_LOOP"
	.asciz "MT_SetStrAdr"
	.byte 0x00
	.asciz "MT_SelectAll"
	.byte 0x00
	.asciz "MT_SelectSAVE"
	.asciz "MT_SelectOK2"
	.byte 0x00
	.asciz "MT_SelectOK"
	.asciz "MT_AckSelNum"
	.byte 0x00
	.asciz "MT_ReqSelNum"
	.byte 0x00
	.asciz "MT_SetSelNum"
	.byte 0x00
	.asciz "MT_ChangeSelNum"
	.asciz "MT_UnderFlow"
	.byte 0x00
	.asciz "MT_OverFlow"
	.zero 2
	.asciz "FDFileSelectProc"
	.byte 0x00
	.asciz "LyricBoxProc"
	.byte 0x00
	.asciz "AcLanguageText1Proc"
	.asciz "IvScreenR2Proc"
	.byte 0x00
	.asciz "AcWindowPage1Proc"
	.asciz "TtlScreenR3Proc"
	.asciz "TtlScreenR2Proc"
	.asciz "HDTitleMenuProc"
	.asciz "IvHddNamingProc"
	.asciz "AcHddNamingWindowProc"
	.asciz "TtlScreenRProc"
	.byte 0x00
	.asciz "DbMemoClProc"
	.byte 0x00
	.asciz "SelectListProc"
	.byte 0x00
	.byte 0x02
	.byte 0x00

HDAE5000_UI_Descriptors:	; 0x29DC14
	; UI page descriptors and config
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x01
	.byte 0x00
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 3
	.asciz "`"
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xe2, 0x98  ; "â"
	.asciz "#"
	.ascii "<"
	.byte 0xdc  ; "Ü"
	.asciz ")"
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz "HD-AE5000"
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x02
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "H"
	.byte 0x9c  ; ""
	.byte 0x00
	.asciz "a"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0xe6, 0x98  ; "æ"
	.asciz "#"
	.ascii "|"
	.byte 0xdc  ; "Ü"
	.asciz ")"
	.byte 0x13
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x08
	.zero 3
	.asciz "SETUP & TOOLS  "
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.zero 2
	.byte 0x03
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.asciz "r"
	.ascii "7"
	.byte 0x01
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x0a
	.byte 0x00
	.byte 0xe8, 0x98  ; "è"
	.asciz "#"
	.byte 0xc2, 0xdc  ; "ÂÜ"
	.asciz ")"
	.byte 0x8f  ; ""
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0xae  ; "®"
	.byte 0x00
	.zero 4
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x02
	.byte 0x00
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xaa  ; "ª"
	.byte 0x00
	.asciz "r"
	.byte 0x19, 0x01
	.byte 0x91  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x06
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.zero 2
	.byte 0x05
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x0b
	.byte 0x00
	.byte 0xea, 0x98  ; "ê"
	.asciz "#"
	.ascii "$"
	.byte 0xdd  ; "Ý"
	.asciz ")"
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 4
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x04
	.byte 0x00
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xaa  ; "ª"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x07
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.zero 2
	.byte 0x07
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "r"
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x8a  ; ""
	.byte 0x00
	.byte 0xec, 0x98  ; "ì"
	.asciz "#"
	.byte 0x86, 0xdd  ; "Ý"
	.asciz ")"
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "s"
	.zero 4
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x06
	.byte 0x00
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "$"
	.asciz "r"
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x91  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.zero 2
	.byte 0x09
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0xee, 0x98  ; "î"
	.asciz "#"
	.byte 0xe8, 0xdd  ; "èÝ"
	.asciz ")"
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "!"
	.zero 4
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x08
	.byte 0x00
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "$"
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x04
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.zero 2
	.ascii "j"
	.byte 0x01
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x0b
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xbc  ; "¼"
	.byte 0x00
	.byte 0x35
	.byte 0x01
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xf0, 0x98  ; "ð"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0xf4, 0x98  ; "ô"
	.asciz "#"
	.zero 4
	.byte 0xf6, 0x98  ; "ö"
	.asciz "#"
	.zero 2
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x0c
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x16
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x0d
	.byte 0x00
	.byte 0x0b
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.byte 0x4a
	.byte 0x01
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x0e
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "]"
	.byte 0x01
	.byte 0x00
	.asciz "w"
	.byte 0x1b
	.byte 0x00
	.asciz "'"
	.ascii "*"
	.byte 0x01
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.zero 2
	.byte 0x0f
	.byte 0x00
	.byte 0x11
	.byte 0x00
	.byte 0x0d
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.asciz "H"
	.ascii "7"
	.byte 0x01
	.asciz "a"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xf8, 0x98  ; "ø"
	.asciz "#"
	.byte 0xd4, 0xde  ; "ÔÞ"
	.asciz ")"
	.asciz "\""
	.byte 0x7f
	.byte 0x00
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 4
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x0e
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xaa  ; "ª"
	.byte 0x00
	.asciz "H"
	.byte 0x19, 0x01
	.asciz "g"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x05
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x0f
	.byte 0x00
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xaa  ; "ª"
	.byte 0x00
	.asciz "H"
	.byte 0x19, 0x01
	.asciz "g"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x05
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x12
	.byte 0x00
	.byte 0x0e
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.asciz "7"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xfa, 0x98  ; "ú"
	.asciz "#"
	.ascii "`"
	.byte 0xdf  ; "ß"
	.asciz ")"
	.byte 0xf0  ; "ð"
	.byte 0x02, 0x7f
	.byte 0x00
	.asciz "<"
	.zero 4
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.zero 2
	.fill 4, 1, 0xff
	.byte 0x11
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xaa  ; "ª"
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0xe5  ; "å"
	.byte 0x00
	.asciz "="
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x8a, 0xdf  ; "ß"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00

HDAE5000_UI_Page_Titles:	; 0x29DF8A
	; UI page title strings
	.asciz "LYRICS WINDOW"
	.byte 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x14
	.byte 0x00
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x7f
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xfc, 0x98  ; "ü"
	.asciz "#"
	.byte 0xc2, 0xdf  ; "Âß"
	.asciz ")"
	.byte 0x08
	.zero 3
	.asciz " SETUP & TOOLS "
	.asciz "I"
	.ascii "`"
	.byte 0x01, 0x13
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x15
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.byte 0x00
	.asciz "("
	.ascii "`"
	.byte 0x01, 0x13
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x16
	.byte 0x00
	.byte 0x14
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.asciz ">"
	.asciz "="
	.byte 0x02
	.byte 0x00
	.asciz "z"
	.byte 0x7f
	.byte 0x00
	.asciz "("
	.ascii "`"
	.byte 0x01, 0x13
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x17
	.byte 0x00
	.byte 0x15
	.byte 0x00
	.byte 0x18
	.zero 3
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz ">"
	.byte 0x01
	.byte 0x00
	.asciz "n"
	.byte 0x7f
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x13
	.byte 0x00
	.fill 4, 1, 0xff
	.byte 0x16
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x3b
	.byte 0x01, 0x17
	.byte 0x00
	.byte 0xf3  ; "ó"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x00
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x19
	.byte 0x00
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x7f
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x01, 0x02
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "r"
	.byte 0xe0  ; "à"
	.asciz ")"
	.zero 6
	.asciz "I"
	.ascii "`"
	.byte 0x01, 0x18
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x1a
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "\""
	.byte 0x7f
	.byte 0x00
	.asciz "("
	.ascii "`"
	.byte 0x01, 0x18
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x1b
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.byte 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.byte 0x01
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "("
	.ascii "`"
	.byte 0x01, 0x18
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x1c
	.byte 0x00
	.byte 0x1a
	.byte 0x00
	.byte 0x18
	.zero 3
	.asciz "@"
	.byte 0x1f
	.byte 0x00
	.asciz "_"
	.byte 0x02
	.byte 0x00
	.byte 0x10, 0x01, 0x7f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x18
	.byte 0x00
	.byte 0x1d
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "$"
	.ascii "7"
	.byte 0x01
	.asciz "="
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x1c
	.byte 0x00
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.asciz "("
	.ascii "1"
	.byte 0x01
	.asciz ":"
	.byte 0x0e
	.byte 0xe1  ; "á"
	.asciz ")"
	.zero 6
	.asciz "LOAD"
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01, 0x18
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x1f
	.byte 0x00
	.byte 0x1c
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz "("
	.ascii "9"
	.byte 0x01
	.asciz "O"
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "0"
	.ascii "`"
	.byte 0x01, 0x18
	.byte 0x00
	.fill 2, 1, 0xff
	.asciz " "
	.byte 0x1e
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.asciz "M"
	.ascii "?"
	.byte 0x01
	.asciz "]"
	.ascii "V"
	.byte 0xe1  ; "á"
	.asciz ")"
	.zero 4
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x09
	.zero 3
	.ascii " "
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "~80"
	.asciz ")"
	.ascii "`"
	.byte 0x01, 0x18
	.byte 0x00
	.fill 2, 1, 0xff
	.asciz "!"
	.byte 0x1f
	.byte 0x00
	.byte 0x18
	.zero 3
	.asciz "`"
	.byte 0x1f
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x0d
	.byte 0x00
	.byte 0x4a
	.byte 0x01, 0x08
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x18
	.byte 0x00
	.fill 4, 1, 0xff
	.asciz " "
	.byte 0x08
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x3b
	.byte 0x01, 0x17
	.byte 0x00
	.byte 0xf3  ; "ó"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x06
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "#"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x08
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0xc2, 0xe1  ; "Âá"
	.asciz ")"
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.asciz "HD DIR SELECT"
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "$"
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "%"
	.asciz "#"
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x4a
	.byte 0x01
	.zero 2
	.ascii "j"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "&"
	.asciz "$"
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "#"
	.byte 0x07, 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x4a
	.byte 0x01, 0x0c
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x02
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.byte 0x10
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x12
	.byte 0x99  ; ""
	.asciz "#"
	.zero 2
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "'"
	.asciz "%"
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x3e
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "|"
	.byte 0xe2  ; "â"
	.asciz ")"
	.asciz "97-120"
	.byte 0x00
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "("
	.asciz "&"
	.byte 0x08
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.asciz "&"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 7
	.byte 0xb0, 0xe2  ; "°â"
	.asciz ")"
	.asciz "01-24"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz ")"
	.asciz "'"
	.byte 0x08
	.byte 0x00
	.asciz "+"
	.byte 0xde  ; "Þ"
	.byte 0x00
	.asciz "P"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0xe2, 0xe2  ; "ââ"
	.asciz ")"
	.asciz "25-48"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "*"
	.asciz "("
	.byte 0x08
	.byte 0x00
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0x14
	.byte 0xe3  ; "ã"
	.asciz ")"
	.asciz "49-72"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "+"
	.asciz ")"
	.byte 0x08
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x15, 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "F"
	.byte 0xe3  ; "ã"
	.asciz ")"
	.asciz "73-96"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz ","
	.asciz "*"
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "$"
	.ascii "7"
	.byte 0x01
	.asciz "="
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz ","
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0f, 0x01
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x32
	.byte 0x01
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x94, 0xe3  ; "ã"
	.asciz ")"
	.zero 6
	.asciz "EDIT"
	.byte 0x00
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "/"
	.asciz ","
	.byte 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.byte 0x00
	.asciz "0"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "0"
	.asciz "."
	.byte 0x08
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.asciz "M"
	.ascii "?"
	.byte 0x01
	.asciz "_"
	.byte 0xdc, 0xe3  ; "Üã"
	.asciz ")"
	.zero 4
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x09
	.zero 3
	.ascii " "
	.byte 0x01, 0x06
	.byte 0x00
	.asciz "~80"
	.asciz "."
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "/"
	.byte 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz "("
	.ascii "9"
	.byte 0x01
	.asciz "O"
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "2"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x14
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "$"
	.byte 0xe4  ; "ä"
	.asciz ")"
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz " DIRECTORY SELECT   "
	.byte 0x00
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz "1"
	.asciz "3"
	.asciz "4"
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0a, 0x01
	.asciz "&"
	.ascii "7"
	.byte 0x01
	.asciz "="
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x08
	.byte 0x00
	.byte 0x18
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "p"
	.byte 0xe4  ; "ä"
	.asciz ")"
	.byte 0x18
	.byte 0x00
	.byte 0x7f
	.zero 7
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "2"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x16, 0x01
	.asciz "*"
	.ascii ")"
	.byte 0x01
	.asciz "<"
	.byte 0x92, 0xe4  ; "ä"
	.asciz ")"
	.zero 6
	.asciz "OK"
	.byte 0x00
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.asciz "1"
	.byte 0xff
	.byte 0xff
	.asciz "5"
	.asciz "2"
	.byte 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 9
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "1"
	.byte 0xff
	.byte 0xff
	.asciz "6"
	.asciz "4"
	.byte 0x08
	.byte 0x00
	.asciz ","
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz "1"
	.asciz "7"
	.asciz "8"
	.asciz "5"
	.byte 0x08
	.byte 0x00
	.byte 0x0a, 0x01
	.asciz "M"
	.ascii "1"
	.byte 0x01
	.asciz "l"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x09
	.byte 0x00
	.byte 0x1a
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x1e
	.byte 0xe5  ; "å"
	.asciz ")"
	.byte 0x18
	.byte 0x00
	.byte 0x7f
	.zero 7
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "6"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x16, 0x01
	.asciz "*"
	.ascii ")"
	.byte 0x01
	.asciz "<"
	.ascii "@"
	.byte 0xe5  ; "å"
	.asciz ")"
	.zero 6
	.asciz "OK"
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.asciz "1"
	.byte 0xff
	.byte 0xff
	.asciz "9"
	.asciz "6"
	.byte 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz ","
	.ascii "9"
	.byte 0x01
	.asciz "S"
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "1"
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "8"
	.byte 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz ";"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x7f
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x01, 0x1c
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0xb0, 0xe5  ; "°å"
	.asciz ")"
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz " FD FILE SELECT   "
	.byte 0x00
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz ":"
	.asciz "<"
	.asciz "="
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0a, 0x01
	.asciz "&"
	.ascii "7"
	.byte 0x01
	.asciz "="
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x08
	.byte 0x00
	.ascii " "
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0xfa, 0xe5  ; "úå"
	.asciz ")"
	.byte 0x18
	.byte 0x00
	.byte 0x7f
	.zero 7
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz ";"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.asciz ")"
	.ascii "1"
	.byte 0x01
	.asciz ";"
	.byte 0x1c
	.byte 0xe6  ; "æ"
	.asciz ")"
	.zero 6
	.asciz "COPY"
	.byte 0x00
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.asciz ":"
	.byte 0xff
	.byte 0xff
	.asciz ">"
	.asciz ";"
	.byte 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 9
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz ":"
	.byte 0xff
	.byte 0xff
	.asciz "?"
	.asciz "="
	.byte 0x08
	.byte 0x00
	.asciz ","
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz ":"
	.byte 0xff
	.byte 0xff
	.asciz "@"
	.asciz ">"
	.byte 0x08
	.byte 0x00
	.byte 0x0a, 0x01
	.asciz "M"
	.ascii "1"
	.byte 0x01
	.asciz "l"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x09
	.byte 0x00
	.byte 0x22
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0xaa, 0xe6  ; "ªæ"
	.asciz ")"
	.byte 0x18
	.byte 0x00
	.byte 0x7f
	.zero 7
	.asciz "."
	.ascii "`"
	.byte 0x01
	.asciz ":"
	.byte 0xff
	.byte 0xff
	.asciz "A"
	.asciz "?"
	.byte 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz ","
	.ascii "9"
	.byte 0x01
	.asciz "S"
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz ":"
	.byte 0xff
	.byte 0xff
	.asciz "B"
	.asciz "@"
	.byte 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.asciz ":"
	.asciz "C"
	.asciz "D"
	.asciz "A"
	.byte 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "B"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xfe  ; "þ"
	.byte 0x00
	.byte 0xdd  ; "Ý"
	.byte 0x00
	.byte 0x31
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x38
	.byte 0xe7  ; "ç"
	.asciz ")"
	.zero 6
	.asciz "SELECT"
	.zero 3
	.ascii "j"
	.byte 0x01
	.asciz ":"
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "B"
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "4"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xcf  ; "Ï"
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0x01
	.zero 5
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0x24
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x02
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	.byte 0x28
	.byte 0x99  ; ""
	.asciz "#"
	.zero 4
	.ascii "*"
	.byte 0x99  ; ""
	.asciz "#"
	.zero 2
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "F"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x2c
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0xa6, 0xe7  ; "¦ç"
	.asciz ")"
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz "HARDWARE TEST"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.asciz "E"
	.asciz "G"
	.asciz "H"
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.asciz "F"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.ascii "*"
	.byte 0x01
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.asciz "E"
	.byte 0xff
	.byte 0xff
	.asciz "I"
	.asciz "F"
	.byte 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.byte 0x00
	.asciz "&"
	.ascii "`"
	.byte 0x01
	.asciz "E"
	.byte 0xff
	.byte 0xff
	.asciz "J"
	.asciz "H"
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xdb  ; "Û"
	.byte 0x00
	.zero 4
	.ascii "."
	.byte 0xe8  ; "è"
	.asciz ")"
	.ascii "*"
	.byte 0xe8  ; "è"
	.asciz ")"
	.ascii "0"
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x0c
	.byte 0x00
	.asciz "RUN"
	.asciz "STOP"
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.asciz "E"
	.byte 0xff
	.byte 0xff
	.asciz "K"
	.asciz "I"
	.byte 0x08
	.zero 3
	.asciz " "
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.zero 2
	.byte 0xff
	.byte 0x00
	.asciz "&"
	.ascii "`"
	.byte 0x01
	.asciz "E"
	.byte 0xff
	.byte 0xff
	.asciz "L"
	.asciz "J"
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "L"
	.ascii "7"
	.byte 0x01
	.asciz "]"
	.zero 4
	.ascii "|"
	.byte 0xe8  ; "è"
	.asciz ")"
	.ascii "v"
	.byte 0xe8  ; "è"
	.asciz ")"
	.ascii "2"
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x09
	.byte 0x00
	.asciz "PPORT"
	.asciz "PPORT"
	.asciz "&"
	.ascii "`"
	.byte 0x01
	.asciz "E"
	.byte 0xff
	.byte 0xff
	.asciz "M"
	.asciz "K"
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.zero 4
	.byte 0xae, 0xe8  ; "®è"
	.asciz ")"
	.byte 0xaa, 0xe8  ; "ªè"
	.asciz ")"
	.ascii "4"
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x0b
	.byte 0x00
	.asciz "FD"
	.byte 0x00
	.asciz "FD"
	.byte 0x00
	.asciz "&"
	.ascii "`"
	.byte 0x01
	.asciz "E"
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "L"
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.asciz "v"
	.ascii "7"
	.byte 0x01
	.byte 0x87  ; ""
	.byte 0x00
	.zero 4
	.byte 0xde, 0xe8  ; "Þè"
	.asciz ")"
	.byte 0xda, 0xe8  ; "Úè"
	.asciz ")"
	.ascii "6"
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x0a
	.byte 0x00
	.asciz "HDD"
	.asciz "HDD"
	.byte 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "O"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x7f
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x38
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x0c
	.byte 0xe9  ; "é"
	.asciz ")"
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.asciz "EDIT FILE NAME"
	.byte 0x00
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.asciz "N"
	.byte 0xff
	.byte 0xff
	.asciz "P"
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x4a
	.byte 0x01
	.asciz " "
	.ascii "`"
	.byte 0x01
	.asciz "N"
	.byte 0xff
	.byte 0xff
	.asciz "Q"
	.asciz "O"
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0b
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.asciz "N"
	.byte 0xff
	.byte 0xff
	.asciz "R"
	.asciz "P"
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz " "
	.ascii "`"
	.byte 0x01
	.asciz "N"
	.asciz "S"
	.asciz "T"
	.asciz "Q"
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.asciz "v"
	.ascii "7"
	.byte 0x01
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0a
	.zero 3
	.byte 0x01
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "R"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a, 0x01
	.asciz "w"
	.ascii "5"
	.byte 0x01
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0xc8, 0xe9  ; "Èé"
	.asciz ")"
	.zero 6
	.asciz "OPT"
	.byte 0x04
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.asciz "N"
	.byte 0xff
	.byte 0xff
	.asciz "U"
	.asciz "R"
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.asciz " "
	.ascii "`"
	.byte 0x01
	.asciz "N"
	.asciz "V"
	.byte 0xff
	.byte 0xff
	.asciz "T"
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "v"
	.asciz "&"
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x8a  ; ""
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "U"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.asciz "w"
	.asciz "$"
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x32
	.byte 0xea  ; "ê"
	.asciz ")"
	.zero 4
	.byte 0xf9  ; "ù"
	.byte 0x00
	.asciz "LST"
	.asciz "K"
	.ascii "`"
	.byte 0x01
	.fill 8, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "`"
	.byte 0x0b, 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.ascii "<"
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "@"
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "Y"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x7f
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x44
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x84, 0xea  ; "ê"
	.asciz ")"
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.asciz "EDIT DIRECTORY NAME"
	.asciz "M"
	.ascii "`"
	.byte 0x01
	.asciz "X"
	.byte 0xff
	.byte 0xff
	.asciz "Z"
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.asciz " "
	.ascii "`"
	.byte 0x01
	.asciz "X"
	.byte 0xff
	.byte 0xff
	.asciz "["
	.asciz "Y"
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0b
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.asciz "X"
	.byte 0xff
	.byte 0xff
	.asciz "\\"
	.asciz "Z"
	.byte 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.asciz "\""
	.byte 0x7f
	.byte 0x00
	.asciz " "
	.ascii "`"
	.byte 0x01
	.asciz "X"
	.asciz "]"
	.byte 0xff
	.byte 0xff
	.asciz "["
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "v"
	.asciz "&"
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x8a  ; ""
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "\\"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.asciz "w"
	.asciz "$"
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x44
	.byte 0xeb  ; "ë"
	.asciz ")"
	.zero 4
	.byte 0xf9  ; "ù"
	.byte 0x00
	.asciz "LST"
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "_"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "<"
	.asciz "T"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.ascii "H"
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "L"
	.byte 0x99  ; ""
	.asciz "#"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "^"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "n"
	.asciz "b"
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.asciz "t"
	.byte 0x8c, 0xeb  ; "ë"
	.asciz ")"
	.zero 6
	.asciz "PLEASE WAIT!"
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "a"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x50
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0xc4, 0xeb  ; "Äë"
	.asciz ")"
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz "HD UTILITY"
	.byte 0x00
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.asciz "`"
	.byte 0xff
	.byte 0xff
	.asciz "b"
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.byte 0x00
	.byte 0x13
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.asciz "`"
	.byte 0xff
	.byte 0xff
	.asciz "c"
	.asciz "a"
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.asciz "F"
	.ascii "`"
	.byte 0x01
	.asciz "`"
	.byte 0xff
	.byte 0xff
	.asciz "d"
	.asciz "b"
	.byte 0x08
	.zero 3
	.asciz " "
	.byte 0xaa  ; "ª"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.asciz "="
	.ascii "`"
	.byte 0x01
	.asciz "`"
	.byte 0xff
	.byte 0xff
	.asciz "e"
	.asciz "c"
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.asciz "H"
	.ascii "7"
	.byte 0x01
	.asciz "a"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x09
	.byte 0x00
	.byte 0x54
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "L"
	.byte 0xec  ; "ì"
	.asciz ")"
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz "FORMAT"
	.byte 0x00
	.asciz "="
	.ascii "`"
	.byte 0x01
	.asciz "`"
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "d"
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x0b
	.byte 0x00
	.byte 0x56
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x86, 0xec  ; "ì"
	.asciz ")"
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz "READ ID"
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "g"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x58
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0xb8, 0xec  ; "¸ì"
	.asciz ")"
	.zero 4
	.asciz "   PC DATA LINK"
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.asciz "f"
	.byte 0xff
	.byte 0xff
	.asciz "h"
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.zero 2
	.ascii "j"
	.byte 0x01
	.asciz "f"
	.byte 0xff
	.byte 0xff
	.asciz "i"
	.asciz "g"
	.byte 0x08
	.byte 0x00
	.byte 0x14
	.byte 0x00
	.asciz "T"
	.ascii "+"
	.byte 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0x5c
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x60
	.byte 0x99  ; ""
	.asciz "#"
	.zero 4
	.ascii "b"
	.byte 0x99  ; ""
	.asciz "#"
	.zero 2
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.asciz "f"
	.asciz "j"
	.asciz "k"
	.asciz "h"
	.byte 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "i"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xfe  ; "þ"
	.byte 0x00
	.byte 0xdb  ; "Û"
	.byte 0x00
	.byte 0x31
	.byte 0x01
	.byte 0xed  ; "í"
	.byte 0x00
	.ascii "h"
	.byte 0xed  ; "í"
	.asciz ")"
	.zero 6
	.asciz "CANCEL"
	.byte 0x00
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.asciz "f"
	.asciz "l"
	.asciz "m"
	.asciz "i"
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "k"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x12
	.byte 0x00
	.byte 0xdb  ; "Û"
	.byte 0x00
	.asciz "="
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0xba, 0xed  ; "ºí"
	.asciz ")"
	.zero 6
	.asciz "START"
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.asciz "f"
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "k"
	.byte 0x08
	.byte 0x00
	.asciz "L"
	.byte 0x01
	.byte 0x00
	.asciz "f"
	.byte 0x1b
	.byte 0x00
	.asciz "'"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "o"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "@"
	.asciz "Z"
	.byte 0x1a, 0x01
	.byte 0xbd  ; "½"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 4
	.ascii "d"
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "h"
	.byte 0x99  ; ""
	.asciz "#"
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz "n"
	.asciz "p"
	.asciz "q"
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x0b
	.byte 0x00
	.ascii "l"
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "4"
	.byte 0xee  ; "î"
	.asciz ")"
	.asciz "f"
	.byte 0x7f
	.byte 0x00
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz "PC DATA LINK"
	.byte 0x00
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.asciz "o"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1b, 0x01
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0x35
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.asciz "'"
	.ascii "*"
	.byte 0x01
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.asciz "n"
	.byte 0xff
	.byte 0xff
	.asciz "r"
	.asciz "o"
	.byte 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "n"
	.asciz "s"
	.asciz "t"
	.asciz "q"
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "H"
	.byte 0xa3  ; "£"
	.byte 0x00
	.asciz "a"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.byte 0xc0, 0xee  ; "Àî"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.ascii "n"
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x11
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.ascii "p"
	.byte 0x99  ; ""
	.asciz "#"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.asciz "r"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "H"
	.byte 0x80  ; ""
	.byte 0x00
	.asciz "g"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x08
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "n"
	.byte 0xff
	.byte 0xff
	.asciz "u"
	.asciz "r"
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.ascii "&"
	.byte 0xef  ; "ï"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.ascii "t"
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x13
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.ascii "v"
	.byte 0x99  ; ""
	.asciz "#"
	.asciz "QUICK LD MODE:"
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "n"
	.byte 0xff
	.byte 0xff
	.asciz "v"
	.asciz "t"
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.asciz "H"
	.ascii "7"
	.byte 0x01
	.asciz "a"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.ascii "p"
	.byte 0xef  ; "ï"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.ascii "z"
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x15
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.byte 0x7c
	.byte 0x99  ; ""
	.asciz "#"
	.asciz "JUMP AFTER LD.:"
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "n"
	.asciz "w"
	.asciz "x"
	.asciz "u"
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "r"
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.byte 0xba, 0xef  ; "ºï"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x8a  ; ""
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x80, 0x99  ; ""
	.asciz "#"
	.byte 0x12
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.byte 0x82, 0x99  ; ""
	.asciz "#"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.asciz "v"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "r"
	.byte 0x80  ; ""
	.byte 0x00
	.byte 0x91  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x09
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "n"
	.byte 0xff
	.byte 0xff
	.asciz "y"
	.asciz "v"
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0xdf  ; "ß"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.ascii " "
	.byte 0xf0  ; "ð"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x8c  ; ""
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x86, 0x99  ; ""
	.asciz "#"
	.byte 0x14
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.byte 0x88, 0x99  ; ""
	.asciz "#"
	.asciz "LD BY NUM. M.:"
	.byte 0x00
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz "n"
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "x"
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.asciz "r"
	.ascii "7"
	.byte 0x01
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x0a
	.byte 0x00
	.byte 0x8c, 0x99  ; ""
	.asciz "#"
	.ascii "f"
	.byte 0xf0  ; "ð"
	.asciz ")"
	.byte 0x0c, 0x03, 0x7f
	.byte 0x00
	.asciz "<"
	.zero 2
	.asciz "LYRICS OPTIONS"
	.byte 0x00
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "{"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "<"
	.asciz "T"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 4
	.byte 0x8e, 0x99  ; ""
	.asciz "#"
	.byte 0x92, 0x99  ; ""
	.asciz "#"
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz "z"
	.asciz "|"
	.asciz "}"
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0xdf  ; "ß"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x8c  ; ""
	.byte 0x00
	.byte 0x96, 0x99  ; ""
	.asciz "#"
	.byte 0xd0, 0xf0  ; "Ðð"
	.asciz ")"
	.byte 0xff
	.fill 3, 1, 0xff
	.zero 6
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.asciz "{"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0xe5  ; "å"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x0b
	.zero 9
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz "z"
	.asciz "~"
	.byte 0x7f
	.byte 0x00
	.asciz "{"
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xdf  ; "ß"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x0c
	.byte 0x00
	.byte 0x98, 0x99  ; ""
	.asciz "#"
	.ascii "2"
	.byte 0xf1  ; "ñ"
	.asciz ")"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x01
	.zero 3
	.asciz "HD-AE INFOS  "
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.asciz "}"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1b, 0x01
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0x35
	.byte 0x01
	.byte 0xdf  ; "ß"
	.byte 0x00
	.asciz "'"
	.ascii "*"
	.byte 0x01
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.asciz "z"
	.byte 0xff
	.byte 0xff
	.byte 0x80  ; ""
	.byte 0x00
	.asciz "}"
	.byte 0x18
	.zero 3
	.asciz "@"
	.byte 0x1f
	.byte 0x00
	.asciz "_"
	.byte 0x04
	.byte 0x00
	.byte 0x4a
	.byte 0x01
	.asciz "! HD FORMAT !"
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.byte 0x80  ; ""
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1b, 0x01
	.asciz "G"
	.ascii "5"
	.byte 0x01
	.asciz "a"
	.asciz "'"
	.ascii "*"
	.byte 0x01
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz "z"
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x80  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x0b
	.byte 0x00
	.byte 0x9c, 0x99  ; ""
	.asciz "#"
	.byte 0xd2, 0xf1  ; "Òñ"
	.asciz ")"
	.byte 0x81  ; ""
	.byte 0x02, 0x7f
	.byte 0x00
	.byte 0x01
	.zero 5
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x84  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1b, 0x01
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0x35
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.asciz "'"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa9  ; "©"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x25
	.byte 0x01
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x0a
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x86  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x9e, 0x99  ; ""
	.asciz "#"
	.ascii "B"
	.byte 0xf2  ; "ò"
	.asciz ")"
	.asciz "!"
	.zero 2
	.asciz "OUTPUT SETTING"
	.byte 0x00
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.byte 0x00
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0x86  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.asciz "H"
	.ascii "7"
	.byte 0x01
	.asciz "a"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.byte 0xd0, 0xf2  ; "Ðò"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xa2, 0x99  ; "¢"
	.asciz "#"
	.byte 0x05
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.byte 0xa4, 0x99  ; "¤"
	.asciz "#"
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x8a  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.asciz "r"
	.ascii "7"
	.byte 0x01
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.byte 0x0c
	.byte 0xf3  ; "ó"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x8a  ; ""
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xa8, 0x99  ; "¨"
	.asciz "#"
	.asciz "<"
	.ascii "*"
	.byte 0x01
	.byte 0xaa, 0x99  ; "ª"
	.asciz "#"
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.ascii "H"
	.byte 0xf3  ; "ó"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xae, 0x99  ; "®"
	.asciz "#"
	.asciz "="
	.ascii "*"
	.byte 0x01
	.byte 0xb0, 0x99  ; "°"
	.asciz "#"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x8c  ; ""
	.byte 0x00
	.byte 0x8a  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.asciz "H"
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "g"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x0d
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x8d  ; ""
	.byte 0x00
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.asciz "r"
	.byte 0x07, 0x01
	.byte 0x91  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x0e
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x8e  ; ""
	.byte 0x00
	.byte 0x8c  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x07, 0x01
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x0f
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x8d  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0xb8  ; "¸"
	.byte 0x00
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x10
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xf1  ; "ñ"
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x90  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xb4, 0x99  ; "´"
	.asciz "#"
	.byte 0x1c
	.byte 0xf4  ; "ô"
	.asciz ")"
	.byte 0xae  ; "®"
	.byte 0x00
	.zero 2
	.asciz "LOAD BY NUMBER"
	.byte 0x00
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x91  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.byte 0x00
	.asciz "("
	.ascii "`"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x92  ; ""
	.byte 0x00
	.byte 0x90  ; ""
	.byte 0x00
	.byte 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.byte 0x01
	.byte 0x00
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "("
	.ascii "`"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x93  ; ""
	.byte 0x00
	.byte 0x91  ; ""
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.asciz " "
	.asciz " "
	.asciz "?"
	.asciz "?"
	.byte 0x02
	.byte 0x00
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x94  ; ""
	.byte 0x00
	.byte 0x92  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x3b
	.byte 0x01, 0x17
	.byte 0x00
	.byte 0xf3  ; "ó"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb8, 0x99  ; "¸"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x93  ; ""
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.asciz "@"
	.asciz " "
	.asciz "_"
	.asciz "?"
	.asciz ")"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x96  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "<"
	.asciz "T"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 4
	.byte 0xba, 0x99  ; "º"
	.asciz "#"
	.byte 0xbe, 0x99  ; "¾"
	.asciz "#"
	.byte 0x1c
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0x98  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x07, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0c
	.byte 0x00
	.byte 0xc2, 0x99  ; "Â"
	.asciz "#"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x96  ; ""
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0x34
	.byte 0x01
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x2a
	.byte 0xf5  ; "õ"
	.asciz ")"
	.zero 6
	.asciz "CLEAR"
	.zero 2
	.ascii "j"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0x96  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.asciz "["
	.ascii "?"
	.byte 0x01
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xc4, 0x99  ; "Ä"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xc8, 0x99  ; "È"
	.asciz "#"
	.zero 4
	.byte 0xca, 0x99  ; "Ê"
	.asciz "#"
	.zero 2
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0x9a  ; ""
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0x98  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "$"
	.ascii "7"
	.byte 0x01
	.asciz "="
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.asciz ")"
	.ascii "1"
	.byte 0x01
	.asciz ";"
	.byte 0xb4, 0xf5  ; "´õ"
	.asciz ")"
	.zero 6
	.asciz "LOAD"
	.byte 0x00
	.asciz "0"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.asciz "M"
	.ascii "?"
	.byte 0x01
	.asciz "]"
	.byte 0xe2, 0xf5  ; "âõ"
	.asciz ")"
	.zero 4
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x09
	.zero 3
	.ascii " "
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "~80"
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz "("
	.ascii "9"
	.byte 0x01
	.asciz "O"
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0x9e  ; ""
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xae  ; "®"
	.byte 0x00
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x28
	.byte 0xf6  ; "ö"
	.asciz ")"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.zero 3
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x9f  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.asciz "\""
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x50
	.byte 0xf6  ; "ö"
	.asciz ")"
	.zero 8
	.asciz "0"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x9e  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xb3  ; "³"
	.byte 0x00
	.asciz "\""
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.ascii "x"
	.byte 0xf6  ; "ö"
	.asciz ")"
	.zero 8
	.asciz "1"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa1  ; "¡"
	.byte 0x00
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "0"
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.asciz "J"
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xa0, 0xf6  ; " ö"
	.asciz ")"
	.zero 8
	.asciz "2"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "0"
	.byte 0xb3  ; "³"
	.byte 0x00
	.asciz "J"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xc8, 0xf6  ; "Èö"
	.asciz ")"
	.zero 8
	.asciz "3"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0xa1  ; "¡"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "X"
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.asciz "r"
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xf0, 0xf6  ; "ðö"
	.asciz ")"
	.zero 8
	.asciz "4"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "X"
	.byte 0xb3  ; "³"
	.byte 0x00
	.asciz "r"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x18
	.byte 0xf7  ; "÷"
	.asciz ")"
	.zero 8
	.asciz "5"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa5  ; "¥"
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x80  ; ""
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x9a  ; ""
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x40
	.byte 0xf7  ; "÷"
	.asciz ")"
	.zero 8
	.asciz "6"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x80  ; ""
	.byte 0x00
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0x9a  ; ""
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.ascii "h"
	.byte 0xf7  ; "÷"
	.asciz ")"
	.zero 8
	.asciz "7"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa7  ; "§"
	.byte 0x00
	.byte 0xa5  ; "¥"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa8  ; "¨"
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xc2  ; "Â"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x90, 0xf7  ; "÷"
	.asciz ")"
	.zero 8
	.asciz "8"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa8  ; "¨"
	.byte 0x00
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa8  ; "¨"
	.byte 0x00
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0xc2  ; "Â"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xb8, 0xf7  ; "¸÷"
	.asciz ")"
	.zero 8
	.asciz "9"
	.zero 2
	.ascii "j"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa9  ; "©"
	.byte 0x00
	.byte 0xa7  ; "§"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.asciz "-"
	.asciz "#"
	.asciz "B"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.zero 4
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xcc, 0x99  ; "Ì"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xd0, 0x99  ; "Ð"
	.asciz "#"
	.zero 4
	.byte 0xd2, 0x99  ; "Ò"
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xaa  ; "ª"
	.byte 0x00
	.byte 0xa8  ; "¨"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "\""
	.asciz "-"
	.byte 0xf9  ; "ù"
	.byte 0x00
	.asciz "B"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.zero 4
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xd4, 0x99  ; "Ô"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xd8, 0x99  ; "Ø"
	.asciz "#"
	.zero 4
	.byte 0xda, 0x99  ; "Ú"
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xab  ; "«"
	.byte 0x00
	.byte 0xa9  ; "©"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.asciz "D"
	.asciz "#"
	.asciz "Y"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.zero 4
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xdc, 0x99  ; "Ü"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xe0, 0x99  ; "à"
	.asciz "#"
	.zero 4
	.byte 0xe2, 0x99  ; "â"
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xac  ; "¬"
	.byte 0x00
	.byte 0xaa  ; "ª"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "\""
	.asciz "D"
	.byte 0xf9  ; "ù"
	.byte 0x00
	.asciz "Y"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.zero 4
	.byte 0xf2  ; "ò"
	.byte 0x00
	.zero 2
	.ascii "@"
	.byte 0x01
	.byte 0xe4, 0x99  ; "ä"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xe8, 0x99  ; "è"
	.asciz "#"
	.zero 4
	.byte 0xea, 0x99  ; "ê"
	.asciz "#"
	.zero 2
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xad  ; "­"
	.byte 0x00
	.byte 0xab  ; "«"
	.byte 0x00
	.byte 0x18
	.zero 3
	.asciz "`"
	.byte 0x1f
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "("
	.ascii "*"
	.byte 0x01
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xae  ; "®"
	.byte 0x00
	.byte 0xac  ; "¬"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xdd  ; "Ý"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x05
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0xad  ; "­"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.asciz "t"
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0xa9  ; "©"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x15
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xf1  ; "ñ"
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xb0  ; "°"
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "h"
	.byte 0x1f
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 4
	.byte 0xec, 0x99  ; "ì"
	.asciz "#"
	.byte 0xf0, 0x99  ; "ð"
	.asciz "#"
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "/"
	.byte 0x07, 0x01
	.asciz "H"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.ascii "v"
	.byte 0xf9  ; "ù"
	.asciz ")"
	.byte 0x05
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xf4, 0x99  ; "ô"
	.asciz "#"
	.asciz "*"
	.ascii "*"
	.byte 0x01
	.byte 0xf6, 0x99  ; "ö"
	.asciz "#"
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb2  ; "²"
	.byte 0x00
	.byte 0xb0  ; "°"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "0"
	.asciz "L"
	.byte 0x03, 0x01
	.asciz "["
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.byte 0xb2, 0xf9  ; "²ù"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xfa, 0x99  ; "ú"
	.asciz "#"
	.asciz "+"
	.ascii "*"
	.byte 0x01
	.byte 0xfc, 0x99  ; "ü"
	.asciz "#"

HDAE5000_Panel_Save_UI:	; 0x29F9B2
	; Panel memory save/load UI strings
	.asciz "CURRENT PANEL          "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0xb4  ; "´"
	.byte 0x00
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "0"
	.asciz "["
	.byte 0x03, 0x01
	.asciz "j"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0xfa  ; "ú"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 4
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz ","
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "PANEL MEMORY           "
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xb2  ; "²"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "J"
	.asciz "("
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xb2  ; "²"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "0"
	.asciz "j"
	.byte 0x03, 0x01
	.asciz "y"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x03
	.byte 0x00
	.ascii "p"
	.byte 0xfa  ; "ú"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x06
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "-"
	.ascii "*"
	.byte 0x01, 0x08
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "SEQUENCER              "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb6  ; "¶"
	.byte 0x00
	.byte 0xb4  ; "´"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "0"
	.asciz "y"
	.byte 0x03, 0x01
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x04
	.byte 0x00
	.byte 0xc2, 0xfa  ; "Âú"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x0c
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "."
	.ascii "*"
	.byte 0x01, 0x0e
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "COMPOSER               "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb7  ; "·"
	.byte 0x00
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "0"
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x05
	.byte 0x00
	.byte 0x14
	.byte 0xfb  ; "û"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "/"
	.ascii "*"
	.byte 0x01, 0x14
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "SOUND MEMORY           "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb8  ; "¸"
	.byte 0x00
	.byte 0xb6  ; "¶"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "0"
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x06
	.byte 0x00
	.ascii "f"
	.byte 0xfb  ; "û"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x18
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "0"
	.ascii "*"
	.byte 0x01, 0x1a
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "MSP                    "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb9  ; "¹"
	.byte 0x00
	.byte 0xb7  ; "·"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "0"
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x07
	.byte 0x00
	.byte 0xb8, 0xfb  ; "¸û"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x1e
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "1"
	.ascii "*"
	.byte 0x01
	.ascii " "
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "RHYTHM CUSTOM          "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xba  ; "º"
	.byte 0x00
	.byte 0xb8  ; "¸"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "0"
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0xc4  ; "Ä"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x08
	.byte 0x00
	.byte 0x0a
	.byte 0xfc  ; "ü"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "$"
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "2"
	.ascii "*"
	.byte 0x01
	.byte 0x26
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "USER MIDI SETTINGS     "
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0xb9  ; "¹"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "J"
	.byte 0x07, 0x01
	.asciz "J"
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xbc  ; "¼"
	.byte 0x00
	.byte 0xba  ; "º"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x07, 0x01
	.asciz "J"
	.byte 0x07, 0x01
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xbd  ; "½"
	.byte 0x00
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "("
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x07, 0x01
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xbe  ; "¾"
	.byte 0x00
	.byte 0xbc  ; "¼"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "#"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 11
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xbf  ; "¿"
	.byte 0x00
	.byte 0xbd  ; "½"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz ","
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xbe  ; "¾"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "s"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x02
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xbf  ; "¿"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "|"
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x03
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc2  ; "Â"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x05
	.zero 9
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x07
	.zero 9
	.byte 0x06
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc4  ; "Ä"
	.byte 0x00
	.byte 0xc2  ; "Â"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x1c, 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x08
	.zero 9
	.byte 0x07
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x06
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xc4  ; "Ä"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xd0, 0xfd  ; "Ðý"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "PNL"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "*"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.asciz "K"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xf4, 0xfd  ; "ôý"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "P.MEM"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc8  ; "È"
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "X"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.asciz "m"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x1a
	.byte 0xfe  ; "þ"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "SEQ"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "~"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x3e
	.byte 0xfe  ; "þ"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "COMP"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xc8  ; "È"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.ascii "d"
	.byte 0xfe  ; "þ"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "SOUND"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x8a, 0xfe  ; "þ"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "MSP"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x16, 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xae, 0xfe  ; "®þ"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "CUSTOM"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x1e, 0x01
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xd6, 0xfe  ; "Öþ"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "MIDI"
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xce  ; "Î"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.asciz "J"
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xcf  ; "Ï"
	.byte 0x00
	.byte 0xd0  ; "Ð"
	.byte 0x00
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "$"
	.ascii "7"
	.byte 0x01
	.asciz "="
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xce  ; "Î"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.asciz ")"
	.ascii "1"
	.byte 0x01
	.asciz ";"
	.ascii ">"
	.byte 0xff
	.asciz ")"
	.zero 6
	.asciz "LOAD"
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xce  ; "Î"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz "("
	.ascii "9"
	.byte 0x01
	.asciz "O"
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "0"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0xd0  ; "Ð"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.asciz "M"
	.ascii "?"
	.byte 0x01
	.asciz "]"
	.byte 0x86  ; ""
	.byte 0xff
	.asciz ")"
	.zero 4
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x09
	.zero 3
	.ascii " "
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "~80"
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x2a
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0xb4  ; "´"
	.byte 0xff
	.asciz ")"
	.asciz "s"
	.zero 2
	.asciz "COPY TECH TO HD"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xd5  ; "Õ"
	.byte 0x00
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz ","
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0xd5  ; "Õ"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz ":"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 8
	.byte 0x0a
	.byte 0x00
	.byte 0x4a
	.byte 0x01
	.byte 0x2e
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x02
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	.byte 0x32
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x34
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xd9  ; "Ù"
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.asciz "<"
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xda  ; "Ú"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "v"
	.asciz "<"
	.asciz "v"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xda  ; "Ú"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x10, 0x01
	.asciz "#"
	.ascii "3"
	.byte 0x01
	.asciz "5"
	.byte 0xe8  ; "è"
	.byte 0x00
	.asciz "*"
	.zero 6
	.asciz "* TO"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0b, 0x01
	.byte 0xcf  ; "Ï"
	.byte 0x00
	.byte 0x32
	.byte 0x01
	.byte 0xd9  ; "Ù"
	.byte 0x00
	.byte 0x0e, 0x01
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "SELECT"
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xdf  ; "ß"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x8e  ; ""
	.byte 0x00
	.asciz "&"
	.byte 0xeb  ; "ë"
	.byte 0x00
	.asciz "5"
	.byte 0x07
	.zero 3
	.asciz "d"
	.zero 4
	.byte 0xf2  ; "ò"
	.byte 0x00
	.zero 2
	.ascii "@"
	.byte 0x01
	.byte 0x36
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x3a
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 4
	.ascii "<"
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 2
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "$"
	.byte 0xef  ; "ï"
	.byte 0x00
	.asciz "7"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.ascii "x"
	.byte 0x01
	.asciz "*"
	.zero 6
	.byte 0x01
	.byte 0x00
	.asciz "StringBox"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08, 0x01
	.byte 0xa5  ; "¥"
	.byte 0x00
	.byte 0x35
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x01
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "SEL ALL"
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xe3  ; "ã"
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x3e
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0xd4  ; "Ô"
	.byte 0x01
	.asciz "*"
	.asciz "s"
	.zero 2
	.asciz "HD DIR SELECT"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xe4  ; "ä"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xe5  ; "å"
	.byte 0x00
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0xe3  ; "ã"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0d, 0x01, 0x1e
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.asciz "7"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xe4  ; "ä"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x10, 0x01
	.asciz "#"
	.ascii "3"
	.byte 0x01
	.asciz "5"
	.ascii "D"
	.byte 0x02
	.asciz "*"
	.zero 6
	.asciz "COPY"
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xe7  ; "ç"
	.byte 0x00
	.byte 0xe4  ; "ä"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "#"
	.byte 0x07, 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x0b
	.byte 0x00
	.byte 0x4a
	.byte 0x01
	.byte 0x42
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x02
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.byte 0x46
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x48
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 2
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xe8  ; "è"
	.byte 0x00
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.asciz "&"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 7
	.byte 0xb2  ; "²"
	.byte 0x02
	.asciz "*"
	.asciz "01-24"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xe9  ; "é"
	.byte 0x00
	.byte 0xe7  ; "ç"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "+"
	.byte 0xde  ; "Þ"
	.byte 0x00
	.asciz "P"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0xe4  ; "ä"
	.byte 0x02
	.asciz "*"
	.asciz "25-48"
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xea  ; "ê"
	.byte 0x00
	.byte 0xe8  ; "è"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xe9  ; "é"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "@"
	.byte 0x03
	.asciz "*"
	.asciz "49-72"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xea  ; "ê"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x15, 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "r"
	.byte 0x03
	.asciz "*"
	.asciz "73-96"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x3e
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0xa4  ; "¤"
	.byte 0x03
	.asciz "*"
	.asciz "97-120"
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0d, 0x01
	.byte 0xc2  ; "Â"
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xdb  ; "Û"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x0c
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x11, 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0x34
	.byte 0x01
	.byte 0xd9  ; "Ù"
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x03
	.asciz "*"
	.zero 6
	.asciz "EDIT"
	.byte 0x00
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.byte 0x00
	.byte 0x0b
	.byte 0x00
	.byte 0x4a
	.byte 0x01, 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xf1  ; "ñ"
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x4a
	.byte 0x9a  ; ""
	.asciz "#"
	.ascii ">"
	.byte 0x04
	.asciz "*"
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 2
	.asciz " F.L.S. SELECT"
	.byte 0x00
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.byte 0x00
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf3  ; "ó"
	.byte 0x00
	.byte 0xf1  ; "ñ"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.asciz "&"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 7
	.byte 0x94  ; ""
	.byte 0x04
	.asciz "*"
	.asciz "01-24"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "+"
	.byte 0xde  ; "Þ"
	.byte 0x00
	.asciz "P"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0xc6  ; "Æ"
	.byte 0x04
	.asciz "*"
	.asciz "25-48"
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xf3  ; "ó"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf6  ; "ö"
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "\""
	.byte 0x05
	.asciz "*"
	.asciz "49-72"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf7  ; "÷"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x15, 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "T"
	.byte 0x05
	.asciz "*"
	.asciz "73-96"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xf6  ; "ö"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x3e
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0x86  ; ""
	.byte 0x05
	.asciz "*"
	.asciz "97-120"
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "#"
	.ascii "7"
	.byte 0x01
	.asciz "<"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x31
	.byte 0x01
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.byte 0x05
	.asciz "*"
	.zero 6
	.asciz "EDIT"
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xfc  ; "ü"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.asciz "\""
	.byte 0xff
	.byte 0x00
	.byte 0xd9  ; "Ù"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0x4a
	.byte 0x01
	.byte 0x4e
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x02
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.byte 0x52
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x54
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 2
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xfd  ; "ý"
	.byte 0x00
	.byte 0xfb  ; "û"
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0x4a
	.byte 0x01
	.asciz "0"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xfe  ; "þ"
	.byte 0x00
	.byte 0xfc  ; "ü"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.asciz "M"
	.ascii "A"
	.byte 0x01
	.asciz "_"
	.ascii "Z"
	.byte 0x06
	.asciz "*"
	.zero 4
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x09
	.zero 3
	.ascii " "
	.byte 0x01, 0x06
	.byte 0x00
	.asciz "~80"
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0xfd  ; "ý"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz "("
	.ascii "9"
	.byte 0x01
	.asciz "O"
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x00
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "<"
	.asciz "P"
	.byte 0xeb  ; "ë"
	.byte 0x00
	.asciz "{"
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.ascii "V"
	.byte 0x9a  ; ""
	.asciz "#"
	.ascii "Z"
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0x31
	.byte 0x01
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xbc  ; "¼"
	.byte 0x06
	.asciz "*"
	.zero 6
	.asciz "SAVE"
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x03, 0x01
	.byte 0x00
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.asciz "_"
	.ascii "@"
	.byte 0x01
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0x5e
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.ascii "b"
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 4
	.ascii "d"
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x04, 0x01, 0x02, 0x01, 0x08
	.byte 0x00
	.asciz ","
	.asciz "4"
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x4a
	.byte 0x01
	.ascii "f"
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.ascii "j"
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.ascii "l"
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x05, 0x01, 0x03, 0x01, 0x08
	.byte 0x00
	.asciz ","
	.asciz "#"
	.byte 0xeb  ; "ë"
	.byte 0x00
	.asciz "2"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.ascii "n"
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.ascii "r"
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 4
	.ascii "t"
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 2
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x06, 0x01, 0x04, 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x07, 0x01, 0x05, 0x01, 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x08, 0x01, 0x06, 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.asciz "-"
	.ascii "`"
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x09, 0x01, 0x07, 0x01, 0x08
	.byte 0x00
	.asciz ","
	.zero 2
	.asciz "G"
	.byte 0x1b
	.byte 0x00
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x0a, 0x01, 0x08, 0x01, 0x08
	.byte 0x00
	.asciz "N"
	.byte 0x06
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.byte 0x2a
	.byte 0x08
	.asciz "*"
	.byte 0x04
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "HD FILE SELECT"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x0a, 0x01
	.fill 2, 1, 0xff
	.byte 0x0c, 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0b
	.byte 0x00
	.asciz "!"
	.asciz " "
	.asciz "+"
	.ascii "Z"
	.byte 0x08
	.asciz "*"
	.byte 0x03
	.zero 5
	.asciz "DEL"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x0a, 0x01
	.fill 4, 1, 0xff
	.byte 0x0b, 0x01, 0x08
	.byte 0x00
	.byte 0x0b
	.byte 0x00
	.asciz "+"
	.asciz " "
	.asciz "5"
	.ascii "~"
	.byte 0x08
	.asciz "*"
	.byte 0x03
	.zero 5
	.asciz "DIR"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x0d, 0x01
	.fill 2, 1, 0xff
	.byte 0x0f, 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	.asciz "u"
	.byte 0x1f
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x08
	.asciz "*"
	.byte 0x03
	.zero 5
	.asciz "DEL"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x0d, 0x01
	.fill 4, 1, 0xff
	.byte 0x0e, 0x01, 0x08
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "%"
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x08
	.asciz "*"
	.byte 0x03
	.zero 5
	.asciz "FILE"
	.byte 0x00
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x11, 0x01
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "F"
	.asciz "P"
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.ascii "v"
	.byte 0x9a  ; ""
	.asciz "#"
	.ascii "z"
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x12, 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "N"
	.byte 0x06
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.byte 0x10, 0x09
	.asciz "*"
	.byte 0x04
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "HD LOAD OPTION"
	.byte 0x00
	.asciz "-"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x13, 0x01, 0x11, 0x01, 0x08
	.byte 0x00
	.asciz ","
	.zero 2
	.asciz "G"
	.byte 0x1b
	.byte 0x00
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x14, 0x01, 0x12, 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.asciz "4"
	.byte 0x03, 0x01
	.asciz "C"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.ascii "t"
	.byte 0x09
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "~"
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x08
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.byte 0x80, 0x9a  ; ""
	.asciz "#"
	.asciz "CURRENT PANEL          "
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x15, 0x01, 0x13, 0x01, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "#"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 11
	.byte 0x03
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x16, 0x01, 0x14, 0x01, 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x09
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "PNL"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x17, 0x01, 0x15, 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x18, 0x01, 0x16, 0x01, 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "s"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x02
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x19, 0x01, 0x17, 0x01, 0x08
	.byte 0x00
	.asciz "|"
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x03
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x1a, 0x01, 0x18, 0x01, 0x08
	.byte 0x00
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x05
	.zero 9
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x1b, 0x01, 0x19, 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x06
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x1c, 0x01, 0x1a, 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x07
	.zero 9
	.byte 0x06
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x1d, 0x01, 0x1b, 0x01, 0x08
	.byte 0x00
	.byte 0x1c, 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x08
	.zero 9
	.byte 0x07
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x1e, 0x01, 0x1c, 0x01, 0x08
	.byte 0x00
	.asciz "*"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.asciz "K"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x10, 0x0b
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "P.MEM"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x1f, 0x01, 0x1d, 0x01, 0x08
	.byte 0x00
	.asciz "X"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.asciz "m"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x36
	.byte 0x0b
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "SEQ"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii " "
	.byte 0x01, 0x1e, 0x01, 0x08
	.byte 0x00
	.asciz "~"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x5a
	.byte 0x0b
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "COMP"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "!"
	.byte 0x01, 0x1f, 0x01, 0x08
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x80  ; ""
	.byte 0x0b
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "SOUND"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "\""
	.byte 0x01
	.ascii " "
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xa6  ; "¦"
	.byte 0x0b
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "MSP"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "#"
	.byte 0x01
	.byte 0x21
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x16, 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x0b
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "CUSTOM"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "$"
	.byte 0x01
	.byte 0x22
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1e, 0x01
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x0b
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "MIDI"
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "%"
	.byte 0x01
	.byte 0x23
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.asciz "T"
	.byte 0x03, 0x01
	.asciz "c"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x03
	.byte 0x00
	.byte 0x32
	.byte 0x0c
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x84, 0x9a  ; ""
	.asciz "#"
	.byte 0x0a
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.byte 0x86, 0x9a  ; ""
	.asciz "#"
	.asciz "SEQUENCER              "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "&"
	.byte 0x01
	.byte 0x24
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.asciz "d"
	.byte 0x03, 0x01
	.asciz "s"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x04
	.byte 0x00
	.byte 0x84  ; ""
	.byte 0x0c
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x8a, 0x9a  ; ""
	.asciz "#"
	.byte 0x0b
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.byte 0x8c, 0x9a  ; ""
	.asciz "#"
	.asciz "COMPOSER               "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "'"
	.byte 0x01
	.byte 0x25
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.asciz "t"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x05
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.byte 0x0c
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x90, 0x9a  ; ""
	.asciz "#"
	.byte 0x0c
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.byte 0x92, 0x9a  ; ""
	.asciz "#"
	.asciz "SOUND MEMORY           "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "("
	.byte 0x01
	.byte 0x26
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.byte 0x84  ; ""
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0x93  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x06
	.byte 0x00
	.byte 0x28
	.byte 0x0d
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x96, 0x9a  ; ""
	.asciz "#"
	.byte 0x0d
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.byte 0x98, 0x9a  ; ""
	.asciz "#"
	.asciz "MSP                    "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii ")"
	.byte 0x01
	.byte 0x27
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.byte 0x94  ; ""
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x07
	.byte 0x00
	.ascii "z"
	.byte 0x0d
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x9c, 0x9a  ; ""
	.asciz "#"
	.byte 0x0e
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.byte 0x9e, 0x9a  ; ""
	.asciz "#"
	.asciz "RHYTHM CUSTOM          "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "*"
	.byte 0x01
	.byte 0x28
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.byte 0xb4  ; "´"
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x09
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x0d
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xa2, 0x9a  ; "¢"
	.asciz "#"
	.byte 0x10
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.byte 0xa4, 0x9a  ; "¤"
	.asciz "#"
	.asciz "TECHNICS LYRICS        "
	.asciz "."
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "+"
	.byte 0x01
	.byte 0x29
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "*"
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x07, 0x01
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii ","
	.byte 0x01
	.byte 0x2a
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "*"
	.byte 0x18
	.byte 0x00
	.byte 0x07, 0x01
	.asciz "1"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x38
	.byte 0x0e
	.asciz "*"
	.byte 0x05
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xa8, 0x9a  ; "¨"
	.asciz "#"
	.byte 0x07
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.byte 0xaa, 0x9a  ; "ª"
	.asciz "#"
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "-"
	.byte 0x01
	.byte 0x2b
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.asciz "D"
	.byte 0x03, 0x01
	.asciz "S"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.ascii "t"
	.byte 0x0e
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xae, 0x9a  ; "®"
	.asciz "#"
	.byte 0x09
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.byte 0xb0, 0x9a  ; "°"
	.asciz "#"
	.asciz "PANEL MEMORY           "
	.asciz "."
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "."
	.byte 0x01
	.byte 0x2c
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x07, 0x01
	.asciz "2"
	.byte 0x07, 0x01
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "0"
	.byte 0x01
	.byte 0x2e
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x94  ; ""
	.byte 0x00
	.asciz "'"
	.byte 0x9e  ; ""
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x0e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "LYRIC"
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "1"
	.byte 0x01
	.byte 0x2f
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x08
	.byte 0x00
	.byte 0x06, 0x0f
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xb4, 0x9a  ; "´"
	.asciz "#"
	.byte 0x0f
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.byte 0xb6, 0x9a  ; "¶"
	.asciz "#"
	.asciz "USER MIDI SETTINGS     "
	.asciz "."
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "2"
	.byte 0x01
	.byte 0x30
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd5  ; "Õ"
	.byte 0x00
	.asciz "2"
	.byte 0xd5  ; "Õ"
	.byte 0x00
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "3"
	.byte 0x01
	.byte 0x31
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "*"
	.asciz "2"
	.asciz "*"
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 4, 1, 0xff
	.ascii "2"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "*"
	.asciz "2"
	.byte 0x07, 0x01
	.asciz "2"
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "5"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xba, 0x9a  ; "º"
	.asciz "#"
	.byte 0x96  ; ""
	.byte 0x0f
	.asciz "*"
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 2
	.asciz "EDIT FLS NAME"
	.asciz "M"
	.ascii "`"
	.byte 0x01
	.byte 0x34
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "6"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x17
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x34
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "7"
	.byte 0x01
	.byte 0x35
	.byte 0x01, 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz " "
	.ascii "`"
	.byte 0x01
	.byte 0x34
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "8"
	.byte 0x01
	.byte 0x36
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0b
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x17
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.asciz " "
	.ascii "`"
	.byte 0x01
	.byte 0x34
	.byte 0x01
	.byte 0x39
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "7"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "v"
	.asciz "&"
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x8a  ; ""
	.byte 0x00
	.zero 2
	.byte 0x17
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x38
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.asciz "w"
	.asciz "$"
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x50
	.byte 0x10
	.asciz "*"
	.zero 4
	.byte 0xf9  ; "ù"
	.byte 0x00
	.asciz "LST"
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii ";"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xbe, 0x9a  ; "¾"
	.asciz "#"
	.ascii "~"
	.byte 0x10
	.asciz "*"
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 2
	.asciz "F.L.S. FILE LOAD"
	.byte 0x00
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "<"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.byte 0x3d
	.byte 0x01
	.byte 0x3e
	.byte 0x01
	.byte 0x3b
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x0a, 0x01
	.asciz " "
	.ascii "7"
	.byte 0x01
	.asciz "7"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x3c
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.asciz "$"
	.ascii "1"
	.byte 0x01
	.asciz "6"
	.byte 0xf2  ; "ò"
	.byte 0x10
	.asciz "*"
	.zero 6
	.asciz "LOAD"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x3e
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x31
	.byte 0x01
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x18, 0x11
	.asciz "*"
	.zero 6
	.asciz "EDIT"
	.byte 0x00
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "A"
	.byte 0x01
	.byte 0x3e
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "B"
	.byte 0x01
	.byte 0x40
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "C"
	.byte 0x01
	.byte 0x41
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x10
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "D"
	.byte 0x01
	.byte 0x42
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.asciz "P"
	.ascii "?"
	.byte 0x01
	.byte 0xbf  ; "¿"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xc2, 0x9a  ; "Â"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xc6, 0x9a  ; "Æ"
	.asciz "#"
	.zero 4
	.byte 0xc8, 0x9a  ; "È"
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "E"
	.byte 0x01
	.byte 0x43
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.asciz ":"
	.ascii "?"
	.byte 0x01
	.asciz "K"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0x0a
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xca, 0x9a  ; "Ê"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xce, 0x9a  ; "Î"
	.asciz "#"
	.zero 4
	.byte 0xd0, 0x9a  ; "Ð"
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.byte 0x46
	.byte 0x01
	.byte 0x48
	.byte 0x01
	.byte 0x44
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz " "
	.byte 0xc5  ; "Å"
	.byte 0x00
	.asciz "1"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xd2, 0x9a  ; "Ò"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xd6, 0x9a  ; "Ö"
	.asciz "#"
	.zero 4
	.byte 0xd8, 0x9a  ; "Ø"
	.asciz "#"
	.zero 2
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x45
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "G"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xc5  ; "Å"
	.byte 0x00
	.asciz " "
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.asciz "1"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.ascii "r"
	.byte 0x12
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.asciz "AS"
	.byte 0x00
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x45
	.byte 0x01
	.fill 4, 1, 0xff
	.ascii "F"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.asciz " "
	.byte 0xe8  ; "è"
	.byte 0x00
	.asciz "1"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x12
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.asciz "AL"
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.byte 0x49
	.byte 0x01
	.byte 0x4b
	.byte 0x01
	.byte 0x45
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "4"
	.byte 0xe8  ; "è"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x4a
	.byte 0x01
	.byte 0xda, 0x9a  ; "Ú"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.byte 0xde, 0x9a  ; "Þ"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xe0, 0x9a  ; "à"
	.asciz "#"
	.zero 2
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0x48
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "J"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xc5  ; "Å"
	.byte 0x00
	.asciz "4"
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0x48
	.byte 0x01
	.fill 4, 1, 0xff
	.ascii "I"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.asciz "4"
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "L"
	.byte 0x01
	.byte 0x48
	.byte 0x01, 0x18
	.byte 0x00
	.ascii " "
	.byte 0x01
	.zero 2
	.ascii "?"
	.byte 0x01, 0x1f
	.byte 0x00
	.asciz "3"
	.ascii "*"
	.byte 0x01
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.byte 0x4d
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "K"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.fill 2, 1, 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x4c
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x02, 0x01
	.byte 0xdd  ; "Ý"
	.byte 0x00
	.byte 0x2d
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.ascii "t"
	.byte 0x13
	.asciz "*"
	.zero 4
	.byte 0xf9  ; "ù"
	.byte 0x00
	.asciz "PANIC"
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "O"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xe2, 0x9a  ; "â"
	.asciz "#"
	.byte 0xa4  ; "¤"
	.byte 0x13
	.asciz "*"
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 2
	.asciz "F.L.S. DIR SELECT"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x4e
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "P"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x3a
	.byte 0x01, 0x7f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x4e
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "Q"
	.byte 0x01
	.byte 0x4f
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x0d, 0x01, 0x1e
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.asciz "7"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0x4e
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "R"
	.byte 0x01
	.byte 0x50
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "#"
	.byte 0x07, 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x4a
	.byte 0x01
	.byte 0xe6, 0x9a  ; "æ"
	.asciz "#"
	.byte 0x02
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.byte 0xea, 0x9a  ; "ê"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xec, 0x9a  ; "ì"
	.asciz "#"
	.zero 2
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0x4e
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "S"
	.byte 0x01
	.byte 0x51
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.asciz "&"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 7
	.ascii "`"
	.byte 0x14
	.asciz "*"
	.asciz "01-24"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0x4e
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "T"
	.byte 0x01
	.byte 0x52
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "+"
	.byte 0xde  ; "Þ"
	.byte 0x00
	.asciz "P"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0x92  ; ""
	.byte 0x14
	.asciz "*"
	.asciz "25-48"
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0x4e
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "U"
	.byte 0x01
	.byte 0x53
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0x4e
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "V"
	.byte 0x01
	.byte 0x54
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0xee  ; "î"
	.byte 0x14
	.asciz "*"
	.asciz "49-72"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0x4e
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "W"
	.byte 0x01
	.byte 0x55
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x15, 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii " "
	.byte 0x15
	.asciz "*"
	.asciz "73-96"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0x4e
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "X"
	.byte 0x01
	.byte 0x56
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x3e
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "R"
	.byte 0x15
	.asciz "*"
	.asciz "97-120"
	.byte 0x00
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.byte 0x4e
	.byte 0x01
	.fill 4, 1, 0xff
	.ascii "W"
	.byte 0x01, 0x18
	.byte 0x00
	.byte 0x1c
	.zero 3
	.asciz ";"
	.byte 0x1f
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x4a
	.byte 0x01, 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "Z"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xee, 0x9a  ; "î"
	.asciz "#"
	.byte 0x9e  ; ""
	.byte 0x15
	.asciz "*"
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 2
	.asciz "F.L.S. FILE SELECT"
	.byte 0x00
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x59
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "["
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x4e
	.byte 0x01, 0x7f
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0x59
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "\\"
	.byte 0x01
	.byte 0x5a
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.asciz " "
	.byte 0xeb  ; "ë"
	.byte 0x00
	.asciz "/"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xf2, 0x9a  ; "ò"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xf6, 0x9a  ; "ö"
	.asciz "#"
	.zero 4
	.byte 0xf8, 0x9a  ; "ø"
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.byte 0x59
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "]"
	.byte 0x01
	.byte 0x5b
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.asciz "0"
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0x4a
	.byte 0x01
	.byte 0xfa, 0x9a  ; "ú"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.byte 0xfe, 0x9a  ; "þ"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.zero 2
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 2
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0x59
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "^"
	.byte 0x01
	.byte 0x5c
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x59
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "_"
	.byte 0x01
	.byte 0x5d
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x59
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "`"
	.byte 0x01
	.byte 0x5e
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x10
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0x59
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "a"
	.byte 0x01
	.byte 0x5f
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.asciz "D"
	.ascii "?"
	.byte 0x01
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01, 0x02
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0x06
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 4
	.byte 0x08
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 2
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x59
	.byte 0x01
	.ascii "b"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "`"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x02, 0x01, 0x1e
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.asciz "7"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.ascii "a"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x03, 0x01
	.asciz "#"
	.ascii "6"
	.byte 0x01
	.asciz "5"
	.ascii "B"
	.byte 0x17
	.asciz "*"
	.zero 6
	.asciz "SELECT"
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "d"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x0a
	.byte 0x9b  ; ""
	.asciz "#"
	.ascii "t"
	.byte 0x17
	.asciz "*"
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 2
	.asciz "F.L.S. EDIT"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "e"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x3a
	.byte 0x01, 0x7f
	.byte 0x00
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "f"
	.byte 0x01
	.ascii "d"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.zero 3
	.ascii "j"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.ascii "g"
	.byte 0x01
	.ascii "i"
	.byte 0x01
	.ascii "e"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz " "
	.byte 0xc5  ; "Å"
	.byte 0x00
	.asciz "1"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 7
	.ascii "@"
	.byte 0x01, 0x0e
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x12
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 4
	.byte 0x14
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 2
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.ascii "f"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "h"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.asciz " "
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.asciz "1"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x26
	.byte 0x18
	.asciz "*"
	.byte 0x03
	.zero 7
	.asciz "AS"
	.byte 0x00
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.ascii "f"
	.byte 0x01
	.fill 4, 1, 0xff
	.ascii "g"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.asciz " "
	.byte 0xe8  ; "è"
	.byte 0x00
	.asciz "1"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x50
	.byte 0x18
	.asciz "*"
	.byte 0x03
	.zero 7
	.asciz "AL"
	.zero 3
	.ascii "j"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.ascii "j"
	.byte 0x01
	.ascii "l"
	.byte 0x01
	.ascii "f"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "4"
	.byte 0xe8  ; "è"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 5
	.byte 0x07
	.byte 0x00
	.byte 0x4a
	.byte 0x01, 0x16
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.byte 0x1a
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1c
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 2
	.asciz "."
	.ascii "`"
	.byte 0x01
	.ascii "i"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "k"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.asciz "4"
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.ascii "i"
	.byte 0x01
	.fill 4, 1, 0xff
	.ascii "j"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xc5  ; "Å"
	.byte 0x00
	.asciz "4"
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.ascii "m"
	.byte 0x01
	.ascii "n"
	.byte 0x01
	.ascii "i"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.asciz "7"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.ascii "l"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x01, 0x01
	.asciz "#"
	.ascii "4"
	.byte 0x01
	.asciz "5"
	.byte 0x0c, 0x19
	.asciz "*"
	.zero 6
	.asciz "SEARCH"
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.ascii "o"
	.byte 0x01
	.ascii "q"
	.byte 0x01
	.ascii "l"
	.byte 0x01, 0x08
	.zero 2
	.byte 0x01
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.byte 0xd9  ; "Ù"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x0c
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.ascii "n"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "p"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0c, 0x01
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0x27
	.byte 0x01
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0x5c
	.byte 0x19
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "SAVE"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.ascii "n"
	.byte 0x01
	.fill 4, 1, 0xff
	.ascii "o"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x0a, 0x01
	.byte 0xce  ; "Î"
	.byte 0x00
	.byte 0x31
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x82  ; ""
	.byte 0x19
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "F.L.S."
	.byte 0x00
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "r"
	.byte 0x01
	.ascii "n"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.asciz "#"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 7
	.byte 0xb6  ; "¶"
	.byte 0x19
	.asciz "*"
	.asciz "DEL1"
	.byte 0x00
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "s"
	.byte 0x01
	.ascii "q"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0xde  ; "Þ"
	.byte 0x00
	.asciz "L"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.zero 3
	.byte 0xe8  ; "è"
	.byte 0x19
	.asciz "*"
	.asciz "DEL2"
	.byte 0x00
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "t"
	.byte 0x01
	.ascii "r"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x05
	.zero 3
	.byte 0x1a, 0x1a
	.asciz "*"
	.asciz "INS"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "u"
	.byte 0x01
	.ascii "s"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x06
	.zero 3
	.ascii "J"
	.byte 0x1a
	.asciz "*"
	.asciz "A.S."
	.byte 0x00
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "v"
	.byte 0x01
	.ascii "t"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1c, 0x01
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "|"
	.byte 0x1a
	.asciz "*"
	.asciz "A.L."
	.zero 3
	.ascii "j"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "w"
	.byte 0x01
	.ascii "u"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.asciz ":"
	.ascii "?"
	.byte 0x01
	.asciz "K"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xf2  ; "ò"
	.byte 0x00
	.zero 2
	.ascii "@"
	.byte 0x01, 0x1e
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x22
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 4
	.ascii "$"
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "x"
	.byte 0x01
	.ascii "v"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.asciz "N"
	.ascii "?"
	.byte 0x01
	.byte 0xbc  ; "¼"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0x26
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0x2a
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 4
	.ascii ","
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 2
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "y"
	.byte 0x01
	.ascii "w"
	.byte 0x01, 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0x4a
	.byte 0x01
	.asciz "."
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "z"
	.byte 0x01
	.ascii "x"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.asciz " "
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.asciz "0"
	.zero 2
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 4, 1, 0xff
	.ascii "y"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xc5  ; "Å"
	.byte 0x00
	.asciz " "
	.byte 0xc5  ; "Å"
	.byte 0x00
	.asciz "0"
	.zero 2
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "|"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x2e
	.byte 0x9b  ; ""
	.asciz "#"
	.ascii "r"
	.byte 0x1b
	.asciz "*"
	.asciz "s"
	.zero 2
	.asciz "EDIT DIRECTORY NAME"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x7b
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "}"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "M"
	.ascii "`"
	.byte 0x01
	.byte 0x7b
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "~"
	.byte 0x01
	.byte 0x7c
	.byte 0x01, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.byte 0x19
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.asciz " "
	.ascii "`"
	.byte 0x01
	.byte 0x7b
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x7f, 0x01
	.byte 0x7d
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0b
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.asciz " "
	.ascii "`"
	.byte 0x01
	.byte 0x7b
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x80  ; ""
	.byte 0x01
	.byte 0x7e
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "v"
	.asciz "&"
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x8a  ; ""
	.byte 0x00
	.zero 2
	.byte 0x19
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x7b
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x7f, 0x01, 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.asciz "w"
	.asciz "$"
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x32
	.byte 0x1c
	.asciz "*"
	.zero 4
	.byte 0xf9  ; "ù"
	.byte 0x00
	.asciz "LST"
	.asciz "K"
	.ascii "`"
	.byte 0x01
	.fill 8, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "<"
	.asciz "T"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.ascii "2"
	.byte 0x9b  ; ""
	.asciz "#"
	.ascii "6"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x83  ; ""
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x3a
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x84  ; ""
	.byte 0x1c
	.asciz "*"
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.asciz "SAVE OPTION"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x84  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "N"
	.byte 0x7f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x85  ; ""
	.byte 0x01
	.byte 0x83  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "#"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 11
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x86  ; ""
	.byte 0x01
	.byte 0x84  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x87  ; ""
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "s"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x02
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x88  ; ""
	.byte 0x01
	.byte 0x86  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "|"
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x03
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x89  ; ""
	.byte 0x01
	.byte 0x87  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x05
	.zero 9
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x8a  ; ""
	.byte 0x01
	.byte 0x88  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x06
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x8b  ; ""
	.byte 0x01
	.byte 0x89  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x07
	.zero 9
	.byte 0x06
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x8c  ; ""
	.byte 0x01
	.byte 0x8a  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1c, 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x08
	.zero 9
	.byte 0x07
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x8d  ; ""
	.byte 0x01
	.byte 0x8b  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x0a, 0x1e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "PNL"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x8e  ; ""
	.byte 0x01
	.byte 0x8c  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "*"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.asciz "K"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x2e
	.byte 0x1e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "P.MEM"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x8f  ; ""
	.byte 0x01
	.byte 0x8d  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "X"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.asciz "m"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x54
	.byte 0x1e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "SEQ"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x90  ; ""
	.byte 0x01
	.byte 0x8e  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "~"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.ascii "x"
	.byte 0x1e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "COMP"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x91  ; ""
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x9e  ; ""
	.byte 0x1e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "SOUND"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x92  ; ""
	.byte 0x01
	.byte 0x90  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xc4  ; "Ä"
	.byte 0x1e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "MSP"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x93  ; ""
	.byte 0x01
	.byte 0x91  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x16, 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xe8  ; "è"
	.byte 0x1e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "CUSTOM"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x94  ; ""
	.byte 0x01
	.byte 0x92  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1e, 0x01
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x10, 0x1f
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "MIDI"
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x95  ; ""
	.byte 0x01
	.byte 0x93  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.asciz "j"
	.byte 0xff
	.byte 0x00
	.asciz "y"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x04
	.byte 0x00
	.byte 0x50
	.byte 0x1f
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii ">"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x0b
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.byte 0x40
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "COMPOSER               "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x96  ; ""
	.byte 0x01
	.byte 0x94  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "("
	.byte 0x1f
	.byte 0x00
	.byte 0x03, 0x01
	.asciz "8"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa2  ; "¢"
	.byte 0x1f
	.asciz "*"
	.byte 0x05
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "D"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x06
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.byte 0x46
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x97  ; ""
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.asciz "="
	.byte 0xff
	.byte 0x00
	.asciz "L"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x1f
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "J"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x08
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.byte 0x4c
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "CURRENT PANEL          "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x98  ; ""
	.byte 0x01
	.byte 0x96  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.asciz "L"
	.byte 0xff
	.byte 0x00
	.asciz "["
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "0 *"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "P"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x09
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.byte 0x52
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "PANEL MEMORY           "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0x97  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.asciz "["
	.byte 0xff
	.byte 0x00
	.asciz "j"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x03
	.byte 0x00
	.byte 0x82  ; ""
	.asciz " *"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "V"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x0a
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.byte 0x58
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "SEQUENCER              "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x9a  ; ""
	.byte 0x01
	.byte 0x98  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.asciz "y"
	.byte 0xff
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x05
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.asciz " *"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "\\"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x0c
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.byte 0x5e
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "SOUND MEMORY           "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x9b  ; ""
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x06
	.byte 0x00
	.asciz "&!*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "b"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x0d
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.ascii "d"
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "MSP                    "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x9c  ; ""
	.byte 0x01
	.byte 0x9a  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x07
	.byte 0x00
	.asciz "x!*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "h"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x0e
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.ascii "j"
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "RHYTHM CUSTOM          "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x9d  ; ""
	.byte 0x01
	.byte 0x9b  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x08
	.byte 0x00
	.byte 0xca  ; "Ê"
	.asciz "!*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "n"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x0f
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.ascii "p"
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "USER MIDI SETTINGS     "
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x9e  ; ""
	.byte 0x01
	.byte 0x9c  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "("
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x9f  ; ""
	.byte 0x01
	.byte 0x9d  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "("
	.asciz ":"
	.byte 0x03, 0x01
	.asciz ":"
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x9e  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x03, 0x01
	.asciz ":"
	.byte 0x03, 0x01
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xa1  ; "¡"
	.byte 0x01
	.byte 0x9f  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "("
	.asciz ":"
	.asciz "("
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xa2  ; "¢"
	.byte 0x01
	.byte 0xa0  ; " "
	.byte 0x01, 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x2a
	.byte 0x01, 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.byte 0xa3  ; "£"
	.byte 0x01
	.byte 0xa4  ; "¤"
	.byte 0x01
	.byte 0xa1  ; "¡"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x0d, 0x01, 0x1e
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.asciz "7"
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xa2  ; "¢"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x10, 0x01
	.asciz "#"
	.ascii "3"
	.byte 0x01
	.asciz "5"
	.byte 0xac  ; "¬"
	.asciz "\"*"
	.zero 6
	.asciz "SAVE"
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.byte 0xa5  ; "¥"
	.byte 0x01
	.byte 0xa6  ; "¦"
	.byte 0x01
	.byte 0xa2  ; "¢"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x07, 0x01
	.asciz "L"
	.ascii "7"
	.byte 0x01
	.asciz "]"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x09
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xa4  ; "¤"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "P"
	.ascii "6"
	.byte 0x01
	.asciz "Z"
	.byte 0xfa  ; "ú"
	.asciz "\"*"
	.byte 0x03
	.zero 5
	.asciz "PERFORM"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.byte 0xa7  ; "§"
	.byte 0x01
	.byte 0xa8  ; "¨"
	.byte 0x01
	.byte 0xa4  ; "¤"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x07, 0x01
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0b
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xa6  ; "¦"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x00
	.asciz "J#*"
	.byte 0x03
	.zero 5
	.asciz "ALL OFF"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.byte 0xa9  ; "©"
	.byte 0x01
	.byte 0xaa  ; "ª"
	.byte 0x01
	.byte 0xa6  ; "¦"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x07, 0x01
	.asciz "v"
	.ascii "7"
	.byte 0x01
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0a
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xa8  ; "¨"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "z"
	.ascii "0"
	.byte 0x01
	.byte 0x84  ; ""
	.byte 0x00
	.byte 0x9a  ; ""
	.asciz "#*"
	.byte 0x03
	.zero 5
	.asciz "BACKUP"
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xab  ; "«"
	.byte 0x01
	.byte 0xa8  ; "¨"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0xc4  ; "Ä"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x09
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.asciz "#*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "t"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x10
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.ascii "v"
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "TECHNICS LYRICS        "
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xac  ; "¬"
	.byte 0x01
	.byte 0xaa  ; "ª"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x9e  ; ""
	.byte 0x00
	.asciz "'"
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x09
	.zero 9
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xad  ; "­"
	.byte 0x01
	.byte 0xab  ; "«"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x93  ; ""
	.byte 0x00
	.asciz "'"
	.byte 0x9d  ; ""
	.byte 0x00
	.asciz "<$*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "LYRIC"
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0xac  ; "¬"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.asciz ":"
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xaf  ; "¯"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz ","
	.asciz "l"
	.byte 0x13, 0x01
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.ascii "z"
	.byte 0x9b  ; ""
	.asciz "#"
	.ascii "~"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.byte 0xb0  ; "°"
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "L"
	.asciz "&"
	.asciz "]"
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0x07
	.zero 9
	.byte 0x89  ; ""
	.byte 0x00
	.zero 2
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.asciz "M"
	.asciz "$"
	.asciz "_"
	.byte 0xc8  ; "È"
	.asciz "$*"
	.zero 6
	.asciz "DEL"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.byte 0xb2  ; "²"
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "\""
	.asciz "&"
	.asciz "3"
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0x06
	.zero 9
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.asciz "#"
	.asciz "$"
	.asciz "5"
	.byte 0x14
	.asciz "%*"
	.zero 6
	.asciz "INS"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.byte 0xb4  ; "´"
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.asciz "\""
	.ascii "7"
	.byte 0x01
	.asciz "3"
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0x09
	.zero 9
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a, 0x01
	.asciz "#"
	.ascii "5"
	.byte 0x01
	.asciz "5"
	.asciz "`%*"
	.zero 6
	.asciz "CLR"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.byte 0xb6  ; "¶"
	.byte 0x01
	.byte 0xb7  ; "·"
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.asciz "L"
	.ascii "7"
	.byte 0x01
	.asciz "]"
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0x08
	.zero 9
	.byte 0x09
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a, 0x01
	.asciz "M"
	.ascii "5"
	.byte 0x01
	.asciz "_"
	.byte 0xac  ; "¬"
	.asciz "%*"
	.zero 6
	.asciz "~8d ~8b"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xb8  ; "¸"
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "#"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 11
	.byte 0x0f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xb9  ; "¹"
	.byte 0x01
	.byte 0xb7  ; "·"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xba  ; "º"
	.byte 0x01
	.byte 0xb8  ; "¸"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "I"
	.byte 0xdb  ; "Û"
	.byte 0x00
	.asciz "$&*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.asciz "POSITION"
	.byte 0x00
	.asciz "L"
	.ascii "`"
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xbb  ; "»"
	.byte 0x01
	.byte 0xb9  ; "¹"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.asciz "H"
	.byte 0x13, 0x01
	.asciz "g"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x82, 0x9b  ; ""
	.asciz "#"
	.asciz "ABC"
	.asciz "ABC"
	.asciz "abc"
	.asciz "abc"
	.asciz "!#$"
	.asciz "!#$"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xbf  ; "¿"
	.byte 0x01
	.byte 0xbd  ; "½"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc0  ; "À"
	.byte 0x01
	.byte 0xbe  ; "¾"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x06
	.byte 0x00
	.byte 0x0e
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc1  ; "Á"
	.byte 0x01
	.byte 0xbf  ; "¿"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1c, 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x05
	.zero 9
	.byte 0x07
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0xc0  ; "À"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc3  ; "Ã"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x8a, 0x9b  ; ""
	.asciz "#"
	.asciz "4'*"
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.asciz "HD FILE DELETE"
	.byte 0x00
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc4  ; "Ä"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc5  ; "Å"
	.byte 0x01
	.byte 0xc3  ; "Ã"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.asciz "~'*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "PNL"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc6  ; "Æ"
	.byte 0x01
	.byte 0xc4  ; "Ä"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "*"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.asciz "K"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xa2  ; "¢"
	.asciz "'*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "P.MEM"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc7  ; "Ç"
	.byte 0x01
	.byte 0xc5  ; "Å"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "X"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.asciz "m"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xc8  ; "È"
	.asciz "'*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "SEQ"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc8  ; "È"
	.byte 0x01
	.byte 0xc6  ; "Æ"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "~"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xec  ; "ì"
	.asciz "'*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "COMP"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc9  ; "É"
	.byte 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x12
	.asciz "(*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "SOUND"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xca  ; "Ê"
	.byte 0x01
	.byte 0xc8  ; "È"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.asciz "8(*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "MSP"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xcb  ; "Ë"
	.byte 0x01
	.byte 0xc9  ; "É"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x16, 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.asciz "\\(*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "CUSTOM"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xcc  ; "Ì"
	.byte 0x01
	.byte 0xca  ; "Ê"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1e, 0x01
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x84  ; ""
	.asciz "(*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "MIDI"
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xcd  ; "Í"
	.byte 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "+"
	.asciz ";"
	.asciz "+"
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xce  ; "Î"
	.byte 0x01
	.byte 0xcc  ; "Ì"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "+"
	.asciz ":"
	.byte 0xfa  ; "ú"
	.byte 0x00
	.asciz ":"
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xcf  ; "Ï"
	.byte 0x01
	.byte 0xcd  ; "Í"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "+"
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xfa  ; "ú"
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd0  ; "Ð"
	.byte 0x01
	.byte 0xce  ; "Î"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.asciz ";"
	.byte 0x01, 0x01
	.asciz "J"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.byte 0x12
	.asciz ")*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x8e, 0x9b  ; ""
	.asciz "#"
	.byte 0x1e
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.byte 0x90, 0x9b  ; ""
	.asciz "#"
	.asciz "CURRENT PANEL     "
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd1  ; "Ñ"
	.byte 0x01
	.byte 0xcf  ; "Ï"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.asciz "L"
	.byte 0x01, 0x01
	.asciz "["
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "`)*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x94, 0x9b  ; ""
	.asciz "#"
	.byte 0x1f
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.byte 0x96, 0x9b  ; ""
	.asciz "#"
	.asciz "PANEL MEMORY      "
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd2  ; "Ò"
	.byte 0x01
	.byte 0xd0  ; "Ð"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.asciz "["
	.byte 0x01, 0x01
	.asciz "j"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x03
	.byte 0x00
	.byte 0xae  ; "®"
	.asciz ")*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x9a, 0x9b  ; ""
	.asciz "#"
	.asciz " "
	.ascii "*"
	.byte 0x01
	.byte 0x9c, 0x9b  ; ""
	.asciz "#"
	.asciz "SEQUENCER         "
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd3  ; "Ó"
	.byte 0x01
	.byte 0xd1  ; "Ñ"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.asciz "j"
	.byte 0x01, 0x01
	.asciz "y"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x04
	.byte 0x00
	.byte 0xfc  ; "ü"
	.asciz ")*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xa0, 0x9b  ; " "
	.asciz "#"
	.asciz "!"
	.ascii "*"
	.byte 0x01
	.byte 0xa2, 0x9b  ; "¢"
	.asciz "#"
	.asciz "COMPOSER          "
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd4  ; "Ô"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.asciz "y"
	.byte 0x01, 0x01
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x05
	.byte 0x00
	.asciz "J**"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xa6, 0x9b  ; "¦"
	.asciz "#"
	.asciz "\""
	.ascii "*"
	.byte 0x01
	.byte 0xa8, 0x9b  ; "¨"
	.asciz "#"
	.asciz "SOUND MEMORY      "
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd5  ; "Õ"
	.byte 0x01
	.byte 0xd3  ; "Ó"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0x01, 0x01
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x06
	.byte 0x00
	.byte 0x98  ; ""
	.asciz "**"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xac, 0x9b  ; "¬"
	.asciz "#"
	.asciz "#"
	.ascii "*"
	.byte 0x01
	.byte 0xae, 0x9b  ; "®"
	.asciz "#"
	.asciz "MSP               "
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd6  ; "Ö"
	.byte 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0x01, 0x01
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x07
	.byte 0x00
	.byte 0xe6  ; "æ"
	.asciz "**"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xb2, 0x9b  ; "²"
	.asciz "#"
	.asciz "$"
	.ascii "*"
	.byte 0x01
	.byte 0xb4, 0x9b  ; "´"
	.asciz "#"
	.asciz "RHYTHM CUSTOM     "
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd7  ; "×"
	.byte 0x01
	.byte 0xd5  ; "Õ"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0x01, 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x08
	.byte 0x00
	.asciz "4+*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xb8, 0x9b  ; "¸"
	.asciz "#"
	.asciz "%"
	.ascii "*"
	.byte 0x01
	.byte 0xba, 0x9b  ; "º"
	.asciz "#"
	.asciz "USER MIDI SETTINGS"
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd8  ; "Ø"
	.byte 0x01
	.byte 0xd6  ; "Ö"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "#"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 11
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd9  ; "Ù"
	.byte 0x01
	.byte 0xd7  ; "×"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xda  ; "Ú"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "s"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x02
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xdb  ; "Û"
	.byte 0x01
	.byte 0xd9  ; "Ù"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "|"
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x03
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xdc  ; "Ü"
	.byte 0x01
	.byte 0xda  ; "Ú"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x05
	.zero 9
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xdd  ; "Ý"
	.byte 0x01
	.byte 0xdb  ; "Û"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x06
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xde  ; "Þ"
	.byte 0x01
	.byte 0xdc  ; "Ü"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x07
	.zero 9
	.byte 0x06
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xdf  ; "ß"
	.byte 0x01
	.byte 0xdd  ; "Ý"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1c, 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x08
	.zero 9
	.byte 0x07
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xe0  ; "à"
	.byte 0x01
	.byte 0xde  ; "Þ"
	.byte 0x01, 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.byte 0x00
	.byte 0x1c
	.byte 0x00
	.byte 0x2a
	.byte 0x01, 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.byte 0xe1  ; "á"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x01
	.byte 0xdf  ; "ß"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x0d, 0x01, 0x1e
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.asciz "7"
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xe0  ; "à"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x14, 0x01
	.asciz "#"
	.ascii "/"
	.byte 0x01
	.asciz "5"
	.byte 0xea  ; "ê"
	.asciz ",*"
	.zero 6
	.asciz "DEL"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.byte 0xe3  ; "ã"
	.byte 0x01
	.byte 0xe4  ; "ä"
	.byte 0x01
	.byte 0xe0  ; "à"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xfd  ; "ý"
	.byte 0x00
	.asciz "v"
	.ascii "7"
	.byte 0x01
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0a
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xfd  ; "ý"
	.byte 0x00
	.asciz "w"
	.ascii "8"
	.byte 0x01
	.byte 0x89  ; ""
	.byte 0x00
	.asciz "6-*"
	.zero 6
	.asciz "ALL DEL"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.byte 0xe5  ; "å"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xfd  ; "ý"
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0b
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xe4  ; "ä"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xfd  ; "ý"
	.byte 0x00
	.byte 0xa1  ; "¡"
	.byte 0x00
	.byte 0x38
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0x86  ; ""
	.asciz "-*"
	.zero 6
	.asciz "ALL OFF"
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xe7  ; "ç"
	.byte 0x01
	.byte 0xe4  ; "ä"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "*"
	.asciz " "
	.byte 0xfc  ; "ü"
	.byte 0x00
	.asciz "9"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc8  ; "È"
	.asciz "-*"
	.byte 0x05
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xbe, 0x9b  ; "¾"
	.asciz "#"
	.byte 0x1d
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.byte 0xc0, 0x9b  ; "À"
	.asciz "#"
	.zero 2
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xe8  ; "è"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x9e  ; ""
	.byte 0x00
	.asciz "'"
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x09
	.zero 9
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xe9  ; "é"
	.byte 0x01
	.byte 0xe7  ; "ç"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x93  ; ""
	.byte 0x00
	.asciz "'"
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0x12
	.asciz ".*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "LYRIC"
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xea  ; "ê"
	.byte 0x01
	.byte 0xe8  ; "è"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0x01, 0x01
	.byte 0xc4  ; "Ä"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x09
	.byte 0x00
	.asciz "R.*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xc4, 0x9b  ; "Ä"
	.asciz "#"
	.asciz "&"
	.ascii "*"
	.byte 0x01
	.byte 0xc6, 0x9b  ; "Æ"
	.asciz "#"
	.asciz "TECHNICS LYRICS   "
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xeb  ; "ë"
	.byte 0x01
	.byte 0xe9  ; "é"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xcd  ; "Í"
	.byte 0x00
	.asciz ";"
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0xea  ; "ê"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xfa  ; "ú"
	.byte 0x00
	.asciz ";"
	.byte 0xfa  ; "ú"
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "3"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xed  ; "í"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xca, 0x9b  ; "Ê"
	.asciz "#"
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.byte 0xec  ; "ì"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a, 0x01
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0x34
	.byte 0x01
	.byte 0xdf  ; "ß"
	.byte 0x00
	.asciz "'"
	.ascii "*"
	.byte 0x01, 0x09
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 8, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xce, 0x9b  ; "Î"
	.asciz "#"
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xf0  ; "ð"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xd2, 0x9b  ; "Ò"
	.asciz "#"
	.asciz "\"/*"
	.zero 6
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x01
	.byte 0xf1  ; "ñ"
	.byte 0x01
	.byte 0xf2  ; "ò"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.asciz "R/*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc8  ; "È"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x01
	.byte 0xf3  ; "ó"
	.byte 0x01
	.byte 0xf4  ; "ô"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xac  ; "¬"
	.asciz "/*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xf2  ; "ò"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xf5  ; "õ"
	.byte 0x01
	.byte 0xf2  ; "ò"
	.byte 0x01, 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "4"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x01
	.byte 0xf6  ; "ö"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xf4  ; "ô"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "("
	.asciz "L"
	.byte 0x17, 0x01
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x04
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xf5  ; "õ"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xf7  ; "÷"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz ","
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xf5  ; "õ"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0xf6  ; "ö"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.asciz "l"
	.byte 0x13, 0x01
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0x0a
	.zero 3
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xf9  ; "ù"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0x25
	.byte 0x01
	.asciz "Q"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.byte 0xd6, 0x9b  ; "Ö"
	.asciz "#"
	.byte 0xda, 0x9b  ; "Ú"
	.asciz "#"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xf8  ; "ø"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xfa  ; "ú"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.asciz " "
	.ascii "!"
	.byte 0x01
	.asciz "2"
	.byte 0xb4  ; "´"
	.asciz "0*"
	.zero 6
	.asciz "DELETE DIRECTORY FROM HARD DISK:"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xf8  ; "ø"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0xf9  ; "ù"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.asciz "6"
	.byte 0x11, 0x01
	.asciz "H"
	.byte 0xf6  ; "ö"
	.asciz "0*"
	.byte 0x02
	.zero 3
	.byte 0x0a
	.byte 0x00
	.asciz "PLEASE WAIT ..."
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xfc  ; "ü"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xde, 0x9b  ; "Þ"
	.asciz "#"
	.asciz "01*"
	.zero 6
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0xfb  ; "û"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xfd  ; "ý"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.asciz "`1*"
	.zero 2
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xfb  ; "û"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xfe  ; "þ"
	.byte 0x01
	.byte 0xfc  ; "ü"
	.byte 0x01, 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "5"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0xfb  ; "û"
	.byte 0x01
	.fill 3, 1, 0xff
	.byte 0x01
	.byte 0xfd  ; "ý"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xaa  ; "ª"
	.asciz "1*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xfb  ; "û"
	.byte 0x01
	.byte 0x00
	.byte 0x02, 0x02, 0x02
	.byte 0xfe  ; "þ"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "("
	.asciz "L"
	.byte 0x17, 0x01
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x04
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xff
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x01, 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz ","
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xff
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x00
	.byte 0x02, 0x08
	.byte 0x00
	.asciz ","
	.asciz "l"
	.byte 0x13, 0x01
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0x0a
	.zero 3
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xfb  ; "û"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x03, 0x02
	.byte 0xff
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc8  ; "È"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xfb  ; "û"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x02, 0x02, 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x05, 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xe2, 0x9b  ; "â"
	.asciz "#"
	.byte 0xa8  ; "¨"
	.asciz "2*"
	.zero 6
	.asciz "R"
	.ascii "`"
	.byte 0x01, 0x04, 0x02
	.fill 2, 1, 0xff
	.byte 0x06, 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz ";"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01, 0x04, 0x02, 0x07, 0x02, 0x08, 0x02, 0x05, 0x02, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.byte 0xf2  ; "ò"
	.asciz "2*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x06, 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc8  ; "È"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01, 0x04, 0x02, 0x09, 0x02, 0x0a, 0x02, 0x06, 0x02, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz "L3*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x08, 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x04, 0x02, 0x0b, 0x02
	.fill 2, 1, 0xff
	.byte 0x08, 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "L"
	.byte 0x17, 0x01
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x04
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x0a, 0x02
	.fill 2, 1, 0xff
	.byte 0x0c, 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz ","
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x0a, 0x02
	.fill 4, 1, 0xff
	.byte 0x0b, 0x02, 0x08
	.byte 0x00
	.asciz ","
	.asciz "l"
	.byte 0x13, 0x01
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x1c
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0x0a
	.zero 3
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x0e, 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xe6, 0x9b  ; "æ"
	.asciz "#"
	.asciz " 4*"
	.zero 6
	.asciz "R"
	.ascii "`"
	.byte 0x01, 0x0d, 0x02
	.fill 2, 1, 0xff
	.byte 0x0f, 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz ":"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01, 0x0d, 0x02, 0x10, 0x02, 0x11, 0x02, 0x0e, 0x02, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.asciz "j4*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x0f, 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc8  ; "È"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01, 0x0d, 0x02, 0x12, 0x02, 0x13, 0x02, 0x0f, 0x02, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xc4  ; "Ä"
	.asciz "4*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x11, 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x0d, 0x02, 0x14, 0x02
	.fill 2, 1, 0xff
	.byte 0x11, 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz ","
	.byte 0x17, 0x01
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x05
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x13, 0x02
	.fill 2, 1, 0xff
	.byte 0x15, 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz ","
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x13, 0x02
	.fill 2, 1, 0xff
	.byte 0x16, 0x02, 0x14, 0x02, 0x08
	.byte 0x00
	.asciz ","
	.asciz "L"
	.byte 0x13, 0x01
	.asciz "{"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0x0a
	.zero 3
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x13, 0x02
	.fill 4, 1, 0xff
	.byte 0x15, 0x02, 0x08
	.byte 0x00
	.asciz ","
	.asciz "|"
	.byte 0x13, 0x01
	.byte 0x9f  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "="
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18, 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0x25
	.byte 0x01
	.asciz "U"
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 2
	.byte 0xea, 0x9b  ; "ê"
	.asciz "#"
	.byte 0xee, 0x9b  ; "î"
	.asciz "#"
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x17, 0x02
	.fill 2, 1, 0xff
	.byte 0x19, 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "\""
	.byte 0x17, 0x01
	.asciz "9"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "8"
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x17, 0x02
	.fill 4, 1, 0xff
	.byte 0x18, 0x02, 0x08
	.byte 0x00
	.asciz " "
	.asciz "8"
	.ascii "#"
	.byte 0x01
	.asciz "O"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "1"
	.byte 0x02
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x1b, 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xf2, 0x9b  ; "ò"
	.asciz "#"
	.asciz ":6*"
	.zero 4
	.asciz "   HD FORMAT"
	.byte 0x00
	.asciz "6"
	.ascii "`"
	.byte 0x01, 0x1a, 0x02, 0x1c, 0x02
	.ascii " "
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "$"
	.asciz "&"
	.byte 0x1b, 0x01
	.byte 0xd5  ; "Õ"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "p6*"
	.byte 0x02
	.zero 7
	.byte 0x05
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x1b, 0x02
	.fill 2, 1, 0xff
	.byte 0x1d, 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "&"
	.asciz "F"
	.byte 0x19, 0x01
	.asciz "g"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x18
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xf1  ; "ñ"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x1b, 0x02
	.fill 2, 1, 0xff
	.byte 0x1e, 0x02, 0x1c, 0x02, 0x08
	.byte 0x00
	.asciz "&"
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x1a
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xf1  ; "ñ"
	.byte 0x00
	.zero 2
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x1b, 0x02
	.fill 2, 1, 0xff
	.byte 0x1f, 0x02, 0x1d, 0x02, 0x08
	.byte 0x00
	.asciz "&"
	.asciz "h"
	.byte 0x19, 0x01
	.byte 0xa7  ; "§"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x19
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x04
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x1b, 0x02
	.fill 4, 1, 0xff
	.byte 0x1e, 0x02, 0x08
	.byte 0x00
	.asciz "&"
	.asciz "."
	.byte 0x19, 0x01
	.asciz "E"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "i"
	.ascii "`"
	.byte 0x01, 0x1a, 0x02
	.fill 2, 1, 0xff
	.ascii "!"
	.byte 0x02, 0x1b, 0x02, 0x08
	.byte 0x00
	.asciz "]"
	.byte 0x01
	.byte 0x00
	.asciz "w"
	.byte 0x1b
	.byte 0x00
	.asciz "'"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01, 0x1a, 0x02
	.fill 2, 1, 0xff
	.ascii "\""
	.byte 0x02
	.ascii " "
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz "b7*"
	.asciz "CANCEL"
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01, 0x1a, 0x02
	.fill 4, 1, 0xff
	.ascii "!"
	.byte 0x02, 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "6"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "$"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0x25
	.byte 0x01
	.byte 0xd5  ; "Õ"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 2
	.byte 0xf6, 0x9b  ; "ö"
	.asciz "#"
	.byte 0xfa, 0x9b  ; "ú"
	.asciz "#"
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x23
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "%"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz " "
	.asciz "&"
	.byte 0x1f, 0x01
	.asciz "]"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "9"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x23
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "&"
	.byte 0x02
	.byte 0x24
	.byte 0x02, 0x08
	.byte 0x00
	.asciz " "
	.asciz "b"
	.byte 0x1f, 0x01
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz ":"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x23
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "%"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz " "
	.byte 0x9a  ; ""
	.byte 0x00
	.byte 0x23
	.byte 0x01
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "1"
	.byte 0x02
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "("
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xfe, 0x9b  ; "þ"
	.asciz "#"
	.asciz "P8*"
	.zero 6
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x27
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii ")"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x13
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x27
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "*"
	.byte 0x02
	.byte 0x28
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "d"
	.byte 0x0c
	.byte 0x00
	.byte 0xdb  ; "Û"
	.byte 0x00
	.asciz "3"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0x92  ; ""
	.asciz "8*"
	.byte 0x04
	.zero 3
	.byte 0xff
	.zero 3
	.asciz "HD-INFO"
	.zero 2
	.ascii "j"
	.byte 0x01
	.byte 0x27
	.byte 0x02
	.byte 0x2b
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii ")"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "H"
	.ascii "<"
	.byte 0x01
	.byte 0xdd  ; "Ý"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01, 0x02
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x9c  ; ""
	.asciz "#"
	.zero 4
	.byte 0x08
	.byte 0x9c  ; ""
	.asciz "#"
	.zero 2
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0x2a
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0x3c
	.byte 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "-"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x0a
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0x1a
	.asciz "9*"
	.byte 0x01
	.zero 3
	.asciz "DEBUG MEMO SCREEN"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x2c
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "."
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.byte 0x00
	.asciz "F"
	.ascii "`"
	.byte 0x01
	.byte 0x2c
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "-"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	.asciz "("
	.ascii "4"
	.byte 0x01
	.byte 0xe5  ; "å"
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "0"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x0e
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0x86  ; ""
	.asciz "9*"
	.zero 6
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x2f
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "1"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "9"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x2f
	.byte 0x02
	.byte 0x32
	.byte 0x02
	.byte 0x35
	.byte 0x02
	.byte 0x30
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz ","
	.byte 0x17, 0x01
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x05
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x31
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "3"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz ","
	.byte 0x9e  ; ""
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xcf  ; "Ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x31
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "4"
	.byte 0x02
	.byte 0x32
	.byte 0x02, 0x08
	.byte 0x00
	.asciz ","
	.asciz "L"
	.byte 0x13, 0x01
	.asciz "{"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0x0a
	.zero 3
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x31
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "3"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz ","
	.asciz "|"
	.byte 0x13, 0x01
	.byte 0x9f  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "<"
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0x2f
	.byte 0x02
	.byte 0x36
	.byte 0x02
	.byte 0x37
	.byte 0x02
	.byte 0x31
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.asciz "x:*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x35
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc8  ; "È"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0x2f
	.byte 0x02
	.byte 0x38
	.byte 0x02
	.byte 0x39
	.byte 0x02
	.byte 0x35
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.byte 0xd2  ; "Ò"
	.asciz ":*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x37
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc8  ; "È"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0x2f
	.byte 0x02
	.byte 0x3a
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "7"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz ",;*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x39
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "<"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x12
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0x82  ; ""
	.asciz ";*"
	.zero 6
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x3b
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "="
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x1a
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0x3b
	.byte 0x02
	.byte 0x3e
	.byte 0x02
	.byte 0x3f
	.byte 0x02
	.byte 0x3c
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.byte 0xcc  ; "Ì"
	.asciz ";*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x3d
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc8  ; "È"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0x3b
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "@"
	.byte 0x02
	.byte 0x3d
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz "&<*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x3b
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "A"
	.byte 0x02
	.byte 0x3f
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x3b
	.byte 0x02
	.byte 0x42
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "@"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "4"
	.byte 0x17, 0x01
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x41
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "C"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "\\"
	.byte 0x17, 0x01
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "C"
	.byte 0x07
	.zero 3
	.byte 0x0a
	.zero 3
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x41
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "B"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "E"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x16
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xfa  ; "ú"
	.asciz "<*"
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 2
	.asciz "EDIT FLS NAME"
	.asciz "M"
	.ascii "`"
	.byte 0x01
	.byte 0x44
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "F"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x44
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "G"
	.byte 0x02
	.byte 0x45
	.byte 0x02, 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.byte 0x00
	.ascii "c"
	.byte 0x01, 0x7f
	.byte 0x00
	.asciz " "
	.ascii "`"
	.byte 0x01
	.byte 0x44
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "H"
	.byte 0x02
	.byte 0x46
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0b
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x17
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.asciz " "
	.ascii "`"
	.byte 0x01
	.byte 0x44
	.byte 0x02
	.byte 0x49
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "G"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "v"
	.asciz "&"
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x8a  ; ""
	.byte 0x00
	.zero 2
	.byte 0x17
	.byte 0x00
	.byte 0x2a
	.byte 0x01
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x48
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.asciz "w"
	.asciz "$"
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0xb4  ; "´"
	.asciz "=*"
	.zero 4
	.byte 0xf9  ; "ù"
	.byte 0x00
	.asciz "LST"
	.byte 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "K"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x1a
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xe2  ; "â"
	.asciz "=*"
	.zero 6
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x4a
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "L"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "7"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0x4a
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "M"
	.byte 0x02
	.byte 0x4b
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz ",>*"
	.zero 2
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x4a
	.byte 0x02
	.byte 0x4e
	.byte 0x02
	.byte 0x50
	.byte 0x02
	.byte 0x4c
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "V>*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x4d
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "O"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "*"
	.asciz "x"
	.byte 0x1d, 0x01
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x1d
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x4d
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "N"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x1e
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x4a
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "Q"
	.byte 0x02
	.byte 0x4d
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "^"
	.byte 0x17, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x4a
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "P"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "S"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x1e
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "*?*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x52
	.byte 0x02
	.byte 0x54
	.byte 0x02
	.byte 0x55
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "T?*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x53
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "&"
	.asciz "|"
	.byte 0x19, 0x01
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x1f
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x52
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "V"
	.byte 0x02
	.byte 0x53
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x52
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "U"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "X"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x22
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xfe  ; "þ"
	.asciz "?*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x57
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "Y"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "(@*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x57
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "Z"
	.byte 0x02
	.byte 0x58
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "z"
	.byte 0x17, 0x01
	.byte 0xa1  ; "¡"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz " "
	.zero 4
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x57
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "["
	.byte 0x02
	.byte 0x59
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x57
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "Z"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "]"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x26
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xd2  ; "Ò"
	.asciz "@*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x5c
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "^"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xfc  ; "ü"
	.asciz "@*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x5c
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "_"
	.byte 0x02
	.byte 0x5d
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "z"
	.byte 0x17, 0x01
	.byte 0xa1  ; "¡"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "!"
	.zero 4
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x5c
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "`"
	.byte 0x02
	.byte 0x5e
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x5c
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "_"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "b"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x2a
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xa6  ; "¦"
	.asciz "A*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.ascii "a"
	.byte 0x02
	.ascii "c"
	.byte 0x02
	.ascii "d"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xd0  ; "Ð"
	.asciz "A*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "b"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "\""
	.asciz "|"
	.byte 0x15, 0x01
	.byte 0xa1  ; "¡"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "\""
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "a"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "e"
	.byte 0x02
	.ascii "b"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "a"
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "d"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "g"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x2e
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "zB*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.ascii "f"
	.byte 0x02
	.ascii "h"
	.byte 0x02
	.ascii "i"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xa4  ; "¤"
	.asciz "B*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "g"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "&"
	.asciz "|"
	.byte 0x19, 0x01
	.byte 0xa1  ; "¡"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "#"
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "f"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "j"
	.byte 0x02
	.ascii "g"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "f"
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "i"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "l"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x32
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "NC*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.ascii "k"
	.byte 0x02
	.ascii "m"
	.byte 0x02
	.ascii "n"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "xC*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "l"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "&"
	.asciz "x"
	.byte 0x19, 0x01
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "$"
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "k"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "o"
	.byte 0x02
	.ascii "l"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "k"
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "n"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "q"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x36
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "\"D*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.ascii "p"
	.byte 0x02
	.ascii "r"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "LD*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "q"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "s"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "q"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "t"
	.byte 0x02
	.ascii "r"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "q"
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "s"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "&"
	.asciz "x"
	.byte 0x19, 0x01
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "%"
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "v"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x3a
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xf6  ; "ö"
	.asciz "D*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.ascii "u"
	.byte 0x02
	.ascii "w"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz " E*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "v"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "x"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "v"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "y"
	.byte 0x02
	.ascii "w"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "v"
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "x"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "&"
	.asciz "x"
	.byte 0x19, 0x01
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "&"
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "{"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x3e
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xca  ; "Ê"
	.asciz "E*"
	.zero 6
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.ascii "z"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "|"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "8"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.ascii "z"
	.byte 0x02
	.byte 0x7d
	.byte 0x02
	.byte 0x7e
	.byte 0x02
	.byte 0x7b
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0x14
	.asciz "F*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x7c
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.ascii "z"
	.byte 0x02, 0x7f, 0x02
	.fill 2, 1, 0xff
	.ascii "|"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0xa8  ; "¨"
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "hF*"
	.byte 0x02
	.zero 7
	.byte 0x02
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x7e
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x80  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "^"
	.byte 0x17, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x7e
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x7f, 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "z"
	.byte 0x17, 0x01
	.byte 0x9f  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "'"
	.byte 0x07
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x82  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x42
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xe8  ; "è"
	.asciz "F*"
	.byte 0x01
	.zero 3
	.asciz "            "
	.byte 0x00
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.byte 0x81  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x83  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "L"
	.byte 0x01
	.byte 0x00
	.asciz "f"
	.byte 0x1b
	.byte 0x00
	.asciz "'"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x81  ; ""
	.byte 0x02
	.byte 0x84  ; ""
	.byte 0x02
	.byte 0x88  ; ""
	.byte 0x02
	.byte 0x82  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.asciz "D"
	.ascii "&"
	.byte 0x01
	.asciz "w"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "8G*"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x83  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x85  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1d
	.byte 0x00
	.asciz "E"
	.asciz " "
	.asciz "O"
	.asciz "ZG*"
	.byte 0x03
	.zero 7
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x83  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x86  ; ""
	.byte 0x02
	.byte 0x84  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1d
	.byte 0x00
	.asciz "T"
	.byte 0xe8  ; "è"
	.byte 0x00
	.asciz "f"
	.asciz "|G*"
	.zero 6

HDAE5000_Credits:	; 0x2A477C
	; Developer credits (Technosoft/KEY SOFT)
	.asciz "Technosoft, CH-Samstagern"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x83  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x87  ; ""
	.byte 0x02
	.byte 0x85  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1d
	.byte 0x00
	.asciz "d"
	.byte 0xe8  ; "è"
	.byte 0x00
	.asciz "v"
	.byte 0xb6  ; "¶"
	.asciz "G*"
	.zero 6
	.asciz "Pointstyle, CH-Buttisholz"
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x83  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x86  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.asciz "E"
	.byte 0x1e, 0x01
	.asciz "T"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x11
	.byte 0x00
	.byte 0x03
	.zero 5
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x81  ; ""
	.byte 0x02
	.byte 0x89  ; ""
	.byte 0x02
	.byte 0x8d  ; ""
	.byte 0x02
	.byte 0x83  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.asciz "x"
	.ascii "&"
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "\"H*"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x88  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x8a  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1d
	.byte 0x00
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x08, 0x01
	.byte 0x9b  ; ""
	.byte 0x00
	.asciz "DH*"
	.zero 6
	.asciz "KEY SOFT SERVICE, CH-Schenkon"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x88  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x8b  ; ""
	.byte 0x02
	.byte 0x89  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1d
	.byte 0x00
	.byte 0x9a  ; ""
	.byte 0x00
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x82  ; ""
	.asciz "H*"
	.byte 0x03
	.zero 5
	.asciz "Fax.  +41-41-922 03 15"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x88  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x8c  ; ""
	.byte 0x02
	.byte 0x8a  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1d
	.byte 0x00
	.byte 0xa5  ; "¥"
	.byte 0x00
	.byte 0xda  ; "Ú"
	.byte 0x00
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xba  ; "º"
	.asciz "H*"
	.byte 0x03
	.zero 5
	.asciz "email:keysoftservice@bluewin.ch"
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x88  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x8b  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.asciz "z"
	.byte 0x1e, 0x01
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x12
	.byte 0x00
	.byte 0x03
	.zero 5
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x81  ; ""
	.byte 0x02
	.byte 0x8e  ; ""
	.byte 0x02
	.byte 0x8f  ; ""
	.byte 0x02
	.byte 0x88  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.byte 0xb4  ; "´"
	.byte 0x00
	.byte 0x26
	.byte 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz ",I*"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x8d  ; ""
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0xb6  ; "¶"
	.byte 0x00
	.byte 0x26
	.byte 0x01
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x13
	.byte 0x00
	.byte 0x03
	.zero 5
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x81  ; ""
	.byte 0x02
	.byte 0x90  ; ""
	.byte 0x02
	.byte 0x92  ; ""
	.byte 0x02
	.byte 0x8d  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0x26
	.byte 0x01
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x80  ; ""
	.asciz "I*"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x91  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1d
	.byte 0x00
	.byte 0xda  ; "Ú"
	.byte 0x00
	.byte 0x21
	.byte 0x01
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xa2  ; "¢"
	.asciz "I*"
	.byte 0x05
	.zero 5
	.asciz "Mr. T.Hamaguchi and Mr. M.Kitajima"
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x90  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0xce  ; "Î"
	.byte 0x00
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xdd  ; "Ý"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x14
	.byte 0x00
	.byte 0x03
	.zero 5
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x81  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x93  ; ""
	.byte 0x02
	.byte 0x8f  ; ""
	.byte 0x02, 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x13
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x81  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x92  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "e"
	.zero 2
	.byte 0x18, 0x01, 0x1f
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x0a
	.byte 0x00
	.byte 0x09
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x95  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0x25
	.byte 0x01
	.asciz "Y"
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 2
	.ascii "F"
	.byte 0x9c  ; ""
	.asciz "#"
	.ascii "J"
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x94  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x96  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "\""
	.byte 0x17, 0x01
	.asciz "9"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz ";"
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x94  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x95  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.asciz " "
	.asciz ":"
	.ascii "#"
	.byte 0x01
	.asciz "Q"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "1"
	.byte 0x02
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x98  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x4e
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x97  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x9a  ; ""
	.byte 0x02
	.byte 0x98  ; ""
	.byte 0x02, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.asciz ">"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x97  ; ""
	.byte 0x02
	.byte 0x9b  ; ""
	.byte 0x02
	.byte 0x9c  ; ""
	.byte 0x02
	.byte 0x99  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x10
	.asciz "K*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x9a  ; ""
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "x"
	.byte 0x17, 0x01
	.byte 0xbf  ; "¿"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz ")"
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x04
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x97  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x9a  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "^"
	.byte 0x17, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x9e  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x52
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x9d  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xa0  ; " "
	.byte 0x02
	.byte 0x9e  ; ""
	.byte 0x02, 0x18
	.zero 3
	.asciz "$"
	.byte 0x1f
	.byte 0x00
	.asciz "C"
	.asciz ">"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x9d  ; ""
	.byte 0x02
	.byte 0xa1  ; "¡"
	.byte 0x02
	.byte 0xa2  ; "¢"
	.byte 0x02
	.byte 0x9f  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.asciz "K*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xa0  ; " "
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "^"
	.byte 0x17, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x9d  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xa0  ; " "
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "x"
	.byte 0x17, 0x01
	.byte 0xbf  ; "¿"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz ")"
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x04
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xa4  ; "¤"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x56
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xa3  ; "£"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xa5  ; "¥"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xa3  ; "£"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xa6  ; "¦"
	.byte 0x02
	.byte 0xa4  ; "¤"
	.byte 0x02, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.asciz ">"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xa3  ; "£"
	.byte 0x02
	.byte 0xa7  ; "§"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xa5  ; "¥"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x9e  ; ""
	.asciz "L*"
	.zero 8
	.byte 0x05
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xa6  ; "¦"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xa8  ; "¨"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "^"
	.byte 0x17, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xa6  ; "¦"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xa7  ; "§"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "|"
	.byte 0x17, 0x01
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "*"
	.byte 0x07
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x04
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xaa  ; "ª"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x5a
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xa9  ; "©"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xab  ; "«"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xa9  ; "©"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xac  ; "¬"
	.byte 0x02
	.byte 0xaa  ; "ª"
	.byte 0x02, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.asciz ">"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xa9  ; "©"
	.byte 0x02
	.byte 0xad  ; "­"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xab  ; "«"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "2"
	.byte 0x17, 0x01
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "rM*"
	.byte 0x02
	.zero 7
	.byte 0x04
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xac  ; "¬"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xae  ; "®"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "8"
	.byte 0x17, 0x01
	.asciz "O"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xac  ; "¬"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xaf  ; "¯"
	.byte 0x02
	.byte 0xad  ; "­"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "R"
	.byte 0x17, 0x01
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "+"
	.byte 0x07
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x04
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xac  ; "¬"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xae  ; "®"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0x98  ; ""
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz ","
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xb1  ; "±"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x5e
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xb0  ; "°"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xb2  ; "²"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xb0  ; "°"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xb3  ; "³"
	.byte 0x02
	.byte 0xb1  ; "±"
	.byte 0x02, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.asciz ">"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xb0  ; "°"
	.byte 0x02
	.byte 0xb4  ; "´"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xb2  ; "²"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "2"
	.byte 0x17, 0x01
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "pN*"
	.byte 0x02
	.zero 7
	.byte 0x04
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xb5  ; "µ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.byte 0x8c  ; ""
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcf  ; "Ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "."
	.zero 8
	.byte 0x04
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xb6  ; "¶"
	.byte 0x02
	.byte 0xb4  ; "´"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "8"
	.byte 0x17, 0x01
	.asciz "O"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xb5  ; "µ"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "-"
	.byte 0x07
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xb8  ; "¸"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.ascii "b"
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xb7  ; "·"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xb9  ; "¹"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xb7  ; "·"
	.byte 0x02
	.byte 0xba  ; "º"
	.byte 0x02
	.byte 0xbb  ; "»"
	.byte 0x02
	.byte 0xb8  ; "¸"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "TO*"
	.byte 0x02
	.zero 7
	.byte 0x02
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xb9  ; "¹"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "x"
	.byte 0x17, 0x01
	.byte 0x9f  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "/"
	.byte 0x07
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xb7  ; "·"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xb9  ; "¹"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "\\"
	.byte 0x17, 0x01
	.asciz "s"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xbd  ; "½"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.ascii "f"
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xbc  ; "¼"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xbe  ; "¾"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xbc  ; "¼"
	.byte 0x02
	.byte 0xbf  ; "¿"
	.byte 0x02
	.byte 0xc0  ; "À"
	.byte 0x02
	.byte 0xbd  ; "½"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x0e
	.asciz "P*"
	.byte 0x02
	.zero 7
	.byte 0x02
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xbe  ; "¾"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "\\"
	.byte 0x17, 0x01
	.asciz "s"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xbc  ; "¼"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xbe  ; "¾"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz ","
	.asciz "x"
	.byte 0x11, 0x01
	.byte 0x9f  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "0"
	.byte 0x07
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc2  ; "Â"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.ascii "j"
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xc1  ; "Á"
	.byte 0x02
	.byte 0xc3  ; "Ã"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "<"
	.asciz "T"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xae  ; "®"
	.asciz "P*"
	.byte 0x01
	.zero 7
	.byte 0x01
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "H"
	.asciz "b"
	.byte 0xf1  ; "ñ"
	.byte 0x00
	.asciz "y"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "1"
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc5  ; "Å"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.ascii "n"
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xc4  ; "Ä"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xc6  ; "Æ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x1a, 0x02, 0x7f
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xc4  ; "Ä"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xc7  ; "Ç"
	.byte 0x02
	.byte 0xc5  ; "Å"
	.byte 0x02, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.asciz ">"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xc4  ; "Ä"
	.byte 0x02
	.byte 0xc8  ; "È"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xc6  ; "Æ"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz " "
	.asciz "N"
	.byte 0x1f, 0x01
	.byte 0xe3  ; "ã"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "XQ*"
	.byte 0x02
	.zero 7
	.byte 0x05
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xc9  ; "É"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "t"
	.byte 0x17, 0x01
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "3"
	.zero 4
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xca  ; "Ê"
	.byte 0x02
	.byte 0xc8  ; "È"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.asciz "P"
	.ascii "!"
	.byte 0x01
	.asciz "s"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "2"
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xc9  ; "É"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xe3  ; "ã"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "4"
	.byte 0x07
	.zero 7
	.byte 0x04
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xcc  ; "Ì"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.ascii "r"
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xcd  ; "Í"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x1a, 0x02, 0x7f
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xce  ; "Î"
	.byte 0x02
	.byte 0xcc  ; "Ì"
	.byte 0x02, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.asciz ">"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x02
	.byte 0xcf  ; "Ï"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xcd  ; "Í"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz " "
	.asciz "N"
	.byte 0x1f, 0x01
	.byte 0xe3  ; "ã"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "VR*"
	.byte 0x02
	.zero 7
	.byte 0x05
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xce  ; "Î"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xd0  ; "Ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "\""
	.asciz "P"
	.ascii "%"
	.byte 0x01
	.asciz "s"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "5"
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xce  ; "Î"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xd1  ; "Ñ"
	.byte 0x02
	.byte 0xcf  ; "Ï"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "t"
	.byte 0x17, 0x01
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "6"
	.zero 4
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xce  ; "Î"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xd0  ; "Ð"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0x98  ; ""
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xdf  ; "ß"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "7"
	.byte 0x07
	.zero 7
	.byte 0x04
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd3  ; "Ó"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.ascii "v"
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0x00
	.asciz "S*"
	.zero 6
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xd4  ; "Ô"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "\""
	.byte 0x7f
	.byte 0x00
	.asciz "("
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xd5  ; "Õ"
	.byte 0x02
	.byte 0xd3  ; "Ó"
	.byte 0x02, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.byte 0x01
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x02, 0x7f
	.byte 0x00
	.asciz "("
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xd6  ; "Ö"
	.byte 0x02
	.byte 0xd4  ; "Ô"
	.byte 0x02, 0x18
	.zero 3
	.asciz "@"
	.byte 0x1f
	.byte 0x00
	.asciz "_"
	.byte 0x02
	.byte 0x00
	.byte 0x10, 0x01, 0x7f
	.byte 0x00
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xd7  ; "×"
	.byte 0x02
	.byte 0xd5  ; "Õ"
	.byte 0x02, 0x18
	.zero 3
	.asciz "`"
	.byte 0x1f
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x0d
	.byte 0x00
	.byte 0x4a
	.byte 0x01, 0x08
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xd6  ; "Ö"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x3b
	.byte 0x01, 0x17
	.byte 0x00
	.byte 0xf3  ; "ó"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.ascii "z"
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd9  ; "Ù"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 4
	.ascii "|"
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0x80, 0x9c  ; ""
	.asciz "#"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xda  ; "Ú"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz ","
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xdb  ; "Û"
	.byte 0x02
	.byte 0xd9  ; "Ù"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xdc  ; "Ü"
	.byte 0x02
	.byte 0xda  ; "Ú"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz ","
	.asciz "4"
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0x84, 0x9c  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.byte 0x88, 0x9c  ; ""
	.asciz "#"
	.zero 4
	.byte 0x8a, 0x9c  ; ""
	.asciz "#"
	.zero 2
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xdd  ; "Ý"
	.byte 0x02
	.byte 0xdb  ; "Û"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "-"
	.ascii "`"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xde  ; "Þ"
	.byte 0x02
	.byte 0xdc  ; "Ü"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "*"
	.zero 2
	.asciz "E"
	.byte 0x1b
	.byte 0x00
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xdf  ; "ß"
	.byte 0x02
	.byte 0xdd  ; "Ý"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "F"
	.byte 0x07
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.byte 0xa6  ; "¦"
	.asciz "T*"
	.byte 0x04
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "FILE SELECT A-Z"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xe0  ; "à"
	.byte 0x02
	.byte 0xde  ; "Þ"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "$"
	.ascii "7"
	.byte 0x01
	.asciz "="
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.asciz "0"
	.ascii "`"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xe1  ; "á"
	.byte 0x02
	.byte 0xdf  ; "ß"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.asciz "M"
	.ascii "?"
	.byte 0x01
	.asciz "_"
	.byte 0x06
	.asciz "U*"
	.zero 4
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x09
	.zero 3
	.ascii " "
	.byte 0x01, 0x06
	.byte 0x00
	.asciz "~80"
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xe2  ; "â"
	.byte 0x02
	.byte 0xe0  ; "à"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz "("
	.ascii "9"
	.byte 0x01
	.asciz "O"
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x01
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.byte 0xe3  ; "ã"
	.byte 0x02
	.byte 0xe5  ; "å"
	.byte 0x02
	.byte 0xe1  ; "á"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz ","
	.byte 0x1e
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.asciz "/"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0x8c, 0x9c  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x90, 0x9c  ; ""
	.asciz "#"
	.zero 4
	.byte 0x92, 0x9c  ; ""
	.asciz "#"
	.zero 2
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x02
	.byte 0xe4  ; "ä"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "N"
	.asciz " "
	.byte 0xed  ; "í"
	.byte 0x00
	.asciz "/"
	.byte 0x08
	.zero 3
	.byte 0x88  ; ""
	.asciz "U*"
	.byte 0x03
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "Evergreens slow / 12"
	.byte 0x00
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe3  ; "ã"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz ","
	.asciz " "
	.byte 0x7f
	.byte 0x00
	.asciz "/"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc6  ; "Æ"
	.asciz "U*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "LOC.:"
	.byte 0x10
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xe6  ; "æ"
	.byte 0x02
	.byte 0xe2  ; "â"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "<"
	.asciz "T"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.byte 0xe7  ; "ç"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xe5  ; "å"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.asciz "d"
	.ascii "?"
	.byte 0x01
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x0a
	.asciz "V*"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.zero 3
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xe8  ; "è"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xae  ; "®"
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0xbf  ; "¿"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "4V*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.byte 0x00

HDAE5000_Demo_Data:	; 0x2A5634
	; Demo song data and rhythm custom UI
	.asciz "RHYTHM CUSTOM"
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xe9  ; "é"
	.byte 0x02
	.byte 0xe7  ; "ç"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xba  ; "º"
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "jV*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.byte 0x00
	.asciz "USER MIDI"
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xea  ; "ê"
	.byte 0x02
	.byte 0xe8  ; "è"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x9c  ; ""
	.asciz "V*"
	.byte 0x03
	.zero 3
	.byte 0x0d
	.zero 3
	.byte 0x01
	.byte 0x00
	.asciz "TECH LYRICS"
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xeb  ; "ë"
	.byte 0x02
	.byte 0xe9  ; "é"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd0  ; "Ð"
	.asciz "V*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.byte 0x00
	.asciz "MSP"
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.byte 0xec  ; "ì"
	.byte 0x02
	.byte 0xed  ; "í"
	.byte 0x02
	.byte 0xea  ; "ê"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0x96  ; ""
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0xa7  ; "§"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xfc  ; "ü"
	.asciz "V*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.byte 0x00
	.asciz "SOUND MEMORY"
	.byte 0x00
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xeb  ; "ë"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0x8a  ; ""
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "2W*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.byte 0x00
	.asciz "COMPOSER"
	.byte 0x00
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xee  ; "î"
	.byte 0x02
	.byte 0xeb  ; "ë"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.asciz "~"
	.ascii "?"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "dW*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.byte 0x00
	.asciz "SEQUENCER"
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xef  ; "ï"
	.byte 0x02
	.byte 0xed  ; "í"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.asciz "r"
	.ascii "?"
	.byte 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x96  ; ""
	.asciz "W*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.byte 0x00
	.asciz "PANEL MEMORY"
	.byte 0x00
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xee  ; "î"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.asciz "f"
	.ascii "?"
	.byte 0x01
	.asciz "w"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xcc  ; "Ì"
	.asciz "W*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.byte 0x00
	.asciz "CURRENT PANEL"
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xf1  ; "ñ"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x94, 0x9c  ; ""
	.asciz "#"
	.byte 0x04
	.asciz "X*"
	.asciz "<"
	.zero 2
	.asciz "TECH LYRICS"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xf2  ; "ò"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.byte 0x00
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.byte 0xf3  ; "ó"
	.byte 0x02
	.byte 0xf4  ; "ô"
	.byte 0x02
	.byte 0xf1  ; "ñ"
	.byte 0x02, 0x08
	.zero 3
	.asciz "!"
	.ascii "?"
	.byte 0x01
	.asciz "8"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "RX*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf2  ; "ò"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "\""
	.ascii "?"
	.byte 0x01
	.asciz "7"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x05
	.zero 3
	.byte 0xff
	.zero 3
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.byte 0xf5  ; "õ"
	.byte 0x02
	.byte 0xf6  ; "ö"
	.byte 0x02
	.byte 0xf2  ; "ò"
	.byte 0x02, 0x08
	.zero 3
	.asciz "8"
	.ascii "?"
	.byte 0x01
	.asciz "I"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xa0  ; " "
	.asciz "X*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf4  ; "ô"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "9"
	.ascii "?"
	.byte 0x01
	.asciz "G"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xf7  ; "÷"
	.byte 0x02
	.byte 0xf4  ; "ô"
	.byte 0x02, 0x08
	.zero 3
	.byte 0xe0  ; "à"
	.byte 0x00
	.asciz "'"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xf8  ; "ø"
	.byte 0x02
	.byte 0xf6  ; "ö"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0xe0  ; "à"
	.byte 0x00
	.asciz "O"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xf9  ; "ù"
	.byte 0x02
	.byte 0xf7  ; "÷"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "P"
	.byte 0xe0  ; "à"
	.byte 0x00
	.asciz "w"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xfa  ; "ú"
	.byte 0x02
	.byte 0xf8  ; "ø"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "x"
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0x9f  ; ""
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xfb  ; "û"
	.byte 0x02
	.byte 0xf9  ; "ù"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xfc  ; "ü"
	.byte 0x02
	.byte 0xfa  ; "ú"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xc8  ; "È"
	.byte 0x00
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xfd  ; "ý"
	.byte 0x02
	.byte 0xfb  ; "û"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xfe  ; "þ"
	.byte 0x02
	.byte 0xfc  ; "ü"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x18, 0x01
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.byte 0xff
	.byte 0x02, 0x03, 0x03
	.byte 0xfd  ; "ý"
	.byte 0x02, 0x08
	.zero 3
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x0e
	.asciz "Z*"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.zero 3
	.byte 0x0b
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xfe  ; "þ"
	.byte 0x02, 0x08
	.zero 3
	.asciz "K"
	.ascii "?"
	.byte 0x01
	.byte 0xce  ; "Î"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x98, 0x9c  ; ""
	.asciz "#"
	.byte 0x07
	.zero 3
	.byte 0xfc  ; "ü"
	.byte 0x00
	.byte 0x0d
	.byte 0x00
	.byte 0x03
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x05, 0x03
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.zero 6
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x9a, 0x9c  ; ""
	.asciz "#"
	.asciz "hZ*"
	.asciz "'"
	.zero 2
	.asciz "LOAD LYRICS FROM FD"
	.asciz "I"
	.ascii "`"
	.byte 0x01, 0x04, 0x03
	.fill 2, 1, 0xff
	.byte 0x06, 0x03
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x02, 0x7f
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x04, 0x03
	.fill 2, 1, 0xff
	.byte 0x07, 0x03, 0x05, 0x03, 0x08
	.byte 0x00
	.byte 0x1c
	.byte 0x00
	.byte 0xe1  ; "á"
	.byte 0x00
	.asciz "7"
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xb6  ; "¶"
	.asciz "Z*"
	.byte 0x03
	.zero 5
	.asciz "Info"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x04, 0x03
	.fill 2, 1, 0xff
	.byte 0x08, 0x03, 0x06, 0x03, 0x08
	.byte 0x00
	.byte 0x06, 0x01
	.byte 0xe1  ; "á"
	.byte 0x00
	.byte 0x21
	.byte 0x01
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.asciz "Z*"
	.byte 0x03
	.zero 5
	.asciz "Load"
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x04, 0x03
	.fill 4, 1, 0xff
	.byte 0x07, 0x03, 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x9e, 0x9c  ; ""
	.asciz "#"
	.byte 0xa0, 0x9c  ; " "
	.asciz "#"
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x0a, 0x03
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xa2, 0x9c  ; "¢"
	.asciz "#"
	.asciz ",[*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01, 0x09, 0x03, 0x0b, 0x03
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "<"
	.asciz "T"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.asciz "V[*"
	.byte 0x01
	.zero 7
	.byte 0x01
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x0a, 0x03
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "H"
	.asciz "b"
	.byte 0xf1  ; "ñ"
	.byte 0x00
	.asciz "y"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "1"
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x0d, 0x03
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xa6, 0x9c  ; "¦"
	.asciz "#"
	.byte 0xac  ; "¬"
	.asciz "[*"
	.asciz "<"
	.zero 2
	.asciz "LYRICS OPTIONS"
	.byte 0x00
	.asciz "I"
	.ascii "`"
	.byte 0x01, 0x0c, 0x03
	.fill 2, 1, 0xff
	.byte 0x0e, 0x03
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x13
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x0c, 0x03, 0x0f, 0x03, 0x10, 0x03, 0x0d, 0x03, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "H"
	.byte 0xc5  ; "Å"
	.byte 0x00
	.asciz "a"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.byte 0x10
	.asciz "\\*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xaa, 0x9c  ; "ª"
	.asciz "#"
	.asciz "B"
	.ascii "*"
	.byte 0x01
	.byte 0xac, 0x9c  ; "¬"
	.asciz "#"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x0e, 0x03
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "H"
	.byte 0x8e  ; ""
	.byte 0x00
	.asciz "g"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "@"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x0c, 0x03, 0x11, 0x03, 0x12, 0x03, 0x0e, 0x03, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "r"
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.asciz "v\\*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x8a  ; ""
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xb0, 0x9c  ; "°"
	.asciz "#"
	.asciz "C"
	.ascii "*"
	.byte 0x01
	.byte 0xb2, 0x9c  ; "²"
	.asciz "#"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x10, 0x03
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "r"
	.byte 0x8e  ; ""
	.byte 0x00
	.byte 0x91  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "A"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x0c, 0x03
	.fill 2, 1, 0xff
	.byte 0x13, 0x03, 0x10, 0x03, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.byte 0xdc  ; "Ü"
	.asciz "\\*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xb6, 0x9c  ; "¶"
	.asciz "#"
	.asciz "D"
	.ascii "*"
	.byte 0x01
	.byte 0xb8, 0x9c  ; "¸"
	.asciz "#"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x0c, 0x03
	.fill 4, 1, 0xff
	.byte 0x12, 0x03, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x8e  ; ""
	.byte 0x00
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "B"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 8, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.asciz "p"
	.ascii "3"
	.byte 0x01
	.byte 0xdf  ; "ß"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.byte 0xbc, 0x9c  ; "¼"
	.asciz "#"
	.byte 0xc0, 0x9c  ; "À"
	.asciz "#"

HDAE5000_GFX_DATA_1:	; 0x2A5D2C
	; Graphics data block 1
	.incbin "includes/code_29af2d_2fffff.bin", 44543, 3160

HDAE5000_GFX_DATA_2:	; 0x2A6984
	; Graphics data block 2
	.incbin "includes/code_29af2d_2fffff.bin", 47703, 6934

HDAE5000_GFX_INIT_PARAMS:	; 0x2A849A
	; Graphics initialization parameters
	.incbin "includes/code_29af2d_2fffff.bin", 54637, 72972

HDAE5000_Font_Data:	; 0x2BA1A6
	; Font bitmap data (large block)
	.incbin "includes/code_29af2d_2fffff.bin", 127609, 162524

HDAE5000_Config_Strings:	; 0x2E1C82
	; Configuration and version strings
	.asciz "V2.06i"
	.zero 3
	.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
	.zero 23
	.ascii "   "
	.byte 0x09
	.zero 2
	.ascii "                "
	.byte 0x09
	.byte 0x00
	.ascii "   "
	.byte 0x09
	.zero 2
	.ascii "                          "
	.byte 0x09
	.byte 0x00
	.ascii "            "
	.byte 0x09
	.byte 0x00
	.ascii "01:        "
	.byte 0x09
	.ascii "02:        "
	.byte 0x09
	.ascii "03:        "
	.byte 0x09
	.ascii "04:        "
	.byte 0x09
	.ascii "05:        "
	.byte 0x09
	.ascii "06:        "
	.byte 0x09
	.ascii "07:        "
	.byte 0x09
	.ascii "08:        "
	.byte 0x09
	.ascii "09:        "
	.byte 0x09
	.ascii "10:        "
	.byte 0x09
	.ascii "11:        "
	.byte 0x09
	.ascii "12:        "
	.byte 0x09
	.ascii "13:        "
	.byte 0x09
	.ascii "14:        "
	.byte 0x09
	.ascii "15:        "
	.byte 0x09
	.ascii "16:        "
	.byte 0x09
	.ascii "17:        "
	.byte 0x09
	.ascii "18:        "
	.byte 0x09
	.ascii "19:        "
	.byte 0x09
	.ascii "20:        "
	.byte 0x09
	.zero 2
	.ascii "STATUS:                        "
	.byte 0x09
	.zero 14
	.ascii "("
	.byte 0x1e
	.asciz "."
	.ascii "$"
	.byte 0x1e
	.asciz "."
	.ascii " "
	.byte 0x1e
	.asciz "."
	.asciz "DEL"
	.asciz "OFF"
	.asciz "---"
	.asciz "050354"
	.byte 0x00
	.asciz "965768"
	.byte 0x00
	.byte 0x48
	.byte 0x1e
	.asciz "."
	.ascii "D"
	.byte 0x1e
	.asciz "."
	.asciz "ON "
	.asciz "OFF"
	.ascii "P"
	.byte 0x1e
	.asciz "."
	.ascii "01:SelectList"
	.byte 0x09
	.byte 0x30, 0x32
	.byte 0x09
	.byte 0x30, 0x33
	.byte 0x09
	.byte 0x30, 0x34
	.byte 0x09
	.byte 0x30, 0x35
	.byte 0x09
	.byte 0x30, 0x36
	.byte 0x09
	.byte 0x30, 0x37
	.byte 0x09
	.byte 0x30, 0x38
	.byte 0x09
	.byte 0x30, 0x39
	.byte 0x09
	.byte 0x31, 0x30
	.byte 0x09
	.byte 0x31, 0x31
	.byte 0x09
	.byte 0x31, 0x32
	.byte 0x09
	.byte 0x31, 0x33
	.byte 0x09
	.byte 0x31, 0x34
	.byte 0x09
	.byte 0x31, 0x35
	.byte 0x09
	.byte 0x31, 0x36
	.byte 0x09
	.byte 0x31, 0x37
	.byte 0x09
	.byte 0x31, 0x38
	.byte 0x09
	.byte 0x31, 0x39
	.byte 0x09
	.byte 0x32, 0x30
	.byte 0x09
	.byte 0x32, 0x31
	.byte 0x09
	.byte 0x32, 0x32
	.byte 0x09
	.byte 0x32, 0x33
	.byte 0x09
	.byte 0x32, 0x34
	.byte 0x09
	.byte 0x32, 0x35
	.byte 0x09
	.byte 0x32, 0x36
	.byte 0x09
	.byte 0x32, 0x37
	.byte 0x09
	.byte 0x32, 0x38
	.byte 0x09
	.byte 0x32, 0x39
	.byte 0x09
	.asciz "30"
	.byte 0x00
	.asciz "Debug Time!"
	.byte 0xea  ; "ê"
	.byte 0x1e
	.asciz "."
	.byte 0xdc  ; "Ü"
	.byte 0x1e
	.asciz "."
	.byte 0xce  ; "Î"
	.byte 0x1e
	.asciz "."
	.asciz " !#$%&?.... "
	.byte 0x00
	.asciz "abc...123..."
	.byte 0x00
	.asciz "ABC...123..."
	.byte 0x00
	.byte 0xe2  ; "â"
	.byte 0x1f
	.asciz "."
	.byte 0xe0  ; "à"
	.byte 0x1f
	.asciz "."
	.byte 0xde  ; "Þ"
	.byte 0x1f
	.asciz "."
	.byte 0xdc  ; "Ü"
	.byte 0x1f
	.asciz "."
	.byte 0xda  ; "Ú"
	.byte 0x1f
	.asciz "."
	.byte 0xd8  ; "Ø"
	.byte 0x1f
	.asciz "."
	.byte 0xd6  ; "Ö"
	.byte 0x1f
	.asciz "."
	.byte 0xd4  ; "Ô"
	.byte 0x1f
	.asciz "."
	.byte 0xd2  ; "Ò"
	.byte 0x1f
	.asciz "."
	.byte 0xd0  ; "Ð"
	.byte 0x1f
	.asciz "."
	.byte 0xce  ; "Î"
	.byte 0x1f
	.asciz "."
	.byte 0xcc  ; "Ì"
	.byte 0x1f
	.asciz "."
	.byte 0xca  ; "Ê"
	.byte 0x1f
	.asciz "."
	.byte 0xc8  ; "È"
	.byte 0x1f
	.asciz "."
	.byte 0xc6  ; "Æ"
	.byte 0x1f
	.asciz "."
	.byte 0xc4  ; "Ä"
	.byte 0x1f
	.asciz "."
	.byte 0xc2  ; "Â"
	.byte 0x1f
	.asciz "."
	.byte 0xc0  ; "À"
	.byte 0x1f
	.asciz "."
	.byte 0xbe  ; "¾"
	.byte 0x1f
	.asciz "."
	.byte 0xbc  ; "¼"
	.byte 0x1f
	.asciz "."
	.byte 0xba  ; "º"
	.byte 0x1f
	.asciz "."
	.byte 0xb8  ; "¸"
	.byte 0x1f
	.asciz "."
	.byte 0xb6  ; "¶"
	.byte 0x1f
	.asciz "."
	.byte 0xb4  ; "´"
	.byte 0x1f
	.asciz "."
	.byte 0xb2  ; "²"
	.byte 0x1f
	.asciz "."
	.byte 0xb0  ; "°"
	.byte 0x1f
	.asciz "."
	.byte 0xae  ; "®"
	.byte 0x1f
	.asciz "."
	.byte 0xac  ; "¬"
	.byte 0x1f
	.asciz "."
	.byte 0xaa  ; "ª"
	.byte 0x1f
	.asciz "."
	.byte 0xa8  ; "¨"
	.byte 0x1f
	.asciz "."
	.byte 0xa6  ; "¦"
	.byte 0x1f
	.asciz "."
	.byte 0xa4  ; "¤"
	.byte 0x1f
	.asciz "."
	.byte 0xa2  ; "¢"
	.byte 0x1f
	.asciz "."
	.byte 0xa0  ; " "
	.byte 0x1f
	.asciz "."
	.byte 0x9e  ; ""
	.byte 0x1f
	.asciz "."
	.byte 0x9c  ; ""
	.byte 0x1f
	.asciz "."
	.byte 0x9a  ; ""
	.byte 0x1f
	.asciz "."
	.byte 0x96  ; ""
	.byte 0x1f
	.asciz "."
	.byte 0x94  ; ""
	.byte 0x1f
	.asciz "."
	.zero 2
	.asciz "SPC"
	.asciz "9"
	.asciz "8"
	.asciz "7"
	.asciz "6"
	.asciz "5"
	.asciz "4"
	.asciz "3"
	.asciz "2"
	.asciz "1"
	.asciz "0"
	.asciz "_"
	.asciz "Z"
	.asciz "Y"
	.asciz "X"
	.asciz "W"
	.asciz "V"
	.asciz "U"
	.asciz "T"
	.asciz "S"
	.asciz "R"
	.asciz "Q"
	.asciz "P"
	.asciz "O"
	.asciz "N"
	.asciz "M"
	.asciz "L"
	.asciz "K"
	.asciz "J"
	.asciz "I"
	.asciz "H"
	.asciz "G"
	.asciz "F"
	.asciz "E"
	.asciz "D"
	.asciz "C"
	.asciz "B"
	.asciz "A"
	.byte 0xce  ; "Î"
	.asciz " ."
	.byte 0xcc  ; "Ì"
	.asciz " ."
	.byte 0xca  ; "Ê"
	.asciz " ."
	.byte 0xc8  ; "È"
	.asciz " ."
	.byte 0xc6  ; "Æ"
	.asciz " ."
	.byte 0xc4  ; "Ä"
	.asciz " ."
	.byte 0xc2  ; "Â"
	.asciz " ."
	.byte 0xc0  ; "À"
	.asciz " ."
	.byte 0xbe  ; "¾"
	.asciz " ."
	.byte 0xbc  ; "¼"
	.asciz " ."
	.byte 0xba  ; "º"
	.asciz " ."
	.byte 0xb8  ; "¸"
	.asciz " ."
	.byte 0xb6  ; "¶"
	.asciz " ."
	.byte 0xb4  ; "´"
	.asciz " ."
	.byte 0xb2  ; "²"
	.asciz " ."
	.byte 0xb0  ; "°"
	.asciz " ."
	.byte 0xae  ; "®"
	.asciz " ."
	.byte 0xac  ; "¬"
	.asciz " ."
	.byte 0xaa  ; "ª"
	.asciz " ."
	.byte 0xa8  ; "¨"
	.asciz " ."
	.byte 0xa6  ; "¦"
	.asciz " ."
	.byte 0xa4  ; "¤"
	.asciz " ."
	.byte 0xa2  ; "¢"
	.asciz " ."
	.byte 0xa0  ; " "
	.asciz " ."
	.byte 0x9e  ; ""
	.asciz " ."
	.byte 0x9c  ; ""
	.asciz " ."
	.byte 0x9a  ; ""
	.asciz " ."
	.byte 0x98  ; ""
	.asciz " ."
	.byte 0x96  ; ""
	.asciz " ."
	.byte 0x94  ; ""
	.asciz " ."
	.byte 0x92  ; ""
	.asciz " ."
	.byte 0x90  ; ""
	.asciz " ."
	.byte 0x8e  ; ""
	.asciz " ."
	.byte 0x8c  ; ""
	.asciz " ."
	.byte 0x8a  ; ""
	.asciz " ."
	.byte 0x88  ; ""
	.asciz " ."
	.byte 0x86  ; ""
	.asciz " ."
	.byte 0x82  ; ""
	.asciz " ."
	.byte 0x80  ; ""
	.asciz " ."
	.zero 2
	.asciz "SPC"
	.asciz "9"
	.asciz "8"
	.asciz "7"
	.asciz "6"
	.asciz "5"
	.asciz "4"
	.asciz "3"
	.asciz "2"
	.asciz "1"
	.asciz "0"
	.asciz "_"
	.asciz "z"
	.asciz "y"
	.asciz "x"
	.asciz "w"
	.asciz "v"
	.asciz "u"
	.asciz "t"
	.asciz "s"
	.asciz "r"
	.asciz "q"
	.asciz "p"
	.asciz "o"
	.asciz "n"
	.asciz "m"
	.asciz "l"
	.asciz "k"
	.asciz "j"
	.asciz "i"
	.asciz "h"
	.asciz "g"
	.asciz "f"
	.asciz "e"
	.asciz "d"
	.asciz "c"
	.asciz "b"
	.asciz "a"
	.byte 0xa0  ; " "
	.asciz "!."
	.byte 0x9e  ; ""
	.asciz "!."
	.byte 0x9c  ; ""
	.asciz "!."
	.byte 0x9a  ; ""
	.asciz "!."
	.byte 0x98  ; ""
	.asciz "!."
	.byte 0x96  ; ""
	.asciz "!."
	.byte 0x92  ; ""
	.asciz "!."
	.byte 0x8e  ; ""
	.asciz "!."
	.byte 0x8c  ; ""
	.asciz "!."
	.byte 0x8a  ; ""
	.asciz "!."
	.byte 0x86  ; ""
	.asciz "!."
	.byte 0x82  ; ""
	.asciz "!."
	.byte 0x80  ; ""
	.asciz "!."
	.asciz "~!."
	.asciz "|!."
	.asciz "z!."
	.asciz "x!."
	.asciz "v!."
	.asciz "t!."
	.asciz "r!."
	.asciz "p!."
	.asciz "n!."
	.asciz "j!."
	.asciz "f!."
	.asciz "d!."
	.asciz "b!."
	.asciz "`!."
	.asciz "^!."
	.asciz "\\!."
	.asciz "Z!."
	.asciz "X!."
	.asciz "V!."
	.asciz "T!."
	.zero 2
	.asciz "}"
	.asciz "{"
	.asciz "]"
	.asciz "["
	.asciz ">"
	.asciz "<"
	.asciz ")"
	.asciz "("
	.asciz "~8d"
	.asciz "~8b"
	.asciz "="
	.asciz "/"
	.asciz "*"
	.asciz "-"
	.asciz "+"
	.asciz ";"
	.asciz ":"
	.asciz "."
	.asciz ","
	.asciz "`"
	.asciz "~27"
	.asciz "~22"
	.asciz "|"
	.asciz "^"
	.asciz "~5c"
	.asciz "~40"
	.asciz "?"
	.asciz "&"
	.asciz "%"
	.asciz "$"
	.asciz "#"
	.asciz "!"
	.byte 0xf8  ; "ø"
	.byte 0x1e
	.asciz "."
	.byte 0xe4  ; "ä"
	.byte 0x1f
	.asciz "."
	.byte 0xd0  ; "Ð"
	.asciz " ."
	.asciz "%"
	.asciz "%"
	.byte 0x1f
	.byte 0x00
	.asciz "$"
	.asciz "$"
	.byte 0x1f
	.byte 0x00
	.byte 0xc4  ; "Ä"
	.asciz "!."
	.byte 0xc2  ; "Â"
	.asciz "!."
	.asciz "_"
	.asciz " "
	.zero 2
	.asciz "L"
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0x5b
	.byte 0x01
	.byte 0xb7  ; "·"
	.byte 0x03
	.byte 0xb5  ; "µ"
	.byte 0x04
	.byte 0x44
	.byte 0x05
	.byte 0xd3  ; "Ó"
	.byte 0x05
	.byte 0x5b
	.byte 0x07

HDAE5000_Test_Strings:	; 0x2E21D8
	; PPORT test and debug strings
	.asciz "Name"
	.byte 0x00
	.asciz "Test"
	.byte 0x00
	.asciz "PPORT TEST"
	.byte 0x00
	.asciz "HDD ID READ"
	.asciz "FD TEST"
	.asciz "OK"
	.byte 0x00
	.asciz "ERROR"
	.asciz "ERROR"
	.asciz "STOP TEST LOOP"
	.byte 0x00
	.asciz "START TEST LOOP"
	.asciz "=======> Port Test OK"
	.asciz "=======> Port Test Error"
	.byte 0x00
	.asciz "HD-TYPE : "
	.byte 0x00
	.asciz "Fre Capa: %3.1f [MB]"
	.zero 3
	.asciz "=======> HDD OK"
	.asciz "=======> HDD NG!"
	.zero 3
	.byte 0xc8  ; "È"
	.asciz "B%2.2d"
	.asciz "*.*"
	.asciz "CpHD"
	.byte 0x00
	.asciz "CpHD"
	.byte 0x00
	.ascii "WRITE PROTECTION   :ON     QUICK LOAD MODE:     1"
	.byte 0x09
	.ascii "WRITE CONFIRM      :OFF    JUMP AFTER LOAD:     2"
	.byte 0x09
	.ascii "LOAD BY NUMBER MODE:  1    FREE HDD SPACE :1251MB"
	.byte 0x09
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%s"
	.byte 0x00
	.asciz "  %d"
	.byte 0x00
	.asciz "     %d"
	.asciz "     %d"
	.asciz "%4ldMB"
	.byte 0x00
	.asciz "HDAE"
	.zero 3
	.byte 0x7f
	.byte 0x00
	.byte 0x52
	.byte 0x02, 0x7f
	.byte 0x00
	.byte 0x57
	.byte 0x02, 0x7f
	.byte 0x00
	.byte 0x5c
	.byte 0x02, 0x7f
	.byte 0x00
	.ascii "a"
	.byte 0x02, 0x7f
	.byte 0x00
	.ascii "f"
	.byte 0x02, 0x7f
	.byte 0x00
	.ascii "k"
	.byte 0x02, 0x7f
	.byte 0x00
	.ascii "p"
	.byte 0x02, 0x7f
	.byte 0x00
	.ascii "u"
	.byte 0x02, 0x7f
	.zero 3
	.byte 0xc0  ; "À"
	.byte 0x01
	.byte 0xc0  ; "À"
	.byte 0x01
	.byte 0xc0  ; "À"
	.byte 0x01
	.byte 0xa6  ; "¦"
	.byte 0x01
	.byte 0xc0  ; "À"
	.byte 0x01
	.byte 0x37
	.byte 0x01
	.byte 0xfe  ; "þ"
	.byte 0x00
	.ascii "   :                "
	.byte 0x09
	.byte 0x00
	.asciz "%3.3d"
	.ascii "CURRENT PANEL"
	.byte 0x09
	.ascii " PANEL MEMORY"
	.byte 0x09
	.ascii "  SEQUENCER  "
	.byte 0x09
	.ascii "  COMPOSER   "
	.byte 0x09
	.ascii " SOUND MEMORY"
	.byte 0x09
	.ascii "     MSP     "
	.byte 0x09
	.ascii "RHYTHM CUSTOM"
	.byte 0x09
	.ascii "  USER MIDI  "
	.byte 0x09
	.ascii "    LYRICS   "
	.byte 0x09
	.zero 2
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.zero 2
	.ascii "             "
	.byte 0x09
	.zero 2
	.byte 0x04, 0x01, 0x7f
	.byte 0x00
	.byte 0x5b
	.byte 0x01, 0x7f
	.byte 0x00
	.byte 0x03, 0x01, 0x7f
	.byte 0x00
	.byte 0x5c
	.byte 0x01, 0x7f
	.byte 0x00
	.byte 0x02, 0x01, 0x7f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x7f
	.byte 0x00

HDAE5000_Dir_Strings:	; 0x2E2500
	; Directory management strings
	.asciz "DIRECTORY "
	.byte 0x00
	.asciz "%2.2d"
	.asciz ":"
	.byte 0x09
	.byte 0x00
	.ascii ":                          "
	.byte 0x09
	.zero 2
	.asciz "%2.2d"
	.byte 0x15, 0x01
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0x51
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01
	.asciz " "
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0xb7  ; "·"
	.byte 0x00
	.byte 0x83  ; ""
	.byte 0x00
	.asciz "DELD"
	.byte 0x00
	.asciz "DELF"
	.byte 0x00
	.asciz "UTIL"
	.byte 0x00
	.asciz "---[ LSW File Info. ]---"
	.byte 0x00
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ SDA File Info. ]---"
	.byte 0x00
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ PMT File Info. ]---"
	.byte 0x00
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ SQF File Info. ]---"
	.byte 0x00
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ SEQ File Info. ]---"
	.byte 0x00
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ CMP File Info. ]---"
	.byte 0x00
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ TM File Info. ]---"
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ MSP File Info. ]---"
	.byte 0x00
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ RCM File Info. ]---"
	.byte 0x00
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ MD File Info. ]---"
	.asciz "adr  : "
	.asciz "size : "
	.asciz "PCLK"
	.byte 0x00
	.asciz "PORT IS ACTIVE"
	.byte 0x00
	.asciz "              "
	.byte 0x00
	.byte 0xb0  ; "°"
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xb0  ; "°"
	.byte 0x00
	.byte 0x9d  ; ""
	.byte 0x00
	.asciz "v'."
	.asciz "f'."
	.asciz "V'."
	.asciz "F'."
	.asciz "BASS/DRUMS MONO"
	.asciz "BASS+DRUMS MIX "
	.asciz "   DRUMS L/R   "
	.asciz "      OFF      "
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "i"
	.asciz "i"
	.asciz "i"
	.asciz "-"
	.asciz "1"
	.asciz "5"
	.asciz "<"
	.zero 2
	.asciz "B(."
	.asciz "<(."
	.asciz "6(."
	.asciz "0(."
	.asciz "*(."
	.asciz "$(."
	.byte 0x1e
	.asciz "(."
	.byte 0x18
	.asciz "(."
	.byte 0x12
	.asciz "(."
	.byte 0x0c
	.asciz "(."
	.byte 0x06
	.asciz "(."
	.byte 0x00
	.asciz "(."
	.byte 0xfa  ; "ú"
	.asciz "'."
	.byte 0xf4  ; "ô"
	.asciz "'."
	.byte 0xee  ; "î"
	.asciz "'."
	.byte 0xe8  ; "è"
	.asciz "'."
	.byte 0xe2  ; "â"
	.asciz "'."
	.asciz " 16 "
	.byte 0x00
	.asciz " 15 "
	.byte 0x00
	.asciz " 14 "
	.byte 0x00
	.asciz " 13 "
	.byte 0x00
	.asciz " 12 "
	.byte 0x00
	.asciz " 11 "
	.byte 0x00
	.asciz " 10 "
	.byte 0x00
	.asciz "  9 "
	.byte 0x00
	.asciz "  8 "
	.byte 0x00
	.asciz "  7 "
	.byte 0x00
	.asciz "  6 "
	.byte 0x00
	.asciz "  5 "
	.byte 0x00
	.asciz "  4 "
	.byte 0x00
	.asciz "  3 "
	.byte 0x00
	.asciz "  2 "
	.byte 0x00
	.asciz "  1 "
	.byte 0x00
	.asciz "NONE"
	.byte 0x00
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "l"
	.asciz "l"
	.asciz "l"
	.asciz "-"
	.asciz "4"
	.asciz "8"
	.asciz "?"
	.zero 2
	.byte 0x04
	.asciz ")."
	.byte 0xfe  ; "þ"
	.asciz "(."
	.byte 0xf8  ; "ø"
	.asciz "(."
	.byte 0xf2  ; "ò"
	.asciz "(."
	.byte 0xec  ; "ì"
	.asciz "(."
	.byte 0xe6  ; "æ"
	.asciz "(."
	.byte 0xe0  ; "à"
	.asciz "(."
	.byte 0xda  ; "Ú"
	.asciz "(."
	.byte 0xd4  ; "Ô"
	.asciz "(."
	.byte 0xce  ; "Î"
	.asciz "(."
	.byte 0xc8  ; "È"
	.asciz "(."
	.byte 0xc2  ; "Â"
	.asciz "(."
	.byte 0xbc  ; "¼"
	.asciz "(."
	.byte 0xb6  ; "¶"
	.asciz "(."
	.byte 0xb0  ; "°"
	.asciz "(."
	.byte 0xaa  ; "ª"
	.asciz "(."
	.byte 0xa4  ; "¤"
	.asciz "(."
	.asciz " 16 "
	.byte 0x00
	.asciz " 15 "
	.byte 0x00
	.asciz " 14 "
	.byte 0x00
	.asciz " 13 "
	.byte 0x00
	.asciz " 12 "
	.byte 0x00
	.asciz " 11 "
	.byte 0x00
	.asciz " 10 "
	.byte 0x00
	.asciz "  9 "
	.byte 0x00
	.asciz "  8 "
	.byte 0x00
	.asciz "  7 "
	.byte 0x00
	.asciz "  6 "
	.byte 0x00
	.asciz "  5 "
	.byte 0x00
	.asciz "  4 "
	.byte 0x00
	.asciz "  3 "
	.byte 0x00
	.asciz "  2 "
	.byte 0x00
	.asciz "  1 "
	.byte 0x00
	.asciz "NONE"
	.byte 0x00
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "l"
	.asciz "l"
	.asciz "l"
	.asciz "-"
	.asciz "4"
	.asciz "8"
	.asciz "?"
	.zero 2
	.asciz "6)."
	.asciz "2)."
	.asciz ".)."
	.asciz "YES"
	.asciz "NO "
	.asciz "---"
	.asciz "%s"
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "B"
	.asciz "B"
	.asciz "B"
	.asciz "#"
	.asciz "'"
	.asciz "+"
	.asciz "2"
	.zero 2
	.asciz "SVOP"
	.byte 0x00
	.asciz "%s"
	.byte 0x00
	.asciz "'"
	.asciz "+"
	.asciz "F"
	.asciz "F"
	.asciz "F"
	.asciz "/"
	.asciz "3"
	.asciz "7"
	.asciz ">"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "0"
	.asciz "4"
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x00
	.asciz "8"
	.asciz "F"
	.asciz "s"
	.asciz "z"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz "%"
	.asciz "J"
	.asciz "J"
	.asciz "J"
	.asciz ")"
	.asciz "-"
	.asciz "1"
	.asciz "8"
	.zero 2
	.asciz "%1d"
	.byte 0x19
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.asciz "4"
	.asciz "4"
	.asciz "4"
	.byte 0x1d
	.byte 0x00
	.asciz "!"
	.asciz "%"
	.asciz ","
	.zero 2
	.asciz "%1d"
	.byte 0xb0  ; "°"
	.asciz "*."
	.byte 0xa8  ; "¨"
	.asciz "*."
	.byte 0xa0  ; " "
	.asciz "*."
	.byte 0x98  ; ""
	.asciz "*."
	.byte 0x90  ; ""
	.asciz "*."
	.asciz " YELLOW"
	.asciz " BLACK "
	.asciz " BLUE  "
	.asciz " GREEN "
	.asciz " RED   "
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "D"
	.asciz "D"
	.asciz "D"
	.asciz "-"
	.asciz "1"
	.asciz "5"
	.asciz "<"
	.zero 2
	.byte 0x04
	.asciz "+."
	.byte 0xfc  ; "ü"
	.asciz "*."
	.byte 0xf4  ; "ô"
	.asciz "*."
	.byte 0xec  ; "ì"
	.asciz "*."
	.byte 0xe4  ; "ä"
	.asciz "*."
	.asciz " YELLOW"
	.asciz " BLACK "
	.asciz " BLUE  "
	.asciz " GREEN "
	.asciz " RED   "
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "D"
	.asciz "D"
	.asciz "D"
	.asciz "-"
	.asciz "1"
	.asciz "5"
	.asciz "<"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz "%"
	.asciz "@"
	.asciz "@"
	.asciz "@"
	.asciz ")"
	.asciz "-"
	.asciz "1"
	.asciz "8"
	.zero 2
	.asciz "%1d"
	.byte 0x19
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.asciz "4"
	.asciz "4"
	.asciz "4"
	.byte 0x1d
	.byte 0x00
	.asciz "!"
	.asciz "%"
	.asciz ","
	.zero 2
	.asciz "%1d"
	.byte 0x19
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.asciz "4"
	.asciz "4"
	.asciz "4"
	.byte 0x1d
	.byte 0x00
	.asciz "!"
	.asciz "%"
	.asciz ","
	.zero 2
	.asciz "%1d"
	.byte 0x19
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.asciz "4"
	.asciz "4"
	.asciz "4"
	.byte 0x1d
	.byte 0x00
	.asciz "!"
	.asciz "%"
	.asciz ","
	.zero 2
	.ascii "HD-TYPE             :                 "
	.byte 0x09
	.ascii "TRACKS              :                 "
	.byte 0x09
	.ascii "HEADS               :                 "
	.byte 0x09
	.ascii "SECTORS PER TRACK   :                 "
	.byte 0x09
	.ascii "TOTAL HD       (MB) :                 "
	.byte 0x09
	.ascii "USED BY SYSTEM (MB) :                 "
	.byte 0x09
	.ascii "FREE FOR USE   (MB) :                 "
	.byte 0x09
	.ascii "SOFTWARE RELEASE    :                 "
	.byte 0x09
	.zero 2
	.asciz "%6.1f"
	.asciz "%6.1f"
	.asciz "%6.1f"
	.zero 2
	.byte 0xc8  ; "È"
	.asciz "B"
	.byte 0x00
	.byte 0xc8  ; "È"
	.asciz "B"
	.byte 0x00
	.byte 0xc8  ; "È"
	.asciz "BFMT!"
	.zero 3
	.byte 0x13
	.byte 0x00
	.asciz "&"
	.asciz "9"
	.asciz "L"
	.byte 0x90  ; ""
	.byte 0x00
	.asciz "a"
	.asciz "a"
	.zero 2
	.byte 0x03
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.asciz "9"
	.asciz "N"
	.asciz "i"
	.asciz "LBNS"
	.byte 0x00
	.asciz "4"
	.asciz "N"
	.asciz "h"
	.byte 0x82  ; ""
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.byte 0xb6  ; "¶"
	.byte 0x00
	.byte 0xb6  ; "¶"
	.byte 0x00
	.byte 0xb6  ; "¶"
	.byte 0x00
	.byte 0xb6  ; "¶"
	.byte 0x00
	.zero 2
	.asciz "LBN!"
	.byte 0x00
	.asciz "%1.1d"
	.asciz "%2.2d"
	.asciz "%3.3d"
	.asciz " %1.1d"
	.byte 0x00
	.asciz " %2.2d"
	.zero 3
	.asciz "U"
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0xbd  ; "½"
	.byte 0x00
	.byte 0x14, 0x01
	.byte 0x49
	.byte 0x01
	.byte 0xbb  ; "»"
	.byte 0x01
	.asciz "                          "
	.byte 0x00
	.asciz "%s"
	.byte 0x00
	.asciz "B"
	.asciz "F"
	.asciz "a"
	.asciz "a"
	.asciz "a"
	.asciz "J"
	.asciz "N"
	.asciz "R"
	.asciz "Y"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.ascii "   :                "
	.byte 0x09
	.byte 0x00

HDAE5000_Char_Tables:	; 0x2E2E76
	; Character set tables
	.asciz "%3.3d"
	.ascii "E"
	.byte 0x01, 0x7f
	.byte 0x00
	.ascii "f"
	.byte 0x01, 0x7f
	.byte 0x00
	.byte 0x48
	.byte 0x01, 0x7f
	.byte 0x00
	.ascii "i"
	.byte 0x01, 0x7f
	.byte 0x00
	.byte 0x44
	.byte 0x01, 0x7f
	.byte 0x00
	.ascii "v"
	.byte 0x01, 0x7f
	.byte 0x00
	.byte 0x43
	.byte 0x01, 0x7f
	.byte 0x00
	.ascii "w"
	.byte 0x01, 0x7f
	.byte 0x00
	.byte 0x49
	.byte 0x01, 0x7f
	.byte 0x00
	.ascii "k"
	.byte 0x01, 0x7f
	.byte 0x00
	.byte 0x4a
	.byte 0x01, 0x7f
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x7f
	.byte 0x00
	.asciz "FLS NAME "
	.asciz "%2.2d"
	.asciz ":"
	.byte 0x09
	.byte 0x00
	.ascii ":                                 "
	.byte 0x09
	.byte 0x00
	.asciz "%2.2d"
	.ascii " LOC. %3.3d/%2.2d"
	.byte 0x09
	.zero 2
	.ascii " LOC. 000/00"
	.byte 0x09
	.byte 0x00
	.asciz "FLS!"
	.byte 0x00
	.asciz "DEL1"
	.byte 0x00
	.asciz "DEL2"
	.byte 0x00
	.asciz "OVWR"
	.byte 0x00
	.asciz "%2.2d"
	.asciz ".LSW"
	.byte 0x00
	.asciz ".PMT"
	.byte 0x00
	.asciz ".SQT"
	.byte 0x00
	.asciz ".CMP"
	.byte 0x00
	.asciz ".TM"
	.asciz ".MSP"
	.byte 0x00
	.asciz ".RCM"
	.byte 0x00
	.asciz ".MD"
	.asciz ".TLX"
	.byte 0x00
	.asciz "WrCn"
	.byte 0x00
	.asciz "DEL!"
	.byte 0x00
	.asciz "%s"
	.byte 0x00
	.asciz "'"
	.asciz "+"
	.asciz "F"
	.asciz "F"
	.asciz "F"
	.asciz "/"
	.asciz "3"
	.asciz "7"
	.asciz ">"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "l"
	.asciz "l"
	.asciz "l"
	.asciz "-"
	.asciz ";"
	.asciz "U"
	.asciz "\\"
	.zero 2
	.asciz "TimB"
	.byte 0x00
	.asciz "TLBN"
	.zero 5
	.byte 0x01, 0x01, 0x01
	.byte 0x00
	.byte 0x02, 0x02, 0x02
	.byte 0x00
	.byte 0x03, 0x03, 0x03
	.byte 0x00
	.byte 0x04, 0x04, 0x04
	.byte 0x00
	.byte 0x05, 0x05, 0x05
	.byte 0x00
	.byte 0x06, 0x06, 0x06
	.byte 0x00
	.byte 0x07, 0x07, 0x07
	.byte 0x00
	.byte 0x08, 0x08, 0x08
	.byte 0x00
	.byte 0x09, 0x09, 0x09
	.byte 0x00
	.byte 0x0a, 0x0a, 0x0a
	.byte 0x00
	.byte 0x0b, 0x0b, 0x0b
	.byte 0x00
	.byte 0x0c, 0x0c, 0x0c
	.byte 0x00
	.byte 0x0d, 0x0d, 0x0d
	.byte 0x00
	.byte 0x0e, 0x0e, 0x0e
	.byte 0x00
	.byte 0x0f, 0x0f, 0x0f
	.byte 0x00
	.byte 0x10, 0x10, 0x10
	.byte 0x00
	.byte 0x11, 0x11, 0x11
	.byte 0x00
	.byte 0x12, 0x12, 0x12
	.byte 0x00
	.byte 0x13, 0x13, 0x13
	.byte 0x00
	.byte 0x14, 0x14, 0x14
	.byte 0x00
	.byte 0x15, 0x15, 0x15
	.byte 0x00
	.byte 0x16, 0x16, 0x16
	.byte 0x00
	.byte 0x17, 0x17, 0x17
	.byte 0x00
	.byte 0x18, 0x18, 0x18
	.byte 0x00
	.byte 0x19, 0x19, 0x19
	.byte 0x00
	.byte 0x1a, 0x1a, 0x1a
	.byte 0x00
	.byte 0x1b, 0x1b, 0x1b
	.byte 0x00
	.byte 0x1c, 0x1c, 0x1c
	.byte 0x00
	.byte 0x1d, 0x1d, 0x1d
	.byte 0x00
	.byte 0x1e, 0x1e, 0x1e
	.byte 0x00
	.byte 0x1f, 0x1f, 0x1f
	.byte 0x00
	.asciz "   "
	.asciz "!!!"
	.asciz "\"\"\""
	.asciz "###"
	.asciz "$$$"
	.asciz "%%%"
	.asciz "&&&"
	.asciz "'''"
	.asciz "((("
	.asciz ")))"
	.asciz "***"
	.asciz "+++"
	.asciz ",,,"
	.asciz "---"
	.asciz "..."
	.asciz "///"
	.asciz "000"
	.asciz "111"
	.asciz "222"
	.asciz "333"
	.asciz "444"
	.asciz "555"
	.asciz "666"
	.asciz "777"
	.asciz "888"
	.asciz "999"
	.asciz ":::"
	.asciz ";;;"
	.asciz "<<<"
	.asciz "==="
	.asciz ">>>"
	.asciz "???"
	.asciz "@@@"
	.asciz "AAA"
	.asciz "BBB"
	.asciz "CCC"
	.asciz "DDD"
	.asciz "EEE"
	.asciz "FFF"
	.asciz "GGG"
	.asciz "HHH"
	.asciz "III"
	.asciz "JJJ"
	.asciz "KKK"
	.asciz "LLL"
	.asciz "MMM"
	.asciz "NNN"
	.asciz "OOO"
	.asciz "PPP"
	.asciz "QQQ"
	.asciz "RRR"
	.asciz "SSS"
	.asciz "TTT"
	.asciz "UUU"
	.asciz "VVV"
	.asciz "WWW"
	.asciz "XXX"
	.asciz "YYY"
	.asciz "ZZZ"
	.asciz "[[["
	.asciz "\\\\\\"
	.asciz "]]]"
	.asciz "^^^"
	.asciz "___"
	.asciz "```"
	.asciz "aaa"
	.asciz "bbb"
	.asciz "ccc"
	.asciz "ddd"
	.asciz "eee"
	.asciz "fff"
	.asciz "ggg"
	.asciz "hhh"
	.asciz "iii"
	.asciz "jjj"
	.asciz "kkk"
	.asciz "lll"
	.asciz "mmm"
	.asciz "nnn"
	.asciz "ooo"
	.asciz "ppp"
	.asciz "qqq"
	.asciz "rrr"
	.asciz "sss"
	.asciz "ttt"
	.asciz "uuu"
	.asciz "vvv"
	.asciz "www"
	.asciz "xxx"
	.asciz "yyy"
	.asciz "zzz"
	.asciz "{{{"
	.asciz "|||"
	.asciz "}}}"
	.asciz "~~~"
	.byte 0x7f, 0x7f, 0x7f
	.byte 0x00
	.byte 0x80, 0x80, 0x80  ; ""
	.byte 0x00
	.byte 0x81, 0x81, 0x81  ; ""
	.byte 0x00
	.byte 0x82, 0x82, 0x82  ; ""
	.byte 0x00
	.byte 0x83, 0x83, 0x83  ; ""
	.byte 0x00
	.byte 0x84, 0x84, 0x84  ; ""
	.byte 0x00
	.byte 0x85, 0x85, 0x85  ; ""
	.byte 0x00
	.byte 0x86, 0x86, 0x86  ; ""
	.byte 0x00
	.byte 0x87, 0x87, 0x87  ; ""
	.byte 0x00
	.byte 0x88, 0x88, 0x88  ; ""
	.byte 0x00
	.byte 0x89, 0x89, 0x89  ; ""
	.byte 0x00
	.byte 0x8a, 0x8a, 0x8a  ; ""
	.byte 0x00
	.byte 0x8b, 0x8b, 0x8b  ; ""
	.byte 0x00
	.byte 0x8c, 0x8c, 0x8c  ; ""
	.byte 0x00
	.byte 0x8d, 0x8d, 0x8d  ; ""
	.byte 0x00
	.byte 0x8e, 0x8e, 0x8e  ; ""
	.byte 0x00
	.byte 0x8f, 0x8f, 0x8f  ; ""
	.byte 0x00
	.byte 0x90, 0x90, 0x90  ; ""
	.byte 0x00
	.byte 0x91, 0x91, 0x91  ; ""
	.byte 0x00
	.byte 0x92, 0x92, 0x92  ; ""
	.byte 0x00
	.byte 0x93, 0x93, 0x93  ; ""
	.byte 0x00
	.byte 0x94, 0x94, 0x94  ; ""
	.byte 0x00
	.byte 0x95, 0x95, 0x95  ; ""
	.byte 0x00
	.byte 0x96, 0x96, 0x96  ; ""
	.byte 0x00
	.byte 0x97, 0x97, 0x97  ; ""
	.byte 0x00
	.byte 0x98, 0x98, 0x98  ; ""
	.byte 0x00
	.byte 0x99, 0x99, 0x99  ; ""
	.byte 0x00
	.byte 0x9a, 0x9a, 0x9a  ; ""
	.byte 0x00
	.byte 0x9b, 0x9b, 0x9b  ; ""
	.byte 0x00
	.byte 0x9c, 0x9c, 0x9c  ; ""
	.byte 0x00
	.byte 0x9d, 0x9d, 0x9d  ; ""
	.byte 0x00
	.byte 0x9e, 0x9e, 0x9e  ; ""
	.byte 0x00
	.byte 0x9f, 0x9f, 0x9f  ; ""
	.byte 0x00
	.byte 0xa0, 0xa0, 0xa0  ; "   "
	.byte 0x00
	.byte 0xa1, 0xa1, 0xa1  ; "¡¡¡"
	.byte 0x00
	.byte 0xa2, 0xa2, 0xa2  ; "¢¢¢"
	.byte 0x00
	.byte 0xa3, 0xa3, 0xa3  ; "£££"
	.byte 0x00
	.byte 0xa4, 0xa4, 0xa4  ; "¤¤¤"
	.byte 0x00
	.byte 0xa5, 0xa5, 0xa5  ; "¥¥¥"
	.byte 0x00
	.byte 0xa6, 0xa6, 0xa6  ; "¦¦¦"
	.byte 0x00
	.byte 0xa7, 0xa7, 0xa7  ; "§§§"
	.byte 0x00
	.byte 0xa8, 0xa8, 0xa8  ; "¨¨¨"
	.byte 0x00
	.byte 0xa9, 0xa9, 0xa9  ; "©©©"
	.byte 0x00
	.byte 0xaa, 0xaa, 0xaa  ; "ªªª"
	.byte 0x00
	.byte 0xab, 0xab, 0xab  ; "«««"
	.byte 0x00
	.byte 0xac, 0xac, 0xac  ; "¬¬¬"
	.byte 0x00
	.byte 0xad, 0xad, 0xad  ; "­­­"
	.byte 0x00
	.byte 0xae, 0xae, 0xae  ; "®®®"
	.byte 0x00
	.byte 0xaf, 0xaf, 0xaf  ; "¯¯¯"
	.byte 0x00
	.byte 0xb0, 0xb0, 0xb0  ; "°°°"
	.byte 0x00
	.byte 0xb1, 0xb1, 0xb1  ; "±±±"
	.byte 0x00
	.byte 0xb2, 0xb2, 0xb2  ; "²²²"
	.byte 0x00
	.byte 0xb3, 0xb3, 0xb3  ; "³³³"
	.byte 0x00
	.byte 0xb4, 0xb4, 0xb4  ; "´´´"
	.byte 0x00
	.byte 0xb5, 0xb5, 0xb5  ; "µµµ"
	.byte 0x00
	.byte 0xb6, 0xb6, 0xb6  ; "¶¶¶"
	.byte 0x00
	.byte 0xb7, 0xb7, 0xb7  ; "···"
	.byte 0x00
	.byte 0xb8, 0xb8, 0xb8  ; "¸¸¸"
	.byte 0x00
	.byte 0xb9, 0xb9, 0xb9  ; "¹¹¹"
	.byte 0x00
	.byte 0xba, 0xba, 0xba  ; "ººº"
	.byte 0x00
	.byte 0xbb, 0xbb, 0xbb  ; "»»»"
	.byte 0x00
	.byte 0xbc, 0xbc, 0xbc  ; "¼¼¼"
	.byte 0x00
	.byte 0xbd, 0xbd, 0xbd  ; "½½½"
	.byte 0x00
	.byte 0xbe, 0xbe, 0xbe  ; "¾¾¾"
	.byte 0x00
	.byte 0xbf, 0xbf, 0xbf  ; "¿¿¿"
	.byte 0x00
	.byte 0xc0, 0xc0, 0xc0  ; "ÀÀÀ"
	.byte 0x00
	.byte 0xc1, 0xc1, 0xc1  ; "ÁÁÁ"
	.byte 0x00
	.byte 0xc2, 0xc2, 0xc2  ; "ÂÂÂ"
	.byte 0x00
	.byte 0xc3, 0xc3, 0xc3  ; "ÃÃÃ"
	.byte 0x00
	.byte 0xc4, 0xc4, 0xc4  ; "ÄÄÄ"
	.byte 0x00
	.byte 0xc5, 0xc5, 0xc5  ; "ÅÅÅ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc7, 0xc7, 0xc7  ; "ÇÇÇ"
	.byte 0x00
	.byte 0xc8, 0xc8, 0xc8  ; "ÈÈÈ"
	.byte 0x00
	.byte 0xc9, 0xc9, 0xc9  ; "ÉÉÉ"
	.byte 0x00
	.byte 0xca, 0xca, 0xca  ; "ÊÊÊ"
	.byte 0x00
	.byte 0xcb, 0xcb, 0xcb  ; "ËËË"
	.byte 0x00
	.byte 0xcc, 0xcc, 0xcc  ; "ÌÌÌ"
	.byte 0x00
	.byte 0xcd, 0xcd, 0xcd  ; "ÍÍÍ"
	.byte 0x00
	.byte 0xce, 0xce, 0xce  ; "ÎÎÎ"
	.byte 0x00
	.byte 0xcf, 0xcf, 0xcf  ; "ÏÏÏ"
	.byte 0x00
	.byte 0xd0, 0xd0, 0xd0  ; "ÐÐÐ"
	.byte 0x00
	.byte 0xd1, 0xd1, 0xd1  ; "ÑÑÑ"
	.byte 0x00
	.byte 0xd2, 0xd2, 0xd2  ; "ÒÒÒ"
	.byte 0x00
	.byte 0xd3, 0xd3, 0xd3  ; "ÓÓÓ"
	.byte 0x00
	.byte 0xd4, 0xd4, 0xd4  ; "ÔÔÔ"
	.byte 0x00
	.byte 0xd5, 0xd5, 0xd5  ; "ÕÕÕ"
	.byte 0x00
	.byte 0xd6, 0xd6, 0xd6  ; "ÖÖÖ"
	.byte 0x00
	.byte 0xd7, 0xd7, 0xd7  ; "×××"
	.byte 0x00
	.byte 0xd8, 0xd8, 0xd8  ; "ØØØ"
	.byte 0x00
	.byte 0xd9, 0xd9, 0xd9  ; "ÙÙÙ"
	.byte 0x00
	.byte 0xda, 0xda, 0xda  ; "ÚÚÚ"
	.byte 0x00
	.byte 0xdb, 0xdb, 0xdb  ; "ÛÛÛ"
	.byte 0x00
	.byte 0xdc, 0xdc, 0xdc  ; "ÜÜÜ"
	.byte 0x00
	.byte 0xdd, 0xdd, 0xdd  ; "ÝÝÝ"
	.byte 0x00
	.byte 0xde, 0xde, 0xde  ; "ÞÞÞ"
	.byte 0x00
	.byte 0xdf, 0xdf, 0xdf  ; "ßßß"
	.byte 0x00
	.byte 0xe0, 0xe0, 0xe0  ; "ààà"
	.byte 0x00
	.byte 0xe1, 0xe1, 0xe1  ; "ááá"
	.byte 0x00
	.byte 0xe2, 0xe2, 0xe2  ; "âââ"
	.byte 0x00
	.byte 0xe3, 0xe3, 0xe3  ; "ããã"
	.byte 0x00
	.byte 0xe4, 0xe4, 0xe4  ; "äää"
	.byte 0x00
	.byte 0xe5, 0xe5, 0xe5  ; "ååå"
	.byte 0x00
	.byte 0xe6, 0xe6, 0xe6  ; "æææ"
	.byte 0x00
	.byte 0xe7, 0xe7, 0xe7  ; "ççç"
	.byte 0x00
	.byte 0xe8, 0xe8, 0xe8  ; "èèè"
	.byte 0x00
	.byte 0xe9, 0xe9, 0xe9  ; "ééé"
	.byte 0x00
	.byte 0xea, 0xea, 0xea  ; "êêê"
	.byte 0x00
	.byte 0xeb, 0xeb, 0xeb  ; "ëëë"
	.byte 0x00
	.byte 0xec, 0xec, 0xec  ; "ììì"
	.byte 0x00
	.byte 0xed, 0xed, 0xed  ; "ííí"
	.byte 0x00
	.byte 0xee, 0xee, 0xee  ; "îîî"
	.byte 0x00
	.byte 0xef, 0xef, 0xef  ; "ïïï"
	.byte 0x00
	.byte 0xf0, 0xf0, 0xf0  ; "ððð"
	.byte 0x00
	.byte 0xf1, 0xf1, 0xf1  ; "ñññ"
	.byte 0x00
	.byte 0xf2, 0xf2, 0xf2  ; "òòò"
	.byte 0x00
	.byte 0xf3, 0xf3, 0xf3  ; "óóó"
	.byte 0x00
	.byte 0xf4, 0xf4, 0xf4  ; "ôôô"
	.byte 0x00
	.byte 0xf5, 0xf5, 0xf5  ; "õõõ"
	.byte 0x00
	.byte 0xf6, 0xf6, 0xf6  ; "ööö"
	.byte 0x00
	.byte 0xf7, 0xf7, 0xf7  ; "÷÷÷"
	.byte 0x00
	.byte 0xf8, 0xf8, 0xf8  ; "øøø"
	.byte 0x00
	.byte 0xf9, 0xf9, 0xf9  ; "ùùù"
	.byte 0x00
	.byte 0xfa, 0xfa, 0xfa  ; "úúú"
	.byte 0x00
	.byte 0xfb, 0xfb, 0xfb  ; "ûûû"
	.byte 0x00
	.byte 0xfc, 0xfc, 0xfc  ; "üüü"
	.byte 0x00
	.byte 0xfd, 0xfd, 0xfd  ; "ýýý"
	.byte 0x00
	.byte 0xfe, 0xfe, 0xfe  ; "þþþ"
	.byte 0x00
	.byte 0xff
	.fill 2, 1, 0xff
	.zero 44

HDAE5000_Path_Strings:	; 0x2E348F
	; File path and config strings
	.asciz ")BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB)"
	.asciz "BZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZB"
	.asciz "BZ{{{{"
	.zero 2
	.asciz "{{"
	.zero 4
	.asciz "{{"
	.zero 2
	.asciz "{{{"
	.zero 3
	.asciz "{{{"
	.zero 3
	.asciz "{{{{ZB"
	.ascii "BZ"
	.byte 0x9c, 0xad, 0xad  ; "­­"
	.byte 0x00
	.byte 0xf7, 0xf7, 0xf7  ; "÷÷÷"
	.byte 0x00
	.byte 0xad, 0xf7, 0xf7  ; "­÷÷"
	.byte 0x00
	.byte 0xf7, 0xf7, 0xad  ; "÷÷­"
	.byte 0x00
	.byte 0xf7, 0xf7, 0xf7  ; "÷÷÷"
	.byte 0x00
	.byte 0xad, 0xad  ; "­­"
	.byte 0x00
	.byte 0xf7, 0xf7, 0xf7  ; "÷÷÷"
	.byte 0x00
	.byte 0xad, 0xad  ; "­­"
	.byte 0x00
	.byte 0xf7, 0xf7, 0xf7, 0xad, 0xad, 0xad  ; "÷÷÷­­­"
	.asciz "{kB"
	.ascii "BZ{"
	.byte 0xc6, 0xc6  ; "ÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6, 0xf7, 0xc6, 0xc6, 0xc6  ; "ÆÆÆ÷ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6  ; "ÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6  ; "ÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0xb5  ; "ÆÆÆÆÆµ"
	.asciz "{ZB"
	.ascii "BZ{"
	.byte 0xde, 0xde, 0xf7  ; "ÞÞ÷"
	.byte 0x00
	.zero 2
	.byte 0xde, 0xde, 0xde, 0xde  ; "ÞÞÞÞ"
	.byte 0x00
	.byte 0xde, 0xde, 0xde  ; "ÞÞÞ"
	.byte 0x00
	.byte 0xde, 0xde, 0xde  ; "ÞÞÞ"
	.byte 0x00
	.byte 0xde, 0xde  ; "ÞÞ"
	.byte 0x00
	.byte 0xde, 0xde, 0xde  ; "ÞÞÞ"
	.byte 0x00
	.byte 0xde, 0xde  ; "ÞÞ"
	.byte 0x00
	.zero 2
	.byte 0xde, 0xde, 0xde, 0xc6  ; "ÞÞÞÆ"
	.asciz "{ZB"
	.ascii "BZ{"
	.byte 0xef, 0xef, 0xef, 0xf7, 0xf7, 0xf7  ; "ïïï÷÷÷"
	.byte 0x00
	.byte 0xef, 0xef, 0xef  ; "ïïï"
	.byte 0x00
	.byte 0xef, 0xef, 0xef  ; "ïïï"
	.byte 0x00
	.byte 0xef, 0xef, 0xef  ; "ïïï"
	.byte 0x00
	.byte 0xef, 0xef  ; "ïï"
	.byte 0x00
	.zero 3
	.byte 0xf7, 0xef, 0xef  ; "÷ïï"
	.byte 0x00
	.byte 0xf7, 0xf7, 0xef, 0xef, 0xef, 0xc6  ; "÷÷ïïïÆ"
	.asciz "{ZB"
	.ascii ")Z{"
	.byte 0xd6, 0xd6, 0xd6, 0xd6, 0xd6, 0xd6  ; "ÖÖÖÖÖÖ"
	.byte 0x00
	.byte 0xd6, 0xd6, 0xd6  ; "ÖÖÖ"
	.byte 0x00
	.byte 0xd6, 0xd6, 0xd6  ; "ÖÖÖ"
	.byte 0x00
	.byte 0xd6, 0xd6, 0xd6  ; "ÖÖÖ"
	.byte 0x00
	.byte 0xd6, 0xd6  ; "ÖÖ"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.byte 0xf7, 0xd6, 0xd6, 0xd6  ; "÷ÖÖÖ"
	.byte 0x00
	.byte 0xd6, 0xd6, 0xd6, 0xd6, 0xd6, 0xc6  ; "ÖÖÖÖÖÆ"
	.asciz "{k)"
	.ascii "BZk"
	.byte 0xc6, 0xc6  ; "ÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6  ; "ÆÆ"
	.byte 0x00
	.byte 0xc6, 0xf7  ; "Æ÷"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0xb5  ; "ÆÆÆÆÆµ"
	.asciz "{Z)"
	.ascii ")Z{"
	.byte 0xad, 0xad, 0xf7  ; "­­÷"
	.byte 0x00
	.zero 2
	.byte 0xf7, 0xad, 0xad, 0xad  ; "÷­­­"
	.byte 0x00
	.byte 0xad, 0xad, 0xad, 0xf7  ; "­­­÷"
	.byte 0x00
	.zero 2
	.byte 0xf7, 0xad, 0xad  ; "÷­­"
	.byte 0x00
	.byte 0xad, 0xad, 0xf7  ; "­­÷"
	.byte 0x00
	.byte 0xad, 0xad  ; "­­"
	.byte 0x00
	.zero 3
	.byte 0xad, 0xad, 0xad  ; "­­­"
	.asciz "{Z)"
	.ascii ")Z{"
	.byte 0x9c, 0x9c, 0x9c, 0xf7, 0xf7, 0xf7, 0x9c, 0x9c, 0x9c, 0x9c, 0xf7, 0x9c, 0x9c, 0x9c, 0x9c, 0xf7, 0xf7, 0xf7, 0x9c, 0x9c, 0x9c, 0xf7, 0x9c, 0x9c, 0x9c, 0xf7, 0x9c, 0x9c, 0xf7, 0xf7, 0xf7, 0xf7, 0x9c, 0x9c, 0x8c  ; "÷÷÷÷÷÷÷÷÷÷÷÷÷"
	.asciz "{Z)"

HDAE5000_UI_Icons:	; 0x2E365D
	; UI icon/pattern data with language IDs
	.asciz ")Bkk{{{kk{k{{kkk{{kkk{{kkkk{{kk{kkkkkkkB)"
	.asciz ")B)B))))))B)B)B))))B)BB)BB)B)))B)B)BB)))B"
	.zero 41
	.asciz "AcLanguage1"
	.asciz "LANENG00"
	.byte 0x00
	.asciz "LANDEU00"
	.byte 0x00
	.asciz "LANFRA00"
	.byte 0x00

HDAE5000_Multilingual_Messages:	; 0x2E3704
	; Trilingual UI messages (EN/DE/FR)
	.asciz "Would you really delete the selected directory?"
	.asciz "Moechten Sie das angewaehlte Verzeichnis wirklich loeschen?"
	.ascii "Voulez-vous effacer ce r"
	.byte 0xe9  ; "é"
	.asciz "pertoir?"
	.asciz "Would you really delete the selected title?"
	.asciz "Moechten Sie den angewaehlten Titel wirklich loeschen?"
	.byte 0x00
	.asciz "Voulez-vous effacer ce titre?"
	.asciz "COPY FD TO HARD DISK"
	.byte 0x00
	.asciz "COPY FD TO HARD DISK"
	.byte 0x00
	.asciz "COPY FD TO HARD DISK"
	.byte 0x00
	.asciz "OUTPUT SETTING"
	.byte 0x00
	.asciz "OUTPUT SETTING"
	.byte 0x00
	.asciz "OUTPUT SETTING"
	.byte 0x00
	.asciz "SELECT BY   NAME    "
	.byte 0x00
	.asciz "SELECT BY   NAME    "
	.byte 0x00
	.asciz "SELECT BY   NAME    "
	.byte 0x00
	.asciz "LOAD BY     NUMBER"
	.byte 0x00
	.asciz "LOAD BY     NUMBER"
	.byte 0x00
	.asciz "LOAD BY     NUMBER"
	.byte 0x00
	.asciz "SELECT FILE LOAD SCRIPT"
	.asciz "SELECT FILE LOAD SCRIPT"
	.asciz "SELECT FILE LOAD SCRIPT"
	.asciz "WRITE PROTECT: "
	.asciz "WRITE PROTECT: "
	.asciz "WRITE PROTECT: "
	.asciz "WRITE CONFIRM: "
	.asciz "WRITE CONFIRM: "
	.asciz "WRITE CONFIRM: "
	.asciz "ABOUT & HELP "
	.asciz "ABOUT & HELP "
	.asciz "ABOUT & HELP "
	.asciz "SAVE SETUP"
	.byte 0x00
	.asciz "SAVE SETUP"
	.byte 0x00
	.asciz "SAVE SETUP"
	.byte 0x00
	.asciz "OUTPUT SETTING"
	.byte 0x00
	.asciz "OUTPUT SETTING"
	.byte 0x00
	.asciz "OUTPUT SETTING"
	.byte 0x00
	.asciz "SEPARATE OUTPUT MODE:"
	.asciz "SEPARATE OUTPUT MODE:"
	.asciz "SEPARATE OUTPUT MODE:"
	.asciz "PART SELECT FOR SEQ.DRUMS OUT:"
	.byte 0x00
	.asciz "PART SELECT FOR SEQ.DRUMS OUT:"
	.byte 0x00
	.asciz "PART SELECT FOR SEQ.DRUMS OUT:"
	.byte 0x00
	.asciz "PART SELECT FOR SEQ.BASS  OUT:"
	.byte 0x00
	.asciz "PART SELECT FOR SEQ.BASS  OUT:"
	.byte 0x00
	.asciz "PART SELECT FOR SEQ.BASS  OUT:"
	.byte 0x00
	.asciz "! The separate outputs cannot be controlled by the internal volume control."
	.asciz "! Die separaten Ausgaenge werden nicht durch Volumen am Keyboard kontrolliert."
	.byte 0x00
	.ascii "! Les sortie s"
	.byte 0xe9  ; "é"
	.ascii "par"
	.byte 0xe9  ; "é"
	.ascii "es ne peuvent pas "
	.byte 0xea  ; "ê"
	.ascii "tre control"
	.byte 0xe9  ; "é"
	.asciz "es par les volume du calvier."
	.asciz "Hardware and software developement:"
	.asciz "Hardware und Software Entwicklung:"
	.byte 0x00
	.asciz "Hardware et Software developement:"
	.byte 0x00
	.asciz "Conception, marketing, sales and service:"
	.asciz "Konzeption, Marketing, Verkauf und Service:"
	.asciz "Conception, Marketing, Vente et Service:"
	.byte 0x00
	.asciz "All rigths reserved by the called companies"
	.asciz "Alle Rechte bei den obengenannten Firmen"
	.byte 0x00
	.asciz "All rigths reserved by the called companies"
	.asciz "Special thanks to:"
	.byte 0x00
	.asciz "Spezieller Dank an:"
	.asciz "Special thanks to:"
	.byte 0x00
	.asciz "Press 3 digits for directory and 2 digits for the file."
	.asciz "Geben Sie 3 Ziffern fuer das Verzeichnis und 2 Ziffern fuer den Titel ein."
	.byte 0x00
	.ascii "Introduisez 3 chiffres pour le r"
	.byte 0xe9  ; "é"
	.asciz "pertoir at 2 chiffres pour le titre."
	.asciz "Do you really want to overwrite this FLS entry?"
	.asciz "Wollen Sie den bestehenden FLS Eintrag wirklich ueberschreiben?"
	.ascii "Voulez-vous vraiment "
	.byte 0xe9  ; "é"
	.asciz "crire par dessus le FLS?"
	.byte 0x00
	.asciz "Do you really want to delete this FLS entry?"
	.byte 0x00
	.asciz "Wollen Sie den bestehenden FLS Eintrag wirklich loeschen?"
	.asciz "Voulez-vous vraiment effacer ce FLS?"
	.byte 0x00
	.asciz "HD FORMAT will erase all files at once."
	.asciz "HD FORMAT loescht alle Daten auf der Festplatte."
	.byte 0x00
	.ascii "HD-FORMAT effacera toutes les donn"
	.byte 0xe9  ; "é"
	.asciz "es de votre disque dur."
	.byte 0x00
	.asciz "Therefore you need a 6-digit key code. Please refer your owners manual chapter SETUP & TOOLS."
	.asciz "Geben Sie auf dieser Seite den 6-stelligen Code ein. Schauen Sie in der Anleitung unter SETUP & TOOLS nach."
	.ascii "Indroduisez le code "
	.byte 0xe0  ; "à"
	.ascii " 6 chiffres et r"
	.byte 0xe9  ; "é"
	.ascii "f"
	.byte 0xe9  ; "é"
	.ascii "rez-vous "
	.byte 0xe0  ; "à"
	.asciz " votre manuel dans (SETUP & TOOLS)."
	.asciz "After your code input all data will be deleted irrevocable!"
	.asciz "Nach der Codeeingabe werden alle Daten unwiderruflich geloescht!"
	.byte 0x00
	.ascii "Apr"
	.byte 0xe8  ; "è"
	.ascii "s l'introduction du code, toutes les donn"
	.byte 0xe9  ; "é"
	.ascii "es seront effac"
	.byte 0xe9  ; "é"
	.asciz "es."
	.asciz "You are going to delete a FLS entry. Are you sure?"
	.byte 0x00
	.asciz "Sie haben einen FLS Eintrag zum Loeschen markiert. Sind Sie sicher?"
	.asciz "Vous avez marquer un FLS connection pour effacer. Vous ait sure?"
	.byte 0x00
	.asciz "You are going to overwrite a FLS entry. Are you sure?"
	.asciz "Sie ueberschreiben eine bestehenden FLS Eintrag. Sind Sie sicher?"
	.asciz "Voulez-vous vraiment transcrire ce FLS enregistration?"
	.byte 0x00
	.asciz "The hard disk is write protected!"
	.ascii "Die Festplatte ist schreibgesch"
	.byte 0xfc  ; "ü"
	.asciz "tzt!"
	.byte 0x00
	.ascii "Le disque dur est prot"
	.byte 0xe9  ; "é"
	.ascii "ger contre l'"
	.byte 0xe9  ; "é"
	.asciz "ctriture!"
	.byte 0x00
	.asciz "Please set the write protect mode to OFF."
	.asciz "Schalten Sie WRITE PROTECT im SETUP & TOOLS auf OFF."
	.byte 0x00
	.ascii "Pour "
	.byte 0xe9  ; "é"
	.asciz "crire mettez la protection sur OFF."
	.asciz "The hard disk is not formatted!"
	.asciz "Die Festplatte ist nicht formatiert!"
	.byte 0x00
	.ascii "Le disque dur n'est pas format"
	.byte 0xe9  ; "é"
	.asciz "."
	.byte 0x00
	.asciz "Hard disk SRAM error."
	.asciz "Im HD-AE5000 SRAM ist ein Fehler aufgetreten."
	.asciz "Il y a un problem avec le SRAM de HD-AE5000."
	.byte 0x00
	.asciz "Hard disk reset error."
	.byte 0x00
	.asciz "Die Festplatte konnte nicht initialisiert werden."
	.asciz "Votre disque dur n'est pas reconnu."
	.asciz "Hard disk read error."
	.asciz "Beim Lesen der Festplatte ist ein Fehler aufgetreten."
	.ascii "Il y a un probl"
	.byte 0xe9  ; "é"
	.asciz "me de leture du disque."
	.asciz "Hard disk ID read error."
	.byte 0x00
	.asciz "Die ID der Festplatte konnte nicht gelesen werden."
	.byte 0x00
	.ascii "L'ID du disque dur n'a pas pu "
	.byte 0xea  ; "ê"
	.asciz "tre lue."
	.asciz "Hard disk track 0 error."
	.byte 0x00
	.asciz "Track O der Festplatte konnte nicht gelesen werden."
	.ascii "La piste 0 du disque dur n'a pas pu "
	.byte 0xea  ; "ê"
	.asciz "tre lue."
	.asciz "Hard disk FAT read error."
	.asciz "Die FAT der Festplatte konnte nicht gelesen werden."
	.ascii "Le FAT du disque dur n'a pas pu "
	.byte 0xea  ; "ê"
	.asciz "tre lue."
	.asciz "Hard disk FSB read error."
	.asciz "Der FSB der Festplatte konnte nicht gelesen werden."
	.ascii "Le FSB du disque dur n'a pas pu "
	.byte 0xea  ; "ê"
	.asciz "tre lue."
	.asciz "There are no files marked for copy to HD!"
	.asciz "Es wurden keine Titel zum Kopieren gefunden."
	.byte 0x00
	.ascii "Aucun titre n'a "
	.byte 0xe9  ; "é"
	.ascii "t"
	.byte 0xe9  ; "é"
	.ascii " marqu"
	.byte 0xe9  ; "é"
	.asciz " pour faire des copies."
	.asciz "Please make a safety backup of your data and call your service center."
	.byte 0x00
	.asciz "Sichern Sie alle Ihre Daten auf Diskette oder den PC und rufen Sie Ihre Service-Stelle an."
	.byte 0x00
	.ascii "Sauvez vos donn"
	.byte 0xe9  ; "é"
	.asciz "e sur disquette ou l'ordinateur et contactez votre service assistance."
	.byte 0x00
	.asciz "Please make a safety backup of your data and call your service center."
	.byte 0x00
	.asciz "Sichern Sie alle Ihre Daten auf Diskette oder den PC und rufen Sie Ihre Service-Stelle an."
	.byte 0x00
	.ascii "Sauvez vos donn"
	.byte 0xe9  ; "é"
	.asciz "e sur disquette ou l'ordinateur et contactez votre service assistance."
	.byte 0x00
	.asciz "The data on the disk you would like to copy to HD has no KN5000 format or some data are corrupted."
	.byte 0x00
	.asciz "Die Daten auf der Diskette die Sie kopieren moechten, haben keine KN5000 ID oder sind fehlerhaft."
	.ascii "Les donn"
	.byte 0xe9  ; "é"
	.ascii "es que vous voulez charger ne sont pas du KN5000 format ou ont des d"
	.byte 0xe9  ; "é"
	.asciz "faults."
	.asciz "The number or marked songs cannot fit in the free space of the selected directory."
	.byte 0x00
	.asciz "Im gewuenschten Verzeichnis sind nicht genuegend freie Plaetze fuer die Anzahl markierter Titel."
	.byte 0x00
	.ascii "Le r"
	.byte 0xe9  ; "é"
	.ascii "pertoir est satur"
	.byte 0xe9  ; "é"
	.ascii ", il n'y "
	.byte 0xe0  ; "à"
	.asciz " plus de place pour d'autres titre."
	.byte 0x00
	.asciz "Reduce the number of selected songs or find a free directory."
	.asciz "Reduzieren Sie die Zahl der Titel oder waehlen Sie ein anderes Verzeichnis."
	.ascii "Changer de r"
	.byte 0xe9  ; "é"
	.asciz "pertoire ou supprimez des titres."
	.byte 0x00
	.asciz "You cannot copy files/songs to an unnamed directory."
	.byte 0x00
	.asciz "Kopieren Sie keine Titel in ein nicht beschriftetes Verzeichnis."
	.byte 0x00
	.ascii "Vous ne pouvez pas copier des titres dans un r"
	.byte 0xe9  ; "é"
	.ascii "pertoire pas pr"
	.byte 0xe9  ; "é"
	.ascii "par"
	.byte 0xe9  ; "é"
	.asciz "."
	.byte 0x00
	.asciz "Please use a named directory or create the new directory with EDIT first."
	.asciz "Waehlen Sie ein bereits beschriftetes Verzeichnis oder benennen Sie es zuvor mit EDIT."
	.byte 0x00
	.asciz "Nommez-le d'abord par example avec EDIT."
	.byte 0x00
	.asciz "The DIR number is out of range."
	.asciz "Sie haben eine ungueltige Verzeichnis Nummer eingegeben."
	.byte 0x00
	.ascii "Le r"
	.byte 0xe9  ; "é"
	.asciz "pertoire choisi n'existe pas."
	.byte 0x00
	.asciz "The file number is out of range."
	.byte 0x00
	.asciz "Die eingegebene Nummer existiert nicht."
	.asciz "Le titre choisi n'existe pas."
	.asciz "Please wait ..."
	.asciz "Bitte warten ..."
	.byte 0x00
	.asciz "Attendre S.V.P."
	.asciz "!FORMAT ERROR!"
	.byte 0x00
	.asciz "!FORMAT FEHLER!"
	.asciz "!FORMAT ERREUR!"
	.asciz "The automatic HD format was not successful!"
	.asciz "Die Formatierung war nicht erfolgreich!"
	.asciz "Le formatage du disque dur n'a pas pu se faire correctement!"
	.byte 0x00
	.asciz "Please try once more, refer your owners manual or ask your dealer/service center."
	.asciz "Versuchen Sie es nochmals, schauen Sie in der Anleitung nach oder rufen Sie Ihre Service-Stelle an."
	.ascii "R"
	.byte 0xe9  ; "é"
	.ascii "p"
	.byte 0xe9  ; "é"
	.ascii "tez l'operation en vous r"
	.byte 0xe9  ; "é"
	.ascii "f"
	.byte 0xe9  ; "é"
	.ascii "rent au manuel ou en cas d'"
	.byte 0xe9  ; "é"
	.asciz "chec, contactez votre service assistance."
	.asciz "Input error!"
	.byte 0x00
	.asciz "Eingabe-Fehler!"
	.asciz "Erreur d'operation!"
	.asciz "The key code input was wrong!"
	.asciz "Die Nummerneingabe war falsch!"
	.byte 0x00
	.asciz "Le cocde n'est pas correct!"
	.asciz "Please try once more, refer your owners manual or ask your dealer/service center."
	.asciz "Versuchen Sie es nochmals, schauen Sie in der Anleitung nach oder rufen Sie Ihre Service-Stelle an."
	.ascii "Veuillez r"
	.byte 0xe9  ; "é"
	.ascii "p"
	.byte 0xe9  ; "é"
	.ascii "ter l'ex"
	.byte 0xe9  ; "é"
	.ascii "cution et vous r"
	.byte 0xe9  ; "é"
	.ascii "f"
	.byte 0xe9  ; "é"
	.asciz "rez au manuel ou contactez votre service assistance."
	.asciz "Delete file from hard disk:"
	.asciz "Loesche Titel von Festplatte:"
	.asciz "Effacer titre du disque dur:"
	.byte 0x00
	.asciz "The hard disk will now be formatted. This procedure can take about 2-3 minutes."
	.asciz "Die Festplatte wird nun neu formatiert. Dieser Vorgang dauert ca. 2-3 Minuten."
	.byte 0x00
	.asciz "The hard disk will now be formatted. This procedure can take about 2-3 minutes."
	.asciz "We recommend to turn ON and OFF again the power after the complete format."
	.byte 0x00
	.asciz "Wir empfehlen, nach der Formatierung das Keyboard aus und wieder einzuschalten."
	.asciz "We recommend to turn ON and OFF again the power after the complete format."
	.byte 0x00
	.asciz "Track O will be recovered:"
	.byte 0x00
	.asciz "Track 0 wird kontrolliert:"
	.byte 0x00
	.asciz "Track O will be recovered:"
	.byte 0x00
	.asciz "The FLS entry remains free."
	.asciz "Der FLS Eintrag bleibt frei."
	.byte 0x00
	.asciz "Ce FLS registartion reste libre."
	.byte 0x00
	.asciz "All following entries will be moved."
	.byte 0x00
	.asciz "Alle nachfolgenden Eintraege werden nachgeschoben."
	.byte 0x00
	.ascii "Tous les registartion suivant seront d"
	.byte 0xe9  ; "é"
	.asciz "placer."
	.byte 0x00
	.asciz "Evaluation 01-01-99"
	.asciz "Test-Version 01-01-99"
	.ascii "Version d'"
	.byte 0xe9  ; "é"
	.asciz "valuation"
	.byte 0x00
	.asciz "LYRICS LOAD MODE"
	.byte 0x00
	.asciz "LYRICS LOAD MODE"
	.byte 0x00
	.asciz "LYRICS LOAD MODE"
	.byte 0x00
	.asciz "COLOR ACTIV"
	.asciz "AKTIVE FARBE"
	.byte 0x00
	.asciz "COLOUR ACTIVE"
	.asciz "COLOR PASSIV"
	.byte 0x00
	.asciz "PASSIVE FARBE"
	.asciz "COLOUR PASSIVE"
	.byte 0x00
	.asciz "You are going to overwrite an existing entry. Are you sure?"
	.asciz "Sie ueberschreiben einen bestehenden Eintrag. Sind Sie sicher?"
	.byte 0x00
	.asciz "Vous etes en train de modifier un titre existant. Etes-vous sur?"
	.byte 0x00
	.asciz "YES"
	.asciz "JA"
	.byte 0x00
	.asciz "OUI"
	.asciz "NO"
	.byte 0x00
	.asciz "NEIN"
	.byte 0x00
	.asciz "NON"
	.asciz "OK"
	.byte 0x00
	.asciz "OK"
	.byte 0x00
	.asciz "OK"
	.byte 0x00
	.asciz "CANCEL"
	.byte 0x00
	.asciz "Abbruch"
	.asciz "CANCEL"
	.byte 0x00
	.asciz "Operation error!"
	.byte 0x00
	.asciz "Bedienungsfehler!"
	.asciz "Error d'operation!"
	.byte 0x00
	.asciz "!SAVE ERROR!"
	.byte 0x00
	.asciz "!SAVE-FEHLER!"
	.asciz "!SAVE ERREUR!"
	.asciz "!LOAD ERROR!"
	.byte 0x00
	.asciz "!LOAD-FEHLER!"
	.asciz "!LOAD ERREUR!"
	.asciz "!SYSTEM ERROR!"
	.byte 0x00
	.asciz "!SYSTEM-FEHLER!"
	.asciz "!SYSTEM ERREUR!"
	.asciz "!ATTENTION!"
	.asciz "!ACHTUNG!"
	.asciz "!ATTENTION!"
	.asciz "Press YES for confirmation, NO to abort."
	.byte 0x00
	.asciz "Bestaetigen Sie den Vorgang mit JA oder druecken Sie die NEIN Taste."
	.byte 0x00
	.asciz "Pressez OUI pour confirmer ou NON pour annuler."
	.asciz "Please call your dealer or service center."
	.byte 0x00
	.asciz "Bitte rufen Sie Ihre Service-Stelle an."
	.asciz "Contactez votre service assistance."
	.asciz "No Message"
	.zero 3
	.asciz "I"
	.byte 0x92  ; ""
	.byte 0x00
	.byte 0xdb  ; "Û"
	.byte 0x00
	.byte 0x24
	.byte 0x01
	.ascii "m"
	.byte 0x01
	.byte 0xb6  ; "¶"
	.byte 0x01
	.byte 0xff
	.byte 0x01
	.byte 0x48
	.byte 0x02
	.byte 0x91  ; ""
	.byte 0x02
	.byte 0xda  ; "Ú"
	.byte 0x02
	.byte 0x23
	.byte 0x03
	.ascii "l"
	.byte 0x03
	.byte 0xb5  ; "µ"
	.byte 0x03
	.byte 0xfe  ; "þ"
	.byte 0x03
	.byte 0x47
	.byte 0x04
	.byte 0x90  ; ""
	.byte 0x04
	.byte 0xd9  ; "Ù"
	.byte 0x04
	.byte 0x22
	.byte 0x05
	.ascii "k"
	.byte 0x05
	.byte 0xb4  ; "´"
	.byte 0x05
	.byte 0xfd  ; "ý"
	.byte 0x05
	.byte 0x46
	.byte 0x06
	.byte 0x8f  ; ""
	.byte 0x06
	.byte 0xd8  ; "Ø"
	.byte 0x06
	.byte 0x21
	.byte 0x07
	.ascii "j"
	.byte 0x07
	.byte 0xb3  ; "³"
	.byte 0x07
	.byte 0xfc  ; "ü"
	.byte 0x07
	.byte 0x45
	.byte 0x08
	.byte 0x8e  ; ""
	.byte 0x08
	.byte 0xd7  ; "×"
	.byte 0x08
	.ascii " "
	.byte 0x09
	.ascii "i"
	.byte 0x09
	.byte 0xb2  ; "²"
	.byte 0x09
	.byte 0xfb  ; "û"
	.byte 0x09
	.byte 0x44
	.byte 0x0a
	.byte 0x8d  ; ""
	.byte 0x0a
	.byte 0xd6  ; "Ö"
	.byte 0x0a, 0x1f, 0x0b
	.ascii "h"
	.byte 0x0b
	.byte 0xb1  ; "±"
	.byte 0x0b
	.byte 0xfa  ; "ú"
	.byte 0x0b
	.byte 0x43
	.byte 0x0c
	.byte 0x8c  ; ""
	.byte 0x0c
	.byte 0xd5  ; "Õ"
	.byte 0x0c, 0x1e, 0x0d
	.ascii "g"
	.byte 0x0d
	.byte 0xb0  ; "°"
	.byte 0x0d
	.byte 0xf9  ; "ù"
	.byte 0x0d
	.byte 0x42
	.byte 0x0e
	.byte 0x8b  ; ""
	.byte 0x0e
	.byte 0xd4  ; "Ô"
	.byte 0x0e, 0x1d, 0x0f
	.ascii "f"
	.byte 0x0f
	.byte 0xaf  ; "¯"
	.byte 0x0f
	.byte 0xf8  ; "ø"
	.byte 0x0f
	.byte 0x41
	.byte 0x10
	.byte 0x8a  ; ""
	.byte 0x10
	.byte 0xd3  ; "Ó"
	.byte 0x10, 0x1c, 0x11
	.ascii "e"
	.byte 0x11
	.byte 0xf1  ; "ñ"
	.byte 0x15
	.byte 0xae  ; "®"
	.byte 0x11
	.byte 0xf7  ; "÷"
	.byte 0x11
	.byte 0x40
	.byte 0x12
	.byte 0x89  ; ""
	.byte 0x12
	.byte 0xd2  ; "Ò"
	.byte 0x12, 0x1b, 0x13
	.ascii "d"
	.byte 0x13
	.byte 0xad  ; "­"
	.byte 0x13
	.byte 0xf1  ; "ñ"
	.byte 0x15
	.byte 0xf1  ; "ñ"
	.byte 0x15
	.byte 0xf6  ; "ö"
	.byte 0x13
	.byte 0x3f
	.byte 0x14
	.byte 0x88  ; ""
	.byte 0x14
	.byte 0xd1  ; "Ñ"
	.byte 0x14, 0x1a, 0x15
	.ascii "c"
	.byte 0x15
	.byte 0xaa  ; "ª"
	.byte 0x15

HDAE5000_Lang_Codes:	; 0x2E5B80
	; Language code strings and file types
	.asciz "                                        "
	.byte 0x00
	.asciz "Reset"
	.asciz "Load"
	.byte 0x00
	.asciz "%03i - %i "
	.zero 3
	.asciz "}"
	.asciz "}"
	.asciz "}"
	.asciz "}"
	.asciz "}"
	.asciz "}"
	.asciz "D"
	.byte 0xaa  ; "ª"
	.byte 0x00
	.byte 0xb0  ; "°"
	.byte 0x06, 0x10, 0x07
	.byte 0xa2  ; "¢"
	.byte 0x05
	.byte 0x29
	.byte 0x02
	.byte 0xc5  ; "Å"
	.byte 0x02
	.byte 0x3b
	.byte 0x05
	.asciz "rb"
	.byte 0x00
	.asciz "TESTTEST.TLX"
	.byte 0x00
	.asciz "Fault : No Lyrics loaded or corrupt Data - Code %i %i %i     "
	.asciz " %i/%i "
	.asciz "Chord : %s               "
	.asciz "Info :                            "
	.byte 0x00
	.asciz "No Copyright Info"
	.asciz "No Song Title"
	.asciz " %i/%i "
	.zero 4
	.asciz "TLhd"
	.byte 0x00
	.asciz "TLtr"
	.zero 3
	.asciz "                           "
	.asciz "                           "
	.asciz "mid"
	.asciz "   "
	.asciz "                                                 "
	.asciz "%s %s"
	.asciz "%s %s"
	.asciz ".TLX"
	.byte 0x00
	.asciz "rb"
	.zero 3
	.byte 0x03, 0x03, 0x03, 0x03, 0x02, 0x02
	.zero 2
	.byte 0x01, 0x01, 0x01, 0x01, 0x02, 0x02
	.byte 0xe9  ; "é"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0x1e, 0x01
	.zero 2
	.asciz " ->"
	.asciz "*.*"
	.asciz ".TTX"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".MID"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz "XLT."
	.byte 0x00
	.byte 0xbc  ; "¼"
	.asciz "]."
	.byte 0xb2  ; "²"
	.asciz "]."
	.byte 0xa8  ; "¨"
	.asciz "]."
	.byte 0x9e  ; ""
	.asciz "]."
	.byte 0x94  ; ""
	.asciz "]."
	.byte 0x8a  ; ""
	.asciz "]."
	.asciz "LANENG006"
	.asciz "LANENG005"
	.asciz "LANENG004"
	.asciz "LANFRA003"
	.asciz "LANDEU002"
	.asciz "LANENG001"
	.asciz "XAP"
	.asciz "rb"
	.byte 0x00

HDAE5000_Palette_Data:	; 0x2E5DCE
	; VGA palette data (256 entries)
	.incbin "includes/code_29af2d_2fffff.bin", 306849, 77824

HDAE5000_Display_Params:	; 0x2F8DCE
	; Display configuration parameters
	.asciz "HD-AE5000"
	.zero 8
	.asciz "                "
	.byte 0x00
	.asciz "                "
	.byte 0x00
	.asciz "                          "
	.byte 0x00
	.byte 0x98, 0x8e
	.asciz "/"
	.byte 0x04
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x94, 0x8e
	.asciz "/"
	.zero 2
	.byte 0x02
	.byte 0x00
	.byte 0x90, 0x8e
	.asciz "/"
	.byte 0x05
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x8c, 0x8e
	.asciz "/"
	.zero 2
	.byte 0x03
	.byte 0x00
	.ascii "z"
	.byte 0x8e
	.asciz "/"
	.zero 2
	.byte 0x10
	.byte 0x00
	.ascii "v"
	.byte 0x8e
	.asciz "/"
	.zero 2
	.byte 0x03
	.byte 0x00
	.ascii "r"
	.byte 0x8e
	.asciz "/"
	.zero 2
	.byte 0x03
	.byte 0x00
	.ascii "n"
	.byte 0x8e
	.asciz "/"
	.zero 2
	.byte 0x02
	.byte 0x00
	.ascii "h"
	.byte 0x8e
	.asciz "/"
	.zero 2
	.byte 0x04
	.byte 0x00
	.asciz "TLhd"
	.byte 0x00
	.asciz "HK"
	.byte 0x00
	.asciz "H"
	.asciz "K"
	.asciz "H"
	.asciz "K"
	.asciz "KN5000 SOUND RAM"
	.byte 0x00
	.asciz "H"
	.asciz "K"
	.byte 0x01, 0x08
	.zero 2
	.asciz "HK"
	.byte 0x00
	.asciz "HK"
	.byte 0x00
	.asciz ".SEQ"
	.byte 0x00
	.asciz ".SQF"
	.byte 0x00
	.asciz ".LSW"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".PMT"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".SQT"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".CMP"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".TM"
	.asciz "rb"
	.byte 0x00
	.asciz ".MSP"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".RCM"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".MD"
	.asciz "rb"
	.byte 0x00
	.asciz ".TLX"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".TTX"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".LSW"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".PMT"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".SQT"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".CMP"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".TM"
	.asciz "rb"
	.byte 0x00
	.asciz ".MSP"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".RCM"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".MD"
	.asciz "rb"
	.byte 0x00
	.asciz ".TLX"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz "---[ GetInfoBlockPointer ]---"
	.asciz "ppib adr = %lx"
	.byte 0x00
	.asciz " "
	.asciz "---[ TurnHdMotorOff ]---"
	.byte 0x00
	.asciz " "
	.asciz "---[ SendInfosAboutHd ]---"
	.byte 0x00
	.asciz "hddname : "
	.byte 0x00
	.asciz "hddtrck : %d"
	.byte 0x00
	.asciz "hddhead : %d"
	.byte 0x00
	.asciz "hddsctr : %d"
	.byte 0x00
	.asciz "hddscby : %d"
	.byte 0x00
	.asciz " "
	.asciz "---[ SendInfosAboutDirBlock ]---"
	.byte 0x00
	.asciz "FGB ptr : %lx"
	.asciz "FGB wid : %d"
	.byte 0x00
	.asciz "FGB num : %d"
	.byte 0x00
	.asciz " "
	.asciz "---[ SendInfosAboutFileSystemBlock ]---"
	.asciz "FEB ptr : %lx"
	.asciz "FEB wid : %d"
	.byte 0x00
	.asciz "FEB num : %d"
	.byte 0x00
	.asciz " "
	.asciz "---[ SendInfosAboutFlsBlock ]---"
	.byte 0x00
	.asciz "FLS ptr : %lx"
	.asciz "FLS wid : %d"
	.byte 0x00
	.asciz "FLS num : %d"
	.byte 0x00
	.asciz "FLS ent : %d"
	.byte 0x00
	.asciz " "
	.asciz "---[ ReadDirBlockFromHd ]---"
	.byte 0x00
	.asciz " "
	.asciz "---[ ReadFileBlockFromHd ]---"
	.asciz " "
	.asciz "---[ ReadFlsBlockFromHd ]---"
	.byte 0x00
	.asciz " "
	.asciz "---[ WriteDirBlockToHd ]---"
	.asciz " "
	.asciz "---[ WriteFileSystemBlockToHd ]---"
	.byte 0x00
	.asciz " "
	.asciz "---[ WriteFlsBlockToHd ]---"
	.asciz " "
	.asciz "---[ SendInfosAboutSong ]--- "
	.asciz "dirname : %s"
	.byte 0x00
	.asciz "sngname : %s"
	.byte 0x00
	.asciz " "
	.asciz "---[ LoadSongFromHdToMemory ]---"
	.byte 0x00
	.asciz " "
	.asciz "---[ SaveSongInMemoryToHd ]---"
	.byte 0x00
	.asciz " "
	.asciz "---[ InitWholeSongInMemory ]---"
	.asciz " "
	.asciz "---[ FormatHd ]---"
	.byte 0x00
	.asciz " "
	.asciz "---[ SendPointerToFreeBufferSpace ]---"
	.byte 0x00
	.asciz "work adr : %lx"
	.byte 0x00
	.asciz " "
	.asciz "---[ PreWholeSongInMemory ]---"
	.byte 0x00
	.asciz " "
	.asciz "---[ WriteOpenHD ]--- "
	.byte 0x00
	.asciz "SUFFIX : %d"
	.asciz "---[ WriteCloseHD ]--- "
	.asciz "---[ WriteFileHD ]--- "
	.byte 0x00
	.asciz "---[ ReadOpenHD ]--- "
	.asciz "---[ ReadFileHD ]--- "
	.ascii "         (((((                  H"
	.byte 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x84
	.byte 0x84, 0x84, 0x84, 0x84, 0x84, 0x84, 0x84, 0x84, 0x84, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10
	.byte 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
	.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10
	.byte 0x82, 0x82, 0x82, 0x82, 0x82, 0x82, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02
	.byte 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x10, 0x10, 0x10, 0x10
	.asciz " "
	.zero 129
	.byte 0x0d, 0x01, 0x8a, 0x06, 0x8a, 0x06, 0x8a, 0x06, 0xe1, 0x06, 0x0d, 0x01, 0xe1, 0x06, 0xe1, 0x06
	.byte 0xe1, 0x06, 0xe1, 0x06
	.ascii "f"
	.byte 0x06, 0x1a, 0x05, 0xaf, 0x03, 0xe1, 0x06, 0xe1, 0x06
	.asciz "i"
	.byte 0xe1, 0x06, 0xb9, 0x02, 0xe1, 0x06, 0xe1, 0x06, 0xb2, 0x03
	.asciz "0123456789abcdef"
	.byte 0x00
	.asciz "0123456789ABCDEF"
	.byte 0x00

HDAE5000_Init_Data:	; 0x2F94B2
	; Data copied to 0x23952A (0xC82 bytes)
	.incbin "includes/code_29af2d_2fffff.bin", 386437, 27470

; ============================================================================
; END OF ROM (0x300000)
; ============================================================================

end:

; Labels emitted as .set (exact addresses from ORG/name)
